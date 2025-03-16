#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=/home/loic/ASSIGNMENT1/finder-app
ARCH=arm64
CROSS_COMPILE=/home/loic/arm-cross-compiler/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-
LIBC_PATH=/home/loic/arm-cross-compiler/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc

if [ $# -lt 1 ]
then
        echo "Using default directory ${OUTDIR} for output"
else
        OUTDIR=$1
        echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    # Clone only if the repository does not exist.
    echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
    git clone --depth 1 --branch ${KERNEL_VERSION} https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git ${OUTDIR}/linux-stable
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    #--------------------------------------------
    # Kernel build steps
    #--------------------------------------------    
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} mproper # clean the kernel
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} defconfig # default config
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} oldconfig # Generate .config file
    make -j12 ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} all # compile the kernel
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} modules # compile modules
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} dtbs # compile device tree
fi
# Si les fichiers de configuration du noyau n'existent pas, générer les fichiers de configuration
if [ ! -f ${OUTDIR}/linux-stable/.config ]; then
    echo "Configuring the kernel"
    cd ${OUTDIR}/linux-stable
    make ARCH=arm64 defconfig
fi

# Maintenant on peut compiler le noyau
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd ${OUTDIR}/linux-stable
    echo "Building the kernel image"
    make -j$(nproc) ARCH=arm64 Image
fi
if [ ! -f ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    echo "ERROR: Kernel image not found! Building the kernel..."

    # Configure le noyau si nécessaire
    cd ${OUTDIR}/linux-stable
    make ARCH=arm64 defconfig  # Configure le noyau pour l'architecture arm64
  # Compilation du noyau (génération de l'image)
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} -j$(nproc) Image
    # Compile le noyau si nécessaire
    make -j$(nproc) ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} Image  # Compile le noyau

fi
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/ # copy to output dir
echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image /tmp/aesd-autograder/ # copier l'image dans /tmp/aesd-autograder
echo "Kernel Image copied to /tmp/aesd-autograder"


echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
    echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm -rf ${OUTDIR}/rootfs
fi

#----------------------------------------
# Create necessary base directories
#----------------------------------------
mkdir "$OUTDIR/rootfs"
mkdir -p ${OUTDIR}/rootfs/{bin,sbin,lib,lib64,dev,etc,home,proc,sys,tmp,usr,var}
mkdir -p ${OUTDIR}/rootfs/usr/{bin,sbin,lib}
mkdir -p ${OUTDIR}/rootfs/var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone https://github.com/mirror/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    make distclean
    make defconfig
    make oldconfig
else
    cd busybox
    make oldconfig
fi

#---------------------------------
# Compile and install busybox
#--------------------------------
echo "Compiling busybox"
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX="${OUTDIR}/rootfs" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

# Apply setuid root to busybox binary
sudo chmod u+s ${OUTDIR}/rootfs/bin/busybox

# Verify busybox binary
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

#-------------------------------------------
# Add library dependencies to rootfs
#-------------------------------------------
cp ${LIBC_PATH}/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib
cp ${LIBC_PATH}/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64/
cp ${LIBC_PATH}/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64/
cp ${LIBC_PATH}/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64/

#--------------------------
# Create device nodes
#--------------------------
echo "Creating device nodes..."
sudo rm -f ${OUTDIR}/rootfs/dev/null
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo rm -f ${OUTDIR}/rootfs/dev/console
sudo mknod -m 600 ${OUTDIR}/rootfs/dev/console c 5 1
# Additional devices
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/tty c 5 0
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/tty1 c 4 1

#-------------------------------------------
# Clean and build the writer utility
#-------------------------------------------
echo "Cleaning and building writer utility"

cd ${FINDER_APP_DIR}
make clean
make CC=${CROSS_COMPILE}gcc # Security message
if [ -f writer ]; then
    echo "Writer utility built successfully"
else
    echo "Error: Writer utility failed to build"
    exit 1
fi

#-------------------------------------------------------------------------------
# Copy the finder related scripts and executables to the /home directory
# on the target rootfs
#-------------------------------------------------------------------------------
cp ${FINDER_APP_DIR}/finder-test.sh ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/finder.sh ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/writer ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/writer.c ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/autorun-qemu.sh ${OUTDIR}/rootfs/home/
cp -rL ${FINDER_APP_DIR}/conf ${OUTDIR}/rootfs/home/

cd "${OUTDIR}/rootfs"
#--------------------------------
# Chown the root directory
#-------------------------------
sudo chown -R root:root ${OUTDIR}/rootfs

#--------------------------------
# Create initramfs.cpio.gz
#--------------------------------
cd "${OUTDIR}/rootfs"
find . | cpio -o -H newc | gzip -9 > ${OUTDIR}/initramfs.cpio.gz
cd "${OUTDIR}"

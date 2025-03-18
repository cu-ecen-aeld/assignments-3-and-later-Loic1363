#/bin/bash
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
CROSS_COMPILE=aarch64-none-linux-gnu-
LIBC_PATH=/home/loic/arm-cross-compiler/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc

echo "Vérification du compilateur croisé : $CROSS_COMPILE"
which aarch64-none-linux-gnu-gcc
echo "CROSS_COMPILE: $CROSS_COMPILE"
echo "PATH: $PATH"
if [ $# -lt 1 ]
then
        echo "Using default directory ${OUTDIR} for output"
else
        OUTDIR=$1
        echo "Using passed directory ${OUTDIR} for output"
fi
echo "Using cross compiler: $CROSS_COMPILE"
#ls -l $(dirname $CROSS_COMPILE)

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    # Clone only if the repository does not exist.
    echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
    git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi

#--------------------------------------------
# Kernel build steps
#--------------------------------------------    
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    git checkout ${KERNEL_VERSION}
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j12 ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} all
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} modules
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/

cd "${OUTDIR}"
if [ -d "${OUTDIR}/rootfs" ]; then
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

if [ ! -d "$OUTDIR/busybox" ]; then
    git clone https://github.com/mirror/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}

    make distclean
    make defconfig
else
   cd busybox
fi

#---------------------------------
# Compile and install busybox
#--------------------------------
echo "Compiling busybox"
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX="${OUTDIR}/rootfs" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

cd "${OUTDIR}"

# Verify busybox binary
${CROSS_COMPILE}readelf -a ./rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ./rootfs/bin/busybox | grep "Shared library"

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
sudo rm -f /dev/null
sudo mknod -m 666 /dev/null c 1 3
sudo rm -f /dev/console
sudo mknod -m 600 /dev/console c 5 1
#-------------------------------------------
# Clean and build the writer utility
#-------------------------------------------
echo "Cleaning and building writer utility"

cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE}
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
sudo chown -R root:root *

#--------------------------------
# Create initramfs.cpio.gz
#--------------------------------
cd "${OUTDIR}/rootfs"
#with help of stackoverflow (above)
echo "initramfs image"
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
cd ..
gzip -f initramfs.cpio

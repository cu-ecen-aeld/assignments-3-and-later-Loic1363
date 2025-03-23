#include <stdbool.h>
#include <pthread.h>

/**
 * This structure should be dynamically allocated and passed as
 * an argument to your thread using pthread_create.
 * It should be returned by your thread so it can be freed by
 * the joiner thread.
 */
struct thread_data{
    /*
     * TODO: add other values your thread will need to manage
     * into this structure, use this structure to communicate
     * between the start_thread_obtaining_mutex function and
     * your thread implementation.
     */

    /**
     * Set to true if the thread completed with success, false
     * if an error occurred.
     */
    pthread_mutex_t *mutex;
    int wait_to_obtain_ms;
    int wait_to_release_ms;
    bool thread_complete_success;
};


/**
* Start a thread which sleeps @param wait_to_obtain_ms number of milliseconds, then obtains the
* mutex in @param mutex, then holds for @param wait_to_release_ms milliseconds, then releases.
* The start_thread_obtaining_mutex function should only start the thread and should not block
* for the thread to complete.
* The start_thread_obtaining_mutex function should use dynamic memory allocation for thread_data
* structure passed into the thread.  The number of threads active should be limited only by the
* amount of available memory.
* The thread started should return a pointer to the thread_data structure when it exits, which can be used
* to free memory as well as to check thread_complete_success for successful exit.
Scanning dependencies of target assignment-autotest
[ 30%] Building C object assignment-autotest/CMakeFiles/assignment-autotest.dir/test/assignment1/Test_hello.c.o
[ 38%] Building C object assignment-autotest/CMakeFiles/assignment-autotest.dir/test/assignment1/Test_assignment_validate.c.o
[ 46%] Building C object assignment-autotest/CMakeFiles/assignment-autotest.dir/test/assignment4/Test_threading.c.o
[ 53%] Building C object assignment-autotest/CMakeFiles/assignment-autotest.dir/test/assignment1/Test_hello_Runner.c.o
[ 61%] Building C object assignment-autotest/CMakeFiles/assignment-autotest.dir/test/assignment1/Test_assignment_validate_Runner.c.o
[ 69%] Building C object assignment-autotest/CMakeFiles/assignment-autotest.dir/test/assignment4/Test_threading_Runner.c.o
[ 76%] Building C object assignment-autotest/CMakeFiles/assignment-autotest.dir/__/examples/autotest-validate/autotest-validate.c.o
[ 84%] Building C object assignment-autotest/CMakeFiles/assignment-autotest.dir/__/examples/threading/threading.c.o
/home/loic/ASSIGNMENT1/examples/threading/threading.c: In function ‘threadfunc’:
/home/loic/ASSIGNMENT1/examples/threading/threading.c:22:16: error: ‘struct thread_data’ has no member named ‘wait_to_obtain_ms’
   22 |     usleep(data->wait_to_obtain_ms * 1000);
      |                ^~
/home/loic/ASSIGNMENT1/examples/threading/threading.c:24:32: error: ‘struct thread_data’ has no member named ‘mutex’
   24 |     if (pthread_mutex_lock(data->mutex) != 0) {
      |                                ^~
/home/loic/ASSIGNMENT1/examples/threading/threading.c:30:16: error: ‘struct thread_data’ has no member named ‘wait_to_release_ms’
   30 |     usleep(data->wait_to_release_ms * 1000);
      |                ^~
/home/loic/ASSIGNMENT1/examples/threading/threading.c:32:30: error: ‘struct thread_data’ has no member named ‘mutex’
   32 |     pthread_mutex_unlock(data->mutex);
      |                              ^~
/home/loic/ASSIGNMENT1/examples/threading/threading.c: In function ‘start_thread_obtaining_mutex’:
/home/loic/ASSIGNMENT1/examples/threading/threading.c:54:9: error: ‘struct thread_data’ has no member named ‘mutex’
   54 |     data->mutex = mutex;
      |         ^~
/home/loic/ASSIGNMENT1/examples/threading/threading.c:55:9: error: ‘struct thread_data’ has no member named ‘wait_to_obtain_ms’
   55 |     data->wait_to_obtain_ms = wait_to_obtain_ms;
      |         ^~
/home/loic/ASSIGNMENT1/examples/threading/threading.c:56:9: error: ‘struct thread_data’ has no member named ‘wait_to_release_ms’
   56 |     data->wait_to_release_ms = wait_to_release_ms;
      |         ^~
make[2]: *** [assignment-autotest/CMakeFiles/assignment-autotest.dir/build.make:169: assignment-autotest/CMakeFiles/assignment-autotest.dir/__/examples/threading/threading.c.o] Error 1
make[1]: *** [CMakeFiles/Makefile2:132: assignment-autotest/CMakeFiles/assignment-autotest.dir/all] Error 2
make: *** [Makefile:130: all] Error 2
./unit-test.sh: line 13: ./build/assignment-autotest/assignment-autotest: No such file or directory
* If a thread was started succesfully @param thread should be filled with the pthread_create thread ID
* coresponding to the thread which was started.
* @return true if the thread could be started, false if a failure occurred.
*/
bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms);

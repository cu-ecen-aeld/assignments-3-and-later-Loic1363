#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...) printf("threading : " msg "\n" , ##__VA_ARGS__)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{

    // TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
    // hint: use a cast like the one below to obtain thread arguments from your parameter
    //struct thread_data* thread_func_args = (struct thread_data *) thread_param;

 struct thread_data* data = (struct thread_data*) thread_param;

    if (!data) {

        ERROR_LOG("Thread received null data.");
        return thread_param;
    }

    usleep(data->wait_to_obtain_ms * 1000);

    if (pthread_mutex_lock(data->mutex) != 0) {

        ERROR_LOG("Failed to lock mutex.");
        data->thread_complete_success = false;
        return thread_param;
    }

    DEBUG_LOG("Mutex locked by thread");
    usleep(data->wait_to_release_ms * 1000);
    pthread_mutex_unlock(data->mutex);

    DEBUG_LOG("Mutex unlocked by thread");
    data->thread_complete_success = true;
    return thread_param;
}

bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    /**
     * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */


 struct thread_data* data = malloc(sizeof(struct thread_data));

    if (!data) {
        ERROR_LOG("Failed to allocate memory for thread_data.");

        return false;
    }

    data->mutex = mutex;

    data->wait_to_obtain_ms = wait_to_obtain_ms;

    data->wait_to_release_ms = wait_to_release_ms;

    data->thread_complete_success = false;



    if (pthread_create(thread, NULL, threadfunc, data) != 0) {

        ERROR_LOG("Failed to create thread.");
        free(data);
        return false;
    }

    return true;
}


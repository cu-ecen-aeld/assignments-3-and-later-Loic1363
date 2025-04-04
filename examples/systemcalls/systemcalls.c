#include "systemcalls.h" // default header (i'll add a few more)
#include <unistd.h>
#include <sys/wait.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
*/
bool do_system(const char *cmd)
{
    int result = system(cmd);   // cmd with system function : done 
    return (result == 0);
}

/**
* @param count -The numbers of variables passed to the function. The variables are command to execute.
*   followed by arguments to pass to the command
*   Since exec() does not perform path expansion, the command to execute needs
*   to be an absolute path.
* @param ... - A list of 1 or more arguments after the @param count argument.
*   The first is always the full path to the command to execute with execv()
*   The remaining arguments are a list of arguments to pass to the command in execv()
* @return true if the command @param ... with arguments @param arguments were executed successfully
*   using the execv() call, false if an error occurred, either in invocation of the
*   fork, waitpid, or execv() command, or if a non-zero return value was returned
*   by the command issued in @param arguments with the specified arguments.
*/



bool do_exec(int count, ...)
{
    va_list args;
    va_start(args, count);
    
    char *command[count + 1];
    for (int i = 0; i < count; i++) {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;

    if (command[0][0] != '/') {
        fprintf(stderr, "execv failed: Command should have an absolute path\n");
        va_end(args);
        return false;
    }

    pid_t pid = fork();

    if (pid == -1) {
        va_end(args);
        return false;
    }

    if (pid == 0) {
        execv(command[0], command);
        perror("execv failed");
        va_end(args);
        return false;
    } else {
        int status;
        waitpid(pid, &status, 0);

        if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
            va_end(args);
            return true;
        } else {
            va_end(args);
            return false;
        }
    }
}

/**
* @param outputfile - The full path to the file to write with command output.
*   This file will be closed at completion of the function call.
* All other parameters, see do_exec above
*/
bool do_exec_redirect(const char *outputfile, int count, ...)
{
    va_list args;
    va_start(args, count);

    char *command[count + 1];
    for (int i = 0; i < count; i++) {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;

    pid_t pid = fork();

    if (pid == -1) {
        va_end(args);
        return false;
    }

    if (pid == 0) {
        FILE *output = fopen(outputfile, "w");
        if (output == NULL) {
            perror("fopen failed");
            va_end(args);
            return false;
        }

        if (dup2(fileno(output), STDOUT_FILENO) == -1) {
            perror("dup2 failed");
            fclose(output);
            va_end(args);
            return false;
        }

        fclose(output);
        execv(command[0], command);
        perror("execv failed");
        va_end(args);
        return false;
    } else {
        int status;
        waitpid(pid, &status, 0);

        if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
            va_end(args);
            return true;
        } else {
            va_end(args);
            return false;
        }
    }
}

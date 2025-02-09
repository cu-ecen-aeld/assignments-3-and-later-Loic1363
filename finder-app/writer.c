#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>
#include <errno.h>


void create_directory(const char *filepath) {
    char path[256];
    strcpy(path, filepath);

    char *last_slash = strrchr(path, '/');
    if (last_slash) {
        *last_slash = '\0'; 
        if (mkdir(path, 0777) != 0 && errno != EEXIST) {
            syslog(LOG_ERR, "Error creating directory %s: %s", path, strerror(errno));
            exit(EXIT_FAILURE);
        }
    }
}

int main(int argc, char *argv[]) {
    openlog("writer", LOG_PID, LOG_USER);

    
    if (argc != 3) {
        syslog(LOG_ERR, "Error: Missing arguments. Usage: %s <file> <string>", argv[0]);
        fprintf(stderr, "Error: Missing arguments. Usage: %s <file> <string>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    const char *filepath = argv[1];
    const char *content = argv[2];

    
    create_directory(filepath);

    
    FILE *file = fopen(filepath, "w");
    if (!file) {
        syslog(LOG_ERR, "Error opening file: %s", filepath);
        fprintf(stderr, "Error opening file: %s\n", filepath);
        exit(EXIT_FAILURE);
    }

    
    if (fprintf(file, "%s", content) < 0) {
        syslog(LOG_ERR, "Error writing to file: %s", filepath);
        fprintf(stderr, "Error writing to file: %s\n", filepath);
        fclose(file);
        exit(EXIT_FAILURE);
    }

    
    fclose(file);
    syslog(LOG_DEBUG, "Writing '%s' to '%s'", content, filepath);

    closelog();
    return 0;
}


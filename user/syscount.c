#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define SYS_MAX 31
// 0-30: system call numbers
static char *syscall_names[] = {
    "fork", "exit", "wait", "pipe", "read", "kill", "exec", "fstat", "chdir",
    "dup", "getpid", "sbrk", "sleep", "uptime", "open", "write", "mknod", 
    "unlink", "link", "mkdir", "close", "getSysCount"
};
int find_index_from_mask(int mask) {
    int index = 0;
    
    // Loop through each bit position until the mask is zero
    while (mask > 1) {
        mask >>= 1;  // Right shift the mask to check the next bit
        index++;     // Increment the index counter
    }
    return index;
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(2, "Usage: syscount <mask> <command> [args...]\n");
        exit(1);
    }

    // Convert mask from string to integer
    int mask = atoi(argv[1]);

    // Create a child process to run the specified command
    int pid = fork();
    if (pid < 0) {
        fprintf(2, "fork failed\n");
        exit(1);
    } else if (pid == 0) {
        // Child process runs the specified command
        exec(argv[2], &argv[2]);
        // If exec fails
        fprintf(2, "exec failed\n");
        exit(1);
    } else {
        // Parent process waits for the child
        wait(0);
        // Call the getSysCount system call to get the syscall count
        int result = getSysCount(mask);
        //int count = result >> 16; // Higher 16 bits hold the count
        int syscall_index = find_index_from_mask(mask);
        // Print the result
        printf("PID %d called %s %d times.\n", pid, syscall_names[syscall_index - 1], result);
        exit(0);
    }
}

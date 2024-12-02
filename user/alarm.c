#include "kernel/types.h"
#include "user.h"

void handler() {
    printf("Handler called\n");
    sigreturn();  // Must call sigreturn at the end of the handler.
}

int main(void) {

    sigalarm(4,handler);  // Set an alarm to trigger every 4 ticks.
    int large_val_to_iterate = 1000 * 500000;

    for (int i = 0; i < large_val_to_iterate; i++) {
        
        if ((i % 1000000) == 0){
            write(2, ".", 1);
        }
    }

    exit(0);
}

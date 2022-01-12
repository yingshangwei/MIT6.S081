#include <kernel/types.h>
#include <kernel/stat.h>
#include "user/user.h"

int main(int argc, char* argv[]) {
    if(argc != 2) {
       fprintf(2,"sleep : arguments error!\n");
        exit(1);
    }

    int tick = atoi(argv[1]);
    sleep(tick);
    //printf("hello world!\n");
    exit(0);
}

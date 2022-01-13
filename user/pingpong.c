#include <kernel/types.h>
#include <kernel/stat.h>
#include "user/user.h"

int main(int argc, char* argv[]) {
    if(argc > 1) {
       fprintf(2,"pingpong : arguments error!\n");
        exit(1);
    }
    
    int fa_p[2];
    int ch_p[2];
    pipe(fa_p);
    pipe(ch_p);

    char buff[2];

    if(fork() == 0) {
        read(fa_p[0],buff,1);
        printf("%d: received ping\n", getpid());
        write(ch_p[1],"c",1);
    } else {
        write(fa_p[1],"c",1);
        read(ch_p[0],buff,1);
        int pid = getpid();
        printf("%d: received pong\n",pid);
    }
    exit(0);
}

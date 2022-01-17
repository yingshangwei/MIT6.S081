#include <kernel/types.h>
#include <kernel/stat.h>
#include "user/user.h"


unsigned int BytesToUnsignedInt(unsigned char bytes[4]) {
    unsigned int t = 0;
    for(int i = 4;i >= 0;i--) {
        t <<= 8;
        t += ((unsigned int)bytes[i]);
    }
    return t;
}
void UnsignedIntToBytes(unsigned int t, unsigned char bytes[]) {
    for(int i = 0;i < 4;i++) {
        bytes[i] = t&255;
        t >>= 8; 
    } 
}
// void dfs(int p[]) {
//     close(p[1]);
//     unsigned char buff[4];
//     buff[0] = buff[1] = buff[2] = buff[3] = 0;
//     int res;
//     if((res=read(p[0],buff,4)) <= 0) {
//         if(res < 0) {
//             fprintf(2,"dfs : first read error!\n");
//         }
//         exit(0);
//     }
//     unsigned int t;
//     t = BytesToUnsignedInt(buff);
//     //if(t > 35) exit(0);
//     printf("prime %d\n", t);
//     int pp[2];
//     // pp[0] = p[0], pp[1] = p[1];
//     while((res=pipe(pp)) < 0) {
//         sleep(1);
//         //fprintf(2,"dfs : pipe error %d\n",res);
//         //exit(0);
//     }
//     while(read(p[0],buff,4) != 0) {
//         if(BytesToUnsignedInt(buff)%t!=0) write(pp[1],buff,4);
//     }
//     close(p[0]);
//     if(fork() == 0) {
//         dfs(pp);
//         //exit(0);
//     }
//     //wait((int*)0);
//     exit(0);

// }
int main(int argc, char* argv[]) {
    if(argc != 1) {
       fprintf(2,"primes : arguments error!\n");
        exit(1);
    }

    int p[2];
    pipe(p);
    unsigned char buff[4];

    int runcnt;
    for(runcnt = 0;;runcnt++) {
        if(runcnt==0) {
            if(fork()==0) continue;
            close(p[0]);
            for(int i = 2;i < 36;i++) {
                UnsignedIntToBytes(i,(unsigned char*)buff);
                //printf("list i %d\n", i);
                //printf("list %d %d %d %d\n", buff[0], buff[1], buff[2], buff[3]);
                write(p[1],buff,4);
            }
            close(p[1]);
            break;
        } else {
            close(p[1]);
            unsigned char buff[4];
            int fd = p[0];
            buff[0] = buff[1] = buff[2] = buff[3] = 0;
            int res;
            if((res=read(fd,buff,4)) <= 0) {
                if(res < 0) {
                    fprintf(2,"dfs : first read error!\n");
                }
                exit(0);
            }
            unsigned int t;
            t = BytesToUnsignedInt(buff);
            //if(t > 35) exit(0);
            printf("prime %d\n", t);
            
            // pp[0] = p[0], pp[1] = p[1];
            while((res=pipe(p)) < 0) {
                sleep(1);
                //fprintf(2,"dfs : pipe error %d\n",res);
                //exit(0);
            }
            if(fork() == 0) {
                continue;
            }
            close(p[0]);
            while(read(fd,buff,4) != 0) {
                if(BytesToUnsignedInt(buff)%t!=0) write(p[1],buff,4);
            }
            close(fd);
            close(p[1]);
            exit(0);
        }
    }
    //wait((int*)0);
    exit(0);
}

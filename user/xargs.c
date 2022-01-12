#include <kernel/types.h>
#include <kernel/stat.h>
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/param.h"

int main(int argc, char* argv[]) {
    if(argc <= 1) {
       fprintf(2,"xargs : arguments error!\n");
        exit(1);
    }
    int n = 1;
    int p = 1;
    if(strcmp(argv[1],"-n") == 0) {
        n = atoi(argv[2]);
        p = 3;
    }

    char buff[512];
    char *arg[MAXARG+1];
    int argcnt = 0;
    char arg_buff[MAXARG][50];
    arg[argcnt] = arg_buff[argcnt];
    argcnt++;
    for(int i = p+1;i < argc;i++) {
        arg[argcnt] = arg_buff[argcnt];
        memmove(arg[argcnt],argv[i],strlen(argv[i]));
        arg[argcnt][strlen(argv[i])] = 0;
        //argp += strlen(argv[i]);
        //*argp++ = ' ';
        argcnt++;
    }
    //int temp = 0;
    while(1) {
        //printf("ok %d\n", ++temp);
        int cnt = 0;
        int targcnt = argcnt;
        arg[argcnt] = 0;
        while(cnt < n) {
            //printf("okk %d\n", cnt);
            char* tail = buff;
            int res;
            while((res=read(0,tail,1)) > 0) {
                //printf("okkk %c\n", *tail);
                if(*tail == '\n') {
                    break;
                }
                tail++;
            }
            if(res <= 0) break;
            if(tail-buff>0) {
                *tail = 0;
            }
            arg[targcnt] = arg_buff[targcnt];
            memmove(arg[targcnt],buff,strlen(buff));
            arg[targcnt][strlen(buff)] = 0;
            arg[++targcnt] = 0;
            cnt++;
        }
        if(cnt == 0) break;
        if(fork() == 0) {
            //printf("exec %s\n", argv[p]);
            for(int i = 0;;i++) {
                if(arg[i]==0) break;
                //printf("arg %s\n", arg[i]);
            }
            memmove(arg[0],argv[p],strlen(argv[p])+1);
            exec(argv[p],arg);
            exit(1);
        } else {
            wait((int*)0);
        }
        if(cnt < n) break;
    }
    exit(0);
}

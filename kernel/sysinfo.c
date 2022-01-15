#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "syscall.h"
#include "defs.h"
#include "sysinfo.h"



uint64
sys_sysinfo(void)
{
  uint64 addr;
  if(argaddr(0, &addr) < 0)
    return -1;
  
  return sysinfo((struct sysinfo *)addr);
}
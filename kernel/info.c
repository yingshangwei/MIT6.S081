#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "defs.h"
#include "sysinfo.h"
#include "proc.h"

int
sysinfo(struct sysinfo * pinfo) {
  struct  sysinfo sinfo;
  sinfo.nproc = get_used_processes_count();
  sinfo.freemem = get_freememory_count();

  struct proc *p = myproc();
  if(copyout(p->pagetable, (uint64)pinfo, (char*)&sinfo, sizeof(sinfo)) < 0)
    return -1;
  return 0;
}
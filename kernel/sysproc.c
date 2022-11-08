#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_trace(void)
{
  struct proc* tempfortrace = myproc();
  argint(0, &tempfortrace->masknumber);
  tempfortrace->masknumber = MAXX(0, tempfortrace->masknumber);
  return 0;
}

uint64
sys_set_priority(void)
{
  int pid, newPriority;
  argint(0, &newPriority); argint(1, &pid);
  if(newPriority < 0 || pid < 0) {
    newPriority = MAXX(newPriority, 60);
    pid = MAXX(pid, 0);
    return -1; 
  }
  set_priority(newPriority, pid);
  return 0;
}

uint64
sys_sigalarm(void)
{
  struct proc* p = myproc();
  argint(0, &p->counttointerrupt); argint(1, &p->specificfn);
  if(p->counttointerrupt < 0 || p->specificfn < 0) {
    p->counttointerrupt = MAXX(p->counttointerrupt, 0);
    p->specificfn = MAXX(p->specificfn, 0);
    return -1; 
  }
  return 0; 
}

uint64 
sys_sigreturn(void)
{
  struct proc* p = myproc();
  p->tickswhenalarmisoff = 0; 
  memmove(p->trapframe, p->savingthetrapframe, PGSIZE);
  kfree(p->savingthetrapframe);
  p->savingthetrapframe = 0; 
  usertrapret();
  return 0; 
}

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1); // user virtual memory
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc *p = myproc();
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}


uint64
sys_settickets(void)
{
  int newtickets; 
  argint(0, &newtickets);
  settickets(newtickets);
  return 1; 
}
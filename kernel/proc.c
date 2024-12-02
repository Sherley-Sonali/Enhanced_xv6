#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "fs.h"
#include "fcntl.h"
struct cpu cpus[NCPU];

struct proc proc[NPROC];
#ifdef MLFQ
struct priority_queues priority_queues[4];
#endif

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[];
// trampoline.S
// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

#ifdef LBS
int the_time;
int pick_lottery(int ub)
{
  uint64 seed = (uint64)ticks;
  seed = seed ^ (seed << 5) ^ (seed >> 17) ^ (seed << 13);

  seed = seed % ub;
  return seed;

}
int the_ticket(){
  struct proc *p;
  int runnable_procs = 0;
    for (p = proc; p < &proc[NPROC]; p++)
    {
      if (p->state == RUNNABLE)
      {
        runnable_procs += p->tickets;
      }
    }
    int winner = pick_lottery(runnable_procs);
    for(p = proc; p < &proc[NPROC]; p++)
    {
      if(p->state == RUNNABLE)
      {
        if(p->tickets > winner)
        {
          the_time = p->start_time;
          return p->tickets;
        }
        else
        {
          winner = winner - p->tickets;
        }
      }
    }
    return 0;
}
#endif


#ifdef MLFQ
void mlfq_remove(struct proc *p, int queue_no) {
    int i;
    int found = 0;

    // Iterate through the queue to find the process
    for (i = 0; i < priority_queues[queue_no].ptr2; i++) {
        if (priority_queues[queue_no].Process[i] == p) {
            found = 1;
            break;
        }
    }

    if (!found) {
        return;
    }

    // Shift all processes after the removed process to the left
    for (int j = i; j < priority_queues[queue_no].ptr2 - 1; j++) {
        priority_queues[queue_no].Process[j] = priority_queues[queue_no].Process[j + 1];
    }

    // Decrease the ptr2 pointer (queue size)
    priority_queues[queue_no].ptr2--;

    // Nullify the last entry (optional for safety)
    priority_queues[queue_no].Process[priority_queues[queue_no].ptr2] = 0;
}


void enque_back(struct proc *p, int qid)
{
  if (priority_queues[qid].ptr2 >= NPROC)
  {
  panic("mlf_enqueue(): invalid params passed");
  }
  priority_queues[qid].Process[priority_queues[qid].ptr2] = p;
  priority_queues[qid].ptr2++;
  p->qid = qid;
  p->proc_no = (priority_queues[qid].ptr2) - 1;
  p->inq = 1;
  priority_queues[qid].size++;
}
// Priority boost logic
void priorityboost() {
  if(ticks % 48 != 0 ){return;}
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++) {
        // Ignore UNUSED, SLEEPING, and ZOMBIE processes
        if (p->state == UNUSED || p->state == SLEEPING || p->state == ZOMBIE) {
            continue;
        }

        // If a process is in a lower queue (not queue 0), move it up by one queue
        if (p->qid > 0) {
            p->qid=0;  // Move the process to a higher priority queue
            enque_back(p, p->qid);  // Reinsert the process in the higher queue
            p->inq = 1;  // Mark the process as enqueued
            // Optionally, log the priority boost
            // log_to_file(p->pid, ticks, p->qid); 
        }

    }
}
struct proc *dequeue(int qid)
{
  if (priority_queues[qid].ptr2 < 0)
  {
    panic("que empty");
  }
  struct proc *p = priority_queues[qid].Process[0];
  priority_queues[qid].Process[0] = 0;

  for (int i = 0; i < NPROC - 1; i++)
  {
    priority_queues[qid].Process[i] = priority_queues[qid].Process[i + 1];
  }
  priority_queues[qid].ptr2--;
  p->inq = 0;
  priority_queues[qid].size--;
  return p;
}
// void log_to_file(int pid, int time, int qid, int rtime)
// {
//   char *filename = "mlfq_log.txt";
//   char *que_name[] = {"Q0", "Q1", "Q2", "Q3"};
//   char *state[] = {"RUNNING", "SLEEPING", "RUNNABLE", "UNUSED", "ZOMBIE"};
//   char *mode[] = {"USER", "KERNEL"};
//   char *log = kalloc();
//   int len = 0;
//   len += sprintf(log + len, "PID: %d, TIME: %d, QUE: %s, RTIME: %d\n", pid, time, que_name[qid], rtime);
//   int fd = open(filename, O_CREATE | O_RDWR);
//   if (fd < 0)
//   {
//     panic("log_to_file(): file open failed");
//   }
//   if (write(fd, log, len) != len)
//   {
//     panic("log_to_file(): write failed");
//   }

//   close(fd);
//   kfree(log);
// }

void enque_top(struct proc *p, int qid)
{
  p->qid = qid;
  priority_queues[qid].ptr2++;
  p->inq = 1;
  priority_queues[qid].size++;
  p->proc_no = 0;
  for (int i = priority_queues[qid].size-1; i >= 0; i--)
    priority_queues[qid].Process[i + 1] = priority_queues[qid].Process[i];
  priority_queues[qid].Process[0] = p;
}

void init_que()
{
  int time_slice_for_level[] = {1, 4, 8, 16};
  for (int i = 0; i < 4; i++)
  {
    priority_queues[i].ptr1 = -1;
    priority_queues[i].ptr2 = 0;
    for (int j = 0; j < NPROC; j++)
      priority_queues[i].Process[j] = 0;
    
    priority_queues[i].size = 0;
    priority_queues[i].time_slice_for_level = time_slice_for_level[i];
  }
}
#endif

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table.
void procinit(void)
{
  struct proc *p;

  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    initlock(&p->lock, "proc");
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int allocpid()
{
  int pid;

  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc *
allocproc(void)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == UNUSED)
    {
      goto found;
    }
    else
    {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;

  // Allocate a trapframe page.
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if (p->pagetable == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;
  p->rtime = 0;
  p->etime = 0;
#ifdef LBS
  p->tickets = 1;        // default number of tickets
  p->start_time = ticks; // start time of the process
#endif

#ifdef MLFQ
  p->qid = 0;
  p->w_time = 0;
  p->inq = 0;
  //log_to_file(p->pid, ticks, p->qid, p->rtime);
#endif
  p->ctime = ticks;
  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if (p->trapframe)
    kfree((void *)p->trapframe);
  p->trapframe = 0;
  if (p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
#ifdef LBS
  p->tickets = 0;
  p->start_time = 0;
#endif
#ifdef MLFQ
  p->inq = 0;
#endif
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
}

// Create a user page table for a given process, with no user memory,
// but with trampoline and trapframe pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if (pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
               (uint64)trampoline, PTE_R | PTE_X) < 0)
  {
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe page just below the trampoline page, for
  // trampoline.S.
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
               (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
  {
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// assembled from ../user/initcode.S
// od -t xC ../user/initcode
uchar initcode[] = {
    0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
    0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
    0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
    0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
    0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
    0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00};

// Set up first user process.
void userinit(void)
{
  struct proc *p;
#ifdef MLFQ
  init_que();
#endif
  p = allocproc();
  initproc = p;

  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;     // user program counter
  p->trapframe->sp = PGSIZE; // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;

  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int growproc(int n)
{
  uint64 sz;
  struct proc *p = myproc();

  sz = p->sz;
  if (n > 0)
  {
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    {
      return -1;
    }
  }
  else if (n < 0)
  {
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if ((np = allocproc()) == 0)
  {
    return -1;
  }

  // Copy user memory from parent to child.
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
  {
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for (i = 0; i < NOFILE; i++)
    if (p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  release(&np->lock);
#ifdef LBS
  // Set the number of tickets of the child process to be the same as the parent process
  np->tickets = p->tickets;
#endif
  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void reparent(struct proc *p)
{
  struct proc *pp;

  for (pp = proc; pp < &proc[NPROC]; pp++)
  {
    if (pp->parent == p)
    {
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void exit(int status)
{
  struct proc *p = myproc();

  if (p == initproc)
    panic("init exiting");

  // Close all open files.
  for (int fd = 0; fd < NOFILE; fd++)
  {
    if (p->ofile[fd])
    {
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);

  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;
  p->etime = ticks;

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int wait(uint64 addr)
{
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (pp = proc; pp < &proc[NPROC]; pp++)
    {
      if (pp->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if (pp->state == ZOMBIE)
        {
          // Found one.
          pid = pp->pid;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
                                   sizeof(pp->xstate)) < 0)
          {
            release(&pp->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(pp);
          release(&pp->lock);
          release(&wait_lock);
          return pid;
        }
        release(&pp->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || killed(p))
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
  int ticks_since_boost = 0;
  if (ticks_since_boost < 0)
    ticks_since_boost = 0;
  c->proc = 0;
  for (;;)
  {
    intr_on();


#ifdef MLFQ
    // Boost all processes to the topmost queue (queue 0)
priorityboost();  


struct proc *sel_p_to_run = 0;
    for (p = proc; p < &proc[NPROC]; p++)
    {
      if (p->state == RUNNABLE && p->inq == 0)
      {
        int qid = p->qid;
        enque_back(p, qid);
        //log_to_file(p->pid, ticks, qid);
        p->inq = 1;
      }
    }
    for (int i = 0; i < 4; i++)
    {
      if (sel_p_to_run != 0)
      {
        break;
      }
      while (priority_queues[i].ptr2 > 0)
      {
        sel_p_to_run = dequeue(i);
        sel_p_to_run->inq = 0;
        if (sel_p_to_run->state == RUNNABLE)
        {
          if(sel_p_to_run->qid ==3)
          enque_back(sel_p_to_run, sel_p_to_run->qid);
          else
          enque_top(sel_p_to_run, sel_p_to_run->qid); // Enable RRS in Q3
          break;
        }
        // else if (sel_p_to_run->state == RUNNABLE && p->qid == 3)
        // {
        //    enque_back(sel_p_to_run, sel_p_to_run->qid);
        //   break;
        // }
      }
    }
    if (sel_p_to_run != 0)
    {
      if (sel_p_to_run->state == RUNNABLE)
      {
        acquire(&sel_p_to_run->lock);
        sel_p_to_run->state = RUNNING;
        c->proc = sel_p_to_run;
        swtch(&c->context, &sel_p_to_run->context);
        c->proc = 0;
        release(&sel_p_to_run->lock);
      }

    }
    ticks_since_boost++;
#endif
#ifdef LBS
    int the_ticket_win = the_ticket();
    for (p = proc; p < &proc[NPROC]; p++)
    {
    acquire(&p->lock);
      if (p->state == RUNNABLE && p->start_time <= the_time)
      {
        if (p->tickets == the_ticket_win)
        {
          p->state = RUNNING;
          c->proc = p;
          swtch(&c->context, &p->context);
          c->proc = 0;
          release(&p->lock);
          break;
        }
      }

      release(&p->lock);
    }
  
#endif

#ifdef DEFAULT
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      }
      release(&p->lock);
    }
#endif
  }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void sched(void)
{
  int intena;
  struct proc *p = myproc();

  if (!holding(&p->lock))
    panic("sched p->lock");
  if (mycpu()->noff != 1)
    panic("sched locks");
  if (p->state == RUNNING)
    panic("sched running");
  if (intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
#ifdef MLFQ
  if (p->state != SLEEPING)
  {
#endif
    p->state = RUNNABLE;
#ifdef MLFQ
  }
#endif
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first)
  {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();

  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
      {
        p->state = RUNNABLE;
      }
      release(&p->lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).id
int kill(int pid)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->pid == pid)
    {
      p->killed = 1;
      if (p->state == SLEEPING)
      {
        // Wake process from sleep().
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

void setkilled(struct proc *p)
{
  acquire(&p->lock);
  p->killed = 1;
  release(&p->lock);
}

int killed(struct proc *p)
{
  int k;

  acquire(&p->lock);
  k = p->killed;
  release(&p->lock);
  return k;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if (user_dst)
  {
    return copyout(p->pagetable, dst, src, len);
  }
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if (user_src)
  {
    return copyin(p->pagetable, dst, src, len);
  }
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
  static char *states[] = {
      [UNUSED] "unused",
      [USED] "used",
      [SLEEPING] "sleep ",
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
#ifdef MLFQ
    printf("%d %s %s %d %d\n", p->pid, state, p->name, p->qid, ticks - p->stime);
#endif
#ifdef LBS
    printf("%d %s %s %d %d\n", p->pid, state, p->name, p->tickets, ticks - p->start_time);
#endif
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (np = proc; np < &proc[NPROC]; np++)
    {
      if (np->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
        {
          // Found one.
          pid = np->pid;
          *rtime = np->rtime;
          *wtime = np->etime - np->ctime - np->rtime;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                   sizeof(np->xstate)) < 0)
          {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || p->killed)
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

void update_time()
{
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    {
      p->rtime++;
#ifdef MLFQ
      p->stime++;
#endif
#ifndef LBS
p->start_time = ticks;
#endif
    }
    else if (p->state == RUNNABLE)
    {
#ifdef MLFQ
      p->w_time++;
#endif
    }
    release(&p->lock);
  }


}

#ifdef MLFQ

#endif

  #ifdef MLFQ
#ifdef PLOT
struct  proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p->state == RUNNABLE || p->state == RUNNING)
    {
      if(ticks % 4 == 0)
      printf("PLOT %d %d %d %d\n", p->pid, ticks, p->qid, p->state);
    }
  }
#endif
#endif
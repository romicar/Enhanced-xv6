# Assignment 4 : Enhancing XV-6
xv6 is a re-implementation of Dennis Ritchie's and Ken Thompson's Unix
Version 6 (v6).  xv6 loosely follows the structure and style of v6,
but is implemented for a modern RISC-V multiprocessor using ANSI C.

> Keval Jain (2021111030)
> Romica Raisinghani (2021101053)

**RUNNIG THE KERNEL**

To run the kernel for different scheduling algorithms use the following command lines:

* `make qemu` runs the kernel for the default scheduling algorithm ROUND ROBIN
* `make qemu SCHEDULER=FCFS` runs the kernel in FCFS (First Come First Serve)
* `make qemu SCHEDULER=LBS` runs the kernel in LBS (Lottery Based Scheduler)
* `make qemu SCHEDULER=PBS` runs the kernel in PBS (Priority Based Scheduler)
* `make qemu SCHEDULER=MLFQ` runs the kernel in MLFQ (Multi Level Feedback Queue)

> *Make sure to run th…
[23:19, 14/10/2022] Romica: # Assignment 4 : Enhancing XV-6
xv6 is a re-implementation of Dennis Ritchie's and Ken Thompson's Unix
Version 6 (v6).  xv6 loosely follows the structure and style of v6,
but is implemented for a modern RISC-V multiprocessor using ANSI C.

*RUNNIG THE KERNEL*

To run the kernel for different scheduling algorithms use the following command lines:

* `make qemu` runs the kernel for the default scheduling algorithm ROUND ROBIN
* `make qemu SCHEDULER=FCFS` runs the kernel in FCFS (First Come First Serve)
* `make qemu SCHEDULER=LBS` runs the kernel in LBS (Lottery Based Scheduler)
* `make qemu SCHEDULER=PBS` runs the kernel in PBS (Priority Based Scheduler)
* `make qemu SCHEDULER=MLFQ` runs the kernel in MLFQ (Multi Level Feedback Queue)

> Make sure to run the `make clean` command whenever you want to switch to a different scheduler

---


## <u>Specification 1: System Calls</u>

### System Call 1 : `trace`

Added the system call `trace` and an accompanying user program `strace`

*Running the command*

> strace mask command [args]


### Features:

* The function `trace` takes one argument,an integer mask, whose bits specify which system
calls to trace.
* Checks if the ith bit in the mask is set or not by `masknumber & (1 << i) == 1` and if it does, then it looks for the corresponding system call number defined in syscall.h
* Prints out a line when each system call is about to return depending if the system call's number is set in the mask
* The output line for a particular system call looks like:
> `sys_call_num` : syscall `sys_call_name` (`space separated values of system call arguments in decimal`) -> `return_value_of_system_call`

### Implementation:

1. Defined the prototypes of the function in the respective files as follows:

* `$U/_strace` in Makefile under UPROGS
* `exec_trace(char, char *, int)` in defs.h
* `masknumber` in proc.h
* `trace(int)` in user.h
* `entry("trace")` in usys.pl
* `SYS_trace` in syscall.h

2. Initialized the `maknumber` for each process to zero in `procinit` function defined in proc.c

3. Implemented a user program `strace.c` in the user directory which calls the `trace` function with the argument `masknumber` which then calls `exec` to execute the command provided through the command line

4. Mapped the system call number from syscall.h to the function that handles the system call

5. Created a struct `systemcalled` in syscall.c that stores the system call name and the number of arguments that the system call takes

6. Created an array of struct `systemcalled` named `findinfo[]` that maps the system call number to the system call name and its number of arguments

7. Printed the traced information by modifying the `syscall()` function in syscall.c corresponding to the system call whose number is set in the `mask` provided through the command line. Moreover, the value of register `a0` is saved to store the first argument before executing the system call as its value is overwritten by the return value of the system call
---
### System Call 2 : `sigalarm` and `sigreturn`

This feature periodically alerts a process as it
uses CPU time.
 Added a system call `sigalarm(interval, handler)`.If an application calls `alarm(n, fn)`, then after every `n` "ticks" of CPU time that the program consumes,the kernel will cause application function `fn` to be called. When `fn` returns,the application will resume where it left off.

 ### Implementation:

1. Declared the prototypes of the function in the respective files as follows:

* `counttointerrupt`,`tickswhenalarmison`,`tickswhenalarmisoff`,`specificfn` in proc.h
* `sigalarm` and `sigreturn` in user.h
* `entry("sigalarm")` and `entry("sigalarm")` in usys.pl
* `SYS_sigalarm` and `SYS_sigreturn` in syscall.h

2. The variables are defined as follows:
* `counttointerrupt`: will store the alarm time period
* `tickswhenalarmison`: will update the ticks for a running process when its running the alarm
* `tickswhenalarmisoff`: will update the ticks for a running process when the alarm is off
* `specificfn`: this is a pointer to the handler
* `savingthetrapframe`: saves the state of the process by saving the trapframe

3. When `tickswhenalarmisoff` exceeds `counttointerrupt`, then we save the current trapframe and in `sigalarm` point the processes program counter to the handler, while returning in `sigreturn`, we return the process state by the saved updating the trapframe to the saved value. 


---

## <u>Specification 2: Scheduling</u>

The default scheduler of xv6 architecture is ROUND ROBIN.
The modified xv6 contains four other scheduling policies each of which are defined in the Makefile by declaring a flag `SCHEDULER_FLAG` that checks for the different scheduling polices which can be:
1. FCFS (First Come First Serve)
2. LBS (Lottery Based Scheduler)
3. PBS (Priority Based Scheduler)
4. MLFQ (Multi Level Feedback Queue)

### <u>*First Come First Serve (FCFS)*</u>
A non-preemptive scheduling algorithm that selects a process with the lowest creation time (creation time
refers to the tick number when the process was created). This means that the process that arrived first is selected first for execution. The process will run until it no
longer needs CPU time.

### Implementation:

1. Added a variable `cTimee` in struct proc in proc.h which is initialized to the current tick number defined as `ticks` in the allocproc() function defined in proc.c 
2. Modified the function scheduler() in proc.c that checks for the different scheduling algorithms based on the flag provided in command line
3. Initialized a variable `respectivecreationtime` to 1e16 which will be the upperbound for the creation time for all processes
3. Initialized a variable `respectivecreationtime` to 1e16 which will be the upperbound for the creation time for all processes
4. In the function scheduler() in proc.c,iterated through the process table to check for each process by acquiring the lock. If the process is RUNNABLE and its creation time is less than the current value of `respectivecreationtime`, then release the previous lock and hold onto the current process along with updating the `respectivecreationtime` to the current process' creation time.We then context switch to the held process if any.
5. To make the process non-preemptive, we remove the condition of `(which dev == 2)` in usertrap() and kerneltrap() functions in trap.c for this scheduling algorithm

---
### <u>*Lottery Based Scheduler (LBS)*</u>
A preemptive scheduling algorithm that assigns a time slice to the process randomly in
proportion to the number of tickets it owns.By default, each process should get one ticket. Implemented a system call `settickets` that raises the number of tickets by the calling process and thus receive a higher proportion of CPU cycles

### Implementation:

1. Added a new variable `numberoftickets` in struct proc defined in proc.h that determines the number of tickets held by a particular process
2. Defined a variable `totalticketcnt` that is initialized to zero and stores the total number of tickets by all the processes
3. Implemented a system call `settickets` which sets the number of tickets of
the calling process. By default, each process should get one ticket; calling this routine
makes it such that a process can raise the number of tickets it receives, and thus
receive a higher proportion of CPU cycles
3. In the function scheduler() defined in proc.c, iterated through the process table to check for `RUNNABLE` processes and if found increase the `totalticketcnt` by the number tickets that process hold
4. The lottery ticket is picked up by a random number generator function named `getrandomnumber()` defined in proc.c
5. Iterate through the process table again in the scheduler() function to check for `RUNNABLE` processes, if found then search for the process that matches the lottery ticket number with the range of the number of tickets that process holds
6. Release the lock if such a process is not found or context switch to the held process if any







---
### <u>*Priority Based Scheduler (PBS)*</u>
A non-preemptive scheduling algorithm that selects a process with the lowest dynamic programming. In case of ties,the number of times the process has been scheduled to break the tie.If the tie
remains, use the start-time of the process to break the tie

The dynamic priority of a process is an integer in the range [0, 100] and is calculated as :

> `DP = max(0, min(SP - niceness + 5, 100))`

Here,
- Static pririty (SP) is an integer in the range [0, 100] and is set to 60 by default during creation of a process (Smaller the value higher the priority)

- `niceness` is an integer in the range [0, 10] that measures what percentage of
the time the process was sleeping and is calculated as :

> `niceness = (ticks spent in (sleeping) state) * 10 /(ticks spent in (running + sleeping) state)`


### Implementation:

1. Added the following variables in struct proc defined in proc.h
* `total_runtime` : total running time since process creation
* `previous_runtime` : number of ticks spent `RUNNING` since the last time it was scheduled
* `previous_sleeptime` : number of ticks spent `SLEEPING` since the last time it was scheduled
* `new_proc` : binary value if it is 1 then we should assign the default niceness value as 5

2. Initialize the variables in allocproc() defined in proc.c appropriately

3. In the function scheduler() in proc.c,iterated through the process table to check for `RUNNABLE` processes, and if the current process is better(as per the algorithm described above after all the tie breaks) than the previous process whose lock was acquired, then we release the old lock and acquire the new lock. We context switch into the process if it was held.

4. Created a new function updateprocesstimes() in proc.c that iterates through the process table and updates `total_runtime`,`previous_runtime`,`previous_sleeptime` and `new_proc` as required

5. Implemented calculate_dp() function in proc.c as per the aforementioned formula

6. To make the scheduling non-preemptive, disabled the timed interrupt (`which_dev == 2`) in usertrap() and kerneltrap() functions in trap.c

7. Implemented a system call set_priority in proc.c that sets the static priority of a process with the help of the function calculate_dp() 
---
### *Multi-Level Feedback Queue (MLFQ)*

A preemptive scheduling algorithm that allows processes to move
between different priority queues based on their behavior and CPU bursts
* If a process uses too much CPU time, it is pushed to a lower priority queue, leaving
I/O bound and interactive processes in the higher priority queues
* To prevent starvation, implement aging

The MLFQ scheduling policy has 5 queues numbered from 0 to 4 representing the highest to lowest priority.
When a new process enters the system it gets added to the highest priority queue. It is then assigned a time quanta specific to its queue level (`1 << i` ticks for level `i`). After the time quanta, if the process happens to exhaust it, it implies that the process is CPU bound and hence, is moved to the queue which is one lower in priority. If not, then the process stays in the same queue.

### Implementation:

1. Implemented the basic queue functionalities in proc.c by defining functions such as : 
* queueesizee that returns the size of a particular queue
* addtoq that adds a new process to the end of the queue
* removeparticularfromq that takes the process pid as an argument and removes that particular process from the queue

2. Added the following variables in struct proc defined in proc.h :
* `pcurrentqlevel` : determines the level of a particular queue (ranging from 0 to 4)
* `ptimeqenter` : tick value when the process enters a queue
* `isthispinq` : binary value to determine if a process if present in the queue or not
* `checkfornextq` : set to `1<<pcurrentqlevel` whenever the process is scheduled

3. Initialize the above variables appropriately in allocproc function in proc.c

4. In the function scheduler() in proc.c,iterate through the process table to check for `RUNNABLE` process and if found, insert it to the appropriate queue

5. Update `checkfornextq` for every clock interrupt in updateprocesstimes() in proc.c
and set `ptimeqenter` and `checkfornextq` to the current tick value everytime a process is scheduled

6. If a particular process has exhausted its time slice, then increment its level(thereby, decreasing the priority) by 1 and call yield() function to reschedule the process. If the said condition doesn't hold then the process remains in the same queue. All this to be done in usertrap() and kerneltrap() functions in trap.c

7. In the same usertrap() and kerneltrap() functions in trap.c, check if there is a process in a higher priority queue. If it does, then call yield() to schedule it

---

*Performance Comaparison between different scheduling algorithms*

The average run time and average wait time for different scheduling algorithms was calculated on different cpus and tested a number of times by runnning `schedulertests` as the command line argument for different algorithms

1. *Default: Round Robin*
> Average run time: 114 & Average wait time: 15

2. *FCFS (First Come First Serve)*
> Average run time: 39 & Average wait time: 34

3. *LBS (Lottery Based Scheduler)*
> Average run time: 118 & Average wait time: 8

4. *PBS (Priority Based Scheduler)*
> Average run time: 106 & Average wait time: 16

5. *MLFQ (Multi Level Feedback Queue)*
> Average run time: 149 & Average wait time: 17

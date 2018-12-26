[TOC]
# 练习1
## mmio_map_region
该函数用于在内存中预留一部分空间给IO来访问LAPIC（局部高级可编程中断控制器）单元。
根据注释可知此处页面的权限位应该另外加上PTE_PCD|PTE_PWT，使得cache不缓存这部分的内容，采用直接写回的策略。
# 练习2
## 应用处理器(AP)启动过程
在boot_aps()中启动AP，该函数遍历cpus数组，启动所有的AP，当一个AP启动后会执行kern/mpentry.S中的代码，在mepentry.S的代码最后跳转到mp_main()中。该函数为当前AP设置全局描述符表GDT（也就是页表项），中断向量表，初始化局部APIC(LAPIC)单元。最后设置cpus数组中当前CPU对应的CpuInfo结构的cpu_status为CPU_STARTED。
## 问题1
>逐行比较 kern/mpentry.S 和 boot/boot.S。牢记 kern/mpentry.S 和其他内核代码一样也是被编译和链接在 KERNBASE 之上运行的。那么，MPBOOTPHYS 这个宏定义的目的是什么呢？为什么它在 kern/mpentry.S 中是必要的，但在 boot/boot.S 却不用？换句话说，如果我们忽略掉 kern/mpentry.S 哪里会出现问题呢？ 提示：回忆一下我们在 Lab 1 讨论的链接地址和装载地址的不同之处。

当时在lab1中自己对链接地址和装载地址的理解是：
>链接地址是通过编译器链接器处理后形成的可执行文件理论上应该执行的地址，即逻辑地址。加载地址则是可执行文件真正被装入内存后运行的地址，即物理地址。在运行boot loader时，boot loader中的链接地址（逻辑地址）和加载地址（物理地址）是一样的，但是当进入到内核程序后，这两种地址就不再相同了。

再看mpentry.S的注释可知，它不需要启动第20根总线。它使用MPBOOTPHYS来计算符号的绝对地址，而不是依靠链接器来填充它们。
kern/mpentry.S是运行在KERNBASE之上的，也就是里面的地址全是大于0xf0000000，实模式下是无法寻址找到的。
`#define MPBOOTPHYS(s) ((s) - mpentry_start + MPENTRY_PADDR)`
可以看出MPBOOTPHYS是将从mpentry_start开始的地址映射到MPENTRY_PADDR开始的地址。在kern/init.c中，boot_aps()函数完成了这部分地址映射内容的拷贝。
```
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
```
所以通过MPBOOTPHYS宏的转换，就能在实模式下运行mpentry_start这部分的代码，而boot.S中没有类似的宏是因为它的代码在实模式下能被直接寻址到。
# 练习3
## mem_init_mp
该函数是根据inc/memlayout.h将每个CPU堆栈映射在KSTACKTOP开始的区域。每个CPU的堆栈都留了KSTKSIZE大小，也就是8个PGSIZE的空间。同时来预留了KSTKGAP，也是8个PGSIZE大小的空间防止堆栈溢出时覆盖了下一个CPU的堆栈。
# 练习4
## trap_init_percpu
初始化每个CPU的任务状态段 (Task State Segment,TSS)并向全局描述符表(Global Descriptor Table,GDT)中加入对应的页表项。
关于GDT和LDT从lab1就开始看见，如今回顾了lab2以及参考了下面的博客总算懂了[https://blog.csdn.net/wrx1721267632/article/details/52056910](https://blog.csdn.net/wrx1721267632/article/details/52056910)
>其实GDT就是lab2中的页目录项

GD_KD 内核数据段的偏移量
### CpuInfo
记录每个CPU当前状态
```
// Per-CPU state
struct CpuInfo {
	uint8_t cpu_id;                 // Local APIC ID; index into cpus[] below
	volatile unsigned cpu_status;   // The status of the CPU
	struct Env *cpu_env;            // The currently-running environment.
	struct Taskstate cpu_ts;        // Used by x86 to find stack for interrupt
};
```
>page fault happen in kernel mode!

# 练习5
## JOS锁机制
### spinlock
锁的数据结构在kern/spinlock.h中定义:
```
// Mutual exclusion lock.
struct spinlock {
	unsigned locked;       // Is the lock held?

#ifdef DEBUG_SPINLOCK
	// For debugging:
	char *name;            // Name of lock.
	struct CpuInfo *cpu;   // The CPU holding the lock.
	uintptr_t pcs[10];     // The call stack (an array of program counters)
	                       // that locked the lock.
#endif
};
```
### spin_lock && spin_unlock
获取锁，释放锁的操作在kern/spinlock.c中定义：
```
// Acquire the lock.
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
	}

	lk->pcs[0] = 0;
	lk->cpu = 0;
#endif

	// The xchg serializes, so that reads before release are 
	// not reordered after it.  The 1996 PentiumPro manual (Volume 3,
	// 7.2) says reads can be carried out speculatively and in
	// any order, which implies we need to serialize here.
	// But the 2007 Intel 64 Architecture Memory Ordering White
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
```
JOS采用了自旋锁模式。对于spin_lock()获取锁的操作，使用xchg这个原子操作，xchg()封装了该指令，交换lk->locked和1的值，并将lk-locked原来的值返回。如果lk-locked原来的值不等于0，说明该锁已经被别的CPU申请了，继续执行while循环吧。对于spin_unlock()释放锁的操作，直接将lk->locked置为0，表明使用完毕，这个锁可以被其他CPU获取。
#### xchg
在inc/x86.h中定义
```
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
			"+m" (*addr), "=a" (result) :
			"1" (newval) :
			"cc");
	return result;
}
```
其中lock确保了操作的原子性
## 问题 2
>看起来使用全局内核锁能够保证同一时段内只有一个 CPU 能够运行内核代码。既然这样，我们为什么还需要为每个 CPU 分配不同的内核堆栈呢？请描述一个即使我们使用了全局内核锁，共享内核堆栈仍会导致错误的情形。

虽然全局内核锁能够保证同时只能有一个CPU运行在内核模式下，看起来只有一个CPU能使用到内核堆栈。但是如果这时其他CPU的代码触发了中断机制，根据lab3的中断实现，我们可以知道，进程进入内核前会自动push将Trapframe结构中的所有数据压入内核栈中，虽然这个CPU此时还未能进入内核态，但是它已经对共享的内核堆栈造成了影响。
# 练习6
## sched_yield
实现多CPU的情况下对进程轮转调度
## JOS轮转调度
JOS轮转调度思想就是当env[i]进程来调用sched_yield()函数的时候，表示进程i要让出CPU了，此时，系统会从i开始，不停的往下寻找状态为runnable的进程，然后执行那个进程。如果遍历了所有的进程队列，发现没有进程满足运行条件，此时分两种情况，若原进程满足运行条件，即状态是runnable,则运行原进程，若原进程不满足运行条件，即原进程被阻塞或者被杀死，则调用 sched_halt()， 让CPU停止工作，直到下次时钟中断，再重新执行上面的过程。
>make run-yield CPUS=2
## 问题 3
>在你实现的 env_run() 中你应当调用了 lcr3()。在调用 lcr3() 之前和之后，你的代码应当都在引用 变量 e，就是 env_run() 所需要的参数。 在装载 %cr3 寄存器之后， MMU 使用的地址上下文立刻发生改变，但是处在之前地址上下文的虚拟地址（比如说 e ）却还能够正常工作，为什么 e 在地址切换前后都可以被正确地解引用呢？

lab3中的函数env_setup_vm()，每次进程创建的时候页目录项都是直接拷贝内核的页目录项，因此所有用户环境的页目录表中和内核相关的页目录项都是一样的。进程ENV的地址e存储在内核栈中，所以尽管上下文切换页表项替换，但是e在上下文的页表项中地址映射到同一物理地址上。
## 问题 4
>无论何时，内核在从一个进程切换到另一个进程时，它应当确保旧的寄存器被保存，以使得以后能够恢复。为什么？在哪里实现的呢？

因为在进程进入内核之前，会自动push将Trapframe结构中的所有数据压入内核栈中，而当从内核态回到用户态时，会恢复之前保存的信息。
保存发生在kern/trapentry.S，恢复发生在kern/env.c。
>保存

```
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

_alltraps:
	pushl %ds
	pushl %es
	pushal

	mov $GD_KD,%eax
	mov %eax,%ds
	mov %eax,%es
	
	pushl %esp  //压入trap()的参数tf，%esp指向Trapframe结构的起始地址
	call trap
```
>恢复

```
void
env_pop_tf(struct Trapframe *tf)
{
    // Record the CPU we are running on for user-space debugging
    curenv->env_cpunum = cpunum();

    asm volatile(
        "\tmovl %0,%%esp\n"    // 恢复栈顶指针
        "\tpopal\n"    // 恢复其他寄存器
        "\tpopl %%es\n"    // 恢复段寄存器
        "\tpopl %%ds\n"
        "\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
        "\tiret\n"
        : : "g" (tf) : "memory");
    panic("iret failed");  /* mostly to placate the compiler */
}
```
# 练习7
## sys_exofork
该系统调用创建一个几乎完全空白的新进程：它的用户地址空间没有内存映射，也不可以运行。这个新的进程拥有和创建它的父进程（调用这一方法的进程）一样的寄存器状态。在父进程中，sys_exofork 会返回刚刚创建的新进程的 envid_t（如果进程分配失败，返回一个负的错误代码）。
>需要注意的是如何让子进程返回0

sys_exofork()的定义与实现在 inc/lib.h 中
```
// This must be inlined.  Exercise for reader: why?
static __inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	__asm __volatile("int %2"
		: "=a" (ret)
		: "a" (SYS_exofork),
		  "i" (T_SYSCALL)
	);
	return ret;
}
```
通过这段内联汇编代码可以得知sys_exofork的返回值存在eax中,根据 kern/trap.c 中的 trap_dispatch() 函数，这个返回值仅仅是存放在了父进程的 trapframe 中，还没有返回。而是在返回用户态的时候，即在 env_run() 中调用 env_pop_tf() 时，才把 trapframe 中的值赋值给各个寄存器。这时候 lib/syscall.c 中的函数 syscall() 才获得真正的返回值。因此，在这里对子进程 trapframe 的修改，可以使得子进程返回0。
## sys_env_set_status
将一个进程的状态设置为 ENV_RUNNABLE 或 ENV_NOT_RUNNABLE。通常用来在新创建的进程的地址空间和寄存器状态已经初始化完毕后将它标记为就绪状态。
注意无论何时调用 envid2env()，都应该把checkperm 参数赋为1。
## sys_page_alloc
分配一个物理内存页面，并将它映射在给定进程虚拟地址空间的给定虚拟地址上。
## sys_page_map
从一个进程的地址空间拷贝一个页的映射 (不是页的内容) 到另一个进程的地址空间，新进程和旧进程的映射应当指向同一个物理内存区域，使两个进程得以共享内存。

>最后需要记得在syscall中添加本练习中实现的系统调用
# make grade PartA && #if defined(TEST)
ENV_CREATE(user_yield, ENV_TYPE_USER);
只能写在#else里，写在#endif中不能通过测试

最后写个实验的总结，整个实验在干些什么，最好复习的时候能把之前的补上
# 练习8
## 写时拷贝
父进程将自己的页目录项和页表项复制给子进程，这样父进程和子进程就能访问相同的内容。并且将复制的页权限标记为只读，当其中某一个执行写操作时，发生缺页中断，内核就为缺页的进程复制这一物理页。这样既能做到地址空间隔离，又能节省了大量的拷贝工作。
## sys_env_set_pgfault_upcall
Env结构体中用变量env_pgfault_upcall来记录缺页处理函数入口。
# 练习9
## JOS异常堆栈
JOS 用户异常堆栈大小也是一个页面，栈顶被定义在虚拟地址 UXSTACKTOP 位置，所以用户异常堆栈可用的字节是 [UXSTACKTOP-PGSIZE, UXSTACKTOP-1]。
### JOS堆栈（目前）
>  
[KSTACKTOP, KSTACKTOP-KSTKSIZE]
内核态系统栈
[UXSTACKTOP, UXSTACKTOP - PGSIZE]
用户态错误处理栈
[USTACKTOP, UTEXT]
用户态运行栈

内核态系统栈是运行内核相关程序的栈，在有中断被触发之后，CPU会将栈自动切换到内核栈上来，而内核栈的设置是在kern/trap.c的trap_init_percpu()中设置的。
## page_fault_handler
这次处理的是缺页发生在用户空间的情况。
首先进入到内核，栈指针esp从用户运行栈切换到内核栈，进行中断处理分发，进入到page_fault_handler()，当确认是用户程序触发的page fault的时候(如果是内核触发直接触发panic了)，为其在用户错误栈里分配UTrapframe大小的空间。把栈指针esp切换到用户错误栈，运行响应的用户中断处理程序中断处理程序可能会触发另外一个同类型的中断，这个时候就会产生递归式的处理。处理完成之后，返回到用户运行栈。 
### UTrapframe
在trap.h中定义
```
struct UTrapframe {
	/* information about the fault */
	uint32_t utf_fault_va;	/* va for T_PGFLT, 0 otherwise */
	uint32_t utf_err;
	/* trap-time return state */
	struct PushRegs utf_regs;
	uintptr_t utf_eip;
	uint32_t utf_eflags;
	/* the trap-time stack to return to */
	uintptr_t utf_esp;
} __attribute__((packed));
```
### esp && ebp && eip
ESP：栈指针寄存器(extended stack pointer)，存放着一个指针，指向系统栈最上面一个栈的栈顶。
EBP：基址指针寄存器(extended base pointer)，存放着一个指针，指向系统栈最上面一个栈的底部。
eip：寄存器存放CPU将要执行的下一条指令存放的内存地址，当CPU执行完当前的指令后，从EIP寄存器中读取下一条指令，然后继续执行。
> x86是字节寻址= =

## 问题
>如果用户进程的异常堆栈已经没有空间了会发生什么？

在 inc/memlayout.h 中可以找到：
```
// Top of one-page user exception stack
#define UXSTACKTOP  UTOP
// Next page left invalid to guard against exception stack overflow;
```
![](/document/picture/7.png)
可知如果没有空间的时候会访问到空白的一页，访问无效，避免了堆栈溢出。
# 练习10

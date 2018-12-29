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
# 练习8
## 写时拷贝
父进程将自己的页目录项和页表项复制给子进程，这样父进程和子进程就能访问相同的内容。并且将复制的页权限标记为只读，当其中某一个执行写操作时，发生缺页中断，内核就为缺页的进程复制这一物理页。这样既能做到地址空间隔离，又能节省了大量的拷贝工作。
## sys_env_set_pgfault_upcall
Env结构体中用变量env_pgfault_upcall来记录缺页处理函数入口。
# 练习9
用户模式下缺页，首先进入到内核，栈指针esp从用户运行栈切换到内核栈，进行中断处理。进入到page_fault_handler，当确认是用户程序触发的page fault时，在用户错误栈里分配UTrapframe大小的空间。把栈指针esp切换到用户错误栈，运行响应的用户中断处理程序中断处理程序可能会触发另外一个同类型的中断，这个时候就会产生递归式的处理。处理完成之后，返回到用户运行栈。 
可以将用户自己定义的用户处理进程当作是一次函数调用。当缺页异常发生的时候，调用一个函数，但实际上还是当前这个进程，并没有发生变化。所以当切换到异常栈的时候，依然运行当前进程，但只运行中断处理函数，所以说此时的栈指针发生了变化，并且eip也发生了变化，同时还需要知道的是引发错误的地址在哪。这些都是要在切换到异常栈的时候需要传递的信息。和之前从用户栈切换到内核栈一样，这里是通过在栈上压入UTrapframe结构体，传递指针来完成信息传递的。
整体上讲，当正常执行过程中发生了页错误，那么栈的切换是
>用户运行栈—>内核栈—>异常栈

而如果在异常处理程序中发生了也错误，那么栈的切换是
>异常栈—>内核栈—>异常栈 

## JOS堆栈（目前）
>  
[KSTACKTOP, KSTACKTOP-KSTKSIZE]
内核态系统栈
[UXSTACKTOP-PGSIZE, UXSTACKTOP-1]
用户态错误处理栈
[USTACKTOP, UTEXT]
用户态运行栈

内核态系统栈是运行内核相关程序的栈，在有中断被触发之后，CPU会将栈自动切换到内核栈上来，而内核栈的设置是在kern/trap.c的trap_init_percpu()中设置的。
## page_fault_handler
这次处理的是缺页发生在用户空间的情况。修改当前进程的程序计数器和栈指针，然后重启这个进程，此时就会在用户错误栈上运行中断处理程序了。然后在中断处理程序运行结束之后，需要重新回到用户运行栈中。
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
相比于Trapframe，多了utf_fault_va来记录触发错误的内存地址。同时还少了es,ds,ss等，因为从用户态栈切换到异常栈，或者从异常栈再切换回去，实际上都是一个用户进程，所以不涉及到段的切换，不用记录。
### esp && ebp && eip
esp：栈指针寄存器(extended stack pointer)，存放着一个指针，指向系统栈最上面一个栈的栈顶。
ebp：基址指针寄存器(extended base pointer)，存放着一个指针，指向系统栈最上面一个栈的底部。
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
## 汇编语法
AT&T汇编语法参考了博客[https://www.cnblogs.com/orlion/p/5765339.html](https://www.cnblogs.com/orlion/p/5765339.html)
### $
汇编中$用来表示当前地址，后面跟上数字代表立即数
### *
直接寻址符号，就是直接给PC赋值某个地址，而不是加偏移量。
## pfentry.S
已有的代码先把esp当前的值压入栈，然后把_pgfault_handler的地址传给eax寄存器，然后用*直接跳转到eax寄存器里面的值，也就是直接跳转到_pgfault_handler（不是相对地址）。根据前面注释可知，全局变量_pgfault_handler指向了user文件中的handler函数（通过自己给定不同的handler函数用户自己选择了如何处理缺页异常）。
>最后把fault_va弹出栈。(其实只是移动esp指针，使得fault_va不在栈中而已)
>感觉没必要弹出fault_va?

然后需要用汇编语言实现：当从用户定义的处理函数返回之后，从用户错误栈直接返回到用户运行栈。
# 练习11
## set_pgfault_handler()
函数使得用户可以自己选择缺页异常的处理方式。
handler传入用户自定义页错误处理函数指针。
_pgfault_upcall是一个全局变量，在lib/pfentry.S中完成的初始化。它是页错误处理的总入口，页错误除了运行page_fault_handler，还需要切换回正常栈。
_pgfault_handler被赋值为handler，会在 _pgfault_upcall中被调用，是页错误处理的一部分。
>该函数是在lib中，获取当前进程id需要通过sys_getenvid()来获取

缺页异常处理逻辑
![](/document/picture/缺页异常处理逻辑.png)
## 问题
>为什么 user/faultalloc 和 user/faultallocbad 的表现不同

两段代码发生缺页中断时使用的处理函数handler都一样，不同的是在umain函数中输出时faultalloc.c选择了cprintf()，而faultallocbad.c选择了sys_cputs()。
sys_cputs()直接通过lib/syscall.c发起系统调用，中间检查了内存，所以还没触发缺页中断就直接panic。
cprintf()在调用 sys_cputs()之前，首先在用户态执行了vprintfmt()将要输出的字符串存入结构体 b 中。在此过程中试图访问 0xdeadbeef 地址，触发了页错误，然后系统调用用户自己选择的handler()来在用户态下处理缺页错误。
# debug tf->trap_no = 6?? illegal opcode
page_fault_handler函数写错了，花了两天各种debug才发现是处理非递归调用的时候esp赋值出了问题。还有前面忘记给SYS_env_set_pgfault_upcall分配系统调用。
# 练习12
## pgfault
_pgfault_upcall中调用的页错误处理函数。调用前，父子进程的页错误地址都引用同一页物理内存，该函数作用是分配一个物理页面使得两者独立。
在pgfault函数中先判断是否页错误是由写时拷贝造成的，如果不是则panic。使用了特殊地址PFTEMP，专门用来发生page fault的时候拷贝内容。先解除addr原先的页映射关系，然后将addr映射到PFTEMP映射的页，最后解除PFTEMP的页映射关系。
## uvpt
在memlayout.h中定义，存储用户态虚拟页表项，同时lib/entry.S 设置了 uvpt 和 uvpd
```
#if JOS_USER
extern volatile pte_t uvpt[];     // VA of "virtual page table"
extern volatile pde_t uvpd[];     // VA of current page directory
#endif
```
## duppage

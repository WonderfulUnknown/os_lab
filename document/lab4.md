[TOC]
# 练习1
## mmio_map_region
该函数用于在内存中预留一部分空间给IO来访问LAPIC（局部高级可编程中断控制器）单元。
根据注释可知此处页面的权限位应该另外加上PTE_PCD|PTE_PWT，使得cache不缓存这部分的内容，采用直接写回的策略。
# 练习2
## 应用处理器(AP)启动过程
在boot_aps()中启动AP，该函数遍历cpus数组，启动所有的AP，当一个AP启动后会执行kern/mpentry.S中的代码，在mepentry.S的代码最后跳转到mp_main()中。该函数为当前AP设置全局描述符表GDT（也就是页表项），中断向量表，初始化局部APIC(LAPIC)单元。最后设置cpus数组中当前CPU对应的CpuInfo结构的cpu_status为CPU_STARTED。
## 问题1
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
## debug boot_map_region
原本写的映射循环是
`for(int i = 0;i < size;i += PGSIZE)`
提示`assertion failed: check_va2pa(pgdir, KERNBASE + i) == i`，才发现原本写的size并不是以页为单位= =，改为`for(int i = 0;i < PGNUM(size);i += PGSIZE)`。
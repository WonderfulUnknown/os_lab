[TOC]
#练习1
##mem_init
与lab2初始化pages数组和映射类似
#练习2
##env_init
初始化全部 envs 数组中的 Env 结构体，并将它们加入到 env_free_list 中。还要调用 env_init_percpu ，这个函数会通过配置段硬件，将其分隔为特权等级 0 (内核) 和特权等级 3（用户）两个不同的段。
通过注释可以得知，第一次调用env_alloc()应该返回envs[0]，所以链表应该倒序存储。
##env_setup_vm
>identical 相同的

 为新的进程分配一个页目录，并初始化新进程的地址空间对应的内核部分。
所有envs结构的虚拟地址都是在UTOP上的。
UTOP之上env_pgdir可以拷贝kern_pgdir, 因为所有用户环境的页目录表中和操作系统相关的页目录项都是一样的，但是UVPT处的env_pgdir需要单独设置成用户只读。
>每个用户进程都需要共享内核空间，所以对于用户进程而言，在UTOP以上的部分，和系统内核的空间是完全一样的。

###memcpy
string.h中定义
```
void *	memcpy(void *dst, const void *src, size_t len);
```
memcpy函数的功能是从源src所指的内存地址的起始位置开始拷贝n个字节到目标dest所指的内存地址的起始位置中。
##region_alloc
>corner-cases 极端情况

为进程分配和映射物理内存。
利用lab2中的 page_alloc() 完成内存页的分配， page_insert() 完成虚拟地址到物理页的映射。
注意把虚拟地址va，va+len以4k为单位取整，方便后面以页为单位计算。
还需要检查页表是否申请成功，是否映射到对应的物理地址。 
##load_icode
为每一个用户进程设置它的初始代码区，堆栈以及处理器标识位。因为用户程序是ELF文件，所以要解析ELF文件。
>函数只在内核初始化且第一个用户进程未运行时被调用，从ELF文件头部指明的虚拟地址开始加载需要加载的字段到用户内存

该段代码需要参考boot/main.c文件来写
###Proghdr
通过查询得知，p_type,p_va,p_memsz是结构Proghdr中的参数。
elf.h中定义
```
struct Proghdr {
	uint32_t p_type;
	uint32_t p_offset;
	uint32_t p_va;
	uint32_t p_pa;
	uint32_t p_filesz;
	uint32_t p_memsz;
	uint32_t p_flags;
	uint32_t p_align;
};
```
通过上网查询可知Proghdr中各个数据类型的意义
uint32_t p_type;  // 段类型，说明载入的是代码还是数据，用于动态链接
uint32_t p_offset;  // 段相对文件头的偏移值
uint32_t p_va;  // 段的第一个字节将被放到内存中的虚拟地址
uint32_t p_pa; // 物理地址，没有使用
uint32_t p_filesz; // 文件中段的长度 
uint memsz;  // 段在内存中占用的空间(每个程序的大小)
uint32_t p_flags; // 读/写/执行位
uint32_t p_align; // 需求队列，总是物理页大小
###Elf
elf.h中定义
```
struct Elf {
	uint32_t e_magic;	// must equal ELF_MAGIC
	uint8_t e_elf[12];
	uint16_t e_type;
	uint16_t e_machine;
	uint32_t e_version;
	uint32_t e_entry;
	uint32_t e_phoff;
	uint32_t e_shoff;
	uint32_t e_flags;
	uint16_t e_ehsize;
	uint16_t e_phentsize;
	uint16_t e_phnum;
	uint16_t e_shentsize;
	uint16_t e_shnum;
	uint16_t e_shstrndx;
};
```
Elf结构具体每个类型的意义可参考下图：
![](https://images2015.cnblogs.com/blog/745386/201606/745386-20160601195400680-1757764183.png)
以及博客：
[https://www.cnblogs.com/dengxiaojun/p/4279407.html](https://www.cnblogs.com/dengxiaojun/p/4279407.html)
具体ELF文件格式可参考下面这篇博客：
[https://blog.csdn.net/fang92/article/details/48092165](https://blog.csdn.net/fang92/article/details/48092165)
###lcr3
x86.h中定义
```
static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
}
```
汇编代码，将地址装入cr3寄存器，而cr3中装的都是页目录的起始地址。


env_create：它会调用env_alloc，从env_free_list中取出一个env结构体，再通过 env_setup_vm为其初始化，申请新的页目录; 然后执行load_icode,这个函数加载elf文件(二进制文件)，它会调用region_alloc为其分配页，并将虚拟地址和物理地址作出映射，load_icon之后分配进程栈，以及，将env->env_tf.tf_eip指向将执行进程函数的入口(等待env_pop_tf的调用)


Env_run：启动进程，通过env_pop_tf函数，改变env结构体中运行状态等信息(防止后来的一个进程在多个内核中运行)，将env结构体中保存的寄存器中的信息加在到真正的寄存器中，接下来便执行eip所指向的内容。
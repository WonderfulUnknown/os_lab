[TOC]
#练习1
与lab2初始化pages数组和映射类似
#练习2
##env_init
通过注释可以得知，第一次调用env_alloc()应该返回envs[0]，所以链表应该倒序存储。
##env_setup_vm
>identical 相同的

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

注意把虚拟地址va，va+len以4k为单位取整，方便后面以页为单位计算。
还需要检查页表是否申请成功，是否映射到对应的物理地址。
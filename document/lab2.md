[TOB]
#练习1代码理解
##i386_detect_memory
识别内存中有多少空间剩余以及base memory,extended memory
>不太理解哪来的额外内存

所有的单位都是页数（一页4KB）
##boot_alloc
>暂时没弄懂end以及kernel bss段是什么意思

当做页分配器，维护静态变量nextfree，使它始终指向一个可用的虚拟内存地址，按照注释要求，每次申请变量空间时都需要修改nextfree的值
初始化时boot_alloc(0)返回的就是可用虚拟内存开始的地址
###ROUNDUP 
inc/types.h中定义 
作用是取整，用来保持变量是4k的倍数（应该是向上取整）
##mem_init
###struct PageInfo 
memlayout.h中定义
```
struct PageInfo {
	// Next page on the free list.
	struct PageInfo *pp_link;

	// pp_ref is the count of pointers (usually in page table entries)
	// to this page, for pages allocated using page_alloc.
	// Pages allocated at boot time using pmap.c's
	// boot_alloc do not have valid reference count fields.

	uint16_t pp_ref;
};
```
pageInfo主要有两个变量:
pp_link表示下一个空闲页，如果pp_link=0,则表示这个页面被分配了，否则就表示未被分配，是空闲页。
pp_ref表示页面被引用的次数，如果为0，表示是空闲页。
###第一次补充的代码
为pages申请地址空间，并初始化为0
###memset
string.h中定义
`void *	memset(void *dst, int c, size_t len);`
函数解释：将dst中当前位置后面的len个字节用c替换并返回 dst 。
作用是在一段内存块中填充某个给定的值，它是对较大的结构体或数组进行清零操作的一种最快方法。
##page_init
初始化pages数组以及page_free_list，将已经被系统使用的剔除
>挺坑的，一开始不知道boot_alloc中end那个还是虚拟地址，要减去KERENBASE转化为物理地址
利用 boot_alloc 函数来找到第一个能分配的页面

###IOPHYSMEM && EXTPHYSMEM
memlayout.h中定义
```
// At IOPHYSMEM (640K) there is a 384K hole for I/O.  From the kernel,
// IOPHYSMEM can be addressed at KERNBASE + IOPHYSMEM.  The hole ends
// at physical address EXTPHYSMEM.
#define IOPHYSMEM	0x0A0000
#define EXTPHYSMEM	0x100000
```
###KERNBASE
memlayout.h中定义
```
// All physical memory mapped at this address
#define	KERNBASE	0xF0000000
```
##page_alloc
申请一页的空间，需要对page_free_list进行更新，以及对页进行初始化
###ALLOC_ZERO
pmap.h中定义
```
enum {
	// For page_alloc, zero the returned physical page.
	ALLOC_ZERO = 1<<0,
};
```
>没太懂这个值的意义，以及把1左移0位的意义

###page2kva
pmap.h中定义
```
static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}

/* This macro takes a physical address and returns the corresponding kernel
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)
```
KADDR：将物理地址转换为虚拟地址
page2kva：将PageInfo结构转换为相应的虚拟地址
##page_free
对申请的空间进行释放，同时对page_free_list和收回的page进行修改

***原本加了个pp->ref是否等于0的判断，发现结果与自己想的相反，后来查了才知道好像前面的代码在调用page_free的时候会提前把pp_ref和pp_link修改了，但没仔细去看过这部分代码***
##check_page_alloc
检查page_alloc是否成功，成功则
`cprintf("check_page_alloc() succeeded!\n");`
###assert
assert.h中定义
```
#define assert(x)		\
	do { if (!(x)) panic("assertion failed: %s", #x); } while (0)
```
>不太懂panic的作用,貌似是个系统中断？感觉语法和printf差不多

```
void _panic(const char*, int, const char*, ...) __attribute__((noreturn));

#define panic(...) _panic(__FILE__, __LINE__, __VA_ARGS__)
```
#练习2Intel理解
对于Intel CPU 来说，分页标志位是CR0寄存器的第31位，为1 表示使用分页，为0 表示不使用分页。CPU 在执行代码时，自动检测CR0寄存器中的分页标志位是否被设定，若被设定就自动完成虚拟地址到物理地址的转换。

#练习3
无法在运行着QEMU软件的terminal里面通过输入ctrl-a c，切换到监控器里，上网查询得知在lab目录下面输入：
```
qemu-system-i386 -hda obj/kern/kernel.img -monitor stdio -gdb tcp::26000 -D qemu.log  
```
可以在linux的terminal里进入到监控器。
>变量x应该是什么类型，uintptr_t还是 physaddr_t？

虚拟地址，因为使用了指针，指针指向的都是虚拟地址。
#练习4
##page_walk
主要是用过一个给定的虚拟地址va和pgdir(page director table的首地址), 返回va所对应的pte(page table entry)中的页表项。当va对应的页表存在时，只需要直接按照页面翻译的过程给出页表项的地址；当va对应的页表没有被创建的时候，就需要手动的申请并创建页面。
最后需要返回的是虚拟地址，而不能直接返回页表项的物理地址。因为程序里面只能执行虚拟地址，给出的物理地址也会被当成是虚拟地址，会引发错误。
###pte_t,pde_t
memlayout.h中定义
```
typedef uint32_t pte_t;
typedef uint32_t pde_t;
```
###mmu.h中有用的宏定义
####PDX
取地址31-22bit，用作pd索引
```
// page directory index
#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
```
####PTE_ADDR
将页目录项的后12位（flag 位）全部置 0 获得对应的页表项物理地址
```
// Address in page table or page directory entry
#define PTE_ADDR(pte)	((physaddr_t) (pte) & ~0xFFF)
```
####PTX
取地址21到12bit，用作pt索引
```
// page table index
#define PTX(la)     ((((uintptr_t) (la)) >> PTXSHIFT) & 0x3FF)
```
####PGOFF
取地址11-0bit，用作页间索引
```
// offset in page
#define PGOFF(la)	(((uintptr_t) (la)) & 0xFFF)
```
####页目录和页表权限位
```
// Page table/directory entry flags.
#define PTE_P		0x001	// Present 存在
#define PTE_W		0x002	// Writeable 可写入
#define PTE_U		0x004	// User 用户可操作
```
>关于权限位如果有不懂的地方看下图

![权限位图](https://pdos.csail.mit.edu/6.828/2014/readings/i386/fig6-10.gif)
##boot_map
>UTOP？

调用pgdir_walk，把虚拟地址和物理地址的映射放到页的首地址对应的页目录中,并设置权限等信息
##page_lookup
根据虚拟地址，找到相应的page(pageInfo)的位置
###pa2page
将虚拟地址转换为对应的PageInfo结构
##page_remove
虚拟地址va和物理页的映射关系删除
###tlb_invalidate
通知tlb失效。tlb是个高速缓存，用来缓存查找记录增加查找速度
```
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
```
具体解释在这个博客里有提到
[https://blog.csdn.net/cinmyheart/article/details/39994769](https://blog.csdn.net/cinmyheart/article/details/39994769)
###page_decref
减少页的被引用次数，如果页的被引用次数为0就调用page_free将页面释放
```
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
	if (--pp->pp_ref == 0)
		page_free(pp);
}
```
##page_insert
把指定的物理地址和虚拟地址之间的联系放到页的首地址（如果虚拟地 址已经有映射，删除之前的映射，添加新的）
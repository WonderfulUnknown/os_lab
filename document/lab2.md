#lab2代码理解
##一些重要的全局变量
size_t npages;
struct PageInfo *pages;
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

***原本加了个pp->ref是否等于0的判断，发现结果一直出乎意外，后来查了才知道好像前面的代码在调用page_free的时候会提前把pp_ref和pp_link修改了***
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
#lab2代码理解
##一些重要的全局变量
size_t npages;
struct PageInfo *pages;
##i386_detect_memory
识别内存中有多少空间剩余以及base memory,extended memory
>不太理解哪来的额外内存

所有的单位都是页数（一页4KB）
##boot_alloc
>暂时没弄懂kernel bss段是什么意思

当做页分配器，维护静态变量nextfree，使它始终指向一个可用的虚拟内存地址，按照注释要求，每次申请变量空间时都需要修改nextfree的值
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
函数解释：将dst中当前位置后面的len个字节 用 c 替换并返回 dst 。
作用是在一段内存块中填充某个给定的值，它是对较大的结构体或数组进行清零操作的一种最快方法。

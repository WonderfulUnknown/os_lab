// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if((err & FEC_WR) == 0 || (uvpt[PGNUM(addr)] & PTE_COW) == 0)
		panic("pgfault:can't copy-on-write\n");
	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	envid_t env_id = sys_getenvid();
	// Allocate a new page, map it at a temporary location (PFTEMP),
	r = sys_page_alloc(env_id, (void *)PFTEMP, PTE_W | PTE_P | PTE_U);
	if(r < 0 )
		panic("pgfault:can't page_alloc at PFTEMP\n");
	
	addr = ROUNDDOWN(addr, PGSIZE);
	//move the new page to the old page's address
	memmove(PFTEMP, addr, PGSIZE);

	r = sys_page_unmap(env_id, addr);
	if (r < 0)
		panic("pgfault:can't unmap page\n");
	//将PFTEMP指向的物理页拷贝到addr指向的物理页
	r = sys_page_map(env_id, PFTEMP, env_id, addr, PTE_U | PTE_P | PTE_W);
    if(r < 0)
        panic("pgfault:can't map temp page to old page\n");
	r = sys_page_unmap(env_id, PFTEMP);
    if(r < 0)
        panic("pgfault:can't unmap page\n");
	//panic("pgfault not implemented");
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	uint32_t addr = pn*PGSIZE;
	//void *addr = (void *)(pn * PGSIZE);
	int perm = uvpt[pn] & 0xFFF;
	envid_t this_env_id = sys_getenvid();

	//If the page is writable or copy-on-write,the new mapping must be created copy-on-write
	if (perm & (PTE_W | PTE_COW))
	{
		perm |= PTE_COW;
		perm &= ~PTE_W;//不把该位去掉会输出非ascii码的东西= =
	}

	perm &= PTE_SYSCALL;//!
	r = sys_page_map(this_env_id, (void *)addr, envid, (void *)addr, perm);
	if (r < 0)
	{
		panic("duppage:can't remap page\n");
		return r;
	}
	if (perm & PTE_COW)
	{
		r = sys_page_map(this_env_id, (void *)addr, this_env_id, (void *)addr, perm);
		if (r < 0)
		{
			panic("duppage:can't remap page\n");
			return r;
		}
	}
	//panic("duppage not implemented");
	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
	// LAB 4: Your code here.
	set_pgfault_handler(pgfault);
	envid_t env_id = sys_exofork();
	if(env_id < 0)
		panic("fork fail\n");
	if(env_id == 0)//子进程
	{
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}
	for (uintptr_t addr = UTEXT; addr < USTACKTOP; addr += PGSIZE) {
        if ( (uvpd[PDX(addr)] & PTE_P) && (uvpt[PGNUM(addr)] & PTE_P) ) {
            // dup page to child
            duppage(env_id, PGNUM(addr));
        }
    }
    // alloc page for exception stack
    int r = sys_page_alloc(env_id, (void *)(UXSTACKTOP-PGSIZE), PTE_U | PTE_W | PTE_P);
    if (r < 0) panic("fork: %e",r);

    // DO NOT FORGET
    extern void _pgfault_upcall();
    r = sys_env_set_pgfault_upcall(env_id, _pgfault_upcall);
    if (r < 0) panic("fork: set upcall for child fail, %e", r);

    // mark the child environment runnable
    if ((r = sys_env_set_status(env_id, ENV_RUNNABLE)) < 0)
        panic("sys_env_set_status: %e", r);
	return env_id;
	//panic("fork not implemented");
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}

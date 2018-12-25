
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 d0 11 00       	mov    $0x11d000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 d0 11 f0       	mov    $0xf011d000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5c 00 00 00       	call   f010009a <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100048:	83 3d 80 ae 22 f0 00 	cmpl   $0x0,0xf022ae80
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 80 ae 22 f0    	mov    %esi,0xf022ae80

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 8d 52 00 00       	call   f01052ee <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 80 59 10 f0       	push   $0xf0105980
f010006d:	e8 23 36 00 00       	call   f0103695 <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 f3 35 00 00       	call   f010366f <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 09 5d 10 f0 	movl   $0xf0105d09,(%esp)
f0100083:	e8 0d 36 00 00       	call   f0103695 <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 8a 08 00 00       	call   f010091f <monitor>
f0100095:	83 c4 10             	add    $0x10,%esp
f0100098:	eb f1                	jmp    f010008b <_panic+0x4b>

f010009a <i386_init>:
static void boot_aps(void);


void
i386_init(void)
{
f010009a:	55                   	push   %ebp
f010009b:	89 e5                	mov    %esp,%ebp
f010009d:	53                   	push   %ebx
f010009e:	83 ec 08             	sub    $0x8,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a1:	b8 08 c0 26 f0       	mov    $0xf026c008,%eax
f01000a6:	2d 98 95 22 f0       	sub    $0xf0229598,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 98 95 22 f0       	push   $0xf0229598
f01000b3:	e8 14 4c 00 00       	call   f0104ccc <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 92 05 00 00       	call   f010064f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 ec 59 10 f0       	push   $0xf01059ec
f01000ca:	e8 c6 35 00 00       	call   f0103695 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 86 11 00 00       	call   f010125a <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 e8 2d 00 00       	call   f0102ec1 <env_init>
	trap_init();
f01000d9:	e8 a5 36 00 00       	call   f0103783 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 01 4f 00 00       	call   f0104fe4 <mp_init>
	lapic_init();
f01000e3:	e8 21 52 00 00       	call   f0105309 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 cf 34 00 00       	call   f01035bc <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 f3 11 f0 	movl   $0xf011f3c0,(%esp)
f01000f4:	e8 63 54 00 00       	call   f010555c <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d 88 ae 22 f0 07 	cmpl   $0x7,0xf022ae88
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 a4 59 10 f0       	push   $0xf01059a4
f010010f:	6a 55                	push   $0x55
f0100111:	68 07 5a 10 f0       	push   $0xf0105a07
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 4a 4f 10 f0       	mov    $0xf0104f4a,%eax
f0100123:	2d d0 4e 10 f0       	sub    $0xf0104ed0,%eax
f0100128:	50                   	push   %eax
f0100129:	68 d0 4e 10 f0       	push   $0xf0104ed0
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 e1 4b 00 00       	call   f0104d19 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 b0 22 f0       	mov    $0xf022b020,%ebx
f0100140:	eb 4d                	jmp    f010018f <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 a7 51 00 00       	call   f01052ee <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 39                	je     f010018c <i386_init+0xf2>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 20 b0 22 f0       	sub    $0xf022b020,%eax
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	05 00 40 23 f0       	add    $0xf0234000,%eax
f010016b:	a3 84 ae 22 f0       	mov    %eax,0xf022ae84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100170:	83 ec 08             	sub    $0x8,%esp
f0100173:	68 00 70 00 00       	push   $0x7000
f0100178:	0f b6 03             	movzbl (%ebx),%eax
f010017b:	50                   	push   %eax
f010017c:	e8 d6 52 00 00       	call   f0105457 <lapic_startap>
f0100181:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100184:	8b 43 04             	mov    0x4(%ebx),%eax
f0100187:	83 f8 01             	cmp    $0x1,%eax
f010018a:	75 f8                	jne    f0100184 <i386_init+0xea>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010018c:	83 c3 74             	add    $0x74,%ebx
f010018f:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f0100196:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010019b:	39 c3                	cmp    %eax,%ebx
f010019d:	72 a3                	jb     f0100142 <i386_init+0xa8>
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f010019f:	83 ec 08             	sub    $0x8,%esp
f01001a2:	6a 00                	push   $0x0
f01001a4:	68 ec 73 19 f0       	push   $0xf01973ec
f01001a9:	e8 db 2e 00 00       	call   f0103089 <env_create>
	// Touch all you want.
	ENV_CREATE(user_primes, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	ENV_CREATE(user_yield, ENV_TYPE_USER);
f01001ae:	83 c4 08             	add    $0x8,%esp
f01001b1:	6a 00                	push   $0x0
f01001b3:	68 ec 73 19 f0       	push   $0xf01973ec
f01001b8:	e8 cc 2e 00 00       	call   f0103089 <env_create>
    ENV_CREATE(user_yield, ENV_TYPE_USER);
f01001bd:	83 c4 08             	add    $0x8,%esp
f01001c0:	6a 00                	push   $0x0
f01001c2:	68 ec 73 19 f0       	push   $0xf01973ec
f01001c7:	e8 bd 2e 00 00       	call   f0103089 <env_create>
	sched_yield();
f01001cc:	e8 43 3e 00 00       	call   f0104014 <sched_yield>

f01001d1 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001d1:	55                   	push   %ebp
f01001d2:	89 e5                	mov    %esp,%ebp
f01001d4:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001d7:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001dc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001e1:	77 12                	ja     f01001f5 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001e3:	50                   	push   %eax
f01001e4:	68 c8 59 10 f0       	push   $0xf01059c8
f01001e9:	6a 6c                	push   $0x6c
f01001eb:	68 07 5a 10 f0       	push   $0xf0105a07
f01001f0:	e8 4b fe ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01001f5:	05 00 00 00 10       	add    $0x10000000,%eax
f01001fa:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001fd:	e8 ec 50 00 00       	call   f01052ee <cpunum>
f0100202:	83 ec 08             	sub    $0x8,%esp
f0100205:	50                   	push   %eax
f0100206:	68 13 5a 10 f0       	push   $0xf0105a13
f010020b:	e8 85 34 00 00       	call   f0103695 <cprintf>

	lapic_init();
f0100210:	e8 f4 50 00 00       	call   f0105309 <lapic_init>
	env_init_percpu();
f0100215:	e8 77 2c 00 00       	call   f0102e91 <env_init_percpu>
	trap_init_percpu();
f010021a:	e8 8a 34 00 00       	call   f01036a9 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f010021f:	e8 ca 50 00 00       	call   f01052ee <cpunum>
f0100224:	6b d0 74             	imul   $0x74,%eax,%edx
f0100227:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f010022d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100232:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100236:	c7 04 24 c0 f3 11 f0 	movl   $0xf011f3c0,(%esp)
f010023d:	e8 1a 53 00 00       	call   f010555c <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();
	sched_yield();//选择进程运行
f0100242:	e8 cd 3d 00 00       	call   f0104014 <sched_yield>

f0100247 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100247:	55                   	push   %ebp
f0100248:	89 e5                	mov    %esp,%ebp
f010024a:	53                   	push   %ebx
f010024b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010024e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100251:	ff 75 0c             	pushl  0xc(%ebp)
f0100254:	ff 75 08             	pushl  0x8(%ebp)
f0100257:	68 29 5a 10 f0       	push   $0xf0105a29
f010025c:	e8 34 34 00 00       	call   f0103695 <cprintf>
	vcprintf(fmt, ap);
f0100261:	83 c4 08             	add    $0x8,%esp
f0100264:	53                   	push   %ebx
f0100265:	ff 75 10             	pushl  0x10(%ebp)
f0100268:	e8 02 34 00 00       	call   f010366f <vcprintf>
	cprintf("\n");
f010026d:	c7 04 24 09 5d 10 f0 	movl   $0xf0105d09,(%esp)
f0100274:	e8 1c 34 00 00       	call   f0103695 <cprintf>
	va_end(ap);
}
f0100279:	83 c4 10             	add    $0x10,%esp
f010027c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010027f:	c9                   	leave  
f0100280:	c3                   	ret    

f0100281 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100281:	55                   	push   %ebp
f0100282:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100284:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100289:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010028a:	a8 01                	test   $0x1,%al
f010028c:	74 0b                	je     f0100299 <serial_proc_data+0x18>
f010028e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100293:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100294:	0f b6 c0             	movzbl %al,%eax
f0100297:	eb 05                	jmp    f010029e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100299:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010029e:	5d                   	pop    %ebp
f010029f:	c3                   	ret    

f01002a0 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002a0:	55                   	push   %ebp
f01002a1:	89 e5                	mov    %esp,%ebp
f01002a3:	53                   	push   %ebx
f01002a4:	83 ec 04             	sub    $0x4,%esp
f01002a7:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01002a9:	eb 2b                	jmp    f01002d6 <cons_intr+0x36>
		if (c == 0)
f01002ab:	85 c0                	test   %eax,%eax
f01002ad:	74 27                	je     f01002d6 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01002af:	8b 0d 24 a2 22 f0    	mov    0xf022a224,%ecx
f01002b5:	8d 51 01             	lea    0x1(%ecx),%edx
f01002b8:	89 15 24 a2 22 f0    	mov    %edx,0xf022a224
f01002be:	88 81 20 a0 22 f0    	mov    %al,-0xfdd5fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002c4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002ca:	75 0a                	jne    f01002d6 <cons_intr+0x36>
			cons.wpos = 0;
f01002cc:	c7 05 24 a2 22 f0 00 	movl   $0x0,0xf022a224
f01002d3:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002d6:	ff d3                	call   *%ebx
f01002d8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002db:	75 ce                	jne    f01002ab <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002dd:	83 c4 04             	add    $0x4,%esp
f01002e0:	5b                   	pop    %ebx
f01002e1:	5d                   	pop    %ebp
f01002e2:	c3                   	ret    

f01002e3 <kbd_proc_data>:
f01002e3:	ba 64 00 00 00       	mov    $0x64,%edx
f01002e8:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01002e9:	a8 01                	test   $0x1,%al
f01002eb:	0f 84 f0 00 00 00    	je     f01003e1 <kbd_proc_data+0xfe>
f01002f1:	ba 60 00 00 00       	mov    $0x60,%edx
f01002f6:	ec                   	in     (%dx),%al
f01002f7:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002f9:	3c e0                	cmp    $0xe0,%al
f01002fb:	75 0d                	jne    f010030a <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01002fd:	83 0d 00 a0 22 f0 40 	orl    $0x40,0xf022a000
		return 0;
f0100304:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100309:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010030a:	55                   	push   %ebp
f010030b:	89 e5                	mov    %esp,%ebp
f010030d:	53                   	push   %ebx
f010030e:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100311:	84 c0                	test   %al,%al
f0100313:	79 36                	jns    f010034b <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100315:	8b 0d 00 a0 22 f0    	mov    0xf022a000,%ecx
f010031b:	89 cb                	mov    %ecx,%ebx
f010031d:	83 e3 40             	and    $0x40,%ebx
f0100320:	83 e0 7f             	and    $0x7f,%eax
f0100323:	85 db                	test   %ebx,%ebx
f0100325:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100328:	0f b6 d2             	movzbl %dl,%edx
f010032b:	0f b6 82 a0 5b 10 f0 	movzbl -0xfefa460(%edx),%eax
f0100332:	83 c8 40             	or     $0x40,%eax
f0100335:	0f b6 c0             	movzbl %al,%eax
f0100338:	f7 d0                	not    %eax
f010033a:	21 c8                	and    %ecx,%eax
f010033c:	a3 00 a0 22 f0       	mov    %eax,0xf022a000
		return 0;
f0100341:	b8 00 00 00 00       	mov    $0x0,%eax
f0100346:	e9 9e 00 00 00       	jmp    f01003e9 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f010034b:	8b 0d 00 a0 22 f0    	mov    0xf022a000,%ecx
f0100351:	f6 c1 40             	test   $0x40,%cl
f0100354:	74 0e                	je     f0100364 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100356:	83 c8 80             	or     $0xffffff80,%eax
f0100359:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010035b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010035e:	89 0d 00 a0 22 f0    	mov    %ecx,0xf022a000
	}

	shift |= shiftcode[data];
f0100364:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100367:	0f b6 82 a0 5b 10 f0 	movzbl -0xfefa460(%edx),%eax
f010036e:	0b 05 00 a0 22 f0    	or     0xf022a000,%eax
f0100374:	0f b6 8a a0 5a 10 f0 	movzbl -0xfefa560(%edx),%ecx
f010037b:	31 c8                	xor    %ecx,%eax
f010037d:	a3 00 a0 22 f0       	mov    %eax,0xf022a000

	c = charcode[shift & (CTL | SHIFT)][data];
f0100382:	89 c1                	mov    %eax,%ecx
f0100384:	83 e1 03             	and    $0x3,%ecx
f0100387:	8b 0c 8d 80 5a 10 f0 	mov    -0xfefa580(,%ecx,4),%ecx
f010038e:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100392:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100395:	a8 08                	test   $0x8,%al
f0100397:	74 1b                	je     f01003b4 <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100399:	89 da                	mov    %ebx,%edx
f010039b:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010039e:	83 f9 19             	cmp    $0x19,%ecx
f01003a1:	77 05                	ja     f01003a8 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f01003a3:	83 eb 20             	sub    $0x20,%ebx
f01003a6:	eb 0c                	jmp    f01003b4 <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f01003a8:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003ab:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003ae:	83 fa 19             	cmp    $0x19,%edx
f01003b1:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003b4:	f7 d0                	not    %eax
f01003b6:	a8 06                	test   $0x6,%al
f01003b8:	75 2d                	jne    f01003e7 <kbd_proc_data+0x104>
f01003ba:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003c0:	75 25                	jne    f01003e7 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01003c2:	83 ec 0c             	sub    $0xc,%esp
f01003c5:	68 43 5a 10 f0       	push   $0xf0105a43
f01003ca:	e8 c6 32 00 00       	call   f0103695 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003cf:	ba 92 00 00 00       	mov    $0x92,%edx
f01003d4:	b8 03 00 00 00       	mov    $0x3,%eax
f01003d9:	ee                   	out    %al,(%dx)
f01003da:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003dd:	89 d8                	mov    %ebx,%eax
f01003df:	eb 08                	jmp    f01003e9 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003e6:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003e7:	89 d8                	mov    %ebx,%eax
}
f01003e9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003ec:	c9                   	leave  
f01003ed:	c3                   	ret    

f01003ee <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003ee:	55                   	push   %ebp
f01003ef:	89 e5                	mov    %esp,%ebp
f01003f1:	57                   	push   %edi
f01003f2:	56                   	push   %esi
f01003f3:	53                   	push   %ebx
f01003f4:	83 ec 1c             	sub    $0x1c,%esp
f01003f7:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003f9:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003fe:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100403:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100408:	eb 09                	jmp    f0100413 <cons_putc+0x25>
f010040a:	89 ca                	mov    %ecx,%edx
f010040c:	ec                   	in     (%dx),%al
f010040d:	ec                   	in     (%dx),%al
f010040e:	ec                   	in     (%dx),%al
f010040f:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100410:	83 c3 01             	add    $0x1,%ebx
f0100413:	89 f2                	mov    %esi,%edx
f0100415:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100416:	a8 20                	test   $0x20,%al
f0100418:	75 08                	jne    f0100422 <cons_putc+0x34>
f010041a:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100420:	7e e8                	jle    f010040a <cons_putc+0x1c>
f0100422:	89 f8                	mov    %edi,%eax
f0100424:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100427:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010042c:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010042d:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100432:	be 79 03 00 00       	mov    $0x379,%esi
f0100437:	b9 84 00 00 00       	mov    $0x84,%ecx
f010043c:	eb 09                	jmp    f0100447 <cons_putc+0x59>
f010043e:	89 ca                	mov    %ecx,%edx
f0100440:	ec                   	in     (%dx),%al
f0100441:	ec                   	in     (%dx),%al
f0100442:	ec                   	in     (%dx),%al
f0100443:	ec                   	in     (%dx),%al
f0100444:	83 c3 01             	add    $0x1,%ebx
f0100447:	89 f2                	mov    %esi,%edx
f0100449:	ec                   	in     (%dx),%al
f010044a:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100450:	7f 04                	jg     f0100456 <cons_putc+0x68>
f0100452:	84 c0                	test   %al,%al
f0100454:	79 e8                	jns    f010043e <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100456:	ba 78 03 00 00       	mov    $0x378,%edx
f010045b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010045f:	ee                   	out    %al,(%dx)
f0100460:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100465:	b8 0d 00 00 00       	mov    $0xd,%eax
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100470:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100471:	89 fa                	mov    %edi,%edx
f0100473:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100479:	89 f8                	mov    %edi,%eax
f010047b:	80 cc 07             	or     $0x7,%ah
f010047e:	85 d2                	test   %edx,%edx
f0100480:	0f 44 f8             	cmove  %eax,%edi
    // 	    }
	//     else {
    //           c |= 0x0400;
    // 	    }
	// }
	switch (c & 0xff) {
f0100483:	89 f8                	mov    %edi,%eax
f0100485:	0f b6 c0             	movzbl %al,%eax
f0100488:	83 f8 09             	cmp    $0x9,%eax
f010048b:	74 74                	je     f0100501 <cons_putc+0x113>
f010048d:	83 f8 09             	cmp    $0x9,%eax
f0100490:	7f 0a                	jg     f010049c <cons_putc+0xae>
f0100492:	83 f8 08             	cmp    $0x8,%eax
f0100495:	74 14                	je     f01004ab <cons_putc+0xbd>
f0100497:	e9 99 00 00 00       	jmp    f0100535 <cons_putc+0x147>
f010049c:	83 f8 0a             	cmp    $0xa,%eax
f010049f:	74 3a                	je     f01004db <cons_putc+0xed>
f01004a1:	83 f8 0d             	cmp    $0xd,%eax
f01004a4:	74 3d                	je     f01004e3 <cons_putc+0xf5>
f01004a6:	e9 8a 00 00 00       	jmp    f0100535 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01004ab:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f01004b2:	66 85 c0             	test   %ax,%ax
f01004b5:	0f 84 e6 00 00 00    	je     f01005a1 <cons_putc+0x1b3>
			crt_pos--;
f01004bb:	83 e8 01             	sub    $0x1,%eax
f01004be:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004c4:	0f b7 c0             	movzwl %ax,%eax
f01004c7:	66 81 e7 00 ff       	and    $0xff00,%di
f01004cc:	83 cf 20             	or     $0x20,%edi
f01004cf:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f01004d5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004d9:	eb 78                	jmp    f0100553 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004db:	66 83 05 28 a2 22 f0 	addw   $0x50,0xf022a228
f01004e2:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004e3:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f01004ea:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004f0:	c1 e8 16             	shr    $0x16,%eax
f01004f3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004f6:	c1 e0 04             	shl    $0x4,%eax
f01004f9:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228
f01004ff:	eb 52                	jmp    f0100553 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f0100501:	b8 20 00 00 00       	mov    $0x20,%eax
f0100506:	e8 e3 fe ff ff       	call   f01003ee <cons_putc>
		cons_putc(' ');
f010050b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100510:	e8 d9 fe ff ff       	call   f01003ee <cons_putc>
		cons_putc(' ');
f0100515:	b8 20 00 00 00       	mov    $0x20,%eax
f010051a:	e8 cf fe ff ff       	call   f01003ee <cons_putc>
		cons_putc(' ');
f010051f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100524:	e8 c5 fe ff ff       	call   f01003ee <cons_putc>
		cons_putc(' ');
f0100529:	b8 20 00 00 00       	mov    $0x20,%eax
f010052e:	e8 bb fe ff ff       	call   f01003ee <cons_putc>
f0100533:	eb 1e                	jmp    f0100553 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100535:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f010053c:	8d 50 01             	lea    0x1(%eax),%edx
f010053f:	66 89 15 28 a2 22 f0 	mov    %dx,0xf022a228
f0100546:	0f b7 c0             	movzwl %ax,%eax
f0100549:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f010054f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100553:	66 81 3d 28 a2 22 f0 	cmpw   $0x7cf,0xf022a228
f010055a:	cf 07 
f010055c:	76 43                	jbe    f01005a1 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010055e:	a1 2c a2 22 f0       	mov    0xf022a22c,%eax
f0100563:	83 ec 04             	sub    $0x4,%esp
f0100566:	68 00 0f 00 00       	push   $0xf00
f010056b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100571:	52                   	push   %edx
f0100572:	50                   	push   %eax
f0100573:	e8 a1 47 00 00       	call   f0104d19 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100578:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f010057e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100584:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010058a:	83 c4 10             	add    $0x10,%esp
f010058d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100592:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100595:	39 d0                	cmp    %edx,%eax
f0100597:	75 f4                	jne    f010058d <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100599:	66 83 2d 28 a2 22 f0 	subw   $0x50,0xf022a228
f01005a0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005a1:	8b 0d 30 a2 22 f0    	mov    0xf022a230,%ecx
f01005a7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ac:	89 ca                	mov    %ecx,%edx
f01005ae:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005af:	0f b7 1d 28 a2 22 f0 	movzwl 0xf022a228,%ebx
f01005b6:	8d 71 01             	lea    0x1(%ecx),%esi
f01005b9:	89 d8                	mov    %ebx,%eax
f01005bb:	66 c1 e8 08          	shr    $0x8,%ax
f01005bf:	89 f2                	mov    %esi,%edx
f01005c1:	ee                   	out    %al,(%dx)
f01005c2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005c7:	89 ca                	mov    %ecx,%edx
f01005c9:	ee                   	out    %al,(%dx)
f01005ca:	89 d8                	mov    %ebx,%eax
f01005cc:	89 f2                	mov    %esi,%edx
f01005ce:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005cf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005d2:	5b                   	pop    %ebx
f01005d3:	5e                   	pop    %esi
f01005d4:	5f                   	pop    %edi
f01005d5:	5d                   	pop    %ebp
f01005d6:	c3                   	ret    

f01005d7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005d7:	80 3d 34 a2 22 f0 00 	cmpb   $0x0,0xf022a234
f01005de:	74 11                	je     f01005f1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005e0:	55                   	push   %ebp
f01005e1:	89 e5                	mov    %esp,%ebp
f01005e3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005e6:	b8 81 02 10 f0       	mov    $0xf0100281,%eax
f01005eb:	e8 b0 fc ff ff       	call   f01002a0 <cons_intr>
}
f01005f0:	c9                   	leave  
f01005f1:	f3 c3                	repz ret 

f01005f3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005f3:	55                   	push   %ebp
f01005f4:	89 e5                	mov    %esp,%ebp
f01005f6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005f9:	b8 e3 02 10 f0       	mov    $0xf01002e3,%eax
f01005fe:	e8 9d fc ff ff       	call   f01002a0 <cons_intr>
}
f0100603:	c9                   	leave  
f0100604:	c3                   	ret    

f0100605 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100605:	55                   	push   %ebp
f0100606:	89 e5                	mov    %esp,%ebp
f0100608:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010060b:	e8 c7 ff ff ff       	call   f01005d7 <serial_intr>
	kbd_intr();
f0100610:	e8 de ff ff ff       	call   f01005f3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100615:	a1 20 a2 22 f0       	mov    0xf022a220,%eax
f010061a:	3b 05 24 a2 22 f0    	cmp    0xf022a224,%eax
f0100620:	74 26                	je     f0100648 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100622:	8d 50 01             	lea    0x1(%eax),%edx
f0100625:	89 15 20 a2 22 f0    	mov    %edx,0xf022a220
f010062b:	0f b6 88 20 a0 22 f0 	movzbl -0xfdd5fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100632:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100634:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010063a:	75 11                	jne    f010064d <cons_getc+0x48>
			cons.rpos = 0;
f010063c:	c7 05 20 a2 22 f0 00 	movl   $0x0,0xf022a220
f0100643:	00 00 00 
f0100646:	eb 05                	jmp    f010064d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100648:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010064d:	c9                   	leave  
f010064e:	c3                   	ret    

f010064f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010064f:	55                   	push   %ebp
f0100650:	89 e5                	mov    %esp,%ebp
f0100652:	57                   	push   %edi
f0100653:	56                   	push   %esi
f0100654:	53                   	push   %ebx
f0100655:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100658:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010065f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100666:	5a a5 
	if (*cp != 0xA55A) {
f0100668:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010066f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100673:	74 11                	je     f0100686 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100675:	c7 05 30 a2 22 f0 b4 	movl   $0x3b4,0xf022a230
f010067c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010067f:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100684:	eb 16                	jmp    f010069c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100686:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010068d:	c7 05 30 a2 22 f0 d4 	movl   $0x3d4,0xf022a230
f0100694:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100697:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010069c:	8b 3d 30 a2 22 f0    	mov    0xf022a230,%edi
f01006a2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006a7:	89 fa                	mov    %edi,%edx
f01006a9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006aa:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ad:	89 da                	mov    %ebx,%edx
f01006af:	ec                   	in     (%dx),%al
f01006b0:	0f b6 c8             	movzbl %al,%ecx
f01006b3:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006b6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006bb:	89 fa                	mov    %edi,%edx
f01006bd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006be:	89 da                	mov    %ebx,%edx
f01006c0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006c1:	89 35 2c a2 22 f0    	mov    %esi,0xf022a22c
	crt_pos = pos;
f01006c7:	0f b6 c0             	movzbl %al,%eax
f01006ca:	09 c8                	or     %ecx,%eax
f01006cc:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006d2:	e8 1c ff ff ff       	call   f01005f3 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f01006d7:	83 ec 0c             	sub    $0xc,%esp
f01006da:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f01006e1:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006e6:	50                   	push   %eax
f01006e7:	e8 58 2e 00 00       	call   f0103544 <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006ec:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f6:	89 f2                	mov    %esi,%edx
f01006f8:	ee                   	out    %al,(%dx)
f01006f9:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01006fe:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100703:	ee                   	out    %al,(%dx)
f0100704:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100709:	b8 0c 00 00 00       	mov    $0xc,%eax
f010070e:	89 da                	mov    %ebx,%edx
f0100710:	ee                   	out    %al,(%dx)
f0100711:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100716:	b8 00 00 00 00       	mov    $0x0,%eax
f010071b:	ee                   	out    %al,(%dx)
f010071c:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100721:	b8 03 00 00 00       	mov    $0x3,%eax
f0100726:	ee                   	out    %al,(%dx)
f0100727:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010072c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100731:	ee                   	out    %al,(%dx)
f0100732:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100737:	b8 01 00 00 00       	mov    $0x1,%eax
f010073c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010073d:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100742:	ec                   	in     (%dx),%al
f0100743:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100745:	83 c4 10             	add    $0x10,%esp
f0100748:	3c ff                	cmp    $0xff,%al
f010074a:	0f 95 05 34 a2 22 f0 	setne  0xf022a234
f0100751:	89 f2                	mov    %esi,%edx
f0100753:	ec                   	in     (%dx),%al
f0100754:	89 da                	mov    %ebx,%edx
f0100756:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100757:	80 f9 ff             	cmp    $0xff,%cl
f010075a:	75 10                	jne    f010076c <cons_init+0x11d>
		cprintf("Serial port does not exist!\n");
f010075c:	83 ec 0c             	sub    $0xc,%esp
f010075f:	68 4f 5a 10 f0       	push   $0xf0105a4f
f0100764:	e8 2c 2f 00 00       	call   f0103695 <cprintf>
f0100769:	83 c4 10             	add    $0x10,%esp
}
f010076c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010076f:	5b                   	pop    %ebx
f0100770:	5e                   	pop    %esi
f0100771:	5f                   	pop    %edi
f0100772:	5d                   	pop    %ebp
f0100773:	c3                   	ret    

f0100774 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100774:	55                   	push   %ebp
f0100775:	89 e5                	mov    %esp,%ebp
f0100777:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010077a:	8b 45 08             	mov    0x8(%ebp),%eax
f010077d:	e8 6c fc ff ff       	call   f01003ee <cons_putc>
}
f0100782:	c9                   	leave  
f0100783:	c3                   	ret    

f0100784 <getchar>:

int
getchar(void)
{
f0100784:	55                   	push   %ebp
f0100785:	89 e5                	mov    %esp,%ebp
f0100787:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010078a:	e8 76 fe ff ff       	call   f0100605 <cons_getc>
f010078f:	85 c0                	test   %eax,%eax
f0100791:	74 f7                	je     f010078a <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100793:	c9                   	leave  
f0100794:	c3                   	ret    

f0100795 <iscons>:

int
iscons(int fdnum)
{
f0100795:	55                   	push   %ebp
f0100796:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100798:	b8 01 00 00 00       	mov    $0x1,%eax
f010079d:	5d                   	pop    %ebp
f010079e:	c3                   	ret    

f010079f <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010079f:	55                   	push   %ebp
f01007a0:	89 e5                	mov    %esp,%ebp
f01007a2:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007a5:	68 a0 5c 10 f0       	push   $0xf0105ca0
f01007aa:	68 be 5c 10 f0       	push   $0xf0105cbe
f01007af:	68 c3 5c 10 f0       	push   $0xf0105cc3
f01007b4:	e8 dc 2e 00 00       	call   f0103695 <cprintf>
f01007b9:	83 c4 0c             	add    $0xc,%esp
f01007bc:	68 58 5d 10 f0       	push   $0xf0105d58
f01007c1:	68 cc 5c 10 f0       	push   $0xf0105ccc
f01007c6:	68 c3 5c 10 f0       	push   $0xf0105cc3
f01007cb:	e8 c5 2e 00 00       	call   f0103695 <cprintf>
f01007d0:	83 c4 0c             	add    $0xc,%esp
f01007d3:	68 80 5d 10 f0       	push   $0xf0105d80
f01007d8:	68 d5 5c 10 f0       	push   $0xf0105cd5
f01007dd:	68 c3 5c 10 f0       	push   $0xf0105cc3
f01007e2:	e8 ae 2e 00 00       	call   f0103695 <cprintf>
	return 0;
}
f01007e7:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ec:	c9                   	leave  
f01007ed:	c3                   	ret    

f01007ee <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007ee:	55                   	push   %ebp
f01007ef:	89 e5                	mov    %esp,%ebp
f01007f1:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007f4:	68 df 5c 10 f0       	push   $0xf0105cdf
f01007f9:	e8 97 2e 00 00       	call   f0103695 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007fe:	83 c4 08             	add    $0x8,%esp
f0100801:	68 0c 00 10 00       	push   $0x10000c
f0100806:	68 a8 5d 10 f0       	push   $0xf0105da8
f010080b:	e8 85 2e 00 00       	call   f0103695 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100810:	83 c4 0c             	add    $0xc,%esp
f0100813:	68 0c 00 10 00       	push   $0x10000c
f0100818:	68 0c 00 10 f0       	push   $0xf010000c
f010081d:	68 d0 5d 10 f0       	push   $0xf0105dd0
f0100822:	e8 6e 2e 00 00       	call   f0103695 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100827:	83 c4 0c             	add    $0xc,%esp
f010082a:	68 71 59 10 00       	push   $0x105971
f010082f:	68 71 59 10 f0       	push   $0xf0105971
f0100834:	68 f4 5d 10 f0       	push   $0xf0105df4
f0100839:	e8 57 2e 00 00       	call   f0103695 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010083e:	83 c4 0c             	add    $0xc,%esp
f0100841:	68 98 95 22 00       	push   $0x229598
f0100846:	68 98 95 22 f0       	push   $0xf0229598
f010084b:	68 18 5e 10 f0       	push   $0xf0105e18
f0100850:	e8 40 2e 00 00       	call   f0103695 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100855:	83 c4 0c             	add    $0xc,%esp
f0100858:	68 08 c0 26 00       	push   $0x26c008
f010085d:	68 08 c0 26 f0       	push   $0xf026c008
f0100862:	68 3c 5e 10 f0       	push   $0xf0105e3c
f0100867:	e8 29 2e 00 00       	call   f0103695 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010086c:	b8 07 c4 26 f0       	mov    $0xf026c407,%eax
f0100871:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100876:	83 c4 08             	add    $0x8,%esp
f0100879:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010087e:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100884:	85 c0                	test   %eax,%eax
f0100886:	0f 48 c2             	cmovs  %edx,%eax
f0100889:	c1 f8 0a             	sar    $0xa,%eax
f010088c:	50                   	push   %eax
f010088d:	68 60 5e 10 f0       	push   $0xf0105e60
f0100892:	e8 fe 2d 00 00       	call   f0103695 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100897:	b8 00 00 00 00       	mov    $0x0,%eax
f010089c:	c9                   	leave  
f010089d:	c3                   	ret    

f010089e <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010089e:	55                   	push   %ebp
f010089f:	89 e5                	mov    %esp,%ebp
f01008a1:	57                   	push   %edi
f01008a2:	56                   	push   %esi
f01008a3:	53                   	push   %ebx
f01008a4:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01008a7:	89 eb                	mov    %ebp,%ebx
	struct Eipdebuginfo info;        
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();

	cprintf("Stack backtrace:\r\n");
f01008a9:	68 f8 5c 10 f0       	push   $0xf0105cf8
f01008ae:	e8 e2 2d 00 00       	call   f0103695 <cprintf>
	while (ebp != 0)
f01008b3:	83 c4 10             	add    $0x10,%esp
	{
		eip = ebp[1];
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]); //%08x 补0输出8位16进制数
		debuginfo_eip((uintptr_t)eip, &info);
f01008b6:	8d 7d d0             	lea    -0x30(%ebp),%edi
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();

	cprintf("Stack backtrace:\r\n");
	while (ebp != 0)
f01008b9:	eb 53                	jmp    f010090e <mon_backtrace+0x70>
	{
		eip = ebp[1];
f01008bb:	8b 73 04             	mov    0x4(%ebx),%esi
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]); //%08x 补0输出8位16进制数
f01008be:	ff 73 18             	pushl  0x18(%ebx)
f01008c1:	ff 73 14             	pushl  0x14(%ebx)
f01008c4:	ff 73 10             	pushl  0x10(%ebx)
f01008c7:	ff 73 0c             	pushl  0xc(%ebx)
f01008ca:	ff 73 08             	pushl  0x8(%ebx)
f01008cd:	56                   	push   %esi
f01008ce:	53                   	push   %ebx
f01008cf:	68 8c 5e 10 f0       	push   $0xf0105e8c
f01008d4:	e8 bc 2d 00 00       	call   f0103695 <cprintf>
		debuginfo_eip((uintptr_t)eip, &info);
f01008d9:	83 c4 18             	add    $0x18,%esp
f01008dc:	57                   	push   %edi
f01008dd:	56                   	push   %esi
f01008de:	e8 b4 39 00 00       	call   f0104297 <debuginfo_eip>
		cprintf("%s:%d", info.eip_file, info.eip_line);
f01008e3:	83 c4 0c             	add    $0xc,%esp
f01008e6:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008e9:	ff 75 d0             	pushl  -0x30(%ebp)
f01008ec:	68 0b 5d 10 f0       	push   $0xf0105d0b
f01008f1:	e8 9f 2d 00 00       	call   f0103695 <cprintf>
		cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name, info.eip_fn_addr);
f01008f6:	ff 75 e0             	pushl  -0x20(%ebp)
f01008f9:	ff 75 d8             	pushl  -0x28(%ebp)
f01008fc:	ff 75 dc             	pushl  -0x24(%ebp)
f01008ff:	68 11 5d 10 f0       	push   $0xf0105d11
f0100904:	e8 8c 2d 00 00       	call   f0103695 <cprintf>
		ebp = (uint32_t *)ebp[0];
f0100909:	8b 1b                	mov    (%ebx),%ebx
f010090b:	83 c4 20             	add    $0x20,%esp
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();

	cprintf("Stack backtrace:\r\n");
	while (ebp != 0)
f010090e:	85 db                	test   %ebx,%ebx
f0100910:	75 a9                	jne    f01008bb <mon_backtrace+0x1d>
		cprintf("%s:%d", info.eip_file, info.eip_line);
		cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name, info.eip_fn_addr);
		ebp = (uint32_t *)ebp[0];
	}
	return 0;
}
f0100912:	b8 00 00 00 00       	mov    $0x0,%eax
f0100917:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010091a:	5b                   	pop    %ebx
f010091b:	5e                   	pop    %esi
f010091c:	5f                   	pop    %edi
f010091d:	5d                   	pop    %ebp
f010091e:	c3                   	ret    

f010091f <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010091f:	55                   	push   %ebp
f0100920:	89 e5                	mov    %esp,%ebp
f0100922:	57                   	push   %edi
f0100923:	56                   	push   %esi
f0100924:	53                   	push   %ebx
f0100925:	83 ec 58             	sub    $0x58,%esp
	char *buf; 
	cprintf("Welcome to the JOS kernel monitor!\n");
f0100928:	68 c4 5e 10 f0       	push   $0xf0105ec4
f010092d:	e8 63 2d 00 00       	call   f0103695 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100932:	c7 04 24 e8 5e 10 f0 	movl   $0xf0105ee8,(%esp)
f0100939:	e8 57 2d 00 00       	call   f0103695 <cprintf>

	if (tf != NULL)
f010093e:	83 c4 10             	add    $0x10,%esp
f0100941:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100945:	74 0e                	je     f0100955 <monitor+0x36>
		print_trapframe(tf);
f0100947:	83 ec 0c             	sub    $0xc,%esp
f010094a:	ff 75 08             	pushl  0x8(%ebp)
f010094d:	e8 7c 31 00 00       	call   f0103ace <print_trapframe>
f0100952:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100955:	83 ec 0c             	sub    $0xc,%esp
f0100958:	68 1c 5d 10 f0       	push   $0xf0105d1c
f010095d:	e8 13 41 00 00       	call   f0104a75 <readline>
f0100962:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100964:	83 c4 10             	add    $0x10,%esp
f0100967:	85 c0                	test   %eax,%eax
f0100969:	74 ea                	je     f0100955 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010096b:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100972:	be 00 00 00 00       	mov    $0x0,%esi
f0100977:	eb 0a                	jmp    f0100983 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100979:	c6 03 00             	movb   $0x0,(%ebx)
f010097c:	89 f7                	mov    %esi,%edi
f010097e:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100981:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100983:	0f b6 03             	movzbl (%ebx),%eax
f0100986:	84 c0                	test   %al,%al
f0100988:	74 63                	je     f01009ed <monitor+0xce>
f010098a:	83 ec 08             	sub    $0x8,%esp
f010098d:	0f be c0             	movsbl %al,%eax
f0100990:	50                   	push   %eax
f0100991:	68 20 5d 10 f0       	push   $0xf0105d20
f0100996:	e8 f4 42 00 00       	call   f0104c8f <strchr>
f010099b:	83 c4 10             	add    $0x10,%esp
f010099e:	85 c0                	test   %eax,%eax
f01009a0:	75 d7                	jne    f0100979 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f01009a2:	80 3b 00             	cmpb   $0x0,(%ebx)
f01009a5:	74 46                	je     f01009ed <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01009a7:	83 fe 0f             	cmp    $0xf,%esi
f01009aa:	75 14                	jne    f01009c0 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009ac:	83 ec 08             	sub    $0x8,%esp
f01009af:	6a 10                	push   $0x10
f01009b1:	68 25 5d 10 f0       	push   $0xf0105d25
f01009b6:	e8 da 2c 00 00       	call   f0103695 <cprintf>
f01009bb:	83 c4 10             	add    $0x10,%esp
f01009be:	eb 95                	jmp    f0100955 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01009c0:	8d 7e 01             	lea    0x1(%esi),%edi
f01009c3:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009c7:	eb 03                	jmp    f01009cc <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01009c9:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009cc:	0f b6 03             	movzbl (%ebx),%eax
f01009cf:	84 c0                	test   %al,%al
f01009d1:	74 ae                	je     f0100981 <monitor+0x62>
f01009d3:	83 ec 08             	sub    $0x8,%esp
f01009d6:	0f be c0             	movsbl %al,%eax
f01009d9:	50                   	push   %eax
f01009da:	68 20 5d 10 f0       	push   $0xf0105d20
f01009df:	e8 ab 42 00 00       	call   f0104c8f <strchr>
f01009e4:	83 c4 10             	add    $0x10,%esp
f01009e7:	85 c0                	test   %eax,%eax
f01009e9:	74 de                	je     f01009c9 <monitor+0xaa>
f01009eb:	eb 94                	jmp    f0100981 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01009ed:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009f4:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009f5:	85 f6                	test   %esi,%esi
f01009f7:	0f 84 58 ff ff ff    	je     f0100955 <monitor+0x36>
f01009fd:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a02:	83 ec 08             	sub    $0x8,%esp
f0100a05:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a08:	ff 34 85 20 5f 10 f0 	pushl  -0xfefa0e0(,%eax,4)
f0100a0f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a12:	e8 1a 42 00 00       	call   f0104c31 <strcmp>
f0100a17:	83 c4 10             	add    $0x10,%esp
f0100a1a:	85 c0                	test   %eax,%eax
f0100a1c:	75 21                	jne    f0100a3f <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f0100a1e:	83 ec 04             	sub    $0x4,%esp
f0100a21:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a24:	ff 75 08             	pushl  0x8(%ebp)
f0100a27:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a2a:	52                   	push   %edx
f0100a2b:	56                   	push   %esi
f0100a2c:	ff 14 85 28 5f 10 f0 	call   *-0xfefa0d8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a33:	83 c4 10             	add    $0x10,%esp
f0100a36:	85 c0                	test   %eax,%eax
f0100a38:	78 25                	js     f0100a5f <monitor+0x140>
f0100a3a:	e9 16 ff ff ff       	jmp    f0100955 <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100a3f:	83 c3 01             	add    $0x1,%ebx
f0100a42:	83 fb 03             	cmp    $0x3,%ebx
f0100a45:	75 bb                	jne    f0100a02 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a47:	83 ec 08             	sub    $0x8,%esp
f0100a4a:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a4d:	68 42 5d 10 f0       	push   $0xf0105d42
f0100a52:	e8 3e 2c 00 00       	call   f0103695 <cprintf>
f0100a57:	83 c4 10             	add    $0x10,%esp
f0100a5a:	e9 f6 fe ff ff       	jmp    f0100955 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a5f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a62:	5b                   	pop    %ebx
f0100a63:	5e                   	pop    %esi
f0100a64:	5f                   	pop    %edi
f0100a65:	5d                   	pop    %ebp
f0100a66:	c3                   	ret    

f0100a67 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a67:	55                   	push   %ebp
f0100a68:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a6a:	83 3d 38 a2 22 f0 00 	cmpl   $0x0,0xf022a238
f0100a71:	75 11                	jne    f0100a84 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a73:	ba 07 d0 26 f0       	mov    $0xf026d007,%edx
f0100a78:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a7e:	89 15 38 a2 22 f0    	mov    %edx,0xf022a238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100a84:	8b 0d 38 a2 22 f0    	mov    0xf022a238,%ecx
	nextfree += n;
	nextfree = ROUNDUP( (char*)nextfree, PGSIZE);
f0100a8a:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100a91:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a97:	89 15 38 a2 22 f0    	mov    %edx,0xf022a238
	//nextfree += ROUNDUP(n,PGSIZE);
	return result;
}
f0100a9d:	89 c8                	mov    %ecx,%eax
f0100a9f:	5d                   	pop    %ebp
f0100aa0:	c3                   	ret    

f0100aa1 <check_va2pa>:
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];

	if (!(*pgdir & PTE_P))
f0100aa1:	89 d1                	mov    %edx,%ecx
f0100aa3:	c1 e9 16             	shr    $0x16,%ecx
f0100aa6:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100aa9:	a8 01                	test   $0x1,%al
f0100aab:	74 52                	je     f0100aff <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100aad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ab2:	89 c1                	mov    %eax,%ecx
f0100ab4:	c1 e9 0c             	shr    $0xc,%ecx
f0100ab7:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0100abd:	72 1b                	jb     f0100ada <check_va2pa+0x39>
// defined by the page directory 'pgdir'.  The hardware normally performs
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100abf:	55                   	push   %ebp
f0100ac0:	89 e5                	mov    %esp,%ebp
f0100ac2:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ac5:	50                   	push   %eax
f0100ac6:	68 a4 59 10 f0       	push   $0xf01059a4
f0100acb:	68 da 03 00 00       	push   $0x3da
f0100ad0:	68 41 68 10 f0       	push   $0xf0106841
f0100ad5:	e8 66 f5 ff ff       	call   f0100040 <_panic>
	pgdir = &pgdir[PDX(va)];

	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100ada:	c1 ea 0c             	shr    $0xc,%edx
f0100add:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100ae3:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100aea:	89 c2                	mov    %eax,%edx
f0100aec:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100aef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100af4:	85 d2                	test   %edx,%edx
f0100af6:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100afb:	0f 44 c2             	cmove  %edx,%eax
f0100afe:	c3                   	ret    
	pte_t *p;

	pgdir = &pgdir[PDX(va)];

	if (!(*pgdir & PTE_P))
		return ~0;
f0100aff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b04:	c3                   	ret    

f0100b05 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100b05:	55                   	push   %ebp
f0100b06:	89 e5                	mov    %esp,%ebp
f0100b08:	57                   	push   %edi
f0100b09:	56                   	push   %esi
f0100b0a:	53                   	push   %ebx
f0100b0b:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b0e:	84 c0                	test   %al,%al
f0100b10:	0f 85 91 02 00 00    	jne    f0100da7 <check_page_free_list+0x2a2>
f0100b16:	e9 9e 02 00 00       	jmp    f0100db9 <check_page_free_list+0x2b4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100b1b:	83 ec 04             	sub    $0x4,%esp
f0100b1e:	68 44 5f 10 f0       	push   $0xf0105f44
f0100b23:	68 0f 03 00 00       	push   $0x30f
f0100b28:	68 41 68 10 f0       	push   $0xf0106841
f0100b2d:	e8 0e f5 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100b32:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b35:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b38:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b3b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b3e:	89 c2                	mov    %eax,%edx
f0100b40:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0100b46:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b4c:	0f 95 c2             	setne  %dl
f0100b4f:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b52:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b56:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b58:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b5c:	8b 00                	mov    (%eax),%eax
f0100b5e:	85 c0                	test   %eax,%eax
f0100b60:	75 dc                	jne    f0100b3e <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b62:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b65:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b6b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b6e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b71:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b73:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b76:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b7b:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b80:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f0100b86:	eb 53                	jmp    f0100bdb <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b88:	89 d8                	mov    %ebx,%eax
f0100b8a:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100b90:	c1 f8 03             	sar    $0x3,%eax
f0100b93:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b96:	89 c2                	mov    %eax,%edx
f0100b98:	c1 ea 16             	shr    $0x16,%edx
f0100b9b:	39 f2                	cmp    %esi,%edx
f0100b9d:	73 3a                	jae    f0100bd9 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b9f:	89 c2                	mov    %eax,%edx
f0100ba1:	c1 ea 0c             	shr    $0xc,%edx
f0100ba4:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100baa:	72 12                	jb     f0100bbe <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bac:	50                   	push   %eax
f0100bad:	68 a4 59 10 f0       	push   $0xf01059a4
f0100bb2:	6a 58                	push   $0x58
f0100bb4:	68 4d 68 10 f0       	push   $0xf010684d
f0100bb9:	e8 82 f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100bbe:	83 ec 04             	sub    $0x4,%esp
f0100bc1:	68 80 00 00 00       	push   $0x80
f0100bc6:	68 97 00 00 00       	push   $0x97
f0100bcb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bd0:	50                   	push   %eax
f0100bd1:	e8 f6 40 00 00       	call   f0104ccc <memset>
f0100bd6:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bd9:	8b 1b                	mov    (%ebx),%ebx
f0100bdb:	85 db                	test   %ebx,%ebx
f0100bdd:	75 a9                	jne    f0100b88 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100bdf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100be4:	e8 7e fe ff ff       	call   f0100a67 <boot_alloc>
f0100be9:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bec:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bf2:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
		assert(pp < pages + npages);
f0100bf8:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0100bfd:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100c00:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100c03:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c06:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c09:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c0e:	e9 52 01 00 00       	jmp    f0100d65 <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c13:	39 ca                	cmp    %ecx,%edx
f0100c15:	73 19                	jae    f0100c30 <check_page_free_list+0x12b>
f0100c17:	68 5b 68 10 f0       	push   $0xf010685b
f0100c1c:	68 67 68 10 f0       	push   $0xf0106867
f0100c21:	68 29 03 00 00       	push   $0x329
f0100c26:	68 41 68 10 f0       	push   $0xf0106841
f0100c2b:	e8 10 f4 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c30:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c33:	72 19                	jb     f0100c4e <check_page_free_list+0x149>
f0100c35:	68 7c 68 10 f0       	push   $0xf010687c
f0100c3a:	68 67 68 10 f0       	push   $0xf0106867
f0100c3f:	68 2a 03 00 00       	push   $0x32a
f0100c44:	68 41 68 10 f0       	push   $0xf0106841
f0100c49:	e8 f2 f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c4e:	89 d0                	mov    %edx,%eax
f0100c50:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c53:	a8 07                	test   $0x7,%al
f0100c55:	74 19                	je     f0100c70 <check_page_free_list+0x16b>
f0100c57:	68 68 5f 10 f0       	push   $0xf0105f68
f0100c5c:	68 67 68 10 f0       	push   $0xf0106867
f0100c61:	68 2b 03 00 00       	push   $0x32b
f0100c66:	68 41 68 10 f0       	push   $0xf0106841
f0100c6b:	e8 d0 f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c70:	c1 f8 03             	sar    $0x3,%eax
f0100c73:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c76:	85 c0                	test   %eax,%eax
f0100c78:	75 19                	jne    f0100c93 <check_page_free_list+0x18e>
f0100c7a:	68 90 68 10 f0       	push   $0xf0106890
f0100c7f:	68 67 68 10 f0       	push   $0xf0106867
f0100c84:	68 2e 03 00 00       	push   $0x32e
f0100c89:	68 41 68 10 f0       	push   $0xf0106841
f0100c8e:	e8 ad f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c93:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c98:	75 19                	jne    f0100cb3 <check_page_free_list+0x1ae>
f0100c9a:	68 a1 68 10 f0       	push   $0xf01068a1
f0100c9f:	68 67 68 10 f0       	push   $0xf0106867
f0100ca4:	68 2f 03 00 00       	push   $0x32f
f0100ca9:	68 41 68 10 f0       	push   $0xf0106841
f0100cae:	e8 8d f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cb3:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cb8:	75 19                	jne    f0100cd3 <check_page_free_list+0x1ce>
f0100cba:	68 9c 5f 10 f0       	push   $0xf0105f9c
f0100cbf:	68 67 68 10 f0       	push   $0xf0106867
f0100cc4:	68 30 03 00 00       	push   $0x330
f0100cc9:	68 41 68 10 f0       	push   $0xf0106841
f0100cce:	e8 6d f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cd3:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cd8:	75 19                	jne    f0100cf3 <check_page_free_list+0x1ee>
f0100cda:	68 ba 68 10 f0       	push   $0xf01068ba
f0100cdf:	68 67 68 10 f0       	push   $0xf0106867
f0100ce4:	68 31 03 00 00       	push   $0x331
f0100ce9:	68 41 68 10 f0       	push   $0xf0106841
f0100cee:	e8 4d f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cf3:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cf8:	0f 86 de 00 00 00    	jbe    f0100ddc <check_page_free_list+0x2d7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cfe:	89 c7                	mov    %eax,%edi
f0100d00:	c1 ef 0c             	shr    $0xc,%edi
f0100d03:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100d06:	77 12                	ja     f0100d1a <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d08:	50                   	push   %eax
f0100d09:	68 a4 59 10 f0       	push   $0xf01059a4
f0100d0e:	6a 58                	push   $0x58
f0100d10:	68 4d 68 10 f0       	push   $0xf010684d
f0100d15:	e8 26 f3 ff ff       	call   f0100040 <_panic>
f0100d1a:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100d20:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100d23:	0f 86 a7 00 00 00    	jbe    f0100dd0 <check_page_free_list+0x2cb>
f0100d29:	68 c0 5f 10 f0       	push   $0xf0105fc0
f0100d2e:	68 67 68 10 f0       	push   $0xf0106867
f0100d33:	68 32 03 00 00       	push   $0x332
f0100d38:	68 41 68 10 f0       	push   $0xf0106841
f0100d3d:	e8 fe f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d42:	68 d4 68 10 f0       	push   $0xf01068d4
f0100d47:	68 67 68 10 f0       	push   $0xf0106867
f0100d4c:	68 34 03 00 00       	push   $0x334
f0100d51:	68 41 68 10 f0       	push   $0xf0106841
f0100d56:	e8 e5 f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d5b:	83 c6 01             	add    $0x1,%esi
f0100d5e:	eb 03                	jmp    f0100d63 <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100d60:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d63:	8b 12                	mov    (%edx),%edx
f0100d65:	85 d2                	test   %edx,%edx
f0100d67:	0f 85 a6 fe ff ff    	jne    f0100c13 <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d6d:	85 f6                	test   %esi,%esi
f0100d6f:	7f 19                	jg     f0100d8a <check_page_free_list+0x285>
f0100d71:	68 f1 68 10 f0       	push   $0xf01068f1
f0100d76:	68 67 68 10 f0       	push   $0xf0106867
f0100d7b:	68 3c 03 00 00       	push   $0x33c
f0100d80:	68 41 68 10 f0       	push   $0xf0106841
f0100d85:	e8 b6 f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100d8a:	85 db                	test   %ebx,%ebx
f0100d8c:	7f 5e                	jg     f0100dec <check_page_free_list+0x2e7>
f0100d8e:	68 03 69 10 f0       	push   $0xf0106903
f0100d93:	68 67 68 10 f0       	push   $0xf0106867
f0100d98:	68 3d 03 00 00       	push   $0x33d
f0100d9d:	68 41 68 10 f0       	push   $0xf0106841
f0100da2:	e8 99 f2 ff ff       	call   f0100040 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100da7:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0100dac:	85 c0                	test   %eax,%eax
f0100dae:	0f 85 7e fd ff ff    	jne    f0100b32 <check_page_free_list+0x2d>
f0100db4:	e9 62 fd ff ff       	jmp    f0100b1b <check_page_free_list+0x16>
f0100db9:	83 3d 40 a2 22 f0 00 	cmpl   $0x0,0xf022a240
f0100dc0:	0f 84 55 fd ff ff    	je     f0100b1b <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100dc6:	be 00 04 00 00       	mov    $0x400,%esi
f0100dcb:	e9 b0 fd ff ff       	jmp    f0100b80 <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100dd0:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100dd5:	75 89                	jne    f0100d60 <check_page_free_list+0x25b>
f0100dd7:	e9 66 ff ff ff       	jmp    f0100d42 <check_page_free_list+0x23d>
f0100ddc:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100de1:	0f 85 74 ff ff ff    	jne    f0100d5b <check_page_free_list+0x256>
f0100de7:	e9 56 ff ff ff       	jmp    f0100d42 <check_page_free_list+0x23d>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100dec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100def:	5b                   	pop    %ebx
f0100df0:	5e                   	pop    %esi
f0100df1:	5f                   	pop    %edi
f0100df2:	5d                   	pop    %ebp
f0100df3:	c3                   	ret    

f0100df4 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100df4:	55                   	push   %ebp
f0100df5:	89 e5                	mov    %esp,%ebp
f0100df7:	56                   	push   %esi
f0100df8:	53                   	push   %ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!

	//  1) Mark physical page 0 as in use.
	pages[0].pp_ref = 1;
f0100df9:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0100dfe:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;	
f0100e04:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	size_t i;
	//临界点是否等于可能存在问题
	for (i = 1; i < npages; i++) {
f0100e0a:	be 08 00 00 00       	mov    $0x8,%esi
f0100e0f:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100e14:	e9 c7 00 00 00       	jmp    f0100ee0 <page_init+0xec>
		//lab4
		if (i == ROUNDUP(MPENTRY_PADDR, PGSIZE) / PGSIZE) {
f0100e19:	83 fb 07             	cmp    $0x7,%ebx
f0100e1c:	75 17                	jne    f0100e35 <page_init+0x41>
        	pages[i].pp_ref = 1;
f0100e1e:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0100e23:	66 c7 40 3c 01 00    	movw   $0x1,0x3c(%eax)
			pages[i].pp_link = NULL;
f0100e29:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
        	continue;
f0100e30:	e9 a5 00 00 00       	jmp    f0100eda <page_init+0xe6>
    	}

		
	//  2) The rest of base memory
		if(i < npages_basemem){
f0100e35:	3b 1d 44 a2 22 f0    	cmp    0xf022a244,%ebx
f0100e3b:	73 25                	jae    f0100e62 <page_init+0x6e>
			pages[i].pp_ref = 0;
f0100e3d:	89 f0                	mov    %esi,%eax
f0100e3f:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100e45:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100e4b:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100e51:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100e53:	89 f0                	mov    %esi,%eax
f0100e55:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100e5b:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
f0100e60:	eb 78                	jmp    f0100eda <page_init+0xe6>
		}
	//  3) Then comes the IO hole 
		else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE){
f0100e62:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100e68:	83 f8 5f             	cmp    $0x5f,%eax
f0100e6b:	77 16                	ja     f0100e83 <page_init+0x8f>
			pages[i].pp_ref = 1;
f0100e6d:	89 f0                	mov    %esi,%eax
f0100e6f:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100e75:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100e7b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100e81:	eb 57                	jmp    f0100eda <page_init+0xe6>
		}
	//  4) Then extended memory
		else if(i >= EXTPHYSMEM/PGSIZE && i< ((int)boot_alloc(0) - KERNBASE)/PGSIZE){
f0100e83:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100e89:	76 2c                	jbe    f0100eb7 <page_init+0xc3>
f0100e8b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e90:	e8 d2 fb ff ff       	call   f0100a67 <boot_alloc>
f0100e95:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e9a:	c1 e8 0c             	shr    $0xc,%eax
f0100e9d:	39 c3                	cmp    %eax,%ebx
f0100e9f:	73 16                	jae    f0100eb7 <page_init+0xc3>
			pages[i].pp_ref = 1;
f0100ea1:	89 f0                	mov    %esi,%eax
f0100ea3:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100ea9:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100eaf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100eb5:	eb 23                	jmp    f0100eda <page_init+0xe6>
		}
		else{
			pages[i].pp_ref = 0;
f0100eb7:	89 f0                	mov    %esi,%eax
f0100eb9:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100ebf:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100ec5:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100ecb:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100ecd:	89 f0                	mov    %esi,%eax
f0100ecf:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100ed5:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
	//  1) Mark physical page 0 as in use.
	pages[0].pp_ref = 1;
	pages[0].pp_link = NULL;	
	size_t i;
	//临界点是否等于可能存在问题
	for (i = 1; i < npages; i++) {
f0100eda:	83 c3 01             	add    $0x1,%ebx
f0100edd:	83 c6 08             	add    $0x8,%esi
f0100ee0:	3b 1d 88 ae 22 f0    	cmp    0xf022ae88,%ebx
f0100ee6:	0f 82 2d ff ff ff    	jb     f0100e19 <page_init+0x25>

	//要在循环里判断，否者该项以及在page_free_list中
	//i = ROUNDUP(MPENTRY_PADDR, PGSIZE) / PGSIZE;
	//pages[i].pp_ref = 1;
	//pages[i].pp_link = NULL;
}
f0100eec:	5b                   	pop    %ebx
f0100eed:	5e                   	pop    %esi
f0100eee:	5d                   	pop    %ebp
f0100eef:	c3                   	ret    

f0100ef0 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100ef0:	55                   	push   %ebp
f0100ef1:	89 e5                	mov    %esp,%ebp
f0100ef3:	53                   	push   %ebx
f0100ef4:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if(page_free_list == NULL)
f0100ef7:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f0100efd:	85 db                	test   %ebx,%ebx
f0100eff:	74 5e                	je     f0100f5f <page_alloc+0x6f>
		//addr = page2kva(page_free_list);
		//int *iq,*ip;
		//iq=ip;//将把ip中的值拷贝到iq中，这样，指针iq也将指向ip指向的对象
		struct PageInfo *Page;
		Page = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100f01:	8b 03                	mov    (%ebx),%eax
f0100f03:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
		//page_free_list->pp_link = NULL;
		Page->pp_link = NULL;
f0100f08:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		//Page->pp_ref = 1;
		Page->pp_ref = 0;
f0100f0e:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		//cprintf("page_alloc\r\n");
		if(alloc_flags & ALLOC_ZERO)
f0100f14:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100f18:	74 45                	je     f0100f5f <page_alloc+0x6f>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f1a:	89 d8                	mov    %ebx,%eax
f0100f1c:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100f22:	c1 f8 03             	sar    $0x3,%eax
f0100f25:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f28:	89 c2                	mov    %eax,%edx
f0100f2a:	c1 ea 0c             	shr    $0xc,%edx
f0100f2d:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100f33:	72 12                	jb     f0100f47 <page_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f35:	50                   	push   %eax
f0100f36:	68 a4 59 10 f0       	push   $0xf01059a4
f0100f3b:	6a 58                	push   $0x58
f0100f3d:	68 4d 68 10 f0       	push   $0xf010684d
f0100f42:	e8 f9 f0 ff ff       	call   f0100040 <_panic>
			memset(page2kva(Page),'\0',PGSIZE);
f0100f47:	83 ec 04             	sub    $0x4,%esp
f0100f4a:	68 00 10 00 00       	push   $0x1000
f0100f4f:	6a 00                	push   $0x0
f0100f51:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f56:	50                   	push   %eax
f0100f57:	e8 70 3d 00 00       	call   f0104ccc <memset>
f0100f5c:	83 c4 10             	add    $0x10,%esp
			// memset(page2kva(page_free_list),0,PGSIZE);
		return Page;
	}
}
f0100f5f:	89 d8                	mov    %ebx,%eax
f0100f61:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f64:	c9                   	leave  
f0100f65:	c3                   	ret    

f0100f66 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100f66:	55                   	push   %ebp
f0100f67:	89 e5                	mov    %esp,%ebp
f0100f69:	8b 45 08             	mov    0x8(%ebp),%eax
	//  	panic("can't free the page");
	//  	return;
	// }
	//	cprinf("can't free the page");
	//pp->pp_link = page_free_list->pp_link;	
	pp->pp_link = page_free_list;
f0100f6c:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100f72:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f74:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
	//pp->pp_ref = 0;
	//cprintf("page_free\r\n");
}
f0100f79:	5d                   	pop    %ebp
f0100f7a:	c3                   	ret    

f0100f7b <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100f7b:	55                   	push   %ebp
f0100f7c:	89 e5                	mov    %esp,%ebp
f0100f7e:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100f81:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100f85:	83 e8 01             	sub    $0x1,%eax
f0100f88:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100f8c:	66 85 c0             	test   %ax,%ax
f0100f8f:	75 09                	jne    f0100f9a <page_decref+0x1f>
		page_free(pp);
f0100f91:	52                   	push   %edx
f0100f92:	e8 cf ff ff ff       	call   f0100f66 <page_free>
f0100f97:	83 c4 04             	add    $0x4,%esp
}
f0100f9a:	c9                   	leave  
f0100f9b:	c3                   	ret    

f0100f9c <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f9c:	55                   	push   %ebp
f0100f9d:	89 e5                	mov    %esp,%ebp
f0100f9f:	56                   	push   %esi
f0100fa0:	53                   	push   %ebx
f0100fa1:	8b 45 0c             	mov    0xc(%ebp),%eax
	// Fill this function in
	uint32_t pd_number,pt_number,pt_addr;//,page_number,page_addr;
	pte_t *pte = NULL;
	struct PageInfo *Page;
	pd_number = PDX(va);
	pt_number = PTX(va);
f0100fa4:	89 c6                	mov    %eax,%esi
f0100fa6:	c1 ee 0c             	shr    $0xc,%esi
f0100fa9:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	if(pgdir[pd_number] & PTE_P)
f0100faf:	c1 e8 16             	shr    $0x16,%eax
f0100fb2:	8d 1c 85 00 00 00 00 	lea    0x0(,%eax,4),%ebx
f0100fb9:	03 5d 08             	add    0x8(%ebp),%ebx
f0100fbc:	8b 03                	mov    (%ebx),%eax
f0100fbe:	a8 01                	test   $0x1,%al
f0100fc0:	74 2e                	je     f0100ff0 <pgdir_walk+0x54>
		pte = KADDR(PTE_ADDR(pgdir[pd_number]));
f0100fc2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fc7:	89 c2                	mov    %eax,%edx
f0100fc9:	c1 ea 0c             	shr    $0xc,%edx
f0100fcc:	39 15 88 ae 22 f0    	cmp    %edx,0xf022ae88
f0100fd2:	77 15                	ja     f0100fe9 <pgdir_walk+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fd4:	50                   	push   %eax
f0100fd5:	68 a4 59 10 f0       	push   $0xf01059a4
f0100fda:	68 c7 01 00 00       	push   $0x1c7
f0100fdf:	68 41 68 10 f0       	push   $0xf0106841
f0100fe4:	e8 57 f0 ff ff       	call   f0100040 <_panic>
	if(!pte){
f0100fe9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fee:	75 58                	jne    f0101048 <pgdir_walk+0xac>
		if(!create)
f0100ff0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100ff4:	74 57                	je     f010104d <pgdir_walk+0xb1>
	 		return NULL;
	 	Page = page_alloc(create);
f0100ff6:	83 ec 0c             	sub    $0xc,%esp
f0100ff9:	ff 75 10             	pushl  0x10(%ebp)
f0100ffc:	e8 ef fe ff ff       	call   f0100ef0 <page_alloc>
		if(!Page)
f0101001:	83 c4 10             	add    $0x10,%esp
f0101004:	85 c0                	test   %eax,%eax
f0101006:	74 4c                	je     f0101054 <pgdir_walk+0xb8>
			return NULL;
		Page->pp_ref ++;
f0101008:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010100d:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0101013:	89 c2                	mov    %eax,%edx
f0101015:	c1 fa 03             	sar    $0x3,%edx
f0101018:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010101b:	89 d0                	mov    %edx,%eax
f010101d:	c1 e8 0c             	shr    $0xc,%eax
f0101020:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0101026:	72 15                	jb     f010103d <pgdir_walk+0xa1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101028:	52                   	push   %edx
f0101029:	68 a4 59 10 f0       	push   $0xf01059a4
f010102e:	68 cf 01 00 00       	push   $0x1cf
f0101033:	68 41 68 10 f0       	push   $0xf0106841
f0101038:	e8 03 f0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010103d:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	 	pte = KADDR(page2pa(Page));		
		// pgdir[pd_number] = page2pa(Page);
		pgdir[pd_number] = page2pa(Page) | PTE_P | PTE_W | PTE_U;
f0101043:	83 ca 07             	or     $0x7,%edx
f0101046:	89 13                	mov    %edx,(%ebx)
	}
	return &(pte[pt_number]);
f0101048:	8d 04 b0             	lea    (%eax,%esi,4),%eax
f010104b:	eb 0c                	jmp    f0101059 <pgdir_walk+0xbd>
	pt_number = PTX(va);
	if(pgdir[pd_number] & PTE_P)
		pte = KADDR(PTE_ADDR(pgdir[pd_number]));
	if(!pte){
		if(!create)
	 		return NULL;
f010104d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101052:	eb 05                	jmp    f0101059 <pgdir_walk+0xbd>
	 	Page = page_alloc(create);
		if(!Page)
			return NULL;
f0101054:	b8 00 00 00 00       	mov    $0x0,%eax
	// //不确定page_alloc函数里应该填入的参数,page_alloc(int alloc_flags)
	// 	Page = page_alloc(create);
	// 	page_addr = page2pa(Page);
	// }
	// return page_addr;
}
f0101059:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010105c:	5b                   	pop    %ebx
f010105d:	5e                   	pop    %esi
f010105e:	5d                   	pop    %ebp
f010105f:	c3                   	ret    

f0101060 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101060:	55                   	push   %ebp
f0101061:	89 e5                	mov    %esp,%ebp
f0101063:	57                   	push   %edi
f0101064:	56                   	push   %esi
f0101065:	53                   	push   %ebx
f0101066:	83 ec 1c             	sub    $0x1c,%esp
f0101069:	89 c7                	mov    %eax,%edi
f010106b:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010106e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	pte_t *pte = NULL;
	//cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for(int i = 0;i < size;i += PGSIZE){
f0101071:	bb 00 00 00 00       	mov    $0x0,%ebx
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
f0101076:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101079:	83 c8 01             	or     $0x1,%eax
f010107c:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte = NULL;
	//cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for(int i = 0;i < size;i += PGSIZE){
f010107f:	eb 1f                	jmp    f01010a0 <boot_map_region+0x40>
		pte = pgdir_walk(pgdir, (void *)va, 1);
f0101081:	83 ec 04             	sub    $0x4,%esp
f0101084:	6a 01                	push   $0x1
f0101086:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101089:	01 d8                	add    %ebx,%eax
f010108b:	50                   	push   %eax
f010108c:	57                   	push   %edi
f010108d:	e8 0a ff ff ff       	call   f0100f9c <pgdir_walk>
		*pte = (pa | perm | PTE_P);
f0101092:	0b 75 dc             	or     -0x24(%ebp),%esi
f0101095:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte = NULL;
	//cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for(int i = 0;i < size;i += PGSIZE){
f0101097:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010109d:	83 c4 10             	add    $0x10,%esp
f01010a0:	89 de                	mov    %ebx,%esi
f01010a2:	03 75 08             	add    0x8(%ebp),%esi
f01010a5:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f01010a8:	77 d7                	ja     f0101081 <boot_map_region+0x21>
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f01010aa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010ad:	5b                   	pop    %ebx
f01010ae:	5e                   	pop    %esi
f01010af:	5f                   	pop    %edi
f01010b0:	5d                   	pop    %ebp
f01010b1:	c3                   	ret    

f01010b2 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01010b2:	55                   	push   %ebp
f01010b3:	89 e5                	mov    %esp,%ebp
f01010b5:	53                   	push   %ebx
f01010b6:	83 ec 08             	sub    $0x8,%esp
f01010b9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
f01010bc:	6a 00                	push   $0x0
f01010be:	ff 75 0c             	pushl  0xc(%ebp)
f01010c1:	ff 75 08             	pushl  0x8(%ebp)
f01010c4:	e8 d3 fe ff ff       	call   f0100f9c <pgdir_walk>
	if(!pte)
f01010c9:	83 c4 10             	add    $0x10,%esp
f01010cc:	85 c0                	test   %eax,%eax
f01010ce:	74 32                	je     f0101102 <page_lookup+0x50>
		return NULL;
	if(pte_store)
f01010d0:	85 db                	test   %ebx,%ebx
f01010d2:	74 02                	je     f01010d6 <page_lookup+0x24>
		*pte_store = pte;
f01010d4:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010d6:	8b 00                	mov    (%eax),%eax
f01010d8:	c1 e8 0c             	shr    $0xc,%eax
f01010db:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01010e1:	72 14                	jb     f01010f7 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f01010e3:	83 ec 04             	sub    $0x4,%esp
f01010e6:	68 08 60 10 f0       	push   $0xf0106008
f01010eb:	6a 51                	push   $0x51
f01010ed:	68 4d 68 10 f0       	push   $0xf010684d
f01010f2:	e8 49 ef ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f01010f7:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f01010fd:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	return pa2page(PTE_ADDR(*pte));
f0101100:	eb 05                	jmp    f0101107 <page_lookup+0x55>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
	if(!pte)
		return NULL;
f0101102:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f0101107:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010110a:	c9                   	leave  
f010110b:	c3                   	ret    

f010110c <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010110c:	55                   	push   %ebp
f010110d:	89 e5                	mov    %esp,%ebp
f010110f:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f0101112:	e8 d7 41 00 00       	call   f01052ee <cpunum>
f0101117:	6b c0 74             	imul   $0x74,%eax,%eax
f010111a:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0101121:	74 16                	je     f0101139 <tlb_invalidate+0x2d>
f0101123:	e8 c6 41 00 00       	call   f01052ee <cpunum>
f0101128:	6b c0 74             	imul   $0x74,%eax,%eax
f010112b:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0101131:	8b 55 08             	mov    0x8(%ebp),%edx
f0101134:	39 50 60             	cmp    %edx,0x60(%eax)
f0101137:	75 06                	jne    f010113f <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101139:	8b 45 0c             	mov    0xc(%ebp),%eax
f010113c:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f010113f:	c9                   	leave  
f0101140:	c3                   	ret    

f0101141 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101141:	55                   	push   %ebp
f0101142:	89 e5                	mov    %esp,%ebp
f0101144:	57                   	push   %edi
f0101145:	56                   	push   %esi
f0101146:	53                   	push   %ebx
f0101147:	83 ec 20             	sub    $0x20,%esp
f010114a:	8b 75 08             	mov    0x8(%ebp),%esi
f010114d:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pte_t *pte;
	// pte_t *pte,**pte_store;
	// pte = pgdir_walk(pgdir, (void *)va, 0);
	// pte_store = &pte;
	struct PageInfo *Page;
	Page = page_lookup(pgdir, va, &pte);
f0101150:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101153:	50                   	push   %eax
f0101154:	57                   	push   %edi
f0101155:	56                   	push   %esi
f0101156:	e8 57 ff ff ff       	call   f01010b2 <page_lookup>
	// Page = page_lookup(pgdir, va, pte_store);
	if(Page){
f010115b:	83 c4 10             	add    $0x10,%esp
f010115e:	85 c0                	test   %eax,%eax
f0101160:	74 20                	je     f0101182 <page_remove+0x41>
f0101162:	89 c3                	mov    %eax,%ebx
		// Page->pp_ref --;
		tlb_invalidate(pgdir, va);
f0101164:	83 ec 08             	sub    $0x8,%esp
f0101167:	57                   	push   %edi
f0101168:	56                   	push   %esi
f0101169:	e8 9e ff ff ff       	call   f010110c <tlb_invalidate>
		page_decref(Page);
f010116e:	89 1c 24             	mov    %ebx,(%esp)
f0101171:	e8 05 fe ff ff       	call   f0100f7b <page_decref>
		*pte = 0;//将对应的页表项清空
f0101176:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101179:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f010117f:	83 c4 10             	add    $0x10,%esp
	}
}
f0101182:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101185:	5b                   	pop    %ebx
f0101186:	5e                   	pop    %esi
f0101187:	5f                   	pop    %edi
f0101188:	5d                   	pop    %ebp
f0101189:	c3                   	ret    

f010118a <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010118a:	55                   	push   %ebp
f010118b:	89 e5                	mov    %esp,%ebp
f010118d:	57                   	push   %edi
f010118e:	56                   	push   %esi
f010118f:	53                   	push   %ebx
f0101190:	83 ec 10             	sub    $0x10,%esp
f0101193:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101196:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
f0101199:	6a 01                	push   $0x1
f010119b:	57                   	push   %edi
f010119c:	ff 75 08             	pushl  0x8(%ebp)
f010119f:	e8 f8 fd ff ff       	call   f0100f9c <pgdir_walk>
	if(!pte)
f01011a4:	83 c4 10             	add    $0x10,%esp
f01011a7:	85 c0                	test   %eax,%eax
f01011a9:	74 38                	je     f01011e3 <page_insert+0x59>
f01011ab:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	pp->pp_ref++;
f01011ad:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	//删除旧映射关系 
    if((*pte) & PTE_P)
f01011b2:	f6 00 01             	testb  $0x1,(%eax)
f01011b5:	74 0f                	je     f01011c6 <page_insert+0x3c>
        page_remove(pgdir, va);
f01011b7:	83 ec 08             	sub    $0x8,%esp
f01011ba:	57                   	push   %edi
f01011bb:	ff 75 08             	pushl  0x8(%ebp)
f01011be:	e8 7e ff ff ff       	call   f0101141 <page_remove>
f01011c3:	83 c4 10             	add    $0x10,%esp
	//pp ->pp_ref++;
    *pte = page2pa(pp) | perm | PTE_P;
f01011c6:	2b 1d 90 ae 22 f0    	sub    0xf022ae90,%ebx
f01011cc:	c1 fb 03             	sar    $0x3,%ebx
f01011cf:	c1 e3 0c             	shl    $0xc,%ebx
f01011d2:	8b 45 14             	mov    0x14(%ebp),%eax
f01011d5:	83 c8 01             	or     $0x1,%eax
f01011d8:	09 c3                	or     %eax,%ebx
f01011da:	89 1e                	mov    %ebx,(%esi)
	return 0;
f01011dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01011e1:	eb 05                	jmp    f01011e8 <page_insert+0x5e>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
	if(!pte)
		return -E_NO_MEM;
f01011e3:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	// 		page_remove(pgdir, va); 
	// }
	// //pp->pp_ref++;
    // *pte = page2pa(pp) | perm | PTE_P;
	// return 0;
}
f01011e8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011eb:	5b                   	pop    %ebx
f01011ec:	5e                   	pop    %esi
f01011ed:	5f                   	pop    %edi
f01011ee:	5d                   	pop    %ebp
f01011ef:	c3                   	ret    

f01011f0 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01011f0:	55                   	push   %ebp
f01011f1:	89 e5                	mov    %esp,%ebp
f01011f3:	53                   	push   %ebx
f01011f4:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	size = ROUNDUP(size, PGSIZE);
f01011f7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011fa:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0101200:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	pa = ROUNDDOWN(pa, PGSIZE);
f0101206:	8b 45 08             	mov    0x8(%ebp),%eax
f0101209:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	
	if(base + size > MMIOLIM)
f010120e:	8b 15 00 f3 11 f0    	mov    0xf011f300,%edx
f0101214:	8d 0c 13             	lea    (%ebx,%edx,1),%ecx
f0101217:	81 f9 00 00 c0 ef    	cmp    $0xefc00000,%ecx
f010121d:	76 17                	jbe    f0101236 <mmio_map_region+0x46>
		panic("MMIOLIM is not enough");
f010121f:	83 ec 04             	sub    $0x4,%esp
f0101222:	68 14 69 10 f0       	push   $0xf0106914
f0101227:	68 b5 02 00 00       	push   $0x2b5
f010122c:	68 41 68 10 f0       	push   $0xf0106841
f0101231:	e8 0a ee ff ff       	call   f0100040 <_panic>

	boot_map_region(kern_pgdir, base, size, pa, PTE_PCD | PTE_PWT | PTE_W | PTE_P);
f0101236:	83 ec 08             	sub    $0x8,%esp
f0101239:	6a 1b                	push   $0x1b
f010123b:	50                   	push   %eax
f010123c:	89 d9                	mov    %ebx,%ecx
f010123e:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101243:	e8 18 fe ff ff       	call   f0101060 <boot_map_region>
	base += size;//每次映射到不同的页面
f0101248:	a1 00 f3 11 f0       	mov    0xf011f300,%eax
f010124d:	01 c3                	add    %eax,%ebx
f010124f:	89 1d 00 f3 11 f0    	mov    %ebx,0xf011f300
	return (void *)(base-size);
	//panic("mmio_map_region not implemented");
}
f0101255:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101258:	c9                   	leave  
f0101259:	c3                   	ret    

f010125a <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010125a:	55                   	push   %ebp
f010125b:	89 e5                	mov    %esp,%ebp
f010125d:	57                   	push   %edi
f010125e:	56                   	push   %esi
f010125f:	53                   	push   %ebx
f0101260:	83 ec 48             	sub    $0x48,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101263:	6a 15                	push   $0x15
f0101265:	e8 ac 22 00 00       	call   f0103516 <mc146818_read>
f010126a:	89 c3                	mov    %eax,%ebx
f010126c:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101273:	e8 9e 22 00 00       	call   f0103516 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101278:	c1 e0 08             	shl    $0x8,%eax
f010127b:	09 d8                	or     %ebx,%eax
f010127d:	c1 e0 0a             	shl    $0xa,%eax
f0101280:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101286:	85 c0                	test   %eax,%eax
f0101288:	0f 48 c2             	cmovs  %edx,%eax
f010128b:	c1 f8 0c             	sar    $0xc,%eax
f010128e:	a3 44 a2 22 f0       	mov    %eax,0xf022a244
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101293:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010129a:	e8 77 22 00 00       	call   f0103516 <mc146818_read>
f010129f:	89 c3                	mov    %eax,%ebx
f01012a1:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01012a8:	e8 69 22 00 00       	call   f0103516 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01012ad:	c1 e0 08             	shl    $0x8,%eax
f01012b0:	09 d8                	or     %ebx,%eax
f01012b2:	c1 e0 0a             	shl    $0xa,%eax
f01012b5:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01012bb:	83 c4 10             	add    $0x10,%esp
f01012be:	85 c0                	test   %eax,%eax
f01012c0:	0f 48 c2             	cmovs  %edx,%eax
f01012c3:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01012c6:	85 c0                	test   %eax,%eax
f01012c8:	74 0e                	je     f01012d8 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01012ca:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01012d0:	89 15 88 ae 22 f0    	mov    %edx,0xf022ae88
f01012d6:	eb 0c                	jmp    f01012e4 <mem_init+0x8a>
	else
		npages = npages_basemem;
f01012d8:	8b 15 44 a2 22 f0    	mov    0xf022a244,%edx
f01012de:	89 15 88 ae 22 f0    	mov    %edx,0xf022ae88

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012e4:	c1 e0 0c             	shl    $0xc,%eax
f01012e7:	c1 e8 0a             	shr    $0xa,%eax
f01012ea:	50                   	push   %eax
f01012eb:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
f01012f0:	c1 e0 0c             	shl    $0xc,%eax
f01012f3:	c1 e8 0a             	shr    $0xa,%eax
f01012f6:	50                   	push   %eax
f01012f7:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f01012fc:	c1 e0 0c             	shl    $0xc,%eax
f01012ff:	c1 e8 0a             	shr    $0xa,%eax
f0101302:	50                   	push   %eax
f0101303:	68 28 60 10 f0       	push   $0xf0106028
f0101308:	e8 88 23 00 00       	call   f0103695 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010130d:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101312:	e8 50 f7 ff ff       	call   f0100a67 <boot_alloc>
f0101317:	a3 8c ae 22 f0       	mov    %eax,0xf022ae8c
	memset(kern_pgdir, 0, PGSIZE);
f010131c:	83 c4 0c             	add    $0xc,%esp
f010131f:	68 00 10 00 00       	push   $0x1000
f0101324:	6a 00                	push   $0x0
f0101326:	50                   	push   %eax
f0101327:	e8 a0 39 00 00       	call   f0104ccc <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010132c:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101331:	83 c4 10             	add    $0x10,%esp
f0101334:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101339:	77 15                	ja     f0101350 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010133b:	50                   	push   %eax
f010133c:	68 c8 59 10 f0       	push   $0xf01059c8
f0101341:	68 90 00 00 00       	push   $0x90
f0101346:	68 41 68 10 f0       	push   $0xf0106841
f010134b:	e8 f0 ec ff ff       	call   f0100040 <_panic>
f0101350:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101356:	83 ca 05             	or     $0x5,%edx
f0101359:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f010135f:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0101364:	c1 e0 03             	shl    $0x3,%eax
f0101367:	e8 fb f6 ff ff       	call   f0100a67 <boot_alloc>
f010136c:	a3 90 ae 22 f0       	mov    %eax,0xf022ae90
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101371:	83 ec 04             	sub    $0x4,%esp
f0101374:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f010137a:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101381:	52                   	push   %edx
f0101382:	6a 00                	push   $0x0
f0101384:	50                   	push   %eax
f0101385:	e8 42 39 00 00       	call   f0104ccc <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*)boot_alloc(NENV * sizeof(struct Env));
f010138a:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f010138f:	e8 d3 f6 ff ff       	call   f0100a67 <boot_alloc>
f0101394:	a3 48 a2 22 f0       	mov    %eax,0xf022a248
	memset(envs, 0, NENV * sizeof(struct Env));
f0101399:	83 c4 0c             	add    $0xc,%esp
f010139c:	68 00 f0 01 00       	push   $0x1f000
f01013a1:	6a 00                	push   $0x0
f01013a3:	50                   	push   %eax
f01013a4:	e8 23 39 00 00       	call   f0104ccc <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01013a9:	e8 46 fa ff ff       	call   f0100df4 <page_init>

	check_page_free_list(1);
f01013ae:	b8 01 00 00 00       	mov    $0x1,%eax
f01013b3:	e8 4d f7 ff ff       	call   f0100b05 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01013b8:	83 c4 10             	add    $0x10,%esp
f01013bb:	83 3d 90 ae 22 f0 00 	cmpl   $0x0,0xf022ae90
f01013c2:	75 17                	jne    f01013db <mem_init+0x181>
		panic("'pages' is a null pointer!");
f01013c4:	83 ec 04             	sub    $0x4,%esp
f01013c7:	68 2a 69 10 f0       	push   $0xf010692a
f01013cc:	68 4e 03 00 00       	push   $0x34e
f01013d1:	68 41 68 10 f0       	push   $0xf0106841
f01013d6:	e8 65 ec ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013db:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f01013e0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01013e5:	eb 05                	jmp    f01013ec <mem_init+0x192>
		++nfree;
f01013e7:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013ea:	8b 00                	mov    (%eax),%eax
f01013ec:	85 c0                	test   %eax,%eax
f01013ee:	75 f7                	jne    f01013e7 <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013f0:	83 ec 0c             	sub    $0xc,%esp
f01013f3:	6a 00                	push   $0x0
f01013f5:	e8 f6 fa ff ff       	call   f0100ef0 <page_alloc>
f01013fa:	89 c7                	mov    %eax,%edi
f01013fc:	83 c4 10             	add    $0x10,%esp
f01013ff:	85 c0                	test   %eax,%eax
f0101401:	75 19                	jne    f010141c <mem_init+0x1c2>
f0101403:	68 45 69 10 f0       	push   $0xf0106945
f0101408:	68 67 68 10 f0       	push   $0xf0106867
f010140d:	68 56 03 00 00       	push   $0x356
f0101412:	68 41 68 10 f0       	push   $0xf0106841
f0101417:	e8 24 ec ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010141c:	83 ec 0c             	sub    $0xc,%esp
f010141f:	6a 00                	push   $0x0
f0101421:	e8 ca fa ff ff       	call   f0100ef0 <page_alloc>
f0101426:	89 c6                	mov    %eax,%esi
f0101428:	83 c4 10             	add    $0x10,%esp
f010142b:	85 c0                	test   %eax,%eax
f010142d:	75 19                	jne    f0101448 <mem_init+0x1ee>
f010142f:	68 5b 69 10 f0       	push   $0xf010695b
f0101434:	68 67 68 10 f0       	push   $0xf0106867
f0101439:	68 57 03 00 00       	push   $0x357
f010143e:	68 41 68 10 f0       	push   $0xf0106841
f0101443:	e8 f8 eb ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101448:	83 ec 0c             	sub    $0xc,%esp
f010144b:	6a 00                	push   $0x0
f010144d:	e8 9e fa ff ff       	call   f0100ef0 <page_alloc>
f0101452:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101455:	83 c4 10             	add    $0x10,%esp
f0101458:	85 c0                	test   %eax,%eax
f010145a:	75 19                	jne    f0101475 <mem_init+0x21b>
f010145c:	68 71 69 10 f0       	push   $0xf0106971
f0101461:	68 67 68 10 f0       	push   $0xf0106867
f0101466:	68 58 03 00 00       	push   $0x358
f010146b:	68 41 68 10 f0       	push   $0xf0106841
f0101470:	e8 cb eb ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101475:	39 f7                	cmp    %esi,%edi
f0101477:	75 19                	jne    f0101492 <mem_init+0x238>
f0101479:	68 87 69 10 f0       	push   $0xf0106987
f010147e:	68 67 68 10 f0       	push   $0xf0106867
f0101483:	68 5b 03 00 00       	push   $0x35b
f0101488:	68 41 68 10 f0       	push   $0xf0106841
f010148d:	e8 ae eb ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101492:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101495:	39 c6                	cmp    %eax,%esi
f0101497:	74 04                	je     f010149d <mem_init+0x243>
f0101499:	39 c7                	cmp    %eax,%edi
f010149b:	75 19                	jne    f01014b6 <mem_init+0x25c>
f010149d:	68 64 60 10 f0       	push   $0xf0106064
f01014a2:	68 67 68 10 f0       	push   $0xf0106867
f01014a7:	68 5c 03 00 00       	push   $0x35c
f01014ac:	68 41 68 10 f0       	push   $0xf0106841
f01014b1:	e8 8a eb ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014b6:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014bc:	8b 15 88 ae 22 f0    	mov    0xf022ae88,%edx
f01014c2:	c1 e2 0c             	shl    $0xc,%edx
f01014c5:	89 f8                	mov    %edi,%eax
f01014c7:	29 c8                	sub    %ecx,%eax
f01014c9:	c1 f8 03             	sar    $0x3,%eax
f01014cc:	c1 e0 0c             	shl    $0xc,%eax
f01014cf:	39 d0                	cmp    %edx,%eax
f01014d1:	72 19                	jb     f01014ec <mem_init+0x292>
f01014d3:	68 99 69 10 f0       	push   $0xf0106999
f01014d8:	68 67 68 10 f0       	push   $0xf0106867
f01014dd:	68 5d 03 00 00       	push   $0x35d
f01014e2:	68 41 68 10 f0       	push   $0xf0106841
f01014e7:	e8 54 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01014ec:	89 f0                	mov    %esi,%eax
f01014ee:	29 c8                	sub    %ecx,%eax
f01014f0:	c1 f8 03             	sar    $0x3,%eax
f01014f3:	c1 e0 0c             	shl    $0xc,%eax
f01014f6:	39 c2                	cmp    %eax,%edx
f01014f8:	77 19                	ja     f0101513 <mem_init+0x2b9>
f01014fa:	68 b6 69 10 f0       	push   $0xf01069b6
f01014ff:	68 67 68 10 f0       	push   $0xf0106867
f0101504:	68 5e 03 00 00       	push   $0x35e
f0101509:	68 41 68 10 f0       	push   $0xf0106841
f010150e:	e8 2d eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101513:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101516:	29 c8                	sub    %ecx,%eax
f0101518:	c1 f8 03             	sar    $0x3,%eax
f010151b:	c1 e0 0c             	shl    $0xc,%eax
f010151e:	39 c2                	cmp    %eax,%edx
f0101520:	77 19                	ja     f010153b <mem_init+0x2e1>
f0101522:	68 d3 69 10 f0       	push   $0xf01069d3
f0101527:	68 67 68 10 f0       	push   $0xf0106867
f010152c:	68 5f 03 00 00       	push   $0x35f
f0101531:	68 41 68 10 f0       	push   $0xf0106841
f0101536:	e8 05 eb ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010153b:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0101540:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101543:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f010154a:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010154d:	83 ec 0c             	sub    $0xc,%esp
f0101550:	6a 00                	push   $0x0
f0101552:	e8 99 f9 ff ff       	call   f0100ef0 <page_alloc>
f0101557:	83 c4 10             	add    $0x10,%esp
f010155a:	85 c0                	test   %eax,%eax
f010155c:	74 19                	je     f0101577 <mem_init+0x31d>
f010155e:	68 f0 69 10 f0       	push   $0xf01069f0
f0101563:	68 67 68 10 f0       	push   $0xf0106867
f0101568:	68 66 03 00 00       	push   $0x366
f010156d:	68 41 68 10 f0       	push   $0xf0106841
f0101572:	e8 c9 ea ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101577:	83 ec 0c             	sub    $0xc,%esp
f010157a:	57                   	push   %edi
f010157b:	e8 e6 f9 ff ff       	call   f0100f66 <page_free>
	page_free(pp1);
f0101580:	89 34 24             	mov    %esi,(%esp)
f0101583:	e8 de f9 ff ff       	call   f0100f66 <page_free>
	page_free(pp2);
f0101588:	83 c4 04             	add    $0x4,%esp
f010158b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010158e:	e8 d3 f9 ff ff       	call   f0100f66 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101593:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010159a:	e8 51 f9 ff ff       	call   f0100ef0 <page_alloc>
f010159f:	89 c6                	mov    %eax,%esi
f01015a1:	83 c4 10             	add    $0x10,%esp
f01015a4:	85 c0                	test   %eax,%eax
f01015a6:	75 19                	jne    f01015c1 <mem_init+0x367>
f01015a8:	68 45 69 10 f0       	push   $0xf0106945
f01015ad:	68 67 68 10 f0       	push   $0xf0106867
f01015b2:	68 6d 03 00 00       	push   $0x36d
f01015b7:	68 41 68 10 f0       	push   $0xf0106841
f01015bc:	e8 7f ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01015c1:	83 ec 0c             	sub    $0xc,%esp
f01015c4:	6a 00                	push   $0x0
f01015c6:	e8 25 f9 ff ff       	call   f0100ef0 <page_alloc>
f01015cb:	89 c7                	mov    %eax,%edi
f01015cd:	83 c4 10             	add    $0x10,%esp
f01015d0:	85 c0                	test   %eax,%eax
f01015d2:	75 19                	jne    f01015ed <mem_init+0x393>
f01015d4:	68 5b 69 10 f0       	push   $0xf010695b
f01015d9:	68 67 68 10 f0       	push   $0xf0106867
f01015de:	68 6e 03 00 00       	push   $0x36e
f01015e3:	68 41 68 10 f0       	push   $0xf0106841
f01015e8:	e8 53 ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01015ed:	83 ec 0c             	sub    $0xc,%esp
f01015f0:	6a 00                	push   $0x0
f01015f2:	e8 f9 f8 ff ff       	call   f0100ef0 <page_alloc>
f01015f7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015fa:	83 c4 10             	add    $0x10,%esp
f01015fd:	85 c0                	test   %eax,%eax
f01015ff:	75 19                	jne    f010161a <mem_init+0x3c0>
f0101601:	68 71 69 10 f0       	push   $0xf0106971
f0101606:	68 67 68 10 f0       	push   $0xf0106867
f010160b:	68 6f 03 00 00       	push   $0x36f
f0101610:	68 41 68 10 f0       	push   $0xf0106841
f0101615:	e8 26 ea ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010161a:	39 fe                	cmp    %edi,%esi
f010161c:	75 19                	jne    f0101637 <mem_init+0x3dd>
f010161e:	68 87 69 10 f0       	push   $0xf0106987
f0101623:	68 67 68 10 f0       	push   $0xf0106867
f0101628:	68 71 03 00 00       	push   $0x371
f010162d:	68 41 68 10 f0       	push   $0xf0106841
f0101632:	e8 09 ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101637:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010163a:	39 c7                	cmp    %eax,%edi
f010163c:	74 04                	je     f0101642 <mem_init+0x3e8>
f010163e:	39 c6                	cmp    %eax,%esi
f0101640:	75 19                	jne    f010165b <mem_init+0x401>
f0101642:	68 64 60 10 f0       	push   $0xf0106064
f0101647:	68 67 68 10 f0       	push   $0xf0106867
f010164c:	68 72 03 00 00       	push   $0x372
f0101651:	68 41 68 10 f0       	push   $0xf0106841
f0101656:	e8 e5 e9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010165b:	83 ec 0c             	sub    $0xc,%esp
f010165e:	6a 00                	push   $0x0
f0101660:	e8 8b f8 ff ff       	call   f0100ef0 <page_alloc>
f0101665:	83 c4 10             	add    $0x10,%esp
f0101668:	85 c0                	test   %eax,%eax
f010166a:	74 19                	je     f0101685 <mem_init+0x42b>
f010166c:	68 f0 69 10 f0       	push   $0xf01069f0
f0101671:	68 67 68 10 f0       	push   $0xf0106867
f0101676:	68 73 03 00 00       	push   $0x373
f010167b:	68 41 68 10 f0       	push   $0xf0106841
f0101680:	e8 bb e9 ff ff       	call   f0100040 <_panic>
f0101685:	89 f0                	mov    %esi,%eax
f0101687:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f010168d:	c1 f8 03             	sar    $0x3,%eax
f0101690:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101693:	89 c2                	mov    %eax,%edx
f0101695:	c1 ea 0c             	shr    $0xc,%edx
f0101698:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f010169e:	72 12                	jb     f01016b2 <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016a0:	50                   	push   %eax
f01016a1:	68 a4 59 10 f0       	push   $0xf01059a4
f01016a6:	6a 58                	push   $0x58
f01016a8:	68 4d 68 10 f0       	push   $0xf010684d
f01016ad:	e8 8e e9 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01016b2:	83 ec 04             	sub    $0x4,%esp
f01016b5:	68 00 10 00 00       	push   $0x1000
f01016ba:	6a 01                	push   $0x1
f01016bc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016c1:	50                   	push   %eax
f01016c2:	e8 05 36 00 00       	call   f0104ccc <memset>
	page_free(pp0);
f01016c7:	89 34 24             	mov    %esi,(%esp)
f01016ca:	e8 97 f8 ff ff       	call   f0100f66 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016cf:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016d6:	e8 15 f8 ff ff       	call   f0100ef0 <page_alloc>
f01016db:	83 c4 10             	add    $0x10,%esp
f01016de:	85 c0                	test   %eax,%eax
f01016e0:	75 19                	jne    f01016fb <mem_init+0x4a1>
f01016e2:	68 ff 69 10 f0       	push   $0xf01069ff
f01016e7:	68 67 68 10 f0       	push   $0xf0106867
f01016ec:	68 78 03 00 00       	push   $0x378
f01016f1:	68 41 68 10 f0       	push   $0xf0106841
f01016f6:	e8 45 e9 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01016fb:	39 c6                	cmp    %eax,%esi
f01016fd:	74 19                	je     f0101718 <mem_init+0x4be>
f01016ff:	68 1d 6a 10 f0       	push   $0xf0106a1d
f0101704:	68 67 68 10 f0       	push   $0xf0106867
f0101709:	68 79 03 00 00       	push   $0x379
f010170e:	68 41 68 10 f0       	push   $0xf0106841
f0101713:	e8 28 e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101718:	89 f0                	mov    %esi,%eax
f010171a:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0101720:	c1 f8 03             	sar    $0x3,%eax
f0101723:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101726:	89 c2                	mov    %eax,%edx
f0101728:	c1 ea 0c             	shr    $0xc,%edx
f010172b:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0101731:	72 12                	jb     f0101745 <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101733:	50                   	push   %eax
f0101734:	68 a4 59 10 f0       	push   $0xf01059a4
f0101739:	6a 58                	push   $0x58
f010173b:	68 4d 68 10 f0       	push   $0xf010684d
f0101740:	e8 fb e8 ff ff       	call   f0100040 <_panic>
f0101745:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010174b:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101751:	80 38 00             	cmpb   $0x0,(%eax)
f0101754:	74 19                	je     f010176f <mem_init+0x515>
f0101756:	68 2d 6a 10 f0       	push   $0xf0106a2d
f010175b:	68 67 68 10 f0       	push   $0xf0106867
f0101760:	68 7c 03 00 00       	push   $0x37c
f0101765:	68 41 68 10 f0       	push   $0xf0106841
f010176a:	e8 d1 e8 ff ff       	call   f0100040 <_panic>
f010176f:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101772:	39 d0                	cmp    %edx,%eax
f0101774:	75 db                	jne    f0101751 <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101776:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101779:	a3 40 a2 22 f0       	mov    %eax,0xf022a240

	// free the pages we took
	page_free(pp0);
f010177e:	83 ec 0c             	sub    $0xc,%esp
f0101781:	56                   	push   %esi
f0101782:	e8 df f7 ff ff       	call   f0100f66 <page_free>
	page_free(pp1);
f0101787:	89 3c 24             	mov    %edi,(%esp)
f010178a:	e8 d7 f7 ff ff       	call   f0100f66 <page_free>
	page_free(pp2);
f010178f:	83 c4 04             	add    $0x4,%esp
f0101792:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101795:	e8 cc f7 ff ff       	call   f0100f66 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010179a:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f010179f:	83 c4 10             	add    $0x10,%esp
f01017a2:	eb 05                	jmp    f01017a9 <mem_init+0x54f>
		--nfree;
f01017a4:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017a7:	8b 00                	mov    (%eax),%eax
f01017a9:	85 c0                	test   %eax,%eax
f01017ab:	75 f7                	jne    f01017a4 <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f01017ad:	85 db                	test   %ebx,%ebx
f01017af:	74 19                	je     f01017ca <mem_init+0x570>
f01017b1:	68 37 6a 10 f0       	push   $0xf0106a37
f01017b6:	68 67 68 10 f0       	push   $0xf0106867
f01017bb:	68 89 03 00 00       	push   $0x389
f01017c0:	68 41 68 10 f0       	push   $0xf0106841
f01017c5:	e8 76 e8 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017ca:	83 ec 0c             	sub    $0xc,%esp
f01017cd:	68 84 60 10 f0       	push   $0xf0106084
f01017d2:	e8 be 1e 00 00       	call   f0103695 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017d7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017de:	e8 0d f7 ff ff       	call   f0100ef0 <page_alloc>
f01017e3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017e6:	83 c4 10             	add    $0x10,%esp
f01017e9:	85 c0                	test   %eax,%eax
f01017eb:	75 19                	jne    f0101806 <mem_init+0x5ac>
f01017ed:	68 45 69 10 f0       	push   $0xf0106945
f01017f2:	68 67 68 10 f0       	push   $0xf0106867
f01017f7:	68 ef 03 00 00       	push   $0x3ef
f01017fc:	68 41 68 10 f0       	push   $0xf0106841
f0101801:	e8 3a e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101806:	83 ec 0c             	sub    $0xc,%esp
f0101809:	6a 00                	push   $0x0
f010180b:	e8 e0 f6 ff ff       	call   f0100ef0 <page_alloc>
f0101810:	89 c3                	mov    %eax,%ebx
f0101812:	83 c4 10             	add    $0x10,%esp
f0101815:	85 c0                	test   %eax,%eax
f0101817:	75 19                	jne    f0101832 <mem_init+0x5d8>
f0101819:	68 5b 69 10 f0       	push   $0xf010695b
f010181e:	68 67 68 10 f0       	push   $0xf0106867
f0101823:	68 f0 03 00 00       	push   $0x3f0
f0101828:	68 41 68 10 f0       	push   $0xf0106841
f010182d:	e8 0e e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101832:	83 ec 0c             	sub    $0xc,%esp
f0101835:	6a 00                	push   $0x0
f0101837:	e8 b4 f6 ff ff       	call   f0100ef0 <page_alloc>
f010183c:	89 c6                	mov    %eax,%esi
f010183e:	83 c4 10             	add    $0x10,%esp
f0101841:	85 c0                	test   %eax,%eax
f0101843:	75 19                	jne    f010185e <mem_init+0x604>
f0101845:	68 71 69 10 f0       	push   $0xf0106971
f010184a:	68 67 68 10 f0       	push   $0xf0106867
f010184f:	68 f1 03 00 00       	push   $0x3f1
f0101854:	68 41 68 10 f0       	push   $0xf0106841
f0101859:	e8 e2 e7 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010185e:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101861:	75 19                	jne    f010187c <mem_init+0x622>
f0101863:	68 87 69 10 f0       	push   $0xf0106987
f0101868:	68 67 68 10 f0       	push   $0xf0106867
f010186d:	68 f4 03 00 00       	push   $0x3f4
f0101872:	68 41 68 10 f0       	push   $0xf0106841
f0101877:	e8 c4 e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010187c:	39 c3                	cmp    %eax,%ebx
f010187e:	74 05                	je     f0101885 <mem_init+0x62b>
f0101880:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101883:	75 19                	jne    f010189e <mem_init+0x644>
f0101885:	68 64 60 10 f0       	push   $0xf0106064
f010188a:	68 67 68 10 f0       	push   $0xf0106867
f010188f:	68 f5 03 00 00       	push   $0x3f5
f0101894:	68 41 68 10 f0       	push   $0xf0106841
f0101899:	e8 a2 e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010189e:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f01018a3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01018a6:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f01018ad:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01018b0:	83 ec 0c             	sub    $0xc,%esp
f01018b3:	6a 00                	push   $0x0
f01018b5:	e8 36 f6 ff ff       	call   f0100ef0 <page_alloc>
f01018ba:	83 c4 10             	add    $0x10,%esp
f01018bd:	85 c0                	test   %eax,%eax
f01018bf:	74 19                	je     f01018da <mem_init+0x680>
f01018c1:	68 f0 69 10 f0       	push   $0xf01069f0
f01018c6:	68 67 68 10 f0       	push   $0xf0106867
f01018cb:	68 fc 03 00 00       	push   $0x3fc
f01018d0:	68 41 68 10 f0       	push   $0xf0106841
f01018d5:	e8 66 e7 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01018da:	83 ec 04             	sub    $0x4,%esp
f01018dd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01018e0:	50                   	push   %eax
f01018e1:	6a 00                	push   $0x0
f01018e3:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01018e9:	e8 c4 f7 ff ff       	call   f01010b2 <page_lookup>
f01018ee:	83 c4 10             	add    $0x10,%esp
f01018f1:	85 c0                	test   %eax,%eax
f01018f3:	74 19                	je     f010190e <mem_init+0x6b4>
f01018f5:	68 a4 60 10 f0       	push   $0xf01060a4
f01018fa:	68 67 68 10 f0       	push   $0xf0106867
f01018ff:	68 ff 03 00 00       	push   $0x3ff
f0101904:	68 41 68 10 f0       	push   $0xf0106841
f0101909:	e8 32 e7 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010190e:	6a 02                	push   $0x2
f0101910:	6a 00                	push   $0x0
f0101912:	53                   	push   %ebx
f0101913:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101919:	e8 6c f8 ff ff       	call   f010118a <page_insert>
f010191e:	83 c4 10             	add    $0x10,%esp
f0101921:	85 c0                	test   %eax,%eax
f0101923:	78 19                	js     f010193e <mem_init+0x6e4>
f0101925:	68 dc 60 10 f0       	push   $0xf01060dc
f010192a:	68 67 68 10 f0       	push   $0xf0106867
f010192f:	68 02 04 00 00       	push   $0x402
f0101934:	68 41 68 10 f0       	push   $0xf0106841
f0101939:	e8 02 e7 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010193e:	83 ec 0c             	sub    $0xc,%esp
f0101941:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101944:	e8 1d f6 ff ff       	call   f0100f66 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101949:	6a 02                	push   $0x2
f010194b:	6a 00                	push   $0x0
f010194d:	53                   	push   %ebx
f010194e:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101954:	e8 31 f8 ff ff       	call   f010118a <page_insert>
f0101959:	83 c4 20             	add    $0x20,%esp
f010195c:	85 c0                	test   %eax,%eax
f010195e:	74 19                	je     f0101979 <mem_init+0x71f>
f0101960:	68 0c 61 10 f0       	push   $0xf010610c
f0101965:	68 67 68 10 f0       	push   $0xf0106867
f010196a:	68 06 04 00 00       	push   $0x406
f010196f:	68 41 68 10 f0       	push   $0xf0106841
f0101974:	e8 c7 e6 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101979:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010197f:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0101984:	89 c1                	mov    %eax,%ecx
f0101986:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101989:	8b 17                	mov    (%edi),%edx
f010198b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101991:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101994:	29 c8                	sub    %ecx,%eax
f0101996:	c1 f8 03             	sar    $0x3,%eax
f0101999:	c1 e0 0c             	shl    $0xc,%eax
f010199c:	39 c2                	cmp    %eax,%edx
f010199e:	74 19                	je     f01019b9 <mem_init+0x75f>
f01019a0:	68 3c 61 10 f0       	push   $0xf010613c
f01019a5:	68 67 68 10 f0       	push   $0xf0106867
f01019aa:	68 07 04 00 00       	push   $0x407
f01019af:	68 41 68 10 f0       	push   $0xf0106841
f01019b4:	e8 87 e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01019b9:	ba 00 00 00 00       	mov    $0x0,%edx
f01019be:	89 f8                	mov    %edi,%eax
f01019c0:	e8 dc f0 ff ff       	call   f0100aa1 <check_va2pa>
f01019c5:	89 da                	mov    %ebx,%edx
f01019c7:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01019ca:	c1 fa 03             	sar    $0x3,%edx
f01019cd:	c1 e2 0c             	shl    $0xc,%edx
f01019d0:	39 d0                	cmp    %edx,%eax
f01019d2:	74 19                	je     f01019ed <mem_init+0x793>
f01019d4:	68 64 61 10 f0       	push   $0xf0106164
f01019d9:	68 67 68 10 f0       	push   $0xf0106867
f01019de:	68 08 04 00 00       	push   $0x408
f01019e3:	68 41 68 10 f0       	push   $0xf0106841
f01019e8:	e8 53 e6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01019ed:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01019f2:	74 19                	je     f0101a0d <mem_init+0x7b3>
f01019f4:	68 42 6a 10 f0       	push   $0xf0106a42
f01019f9:	68 67 68 10 f0       	push   $0xf0106867
f01019fe:	68 09 04 00 00       	push   $0x409
f0101a03:	68 41 68 10 f0       	push   $0xf0106841
f0101a08:	e8 33 e6 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101a0d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a10:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a15:	74 19                	je     f0101a30 <mem_init+0x7d6>
f0101a17:	68 53 6a 10 f0       	push   $0xf0106a53
f0101a1c:	68 67 68 10 f0       	push   $0xf0106867
f0101a21:	68 0a 04 00 00       	push   $0x40a
f0101a26:	68 41 68 10 f0       	push   $0xf0106841
f0101a2b:	e8 10 e6 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a30:	6a 02                	push   $0x2
f0101a32:	68 00 10 00 00       	push   $0x1000
f0101a37:	56                   	push   %esi
f0101a38:	57                   	push   %edi
f0101a39:	e8 4c f7 ff ff       	call   f010118a <page_insert>
f0101a3e:	83 c4 10             	add    $0x10,%esp
f0101a41:	85 c0                	test   %eax,%eax
f0101a43:	74 19                	je     f0101a5e <mem_init+0x804>
f0101a45:	68 94 61 10 f0       	push   $0xf0106194
f0101a4a:	68 67 68 10 f0       	push   $0xf0106867
f0101a4f:	68 0d 04 00 00       	push   $0x40d
f0101a54:	68 41 68 10 f0       	push   $0xf0106841
f0101a59:	e8 e2 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a5e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a63:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101a68:	e8 34 f0 ff ff       	call   f0100aa1 <check_va2pa>
f0101a6d:	89 f2                	mov    %esi,%edx
f0101a6f:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101a75:	c1 fa 03             	sar    $0x3,%edx
f0101a78:	c1 e2 0c             	shl    $0xc,%edx
f0101a7b:	39 d0                	cmp    %edx,%eax
f0101a7d:	74 19                	je     f0101a98 <mem_init+0x83e>
f0101a7f:	68 d0 61 10 f0       	push   $0xf01061d0
f0101a84:	68 67 68 10 f0       	push   $0xf0106867
f0101a89:	68 0e 04 00 00       	push   $0x40e
f0101a8e:	68 41 68 10 f0       	push   $0xf0106841
f0101a93:	e8 a8 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101a98:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a9d:	74 19                	je     f0101ab8 <mem_init+0x85e>
f0101a9f:	68 64 6a 10 f0       	push   $0xf0106a64
f0101aa4:	68 67 68 10 f0       	push   $0xf0106867
f0101aa9:	68 0f 04 00 00       	push   $0x40f
f0101aae:	68 41 68 10 f0       	push   $0xf0106841
f0101ab3:	e8 88 e5 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ab8:	83 ec 0c             	sub    $0xc,%esp
f0101abb:	6a 00                	push   $0x0
f0101abd:	e8 2e f4 ff ff       	call   f0100ef0 <page_alloc>
f0101ac2:	83 c4 10             	add    $0x10,%esp
f0101ac5:	85 c0                	test   %eax,%eax
f0101ac7:	74 19                	je     f0101ae2 <mem_init+0x888>
f0101ac9:	68 f0 69 10 f0       	push   $0xf01069f0
f0101ace:	68 67 68 10 f0       	push   $0xf0106867
f0101ad3:	68 12 04 00 00       	push   $0x412
f0101ad8:	68 41 68 10 f0       	push   $0xf0106841
f0101add:	e8 5e e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ae2:	6a 02                	push   $0x2
f0101ae4:	68 00 10 00 00       	push   $0x1000
f0101ae9:	56                   	push   %esi
f0101aea:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101af0:	e8 95 f6 ff ff       	call   f010118a <page_insert>
f0101af5:	83 c4 10             	add    $0x10,%esp
f0101af8:	85 c0                	test   %eax,%eax
f0101afa:	74 19                	je     f0101b15 <mem_init+0x8bb>
f0101afc:	68 94 61 10 f0       	push   $0xf0106194
f0101b01:	68 67 68 10 f0       	push   $0xf0106867
f0101b06:	68 15 04 00 00       	push   $0x415
f0101b0b:	68 41 68 10 f0       	push   $0xf0106841
f0101b10:	e8 2b e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b15:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b1a:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101b1f:	e8 7d ef ff ff       	call   f0100aa1 <check_va2pa>
f0101b24:	89 f2                	mov    %esi,%edx
f0101b26:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101b2c:	c1 fa 03             	sar    $0x3,%edx
f0101b2f:	c1 e2 0c             	shl    $0xc,%edx
f0101b32:	39 d0                	cmp    %edx,%eax
f0101b34:	74 19                	je     f0101b4f <mem_init+0x8f5>
f0101b36:	68 d0 61 10 f0       	push   $0xf01061d0
f0101b3b:	68 67 68 10 f0       	push   $0xf0106867
f0101b40:	68 16 04 00 00       	push   $0x416
f0101b45:	68 41 68 10 f0       	push   $0xf0106841
f0101b4a:	e8 f1 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b4f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b54:	74 19                	je     f0101b6f <mem_init+0x915>
f0101b56:	68 64 6a 10 f0       	push   $0xf0106a64
f0101b5b:	68 67 68 10 f0       	push   $0xf0106867
f0101b60:	68 17 04 00 00       	push   $0x417
f0101b65:	68 41 68 10 f0       	push   $0xf0106841
f0101b6a:	e8 d1 e4 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b6f:	83 ec 0c             	sub    $0xc,%esp
f0101b72:	6a 00                	push   $0x0
f0101b74:	e8 77 f3 ff ff       	call   f0100ef0 <page_alloc>
f0101b79:	83 c4 10             	add    $0x10,%esp
f0101b7c:	85 c0                	test   %eax,%eax
f0101b7e:	74 19                	je     f0101b99 <mem_init+0x93f>
f0101b80:	68 f0 69 10 f0       	push   $0xf01069f0
f0101b85:	68 67 68 10 f0       	push   $0xf0106867
f0101b8a:	68 1b 04 00 00       	push   $0x41b
f0101b8f:	68 41 68 10 f0       	push   $0xf0106841
f0101b94:	e8 a7 e4 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b99:	8b 15 8c ae 22 f0    	mov    0xf022ae8c,%edx
f0101b9f:	8b 02                	mov    (%edx),%eax
f0101ba1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ba6:	89 c1                	mov    %eax,%ecx
f0101ba8:	c1 e9 0c             	shr    $0xc,%ecx
f0101bab:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0101bb1:	72 15                	jb     f0101bc8 <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101bb3:	50                   	push   %eax
f0101bb4:	68 a4 59 10 f0       	push   $0xf01059a4
f0101bb9:	68 1e 04 00 00       	push   $0x41e
f0101bbe:	68 41 68 10 f0       	push   $0xf0106841
f0101bc3:	e8 78 e4 ff ff       	call   f0100040 <_panic>
f0101bc8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101bcd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101bd0:	83 ec 04             	sub    $0x4,%esp
f0101bd3:	6a 00                	push   $0x0
f0101bd5:	68 00 10 00 00       	push   $0x1000
f0101bda:	52                   	push   %edx
f0101bdb:	e8 bc f3 ff ff       	call   f0100f9c <pgdir_walk>
f0101be0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101be3:	8d 51 04             	lea    0x4(%ecx),%edx
f0101be6:	83 c4 10             	add    $0x10,%esp
f0101be9:	39 d0                	cmp    %edx,%eax
f0101beb:	74 19                	je     f0101c06 <mem_init+0x9ac>
f0101bed:	68 00 62 10 f0       	push   $0xf0106200
f0101bf2:	68 67 68 10 f0       	push   $0xf0106867
f0101bf7:	68 1f 04 00 00       	push   $0x41f
f0101bfc:	68 41 68 10 f0       	push   $0xf0106841
f0101c01:	e8 3a e4 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c06:	6a 06                	push   $0x6
f0101c08:	68 00 10 00 00       	push   $0x1000
f0101c0d:	56                   	push   %esi
f0101c0e:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101c14:	e8 71 f5 ff ff       	call   f010118a <page_insert>
f0101c19:	83 c4 10             	add    $0x10,%esp
f0101c1c:	85 c0                	test   %eax,%eax
f0101c1e:	74 19                	je     f0101c39 <mem_init+0x9df>
f0101c20:	68 40 62 10 f0       	push   $0xf0106240
f0101c25:	68 67 68 10 f0       	push   $0xf0106867
f0101c2a:	68 22 04 00 00       	push   $0x422
f0101c2f:	68 41 68 10 f0       	push   $0xf0106841
f0101c34:	e8 07 e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c39:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101c3f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c44:	89 f8                	mov    %edi,%eax
f0101c46:	e8 56 ee ff ff       	call   f0100aa1 <check_va2pa>
f0101c4b:	89 f2                	mov    %esi,%edx
f0101c4d:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101c53:	c1 fa 03             	sar    $0x3,%edx
f0101c56:	c1 e2 0c             	shl    $0xc,%edx
f0101c59:	39 d0                	cmp    %edx,%eax
f0101c5b:	74 19                	je     f0101c76 <mem_init+0xa1c>
f0101c5d:	68 d0 61 10 f0       	push   $0xf01061d0
f0101c62:	68 67 68 10 f0       	push   $0xf0106867
f0101c67:	68 23 04 00 00       	push   $0x423
f0101c6c:	68 41 68 10 f0       	push   $0xf0106841
f0101c71:	e8 ca e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101c76:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c7b:	74 19                	je     f0101c96 <mem_init+0xa3c>
f0101c7d:	68 64 6a 10 f0       	push   $0xf0106a64
f0101c82:	68 67 68 10 f0       	push   $0xf0106867
f0101c87:	68 24 04 00 00       	push   $0x424
f0101c8c:	68 41 68 10 f0       	push   $0xf0106841
f0101c91:	e8 aa e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c96:	83 ec 04             	sub    $0x4,%esp
f0101c99:	6a 00                	push   $0x0
f0101c9b:	68 00 10 00 00       	push   $0x1000
f0101ca0:	57                   	push   %edi
f0101ca1:	e8 f6 f2 ff ff       	call   f0100f9c <pgdir_walk>
f0101ca6:	83 c4 10             	add    $0x10,%esp
f0101ca9:	f6 00 04             	testb  $0x4,(%eax)
f0101cac:	75 19                	jne    f0101cc7 <mem_init+0xa6d>
f0101cae:	68 80 62 10 f0       	push   $0xf0106280
f0101cb3:	68 67 68 10 f0       	push   $0xf0106867
f0101cb8:	68 25 04 00 00       	push   $0x425
f0101cbd:	68 41 68 10 f0       	push   $0xf0106841
f0101cc2:	e8 79 e3 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101cc7:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101ccc:	f6 00 04             	testb  $0x4,(%eax)
f0101ccf:	75 19                	jne    f0101cea <mem_init+0xa90>
f0101cd1:	68 75 6a 10 f0       	push   $0xf0106a75
f0101cd6:	68 67 68 10 f0       	push   $0xf0106867
f0101cdb:	68 26 04 00 00       	push   $0x426
f0101ce0:	68 41 68 10 f0       	push   $0xf0106841
f0101ce5:	e8 56 e3 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101cea:	6a 02                	push   $0x2
f0101cec:	68 00 10 00 00       	push   $0x1000
f0101cf1:	56                   	push   %esi
f0101cf2:	50                   	push   %eax
f0101cf3:	e8 92 f4 ff ff       	call   f010118a <page_insert>
f0101cf8:	83 c4 10             	add    $0x10,%esp
f0101cfb:	85 c0                	test   %eax,%eax
f0101cfd:	74 19                	je     f0101d18 <mem_init+0xabe>
f0101cff:	68 94 61 10 f0       	push   $0xf0106194
f0101d04:	68 67 68 10 f0       	push   $0xf0106867
f0101d09:	68 29 04 00 00       	push   $0x429
f0101d0e:	68 41 68 10 f0       	push   $0xf0106841
f0101d13:	e8 28 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d18:	83 ec 04             	sub    $0x4,%esp
f0101d1b:	6a 00                	push   $0x0
f0101d1d:	68 00 10 00 00       	push   $0x1000
f0101d22:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d28:	e8 6f f2 ff ff       	call   f0100f9c <pgdir_walk>
f0101d2d:	83 c4 10             	add    $0x10,%esp
f0101d30:	f6 00 02             	testb  $0x2,(%eax)
f0101d33:	75 19                	jne    f0101d4e <mem_init+0xaf4>
f0101d35:	68 b4 62 10 f0       	push   $0xf01062b4
f0101d3a:	68 67 68 10 f0       	push   $0xf0106867
f0101d3f:	68 2a 04 00 00       	push   $0x42a
f0101d44:	68 41 68 10 f0       	push   $0xf0106841
f0101d49:	e8 f2 e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d4e:	83 ec 04             	sub    $0x4,%esp
f0101d51:	6a 00                	push   $0x0
f0101d53:	68 00 10 00 00       	push   $0x1000
f0101d58:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d5e:	e8 39 f2 ff ff       	call   f0100f9c <pgdir_walk>
f0101d63:	83 c4 10             	add    $0x10,%esp
f0101d66:	f6 00 04             	testb  $0x4,(%eax)
f0101d69:	74 19                	je     f0101d84 <mem_init+0xb2a>
f0101d6b:	68 e8 62 10 f0       	push   $0xf01062e8
f0101d70:	68 67 68 10 f0       	push   $0xf0106867
f0101d75:	68 2b 04 00 00       	push   $0x42b
f0101d7a:	68 41 68 10 f0       	push   $0xf0106841
f0101d7f:	e8 bc e2 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d84:	6a 02                	push   $0x2
f0101d86:	68 00 00 40 00       	push   $0x400000
f0101d8b:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101d8e:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d94:	e8 f1 f3 ff ff       	call   f010118a <page_insert>
f0101d99:	83 c4 10             	add    $0x10,%esp
f0101d9c:	85 c0                	test   %eax,%eax
f0101d9e:	78 19                	js     f0101db9 <mem_init+0xb5f>
f0101da0:	68 20 63 10 f0       	push   $0xf0106320
f0101da5:	68 67 68 10 f0       	push   $0xf0106867
f0101daa:	68 2e 04 00 00       	push   $0x42e
f0101daf:	68 41 68 10 f0       	push   $0xf0106841
f0101db4:	e8 87 e2 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101db9:	6a 02                	push   $0x2
f0101dbb:	68 00 10 00 00       	push   $0x1000
f0101dc0:	53                   	push   %ebx
f0101dc1:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101dc7:	e8 be f3 ff ff       	call   f010118a <page_insert>
f0101dcc:	83 c4 10             	add    $0x10,%esp
f0101dcf:	85 c0                	test   %eax,%eax
f0101dd1:	74 19                	je     f0101dec <mem_init+0xb92>
f0101dd3:	68 58 63 10 f0       	push   $0xf0106358
f0101dd8:	68 67 68 10 f0       	push   $0xf0106867
f0101ddd:	68 31 04 00 00       	push   $0x431
f0101de2:	68 41 68 10 f0       	push   $0xf0106841
f0101de7:	e8 54 e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101dec:	83 ec 04             	sub    $0x4,%esp
f0101def:	6a 00                	push   $0x0
f0101df1:	68 00 10 00 00       	push   $0x1000
f0101df6:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101dfc:	e8 9b f1 ff ff       	call   f0100f9c <pgdir_walk>
f0101e01:	83 c4 10             	add    $0x10,%esp
f0101e04:	f6 00 04             	testb  $0x4,(%eax)
f0101e07:	74 19                	je     f0101e22 <mem_init+0xbc8>
f0101e09:	68 e8 62 10 f0       	push   $0xf01062e8
f0101e0e:	68 67 68 10 f0       	push   $0xf0106867
f0101e13:	68 32 04 00 00       	push   $0x432
f0101e18:	68 41 68 10 f0       	push   $0xf0106841
f0101e1d:	e8 1e e2 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e22:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101e28:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e2d:	89 f8                	mov    %edi,%eax
f0101e2f:	e8 6d ec ff ff       	call   f0100aa1 <check_va2pa>
f0101e34:	89 c1                	mov    %eax,%ecx
f0101e36:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e39:	89 d8                	mov    %ebx,%eax
f0101e3b:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0101e41:	c1 f8 03             	sar    $0x3,%eax
f0101e44:	c1 e0 0c             	shl    $0xc,%eax
f0101e47:	39 c1                	cmp    %eax,%ecx
f0101e49:	74 19                	je     f0101e64 <mem_init+0xc0a>
f0101e4b:	68 94 63 10 f0       	push   $0xf0106394
f0101e50:	68 67 68 10 f0       	push   $0xf0106867
f0101e55:	68 35 04 00 00       	push   $0x435
f0101e5a:	68 41 68 10 f0       	push   $0xf0106841
f0101e5f:	e8 dc e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e64:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e69:	89 f8                	mov    %edi,%eax
f0101e6b:	e8 31 ec ff ff       	call   f0100aa1 <check_va2pa>
f0101e70:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101e73:	74 19                	je     f0101e8e <mem_init+0xc34>
f0101e75:	68 c0 63 10 f0       	push   $0xf01063c0
f0101e7a:	68 67 68 10 f0       	push   $0xf0106867
f0101e7f:	68 36 04 00 00       	push   $0x436
f0101e84:	68 41 68 10 f0       	push   $0xf0106841
f0101e89:	e8 b2 e1 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e8e:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101e93:	74 19                	je     f0101eae <mem_init+0xc54>
f0101e95:	68 8b 6a 10 f0       	push   $0xf0106a8b
f0101e9a:	68 67 68 10 f0       	push   $0xf0106867
f0101e9f:	68 38 04 00 00       	push   $0x438
f0101ea4:	68 41 68 10 f0       	push   $0xf0106841
f0101ea9:	e8 92 e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101eae:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101eb3:	74 19                	je     f0101ece <mem_init+0xc74>
f0101eb5:	68 9c 6a 10 f0       	push   $0xf0106a9c
f0101eba:	68 67 68 10 f0       	push   $0xf0106867
f0101ebf:	68 39 04 00 00       	push   $0x439
f0101ec4:	68 41 68 10 f0       	push   $0xf0106841
f0101ec9:	e8 72 e1 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101ece:	83 ec 0c             	sub    $0xc,%esp
f0101ed1:	6a 00                	push   $0x0
f0101ed3:	e8 18 f0 ff ff       	call   f0100ef0 <page_alloc>
f0101ed8:	83 c4 10             	add    $0x10,%esp
f0101edb:	85 c0                	test   %eax,%eax
f0101edd:	74 04                	je     f0101ee3 <mem_init+0xc89>
f0101edf:	39 c6                	cmp    %eax,%esi
f0101ee1:	74 19                	je     f0101efc <mem_init+0xca2>
f0101ee3:	68 f0 63 10 f0       	push   $0xf01063f0
f0101ee8:	68 67 68 10 f0       	push   $0xf0106867
f0101eed:	68 3c 04 00 00       	push   $0x43c
f0101ef2:	68 41 68 10 f0       	push   $0xf0106841
f0101ef7:	e8 44 e1 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101efc:	83 ec 08             	sub    $0x8,%esp
f0101eff:	6a 00                	push   $0x0
f0101f01:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101f07:	e8 35 f2 ff ff       	call   f0101141 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f0c:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101f12:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f17:	89 f8                	mov    %edi,%eax
f0101f19:	e8 83 eb ff ff       	call   f0100aa1 <check_va2pa>
f0101f1e:	83 c4 10             	add    $0x10,%esp
f0101f21:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f24:	74 19                	je     f0101f3f <mem_init+0xce5>
f0101f26:	68 14 64 10 f0       	push   $0xf0106414
f0101f2b:	68 67 68 10 f0       	push   $0xf0106867
f0101f30:	68 40 04 00 00       	push   $0x440
f0101f35:	68 41 68 10 f0       	push   $0xf0106841
f0101f3a:	e8 01 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f3f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f44:	89 f8                	mov    %edi,%eax
f0101f46:	e8 56 eb ff ff       	call   f0100aa1 <check_va2pa>
f0101f4b:	89 da                	mov    %ebx,%edx
f0101f4d:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101f53:	c1 fa 03             	sar    $0x3,%edx
f0101f56:	c1 e2 0c             	shl    $0xc,%edx
f0101f59:	39 d0                	cmp    %edx,%eax
f0101f5b:	74 19                	je     f0101f76 <mem_init+0xd1c>
f0101f5d:	68 c0 63 10 f0       	push   $0xf01063c0
f0101f62:	68 67 68 10 f0       	push   $0xf0106867
f0101f67:	68 41 04 00 00       	push   $0x441
f0101f6c:	68 41 68 10 f0       	push   $0xf0106841
f0101f71:	e8 ca e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101f76:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101f7b:	74 19                	je     f0101f96 <mem_init+0xd3c>
f0101f7d:	68 42 6a 10 f0       	push   $0xf0106a42
f0101f82:	68 67 68 10 f0       	push   $0xf0106867
f0101f87:	68 42 04 00 00       	push   $0x442
f0101f8c:	68 41 68 10 f0       	push   $0xf0106841
f0101f91:	e8 aa e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101f96:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f9b:	74 19                	je     f0101fb6 <mem_init+0xd5c>
f0101f9d:	68 9c 6a 10 f0       	push   $0xf0106a9c
f0101fa2:	68 67 68 10 f0       	push   $0xf0106867
f0101fa7:	68 43 04 00 00       	push   $0x443
f0101fac:	68 41 68 10 f0       	push   $0xf0106841
f0101fb1:	e8 8a e0 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101fb6:	6a 00                	push   $0x0
f0101fb8:	68 00 10 00 00       	push   $0x1000
f0101fbd:	53                   	push   %ebx
f0101fbe:	57                   	push   %edi
f0101fbf:	e8 c6 f1 ff ff       	call   f010118a <page_insert>
f0101fc4:	83 c4 10             	add    $0x10,%esp
f0101fc7:	85 c0                	test   %eax,%eax
f0101fc9:	74 19                	je     f0101fe4 <mem_init+0xd8a>
f0101fcb:	68 38 64 10 f0       	push   $0xf0106438
f0101fd0:	68 67 68 10 f0       	push   $0xf0106867
f0101fd5:	68 46 04 00 00       	push   $0x446
f0101fda:	68 41 68 10 f0       	push   $0xf0106841
f0101fdf:	e8 5c e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0101fe4:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101fe9:	75 19                	jne    f0102004 <mem_init+0xdaa>
f0101feb:	68 ad 6a 10 f0       	push   $0xf0106aad
f0101ff0:	68 67 68 10 f0       	push   $0xf0106867
f0101ff5:	68 47 04 00 00       	push   $0x447
f0101ffa:	68 41 68 10 f0       	push   $0xf0106841
f0101fff:	e8 3c e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102004:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102007:	74 19                	je     f0102022 <mem_init+0xdc8>
f0102009:	68 b9 6a 10 f0       	push   $0xf0106ab9
f010200e:	68 67 68 10 f0       	push   $0xf0106867
f0102013:	68 48 04 00 00       	push   $0x448
f0102018:	68 41 68 10 f0       	push   $0xf0106841
f010201d:	e8 1e e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102022:	83 ec 08             	sub    $0x8,%esp
f0102025:	68 00 10 00 00       	push   $0x1000
f010202a:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102030:	e8 0c f1 ff ff       	call   f0101141 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102035:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f010203b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102040:	89 f8                	mov    %edi,%eax
f0102042:	e8 5a ea ff ff       	call   f0100aa1 <check_va2pa>
f0102047:	83 c4 10             	add    $0x10,%esp
f010204a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010204d:	74 19                	je     f0102068 <mem_init+0xe0e>
f010204f:	68 14 64 10 f0       	push   $0xf0106414
f0102054:	68 67 68 10 f0       	push   $0xf0106867
f0102059:	68 4c 04 00 00       	push   $0x44c
f010205e:	68 41 68 10 f0       	push   $0xf0106841
f0102063:	e8 d8 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102068:	ba 00 10 00 00       	mov    $0x1000,%edx
f010206d:	89 f8                	mov    %edi,%eax
f010206f:	e8 2d ea ff ff       	call   f0100aa1 <check_va2pa>
f0102074:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102077:	74 19                	je     f0102092 <mem_init+0xe38>
f0102079:	68 70 64 10 f0       	push   $0xf0106470
f010207e:	68 67 68 10 f0       	push   $0xf0106867
f0102083:	68 4d 04 00 00       	push   $0x44d
f0102088:	68 41 68 10 f0       	push   $0xf0106841
f010208d:	e8 ae df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102092:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102097:	74 19                	je     f01020b2 <mem_init+0xe58>
f0102099:	68 ce 6a 10 f0       	push   $0xf0106ace
f010209e:	68 67 68 10 f0       	push   $0xf0106867
f01020a3:	68 4e 04 00 00       	push   $0x44e
f01020a8:	68 41 68 10 f0       	push   $0xf0106841
f01020ad:	e8 8e df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01020b2:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020b7:	74 19                	je     f01020d2 <mem_init+0xe78>
f01020b9:	68 9c 6a 10 f0       	push   $0xf0106a9c
f01020be:	68 67 68 10 f0       	push   $0xf0106867
f01020c3:	68 4f 04 00 00       	push   $0x44f
f01020c8:	68 41 68 10 f0       	push   $0xf0106841
f01020cd:	e8 6e df ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01020d2:	83 ec 0c             	sub    $0xc,%esp
f01020d5:	6a 00                	push   $0x0
f01020d7:	e8 14 ee ff ff       	call   f0100ef0 <page_alloc>
f01020dc:	83 c4 10             	add    $0x10,%esp
f01020df:	39 c3                	cmp    %eax,%ebx
f01020e1:	75 04                	jne    f01020e7 <mem_init+0xe8d>
f01020e3:	85 c0                	test   %eax,%eax
f01020e5:	75 19                	jne    f0102100 <mem_init+0xea6>
f01020e7:	68 98 64 10 f0       	push   $0xf0106498
f01020ec:	68 67 68 10 f0       	push   $0xf0106867
f01020f1:	68 52 04 00 00       	push   $0x452
f01020f6:	68 41 68 10 f0       	push   $0xf0106841
f01020fb:	e8 40 df ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102100:	83 ec 0c             	sub    $0xc,%esp
f0102103:	6a 00                	push   $0x0
f0102105:	e8 e6 ed ff ff       	call   f0100ef0 <page_alloc>
f010210a:	83 c4 10             	add    $0x10,%esp
f010210d:	85 c0                	test   %eax,%eax
f010210f:	74 19                	je     f010212a <mem_init+0xed0>
f0102111:	68 f0 69 10 f0       	push   $0xf01069f0
f0102116:	68 67 68 10 f0       	push   $0xf0106867
f010211b:	68 55 04 00 00       	push   $0x455
f0102120:	68 41 68 10 f0       	push   $0xf0106841
f0102125:	e8 16 df ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010212a:	8b 0d 8c ae 22 f0    	mov    0xf022ae8c,%ecx
f0102130:	8b 11                	mov    (%ecx),%edx
f0102132:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102138:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010213b:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102141:	c1 f8 03             	sar    $0x3,%eax
f0102144:	c1 e0 0c             	shl    $0xc,%eax
f0102147:	39 c2                	cmp    %eax,%edx
f0102149:	74 19                	je     f0102164 <mem_init+0xf0a>
f010214b:	68 3c 61 10 f0       	push   $0xf010613c
f0102150:	68 67 68 10 f0       	push   $0xf0106867
f0102155:	68 58 04 00 00       	push   $0x458
f010215a:	68 41 68 10 f0       	push   $0xf0106841
f010215f:	e8 dc de ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102164:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010216a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010216d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102172:	74 19                	je     f010218d <mem_init+0xf33>
f0102174:	68 53 6a 10 f0       	push   $0xf0106a53
f0102179:	68 67 68 10 f0       	push   $0xf0106867
f010217e:	68 5a 04 00 00       	push   $0x45a
f0102183:	68 41 68 10 f0       	push   $0xf0106841
f0102188:	e8 b3 de ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f010218d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102190:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102196:	83 ec 0c             	sub    $0xc,%esp
f0102199:	50                   	push   %eax
f010219a:	e8 c7 ed ff ff       	call   f0100f66 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010219f:	83 c4 0c             	add    $0xc,%esp
f01021a2:	6a 01                	push   $0x1
f01021a4:	68 00 10 40 00       	push   $0x401000
f01021a9:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01021af:	e8 e8 ed ff ff       	call   f0100f9c <pgdir_walk>
f01021b4:	89 c7                	mov    %eax,%edi
f01021b6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01021b9:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01021be:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021c1:	8b 40 04             	mov    0x4(%eax),%eax
f01021c4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01021c9:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f01021cf:	89 c2                	mov    %eax,%edx
f01021d1:	c1 ea 0c             	shr    $0xc,%edx
f01021d4:	83 c4 10             	add    $0x10,%esp
f01021d7:	39 ca                	cmp    %ecx,%edx
f01021d9:	72 15                	jb     f01021f0 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021db:	50                   	push   %eax
f01021dc:	68 a4 59 10 f0       	push   $0xf01059a4
f01021e1:	68 61 04 00 00       	push   $0x461
f01021e6:	68 41 68 10 f0       	push   $0xf0106841
f01021eb:	e8 50 de ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01021f0:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f01021f5:	39 c7                	cmp    %eax,%edi
f01021f7:	74 19                	je     f0102212 <mem_init+0xfb8>
f01021f9:	68 df 6a 10 f0       	push   $0xf0106adf
f01021fe:	68 67 68 10 f0       	push   $0xf0106867
f0102203:	68 62 04 00 00       	push   $0x462
f0102208:	68 41 68 10 f0       	push   $0xf0106841
f010220d:	e8 2e de ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102212:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102215:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f010221c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010221f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102225:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f010222b:	c1 f8 03             	sar    $0x3,%eax
f010222e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102231:	89 c2                	mov    %eax,%edx
f0102233:	c1 ea 0c             	shr    $0xc,%edx
f0102236:	39 d1                	cmp    %edx,%ecx
f0102238:	77 12                	ja     f010224c <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010223a:	50                   	push   %eax
f010223b:	68 a4 59 10 f0       	push   $0xf01059a4
f0102240:	6a 58                	push   $0x58
f0102242:	68 4d 68 10 f0       	push   $0xf010684d
f0102247:	e8 f4 dd ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010224c:	83 ec 04             	sub    $0x4,%esp
f010224f:	68 00 10 00 00       	push   $0x1000
f0102254:	68 ff 00 00 00       	push   $0xff
f0102259:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010225e:	50                   	push   %eax
f010225f:	e8 68 2a 00 00       	call   f0104ccc <memset>
	page_free(pp0);
f0102264:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102267:	89 3c 24             	mov    %edi,(%esp)
f010226a:	e8 f7 ec ff ff       	call   f0100f66 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010226f:	83 c4 0c             	add    $0xc,%esp
f0102272:	6a 01                	push   $0x1
f0102274:	6a 00                	push   $0x0
f0102276:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f010227c:	e8 1b ed ff ff       	call   f0100f9c <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102281:	89 fa                	mov    %edi,%edx
f0102283:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0102289:	c1 fa 03             	sar    $0x3,%edx
f010228c:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010228f:	89 d0                	mov    %edx,%eax
f0102291:	c1 e8 0c             	shr    $0xc,%eax
f0102294:	83 c4 10             	add    $0x10,%esp
f0102297:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f010229d:	72 12                	jb     f01022b1 <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010229f:	52                   	push   %edx
f01022a0:	68 a4 59 10 f0       	push   $0xf01059a4
f01022a5:	6a 58                	push   $0x58
f01022a7:	68 4d 68 10 f0       	push   $0xf010684d
f01022ac:	e8 8f dd ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01022b1:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01022b7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01022ba:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01022c0:	f6 00 01             	testb  $0x1,(%eax)
f01022c3:	74 19                	je     f01022de <mem_init+0x1084>
f01022c5:	68 f7 6a 10 f0       	push   $0xf0106af7
f01022ca:	68 67 68 10 f0       	push   $0xf0106867
f01022cf:	68 6c 04 00 00       	push   $0x46c
f01022d4:	68 41 68 10 f0       	push   $0xf0106841
f01022d9:	e8 62 dd ff ff       	call   f0100040 <_panic>
f01022de:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01022e1:	39 d0                	cmp    %edx,%eax
f01022e3:	75 db                	jne    f01022c0 <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01022e5:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01022ea:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01022f0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022f3:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01022f9:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01022fc:	89 0d 40 a2 22 f0    	mov    %ecx,0xf022a240

	// free the pages we took
	page_free(pp0);
f0102302:	83 ec 0c             	sub    $0xc,%esp
f0102305:	50                   	push   %eax
f0102306:	e8 5b ec ff ff       	call   f0100f66 <page_free>
	page_free(pp1);
f010230b:	89 1c 24             	mov    %ebx,(%esp)
f010230e:	e8 53 ec ff ff       	call   f0100f66 <page_free>
	page_free(pp2);
f0102313:	89 34 24             	mov    %esi,(%esp)
f0102316:	e8 4b ec ff ff       	call   f0100f66 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f010231b:	83 c4 08             	add    $0x8,%esp
f010231e:	68 01 10 00 00       	push   $0x1001
f0102323:	6a 00                	push   $0x0
f0102325:	e8 c6 ee ff ff       	call   f01011f0 <mmio_map_region>
f010232a:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f010232c:	83 c4 08             	add    $0x8,%esp
f010232f:	68 00 10 00 00       	push   $0x1000
f0102334:	6a 00                	push   $0x0
f0102336:	e8 b5 ee ff ff       	call   f01011f0 <mmio_map_region>
f010233b:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f010233d:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f0102343:	83 c4 10             	add    $0x10,%esp
f0102346:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f010234c:	76 07                	jbe    f0102355 <mem_init+0x10fb>
f010234e:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102353:	76 19                	jbe    f010236e <mem_init+0x1114>
f0102355:	68 bc 64 10 f0       	push   $0xf01064bc
f010235a:	68 67 68 10 f0       	push   $0xf0106867
f010235f:	68 7c 04 00 00       	push   $0x47c
f0102364:	68 41 68 10 f0       	push   $0xf0106841
f0102369:	e8 d2 dc ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f010236e:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f0102374:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f010237a:	77 08                	ja     f0102384 <mem_init+0x112a>
f010237c:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102382:	77 19                	ja     f010239d <mem_init+0x1143>
f0102384:	68 e4 64 10 f0       	push   $0xf01064e4
f0102389:	68 67 68 10 f0       	push   $0xf0106867
f010238e:	68 7d 04 00 00       	push   $0x47d
f0102393:	68 41 68 10 f0       	push   $0xf0106841
f0102398:	e8 a3 dc ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f010239d:	89 da                	mov    %ebx,%edx
f010239f:	09 f2                	or     %esi,%edx
f01023a1:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f01023a7:	74 19                	je     f01023c2 <mem_init+0x1168>
f01023a9:	68 0c 65 10 f0       	push   $0xf010650c
f01023ae:	68 67 68 10 f0       	push   $0xf0106867
f01023b3:	68 7f 04 00 00       	push   $0x47f
f01023b8:	68 41 68 10 f0       	push   $0xf0106841
f01023bd:	e8 7e dc ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f01023c2:	39 c6                	cmp    %eax,%esi
f01023c4:	73 19                	jae    f01023df <mem_init+0x1185>
f01023c6:	68 0e 6b 10 f0       	push   $0xf0106b0e
f01023cb:	68 67 68 10 f0       	push   $0xf0106867
f01023d0:	68 81 04 00 00       	push   $0x481
f01023d5:	68 41 68 10 f0       	push   $0xf0106841
f01023da:	e8 61 dc ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f01023df:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f01023e5:	89 da                	mov    %ebx,%edx
f01023e7:	89 f8                	mov    %edi,%eax
f01023e9:	e8 b3 e6 ff ff       	call   f0100aa1 <check_va2pa>
f01023ee:	85 c0                	test   %eax,%eax
f01023f0:	74 19                	je     f010240b <mem_init+0x11b1>
f01023f2:	68 34 65 10 f0       	push   $0xf0106534
f01023f7:	68 67 68 10 f0       	push   $0xf0106867
f01023fc:	68 83 04 00 00       	push   $0x483
f0102401:	68 41 68 10 f0       	push   $0xf0106841
f0102406:	e8 35 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f010240b:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102411:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102414:	89 c2                	mov    %eax,%edx
f0102416:	89 f8                	mov    %edi,%eax
f0102418:	e8 84 e6 ff ff       	call   f0100aa1 <check_va2pa>
f010241d:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102422:	74 19                	je     f010243d <mem_init+0x11e3>
f0102424:	68 58 65 10 f0       	push   $0xf0106558
f0102429:	68 67 68 10 f0       	push   $0xf0106867
f010242e:	68 84 04 00 00       	push   $0x484
f0102433:	68 41 68 10 f0       	push   $0xf0106841
f0102438:	e8 03 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f010243d:	89 f2                	mov    %esi,%edx
f010243f:	89 f8                	mov    %edi,%eax
f0102441:	e8 5b e6 ff ff       	call   f0100aa1 <check_va2pa>
f0102446:	85 c0                	test   %eax,%eax
f0102448:	74 19                	je     f0102463 <mem_init+0x1209>
f010244a:	68 88 65 10 f0       	push   $0xf0106588
f010244f:	68 67 68 10 f0       	push   $0xf0106867
f0102454:	68 85 04 00 00       	push   $0x485
f0102459:	68 41 68 10 f0       	push   $0xf0106841
f010245e:	e8 dd db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102463:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102469:	89 f8                	mov    %edi,%eax
f010246b:	e8 31 e6 ff ff       	call   f0100aa1 <check_va2pa>
f0102470:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102473:	74 19                	je     f010248e <mem_init+0x1234>
f0102475:	68 ac 65 10 f0       	push   $0xf01065ac
f010247a:	68 67 68 10 f0       	push   $0xf0106867
f010247f:	68 86 04 00 00       	push   $0x486
f0102484:	68 41 68 10 f0       	push   $0xf0106841
f0102489:	e8 b2 db ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f010248e:	83 ec 04             	sub    $0x4,%esp
f0102491:	6a 00                	push   $0x0
f0102493:	53                   	push   %ebx
f0102494:	57                   	push   %edi
f0102495:	e8 02 eb ff ff       	call   f0100f9c <pgdir_walk>
f010249a:	83 c4 10             	add    $0x10,%esp
f010249d:	f6 00 1a             	testb  $0x1a,(%eax)
f01024a0:	75 19                	jne    f01024bb <mem_init+0x1261>
f01024a2:	68 d8 65 10 f0       	push   $0xf01065d8
f01024a7:	68 67 68 10 f0       	push   $0xf0106867
f01024ac:	68 88 04 00 00       	push   $0x488
f01024b1:	68 41 68 10 f0       	push   $0xf0106841
f01024b6:	e8 85 db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f01024bb:	83 ec 04             	sub    $0x4,%esp
f01024be:	6a 00                	push   $0x0
f01024c0:	53                   	push   %ebx
f01024c1:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01024c7:	e8 d0 ea ff ff       	call   f0100f9c <pgdir_walk>
f01024cc:	8b 00                	mov    (%eax),%eax
f01024ce:	83 c4 10             	add    $0x10,%esp
f01024d1:	83 e0 04             	and    $0x4,%eax
f01024d4:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01024d7:	74 19                	je     f01024f2 <mem_init+0x1298>
f01024d9:	68 1c 66 10 f0       	push   $0xf010661c
f01024de:	68 67 68 10 f0       	push   $0xf0106867
f01024e3:	68 89 04 00 00       	push   $0x489
f01024e8:	68 41 68 10 f0       	push   $0xf0106841
f01024ed:	e8 4e db ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f01024f2:	83 ec 04             	sub    $0x4,%esp
f01024f5:	6a 00                	push   $0x0
f01024f7:	53                   	push   %ebx
f01024f8:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01024fe:	e8 99 ea ff ff       	call   f0100f9c <pgdir_walk>
f0102503:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102509:	83 c4 0c             	add    $0xc,%esp
f010250c:	6a 00                	push   $0x0
f010250e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102511:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102517:	e8 80 ea ff ff       	call   f0100f9c <pgdir_walk>
f010251c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102522:	83 c4 0c             	add    $0xc,%esp
f0102525:	6a 00                	push   $0x0
f0102527:	56                   	push   %esi
f0102528:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f010252e:	e8 69 ea ff ff       	call   f0100f9c <pgdir_walk>
f0102533:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102539:	c7 04 24 20 6b 10 f0 	movl   $0xf0106b20,(%esp)
f0102540:	e8 50 11 00 00       	call   f0103695 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U | PTE_P);
f0102545:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010254a:	83 c4 10             	add    $0x10,%esp
f010254d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102552:	77 15                	ja     f0102569 <mem_init+0x130f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102554:	50                   	push   %eax
f0102555:	68 c8 59 10 f0       	push   $0xf01059c8
f010255a:	68 b7 00 00 00       	push   $0xb7
f010255f:	68 41 68 10 f0       	push   $0xf0106841
f0102564:	e8 d7 da ff ff       	call   f0100040 <_panic>
f0102569:	83 ec 08             	sub    $0x8,%esp
f010256c:	6a 05                	push   $0x5
f010256e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102573:	50                   	push   %eax
f0102574:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102579:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010257e:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102583:	e8 d8 ea ff ff       	call   f0101060 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U | PTE_P);
f0102588:	a1 48 a2 22 f0       	mov    0xf022a248,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010258d:	83 c4 10             	add    $0x10,%esp
f0102590:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102595:	77 15                	ja     f01025ac <mem_init+0x1352>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102597:	50                   	push   %eax
f0102598:	68 c8 59 10 f0       	push   $0xf01059c8
f010259d:	68 bf 00 00 00       	push   $0xbf
f01025a2:	68 41 68 10 f0       	push   $0xf0106841
f01025a7:	e8 94 da ff ff       	call   f0100040 <_panic>
f01025ac:	83 ec 08             	sub    $0x8,%esp
f01025af:	6a 05                	push   $0x5
f01025b1:	05 00 00 00 10       	add    $0x10000000,%eax
f01025b6:	50                   	push   %eax
f01025b7:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01025bc:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01025c1:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01025c6:	e8 95 ea ff ff       	call   f0101060 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025cb:	83 c4 10             	add    $0x10,%esp
f01025ce:	b8 00 50 11 f0       	mov    $0xf0115000,%eax
f01025d3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025d8:	77 15                	ja     f01025ef <mem_init+0x1395>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025da:	50                   	push   %eax
f01025db:	68 c8 59 10 f0       	push   $0xf01059c8
f01025e0:	68 cb 00 00 00       	push   $0xcb
f01025e5:	68 41 68 10 f0       	push   $0xf0106841
f01025ea:	e8 51 da ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01025ef:	83 ec 08             	sub    $0x8,%esp
f01025f2:	6a 02                	push   $0x2
f01025f4:	68 00 50 11 00       	push   $0x115000
f01025f9:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01025fe:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102603:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102608:	e8 53 ea ff ff       	call   f0101060 <boot_map_region>
f010260d:	c7 45 c4 00 c0 22 f0 	movl   $0xf022c000,-0x3c(%ebp)
f0102614:	83 c4 10             	add    $0x10,%esp
f0102617:	bb 00 c0 22 f0       	mov    $0xf022c000,%ebx
f010261c:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102621:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102627:	77 15                	ja     f010263e <mem_init+0x13e4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102629:	53                   	push   %ebx
f010262a:	68 c8 59 10 f0       	push   $0xf01059c8
f010262f:	68 0b 01 00 00       	push   $0x10b
f0102634:	68 41 68 10 f0       	push   $0xf0106841
f0102639:	e8 02 da ff ff       	call   f0100040 <_panic>
	// LAB 4: Your code here:
	uintptr_t kstacktop_i;
	for(int i = 0;i < NCPU;i++)
	{
		kstacktop_i = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
		boot_map_region(kern_pgdir, kstacktop_i - KSTKSIZE, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W);
f010263e:	83 ec 08             	sub    $0x8,%esp
f0102641:	6a 02                	push   $0x2
f0102643:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0102649:	50                   	push   %eax
f010264a:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010264f:	89 f2                	mov    %esi,%edx
f0102651:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102656:	e8 05 ea ff ff       	call   f0101060 <boot_map_region>
f010265b:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102661:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//             Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	uintptr_t kstacktop_i;
	for(int i = 0;i < NCPU;i++)
f0102667:	83 c4 10             	add    $0x10,%esp
f010266a:	b8 00 c0 26 f0       	mov    $0xf026c000,%eax
f010266f:	39 d8                	cmp    %ebx,%eax
f0102671:	75 ae                	jne    f0102621 <mem_init+0x13c7>
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	// Initialize the SMP-related parts of the memory map
	mem_init_mp();
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff-KERNBASE, 0, PTE_W);
f0102673:	83 ec 08             	sub    $0x8,%esp
f0102676:	6a 02                	push   $0x2
f0102678:	6a 00                	push   $0x0
f010267a:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010267f:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102684:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102689:	e8 d2 e9 ff ff       	call   f0101060 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010268e:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102694:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0102699:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010269c:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01026a3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01026a8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026ab:	8b 35 90 ae 22 f0    	mov    0xf022ae90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026b1:	89 75 d0             	mov    %esi,-0x30(%ebp)
f01026b4:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026b7:	bb 00 00 00 00       	mov    $0x0,%ebx
f01026bc:	eb 55                	jmp    f0102713 <mem_init+0x14b9>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026be:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01026c4:	89 f8                	mov    %edi,%eax
f01026c6:	e8 d6 e3 ff ff       	call   f0100aa1 <check_va2pa>
f01026cb:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01026d2:	77 15                	ja     f01026e9 <mem_init+0x148f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026d4:	56                   	push   %esi
f01026d5:	68 c8 59 10 f0       	push   $0xf01059c8
f01026da:	68 a1 03 00 00       	push   $0x3a1
f01026df:	68 41 68 10 f0       	push   $0xf0106841
f01026e4:	e8 57 d9 ff ff       	call   f0100040 <_panic>
f01026e9:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f01026f0:	39 c2                	cmp    %eax,%edx
f01026f2:	74 19                	je     f010270d <mem_init+0x14b3>
f01026f4:	68 50 66 10 f0       	push   $0xf0106650
f01026f9:	68 67 68 10 f0       	push   $0xf0106867
f01026fe:	68 a1 03 00 00       	push   $0x3a1
f0102703:	68 41 68 10 f0       	push   $0xf0106841
f0102708:	e8 33 d9 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010270d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102713:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102716:	77 a6                	ja     f01026be <mem_init+0x1464>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102718:	8b 35 48 a2 22 f0    	mov    0xf022a248,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010271e:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102721:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102726:	89 da                	mov    %ebx,%edx
f0102728:	89 f8                	mov    %edi,%eax
f010272a:	e8 72 e3 ff ff       	call   f0100aa1 <check_va2pa>
f010272f:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102736:	77 15                	ja     f010274d <mem_init+0x14f3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102738:	56                   	push   %esi
f0102739:	68 c8 59 10 f0       	push   $0xf01059c8
f010273e:	68 a6 03 00 00       	push   $0x3a6
f0102743:	68 41 68 10 f0       	push   $0xf0106841
f0102748:	e8 f3 d8 ff ff       	call   f0100040 <_panic>
f010274d:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f0102754:	39 d0                	cmp    %edx,%eax
f0102756:	74 19                	je     f0102771 <mem_init+0x1517>
f0102758:	68 84 66 10 f0       	push   $0xf0106684
f010275d:	68 67 68 10 f0       	push   $0xf0106867
f0102762:	68 a6 03 00 00       	push   $0x3a6
f0102767:	68 41 68 10 f0       	push   $0xf0106841
f010276c:	e8 cf d8 ff ff       	call   f0100040 <_panic>
f0102771:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102777:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f010277d:	75 a7                	jne    f0102726 <mem_init+0x14cc>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010277f:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0102782:	c1 e6 0c             	shl    $0xc,%esi
f0102785:	bb 00 00 00 00       	mov    $0x0,%ebx
f010278a:	eb 30                	jmp    f01027bc <mem_init+0x1562>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010278c:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102792:	89 f8                	mov    %edi,%eax
f0102794:	e8 08 e3 ff ff       	call   f0100aa1 <check_va2pa>
f0102799:	39 c3                	cmp    %eax,%ebx
f010279b:	74 19                	je     f01027b6 <mem_init+0x155c>
f010279d:	68 b8 66 10 f0       	push   $0xf01066b8
f01027a2:	68 67 68 10 f0       	push   $0xf0106867
f01027a7:	68 aa 03 00 00       	push   $0x3aa
f01027ac:	68 41 68 10 f0       	push   $0xf0106841
f01027b1:	e8 8a d8 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01027b6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01027bc:	39 f3                	cmp    %esi,%ebx
f01027be:	72 cc                	jb     f010278c <mem_init+0x1532>
f01027c0:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f01027c5:	89 75 cc             	mov    %esi,-0x34(%ebp)
f01027c8:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01027cb:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01027ce:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f01027d4:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01027d7:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f01027d9:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01027dc:	05 00 80 00 20       	add    $0x20008000,%eax
f01027e1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01027e4:	89 da                	mov    %ebx,%edx
f01027e6:	89 f8                	mov    %edi,%eax
f01027e8:	e8 b4 e2 ff ff       	call   f0100aa1 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027ed:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01027f3:	77 15                	ja     f010280a <mem_init+0x15b0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027f5:	56                   	push   %esi
f01027f6:	68 c8 59 10 f0       	push   $0xf01059c8
f01027fb:	68 b2 03 00 00       	push   $0x3b2
f0102800:	68 41 68 10 f0       	push   $0xf0106841
f0102805:	e8 36 d8 ff ff       	call   f0100040 <_panic>
f010280a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010280d:	8d 94 0b 00 c0 22 f0 	lea    -0xfdd4000(%ebx,%ecx,1),%edx
f0102814:	39 d0                	cmp    %edx,%eax
f0102816:	74 19                	je     f0102831 <mem_init+0x15d7>
f0102818:	68 e0 66 10 f0       	push   $0xf01066e0
f010281d:	68 67 68 10 f0       	push   $0xf0106867
f0102822:	68 b2 03 00 00       	push   $0x3b2
f0102827:	68 41 68 10 f0       	push   $0xf0106841
f010282c:	e8 0f d8 ff ff       	call   f0100040 <_panic>
f0102831:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102837:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f010283a:	75 a8                	jne    f01027e4 <mem_init+0x158a>
f010283c:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010283f:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f0102845:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102848:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f010284a:	89 da                	mov    %ebx,%edx
f010284c:	89 f8                	mov    %edi,%eax
f010284e:	e8 4e e2 ff ff       	call   f0100aa1 <check_va2pa>
f0102853:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102856:	74 19                	je     f0102871 <mem_init+0x1617>
f0102858:	68 28 67 10 f0       	push   $0xf0106728
f010285d:	68 67 68 10 f0       	push   $0xf0106867
f0102862:	68 b4 03 00 00       	push   $0x3b4
f0102867:	68 41 68 10 f0       	push   $0xf0106841
f010286c:	e8 cf d7 ff ff       	call   f0100040 <_panic>
f0102871:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102877:	39 de                	cmp    %ebx,%esi
f0102879:	75 cf                	jne    f010284a <mem_init+0x15f0>
f010287b:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010287e:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f0102885:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f010288c:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102892:	81 fe 00 c0 26 f0    	cmp    $0xf026c000,%esi
f0102898:	0f 85 2d ff ff ff    	jne    f01027cb <mem_init+0x1571>
f010289e:	b8 00 00 00 00       	mov    $0x0,%eax
f01028a3:	eb 2a                	jmp    f01028cf <mem_init+0x1675>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01028a5:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f01028ab:	83 fa 04             	cmp    $0x4,%edx
f01028ae:	77 1f                	ja     f01028cf <mem_init+0x1675>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f01028b0:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f01028b4:	75 7e                	jne    f0102934 <mem_init+0x16da>
f01028b6:	68 39 6b 10 f0       	push   $0xf0106b39
f01028bb:	68 67 68 10 f0       	push   $0xf0106867
f01028c0:	68 bf 03 00 00       	push   $0x3bf
f01028c5:	68 41 68 10 f0       	push   $0xf0106841
f01028ca:	e8 71 d7 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01028cf:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01028d4:	76 3f                	jbe    f0102915 <mem_init+0x16bb>
				assert(pgdir[i] & PTE_P);
f01028d6:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01028d9:	f6 c2 01             	test   $0x1,%dl
f01028dc:	75 19                	jne    f01028f7 <mem_init+0x169d>
f01028de:	68 39 6b 10 f0       	push   $0xf0106b39
f01028e3:	68 67 68 10 f0       	push   $0xf0106867
f01028e8:	68 c3 03 00 00       	push   $0x3c3
f01028ed:	68 41 68 10 f0       	push   $0xf0106841
f01028f2:	e8 49 d7 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f01028f7:	f6 c2 02             	test   $0x2,%dl
f01028fa:	75 38                	jne    f0102934 <mem_init+0x16da>
f01028fc:	68 4a 6b 10 f0       	push   $0xf0106b4a
f0102901:	68 67 68 10 f0       	push   $0xf0106867
f0102906:	68 c4 03 00 00       	push   $0x3c4
f010290b:	68 41 68 10 f0       	push   $0xf0106841
f0102910:	e8 2b d7 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102915:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102919:	74 19                	je     f0102934 <mem_init+0x16da>
f010291b:	68 5b 6b 10 f0       	push   $0xf0106b5b
f0102920:	68 67 68 10 f0       	push   $0xf0106867
f0102925:	68 c6 03 00 00       	push   $0x3c6
f010292a:	68 41 68 10 f0       	push   $0xf0106841
f010292f:	e8 0c d7 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102934:	83 c0 01             	add    $0x1,%eax
f0102937:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010293c:	0f 86 63 ff ff ff    	jbe    f01028a5 <mem_init+0x164b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102942:	83 ec 0c             	sub    $0xc,%esp
f0102945:	68 4c 67 10 f0       	push   $0xf010674c
f010294a:	e8 46 0d 00 00       	call   f0103695 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010294f:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102954:	83 c4 10             	add    $0x10,%esp
f0102957:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010295c:	77 15                	ja     f0102973 <mem_init+0x1719>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010295e:	50                   	push   %eax
f010295f:	68 c8 59 10 f0       	push   $0xf01059c8
f0102964:	68 e2 00 00 00       	push   $0xe2
f0102969:	68 41 68 10 f0       	push   $0xf0106841
f010296e:	e8 cd d6 ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102973:	05 00 00 00 10       	add    $0x10000000,%eax
f0102978:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010297b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102980:	e8 80 e1 ff ff       	call   f0100b05 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102985:	0f 20 c0             	mov    %cr0,%eax
f0102988:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f010298b:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102990:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102993:	83 ec 0c             	sub    $0xc,%esp
f0102996:	6a 00                	push   $0x0
f0102998:	e8 53 e5 ff ff       	call   f0100ef0 <page_alloc>
f010299d:	89 c3                	mov    %eax,%ebx
f010299f:	83 c4 10             	add    $0x10,%esp
f01029a2:	85 c0                	test   %eax,%eax
f01029a4:	75 19                	jne    f01029bf <mem_init+0x1765>
f01029a6:	68 45 69 10 f0       	push   $0xf0106945
f01029ab:	68 67 68 10 f0       	push   $0xf0106867
f01029b0:	68 9e 04 00 00       	push   $0x49e
f01029b5:	68 41 68 10 f0       	push   $0xf0106841
f01029ba:	e8 81 d6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01029bf:	83 ec 0c             	sub    $0xc,%esp
f01029c2:	6a 00                	push   $0x0
f01029c4:	e8 27 e5 ff ff       	call   f0100ef0 <page_alloc>
f01029c9:	89 c7                	mov    %eax,%edi
f01029cb:	83 c4 10             	add    $0x10,%esp
f01029ce:	85 c0                	test   %eax,%eax
f01029d0:	75 19                	jne    f01029eb <mem_init+0x1791>
f01029d2:	68 5b 69 10 f0       	push   $0xf010695b
f01029d7:	68 67 68 10 f0       	push   $0xf0106867
f01029dc:	68 9f 04 00 00       	push   $0x49f
f01029e1:	68 41 68 10 f0       	push   $0xf0106841
f01029e6:	e8 55 d6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01029eb:	83 ec 0c             	sub    $0xc,%esp
f01029ee:	6a 00                	push   $0x0
f01029f0:	e8 fb e4 ff ff       	call   f0100ef0 <page_alloc>
f01029f5:	89 c6                	mov    %eax,%esi
f01029f7:	83 c4 10             	add    $0x10,%esp
f01029fa:	85 c0                	test   %eax,%eax
f01029fc:	75 19                	jne    f0102a17 <mem_init+0x17bd>
f01029fe:	68 71 69 10 f0       	push   $0xf0106971
f0102a03:	68 67 68 10 f0       	push   $0xf0106867
f0102a08:	68 a0 04 00 00       	push   $0x4a0
f0102a0d:	68 41 68 10 f0       	push   $0xf0106841
f0102a12:	e8 29 d6 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102a17:	83 ec 0c             	sub    $0xc,%esp
f0102a1a:	53                   	push   %ebx
f0102a1b:	e8 46 e5 ff ff       	call   f0100f66 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a20:	89 f8                	mov    %edi,%eax
f0102a22:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102a28:	c1 f8 03             	sar    $0x3,%eax
f0102a2b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a2e:	89 c2                	mov    %eax,%edx
f0102a30:	c1 ea 0c             	shr    $0xc,%edx
f0102a33:	83 c4 10             	add    $0x10,%esp
f0102a36:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102a3c:	72 12                	jb     f0102a50 <mem_init+0x17f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a3e:	50                   	push   %eax
f0102a3f:	68 a4 59 10 f0       	push   $0xf01059a4
f0102a44:	6a 58                	push   $0x58
f0102a46:	68 4d 68 10 f0       	push   $0xf010684d
f0102a4b:	e8 f0 d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102a50:	83 ec 04             	sub    $0x4,%esp
f0102a53:	68 00 10 00 00       	push   $0x1000
f0102a58:	6a 01                	push   $0x1
f0102a5a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a5f:	50                   	push   %eax
f0102a60:	e8 67 22 00 00       	call   f0104ccc <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a65:	89 f0                	mov    %esi,%eax
f0102a67:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102a6d:	c1 f8 03             	sar    $0x3,%eax
f0102a70:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a73:	89 c2                	mov    %eax,%edx
f0102a75:	c1 ea 0c             	shr    $0xc,%edx
f0102a78:	83 c4 10             	add    $0x10,%esp
f0102a7b:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102a81:	72 12                	jb     f0102a95 <mem_init+0x183b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a83:	50                   	push   %eax
f0102a84:	68 a4 59 10 f0       	push   $0xf01059a4
f0102a89:	6a 58                	push   $0x58
f0102a8b:	68 4d 68 10 f0       	push   $0xf010684d
f0102a90:	e8 ab d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102a95:	83 ec 04             	sub    $0x4,%esp
f0102a98:	68 00 10 00 00       	push   $0x1000
f0102a9d:	6a 02                	push   $0x2
f0102a9f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102aa4:	50                   	push   %eax
f0102aa5:	e8 22 22 00 00       	call   f0104ccc <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102aaa:	6a 02                	push   $0x2
f0102aac:	68 00 10 00 00       	push   $0x1000
f0102ab1:	57                   	push   %edi
f0102ab2:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102ab8:	e8 cd e6 ff ff       	call   f010118a <page_insert>
	assert(pp1->pp_ref == 1);
f0102abd:	83 c4 20             	add    $0x20,%esp
f0102ac0:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102ac5:	74 19                	je     f0102ae0 <mem_init+0x1886>
f0102ac7:	68 42 6a 10 f0       	push   $0xf0106a42
f0102acc:	68 67 68 10 f0       	push   $0xf0106867
f0102ad1:	68 a5 04 00 00       	push   $0x4a5
f0102ad6:	68 41 68 10 f0       	push   $0xf0106841
f0102adb:	e8 60 d5 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ae0:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102ae7:	01 01 01 
f0102aea:	74 19                	je     f0102b05 <mem_init+0x18ab>
f0102aec:	68 6c 67 10 f0       	push   $0xf010676c
f0102af1:	68 67 68 10 f0       	push   $0xf0106867
f0102af6:	68 a6 04 00 00       	push   $0x4a6
f0102afb:	68 41 68 10 f0       	push   $0xf0106841
f0102b00:	e8 3b d5 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b05:	6a 02                	push   $0x2
f0102b07:	68 00 10 00 00       	push   $0x1000
f0102b0c:	56                   	push   %esi
f0102b0d:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102b13:	e8 72 e6 ff ff       	call   f010118a <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102b18:	83 c4 10             	add    $0x10,%esp
f0102b1b:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b22:	02 02 02 
f0102b25:	74 19                	je     f0102b40 <mem_init+0x18e6>
f0102b27:	68 90 67 10 f0       	push   $0xf0106790
f0102b2c:	68 67 68 10 f0       	push   $0xf0106867
f0102b31:	68 a8 04 00 00       	push   $0x4a8
f0102b36:	68 41 68 10 f0       	push   $0xf0106841
f0102b3b:	e8 00 d5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102b40:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b45:	74 19                	je     f0102b60 <mem_init+0x1906>
f0102b47:	68 64 6a 10 f0       	push   $0xf0106a64
f0102b4c:	68 67 68 10 f0       	push   $0xf0106867
f0102b51:	68 a9 04 00 00       	push   $0x4a9
f0102b56:	68 41 68 10 f0       	push   $0xf0106841
f0102b5b:	e8 e0 d4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102b60:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102b65:	74 19                	je     f0102b80 <mem_init+0x1926>
f0102b67:	68 ce 6a 10 f0       	push   $0xf0106ace
f0102b6c:	68 67 68 10 f0       	push   $0xf0106867
f0102b71:	68 aa 04 00 00       	push   $0x4aa
f0102b76:	68 41 68 10 f0       	push   $0xf0106841
f0102b7b:	e8 c0 d4 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b80:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b87:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b8a:	89 f0                	mov    %esi,%eax
f0102b8c:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102b92:	c1 f8 03             	sar    $0x3,%eax
f0102b95:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b98:	89 c2                	mov    %eax,%edx
f0102b9a:	c1 ea 0c             	shr    $0xc,%edx
f0102b9d:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102ba3:	72 12                	jb     f0102bb7 <mem_init+0x195d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ba5:	50                   	push   %eax
f0102ba6:	68 a4 59 10 f0       	push   $0xf01059a4
f0102bab:	6a 58                	push   $0x58
f0102bad:	68 4d 68 10 f0       	push   $0xf010684d
f0102bb2:	e8 89 d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102bb7:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102bbe:	03 03 03 
f0102bc1:	74 19                	je     f0102bdc <mem_init+0x1982>
f0102bc3:	68 b4 67 10 f0       	push   $0xf01067b4
f0102bc8:	68 67 68 10 f0       	push   $0xf0106867
f0102bcd:	68 ac 04 00 00       	push   $0x4ac
f0102bd2:	68 41 68 10 f0       	push   $0xf0106841
f0102bd7:	e8 64 d4 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102bdc:	83 ec 08             	sub    $0x8,%esp
f0102bdf:	68 00 10 00 00       	push   $0x1000
f0102be4:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102bea:	e8 52 e5 ff ff       	call   f0101141 <page_remove>
	assert(pp2->pp_ref == 0);
f0102bef:	83 c4 10             	add    $0x10,%esp
f0102bf2:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102bf7:	74 19                	je     f0102c12 <mem_init+0x19b8>
f0102bf9:	68 9c 6a 10 f0       	push   $0xf0106a9c
f0102bfe:	68 67 68 10 f0       	push   $0xf0106867
f0102c03:	68 ae 04 00 00       	push   $0x4ae
f0102c08:	68 41 68 10 f0       	push   $0xf0106841
f0102c0d:	e8 2e d4 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c12:	8b 0d 8c ae 22 f0    	mov    0xf022ae8c,%ecx
f0102c18:	8b 11                	mov    (%ecx),%edx
f0102c1a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102c20:	89 d8                	mov    %ebx,%eax
f0102c22:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102c28:	c1 f8 03             	sar    $0x3,%eax
f0102c2b:	c1 e0 0c             	shl    $0xc,%eax
f0102c2e:	39 c2                	cmp    %eax,%edx
f0102c30:	74 19                	je     f0102c4b <mem_init+0x19f1>
f0102c32:	68 3c 61 10 f0       	push   $0xf010613c
f0102c37:	68 67 68 10 f0       	push   $0xf0106867
f0102c3c:	68 b1 04 00 00       	push   $0x4b1
f0102c41:	68 41 68 10 f0       	push   $0xf0106841
f0102c46:	e8 f5 d3 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102c4b:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102c51:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102c56:	74 19                	je     f0102c71 <mem_init+0x1a17>
f0102c58:	68 53 6a 10 f0       	push   $0xf0106a53
f0102c5d:	68 67 68 10 f0       	push   $0xf0106867
f0102c62:	68 b3 04 00 00       	push   $0x4b3
f0102c67:	68 41 68 10 f0       	push   $0xf0106841
f0102c6c:	e8 cf d3 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102c71:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102c77:	83 ec 0c             	sub    $0xc,%esp
f0102c7a:	53                   	push   %ebx
f0102c7b:	e8 e6 e2 ff ff       	call   f0100f66 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102c80:	c7 04 24 e0 67 10 f0 	movl   $0xf01067e0,(%esp)
f0102c87:	e8 09 0a 00 00       	call   f0103695 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102c8c:	83 c4 10             	add    $0x10,%esp
f0102c8f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c92:	5b                   	pop    %ebx
f0102c93:	5e                   	pop    %esi
f0102c94:	5f                   	pop    %edi
f0102c95:	5d                   	pop    %ebp
f0102c96:	c3                   	ret    

f0102c97 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102c97:	55                   	push   %ebp
f0102c98:	89 e5                	mov    %esp,%ebp
f0102c9a:	57                   	push   %edi
f0102c9b:	56                   	push   %esi
f0102c9c:	53                   	push   %ebx
f0102c9d:	83 ec 1c             	sub    $0x1c,%esp
f0102ca0:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102ca3:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	uint32_t start = (uint32_t)ROUNDDOWN(va, PGSIZE);
f0102ca6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ca9:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t end = (uint32_t)ROUNDUP(va+len, PGSIZE);
f0102caf:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102cb2:	03 45 10             	add    0x10(%ebp),%eax
f0102cb5:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102cba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102cbf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(uint32_t i = start;i < end;i += PGSIZE)
f0102cc2:	eb 50                	jmp    f0102d14 <user_mem_check+0x7d>
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, (void *)i, 0);
f0102cc4:	83 ec 04             	sub    $0x4,%esp
f0102cc7:	6a 00                	push   $0x0
f0102cc9:	53                   	push   %ebx
f0102cca:	ff 77 60             	pushl  0x60(%edi)
f0102ccd:	e8 ca e2 ff ff       	call   f0100f9c <pgdir_walk>
// A user program can access a virtual address if (1) the address is below
// ULIM, and (2) the page table gives it permission. 
		//不满足的条件:1.地址大于ULIM 2.pte不存在 3.pte没有PTE_P的权限位 
		//4.pte的权限比perm高，说明当前权限无法访问对应内存
		if(i >= ULIM || !pte || !(*pte & PTE_P) || (*pte & perm) != perm)
f0102cd2:	83 c4 10             	add    $0x10,%esp
f0102cd5:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102cdb:	77 10                	ja     f0102ced <user_mem_check+0x56>
f0102cdd:	85 c0                	test   %eax,%eax
f0102cdf:	74 0c                	je     f0102ced <user_mem_check+0x56>
f0102ce1:	8b 00                	mov    (%eax),%eax
f0102ce3:	a8 01                	test   $0x1,%al
f0102ce5:	74 06                	je     f0102ced <user_mem_check+0x56>
f0102ce7:	21 f0                	and    %esi,%eax
f0102ce9:	39 c6                	cmp    %eax,%esi
f0102ceb:	74 21                	je     f0102d0e <user_mem_check+0x77>
		{
// If there is an error, set the 'user_mem_check_addr' variable to the first
// erroneous virtual address.
			//如果出错的是va之前的地址，需要返回的也应该是va的地址
			if(i < (uint32_t)va)
f0102ced:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0102cf0:	73 0f                	jae    f0102d01 <user_mem_check+0x6a>
				user_mem_check_addr = (uint32_t)va;
f0102cf2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102cf5:	a3 3c a2 22 f0       	mov    %eax,0xf022a23c
			else 
				user_mem_check_addr = i;
			return -E_FAULT;
f0102cfa:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102cff:	eb 1d                	jmp    f0102d1e <user_mem_check+0x87>
// erroneous virtual address.
			//如果出错的是va之前的地址，需要返回的也应该是va的地址
			if(i < (uint32_t)va)
				user_mem_check_addr = (uint32_t)va;
			else 
				user_mem_check_addr = i;
f0102d01:	89 1d 3c a2 22 f0    	mov    %ebx,0xf022a23c
			return -E_FAULT;
f0102d07:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d0c:	eb 10                	jmp    f0102d1e <user_mem_check+0x87>
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	uint32_t start = (uint32_t)ROUNDDOWN(va, PGSIZE);
	uint32_t end = (uint32_t)ROUNDUP(va+len, PGSIZE);
	for(uint32_t i = start;i < end;i += PGSIZE)
f0102d0e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102d14:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102d17:	72 ab                	jb     f0102cc4 <user_mem_check+0x2d>
			else 
				user_mem_check_addr = i;
			return -E_FAULT;
		} 
	}
	return 0;
f0102d19:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102d1e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d21:	5b                   	pop    %ebx
f0102d22:	5e                   	pop    %esi
f0102d23:	5f                   	pop    %edi
f0102d24:	5d                   	pop    %ebp
f0102d25:	c3                   	ret    

f0102d26 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102d26:	55                   	push   %ebp
f0102d27:	89 e5                	mov    %esp,%ebp
f0102d29:	53                   	push   %ebx
f0102d2a:	83 ec 04             	sub    $0x4,%esp
f0102d2d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102d30:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d33:	83 c8 04             	or     $0x4,%eax
f0102d36:	50                   	push   %eax
f0102d37:	ff 75 10             	pushl  0x10(%ebp)
f0102d3a:	ff 75 0c             	pushl  0xc(%ebp)
f0102d3d:	53                   	push   %ebx
f0102d3e:	e8 54 ff ff ff       	call   f0102c97 <user_mem_check>
f0102d43:	83 c4 10             	add    $0x10,%esp
f0102d46:	85 c0                	test   %eax,%eax
f0102d48:	79 21                	jns    f0102d6b <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102d4a:	83 ec 04             	sub    $0x4,%esp
f0102d4d:	ff 35 3c a2 22 f0    	pushl  0xf022a23c
f0102d53:	ff 73 48             	pushl  0x48(%ebx)
f0102d56:	68 0c 68 10 f0       	push   $0xf010680c
f0102d5b:	e8 35 09 00 00       	call   f0103695 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102d60:	89 1c 24             	mov    %ebx,(%esp)
f0102d63:	e8 46 06 00 00       	call   f01033ae <env_destroy>
f0102d68:	83 c4 10             	add    $0x10,%esp
	}
}
f0102d6b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102d6e:	c9                   	leave  
f0102d6f:	c3                   	ret    

f0102d70 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102d70:	55                   	push   %ebp
f0102d71:	89 e5                	mov    %esp,%ebp
f0102d73:	57                   	push   %edi
f0102d74:	56                   	push   %esi
f0102d75:	53                   	push   %ebx
f0102d76:	83 ec 0c             	sub    $0xc,%esp
f0102d79:	89 c7                	mov    %eax,%edi
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	//boot_map_region(e->env_pgdir, va, len, PADDR(envs), PTE_P | PTE_U | PTE_W);
	uint32_t start,end;
	start = ROUNDDOWN((uint32_t)va, PGSIZE);
	end = ROUNDUP((uint32_t)(va + len), PGSIZE);
f0102d7b:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102d82:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	//cprintf("start=%x \n",start);
	//cprintf("end=%x \n",end);

	struct PageInfo *Page;
	int r;
	for(int i = start;i < end;i += PGSIZE)
f0102d88:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102d8e:	89 d3                	mov    %edx,%ebx
f0102d90:	eb 56                	jmp    f0102de8 <region_alloc+0x78>
	{
		Page = page_alloc(0);
f0102d92:	83 ec 0c             	sub    $0xc,%esp
f0102d95:	6a 00                	push   $0x0
f0102d97:	e8 54 e1 ff ff       	call   f0100ef0 <page_alloc>
		if(!Page)
f0102d9c:	83 c4 10             	add    $0x10,%esp
f0102d9f:	85 c0                	test   %eax,%eax
f0102da1:	75 17                	jne    f0102dba <region_alloc+0x4a>
			panic("page_alloc fail");
f0102da3:	83 ec 04             	sub    $0x4,%esp
f0102da6:	68 69 6b 10 f0       	push   $0xf0106b69
f0102dab:	68 34 01 00 00       	push   $0x134
f0102db0:	68 79 6b 10 f0       	push   $0xf0106b79
f0102db5:	e8 86 d2 ff ff       	call   f0100040 <_panic>
		//r = page_insert(e->env_pgdir, Page, va, PTE_P | PTE_U | PTE_W);
		r = page_insert(e->env_pgdir, Page, (void *)i, PTE_U | PTE_W);
f0102dba:	6a 06                	push   $0x6
f0102dbc:	53                   	push   %ebx
f0102dbd:	50                   	push   %eax
f0102dbe:	ff 77 60             	pushl  0x60(%edi)
f0102dc1:	e8 c4 e3 ff ff       	call   f010118a <page_insert>
		if(r != 0)
f0102dc6:	83 c4 10             	add    $0x10,%esp
f0102dc9:	85 c0                	test   %eax,%eax
f0102dcb:	74 15                	je     f0102de2 <region_alloc+0x72>
			panic("region_alloc: %e", r);
f0102dcd:	50                   	push   %eax
f0102dce:	68 84 6b 10 f0       	push   $0xf0106b84
f0102dd3:	68 38 01 00 00       	push   $0x138
f0102dd8:	68 79 6b 10 f0       	push   $0xf0106b79
f0102ddd:	e8 5e d2 ff ff       	call   f0100040 <_panic>
	//cprintf("start=%x \n",start);
	//cprintf("end=%x \n",end);

	struct PageInfo *Page;
	int r;
	for(int i = start;i < end;i += PGSIZE)
f0102de2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102de8:	39 de                	cmp    %ebx,%esi
f0102dea:	77 a6                	ja     f0102d92 <region_alloc+0x22>
		r = page_insert(e->env_pgdir, Page, (void *)i, PTE_U | PTE_W);
		if(r != 0)
			panic("region_alloc: %e", r);
			//panic("region_alloc fail");
	}
}
f0102dec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102def:	5b                   	pop    %ebx
f0102df0:	5e                   	pop    %esi
f0102df1:	5f                   	pop    %edi
f0102df2:	5d                   	pop    %ebp
f0102df3:	c3                   	ret    

f0102df4 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102df4:	55                   	push   %ebp
f0102df5:	89 e5                	mov    %esp,%ebp
f0102df7:	56                   	push   %esi
f0102df8:	53                   	push   %ebx
f0102df9:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dfc:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102dff:	85 c0                	test   %eax,%eax
f0102e01:	75 1a                	jne    f0102e1d <envid2env+0x29>
		*env_store = curenv;
f0102e03:	e8 e6 24 00 00       	call   f01052ee <cpunum>
f0102e08:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e0b:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102e11:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102e14:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102e16:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e1b:	eb 70                	jmp    f0102e8d <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102e1d:	89 c3                	mov    %eax,%ebx
f0102e1f:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102e25:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102e28:	03 1d 48 a2 22 f0    	add    0xf022a248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102e2e:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102e32:	74 05                	je     f0102e39 <envid2env+0x45>
f0102e34:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102e37:	74 10                	je     f0102e49 <envid2env+0x55>
		*env_store = 0;
f0102e39:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e3c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e42:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e47:	eb 44                	jmp    f0102e8d <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102e49:	84 d2                	test   %dl,%dl
f0102e4b:	74 36                	je     f0102e83 <envid2env+0x8f>
f0102e4d:	e8 9c 24 00 00       	call   f01052ee <cpunum>
f0102e52:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e55:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f0102e5b:	74 26                	je     f0102e83 <envid2env+0x8f>
f0102e5d:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102e60:	e8 89 24 00 00       	call   f01052ee <cpunum>
f0102e65:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e68:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102e6e:	3b 70 48             	cmp    0x48(%eax),%esi
f0102e71:	74 10                	je     f0102e83 <envid2env+0x8f>
		*env_store = 0;
f0102e73:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e76:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e7c:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e81:	eb 0a                	jmp    f0102e8d <envid2env+0x99>
	}

	*env_store = e;
f0102e83:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e86:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102e88:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102e8d:	5b                   	pop    %ebx
f0102e8e:	5e                   	pop    %esi
f0102e8f:	5d                   	pop    %ebp
f0102e90:	c3                   	ret    

f0102e91 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102e91:	55                   	push   %ebp
f0102e92:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102e94:	b8 20 f3 11 f0       	mov    $0xf011f320,%eax
f0102e99:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102e9c:	b8 23 00 00 00       	mov    $0x23,%eax
f0102ea1:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102ea3:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102ea5:	b8 10 00 00 00       	mov    $0x10,%eax
f0102eaa:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102eac:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102eae:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102eb0:	ea b7 2e 10 f0 08 00 	ljmp   $0x8,$0xf0102eb7
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102eb7:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ebc:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102ebf:	5d                   	pop    %ebp
f0102ec0:	c3                   	ret    

f0102ec1 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102ec1:	55                   	push   %ebp
f0102ec2:	89 e5                	mov    %esp,%ebp
f0102ec4:	56                   	push   %esi
f0102ec5:	53                   	push   %ebx
	// LAB 3: Your code here.
	// struct Env* envs;
	// env_free_list = NULL;
	for(int i = NENV - 1;i >= 0;i--)
	{
		envs[i].env_id = 0;
f0102ec6:	8b 35 48 a2 22 f0    	mov    0xf022a248,%esi
f0102ecc:	8b 15 4c a2 22 f0    	mov    0xf022a24c,%edx
f0102ed2:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102ed8:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102edb:	89 c1                	mov    %eax,%ecx
f0102edd:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f0102ee4:	89 50 44             	mov    %edx,0x44(%eax)
f0102ee7:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];
f0102eea:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	// struct Env* envs;
	// env_free_list = NULL;
	for(int i = NENV - 1;i >= 0;i--)
f0102eec:	39 d8                	cmp    %ebx,%eax
f0102eee:	75 eb                	jne    f0102edb <env_init+0x1a>
f0102ef0:	89 35 4c a2 22 f0    	mov    %esi,0xf022a24c
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
		//envs[i].env_status = 
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f0102ef6:	e8 96 ff ff ff       	call   f0102e91 <env_init_percpu>
}
f0102efb:	5b                   	pop    %ebx
f0102efc:	5e                   	pop    %esi
f0102efd:	5d                   	pop    %ebp
f0102efe:	c3                   	ret    

f0102eff <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102eff:	55                   	push   %ebp
f0102f00:	89 e5                	mov    %esp,%ebp
f0102f02:	56                   	push   %esi
f0102f03:	53                   	push   %ebx
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102f04:	8b 1d 4c a2 22 f0    	mov    0xf022a24c,%ebx
f0102f0a:	85 db                	test   %ebx,%ebx
f0102f0c:	0f 84 64 01 00 00    	je     f0103076 <env_alloc+0x177>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102f12:	83 ec 0c             	sub    $0xc,%esp
f0102f15:	6a 01                	push   $0x1
f0102f17:	e8 d4 df ff ff       	call   f0100ef0 <page_alloc>
f0102f1c:	89 c6                	mov    %eax,%esi
f0102f1e:	83 c4 10             	add    $0x10,%esp
f0102f21:	85 c0                	test   %eax,%eax
f0102f23:	0f 84 54 01 00 00    	je     f010307d <env_alloc+0x17e>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f29:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102f2f:	c1 f8 03             	sar    $0x3,%eax
f0102f32:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f35:	89 c2                	mov    %eax,%edx
f0102f37:	c1 ea 0c             	shr    $0xc,%edx
f0102f3a:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102f40:	72 12                	jb     f0102f54 <env_alloc+0x55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f42:	50                   	push   %eax
f0102f43:	68 a4 59 10 f0       	push   $0xf01059a4
f0102f48:	6a 58                	push   $0x58
f0102f4a:	68 4d 68 10 f0       	push   $0xf010684d
f0102f4f:	e8 ec d0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102f54:	2d 00 00 00 10       	sub    $0x10000000,%eax
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	// p = page_alloc(ALLOC_ZERO);
	e->env_pgdir = page2kva(p);
f0102f59:	89 43 60             	mov    %eax,0x60(%ebx)
	//memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
	memmove(e->env_pgdir, kern_pgdir, PGSIZE);
f0102f5c:	83 ec 04             	sub    $0x4,%esp
f0102f5f:	68 00 10 00 00       	push   $0x1000
f0102f64:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102f6a:	50                   	push   %eax
f0102f6b:	e8 a9 1d 00 00       	call   f0104d19 <memmove>
	p->pp_ref++;
f0102f70:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102f75:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f78:	83 c4 10             	add    $0x10,%esp
f0102f7b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102f80:	77 15                	ja     f0102f97 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f82:	50                   	push   %eax
f0102f83:	68 c8 59 10 f0       	push   $0xf01059c8
f0102f88:	68 c9 00 00 00       	push   $0xc9
f0102f8d:	68 79 6b 10 f0       	push   $0xf0106b79
f0102f92:	e8 a9 d0 ff ff       	call   f0100040 <_panic>
f0102f97:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102f9d:	83 ca 05             	or     $0x5,%edx
f0102fa0:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102fa6:	8b 43 48             	mov    0x48(%ebx),%eax
f0102fa9:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102fae:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102fb3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102fb8:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102fbb:	89 da                	mov    %ebx,%edx
f0102fbd:	2b 15 48 a2 22 f0    	sub    0xf022a248,%edx
f0102fc3:	c1 fa 02             	sar    $0x2,%edx
f0102fc6:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0102fcc:	09 d0                	or     %edx,%eax
f0102fce:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102fd1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fd4:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102fd7:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102fde:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102fe5:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102fec:	83 ec 04             	sub    $0x4,%esp
f0102fef:	6a 44                	push   $0x44
f0102ff1:	6a 00                	push   $0x0
f0102ff3:	53                   	push   %ebx
f0102ff4:	e8 d3 1c 00 00       	call   f0104ccc <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102ff9:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102fff:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103005:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010300b:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103012:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0103018:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f010301f:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103023:	8b 43 44             	mov    0x44(%ebx),%eax
f0103026:	a3 4c a2 22 f0       	mov    %eax,0xf022a24c
	*newenv_store = e;
f010302b:	8b 45 08             	mov    0x8(%ebp),%eax
f010302e:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103030:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103033:	e8 b6 22 00 00       	call   f01052ee <cpunum>
f0103038:	6b c0 74             	imul   $0x74,%eax,%eax
f010303b:	83 c4 10             	add    $0x10,%esp
f010303e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103043:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f010304a:	74 11                	je     f010305d <env_alloc+0x15e>
f010304c:	e8 9d 22 00 00       	call   f01052ee <cpunum>
f0103051:	6b c0 74             	imul   $0x74,%eax,%eax
f0103054:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010305a:	8b 50 48             	mov    0x48(%eax),%edx
f010305d:	83 ec 04             	sub    $0x4,%esp
f0103060:	53                   	push   %ebx
f0103061:	52                   	push   %edx
f0103062:	68 95 6b 10 f0       	push   $0xf0106b95
f0103067:	e8 29 06 00 00       	call   f0103695 <cprintf>
	return 0;
f010306c:	83 c4 10             	add    $0x10,%esp
f010306f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103074:	eb 0c                	jmp    f0103082 <env_alloc+0x183>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103076:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010307b:	eb 05                	jmp    f0103082 <env_alloc+0x183>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f010307d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103082:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103085:	5b                   	pop    %ebx
f0103086:	5e                   	pop    %esi
f0103087:	5d                   	pop    %ebp
f0103088:	c3                   	ret    

f0103089 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103089:	55                   	push   %ebp
f010308a:	89 e5                	mov    %esp,%ebp
f010308c:	57                   	push   %edi
f010308d:	56                   	push   %esi
f010308e:	53                   	push   %ebx
f010308f:	83 ec 34             	sub    $0x34,%esp
f0103092:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int r;
	r = env_alloc(&e, 0);
f0103095:	6a 00                	push   $0x0
f0103097:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010309a:	50                   	push   %eax
f010309b:	e8 5f fe ff ff       	call   f0102eff <env_alloc>
	if(r != 0)
f01030a0:	83 c4 10             	add    $0x10,%esp
f01030a3:	85 c0                	test   %eax,%eax
f01030a5:	74 15                	je     f01030bc <env_create+0x33>
		panic("env_create: %e", r);
f01030a7:	50                   	push   %eax
f01030a8:	68 aa 6b 10 f0       	push   $0xf0106baa
f01030ad:	68 ad 01 00 00       	push   $0x1ad
f01030b2:	68 79 6b 10 f0       	push   $0xf0106b79
f01030b7:	e8 84 cf ff ff       	call   f0100040 <_panic>
	//if(env_alloc(&e,0) != 0)
	//	panic("env_alloc fail");
	e->env_type = type;
f01030bc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030bf:	89 c2                	mov    %eax,%edx
f01030c1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01030c4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030c7:	89 42 50             	mov    %eax,0x50(%edx)
	struct Elf *elf;
	// 强制类型转换，将binary后的内存空间内容按照结构ELF的格式读取
	elf = (struct Elf *)binary;
	// is this a valid ELF? 判断是否是ELF
	// ELF头开头的结构体叫做魔数,是一个16位的数组
	if(elf->e_magic != ELF_MAGIC)
f01030ca:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01030d0:	74 17                	je     f01030e9 <env_create+0x60>
		panic("load segements fail");
f01030d2:	83 ec 04             	sub    $0x4,%esp
f01030d5:	68 b9 6b 10 f0       	push   $0xf0106bb9
f01030da:	68 7a 01 00 00       	push   $0x17a
f01030df:	68 79 6b 10 f0       	push   $0xf0106b79
f01030e4:	e8 57 cf ff ff       	call   f0100040 <_panic>
	// load each program segment (ignores ph flags)
	// e_phoff 程序头表的文件偏移地址
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
f01030e9:	89 fb                	mov    %edi,%ebx
f01030eb:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f01030ee:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01030f2:	c1 e6 05             	shl    $0x5,%esi
f01030f5:	01 de                	add    %ebx,%esi
	// 因为后面需要访问刚分配的内存，所以需要将env_pgdir装入cr3，使二级页表能够运作
	lcr3(PADDR(e->env_pgdir));
f01030f7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030fa:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030fd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103102:	77 15                	ja     f0103119 <env_create+0x90>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103104:	50                   	push   %eax
f0103105:	68 c8 59 10 f0       	push   $0xf01059c8
f010310a:	68 80 01 00 00       	push   $0x180
f010310f:	68 79 6b 10 f0       	push   $0xf0106b79
f0103114:	e8 27 cf ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103119:	05 00 00 00 10       	add    $0x10000000,%eax
f010311e:	0f 22 d8             	mov    %eax,%cr3
f0103121:	eb 60                	jmp    f0103183 <env_create+0xfa>

	for (; ph < eph; ph++)
	{
		// 	(The ELF header should have ph->p_filesz <= ph->p_memsz.)
		if(ph->p_filesz > ph->p_memsz)
f0103123:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103126:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f0103129:	76 17                	jbe    f0103142 <env_create+0xb9>
			panic("memory is not enough for file");
f010312b:	83 ec 04             	sub    $0x4,%esp
f010312e:	68 cd 6b 10 f0       	push   $0xf0106bcd
f0103133:	68 86 01 00 00       	push   $0x186
f0103138:	68 79 6b 10 f0       	push   $0xf0106b79
f010313d:	e8 fe ce ff ff       	call   f0100040 <_panic>
		if(ph->p_type == ELF_PROG_LOAD)
f0103142:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103145:	75 39                	jne    f0103180 <env_create+0xf7>
		{
		//  Each segment's virtual address can be found in ph->p_va
		//  and its size in memory can be found in ph->p_memsz.
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0103147:	8b 53 08             	mov    0x8(%ebx),%edx
f010314a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010314d:	e8 1e fc ff ff       	call   f0102d70 <region_alloc>
		//  The ph->p_filesz bytes from the ELF binary, starting at
		//  'binary + ph->p_offset', should be copied to virtual address
		//  ph->p_va. 
			//memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0103152:	83 ec 04             	sub    $0x4,%esp
f0103155:	ff 73 10             	pushl  0x10(%ebx)
f0103158:	89 f8                	mov    %edi,%eax
f010315a:	03 43 04             	add    0x4(%ebx),%eax
f010315d:	50                   	push   %eax
f010315e:	ff 73 08             	pushl  0x8(%ebx)
f0103161:	e8 b3 1b 00 00       	call   f0104d19 <memmove>
        //	Any remaining memory bytes should be cleared to zero.
		    memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
f0103166:	8b 43 10             	mov    0x10(%ebx),%eax
f0103169:	83 c4 0c             	add    $0xc,%esp
f010316c:	8b 53 14             	mov    0x14(%ebx),%edx
f010316f:	29 c2                	sub    %eax,%edx
f0103171:	52                   	push   %edx
f0103172:	6a 00                	push   $0x0
f0103174:	03 43 08             	add    0x8(%ebx),%eax
f0103177:	50                   	push   %eax
f0103178:	e8 4f 1b 00 00       	call   f0104ccc <memset>
f010317d:	83 c4 10             	add    $0x10,%esp
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
	eph = ph + elf->e_phnum;
	// 因为后面需要访问刚分配的内存，所以需要将env_pgdir装入cr3，使二级页表能够运作
	lcr3(PADDR(e->env_pgdir));

	for (; ph < eph; ph++)
f0103180:	83 c3 20             	add    $0x20,%ebx
f0103183:	39 de                	cmp    %ebx,%esi
f0103185:	77 9c                	ja     f0103123 <env_create+0x9a>
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
        //	Any remaining memory bytes should be cleared to zero.
		    memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
		}
	}
	e->env_tf.tf_eip = elf->e_entry;
f0103187:	8b 47 18             	mov    0x18(%edi),%eax
f010318a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010318d:	89 47 30             	mov    %eax,0x30(%edi)
	lcr3(PADDR(kern_pgdir));
f0103190:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103195:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010319a:	77 15                	ja     f01031b1 <env_create+0x128>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010319c:	50                   	push   %eax
f010319d:	68 c8 59 10 f0       	push   $0xf01059c8
f01031a2:	68 96 01 00 00       	push   $0x196
f01031a7:	68 79 6b 10 f0       	push   $0xf0106b79
f01031ac:	e8 8f ce ff ff       	call   f0100040 <_panic>
f01031b1:	05 00 00 00 10       	add    $0x10000000,%eax
f01031b6:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *) USTACKTOP-PGSIZE, PGSIZE);
f01031b9:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01031be:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01031c3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031c6:	e8 a5 fb ff ff       	call   f0102d70 <region_alloc>
		panic("env_create: %e", r);
	//if(env_alloc(&e,0) != 0)
	//	panic("env_alloc fail");
	e->env_type = type;
	load_icode(e, binary);
}
f01031cb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031ce:	5b                   	pop    %ebx
f01031cf:	5e                   	pop    %esi
f01031d0:	5f                   	pop    %edi
f01031d1:	5d                   	pop    %ebp
f01031d2:	c3                   	ret    

f01031d3 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01031d3:	55                   	push   %ebp
f01031d4:	89 e5                	mov    %esp,%ebp
f01031d6:	57                   	push   %edi
f01031d7:	56                   	push   %esi
f01031d8:	53                   	push   %ebx
f01031d9:	83 ec 1c             	sub    $0x1c,%esp
f01031dc:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01031df:	e8 0a 21 00 00       	call   f01052ee <cpunum>
f01031e4:	6b c0 74             	imul   $0x74,%eax,%eax
f01031e7:	39 b8 28 b0 22 f0    	cmp    %edi,-0xfdd4fd8(%eax)
f01031ed:	75 29                	jne    f0103218 <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f01031ef:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031f4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031f9:	77 15                	ja     f0103210 <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031fb:	50                   	push   %eax
f01031fc:	68 c8 59 10 f0       	push   $0xf01059c8
f0103201:	68 c2 01 00 00       	push   $0x1c2
f0103206:	68 79 6b 10 f0       	push   $0xf0106b79
f010320b:	e8 30 ce ff ff       	call   f0100040 <_panic>
f0103210:	05 00 00 00 10       	add    $0x10000000,%eax
f0103215:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103218:	8b 5f 48             	mov    0x48(%edi),%ebx
f010321b:	e8 ce 20 00 00       	call   f01052ee <cpunum>
f0103220:	6b c0 74             	imul   $0x74,%eax,%eax
f0103223:	ba 00 00 00 00       	mov    $0x0,%edx
f0103228:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f010322f:	74 11                	je     f0103242 <env_free+0x6f>
f0103231:	e8 b8 20 00 00       	call   f01052ee <cpunum>
f0103236:	6b c0 74             	imul   $0x74,%eax,%eax
f0103239:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010323f:	8b 50 48             	mov    0x48(%eax),%edx
f0103242:	83 ec 04             	sub    $0x4,%esp
f0103245:	53                   	push   %ebx
f0103246:	52                   	push   %edx
f0103247:	68 eb 6b 10 f0       	push   $0xf0106beb
f010324c:	e8 44 04 00 00       	call   f0103695 <cprintf>
f0103251:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103254:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010325b:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010325e:	89 d0                	mov    %edx,%eax
f0103260:	c1 e0 02             	shl    $0x2,%eax
f0103263:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103266:	8b 47 60             	mov    0x60(%edi),%eax
f0103269:	8b 34 90             	mov    (%eax,%edx,4),%esi
f010326c:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103272:	0f 84 a8 00 00 00    	je     f0103320 <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103278:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010327e:	89 f0                	mov    %esi,%eax
f0103280:	c1 e8 0c             	shr    $0xc,%eax
f0103283:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103286:	39 05 88 ae 22 f0    	cmp    %eax,0xf022ae88
f010328c:	77 15                	ja     f01032a3 <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010328e:	56                   	push   %esi
f010328f:	68 a4 59 10 f0       	push   $0xf01059a4
f0103294:	68 d1 01 00 00       	push   $0x1d1
f0103299:	68 79 6b 10 f0       	push   $0xf0106b79
f010329e:	e8 9d cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01032a3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032a6:	c1 e0 16             	shl    $0x16,%eax
f01032a9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032ac:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01032b1:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01032b8:	01 
f01032b9:	74 17                	je     f01032d2 <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01032bb:	83 ec 08             	sub    $0x8,%esp
f01032be:	89 d8                	mov    %ebx,%eax
f01032c0:	c1 e0 0c             	shl    $0xc,%eax
f01032c3:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01032c6:	50                   	push   %eax
f01032c7:	ff 77 60             	pushl  0x60(%edi)
f01032ca:	e8 72 de ff ff       	call   f0101141 <page_remove>
f01032cf:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032d2:	83 c3 01             	add    $0x1,%ebx
f01032d5:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01032db:	75 d4                	jne    f01032b1 <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01032dd:	8b 47 60             	mov    0x60(%edi),%eax
f01032e0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01032e3:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01032ea:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01032ed:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01032f3:	72 14                	jb     f0103309 <env_free+0x136>
		panic("pa2page called with invalid pa");
f01032f5:	83 ec 04             	sub    $0x4,%esp
f01032f8:	68 08 60 10 f0       	push   $0xf0106008
f01032fd:	6a 51                	push   $0x51
f01032ff:	68 4d 68 10 f0       	push   $0xf010684d
f0103304:	e8 37 cd ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f0103309:	83 ec 0c             	sub    $0xc,%esp
f010330c:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0103311:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103314:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0103317:	50                   	push   %eax
f0103318:	e8 5e dc ff ff       	call   f0100f7b <page_decref>
f010331d:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103320:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103324:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103327:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010332c:	0f 85 29 ff ff ff    	jne    f010325b <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103332:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103335:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010333a:	77 15                	ja     f0103351 <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010333c:	50                   	push   %eax
f010333d:	68 c8 59 10 f0       	push   $0xf01059c8
f0103342:	68 df 01 00 00       	push   $0x1df
f0103347:	68 79 6b 10 f0       	push   $0xf0106b79
f010334c:	e8 ef cc ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103351:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103358:	05 00 00 00 10       	add    $0x10000000,%eax
f010335d:	c1 e8 0c             	shr    $0xc,%eax
f0103360:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0103366:	72 14                	jb     f010337c <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f0103368:	83 ec 04             	sub    $0x4,%esp
f010336b:	68 08 60 10 f0       	push   $0xf0106008
f0103370:	6a 51                	push   $0x51
f0103372:	68 4d 68 10 f0       	push   $0xf010684d
f0103377:	e8 c4 cc ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f010337c:	83 ec 0c             	sub    $0xc,%esp
f010337f:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f0103385:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103388:	50                   	push   %eax
f0103389:	e8 ed db ff ff       	call   f0100f7b <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010338e:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103395:	a1 4c a2 22 f0       	mov    0xf022a24c,%eax
f010339a:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010339d:	89 3d 4c a2 22 f0    	mov    %edi,0xf022a24c
}
f01033a3:	83 c4 10             	add    $0x10,%esp
f01033a6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033a9:	5b                   	pop    %ebx
f01033aa:	5e                   	pop    %esi
f01033ab:	5f                   	pop    %edi
f01033ac:	5d                   	pop    %ebp
f01033ad:	c3                   	ret    

f01033ae <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f01033ae:	55                   	push   %ebp
f01033af:	89 e5                	mov    %esp,%ebp
f01033b1:	53                   	push   %ebx
f01033b2:	83 ec 04             	sub    $0x4,%esp
f01033b5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01033b8:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01033bc:	75 19                	jne    f01033d7 <env_destroy+0x29>
f01033be:	e8 2b 1f 00 00       	call   f01052ee <cpunum>
f01033c3:	6b c0 74             	imul   $0x74,%eax,%eax
f01033c6:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f01033cc:	74 09                	je     f01033d7 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01033ce:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01033d5:	eb 33                	jmp    f010340a <env_destroy+0x5c>
	}

	env_free(e);
f01033d7:	83 ec 0c             	sub    $0xc,%esp
f01033da:	53                   	push   %ebx
f01033db:	e8 f3 fd ff ff       	call   f01031d3 <env_free>

	if (curenv == e) {
f01033e0:	e8 09 1f 00 00       	call   f01052ee <cpunum>
f01033e5:	6b c0 74             	imul   $0x74,%eax,%eax
f01033e8:	83 c4 10             	add    $0x10,%esp
f01033eb:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f01033f1:	75 17                	jne    f010340a <env_destroy+0x5c>
		curenv = NULL;
f01033f3:	e8 f6 1e 00 00       	call   f01052ee <cpunum>
f01033f8:	6b c0 74             	imul   $0x74,%eax,%eax
f01033fb:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103402:	00 00 00 
		sched_yield();
f0103405:	e8 0a 0c 00 00       	call   f0104014 <sched_yield>
	}
}
f010340a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010340d:	c9                   	leave  
f010340e:	c3                   	ret    

f010340f <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f010340f:	55                   	push   %ebp
f0103410:	89 e5                	mov    %esp,%ebp
f0103412:	53                   	push   %ebx
f0103413:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103416:	e8 d3 1e 00 00       	call   f01052ee <cpunum>
f010341b:	6b c0 74             	imul   $0x74,%eax,%eax
f010341e:	8b 98 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%ebx
f0103424:	e8 c5 1e 00 00       	call   f01052ee <cpunum>
f0103429:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f010342c:	8b 65 08             	mov    0x8(%ebp),%esp
f010342f:	61                   	popa   
f0103430:	07                   	pop    %es
f0103431:	1f                   	pop    %ds
f0103432:	83 c4 08             	add    $0x8,%esp
f0103435:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103436:	83 ec 04             	sub    $0x4,%esp
f0103439:	68 01 6c 10 f0       	push   $0xf0106c01
f010343e:	68 15 02 00 00       	push   $0x215
f0103443:	68 79 6b 10 f0       	push   $0xf0106b79
f0103448:	e8 f3 cb ff ff       	call   f0100040 <_panic>

f010344d <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010344d:	55                   	push   %ebp
f010344e:	89 e5                	mov    %esp,%ebp
f0103450:	53                   	push   %ebx
f0103451:	83 ec 04             	sub    $0x4,%esp
f0103454:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv && curenv->env_status == ENV_RUNNING)
f0103457:	e8 92 1e 00 00       	call   f01052ee <cpunum>
f010345c:	6b c0 74             	imul   $0x74,%eax,%eax
f010345f:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103466:	74 29                	je     f0103491 <env_run+0x44>
f0103468:	e8 81 1e 00 00       	call   f01052ee <cpunum>
f010346d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103470:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103476:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010347a:	75 15                	jne    f0103491 <env_run+0x44>
		curenv->env_status = ENV_RUNNABLE;
f010347c:	e8 6d 1e 00 00       	call   f01052ee <cpunum>
f0103481:	6b c0 74             	imul   $0x74,%eax,%eax
f0103484:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010348a:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	curenv = e;
f0103491:	e8 58 1e 00 00       	call   f01052ee <cpunum>
f0103496:	6b c0 74             	imul   $0x74,%eax,%eax
f0103499:	89 98 28 b0 22 f0    	mov    %ebx,-0xfdd4fd8(%eax)
	curenv->env_status = ENV_RUNNING;
f010349f:	e8 4a 1e 00 00       	call   f01052ee <cpunum>
f01034a4:	6b c0 74             	imul   $0x74,%eax,%eax
f01034a7:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01034ad:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f01034b4:	e8 35 1e 00 00       	call   f01052ee <cpunum>
f01034b9:	6b c0 74             	imul   $0x74,%eax,%eax
f01034bc:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01034c2:	83 40 58 01          	addl   $0x1,0x58(%eax)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01034c6:	83 ec 0c             	sub    $0xc,%esp
f01034c9:	68 c0 f3 11 f0       	push   $0xf011f3c0
f01034ce:	e8 26 21 00 00       	call   f01055f9 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01034d3:	f3 90                	pause  
	//cprintf("%o \n",(physaddr_t)curenv->env_pgdir);

	//lab4 unlock
	unlock_kernel();
	lcr3(PADDR(curenv->env_pgdir));
f01034d5:	e8 14 1e 00 00       	call   f01052ee <cpunum>
f01034da:	6b c0 74             	imul   $0x74,%eax,%eax
f01034dd:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01034e3:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034e6:	83 c4 10             	add    $0x10,%esp
f01034e9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034ee:	77 15                	ja     f0103505 <env_run+0xb8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034f0:	50                   	push   %eax
f01034f1:	68 c8 59 10 f0       	push   $0xf01059c8
f01034f6:	68 3c 02 00 00       	push   $0x23c
f01034fb:	68 79 6b 10 f0       	push   $0xf0106b79
f0103500:	e8 3b cb ff ff       	call   f0100040 <_panic>
f0103505:	05 00 00 00 10       	add    $0x10000000,%eax
f010350a:	0f 22 d8             	mov    %eax,%cr3

	env_pop_tf(&e->env_tf);
f010350d:	83 ec 0c             	sub    $0xc,%esp
f0103510:	53                   	push   %ebx
f0103511:	e8 f9 fe ff ff       	call   f010340f <env_pop_tf>

f0103516 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103516:	55                   	push   %ebp
f0103517:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103519:	ba 70 00 00 00       	mov    $0x70,%edx
f010351e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103521:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103522:	ba 71 00 00 00       	mov    $0x71,%edx
f0103527:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103528:	0f b6 c0             	movzbl %al,%eax
}
f010352b:	5d                   	pop    %ebp
f010352c:	c3                   	ret    

f010352d <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010352d:	55                   	push   %ebp
f010352e:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103530:	ba 70 00 00 00       	mov    $0x70,%edx
f0103535:	8b 45 08             	mov    0x8(%ebp),%eax
f0103538:	ee                   	out    %al,(%dx)
f0103539:	ba 71 00 00 00       	mov    $0x71,%edx
f010353e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103541:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103542:	5d                   	pop    %ebp
f0103543:	c3                   	ret    

f0103544 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103544:	55                   	push   %ebp
f0103545:	89 e5                	mov    %esp,%ebp
f0103547:	56                   	push   %esi
f0103548:	53                   	push   %ebx
f0103549:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f010354c:	66 a3 a8 f3 11 f0    	mov    %ax,0xf011f3a8
	if (!didinit)
f0103552:	80 3d 50 a2 22 f0 00 	cmpb   $0x0,0xf022a250
f0103559:	74 5a                	je     f01035b5 <irq_setmask_8259A+0x71>
f010355b:	89 c6                	mov    %eax,%esi
f010355d:	ba 21 00 00 00       	mov    $0x21,%edx
f0103562:	ee                   	out    %al,(%dx)
f0103563:	66 c1 e8 08          	shr    $0x8,%ax
f0103567:	ba a1 00 00 00       	mov    $0xa1,%edx
f010356c:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f010356d:	83 ec 0c             	sub    $0xc,%esp
f0103570:	68 0d 6c 10 f0       	push   $0xf0106c0d
f0103575:	e8 1b 01 00 00       	call   f0103695 <cprintf>
f010357a:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f010357d:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103582:	0f b7 f6             	movzwl %si,%esi
f0103585:	f7 d6                	not    %esi
f0103587:	0f a3 de             	bt     %ebx,%esi
f010358a:	73 11                	jae    f010359d <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f010358c:	83 ec 08             	sub    $0x8,%esp
f010358f:	53                   	push   %ebx
f0103590:	68 d3 70 10 f0       	push   $0xf01070d3
f0103595:	e8 fb 00 00 00       	call   f0103695 <cprintf>
f010359a:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f010359d:	83 c3 01             	add    $0x1,%ebx
f01035a0:	83 fb 10             	cmp    $0x10,%ebx
f01035a3:	75 e2                	jne    f0103587 <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f01035a5:	83 ec 0c             	sub    $0xc,%esp
f01035a8:	68 09 5d 10 f0       	push   $0xf0105d09
f01035ad:	e8 e3 00 00 00       	call   f0103695 <cprintf>
f01035b2:	83 c4 10             	add    $0x10,%esp
}
f01035b5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01035b8:	5b                   	pop    %ebx
f01035b9:	5e                   	pop    %esi
f01035ba:	5d                   	pop    %ebp
f01035bb:	c3                   	ret    

f01035bc <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f01035bc:	c6 05 50 a2 22 f0 01 	movb   $0x1,0xf022a250
f01035c3:	ba 21 00 00 00       	mov    $0x21,%edx
f01035c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01035cd:	ee                   	out    %al,(%dx)
f01035ce:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035d3:	ee                   	out    %al,(%dx)
f01035d4:	ba 20 00 00 00       	mov    $0x20,%edx
f01035d9:	b8 11 00 00 00       	mov    $0x11,%eax
f01035de:	ee                   	out    %al,(%dx)
f01035df:	ba 21 00 00 00       	mov    $0x21,%edx
f01035e4:	b8 20 00 00 00       	mov    $0x20,%eax
f01035e9:	ee                   	out    %al,(%dx)
f01035ea:	b8 04 00 00 00       	mov    $0x4,%eax
f01035ef:	ee                   	out    %al,(%dx)
f01035f0:	b8 03 00 00 00       	mov    $0x3,%eax
f01035f5:	ee                   	out    %al,(%dx)
f01035f6:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035fb:	b8 11 00 00 00       	mov    $0x11,%eax
f0103600:	ee                   	out    %al,(%dx)
f0103601:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103606:	b8 28 00 00 00       	mov    $0x28,%eax
f010360b:	ee                   	out    %al,(%dx)
f010360c:	b8 02 00 00 00       	mov    $0x2,%eax
f0103611:	ee                   	out    %al,(%dx)
f0103612:	b8 01 00 00 00       	mov    $0x1,%eax
f0103617:	ee                   	out    %al,(%dx)
f0103618:	ba 20 00 00 00       	mov    $0x20,%edx
f010361d:	b8 68 00 00 00       	mov    $0x68,%eax
f0103622:	ee                   	out    %al,(%dx)
f0103623:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103628:	ee                   	out    %al,(%dx)
f0103629:	ba a0 00 00 00       	mov    $0xa0,%edx
f010362e:	b8 68 00 00 00       	mov    $0x68,%eax
f0103633:	ee                   	out    %al,(%dx)
f0103634:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103639:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f010363a:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f0103641:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103645:	74 13                	je     f010365a <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103647:	55                   	push   %ebp
f0103648:	89 e5                	mov    %esp,%ebp
f010364a:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f010364d:	0f b7 c0             	movzwl %ax,%eax
f0103650:	50                   	push   %eax
f0103651:	e8 ee fe ff ff       	call   f0103544 <irq_setmask_8259A>
f0103656:	83 c4 10             	add    $0x10,%esp
}
f0103659:	c9                   	leave  
f010365a:	f3 c3                	repz ret 

f010365c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010365c:	55                   	push   %ebp
f010365d:	89 e5                	mov    %esp,%ebp
f010365f:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103662:	ff 75 08             	pushl  0x8(%ebp)
f0103665:	e8 0a d1 ff ff       	call   f0100774 <cputchar>
	*cnt++;
}
f010366a:	83 c4 10             	add    $0x10,%esp
f010366d:	c9                   	leave  
f010366e:	c3                   	ret    

f010366f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010366f:	55                   	push   %ebp
f0103670:	89 e5                	mov    %esp,%ebp
f0103672:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103675:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010367c:	ff 75 0c             	pushl  0xc(%ebp)
f010367f:	ff 75 08             	pushl  0x8(%ebp)
f0103682:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103685:	50                   	push   %eax
f0103686:	68 5c 36 10 f0       	push   $0xf010365c
f010368b:	e8 d0 0f 00 00       	call   f0104660 <vprintfmt>
	return cnt;
}
f0103690:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103693:	c9                   	leave  
f0103694:	c3                   	ret    

f0103695 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103695:	55                   	push   %ebp
f0103696:	89 e5                	mov    %esp,%ebp
f0103698:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010369b:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010369e:	50                   	push   %eax
f010369f:	ff 75 08             	pushl  0x8(%ebp)
f01036a2:	e8 c8 ff ff ff       	call   f010366f <vcprintf>
	va_end(ap);

	return cnt;
}
f01036a7:	c9                   	leave  
f01036a8:	c3                   	ret    

f01036a9 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01036a9:	55                   	push   %ebp
f01036aa:	89 e5                	mov    %esp,%ebp
f01036ac:	57                   	push   %edi
f01036ad:	56                   	push   %esi
f01036ae:	53                   	push   %ebx
f01036af:	83 ec 0c             	sub    $0xc,%esp
	// when we trap to the kernel.
	// struct Taskstate* this_ts = &thiscpu->cpu_ts;
    // this_ts->ts_esp0 = KSTACKTOP - thiscpu->cpu_id*(KSTKSIZE + KSTKGAP);
    // this_ts->ts_ss0 = GD_KD;
    // this_ts->ts_iomb = sizeof(struct Taskstate);
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - thiscpu->cpu_id*(KSTKSIZE + KSTKGAP);
f01036b2:	e8 37 1c 00 00       	call   f01052ee <cpunum>
f01036b7:	89 c3                	mov    %eax,%ebx
f01036b9:	e8 30 1c 00 00       	call   f01052ee <cpunum>
f01036be:	6b d3 74             	imul   $0x74,%ebx,%edx
f01036c1:	6b c0 74             	imul   $0x74,%eax,%eax
f01036c4:	0f b6 88 20 b0 22 f0 	movzbl -0xfdd4fe0(%eax),%ecx
f01036cb:	c1 e1 10             	shl    $0x10,%ecx
f01036ce:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
f01036d3:	29 c8                	sub    %ecx,%eax
f01036d5:	89 82 30 b0 22 f0    	mov    %eax,-0xfdd4fd0(%edx)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f01036db:	e8 0e 1c 00 00       	call   f01052ee <cpunum>
f01036e0:	6b c0 74             	imul   $0x74,%eax,%eax
f01036e3:	66 c7 80 34 b0 22 f0 	movw   $0x10,-0xfdd4fcc(%eax)
f01036ea:	10 00 
	//ts.ts_esp0 = KSTACKTOP;
	//ts.ts_ss0 = GD_KD;

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + cpunum()] = SEG16(STS_T32A, (uint32_t) (&(thiscpu->cpu_ts)),
f01036ec:	e8 fd 1b 00 00       	call   f01052ee <cpunum>
f01036f1:	8d 58 05             	lea    0x5(%eax),%ebx
f01036f4:	e8 f5 1b 00 00       	call   f01052ee <cpunum>
f01036f9:	89 c7                	mov    %eax,%edi
f01036fb:	e8 ee 1b 00 00       	call   f01052ee <cpunum>
f0103700:	89 c6                	mov    %eax,%esi
f0103702:	e8 e7 1b 00 00       	call   f01052ee <cpunum>
f0103707:	66 c7 04 dd 40 f3 11 	movw   $0x67,-0xfee0cc0(,%ebx,8)
f010370e:	f0 67 00 
f0103711:	6b ff 74             	imul   $0x74,%edi,%edi
f0103714:	81 c7 2c b0 22 f0    	add    $0xf022b02c,%edi
f010371a:	66 89 3c dd 42 f3 11 	mov    %di,-0xfee0cbe(,%ebx,8)
f0103721:	f0 
f0103722:	6b d6 74             	imul   $0x74,%esi,%edx
f0103725:	81 c2 2c b0 22 f0    	add    $0xf022b02c,%edx
f010372b:	c1 ea 10             	shr    $0x10,%edx
f010372e:	88 14 dd 44 f3 11 f0 	mov    %dl,-0xfee0cbc(,%ebx,8)
f0103735:	c6 04 dd 45 f3 11 f0 	movb   $0x99,-0xfee0cbb(,%ebx,8)
f010373c:	99 
f010373d:	c6 04 dd 46 f3 11 f0 	movb   $0x40,-0xfee0cba(,%ebx,8)
f0103744:	40 
f0103745:	6b c0 74             	imul   $0x74,%eax,%eax
f0103748:	05 2c b0 22 f0       	add    $0xf022b02c,%eax
f010374d:	c1 e8 18             	shr    $0x18,%eax
f0103750:	88 04 dd 47 f3 11 f0 	mov    %al,-0xfee0cb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + cpunum()].sd_s = 0;
f0103757:	e8 92 1b 00 00       	call   f01052ee <cpunum>
f010375c:	80 24 c5 6d f3 11 f0 	andb   $0xef,-0xfee0c93(,%eax,8)
f0103763:	ef 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (cpunum() << 3));
f0103764:	e8 85 1b 00 00       	call   f01052ee <cpunum>
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0103769:	8d 04 c5 28 00 00 00 	lea    0x28(,%eax,8),%eax
f0103770:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0103773:	b8 ac f3 11 f0       	mov    $0xf011f3ac,%eax
f0103778:	0f 01 18             	lidtl  (%eax)

	// Load the IDT
	lidt(&idt_pd);
}
f010377b:	83 c4 0c             	add    $0xc,%esp
f010377e:	5b                   	pop    %ebx
f010377f:	5e                   	pop    %esi
f0103780:	5f                   	pop    %edi
f0103781:	5d                   	pop    %ebp
f0103782:	c3                   	ret    

f0103783 <trap_init>:
}


void
trap_init(void)
{
f0103783:	55                   	push   %ebp
f0103784:	89 e5                	mov    %esp,%ebp
f0103786:	83 ec 08             	sub    $0x8,%esp
	
	void floating_point_error();

	void system_call();

	SETGATE(idt[T_DIVIDE], 1, GD_KT, divide_error, 0);
f0103789:	b8 da 3e 10 f0       	mov    $0xf0103eda,%eax
f010378e:	66 a3 60 a2 22 f0    	mov    %ax,0xf022a260
f0103794:	66 c7 05 62 a2 22 f0 	movw   $0x8,0xf022a262
f010379b:	08 00 
f010379d:	c6 05 64 a2 22 f0 00 	movb   $0x0,0xf022a264
f01037a4:	c6 05 65 a2 22 f0 8f 	movb   $0x8f,0xf022a265
f01037ab:	c1 e8 10             	shr    $0x10,%eax
f01037ae:	66 a3 66 a2 22 f0    	mov    %ax,0xf022a266
	SETGATE(idt[T_DEBUG], 1, GD_KT, debug_exception, 0);
f01037b4:	b8 e0 3e 10 f0       	mov    $0xf0103ee0,%eax
f01037b9:	66 a3 68 a2 22 f0    	mov    %ax,0xf022a268
f01037bf:	66 c7 05 6a a2 22 f0 	movw   $0x8,0xf022a26a
f01037c6:	08 00 
f01037c8:	c6 05 6c a2 22 f0 00 	movb   $0x0,0xf022a26c
f01037cf:	c6 05 6d a2 22 f0 8f 	movb   $0x8f,0xf022a26d
f01037d6:	c1 e8 10             	shr    $0x10,%eax
f01037d9:	66 a3 6e a2 22 f0    	mov    %ax,0xf022a26e
	SETGATE(idt[T_NMI], 1, GD_KT, non_maskable_interrupt, 0);
f01037df:	b8 e6 3e 10 f0       	mov    $0xf0103ee6,%eax
f01037e4:	66 a3 70 a2 22 f0    	mov    %ax,0xf022a270
f01037ea:	66 c7 05 72 a2 22 f0 	movw   $0x8,0xf022a272
f01037f1:	08 00 
f01037f3:	c6 05 74 a2 22 f0 00 	movb   $0x0,0xf022a274
f01037fa:	c6 05 75 a2 22 f0 8f 	movb   $0x8f,0xf022a275
f0103801:	c1 e8 10             	shr    $0x10,%eax
f0103804:	66 a3 76 a2 22 f0    	mov    %ax,0xf022a276
	SETGATE(idt[T_BRKPT], 1, GD_KT, break_point, 3);//!
f010380a:	b8 ec 3e 10 f0       	mov    $0xf0103eec,%eax
f010380f:	66 a3 78 a2 22 f0    	mov    %ax,0xf022a278
f0103815:	66 c7 05 7a a2 22 f0 	movw   $0x8,0xf022a27a
f010381c:	08 00 
f010381e:	c6 05 7c a2 22 f0 00 	movb   $0x0,0xf022a27c
f0103825:	c6 05 7d a2 22 f0 ef 	movb   $0xef,0xf022a27d
f010382c:	c1 e8 10             	shr    $0x10,%eax
f010382f:	66 a3 7e a2 22 f0    	mov    %ax,0xf022a27e
	SETGATE(idt[T_OFLOW], 1, GD_KT, overflow, 0);
f0103835:	b8 f2 3e 10 f0       	mov    $0xf0103ef2,%eax
f010383a:	66 a3 80 a2 22 f0    	mov    %ax,0xf022a280
f0103840:	66 c7 05 82 a2 22 f0 	movw   $0x8,0xf022a282
f0103847:	08 00 
f0103849:	c6 05 84 a2 22 f0 00 	movb   $0x0,0xf022a284
f0103850:	c6 05 85 a2 22 f0 8f 	movb   $0x8f,0xf022a285
f0103857:	c1 e8 10             	shr    $0x10,%eax
f010385a:	66 a3 86 a2 22 f0    	mov    %ax,0xf022a286
	SETGATE(idt[T_BOUND], 1, GD_KT, bounds_check, 0);
f0103860:	b8 f8 3e 10 f0       	mov    $0xf0103ef8,%eax
f0103865:	66 a3 88 a2 22 f0    	mov    %ax,0xf022a288
f010386b:	66 c7 05 8a a2 22 f0 	movw   $0x8,0xf022a28a
f0103872:	08 00 
f0103874:	c6 05 8c a2 22 f0 00 	movb   $0x0,0xf022a28c
f010387b:	c6 05 8d a2 22 f0 8f 	movb   $0x8f,0xf022a28d
f0103882:	c1 e8 10             	shr    $0x10,%eax
f0103885:	66 a3 8e a2 22 f0    	mov    %ax,0xf022a28e
	SETGATE(idt[T_ILLOP], 1, GD_KT, illegal_opcode, 0);
f010388b:	b8 fe 3e 10 f0       	mov    $0xf0103efe,%eax
f0103890:	66 a3 90 a2 22 f0    	mov    %ax,0xf022a290
f0103896:	66 c7 05 92 a2 22 f0 	movw   $0x8,0xf022a292
f010389d:	08 00 
f010389f:	c6 05 94 a2 22 f0 00 	movb   $0x0,0xf022a294
f01038a6:	c6 05 95 a2 22 f0 8f 	movb   $0x8f,0xf022a295
f01038ad:	c1 e8 10             	shr    $0x10,%eax
f01038b0:	66 a3 96 a2 22 f0    	mov    %ax,0xf022a296
	SETGATE(idt[T_DEVICE], 1, GD_KT, device_not_available, 0);
f01038b6:	b8 04 3f 10 f0       	mov    $0xf0103f04,%eax
f01038bb:	66 a3 98 a2 22 f0    	mov    %ax,0xf022a298
f01038c1:	66 c7 05 9a a2 22 f0 	movw   $0x8,0xf022a29a
f01038c8:	08 00 
f01038ca:	c6 05 9c a2 22 f0 00 	movb   $0x0,0xf022a29c
f01038d1:	c6 05 9d a2 22 f0 8f 	movb   $0x8f,0xf022a29d
f01038d8:	c1 e8 10             	shr    $0x10,%eax
f01038db:	66 a3 9e a2 22 f0    	mov    %ax,0xf022a29e
	SETGATE(idt[T_DBLFLT], 1, GD_KT, double_fault, 0);
f01038e1:	b8 0a 3f 10 f0       	mov    $0xf0103f0a,%eax
f01038e6:	66 a3 a0 a2 22 f0    	mov    %ax,0xf022a2a0
f01038ec:	66 c7 05 a2 a2 22 f0 	movw   $0x8,0xf022a2a2
f01038f3:	08 00 
f01038f5:	c6 05 a4 a2 22 f0 00 	movb   $0x0,0xf022a2a4
f01038fc:	c6 05 a5 a2 22 f0 8f 	movb   $0x8f,0xf022a2a5
f0103903:	c1 e8 10             	shr    $0x10,%eax
f0103906:	66 a3 a6 a2 22 f0    	mov    %ax,0xf022a2a6

	SETGATE(idt[T_TSS], 1, GD_KT, invalid_task_switch_segment, 0);
f010390c:	b8 0e 3f 10 f0       	mov    $0xf0103f0e,%eax
f0103911:	66 a3 b0 a2 22 f0    	mov    %ax,0xf022a2b0
f0103917:	66 c7 05 b2 a2 22 f0 	movw   $0x8,0xf022a2b2
f010391e:	08 00 
f0103920:	c6 05 b4 a2 22 f0 00 	movb   $0x0,0xf022a2b4
f0103927:	c6 05 b5 a2 22 f0 8f 	movb   $0x8f,0xf022a2b5
f010392e:	c1 e8 10             	shr    $0x10,%eax
f0103931:	66 a3 b6 a2 22 f0    	mov    %ax,0xf022a2b6
	SETGATE(idt[T_SEGNP], 1, GD_KT, segment_not_present, 0);
f0103937:	b8 12 3f 10 f0       	mov    $0xf0103f12,%eax
f010393c:	66 a3 b8 a2 22 f0    	mov    %ax,0xf022a2b8
f0103942:	66 c7 05 ba a2 22 f0 	movw   $0x8,0xf022a2ba
f0103949:	08 00 
f010394b:	c6 05 bc a2 22 f0 00 	movb   $0x0,0xf022a2bc
f0103952:	c6 05 bd a2 22 f0 8f 	movb   $0x8f,0xf022a2bd
f0103959:	c1 e8 10             	shr    $0x10,%eax
f010395c:	66 a3 be a2 22 f0    	mov    %ax,0xf022a2be
	SETGATE(idt[T_STACK], 1, GD_KT, stack_exception, 0);
f0103962:	b8 16 3f 10 f0       	mov    $0xf0103f16,%eax
f0103967:	66 a3 c0 a2 22 f0    	mov    %ax,0xf022a2c0
f010396d:	66 c7 05 c2 a2 22 f0 	movw   $0x8,0xf022a2c2
f0103974:	08 00 
f0103976:	c6 05 c4 a2 22 f0 00 	movb   $0x0,0xf022a2c4
f010397d:	c6 05 c5 a2 22 f0 8f 	movb   $0x8f,0xf022a2c5
f0103984:	c1 e8 10             	shr    $0x10,%eax
f0103987:	66 a3 c6 a2 22 f0    	mov    %ax,0xf022a2c6
	SETGATE(idt[T_GPFLT], 1, GD_KT, general_protection_fault, 0);
f010398d:	b8 1a 3f 10 f0       	mov    $0xf0103f1a,%eax
f0103992:	66 a3 c8 a2 22 f0    	mov    %ax,0xf022a2c8
f0103998:	66 c7 05 ca a2 22 f0 	movw   $0x8,0xf022a2ca
f010399f:	08 00 
f01039a1:	c6 05 cc a2 22 f0 00 	movb   $0x0,0xf022a2cc
f01039a8:	c6 05 cd a2 22 f0 8f 	movb   $0x8f,0xf022a2cd
f01039af:	c1 e8 10             	shr    $0x10,%eax
f01039b2:	66 a3 ce a2 22 f0    	mov    %ax,0xf022a2ce
	SETGATE(idt[T_PGFLT], 1, GD_KT, page_fault, 0);
f01039b8:	b8 1e 3f 10 f0       	mov    $0xf0103f1e,%eax
f01039bd:	66 a3 d0 a2 22 f0    	mov    %ax,0xf022a2d0
f01039c3:	66 c7 05 d2 a2 22 f0 	movw   $0x8,0xf022a2d2
f01039ca:	08 00 
f01039cc:	c6 05 d4 a2 22 f0 00 	movb   $0x0,0xf022a2d4
f01039d3:	c6 05 d5 a2 22 f0 8f 	movb   $0x8f,0xf022a2d5
f01039da:	c1 e8 10             	shr    $0x10,%eax
f01039dd:	66 a3 d6 a2 22 f0    	mov    %ax,0xf022a2d6

	SETGATE(idt[T_FPERR], 1, GD_KT, floating_point_error, 0);
f01039e3:	b8 22 3f 10 f0       	mov    $0xf0103f22,%eax
f01039e8:	66 a3 e0 a2 22 f0    	mov    %ax,0xf022a2e0
f01039ee:	66 c7 05 e2 a2 22 f0 	movw   $0x8,0xf022a2e2
f01039f5:	08 00 
f01039f7:	c6 05 e4 a2 22 f0 00 	movb   $0x0,0xf022a2e4
f01039fe:	c6 05 e5 a2 22 f0 8f 	movb   $0x8f,0xf022a2e5
f0103a05:	c1 e8 10             	shr    $0x10,%eax
f0103a08:	66 a3 e6 a2 22 f0    	mov    %ax,0xf022a2e6

	SETGATE(idt[T_SYSCALL], 0, GD_KT, system_call, 3);
f0103a0e:	b8 28 3f 10 f0       	mov    $0xf0103f28,%eax
f0103a13:	66 a3 e0 a3 22 f0    	mov    %ax,0xf022a3e0
f0103a19:	66 c7 05 e2 a3 22 f0 	movw   $0x8,0xf022a3e2
f0103a20:	08 00 
f0103a22:	c6 05 e4 a3 22 f0 00 	movb   $0x0,0xf022a3e4
f0103a29:	c6 05 e5 a3 22 f0 ee 	movb   $0xee,0xf022a3e5
f0103a30:	c1 e8 10             	shr    $0x10,%eax
f0103a33:	66 a3 e6 a3 22 f0    	mov    %ax,0xf022a3e6

	// Per-CPU setup 
	trap_init_percpu();
f0103a39:	e8 6b fc ff ff       	call   f01036a9 <trap_init_percpu>
}
f0103a3e:	c9                   	leave  
f0103a3f:	c3                   	ret    

f0103a40 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103a40:	55                   	push   %ebp
f0103a41:	89 e5                	mov    %esp,%ebp
f0103a43:	53                   	push   %ebx
f0103a44:	83 ec 0c             	sub    $0xc,%esp
f0103a47:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103a4a:	ff 33                	pushl  (%ebx)
f0103a4c:	68 21 6c 10 f0       	push   $0xf0106c21
f0103a51:	e8 3f fc ff ff       	call   f0103695 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103a56:	83 c4 08             	add    $0x8,%esp
f0103a59:	ff 73 04             	pushl  0x4(%ebx)
f0103a5c:	68 30 6c 10 f0       	push   $0xf0106c30
f0103a61:	e8 2f fc ff ff       	call   f0103695 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103a66:	83 c4 08             	add    $0x8,%esp
f0103a69:	ff 73 08             	pushl  0x8(%ebx)
f0103a6c:	68 3f 6c 10 f0       	push   $0xf0106c3f
f0103a71:	e8 1f fc ff ff       	call   f0103695 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103a76:	83 c4 08             	add    $0x8,%esp
f0103a79:	ff 73 0c             	pushl  0xc(%ebx)
f0103a7c:	68 4e 6c 10 f0       	push   $0xf0106c4e
f0103a81:	e8 0f fc ff ff       	call   f0103695 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103a86:	83 c4 08             	add    $0x8,%esp
f0103a89:	ff 73 10             	pushl  0x10(%ebx)
f0103a8c:	68 5d 6c 10 f0       	push   $0xf0106c5d
f0103a91:	e8 ff fb ff ff       	call   f0103695 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103a96:	83 c4 08             	add    $0x8,%esp
f0103a99:	ff 73 14             	pushl  0x14(%ebx)
f0103a9c:	68 6c 6c 10 f0       	push   $0xf0106c6c
f0103aa1:	e8 ef fb ff ff       	call   f0103695 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103aa6:	83 c4 08             	add    $0x8,%esp
f0103aa9:	ff 73 18             	pushl  0x18(%ebx)
f0103aac:	68 7b 6c 10 f0       	push   $0xf0106c7b
f0103ab1:	e8 df fb ff ff       	call   f0103695 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103ab6:	83 c4 08             	add    $0x8,%esp
f0103ab9:	ff 73 1c             	pushl  0x1c(%ebx)
f0103abc:	68 8a 6c 10 f0       	push   $0xf0106c8a
f0103ac1:	e8 cf fb ff ff       	call   f0103695 <cprintf>
}
f0103ac6:	83 c4 10             	add    $0x10,%esp
f0103ac9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103acc:	c9                   	leave  
f0103acd:	c3                   	ret    

f0103ace <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103ace:	55                   	push   %ebp
f0103acf:	89 e5                	mov    %esp,%ebp
f0103ad1:	56                   	push   %esi
f0103ad2:	53                   	push   %ebx
f0103ad3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103ad6:	e8 13 18 00 00       	call   f01052ee <cpunum>
f0103adb:	83 ec 04             	sub    $0x4,%esp
f0103ade:	50                   	push   %eax
f0103adf:	53                   	push   %ebx
f0103ae0:	68 ee 6c 10 f0       	push   $0xf0106cee
f0103ae5:	e8 ab fb ff ff       	call   f0103695 <cprintf>
	print_regs(&tf->tf_regs);
f0103aea:	89 1c 24             	mov    %ebx,(%esp)
f0103aed:	e8 4e ff ff ff       	call   f0103a40 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103af2:	83 c4 08             	add    $0x8,%esp
f0103af5:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103af9:	50                   	push   %eax
f0103afa:	68 0c 6d 10 f0       	push   $0xf0106d0c
f0103aff:	e8 91 fb ff ff       	call   f0103695 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103b04:	83 c4 08             	add    $0x8,%esp
f0103b07:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103b0b:	50                   	push   %eax
f0103b0c:	68 1f 6d 10 f0       	push   $0xf0106d1f
f0103b11:	e8 7f fb ff ff       	call   f0103695 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b16:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103b19:	83 c4 10             	add    $0x10,%esp
f0103b1c:	83 f8 13             	cmp    $0x13,%eax
f0103b1f:	77 09                	ja     f0103b2a <print_trapframe+0x5c>
		return excnames[trapno];
f0103b21:	8b 14 85 c0 6f 10 f0 	mov    -0xfef9040(,%eax,4),%edx
f0103b28:	eb 1f                	jmp    f0103b49 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103b2a:	83 f8 30             	cmp    $0x30,%eax
f0103b2d:	74 15                	je     f0103b44 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103b2f:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103b32:	83 fa 10             	cmp    $0x10,%edx
f0103b35:	b9 b8 6c 10 f0       	mov    $0xf0106cb8,%ecx
f0103b3a:	ba a5 6c 10 f0       	mov    $0xf0106ca5,%edx
f0103b3f:	0f 43 d1             	cmovae %ecx,%edx
f0103b42:	eb 05                	jmp    f0103b49 <print_trapframe+0x7b>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103b44:	ba 99 6c 10 f0       	mov    $0xf0106c99,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b49:	83 ec 04             	sub    $0x4,%esp
f0103b4c:	52                   	push   %edx
f0103b4d:	50                   	push   %eax
f0103b4e:	68 32 6d 10 f0       	push   $0xf0106d32
f0103b53:	e8 3d fb ff ff       	call   f0103695 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103b58:	83 c4 10             	add    $0x10,%esp
f0103b5b:	3b 1d 60 aa 22 f0    	cmp    0xf022aa60,%ebx
f0103b61:	75 1a                	jne    f0103b7d <print_trapframe+0xaf>
f0103b63:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b67:	75 14                	jne    f0103b7d <print_trapframe+0xaf>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103b69:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103b6c:	83 ec 08             	sub    $0x8,%esp
f0103b6f:	50                   	push   %eax
f0103b70:	68 44 6d 10 f0       	push   $0xf0106d44
f0103b75:	e8 1b fb ff ff       	call   f0103695 <cprintf>
f0103b7a:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103b7d:	83 ec 08             	sub    $0x8,%esp
f0103b80:	ff 73 2c             	pushl  0x2c(%ebx)
f0103b83:	68 53 6d 10 f0       	push   $0xf0106d53
f0103b88:	e8 08 fb ff ff       	call   f0103695 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103b8d:	83 c4 10             	add    $0x10,%esp
f0103b90:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b94:	75 49                	jne    f0103bdf <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103b96:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103b99:	89 c2                	mov    %eax,%edx
f0103b9b:	83 e2 01             	and    $0x1,%edx
f0103b9e:	ba d2 6c 10 f0       	mov    $0xf0106cd2,%edx
f0103ba3:	b9 c7 6c 10 f0       	mov    $0xf0106cc7,%ecx
f0103ba8:	0f 44 ca             	cmove  %edx,%ecx
f0103bab:	89 c2                	mov    %eax,%edx
f0103bad:	83 e2 02             	and    $0x2,%edx
f0103bb0:	ba e4 6c 10 f0       	mov    $0xf0106ce4,%edx
f0103bb5:	be de 6c 10 f0       	mov    $0xf0106cde,%esi
f0103bba:	0f 45 d6             	cmovne %esi,%edx
f0103bbd:	83 e0 04             	and    $0x4,%eax
f0103bc0:	be 1e 6e 10 f0       	mov    $0xf0106e1e,%esi
f0103bc5:	b8 e9 6c 10 f0       	mov    $0xf0106ce9,%eax
f0103bca:	0f 44 c6             	cmove  %esi,%eax
f0103bcd:	51                   	push   %ecx
f0103bce:	52                   	push   %edx
f0103bcf:	50                   	push   %eax
f0103bd0:	68 61 6d 10 f0       	push   $0xf0106d61
f0103bd5:	e8 bb fa ff ff       	call   f0103695 <cprintf>
f0103bda:	83 c4 10             	add    $0x10,%esp
f0103bdd:	eb 10                	jmp    f0103bef <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103bdf:	83 ec 0c             	sub    $0xc,%esp
f0103be2:	68 09 5d 10 f0       	push   $0xf0105d09
f0103be7:	e8 a9 fa ff ff       	call   f0103695 <cprintf>
f0103bec:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103bef:	83 ec 08             	sub    $0x8,%esp
f0103bf2:	ff 73 30             	pushl  0x30(%ebx)
f0103bf5:	68 70 6d 10 f0       	push   $0xf0106d70
f0103bfa:	e8 96 fa ff ff       	call   f0103695 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103bff:	83 c4 08             	add    $0x8,%esp
f0103c02:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103c06:	50                   	push   %eax
f0103c07:	68 7f 6d 10 f0       	push   $0xf0106d7f
f0103c0c:	e8 84 fa ff ff       	call   f0103695 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103c11:	83 c4 08             	add    $0x8,%esp
f0103c14:	ff 73 38             	pushl  0x38(%ebx)
f0103c17:	68 92 6d 10 f0       	push   $0xf0106d92
f0103c1c:	e8 74 fa ff ff       	call   f0103695 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103c21:	83 c4 10             	add    $0x10,%esp
f0103c24:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c28:	74 25                	je     f0103c4f <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103c2a:	83 ec 08             	sub    $0x8,%esp
f0103c2d:	ff 73 3c             	pushl  0x3c(%ebx)
f0103c30:	68 a1 6d 10 f0       	push   $0xf0106da1
f0103c35:	e8 5b fa ff ff       	call   f0103695 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103c3a:	83 c4 08             	add    $0x8,%esp
f0103c3d:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103c41:	50                   	push   %eax
f0103c42:	68 b0 6d 10 f0       	push   $0xf0106db0
f0103c47:	e8 49 fa ff ff       	call   f0103695 <cprintf>
f0103c4c:	83 c4 10             	add    $0x10,%esp
	}
}
f0103c4f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103c52:	5b                   	pop    %ebx
f0103c53:	5e                   	pop    %esi
f0103c54:	5d                   	pop    %ebp
f0103c55:	c3                   	ret    

f0103c56 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103c56:	55                   	push   %ebp
f0103c57:	89 e5                	mov    %esp,%ebp
f0103c59:	57                   	push   %edi
f0103c5a:	56                   	push   %esi
f0103c5b:	53                   	push   %ebx
f0103c5c:	83 ec 0c             	sub    $0xc,%esp
f0103c5f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103c62:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs & 3) == 0) //缺页中断发生在内核中
f0103c65:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c69:	75 17                	jne    f0103c82 <page_fault_handler+0x2c>
    	panic("page fault happen in kernel mode!\n");
f0103c6b:	83 ec 04             	sub    $0x4,%esp
f0103c6e:	68 68 6f 10 f0       	push   $0xf0106f68
f0103c73:	68 56 01 00 00       	push   $0x156
f0103c78:	68 c3 6d 10 f0       	push   $0xf0106dc3
f0103c7d:	e8 be c3 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c82:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103c85:	e8 64 16 00 00       	call   f01052ee <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c8a:	57                   	push   %edi
f0103c8b:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103c8c:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c8f:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103c95:	ff 70 48             	pushl  0x48(%eax)
f0103c98:	68 8c 6f 10 f0       	push   $0xf0106f8c
f0103c9d:	e8 f3 f9 ff ff       	call   f0103695 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103ca2:	89 1c 24             	mov    %ebx,(%esp)
f0103ca5:	e8 24 fe ff ff       	call   f0103ace <print_trapframe>
	env_destroy(curenv);
f0103caa:	e8 3f 16 00 00       	call   f01052ee <cpunum>
f0103caf:	83 c4 04             	add    $0x4,%esp
f0103cb2:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cb5:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103cbb:	e8 ee f6 ff ff       	call   f01033ae <env_destroy>
}
f0103cc0:	83 c4 10             	add    $0x10,%esp
f0103cc3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103cc6:	5b                   	pop    %ebx
f0103cc7:	5e                   	pop    %esi
f0103cc8:	5f                   	pop    %edi
f0103cc9:	5d                   	pop    %ebp
f0103cca:	c3                   	ret    

f0103ccb <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103ccb:	55                   	push   %ebp
f0103ccc:	89 e5                	mov    %esp,%ebp
f0103cce:	57                   	push   %edi
f0103ccf:	56                   	push   %esi
f0103cd0:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103cd3:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103cd4:	83 3d 80 ae 22 f0 00 	cmpl   $0x0,0xf022ae80
f0103cdb:	74 01                	je     f0103cde <trap+0x13>
		asm volatile("hlt");
f0103cdd:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103cde:	e8 0b 16 00 00       	call   f01052ee <cpunum>
f0103ce3:	6b d0 74             	imul   $0x74,%eax,%edx
f0103ce6:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103cec:	b8 01 00 00 00       	mov    $0x1,%eax
f0103cf1:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103cf5:	83 f8 02             	cmp    $0x2,%eax
f0103cf8:	75 10                	jne    f0103d0a <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103cfa:	83 ec 0c             	sub    $0xc,%esp
f0103cfd:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103d02:	e8 55 18 00 00       	call   f010555c <spin_lock>
f0103d07:	83 c4 10             	add    $0x10,%esp

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103d0a:	9c                   	pushf  
f0103d0b:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d0c:	f6 c4 02             	test   $0x2,%ah
f0103d0f:	74 19                	je     f0103d2a <trap+0x5f>
f0103d11:	68 cf 6d 10 f0       	push   $0xf0106dcf
f0103d16:	68 67 68 10 f0       	push   $0xf0106867
f0103d1b:	68 20 01 00 00       	push   $0x120
f0103d20:	68 c3 6d 10 f0       	push   $0xf0106dc3
f0103d25:	e8 16 c3 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103d2a:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d2e:	83 e0 03             	and    $0x3,%eax
f0103d31:	66 83 f8 03          	cmp    $0x3,%ax
f0103d35:	0f 85 a0 00 00 00    	jne    f0103ddb <trap+0x110>
f0103d3b:	83 ec 0c             	sub    $0xc,%esp
f0103d3e:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103d43:	e8 14 18 00 00       	call   f010555c <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f0103d48:	e8 a1 15 00 00       	call   f01052ee <cpunum>
f0103d4d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d50:	83 c4 10             	add    $0x10,%esp
f0103d53:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103d5a:	75 19                	jne    f0103d75 <trap+0xaa>
f0103d5c:	68 e8 6d 10 f0       	push   $0xf0106de8
f0103d61:	68 67 68 10 f0       	push   $0xf0106867
f0103d66:	68 28 01 00 00       	push   $0x128
f0103d6b:	68 c3 6d 10 f0       	push   $0xf0106dc3
f0103d70:	e8 cb c2 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103d75:	e8 74 15 00 00       	call   f01052ee <cpunum>
f0103d7a:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d7d:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103d83:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103d87:	75 2d                	jne    f0103db6 <trap+0xeb>
			env_free(curenv);
f0103d89:	e8 60 15 00 00       	call   f01052ee <cpunum>
f0103d8e:	83 ec 0c             	sub    $0xc,%esp
f0103d91:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d94:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103d9a:	e8 34 f4 ff ff       	call   f01031d3 <env_free>
			curenv = NULL;
f0103d9f:	e8 4a 15 00 00       	call   f01052ee <cpunum>
f0103da4:	6b c0 74             	imul   $0x74,%eax,%eax
f0103da7:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103dae:	00 00 00 
			sched_yield();
f0103db1:	e8 5e 02 00 00       	call   f0104014 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103db6:	e8 33 15 00 00       	call   f01052ee <cpunum>
f0103dbb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dbe:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103dc4:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103dc9:	89 c7                	mov    %eax,%edi
f0103dcb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103dcd:	e8 1c 15 00 00       	call   f01052ee <cpunum>
f0103dd2:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dd5:	8b b0 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103ddb:	89 35 60 aa 22 f0    	mov    %esi,0xf022aa60
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch (tf->tf_trapno)
f0103de1:	8b 46 28             	mov    0x28(%esi),%eax
f0103de4:	83 f8 0e             	cmp    $0xe,%eax
f0103de7:	74 0c                	je     f0103df5 <trap+0x12a>
f0103de9:	83 f8 30             	cmp    $0x30,%eax
f0103dec:	74 29                	je     f0103e17 <trap+0x14c>
f0103dee:	83 f8 03             	cmp    $0x3,%eax
f0103df1:	75 45                	jne    f0103e38 <trap+0x16d>
f0103df3:	eb 11                	jmp    f0103e06 <trap+0x13b>
	{
	case T_PGFLT:
		page_fault_handler(tf);
f0103df5:	83 ec 0c             	sub    $0xc,%esp
f0103df8:	56                   	push   %esi
f0103df9:	e8 58 fe ff ff       	call   f0103c56 <page_fault_handler>
f0103dfe:	83 c4 10             	add    $0x10,%esp
f0103e01:	e9 94 00 00 00       	jmp    f0103e9a <trap+0x1cf>
		return;
	case T_BRKPT:
		monitor(tf);
f0103e06:	83 ec 0c             	sub    $0xc,%esp
f0103e09:	56                   	push   %esi
f0103e0a:	e8 10 cb ff ff       	call   f010091f <monitor>
f0103e0f:	83 c4 10             	add    $0x10,%esp
f0103e12:	e9 83 00 00 00       	jmp    f0103e9a <trap+0x1cf>
		return;
	case T_SYSCALL:
		tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, 
f0103e17:	83 ec 08             	sub    $0x8,%esp
f0103e1a:	ff 76 04             	pushl  0x4(%esi)
f0103e1d:	ff 36                	pushl  (%esi)
f0103e1f:	ff 76 10             	pushl  0x10(%esi)
f0103e22:	ff 76 18             	pushl  0x18(%esi)
f0103e25:	ff 76 14             	pushl  0x14(%esi)
f0103e28:	ff 76 1c             	pushl  0x1c(%esi)
f0103e2b:	e8 64 02 00 00       	call   f0104094 <syscall>
f0103e30:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103e33:	83 c4 20             	add    $0x20,%esp
f0103e36:	eb 62                	jmp    f0103e9a <trap+0x1cf>
	// 	}
	}
	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103e38:	83 f8 27             	cmp    $0x27,%eax
f0103e3b:	75 1a                	jne    f0103e57 <trap+0x18c>
		cprintf("Spurious interrupt on irq 7\n");
f0103e3d:	83 ec 0c             	sub    $0xc,%esp
f0103e40:	68 ef 6d 10 f0       	push   $0xf0106def
f0103e45:	e8 4b f8 ff ff       	call   f0103695 <cprintf>
		print_trapframe(tf);
f0103e4a:	89 34 24             	mov    %esi,(%esp)
f0103e4d:	e8 7c fc ff ff       	call   f0103ace <print_trapframe>
f0103e52:	83 c4 10             	add    $0x10,%esp
f0103e55:	eb 43                	jmp    f0103e9a <trap+0x1cf>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103e57:	83 ec 0c             	sub    $0xc,%esp
f0103e5a:	56                   	push   %esi
f0103e5b:	e8 6e fc ff ff       	call   f0103ace <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103e60:	83 c4 10             	add    $0x10,%esp
f0103e63:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103e68:	75 17                	jne    f0103e81 <trap+0x1b6>
		panic("unhandled trap in kernel");
f0103e6a:	83 ec 04             	sub    $0x4,%esp
f0103e6d:	68 0c 6e 10 f0       	push   $0xf0106e0c
f0103e72:	68 06 01 00 00       	push   $0x106
f0103e77:	68 c3 6d 10 f0       	push   $0xf0106dc3
f0103e7c:	e8 bf c1 ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f0103e81:	e8 68 14 00 00       	call   f01052ee <cpunum>
f0103e86:	83 ec 0c             	sub    $0xc,%esp
f0103e89:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e8c:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103e92:	e8 17 f5 ff ff       	call   f01033ae <env_destroy>
f0103e97:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103e9a:	e8 4f 14 00 00       	call   f01052ee <cpunum>
f0103e9f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ea2:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103ea9:	74 2a                	je     f0103ed5 <trap+0x20a>
f0103eab:	e8 3e 14 00 00       	call   f01052ee <cpunum>
f0103eb0:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eb3:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103eb9:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103ebd:	75 16                	jne    f0103ed5 <trap+0x20a>
		env_run(curenv);
f0103ebf:	e8 2a 14 00 00       	call   f01052ee <cpunum>
f0103ec4:	83 ec 0c             	sub    $0xc,%esp
f0103ec7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eca:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103ed0:	e8 78 f5 ff ff       	call   f010344d <env_run>
	else
		sched_yield();
f0103ed5:	e8 3a 01 00 00       	call   f0104014 <sched_yield>

f0103eda <divide_error>:
 * Lab 3: Your code here for generating entry points for the different traps.
 */



	TRAPHANDLER_NOEC(divide_error, T_DIVIDE) 
f0103eda:	6a 00                	push   $0x0
f0103edc:	6a 00                	push   $0x0
f0103ede:	eb 4e                	jmp    f0103f2e <_alltraps>

f0103ee0 <debug_exception>:
	TRAPHANDLER_NOEC(debug_exception, T_DEBUG) 
f0103ee0:	6a 00                	push   $0x0
f0103ee2:	6a 01                	push   $0x1
f0103ee4:	eb 48                	jmp    f0103f2e <_alltraps>

f0103ee6 <non_maskable_interrupt>:
	TRAPHANDLER_NOEC(non_maskable_interrupt, T_NMI) 
f0103ee6:	6a 00                	push   $0x0
f0103ee8:	6a 02                	push   $0x2
f0103eea:	eb 42                	jmp    f0103f2e <_alltraps>

f0103eec <break_point>:
	TRAPHANDLER_NOEC(break_point, T_BRKPT)// inc/x86.中有breakpoint同名函数
f0103eec:	6a 00                	push   $0x0
f0103eee:	6a 03                	push   $0x3
f0103ef0:	eb 3c                	jmp    f0103f2e <_alltraps>

f0103ef2 <overflow>:
	TRAPHANDLER_NOEC(overflow, T_OFLOW) 
f0103ef2:	6a 00                	push   $0x0
f0103ef4:	6a 04                	push   $0x4
f0103ef6:	eb 36                	jmp    f0103f2e <_alltraps>

f0103ef8 <bounds_check>:
	TRAPHANDLER_NOEC(bounds_check, T_BOUND) 
f0103ef8:	6a 00                	push   $0x0
f0103efa:	6a 05                	push   $0x5
f0103efc:	eb 30                	jmp    f0103f2e <_alltraps>

f0103efe <illegal_opcode>:
	TRAPHANDLER_NOEC(illegal_opcode, T_ILLOP) 
f0103efe:	6a 00                	push   $0x0
f0103f00:	6a 06                	push   $0x6
f0103f02:	eb 2a                	jmp    f0103f2e <_alltraps>

f0103f04 <device_not_available>:
	TRAPHANDLER_NOEC(device_not_available, T_DEVICE) 
f0103f04:	6a 00                	push   $0x0
f0103f06:	6a 07                	push   $0x7
f0103f08:	eb 24                	jmp    f0103f2e <_alltraps>

f0103f0a <double_fault>:
	TRAPHANDLER(double_fault, T_DBLFLT) 
f0103f0a:	6a 08                	push   $0x8
f0103f0c:	eb 20                	jmp    f0103f2e <_alltraps>

f0103f0e <invalid_task_switch_segment>:

	TRAPHANDLER(invalid_task_switch_segment, T_TSS) 
f0103f0e:	6a 0a                	push   $0xa
f0103f10:	eb 1c                	jmp    f0103f2e <_alltraps>

f0103f12 <segment_not_present>:
	TRAPHANDLER(segment_not_present, T_SEGNP) 
f0103f12:	6a 0b                	push   $0xb
f0103f14:	eb 18                	jmp    f0103f2e <_alltraps>

f0103f16 <stack_exception>:
	TRAPHANDLER(stack_exception, T_STACK) 
f0103f16:	6a 0c                	push   $0xc
f0103f18:	eb 14                	jmp    f0103f2e <_alltraps>

f0103f1a <general_protection_fault>:
	TRAPHANDLER(general_protection_fault, T_GPFLT) 
f0103f1a:	6a 0d                	push   $0xd
f0103f1c:	eb 10                	jmp    f0103f2e <_alltraps>

f0103f1e <page_fault>:
	TRAPHANDLER(page_fault, T_PGFLT) 
f0103f1e:	6a 0e                	push   $0xe
f0103f20:	eb 0c                	jmp    f0103f2e <_alltraps>

f0103f22 <floating_point_error>:

	TRAPHANDLER_NOEC(floating_point_error, T_FPERR) 
f0103f22:	6a 00                	push   $0x0
f0103f24:	6a 10                	push   $0x10
f0103f26:	eb 06                	jmp    f0103f2e <_alltraps>

f0103f28 <system_call>:
	//x86手册9.10中没有说明aligment check && machine check
	//&& SIMD floating point error是否返回error code，故没写上
	TRAPHANDLER_NOEC(system_call, T_SYSCALL)
f0103f28:	6a 00                	push   $0x0
f0103f2a:	6a 30                	push   $0x30
f0103f2c:	eb 00                	jmp    f0103f2e <_alltraps>

f0103f2e <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
f0103f2e:	1e                   	push   %ds
	pushl %es
f0103f2f:	06                   	push   %es
	pushal
f0103f30:	60                   	pusha  

	mov $GD_KD,%eax
f0103f31:	b8 10 00 00 00       	mov    $0x10,%eax
	mov %eax,%ds
f0103f36:	8e d8                	mov    %eax,%ds
	mov %eax,%es
f0103f38:	8e c0                	mov    %eax,%es
	
	pushl %esp  //压入trap()的参数tf，%esp指向Trapframe结构的起始地址
f0103f3a:	54                   	push   %esp
	call trap
f0103f3b:	e8 8b fd ff ff       	call   f0103ccb <trap>

f0103f40 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0103f40:	55                   	push   %ebp
f0103f41:	89 e5                	mov    %esp,%ebp
f0103f43:	83 ec 08             	sub    $0x8,%esp
f0103f46:	a1 48 a2 22 f0       	mov    0xf022a248,%eax
f0103f4b:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103f4e:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0103f53:	8b 02                	mov    (%edx),%eax
f0103f55:	83 e8 01             	sub    $0x1,%eax
f0103f58:	83 f8 02             	cmp    $0x2,%eax
f0103f5b:	76 10                	jbe    f0103f6d <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103f5d:	83 c1 01             	add    $0x1,%ecx
f0103f60:	83 c2 7c             	add    $0x7c,%edx
f0103f63:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103f69:	75 e8                	jne    f0103f53 <sched_halt+0x13>
f0103f6b:	eb 08                	jmp    f0103f75 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0103f6d:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103f73:	75 1f                	jne    f0103f94 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0103f75:	83 ec 0c             	sub    $0xc,%esp
f0103f78:	68 10 70 10 f0       	push   $0xf0107010
f0103f7d:	e8 13 f7 ff ff       	call   f0103695 <cprintf>
f0103f82:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0103f85:	83 ec 0c             	sub    $0xc,%esp
f0103f88:	6a 00                	push   $0x0
f0103f8a:	e8 90 c9 ff ff       	call   f010091f <monitor>
f0103f8f:	83 c4 10             	add    $0x10,%esp
f0103f92:	eb f1                	jmp    f0103f85 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0103f94:	e8 55 13 00 00       	call   f01052ee <cpunum>
f0103f99:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f9c:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103fa3:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0103fa6:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103fab:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103fb0:	77 12                	ja     f0103fc4 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103fb2:	50                   	push   %eax
f0103fb3:	68 c8 59 10 f0       	push   $0xf01059c8
f0103fb8:	6a 5c                	push   $0x5c
f0103fba:	68 39 70 10 f0       	push   $0xf0107039
f0103fbf:	e8 7c c0 ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103fc4:	05 00 00 00 10       	add    $0x10000000,%eax
f0103fc9:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0103fcc:	e8 1d 13 00 00       	call   f01052ee <cpunum>
f0103fd1:	6b d0 74             	imul   $0x74,%eax,%edx
f0103fd4:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103fda:	b8 02 00 00 00       	mov    $0x2,%eax
f0103fdf:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103fe3:	83 ec 0c             	sub    $0xc,%esp
f0103fe6:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103feb:	e8 09 16 00 00       	call   f01055f9 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103ff0:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0103ff2:	e8 f7 12 00 00       	call   f01052ee <cpunum>
f0103ff7:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f0103ffa:	8b 80 30 b0 22 f0    	mov    -0xfdd4fd0(%eax),%eax
f0104000:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104005:	89 c4                	mov    %eax,%esp
f0104007:	6a 00                	push   $0x0
f0104009:	6a 00                	push   $0x0
f010400b:	fb                   	sti    
f010400c:	f4                   	hlt    
f010400d:	eb fd                	jmp    f010400c <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f010400f:	83 c4 10             	add    $0x10,%esp
f0104012:	c9                   	leave  
f0104013:	c3                   	ret    

f0104014 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0104014:	55                   	push   %ebp
f0104015:	89 e5                	mov    %esp,%ebp
f0104017:	57                   	push   %edi
f0104018:	56                   	push   %esi
f0104019:	53                   	push   %ebx
f010401a:	83 ec 0c             	sub    $0xc,%esp
	// if(idle && idle->env_status == ENV_RUNNING)
	// {
	// 	env_run(idle);
	// 	return;
	// }	
	idle = curenv;
f010401d:	e8 cc 12 00 00       	call   f01052ee <cpunum>
f0104022:	6b c0 74             	imul   $0x74,%eax,%eax
f0104025:	8b b8 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%edi
    size_t idx = idle!=NULL ? ENVX(idle->env_id):-1;
f010402b:	85 ff                	test   %edi,%edi
f010402d:	74 0a                	je     f0104039 <sched_yield+0x25>
f010402f:	8b 47 48             	mov    0x48(%edi),%eax
f0104032:	25 ff 03 00 00       	and    $0x3ff,%eax
f0104037:	eb 05                	jmp    f010403e <sched_yield+0x2a>
f0104039:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    for (size_t i=0; i<NENV; i++) {
        idx = (idx+1 == NENV) ? 0:idx+1;
        if (envs[idx].env_status == ENV_RUNNABLE) {
f010403e:	8b 35 48 a2 22 f0    	mov    0xf022a248,%esi
f0104044:	b9 00 04 00 00       	mov    $0x400,%ecx
	// 	return;
	// }	
	idle = curenv;
    size_t idx = idle!=NULL ? ENVX(idle->env_id):-1;
    for (size_t i=0; i<NENV; i++) {
        idx = (idx+1 == NENV) ? 0:idx+1;
f0104049:	bb 00 00 00 00       	mov    $0x0,%ebx
f010404e:	8d 50 01             	lea    0x1(%eax),%edx
f0104051:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0104056:	89 d0                	mov    %edx,%eax
f0104058:	0f 44 c3             	cmove  %ebx,%eax
        if (envs[idx].env_status == ENV_RUNNABLE) {
f010405b:	6b d0 7c             	imul   $0x7c,%eax,%edx
f010405e:	01 f2                	add    %esi,%edx
f0104060:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f0104064:	75 09                	jne    f010406f <sched_yield+0x5b>
            env_run(&envs[idx]);
f0104066:	83 ec 0c             	sub    $0xc,%esp
f0104069:	52                   	push   %edx
f010406a:	e8 de f3 ff ff       	call   f010344d <env_run>
	// 	env_run(idle);
	// 	return;
	// }	
	idle = curenv;
    size_t idx = idle!=NULL ? ENVX(idle->env_id):-1;
    for (size_t i=0; i<NENV; i++) {
f010406f:	83 e9 01             	sub    $0x1,%ecx
f0104072:	75 da                	jne    f010404e <sched_yield+0x3a>
        if (envs[idx].env_status == ENV_RUNNABLE) {
            env_run(&envs[idx]);
            return;
        }
    }
    if (idle && idle->env_status == ENV_RUNNING) {
f0104074:	85 ff                	test   %edi,%edi
f0104076:	74 0f                	je     f0104087 <sched_yield+0x73>
f0104078:	83 7f 54 03          	cmpl   $0x3,0x54(%edi)
f010407c:	75 09                	jne    f0104087 <sched_yield+0x73>
        env_run(idle);
f010407e:	83 ec 0c             	sub    $0xc,%esp
f0104081:	57                   	push   %edi
f0104082:	e8 c6 f3 ff ff       	call   f010344d <env_run>
        return;
    }
	//sched_halt never returns
	sched_halt();
f0104087:	e8 b4 fe ff ff       	call   f0103f40 <sched_halt>
}
f010408c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010408f:	5b                   	pop    %ebx
f0104090:	5e                   	pop    %esi
f0104091:	5f                   	pop    %edi
f0104092:	5d                   	pop    %ebp
f0104093:	c3                   	ret    

f0104094 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104094:	55                   	push   %ebp
f0104095:	89 e5                	mov    %esp,%ebp
f0104097:	53                   	push   %ebx
f0104098:	83 ec 14             	sub    $0x14,%esp
f010409b:	8b 45 08             	mov    0x8(%ebp),%eax
	// LAB 3: Your code here.

	//panic("syscall not implemented");
	int ret = 0;

	switch (syscallno) {
f010409e:	83 f8 0a             	cmp    $0xa,%eax
f01040a1:	0f 87 f0 00 00 00    	ja     f0104197 <syscall+0x103>
f01040a7:	ff 24 85 80 70 10 f0 	jmp    *-0xfef8f80(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f01040ae:	e8 3b 12 00 00       	call   f01052ee <cpunum>
f01040b3:	6a 04                	push   $0x4
f01040b5:	ff 75 10             	pushl  0x10(%ebp)
f01040b8:	ff 75 0c             	pushl  0xc(%ebp)
f01040bb:	6b c0 74             	imul   $0x74,%eax,%eax
f01040be:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f01040c4:	e8 5d ec ff ff       	call   f0102d26 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01040c9:	83 c4 0c             	add    $0xc,%esp
f01040cc:	ff 75 0c             	pushl  0xc(%ebp)
f01040cf:	ff 75 10             	pushl  0x10(%ebp)
f01040d2:	68 46 70 10 f0       	push   $0xf0107046
f01040d7:	e8 b9 f5 ff ff       	call   f0103695 <cprintf>
f01040dc:	83 c4 10             	add    $0x10,%esp
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");
	int ret = 0;
f01040df:	b8 00 00 00 00       	mov    $0x0,%eax
f01040e4:	e9 b3 00 00 00       	jmp    f010419c <syscall+0x108>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01040e9:	e8 17 c5 ff ff       	call   f0100605 <cons_getc>
	case SYS_cputs:
		sys_cputs((const char*)a1,(size_t)a2);
		break;
	case SYS_cgetc:
		ret = sys_cgetc();
		break;
f01040ee:	e9 a9 00 00 00       	jmp    f010419c <syscall+0x108>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01040f3:	83 ec 04             	sub    $0x4,%esp
f01040f6:	6a 01                	push   $0x1
f01040f8:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01040fb:	50                   	push   %eax
f01040fc:	ff 75 0c             	pushl  0xc(%ebp)
f01040ff:	e8 f0 ec ff ff       	call   f0102df4 <envid2env>
f0104104:	83 c4 10             	add    $0x10,%esp
f0104107:	85 c0                	test   %eax,%eax
f0104109:	0f 88 8d 00 00 00    	js     f010419c <syscall+0x108>
		return r;
	if (e == curenv)
f010410f:	e8 da 11 00 00       	call   f01052ee <cpunum>
f0104114:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104117:	6b c0 74             	imul   $0x74,%eax,%eax
f010411a:	39 90 28 b0 22 f0    	cmp    %edx,-0xfdd4fd8(%eax)
f0104120:	75 23                	jne    f0104145 <syscall+0xb1>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104122:	e8 c7 11 00 00       	call   f01052ee <cpunum>
f0104127:	83 ec 08             	sub    $0x8,%esp
f010412a:	6b c0 74             	imul   $0x74,%eax,%eax
f010412d:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104133:	ff 70 48             	pushl  0x48(%eax)
f0104136:	68 4b 70 10 f0       	push   $0xf010704b
f010413b:	e8 55 f5 ff ff       	call   f0103695 <cprintf>
f0104140:	83 c4 10             	add    $0x10,%esp
f0104143:	eb 25                	jmp    f010416a <syscall+0xd6>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104145:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104148:	e8 a1 11 00 00       	call   f01052ee <cpunum>
f010414d:	83 ec 04             	sub    $0x4,%esp
f0104150:	53                   	push   %ebx
f0104151:	6b c0 74             	imul   $0x74,%eax,%eax
f0104154:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010415a:	ff 70 48             	pushl  0x48(%eax)
f010415d:	68 66 70 10 f0       	push   $0xf0107066
f0104162:	e8 2e f5 ff ff       	call   f0103695 <cprintf>
f0104167:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f010416a:	83 ec 0c             	sub    $0xc,%esp
f010416d:	ff 75 f4             	pushl  -0xc(%ebp)
f0104170:	e8 39 f2 ff ff       	call   f01033ae <env_destroy>
f0104175:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104178:	b8 00 00 00 00       	mov    $0x0,%eax
f010417d:	eb 1d                	jmp    f010419c <syscall+0x108>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f010417f:	e8 6a 11 00 00       	call   f01052ee <cpunum>
f0104184:	6b c0 74             	imul   $0x74,%eax,%eax
f0104187:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010418d:	8b 40 48             	mov    0x48(%eax),%eax
	case SYS_env_destroy:
		ret = sys_env_destroy((envid_t)a1);
		break;
	case SYS_getenvid:
		ret = sys_getenvid();
		break;
f0104190:	eb 0a                	jmp    f010419c <syscall+0x108>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104192:	e8 7d fe ff ff       	call   f0104014 <sched_yield>
		break;
	case SYS_yield:
		sys_yield();
		break;
	default:
		return -E_NO_SYS;
f0104197:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
	}
	return ret;
}
f010419c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010419f:	c9                   	leave  
f01041a0:	c3                   	ret    

f01041a1 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01041a1:	55                   	push   %ebp
f01041a2:	89 e5                	mov    %esp,%ebp
f01041a4:	57                   	push   %edi
f01041a5:	56                   	push   %esi
f01041a6:	53                   	push   %ebx
f01041a7:	83 ec 14             	sub    $0x14,%esp
f01041aa:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01041ad:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01041b0:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01041b3:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01041b6:	8b 1a                	mov    (%edx),%ebx
f01041b8:	8b 01                	mov    (%ecx),%eax
f01041ba:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01041bd:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01041c4:	eb 7f                	jmp    f0104245 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01041c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01041c9:	01 d8                	add    %ebx,%eax
f01041cb:	89 c6                	mov    %eax,%esi
f01041cd:	c1 ee 1f             	shr    $0x1f,%esi
f01041d0:	01 c6                	add    %eax,%esi
f01041d2:	d1 fe                	sar    %esi
f01041d4:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01041d7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01041da:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01041dd:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01041df:	eb 03                	jmp    f01041e4 <stab_binsearch+0x43>
			m--;
f01041e1:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01041e4:	39 c3                	cmp    %eax,%ebx
f01041e6:	7f 0d                	jg     f01041f5 <stab_binsearch+0x54>
f01041e8:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01041ec:	83 ea 0c             	sub    $0xc,%edx
f01041ef:	39 f9                	cmp    %edi,%ecx
f01041f1:	75 ee                	jne    f01041e1 <stab_binsearch+0x40>
f01041f3:	eb 05                	jmp    f01041fa <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01041f5:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01041f8:	eb 4b                	jmp    f0104245 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01041fa:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01041fd:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104200:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104204:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104207:	76 11                	jbe    f010421a <stab_binsearch+0x79>
			*region_left = m;
f0104209:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010420c:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010420e:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104211:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104218:	eb 2b                	jmp    f0104245 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010421a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010421d:	73 14                	jae    f0104233 <stab_binsearch+0x92>
			*region_right = m - 1;
f010421f:	83 e8 01             	sub    $0x1,%eax
f0104222:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104225:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104228:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010422a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104231:	eb 12                	jmp    f0104245 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104233:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104236:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0104238:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010423c:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010423e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104245:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104248:	0f 8e 78 ff ff ff    	jle    f01041c6 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010424e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104252:	75 0f                	jne    f0104263 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0104254:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104257:	8b 00                	mov    (%eax),%eax
f0104259:	83 e8 01             	sub    $0x1,%eax
f010425c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010425f:	89 06                	mov    %eax,(%esi)
f0104261:	eb 2c                	jmp    f010428f <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104263:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104266:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104268:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010426b:	8b 0e                	mov    (%esi),%ecx
f010426d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104270:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104273:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104276:	eb 03                	jmp    f010427b <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104278:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010427b:	39 c8                	cmp    %ecx,%eax
f010427d:	7e 0b                	jle    f010428a <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010427f:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104283:	83 ea 0c             	sub    $0xc,%edx
f0104286:	39 df                	cmp    %ebx,%edi
f0104288:	75 ee                	jne    f0104278 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010428a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010428d:	89 06                	mov    %eax,(%esi)
	}
}
f010428f:	83 c4 14             	add    $0x14,%esp
f0104292:	5b                   	pop    %ebx
f0104293:	5e                   	pop    %esi
f0104294:	5f                   	pop    %edi
f0104295:	5d                   	pop    %ebp
f0104296:	c3                   	ret    

f0104297 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104297:	55                   	push   %ebp
f0104298:	89 e5                	mov    %esp,%ebp
f010429a:	57                   	push   %edi
f010429b:	56                   	push   %esi
f010429c:	53                   	push   %ebx
f010429d:	83 ec 3c             	sub    $0x3c,%esp
f01042a0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01042a3:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01042a6:	c7 06 ac 70 10 f0    	movl   $0xf01070ac,(%esi)
	info->eip_line = 0;
f01042ac:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01042b3:	c7 46 08 ac 70 10 f0 	movl   $0xf01070ac,0x8(%esi)
	info->eip_fn_namelen = 9;
f01042ba:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01042c1:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01042c4:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01042cb:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01042d1:	0f 87 92 00 00 00    	ja     f0104369 <debuginfo_eip+0xd2>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0)
f01042d7:	e8 12 10 00 00       	call   f01052ee <cpunum>
f01042dc:	6a 04                	push   $0x4
f01042de:	6a 10                	push   $0x10
f01042e0:	68 00 00 20 00       	push   $0x200000
f01042e5:	6b c0 74             	imul   $0x74,%eax,%eax
f01042e8:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f01042ee:	e8 a4 e9 ff ff       	call   f0102c97 <user_mem_check>
f01042f3:	83 c4 10             	add    $0x10,%esp
f01042f6:	85 c0                	test   %eax,%eax
f01042f8:	0f 85 01 02 00 00    	jne    f01044ff <debuginfo_eip+0x268>
			return -1;
		stabs = usd->stabs;
f01042fe:	a1 00 00 20 00       	mov    0x200000,%eax
f0104303:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f0104306:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f010430c:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0104312:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f0104315:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f010431b:	89 55 d0             	mov    %edx,-0x30(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, sizeof(struct UserStabData), PTE_U) != 0)
f010431e:	e8 cb 0f 00 00       	call   f01052ee <cpunum>
f0104323:	6a 04                	push   $0x4
f0104325:	6a 10                	push   $0x10
f0104327:	ff 75 d4             	pushl  -0x2c(%ebp)
f010432a:	6b c0 74             	imul   $0x74,%eax,%eax
f010432d:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0104333:	e8 5f e9 ff ff       	call   f0102c97 <user_mem_check>
f0104338:	83 c4 10             	add    $0x10,%esp
f010433b:	85 c0                	test   %eax,%eax
f010433d:	0f 85 c3 01 00 00    	jne    f0104506 <debuginfo_eip+0x26f>
			return -1;
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
f0104343:	e8 a6 0f 00 00       	call   f01052ee <cpunum>
f0104348:	6a 04                	push   $0x4
f010434a:	6a 10                	push   $0x10
f010434c:	ff 75 cc             	pushl  -0x34(%ebp)
f010434f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104352:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0104358:	e8 3a e9 ff ff       	call   f0102c97 <user_mem_check>
f010435d:	83 c4 10             	add    $0x10,%esp
f0104360:	85 c0                	test   %eax,%eax
f0104362:	74 1f                	je     f0104383 <debuginfo_eip+0xec>
f0104364:	e9 a4 01 00 00       	jmp    f010450d <debuginfo_eip+0x276>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104369:	c7 45 d0 4b 43 11 f0 	movl   $0xf011434b,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104370:	c7 45 cc 61 0d 11 f0 	movl   $0xf0110d61,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104377:	bb 60 0d 11 f0       	mov    $0xf0110d60,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f010437c:	c7 45 d4 98 75 10 f0 	movl   $0xf0107598,-0x2c(%ebp)
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104383:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104386:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0104389:	0f 83 85 01 00 00    	jae    f0104514 <debuginfo_eip+0x27d>
f010438f:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104393:	0f 85 82 01 00 00    	jne    f010451b <debuginfo_eip+0x284>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104399:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01043a0:	2b 5d d4             	sub    -0x2c(%ebp),%ebx
f01043a3:	c1 fb 02             	sar    $0x2,%ebx
f01043a6:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f01043ac:	83 e8 01             	sub    $0x1,%eax
f01043af:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01043b2:	83 ec 08             	sub    $0x8,%esp
f01043b5:	57                   	push   %edi
f01043b6:	6a 64                	push   $0x64
f01043b8:	8d 55 e0             	lea    -0x20(%ebp),%edx
f01043bb:	89 d1                	mov    %edx,%ecx
f01043bd:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01043c0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01043c3:	89 d8                	mov    %ebx,%eax
f01043c5:	e8 d7 fd ff ff       	call   f01041a1 <stab_binsearch>
	if (lfile == 0)
f01043ca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043cd:	83 c4 10             	add    $0x10,%esp
f01043d0:	85 c0                	test   %eax,%eax
f01043d2:	0f 84 4a 01 00 00    	je     f0104522 <debuginfo_eip+0x28b>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01043d8:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01043db:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01043de:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01043e1:	83 ec 08             	sub    $0x8,%esp
f01043e4:	57                   	push   %edi
f01043e5:	6a 24                	push   $0x24
f01043e7:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01043ea:	89 d1                	mov    %edx,%ecx
f01043ec:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01043ef:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f01043f2:	89 d8                	mov    %ebx,%eax
f01043f4:	e8 a8 fd ff ff       	call   f01041a1 <stab_binsearch>

	if (lfun <= rfun) {
f01043f9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01043fc:	83 c4 10             	add    $0x10,%esp
f01043ff:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0104402:	7f 25                	jg     f0104429 <debuginfo_eip+0x192>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104404:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104407:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010440a:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010440d:	8b 02                	mov    (%edx),%eax
f010440f:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0104412:	2b 4d cc             	sub    -0x34(%ebp),%ecx
f0104415:	39 c8                	cmp    %ecx,%eax
f0104417:	73 06                	jae    f010441f <debuginfo_eip+0x188>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104419:	03 45 cc             	add    -0x34(%ebp),%eax
f010441c:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010441f:	8b 42 08             	mov    0x8(%edx),%eax
f0104422:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f0104425:	29 c7                	sub    %eax,%edi
f0104427:	eb 06                	jmp    f010442f <debuginfo_eip+0x198>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104429:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f010442c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010442f:	83 ec 08             	sub    $0x8,%esp
f0104432:	6a 3a                	push   $0x3a
f0104434:	ff 76 08             	pushl  0x8(%esi)
f0104437:	e8 74 08 00 00       	call   f0104cb0 <strfind>
f010443c:	2b 46 08             	sub    0x8(%esi),%eax
f010443f:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
f0104442:	83 c4 08             	add    $0x8,%esp
f0104445:	2b 7e 10             	sub    0x10(%esi),%edi
f0104448:	57                   	push   %edi
f0104449:	6a 44                	push   $0x44
f010444b:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010444e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104451:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104454:	89 f8                	mov    %edi,%eax
f0104456:	e8 46 fd ff ff       	call   f01041a1 <stab_binsearch>
	if (lfun > rfun) 
f010445b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010445e:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0104461:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0104464:	83 c4 10             	add    $0x10,%esp
f0104467:	39 c8                	cmp    %ecx,%eax
f0104469:	0f 8f ba 00 00 00    	jg     f0104529 <debuginfo_eip+0x292>
       	  return -1;
        info->eip_line = stabs[lfun].n_desc;
f010446f:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104472:	89 fa                	mov    %edi,%edx
f0104474:	8d 04 87             	lea    (%edi,%eax,4),%eax
f0104477:	89 45 c0             	mov    %eax,-0x40(%ebp)
f010447a:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f010447e:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104481:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104484:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104487:	8d 04 82             	lea    (%edx,%eax,4),%eax
f010448a:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f010448d:	eb 06                	jmp    f0104495 <debuginfo_eip+0x1fe>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010448f:	83 eb 01             	sub    $0x1,%ebx
f0104492:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104495:	39 fb                	cmp    %edi,%ebx
f0104497:	7c 32                	jl     f01044cb <debuginfo_eip+0x234>
	       && stabs[lline].n_type != N_SOL
f0104499:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f010449d:	80 fa 84             	cmp    $0x84,%dl
f01044a0:	74 0b                	je     f01044ad <debuginfo_eip+0x216>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01044a2:	80 fa 64             	cmp    $0x64,%dl
f01044a5:	75 e8                	jne    f010448f <debuginfo_eip+0x1f8>
f01044a7:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01044ab:	74 e2                	je     f010448f <debuginfo_eip+0x1f8>
f01044ad:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01044b0:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01044b3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01044b6:	8b 04 87             	mov    (%edi,%eax,4),%eax
f01044b9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01044bc:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01044bf:	29 fa                	sub    %edi,%edx
f01044c1:	39 d0                	cmp    %edx,%eax
f01044c3:	73 09                	jae    f01044ce <debuginfo_eip+0x237>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01044c5:	01 f8                	add    %edi,%eax
f01044c7:	89 06                	mov    %eax,(%esi)
f01044c9:	eb 03                	jmp    f01044ce <debuginfo_eip+0x237>
f01044cb:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01044ce:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01044d3:	8b 7d c8             	mov    -0x38(%ebp),%edi
f01044d6:	39 cf                	cmp    %ecx,%edi
f01044d8:	7d 5b                	jge    f0104535 <debuginfo_eip+0x29e>
		for (lline = lfun + 1;
f01044da:	89 f8                	mov    %edi,%eax
f01044dc:	83 c0 01             	add    $0x1,%eax
f01044df:	8b 55 c0             	mov    -0x40(%ebp),%edx
f01044e2:	eb 07                	jmp    f01044eb <debuginfo_eip+0x254>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01044e4:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01044e8:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01044eb:	39 c8                	cmp    %ecx,%eax
f01044ed:	74 41                	je     f0104530 <debuginfo_eip+0x299>
f01044ef:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01044f2:	80 7a 04 a0          	cmpb   $0xa0,0x4(%edx)
f01044f6:	74 ec                	je     f01044e4 <debuginfo_eip+0x24d>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01044f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01044fd:	eb 36                	jmp    f0104535 <debuginfo_eip+0x29e>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f01044ff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104504:	eb 2f                	jmp    f0104535 <debuginfo_eip+0x29e>
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f0104506:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010450b:	eb 28                	jmp    f0104535 <debuginfo_eip+0x29e>
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f010450d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104512:	eb 21                	jmp    f0104535 <debuginfo_eip+0x29e>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104514:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104519:	eb 1a                	jmp    f0104535 <debuginfo_eip+0x29e>
f010451b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104520:	eb 13                	jmp    f0104535 <debuginfo_eip+0x29e>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104522:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104527:	eb 0c                	jmp    f0104535 <debuginfo_eip+0x29e>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
	if (lfun > rfun) 
       	  return -1;
f0104529:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010452e:	eb 05                	jmp    f0104535 <debuginfo_eip+0x29e>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104530:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104535:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104538:	5b                   	pop    %ebx
f0104539:	5e                   	pop    %esi
f010453a:	5f                   	pop    %edi
f010453b:	5d                   	pop    %ebp
f010453c:	c3                   	ret    

f010453d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010453d:	55                   	push   %ebp
f010453e:	89 e5                	mov    %esp,%ebp
f0104540:	57                   	push   %edi
f0104541:	56                   	push   %esi
f0104542:	53                   	push   %ebx
f0104543:	83 ec 1c             	sub    $0x1c,%esp
f0104546:	89 c7                	mov    %eax,%edi
f0104548:	89 d6                	mov    %edx,%esi
f010454a:	8b 45 08             	mov    0x8(%ebp),%eax
f010454d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104550:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104553:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104556:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104559:	bb 00 00 00 00       	mov    $0x0,%ebx
f010455e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104561:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104564:	39 d3                	cmp    %edx,%ebx
f0104566:	72 05                	jb     f010456d <printnum+0x30>
f0104568:	39 45 10             	cmp    %eax,0x10(%ebp)
f010456b:	77 45                	ja     f01045b2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010456d:	83 ec 0c             	sub    $0xc,%esp
f0104570:	ff 75 18             	pushl  0x18(%ebp)
f0104573:	8b 45 14             	mov    0x14(%ebp),%eax
f0104576:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104579:	53                   	push   %ebx
f010457a:	ff 75 10             	pushl  0x10(%ebp)
f010457d:	83 ec 08             	sub    $0x8,%esp
f0104580:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104583:	ff 75 e0             	pushl  -0x20(%ebp)
f0104586:	ff 75 dc             	pushl  -0x24(%ebp)
f0104589:	ff 75 d8             	pushl  -0x28(%ebp)
f010458c:	e8 5f 11 00 00       	call   f01056f0 <__udivdi3>
f0104591:	83 c4 18             	add    $0x18,%esp
f0104594:	52                   	push   %edx
f0104595:	50                   	push   %eax
f0104596:	89 f2                	mov    %esi,%edx
f0104598:	89 f8                	mov    %edi,%eax
f010459a:	e8 9e ff ff ff       	call   f010453d <printnum>
f010459f:	83 c4 20             	add    $0x20,%esp
f01045a2:	eb 18                	jmp    f01045bc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01045a4:	83 ec 08             	sub    $0x8,%esp
f01045a7:	56                   	push   %esi
f01045a8:	ff 75 18             	pushl  0x18(%ebp)
f01045ab:	ff d7                	call   *%edi
f01045ad:	83 c4 10             	add    $0x10,%esp
f01045b0:	eb 03                	jmp    f01045b5 <printnum+0x78>
f01045b2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01045b5:	83 eb 01             	sub    $0x1,%ebx
f01045b8:	85 db                	test   %ebx,%ebx
f01045ba:	7f e8                	jg     f01045a4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01045bc:	83 ec 08             	sub    $0x8,%esp
f01045bf:	56                   	push   %esi
f01045c0:	83 ec 04             	sub    $0x4,%esp
f01045c3:	ff 75 e4             	pushl  -0x1c(%ebp)
f01045c6:	ff 75 e0             	pushl  -0x20(%ebp)
f01045c9:	ff 75 dc             	pushl  -0x24(%ebp)
f01045cc:	ff 75 d8             	pushl  -0x28(%ebp)
f01045cf:	e8 4c 12 00 00       	call   f0105820 <__umoddi3>
f01045d4:	83 c4 14             	add    $0x14,%esp
f01045d7:	0f be 80 b6 70 10 f0 	movsbl -0xfef8f4a(%eax),%eax
f01045de:	50                   	push   %eax
f01045df:	ff d7                	call   *%edi
}
f01045e1:	83 c4 10             	add    $0x10,%esp
f01045e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01045e7:	5b                   	pop    %ebx
f01045e8:	5e                   	pop    %esi
f01045e9:	5f                   	pop    %edi
f01045ea:	5d                   	pop    %ebp
f01045eb:	c3                   	ret    

f01045ec <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01045ec:	55                   	push   %ebp
f01045ed:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01045ef:	83 fa 01             	cmp    $0x1,%edx
f01045f2:	7e 0e                	jle    f0104602 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01045f4:	8b 10                	mov    (%eax),%edx
f01045f6:	8d 4a 08             	lea    0x8(%edx),%ecx
f01045f9:	89 08                	mov    %ecx,(%eax)
f01045fb:	8b 02                	mov    (%edx),%eax
f01045fd:	8b 52 04             	mov    0x4(%edx),%edx
f0104600:	eb 22                	jmp    f0104624 <getuint+0x38>
	else if (lflag)
f0104602:	85 d2                	test   %edx,%edx
f0104604:	74 10                	je     f0104616 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104606:	8b 10                	mov    (%eax),%edx
f0104608:	8d 4a 04             	lea    0x4(%edx),%ecx
f010460b:	89 08                	mov    %ecx,(%eax)
f010460d:	8b 02                	mov    (%edx),%eax
f010460f:	ba 00 00 00 00       	mov    $0x0,%edx
f0104614:	eb 0e                	jmp    f0104624 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104616:	8b 10                	mov    (%eax),%edx
f0104618:	8d 4a 04             	lea    0x4(%edx),%ecx
f010461b:	89 08                	mov    %ecx,(%eax)
f010461d:	8b 02                	mov    (%edx),%eax
f010461f:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104624:	5d                   	pop    %ebp
f0104625:	c3                   	ret    

f0104626 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104626:	55                   	push   %ebp
f0104627:	89 e5                	mov    %esp,%ebp
f0104629:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010462c:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104630:	8b 10                	mov    (%eax),%edx
f0104632:	3b 50 04             	cmp    0x4(%eax),%edx
f0104635:	73 0a                	jae    f0104641 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104637:	8d 4a 01             	lea    0x1(%edx),%ecx
f010463a:	89 08                	mov    %ecx,(%eax)
f010463c:	8b 45 08             	mov    0x8(%ebp),%eax
f010463f:	88 02                	mov    %al,(%edx)
}
f0104641:	5d                   	pop    %ebp
f0104642:	c3                   	ret    

f0104643 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104643:	55                   	push   %ebp
f0104644:	89 e5                	mov    %esp,%ebp
f0104646:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104649:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010464c:	50                   	push   %eax
f010464d:	ff 75 10             	pushl  0x10(%ebp)
f0104650:	ff 75 0c             	pushl  0xc(%ebp)
f0104653:	ff 75 08             	pushl  0x8(%ebp)
f0104656:	e8 05 00 00 00       	call   f0104660 <vprintfmt>
	va_end(ap);
}
f010465b:	83 c4 10             	add    $0x10,%esp
f010465e:	c9                   	leave  
f010465f:	c3                   	ret    

f0104660 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104660:	55                   	push   %ebp
f0104661:	89 e5                	mov    %esp,%ebp
f0104663:	57                   	push   %edi
f0104664:	56                   	push   %esi
f0104665:	53                   	push   %ebx
f0104666:	83 ec 2c             	sub    $0x2c,%esp
f0104669:	8b 75 08             	mov    0x8(%ebp),%esi
f010466c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010466f:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104672:	eb 12                	jmp    f0104686 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104674:	85 c0                	test   %eax,%eax
f0104676:	0f 84 89 03 00 00    	je     f0104a05 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f010467c:	83 ec 08             	sub    $0x8,%esp
f010467f:	53                   	push   %ebx
f0104680:	50                   	push   %eax
f0104681:	ff d6                	call   *%esi
f0104683:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104686:	83 c7 01             	add    $0x1,%edi
f0104689:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010468d:	83 f8 25             	cmp    $0x25,%eax
f0104690:	75 e2                	jne    f0104674 <vprintfmt+0x14>
f0104692:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104696:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010469d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01046a4:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01046ab:	ba 00 00 00 00       	mov    $0x0,%edx
f01046b0:	eb 07                	jmp    f01046b9 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046b2:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01046b5:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046b9:	8d 47 01             	lea    0x1(%edi),%eax
f01046bc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01046bf:	0f b6 07             	movzbl (%edi),%eax
f01046c2:	0f b6 c8             	movzbl %al,%ecx
f01046c5:	83 e8 23             	sub    $0x23,%eax
f01046c8:	3c 55                	cmp    $0x55,%al
f01046ca:	0f 87 1a 03 00 00    	ja     f01049ea <vprintfmt+0x38a>
f01046d0:	0f b6 c0             	movzbl %al,%eax
f01046d3:	ff 24 85 80 71 10 f0 	jmp    *-0xfef8e80(,%eax,4)
f01046da:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01046dd:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01046e1:	eb d6                	jmp    f01046b9 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046e3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01046e6:	b8 00 00 00 00       	mov    $0x0,%eax
f01046eb:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01046ee:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01046f1:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f01046f5:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f01046f8:	8d 51 d0             	lea    -0x30(%ecx),%edx
f01046fb:	83 fa 09             	cmp    $0x9,%edx
f01046fe:	77 39                	ja     f0104739 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104700:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104703:	eb e9                	jmp    f01046ee <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104705:	8b 45 14             	mov    0x14(%ebp),%eax
f0104708:	8d 48 04             	lea    0x4(%eax),%ecx
f010470b:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010470e:	8b 00                	mov    (%eax),%eax
f0104710:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104713:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104716:	eb 27                	jmp    f010473f <vprintfmt+0xdf>
f0104718:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010471b:	85 c0                	test   %eax,%eax
f010471d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104722:	0f 49 c8             	cmovns %eax,%ecx
f0104725:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104728:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010472b:	eb 8c                	jmp    f01046b9 <vprintfmt+0x59>
f010472d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104730:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104737:	eb 80                	jmp    f01046b9 <vprintfmt+0x59>
f0104739:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010473c:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f010473f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104743:	0f 89 70 ff ff ff    	jns    f01046b9 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104749:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010474c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010474f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104756:	e9 5e ff ff ff       	jmp    f01046b9 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010475b:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010475e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104761:	e9 53 ff ff ff       	jmp    f01046b9 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104766:	8b 45 14             	mov    0x14(%ebp),%eax
f0104769:	8d 50 04             	lea    0x4(%eax),%edx
f010476c:	89 55 14             	mov    %edx,0x14(%ebp)
f010476f:	83 ec 08             	sub    $0x8,%esp
f0104772:	53                   	push   %ebx
f0104773:	ff 30                	pushl  (%eax)
f0104775:	ff d6                	call   *%esi
			break;
f0104777:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010477a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010477d:	e9 04 ff ff ff       	jmp    f0104686 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104782:	8b 45 14             	mov    0x14(%ebp),%eax
f0104785:	8d 50 04             	lea    0x4(%eax),%edx
f0104788:	89 55 14             	mov    %edx,0x14(%ebp)
f010478b:	8b 00                	mov    (%eax),%eax
f010478d:	99                   	cltd   
f010478e:	31 d0                	xor    %edx,%eax
f0104790:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104792:	83 f8 09             	cmp    $0x9,%eax
f0104795:	7f 0b                	jg     f01047a2 <vprintfmt+0x142>
f0104797:	8b 14 85 e0 72 10 f0 	mov    -0xfef8d20(,%eax,4),%edx
f010479e:	85 d2                	test   %edx,%edx
f01047a0:	75 18                	jne    f01047ba <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f01047a2:	50                   	push   %eax
f01047a3:	68 ce 70 10 f0       	push   $0xf01070ce
f01047a8:	53                   	push   %ebx
f01047a9:	56                   	push   %esi
f01047aa:	e8 94 fe ff ff       	call   f0104643 <printfmt>
f01047af:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01047b2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01047b5:	e9 cc fe ff ff       	jmp    f0104686 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f01047ba:	52                   	push   %edx
f01047bb:	68 79 68 10 f0       	push   $0xf0106879
f01047c0:	53                   	push   %ebx
f01047c1:	56                   	push   %esi
f01047c2:	e8 7c fe ff ff       	call   f0104643 <printfmt>
f01047c7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01047ca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01047cd:	e9 b4 fe ff ff       	jmp    f0104686 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01047d2:	8b 45 14             	mov    0x14(%ebp),%eax
f01047d5:	8d 50 04             	lea    0x4(%eax),%edx
f01047d8:	89 55 14             	mov    %edx,0x14(%ebp)
f01047db:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01047dd:	85 ff                	test   %edi,%edi
f01047df:	b8 c7 70 10 f0       	mov    $0xf01070c7,%eax
f01047e4:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01047e7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01047eb:	0f 8e 94 00 00 00    	jle    f0104885 <vprintfmt+0x225>
f01047f1:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01047f5:	0f 84 98 00 00 00    	je     f0104893 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f01047fb:	83 ec 08             	sub    $0x8,%esp
f01047fe:	ff 75 d0             	pushl  -0x30(%ebp)
f0104801:	57                   	push   %edi
f0104802:	e8 5f 03 00 00       	call   f0104b66 <strnlen>
f0104807:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010480a:	29 c1                	sub    %eax,%ecx
f010480c:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f010480f:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104812:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104816:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104819:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010481c:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010481e:	eb 0f                	jmp    f010482f <vprintfmt+0x1cf>
					putch(padc, putdat);
f0104820:	83 ec 08             	sub    $0x8,%esp
f0104823:	53                   	push   %ebx
f0104824:	ff 75 e0             	pushl  -0x20(%ebp)
f0104827:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104829:	83 ef 01             	sub    $0x1,%edi
f010482c:	83 c4 10             	add    $0x10,%esp
f010482f:	85 ff                	test   %edi,%edi
f0104831:	7f ed                	jg     f0104820 <vprintfmt+0x1c0>
f0104833:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104836:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104839:	85 c9                	test   %ecx,%ecx
f010483b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104840:	0f 49 c1             	cmovns %ecx,%eax
f0104843:	29 c1                	sub    %eax,%ecx
f0104845:	89 75 08             	mov    %esi,0x8(%ebp)
f0104848:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010484b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010484e:	89 cb                	mov    %ecx,%ebx
f0104850:	eb 4d                	jmp    f010489f <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104852:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104856:	74 1b                	je     f0104873 <vprintfmt+0x213>
f0104858:	0f be c0             	movsbl %al,%eax
f010485b:	83 e8 20             	sub    $0x20,%eax
f010485e:	83 f8 5e             	cmp    $0x5e,%eax
f0104861:	76 10                	jbe    f0104873 <vprintfmt+0x213>
					putch('?', putdat);
f0104863:	83 ec 08             	sub    $0x8,%esp
f0104866:	ff 75 0c             	pushl  0xc(%ebp)
f0104869:	6a 3f                	push   $0x3f
f010486b:	ff 55 08             	call   *0x8(%ebp)
f010486e:	83 c4 10             	add    $0x10,%esp
f0104871:	eb 0d                	jmp    f0104880 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0104873:	83 ec 08             	sub    $0x8,%esp
f0104876:	ff 75 0c             	pushl  0xc(%ebp)
f0104879:	52                   	push   %edx
f010487a:	ff 55 08             	call   *0x8(%ebp)
f010487d:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104880:	83 eb 01             	sub    $0x1,%ebx
f0104883:	eb 1a                	jmp    f010489f <vprintfmt+0x23f>
f0104885:	89 75 08             	mov    %esi,0x8(%ebp)
f0104888:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010488b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010488e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104891:	eb 0c                	jmp    f010489f <vprintfmt+0x23f>
f0104893:	89 75 08             	mov    %esi,0x8(%ebp)
f0104896:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104899:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010489c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010489f:	83 c7 01             	add    $0x1,%edi
f01048a2:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01048a6:	0f be d0             	movsbl %al,%edx
f01048a9:	85 d2                	test   %edx,%edx
f01048ab:	74 23                	je     f01048d0 <vprintfmt+0x270>
f01048ad:	85 f6                	test   %esi,%esi
f01048af:	78 a1                	js     f0104852 <vprintfmt+0x1f2>
f01048b1:	83 ee 01             	sub    $0x1,%esi
f01048b4:	79 9c                	jns    f0104852 <vprintfmt+0x1f2>
f01048b6:	89 df                	mov    %ebx,%edi
f01048b8:	8b 75 08             	mov    0x8(%ebp),%esi
f01048bb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01048be:	eb 18                	jmp    f01048d8 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01048c0:	83 ec 08             	sub    $0x8,%esp
f01048c3:	53                   	push   %ebx
f01048c4:	6a 20                	push   $0x20
f01048c6:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01048c8:	83 ef 01             	sub    $0x1,%edi
f01048cb:	83 c4 10             	add    $0x10,%esp
f01048ce:	eb 08                	jmp    f01048d8 <vprintfmt+0x278>
f01048d0:	89 df                	mov    %ebx,%edi
f01048d2:	8b 75 08             	mov    0x8(%ebp),%esi
f01048d5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01048d8:	85 ff                	test   %edi,%edi
f01048da:	7f e4                	jg     f01048c0 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01048dc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01048df:	e9 a2 fd ff ff       	jmp    f0104686 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01048e4:	83 fa 01             	cmp    $0x1,%edx
f01048e7:	7e 16                	jle    f01048ff <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01048e9:	8b 45 14             	mov    0x14(%ebp),%eax
f01048ec:	8d 50 08             	lea    0x8(%eax),%edx
f01048ef:	89 55 14             	mov    %edx,0x14(%ebp)
f01048f2:	8b 50 04             	mov    0x4(%eax),%edx
f01048f5:	8b 00                	mov    (%eax),%eax
f01048f7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01048fa:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01048fd:	eb 32                	jmp    f0104931 <vprintfmt+0x2d1>
	else if (lflag)
f01048ff:	85 d2                	test   %edx,%edx
f0104901:	74 18                	je     f010491b <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0104903:	8b 45 14             	mov    0x14(%ebp),%eax
f0104906:	8d 50 04             	lea    0x4(%eax),%edx
f0104909:	89 55 14             	mov    %edx,0x14(%ebp)
f010490c:	8b 00                	mov    (%eax),%eax
f010490e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104911:	89 c1                	mov    %eax,%ecx
f0104913:	c1 f9 1f             	sar    $0x1f,%ecx
f0104916:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104919:	eb 16                	jmp    f0104931 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f010491b:	8b 45 14             	mov    0x14(%ebp),%eax
f010491e:	8d 50 04             	lea    0x4(%eax),%edx
f0104921:	89 55 14             	mov    %edx,0x14(%ebp)
f0104924:	8b 00                	mov    (%eax),%eax
f0104926:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104929:	89 c1                	mov    %eax,%ecx
f010492b:	c1 f9 1f             	sar    $0x1f,%ecx
f010492e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104931:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104934:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104937:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010493c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104940:	79 74                	jns    f01049b6 <vprintfmt+0x356>
				putch('-', putdat);
f0104942:	83 ec 08             	sub    $0x8,%esp
f0104945:	53                   	push   %ebx
f0104946:	6a 2d                	push   $0x2d
f0104948:	ff d6                	call   *%esi
				num = -(long long) num;
f010494a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010494d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104950:	f7 d8                	neg    %eax
f0104952:	83 d2 00             	adc    $0x0,%edx
f0104955:	f7 da                	neg    %edx
f0104957:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010495a:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010495f:	eb 55                	jmp    f01049b6 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104961:	8d 45 14             	lea    0x14(%ebp),%eax
f0104964:	e8 83 fc ff ff       	call   f01045ec <getuint>
			base = 10;
f0104969:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010496e:	eb 46                	jmp    f01049b6 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0104970:	8d 45 14             	lea    0x14(%ebp),%eax
f0104973:	e8 74 fc ff ff       	call   f01045ec <getuint>
			base = 8;
f0104978:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010497d:	eb 37                	jmp    f01049b6 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f010497f:	83 ec 08             	sub    $0x8,%esp
f0104982:	53                   	push   %ebx
f0104983:	6a 30                	push   $0x30
f0104985:	ff d6                	call   *%esi
			putch('x', putdat);
f0104987:	83 c4 08             	add    $0x8,%esp
f010498a:	53                   	push   %ebx
f010498b:	6a 78                	push   $0x78
f010498d:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010498f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104992:	8d 50 04             	lea    0x4(%eax),%edx
f0104995:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104998:	8b 00                	mov    (%eax),%eax
f010499a:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010499f:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01049a2:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01049a7:	eb 0d                	jmp    f01049b6 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01049a9:	8d 45 14             	lea    0x14(%ebp),%eax
f01049ac:	e8 3b fc ff ff       	call   f01045ec <getuint>
			base = 16;
f01049b1:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01049b6:	83 ec 0c             	sub    $0xc,%esp
f01049b9:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01049bd:	57                   	push   %edi
f01049be:	ff 75 e0             	pushl  -0x20(%ebp)
f01049c1:	51                   	push   %ecx
f01049c2:	52                   	push   %edx
f01049c3:	50                   	push   %eax
f01049c4:	89 da                	mov    %ebx,%edx
f01049c6:	89 f0                	mov    %esi,%eax
f01049c8:	e8 70 fb ff ff       	call   f010453d <printnum>
			break;
f01049cd:	83 c4 20             	add    $0x20,%esp
f01049d0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01049d3:	e9 ae fc ff ff       	jmp    f0104686 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01049d8:	83 ec 08             	sub    $0x8,%esp
f01049db:	53                   	push   %ebx
f01049dc:	51                   	push   %ecx
f01049dd:	ff d6                	call   *%esi
			break;
f01049df:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01049e2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01049e5:	e9 9c fc ff ff       	jmp    f0104686 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01049ea:	83 ec 08             	sub    $0x8,%esp
f01049ed:	53                   	push   %ebx
f01049ee:	6a 25                	push   $0x25
f01049f0:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01049f2:	83 c4 10             	add    $0x10,%esp
f01049f5:	eb 03                	jmp    f01049fa <vprintfmt+0x39a>
f01049f7:	83 ef 01             	sub    $0x1,%edi
f01049fa:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01049fe:	75 f7                	jne    f01049f7 <vprintfmt+0x397>
f0104a00:	e9 81 fc ff ff       	jmp    f0104686 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0104a05:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104a08:	5b                   	pop    %ebx
f0104a09:	5e                   	pop    %esi
f0104a0a:	5f                   	pop    %edi
f0104a0b:	5d                   	pop    %ebp
f0104a0c:	c3                   	ret    

f0104a0d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104a0d:	55                   	push   %ebp
f0104a0e:	89 e5                	mov    %esp,%ebp
f0104a10:	83 ec 18             	sub    $0x18,%esp
f0104a13:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a16:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104a19:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104a1c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104a20:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104a23:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104a2a:	85 c0                	test   %eax,%eax
f0104a2c:	74 26                	je     f0104a54 <vsnprintf+0x47>
f0104a2e:	85 d2                	test   %edx,%edx
f0104a30:	7e 22                	jle    f0104a54 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104a32:	ff 75 14             	pushl  0x14(%ebp)
f0104a35:	ff 75 10             	pushl  0x10(%ebp)
f0104a38:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104a3b:	50                   	push   %eax
f0104a3c:	68 26 46 10 f0       	push   $0xf0104626
f0104a41:	e8 1a fc ff ff       	call   f0104660 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104a46:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104a49:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104a4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104a4f:	83 c4 10             	add    $0x10,%esp
f0104a52:	eb 05                	jmp    f0104a59 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104a54:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104a59:	c9                   	leave  
f0104a5a:	c3                   	ret    

f0104a5b <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104a5b:	55                   	push   %ebp
f0104a5c:	89 e5                	mov    %esp,%ebp
f0104a5e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104a61:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104a64:	50                   	push   %eax
f0104a65:	ff 75 10             	pushl  0x10(%ebp)
f0104a68:	ff 75 0c             	pushl  0xc(%ebp)
f0104a6b:	ff 75 08             	pushl  0x8(%ebp)
f0104a6e:	e8 9a ff ff ff       	call   f0104a0d <vsnprintf>
	va_end(ap);

	return rc;
}
f0104a73:	c9                   	leave  
f0104a74:	c3                   	ret    

f0104a75 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104a75:	55                   	push   %ebp
f0104a76:	89 e5                	mov    %esp,%ebp
f0104a78:	57                   	push   %edi
f0104a79:	56                   	push   %esi
f0104a7a:	53                   	push   %ebx
f0104a7b:	83 ec 0c             	sub    $0xc,%esp
f0104a7e:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104a81:	85 c0                	test   %eax,%eax
f0104a83:	74 11                	je     f0104a96 <readline+0x21>
		cprintf("%s", prompt);
f0104a85:	83 ec 08             	sub    $0x8,%esp
f0104a88:	50                   	push   %eax
f0104a89:	68 79 68 10 f0       	push   $0xf0106879
f0104a8e:	e8 02 ec ff ff       	call   f0103695 <cprintf>
f0104a93:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104a96:	83 ec 0c             	sub    $0xc,%esp
f0104a99:	6a 00                	push   $0x0
f0104a9b:	e8 f5 bc ff ff       	call   f0100795 <iscons>
f0104aa0:	89 c7                	mov    %eax,%edi
f0104aa2:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104aa5:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104aaa:	e8 d5 bc ff ff       	call   f0100784 <getchar>
f0104aaf:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104ab1:	85 c0                	test   %eax,%eax
f0104ab3:	79 18                	jns    f0104acd <readline+0x58>
			cprintf("read error: %e\n", c);
f0104ab5:	83 ec 08             	sub    $0x8,%esp
f0104ab8:	50                   	push   %eax
f0104ab9:	68 08 73 10 f0       	push   $0xf0107308
f0104abe:	e8 d2 eb ff ff       	call   f0103695 <cprintf>
			return NULL;
f0104ac3:	83 c4 10             	add    $0x10,%esp
f0104ac6:	b8 00 00 00 00       	mov    $0x0,%eax
f0104acb:	eb 79                	jmp    f0104b46 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104acd:	83 f8 08             	cmp    $0x8,%eax
f0104ad0:	0f 94 c2             	sete   %dl
f0104ad3:	83 f8 7f             	cmp    $0x7f,%eax
f0104ad6:	0f 94 c0             	sete   %al
f0104ad9:	08 c2                	or     %al,%dl
f0104adb:	74 1a                	je     f0104af7 <readline+0x82>
f0104add:	85 f6                	test   %esi,%esi
f0104adf:	7e 16                	jle    f0104af7 <readline+0x82>
			if (echoing)
f0104ae1:	85 ff                	test   %edi,%edi
f0104ae3:	74 0d                	je     f0104af2 <readline+0x7d>
				cputchar('\b');
f0104ae5:	83 ec 0c             	sub    $0xc,%esp
f0104ae8:	6a 08                	push   $0x8
f0104aea:	e8 85 bc ff ff       	call   f0100774 <cputchar>
f0104aef:	83 c4 10             	add    $0x10,%esp
			i--;
f0104af2:	83 ee 01             	sub    $0x1,%esi
f0104af5:	eb b3                	jmp    f0104aaa <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104af7:	83 fb 1f             	cmp    $0x1f,%ebx
f0104afa:	7e 23                	jle    f0104b1f <readline+0xaa>
f0104afc:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104b02:	7f 1b                	jg     f0104b1f <readline+0xaa>
			if (echoing)
f0104b04:	85 ff                	test   %edi,%edi
f0104b06:	74 0c                	je     f0104b14 <readline+0x9f>
				cputchar(c);
f0104b08:	83 ec 0c             	sub    $0xc,%esp
f0104b0b:	53                   	push   %ebx
f0104b0c:	e8 63 bc ff ff       	call   f0100774 <cputchar>
f0104b11:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104b14:	88 9e 80 aa 22 f0    	mov    %bl,-0xfdd5580(%esi)
f0104b1a:	8d 76 01             	lea    0x1(%esi),%esi
f0104b1d:	eb 8b                	jmp    f0104aaa <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104b1f:	83 fb 0a             	cmp    $0xa,%ebx
f0104b22:	74 05                	je     f0104b29 <readline+0xb4>
f0104b24:	83 fb 0d             	cmp    $0xd,%ebx
f0104b27:	75 81                	jne    f0104aaa <readline+0x35>
			if (echoing)
f0104b29:	85 ff                	test   %edi,%edi
f0104b2b:	74 0d                	je     f0104b3a <readline+0xc5>
				cputchar('\n');
f0104b2d:	83 ec 0c             	sub    $0xc,%esp
f0104b30:	6a 0a                	push   $0xa
f0104b32:	e8 3d bc ff ff       	call   f0100774 <cputchar>
f0104b37:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104b3a:	c6 86 80 aa 22 f0 00 	movb   $0x0,-0xfdd5580(%esi)
			return buf;
f0104b41:	b8 80 aa 22 f0       	mov    $0xf022aa80,%eax
		}
	}
}
f0104b46:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104b49:	5b                   	pop    %ebx
f0104b4a:	5e                   	pop    %esi
f0104b4b:	5f                   	pop    %edi
f0104b4c:	5d                   	pop    %ebp
f0104b4d:	c3                   	ret    

f0104b4e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104b4e:	55                   	push   %ebp
f0104b4f:	89 e5                	mov    %esp,%ebp
f0104b51:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104b54:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b59:	eb 03                	jmp    f0104b5e <strlen+0x10>
		n++;
f0104b5b:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104b5e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104b62:	75 f7                	jne    f0104b5b <strlen+0xd>
		n++;
	return n;
}
f0104b64:	5d                   	pop    %ebp
f0104b65:	c3                   	ret    

f0104b66 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104b66:	55                   	push   %ebp
f0104b67:	89 e5                	mov    %esp,%ebp
f0104b69:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104b6c:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104b6f:	ba 00 00 00 00       	mov    $0x0,%edx
f0104b74:	eb 03                	jmp    f0104b79 <strnlen+0x13>
		n++;
f0104b76:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104b79:	39 c2                	cmp    %eax,%edx
f0104b7b:	74 08                	je     f0104b85 <strnlen+0x1f>
f0104b7d:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104b81:	75 f3                	jne    f0104b76 <strnlen+0x10>
f0104b83:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104b85:	5d                   	pop    %ebp
f0104b86:	c3                   	ret    

f0104b87 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104b87:	55                   	push   %ebp
f0104b88:	89 e5                	mov    %esp,%ebp
f0104b8a:	53                   	push   %ebx
f0104b8b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b8e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104b91:	89 c2                	mov    %eax,%edx
f0104b93:	83 c2 01             	add    $0x1,%edx
f0104b96:	83 c1 01             	add    $0x1,%ecx
f0104b99:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104b9d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104ba0:	84 db                	test   %bl,%bl
f0104ba2:	75 ef                	jne    f0104b93 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104ba4:	5b                   	pop    %ebx
f0104ba5:	5d                   	pop    %ebp
f0104ba6:	c3                   	ret    

f0104ba7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104ba7:	55                   	push   %ebp
f0104ba8:	89 e5                	mov    %esp,%ebp
f0104baa:	53                   	push   %ebx
f0104bab:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104bae:	53                   	push   %ebx
f0104baf:	e8 9a ff ff ff       	call   f0104b4e <strlen>
f0104bb4:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104bb7:	ff 75 0c             	pushl  0xc(%ebp)
f0104bba:	01 d8                	add    %ebx,%eax
f0104bbc:	50                   	push   %eax
f0104bbd:	e8 c5 ff ff ff       	call   f0104b87 <strcpy>
	return dst;
}
f0104bc2:	89 d8                	mov    %ebx,%eax
f0104bc4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104bc7:	c9                   	leave  
f0104bc8:	c3                   	ret    

f0104bc9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104bc9:	55                   	push   %ebp
f0104bca:	89 e5                	mov    %esp,%ebp
f0104bcc:	56                   	push   %esi
f0104bcd:	53                   	push   %ebx
f0104bce:	8b 75 08             	mov    0x8(%ebp),%esi
f0104bd1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104bd4:	89 f3                	mov    %esi,%ebx
f0104bd6:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104bd9:	89 f2                	mov    %esi,%edx
f0104bdb:	eb 0f                	jmp    f0104bec <strncpy+0x23>
		*dst++ = *src;
f0104bdd:	83 c2 01             	add    $0x1,%edx
f0104be0:	0f b6 01             	movzbl (%ecx),%eax
f0104be3:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104be6:	80 39 01             	cmpb   $0x1,(%ecx)
f0104be9:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104bec:	39 da                	cmp    %ebx,%edx
f0104bee:	75 ed                	jne    f0104bdd <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104bf0:	89 f0                	mov    %esi,%eax
f0104bf2:	5b                   	pop    %ebx
f0104bf3:	5e                   	pop    %esi
f0104bf4:	5d                   	pop    %ebp
f0104bf5:	c3                   	ret    

f0104bf6 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104bf6:	55                   	push   %ebp
f0104bf7:	89 e5                	mov    %esp,%ebp
f0104bf9:	56                   	push   %esi
f0104bfa:	53                   	push   %ebx
f0104bfb:	8b 75 08             	mov    0x8(%ebp),%esi
f0104bfe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104c01:	8b 55 10             	mov    0x10(%ebp),%edx
f0104c04:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104c06:	85 d2                	test   %edx,%edx
f0104c08:	74 21                	je     f0104c2b <strlcpy+0x35>
f0104c0a:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104c0e:	89 f2                	mov    %esi,%edx
f0104c10:	eb 09                	jmp    f0104c1b <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104c12:	83 c2 01             	add    $0x1,%edx
f0104c15:	83 c1 01             	add    $0x1,%ecx
f0104c18:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104c1b:	39 c2                	cmp    %eax,%edx
f0104c1d:	74 09                	je     f0104c28 <strlcpy+0x32>
f0104c1f:	0f b6 19             	movzbl (%ecx),%ebx
f0104c22:	84 db                	test   %bl,%bl
f0104c24:	75 ec                	jne    f0104c12 <strlcpy+0x1c>
f0104c26:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104c28:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104c2b:	29 f0                	sub    %esi,%eax
}
f0104c2d:	5b                   	pop    %ebx
f0104c2e:	5e                   	pop    %esi
f0104c2f:	5d                   	pop    %ebp
f0104c30:	c3                   	ret    

f0104c31 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104c31:	55                   	push   %ebp
f0104c32:	89 e5                	mov    %esp,%ebp
f0104c34:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104c37:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104c3a:	eb 06                	jmp    f0104c42 <strcmp+0x11>
		p++, q++;
f0104c3c:	83 c1 01             	add    $0x1,%ecx
f0104c3f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104c42:	0f b6 01             	movzbl (%ecx),%eax
f0104c45:	84 c0                	test   %al,%al
f0104c47:	74 04                	je     f0104c4d <strcmp+0x1c>
f0104c49:	3a 02                	cmp    (%edx),%al
f0104c4b:	74 ef                	je     f0104c3c <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104c4d:	0f b6 c0             	movzbl %al,%eax
f0104c50:	0f b6 12             	movzbl (%edx),%edx
f0104c53:	29 d0                	sub    %edx,%eax
}
f0104c55:	5d                   	pop    %ebp
f0104c56:	c3                   	ret    

f0104c57 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104c57:	55                   	push   %ebp
f0104c58:	89 e5                	mov    %esp,%ebp
f0104c5a:	53                   	push   %ebx
f0104c5b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c5e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c61:	89 c3                	mov    %eax,%ebx
f0104c63:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104c66:	eb 06                	jmp    f0104c6e <strncmp+0x17>
		n--, p++, q++;
f0104c68:	83 c0 01             	add    $0x1,%eax
f0104c6b:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104c6e:	39 d8                	cmp    %ebx,%eax
f0104c70:	74 15                	je     f0104c87 <strncmp+0x30>
f0104c72:	0f b6 08             	movzbl (%eax),%ecx
f0104c75:	84 c9                	test   %cl,%cl
f0104c77:	74 04                	je     f0104c7d <strncmp+0x26>
f0104c79:	3a 0a                	cmp    (%edx),%cl
f0104c7b:	74 eb                	je     f0104c68 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104c7d:	0f b6 00             	movzbl (%eax),%eax
f0104c80:	0f b6 12             	movzbl (%edx),%edx
f0104c83:	29 d0                	sub    %edx,%eax
f0104c85:	eb 05                	jmp    f0104c8c <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104c87:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104c8c:	5b                   	pop    %ebx
f0104c8d:	5d                   	pop    %ebp
f0104c8e:	c3                   	ret    

f0104c8f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104c8f:	55                   	push   %ebp
f0104c90:	89 e5                	mov    %esp,%ebp
f0104c92:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c95:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104c99:	eb 07                	jmp    f0104ca2 <strchr+0x13>
		if (*s == c)
f0104c9b:	38 ca                	cmp    %cl,%dl
f0104c9d:	74 0f                	je     f0104cae <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104c9f:	83 c0 01             	add    $0x1,%eax
f0104ca2:	0f b6 10             	movzbl (%eax),%edx
f0104ca5:	84 d2                	test   %dl,%dl
f0104ca7:	75 f2                	jne    f0104c9b <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104ca9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104cae:	5d                   	pop    %ebp
f0104caf:	c3                   	ret    

f0104cb0 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104cb0:	55                   	push   %ebp
f0104cb1:	89 e5                	mov    %esp,%ebp
f0104cb3:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cb6:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104cba:	eb 03                	jmp    f0104cbf <strfind+0xf>
f0104cbc:	83 c0 01             	add    $0x1,%eax
f0104cbf:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104cc2:	38 ca                	cmp    %cl,%dl
f0104cc4:	74 04                	je     f0104cca <strfind+0x1a>
f0104cc6:	84 d2                	test   %dl,%dl
f0104cc8:	75 f2                	jne    f0104cbc <strfind+0xc>
			break;
	return (char *) s;
}
f0104cca:	5d                   	pop    %ebp
f0104ccb:	c3                   	ret    

f0104ccc <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104ccc:	55                   	push   %ebp
f0104ccd:	89 e5                	mov    %esp,%ebp
f0104ccf:	57                   	push   %edi
f0104cd0:	56                   	push   %esi
f0104cd1:	53                   	push   %ebx
f0104cd2:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104cd5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104cd8:	85 c9                	test   %ecx,%ecx
f0104cda:	74 36                	je     f0104d12 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104cdc:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104ce2:	75 28                	jne    f0104d0c <memset+0x40>
f0104ce4:	f6 c1 03             	test   $0x3,%cl
f0104ce7:	75 23                	jne    f0104d0c <memset+0x40>
		c &= 0xFF;
f0104ce9:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104ced:	89 d3                	mov    %edx,%ebx
f0104cef:	c1 e3 08             	shl    $0x8,%ebx
f0104cf2:	89 d6                	mov    %edx,%esi
f0104cf4:	c1 e6 18             	shl    $0x18,%esi
f0104cf7:	89 d0                	mov    %edx,%eax
f0104cf9:	c1 e0 10             	shl    $0x10,%eax
f0104cfc:	09 f0                	or     %esi,%eax
f0104cfe:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0104d00:	89 d8                	mov    %ebx,%eax
f0104d02:	09 d0                	or     %edx,%eax
f0104d04:	c1 e9 02             	shr    $0x2,%ecx
f0104d07:	fc                   	cld    
f0104d08:	f3 ab                	rep stos %eax,%es:(%edi)
f0104d0a:	eb 06                	jmp    f0104d12 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104d0c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d0f:	fc                   	cld    
f0104d10:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104d12:	89 f8                	mov    %edi,%eax
f0104d14:	5b                   	pop    %ebx
f0104d15:	5e                   	pop    %esi
f0104d16:	5f                   	pop    %edi
f0104d17:	5d                   	pop    %ebp
f0104d18:	c3                   	ret    

f0104d19 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104d19:	55                   	push   %ebp
f0104d1a:	89 e5                	mov    %esp,%ebp
f0104d1c:	57                   	push   %edi
f0104d1d:	56                   	push   %esi
f0104d1e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d21:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104d24:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104d27:	39 c6                	cmp    %eax,%esi
f0104d29:	73 35                	jae    f0104d60 <memmove+0x47>
f0104d2b:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104d2e:	39 d0                	cmp    %edx,%eax
f0104d30:	73 2e                	jae    f0104d60 <memmove+0x47>
		s += n;
		d += n;
f0104d32:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104d35:	89 d6                	mov    %edx,%esi
f0104d37:	09 fe                	or     %edi,%esi
f0104d39:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104d3f:	75 13                	jne    f0104d54 <memmove+0x3b>
f0104d41:	f6 c1 03             	test   $0x3,%cl
f0104d44:	75 0e                	jne    f0104d54 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104d46:	83 ef 04             	sub    $0x4,%edi
f0104d49:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104d4c:	c1 e9 02             	shr    $0x2,%ecx
f0104d4f:	fd                   	std    
f0104d50:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104d52:	eb 09                	jmp    f0104d5d <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104d54:	83 ef 01             	sub    $0x1,%edi
f0104d57:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104d5a:	fd                   	std    
f0104d5b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104d5d:	fc                   	cld    
f0104d5e:	eb 1d                	jmp    f0104d7d <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104d60:	89 f2                	mov    %esi,%edx
f0104d62:	09 c2                	or     %eax,%edx
f0104d64:	f6 c2 03             	test   $0x3,%dl
f0104d67:	75 0f                	jne    f0104d78 <memmove+0x5f>
f0104d69:	f6 c1 03             	test   $0x3,%cl
f0104d6c:	75 0a                	jne    f0104d78 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0104d6e:	c1 e9 02             	shr    $0x2,%ecx
f0104d71:	89 c7                	mov    %eax,%edi
f0104d73:	fc                   	cld    
f0104d74:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104d76:	eb 05                	jmp    f0104d7d <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104d78:	89 c7                	mov    %eax,%edi
f0104d7a:	fc                   	cld    
f0104d7b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104d7d:	5e                   	pop    %esi
f0104d7e:	5f                   	pop    %edi
f0104d7f:	5d                   	pop    %ebp
f0104d80:	c3                   	ret    

f0104d81 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104d81:	55                   	push   %ebp
f0104d82:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104d84:	ff 75 10             	pushl  0x10(%ebp)
f0104d87:	ff 75 0c             	pushl  0xc(%ebp)
f0104d8a:	ff 75 08             	pushl  0x8(%ebp)
f0104d8d:	e8 87 ff ff ff       	call   f0104d19 <memmove>
}
f0104d92:	c9                   	leave  
f0104d93:	c3                   	ret    

f0104d94 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104d94:	55                   	push   %ebp
f0104d95:	89 e5                	mov    %esp,%ebp
f0104d97:	56                   	push   %esi
f0104d98:	53                   	push   %ebx
f0104d99:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d9c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104d9f:	89 c6                	mov    %eax,%esi
f0104da1:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104da4:	eb 1a                	jmp    f0104dc0 <memcmp+0x2c>
		if (*s1 != *s2)
f0104da6:	0f b6 08             	movzbl (%eax),%ecx
f0104da9:	0f b6 1a             	movzbl (%edx),%ebx
f0104dac:	38 d9                	cmp    %bl,%cl
f0104dae:	74 0a                	je     f0104dba <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104db0:	0f b6 c1             	movzbl %cl,%eax
f0104db3:	0f b6 db             	movzbl %bl,%ebx
f0104db6:	29 d8                	sub    %ebx,%eax
f0104db8:	eb 0f                	jmp    f0104dc9 <memcmp+0x35>
		s1++, s2++;
f0104dba:	83 c0 01             	add    $0x1,%eax
f0104dbd:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104dc0:	39 f0                	cmp    %esi,%eax
f0104dc2:	75 e2                	jne    f0104da6 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104dc4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104dc9:	5b                   	pop    %ebx
f0104dca:	5e                   	pop    %esi
f0104dcb:	5d                   	pop    %ebp
f0104dcc:	c3                   	ret    

f0104dcd <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104dcd:	55                   	push   %ebp
f0104dce:	89 e5                	mov    %esp,%ebp
f0104dd0:	53                   	push   %ebx
f0104dd1:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104dd4:	89 c1                	mov    %eax,%ecx
f0104dd6:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104dd9:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104ddd:	eb 0a                	jmp    f0104de9 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104ddf:	0f b6 10             	movzbl (%eax),%edx
f0104de2:	39 da                	cmp    %ebx,%edx
f0104de4:	74 07                	je     f0104ded <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104de6:	83 c0 01             	add    $0x1,%eax
f0104de9:	39 c8                	cmp    %ecx,%eax
f0104deb:	72 f2                	jb     f0104ddf <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104ded:	5b                   	pop    %ebx
f0104dee:	5d                   	pop    %ebp
f0104def:	c3                   	ret    

f0104df0 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104df0:	55                   	push   %ebp
f0104df1:	89 e5                	mov    %esp,%ebp
f0104df3:	57                   	push   %edi
f0104df4:	56                   	push   %esi
f0104df5:	53                   	push   %ebx
f0104df6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104df9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104dfc:	eb 03                	jmp    f0104e01 <strtol+0x11>
		s++;
f0104dfe:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104e01:	0f b6 01             	movzbl (%ecx),%eax
f0104e04:	3c 20                	cmp    $0x20,%al
f0104e06:	74 f6                	je     f0104dfe <strtol+0xe>
f0104e08:	3c 09                	cmp    $0x9,%al
f0104e0a:	74 f2                	je     f0104dfe <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104e0c:	3c 2b                	cmp    $0x2b,%al
f0104e0e:	75 0a                	jne    f0104e1a <strtol+0x2a>
		s++;
f0104e10:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104e13:	bf 00 00 00 00       	mov    $0x0,%edi
f0104e18:	eb 11                	jmp    f0104e2b <strtol+0x3b>
f0104e1a:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104e1f:	3c 2d                	cmp    $0x2d,%al
f0104e21:	75 08                	jne    f0104e2b <strtol+0x3b>
		s++, neg = 1;
f0104e23:	83 c1 01             	add    $0x1,%ecx
f0104e26:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104e2b:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104e31:	75 15                	jne    f0104e48 <strtol+0x58>
f0104e33:	80 39 30             	cmpb   $0x30,(%ecx)
f0104e36:	75 10                	jne    f0104e48 <strtol+0x58>
f0104e38:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104e3c:	75 7c                	jne    f0104eba <strtol+0xca>
		s += 2, base = 16;
f0104e3e:	83 c1 02             	add    $0x2,%ecx
f0104e41:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104e46:	eb 16                	jmp    f0104e5e <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104e48:	85 db                	test   %ebx,%ebx
f0104e4a:	75 12                	jne    f0104e5e <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104e4c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104e51:	80 39 30             	cmpb   $0x30,(%ecx)
f0104e54:	75 08                	jne    f0104e5e <strtol+0x6e>
		s++, base = 8;
f0104e56:	83 c1 01             	add    $0x1,%ecx
f0104e59:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104e5e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e63:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104e66:	0f b6 11             	movzbl (%ecx),%edx
f0104e69:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104e6c:	89 f3                	mov    %esi,%ebx
f0104e6e:	80 fb 09             	cmp    $0x9,%bl
f0104e71:	77 08                	ja     f0104e7b <strtol+0x8b>
			dig = *s - '0';
f0104e73:	0f be d2             	movsbl %dl,%edx
f0104e76:	83 ea 30             	sub    $0x30,%edx
f0104e79:	eb 22                	jmp    f0104e9d <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104e7b:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104e7e:	89 f3                	mov    %esi,%ebx
f0104e80:	80 fb 19             	cmp    $0x19,%bl
f0104e83:	77 08                	ja     f0104e8d <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104e85:	0f be d2             	movsbl %dl,%edx
f0104e88:	83 ea 57             	sub    $0x57,%edx
f0104e8b:	eb 10                	jmp    f0104e9d <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104e8d:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104e90:	89 f3                	mov    %esi,%ebx
f0104e92:	80 fb 19             	cmp    $0x19,%bl
f0104e95:	77 16                	ja     f0104ead <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104e97:	0f be d2             	movsbl %dl,%edx
f0104e9a:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104e9d:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104ea0:	7d 0b                	jge    f0104ead <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104ea2:	83 c1 01             	add    $0x1,%ecx
f0104ea5:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104ea9:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104eab:	eb b9                	jmp    f0104e66 <strtol+0x76>

	if (endptr)
f0104ead:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104eb1:	74 0d                	je     f0104ec0 <strtol+0xd0>
		*endptr = (char *) s;
f0104eb3:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104eb6:	89 0e                	mov    %ecx,(%esi)
f0104eb8:	eb 06                	jmp    f0104ec0 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104eba:	85 db                	test   %ebx,%ebx
f0104ebc:	74 98                	je     f0104e56 <strtol+0x66>
f0104ebe:	eb 9e                	jmp    f0104e5e <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104ec0:	89 c2                	mov    %eax,%edx
f0104ec2:	f7 da                	neg    %edx
f0104ec4:	85 ff                	test   %edi,%edi
f0104ec6:	0f 45 c2             	cmovne %edx,%eax
}
f0104ec9:	5b                   	pop    %ebx
f0104eca:	5e                   	pop    %esi
f0104ecb:	5f                   	pop    %edi
f0104ecc:	5d                   	pop    %ebp
f0104ecd:	c3                   	ret    
f0104ece:	66 90                	xchg   %ax,%ax

f0104ed0 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0104ed0:	fa                   	cli    

	xorw    %ax, %ax
f0104ed1:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0104ed3:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104ed5:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104ed7:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0104ed9:	0f 01 16             	lgdtl  (%esi)
f0104edc:	74 70                	je     f0104f4e <mpsearch1+0x3>
	movl    %cr0, %eax
f0104ede:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0104ee1:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0104ee5:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0104ee8:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0104eee:	08 00                	or     %al,(%eax)

f0104ef0 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0104ef0:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0104ef4:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104ef6:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104ef8:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0104efa:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0104efe:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0104f00:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0104f02:	b8 00 d0 11 00       	mov    $0x11d000,%eax
	movl    %eax, %cr3
f0104f07:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0104f0a:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0104f0d:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0104f12:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0104f15:	8b 25 84 ae 22 f0    	mov    0xf022ae84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0104f1b:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0104f20:	b8 d1 01 10 f0       	mov    $0xf01001d1,%eax
	call    *%eax
f0104f25:	ff d0                	call   *%eax

f0104f27 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0104f27:	eb fe                	jmp    f0104f27 <spin>
f0104f29:	8d 76 00             	lea    0x0(%esi),%esi

f0104f2c <gdt>:
	...
f0104f34:	ff                   	(bad)  
f0104f35:	ff 00                	incl   (%eax)
f0104f37:	00 00                	add    %al,(%eax)
f0104f39:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0104f40:	00                   	.byte 0x0
f0104f41:	92                   	xchg   %eax,%edx
f0104f42:	cf                   	iret   
	...

f0104f44 <gdtdesc>:
f0104f44:	17                   	pop    %ss
f0104f45:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0104f4a <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0104f4a:	90                   	nop

f0104f4b <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0104f4b:	55                   	push   %ebp
f0104f4c:	89 e5                	mov    %esp,%ebp
f0104f4e:	57                   	push   %edi
f0104f4f:	56                   	push   %esi
f0104f50:	53                   	push   %ebx
f0104f51:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104f54:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f0104f5a:	89 c3                	mov    %eax,%ebx
f0104f5c:	c1 eb 0c             	shr    $0xc,%ebx
f0104f5f:	39 cb                	cmp    %ecx,%ebx
f0104f61:	72 12                	jb     f0104f75 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104f63:	50                   	push   %eax
f0104f64:	68 a4 59 10 f0       	push   $0xf01059a4
f0104f69:	6a 57                	push   $0x57
f0104f6b:	68 a5 74 10 f0       	push   $0xf01074a5
f0104f70:	e8 cb b0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104f75:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0104f7b:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104f7d:	89 c2                	mov    %eax,%edx
f0104f7f:	c1 ea 0c             	shr    $0xc,%edx
f0104f82:	39 ca                	cmp    %ecx,%edx
f0104f84:	72 12                	jb     f0104f98 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104f86:	50                   	push   %eax
f0104f87:	68 a4 59 10 f0       	push   $0xf01059a4
f0104f8c:	6a 57                	push   $0x57
f0104f8e:	68 a5 74 10 f0       	push   $0xf01074a5
f0104f93:	e8 a8 b0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104f98:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0104f9e:	eb 2f                	jmp    f0104fcf <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104fa0:	83 ec 04             	sub    $0x4,%esp
f0104fa3:	6a 04                	push   $0x4
f0104fa5:	68 b5 74 10 f0       	push   $0xf01074b5
f0104faa:	53                   	push   %ebx
f0104fab:	e8 e4 fd ff ff       	call   f0104d94 <memcmp>
f0104fb0:	83 c4 10             	add    $0x10,%esp
f0104fb3:	85 c0                	test   %eax,%eax
f0104fb5:	75 15                	jne    f0104fcc <mpsearch1+0x81>
f0104fb7:	89 da                	mov    %ebx,%edx
f0104fb9:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0104fbc:	0f b6 0a             	movzbl (%edx),%ecx
f0104fbf:	01 c8                	add    %ecx,%eax
f0104fc1:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0104fc4:	39 d7                	cmp    %edx,%edi
f0104fc6:	75 f4                	jne    f0104fbc <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104fc8:	84 c0                	test   %al,%al
f0104fca:	74 0e                	je     f0104fda <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0104fcc:	83 c3 10             	add    $0x10,%ebx
f0104fcf:	39 f3                	cmp    %esi,%ebx
f0104fd1:	72 cd                	jb     f0104fa0 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0104fd3:	b8 00 00 00 00       	mov    $0x0,%eax
f0104fd8:	eb 02                	jmp    f0104fdc <mpsearch1+0x91>
f0104fda:	89 d8                	mov    %ebx,%eax
}
f0104fdc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104fdf:	5b                   	pop    %ebx
f0104fe0:	5e                   	pop    %esi
f0104fe1:	5f                   	pop    %edi
f0104fe2:	5d                   	pop    %ebp
f0104fe3:	c3                   	ret    

f0104fe4 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0104fe4:	55                   	push   %ebp
f0104fe5:	89 e5                	mov    %esp,%ebp
f0104fe7:	57                   	push   %edi
f0104fe8:	56                   	push   %esi
f0104fe9:	53                   	push   %ebx
f0104fea:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0104fed:	c7 05 c0 b3 22 f0 20 	movl   $0xf022b020,0xf022b3c0
f0104ff4:	b0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104ff7:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f0104ffe:	75 16                	jne    f0105016 <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105000:	68 00 04 00 00       	push   $0x400
f0105005:	68 a4 59 10 f0       	push   $0xf01059a4
f010500a:	6a 6f                	push   $0x6f
f010500c:	68 a5 74 10 f0       	push   $0xf01074a5
f0105011:	e8 2a b0 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105016:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f010501d:	85 c0                	test   %eax,%eax
f010501f:	74 16                	je     f0105037 <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f0105021:	c1 e0 04             	shl    $0x4,%eax
f0105024:	ba 00 04 00 00       	mov    $0x400,%edx
f0105029:	e8 1d ff ff ff       	call   f0104f4b <mpsearch1>
f010502e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105031:	85 c0                	test   %eax,%eax
f0105033:	75 3c                	jne    f0105071 <mp_init+0x8d>
f0105035:	eb 20                	jmp    f0105057 <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105037:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f010503e:	c1 e0 0a             	shl    $0xa,%eax
f0105041:	2d 00 04 00 00       	sub    $0x400,%eax
f0105046:	ba 00 04 00 00       	mov    $0x400,%edx
f010504b:	e8 fb fe ff ff       	call   f0104f4b <mpsearch1>
f0105050:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105053:	85 c0                	test   %eax,%eax
f0105055:	75 1a                	jne    f0105071 <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0105057:	ba 00 00 01 00       	mov    $0x10000,%edx
f010505c:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105061:	e8 e5 fe ff ff       	call   f0104f4b <mpsearch1>
f0105066:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105069:	85 c0                	test   %eax,%eax
f010506b:	0f 84 5d 02 00 00    	je     f01052ce <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0105071:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105074:	8b 70 04             	mov    0x4(%eax),%esi
f0105077:	85 f6                	test   %esi,%esi
f0105079:	74 06                	je     f0105081 <mp_init+0x9d>
f010507b:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f010507f:	74 15                	je     f0105096 <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f0105081:	83 ec 0c             	sub    $0xc,%esp
f0105084:	68 18 73 10 f0       	push   $0xf0107318
f0105089:	e8 07 e6 ff ff       	call   f0103695 <cprintf>
f010508e:	83 c4 10             	add    $0x10,%esp
f0105091:	e9 38 02 00 00       	jmp    f01052ce <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105096:	89 f0                	mov    %esi,%eax
f0105098:	c1 e8 0c             	shr    $0xc,%eax
f010509b:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01050a1:	72 15                	jb     f01050b8 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01050a3:	56                   	push   %esi
f01050a4:	68 a4 59 10 f0       	push   $0xf01059a4
f01050a9:	68 90 00 00 00       	push   $0x90
f01050ae:	68 a5 74 10 f0       	push   $0xf01074a5
f01050b3:	e8 88 af ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01050b8:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f01050be:	83 ec 04             	sub    $0x4,%esp
f01050c1:	6a 04                	push   $0x4
f01050c3:	68 ba 74 10 f0       	push   $0xf01074ba
f01050c8:	53                   	push   %ebx
f01050c9:	e8 c6 fc ff ff       	call   f0104d94 <memcmp>
f01050ce:	83 c4 10             	add    $0x10,%esp
f01050d1:	85 c0                	test   %eax,%eax
f01050d3:	74 15                	je     f01050ea <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01050d5:	83 ec 0c             	sub    $0xc,%esp
f01050d8:	68 48 73 10 f0       	push   $0xf0107348
f01050dd:	e8 b3 e5 ff ff       	call   f0103695 <cprintf>
f01050e2:	83 c4 10             	add    $0x10,%esp
f01050e5:	e9 e4 01 00 00       	jmp    f01052ce <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01050ea:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f01050ee:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f01050f2:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01050f5:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01050fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01050ff:	eb 0d                	jmp    f010510e <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f0105101:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105108:	f0 
f0105109:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010510b:	83 c0 01             	add    $0x1,%eax
f010510e:	39 c7                	cmp    %eax,%edi
f0105110:	75 ef                	jne    f0105101 <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105112:	84 d2                	test   %dl,%dl
f0105114:	74 15                	je     f010512b <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105116:	83 ec 0c             	sub    $0xc,%esp
f0105119:	68 7c 73 10 f0       	push   $0xf010737c
f010511e:	e8 72 e5 ff ff       	call   f0103695 <cprintf>
f0105123:	83 c4 10             	add    $0x10,%esp
f0105126:	e9 a3 01 00 00       	jmp    f01052ce <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f010512b:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f010512f:	3c 01                	cmp    $0x1,%al
f0105131:	74 1d                	je     f0105150 <mp_init+0x16c>
f0105133:	3c 04                	cmp    $0x4,%al
f0105135:	74 19                	je     f0105150 <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105137:	83 ec 08             	sub    $0x8,%esp
f010513a:	0f b6 c0             	movzbl %al,%eax
f010513d:	50                   	push   %eax
f010513e:	68 a0 73 10 f0       	push   $0xf01073a0
f0105143:	e8 4d e5 ff ff       	call   f0103695 <cprintf>
f0105148:	83 c4 10             	add    $0x10,%esp
f010514b:	e9 7e 01 00 00       	jmp    f01052ce <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105150:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f0105154:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105158:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f010515d:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f0105162:	01 ce                	add    %ecx,%esi
f0105164:	eb 0d                	jmp    f0105173 <mp_init+0x18f>
f0105166:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f010516d:	f0 
f010516e:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105170:	83 c0 01             	add    $0x1,%eax
f0105173:	39 c7                	cmp    %eax,%edi
f0105175:	75 ef                	jne    f0105166 <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105177:	89 d0                	mov    %edx,%eax
f0105179:	02 43 2a             	add    0x2a(%ebx),%al
f010517c:	74 15                	je     f0105193 <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f010517e:	83 ec 0c             	sub    $0xc,%esp
f0105181:	68 c0 73 10 f0       	push   $0xf01073c0
f0105186:	e8 0a e5 ff ff       	call   f0103695 <cprintf>
f010518b:	83 c4 10             	add    $0x10,%esp
f010518e:	e9 3b 01 00 00       	jmp    f01052ce <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f0105193:	85 db                	test   %ebx,%ebx
f0105195:	0f 84 33 01 00 00    	je     f01052ce <mp_init+0x2ea>
		return;
	ismp = 1;
f010519b:	c7 05 00 b0 22 f0 01 	movl   $0x1,0xf022b000
f01051a2:	00 00 00 
	lapicaddr = conf->lapicaddr;
f01051a5:	8b 43 24             	mov    0x24(%ebx),%eax
f01051a8:	a3 00 c0 26 f0       	mov    %eax,0xf026c000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01051ad:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f01051b0:	be 00 00 00 00       	mov    $0x0,%esi
f01051b5:	e9 85 00 00 00       	jmp    f010523f <mp_init+0x25b>
		switch (*p) {
f01051ba:	0f b6 07             	movzbl (%edi),%eax
f01051bd:	84 c0                	test   %al,%al
f01051bf:	74 06                	je     f01051c7 <mp_init+0x1e3>
f01051c1:	3c 04                	cmp    $0x4,%al
f01051c3:	77 55                	ja     f010521a <mp_init+0x236>
f01051c5:	eb 4e                	jmp    f0105215 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01051c7:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01051cb:	74 11                	je     f01051de <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f01051cd:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f01051d4:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01051d9:	a3 c0 b3 22 f0       	mov    %eax,0xf022b3c0
			if (ncpu < NCPU) {
f01051de:	a1 c4 b3 22 f0       	mov    0xf022b3c4,%eax
f01051e3:	83 f8 07             	cmp    $0x7,%eax
f01051e6:	7f 13                	jg     f01051fb <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f01051e8:	6b d0 74             	imul   $0x74,%eax,%edx
f01051eb:	88 82 20 b0 22 f0    	mov    %al,-0xfdd4fe0(%edx)
				ncpu++;
f01051f1:	83 c0 01             	add    $0x1,%eax
f01051f4:	a3 c4 b3 22 f0       	mov    %eax,0xf022b3c4
f01051f9:	eb 15                	jmp    f0105210 <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01051fb:	83 ec 08             	sub    $0x8,%esp
f01051fe:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0105202:	50                   	push   %eax
f0105203:	68 f0 73 10 f0       	push   $0xf01073f0
f0105208:	e8 88 e4 ff ff       	call   f0103695 <cprintf>
f010520d:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105210:	83 c7 14             	add    $0x14,%edi
			continue;
f0105213:	eb 27                	jmp    f010523c <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105215:	83 c7 08             	add    $0x8,%edi
			continue;
f0105218:	eb 22                	jmp    f010523c <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f010521a:	83 ec 08             	sub    $0x8,%esp
f010521d:	0f b6 c0             	movzbl %al,%eax
f0105220:	50                   	push   %eax
f0105221:	68 18 74 10 f0       	push   $0xf0107418
f0105226:	e8 6a e4 ff ff       	call   f0103695 <cprintf>
			ismp = 0;
f010522b:	c7 05 00 b0 22 f0 00 	movl   $0x0,0xf022b000
f0105232:	00 00 00 
			i = conf->entry;
f0105235:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105239:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010523c:	83 c6 01             	add    $0x1,%esi
f010523f:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0105243:	39 c6                	cmp    %eax,%esi
f0105245:	0f 82 6f ff ff ff    	jb     f01051ba <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f010524b:	a1 c0 b3 22 f0       	mov    0xf022b3c0,%eax
f0105250:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105257:	83 3d 00 b0 22 f0 00 	cmpl   $0x0,0xf022b000
f010525e:	75 26                	jne    f0105286 <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105260:	c7 05 c4 b3 22 f0 01 	movl   $0x1,0xf022b3c4
f0105267:	00 00 00 
		lapicaddr = 0;
f010526a:	c7 05 00 c0 26 f0 00 	movl   $0x0,0xf026c000
f0105271:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105274:	83 ec 0c             	sub    $0xc,%esp
f0105277:	68 38 74 10 f0       	push   $0xf0107438
f010527c:	e8 14 e4 ff ff       	call   f0103695 <cprintf>
		return;
f0105281:	83 c4 10             	add    $0x10,%esp
f0105284:	eb 48                	jmp    f01052ce <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105286:	83 ec 04             	sub    $0x4,%esp
f0105289:	ff 35 c4 b3 22 f0    	pushl  0xf022b3c4
f010528f:	0f b6 00             	movzbl (%eax),%eax
f0105292:	50                   	push   %eax
f0105293:	68 bf 74 10 f0       	push   $0xf01074bf
f0105298:	e8 f8 e3 ff ff       	call   f0103695 <cprintf>

	if (mp->imcrp) {
f010529d:	83 c4 10             	add    $0x10,%esp
f01052a0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01052a3:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f01052a7:	74 25                	je     f01052ce <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f01052a9:	83 ec 0c             	sub    $0xc,%esp
f01052ac:	68 64 74 10 f0       	push   $0xf0107464
f01052b1:	e8 df e3 ff ff       	call   f0103695 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01052b6:	ba 22 00 00 00       	mov    $0x22,%edx
f01052bb:	b8 70 00 00 00       	mov    $0x70,%eax
f01052c0:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01052c1:	ba 23 00 00 00       	mov    $0x23,%edx
f01052c6:	ec                   	in     (%dx),%al
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01052c7:	83 c8 01             	or     $0x1,%eax
f01052ca:	ee                   	out    %al,(%dx)
f01052cb:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f01052ce:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01052d1:	5b                   	pop    %ebx
f01052d2:	5e                   	pop    %esi
f01052d3:	5f                   	pop    %edi
f01052d4:	5d                   	pop    %ebp
f01052d5:	c3                   	ret    

f01052d6 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01052d6:	55                   	push   %ebp
f01052d7:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01052d9:	8b 0d 04 c0 26 f0    	mov    0xf026c004,%ecx
f01052df:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01052e2:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01052e4:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f01052e9:	8b 40 20             	mov    0x20(%eax),%eax
}
f01052ec:	5d                   	pop    %ebp
f01052ed:	c3                   	ret    

f01052ee <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01052ee:	55                   	push   %ebp
f01052ef:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01052f1:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f01052f6:	85 c0                	test   %eax,%eax
f01052f8:	74 08                	je     f0105302 <cpunum+0x14>
		return lapic[ID] >> 24;
f01052fa:	8b 40 20             	mov    0x20(%eax),%eax
f01052fd:	c1 e8 18             	shr    $0x18,%eax
f0105300:	eb 05                	jmp    f0105307 <cpunum+0x19>
	return 0;
f0105302:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105307:	5d                   	pop    %ebp
f0105308:	c3                   	ret    

f0105309 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105309:	a1 00 c0 26 f0       	mov    0xf026c000,%eax
f010530e:	85 c0                	test   %eax,%eax
f0105310:	0f 84 21 01 00 00    	je     f0105437 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105316:	55                   	push   %ebp
f0105317:	89 e5                	mov    %esp,%ebp
f0105319:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f010531c:	68 00 10 00 00       	push   $0x1000
f0105321:	50                   	push   %eax
f0105322:	e8 c9 be ff ff       	call   f01011f0 <mmio_map_region>
f0105327:	a3 04 c0 26 f0       	mov    %eax,0xf026c004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f010532c:	ba 27 01 00 00       	mov    $0x127,%edx
f0105331:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105336:	e8 9b ff ff ff       	call   f01052d6 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f010533b:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105340:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105345:	e8 8c ff ff ff       	call   f01052d6 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f010534a:	ba 20 00 02 00       	mov    $0x20020,%edx
f010534f:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105354:	e8 7d ff ff ff       	call   f01052d6 <lapicw>
	lapicw(TICR, 10000000); 
f0105359:	ba 80 96 98 00       	mov    $0x989680,%edx
f010535e:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105363:	e8 6e ff ff ff       	call   f01052d6 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105368:	e8 81 ff ff ff       	call   f01052ee <cpunum>
f010536d:	6b c0 74             	imul   $0x74,%eax,%eax
f0105370:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f0105375:	83 c4 10             	add    $0x10,%esp
f0105378:	39 05 c0 b3 22 f0    	cmp    %eax,0xf022b3c0
f010537e:	74 0f                	je     f010538f <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105380:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105385:	b8 d4 00 00 00       	mov    $0xd4,%eax
f010538a:	e8 47 ff ff ff       	call   f01052d6 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f010538f:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105394:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105399:	e8 38 ff ff ff       	call   f01052d6 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f010539e:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f01053a3:	8b 40 30             	mov    0x30(%eax),%eax
f01053a6:	c1 e8 10             	shr    $0x10,%eax
f01053a9:	3c 03                	cmp    $0x3,%al
f01053ab:	76 0f                	jbe    f01053bc <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f01053ad:	ba 00 00 01 00       	mov    $0x10000,%edx
f01053b2:	b8 d0 00 00 00       	mov    $0xd0,%eax
f01053b7:	e8 1a ff ff ff       	call   f01052d6 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f01053bc:	ba 33 00 00 00       	mov    $0x33,%edx
f01053c1:	b8 dc 00 00 00       	mov    $0xdc,%eax
f01053c6:	e8 0b ff ff ff       	call   f01052d6 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f01053cb:	ba 00 00 00 00       	mov    $0x0,%edx
f01053d0:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01053d5:	e8 fc fe ff ff       	call   f01052d6 <lapicw>
	lapicw(ESR, 0);
f01053da:	ba 00 00 00 00       	mov    $0x0,%edx
f01053df:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01053e4:	e8 ed fe ff ff       	call   f01052d6 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f01053e9:	ba 00 00 00 00       	mov    $0x0,%edx
f01053ee:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01053f3:	e8 de fe ff ff       	call   f01052d6 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f01053f8:	ba 00 00 00 00       	mov    $0x0,%edx
f01053fd:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105402:	e8 cf fe ff ff       	call   f01052d6 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105407:	ba 00 85 08 00       	mov    $0x88500,%edx
f010540c:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105411:	e8 c0 fe ff ff       	call   f01052d6 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105416:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f010541c:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105422:	f6 c4 10             	test   $0x10,%ah
f0105425:	75 f5                	jne    f010541c <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105427:	ba 00 00 00 00       	mov    $0x0,%edx
f010542c:	b8 20 00 00 00       	mov    $0x20,%eax
f0105431:	e8 a0 fe ff ff       	call   f01052d6 <lapicw>
}
f0105436:	c9                   	leave  
f0105437:	f3 c3                	repz ret 

f0105439 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105439:	83 3d 04 c0 26 f0 00 	cmpl   $0x0,0xf026c004
f0105440:	74 13                	je     f0105455 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105442:	55                   	push   %ebp
f0105443:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105445:	ba 00 00 00 00       	mov    $0x0,%edx
f010544a:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010544f:	e8 82 fe ff ff       	call   f01052d6 <lapicw>
}
f0105454:	5d                   	pop    %ebp
f0105455:	f3 c3                	repz ret 

f0105457 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105457:	55                   	push   %ebp
f0105458:	89 e5                	mov    %esp,%ebp
f010545a:	56                   	push   %esi
f010545b:	53                   	push   %ebx
f010545c:	8b 75 08             	mov    0x8(%ebp),%esi
f010545f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105462:	ba 70 00 00 00       	mov    $0x70,%edx
f0105467:	b8 0f 00 00 00       	mov    $0xf,%eax
f010546c:	ee                   	out    %al,(%dx)
f010546d:	ba 71 00 00 00       	mov    $0x71,%edx
f0105472:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105477:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105478:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f010547f:	75 19                	jne    f010549a <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105481:	68 67 04 00 00       	push   $0x467
f0105486:	68 a4 59 10 f0       	push   $0xf01059a4
f010548b:	68 98 00 00 00       	push   $0x98
f0105490:	68 dc 74 10 f0       	push   $0xf01074dc
f0105495:	e8 a6 ab ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f010549a:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f01054a1:	00 00 
	wrv[1] = addr >> 4;
f01054a3:	89 d8                	mov    %ebx,%eax
f01054a5:	c1 e8 04             	shr    $0x4,%eax
f01054a8:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f01054ae:	c1 e6 18             	shl    $0x18,%esi
f01054b1:	89 f2                	mov    %esi,%edx
f01054b3:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01054b8:	e8 19 fe ff ff       	call   f01052d6 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f01054bd:	ba 00 c5 00 00       	mov    $0xc500,%edx
f01054c2:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01054c7:	e8 0a fe ff ff       	call   f01052d6 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f01054cc:	ba 00 85 00 00       	mov    $0x8500,%edx
f01054d1:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01054d6:	e8 fb fd ff ff       	call   f01052d6 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01054db:	c1 eb 0c             	shr    $0xc,%ebx
f01054de:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01054e1:	89 f2                	mov    %esi,%edx
f01054e3:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01054e8:	e8 e9 fd ff ff       	call   f01052d6 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01054ed:	89 da                	mov    %ebx,%edx
f01054ef:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01054f4:	e8 dd fd ff ff       	call   f01052d6 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01054f9:	89 f2                	mov    %esi,%edx
f01054fb:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105500:	e8 d1 fd ff ff       	call   f01052d6 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105505:	89 da                	mov    %ebx,%edx
f0105507:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010550c:	e8 c5 fd ff ff       	call   f01052d6 <lapicw>
		microdelay(200);
	}
}
f0105511:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105514:	5b                   	pop    %ebx
f0105515:	5e                   	pop    %esi
f0105516:	5d                   	pop    %ebp
f0105517:	c3                   	ret    

f0105518 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105518:	55                   	push   %ebp
f0105519:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f010551b:	8b 55 08             	mov    0x8(%ebp),%edx
f010551e:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105524:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105529:	e8 a8 fd ff ff       	call   f01052d6 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f010552e:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f0105534:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010553a:	f6 c4 10             	test   $0x10,%ah
f010553d:	75 f5                	jne    f0105534 <lapic_ipi+0x1c>
		;
}
f010553f:	5d                   	pop    %ebp
f0105540:	c3                   	ret    

f0105541 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105541:	55                   	push   %ebp
f0105542:	89 e5                	mov    %esp,%ebp
f0105544:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105547:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f010554d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105550:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105553:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f010555a:	5d                   	pop    %ebp
f010555b:	c3                   	ret    

f010555c <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f010555c:	55                   	push   %ebp
f010555d:	89 e5                	mov    %esp,%ebp
f010555f:	56                   	push   %esi
f0105560:	53                   	push   %ebx
f0105561:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105564:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105567:	74 14                	je     f010557d <spin_lock+0x21>
f0105569:	8b 73 08             	mov    0x8(%ebx),%esi
f010556c:	e8 7d fd ff ff       	call   f01052ee <cpunum>
f0105571:	6b c0 74             	imul   $0x74,%eax,%eax
f0105574:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105579:	39 c6                	cmp    %eax,%esi
f010557b:	74 07                	je     f0105584 <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f010557d:	ba 01 00 00 00       	mov    $0x1,%edx
f0105582:	eb 20                	jmp    f01055a4 <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105584:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105587:	e8 62 fd ff ff       	call   f01052ee <cpunum>
f010558c:	83 ec 0c             	sub    $0xc,%esp
f010558f:	53                   	push   %ebx
f0105590:	50                   	push   %eax
f0105591:	68 ec 74 10 f0       	push   $0xf01074ec
f0105596:	6a 41                	push   $0x41
f0105598:	68 50 75 10 f0       	push   $0xf0107550
f010559d:	e8 9e aa ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f01055a2:	f3 90                	pause  
f01055a4:	89 d0                	mov    %edx,%eax
f01055a6:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f01055a9:	85 c0                	test   %eax,%eax
f01055ab:	75 f5                	jne    f01055a2 <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f01055ad:	e8 3c fd ff ff       	call   f01052ee <cpunum>
f01055b2:	6b c0 74             	imul   $0x74,%eax,%eax
f01055b5:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01055ba:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f01055bd:	83 c3 0c             	add    $0xc,%ebx

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01055c0:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01055c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01055c7:	eb 0b                	jmp    f01055d4 <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f01055c9:	8b 4a 04             	mov    0x4(%edx),%ecx
f01055cc:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f01055cf:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01055d1:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f01055d4:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f01055da:	76 11                	jbe    f01055ed <spin_lock+0x91>
f01055dc:	83 f8 09             	cmp    $0x9,%eax
f01055df:	7e e8                	jle    f01055c9 <spin_lock+0x6d>
f01055e1:	eb 0a                	jmp    f01055ed <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f01055e3:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f01055ea:	83 c0 01             	add    $0x1,%eax
f01055ed:	83 f8 09             	cmp    $0x9,%eax
f01055f0:	7e f1                	jle    f01055e3 <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f01055f2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01055f5:	5b                   	pop    %ebx
f01055f6:	5e                   	pop    %esi
f01055f7:	5d                   	pop    %ebp
f01055f8:	c3                   	ret    

f01055f9 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f01055f9:	55                   	push   %ebp
f01055fa:	89 e5                	mov    %esp,%ebp
f01055fc:	57                   	push   %edi
f01055fd:	56                   	push   %esi
f01055fe:	53                   	push   %ebx
f01055ff:	83 ec 4c             	sub    $0x4c,%esp
f0105602:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105605:	83 3e 00             	cmpl   $0x0,(%esi)
f0105608:	74 18                	je     f0105622 <spin_unlock+0x29>
f010560a:	8b 5e 08             	mov    0x8(%esi),%ebx
f010560d:	e8 dc fc ff ff       	call   f01052ee <cpunum>
f0105612:	6b c0 74             	imul   $0x74,%eax,%eax
f0105615:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f010561a:	39 c3                	cmp    %eax,%ebx
f010561c:	0f 84 a5 00 00 00    	je     f01056c7 <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105622:	83 ec 04             	sub    $0x4,%esp
f0105625:	6a 28                	push   $0x28
f0105627:	8d 46 0c             	lea    0xc(%esi),%eax
f010562a:	50                   	push   %eax
f010562b:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f010562e:	53                   	push   %ebx
f010562f:	e8 e5 f6 ff ff       	call   f0104d19 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105634:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105637:	0f b6 38             	movzbl (%eax),%edi
f010563a:	8b 76 04             	mov    0x4(%esi),%esi
f010563d:	e8 ac fc ff ff       	call   f01052ee <cpunum>
f0105642:	57                   	push   %edi
f0105643:	56                   	push   %esi
f0105644:	50                   	push   %eax
f0105645:	68 18 75 10 f0       	push   $0xf0107518
f010564a:	e8 46 e0 ff ff       	call   f0103695 <cprintf>
f010564f:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105652:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105655:	eb 54                	jmp    f01056ab <spin_unlock+0xb2>
f0105657:	83 ec 08             	sub    $0x8,%esp
f010565a:	57                   	push   %edi
f010565b:	50                   	push   %eax
f010565c:	e8 36 ec ff ff       	call   f0104297 <debuginfo_eip>
f0105661:	83 c4 10             	add    $0x10,%esp
f0105664:	85 c0                	test   %eax,%eax
f0105666:	78 27                	js     f010568f <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105668:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f010566a:	83 ec 04             	sub    $0x4,%esp
f010566d:	89 c2                	mov    %eax,%edx
f010566f:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105672:	52                   	push   %edx
f0105673:	ff 75 b0             	pushl  -0x50(%ebp)
f0105676:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105679:	ff 75 ac             	pushl  -0x54(%ebp)
f010567c:	ff 75 a8             	pushl  -0x58(%ebp)
f010567f:	50                   	push   %eax
f0105680:	68 60 75 10 f0       	push   $0xf0107560
f0105685:	e8 0b e0 ff ff       	call   f0103695 <cprintf>
f010568a:	83 c4 20             	add    $0x20,%esp
f010568d:	eb 12                	jmp    f01056a1 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f010568f:	83 ec 08             	sub    $0x8,%esp
f0105692:	ff 36                	pushl  (%esi)
f0105694:	68 77 75 10 f0       	push   $0xf0107577
f0105699:	e8 f7 df ff ff       	call   f0103695 <cprintf>
f010569e:	83 c4 10             	add    $0x10,%esp
f01056a1:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f01056a4:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01056a7:	39 c3                	cmp    %eax,%ebx
f01056a9:	74 08                	je     f01056b3 <spin_unlock+0xba>
f01056ab:	89 de                	mov    %ebx,%esi
f01056ad:	8b 03                	mov    (%ebx),%eax
f01056af:	85 c0                	test   %eax,%eax
f01056b1:	75 a4                	jne    f0105657 <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f01056b3:	83 ec 04             	sub    $0x4,%esp
f01056b6:	68 7f 75 10 f0       	push   $0xf010757f
f01056bb:	6a 67                	push   $0x67
f01056bd:	68 50 75 10 f0       	push   $0xf0107550
f01056c2:	e8 79 a9 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f01056c7:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f01056ce:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f01056d5:	b8 00 00 00 00       	mov    $0x0,%eax
f01056da:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f01056dd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01056e0:	5b                   	pop    %ebx
f01056e1:	5e                   	pop    %esi
f01056e2:	5f                   	pop    %edi
f01056e3:	5d                   	pop    %ebp
f01056e4:	c3                   	ret    
f01056e5:	66 90                	xchg   %ax,%ax
f01056e7:	66 90                	xchg   %ax,%ax
f01056e9:	66 90                	xchg   %ax,%ax
f01056eb:	66 90                	xchg   %ax,%ax
f01056ed:	66 90                	xchg   %ax,%ax
f01056ef:	90                   	nop

f01056f0 <__udivdi3>:
f01056f0:	55                   	push   %ebp
f01056f1:	57                   	push   %edi
f01056f2:	56                   	push   %esi
f01056f3:	53                   	push   %ebx
f01056f4:	83 ec 1c             	sub    $0x1c,%esp
f01056f7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01056fb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01056ff:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105703:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105707:	85 f6                	test   %esi,%esi
f0105709:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010570d:	89 ca                	mov    %ecx,%edx
f010570f:	89 f8                	mov    %edi,%eax
f0105711:	75 3d                	jne    f0105750 <__udivdi3+0x60>
f0105713:	39 cf                	cmp    %ecx,%edi
f0105715:	0f 87 c5 00 00 00    	ja     f01057e0 <__udivdi3+0xf0>
f010571b:	85 ff                	test   %edi,%edi
f010571d:	89 fd                	mov    %edi,%ebp
f010571f:	75 0b                	jne    f010572c <__udivdi3+0x3c>
f0105721:	b8 01 00 00 00       	mov    $0x1,%eax
f0105726:	31 d2                	xor    %edx,%edx
f0105728:	f7 f7                	div    %edi
f010572a:	89 c5                	mov    %eax,%ebp
f010572c:	89 c8                	mov    %ecx,%eax
f010572e:	31 d2                	xor    %edx,%edx
f0105730:	f7 f5                	div    %ebp
f0105732:	89 c1                	mov    %eax,%ecx
f0105734:	89 d8                	mov    %ebx,%eax
f0105736:	89 cf                	mov    %ecx,%edi
f0105738:	f7 f5                	div    %ebp
f010573a:	89 c3                	mov    %eax,%ebx
f010573c:	89 d8                	mov    %ebx,%eax
f010573e:	89 fa                	mov    %edi,%edx
f0105740:	83 c4 1c             	add    $0x1c,%esp
f0105743:	5b                   	pop    %ebx
f0105744:	5e                   	pop    %esi
f0105745:	5f                   	pop    %edi
f0105746:	5d                   	pop    %ebp
f0105747:	c3                   	ret    
f0105748:	90                   	nop
f0105749:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105750:	39 ce                	cmp    %ecx,%esi
f0105752:	77 74                	ja     f01057c8 <__udivdi3+0xd8>
f0105754:	0f bd fe             	bsr    %esi,%edi
f0105757:	83 f7 1f             	xor    $0x1f,%edi
f010575a:	0f 84 98 00 00 00    	je     f01057f8 <__udivdi3+0x108>
f0105760:	bb 20 00 00 00       	mov    $0x20,%ebx
f0105765:	89 f9                	mov    %edi,%ecx
f0105767:	89 c5                	mov    %eax,%ebp
f0105769:	29 fb                	sub    %edi,%ebx
f010576b:	d3 e6                	shl    %cl,%esi
f010576d:	89 d9                	mov    %ebx,%ecx
f010576f:	d3 ed                	shr    %cl,%ebp
f0105771:	89 f9                	mov    %edi,%ecx
f0105773:	d3 e0                	shl    %cl,%eax
f0105775:	09 ee                	or     %ebp,%esi
f0105777:	89 d9                	mov    %ebx,%ecx
f0105779:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010577d:	89 d5                	mov    %edx,%ebp
f010577f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105783:	d3 ed                	shr    %cl,%ebp
f0105785:	89 f9                	mov    %edi,%ecx
f0105787:	d3 e2                	shl    %cl,%edx
f0105789:	89 d9                	mov    %ebx,%ecx
f010578b:	d3 e8                	shr    %cl,%eax
f010578d:	09 c2                	or     %eax,%edx
f010578f:	89 d0                	mov    %edx,%eax
f0105791:	89 ea                	mov    %ebp,%edx
f0105793:	f7 f6                	div    %esi
f0105795:	89 d5                	mov    %edx,%ebp
f0105797:	89 c3                	mov    %eax,%ebx
f0105799:	f7 64 24 0c          	mull   0xc(%esp)
f010579d:	39 d5                	cmp    %edx,%ebp
f010579f:	72 10                	jb     f01057b1 <__udivdi3+0xc1>
f01057a1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01057a5:	89 f9                	mov    %edi,%ecx
f01057a7:	d3 e6                	shl    %cl,%esi
f01057a9:	39 c6                	cmp    %eax,%esi
f01057ab:	73 07                	jae    f01057b4 <__udivdi3+0xc4>
f01057ad:	39 d5                	cmp    %edx,%ebp
f01057af:	75 03                	jne    f01057b4 <__udivdi3+0xc4>
f01057b1:	83 eb 01             	sub    $0x1,%ebx
f01057b4:	31 ff                	xor    %edi,%edi
f01057b6:	89 d8                	mov    %ebx,%eax
f01057b8:	89 fa                	mov    %edi,%edx
f01057ba:	83 c4 1c             	add    $0x1c,%esp
f01057bd:	5b                   	pop    %ebx
f01057be:	5e                   	pop    %esi
f01057bf:	5f                   	pop    %edi
f01057c0:	5d                   	pop    %ebp
f01057c1:	c3                   	ret    
f01057c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01057c8:	31 ff                	xor    %edi,%edi
f01057ca:	31 db                	xor    %ebx,%ebx
f01057cc:	89 d8                	mov    %ebx,%eax
f01057ce:	89 fa                	mov    %edi,%edx
f01057d0:	83 c4 1c             	add    $0x1c,%esp
f01057d3:	5b                   	pop    %ebx
f01057d4:	5e                   	pop    %esi
f01057d5:	5f                   	pop    %edi
f01057d6:	5d                   	pop    %ebp
f01057d7:	c3                   	ret    
f01057d8:	90                   	nop
f01057d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01057e0:	89 d8                	mov    %ebx,%eax
f01057e2:	f7 f7                	div    %edi
f01057e4:	31 ff                	xor    %edi,%edi
f01057e6:	89 c3                	mov    %eax,%ebx
f01057e8:	89 d8                	mov    %ebx,%eax
f01057ea:	89 fa                	mov    %edi,%edx
f01057ec:	83 c4 1c             	add    $0x1c,%esp
f01057ef:	5b                   	pop    %ebx
f01057f0:	5e                   	pop    %esi
f01057f1:	5f                   	pop    %edi
f01057f2:	5d                   	pop    %ebp
f01057f3:	c3                   	ret    
f01057f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01057f8:	39 ce                	cmp    %ecx,%esi
f01057fa:	72 0c                	jb     f0105808 <__udivdi3+0x118>
f01057fc:	31 db                	xor    %ebx,%ebx
f01057fe:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0105802:	0f 87 34 ff ff ff    	ja     f010573c <__udivdi3+0x4c>
f0105808:	bb 01 00 00 00       	mov    $0x1,%ebx
f010580d:	e9 2a ff ff ff       	jmp    f010573c <__udivdi3+0x4c>
f0105812:	66 90                	xchg   %ax,%ax
f0105814:	66 90                	xchg   %ax,%ax
f0105816:	66 90                	xchg   %ax,%ax
f0105818:	66 90                	xchg   %ax,%ax
f010581a:	66 90                	xchg   %ax,%ax
f010581c:	66 90                	xchg   %ax,%ax
f010581e:	66 90                	xchg   %ax,%ax

f0105820 <__umoddi3>:
f0105820:	55                   	push   %ebp
f0105821:	57                   	push   %edi
f0105822:	56                   	push   %esi
f0105823:	53                   	push   %ebx
f0105824:	83 ec 1c             	sub    $0x1c,%esp
f0105827:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010582b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010582f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105833:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105837:	85 d2                	test   %edx,%edx
f0105839:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010583d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105841:	89 f3                	mov    %esi,%ebx
f0105843:	89 3c 24             	mov    %edi,(%esp)
f0105846:	89 74 24 04          	mov    %esi,0x4(%esp)
f010584a:	75 1c                	jne    f0105868 <__umoddi3+0x48>
f010584c:	39 f7                	cmp    %esi,%edi
f010584e:	76 50                	jbe    f01058a0 <__umoddi3+0x80>
f0105850:	89 c8                	mov    %ecx,%eax
f0105852:	89 f2                	mov    %esi,%edx
f0105854:	f7 f7                	div    %edi
f0105856:	89 d0                	mov    %edx,%eax
f0105858:	31 d2                	xor    %edx,%edx
f010585a:	83 c4 1c             	add    $0x1c,%esp
f010585d:	5b                   	pop    %ebx
f010585e:	5e                   	pop    %esi
f010585f:	5f                   	pop    %edi
f0105860:	5d                   	pop    %ebp
f0105861:	c3                   	ret    
f0105862:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105868:	39 f2                	cmp    %esi,%edx
f010586a:	89 d0                	mov    %edx,%eax
f010586c:	77 52                	ja     f01058c0 <__umoddi3+0xa0>
f010586e:	0f bd ea             	bsr    %edx,%ebp
f0105871:	83 f5 1f             	xor    $0x1f,%ebp
f0105874:	75 5a                	jne    f01058d0 <__umoddi3+0xb0>
f0105876:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010587a:	0f 82 e0 00 00 00    	jb     f0105960 <__umoddi3+0x140>
f0105880:	39 0c 24             	cmp    %ecx,(%esp)
f0105883:	0f 86 d7 00 00 00    	jbe    f0105960 <__umoddi3+0x140>
f0105889:	8b 44 24 08          	mov    0x8(%esp),%eax
f010588d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105891:	83 c4 1c             	add    $0x1c,%esp
f0105894:	5b                   	pop    %ebx
f0105895:	5e                   	pop    %esi
f0105896:	5f                   	pop    %edi
f0105897:	5d                   	pop    %ebp
f0105898:	c3                   	ret    
f0105899:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01058a0:	85 ff                	test   %edi,%edi
f01058a2:	89 fd                	mov    %edi,%ebp
f01058a4:	75 0b                	jne    f01058b1 <__umoddi3+0x91>
f01058a6:	b8 01 00 00 00       	mov    $0x1,%eax
f01058ab:	31 d2                	xor    %edx,%edx
f01058ad:	f7 f7                	div    %edi
f01058af:	89 c5                	mov    %eax,%ebp
f01058b1:	89 f0                	mov    %esi,%eax
f01058b3:	31 d2                	xor    %edx,%edx
f01058b5:	f7 f5                	div    %ebp
f01058b7:	89 c8                	mov    %ecx,%eax
f01058b9:	f7 f5                	div    %ebp
f01058bb:	89 d0                	mov    %edx,%eax
f01058bd:	eb 99                	jmp    f0105858 <__umoddi3+0x38>
f01058bf:	90                   	nop
f01058c0:	89 c8                	mov    %ecx,%eax
f01058c2:	89 f2                	mov    %esi,%edx
f01058c4:	83 c4 1c             	add    $0x1c,%esp
f01058c7:	5b                   	pop    %ebx
f01058c8:	5e                   	pop    %esi
f01058c9:	5f                   	pop    %edi
f01058ca:	5d                   	pop    %ebp
f01058cb:	c3                   	ret    
f01058cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01058d0:	8b 34 24             	mov    (%esp),%esi
f01058d3:	bf 20 00 00 00       	mov    $0x20,%edi
f01058d8:	89 e9                	mov    %ebp,%ecx
f01058da:	29 ef                	sub    %ebp,%edi
f01058dc:	d3 e0                	shl    %cl,%eax
f01058de:	89 f9                	mov    %edi,%ecx
f01058e0:	89 f2                	mov    %esi,%edx
f01058e2:	d3 ea                	shr    %cl,%edx
f01058e4:	89 e9                	mov    %ebp,%ecx
f01058e6:	09 c2                	or     %eax,%edx
f01058e8:	89 d8                	mov    %ebx,%eax
f01058ea:	89 14 24             	mov    %edx,(%esp)
f01058ed:	89 f2                	mov    %esi,%edx
f01058ef:	d3 e2                	shl    %cl,%edx
f01058f1:	89 f9                	mov    %edi,%ecx
f01058f3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01058f7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01058fb:	d3 e8                	shr    %cl,%eax
f01058fd:	89 e9                	mov    %ebp,%ecx
f01058ff:	89 c6                	mov    %eax,%esi
f0105901:	d3 e3                	shl    %cl,%ebx
f0105903:	89 f9                	mov    %edi,%ecx
f0105905:	89 d0                	mov    %edx,%eax
f0105907:	d3 e8                	shr    %cl,%eax
f0105909:	89 e9                	mov    %ebp,%ecx
f010590b:	09 d8                	or     %ebx,%eax
f010590d:	89 d3                	mov    %edx,%ebx
f010590f:	89 f2                	mov    %esi,%edx
f0105911:	f7 34 24             	divl   (%esp)
f0105914:	89 d6                	mov    %edx,%esi
f0105916:	d3 e3                	shl    %cl,%ebx
f0105918:	f7 64 24 04          	mull   0x4(%esp)
f010591c:	39 d6                	cmp    %edx,%esi
f010591e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105922:	89 d1                	mov    %edx,%ecx
f0105924:	89 c3                	mov    %eax,%ebx
f0105926:	72 08                	jb     f0105930 <__umoddi3+0x110>
f0105928:	75 11                	jne    f010593b <__umoddi3+0x11b>
f010592a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010592e:	73 0b                	jae    f010593b <__umoddi3+0x11b>
f0105930:	2b 44 24 04          	sub    0x4(%esp),%eax
f0105934:	1b 14 24             	sbb    (%esp),%edx
f0105937:	89 d1                	mov    %edx,%ecx
f0105939:	89 c3                	mov    %eax,%ebx
f010593b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010593f:	29 da                	sub    %ebx,%edx
f0105941:	19 ce                	sbb    %ecx,%esi
f0105943:	89 f9                	mov    %edi,%ecx
f0105945:	89 f0                	mov    %esi,%eax
f0105947:	d3 e0                	shl    %cl,%eax
f0105949:	89 e9                	mov    %ebp,%ecx
f010594b:	d3 ea                	shr    %cl,%edx
f010594d:	89 e9                	mov    %ebp,%ecx
f010594f:	d3 ee                	shr    %cl,%esi
f0105951:	09 d0                	or     %edx,%eax
f0105953:	89 f2                	mov    %esi,%edx
f0105955:	83 c4 1c             	add    $0x1c,%esp
f0105958:	5b                   	pop    %ebx
f0105959:	5e                   	pop    %esi
f010595a:	5f                   	pop    %edi
f010595b:	5d                   	pop    %ebp
f010595c:	c3                   	ret    
f010595d:	8d 76 00             	lea    0x0(%esi),%esi
f0105960:	29 f9                	sub    %edi,%ecx
f0105962:	19 d6                	sbb    %edx,%esi
f0105964:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105968:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010596c:	e9 18 ff ff ff       	jmp    f0105889 <__umoddi3+0x69>


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
f010005c:	e8 d9 52 00 00       	call   f010533a <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 e0 59 10 f0       	push   $0xf01059e0
f010006d:	e8 22 36 00 00       	call   f0103694 <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 f2 35 00 00       	call   f010366e <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 69 5d 10 f0 	movl   $0xf0105d69,(%esp)
f0100083:	e8 0c 36 00 00       	call   f0103694 <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 6c 08 00 00       	call   f0100901 <monitor>
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
f01000b3:	e8 61 4c 00 00       	call   f0104d19 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 74 05 00 00       	call   f0100631 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 4c 5a 10 f0       	push   $0xf0105a4c
f01000ca:	e8 c5 35 00 00       	call   f0103694 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 68 11 00 00       	call   f010123c <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 ca 2d 00 00       	call   f0102ea3 <env_init>
	trap_init();
f01000d9:	e8 a4 36 00 00       	call   f0103782 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 4d 4f 00 00       	call   f0105030 <mp_init>
	lapic_init();
f01000e3:	e8 6d 52 00 00       	call   f0105355 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 ce 34 00 00       	call   f01035bb <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 f3 11 f0 	movl   $0xf011f3c0,(%esp)
f01000f4:	e8 af 54 00 00       	call   f01055a8 <spin_lock>
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
f010010a:	68 04 5a 10 f0       	push   $0xf0105a04
f010010f:	6a 53                	push   $0x53
f0100111:	68 67 5a 10 f0       	push   $0xf0105a67
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 96 4f 10 f0       	mov    $0xf0104f96,%eax
f0100123:	2d 1c 4f 10 f0       	sub    $0xf0104f1c,%eax
f0100128:	50                   	push   %eax
f0100129:	68 1c 4f 10 f0       	push   $0xf0104f1c
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 2e 4c 00 00       	call   f0104d66 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 20 b0 22 f0       	mov    $0xf022b020,%ebx
f0100140:	eb 4d                	jmp    f010018f <i386_init+0xf5>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 f3 51 00 00       	call   f010533a <cpunum>
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
f010017c:	e8 22 53 00 00       	call   f01054a3 <lapic_startap>
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
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_primes, ENV_TYPE_USER);
f010019f:	83 ec 08             	sub    $0x8,%esp
f01001a2:	6a 00                	push   $0x0
f01001a4:	68 c8 0b 22 f0       	push   $0xf0220bc8
f01001a9:	e8 bd 2e 00 00       	call   f010306b <env_create>
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001ae:	e8 9f 3e 00 00       	call   f0104052 <sched_yield>

f01001b3 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001b3:	55                   	push   %ebp
f01001b4:	89 e5                	mov    %esp,%ebp
f01001b6:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001b9:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001be:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001c3:	77 12                	ja     f01001d7 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001c5:	50                   	push   %eax
f01001c6:	68 28 5a 10 f0       	push   $0xf0105a28
f01001cb:	6a 6a                	push   $0x6a
f01001cd:	68 67 5a 10 f0       	push   $0xf0105a67
f01001d2:	e8 69 fe ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01001d7:	05 00 00 00 10       	add    $0x10000000,%eax
f01001dc:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001df:	e8 56 51 00 00       	call   f010533a <cpunum>
f01001e4:	83 ec 08             	sub    $0x8,%esp
f01001e7:	50                   	push   %eax
f01001e8:	68 73 5a 10 f0       	push   $0xf0105a73
f01001ed:	e8 a2 34 00 00       	call   f0103694 <cprintf>

	lapic_init();
f01001f2:	e8 5e 51 00 00       	call   f0105355 <lapic_init>
	env_init_percpu();
f01001f7:	e8 77 2c 00 00       	call   f0102e73 <env_init_percpu>
	trap_init_percpu();
f01001fc:	e8 a7 34 00 00       	call   f01036a8 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100201:	e8 34 51 00 00       	call   f010533a <cpunum>
f0100206:	6b d0 74             	imul   $0x74,%eax,%edx
f0100209:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f010020f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100214:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100218:	c7 04 24 c0 f3 11 f0 	movl   $0xf011f3c0,(%esp)
f010021f:	e8 84 53 00 00       	call   f01055a8 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();
	sched_yield();//选择进程运行
f0100224:	e8 29 3e 00 00       	call   f0104052 <sched_yield>

f0100229 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100229:	55                   	push   %ebp
f010022a:	89 e5                	mov    %esp,%ebp
f010022c:	53                   	push   %ebx
f010022d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100230:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100233:	ff 75 0c             	pushl  0xc(%ebp)
f0100236:	ff 75 08             	pushl  0x8(%ebp)
f0100239:	68 89 5a 10 f0       	push   $0xf0105a89
f010023e:	e8 51 34 00 00       	call   f0103694 <cprintf>
	vcprintf(fmt, ap);
f0100243:	83 c4 08             	add    $0x8,%esp
f0100246:	53                   	push   %ebx
f0100247:	ff 75 10             	pushl  0x10(%ebp)
f010024a:	e8 1f 34 00 00       	call   f010366e <vcprintf>
	cprintf("\n");
f010024f:	c7 04 24 69 5d 10 f0 	movl   $0xf0105d69,(%esp)
f0100256:	e8 39 34 00 00       	call   f0103694 <cprintf>
	va_end(ap);
}
f010025b:	83 c4 10             	add    $0x10,%esp
f010025e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100261:	c9                   	leave  
f0100262:	c3                   	ret    

f0100263 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100263:	55                   	push   %ebp
f0100264:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100266:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010026b:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010026c:	a8 01                	test   $0x1,%al
f010026e:	74 0b                	je     f010027b <serial_proc_data+0x18>
f0100270:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100275:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100276:	0f b6 c0             	movzbl %al,%eax
f0100279:	eb 05                	jmp    f0100280 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010027b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100280:	5d                   	pop    %ebp
f0100281:	c3                   	ret    

f0100282 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100282:	55                   	push   %ebp
f0100283:	89 e5                	mov    %esp,%ebp
f0100285:	53                   	push   %ebx
f0100286:	83 ec 04             	sub    $0x4,%esp
f0100289:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010028b:	eb 2b                	jmp    f01002b8 <cons_intr+0x36>
		if (c == 0)
f010028d:	85 c0                	test   %eax,%eax
f010028f:	74 27                	je     f01002b8 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100291:	8b 0d 24 a2 22 f0    	mov    0xf022a224,%ecx
f0100297:	8d 51 01             	lea    0x1(%ecx),%edx
f010029a:	89 15 24 a2 22 f0    	mov    %edx,0xf022a224
f01002a0:	88 81 20 a0 22 f0    	mov    %al,-0xfdd5fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002a6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002ac:	75 0a                	jne    f01002b8 <cons_intr+0x36>
			cons.wpos = 0;
f01002ae:	c7 05 24 a2 22 f0 00 	movl   $0x0,0xf022a224
f01002b5:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002b8:	ff d3                	call   *%ebx
f01002ba:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002bd:	75 ce                	jne    f010028d <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002bf:	83 c4 04             	add    $0x4,%esp
f01002c2:	5b                   	pop    %ebx
f01002c3:	5d                   	pop    %ebp
f01002c4:	c3                   	ret    

f01002c5 <kbd_proc_data>:
f01002c5:	ba 64 00 00 00       	mov    $0x64,%edx
f01002ca:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01002cb:	a8 01                	test   $0x1,%al
f01002cd:	0f 84 f0 00 00 00    	je     f01003c3 <kbd_proc_data+0xfe>
f01002d3:	ba 60 00 00 00       	mov    $0x60,%edx
f01002d8:	ec                   	in     (%dx),%al
f01002d9:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002db:	3c e0                	cmp    $0xe0,%al
f01002dd:	75 0d                	jne    f01002ec <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01002df:	83 0d 00 a0 22 f0 40 	orl    $0x40,0xf022a000
		return 0;
f01002e6:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002eb:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01002ec:	55                   	push   %ebp
f01002ed:	89 e5                	mov    %esp,%ebp
f01002ef:	53                   	push   %ebx
f01002f0:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01002f3:	84 c0                	test   %al,%al
f01002f5:	79 36                	jns    f010032d <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01002f7:	8b 0d 00 a0 22 f0    	mov    0xf022a000,%ecx
f01002fd:	89 cb                	mov    %ecx,%ebx
f01002ff:	83 e3 40             	and    $0x40,%ebx
f0100302:	83 e0 7f             	and    $0x7f,%eax
f0100305:	85 db                	test   %ebx,%ebx
f0100307:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010030a:	0f b6 d2             	movzbl %dl,%edx
f010030d:	0f b6 82 00 5c 10 f0 	movzbl -0xfefa400(%edx),%eax
f0100314:	83 c8 40             	or     $0x40,%eax
f0100317:	0f b6 c0             	movzbl %al,%eax
f010031a:	f7 d0                	not    %eax
f010031c:	21 c8                	and    %ecx,%eax
f010031e:	a3 00 a0 22 f0       	mov    %eax,0xf022a000
		return 0;
f0100323:	b8 00 00 00 00       	mov    $0x0,%eax
f0100328:	e9 9e 00 00 00       	jmp    f01003cb <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f010032d:	8b 0d 00 a0 22 f0    	mov    0xf022a000,%ecx
f0100333:	f6 c1 40             	test   $0x40,%cl
f0100336:	74 0e                	je     f0100346 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100338:	83 c8 80             	or     $0xffffff80,%eax
f010033b:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010033d:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100340:	89 0d 00 a0 22 f0    	mov    %ecx,0xf022a000
	}

	shift |= shiftcode[data];
f0100346:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100349:	0f b6 82 00 5c 10 f0 	movzbl -0xfefa400(%edx),%eax
f0100350:	0b 05 00 a0 22 f0    	or     0xf022a000,%eax
f0100356:	0f b6 8a 00 5b 10 f0 	movzbl -0xfefa500(%edx),%ecx
f010035d:	31 c8                	xor    %ecx,%eax
f010035f:	a3 00 a0 22 f0       	mov    %eax,0xf022a000

	c = charcode[shift & (CTL | SHIFT)][data];
f0100364:	89 c1                	mov    %eax,%ecx
f0100366:	83 e1 03             	and    $0x3,%ecx
f0100369:	8b 0c 8d e0 5a 10 f0 	mov    -0xfefa520(,%ecx,4),%ecx
f0100370:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100374:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100377:	a8 08                	test   $0x8,%al
f0100379:	74 1b                	je     f0100396 <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f010037b:	89 da                	mov    %ebx,%edx
f010037d:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100380:	83 f9 19             	cmp    $0x19,%ecx
f0100383:	77 05                	ja     f010038a <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100385:	83 eb 20             	sub    $0x20,%ebx
f0100388:	eb 0c                	jmp    f0100396 <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f010038a:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010038d:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100390:	83 fa 19             	cmp    $0x19,%edx
f0100393:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100396:	f7 d0                	not    %eax
f0100398:	a8 06                	test   $0x6,%al
f010039a:	75 2d                	jne    f01003c9 <kbd_proc_data+0x104>
f010039c:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003a2:	75 25                	jne    f01003c9 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01003a4:	83 ec 0c             	sub    $0xc,%esp
f01003a7:	68 a3 5a 10 f0       	push   $0xf0105aa3
f01003ac:	e8 e3 32 00 00       	call   f0103694 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003b1:	ba 92 00 00 00       	mov    $0x92,%edx
f01003b6:	b8 03 00 00 00       	mov    $0x3,%eax
f01003bb:	ee                   	out    %al,(%dx)
f01003bc:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003bf:	89 d8                	mov    %ebx,%eax
f01003c1:	eb 08                	jmp    f01003cb <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003c8:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003c9:	89 d8                	mov    %ebx,%eax
}
f01003cb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003ce:	c9                   	leave  
f01003cf:	c3                   	ret    

f01003d0 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003d0:	55                   	push   %ebp
f01003d1:	89 e5                	mov    %esp,%ebp
f01003d3:	57                   	push   %edi
f01003d4:	56                   	push   %esi
f01003d5:	53                   	push   %ebx
f01003d6:	83 ec 1c             	sub    $0x1c,%esp
f01003d9:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003db:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003e0:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003e5:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003ea:	eb 09                	jmp    f01003f5 <cons_putc+0x25>
f01003ec:	89 ca                	mov    %ecx,%edx
f01003ee:	ec                   	in     (%dx),%al
f01003ef:	ec                   	in     (%dx),%al
f01003f0:	ec                   	in     (%dx),%al
f01003f1:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01003f2:	83 c3 01             	add    $0x1,%ebx
f01003f5:	89 f2                	mov    %esi,%edx
f01003f7:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01003f8:	a8 20                	test   $0x20,%al
f01003fa:	75 08                	jne    f0100404 <cons_putc+0x34>
f01003fc:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100402:	7e e8                	jle    f01003ec <cons_putc+0x1c>
f0100404:	89 f8                	mov    %edi,%eax
f0100406:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100409:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010040e:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010040f:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100414:	be 79 03 00 00       	mov    $0x379,%esi
f0100419:	b9 84 00 00 00       	mov    $0x84,%ecx
f010041e:	eb 09                	jmp    f0100429 <cons_putc+0x59>
f0100420:	89 ca                	mov    %ecx,%edx
f0100422:	ec                   	in     (%dx),%al
f0100423:	ec                   	in     (%dx),%al
f0100424:	ec                   	in     (%dx),%al
f0100425:	ec                   	in     (%dx),%al
f0100426:	83 c3 01             	add    $0x1,%ebx
f0100429:	89 f2                	mov    %esi,%edx
f010042b:	ec                   	in     (%dx),%al
f010042c:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100432:	7f 04                	jg     f0100438 <cons_putc+0x68>
f0100434:	84 c0                	test   %al,%al
f0100436:	79 e8                	jns    f0100420 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100438:	ba 78 03 00 00       	mov    $0x378,%edx
f010043d:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100441:	ee                   	out    %al,(%dx)
f0100442:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100447:	b8 0d 00 00 00       	mov    $0xd,%eax
f010044c:	ee                   	out    %al,(%dx)
f010044d:	b8 08 00 00 00       	mov    $0x8,%eax
f0100452:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100453:	89 fa                	mov    %edi,%edx
f0100455:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010045b:	89 f8                	mov    %edi,%eax
f010045d:	80 cc 07             	or     $0x7,%ah
f0100460:	85 d2                	test   %edx,%edx
f0100462:	0f 44 f8             	cmove  %eax,%edi
    // 	    }
	//     else {
    //           c |= 0x0400;
    // 	    }
	// }
	switch (c & 0xff) {
f0100465:	89 f8                	mov    %edi,%eax
f0100467:	0f b6 c0             	movzbl %al,%eax
f010046a:	83 f8 09             	cmp    $0x9,%eax
f010046d:	74 74                	je     f01004e3 <cons_putc+0x113>
f010046f:	83 f8 09             	cmp    $0x9,%eax
f0100472:	7f 0a                	jg     f010047e <cons_putc+0xae>
f0100474:	83 f8 08             	cmp    $0x8,%eax
f0100477:	74 14                	je     f010048d <cons_putc+0xbd>
f0100479:	e9 99 00 00 00       	jmp    f0100517 <cons_putc+0x147>
f010047e:	83 f8 0a             	cmp    $0xa,%eax
f0100481:	74 3a                	je     f01004bd <cons_putc+0xed>
f0100483:	83 f8 0d             	cmp    $0xd,%eax
f0100486:	74 3d                	je     f01004c5 <cons_putc+0xf5>
f0100488:	e9 8a 00 00 00       	jmp    f0100517 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010048d:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f0100494:	66 85 c0             	test   %ax,%ax
f0100497:	0f 84 e6 00 00 00    	je     f0100583 <cons_putc+0x1b3>
			crt_pos--;
f010049d:	83 e8 01             	sub    $0x1,%eax
f01004a0:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	66 81 e7 00 ff       	and    $0xff00,%di
f01004ae:	83 cf 20             	or     $0x20,%edi
f01004b1:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f01004b7:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004bb:	eb 78                	jmp    f0100535 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004bd:	66 83 05 28 a2 22 f0 	addw   $0x50,0xf022a228
f01004c4:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004c5:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f01004cc:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004d2:	c1 e8 16             	shr    $0x16,%eax
f01004d5:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004d8:	c1 e0 04             	shl    $0x4,%eax
f01004db:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228
f01004e1:	eb 52                	jmp    f0100535 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01004e3:	b8 20 00 00 00       	mov    $0x20,%eax
f01004e8:	e8 e3 fe ff ff       	call   f01003d0 <cons_putc>
		cons_putc(' ');
f01004ed:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f2:	e8 d9 fe ff ff       	call   f01003d0 <cons_putc>
		cons_putc(' ');
f01004f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01004fc:	e8 cf fe ff ff       	call   f01003d0 <cons_putc>
		cons_putc(' ');
f0100501:	b8 20 00 00 00       	mov    $0x20,%eax
f0100506:	e8 c5 fe ff ff       	call   f01003d0 <cons_putc>
		cons_putc(' ');
f010050b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100510:	e8 bb fe ff ff       	call   f01003d0 <cons_putc>
f0100515:	eb 1e                	jmp    f0100535 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100517:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f010051e:	8d 50 01             	lea    0x1(%eax),%edx
f0100521:	66 89 15 28 a2 22 f0 	mov    %dx,0xf022a228
f0100528:	0f b7 c0             	movzwl %ax,%eax
f010052b:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f0100531:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100535:	66 81 3d 28 a2 22 f0 	cmpw   $0x7cf,0xf022a228
f010053c:	cf 07 
f010053e:	76 43                	jbe    f0100583 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100540:	a1 2c a2 22 f0       	mov    0xf022a22c,%eax
f0100545:	83 ec 04             	sub    $0x4,%esp
f0100548:	68 00 0f 00 00       	push   $0xf00
f010054d:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100553:	52                   	push   %edx
f0100554:	50                   	push   %eax
f0100555:	e8 0c 48 00 00       	call   f0104d66 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010055a:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f0100560:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100566:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010056c:	83 c4 10             	add    $0x10,%esp
f010056f:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100574:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100577:	39 d0                	cmp    %edx,%eax
f0100579:	75 f4                	jne    f010056f <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010057b:	66 83 2d 28 a2 22 f0 	subw   $0x50,0xf022a228
f0100582:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100583:	8b 0d 30 a2 22 f0    	mov    0xf022a230,%ecx
f0100589:	b8 0e 00 00 00       	mov    $0xe,%eax
f010058e:	89 ca                	mov    %ecx,%edx
f0100590:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100591:	0f b7 1d 28 a2 22 f0 	movzwl 0xf022a228,%ebx
f0100598:	8d 71 01             	lea    0x1(%ecx),%esi
f010059b:	89 d8                	mov    %ebx,%eax
f010059d:	66 c1 e8 08          	shr    $0x8,%ax
f01005a1:	89 f2                	mov    %esi,%edx
f01005a3:	ee                   	out    %al,(%dx)
f01005a4:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005a9:	89 ca                	mov    %ecx,%edx
f01005ab:	ee                   	out    %al,(%dx)
f01005ac:	89 d8                	mov    %ebx,%eax
f01005ae:	89 f2                	mov    %esi,%edx
f01005b0:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005b1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005b4:	5b                   	pop    %ebx
f01005b5:	5e                   	pop    %esi
f01005b6:	5f                   	pop    %edi
f01005b7:	5d                   	pop    %ebp
f01005b8:	c3                   	ret    

f01005b9 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005b9:	80 3d 34 a2 22 f0 00 	cmpb   $0x0,0xf022a234
f01005c0:	74 11                	je     f01005d3 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005c2:	55                   	push   %ebp
f01005c3:	89 e5                	mov    %esp,%ebp
f01005c5:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005c8:	b8 63 02 10 f0       	mov    $0xf0100263,%eax
f01005cd:	e8 b0 fc ff ff       	call   f0100282 <cons_intr>
}
f01005d2:	c9                   	leave  
f01005d3:	f3 c3                	repz ret 

f01005d5 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005d5:	55                   	push   %ebp
f01005d6:	89 e5                	mov    %esp,%ebp
f01005d8:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005db:	b8 c5 02 10 f0       	mov    $0xf01002c5,%eax
f01005e0:	e8 9d fc ff ff       	call   f0100282 <cons_intr>
}
f01005e5:	c9                   	leave  
f01005e6:	c3                   	ret    

f01005e7 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01005e7:	55                   	push   %ebp
f01005e8:	89 e5                	mov    %esp,%ebp
f01005ea:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01005ed:	e8 c7 ff ff ff       	call   f01005b9 <serial_intr>
	kbd_intr();
f01005f2:	e8 de ff ff ff       	call   f01005d5 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01005f7:	a1 20 a2 22 f0       	mov    0xf022a220,%eax
f01005fc:	3b 05 24 a2 22 f0    	cmp    0xf022a224,%eax
f0100602:	74 26                	je     f010062a <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100604:	8d 50 01             	lea    0x1(%eax),%edx
f0100607:	89 15 20 a2 22 f0    	mov    %edx,0xf022a220
f010060d:	0f b6 88 20 a0 22 f0 	movzbl -0xfdd5fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100614:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100616:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010061c:	75 11                	jne    f010062f <cons_getc+0x48>
			cons.rpos = 0;
f010061e:	c7 05 20 a2 22 f0 00 	movl   $0x0,0xf022a220
f0100625:	00 00 00 
f0100628:	eb 05                	jmp    f010062f <cons_getc+0x48>
		return c;
	}
	return 0;
f010062a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010062f:	c9                   	leave  
f0100630:	c3                   	ret    

f0100631 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100631:	55                   	push   %ebp
f0100632:	89 e5                	mov    %esp,%ebp
f0100634:	57                   	push   %edi
f0100635:	56                   	push   %esi
f0100636:	53                   	push   %ebx
f0100637:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010063a:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100641:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100648:	5a a5 
	if (*cp != 0xA55A) {
f010064a:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100651:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100655:	74 11                	je     f0100668 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100657:	c7 05 30 a2 22 f0 b4 	movl   $0x3b4,0xf022a230
f010065e:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100661:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100666:	eb 16                	jmp    f010067e <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100668:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010066f:	c7 05 30 a2 22 f0 d4 	movl   $0x3d4,0xf022a230
f0100676:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100679:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010067e:	8b 3d 30 a2 22 f0    	mov    0xf022a230,%edi
f0100684:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100689:	89 fa                	mov    %edi,%edx
f010068b:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010068c:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010068f:	89 da                	mov    %ebx,%edx
f0100691:	ec                   	in     (%dx),%al
f0100692:	0f b6 c8             	movzbl %al,%ecx
f0100695:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100698:	b8 0f 00 00 00       	mov    $0xf,%eax
f010069d:	89 fa                	mov    %edi,%edx
f010069f:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006a0:	89 da                	mov    %ebx,%edx
f01006a2:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006a3:	89 35 2c a2 22 f0    	mov    %esi,0xf022a22c
	crt_pos = pos;
f01006a9:	0f b6 c0             	movzbl %al,%eax
f01006ac:	09 c8                	or     %ecx,%eax
f01006ae:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006b4:	e8 1c ff ff ff       	call   f01005d5 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f01006b9:	83 ec 0c             	sub    $0xc,%esp
f01006bc:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f01006c3:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006c8:	50                   	push   %eax
f01006c9:	e8 75 2e 00 00       	call   f0103543 <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006ce:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d8:	89 f2                	mov    %esi,%edx
f01006da:	ee                   	out    %al,(%dx)
f01006db:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01006e0:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006e5:	ee                   	out    %al,(%dx)
f01006e6:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01006eb:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006f0:	89 da                	mov    %ebx,%edx
f01006f2:	ee                   	out    %al,(%dx)
f01006f3:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01006f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01006fd:	ee                   	out    %al,(%dx)
f01006fe:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100703:	b8 03 00 00 00       	mov    $0x3,%eax
f0100708:	ee                   	out    %al,(%dx)
f0100709:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010070e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100713:	ee                   	out    %al,(%dx)
f0100714:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100719:	b8 01 00 00 00       	mov    $0x1,%eax
f010071e:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010071f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100724:	ec                   	in     (%dx),%al
f0100725:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100727:	83 c4 10             	add    $0x10,%esp
f010072a:	3c ff                	cmp    $0xff,%al
f010072c:	0f 95 05 34 a2 22 f0 	setne  0xf022a234
f0100733:	89 f2                	mov    %esi,%edx
f0100735:	ec                   	in     (%dx),%al
f0100736:	89 da                	mov    %ebx,%edx
f0100738:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100739:	80 f9 ff             	cmp    $0xff,%cl
f010073c:	75 10                	jne    f010074e <cons_init+0x11d>
		cprintf("Serial port does not exist!\n");
f010073e:	83 ec 0c             	sub    $0xc,%esp
f0100741:	68 af 5a 10 f0       	push   $0xf0105aaf
f0100746:	e8 49 2f 00 00       	call   f0103694 <cprintf>
f010074b:	83 c4 10             	add    $0x10,%esp
}
f010074e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100751:	5b                   	pop    %ebx
f0100752:	5e                   	pop    %esi
f0100753:	5f                   	pop    %edi
f0100754:	5d                   	pop    %ebp
f0100755:	c3                   	ret    

f0100756 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100756:	55                   	push   %ebp
f0100757:	89 e5                	mov    %esp,%ebp
f0100759:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010075c:	8b 45 08             	mov    0x8(%ebp),%eax
f010075f:	e8 6c fc ff ff       	call   f01003d0 <cons_putc>
}
f0100764:	c9                   	leave  
f0100765:	c3                   	ret    

f0100766 <getchar>:

int
getchar(void)
{
f0100766:	55                   	push   %ebp
f0100767:	89 e5                	mov    %esp,%ebp
f0100769:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010076c:	e8 76 fe ff ff       	call   f01005e7 <cons_getc>
f0100771:	85 c0                	test   %eax,%eax
f0100773:	74 f7                	je     f010076c <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100775:	c9                   	leave  
f0100776:	c3                   	ret    

f0100777 <iscons>:

int
iscons(int fdnum)
{
f0100777:	55                   	push   %ebp
f0100778:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010077a:	b8 01 00 00 00       	mov    $0x1,%eax
f010077f:	5d                   	pop    %ebp
f0100780:	c3                   	ret    

f0100781 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100781:	55                   	push   %ebp
f0100782:	89 e5                	mov    %esp,%ebp
f0100784:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100787:	68 00 5d 10 f0       	push   $0xf0105d00
f010078c:	68 1e 5d 10 f0       	push   $0xf0105d1e
f0100791:	68 23 5d 10 f0       	push   $0xf0105d23
f0100796:	e8 f9 2e 00 00       	call   f0103694 <cprintf>
f010079b:	83 c4 0c             	add    $0xc,%esp
f010079e:	68 b8 5d 10 f0       	push   $0xf0105db8
f01007a3:	68 2c 5d 10 f0       	push   $0xf0105d2c
f01007a8:	68 23 5d 10 f0       	push   $0xf0105d23
f01007ad:	e8 e2 2e 00 00       	call   f0103694 <cprintf>
f01007b2:	83 c4 0c             	add    $0xc,%esp
f01007b5:	68 e0 5d 10 f0       	push   $0xf0105de0
f01007ba:	68 35 5d 10 f0       	push   $0xf0105d35
f01007bf:	68 23 5d 10 f0       	push   $0xf0105d23
f01007c4:	e8 cb 2e 00 00       	call   f0103694 <cprintf>
	return 0;
}
f01007c9:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ce:	c9                   	leave  
f01007cf:	c3                   	ret    

f01007d0 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007d0:	55                   	push   %ebp
f01007d1:	89 e5                	mov    %esp,%ebp
f01007d3:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007d6:	68 3f 5d 10 f0       	push   $0xf0105d3f
f01007db:	e8 b4 2e 00 00       	call   f0103694 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007e0:	83 c4 08             	add    $0x8,%esp
f01007e3:	68 0c 00 10 00       	push   $0x10000c
f01007e8:	68 08 5e 10 f0       	push   $0xf0105e08
f01007ed:	e8 a2 2e 00 00       	call   f0103694 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007f2:	83 c4 0c             	add    $0xc,%esp
f01007f5:	68 0c 00 10 00       	push   $0x10000c
f01007fa:	68 0c 00 10 f0       	push   $0xf010000c
f01007ff:	68 30 5e 10 f0       	push   $0xf0105e30
f0100804:	e8 8b 2e 00 00       	call   f0103694 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100809:	83 c4 0c             	add    $0xc,%esp
f010080c:	68 c1 59 10 00       	push   $0x1059c1
f0100811:	68 c1 59 10 f0       	push   $0xf01059c1
f0100816:	68 54 5e 10 f0       	push   $0xf0105e54
f010081b:	e8 74 2e 00 00       	call   f0103694 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100820:	83 c4 0c             	add    $0xc,%esp
f0100823:	68 98 95 22 00       	push   $0x229598
f0100828:	68 98 95 22 f0       	push   $0xf0229598
f010082d:	68 78 5e 10 f0       	push   $0xf0105e78
f0100832:	e8 5d 2e 00 00       	call   f0103694 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100837:	83 c4 0c             	add    $0xc,%esp
f010083a:	68 08 c0 26 00       	push   $0x26c008
f010083f:	68 08 c0 26 f0       	push   $0xf026c008
f0100844:	68 9c 5e 10 f0       	push   $0xf0105e9c
f0100849:	e8 46 2e 00 00       	call   f0103694 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010084e:	b8 07 c4 26 f0       	mov    $0xf026c407,%eax
f0100853:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100858:	83 c4 08             	add    $0x8,%esp
f010085b:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100860:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100866:	85 c0                	test   %eax,%eax
f0100868:	0f 48 c2             	cmovs  %edx,%eax
f010086b:	c1 f8 0a             	sar    $0xa,%eax
f010086e:	50                   	push   %eax
f010086f:	68 c0 5e 10 f0       	push   $0xf0105ec0
f0100874:	e8 1b 2e 00 00       	call   f0103694 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100879:	b8 00 00 00 00       	mov    $0x0,%eax
f010087e:	c9                   	leave  
f010087f:	c3                   	ret    

f0100880 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100880:	55                   	push   %ebp
f0100881:	89 e5                	mov    %esp,%ebp
f0100883:	57                   	push   %edi
f0100884:	56                   	push   %esi
f0100885:	53                   	push   %ebx
f0100886:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100889:	89 eb                	mov    %ebp,%ebx
	struct Eipdebuginfo info;        
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();

	cprintf("Stack backtrace:\r\n");
f010088b:	68 58 5d 10 f0       	push   $0xf0105d58
f0100890:	e8 ff 2d 00 00       	call   f0103694 <cprintf>
	while (ebp != 0)
f0100895:	83 c4 10             	add    $0x10,%esp
	{
		eip = ebp[1];
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]); //%08x 补0输出8位16进制数
		debuginfo_eip((uintptr_t)eip, &info);
f0100898:	8d 7d d0             	lea    -0x30(%ebp),%edi
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();

	cprintf("Stack backtrace:\r\n");
	while (ebp != 0)
f010089b:	eb 53                	jmp    f01008f0 <mon_backtrace+0x70>
	{
		eip = ebp[1];
f010089d:	8b 73 04             	mov    0x4(%ebx),%esi
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]); //%08x 补0输出8位16进制数
f01008a0:	ff 73 18             	pushl  0x18(%ebx)
f01008a3:	ff 73 14             	pushl  0x14(%ebx)
f01008a6:	ff 73 10             	pushl  0x10(%ebx)
f01008a9:	ff 73 0c             	pushl  0xc(%ebx)
f01008ac:	ff 73 08             	pushl  0x8(%ebx)
f01008af:	56                   	push   %esi
f01008b0:	53                   	push   %ebx
f01008b1:	68 ec 5e 10 f0       	push   $0xf0105eec
f01008b6:	e8 d9 2d 00 00       	call   f0103694 <cprintf>
		debuginfo_eip((uintptr_t)eip, &info);
f01008bb:	83 c4 18             	add    $0x18,%esp
f01008be:	57                   	push   %edi
f01008bf:	56                   	push   %esi
f01008c0:	e8 1f 3a 00 00       	call   f01042e4 <debuginfo_eip>
		cprintf("%s:%d", info.eip_file, info.eip_line);
f01008c5:	83 c4 0c             	add    $0xc,%esp
f01008c8:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008cb:	ff 75 d0             	pushl  -0x30(%ebp)
f01008ce:	68 6b 5d 10 f0       	push   $0xf0105d6b
f01008d3:	e8 bc 2d 00 00       	call   f0103694 <cprintf>
		cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name, info.eip_fn_addr);
f01008d8:	ff 75 e0             	pushl  -0x20(%ebp)
f01008db:	ff 75 d8             	pushl  -0x28(%ebp)
f01008de:	ff 75 dc             	pushl  -0x24(%ebp)
f01008e1:	68 71 5d 10 f0       	push   $0xf0105d71
f01008e6:	e8 a9 2d 00 00       	call   f0103694 <cprintf>
		ebp = (uint32_t *)ebp[0];
f01008eb:	8b 1b                	mov    (%ebx),%ebx
f01008ed:	83 c4 20             	add    $0x20,%esp
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();

	cprintf("Stack backtrace:\r\n");
	while (ebp != 0)
f01008f0:	85 db                	test   %ebx,%ebx
f01008f2:	75 a9                	jne    f010089d <mon_backtrace+0x1d>
		cprintf("%s:%d", info.eip_file, info.eip_line);
		cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name, info.eip_fn_addr);
		ebp = (uint32_t *)ebp[0];
	}
	return 0;
}
f01008f4:	b8 00 00 00 00       	mov    $0x0,%eax
f01008f9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008fc:	5b                   	pop    %ebx
f01008fd:	5e                   	pop    %esi
f01008fe:	5f                   	pop    %edi
f01008ff:	5d                   	pop    %ebp
f0100900:	c3                   	ret    

f0100901 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100901:	55                   	push   %ebp
f0100902:	89 e5                	mov    %esp,%ebp
f0100904:	57                   	push   %edi
f0100905:	56                   	push   %esi
f0100906:	53                   	push   %ebx
f0100907:	83 ec 58             	sub    $0x58,%esp
	char *buf; 
	cprintf("Welcome to the JOS kernel monitor!\n");
f010090a:	68 24 5f 10 f0       	push   $0xf0105f24
f010090f:	e8 80 2d 00 00       	call   f0103694 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100914:	c7 04 24 48 5f 10 f0 	movl   $0xf0105f48,(%esp)
f010091b:	e8 74 2d 00 00       	call   f0103694 <cprintf>

	if (tf != NULL)
f0100920:	83 c4 10             	add    $0x10,%esp
f0100923:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100927:	74 0e                	je     f0100937 <monitor+0x36>
		print_trapframe(tf);
f0100929:	83 ec 0c             	sub    $0xc,%esp
f010092c:	ff 75 08             	pushl  0x8(%ebp)
f010092f:	e8 99 31 00 00       	call   f0103acd <print_trapframe>
f0100934:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100937:	83 ec 0c             	sub    $0xc,%esp
f010093a:	68 7c 5d 10 f0       	push   $0xf0105d7c
f010093f:	e8 7e 41 00 00       	call   f0104ac2 <readline>
f0100944:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100946:	83 c4 10             	add    $0x10,%esp
f0100949:	85 c0                	test   %eax,%eax
f010094b:	74 ea                	je     f0100937 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010094d:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100954:	be 00 00 00 00       	mov    $0x0,%esi
f0100959:	eb 0a                	jmp    f0100965 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010095b:	c6 03 00             	movb   $0x0,(%ebx)
f010095e:	89 f7                	mov    %esi,%edi
f0100960:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100963:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100965:	0f b6 03             	movzbl (%ebx),%eax
f0100968:	84 c0                	test   %al,%al
f010096a:	74 63                	je     f01009cf <monitor+0xce>
f010096c:	83 ec 08             	sub    $0x8,%esp
f010096f:	0f be c0             	movsbl %al,%eax
f0100972:	50                   	push   %eax
f0100973:	68 80 5d 10 f0       	push   $0xf0105d80
f0100978:	e8 5f 43 00 00       	call   f0104cdc <strchr>
f010097d:	83 c4 10             	add    $0x10,%esp
f0100980:	85 c0                	test   %eax,%eax
f0100982:	75 d7                	jne    f010095b <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100984:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100987:	74 46                	je     f01009cf <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100989:	83 fe 0f             	cmp    $0xf,%esi
f010098c:	75 14                	jne    f01009a2 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010098e:	83 ec 08             	sub    $0x8,%esp
f0100991:	6a 10                	push   $0x10
f0100993:	68 85 5d 10 f0       	push   $0xf0105d85
f0100998:	e8 f7 2c 00 00       	call   f0103694 <cprintf>
f010099d:	83 c4 10             	add    $0x10,%esp
f01009a0:	eb 95                	jmp    f0100937 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01009a2:	8d 7e 01             	lea    0x1(%esi),%edi
f01009a5:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009a9:	eb 03                	jmp    f01009ae <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01009ab:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009ae:	0f b6 03             	movzbl (%ebx),%eax
f01009b1:	84 c0                	test   %al,%al
f01009b3:	74 ae                	je     f0100963 <monitor+0x62>
f01009b5:	83 ec 08             	sub    $0x8,%esp
f01009b8:	0f be c0             	movsbl %al,%eax
f01009bb:	50                   	push   %eax
f01009bc:	68 80 5d 10 f0       	push   $0xf0105d80
f01009c1:	e8 16 43 00 00       	call   f0104cdc <strchr>
f01009c6:	83 c4 10             	add    $0x10,%esp
f01009c9:	85 c0                	test   %eax,%eax
f01009cb:	74 de                	je     f01009ab <monitor+0xaa>
f01009cd:	eb 94                	jmp    f0100963 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01009cf:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009d6:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009d7:	85 f6                	test   %esi,%esi
f01009d9:	0f 84 58 ff ff ff    	je     f0100937 <monitor+0x36>
f01009df:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009e4:	83 ec 08             	sub    $0x8,%esp
f01009e7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009ea:	ff 34 85 80 5f 10 f0 	pushl  -0xfefa080(,%eax,4)
f01009f1:	ff 75 a8             	pushl  -0x58(%ebp)
f01009f4:	e8 85 42 00 00       	call   f0104c7e <strcmp>
f01009f9:	83 c4 10             	add    $0x10,%esp
f01009fc:	85 c0                	test   %eax,%eax
f01009fe:	75 21                	jne    f0100a21 <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f0100a00:	83 ec 04             	sub    $0x4,%esp
f0100a03:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a06:	ff 75 08             	pushl  0x8(%ebp)
f0100a09:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a0c:	52                   	push   %edx
f0100a0d:	56                   	push   %esi
f0100a0e:	ff 14 85 88 5f 10 f0 	call   *-0xfefa078(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a15:	83 c4 10             	add    $0x10,%esp
f0100a18:	85 c0                	test   %eax,%eax
f0100a1a:	78 25                	js     f0100a41 <monitor+0x140>
f0100a1c:	e9 16 ff ff ff       	jmp    f0100937 <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100a21:	83 c3 01             	add    $0x1,%ebx
f0100a24:	83 fb 03             	cmp    $0x3,%ebx
f0100a27:	75 bb                	jne    f01009e4 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a29:	83 ec 08             	sub    $0x8,%esp
f0100a2c:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a2f:	68 a2 5d 10 f0       	push   $0xf0105da2
f0100a34:	e8 5b 2c 00 00       	call   f0103694 <cprintf>
f0100a39:	83 c4 10             	add    $0x10,%esp
f0100a3c:	e9 f6 fe ff ff       	jmp    f0100937 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a41:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a44:	5b                   	pop    %ebx
f0100a45:	5e                   	pop    %esi
f0100a46:	5f                   	pop    %edi
f0100a47:	5d                   	pop    %ebp
f0100a48:	c3                   	ret    

f0100a49 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a49:	55                   	push   %ebp
f0100a4a:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a4c:	83 3d 38 a2 22 f0 00 	cmpl   $0x0,0xf022a238
f0100a53:	75 11                	jne    f0100a66 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a55:	ba 07 d0 26 f0       	mov    $0xf026d007,%edx
f0100a5a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a60:	89 15 38 a2 22 f0    	mov    %edx,0xf022a238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100a66:	8b 0d 38 a2 22 f0    	mov    0xf022a238,%ecx
	nextfree += n;
	nextfree = ROUNDUP( (char*)nextfree, PGSIZE);
f0100a6c:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100a73:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a79:	89 15 38 a2 22 f0    	mov    %edx,0xf022a238
	//nextfree += ROUNDUP(n,PGSIZE);
	return result;
}
f0100a7f:	89 c8                	mov    %ecx,%eax
f0100a81:	5d                   	pop    %ebp
f0100a82:	c3                   	ret    

f0100a83 <check_va2pa>:
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];

	if (!(*pgdir & PTE_P))
f0100a83:	89 d1                	mov    %edx,%ecx
f0100a85:	c1 e9 16             	shr    $0x16,%ecx
f0100a88:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a8b:	a8 01                	test   $0x1,%al
f0100a8d:	74 52                	je     f0100ae1 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a8f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a94:	89 c1                	mov    %eax,%ecx
f0100a96:	c1 e9 0c             	shr    $0xc,%ecx
f0100a99:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0100a9f:	72 1b                	jb     f0100abc <check_va2pa+0x39>
// defined by the page directory 'pgdir'.  The hardware normally performs
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100aa1:	55                   	push   %ebp
f0100aa2:	89 e5                	mov    %esp,%ebp
f0100aa4:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100aa7:	50                   	push   %eax
f0100aa8:	68 04 5a 10 f0       	push   $0xf0105a04
f0100aad:	68 da 03 00 00       	push   $0x3da
f0100ab2:	68 a1 68 10 f0       	push   $0xf01068a1
f0100ab7:	e8 84 f5 ff ff       	call   f0100040 <_panic>
	pgdir = &pgdir[PDX(va)];

	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100abc:	c1 ea 0c             	shr    $0xc,%edx
f0100abf:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100ac5:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100acc:	89 c2                	mov    %eax,%edx
f0100ace:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100ad1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ad6:	85 d2                	test   %edx,%edx
f0100ad8:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100add:	0f 44 c2             	cmove  %edx,%eax
f0100ae0:	c3                   	ret    
	pte_t *p;

	pgdir = &pgdir[PDX(va)];

	if (!(*pgdir & PTE_P))
		return ~0;
f0100ae1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100ae6:	c3                   	ret    

f0100ae7 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100ae7:	55                   	push   %ebp
f0100ae8:	89 e5                	mov    %esp,%ebp
f0100aea:	57                   	push   %edi
f0100aeb:	56                   	push   %esi
f0100aec:	53                   	push   %ebx
f0100aed:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100af0:	84 c0                	test   %al,%al
f0100af2:	0f 85 91 02 00 00    	jne    f0100d89 <check_page_free_list+0x2a2>
f0100af8:	e9 9e 02 00 00       	jmp    f0100d9b <check_page_free_list+0x2b4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100afd:	83 ec 04             	sub    $0x4,%esp
f0100b00:	68 a4 5f 10 f0       	push   $0xf0105fa4
f0100b05:	68 0f 03 00 00       	push   $0x30f
f0100b0a:	68 a1 68 10 f0       	push   $0xf01068a1
f0100b0f:	e8 2c f5 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100b14:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b17:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b1a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b1d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b20:	89 c2                	mov    %eax,%edx
f0100b22:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0100b28:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b2e:	0f 95 c2             	setne  %dl
f0100b31:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b34:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b38:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b3a:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b3e:	8b 00                	mov    (%eax),%eax
f0100b40:	85 c0                	test   %eax,%eax
f0100b42:	75 dc                	jne    f0100b20 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b44:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b47:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b4d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b50:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b53:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b55:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b58:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b5d:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b62:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f0100b68:	eb 53                	jmp    f0100bbd <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b6a:	89 d8                	mov    %ebx,%eax
f0100b6c:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100b72:	c1 f8 03             	sar    $0x3,%eax
f0100b75:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b78:	89 c2                	mov    %eax,%edx
f0100b7a:	c1 ea 16             	shr    $0x16,%edx
f0100b7d:	39 f2                	cmp    %esi,%edx
f0100b7f:	73 3a                	jae    f0100bbb <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b81:	89 c2                	mov    %eax,%edx
f0100b83:	c1 ea 0c             	shr    $0xc,%edx
f0100b86:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100b8c:	72 12                	jb     f0100ba0 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b8e:	50                   	push   %eax
f0100b8f:	68 04 5a 10 f0       	push   $0xf0105a04
f0100b94:	6a 58                	push   $0x58
f0100b96:	68 ad 68 10 f0       	push   $0xf01068ad
f0100b9b:	e8 a0 f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100ba0:	83 ec 04             	sub    $0x4,%esp
f0100ba3:	68 80 00 00 00       	push   $0x80
f0100ba8:	68 97 00 00 00       	push   $0x97
f0100bad:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bb2:	50                   	push   %eax
f0100bb3:	e8 61 41 00 00       	call   f0104d19 <memset>
f0100bb8:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bbb:	8b 1b                	mov    (%ebx),%ebx
f0100bbd:	85 db                	test   %ebx,%ebx
f0100bbf:	75 a9                	jne    f0100b6a <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100bc1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bc6:	e8 7e fe ff ff       	call   f0100a49 <boot_alloc>
f0100bcb:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bce:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bd4:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
		assert(pp < pages + npages);
f0100bda:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0100bdf:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100be2:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100be5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100be8:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100beb:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bf0:	e9 52 01 00 00       	jmp    f0100d47 <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bf5:	39 ca                	cmp    %ecx,%edx
f0100bf7:	73 19                	jae    f0100c12 <check_page_free_list+0x12b>
f0100bf9:	68 bb 68 10 f0       	push   $0xf01068bb
f0100bfe:	68 c7 68 10 f0       	push   $0xf01068c7
f0100c03:	68 29 03 00 00       	push   $0x329
f0100c08:	68 a1 68 10 f0       	push   $0xf01068a1
f0100c0d:	e8 2e f4 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c12:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c15:	72 19                	jb     f0100c30 <check_page_free_list+0x149>
f0100c17:	68 dc 68 10 f0       	push   $0xf01068dc
f0100c1c:	68 c7 68 10 f0       	push   $0xf01068c7
f0100c21:	68 2a 03 00 00       	push   $0x32a
f0100c26:	68 a1 68 10 f0       	push   $0xf01068a1
f0100c2b:	e8 10 f4 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c30:	89 d0                	mov    %edx,%eax
f0100c32:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c35:	a8 07                	test   $0x7,%al
f0100c37:	74 19                	je     f0100c52 <check_page_free_list+0x16b>
f0100c39:	68 c8 5f 10 f0       	push   $0xf0105fc8
f0100c3e:	68 c7 68 10 f0       	push   $0xf01068c7
f0100c43:	68 2b 03 00 00       	push   $0x32b
f0100c48:	68 a1 68 10 f0       	push   $0xf01068a1
f0100c4d:	e8 ee f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c52:	c1 f8 03             	sar    $0x3,%eax
f0100c55:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c58:	85 c0                	test   %eax,%eax
f0100c5a:	75 19                	jne    f0100c75 <check_page_free_list+0x18e>
f0100c5c:	68 f0 68 10 f0       	push   $0xf01068f0
f0100c61:	68 c7 68 10 f0       	push   $0xf01068c7
f0100c66:	68 2e 03 00 00       	push   $0x32e
f0100c6b:	68 a1 68 10 f0       	push   $0xf01068a1
f0100c70:	e8 cb f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c75:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c7a:	75 19                	jne    f0100c95 <check_page_free_list+0x1ae>
f0100c7c:	68 01 69 10 f0       	push   $0xf0106901
f0100c81:	68 c7 68 10 f0       	push   $0xf01068c7
f0100c86:	68 2f 03 00 00       	push   $0x32f
f0100c8b:	68 a1 68 10 f0       	push   $0xf01068a1
f0100c90:	e8 ab f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c95:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c9a:	75 19                	jne    f0100cb5 <check_page_free_list+0x1ce>
f0100c9c:	68 fc 5f 10 f0       	push   $0xf0105ffc
f0100ca1:	68 c7 68 10 f0       	push   $0xf01068c7
f0100ca6:	68 30 03 00 00       	push   $0x330
f0100cab:	68 a1 68 10 f0       	push   $0xf01068a1
f0100cb0:	e8 8b f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cb5:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cba:	75 19                	jne    f0100cd5 <check_page_free_list+0x1ee>
f0100cbc:	68 1a 69 10 f0       	push   $0xf010691a
f0100cc1:	68 c7 68 10 f0       	push   $0xf01068c7
f0100cc6:	68 31 03 00 00       	push   $0x331
f0100ccb:	68 a1 68 10 f0       	push   $0xf01068a1
f0100cd0:	e8 6b f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cd5:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cda:	0f 86 de 00 00 00    	jbe    f0100dbe <check_page_free_list+0x2d7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ce0:	89 c7                	mov    %eax,%edi
f0100ce2:	c1 ef 0c             	shr    $0xc,%edi
f0100ce5:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100ce8:	77 12                	ja     f0100cfc <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cea:	50                   	push   %eax
f0100ceb:	68 04 5a 10 f0       	push   $0xf0105a04
f0100cf0:	6a 58                	push   $0x58
f0100cf2:	68 ad 68 10 f0       	push   $0xf01068ad
f0100cf7:	e8 44 f3 ff ff       	call   f0100040 <_panic>
f0100cfc:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100d02:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100d05:	0f 86 a7 00 00 00    	jbe    f0100db2 <check_page_free_list+0x2cb>
f0100d0b:	68 20 60 10 f0       	push   $0xf0106020
f0100d10:	68 c7 68 10 f0       	push   $0xf01068c7
f0100d15:	68 32 03 00 00       	push   $0x332
f0100d1a:	68 a1 68 10 f0       	push   $0xf01068a1
f0100d1f:	e8 1c f3 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d24:	68 34 69 10 f0       	push   $0xf0106934
f0100d29:	68 c7 68 10 f0       	push   $0xf01068c7
f0100d2e:	68 34 03 00 00       	push   $0x334
f0100d33:	68 a1 68 10 f0       	push   $0xf01068a1
f0100d38:	e8 03 f3 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d3d:	83 c6 01             	add    $0x1,%esi
f0100d40:	eb 03                	jmp    f0100d45 <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100d42:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d45:	8b 12                	mov    (%edx),%edx
f0100d47:	85 d2                	test   %edx,%edx
f0100d49:	0f 85 a6 fe ff ff    	jne    f0100bf5 <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d4f:	85 f6                	test   %esi,%esi
f0100d51:	7f 19                	jg     f0100d6c <check_page_free_list+0x285>
f0100d53:	68 51 69 10 f0       	push   $0xf0106951
f0100d58:	68 c7 68 10 f0       	push   $0xf01068c7
f0100d5d:	68 3c 03 00 00       	push   $0x33c
f0100d62:	68 a1 68 10 f0       	push   $0xf01068a1
f0100d67:	e8 d4 f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100d6c:	85 db                	test   %ebx,%ebx
f0100d6e:	7f 5e                	jg     f0100dce <check_page_free_list+0x2e7>
f0100d70:	68 63 69 10 f0       	push   $0xf0106963
f0100d75:	68 c7 68 10 f0       	push   $0xf01068c7
f0100d7a:	68 3d 03 00 00       	push   $0x33d
f0100d7f:	68 a1 68 10 f0       	push   $0xf01068a1
f0100d84:	e8 b7 f2 ff ff       	call   f0100040 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d89:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0100d8e:	85 c0                	test   %eax,%eax
f0100d90:	0f 85 7e fd ff ff    	jne    f0100b14 <check_page_free_list+0x2d>
f0100d96:	e9 62 fd ff ff       	jmp    f0100afd <check_page_free_list+0x16>
f0100d9b:	83 3d 40 a2 22 f0 00 	cmpl   $0x0,0xf022a240
f0100da2:	0f 84 55 fd ff ff    	je     f0100afd <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100da8:	be 00 04 00 00       	mov    $0x400,%esi
f0100dad:	e9 b0 fd ff ff       	jmp    f0100b62 <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100db2:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100db7:	75 89                	jne    f0100d42 <check_page_free_list+0x25b>
f0100db9:	e9 66 ff ff ff       	jmp    f0100d24 <check_page_free_list+0x23d>
f0100dbe:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100dc3:	0f 85 74 ff ff ff    	jne    f0100d3d <check_page_free_list+0x256>
f0100dc9:	e9 56 ff ff ff       	jmp    f0100d24 <check_page_free_list+0x23d>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100dce:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100dd1:	5b                   	pop    %ebx
f0100dd2:	5e                   	pop    %esi
f0100dd3:	5f                   	pop    %edi
f0100dd4:	5d                   	pop    %ebp
f0100dd5:	c3                   	ret    

f0100dd6 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100dd6:	55                   	push   %ebp
f0100dd7:	89 e5                	mov    %esp,%ebp
f0100dd9:	56                   	push   %esi
f0100dda:	53                   	push   %ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!

	//  1) Mark physical page 0 as in use.
	pages[0].pp_ref = 1;
f0100ddb:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0100de0:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;	
f0100de6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	size_t i;
	//临界点是否等于可能存在问题
	for (i = 1; i < npages; i++) {
f0100dec:	be 08 00 00 00       	mov    $0x8,%esi
f0100df1:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100df6:	e9 c7 00 00 00       	jmp    f0100ec2 <page_init+0xec>
		//lab4
		if (i == ROUNDUP(MPENTRY_PADDR, PGSIZE) / PGSIZE) {
f0100dfb:	83 fb 07             	cmp    $0x7,%ebx
f0100dfe:	75 17                	jne    f0100e17 <page_init+0x41>
        	pages[i].pp_ref = 1;
f0100e00:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0100e05:	66 c7 40 3c 01 00    	movw   $0x1,0x3c(%eax)
			pages[i].pp_link = NULL;
f0100e0b:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
        	continue;
f0100e12:	e9 a5 00 00 00       	jmp    f0100ebc <page_init+0xe6>
    	}

		
	//  2) The rest of base memory
		if(i < npages_basemem){
f0100e17:	3b 1d 44 a2 22 f0    	cmp    0xf022a244,%ebx
f0100e1d:	73 25                	jae    f0100e44 <page_init+0x6e>
			pages[i].pp_ref = 0;
f0100e1f:	89 f0                	mov    %esi,%eax
f0100e21:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100e27:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100e2d:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100e33:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100e35:	89 f0                	mov    %esi,%eax
f0100e37:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100e3d:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
f0100e42:	eb 78                	jmp    f0100ebc <page_init+0xe6>
		}
	//  3) Then comes the IO hole 
		else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE){
f0100e44:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100e4a:	83 f8 5f             	cmp    $0x5f,%eax
f0100e4d:	77 16                	ja     f0100e65 <page_init+0x8f>
			pages[i].pp_ref = 1;
f0100e4f:	89 f0                	mov    %esi,%eax
f0100e51:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100e57:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100e5d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100e63:	eb 57                	jmp    f0100ebc <page_init+0xe6>
		}
	//  4) Then extended memory
		else if(i >= EXTPHYSMEM/PGSIZE && i< ((int)boot_alloc(0) - KERNBASE)/PGSIZE){
f0100e65:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100e6b:	76 2c                	jbe    f0100e99 <page_init+0xc3>
f0100e6d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e72:	e8 d2 fb ff ff       	call   f0100a49 <boot_alloc>
f0100e77:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e7c:	c1 e8 0c             	shr    $0xc,%eax
f0100e7f:	39 c3                	cmp    %eax,%ebx
f0100e81:	73 16                	jae    f0100e99 <page_init+0xc3>
			pages[i].pp_ref = 1;
f0100e83:	89 f0                	mov    %esi,%eax
f0100e85:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100e8b:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100e91:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100e97:	eb 23                	jmp    f0100ebc <page_init+0xe6>
		}
		else{
			pages[i].pp_ref = 0;
f0100e99:	89 f0                	mov    %esi,%eax
f0100e9b:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100ea1:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100ea7:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100ead:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100eaf:	89 f0                	mov    %esi,%eax
f0100eb1:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100eb7:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
	//  1) Mark physical page 0 as in use.
	pages[0].pp_ref = 1;
	pages[0].pp_link = NULL;	
	size_t i;
	//临界点是否等于可能存在问题
	for (i = 1; i < npages; i++) {
f0100ebc:	83 c3 01             	add    $0x1,%ebx
f0100ebf:	83 c6 08             	add    $0x8,%esi
f0100ec2:	3b 1d 88 ae 22 f0    	cmp    0xf022ae88,%ebx
f0100ec8:	0f 82 2d ff ff ff    	jb     f0100dfb <page_init+0x25>

	//要在循环里判断，否者该项以及在page_free_list中
	//i = ROUNDUP(MPENTRY_PADDR, PGSIZE) / PGSIZE;
	//pages[i].pp_ref = 1;
	//pages[i].pp_link = NULL;
}
f0100ece:	5b                   	pop    %ebx
f0100ecf:	5e                   	pop    %esi
f0100ed0:	5d                   	pop    %ebp
f0100ed1:	c3                   	ret    

f0100ed2 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100ed2:	55                   	push   %ebp
f0100ed3:	89 e5                	mov    %esp,%ebp
f0100ed5:	53                   	push   %ebx
f0100ed6:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if(page_free_list == NULL)
f0100ed9:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f0100edf:	85 db                	test   %ebx,%ebx
f0100ee1:	74 5e                	je     f0100f41 <page_alloc+0x6f>
		//addr = page2kva(page_free_list);
		//int *iq,*ip;
		//iq=ip;//将把ip中的值拷贝到iq中，这样，指针iq也将指向ip指向的对象
		struct PageInfo *Page;
		Page = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100ee3:	8b 03                	mov    (%ebx),%eax
f0100ee5:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
		//page_free_list->pp_link = NULL;
		Page->pp_link = NULL;
f0100eea:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		//Page->pp_ref = 1;
		Page->pp_ref = 0;
f0100ef0:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		//cprintf("page_alloc\r\n");
		if(alloc_flags & ALLOC_ZERO)
f0100ef6:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100efa:	74 45                	je     f0100f41 <page_alloc+0x6f>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100efc:	89 d8                	mov    %ebx,%eax
f0100efe:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100f04:	c1 f8 03             	sar    $0x3,%eax
f0100f07:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f0a:	89 c2                	mov    %eax,%edx
f0100f0c:	c1 ea 0c             	shr    $0xc,%edx
f0100f0f:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100f15:	72 12                	jb     f0100f29 <page_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f17:	50                   	push   %eax
f0100f18:	68 04 5a 10 f0       	push   $0xf0105a04
f0100f1d:	6a 58                	push   $0x58
f0100f1f:	68 ad 68 10 f0       	push   $0xf01068ad
f0100f24:	e8 17 f1 ff ff       	call   f0100040 <_panic>
			memset(page2kva(Page),'\0',PGSIZE);
f0100f29:	83 ec 04             	sub    $0x4,%esp
f0100f2c:	68 00 10 00 00       	push   $0x1000
f0100f31:	6a 00                	push   $0x0
f0100f33:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f38:	50                   	push   %eax
f0100f39:	e8 db 3d 00 00       	call   f0104d19 <memset>
f0100f3e:	83 c4 10             	add    $0x10,%esp
			// memset(page2kva(page_free_list),0,PGSIZE);
		return Page;
	}
}
f0100f41:	89 d8                	mov    %ebx,%eax
f0100f43:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f46:	c9                   	leave  
f0100f47:	c3                   	ret    

f0100f48 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100f48:	55                   	push   %ebp
f0100f49:	89 e5                	mov    %esp,%ebp
f0100f4b:	8b 45 08             	mov    0x8(%ebp),%eax
	//  	panic("can't free the page");
	//  	return;
	// }
	//	cprinf("can't free the page");
	//pp->pp_link = page_free_list->pp_link;	
	pp->pp_link = page_free_list;
f0100f4e:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100f54:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f56:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
	//pp->pp_ref = 0;
	//cprintf("page_free\r\n");
}
f0100f5b:	5d                   	pop    %ebp
f0100f5c:	c3                   	ret    

f0100f5d <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100f5d:	55                   	push   %ebp
f0100f5e:	89 e5                	mov    %esp,%ebp
f0100f60:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100f63:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100f67:	83 e8 01             	sub    $0x1,%eax
f0100f6a:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100f6e:	66 85 c0             	test   %ax,%ax
f0100f71:	75 09                	jne    f0100f7c <page_decref+0x1f>
		page_free(pp);
f0100f73:	52                   	push   %edx
f0100f74:	e8 cf ff ff ff       	call   f0100f48 <page_free>
f0100f79:	83 c4 04             	add    $0x4,%esp
}
f0100f7c:	c9                   	leave  
f0100f7d:	c3                   	ret    

f0100f7e <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f7e:	55                   	push   %ebp
f0100f7f:	89 e5                	mov    %esp,%ebp
f0100f81:	56                   	push   %esi
f0100f82:	53                   	push   %ebx
f0100f83:	8b 45 0c             	mov    0xc(%ebp),%eax
	// Fill this function in
	uint32_t pd_number,pt_number,pt_addr;//,page_number,page_addr;
	pte_t *pte = NULL;
	struct PageInfo *Page;
	pd_number = PDX(va);
	pt_number = PTX(va);
f0100f86:	89 c6                	mov    %eax,%esi
f0100f88:	c1 ee 0c             	shr    $0xc,%esi
f0100f8b:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	if(pgdir[pd_number] & PTE_P)
f0100f91:	c1 e8 16             	shr    $0x16,%eax
f0100f94:	8d 1c 85 00 00 00 00 	lea    0x0(,%eax,4),%ebx
f0100f9b:	03 5d 08             	add    0x8(%ebp),%ebx
f0100f9e:	8b 03                	mov    (%ebx),%eax
f0100fa0:	a8 01                	test   $0x1,%al
f0100fa2:	74 2e                	je     f0100fd2 <pgdir_walk+0x54>
		pte = KADDR(PTE_ADDR(pgdir[pd_number]));
f0100fa4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fa9:	89 c2                	mov    %eax,%edx
f0100fab:	c1 ea 0c             	shr    $0xc,%edx
f0100fae:	39 15 88 ae 22 f0    	cmp    %edx,0xf022ae88
f0100fb4:	77 15                	ja     f0100fcb <pgdir_walk+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fb6:	50                   	push   %eax
f0100fb7:	68 04 5a 10 f0       	push   $0xf0105a04
f0100fbc:	68 c7 01 00 00       	push   $0x1c7
f0100fc1:	68 a1 68 10 f0       	push   $0xf01068a1
f0100fc6:	e8 75 f0 ff ff       	call   f0100040 <_panic>
	if(!pte){
f0100fcb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fd0:	75 58                	jne    f010102a <pgdir_walk+0xac>
		if(!create)
f0100fd2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100fd6:	74 57                	je     f010102f <pgdir_walk+0xb1>
	 		return NULL;
	 	Page = page_alloc(create);
f0100fd8:	83 ec 0c             	sub    $0xc,%esp
f0100fdb:	ff 75 10             	pushl  0x10(%ebp)
f0100fde:	e8 ef fe ff ff       	call   f0100ed2 <page_alloc>
		if(!Page)
f0100fe3:	83 c4 10             	add    $0x10,%esp
f0100fe6:	85 c0                	test   %eax,%eax
f0100fe8:	74 4c                	je     f0101036 <pgdir_walk+0xb8>
			return NULL;
		Page->pp_ref ++;
f0100fea:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fef:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100ff5:	89 c2                	mov    %eax,%edx
f0100ff7:	c1 fa 03             	sar    $0x3,%edx
f0100ffa:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ffd:	89 d0                	mov    %edx,%eax
f0100fff:	c1 e8 0c             	shr    $0xc,%eax
f0101002:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0101008:	72 15                	jb     f010101f <pgdir_walk+0xa1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010100a:	52                   	push   %edx
f010100b:	68 04 5a 10 f0       	push   $0xf0105a04
f0101010:	68 cf 01 00 00       	push   $0x1cf
f0101015:	68 a1 68 10 f0       	push   $0xf01068a1
f010101a:	e8 21 f0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010101f:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	 	pte = KADDR(page2pa(Page));		
		// pgdir[pd_number] = page2pa(Page);
		pgdir[pd_number] = page2pa(Page) | PTE_P | PTE_W | PTE_U;
f0101025:	83 ca 07             	or     $0x7,%edx
f0101028:	89 13                	mov    %edx,(%ebx)
	}
	return &(pte[pt_number]);
f010102a:	8d 04 b0             	lea    (%eax,%esi,4),%eax
f010102d:	eb 0c                	jmp    f010103b <pgdir_walk+0xbd>
	pt_number = PTX(va);
	if(pgdir[pd_number] & PTE_P)
		pte = KADDR(PTE_ADDR(pgdir[pd_number]));
	if(!pte){
		if(!create)
	 		return NULL;
f010102f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101034:	eb 05                	jmp    f010103b <pgdir_walk+0xbd>
	 	Page = page_alloc(create);
		if(!Page)
			return NULL;
f0101036:	b8 00 00 00 00       	mov    $0x0,%eax
	// //不确定page_alloc函数里应该填入的参数,page_alloc(int alloc_flags)
	// 	Page = page_alloc(create);
	// 	page_addr = page2pa(Page);
	// }
	// return page_addr;
}
f010103b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010103e:	5b                   	pop    %ebx
f010103f:	5e                   	pop    %esi
f0101040:	5d                   	pop    %ebp
f0101041:	c3                   	ret    

f0101042 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101042:	55                   	push   %ebp
f0101043:	89 e5                	mov    %esp,%ebp
f0101045:	57                   	push   %edi
f0101046:	56                   	push   %esi
f0101047:	53                   	push   %ebx
f0101048:	83 ec 1c             	sub    $0x1c,%esp
f010104b:	89 c7                	mov    %eax,%edi
f010104d:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101050:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	pte_t *pte = NULL;
	//cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for(int i = 0;i < size;i += PGSIZE){
f0101053:	bb 00 00 00 00       	mov    $0x0,%ebx
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
f0101058:	8b 45 0c             	mov    0xc(%ebp),%eax
f010105b:	83 c8 01             	or     $0x1,%eax
f010105e:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte = NULL;
	//cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for(int i = 0;i < size;i += PGSIZE){
f0101061:	eb 1f                	jmp    f0101082 <boot_map_region+0x40>
		pte = pgdir_walk(pgdir, (void *)va, 1);
f0101063:	83 ec 04             	sub    $0x4,%esp
f0101066:	6a 01                	push   $0x1
f0101068:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010106b:	01 d8                	add    %ebx,%eax
f010106d:	50                   	push   %eax
f010106e:	57                   	push   %edi
f010106f:	e8 0a ff ff ff       	call   f0100f7e <pgdir_walk>
		*pte = (pa | perm | PTE_P);
f0101074:	0b 75 dc             	or     -0x24(%ebp),%esi
f0101077:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte = NULL;
	//cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for(int i = 0;i < size;i += PGSIZE){
f0101079:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010107f:	83 c4 10             	add    $0x10,%esp
f0101082:	89 de                	mov    %ebx,%esi
f0101084:	03 75 08             	add    0x8(%ebp),%esi
f0101087:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f010108a:	77 d7                	ja     f0101063 <boot_map_region+0x21>
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f010108c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010108f:	5b                   	pop    %ebx
f0101090:	5e                   	pop    %esi
f0101091:	5f                   	pop    %edi
f0101092:	5d                   	pop    %ebp
f0101093:	c3                   	ret    

f0101094 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101094:	55                   	push   %ebp
f0101095:	89 e5                	mov    %esp,%ebp
f0101097:	53                   	push   %ebx
f0101098:	83 ec 08             	sub    $0x8,%esp
f010109b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
f010109e:	6a 00                	push   $0x0
f01010a0:	ff 75 0c             	pushl  0xc(%ebp)
f01010a3:	ff 75 08             	pushl  0x8(%ebp)
f01010a6:	e8 d3 fe ff ff       	call   f0100f7e <pgdir_walk>
	if(!pte)
f01010ab:	83 c4 10             	add    $0x10,%esp
f01010ae:	85 c0                	test   %eax,%eax
f01010b0:	74 32                	je     f01010e4 <page_lookup+0x50>
		return NULL;
	if(pte_store)
f01010b2:	85 db                	test   %ebx,%ebx
f01010b4:	74 02                	je     f01010b8 <page_lookup+0x24>
		*pte_store = pte;
f01010b6:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010b8:	8b 00                	mov    (%eax),%eax
f01010ba:	c1 e8 0c             	shr    $0xc,%eax
f01010bd:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01010c3:	72 14                	jb     f01010d9 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f01010c5:	83 ec 04             	sub    $0x4,%esp
f01010c8:	68 68 60 10 f0       	push   $0xf0106068
f01010cd:	6a 51                	push   $0x51
f01010cf:	68 ad 68 10 f0       	push   $0xf01068ad
f01010d4:	e8 67 ef ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f01010d9:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f01010df:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	return pa2page(PTE_ADDR(*pte));
f01010e2:	eb 05                	jmp    f01010e9 <page_lookup+0x55>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
	if(!pte)
		return NULL;
f01010e4:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f01010e9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010ec:	c9                   	leave  
f01010ed:	c3                   	ret    

f01010ee <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01010ee:	55                   	push   %ebp
f01010ef:	89 e5                	mov    %esp,%ebp
f01010f1:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f01010f4:	e8 41 42 00 00       	call   f010533a <cpunum>
f01010f9:	6b c0 74             	imul   $0x74,%eax,%eax
f01010fc:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0101103:	74 16                	je     f010111b <tlb_invalidate+0x2d>
f0101105:	e8 30 42 00 00       	call   f010533a <cpunum>
f010110a:	6b c0 74             	imul   $0x74,%eax,%eax
f010110d:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0101113:	8b 55 08             	mov    0x8(%ebp),%edx
f0101116:	39 50 60             	cmp    %edx,0x60(%eax)
f0101119:	75 06                	jne    f0101121 <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010111b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010111e:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0101121:	c9                   	leave  
f0101122:	c3                   	ret    

f0101123 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101123:	55                   	push   %ebp
f0101124:	89 e5                	mov    %esp,%ebp
f0101126:	57                   	push   %edi
f0101127:	56                   	push   %esi
f0101128:	53                   	push   %ebx
f0101129:	83 ec 20             	sub    $0x20,%esp
f010112c:	8b 75 08             	mov    0x8(%ebp),%esi
f010112f:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pte_t *pte;
	// pte_t *pte,**pte_store;
	// pte = pgdir_walk(pgdir, (void *)va, 0);
	// pte_store = &pte;
	struct PageInfo *Page;
	Page = page_lookup(pgdir, va, &pte);
f0101132:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101135:	50                   	push   %eax
f0101136:	57                   	push   %edi
f0101137:	56                   	push   %esi
f0101138:	e8 57 ff ff ff       	call   f0101094 <page_lookup>
	// Page = page_lookup(pgdir, va, pte_store);
	if(Page){
f010113d:	83 c4 10             	add    $0x10,%esp
f0101140:	85 c0                	test   %eax,%eax
f0101142:	74 20                	je     f0101164 <page_remove+0x41>
f0101144:	89 c3                	mov    %eax,%ebx
		// Page->pp_ref --;
		tlb_invalidate(pgdir, va);
f0101146:	83 ec 08             	sub    $0x8,%esp
f0101149:	57                   	push   %edi
f010114a:	56                   	push   %esi
f010114b:	e8 9e ff ff ff       	call   f01010ee <tlb_invalidate>
		page_decref(Page);
f0101150:	89 1c 24             	mov    %ebx,(%esp)
f0101153:	e8 05 fe ff ff       	call   f0100f5d <page_decref>
		*pte = 0;//将对应的页表项清空
f0101158:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010115b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101161:	83 c4 10             	add    $0x10,%esp
	}
}
f0101164:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101167:	5b                   	pop    %ebx
f0101168:	5e                   	pop    %esi
f0101169:	5f                   	pop    %edi
f010116a:	5d                   	pop    %ebp
f010116b:	c3                   	ret    

f010116c <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010116c:	55                   	push   %ebp
f010116d:	89 e5                	mov    %esp,%ebp
f010116f:	57                   	push   %edi
f0101170:	56                   	push   %esi
f0101171:	53                   	push   %ebx
f0101172:	83 ec 10             	sub    $0x10,%esp
f0101175:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101178:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
f010117b:	6a 01                	push   $0x1
f010117d:	57                   	push   %edi
f010117e:	ff 75 08             	pushl  0x8(%ebp)
f0101181:	e8 f8 fd ff ff       	call   f0100f7e <pgdir_walk>
	if(!pte)
f0101186:	83 c4 10             	add    $0x10,%esp
f0101189:	85 c0                	test   %eax,%eax
f010118b:	74 38                	je     f01011c5 <page_insert+0x59>
f010118d:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	pp->pp_ref++;
f010118f:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	//删除旧映射关系 
    if((*pte) & PTE_P)
f0101194:	f6 00 01             	testb  $0x1,(%eax)
f0101197:	74 0f                	je     f01011a8 <page_insert+0x3c>
        page_remove(pgdir, va);
f0101199:	83 ec 08             	sub    $0x8,%esp
f010119c:	57                   	push   %edi
f010119d:	ff 75 08             	pushl  0x8(%ebp)
f01011a0:	e8 7e ff ff ff       	call   f0101123 <page_remove>
f01011a5:	83 c4 10             	add    $0x10,%esp
	//pp ->pp_ref++;
    *pte = page2pa(pp) | perm | PTE_P;
f01011a8:	2b 1d 90 ae 22 f0    	sub    0xf022ae90,%ebx
f01011ae:	c1 fb 03             	sar    $0x3,%ebx
f01011b1:	c1 e3 0c             	shl    $0xc,%ebx
f01011b4:	8b 45 14             	mov    0x14(%ebp),%eax
f01011b7:	83 c8 01             	or     $0x1,%eax
f01011ba:	09 c3                	or     %eax,%ebx
f01011bc:	89 1e                	mov    %ebx,(%esi)
	return 0;
f01011be:	b8 00 00 00 00       	mov    $0x0,%eax
f01011c3:	eb 05                	jmp    f01011ca <page_insert+0x5e>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
	if(!pte)
		return -E_NO_MEM;
f01011c5:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	// 		page_remove(pgdir, va); 
	// }
	// //pp->pp_ref++;
    // *pte = page2pa(pp) | perm | PTE_P;
	// return 0;
}
f01011ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011cd:	5b                   	pop    %ebx
f01011ce:	5e                   	pop    %esi
f01011cf:	5f                   	pop    %edi
f01011d0:	5d                   	pop    %ebp
f01011d1:	c3                   	ret    

f01011d2 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01011d2:	55                   	push   %ebp
f01011d3:	89 e5                	mov    %esp,%ebp
f01011d5:	53                   	push   %ebx
f01011d6:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	size = ROUNDUP(size, PGSIZE);
f01011d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011dc:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f01011e2:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	pa = ROUNDDOWN(pa, PGSIZE);
f01011e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01011eb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	
	if(base + size > MMIOLIM)
f01011f0:	8b 15 00 f3 11 f0    	mov    0xf011f300,%edx
f01011f6:	8d 0c 13             	lea    (%ebx,%edx,1),%ecx
f01011f9:	81 f9 00 00 c0 ef    	cmp    $0xefc00000,%ecx
f01011ff:	76 17                	jbe    f0101218 <mmio_map_region+0x46>
		panic("MMIOLIM is not enough");
f0101201:	83 ec 04             	sub    $0x4,%esp
f0101204:	68 74 69 10 f0       	push   $0xf0106974
f0101209:	68 b5 02 00 00       	push   $0x2b5
f010120e:	68 a1 68 10 f0       	push   $0xf01068a1
f0101213:	e8 28 ee ff ff       	call   f0100040 <_panic>

	boot_map_region(kern_pgdir, base, size, pa, PTE_PCD | PTE_PWT | PTE_W | PTE_P);
f0101218:	83 ec 08             	sub    $0x8,%esp
f010121b:	6a 1b                	push   $0x1b
f010121d:	50                   	push   %eax
f010121e:	89 d9                	mov    %ebx,%ecx
f0101220:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101225:	e8 18 fe ff ff       	call   f0101042 <boot_map_region>
	base += size;//每次映射到不同的页面
f010122a:	a1 00 f3 11 f0       	mov    0xf011f300,%eax
f010122f:	01 c3                	add    %eax,%ebx
f0101231:	89 1d 00 f3 11 f0    	mov    %ebx,0xf011f300
	return (void *)(base-size);
	//panic("mmio_map_region not implemented");
}
f0101237:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010123a:	c9                   	leave  
f010123b:	c3                   	ret    

f010123c <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010123c:	55                   	push   %ebp
f010123d:	89 e5                	mov    %esp,%ebp
f010123f:	57                   	push   %edi
f0101240:	56                   	push   %esi
f0101241:	53                   	push   %ebx
f0101242:	83 ec 48             	sub    $0x48,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101245:	6a 15                	push   $0x15
f0101247:	e8 c9 22 00 00       	call   f0103515 <mc146818_read>
f010124c:	89 c3                	mov    %eax,%ebx
f010124e:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101255:	e8 bb 22 00 00       	call   f0103515 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010125a:	c1 e0 08             	shl    $0x8,%eax
f010125d:	09 d8                	or     %ebx,%eax
f010125f:	c1 e0 0a             	shl    $0xa,%eax
f0101262:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101268:	85 c0                	test   %eax,%eax
f010126a:	0f 48 c2             	cmovs  %edx,%eax
f010126d:	c1 f8 0c             	sar    $0xc,%eax
f0101270:	a3 44 a2 22 f0       	mov    %eax,0xf022a244
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101275:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010127c:	e8 94 22 00 00       	call   f0103515 <mc146818_read>
f0101281:	89 c3                	mov    %eax,%ebx
f0101283:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010128a:	e8 86 22 00 00       	call   f0103515 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010128f:	c1 e0 08             	shl    $0x8,%eax
f0101292:	09 d8                	or     %ebx,%eax
f0101294:	c1 e0 0a             	shl    $0xa,%eax
f0101297:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010129d:	83 c4 10             	add    $0x10,%esp
f01012a0:	85 c0                	test   %eax,%eax
f01012a2:	0f 48 c2             	cmovs  %edx,%eax
f01012a5:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01012a8:	85 c0                	test   %eax,%eax
f01012aa:	74 0e                	je     f01012ba <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01012ac:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01012b2:	89 15 88 ae 22 f0    	mov    %edx,0xf022ae88
f01012b8:	eb 0c                	jmp    f01012c6 <mem_init+0x8a>
	else
		npages = npages_basemem;
f01012ba:	8b 15 44 a2 22 f0    	mov    0xf022a244,%edx
f01012c0:	89 15 88 ae 22 f0    	mov    %edx,0xf022ae88

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012c6:	c1 e0 0c             	shl    $0xc,%eax
f01012c9:	c1 e8 0a             	shr    $0xa,%eax
f01012cc:	50                   	push   %eax
f01012cd:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
f01012d2:	c1 e0 0c             	shl    $0xc,%eax
f01012d5:	c1 e8 0a             	shr    $0xa,%eax
f01012d8:	50                   	push   %eax
f01012d9:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f01012de:	c1 e0 0c             	shl    $0xc,%eax
f01012e1:	c1 e8 0a             	shr    $0xa,%eax
f01012e4:	50                   	push   %eax
f01012e5:	68 88 60 10 f0       	push   $0xf0106088
f01012ea:	e8 a5 23 00 00       	call   f0103694 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01012ef:	b8 00 10 00 00       	mov    $0x1000,%eax
f01012f4:	e8 50 f7 ff ff       	call   f0100a49 <boot_alloc>
f01012f9:	a3 8c ae 22 f0       	mov    %eax,0xf022ae8c
	memset(kern_pgdir, 0, PGSIZE);
f01012fe:	83 c4 0c             	add    $0xc,%esp
f0101301:	68 00 10 00 00       	push   $0x1000
f0101306:	6a 00                	push   $0x0
f0101308:	50                   	push   %eax
f0101309:	e8 0b 3a 00 00       	call   f0104d19 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010130e:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101313:	83 c4 10             	add    $0x10,%esp
f0101316:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010131b:	77 15                	ja     f0101332 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010131d:	50                   	push   %eax
f010131e:	68 28 5a 10 f0       	push   $0xf0105a28
f0101323:	68 90 00 00 00       	push   $0x90
f0101328:	68 a1 68 10 f0       	push   $0xf01068a1
f010132d:	e8 0e ed ff ff       	call   f0100040 <_panic>
f0101332:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101338:	83 ca 05             	or     $0x5,%edx
f010133b:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f0101341:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0101346:	c1 e0 03             	shl    $0x3,%eax
f0101349:	e8 fb f6 ff ff       	call   f0100a49 <boot_alloc>
f010134e:	a3 90 ae 22 f0       	mov    %eax,0xf022ae90
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101353:	83 ec 04             	sub    $0x4,%esp
f0101356:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f010135c:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101363:	52                   	push   %edx
f0101364:	6a 00                	push   $0x0
f0101366:	50                   	push   %eax
f0101367:	e8 ad 39 00 00       	call   f0104d19 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*)boot_alloc(NENV * sizeof(struct Env));
f010136c:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101371:	e8 d3 f6 ff ff       	call   f0100a49 <boot_alloc>
f0101376:	a3 48 a2 22 f0       	mov    %eax,0xf022a248
	memset(envs, 0, NENV * sizeof(struct Env));
f010137b:	83 c4 0c             	add    $0xc,%esp
f010137e:	68 00 f0 01 00       	push   $0x1f000
f0101383:	6a 00                	push   $0x0
f0101385:	50                   	push   %eax
f0101386:	e8 8e 39 00 00       	call   f0104d19 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010138b:	e8 46 fa ff ff       	call   f0100dd6 <page_init>

	check_page_free_list(1);
f0101390:	b8 01 00 00 00       	mov    $0x1,%eax
f0101395:	e8 4d f7 ff ff       	call   f0100ae7 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010139a:	83 c4 10             	add    $0x10,%esp
f010139d:	83 3d 90 ae 22 f0 00 	cmpl   $0x0,0xf022ae90
f01013a4:	75 17                	jne    f01013bd <mem_init+0x181>
		panic("'pages' is a null pointer!");
f01013a6:	83 ec 04             	sub    $0x4,%esp
f01013a9:	68 8a 69 10 f0       	push   $0xf010698a
f01013ae:	68 4e 03 00 00       	push   $0x34e
f01013b3:	68 a1 68 10 f0       	push   $0xf01068a1
f01013b8:	e8 83 ec ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013bd:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f01013c2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01013c7:	eb 05                	jmp    f01013ce <mem_init+0x192>
		++nfree;
f01013c9:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013cc:	8b 00                	mov    (%eax),%eax
f01013ce:	85 c0                	test   %eax,%eax
f01013d0:	75 f7                	jne    f01013c9 <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013d2:	83 ec 0c             	sub    $0xc,%esp
f01013d5:	6a 00                	push   $0x0
f01013d7:	e8 f6 fa ff ff       	call   f0100ed2 <page_alloc>
f01013dc:	89 c7                	mov    %eax,%edi
f01013de:	83 c4 10             	add    $0x10,%esp
f01013e1:	85 c0                	test   %eax,%eax
f01013e3:	75 19                	jne    f01013fe <mem_init+0x1c2>
f01013e5:	68 a5 69 10 f0       	push   $0xf01069a5
f01013ea:	68 c7 68 10 f0       	push   $0xf01068c7
f01013ef:	68 56 03 00 00       	push   $0x356
f01013f4:	68 a1 68 10 f0       	push   $0xf01068a1
f01013f9:	e8 42 ec ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01013fe:	83 ec 0c             	sub    $0xc,%esp
f0101401:	6a 00                	push   $0x0
f0101403:	e8 ca fa ff ff       	call   f0100ed2 <page_alloc>
f0101408:	89 c6                	mov    %eax,%esi
f010140a:	83 c4 10             	add    $0x10,%esp
f010140d:	85 c0                	test   %eax,%eax
f010140f:	75 19                	jne    f010142a <mem_init+0x1ee>
f0101411:	68 bb 69 10 f0       	push   $0xf01069bb
f0101416:	68 c7 68 10 f0       	push   $0xf01068c7
f010141b:	68 57 03 00 00       	push   $0x357
f0101420:	68 a1 68 10 f0       	push   $0xf01068a1
f0101425:	e8 16 ec ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010142a:	83 ec 0c             	sub    $0xc,%esp
f010142d:	6a 00                	push   $0x0
f010142f:	e8 9e fa ff ff       	call   f0100ed2 <page_alloc>
f0101434:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101437:	83 c4 10             	add    $0x10,%esp
f010143a:	85 c0                	test   %eax,%eax
f010143c:	75 19                	jne    f0101457 <mem_init+0x21b>
f010143e:	68 d1 69 10 f0       	push   $0xf01069d1
f0101443:	68 c7 68 10 f0       	push   $0xf01068c7
f0101448:	68 58 03 00 00       	push   $0x358
f010144d:	68 a1 68 10 f0       	push   $0xf01068a1
f0101452:	e8 e9 eb ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101457:	39 f7                	cmp    %esi,%edi
f0101459:	75 19                	jne    f0101474 <mem_init+0x238>
f010145b:	68 e7 69 10 f0       	push   $0xf01069e7
f0101460:	68 c7 68 10 f0       	push   $0xf01068c7
f0101465:	68 5b 03 00 00       	push   $0x35b
f010146a:	68 a1 68 10 f0       	push   $0xf01068a1
f010146f:	e8 cc eb ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101474:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101477:	39 c6                	cmp    %eax,%esi
f0101479:	74 04                	je     f010147f <mem_init+0x243>
f010147b:	39 c7                	cmp    %eax,%edi
f010147d:	75 19                	jne    f0101498 <mem_init+0x25c>
f010147f:	68 c4 60 10 f0       	push   $0xf01060c4
f0101484:	68 c7 68 10 f0       	push   $0xf01068c7
f0101489:	68 5c 03 00 00       	push   $0x35c
f010148e:	68 a1 68 10 f0       	push   $0xf01068a1
f0101493:	e8 a8 eb ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101498:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010149e:	8b 15 88 ae 22 f0    	mov    0xf022ae88,%edx
f01014a4:	c1 e2 0c             	shl    $0xc,%edx
f01014a7:	89 f8                	mov    %edi,%eax
f01014a9:	29 c8                	sub    %ecx,%eax
f01014ab:	c1 f8 03             	sar    $0x3,%eax
f01014ae:	c1 e0 0c             	shl    $0xc,%eax
f01014b1:	39 d0                	cmp    %edx,%eax
f01014b3:	72 19                	jb     f01014ce <mem_init+0x292>
f01014b5:	68 f9 69 10 f0       	push   $0xf01069f9
f01014ba:	68 c7 68 10 f0       	push   $0xf01068c7
f01014bf:	68 5d 03 00 00       	push   $0x35d
f01014c4:	68 a1 68 10 f0       	push   $0xf01068a1
f01014c9:	e8 72 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01014ce:	89 f0                	mov    %esi,%eax
f01014d0:	29 c8                	sub    %ecx,%eax
f01014d2:	c1 f8 03             	sar    $0x3,%eax
f01014d5:	c1 e0 0c             	shl    $0xc,%eax
f01014d8:	39 c2                	cmp    %eax,%edx
f01014da:	77 19                	ja     f01014f5 <mem_init+0x2b9>
f01014dc:	68 16 6a 10 f0       	push   $0xf0106a16
f01014e1:	68 c7 68 10 f0       	push   $0xf01068c7
f01014e6:	68 5e 03 00 00       	push   $0x35e
f01014eb:	68 a1 68 10 f0       	push   $0xf01068a1
f01014f0:	e8 4b eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01014f5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014f8:	29 c8                	sub    %ecx,%eax
f01014fa:	c1 f8 03             	sar    $0x3,%eax
f01014fd:	c1 e0 0c             	shl    $0xc,%eax
f0101500:	39 c2                	cmp    %eax,%edx
f0101502:	77 19                	ja     f010151d <mem_init+0x2e1>
f0101504:	68 33 6a 10 f0       	push   $0xf0106a33
f0101509:	68 c7 68 10 f0       	push   $0xf01068c7
f010150e:	68 5f 03 00 00       	push   $0x35f
f0101513:	68 a1 68 10 f0       	push   $0xf01068a1
f0101518:	e8 23 eb ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010151d:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0101522:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101525:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f010152c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010152f:	83 ec 0c             	sub    $0xc,%esp
f0101532:	6a 00                	push   $0x0
f0101534:	e8 99 f9 ff ff       	call   f0100ed2 <page_alloc>
f0101539:	83 c4 10             	add    $0x10,%esp
f010153c:	85 c0                	test   %eax,%eax
f010153e:	74 19                	je     f0101559 <mem_init+0x31d>
f0101540:	68 50 6a 10 f0       	push   $0xf0106a50
f0101545:	68 c7 68 10 f0       	push   $0xf01068c7
f010154a:	68 66 03 00 00       	push   $0x366
f010154f:	68 a1 68 10 f0       	push   $0xf01068a1
f0101554:	e8 e7 ea ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101559:	83 ec 0c             	sub    $0xc,%esp
f010155c:	57                   	push   %edi
f010155d:	e8 e6 f9 ff ff       	call   f0100f48 <page_free>
	page_free(pp1);
f0101562:	89 34 24             	mov    %esi,(%esp)
f0101565:	e8 de f9 ff ff       	call   f0100f48 <page_free>
	page_free(pp2);
f010156a:	83 c4 04             	add    $0x4,%esp
f010156d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101570:	e8 d3 f9 ff ff       	call   f0100f48 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101575:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010157c:	e8 51 f9 ff ff       	call   f0100ed2 <page_alloc>
f0101581:	89 c6                	mov    %eax,%esi
f0101583:	83 c4 10             	add    $0x10,%esp
f0101586:	85 c0                	test   %eax,%eax
f0101588:	75 19                	jne    f01015a3 <mem_init+0x367>
f010158a:	68 a5 69 10 f0       	push   $0xf01069a5
f010158f:	68 c7 68 10 f0       	push   $0xf01068c7
f0101594:	68 6d 03 00 00       	push   $0x36d
f0101599:	68 a1 68 10 f0       	push   $0xf01068a1
f010159e:	e8 9d ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01015a3:	83 ec 0c             	sub    $0xc,%esp
f01015a6:	6a 00                	push   $0x0
f01015a8:	e8 25 f9 ff ff       	call   f0100ed2 <page_alloc>
f01015ad:	89 c7                	mov    %eax,%edi
f01015af:	83 c4 10             	add    $0x10,%esp
f01015b2:	85 c0                	test   %eax,%eax
f01015b4:	75 19                	jne    f01015cf <mem_init+0x393>
f01015b6:	68 bb 69 10 f0       	push   $0xf01069bb
f01015bb:	68 c7 68 10 f0       	push   $0xf01068c7
f01015c0:	68 6e 03 00 00       	push   $0x36e
f01015c5:	68 a1 68 10 f0       	push   $0xf01068a1
f01015ca:	e8 71 ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01015cf:	83 ec 0c             	sub    $0xc,%esp
f01015d2:	6a 00                	push   $0x0
f01015d4:	e8 f9 f8 ff ff       	call   f0100ed2 <page_alloc>
f01015d9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015dc:	83 c4 10             	add    $0x10,%esp
f01015df:	85 c0                	test   %eax,%eax
f01015e1:	75 19                	jne    f01015fc <mem_init+0x3c0>
f01015e3:	68 d1 69 10 f0       	push   $0xf01069d1
f01015e8:	68 c7 68 10 f0       	push   $0xf01068c7
f01015ed:	68 6f 03 00 00       	push   $0x36f
f01015f2:	68 a1 68 10 f0       	push   $0xf01068a1
f01015f7:	e8 44 ea ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015fc:	39 fe                	cmp    %edi,%esi
f01015fe:	75 19                	jne    f0101619 <mem_init+0x3dd>
f0101600:	68 e7 69 10 f0       	push   $0xf01069e7
f0101605:	68 c7 68 10 f0       	push   $0xf01068c7
f010160a:	68 71 03 00 00       	push   $0x371
f010160f:	68 a1 68 10 f0       	push   $0xf01068a1
f0101614:	e8 27 ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101619:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010161c:	39 c7                	cmp    %eax,%edi
f010161e:	74 04                	je     f0101624 <mem_init+0x3e8>
f0101620:	39 c6                	cmp    %eax,%esi
f0101622:	75 19                	jne    f010163d <mem_init+0x401>
f0101624:	68 c4 60 10 f0       	push   $0xf01060c4
f0101629:	68 c7 68 10 f0       	push   $0xf01068c7
f010162e:	68 72 03 00 00       	push   $0x372
f0101633:	68 a1 68 10 f0       	push   $0xf01068a1
f0101638:	e8 03 ea ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010163d:	83 ec 0c             	sub    $0xc,%esp
f0101640:	6a 00                	push   $0x0
f0101642:	e8 8b f8 ff ff       	call   f0100ed2 <page_alloc>
f0101647:	83 c4 10             	add    $0x10,%esp
f010164a:	85 c0                	test   %eax,%eax
f010164c:	74 19                	je     f0101667 <mem_init+0x42b>
f010164e:	68 50 6a 10 f0       	push   $0xf0106a50
f0101653:	68 c7 68 10 f0       	push   $0xf01068c7
f0101658:	68 73 03 00 00       	push   $0x373
f010165d:	68 a1 68 10 f0       	push   $0xf01068a1
f0101662:	e8 d9 e9 ff ff       	call   f0100040 <_panic>
f0101667:	89 f0                	mov    %esi,%eax
f0101669:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f010166f:	c1 f8 03             	sar    $0x3,%eax
f0101672:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101675:	89 c2                	mov    %eax,%edx
f0101677:	c1 ea 0c             	shr    $0xc,%edx
f010167a:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0101680:	72 12                	jb     f0101694 <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101682:	50                   	push   %eax
f0101683:	68 04 5a 10 f0       	push   $0xf0105a04
f0101688:	6a 58                	push   $0x58
f010168a:	68 ad 68 10 f0       	push   $0xf01068ad
f010168f:	e8 ac e9 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101694:	83 ec 04             	sub    $0x4,%esp
f0101697:	68 00 10 00 00       	push   $0x1000
f010169c:	6a 01                	push   $0x1
f010169e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016a3:	50                   	push   %eax
f01016a4:	e8 70 36 00 00       	call   f0104d19 <memset>
	page_free(pp0);
f01016a9:	89 34 24             	mov    %esi,(%esp)
f01016ac:	e8 97 f8 ff ff       	call   f0100f48 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016b1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016b8:	e8 15 f8 ff ff       	call   f0100ed2 <page_alloc>
f01016bd:	83 c4 10             	add    $0x10,%esp
f01016c0:	85 c0                	test   %eax,%eax
f01016c2:	75 19                	jne    f01016dd <mem_init+0x4a1>
f01016c4:	68 5f 6a 10 f0       	push   $0xf0106a5f
f01016c9:	68 c7 68 10 f0       	push   $0xf01068c7
f01016ce:	68 78 03 00 00       	push   $0x378
f01016d3:	68 a1 68 10 f0       	push   $0xf01068a1
f01016d8:	e8 63 e9 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01016dd:	39 c6                	cmp    %eax,%esi
f01016df:	74 19                	je     f01016fa <mem_init+0x4be>
f01016e1:	68 7d 6a 10 f0       	push   $0xf0106a7d
f01016e6:	68 c7 68 10 f0       	push   $0xf01068c7
f01016eb:	68 79 03 00 00       	push   $0x379
f01016f0:	68 a1 68 10 f0       	push   $0xf01068a1
f01016f5:	e8 46 e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016fa:	89 f0                	mov    %esi,%eax
f01016fc:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0101702:	c1 f8 03             	sar    $0x3,%eax
f0101705:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101708:	89 c2                	mov    %eax,%edx
f010170a:	c1 ea 0c             	shr    $0xc,%edx
f010170d:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0101713:	72 12                	jb     f0101727 <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101715:	50                   	push   %eax
f0101716:	68 04 5a 10 f0       	push   $0xf0105a04
f010171b:	6a 58                	push   $0x58
f010171d:	68 ad 68 10 f0       	push   $0xf01068ad
f0101722:	e8 19 e9 ff ff       	call   f0100040 <_panic>
f0101727:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010172d:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101733:	80 38 00             	cmpb   $0x0,(%eax)
f0101736:	74 19                	je     f0101751 <mem_init+0x515>
f0101738:	68 8d 6a 10 f0       	push   $0xf0106a8d
f010173d:	68 c7 68 10 f0       	push   $0xf01068c7
f0101742:	68 7c 03 00 00       	push   $0x37c
f0101747:	68 a1 68 10 f0       	push   $0xf01068a1
f010174c:	e8 ef e8 ff ff       	call   f0100040 <_panic>
f0101751:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101754:	39 d0                	cmp    %edx,%eax
f0101756:	75 db                	jne    f0101733 <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101758:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010175b:	a3 40 a2 22 f0       	mov    %eax,0xf022a240

	// free the pages we took
	page_free(pp0);
f0101760:	83 ec 0c             	sub    $0xc,%esp
f0101763:	56                   	push   %esi
f0101764:	e8 df f7 ff ff       	call   f0100f48 <page_free>
	page_free(pp1);
f0101769:	89 3c 24             	mov    %edi,(%esp)
f010176c:	e8 d7 f7 ff ff       	call   f0100f48 <page_free>
	page_free(pp2);
f0101771:	83 c4 04             	add    $0x4,%esp
f0101774:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101777:	e8 cc f7 ff ff       	call   f0100f48 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010177c:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0101781:	83 c4 10             	add    $0x10,%esp
f0101784:	eb 05                	jmp    f010178b <mem_init+0x54f>
		--nfree;
f0101786:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101789:	8b 00                	mov    (%eax),%eax
f010178b:	85 c0                	test   %eax,%eax
f010178d:	75 f7                	jne    f0101786 <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f010178f:	85 db                	test   %ebx,%ebx
f0101791:	74 19                	je     f01017ac <mem_init+0x570>
f0101793:	68 97 6a 10 f0       	push   $0xf0106a97
f0101798:	68 c7 68 10 f0       	push   $0xf01068c7
f010179d:	68 89 03 00 00       	push   $0x389
f01017a2:	68 a1 68 10 f0       	push   $0xf01068a1
f01017a7:	e8 94 e8 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017ac:	83 ec 0c             	sub    $0xc,%esp
f01017af:	68 e4 60 10 f0       	push   $0xf01060e4
f01017b4:	e8 db 1e 00 00       	call   f0103694 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017c0:	e8 0d f7 ff ff       	call   f0100ed2 <page_alloc>
f01017c5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017c8:	83 c4 10             	add    $0x10,%esp
f01017cb:	85 c0                	test   %eax,%eax
f01017cd:	75 19                	jne    f01017e8 <mem_init+0x5ac>
f01017cf:	68 a5 69 10 f0       	push   $0xf01069a5
f01017d4:	68 c7 68 10 f0       	push   $0xf01068c7
f01017d9:	68 ef 03 00 00       	push   $0x3ef
f01017de:	68 a1 68 10 f0       	push   $0xf01068a1
f01017e3:	e8 58 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01017e8:	83 ec 0c             	sub    $0xc,%esp
f01017eb:	6a 00                	push   $0x0
f01017ed:	e8 e0 f6 ff ff       	call   f0100ed2 <page_alloc>
f01017f2:	89 c3                	mov    %eax,%ebx
f01017f4:	83 c4 10             	add    $0x10,%esp
f01017f7:	85 c0                	test   %eax,%eax
f01017f9:	75 19                	jne    f0101814 <mem_init+0x5d8>
f01017fb:	68 bb 69 10 f0       	push   $0xf01069bb
f0101800:	68 c7 68 10 f0       	push   $0xf01068c7
f0101805:	68 f0 03 00 00       	push   $0x3f0
f010180a:	68 a1 68 10 f0       	push   $0xf01068a1
f010180f:	e8 2c e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101814:	83 ec 0c             	sub    $0xc,%esp
f0101817:	6a 00                	push   $0x0
f0101819:	e8 b4 f6 ff ff       	call   f0100ed2 <page_alloc>
f010181e:	89 c6                	mov    %eax,%esi
f0101820:	83 c4 10             	add    $0x10,%esp
f0101823:	85 c0                	test   %eax,%eax
f0101825:	75 19                	jne    f0101840 <mem_init+0x604>
f0101827:	68 d1 69 10 f0       	push   $0xf01069d1
f010182c:	68 c7 68 10 f0       	push   $0xf01068c7
f0101831:	68 f1 03 00 00       	push   $0x3f1
f0101836:	68 a1 68 10 f0       	push   $0xf01068a1
f010183b:	e8 00 e8 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101840:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101843:	75 19                	jne    f010185e <mem_init+0x622>
f0101845:	68 e7 69 10 f0       	push   $0xf01069e7
f010184a:	68 c7 68 10 f0       	push   $0xf01068c7
f010184f:	68 f4 03 00 00       	push   $0x3f4
f0101854:	68 a1 68 10 f0       	push   $0xf01068a1
f0101859:	e8 e2 e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010185e:	39 c3                	cmp    %eax,%ebx
f0101860:	74 05                	je     f0101867 <mem_init+0x62b>
f0101862:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101865:	75 19                	jne    f0101880 <mem_init+0x644>
f0101867:	68 c4 60 10 f0       	push   $0xf01060c4
f010186c:	68 c7 68 10 f0       	push   $0xf01068c7
f0101871:	68 f5 03 00 00       	push   $0x3f5
f0101876:	68 a1 68 10 f0       	push   $0xf01068a1
f010187b:	e8 c0 e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101880:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0101885:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101888:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f010188f:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101892:	83 ec 0c             	sub    $0xc,%esp
f0101895:	6a 00                	push   $0x0
f0101897:	e8 36 f6 ff ff       	call   f0100ed2 <page_alloc>
f010189c:	83 c4 10             	add    $0x10,%esp
f010189f:	85 c0                	test   %eax,%eax
f01018a1:	74 19                	je     f01018bc <mem_init+0x680>
f01018a3:	68 50 6a 10 f0       	push   $0xf0106a50
f01018a8:	68 c7 68 10 f0       	push   $0xf01068c7
f01018ad:	68 fc 03 00 00       	push   $0x3fc
f01018b2:	68 a1 68 10 f0       	push   $0xf01068a1
f01018b7:	e8 84 e7 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01018bc:	83 ec 04             	sub    $0x4,%esp
f01018bf:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01018c2:	50                   	push   %eax
f01018c3:	6a 00                	push   $0x0
f01018c5:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01018cb:	e8 c4 f7 ff ff       	call   f0101094 <page_lookup>
f01018d0:	83 c4 10             	add    $0x10,%esp
f01018d3:	85 c0                	test   %eax,%eax
f01018d5:	74 19                	je     f01018f0 <mem_init+0x6b4>
f01018d7:	68 04 61 10 f0       	push   $0xf0106104
f01018dc:	68 c7 68 10 f0       	push   $0xf01068c7
f01018e1:	68 ff 03 00 00       	push   $0x3ff
f01018e6:	68 a1 68 10 f0       	push   $0xf01068a1
f01018eb:	e8 50 e7 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01018f0:	6a 02                	push   $0x2
f01018f2:	6a 00                	push   $0x0
f01018f4:	53                   	push   %ebx
f01018f5:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01018fb:	e8 6c f8 ff ff       	call   f010116c <page_insert>
f0101900:	83 c4 10             	add    $0x10,%esp
f0101903:	85 c0                	test   %eax,%eax
f0101905:	78 19                	js     f0101920 <mem_init+0x6e4>
f0101907:	68 3c 61 10 f0       	push   $0xf010613c
f010190c:	68 c7 68 10 f0       	push   $0xf01068c7
f0101911:	68 02 04 00 00       	push   $0x402
f0101916:	68 a1 68 10 f0       	push   $0xf01068a1
f010191b:	e8 20 e7 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101920:	83 ec 0c             	sub    $0xc,%esp
f0101923:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101926:	e8 1d f6 ff ff       	call   f0100f48 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010192b:	6a 02                	push   $0x2
f010192d:	6a 00                	push   $0x0
f010192f:	53                   	push   %ebx
f0101930:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101936:	e8 31 f8 ff ff       	call   f010116c <page_insert>
f010193b:	83 c4 20             	add    $0x20,%esp
f010193e:	85 c0                	test   %eax,%eax
f0101940:	74 19                	je     f010195b <mem_init+0x71f>
f0101942:	68 6c 61 10 f0       	push   $0xf010616c
f0101947:	68 c7 68 10 f0       	push   $0xf01068c7
f010194c:	68 06 04 00 00       	push   $0x406
f0101951:	68 a1 68 10 f0       	push   $0xf01068a1
f0101956:	e8 e5 e6 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010195b:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101961:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0101966:	89 c1                	mov    %eax,%ecx
f0101968:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010196b:	8b 17                	mov    (%edi),%edx
f010196d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101973:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101976:	29 c8                	sub    %ecx,%eax
f0101978:	c1 f8 03             	sar    $0x3,%eax
f010197b:	c1 e0 0c             	shl    $0xc,%eax
f010197e:	39 c2                	cmp    %eax,%edx
f0101980:	74 19                	je     f010199b <mem_init+0x75f>
f0101982:	68 9c 61 10 f0       	push   $0xf010619c
f0101987:	68 c7 68 10 f0       	push   $0xf01068c7
f010198c:	68 07 04 00 00       	push   $0x407
f0101991:	68 a1 68 10 f0       	push   $0xf01068a1
f0101996:	e8 a5 e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010199b:	ba 00 00 00 00       	mov    $0x0,%edx
f01019a0:	89 f8                	mov    %edi,%eax
f01019a2:	e8 dc f0 ff ff       	call   f0100a83 <check_va2pa>
f01019a7:	89 da                	mov    %ebx,%edx
f01019a9:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01019ac:	c1 fa 03             	sar    $0x3,%edx
f01019af:	c1 e2 0c             	shl    $0xc,%edx
f01019b2:	39 d0                	cmp    %edx,%eax
f01019b4:	74 19                	je     f01019cf <mem_init+0x793>
f01019b6:	68 c4 61 10 f0       	push   $0xf01061c4
f01019bb:	68 c7 68 10 f0       	push   $0xf01068c7
f01019c0:	68 08 04 00 00       	push   $0x408
f01019c5:	68 a1 68 10 f0       	push   $0xf01068a1
f01019ca:	e8 71 e6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01019cf:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01019d4:	74 19                	je     f01019ef <mem_init+0x7b3>
f01019d6:	68 a2 6a 10 f0       	push   $0xf0106aa2
f01019db:	68 c7 68 10 f0       	push   $0xf01068c7
f01019e0:	68 09 04 00 00       	push   $0x409
f01019e5:	68 a1 68 10 f0       	push   $0xf01068a1
f01019ea:	e8 51 e6 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f01019ef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019f2:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01019f7:	74 19                	je     f0101a12 <mem_init+0x7d6>
f01019f9:	68 b3 6a 10 f0       	push   $0xf0106ab3
f01019fe:	68 c7 68 10 f0       	push   $0xf01068c7
f0101a03:	68 0a 04 00 00       	push   $0x40a
f0101a08:	68 a1 68 10 f0       	push   $0xf01068a1
f0101a0d:	e8 2e e6 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a12:	6a 02                	push   $0x2
f0101a14:	68 00 10 00 00       	push   $0x1000
f0101a19:	56                   	push   %esi
f0101a1a:	57                   	push   %edi
f0101a1b:	e8 4c f7 ff ff       	call   f010116c <page_insert>
f0101a20:	83 c4 10             	add    $0x10,%esp
f0101a23:	85 c0                	test   %eax,%eax
f0101a25:	74 19                	je     f0101a40 <mem_init+0x804>
f0101a27:	68 f4 61 10 f0       	push   $0xf01061f4
f0101a2c:	68 c7 68 10 f0       	push   $0xf01068c7
f0101a31:	68 0d 04 00 00       	push   $0x40d
f0101a36:	68 a1 68 10 f0       	push   $0xf01068a1
f0101a3b:	e8 00 e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a40:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a45:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101a4a:	e8 34 f0 ff ff       	call   f0100a83 <check_va2pa>
f0101a4f:	89 f2                	mov    %esi,%edx
f0101a51:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101a57:	c1 fa 03             	sar    $0x3,%edx
f0101a5a:	c1 e2 0c             	shl    $0xc,%edx
f0101a5d:	39 d0                	cmp    %edx,%eax
f0101a5f:	74 19                	je     f0101a7a <mem_init+0x83e>
f0101a61:	68 30 62 10 f0       	push   $0xf0106230
f0101a66:	68 c7 68 10 f0       	push   $0xf01068c7
f0101a6b:	68 0e 04 00 00       	push   $0x40e
f0101a70:	68 a1 68 10 f0       	push   $0xf01068a1
f0101a75:	e8 c6 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101a7a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a7f:	74 19                	je     f0101a9a <mem_init+0x85e>
f0101a81:	68 c4 6a 10 f0       	push   $0xf0106ac4
f0101a86:	68 c7 68 10 f0       	push   $0xf01068c7
f0101a8b:	68 0f 04 00 00       	push   $0x40f
f0101a90:	68 a1 68 10 f0       	push   $0xf01068a1
f0101a95:	e8 a6 e5 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101a9a:	83 ec 0c             	sub    $0xc,%esp
f0101a9d:	6a 00                	push   $0x0
f0101a9f:	e8 2e f4 ff ff       	call   f0100ed2 <page_alloc>
f0101aa4:	83 c4 10             	add    $0x10,%esp
f0101aa7:	85 c0                	test   %eax,%eax
f0101aa9:	74 19                	je     f0101ac4 <mem_init+0x888>
f0101aab:	68 50 6a 10 f0       	push   $0xf0106a50
f0101ab0:	68 c7 68 10 f0       	push   $0xf01068c7
f0101ab5:	68 12 04 00 00       	push   $0x412
f0101aba:	68 a1 68 10 f0       	push   $0xf01068a1
f0101abf:	e8 7c e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ac4:	6a 02                	push   $0x2
f0101ac6:	68 00 10 00 00       	push   $0x1000
f0101acb:	56                   	push   %esi
f0101acc:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101ad2:	e8 95 f6 ff ff       	call   f010116c <page_insert>
f0101ad7:	83 c4 10             	add    $0x10,%esp
f0101ada:	85 c0                	test   %eax,%eax
f0101adc:	74 19                	je     f0101af7 <mem_init+0x8bb>
f0101ade:	68 f4 61 10 f0       	push   $0xf01061f4
f0101ae3:	68 c7 68 10 f0       	push   $0xf01068c7
f0101ae8:	68 15 04 00 00       	push   $0x415
f0101aed:	68 a1 68 10 f0       	push   $0xf01068a1
f0101af2:	e8 49 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101af7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101afc:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101b01:	e8 7d ef ff ff       	call   f0100a83 <check_va2pa>
f0101b06:	89 f2                	mov    %esi,%edx
f0101b08:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101b0e:	c1 fa 03             	sar    $0x3,%edx
f0101b11:	c1 e2 0c             	shl    $0xc,%edx
f0101b14:	39 d0                	cmp    %edx,%eax
f0101b16:	74 19                	je     f0101b31 <mem_init+0x8f5>
f0101b18:	68 30 62 10 f0       	push   $0xf0106230
f0101b1d:	68 c7 68 10 f0       	push   $0xf01068c7
f0101b22:	68 16 04 00 00       	push   $0x416
f0101b27:	68 a1 68 10 f0       	push   $0xf01068a1
f0101b2c:	e8 0f e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b31:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b36:	74 19                	je     f0101b51 <mem_init+0x915>
f0101b38:	68 c4 6a 10 f0       	push   $0xf0106ac4
f0101b3d:	68 c7 68 10 f0       	push   $0xf01068c7
f0101b42:	68 17 04 00 00       	push   $0x417
f0101b47:	68 a1 68 10 f0       	push   $0xf01068a1
f0101b4c:	e8 ef e4 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b51:	83 ec 0c             	sub    $0xc,%esp
f0101b54:	6a 00                	push   $0x0
f0101b56:	e8 77 f3 ff ff       	call   f0100ed2 <page_alloc>
f0101b5b:	83 c4 10             	add    $0x10,%esp
f0101b5e:	85 c0                	test   %eax,%eax
f0101b60:	74 19                	je     f0101b7b <mem_init+0x93f>
f0101b62:	68 50 6a 10 f0       	push   $0xf0106a50
f0101b67:	68 c7 68 10 f0       	push   $0xf01068c7
f0101b6c:	68 1b 04 00 00       	push   $0x41b
f0101b71:	68 a1 68 10 f0       	push   $0xf01068a1
f0101b76:	e8 c5 e4 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b7b:	8b 15 8c ae 22 f0    	mov    0xf022ae8c,%edx
f0101b81:	8b 02                	mov    (%edx),%eax
f0101b83:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b88:	89 c1                	mov    %eax,%ecx
f0101b8a:	c1 e9 0c             	shr    $0xc,%ecx
f0101b8d:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0101b93:	72 15                	jb     f0101baa <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b95:	50                   	push   %eax
f0101b96:	68 04 5a 10 f0       	push   $0xf0105a04
f0101b9b:	68 1e 04 00 00       	push   $0x41e
f0101ba0:	68 a1 68 10 f0       	push   $0xf01068a1
f0101ba5:	e8 96 e4 ff ff       	call   f0100040 <_panic>
f0101baa:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101baf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101bb2:	83 ec 04             	sub    $0x4,%esp
f0101bb5:	6a 00                	push   $0x0
f0101bb7:	68 00 10 00 00       	push   $0x1000
f0101bbc:	52                   	push   %edx
f0101bbd:	e8 bc f3 ff ff       	call   f0100f7e <pgdir_walk>
f0101bc2:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101bc5:	8d 51 04             	lea    0x4(%ecx),%edx
f0101bc8:	83 c4 10             	add    $0x10,%esp
f0101bcb:	39 d0                	cmp    %edx,%eax
f0101bcd:	74 19                	je     f0101be8 <mem_init+0x9ac>
f0101bcf:	68 60 62 10 f0       	push   $0xf0106260
f0101bd4:	68 c7 68 10 f0       	push   $0xf01068c7
f0101bd9:	68 1f 04 00 00       	push   $0x41f
f0101bde:	68 a1 68 10 f0       	push   $0xf01068a1
f0101be3:	e8 58 e4 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101be8:	6a 06                	push   $0x6
f0101bea:	68 00 10 00 00       	push   $0x1000
f0101bef:	56                   	push   %esi
f0101bf0:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101bf6:	e8 71 f5 ff ff       	call   f010116c <page_insert>
f0101bfb:	83 c4 10             	add    $0x10,%esp
f0101bfe:	85 c0                	test   %eax,%eax
f0101c00:	74 19                	je     f0101c1b <mem_init+0x9df>
f0101c02:	68 a0 62 10 f0       	push   $0xf01062a0
f0101c07:	68 c7 68 10 f0       	push   $0xf01068c7
f0101c0c:	68 22 04 00 00       	push   $0x422
f0101c11:	68 a1 68 10 f0       	push   $0xf01068a1
f0101c16:	e8 25 e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c1b:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101c21:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c26:	89 f8                	mov    %edi,%eax
f0101c28:	e8 56 ee ff ff       	call   f0100a83 <check_va2pa>
f0101c2d:	89 f2                	mov    %esi,%edx
f0101c2f:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101c35:	c1 fa 03             	sar    $0x3,%edx
f0101c38:	c1 e2 0c             	shl    $0xc,%edx
f0101c3b:	39 d0                	cmp    %edx,%eax
f0101c3d:	74 19                	je     f0101c58 <mem_init+0xa1c>
f0101c3f:	68 30 62 10 f0       	push   $0xf0106230
f0101c44:	68 c7 68 10 f0       	push   $0xf01068c7
f0101c49:	68 23 04 00 00       	push   $0x423
f0101c4e:	68 a1 68 10 f0       	push   $0xf01068a1
f0101c53:	e8 e8 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101c58:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c5d:	74 19                	je     f0101c78 <mem_init+0xa3c>
f0101c5f:	68 c4 6a 10 f0       	push   $0xf0106ac4
f0101c64:	68 c7 68 10 f0       	push   $0xf01068c7
f0101c69:	68 24 04 00 00       	push   $0x424
f0101c6e:	68 a1 68 10 f0       	push   $0xf01068a1
f0101c73:	e8 c8 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c78:	83 ec 04             	sub    $0x4,%esp
f0101c7b:	6a 00                	push   $0x0
f0101c7d:	68 00 10 00 00       	push   $0x1000
f0101c82:	57                   	push   %edi
f0101c83:	e8 f6 f2 ff ff       	call   f0100f7e <pgdir_walk>
f0101c88:	83 c4 10             	add    $0x10,%esp
f0101c8b:	f6 00 04             	testb  $0x4,(%eax)
f0101c8e:	75 19                	jne    f0101ca9 <mem_init+0xa6d>
f0101c90:	68 e0 62 10 f0       	push   $0xf01062e0
f0101c95:	68 c7 68 10 f0       	push   $0xf01068c7
f0101c9a:	68 25 04 00 00       	push   $0x425
f0101c9f:	68 a1 68 10 f0       	push   $0xf01068a1
f0101ca4:	e8 97 e3 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101ca9:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101cae:	f6 00 04             	testb  $0x4,(%eax)
f0101cb1:	75 19                	jne    f0101ccc <mem_init+0xa90>
f0101cb3:	68 d5 6a 10 f0       	push   $0xf0106ad5
f0101cb8:	68 c7 68 10 f0       	push   $0xf01068c7
f0101cbd:	68 26 04 00 00       	push   $0x426
f0101cc2:	68 a1 68 10 f0       	push   $0xf01068a1
f0101cc7:	e8 74 e3 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ccc:	6a 02                	push   $0x2
f0101cce:	68 00 10 00 00       	push   $0x1000
f0101cd3:	56                   	push   %esi
f0101cd4:	50                   	push   %eax
f0101cd5:	e8 92 f4 ff ff       	call   f010116c <page_insert>
f0101cda:	83 c4 10             	add    $0x10,%esp
f0101cdd:	85 c0                	test   %eax,%eax
f0101cdf:	74 19                	je     f0101cfa <mem_init+0xabe>
f0101ce1:	68 f4 61 10 f0       	push   $0xf01061f4
f0101ce6:	68 c7 68 10 f0       	push   $0xf01068c7
f0101ceb:	68 29 04 00 00       	push   $0x429
f0101cf0:	68 a1 68 10 f0       	push   $0xf01068a1
f0101cf5:	e8 46 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101cfa:	83 ec 04             	sub    $0x4,%esp
f0101cfd:	6a 00                	push   $0x0
f0101cff:	68 00 10 00 00       	push   $0x1000
f0101d04:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d0a:	e8 6f f2 ff ff       	call   f0100f7e <pgdir_walk>
f0101d0f:	83 c4 10             	add    $0x10,%esp
f0101d12:	f6 00 02             	testb  $0x2,(%eax)
f0101d15:	75 19                	jne    f0101d30 <mem_init+0xaf4>
f0101d17:	68 14 63 10 f0       	push   $0xf0106314
f0101d1c:	68 c7 68 10 f0       	push   $0xf01068c7
f0101d21:	68 2a 04 00 00       	push   $0x42a
f0101d26:	68 a1 68 10 f0       	push   $0xf01068a1
f0101d2b:	e8 10 e3 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d30:	83 ec 04             	sub    $0x4,%esp
f0101d33:	6a 00                	push   $0x0
f0101d35:	68 00 10 00 00       	push   $0x1000
f0101d3a:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d40:	e8 39 f2 ff ff       	call   f0100f7e <pgdir_walk>
f0101d45:	83 c4 10             	add    $0x10,%esp
f0101d48:	f6 00 04             	testb  $0x4,(%eax)
f0101d4b:	74 19                	je     f0101d66 <mem_init+0xb2a>
f0101d4d:	68 48 63 10 f0       	push   $0xf0106348
f0101d52:	68 c7 68 10 f0       	push   $0xf01068c7
f0101d57:	68 2b 04 00 00       	push   $0x42b
f0101d5c:	68 a1 68 10 f0       	push   $0xf01068a1
f0101d61:	e8 da e2 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d66:	6a 02                	push   $0x2
f0101d68:	68 00 00 40 00       	push   $0x400000
f0101d6d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101d70:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d76:	e8 f1 f3 ff ff       	call   f010116c <page_insert>
f0101d7b:	83 c4 10             	add    $0x10,%esp
f0101d7e:	85 c0                	test   %eax,%eax
f0101d80:	78 19                	js     f0101d9b <mem_init+0xb5f>
f0101d82:	68 80 63 10 f0       	push   $0xf0106380
f0101d87:	68 c7 68 10 f0       	push   $0xf01068c7
f0101d8c:	68 2e 04 00 00       	push   $0x42e
f0101d91:	68 a1 68 10 f0       	push   $0xf01068a1
f0101d96:	e8 a5 e2 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d9b:	6a 02                	push   $0x2
f0101d9d:	68 00 10 00 00       	push   $0x1000
f0101da2:	53                   	push   %ebx
f0101da3:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101da9:	e8 be f3 ff ff       	call   f010116c <page_insert>
f0101dae:	83 c4 10             	add    $0x10,%esp
f0101db1:	85 c0                	test   %eax,%eax
f0101db3:	74 19                	je     f0101dce <mem_init+0xb92>
f0101db5:	68 b8 63 10 f0       	push   $0xf01063b8
f0101dba:	68 c7 68 10 f0       	push   $0xf01068c7
f0101dbf:	68 31 04 00 00       	push   $0x431
f0101dc4:	68 a1 68 10 f0       	push   $0xf01068a1
f0101dc9:	e8 72 e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101dce:	83 ec 04             	sub    $0x4,%esp
f0101dd1:	6a 00                	push   $0x0
f0101dd3:	68 00 10 00 00       	push   $0x1000
f0101dd8:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101dde:	e8 9b f1 ff ff       	call   f0100f7e <pgdir_walk>
f0101de3:	83 c4 10             	add    $0x10,%esp
f0101de6:	f6 00 04             	testb  $0x4,(%eax)
f0101de9:	74 19                	je     f0101e04 <mem_init+0xbc8>
f0101deb:	68 48 63 10 f0       	push   $0xf0106348
f0101df0:	68 c7 68 10 f0       	push   $0xf01068c7
f0101df5:	68 32 04 00 00       	push   $0x432
f0101dfa:	68 a1 68 10 f0       	push   $0xf01068a1
f0101dff:	e8 3c e2 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e04:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101e0a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e0f:	89 f8                	mov    %edi,%eax
f0101e11:	e8 6d ec ff ff       	call   f0100a83 <check_va2pa>
f0101e16:	89 c1                	mov    %eax,%ecx
f0101e18:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e1b:	89 d8                	mov    %ebx,%eax
f0101e1d:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0101e23:	c1 f8 03             	sar    $0x3,%eax
f0101e26:	c1 e0 0c             	shl    $0xc,%eax
f0101e29:	39 c1                	cmp    %eax,%ecx
f0101e2b:	74 19                	je     f0101e46 <mem_init+0xc0a>
f0101e2d:	68 f4 63 10 f0       	push   $0xf01063f4
f0101e32:	68 c7 68 10 f0       	push   $0xf01068c7
f0101e37:	68 35 04 00 00       	push   $0x435
f0101e3c:	68 a1 68 10 f0       	push   $0xf01068a1
f0101e41:	e8 fa e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e46:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e4b:	89 f8                	mov    %edi,%eax
f0101e4d:	e8 31 ec ff ff       	call   f0100a83 <check_va2pa>
f0101e52:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101e55:	74 19                	je     f0101e70 <mem_init+0xc34>
f0101e57:	68 20 64 10 f0       	push   $0xf0106420
f0101e5c:	68 c7 68 10 f0       	push   $0xf01068c7
f0101e61:	68 36 04 00 00       	push   $0x436
f0101e66:	68 a1 68 10 f0       	push   $0xf01068a1
f0101e6b:	e8 d0 e1 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e70:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101e75:	74 19                	je     f0101e90 <mem_init+0xc54>
f0101e77:	68 eb 6a 10 f0       	push   $0xf0106aeb
f0101e7c:	68 c7 68 10 f0       	push   $0xf01068c7
f0101e81:	68 38 04 00 00       	push   $0x438
f0101e86:	68 a1 68 10 f0       	push   $0xf01068a1
f0101e8b:	e8 b0 e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101e90:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e95:	74 19                	je     f0101eb0 <mem_init+0xc74>
f0101e97:	68 fc 6a 10 f0       	push   $0xf0106afc
f0101e9c:	68 c7 68 10 f0       	push   $0xf01068c7
f0101ea1:	68 39 04 00 00       	push   $0x439
f0101ea6:	68 a1 68 10 f0       	push   $0xf01068a1
f0101eab:	e8 90 e1 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101eb0:	83 ec 0c             	sub    $0xc,%esp
f0101eb3:	6a 00                	push   $0x0
f0101eb5:	e8 18 f0 ff ff       	call   f0100ed2 <page_alloc>
f0101eba:	83 c4 10             	add    $0x10,%esp
f0101ebd:	85 c0                	test   %eax,%eax
f0101ebf:	74 04                	je     f0101ec5 <mem_init+0xc89>
f0101ec1:	39 c6                	cmp    %eax,%esi
f0101ec3:	74 19                	je     f0101ede <mem_init+0xca2>
f0101ec5:	68 50 64 10 f0       	push   $0xf0106450
f0101eca:	68 c7 68 10 f0       	push   $0xf01068c7
f0101ecf:	68 3c 04 00 00       	push   $0x43c
f0101ed4:	68 a1 68 10 f0       	push   $0xf01068a1
f0101ed9:	e8 62 e1 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ede:	83 ec 08             	sub    $0x8,%esp
f0101ee1:	6a 00                	push   $0x0
f0101ee3:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101ee9:	e8 35 f2 ff ff       	call   f0101123 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101eee:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101ef4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ef9:	89 f8                	mov    %edi,%eax
f0101efb:	e8 83 eb ff ff       	call   f0100a83 <check_va2pa>
f0101f00:	83 c4 10             	add    $0x10,%esp
f0101f03:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f06:	74 19                	je     f0101f21 <mem_init+0xce5>
f0101f08:	68 74 64 10 f0       	push   $0xf0106474
f0101f0d:	68 c7 68 10 f0       	push   $0xf01068c7
f0101f12:	68 40 04 00 00       	push   $0x440
f0101f17:	68 a1 68 10 f0       	push   $0xf01068a1
f0101f1c:	e8 1f e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f21:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f26:	89 f8                	mov    %edi,%eax
f0101f28:	e8 56 eb ff ff       	call   f0100a83 <check_va2pa>
f0101f2d:	89 da                	mov    %ebx,%edx
f0101f2f:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101f35:	c1 fa 03             	sar    $0x3,%edx
f0101f38:	c1 e2 0c             	shl    $0xc,%edx
f0101f3b:	39 d0                	cmp    %edx,%eax
f0101f3d:	74 19                	je     f0101f58 <mem_init+0xd1c>
f0101f3f:	68 20 64 10 f0       	push   $0xf0106420
f0101f44:	68 c7 68 10 f0       	push   $0xf01068c7
f0101f49:	68 41 04 00 00       	push   $0x441
f0101f4e:	68 a1 68 10 f0       	push   $0xf01068a1
f0101f53:	e8 e8 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101f58:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101f5d:	74 19                	je     f0101f78 <mem_init+0xd3c>
f0101f5f:	68 a2 6a 10 f0       	push   $0xf0106aa2
f0101f64:	68 c7 68 10 f0       	push   $0xf01068c7
f0101f69:	68 42 04 00 00       	push   $0x442
f0101f6e:	68 a1 68 10 f0       	push   $0xf01068a1
f0101f73:	e8 c8 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101f78:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f7d:	74 19                	je     f0101f98 <mem_init+0xd5c>
f0101f7f:	68 fc 6a 10 f0       	push   $0xf0106afc
f0101f84:	68 c7 68 10 f0       	push   $0xf01068c7
f0101f89:	68 43 04 00 00       	push   $0x443
f0101f8e:	68 a1 68 10 f0       	push   $0xf01068a1
f0101f93:	e8 a8 e0 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101f98:	6a 00                	push   $0x0
f0101f9a:	68 00 10 00 00       	push   $0x1000
f0101f9f:	53                   	push   %ebx
f0101fa0:	57                   	push   %edi
f0101fa1:	e8 c6 f1 ff ff       	call   f010116c <page_insert>
f0101fa6:	83 c4 10             	add    $0x10,%esp
f0101fa9:	85 c0                	test   %eax,%eax
f0101fab:	74 19                	je     f0101fc6 <mem_init+0xd8a>
f0101fad:	68 98 64 10 f0       	push   $0xf0106498
f0101fb2:	68 c7 68 10 f0       	push   $0xf01068c7
f0101fb7:	68 46 04 00 00       	push   $0x446
f0101fbc:	68 a1 68 10 f0       	push   $0xf01068a1
f0101fc1:	e8 7a e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0101fc6:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101fcb:	75 19                	jne    f0101fe6 <mem_init+0xdaa>
f0101fcd:	68 0d 6b 10 f0       	push   $0xf0106b0d
f0101fd2:	68 c7 68 10 f0       	push   $0xf01068c7
f0101fd7:	68 47 04 00 00       	push   $0x447
f0101fdc:	68 a1 68 10 f0       	push   $0xf01068a1
f0101fe1:	e8 5a e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0101fe6:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101fe9:	74 19                	je     f0102004 <mem_init+0xdc8>
f0101feb:	68 19 6b 10 f0       	push   $0xf0106b19
f0101ff0:	68 c7 68 10 f0       	push   $0xf01068c7
f0101ff5:	68 48 04 00 00       	push   $0x448
f0101ffa:	68 a1 68 10 f0       	push   $0xf01068a1
f0101fff:	e8 3c e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102004:	83 ec 08             	sub    $0x8,%esp
f0102007:	68 00 10 00 00       	push   $0x1000
f010200c:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102012:	e8 0c f1 ff ff       	call   f0101123 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102017:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f010201d:	ba 00 00 00 00       	mov    $0x0,%edx
f0102022:	89 f8                	mov    %edi,%eax
f0102024:	e8 5a ea ff ff       	call   f0100a83 <check_va2pa>
f0102029:	83 c4 10             	add    $0x10,%esp
f010202c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010202f:	74 19                	je     f010204a <mem_init+0xe0e>
f0102031:	68 74 64 10 f0       	push   $0xf0106474
f0102036:	68 c7 68 10 f0       	push   $0xf01068c7
f010203b:	68 4c 04 00 00       	push   $0x44c
f0102040:	68 a1 68 10 f0       	push   $0xf01068a1
f0102045:	e8 f6 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010204a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010204f:	89 f8                	mov    %edi,%eax
f0102051:	e8 2d ea ff ff       	call   f0100a83 <check_va2pa>
f0102056:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102059:	74 19                	je     f0102074 <mem_init+0xe38>
f010205b:	68 d0 64 10 f0       	push   $0xf01064d0
f0102060:	68 c7 68 10 f0       	push   $0xf01068c7
f0102065:	68 4d 04 00 00       	push   $0x44d
f010206a:	68 a1 68 10 f0       	push   $0xf01068a1
f010206f:	e8 cc df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102074:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102079:	74 19                	je     f0102094 <mem_init+0xe58>
f010207b:	68 2e 6b 10 f0       	push   $0xf0106b2e
f0102080:	68 c7 68 10 f0       	push   $0xf01068c7
f0102085:	68 4e 04 00 00       	push   $0x44e
f010208a:	68 a1 68 10 f0       	push   $0xf01068a1
f010208f:	e8 ac df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102094:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102099:	74 19                	je     f01020b4 <mem_init+0xe78>
f010209b:	68 fc 6a 10 f0       	push   $0xf0106afc
f01020a0:	68 c7 68 10 f0       	push   $0xf01068c7
f01020a5:	68 4f 04 00 00       	push   $0x44f
f01020aa:	68 a1 68 10 f0       	push   $0xf01068a1
f01020af:	e8 8c df ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01020b4:	83 ec 0c             	sub    $0xc,%esp
f01020b7:	6a 00                	push   $0x0
f01020b9:	e8 14 ee ff ff       	call   f0100ed2 <page_alloc>
f01020be:	83 c4 10             	add    $0x10,%esp
f01020c1:	39 c3                	cmp    %eax,%ebx
f01020c3:	75 04                	jne    f01020c9 <mem_init+0xe8d>
f01020c5:	85 c0                	test   %eax,%eax
f01020c7:	75 19                	jne    f01020e2 <mem_init+0xea6>
f01020c9:	68 f8 64 10 f0       	push   $0xf01064f8
f01020ce:	68 c7 68 10 f0       	push   $0xf01068c7
f01020d3:	68 52 04 00 00       	push   $0x452
f01020d8:	68 a1 68 10 f0       	push   $0xf01068a1
f01020dd:	e8 5e df ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01020e2:	83 ec 0c             	sub    $0xc,%esp
f01020e5:	6a 00                	push   $0x0
f01020e7:	e8 e6 ed ff ff       	call   f0100ed2 <page_alloc>
f01020ec:	83 c4 10             	add    $0x10,%esp
f01020ef:	85 c0                	test   %eax,%eax
f01020f1:	74 19                	je     f010210c <mem_init+0xed0>
f01020f3:	68 50 6a 10 f0       	push   $0xf0106a50
f01020f8:	68 c7 68 10 f0       	push   $0xf01068c7
f01020fd:	68 55 04 00 00       	push   $0x455
f0102102:	68 a1 68 10 f0       	push   $0xf01068a1
f0102107:	e8 34 df ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010210c:	8b 0d 8c ae 22 f0    	mov    0xf022ae8c,%ecx
f0102112:	8b 11                	mov    (%ecx),%edx
f0102114:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010211a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010211d:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102123:	c1 f8 03             	sar    $0x3,%eax
f0102126:	c1 e0 0c             	shl    $0xc,%eax
f0102129:	39 c2                	cmp    %eax,%edx
f010212b:	74 19                	je     f0102146 <mem_init+0xf0a>
f010212d:	68 9c 61 10 f0       	push   $0xf010619c
f0102132:	68 c7 68 10 f0       	push   $0xf01068c7
f0102137:	68 58 04 00 00       	push   $0x458
f010213c:	68 a1 68 10 f0       	push   $0xf01068a1
f0102141:	e8 fa de ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102146:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010214c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010214f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102154:	74 19                	je     f010216f <mem_init+0xf33>
f0102156:	68 b3 6a 10 f0       	push   $0xf0106ab3
f010215b:	68 c7 68 10 f0       	push   $0xf01068c7
f0102160:	68 5a 04 00 00       	push   $0x45a
f0102165:	68 a1 68 10 f0       	push   $0xf01068a1
f010216a:	e8 d1 de ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f010216f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102172:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102178:	83 ec 0c             	sub    $0xc,%esp
f010217b:	50                   	push   %eax
f010217c:	e8 c7 ed ff ff       	call   f0100f48 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102181:	83 c4 0c             	add    $0xc,%esp
f0102184:	6a 01                	push   $0x1
f0102186:	68 00 10 40 00       	push   $0x401000
f010218b:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102191:	e8 e8 ed ff ff       	call   f0100f7e <pgdir_walk>
f0102196:	89 c7                	mov    %eax,%edi
f0102198:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010219b:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01021a0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021a3:	8b 40 04             	mov    0x4(%eax),%eax
f01021a6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01021ab:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f01021b1:	89 c2                	mov    %eax,%edx
f01021b3:	c1 ea 0c             	shr    $0xc,%edx
f01021b6:	83 c4 10             	add    $0x10,%esp
f01021b9:	39 ca                	cmp    %ecx,%edx
f01021bb:	72 15                	jb     f01021d2 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021bd:	50                   	push   %eax
f01021be:	68 04 5a 10 f0       	push   $0xf0105a04
f01021c3:	68 61 04 00 00       	push   $0x461
f01021c8:	68 a1 68 10 f0       	push   $0xf01068a1
f01021cd:	e8 6e de ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01021d2:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f01021d7:	39 c7                	cmp    %eax,%edi
f01021d9:	74 19                	je     f01021f4 <mem_init+0xfb8>
f01021db:	68 3f 6b 10 f0       	push   $0xf0106b3f
f01021e0:	68 c7 68 10 f0       	push   $0xf01068c7
f01021e5:	68 62 04 00 00       	push   $0x462
f01021ea:	68 a1 68 10 f0       	push   $0xf01068a1
f01021ef:	e8 4c de ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01021f4:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01021f7:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01021fe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102201:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102207:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f010220d:	c1 f8 03             	sar    $0x3,%eax
f0102210:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102213:	89 c2                	mov    %eax,%edx
f0102215:	c1 ea 0c             	shr    $0xc,%edx
f0102218:	39 d1                	cmp    %edx,%ecx
f010221a:	77 12                	ja     f010222e <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010221c:	50                   	push   %eax
f010221d:	68 04 5a 10 f0       	push   $0xf0105a04
f0102222:	6a 58                	push   $0x58
f0102224:	68 ad 68 10 f0       	push   $0xf01068ad
f0102229:	e8 12 de ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010222e:	83 ec 04             	sub    $0x4,%esp
f0102231:	68 00 10 00 00       	push   $0x1000
f0102236:	68 ff 00 00 00       	push   $0xff
f010223b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102240:	50                   	push   %eax
f0102241:	e8 d3 2a 00 00       	call   f0104d19 <memset>
	page_free(pp0);
f0102246:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102249:	89 3c 24             	mov    %edi,(%esp)
f010224c:	e8 f7 ec ff ff       	call   f0100f48 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102251:	83 c4 0c             	add    $0xc,%esp
f0102254:	6a 01                	push   $0x1
f0102256:	6a 00                	push   $0x0
f0102258:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f010225e:	e8 1b ed ff ff       	call   f0100f7e <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102263:	89 fa                	mov    %edi,%edx
f0102265:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f010226b:	c1 fa 03             	sar    $0x3,%edx
f010226e:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102271:	89 d0                	mov    %edx,%eax
f0102273:	c1 e8 0c             	shr    $0xc,%eax
f0102276:	83 c4 10             	add    $0x10,%esp
f0102279:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f010227f:	72 12                	jb     f0102293 <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102281:	52                   	push   %edx
f0102282:	68 04 5a 10 f0       	push   $0xf0105a04
f0102287:	6a 58                	push   $0x58
f0102289:	68 ad 68 10 f0       	push   $0xf01068ad
f010228e:	e8 ad dd ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102293:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102299:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010229c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01022a2:	f6 00 01             	testb  $0x1,(%eax)
f01022a5:	74 19                	je     f01022c0 <mem_init+0x1084>
f01022a7:	68 57 6b 10 f0       	push   $0xf0106b57
f01022ac:	68 c7 68 10 f0       	push   $0xf01068c7
f01022b1:	68 6c 04 00 00       	push   $0x46c
f01022b6:	68 a1 68 10 f0       	push   $0xf01068a1
f01022bb:	e8 80 dd ff ff       	call   f0100040 <_panic>
f01022c0:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01022c3:	39 d0                	cmp    %edx,%eax
f01022c5:	75 db                	jne    f01022a2 <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01022c7:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01022cc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01022d2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022d5:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01022db:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01022de:	89 0d 40 a2 22 f0    	mov    %ecx,0xf022a240

	// free the pages we took
	page_free(pp0);
f01022e4:	83 ec 0c             	sub    $0xc,%esp
f01022e7:	50                   	push   %eax
f01022e8:	e8 5b ec ff ff       	call   f0100f48 <page_free>
	page_free(pp1);
f01022ed:	89 1c 24             	mov    %ebx,(%esp)
f01022f0:	e8 53 ec ff ff       	call   f0100f48 <page_free>
	page_free(pp2);
f01022f5:	89 34 24             	mov    %esi,(%esp)
f01022f8:	e8 4b ec ff ff       	call   f0100f48 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f01022fd:	83 c4 08             	add    $0x8,%esp
f0102300:	68 01 10 00 00       	push   $0x1001
f0102305:	6a 00                	push   $0x0
f0102307:	e8 c6 ee ff ff       	call   f01011d2 <mmio_map_region>
f010230c:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f010230e:	83 c4 08             	add    $0x8,%esp
f0102311:	68 00 10 00 00       	push   $0x1000
f0102316:	6a 00                	push   $0x0
f0102318:	e8 b5 ee ff ff       	call   f01011d2 <mmio_map_region>
f010231d:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f010231f:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f0102325:	83 c4 10             	add    $0x10,%esp
f0102328:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f010232e:	76 07                	jbe    f0102337 <mem_init+0x10fb>
f0102330:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102335:	76 19                	jbe    f0102350 <mem_init+0x1114>
f0102337:	68 1c 65 10 f0       	push   $0xf010651c
f010233c:	68 c7 68 10 f0       	push   $0xf01068c7
f0102341:	68 7c 04 00 00       	push   $0x47c
f0102346:	68 a1 68 10 f0       	push   $0xf01068a1
f010234b:	e8 f0 dc ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102350:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f0102356:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f010235c:	77 08                	ja     f0102366 <mem_init+0x112a>
f010235e:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102364:	77 19                	ja     f010237f <mem_init+0x1143>
f0102366:	68 44 65 10 f0       	push   $0xf0106544
f010236b:	68 c7 68 10 f0       	push   $0xf01068c7
f0102370:	68 7d 04 00 00       	push   $0x47d
f0102375:	68 a1 68 10 f0       	push   $0xf01068a1
f010237a:	e8 c1 dc ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f010237f:	89 da                	mov    %ebx,%edx
f0102381:	09 f2                	or     %esi,%edx
f0102383:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102389:	74 19                	je     f01023a4 <mem_init+0x1168>
f010238b:	68 6c 65 10 f0       	push   $0xf010656c
f0102390:	68 c7 68 10 f0       	push   $0xf01068c7
f0102395:	68 7f 04 00 00       	push   $0x47f
f010239a:	68 a1 68 10 f0       	push   $0xf01068a1
f010239f:	e8 9c dc ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f01023a4:	39 c6                	cmp    %eax,%esi
f01023a6:	73 19                	jae    f01023c1 <mem_init+0x1185>
f01023a8:	68 6e 6b 10 f0       	push   $0xf0106b6e
f01023ad:	68 c7 68 10 f0       	push   $0xf01068c7
f01023b2:	68 81 04 00 00       	push   $0x481
f01023b7:	68 a1 68 10 f0       	push   $0xf01068a1
f01023bc:	e8 7f dc ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f01023c1:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f01023c7:	89 da                	mov    %ebx,%edx
f01023c9:	89 f8                	mov    %edi,%eax
f01023cb:	e8 b3 e6 ff ff       	call   f0100a83 <check_va2pa>
f01023d0:	85 c0                	test   %eax,%eax
f01023d2:	74 19                	je     f01023ed <mem_init+0x11b1>
f01023d4:	68 94 65 10 f0       	push   $0xf0106594
f01023d9:	68 c7 68 10 f0       	push   $0xf01068c7
f01023de:	68 83 04 00 00       	push   $0x483
f01023e3:	68 a1 68 10 f0       	push   $0xf01068a1
f01023e8:	e8 53 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f01023ed:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f01023f3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01023f6:	89 c2                	mov    %eax,%edx
f01023f8:	89 f8                	mov    %edi,%eax
f01023fa:	e8 84 e6 ff ff       	call   f0100a83 <check_va2pa>
f01023ff:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102404:	74 19                	je     f010241f <mem_init+0x11e3>
f0102406:	68 b8 65 10 f0       	push   $0xf01065b8
f010240b:	68 c7 68 10 f0       	push   $0xf01068c7
f0102410:	68 84 04 00 00       	push   $0x484
f0102415:	68 a1 68 10 f0       	push   $0xf01068a1
f010241a:	e8 21 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f010241f:	89 f2                	mov    %esi,%edx
f0102421:	89 f8                	mov    %edi,%eax
f0102423:	e8 5b e6 ff ff       	call   f0100a83 <check_va2pa>
f0102428:	85 c0                	test   %eax,%eax
f010242a:	74 19                	je     f0102445 <mem_init+0x1209>
f010242c:	68 e8 65 10 f0       	push   $0xf01065e8
f0102431:	68 c7 68 10 f0       	push   $0xf01068c7
f0102436:	68 85 04 00 00       	push   $0x485
f010243b:	68 a1 68 10 f0       	push   $0xf01068a1
f0102440:	e8 fb db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102445:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f010244b:	89 f8                	mov    %edi,%eax
f010244d:	e8 31 e6 ff ff       	call   f0100a83 <check_va2pa>
f0102452:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102455:	74 19                	je     f0102470 <mem_init+0x1234>
f0102457:	68 0c 66 10 f0       	push   $0xf010660c
f010245c:	68 c7 68 10 f0       	push   $0xf01068c7
f0102461:	68 86 04 00 00       	push   $0x486
f0102466:	68 a1 68 10 f0       	push   $0xf01068a1
f010246b:	e8 d0 db ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102470:	83 ec 04             	sub    $0x4,%esp
f0102473:	6a 00                	push   $0x0
f0102475:	53                   	push   %ebx
f0102476:	57                   	push   %edi
f0102477:	e8 02 eb ff ff       	call   f0100f7e <pgdir_walk>
f010247c:	83 c4 10             	add    $0x10,%esp
f010247f:	f6 00 1a             	testb  $0x1a,(%eax)
f0102482:	75 19                	jne    f010249d <mem_init+0x1261>
f0102484:	68 38 66 10 f0       	push   $0xf0106638
f0102489:	68 c7 68 10 f0       	push   $0xf01068c7
f010248e:	68 88 04 00 00       	push   $0x488
f0102493:	68 a1 68 10 f0       	push   $0xf01068a1
f0102498:	e8 a3 db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f010249d:	83 ec 04             	sub    $0x4,%esp
f01024a0:	6a 00                	push   $0x0
f01024a2:	53                   	push   %ebx
f01024a3:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01024a9:	e8 d0 ea ff ff       	call   f0100f7e <pgdir_walk>
f01024ae:	8b 00                	mov    (%eax),%eax
f01024b0:	83 c4 10             	add    $0x10,%esp
f01024b3:	83 e0 04             	and    $0x4,%eax
f01024b6:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01024b9:	74 19                	je     f01024d4 <mem_init+0x1298>
f01024bb:	68 7c 66 10 f0       	push   $0xf010667c
f01024c0:	68 c7 68 10 f0       	push   $0xf01068c7
f01024c5:	68 89 04 00 00       	push   $0x489
f01024ca:	68 a1 68 10 f0       	push   $0xf01068a1
f01024cf:	e8 6c db ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f01024d4:	83 ec 04             	sub    $0x4,%esp
f01024d7:	6a 00                	push   $0x0
f01024d9:	53                   	push   %ebx
f01024da:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01024e0:	e8 99 ea ff ff       	call   f0100f7e <pgdir_walk>
f01024e5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f01024eb:	83 c4 0c             	add    $0xc,%esp
f01024ee:	6a 00                	push   $0x0
f01024f0:	ff 75 d4             	pushl  -0x2c(%ebp)
f01024f3:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01024f9:	e8 80 ea ff ff       	call   f0100f7e <pgdir_walk>
f01024fe:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102504:	83 c4 0c             	add    $0xc,%esp
f0102507:	6a 00                	push   $0x0
f0102509:	56                   	push   %esi
f010250a:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102510:	e8 69 ea ff ff       	call   f0100f7e <pgdir_walk>
f0102515:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f010251b:	c7 04 24 80 6b 10 f0 	movl   $0xf0106b80,(%esp)
f0102522:	e8 6d 11 00 00       	call   f0103694 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U | PTE_P);
f0102527:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010252c:	83 c4 10             	add    $0x10,%esp
f010252f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102534:	77 15                	ja     f010254b <mem_init+0x130f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102536:	50                   	push   %eax
f0102537:	68 28 5a 10 f0       	push   $0xf0105a28
f010253c:	68 b7 00 00 00       	push   $0xb7
f0102541:	68 a1 68 10 f0       	push   $0xf01068a1
f0102546:	e8 f5 da ff ff       	call   f0100040 <_panic>
f010254b:	83 ec 08             	sub    $0x8,%esp
f010254e:	6a 05                	push   $0x5
f0102550:	05 00 00 00 10       	add    $0x10000000,%eax
f0102555:	50                   	push   %eax
f0102556:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010255b:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102560:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102565:	e8 d8 ea ff ff       	call   f0101042 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U | PTE_P);
f010256a:	a1 48 a2 22 f0       	mov    0xf022a248,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010256f:	83 c4 10             	add    $0x10,%esp
f0102572:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102577:	77 15                	ja     f010258e <mem_init+0x1352>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102579:	50                   	push   %eax
f010257a:	68 28 5a 10 f0       	push   $0xf0105a28
f010257f:	68 bf 00 00 00       	push   $0xbf
f0102584:	68 a1 68 10 f0       	push   $0xf01068a1
f0102589:	e8 b2 da ff ff       	call   f0100040 <_panic>
f010258e:	83 ec 08             	sub    $0x8,%esp
f0102591:	6a 05                	push   $0x5
f0102593:	05 00 00 00 10       	add    $0x10000000,%eax
f0102598:	50                   	push   %eax
f0102599:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010259e:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01025a3:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01025a8:	e8 95 ea ff ff       	call   f0101042 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025ad:	83 c4 10             	add    $0x10,%esp
f01025b0:	b8 00 50 11 f0       	mov    $0xf0115000,%eax
f01025b5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025ba:	77 15                	ja     f01025d1 <mem_init+0x1395>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025bc:	50                   	push   %eax
f01025bd:	68 28 5a 10 f0       	push   $0xf0105a28
f01025c2:	68 cb 00 00 00       	push   $0xcb
f01025c7:	68 a1 68 10 f0       	push   $0xf01068a1
f01025cc:	e8 6f da ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01025d1:	83 ec 08             	sub    $0x8,%esp
f01025d4:	6a 02                	push   $0x2
f01025d6:	68 00 50 11 00       	push   $0x115000
f01025db:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01025e0:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01025e5:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01025ea:	e8 53 ea ff ff       	call   f0101042 <boot_map_region>
f01025ef:	c7 45 c4 00 c0 22 f0 	movl   $0xf022c000,-0x3c(%ebp)
f01025f6:	83 c4 10             	add    $0x10,%esp
f01025f9:	bb 00 c0 22 f0       	mov    $0xf022c000,%ebx
f01025fe:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102603:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102609:	77 15                	ja     f0102620 <mem_init+0x13e4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010260b:	53                   	push   %ebx
f010260c:	68 28 5a 10 f0       	push   $0xf0105a28
f0102611:	68 0b 01 00 00       	push   $0x10b
f0102616:	68 a1 68 10 f0       	push   $0xf01068a1
f010261b:	e8 20 da ff ff       	call   f0100040 <_panic>
	// LAB 4: Your code here:
	uintptr_t kstacktop_i;
	for(int i = 0;i < NCPU;i++)
	{
		kstacktop_i = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
		boot_map_region(kern_pgdir, kstacktop_i - KSTKSIZE, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W);
f0102620:	83 ec 08             	sub    $0x8,%esp
f0102623:	6a 02                	push   $0x2
f0102625:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f010262b:	50                   	push   %eax
f010262c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102631:	89 f2                	mov    %esi,%edx
f0102633:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102638:	e8 05 ea ff ff       	call   f0101042 <boot_map_region>
f010263d:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102643:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//             Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	uintptr_t kstacktop_i;
	for(int i = 0;i < NCPU;i++)
f0102649:	83 c4 10             	add    $0x10,%esp
f010264c:	b8 00 c0 26 f0       	mov    $0xf026c000,%eax
f0102651:	39 d8                	cmp    %ebx,%eax
f0102653:	75 ae                	jne    f0102603 <mem_init+0x13c7>
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	// Initialize the SMP-related parts of the memory map
	mem_init_mp();
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff-KERNBASE, 0, PTE_W);
f0102655:	83 ec 08             	sub    $0x8,%esp
f0102658:	6a 02                	push   $0x2
f010265a:	6a 00                	push   $0x0
f010265c:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102661:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102666:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f010266b:	e8 d2 e9 ff ff       	call   f0101042 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102670:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102676:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f010267b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010267e:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102685:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010268a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010268d:	8b 35 90 ae 22 f0    	mov    0xf022ae90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102693:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0102696:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102699:	bb 00 00 00 00       	mov    $0x0,%ebx
f010269e:	eb 55                	jmp    f01026f5 <mem_init+0x14b9>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026a0:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01026a6:	89 f8                	mov    %edi,%eax
f01026a8:	e8 d6 e3 ff ff       	call   f0100a83 <check_va2pa>
f01026ad:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01026b4:	77 15                	ja     f01026cb <mem_init+0x148f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026b6:	56                   	push   %esi
f01026b7:	68 28 5a 10 f0       	push   $0xf0105a28
f01026bc:	68 a1 03 00 00       	push   $0x3a1
f01026c1:	68 a1 68 10 f0       	push   $0xf01068a1
f01026c6:	e8 75 d9 ff ff       	call   f0100040 <_panic>
f01026cb:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f01026d2:	39 c2                	cmp    %eax,%edx
f01026d4:	74 19                	je     f01026ef <mem_init+0x14b3>
f01026d6:	68 b0 66 10 f0       	push   $0xf01066b0
f01026db:	68 c7 68 10 f0       	push   $0xf01068c7
f01026e0:	68 a1 03 00 00       	push   $0x3a1
f01026e5:	68 a1 68 10 f0       	push   $0xf01068a1
f01026ea:	e8 51 d9 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026ef:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01026f5:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01026f8:	77 a6                	ja     f01026a0 <mem_init+0x1464>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01026fa:	8b 35 48 a2 22 f0    	mov    0xf022a248,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102700:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102703:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102708:	89 da                	mov    %ebx,%edx
f010270a:	89 f8                	mov    %edi,%eax
f010270c:	e8 72 e3 ff ff       	call   f0100a83 <check_va2pa>
f0102711:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102718:	77 15                	ja     f010272f <mem_init+0x14f3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010271a:	56                   	push   %esi
f010271b:	68 28 5a 10 f0       	push   $0xf0105a28
f0102720:	68 a6 03 00 00       	push   $0x3a6
f0102725:	68 a1 68 10 f0       	push   $0xf01068a1
f010272a:	e8 11 d9 ff ff       	call   f0100040 <_panic>
f010272f:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f0102736:	39 d0                	cmp    %edx,%eax
f0102738:	74 19                	je     f0102753 <mem_init+0x1517>
f010273a:	68 e4 66 10 f0       	push   $0xf01066e4
f010273f:	68 c7 68 10 f0       	push   $0xf01068c7
f0102744:	68 a6 03 00 00       	push   $0x3a6
f0102749:	68 a1 68 10 f0       	push   $0xf01068a1
f010274e:	e8 ed d8 ff ff       	call   f0100040 <_panic>
f0102753:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102759:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f010275f:	75 a7                	jne    f0102708 <mem_init+0x14cc>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102761:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0102764:	c1 e6 0c             	shl    $0xc,%esi
f0102767:	bb 00 00 00 00       	mov    $0x0,%ebx
f010276c:	eb 30                	jmp    f010279e <mem_init+0x1562>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010276e:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102774:	89 f8                	mov    %edi,%eax
f0102776:	e8 08 e3 ff ff       	call   f0100a83 <check_va2pa>
f010277b:	39 c3                	cmp    %eax,%ebx
f010277d:	74 19                	je     f0102798 <mem_init+0x155c>
f010277f:	68 18 67 10 f0       	push   $0xf0106718
f0102784:	68 c7 68 10 f0       	push   $0xf01068c7
f0102789:	68 aa 03 00 00       	push   $0x3aa
f010278e:	68 a1 68 10 f0       	push   $0xf01068a1
f0102793:	e8 a8 d8 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102798:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010279e:	39 f3                	cmp    %esi,%ebx
f01027a0:	72 cc                	jb     f010276e <mem_init+0x1532>
f01027a2:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f01027a7:	89 75 cc             	mov    %esi,-0x34(%ebp)
f01027aa:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01027ad:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01027b0:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f01027b6:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01027b9:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f01027bb:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01027be:	05 00 80 00 20       	add    $0x20008000,%eax
f01027c3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01027c6:	89 da                	mov    %ebx,%edx
f01027c8:	89 f8                	mov    %edi,%eax
f01027ca:	e8 b4 e2 ff ff       	call   f0100a83 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027cf:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01027d5:	77 15                	ja     f01027ec <mem_init+0x15b0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027d7:	56                   	push   %esi
f01027d8:	68 28 5a 10 f0       	push   $0xf0105a28
f01027dd:	68 b2 03 00 00       	push   $0x3b2
f01027e2:	68 a1 68 10 f0       	push   $0xf01068a1
f01027e7:	e8 54 d8 ff ff       	call   f0100040 <_panic>
f01027ec:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01027ef:	8d 94 0b 00 c0 22 f0 	lea    -0xfdd4000(%ebx,%ecx,1),%edx
f01027f6:	39 d0                	cmp    %edx,%eax
f01027f8:	74 19                	je     f0102813 <mem_init+0x15d7>
f01027fa:	68 40 67 10 f0       	push   $0xf0106740
f01027ff:	68 c7 68 10 f0       	push   $0xf01068c7
f0102804:	68 b2 03 00 00       	push   $0x3b2
f0102809:	68 a1 68 10 f0       	push   $0xf01068a1
f010280e:	e8 2d d8 ff ff       	call   f0100040 <_panic>
f0102813:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102819:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f010281c:	75 a8                	jne    f01027c6 <mem_init+0x158a>
f010281e:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102821:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f0102827:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010282a:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f010282c:	89 da                	mov    %ebx,%edx
f010282e:	89 f8                	mov    %edi,%eax
f0102830:	e8 4e e2 ff ff       	call   f0100a83 <check_va2pa>
f0102835:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102838:	74 19                	je     f0102853 <mem_init+0x1617>
f010283a:	68 88 67 10 f0       	push   $0xf0106788
f010283f:	68 c7 68 10 f0       	push   $0xf01068c7
f0102844:	68 b4 03 00 00       	push   $0x3b4
f0102849:	68 a1 68 10 f0       	push   $0xf01068a1
f010284e:	e8 ed d7 ff ff       	call   f0100040 <_panic>
f0102853:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102859:	39 de                	cmp    %ebx,%esi
f010285b:	75 cf                	jne    f010282c <mem_init+0x15f0>
f010285d:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102860:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f0102867:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f010286e:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102874:	81 fe 00 c0 26 f0    	cmp    $0xf026c000,%esi
f010287a:	0f 85 2d ff ff ff    	jne    f01027ad <mem_init+0x1571>
f0102880:	b8 00 00 00 00       	mov    $0x0,%eax
f0102885:	eb 2a                	jmp    f01028b1 <mem_init+0x1675>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102887:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f010288d:	83 fa 04             	cmp    $0x4,%edx
f0102890:	77 1f                	ja     f01028b1 <mem_init+0x1675>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102892:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102896:	75 7e                	jne    f0102916 <mem_init+0x16da>
f0102898:	68 99 6b 10 f0       	push   $0xf0106b99
f010289d:	68 c7 68 10 f0       	push   $0xf01068c7
f01028a2:	68 bf 03 00 00       	push   $0x3bf
f01028a7:	68 a1 68 10 f0       	push   $0xf01068a1
f01028ac:	e8 8f d7 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01028b1:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01028b6:	76 3f                	jbe    f01028f7 <mem_init+0x16bb>
				assert(pgdir[i] & PTE_P);
f01028b8:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01028bb:	f6 c2 01             	test   $0x1,%dl
f01028be:	75 19                	jne    f01028d9 <mem_init+0x169d>
f01028c0:	68 99 6b 10 f0       	push   $0xf0106b99
f01028c5:	68 c7 68 10 f0       	push   $0xf01068c7
f01028ca:	68 c3 03 00 00       	push   $0x3c3
f01028cf:	68 a1 68 10 f0       	push   $0xf01068a1
f01028d4:	e8 67 d7 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f01028d9:	f6 c2 02             	test   $0x2,%dl
f01028dc:	75 38                	jne    f0102916 <mem_init+0x16da>
f01028de:	68 aa 6b 10 f0       	push   $0xf0106baa
f01028e3:	68 c7 68 10 f0       	push   $0xf01068c7
f01028e8:	68 c4 03 00 00       	push   $0x3c4
f01028ed:	68 a1 68 10 f0       	push   $0xf01068a1
f01028f2:	e8 49 d7 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f01028f7:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01028fb:	74 19                	je     f0102916 <mem_init+0x16da>
f01028fd:	68 bb 6b 10 f0       	push   $0xf0106bbb
f0102902:	68 c7 68 10 f0       	push   $0xf01068c7
f0102907:	68 c6 03 00 00       	push   $0x3c6
f010290c:	68 a1 68 10 f0       	push   $0xf01068a1
f0102911:	e8 2a d7 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102916:	83 c0 01             	add    $0x1,%eax
f0102919:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010291e:	0f 86 63 ff ff ff    	jbe    f0102887 <mem_init+0x164b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102924:	83 ec 0c             	sub    $0xc,%esp
f0102927:	68 ac 67 10 f0       	push   $0xf01067ac
f010292c:	e8 63 0d 00 00       	call   f0103694 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102931:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102936:	83 c4 10             	add    $0x10,%esp
f0102939:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010293e:	77 15                	ja     f0102955 <mem_init+0x1719>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102940:	50                   	push   %eax
f0102941:	68 28 5a 10 f0       	push   $0xf0105a28
f0102946:	68 e2 00 00 00       	push   $0xe2
f010294b:	68 a1 68 10 f0       	push   $0xf01068a1
f0102950:	e8 eb d6 ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102955:	05 00 00 00 10       	add    $0x10000000,%eax
f010295a:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010295d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102962:	e8 80 e1 ff ff       	call   f0100ae7 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102967:	0f 20 c0             	mov    %cr0,%eax
f010296a:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f010296d:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102972:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102975:	83 ec 0c             	sub    $0xc,%esp
f0102978:	6a 00                	push   $0x0
f010297a:	e8 53 e5 ff ff       	call   f0100ed2 <page_alloc>
f010297f:	89 c3                	mov    %eax,%ebx
f0102981:	83 c4 10             	add    $0x10,%esp
f0102984:	85 c0                	test   %eax,%eax
f0102986:	75 19                	jne    f01029a1 <mem_init+0x1765>
f0102988:	68 a5 69 10 f0       	push   $0xf01069a5
f010298d:	68 c7 68 10 f0       	push   $0xf01068c7
f0102992:	68 9e 04 00 00       	push   $0x49e
f0102997:	68 a1 68 10 f0       	push   $0xf01068a1
f010299c:	e8 9f d6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01029a1:	83 ec 0c             	sub    $0xc,%esp
f01029a4:	6a 00                	push   $0x0
f01029a6:	e8 27 e5 ff ff       	call   f0100ed2 <page_alloc>
f01029ab:	89 c7                	mov    %eax,%edi
f01029ad:	83 c4 10             	add    $0x10,%esp
f01029b0:	85 c0                	test   %eax,%eax
f01029b2:	75 19                	jne    f01029cd <mem_init+0x1791>
f01029b4:	68 bb 69 10 f0       	push   $0xf01069bb
f01029b9:	68 c7 68 10 f0       	push   $0xf01068c7
f01029be:	68 9f 04 00 00       	push   $0x49f
f01029c3:	68 a1 68 10 f0       	push   $0xf01068a1
f01029c8:	e8 73 d6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01029cd:	83 ec 0c             	sub    $0xc,%esp
f01029d0:	6a 00                	push   $0x0
f01029d2:	e8 fb e4 ff ff       	call   f0100ed2 <page_alloc>
f01029d7:	89 c6                	mov    %eax,%esi
f01029d9:	83 c4 10             	add    $0x10,%esp
f01029dc:	85 c0                	test   %eax,%eax
f01029de:	75 19                	jne    f01029f9 <mem_init+0x17bd>
f01029e0:	68 d1 69 10 f0       	push   $0xf01069d1
f01029e5:	68 c7 68 10 f0       	push   $0xf01068c7
f01029ea:	68 a0 04 00 00       	push   $0x4a0
f01029ef:	68 a1 68 10 f0       	push   $0xf01068a1
f01029f4:	e8 47 d6 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f01029f9:	83 ec 0c             	sub    $0xc,%esp
f01029fc:	53                   	push   %ebx
f01029fd:	e8 46 e5 ff ff       	call   f0100f48 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a02:	89 f8                	mov    %edi,%eax
f0102a04:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102a0a:	c1 f8 03             	sar    $0x3,%eax
f0102a0d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a10:	89 c2                	mov    %eax,%edx
f0102a12:	c1 ea 0c             	shr    $0xc,%edx
f0102a15:	83 c4 10             	add    $0x10,%esp
f0102a18:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102a1e:	72 12                	jb     f0102a32 <mem_init+0x17f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a20:	50                   	push   %eax
f0102a21:	68 04 5a 10 f0       	push   $0xf0105a04
f0102a26:	6a 58                	push   $0x58
f0102a28:	68 ad 68 10 f0       	push   $0xf01068ad
f0102a2d:	e8 0e d6 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102a32:	83 ec 04             	sub    $0x4,%esp
f0102a35:	68 00 10 00 00       	push   $0x1000
f0102a3a:	6a 01                	push   $0x1
f0102a3c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a41:	50                   	push   %eax
f0102a42:	e8 d2 22 00 00       	call   f0104d19 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a47:	89 f0                	mov    %esi,%eax
f0102a49:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102a4f:	c1 f8 03             	sar    $0x3,%eax
f0102a52:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a55:	89 c2                	mov    %eax,%edx
f0102a57:	c1 ea 0c             	shr    $0xc,%edx
f0102a5a:	83 c4 10             	add    $0x10,%esp
f0102a5d:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102a63:	72 12                	jb     f0102a77 <mem_init+0x183b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a65:	50                   	push   %eax
f0102a66:	68 04 5a 10 f0       	push   $0xf0105a04
f0102a6b:	6a 58                	push   $0x58
f0102a6d:	68 ad 68 10 f0       	push   $0xf01068ad
f0102a72:	e8 c9 d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102a77:	83 ec 04             	sub    $0x4,%esp
f0102a7a:	68 00 10 00 00       	push   $0x1000
f0102a7f:	6a 02                	push   $0x2
f0102a81:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a86:	50                   	push   %eax
f0102a87:	e8 8d 22 00 00       	call   f0104d19 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102a8c:	6a 02                	push   $0x2
f0102a8e:	68 00 10 00 00       	push   $0x1000
f0102a93:	57                   	push   %edi
f0102a94:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102a9a:	e8 cd e6 ff ff       	call   f010116c <page_insert>
	assert(pp1->pp_ref == 1);
f0102a9f:	83 c4 20             	add    $0x20,%esp
f0102aa2:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102aa7:	74 19                	je     f0102ac2 <mem_init+0x1886>
f0102aa9:	68 a2 6a 10 f0       	push   $0xf0106aa2
f0102aae:	68 c7 68 10 f0       	push   $0xf01068c7
f0102ab3:	68 a5 04 00 00       	push   $0x4a5
f0102ab8:	68 a1 68 10 f0       	push   $0xf01068a1
f0102abd:	e8 7e d5 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ac2:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102ac9:	01 01 01 
f0102acc:	74 19                	je     f0102ae7 <mem_init+0x18ab>
f0102ace:	68 cc 67 10 f0       	push   $0xf01067cc
f0102ad3:	68 c7 68 10 f0       	push   $0xf01068c7
f0102ad8:	68 a6 04 00 00       	push   $0x4a6
f0102add:	68 a1 68 10 f0       	push   $0xf01068a1
f0102ae2:	e8 59 d5 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102ae7:	6a 02                	push   $0x2
f0102ae9:	68 00 10 00 00       	push   $0x1000
f0102aee:	56                   	push   %esi
f0102aef:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102af5:	e8 72 e6 ff ff       	call   f010116c <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102afa:	83 c4 10             	add    $0x10,%esp
f0102afd:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b04:	02 02 02 
f0102b07:	74 19                	je     f0102b22 <mem_init+0x18e6>
f0102b09:	68 f0 67 10 f0       	push   $0xf01067f0
f0102b0e:	68 c7 68 10 f0       	push   $0xf01068c7
f0102b13:	68 a8 04 00 00       	push   $0x4a8
f0102b18:	68 a1 68 10 f0       	push   $0xf01068a1
f0102b1d:	e8 1e d5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102b22:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b27:	74 19                	je     f0102b42 <mem_init+0x1906>
f0102b29:	68 c4 6a 10 f0       	push   $0xf0106ac4
f0102b2e:	68 c7 68 10 f0       	push   $0xf01068c7
f0102b33:	68 a9 04 00 00       	push   $0x4a9
f0102b38:	68 a1 68 10 f0       	push   $0xf01068a1
f0102b3d:	e8 fe d4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102b42:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102b47:	74 19                	je     f0102b62 <mem_init+0x1926>
f0102b49:	68 2e 6b 10 f0       	push   $0xf0106b2e
f0102b4e:	68 c7 68 10 f0       	push   $0xf01068c7
f0102b53:	68 aa 04 00 00       	push   $0x4aa
f0102b58:	68 a1 68 10 f0       	push   $0xf01068a1
f0102b5d:	e8 de d4 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b62:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b69:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b6c:	89 f0                	mov    %esi,%eax
f0102b6e:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102b74:	c1 f8 03             	sar    $0x3,%eax
f0102b77:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b7a:	89 c2                	mov    %eax,%edx
f0102b7c:	c1 ea 0c             	shr    $0xc,%edx
f0102b7f:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102b85:	72 12                	jb     f0102b99 <mem_init+0x195d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b87:	50                   	push   %eax
f0102b88:	68 04 5a 10 f0       	push   $0xf0105a04
f0102b8d:	6a 58                	push   $0x58
f0102b8f:	68 ad 68 10 f0       	push   $0xf01068ad
f0102b94:	e8 a7 d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102b99:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102ba0:	03 03 03 
f0102ba3:	74 19                	je     f0102bbe <mem_init+0x1982>
f0102ba5:	68 14 68 10 f0       	push   $0xf0106814
f0102baa:	68 c7 68 10 f0       	push   $0xf01068c7
f0102baf:	68 ac 04 00 00       	push   $0x4ac
f0102bb4:	68 a1 68 10 f0       	push   $0xf01068a1
f0102bb9:	e8 82 d4 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102bbe:	83 ec 08             	sub    $0x8,%esp
f0102bc1:	68 00 10 00 00       	push   $0x1000
f0102bc6:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102bcc:	e8 52 e5 ff ff       	call   f0101123 <page_remove>
	assert(pp2->pp_ref == 0);
f0102bd1:	83 c4 10             	add    $0x10,%esp
f0102bd4:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102bd9:	74 19                	je     f0102bf4 <mem_init+0x19b8>
f0102bdb:	68 fc 6a 10 f0       	push   $0xf0106afc
f0102be0:	68 c7 68 10 f0       	push   $0xf01068c7
f0102be5:	68 ae 04 00 00       	push   $0x4ae
f0102bea:	68 a1 68 10 f0       	push   $0xf01068a1
f0102bef:	e8 4c d4 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102bf4:	8b 0d 8c ae 22 f0    	mov    0xf022ae8c,%ecx
f0102bfa:	8b 11                	mov    (%ecx),%edx
f0102bfc:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102c02:	89 d8                	mov    %ebx,%eax
f0102c04:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102c0a:	c1 f8 03             	sar    $0x3,%eax
f0102c0d:	c1 e0 0c             	shl    $0xc,%eax
f0102c10:	39 c2                	cmp    %eax,%edx
f0102c12:	74 19                	je     f0102c2d <mem_init+0x19f1>
f0102c14:	68 9c 61 10 f0       	push   $0xf010619c
f0102c19:	68 c7 68 10 f0       	push   $0xf01068c7
f0102c1e:	68 b1 04 00 00       	push   $0x4b1
f0102c23:	68 a1 68 10 f0       	push   $0xf01068a1
f0102c28:	e8 13 d4 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102c2d:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102c33:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102c38:	74 19                	je     f0102c53 <mem_init+0x1a17>
f0102c3a:	68 b3 6a 10 f0       	push   $0xf0106ab3
f0102c3f:	68 c7 68 10 f0       	push   $0xf01068c7
f0102c44:	68 b3 04 00 00       	push   $0x4b3
f0102c49:	68 a1 68 10 f0       	push   $0xf01068a1
f0102c4e:	e8 ed d3 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102c53:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102c59:	83 ec 0c             	sub    $0xc,%esp
f0102c5c:	53                   	push   %ebx
f0102c5d:	e8 e6 e2 ff ff       	call   f0100f48 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102c62:	c7 04 24 40 68 10 f0 	movl   $0xf0106840,(%esp)
f0102c69:	e8 26 0a 00 00       	call   f0103694 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102c6e:	83 c4 10             	add    $0x10,%esp
f0102c71:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c74:	5b                   	pop    %ebx
f0102c75:	5e                   	pop    %esi
f0102c76:	5f                   	pop    %edi
f0102c77:	5d                   	pop    %ebp
f0102c78:	c3                   	ret    

f0102c79 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102c79:	55                   	push   %ebp
f0102c7a:	89 e5                	mov    %esp,%ebp
f0102c7c:	57                   	push   %edi
f0102c7d:	56                   	push   %esi
f0102c7e:	53                   	push   %ebx
f0102c7f:	83 ec 1c             	sub    $0x1c,%esp
f0102c82:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102c85:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	uint32_t start = (uint32_t)ROUNDDOWN(va, PGSIZE);
f0102c88:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102c8b:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t end = (uint32_t)ROUNDUP(va+len, PGSIZE);
f0102c91:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c94:	03 45 10             	add    0x10(%ebp),%eax
f0102c97:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102c9c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102ca1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(uint32_t i = start;i < end;i += PGSIZE)
f0102ca4:	eb 50                	jmp    f0102cf6 <user_mem_check+0x7d>
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, (void *)i, 0);
f0102ca6:	83 ec 04             	sub    $0x4,%esp
f0102ca9:	6a 00                	push   $0x0
f0102cab:	53                   	push   %ebx
f0102cac:	ff 77 60             	pushl  0x60(%edi)
f0102caf:	e8 ca e2 ff ff       	call   f0100f7e <pgdir_walk>
// A user program can access a virtual address if (1) the address is below
// ULIM, and (2) the page table gives it permission. 
		//不满足的条件:1.地址大于ULIM 2.pte不存在 3.pte没有PTE_P的权限位 
		//4.pte的权限比perm高，说明当前权限无法访问对应内存
		if(i >= ULIM || !pte || !(*pte & PTE_P) || (*pte & perm) != perm)
f0102cb4:	83 c4 10             	add    $0x10,%esp
f0102cb7:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102cbd:	77 10                	ja     f0102ccf <user_mem_check+0x56>
f0102cbf:	85 c0                	test   %eax,%eax
f0102cc1:	74 0c                	je     f0102ccf <user_mem_check+0x56>
f0102cc3:	8b 00                	mov    (%eax),%eax
f0102cc5:	a8 01                	test   $0x1,%al
f0102cc7:	74 06                	je     f0102ccf <user_mem_check+0x56>
f0102cc9:	21 f0                	and    %esi,%eax
f0102ccb:	39 c6                	cmp    %eax,%esi
f0102ccd:	74 21                	je     f0102cf0 <user_mem_check+0x77>
		{
// If there is an error, set the 'user_mem_check_addr' variable to the first
// erroneous virtual address.
			//如果出错的是va之前的地址，需要返回的也应该是va的地址
			if(i < (uint32_t)va)
f0102ccf:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0102cd2:	73 0f                	jae    f0102ce3 <user_mem_check+0x6a>
				user_mem_check_addr = (uint32_t)va;
f0102cd4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102cd7:	a3 3c a2 22 f0       	mov    %eax,0xf022a23c
			else 
				user_mem_check_addr = i;
			return -E_FAULT;
f0102cdc:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102ce1:	eb 1d                	jmp    f0102d00 <user_mem_check+0x87>
// erroneous virtual address.
			//如果出错的是va之前的地址，需要返回的也应该是va的地址
			if(i < (uint32_t)va)
				user_mem_check_addr = (uint32_t)va;
			else 
				user_mem_check_addr = i;
f0102ce3:	89 1d 3c a2 22 f0    	mov    %ebx,0xf022a23c
			return -E_FAULT;
f0102ce9:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102cee:	eb 10                	jmp    f0102d00 <user_mem_check+0x87>
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	uint32_t start = (uint32_t)ROUNDDOWN(va, PGSIZE);
	uint32_t end = (uint32_t)ROUNDUP(va+len, PGSIZE);
	for(uint32_t i = start;i < end;i += PGSIZE)
f0102cf0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102cf6:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102cf9:	72 ab                	jb     f0102ca6 <user_mem_check+0x2d>
			else 
				user_mem_check_addr = i;
			return -E_FAULT;
		} 
	}
	return 0;
f0102cfb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102d00:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d03:	5b                   	pop    %ebx
f0102d04:	5e                   	pop    %esi
f0102d05:	5f                   	pop    %edi
f0102d06:	5d                   	pop    %ebp
f0102d07:	c3                   	ret    

f0102d08 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102d08:	55                   	push   %ebp
f0102d09:	89 e5                	mov    %esp,%ebp
f0102d0b:	53                   	push   %ebx
f0102d0c:	83 ec 04             	sub    $0x4,%esp
f0102d0f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102d12:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d15:	83 c8 04             	or     $0x4,%eax
f0102d18:	50                   	push   %eax
f0102d19:	ff 75 10             	pushl  0x10(%ebp)
f0102d1c:	ff 75 0c             	pushl  0xc(%ebp)
f0102d1f:	53                   	push   %ebx
f0102d20:	e8 54 ff ff ff       	call   f0102c79 <user_mem_check>
f0102d25:	83 c4 10             	add    $0x10,%esp
f0102d28:	85 c0                	test   %eax,%eax
f0102d2a:	79 21                	jns    f0102d4d <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102d2c:	83 ec 04             	sub    $0x4,%esp
f0102d2f:	ff 35 3c a2 22 f0    	pushl  0xf022a23c
f0102d35:	ff 73 48             	pushl  0x48(%ebx)
f0102d38:	68 6c 68 10 f0       	push   $0xf010686c
f0102d3d:	e8 52 09 00 00       	call   f0103694 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102d42:	89 1c 24             	mov    %ebx,(%esp)
f0102d45:	e8 46 06 00 00       	call   f0103390 <env_destroy>
f0102d4a:	83 c4 10             	add    $0x10,%esp
	}
}
f0102d4d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102d50:	c9                   	leave  
f0102d51:	c3                   	ret    

f0102d52 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102d52:	55                   	push   %ebp
f0102d53:	89 e5                	mov    %esp,%ebp
f0102d55:	57                   	push   %edi
f0102d56:	56                   	push   %esi
f0102d57:	53                   	push   %ebx
f0102d58:	83 ec 0c             	sub    $0xc,%esp
f0102d5b:	89 c7                	mov    %eax,%edi
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	//boot_map_region(e->env_pgdir, va, len, PADDR(envs), PTE_P | PTE_U | PTE_W);
	uint32_t start,end;
	start = ROUNDDOWN((uint32_t)va, PGSIZE);
	end = ROUNDUP((uint32_t)(va + len), PGSIZE);
f0102d5d:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102d64:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	//cprintf("start=%x \n",start);
	//cprintf("end=%x \n",end);

	struct PageInfo *Page;
	int r;
	for(int i = start;i < end;i += PGSIZE)
f0102d6a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102d70:	89 d3                	mov    %edx,%ebx
f0102d72:	eb 56                	jmp    f0102dca <region_alloc+0x78>
	{
		Page = page_alloc(0);
f0102d74:	83 ec 0c             	sub    $0xc,%esp
f0102d77:	6a 00                	push   $0x0
f0102d79:	e8 54 e1 ff ff       	call   f0100ed2 <page_alloc>
		if(!Page)
f0102d7e:	83 c4 10             	add    $0x10,%esp
f0102d81:	85 c0                	test   %eax,%eax
f0102d83:	75 17                	jne    f0102d9c <region_alloc+0x4a>
			panic("page_alloc fail");
f0102d85:	83 ec 04             	sub    $0x4,%esp
f0102d88:	68 c9 6b 10 f0       	push   $0xf0106bc9
f0102d8d:	68 34 01 00 00       	push   $0x134
f0102d92:	68 d9 6b 10 f0       	push   $0xf0106bd9
f0102d97:	e8 a4 d2 ff ff       	call   f0100040 <_panic>
		//r = page_insert(e->env_pgdir, Page, va, PTE_P | PTE_U | PTE_W);
		r = page_insert(e->env_pgdir, Page, (void *)i, PTE_U | PTE_W);
f0102d9c:	6a 06                	push   $0x6
f0102d9e:	53                   	push   %ebx
f0102d9f:	50                   	push   %eax
f0102da0:	ff 77 60             	pushl  0x60(%edi)
f0102da3:	e8 c4 e3 ff ff       	call   f010116c <page_insert>
		if(r != 0)
f0102da8:	83 c4 10             	add    $0x10,%esp
f0102dab:	85 c0                	test   %eax,%eax
f0102dad:	74 15                	je     f0102dc4 <region_alloc+0x72>
			panic("region_alloc: %e", r);
f0102daf:	50                   	push   %eax
f0102db0:	68 e4 6b 10 f0       	push   $0xf0106be4
f0102db5:	68 38 01 00 00       	push   $0x138
f0102dba:	68 d9 6b 10 f0       	push   $0xf0106bd9
f0102dbf:	e8 7c d2 ff ff       	call   f0100040 <_panic>
	//cprintf("start=%x \n",start);
	//cprintf("end=%x \n",end);

	struct PageInfo *Page;
	int r;
	for(int i = start;i < end;i += PGSIZE)
f0102dc4:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102dca:	39 de                	cmp    %ebx,%esi
f0102dcc:	77 a6                	ja     f0102d74 <region_alloc+0x22>
		r = page_insert(e->env_pgdir, Page, (void *)i, PTE_U | PTE_W);
		if(r != 0)
			panic("region_alloc: %e", r);
			//panic("region_alloc fail");
	}
}
f0102dce:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102dd1:	5b                   	pop    %ebx
f0102dd2:	5e                   	pop    %esi
f0102dd3:	5f                   	pop    %edi
f0102dd4:	5d                   	pop    %ebp
f0102dd5:	c3                   	ret    

f0102dd6 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102dd6:	55                   	push   %ebp
f0102dd7:	89 e5                	mov    %esp,%ebp
f0102dd9:	56                   	push   %esi
f0102dda:	53                   	push   %ebx
f0102ddb:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dde:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102de1:	85 c0                	test   %eax,%eax
f0102de3:	75 1a                	jne    f0102dff <envid2env+0x29>
		*env_store = curenv;
f0102de5:	e8 50 25 00 00       	call   f010533a <cpunum>
f0102dea:	6b c0 74             	imul   $0x74,%eax,%eax
f0102ded:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102df3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102df6:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102df8:	b8 00 00 00 00       	mov    $0x0,%eax
f0102dfd:	eb 70                	jmp    f0102e6f <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102dff:	89 c3                	mov    %eax,%ebx
f0102e01:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102e07:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102e0a:	03 1d 48 a2 22 f0    	add    0xf022a248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102e10:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102e14:	74 05                	je     f0102e1b <envid2env+0x45>
f0102e16:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102e19:	74 10                	je     f0102e2b <envid2env+0x55>
		*env_store = 0;
f0102e1b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e1e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e24:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e29:	eb 44                	jmp    f0102e6f <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102e2b:	84 d2                	test   %dl,%dl
f0102e2d:	74 36                	je     f0102e65 <envid2env+0x8f>
f0102e2f:	e8 06 25 00 00       	call   f010533a <cpunum>
f0102e34:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e37:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f0102e3d:	74 26                	je     f0102e65 <envid2env+0x8f>
f0102e3f:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102e42:	e8 f3 24 00 00       	call   f010533a <cpunum>
f0102e47:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e4a:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102e50:	3b 70 48             	cmp    0x48(%eax),%esi
f0102e53:	74 10                	je     f0102e65 <envid2env+0x8f>
		*env_store = 0;
f0102e55:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e58:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e5e:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e63:	eb 0a                	jmp    f0102e6f <envid2env+0x99>
	}

	*env_store = e;
f0102e65:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e68:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102e6a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102e6f:	5b                   	pop    %ebx
f0102e70:	5e                   	pop    %esi
f0102e71:	5d                   	pop    %ebp
f0102e72:	c3                   	ret    

f0102e73 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102e73:	55                   	push   %ebp
f0102e74:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102e76:	b8 20 f3 11 f0       	mov    $0xf011f320,%eax
f0102e7b:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102e7e:	b8 23 00 00 00       	mov    $0x23,%eax
f0102e83:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102e85:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102e87:	b8 10 00 00 00       	mov    $0x10,%eax
f0102e8c:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102e8e:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102e90:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102e92:	ea 99 2e 10 f0 08 00 	ljmp   $0x8,$0xf0102e99
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102e99:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e9e:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102ea1:	5d                   	pop    %ebp
f0102ea2:	c3                   	ret    

f0102ea3 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102ea3:	55                   	push   %ebp
f0102ea4:	89 e5                	mov    %esp,%ebp
f0102ea6:	56                   	push   %esi
f0102ea7:	53                   	push   %ebx
	// LAB 3: Your code here.
	// struct Env* envs;
	// env_free_list = NULL;
	for(int i = NENV - 1;i >= 0;i--)
	{
		envs[i].env_id = 0;
f0102ea8:	8b 35 48 a2 22 f0    	mov    0xf022a248,%esi
f0102eae:	8b 15 4c a2 22 f0    	mov    0xf022a24c,%edx
f0102eb4:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102eba:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102ebd:	89 c1                	mov    %eax,%ecx
f0102ebf:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f0102ec6:	89 50 44             	mov    %edx,0x44(%eax)
f0102ec9:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];
f0102ecc:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	// struct Env* envs;
	// env_free_list = NULL;
	for(int i = NENV - 1;i >= 0;i--)
f0102ece:	39 d8                	cmp    %ebx,%eax
f0102ed0:	75 eb                	jne    f0102ebd <env_init+0x1a>
f0102ed2:	89 35 4c a2 22 f0    	mov    %esi,0xf022a24c
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
		//envs[i].env_status = 
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f0102ed8:	e8 96 ff ff ff       	call   f0102e73 <env_init_percpu>
}
f0102edd:	5b                   	pop    %ebx
f0102ede:	5e                   	pop    %esi
f0102edf:	5d                   	pop    %ebp
f0102ee0:	c3                   	ret    

f0102ee1 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102ee1:	55                   	push   %ebp
f0102ee2:	89 e5                	mov    %esp,%ebp
f0102ee4:	56                   	push   %esi
f0102ee5:	53                   	push   %ebx
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102ee6:	8b 1d 4c a2 22 f0    	mov    0xf022a24c,%ebx
f0102eec:	85 db                	test   %ebx,%ebx
f0102eee:	0f 84 64 01 00 00    	je     f0103058 <env_alloc+0x177>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102ef4:	83 ec 0c             	sub    $0xc,%esp
f0102ef7:	6a 01                	push   $0x1
f0102ef9:	e8 d4 df ff ff       	call   f0100ed2 <page_alloc>
f0102efe:	89 c6                	mov    %eax,%esi
f0102f00:	83 c4 10             	add    $0x10,%esp
f0102f03:	85 c0                	test   %eax,%eax
f0102f05:	0f 84 54 01 00 00    	je     f010305f <env_alloc+0x17e>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f0b:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102f11:	c1 f8 03             	sar    $0x3,%eax
f0102f14:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f17:	89 c2                	mov    %eax,%edx
f0102f19:	c1 ea 0c             	shr    $0xc,%edx
f0102f1c:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102f22:	72 12                	jb     f0102f36 <env_alloc+0x55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f24:	50                   	push   %eax
f0102f25:	68 04 5a 10 f0       	push   $0xf0105a04
f0102f2a:	6a 58                	push   $0x58
f0102f2c:	68 ad 68 10 f0       	push   $0xf01068ad
f0102f31:	e8 0a d1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102f36:	2d 00 00 00 10       	sub    $0x10000000,%eax
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	// p = page_alloc(ALLOC_ZERO);
	e->env_pgdir = page2kva(p);
f0102f3b:	89 43 60             	mov    %eax,0x60(%ebx)
	//memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
	memmove(e->env_pgdir, kern_pgdir, PGSIZE);
f0102f3e:	83 ec 04             	sub    $0x4,%esp
f0102f41:	68 00 10 00 00       	push   $0x1000
f0102f46:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102f4c:	50                   	push   %eax
f0102f4d:	e8 14 1e 00 00       	call   f0104d66 <memmove>
	p->pp_ref++;
f0102f52:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102f57:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f5a:	83 c4 10             	add    $0x10,%esp
f0102f5d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102f62:	77 15                	ja     f0102f79 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f64:	50                   	push   %eax
f0102f65:	68 28 5a 10 f0       	push   $0xf0105a28
f0102f6a:	68 c9 00 00 00       	push   $0xc9
f0102f6f:	68 d9 6b 10 f0       	push   $0xf0106bd9
f0102f74:	e8 c7 d0 ff ff       	call   f0100040 <_panic>
f0102f79:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102f7f:	83 ca 05             	or     $0x5,%edx
f0102f82:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102f88:	8b 43 48             	mov    0x48(%ebx),%eax
f0102f8b:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102f90:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102f95:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102f9a:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102f9d:	89 da                	mov    %ebx,%edx
f0102f9f:	2b 15 48 a2 22 f0    	sub    0xf022a248,%edx
f0102fa5:	c1 fa 02             	sar    $0x2,%edx
f0102fa8:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0102fae:	09 d0                	or     %edx,%eax
f0102fb0:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102fb3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fb6:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102fb9:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102fc0:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102fc7:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102fce:	83 ec 04             	sub    $0x4,%esp
f0102fd1:	6a 44                	push   $0x44
f0102fd3:	6a 00                	push   $0x0
f0102fd5:	53                   	push   %ebx
f0102fd6:	e8 3e 1d 00 00       	call   f0104d19 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102fdb:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102fe1:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102fe7:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102fed:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102ff4:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0102ffa:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103001:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103005:	8b 43 44             	mov    0x44(%ebx),%eax
f0103008:	a3 4c a2 22 f0       	mov    %eax,0xf022a24c
	*newenv_store = e;
f010300d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103010:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103012:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103015:	e8 20 23 00 00       	call   f010533a <cpunum>
f010301a:	6b c0 74             	imul   $0x74,%eax,%eax
f010301d:	83 c4 10             	add    $0x10,%esp
f0103020:	ba 00 00 00 00       	mov    $0x0,%edx
f0103025:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f010302c:	74 11                	je     f010303f <env_alloc+0x15e>
f010302e:	e8 07 23 00 00       	call   f010533a <cpunum>
f0103033:	6b c0 74             	imul   $0x74,%eax,%eax
f0103036:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010303c:	8b 50 48             	mov    0x48(%eax),%edx
f010303f:	83 ec 04             	sub    $0x4,%esp
f0103042:	53                   	push   %ebx
f0103043:	52                   	push   %edx
f0103044:	68 f5 6b 10 f0       	push   $0xf0106bf5
f0103049:	e8 46 06 00 00       	call   f0103694 <cprintf>
	return 0;
f010304e:	83 c4 10             	add    $0x10,%esp
f0103051:	b8 00 00 00 00       	mov    $0x0,%eax
f0103056:	eb 0c                	jmp    f0103064 <env_alloc+0x183>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103058:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010305d:	eb 05                	jmp    f0103064 <env_alloc+0x183>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f010305f:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103064:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103067:	5b                   	pop    %ebx
f0103068:	5e                   	pop    %esi
f0103069:	5d                   	pop    %ebp
f010306a:	c3                   	ret    

f010306b <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010306b:	55                   	push   %ebp
f010306c:	89 e5                	mov    %esp,%ebp
f010306e:	57                   	push   %edi
f010306f:	56                   	push   %esi
f0103070:	53                   	push   %ebx
f0103071:	83 ec 34             	sub    $0x34,%esp
f0103074:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int r;
	r = env_alloc(&e, 0);
f0103077:	6a 00                	push   $0x0
f0103079:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010307c:	50                   	push   %eax
f010307d:	e8 5f fe ff ff       	call   f0102ee1 <env_alloc>
	if(r != 0)
f0103082:	83 c4 10             	add    $0x10,%esp
f0103085:	85 c0                	test   %eax,%eax
f0103087:	74 15                	je     f010309e <env_create+0x33>
		panic("env_create: %e", r);
f0103089:	50                   	push   %eax
f010308a:	68 0a 6c 10 f0       	push   $0xf0106c0a
f010308f:	68 ad 01 00 00       	push   $0x1ad
f0103094:	68 d9 6b 10 f0       	push   $0xf0106bd9
f0103099:	e8 a2 cf ff ff       	call   f0100040 <_panic>
	//if(env_alloc(&e,0) != 0)
	//	panic("env_alloc fail");
	e->env_type = type;
f010309e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030a1:	89 c2                	mov    %eax,%edx
f01030a3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01030a6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030a9:	89 42 50             	mov    %eax,0x50(%edx)
	struct Elf *elf;
	// 强制类型转换，将binary后的内存空间内容按照结构ELF的格式读取
	elf = (struct Elf *)binary;
	// is this a valid ELF? 判断是否是ELF
	// ELF头开头的结构体叫做魔数,是一个16位的数组
	if(elf->e_magic != ELF_MAGIC)
f01030ac:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01030b2:	74 17                	je     f01030cb <env_create+0x60>
		panic("load segements fail");
f01030b4:	83 ec 04             	sub    $0x4,%esp
f01030b7:	68 19 6c 10 f0       	push   $0xf0106c19
f01030bc:	68 7a 01 00 00       	push   $0x17a
f01030c1:	68 d9 6b 10 f0       	push   $0xf0106bd9
f01030c6:	e8 75 cf ff ff       	call   f0100040 <_panic>
	// load each program segment (ignores ph flags)
	// e_phoff 程序头表的文件偏移地址
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
f01030cb:	89 fb                	mov    %edi,%ebx
f01030cd:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f01030d0:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01030d4:	c1 e6 05             	shl    $0x5,%esi
f01030d7:	01 de                	add    %ebx,%esi
	// 因为后面需要访问刚分配的内存，所以需要将env_pgdir装入cr3，使二级页表能够运作
	lcr3(PADDR(e->env_pgdir));
f01030d9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030dc:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030df:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030e4:	77 15                	ja     f01030fb <env_create+0x90>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030e6:	50                   	push   %eax
f01030e7:	68 28 5a 10 f0       	push   $0xf0105a28
f01030ec:	68 80 01 00 00       	push   $0x180
f01030f1:	68 d9 6b 10 f0       	push   $0xf0106bd9
f01030f6:	e8 45 cf ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01030fb:	05 00 00 00 10       	add    $0x10000000,%eax
f0103100:	0f 22 d8             	mov    %eax,%cr3
f0103103:	eb 60                	jmp    f0103165 <env_create+0xfa>

	for (; ph < eph; ph++)
	{
		// 	(The ELF header should have ph->p_filesz <= ph->p_memsz.)
		if(ph->p_filesz > ph->p_memsz)
f0103105:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103108:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f010310b:	76 17                	jbe    f0103124 <env_create+0xb9>
			panic("memory is not enough for file");
f010310d:	83 ec 04             	sub    $0x4,%esp
f0103110:	68 2d 6c 10 f0       	push   $0xf0106c2d
f0103115:	68 86 01 00 00       	push   $0x186
f010311a:	68 d9 6b 10 f0       	push   $0xf0106bd9
f010311f:	e8 1c cf ff ff       	call   f0100040 <_panic>
		if(ph->p_type == ELF_PROG_LOAD)
f0103124:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103127:	75 39                	jne    f0103162 <env_create+0xf7>
		{
		//  Each segment's virtual address can be found in ph->p_va
		//  and its size in memory can be found in ph->p_memsz.
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0103129:	8b 53 08             	mov    0x8(%ebx),%edx
f010312c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010312f:	e8 1e fc ff ff       	call   f0102d52 <region_alloc>
		//  The ph->p_filesz bytes from the ELF binary, starting at
		//  'binary + ph->p_offset', should be copied to virtual address
		//  ph->p_va. 
			//memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0103134:	83 ec 04             	sub    $0x4,%esp
f0103137:	ff 73 10             	pushl  0x10(%ebx)
f010313a:	89 f8                	mov    %edi,%eax
f010313c:	03 43 04             	add    0x4(%ebx),%eax
f010313f:	50                   	push   %eax
f0103140:	ff 73 08             	pushl  0x8(%ebx)
f0103143:	e8 1e 1c 00 00       	call   f0104d66 <memmove>
        //	Any remaining memory bytes should be cleared to zero.
		    memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
f0103148:	8b 43 10             	mov    0x10(%ebx),%eax
f010314b:	83 c4 0c             	add    $0xc,%esp
f010314e:	8b 53 14             	mov    0x14(%ebx),%edx
f0103151:	29 c2                	sub    %eax,%edx
f0103153:	52                   	push   %edx
f0103154:	6a 00                	push   $0x0
f0103156:	03 43 08             	add    0x8(%ebx),%eax
f0103159:	50                   	push   %eax
f010315a:	e8 ba 1b 00 00       	call   f0104d19 <memset>
f010315f:	83 c4 10             	add    $0x10,%esp
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
	eph = ph + elf->e_phnum;
	// 因为后面需要访问刚分配的内存，所以需要将env_pgdir装入cr3，使二级页表能够运作
	lcr3(PADDR(e->env_pgdir));

	for (; ph < eph; ph++)
f0103162:	83 c3 20             	add    $0x20,%ebx
f0103165:	39 de                	cmp    %ebx,%esi
f0103167:	77 9c                	ja     f0103105 <env_create+0x9a>
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
        //	Any remaining memory bytes should be cleared to zero.
		    memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
		}
	}
	e->env_tf.tf_eip = elf->e_entry;
f0103169:	8b 47 18             	mov    0x18(%edi),%eax
f010316c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010316f:	89 47 30             	mov    %eax,0x30(%edi)
	lcr3(PADDR(kern_pgdir));
f0103172:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103177:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010317c:	77 15                	ja     f0103193 <env_create+0x128>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010317e:	50                   	push   %eax
f010317f:	68 28 5a 10 f0       	push   $0xf0105a28
f0103184:	68 96 01 00 00       	push   $0x196
f0103189:	68 d9 6b 10 f0       	push   $0xf0106bd9
f010318e:	e8 ad ce ff ff       	call   f0100040 <_panic>
f0103193:	05 00 00 00 10       	add    $0x10000000,%eax
f0103198:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *) USTACKTOP-PGSIZE, PGSIZE);
f010319b:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01031a0:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01031a5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031a8:	e8 a5 fb ff ff       	call   f0102d52 <region_alloc>
		panic("env_create: %e", r);
	//if(env_alloc(&e,0) != 0)
	//	panic("env_alloc fail");
	e->env_type = type;
	load_icode(e, binary);
}
f01031ad:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031b0:	5b                   	pop    %ebx
f01031b1:	5e                   	pop    %esi
f01031b2:	5f                   	pop    %edi
f01031b3:	5d                   	pop    %ebp
f01031b4:	c3                   	ret    

f01031b5 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01031b5:	55                   	push   %ebp
f01031b6:	89 e5                	mov    %esp,%ebp
f01031b8:	57                   	push   %edi
f01031b9:	56                   	push   %esi
f01031ba:	53                   	push   %ebx
f01031bb:	83 ec 1c             	sub    $0x1c,%esp
f01031be:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01031c1:	e8 74 21 00 00       	call   f010533a <cpunum>
f01031c6:	6b c0 74             	imul   $0x74,%eax,%eax
f01031c9:	39 b8 28 b0 22 f0    	cmp    %edi,-0xfdd4fd8(%eax)
f01031cf:	75 29                	jne    f01031fa <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f01031d1:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031d6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031db:	77 15                	ja     f01031f2 <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031dd:	50                   	push   %eax
f01031de:	68 28 5a 10 f0       	push   $0xf0105a28
f01031e3:	68 c2 01 00 00       	push   $0x1c2
f01031e8:	68 d9 6b 10 f0       	push   $0xf0106bd9
f01031ed:	e8 4e ce ff ff       	call   f0100040 <_panic>
f01031f2:	05 00 00 00 10       	add    $0x10000000,%eax
f01031f7:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01031fa:	8b 5f 48             	mov    0x48(%edi),%ebx
f01031fd:	e8 38 21 00 00       	call   f010533a <cpunum>
f0103202:	6b c0 74             	imul   $0x74,%eax,%eax
f0103205:	ba 00 00 00 00       	mov    $0x0,%edx
f010320a:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103211:	74 11                	je     f0103224 <env_free+0x6f>
f0103213:	e8 22 21 00 00       	call   f010533a <cpunum>
f0103218:	6b c0 74             	imul   $0x74,%eax,%eax
f010321b:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103221:	8b 50 48             	mov    0x48(%eax),%edx
f0103224:	83 ec 04             	sub    $0x4,%esp
f0103227:	53                   	push   %ebx
f0103228:	52                   	push   %edx
f0103229:	68 4b 6c 10 f0       	push   $0xf0106c4b
f010322e:	e8 61 04 00 00       	call   f0103694 <cprintf>
f0103233:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103236:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010323d:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103240:	89 d0                	mov    %edx,%eax
f0103242:	c1 e0 02             	shl    $0x2,%eax
f0103245:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103248:	8b 47 60             	mov    0x60(%edi),%eax
f010324b:	8b 34 90             	mov    (%eax,%edx,4),%esi
f010324e:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103254:	0f 84 a8 00 00 00    	je     f0103302 <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010325a:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103260:	89 f0                	mov    %esi,%eax
f0103262:	c1 e8 0c             	shr    $0xc,%eax
f0103265:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103268:	39 05 88 ae 22 f0    	cmp    %eax,0xf022ae88
f010326e:	77 15                	ja     f0103285 <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103270:	56                   	push   %esi
f0103271:	68 04 5a 10 f0       	push   $0xf0105a04
f0103276:	68 d1 01 00 00       	push   $0x1d1
f010327b:	68 d9 6b 10 f0       	push   $0xf0106bd9
f0103280:	e8 bb cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103285:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103288:	c1 e0 16             	shl    $0x16,%eax
f010328b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010328e:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103293:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f010329a:	01 
f010329b:	74 17                	je     f01032b4 <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010329d:	83 ec 08             	sub    $0x8,%esp
f01032a0:	89 d8                	mov    %ebx,%eax
f01032a2:	c1 e0 0c             	shl    $0xc,%eax
f01032a5:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01032a8:	50                   	push   %eax
f01032a9:	ff 77 60             	pushl  0x60(%edi)
f01032ac:	e8 72 de ff ff       	call   f0101123 <page_remove>
f01032b1:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032b4:	83 c3 01             	add    $0x1,%ebx
f01032b7:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01032bd:	75 d4                	jne    f0103293 <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01032bf:	8b 47 60             	mov    0x60(%edi),%eax
f01032c2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01032c5:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01032cc:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01032cf:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01032d5:	72 14                	jb     f01032eb <env_free+0x136>
		panic("pa2page called with invalid pa");
f01032d7:	83 ec 04             	sub    $0x4,%esp
f01032da:	68 68 60 10 f0       	push   $0xf0106068
f01032df:	6a 51                	push   $0x51
f01032e1:	68 ad 68 10 f0       	push   $0xf01068ad
f01032e6:	e8 55 cd ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01032eb:	83 ec 0c             	sub    $0xc,%esp
f01032ee:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f01032f3:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01032f6:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01032f9:	50                   	push   %eax
f01032fa:	e8 5e dc ff ff       	call   f0100f5d <page_decref>
f01032ff:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103302:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103306:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103309:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010330e:	0f 85 29 ff ff ff    	jne    f010323d <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103314:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103317:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010331c:	77 15                	ja     f0103333 <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010331e:	50                   	push   %eax
f010331f:	68 28 5a 10 f0       	push   $0xf0105a28
f0103324:	68 df 01 00 00       	push   $0x1df
f0103329:	68 d9 6b 10 f0       	push   $0xf0106bd9
f010332e:	e8 0d cd ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103333:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010333a:	05 00 00 00 10       	add    $0x10000000,%eax
f010333f:	c1 e8 0c             	shr    $0xc,%eax
f0103342:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0103348:	72 14                	jb     f010335e <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f010334a:	83 ec 04             	sub    $0x4,%esp
f010334d:	68 68 60 10 f0       	push   $0xf0106068
f0103352:	6a 51                	push   $0x51
f0103354:	68 ad 68 10 f0       	push   $0xf01068ad
f0103359:	e8 e2 cc ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f010335e:	83 ec 0c             	sub    $0xc,%esp
f0103361:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f0103367:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010336a:	50                   	push   %eax
f010336b:	e8 ed db ff ff       	call   f0100f5d <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103370:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103377:	a1 4c a2 22 f0       	mov    0xf022a24c,%eax
f010337c:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010337f:	89 3d 4c a2 22 f0    	mov    %edi,0xf022a24c
}
f0103385:	83 c4 10             	add    $0x10,%esp
f0103388:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010338b:	5b                   	pop    %ebx
f010338c:	5e                   	pop    %esi
f010338d:	5f                   	pop    %edi
f010338e:	5d                   	pop    %ebp
f010338f:	c3                   	ret    

f0103390 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103390:	55                   	push   %ebp
f0103391:	89 e5                	mov    %esp,%ebp
f0103393:	53                   	push   %ebx
f0103394:	83 ec 04             	sub    $0x4,%esp
f0103397:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f010339a:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f010339e:	75 19                	jne    f01033b9 <env_destroy+0x29>
f01033a0:	e8 95 1f 00 00       	call   f010533a <cpunum>
f01033a5:	6b c0 74             	imul   $0x74,%eax,%eax
f01033a8:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f01033ae:	74 09                	je     f01033b9 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01033b0:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01033b7:	eb 33                	jmp    f01033ec <env_destroy+0x5c>
	}

	env_free(e);
f01033b9:	83 ec 0c             	sub    $0xc,%esp
f01033bc:	53                   	push   %ebx
f01033bd:	e8 f3 fd ff ff       	call   f01031b5 <env_free>

	if (curenv == e) {
f01033c2:	e8 73 1f 00 00       	call   f010533a <cpunum>
f01033c7:	6b c0 74             	imul   $0x74,%eax,%eax
f01033ca:	83 c4 10             	add    $0x10,%esp
f01033cd:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f01033d3:	75 17                	jne    f01033ec <env_destroy+0x5c>
		curenv = NULL;
f01033d5:	e8 60 1f 00 00       	call   f010533a <cpunum>
f01033da:	6b c0 74             	imul   $0x74,%eax,%eax
f01033dd:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f01033e4:	00 00 00 
		sched_yield();
f01033e7:	e8 66 0c 00 00       	call   f0104052 <sched_yield>
	}
}
f01033ec:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01033ef:	c9                   	leave  
f01033f0:	c3                   	ret    

f01033f1 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01033f1:	55                   	push   %ebp
f01033f2:	89 e5                	mov    %esp,%ebp
f01033f4:	53                   	push   %ebx
f01033f5:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01033f8:	e8 3d 1f 00 00       	call   f010533a <cpunum>
f01033fd:	6b c0 74             	imul   $0x74,%eax,%eax
f0103400:	8b 98 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%ebx
f0103406:	e8 2f 1f 00 00       	call   f010533a <cpunum>
f010340b:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f010340e:	8b 65 08             	mov    0x8(%ebp),%esp
f0103411:	61                   	popa   
f0103412:	07                   	pop    %es
f0103413:	1f                   	pop    %ds
f0103414:	83 c4 08             	add    $0x8,%esp
f0103417:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103418:	83 ec 04             	sub    $0x4,%esp
f010341b:	68 61 6c 10 f0       	push   $0xf0106c61
f0103420:	68 15 02 00 00       	push   $0x215
f0103425:	68 d9 6b 10 f0       	push   $0xf0106bd9
f010342a:	e8 11 cc ff ff       	call   f0100040 <_panic>

f010342f <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010342f:	55                   	push   %ebp
f0103430:	89 e5                	mov    %esp,%ebp
f0103432:	53                   	push   %ebx
f0103433:	83 ec 04             	sub    $0x4,%esp
f0103436:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv && curenv->env_status == ENV_RUNNING)
f0103439:	e8 fc 1e 00 00       	call   f010533a <cpunum>
f010343e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103441:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103448:	74 29                	je     f0103473 <env_run+0x44>
f010344a:	e8 eb 1e 00 00       	call   f010533a <cpunum>
f010344f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103452:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103458:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010345c:	75 15                	jne    f0103473 <env_run+0x44>
		curenv->env_status = ENV_RUNNABLE;
f010345e:	e8 d7 1e 00 00       	call   f010533a <cpunum>
f0103463:	6b c0 74             	imul   $0x74,%eax,%eax
f0103466:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010346c:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	curenv = e;
f0103473:	e8 c2 1e 00 00       	call   f010533a <cpunum>
f0103478:	6b c0 74             	imul   $0x74,%eax,%eax
f010347b:	89 98 28 b0 22 f0    	mov    %ebx,-0xfdd4fd8(%eax)
	curenv->env_status = ENV_RUNNING;
f0103481:	e8 b4 1e 00 00       	call   f010533a <cpunum>
f0103486:	6b c0 74             	imul   $0x74,%eax,%eax
f0103489:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010348f:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0103496:	e8 9f 1e 00 00       	call   f010533a <cpunum>
f010349b:	6b c0 74             	imul   $0x74,%eax,%eax
f010349e:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01034a4:	83 40 58 01          	addl   $0x1,0x58(%eax)
	cprintf("%o \n",(physaddr_t)curenv->env_pgdir);
f01034a8:	e8 8d 1e 00 00       	call   f010533a <cpunum>
f01034ad:	83 ec 08             	sub    $0x8,%esp
f01034b0:	6b c0 74             	imul   $0x74,%eax,%eax
f01034b3:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01034b9:	ff 70 60             	pushl  0x60(%eax)
f01034bc:	68 6d 6c 10 f0       	push   $0xf0106c6d
f01034c1:	e8 ce 01 00 00       	call   f0103694 <cprintf>
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01034c6:	c7 04 24 c0 f3 11 f0 	movl   $0xf011f3c0,(%esp)
f01034cd:	e8 73 21 00 00       	call   f0105645 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01034d2:	f3 90                	pause  

	//lab4 unlock
	unlock_kernel();
	lcr3(PADDR(curenv->env_pgdir));
f01034d4:	e8 61 1e 00 00       	call   f010533a <cpunum>
f01034d9:	6b c0 74             	imul   $0x74,%eax,%eax
f01034dc:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01034e2:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034e5:	83 c4 10             	add    $0x10,%esp
f01034e8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034ed:	77 15                	ja     f0103504 <env_run+0xd5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034ef:	50                   	push   %eax
f01034f0:	68 28 5a 10 f0       	push   $0xf0105a28
f01034f5:	68 3c 02 00 00       	push   $0x23c
f01034fa:	68 d9 6b 10 f0       	push   $0xf0106bd9
f01034ff:	e8 3c cb ff ff       	call   f0100040 <_panic>
f0103504:	05 00 00 00 10       	add    $0x10000000,%eax
f0103509:	0f 22 d8             	mov    %eax,%cr3

	env_pop_tf(&e->env_tf);
f010350c:	83 ec 0c             	sub    $0xc,%esp
f010350f:	53                   	push   %ebx
f0103510:	e8 dc fe ff ff       	call   f01033f1 <env_pop_tf>

f0103515 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103515:	55                   	push   %ebp
f0103516:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103518:	ba 70 00 00 00       	mov    $0x70,%edx
f010351d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103520:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103521:	ba 71 00 00 00       	mov    $0x71,%edx
f0103526:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103527:	0f b6 c0             	movzbl %al,%eax
}
f010352a:	5d                   	pop    %ebp
f010352b:	c3                   	ret    

f010352c <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010352c:	55                   	push   %ebp
f010352d:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010352f:	ba 70 00 00 00       	mov    $0x70,%edx
f0103534:	8b 45 08             	mov    0x8(%ebp),%eax
f0103537:	ee                   	out    %al,(%dx)
f0103538:	ba 71 00 00 00       	mov    $0x71,%edx
f010353d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103540:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103541:	5d                   	pop    %ebp
f0103542:	c3                   	ret    

f0103543 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103543:	55                   	push   %ebp
f0103544:	89 e5                	mov    %esp,%ebp
f0103546:	56                   	push   %esi
f0103547:	53                   	push   %ebx
f0103548:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f010354b:	66 a3 a8 f3 11 f0    	mov    %ax,0xf011f3a8
	if (!didinit)
f0103551:	80 3d 50 a2 22 f0 00 	cmpb   $0x0,0xf022a250
f0103558:	74 5a                	je     f01035b4 <irq_setmask_8259A+0x71>
f010355a:	89 c6                	mov    %eax,%esi
f010355c:	ba 21 00 00 00       	mov    $0x21,%edx
f0103561:	ee                   	out    %al,(%dx)
f0103562:	66 c1 e8 08          	shr    $0x8,%ax
f0103566:	ba a1 00 00 00       	mov    $0xa1,%edx
f010356b:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f010356c:	83 ec 0c             	sub    $0xc,%esp
f010356f:	68 72 6c 10 f0       	push   $0xf0106c72
f0103574:	e8 1b 01 00 00       	call   f0103694 <cprintf>
f0103579:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f010357c:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103581:	0f b7 f6             	movzwl %si,%esi
f0103584:	f7 d6                	not    %esi
f0103586:	0f a3 de             	bt     %ebx,%esi
f0103589:	73 11                	jae    f010359c <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f010358b:	83 ec 08             	sub    $0x8,%esp
f010358e:	53                   	push   %ebx
f010358f:	68 33 71 10 f0       	push   $0xf0107133
f0103594:	e8 fb 00 00 00       	call   f0103694 <cprintf>
f0103599:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f010359c:	83 c3 01             	add    $0x1,%ebx
f010359f:	83 fb 10             	cmp    $0x10,%ebx
f01035a2:	75 e2                	jne    f0103586 <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f01035a4:	83 ec 0c             	sub    $0xc,%esp
f01035a7:	68 69 5d 10 f0       	push   $0xf0105d69
f01035ac:	e8 e3 00 00 00       	call   f0103694 <cprintf>
f01035b1:	83 c4 10             	add    $0x10,%esp
}
f01035b4:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01035b7:	5b                   	pop    %ebx
f01035b8:	5e                   	pop    %esi
f01035b9:	5d                   	pop    %ebp
f01035ba:	c3                   	ret    

f01035bb <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f01035bb:	c6 05 50 a2 22 f0 01 	movb   $0x1,0xf022a250
f01035c2:	ba 21 00 00 00       	mov    $0x21,%edx
f01035c7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01035cc:	ee                   	out    %al,(%dx)
f01035cd:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035d2:	ee                   	out    %al,(%dx)
f01035d3:	ba 20 00 00 00       	mov    $0x20,%edx
f01035d8:	b8 11 00 00 00       	mov    $0x11,%eax
f01035dd:	ee                   	out    %al,(%dx)
f01035de:	ba 21 00 00 00       	mov    $0x21,%edx
f01035e3:	b8 20 00 00 00       	mov    $0x20,%eax
f01035e8:	ee                   	out    %al,(%dx)
f01035e9:	b8 04 00 00 00       	mov    $0x4,%eax
f01035ee:	ee                   	out    %al,(%dx)
f01035ef:	b8 03 00 00 00       	mov    $0x3,%eax
f01035f4:	ee                   	out    %al,(%dx)
f01035f5:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035fa:	b8 11 00 00 00       	mov    $0x11,%eax
f01035ff:	ee                   	out    %al,(%dx)
f0103600:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103605:	b8 28 00 00 00       	mov    $0x28,%eax
f010360a:	ee                   	out    %al,(%dx)
f010360b:	b8 02 00 00 00       	mov    $0x2,%eax
f0103610:	ee                   	out    %al,(%dx)
f0103611:	b8 01 00 00 00       	mov    $0x1,%eax
f0103616:	ee                   	out    %al,(%dx)
f0103617:	ba 20 00 00 00       	mov    $0x20,%edx
f010361c:	b8 68 00 00 00       	mov    $0x68,%eax
f0103621:	ee                   	out    %al,(%dx)
f0103622:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103627:	ee                   	out    %al,(%dx)
f0103628:	ba a0 00 00 00       	mov    $0xa0,%edx
f010362d:	b8 68 00 00 00       	mov    $0x68,%eax
f0103632:	ee                   	out    %al,(%dx)
f0103633:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103638:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0103639:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f0103640:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103644:	74 13                	je     f0103659 <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103646:	55                   	push   %ebp
f0103647:	89 e5                	mov    %esp,%ebp
f0103649:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f010364c:	0f b7 c0             	movzwl %ax,%eax
f010364f:	50                   	push   %eax
f0103650:	e8 ee fe ff ff       	call   f0103543 <irq_setmask_8259A>
f0103655:	83 c4 10             	add    $0x10,%esp
}
f0103658:	c9                   	leave  
f0103659:	f3 c3                	repz ret 

f010365b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010365b:	55                   	push   %ebp
f010365c:	89 e5                	mov    %esp,%ebp
f010365e:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103661:	ff 75 08             	pushl  0x8(%ebp)
f0103664:	e8 ed d0 ff ff       	call   f0100756 <cputchar>
	*cnt++;
}
f0103669:	83 c4 10             	add    $0x10,%esp
f010366c:	c9                   	leave  
f010366d:	c3                   	ret    

f010366e <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010366e:	55                   	push   %ebp
f010366f:	89 e5                	mov    %esp,%ebp
f0103671:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103674:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010367b:	ff 75 0c             	pushl  0xc(%ebp)
f010367e:	ff 75 08             	pushl  0x8(%ebp)
f0103681:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103684:	50                   	push   %eax
f0103685:	68 5b 36 10 f0       	push   $0xf010365b
f010368a:	e8 1e 10 00 00       	call   f01046ad <vprintfmt>
	return cnt;
}
f010368f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103692:	c9                   	leave  
f0103693:	c3                   	ret    

f0103694 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103694:	55                   	push   %ebp
f0103695:	89 e5                	mov    %esp,%ebp
f0103697:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010369a:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010369d:	50                   	push   %eax
f010369e:	ff 75 08             	pushl  0x8(%ebp)
f01036a1:	e8 c8 ff ff ff       	call   f010366e <vcprintf>
	va_end(ap);

	return cnt;
}
f01036a6:	c9                   	leave  
f01036a7:	c3                   	ret    

f01036a8 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01036a8:	55                   	push   %ebp
f01036a9:	89 e5                	mov    %esp,%ebp
f01036ab:	57                   	push   %edi
f01036ac:	56                   	push   %esi
f01036ad:	53                   	push   %ebx
f01036ae:	83 ec 0c             	sub    $0xc,%esp
	// user space on that CPU.
	//
	// LAB 4: Your code here:
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - thiscpu->cpu_id*(KSTKSIZE + KSTKGAP);
f01036b1:	e8 84 1c 00 00       	call   f010533a <cpunum>
f01036b6:	89 c3                	mov    %eax,%ebx
f01036b8:	e8 7d 1c 00 00       	call   f010533a <cpunum>
f01036bd:	6b d3 74             	imul   $0x74,%ebx,%edx
f01036c0:	6b c0 74             	imul   $0x74,%eax,%eax
f01036c3:	0f b6 88 20 b0 22 f0 	movzbl -0xfdd4fe0(%eax),%ecx
f01036ca:	c1 e1 10             	shl    $0x10,%ecx
f01036cd:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
f01036d2:	29 c8                	sub    %ecx,%eax
f01036d4:	89 82 30 b0 22 f0    	mov    %eax,-0xfdd4fd0(%edx)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f01036da:	e8 5b 1c 00 00       	call   f010533a <cpunum>
f01036df:	6b c0 74             	imul   $0x74,%eax,%eax
f01036e2:	66 c7 80 34 b0 22 f0 	movw   $0x10,-0xfdd4fcc(%eax)
f01036e9:	10 00 
	//ts.ts_esp0 = KSTACKTOP;
	//ts.ts_ss0 = GD_KD;

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + cpunum()] = SEG16(STS_T32A, (uint32_t) (&(thiscpu->cpu_ts)),
f01036eb:	e8 4a 1c 00 00       	call   f010533a <cpunum>
f01036f0:	8d 58 05             	lea    0x5(%eax),%ebx
f01036f3:	e8 42 1c 00 00       	call   f010533a <cpunum>
f01036f8:	89 c7                	mov    %eax,%edi
f01036fa:	e8 3b 1c 00 00       	call   f010533a <cpunum>
f01036ff:	89 c6                	mov    %eax,%esi
f0103701:	e8 34 1c 00 00       	call   f010533a <cpunum>
f0103706:	66 c7 04 dd 40 f3 11 	movw   $0x67,-0xfee0cc0(,%ebx,8)
f010370d:	f0 67 00 
f0103710:	6b ff 74             	imul   $0x74,%edi,%edi
f0103713:	81 c7 2c b0 22 f0    	add    $0xf022b02c,%edi
f0103719:	66 89 3c dd 42 f3 11 	mov    %di,-0xfee0cbe(,%ebx,8)
f0103720:	f0 
f0103721:	6b d6 74             	imul   $0x74,%esi,%edx
f0103724:	81 c2 2c b0 22 f0    	add    $0xf022b02c,%edx
f010372a:	c1 ea 10             	shr    $0x10,%edx
f010372d:	88 14 dd 44 f3 11 f0 	mov    %dl,-0xfee0cbc(,%ebx,8)
f0103734:	c6 04 dd 45 f3 11 f0 	movb   $0x99,-0xfee0cbb(,%ebx,8)
f010373b:	99 
f010373c:	c6 04 dd 46 f3 11 f0 	movb   $0x40,-0xfee0cba(,%ebx,8)
f0103743:	40 
f0103744:	6b c0 74             	imul   $0x74,%eax,%eax
f0103747:	05 2c b0 22 f0       	add    $0xf022b02c,%eax
f010374c:	c1 e8 18             	shr    $0x18,%eax
f010374f:	88 04 dd 47 f3 11 f0 	mov    %al,-0xfee0cb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + cpunum()].sd_s = 0;
f0103756:	e8 df 1b 00 00       	call   f010533a <cpunum>
f010375b:	80 24 c5 6d f3 11 f0 	andb   $0xef,-0xfee0c93(,%eax,8)
f0103762:	ef 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (cpunum() << 3));
f0103763:	e8 d2 1b 00 00       	call   f010533a <cpunum>
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0103768:	8d 04 c5 28 00 00 00 	lea    0x28(,%eax,8),%eax
f010376f:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0103772:	b8 ac f3 11 f0       	mov    $0xf011f3ac,%eax
f0103777:	0f 01 18             	lidtl  (%eax)

	// Load the IDT
	lidt(&idt_pd);
}
f010377a:	83 c4 0c             	add    $0xc,%esp
f010377d:	5b                   	pop    %ebx
f010377e:	5e                   	pop    %esi
f010377f:	5f                   	pop    %edi
f0103780:	5d                   	pop    %ebp
f0103781:	c3                   	ret    

f0103782 <trap_init>:
}


void
trap_init(void)
{
f0103782:	55                   	push   %ebp
f0103783:	89 e5                	mov    %esp,%ebp
f0103785:	83 ec 08             	sub    $0x8,%esp
	
	void floating_point_error();

	void system_call();

	SETGATE(idt[T_DIVIDE], 1, GD_KT, divide_error, 0);
f0103788:	b8 18 3f 10 f0       	mov    $0xf0103f18,%eax
f010378d:	66 a3 60 a2 22 f0    	mov    %ax,0xf022a260
f0103793:	66 c7 05 62 a2 22 f0 	movw   $0x8,0xf022a262
f010379a:	08 00 
f010379c:	c6 05 64 a2 22 f0 00 	movb   $0x0,0xf022a264
f01037a3:	c6 05 65 a2 22 f0 8f 	movb   $0x8f,0xf022a265
f01037aa:	c1 e8 10             	shr    $0x10,%eax
f01037ad:	66 a3 66 a2 22 f0    	mov    %ax,0xf022a266
	SETGATE(idt[T_DEBUG], 1, GD_KT, debug_exception, 0);
f01037b3:	b8 1e 3f 10 f0       	mov    $0xf0103f1e,%eax
f01037b8:	66 a3 68 a2 22 f0    	mov    %ax,0xf022a268
f01037be:	66 c7 05 6a a2 22 f0 	movw   $0x8,0xf022a26a
f01037c5:	08 00 
f01037c7:	c6 05 6c a2 22 f0 00 	movb   $0x0,0xf022a26c
f01037ce:	c6 05 6d a2 22 f0 8f 	movb   $0x8f,0xf022a26d
f01037d5:	c1 e8 10             	shr    $0x10,%eax
f01037d8:	66 a3 6e a2 22 f0    	mov    %ax,0xf022a26e
	SETGATE(idt[T_NMI], 1, GD_KT, non_maskable_interrupt, 0);
f01037de:	b8 24 3f 10 f0       	mov    $0xf0103f24,%eax
f01037e3:	66 a3 70 a2 22 f0    	mov    %ax,0xf022a270
f01037e9:	66 c7 05 72 a2 22 f0 	movw   $0x8,0xf022a272
f01037f0:	08 00 
f01037f2:	c6 05 74 a2 22 f0 00 	movb   $0x0,0xf022a274
f01037f9:	c6 05 75 a2 22 f0 8f 	movb   $0x8f,0xf022a275
f0103800:	c1 e8 10             	shr    $0x10,%eax
f0103803:	66 a3 76 a2 22 f0    	mov    %ax,0xf022a276
	SETGATE(idt[T_BRKPT], 1, GD_KT, break_point, 3);//!
f0103809:	b8 2a 3f 10 f0       	mov    $0xf0103f2a,%eax
f010380e:	66 a3 78 a2 22 f0    	mov    %ax,0xf022a278
f0103814:	66 c7 05 7a a2 22 f0 	movw   $0x8,0xf022a27a
f010381b:	08 00 
f010381d:	c6 05 7c a2 22 f0 00 	movb   $0x0,0xf022a27c
f0103824:	c6 05 7d a2 22 f0 ef 	movb   $0xef,0xf022a27d
f010382b:	c1 e8 10             	shr    $0x10,%eax
f010382e:	66 a3 7e a2 22 f0    	mov    %ax,0xf022a27e
	SETGATE(idt[T_OFLOW], 1, GD_KT, overflow, 0);
f0103834:	b8 30 3f 10 f0       	mov    $0xf0103f30,%eax
f0103839:	66 a3 80 a2 22 f0    	mov    %ax,0xf022a280
f010383f:	66 c7 05 82 a2 22 f0 	movw   $0x8,0xf022a282
f0103846:	08 00 
f0103848:	c6 05 84 a2 22 f0 00 	movb   $0x0,0xf022a284
f010384f:	c6 05 85 a2 22 f0 8f 	movb   $0x8f,0xf022a285
f0103856:	c1 e8 10             	shr    $0x10,%eax
f0103859:	66 a3 86 a2 22 f0    	mov    %ax,0xf022a286
	SETGATE(idt[T_BOUND], 1, GD_KT, bounds_check, 0);
f010385f:	b8 36 3f 10 f0       	mov    $0xf0103f36,%eax
f0103864:	66 a3 88 a2 22 f0    	mov    %ax,0xf022a288
f010386a:	66 c7 05 8a a2 22 f0 	movw   $0x8,0xf022a28a
f0103871:	08 00 
f0103873:	c6 05 8c a2 22 f0 00 	movb   $0x0,0xf022a28c
f010387a:	c6 05 8d a2 22 f0 8f 	movb   $0x8f,0xf022a28d
f0103881:	c1 e8 10             	shr    $0x10,%eax
f0103884:	66 a3 8e a2 22 f0    	mov    %ax,0xf022a28e
	SETGATE(idt[T_ILLOP], 1, GD_KT, illegal_opcode, 0);
f010388a:	b8 3c 3f 10 f0       	mov    $0xf0103f3c,%eax
f010388f:	66 a3 90 a2 22 f0    	mov    %ax,0xf022a290
f0103895:	66 c7 05 92 a2 22 f0 	movw   $0x8,0xf022a292
f010389c:	08 00 
f010389e:	c6 05 94 a2 22 f0 00 	movb   $0x0,0xf022a294
f01038a5:	c6 05 95 a2 22 f0 8f 	movb   $0x8f,0xf022a295
f01038ac:	c1 e8 10             	shr    $0x10,%eax
f01038af:	66 a3 96 a2 22 f0    	mov    %ax,0xf022a296
	SETGATE(idt[T_DEVICE], 1, GD_KT, device_not_available, 0);
f01038b5:	b8 42 3f 10 f0       	mov    $0xf0103f42,%eax
f01038ba:	66 a3 98 a2 22 f0    	mov    %ax,0xf022a298
f01038c0:	66 c7 05 9a a2 22 f0 	movw   $0x8,0xf022a29a
f01038c7:	08 00 
f01038c9:	c6 05 9c a2 22 f0 00 	movb   $0x0,0xf022a29c
f01038d0:	c6 05 9d a2 22 f0 8f 	movb   $0x8f,0xf022a29d
f01038d7:	c1 e8 10             	shr    $0x10,%eax
f01038da:	66 a3 9e a2 22 f0    	mov    %ax,0xf022a29e
	SETGATE(idt[T_DBLFLT], 1, GD_KT, double_fault, 0);
f01038e0:	b8 48 3f 10 f0       	mov    $0xf0103f48,%eax
f01038e5:	66 a3 a0 a2 22 f0    	mov    %ax,0xf022a2a0
f01038eb:	66 c7 05 a2 a2 22 f0 	movw   $0x8,0xf022a2a2
f01038f2:	08 00 
f01038f4:	c6 05 a4 a2 22 f0 00 	movb   $0x0,0xf022a2a4
f01038fb:	c6 05 a5 a2 22 f0 8f 	movb   $0x8f,0xf022a2a5
f0103902:	c1 e8 10             	shr    $0x10,%eax
f0103905:	66 a3 a6 a2 22 f0    	mov    %ax,0xf022a2a6

	SETGATE(idt[T_TSS], 1, GD_KT, invalid_task_switch_segment, 0);
f010390b:	b8 4c 3f 10 f0       	mov    $0xf0103f4c,%eax
f0103910:	66 a3 b0 a2 22 f0    	mov    %ax,0xf022a2b0
f0103916:	66 c7 05 b2 a2 22 f0 	movw   $0x8,0xf022a2b2
f010391d:	08 00 
f010391f:	c6 05 b4 a2 22 f0 00 	movb   $0x0,0xf022a2b4
f0103926:	c6 05 b5 a2 22 f0 8f 	movb   $0x8f,0xf022a2b5
f010392d:	c1 e8 10             	shr    $0x10,%eax
f0103930:	66 a3 b6 a2 22 f0    	mov    %ax,0xf022a2b6
	SETGATE(idt[T_SEGNP], 1, GD_KT, segment_not_present, 0);
f0103936:	b8 50 3f 10 f0       	mov    $0xf0103f50,%eax
f010393b:	66 a3 b8 a2 22 f0    	mov    %ax,0xf022a2b8
f0103941:	66 c7 05 ba a2 22 f0 	movw   $0x8,0xf022a2ba
f0103948:	08 00 
f010394a:	c6 05 bc a2 22 f0 00 	movb   $0x0,0xf022a2bc
f0103951:	c6 05 bd a2 22 f0 8f 	movb   $0x8f,0xf022a2bd
f0103958:	c1 e8 10             	shr    $0x10,%eax
f010395b:	66 a3 be a2 22 f0    	mov    %ax,0xf022a2be
	SETGATE(idt[T_STACK], 1, GD_KT, stack_exception, 0);
f0103961:	b8 54 3f 10 f0       	mov    $0xf0103f54,%eax
f0103966:	66 a3 c0 a2 22 f0    	mov    %ax,0xf022a2c0
f010396c:	66 c7 05 c2 a2 22 f0 	movw   $0x8,0xf022a2c2
f0103973:	08 00 
f0103975:	c6 05 c4 a2 22 f0 00 	movb   $0x0,0xf022a2c4
f010397c:	c6 05 c5 a2 22 f0 8f 	movb   $0x8f,0xf022a2c5
f0103983:	c1 e8 10             	shr    $0x10,%eax
f0103986:	66 a3 c6 a2 22 f0    	mov    %ax,0xf022a2c6
	SETGATE(idt[T_GPFLT], 1, GD_KT, general_protection_fault, 0);
f010398c:	b8 58 3f 10 f0       	mov    $0xf0103f58,%eax
f0103991:	66 a3 c8 a2 22 f0    	mov    %ax,0xf022a2c8
f0103997:	66 c7 05 ca a2 22 f0 	movw   $0x8,0xf022a2ca
f010399e:	08 00 
f01039a0:	c6 05 cc a2 22 f0 00 	movb   $0x0,0xf022a2cc
f01039a7:	c6 05 cd a2 22 f0 8f 	movb   $0x8f,0xf022a2cd
f01039ae:	c1 e8 10             	shr    $0x10,%eax
f01039b1:	66 a3 ce a2 22 f0    	mov    %ax,0xf022a2ce
	SETGATE(idt[T_PGFLT], 1, GD_KT, page_fault, 0);
f01039b7:	b8 5c 3f 10 f0       	mov    $0xf0103f5c,%eax
f01039bc:	66 a3 d0 a2 22 f0    	mov    %ax,0xf022a2d0
f01039c2:	66 c7 05 d2 a2 22 f0 	movw   $0x8,0xf022a2d2
f01039c9:	08 00 
f01039cb:	c6 05 d4 a2 22 f0 00 	movb   $0x0,0xf022a2d4
f01039d2:	c6 05 d5 a2 22 f0 8f 	movb   $0x8f,0xf022a2d5
f01039d9:	c1 e8 10             	shr    $0x10,%eax
f01039dc:	66 a3 d6 a2 22 f0    	mov    %ax,0xf022a2d6

	SETGATE(idt[T_FPERR], 1, GD_KT, floating_point_error, 0);
f01039e2:	b8 60 3f 10 f0       	mov    $0xf0103f60,%eax
f01039e7:	66 a3 e0 a2 22 f0    	mov    %ax,0xf022a2e0
f01039ed:	66 c7 05 e2 a2 22 f0 	movw   $0x8,0xf022a2e2
f01039f4:	08 00 
f01039f6:	c6 05 e4 a2 22 f0 00 	movb   $0x0,0xf022a2e4
f01039fd:	c6 05 e5 a2 22 f0 8f 	movb   $0x8f,0xf022a2e5
f0103a04:	c1 e8 10             	shr    $0x10,%eax
f0103a07:	66 a3 e6 a2 22 f0    	mov    %ax,0xf022a2e6

	SETGATE(idt[T_SYSCALL], 0, GD_KT, system_call, 3);
f0103a0d:	b8 66 3f 10 f0       	mov    $0xf0103f66,%eax
f0103a12:	66 a3 e0 a3 22 f0    	mov    %ax,0xf022a3e0
f0103a18:	66 c7 05 e2 a3 22 f0 	movw   $0x8,0xf022a3e2
f0103a1f:	08 00 
f0103a21:	c6 05 e4 a3 22 f0 00 	movb   $0x0,0xf022a3e4
f0103a28:	c6 05 e5 a3 22 f0 ee 	movb   $0xee,0xf022a3e5
f0103a2f:	c1 e8 10             	shr    $0x10,%eax
f0103a32:	66 a3 e6 a3 22 f0    	mov    %ax,0xf022a3e6

	// Per-CPU setup 
	trap_init_percpu();
f0103a38:	e8 6b fc ff ff       	call   f01036a8 <trap_init_percpu>
}
f0103a3d:	c9                   	leave  
f0103a3e:	c3                   	ret    

f0103a3f <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103a3f:	55                   	push   %ebp
f0103a40:	89 e5                	mov    %esp,%ebp
f0103a42:	53                   	push   %ebx
f0103a43:	83 ec 0c             	sub    $0xc,%esp
f0103a46:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103a49:	ff 33                	pushl  (%ebx)
f0103a4b:	68 86 6c 10 f0       	push   $0xf0106c86
f0103a50:	e8 3f fc ff ff       	call   f0103694 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103a55:	83 c4 08             	add    $0x8,%esp
f0103a58:	ff 73 04             	pushl  0x4(%ebx)
f0103a5b:	68 95 6c 10 f0       	push   $0xf0106c95
f0103a60:	e8 2f fc ff ff       	call   f0103694 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103a65:	83 c4 08             	add    $0x8,%esp
f0103a68:	ff 73 08             	pushl  0x8(%ebx)
f0103a6b:	68 a4 6c 10 f0       	push   $0xf0106ca4
f0103a70:	e8 1f fc ff ff       	call   f0103694 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103a75:	83 c4 08             	add    $0x8,%esp
f0103a78:	ff 73 0c             	pushl  0xc(%ebx)
f0103a7b:	68 b3 6c 10 f0       	push   $0xf0106cb3
f0103a80:	e8 0f fc ff ff       	call   f0103694 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103a85:	83 c4 08             	add    $0x8,%esp
f0103a88:	ff 73 10             	pushl  0x10(%ebx)
f0103a8b:	68 c2 6c 10 f0       	push   $0xf0106cc2
f0103a90:	e8 ff fb ff ff       	call   f0103694 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103a95:	83 c4 08             	add    $0x8,%esp
f0103a98:	ff 73 14             	pushl  0x14(%ebx)
f0103a9b:	68 d1 6c 10 f0       	push   $0xf0106cd1
f0103aa0:	e8 ef fb ff ff       	call   f0103694 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103aa5:	83 c4 08             	add    $0x8,%esp
f0103aa8:	ff 73 18             	pushl  0x18(%ebx)
f0103aab:	68 e0 6c 10 f0       	push   $0xf0106ce0
f0103ab0:	e8 df fb ff ff       	call   f0103694 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103ab5:	83 c4 08             	add    $0x8,%esp
f0103ab8:	ff 73 1c             	pushl  0x1c(%ebx)
f0103abb:	68 ef 6c 10 f0       	push   $0xf0106cef
f0103ac0:	e8 cf fb ff ff       	call   f0103694 <cprintf>
}
f0103ac5:	83 c4 10             	add    $0x10,%esp
f0103ac8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103acb:	c9                   	leave  
f0103acc:	c3                   	ret    

f0103acd <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103acd:	55                   	push   %ebp
f0103ace:	89 e5                	mov    %esp,%ebp
f0103ad0:	56                   	push   %esi
f0103ad1:	53                   	push   %ebx
f0103ad2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103ad5:	e8 60 18 00 00       	call   f010533a <cpunum>
f0103ada:	83 ec 04             	sub    $0x4,%esp
f0103add:	50                   	push   %eax
f0103ade:	53                   	push   %ebx
f0103adf:	68 53 6d 10 f0       	push   $0xf0106d53
f0103ae4:	e8 ab fb ff ff       	call   f0103694 <cprintf>
	print_regs(&tf->tf_regs);
f0103ae9:	89 1c 24             	mov    %ebx,(%esp)
f0103aec:	e8 4e ff ff ff       	call   f0103a3f <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103af1:	83 c4 08             	add    $0x8,%esp
f0103af4:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103af8:	50                   	push   %eax
f0103af9:	68 71 6d 10 f0       	push   $0xf0106d71
f0103afe:	e8 91 fb ff ff       	call   f0103694 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103b03:	83 c4 08             	add    $0x8,%esp
f0103b06:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103b0a:	50                   	push   %eax
f0103b0b:	68 84 6d 10 f0       	push   $0xf0106d84
f0103b10:	e8 7f fb ff ff       	call   f0103694 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b15:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103b18:	83 c4 10             	add    $0x10,%esp
f0103b1b:	83 f8 13             	cmp    $0x13,%eax
f0103b1e:	77 09                	ja     f0103b29 <print_trapframe+0x5c>
		return excnames[trapno];
f0103b20:	8b 14 85 20 70 10 f0 	mov    -0xfef8fe0(,%eax,4),%edx
f0103b27:	eb 1f                	jmp    f0103b48 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103b29:	83 f8 30             	cmp    $0x30,%eax
f0103b2c:	74 15                	je     f0103b43 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103b2e:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103b31:	83 fa 10             	cmp    $0x10,%edx
f0103b34:	b9 1d 6d 10 f0       	mov    $0xf0106d1d,%ecx
f0103b39:	ba 0a 6d 10 f0       	mov    $0xf0106d0a,%edx
f0103b3e:	0f 43 d1             	cmovae %ecx,%edx
f0103b41:	eb 05                	jmp    f0103b48 <print_trapframe+0x7b>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103b43:	ba fe 6c 10 f0       	mov    $0xf0106cfe,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b48:	83 ec 04             	sub    $0x4,%esp
f0103b4b:	52                   	push   %edx
f0103b4c:	50                   	push   %eax
f0103b4d:	68 97 6d 10 f0       	push   $0xf0106d97
f0103b52:	e8 3d fb ff ff       	call   f0103694 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103b57:	83 c4 10             	add    $0x10,%esp
f0103b5a:	3b 1d 60 aa 22 f0    	cmp    0xf022aa60,%ebx
f0103b60:	75 1a                	jne    f0103b7c <print_trapframe+0xaf>
f0103b62:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b66:	75 14                	jne    f0103b7c <print_trapframe+0xaf>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103b68:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103b6b:	83 ec 08             	sub    $0x8,%esp
f0103b6e:	50                   	push   %eax
f0103b6f:	68 a9 6d 10 f0       	push   $0xf0106da9
f0103b74:	e8 1b fb ff ff       	call   f0103694 <cprintf>
f0103b79:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103b7c:	83 ec 08             	sub    $0x8,%esp
f0103b7f:	ff 73 2c             	pushl  0x2c(%ebx)
f0103b82:	68 b8 6d 10 f0       	push   $0xf0106db8
f0103b87:	e8 08 fb ff ff       	call   f0103694 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103b8c:	83 c4 10             	add    $0x10,%esp
f0103b8f:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b93:	75 49                	jne    f0103bde <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103b95:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103b98:	89 c2                	mov    %eax,%edx
f0103b9a:	83 e2 01             	and    $0x1,%edx
f0103b9d:	ba 37 6d 10 f0       	mov    $0xf0106d37,%edx
f0103ba2:	b9 2c 6d 10 f0       	mov    $0xf0106d2c,%ecx
f0103ba7:	0f 44 ca             	cmove  %edx,%ecx
f0103baa:	89 c2                	mov    %eax,%edx
f0103bac:	83 e2 02             	and    $0x2,%edx
f0103baf:	ba 49 6d 10 f0       	mov    $0xf0106d49,%edx
f0103bb4:	be 43 6d 10 f0       	mov    $0xf0106d43,%esi
f0103bb9:	0f 45 d6             	cmovne %esi,%edx
f0103bbc:	83 e0 04             	and    $0x4,%eax
f0103bbf:	be 66 6e 10 f0       	mov    $0xf0106e66,%esi
f0103bc4:	b8 4e 6d 10 f0       	mov    $0xf0106d4e,%eax
f0103bc9:	0f 44 c6             	cmove  %esi,%eax
f0103bcc:	51                   	push   %ecx
f0103bcd:	52                   	push   %edx
f0103bce:	50                   	push   %eax
f0103bcf:	68 c6 6d 10 f0       	push   $0xf0106dc6
f0103bd4:	e8 bb fa ff ff       	call   f0103694 <cprintf>
f0103bd9:	83 c4 10             	add    $0x10,%esp
f0103bdc:	eb 10                	jmp    f0103bee <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103bde:	83 ec 0c             	sub    $0xc,%esp
f0103be1:	68 69 5d 10 f0       	push   $0xf0105d69
f0103be6:	e8 a9 fa ff ff       	call   f0103694 <cprintf>
f0103beb:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103bee:	83 ec 08             	sub    $0x8,%esp
f0103bf1:	ff 73 30             	pushl  0x30(%ebx)
f0103bf4:	68 d5 6d 10 f0       	push   $0xf0106dd5
f0103bf9:	e8 96 fa ff ff       	call   f0103694 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103bfe:	83 c4 08             	add    $0x8,%esp
f0103c01:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103c05:	50                   	push   %eax
f0103c06:	68 e4 6d 10 f0       	push   $0xf0106de4
f0103c0b:	e8 84 fa ff ff       	call   f0103694 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103c10:	83 c4 08             	add    $0x8,%esp
f0103c13:	ff 73 38             	pushl  0x38(%ebx)
f0103c16:	68 f7 6d 10 f0       	push   $0xf0106df7
f0103c1b:	e8 74 fa ff ff       	call   f0103694 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103c20:	83 c4 10             	add    $0x10,%esp
f0103c23:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c27:	74 25                	je     f0103c4e <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103c29:	83 ec 08             	sub    $0x8,%esp
f0103c2c:	ff 73 3c             	pushl  0x3c(%ebx)
f0103c2f:	68 06 6e 10 f0       	push   $0xf0106e06
f0103c34:	e8 5b fa ff ff       	call   f0103694 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103c39:	83 c4 08             	add    $0x8,%esp
f0103c3c:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103c40:	50                   	push   %eax
f0103c41:	68 15 6e 10 f0       	push   $0xf0106e15
f0103c46:	e8 49 fa ff ff       	call   f0103694 <cprintf>
f0103c4b:	83 c4 10             	add    $0x10,%esp
	}
}
f0103c4e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103c51:	5b                   	pop    %ebx
f0103c52:	5e                   	pop    %esi
f0103c53:	5d                   	pop    %ebp
f0103c54:	c3                   	ret    

f0103c55 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103c55:	55                   	push   %ebp
f0103c56:	89 e5                	mov    %esp,%ebp
f0103c58:	57                   	push   %edi
f0103c59:	56                   	push   %esi
f0103c5a:	53                   	push   %ebx
f0103c5b:	83 ec 0c             	sub    $0xc,%esp
f0103c5e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103c61:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs & 3) == 0) //缺页中断发生在内核中
f0103c64:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c68:	75 17                	jne    f0103c81 <page_fault_handler+0x2c>
    	panic("page fault happen in kernel mode!\n");
f0103c6a:	83 ec 04             	sub    $0x4,%esp
f0103c6d:	68 d0 6f 10 f0       	push   $0xf0106fd0
f0103c72:	68 53 01 00 00       	push   $0x153
f0103c77:	68 28 6e 10 f0       	push   $0xf0106e28
f0103c7c:	e8 bf c3 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c81:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103c84:	e8 b1 16 00 00       	call   f010533a <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c89:	57                   	push   %edi
f0103c8a:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103c8b:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c8e:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103c94:	ff 70 48             	pushl  0x48(%eax)
f0103c97:	68 f4 6f 10 f0       	push   $0xf0106ff4
f0103c9c:	e8 f3 f9 ff ff       	call   f0103694 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103ca1:	89 1c 24             	mov    %ebx,(%esp)
f0103ca4:	e8 24 fe ff ff       	call   f0103acd <print_trapframe>
	env_destroy(curenv);
f0103ca9:	e8 8c 16 00 00       	call   f010533a <cpunum>
f0103cae:	83 c4 04             	add    $0x4,%esp
f0103cb1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cb4:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103cba:	e8 d1 f6 ff ff       	call   f0103390 <env_destroy>
}
f0103cbf:	83 c4 10             	add    $0x10,%esp
f0103cc2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103cc5:	5b                   	pop    %ebx
f0103cc6:	5e                   	pop    %esi
f0103cc7:	5f                   	pop    %edi
f0103cc8:	5d                   	pop    %ebp
f0103cc9:	c3                   	ret    

f0103cca <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103cca:	55                   	push   %ebp
f0103ccb:	89 e5                	mov    %esp,%ebp
f0103ccd:	57                   	push   %edi
f0103cce:	56                   	push   %esi
f0103ccf:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103cd2:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103cd3:	83 3d 80 ae 22 f0 00 	cmpl   $0x0,0xf022ae80
f0103cda:	74 01                	je     f0103cdd <trap+0x13>
		asm volatile("hlt");
f0103cdc:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103cdd:	e8 58 16 00 00       	call   f010533a <cpunum>
f0103ce2:	6b d0 74             	imul   $0x74,%eax,%edx
f0103ce5:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103ceb:	b8 01 00 00 00       	mov    $0x1,%eax
f0103cf0:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103cf4:	83 f8 02             	cmp    $0x2,%eax
f0103cf7:	75 10                	jne    f0103d09 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103cf9:	83 ec 0c             	sub    $0xc,%esp
f0103cfc:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103d01:	e8 a2 18 00 00       	call   f01055a8 <spin_lock>
f0103d06:	83 c4 10             	add    $0x10,%esp

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103d09:	9c                   	pushf  
f0103d0a:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d0b:	f6 c4 02             	test   $0x2,%ah
f0103d0e:	74 19                	je     f0103d29 <trap+0x5f>
f0103d10:	68 34 6e 10 f0       	push   $0xf0106e34
f0103d15:	68 c7 68 10 f0       	push   $0xf01068c7
f0103d1a:	68 1d 01 00 00       	push   $0x11d
f0103d1f:	68 28 6e 10 f0       	push   $0xf0106e28
f0103d24:	e8 17 c3 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103d29:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d2d:	83 e0 03             	and    $0x3,%eax
f0103d30:	66 83 f8 03          	cmp    $0x3,%ax
f0103d34:	0f 85 a0 00 00 00    	jne    f0103dda <trap+0x110>
f0103d3a:	83 ec 0c             	sub    $0xc,%esp
f0103d3d:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103d42:	e8 61 18 00 00       	call   f01055a8 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f0103d47:	e8 ee 15 00 00       	call   f010533a <cpunum>
f0103d4c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d4f:	83 c4 10             	add    $0x10,%esp
f0103d52:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103d59:	75 19                	jne    f0103d74 <trap+0xaa>
f0103d5b:	68 4d 6e 10 f0       	push   $0xf0106e4d
f0103d60:	68 c7 68 10 f0       	push   $0xf01068c7
f0103d65:	68 25 01 00 00       	push   $0x125
f0103d6a:	68 28 6e 10 f0       	push   $0xf0106e28
f0103d6f:	e8 cc c2 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103d74:	e8 c1 15 00 00       	call   f010533a <cpunum>
f0103d79:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d7c:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103d82:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103d86:	75 2d                	jne    f0103db5 <trap+0xeb>
			env_free(curenv);
f0103d88:	e8 ad 15 00 00       	call   f010533a <cpunum>
f0103d8d:	83 ec 0c             	sub    $0xc,%esp
f0103d90:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d93:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103d99:	e8 17 f4 ff ff       	call   f01031b5 <env_free>
			curenv = NULL;
f0103d9e:	e8 97 15 00 00       	call   f010533a <cpunum>
f0103da3:	6b c0 74             	imul   $0x74,%eax,%eax
f0103da6:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103dad:	00 00 00 
			sched_yield();
f0103db0:	e8 9d 02 00 00       	call   f0104052 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103db5:	e8 80 15 00 00       	call   f010533a <cpunum>
f0103dba:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dbd:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103dc3:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103dc8:	89 c7                	mov    %eax,%edi
f0103dca:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103dcc:	e8 69 15 00 00       	call   f010533a <cpunum>
f0103dd1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dd4:	8b b0 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103dda:	89 35 60 aa 22 f0    	mov    %esi,0xf022aa60
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch (tf->tf_trapno)
f0103de0:	8b 46 28             	mov    0x28(%esi),%eax
f0103de3:	83 f8 0e             	cmp    $0xe,%eax
f0103de6:	74 0c                	je     f0103df4 <trap+0x12a>
f0103de8:	83 f8 30             	cmp    $0x30,%eax
f0103deb:	74 23                	je     f0103e10 <trap+0x146>
f0103ded:	83 f8 03             	cmp    $0x3,%eax
f0103df0:	75 3e                	jne    f0103e30 <trap+0x166>
f0103df2:	eb 0e                	jmp    f0103e02 <trap+0x138>
	{
	case T_PGFLT:
		page_fault_handler(tf);
f0103df4:	83 ec 0c             	sub    $0xc,%esp
f0103df7:	56                   	push   %esi
f0103df8:	e8 58 fe ff ff       	call   f0103c55 <page_fault_handler>
f0103dfd:	83 c4 10             	add    $0x10,%esp
f0103e00:	eb 73                	jmp    f0103e75 <trap+0x1ab>
		break;
	case T_BRKPT:
		monitor(tf);
f0103e02:	83 ec 0c             	sub    $0xc,%esp
f0103e05:	56                   	push   %esi
f0103e06:	e8 f6 ca ff ff       	call   f0100901 <monitor>
f0103e0b:	83 c4 10             	add    $0x10,%esp
f0103e0e:	eb 65                	jmp    f0103e75 <trap+0x1ab>
		break;
	case T_SYSCALL:
		tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, 
f0103e10:	8b 46 18             	mov    0x18(%esi),%eax
f0103e13:	83 ec 08             	sub    $0x8,%esp
f0103e16:	ff 76 04             	pushl  0x4(%esi)
f0103e19:	ff 36                	pushl  (%esi)
f0103e1b:	50                   	push   %eax
f0103e1c:	50                   	push   %eax
f0103e1d:	ff 76 14             	pushl  0x14(%esi)
f0103e20:	ff 76 1c             	pushl  0x1c(%esi)
f0103e23:	e8 b9 02 00 00       	call   f01040e1 <syscall>
f0103e28:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103e2b:	83 c4 20             	add    $0x20,%esp
f0103e2e:	eb 45                	jmp    f0103e75 <trap+0x1ab>
		tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx, tf->tf_regs.reg_ecx, 
		tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
		break;
	default:
		// Unexpected trap: The user process or the kernel has a bug.
		print_trapframe(tf);
f0103e30:	83 ec 0c             	sub    $0xc,%esp
f0103e33:	56                   	push   %esi
f0103e34:	e8 94 fc ff ff       	call   f0103acd <print_trapframe>
		if (tf->tf_cs == GD_KT)
f0103e39:	83 c4 10             	add    $0x10,%esp
f0103e3c:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103e41:	75 17                	jne    f0103e5a <trap+0x190>
			panic("unhandled trap in kernel");
f0103e43:	83 ec 04             	sub    $0x4,%esp
f0103e46:	68 54 6e 10 f0       	push   $0xf0106e54
f0103e4b:	68 eb 00 00 00       	push   $0xeb
f0103e50:	68 28 6e 10 f0       	push   $0xf0106e28
f0103e55:	e8 e6 c1 ff ff       	call   f0100040 <_panic>
		else
		{
			env_destroy(curenv);
f0103e5a:	e8 db 14 00 00       	call   f010533a <cpunum>
f0103e5f:	83 ec 0c             	sub    $0xc,%esp
f0103e62:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e65:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103e6b:	e8 20 f5 ff ff       	call   f0103390 <env_destroy>
f0103e70:	83 c4 10             	add    $0x10,%esp
f0103e73:	eb 63                	jmp    f0103ed8 <trap+0x20e>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103e75:	83 7e 28 27          	cmpl   $0x27,0x28(%esi)
f0103e79:	75 1a                	jne    f0103e95 <trap+0x1cb>
		cprintf("Spurious interrupt on irq 7\n");
f0103e7b:	83 ec 0c             	sub    $0xc,%esp
f0103e7e:	68 6d 6e 10 f0       	push   $0xf0106e6d
f0103e83:	e8 0c f8 ff ff       	call   f0103694 <cprintf>
		print_trapframe(tf);
f0103e88:	89 34 24             	mov    %esi,(%esp)
f0103e8b:	e8 3d fc ff ff       	call   f0103acd <print_trapframe>
f0103e90:	83 c4 10             	add    $0x10,%esp
f0103e93:	eb 43                	jmp    f0103ed8 <trap+0x20e>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103e95:	83 ec 0c             	sub    $0xc,%esp
f0103e98:	56                   	push   %esi
f0103e99:	e8 2f fc ff ff       	call   f0103acd <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103e9e:	83 c4 10             	add    $0x10,%esp
f0103ea1:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103ea6:	75 17                	jne    f0103ebf <trap+0x1f5>
		panic("unhandled trap in kernel");
f0103ea8:	83 ec 04             	sub    $0x4,%esp
f0103eab:	68 54 6e 10 f0       	push   $0xf0106e54
f0103eb0:	68 03 01 00 00       	push   $0x103
f0103eb5:	68 28 6e 10 f0       	push   $0xf0106e28
f0103eba:	e8 81 c1 ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f0103ebf:	e8 76 14 00 00       	call   f010533a <cpunum>
f0103ec4:	83 ec 0c             	sub    $0xc,%esp
f0103ec7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eca:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103ed0:	e8 bb f4 ff ff       	call   f0103390 <env_destroy>
f0103ed5:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103ed8:	e8 5d 14 00 00       	call   f010533a <cpunum>
f0103edd:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ee0:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103ee7:	74 2a                	je     f0103f13 <trap+0x249>
f0103ee9:	e8 4c 14 00 00       	call   f010533a <cpunum>
f0103eee:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ef1:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103ef7:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103efb:	75 16                	jne    f0103f13 <trap+0x249>
		env_run(curenv);
f0103efd:	e8 38 14 00 00       	call   f010533a <cpunum>
f0103f02:	83 ec 0c             	sub    $0xc,%esp
f0103f05:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f08:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103f0e:	e8 1c f5 ff ff       	call   f010342f <env_run>
	else
		sched_yield();
f0103f13:	e8 3a 01 00 00       	call   f0104052 <sched_yield>

f0103f18 <divide_error>:
 * Lab 3: Your code here for generating entry points for the different traps.
 */



	TRAPHANDLER_NOEC(divide_error, T_DIVIDE) 
f0103f18:	6a 00                	push   $0x0
f0103f1a:	6a 00                	push   $0x0
f0103f1c:	eb 4e                	jmp    f0103f6c <_alltraps>

f0103f1e <debug_exception>:
	TRAPHANDLER_NOEC(debug_exception, T_DEBUG) 
f0103f1e:	6a 00                	push   $0x0
f0103f20:	6a 01                	push   $0x1
f0103f22:	eb 48                	jmp    f0103f6c <_alltraps>

f0103f24 <non_maskable_interrupt>:
	TRAPHANDLER_NOEC(non_maskable_interrupt, T_NMI) 
f0103f24:	6a 00                	push   $0x0
f0103f26:	6a 02                	push   $0x2
f0103f28:	eb 42                	jmp    f0103f6c <_alltraps>

f0103f2a <break_point>:
	TRAPHANDLER_NOEC(break_point, T_BRKPT)// inc/x86.中有breakpoint同名函数
f0103f2a:	6a 00                	push   $0x0
f0103f2c:	6a 03                	push   $0x3
f0103f2e:	eb 3c                	jmp    f0103f6c <_alltraps>

f0103f30 <overflow>:
	TRAPHANDLER_NOEC(overflow, T_OFLOW) 
f0103f30:	6a 00                	push   $0x0
f0103f32:	6a 04                	push   $0x4
f0103f34:	eb 36                	jmp    f0103f6c <_alltraps>

f0103f36 <bounds_check>:
	TRAPHANDLER_NOEC(bounds_check, T_BOUND) 
f0103f36:	6a 00                	push   $0x0
f0103f38:	6a 05                	push   $0x5
f0103f3a:	eb 30                	jmp    f0103f6c <_alltraps>

f0103f3c <illegal_opcode>:
	TRAPHANDLER_NOEC(illegal_opcode, T_ILLOP) 
f0103f3c:	6a 00                	push   $0x0
f0103f3e:	6a 06                	push   $0x6
f0103f40:	eb 2a                	jmp    f0103f6c <_alltraps>

f0103f42 <device_not_available>:
	TRAPHANDLER_NOEC(device_not_available, T_DEVICE) 
f0103f42:	6a 00                	push   $0x0
f0103f44:	6a 07                	push   $0x7
f0103f46:	eb 24                	jmp    f0103f6c <_alltraps>

f0103f48 <double_fault>:
	TRAPHANDLER(double_fault, T_DBLFLT) 
f0103f48:	6a 08                	push   $0x8
f0103f4a:	eb 20                	jmp    f0103f6c <_alltraps>

f0103f4c <invalid_task_switch_segment>:

	TRAPHANDLER(invalid_task_switch_segment, T_TSS) 
f0103f4c:	6a 0a                	push   $0xa
f0103f4e:	eb 1c                	jmp    f0103f6c <_alltraps>

f0103f50 <segment_not_present>:
	TRAPHANDLER(segment_not_present, T_SEGNP) 
f0103f50:	6a 0b                	push   $0xb
f0103f52:	eb 18                	jmp    f0103f6c <_alltraps>

f0103f54 <stack_exception>:
	TRAPHANDLER(stack_exception, T_STACK) 
f0103f54:	6a 0c                	push   $0xc
f0103f56:	eb 14                	jmp    f0103f6c <_alltraps>

f0103f58 <general_protection_fault>:
	TRAPHANDLER(general_protection_fault, T_GPFLT) 
f0103f58:	6a 0d                	push   $0xd
f0103f5a:	eb 10                	jmp    f0103f6c <_alltraps>

f0103f5c <page_fault>:
	TRAPHANDLER(page_fault, T_PGFLT) 
f0103f5c:	6a 0e                	push   $0xe
f0103f5e:	eb 0c                	jmp    f0103f6c <_alltraps>

f0103f60 <floating_point_error>:

	TRAPHANDLER_NOEC(floating_point_error, T_FPERR) 
f0103f60:	6a 00                	push   $0x0
f0103f62:	6a 10                	push   $0x10
f0103f64:	eb 06                	jmp    f0103f6c <_alltraps>

f0103f66 <system_call>:
	//x86手册9.10中没有说明aligment check && machine check
	//&& SIMD floating point error是否返回error code，故没写上
	TRAPHANDLER_NOEC(system_call, T_SYSCALL)
f0103f66:	6a 00                	push   $0x0
f0103f68:	6a 30                	push   $0x30
f0103f6a:	eb 00                	jmp    f0103f6c <_alltraps>

f0103f6c <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
f0103f6c:	1e                   	push   %ds
	pushl %es
f0103f6d:	06                   	push   %es
	pushal
f0103f6e:	60                   	pusha  

	mov $GD_KD,%eax
f0103f6f:	b8 10 00 00 00       	mov    $0x10,%eax
	mov %eax,%ds
f0103f74:	8e d8                	mov    %eax,%ds
	mov %eax,%es
f0103f76:	8e c0                	mov    %eax,%es
	
	pushl %esp  //压入trap()的参数tf，%esp指向Trapframe结构的起始地址
f0103f78:	54                   	push   %esp
	call trap
f0103f79:	e8 4c fd ff ff       	call   f0103cca <trap>

f0103f7e <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0103f7e:	55                   	push   %ebp
f0103f7f:	89 e5                	mov    %esp,%ebp
f0103f81:	83 ec 08             	sub    $0x8,%esp
f0103f84:	a1 48 a2 22 f0       	mov    0xf022a248,%eax
f0103f89:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103f8c:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0103f91:	8b 02                	mov    (%edx),%eax
f0103f93:	83 e8 01             	sub    $0x1,%eax
f0103f96:	83 f8 02             	cmp    $0x2,%eax
f0103f99:	76 10                	jbe    f0103fab <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103f9b:	83 c1 01             	add    $0x1,%ecx
f0103f9e:	83 c2 7c             	add    $0x7c,%edx
f0103fa1:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103fa7:	75 e8                	jne    f0103f91 <sched_halt+0x13>
f0103fa9:	eb 08                	jmp    f0103fb3 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0103fab:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103fb1:	75 1f                	jne    f0103fd2 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0103fb3:	83 ec 0c             	sub    $0xc,%esp
f0103fb6:	68 70 70 10 f0       	push   $0xf0107070
f0103fbb:	e8 d4 f6 ff ff       	call   f0103694 <cprintf>
f0103fc0:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0103fc3:	83 ec 0c             	sub    $0xc,%esp
f0103fc6:	6a 00                	push   $0x0
f0103fc8:	e8 34 c9 ff ff       	call   f0100901 <monitor>
f0103fcd:	83 c4 10             	add    $0x10,%esp
f0103fd0:	eb f1                	jmp    f0103fc3 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0103fd2:	e8 63 13 00 00       	call   f010533a <cpunum>
f0103fd7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fda:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103fe1:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0103fe4:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103fe9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103fee:	77 12                	ja     f0104002 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103ff0:	50                   	push   %eax
f0103ff1:	68 28 5a 10 f0       	push   $0xf0105a28
f0103ff6:	6a 4f                	push   $0x4f
f0103ff8:	68 99 70 10 f0       	push   $0xf0107099
f0103ffd:	e8 3e c0 ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0104002:	05 00 00 00 10       	add    $0x10000000,%eax
f0104007:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f010400a:	e8 2b 13 00 00       	call   f010533a <cpunum>
f010400f:	6b d0 74             	imul   $0x74,%eax,%edx
f0104012:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0104018:	b8 02 00 00 00       	mov    $0x2,%eax
f010401d:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0104021:	83 ec 0c             	sub    $0xc,%esp
f0104024:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0104029:	e8 17 16 00 00       	call   f0105645 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f010402e:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104030:	e8 05 13 00 00       	call   f010533a <cpunum>
f0104035:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f0104038:	8b 80 30 b0 22 f0    	mov    -0xfdd4fd0(%eax),%eax
f010403e:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104043:	89 c4                	mov    %eax,%esp
f0104045:	6a 00                	push   $0x0
f0104047:	6a 00                	push   $0x0
f0104049:	fb                   	sti    
f010404a:	f4                   	hlt    
f010404b:	eb fd                	jmp    f010404a <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f010404d:	83 c4 10             	add    $0x10,%esp
f0104050:	c9                   	leave  
f0104051:	c3                   	ret    

f0104052 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0104052:	55                   	push   %ebp
f0104053:	89 e5                	mov    %esp,%ebp
f0104055:	57                   	push   %edi
f0104056:	56                   	push   %esi
f0104057:	53                   	push   %ebx
f0104058:	83 ec 0c             	sub    $0xc,%esp
	// another CPU (env_status == ENV_RUNNING). If there are
	// no runnable environments, simply drop through to the code
	// below to halt the cpu.

	// LAB 4: Your code here.
	idle = thiscpu->cpu_env;
f010405b:	e8 da 12 00 00       	call   f010533a <cpunum>
f0104060:	6b c0 74             	imul   $0x74,%eax,%eax
f0104063:	8b 98 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%ebx
	int num = 0,index;
f0104069:	b9 00 00 00 00       	mov    $0x0,%ecx
	if(idle)
f010406e:	85 db                	test   %ebx,%ebx
f0104070:	74 14                	je     f0104086 <sched_yield+0x34>
		//num = ENVX(idle->env_id) + 1;
		num = curenv->env_id + 1;
f0104072:	e8 c3 12 00 00       	call   f010533a <cpunum>
f0104077:	6b c0 74             	imul   $0x74,%eax,%eax
f010407a:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104080:	8b 48 48             	mov    0x48(%eax),%ecx
f0104083:	83 c1 01             	add    $0x1,%ecx
	for(int i = 0;i < NENV;i++)
	{
		index = (num + i) % NENV;
		if(envs[index].env_status == ENV_RUNNABLE)
f0104086:	8b 35 48 a2 22 f0    	mov    0xf022a248,%esi
f010408c:	89 ca                	mov    %ecx,%edx
f010408e:	81 c1 00 04 00 00    	add    $0x400,%ecx
f0104094:	89 d7                	mov    %edx,%edi
f0104096:	c1 ff 1f             	sar    $0x1f,%edi
f0104099:	c1 ef 16             	shr    $0x16,%edi
f010409c:	8d 04 3a             	lea    (%edx,%edi,1),%eax
f010409f:	25 ff 03 00 00       	and    $0x3ff,%eax
f01040a4:	29 f8                	sub    %edi,%eax
f01040a6:	6b c0 7c             	imul   $0x7c,%eax,%eax
f01040a9:	01 f0                	add    %esi,%eax
f01040ab:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f01040af:	75 09                	jne    f01040ba <sched_yield+0x68>
		{
			env_run(&envs[index]);
f01040b1:	83 ec 0c             	sub    $0xc,%esp
f01040b4:	50                   	push   %eax
f01040b5:	e8 75 f3 ff ff       	call   f010342f <env_run>
f01040ba:	83 c2 01             	add    $0x1,%edx
	idle = thiscpu->cpu_env;
	int num = 0,index;
	if(idle)
		//num = ENVX(idle->env_id) + 1;
		num = curenv->env_id + 1;
	for(int i = 0;i < NENV;i++)
f01040bd:	39 ca                	cmp    %ecx,%edx
f01040bf:	75 d3                	jne    f0104094 <sched_yield+0x42>
		{
			env_run(&envs[index]);
			return;
		}
	}
	if(idle && idle->env_status == ENV_RUNNING)
f01040c1:	85 db                	test   %ebx,%ebx
f01040c3:	74 0f                	je     f01040d4 <sched_yield+0x82>
f01040c5:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01040c9:	75 09                	jne    f01040d4 <sched_yield+0x82>
	{
		env_run(idle);
f01040cb:	83 ec 0c             	sub    $0xc,%esp
f01040ce:	53                   	push   %ebx
f01040cf:	e8 5b f3 ff ff       	call   f010342f <env_run>
		return;
	}	
	//sched_halt never returns
	sched_halt();
f01040d4:	e8 a5 fe ff ff       	call   f0103f7e <sched_halt>
}
f01040d9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01040dc:	5b                   	pop    %ebx
f01040dd:	5e                   	pop    %esi
f01040de:	5f                   	pop    %edi
f01040df:	5d                   	pop    %ebp
f01040e0:	c3                   	ret    

f01040e1 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01040e1:	55                   	push   %ebp
f01040e2:	89 e5                	mov    %esp,%ebp
f01040e4:	53                   	push   %ebx
f01040e5:	83 ec 14             	sub    $0x14,%esp
f01040e8:	8b 45 08             	mov    0x8(%ebp),%eax
	// LAB 3: Your code here.

	//panic("syscall not implemented");
	int ret = 0;

	switch (syscallno) {
f01040eb:	83 f8 0a             	cmp    $0xa,%eax
f01040ee:	0f 87 f0 00 00 00    	ja     f01041e4 <syscall+0x103>
f01040f4:	ff 24 85 e0 70 10 f0 	jmp    *-0xfef8f20(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f01040fb:	e8 3a 12 00 00       	call   f010533a <cpunum>
f0104100:	6a 04                	push   $0x4
f0104102:	ff 75 10             	pushl  0x10(%ebp)
f0104105:	ff 75 0c             	pushl  0xc(%ebp)
f0104108:	6b c0 74             	imul   $0x74,%eax,%eax
f010410b:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0104111:	e8 f2 eb ff ff       	call   f0102d08 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104116:	83 c4 0c             	add    $0xc,%esp
f0104119:	ff 75 0c             	pushl  0xc(%ebp)
f010411c:	ff 75 10             	pushl  0x10(%ebp)
f010411f:	68 a6 70 10 f0       	push   $0xf01070a6
f0104124:	e8 6b f5 ff ff       	call   f0103694 <cprintf>
f0104129:	83 c4 10             	add    $0x10,%esp
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");
	int ret = 0;
f010412c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104131:	e9 b3 00 00 00       	jmp    f01041e9 <syscall+0x108>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0104136:	e8 ac c4 ff ff       	call   f01005e7 <cons_getc>
	case SYS_cputs:
		sys_cputs((const char*)a1,(size_t)a2);
		break;
	case SYS_cgetc:
		ret = sys_cgetc();
		break;
f010413b:	e9 a9 00 00 00       	jmp    f01041e9 <syscall+0x108>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104140:	83 ec 04             	sub    $0x4,%esp
f0104143:	6a 01                	push   $0x1
f0104145:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104148:	50                   	push   %eax
f0104149:	ff 75 0c             	pushl  0xc(%ebp)
f010414c:	e8 85 ec ff ff       	call   f0102dd6 <envid2env>
f0104151:	83 c4 10             	add    $0x10,%esp
f0104154:	85 c0                	test   %eax,%eax
f0104156:	0f 88 8d 00 00 00    	js     f01041e9 <syscall+0x108>
		return r;
	if (e == curenv)
f010415c:	e8 d9 11 00 00       	call   f010533a <cpunum>
f0104161:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104164:	6b c0 74             	imul   $0x74,%eax,%eax
f0104167:	39 90 28 b0 22 f0    	cmp    %edx,-0xfdd4fd8(%eax)
f010416d:	75 23                	jne    f0104192 <syscall+0xb1>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f010416f:	e8 c6 11 00 00       	call   f010533a <cpunum>
f0104174:	83 ec 08             	sub    $0x8,%esp
f0104177:	6b c0 74             	imul   $0x74,%eax,%eax
f010417a:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104180:	ff 70 48             	pushl  0x48(%eax)
f0104183:	68 ab 70 10 f0       	push   $0xf01070ab
f0104188:	e8 07 f5 ff ff       	call   f0103694 <cprintf>
f010418d:	83 c4 10             	add    $0x10,%esp
f0104190:	eb 25                	jmp    f01041b7 <syscall+0xd6>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104192:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104195:	e8 a0 11 00 00       	call   f010533a <cpunum>
f010419a:	83 ec 04             	sub    $0x4,%esp
f010419d:	53                   	push   %ebx
f010419e:	6b c0 74             	imul   $0x74,%eax,%eax
f01041a1:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01041a7:	ff 70 48             	pushl  0x48(%eax)
f01041aa:	68 c6 70 10 f0       	push   $0xf01070c6
f01041af:	e8 e0 f4 ff ff       	call   f0103694 <cprintf>
f01041b4:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01041b7:	83 ec 0c             	sub    $0xc,%esp
f01041ba:	ff 75 f4             	pushl  -0xc(%ebp)
f01041bd:	e8 ce f1 ff ff       	call   f0103390 <env_destroy>
f01041c2:	83 c4 10             	add    $0x10,%esp
	return 0;
f01041c5:	b8 00 00 00 00       	mov    $0x0,%eax
f01041ca:	eb 1d                	jmp    f01041e9 <syscall+0x108>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f01041cc:	e8 69 11 00 00       	call   f010533a <cpunum>
f01041d1:	6b c0 74             	imul   $0x74,%eax,%eax
f01041d4:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01041da:	8b 40 48             	mov    0x48(%eax),%eax
	case SYS_env_destroy:
		ret = sys_env_destroy((envid_t)a1);
		break;
	case SYS_getenvid:
		ret = sys_getenvid();
		break;
f01041dd:	eb 0a                	jmp    f01041e9 <syscall+0x108>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f01041df:	e8 6e fe ff ff       	call   f0104052 <sched_yield>
		break;
	case SYS_yield:
		sys_yield();
		break;
	default:
		return -E_NO_SYS;
f01041e4:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
	}
	return ret;
}
f01041e9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01041ec:	c9                   	leave  
f01041ed:	c3                   	ret    

f01041ee <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01041ee:	55                   	push   %ebp
f01041ef:	89 e5                	mov    %esp,%ebp
f01041f1:	57                   	push   %edi
f01041f2:	56                   	push   %esi
f01041f3:	53                   	push   %ebx
f01041f4:	83 ec 14             	sub    $0x14,%esp
f01041f7:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01041fa:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01041fd:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104200:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104203:	8b 1a                	mov    (%edx),%ebx
f0104205:	8b 01                	mov    (%ecx),%eax
f0104207:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010420a:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104211:	eb 7f                	jmp    f0104292 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0104213:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104216:	01 d8                	add    %ebx,%eax
f0104218:	89 c6                	mov    %eax,%esi
f010421a:	c1 ee 1f             	shr    $0x1f,%esi
f010421d:	01 c6                	add    %eax,%esi
f010421f:	d1 fe                	sar    %esi
f0104221:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104224:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104227:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010422a:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010422c:	eb 03                	jmp    f0104231 <stab_binsearch+0x43>
			m--;
f010422e:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104231:	39 c3                	cmp    %eax,%ebx
f0104233:	7f 0d                	jg     f0104242 <stab_binsearch+0x54>
f0104235:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104239:	83 ea 0c             	sub    $0xc,%edx
f010423c:	39 f9                	cmp    %edi,%ecx
f010423e:	75 ee                	jne    f010422e <stab_binsearch+0x40>
f0104240:	eb 05                	jmp    f0104247 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104242:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0104245:	eb 4b                	jmp    f0104292 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104247:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010424a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010424d:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104251:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104254:	76 11                	jbe    f0104267 <stab_binsearch+0x79>
			*region_left = m;
f0104256:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104259:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010425b:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010425e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104265:	eb 2b                	jmp    f0104292 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104267:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010426a:	73 14                	jae    f0104280 <stab_binsearch+0x92>
			*region_right = m - 1;
f010426c:	83 e8 01             	sub    $0x1,%eax
f010426f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104272:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104275:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104277:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010427e:	eb 12                	jmp    f0104292 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104280:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104283:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0104285:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104289:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010428b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104292:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104295:	0f 8e 78 ff ff ff    	jle    f0104213 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010429b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010429f:	75 0f                	jne    f01042b0 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01042a1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01042a4:	8b 00                	mov    (%eax),%eax
f01042a6:	83 e8 01             	sub    $0x1,%eax
f01042a9:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01042ac:	89 06                	mov    %eax,(%esi)
f01042ae:	eb 2c                	jmp    f01042dc <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01042b0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01042b3:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01042b5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01042b8:	8b 0e                	mov    (%esi),%ecx
f01042ba:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01042bd:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01042c0:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01042c3:	eb 03                	jmp    f01042c8 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01042c5:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01042c8:	39 c8                	cmp    %ecx,%eax
f01042ca:	7e 0b                	jle    f01042d7 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01042cc:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01042d0:	83 ea 0c             	sub    $0xc,%edx
f01042d3:	39 df                	cmp    %ebx,%edi
f01042d5:	75 ee                	jne    f01042c5 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01042d7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01042da:	89 06                	mov    %eax,(%esi)
	}
}
f01042dc:	83 c4 14             	add    $0x14,%esp
f01042df:	5b                   	pop    %ebx
f01042e0:	5e                   	pop    %esi
f01042e1:	5f                   	pop    %edi
f01042e2:	5d                   	pop    %ebp
f01042e3:	c3                   	ret    

f01042e4 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01042e4:	55                   	push   %ebp
f01042e5:	89 e5                	mov    %esp,%ebp
f01042e7:	57                   	push   %edi
f01042e8:	56                   	push   %esi
f01042e9:	53                   	push   %ebx
f01042ea:	83 ec 3c             	sub    $0x3c,%esp
f01042ed:	8b 7d 08             	mov    0x8(%ebp),%edi
f01042f0:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01042f3:	c7 06 0c 71 10 f0    	movl   $0xf010710c,(%esi)
	info->eip_line = 0;
f01042f9:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0104300:	c7 46 08 0c 71 10 f0 	movl   $0xf010710c,0x8(%esi)
	info->eip_fn_namelen = 9;
f0104307:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010430e:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0104311:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104318:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010431e:	0f 87 92 00 00 00    	ja     f01043b6 <debuginfo_eip+0xd2>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0)
f0104324:	e8 11 10 00 00       	call   f010533a <cpunum>
f0104329:	6a 04                	push   $0x4
f010432b:	6a 10                	push   $0x10
f010432d:	68 00 00 20 00       	push   $0x200000
f0104332:	6b c0 74             	imul   $0x74,%eax,%eax
f0104335:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f010433b:	e8 39 e9 ff ff       	call   f0102c79 <user_mem_check>
f0104340:	83 c4 10             	add    $0x10,%esp
f0104343:	85 c0                	test   %eax,%eax
f0104345:	0f 85 01 02 00 00    	jne    f010454c <debuginfo_eip+0x268>
			return -1;
		stabs = usd->stabs;
f010434b:	a1 00 00 20 00       	mov    0x200000,%eax
f0104350:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f0104353:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f0104359:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f010435f:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f0104362:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0104368:	89 55 d0             	mov    %edx,-0x30(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, sizeof(struct UserStabData), PTE_U) != 0)
f010436b:	e8 ca 0f 00 00       	call   f010533a <cpunum>
f0104370:	6a 04                	push   $0x4
f0104372:	6a 10                	push   $0x10
f0104374:	ff 75 d4             	pushl  -0x2c(%ebp)
f0104377:	6b c0 74             	imul   $0x74,%eax,%eax
f010437a:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0104380:	e8 f4 e8 ff ff       	call   f0102c79 <user_mem_check>
f0104385:	83 c4 10             	add    $0x10,%esp
f0104388:	85 c0                	test   %eax,%eax
f010438a:	0f 85 c3 01 00 00    	jne    f0104553 <debuginfo_eip+0x26f>
			return -1;
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
f0104390:	e8 a5 0f 00 00       	call   f010533a <cpunum>
f0104395:	6a 04                	push   $0x4
f0104397:	6a 10                	push   $0x10
f0104399:	ff 75 cc             	pushl  -0x34(%ebp)
f010439c:	6b c0 74             	imul   $0x74,%eax,%eax
f010439f:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f01043a5:	e8 cf e8 ff ff       	call   f0102c79 <user_mem_check>
f01043aa:	83 c4 10             	add    $0x10,%esp
f01043ad:	85 c0                	test   %eax,%eax
f01043af:	74 1f                	je     f01043d0 <debuginfo_eip+0xec>
f01043b1:	e9 a4 01 00 00       	jmp    f010455a <debuginfo_eip+0x276>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01043b6:	c7 45 d0 aa 43 11 f0 	movl   $0xf01143aa,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01043bd:	c7 45 cc c1 0d 11 f0 	movl   $0xf0110dc1,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01043c4:	bb c0 0d 11 f0       	mov    $0xf0110dc0,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01043c9:	c7 45 d4 f8 75 10 f0 	movl   $0xf01075f8,-0x2c(%ebp)
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01043d0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01043d3:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01043d6:	0f 83 85 01 00 00    	jae    f0104561 <debuginfo_eip+0x27d>
f01043dc:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01043e0:	0f 85 82 01 00 00    	jne    f0104568 <debuginfo_eip+0x284>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01043e6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01043ed:	2b 5d d4             	sub    -0x2c(%ebp),%ebx
f01043f0:	c1 fb 02             	sar    $0x2,%ebx
f01043f3:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f01043f9:	83 e8 01             	sub    $0x1,%eax
f01043fc:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01043ff:	83 ec 08             	sub    $0x8,%esp
f0104402:	57                   	push   %edi
f0104403:	6a 64                	push   $0x64
f0104405:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0104408:	89 d1                	mov    %edx,%ecx
f010440a:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010440d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104410:	89 d8                	mov    %ebx,%eax
f0104412:	e8 d7 fd ff ff       	call   f01041ee <stab_binsearch>
	if (lfile == 0)
f0104417:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010441a:	83 c4 10             	add    $0x10,%esp
f010441d:	85 c0                	test   %eax,%eax
f010441f:	0f 84 4a 01 00 00    	je     f010456f <debuginfo_eip+0x28b>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104425:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104428:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010442b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010442e:	83 ec 08             	sub    $0x8,%esp
f0104431:	57                   	push   %edi
f0104432:	6a 24                	push   $0x24
f0104434:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0104437:	89 d1                	mov    %edx,%ecx
f0104439:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010443c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f010443f:	89 d8                	mov    %ebx,%eax
f0104441:	e8 a8 fd ff ff       	call   f01041ee <stab_binsearch>

	if (lfun <= rfun) {
f0104446:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104449:	83 c4 10             	add    $0x10,%esp
f010444c:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010444f:	7f 25                	jg     f0104476 <debuginfo_eip+0x192>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104451:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104454:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104457:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010445a:	8b 02                	mov    (%edx),%eax
f010445c:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010445f:	2b 4d cc             	sub    -0x34(%ebp),%ecx
f0104462:	39 c8                	cmp    %ecx,%eax
f0104464:	73 06                	jae    f010446c <debuginfo_eip+0x188>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104466:	03 45 cc             	add    -0x34(%ebp),%eax
f0104469:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010446c:	8b 42 08             	mov    0x8(%edx),%eax
f010446f:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f0104472:	29 c7                	sub    %eax,%edi
f0104474:	eb 06                	jmp    f010447c <debuginfo_eip+0x198>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104476:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0104479:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010447c:	83 ec 08             	sub    $0x8,%esp
f010447f:	6a 3a                	push   $0x3a
f0104481:	ff 76 08             	pushl  0x8(%esi)
f0104484:	e8 74 08 00 00       	call   f0104cfd <strfind>
f0104489:	2b 46 08             	sub    0x8(%esi),%eax
f010448c:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
f010448f:	83 c4 08             	add    $0x8,%esp
f0104492:	2b 7e 10             	sub    0x10(%esi),%edi
f0104495:	57                   	push   %edi
f0104496:	6a 44                	push   $0x44
f0104498:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010449b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010449e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01044a1:	89 f8                	mov    %edi,%eax
f01044a3:	e8 46 fd ff ff       	call   f01041ee <stab_binsearch>
	if (lfun > rfun) 
f01044a8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01044ab:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01044ae:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01044b1:	83 c4 10             	add    $0x10,%esp
f01044b4:	39 c8                	cmp    %ecx,%eax
f01044b6:	0f 8f ba 00 00 00    	jg     f0104576 <debuginfo_eip+0x292>
       	  return -1;
        info->eip_line = stabs[lfun].n_desc;
f01044bc:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01044bf:	89 fa                	mov    %edi,%edx
f01044c1:	8d 04 87             	lea    (%edi,%eax,4),%eax
f01044c4:	89 45 c0             	mov    %eax,-0x40(%ebp)
f01044c7:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f01044cb:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01044ce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01044d1:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01044d4:	8d 04 82             	lea    (%edx,%eax,4),%eax
f01044d7:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f01044da:	eb 06                	jmp    f01044e2 <debuginfo_eip+0x1fe>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01044dc:	83 eb 01             	sub    $0x1,%ebx
f01044df:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01044e2:	39 fb                	cmp    %edi,%ebx
f01044e4:	7c 32                	jl     f0104518 <debuginfo_eip+0x234>
	       && stabs[lline].n_type != N_SOL
f01044e6:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01044ea:	80 fa 84             	cmp    $0x84,%dl
f01044ed:	74 0b                	je     f01044fa <debuginfo_eip+0x216>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01044ef:	80 fa 64             	cmp    $0x64,%dl
f01044f2:	75 e8                	jne    f01044dc <debuginfo_eip+0x1f8>
f01044f4:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01044f8:	74 e2                	je     f01044dc <debuginfo_eip+0x1f8>
f01044fa:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01044fd:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104500:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104503:	8b 04 87             	mov    (%edi,%eax,4),%eax
f0104506:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0104509:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010450c:	29 fa                	sub    %edi,%edx
f010450e:	39 d0                	cmp    %edx,%eax
f0104510:	73 09                	jae    f010451b <debuginfo_eip+0x237>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104512:	01 f8                	add    %edi,%eax
f0104514:	89 06                	mov    %eax,(%esi)
f0104516:	eb 03                	jmp    f010451b <debuginfo_eip+0x237>
f0104518:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010451b:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104520:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0104523:	39 cf                	cmp    %ecx,%edi
f0104525:	7d 5b                	jge    f0104582 <debuginfo_eip+0x29e>
		for (lline = lfun + 1;
f0104527:	89 f8                	mov    %edi,%eax
f0104529:	83 c0 01             	add    $0x1,%eax
f010452c:	8b 55 c0             	mov    -0x40(%ebp),%edx
f010452f:	eb 07                	jmp    f0104538 <debuginfo_eip+0x254>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104531:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0104535:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104538:	39 c8                	cmp    %ecx,%eax
f010453a:	74 41                	je     f010457d <debuginfo_eip+0x299>
f010453c:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010453f:	80 7a 04 a0          	cmpb   $0xa0,0x4(%edx)
f0104543:	74 ec                	je     f0104531 <debuginfo_eip+0x24d>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104545:	b8 00 00 00 00       	mov    $0x0,%eax
f010454a:	eb 36                	jmp    f0104582 <debuginfo_eip+0x29e>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f010454c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104551:	eb 2f                	jmp    f0104582 <debuginfo_eip+0x29e>
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f0104553:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104558:	eb 28                	jmp    f0104582 <debuginfo_eip+0x29e>
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f010455a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010455f:	eb 21                	jmp    f0104582 <debuginfo_eip+0x29e>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104561:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104566:	eb 1a                	jmp    f0104582 <debuginfo_eip+0x29e>
f0104568:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010456d:	eb 13                	jmp    f0104582 <debuginfo_eip+0x29e>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f010456f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104574:	eb 0c                	jmp    f0104582 <debuginfo_eip+0x29e>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
	if (lfun > rfun) 
       	  return -1;
f0104576:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010457b:	eb 05                	jmp    f0104582 <debuginfo_eip+0x29e>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010457d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104582:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104585:	5b                   	pop    %ebx
f0104586:	5e                   	pop    %esi
f0104587:	5f                   	pop    %edi
f0104588:	5d                   	pop    %ebp
f0104589:	c3                   	ret    

f010458a <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010458a:	55                   	push   %ebp
f010458b:	89 e5                	mov    %esp,%ebp
f010458d:	57                   	push   %edi
f010458e:	56                   	push   %esi
f010458f:	53                   	push   %ebx
f0104590:	83 ec 1c             	sub    $0x1c,%esp
f0104593:	89 c7                	mov    %eax,%edi
f0104595:	89 d6                	mov    %edx,%esi
f0104597:	8b 45 08             	mov    0x8(%ebp),%eax
f010459a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010459d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01045a0:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01045a3:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01045a6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01045ab:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01045ae:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01045b1:	39 d3                	cmp    %edx,%ebx
f01045b3:	72 05                	jb     f01045ba <printnum+0x30>
f01045b5:	39 45 10             	cmp    %eax,0x10(%ebp)
f01045b8:	77 45                	ja     f01045ff <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01045ba:	83 ec 0c             	sub    $0xc,%esp
f01045bd:	ff 75 18             	pushl  0x18(%ebp)
f01045c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01045c3:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01045c6:	53                   	push   %ebx
f01045c7:	ff 75 10             	pushl  0x10(%ebp)
f01045ca:	83 ec 08             	sub    $0x8,%esp
f01045cd:	ff 75 e4             	pushl  -0x1c(%ebp)
f01045d0:	ff 75 e0             	pushl  -0x20(%ebp)
f01045d3:	ff 75 dc             	pushl  -0x24(%ebp)
f01045d6:	ff 75 d8             	pushl  -0x28(%ebp)
f01045d9:	e8 62 11 00 00       	call   f0105740 <__udivdi3>
f01045de:	83 c4 18             	add    $0x18,%esp
f01045e1:	52                   	push   %edx
f01045e2:	50                   	push   %eax
f01045e3:	89 f2                	mov    %esi,%edx
f01045e5:	89 f8                	mov    %edi,%eax
f01045e7:	e8 9e ff ff ff       	call   f010458a <printnum>
f01045ec:	83 c4 20             	add    $0x20,%esp
f01045ef:	eb 18                	jmp    f0104609 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01045f1:	83 ec 08             	sub    $0x8,%esp
f01045f4:	56                   	push   %esi
f01045f5:	ff 75 18             	pushl  0x18(%ebp)
f01045f8:	ff d7                	call   *%edi
f01045fa:	83 c4 10             	add    $0x10,%esp
f01045fd:	eb 03                	jmp    f0104602 <printnum+0x78>
f01045ff:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104602:	83 eb 01             	sub    $0x1,%ebx
f0104605:	85 db                	test   %ebx,%ebx
f0104607:	7f e8                	jg     f01045f1 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104609:	83 ec 08             	sub    $0x8,%esp
f010460c:	56                   	push   %esi
f010460d:	83 ec 04             	sub    $0x4,%esp
f0104610:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104613:	ff 75 e0             	pushl  -0x20(%ebp)
f0104616:	ff 75 dc             	pushl  -0x24(%ebp)
f0104619:	ff 75 d8             	pushl  -0x28(%ebp)
f010461c:	e8 4f 12 00 00       	call   f0105870 <__umoddi3>
f0104621:	83 c4 14             	add    $0x14,%esp
f0104624:	0f be 80 16 71 10 f0 	movsbl -0xfef8eea(%eax),%eax
f010462b:	50                   	push   %eax
f010462c:	ff d7                	call   *%edi
}
f010462e:	83 c4 10             	add    $0x10,%esp
f0104631:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104634:	5b                   	pop    %ebx
f0104635:	5e                   	pop    %esi
f0104636:	5f                   	pop    %edi
f0104637:	5d                   	pop    %ebp
f0104638:	c3                   	ret    

f0104639 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104639:	55                   	push   %ebp
f010463a:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010463c:	83 fa 01             	cmp    $0x1,%edx
f010463f:	7e 0e                	jle    f010464f <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104641:	8b 10                	mov    (%eax),%edx
f0104643:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104646:	89 08                	mov    %ecx,(%eax)
f0104648:	8b 02                	mov    (%edx),%eax
f010464a:	8b 52 04             	mov    0x4(%edx),%edx
f010464d:	eb 22                	jmp    f0104671 <getuint+0x38>
	else if (lflag)
f010464f:	85 d2                	test   %edx,%edx
f0104651:	74 10                	je     f0104663 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104653:	8b 10                	mov    (%eax),%edx
f0104655:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104658:	89 08                	mov    %ecx,(%eax)
f010465a:	8b 02                	mov    (%edx),%eax
f010465c:	ba 00 00 00 00       	mov    $0x0,%edx
f0104661:	eb 0e                	jmp    f0104671 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104663:	8b 10                	mov    (%eax),%edx
f0104665:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104668:	89 08                	mov    %ecx,(%eax)
f010466a:	8b 02                	mov    (%edx),%eax
f010466c:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104671:	5d                   	pop    %ebp
f0104672:	c3                   	ret    

f0104673 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104673:	55                   	push   %ebp
f0104674:	89 e5                	mov    %esp,%ebp
f0104676:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104679:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010467d:	8b 10                	mov    (%eax),%edx
f010467f:	3b 50 04             	cmp    0x4(%eax),%edx
f0104682:	73 0a                	jae    f010468e <sprintputch+0x1b>
		*b->buf++ = ch;
f0104684:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104687:	89 08                	mov    %ecx,(%eax)
f0104689:	8b 45 08             	mov    0x8(%ebp),%eax
f010468c:	88 02                	mov    %al,(%edx)
}
f010468e:	5d                   	pop    %ebp
f010468f:	c3                   	ret    

f0104690 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104690:	55                   	push   %ebp
f0104691:	89 e5                	mov    %esp,%ebp
f0104693:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104696:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104699:	50                   	push   %eax
f010469a:	ff 75 10             	pushl  0x10(%ebp)
f010469d:	ff 75 0c             	pushl  0xc(%ebp)
f01046a0:	ff 75 08             	pushl  0x8(%ebp)
f01046a3:	e8 05 00 00 00       	call   f01046ad <vprintfmt>
	va_end(ap);
}
f01046a8:	83 c4 10             	add    $0x10,%esp
f01046ab:	c9                   	leave  
f01046ac:	c3                   	ret    

f01046ad <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01046ad:	55                   	push   %ebp
f01046ae:	89 e5                	mov    %esp,%ebp
f01046b0:	57                   	push   %edi
f01046b1:	56                   	push   %esi
f01046b2:	53                   	push   %ebx
f01046b3:	83 ec 2c             	sub    $0x2c,%esp
f01046b6:	8b 75 08             	mov    0x8(%ebp),%esi
f01046b9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01046bc:	8b 7d 10             	mov    0x10(%ebp),%edi
f01046bf:	eb 12                	jmp    f01046d3 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01046c1:	85 c0                	test   %eax,%eax
f01046c3:	0f 84 89 03 00 00    	je     f0104a52 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f01046c9:	83 ec 08             	sub    $0x8,%esp
f01046cc:	53                   	push   %ebx
f01046cd:	50                   	push   %eax
f01046ce:	ff d6                	call   *%esi
f01046d0:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01046d3:	83 c7 01             	add    $0x1,%edi
f01046d6:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01046da:	83 f8 25             	cmp    $0x25,%eax
f01046dd:	75 e2                	jne    f01046c1 <vprintfmt+0x14>
f01046df:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01046e3:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01046ea:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01046f1:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01046f8:	ba 00 00 00 00       	mov    $0x0,%edx
f01046fd:	eb 07                	jmp    f0104706 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046ff:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104702:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104706:	8d 47 01             	lea    0x1(%edi),%eax
f0104709:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010470c:	0f b6 07             	movzbl (%edi),%eax
f010470f:	0f b6 c8             	movzbl %al,%ecx
f0104712:	83 e8 23             	sub    $0x23,%eax
f0104715:	3c 55                	cmp    $0x55,%al
f0104717:	0f 87 1a 03 00 00    	ja     f0104a37 <vprintfmt+0x38a>
f010471d:	0f b6 c0             	movzbl %al,%eax
f0104720:	ff 24 85 e0 71 10 f0 	jmp    *-0xfef8e20(,%eax,4)
f0104727:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010472a:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010472e:	eb d6                	jmp    f0104706 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104730:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104733:	b8 00 00 00 00       	mov    $0x0,%eax
f0104738:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010473b:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010473e:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0104742:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104745:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104748:	83 fa 09             	cmp    $0x9,%edx
f010474b:	77 39                	ja     f0104786 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010474d:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104750:	eb e9                	jmp    f010473b <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104752:	8b 45 14             	mov    0x14(%ebp),%eax
f0104755:	8d 48 04             	lea    0x4(%eax),%ecx
f0104758:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010475b:	8b 00                	mov    (%eax),%eax
f010475d:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104760:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104763:	eb 27                	jmp    f010478c <vprintfmt+0xdf>
f0104765:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104768:	85 c0                	test   %eax,%eax
f010476a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010476f:	0f 49 c8             	cmovns %eax,%ecx
f0104772:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104775:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104778:	eb 8c                	jmp    f0104706 <vprintfmt+0x59>
f010477a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010477d:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104784:	eb 80                	jmp    f0104706 <vprintfmt+0x59>
f0104786:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104789:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f010478c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104790:	0f 89 70 ff ff ff    	jns    f0104706 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104796:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104799:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010479c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01047a3:	e9 5e ff ff ff       	jmp    f0104706 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01047a8:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01047ab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01047ae:	e9 53 ff ff ff       	jmp    f0104706 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01047b3:	8b 45 14             	mov    0x14(%ebp),%eax
f01047b6:	8d 50 04             	lea    0x4(%eax),%edx
f01047b9:	89 55 14             	mov    %edx,0x14(%ebp)
f01047bc:	83 ec 08             	sub    $0x8,%esp
f01047bf:	53                   	push   %ebx
f01047c0:	ff 30                	pushl  (%eax)
f01047c2:	ff d6                	call   *%esi
			break;
f01047c4:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01047c7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01047ca:	e9 04 ff ff ff       	jmp    f01046d3 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01047cf:	8b 45 14             	mov    0x14(%ebp),%eax
f01047d2:	8d 50 04             	lea    0x4(%eax),%edx
f01047d5:	89 55 14             	mov    %edx,0x14(%ebp)
f01047d8:	8b 00                	mov    (%eax),%eax
f01047da:	99                   	cltd   
f01047db:	31 d0                	xor    %edx,%eax
f01047dd:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01047df:	83 f8 09             	cmp    $0x9,%eax
f01047e2:	7f 0b                	jg     f01047ef <vprintfmt+0x142>
f01047e4:	8b 14 85 40 73 10 f0 	mov    -0xfef8cc0(,%eax,4),%edx
f01047eb:	85 d2                	test   %edx,%edx
f01047ed:	75 18                	jne    f0104807 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f01047ef:	50                   	push   %eax
f01047f0:	68 2e 71 10 f0       	push   $0xf010712e
f01047f5:	53                   	push   %ebx
f01047f6:	56                   	push   %esi
f01047f7:	e8 94 fe ff ff       	call   f0104690 <printfmt>
f01047fc:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01047ff:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104802:	e9 cc fe ff ff       	jmp    f01046d3 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104807:	52                   	push   %edx
f0104808:	68 d9 68 10 f0       	push   $0xf01068d9
f010480d:	53                   	push   %ebx
f010480e:	56                   	push   %esi
f010480f:	e8 7c fe ff ff       	call   f0104690 <printfmt>
f0104814:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104817:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010481a:	e9 b4 fe ff ff       	jmp    f01046d3 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010481f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104822:	8d 50 04             	lea    0x4(%eax),%edx
f0104825:	89 55 14             	mov    %edx,0x14(%ebp)
f0104828:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010482a:	85 ff                	test   %edi,%edi
f010482c:	b8 27 71 10 f0       	mov    $0xf0107127,%eax
f0104831:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104834:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104838:	0f 8e 94 00 00 00    	jle    f01048d2 <vprintfmt+0x225>
f010483e:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104842:	0f 84 98 00 00 00    	je     f01048e0 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104848:	83 ec 08             	sub    $0x8,%esp
f010484b:	ff 75 d0             	pushl  -0x30(%ebp)
f010484e:	57                   	push   %edi
f010484f:	e8 5f 03 00 00       	call   f0104bb3 <strnlen>
f0104854:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104857:	29 c1                	sub    %eax,%ecx
f0104859:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f010485c:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010485f:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104863:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104866:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104869:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010486b:	eb 0f                	jmp    f010487c <vprintfmt+0x1cf>
					putch(padc, putdat);
f010486d:	83 ec 08             	sub    $0x8,%esp
f0104870:	53                   	push   %ebx
f0104871:	ff 75 e0             	pushl  -0x20(%ebp)
f0104874:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104876:	83 ef 01             	sub    $0x1,%edi
f0104879:	83 c4 10             	add    $0x10,%esp
f010487c:	85 ff                	test   %edi,%edi
f010487e:	7f ed                	jg     f010486d <vprintfmt+0x1c0>
f0104880:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104883:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104886:	85 c9                	test   %ecx,%ecx
f0104888:	b8 00 00 00 00       	mov    $0x0,%eax
f010488d:	0f 49 c1             	cmovns %ecx,%eax
f0104890:	29 c1                	sub    %eax,%ecx
f0104892:	89 75 08             	mov    %esi,0x8(%ebp)
f0104895:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104898:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010489b:	89 cb                	mov    %ecx,%ebx
f010489d:	eb 4d                	jmp    f01048ec <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010489f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01048a3:	74 1b                	je     f01048c0 <vprintfmt+0x213>
f01048a5:	0f be c0             	movsbl %al,%eax
f01048a8:	83 e8 20             	sub    $0x20,%eax
f01048ab:	83 f8 5e             	cmp    $0x5e,%eax
f01048ae:	76 10                	jbe    f01048c0 <vprintfmt+0x213>
					putch('?', putdat);
f01048b0:	83 ec 08             	sub    $0x8,%esp
f01048b3:	ff 75 0c             	pushl  0xc(%ebp)
f01048b6:	6a 3f                	push   $0x3f
f01048b8:	ff 55 08             	call   *0x8(%ebp)
f01048bb:	83 c4 10             	add    $0x10,%esp
f01048be:	eb 0d                	jmp    f01048cd <vprintfmt+0x220>
				else
					putch(ch, putdat);
f01048c0:	83 ec 08             	sub    $0x8,%esp
f01048c3:	ff 75 0c             	pushl  0xc(%ebp)
f01048c6:	52                   	push   %edx
f01048c7:	ff 55 08             	call   *0x8(%ebp)
f01048ca:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01048cd:	83 eb 01             	sub    $0x1,%ebx
f01048d0:	eb 1a                	jmp    f01048ec <vprintfmt+0x23f>
f01048d2:	89 75 08             	mov    %esi,0x8(%ebp)
f01048d5:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01048d8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01048db:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01048de:	eb 0c                	jmp    f01048ec <vprintfmt+0x23f>
f01048e0:	89 75 08             	mov    %esi,0x8(%ebp)
f01048e3:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01048e6:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01048e9:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01048ec:	83 c7 01             	add    $0x1,%edi
f01048ef:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01048f3:	0f be d0             	movsbl %al,%edx
f01048f6:	85 d2                	test   %edx,%edx
f01048f8:	74 23                	je     f010491d <vprintfmt+0x270>
f01048fa:	85 f6                	test   %esi,%esi
f01048fc:	78 a1                	js     f010489f <vprintfmt+0x1f2>
f01048fe:	83 ee 01             	sub    $0x1,%esi
f0104901:	79 9c                	jns    f010489f <vprintfmt+0x1f2>
f0104903:	89 df                	mov    %ebx,%edi
f0104905:	8b 75 08             	mov    0x8(%ebp),%esi
f0104908:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010490b:	eb 18                	jmp    f0104925 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010490d:	83 ec 08             	sub    $0x8,%esp
f0104910:	53                   	push   %ebx
f0104911:	6a 20                	push   $0x20
f0104913:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104915:	83 ef 01             	sub    $0x1,%edi
f0104918:	83 c4 10             	add    $0x10,%esp
f010491b:	eb 08                	jmp    f0104925 <vprintfmt+0x278>
f010491d:	89 df                	mov    %ebx,%edi
f010491f:	8b 75 08             	mov    0x8(%ebp),%esi
f0104922:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104925:	85 ff                	test   %edi,%edi
f0104927:	7f e4                	jg     f010490d <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104929:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010492c:	e9 a2 fd ff ff       	jmp    f01046d3 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104931:	83 fa 01             	cmp    $0x1,%edx
f0104934:	7e 16                	jle    f010494c <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0104936:	8b 45 14             	mov    0x14(%ebp),%eax
f0104939:	8d 50 08             	lea    0x8(%eax),%edx
f010493c:	89 55 14             	mov    %edx,0x14(%ebp)
f010493f:	8b 50 04             	mov    0x4(%eax),%edx
f0104942:	8b 00                	mov    (%eax),%eax
f0104944:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104947:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010494a:	eb 32                	jmp    f010497e <vprintfmt+0x2d1>
	else if (lflag)
f010494c:	85 d2                	test   %edx,%edx
f010494e:	74 18                	je     f0104968 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0104950:	8b 45 14             	mov    0x14(%ebp),%eax
f0104953:	8d 50 04             	lea    0x4(%eax),%edx
f0104956:	89 55 14             	mov    %edx,0x14(%ebp)
f0104959:	8b 00                	mov    (%eax),%eax
f010495b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010495e:	89 c1                	mov    %eax,%ecx
f0104960:	c1 f9 1f             	sar    $0x1f,%ecx
f0104963:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104966:	eb 16                	jmp    f010497e <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0104968:	8b 45 14             	mov    0x14(%ebp),%eax
f010496b:	8d 50 04             	lea    0x4(%eax),%edx
f010496e:	89 55 14             	mov    %edx,0x14(%ebp)
f0104971:	8b 00                	mov    (%eax),%eax
f0104973:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104976:	89 c1                	mov    %eax,%ecx
f0104978:	c1 f9 1f             	sar    $0x1f,%ecx
f010497b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010497e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104981:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104984:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104989:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010498d:	79 74                	jns    f0104a03 <vprintfmt+0x356>
				putch('-', putdat);
f010498f:	83 ec 08             	sub    $0x8,%esp
f0104992:	53                   	push   %ebx
f0104993:	6a 2d                	push   $0x2d
f0104995:	ff d6                	call   *%esi
				num = -(long long) num;
f0104997:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010499a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010499d:	f7 d8                	neg    %eax
f010499f:	83 d2 00             	adc    $0x0,%edx
f01049a2:	f7 da                	neg    %edx
f01049a4:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01049a7:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01049ac:	eb 55                	jmp    f0104a03 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01049ae:	8d 45 14             	lea    0x14(%ebp),%eax
f01049b1:	e8 83 fc ff ff       	call   f0104639 <getuint>
			base = 10;
f01049b6:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01049bb:	eb 46                	jmp    f0104a03 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01049bd:	8d 45 14             	lea    0x14(%ebp),%eax
f01049c0:	e8 74 fc ff ff       	call   f0104639 <getuint>
			base = 8;
f01049c5:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01049ca:	eb 37                	jmp    f0104a03 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f01049cc:	83 ec 08             	sub    $0x8,%esp
f01049cf:	53                   	push   %ebx
f01049d0:	6a 30                	push   $0x30
f01049d2:	ff d6                	call   *%esi
			putch('x', putdat);
f01049d4:	83 c4 08             	add    $0x8,%esp
f01049d7:	53                   	push   %ebx
f01049d8:	6a 78                	push   $0x78
f01049da:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01049dc:	8b 45 14             	mov    0x14(%ebp),%eax
f01049df:	8d 50 04             	lea    0x4(%eax),%edx
f01049e2:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01049e5:	8b 00                	mov    (%eax),%eax
f01049e7:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01049ec:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01049ef:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01049f4:	eb 0d                	jmp    f0104a03 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01049f6:	8d 45 14             	lea    0x14(%ebp),%eax
f01049f9:	e8 3b fc ff ff       	call   f0104639 <getuint>
			base = 16;
f01049fe:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104a03:	83 ec 0c             	sub    $0xc,%esp
f0104a06:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104a0a:	57                   	push   %edi
f0104a0b:	ff 75 e0             	pushl  -0x20(%ebp)
f0104a0e:	51                   	push   %ecx
f0104a0f:	52                   	push   %edx
f0104a10:	50                   	push   %eax
f0104a11:	89 da                	mov    %ebx,%edx
f0104a13:	89 f0                	mov    %esi,%eax
f0104a15:	e8 70 fb ff ff       	call   f010458a <printnum>
			break;
f0104a1a:	83 c4 20             	add    $0x20,%esp
f0104a1d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104a20:	e9 ae fc ff ff       	jmp    f01046d3 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104a25:	83 ec 08             	sub    $0x8,%esp
f0104a28:	53                   	push   %ebx
f0104a29:	51                   	push   %ecx
f0104a2a:	ff d6                	call   *%esi
			break;
f0104a2c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104a2f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104a32:	e9 9c fc ff ff       	jmp    f01046d3 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104a37:	83 ec 08             	sub    $0x8,%esp
f0104a3a:	53                   	push   %ebx
f0104a3b:	6a 25                	push   $0x25
f0104a3d:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104a3f:	83 c4 10             	add    $0x10,%esp
f0104a42:	eb 03                	jmp    f0104a47 <vprintfmt+0x39a>
f0104a44:	83 ef 01             	sub    $0x1,%edi
f0104a47:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104a4b:	75 f7                	jne    f0104a44 <vprintfmt+0x397>
f0104a4d:	e9 81 fc ff ff       	jmp    f01046d3 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0104a52:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104a55:	5b                   	pop    %ebx
f0104a56:	5e                   	pop    %esi
f0104a57:	5f                   	pop    %edi
f0104a58:	5d                   	pop    %ebp
f0104a59:	c3                   	ret    

f0104a5a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104a5a:	55                   	push   %ebp
f0104a5b:	89 e5                	mov    %esp,%ebp
f0104a5d:	83 ec 18             	sub    $0x18,%esp
f0104a60:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a63:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104a66:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104a69:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104a6d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104a70:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104a77:	85 c0                	test   %eax,%eax
f0104a79:	74 26                	je     f0104aa1 <vsnprintf+0x47>
f0104a7b:	85 d2                	test   %edx,%edx
f0104a7d:	7e 22                	jle    f0104aa1 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104a7f:	ff 75 14             	pushl  0x14(%ebp)
f0104a82:	ff 75 10             	pushl  0x10(%ebp)
f0104a85:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104a88:	50                   	push   %eax
f0104a89:	68 73 46 10 f0       	push   $0xf0104673
f0104a8e:	e8 1a fc ff ff       	call   f01046ad <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104a93:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104a96:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104a99:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104a9c:	83 c4 10             	add    $0x10,%esp
f0104a9f:	eb 05                	jmp    f0104aa6 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104aa1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104aa6:	c9                   	leave  
f0104aa7:	c3                   	ret    

f0104aa8 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104aa8:	55                   	push   %ebp
f0104aa9:	89 e5                	mov    %esp,%ebp
f0104aab:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104aae:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104ab1:	50                   	push   %eax
f0104ab2:	ff 75 10             	pushl  0x10(%ebp)
f0104ab5:	ff 75 0c             	pushl  0xc(%ebp)
f0104ab8:	ff 75 08             	pushl  0x8(%ebp)
f0104abb:	e8 9a ff ff ff       	call   f0104a5a <vsnprintf>
	va_end(ap);

	return rc;
}
f0104ac0:	c9                   	leave  
f0104ac1:	c3                   	ret    

f0104ac2 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104ac2:	55                   	push   %ebp
f0104ac3:	89 e5                	mov    %esp,%ebp
f0104ac5:	57                   	push   %edi
f0104ac6:	56                   	push   %esi
f0104ac7:	53                   	push   %ebx
f0104ac8:	83 ec 0c             	sub    $0xc,%esp
f0104acb:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104ace:	85 c0                	test   %eax,%eax
f0104ad0:	74 11                	je     f0104ae3 <readline+0x21>
		cprintf("%s", prompt);
f0104ad2:	83 ec 08             	sub    $0x8,%esp
f0104ad5:	50                   	push   %eax
f0104ad6:	68 d9 68 10 f0       	push   $0xf01068d9
f0104adb:	e8 b4 eb ff ff       	call   f0103694 <cprintf>
f0104ae0:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104ae3:	83 ec 0c             	sub    $0xc,%esp
f0104ae6:	6a 00                	push   $0x0
f0104ae8:	e8 8a bc ff ff       	call   f0100777 <iscons>
f0104aed:	89 c7                	mov    %eax,%edi
f0104aef:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104af2:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104af7:	e8 6a bc ff ff       	call   f0100766 <getchar>
f0104afc:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104afe:	85 c0                	test   %eax,%eax
f0104b00:	79 18                	jns    f0104b1a <readline+0x58>
			cprintf("read error: %e\n", c);
f0104b02:	83 ec 08             	sub    $0x8,%esp
f0104b05:	50                   	push   %eax
f0104b06:	68 68 73 10 f0       	push   $0xf0107368
f0104b0b:	e8 84 eb ff ff       	call   f0103694 <cprintf>
			return NULL;
f0104b10:	83 c4 10             	add    $0x10,%esp
f0104b13:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b18:	eb 79                	jmp    f0104b93 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104b1a:	83 f8 08             	cmp    $0x8,%eax
f0104b1d:	0f 94 c2             	sete   %dl
f0104b20:	83 f8 7f             	cmp    $0x7f,%eax
f0104b23:	0f 94 c0             	sete   %al
f0104b26:	08 c2                	or     %al,%dl
f0104b28:	74 1a                	je     f0104b44 <readline+0x82>
f0104b2a:	85 f6                	test   %esi,%esi
f0104b2c:	7e 16                	jle    f0104b44 <readline+0x82>
			if (echoing)
f0104b2e:	85 ff                	test   %edi,%edi
f0104b30:	74 0d                	je     f0104b3f <readline+0x7d>
				cputchar('\b');
f0104b32:	83 ec 0c             	sub    $0xc,%esp
f0104b35:	6a 08                	push   $0x8
f0104b37:	e8 1a bc ff ff       	call   f0100756 <cputchar>
f0104b3c:	83 c4 10             	add    $0x10,%esp
			i--;
f0104b3f:	83 ee 01             	sub    $0x1,%esi
f0104b42:	eb b3                	jmp    f0104af7 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104b44:	83 fb 1f             	cmp    $0x1f,%ebx
f0104b47:	7e 23                	jle    f0104b6c <readline+0xaa>
f0104b49:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104b4f:	7f 1b                	jg     f0104b6c <readline+0xaa>
			if (echoing)
f0104b51:	85 ff                	test   %edi,%edi
f0104b53:	74 0c                	je     f0104b61 <readline+0x9f>
				cputchar(c);
f0104b55:	83 ec 0c             	sub    $0xc,%esp
f0104b58:	53                   	push   %ebx
f0104b59:	e8 f8 bb ff ff       	call   f0100756 <cputchar>
f0104b5e:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104b61:	88 9e 80 aa 22 f0    	mov    %bl,-0xfdd5580(%esi)
f0104b67:	8d 76 01             	lea    0x1(%esi),%esi
f0104b6a:	eb 8b                	jmp    f0104af7 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104b6c:	83 fb 0a             	cmp    $0xa,%ebx
f0104b6f:	74 05                	je     f0104b76 <readline+0xb4>
f0104b71:	83 fb 0d             	cmp    $0xd,%ebx
f0104b74:	75 81                	jne    f0104af7 <readline+0x35>
			if (echoing)
f0104b76:	85 ff                	test   %edi,%edi
f0104b78:	74 0d                	je     f0104b87 <readline+0xc5>
				cputchar('\n');
f0104b7a:	83 ec 0c             	sub    $0xc,%esp
f0104b7d:	6a 0a                	push   $0xa
f0104b7f:	e8 d2 bb ff ff       	call   f0100756 <cputchar>
f0104b84:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104b87:	c6 86 80 aa 22 f0 00 	movb   $0x0,-0xfdd5580(%esi)
			return buf;
f0104b8e:	b8 80 aa 22 f0       	mov    $0xf022aa80,%eax
		}
	}
}
f0104b93:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104b96:	5b                   	pop    %ebx
f0104b97:	5e                   	pop    %esi
f0104b98:	5f                   	pop    %edi
f0104b99:	5d                   	pop    %ebp
f0104b9a:	c3                   	ret    

f0104b9b <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104b9b:	55                   	push   %ebp
f0104b9c:	89 e5                	mov    %esp,%ebp
f0104b9e:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104ba1:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ba6:	eb 03                	jmp    f0104bab <strlen+0x10>
		n++;
f0104ba8:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104bab:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104baf:	75 f7                	jne    f0104ba8 <strlen+0xd>
		n++;
	return n;
}
f0104bb1:	5d                   	pop    %ebp
f0104bb2:	c3                   	ret    

f0104bb3 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104bb3:	55                   	push   %ebp
f0104bb4:	89 e5                	mov    %esp,%ebp
f0104bb6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104bb9:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104bbc:	ba 00 00 00 00       	mov    $0x0,%edx
f0104bc1:	eb 03                	jmp    f0104bc6 <strnlen+0x13>
		n++;
f0104bc3:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104bc6:	39 c2                	cmp    %eax,%edx
f0104bc8:	74 08                	je     f0104bd2 <strnlen+0x1f>
f0104bca:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104bce:	75 f3                	jne    f0104bc3 <strnlen+0x10>
f0104bd0:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104bd2:	5d                   	pop    %ebp
f0104bd3:	c3                   	ret    

f0104bd4 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104bd4:	55                   	push   %ebp
f0104bd5:	89 e5                	mov    %esp,%ebp
f0104bd7:	53                   	push   %ebx
f0104bd8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bdb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104bde:	89 c2                	mov    %eax,%edx
f0104be0:	83 c2 01             	add    $0x1,%edx
f0104be3:	83 c1 01             	add    $0x1,%ecx
f0104be6:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104bea:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104bed:	84 db                	test   %bl,%bl
f0104bef:	75 ef                	jne    f0104be0 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104bf1:	5b                   	pop    %ebx
f0104bf2:	5d                   	pop    %ebp
f0104bf3:	c3                   	ret    

f0104bf4 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104bf4:	55                   	push   %ebp
f0104bf5:	89 e5                	mov    %esp,%ebp
f0104bf7:	53                   	push   %ebx
f0104bf8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104bfb:	53                   	push   %ebx
f0104bfc:	e8 9a ff ff ff       	call   f0104b9b <strlen>
f0104c01:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104c04:	ff 75 0c             	pushl  0xc(%ebp)
f0104c07:	01 d8                	add    %ebx,%eax
f0104c09:	50                   	push   %eax
f0104c0a:	e8 c5 ff ff ff       	call   f0104bd4 <strcpy>
	return dst;
}
f0104c0f:	89 d8                	mov    %ebx,%eax
f0104c11:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104c14:	c9                   	leave  
f0104c15:	c3                   	ret    

f0104c16 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104c16:	55                   	push   %ebp
f0104c17:	89 e5                	mov    %esp,%ebp
f0104c19:	56                   	push   %esi
f0104c1a:	53                   	push   %ebx
f0104c1b:	8b 75 08             	mov    0x8(%ebp),%esi
f0104c1e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104c21:	89 f3                	mov    %esi,%ebx
f0104c23:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104c26:	89 f2                	mov    %esi,%edx
f0104c28:	eb 0f                	jmp    f0104c39 <strncpy+0x23>
		*dst++ = *src;
f0104c2a:	83 c2 01             	add    $0x1,%edx
f0104c2d:	0f b6 01             	movzbl (%ecx),%eax
f0104c30:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104c33:	80 39 01             	cmpb   $0x1,(%ecx)
f0104c36:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104c39:	39 da                	cmp    %ebx,%edx
f0104c3b:	75 ed                	jne    f0104c2a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104c3d:	89 f0                	mov    %esi,%eax
f0104c3f:	5b                   	pop    %ebx
f0104c40:	5e                   	pop    %esi
f0104c41:	5d                   	pop    %ebp
f0104c42:	c3                   	ret    

f0104c43 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104c43:	55                   	push   %ebp
f0104c44:	89 e5                	mov    %esp,%ebp
f0104c46:	56                   	push   %esi
f0104c47:	53                   	push   %ebx
f0104c48:	8b 75 08             	mov    0x8(%ebp),%esi
f0104c4b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104c4e:	8b 55 10             	mov    0x10(%ebp),%edx
f0104c51:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104c53:	85 d2                	test   %edx,%edx
f0104c55:	74 21                	je     f0104c78 <strlcpy+0x35>
f0104c57:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104c5b:	89 f2                	mov    %esi,%edx
f0104c5d:	eb 09                	jmp    f0104c68 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104c5f:	83 c2 01             	add    $0x1,%edx
f0104c62:	83 c1 01             	add    $0x1,%ecx
f0104c65:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104c68:	39 c2                	cmp    %eax,%edx
f0104c6a:	74 09                	je     f0104c75 <strlcpy+0x32>
f0104c6c:	0f b6 19             	movzbl (%ecx),%ebx
f0104c6f:	84 db                	test   %bl,%bl
f0104c71:	75 ec                	jne    f0104c5f <strlcpy+0x1c>
f0104c73:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104c75:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104c78:	29 f0                	sub    %esi,%eax
}
f0104c7a:	5b                   	pop    %ebx
f0104c7b:	5e                   	pop    %esi
f0104c7c:	5d                   	pop    %ebp
f0104c7d:	c3                   	ret    

f0104c7e <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104c7e:	55                   	push   %ebp
f0104c7f:	89 e5                	mov    %esp,%ebp
f0104c81:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104c84:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104c87:	eb 06                	jmp    f0104c8f <strcmp+0x11>
		p++, q++;
f0104c89:	83 c1 01             	add    $0x1,%ecx
f0104c8c:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104c8f:	0f b6 01             	movzbl (%ecx),%eax
f0104c92:	84 c0                	test   %al,%al
f0104c94:	74 04                	je     f0104c9a <strcmp+0x1c>
f0104c96:	3a 02                	cmp    (%edx),%al
f0104c98:	74 ef                	je     f0104c89 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104c9a:	0f b6 c0             	movzbl %al,%eax
f0104c9d:	0f b6 12             	movzbl (%edx),%edx
f0104ca0:	29 d0                	sub    %edx,%eax
}
f0104ca2:	5d                   	pop    %ebp
f0104ca3:	c3                   	ret    

f0104ca4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104ca4:	55                   	push   %ebp
f0104ca5:	89 e5                	mov    %esp,%ebp
f0104ca7:	53                   	push   %ebx
f0104ca8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cab:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104cae:	89 c3                	mov    %eax,%ebx
f0104cb0:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104cb3:	eb 06                	jmp    f0104cbb <strncmp+0x17>
		n--, p++, q++;
f0104cb5:	83 c0 01             	add    $0x1,%eax
f0104cb8:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104cbb:	39 d8                	cmp    %ebx,%eax
f0104cbd:	74 15                	je     f0104cd4 <strncmp+0x30>
f0104cbf:	0f b6 08             	movzbl (%eax),%ecx
f0104cc2:	84 c9                	test   %cl,%cl
f0104cc4:	74 04                	je     f0104cca <strncmp+0x26>
f0104cc6:	3a 0a                	cmp    (%edx),%cl
f0104cc8:	74 eb                	je     f0104cb5 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104cca:	0f b6 00             	movzbl (%eax),%eax
f0104ccd:	0f b6 12             	movzbl (%edx),%edx
f0104cd0:	29 d0                	sub    %edx,%eax
f0104cd2:	eb 05                	jmp    f0104cd9 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104cd4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104cd9:	5b                   	pop    %ebx
f0104cda:	5d                   	pop    %ebp
f0104cdb:	c3                   	ret    

f0104cdc <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104cdc:	55                   	push   %ebp
f0104cdd:	89 e5                	mov    %esp,%ebp
f0104cdf:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ce2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104ce6:	eb 07                	jmp    f0104cef <strchr+0x13>
		if (*s == c)
f0104ce8:	38 ca                	cmp    %cl,%dl
f0104cea:	74 0f                	je     f0104cfb <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104cec:	83 c0 01             	add    $0x1,%eax
f0104cef:	0f b6 10             	movzbl (%eax),%edx
f0104cf2:	84 d2                	test   %dl,%dl
f0104cf4:	75 f2                	jne    f0104ce8 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104cf6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104cfb:	5d                   	pop    %ebp
f0104cfc:	c3                   	ret    

f0104cfd <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104cfd:	55                   	push   %ebp
f0104cfe:	89 e5                	mov    %esp,%ebp
f0104d00:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d03:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104d07:	eb 03                	jmp    f0104d0c <strfind+0xf>
f0104d09:	83 c0 01             	add    $0x1,%eax
f0104d0c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104d0f:	38 ca                	cmp    %cl,%dl
f0104d11:	74 04                	je     f0104d17 <strfind+0x1a>
f0104d13:	84 d2                	test   %dl,%dl
f0104d15:	75 f2                	jne    f0104d09 <strfind+0xc>
			break;
	return (char *) s;
}
f0104d17:	5d                   	pop    %ebp
f0104d18:	c3                   	ret    

f0104d19 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104d19:	55                   	push   %ebp
f0104d1a:	89 e5                	mov    %esp,%ebp
f0104d1c:	57                   	push   %edi
f0104d1d:	56                   	push   %esi
f0104d1e:	53                   	push   %ebx
f0104d1f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104d22:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104d25:	85 c9                	test   %ecx,%ecx
f0104d27:	74 36                	je     f0104d5f <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104d29:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104d2f:	75 28                	jne    f0104d59 <memset+0x40>
f0104d31:	f6 c1 03             	test   $0x3,%cl
f0104d34:	75 23                	jne    f0104d59 <memset+0x40>
		c &= 0xFF;
f0104d36:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104d3a:	89 d3                	mov    %edx,%ebx
f0104d3c:	c1 e3 08             	shl    $0x8,%ebx
f0104d3f:	89 d6                	mov    %edx,%esi
f0104d41:	c1 e6 18             	shl    $0x18,%esi
f0104d44:	89 d0                	mov    %edx,%eax
f0104d46:	c1 e0 10             	shl    $0x10,%eax
f0104d49:	09 f0                	or     %esi,%eax
f0104d4b:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0104d4d:	89 d8                	mov    %ebx,%eax
f0104d4f:	09 d0                	or     %edx,%eax
f0104d51:	c1 e9 02             	shr    $0x2,%ecx
f0104d54:	fc                   	cld    
f0104d55:	f3 ab                	rep stos %eax,%es:(%edi)
f0104d57:	eb 06                	jmp    f0104d5f <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104d59:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d5c:	fc                   	cld    
f0104d5d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104d5f:	89 f8                	mov    %edi,%eax
f0104d61:	5b                   	pop    %ebx
f0104d62:	5e                   	pop    %esi
f0104d63:	5f                   	pop    %edi
f0104d64:	5d                   	pop    %ebp
f0104d65:	c3                   	ret    

f0104d66 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104d66:	55                   	push   %ebp
f0104d67:	89 e5                	mov    %esp,%ebp
f0104d69:	57                   	push   %edi
f0104d6a:	56                   	push   %esi
f0104d6b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d6e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104d71:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104d74:	39 c6                	cmp    %eax,%esi
f0104d76:	73 35                	jae    f0104dad <memmove+0x47>
f0104d78:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104d7b:	39 d0                	cmp    %edx,%eax
f0104d7d:	73 2e                	jae    f0104dad <memmove+0x47>
		s += n;
		d += n;
f0104d7f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104d82:	89 d6                	mov    %edx,%esi
f0104d84:	09 fe                	or     %edi,%esi
f0104d86:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104d8c:	75 13                	jne    f0104da1 <memmove+0x3b>
f0104d8e:	f6 c1 03             	test   $0x3,%cl
f0104d91:	75 0e                	jne    f0104da1 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104d93:	83 ef 04             	sub    $0x4,%edi
f0104d96:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104d99:	c1 e9 02             	shr    $0x2,%ecx
f0104d9c:	fd                   	std    
f0104d9d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104d9f:	eb 09                	jmp    f0104daa <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104da1:	83 ef 01             	sub    $0x1,%edi
f0104da4:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104da7:	fd                   	std    
f0104da8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104daa:	fc                   	cld    
f0104dab:	eb 1d                	jmp    f0104dca <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104dad:	89 f2                	mov    %esi,%edx
f0104daf:	09 c2                	or     %eax,%edx
f0104db1:	f6 c2 03             	test   $0x3,%dl
f0104db4:	75 0f                	jne    f0104dc5 <memmove+0x5f>
f0104db6:	f6 c1 03             	test   $0x3,%cl
f0104db9:	75 0a                	jne    f0104dc5 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0104dbb:	c1 e9 02             	shr    $0x2,%ecx
f0104dbe:	89 c7                	mov    %eax,%edi
f0104dc0:	fc                   	cld    
f0104dc1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104dc3:	eb 05                	jmp    f0104dca <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104dc5:	89 c7                	mov    %eax,%edi
f0104dc7:	fc                   	cld    
f0104dc8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104dca:	5e                   	pop    %esi
f0104dcb:	5f                   	pop    %edi
f0104dcc:	5d                   	pop    %ebp
f0104dcd:	c3                   	ret    

f0104dce <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104dce:	55                   	push   %ebp
f0104dcf:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104dd1:	ff 75 10             	pushl  0x10(%ebp)
f0104dd4:	ff 75 0c             	pushl  0xc(%ebp)
f0104dd7:	ff 75 08             	pushl  0x8(%ebp)
f0104dda:	e8 87 ff ff ff       	call   f0104d66 <memmove>
}
f0104ddf:	c9                   	leave  
f0104de0:	c3                   	ret    

f0104de1 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104de1:	55                   	push   %ebp
f0104de2:	89 e5                	mov    %esp,%ebp
f0104de4:	56                   	push   %esi
f0104de5:	53                   	push   %ebx
f0104de6:	8b 45 08             	mov    0x8(%ebp),%eax
f0104de9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104dec:	89 c6                	mov    %eax,%esi
f0104dee:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104df1:	eb 1a                	jmp    f0104e0d <memcmp+0x2c>
		if (*s1 != *s2)
f0104df3:	0f b6 08             	movzbl (%eax),%ecx
f0104df6:	0f b6 1a             	movzbl (%edx),%ebx
f0104df9:	38 d9                	cmp    %bl,%cl
f0104dfb:	74 0a                	je     f0104e07 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104dfd:	0f b6 c1             	movzbl %cl,%eax
f0104e00:	0f b6 db             	movzbl %bl,%ebx
f0104e03:	29 d8                	sub    %ebx,%eax
f0104e05:	eb 0f                	jmp    f0104e16 <memcmp+0x35>
		s1++, s2++;
f0104e07:	83 c0 01             	add    $0x1,%eax
f0104e0a:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104e0d:	39 f0                	cmp    %esi,%eax
f0104e0f:	75 e2                	jne    f0104df3 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104e11:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104e16:	5b                   	pop    %ebx
f0104e17:	5e                   	pop    %esi
f0104e18:	5d                   	pop    %ebp
f0104e19:	c3                   	ret    

f0104e1a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104e1a:	55                   	push   %ebp
f0104e1b:	89 e5                	mov    %esp,%ebp
f0104e1d:	53                   	push   %ebx
f0104e1e:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104e21:	89 c1                	mov    %eax,%ecx
f0104e23:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104e26:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104e2a:	eb 0a                	jmp    f0104e36 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104e2c:	0f b6 10             	movzbl (%eax),%edx
f0104e2f:	39 da                	cmp    %ebx,%edx
f0104e31:	74 07                	je     f0104e3a <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104e33:	83 c0 01             	add    $0x1,%eax
f0104e36:	39 c8                	cmp    %ecx,%eax
f0104e38:	72 f2                	jb     f0104e2c <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104e3a:	5b                   	pop    %ebx
f0104e3b:	5d                   	pop    %ebp
f0104e3c:	c3                   	ret    

f0104e3d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104e3d:	55                   	push   %ebp
f0104e3e:	89 e5                	mov    %esp,%ebp
f0104e40:	57                   	push   %edi
f0104e41:	56                   	push   %esi
f0104e42:	53                   	push   %ebx
f0104e43:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104e46:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104e49:	eb 03                	jmp    f0104e4e <strtol+0x11>
		s++;
f0104e4b:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104e4e:	0f b6 01             	movzbl (%ecx),%eax
f0104e51:	3c 20                	cmp    $0x20,%al
f0104e53:	74 f6                	je     f0104e4b <strtol+0xe>
f0104e55:	3c 09                	cmp    $0x9,%al
f0104e57:	74 f2                	je     f0104e4b <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104e59:	3c 2b                	cmp    $0x2b,%al
f0104e5b:	75 0a                	jne    f0104e67 <strtol+0x2a>
		s++;
f0104e5d:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104e60:	bf 00 00 00 00       	mov    $0x0,%edi
f0104e65:	eb 11                	jmp    f0104e78 <strtol+0x3b>
f0104e67:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104e6c:	3c 2d                	cmp    $0x2d,%al
f0104e6e:	75 08                	jne    f0104e78 <strtol+0x3b>
		s++, neg = 1;
f0104e70:	83 c1 01             	add    $0x1,%ecx
f0104e73:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104e78:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104e7e:	75 15                	jne    f0104e95 <strtol+0x58>
f0104e80:	80 39 30             	cmpb   $0x30,(%ecx)
f0104e83:	75 10                	jne    f0104e95 <strtol+0x58>
f0104e85:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104e89:	75 7c                	jne    f0104f07 <strtol+0xca>
		s += 2, base = 16;
f0104e8b:	83 c1 02             	add    $0x2,%ecx
f0104e8e:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104e93:	eb 16                	jmp    f0104eab <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104e95:	85 db                	test   %ebx,%ebx
f0104e97:	75 12                	jne    f0104eab <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104e99:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104e9e:	80 39 30             	cmpb   $0x30,(%ecx)
f0104ea1:	75 08                	jne    f0104eab <strtol+0x6e>
		s++, base = 8;
f0104ea3:	83 c1 01             	add    $0x1,%ecx
f0104ea6:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104eab:	b8 00 00 00 00       	mov    $0x0,%eax
f0104eb0:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104eb3:	0f b6 11             	movzbl (%ecx),%edx
f0104eb6:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104eb9:	89 f3                	mov    %esi,%ebx
f0104ebb:	80 fb 09             	cmp    $0x9,%bl
f0104ebe:	77 08                	ja     f0104ec8 <strtol+0x8b>
			dig = *s - '0';
f0104ec0:	0f be d2             	movsbl %dl,%edx
f0104ec3:	83 ea 30             	sub    $0x30,%edx
f0104ec6:	eb 22                	jmp    f0104eea <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104ec8:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104ecb:	89 f3                	mov    %esi,%ebx
f0104ecd:	80 fb 19             	cmp    $0x19,%bl
f0104ed0:	77 08                	ja     f0104eda <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104ed2:	0f be d2             	movsbl %dl,%edx
f0104ed5:	83 ea 57             	sub    $0x57,%edx
f0104ed8:	eb 10                	jmp    f0104eea <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104eda:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104edd:	89 f3                	mov    %esi,%ebx
f0104edf:	80 fb 19             	cmp    $0x19,%bl
f0104ee2:	77 16                	ja     f0104efa <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104ee4:	0f be d2             	movsbl %dl,%edx
f0104ee7:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104eea:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104eed:	7d 0b                	jge    f0104efa <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104eef:	83 c1 01             	add    $0x1,%ecx
f0104ef2:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104ef6:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104ef8:	eb b9                	jmp    f0104eb3 <strtol+0x76>

	if (endptr)
f0104efa:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104efe:	74 0d                	je     f0104f0d <strtol+0xd0>
		*endptr = (char *) s;
f0104f00:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104f03:	89 0e                	mov    %ecx,(%esi)
f0104f05:	eb 06                	jmp    f0104f0d <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104f07:	85 db                	test   %ebx,%ebx
f0104f09:	74 98                	je     f0104ea3 <strtol+0x66>
f0104f0b:	eb 9e                	jmp    f0104eab <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104f0d:	89 c2                	mov    %eax,%edx
f0104f0f:	f7 da                	neg    %edx
f0104f11:	85 ff                	test   %edi,%edi
f0104f13:	0f 45 c2             	cmovne %edx,%eax
}
f0104f16:	5b                   	pop    %ebx
f0104f17:	5e                   	pop    %esi
f0104f18:	5f                   	pop    %edi
f0104f19:	5d                   	pop    %ebp
f0104f1a:	c3                   	ret    
f0104f1b:	90                   	nop

f0104f1c <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0104f1c:	fa                   	cli    

	xorw    %ax, %ax
f0104f1d:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0104f1f:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104f21:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104f23:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0104f25:	0f 01 16             	lgdtl  (%esi)
f0104f28:	74 70                	je     f0104f9a <mpsearch1+0x3>
	movl    %cr0, %eax
f0104f2a:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0104f2d:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0104f31:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0104f34:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0104f3a:	08 00                	or     %al,(%eax)

f0104f3c <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0104f3c:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0104f40:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104f42:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104f44:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0104f46:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0104f4a:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0104f4c:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0104f4e:	b8 00 d0 11 00       	mov    $0x11d000,%eax
	movl    %eax, %cr3
f0104f53:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0104f56:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0104f59:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0104f5e:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0104f61:	8b 25 84 ae 22 f0    	mov    0xf022ae84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0104f67:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0104f6c:	b8 b3 01 10 f0       	mov    $0xf01001b3,%eax
	call    *%eax
f0104f71:	ff d0                	call   *%eax

f0104f73 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0104f73:	eb fe                	jmp    f0104f73 <spin>
f0104f75:	8d 76 00             	lea    0x0(%esi),%esi

f0104f78 <gdt>:
	...
f0104f80:	ff                   	(bad)  
f0104f81:	ff 00                	incl   (%eax)
f0104f83:	00 00                	add    %al,(%eax)
f0104f85:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0104f8c:	00                   	.byte 0x0
f0104f8d:	92                   	xchg   %eax,%edx
f0104f8e:	cf                   	iret   
	...

f0104f90 <gdtdesc>:
f0104f90:	17                   	pop    %ss
f0104f91:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0104f96 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0104f96:	90                   	nop

f0104f97 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0104f97:	55                   	push   %ebp
f0104f98:	89 e5                	mov    %esp,%ebp
f0104f9a:	57                   	push   %edi
f0104f9b:	56                   	push   %esi
f0104f9c:	53                   	push   %ebx
f0104f9d:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104fa0:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f0104fa6:	89 c3                	mov    %eax,%ebx
f0104fa8:	c1 eb 0c             	shr    $0xc,%ebx
f0104fab:	39 cb                	cmp    %ecx,%ebx
f0104fad:	72 12                	jb     f0104fc1 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104faf:	50                   	push   %eax
f0104fb0:	68 04 5a 10 f0       	push   $0xf0105a04
f0104fb5:	6a 57                	push   $0x57
f0104fb7:	68 05 75 10 f0       	push   $0xf0107505
f0104fbc:	e8 7f b0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104fc1:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0104fc7:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104fc9:	89 c2                	mov    %eax,%edx
f0104fcb:	c1 ea 0c             	shr    $0xc,%edx
f0104fce:	39 ca                	cmp    %ecx,%edx
f0104fd0:	72 12                	jb     f0104fe4 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104fd2:	50                   	push   %eax
f0104fd3:	68 04 5a 10 f0       	push   $0xf0105a04
f0104fd8:	6a 57                	push   $0x57
f0104fda:	68 05 75 10 f0       	push   $0xf0107505
f0104fdf:	e8 5c b0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104fe4:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0104fea:	eb 2f                	jmp    f010501b <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104fec:	83 ec 04             	sub    $0x4,%esp
f0104fef:	6a 04                	push   $0x4
f0104ff1:	68 15 75 10 f0       	push   $0xf0107515
f0104ff6:	53                   	push   %ebx
f0104ff7:	e8 e5 fd ff ff       	call   f0104de1 <memcmp>
f0104ffc:	83 c4 10             	add    $0x10,%esp
f0104fff:	85 c0                	test   %eax,%eax
f0105001:	75 15                	jne    f0105018 <mpsearch1+0x81>
f0105003:	89 da                	mov    %ebx,%edx
f0105005:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0105008:	0f b6 0a             	movzbl (%edx),%ecx
f010500b:	01 c8                	add    %ecx,%eax
f010500d:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105010:	39 d7                	cmp    %edx,%edi
f0105012:	75 f4                	jne    f0105008 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105014:	84 c0                	test   %al,%al
f0105016:	74 0e                	je     f0105026 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0105018:	83 c3 10             	add    $0x10,%ebx
f010501b:	39 f3                	cmp    %esi,%ebx
f010501d:	72 cd                	jb     f0104fec <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f010501f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105024:	eb 02                	jmp    f0105028 <mpsearch1+0x91>
f0105026:	89 d8                	mov    %ebx,%eax
}
f0105028:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010502b:	5b                   	pop    %ebx
f010502c:	5e                   	pop    %esi
f010502d:	5f                   	pop    %edi
f010502e:	5d                   	pop    %ebp
f010502f:	c3                   	ret    

f0105030 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105030:	55                   	push   %ebp
f0105031:	89 e5                	mov    %esp,%ebp
f0105033:	57                   	push   %edi
f0105034:	56                   	push   %esi
f0105035:	53                   	push   %ebx
f0105036:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105039:	c7 05 c0 b3 22 f0 20 	movl   $0xf022b020,0xf022b3c0
f0105040:	b0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105043:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f010504a:	75 16                	jne    f0105062 <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010504c:	68 00 04 00 00       	push   $0x400
f0105051:	68 04 5a 10 f0       	push   $0xf0105a04
f0105056:	6a 6f                	push   $0x6f
f0105058:	68 05 75 10 f0       	push   $0xf0107505
f010505d:	e8 de af ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105062:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105069:	85 c0                	test   %eax,%eax
f010506b:	74 16                	je     f0105083 <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f010506d:	c1 e0 04             	shl    $0x4,%eax
f0105070:	ba 00 04 00 00       	mov    $0x400,%edx
f0105075:	e8 1d ff ff ff       	call   f0104f97 <mpsearch1>
f010507a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010507d:	85 c0                	test   %eax,%eax
f010507f:	75 3c                	jne    f01050bd <mp_init+0x8d>
f0105081:	eb 20                	jmp    f01050a3 <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105083:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f010508a:	c1 e0 0a             	shl    $0xa,%eax
f010508d:	2d 00 04 00 00       	sub    $0x400,%eax
f0105092:	ba 00 04 00 00       	mov    $0x400,%edx
f0105097:	e8 fb fe ff ff       	call   f0104f97 <mpsearch1>
f010509c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010509f:	85 c0                	test   %eax,%eax
f01050a1:	75 1a                	jne    f01050bd <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f01050a3:	ba 00 00 01 00       	mov    $0x10000,%edx
f01050a8:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f01050ad:	e8 e5 fe ff ff       	call   f0104f97 <mpsearch1>
f01050b2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f01050b5:	85 c0                	test   %eax,%eax
f01050b7:	0f 84 5d 02 00 00    	je     f010531a <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f01050bd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01050c0:	8b 70 04             	mov    0x4(%eax),%esi
f01050c3:	85 f6                	test   %esi,%esi
f01050c5:	74 06                	je     f01050cd <mp_init+0x9d>
f01050c7:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f01050cb:	74 15                	je     f01050e2 <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f01050cd:	83 ec 0c             	sub    $0xc,%esp
f01050d0:	68 78 73 10 f0       	push   $0xf0107378
f01050d5:	e8 ba e5 ff ff       	call   f0103694 <cprintf>
f01050da:	83 c4 10             	add    $0x10,%esp
f01050dd:	e9 38 02 00 00       	jmp    f010531a <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01050e2:	89 f0                	mov    %esi,%eax
f01050e4:	c1 e8 0c             	shr    $0xc,%eax
f01050e7:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01050ed:	72 15                	jb     f0105104 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01050ef:	56                   	push   %esi
f01050f0:	68 04 5a 10 f0       	push   $0xf0105a04
f01050f5:	68 90 00 00 00       	push   $0x90
f01050fa:	68 05 75 10 f0       	push   $0xf0107505
f01050ff:	e8 3c af ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105104:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f010510a:	83 ec 04             	sub    $0x4,%esp
f010510d:	6a 04                	push   $0x4
f010510f:	68 1a 75 10 f0       	push   $0xf010751a
f0105114:	53                   	push   %ebx
f0105115:	e8 c7 fc ff ff       	call   f0104de1 <memcmp>
f010511a:	83 c4 10             	add    $0x10,%esp
f010511d:	85 c0                	test   %eax,%eax
f010511f:	74 15                	je     f0105136 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105121:	83 ec 0c             	sub    $0xc,%esp
f0105124:	68 a8 73 10 f0       	push   $0xf01073a8
f0105129:	e8 66 e5 ff ff       	call   f0103694 <cprintf>
f010512e:	83 c4 10             	add    $0x10,%esp
f0105131:	e9 e4 01 00 00       	jmp    f010531a <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105136:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f010513a:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f010513e:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105141:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105146:	b8 00 00 00 00       	mov    $0x0,%eax
f010514b:	eb 0d                	jmp    f010515a <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f010514d:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105154:	f0 
f0105155:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105157:	83 c0 01             	add    $0x1,%eax
f010515a:	39 c7                	cmp    %eax,%edi
f010515c:	75 ef                	jne    f010514d <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010515e:	84 d2                	test   %dl,%dl
f0105160:	74 15                	je     f0105177 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105162:	83 ec 0c             	sub    $0xc,%esp
f0105165:	68 dc 73 10 f0       	push   $0xf01073dc
f010516a:	e8 25 e5 ff ff       	call   f0103694 <cprintf>
f010516f:	83 c4 10             	add    $0x10,%esp
f0105172:	e9 a3 01 00 00       	jmp    f010531a <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105177:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f010517b:	3c 01                	cmp    $0x1,%al
f010517d:	74 1d                	je     f010519c <mp_init+0x16c>
f010517f:	3c 04                	cmp    $0x4,%al
f0105181:	74 19                	je     f010519c <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105183:	83 ec 08             	sub    $0x8,%esp
f0105186:	0f b6 c0             	movzbl %al,%eax
f0105189:	50                   	push   %eax
f010518a:	68 00 74 10 f0       	push   $0xf0107400
f010518f:	e8 00 e5 ff ff       	call   f0103694 <cprintf>
f0105194:	83 c4 10             	add    $0x10,%esp
f0105197:	e9 7e 01 00 00       	jmp    f010531a <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010519c:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f01051a0:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01051a4:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01051a9:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f01051ae:	01 ce                	add    %ecx,%esi
f01051b0:	eb 0d                	jmp    f01051bf <mp_init+0x18f>
f01051b2:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f01051b9:	f0 
f01051ba:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01051bc:	83 c0 01             	add    $0x1,%eax
f01051bf:	39 c7                	cmp    %eax,%edi
f01051c1:	75 ef                	jne    f01051b2 <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01051c3:	89 d0                	mov    %edx,%eax
f01051c5:	02 43 2a             	add    0x2a(%ebx),%al
f01051c8:	74 15                	je     f01051df <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f01051ca:	83 ec 0c             	sub    $0xc,%esp
f01051cd:	68 20 74 10 f0       	push   $0xf0107420
f01051d2:	e8 bd e4 ff ff       	call   f0103694 <cprintf>
f01051d7:	83 c4 10             	add    $0x10,%esp
f01051da:	e9 3b 01 00 00       	jmp    f010531a <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f01051df:	85 db                	test   %ebx,%ebx
f01051e1:	0f 84 33 01 00 00    	je     f010531a <mp_init+0x2ea>
		return;
	ismp = 1;
f01051e7:	c7 05 00 b0 22 f0 01 	movl   $0x1,0xf022b000
f01051ee:	00 00 00 
	lapicaddr = conf->lapicaddr;
f01051f1:	8b 43 24             	mov    0x24(%ebx),%eax
f01051f4:	a3 00 c0 26 f0       	mov    %eax,0xf026c000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01051f9:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f01051fc:	be 00 00 00 00       	mov    $0x0,%esi
f0105201:	e9 85 00 00 00       	jmp    f010528b <mp_init+0x25b>
		switch (*p) {
f0105206:	0f b6 07             	movzbl (%edi),%eax
f0105209:	84 c0                	test   %al,%al
f010520b:	74 06                	je     f0105213 <mp_init+0x1e3>
f010520d:	3c 04                	cmp    $0x4,%al
f010520f:	77 55                	ja     f0105266 <mp_init+0x236>
f0105211:	eb 4e                	jmp    f0105261 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105213:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105217:	74 11                	je     f010522a <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f0105219:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f0105220:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f0105225:	a3 c0 b3 22 f0       	mov    %eax,0xf022b3c0
			if (ncpu < NCPU) {
f010522a:	a1 c4 b3 22 f0       	mov    0xf022b3c4,%eax
f010522f:	83 f8 07             	cmp    $0x7,%eax
f0105232:	7f 13                	jg     f0105247 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f0105234:	6b d0 74             	imul   $0x74,%eax,%edx
f0105237:	88 82 20 b0 22 f0    	mov    %al,-0xfdd4fe0(%edx)
				ncpu++;
f010523d:	83 c0 01             	add    $0x1,%eax
f0105240:	a3 c4 b3 22 f0       	mov    %eax,0xf022b3c4
f0105245:	eb 15                	jmp    f010525c <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105247:	83 ec 08             	sub    $0x8,%esp
f010524a:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f010524e:	50                   	push   %eax
f010524f:	68 50 74 10 f0       	push   $0xf0107450
f0105254:	e8 3b e4 ff ff       	call   f0103694 <cprintf>
f0105259:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f010525c:	83 c7 14             	add    $0x14,%edi
			continue;
f010525f:	eb 27                	jmp    f0105288 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105261:	83 c7 08             	add    $0x8,%edi
			continue;
f0105264:	eb 22                	jmp    f0105288 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105266:	83 ec 08             	sub    $0x8,%esp
f0105269:	0f b6 c0             	movzbl %al,%eax
f010526c:	50                   	push   %eax
f010526d:	68 78 74 10 f0       	push   $0xf0107478
f0105272:	e8 1d e4 ff ff       	call   f0103694 <cprintf>
			ismp = 0;
f0105277:	c7 05 00 b0 22 f0 00 	movl   $0x0,0xf022b000
f010527e:	00 00 00 
			i = conf->entry;
f0105281:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105285:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105288:	83 c6 01             	add    $0x1,%esi
f010528b:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f010528f:	39 c6                	cmp    %eax,%esi
f0105291:	0f 82 6f ff ff ff    	jb     f0105206 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105297:	a1 c0 b3 22 f0       	mov    0xf022b3c0,%eax
f010529c:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01052a3:	83 3d 00 b0 22 f0 00 	cmpl   $0x0,0xf022b000
f01052aa:	75 26                	jne    f01052d2 <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f01052ac:	c7 05 c4 b3 22 f0 01 	movl   $0x1,0xf022b3c4
f01052b3:	00 00 00 
		lapicaddr = 0;
f01052b6:	c7 05 00 c0 26 f0 00 	movl   $0x0,0xf026c000
f01052bd:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01052c0:	83 ec 0c             	sub    $0xc,%esp
f01052c3:	68 98 74 10 f0       	push   $0xf0107498
f01052c8:	e8 c7 e3 ff ff       	call   f0103694 <cprintf>
		return;
f01052cd:	83 c4 10             	add    $0x10,%esp
f01052d0:	eb 48                	jmp    f010531a <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01052d2:	83 ec 04             	sub    $0x4,%esp
f01052d5:	ff 35 c4 b3 22 f0    	pushl  0xf022b3c4
f01052db:	0f b6 00             	movzbl (%eax),%eax
f01052de:	50                   	push   %eax
f01052df:	68 1f 75 10 f0       	push   $0xf010751f
f01052e4:	e8 ab e3 ff ff       	call   f0103694 <cprintf>

	if (mp->imcrp) {
f01052e9:	83 c4 10             	add    $0x10,%esp
f01052ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01052ef:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f01052f3:	74 25                	je     f010531a <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f01052f5:	83 ec 0c             	sub    $0xc,%esp
f01052f8:	68 c4 74 10 f0       	push   $0xf01074c4
f01052fd:	e8 92 e3 ff ff       	call   f0103694 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105302:	ba 22 00 00 00       	mov    $0x22,%edx
f0105307:	b8 70 00 00 00       	mov    $0x70,%eax
f010530c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010530d:	ba 23 00 00 00       	mov    $0x23,%edx
f0105312:	ec                   	in     (%dx),%al
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105313:	83 c8 01             	or     $0x1,%eax
f0105316:	ee                   	out    %al,(%dx)
f0105317:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f010531a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010531d:	5b                   	pop    %ebx
f010531e:	5e                   	pop    %esi
f010531f:	5f                   	pop    %edi
f0105320:	5d                   	pop    %ebp
f0105321:	c3                   	ret    

f0105322 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105322:	55                   	push   %ebp
f0105323:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105325:	8b 0d 04 c0 26 f0    	mov    0xf026c004,%ecx
f010532b:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f010532e:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105330:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f0105335:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105338:	5d                   	pop    %ebp
f0105339:	c3                   	ret    

f010533a <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f010533a:	55                   	push   %ebp
f010533b:	89 e5                	mov    %esp,%ebp
	if (lapic)
f010533d:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f0105342:	85 c0                	test   %eax,%eax
f0105344:	74 08                	je     f010534e <cpunum+0x14>
		return lapic[ID] >> 24;
f0105346:	8b 40 20             	mov    0x20(%eax),%eax
f0105349:	c1 e8 18             	shr    $0x18,%eax
f010534c:	eb 05                	jmp    f0105353 <cpunum+0x19>
	return 0;
f010534e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105353:	5d                   	pop    %ebp
f0105354:	c3                   	ret    

f0105355 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105355:	a1 00 c0 26 f0       	mov    0xf026c000,%eax
f010535a:	85 c0                	test   %eax,%eax
f010535c:	0f 84 21 01 00 00    	je     f0105483 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105362:	55                   	push   %ebp
f0105363:	89 e5                	mov    %esp,%ebp
f0105365:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105368:	68 00 10 00 00       	push   $0x1000
f010536d:	50                   	push   %eax
f010536e:	e8 5f be ff ff       	call   f01011d2 <mmio_map_region>
f0105373:	a3 04 c0 26 f0       	mov    %eax,0xf026c004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105378:	ba 27 01 00 00       	mov    $0x127,%edx
f010537d:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105382:	e8 9b ff ff ff       	call   f0105322 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105387:	ba 0b 00 00 00       	mov    $0xb,%edx
f010538c:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105391:	e8 8c ff ff ff       	call   f0105322 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105396:	ba 20 00 02 00       	mov    $0x20020,%edx
f010539b:	b8 c8 00 00 00       	mov    $0xc8,%eax
f01053a0:	e8 7d ff ff ff       	call   f0105322 <lapicw>
	lapicw(TICR, 10000000); 
f01053a5:	ba 80 96 98 00       	mov    $0x989680,%edx
f01053aa:	b8 e0 00 00 00       	mov    $0xe0,%eax
f01053af:	e8 6e ff ff ff       	call   f0105322 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f01053b4:	e8 81 ff ff ff       	call   f010533a <cpunum>
f01053b9:	6b c0 74             	imul   $0x74,%eax,%eax
f01053bc:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01053c1:	83 c4 10             	add    $0x10,%esp
f01053c4:	39 05 c0 b3 22 f0    	cmp    %eax,0xf022b3c0
f01053ca:	74 0f                	je     f01053db <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f01053cc:	ba 00 00 01 00       	mov    $0x10000,%edx
f01053d1:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01053d6:	e8 47 ff ff ff       	call   f0105322 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f01053db:	ba 00 00 01 00       	mov    $0x10000,%edx
f01053e0:	b8 d8 00 00 00       	mov    $0xd8,%eax
f01053e5:	e8 38 ff ff ff       	call   f0105322 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f01053ea:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f01053ef:	8b 40 30             	mov    0x30(%eax),%eax
f01053f2:	c1 e8 10             	shr    $0x10,%eax
f01053f5:	3c 03                	cmp    $0x3,%al
f01053f7:	76 0f                	jbe    f0105408 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f01053f9:	ba 00 00 01 00       	mov    $0x10000,%edx
f01053fe:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105403:	e8 1a ff ff ff       	call   f0105322 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105408:	ba 33 00 00 00       	mov    $0x33,%edx
f010540d:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105412:	e8 0b ff ff ff       	call   f0105322 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105417:	ba 00 00 00 00       	mov    $0x0,%edx
f010541c:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105421:	e8 fc fe ff ff       	call   f0105322 <lapicw>
	lapicw(ESR, 0);
f0105426:	ba 00 00 00 00       	mov    $0x0,%edx
f010542b:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105430:	e8 ed fe ff ff       	call   f0105322 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105435:	ba 00 00 00 00       	mov    $0x0,%edx
f010543a:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010543f:	e8 de fe ff ff       	call   f0105322 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105444:	ba 00 00 00 00       	mov    $0x0,%edx
f0105449:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010544e:	e8 cf fe ff ff       	call   f0105322 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105453:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105458:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010545d:	e8 c0 fe ff ff       	call   f0105322 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105462:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f0105468:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010546e:	f6 c4 10             	test   $0x10,%ah
f0105471:	75 f5                	jne    f0105468 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105473:	ba 00 00 00 00       	mov    $0x0,%edx
f0105478:	b8 20 00 00 00       	mov    $0x20,%eax
f010547d:	e8 a0 fe ff ff       	call   f0105322 <lapicw>
}
f0105482:	c9                   	leave  
f0105483:	f3 c3                	repz ret 

f0105485 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105485:	83 3d 04 c0 26 f0 00 	cmpl   $0x0,0xf026c004
f010548c:	74 13                	je     f01054a1 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010548e:	55                   	push   %ebp
f010548f:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105491:	ba 00 00 00 00       	mov    $0x0,%edx
f0105496:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010549b:	e8 82 fe ff ff       	call   f0105322 <lapicw>
}
f01054a0:	5d                   	pop    %ebp
f01054a1:	f3 c3                	repz ret 

f01054a3 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f01054a3:	55                   	push   %ebp
f01054a4:	89 e5                	mov    %esp,%ebp
f01054a6:	56                   	push   %esi
f01054a7:	53                   	push   %ebx
f01054a8:	8b 75 08             	mov    0x8(%ebp),%esi
f01054ab:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01054ae:	ba 70 00 00 00       	mov    $0x70,%edx
f01054b3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01054b8:	ee                   	out    %al,(%dx)
f01054b9:	ba 71 00 00 00       	mov    $0x71,%edx
f01054be:	b8 0a 00 00 00       	mov    $0xa,%eax
f01054c3:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01054c4:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f01054cb:	75 19                	jne    f01054e6 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01054cd:	68 67 04 00 00       	push   $0x467
f01054d2:	68 04 5a 10 f0       	push   $0xf0105a04
f01054d7:	68 98 00 00 00       	push   $0x98
f01054dc:	68 3c 75 10 f0       	push   $0xf010753c
f01054e1:	e8 5a ab ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f01054e6:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f01054ed:	00 00 
	wrv[1] = addr >> 4;
f01054ef:	89 d8                	mov    %ebx,%eax
f01054f1:	c1 e8 04             	shr    $0x4,%eax
f01054f4:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f01054fa:	c1 e6 18             	shl    $0x18,%esi
f01054fd:	89 f2                	mov    %esi,%edx
f01054ff:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105504:	e8 19 fe ff ff       	call   f0105322 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105509:	ba 00 c5 00 00       	mov    $0xc500,%edx
f010550e:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105513:	e8 0a fe ff ff       	call   f0105322 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105518:	ba 00 85 00 00       	mov    $0x8500,%edx
f010551d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105522:	e8 fb fd ff ff       	call   f0105322 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105527:	c1 eb 0c             	shr    $0xc,%ebx
f010552a:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f010552d:	89 f2                	mov    %esi,%edx
f010552f:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105534:	e8 e9 fd ff ff       	call   f0105322 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105539:	89 da                	mov    %ebx,%edx
f010553b:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105540:	e8 dd fd ff ff       	call   f0105322 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105545:	89 f2                	mov    %esi,%edx
f0105547:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010554c:	e8 d1 fd ff ff       	call   f0105322 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105551:	89 da                	mov    %ebx,%edx
f0105553:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105558:	e8 c5 fd ff ff       	call   f0105322 <lapicw>
		microdelay(200);
	}
}
f010555d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105560:	5b                   	pop    %ebx
f0105561:	5e                   	pop    %esi
f0105562:	5d                   	pop    %ebp
f0105563:	c3                   	ret    

f0105564 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105564:	55                   	push   %ebp
f0105565:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105567:	8b 55 08             	mov    0x8(%ebp),%edx
f010556a:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105570:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105575:	e8 a8 fd ff ff       	call   f0105322 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f010557a:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f0105580:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105586:	f6 c4 10             	test   $0x10,%ah
f0105589:	75 f5                	jne    f0105580 <lapic_ipi+0x1c>
		;
}
f010558b:	5d                   	pop    %ebp
f010558c:	c3                   	ret    

f010558d <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f010558d:	55                   	push   %ebp
f010558e:	89 e5                	mov    %esp,%ebp
f0105590:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105593:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105599:	8b 55 0c             	mov    0xc(%ebp),%edx
f010559c:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f010559f:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f01055a6:	5d                   	pop    %ebp
f01055a7:	c3                   	ret    

f01055a8 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f01055a8:	55                   	push   %ebp
f01055a9:	89 e5                	mov    %esp,%ebp
f01055ab:	56                   	push   %esi
f01055ac:	53                   	push   %ebx
f01055ad:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f01055b0:	83 3b 00             	cmpl   $0x0,(%ebx)
f01055b3:	74 14                	je     f01055c9 <spin_lock+0x21>
f01055b5:	8b 73 08             	mov    0x8(%ebx),%esi
f01055b8:	e8 7d fd ff ff       	call   f010533a <cpunum>
f01055bd:	6b c0 74             	imul   $0x74,%eax,%eax
f01055c0:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f01055c5:	39 c6                	cmp    %eax,%esi
f01055c7:	74 07                	je     f01055d0 <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f01055c9:	ba 01 00 00 00       	mov    $0x1,%edx
f01055ce:	eb 20                	jmp    f01055f0 <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f01055d0:	8b 5b 04             	mov    0x4(%ebx),%ebx
f01055d3:	e8 62 fd ff ff       	call   f010533a <cpunum>
f01055d8:	83 ec 0c             	sub    $0xc,%esp
f01055db:	53                   	push   %ebx
f01055dc:	50                   	push   %eax
f01055dd:	68 4c 75 10 f0       	push   $0xf010754c
f01055e2:	6a 41                	push   $0x41
f01055e4:	68 b0 75 10 f0       	push   $0xf01075b0
f01055e9:	e8 52 aa ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f01055ee:	f3 90                	pause  
f01055f0:	89 d0                	mov    %edx,%eax
f01055f2:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f01055f5:	85 c0                	test   %eax,%eax
f01055f7:	75 f5                	jne    f01055ee <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f01055f9:	e8 3c fd ff ff       	call   f010533a <cpunum>
f01055fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0105601:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f0105606:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105609:	83 c3 0c             	add    $0xc,%ebx

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010560c:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f010560e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105613:	eb 0b                	jmp    f0105620 <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105615:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105618:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f010561b:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f010561d:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105620:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105626:	76 11                	jbe    f0105639 <spin_lock+0x91>
f0105628:	83 f8 09             	cmp    $0x9,%eax
f010562b:	7e e8                	jle    f0105615 <spin_lock+0x6d>
f010562d:	eb 0a                	jmp    f0105639 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f010562f:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105636:	83 c0 01             	add    $0x1,%eax
f0105639:	83 f8 09             	cmp    $0x9,%eax
f010563c:	7e f1                	jle    f010562f <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f010563e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105641:	5b                   	pop    %ebx
f0105642:	5e                   	pop    %esi
f0105643:	5d                   	pop    %ebp
f0105644:	c3                   	ret    

f0105645 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105645:	55                   	push   %ebp
f0105646:	89 e5                	mov    %esp,%ebp
f0105648:	57                   	push   %edi
f0105649:	56                   	push   %esi
f010564a:	53                   	push   %ebx
f010564b:	83 ec 4c             	sub    $0x4c,%esp
f010564e:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105651:	83 3e 00             	cmpl   $0x0,(%esi)
f0105654:	74 18                	je     f010566e <spin_unlock+0x29>
f0105656:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105659:	e8 dc fc ff ff       	call   f010533a <cpunum>
f010565e:	6b c0 74             	imul   $0x74,%eax,%eax
f0105661:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105666:	39 c3                	cmp    %eax,%ebx
f0105668:	0f 84 a5 00 00 00    	je     f0105713 <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f010566e:	83 ec 04             	sub    $0x4,%esp
f0105671:	6a 28                	push   $0x28
f0105673:	8d 46 0c             	lea    0xc(%esi),%eax
f0105676:	50                   	push   %eax
f0105677:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f010567a:	53                   	push   %ebx
f010567b:	e8 e6 f6 ff ff       	call   f0104d66 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105680:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105683:	0f b6 38             	movzbl (%eax),%edi
f0105686:	8b 76 04             	mov    0x4(%esi),%esi
f0105689:	e8 ac fc ff ff       	call   f010533a <cpunum>
f010568e:	57                   	push   %edi
f010568f:	56                   	push   %esi
f0105690:	50                   	push   %eax
f0105691:	68 78 75 10 f0       	push   $0xf0107578
f0105696:	e8 f9 df ff ff       	call   f0103694 <cprintf>
f010569b:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f010569e:	8d 7d a8             	lea    -0x58(%ebp),%edi
f01056a1:	eb 54                	jmp    f01056f7 <spin_unlock+0xb2>
f01056a3:	83 ec 08             	sub    $0x8,%esp
f01056a6:	57                   	push   %edi
f01056a7:	50                   	push   %eax
f01056a8:	e8 37 ec ff ff       	call   f01042e4 <debuginfo_eip>
f01056ad:	83 c4 10             	add    $0x10,%esp
f01056b0:	85 c0                	test   %eax,%eax
f01056b2:	78 27                	js     f01056db <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f01056b4:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f01056b6:	83 ec 04             	sub    $0x4,%esp
f01056b9:	89 c2                	mov    %eax,%edx
f01056bb:	2b 55 b8             	sub    -0x48(%ebp),%edx
f01056be:	52                   	push   %edx
f01056bf:	ff 75 b0             	pushl  -0x50(%ebp)
f01056c2:	ff 75 b4             	pushl  -0x4c(%ebp)
f01056c5:	ff 75 ac             	pushl  -0x54(%ebp)
f01056c8:	ff 75 a8             	pushl  -0x58(%ebp)
f01056cb:	50                   	push   %eax
f01056cc:	68 c0 75 10 f0       	push   $0xf01075c0
f01056d1:	e8 be df ff ff       	call   f0103694 <cprintf>
f01056d6:	83 c4 20             	add    $0x20,%esp
f01056d9:	eb 12                	jmp    f01056ed <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f01056db:	83 ec 08             	sub    $0x8,%esp
f01056de:	ff 36                	pushl  (%esi)
f01056e0:	68 d7 75 10 f0       	push   $0xf01075d7
f01056e5:	e8 aa df ff ff       	call   f0103694 <cprintf>
f01056ea:	83 c4 10             	add    $0x10,%esp
f01056ed:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f01056f0:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01056f3:	39 c3                	cmp    %eax,%ebx
f01056f5:	74 08                	je     f01056ff <spin_unlock+0xba>
f01056f7:	89 de                	mov    %ebx,%esi
f01056f9:	8b 03                	mov    (%ebx),%eax
f01056fb:	85 c0                	test   %eax,%eax
f01056fd:	75 a4                	jne    f01056a3 <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f01056ff:	83 ec 04             	sub    $0x4,%esp
f0105702:	68 df 75 10 f0       	push   $0xf01075df
f0105707:	6a 67                	push   $0x67
f0105709:	68 b0 75 10 f0       	push   $0xf01075b0
f010570e:	e8 2d a9 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105713:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f010571a:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0105721:	b8 00 00 00 00       	mov    $0x0,%eax
f0105726:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0105729:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010572c:	5b                   	pop    %ebx
f010572d:	5e                   	pop    %esi
f010572e:	5f                   	pop    %edi
f010572f:	5d                   	pop    %ebp
f0105730:	c3                   	ret    
f0105731:	66 90                	xchg   %ax,%ax
f0105733:	66 90                	xchg   %ax,%ax
f0105735:	66 90                	xchg   %ax,%ax
f0105737:	66 90                	xchg   %ax,%ax
f0105739:	66 90                	xchg   %ax,%ax
f010573b:	66 90                	xchg   %ax,%ax
f010573d:	66 90                	xchg   %ax,%ax
f010573f:	90                   	nop

f0105740 <__udivdi3>:
f0105740:	55                   	push   %ebp
f0105741:	57                   	push   %edi
f0105742:	56                   	push   %esi
f0105743:	53                   	push   %ebx
f0105744:	83 ec 1c             	sub    $0x1c,%esp
f0105747:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010574b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010574f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105753:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105757:	85 f6                	test   %esi,%esi
f0105759:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010575d:	89 ca                	mov    %ecx,%edx
f010575f:	89 f8                	mov    %edi,%eax
f0105761:	75 3d                	jne    f01057a0 <__udivdi3+0x60>
f0105763:	39 cf                	cmp    %ecx,%edi
f0105765:	0f 87 c5 00 00 00    	ja     f0105830 <__udivdi3+0xf0>
f010576b:	85 ff                	test   %edi,%edi
f010576d:	89 fd                	mov    %edi,%ebp
f010576f:	75 0b                	jne    f010577c <__udivdi3+0x3c>
f0105771:	b8 01 00 00 00       	mov    $0x1,%eax
f0105776:	31 d2                	xor    %edx,%edx
f0105778:	f7 f7                	div    %edi
f010577a:	89 c5                	mov    %eax,%ebp
f010577c:	89 c8                	mov    %ecx,%eax
f010577e:	31 d2                	xor    %edx,%edx
f0105780:	f7 f5                	div    %ebp
f0105782:	89 c1                	mov    %eax,%ecx
f0105784:	89 d8                	mov    %ebx,%eax
f0105786:	89 cf                	mov    %ecx,%edi
f0105788:	f7 f5                	div    %ebp
f010578a:	89 c3                	mov    %eax,%ebx
f010578c:	89 d8                	mov    %ebx,%eax
f010578e:	89 fa                	mov    %edi,%edx
f0105790:	83 c4 1c             	add    $0x1c,%esp
f0105793:	5b                   	pop    %ebx
f0105794:	5e                   	pop    %esi
f0105795:	5f                   	pop    %edi
f0105796:	5d                   	pop    %ebp
f0105797:	c3                   	ret    
f0105798:	90                   	nop
f0105799:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01057a0:	39 ce                	cmp    %ecx,%esi
f01057a2:	77 74                	ja     f0105818 <__udivdi3+0xd8>
f01057a4:	0f bd fe             	bsr    %esi,%edi
f01057a7:	83 f7 1f             	xor    $0x1f,%edi
f01057aa:	0f 84 98 00 00 00    	je     f0105848 <__udivdi3+0x108>
f01057b0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01057b5:	89 f9                	mov    %edi,%ecx
f01057b7:	89 c5                	mov    %eax,%ebp
f01057b9:	29 fb                	sub    %edi,%ebx
f01057bb:	d3 e6                	shl    %cl,%esi
f01057bd:	89 d9                	mov    %ebx,%ecx
f01057bf:	d3 ed                	shr    %cl,%ebp
f01057c1:	89 f9                	mov    %edi,%ecx
f01057c3:	d3 e0                	shl    %cl,%eax
f01057c5:	09 ee                	or     %ebp,%esi
f01057c7:	89 d9                	mov    %ebx,%ecx
f01057c9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01057cd:	89 d5                	mov    %edx,%ebp
f01057cf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01057d3:	d3 ed                	shr    %cl,%ebp
f01057d5:	89 f9                	mov    %edi,%ecx
f01057d7:	d3 e2                	shl    %cl,%edx
f01057d9:	89 d9                	mov    %ebx,%ecx
f01057db:	d3 e8                	shr    %cl,%eax
f01057dd:	09 c2                	or     %eax,%edx
f01057df:	89 d0                	mov    %edx,%eax
f01057e1:	89 ea                	mov    %ebp,%edx
f01057e3:	f7 f6                	div    %esi
f01057e5:	89 d5                	mov    %edx,%ebp
f01057e7:	89 c3                	mov    %eax,%ebx
f01057e9:	f7 64 24 0c          	mull   0xc(%esp)
f01057ed:	39 d5                	cmp    %edx,%ebp
f01057ef:	72 10                	jb     f0105801 <__udivdi3+0xc1>
f01057f1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01057f5:	89 f9                	mov    %edi,%ecx
f01057f7:	d3 e6                	shl    %cl,%esi
f01057f9:	39 c6                	cmp    %eax,%esi
f01057fb:	73 07                	jae    f0105804 <__udivdi3+0xc4>
f01057fd:	39 d5                	cmp    %edx,%ebp
f01057ff:	75 03                	jne    f0105804 <__udivdi3+0xc4>
f0105801:	83 eb 01             	sub    $0x1,%ebx
f0105804:	31 ff                	xor    %edi,%edi
f0105806:	89 d8                	mov    %ebx,%eax
f0105808:	89 fa                	mov    %edi,%edx
f010580a:	83 c4 1c             	add    $0x1c,%esp
f010580d:	5b                   	pop    %ebx
f010580e:	5e                   	pop    %esi
f010580f:	5f                   	pop    %edi
f0105810:	5d                   	pop    %ebp
f0105811:	c3                   	ret    
f0105812:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105818:	31 ff                	xor    %edi,%edi
f010581a:	31 db                	xor    %ebx,%ebx
f010581c:	89 d8                	mov    %ebx,%eax
f010581e:	89 fa                	mov    %edi,%edx
f0105820:	83 c4 1c             	add    $0x1c,%esp
f0105823:	5b                   	pop    %ebx
f0105824:	5e                   	pop    %esi
f0105825:	5f                   	pop    %edi
f0105826:	5d                   	pop    %ebp
f0105827:	c3                   	ret    
f0105828:	90                   	nop
f0105829:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105830:	89 d8                	mov    %ebx,%eax
f0105832:	f7 f7                	div    %edi
f0105834:	31 ff                	xor    %edi,%edi
f0105836:	89 c3                	mov    %eax,%ebx
f0105838:	89 d8                	mov    %ebx,%eax
f010583a:	89 fa                	mov    %edi,%edx
f010583c:	83 c4 1c             	add    $0x1c,%esp
f010583f:	5b                   	pop    %ebx
f0105840:	5e                   	pop    %esi
f0105841:	5f                   	pop    %edi
f0105842:	5d                   	pop    %ebp
f0105843:	c3                   	ret    
f0105844:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105848:	39 ce                	cmp    %ecx,%esi
f010584a:	72 0c                	jb     f0105858 <__udivdi3+0x118>
f010584c:	31 db                	xor    %ebx,%ebx
f010584e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0105852:	0f 87 34 ff ff ff    	ja     f010578c <__udivdi3+0x4c>
f0105858:	bb 01 00 00 00       	mov    $0x1,%ebx
f010585d:	e9 2a ff ff ff       	jmp    f010578c <__udivdi3+0x4c>
f0105862:	66 90                	xchg   %ax,%ax
f0105864:	66 90                	xchg   %ax,%ax
f0105866:	66 90                	xchg   %ax,%ax
f0105868:	66 90                	xchg   %ax,%ax
f010586a:	66 90                	xchg   %ax,%ax
f010586c:	66 90                	xchg   %ax,%ax
f010586e:	66 90                	xchg   %ax,%ax

f0105870 <__umoddi3>:
f0105870:	55                   	push   %ebp
f0105871:	57                   	push   %edi
f0105872:	56                   	push   %esi
f0105873:	53                   	push   %ebx
f0105874:	83 ec 1c             	sub    $0x1c,%esp
f0105877:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010587b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010587f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105883:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105887:	85 d2                	test   %edx,%edx
f0105889:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010588d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105891:	89 f3                	mov    %esi,%ebx
f0105893:	89 3c 24             	mov    %edi,(%esp)
f0105896:	89 74 24 04          	mov    %esi,0x4(%esp)
f010589a:	75 1c                	jne    f01058b8 <__umoddi3+0x48>
f010589c:	39 f7                	cmp    %esi,%edi
f010589e:	76 50                	jbe    f01058f0 <__umoddi3+0x80>
f01058a0:	89 c8                	mov    %ecx,%eax
f01058a2:	89 f2                	mov    %esi,%edx
f01058a4:	f7 f7                	div    %edi
f01058a6:	89 d0                	mov    %edx,%eax
f01058a8:	31 d2                	xor    %edx,%edx
f01058aa:	83 c4 1c             	add    $0x1c,%esp
f01058ad:	5b                   	pop    %ebx
f01058ae:	5e                   	pop    %esi
f01058af:	5f                   	pop    %edi
f01058b0:	5d                   	pop    %ebp
f01058b1:	c3                   	ret    
f01058b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01058b8:	39 f2                	cmp    %esi,%edx
f01058ba:	89 d0                	mov    %edx,%eax
f01058bc:	77 52                	ja     f0105910 <__umoddi3+0xa0>
f01058be:	0f bd ea             	bsr    %edx,%ebp
f01058c1:	83 f5 1f             	xor    $0x1f,%ebp
f01058c4:	75 5a                	jne    f0105920 <__umoddi3+0xb0>
f01058c6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01058ca:	0f 82 e0 00 00 00    	jb     f01059b0 <__umoddi3+0x140>
f01058d0:	39 0c 24             	cmp    %ecx,(%esp)
f01058d3:	0f 86 d7 00 00 00    	jbe    f01059b0 <__umoddi3+0x140>
f01058d9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01058dd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01058e1:	83 c4 1c             	add    $0x1c,%esp
f01058e4:	5b                   	pop    %ebx
f01058e5:	5e                   	pop    %esi
f01058e6:	5f                   	pop    %edi
f01058e7:	5d                   	pop    %ebp
f01058e8:	c3                   	ret    
f01058e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01058f0:	85 ff                	test   %edi,%edi
f01058f2:	89 fd                	mov    %edi,%ebp
f01058f4:	75 0b                	jne    f0105901 <__umoddi3+0x91>
f01058f6:	b8 01 00 00 00       	mov    $0x1,%eax
f01058fb:	31 d2                	xor    %edx,%edx
f01058fd:	f7 f7                	div    %edi
f01058ff:	89 c5                	mov    %eax,%ebp
f0105901:	89 f0                	mov    %esi,%eax
f0105903:	31 d2                	xor    %edx,%edx
f0105905:	f7 f5                	div    %ebp
f0105907:	89 c8                	mov    %ecx,%eax
f0105909:	f7 f5                	div    %ebp
f010590b:	89 d0                	mov    %edx,%eax
f010590d:	eb 99                	jmp    f01058a8 <__umoddi3+0x38>
f010590f:	90                   	nop
f0105910:	89 c8                	mov    %ecx,%eax
f0105912:	89 f2                	mov    %esi,%edx
f0105914:	83 c4 1c             	add    $0x1c,%esp
f0105917:	5b                   	pop    %ebx
f0105918:	5e                   	pop    %esi
f0105919:	5f                   	pop    %edi
f010591a:	5d                   	pop    %ebp
f010591b:	c3                   	ret    
f010591c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105920:	8b 34 24             	mov    (%esp),%esi
f0105923:	bf 20 00 00 00       	mov    $0x20,%edi
f0105928:	89 e9                	mov    %ebp,%ecx
f010592a:	29 ef                	sub    %ebp,%edi
f010592c:	d3 e0                	shl    %cl,%eax
f010592e:	89 f9                	mov    %edi,%ecx
f0105930:	89 f2                	mov    %esi,%edx
f0105932:	d3 ea                	shr    %cl,%edx
f0105934:	89 e9                	mov    %ebp,%ecx
f0105936:	09 c2                	or     %eax,%edx
f0105938:	89 d8                	mov    %ebx,%eax
f010593a:	89 14 24             	mov    %edx,(%esp)
f010593d:	89 f2                	mov    %esi,%edx
f010593f:	d3 e2                	shl    %cl,%edx
f0105941:	89 f9                	mov    %edi,%ecx
f0105943:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105947:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010594b:	d3 e8                	shr    %cl,%eax
f010594d:	89 e9                	mov    %ebp,%ecx
f010594f:	89 c6                	mov    %eax,%esi
f0105951:	d3 e3                	shl    %cl,%ebx
f0105953:	89 f9                	mov    %edi,%ecx
f0105955:	89 d0                	mov    %edx,%eax
f0105957:	d3 e8                	shr    %cl,%eax
f0105959:	89 e9                	mov    %ebp,%ecx
f010595b:	09 d8                	or     %ebx,%eax
f010595d:	89 d3                	mov    %edx,%ebx
f010595f:	89 f2                	mov    %esi,%edx
f0105961:	f7 34 24             	divl   (%esp)
f0105964:	89 d6                	mov    %edx,%esi
f0105966:	d3 e3                	shl    %cl,%ebx
f0105968:	f7 64 24 04          	mull   0x4(%esp)
f010596c:	39 d6                	cmp    %edx,%esi
f010596e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105972:	89 d1                	mov    %edx,%ecx
f0105974:	89 c3                	mov    %eax,%ebx
f0105976:	72 08                	jb     f0105980 <__umoddi3+0x110>
f0105978:	75 11                	jne    f010598b <__umoddi3+0x11b>
f010597a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010597e:	73 0b                	jae    f010598b <__umoddi3+0x11b>
f0105980:	2b 44 24 04          	sub    0x4(%esp),%eax
f0105984:	1b 14 24             	sbb    (%esp),%edx
f0105987:	89 d1                	mov    %edx,%ecx
f0105989:	89 c3                	mov    %eax,%ebx
f010598b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010598f:	29 da                	sub    %ebx,%edx
f0105991:	19 ce                	sbb    %ecx,%esi
f0105993:	89 f9                	mov    %edi,%ecx
f0105995:	89 f0                	mov    %esi,%eax
f0105997:	d3 e0                	shl    %cl,%eax
f0105999:	89 e9                	mov    %ebp,%ecx
f010599b:	d3 ea                	shr    %cl,%edx
f010599d:	89 e9                	mov    %ebp,%ecx
f010599f:	d3 ee                	shr    %cl,%esi
f01059a1:	09 d0                	or     %edx,%eax
f01059a3:	89 f2                	mov    %esi,%edx
f01059a5:	83 c4 1c             	add    $0x1c,%esp
f01059a8:	5b                   	pop    %ebx
f01059a9:	5e                   	pop    %esi
f01059aa:	5f                   	pop    %edi
f01059ab:	5d                   	pop    %ebp
f01059ac:	c3                   	ret    
f01059ad:	8d 76 00             	lea    0x0(%esi),%esi
f01059b0:	29 f9                	sub    %edi,%ecx
f01059b2:	19 d6                	sbb    %edx,%esi
f01059b4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01059b8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01059bc:	e9 18 ff ff ff       	jmp    f01058d9 <__umoddi3+0x69>

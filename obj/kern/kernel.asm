
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
f010005c:	e8 75 52 00 00       	call   f01052d6 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 60 59 10 f0       	push   $0xf0105960
f010006d:	e8 4f 36 00 00       	call   f01036c1 <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 1f 36 00 00       	call   f010369b <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 e9 5c 10 f0 	movl   $0xf0105ce9,(%esp)
f0100083:	e8 39 36 00 00       	call   f01036c1 <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 54 08 00 00       	call   f01008e9 <monitor>
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
f01000b3:	e8 fd 4b 00 00       	call   f0104cb5 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 5c 05 00 00       	call   f0100619 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 cc 59 10 f0       	push   $0xf01059cc
f01000ca:	e8 f2 35 00 00       	call   f01036c1 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 87 11 00 00       	call   f010125b <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 05 2e 00 00       	call   f0102ede <env_init>
	trap_init();
f01000d9:	e8 c9 36 00 00       	call   f01037a7 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 e9 4e 00 00       	call   f0104fcc <mp_init>
	lapic_init();
f01000e3:	e8 09 52 00 00       	call   f01052f1 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 fb 34 00 00       	call   f01035e8 <pic_init>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000ed:	83 c4 10             	add    $0x10,%esp
f01000f0:	83 3d 88 ae 22 f0 07 	cmpl   $0x7,0xf022ae88
f01000f7:	77 16                	ja     f010010f <i386_init+0x75>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01000f9:	68 00 70 00 00       	push   $0x7000
f01000fe:	68 84 59 10 f0       	push   $0xf0105984
f0100103:	6a 53                	push   $0x53
f0100105:	68 e7 59 10 f0       	push   $0xf01059e7
f010010a:	e8 31 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010010f:	83 ec 04             	sub    $0x4,%esp
f0100112:	b8 32 4f 10 f0       	mov    $0xf0104f32,%eax
f0100117:	2d b8 4e 10 f0       	sub    $0xf0104eb8,%eax
f010011c:	50                   	push   %eax
f010011d:	68 b8 4e 10 f0       	push   $0xf0104eb8
f0100122:	68 00 70 00 f0       	push   $0xf0007000
f0100127:	e8 d6 4b 00 00       	call   f0104d02 <memmove>
f010012c:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010012f:	bb 20 b0 22 f0       	mov    $0xf022b020,%ebx
f0100134:	eb 4d                	jmp    f0100183 <i386_init+0xe9>
		if (c == cpus + cpunum())  // We've started already.
f0100136:	e8 9b 51 00 00       	call   f01052d6 <cpunum>
f010013b:	6b c0 74             	imul   $0x74,%eax,%eax
f010013e:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f0100143:	39 c3                	cmp    %eax,%ebx
f0100145:	74 39                	je     f0100180 <i386_init+0xe6>
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100147:	89 d8                	mov    %ebx,%eax
f0100149:	2d 20 b0 22 f0       	sub    $0xf022b020,%eax
f010014e:	c1 f8 02             	sar    $0x2,%eax
f0100151:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100157:	c1 e0 0f             	shl    $0xf,%eax
f010015a:	05 00 40 23 f0       	add    $0xf0234000,%eax
f010015f:	a3 84 ae 22 f0       	mov    %eax,0xf022ae84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100164:	83 ec 08             	sub    $0x8,%esp
f0100167:	68 00 70 00 00       	push   $0x7000
f010016c:	0f b6 03             	movzbl (%ebx),%eax
f010016f:	50                   	push   %eax
f0100170:	e8 ca 52 00 00       	call   f010543f <lapic_startap>
f0100175:	83 c4 10             	add    $0x10,%esp
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f0100178:	8b 43 04             	mov    0x4(%ebx),%eax
f010017b:	83 f8 01             	cmp    $0x1,%eax
f010017e:	75 f8                	jne    f0100178 <i386_init+0xde>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100180:	83 c3 74             	add    $0x74,%ebx
f0100183:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f010018a:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010018f:	39 c3                	cmp    %eax,%ebx
f0100191:	72 a3                	jb     f0100136 <i386_init+0x9c>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_primes, ENV_TYPE_USER);
f0100193:	83 ec 08             	sub    $0x8,%esp
f0100196:	6a 00                	push   $0x0
f0100198:	68 c8 0b 22 f0       	push   $0xf0220bc8
f010019d:	e8 04 2f 00 00       	call   f01030a6 <env_create>
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001a2:	e8 c1 3e 00 00       	call   f0104068 <sched_yield>

f01001a7 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001a7:	55                   	push   %ebp
f01001a8:	89 e5                	mov    %esp,%ebp
f01001aa:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001ad:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001b2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001b7:	77 12                	ja     f01001cb <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001b9:	50                   	push   %eax
f01001ba:	68 a8 59 10 f0       	push   $0xf01059a8
f01001bf:	6a 6a                	push   $0x6a
f01001c1:	68 e7 59 10 f0       	push   $0xf01059e7
f01001c6:	e8 75 fe ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01001cb:	05 00 00 00 10       	add    $0x10000000,%eax
f01001d0:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001d3:	e8 fe 50 00 00       	call   f01052d6 <cpunum>
f01001d8:	83 ec 08             	sub    $0x8,%esp
f01001db:	50                   	push   %eax
f01001dc:	68 f3 59 10 f0       	push   $0xf01059f3
f01001e1:	e8 db 34 00 00       	call   f01036c1 <cprintf>

	lapic_init();
f01001e6:	e8 06 51 00 00       	call   f01052f1 <lapic_init>
	env_init_percpu();
f01001eb:	e8 be 2c 00 00       	call   f0102eae <env_init_percpu>
	trap_init_percpu();
f01001f0:	e8 e0 34 00 00       	call   f01036d5 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f01001f5:	e8 dc 50 00 00       	call   f01052d6 <cpunum>
f01001fa:	6b d0 74             	imul   $0x74,%eax,%edx
f01001fd:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0100203:	b8 01 00 00 00       	mov    $0x1,%eax
f0100208:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010020c:	83 c4 10             	add    $0x10,%esp
f010020f:	eb fe                	jmp    f010020f <mp_main+0x68>

f0100211 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100211:	55                   	push   %ebp
f0100212:	89 e5                	mov    %esp,%ebp
f0100214:	53                   	push   %ebx
f0100215:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100218:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010021b:	ff 75 0c             	pushl  0xc(%ebp)
f010021e:	ff 75 08             	pushl  0x8(%ebp)
f0100221:	68 09 5a 10 f0       	push   $0xf0105a09
f0100226:	e8 96 34 00 00       	call   f01036c1 <cprintf>
	vcprintf(fmt, ap);
f010022b:	83 c4 08             	add    $0x8,%esp
f010022e:	53                   	push   %ebx
f010022f:	ff 75 10             	pushl  0x10(%ebp)
f0100232:	e8 64 34 00 00       	call   f010369b <vcprintf>
	cprintf("\n");
f0100237:	c7 04 24 e9 5c 10 f0 	movl   $0xf0105ce9,(%esp)
f010023e:	e8 7e 34 00 00       	call   f01036c1 <cprintf>
	va_end(ap);
}
f0100243:	83 c4 10             	add    $0x10,%esp
f0100246:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100249:	c9                   	leave  
f010024a:	c3                   	ret    

f010024b <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010024b:	55                   	push   %ebp
f010024c:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010024e:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100253:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100254:	a8 01                	test   $0x1,%al
f0100256:	74 0b                	je     f0100263 <serial_proc_data+0x18>
f0100258:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010025d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010025e:	0f b6 c0             	movzbl %al,%eax
f0100261:	eb 05                	jmp    f0100268 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100263:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100268:	5d                   	pop    %ebp
f0100269:	c3                   	ret    

f010026a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010026a:	55                   	push   %ebp
f010026b:	89 e5                	mov    %esp,%ebp
f010026d:	53                   	push   %ebx
f010026e:	83 ec 04             	sub    $0x4,%esp
f0100271:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100273:	eb 2b                	jmp    f01002a0 <cons_intr+0x36>
		if (c == 0)
f0100275:	85 c0                	test   %eax,%eax
f0100277:	74 27                	je     f01002a0 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100279:	8b 0d 24 a2 22 f0    	mov    0xf022a224,%ecx
f010027f:	8d 51 01             	lea    0x1(%ecx),%edx
f0100282:	89 15 24 a2 22 f0    	mov    %edx,0xf022a224
f0100288:	88 81 20 a0 22 f0    	mov    %al,-0xfdd5fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010028e:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100294:	75 0a                	jne    f01002a0 <cons_intr+0x36>
			cons.wpos = 0;
f0100296:	c7 05 24 a2 22 f0 00 	movl   $0x0,0xf022a224
f010029d:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002a0:	ff d3                	call   *%ebx
f01002a2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002a5:	75 ce                	jne    f0100275 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002a7:	83 c4 04             	add    $0x4,%esp
f01002aa:	5b                   	pop    %ebx
f01002ab:	5d                   	pop    %ebp
f01002ac:	c3                   	ret    

f01002ad <kbd_proc_data>:
f01002ad:	ba 64 00 00 00       	mov    $0x64,%edx
f01002b2:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01002b3:	a8 01                	test   $0x1,%al
f01002b5:	0f 84 f0 00 00 00    	je     f01003ab <kbd_proc_data+0xfe>
f01002bb:	ba 60 00 00 00       	mov    $0x60,%edx
f01002c0:	ec                   	in     (%dx),%al
f01002c1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002c3:	3c e0                	cmp    $0xe0,%al
f01002c5:	75 0d                	jne    f01002d4 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01002c7:	83 0d 00 a0 22 f0 40 	orl    $0x40,0xf022a000
		return 0;
f01002ce:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002d3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01002d4:	55                   	push   %ebp
f01002d5:	89 e5                	mov    %esp,%ebp
f01002d7:	53                   	push   %ebx
f01002d8:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01002db:	84 c0                	test   %al,%al
f01002dd:	79 36                	jns    f0100315 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01002df:	8b 0d 00 a0 22 f0    	mov    0xf022a000,%ecx
f01002e5:	89 cb                	mov    %ecx,%ebx
f01002e7:	83 e3 40             	and    $0x40,%ebx
f01002ea:	83 e0 7f             	and    $0x7f,%eax
f01002ed:	85 db                	test   %ebx,%ebx
f01002ef:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002f2:	0f b6 d2             	movzbl %dl,%edx
f01002f5:	0f b6 82 80 5b 10 f0 	movzbl -0xfefa480(%edx),%eax
f01002fc:	83 c8 40             	or     $0x40,%eax
f01002ff:	0f b6 c0             	movzbl %al,%eax
f0100302:	f7 d0                	not    %eax
f0100304:	21 c8                	and    %ecx,%eax
f0100306:	a3 00 a0 22 f0       	mov    %eax,0xf022a000
		return 0;
f010030b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100310:	e9 9e 00 00 00       	jmp    f01003b3 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100315:	8b 0d 00 a0 22 f0    	mov    0xf022a000,%ecx
f010031b:	f6 c1 40             	test   $0x40,%cl
f010031e:	74 0e                	je     f010032e <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100320:	83 c8 80             	or     $0xffffff80,%eax
f0100323:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100325:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100328:	89 0d 00 a0 22 f0    	mov    %ecx,0xf022a000
	}

	shift |= shiftcode[data];
f010032e:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100331:	0f b6 82 80 5b 10 f0 	movzbl -0xfefa480(%edx),%eax
f0100338:	0b 05 00 a0 22 f0    	or     0xf022a000,%eax
f010033e:	0f b6 8a 80 5a 10 f0 	movzbl -0xfefa580(%edx),%ecx
f0100345:	31 c8                	xor    %ecx,%eax
f0100347:	a3 00 a0 22 f0       	mov    %eax,0xf022a000

	c = charcode[shift & (CTL | SHIFT)][data];
f010034c:	89 c1                	mov    %eax,%ecx
f010034e:	83 e1 03             	and    $0x3,%ecx
f0100351:	8b 0c 8d 60 5a 10 f0 	mov    -0xfefa5a0(,%ecx,4),%ecx
f0100358:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010035c:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010035f:	a8 08                	test   $0x8,%al
f0100361:	74 1b                	je     f010037e <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100363:	89 da                	mov    %ebx,%edx
f0100365:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100368:	83 f9 19             	cmp    $0x19,%ecx
f010036b:	77 05                	ja     f0100372 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f010036d:	83 eb 20             	sub    $0x20,%ebx
f0100370:	eb 0c                	jmp    f010037e <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100372:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100375:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100378:	83 fa 19             	cmp    $0x19,%edx
f010037b:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010037e:	f7 d0                	not    %eax
f0100380:	a8 06                	test   $0x6,%al
f0100382:	75 2d                	jne    f01003b1 <kbd_proc_data+0x104>
f0100384:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010038a:	75 25                	jne    f01003b1 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f010038c:	83 ec 0c             	sub    $0xc,%esp
f010038f:	68 23 5a 10 f0       	push   $0xf0105a23
f0100394:	e8 28 33 00 00       	call   f01036c1 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100399:	ba 92 00 00 00       	mov    $0x92,%edx
f010039e:	b8 03 00 00 00       	mov    $0x3,%eax
f01003a3:	ee                   	out    %al,(%dx)
f01003a4:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003a7:	89 d8                	mov    %ebx,%eax
f01003a9:	eb 08                	jmp    f01003b3 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003b0:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003b1:	89 d8                	mov    %ebx,%eax
}
f01003b3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003b6:	c9                   	leave  
f01003b7:	c3                   	ret    

f01003b8 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003b8:	55                   	push   %ebp
f01003b9:	89 e5                	mov    %esp,%ebp
f01003bb:	57                   	push   %edi
f01003bc:	56                   	push   %esi
f01003bd:	53                   	push   %ebx
f01003be:	83 ec 1c             	sub    $0x1c,%esp
f01003c1:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003c3:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003c8:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003cd:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003d2:	eb 09                	jmp    f01003dd <cons_putc+0x25>
f01003d4:	89 ca                	mov    %ecx,%edx
f01003d6:	ec                   	in     (%dx),%al
f01003d7:	ec                   	in     (%dx),%al
f01003d8:	ec                   	in     (%dx),%al
f01003d9:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01003da:	83 c3 01             	add    $0x1,%ebx
f01003dd:	89 f2                	mov    %esi,%edx
f01003df:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01003e0:	a8 20                	test   $0x20,%al
f01003e2:	75 08                	jne    f01003ec <cons_putc+0x34>
f01003e4:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01003ea:	7e e8                	jle    f01003d4 <cons_putc+0x1c>
f01003ec:	89 f8                	mov    %edi,%eax
f01003ee:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003f1:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003f6:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003f7:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003fc:	be 79 03 00 00       	mov    $0x379,%esi
f0100401:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100406:	eb 09                	jmp    f0100411 <cons_putc+0x59>
f0100408:	89 ca                	mov    %ecx,%edx
f010040a:	ec                   	in     (%dx),%al
f010040b:	ec                   	in     (%dx),%al
f010040c:	ec                   	in     (%dx),%al
f010040d:	ec                   	in     (%dx),%al
f010040e:	83 c3 01             	add    $0x1,%ebx
f0100411:	89 f2                	mov    %esi,%edx
f0100413:	ec                   	in     (%dx),%al
f0100414:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010041a:	7f 04                	jg     f0100420 <cons_putc+0x68>
f010041c:	84 c0                	test   %al,%al
f010041e:	79 e8                	jns    f0100408 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100420:	ba 78 03 00 00       	mov    $0x378,%edx
f0100425:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100429:	ee                   	out    %al,(%dx)
f010042a:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010042f:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100434:	ee                   	out    %al,(%dx)
f0100435:	b8 08 00 00 00       	mov    $0x8,%eax
f010043a:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010043b:	89 fa                	mov    %edi,%edx
f010043d:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100443:	89 f8                	mov    %edi,%eax
f0100445:	80 cc 07             	or     $0x7,%ah
f0100448:	85 d2                	test   %edx,%edx
f010044a:	0f 44 f8             	cmove  %eax,%edi
    // 	    }
	//     else {
    //           c |= 0x0400;
    // 	    }
	// }
	switch (c & 0xff) {
f010044d:	89 f8                	mov    %edi,%eax
f010044f:	0f b6 c0             	movzbl %al,%eax
f0100452:	83 f8 09             	cmp    $0x9,%eax
f0100455:	74 74                	je     f01004cb <cons_putc+0x113>
f0100457:	83 f8 09             	cmp    $0x9,%eax
f010045a:	7f 0a                	jg     f0100466 <cons_putc+0xae>
f010045c:	83 f8 08             	cmp    $0x8,%eax
f010045f:	74 14                	je     f0100475 <cons_putc+0xbd>
f0100461:	e9 99 00 00 00       	jmp    f01004ff <cons_putc+0x147>
f0100466:	83 f8 0a             	cmp    $0xa,%eax
f0100469:	74 3a                	je     f01004a5 <cons_putc+0xed>
f010046b:	83 f8 0d             	cmp    $0xd,%eax
f010046e:	74 3d                	je     f01004ad <cons_putc+0xf5>
f0100470:	e9 8a 00 00 00       	jmp    f01004ff <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100475:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f010047c:	66 85 c0             	test   %ax,%ax
f010047f:	0f 84 e6 00 00 00    	je     f010056b <cons_putc+0x1b3>
			crt_pos--;
f0100485:	83 e8 01             	sub    $0x1,%eax
f0100488:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010048e:	0f b7 c0             	movzwl %ax,%eax
f0100491:	66 81 e7 00 ff       	and    $0xff00,%di
f0100496:	83 cf 20             	or     $0x20,%edi
f0100499:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f010049f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004a3:	eb 78                	jmp    f010051d <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004a5:	66 83 05 28 a2 22 f0 	addw   $0x50,0xf022a228
f01004ac:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004ad:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f01004b4:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004ba:	c1 e8 16             	shr    $0x16,%eax
f01004bd:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004c0:	c1 e0 04             	shl    $0x4,%eax
f01004c3:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228
f01004c9:	eb 52                	jmp    f010051d <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01004cb:	b8 20 00 00 00       	mov    $0x20,%eax
f01004d0:	e8 e3 fe ff ff       	call   f01003b8 <cons_putc>
		cons_putc(' ');
f01004d5:	b8 20 00 00 00       	mov    $0x20,%eax
f01004da:	e8 d9 fe ff ff       	call   f01003b8 <cons_putc>
		cons_putc(' ');
f01004df:	b8 20 00 00 00       	mov    $0x20,%eax
f01004e4:	e8 cf fe ff ff       	call   f01003b8 <cons_putc>
		cons_putc(' ');
f01004e9:	b8 20 00 00 00       	mov    $0x20,%eax
f01004ee:	e8 c5 fe ff ff       	call   f01003b8 <cons_putc>
		cons_putc(' ');
f01004f3:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f8:	e8 bb fe ff ff       	call   f01003b8 <cons_putc>
f01004fd:	eb 1e                	jmp    f010051d <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01004ff:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f0100506:	8d 50 01             	lea    0x1(%eax),%edx
f0100509:	66 89 15 28 a2 22 f0 	mov    %dx,0xf022a228
f0100510:	0f b7 c0             	movzwl %ax,%eax
f0100513:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f0100519:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010051d:	66 81 3d 28 a2 22 f0 	cmpw   $0x7cf,0xf022a228
f0100524:	cf 07 
f0100526:	76 43                	jbe    f010056b <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100528:	a1 2c a2 22 f0       	mov    0xf022a22c,%eax
f010052d:	83 ec 04             	sub    $0x4,%esp
f0100530:	68 00 0f 00 00       	push   $0xf00
f0100535:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010053b:	52                   	push   %edx
f010053c:	50                   	push   %eax
f010053d:	e8 c0 47 00 00       	call   f0104d02 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100542:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f0100548:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010054e:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100554:	83 c4 10             	add    $0x10,%esp
f0100557:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010055c:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010055f:	39 d0                	cmp    %edx,%eax
f0100561:	75 f4                	jne    f0100557 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100563:	66 83 2d 28 a2 22 f0 	subw   $0x50,0xf022a228
f010056a:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010056b:	8b 0d 30 a2 22 f0    	mov    0xf022a230,%ecx
f0100571:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100576:	89 ca                	mov    %ecx,%edx
f0100578:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100579:	0f b7 1d 28 a2 22 f0 	movzwl 0xf022a228,%ebx
f0100580:	8d 71 01             	lea    0x1(%ecx),%esi
f0100583:	89 d8                	mov    %ebx,%eax
f0100585:	66 c1 e8 08          	shr    $0x8,%ax
f0100589:	89 f2                	mov    %esi,%edx
f010058b:	ee                   	out    %al,(%dx)
f010058c:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100591:	89 ca                	mov    %ecx,%edx
f0100593:	ee                   	out    %al,(%dx)
f0100594:	89 d8                	mov    %ebx,%eax
f0100596:	89 f2                	mov    %esi,%edx
f0100598:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100599:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010059c:	5b                   	pop    %ebx
f010059d:	5e                   	pop    %esi
f010059e:	5f                   	pop    %edi
f010059f:	5d                   	pop    %ebp
f01005a0:	c3                   	ret    

f01005a1 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005a1:	80 3d 34 a2 22 f0 00 	cmpb   $0x0,0xf022a234
f01005a8:	74 11                	je     f01005bb <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005aa:	55                   	push   %ebp
f01005ab:	89 e5                	mov    %esp,%ebp
f01005ad:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005b0:	b8 4b 02 10 f0       	mov    $0xf010024b,%eax
f01005b5:	e8 b0 fc ff ff       	call   f010026a <cons_intr>
}
f01005ba:	c9                   	leave  
f01005bb:	f3 c3                	repz ret 

f01005bd <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005bd:	55                   	push   %ebp
f01005be:	89 e5                	mov    %esp,%ebp
f01005c0:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005c3:	b8 ad 02 10 f0       	mov    $0xf01002ad,%eax
f01005c8:	e8 9d fc ff ff       	call   f010026a <cons_intr>
}
f01005cd:	c9                   	leave  
f01005ce:	c3                   	ret    

f01005cf <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01005cf:	55                   	push   %ebp
f01005d0:	89 e5                	mov    %esp,%ebp
f01005d2:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01005d5:	e8 c7 ff ff ff       	call   f01005a1 <serial_intr>
	kbd_intr();
f01005da:	e8 de ff ff ff       	call   f01005bd <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01005df:	a1 20 a2 22 f0       	mov    0xf022a220,%eax
f01005e4:	3b 05 24 a2 22 f0    	cmp    0xf022a224,%eax
f01005ea:	74 26                	je     f0100612 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01005ec:	8d 50 01             	lea    0x1(%eax),%edx
f01005ef:	89 15 20 a2 22 f0    	mov    %edx,0xf022a220
f01005f5:	0f b6 88 20 a0 22 f0 	movzbl -0xfdd5fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01005fc:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01005fe:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100604:	75 11                	jne    f0100617 <cons_getc+0x48>
			cons.rpos = 0;
f0100606:	c7 05 20 a2 22 f0 00 	movl   $0x0,0xf022a220
f010060d:	00 00 00 
f0100610:	eb 05                	jmp    f0100617 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100612:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100617:	c9                   	leave  
f0100618:	c3                   	ret    

f0100619 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100619:	55                   	push   %ebp
f010061a:	89 e5                	mov    %esp,%ebp
f010061c:	57                   	push   %edi
f010061d:	56                   	push   %esi
f010061e:	53                   	push   %ebx
f010061f:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100622:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100629:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100630:	5a a5 
	if (*cp != 0xA55A) {
f0100632:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100639:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010063d:	74 11                	je     f0100650 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010063f:	c7 05 30 a2 22 f0 b4 	movl   $0x3b4,0xf022a230
f0100646:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100649:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010064e:	eb 16                	jmp    f0100666 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100650:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100657:	c7 05 30 a2 22 f0 d4 	movl   $0x3d4,0xf022a230
f010065e:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100661:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100666:	8b 3d 30 a2 22 f0    	mov    0xf022a230,%edi
f010066c:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100671:	89 fa                	mov    %edi,%edx
f0100673:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100674:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100677:	89 da                	mov    %ebx,%edx
f0100679:	ec                   	in     (%dx),%al
f010067a:	0f b6 c8             	movzbl %al,%ecx
f010067d:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100680:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100685:	89 fa                	mov    %edi,%edx
f0100687:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100688:	89 da                	mov    %ebx,%edx
f010068a:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010068b:	89 35 2c a2 22 f0    	mov    %esi,0xf022a22c
	crt_pos = pos;
f0100691:	0f b6 c0             	movzbl %al,%eax
f0100694:	09 c8                	or     %ecx,%eax
f0100696:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f010069c:	e8 1c ff ff ff       	call   f01005bd <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f01006a1:	83 ec 0c             	sub    $0xc,%esp
f01006a4:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f01006ab:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006b0:	50                   	push   %eax
f01006b1:	e8 ba 2e 00 00       	call   f0103570 <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006b6:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c0:	89 f2                	mov    %esi,%edx
f01006c2:	ee                   	out    %al,(%dx)
f01006c3:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01006c8:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006cd:	ee                   	out    %al,(%dx)
f01006ce:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01006d3:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006d8:	89 da                	mov    %ebx,%edx
f01006da:	ee                   	out    %al,(%dx)
f01006db:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01006e0:	b8 00 00 00 00       	mov    $0x0,%eax
f01006e5:	ee                   	out    %al,(%dx)
f01006e6:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01006eb:	b8 03 00 00 00       	mov    $0x3,%eax
f01006f0:	ee                   	out    %al,(%dx)
f01006f1:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01006f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01006fb:	ee                   	out    %al,(%dx)
f01006fc:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100701:	b8 01 00 00 00       	mov    $0x1,%eax
f0100706:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100707:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010070c:	ec                   	in     (%dx),%al
f010070d:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010070f:	83 c4 10             	add    $0x10,%esp
f0100712:	3c ff                	cmp    $0xff,%al
f0100714:	0f 95 05 34 a2 22 f0 	setne  0xf022a234
f010071b:	89 f2                	mov    %esi,%edx
f010071d:	ec                   	in     (%dx),%al
f010071e:	89 da                	mov    %ebx,%edx
f0100720:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100721:	80 f9 ff             	cmp    $0xff,%cl
f0100724:	75 10                	jne    f0100736 <cons_init+0x11d>
		cprintf("Serial port does not exist!\n");
f0100726:	83 ec 0c             	sub    $0xc,%esp
f0100729:	68 2f 5a 10 f0       	push   $0xf0105a2f
f010072e:	e8 8e 2f 00 00       	call   f01036c1 <cprintf>
f0100733:	83 c4 10             	add    $0x10,%esp
}
f0100736:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100739:	5b                   	pop    %ebx
f010073a:	5e                   	pop    %esi
f010073b:	5f                   	pop    %edi
f010073c:	5d                   	pop    %ebp
f010073d:	c3                   	ret    

f010073e <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010073e:	55                   	push   %ebp
f010073f:	89 e5                	mov    %esp,%ebp
f0100741:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100744:	8b 45 08             	mov    0x8(%ebp),%eax
f0100747:	e8 6c fc ff ff       	call   f01003b8 <cons_putc>
}
f010074c:	c9                   	leave  
f010074d:	c3                   	ret    

f010074e <getchar>:

int
getchar(void)
{
f010074e:	55                   	push   %ebp
f010074f:	89 e5                	mov    %esp,%ebp
f0100751:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100754:	e8 76 fe ff ff       	call   f01005cf <cons_getc>
f0100759:	85 c0                	test   %eax,%eax
f010075b:	74 f7                	je     f0100754 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010075d:	c9                   	leave  
f010075e:	c3                   	ret    

f010075f <iscons>:

int
iscons(int fdnum)
{
f010075f:	55                   	push   %ebp
f0100760:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100762:	b8 01 00 00 00       	mov    $0x1,%eax
f0100767:	5d                   	pop    %ebp
f0100768:	c3                   	ret    

f0100769 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100769:	55                   	push   %ebp
f010076a:	89 e5                	mov    %esp,%ebp
f010076c:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010076f:	68 80 5c 10 f0       	push   $0xf0105c80
f0100774:	68 9e 5c 10 f0       	push   $0xf0105c9e
f0100779:	68 a3 5c 10 f0       	push   $0xf0105ca3
f010077e:	e8 3e 2f 00 00       	call   f01036c1 <cprintf>
f0100783:	83 c4 0c             	add    $0xc,%esp
f0100786:	68 38 5d 10 f0       	push   $0xf0105d38
f010078b:	68 ac 5c 10 f0       	push   $0xf0105cac
f0100790:	68 a3 5c 10 f0       	push   $0xf0105ca3
f0100795:	e8 27 2f 00 00       	call   f01036c1 <cprintf>
f010079a:	83 c4 0c             	add    $0xc,%esp
f010079d:	68 60 5d 10 f0       	push   $0xf0105d60
f01007a2:	68 b5 5c 10 f0       	push   $0xf0105cb5
f01007a7:	68 a3 5c 10 f0       	push   $0xf0105ca3
f01007ac:	e8 10 2f 00 00       	call   f01036c1 <cprintf>
	return 0;
}
f01007b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b6:	c9                   	leave  
f01007b7:	c3                   	ret    

f01007b8 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007b8:	55                   	push   %ebp
f01007b9:	89 e5                	mov    %esp,%ebp
f01007bb:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007be:	68 bf 5c 10 f0       	push   $0xf0105cbf
f01007c3:	e8 f9 2e 00 00       	call   f01036c1 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007c8:	83 c4 08             	add    $0x8,%esp
f01007cb:	68 0c 00 10 00       	push   $0x10000c
f01007d0:	68 88 5d 10 f0       	push   $0xf0105d88
f01007d5:	e8 e7 2e 00 00       	call   f01036c1 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007da:	83 c4 0c             	add    $0xc,%esp
f01007dd:	68 0c 00 10 00       	push   $0x10000c
f01007e2:	68 0c 00 10 f0       	push   $0xf010000c
f01007e7:	68 b0 5d 10 f0       	push   $0xf0105db0
f01007ec:	e8 d0 2e 00 00       	call   f01036c1 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007f1:	83 c4 0c             	add    $0xc,%esp
f01007f4:	68 51 59 10 00       	push   $0x105951
f01007f9:	68 51 59 10 f0       	push   $0xf0105951
f01007fe:	68 d4 5d 10 f0       	push   $0xf0105dd4
f0100803:	e8 b9 2e 00 00       	call   f01036c1 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100808:	83 c4 0c             	add    $0xc,%esp
f010080b:	68 98 95 22 00       	push   $0x229598
f0100810:	68 98 95 22 f0       	push   $0xf0229598
f0100815:	68 f8 5d 10 f0       	push   $0xf0105df8
f010081a:	e8 a2 2e 00 00       	call   f01036c1 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010081f:	83 c4 0c             	add    $0xc,%esp
f0100822:	68 08 c0 26 00       	push   $0x26c008
f0100827:	68 08 c0 26 f0       	push   $0xf026c008
f010082c:	68 1c 5e 10 f0       	push   $0xf0105e1c
f0100831:	e8 8b 2e 00 00       	call   f01036c1 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100836:	b8 07 c4 26 f0       	mov    $0xf026c407,%eax
f010083b:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100840:	83 c4 08             	add    $0x8,%esp
f0100843:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100848:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010084e:	85 c0                	test   %eax,%eax
f0100850:	0f 48 c2             	cmovs  %edx,%eax
f0100853:	c1 f8 0a             	sar    $0xa,%eax
f0100856:	50                   	push   %eax
f0100857:	68 40 5e 10 f0       	push   $0xf0105e40
f010085c:	e8 60 2e 00 00       	call   f01036c1 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100861:	b8 00 00 00 00       	mov    $0x0,%eax
f0100866:	c9                   	leave  
f0100867:	c3                   	ret    

f0100868 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100868:	55                   	push   %ebp
f0100869:	89 e5                	mov    %esp,%ebp
f010086b:	57                   	push   %edi
f010086c:	56                   	push   %esi
f010086d:	53                   	push   %ebx
f010086e:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100871:	89 eb                	mov    %ebp,%ebx
	struct Eipdebuginfo info;        
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();

	cprintf("Stack backtrace:\r\n");
f0100873:	68 d8 5c 10 f0       	push   $0xf0105cd8
f0100878:	e8 44 2e 00 00       	call   f01036c1 <cprintf>
	while (ebp != 0)
f010087d:	83 c4 10             	add    $0x10,%esp
	{
		eip = ebp[1];
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]); //%08x 补0输出8位16进制数
		debuginfo_eip((uintptr_t)eip, &info);
f0100880:	8d 7d d0             	lea    -0x30(%ebp),%edi
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();

	cprintf("Stack backtrace:\r\n");
	while (ebp != 0)
f0100883:	eb 53                	jmp    f01008d8 <mon_backtrace+0x70>
	{
		eip = ebp[1];
f0100885:	8b 73 04             	mov    0x4(%ebx),%esi
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]); //%08x 补0输出8位16进制数
f0100888:	ff 73 18             	pushl  0x18(%ebx)
f010088b:	ff 73 14             	pushl  0x14(%ebx)
f010088e:	ff 73 10             	pushl  0x10(%ebx)
f0100891:	ff 73 0c             	pushl  0xc(%ebx)
f0100894:	ff 73 08             	pushl  0x8(%ebx)
f0100897:	56                   	push   %esi
f0100898:	53                   	push   %ebx
f0100899:	68 6c 5e 10 f0       	push   $0xf0105e6c
f010089e:	e8 1e 2e 00 00       	call   f01036c1 <cprintf>
		debuginfo_eip((uintptr_t)eip, &info);
f01008a3:	83 c4 18             	add    $0x18,%esp
f01008a6:	57                   	push   %edi
f01008a7:	56                   	push   %esi
f01008a8:	e8 d3 39 00 00       	call   f0104280 <debuginfo_eip>
		cprintf("%s:%d", info.eip_file, info.eip_line);
f01008ad:	83 c4 0c             	add    $0xc,%esp
f01008b0:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008b3:	ff 75 d0             	pushl  -0x30(%ebp)
f01008b6:	68 eb 5c 10 f0       	push   $0xf0105ceb
f01008bb:	e8 01 2e 00 00       	call   f01036c1 <cprintf>
		cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name, info.eip_fn_addr);
f01008c0:	ff 75 e0             	pushl  -0x20(%ebp)
f01008c3:	ff 75 d8             	pushl  -0x28(%ebp)
f01008c6:	ff 75 dc             	pushl  -0x24(%ebp)
f01008c9:	68 f1 5c 10 f0       	push   $0xf0105cf1
f01008ce:	e8 ee 2d 00 00       	call   f01036c1 <cprintf>
		ebp = (uint32_t *)ebp[0];
f01008d3:	8b 1b                	mov    (%ebx),%ebx
f01008d5:	83 c4 20             	add    $0x20,%esp
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();

	cprintf("Stack backtrace:\r\n");
	while (ebp != 0)
f01008d8:	85 db                	test   %ebx,%ebx
f01008da:	75 a9                	jne    f0100885 <mon_backtrace+0x1d>
		cprintf("%s:%d", info.eip_file, info.eip_line);
		cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name, info.eip_fn_addr);
		ebp = (uint32_t *)ebp[0];
	}
	return 0;
}
f01008dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01008e1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008e4:	5b                   	pop    %ebx
f01008e5:	5e                   	pop    %esi
f01008e6:	5f                   	pop    %edi
f01008e7:	5d                   	pop    %ebp
f01008e8:	c3                   	ret    

f01008e9 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008e9:	55                   	push   %ebp
f01008ea:	89 e5                	mov    %esp,%ebp
f01008ec:	57                   	push   %edi
f01008ed:	56                   	push   %esi
f01008ee:	53                   	push   %ebx
f01008ef:	83 ec 58             	sub    $0x58,%esp
	char *buf; 
	cprintf("Welcome to the JOS kernel monitor!\n");
f01008f2:	68 a4 5e 10 f0       	push   $0xf0105ea4
f01008f7:	e8 c5 2d 00 00       	call   f01036c1 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008fc:	c7 04 24 c8 5e 10 f0 	movl   $0xf0105ec8,(%esp)
f0100903:	e8 b9 2d 00 00       	call   f01036c1 <cprintf>

	if (tf != NULL)
f0100908:	83 c4 10             	add    $0x10,%esp
f010090b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010090f:	74 0e                	je     f010091f <monitor+0x36>
		print_trapframe(tf);
f0100911:	83 ec 0c             	sub    $0xc,%esp
f0100914:	ff 75 08             	pushl  0x8(%ebp)
f0100917:	e8 d6 31 00 00       	call   f0103af2 <print_trapframe>
f010091c:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f010091f:	83 ec 0c             	sub    $0xc,%esp
f0100922:	68 fc 5c 10 f0       	push   $0xf0105cfc
f0100927:	e8 32 41 00 00       	call   f0104a5e <readline>
f010092c:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010092e:	83 c4 10             	add    $0x10,%esp
f0100931:	85 c0                	test   %eax,%eax
f0100933:	74 ea                	je     f010091f <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100935:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010093c:	be 00 00 00 00       	mov    $0x0,%esi
f0100941:	eb 0a                	jmp    f010094d <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100943:	c6 03 00             	movb   $0x0,(%ebx)
f0100946:	89 f7                	mov    %esi,%edi
f0100948:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010094b:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010094d:	0f b6 03             	movzbl (%ebx),%eax
f0100950:	84 c0                	test   %al,%al
f0100952:	74 63                	je     f01009b7 <monitor+0xce>
f0100954:	83 ec 08             	sub    $0x8,%esp
f0100957:	0f be c0             	movsbl %al,%eax
f010095a:	50                   	push   %eax
f010095b:	68 00 5d 10 f0       	push   $0xf0105d00
f0100960:	e8 13 43 00 00       	call   f0104c78 <strchr>
f0100965:	83 c4 10             	add    $0x10,%esp
f0100968:	85 c0                	test   %eax,%eax
f010096a:	75 d7                	jne    f0100943 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f010096c:	80 3b 00             	cmpb   $0x0,(%ebx)
f010096f:	74 46                	je     f01009b7 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100971:	83 fe 0f             	cmp    $0xf,%esi
f0100974:	75 14                	jne    f010098a <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100976:	83 ec 08             	sub    $0x8,%esp
f0100979:	6a 10                	push   $0x10
f010097b:	68 05 5d 10 f0       	push   $0xf0105d05
f0100980:	e8 3c 2d 00 00       	call   f01036c1 <cprintf>
f0100985:	83 c4 10             	add    $0x10,%esp
f0100988:	eb 95                	jmp    f010091f <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f010098a:	8d 7e 01             	lea    0x1(%esi),%edi
f010098d:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100991:	eb 03                	jmp    f0100996 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100993:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100996:	0f b6 03             	movzbl (%ebx),%eax
f0100999:	84 c0                	test   %al,%al
f010099b:	74 ae                	je     f010094b <monitor+0x62>
f010099d:	83 ec 08             	sub    $0x8,%esp
f01009a0:	0f be c0             	movsbl %al,%eax
f01009a3:	50                   	push   %eax
f01009a4:	68 00 5d 10 f0       	push   $0xf0105d00
f01009a9:	e8 ca 42 00 00       	call   f0104c78 <strchr>
f01009ae:	83 c4 10             	add    $0x10,%esp
f01009b1:	85 c0                	test   %eax,%eax
f01009b3:	74 de                	je     f0100993 <monitor+0xaa>
f01009b5:	eb 94                	jmp    f010094b <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01009b7:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009be:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009bf:	85 f6                	test   %esi,%esi
f01009c1:	0f 84 58 ff ff ff    	je     f010091f <monitor+0x36>
f01009c7:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009cc:	83 ec 08             	sub    $0x8,%esp
f01009cf:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009d2:	ff 34 85 00 5f 10 f0 	pushl  -0xfefa100(,%eax,4)
f01009d9:	ff 75 a8             	pushl  -0x58(%ebp)
f01009dc:	e8 39 42 00 00       	call   f0104c1a <strcmp>
f01009e1:	83 c4 10             	add    $0x10,%esp
f01009e4:	85 c0                	test   %eax,%eax
f01009e6:	75 21                	jne    f0100a09 <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f01009e8:	83 ec 04             	sub    $0x4,%esp
f01009eb:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009ee:	ff 75 08             	pushl  0x8(%ebp)
f01009f1:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01009f4:	52                   	push   %edx
f01009f5:	56                   	push   %esi
f01009f6:	ff 14 85 08 5f 10 f0 	call   *-0xfefa0f8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01009fd:	83 c4 10             	add    $0x10,%esp
f0100a00:	85 c0                	test   %eax,%eax
f0100a02:	78 25                	js     f0100a29 <monitor+0x140>
f0100a04:	e9 16 ff ff ff       	jmp    f010091f <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100a09:	83 c3 01             	add    $0x1,%ebx
f0100a0c:	83 fb 03             	cmp    $0x3,%ebx
f0100a0f:	75 bb                	jne    f01009cc <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a11:	83 ec 08             	sub    $0x8,%esp
f0100a14:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a17:	68 22 5d 10 f0       	push   $0xf0105d22
f0100a1c:	e8 a0 2c 00 00       	call   f01036c1 <cprintf>
f0100a21:	83 c4 10             	add    $0x10,%esp
f0100a24:	e9 f6 fe ff ff       	jmp    f010091f <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a29:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a2c:	5b                   	pop    %ebx
f0100a2d:	5e                   	pop    %esi
f0100a2e:	5f                   	pop    %edi
f0100a2f:	5d                   	pop    %ebp
f0100a30:	c3                   	ret    

f0100a31 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a31:	55                   	push   %ebp
f0100a32:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a34:	83 3d 38 a2 22 f0 00 	cmpl   $0x0,0xf022a238
f0100a3b:	75 11                	jne    f0100a4e <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a3d:	ba 07 d0 26 f0       	mov    $0xf026d007,%edx
f0100a42:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a48:	89 15 38 a2 22 f0    	mov    %edx,0xf022a238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100a4e:	8b 0d 38 a2 22 f0    	mov    0xf022a238,%ecx
	nextfree += n;
	nextfree = ROUNDUP( (char*)nextfree, PGSIZE);
f0100a54:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100a5b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a61:	89 15 38 a2 22 f0    	mov    %edx,0xf022a238
	//nextfree += ROUNDUP(n,PGSIZE);
	return result;
}
f0100a67:	89 c8                	mov    %ecx,%eax
f0100a69:	5d                   	pop    %ebp
f0100a6a:	c3                   	ret    

f0100a6b <check_va2pa>:
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];

	if (!(*pgdir & PTE_P))
f0100a6b:	89 d1                	mov    %edx,%ecx
f0100a6d:	c1 e9 16             	shr    $0x16,%ecx
f0100a70:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a73:	a8 01                	test   $0x1,%al
f0100a75:	74 52                	je     f0100ac9 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a77:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a7c:	89 c1                	mov    %eax,%ecx
f0100a7e:	c1 e9 0c             	shr    $0xc,%ecx
f0100a81:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0100a87:	72 1b                	jb     f0100aa4 <check_va2pa+0x39>
// defined by the page directory 'pgdir'.  The hardware normally performs
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a89:	55                   	push   %ebp
f0100a8a:	89 e5                	mov    %esp,%ebp
f0100a8c:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a8f:	50                   	push   %eax
f0100a90:	68 84 59 10 f0       	push   $0xf0105984
f0100a95:	68 da 03 00 00       	push   $0x3da
f0100a9a:	68 55 68 10 f0       	push   $0xf0106855
f0100a9f:	e8 9c f5 ff ff       	call   f0100040 <_panic>
	pgdir = &pgdir[PDX(va)];

	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100aa4:	c1 ea 0c             	shr    $0xc,%edx
f0100aa7:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100aad:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100ab4:	89 c2                	mov    %eax,%edx
f0100ab6:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100ab9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100abe:	85 d2                	test   %edx,%edx
f0100ac0:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100ac5:	0f 44 c2             	cmove  %edx,%eax
f0100ac8:	c3                   	ret    
	pte_t *p;

	pgdir = &pgdir[PDX(va)];

	if (!(*pgdir & PTE_P))
		return ~0;
f0100ac9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100ace:	c3                   	ret    

f0100acf <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100acf:	55                   	push   %ebp
f0100ad0:	89 e5                	mov    %esp,%ebp
f0100ad2:	57                   	push   %edi
f0100ad3:	56                   	push   %esi
f0100ad4:	53                   	push   %ebx
f0100ad5:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ad8:	84 c0                	test   %al,%al
f0100ada:	0f 85 91 02 00 00    	jne    f0100d71 <check_page_free_list+0x2a2>
f0100ae0:	e9 9e 02 00 00       	jmp    f0100d83 <check_page_free_list+0x2b4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100ae5:	83 ec 04             	sub    $0x4,%esp
f0100ae8:	68 24 5f 10 f0       	push   $0xf0105f24
f0100aed:	68 0f 03 00 00       	push   $0x30f
f0100af2:	68 55 68 10 f0       	push   $0xf0106855
f0100af7:	e8 44 f5 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100afc:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100aff:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b02:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b05:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b08:	89 c2                	mov    %eax,%edx
f0100b0a:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0100b10:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b16:	0f 95 c2             	setne  %dl
f0100b19:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b1c:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b20:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b22:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b26:	8b 00                	mov    (%eax),%eax
f0100b28:	85 c0                	test   %eax,%eax
f0100b2a:	75 dc                	jne    f0100b08 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b2c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b2f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b35:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b38:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b3b:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b3d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b40:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b45:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b4a:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f0100b50:	eb 53                	jmp    f0100ba5 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b52:	89 d8                	mov    %ebx,%eax
f0100b54:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100b5a:	c1 f8 03             	sar    $0x3,%eax
f0100b5d:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b60:	89 c2                	mov    %eax,%edx
f0100b62:	c1 ea 16             	shr    $0x16,%edx
f0100b65:	39 f2                	cmp    %esi,%edx
f0100b67:	73 3a                	jae    f0100ba3 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b69:	89 c2                	mov    %eax,%edx
f0100b6b:	c1 ea 0c             	shr    $0xc,%edx
f0100b6e:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100b74:	72 12                	jb     f0100b88 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b76:	50                   	push   %eax
f0100b77:	68 84 59 10 f0       	push   $0xf0105984
f0100b7c:	6a 58                	push   $0x58
f0100b7e:	68 61 68 10 f0       	push   $0xf0106861
f0100b83:	e8 b8 f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b88:	83 ec 04             	sub    $0x4,%esp
f0100b8b:	68 80 00 00 00       	push   $0x80
f0100b90:	68 97 00 00 00       	push   $0x97
f0100b95:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b9a:	50                   	push   %eax
f0100b9b:	e8 15 41 00 00       	call   f0104cb5 <memset>
f0100ba0:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ba3:	8b 1b                	mov    (%ebx),%ebx
f0100ba5:	85 db                	test   %ebx,%ebx
f0100ba7:	75 a9                	jne    f0100b52 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100ba9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bae:	e8 7e fe ff ff       	call   f0100a31 <boot_alloc>
f0100bb3:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bb6:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bbc:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
		assert(pp < pages + npages);
f0100bc2:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0100bc7:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100bca:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100bcd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bd0:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100bd3:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bd8:	e9 52 01 00 00       	jmp    f0100d2f <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bdd:	39 ca                	cmp    %ecx,%edx
f0100bdf:	73 19                	jae    f0100bfa <check_page_free_list+0x12b>
f0100be1:	68 6f 68 10 f0       	push   $0xf010686f
f0100be6:	68 7b 68 10 f0       	push   $0xf010687b
f0100beb:	68 29 03 00 00       	push   $0x329
f0100bf0:	68 55 68 10 f0       	push   $0xf0106855
f0100bf5:	e8 46 f4 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100bfa:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bfd:	72 19                	jb     f0100c18 <check_page_free_list+0x149>
f0100bff:	68 90 68 10 f0       	push   $0xf0106890
f0100c04:	68 7b 68 10 f0       	push   $0xf010687b
f0100c09:	68 2a 03 00 00       	push   $0x32a
f0100c0e:	68 55 68 10 f0       	push   $0xf0106855
f0100c13:	e8 28 f4 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c18:	89 d0                	mov    %edx,%eax
f0100c1a:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c1d:	a8 07                	test   $0x7,%al
f0100c1f:	74 19                	je     f0100c3a <check_page_free_list+0x16b>
f0100c21:	68 48 5f 10 f0       	push   $0xf0105f48
f0100c26:	68 7b 68 10 f0       	push   $0xf010687b
f0100c2b:	68 2b 03 00 00       	push   $0x32b
f0100c30:	68 55 68 10 f0       	push   $0xf0106855
f0100c35:	e8 06 f4 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c3a:	c1 f8 03             	sar    $0x3,%eax
f0100c3d:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c40:	85 c0                	test   %eax,%eax
f0100c42:	75 19                	jne    f0100c5d <check_page_free_list+0x18e>
f0100c44:	68 a4 68 10 f0       	push   $0xf01068a4
f0100c49:	68 7b 68 10 f0       	push   $0xf010687b
f0100c4e:	68 2e 03 00 00       	push   $0x32e
f0100c53:	68 55 68 10 f0       	push   $0xf0106855
f0100c58:	e8 e3 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c5d:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c62:	75 19                	jne    f0100c7d <check_page_free_list+0x1ae>
f0100c64:	68 b5 68 10 f0       	push   $0xf01068b5
f0100c69:	68 7b 68 10 f0       	push   $0xf010687b
f0100c6e:	68 2f 03 00 00       	push   $0x32f
f0100c73:	68 55 68 10 f0       	push   $0xf0106855
f0100c78:	e8 c3 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c7d:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c82:	75 19                	jne    f0100c9d <check_page_free_list+0x1ce>
f0100c84:	68 7c 5f 10 f0       	push   $0xf0105f7c
f0100c89:	68 7b 68 10 f0       	push   $0xf010687b
f0100c8e:	68 30 03 00 00       	push   $0x330
f0100c93:	68 55 68 10 f0       	push   $0xf0106855
f0100c98:	e8 a3 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c9d:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100ca2:	75 19                	jne    f0100cbd <check_page_free_list+0x1ee>
f0100ca4:	68 ce 68 10 f0       	push   $0xf01068ce
f0100ca9:	68 7b 68 10 f0       	push   $0xf010687b
f0100cae:	68 31 03 00 00       	push   $0x331
f0100cb3:	68 55 68 10 f0       	push   $0xf0106855
f0100cb8:	e8 83 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cbd:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cc2:	0f 86 de 00 00 00    	jbe    f0100da6 <check_page_free_list+0x2d7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cc8:	89 c7                	mov    %eax,%edi
f0100cca:	c1 ef 0c             	shr    $0xc,%edi
f0100ccd:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100cd0:	77 12                	ja     f0100ce4 <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cd2:	50                   	push   %eax
f0100cd3:	68 84 59 10 f0       	push   $0xf0105984
f0100cd8:	6a 58                	push   $0x58
f0100cda:	68 61 68 10 f0       	push   $0xf0106861
f0100cdf:	e8 5c f3 ff ff       	call   f0100040 <_panic>
f0100ce4:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100cea:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100ced:	0f 86 a7 00 00 00    	jbe    f0100d9a <check_page_free_list+0x2cb>
f0100cf3:	68 a0 5f 10 f0       	push   $0xf0105fa0
f0100cf8:	68 7b 68 10 f0       	push   $0xf010687b
f0100cfd:	68 32 03 00 00       	push   $0x332
f0100d02:	68 55 68 10 f0       	push   $0xf0106855
f0100d07:	e8 34 f3 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d0c:	68 e8 68 10 f0       	push   $0xf01068e8
f0100d11:	68 7b 68 10 f0       	push   $0xf010687b
f0100d16:	68 34 03 00 00       	push   $0x334
f0100d1b:	68 55 68 10 f0       	push   $0xf0106855
f0100d20:	e8 1b f3 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d25:	83 c6 01             	add    $0x1,%esi
f0100d28:	eb 03                	jmp    f0100d2d <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100d2a:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d2d:	8b 12                	mov    (%edx),%edx
f0100d2f:	85 d2                	test   %edx,%edx
f0100d31:	0f 85 a6 fe ff ff    	jne    f0100bdd <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d37:	85 f6                	test   %esi,%esi
f0100d39:	7f 19                	jg     f0100d54 <check_page_free_list+0x285>
f0100d3b:	68 05 69 10 f0       	push   $0xf0106905
f0100d40:	68 7b 68 10 f0       	push   $0xf010687b
f0100d45:	68 3c 03 00 00       	push   $0x33c
f0100d4a:	68 55 68 10 f0       	push   $0xf0106855
f0100d4f:	e8 ec f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100d54:	85 db                	test   %ebx,%ebx
f0100d56:	7f 5e                	jg     f0100db6 <check_page_free_list+0x2e7>
f0100d58:	68 17 69 10 f0       	push   $0xf0106917
f0100d5d:	68 7b 68 10 f0       	push   $0xf010687b
f0100d62:	68 3d 03 00 00       	push   $0x33d
f0100d67:	68 55 68 10 f0       	push   $0xf0106855
f0100d6c:	e8 cf f2 ff ff       	call   f0100040 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d71:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0100d76:	85 c0                	test   %eax,%eax
f0100d78:	0f 85 7e fd ff ff    	jne    f0100afc <check_page_free_list+0x2d>
f0100d7e:	e9 62 fd ff ff       	jmp    f0100ae5 <check_page_free_list+0x16>
f0100d83:	83 3d 40 a2 22 f0 00 	cmpl   $0x0,0xf022a240
f0100d8a:	0f 84 55 fd ff ff    	je     f0100ae5 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d90:	be 00 04 00 00       	mov    $0x400,%esi
f0100d95:	e9 b0 fd ff ff       	jmp    f0100b4a <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d9a:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100d9f:	75 89                	jne    f0100d2a <check_page_free_list+0x25b>
f0100da1:	e9 66 ff ff ff       	jmp    f0100d0c <check_page_free_list+0x23d>
f0100da6:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100dab:	0f 85 74 ff ff ff    	jne    f0100d25 <check_page_free_list+0x256>
f0100db1:	e9 56 ff ff ff       	jmp    f0100d0c <check_page_free_list+0x23d>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100db6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100db9:	5b                   	pop    %ebx
f0100dba:	5e                   	pop    %esi
f0100dbb:	5f                   	pop    %edi
f0100dbc:	5d                   	pop    %ebp
f0100dbd:	c3                   	ret    

f0100dbe <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100dbe:	55                   	push   %ebp
f0100dbf:	89 e5                	mov    %esp,%ebp
f0100dc1:	56                   	push   %esi
f0100dc2:	53                   	push   %ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!

	//  1) Mark physical page 0 as in use.
	pages[0].pp_ref = 1;
f0100dc3:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0100dc8:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;	
f0100dce:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	size_t i;
	//临界点是否等于可能存在问题
	for (i = 1; i < npages; i++) {
f0100dd4:	be 08 00 00 00       	mov    $0x8,%esi
f0100dd9:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100dde:	e9 c7 00 00 00       	jmp    f0100eaa <page_init+0xec>
		//lab4
		if (i == ROUNDUP(MPENTRY_PADDR, PGSIZE) / PGSIZE) {
f0100de3:	83 fb 07             	cmp    $0x7,%ebx
f0100de6:	75 17                	jne    f0100dff <page_init+0x41>
        	pages[i].pp_ref = 1;
f0100de8:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0100ded:	66 c7 40 3c 01 00    	movw   $0x1,0x3c(%eax)
			pages[i].pp_link = NULL;
f0100df3:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
        	continue;
f0100dfa:	e9 a5 00 00 00       	jmp    f0100ea4 <page_init+0xe6>
    	}

		
	//  2) The rest of base memory
		if(i < npages_basemem){
f0100dff:	3b 1d 44 a2 22 f0    	cmp    0xf022a244,%ebx
f0100e05:	73 25                	jae    f0100e2c <page_init+0x6e>
			pages[i].pp_ref = 0;
f0100e07:	89 f0                	mov    %esi,%eax
f0100e09:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100e0f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100e15:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100e1b:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100e1d:	89 f0                	mov    %esi,%eax
f0100e1f:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100e25:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
f0100e2a:	eb 78                	jmp    f0100ea4 <page_init+0xe6>
		}
	//  3) Then comes the IO hole 
		else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE){
f0100e2c:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100e32:	83 f8 5f             	cmp    $0x5f,%eax
f0100e35:	77 16                	ja     f0100e4d <page_init+0x8f>
			pages[i].pp_ref = 1;
f0100e37:	89 f0                	mov    %esi,%eax
f0100e39:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100e3f:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100e45:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100e4b:	eb 57                	jmp    f0100ea4 <page_init+0xe6>
		}
	//  4) Then extended memory
		else if(i >= EXTPHYSMEM/PGSIZE && i< ((int)boot_alloc(0) - KERNBASE)/PGSIZE){
f0100e4d:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100e53:	76 2c                	jbe    f0100e81 <page_init+0xc3>
f0100e55:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e5a:	e8 d2 fb ff ff       	call   f0100a31 <boot_alloc>
f0100e5f:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e64:	c1 e8 0c             	shr    $0xc,%eax
f0100e67:	39 c3                	cmp    %eax,%ebx
f0100e69:	73 16                	jae    f0100e81 <page_init+0xc3>
			pages[i].pp_ref = 1;
f0100e6b:	89 f0                	mov    %esi,%eax
f0100e6d:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100e73:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100e79:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100e7f:	eb 23                	jmp    f0100ea4 <page_init+0xe6>
		}
		else{
			pages[i].pp_ref = 0;
f0100e81:	89 f0                	mov    %esi,%eax
f0100e83:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100e89:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100e8f:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100e95:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100e97:	89 f0                	mov    %esi,%eax
f0100e99:	03 05 90 ae 22 f0    	add    0xf022ae90,%eax
f0100e9f:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
	//  1) Mark physical page 0 as in use.
	pages[0].pp_ref = 1;
	pages[0].pp_link = NULL;	
	size_t i;
	//临界点是否等于可能存在问题
	for (i = 1; i < npages; i++) {
f0100ea4:	83 c3 01             	add    $0x1,%ebx
f0100ea7:	83 c6 08             	add    $0x8,%esi
f0100eaa:	3b 1d 88 ae 22 f0    	cmp    0xf022ae88,%ebx
f0100eb0:	0f 82 2d ff ff ff    	jb     f0100de3 <page_init+0x25>

	//要在循环里判断，否者该项以及在page_free_list中
	//i = ROUNDUP(MPENTRY_PADDR, PGSIZE) / PGSIZE;
	//pages[i].pp_ref = 1;
	//pages[i].pp_link = NULL;
}
f0100eb6:	5b                   	pop    %ebx
f0100eb7:	5e                   	pop    %esi
f0100eb8:	5d                   	pop    %ebp
f0100eb9:	c3                   	ret    

f0100eba <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100eba:	55                   	push   %ebp
f0100ebb:	89 e5                	mov    %esp,%ebp
f0100ebd:	53                   	push   %ebx
f0100ebe:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if(page_free_list == NULL)
f0100ec1:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f0100ec7:	85 db                	test   %ebx,%ebx
f0100ec9:	74 6e                	je     f0100f39 <page_alloc+0x7f>
		//addr = page2kva(page_free_list);
		//int *iq,*ip;
		//iq=ip;//将把ip中的值拷贝到iq中，这样，指针iq也将指向ip指向的对象
		struct PageInfo *Page;
		Page = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100ecb:	8b 03                	mov    (%ebx),%eax
f0100ecd:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
		//page_free_list->pp_link = NULL;
		Page->pp_link = NULL;
f0100ed2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		//Page->pp_ref = 1;
		Page->pp_ref = 0;
f0100ed8:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		cprintf("page_alloc\r\n");
f0100ede:	83 ec 0c             	sub    $0xc,%esp
f0100ee1:	68 28 69 10 f0       	push   $0xf0106928
f0100ee6:	e8 d6 27 00 00       	call   f01036c1 <cprintf>
		if(alloc_flags & ALLOC_ZERO)
f0100eeb:	83 c4 10             	add    $0x10,%esp
f0100eee:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ef2:	74 45                	je     f0100f39 <page_alloc+0x7f>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ef4:	89 d8                	mov    %ebx,%eax
f0100ef6:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100efc:	c1 f8 03             	sar    $0x3,%eax
f0100eff:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f02:	89 c2                	mov    %eax,%edx
f0100f04:	c1 ea 0c             	shr    $0xc,%edx
f0100f07:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100f0d:	72 12                	jb     f0100f21 <page_alloc+0x67>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f0f:	50                   	push   %eax
f0100f10:	68 84 59 10 f0       	push   $0xf0105984
f0100f15:	6a 58                	push   $0x58
f0100f17:	68 61 68 10 f0       	push   $0xf0106861
f0100f1c:	e8 1f f1 ff ff       	call   f0100040 <_panic>
			memset(page2kva(Page),'\0',PGSIZE);
f0100f21:	83 ec 04             	sub    $0x4,%esp
f0100f24:	68 00 10 00 00       	push   $0x1000
f0100f29:	6a 00                	push   $0x0
f0100f2b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f30:	50                   	push   %eax
f0100f31:	e8 7f 3d 00 00       	call   f0104cb5 <memset>
f0100f36:	83 c4 10             	add    $0x10,%esp
			// memset(page2kva(page_free_list),0,PGSIZE);
		return Page;
	}
}
f0100f39:	89 d8                	mov    %ebx,%eax
f0100f3b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f3e:	c9                   	leave  
f0100f3f:	c3                   	ret    

f0100f40 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100f40:	55                   	push   %ebp
f0100f41:	89 e5                	mov    %esp,%ebp
f0100f43:	83 ec 14             	sub    $0x14,%esp
f0100f46:	8b 45 08             	mov    0x8(%ebp),%eax
	//  	panic("can't free the page");
	//  	return;
	// }
	//	cprinf("can't free the page");
	//pp->pp_link = page_free_list->pp_link;	
	pp->pp_link = page_free_list;
f0100f49:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100f4f:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f51:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
	//pp->pp_ref = 0;
	cprintf("page_free\r\n");
f0100f56:	68 35 69 10 f0       	push   $0xf0106935
f0100f5b:	e8 61 27 00 00       	call   f01036c1 <cprintf>
}
f0100f60:	83 c4 10             	add    $0x10,%esp
f0100f63:	c9                   	leave  
f0100f64:	c3                   	ret    

f0100f65 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100f65:	55                   	push   %ebp
f0100f66:	89 e5                	mov    %esp,%ebp
f0100f68:	83 ec 08             	sub    $0x8,%esp
f0100f6b:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100f6e:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100f72:	83 e8 01             	sub    $0x1,%eax
f0100f75:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100f79:	66 85 c0             	test   %ax,%ax
f0100f7c:	75 0c                	jne    f0100f8a <page_decref+0x25>
		page_free(pp);
f0100f7e:	83 ec 0c             	sub    $0xc,%esp
f0100f81:	52                   	push   %edx
f0100f82:	e8 b9 ff ff ff       	call   f0100f40 <page_free>
f0100f87:	83 c4 10             	add    $0x10,%esp
}
f0100f8a:	c9                   	leave  
f0100f8b:	c3                   	ret    

f0100f8c <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f8c:	55                   	push   %ebp
f0100f8d:	89 e5                	mov    %esp,%ebp
f0100f8f:	56                   	push   %esi
f0100f90:	53                   	push   %ebx
f0100f91:	8b 45 0c             	mov    0xc(%ebp),%eax
	// Fill this function in
	uint32_t pd_number,pt_number,pt_addr;//,page_number,page_addr;
	pte_t *pte = NULL;
	struct PageInfo *Page;
	pd_number = PDX(va);
	pt_number = PTX(va);
f0100f94:	89 c6                	mov    %eax,%esi
f0100f96:	c1 ee 0c             	shr    $0xc,%esi
f0100f99:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	if(pgdir[pd_number] & PTE_P)
f0100f9f:	c1 e8 16             	shr    $0x16,%eax
f0100fa2:	8d 1c 85 00 00 00 00 	lea    0x0(,%eax,4),%ebx
f0100fa9:	03 5d 08             	add    0x8(%ebp),%ebx
f0100fac:	8b 03                	mov    (%ebx),%eax
f0100fae:	a8 01                	test   $0x1,%al
f0100fb0:	74 2e                	je     f0100fe0 <pgdir_walk+0x54>
		pte = KADDR(PTE_ADDR(pgdir[pd_number]));
f0100fb2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fb7:	89 c2                	mov    %eax,%edx
f0100fb9:	c1 ea 0c             	shr    $0xc,%edx
f0100fbc:	39 15 88 ae 22 f0    	cmp    %edx,0xf022ae88
f0100fc2:	77 15                	ja     f0100fd9 <pgdir_walk+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fc4:	50                   	push   %eax
f0100fc5:	68 84 59 10 f0       	push   $0xf0105984
f0100fca:	68 c7 01 00 00       	push   $0x1c7
f0100fcf:	68 55 68 10 f0       	push   $0xf0106855
f0100fd4:	e8 67 f0 ff ff       	call   f0100040 <_panic>
	if(!pte){
f0100fd9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fde:	75 58                	jne    f0101038 <pgdir_walk+0xac>
		if(!create)
f0100fe0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100fe4:	74 57                	je     f010103d <pgdir_walk+0xb1>
	 		return NULL;
	 	Page = page_alloc(create);
f0100fe6:	83 ec 0c             	sub    $0xc,%esp
f0100fe9:	ff 75 10             	pushl  0x10(%ebp)
f0100fec:	e8 c9 fe ff ff       	call   f0100eba <page_alloc>
		if(!Page)
f0100ff1:	83 c4 10             	add    $0x10,%esp
f0100ff4:	85 c0                	test   %eax,%eax
f0100ff6:	74 4c                	je     f0101044 <pgdir_walk+0xb8>
			return NULL;
		Page->pp_ref ++;
f0100ff8:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ffd:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0101003:	89 c2                	mov    %eax,%edx
f0101005:	c1 fa 03             	sar    $0x3,%edx
f0101008:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010100b:	89 d0                	mov    %edx,%eax
f010100d:	c1 e8 0c             	shr    $0xc,%eax
f0101010:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0101016:	72 15                	jb     f010102d <pgdir_walk+0xa1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101018:	52                   	push   %edx
f0101019:	68 84 59 10 f0       	push   $0xf0105984
f010101e:	68 cf 01 00 00       	push   $0x1cf
f0101023:	68 55 68 10 f0       	push   $0xf0106855
f0101028:	e8 13 f0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010102d:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	 	pte = KADDR(page2pa(Page));		
		// pgdir[pd_number] = page2pa(Page);
		pgdir[pd_number] = page2pa(Page) | PTE_P | PTE_W | PTE_U;
f0101033:	83 ca 07             	or     $0x7,%edx
f0101036:	89 13                	mov    %edx,(%ebx)
	}
	return &(pte[pt_number]);
f0101038:	8d 04 b0             	lea    (%eax,%esi,4),%eax
f010103b:	eb 0c                	jmp    f0101049 <pgdir_walk+0xbd>
	pt_number = PTX(va);
	if(pgdir[pd_number] & PTE_P)
		pte = KADDR(PTE_ADDR(pgdir[pd_number]));
	if(!pte){
		if(!create)
	 		return NULL;
f010103d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101042:	eb 05                	jmp    f0101049 <pgdir_walk+0xbd>
	 	Page = page_alloc(create);
		if(!Page)
			return NULL;
f0101044:	b8 00 00 00 00       	mov    $0x0,%eax
	// //不确定page_alloc函数里应该填入的参数,page_alloc(int alloc_flags)
	// 	Page = page_alloc(create);
	// 	page_addr = page2pa(Page);
	// }
	// return page_addr;
}
f0101049:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010104c:	5b                   	pop    %ebx
f010104d:	5e                   	pop    %esi
f010104e:	5d                   	pop    %ebp
f010104f:	c3                   	ret    

f0101050 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101050:	55                   	push   %ebp
f0101051:	89 e5                	mov    %esp,%ebp
f0101053:	57                   	push   %edi
f0101054:	56                   	push   %esi
f0101055:	53                   	push   %ebx
f0101056:	83 ec 20             	sub    $0x20,%esp
f0101059:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010105c:	89 d7                	mov    %edx,%edi
f010105e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	pte_t *pte = NULL;
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
f0101061:	ff 75 08             	pushl  0x8(%ebp)
f0101064:	52                   	push   %edx
f0101065:	68 e8 5f 10 f0       	push   $0xf0105fe8
f010106a:	e8 52 26 00 00       	call   f01036c1 <cprintf>
	for(int i = 0;i < size;i += PGSIZE){
f010106f:	83 c4 10             	add    $0x10,%esp
f0101072:	bb 00 00 00 00       	mov    $0x0,%ebx
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
f0101077:	8b 45 0c             	mov    0xc(%ebp),%eax
f010107a:	83 c8 01             	or     $0x1,%eax
f010107d:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte = NULL;
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for(int i = 0;i < size;i += PGSIZE){
f0101080:	eb 1f                	jmp    f01010a1 <boot_map_region+0x51>
		pte = pgdir_walk(pgdir, (void *)va, 1);
f0101082:	83 ec 04             	sub    $0x4,%esp
f0101085:	6a 01                	push   $0x1
f0101087:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f010108a:	50                   	push   %eax
f010108b:	ff 75 e0             	pushl  -0x20(%ebp)
f010108e:	e8 f9 fe ff ff       	call   f0100f8c <pgdir_walk>
		*pte = (pa | perm | PTE_P);
f0101093:	0b 75 dc             	or     -0x24(%ebp),%esi
f0101096:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte = NULL;
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for(int i = 0;i < size;i += PGSIZE){
f0101098:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010109e:	83 c4 10             	add    $0x10,%esp
f01010a1:	89 de                	mov    %ebx,%esi
f01010a3:	03 75 08             	add    0x8(%ebp),%esi
f01010a6:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f01010a9:	77 d7                	ja     f0101082 <boot_map_region+0x32>
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f01010ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010ae:	5b                   	pop    %ebx
f01010af:	5e                   	pop    %esi
f01010b0:	5f                   	pop    %edi
f01010b1:	5d                   	pop    %ebp
f01010b2:	c3                   	ret    

f01010b3 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01010b3:	55                   	push   %ebp
f01010b4:	89 e5                	mov    %esp,%ebp
f01010b6:	53                   	push   %ebx
f01010b7:	83 ec 08             	sub    $0x8,%esp
f01010ba:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
f01010bd:	6a 00                	push   $0x0
f01010bf:	ff 75 0c             	pushl  0xc(%ebp)
f01010c2:	ff 75 08             	pushl  0x8(%ebp)
f01010c5:	e8 c2 fe ff ff       	call   f0100f8c <pgdir_walk>
	if(!pte)
f01010ca:	83 c4 10             	add    $0x10,%esp
f01010cd:	85 c0                	test   %eax,%eax
f01010cf:	74 32                	je     f0101103 <page_lookup+0x50>
		return NULL;
	if(pte_store)
f01010d1:	85 db                	test   %ebx,%ebx
f01010d3:	74 02                	je     f01010d7 <page_lookup+0x24>
		*pte_store = pte;
f01010d5:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010d7:	8b 00                	mov    (%eax),%eax
f01010d9:	c1 e8 0c             	shr    $0xc,%eax
f01010dc:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01010e2:	72 14                	jb     f01010f8 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f01010e4:	83 ec 04             	sub    $0x4,%esp
f01010e7:	68 1c 60 10 f0       	push   $0xf010601c
f01010ec:	6a 51                	push   $0x51
f01010ee:	68 61 68 10 f0       	push   $0xf0106861
f01010f3:	e8 48 ef ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f01010f8:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f01010fe:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	return pa2page(PTE_ADDR(*pte));
f0101101:	eb 05                	jmp    f0101108 <page_lookup+0x55>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
	if(!pte)
		return NULL;
f0101103:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f0101108:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010110b:	c9                   	leave  
f010110c:	c3                   	ret    

f010110d <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010110d:	55                   	push   %ebp
f010110e:	89 e5                	mov    %esp,%ebp
f0101110:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f0101113:	e8 be 41 00 00       	call   f01052d6 <cpunum>
f0101118:	6b c0 74             	imul   $0x74,%eax,%eax
f010111b:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0101122:	74 16                	je     f010113a <tlb_invalidate+0x2d>
f0101124:	e8 ad 41 00 00       	call   f01052d6 <cpunum>
f0101129:	6b c0 74             	imul   $0x74,%eax,%eax
f010112c:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0101132:	8b 55 08             	mov    0x8(%ebp),%edx
f0101135:	39 50 60             	cmp    %edx,0x60(%eax)
f0101138:	75 06                	jne    f0101140 <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010113a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010113d:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0101140:	c9                   	leave  
f0101141:	c3                   	ret    

f0101142 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101142:	55                   	push   %ebp
f0101143:	89 e5                	mov    %esp,%ebp
f0101145:	57                   	push   %edi
f0101146:	56                   	push   %esi
f0101147:	53                   	push   %ebx
f0101148:	83 ec 20             	sub    $0x20,%esp
f010114b:	8b 75 08             	mov    0x8(%ebp),%esi
f010114e:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pte_t *pte;
	// pte_t *pte,**pte_store;
	// pte = pgdir_walk(pgdir, (void *)va, 0);
	// pte_store = &pte;
	struct PageInfo *Page;
	Page = page_lookup(pgdir, va, &pte);
f0101151:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101154:	50                   	push   %eax
f0101155:	57                   	push   %edi
f0101156:	56                   	push   %esi
f0101157:	e8 57 ff ff ff       	call   f01010b3 <page_lookup>
	// Page = page_lookup(pgdir, va, pte_store);
	if(Page){
f010115c:	83 c4 10             	add    $0x10,%esp
f010115f:	85 c0                	test   %eax,%eax
f0101161:	74 20                	je     f0101183 <page_remove+0x41>
f0101163:	89 c3                	mov    %eax,%ebx
		// Page->pp_ref --;
		tlb_invalidate(pgdir, va);
f0101165:	83 ec 08             	sub    $0x8,%esp
f0101168:	57                   	push   %edi
f0101169:	56                   	push   %esi
f010116a:	e8 9e ff ff ff       	call   f010110d <tlb_invalidate>
		page_decref(Page);
f010116f:	89 1c 24             	mov    %ebx,(%esp)
f0101172:	e8 ee fd ff ff       	call   f0100f65 <page_decref>
		*pte = 0;//将对应的页表项清空
f0101177:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010117a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101180:	83 c4 10             	add    $0x10,%esp
	}
}
f0101183:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101186:	5b                   	pop    %ebx
f0101187:	5e                   	pop    %esi
f0101188:	5f                   	pop    %edi
f0101189:	5d                   	pop    %ebp
f010118a:	c3                   	ret    

f010118b <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010118b:	55                   	push   %ebp
f010118c:	89 e5                	mov    %esp,%ebp
f010118e:	57                   	push   %edi
f010118f:	56                   	push   %esi
f0101190:	53                   	push   %ebx
f0101191:	83 ec 10             	sub    $0x10,%esp
f0101194:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101197:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
f010119a:	6a 01                	push   $0x1
f010119c:	57                   	push   %edi
f010119d:	ff 75 08             	pushl  0x8(%ebp)
f01011a0:	e8 e7 fd ff ff       	call   f0100f8c <pgdir_walk>
	if(!pte)
f01011a5:	83 c4 10             	add    $0x10,%esp
f01011a8:	85 c0                	test   %eax,%eax
f01011aa:	74 38                	je     f01011e4 <page_insert+0x59>
f01011ac:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	pp->pp_ref++;
f01011ae:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	//删除旧映射关系 
    if((*pte) & PTE_P)
f01011b3:	f6 00 01             	testb  $0x1,(%eax)
f01011b6:	74 0f                	je     f01011c7 <page_insert+0x3c>
        page_remove(pgdir, va);
f01011b8:	83 ec 08             	sub    $0x8,%esp
f01011bb:	57                   	push   %edi
f01011bc:	ff 75 08             	pushl  0x8(%ebp)
f01011bf:	e8 7e ff ff ff       	call   f0101142 <page_remove>
f01011c4:	83 c4 10             	add    $0x10,%esp
	//pp ->pp_ref++;
    *pte = page2pa(pp) | perm | PTE_P;
f01011c7:	2b 1d 90 ae 22 f0    	sub    0xf022ae90,%ebx
f01011cd:	c1 fb 03             	sar    $0x3,%ebx
f01011d0:	c1 e3 0c             	shl    $0xc,%ebx
f01011d3:	8b 45 14             	mov    0x14(%ebp),%eax
f01011d6:	83 c8 01             	or     $0x1,%eax
f01011d9:	09 c3                	or     %eax,%ebx
f01011db:	89 1e                	mov    %ebx,(%esi)
	return 0;
f01011dd:	b8 00 00 00 00       	mov    $0x0,%eax
f01011e2:	eb 05                	jmp    f01011e9 <page_insert+0x5e>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
	if(!pte)
		return -E_NO_MEM;
f01011e4:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	// 		page_remove(pgdir, va); 
	// }
	// //pp->pp_ref++;
    // *pte = page2pa(pp) | perm | PTE_P;
	// return 0;
}
f01011e9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011ec:	5b                   	pop    %ebx
f01011ed:	5e                   	pop    %esi
f01011ee:	5f                   	pop    %edi
f01011ef:	5d                   	pop    %ebp
f01011f0:	c3                   	ret    

f01011f1 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01011f1:	55                   	push   %ebp
f01011f2:	89 e5                	mov    %esp,%ebp
f01011f4:	53                   	push   %ebx
f01011f5:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	size = ROUNDUP(size, PGSIZE);
f01011f8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011fb:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0101201:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	pa = ROUNDDOWN(pa, PGSIZE);
f0101207:	8b 45 08             	mov    0x8(%ebp),%eax
f010120a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	
	if(base + size > MMIOLIM)
f010120f:	8b 15 00 f3 11 f0    	mov    0xf011f300,%edx
f0101215:	8d 0c 13             	lea    (%ebx,%edx,1),%ecx
f0101218:	81 f9 00 00 c0 ef    	cmp    $0xefc00000,%ecx
f010121e:	76 17                	jbe    f0101237 <mmio_map_region+0x46>
		panic("MMIOLIM is not enough");
f0101220:	83 ec 04             	sub    $0x4,%esp
f0101223:	68 41 69 10 f0       	push   $0xf0106941
f0101228:	68 b5 02 00 00       	push   $0x2b5
f010122d:	68 55 68 10 f0       	push   $0xf0106855
f0101232:	e8 09 ee ff ff       	call   f0100040 <_panic>

	boot_map_region(kern_pgdir, base, size, pa, PTE_PCD | PTE_PWT | PTE_W | PTE_P);
f0101237:	83 ec 08             	sub    $0x8,%esp
f010123a:	6a 1b                	push   $0x1b
f010123c:	50                   	push   %eax
f010123d:	89 d9                	mov    %ebx,%ecx
f010123f:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101244:	e8 07 fe ff ff       	call   f0101050 <boot_map_region>
	base += size;//每次映射到不同的页面
f0101249:	a1 00 f3 11 f0       	mov    0xf011f300,%eax
f010124e:	01 c3                	add    %eax,%ebx
f0101250:	89 1d 00 f3 11 f0    	mov    %ebx,0xf011f300
	return (void *)(base-size);
	//panic("mmio_map_region not implemented");
}
f0101256:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101259:	c9                   	leave  
f010125a:	c3                   	ret    

f010125b <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010125b:	55                   	push   %ebp
f010125c:	89 e5                	mov    %esp,%ebp
f010125e:	57                   	push   %edi
f010125f:	56                   	push   %esi
f0101260:	53                   	push   %ebx
f0101261:	83 ec 48             	sub    $0x48,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101264:	6a 15                	push   $0x15
f0101266:	e8 d7 22 00 00       	call   f0103542 <mc146818_read>
f010126b:	89 c3                	mov    %eax,%ebx
f010126d:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101274:	e8 c9 22 00 00       	call   f0103542 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101279:	c1 e0 08             	shl    $0x8,%eax
f010127c:	09 d8                	or     %ebx,%eax
f010127e:	c1 e0 0a             	shl    $0xa,%eax
f0101281:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101287:	85 c0                	test   %eax,%eax
f0101289:	0f 48 c2             	cmovs  %edx,%eax
f010128c:	c1 f8 0c             	sar    $0xc,%eax
f010128f:	a3 44 a2 22 f0       	mov    %eax,0xf022a244
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101294:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010129b:	e8 a2 22 00 00       	call   f0103542 <mc146818_read>
f01012a0:	89 c3                	mov    %eax,%ebx
f01012a2:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01012a9:	e8 94 22 00 00       	call   f0103542 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01012ae:	c1 e0 08             	shl    $0x8,%eax
f01012b1:	09 d8                	or     %ebx,%eax
f01012b3:	c1 e0 0a             	shl    $0xa,%eax
f01012b6:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01012bc:	83 c4 10             	add    $0x10,%esp
f01012bf:	85 c0                	test   %eax,%eax
f01012c1:	0f 48 c2             	cmovs  %edx,%eax
f01012c4:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01012c7:	85 c0                	test   %eax,%eax
f01012c9:	74 0e                	je     f01012d9 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01012cb:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01012d1:	89 15 88 ae 22 f0    	mov    %edx,0xf022ae88
f01012d7:	eb 0c                	jmp    f01012e5 <mem_init+0x8a>
	else
		npages = npages_basemem;
f01012d9:	8b 15 44 a2 22 f0    	mov    0xf022a244,%edx
f01012df:	89 15 88 ae 22 f0    	mov    %edx,0xf022ae88

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012e5:	c1 e0 0c             	shl    $0xc,%eax
f01012e8:	c1 e8 0a             	shr    $0xa,%eax
f01012eb:	50                   	push   %eax
f01012ec:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
f01012f1:	c1 e0 0c             	shl    $0xc,%eax
f01012f4:	c1 e8 0a             	shr    $0xa,%eax
f01012f7:	50                   	push   %eax
f01012f8:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f01012fd:	c1 e0 0c             	shl    $0xc,%eax
f0101300:	c1 e8 0a             	shr    $0xa,%eax
f0101303:	50                   	push   %eax
f0101304:	68 3c 60 10 f0       	push   $0xf010603c
f0101309:	e8 b3 23 00 00       	call   f01036c1 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010130e:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101313:	e8 19 f7 ff ff       	call   f0100a31 <boot_alloc>
f0101318:	a3 8c ae 22 f0       	mov    %eax,0xf022ae8c
	memset(kern_pgdir, 0, PGSIZE);
f010131d:	83 c4 0c             	add    $0xc,%esp
f0101320:	68 00 10 00 00       	push   $0x1000
f0101325:	6a 00                	push   $0x0
f0101327:	50                   	push   %eax
f0101328:	e8 88 39 00 00       	call   f0104cb5 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010132d:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101332:	83 c4 10             	add    $0x10,%esp
f0101335:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010133a:	77 15                	ja     f0101351 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010133c:	50                   	push   %eax
f010133d:	68 a8 59 10 f0       	push   $0xf01059a8
f0101342:	68 90 00 00 00       	push   $0x90
f0101347:	68 55 68 10 f0       	push   $0xf0106855
f010134c:	e8 ef ec ff ff       	call   f0100040 <_panic>
f0101351:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101357:	83 ca 05             	or     $0x5,%edx
f010135a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f0101360:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0101365:	c1 e0 03             	shl    $0x3,%eax
f0101368:	e8 c4 f6 ff ff       	call   f0100a31 <boot_alloc>
f010136d:	a3 90 ae 22 f0       	mov    %eax,0xf022ae90
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101372:	83 ec 04             	sub    $0x4,%esp
f0101375:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f010137b:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101382:	52                   	push   %edx
f0101383:	6a 00                	push   $0x0
f0101385:	50                   	push   %eax
f0101386:	e8 2a 39 00 00       	call   f0104cb5 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*)boot_alloc(NENV * sizeof(struct Env));
f010138b:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101390:	e8 9c f6 ff ff       	call   f0100a31 <boot_alloc>
f0101395:	a3 48 a2 22 f0       	mov    %eax,0xf022a248
	memset(envs, 0, NENV * sizeof(struct Env));
f010139a:	83 c4 0c             	add    $0xc,%esp
f010139d:	68 00 f0 01 00       	push   $0x1f000
f01013a2:	6a 00                	push   $0x0
f01013a4:	50                   	push   %eax
f01013a5:	e8 0b 39 00 00       	call   f0104cb5 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01013aa:	e8 0f fa ff ff       	call   f0100dbe <page_init>

	check_page_free_list(1);
f01013af:	b8 01 00 00 00       	mov    $0x1,%eax
f01013b4:	e8 16 f7 ff ff       	call   f0100acf <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01013b9:	83 c4 10             	add    $0x10,%esp
f01013bc:	83 3d 90 ae 22 f0 00 	cmpl   $0x0,0xf022ae90
f01013c3:	75 17                	jne    f01013dc <mem_init+0x181>
		panic("'pages' is a null pointer!");
f01013c5:	83 ec 04             	sub    $0x4,%esp
f01013c8:	68 57 69 10 f0       	push   $0xf0106957
f01013cd:	68 4e 03 00 00       	push   $0x34e
f01013d2:	68 55 68 10 f0       	push   $0xf0106855
f01013d7:	e8 64 ec ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013dc:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f01013e1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01013e6:	eb 05                	jmp    f01013ed <mem_init+0x192>
		++nfree;
f01013e8:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013eb:	8b 00                	mov    (%eax),%eax
f01013ed:	85 c0                	test   %eax,%eax
f01013ef:	75 f7                	jne    f01013e8 <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013f1:	83 ec 0c             	sub    $0xc,%esp
f01013f4:	6a 00                	push   $0x0
f01013f6:	e8 bf fa ff ff       	call   f0100eba <page_alloc>
f01013fb:	89 c7                	mov    %eax,%edi
f01013fd:	83 c4 10             	add    $0x10,%esp
f0101400:	85 c0                	test   %eax,%eax
f0101402:	75 19                	jne    f010141d <mem_init+0x1c2>
f0101404:	68 72 69 10 f0       	push   $0xf0106972
f0101409:	68 7b 68 10 f0       	push   $0xf010687b
f010140e:	68 56 03 00 00       	push   $0x356
f0101413:	68 55 68 10 f0       	push   $0xf0106855
f0101418:	e8 23 ec ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010141d:	83 ec 0c             	sub    $0xc,%esp
f0101420:	6a 00                	push   $0x0
f0101422:	e8 93 fa ff ff       	call   f0100eba <page_alloc>
f0101427:	89 c6                	mov    %eax,%esi
f0101429:	83 c4 10             	add    $0x10,%esp
f010142c:	85 c0                	test   %eax,%eax
f010142e:	75 19                	jne    f0101449 <mem_init+0x1ee>
f0101430:	68 88 69 10 f0       	push   $0xf0106988
f0101435:	68 7b 68 10 f0       	push   $0xf010687b
f010143a:	68 57 03 00 00       	push   $0x357
f010143f:	68 55 68 10 f0       	push   $0xf0106855
f0101444:	e8 f7 eb ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101449:	83 ec 0c             	sub    $0xc,%esp
f010144c:	6a 00                	push   $0x0
f010144e:	e8 67 fa ff ff       	call   f0100eba <page_alloc>
f0101453:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101456:	83 c4 10             	add    $0x10,%esp
f0101459:	85 c0                	test   %eax,%eax
f010145b:	75 19                	jne    f0101476 <mem_init+0x21b>
f010145d:	68 9e 69 10 f0       	push   $0xf010699e
f0101462:	68 7b 68 10 f0       	push   $0xf010687b
f0101467:	68 58 03 00 00       	push   $0x358
f010146c:	68 55 68 10 f0       	push   $0xf0106855
f0101471:	e8 ca eb ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101476:	39 f7                	cmp    %esi,%edi
f0101478:	75 19                	jne    f0101493 <mem_init+0x238>
f010147a:	68 b4 69 10 f0       	push   $0xf01069b4
f010147f:	68 7b 68 10 f0       	push   $0xf010687b
f0101484:	68 5b 03 00 00       	push   $0x35b
f0101489:	68 55 68 10 f0       	push   $0xf0106855
f010148e:	e8 ad eb ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101493:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101496:	39 c6                	cmp    %eax,%esi
f0101498:	74 04                	je     f010149e <mem_init+0x243>
f010149a:	39 c7                	cmp    %eax,%edi
f010149c:	75 19                	jne    f01014b7 <mem_init+0x25c>
f010149e:	68 78 60 10 f0       	push   $0xf0106078
f01014a3:	68 7b 68 10 f0       	push   $0xf010687b
f01014a8:	68 5c 03 00 00       	push   $0x35c
f01014ad:	68 55 68 10 f0       	push   $0xf0106855
f01014b2:	e8 89 eb ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014b7:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014bd:	8b 15 88 ae 22 f0    	mov    0xf022ae88,%edx
f01014c3:	c1 e2 0c             	shl    $0xc,%edx
f01014c6:	89 f8                	mov    %edi,%eax
f01014c8:	29 c8                	sub    %ecx,%eax
f01014ca:	c1 f8 03             	sar    $0x3,%eax
f01014cd:	c1 e0 0c             	shl    $0xc,%eax
f01014d0:	39 d0                	cmp    %edx,%eax
f01014d2:	72 19                	jb     f01014ed <mem_init+0x292>
f01014d4:	68 c6 69 10 f0       	push   $0xf01069c6
f01014d9:	68 7b 68 10 f0       	push   $0xf010687b
f01014de:	68 5d 03 00 00       	push   $0x35d
f01014e3:	68 55 68 10 f0       	push   $0xf0106855
f01014e8:	e8 53 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01014ed:	89 f0                	mov    %esi,%eax
f01014ef:	29 c8                	sub    %ecx,%eax
f01014f1:	c1 f8 03             	sar    $0x3,%eax
f01014f4:	c1 e0 0c             	shl    $0xc,%eax
f01014f7:	39 c2                	cmp    %eax,%edx
f01014f9:	77 19                	ja     f0101514 <mem_init+0x2b9>
f01014fb:	68 e3 69 10 f0       	push   $0xf01069e3
f0101500:	68 7b 68 10 f0       	push   $0xf010687b
f0101505:	68 5e 03 00 00       	push   $0x35e
f010150a:	68 55 68 10 f0       	push   $0xf0106855
f010150f:	e8 2c eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101514:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101517:	29 c8                	sub    %ecx,%eax
f0101519:	c1 f8 03             	sar    $0x3,%eax
f010151c:	c1 e0 0c             	shl    $0xc,%eax
f010151f:	39 c2                	cmp    %eax,%edx
f0101521:	77 19                	ja     f010153c <mem_init+0x2e1>
f0101523:	68 00 6a 10 f0       	push   $0xf0106a00
f0101528:	68 7b 68 10 f0       	push   $0xf010687b
f010152d:	68 5f 03 00 00       	push   $0x35f
f0101532:	68 55 68 10 f0       	push   $0xf0106855
f0101537:	e8 04 eb ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010153c:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0101541:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101544:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f010154b:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010154e:	83 ec 0c             	sub    $0xc,%esp
f0101551:	6a 00                	push   $0x0
f0101553:	e8 62 f9 ff ff       	call   f0100eba <page_alloc>
f0101558:	83 c4 10             	add    $0x10,%esp
f010155b:	85 c0                	test   %eax,%eax
f010155d:	74 19                	je     f0101578 <mem_init+0x31d>
f010155f:	68 1d 6a 10 f0       	push   $0xf0106a1d
f0101564:	68 7b 68 10 f0       	push   $0xf010687b
f0101569:	68 66 03 00 00       	push   $0x366
f010156e:	68 55 68 10 f0       	push   $0xf0106855
f0101573:	e8 c8 ea ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101578:	83 ec 0c             	sub    $0xc,%esp
f010157b:	57                   	push   %edi
f010157c:	e8 bf f9 ff ff       	call   f0100f40 <page_free>
	page_free(pp1);
f0101581:	89 34 24             	mov    %esi,(%esp)
f0101584:	e8 b7 f9 ff ff       	call   f0100f40 <page_free>
	page_free(pp2);
f0101589:	83 c4 04             	add    $0x4,%esp
f010158c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010158f:	e8 ac f9 ff ff       	call   f0100f40 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101594:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010159b:	e8 1a f9 ff ff       	call   f0100eba <page_alloc>
f01015a0:	89 c6                	mov    %eax,%esi
f01015a2:	83 c4 10             	add    $0x10,%esp
f01015a5:	85 c0                	test   %eax,%eax
f01015a7:	75 19                	jne    f01015c2 <mem_init+0x367>
f01015a9:	68 72 69 10 f0       	push   $0xf0106972
f01015ae:	68 7b 68 10 f0       	push   $0xf010687b
f01015b3:	68 6d 03 00 00       	push   $0x36d
f01015b8:	68 55 68 10 f0       	push   $0xf0106855
f01015bd:	e8 7e ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01015c2:	83 ec 0c             	sub    $0xc,%esp
f01015c5:	6a 00                	push   $0x0
f01015c7:	e8 ee f8 ff ff       	call   f0100eba <page_alloc>
f01015cc:	89 c7                	mov    %eax,%edi
f01015ce:	83 c4 10             	add    $0x10,%esp
f01015d1:	85 c0                	test   %eax,%eax
f01015d3:	75 19                	jne    f01015ee <mem_init+0x393>
f01015d5:	68 88 69 10 f0       	push   $0xf0106988
f01015da:	68 7b 68 10 f0       	push   $0xf010687b
f01015df:	68 6e 03 00 00       	push   $0x36e
f01015e4:	68 55 68 10 f0       	push   $0xf0106855
f01015e9:	e8 52 ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01015ee:	83 ec 0c             	sub    $0xc,%esp
f01015f1:	6a 00                	push   $0x0
f01015f3:	e8 c2 f8 ff ff       	call   f0100eba <page_alloc>
f01015f8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015fb:	83 c4 10             	add    $0x10,%esp
f01015fe:	85 c0                	test   %eax,%eax
f0101600:	75 19                	jne    f010161b <mem_init+0x3c0>
f0101602:	68 9e 69 10 f0       	push   $0xf010699e
f0101607:	68 7b 68 10 f0       	push   $0xf010687b
f010160c:	68 6f 03 00 00       	push   $0x36f
f0101611:	68 55 68 10 f0       	push   $0xf0106855
f0101616:	e8 25 ea ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010161b:	39 fe                	cmp    %edi,%esi
f010161d:	75 19                	jne    f0101638 <mem_init+0x3dd>
f010161f:	68 b4 69 10 f0       	push   $0xf01069b4
f0101624:	68 7b 68 10 f0       	push   $0xf010687b
f0101629:	68 71 03 00 00       	push   $0x371
f010162e:	68 55 68 10 f0       	push   $0xf0106855
f0101633:	e8 08 ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101638:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010163b:	39 c7                	cmp    %eax,%edi
f010163d:	74 04                	je     f0101643 <mem_init+0x3e8>
f010163f:	39 c6                	cmp    %eax,%esi
f0101641:	75 19                	jne    f010165c <mem_init+0x401>
f0101643:	68 78 60 10 f0       	push   $0xf0106078
f0101648:	68 7b 68 10 f0       	push   $0xf010687b
f010164d:	68 72 03 00 00       	push   $0x372
f0101652:	68 55 68 10 f0       	push   $0xf0106855
f0101657:	e8 e4 e9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010165c:	83 ec 0c             	sub    $0xc,%esp
f010165f:	6a 00                	push   $0x0
f0101661:	e8 54 f8 ff ff       	call   f0100eba <page_alloc>
f0101666:	83 c4 10             	add    $0x10,%esp
f0101669:	85 c0                	test   %eax,%eax
f010166b:	74 19                	je     f0101686 <mem_init+0x42b>
f010166d:	68 1d 6a 10 f0       	push   $0xf0106a1d
f0101672:	68 7b 68 10 f0       	push   $0xf010687b
f0101677:	68 73 03 00 00       	push   $0x373
f010167c:	68 55 68 10 f0       	push   $0xf0106855
f0101681:	e8 ba e9 ff ff       	call   f0100040 <_panic>
f0101686:	89 f0                	mov    %esi,%eax
f0101688:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f010168e:	c1 f8 03             	sar    $0x3,%eax
f0101691:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101694:	89 c2                	mov    %eax,%edx
f0101696:	c1 ea 0c             	shr    $0xc,%edx
f0101699:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f010169f:	72 12                	jb     f01016b3 <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016a1:	50                   	push   %eax
f01016a2:	68 84 59 10 f0       	push   $0xf0105984
f01016a7:	6a 58                	push   $0x58
f01016a9:	68 61 68 10 f0       	push   $0xf0106861
f01016ae:	e8 8d e9 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01016b3:	83 ec 04             	sub    $0x4,%esp
f01016b6:	68 00 10 00 00       	push   $0x1000
f01016bb:	6a 01                	push   $0x1
f01016bd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016c2:	50                   	push   %eax
f01016c3:	e8 ed 35 00 00       	call   f0104cb5 <memset>
	page_free(pp0);
f01016c8:	89 34 24             	mov    %esi,(%esp)
f01016cb:	e8 70 f8 ff ff       	call   f0100f40 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016d0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016d7:	e8 de f7 ff ff       	call   f0100eba <page_alloc>
f01016dc:	83 c4 10             	add    $0x10,%esp
f01016df:	85 c0                	test   %eax,%eax
f01016e1:	75 19                	jne    f01016fc <mem_init+0x4a1>
f01016e3:	68 2c 6a 10 f0       	push   $0xf0106a2c
f01016e8:	68 7b 68 10 f0       	push   $0xf010687b
f01016ed:	68 78 03 00 00       	push   $0x378
f01016f2:	68 55 68 10 f0       	push   $0xf0106855
f01016f7:	e8 44 e9 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01016fc:	39 c6                	cmp    %eax,%esi
f01016fe:	74 19                	je     f0101719 <mem_init+0x4be>
f0101700:	68 4a 6a 10 f0       	push   $0xf0106a4a
f0101705:	68 7b 68 10 f0       	push   $0xf010687b
f010170a:	68 79 03 00 00       	push   $0x379
f010170f:	68 55 68 10 f0       	push   $0xf0106855
f0101714:	e8 27 e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101719:	89 f0                	mov    %esi,%eax
f010171b:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0101721:	c1 f8 03             	sar    $0x3,%eax
f0101724:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101727:	89 c2                	mov    %eax,%edx
f0101729:	c1 ea 0c             	shr    $0xc,%edx
f010172c:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0101732:	72 12                	jb     f0101746 <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101734:	50                   	push   %eax
f0101735:	68 84 59 10 f0       	push   $0xf0105984
f010173a:	6a 58                	push   $0x58
f010173c:	68 61 68 10 f0       	push   $0xf0106861
f0101741:	e8 fa e8 ff ff       	call   f0100040 <_panic>
f0101746:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010174c:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101752:	80 38 00             	cmpb   $0x0,(%eax)
f0101755:	74 19                	je     f0101770 <mem_init+0x515>
f0101757:	68 5a 6a 10 f0       	push   $0xf0106a5a
f010175c:	68 7b 68 10 f0       	push   $0xf010687b
f0101761:	68 7c 03 00 00       	push   $0x37c
f0101766:	68 55 68 10 f0       	push   $0xf0106855
f010176b:	e8 d0 e8 ff ff       	call   f0100040 <_panic>
f0101770:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101773:	39 d0                	cmp    %edx,%eax
f0101775:	75 db                	jne    f0101752 <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101777:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010177a:	a3 40 a2 22 f0       	mov    %eax,0xf022a240

	// free the pages we took
	page_free(pp0);
f010177f:	83 ec 0c             	sub    $0xc,%esp
f0101782:	56                   	push   %esi
f0101783:	e8 b8 f7 ff ff       	call   f0100f40 <page_free>
	page_free(pp1);
f0101788:	89 3c 24             	mov    %edi,(%esp)
f010178b:	e8 b0 f7 ff ff       	call   f0100f40 <page_free>
	page_free(pp2);
f0101790:	83 c4 04             	add    $0x4,%esp
f0101793:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101796:	e8 a5 f7 ff ff       	call   f0100f40 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010179b:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f01017a0:	83 c4 10             	add    $0x10,%esp
f01017a3:	eb 05                	jmp    f01017aa <mem_init+0x54f>
		--nfree;
f01017a5:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017a8:	8b 00                	mov    (%eax),%eax
f01017aa:	85 c0                	test   %eax,%eax
f01017ac:	75 f7                	jne    f01017a5 <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f01017ae:	85 db                	test   %ebx,%ebx
f01017b0:	74 19                	je     f01017cb <mem_init+0x570>
f01017b2:	68 64 6a 10 f0       	push   $0xf0106a64
f01017b7:	68 7b 68 10 f0       	push   $0xf010687b
f01017bc:	68 89 03 00 00       	push   $0x389
f01017c1:	68 55 68 10 f0       	push   $0xf0106855
f01017c6:	e8 75 e8 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017cb:	83 ec 0c             	sub    $0xc,%esp
f01017ce:	68 98 60 10 f0       	push   $0xf0106098
f01017d3:	e8 e9 1e 00 00       	call   f01036c1 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017d8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017df:	e8 d6 f6 ff ff       	call   f0100eba <page_alloc>
f01017e4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017e7:	83 c4 10             	add    $0x10,%esp
f01017ea:	85 c0                	test   %eax,%eax
f01017ec:	75 19                	jne    f0101807 <mem_init+0x5ac>
f01017ee:	68 72 69 10 f0       	push   $0xf0106972
f01017f3:	68 7b 68 10 f0       	push   $0xf010687b
f01017f8:	68 ef 03 00 00       	push   $0x3ef
f01017fd:	68 55 68 10 f0       	push   $0xf0106855
f0101802:	e8 39 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101807:	83 ec 0c             	sub    $0xc,%esp
f010180a:	6a 00                	push   $0x0
f010180c:	e8 a9 f6 ff ff       	call   f0100eba <page_alloc>
f0101811:	89 c3                	mov    %eax,%ebx
f0101813:	83 c4 10             	add    $0x10,%esp
f0101816:	85 c0                	test   %eax,%eax
f0101818:	75 19                	jne    f0101833 <mem_init+0x5d8>
f010181a:	68 88 69 10 f0       	push   $0xf0106988
f010181f:	68 7b 68 10 f0       	push   $0xf010687b
f0101824:	68 f0 03 00 00       	push   $0x3f0
f0101829:	68 55 68 10 f0       	push   $0xf0106855
f010182e:	e8 0d e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101833:	83 ec 0c             	sub    $0xc,%esp
f0101836:	6a 00                	push   $0x0
f0101838:	e8 7d f6 ff ff       	call   f0100eba <page_alloc>
f010183d:	89 c6                	mov    %eax,%esi
f010183f:	83 c4 10             	add    $0x10,%esp
f0101842:	85 c0                	test   %eax,%eax
f0101844:	75 19                	jne    f010185f <mem_init+0x604>
f0101846:	68 9e 69 10 f0       	push   $0xf010699e
f010184b:	68 7b 68 10 f0       	push   $0xf010687b
f0101850:	68 f1 03 00 00       	push   $0x3f1
f0101855:	68 55 68 10 f0       	push   $0xf0106855
f010185a:	e8 e1 e7 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010185f:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101862:	75 19                	jne    f010187d <mem_init+0x622>
f0101864:	68 b4 69 10 f0       	push   $0xf01069b4
f0101869:	68 7b 68 10 f0       	push   $0xf010687b
f010186e:	68 f4 03 00 00       	push   $0x3f4
f0101873:	68 55 68 10 f0       	push   $0xf0106855
f0101878:	e8 c3 e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010187d:	39 c3                	cmp    %eax,%ebx
f010187f:	74 05                	je     f0101886 <mem_init+0x62b>
f0101881:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101884:	75 19                	jne    f010189f <mem_init+0x644>
f0101886:	68 78 60 10 f0       	push   $0xf0106078
f010188b:	68 7b 68 10 f0       	push   $0xf010687b
f0101890:	68 f5 03 00 00       	push   $0x3f5
f0101895:	68 55 68 10 f0       	push   $0xf0106855
f010189a:	e8 a1 e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010189f:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f01018a4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01018a7:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f01018ae:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01018b1:	83 ec 0c             	sub    $0xc,%esp
f01018b4:	6a 00                	push   $0x0
f01018b6:	e8 ff f5 ff ff       	call   f0100eba <page_alloc>
f01018bb:	83 c4 10             	add    $0x10,%esp
f01018be:	85 c0                	test   %eax,%eax
f01018c0:	74 19                	je     f01018db <mem_init+0x680>
f01018c2:	68 1d 6a 10 f0       	push   $0xf0106a1d
f01018c7:	68 7b 68 10 f0       	push   $0xf010687b
f01018cc:	68 fc 03 00 00       	push   $0x3fc
f01018d1:	68 55 68 10 f0       	push   $0xf0106855
f01018d6:	e8 65 e7 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01018db:	83 ec 04             	sub    $0x4,%esp
f01018de:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01018e1:	50                   	push   %eax
f01018e2:	6a 00                	push   $0x0
f01018e4:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01018ea:	e8 c4 f7 ff ff       	call   f01010b3 <page_lookup>
f01018ef:	83 c4 10             	add    $0x10,%esp
f01018f2:	85 c0                	test   %eax,%eax
f01018f4:	74 19                	je     f010190f <mem_init+0x6b4>
f01018f6:	68 b8 60 10 f0       	push   $0xf01060b8
f01018fb:	68 7b 68 10 f0       	push   $0xf010687b
f0101900:	68 ff 03 00 00       	push   $0x3ff
f0101905:	68 55 68 10 f0       	push   $0xf0106855
f010190a:	e8 31 e7 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010190f:	6a 02                	push   $0x2
f0101911:	6a 00                	push   $0x0
f0101913:	53                   	push   %ebx
f0101914:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f010191a:	e8 6c f8 ff ff       	call   f010118b <page_insert>
f010191f:	83 c4 10             	add    $0x10,%esp
f0101922:	85 c0                	test   %eax,%eax
f0101924:	78 19                	js     f010193f <mem_init+0x6e4>
f0101926:	68 f0 60 10 f0       	push   $0xf01060f0
f010192b:	68 7b 68 10 f0       	push   $0xf010687b
f0101930:	68 02 04 00 00       	push   $0x402
f0101935:	68 55 68 10 f0       	push   $0xf0106855
f010193a:	e8 01 e7 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010193f:	83 ec 0c             	sub    $0xc,%esp
f0101942:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101945:	e8 f6 f5 ff ff       	call   f0100f40 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010194a:	6a 02                	push   $0x2
f010194c:	6a 00                	push   $0x0
f010194e:	53                   	push   %ebx
f010194f:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101955:	e8 31 f8 ff ff       	call   f010118b <page_insert>
f010195a:	83 c4 20             	add    $0x20,%esp
f010195d:	85 c0                	test   %eax,%eax
f010195f:	74 19                	je     f010197a <mem_init+0x71f>
f0101961:	68 20 61 10 f0       	push   $0xf0106120
f0101966:	68 7b 68 10 f0       	push   $0xf010687b
f010196b:	68 06 04 00 00       	push   $0x406
f0101970:	68 55 68 10 f0       	push   $0xf0106855
f0101975:	e8 c6 e6 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010197a:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101980:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f0101985:	89 c1                	mov    %eax,%ecx
f0101987:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010198a:	8b 17                	mov    (%edi),%edx
f010198c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101992:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101995:	29 c8                	sub    %ecx,%eax
f0101997:	c1 f8 03             	sar    $0x3,%eax
f010199a:	c1 e0 0c             	shl    $0xc,%eax
f010199d:	39 c2                	cmp    %eax,%edx
f010199f:	74 19                	je     f01019ba <mem_init+0x75f>
f01019a1:	68 50 61 10 f0       	push   $0xf0106150
f01019a6:	68 7b 68 10 f0       	push   $0xf010687b
f01019ab:	68 07 04 00 00       	push   $0x407
f01019b0:	68 55 68 10 f0       	push   $0xf0106855
f01019b5:	e8 86 e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01019ba:	ba 00 00 00 00       	mov    $0x0,%edx
f01019bf:	89 f8                	mov    %edi,%eax
f01019c1:	e8 a5 f0 ff ff       	call   f0100a6b <check_va2pa>
f01019c6:	89 da                	mov    %ebx,%edx
f01019c8:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01019cb:	c1 fa 03             	sar    $0x3,%edx
f01019ce:	c1 e2 0c             	shl    $0xc,%edx
f01019d1:	39 d0                	cmp    %edx,%eax
f01019d3:	74 19                	je     f01019ee <mem_init+0x793>
f01019d5:	68 78 61 10 f0       	push   $0xf0106178
f01019da:	68 7b 68 10 f0       	push   $0xf010687b
f01019df:	68 08 04 00 00       	push   $0x408
f01019e4:	68 55 68 10 f0       	push   $0xf0106855
f01019e9:	e8 52 e6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01019ee:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01019f3:	74 19                	je     f0101a0e <mem_init+0x7b3>
f01019f5:	68 6f 6a 10 f0       	push   $0xf0106a6f
f01019fa:	68 7b 68 10 f0       	push   $0xf010687b
f01019ff:	68 09 04 00 00       	push   $0x409
f0101a04:	68 55 68 10 f0       	push   $0xf0106855
f0101a09:	e8 32 e6 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101a0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a11:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a16:	74 19                	je     f0101a31 <mem_init+0x7d6>
f0101a18:	68 80 6a 10 f0       	push   $0xf0106a80
f0101a1d:	68 7b 68 10 f0       	push   $0xf010687b
f0101a22:	68 0a 04 00 00       	push   $0x40a
f0101a27:	68 55 68 10 f0       	push   $0xf0106855
f0101a2c:	e8 0f e6 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a31:	6a 02                	push   $0x2
f0101a33:	68 00 10 00 00       	push   $0x1000
f0101a38:	56                   	push   %esi
f0101a39:	57                   	push   %edi
f0101a3a:	e8 4c f7 ff ff       	call   f010118b <page_insert>
f0101a3f:	83 c4 10             	add    $0x10,%esp
f0101a42:	85 c0                	test   %eax,%eax
f0101a44:	74 19                	je     f0101a5f <mem_init+0x804>
f0101a46:	68 a8 61 10 f0       	push   $0xf01061a8
f0101a4b:	68 7b 68 10 f0       	push   $0xf010687b
f0101a50:	68 0d 04 00 00       	push   $0x40d
f0101a55:	68 55 68 10 f0       	push   $0xf0106855
f0101a5a:	e8 e1 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a5f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a64:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101a69:	e8 fd ef ff ff       	call   f0100a6b <check_va2pa>
f0101a6e:	89 f2                	mov    %esi,%edx
f0101a70:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101a76:	c1 fa 03             	sar    $0x3,%edx
f0101a79:	c1 e2 0c             	shl    $0xc,%edx
f0101a7c:	39 d0                	cmp    %edx,%eax
f0101a7e:	74 19                	je     f0101a99 <mem_init+0x83e>
f0101a80:	68 e4 61 10 f0       	push   $0xf01061e4
f0101a85:	68 7b 68 10 f0       	push   $0xf010687b
f0101a8a:	68 0e 04 00 00       	push   $0x40e
f0101a8f:	68 55 68 10 f0       	push   $0xf0106855
f0101a94:	e8 a7 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101a99:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a9e:	74 19                	je     f0101ab9 <mem_init+0x85e>
f0101aa0:	68 91 6a 10 f0       	push   $0xf0106a91
f0101aa5:	68 7b 68 10 f0       	push   $0xf010687b
f0101aaa:	68 0f 04 00 00       	push   $0x40f
f0101aaf:	68 55 68 10 f0       	push   $0xf0106855
f0101ab4:	e8 87 e5 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ab9:	83 ec 0c             	sub    $0xc,%esp
f0101abc:	6a 00                	push   $0x0
f0101abe:	e8 f7 f3 ff ff       	call   f0100eba <page_alloc>
f0101ac3:	83 c4 10             	add    $0x10,%esp
f0101ac6:	85 c0                	test   %eax,%eax
f0101ac8:	74 19                	je     f0101ae3 <mem_init+0x888>
f0101aca:	68 1d 6a 10 f0       	push   $0xf0106a1d
f0101acf:	68 7b 68 10 f0       	push   $0xf010687b
f0101ad4:	68 12 04 00 00       	push   $0x412
f0101ad9:	68 55 68 10 f0       	push   $0xf0106855
f0101ade:	e8 5d e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ae3:	6a 02                	push   $0x2
f0101ae5:	68 00 10 00 00       	push   $0x1000
f0101aea:	56                   	push   %esi
f0101aeb:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101af1:	e8 95 f6 ff ff       	call   f010118b <page_insert>
f0101af6:	83 c4 10             	add    $0x10,%esp
f0101af9:	85 c0                	test   %eax,%eax
f0101afb:	74 19                	je     f0101b16 <mem_init+0x8bb>
f0101afd:	68 a8 61 10 f0       	push   $0xf01061a8
f0101b02:	68 7b 68 10 f0       	push   $0xf010687b
f0101b07:	68 15 04 00 00       	push   $0x415
f0101b0c:	68 55 68 10 f0       	push   $0xf0106855
f0101b11:	e8 2a e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b16:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b1b:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101b20:	e8 46 ef ff ff       	call   f0100a6b <check_va2pa>
f0101b25:	89 f2                	mov    %esi,%edx
f0101b27:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101b2d:	c1 fa 03             	sar    $0x3,%edx
f0101b30:	c1 e2 0c             	shl    $0xc,%edx
f0101b33:	39 d0                	cmp    %edx,%eax
f0101b35:	74 19                	je     f0101b50 <mem_init+0x8f5>
f0101b37:	68 e4 61 10 f0       	push   $0xf01061e4
f0101b3c:	68 7b 68 10 f0       	push   $0xf010687b
f0101b41:	68 16 04 00 00       	push   $0x416
f0101b46:	68 55 68 10 f0       	push   $0xf0106855
f0101b4b:	e8 f0 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b50:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b55:	74 19                	je     f0101b70 <mem_init+0x915>
f0101b57:	68 91 6a 10 f0       	push   $0xf0106a91
f0101b5c:	68 7b 68 10 f0       	push   $0xf010687b
f0101b61:	68 17 04 00 00       	push   $0x417
f0101b66:	68 55 68 10 f0       	push   $0xf0106855
f0101b6b:	e8 d0 e4 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b70:	83 ec 0c             	sub    $0xc,%esp
f0101b73:	6a 00                	push   $0x0
f0101b75:	e8 40 f3 ff ff       	call   f0100eba <page_alloc>
f0101b7a:	83 c4 10             	add    $0x10,%esp
f0101b7d:	85 c0                	test   %eax,%eax
f0101b7f:	74 19                	je     f0101b9a <mem_init+0x93f>
f0101b81:	68 1d 6a 10 f0       	push   $0xf0106a1d
f0101b86:	68 7b 68 10 f0       	push   $0xf010687b
f0101b8b:	68 1b 04 00 00       	push   $0x41b
f0101b90:	68 55 68 10 f0       	push   $0xf0106855
f0101b95:	e8 a6 e4 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b9a:	8b 15 8c ae 22 f0    	mov    0xf022ae8c,%edx
f0101ba0:	8b 02                	mov    (%edx),%eax
f0101ba2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ba7:	89 c1                	mov    %eax,%ecx
f0101ba9:	c1 e9 0c             	shr    $0xc,%ecx
f0101bac:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0101bb2:	72 15                	jb     f0101bc9 <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101bb4:	50                   	push   %eax
f0101bb5:	68 84 59 10 f0       	push   $0xf0105984
f0101bba:	68 1e 04 00 00       	push   $0x41e
f0101bbf:	68 55 68 10 f0       	push   $0xf0106855
f0101bc4:	e8 77 e4 ff ff       	call   f0100040 <_panic>
f0101bc9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101bce:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101bd1:	83 ec 04             	sub    $0x4,%esp
f0101bd4:	6a 00                	push   $0x0
f0101bd6:	68 00 10 00 00       	push   $0x1000
f0101bdb:	52                   	push   %edx
f0101bdc:	e8 ab f3 ff ff       	call   f0100f8c <pgdir_walk>
f0101be1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101be4:	8d 51 04             	lea    0x4(%ecx),%edx
f0101be7:	83 c4 10             	add    $0x10,%esp
f0101bea:	39 d0                	cmp    %edx,%eax
f0101bec:	74 19                	je     f0101c07 <mem_init+0x9ac>
f0101bee:	68 14 62 10 f0       	push   $0xf0106214
f0101bf3:	68 7b 68 10 f0       	push   $0xf010687b
f0101bf8:	68 1f 04 00 00       	push   $0x41f
f0101bfd:	68 55 68 10 f0       	push   $0xf0106855
f0101c02:	e8 39 e4 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c07:	6a 06                	push   $0x6
f0101c09:	68 00 10 00 00       	push   $0x1000
f0101c0e:	56                   	push   %esi
f0101c0f:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101c15:	e8 71 f5 ff ff       	call   f010118b <page_insert>
f0101c1a:	83 c4 10             	add    $0x10,%esp
f0101c1d:	85 c0                	test   %eax,%eax
f0101c1f:	74 19                	je     f0101c3a <mem_init+0x9df>
f0101c21:	68 54 62 10 f0       	push   $0xf0106254
f0101c26:	68 7b 68 10 f0       	push   $0xf010687b
f0101c2b:	68 22 04 00 00       	push   $0x422
f0101c30:	68 55 68 10 f0       	push   $0xf0106855
f0101c35:	e8 06 e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c3a:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101c40:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c45:	89 f8                	mov    %edi,%eax
f0101c47:	e8 1f ee ff ff       	call   f0100a6b <check_va2pa>
f0101c4c:	89 f2                	mov    %esi,%edx
f0101c4e:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101c54:	c1 fa 03             	sar    $0x3,%edx
f0101c57:	c1 e2 0c             	shl    $0xc,%edx
f0101c5a:	39 d0                	cmp    %edx,%eax
f0101c5c:	74 19                	je     f0101c77 <mem_init+0xa1c>
f0101c5e:	68 e4 61 10 f0       	push   $0xf01061e4
f0101c63:	68 7b 68 10 f0       	push   $0xf010687b
f0101c68:	68 23 04 00 00       	push   $0x423
f0101c6d:	68 55 68 10 f0       	push   $0xf0106855
f0101c72:	e8 c9 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101c77:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c7c:	74 19                	je     f0101c97 <mem_init+0xa3c>
f0101c7e:	68 91 6a 10 f0       	push   $0xf0106a91
f0101c83:	68 7b 68 10 f0       	push   $0xf010687b
f0101c88:	68 24 04 00 00       	push   $0x424
f0101c8d:	68 55 68 10 f0       	push   $0xf0106855
f0101c92:	e8 a9 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c97:	83 ec 04             	sub    $0x4,%esp
f0101c9a:	6a 00                	push   $0x0
f0101c9c:	68 00 10 00 00       	push   $0x1000
f0101ca1:	57                   	push   %edi
f0101ca2:	e8 e5 f2 ff ff       	call   f0100f8c <pgdir_walk>
f0101ca7:	83 c4 10             	add    $0x10,%esp
f0101caa:	f6 00 04             	testb  $0x4,(%eax)
f0101cad:	75 19                	jne    f0101cc8 <mem_init+0xa6d>
f0101caf:	68 94 62 10 f0       	push   $0xf0106294
f0101cb4:	68 7b 68 10 f0       	push   $0xf010687b
f0101cb9:	68 25 04 00 00       	push   $0x425
f0101cbe:	68 55 68 10 f0       	push   $0xf0106855
f0101cc3:	e8 78 e3 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101cc8:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101ccd:	f6 00 04             	testb  $0x4,(%eax)
f0101cd0:	75 19                	jne    f0101ceb <mem_init+0xa90>
f0101cd2:	68 a2 6a 10 f0       	push   $0xf0106aa2
f0101cd7:	68 7b 68 10 f0       	push   $0xf010687b
f0101cdc:	68 26 04 00 00       	push   $0x426
f0101ce1:	68 55 68 10 f0       	push   $0xf0106855
f0101ce6:	e8 55 e3 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ceb:	6a 02                	push   $0x2
f0101ced:	68 00 10 00 00       	push   $0x1000
f0101cf2:	56                   	push   %esi
f0101cf3:	50                   	push   %eax
f0101cf4:	e8 92 f4 ff ff       	call   f010118b <page_insert>
f0101cf9:	83 c4 10             	add    $0x10,%esp
f0101cfc:	85 c0                	test   %eax,%eax
f0101cfe:	74 19                	je     f0101d19 <mem_init+0xabe>
f0101d00:	68 a8 61 10 f0       	push   $0xf01061a8
f0101d05:	68 7b 68 10 f0       	push   $0xf010687b
f0101d0a:	68 29 04 00 00       	push   $0x429
f0101d0f:	68 55 68 10 f0       	push   $0xf0106855
f0101d14:	e8 27 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d19:	83 ec 04             	sub    $0x4,%esp
f0101d1c:	6a 00                	push   $0x0
f0101d1e:	68 00 10 00 00       	push   $0x1000
f0101d23:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d29:	e8 5e f2 ff ff       	call   f0100f8c <pgdir_walk>
f0101d2e:	83 c4 10             	add    $0x10,%esp
f0101d31:	f6 00 02             	testb  $0x2,(%eax)
f0101d34:	75 19                	jne    f0101d4f <mem_init+0xaf4>
f0101d36:	68 c8 62 10 f0       	push   $0xf01062c8
f0101d3b:	68 7b 68 10 f0       	push   $0xf010687b
f0101d40:	68 2a 04 00 00       	push   $0x42a
f0101d45:	68 55 68 10 f0       	push   $0xf0106855
f0101d4a:	e8 f1 e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d4f:	83 ec 04             	sub    $0x4,%esp
f0101d52:	6a 00                	push   $0x0
f0101d54:	68 00 10 00 00       	push   $0x1000
f0101d59:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d5f:	e8 28 f2 ff ff       	call   f0100f8c <pgdir_walk>
f0101d64:	83 c4 10             	add    $0x10,%esp
f0101d67:	f6 00 04             	testb  $0x4,(%eax)
f0101d6a:	74 19                	je     f0101d85 <mem_init+0xb2a>
f0101d6c:	68 fc 62 10 f0       	push   $0xf01062fc
f0101d71:	68 7b 68 10 f0       	push   $0xf010687b
f0101d76:	68 2b 04 00 00       	push   $0x42b
f0101d7b:	68 55 68 10 f0       	push   $0xf0106855
f0101d80:	e8 bb e2 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d85:	6a 02                	push   $0x2
f0101d87:	68 00 00 40 00       	push   $0x400000
f0101d8c:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101d8f:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d95:	e8 f1 f3 ff ff       	call   f010118b <page_insert>
f0101d9a:	83 c4 10             	add    $0x10,%esp
f0101d9d:	85 c0                	test   %eax,%eax
f0101d9f:	78 19                	js     f0101dba <mem_init+0xb5f>
f0101da1:	68 34 63 10 f0       	push   $0xf0106334
f0101da6:	68 7b 68 10 f0       	push   $0xf010687b
f0101dab:	68 2e 04 00 00       	push   $0x42e
f0101db0:	68 55 68 10 f0       	push   $0xf0106855
f0101db5:	e8 86 e2 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101dba:	6a 02                	push   $0x2
f0101dbc:	68 00 10 00 00       	push   $0x1000
f0101dc1:	53                   	push   %ebx
f0101dc2:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101dc8:	e8 be f3 ff ff       	call   f010118b <page_insert>
f0101dcd:	83 c4 10             	add    $0x10,%esp
f0101dd0:	85 c0                	test   %eax,%eax
f0101dd2:	74 19                	je     f0101ded <mem_init+0xb92>
f0101dd4:	68 6c 63 10 f0       	push   $0xf010636c
f0101dd9:	68 7b 68 10 f0       	push   $0xf010687b
f0101dde:	68 31 04 00 00       	push   $0x431
f0101de3:	68 55 68 10 f0       	push   $0xf0106855
f0101de8:	e8 53 e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ded:	83 ec 04             	sub    $0x4,%esp
f0101df0:	6a 00                	push   $0x0
f0101df2:	68 00 10 00 00       	push   $0x1000
f0101df7:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101dfd:	e8 8a f1 ff ff       	call   f0100f8c <pgdir_walk>
f0101e02:	83 c4 10             	add    $0x10,%esp
f0101e05:	f6 00 04             	testb  $0x4,(%eax)
f0101e08:	74 19                	je     f0101e23 <mem_init+0xbc8>
f0101e0a:	68 fc 62 10 f0       	push   $0xf01062fc
f0101e0f:	68 7b 68 10 f0       	push   $0xf010687b
f0101e14:	68 32 04 00 00       	push   $0x432
f0101e19:	68 55 68 10 f0       	push   $0xf0106855
f0101e1e:	e8 1d e2 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e23:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101e29:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e2e:	89 f8                	mov    %edi,%eax
f0101e30:	e8 36 ec ff ff       	call   f0100a6b <check_va2pa>
f0101e35:	89 c1                	mov    %eax,%ecx
f0101e37:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e3a:	89 d8                	mov    %ebx,%eax
f0101e3c:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0101e42:	c1 f8 03             	sar    $0x3,%eax
f0101e45:	c1 e0 0c             	shl    $0xc,%eax
f0101e48:	39 c1                	cmp    %eax,%ecx
f0101e4a:	74 19                	je     f0101e65 <mem_init+0xc0a>
f0101e4c:	68 a8 63 10 f0       	push   $0xf01063a8
f0101e51:	68 7b 68 10 f0       	push   $0xf010687b
f0101e56:	68 35 04 00 00       	push   $0x435
f0101e5b:	68 55 68 10 f0       	push   $0xf0106855
f0101e60:	e8 db e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e65:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e6a:	89 f8                	mov    %edi,%eax
f0101e6c:	e8 fa eb ff ff       	call   f0100a6b <check_va2pa>
f0101e71:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101e74:	74 19                	je     f0101e8f <mem_init+0xc34>
f0101e76:	68 d4 63 10 f0       	push   $0xf01063d4
f0101e7b:	68 7b 68 10 f0       	push   $0xf010687b
f0101e80:	68 36 04 00 00       	push   $0x436
f0101e85:	68 55 68 10 f0       	push   $0xf0106855
f0101e8a:	e8 b1 e1 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e8f:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101e94:	74 19                	je     f0101eaf <mem_init+0xc54>
f0101e96:	68 b8 6a 10 f0       	push   $0xf0106ab8
f0101e9b:	68 7b 68 10 f0       	push   $0xf010687b
f0101ea0:	68 38 04 00 00       	push   $0x438
f0101ea5:	68 55 68 10 f0       	push   $0xf0106855
f0101eaa:	e8 91 e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101eaf:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101eb4:	74 19                	je     f0101ecf <mem_init+0xc74>
f0101eb6:	68 c9 6a 10 f0       	push   $0xf0106ac9
f0101ebb:	68 7b 68 10 f0       	push   $0xf010687b
f0101ec0:	68 39 04 00 00       	push   $0x439
f0101ec5:	68 55 68 10 f0       	push   $0xf0106855
f0101eca:	e8 71 e1 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101ecf:	83 ec 0c             	sub    $0xc,%esp
f0101ed2:	6a 00                	push   $0x0
f0101ed4:	e8 e1 ef ff ff       	call   f0100eba <page_alloc>
f0101ed9:	83 c4 10             	add    $0x10,%esp
f0101edc:	85 c0                	test   %eax,%eax
f0101ede:	74 04                	je     f0101ee4 <mem_init+0xc89>
f0101ee0:	39 c6                	cmp    %eax,%esi
f0101ee2:	74 19                	je     f0101efd <mem_init+0xca2>
f0101ee4:	68 04 64 10 f0       	push   $0xf0106404
f0101ee9:	68 7b 68 10 f0       	push   $0xf010687b
f0101eee:	68 3c 04 00 00       	push   $0x43c
f0101ef3:	68 55 68 10 f0       	push   $0xf0106855
f0101ef8:	e8 43 e1 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101efd:	83 ec 08             	sub    $0x8,%esp
f0101f00:	6a 00                	push   $0x0
f0101f02:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101f08:	e8 35 f2 ff ff       	call   f0101142 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f0d:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101f13:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f18:	89 f8                	mov    %edi,%eax
f0101f1a:	e8 4c eb ff ff       	call   f0100a6b <check_va2pa>
f0101f1f:	83 c4 10             	add    $0x10,%esp
f0101f22:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f25:	74 19                	je     f0101f40 <mem_init+0xce5>
f0101f27:	68 28 64 10 f0       	push   $0xf0106428
f0101f2c:	68 7b 68 10 f0       	push   $0xf010687b
f0101f31:	68 40 04 00 00       	push   $0x440
f0101f36:	68 55 68 10 f0       	push   $0xf0106855
f0101f3b:	e8 00 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f40:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f45:	89 f8                	mov    %edi,%eax
f0101f47:	e8 1f eb ff ff       	call   f0100a6b <check_va2pa>
f0101f4c:	89 da                	mov    %ebx,%edx
f0101f4e:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101f54:	c1 fa 03             	sar    $0x3,%edx
f0101f57:	c1 e2 0c             	shl    $0xc,%edx
f0101f5a:	39 d0                	cmp    %edx,%eax
f0101f5c:	74 19                	je     f0101f77 <mem_init+0xd1c>
f0101f5e:	68 d4 63 10 f0       	push   $0xf01063d4
f0101f63:	68 7b 68 10 f0       	push   $0xf010687b
f0101f68:	68 41 04 00 00       	push   $0x441
f0101f6d:	68 55 68 10 f0       	push   $0xf0106855
f0101f72:	e8 c9 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101f77:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101f7c:	74 19                	je     f0101f97 <mem_init+0xd3c>
f0101f7e:	68 6f 6a 10 f0       	push   $0xf0106a6f
f0101f83:	68 7b 68 10 f0       	push   $0xf010687b
f0101f88:	68 42 04 00 00       	push   $0x442
f0101f8d:	68 55 68 10 f0       	push   $0xf0106855
f0101f92:	e8 a9 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101f97:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f9c:	74 19                	je     f0101fb7 <mem_init+0xd5c>
f0101f9e:	68 c9 6a 10 f0       	push   $0xf0106ac9
f0101fa3:	68 7b 68 10 f0       	push   $0xf010687b
f0101fa8:	68 43 04 00 00       	push   $0x443
f0101fad:	68 55 68 10 f0       	push   $0xf0106855
f0101fb2:	e8 89 e0 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101fb7:	6a 00                	push   $0x0
f0101fb9:	68 00 10 00 00       	push   $0x1000
f0101fbe:	53                   	push   %ebx
f0101fbf:	57                   	push   %edi
f0101fc0:	e8 c6 f1 ff ff       	call   f010118b <page_insert>
f0101fc5:	83 c4 10             	add    $0x10,%esp
f0101fc8:	85 c0                	test   %eax,%eax
f0101fca:	74 19                	je     f0101fe5 <mem_init+0xd8a>
f0101fcc:	68 4c 64 10 f0       	push   $0xf010644c
f0101fd1:	68 7b 68 10 f0       	push   $0xf010687b
f0101fd6:	68 46 04 00 00       	push   $0x446
f0101fdb:	68 55 68 10 f0       	push   $0xf0106855
f0101fe0:	e8 5b e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0101fe5:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101fea:	75 19                	jne    f0102005 <mem_init+0xdaa>
f0101fec:	68 da 6a 10 f0       	push   $0xf0106ada
f0101ff1:	68 7b 68 10 f0       	push   $0xf010687b
f0101ff6:	68 47 04 00 00       	push   $0x447
f0101ffb:	68 55 68 10 f0       	push   $0xf0106855
f0102000:	e8 3b e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102005:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102008:	74 19                	je     f0102023 <mem_init+0xdc8>
f010200a:	68 e6 6a 10 f0       	push   $0xf0106ae6
f010200f:	68 7b 68 10 f0       	push   $0xf010687b
f0102014:	68 48 04 00 00       	push   $0x448
f0102019:	68 55 68 10 f0       	push   $0xf0106855
f010201e:	e8 1d e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102023:	83 ec 08             	sub    $0x8,%esp
f0102026:	68 00 10 00 00       	push   $0x1000
f010202b:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102031:	e8 0c f1 ff ff       	call   f0101142 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102036:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f010203c:	ba 00 00 00 00       	mov    $0x0,%edx
f0102041:	89 f8                	mov    %edi,%eax
f0102043:	e8 23 ea ff ff       	call   f0100a6b <check_va2pa>
f0102048:	83 c4 10             	add    $0x10,%esp
f010204b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010204e:	74 19                	je     f0102069 <mem_init+0xe0e>
f0102050:	68 28 64 10 f0       	push   $0xf0106428
f0102055:	68 7b 68 10 f0       	push   $0xf010687b
f010205a:	68 4c 04 00 00       	push   $0x44c
f010205f:	68 55 68 10 f0       	push   $0xf0106855
f0102064:	e8 d7 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102069:	ba 00 10 00 00       	mov    $0x1000,%edx
f010206e:	89 f8                	mov    %edi,%eax
f0102070:	e8 f6 e9 ff ff       	call   f0100a6b <check_va2pa>
f0102075:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102078:	74 19                	je     f0102093 <mem_init+0xe38>
f010207a:	68 84 64 10 f0       	push   $0xf0106484
f010207f:	68 7b 68 10 f0       	push   $0xf010687b
f0102084:	68 4d 04 00 00       	push   $0x44d
f0102089:	68 55 68 10 f0       	push   $0xf0106855
f010208e:	e8 ad df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102093:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102098:	74 19                	je     f01020b3 <mem_init+0xe58>
f010209a:	68 fb 6a 10 f0       	push   $0xf0106afb
f010209f:	68 7b 68 10 f0       	push   $0xf010687b
f01020a4:	68 4e 04 00 00       	push   $0x44e
f01020a9:	68 55 68 10 f0       	push   $0xf0106855
f01020ae:	e8 8d df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01020b3:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020b8:	74 19                	je     f01020d3 <mem_init+0xe78>
f01020ba:	68 c9 6a 10 f0       	push   $0xf0106ac9
f01020bf:	68 7b 68 10 f0       	push   $0xf010687b
f01020c4:	68 4f 04 00 00       	push   $0x44f
f01020c9:	68 55 68 10 f0       	push   $0xf0106855
f01020ce:	e8 6d df ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01020d3:	83 ec 0c             	sub    $0xc,%esp
f01020d6:	6a 00                	push   $0x0
f01020d8:	e8 dd ed ff ff       	call   f0100eba <page_alloc>
f01020dd:	83 c4 10             	add    $0x10,%esp
f01020e0:	39 c3                	cmp    %eax,%ebx
f01020e2:	75 04                	jne    f01020e8 <mem_init+0xe8d>
f01020e4:	85 c0                	test   %eax,%eax
f01020e6:	75 19                	jne    f0102101 <mem_init+0xea6>
f01020e8:	68 ac 64 10 f0       	push   $0xf01064ac
f01020ed:	68 7b 68 10 f0       	push   $0xf010687b
f01020f2:	68 52 04 00 00       	push   $0x452
f01020f7:	68 55 68 10 f0       	push   $0xf0106855
f01020fc:	e8 3f df ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102101:	83 ec 0c             	sub    $0xc,%esp
f0102104:	6a 00                	push   $0x0
f0102106:	e8 af ed ff ff       	call   f0100eba <page_alloc>
f010210b:	83 c4 10             	add    $0x10,%esp
f010210e:	85 c0                	test   %eax,%eax
f0102110:	74 19                	je     f010212b <mem_init+0xed0>
f0102112:	68 1d 6a 10 f0       	push   $0xf0106a1d
f0102117:	68 7b 68 10 f0       	push   $0xf010687b
f010211c:	68 55 04 00 00       	push   $0x455
f0102121:	68 55 68 10 f0       	push   $0xf0106855
f0102126:	e8 15 df ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010212b:	8b 0d 8c ae 22 f0    	mov    0xf022ae8c,%ecx
f0102131:	8b 11                	mov    (%ecx),%edx
f0102133:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102139:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010213c:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102142:	c1 f8 03             	sar    $0x3,%eax
f0102145:	c1 e0 0c             	shl    $0xc,%eax
f0102148:	39 c2                	cmp    %eax,%edx
f010214a:	74 19                	je     f0102165 <mem_init+0xf0a>
f010214c:	68 50 61 10 f0       	push   $0xf0106150
f0102151:	68 7b 68 10 f0       	push   $0xf010687b
f0102156:	68 58 04 00 00       	push   $0x458
f010215b:	68 55 68 10 f0       	push   $0xf0106855
f0102160:	e8 db de ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102165:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010216b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010216e:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102173:	74 19                	je     f010218e <mem_init+0xf33>
f0102175:	68 80 6a 10 f0       	push   $0xf0106a80
f010217a:	68 7b 68 10 f0       	push   $0xf010687b
f010217f:	68 5a 04 00 00       	push   $0x45a
f0102184:	68 55 68 10 f0       	push   $0xf0106855
f0102189:	e8 b2 de ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f010218e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102191:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102197:	83 ec 0c             	sub    $0xc,%esp
f010219a:	50                   	push   %eax
f010219b:	e8 a0 ed ff ff       	call   f0100f40 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01021a0:	83 c4 0c             	add    $0xc,%esp
f01021a3:	6a 01                	push   $0x1
f01021a5:	68 00 10 40 00       	push   $0x401000
f01021aa:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01021b0:	e8 d7 ed ff ff       	call   f0100f8c <pgdir_walk>
f01021b5:	89 c7                	mov    %eax,%edi
f01021b7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01021ba:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01021bf:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021c2:	8b 40 04             	mov    0x4(%eax),%eax
f01021c5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01021ca:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f01021d0:	89 c2                	mov    %eax,%edx
f01021d2:	c1 ea 0c             	shr    $0xc,%edx
f01021d5:	83 c4 10             	add    $0x10,%esp
f01021d8:	39 ca                	cmp    %ecx,%edx
f01021da:	72 15                	jb     f01021f1 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021dc:	50                   	push   %eax
f01021dd:	68 84 59 10 f0       	push   $0xf0105984
f01021e2:	68 61 04 00 00       	push   $0x461
f01021e7:	68 55 68 10 f0       	push   $0xf0106855
f01021ec:	e8 4f de ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01021f1:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f01021f6:	39 c7                	cmp    %eax,%edi
f01021f8:	74 19                	je     f0102213 <mem_init+0xfb8>
f01021fa:	68 0c 6b 10 f0       	push   $0xf0106b0c
f01021ff:	68 7b 68 10 f0       	push   $0xf010687b
f0102204:	68 62 04 00 00       	push   $0x462
f0102209:	68 55 68 10 f0       	push   $0xf0106855
f010220e:	e8 2d de ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102213:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102216:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f010221d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102220:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102226:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f010222c:	c1 f8 03             	sar    $0x3,%eax
f010222f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102232:	89 c2                	mov    %eax,%edx
f0102234:	c1 ea 0c             	shr    $0xc,%edx
f0102237:	39 d1                	cmp    %edx,%ecx
f0102239:	77 12                	ja     f010224d <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010223b:	50                   	push   %eax
f010223c:	68 84 59 10 f0       	push   $0xf0105984
f0102241:	6a 58                	push   $0x58
f0102243:	68 61 68 10 f0       	push   $0xf0106861
f0102248:	e8 f3 dd ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010224d:	83 ec 04             	sub    $0x4,%esp
f0102250:	68 00 10 00 00       	push   $0x1000
f0102255:	68 ff 00 00 00       	push   $0xff
f010225a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010225f:	50                   	push   %eax
f0102260:	e8 50 2a 00 00       	call   f0104cb5 <memset>
	page_free(pp0);
f0102265:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102268:	89 3c 24             	mov    %edi,(%esp)
f010226b:	e8 d0 ec ff ff       	call   f0100f40 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102270:	83 c4 0c             	add    $0xc,%esp
f0102273:	6a 01                	push   $0x1
f0102275:	6a 00                	push   $0x0
f0102277:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f010227d:	e8 0a ed ff ff       	call   f0100f8c <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102282:	89 fa                	mov    %edi,%edx
f0102284:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f010228a:	c1 fa 03             	sar    $0x3,%edx
f010228d:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102290:	89 d0                	mov    %edx,%eax
f0102292:	c1 e8 0c             	shr    $0xc,%eax
f0102295:	83 c4 10             	add    $0x10,%esp
f0102298:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f010229e:	72 12                	jb     f01022b2 <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022a0:	52                   	push   %edx
f01022a1:	68 84 59 10 f0       	push   $0xf0105984
f01022a6:	6a 58                	push   $0x58
f01022a8:	68 61 68 10 f0       	push   $0xf0106861
f01022ad:	e8 8e dd ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01022b2:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01022b8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01022bb:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01022c1:	f6 00 01             	testb  $0x1,(%eax)
f01022c4:	74 19                	je     f01022df <mem_init+0x1084>
f01022c6:	68 24 6b 10 f0       	push   $0xf0106b24
f01022cb:	68 7b 68 10 f0       	push   $0xf010687b
f01022d0:	68 6c 04 00 00       	push   $0x46c
f01022d5:	68 55 68 10 f0       	push   $0xf0106855
f01022da:	e8 61 dd ff ff       	call   f0100040 <_panic>
f01022df:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01022e2:	39 d0                	cmp    %edx,%eax
f01022e4:	75 db                	jne    f01022c1 <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01022e6:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01022eb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01022f1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022f4:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01022fa:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01022fd:	89 0d 40 a2 22 f0    	mov    %ecx,0xf022a240

	// free the pages we took
	page_free(pp0);
f0102303:	83 ec 0c             	sub    $0xc,%esp
f0102306:	50                   	push   %eax
f0102307:	e8 34 ec ff ff       	call   f0100f40 <page_free>
	page_free(pp1);
f010230c:	89 1c 24             	mov    %ebx,(%esp)
f010230f:	e8 2c ec ff ff       	call   f0100f40 <page_free>
	page_free(pp2);
f0102314:	89 34 24             	mov    %esi,(%esp)
f0102317:	e8 24 ec ff ff       	call   f0100f40 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f010231c:	83 c4 08             	add    $0x8,%esp
f010231f:	68 01 10 00 00       	push   $0x1001
f0102324:	6a 00                	push   $0x0
f0102326:	e8 c6 ee ff ff       	call   f01011f1 <mmio_map_region>
f010232b:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f010232d:	83 c4 08             	add    $0x8,%esp
f0102330:	68 00 10 00 00       	push   $0x1000
f0102335:	6a 00                	push   $0x0
f0102337:	e8 b5 ee ff ff       	call   f01011f1 <mmio_map_region>
f010233c:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f010233e:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f0102344:	83 c4 10             	add    $0x10,%esp
f0102347:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f010234d:	76 07                	jbe    f0102356 <mem_init+0x10fb>
f010234f:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102354:	76 19                	jbe    f010236f <mem_init+0x1114>
f0102356:	68 d0 64 10 f0       	push   $0xf01064d0
f010235b:	68 7b 68 10 f0       	push   $0xf010687b
f0102360:	68 7c 04 00 00       	push   $0x47c
f0102365:	68 55 68 10 f0       	push   $0xf0106855
f010236a:	e8 d1 dc ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f010236f:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f0102375:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f010237b:	77 08                	ja     f0102385 <mem_init+0x112a>
f010237d:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102383:	77 19                	ja     f010239e <mem_init+0x1143>
f0102385:	68 f8 64 10 f0       	push   $0xf01064f8
f010238a:	68 7b 68 10 f0       	push   $0xf010687b
f010238f:	68 7d 04 00 00       	push   $0x47d
f0102394:	68 55 68 10 f0       	push   $0xf0106855
f0102399:	e8 a2 dc ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f010239e:	89 da                	mov    %ebx,%edx
f01023a0:	09 f2                	or     %esi,%edx
f01023a2:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f01023a8:	74 19                	je     f01023c3 <mem_init+0x1168>
f01023aa:	68 20 65 10 f0       	push   $0xf0106520
f01023af:	68 7b 68 10 f0       	push   $0xf010687b
f01023b4:	68 7f 04 00 00       	push   $0x47f
f01023b9:	68 55 68 10 f0       	push   $0xf0106855
f01023be:	e8 7d dc ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f01023c3:	39 c6                	cmp    %eax,%esi
f01023c5:	73 19                	jae    f01023e0 <mem_init+0x1185>
f01023c7:	68 3b 6b 10 f0       	push   $0xf0106b3b
f01023cc:	68 7b 68 10 f0       	push   $0xf010687b
f01023d1:	68 81 04 00 00       	push   $0x481
f01023d6:	68 55 68 10 f0       	push   $0xf0106855
f01023db:	e8 60 dc ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f01023e0:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f01023e6:	89 da                	mov    %ebx,%edx
f01023e8:	89 f8                	mov    %edi,%eax
f01023ea:	e8 7c e6 ff ff       	call   f0100a6b <check_va2pa>
f01023ef:	85 c0                	test   %eax,%eax
f01023f1:	74 19                	je     f010240c <mem_init+0x11b1>
f01023f3:	68 48 65 10 f0       	push   $0xf0106548
f01023f8:	68 7b 68 10 f0       	push   $0xf010687b
f01023fd:	68 83 04 00 00       	push   $0x483
f0102402:	68 55 68 10 f0       	push   $0xf0106855
f0102407:	e8 34 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f010240c:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102412:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102415:	89 c2                	mov    %eax,%edx
f0102417:	89 f8                	mov    %edi,%eax
f0102419:	e8 4d e6 ff ff       	call   f0100a6b <check_va2pa>
f010241e:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102423:	74 19                	je     f010243e <mem_init+0x11e3>
f0102425:	68 6c 65 10 f0       	push   $0xf010656c
f010242a:	68 7b 68 10 f0       	push   $0xf010687b
f010242f:	68 84 04 00 00       	push   $0x484
f0102434:	68 55 68 10 f0       	push   $0xf0106855
f0102439:	e8 02 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f010243e:	89 f2                	mov    %esi,%edx
f0102440:	89 f8                	mov    %edi,%eax
f0102442:	e8 24 e6 ff ff       	call   f0100a6b <check_va2pa>
f0102447:	85 c0                	test   %eax,%eax
f0102449:	74 19                	je     f0102464 <mem_init+0x1209>
f010244b:	68 9c 65 10 f0       	push   $0xf010659c
f0102450:	68 7b 68 10 f0       	push   $0xf010687b
f0102455:	68 85 04 00 00       	push   $0x485
f010245a:	68 55 68 10 f0       	push   $0xf0106855
f010245f:	e8 dc db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102464:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f010246a:	89 f8                	mov    %edi,%eax
f010246c:	e8 fa e5 ff ff       	call   f0100a6b <check_va2pa>
f0102471:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102474:	74 19                	je     f010248f <mem_init+0x1234>
f0102476:	68 c0 65 10 f0       	push   $0xf01065c0
f010247b:	68 7b 68 10 f0       	push   $0xf010687b
f0102480:	68 86 04 00 00       	push   $0x486
f0102485:	68 55 68 10 f0       	push   $0xf0106855
f010248a:	e8 b1 db ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f010248f:	83 ec 04             	sub    $0x4,%esp
f0102492:	6a 00                	push   $0x0
f0102494:	53                   	push   %ebx
f0102495:	57                   	push   %edi
f0102496:	e8 f1 ea ff ff       	call   f0100f8c <pgdir_walk>
f010249b:	83 c4 10             	add    $0x10,%esp
f010249e:	f6 00 1a             	testb  $0x1a,(%eax)
f01024a1:	75 19                	jne    f01024bc <mem_init+0x1261>
f01024a3:	68 ec 65 10 f0       	push   $0xf01065ec
f01024a8:	68 7b 68 10 f0       	push   $0xf010687b
f01024ad:	68 88 04 00 00       	push   $0x488
f01024b2:	68 55 68 10 f0       	push   $0xf0106855
f01024b7:	e8 84 db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f01024bc:	83 ec 04             	sub    $0x4,%esp
f01024bf:	6a 00                	push   $0x0
f01024c1:	53                   	push   %ebx
f01024c2:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01024c8:	e8 bf ea ff ff       	call   f0100f8c <pgdir_walk>
f01024cd:	8b 00                	mov    (%eax),%eax
f01024cf:	83 c4 10             	add    $0x10,%esp
f01024d2:	83 e0 04             	and    $0x4,%eax
f01024d5:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01024d8:	74 19                	je     f01024f3 <mem_init+0x1298>
f01024da:	68 30 66 10 f0       	push   $0xf0106630
f01024df:	68 7b 68 10 f0       	push   $0xf010687b
f01024e4:	68 89 04 00 00       	push   $0x489
f01024e9:	68 55 68 10 f0       	push   $0xf0106855
f01024ee:	e8 4d db ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f01024f3:	83 ec 04             	sub    $0x4,%esp
f01024f6:	6a 00                	push   $0x0
f01024f8:	53                   	push   %ebx
f01024f9:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01024ff:	e8 88 ea ff ff       	call   f0100f8c <pgdir_walk>
f0102504:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f010250a:	83 c4 0c             	add    $0xc,%esp
f010250d:	6a 00                	push   $0x0
f010250f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102512:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102518:	e8 6f ea ff ff       	call   f0100f8c <pgdir_walk>
f010251d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102523:	83 c4 0c             	add    $0xc,%esp
f0102526:	6a 00                	push   $0x0
f0102528:	56                   	push   %esi
f0102529:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f010252f:	e8 58 ea ff ff       	call   f0100f8c <pgdir_walk>
f0102534:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f010253a:	c7 04 24 4d 6b 10 f0 	movl   $0xf0106b4d,(%esp)
f0102541:	e8 7b 11 00 00       	call   f01036c1 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U | PTE_P);
f0102546:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010254b:	83 c4 10             	add    $0x10,%esp
f010254e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102553:	77 15                	ja     f010256a <mem_init+0x130f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102555:	50                   	push   %eax
f0102556:	68 a8 59 10 f0       	push   $0xf01059a8
f010255b:	68 b7 00 00 00       	push   $0xb7
f0102560:	68 55 68 10 f0       	push   $0xf0106855
f0102565:	e8 d6 da ff ff       	call   f0100040 <_panic>
f010256a:	83 ec 08             	sub    $0x8,%esp
f010256d:	6a 05                	push   $0x5
f010256f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102574:	50                   	push   %eax
f0102575:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010257a:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010257f:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102584:	e8 c7 ea ff ff       	call   f0101050 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U | PTE_P);
f0102589:	a1 48 a2 22 f0       	mov    0xf022a248,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010258e:	83 c4 10             	add    $0x10,%esp
f0102591:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102596:	77 15                	ja     f01025ad <mem_init+0x1352>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102598:	50                   	push   %eax
f0102599:	68 a8 59 10 f0       	push   $0xf01059a8
f010259e:	68 bf 00 00 00       	push   $0xbf
f01025a3:	68 55 68 10 f0       	push   $0xf0106855
f01025a8:	e8 93 da ff ff       	call   f0100040 <_panic>
f01025ad:	83 ec 08             	sub    $0x8,%esp
f01025b0:	6a 05                	push   $0x5
f01025b2:	05 00 00 00 10       	add    $0x10000000,%eax
f01025b7:	50                   	push   %eax
f01025b8:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01025bd:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01025c2:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01025c7:	e8 84 ea ff ff       	call   f0101050 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025cc:	83 c4 10             	add    $0x10,%esp
f01025cf:	b8 00 50 11 f0       	mov    $0xf0115000,%eax
f01025d4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025d9:	77 15                	ja     f01025f0 <mem_init+0x1395>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025db:	50                   	push   %eax
f01025dc:	68 a8 59 10 f0       	push   $0xf01059a8
f01025e1:	68 cb 00 00 00       	push   $0xcb
f01025e6:	68 55 68 10 f0       	push   $0xf0106855
f01025eb:	e8 50 da ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01025f0:	83 ec 08             	sub    $0x8,%esp
f01025f3:	6a 02                	push   $0x2
f01025f5:	68 00 50 11 00       	push   $0x115000
f01025fa:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01025ff:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102604:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102609:	e8 42 ea ff ff       	call   f0101050 <boot_map_region>
f010260e:	c7 45 c4 00 c0 22 f0 	movl   $0xf022c000,-0x3c(%ebp)
f0102615:	83 c4 10             	add    $0x10,%esp
f0102618:	bb 00 c0 22 f0       	mov    $0xf022c000,%ebx
f010261d:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102622:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102628:	77 15                	ja     f010263f <mem_init+0x13e4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010262a:	53                   	push   %ebx
f010262b:	68 a8 59 10 f0       	push   $0xf01059a8
f0102630:	68 0b 01 00 00       	push   $0x10b
f0102635:	68 55 68 10 f0       	push   $0xf0106855
f010263a:	e8 01 da ff ff       	call   f0100040 <_panic>
	// LAB 4: Your code here:
	uintptr_t kstacktop_i;
	for(int i = 0;i < NCPU;i++)
	{
		kstacktop_i = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
		boot_map_region(kern_pgdir, kstacktop_i - KSTKSIZE, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W);
f010263f:	83 ec 08             	sub    $0x8,%esp
f0102642:	6a 02                	push   $0x2
f0102644:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f010264a:	50                   	push   %eax
f010264b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102650:	89 f2                	mov    %esi,%edx
f0102652:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102657:	e8 f4 e9 ff ff       	call   f0101050 <boot_map_region>
f010265c:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102662:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//             Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	uintptr_t kstacktop_i;
	for(int i = 0;i < NCPU;i++)
f0102668:	83 c4 10             	add    $0x10,%esp
f010266b:	b8 00 c0 26 f0       	mov    $0xf026c000,%eax
f0102670:	39 d8                	cmp    %ebx,%eax
f0102672:	75 ae                	jne    f0102622 <mem_init+0x13c7>
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	// Initialize the SMP-related parts of the memory map
	mem_init_mp();
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff-KERNBASE, 0, PTE_W);
f0102674:	83 ec 08             	sub    $0x8,%esp
f0102677:	6a 02                	push   $0x2
f0102679:	6a 00                	push   $0x0
f010267b:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102680:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102685:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f010268a:	e8 c1 e9 ff ff       	call   f0101050 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010268f:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102695:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f010269a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010269d:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01026a4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01026a9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026ac:	8b 35 90 ae 22 f0    	mov    0xf022ae90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026b2:	89 75 d0             	mov    %esi,-0x30(%ebp)
f01026b5:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026b8:	bb 00 00 00 00       	mov    $0x0,%ebx
f01026bd:	eb 55                	jmp    f0102714 <mem_init+0x14b9>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026bf:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01026c5:	89 f8                	mov    %edi,%eax
f01026c7:	e8 9f e3 ff ff       	call   f0100a6b <check_va2pa>
f01026cc:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01026d3:	77 15                	ja     f01026ea <mem_init+0x148f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026d5:	56                   	push   %esi
f01026d6:	68 a8 59 10 f0       	push   $0xf01059a8
f01026db:	68 a1 03 00 00       	push   $0x3a1
f01026e0:	68 55 68 10 f0       	push   $0xf0106855
f01026e5:	e8 56 d9 ff ff       	call   f0100040 <_panic>
f01026ea:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f01026f1:	39 c2                	cmp    %eax,%edx
f01026f3:	74 19                	je     f010270e <mem_init+0x14b3>
f01026f5:	68 64 66 10 f0       	push   $0xf0106664
f01026fa:	68 7b 68 10 f0       	push   $0xf010687b
f01026ff:	68 a1 03 00 00       	push   $0x3a1
f0102704:	68 55 68 10 f0       	push   $0xf0106855
f0102709:	e8 32 d9 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010270e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102714:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102717:	77 a6                	ja     f01026bf <mem_init+0x1464>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102719:	8b 35 48 a2 22 f0    	mov    0xf022a248,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010271f:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102722:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102727:	89 da                	mov    %ebx,%edx
f0102729:	89 f8                	mov    %edi,%eax
f010272b:	e8 3b e3 ff ff       	call   f0100a6b <check_va2pa>
f0102730:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102737:	77 15                	ja     f010274e <mem_init+0x14f3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102739:	56                   	push   %esi
f010273a:	68 a8 59 10 f0       	push   $0xf01059a8
f010273f:	68 a6 03 00 00       	push   $0x3a6
f0102744:	68 55 68 10 f0       	push   $0xf0106855
f0102749:	e8 f2 d8 ff ff       	call   f0100040 <_panic>
f010274e:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f0102755:	39 d0                	cmp    %edx,%eax
f0102757:	74 19                	je     f0102772 <mem_init+0x1517>
f0102759:	68 98 66 10 f0       	push   $0xf0106698
f010275e:	68 7b 68 10 f0       	push   $0xf010687b
f0102763:	68 a6 03 00 00       	push   $0x3a6
f0102768:	68 55 68 10 f0       	push   $0xf0106855
f010276d:	e8 ce d8 ff ff       	call   f0100040 <_panic>
f0102772:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102778:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f010277e:	75 a7                	jne    f0102727 <mem_init+0x14cc>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102780:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0102783:	c1 e6 0c             	shl    $0xc,%esi
f0102786:	bb 00 00 00 00       	mov    $0x0,%ebx
f010278b:	eb 30                	jmp    f01027bd <mem_init+0x1562>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010278d:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102793:	89 f8                	mov    %edi,%eax
f0102795:	e8 d1 e2 ff ff       	call   f0100a6b <check_va2pa>
f010279a:	39 c3                	cmp    %eax,%ebx
f010279c:	74 19                	je     f01027b7 <mem_init+0x155c>
f010279e:	68 cc 66 10 f0       	push   $0xf01066cc
f01027a3:	68 7b 68 10 f0       	push   $0xf010687b
f01027a8:	68 aa 03 00 00       	push   $0x3aa
f01027ad:	68 55 68 10 f0       	push   $0xf0106855
f01027b2:	e8 89 d8 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01027b7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01027bd:	39 f3                	cmp    %esi,%ebx
f01027bf:	72 cc                	jb     f010278d <mem_init+0x1532>
f01027c1:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f01027c6:	89 75 cc             	mov    %esi,-0x34(%ebp)
f01027c9:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01027cc:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01027cf:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f01027d5:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01027d8:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f01027da:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01027dd:	05 00 80 00 20       	add    $0x20008000,%eax
f01027e2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01027e5:	89 da                	mov    %ebx,%edx
f01027e7:	89 f8                	mov    %edi,%eax
f01027e9:	e8 7d e2 ff ff       	call   f0100a6b <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027ee:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01027f4:	77 15                	ja     f010280b <mem_init+0x15b0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027f6:	56                   	push   %esi
f01027f7:	68 a8 59 10 f0       	push   $0xf01059a8
f01027fc:	68 b2 03 00 00       	push   $0x3b2
f0102801:	68 55 68 10 f0       	push   $0xf0106855
f0102806:	e8 35 d8 ff ff       	call   f0100040 <_panic>
f010280b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010280e:	8d 94 0b 00 c0 22 f0 	lea    -0xfdd4000(%ebx,%ecx,1),%edx
f0102815:	39 d0                	cmp    %edx,%eax
f0102817:	74 19                	je     f0102832 <mem_init+0x15d7>
f0102819:	68 f4 66 10 f0       	push   $0xf01066f4
f010281e:	68 7b 68 10 f0       	push   $0xf010687b
f0102823:	68 b2 03 00 00       	push   $0x3b2
f0102828:	68 55 68 10 f0       	push   $0xf0106855
f010282d:	e8 0e d8 ff ff       	call   f0100040 <_panic>
f0102832:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102838:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f010283b:	75 a8                	jne    f01027e5 <mem_init+0x158a>
f010283d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102840:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f0102846:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102849:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f010284b:	89 da                	mov    %ebx,%edx
f010284d:	89 f8                	mov    %edi,%eax
f010284f:	e8 17 e2 ff ff       	call   f0100a6b <check_va2pa>
f0102854:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102857:	74 19                	je     f0102872 <mem_init+0x1617>
f0102859:	68 3c 67 10 f0       	push   $0xf010673c
f010285e:	68 7b 68 10 f0       	push   $0xf010687b
f0102863:	68 b4 03 00 00       	push   $0x3b4
f0102868:	68 55 68 10 f0       	push   $0xf0106855
f010286d:	e8 ce d7 ff ff       	call   f0100040 <_panic>
f0102872:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102878:	39 de                	cmp    %ebx,%esi
f010287a:	75 cf                	jne    f010284b <mem_init+0x15f0>
f010287c:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010287f:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f0102886:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f010288d:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102893:	81 fe 00 c0 26 f0    	cmp    $0xf026c000,%esi
f0102899:	0f 85 2d ff ff ff    	jne    f01027cc <mem_init+0x1571>
f010289f:	b8 00 00 00 00       	mov    $0x0,%eax
f01028a4:	eb 2a                	jmp    f01028d0 <mem_init+0x1675>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01028a6:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f01028ac:	83 fa 04             	cmp    $0x4,%edx
f01028af:	77 1f                	ja     f01028d0 <mem_init+0x1675>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f01028b1:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f01028b5:	75 7e                	jne    f0102935 <mem_init+0x16da>
f01028b7:	68 66 6b 10 f0       	push   $0xf0106b66
f01028bc:	68 7b 68 10 f0       	push   $0xf010687b
f01028c1:	68 bf 03 00 00       	push   $0x3bf
f01028c6:	68 55 68 10 f0       	push   $0xf0106855
f01028cb:	e8 70 d7 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01028d0:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01028d5:	76 3f                	jbe    f0102916 <mem_init+0x16bb>
				assert(pgdir[i] & PTE_P);
f01028d7:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01028da:	f6 c2 01             	test   $0x1,%dl
f01028dd:	75 19                	jne    f01028f8 <mem_init+0x169d>
f01028df:	68 66 6b 10 f0       	push   $0xf0106b66
f01028e4:	68 7b 68 10 f0       	push   $0xf010687b
f01028e9:	68 c3 03 00 00       	push   $0x3c3
f01028ee:	68 55 68 10 f0       	push   $0xf0106855
f01028f3:	e8 48 d7 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f01028f8:	f6 c2 02             	test   $0x2,%dl
f01028fb:	75 38                	jne    f0102935 <mem_init+0x16da>
f01028fd:	68 77 6b 10 f0       	push   $0xf0106b77
f0102902:	68 7b 68 10 f0       	push   $0xf010687b
f0102907:	68 c4 03 00 00       	push   $0x3c4
f010290c:	68 55 68 10 f0       	push   $0xf0106855
f0102911:	e8 2a d7 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102916:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f010291a:	74 19                	je     f0102935 <mem_init+0x16da>
f010291c:	68 88 6b 10 f0       	push   $0xf0106b88
f0102921:	68 7b 68 10 f0       	push   $0xf010687b
f0102926:	68 c6 03 00 00       	push   $0x3c6
f010292b:	68 55 68 10 f0       	push   $0xf0106855
f0102930:	e8 0b d7 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102935:	83 c0 01             	add    $0x1,%eax
f0102938:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010293d:	0f 86 63 ff ff ff    	jbe    f01028a6 <mem_init+0x164b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102943:	83 ec 0c             	sub    $0xc,%esp
f0102946:	68 60 67 10 f0       	push   $0xf0106760
f010294b:	e8 71 0d 00 00       	call   f01036c1 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102950:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102955:	83 c4 10             	add    $0x10,%esp
f0102958:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010295d:	77 15                	ja     f0102974 <mem_init+0x1719>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010295f:	50                   	push   %eax
f0102960:	68 a8 59 10 f0       	push   $0xf01059a8
f0102965:	68 e2 00 00 00       	push   $0xe2
f010296a:	68 55 68 10 f0       	push   $0xf0106855
f010296f:	e8 cc d6 ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102974:	05 00 00 00 10       	add    $0x10000000,%eax
f0102979:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010297c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102981:	e8 49 e1 ff ff       	call   f0100acf <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102986:	0f 20 c0             	mov    %cr0,%eax
f0102989:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f010298c:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102991:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102994:	83 ec 0c             	sub    $0xc,%esp
f0102997:	6a 00                	push   $0x0
f0102999:	e8 1c e5 ff ff       	call   f0100eba <page_alloc>
f010299e:	89 c3                	mov    %eax,%ebx
f01029a0:	83 c4 10             	add    $0x10,%esp
f01029a3:	85 c0                	test   %eax,%eax
f01029a5:	75 19                	jne    f01029c0 <mem_init+0x1765>
f01029a7:	68 72 69 10 f0       	push   $0xf0106972
f01029ac:	68 7b 68 10 f0       	push   $0xf010687b
f01029b1:	68 9e 04 00 00       	push   $0x49e
f01029b6:	68 55 68 10 f0       	push   $0xf0106855
f01029bb:	e8 80 d6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01029c0:	83 ec 0c             	sub    $0xc,%esp
f01029c3:	6a 00                	push   $0x0
f01029c5:	e8 f0 e4 ff ff       	call   f0100eba <page_alloc>
f01029ca:	89 c7                	mov    %eax,%edi
f01029cc:	83 c4 10             	add    $0x10,%esp
f01029cf:	85 c0                	test   %eax,%eax
f01029d1:	75 19                	jne    f01029ec <mem_init+0x1791>
f01029d3:	68 88 69 10 f0       	push   $0xf0106988
f01029d8:	68 7b 68 10 f0       	push   $0xf010687b
f01029dd:	68 9f 04 00 00       	push   $0x49f
f01029e2:	68 55 68 10 f0       	push   $0xf0106855
f01029e7:	e8 54 d6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01029ec:	83 ec 0c             	sub    $0xc,%esp
f01029ef:	6a 00                	push   $0x0
f01029f1:	e8 c4 e4 ff ff       	call   f0100eba <page_alloc>
f01029f6:	89 c6                	mov    %eax,%esi
f01029f8:	83 c4 10             	add    $0x10,%esp
f01029fb:	85 c0                	test   %eax,%eax
f01029fd:	75 19                	jne    f0102a18 <mem_init+0x17bd>
f01029ff:	68 9e 69 10 f0       	push   $0xf010699e
f0102a04:	68 7b 68 10 f0       	push   $0xf010687b
f0102a09:	68 a0 04 00 00       	push   $0x4a0
f0102a0e:	68 55 68 10 f0       	push   $0xf0106855
f0102a13:	e8 28 d6 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102a18:	83 ec 0c             	sub    $0xc,%esp
f0102a1b:	53                   	push   %ebx
f0102a1c:	e8 1f e5 ff ff       	call   f0100f40 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a21:	89 f8                	mov    %edi,%eax
f0102a23:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102a29:	c1 f8 03             	sar    $0x3,%eax
f0102a2c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a2f:	89 c2                	mov    %eax,%edx
f0102a31:	c1 ea 0c             	shr    $0xc,%edx
f0102a34:	83 c4 10             	add    $0x10,%esp
f0102a37:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102a3d:	72 12                	jb     f0102a51 <mem_init+0x17f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a3f:	50                   	push   %eax
f0102a40:	68 84 59 10 f0       	push   $0xf0105984
f0102a45:	6a 58                	push   $0x58
f0102a47:	68 61 68 10 f0       	push   $0xf0106861
f0102a4c:	e8 ef d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102a51:	83 ec 04             	sub    $0x4,%esp
f0102a54:	68 00 10 00 00       	push   $0x1000
f0102a59:	6a 01                	push   $0x1
f0102a5b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a60:	50                   	push   %eax
f0102a61:	e8 4f 22 00 00       	call   f0104cb5 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a66:	89 f0                	mov    %esi,%eax
f0102a68:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102a6e:	c1 f8 03             	sar    $0x3,%eax
f0102a71:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a74:	89 c2                	mov    %eax,%edx
f0102a76:	c1 ea 0c             	shr    $0xc,%edx
f0102a79:	83 c4 10             	add    $0x10,%esp
f0102a7c:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102a82:	72 12                	jb     f0102a96 <mem_init+0x183b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a84:	50                   	push   %eax
f0102a85:	68 84 59 10 f0       	push   $0xf0105984
f0102a8a:	6a 58                	push   $0x58
f0102a8c:	68 61 68 10 f0       	push   $0xf0106861
f0102a91:	e8 aa d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102a96:	83 ec 04             	sub    $0x4,%esp
f0102a99:	68 00 10 00 00       	push   $0x1000
f0102a9e:	6a 02                	push   $0x2
f0102aa0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102aa5:	50                   	push   %eax
f0102aa6:	e8 0a 22 00 00       	call   f0104cb5 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102aab:	6a 02                	push   $0x2
f0102aad:	68 00 10 00 00       	push   $0x1000
f0102ab2:	57                   	push   %edi
f0102ab3:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102ab9:	e8 cd e6 ff ff       	call   f010118b <page_insert>
	assert(pp1->pp_ref == 1);
f0102abe:	83 c4 20             	add    $0x20,%esp
f0102ac1:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102ac6:	74 19                	je     f0102ae1 <mem_init+0x1886>
f0102ac8:	68 6f 6a 10 f0       	push   $0xf0106a6f
f0102acd:	68 7b 68 10 f0       	push   $0xf010687b
f0102ad2:	68 a5 04 00 00       	push   $0x4a5
f0102ad7:	68 55 68 10 f0       	push   $0xf0106855
f0102adc:	e8 5f d5 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ae1:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102ae8:	01 01 01 
f0102aeb:	74 19                	je     f0102b06 <mem_init+0x18ab>
f0102aed:	68 80 67 10 f0       	push   $0xf0106780
f0102af2:	68 7b 68 10 f0       	push   $0xf010687b
f0102af7:	68 a6 04 00 00       	push   $0x4a6
f0102afc:	68 55 68 10 f0       	push   $0xf0106855
f0102b01:	e8 3a d5 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b06:	6a 02                	push   $0x2
f0102b08:	68 00 10 00 00       	push   $0x1000
f0102b0d:	56                   	push   %esi
f0102b0e:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102b14:	e8 72 e6 ff ff       	call   f010118b <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102b19:	83 c4 10             	add    $0x10,%esp
f0102b1c:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b23:	02 02 02 
f0102b26:	74 19                	je     f0102b41 <mem_init+0x18e6>
f0102b28:	68 a4 67 10 f0       	push   $0xf01067a4
f0102b2d:	68 7b 68 10 f0       	push   $0xf010687b
f0102b32:	68 a8 04 00 00       	push   $0x4a8
f0102b37:	68 55 68 10 f0       	push   $0xf0106855
f0102b3c:	e8 ff d4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102b41:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b46:	74 19                	je     f0102b61 <mem_init+0x1906>
f0102b48:	68 91 6a 10 f0       	push   $0xf0106a91
f0102b4d:	68 7b 68 10 f0       	push   $0xf010687b
f0102b52:	68 a9 04 00 00       	push   $0x4a9
f0102b57:	68 55 68 10 f0       	push   $0xf0106855
f0102b5c:	e8 df d4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102b61:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102b66:	74 19                	je     f0102b81 <mem_init+0x1926>
f0102b68:	68 fb 6a 10 f0       	push   $0xf0106afb
f0102b6d:	68 7b 68 10 f0       	push   $0xf010687b
f0102b72:	68 aa 04 00 00       	push   $0x4aa
f0102b77:	68 55 68 10 f0       	push   $0xf0106855
f0102b7c:	e8 bf d4 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b81:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b88:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b8b:	89 f0                	mov    %esi,%eax
f0102b8d:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102b93:	c1 f8 03             	sar    $0x3,%eax
f0102b96:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b99:	89 c2                	mov    %eax,%edx
f0102b9b:	c1 ea 0c             	shr    $0xc,%edx
f0102b9e:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102ba4:	72 12                	jb     f0102bb8 <mem_init+0x195d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ba6:	50                   	push   %eax
f0102ba7:	68 84 59 10 f0       	push   $0xf0105984
f0102bac:	6a 58                	push   $0x58
f0102bae:	68 61 68 10 f0       	push   $0xf0106861
f0102bb3:	e8 88 d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102bb8:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102bbf:	03 03 03 
f0102bc2:	74 19                	je     f0102bdd <mem_init+0x1982>
f0102bc4:	68 c8 67 10 f0       	push   $0xf01067c8
f0102bc9:	68 7b 68 10 f0       	push   $0xf010687b
f0102bce:	68 ac 04 00 00       	push   $0x4ac
f0102bd3:	68 55 68 10 f0       	push   $0xf0106855
f0102bd8:	e8 63 d4 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102bdd:	83 ec 08             	sub    $0x8,%esp
f0102be0:	68 00 10 00 00       	push   $0x1000
f0102be5:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102beb:	e8 52 e5 ff ff       	call   f0101142 <page_remove>
	assert(pp2->pp_ref == 0);
f0102bf0:	83 c4 10             	add    $0x10,%esp
f0102bf3:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102bf8:	74 19                	je     f0102c13 <mem_init+0x19b8>
f0102bfa:	68 c9 6a 10 f0       	push   $0xf0106ac9
f0102bff:	68 7b 68 10 f0       	push   $0xf010687b
f0102c04:	68 ae 04 00 00       	push   $0x4ae
f0102c09:	68 55 68 10 f0       	push   $0xf0106855
f0102c0e:	e8 2d d4 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c13:	8b 0d 8c ae 22 f0    	mov    0xf022ae8c,%ecx
f0102c19:	8b 11                	mov    (%ecx),%edx
f0102c1b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102c21:	89 d8                	mov    %ebx,%eax
f0102c23:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102c29:	c1 f8 03             	sar    $0x3,%eax
f0102c2c:	c1 e0 0c             	shl    $0xc,%eax
f0102c2f:	39 c2                	cmp    %eax,%edx
f0102c31:	74 19                	je     f0102c4c <mem_init+0x19f1>
f0102c33:	68 50 61 10 f0       	push   $0xf0106150
f0102c38:	68 7b 68 10 f0       	push   $0xf010687b
f0102c3d:	68 b1 04 00 00       	push   $0x4b1
f0102c42:	68 55 68 10 f0       	push   $0xf0106855
f0102c47:	e8 f4 d3 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102c4c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102c52:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102c57:	74 19                	je     f0102c72 <mem_init+0x1a17>
f0102c59:	68 80 6a 10 f0       	push   $0xf0106a80
f0102c5e:	68 7b 68 10 f0       	push   $0xf010687b
f0102c63:	68 b3 04 00 00       	push   $0x4b3
f0102c68:	68 55 68 10 f0       	push   $0xf0106855
f0102c6d:	e8 ce d3 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102c72:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102c78:	83 ec 0c             	sub    $0xc,%esp
f0102c7b:	53                   	push   %ebx
f0102c7c:	e8 bf e2 ff ff       	call   f0100f40 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102c81:	c7 04 24 f4 67 10 f0 	movl   $0xf01067f4,(%esp)
f0102c88:	e8 34 0a 00 00       	call   f01036c1 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102c8d:	83 c4 10             	add    $0x10,%esp
f0102c90:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c93:	5b                   	pop    %ebx
f0102c94:	5e                   	pop    %esi
f0102c95:	5f                   	pop    %edi
f0102c96:	5d                   	pop    %ebp
f0102c97:	c3                   	ret    

f0102c98 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102c98:	55                   	push   %ebp
f0102c99:	89 e5                	mov    %esp,%ebp
f0102c9b:	57                   	push   %edi
f0102c9c:	56                   	push   %esi
f0102c9d:	53                   	push   %ebx
f0102c9e:	83 ec 1c             	sub    $0x1c,%esp
f0102ca1:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102ca4:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	uint32_t start = (uint32_t)ROUNDDOWN(va, PGSIZE);
f0102ca7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102caa:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t end = (uint32_t)ROUNDUP(va+len, PGSIZE);
f0102cb0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102cb3:	03 45 10             	add    0x10(%ebp),%eax
f0102cb6:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102cbb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102cc0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(uint32_t i = start;i < end;i += PGSIZE)
f0102cc3:	eb 50                	jmp    f0102d15 <user_mem_check+0x7d>
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, (void *)i, 0);
f0102cc5:	83 ec 04             	sub    $0x4,%esp
f0102cc8:	6a 00                	push   $0x0
f0102cca:	53                   	push   %ebx
f0102ccb:	ff 77 60             	pushl  0x60(%edi)
f0102cce:	e8 b9 e2 ff ff       	call   f0100f8c <pgdir_walk>
// A user program can access a virtual address if (1) the address is below
// ULIM, and (2) the page table gives it permission. 
		//不满足的条件:1.地址大于ULIM 2.pte不存在 3.pte没有PTE_P的权限位 
		//4.pte的权限比perm高，说明当前权限无法访问对应内存
		if(i >= ULIM || !pte || !(*pte & PTE_P) || (*pte & perm) != perm)
f0102cd3:	83 c4 10             	add    $0x10,%esp
f0102cd6:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102cdc:	77 10                	ja     f0102cee <user_mem_check+0x56>
f0102cde:	85 c0                	test   %eax,%eax
f0102ce0:	74 0c                	je     f0102cee <user_mem_check+0x56>
f0102ce2:	8b 00                	mov    (%eax),%eax
f0102ce4:	a8 01                	test   $0x1,%al
f0102ce6:	74 06                	je     f0102cee <user_mem_check+0x56>
f0102ce8:	21 f0                	and    %esi,%eax
f0102cea:	39 c6                	cmp    %eax,%esi
f0102cec:	74 21                	je     f0102d0f <user_mem_check+0x77>
		{
// If there is an error, set the 'user_mem_check_addr' variable to the first
// erroneous virtual address.
			//如果出错的是va之前的地址，需要返回的也应该是va的地址
			if(i < (uint32_t)va)
f0102cee:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0102cf1:	73 0f                	jae    f0102d02 <user_mem_check+0x6a>
				user_mem_check_addr = (uint32_t)va;
f0102cf3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102cf6:	a3 3c a2 22 f0       	mov    %eax,0xf022a23c
			else 
				user_mem_check_addr = i;
			return -E_FAULT;
f0102cfb:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d00:	eb 1d                	jmp    f0102d1f <user_mem_check+0x87>
// erroneous virtual address.
			//如果出错的是va之前的地址，需要返回的也应该是va的地址
			if(i < (uint32_t)va)
				user_mem_check_addr = (uint32_t)va;
			else 
				user_mem_check_addr = i;
f0102d02:	89 1d 3c a2 22 f0    	mov    %ebx,0xf022a23c
			return -E_FAULT;
f0102d08:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d0d:	eb 10                	jmp    f0102d1f <user_mem_check+0x87>
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	uint32_t start = (uint32_t)ROUNDDOWN(va, PGSIZE);
	uint32_t end = (uint32_t)ROUNDUP(va+len, PGSIZE);
	for(uint32_t i = start;i < end;i += PGSIZE)
f0102d0f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102d15:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102d18:	72 ab                	jb     f0102cc5 <user_mem_check+0x2d>
			else 
				user_mem_check_addr = i;
			return -E_FAULT;
		} 
	}
	return 0;
f0102d1a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102d1f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d22:	5b                   	pop    %ebx
f0102d23:	5e                   	pop    %esi
f0102d24:	5f                   	pop    %edi
f0102d25:	5d                   	pop    %ebp
f0102d26:	c3                   	ret    

f0102d27 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102d27:	55                   	push   %ebp
f0102d28:	89 e5                	mov    %esp,%ebp
f0102d2a:	53                   	push   %ebx
f0102d2b:	83 ec 04             	sub    $0x4,%esp
f0102d2e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102d31:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d34:	83 c8 04             	or     $0x4,%eax
f0102d37:	50                   	push   %eax
f0102d38:	ff 75 10             	pushl  0x10(%ebp)
f0102d3b:	ff 75 0c             	pushl  0xc(%ebp)
f0102d3e:	53                   	push   %ebx
f0102d3f:	e8 54 ff ff ff       	call   f0102c98 <user_mem_check>
f0102d44:	83 c4 10             	add    $0x10,%esp
f0102d47:	85 c0                	test   %eax,%eax
f0102d49:	79 21                	jns    f0102d6c <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102d4b:	83 ec 04             	sub    $0x4,%esp
f0102d4e:	ff 35 3c a2 22 f0    	pushl  0xf022a23c
f0102d54:	ff 73 48             	pushl  0x48(%ebx)
f0102d57:	68 20 68 10 f0       	push   $0xf0106820
f0102d5c:	e8 60 09 00 00       	call   f01036c1 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102d61:	89 1c 24             	mov    %ebx,(%esp)
f0102d64:	e8 62 06 00 00       	call   f01033cb <env_destroy>
f0102d69:	83 c4 10             	add    $0x10,%esp
	}
}
f0102d6c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102d6f:	c9                   	leave  
f0102d70:	c3                   	ret    

f0102d71 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102d71:	55                   	push   %ebp
f0102d72:	89 e5                	mov    %esp,%ebp
f0102d74:	57                   	push   %edi
f0102d75:	56                   	push   %esi
f0102d76:	53                   	push   %ebx
f0102d77:	83 ec 14             	sub    $0x14,%esp
f0102d7a:	89 c7                	mov    %eax,%edi
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	//boot_map_region(e->env_pgdir, va, len, PADDR(envs), PTE_P | PTE_U | PTE_W);
	uint32_t start,end;
	start = ROUNDDOWN((uint32_t)va, PGSIZE);
f0102d7c:	89 d3                	mov    %edx,%ebx
f0102d7e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	end = ROUNDUP((uint32_t)(va + len), PGSIZE);
f0102d84:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102d8b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	cprintf("start=%x \n",start);
f0102d91:	53                   	push   %ebx
f0102d92:	68 96 6b 10 f0       	push   $0xf0106b96
f0102d97:	e8 25 09 00 00       	call   f01036c1 <cprintf>
	cprintf("end=%x \n",end);
f0102d9c:	83 c4 08             	add    $0x8,%esp
f0102d9f:	56                   	push   %esi
f0102da0:	68 a1 6b 10 f0       	push   $0xf0106ba1
f0102da5:	e8 17 09 00 00       	call   f01036c1 <cprintf>

	struct PageInfo *Page;
	int r;
	for(int i = start;i < end;i += PGSIZE)
f0102daa:	83 c4 10             	add    $0x10,%esp
f0102dad:	eb 56                	jmp    f0102e05 <region_alloc+0x94>
	{
		Page = page_alloc(0);
f0102daf:	83 ec 0c             	sub    $0xc,%esp
f0102db2:	6a 00                	push   $0x0
f0102db4:	e8 01 e1 ff ff       	call   f0100eba <page_alloc>
		if(!Page)
f0102db9:	83 c4 10             	add    $0x10,%esp
f0102dbc:	85 c0                	test   %eax,%eax
f0102dbe:	75 17                	jne    f0102dd7 <region_alloc+0x66>
			panic("page_alloc fail");
f0102dc0:	83 ec 04             	sub    $0x4,%esp
f0102dc3:	68 aa 6b 10 f0       	push   $0xf0106baa
f0102dc8:	68 34 01 00 00       	push   $0x134
f0102dcd:	68 ba 6b 10 f0       	push   $0xf0106bba
f0102dd2:	e8 69 d2 ff ff       	call   f0100040 <_panic>
		//r = page_insert(e->env_pgdir, Page, va, PTE_P | PTE_U | PTE_W);
		r = page_insert(e->env_pgdir, Page, (void *)i, PTE_U | PTE_W);
f0102dd7:	6a 06                	push   $0x6
f0102dd9:	53                   	push   %ebx
f0102dda:	50                   	push   %eax
f0102ddb:	ff 77 60             	pushl  0x60(%edi)
f0102dde:	e8 a8 e3 ff ff       	call   f010118b <page_insert>
		if(r != 0)
f0102de3:	83 c4 10             	add    $0x10,%esp
f0102de6:	85 c0                	test   %eax,%eax
f0102de8:	74 15                	je     f0102dff <region_alloc+0x8e>
			panic("region_alloc: %e", r);
f0102dea:	50                   	push   %eax
f0102deb:	68 c5 6b 10 f0       	push   $0xf0106bc5
f0102df0:	68 38 01 00 00       	push   $0x138
f0102df5:	68 ba 6b 10 f0       	push   $0xf0106bba
f0102dfa:	e8 41 d2 ff ff       	call   f0100040 <_panic>
	cprintf("start=%x \n",start);
	cprintf("end=%x \n",end);

	struct PageInfo *Page;
	int r;
	for(int i = start;i < end;i += PGSIZE)
f0102dff:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102e05:	39 de                	cmp    %ebx,%esi
f0102e07:	77 a6                	ja     f0102daf <region_alloc+0x3e>
		r = page_insert(e->env_pgdir, Page, (void *)i, PTE_U | PTE_W);
		if(r != 0)
			panic("region_alloc: %e", r);
			//panic("region_alloc fail");
	}
}
f0102e09:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e0c:	5b                   	pop    %ebx
f0102e0d:	5e                   	pop    %esi
f0102e0e:	5f                   	pop    %edi
f0102e0f:	5d                   	pop    %ebp
f0102e10:	c3                   	ret    

f0102e11 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102e11:	55                   	push   %ebp
f0102e12:	89 e5                	mov    %esp,%ebp
f0102e14:	56                   	push   %esi
f0102e15:	53                   	push   %ebx
f0102e16:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e19:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102e1c:	85 c0                	test   %eax,%eax
f0102e1e:	75 1a                	jne    f0102e3a <envid2env+0x29>
		*env_store = curenv;
f0102e20:	e8 b1 24 00 00       	call   f01052d6 <cpunum>
f0102e25:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e28:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102e2e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102e31:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102e33:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e38:	eb 70                	jmp    f0102eaa <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102e3a:	89 c3                	mov    %eax,%ebx
f0102e3c:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102e42:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102e45:	03 1d 48 a2 22 f0    	add    0xf022a248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102e4b:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102e4f:	74 05                	je     f0102e56 <envid2env+0x45>
f0102e51:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102e54:	74 10                	je     f0102e66 <envid2env+0x55>
		*env_store = 0;
f0102e56:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e59:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e5f:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e64:	eb 44                	jmp    f0102eaa <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102e66:	84 d2                	test   %dl,%dl
f0102e68:	74 36                	je     f0102ea0 <envid2env+0x8f>
f0102e6a:	e8 67 24 00 00       	call   f01052d6 <cpunum>
f0102e6f:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e72:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f0102e78:	74 26                	je     f0102ea0 <envid2env+0x8f>
f0102e7a:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102e7d:	e8 54 24 00 00       	call   f01052d6 <cpunum>
f0102e82:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e85:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102e8b:	3b 70 48             	cmp    0x48(%eax),%esi
f0102e8e:	74 10                	je     f0102ea0 <envid2env+0x8f>
		*env_store = 0;
f0102e90:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e93:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e99:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e9e:	eb 0a                	jmp    f0102eaa <envid2env+0x99>
	}

	*env_store = e;
f0102ea0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ea3:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102ea5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102eaa:	5b                   	pop    %ebx
f0102eab:	5e                   	pop    %esi
f0102eac:	5d                   	pop    %ebp
f0102ead:	c3                   	ret    

f0102eae <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102eae:	55                   	push   %ebp
f0102eaf:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102eb1:	b8 20 f3 11 f0       	mov    $0xf011f320,%eax
f0102eb6:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102eb9:	b8 23 00 00 00       	mov    $0x23,%eax
f0102ebe:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102ec0:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102ec2:	b8 10 00 00 00       	mov    $0x10,%eax
f0102ec7:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102ec9:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102ecb:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102ecd:	ea d4 2e 10 f0 08 00 	ljmp   $0x8,$0xf0102ed4
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102ed4:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ed9:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102edc:	5d                   	pop    %ebp
f0102edd:	c3                   	ret    

f0102ede <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102ede:	55                   	push   %ebp
f0102edf:	89 e5                	mov    %esp,%ebp
f0102ee1:	56                   	push   %esi
f0102ee2:	53                   	push   %ebx
	// LAB 3: Your code here.
	// struct Env* envs;
	// env_free_list = NULL;
	for(int i = NENV - 1;i >= 0;i--)
	{
		envs[i].env_id = 0;
f0102ee3:	8b 35 48 a2 22 f0    	mov    0xf022a248,%esi
f0102ee9:	8b 15 4c a2 22 f0    	mov    0xf022a24c,%edx
f0102eef:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102ef5:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102ef8:	89 c1                	mov    %eax,%ecx
f0102efa:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f0102f01:	89 50 44             	mov    %edx,0x44(%eax)
f0102f04:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];
f0102f07:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	// struct Env* envs;
	// env_free_list = NULL;
	for(int i = NENV - 1;i >= 0;i--)
f0102f09:	39 d8                	cmp    %ebx,%eax
f0102f0b:	75 eb                	jne    f0102ef8 <env_init+0x1a>
f0102f0d:	89 35 4c a2 22 f0    	mov    %esi,0xf022a24c
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
		//envs[i].env_status = 
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f0102f13:	e8 96 ff ff ff       	call   f0102eae <env_init_percpu>
}
f0102f18:	5b                   	pop    %ebx
f0102f19:	5e                   	pop    %esi
f0102f1a:	5d                   	pop    %ebp
f0102f1b:	c3                   	ret    

f0102f1c <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102f1c:	55                   	push   %ebp
f0102f1d:	89 e5                	mov    %esp,%ebp
f0102f1f:	56                   	push   %esi
f0102f20:	53                   	push   %ebx
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102f21:	8b 1d 4c a2 22 f0    	mov    0xf022a24c,%ebx
f0102f27:	85 db                	test   %ebx,%ebx
f0102f29:	0f 84 64 01 00 00    	je     f0103093 <env_alloc+0x177>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102f2f:	83 ec 0c             	sub    $0xc,%esp
f0102f32:	6a 01                	push   $0x1
f0102f34:	e8 81 df ff ff       	call   f0100eba <page_alloc>
f0102f39:	89 c6                	mov    %eax,%esi
f0102f3b:	83 c4 10             	add    $0x10,%esp
f0102f3e:	85 c0                	test   %eax,%eax
f0102f40:	0f 84 54 01 00 00    	je     f010309a <env_alloc+0x17e>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f46:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102f4c:	c1 f8 03             	sar    $0x3,%eax
f0102f4f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f52:	89 c2                	mov    %eax,%edx
f0102f54:	c1 ea 0c             	shr    $0xc,%edx
f0102f57:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102f5d:	72 12                	jb     f0102f71 <env_alloc+0x55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f5f:	50                   	push   %eax
f0102f60:	68 84 59 10 f0       	push   $0xf0105984
f0102f65:	6a 58                	push   $0x58
f0102f67:	68 61 68 10 f0       	push   $0xf0106861
f0102f6c:	e8 cf d0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102f71:	2d 00 00 00 10       	sub    $0x10000000,%eax
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	// p = page_alloc(ALLOC_ZERO);
	e->env_pgdir = page2kva(p);
f0102f76:	89 43 60             	mov    %eax,0x60(%ebx)
	//memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
	memmove(e->env_pgdir, kern_pgdir, PGSIZE);
f0102f79:	83 ec 04             	sub    $0x4,%esp
f0102f7c:	68 00 10 00 00       	push   $0x1000
f0102f81:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102f87:	50                   	push   %eax
f0102f88:	e8 75 1d 00 00       	call   f0104d02 <memmove>
	p->pp_ref++;
f0102f8d:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102f92:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f95:	83 c4 10             	add    $0x10,%esp
f0102f98:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102f9d:	77 15                	ja     f0102fb4 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f9f:	50                   	push   %eax
f0102fa0:	68 a8 59 10 f0       	push   $0xf01059a8
f0102fa5:	68 c9 00 00 00       	push   $0xc9
f0102faa:	68 ba 6b 10 f0       	push   $0xf0106bba
f0102faf:	e8 8c d0 ff ff       	call   f0100040 <_panic>
f0102fb4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102fba:	83 ca 05             	or     $0x5,%edx
f0102fbd:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102fc3:	8b 43 48             	mov    0x48(%ebx),%eax
f0102fc6:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102fcb:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102fd0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102fd5:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102fd8:	89 da                	mov    %ebx,%edx
f0102fda:	2b 15 48 a2 22 f0    	sub    0xf022a248,%edx
f0102fe0:	c1 fa 02             	sar    $0x2,%edx
f0102fe3:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0102fe9:	09 d0                	or     %edx,%eax
f0102feb:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102fee:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ff1:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102ff4:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102ffb:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103002:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103009:	83 ec 04             	sub    $0x4,%esp
f010300c:	6a 44                	push   $0x44
f010300e:	6a 00                	push   $0x0
f0103010:	53                   	push   %ebx
f0103011:	e8 9f 1c 00 00       	call   f0104cb5 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103016:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f010301c:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103022:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103028:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010302f:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0103035:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f010303c:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103040:	8b 43 44             	mov    0x44(%ebx),%eax
f0103043:	a3 4c a2 22 f0       	mov    %eax,0xf022a24c
	*newenv_store = e;
f0103048:	8b 45 08             	mov    0x8(%ebp),%eax
f010304b:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010304d:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103050:	e8 81 22 00 00       	call   f01052d6 <cpunum>
f0103055:	6b c0 74             	imul   $0x74,%eax,%eax
f0103058:	83 c4 10             	add    $0x10,%esp
f010305b:	ba 00 00 00 00       	mov    $0x0,%edx
f0103060:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103067:	74 11                	je     f010307a <env_alloc+0x15e>
f0103069:	e8 68 22 00 00       	call   f01052d6 <cpunum>
f010306e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103071:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103077:	8b 50 48             	mov    0x48(%eax),%edx
f010307a:	83 ec 04             	sub    $0x4,%esp
f010307d:	53                   	push   %ebx
f010307e:	52                   	push   %edx
f010307f:	68 d6 6b 10 f0       	push   $0xf0106bd6
f0103084:	e8 38 06 00 00       	call   f01036c1 <cprintf>
	return 0;
f0103089:	83 c4 10             	add    $0x10,%esp
f010308c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103091:	eb 0c                	jmp    f010309f <env_alloc+0x183>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103093:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103098:	eb 05                	jmp    f010309f <env_alloc+0x183>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f010309a:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f010309f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01030a2:	5b                   	pop    %ebx
f01030a3:	5e                   	pop    %esi
f01030a4:	5d                   	pop    %ebp
f01030a5:	c3                   	ret    

f01030a6 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01030a6:	55                   	push   %ebp
f01030a7:	89 e5                	mov    %esp,%ebp
f01030a9:	57                   	push   %edi
f01030aa:	56                   	push   %esi
f01030ab:	53                   	push   %ebx
f01030ac:	83 ec 34             	sub    $0x34,%esp
f01030af:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int r;
	r = env_alloc(&e, 0);
f01030b2:	6a 00                	push   $0x0
f01030b4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01030b7:	50                   	push   %eax
f01030b8:	e8 5f fe ff ff       	call   f0102f1c <env_alloc>
	if(r != 0)
f01030bd:	83 c4 10             	add    $0x10,%esp
f01030c0:	85 c0                	test   %eax,%eax
f01030c2:	74 15                	je     f01030d9 <env_create+0x33>
		panic("env_create: %e", r);
f01030c4:	50                   	push   %eax
f01030c5:	68 eb 6b 10 f0       	push   $0xf0106beb
f01030ca:	68 ad 01 00 00       	push   $0x1ad
f01030cf:	68 ba 6b 10 f0       	push   $0xf0106bba
f01030d4:	e8 67 cf ff ff       	call   f0100040 <_panic>
	//if(env_alloc(&e,0) != 0)
	//	panic("env_alloc fail");
	e->env_type = type;
f01030d9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030dc:	89 c2                	mov    %eax,%edx
f01030de:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01030e1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030e4:	89 42 50             	mov    %eax,0x50(%edx)
	struct Elf *elf;
	// 强制类型转换，将binary后的内存空间内容按照结构ELF的格式读取
	elf = (struct Elf *)binary;
	// is this a valid ELF? 判断是否是ELF
	// ELF头开头的结构体叫做魔数,是一个16位的数组
	if(elf->e_magic != ELF_MAGIC)
f01030e7:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01030ed:	74 17                	je     f0103106 <env_create+0x60>
		panic("load segements fail");
f01030ef:	83 ec 04             	sub    $0x4,%esp
f01030f2:	68 fa 6b 10 f0       	push   $0xf0106bfa
f01030f7:	68 7a 01 00 00       	push   $0x17a
f01030fc:	68 ba 6b 10 f0       	push   $0xf0106bba
f0103101:	e8 3a cf ff ff       	call   f0100040 <_panic>
	// load each program segment (ignores ph flags)
	// e_phoff 程序头表的文件偏移地址
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
f0103106:	89 fb                	mov    %edi,%ebx
f0103108:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f010310b:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f010310f:	c1 e6 05             	shl    $0x5,%esi
f0103112:	01 de                	add    %ebx,%esi
	// 因为后面需要访问刚分配的内存，所以需要将env_pgdir装入cr3，使二级页表能够运作
	lcr3(PADDR(e->env_pgdir));
f0103114:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103117:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010311a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010311f:	77 15                	ja     f0103136 <env_create+0x90>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103121:	50                   	push   %eax
f0103122:	68 a8 59 10 f0       	push   $0xf01059a8
f0103127:	68 80 01 00 00       	push   $0x180
f010312c:	68 ba 6b 10 f0       	push   $0xf0106bba
f0103131:	e8 0a cf ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103136:	05 00 00 00 10       	add    $0x10000000,%eax
f010313b:	0f 22 d8             	mov    %eax,%cr3
f010313e:	eb 60                	jmp    f01031a0 <env_create+0xfa>

	for (; ph < eph; ph++)
	{
		// 	(The ELF header should have ph->p_filesz <= ph->p_memsz.)
		if(ph->p_filesz > ph->p_memsz)
f0103140:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103143:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f0103146:	76 17                	jbe    f010315f <env_create+0xb9>
			panic("memory is not enough for file");
f0103148:	83 ec 04             	sub    $0x4,%esp
f010314b:	68 0e 6c 10 f0       	push   $0xf0106c0e
f0103150:	68 86 01 00 00       	push   $0x186
f0103155:	68 ba 6b 10 f0       	push   $0xf0106bba
f010315a:	e8 e1 ce ff ff       	call   f0100040 <_panic>
		if(ph->p_type == ELF_PROG_LOAD)
f010315f:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103162:	75 39                	jne    f010319d <env_create+0xf7>
		{
		//  Each segment's virtual address can be found in ph->p_va
		//  and its size in memory can be found in ph->p_memsz.
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0103164:	8b 53 08             	mov    0x8(%ebx),%edx
f0103167:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010316a:	e8 02 fc ff ff       	call   f0102d71 <region_alloc>
		//  The ph->p_filesz bytes from the ELF binary, starting at
		//  'binary + ph->p_offset', should be copied to virtual address
		//  ph->p_va. 
			//memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f010316f:	83 ec 04             	sub    $0x4,%esp
f0103172:	ff 73 10             	pushl  0x10(%ebx)
f0103175:	89 f8                	mov    %edi,%eax
f0103177:	03 43 04             	add    0x4(%ebx),%eax
f010317a:	50                   	push   %eax
f010317b:	ff 73 08             	pushl  0x8(%ebx)
f010317e:	e8 7f 1b 00 00       	call   f0104d02 <memmove>
        //	Any remaining memory bytes should be cleared to zero.
		    memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
f0103183:	8b 43 10             	mov    0x10(%ebx),%eax
f0103186:	83 c4 0c             	add    $0xc,%esp
f0103189:	8b 53 14             	mov    0x14(%ebx),%edx
f010318c:	29 c2                	sub    %eax,%edx
f010318e:	52                   	push   %edx
f010318f:	6a 00                	push   $0x0
f0103191:	03 43 08             	add    0x8(%ebx),%eax
f0103194:	50                   	push   %eax
f0103195:	e8 1b 1b 00 00       	call   f0104cb5 <memset>
f010319a:	83 c4 10             	add    $0x10,%esp
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
	eph = ph + elf->e_phnum;
	// 因为后面需要访问刚分配的内存，所以需要将env_pgdir装入cr3，使二级页表能够运作
	lcr3(PADDR(e->env_pgdir));

	for (; ph < eph; ph++)
f010319d:	83 c3 20             	add    $0x20,%ebx
f01031a0:	39 de                	cmp    %ebx,%esi
f01031a2:	77 9c                	ja     f0103140 <env_create+0x9a>
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
        //	Any remaining memory bytes should be cleared to zero.
		    memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
		}
	}
	e->env_tf.tf_eip = elf->e_entry;
f01031a4:	8b 47 18             	mov    0x18(%edi),%eax
f01031a7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01031aa:	89 47 30             	mov    %eax,0x30(%edi)
	lcr3(PADDR(kern_pgdir));
f01031ad:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031b2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031b7:	77 15                	ja     f01031ce <env_create+0x128>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031b9:	50                   	push   %eax
f01031ba:	68 a8 59 10 f0       	push   $0xf01059a8
f01031bf:	68 96 01 00 00       	push   $0x196
f01031c4:	68 ba 6b 10 f0       	push   $0xf0106bba
f01031c9:	e8 72 ce ff ff       	call   f0100040 <_panic>
f01031ce:	05 00 00 00 10       	add    $0x10000000,%eax
f01031d3:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *) USTACKTOP-PGSIZE, PGSIZE);
f01031d6:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01031db:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01031e0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031e3:	e8 89 fb ff ff       	call   f0102d71 <region_alloc>
		panic("env_create: %e", r);
	//if(env_alloc(&e,0) != 0)
	//	panic("env_alloc fail");
	e->env_type = type;
	load_icode(e, binary);
}
f01031e8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031eb:	5b                   	pop    %ebx
f01031ec:	5e                   	pop    %esi
f01031ed:	5f                   	pop    %edi
f01031ee:	5d                   	pop    %ebp
f01031ef:	c3                   	ret    

f01031f0 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01031f0:	55                   	push   %ebp
f01031f1:	89 e5                	mov    %esp,%ebp
f01031f3:	57                   	push   %edi
f01031f4:	56                   	push   %esi
f01031f5:	53                   	push   %ebx
f01031f6:	83 ec 1c             	sub    $0x1c,%esp
f01031f9:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01031fc:	e8 d5 20 00 00       	call   f01052d6 <cpunum>
f0103201:	6b c0 74             	imul   $0x74,%eax,%eax
f0103204:	39 b8 28 b0 22 f0    	cmp    %edi,-0xfdd4fd8(%eax)
f010320a:	75 29                	jne    f0103235 <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f010320c:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103211:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103216:	77 15                	ja     f010322d <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103218:	50                   	push   %eax
f0103219:	68 a8 59 10 f0       	push   $0xf01059a8
f010321e:	68 c2 01 00 00       	push   $0x1c2
f0103223:	68 ba 6b 10 f0       	push   $0xf0106bba
f0103228:	e8 13 ce ff ff       	call   f0100040 <_panic>
f010322d:	05 00 00 00 10       	add    $0x10000000,%eax
f0103232:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103235:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103238:	e8 99 20 00 00       	call   f01052d6 <cpunum>
f010323d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103240:	ba 00 00 00 00       	mov    $0x0,%edx
f0103245:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f010324c:	74 11                	je     f010325f <env_free+0x6f>
f010324e:	e8 83 20 00 00       	call   f01052d6 <cpunum>
f0103253:	6b c0 74             	imul   $0x74,%eax,%eax
f0103256:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010325c:	8b 50 48             	mov    0x48(%eax),%edx
f010325f:	83 ec 04             	sub    $0x4,%esp
f0103262:	53                   	push   %ebx
f0103263:	52                   	push   %edx
f0103264:	68 2c 6c 10 f0       	push   $0xf0106c2c
f0103269:	e8 53 04 00 00       	call   f01036c1 <cprintf>
f010326e:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103271:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103278:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010327b:	89 d0                	mov    %edx,%eax
f010327d:	c1 e0 02             	shl    $0x2,%eax
f0103280:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103283:	8b 47 60             	mov    0x60(%edi),%eax
f0103286:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103289:	f7 c6 01 00 00 00    	test   $0x1,%esi
f010328f:	0f 84 a8 00 00 00    	je     f010333d <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103295:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010329b:	89 f0                	mov    %esi,%eax
f010329d:	c1 e8 0c             	shr    $0xc,%eax
f01032a0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01032a3:	39 05 88 ae 22 f0    	cmp    %eax,0xf022ae88
f01032a9:	77 15                	ja     f01032c0 <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01032ab:	56                   	push   %esi
f01032ac:	68 84 59 10 f0       	push   $0xf0105984
f01032b1:	68 d1 01 00 00       	push   $0x1d1
f01032b6:	68 ba 6b 10 f0       	push   $0xf0106bba
f01032bb:	e8 80 cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01032c0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032c3:	c1 e0 16             	shl    $0x16,%eax
f01032c6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032c9:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01032ce:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01032d5:	01 
f01032d6:	74 17                	je     f01032ef <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01032d8:	83 ec 08             	sub    $0x8,%esp
f01032db:	89 d8                	mov    %ebx,%eax
f01032dd:	c1 e0 0c             	shl    $0xc,%eax
f01032e0:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01032e3:	50                   	push   %eax
f01032e4:	ff 77 60             	pushl  0x60(%edi)
f01032e7:	e8 56 de ff ff       	call   f0101142 <page_remove>
f01032ec:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01032ef:	83 c3 01             	add    $0x1,%ebx
f01032f2:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01032f8:	75 d4                	jne    f01032ce <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01032fa:	8b 47 60             	mov    0x60(%edi),%eax
f01032fd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103300:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103307:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010330a:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0103310:	72 14                	jb     f0103326 <env_free+0x136>
		panic("pa2page called with invalid pa");
f0103312:	83 ec 04             	sub    $0x4,%esp
f0103315:	68 1c 60 10 f0       	push   $0xf010601c
f010331a:	6a 51                	push   $0x51
f010331c:	68 61 68 10 f0       	push   $0xf0106861
f0103321:	e8 1a cd ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f0103326:	83 ec 0c             	sub    $0xc,%esp
f0103329:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f010332e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103331:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0103334:	50                   	push   %eax
f0103335:	e8 2b dc ff ff       	call   f0100f65 <page_decref>
f010333a:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010333d:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103341:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103344:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103349:	0f 85 29 ff ff ff    	jne    f0103278 <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f010334f:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103352:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103357:	77 15                	ja     f010336e <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103359:	50                   	push   %eax
f010335a:	68 a8 59 10 f0       	push   $0xf01059a8
f010335f:	68 df 01 00 00       	push   $0x1df
f0103364:	68 ba 6b 10 f0       	push   $0xf0106bba
f0103369:	e8 d2 cc ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f010336e:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103375:	05 00 00 00 10       	add    $0x10000000,%eax
f010337a:	c1 e8 0c             	shr    $0xc,%eax
f010337d:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0103383:	72 14                	jb     f0103399 <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f0103385:	83 ec 04             	sub    $0x4,%esp
f0103388:	68 1c 60 10 f0       	push   $0xf010601c
f010338d:	6a 51                	push   $0x51
f010338f:	68 61 68 10 f0       	push   $0xf0106861
f0103394:	e8 a7 cc ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103399:	83 ec 0c             	sub    $0xc,%esp
f010339c:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f01033a2:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01033a5:	50                   	push   %eax
f01033a6:	e8 ba db ff ff       	call   f0100f65 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01033ab:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01033b2:	a1 4c a2 22 f0       	mov    0xf022a24c,%eax
f01033b7:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01033ba:	89 3d 4c a2 22 f0    	mov    %edi,0xf022a24c
}
f01033c0:	83 c4 10             	add    $0x10,%esp
f01033c3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033c6:	5b                   	pop    %ebx
f01033c7:	5e                   	pop    %esi
f01033c8:	5f                   	pop    %edi
f01033c9:	5d                   	pop    %ebp
f01033ca:	c3                   	ret    

f01033cb <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f01033cb:	55                   	push   %ebp
f01033cc:	89 e5                	mov    %esp,%ebp
f01033ce:	53                   	push   %ebx
f01033cf:	83 ec 04             	sub    $0x4,%esp
f01033d2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01033d5:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01033d9:	75 19                	jne    f01033f4 <env_destroy+0x29>
f01033db:	e8 f6 1e 00 00       	call   f01052d6 <cpunum>
f01033e0:	6b c0 74             	imul   $0x74,%eax,%eax
f01033e3:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f01033e9:	74 09                	je     f01033f4 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01033eb:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01033f2:	eb 33                	jmp    f0103427 <env_destroy+0x5c>
	}

	env_free(e);
f01033f4:	83 ec 0c             	sub    $0xc,%esp
f01033f7:	53                   	push   %ebx
f01033f8:	e8 f3 fd ff ff       	call   f01031f0 <env_free>

	if (curenv == e) {
f01033fd:	e8 d4 1e 00 00       	call   f01052d6 <cpunum>
f0103402:	6b c0 74             	imul   $0x74,%eax,%eax
f0103405:	83 c4 10             	add    $0x10,%esp
f0103408:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f010340e:	75 17                	jne    f0103427 <env_destroy+0x5c>
		curenv = NULL;
f0103410:	e8 c1 1e 00 00       	call   f01052d6 <cpunum>
f0103415:	6b c0 74             	imul   $0x74,%eax,%eax
f0103418:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f010341f:	00 00 00 
		sched_yield();
f0103422:	e8 41 0c 00 00       	call   f0104068 <sched_yield>
	}
}
f0103427:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010342a:	c9                   	leave  
f010342b:	c3                   	ret    

f010342c <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f010342c:	55                   	push   %ebp
f010342d:	89 e5                	mov    %esp,%ebp
f010342f:	53                   	push   %ebx
f0103430:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103433:	e8 9e 1e 00 00       	call   f01052d6 <cpunum>
f0103438:	6b c0 74             	imul   $0x74,%eax,%eax
f010343b:	8b 98 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%ebx
f0103441:	e8 90 1e 00 00       	call   f01052d6 <cpunum>
f0103446:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f0103449:	8b 65 08             	mov    0x8(%ebp),%esp
f010344c:	61                   	popa   
f010344d:	07                   	pop    %es
f010344e:	1f                   	pop    %ds
f010344f:	83 c4 08             	add    $0x8,%esp
f0103452:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103453:	83 ec 04             	sub    $0x4,%esp
f0103456:	68 42 6c 10 f0       	push   $0xf0106c42
f010345b:	68 15 02 00 00       	push   $0x215
f0103460:	68 ba 6b 10 f0       	push   $0xf0106bba
f0103465:	e8 d6 cb ff ff       	call   f0100040 <_panic>

f010346a <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010346a:	55                   	push   %ebp
f010346b:	89 e5                	mov    %esp,%ebp
f010346d:	53                   	push   %ebx
f010346e:	83 ec 04             	sub    $0x4,%esp
f0103471:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv && curenv->env_status == ENV_RUNNING)
f0103474:	e8 5d 1e 00 00       	call   f01052d6 <cpunum>
f0103479:	6b c0 74             	imul   $0x74,%eax,%eax
f010347c:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103483:	74 29                	je     f01034ae <env_run+0x44>
f0103485:	e8 4c 1e 00 00       	call   f01052d6 <cpunum>
f010348a:	6b c0 74             	imul   $0x74,%eax,%eax
f010348d:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103493:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103497:	75 15                	jne    f01034ae <env_run+0x44>
		curenv->env_status = ENV_RUNNABLE;
f0103499:	e8 38 1e 00 00       	call   f01052d6 <cpunum>
f010349e:	6b c0 74             	imul   $0x74,%eax,%eax
f01034a1:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01034a7:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	curenv = e;
f01034ae:	e8 23 1e 00 00       	call   f01052d6 <cpunum>
f01034b3:	6b c0 74             	imul   $0x74,%eax,%eax
f01034b6:	89 98 28 b0 22 f0    	mov    %ebx,-0xfdd4fd8(%eax)
	curenv->env_status = ENV_RUNNING;
f01034bc:	e8 15 1e 00 00       	call   f01052d6 <cpunum>
f01034c1:	6b c0 74             	imul   $0x74,%eax,%eax
f01034c4:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01034ca:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f01034d1:	e8 00 1e 00 00       	call   f01052d6 <cpunum>
f01034d6:	6b c0 74             	imul   $0x74,%eax,%eax
f01034d9:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01034df:	83 40 58 01          	addl   $0x1,0x58(%eax)
	cprintf("%o \n",(physaddr_t)curenv->env_pgdir);
f01034e3:	e8 ee 1d 00 00       	call   f01052d6 <cpunum>
f01034e8:	83 ec 08             	sub    $0x8,%esp
f01034eb:	6b c0 74             	imul   $0x74,%eax,%eax
f01034ee:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01034f4:	ff 70 60             	pushl  0x60(%eax)
f01034f7:	68 4e 6c 10 f0       	push   $0xf0106c4e
f01034fc:	e8 c0 01 00 00       	call   f01036c1 <cprintf>
	lcr3(PADDR(curenv->env_pgdir));
f0103501:	e8 d0 1d 00 00       	call   f01052d6 <cpunum>
f0103506:	6b c0 74             	imul   $0x74,%eax,%eax
f0103509:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010350f:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103512:	83 c4 10             	add    $0x10,%esp
f0103515:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010351a:	77 15                	ja     f0103531 <env_run+0xc7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010351c:	50                   	push   %eax
f010351d:	68 a8 59 10 f0       	push   $0xf01059a8
f0103522:	68 39 02 00 00       	push   $0x239
f0103527:	68 ba 6b 10 f0       	push   $0xf0106bba
f010352c:	e8 0f cb ff ff       	call   f0100040 <_panic>
f0103531:	05 00 00 00 10       	add    $0x10000000,%eax
f0103536:	0f 22 d8             	mov    %eax,%cr3

	env_pop_tf(&e->env_tf);
f0103539:	83 ec 0c             	sub    $0xc,%esp
f010353c:	53                   	push   %ebx
f010353d:	e8 ea fe ff ff       	call   f010342c <env_pop_tf>

f0103542 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103542:	55                   	push   %ebp
f0103543:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103545:	ba 70 00 00 00       	mov    $0x70,%edx
f010354a:	8b 45 08             	mov    0x8(%ebp),%eax
f010354d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010354e:	ba 71 00 00 00       	mov    $0x71,%edx
f0103553:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103554:	0f b6 c0             	movzbl %al,%eax
}
f0103557:	5d                   	pop    %ebp
f0103558:	c3                   	ret    

f0103559 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103559:	55                   	push   %ebp
f010355a:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010355c:	ba 70 00 00 00       	mov    $0x70,%edx
f0103561:	8b 45 08             	mov    0x8(%ebp),%eax
f0103564:	ee                   	out    %al,(%dx)
f0103565:	ba 71 00 00 00       	mov    $0x71,%edx
f010356a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010356d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010356e:	5d                   	pop    %ebp
f010356f:	c3                   	ret    

f0103570 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103570:	55                   	push   %ebp
f0103571:	89 e5                	mov    %esp,%ebp
f0103573:	56                   	push   %esi
f0103574:	53                   	push   %ebx
f0103575:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103578:	66 a3 a8 f3 11 f0    	mov    %ax,0xf011f3a8
	if (!didinit)
f010357e:	80 3d 50 a2 22 f0 00 	cmpb   $0x0,0xf022a250
f0103585:	74 5a                	je     f01035e1 <irq_setmask_8259A+0x71>
f0103587:	89 c6                	mov    %eax,%esi
f0103589:	ba 21 00 00 00       	mov    $0x21,%edx
f010358e:	ee                   	out    %al,(%dx)
f010358f:	66 c1 e8 08          	shr    $0x8,%ax
f0103593:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103598:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f0103599:	83 ec 0c             	sub    $0xc,%esp
f010359c:	68 53 6c 10 f0       	push   $0xf0106c53
f01035a1:	e8 1b 01 00 00       	call   f01036c1 <cprintf>
f01035a6:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f01035a9:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f01035ae:	0f b7 f6             	movzwl %si,%esi
f01035b1:	f7 d6                	not    %esi
f01035b3:	0f a3 de             	bt     %ebx,%esi
f01035b6:	73 11                	jae    f01035c9 <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f01035b8:	83 ec 08             	sub    $0x8,%esp
f01035bb:	53                   	push   %ebx
f01035bc:	68 e5 70 10 f0       	push   $0xf01070e5
f01035c1:	e8 fb 00 00 00       	call   f01036c1 <cprintf>
f01035c6:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f01035c9:	83 c3 01             	add    $0x1,%ebx
f01035cc:	83 fb 10             	cmp    $0x10,%ebx
f01035cf:	75 e2                	jne    f01035b3 <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f01035d1:	83 ec 0c             	sub    $0xc,%esp
f01035d4:	68 e9 5c 10 f0       	push   $0xf0105ce9
f01035d9:	e8 e3 00 00 00       	call   f01036c1 <cprintf>
f01035de:	83 c4 10             	add    $0x10,%esp
}
f01035e1:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01035e4:	5b                   	pop    %ebx
f01035e5:	5e                   	pop    %esi
f01035e6:	5d                   	pop    %ebp
f01035e7:	c3                   	ret    

f01035e8 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f01035e8:	c6 05 50 a2 22 f0 01 	movb   $0x1,0xf022a250
f01035ef:	ba 21 00 00 00       	mov    $0x21,%edx
f01035f4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01035f9:	ee                   	out    %al,(%dx)
f01035fa:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035ff:	ee                   	out    %al,(%dx)
f0103600:	ba 20 00 00 00       	mov    $0x20,%edx
f0103605:	b8 11 00 00 00       	mov    $0x11,%eax
f010360a:	ee                   	out    %al,(%dx)
f010360b:	ba 21 00 00 00       	mov    $0x21,%edx
f0103610:	b8 20 00 00 00       	mov    $0x20,%eax
f0103615:	ee                   	out    %al,(%dx)
f0103616:	b8 04 00 00 00       	mov    $0x4,%eax
f010361b:	ee                   	out    %al,(%dx)
f010361c:	b8 03 00 00 00       	mov    $0x3,%eax
f0103621:	ee                   	out    %al,(%dx)
f0103622:	ba a0 00 00 00       	mov    $0xa0,%edx
f0103627:	b8 11 00 00 00       	mov    $0x11,%eax
f010362c:	ee                   	out    %al,(%dx)
f010362d:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103632:	b8 28 00 00 00       	mov    $0x28,%eax
f0103637:	ee                   	out    %al,(%dx)
f0103638:	b8 02 00 00 00       	mov    $0x2,%eax
f010363d:	ee                   	out    %al,(%dx)
f010363e:	b8 01 00 00 00       	mov    $0x1,%eax
f0103643:	ee                   	out    %al,(%dx)
f0103644:	ba 20 00 00 00       	mov    $0x20,%edx
f0103649:	b8 68 00 00 00       	mov    $0x68,%eax
f010364e:	ee                   	out    %al,(%dx)
f010364f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103654:	ee                   	out    %al,(%dx)
f0103655:	ba a0 00 00 00       	mov    $0xa0,%edx
f010365a:	b8 68 00 00 00       	mov    $0x68,%eax
f010365f:	ee                   	out    %al,(%dx)
f0103660:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103665:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0103666:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f010366d:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103671:	74 13                	je     f0103686 <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103673:	55                   	push   %ebp
f0103674:	89 e5                	mov    %esp,%ebp
f0103676:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103679:	0f b7 c0             	movzwl %ax,%eax
f010367c:	50                   	push   %eax
f010367d:	e8 ee fe ff ff       	call   f0103570 <irq_setmask_8259A>
f0103682:	83 c4 10             	add    $0x10,%esp
}
f0103685:	c9                   	leave  
f0103686:	f3 c3                	repz ret 

f0103688 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103688:	55                   	push   %ebp
f0103689:	89 e5                	mov    %esp,%ebp
f010368b:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010368e:	ff 75 08             	pushl  0x8(%ebp)
f0103691:	e8 a8 d0 ff ff       	call   f010073e <cputchar>
	*cnt++;
}
f0103696:	83 c4 10             	add    $0x10,%esp
f0103699:	c9                   	leave  
f010369a:	c3                   	ret    

f010369b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010369b:	55                   	push   %ebp
f010369c:	89 e5                	mov    %esp,%ebp
f010369e:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01036a1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01036a8:	ff 75 0c             	pushl  0xc(%ebp)
f01036ab:	ff 75 08             	pushl  0x8(%ebp)
f01036ae:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01036b1:	50                   	push   %eax
f01036b2:	68 88 36 10 f0       	push   $0xf0103688
f01036b7:	e8 8d 0f 00 00       	call   f0104649 <vprintfmt>
	return cnt;
}
f01036bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01036bf:	c9                   	leave  
f01036c0:	c3                   	ret    

f01036c1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01036c1:	55                   	push   %ebp
f01036c2:	89 e5                	mov    %esp,%ebp
f01036c4:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01036c7:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01036ca:	50                   	push   %eax
f01036cb:	ff 75 08             	pushl  0x8(%ebp)
f01036ce:	e8 c8 ff ff ff       	call   f010369b <vcprintf>
	va_end(ap);

	return cnt;
}
f01036d3:	c9                   	leave  
f01036d4:	c3                   	ret    

f01036d5 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01036d5:	55                   	push   %ebp
f01036d6:	89 e5                	mov    %esp,%ebp
f01036d8:	57                   	push   %edi
f01036d9:	56                   	push   %esi
f01036da:	53                   	push   %ebx
f01036db:	83 ec 0c             	sub    $0xc,%esp
	// // bottom three bits are special; we leave them 0)
	// ltr(GD_TSS0);

	// // Load the IDT
	// lidt(&idt_pd);
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - cpunum() * (KSTKSIZE + KSTKGAP);
f01036de:	e8 f3 1b 00 00       	call   f01052d6 <cpunum>
f01036e3:	89 c3                	mov    %eax,%ebx
f01036e5:	e8 ec 1b 00 00       	call   f01052d6 <cpunum>
f01036ea:	6b db 74             	imul   $0x74,%ebx,%ebx
f01036ed:	c1 e0 10             	shl    $0x10,%eax
f01036f0:	89 c2                	mov    %eax,%edx
f01036f2:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
f01036f7:	29 d0                	sub    %edx,%eax
f01036f9:	89 83 30 b0 22 f0    	mov    %eax,-0xfdd4fd0(%ebx)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f01036ff:	e8 d2 1b 00 00       	call   f01052d6 <cpunum>
f0103704:	6b c0 74             	imul   $0x74,%eax,%eax
f0103707:	66 c7 80 34 b0 22 f0 	movw   $0x10,-0xfdd4fcc(%eax)
f010370e:	10 00 
	gdt[(GD_TSS0 >> 3) + cpunum()] = SEG16(STS_T32A, (uint32_t)(&(thiscpu->cpu_ts)), sizeof(struct Taskstate) - 1, 0);
f0103710:	e8 c1 1b 00 00       	call   f01052d6 <cpunum>
f0103715:	8d 58 05             	lea    0x5(%eax),%ebx
f0103718:	e8 b9 1b 00 00       	call   f01052d6 <cpunum>
f010371d:	89 c7                	mov    %eax,%edi
f010371f:	e8 b2 1b 00 00       	call   f01052d6 <cpunum>
f0103724:	89 c6                	mov    %eax,%esi
f0103726:	e8 ab 1b 00 00       	call   f01052d6 <cpunum>
f010372b:	66 c7 04 dd 40 f3 11 	movw   $0x67,-0xfee0cc0(,%ebx,8)
f0103732:	f0 67 00 
f0103735:	6b ff 74             	imul   $0x74,%edi,%edi
f0103738:	81 c7 2c b0 22 f0    	add    $0xf022b02c,%edi
f010373e:	66 89 3c dd 42 f3 11 	mov    %di,-0xfee0cbe(,%ebx,8)
f0103745:	f0 
f0103746:	6b d6 74             	imul   $0x74,%esi,%edx
f0103749:	81 c2 2c b0 22 f0    	add    $0xf022b02c,%edx
f010374f:	c1 ea 10             	shr    $0x10,%edx
f0103752:	88 14 dd 44 f3 11 f0 	mov    %dl,-0xfee0cbc(,%ebx,8)
f0103759:	c6 04 dd 45 f3 11 f0 	movb   $0x99,-0xfee0cbb(,%ebx,8)
f0103760:	99 
f0103761:	c6 04 dd 46 f3 11 f0 	movb   $0x40,-0xfee0cba(,%ebx,8)
f0103768:	40 
f0103769:	6b c0 74             	imul   $0x74,%eax,%eax
f010376c:	05 2c b0 22 f0       	add    $0xf022b02c,%eax
f0103771:	c1 e8 18             	shr    $0x18,%eax
f0103774:	88 04 dd 47 f3 11 f0 	mov    %al,-0xfee0cb9(,%ebx,8)
	gdt[(GD_TSS0 >> 3) + cpunum()].sd_s = 0;
f010377b:	e8 56 1b 00 00       	call   f01052d6 <cpunum>
f0103780:	80 24 c5 6d f3 11 f0 	andb   $0xef,-0xfee0c93(,%eax,8)
f0103787:	ef 
	ltr(GD_TSS0 + (cpunum() << 3));
f0103788:	e8 49 1b 00 00       	call   f01052d6 <cpunum>
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f010378d:	8d 04 c5 28 00 00 00 	lea    0x28(,%eax,8),%eax
f0103794:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0103797:	b8 ac f3 11 f0       	mov    $0xf011f3ac,%eax
f010379c:	0f 01 18             	lidtl  (%eax)
	lidt(&idt_pd);
}
f010379f:	83 c4 0c             	add    $0xc,%esp
f01037a2:	5b                   	pop    %ebx
f01037a3:	5e                   	pop    %esi
f01037a4:	5f                   	pop    %edi
f01037a5:	5d                   	pop    %ebp
f01037a6:	c3                   	ret    

f01037a7 <trap_init>:
}


void
trap_init(void)
{
f01037a7:	55                   	push   %ebp
f01037a8:	89 e5                	mov    %esp,%ebp
f01037aa:	83 ec 08             	sub    $0x8,%esp
	
	void floating_point_error();

	void system_call();

	SETGATE(idt[T_DIVIDE], 1, GD_KT, divide_error, 0);
f01037ad:	b8 2e 3f 10 f0       	mov    $0xf0103f2e,%eax
f01037b2:	66 a3 60 a2 22 f0    	mov    %ax,0xf022a260
f01037b8:	66 c7 05 62 a2 22 f0 	movw   $0x8,0xf022a262
f01037bf:	08 00 
f01037c1:	c6 05 64 a2 22 f0 00 	movb   $0x0,0xf022a264
f01037c8:	c6 05 65 a2 22 f0 8f 	movb   $0x8f,0xf022a265
f01037cf:	c1 e8 10             	shr    $0x10,%eax
f01037d2:	66 a3 66 a2 22 f0    	mov    %ax,0xf022a266
	SETGATE(idt[T_DEBUG], 1, GD_KT, debug_exception, 0);
f01037d8:	b8 34 3f 10 f0       	mov    $0xf0103f34,%eax
f01037dd:	66 a3 68 a2 22 f0    	mov    %ax,0xf022a268
f01037e3:	66 c7 05 6a a2 22 f0 	movw   $0x8,0xf022a26a
f01037ea:	08 00 
f01037ec:	c6 05 6c a2 22 f0 00 	movb   $0x0,0xf022a26c
f01037f3:	c6 05 6d a2 22 f0 8f 	movb   $0x8f,0xf022a26d
f01037fa:	c1 e8 10             	shr    $0x10,%eax
f01037fd:	66 a3 6e a2 22 f0    	mov    %ax,0xf022a26e
	SETGATE(idt[T_NMI], 1, GD_KT, non_maskable_interrupt, 0);
f0103803:	b8 3a 3f 10 f0       	mov    $0xf0103f3a,%eax
f0103808:	66 a3 70 a2 22 f0    	mov    %ax,0xf022a270
f010380e:	66 c7 05 72 a2 22 f0 	movw   $0x8,0xf022a272
f0103815:	08 00 
f0103817:	c6 05 74 a2 22 f0 00 	movb   $0x0,0xf022a274
f010381e:	c6 05 75 a2 22 f0 8f 	movb   $0x8f,0xf022a275
f0103825:	c1 e8 10             	shr    $0x10,%eax
f0103828:	66 a3 76 a2 22 f0    	mov    %ax,0xf022a276
	SETGATE(idt[T_BRKPT], 1, GD_KT, break_point, 3);//!
f010382e:	b8 40 3f 10 f0       	mov    $0xf0103f40,%eax
f0103833:	66 a3 78 a2 22 f0    	mov    %ax,0xf022a278
f0103839:	66 c7 05 7a a2 22 f0 	movw   $0x8,0xf022a27a
f0103840:	08 00 
f0103842:	c6 05 7c a2 22 f0 00 	movb   $0x0,0xf022a27c
f0103849:	c6 05 7d a2 22 f0 ef 	movb   $0xef,0xf022a27d
f0103850:	c1 e8 10             	shr    $0x10,%eax
f0103853:	66 a3 7e a2 22 f0    	mov    %ax,0xf022a27e
	SETGATE(idt[T_OFLOW], 1, GD_KT, overflow, 0);
f0103859:	b8 46 3f 10 f0       	mov    $0xf0103f46,%eax
f010385e:	66 a3 80 a2 22 f0    	mov    %ax,0xf022a280
f0103864:	66 c7 05 82 a2 22 f0 	movw   $0x8,0xf022a282
f010386b:	08 00 
f010386d:	c6 05 84 a2 22 f0 00 	movb   $0x0,0xf022a284
f0103874:	c6 05 85 a2 22 f0 8f 	movb   $0x8f,0xf022a285
f010387b:	c1 e8 10             	shr    $0x10,%eax
f010387e:	66 a3 86 a2 22 f0    	mov    %ax,0xf022a286
	SETGATE(idt[T_BOUND], 1, GD_KT, bounds_check, 0);
f0103884:	b8 4c 3f 10 f0       	mov    $0xf0103f4c,%eax
f0103889:	66 a3 88 a2 22 f0    	mov    %ax,0xf022a288
f010388f:	66 c7 05 8a a2 22 f0 	movw   $0x8,0xf022a28a
f0103896:	08 00 
f0103898:	c6 05 8c a2 22 f0 00 	movb   $0x0,0xf022a28c
f010389f:	c6 05 8d a2 22 f0 8f 	movb   $0x8f,0xf022a28d
f01038a6:	c1 e8 10             	shr    $0x10,%eax
f01038a9:	66 a3 8e a2 22 f0    	mov    %ax,0xf022a28e
	SETGATE(idt[T_ILLOP], 1, GD_KT, illegal_opcode, 0);
f01038af:	b8 52 3f 10 f0       	mov    $0xf0103f52,%eax
f01038b4:	66 a3 90 a2 22 f0    	mov    %ax,0xf022a290
f01038ba:	66 c7 05 92 a2 22 f0 	movw   $0x8,0xf022a292
f01038c1:	08 00 
f01038c3:	c6 05 94 a2 22 f0 00 	movb   $0x0,0xf022a294
f01038ca:	c6 05 95 a2 22 f0 8f 	movb   $0x8f,0xf022a295
f01038d1:	c1 e8 10             	shr    $0x10,%eax
f01038d4:	66 a3 96 a2 22 f0    	mov    %ax,0xf022a296
	SETGATE(idt[T_DEVICE], 1, GD_KT, device_not_available, 0);
f01038da:	b8 58 3f 10 f0       	mov    $0xf0103f58,%eax
f01038df:	66 a3 98 a2 22 f0    	mov    %ax,0xf022a298
f01038e5:	66 c7 05 9a a2 22 f0 	movw   $0x8,0xf022a29a
f01038ec:	08 00 
f01038ee:	c6 05 9c a2 22 f0 00 	movb   $0x0,0xf022a29c
f01038f5:	c6 05 9d a2 22 f0 8f 	movb   $0x8f,0xf022a29d
f01038fc:	c1 e8 10             	shr    $0x10,%eax
f01038ff:	66 a3 9e a2 22 f0    	mov    %ax,0xf022a29e
	SETGATE(idt[T_DBLFLT], 1, GD_KT, double_fault, 0);
f0103905:	b8 5e 3f 10 f0       	mov    $0xf0103f5e,%eax
f010390a:	66 a3 a0 a2 22 f0    	mov    %ax,0xf022a2a0
f0103910:	66 c7 05 a2 a2 22 f0 	movw   $0x8,0xf022a2a2
f0103917:	08 00 
f0103919:	c6 05 a4 a2 22 f0 00 	movb   $0x0,0xf022a2a4
f0103920:	c6 05 a5 a2 22 f0 8f 	movb   $0x8f,0xf022a2a5
f0103927:	c1 e8 10             	shr    $0x10,%eax
f010392a:	66 a3 a6 a2 22 f0    	mov    %ax,0xf022a2a6

	SETGATE(idt[T_TSS], 1, GD_KT, invalid_task_switch_segment, 0);
f0103930:	b8 62 3f 10 f0       	mov    $0xf0103f62,%eax
f0103935:	66 a3 b0 a2 22 f0    	mov    %ax,0xf022a2b0
f010393b:	66 c7 05 b2 a2 22 f0 	movw   $0x8,0xf022a2b2
f0103942:	08 00 
f0103944:	c6 05 b4 a2 22 f0 00 	movb   $0x0,0xf022a2b4
f010394b:	c6 05 b5 a2 22 f0 8f 	movb   $0x8f,0xf022a2b5
f0103952:	c1 e8 10             	shr    $0x10,%eax
f0103955:	66 a3 b6 a2 22 f0    	mov    %ax,0xf022a2b6
	SETGATE(idt[T_SEGNP], 1, GD_KT, segment_not_present, 0);
f010395b:	b8 66 3f 10 f0       	mov    $0xf0103f66,%eax
f0103960:	66 a3 b8 a2 22 f0    	mov    %ax,0xf022a2b8
f0103966:	66 c7 05 ba a2 22 f0 	movw   $0x8,0xf022a2ba
f010396d:	08 00 
f010396f:	c6 05 bc a2 22 f0 00 	movb   $0x0,0xf022a2bc
f0103976:	c6 05 bd a2 22 f0 8f 	movb   $0x8f,0xf022a2bd
f010397d:	c1 e8 10             	shr    $0x10,%eax
f0103980:	66 a3 be a2 22 f0    	mov    %ax,0xf022a2be
	SETGATE(idt[T_STACK], 1, GD_KT, stack_exception, 0);
f0103986:	b8 6a 3f 10 f0       	mov    $0xf0103f6a,%eax
f010398b:	66 a3 c0 a2 22 f0    	mov    %ax,0xf022a2c0
f0103991:	66 c7 05 c2 a2 22 f0 	movw   $0x8,0xf022a2c2
f0103998:	08 00 
f010399a:	c6 05 c4 a2 22 f0 00 	movb   $0x0,0xf022a2c4
f01039a1:	c6 05 c5 a2 22 f0 8f 	movb   $0x8f,0xf022a2c5
f01039a8:	c1 e8 10             	shr    $0x10,%eax
f01039ab:	66 a3 c6 a2 22 f0    	mov    %ax,0xf022a2c6
	SETGATE(idt[T_GPFLT], 1, GD_KT, general_protection_fault, 0);
f01039b1:	b8 6e 3f 10 f0       	mov    $0xf0103f6e,%eax
f01039b6:	66 a3 c8 a2 22 f0    	mov    %ax,0xf022a2c8
f01039bc:	66 c7 05 ca a2 22 f0 	movw   $0x8,0xf022a2ca
f01039c3:	08 00 
f01039c5:	c6 05 cc a2 22 f0 00 	movb   $0x0,0xf022a2cc
f01039cc:	c6 05 cd a2 22 f0 8f 	movb   $0x8f,0xf022a2cd
f01039d3:	c1 e8 10             	shr    $0x10,%eax
f01039d6:	66 a3 ce a2 22 f0    	mov    %ax,0xf022a2ce
	SETGATE(idt[T_PGFLT], 1, GD_KT, page_fault, 0);
f01039dc:	b8 72 3f 10 f0       	mov    $0xf0103f72,%eax
f01039e1:	66 a3 d0 a2 22 f0    	mov    %ax,0xf022a2d0
f01039e7:	66 c7 05 d2 a2 22 f0 	movw   $0x8,0xf022a2d2
f01039ee:	08 00 
f01039f0:	c6 05 d4 a2 22 f0 00 	movb   $0x0,0xf022a2d4
f01039f7:	c6 05 d5 a2 22 f0 8f 	movb   $0x8f,0xf022a2d5
f01039fe:	c1 e8 10             	shr    $0x10,%eax
f0103a01:	66 a3 d6 a2 22 f0    	mov    %ax,0xf022a2d6

	SETGATE(idt[T_FPERR], 1, GD_KT, floating_point_error, 0);
f0103a07:	b8 76 3f 10 f0       	mov    $0xf0103f76,%eax
f0103a0c:	66 a3 e0 a2 22 f0    	mov    %ax,0xf022a2e0
f0103a12:	66 c7 05 e2 a2 22 f0 	movw   $0x8,0xf022a2e2
f0103a19:	08 00 
f0103a1b:	c6 05 e4 a2 22 f0 00 	movb   $0x0,0xf022a2e4
f0103a22:	c6 05 e5 a2 22 f0 8f 	movb   $0x8f,0xf022a2e5
f0103a29:	c1 e8 10             	shr    $0x10,%eax
f0103a2c:	66 a3 e6 a2 22 f0    	mov    %ax,0xf022a2e6

	SETGATE(idt[T_SYSCALL], 0, GD_KT, system_call, 3);
f0103a32:	b8 7c 3f 10 f0       	mov    $0xf0103f7c,%eax
f0103a37:	66 a3 e0 a3 22 f0    	mov    %ax,0xf022a3e0
f0103a3d:	66 c7 05 e2 a3 22 f0 	movw   $0x8,0xf022a3e2
f0103a44:	08 00 
f0103a46:	c6 05 e4 a3 22 f0 00 	movb   $0x0,0xf022a3e4
f0103a4d:	c6 05 e5 a3 22 f0 ee 	movb   $0xee,0xf022a3e5
f0103a54:	c1 e8 10             	shr    $0x10,%eax
f0103a57:	66 a3 e6 a3 22 f0    	mov    %ax,0xf022a3e6

	// Per-CPU setup 
	trap_init_percpu();
f0103a5d:	e8 73 fc ff ff       	call   f01036d5 <trap_init_percpu>
}
f0103a62:	c9                   	leave  
f0103a63:	c3                   	ret    

f0103a64 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103a64:	55                   	push   %ebp
f0103a65:	89 e5                	mov    %esp,%ebp
f0103a67:	53                   	push   %ebx
f0103a68:	83 ec 0c             	sub    $0xc,%esp
f0103a6b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103a6e:	ff 33                	pushl  (%ebx)
f0103a70:	68 67 6c 10 f0       	push   $0xf0106c67
f0103a75:	e8 47 fc ff ff       	call   f01036c1 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103a7a:	83 c4 08             	add    $0x8,%esp
f0103a7d:	ff 73 04             	pushl  0x4(%ebx)
f0103a80:	68 76 6c 10 f0       	push   $0xf0106c76
f0103a85:	e8 37 fc ff ff       	call   f01036c1 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103a8a:	83 c4 08             	add    $0x8,%esp
f0103a8d:	ff 73 08             	pushl  0x8(%ebx)
f0103a90:	68 85 6c 10 f0       	push   $0xf0106c85
f0103a95:	e8 27 fc ff ff       	call   f01036c1 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103a9a:	83 c4 08             	add    $0x8,%esp
f0103a9d:	ff 73 0c             	pushl  0xc(%ebx)
f0103aa0:	68 94 6c 10 f0       	push   $0xf0106c94
f0103aa5:	e8 17 fc ff ff       	call   f01036c1 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103aaa:	83 c4 08             	add    $0x8,%esp
f0103aad:	ff 73 10             	pushl  0x10(%ebx)
f0103ab0:	68 a3 6c 10 f0       	push   $0xf0106ca3
f0103ab5:	e8 07 fc ff ff       	call   f01036c1 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103aba:	83 c4 08             	add    $0x8,%esp
f0103abd:	ff 73 14             	pushl  0x14(%ebx)
f0103ac0:	68 b2 6c 10 f0       	push   $0xf0106cb2
f0103ac5:	e8 f7 fb ff ff       	call   f01036c1 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103aca:	83 c4 08             	add    $0x8,%esp
f0103acd:	ff 73 18             	pushl  0x18(%ebx)
f0103ad0:	68 c1 6c 10 f0       	push   $0xf0106cc1
f0103ad5:	e8 e7 fb ff ff       	call   f01036c1 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103ada:	83 c4 08             	add    $0x8,%esp
f0103add:	ff 73 1c             	pushl  0x1c(%ebx)
f0103ae0:	68 d0 6c 10 f0       	push   $0xf0106cd0
f0103ae5:	e8 d7 fb ff ff       	call   f01036c1 <cprintf>
}
f0103aea:	83 c4 10             	add    $0x10,%esp
f0103aed:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103af0:	c9                   	leave  
f0103af1:	c3                   	ret    

f0103af2 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103af2:	55                   	push   %ebp
f0103af3:	89 e5                	mov    %esp,%ebp
f0103af5:	56                   	push   %esi
f0103af6:	53                   	push   %ebx
f0103af7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103afa:	e8 d7 17 00 00       	call   f01052d6 <cpunum>
f0103aff:	83 ec 04             	sub    $0x4,%esp
f0103b02:	50                   	push   %eax
f0103b03:	53                   	push   %ebx
f0103b04:	68 34 6d 10 f0       	push   $0xf0106d34
f0103b09:	e8 b3 fb ff ff       	call   f01036c1 <cprintf>
	print_regs(&tf->tf_regs);
f0103b0e:	89 1c 24             	mov    %ebx,(%esp)
f0103b11:	e8 4e ff ff ff       	call   f0103a64 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103b16:	83 c4 08             	add    $0x8,%esp
f0103b19:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103b1d:	50                   	push   %eax
f0103b1e:	68 52 6d 10 f0       	push   $0xf0106d52
f0103b23:	e8 99 fb ff ff       	call   f01036c1 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103b28:	83 c4 08             	add    $0x8,%esp
f0103b2b:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103b2f:	50                   	push   %eax
f0103b30:	68 65 6d 10 f0       	push   $0xf0106d65
f0103b35:	e8 87 fb ff ff       	call   f01036c1 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b3a:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103b3d:	83 c4 10             	add    $0x10,%esp
f0103b40:	83 f8 13             	cmp    $0x13,%eax
f0103b43:	77 09                	ja     f0103b4e <print_trapframe+0x5c>
		return excnames[trapno];
f0103b45:	8b 14 85 00 70 10 f0 	mov    -0xfef9000(,%eax,4),%edx
f0103b4c:	eb 1f                	jmp    f0103b6d <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103b4e:	83 f8 30             	cmp    $0x30,%eax
f0103b51:	74 15                	je     f0103b68 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103b53:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103b56:	83 fa 10             	cmp    $0x10,%edx
f0103b59:	b9 fe 6c 10 f0       	mov    $0xf0106cfe,%ecx
f0103b5e:	ba eb 6c 10 f0       	mov    $0xf0106ceb,%edx
f0103b63:	0f 43 d1             	cmovae %ecx,%edx
f0103b66:	eb 05                	jmp    f0103b6d <print_trapframe+0x7b>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103b68:	ba df 6c 10 f0       	mov    $0xf0106cdf,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b6d:	83 ec 04             	sub    $0x4,%esp
f0103b70:	52                   	push   %edx
f0103b71:	50                   	push   %eax
f0103b72:	68 78 6d 10 f0       	push   $0xf0106d78
f0103b77:	e8 45 fb ff ff       	call   f01036c1 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103b7c:	83 c4 10             	add    $0x10,%esp
f0103b7f:	3b 1d 60 aa 22 f0    	cmp    0xf022aa60,%ebx
f0103b85:	75 1a                	jne    f0103ba1 <print_trapframe+0xaf>
f0103b87:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b8b:	75 14                	jne    f0103ba1 <print_trapframe+0xaf>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103b8d:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103b90:	83 ec 08             	sub    $0x8,%esp
f0103b93:	50                   	push   %eax
f0103b94:	68 8a 6d 10 f0       	push   $0xf0106d8a
f0103b99:	e8 23 fb ff ff       	call   f01036c1 <cprintf>
f0103b9e:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103ba1:	83 ec 08             	sub    $0x8,%esp
f0103ba4:	ff 73 2c             	pushl  0x2c(%ebx)
f0103ba7:	68 99 6d 10 f0       	push   $0xf0106d99
f0103bac:	e8 10 fb ff ff       	call   f01036c1 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103bb1:	83 c4 10             	add    $0x10,%esp
f0103bb4:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103bb8:	75 49                	jne    f0103c03 <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103bba:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103bbd:	89 c2                	mov    %eax,%edx
f0103bbf:	83 e2 01             	and    $0x1,%edx
f0103bc2:	ba 18 6d 10 f0       	mov    $0xf0106d18,%edx
f0103bc7:	b9 0d 6d 10 f0       	mov    $0xf0106d0d,%ecx
f0103bcc:	0f 44 ca             	cmove  %edx,%ecx
f0103bcf:	89 c2                	mov    %eax,%edx
f0103bd1:	83 e2 02             	and    $0x2,%edx
f0103bd4:	ba 2a 6d 10 f0       	mov    $0xf0106d2a,%edx
f0103bd9:	be 24 6d 10 f0       	mov    $0xf0106d24,%esi
f0103bde:	0f 45 d6             	cmovne %esi,%edx
f0103be1:	83 e0 04             	and    $0x4,%eax
f0103be4:	be 47 6e 10 f0       	mov    $0xf0106e47,%esi
f0103be9:	b8 2f 6d 10 f0       	mov    $0xf0106d2f,%eax
f0103bee:	0f 44 c6             	cmove  %esi,%eax
f0103bf1:	51                   	push   %ecx
f0103bf2:	52                   	push   %edx
f0103bf3:	50                   	push   %eax
f0103bf4:	68 a7 6d 10 f0       	push   $0xf0106da7
f0103bf9:	e8 c3 fa ff ff       	call   f01036c1 <cprintf>
f0103bfe:	83 c4 10             	add    $0x10,%esp
f0103c01:	eb 10                	jmp    f0103c13 <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103c03:	83 ec 0c             	sub    $0xc,%esp
f0103c06:	68 e9 5c 10 f0       	push   $0xf0105ce9
f0103c0b:	e8 b1 fa ff ff       	call   f01036c1 <cprintf>
f0103c10:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103c13:	83 ec 08             	sub    $0x8,%esp
f0103c16:	ff 73 30             	pushl  0x30(%ebx)
f0103c19:	68 b6 6d 10 f0       	push   $0xf0106db6
f0103c1e:	e8 9e fa ff ff       	call   f01036c1 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103c23:	83 c4 08             	add    $0x8,%esp
f0103c26:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103c2a:	50                   	push   %eax
f0103c2b:	68 c5 6d 10 f0       	push   $0xf0106dc5
f0103c30:	e8 8c fa ff ff       	call   f01036c1 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103c35:	83 c4 08             	add    $0x8,%esp
f0103c38:	ff 73 38             	pushl  0x38(%ebx)
f0103c3b:	68 d8 6d 10 f0       	push   $0xf0106dd8
f0103c40:	e8 7c fa ff ff       	call   f01036c1 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103c45:	83 c4 10             	add    $0x10,%esp
f0103c48:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c4c:	74 25                	je     f0103c73 <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103c4e:	83 ec 08             	sub    $0x8,%esp
f0103c51:	ff 73 3c             	pushl  0x3c(%ebx)
f0103c54:	68 e7 6d 10 f0       	push   $0xf0106de7
f0103c59:	e8 63 fa ff ff       	call   f01036c1 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103c5e:	83 c4 08             	add    $0x8,%esp
f0103c61:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103c65:	50                   	push   %eax
f0103c66:	68 f6 6d 10 f0       	push   $0xf0106df6
f0103c6b:	e8 51 fa ff ff       	call   f01036c1 <cprintf>
f0103c70:	83 c4 10             	add    $0x10,%esp
	}
}
f0103c73:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103c76:	5b                   	pop    %ebx
f0103c77:	5e                   	pop    %esi
f0103c78:	5d                   	pop    %ebp
f0103c79:	c3                   	ret    

f0103c7a <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103c7a:	55                   	push   %ebp
f0103c7b:	89 e5                	mov    %esp,%ebp
f0103c7d:	57                   	push   %edi
f0103c7e:	56                   	push   %esi
f0103c7f:	53                   	push   %ebx
f0103c80:	83 ec 0c             	sub    $0xc,%esp
f0103c83:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103c86:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs & 3) == 0) //缺页中断发生在内核中
f0103c89:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c8d:	75 17                	jne    f0103ca6 <page_fault_handler+0x2c>
    	panic("page fault happen in kernel mode!\n");
f0103c8f:	83 ec 04             	sub    $0x4,%esp
f0103c92:	68 b0 6f 10 f0       	push   $0xf0106fb0
f0103c97:	68 58 01 00 00       	push   $0x158
f0103c9c:	68 09 6e 10 f0       	push   $0xf0106e09
f0103ca1:	e8 9a c3 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103ca6:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103ca9:	e8 28 16 00 00       	call   f01052d6 <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103cae:	57                   	push   %edi
f0103caf:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103cb0:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103cb3:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103cb9:	ff 70 48             	pushl  0x48(%eax)
f0103cbc:	68 d4 6f 10 f0       	push   $0xf0106fd4
f0103cc1:	e8 fb f9 ff ff       	call   f01036c1 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103cc6:	89 1c 24             	mov    %ebx,(%esp)
f0103cc9:	e8 24 fe ff ff       	call   f0103af2 <print_trapframe>
	env_destroy(curenv);
f0103cce:	e8 03 16 00 00       	call   f01052d6 <cpunum>
f0103cd3:	83 c4 04             	add    $0x4,%esp
f0103cd6:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cd9:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103cdf:	e8 e7 f6 ff ff       	call   f01033cb <env_destroy>
}
f0103ce4:	83 c4 10             	add    $0x10,%esp
f0103ce7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103cea:	5b                   	pop    %ebx
f0103ceb:	5e                   	pop    %esi
f0103cec:	5f                   	pop    %edi
f0103ced:	5d                   	pop    %ebp
f0103cee:	c3                   	ret    

f0103cef <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103cef:	55                   	push   %ebp
f0103cf0:	89 e5                	mov    %esp,%ebp
f0103cf2:	57                   	push   %edi
f0103cf3:	56                   	push   %esi
f0103cf4:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103cf7:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103cf8:	83 3d 80 ae 22 f0 00 	cmpl   $0x0,0xf022ae80
f0103cff:	74 01                	je     f0103d02 <trap+0x13>
		asm volatile("hlt");
f0103d01:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103d02:	e8 cf 15 00 00       	call   f01052d6 <cpunum>
f0103d07:	6b d0 74             	imul   $0x74,%eax,%edx
f0103d0a:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103d10:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d15:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103d19:	83 f8 02             	cmp    $0x2,%eax
f0103d1c:	75 10                	jne    f0103d2e <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103d1e:	83 ec 0c             	sub    $0xc,%esp
f0103d21:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103d26:	e8 19 18 00 00       	call   f0105544 <spin_lock>
f0103d2b:	83 c4 10             	add    $0x10,%esp

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103d2e:	9c                   	pushf  
f0103d2f:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d30:	f6 c4 02             	test   $0x2,%ah
f0103d33:	74 19                	je     f0103d4e <trap+0x5f>
f0103d35:	68 15 6e 10 f0       	push   $0xf0106e15
f0103d3a:	68 7b 68 10 f0       	push   $0xf010687b
f0103d3f:	68 23 01 00 00       	push   $0x123
f0103d44:	68 09 6e 10 f0       	push   $0xf0106e09
f0103d49:	e8 f2 c2 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103d4e:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d52:	83 e0 03             	and    $0x3,%eax
f0103d55:	66 83 f8 03          	cmp    $0x3,%ax
f0103d59:	0f 85 90 00 00 00    	jne    f0103def <trap+0x100>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		assert(curenv);
f0103d5f:	e8 72 15 00 00       	call   f01052d6 <cpunum>
f0103d64:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d67:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103d6e:	75 19                	jne    f0103d89 <trap+0x9a>
f0103d70:	68 2e 6e 10 f0       	push   $0xf0106e2e
f0103d75:	68 7b 68 10 f0       	push   $0xf010687b
f0103d7a:	68 2a 01 00 00       	push   $0x12a
f0103d7f:	68 09 6e 10 f0       	push   $0xf0106e09
f0103d84:	e8 b7 c2 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103d89:	e8 48 15 00 00       	call   f01052d6 <cpunum>
f0103d8e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d91:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103d97:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103d9b:	75 2d                	jne    f0103dca <trap+0xdb>
			env_free(curenv);
f0103d9d:	e8 34 15 00 00       	call   f01052d6 <cpunum>
f0103da2:	83 ec 0c             	sub    $0xc,%esp
f0103da5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103da8:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103dae:	e8 3d f4 ff ff       	call   f01031f0 <env_free>
			curenv = NULL;
f0103db3:	e8 1e 15 00 00       	call   f01052d6 <cpunum>
f0103db8:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dbb:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103dc2:	00 00 00 
			sched_yield();
f0103dc5:	e8 9e 02 00 00       	call   f0104068 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103dca:	e8 07 15 00 00       	call   f01052d6 <cpunum>
f0103dcf:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dd2:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103dd8:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103ddd:	89 c7                	mov    %eax,%edi
f0103ddf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103de1:	e8 f0 14 00 00       	call   f01052d6 <cpunum>
f0103de6:	6b c0 74             	imul   $0x74,%eax,%eax
f0103de9:	8b b0 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103def:	89 35 60 aa 22 f0    	mov    %esi,0xf022aa60
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch (tf->tf_trapno)
f0103df5:	8b 46 28             	mov    0x28(%esi),%eax
f0103df8:	83 f8 0e             	cmp    $0xe,%eax
f0103dfb:	74 0c                	je     f0103e09 <trap+0x11a>
f0103dfd:	83 f8 30             	cmp    $0x30,%eax
f0103e00:	74 23                	je     f0103e25 <trap+0x136>
f0103e02:	83 f8 03             	cmp    $0x3,%eax
f0103e05:	75 3e                	jne    f0103e45 <trap+0x156>
f0103e07:	eb 0e                	jmp    f0103e17 <trap+0x128>
	{
	case T_PGFLT:
		page_fault_handler(tf);
f0103e09:	83 ec 0c             	sub    $0xc,%esp
f0103e0c:	56                   	push   %esi
f0103e0d:	e8 68 fe ff ff       	call   f0103c7a <page_fault_handler>
f0103e12:	83 c4 10             	add    $0x10,%esp
f0103e15:	eb 73                	jmp    f0103e8a <trap+0x19b>
		break;
	case T_BRKPT:
		monitor(tf);
f0103e17:	83 ec 0c             	sub    $0xc,%esp
f0103e1a:	56                   	push   %esi
f0103e1b:	e8 c9 ca ff ff       	call   f01008e9 <monitor>
f0103e20:	83 c4 10             	add    $0x10,%esp
f0103e23:	eb 65                	jmp    f0103e8a <trap+0x19b>
		break;
	case T_SYSCALL:
		tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, 
f0103e25:	8b 46 18             	mov    0x18(%esi),%eax
f0103e28:	83 ec 08             	sub    $0x8,%esp
f0103e2b:	ff 76 04             	pushl  0x4(%esi)
f0103e2e:	ff 36                	pushl  (%esi)
f0103e30:	50                   	push   %eax
f0103e31:	50                   	push   %eax
f0103e32:	ff 76 14             	pushl  0x14(%esi)
f0103e35:	ff 76 1c             	pushl  0x1c(%esi)
f0103e38:	e8 38 02 00 00       	call   f0104075 <syscall>
f0103e3d:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103e40:	83 c4 20             	add    $0x20,%esp
f0103e43:	eb 45                	jmp    f0103e8a <trap+0x19b>
		tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx, tf->tf_regs.reg_ecx, 
		tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
		break;
	default:
		// Unexpected trap: The user process or the kernel has a bug.
		print_trapframe(tf);
f0103e45:	83 ec 0c             	sub    $0xc,%esp
f0103e48:	56                   	push   %esi
f0103e49:	e8 a4 fc ff ff       	call   f0103af2 <print_trapframe>
		if (tf->tf_cs == GD_KT)
f0103e4e:	83 c4 10             	add    $0x10,%esp
f0103e51:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103e56:	75 17                	jne    f0103e6f <trap+0x180>
			panic("unhandled trap in kernel");
f0103e58:	83 ec 04             	sub    $0x4,%esp
f0103e5b:	68 35 6e 10 f0       	push   $0xf0106e35
f0103e60:	68 f1 00 00 00       	push   $0xf1
f0103e65:	68 09 6e 10 f0       	push   $0xf0106e09
f0103e6a:	e8 d1 c1 ff ff       	call   f0100040 <_panic>
		else
		{
			env_destroy(curenv);
f0103e6f:	e8 62 14 00 00       	call   f01052d6 <cpunum>
f0103e74:	83 ec 0c             	sub    $0xc,%esp
f0103e77:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e7a:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103e80:	e8 46 f5 ff ff       	call   f01033cb <env_destroy>
f0103e85:	83 c4 10             	add    $0x10,%esp
f0103e88:	eb 63                	jmp    f0103eed <trap+0x1fe>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103e8a:	83 7e 28 27          	cmpl   $0x27,0x28(%esi)
f0103e8e:	75 1a                	jne    f0103eaa <trap+0x1bb>
		cprintf("Spurious interrupt on irq 7\n");
f0103e90:	83 ec 0c             	sub    $0xc,%esp
f0103e93:	68 4e 6e 10 f0       	push   $0xf0106e4e
f0103e98:	e8 24 f8 ff ff       	call   f01036c1 <cprintf>
		print_trapframe(tf);
f0103e9d:	89 34 24             	mov    %esi,(%esp)
f0103ea0:	e8 4d fc ff ff       	call   f0103af2 <print_trapframe>
f0103ea5:	83 c4 10             	add    $0x10,%esp
f0103ea8:	eb 43                	jmp    f0103eed <trap+0x1fe>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103eaa:	83 ec 0c             	sub    $0xc,%esp
f0103ead:	56                   	push   %esi
f0103eae:	e8 3f fc ff ff       	call   f0103af2 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103eb3:	83 c4 10             	add    $0x10,%esp
f0103eb6:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103ebb:	75 17                	jne    f0103ed4 <trap+0x1e5>
		panic("unhandled trap in kernel");
f0103ebd:	83 ec 04             	sub    $0x4,%esp
f0103ec0:	68 35 6e 10 f0       	push   $0xf0106e35
f0103ec5:	68 09 01 00 00       	push   $0x109
f0103eca:	68 09 6e 10 f0       	push   $0xf0106e09
f0103ecf:	e8 6c c1 ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f0103ed4:	e8 fd 13 00 00       	call   f01052d6 <cpunum>
f0103ed9:	83 ec 0c             	sub    $0xc,%esp
f0103edc:	6b c0 74             	imul   $0x74,%eax,%eax
f0103edf:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103ee5:	e8 e1 f4 ff ff       	call   f01033cb <env_destroy>
f0103eea:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103eed:	e8 e4 13 00 00       	call   f01052d6 <cpunum>
f0103ef2:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ef5:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103efc:	74 2a                	je     f0103f28 <trap+0x239>
f0103efe:	e8 d3 13 00 00       	call   f01052d6 <cpunum>
f0103f03:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f06:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103f0c:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103f10:	75 16                	jne    f0103f28 <trap+0x239>
		env_run(curenv);
f0103f12:	e8 bf 13 00 00       	call   f01052d6 <cpunum>
f0103f17:	83 ec 0c             	sub    $0xc,%esp
f0103f1a:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f1d:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103f23:	e8 42 f5 ff ff       	call   f010346a <env_run>
	else
		sched_yield();
f0103f28:	e8 3b 01 00 00       	call   f0104068 <sched_yield>
f0103f2d:	90                   	nop

f0103f2e <divide_error>:
 * Lab 3: Your code here for generating entry points for the different traps.
 */



	TRAPHANDLER_NOEC(divide_error, T_DIVIDE) 
f0103f2e:	6a 00                	push   $0x0
f0103f30:	6a 00                	push   $0x0
f0103f32:	eb 4e                	jmp    f0103f82 <_alltraps>

f0103f34 <debug_exception>:
	TRAPHANDLER_NOEC(debug_exception, T_DEBUG) 
f0103f34:	6a 00                	push   $0x0
f0103f36:	6a 01                	push   $0x1
f0103f38:	eb 48                	jmp    f0103f82 <_alltraps>

f0103f3a <non_maskable_interrupt>:
	TRAPHANDLER_NOEC(non_maskable_interrupt, T_NMI) 
f0103f3a:	6a 00                	push   $0x0
f0103f3c:	6a 02                	push   $0x2
f0103f3e:	eb 42                	jmp    f0103f82 <_alltraps>

f0103f40 <break_point>:
	TRAPHANDLER_NOEC(break_point, T_BRKPT)// inc/x86.中有breakpoint同名函数
f0103f40:	6a 00                	push   $0x0
f0103f42:	6a 03                	push   $0x3
f0103f44:	eb 3c                	jmp    f0103f82 <_alltraps>

f0103f46 <overflow>:
	TRAPHANDLER_NOEC(overflow, T_OFLOW) 
f0103f46:	6a 00                	push   $0x0
f0103f48:	6a 04                	push   $0x4
f0103f4a:	eb 36                	jmp    f0103f82 <_alltraps>

f0103f4c <bounds_check>:
	TRAPHANDLER_NOEC(bounds_check, T_BOUND) 
f0103f4c:	6a 00                	push   $0x0
f0103f4e:	6a 05                	push   $0x5
f0103f50:	eb 30                	jmp    f0103f82 <_alltraps>

f0103f52 <illegal_opcode>:
	TRAPHANDLER_NOEC(illegal_opcode, T_ILLOP) 
f0103f52:	6a 00                	push   $0x0
f0103f54:	6a 06                	push   $0x6
f0103f56:	eb 2a                	jmp    f0103f82 <_alltraps>

f0103f58 <device_not_available>:
	TRAPHANDLER_NOEC(device_not_available, T_DEVICE) 
f0103f58:	6a 00                	push   $0x0
f0103f5a:	6a 07                	push   $0x7
f0103f5c:	eb 24                	jmp    f0103f82 <_alltraps>

f0103f5e <double_fault>:
	TRAPHANDLER(double_fault, T_DBLFLT) 
f0103f5e:	6a 08                	push   $0x8
f0103f60:	eb 20                	jmp    f0103f82 <_alltraps>

f0103f62 <invalid_task_switch_segment>:

	TRAPHANDLER(invalid_task_switch_segment, T_TSS) 
f0103f62:	6a 0a                	push   $0xa
f0103f64:	eb 1c                	jmp    f0103f82 <_alltraps>

f0103f66 <segment_not_present>:
	TRAPHANDLER(segment_not_present, T_SEGNP) 
f0103f66:	6a 0b                	push   $0xb
f0103f68:	eb 18                	jmp    f0103f82 <_alltraps>

f0103f6a <stack_exception>:
	TRAPHANDLER(stack_exception, T_STACK) 
f0103f6a:	6a 0c                	push   $0xc
f0103f6c:	eb 14                	jmp    f0103f82 <_alltraps>

f0103f6e <general_protection_fault>:
	TRAPHANDLER(general_protection_fault, T_GPFLT) 
f0103f6e:	6a 0d                	push   $0xd
f0103f70:	eb 10                	jmp    f0103f82 <_alltraps>

f0103f72 <page_fault>:
	TRAPHANDLER(page_fault, T_PGFLT) 
f0103f72:	6a 0e                	push   $0xe
f0103f74:	eb 0c                	jmp    f0103f82 <_alltraps>

f0103f76 <floating_point_error>:

	TRAPHANDLER_NOEC(floating_point_error, T_FPERR) 
f0103f76:	6a 00                	push   $0x0
f0103f78:	6a 10                	push   $0x10
f0103f7a:	eb 06                	jmp    f0103f82 <_alltraps>

f0103f7c <system_call>:
	//x86手册9.10中没有说明aligment check && machine check
	//&& SIMD floating point error是否返回error code，故没写上
	TRAPHANDLER_NOEC(system_call, T_SYSCALL)
f0103f7c:	6a 00                	push   $0x0
f0103f7e:	6a 30                	push   $0x30
f0103f80:	eb 00                	jmp    f0103f82 <_alltraps>

f0103f82 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
f0103f82:	1e                   	push   %ds
	pushl %es
f0103f83:	06                   	push   %es
	pushal
f0103f84:	60                   	pusha  

	mov $GD_KD,%eax
f0103f85:	b8 10 00 00 00       	mov    $0x10,%eax
	mov %eax,%ds
f0103f8a:	8e d8                	mov    %eax,%ds
	mov %eax,%es
f0103f8c:	8e c0                	mov    %eax,%es
	
	pushl %esp  //压入trap()的参数tf，%esp指向Trapframe结构的起始地址
f0103f8e:	54                   	push   %esp
	call trap
f0103f8f:	e8 5b fd ff ff       	call   f0103cef <trap>

f0103f94 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0103f94:	55                   	push   %ebp
f0103f95:	89 e5                	mov    %esp,%ebp
f0103f97:	83 ec 08             	sub    $0x8,%esp
f0103f9a:	a1 48 a2 22 f0       	mov    0xf022a248,%eax
f0103f9f:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103fa2:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0103fa7:	8b 02                	mov    (%edx),%eax
f0103fa9:	83 e8 01             	sub    $0x1,%eax
f0103fac:	83 f8 02             	cmp    $0x2,%eax
f0103faf:	76 10                	jbe    f0103fc1 <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103fb1:	83 c1 01             	add    $0x1,%ecx
f0103fb4:	83 c2 7c             	add    $0x7c,%edx
f0103fb7:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103fbd:	75 e8                	jne    f0103fa7 <sched_halt+0x13>
f0103fbf:	eb 08                	jmp    f0103fc9 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0103fc1:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103fc7:	75 1f                	jne    f0103fe8 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0103fc9:	83 ec 0c             	sub    $0xc,%esp
f0103fcc:	68 50 70 10 f0       	push   $0xf0107050
f0103fd1:	e8 eb f6 ff ff       	call   f01036c1 <cprintf>
f0103fd6:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0103fd9:	83 ec 0c             	sub    $0xc,%esp
f0103fdc:	6a 00                	push   $0x0
f0103fde:	e8 06 c9 ff ff       	call   f01008e9 <monitor>
f0103fe3:	83 c4 10             	add    $0x10,%esp
f0103fe6:	eb f1                	jmp    f0103fd9 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0103fe8:	e8 e9 12 00 00       	call   f01052d6 <cpunum>
f0103fed:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ff0:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103ff7:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0103ffa:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103fff:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104004:	77 12                	ja     f0104018 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104006:	50                   	push   %eax
f0104007:	68 a8 59 10 f0       	push   $0xf01059a8
f010400c:	6a 3d                	push   $0x3d
f010400e:	68 79 70 10 f0       	push   $0xf0107079
f0104013:	e8 28 c0 ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0104018:	05 00 00 00 10       	add    $0x10000000,%eax
f010401d:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104020:	e8 b1 12 00 00       	call   f01052d6 <cpunum>
f0104025:	6b d0 74             	imul   $0x74,%eax,%edx
f0104028:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f010402e:	b8 02 00 00 00       	mov    $0x2,%eax
f0104033:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0104037:	83 ec 0c             	sub    $0xc,%esp
f010403a:	68 c0 f3 11 f0       	push   $0xf011f3c0
f010403f:	e8 9d 15 00 00       	call   f01055e1 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0104044:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104046:	e8 8b 12 00 00       	call   f01052d6 <cpunum>
f010404b:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f010404e:	8b 80 30 b0 22 f0    	mov    -0xfdd4fd0(%eax),%eax
f0104054:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104059:	89 c4                	mov    %eax,%esp
f010405b:	6a 00                	push   $0x0
f010405d:	6a 00                	push   $0x0
f010405f:	fb                   	sti    
f0104060:	f4                   	hlt    
f0104061:	eb fd                	jmp    f0104060 <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0104063:	83 c4 10             	add    $0x10,%esp
f0104066:	c9                   	leave  
f0104067:	c3                   	ret    

f0104068 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0104068:	55                   	push   %ebp
f0104069:	89 e5                	mov    %esp,%ebp
f010406b:	83 ec 08             	sub    $0x8,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.

	// sched_halt never returns
	sched_halt();
f010406e:	e8 21 ff ff ff       	call   f0103f94 <sched_halt>
}
f0104073:	c9                   	leave  
f0104074:	c3                   	ret    

f0104075 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104075:	55                   	push   %ebp
f0104076:	89 e5                	mov    %esp,%ebp
f0104078:	53                   	push   %ebx
f0104079:	83 ec 14             	sub    $0x14,%esp
f010407c:	8b 45 08             	mov    0x8(%ebp),%eax
	// LAB 3: Your code here.

	//panic("syscall not implemented");
	int ret;

	switch (syscallno) {
f010407f:	83 f8 01             	cmp    $0x1,%eax
f0104082:	74 53                	je     f01040d7 <syscall+0x62>
f0104084:	83 f8 01             	cmp    $0x1,%eax
f0104087:	72 13                	jb     f010409c <syscall+0x27>
f0104089:	83 f8 02             	cmp    $0x2,%eax
f010408c:	0f 84 db 00 00 00    	je     f010416d <syscall+0xf8>
f0104092:	83 f8 03             	cmp    $0x3,%eax
f0104095:	74 4a                	je     f01040e1 <syscall+0x6c>
f0104097:	e9 e4 00 00 00       	jmp    f0104180 <syscall+0x10b>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f010409c:	e8 35 12 00 00       	call   f01052d6 <cpunum>
f01040a1:	6a 04                	push   $0x4
f01040a3:	ff 75 10             	pushl  0x10(%ebp)
f01040a6:	ff 75 0c             	pushl  0xc(%ebp)
f01040a9:	6b c0 74             	imul   $0x74,%eax,%eax
f01040ac:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f01040b2:	e8 70 ec ff ff       	call   f0102d27 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01040b7:	83 c4 0c             	add    $0xc,%esp
f01040ba:	ff 75 0c             	pushl  0xc(%ebp)
f01040bd:	ff 75 10             	pushl  0x10(%ebp)
f01040c0:	68 86 70 10 f0       	push   $0xf0107086
f01040c5:	e8 f7 f5 ff ff       	call   f01036c1 <cprintf>
f01040ca:	83 c4 10             	add    $0x10,%esp
	int ret;

	switch (syscallno) {
	case SYS_cputs:
		sys_cputs((const char*)a1,(size_t)a2);
		ret = 0;//其他函数都return 0
f01040cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01040d2:	e9 ae 00 00 00       	jmp    f0104185 <syscall+0x110>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01040d7:	e8 f3 c4 ff ff       	call   f01005cf <cons_getc>
		sys_cputs((const char*)a1,(size_t)a2);
		ret = 0;//其他函数都return 0
		break;
	case SYS_cgetc:
		ret = sys_cgetc();
		break;
f01040dc:	e9 a4 00 00 00       	jmp    f0104185 <syscall+0x110>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01040e1:	83 ec 04             	sub    $0x4,%esp
f01040e4:	6a 01                	push   $0x1
f01040e6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01040e9:	50                   	push   %eax
f01040ea:	ff 75 0c             	pushl  0xc(%ebp)
f01040ed:	e8 1f ed ff ff       	call   f0102e11 <envid2env>
f01040f2:	83 c4 10             	add    $0x10,%esp
f01040f5:	85 c0                	test   %eax,%eax
f01040f7:	0f 88 88 00 00 00    	js     f0104185 <syscall+0x110>
		return r;
	if (e == curenv)
f01040fd:	e8 d4 11 00 00       	call   f01052d6 <cpunum>
f0104102:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104105:	6b c0 74             	imul   $0x74,%eax,%eax
f0104108:	39 90 28 b0 22 f0    	cmp    %edx,-0xfdd4fd8(%eax)
f010410e:	75 23                	jne    f0104133 <syscall+0xbe>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104110:	e8 c1 11 00 00       	call   f01052d6 <cpunum>
f0104115:	83 ec 08             	sub    $0x8,%esp
f0104118:	6b c0 74             	imul   $0x74,%eax,%eax
f010411b:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104121:	ff 70 48             	pushl  0x48(%eax)
f0104124:	68 8b 70 10 f0       	push   $0xf010708b
f0104129:	e8 93 f5 ff ff       	call   f01036c1 <cprintf>
f010412e:	83 c4 10             	add    $0x10,%esp
f0104131:	eb 25                	jmp    f0104158 <syscall+0xe3>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104133:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104136:	e8 9b 11 00 00       	call   f01052d6 <cpunum>
f010413b:	83 ec 04             	sub    $0x4,%esp
f010413e:	53                   	push   %ebx
f010413f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104142:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104148:	ff 70 48             	pushl  0x48(%eax)
f010414b:	68 a6 70 10 f0       	push   $0xf01070a6
f0104150:	e8 6c f5 ff ff       	call   f01036c1 <cprintf>
f0104155:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0104158:	83 ec 0c             	sub    $0xc,%esp
f010415b:	ff 75 f4             	pushl  -0xc(%ebp)
f010415e:	e8 68 f2 ff ff       	call   f01033cb <env_destroy>
f0104163:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104166:	b8 00 00 00 00       	mov    $0x0,%eax
f010416b:	eb 18                	jmp    f0104185 <syscall+0x110>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f010416d:	e8 64 11 00 00       	call   f01052d6 <cpunum>
f0104172:	6b c0 74             	imul   $0x74,%eax,%eax
f0104175:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010417b:	8b 40 48             	mov    0x48(%eax),%eax
	case SYS_env_destroy:
		ret = sys_env_destroy((envid_t)a1);
		break;
	case SYS_getenvid:
		ret = sys_getenvid();
		break;
f010417e:	eb 05                	jmp    f0104185 <syscall+0x110>
	default:
		return -E_NO_SYS;
f0104180:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
	}
	return ret;
}
f0104185:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104188:	c9                   	leave  
f0104189:	c3                   	ret    

f010418a <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010418a:	55                   	push   %ebp
f010418b:	89 e5                	mov    %esp,%ebp
f010418d:	57                   	push   %edi
f010418e:	56                   	push   %esi
f010418f:	53                   	push   %ebx
f0104190:	83 ec 14             	sub    $0x14,%esp
f0104193:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104196:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104199:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010419c:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010419f:	8b 1a                	mov    (%edx),%ebx
f01041a1:	8b 01                	mov    (%ecx),%eax
f01041a3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01041a6:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01041ad:	eb 7f                	jmp    f010422e <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01041af:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01041b2:	01 d8                	add    %ebx,%eax
f01041b4:	89 c6                	mov    %eax,%esi
f01041b6:	c1 ee 1f             	shr    $0x1f,%esi
f01041b9:	01 c6                	add    %eax,%esi
f01041bb:	d1 fe                	sar    %esi
f01041bd:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01041c0:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01041c3:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01041c6:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01041c8:	eb 03                	jmp    f01041cd <stab_binsearch+0x43>
			m--;
f01041ca:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01041cd:	39 c3                	cmp    %eax,%ebx
f01041cf:	7f 0d                	jg     f01041de <stab_binsearch+0x54>
f01041d1:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01041d5:	83 ea 0c             	sub    $0xc,%edx
f01041d8:	39 f9                	cmp    %edi,%ecx
f01041da:	75 ee                	jne    f01041ca <stab_binsearch+0x40>
f01041dc:	eb 05                	jmp    f01041e3 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01041de:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01041e1:	eb 4b                	jmp    f010422e <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01041e3:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01041e6:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01041e9:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01041ed:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01041f0:	76 11                	jbe    f0104203 <stab_binsearch+0x79>
			*region_left = m;
f01041f2:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01041f5:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01041f7:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01041fa:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104201:	eb 2b                	jmp    f010422e <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104203:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104206:	73 14                	jae    f010421c <stab_binsearch+0x92>
			*region_right = m - 1;
f0104208:	83 e8 01             	sub    $0x1,%eax
f010420b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010420e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104211:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104213:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010421a:	eb 12                	jmp    f010422e <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010421c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010421f:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0104221:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104225:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104227:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010422e:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104231:	0f 8e 78 ff ff ff    	jle    f01041af <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104237:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010423b:	75 0f                	jne    f010424c <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010423d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104240:	8b 00                	mov    (%eax),%eax
f0104242:	83 e8 01             	sub    $0x1,%eax
f0104245:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104248:	89 06                	mov    %eax,(%esi)
f010424a:	eb 2c                	jmp    f0104278 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010424c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010424f:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104251:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104254:	8b 0e                	mov    (%esi),%ecx
f0104256:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104259:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010425c:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010425f:	eb 03                	jmp    f0104264 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104261:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104264:	39 c8                	cmp    %ecx,%eax
f0104266:	7e 0b                	jle    f0104273 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0104268:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010426c:	83 ea 0c             	sub    $0xc,%edx
f010426f:	39 df                	cmp    %ebx,%edi
f0104271:	75 ee                	jne    f0104261 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104273:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104276:	89 06                	mov    %eax,(%esi)
	}
}
f0104278:	83 c4 14             	add    $0x14,%esp
f010427b:	5b                   	pop    %ebx
f010427c:	5e                   	pop    %esi
f010427d:	5f                   	pop    %edi
f010427e:	5d                   	pop    %ebp
f010427f:	c3                   	ret    

f0104280 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104280:	55                   	push   %ebp
f0104281:	89 e5                	mov    %esp,%ebp
f0104283:	57                   	push   %edi
f0104284:	56                   	push   %esi
f0104285:	53                   	push   %ebx
f0104286:	83 ec 3c             	sub    $0x3c,%esp
f0104289:	8b 7d 08             	mov    0x8(%ebp),%edi
f010428c:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010428f:	c7 06 be 70 10 f0    	movl   $0xf01070be,(%esi)
	info->eip_line = 0;
f0104295:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010429c:	c7 46 08 be 70 10 f0 	movl   $0xf01070be,0x8(%esi)
	info->eip_fn_namelen = 9;
f01042a3:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01042aa:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01042ad:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01042b4:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01042ba:	0f 87 92 00 00 00    	ja     f0104352 <debuginfo_eip+0xd2>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0)
f01042c0:	e8 11 10 00 00       	call   f01052d6 <cpunum>
f01042c5:	6a 04                	push   $0x4
f01042c7:	6a 10                	push   $0x10
f01042c9:	68 00 00 20 00       	push   $0x200000
f01042ce:	6b c0 74             	imul   $0x74,%eax,%eax
f01042d1:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f01042d7:	e8 bc e9 ff ff       	call   f0102c98 <user_mem_check>
f01042dc:	83 c4 10             	add    $0x10,%esp
f01042df:	85 c0                	test   %eax,%eax
f01042e1:	0f 85 01 02 00 00    	jne    f01044e8 <debuginfo_eip+0x268>
			return -1;
		stabs = usd->stabs;
f01042e7:	a1 00 00 20 00       	mov    0x200000,%eax
f01042ec:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f01042ef:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f01042f5:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f01042fb:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f01042fe:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0104304:	89 55 d0             	mov    %edx,-0x30(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, sizeof(struct UserStabData), PTE_U) != 0)
f0104307:	e8 ca 0f 00 00       	call   f01052d6 <cpunum>
f010430c:	6a 04                	push   $0x4
f010430e:	6a 10                	push   $0x10
f0104310:	ff 75 d4             	pushl  -0x2c(%ebp)
f0104313:	6b c0 74             	imul   $0x74,%eax,%eax
f0104316:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f010431c:	e8 77 e9 ff ff       	call   f0102c98 <user_mem_check>
f0104321:	83 c4 10             	add    $0x10,%esp
f0104324:	85 c0                	test   %eax,%eax
f0104326:	0f 85 c3 01 00 00    	jne    f01044ef <debuginfo_eip+0x26f>
			return -1;
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
f010432c:	e8 a5 0f 00 00       	call   f01052d6 <cpunum>
f0104331:	6a 04                	push   $0x4
f0104333:	6a 10                	push   $0x10
f0104335:	ff 75 cc             	pushl  -0x34(%ebp)
f0104338:	6b c0 74             	imul   $0x74,%eax,%eax
f010433b:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0104341:	e8 52 e9 ff ff       	call   f0102c98 <user_mem_check>
f0104346:	83 c4 10             	add    $0x10,%esp
f0104349:	85 c0                	test   %eax,%eax
f010434b:	74 1f                	je     f010436c <debuginfo_eip+0xec>
f010434d:	e9 a4 01 00 00       	jmp    f01044f6 <debuginfo_eip+0x276>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104352:	c7 45 d0 50 42 11 f0 	movl   $0xf0114250,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104359:	c7 45 cc 71 0c 11 f0 	movl   $0xf0110c71,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104360:	bb 70 0c 11 f0       	mov    $0xf0110c70,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104365:	c7 45 d4 98 75 10 f0 	movl   $0xf0107598,-0x2c(%ebp)
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010436c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010436f:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0104372:	0f 83 85 01 00 00    	jae    f01044fd <debuginfo_eip+0x27d>
f0104378:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f010437c:	0f 85 82 01 00 00    	jne    f0104504 <debuginfo_eip+0x284>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104382:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104389:	2b 5d d4             	sub    -0x2c(%ebp),%ebx
f010438c:	c1 fb 02             	sar    $0x2,%ebx
f010438f:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f0104395:	83 e8 01             	sub    $0x1,%eax
f0104398:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010439b:	83 ec 08             	sub    $0x8,%esp
f010439e:	57                   	push   %edi
f010439f:	6a 64                	push   $0x64
f01043a1:	8d 55 e0             	lea    -0x20(%ebp),%edx
f01043a4:	89 d1                	mov    %edx,%ecx
f01043a6:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01043a9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01043ac:	89 d8                	mov    %ebx,%eax
f01043ae:	e8 d7 fd ff ff       	call   f010418a <stab_binsearch>
	if (lfile == 0)
f01043b3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043b6:	83 c4 10             	add    $0x10,%esp
f01043b9:	85 c0                	test   %eax,%eax
f01043bb:	0f 84 4a 01 00 00    	je     f010450b <debuginfo_eip+0x28b>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01043c1:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01043c4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01043c7:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01043ca:	83 ec 08             	sub    $0x8,%esp
f01043cd:	57                   	push   %edi
f01043ce:	6a 24                	push   $0x24
f01043d0:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01043d3:	89 d1                	mov    %edx,%ecx
f01043d5:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01043d8:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f01043db:	89 d8                	mov    %ebx,%eax
f01043dd:	e8 a8 fd ff ff       	call   f010418a <stab_binsearch>

	if (lfun <= rfun) {
f01043e2:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01043e5:	83 c4 10             	add    $0x10,%esp
f01043e8:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f01043eb:	7f 25                	jg     f0104412 <debuginfo_eip+0x192>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01043ed:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01043f0:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01043f3:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01043f6:	8b 02                	mov    (%edx),%eax
f01043f8:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01043fb:	2b 4d cc             	sub    -0x34(%ebp),%ecx
f01043fe:	39 c8                	cmp    %ecx,%eax
f0104400:	73 06                	jae    f0104408 <debuginfo_eip+0x188>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104402:	03 45 cc             	add    -0x34(%ebp),%eax
f0104405:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104408:	8b 42 08             	mov    0x8(%edx),%eax
f010440b:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f010440e:	29 c7                	sub    %eax,%edi
f0104410:	eb 06                	jmp    f0104418 <debuginfo_eip+0x198>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104412:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0104415:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104418:	83 ec 08             	sub    $0x8,%esp
f010441b:	6a 3a                	push   $0x3a
f010441d:	ff 76 08             	pushl  0x8(%esi)
f0104420:	e8 74 08 00 00       	call   f0104c99 <strfind>
f0104425:	2b 46 08             	sub    0x8(%esi),%eax
f0104428:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
f010442b:	83 c4 08             	add    $0x8,%esp
f010442e:	2b 7e 10             	sub    0x10(%esi),%edi
f0104431:	57                   	push   %edi
f0104432:	6a 44                	push   $0x44
f0104434:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104437:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010443a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010443d:	89 f8                	mov    %edi,%eax
f010443f:	e8 46 fd ff ff       	call   f010418a <stab_binsearch>
	if (lfun > rfun) 
f0104444:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104447:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010444a:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f010444d:	83 c4 10             	add    $0x10,%esp
f0104450:	39 c8                	cmp    %ecx,%eax
f0104452:	0f 8f ba 00 00 00    	jg     f0104512 <debuginfo_eip+0x292>
       	  return -1;
        info->eip_line = stabs[lfun].n_desc;
f0104458:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010445b:	89 fa                	mov    %edi,%edx
f010445d:	8d 04 87             	lea    (%edi,%eax,4),%eax
f0104460:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0104463:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f0104467:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010446a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010446d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104470:	8d 04 82             	lea    (%edx,%eax,4),%eax
f0104473:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0104476:	eb 06                	jmp    f010447e <debuginfo_eip+0x1fe>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0104478:	83 eb 01             	sub    $0x1,%ebx
f010447b:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010447e:	39 fb                	cmp    %edi,%ebx
f0104480:	7c 32                	jl     f01044b4 <debuginfo_eip+0x234>
	       && stabs[lline].n_type != N_SOL
f0104482:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0104486:	80 fa 84             	cmp    $0x84,%dl
f0104489:	74 0b                	je     f0104496 <debuginfo_eip+0x216>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010448b:	80 fa 64             	cmp    $0x64,%dl
f010448e:	75 e8                	jne    f0104478 <debuginfo_eip+0x1f8>
f0104490:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0104494:	74 e2                	je     f0104478 <debuginfo_eip+0x1f8>
f0104496:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104499:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010449c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010449f:	8b 04 87             	mov    (%edi,%eax,4),%eax
f01044a2:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01044a5:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01044a8:	29 fa                	sub    %edi,%edx
f01044aa:	39 d0                	cmp    %edx,%eax
f01044ac:	73 09                	jae    f01044b7 <debuginfo_eip+0x237>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01044ae:	01 f8                	add    %edi,%eax
f01044b0:	89 06                	mov    %eax,(%esi)
f01044b2:	eb 03                	jmp    f01044b7 <debuginfo_eip+0x237>
f01044b4:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01044b7:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01044bc:	8b 7d c8             	mov    -0x38(%ebp),%edi
f01044bf:	39 cf                	cmp    %ecx,%edi
f01044c1:	7d 5b                	jge    f010451e <debuginfo_eip+0x29e>
		for (lline = lfun + 1;
f01044c3:	89 f8                	mov    %edi,%eax
f01044c5:	83 c0 01             	add    $0x1,%eax
f01044c8:	8b 55 c0             	mov    -0x40(%ebp),%edx
f01044cb:	eb 07                	jmp    f01044d4 <debuginfo_eip+0x254>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01044cd:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01044d1:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01044d4:	39 c8                	cmp    %ecx,%eax
f01044d6:	74 41                	je     f0104519 <debuginfo_eip+0x299>
f01044d8:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01044db:	80 7a 04 a0          	cmpb   $0xa0,0x4(%edx)
f01044df:	74 ec                	je     f01044cd <debuginfo_eip+0x24d>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01044e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01044e6:	eb 36                	jmp    f010451e <debuginfo_eip+0x29e>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f01044e8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01044ed:	eb 2f                	jmp    f010451e <debuginfo_eip+0x29e>
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f01044ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01044f4:	eb 28                	jmp    f010451e <debuginfo_eip+0x29e>
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f01044f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01044fb:	eb 21                	jmp    f010451e <debuginfo_eip+0x29e>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01044fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104502:	eb 1a                	jmp    f010451e <debuginfo_eip+0x29e>
f0104504:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104509:	eb 13                	jmp    f010451e <debuginfo_eip+0x29e>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f010450b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104510:	eb 0c                	jmp    f010451e <debuginfo_eip+0x29e>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
	if (lfun > rfun) 
       	  return -1;
f0104512:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104517:	eb 05                	jmp    f010451e <debuginfo_eip+0x29e>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104519:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010451e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104521:	5b                   	pop    %ebx
f0104522:	5e                   	pop    %esi
f0104523:	5f                   	pop    %edi
f0104524:	5d                   	pop    %ebp
f0104525:	c3                   	ret    

f0104526 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104526:	55                   	push   %ebp
f0104527:	89 e5                	mov    %esp,%ebp
f0104529:	57                   	push   %edi
f010452a:	56                   	push   %esi
f010452b:	53                   	push   %ebx
f010452c:	83 ec 1c             	sub    $0x1c,%esp
f010452f:	89 c7                	mov    %eax,%edi
f0104531:	89 d6                	mov    %edx,%esi
f0104533:	8b 45 08             	mov    0x8(%ebp),%eax
f0104536:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104539:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010453c:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010453f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104542:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104547:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010454a:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010454d:	39 d3                	cmp    %edx,%ebx
f010454f:	72 05                	jb     f0104556 <printnum+0x30>
f0104551:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104554:	77 45                	ja     f010459b <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104556:	83 ec 0c             	sub    $0xc,%esp
f0104559:	ff 75 18             	pushl  0x18(%ebp)
f010455c:	8b 45 14             	mov    0x14(%ebp),%eax
f010455f:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104562:	53                   	push   %ebx
f0104563:	ff 75 10             	pushl  0x10(%ebp)
f0104566:	83 ec 08             	sub    $0x8,%esp
f0104569:	ff 75 e4             	pushl  -0x1c(%ebp)
f010456c:	ff 75 e0             	pushl  -0x20(%ebp)
f010456f:	ff 75 dc             	pushl  -0x24(%ebp)
f0104572:	ff 75 d8             	pushl  -0x28(%ebp)
f0104575:	e8 56 11 00 00       	call   f01056d0 <__udivdi3>
f010457a:	83 c4 18             	add    $0x18,%esp
f010457d:	52                   	push   %edx
f010457e:	50                   	push   %eax
f010457f:	89 f2                	mov    %esi,%edx
f0104581:	89 f8                	mov    %edi,%eax
f0104583:	e8 9e ff ff ff       	call   f0104526 <printnum>
f0104588:	83 c4 20             	add    $0x20,%esp
f010458b:	eb 18                	jmp    f01045a5 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010458d:	83 ec 08             	sub    $0x8,%esp
f0104590:	56                   	push   %esi
f0104591:	ff 75 18             	pushl  0x18(%ebp)
f0104594:	ff d7                	call   *%edi
f0104596:	83 c4 10             	add    $0x10,%esp
f0104599:	eb 03                	jmp    f010459e <printnum+0x78>
f010459b:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010459e:	83 eb 01             	sub    $0x1,%ebx
f01045a1:	85 db                	test   %ebx,%ebx
f01045a3:	7f e8                	jg     f010458d <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01045a5:	83 ec 08             	sub    $0x8,%esp
f01045a8:	56                   	push   %esi
f01045a9:	83 ec 04             	sub    $0x4,%esp
f01045ac:	ff 75 e4             	pushl  -0x1c(%ebp)
f01045af:	ff 75 e0             	pushl  -0x20(%ebp)
f01045b2:	ff 75 dc             	pushl  -0x24(%ebp)
f01045b5:	ff 75 d8             	pushl  -0x28(%ebp)
f01045b8:	e8 43 12 00 00       	call   f0105800 <__umoddi3>
f01045bd:	83 c4 14             	add    $0x14,%esp
f01045c0:	0f be 80 c8 70 10 f0 	movsbl -0xfef8f38(%eax),%eax
f01045c7:	50                   	push   %eax
f01045c8:	ff d7                	call   *%edi
}
f01045ca:	83 c4 10             	add    $0x10,%esp
f01045cd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01045d0:	5b                   	pop    %ebx
f01045d1:	5e                   	pop    %esi
f01045d2:	5f                   	pop    %edi
f01045d3:	5d                   	pop    %ebp
f01045d4:	c3                   	ret    

f01045d5 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01045d5:	55                   	push   %ebp
f01045d6:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01045d8:	83 fa 01             	cmp    $0x1,%edx
f01045db:	7e 0e                	jle    f01045eb <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01045dd:	8b 10                	mov    (%eax),%edx
f01045df:	8d 4a 08             	lea    0x8(%edx),%ecx
f01045e2:	89 08                	mov    %ecx,(%eax)
f01045e4:	8b 02                	mov    (%edx),%eax
f01045e6:	8b 52 04             	mov    0x4(%edx),%edx
f01045e9:	eb 22                	jmp    f010460d <getuint+0x38>
	else if (lflag)
f01045eb:	85 d2                	test   %edx,%edx
f01045ed:	74 10                	je     f01045ff <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01045ef:	8b 10                	mov    (%eax),%edx
f01045f1:	8d 4a 04             	lea    0x4(%edx),%ecx
f01045f4:	89 08                	mov    %ecx,(%eax)
f01045f6:	8b 02                	mov    (%edx),%eax
f01045f8:	ba 00 00 00 00       	mov    $0x0,%edx
f01045fd:	eb 0e                	jmp    f010460d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01045ff:	8b 10                	mov    (%eax),%edx
f0104601:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104604:	89 08                	mov    %ecx,(%eax)
f0104606:	8b 02                	mov    (%edx),%eax
f0104608:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010460d:	5d                   	pop    %ebp
f010460e:	c3                   	ret    

f010460f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010460f:	55                   	push   %ebp
f0104610:	89 e5                	mov    %esp,%ebp
f0104612:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104615:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104619:	8b 10                	mov    (%eax),%edx
f010461b:	3b 50 04             	cmp    0x4(%eax),%edx
f010461e:	73 0a                	jae    f010462a <sprintputch+0x1b>
		*b->buf++ = ch;
f0104620:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104623:	89 08                	mov    %ecx,(%eax)
f0104625:	8b 45 08             	mov    0x8(%ebp),%eax
f0104628:	88 02                	mov    %al,(%edx)
}
f010462a:	5d                   	pop    %ebp
f010462b:	c3                   	ret    

f010462c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010462c:	55                   	push   %ebp
f010462d:	89 e5                	mov    %esp,%ebp
f010462f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104632:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104635:	50                   	push   %eax
f0104636:	ff 75 10             	pushl  0x10(%ebp)
f0104639:	ff 75 0c             	pushl  0xc(%ebp)
f010463c:	ff 75 08             	pushl  0x8(%ebp)
f010463f:	e8 05 00 00 00       	call   f0104649 <vprintfmt>
	va_end(ap);
}
f0104644:	83 c4 10             	add    $0x10,%esp
f0104647:	c9                   	leave  
f0104648:	c3                   	ret    

f0104649 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104649:	55                   	push   %ebp
f010464a:	89 e5                	mov    %esp,%ebp
f010464c:	57                   	push   %edi
f010464d:	56                   	push   %esi
f010464e:	53                   	push   %ebx
f010464f:	83 ec 2c             	sub    $0x2c,%esp
f0104652:	8b 75 08             	mov    0x8(%ebp),%esi
f0104655:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104658:	8b 7d 10             	mov    0x10(%ebp),%edi
f010465b:	eb 12                	jmp    f010466f <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010465d:	85 c0                	test   %eax,%eax
f010465f:	0f 84 89 03 00 00    	je     f01049ee <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0104665:	83 ec 08             	sub    $0x8,%esp
f0104668:	53                   	push   %ebx
f0104669:	50                   	push   %eax
f010466a:	ff d6                	call   *%esi
f010466c:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010466f:	83 c7 01             	add    $0x1,%edi
f0104672:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104676:	83 f8 25             	cmp    $0x25,%eax
f0104679:	75 e2                	jne    f010465d <vprintfmt+0x14>
f010467b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f010467f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104686:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010468d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104694:	ba 00 00 00 00       	mov    $0x0,%edx
f0104699:	eb 07                	jmp    f01046a2 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010469b:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f010469e:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046a2:	8d 47 01             	lea    0x1(%edi),%eax
f01046a5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01046a8:	0f b6 07             	movzbl (%edi),%eax
f01046ab:	0f b6 c8             	movzbl %al,%ecx
f01046ae:	83 e8 23             	sub    $0x23,%eax
f01046b1:	3c 55                	cmp    $0x55,%al
f01046b3:	0f 87 1a 03 00 00    	ja     f01049d3 <vprintfmt+0x38a>
f01046b9:	0f b6 c0             	movzbl %al,%eax
f01046bc:	ff 24 85 80 71 10 f0 	jmp    *-0xfef8e80(,%eax,4)
f01046c3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01046c6:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01046ca:	eb d6                	jmp    f01046a2 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046cc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01046cf:	b8 00 00 00 00       	mov    $0x0,%eax
f01046d4:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01046d7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01046da:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f01046de:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f01046e1:	8d 51 d0             	lea    -0x30(%ecx),%edx
f01046e4:	83 fa 09             	cmp    $0x9,%edx
f01046e7:	77 39                	ja     f0104722 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01046e9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01046ec:	eb e9                	jmp    f01046d7 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01046ee:	8b 45 14             	mov    0x14(%ebp),%eax
f01046f1:	8d 48 04             	lea    0x4(%eax),%ecx
f01046f4:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01046f7:	8b 00                	mov    (%eax),%eax
f01046f9:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046fc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01046ff:	eb 27                	jmp    f0104728 <vprintfmt+0xdf>
f0104701:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104704:	85 c0                	test   %eax,%eax
f0104706:	b9 00 00 00 00       	mov    $0x0,%ecx
f010470b:	0f 49 c8             	cmovns %eax,%ecx
f010470e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104711:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104714:	eb 8c                	jmp    f01046a2 <vprintfmt+0x59>
f0104716:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104719:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104720:	eb 80                	jmp    f01046a2 <vprintfmt+0x59>
f0104722:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104725:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104728:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010472c:	0f 89 70 ff ff ff    	jns    f01046a2 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104732:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104735:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104738:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010473f:	e9 5e ff ff ff       	jmp    f01046a2 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104744:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104747:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010474a:	e9 53 ff ff ff       	jmp    f01046a2 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010474f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104752:	8d 50 04             	lea    0x4(%eax),%edx
f0104755:	89 55 14             	mov    %edx,0x14(%ebp)
f0104758:	83 ec 08             	sub    $0x8,%esp
f010475b:	53                   	push   %ebx
f010475c:	ff 30                	pushl  (%eax)
f010475e:	ff d6                	call   *%esi
			break;
f0104760:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104763:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104766:	e9 04 ff ff ff       	jmp    f010466f <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010476b:	8b 45 14             	mov    0x14(%ebp),%eax
f010476e:	8d 50 04             	lea    0x4(%eax),%edx
f0104771:	89 55 14             	mov    %edx,0x14(%ebp)
f0104774:	8b 00                	mov    (%eax),%eax
f0104776:	99                   	cltd   
f0104777:	31 d0                	xor    %edx,%eax
f0104779:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010477b:	83 f8 09             	cmp    $0x9,%eax
f010477e:	7f 0b                	jg     f010478b <vprintfmt+0x142>
f0104780:	8b 14 85 e0 72 10 f0 	mov    -0xfef8d20(,%eax,4),%edx
f0104787:	85 d2                	test   %edx,%edx
f0104789:	75 18                	jne    f01047a3 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f010478b:	50                   	push   %eax
f010478c:	68 e0 70 10 f0       	push   $0xf01070e0
f0104791:	53                   	push   %ebx
f0104792:	56                   	push   %esi
f0104793:	e8 94 fe ff ff       	call   f010462c <printfmt>
f0104798:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010479b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010479e:	e9 cc fe ff ff       	jmp    f010466f <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f01047a3:	52                   	push   %edx
f01047a4:	68 8d 68 10 f0       	push   $0xf010688d
f01047a9:	53                   	push   %ebx
f01047aa:	56                   	push   %esi
f01047ab:	e8 7c fe ff ff       	call   f010462c <printfmt>
f01047b0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01047b3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01047b6:	e9 b4 fe ff ff       	jmp    f010466f <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01047bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01047be:	8d 50 04             	lea    0x4(%eax),%edx
f01047c1:	89 55 14             	mov    %edx,0x14(%ebp)
f01047c4:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01047c6:	85 ff                	test   %edi,%edi
f01047c8:	b8 d9 70 10 f0       	mov    $0xf01070d9,%eax
f01047cd:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01047d0:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01047d4:	0f 8e 94 00 00 00    	jle    f010486e <vprintfmt+0x225>
f01047da:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01047de:	0f 84 98 00 00 00    	je     f010487c <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f01047e4:	83 ec 08             	sub    $0x8,%esp
f01047e7:	ff 75 d0             	pushl  -0x30(%ebp)
f01047ea:	57                   	push   %edi
f01047eb:	e8 5f 03 00 00       	call   f0104b4f <strnlen>
f01047f0:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01047f3:	29 c1                	sub    %eax,%ecx
f01047f5:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f01047f8:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01047fb:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01047ff:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104802:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104805:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104807:	eb 0f                	jmp    f0104818 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0104809:	83 ec 08             	sub    $0x8,%esp
f010480c:	53                   	push   %ebx
f010480d:	ff 75 e0             	pushl  -0x20(%ebp)
f0104810:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104812:	83 ef 01             	sub    $0x1,%edi
f0104815:	83 c4 10             	add    $0x10,%esp
f0104818:	85 ff                	test   %edi,%edi
f010481a:	7f ed                	jg     f0104809 <vprintfmt+0x1c0>
f010481c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010481f:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104822:	85 c9                	test   %ecx,%ecx
f0104824:	b8 00 00 00 00       	mov    $0x0,%eax
f0104829:	0f 49 c1             	cmovns %ecx,%eax
f010482c:	29 c1                	sub    %eax,%ecx
f010482e:	89 75 08             	mov    %esi,0x8(%ebp)
f0104831:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104834:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104837:	89 cb                	mov    %ecx,%ebx
f0104839:	eb 4d                	jmp    f0104888 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010483b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010483f:	74 1b                	je     f010485c <vprintfmt+0x213>
f0104841:	0f be c0             	movsbl %al,%eax
f0104844:	83 e8 20             	sub    $0x20,%eax
f0104847:	83 f8 5e             	cmp    $0x5e,%eax
f010484a:	76 10                	jbe    f010485c <vprintfmt+0x213>
					putch('?', putdat);
f010484c:	83 ec 08             	sub    $0x8,%esp
f010484f:	ff 75 0c             	pushl  0xc(%ebp)
f0104852:	6a 3f                	push   $0x3f
f0104854:	ff 55 08             	call   *0x8(%ebp)
f0104857:	83 c4 10             	add    $0x10,%esp
f010485a:	eb 0d                	jmp    f0104869 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f010485c:	83 ec 08             	sub    $0x8,%esp
f010485f:	ff 75 0c             	pushl  0xc(%ebp)
f0104862:	52                   	push   %edx
f0104863:	ff 55 08             	call   *0x8(%ebp)
f0104866:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104869:	83 eb 01             	sub    $0x1,%ebx
f010486c:	eb 1a                	jmp    f0104888 <vprintfmt+0x23f>
f010486e:	89 75 08             	mov    %esi,0x8(%ebp)
f0104871:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104874:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104877:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010487a:	eb 0c                	jmp    f0104888 <vprintfmt+0x23f>
f010487c:	89 75 08             	mov    %esi,0x8(%ebp)
f010487f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104882:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104885:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104888:	83 c7 01             	add    $0x1,%edi
f010488b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010488f:	0f be d0             	movsbl %al,%edx
f0104892:	85 d2                	test   %edx,%edx
f0104894:	74 23                	je     f01048b9 <vprintfmt+0x270>
f0104896:	85 f6                	test   %esi,%esi
f0104898:	78 a1                	js     f010483b <vprintfmt+0x1f2>
f010489a:	83 ee 01             	sub    $0x1,%esi
f010489d:	79 9c                	jns    f010483b <vprintfmt+0x1f2>
f010489f:	89 df                	mov    %ebx,%edi
f01048a1:	8b 75 08             	mov    0x8(%ebp),%esi
f01048a4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01048a7:	eb 18                	jmp    f01048c1 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01048a9:	83 ec 08             	sub    $0x8,%esp
f01048ac:	53                   	push   %ebx
f01048ad:	6a 20                	push   $0x20
f01048af:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01048b1:	83 ef 01             	sub    $0x1,%edi
f01048b4:	83 c4 10             	add    $0x10,%esp
f01048b7:	eb 08                	jmp    f01048c1 <vprintfmt+0x278>
f01048b9:	89 df                	mov    %ebx,%edi
f01048bb:	8b 75 08             	mov    0x8(%ebp),%esi
f01048be:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01048c1:	85 ff                	test   %edi,%edi
f01048c3:	7f e4                	jg     f01048a9 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01048c5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01048c8:	e9 a2 fd ff ff       	jmp    f010466f <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01048cd:	83 fa 01             	cmp    $0x1,%edx
f01048d0:	7e 16                	jle    f01048e8 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01048d2:	8b 45 14             	mov    0x14(%ebp),%eax
f01048d5:	8d 50 08             	lea    0x8(%eax),%edx
f01048d8:	89 55 14             	mov    %edx,0x14(%ebp)
f01048db:	8b 50 04             	mov    0x4(%eax),%edx
f01048de:	8b 00                	mov    (%eax),%eax
f01048e0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01048e3:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01048e6:	eb 32                	jmp    f010491a <vprintfmt+0x2d1>
	else if (lflag)
f01048e8:	85 d2                	test   %edx,%edx
f01048ea:	74 18                	je     f0104904 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f01048ec:	8b 45 14             	mov    0x14(%ebp),%eax
f01048ef:	8d 50 04             	lea    0x4(%eax),%edx
f01048f2:	89 55 14             	mov    %edx,0x14(%ebp)
f01048f5:	8b 00                	mov    (%eax),%eax
f01048f7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01048fa:	89 c1                	mov    %eax,%ecx
f01048fc:	c1 f9 1f             	sar    $0x1f,%ecx
f01048ff:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104902:	eb 16                	jmp    f010491a <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0104904:	8b 45 14             	mov    0x14(%ebp),%eax
f0104907:	8d 50 04             	lea    0x4(%eax),%edx
f010490a:	89 55 14             	mov    %edx,0x14(%ebp)
f010490d:	8b 00                	mov    (%eax),%eax
f010490f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104912:	89 c1                	mov    %eax,%ecx
f0104914:	c1 f9 1f             	sar    $0x1f,%ecx
f0104917:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010491a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010491d:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104920:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104925:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104929:	79 74                	jns    f010499f <vprintfmt+0x356>
				putch('-', putdat);
f010492b:	83 ec 08             	sub    $0x8,%esp
f010492e:	53                   	push   %ebx
f010492f:	6a 2d                	push   $0x2d
f0104931:	ff d6                	call   *%esi
				num = -(long long) num;
f0104933:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104936:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104939:	f7 d8                	neg    %eax
f010493b:	83 d2 00             	adc    $0x0,%edx
f010493e:	f7 da                	neg    %edx
f0104940:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0104943:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104948:	eb 55                	jmp    f010499f <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010494a:	8d 45 14             	lea    0x14(%ebp),%eax
f010494d:	e8 83 fc ff ff       	call   f01045d5 <getuint>
			base = 10;
f0104952:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104957:	eb 46                	jmp    f010499f <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0104959:	8d 45 14             	lea    0x14(%ebp),%eax
f010495c:	e8 74 fc ff ff       	call   f01045d5 <getuint>
			base = 8;
f0104961:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104966:	eb 37                	jmp    f010499f <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0104968:	83 ec 08             	sub    $0x8,%esp
f010496b:	53                   	push   %ebx
f010496c:	6a 30                	push   $0x30
f010496e:	ff d6                	call   *%esi
			putch('x', putdat);
f0104970:	83 c4 08             	add    $0x8,%esp
f0104973:	53                   	push   %ebx
f0104974:	6a 78                	push   $0x78
f0104976:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104978:	8b 45 14             	mov    0x14(%ebp),%eax
f010497b:	8d 50 04             	lea    0x4(%eax),%edx
f010497e:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104981:	8b 00                	mov    (%eax),%eax
f0104983:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0104988:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010498b:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104990:	eb 0d                	jmp    f010499f <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104992:	8d 45 14             	lea    0x14(%ebp),%eax
f0104995:	e8 3b fc ff ff       	call   f01045d5 <getuint>
			base = 16;
f010499a:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010499f:	83 ec 0c             	sub    $0xc,%esp
f01049a2:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01049a6:	57                   	push   %edi
f01049a7:	ff 75 e0             	pushl  -0x20(%ebp)
f01049aa:	51                   	push   %ecx
f01049ab:	52                   	push   %edx
f01049ac:	50                   	push   %eax
f01049ad:	89 da                	mov    %ebx,%edx
f01049af:	89 f0                	mov    %esi,%eax
f01049b1:	e8 70 fb ff ff       	call   f0104526 <printnum>
			break;
f01049b6:	83 c4 20             	add    $0x20,%esp
f01049b9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01049bc:	e9 ae fc ff ff       	jmp    f010466f <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01049c1:	83 ec 08             	sub    $0x8,%esp
f01049c4:	53                   	push   %ebx
f01049c5:	51                   	push   %ecx
f01049c6:	ff d6                	call   *%esi
			break;
f01049c8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01049cb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01049ce:	e9 9c fc ff ff       	jmp    f010466f <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01049d3:	83 ec 08             	sub    $0x8,%esp
f01049d6:	53                   	push   %ebx
f01049d7:	6a 25                	push   $0x25
f01049d9:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01049db:	83 c4 10             	add    $0x10,%esp
f01049de:	eb 03                	jmp    f01049e3 <vprintfmt+0x39a>
f01049e0:	83 ef 01             	sub    $0x1,%edi
f01049e3:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01049e7:	75 f7                	jne    f01049e0 <vprintfmt+0x397>
f01049e9:	e9 81 fc ff ff       	jmp    f010466f <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01049ee:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01049f1:	5b                   	pop    %ebx
f01049f2:	5e                   	pop    %esi
f01049f3:	5f                   	pop    %edi
f01049f4:	5d                   	pop    %ebp
f01049f5:	c3                   	ret    

f01049f6 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01049f6:	55                   	push   %ebp
f01049f7:	89 e5                	mov    %esp,%ebp
f01049f9:	83 ec 18             	sub    $0x18,%esp
f01049fc:	8b 45 08             	mov    0x8(%ebp),%eax
f01049ff:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104a02:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104a05:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104a09:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104a0c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104a13:	85 c0                	test   %eax,%eax
f0104a15:	74 26                	je     f0104a3d <vsnprintf+0x47>
f0104a17:	85 d2                	test   %edx,%edx
f0104a19:	7e 22                	jle    f0104a3d <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104a1b:	ff 75 14             	pushl  0x14(%ebp)
f0104a1e:	ff 75 10             	pushl  0x10(%ebp)
f0104a21:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104a24:	50                   	push   %eax
f0104a25:	68 0f 46 10 f0       	push   $0xf010460f
f0104a2a:	e8 1a fc ff ff       	call   f0104649 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104a2f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104a32:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104a35:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104a38:	83 c4 10             	add    $0x10,%esp
f0104a3b:	eb 05                	jmp    f0104a42 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104a3d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104a42:	c9                   	leave  
f0104a43:	c3                   	ret    

f0104a44 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104a44:	55                   	push   %ebp
f0104a45:	89 e5                	mov    %esp,%ebp
f0104a47:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104a4a:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104a4d:	50                   	push   %eax
f0104a4e:	ff 75 10             	pushl  0x10(%ebp)
f0104a51:	ff 75 0c             	pushl  0xc(%ebp)
f0104a54:	ff 75 08             	pushl  0x8(%ebp)
f0104a57:	e8 9a ff ff ff       	call   f01049f6 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104a5c:	c9                   	leave  
f0104a5d:	c3                   	ret    

f0104a5e <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104a5e:	55                   	push   %ebp
f0104a5f:	89 e5                	mov    %esp,%ebp
f0104a61:	57                   	push   %edi
f0104a62:	56                   	push   %esi
f0104a63:	53                   	push   %ebx
f0104a64:	83 ec 0c             	sub    $0xc,%esp
f0104a67:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104a6a:	85 c0                	test   %eax,%eax
f0104a6c:	74 11                	je     f0104a7f <readline+0x21>
		cprintf("%s", prompt);
f0104a6e:	83 ec 08             	sub    $0x8,%esp
f0104a71:	50                   	push   %eax
f0104a72:	68 8d 68 10 f0       	push   $0xf010688d
f0104a77:	e8 45 ec ff ff       	call   f01036c1 <cprintf>
f0104a7c:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104a7f:	83 ec 0c             	sub    $0xc,%esp
f0104a82:	6a 00                	push   $0x0
f0104a84:	e8 d6 bc ff ff       	call   f010075f <iscons>
f0104a89:	89 c7                	mov    %eax,%edi
f0104a8b:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104a8e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104a93:	e8 b6 bc ff ff       	call   f010074e <getchar>
f0104a98:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104a9a:	85 c0                	test   %eax,%eax
f0104a9c:	79 18                	jns    f0104ab6 <readline+0x58>
			cprintf("read error: %e\n", c);
f0104a9e:	83 ec 08             	sub    $0x8,%esp
f0104aa1:	50                   	push   %eax
f0104aa2:	68 08 73 10 f0       	push   $0xf0107308
f0104aa7:	e8 15 ec ff ff       	call   f01036c1 <cprintf>
			return NULL;
f0104aac:	83 c4 10             	add    $0x10,%esp
f0104aaf:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ab4:	eb 79                	jmp    f0104b2f <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104ab6:	83 f8 08             	cmp    $0x8,%eax
f0104ab9:	0f 94 c2             	sete   %dl
f0104abc:	83 f8 7f             	cmp    $0x7f,%eax
f0104abf:	0f 94 c0             	sete   %al
f0104ac2:	08 c2                	or     %al,%dl
f0104ac4:	74 1a                	je     f0104ae0 <readline+0x82>
f0104ac6:	85 f6                	test   %esi,%esi
f0104ac8:	7e 16                	jle    f0104ae0 <readline+0x82>
			if (echoing)
f0104aca:	85 ff                	test   %edi,%edi
f0104acc:	74 0d                	je     f0104adb <readline+0x7d>
				cputchar('\b');
f0104ace:	83 ec 0c             	sub    $0xc,%esp
f0104ad1:	6a 08                	push   $0x8
f0104ad3:	e8 66 bc ff ff       	call   f010073e <cputchar>
f0104ad8:	83 c4 10             	add    $0x10,%esp
			i--;
f0104adb:	83 ee 01             	sub    $0x1,%esi
f0104ade:	eb b3                	jmp    f0104a93 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104ae0:	83 fb 1f             	cmp    $0x1f,%ebx
f0104ae3:	7e 23                	jle    f0104b08 <readline+0xaa>
f0104ae5:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104aeb:	7f 1b                	jg     f0104b08 <readline+0xaa>
			if (echoing)
f0104aed:	85 ff                	test   %edi,%edi
f0104aef:	74 0c                	je     f0104afd <readline+0x9f>
				cputchar(c);
f0104af1:	83 ec 0c             	sub    $0xc,%esp
f0104af4:	53                   	push   %ebx
f0104af5:	e8 44 bc ff ff       	call   f010073e <cputchar>
f0104afa:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104afd:	88 9e 80 aa 22 f0    	mov    %bl,-0xfdd5580(%esi)
f0104b03:	8d 76 01             	lea    0x1(%esi),%esi
f0104b06:	eb 8b                	jmp    f0104a93 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104b08:	83 fb 0a             	cmp    $0xa,%ebx
f0104b0b:	74 05                	je     f0104b12 <readline+0xb4>
f0104b0d:	83 fb 0d             	cmp    $0xd,%ebx
f0104b10:	75 81                	jne    f0104a93 <readline+0x35>
			if (echoing)
f0104b12:	85 ff                	test   %edi,%edi
f0104b14:	74 0d                	je     f0104b23 <readline+0xc5>
				cputchar('\n');
f0104b16:	83 ec 0c             	sub    $0xc,%esp
f0104b19:	6a 0a                	push   $0xa
f0104b1b:	e8 1e bc ff ff       	call   f010073e <cputchar>
f0104b20:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104b23:	c6 86 80 aa 22 f0 00 	movb   $0x0,-0xfdd5580(%esi)
			return buf;
f0104b2a:	b8 80 aa 22 f0       	mov    $0xf022aa80,%eax
		}
	}
}
f0104b2f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104b32:	5b                   	pop    %ebx
f0104b33:	5e                   	pop    %esi
f0104b34:	5f                   	pop    %edi
f0104b35:	5d                   	pop    %ebp
f0104b36:	c3                   	ret    

f0104b37 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104b37:	55                   	push   %ebp
f0104b38:	89 e5                	mov    %esp,%ebp
f0104b3a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104b3d:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b42:	eb 03                	jmp    f0104b47 <strlen+0x10>
		n++;
f0104b44:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104b47:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104b4b:	75 f7                	jne    f0104b44 <strlen+0xd>
		n++;
	return n;
}
f0104b4d:	5d                   	pop    %ebp
f0104b4e:	c3                   	ret    

f0104b4f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104b4f:	55                   	push   %ebp
f0104b50:	89 e5                	mov    %esp,%ebp
f0104b52:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104b55:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104b58:	ba 00 00 00 00       	mov    $0x0,%edx
f0104b5d:	eb 03                	jmp    f0104b62 <strnlen+0x13>
		n++;
f0104b5f:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104b62:	39 c2                	cmp    %eax,%edx
f0104b64:	74 08                	je     f0104b6e <strnlen+0x1f>
f0104b66:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104b6a:	75 f3                	jne    f0104b5f <strnlen+0x10>
f0104b6c:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104b6e:	5d                   	pop    %ebp
f0104b6f:	c3                   	ret    

f0104b70 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104b70:	55                   	push   %ebp
f0104b71:	89 e5                	mov    %esp,%ebp
f0104b73:	53                   	push   %ebx
f0104b74:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b77:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104b7a:	89 c2                	mov    %eax,%edx
f0104b7c:	83 c2 01             	add    $0x1,%edx
f0104b7f:	83 c1 01             	add    $0x1,%ecx
f0104b82:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104b86:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104b89:	84 db                	test   %bl,%bl
f0104b8b:	75 ef                	jne    f0104b7c <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104b8d:	5b                   	pop    %ebx
f0104b8e:	5d                   	pop    %ebp
f0104b8f:	c3                   	ret    

f0104b90 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104b90:	55                   	push   %ebp
f0104b91:	89 e5                	mov    %esp,%ebp
f0104b93:	53                   	push   %ebx
f0104b94:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104b97:	53                   	push   %ebx
f0104b98:	e8 9a ff ff ff       	call   f0104b37 <strlen>
f0104b9d:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104ba0:	ff 75 0c             	pushl  0xc(%ebp)
f0104ba3:	01 d8                	add    %ebx,%eax
f0104ba5:	50                   	push   %eax
f0104ba6:	e8 c5 ff ff ff       	call   f0104b70 <strcpy>
	return dst;
}
f0104bab:	89 d8                	mov    %ebx,%eax
f0104bad:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104bb0:	c9                   	leave  
f0104bb1:	c3                   	ret    

f0104bb2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104bb2:	55                   	push   %ebp
f0104bb3:	89 e5                	mov    %esp,%ebp
f0104bb5:	56                   	push   %esi
f0104bb6:	53                   	push   %ebx
f0104bb7:	8b 75 08             	mov    0x8(%ebp),%esi
f0104bba:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104bbd:	89 f3                	mov    %esi,%ebx
f0104bbf:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104bc2:	89 f2                	mov    %esi,%edx
f0104bc4:	eb 0f                	jmp    f0104bd5 <strncpy+0x23>
		*dst++ = *src;
f0104bc6:	83 c2 01             	add    $0x1,%edx
f0104bc9:	0f b6 01             	movzbl (%ecx),%eax
f0104bcc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104bcf:	80 39 01             	cmpb   $0x1,(%ecx)
f0104bd2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104bd5:	39 da                	cmp    %ebx,%edx
f0104bd7:	75 ed                	jne    f0104bc6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104bd9:	89 f0                	mov    %esi,%eax
f0104bdb:	5b                   	pop    %ebx
f0104bdc:	5e                   	pop    %esi
f0104bdd:	5d                   	pop    %ebp
f0104bde:	c3                   	ret    

f0104bdf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104bdf:	55                   	push   %ebp
f0104be0:	89 e5                	mov    %esp,%ebp
f0104be2:	56                   	push   %esi
f0104be3:	53                   	push   %ebx
f0104be4:	8b 75 08             	mov    0x8(%ebp),%esi
f0104be7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104bea:	8b 55 10             	mov    0x10(%ebp),%edx
f0104bed:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104bef:	85 d2                	test   %edx,%edx
f0104bf1:	74 21                	je     f0104c14 <strlcpy+0x35>
f0104bf3:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104bf7:	89 f2                	mov    %esi,%edx
f0104bf9:	eb 09                	jmp    f0104c04 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104bfb:	83 c2 01             	add    $0x1,%edx
f0104bfe:	83 c1 01             	add    $0x1,%ecx
f0104c01:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104c04:	39 c2                	cmp    %eax,%edx
f0104c06:	74 09                	je     f0104c11 <strlcpy+0x32>
f0104c08:	0f b6 19             	movzbl (%ecx),%ebx
f0104c0b:	84 db                	test   %bl,%bl
f0104c0d:	75 ec                	jne    f0104bfb <strlcpy+0x1c>
f0104c0f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104c11:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104c14:	29 f0                	sub    %esi,%eax
}
f0104c16:	5b                   	pop    %ebx
f0104c17:	5e                   	pop    %esi
f0104c18:	5d                   	pop    %ebp
f0104c19:	c3                   	ret    

f0104c1a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104c1a:	55                   	push   %ebp
f0104c1b:	89 e5                	mov    %esp,%ebp
f0104c1d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104c20:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104c23:	eb 06                	jmp    f0104c2b <strcmp+0x11>
		p++, q++;
f0104c25:	83 c1 01             	add    $0x1,%ecx
f0104c28:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104c2b:	0f b6 01             	movzbl (%ecx),%eax
f0104c2e:	84 c0                	test   %al,%al
f0104c30:	74 04                	je     f0104c36 <strcmp+0x1c>
f0104c32:	3a 02                	cmp    (%edx),%al
f0104c34:	74 ef                	je     f0104c25 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104c36:	0f b6 c0             	movzbl %al,%eax
f0104c39:	0f b6 12             	movzbl (%edx),%edx
f0104c3c:	29 d0                	sub    %edx,%eax
}
f0104c3e:	5d                   	pop    %ebp
f0104c3f:	c3                   	ret    

f0104c40 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104c40:	55                   	push   %ebp
f0104c41:	89 e5                	mov    %esp,%ebp
f0104c43:	53                   	push   %ebx
f0104c44:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c47:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c4a:	89 c3                	mov    %eax,%ebx
f0104c4c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104c4f:	eb 06                	jmp    f0104c57 <strncmp+0x17>
		n--, p++, q++;
f0104c51:	83 c0 01             	add    $0x1,%eax
f0104c54:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104c57:	39 d8                	cmp    %ebx,%eax
f0104c59:	74 15                	je     f0104c70 <strncmp+0x30>
f0104c5b:	0f b6 08             	movzbl (%eax),%ecx
f0104c5e:	84 c9                	test   %cl,%cl
f0104c60:	74 04                	je     f0104c66 <strncmp+0x26>
f0104c62:	3a 0a                	cmp    (%edx),%cl
f0104c64:	74 eb                	je     f0104c51 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104c66:	0f b6 00             	movzbl (%eax),%eax
f0104c69:	0f b6 12             	movzbl (%edx),%edx
f0104c6c:	29 d0                	sub    %edx,%eax
f0104c6e:	eb 05                	jmp    f0104c75 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104c70:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104c75:	5b                   	pop    %ebx
f0104c76:	5d                   	pop    %ebp
f0104c77:	c3                   	ret    

f0104c78 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104c78:	55                   	push   %ebp
f0104c79:	89 e5                	mov    %esp,%ebp
f0104c7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c7e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104c82:	eb 07                	jmp    f0104c8b <strchr+0x13>
		if (*s == c)
f0104c84:	38 ca                	cmp    %cl,%dl
f0104c86:	74 0f                	je     f0104c97 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104c88:	83 c0 01             	add    $0x1,%eax
f0104c8b:	0f b6 10             	movzbl (%eax),%edx
f0104c8e:	84 d2                	test   %dl,%dl
f0104c90:	75 f2                	jne    f0104c84 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104c92:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104c97:	5d                   	pop    %ebp
f0104c98:	c3                   	ret    

f0104c99 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104c99:	55                   	push   %ebp
f0104c9a:	89 e5                	mov    %esp,%ebp
f0104c9c:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c9f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104ca3:	eb 03                	jmp    f0104ca8 <strfind+0xf>
f0104ca5:	83 c0 01             	add    $0x1,%eax
f0104ca8:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104cab:	38 ca                	cmp    %cl,%dl
f0104cad:	74 04                	je     f0104cb3 <strfind+0x1a>
f0104caf:	84 d2                	test   %dl,%dl
f0104cb1:	75 f2                	jne    f0104ca5 <strfind+0xc>
			break;
	return (char *) s;
}
f0104cb3:	5d                   	pop    %ebp
f0104cb4:	c3                   	ret    

f0104cb5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104cb5:	55                   	push   %ebp
f0104cb6:	89 e5                	mov    %esp,%ebp
f0104cb8:	57                   	push   %edi
f0104cb9:	56                   	push   %esi
f0104cba:	53                   	push   %ebx
f0104cbb:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104cbe:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104cc1:	85 c9                	test   %ecx,%ecx
f0104cc3:	74 36                	je     f0104cfb <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104cc5:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104ccb:	75 28                	jne    f0104cf5 <memset+0x40>
f0104ccd:	f6 c1 03             	test   $0x3,%cl
f0104cd0:	75 23                	jne    f0104cf5 <memset+0x40>
		c &= 0xFF;
f0104cd2:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104cd6:	89 d3                	mov    %edx,%ebx
f0104cd8:	c1 e3 08             	shl    $0x8,%ebx
f0104cdb:	89 d6                	mov    %edx,%esi
f0104cdd:	c1 e6 18             	shl    $0x18,%esi
f0104ce0:	89 d0                	mov    %edx,%eax
f0104ce2:	c1 e0 10             	shl    $0x10,%eax
f0104ce5:	09 f0                	or     %esi,%eax
f0104ce7:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0104ce9:	89 d8                	mov    %ebx,%eax
f0104ceb:	09 d0                	or     %edx,%eax
f0104ced:	c1 e9 02             	shr    $0x2,%ecx
f0104cf0:	fc                   	cld    
f0104cf1:	f3 ab                	rep stos %eax,%es:(%edi)
f0104cf3:	eb 06                	jmp    f0104cfb <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104cf5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104cf8:	fc                   	cld    
f0104cf9:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104cfb:	89 f8                	mov    %edi,%eax
f0104cfd:	5b                   	pop    %ebx
f0104cfe:	5e                   	pop    %esi
f0104cff:	5f                   	pop    %edi
f0104d00:	5d                   	pop    %ebp
f0104d01:	c3                   	ret    

f0104d02 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104d02:	55                   	push   %ebp
f0104d03:	89 e5                	mov    %esp,%ebp
f0104d05:	57                   	push   %edi
f0104d06:	56                   	push   %esi
f0104d07:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d0a:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104d0d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104d10:	39 c6                	cmp    %eax,%esi
f0104d12:	73 35                	jae    f0104d49 <memmove+0x47>
f0104d14:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104d17:	39 d0                	cmp    %edx,%eax
f0104d19:	73 2e                	jae    f0104d49 <memmove+0x47>
		s += n;
		d += n;
f0104d1b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104d1e:	89 d6                	mov    %edx,%esi
f0104d20:	09 fe                	or     %edi,%esi
f0104d22:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104d28:	75 13                	jne    f0104d3d <memmove+0x3b>
f0104d2a:	f6 c1 03             	test   $0x3,%cl
f0104d2d:	75 0e                	jne    f0104d3d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104d2f:	83 ef 04             	sub    $0x4,%edi
f0104d32:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104d35:	c1 e9 02             	shr    $0x2,%ecx
f0104d38:	fd                   	std    
f0104d39:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104d3b:	eb 09                	jmp    f0104d46 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104d3d:	83 ef 01             	sub    $0x1,%edi
f0104d40:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104d43:	fd                   	std    
f0104d44:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104d46:	fc                   	cld    
f0104d47:	eb 1d                	jmp    f0104d66 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104d49:	89 f2                	mov    %esi,%edx
f0104d4b:	09 c2                	or     %eax,%edx
f0104d4d:	f6 c2 03             	test   $0x3,%dl
f0104d50:	75 0f                	jne    f0104d61 <memmove+0x5f>
f0104d52:	f6 c1 03             	test   $0x3,%cl
f0104d55:	75 0a                	jne    f0104d61 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0104d57:	c1 e9 02             	shr    $0x2,%ecx
f0104d5a:	89 c7                	mov    %eax,%edi
f0104d5c:	fc                   	cld    
f0104d5d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104d5f:	eb 05                	jmp    f0104d66 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104d61:	89 c7                	mov    %eax,%edi
f0104d63:	fc                   	cld    
f0104d64:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104d66:	5e                   	pop    %esi
f0104d67:	5f                   	pop    %edi
f0104d68:	5d                   	pop    %ebp
f0104d69:	c3                   	ret    

f0104d6a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104d6a:	55                   	push   %ebp
f0104d6b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104d6d:	ff 75 10             	pushl  0x10(%ebp)
f0104d70:	ff 75 0c             	pushl  0xc(%ebp)
f0104d73:	ff 75 08             	pushl  0x8(%ebp)
f0104d76:	e8 87 ff ff ff       	call   f0104d02 <memmove>
}
f0104d7b:	c9                   	leave  
f0104d7c:	c3                   	ret    

f0104d7d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104d7d:	55                   	push   %ebp
f0104d7e:	89 e5                	mov    %esp,%ebp
f0104d80:	56                   	push   %esi
f0104d81:	53                   	push   %ebx
f0104d82:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d85:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104d88:	89 c6                	mov    %eax,%esi
f0104d8a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104d8d:	eb 1a                	jmp    f0104da9 <memcmp+0x2c>
		if (*s1 != *s2)
f0104d8f:	0f b6 08             	movzbl (%eax),%ecx
f0104d92:	0f b6 1a             	movzbl (%edx),%ebx
f0104d95:	38 d9                	cmp    %bl,%cl
f0104d97:	74 0a                	je     f0104da3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104d99:	0f b6 c1             	movzbl %cl,%eax
f0104d9c:	0f b6 db             	movzbl %bl,%ebx
f0104d9f:	29 d8                	sub    %ebx,%eax
f0104da1:	eb 0f                	jmp    f0104db2 <memcmp+0x35>
		s1++, s2++;
f0104da3:	83 c0 01             	add    $0x1,%eax
f0104da6:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104da9:	39 f0                	cmp    %esi,%eax
f0104dab:	75 e2                	jne    f0104d8f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104dad:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104db2:	5b                   	pop    %ebx
f0104db3:	5e                   	pop    %esi
f0104db4:	5d                   	pop    %ebp
f0104db5:	c3                   	ret    

f0104db6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104db6:	55                   	push   %ebp
f0104db7:	89 e5                	mov    %esp,%ebp
f0104db9:	53                   	push   %ebx
f0104dba:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104dbd:	89 c1                	mov    %eax,%ecx
f0104dbf:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104dc2:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104dc6:	eb 0a                	jmp    f0104dd2 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104dc8:	0f b6 10             	movzbl (%eax),%edx
f0104dcb:	39 da                	cmp    %ebx,%edx
f0104dcd:	74 07                	je     f0104dd6 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104dcf:	83 c0 01             	add    $0x1,%eax
f0104dd2:	39 c8                	cmp    %ecx,%eax
f0104dd4:	72 f2                	jb     f0104dc8 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104dd6:	5b                   	pop    %ebx
f0104dd7:	5d                   	pop    %ebp
f0104dd8:	c3                   	ret    

f0104dd9 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104dd9:	55                   	push   %ebp
f0104dda:	89 e5                	mov    %esp,%ebp
f0104ddc:	57                   	push   %edi
f0104ddd:	56                   	push   %esi
f0104dde:	53                   	push   %ebx
f0104ddf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104de2:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104de5:	eb 03                	jmp    f0104dea <strtol+0x11>
		s++;
f0104de7:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104dea:	0f b6 01             	movzbl (%ecx),%eax
f0104ded:	3c 20                	cmp    $0x20,%al
f0104def:	74 f6                	je     f0104de7 <strtol+0xe>
f0104df1:	3c 09                	cmp    $0x9,%al
f0104df3:	74 f2                	je     f0104de7 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104df5:	3c 2b                	cmp    $0x2b,%al
f0104df7:	75 0a                	jne    f0104e03 <strtol+0x2a>
		s++;
f0104df9:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104dfc:	bf 00 00 00 00       	mov    $0x0,%edi
f0104e01:	eb 11                	jmp    f0104e14 <strtol+0x3b>
f0104e03:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104e08:	3c 2d                	cmp    $0x2d,%al
f0104e0a:	75 08                	jne    f0104e14 <strtol+0x3b>
		s++, neg = 1;
f0104e0c:	83 c1 01             	add    $0x1,%ecx
f0104e0f:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104e14:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104e1a:	75 15                	jne    f0104e31 <strtol+0x58>
f0104e1c:	80 39 30             	cmpb   $0x30,(%ecx)
f0104e1f:	75 10                	jne    f0104e31 <strtol+0x58>
f0104e21:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104e25:	75 7c                	jne    f0104ea3 <strtol+0xca>
		s += 2, base = 16;
f0104e27:	83 c1 02             	add    $0x2,%ecx
f0104e2a:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104e2f:	eb 16                	jmp    f0104e47 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104e31:	85 db                	test   %ebx,%ebx
f0104e33:	75 12                	jne    f0104e47 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104e35:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104e3a:	80 39 30             	cmpb   $0x30,(%ecx)
f0104e3d:	75 08                	jne    f0104e47 <strtol+0x6e>
		s++, base = 8;
f0104e3f:	83 c1 01             	add    $0x1,%ecx
f0104e42:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104e47:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e4c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104e4f:	0f b6 11             	movzbl (%ecx),%edx
f0104e52:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104e55:	89 f3                	mov    %esi,%ebx
f0104e57:	80 fb 09             	cmp    $0x9,%bl
f0104e5a:	77 08                	ja     f0104e64 <strtol+0x8b>
			dig = *s - '0';
f0104e5c:	0f be d2             	movsbl %dl,%edx
f0104e5f:	83 ea 30             	sub    $0x30,%edx
f0104e62:	eb 22                	jmp    f0104e86 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104e64:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104e67:	89 f3                	mov    %esi,%ebx
f0104e69:	80 fb 19             	cmp    $0x19,%bl
f0104e6c:	77 08                	ja     f0104e76 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104e6e:	0f be d2             	movsbl %dl,%edx
f0104e71:	83 ea 57             	sub    $0x57,%edx
f0104e74:	eb 10                	jmp    f0104e86 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104e76:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104e79:	89 f3                	mov    %esi,%ebx
f0104e7b:	80 fb 19             	cmp    $0x19,%bl
f0104e7e:	77 16                	ja     f0104e96 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104e80:	0f be d2             	movsbl %dl,%edx
f0104e83:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104e86:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104e89:	7d 0b                	jge    f0104e96 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104e8b:	83 c1 01             	add    $0x1,%ecx
f0104e8e:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104e92:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104e94:	eb b9                	jmp    f0104e4f <strtol+0x76>

	if (endptr)
f0104e96:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104e9a:	74 0d                	je     f0104ea9 <strtol+0xd0>
		*endptr = (char *) s;
f0104e9c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104e9f:	89 0e                	mov    %ecx,(%esi)
f0104ea1:	eb 06                	jmp    f0104ea9 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104ea3:	85 db                	test   %ebx,%ebx
f0104ea5:	74 98                	je     f0104e3f <strtol+0x66>
f0104ea7:	eb 9e                	jmp    f0104e47 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104ea9:	89 c2                	mov    %eax,%edx
f0104eab:	f7 da                	neg    %edx
f0104ead:	85 ff                	test   %edi,%edi
f0104eaf:	0f 45 c2             	cmovne %edx,%eax
}
f0104eb2:	5b                   	pop    %ebx
f0104eb3:	5e                   	pop    %esi
f0104eb4:	5f                   	pop    %edi
f0104eb5:	5d                   	pop    %ebp
f0104eb6:	c3                   	ret    
f0104eb7:	90                   	nop

f0104eb8 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0104eb8:	fa                   	cli    

	xorw    %ax, %ax
f0104eb9:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0104ebb:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104ebd:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104ebf:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0104ec1:	0f 01 16             	lgdtl  (%esi)
f0104ec4:	74 70                	je     f0104f36 <mpsearch1+0x3>
	movl    %cr0, %eax
f0104ec6:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0104ec9:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0104ecd:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0104ed0:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0104ed6:	08 00                	or     %al,(%eax)

f0104ed8 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0104ed8:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0104edc:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104ede:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104ee0:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0104ee2:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0104ee6:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0104ee8:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0104eea:	b8 00 d0 11 00       	mov    $0x11d000,%eax
	movl    %eax, %cr3
f0104eef:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0104ef2:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0104ef5:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0104efa:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0104efd:	8b 25 84 ae 22 f0    	mov    0xf022ae84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0104f03:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0104f08:	b8 a7 01 10 f0       	mov    $0xf01001a7,%eax
	call    *%eax
f0104f0d:	ff d0                	call   *%eax

f0104f0f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0104f0f:	eb fe                	jmp    f0104f0f <spin>
f0104f11:	8d 76 00             	lea    0x0(%esi),%esi

f0104f14 <gdt>:
	...
f0104f1c:	ff                   	(bad)  
f0104f1d:	ff 00                	incl   (%eax)
f0104f1f:	00 00                	add    %al,(%eax)
f0104f21:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0104f28:	00                   	.byte 0x0
f0104f29:	92                   	xchg   %eax,%edx
f0104f2a:	cf                   	iret   
	...

f0104f2c <gdtdesc>:
f0104f2c:	17                   	pop    %ss
f0104f2d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0104f32 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0104f32:	90                   	nop

f0104f33 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0104f33:	55                   	push   %ebp
f0104f34:	89 e5                	mov    %esp,%ebp
f0104f36:	57                   	push   %edi
f0104f37:	56                   	push   %esi
f0104f38:	53                   	push   %ebx
f0104f39:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104f3c:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f0104f42:	89 c3                	mov    %eax,%ebx
f0104f44:	c1 eb 0c             	shr    $0xc,%ebx
f0104f47:	39 cb                	cmp    %ecx,%ebx
f0104f49:	72 12                	jb     f0104f5d <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104f4b:	50                   	push   %eax
f0104f4c:	68 84 59 10 f0       	push   $0xf0105984
f0104f51:	6a 57                	push   $0x57
f0104f53:	68 a5 74 10 f0       	push   $0xf01074a5
f0104f58:	e8 e3 b0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104f5d:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0104f63:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104f65:	89 c2                	mov    %eax,%edx
f0104f67:	c1 ea 0c             	shr    $0xc,%edx
f0104f6a:	39 ca                	cmp    %ecx,%edx
f0104f6c:	72 12                	jb     f0104f80 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104f6e:	50                   	push   %eax
f0104f6f:	68 84 59 10 f0       	push   $0xf0105984
f0104f74:	6a 57                	push   $0x57
f0104f76:	68 a5 74 10 f0       	push   $0xf01074a5
f0104f7b:	e8 c0 b0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104f80:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0104f86:	eb 2f                	jmp    f0104fb7 <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104f88:	83 ec 04             	sub    $0x4,%esp
f0104f8b:	6a 04                	push   $0x4
f0104f8d:	68 b5 74 10 f0       	push   $0xf01074b5
f0104f92:	53                   	push   %ebx
f0104f93:	e8 e5 fd ff ff       	call   f0104d7d <memcmp>
f0104f98:	83 c4 10             	add    $0x10,%esp
f0104f9b:	85 c0                	test   %eax,%eax
f0104f9d:	75 15                	jne    f0104fb4 <mpsearch1+0x81>
f0104f9f:	89 da                	mov    %ebx,%edx
f0104fa1:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0104fa4:	0f b6 0a             	movzbl (%edx),%ecx
f0104fa7:	01 c8                	add    %ecx,%eax
f0104fa9:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0104fac:	39 d7                	cmp    %edx,%edi
f0104fae:	75 f4                	jne    f0104fa4 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104fb0:	84 c0                	test   %al,%al
f0104fb2:	74 0e                	je     f0104fc2 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0104fb4:	83 c3 10             	add    $0x10,%ebx
f0104fb7:	39 f3                	cmp    %esi,%ebx
f0104fb9:	72 cd                	jb     f0104f88 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0104fbb:	b8 00 00 00 00       	mov    $0x0,%eax
f0104fc0:	eb 02                	jmp    f0104fc4 <mpsearch1+0x91>
f0104fc2:	89 d8                	mov    %ebx,%eax
}
f0104fc4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104fc7:	5b                   	pop    %ebx
f0104fc8:	5e                   	pop    %esi
f0104fc9:	5f                   	pop    %edi
f0104fca:	5d                   	pop    %ebp
f0104fcb:	c3                   	ret    

f0104fcc <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0104fcc:	55                   	push   %ebp
f0104fcd:	89 e5                	mov    %esp,%ebp
f0104fcf:	57                   	push   %edi
f0104fd0:	56                   	push   %esi
f0104fd1:	53                   	push   %ebx
f0104fd2:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0104fd5:	c7 05 c0 b3 22 f0 20 	movl   $0xf022b020,0xf022b3c0
f0104fdc:	b0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104fdf:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f0104fe6:	75 16                	jne    f0104ffe <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104fe8:	68 00 04 00 00       	push   $0x400
f0104fed:	68 84 59 10 f0       	push   $0xf0105984
f0104ff2:	6a 6f                	push   $0x6f
f0104ff4:	68 a5 74 10 f0       	push   $0xf01074a5
f0104ff9:	e8 42 b0 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0104ffe:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105005:	85 c0                	test   %eax,%eax
f0105007:	74 16                	je     f010501f <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f0105009:	c1 e0 04             	shl    $0x4,%eax
f010500c:	ba 00 04 00 00       	mov    $0x400,%edx
f0105011:	e8 1d ff ff ff       	call   f0104f33 <mpsearch1>
f0105016:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105019:	85 c0                	test   %eax,%eax
f010501b:	75 3c                	jne    f0105059 <mp_init+0x8d>
f010501d:	eb 20                	jmp    f010503f <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f010501f:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105026:	c1 e0 0a             	shl    $0xa,%eax
f0105029:	2d 00 04 00 00       	sub    $0x400,%eax
f010502e:	ba 00 04 00 00       	mov    $0x400,%edx
f0105033:	e8 fb fe ff ff       	call   f0104f33 <mpsearch1>
f0105038:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010503b:	85 c0                	test   %eax,%eax
f010503d:	75 1a                	jne    f0105059 <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f010503f:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105044:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105049:	e8 e5 fe ff ff       	call   f0104f33 <mpsearch1>
f010504e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105051:	85 c0                	test   %eax,%eax
f0105053:	0f 84 5d 02 00 00    	je     f01052b6 <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0105059:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010505c:	8b 70 04             	mov    0x4(%eax),%esi
f010505f:	85 f6                	test   %esi,%esi
f0105061:	74 06                	je     f0105069 <mp_init+0x9d>
f0105063:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105067:	74 15                	je     f010507e <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f0105069:	83 ec 0c             	sub    $0xc,%esp
f010506c:	68 18 73 10 f0       	push   $0xf0107318
f0105071:	e8 4b e6 ff ff       	call   f01036c1 <cprintf>
f0105076:	83 c4 10             	add    $0x10,%esp
f0105079:	e9 38 02 00 00       	jmp    f01052b6 <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010507e:	89 f0                	mov    %esi,%eax
f0105080:	c1 e8 0c             	shr    $0xc,%eax
f0105083:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0105089:	72 15                	jb     f01050a0 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010508b:	56                   	push   %esi
f010508c:	68 84 59 10 f0       	push   $0xf0105984
f0105091:	68 90 00 00 00       	push   $0x90
f0105096:	68 a5 74 10 f0       	push   $0xf01074a5
f010509b:	e8 a0 af ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01050a0:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f01050a6:	83 ec 04             	sub    $0x4,%esp
f01050a9:	6a 04                	push   $0x4
f01050ab:	68 ba 74 10 f0       	push   $0xf01074ba
f01050b0:	53                   	push   %ebx
f01050b1:	e8 c7 fc ff ff       	call   f0104d7d <memcmp>
f01050b6:	83 c4 10             	add    $0x10,%esp
f01050b9:	85 c0                	test   %eax,%eax
f01050bb:	74 15                	je     f01050d2 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01050bd:	83 ec 0c             	sub    $0xc,%esp
f01050c0:	68 48 73 10 f0       	push   $0xf0107348
f01050c5:	e8 f7 e5 ff ff       	call   f01036c1 <cprintf>
f01050ca:	83 c4 10             	add    $0x10,%esp
f01050cd:	e9 e4 01 00 00       	jmp    f01052b6 <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01050d2:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f01050d6:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f01050da:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01050dd:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01050e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01050e7:	eb 0d                	jmp    f01050f6 <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f01050e9:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f01050f0:	f0 
f01050f1:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01050f3:	83 c0 01             	add    $0x1,%eax
f01050f6:	39 c7                	cmp    %eax,%edi
f01050f8:	75 ef                	jne    f01050e9 <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01050fa:	84 d2                	test   %dl,%dl
f01050fc:	74 15                	je     f0105113 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f01050fe:	83 ec 0c             	sub    $0xc,%esp
f0105101:	68 7c 73 10 f0       	push   $0xf010737c
f0105106:	e8 b6 e5 ff ff       	call   f01036c1 <cprintf>
f010510b:	83 c4 10             	add    $0x10,%esp
f010510e:	e9 a3 01 00 00       	jmp    f01052b6 <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105113:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105117:	3c 01                	cmp    $0x1,%al
f0105119:	74 1d                	je     f0105138 <mp_init+0x16c>
f010511b:	3c 04                	cmp    $0x4,%al
f010511d:	74 19                	je     f0105138 <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f010511f:	83 ec 08             	sub    $0x8,%esp
f0105122:	0f b6 c0             	movzbl %al,%eax
f0105125:	50                   	push   %eax
f0105126:	68 a0 73 10 f0       	push   $0xf01073a0
f010512b:	e8 91 e5 ff ff       	call   f01036c1 <cprintf>
f0105130:	83 c4 10             	add    $0x10,%esp
f0105133:	e9 7e 01 00 00       	jmp    f01052b6 <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105138:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f010513c:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105140:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105145:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f010514a:	01 ce                	add    %ecx,%esi
f010514c:	eb 0d                	jmp    f010515b <mp_init+0x18f>
f010514e:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f0105155:	f0 
f0105156:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105158:	83 c0 01             	add    $0x1,%eax
f010515b:	39 c7                	cmp    %eax,%edi
f010515d:	75 ef                	jne    f010514e <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010515f:	89 d0                	mov    %edx,%eax
f0105161:	02 43 2a             	add    0x2a(%ebx),%al
f0105164:	74 15                	je     f010517b <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105166:	83 ec 0c             	sub    $0xc,%esp
f0105169:	68 c0 73 10 f0       	push   $0xf01073c0
f010516e:	e8 4e e5 ff ff       	call   f01036c1 <cprintf>
f0105173:	83 c4 10             	add    $0x10,%esp
f0105176:	e9 3b 01 00 00       	jmp    f01052b6 <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f010517b:	85 db                	test   %ebx,%ebx
f010517d:	0f 84 33 01 00 00    	je     f01052b6 <mp_init+0x2ea>
		return;
	ismp = 1;
f0105183:	c7 05 00 b0 22 f0 01 	movl   $0x1,0xf022b000
f010518a:	00 00 00 
	lapicaddr = conf->lapicaddr;
f010518d:	8b 43 24             	mov    0x24(%ebx),%eax
f0105190:	a3 00 c0 26 f0       	mov    %eax,0xf026c000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105195:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f0105198:	be 00 00 00 00       	mov    $0x0,%esi
f010519d:	e9 85 00 00 00       	jmp    f0105227 <mp_init+0x25b>
		switch (*p) {
f01051a2:	0f b6 07             	movzbl (%edi),%eax
f01051a5:	84 c0                	test   %al,%al
f01051a7:	74 06                	je     f01051af <mp_init+0x1e3>
f01051a9:	3c 04                	cmp    $0x4,%al
f01051ab:	77 55                	ja     f0105202 <mp_init+0x236>
f01051ad:	eb 4e                	jmp    f01051fd <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01051af:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01051b3:	74 11                	je     f01051c6 <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f01051b5:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f01051bc:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01051c1:	a3 c0 b3 22 f0       	mov    %eax,0xf022b3c0
			if (ncpu < NCPU) {
f01051c6:	a1 c4 b3 22 f0       	mov    0xf022b3c4,%eax
f01051cb:	83 f8 07             	cmp    $0x7,%eax
f01051ce:	7f 13                	jg     f01051e3 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f01051d0:	6b d0 74             	imul   $0x74,%eax,%edx
f01051d3:	88 82 20 b0 22 f0    	mov    %al,-0xfdd4fe0(%edx)
				ncpu++;
f01051d9:	83 c0 01             	add    $0x1,%eax
f01051dc:	a3 c4 b3 22 f0       	mov    %eax,0xf022b3c4
f01051e1:	eb 15                	jmp    f01051f8 <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01051e3:	83 ec 08             	sub    $0x8,%esp
f01051e6:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f01051ea:	50                   	push   %eax
f01051eb:	68 f0 73 10 f0       	push   $0xf01073f0
f01051f0:	e8 cc e4 ff ff       	call   f01036c1 <cprintf>
f01051f5:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f01051f8:	83 c7 14             	add    $0x14,%edi
			continue;
f01051fb:	eb 27                	jmp    f0105224 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f01051fd:	83 c7 08             	add    $0x8,%edi
			continue;
f0105200:	eb 22                	jmp    f0105224 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105202:	83 ec 08             	sub    $0x8,%esp
f0105205:	0f b6 c0             	movzbl %al,%eax
f0105208:	50                   	push   %eax
f0105209:	68 18 74 10 f0       	push   $0xf0107418
f010520e:	e8 ae e4 ff ff       	call   f01036c1 <cprintf>
			ismp = 0;
f0105213:	c7 05 00 b0 22 f0 00 	movl   $0x0,0xf022b000
f010521a:	00 00 00 
			i = conf->entry;
f010521d:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105221:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105224:	83 c6 01             	add    $0x1,%esi
f0105227:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f010522b:	39 c6                	cmp    %eax,%esi
f010522d:	0f 82 6f ff ff ff    	jb     f01051a2 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105233:	a1 c0 b3 22 f0       	mov    0xf022b3c0,%eax
f0105238:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f010523f:	83 3d 00 b0 22 f0 00 	cmpl   $0x0,0xf022b000
f0105246:	75 26                	jne    f010526e <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105248:	c7 05 c4 b3 22 f0 01 	movl   $0x1,0xf022b3c4
f010524f:	00 00 00 
		lapicaddr = 0;
f0105252:	c7 05 00 c0 26 f0 00 	movl   $0x0,0xf026c000
f0105259:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f010525c:	83 ec 0c             	sub    $0xc,%esp
f010525f:	68 38 74 10 f0       	push   $0xf0107438
f0105264:	e8 58 e4 ff ff       	call   f01036c1 <cprintf>
		return;
f0105269:	83 c4 10             	add    $0x10,%esp
f010526c:	eb 48                	jmp    f01052b6 <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f010526e:	83 ec 04             	sub    $0x4,%esp
f0105271:	ff 35 c4 b3 22 f0    	pushl  0xf022b3c4
f0105277:	0f b6 00             	movzbl (%eax),%eax
f010527a:	50                   	push   %eax
f010527b:	68 bf 74 10 f0       	push   $0xf01074bf
f0105280:	e8 3c e4 ff ff       	call   f01036c1 <cprintf>

	if (mp->imcrp) {
f0105285:	83 c4 10             	add    $0x10,%esp
f0105288:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010528b:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f010528f:	74 25                	je     f01052b6 <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105291:	83 ec 0c             	sub    $0xc,%esp
f0105294:	68 64 74 10 f0       	push   $0xf0107464
f0105299:	e8 23 e4 ff ff       	call   f01036c1 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010529e:	ba 22 00 00 00       	mov    $0x22,%edx
f01052a3:	b8 70 00 00 00       	mov    $0x70,%eax
f01052a8:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01052a9:	ba 23 00 00 00       	mov    $0x23,%edx
f01052ae:	ec                   	in     (%dx),%al
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01052af:	83 c8 01             	or     $0x1,%eax
f01052b2:	ee                   	out    %al,(%dx)
f01052b3:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f01052b6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01052b9:	5b                   	pop    %ebx
f01052ba:	5e                   	pop    %esi
f01052bb:	5f                   	pop    %edi
f01052bc:	5d                   	pop    %ebp
f01052bd:	c3                   	ret    

f01052be <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01052be:	55                   	push   %ebp
f01052bf:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01052c1:	8b 0d 04 c0 26 f0    	mov    0xf026c004,%ecx
f01052c7:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01052ca:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01052cc:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f01052d1:	8b 40 20             	mov    0x20(%eax),%eax
}
f01052d4:	5d                   	pop    %ebp
f01052d5:	c3                   	ret    

f01052d6 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01052d6:	55                   	push   %ebp
f01052d7:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01052d9:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f01052de:	85 c0                	test   %eax,%eax
f01052e0:	74 08                	je     f01052ea <cpunum+0x14>
		return lapic[ID] >> 24;
f01052e2:	8b 40 20             	mov    0x20(%eax),%eax
f01052e5:	c1 e8 18             	shr    $0x18,%eax
f01052e8:	eb 05                	jmp    f01052ef <cpunum+0x19>
	return 0;
f01052ea:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01052ef:	5d                   	pop    %ebp
f01052f0:	c3                   	ret    

f01052f1 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f01052f1:	a1 00 c0 26 f0       	mov    0xf026c000,%eax
f01052f6:	85 c0                	test   %eax,%eax
f01052f8:	0f 84 21 01 00 00    	je     f010541f <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f01052fe:	55                   	push   %ebp
f01052ff:	89 e5                	mov    %esp,%ebp
f0105301:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105304:	68 00 10 00 00       	push   $0x1000
f0105309:	50                   	push   %eax
f010530a:	e8 e2 be ff ff       	call   f01011f1 <mmio_map_region>
f010530f:	a3 04 c0 26 f0       	mov    %eax,0xf026c004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105314:	ba 27 01 00 00       	mov    $0x127,%edx
f0105319:	b8 3c 00 00 00       	mov    $0x3c,%eax
f010531e:	e8 9b ff ff ff       	call   f01052be <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105323:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105328:	b8 f8 00 00 00       	mov    $0xf8,%eax
f010532d:	e8 8c ff ff ff       	call   f01052be <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105332:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105337:	b8 c8 00 00 00       	mov    $0xc8,%eax
f010533c:	e8 7d ff ff ff       	call   f01052be <lapicw>
	lapicw(TICR, 10000000); 
f0105341:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105346:	b8 e0 00 00 00       	mov    $0xe0,%eax
f010534b:	e8 6e ff ff ff       	call   f01052be <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105350:	e8 81 ff ff ff       	call   f01052d6 <cpunum>
f0105355:	6b c0 74             	imul   $0x74,%eax,%eax
f0105358:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010535d:	83 c4 10             	add    $0x10,%esp
f0105360:	39 05 c0 b3 22 f0    	cmp    %eax,0xf022b3c0
f0105366:	74 0f                	je     f0105377 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105368:	ba 00 00 01 00       	mov    $0x10000,%edx
f010536d:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105372:	e8 47 ff ff ff       	call   f01052be <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105377:	ba 00 00 01 00       	mov    $0x10000,%edx
f010537c:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105381:	e8 38 ff ff ff       	call   f01052be <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105386:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f010538b:	8b 40 30             	mov    0x30(%eax),%eax
f010538e:	c1 e8 10             	shr    $0x10,%eax
f0105391:	3c 03                	cmp    $0x3,%al
f0105393:	76 0f                	jbe    f01053a4 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105395:	ba 00 00 01 00       	mov    $0x10000,%edx
f010539a:	b8 d0 00 00 00       	mov    $0xd0,%eax
f010539f:	e8 1a ff ff ff       	call   f01052be <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f01053a4:	ba 33 00 00 00       	mov    $0x33,%edx
f01053a9:	b8 dc 00 00 00       	mov    $0xdc,%eax
f01053ae:	e8 0b ff ff ff       	call   f01052be <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f01053b3:	ba 00 00 00 00       	mov    $0x0,%edx
f01053b8:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01053bd:	e8 fc fe ff ff       	call   f01052be <lapicw>
	lapicw(ESR, 0);
f01053c2:	ba 00 00 00 00       	mov    $0x0,%edx
f01053c7:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01053cc:	e8 ed fe ff ff       	call   f01052be <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f01053d1:	ba 00 00 00 00       	mov    $0x0,%edx
f01053d6:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01053db:	e8 de fe ff ff       	call   f01052be <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f01053e0:	ba 00 00 00 00       	mov    $0x0,%edx
f01053e5:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01053ea:	e8 cf fe ff ff       	call   f01052be <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f01053ef:	ba 00 85 08 00       	mov    $0x88500,%edx
f01053f4:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01053f9:	e8 c0 fe ff ff       	call   f01052be <lapicw>
	while(lapic[ICRLO] & DELIVS)
f01053fe:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f0105404:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010540a:	f6 c4 10             	test   $0x10,%ah
f010540d:	75 f5                	jne    f0105404 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f010540f:	ba 00 00 00 00       	mov    $0x0,%edx
f0105414:	b8 20 00 00 00       	mov    $0x20,%eax
f0105419:	e8 a0 fe ff ff       	call   f01052be <lapicw>
}
f010541e:	c9                   	leave  
f010541f:	f3 c3                	repz ret 

f0105421 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105421:	83 3d 04 c0 26 f0 00 	cmpl   $0x0,0xf026c004
f0105428:	74 13                	je     f010543d <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010542a:	55                   	push   %ebp
f010542b:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f010542d:	ba 00 00 00 00       	mov    $0x0,%edx
f0105432:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105437:	e8 82 fe ff ff       	call   f01052be <lapicw>
}
f010543c:	5d                   	pop    %ebp
f010543d:	f3 c3                	repz ret 

f010543f <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f010543f:	55                   	push   %ebp
f0105440:	89 e5                	mov    %esp,%ebp
f0105442:	56                   	push   %esi
f0105443:	53                   	push   %ebx
f0105444:	8b 75 08             	mov    0x8(%ebp),%esi
f0105447:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010544a:	ba 70 00 00 00       	mov    $0x70,%edx
f010544f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105454:	ee                   	out    %al,(%dx)
f0105455:	ba 71 00 00 00       	mov    $0x71,%edx
f010545a:	b8 0a 00 00 00       	mov    $0xa,%eax
f010545f:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105460:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f0105467:	75 19                	jne    f0105482 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105469:	68 67 04 00 00       	push   $0x467
f010546e:	68 84 59 10 f0       	push   $0xf0105984
f0105473:	68 98 00 00 00       	push   $0x98
f0105478:	68 dc 74 10 f0       	push   $0xf01074dc
f010547d:	e8 be ab ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105482:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105489:	00 00 
	wrv[1] = addr >> 4;
f010548b:	89 d8                	mov    %ebx,%eax
f010548d:	c1 e8 04             	shr    $0x4,%eax
f0105490:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105496:	c1 e6 18             	shl    $0x18,%esi
f0105499:	89 f2                	mov    %esi,%edx
f010549b:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01054a0:	e8 19 fe ff ff       	call   f01052be <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f01054a5:	ba 00 c5 00 00       	mov    $0xc500,%edx
f01054aa:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01054af:	e8 0a fe ff ff       	call   f01052be <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f01054b4:	ba 00 85 00 00       	mov    $0x8500,%edx
f01054b9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01054be:	e8 fb fd ff ff       	call   f01052be <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01054c3:	c1 eb 0c             	shr    $0xc,%ebx
f01054c6:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01054c9:	89 f2                	mov    %esi,%edx
f01054cb:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01054d0:	e8 e9 fd ff ff       	call   f01052be <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01054d5:	89 da                	mov    %ebx,%edx
f01054d7:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01054dc:	e8 dd fd ff ff       	call   f01052be <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01054e1:	89 f2                	mov    %esi,%edx
f01054e3:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01054e8:	e8 d1 fd ff ff       	call   f01052be <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01054ed:	89 da                	mov    %ebx,%edx
f01054ef:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01054f4:	e8 c5 fd ff ff       	call   f01052be <lapicw>
		microdelay(200);
	}
}
f01054f9:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01054fc:	5b                   	pop    %ebx
f01054fd:	5e                   	pop    %esi
f01054fe:	5d                   	pop    %ebp
f01054ff:	c3                   	ret    

f0105500 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105500:	55                   	push   %ebp
f0105501:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105503:	8b 55 08             	mov    0x8(%ebp),%edx
f0105506:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f010550c:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105511:	e8 a8 fd ff ff       	call   f01052be <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105516:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f010551c:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105522:	f6 c4 10             	test   $0x10,%ah
f0105525:	75 f5                	jne    f010551c <lapic_ipi+0x1c>
		;
}
f0105527:	5d                   	pop    %ebp
f0105528:	c3                   	ret    

f0105529 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105529:	55                   	push   %ebp
f010552a:	89 e5                	mov    %esp,%ebp
f010552c:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f010552f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105535:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105538:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f010553b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105542:	5d                   	pop    %ebp
f0105543:	c3                   	ret    

f0105544 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105544:	55                   	push   %ebp
f0105545:	89 e5                	mov    %esp,%ebp
f0105547:	56                   	push   %esi
f0105548:	53                   	push   %ebx
f0105549:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f010554c:	83 3b 00             	cmpl   $0x0,(%ebx)
f010554f:	74 14                	je     f0105565 <spin_lock+0x21>
f0105551:	8b 73 08             	mov    0x8(%ebx),%esi
f0105554:	e8 7d fd ff ff       	call   f01052d6 <cpunum>
f0105559:	6b c0 74             	imul   $0x74,%eax,%eax
f010555c:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105561:	39 c6                	cmp    %eax,%esi
f0105563:	74 07                	je     f010556c <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0105565:	ba 01 00 00 00       	mov    $0x1,%edx
f010556a:	eb 20                	jmp    f010558c <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f010556c:	8b 5b 04             	mov    0x4(%ebx),%ebx
f010556f:	e8 62 fd ff ff       	call   f01052d6 <cpunum>
f0105574:	83 ec 0c             	sub    $0xc,%esp
f0105577:	53                   	push   %ebx
f0105578:	50                   	push   %eax
f0105579:	68 ec 74 10 f0       	push   $0xf01074ec
f010557e:	6a 41                	push   $0x41
f0105580:	68 50 75 10 f0       	push   $0xf0107550
f0105585:	e8 b6 aa ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f010558a:	f3 90                	pause  
f010558c:	89 d0                	mov    %edx,%eax
f010558e:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105591:	85 c0                	test   %eax,%eax
f0105593:	75 f5                	jne    f010558a <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105595:	e8 3c fd ff ff       	call   f01052d6 <cpunum>
f010559a:	6b c0 74             	imul   $0x74,%eax,%eax
f010559d:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01055a2:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f01055a5:	83 c3 0c             	add    $0xc,%ebx

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01055a8:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01055aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01055af:	eb 0b                	jmp    f01055bc <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f01055b1:	8b 4a 04             	mov    0x4(%edx),%ecx
f01055b4:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f01055b7:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01055b9:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f01055bc:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f01055c2:	76 11                	jbe    f01055d5 <spin_lock+0x91>
f01055c4:	83 f8 09             	cmp    $0x9,%eax
f01055c7:	7e e8                	jle    f01055b1 <spin_lock+0x6d>
f01055c9:	eb 0a                	jmp    f01055d5 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f01055cb:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f01055d2:	83 c0 01             	add    $0x1,%eax
f01055d5:	83 f8 09             	cmp    $0x9,%eax
f01055d8:	7e f1                	jle    f01055cb <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f01055da:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01055dd:	5b                   	pop    %ebx
f01055de:	5e                   	pop    %esi
f01055df:	5d                   	pop    %ebp
f01055e0:	c3                   	ret    

f01055e1 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f01055e1:	55                   	push   %ebp
f01055e2:	89 e5                	mov    %esp,%ebp
f01055e4:	57                   	push   %edi
f01055e5:	56                   	push   %esi
f01055e6:	53                   	push   %ebx
f01055e7:	83 ec 4c             	sub    $0x4c,%esp
f01055ea:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f01055ed:	83 3e 00             	cmpl   $0x0,(%esi)
f01055f0:	74 18                	je     f010560a <spin_unlock+0x29>
f01055f2:	8b 5e 08             	mov    0x8(%esi),%ebx
f01055f5:	e8 dc fc ff ff       	call   f01052d6 <cpunum>
f01055fa:	6b c0 74             	imul   $0x74,%eax,%eax
f01055fd:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105602:	39 c3                	cmp    %eax,%ebx
f0105604:	0f 84 a5 00 00 00    	je     f01056af <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f010560a:	83 ec 04             	sub    $0x4,%esp
f010560d:	6a 28                	push   $0x28
f010560f:	8d 46 0c             	lea    0xc(%esi),%eax
f0105612:	50                   	push   %eax
f0105613:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105616:	53                   	push   %ebx
f0105617:	e8 e6 f6 ff ff       	call   f0104d02 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f010561c:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f010561f:	0f b6 38             	movzbl (%eax),%edi
f0105622:	8b 76 04             	mov    0x4(%esi),%esi
f0105625:	e8 ac fc ff ff       	call   f01052d6 <cpunum>
f010562a:	57                   	push   %edi
f010562b:	56                   	push   %esi
f010562c:	50                   	push   %eax
f010562d:	68 18 75 10 f0       	push   $0xf0107518
f0105632:	e8 8a e0 ff ff       	call   f01036c1 <cprintf>
f0105637:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f010563a:	8d 7d a8             	lea    -0x58(%ebp),%edi
f010563d:	eb 54                	jmp    f0105693 <spin_unlock+0xb2>
f010563f:	83 ec 08             	sub    $0x8,%esp
f0105642:	57                   	push   %edi
f0105643:	50                   	push   %eax
f0105644:	e8 37 ec ff ff       	call   f0104280 <debuginfo_eip>
f0105649:	83 c4 10             	add    $0x10,%esp
f010564c:	85 c0                	test   %eax,%eax
f010564e:	78 27                	js     f0105677 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105650:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105652:	83 ec 04             	sub    $0x4,%esp
f0105655:	89 c2                	mov    %eax,%edx
f0105657:	2b 55 b8             	sub    -0x48(%ebp),%edx
f010565a:	52                   	push   %edx
f010565b:	ff 75 b0             	pushl  -0x50(%ebp)
f010565e:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105661:	ff 75 ac             	pushl  -0x54(%ebp)
f0105664:	ff 75 a8             	pushl  -0x58(%ebp)
f0105667:	50                   	push   %eax
f0105668:	68 60 75 10 f0       	push   $0xf0107560
f010566d:	e8 4f e0 ff ff       	call   f01036c1 <cprintf>
f0105672:	83 c4 20             	add    $0x20,%esp
f0105675:	eb 12                	jmp    f0105689 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105677:	83 ec 08             	sub    $0x8,%esp
f010567a:	ff 36                	pushl  (%esi)
f010567c:	68 77 75 10 f0       	push   $0xf0107577
f0105681:	e8 3b e0 ff ff       	call   f01036c1 <cprintf>
f0105686:	83 c4 10             	add    $0x10,%esp
f0105689:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f010568c:	8d 45 e8             	lea    -0x18(%ebp),%eax
f010568f:	39 c3                	cmp    %eax,%ebx
f0105691:	74 08                	je     f010569b <spin_unlock+0xba>
f0105693:	89 de                	mov    %ebx,%esi
f0105695:	8b 03                	mov    (%ebx),%eax
f0105697:	85 c0                	test   %eax,%eax
f0105699:	75 a4                	jne    f010563f <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f010569b:	83 ec 04             	sub    $0x4,%esp
f010569e:	68 7f 75 10 f0       	push   $0xf010757f
f01056a3:	6a 67                	push   $0x67
f01056a5:	68 50 75 10 f0       	push   $0xf0107550
f01056aa:	e8 91 a9 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f01056af:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f01056b6:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f01056bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01056c2:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f01056c5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01056c8:	5b                   	pop    %ebx
f01056c9:	5e                   	pop    %esi
f01056ca:	5f                   	pop    %edi
f01056cb:	5d                   	pop    %ebp
f01056cc:	c3                   	ret    
f01056cd:	66 90                	xchg   %ax,%ax
f01056cf:	90                   	nop

f01056d0 <__udivdi3>:
f01056d0:	55                   	push   %ebp
f01056d1:	57                   	push   %edi
f01056d2:	56                   	push   %esi
f01056d3:	53                   	push   %ebx
f01056d4:	83 ec 1c             	sub    $0x1c,%esp
f01056d7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01056db:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01056df:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01056e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01056e7:	85 f6                	test   %esi,%esi
f01056e9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01056ed:	89 ca                	mov    %ecx,%edx
f01056ef:	89 f8                	mov    %edi,%eax
f01056f1:	75 3d                	jne    f0105730 <__udivdi3+0x60>
f01056f3:	39 cf                	cmp    %ecx,%edi
f01056f5:	0f 87 c5 00 00 00    	ja     f01057c0 <__udivdi3+0xf0>
f01056fb:	85 ff                	test   %edi,%edi
f01056fd:	89 fd                	mov    %edi,%ebp
f01056ff:	75 0b                	jne    f010570c <__udivdi3+0x3c>
f0105701:	b8 01 00 00 00       	mov    $0x1,%eax
f0105706:	31 d2                	xor    %edx,%edx
f0105708:	f7 f7                	div    %edi
f010570a:	89 c5                	mov    %eax,%ebp
f010570c:	89 c8                	mov    %ecx,%eax
f010570e:	31 d2                	xor    %edx,%edx
f0105710:	f7 f5                	div    %ebp
f0105712:	89 c1                	mov    %eax,%ecx
f0105714:	89 d8                	mov    %ebx,%eax
f0105716:	89 cf                	mov    %ecx,%edi
f0105718:	f7 f5                	div    %ebp
f010571a:	89 c3                	mov    %eax,%ebx
f010571c:	89 d8                	mov    %ebx,%eax
f010571e:	89 fa                	mov    %edi,%edx
f0105720:	83 c4 1c             	add    $0x1c,%esp
f0105723:	5b                   	pop    %ebx
f0105724:	5e                   	pop    %esi
f0105725:	5f                   	pop    %edi
f0105726:	5d                   	pop    %ebp
f0105727:	c3                   	ret    
f0105728:	90                   	nop
f0105729:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105730:	39 ce                	cmp    %ecx,%esi
f0105732:	77 74                	ja     f01057a8 <__udivdi3+0xd8>
f0105734:	0f bd fe             	bsr    %esi,%edi
f0105737:	83 f7 1f             	xor    $0x1f,%edi
f010573a:	0f 84 98 00 00 00    	je     f01057d8 <__udivdi3+0x108>
f0105740:	bb 20 00 00 00       	mov    $0x20,%ebx
f0105745:	89 f9                	mov    %edi,%ecx
f0105747:	89 c5                	mov    %eax,%ebp
f0105749:	29 fb                	sub    %edi,%ebx
f010574b:	d3 e6                	shl    %cl,%esi
f010574d:	89 d9                	mov    %ebx,%ecx
f010574f:	d3 ed                	shr    %cl,%ebp
f0105751:	89 f9                	mov    %edi,%ecx
f0105753:	d3 e0                	shl    %cl,%eax
f0105755:	09 ee                	or     %ebp,%esi
f0105757:	89 d9                	mov    %ebx,%ecx
f0105759:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010575d:	89 d5                	mov    %edx,%ebp
f010575f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105763:	d3 ed                	shr    %cl,%ebp
f0105765:	89 f9                	mov    %edi,%ecx
f0105767:	d3 e2                	shl    %cl,%edx
f0105769:	89 d9                	mov    %ebx,%ecx
f010576b:	d3 e8                	shr    %cl,%eax
f010576d:	09 c2                	or     %eax,%edx
f010576f:	89 d0                	mov    %edx,%eax
f0105771:	89 ea                	mov    %ebp,%edx
f0105773:	f7 f6                	div    %esi
f0105775:	89 d5                	mov    %edx,%ebp
f0105777:	89 c3                	mov    %eax,%ebx
f0105779:	f7 64 24 0c          	mull   0xc(%esp)
f010577d:	39 d5                	cmp    %edx,%ebp
f010577f:	72 10                	jb     f0105791 <__udivdi3+0xc1>
f0105781:	8b 74 24 08          	mov    0x8(%esp),%esi
f0105785:	89 f9                	mov    %edi,%ecx
f0105787:	d3 e6                	shl    %cl,%esi
f0105789:	39 c6                	cmp    %eax,%esi
f010578b:	73 07                	jae    f0105794 <__udivdi3+0xc4>
f010578d:	39 d5                	cmp    %edx,%ebp
f010578f:	75 03                	jne    f0105794 <__udivdi3+0xc4>
f0105791:	83 eb 01             	sub    $0x1,%ebx
f0105794:	31 ff                	xor    %edi,%edi
f0105796:	89 d8                	mov    %ebx,%eax
f0105798:	89 fa                	mov    %edi,%edx
f010579a:	83 c4 1c             	add    $0x1c,%esp
f010579d:	5b                   	pop    %ebx
f010579e:	5e                   	pop    %esi
f010579f:	5f                   	pop    %edi
f01057a0:	5d                   	pop    %ebp
f01057a1:	c3                   	ret    
f01057a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01057a8:	31 ff                	xor    %edi,%edi
f01057aa:	31 db                	xor    %ebx,%ebx
f01057ac:	89 d8                	mov    %ebx,%eax
f01057ae:	89 fa                	mov    %edi,%edx
f01057b0:	83 c4 1c             	add    $0x1c,%esp
f01057b3:	5b                   	pop    %ebx
f01057b4:	5e                   	pop    %esi
f01057b5:	5f                   	pop    %edi
f01057b6:	5d                   	pop    %ebp
f01057b7:	c3                   	ret    
f01057b8:	90                   	nop
f01057b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01057c0:	89 d8                	mov    %ebx,%eax
f01057c2:	f7 f7                	div    %edi
f01057c4:	31 ff                	xor    %edi,%edi
f01057c6:	89 c3                	mov    %eax,%ebx
f01057c8:	89 d8                	mov    %ebx,%eax
f01057ca:	89 fa                	mov    %edi,%edx
f01057cc:	83 c4 1c             	add    $0x1c,%esp
f01057cf:	5b                   	pop    %ebx
f01057d0:	5e                   	pop    %esi
f01057d1:	5f                   	pop    %edi
f01057d2:	5d                   	pop    %ebp
f01057d3:	c3                   	ret    
f01057d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01057d8:	39 ce                	cmp    %ecx,%esi
f01057da:	72 0c                	jb     f01057e8 <__udivdi3+0x118>
f01057dc:	31 db                	xor    %ebx,%ebx
f01057de:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01057e2:	0f 87 34 ff ff ff    	ja     f010571c <__udivdi3+0x4c>
f01057e8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01057ed:	e9 2a ff ff ff       	jmp    f010571c <__udivdi3+0x4c>
f01057f2:	66 90                	xchg   %ax,%ax
f01057f4:	66 90                	xchg   %ax,%ax
f01057f6:	66 90                	xchg   %ax,%ax
f01057f8:	66 90                	xchg   %ax,%ax
f01057fa:	66 90                	xchg   %ax,%ax
f01057fc:	66 90                	xchg   %ax,%ax
f01057fe:	66 90                	xchg   %ax,%ax

f0105800 <__umoddi3>:
f0105800:	55                   	push   %ebp
f0105801:	57                   	push   %edi
f0105802:	56                   	push   %esi
f0105803:	53                   	push   %ebx
f0105804:	83 ec 1c             	sub    $0x1c,%esp
f0105807:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010580b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010580f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105813:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105817:	85 d2                	test   %edx,%edx
f0105819:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010581d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105821:	89 f3                	mov    %esi,%ebx
f0105823:	89 3c 24             	mov    %edi,(%esp)
f0105826:	89 74 24 04          	mov    %esi,0x4(%esp)
f010582a:	75 1c                	jne    f0105848 <__umoddi3+0x48>
f010582c:	39 f7                	cmp    %esi,%edi
f010582e:	76 50                	jbe    f0105880 <__umoddi3+0x80>
f0105830:	89 c8                	mov    %ecx,%eax
f0105832:	89 f2                	mov    %esi,%edx
f0105834:	f7 f7                	div    %edi
f0105836:	89 d0                	mov    %edx,%eax
f0105838:	31 d2                	xor    %edx,%edx
f010583a:	83 c4 1c             	add    $0x1c,%esp
f010583d:	5b                   	pop    %ebx
f010583e:	5e                   	pop    %esi
f010583f:	5f                   	pop    %edi
f0105840:	5d                   	pop    %ebp
f0105841:	c3                   	ret    
f0105842:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105848:	39 f2                	cmp    %esi,%edx
f010584a:	89 d0                	mov    %edx,%eax
f010584c:	77 52                	ja     f01058a0 <__umoddi3+0xa0>
f010584e:	0f bd ea             	bsr    %edx,%ebp
f0105851:	83 f5 1f             	xor    $0x1f,%ebp
f0105854:	75 5a                	jne    f01058b0 <__umoddi3+0xb0>
f0105856:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010585a:	0f 82 e0 00 00 00    	jb     f0105940 <__umoddi3+0x140>
f0105860:	39 0c 24             	cmp    %ecx,(%esp)
f0105863:	0f 86 d7 00 00 00    	jbe    f0105940 <__umoddi3+0x140>
f0105869:	8b 44 24 08          	mov    0x8(%esp),%eax
f010586d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105871:	83 c4 1c             	add    $0x1c,%esp
f0105874:	5b                   	pop    %ebx
f0105875:	5e                   	pop    %esi
f0105876:	5f                   	pop    %edi
f0105877:	5d                   	pop    %ebp
f0105878:	c3                   	ret    
f0105879:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105880:	85 ff                	test   %edi,%edi
f0105882:	89 fd                	mov    %edi,%ebp
f0105884:	75 0b                	jne    f0105891 <__umoddi3+0x91>
f0105886:	b8 01 00 00 00       	mov    $0x1,%eax
f010588b:	31 d2                	xor    %edx,%edx
f010588d:	f7 f7                	div    %edi
f010588f:	89 c5                	mov    %eax,%ebp
f0105891:	89 f0                	mov    %esi,%eax
f0105893:	31 d2                	xor    %edx,%edx
f0105895:	f7 f5                	div    %ebp
f0105897:	89 c8                	mov    %ecx,%eax
f0105899:	f7 f5                	div    %ebp
f010589b:	89 d0                	mov    %edx,%eax
f010589d:	eb 99                	jmp    f0105838 <__umoddi3+0x38>
f010589f:	90                   	nop
f01058a0:	89 c8                	mov    %ecx,%eax
f01058a2:	89 f2                	mov    %esi,%edx
f01058a4:	83 c4 1c             	add    $0x1c,%esp
f01058a7:	5b                   	pop    %ebx
f01058a8:	5e                   	pop    %esi
f01058a9:	5f                   	pop    %edi
f01058aa:	5d                   	pop    %ebp
f01058ab:	c3                   	ret    
f01058ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01058b0:	8b 34 24             	mov    (%esp),%esi
f01058b3:	bf 20 00 00 00       	mov    $0x20,%edi
f01058b8:	89 e9                	mov    %ebp,%ecx
f01058ba:	29 ef                	sub    %ebp,%edi
f01058bc:	d3 e0                	shl    %cl,%eax
f01058be:	89 f9                	mov    %edi,%ecx
f01058c0:	89 f2                	mov    %esi,%edx
f01058c2:	d3 ea                	shr    %cl,%edx
f01058c4:	89 e9                	mov    %ebp,%ecx
f01058c6:	09 c2                	or     %eax,%edx
f01058c8:	89 d8                	mov    %ebx,%eax
f01058ca:	89 14 24             	mov    %edx,(%esp)
f01058cd:	89 f2                	mov    %esi,%edx
f01058cf:	d3 e2                	shl    %cl,%edx
f01058d1:	89 f9                	mov    %edi,%ecx
f01058d3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01058d7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01058db:	d3 e8                	shr    %cl,%eax
f01058dd:	89 e9                	mov    %ebp,%ecx
f01058df:	89 c6                	mov    %eax,%esi
f01058e1:	d3 e3                	shl    %cl,%ebx
f01058e3:	89 f9                	mov    %edi,%ecx
f01058e5:	89 d0                	mov    %edx,%eax
f01058e7:	d3 e8                	shr    %cl,%eax
f01058e9:	89 e9                	mov    %ebp,%ecx
f01058eb:	09 d8                	or     %ebx,%eax
f01058ed:	89 d3                	mov    %edx,%ebx
f01058ef:	89 f2                	mov    %esi,%edx
f01058f1:	f7 34 24             	divl   (%esp)
f01058f4:	89 d6                	mov    %edx,%esi
f01058f6:	d3 e3                	shl    %cl,%ebx
f01058f8:	f7 64 24 04          	mull   0x4(%esp)
f01058fc:	39 d6                	cmp    %edx,%esi
f01058fe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105902:	89 d1                	mov    %edx,%ecx
f0105904:	89 c3                	mov    %eax,%ebx
f0105906:	72 08                	jb     f0105910 <__umoddi3+0x110>
f0105908:	75 11                	jne    f010591b <__umoddi3+0x11b>
f010590a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010590e:	73 0b                	jae    f010591b <__umoddi3+0x11b>
f0105910:	2b 44 24 04          	sub    0x4(%esp),%eax
f0105914:	1b 14 24             	sbb    (%esp),%edx
f0105917:	89 d1                	mov    %edx,%ecx
f0105919:	89 c3                	mov    %eax,%ebx
f010591b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010591f:	29 da                	sub    %ebx,%edx
f0105921:	19 ce                	sbb    %ecx,%esi
f0105923:	89 f9                	mov    %edi,%ecx
f0105925:	89 f0                	mov    %esi,%eax
f0105927:	d3 e0                	shl    %cl,%eax
f0105929:	89 e9                	mov    %ebp,%ecx
f010592b:	d3 ea                	shr    %cl,%edx
f010592d:	89 e9                	mov    %ebp,%ecx
f010592f:	d3 ee                	shr    %cl,%esi
f0105931:	09 d0                	or     %edx,%eax
f0105933:	89 f2                	mov    %esi,%edx
f0105935:	83 c4 1c             	add    $0x1c,%esp
f0105938:	5b                   	pop    %ebx
f0105939:	5e                   	pop    %esi
f010593a:	5f                   	pop    %edi
f010593b:	5d                   	pop    %ebp
f010593c:	c3                   	ret    
f010593d:	8d 76 00             	lea    0x0(%esi),%esi
f0105940:	29 f9                	sub    %edi,%ecx
f0105942:	19 d6                	sbb    %edx,%esi
f0105944:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105948:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010594c:	e9 18 ff ff ff       	jmp    f0105869 <__umoddi3+0x69>


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
f010005c:	e8 29 52 00 00       	call   f010528a <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 20 59 10 f0       	push   $0xf0105920
f010006d:	e8 fc 35 00 00       	call   f010366e <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 cc 35 00 00       	call   f0103648 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 a9 5c 10 f0 	movl   $0xf0105ca9,(%esp)
f0100083:	e8 e6 35 00 00       	call   f010366e <cprintf>
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
f01000b3:	e8 b1 4b 00 00       	call   f0104c69 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 5c 05 00 00       	call   f0100619 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 8c 59 10 f0       	push   $0xf010598c
f01000ca:	e8 9f 35 00 00       	call   f010366e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 50 11 00 00       	call   f0101224 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 b2 2d 00 00       	call   f0102e8b <env_init>
	trap_init();
f01000d9:	e8 7e 36 00 00       	call   f010375c <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 9d 4e 00 00       	call   f0104f80 <mp_init>
	lapic_init();
f01000e3:	e8 bd 51 00 00       	call   f01052a5 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 a8 34 00 00       	call   f0103595 <pic_init>
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
f01000fe:	68 44 59 10 f0       	push   $0xf0105944
f0100103:	6a 53                	push   $0x53
f0100105:	68 a7 59 10 f0       	push   $0xf01059a7
f010010a:	e8 31 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010010f:	83 ec 04             	sub    $0x4,%esp
f0100112:	b8 e6 4e 10 f0       	mov    $0xf0104ee6,%eax
f0100117:	2d 6c 4e 10 f0       	sub    $0xf0104e6c,%eax
f010011c:	50                   	push   %eax
f010011d:	68 6c 4e 10 f0       	push   $0xf0104e6c
f0100122:	68 00 70 00 f0       	push   $0xf0007000
f0100127:	e8 8a 4b 00 00       	call   f0104cb6 <memmove>
f010012c:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010012f:	bb 20 b0 22 f0       	mov    $0xf022b020,%ebx
f0100134:	eb 4d                	jmp    f0100183 <i386_init+0xe9>
		if (c == cpus + cpunum())  // We've started already.
f0100136:	e8 4f 51 00 00       	call   f010528a <cpunum>
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
f0100170:	e8 7e 52 00 00       	call   f01053f3 <lapic_startap>
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
f010019d:	e8 b1 2e 00 00       	call   f0103053 <env_create>
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001a2:	e8 75 3e 00 00       	call   f010401c <sched_yield>

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
f01001ba:	68 68 59 10 f0       	push   $0xf0105968
f01001bf:	6a 6a                	push   $0x6a
f01001c1:	68 a7 59 10 f0       	push   $0xf01059a7
f01001c6:	e8 75 fe ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01001cb:	05 00 00 00 10       	add    $0x10000000,%eax
f01001d0:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001d3:	e8 b2 50 00 00       	call   f010528a <cpunum>
f01001d8:	83 ec 08             	sub    $0x8,%esp
f01001db:	50                   	push   %eax
f01001dc:	68 b3 59 10 f0       	push   $0xf01059b3
f01001e1:	e8 88 34 00 00       	call   f010366e <cprintf>

	lapic_init();
f01001e6:	e8 ba 50 00 00       	call   f01052a5 <lapic_init>
	env_init_percpu();
f01001eb:	e8 6b 2c 00 00       	call   f0102e5b <env_init_percpu>
	trap_init_percpu();
f01001f0:	e8 8d 34 00 00       	call   f0103682 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f01001f5:	e8 90 50 00 00       	call   f010528a <cpunum>
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
f0100221:	68 c9 59 10 f0       	push   $0xf01059c9
f0100226:	e8 43 34 00 00       	call   f010366e <cprintf>
	vcprintf(fmt, ap);
f010022b:	83 c4 08             	add    $0x8,%esp
f010022e:	53                   	push   %ebx
f010022f:	ff 75 10             	pushl  0x10(%ebp)
f0100232:	e8 11 34 00 00       	call   f0103648 <vcprintf>
	cprintf("\n");
f0100237:	c7 04 24 a9 5c 10 f0 	movl   $0xf0105ca9,(%esp)
f010023e:	e8 2b 34 00 00       	call   f010366e <cprintf>
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
f01002f5:	0f b6 82 40 5b 10 f0 	movzbl -0xfefa4c0(%edx),%eax
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
f0100331:	0f b6 82 40 5b 10 f0 	movzbl -0xfefa4c0(%edx),%eax
f0100338:	0b 05 00 a0 22 f0    	or     0xf022a000,%eax
f010033e:	0f b6 8a 40 5a 10 f0 	movzbl -0xfefa5c0(%edx),%ecx
f0100345:	31 c8                	xor    %ecx,%eax
f0100347:	a3 00 a0 22 f0       	mov    %eax,0xf022a000

	c = charcode[shift & (CTL | SHIFT)][data];
f010034c:	89 c1                	mov    %eax,%ecx
f010034e:	83 e1 03             	and    $0x3,%ecx
f0100351:	8b 0c 8d 20 5a 10 f0 	mov    -0xfefa5e0(,%ecx,4),%ecx
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
f010038f:	68 e3 59 10 f0       	push   $0xf01059e3
f0100394:	e8 d5 32 00 00       	call   f010366e <cprintf>
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
f010053d:	e8 74 47 00 00       	call   f0104cb6 <memmove>
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
f01006b1:	e8 67 2e 00 00       	call   f010351d <irq_setmask_8259A>
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
f0100729:	68 ef 59 10 f0       	push   $0xf01059ef
f010072e:	e8 3b 2f 00 00       	call   f010366e <cprintf>
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
f010076f:	68 40 5c 10 f0       	push   $0xf0105c40
f0100774:	68 5e 5c 10 f0       	push   $0xf0105c5e
f0100779:	68 63 5c 10 f0       	push   $0xf0105c63
f010077e:	e8 eb 2e 00 00       	call   f010366e <cprintf>
f0100783:	83 c4 0c             	add    $0xc,%esp
f0100786:	68 f8 5c 10 f0       	push   $0xf0105cf8
f010078b:	68 6c 5c 10 f0       	push   $0xf0105c6c
f0100790:	68 63 5c 10 f0       	push   $0xf0105c63
f0100795:	e8 d4 2e 00 00       	call   f010366e <cprintf>
f010079a:	83 c4 0c             	add    $0xc,%esp
f010079d:	68 20 5d 10 f0       	push   $0xf0105d20
f01007a2:	68 75 5c 10 f0       	push   $0xf0105c75
f01007a7:	68 63 5c 10 f0       	push   $0xf0105c63
f01007ac:	e8 bd 2e 00 00       	call   f010366e <cprintf>
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
f01007be:	68 7f 5c 10 f0       	push   $0xf0105c7f
f01007c3:	e8 a6 2e 00 00       	call   f010366e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007c8:	83 c4 08             	add    $0x8,%esp
f01007cb:	68 0c 00 10 00       	push   $0x10000c
f01007d0:	68 48 5d 10 f0       	push   $0xf0105d48
f01007d5:	e8 94 2e 00 00       	call   f010366e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007da:	83 c4 0c             	add    $0xc,%esp
f01007dd:	68 0c 00 10 00       	push   $0x10000c
f01007e2:	68 0c 00 10 f0       	push   $0xf010000c
f01007e7:	68 70 5d 10 f0       	push   $0xf0105d70
f01007ec:	e8 7d 2e 00 00       	call   f010366e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007f1:	83 c4 0c             	add    $0xc,%esp
f01007f4:	68 11 59 10 00       	push   $0x105911
f01007f9:	68 11 59 10 f0       	push   $0xf0105911
f01007fe:	68 94 5d 10 f0       	push   $0xf0105d94
f0100803:	e8 66 2e 00 00       	call   f010366e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100808:	83 c4 0c             	add    $0xc,%esp
f010080b:	68 98 95 22 00       	push   $0x229598
f0100810:	68 98 95 22 f0       	push   $0xf0229598
f0100815:	68 b8 5d 10 f0       	push   $0xf0105db8
f010081a:	e8 4f 2e 00 00       	call   f010366e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010081f:	83 c4 0c             	add    $0xc,%esp
f0100822:	68 08 c0 26 00       	push   $0x26c008
f0100827:	68 08 c0 26 f0       	push   $0xf026c008
f010082c:	68 dc 5d 10 f0       	push   $0xf0105ddc
f0100831:	e8 38 2e 00 00       	call   f010366e <cprintf>
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
f0100857:	68 00 5e 10 f0       	push   $0xf0105e00
f010085c:	e8 0d 2e 00 00       	call   f010366e <cprintf>
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
f0100873:	68 98 5c 10 f0       	push   $0xf0105c98
f0100878:	e8 f1 2d 00 00       	call   f010366e <cprintf>
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
f0100899:	68 2c 5e 10 f0       	push   $0xf0105e2c
f010089e:	e8 cb 2d 00 00       	call   f010366e <cprintf>
		debuginfo_eip((uintptr_t)eip, &info);
f01008a3:	83 c4 18             	add    $0x18,%esp
f01008a6:	57                   	push   %edi
f01008a7:	56                   	push   %esi
f01008a8:	e8 87 39 00 00       	call   f0104234 <debuginfo_eip>
		cprintf("%s:%d", info.eip_file, info.eip_line);
f01008ad:	83 c4 0c             	add    $0xc,%esp
f01008b0:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008b3:	ff 75 d0             	pushl  -0x30(%ebp)
f01008b6:	68 ab 5c 10 f0       	push   $0xf0105cab
f01008bb:	e8 ae 2d 00 00       	call   f010366e <cprintf>
		cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name, info.eip_fn_addr);
f01008c0:	ff 75 e0             	pushl  -0x20(%ebp)
f01008c3:	ff 75 d8             	pushl  -0x28(%ebp)
f01008c6:	ff 75 dc             	pushl  -0x24(%ebp)
f01008c9:	68 b1 5c 10 f0       	push   $0xf0105cb1
f01008ce:	e8 9b 2d 00 00       	call   f010366e <cprintf>
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
f01008f2:	68 64 5e 10 f0       	push   $0xf0105e64
f01008f7:	e8 72 2d 00 00       	call   f010366e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008fc:	c7 04 24 88 5e 10 f0 	movl   $0xf0105e88,(%esp)
f0100903:	e8 66 2d 00 00       	call   f010366e <cprintf>

	if (tf != NULL)
f0100908:	83 c4 10             	add    $0x10,%esp
f010090b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010090f:	74 0e                	je     f010091f <monitor+0x36>
		print_trapframe(tf);
f0100911:	83 ec 0c             	sub    $0xc,%esp
f0100914:	ff 75 08             	pushl  0x8(%ebp)
f0100917:	e8 8b 31 00 00       	call   f0103aa7 <print_trapframe>
f010091c:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f010091f:	83 ec 0c             	sub    $0xc,%esp
f0100922:	68 bc 5c 10 f0       	push   $0xf0105cbc
f0100927:	e8 e6 40 00 00       	call   f0104a12 <readline>
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
f010095b:	68 c0 5c 10 f0       	push   $0xf0105cc0
f0100960:	e8 c7 42 00 00       	call   f0104c2c <strchr>
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
f010097b:	68 c5 5c 10 f0       	push   $0xf0105cc5
f0100980:	e8 e9 2c 00 00       	call   f010366e <cprintf>
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
f01009a4:	68 c0 5c 10 f0       	push   $0xf0105cc0
f01009a9:	e8 7e 42 00 00       	call   f0104c2c <strchr>
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
f01009d2:	ff 34 85 c0 5e 10 f0 	pushl  -0xfefa140(,%eax,4)
f01009d9:	ff 75 a8             	pushl  -0x58(%ebp)
f01009dc:	e8 ed 41 00 00       	call   f0104bce <strcmp>
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
f01009f6:	ff 14 85 c8 5e 10 f0 	call   *-0xfefa138(,%eax,4)
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
f0100a17:	68 e2 5c 10 f0       	push   $0xf0105ce2
f0100a1c:	e8 4d 2c 00 00       	call   f010366e <cprintf>
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
f0100a90:	68 44 59 10 f0       	push   $0xf0105944
f0100a95:	68 da 03 00 00       	push   $0x3da
f0100a9a:	68 e1 67 10 f0       	push   $0xf01067e1
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
f0100ae8:	68 e4 5e 10 f0       	push   $0xf0105ee4
f0100aed:	68 0f 03 00 00       	push   $0x30f
f0100af2:	68 e1 67 10 f0       	push   $0xf01067e1
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
f0100b77:	68 44 59 10 f0       	push   $0xf0105944
f0100b7c:	6a 58                	push   $0x58
f0100b7e:	68 ed 67 10 f0       	push   $0xf01067ed
f0100b83:	e8 b8 f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b88:	83 ec 04             	sub    $0x4,%esp
f0100b8b:	68 80 00 00 00       	push   $0x80
f0100b90:	68 97 00 00 00       	push   $0x97
f0100b95:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b9a:	50                   	push   %eax
f0100b9b:	e8 c9 40 00 00       	call   f0104c69 <memset>
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
f0100be1:	68 fb 67 10 f0       	push   $0xf01067fb
f0100be6:	68 07 68 10 f0       	push   $0xf0106807
f0100beb:	68 29 03 00 00       	push   $0x329
f0100bf0:	68 e1 67 10 f0       	push   $0xf01067e1
f0100bf5:	e8 46 f4 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100bfa:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bfd:	72 19                	jb     f0100c18 <check_page_free_list+0x149>
f0100bff:	68 1c 68 10 f0       	push   $0xf010681c
f0100c04:	68 07 68 10 f0       	push   $0xf0106807
f0100c09:	68 2a 03 00 00       	push   $0x32a
f0100c0e:	68 e1 67 10 f0       	push   $0xf01067e1
f0100c13:	e8 28 f4 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c18:	89 d0                	mov    %edx,%eax
f0100c1a:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c1d:	a8 07                	test   $0x7,%al
f0100c1f:	74 19                	je     f0100c3a <check_page_free_list+0x16b>
f0100c21:	68 08 5f 10 f0       	push   $0xf0105f08
f0100c26:	68 07 68 10 f0       	push   $0xf0106807
f0100c2b:	68 2b 03 00 00       	push   $0x32b
f0100c30:	68 e1 67 10 f0       	push   $0xf01067e1
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
f0100c44:	68 30 68 10 f0       	push   $0xf0106830
f0100c49:	68 07 68 10 f0       	push   $0xf0106807
f0100c4e:	68 2e 03 00 00       	push   $0x32e
f0100c53:	68 e1 67 10 f0       	push   $0xf01067e1
f0100c58:	e8 e3 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c5d:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c62:	75 19                	jne    f0100c7d <check_page_free_list+0x1ae>
f0100c64:	68 41 68 10 f0       	push   $0xf0106841
f0100c69:	68 07 68 10 f0       	push   $0xf0106807
f0100c6e:	68 2f 03 00 00       	push   $0x32f
f0100c73:	68 e1 67 10 f0       	push   $0xf01067e1
f0100c78:	e8 c3 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c7d:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c82:	75 19                	jne    f0100c9d <check_page_free_list+0x1ce>
f0100c84:	68 3c 5f 10 f0       	push   $0xf0105f3c
f0100c89:	68 07 68 10 f0       	push   $0xf0106807
f0100c8e:	68 30 03 00 00       	push   $0x330
f0100c93:	68 e1 67 10 f0       	push   $0xf01067e1
f0100c98:	e8 a3 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c9d:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100ca2:	75 19                	jne    f0100cbd <check_page_free_list+0x1ee>
f0100ca4:	68 5a 68 10 f0       	push   $0xf010685a
f0100ca9:	68 07 68 10 f0       	push   $0xf0106807
f0100cae:	68 31 03 00 00       	push   $0x331
f0100cb3:	68 e1 67 10 f0       	push   $0xf01067e1
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
f0100cd3:	68 44 59 10 f0       	push   $0xf0105944
f0100cd8:	6a 58                	push   $0x58
f0100cda:	68 ed 67 10 f0       	push   $0xf01067ed
f0100cdf:	e8 5c f3 ff ff       	call   f0100040 <_panic>
f0100ce4:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100cea:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100ced:	0f 86 a7 00 00 00    	jbe    f0100d9a <check_page_free_list+0x2cb>
f0100cf3:	68 60 5f 10 f0       	push   $0xf0105f60
f0100cf8:	68 07 68 10 f0       	push   $0xf0106807
f0100cfd:	68 32 03 00 00       	push   $0x332
f0100d02:	68 e1 67 10 f0       	push   $0xf01067e1
f0100d07:	e8 34 f3 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d0c:	68 74 68 10 f0       	push   $0xf0106874
f0100d11:	68 07 68 10 f0       	push   $0xf0106807
f0100d16:	68 34 03 00 00       	push   $0x334
f0100d1b:	68 e1 67 10 f0       	push   $0xf01067e1
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
f0100d3b:	68 91 68 10 f0       	push   $0xf0106891
f0100d40:	68 07 68 10 f0       	push   $0xf0106807
f0100d45:	68 3c 03 00 00       	push   $0x33c
f0100d4a:	68 e1 67 10 f0       	push   $0xf01067e1
f0100d4f:	e8 ec f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100d54:	85 db                	test   %ebx,%ebx
f0100d56:	7f 5e                	jg     f0100db6 <check_page_free_list+0x2e7>
f0100d58:	68 a3 68 10 f0       	push   $0xf01068a3
f0100d5d:	68 07 68 10 f0       	push   $0xf0106807
f0100d62:	68 3d 03 00 00       	push   $0x33d
f0100d67:	68 e1 67 10 f0       	push   $0xf01067e1
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
f0100ec9:	74 5e                	je     f0100f29 <page_alloc+0x6f>
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
		//cprintf("page_alloc\r\n");
		if(alloc_flags & ALLOC_ZERO)
f0100ede:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ee2:	74 45                	je     f0100f29 <page_alloc+0x6f>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ee4:	89 d8                	mov    %ebx,%eax
f0100ee6:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100eec:	c1 f8 03             	sar    $0x3,%eax
f0100eef:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ef2:	89 c2                	mov    %eax,%edx
f0100ef4:	c1 ea 0c             	shr    $0xc,%edx
f0100ef7:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0100efd:	72 12                	jb     f0100f11 <page_alloc+0x57>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100eff:	50                   	push   %eax
f0100f00:	68 44 59 10 f0       	push   $0xf0105944
f0100f05:	6a 58                	push   $0x58
f0100f07:	68 ed 67 10 f0       	push   $0xf01067ed
f0100f0c:	e8 2f f1 ff ff       	call   f0100040 <_panic>
			memset(page2kva(Page),'\0',PGSIZE);
f0100f11:	83 ec 04             	sub    $0x4,%esp
f0100f14:	68 00 10 00 00       	push   $0x1000
f0100f19:	6a 00                	push   $0x0
f0100f1b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f20:	50                   	push   %eax
f0100f21:	e8 43 3d 00 00       	call   f0104c69 <memset>
f0100f26:	83 c4 10             	add    $0x10,%esp
			// memset(page2kva(page_free_list),0,PGSIZE);
		return Page;
	}
}
f0100f29:	89 d8                	mov    %ebx,%eax
f0100f2b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f2e:	c9                   	leave  
f0100f2f:	c3                   	ret    

f0100f30 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100f30:	55                   	push   %ebp
f0100f31:	89 e5                	mov    %esp,%ebp
f0100f33:	8b 45 08             	mov    0x8(%ebp),%eax
	//  	panic("can't free the page");
	//  	return;
	// }
	//	cprinf("can't free the page");
	//pp->pp_link = page_free_list->pp_link;	
	pp->pp_link = page_free_list;
f0100f36:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100f3c:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f3e:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
	//pp->pp_ref = 0;
	//cprintf("page_free\r\n");
}
f0100f43:	5d                   	pop    %ebp
f0100f44:	c3                   	ret    

f0100f45 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100f45:	55                   	push   %ebp
f0100f46:	89 e5                	mov    %esp,%ebp
f0100f48:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100f4b:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100f4f:	83 e8 01             	sub    $0x1,%eax
f0100f52:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100f56:	66 85 c0             	test   %ax,%ax
f0100f59:	75 09                	jne    f0100f64 <page_decref+0x1f>
		page_free(pp);
f0100f5b:	52                   	push   %edx
f0100f5c:	e8 cf ff ff ff       	call   f0100f30 <page_free>
f0100f61:	83 c4 04             	add    $0x4,%esp
}
f0100f64:	c9                   	leave  
f0100f65:	c3                   	ret    

f0100f66 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f66:	55                   	push   %ebp
f0100f67:	89 e5                	mov    %esp,%ebp
f0100f69:	56                   	push   %esi
f0100f6a:	53                   	push   %ebx
f0100f6b:	8b 45 0c             	mov    0xc(%ebp),%eax
	// Fill this function in
	uint32_t pd_number,pt_number,pt_addr;//,page_number,page_addr;
	pte_t *pte = NULL;
	struct PageInfo *Page;
	pd_number = PDX(va);
	pt_number = PTX(va);
f0100f6e:	89 c6                	mov    %eax,%esi
f0100f70:	c1 ee 0c             	shr    $0xc,%esi
f0100f73:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	if(pgdir[pd_number] & PTE_P)
f0100f79:	c1 e8 16             	shr    $0x16,%eax
f0100f7c:	8d 1c 85 00 00 00 00 	lea    0x0(,%eax,4),%ebx
f0100f83:	03 5d 08             	add    0x8(%ebp),%ebx
f0100f86:	8b 03                	mov    (%ebx),%eax
f0100f88:	a8 01                	test   $0x1,%al
f0100f8a:	74 2e                	je     f0100fba <pgdir_walk+0x54>
		pte = KADDR(PTE_ADDR(pgdir[pd_number]));
f0100f8c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f91:	89 c2                	mov    %eax,%edx
f0100f93:	c1 ea 0c             	shr    $0xc,%edx
f0100f96:	39 15 88 ae 22 f0    	cmp    %edx,0xf022ae88
f0100f9c:	77 15                	ja     f0100fb3 <pgdir_walk+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f9e:	50                   	push   %eax
f0100f9f:	68 44 59 10 f0       	push   $0xf0105944
f0100fa4:	68 c7 01 00 00       	push   $0x1c7
f0100fa9:	68 e1 67 10 f0       	push   $0xf01067e1
f0100fae:	e8 8d f0 ff ff       	call   f0100040 <_panic>
	if(!pte){
f0100fb3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fb8:	75 58                	jne    f0101012 <pgdir_walk+0xac>
		if(!create)
f0100fba:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100fbe:	74 57                	je     f0101017 <pgdir_walk+0xb1>
	 		return NULL;
	 	Page = page_alloc(create);
f0100fc0:	83 ec 0c             	sub    $0xc,%esp
f0100fc3:	ff 75 10             	pushl  0x10(%ebp)
f0100fc6:	e8 ef fe ff ff       	call   f0100eba <page_alloc>
		if(!Page)
f0100fcb:	83 c4 10             	add    $0x10,%esp
f0100fce:	85 c0                	test   %eax,%eax
f0100fd0:	74 4c                	je     f010101e <pgdir_walk+0xb8>
			return NULL;
		Page->pp_ref ++;
f0100fd2:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fd7:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0100fdd:	89 c2                	mov    %eax,%edx
f0100fdf:	c1 fa 03             	sar    $0x3,%edx
f0100fe2:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fe5:	89 d0                	mov    %edx,%eax
f0100fe7:	c1 e8 0c             	shr    $0xc,%eax
f0100fea:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0100ff0:	72 15                	jb     f0101007 <pgdir_walk+0xa1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ff2:	52                   	push   %edx
f0100ff3:	68 44 59 10 f0       	push   $0xf0105944
f0100ff8:	68 cf 01 00 00       	push   $0x1cf
f0100ffd:	68 e1 67 10 f0       	push   $0xf01067e1
f0101002:	e8 39 f0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101007:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	 	pte = KADDR(page2pa(Page));		
		// pgdir[pd_number] = page2pa(Page);
		pgdir[pd_number] = page2pa(Page) | PTE_P | PTE_W | PTE_U;
f010100d:	83 ca 07             	or     $0x7,%edx
f0101010:	89 13                	mov    %edx,(%ebx)
	}
	return &(pte[pt_number]);
f0101012:	8d 04 b0             	lea    (%eax,%esi,4),%eax
f0101015:	eb 0c                	jmp    f0101023 <pgdir_walk+0xbd>
	pt_number = PTX(va);
	if(pgdir[pd_number] & PTE_P)
		pte = KADDR(PTE_ADDR(pgdir[pd_number]));
	if(!pte){
		if(!create)
	 		return NULL;
f0101017:	b8 00 00 00 00       	mov    $0x0,%eax
f010101c:	eb 05                	jmp    f0101023 <pgdir_walk+0xbd>
	 	Page = page_alloc(create);
		if(!Page)
			return NULL;
f010101e:	b8 00 00 00 00       	mov    $0x0,%eax
	// //不确定page_alloc函数里应该填入的参数,page_alloc(int alloc_flags)
	// 	Page = page_alloc(create);
	// 	page_addr = page2pa(Page);
	// }
	// return page_addr;
}
f0101023:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101026:	5b                   	pop    %ebx
f0101027:	5e                   	pop    %esi
f0101028:	5d                   	pop    %ebp
f0101029:	c3                   	ret    

f010102a <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010102a:	55                   	push   %ebp
f010102b:	89 e5                	mov    %esp,%ebp
f010102d:	57                   	push   %edi
f010102e:	56                   	push   %esi
f010102f:	53                   	push   %ebx
f0101030:	83 ec 1c             	sub    $0x1c,%esp
f0101033:	89 c7                	mov    %eax,%edi
f0101035:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101038:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	pte_t *pte = NULL;
	//cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for(int i = 0;i < size;i += PGSIZE){
f010103b:	bb 00 00 00 00       	mov    $0x0,%ebx
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
f0101040:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101043:	83 c8 01             	or     $0x1,%eax
f0101046:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte = NULL;
	//cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for(int i = 0;i < size;i += PGSIZE){
f0101049:	eb 1f                	jmp    f010106a <boot_map_region+0x40>
		pte = pgdir_walk(pgdir, (void *)va, 1);
f010104b:	83 ec 04             	sub    $0x4,%esp
f010104e:	6a 01                	push   $0x1
f0101050:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101053:	01 d8                	add    %ebx,%eax
f0101055:	50                   	push   %eax
f0101056:	57                   	push   %edi
f0101057:	e8 0a ff ff ff       	call   f0100f66 <pgdir_walk>
		*pte = (pa | perm | PTE_P);
f010105c:	0b 75 dc             	or     -0x24(%ebp),%esi
f010105f:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte = NULL;
	//cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for(int i = 0;i < size;i += PGSIZE){
f0101061:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101067:	83 c4 10             	add    $0x10,%esp
f010106a:	89 de                	mov    %ebx,%esi
f010106c:	03 75 08             	add    0x8(%ebp),%esi
f010106f:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0101072:	77 d7                	ja     f010104b <boot_map_region+0x21>
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f0101074:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101077:	5b                   	pop    %ebx
f0101078:	5e                   	pop    %esi
f0101079:	5f                   	pop    %edi
f010107a:	5d                   	pop    %ebp
f010107b:	c3                   	ret    

f010107c <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010107c:	55                   	push   %ebp
f010107d:	89 e5                	mov    %esp,%ebp
f010107f:	53                   	push   %ebx
f0101080:	83 ec 08             	sub    $0x8,%esp
f0101083:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
f0101086:	6a 00                	push   $0x0
f0101088:	ff 75 0c             	pushl  0xc(%ebp)
f010108b:	ff 75 08             	pushl  0x8(%ebp)
f010108e:	e8 d3 fe ff ff       	call   f0100f66 <pgdir_walk>
	if(!pte)
f0101093:	83 c4 10             	add    $0x10,%esp
f0101096:	85 c0                	test   %eax,%eax
f0101098:	74 32                	je     f01010cc <page_lookup+0x50>
		return NULL;
	if(pte_store)
f010109a:	85 db                	test   %ebx,%ebx
f010109c:	74 02                	je     f01010a0 <page_lookup+0x24>
		*pte_store = pte;
f010109e:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010a0:	8b 00                	mov    (%eax),%eax
f01010a2:	c1 e8 0c             	shr    $0xc,%eax
f01010a5:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01010ab:	72 14                	jb     f01010c1 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f01010ad:	83 ec 04             	sub    $0x4,%esp
f01010b0:	68 a8 5f 10 f0       	push   $0xf0105fa8
f01010b5:	6a 51                	push   $0x51
f01010b7:	68 ed 67 10 f0       	push   $0xf01067ed
f01010bc:	e8 7f ef ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f01010c1:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f01010c7:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	return pa2page(PTE_ADDR(*pte));
f01010ca:	eb 05                	jmp    f01010d1 <page_lookup+0x55>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
	if(!pte)
		return NULL;
f01010cc:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f01010d1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010d4:	c9                   	leave  
f01010d5:	c3                   	ret    

f01010d6 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01010d6:	55                   	push   %ebp
f01010d7:	89 e5                	mov    %esp,%ebp
f01010d9:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f01010dc:	e8 a9 41 00 00       	call   f010528a <cpunum>
f01010e1:	6b c0 74             	imul   $0x74,%eax,%eax
f01010e4:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f01010eb:	74 16                	je     f0101103 <tlb_invalidate+0x2d>
f01010ed:	e8 98 41 00 00       	call   f010528a <cpunum>
f01010f2:	6b c0 74             	imul   $0x74,%eax,%eax
f01010f5:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01010fb:	8b 55 08             	mov    0x8(%ebp),%edx
f01010fe:	39 50 60             	cmp    %edx,0x60(%eax)
f0101101:	75 06                	jne    f0101109 <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101103:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101106:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0101109:	c9                   	leave  
f010110a:	c3                   	ret    

f010110b <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010110b:	55                   	push   %ebp
f010110c:	89 e5                	mov    %esp,%ebp
f010110e:	57                   	push   %edi
f010110f:	56                   	push   %esi
f0101110:	53                   	push   %ebx
f0101111:	83 ec 20             	sub    $0x20,%esp
f0101114:	8b 75 08             	mov    0x8(%ebp),%esi
f0101117:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pte_t *pte;
	// pte_t *pte,**pte_store;
	// pte = pgdir_walk(pgdir, (void *)va, 0);
	// pte_store = &pte;
	struct PageInfo *Page;
	Page = page_lookup(pgdir, va, &pte);
f010111a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010111d:	50                   	push   %eax
f010111e:	57                   	push   %edi
f010111f:	56                   	push   %esi
f0101120:	e8 57 ff ff ff       	call   f010107c <page_lookup>
	// Page = page_lookup(pgdir, va, pte_store);
	if(Page){
f0101125:	83 c4 10             	add    $0x10,%esp
f0101128:	85 c0                	test   %eax,%eax
f010112a:	74 20                	je     f010114c <page_remove+0x41>
f010112c:	89 c3                	mov    %eax,%ebx
		// Page->pp_ref --;
		tlb_invalidate(pgdir, va);
f010112e:	83 ec 08             	sub    $0x8,%esp
f0101131:	57                   	push   %edi
f0101132:	56                   	push   %esi
f0101133:	e8 9e ff ff ff       	call   f01010d6 <tlb_invalidate>
		page_decref(Page);
f0101138:	89 1c 24             	mov    %ebx,(%esp)
f010113b:	e8 05 fe ff ff       	call   f0100f45 <page_decref>
		*pte = 0;//将对应的页表项清空
f0101140:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101143:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101149:	83 c4 10             	add    $0x10,%esp
	}
}
f010114c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010114f:	5b                   	pop    %ebx
f0101150:	5e                   	pop    %esi
f0101151:	5f                   	pop    %edi
f0101152:	5d                   	pop    %ebp
f0101153:	c3                   	ret    

f0101154 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101154:	55                   	push   %ebp
f0101155:	89 e5                	mov    %esp,%ebp
f0101157:	57                   	push   %edi
f0101158:	56                   	push   %esi
f0101159:	53                   	push   %ebx
f010115a:	83 ec 10             	sub    $0x10,%esp
f010115d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101160:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
f0101163:	6a 01                	push   $0x1
f0101165:	57                   	push   %edi
f0101166:	ff 75 08             	pushl  0x8(%ebp)
f0101169:	e8 f8 fd ff ff       	call   f0100f66 <pgdir_walk>
	if(!pte)
f010116e:	83 c4 10             	add    $0x10,%esp
f0101171:	85 c0                	test   %eax,%eax
f0101173:	74 38                	je     f01011ad <page_insert+0x59>
f0101175:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	pp->pp_ref++;
f0101177:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	//删除旧映射关系 
    if((*pte) & PTE_P)
f010117c:	f6 00 01             	testb  $0x1,(%eax)
f010117f:	74 0f                	je     f0101190 <page_insert+0x3c>
        page_remove(pgdir, va);
f0101181:	83 ec 08             	sub    $0x8,%esp
f0101184:	57                   	push   %edi
f0101185:	ff 75 08             	pushl  0x8(%ebp)
f0101188:	e8 7e ff ff ff       	call   f010110b <page_remove>
f010118d:	83 c4 10             	add    $0x10,%esp
	//pp ->pp_ref++;
    *pte = page2pa(pp) | perm | PTE_P;
f0101190:	2b 1d 90 ae 22 f0    	sub    0xf022ae90,%ebx
f0101196:	c1 fb 03             	sar    $0x3,%ebx
f0101199:	c1 e3 0c             	shl    $0xc,%ebx
f010119c:	8b 45 14             	mov    0x14(%ebp),%eax
f010119f:	83 c8 01             	or     $0x1,%eax
f01011a2:	09 c3                	or     %eax,%ebx
f01011a4:	89 1e                	mov    %ebx,(%esi)
	return 0;
f01011a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01011ab:	eb 05                	jmp    f01011b2 <page_insert+0x5e>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
	if(!pte)
		return -E_NO_MEM;
f01011ad:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	// 		page_remove(pgdir, va); 
	// }
	// //pp->pp_ref++;
    // *pte = page2pa(pp) | perm | PTE_P;
	// return 0;
}
f01011b2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011b5:	5b                   	pop    %ebx
f01011b6:	5e                   	pop    %esi
f01011b7:	5f                   	pop    %edi
f01011b8:	5d                   	pop    %ebp
f01011b9:	c3                   	ret    

f01011ba <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01011ba:	55                   	push   %ebp
f01011bb:	89 e5                	mov    %esp,%ebp
f01011bd:	53                   	push   %ebx
f01011be:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	size = ROUNDUP(size, PGSIZE);
f01011c1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011c4:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f01011ca:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	pa = ROUNDDOWN(pa, PGSIZE);
f01011d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01011d3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	
	if(base + size > MMIOLIM)
f01011d8:	8b 15 00 f3 11 f0    	mov    0xf011f300,%edx
f01011de:	8d 0c 13             	lea    (%ebx,%edx,1),%ecx
f01011e1:	81 f9 00 00 c0 ef    	cmp    $0xefc00000,%ecx
f01011e7:	76 17                	jbe    f0101200 <mmio_map_region+0x46>
		panic("MMIOLIM is not enough");
f01011e9:	83 ec 04             	sub    $0x4,%esp
f01011ec:	68 b4 68 10 f0       	push   $0xf01068b4
f01011f1:	68 b5 02 00 00       	push   $0x2b5
f01011f6:	68 e1 67 10 f0       	push   $0xf01067e1
f01011fb:	e8 40 ee ff ff       	call   f0100040 <_panic>

	boot_map_region(kern_pgdir, base, size, pa, PTE_PCD | PTE_PWT | PTE_W | PTE_P);
f0101200:	83 ec 08             	sub    $0x8,%esp
f0101203:	6a 1b                	push   $0x1b
f0101205:	50                   	push   %eax
f0101206:	89 d9                	mov    %ebx,%ecx
f0101208:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f010120d:	e8 18 fe ff ff       	call   f010102a <boot_map_region>
	base += size;//每次映射到不同的页面
f0101212:	a1 00 f3 11 f0       	mov    0xf011f300,%eax
f0101217:	01 c3                	add    %eax,%ebx
f0101219:	89 1d 00 f3 11 f0    	mov    %ebx,0xf011f300
	return (void *)(base-size);
	//panic("mmio_map_region not implemented");
}
f010121f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101222:	c9                   	leave  
f0101223:	c3                   	ret    

f0101224 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101224:	55                   	push   %ebp
f0101225:	89 e5                	mov    %esp,%ebp
f0101227:	57                   	push   %edi
f0101228:	56                   	push   %esi
f0101229:	53                   	push   %ebx
f010122a:	83 ec 48             	sub    $0x48,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010122d:	6a 15                	push   $0x15
f010122f:	e8 bb 22 00 00       	call   f01034ef <mc146818_read>
f0101234:	89 c3                	mov    %eax,%ebx
f0101236:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010123d:	e8 ad 22 00 00       	call   f01034ef <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101242:	c1 e0 08             	shl    $0x8,%eax
f0101245:	09 d8                	or     %ebx,%eax
f0101247:	c1 e0 0a             	shl    $0xa,%eax
f010124a:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101250:	85 c0                	test   %eax,%eax
f0101252:	0f 48 c2             	cmovs  %edx,%eax
f0101255:	c1 f8 0c             	sar    $0xc,%eax
f0101258:	a3 44 a2 22 f0       	mov    %eax,0xf022a244
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010125d:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101264:	e8 86 22 00 00       	call   f01034ef <mc146818_read>
f0101269:	89 c3                	mov    %eax,%ebx
f010126b:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101272:	e8 78 22 00 00       	call   f01034ef <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101277:	c1 e0 08             	shl    $0x8,%eax
f010127a:	09 d8                	or     %ebx,%eax
f010127c:	c1 e0 0a             	shl    $0xa,%eax
f010127f:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101285:	83 c4 10             	add    $0x10,%esp
f0101288:	85 c0                	test   %eax,%eax
f010128a:	0f 48 c2             	cmovs  %edx,%eax
f010128d:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101290:	85 c0                	test   %eax,%eax
f0101292:	74 0e                	je     f01012a2 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101294:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010129a:	89 15 88 ae 22 f0    	mov    %edx,0xf022ae88
f01012a0:	eb 0c                	jmp    f01012ae <mem_init+0x8a>
	else
		npages = npages_basemem;
f01012a2:	8b 15 44 a2 22 f0    	mov    0xf022a244,%edx
f01012a8:	89 15 88 ae 22 f0    	mov    %edx,0xf022ae88

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012ae:	c1 e0 0c             	shl    $0xc,%eax
f01012b1:	c1 e8 0a             	shr    $0xa,%eax
f01012b4:	50                   	push   %eax
f01012b5:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
f01012ba:	c1 e0 0c             	shl    $0xc,%eax
f01012bd:	c1 e8 0a             	shr    $0xa,%eax
f01012c0:	50                   	push   %eax
f01012c1:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f01012c6:	c1 e0 0c             	shl    $0xc,%eax
f01012c9:	c1 e8 0a             	shr    $0xa,%eax
f01012cc:	50                   	push   %eax
f01012cd:	68 c8 5f 10 f0       	push   $0xf0105fc8
f01012d2:	e8 97 23 00 00       	call   f010366e <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01012d7:	b8 00 10 00 00       	mov    $0x1000,%eax
f01012dc:	e8 50 f7 ff ff       	call   f0100a31 <boot_alloc>
f01012e1:	a3 8c ae 22 f0       	mov    %eax,0xf022ae8c
	memset(kern_pgdir, 0, PGSIZE);
f01012e6:	83 c4 0c             	add    $0xc,%esp
f01012e9:	68 00 10 00 00       	push   $0x1000
f01012ee:	6a 00                	push   $0x0
f01012f0:	50                   	push   %eax
f01012f1:	e8 73 39 00 00       	call   f0104c69 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01012f6:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01012fb:	83 c4 10             	add    $0x10,%esp
f01012fe:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101303:	77 15                	ja     f010131a <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101305:	50                   	push   %eax
f0101306:	68 68 59 10 f0       	push   $0xf0105968
f010130b:	68 90 00 00 00       	push   $0x90
f0101310:	68 e1 67 10 f0       	push   $0xf01067e1
f0101315:	e8 26 ed ff ff       	call   f0100040 <_panic>
f010131a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101320:	83 ca 05             	or     $0x5,%edx
f0101323:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f0101329:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f010132e:	c1 e0 03             	shl    $0x3,%eax
f0101331:	e8 fb f6 ff ff       	call   f0100a31 <boot_alloc>
f0101336:	a3 90 ae 22 f0       	mov    %eax,0xf022ae90
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010133b:	83 ec 04             	sub    $0x4,%esp
f010133e:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f0101344:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f010134b:	52                   	push   %edx
f010134c:	6a 00                	push   $0x0
f010134e:	50                   	push   %eax
f010134f:	e8 15 39 00 00       	call   f0104c69 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*)boot_alloc(NENV * sizeof(struct Env));
f0101354:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101359:	e8 d3 f6 ff ff       	call   f0100a31 <boot_alloc>
f010135e:	a3 48 a2 22 f0       	mov    %eax,0xf022a248
	memset(envs, 0, NENV * sizeof(struct Env));
f0101363:	83 c4 0c             	add    $0xc,%esp
f0101366:	68 00 f0 01 00       	push   $0x1f000
f010136b:	6a 00                	push   $0x0
f010136d:	50                   	push   %eax
f010136e:	e8 f6 38 00 00       	call   f0104c69 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101373:	e8 46 fa ff ff       	call   f0100dbe <page_init>

	check_page_free_list(1);
f0101378:	b8 01 00 00 00       	mov    $0x1,%eax
f010137d:	e8 4d f7 ff ff       	call   f0100acf <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101382:	83 c4 10             	add    $0x10,%esp
f0101385:	83 3d 90 ae 22 f0 00 	cmpl   $0x0,0xf022ae90
f010138c:	75 17                	jne    f01013a5 <mem_init+0x181>
		panic("'pages' is a null pointer!");
f010138e:	83 ec 04             	sub    $0x4,%esp
f0101391:	68 ca 68 10 f0       	push   $0xf01068ca
f0101396:	68 4e 03 00 00       	push   $0x34e
f010139b:	68 e1 67 10 f0       	push   $0xf01067e1
f01013a0:	e8 9b ec ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013a5:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f01013aa:	bb 00 00 00 00       	mov    $0x0,%ebx
f01013af:	eb 05                	jmp    f01013b6 <mem_init+0x192>
		++nfree;
f01013b1:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013b4:	8b 00                	mov    (%eax),%eax
f01013b6:	85 c0                	test   %eax,%eax
f01013b8:	75 f7                	jne    f01013b1 <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013ba:	83 ec 0c             	sub    $0xc,%esp
f01013bd:	6a 00                	push   $0x0
f01013bf:	e8 f6 fa ff ff       	call   f0100eba <page_alloc>
f01013c4:	89 c7                	mov    %eax,%edi
f01013c6:	83 c4 10             	add    $0x10,%esp
f01013c9:	85 c0                	test   %eax,%eax
f01013cb:	75 19                	jne    f01013e6 <mem_init+0x1c2>
f01013cd:	68 e5 68 10 f0       	push   $0xf01068e5
f01013d2:	68 07 68 10 f0       	push   $0xf0106807
f01013d7:	68 56 03 00 00       	push   $0x356
f01013dc:	68 e1 67 10 f0       	push   $0xf01067e1
f01013e1:	e8 5a ec ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01013e6:	83 ec 0c             	sub    $0xc,%esp
f01013e9:	6a 00                	push   $0x0
f01013eb:	e8 ca fa ff ff       	call   f0100eba <page_alloc>
f01013f0:	89 c6                	mov    %eax,%esi
f01013f2:	83 c4 10             	add    $0x10,%esp
f01013f5:	85 c0                	test   %eax,%eax
f01013f7:	75 19                	jne    f0101412 <mem_init+0x1ee>
f01013f9:	68 fb 68 10 f0       	push   $0xf01068fb
f01013fe:	68 07 68 10 f0       	push   $0xf0106807
f0101403:	68 57 03 00 00       	push   $0x357
f0101408:	68 e1 67 10 f0       	push   $0xf01067e1
f010140d:	e8 2e ec ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101412:	83 ec 0c             	sub    $0xc,%esp
f0101415:	6a 00                	push   $0x0
f0101417:	e8 9e fa ff ff       	call   f0100eba <page_alloc>
f010141c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010141f:	83 c4 10             	add    $0x10,%esp
f0101422:	85 c0                	test   %eax,%eax
f0101424:	75 19                	jne    f010143f <mem_init+0x21b>
f0101426:	68 11 69 10 f0       	push   $0xf0106911
f010142b:	68 07 68 10 f0       	push   $0xf0106807
f0101430:	68 58 03 00 00       	push   $0x358
f0101435:	68 e1 67 10 f0       	push   $0xf01067e1
f010143a:	e8 01 ec ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010143f:	39 f7                	cmp    %esi,%edi
f0101441:	75 19                	jne    f010145c <mem_init+0x238>
f0101443:	68 27 69 10 f0       	push   $0xf0106927
f0101448:	68 07 68 10 f0       	push   $0xf0106807
f010144d:	68 5b 03 00 00       	push   $0x35b
f0101452:	68 e1 67 10 f0       	push   $0xf01067e1
f0101457:	e8 e4 eb ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010145c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010145f:	39 c6                	cmp    %eax,%esi
f0101461:	74 04                	je     f0101467 <mem_init+0x243>
f0101463:	39 c7                	cmp    %eax,%edi
f0101465:	75 19                	jne    f0101480 <mem_init+0x25c>
f0101467:	68 04 60 10 f0       	push   $0xf0106004
f010146c:	68 07 68 10 f0       	push   $0xf0106807
f0101471:	68 5c 03 00 00       	push   $0x35c
f0101476:	68 e1 67 10 f0       	push   $0xf01067e1
f010147b:	e8 c0 eb ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101480:	8b 0d 90 ae 22 f0    	mov    0xf022ae90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101486:	8b 15 88 ae 22 f0    	mov    0xf022ae88,%edx
f010148c:	c1 e2 0c             	shl    $0xc,%edx
f010148f:	89 f8                	mov    %edi,%eax
f0101491:	29 c8                	sub    %ecx,%eax
f0101493:	c1 f8 03             	sar    $0x3,%eax
f0101496:	c1 e0 0c             	shl    $0xc,%eax
f0101499:	39 d0                	cmp    %edx,%eax
f010149b:	72 19                	jb     f01014b6 <mem_init+0x292>
f010149d:	68 39 69 10 f0       	push   $0xf0106939
f01014a2:	68 07 68 10 f0       	push   $0xf0106807
f01014a7:	68 5d 03 00 00       	push   $0x35d
f01014ac:	68 e1 67 10 f0       	push   $0xf01067e1
f01014b1:	e8 8a eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01014b6:	89 f0                	mov    %esi,%eax
f01014b8:	29 c8                	sub    %ecx,%eax
f01014ba:	c1 f8 03             	sar    $0x3,%eax
f01014bd:	c1 e0 0c             	shl    $0xc,%eax
f01014c0:	39 c2                	cmp    %eax,%edx
f01014c2:	77 19                	ja     f01014dd <mem_init+0x2b9>
f01014c4:	68 56 69 10 f0       	push   $0xf0106956
f01014c9:	68 07 68 10 f0       	push   $0xf0106807
f01014ce:	68 5e 03 00 00       	push   $0x35e
f01014d3:	68 e1 67 10 f0       	push   $0xf01067e1
f01014d8:	e8 63 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01014dd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014e0:	29 c8                	sub    %ecx,%eax
f01014e2:	c1 f8 03             	sar    $0x3,%eax
f01014e5:	c1 e0 0c             	shl    $0xc,%eax
f01014e8:	39 c2                	cmp    %eax,%edx
f01014ea:	77 19                	ja     f0101505 <mem_init+0x2e1>
f01014ec:	68 73 69 10 f0       	push   $0xf0106973
f01014f1:	68 07 68 10 f0       	push   $0xf0106807
f01014f6:	68 5f 03 00 00       	push   $0x35f
f01014fb:	68 e1 67 10 f0       	push   $0xf01067e1
f0101500:	e8 3b eb ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101505:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f010150a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010150d:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f0101514:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101517:	83 ec 0c             	sub    $0xc,%esp
f010151a:	6a 00                	push   $0x0
f010151c:	e8 99 f9 ff ff       	call   f0100eba <page_alloc>
f0101521:	83 c4 10             	add    $0x10,%esp
f0101524:	85 c0                	test   %eax,%eax
f0101526:	74 19                	je     f0101541 <mem_init+0x31d>
f0101528:	68 90 69 10 f0       	push   $0xf0106990
f010152d:	68 07 68 10 f0       	push   $0xf0106807
f0101532:	68 66 03 00 00       	push   $0x366
f0101537:	68 e1 67 10 f0       	push   $0xf01067e1
f010153c:	e8 ff ea ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101541:	83 ec 0c             	sub    $0xc,%esp
f0101544:	57                   	push   %edi
f0101545:	e8 e6 f9 ff ff       	call   f0100f30 <page_free>
	page_free(pp1);
f010154a:	89 34 24             	mov    %esi,(%esp)
f010154d:	e8 de f9 ff ff       	call   f0100f30 <page_free>
	page_free(pp2);
f0101552:	83 c4 04             	add    $0x4,%esp
f0101555:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101558:	e8 d3 f9 ff ff       	call   f0100f30 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010155d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101564:	e8 51 f9 ff ff       	call   f0100eba <page_alloc>
f0101569:	89 c6                	mov    %eax,%esi
f010156b:	83 c4 10             	add    $0x10,%esp
f010156e:	85 c0                	test   %eax,%eax
f0101570:	75 19                	jne    f010158b <mem_init+0x367>
f0101572:	68 e5 68 10 f0       	push   $0xf01068e5
f0101577:	68 07 68 10 f0       	push   $0xf0106807
f010157c:	68 6d 03 00 00       	push   $0x36d
f0101581:	68 e1 67 10 f0       	push   $0xf01067e1
f0101586:	e8 b5 ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010158b:	83 ec 0c             	sub    $0xc,%esp
f010158e:	6a 00                	push   $0x0
f0101590:	e8 25 f9 ff ff       	call   f0100eba <page_alloc>
f0101595:	89 c7                	mov    %eax,%edi
f0101597:	83 c4 10             	add    $0x10,%esp
f010159a:	85 c0                	test   %eax,%eax
f010159c:	75 19                	jne    f01015b7 <mem_init+0x393>
f010159e:	68 fb 68 10 f0       	push   $0xf01068fb
f01015a3:	68 07 68 10 f0       	push   $0xf0106807
f01015a8:	68 6e 03 00 00       	push   $0x36e
f01015ad:	68 e1 67 10 f0       	push   $0xf01067e1
f01015b2:	e8 89 ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01015b7:	83 ec 0c             	sub    $0xc,%esp
f01015ba:	6a 00                	push   $0x0
f01015bc:	e8 f9 f8 ff ff       	call   f0100eba <page_alloc>
f01015c1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015c4:	83 c4 10             	add    $0x10,%esp
f01015c7:	85 c0                	test   %eax,%eax
f01015c9:	75 19                	jne    f01015e4 <mem_init+0x3c0>
f01015cb:	68 11 69 10 f0       	push   $0xf0106911
f01015d0:	68 07 68 10 f0       	push   $0xf0106807
f01015d5:	68 6f 03 00 00       	push   $0x36f
f01015da:	68 e1 67 10 f0       	push   $0xf01067e1
f01015df:	e8 5c ea ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015e4:	39 fe                	cmp    %edi,%esi
f01015e6:	75 19                	jne    f0101601 <mem_init+0x3dd>
f01015e8:	68 27 69 10 f0       	push   $0xf0106927
f01015ed:	68 07 68 10 f0       	push   $0xf0106807
f01015f2:	68 71 03 00 00       	push   $0x371
f01015f7:	68 e1 67 10 f0       	push   $0xf01067e1
f01015fc:	e8 3f ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101601:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101604:	39 c7                	cmp    %eax,%edi
f0101606:	74 04                	je     f010160c <mem_init+0x3e8>
f0101608:	39 c6                	cmp    %eax,%esi
f010160a:	75 19                	jne    f0101625 <mem_init+0x401>
f010160c:	68 04 60 10 f0       	push   $0xf0106004
f0101611:	68 07 68 10 f0       	push   $0xf0106807
f0101616:	68 72 03 00 00       	push   $0x372
f010161b:	68 e1 67 10 f0       	push   $0xf01067e1
f0101620:	e8 1b ea ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101625:	83 ec 0c             	sub    $0xc,%esp
f0101628:	6a 00                	push   $0x0
f010162a:	e8 8b f8 ff ff       	call   f0100eba <page_alloc>
f010162f:	83 c4 10             	add    $0x10,%esp
f0101632:	85 c0                	test   %eax,%eax
f0101634:	74 19                	je     f010164f <mem_init+0x42b>
f0101636:	68 90 69 10 f0       	push   $0xf0106990
f010163b:	68 07 68 10 f0       	push   $0xf0106807
f0101640:	68 73 03 00 00       	push   $0x373
f0101645:	68 e1 67 10 f0       	push   $0xf01067e1
f010164a:	e8 f1 e9 ff ff       	call   f0100040 <_panic>
f010164f:	89 f0                	mov    %esi,%eax
f0101651:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0101657:	c1 f8 03             	sar    $0x3,%eax
f010165a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010165d:	89 c2                	mov    %eax,%edx
f010165f:	c1 ea 0c             	shr    $0xc,%edx
f0101662:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0101668:	72 12                	jb     f010167c <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010166a:	50                   	push   %eax
f010166b:	68 44 59 10 f0       	push   $0xf0105944
f0101670:	6a 58                	push   $0x58
f0101672:	68 ed 67 10 f0       	push   $0xf01067ed
f0101677:	e8 c4 e9 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010167c:	83 ec 04             	sub    $0x4,%esp
f010167f:	68 00 10 00 00       	push   $0x1000
f0101684:	6a 01                	push   $0x1
f0101686:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010168b:	50                   	push   %eax
f010168c:	e8 d8 35 00 00       	call   f0104c69 <memset>
	page_free(pp0);
f0101691:	89 34 24             	mov    %esi,(%esp)
f0101694:	e8 97 f8 ff ff       	call   f0100f30 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101699:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016a0:	e8 15 f8 ff ff       	call   f0100eba <page_alloc>
f01016a5:	83 c4 10             	add    $0x10,%esp
f01016a8:	85 c0                	test   %eax,%eax
f01016aa:	75 19                	jne    f01016c5 <mem_init+0x4a1>
f01016ac:	68 9f 69 10 f0       	push   $0xf010699f
f01016b1:	68 07 68 10 f0       	push   $0xf0106807
f01016b6:	68 78 03 00 00       	push   $0x378
f01016bb:	68 e1 67 10 f0       	push   $0xf01067e1
f01016c0:	e8 7b e9 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01016c5:	39 c6                	cmp    %eax,%esi
f01016c7:	74 19                	je     f01016e2 <mem_init+0x4be>
f01016c9:	68 bd 69 10 f0       	push   $0xf01069bd
f01016ce:	68 07 68 10 f0       	push   $0xf0106807
f01016d3:	68 79 03 00 00       	push   $0x379
f01016d8:	68 e1 67 10 f0       	push   $0xf01067e1
f01016dd:	e8 5e e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016e2:	89 f0                	mov    %esi,%eax
f01016e4:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01016ea:	c1 f8 03             	sar    $0x3,%eax
f01016ed:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016f0:	89 c2                	mov    %eax,%edx
f01016f2:	c1 ea 0c             	shr    $0xc,%edx
f01016f5:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f01016fb:	72 12                	jb     f010170f <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016fd:	50                   	push   %eax
f01016fe:	68 44 59 10 f0       	push   $0xf0105944
f0101703:	6a 58                	push   $0x58
f0101705:	68 ed 67 10 f0       	push   $0xf01067ed
f010170a:	e8 31 e9 ff ff       	call   f0100040 <_panic>
f010170f:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101715:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010171b:	80 38 00             	cmpb   $0x0,(%eax)
f010171e:	74 19                	je     f0101739 <mem_init+0x515>
f0101720:	68 cd 69 10 f0       	push   $0xf01069cd
f0101725:	68 07 68 10 f0       	push   $0xf0106807
f010172a:	68 7c 03 00 00       	push   $0x37c
f010172f:	68 e1 67 10 f0       	push   $0xf01067e1
f0101734:	e8 07 e9 ff ff       	call   f0100040 <_panic>
f0101739:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010173c:	39 d0                	cmp    %edx,%eax
f010173e:	75 db                	jne    f010171b <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101740:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101743:	a3 40 a2 22 f0       	mov    %eax,0xf022a240

	// free the pages we took
	page_free(pp0);
f0101748:	83 ec 0c             	sub    $0xc,%esp
f010174b:	56                   	push   %esi
f010174c:	e8 df f7 ff ff       	call   f0100f30 <page_free>
	page_free(pp1);
f0101751:	89 3c 24             	mov    %edi,(%esp)
f0101754:	e8 d7 f7 ff ff       	call   f0100f30 <page_free>
	page_free(pp2);
f0101759:	83 c4 04             	add    $0x4,%esp
f010175c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010175f:	e8 cc f7 ff ff       	call   f0100f30 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101764:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0101769:	83 c4 10             	add    $0x10,%esp
f010176c:	eb 05                	jmp    f0101773 <mem_init+0x54f>
		--nfree;
f010176e:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101771:	8b 00                	mov    (%eax),%eax
f0101773:	85 c0                	test   %eax,%eax
f0101775:	75 f7                	jne    f010176e <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f0101777:	85 db                	test   %ebx,%ebx
f0101779:	74 19                	je     f0101794 <mem_init+0x570>
f010177b:	68 d7 69 10 f0       	push   $0xf01069d7
f0101780:	68 07 68 10 f0       	push   $0xf0106807
f0101785:	68 89 03 00 00       	push   $0x389
f010178a:	68 e1 67 10 f0       	push   $0xf01067e1
f010178f:	e8 ac e8 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101794:	83 ec 0c             	sub    $0xc,%esp
f0101797:	68 24 60 10 f0       	push   $0xf0106024
f010179c:	e8 cd 1e 00 00       	call   f010366e <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017a1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017a8:	e8 0d f7 ff ff       	call   f0100eba <page_alloc>
f01017ad:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017b0:	83 c4 10             	add    $0x10,%esp
f01017b3:	85 c0                	test   %eax,%eax
f01017b5:	75 19                	jne    f01017d0 <mem_init+0x5ac>
f01017b7:	68 e5 68 10 f0       	push   $0xf01068e5
f01017bc:	68 07 68 10 f0       	push   $0xf0106807
f01017c1:	68 ef 03 00 00       	push   $0x3ef
f01017c6:	68 e1 67 10 f0       	push   $0xf01067e1
f01017cb:	e8 70 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01017d0:	83 ec 0c             	sub    $0xc,%esp
f01017d3:	6a 00                	push   $0x0
f01017d5:	e8 e0 f6 ff ff       	call   f0100eba <page_alloc>
f01017da:	89 c3                	mov    %eax,%ebx
f01017dc:	83 c4 10             	add    $0x10,%esp
f01017df:	85 c0                	test   %eax,%eax
f01017e1:	75 19                	jne    f01017fc <mem_init+0x5d8>
f01017e3:	68 fb 68 10 f0       	push   $0xf01068fb
f01017e8:	68 07 68 10 f0       	push   $0xf0106807
f01017ed:	68 f0 03 00 00       	push   $0x3f0
f01017f2:	68 e1 67 10 f0       	push   $0xf01067e1
f01017f7:	e8 44 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01017fc:	83 ec 0c             	sub    $0xc,%esp
f01017ff:	6a 00                	push   $0x0
f0101801:	e8 b4 f6 ff ff       	call   f0100eba <page_alloc>
f0101806:	89 c6                	mov    %eax,%esi
f0101808:	83 c4 10             	add    $0x10,%esp
f010180b:	85 c0                	test   %eax,%eax
f010180d:	75 19                	jne    f0101828 <mem_init+0x604>
f010180f:	68 11 69 10 f0       	push   $0xf0106911
f0101814:	68 07 68 10 f0       	push   $0xf0106807
f0101819:	68 f1 03 00 00       	push   $0x3f1
f010181e:	68 e1 67 10 f0       	push   $0xf01067e1
f0101823:	e8 18 e8 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101828:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010182b:	75 19                	jne    f0101846 <mem_init+0x622>
f010182d:	68 27 69 10 f0       	push   $0xf0106927
f0101832:	68 07 68 10 f0       	push   $0xf0106807
f0101837:	68 f4 03 00 00       	push   $0x3f4
f010183c:	68 e1 67 10 f0       	push   $0xf01067e1
f0101841:	e8 fa e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101846:	39 c3                	cmp    %eax,%ebx
f0101848:	74 05                	je     f010184f <mem_init+0x62b>
f010184a:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010184d:	75 19                	jne    f0101868 <mem_init+0x644>
f010184f:	68 04 60 10 f0       	push   $0xf0106004
f0101854:	68 07 68 10 f0       	push   $0xf0106807
f0101859:	68 f5 03 00 00       	push   $0x3f5
f010185e:	68 e1 67 10 f0       	push   $0xf01067e1
f0101863:	e8 d8 e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101868:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f010186d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101870:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f0101877:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010187a:	83 ec 0c             	sub    $0xc,%esp
f010187d:	6a 00                	push   $0x0
f010187f:	e8 36 f6 ff ff       	call   f0100eba <page_alloc>
f0101884:	83 c4 10             	add    $0x10,%esp
f0101887:	85 c0                	test   %eax,%eax
f0101889:	74 19                	je     f01018a4 <mem_init+0x680>
f010188b:	68 90 69 10 f0       	push   $0xf0106990
f0101890:	68 07 68 10 f0       	push   $0xf0106807
f0101895:	68 fc 03 00 00       	push   $0x3fc
f010189a:	68 e1 67 10 f0       	push   $0xf01067e1
f010189f:	e8 9c e7 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01018a4:	83 ec 04             	sub    $0x4,%esp
f01018a7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01018aa:	50                   	push   %eax
f01018ab:	6a 00                	push   $0x0
f01018ad:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01018b3:	e8 c4 f7 ff ff       	call   f010107c <page_lookup>
f01018b8:	83 c4 10             	add    $0x10,%esp
f01018bb:	85 c0                	test   %eax,%eax
f01018bd:	74 19                	je     f01018d8 <mem_init+0x6b4>
f01018bf:	68 44 60 10 f0       	push   $0xf0106044
f01018c4:	68 07 68 10 f0       	push   $0xf0106807
f01018c9:	68 ff 03 00 00       	push   $0x3ff
f01018ce:	68 e1 67 10 f0       	push   $0xf01067e1
f01018d3:	e8 68 e7 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01018d8:	6a 02                	push   $0x2
f01018da:	6a 00                	push   $0x0
f01018dc:	53                   	push   %ebx
f01018dd:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01018e3:	e8 6c f8 ff ff       	call   f0101154 <page_insert>
f01018e8:	83 c4 10             	add    $0x10,%esp
f01018eb:	85 c0                	test   %eax,%eax
f01018ed:	78 19                	js     f0101908 <mem_init+0x6e4>
f01018ef:	68 7c 60 10 f0       	push   $0xf010607c
f01018f4:	68 07 68 10 f0       	push   $0xf0106807
f01018f9:	68 02 04 00 00       	push   $0x402
f01018fe:	68 e1 67 10 f0       	push   $0xf01067e1
f0101903:	e8 38 e7 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101908:	83 ec 0c             	sub    $0xc,%esp
f010190b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010190e:	e8 1d f6 ff ff       	call   f0100f30 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101913:	6a 02                	push   $0x2
f0101915:	6a 00                	push   $0x0
f0101917:	53                   	push   %ebx
f0101918:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f010191e:	e8 31 f8 ff ff       	call   f0101154 <page_insert>
f0101923:	83 c4 20             	add    $0x20,%esp
f0101926:	85 c0                	test   %eax,%eax
f0101928:	74 19                	je     f0101943 <mem_init+0x71f>
f010192a:	68 ac 60 10 f0       	push   $0xf01060ac
f010192f:	68 07 68 10 f0       	push   $0xf0106807
f0101934:	68 06 04 00 00       	push   $0x406
f0101939:	68 e1 67 10 f0       	push   $0xf01067e1
f010193e:	e8 fd e6 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101943:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101949:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f010194e:	89 c1                	mov    %eax,%ecx
f0101950:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101953:	8b 17                	mov    (%edi),%edx
f0101955:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010195b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010195e:	29 c8                	sub    %ecx,%eax
f0101960:	c1 f8 03             	sar    $0x3,%eax
f0101963:	c1 e0 0c             	shl    $0xc,%eax
f0101966:	39 c2                	cmp    %eax,%edx
f0101968:	74 19                	je     f0101983 <mem_init+0x75f>
f010196a:	68 dc 60 10 f0       	push   $0xf01060dc
f010196f:	68 07 68 10 f0       	push   $0xf0106807
f0101974:	68 07 04 00 00       	push   $0x407
f0101979:	68 e1 67 10 f0       	push   $0xf01067e1
f010197e:	e8 bd e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101983:	ba 00 00 00 00       	mov    $0x0,%edx
f0101988:	89 f8                	mov    %edi,%eax
f010198a:	e8 dc f0 ff ff       	call   f0100a6b <check_va2pa>
f010198f:	89 da                	mov    %ebx,%edx
f0101991:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101994:	c1 fa 03             	sar    $0x3,%edx
f0101997:	c1 e2 0c             	shl    $0xc,%edx
f010199a:	39 d0                	cmp    %edx,%eax
f010199c:	74 19                	je     f01019b7 <mem_init+0x793>
f010199e:	68 04 61 10 f0       	push   $0xf0106104
f01019a3:	68 07 68 10 f0       	push   $0xf0106807
f01019a8:	68 08 04 00 00       	push   $0x408
f01019ad:	68 e1 67 10 f0       	push   $0xf01067e1
f01019b2:	e8 89 e6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01019b7:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01019bc:	74 19                	je     f01019d7 <mem_init+0x7b3>
f01019be:	68 e2 69 10 f0       	push   $0xf01069e2
f01019c3:	68 07 68 10 f0       	push   $0xf0106807
f01019c8:	68 09 04 00 00       	push   $0x409
f01019cd:	68 e1 67 10 f0       	push   $0xf01067e1
f01019d2:	e8 69 e6 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f01019d7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019da:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01019df:	74 19                	je     f01019fa <mem_init+0x7d6>
f01019e1:	68 f3 69 10 f0       	push   $0xf01069f3
f01019e6:	68 07 68 10 f0       	push   $0xf0106807
f01019eb:	68 0a 04 00 00       	push   $0x40a
f01019f0:	68 e1 67 10 f0       	push   $0xf01067e1
f01019f5:	e8 46 e6 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01019fa:	6a 02                	push   $0x2
f01019fc:	68 00 10 00 00       	push   $0x1000
f0101a01:	56                   	push   %esi
f0101a02:	57                   	push   %edi
f0101a03:	e8 4c f7 ff ff       	call   f0101154 <page_insert>
f0101a08:	83 c4 10             	add    $0x10,%esp
f0101a0b:	85 c0                	test   %eax,%eax
f0101a0d:	74 19                	je     f0101a28 <mem_init+0x804>
f0101a0f:	68 34 61 10 f0       	push   $0xf0106134
f0101a14:	68 07 68 10 f0       	push   $0xf0106807
f0101a19:	68 0d 04 00 00       	push   $0x40d
f0101a1e:	68 e1 67 10 f0       	push   $0xf01067e1
f0101a23:	e8 18 e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a28:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a2d:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101a32:	e8 34 f0 ff ff       	call   f0100a6b <check_va2pa>
f0101a37:	89 f2                	mov    %esi,%edx
f0101a39:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101a3f:	c1 fa 03             	sar    $0x3,%edx
f0101a42:	c1 e2 0c             	shl    $0xc,%edx
f0101a45:	39 d0                	cmp    %edx,%eax
f0101a47:	74 19                	je     f0101a62 <mem_init+0x83e>
f0101a49:	68 70 61 10 f0       	push   $0xf0106170
f0101a4e:	68 07 68 10 f0       	push   $0xf0106807
f0101a53:	68 0e 04 00 00       	push   $0x40e
f0101a58:	68 e1 67 10 f0       	push   $0xf01067e1
f0101a5d:	e8 de e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101a62:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a67:	74 19                	je     f0101a82 <mem_init+0x85e>
f0101a69:	68 04 6a 10 f0       	push   $0xf0106a04
f0101a6e:	68 07 68 10 f0       	push   $0xf0106807
f0101a73:	68 0f 04 00 00       	push   $0x40f
f0101a78:	68 e1 67 10 f0       	push   $0xf01067e1
f0101a7d:	e8 be e5 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101a82:	83 ec 0c             	sub    $0xc,%esp
f0101a85:	6a 00                	push   $0x0
f0101a87:	e8 2e f4 ff ff       	call   f0100eba <page_alloc>
f0101a8c:	83 c4 10             	add    $0x10,%esp
f0101a8f:	85 c0                	test   %eax,%eax
f0101a91:	74 19                	je     f0101aac <mem_init+0x888>
f0101a93:	68 90 69 10 f0       	push   $0xf0106990
f0101a98:	68 07 68 10 f0       	push   $0xf0106807
f0101a9d:	68 12 04 00 00       	push   $0x412
f0101aa2:	68 e1 67 10 f0       	push   $0xf01067e1
f0101aa7:	e8 94 e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101aac:	6a 02                	push   $0x2
f0101aae:	68 00 10 00 00       	push   $0x1000
f0101ab3:	56                   	push   %esi
f0101ab4:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101aba:	e8 95 f6 ff ff       	call   f0101154 <page_insert>
f0101abf:	83 c4 10             	add    $0x10,%esp
f0101ac2:	85 c0                	test   %eax,%eax
f0101ac4:	74 19                	je     f0101adf <mem_init+0x8bb>
f0101ac6:	68 34 61 10 f0       	push   $0xf0106134
f0101acb:	68 07 68 10 f0       	push   $0xf0106807
f0101ad0:	68 15 04 00 00       	push   $0x415
f0101ad5:	68 e1 67 10 f0       	push   $0xf01067e1
f0101ada:	e8 61 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101adf:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ae4:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101ae9:	e8 7d ef ff ff       	call   f0100a6b <check_va2pa>
f0101aee:	89 f2                	mov    %esi,%edx
f0101af0:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101af6:	c1 fa 03             	sar    $0x3,%edx
f0101af9:	c1 e2 0c             	shl    $0xc,%edx
f0101afc:	39 d0                	cmp    %edx,%eax
f0101afe:	74 19                	je     f0101b19 <mem_init+0x8f5>
f0101b00:	68 70 61 10 f0       	push   $0xf0106170
f0101b05:	68 07 68 10 f0       	push   $0xf0106807
f0101b0a:	68 16 04 00 00       	push   $0x416
f0101b0f:	68 e1 67 10 f0       	push   $0xf01067e1
f0101b14:	e8 27 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b19:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b1e:	74 19                	je     f0101b39 <mem_init+0x915>
f0101b20:	68 04 6a 10 f0       	push   $0xf0106a04
f0101b25:	68 07 68 10 f0       	push   $0xf0106807
f0101b2a:	68 17 04 00 00       	push   $0x417
f0101b2f:	68 e1 67 10 f0       	push   $0xf01067e1
f0101b34:	e8 07 e5 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b39:	83 ec 0c             	sub    $0xc,%esp
f0101b3c:	6a 00                	push   $0x0
f0101b3e:	e8 77 f3 ff ff       	call   f0100eba <page_alloc>
f0101b43:	83 c4 10             	add    $0x10,%esp
f0101b46:	85 c0                	test   %eax,%eax
f0101b48:	74 19                	je     f0101b63 <mem_init+0x93f>
f0101b4a:	68 90 69 10 f0       	push   $0xf0106990
f0101b4f:	68 07 68 10 f0       	push   $0xf0106807
f0101b54:	68 1b 04 00 00       	push   $0x41b
f0101b59:	68 e1 67 10 f0       	push   $0xf01067e1
f0101b5e:	e8 dd e4 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b63:	8b 15 8c ae 22 f0    	mov    0xf022ae8c,%edx
f0101b69:	8b 02                	mov    (%edx),%eax
f0101b6b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b70:	89 c1                	mov    %eax,%ecx
f0101b72:	c1 e9 0c             	shr    $0xc,%ecx
f0101b75:	3b 0d 88 ae 22 f0    	cmp    0xf022ae88,%ecx
f0101b7b:	72 15                	jb     f0101b92 <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b7d:	50                   	push   %eax
f0101b7e:	68 44 59 10 f0       	push   $0xf0105944
f0101b83:	68 1e 04 00 00       	push   $0x41e
f0101b88:	68 e1 67 10 f0       	push   $0xf01067e1
f0101b8d:	e8 ae e4 ff ff       	call   f0100040 <_panic>
f0101b92:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101b97:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101b9a:	83 ec 04             	sub    $0x4,%esp
f0101b9d:	6a 00                	push   $0x0
f0101b9f:	68 00 10 00 00       	push   $0x1000
f0101ba4:	52                   	push   %edx
f0101ba5:	e8 bc f3 ff ff       	call   f0100f66 <pgdir_walk>
f0101baa:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101bad:	8d 51 04             	lea    0x4(%ecx),%edx
f0101bb0:	83 c4 10             	add    $0x10,%esp
f0101bb3:	39 d0                	cmp    %edx,%eax
f0101bb5:	74 19                	je     f0101bd0 <mem_init+0x9ac>
f0101bb7:	68 a0 61 10 f0       	push   $0xf01061a0
f0101bbc:	68 07 68 10 f0       	push   $0xf0106807
f0101bc1:	68 1f 04 00 00       	push   $0x41f
f0101bc6:	68 e1 67 10 f0       	push   $0xf01067e1
f0101bcb:	e8 70 e4 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101bd0:	6a 06                	push   $0x6
f0101bd2:	68 00 10 00 00       	push   $0x1000
f0101bd7:	56                   	push   %esi
f0101bd8:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101bde:	e8 71 f5 ff ff       	call   f0101154 <page_insert>
f0101be3:	83 c4 10             	add    $0x10,%esp
f0101be6:	85 c0                	test   %eax,%eax
f0101be8:	74 19                	je     f0101c03 <mem_init+0x9df>
f0101bea:	68 e0 61 10 f0       	push   $0xf01061e0
f0101bef:	68 07 68 10 f0       	push   $0xf0106807
f0101bf4:	68 22 04 00 00       	push   $0x422
f0101bf9:	68 e1 67 10 f0       	push   $0xf01067e1
f0101bfe:	e8 3d e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c03:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101c09:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c0e:	89 f8                	mov    %edi,%eax
f0101c10:	e8 56 ee ff ff       	call   f0100a6b <check_va2pa>
f0101c15:	89 f2                	mov    %esi,%edx
f0101c17:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101c1d:	c1 fa 03             	sar    $0x3,%edx
f0101c20:	c1 e2 0c             	shl    $0xc,%edx
f0101c23:	39 d0                	cmp    %edx,%eax
f0101c25:	74 19                	je     f0101c40 <mem_init+0xa1c>
f0101c27:	68 70 61 10 f0       	push   $0xf0106170
f0101c2c:	68 07 68 10 f0       	push   $0xf0106807
f0101c31:	68 23 04 00 00       	push   $0x423
f0101c36:	68 e1 67 10 f0       	push   $0xf01067e1
f0101c3b:	e8 00 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101c40:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c45:	74 19                	je     f0101c60 <mem_init+0xa3c>
f0101c47:	68 04 6a 10 f0       	push   $0xf0106a04
f0101c4c:	68 07 68 10 f0       	push   $0xf0106807
f0101c51:	68 24 04 00 00       	push   $0x424
f0101c56:	68 e1 67 10 f0       	push   $0xf01067e1
f0101c5b:	e8 e0 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c60:	83 ec 04             	sub    $0x4,%esp
f0101c63:	6a 00                	push   $0x0
f0101c65:	68 00 10 00 00       	push   $0x1000
f0101c6a:	57                   	push   %edi
f0101c6b:	e8 f6 f2 ff ff       	call   f0100f66 <pgdir_walk>
f0101c70:	83 c4 10             	add    $0x10,%esp
f0101c73:	f6 00 04             	testb  $0x4,(%eax)
f0101c76:	75 19                	jne    f0101c91 <mem_init+0xa6d>
f0101c78:	68 20 62 10 f0       	push   $0xf0106220
f0101c7d:	68 07 68 10 f0       	push   $0xf0106807
f0101c82:	68 25 04 00 00       	push   $0x425
f0101c87:	68 e1 67 10 f0       	push   $0xf01067e1
f0101c8c:	e8 af e3 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101c91:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0101c96:	f6 00 04             	testb  $0x4,(%eax)
f0101c99:	75 19                	jne    f0101cb4 <mem_init+0xa90>
f0101c9b:	68 15 6a 10 f0       	push   $0xf0106a15
f0101ca0:	68 07 68 10 f0       	push   $0xf0106807
f0101ca5:	68 26 04 00 00       	push   $0x426
f0101caa:	68 e1 67 10 f0       	push   $0xf01067e1
f0101caf:	e8 8c e3 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101cb4:	6a 02                	push   $0x2
f0101cb6:	68 00 10 00 00       	push   $0x1000
f0101cbb:	56                   	push   %esi
f0101cbc:	50                   	push   %eax
f0101cbd:	e8 92 f4 ff ff       	call   f0101154 <page_insert>
f0101cc2:	83 c4 10             	add    $0x10,%esp
f0101cc5:	85 c0                	test   %eax,%eax
f0101cc7:	74 19                	je     f0101ce2 <mem_init+0xabe>
f0101cc9:	68 34 61 10 f0       	push   $0xf0106134
f0101cce:	68 07 68 10 f0       	push   $0xf0106807
f0101cd3:	68 29 04 00 00       	push   $0x429
f0101cd8:	68 e1 67 10 f0       	push   $0xf01067e1
f0101cdd:	e8 5e e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ce2:	83 ec 04             	sub    $0x4,%esp
f0101ce5:	6a 00                	push   $0x0
f0101ce7:	68 00 10 00 00       	push   $0x1000
f0101cec:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101cf2:	e8 6f f2 ff ff       	call   f0100f66 <pgdir_walk>
f0101cf7:	83 c4 10             	add    $0x10,%esp
f0101cfa:	f6 00 02             	testb  $0x2,(%eax)
f0101cfd:	75 19                	jne    f0101d18 <mem_init+0xaf4>
f0101cff:	68 54 62 10 f0       	push   $0xf0106254
f0101d04:	68 07 68 10 f0       	push   $0xf0106807
f0101d09:	68 2a 04 00 00       	push   $0x42a
f0101d0e:	68 e1 67 10 f0       	push   $0xf01067e1
f0101d13:	e8 28 e3 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d18:	83 ec 04             	sub    $0x4,%esp
f0101d1b:	6a 00                	push   $0x0
f0101d1d:	68 00 10 00 00       	push   $0x1000
f0101d22:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d28:	e8 39 f2 ff ff       	call   f0100f66 <pgdir_walk>
f0101d2d:	83 c4 10             	add    $0x10,%esp
f0101d30:	f6 00 04             	testb  $0x4,(%eax)
f0101d33:	74 19                	je     f0101d4e <mem_init+0xb2a>
f0101d35:	68 88 62 10 f0       	push   $0xf0106288
f0101d3a:	68 07 68 10 f0       	push   $0xf0106807
f0101d3f:	68 2b 04 00 00       	push   $0x42b
f0101d44:	68 e1 67 10 f0       	push   $0xf01067e1
f0101d49:	e8 f2 e2 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d4e:	6a 02                	push   $0x2
f0101d50:	68 00 00 40 00       	push   $0x400000
f0101d55:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101d58:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d5e:	e8 f1 f3 ff ff       	call   f0101154 <page_insert>
f0101d63:	83 c4 10             	add    $0x10,%esp
f0101d66:	85 c0                	test   %eax,%eax
f0101d68:	78 19                	js     f0101d83 <mem_init+0xb5f>
f0101d6a:	68 c0 62 10 f0       	push   $0xf01062c0
f0101d6f:	68 07 68 10 f0       	push   $0xf0106807
f0101d74:	68 2e 04 00 00       	push   $0x42e
f0101d79:	68 e1 67 10 f0       	push   $0xf01067e1
f0101d7e:	e8 bd e2 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d83:	6a 02                	push   $0x2
f0101d85:	68 00 10 00 00       	push   $0x1000
f0101d8a:	53                   	push   %ebx
f0101d8b:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101d91:	e8 be f3 ff ff       	call   f0101154 <page_insert>
f0101d96:	83 c4 10             	add    $0x10,%esp
f0101d99:	85 c0                	test   %eax,%eax
f0101d9b:	74 19                	je     f0101db6 <mem_init+0xb92>
f0101d9d:	68 f8 62 10 f0       	push   $0xf01062f8
f0101da2:	68 07 68 10 f0       	push   $0xf0106807
f0101da7:	68 31 04 00 00       	push   $0x431
f0101dac:	68 e1 67 10 f0       	push   $0xf01067e1
f0101db1:	e8 8a e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101db6:	83 ec 04             	sub    $0x4,%esp
f0101db9:	6a 00                	push   $0x0
f0101dbb:	68 00 10 00 00       	push   $0x1000
f0101dc0:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101dc6:	e8 9b f1 ff ff       	call   f0100f66 <pgdir_walk>
f0101dcb:	83 c4 10             	add    $0x10,%esp
f0101dce:	f6 00 04             	testb  $0x4,(%eax)
f0101dd1:	74 19                	je     f0101dec <mem_init+0xbc8>
f0101dd3:	68 88 62 10 f0       	push   $0xf0106288
f0101dd8:	68 07 68 10 f0       	push   $0xf0106807
f0101ddd:	68 32 04 00 00       	push   $0x432
f0101de2:	68 e1 67 10 f0       	push   $0xf01067e1
f0101de7:	e8 54 e2 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101dec:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101df2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101df7:	89 f8                	mov    %edi,%eax
f0101df9:	e8 6d ec ff ff       	call   f0100a6b <check_va2pa>
f0101dfe:	89 c1                	mov    %eax,%ecx
f0101e00:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e03:	89 d8                	mov    %ebx,%eax
f0101e05:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0101e0b:	c1 f8 03             	sar    $0x3,%eax
f0101e0e:	c1 e0 0c             	shl    $0xc,%eax
f0101e11:	39 c1                	cmp    %eax,%ecx
f0101e13:	74 19                	je     f0101e2e <mem_init+0xc0a>
f0101e15:	68 34 63 10 f0       	push   $0xf0106334
f0101e1a:	68 07 68 10 f0       	push   $0xf0106807
f0101e1f:	68 35 04 00 00       	push   $0x435
f0101e24:	68 e1 67 10 f0       	push   $0xf01067e1
f0101e29:	e8 12 e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e2e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e33:	89 f8                	mov    %edi,%eax
f0101e35:	e8 31 ec ff ff       	call   f0100a6b <check_va2pa>
f0101e3a:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101e3d:	74 19                	je     f0101e58 <mem_init+0xc34>
f0101e3f:	68 60 63 10 f0       	push   $0xf0106360
f0101e44:	68 07 68 10 f0       	push   $0xf0106807
f0101e49:	68 36 04 00 00       	push   $0x436
f0101e4e:	68 e1 67 10 f0       	push   $0xf01067e1
f0101e53:	e8 e8 e1 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e58:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101e5d:	74 19                	je     f0101e78 <mem_init+0xc54>
f0101e5f:	68 2b 6a 10 f0       	push   $0xf0106a2b
f0101e64:	68 07 68 10 f0       	push   $0xf0106807
f0101e69:	68 38 04 00 00       	push   $0x438
f0101e6e:	68 e1 67 10 f0       	push   $0xf01067e1
f0101e73:	e8 c8 e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101e78:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e7d:	74 19                	je     f0101e98 <mem_init+0xc74>
f0101e7f:	68 3c 6a 10 f0       	push   $0xf0106a3c
f0101e84:	68 07 68 10 f0       	push   $0xf0106807
f0101e89:	68 39 04 00 00       	push   $0x439
f0101e8e:	68 e1 67 10 f0       	push   $0xf01067e1
f0101e93:	e8 a8 e1 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e98:	83 ec 0c             	sub    $0xc,%esp
f0101e9b:	6a 00                	push   $0x0
f0101e9d:	e8 18 f0 ff ff       	call   f0100eba <page_alloc>
f0101ea2:	83 c4 10             	add    $0x10,%esp
f0101ea5:	85 c0                	test   %eax,%eax
f0101ea7:	74 04                	je     f0101ead <mem_init+0xc89>
f0101ea9:	39 c6                	cmp    %eax,%esi
f0101eab:	74 19                	je     f0101ec6 <mem_init+0xca2>
f0101ead:	68 90 63 10 f0       	push   $0xf0106390
f0101eb2:	68 07 68 10 f0       	push   $0xf0106807
f0101eb7:	68 3c 04 00 00       	push   $0x43c
f0101ebc:	68 e1 67 10 f0       	push   $0xf01067e1
f0101ec1:	e8 7a e1 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ec6:	83 ec 08             	sub    $0x8,%esp
f0101ec9:	6a 00                	push   $0x0
f0101ecb:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101ed1:	e8 35 f2 ff ff       	call   f010110b <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101ed6:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0101edc:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ee1:	89 f8                	mov    %edi,%eax
f0101ee3:	e8 83 eb ff ff       	call   f0100a6b <check_va2pa>
f0101ee8:	83 c4 10             	add    $0x10,%esp
f0101eeb:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101eee:	74 19                	je     f0101f09 <mem_init+0xce5>
f0101ef0:	68 b4 63 10 f0       	push   $0xf01063b4
f0101ef5:	68 07 68 10 f0       	push   $0xf0106807
f0101efa:	68 40 04 00 00       	push   $0x440
f0101eff:	68 e1 67 10 f0       	push   $0xf01067e1
f0101f04:	e8 37 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f09:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f0e:	89 f8                	mov    %edi,%eax
f0101f10:	e8 56 eb ff ff       	call   f0100a6b <check_va2pa>
f0101f15:	89 da                	mov    %ebx,%edx
f0101f17:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0101f1d:	c1 fa 03             	sar    $0x3,%edx
f0101f20:	c1 e2 0c             	shl    $0xc,%edx
f0101f23:	39 d0                	cmp    %edx,%eax
f0101f25:	74 19                	je     f0101f40 <mem_init+0xd1c>
f0101f27:	68 60 63 10 f0       	push   $0xf0106360
f0101f2c:	68 07 68 10 f0       	push   $0xf0106807
f0101f31:	68 41 04 00 00       	push   $0x441
f0101f36:	68 e1 67 10 f0       	push   $0xf01067e1
f0101f3b:	e8 00 e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101f40:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101f45:	74 19                	je     f0101f60 <mem_init+0xd3c>
f0101f47:	68 e2 69 10 f0       	push   $0xf01069e2
f0101f4c:	68 07 68 10 f0       	push   $0xf0106807
f0101f51:	68 42 04 00 00       	push   $0x442
f0101f56:	68 e1 67 10 f0       	push   $0xf01067e1
f0101f5b:	e8 e0 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101f60:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f65:	74 19                	je     f0101f80 <mem_init+0xd5c>
f0101f67:	68 3c 6a 10 f0       	push   $0xf0106a3c
f0101f6c:	68 07 68 10 f0       	push   $0xf0106807
f0101f71:	68 43 04 00 00       	push   $0x443
f0101f76:	68 e1 67 10 f0       	push   $0xf01067e1
f0101f7b:	e8 c0 e0 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101f80:	6a 00                	push   $0x0
f0101f82:	68 00 10 00 00       	push   $0x1000
f0101f87:	53                   	push   %ebx
f0101f88:	57                   	push   %edi
f0101f89:	e8 c6 f1 ff ff       	call   f0101154 <page_insert>
f0101f8e:	83 c4 10             	add    $0x10,%esp
f0101f91:	85 c0                	test   %eax,%eax
f0101f93:	74 19                	je     f0101fae <mem_init+0xd8a>
f0101f95:	68 d8 63 10 f0       	push   $0xf01063d8
f0101f9a:	68 07 68 10 f0       	push   $0xf0106807
f0101f9f:	68 46 04 00 00       	push   $0x446
f0101fa4:	68 e1 67 10 f0       	push   $0xf01067e1
f0101fa9:	e8 92 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0101fae:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101fb3:	75 19                	jne    f0101fce <mem_init+0xdaa>
f0101fb5:	68 4d 6a 10 f0       	push   $0xf0106a4d
f0101fba:	68 07 68 10 f0       	push   $0xf0106807
f0101fbf:	68 47 04 00 00       	push   $0x447
f0101fc4:	68 e1 67 10 f0       	push   $0xf01067e1
f0101fc9:	e8 72 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0101fce:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101fd1:	74 19                	je     f0101fec <mem_init+0xdc8>
f0101fd3:	68 59 6a 10 f0       	push   $0xf0106a59
f0101fd8:	68 07 68 10 f0       	push   $0xf0106807
f0101fdd:	68 48 04 00 00       	push   $0x448
f0101fe2:	68 e1 67 10 f0       	push   $0xf01067e1
f0101fe7:	e8 54 e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101fec:	83 ec 08             	sub    $0x8,%esp
f0101fef:	68 00 10 00 00       	push   $0x1000
f0101ff4:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0101ffa:	e8 0c f1 ff ff       	call   f010110b <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101fff:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f0102005:	ba 00 00 00 00       	mov    $0x0,%edx
f010200a:	89 f8                	mov    %edi,%eax
f010200c:	e8 5a ea ff ff       	call   f0100a6b <check_va2pa>
f0102011:	83 c4 10             	add    $0x10,%esp
f0102014:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102017:	74 19                	je     f0102032 <mem_init+0xe0e>
f0102019:	68 b4 63 10 f0       	push   $0xf01063b4
f010201e:	68 07 68 10 f0       	push   $0xf0106807
f0102023:	68 4c 04 00 00       	push   $0x44c
f0102028:	68 e1 67 10 f0       	push   $0xf01067e1
f010202d:	e8 0e e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102032:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102037:	89 f8                	mov    %edi,%eax
f0102039:	e8 2d ea ff ff       	call   f0100a6b <check_va2pa>
f010203e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102041:	74 19                	je     f010205c <mem_init+0xe38>
f0102043:	68 10 64 10 f0       	push   $0xf0106410
f0102048:	68 07 68 10 f0       	push   $0xf0106807
f010204d:	68 4d 04 00 00       	push   $0x44d
f0102052:	68 e1 67 10 f0       	push   $0xf01067e1
f0102057:	e8 e4 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f010205c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102061:	74 19                	je     f010207c <mem_init+0xe58>
f0102063:	68 6e 6a 10 f0       	push   $0xf0106a6e
f0102068:	68 07 68 10 f0       	push   $0xf0106807
f010206d:	68 4e 04 00 00       	push   $0x44e
f0102072:	68 e1 67 10 f0       	push   $0xf01067e1
f0102077:	e8 c4 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010207c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102081:	74 19                	je     f010209c <mem_init+0xe78>
f0102083:	68 3c 6a 10 f0       	push   $0xf0106a3c
f0102088:	68 07 68 10 f0       	push   $0xf0106807
f010208d:	68 4f 04 00 00       	push   $0x44f
f0102092:	68 e1 67 10 f0       	push   $0xf01067e1
f0102097:	e8 a4 df ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010209c:	83 ec 0c             	sub    $0xc,%esp
f010209f:	6a 00                	push   $0x0
f01020a1:	e8 14 ee ff ff       	call   f0100eba <page_alloc>
f01020a6:	83 c4 10             	add    $0x10,%esp
f01020a9:	39 c3                	cmp    %eax,%ebx
f01020ab:	75 04                	jne    f01020b1 <mem_init+0xe8d>
f01020ad:	85 c0                	test   %eax,%eax
f01020af:	75 19                	jne    f01020ca <mem_init+0xea6>
f01020b1:	68 38 64 10 f0       	push   $0xf0106438
f01020b6:	68 07 68 10 f0       	push   $0xf0106807
f01020bb:	68 52 04 00 00       	push   $0x452
f01020c0:	68 e1 67 10 f0       	push   $0xf01067e1
f01020c5:	e8 76 df ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01020ca:	83 ec 0c             	sub    $0xc,%esp
f01020cd:	6a 00                	push   $0x0
f01020cf:	e8 e6 ed ff ff       	call   f0100eba <page_alloc>
f01020d4:	83 c4 10             	add    $0x10,%esp
f01020d7:	85 c0                	test   %eax,%eax
f01020d9:	74 19                	je     f01020f4 <mem_init+0xed0>
f01020db:	68 90 69 10 f0       	push   $0xf0106990
f01020e0:	68 07 68 10 f0       	push   $0xf0106807
f01020e5:	68 55 04 00 00       	push   $0x455
f01020ea:	68 e1 67 10 f0       	push   $0xf01067e1
f01020ef:	e8 4c df ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01020f4:	8b 0d 8c ae 22 f0    	mov    0xf022ae8c,%ecx
f01020fa:	8b 11                	mov    (%ecx),%edx
f01020fc:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102102:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102105:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f010210b:	c1 f8 03             	sar    $0x3,%eax
f010210e:	c1 e0 0c             	shl    $0xc,%eax
f0102111:	39 c2                	cmp    %eax,%edx
f0102113:	74 19                	je     f010212e <mem_init+0xf0a>
f0102115:	68 dc 60 10 f0       	push   $0xf01060dc
f010211a:	68 07 68 10 f0       	push   $0xf0106807
f010211f:	68 58 04 00 00       	push   $0x458
f0102124:	68 e1 67 10 f0       	push   $0xf01067e1
f0102129:	e8 12 df ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010212e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102134:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102137:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010213c:	74 19                	je     f0102157 <mem_init+0xf33>
f010213e:	68 f3 69 10 f0       	push   $0xf01069f3
f0102143:	68 07 68 10 f0       	push   $0xf0106807
f0102148:	68 5a 04 00 00       	push   $0x45a
f010214d:	68 e1 67 10 f0       	push   $0xf01067e1
f0102152:	e8 e9 de ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102157:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010215a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102160:	83 ec 0c             	sub    $0xc,%esp
f0102163:	50                   	push   %eax
f0102164:	e8 c7 ed ff ff       	call   f0100f30 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102169:	83 c4 0c             	add    $0xc,%esp
f010216c:	6a 01                	push   $0x1
f010216e:	68 00 10 40 00       	push   $0x401000
f0102173:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102179:	e8 e8 ed ff ff       	call   f0100f66 <pgdir_walk>
f010217e:	89 c7                	mov    %eax,%edi
f0102180:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102183:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102188:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010218b:	8b 40 04             	mov    0x4(%eax),%eax
f010218e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102193:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f0102199:	89 c2                	mov    %eax,%edx
f010219b:	c1 ea 0c             	shr    $0xc,%edx
f010219e:	83 c4 10             	add    $0x10,%esp
f01021a1:	39 ca                	cmp    %ecx,%edx
f01021a3:	72 15                	jb     f01021ba <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021a5:	50                   	push   %eax
f01021a6:	68 44 59 10 f0       	push   $0xf0105944
f01021ab:	68 61 04 00 00       	push   $0x461
f01021b0:	68 e1 67 10 f0       	push   $0xf01067e1
f01021b5:	e8 86 de ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01021ba:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f01021bf:	39 c7                	cmp    %eax,%edi
f01021c1:	74 19                	je     f01021dc <mem_init+0xfb8>
f01021c3:	68 7f 6a 10 f0       	push   $0xf0106a7f
f01021c8:	68 07 68 10 f0       	push   $0xf0106807
f01021cd:	68 62 04 00 00       	push   $0x462
f01021d2:	68 e1 67 10 f0       	push   $0xf01067e1
f01021d7:	e8 64 de ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01021dc:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01021df:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01021e6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021e9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01021ef:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01021f5:	c1 f8 03             	sar    $0x3,%eax
f01021f8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01021fb:	89 c2                	mov    %eax,%edx
f01021fd:	c1 ea 0c             	shr    $0xc,%edx
f0102200:	39 d1                	cmp    %edx,%ecx
f0102202:	77 12                	ja     f0102216 <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102204:	50                   	push   %eax
f0102205:	68 44 59 10 f0       	push   $0xf0105944
f010220a:	6a 58                	push   $0x58
f010220c:	68 ed 67 10 f0       	push   $0xf01067ed
f0102211:	e8 2a de ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102216:	83 ec 04             	sub    $0x4,%esp
f0102219:	68 00 10 00 00       	push   $0x1000
f010221e:	68 ff 00 00 00       	push   $0xff
f0102223:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102228:	50                   	push   %eax
f0102229:	e8 3b 2a 00 00       	call   f0104c69 <memset>
	page_free(pp0);
f010222e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102231:	89 3c 24             	mov    %edi,(%esp)
f0102234:	e8 f7 ec ff ff       	call   f0100f30 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102239:	83 c4 0c             	add    $0xc,%esp
f010223c:	6a 01                	push   $0x1
f010223e:	6a 00                	push   $0x0
f0102240:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102246:	e8 1b ed ff ff       	call   f0100f66 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010224b:	89 fa                	mov    %edi,%edx
f010224d:	2b 15 90 ae 22 f0    	sub    0xf022ae90,%edx
f0102253:	c1 fa 03             	sar    $0x3,%edx
f0102256:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102259:	89 d0                	mov    %edx,%eax
f010225b:	c1 e8 0c             	shr    $0xc,%eax
f010225e:	83 c4 10             	add    $0x10,%esp
f0102261:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0102267:	72 12                	jb     f010227b <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102269:	52                   	push   %edx
f010226a:	68 44 59 10 f0       	push   $0xf0105944
f010226f:	6a 58                	push   $0x58
f0102271:	68 ed 67 10 f0       	push   $0xf01067ed
f0102276:	e8 c5 dd ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010227b:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102281:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102284:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010228a:	f6 00 01             	testb  $0x1,(%eax)
f010228d:	74 19                	je     f01022a8 <mem_init+0x1084>
f010228f:	68 97 6a 10 f0       	push   $0xf0106a97
f0102294:	68 07 68 10 f0       	push   $0xf0106807
f0102299:	68 6c 04 00 00       	push   $0x46c
f010229e:	68 e1 67 10 f0       	push   $0xf01067e1
f01022a3:	e8 98 dd ff ff       	call   f0100040 <_panic>
f01022a8:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01022ab:	39 d0                	cmp    %edx,%eax
f01022ad:	75 db                	jne    f010228a <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01022af:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01022b4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01022ba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022bd:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01022c3:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01022c6:	89 0d 40 a2 22 f0    	mov    %ecx,0xf022a240

	// free the pages we took
	page_free(pp0);
f01022cc:	83 ec 0c             	sub    $0xc,%esp
f01022cf:	50                   	push   %eax
f01022d0:	e8 5b ec ff ff       	call   f0100f30 <page_free>
	page_free(pp1);
f01022d5:	89 1c 24             	mov    %ebx,(%esp)
f01022d8:	e8 53 ec ff ff       	call   f0100f30 <page_free>
	page_free(pp2);
f01022dd:	89 34 24             	mov    %esi,(%esp)
f01022e0:	e8 4b ec ff ff       	call   f0100f30 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f01022e5:	83 c4 08             	add    $0x8,%esp
f01022e8:	68 01 10 00 00       	push   $0x1001
f01022ed:	6a 00                	push   $0x0
f01022ef:	e8 c6 ee ff ff       	call   f01011ba <mmio_map_region>
f01022f4:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f01022f6:	83 c4 08             	add    $0x8,%esp
f01022f9:	68 00 10 00 00       	push   $0x1000
f01022fe:	6a 00                	push   $0x0
f0102300:	e8 b5 ee ff ff       	call   f01011ba <mmio_map_region>
f0102305:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f0102307:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f010230d:	83 c4 10             	add    $0x10,%esp
f0102310:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102316:	76 07                	jbe    f010231f <mem_init+0x10fb>
f0102318:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f010231d:	76 19                	jbe    f0102338 <mem_init+0x1114>
f010231f:	68 5c 64 10 f0       	push   $0xf010645c
f0102324:	68 07 68 10 f0       	push   $0xf0106807
f0102329:	68 7c 04 00 00       	push   $0x47c
f010232e:	68 e1 67 10 f0       	push   $0xf01067e1
f0102333:	e8 08 dd ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102338:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f010233e:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102344:	77 08                	ja     f010234e <mem_init+0x112a>
f0102346:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010234c:	77 19                	ja     f0102367 <mem_init+0x1143>
f010234e:	68 84 64 10 f0       	push   $0xf0106484
f0102353:	68 07 68 10 f0       	push   $0xf0106807
f0102358:	68 7d 04 00 00       	push   $0x47d
f010235d:	68 e1 67 10 f0       	push   $0xf01067e1
f0102362:	e8 d9 dc ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102367:	89 da                	mov    %ebx,%edx
f0102369:	09 f2                	or     %esi,%edx
f010236b:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102371:	74 19                	je     f010238c <mem_init+0x1168>
f0102373:	68 ac 64 10 f0       	push   $0xf01064ac
f0102378:	68 07 68 10 f0       	push   $0xf0106807
f010237d:	68 7f 04 00 00       	push   $0x47f
f0102382:	68 e1 67 10 f0       	push   $0xf01067e1
f0102387:	e8 b4 dc ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f010238c:	39 c6                	cmp    %eax,%esi
f010238e:	73 19                	jae    f01023a9 <mem_init+0x1185>
f0102390:	68 ae 6a 10 f0       	push   $0xf0106aae
f0102395:	68 07 68 10 f0       	push   $0xf0106807
f010239a:	68 81 04 00 00       	push   $0x481
f010239f:	68 e1 67 10 f0       	push   $0xf01067e1
f01023a4:	e8 97 dc ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f01023a9:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi
f01023af:	89 da                	mov    %ebx,%edx
f01023b1:	89 f8                	mov    %edi,%eax
f01023b3:	e8 b3 e6 ff ff       	call   f0100a6b <check_va2pa>
f01023b8:	85 c0                	test   %eax,%eax
f01023ba:	74 19                	je     f01023d5 <mem_init+0x11b1>
f01023bc:	68 d4 64 10 f0       	push   $0xf01064d4
f01023c1:	68 07 68 10 f0       	push   $0xf0106807
f01023c6:	68 83 04 00 00       	push   $0x483
f01023cb:	68 e1 67 10 f0       	push   $0xf01067e1
f01023d0:	e8 6b dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f01023d5:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f01023db:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01023de:	89 c2                	mov    %eax,%edx
f01023e0:	89 f8                	mov    %edi,%eax
f01023e2:	e8 84 e6 ff ff       	call   f0100a6b <check_va2pa>
f01023e7:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01023ec:	74 19                	je     f0102407 <mem_init+0x11e3>
f01023ee:	68 f8 64 10 f0       	push   $0xf01064f8
f01023f3:	68 07 68 10 f0       	push   $0xf0106807
f01023f8:	68 84 04 00 00       	push   $0x484
f01023fd:	68 e1 67 10 f0       	push   $0xf01067e1
f0102402:	e8 39 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102407:	89 f2                	mov    %esi,%edx
f0102409:	89 f8                	mov    %edi,%eax
f010240b:	e8 5b e6 ff ff       	call   f0100a6b <check_va2pa>
f0102410:	85 c0                	test   %eax,%eax
f0102412:	74 19                	je     f010242d <mem_init+0x1209>
f0102414:	68 28 65 10 f0       	push   $0xf0106528
f0102419:	68 07 68 10 f0       	push   $0xf0106807
f010241e:	68 85 04 00 00       	push   $0x485
f0102423:	68 e1 67 10 f0       	push   $0xf01067e1
f0102428:	e8 13 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f010242d:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102433:	89 f8                	mov    %edi,%eax
f0102435:	e8 31 e6 ff ff       	call   f0100a6b <check_va2pa>
f010243a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010243d:	74 19                	je     f0102458 <mem_init+0x1234>
f010243f:	68 4c 65 10 f0       	push   $0xf010654c
f0102444:	68 07 68 10 f0       	push   $0xf0106807
f0102449:	68 86 04 00 00       	push   $0x486
f010244e:	68 e1 67 10 f0       	push   $0xf01067e1
f0102453:	e8 e8 db ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102458:	83 ec 04             	sub    $0x4,%esp
f010245b:	6a 00                	push   $0x0
f010245d:	53                   	push   %ebx
f010245e:	57                   	push   %edi
f010245f:	e8 02 eb ff ff       	call   f0100f66 <pgdir_walk>
f0102464:	83 c4 10             	add    $0x10,%esp
f0102467:	f6 00 1a             	testb  $0x1a,(%eax)
f010246a:	75 19                	jne    f0102485 <mem_init+0x1261>
f010246c:	68 78 65 10 f0       	push   $0xf0106578
f0102471:	68 07 68 10 f0       	push   $0xf0106807
f0102476:	68 88 04 00 00       	push   $0x488
f010247b:	68 e1 67 10 f0       	push   $0xf01067e1
f0102480:	e8 bb db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102485:	83 ec 04             	sub    $0x4,%esp
f0102488:	6a 00                	push   $0x0
f010248a:	53                   	push   %ebx
f010248b:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102491:	e8 d0 ea ff ff       	call   f0100f66 <pgdir_walk>
f0102496:	8b 00                	mov    (%eax),%eax
f0102498:	83 c4 10             	add    $0x10,%esp
f010249b:	83 e0 04             	and    $0x4,%eax
f010249e:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01024a1:	74 19                	je     f01024bc <mem_init+0x1298>
f01024a3:	68 bc 65 10 f0       	push   $0xf01065bc
f01024a8:	68 07 68 10 f0       	push   $0xf0106807
f01024ad:	68 89 04 00 00       	push   $0x489
f01024b2:	68 e1 67 10 f0       	push   $0xf01067e1
f01024b7:	e8 84 db ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f01024bc:	83 ec 04             	sub    $0x4,%esp
f01024bf:	6a 00                	push   $0x0
f01024c1:	53                   	push   %ebx
f01024c2:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01024c8:	e8 99 ea ff ff       	call   f0100f66 <pgdir_walk>
f01024cd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f01024d3:	83 c4 0c             	add    $0xc,%esp
f01024d6:	6a 00                	push   $0x0
f01024d8:	ff 75 d4             	pushl  -0x2c(%ebp)
f01024db:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01024e1:	e8 80 ea ff ff       	call   f0100f66 <pgdir_walk>
f01024e6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f01024ec:	83 c4 0c             	add    $0xc,%esp
f01024ef:	6a 00                	push   $0x0
f01024f1:	56                   	push   %esi
f01024f2:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f01024f8:	e8 69 ea ff ff       	call   f0100f66 <pgdir_walk>
f01024fd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102503:	c7 04 24 c0 6a 10 f0 	movl   $0xf0106ac0,(%esp)
f010250a:	e8 5f 11 00 00       	call   f010366e <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U | PTE_P);
f010250f:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102514:	83 c4 10             	add    $0x10,%esp
f0102517:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010251c:	77 15                	ja     f0102533 <mem_init+0x130f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010251e:	50                   	push   %eax
f010251f:	68 68 59 10 f0       	push   $0xf0105968
f0102524:	68 b7 00 00 00       	push   $0xb7
f0102529:	68 e1 67 10 f0       	push   $0xf01067e1
f010252e:	e8 0d db ff ff       	call   f0100040 <_panic>
f0102533:	83 ec 08             	sub    $0x8,%esp
f0102536:	6a 05                	push   $0x5
f0102538:	05 00 00 00 10       	add    $0x10000000,%eax
f010253d:	50                   	push   %eax
f010253e:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102543:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102548:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f010254d:	e8 d8 ea ff ff       	call   f010102a <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U | PTE_P);
f0102552:	a1 48 a2 22 f0       	mov    0xf022a248,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102557:	83 c4 10             	add    $0x10,%esp
f010255a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010255f:	77 15                	ja     f0102576 <mem_init+0x1352>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102561:	50                   	push   %eax
f0102562:	68 68 59 10 f0       	push   $0xf0105968
f0102567:	68 bf 00 00 00       	push   $0xbf
f010256c:	68 e1 67 10 f0       	push   $0xf01067e1
f0102571:	e8 ca da ff ff       	call   f0100040 <_panic>
f0102576:	83 ec 08             	sub    $0x8,%esp
f0102579:	6a 05                	push   $0x5
f010257b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102580:	50                   	push   %eax
f0102581:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102586:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010258b:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102590:	e8 95 ea ff ff       	call   f010102a <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102595:	83 c4 10             	add    $0x10,%esp
f0102598:	b8 00 50 11 f0       	mov    $0xf0115000,%eax
f010259d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025a2:	77 15                	ja     f01025b9 <mem_init+0x1395>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025a4:	50                   	push   %eax
f01025a5:	68 68 59 10 f0       	push   $0xf0105968
f01025aa:	68 cb 00 00 00       	push   $0xcb
f01025af:	68 e1 67 10 f0       	push   $0xf01067e1
f01025b4:	e8 87 da ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01025b9:	83 ec 08             	sub    $0x8,%esp
f01025bc:	6a 02                	push   $0x2
f01025be:	68 00 50 11 00       	push   $0x115000
f01025c3:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01025c8:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01025cd:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f01025d2:	e8 53 ea ff ff       	call   f010102a <boot_map_region>
f01025d7:	c7 45 c4 00 c0 22 f0 	movl   $0xf022c000,-0x3c(%ebp)
f01025de:	83 c4 10             	add    $0x10,%esp
f01025e1:	bb 00 c0 22 f0       	mov    $0xf022c000,%ebx
f01025e6:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025eb:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01025f1:	77 15                	ja     f0102608 <mem_init+0x13e4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025f3:	53                   	push   %ebx
f01025f4:	68 68 59 10 f0       	push   $0xf0105968
f01025f9:	68 0b 01 00 00       	push   $0x10b
f01025fe:	68 e1 67 10 f0       	push   $0xf01067e1
f0102603:	e8 38 da ff ff       	call   f0100040 <_panic>
	// LAB 4: Your code here:
	uintptr_t kstacktop_i;
	for(int i = 0;i < NCPU;i++)
	{
		kstacktop_i = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
		boot_map_region(kern_pgdir, kstacktop_i - KSTKSIZE, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W);
f0102608:	83 ec 08             	sub    $0x8,%esp
f010260b:	6a 02                	push   $0x2
f010260d:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0102613:	50                   	push   %eax
f0102614:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102619:	89 f2                	mov    %esi,%edx
f010261b:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102620:	e8 05 ea ff ff       	call   f010102a <boot_map_region>
f0102625:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f010262b:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//             Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	uintptr_t kstacktop_i;
	for(int i = 0;i < NCPU;i++)
f0102631:	83 c4 10             	add    $0x10,%esp
f0102634:	b8 00 c0 26 f0       	mov    $0xf026c000,%eax
f0102639:	39 d8                	cmp    %ebx,%eax
f010263b:	75 ae                	jne    f01025eb <mem_init+0x13c7>
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	// Initialize the SMP-related parts of the memory map
	mem_init_mp();
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff-KERNBASE, 0, PTE_W);
f010263d:	83 ec 08             	sub    $0x8,%esp
f0102640:	6a 02                	push   $0x2
f0102642:	6a 00                	push   $0x0
f0102644:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102649:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010264e:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
f0102653:	e8 d2 e9 ff ff       	call   f010102a <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102658:	8b 3d 8c ae 22 f0    	mov    0xf022ae8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010265e:	a1 88 ae 22 f0       	mov    0xf022ae88,%eax
f0102663:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102666:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010266d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102672:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102675:	8b 35 90 ae 22 f0    	mov    0xf022ae90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010267b:	89 75 d0             	mov    %esi,-0x30(%ebp)
f010267e:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102681:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102686:	eb 55                	jmp    f01026dd <mem_init+0x14b9>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102688:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f010268e:	89 f8                	mov    %edi,%eax
f0102690:	e8 d6 e3 ff ff       	call   f0100a6b <check_va2pa>
f0102695:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010269c:	77 15                	ja     f01026b3 <mem_init+0x148f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010269e:	56                   	push   %esi
f010269f:	68 68 59 10 f0       	push   $0xf0105968
f01026a4:	68 a1 03 00 00       	push   $0x3a1
f01026a9:	68 e1 67 10 f0       	push   $0xf01067e1
f01026ae:	e8 8d d9 ff ff       	call   f0100040 <_panic>
f01026b3:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f01026ba:	39 c2                	cmp    %eax,%edx
f01026bc:	74 19                	je     f01026d7 <mem_init+0x14b3>
f01026be:	68 f0 65 10 f0       	push   $0xf01065f0
f01026c3:	68 07 68 10 f0       	push   $0xf0106807
f01026c8:	68 a1 03 00 00       	push   $0x3a1
f01026cd:	68 e1 67 10 f0       	push   $0xf01067e1
f01026d2:	e8 69 d9 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026d7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01026dd:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01026e0:	77 a6                	ja     f0102688 <mem_init+0x1464>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01026e2:	8b 35 48 a2 22 f0    	mov    0xf022a248,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026e8:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01026eb:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f01026f0:	89 da                	mov    %ebx,%edx
f01026f2:	89 f8                	mov    %edi,%eax
f01026f4:	e8 72 e3 ff ff       	call   f0100a6b <check_va2pa>
f01026f9:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102700:	77 15                	ja     f0102717 <mem_init+0x14f3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102702:	56                   	push   %esi
f0102703:	68 68 59 10 f0       	push   $0xf0105968
f0102708:	68 a6 03 00 00       	push   $0x3a6
f010270d:	68 e1 67 10 f0       	push   $0xf01067e1
f0102712:	e8 29 d9 ff ff       	call   f0100040 <_panic>
f0102717:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f010271e:	39 d0                	cmp    %edx,%eax
f0102720:	74 19                	je     f010273b <mem_init+0x1517>
f0102722:	68 24 66 10 f0       	push   $0xf0106624
f0102727:	68 07 68 10 f0       	push   $0xf0106807
f010272c:	68 a6 03 00 00       	push   $0x3a6
f0102731:	68 e1 67 10 f0       	push   $0xf01067e1
f0102736:	e8 05 d9 ff ff       	call   f0100040 <_panic>
f010273b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102741:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0102747:	75 a7                	jne    f01026f0 <mem_init+0x14cc>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102749:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010274c:	c1 e6 0c             	shl    $0xc,%esi
f010274f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102754:	eb 30                	jmp    f0102786 <mem_init+0x1562>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102756:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f010275c:	89 f8                	mov    %edi,%eax
f010275e:	e8 08 e3 ff ff       	call   f0100a6b <check_va2pa>
f0102763:	39 c3                	cmp    %eax,%ebx
f0102765:	74 19                	je     f0102780 <mem_init+0x155c>
f0102767:	68 58 66 10 f0       	push   $0xf0106658
f010276c:	68 07 68 10 f0       	push   $0xf0106807
f0102771:	68 aa 03 00 00       	push   $0x3aa
f0102776:	68 e1 67 10 f0       	push   $0xf01067e1
f010277b:	e8 c0 d8 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102780:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102786:	39 f3                	cmp    %esi,%ebx
f0102788:	72 cc                	jb     f0102756 <mem_init+0x1532>
f010278a:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f010278f:	89 75 cc             	mov    %esi,-0x34(%ebp)
f0102792:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0102795:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102798:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f010279e:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01027a1:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f01027a3:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01027a6:	05 00 80 00 20       	add    $0x20008000,%eax
f01027ab:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01027ae:	89 da                	mov    %ebx,%edx
f01027b0:	89 f8                	mov    %edi,%eax
f01027b2:	e8 b4 e2 ff ff       	call   f0100a6b <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027b7:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01027bd:	77 15                	ja     f01027d4 <mem_init+0x15b0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027bf:	56                   	push   %esi
f01027c0:	68 68 59 10 f0       	push   $0xf0105968
f01027c5:	68 b2 03 00 00       	push   $0x3b2
f01027ca:	68 e1 67 10 f0       	push   $0xf01067e1
f01027cf:	e8 6c d8 ff ff       	call   f0100040 <_panic>
f01027d4:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01027d7:	8d 94 0b 00 c0 22 f0 	lea    -0xfdd4000(%ebx,%ecx,1),%edx
f01027de:	39 d0                	cmp    %edx,%eax
f01027e0:	74 19                	je     f01027fb <mem_init+0x15d7>
f01027e2:	68 80 66 10 f0       	push   $0xf0106680
f01027e7:	68 07 68 10 f0       	push   $0xf0106807
f01027ec:	68 b2 03 00 00       	push   $0x3b2
f01027f1:	68 e1 67 10 f0       	push   $0xf01067e1
f01027f6:	e8 45 d8 ff ff       	call   f0100040 <_panic>
f01027fb:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102801:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f0102804:	75 a8                	jne    f01027ae <mem_init+0x158a>
f0102806:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102809:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f010280f:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102812:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102814:	89 da                	mov    %ebx,%edx
f0102816:	89 f8                	mov    %edi,%eax
f0102818:	e8 4e e2 ff ff       	call   f0100a6b <check_va2pa>
f010281d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102820:	74 19                	je     f010283b <mem_init+0x1617>
f0102822:	68 c8 66 10 f0       	push   $0xf01066c8
f0102827:	68 07 68 10 f0       	push   $0xf0106807
f010282c:	68 b4 03 00 00       	push   $0x3b4
f0102831:	68 e1 67 10 f0       	push   $0xf01067e1
f0102836:	e8 05 d8 ff ff       	call   f0100040 <_panic>
f010283b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102841:	39 de                	cmp    %ebx,%esi
f0102843:	75 cf                	jne    f0102814 <mem_init+0x15f0>
f0102845:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102848:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f010284f:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f0102856:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f010285c:	81 fe 00 c0 26 f0    	cmp    $0xf026c000,%esi
f0102862:	0f 85 2d ff ff ff    	jne    f0102795 <mem_init+0x1571>
f0102868:	b8 00 00 00 00       	mov    $0x0,%eax
f010286d:	eb 2a                	jmp    f0102899 <mem_init+0x1675>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010286f:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102875:	83 fa 04             	cmp    $0x4,%edx
f0102878:	77 1f                	ja     f0102899 <mem_init+0x1675>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f010287a:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f010287e:	75 7e                	jne    f01028fe <mem_init+0x16da>
f0102880:	68 d9 6a 10 f0       	push   $0xf0106ad9
f0102885:	68 07 68 10 f0       	push   $0xf0106807
f010288a:	68 bf 03 00 00       	push   $0x3bf
f010288f:	68 e1 67 10 f0       	push   $0xf01067e1
f0102894:	e8 a7 d7 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102899:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010289e:	76 3f                	jbe    f01028df <mem_init+0x16bb>
				assert(pgdir[i] & PTE_P);
f01028a0:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01028a3:	f6 c2 01             	test   $0x1,%dl
f01028a6:	75 19                	jne    f01028c1 <mem_init+0x169d>
f01028a8:	68 d9 6a 10 f0       	push   $0xf0106ad9
f01028ad:	68 07 68 10 f0       	push   $0xf0106807
f01028b2:	68 c3 03 00 00       	push   $0x3c3
f01028b7:	68 e1 67 10 f0       	push   $0xf01067e1
f01028bc:	e8 7f d7 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f01028c1:	f6 c2 02             	test   $0x2,%dl
f01028c4:	75 38                	jne    f01028fe <mem_init+0x16da>
f01028c6:	68 ea 6a 10 f0       	push   $0xf0106aea
f01028cb:	68 07 68 10 f0       	push   $0xf0106807
f01028d0:	68 c4 03 00 00       	push   $0x3c4
f01028d5:	68 e1 67 10 f0       	push   $0xf01067e1
f01028da:	e8 61 d7 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f01028df:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01028e3:	74 19                	je     f01028fe <mem_init+0x16da>
f01028e5:	68 fb 6a 10 f0       	push   $0xf0106afb
f01028ea:	68 07 68 10 f0       	push   $0xf0106807
f01028ef:	68 c6 03 00 00       	push   $0x3c6
f01028f4:	68 e1 67 10 f0       	push   $0xf01067e1
f01028f9:	e8 42 d7 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01028fe:	83 c0 01             	add    $0x1,%eax
f0102901:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102906:	0f 86 63 ff ff ff    	jbe    f010286f <mem_init+0x164b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010290c:	83 ec 0c             	sub    $0xc,%esp
f010290f:	68 ec 66 10 f0       	push   $0xf01066ec
f0102914:	e8 55 0d 00 00       	call   f010366e <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102919:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010291e:	83 c4 10             	add    $0x10,%esp
f0102921:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102926:	77 15                	ja     f010293d <mem_init+0x1719>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102928:	50                   	push   %eax
f0102929:	68 68 59 10 f0       	push   $0xf0105968
f010292e:	68 e2 00 00 00       	push   $0xe2
f0102933:	68 e1 67 10 f0       	push   $0xf01067e1
f0102938:	e8 03 d7 ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010293d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102942:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102945:	b8 00 00 00 00       	mov    $0x0,%eax
f010294a:	e8 80 e1 ff ff       	call   f0100acf <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f010294f:	0f 20 c0             	mov    %cr0,%eax
f0102952:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102955:	0d 23 00 05 80       	or     $0x80050023,%eax
f010295a:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010295d:	83 ec 0c             	sub    $0xc,%esp
f0102960:	6a 00                	push   $0x0
f0102962:	e8 53 e5 ff ff       	call   f0100eba <page_alloc>
f0102967:	89 c3                	mov    %eax,%ebx
f0102969:	83 c4 10             	add    $0x10,%esp
f010296c:	85 c0                	test   %eax,%eax
f010296e:	75 19                	jne    f0102989 <mem_init+0x1765>
f0102970:	68 e5 68 10 f0       	push   $0xf01068e5
f0102975:	68 07 68 10 f0       	push   $0xf0106807
f010297a:	68 9e 04 00 00       	push   $0x49e
f010297f:	68 e1 67 10 f0       	push   $0xf01067e1
f0102984:	e8 b7 d6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102989:	83 ec 0c             	sub    $0xc,%esp
f010298c:	6a 00                	push   $0x0
f010298e:	e8 27 e5 ff ff       	call   f0100eba <page_alloc>
f0102993:	89 c7                	mov    %eax,%edi
f0102995:	83 c4 10             	add    $0x10,%esp
f0102998:	85 c0                	test   %eax,%eax
f010299a:	75 19                	jne    f01029b5 <mem_init+0x1791>
f010299c:	68 fb 68 10 f0       	push   $0xf01068fb
f01029a1:	68 07 68 10 f0       	push   $0xf0106807
f01029a6:	68 9f 04 00 00       	push   $0x49f
f01029ab:	68 e1 67 10 f0       	push   $0xf01067e1
f01029b0:	e8 8b d6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01029b5:	83 ec 0c             	sub    $0xc,%esp
f01029b8:	6a 00                	push   $0x0
f01029ba:	e8 fb e4 ff ff       	call   f0100eba <page_alloc>
f01029bf:	89 c6                	mov    %eax,%esi
f01029c1:	83 c4 10             	add    $0x10,%esp
f01029c4:	85 c0                	test   %eax,%eax
f01029c6:	75 19                	jne    f01029e1 <mem_init+0x17bd>
f01029c8:	68 11 69 10 f0       	push   $0xf0106911
f01029cd:	68 07 68 10 f0       	push   $0xf0106807
f01029d2:	68 a0 04 00 00       	push   $0x4a0
f01029d7:	68 e1 67 10 f0       	push   $0xf01067e1
f01029dc:	e8 5f d6 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f01029e1:	83 ec 0c             	sub    $0xc,%esp
f01029e4:	53                   	push   %ebx
f01029e5:	e8 46 e5 ff ff       	call   f0100f30 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029ea:	89 f8                	mov    %edi,%eax
f01029ec:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f01029f2:	c1 f8 03             	sar    $0x3,%eax
f01029f5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029f8:	89 c2                	mov    %eax,%edx
f01029fa:	c1 ea 0c             	shr    $0xc,%edx
f01029fd:	83 c4 10             	add    $0x10,%esp
f0102a00:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102a06:	72 12                	jb     f0102a1a <mem_init+0x17f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a08:	50                   	push   %eax
f0102a09:	68 44 59 10 f0       	push   $0xf0105944
f0102a0e:	6a 58                	push   $0x58
f0102a10:	68 ed 67 10 f0       	push   $0xf01067ed
f0102a15:	e8 26 d6 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102a1a:	83 ec 04             	sub    $0x4,%esp
f0102a1d:	68 00 10 00 00       	push   $0x1000
f0102a22:	6a 01                	push   $0x1
f0102a24:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a29:	50                   	push   %eax
f0102a2a:	e8 3a 22 00 00       	call   f0104c69 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a2f:	89 f0                	mov    %esi,%eax
f0102a31:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102a37:	c1 f8 03             	sar    $0x3,%eax
f0102a3a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a3d:	89 c2                	mov    %eax,%edx
f0102a3f:	c1 ea 0c             	shr    $0xc,%edx
f0102a42:	83 c4 10             	add    $0x10,%esp
f0102a45:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102a4b:	72 12                	jb     f0102a5f <mem_init+0x183b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a4d:	50                   	push   %eax
f0102a4e:	68 44 59 10 f0       	push   $0xf0105944
f0102a53:	6a 58                	push   $0x58
f0102a55:	68 ed 67 10 f0       	push   $0xf01067ed
f0102a5a:	e8 e1 d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102a5f:	83 ec 04             	sub    $0x4,%esp
f0102a62:	68 00 10 00 00       	push   $0x1000
f0102a67:	6a 02                	push   $0x2
f0102a69:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a6e:	50                   	push   %eax
f0102a6f:	e8 f5 21 00 00       	call   f0104c69 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102a74:	6a 02                	push   $0x2
f0102a76:	68 00 10 00 00       	push   $0x1000
f0102a7b:	57                   	push   %edi
f0102a7c:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102a82:	e8 cd e6 ff ff       	call   f0101154 <page_insert>
	assert(pp1->pp_ref == 1);
f0102a87:	83 c4 20             	add    $0x20,%esp
f0102a8a:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102a8f:	74 19                	je     f0102aaa <mem_init+0x1886>
f0102a91:	68 e2 69 10 f0       	push   $0xf01069e2
f0102a96:	68 07 68 10 f0       	push   $0xf0106807
f0102a9b:	68 a5 04 00 00       	push   $0x4a5
f0102aa0:	68 e1 67 10 f0       	push   $0xf01067e1
f0102aa5:	e8 96 d5 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102aaa:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102ab1:	01 01 01 
f0102ab4:	74 19                	je     f0102acf <mem_init+0x18ab>
f0102ab6:	68 0c 67 10 f0       	push   $0xf010670c
f0102abb:	68 07 68 10 f0       	push   $0xf0106807
f0102ac0:	68 a6 04 00 00       	push   $0x4a6
f0102ac5:	68 e1 67 10 f0       	push   $0xf01067e1
f0102aca:	e8 71 d5 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102acf:	6a 02                	push   $0x2
f0102ad1:	68 00 10 00 00       	push   $0x1000
f0102ad6:	56                   	push   %esi
f0102ad7:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102add:	e8 72 e6 ff ff       	call   f0101154 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102ae2:	83 c4 10             	add    $0x10,%esp
f0102ae5:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102aec:	02 02 02 
f0102aef:	74 19                	je     f0102b0a <mem_init+0x18e6>
f0102af1:	68 30 67 10 f0       	push   $0xf0106730
f0102af6:	68 07 68 10 f0       	push   $0xf0106807
f0102afb:	68 a8 04 00 00       	push   $0x4a8
f0102b00:	68 e1 67 10 f0       	push   $0xf01067e1
f0102b05:	e8 36 d5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102b0a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b0f:	74 19                	je     f0102b2a <mem_init+0x1906>
f0102b11:	68 04 6a 10 f0       	push   $0xf0106a04
f0102b16:	68 07 68 10 f0       	push   $0xf0106807
f0102b1b:	68 a9 04 00 00       	push   $0x4a9
f0102b20:	68 e1 67 10 f0       	push   $0xf01067e1
f0102b25:	e8 16 d5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102b2a:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102b2f:	74 19                	je     f0102b4a <mem_init+0x1926>
f0102b31:	68 6e 6a 10 f0       	push   $0xf0106a6e
f0102b36:	68 07 68 10 f0       	push   $0xf0106807
f0102b3b:	68 aa 04 00 00       	push   $0x4aa
f0102b40:	68 e1 67 10 f0       	push   $0xf01067e1
f0102b45:	e8 f6 d4 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b4a:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b51:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b54:	89 f0                	mov    %esi,%eax
f0102b56:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102b5c:	c1 f8 03             	sar    $0x3,%eax
f0102b5f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b62:	89 c2                	mov    %eax,%edx
f0102b64:	c1 ea 0c             	shr    $0xc,%edx
f0102b67:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102b6d:	72 12                	jb     f0102b81 <mem_init+0x195d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b6f:	50                   	push   %eax
f0102b70:	68 44 59 10 f0       	push   $0xf0105944
f0102b75:	6a 58                	push   $0x58
f0102b77:	68 ed 67 10 f0       	push   $0xf01067ed
f0102b7c:	e8 bf d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102b81:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102b88:	03 03 03 
f0102b8b:	74 19                	je     f0102ba6 <mem_init+0x1982>
f0102b8d:	68 54 67 10 f0       	push   $0xf0106754
f0102b92:	68 07 68 10 f0       	push   $0xf0106807
f0102b97:	68 ac 04 00 00       	push   $0x4ac
f0102b9c:	68 e1 67 10 f0       	push   $0xf01067e1
f0102ba1:	e8 9a d4 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102ba6:	83 ec 08             	sub    $0x8,%esp
f0102ba9:	68 00 10 00 00       	push   $0x1000
f0102bae:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102bb4:	e8 52 e5 ff ff       	call   f010110b <page_remove>
	assert(pp2->pp_ref == 0);
f0102bb9:	83 c4 10             	add    $0x10,%esp
f0102bbc:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102bc1:	74 19                	je     f0102bdc <mem_init+0x19b8>
f0102bc3:	68 3c 6a 10 f0       	push   $0xf0106a3c
f0102bc8:	68 07 68 10 f0       	push   $0xf0106807
f0102bcd:	68 ae 04 00 00       	push   $0x4ae
f0102bd2:	68 e1 67 10 f0       	push   $0xf01067e1
f0102bd7:	e8 64 d4 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102bdc:	8b 0d 8c ae 22 f0    	mov    0xf022ae8c,%ecx
f0102be2:	8b 11                	mov    (%ecx),%edx
f0102be4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102bea:	89 d8                	mov    %ebx,%eax
f0102bec:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102bf2:	c1 f8 03             	sar    $0x3,%eax
f0102bf5:	c1 e0 0c             	shl    $0xc,%eax
f0102bf8:	39 c2                	cmp    %eax,%edx
f0102bfa:	74 19                	je     f0102c15 <mem_init+0x19f1>
f0102bfc:	68 dc 60 10 f0       	push   $0xf01060dc
f0102c01:	68 07 68 10 f0       	push   $0xf0106807
f0102c06:	68 b1 04 00 00       	push   $0x4b1
f0102c0b:	68 e1 67 10 f0       	push   $0xf01067e1
f0102c10:	e8 2b d4 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102c15:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102c1b:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102c20:	74 19                	je     f0102c3b <mem_init+0x1a17>
f0102c22:	68 f3 69 10 f0       	push   $0xf01069f3
f0102c27:	68 07 68 10 f0       	push   $0xf0106807
f0102c2c:	68 b3 04 00 00       	push   $0x4b3
f0102c31:	68 e1 67 10 f0       	push   $0xf01067e1
f0102c36:	e8 05 d4 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102c3b:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102c41:	83 ec 0c             	sub    $0xc,%esp
f0102c44:	53                   	push   %ebx
f0102c45:	e8 e6 e2 ff ff       	call   f0100f30 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102c4a:	c7 04 24 80 67 10 f0 	movl   $0xf0106780,(%esp)
f0102c51:	e8 18 0a 00 00       	call   f010366e <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102c56:	83 c4 10             	add    $0x10,%esp
f0102c59:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c5c:	5b                   	pop    %ebx
f0102c5d:	5e                   	pop    %esi
f0102c5e:	5f                   	pop    %edi
f0102c5f:	5d                   	pop    %ebp
f0102c60:	c3                   	ret    

f0102c61 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102c61:	55                   	push   %ebp
f0102c62:	89 e5                	mov    %esp,%ebp
f0102c64:	57                   	push   %edi
f0102c65:	56                   	push   %esi
f0102c66:	53                   	push   %ebx
f0102c67:	83 ec 1c             	sub    $0x1c,%esp
f0102c6a:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102c6d:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	uint32_t start = (uint32_t)ROUNDDOWN(va, PGSIZE);
f0102c70:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102c73:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t end = (uint32_t)ROUNDUP(va+len, PGSIZE);
f0102c79:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c7c:	03 45 10             	add    0x10(%ebp),%eax
f0102c7f:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102c84:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102c89:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(uint32_t i = start;i < end;i += PGSIZE)
f0102c8c:	eb 50                	jmp    f0102cde <user_mem_check+0x7d>
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, (void *)i, 0);
f0102c8e:	83 ec 04             	sub    $0x4,%esp
f0102c91:	6a 00                	push   $0x0
f0102c93:	53                   	push   %ebx
f0102c94:	ff 77 60             	pushl  0x60(%edi)
f0102c97:	e8 ca e2 ff ff       	call   f0100f66 <pgdir_walk>
// A user program can access a virtual address if (1) the address is below
// ULIM, and (2) the page table gives it permission. 
		//不满足的条件:1.地址大于ULIM 2.pte不存在 3.pte没有PTE_P的权限位 
		//4.pte的权限比perm高，说明当前权限无法访问对应内存
		if(i >= ULIM || !pte || !(*pte & PTE_P) || (*pte & perm) != perm)
f0102c9c:	83 c4 10             	add    $0x10,%esp
f0102c9f:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102ca5:	77 10                	ja     f0102cb7 <user_mem_check+0x56>
f0102ca7:	85 c0                	test   %eax,%eax
f0102ca9:	74 0c                	je     f0102cb7 <user_mem_check+0x56>
f0102cab:	8b 00                	mov    (%eax),%eax
f0102cad:	a8 01                	test   $0x1,%al
f0102caf:	74 06                	je     f0102cb7 <user_mem_check+0x56>
f0102cb1:	21 f0                	and    %esi,%eax
f0102cb3:	39 c6                	cmp    %eax,%esi
f0102cb5:	74 21                	je     f0102cd8 <user_mem_check+0x77>
		{
// If there is an error, set the 'user_mem_check_addr' variable to the first
// erroneous virtual address.
			//如果出错的是va之前的地址，需要返回的也应该是va的地址
			if(i < (uint32_t)va)
f0102cb7:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0102cba:	73 0f                	jae    f0102ccb <user_mem_check+0x6a>
				user_mem_check_addr = (uint32_t)va;
f0102cbc:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102cbf:	a3 3c a2 22 f0       	mov    %eax,0xf022a23c
			else 
				user_mem_check_addr = i;
			return -E_FAULT;
f0102cc4:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102cc9:	eb 1d                	jmp    f0102ce8 <user_mem_check+0x87>
// erroneous virtual address.
			//如果出错的是va之前的地址，需要返回的也应该是va的地址
			if(i < (uint32_t)va)
				user_mem_check_addr = (uint32_t)va;
			else 
				user_mem_check_addr = i;
f0102ccb:	89 1d 3c a2 22 f0    	mov    %ebx,0xf022a23c
			return -E_FAULT;
f0102cd1:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102cd6:	eb 10                	jmp    f0102ce8 <user_mem_check+0x87>
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	uint32_t start = (uint32_t)ROUNDDOWN(va, PGSIZE);
	uint32_t end = (uint32_t)ROUNDUP(va+len, PGSIZE);
	for(uint32_t i = start;i < end;i += PGSIZE)
f0102cd8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102cde:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102ce1:	72 ab                	jb     f0102c8e <user_mem_check+0x2d>
			else 
				user_mem_check_addr = i;
			return -E_FAULT;
		} 
	}
	return 0;
f0102ce3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102ce8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ceb:	5b                   	pop    %ebx
f0102cec:	5e                   	pop    %esi
f0102ced:	5f                   	pop    %edi
f0102cee:	5d                   	pop    %ebp
f0102cef:	c3                   	ret    

f0102cf0 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102cf0:	55                   	push   %ebp
f0102cf1:	89 e5                	mov    %esp,%ebp
f0102cf3:	53                   	push   %ebx
f0102cf4:	83 ec 04             	sub    $0x4,%esp
f0102cf7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102cfa:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cfd:	83 c8 04             	or     $0x4,%eax
f0102d00:	50                   	push   %eax
f0102d01:	ff 75 10             	pushl  0x10(%ebp)
f0102d04:	ff 75 0c             	pushl  0xc(%ebp)
f0102d07:	53                   	push   %ebx
f0102d08:	e8 54 ff ff ff       	call   f0102c61 <user_mem_check>
f0102d0d:	83 c4 10             	add    $0x10,%esp
f0102d10:	85 c0                	test   %eax,%eax
f0102d12:	79 21                	jns    f0102d35 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102d14:	83 ec 04             	sub    $0x4,%esp
f0102d17:	ff 35 3c a2 22 f0    	pushl  0xf022a23c
f0102d1d:	ff 73 48             	pushl  0x48(%ebx)
f0102d20:	68 ac 67 10 f0       	push   $0xf01067ac
f0102d25:	e8 44 09 00 00       	call   f010366e <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102d2a:	89 1c 24             	mov    %ebx,(%esp)
f0102d2d:	e8 46 06 00 00       	call   f0103378 <env_destroy>
f0102d32:	83 c4 10             	add    $0x10,%esp
	}
}
f0102d35:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102d38:	c9                   	leave  
f0102d39:	c3                   	ret    

f0102d3a <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102d3a:	55                   	push   %ebp
f0102d3b:	89 e5                	mov    %esp,%ebp
f0102d3d:	57                   	push   %edi
f0102d3e:	56                   	push   %esi
f0102d3f:	53                   	push   %ebx
f0102d40:	83 ec 0c             	sub    $0xc,%esp
f0102d43:	89 c7                	mov    %eax,%edi
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	//boot_map_region(e->env_pgdir, va, len, PADDR(envs), PTE_P | PTE_U | PTE_W);
	uint32_t start,end;
	start = ROUNDDOWN((uint32_t)va, PGSIZE);
	end = ROUNDUP((uint32_t)(va + len), PGSIZE);
f0102d45:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102d4c:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	//cprintf("start=%x \n",start);
	//cprintf("end=%x \n",end);

	struct PageInfo *Page;
	int r;
	for(int i = start;i < end;i += PGSIZE)
f0102d52:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102d58:	89 d3                	mov    %edx,%ebx
f0102d5a:	eb 56                	jmp    f0102db2 <region_alloc+0x78>
	{
		Page = page_alloc(0);
f0102d5c:	83 ec 0c             	sub    $0xc,%esp
f0102d5f:	6a 00                	push   $0x0
f0102d61:	e8 54 e1 ff ff       	call   f0100eba <page_alloc>
		if(!Page)
f0102d66:	83 c4 10             	add    $0x10,%esp
f0102d69:	85 c0                	test   %eax,%eax
f0102d6b:	75 17                	jne    f0102d84 <region_alloc+0x4a>
			panic("page_alloc fail");
f0102d6d:	83 ec 04             	sub    $0x4,%esp
f0102d70:	68 09 6b 10 f0       	push   $0xf0106b09
f0102d75:	68 34 01 00 00       	push   $0x134
f0102d7a:	68 19 6b 10 f0       	push   $0xf0106b19
f0102d7f:	e8 bc d2 ff ff       	call   f0100040 <_panic>
		//r = page_insert(e->env_pgdir, Page, va, PTE_P | PTE_U | PTE_W);
		r = page_insert(e->env_pgdir, Page, (void *)i, PTE_U | PTE_W);
f0102d84:	6a 06                	push   $0x6
f0102d86:	53                   	push   %ebx
f0102d87:	50                   	push   %eax
f0102d88:	ff 77 60             	pushl  0x60(%edi)
f0102d8b:	e8 c4 e3 ff ff       	call   f0101154 <page_insert>
		if(r != 0)
f0102d90:	83 c4 10             	add    $0x10,%esp
f0102d93:	85 c0                	test   %eax,%eax
f0102d95:	74 15                	je     f0102dac <region_alloc+0x72>
			panic("region_alloc: %e", r);
f0102d97:	50                   	push   %eax
f0102d98:	68 24 6b 10 f0       	push   $0xf0106b24
f0102d9d:	68 38 01 00 00       	push   $0x138
f0102da2:	68 19 6b 10 f0       	push   $0xf0106b19
f0102da7:	e8 94 d2 ff ff       	call   f0100040 <_panic>
	//cprintf("start=%x \n",start);
	//cprintf("end=%x \n",end);

	struct PageInfo *Page;
	int r;
	for(int i = start;i < end;i += PGSIZE)
f0102dac:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102db2:	39 de                	cmp    %ebx,%esi
f0102db4:	77 a6                	ja     f0102d5c <region_alloc+0x22>
		r = page_insert(e->env_pgdir, Page, (void *)i, PTE_U | PTE_W);
		if(r != 0)
			panic("region_alloc: %e", r);
			//panic("region_alloc fail");
	}
}
f0102db6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102db9:	5b                   	pop    %ebx
f0102dba:	5e                   	pop    %esi
f0102dbb:	5f                   	pop    %edi
f0102dbc:	5d                   	pop    %ebp
f0102dbd:	c3                   	ret    

f0102dbe <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102dbe:	55                   	push   %ebp
f0102dbf:	89 e5                	mov    %esp,%ebp
f0102dc1:	56                   	push   %esi
f0102dc2:	53                   	push   %ebx
f0102dc3:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dc6:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102dc9:	85 c0                	test   %eax,%eax
f0102dcb:	75 1a                	jne    f0102de7 <envid2env+0x29>
		*env_store = curenv;
f0102dcd:	e8 b8 24 00 00       	call   f010528a <cpunum>
f0102dd2:	6b c0 74             	imul   $0x74,%eax,%eax
f0102dd5:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102ddb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102dde:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102de0:	b8 00 00 00 00       	mov    $0x0,%eax
f0102de5:	eb 70                	jmp    f0102e57 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102de7:	89 c3                	mov    %eax,%ebx
f0102de9:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102def:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102df2:	03 1d 48 a2 22 f0    	add    0xf022a248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102df8:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102dfc:	74 05                	je     f0102e03 <envid2env+0x45>
f0102dfe:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102e01:	74 10                	je     f0102e13 <envid2env+0x55>
		*env_store = 0;
f0102e03:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e06:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e0c:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e11:	eb 44                	jmp    f0102e57 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102e13:	84 d2                	test   %dl,%dl
f0102e15:	74 36                	je     f0102e4d <envid2env+0x8f>
f0102e17:	e8 6e 24 00 00       	call   f010528a <cpunum>
f0102e1c:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e1f:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f0102e25:	74 26                	je     f0102e4d <envid2env+0x8f>
f0102e27:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102e2a:	e8 5b 24 00 00       	call   f010528a <cpunum>
f0102e2f:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e32:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102e38:	3b 70 48             	cmp    0x48(%eax),%esi
f0102e3b:	74 10                	je     f0102e4d <envid2env+0x8f>
		*env_store = 0;
f0102e3d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e40:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e46:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e4b:	eb 0a                	jmp    f0102e57 <envid2env+0x99>
	}

	*env_store = e;
f0102e4d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e50:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102e52:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102e57:	5b                   	pop    %ebx
f0102e58:	5e                   	pop    %esi
f0102e59:	5d                   	pop    %ebp
f0102e5a:	c3                   	ret    

f0102e5b <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102e5b:	55                   	push   %ebp
f0102e5c:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102e5e:	b8 20 f3 11 f0       	mov    $0xf011f320,%eax
f0102e63:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102e66:	b8 23 00 00 00       	mov    $0x23,%eax
f0102e6b:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102e6d:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102e6f:	b8 10 00 00 00       	mov    $0x10,%eax
f0102e74:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102e76:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102e78:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102e7a:	ea 81 2e 10 f0 08 00 	ljmp   $0x8,$0xf0102e81
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102e81:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e86:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102e89:	5d                   	pop    %ebp
f0102e8a:	c3                   	ret    

f0102e8b <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102e8b:	55                   	push   %ebp
f0102e8c:	89 e5                	mov    %esp,%ebp
f0102e8e:	56                   	push   %esi
f0102e8f:	53                   	push   %ebx
	// LAB 3: Your code here.
	// struct Env* envs;
	// env_free_list = NULL;
	for(int i = NENV - 1;i >= 0;i--)
	{
		envs[i].env_id = 0;
f0102e90:	8b 35 48 a2 22 f0    	mov    0xf022a248,%esi
f0102e96:	8b 15 4c a2 22 f0    	mov    0xf022a24c,%edx
f0102e9c:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102ea2:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102ea5:	89 c1                	mov    %eax,%ecx
f0102ea7:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f0102eae:	89 50 44             	mov    %edx,0x44(%eax)
f0102eb1:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];
f0102eb4:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	// struct Env* envs;
	// env_free_list = NULL;
	for(int i = NENV - 1;i >= 0;i--)
f0102eb6:	39 d8                	cmp    %ebx,%eax
f0102eb8:	75 eb                	jne    f0102ea5 <env_init+0x1a>
f0102eba:	89 35 4c a2 22 f0    	mov    %esi,0xf022a24c
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
		//envs[i].env_status = 
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f0102ec0:	e8 96 ff ff ff       	call   f0102e5b <env_init_percpu>
}
f0102ec5:	5b                   	pop    %ebx
f0102ec6:	5e                   	pop    %esi
f0102ec7:	5d                   	pop    %ebp
f0102ec8:	c3                   	ret    

f0102ec9 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102ec9:	55                   	push   %ebp
f0102eca:	89 e5                	mov    %esp,%ebp
f0102ecc:	56                   	push   %esi
f0102ecd:	53                   	push   %ebx
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102ece:	8b 1d 4c a2 22 f0    	mov    0xf022a24c,%ebx
f0102ed4:	85 db                	test   %ebx,%ebx
f0102ed6:	0f 84 64 01 00 00    	je     f0103040 <env_alloc+0x177>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102edc:	83 ec 0c             	sub    $0xc,%esp
f0102edf:	6a 01                	push   $0x1
f0102ee1:	e8 d4 df ff ff       	call   f0100eba <page_alloc>
f0102ee6:	89 c6                	mov    %eax,%esi
f0102ee8:	83 c4 10             	add    $0x10,%esp
f0102eeb:	85 c0                	test   %eax,%eax
f0102eed:	0f 84 54 01 00 00    	je     f0103047 <env_alloc+0x17e>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102ef3:	2b 05 90 ae 22 f0    	sub    0xf022ae90,%eax
f0102ef9:	c1 f8 03             	sar    $0x3,%eax
f0102efc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102eff:	89 c2                	mov    %eax,%edx
f0102f01:	c1 ea 0c             	shr    $0xc,%edx
f0102f04:	3b 15 88 ae 22 f0    	cmp    0xf022ae88,%edx
f0102f0a:	72 12                	jb     f0102f1e <env_alloc+0x55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f0c:	50                   	push   %eax
f0102f0d:	68 44 59 10 f0       	push   $0xf0105944
f0102f12:	6a 58                	push   $0x58
f0102f14:	68 ed 67 10 f0       	push   $0xf01067ed
f0102f19:	e8 22 d1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102f1e:	2d 00 00 00 10       	sub    $0x10000000,%eax
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	// p = page_alloc(ALLOC_ZERO);
	e->env_pgdir = page2kva(p);
f0102f23:	89 43 60             	mov    %eax,0x60(%ebx)
	//memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
	memmove(e->env_pgdir, kern_pgdir, PGSIZE);
f0102f26:	83 ec 04             	sub    $0x4,%esp
f0102f29:	68 00 10 00 00       	push   $0x1000
f0102f2e:	ff 35 8c ae 22 f0    	pushl  0xf022ae8c
f0102f34:	50                   	push   %eax
f0102f35:	e8 7c 1d 00 00       	call   f0104cb6 <memmove>
	p->pp_ref++;
f0102f3a:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102f3f:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f42:	83 c4 10             	add    $0x10,%esp
f0102f45:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102f4a:	77 15                	ja     f0102f61 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f4c:	50                   	push   %eax
f0102f4d:	68 68 59 10 f0       	push   $0xf0105968
f0102f52:	68 c9 00 00 00       	push   $0xc9
f0102f57:	68 19 6b 10 f0       	push   $0xf0106b19
f0102f5c:	e8 df d0 ff ff       	call   f0100040 <_panic>
f0102f61:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102f67:	83 ca 05             	or     $0x5,%edx
f0102f6a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102f70:	8b 43 48             	mov    0x48(%ebx),%eax
f0102f73:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102f78:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102f7d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102f82:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102f85:	89 da                	mov    %ebx,%edx
f0102f87:	2b 15 48 a2 22 f0    	sub    0xf022a248,%edx
f0102f8d:	c1 fa 02             	sar    $0x2,%edx
f0102f90:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0102f96:	09 d0                	or     %edx,%eax
f0102f98:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102f9b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f9e:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102fa1:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102fa8:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102faf:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102fb6:	83 ec 04             	sub    $0x4,%esp
f0102fb9:	6a 44                	push   $0x44
f0102fbb:	6a 00                	push   $0x0
f0102fbd:	53                   	push   %ebx
f0102fbe:	e8 a6 1c 00 00       	call   f0104c69 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102fc3:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102fc9:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102fcf:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102fd5:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102fdc:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0102fe2:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0102fe9:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0102fed:	8b 43 44             	mov    0x44(%ebx),%eax
f0102ff0:	a3 4c a2 22 f0       	mov    %eax,0xf022a24c
	*newenv_store = e;
f0102ff5:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ff8:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102ffa:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0102ffd:	e8 88 22 00 00       	call   f010528a <cpunum>
f0103002:	6b c0 74             	imul   $0x74,%eax,%eax
f0103005:	83 c4 10             	add    $0x10,%esp
f0103008:	ba 00 00 00 00       	mov    $0x0,%edx
f010300d:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103014:	74 11                	je     f0103027 <env_alloc+0x15e>
f0103016:	e8 6f 22 00 00       	call   f010528a <cpunum>
f010301b:	6b c0 74             	imul   $0x74,%eax,%eax
f010301e:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103024:	8b 50 48             	mov    0x48(%eax),%edx
f0103027:	83 ec 04             	sub    $0x4,%esp
f010302a:	53                   	push   %ebx
f010302b:	52                   	push   %edx
f010302c:	68 35 6b 10 f0       	push   $0xf0106b35
f0103031:	e8 38 06 00 00       	call   f010366e <cprintf>
	return 0;
f0103036:	83 c4 10             	add    $0x10,%esp
f0103039:	b8 00 00 00 00       	mov    $0x0,%eax
f010303e:	eb 0c                	jmp    f010304c <env_alloc+0x183>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103040:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103045:	eb 05                	jmp    f010304c <env_alloc+0x183>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103047:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f010304c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010304f:	5b                   	pop    %ebx
f0103050:	5e                   	pop    %esi
f0103051:	5d                   	pop    %ebp
f0103052:	c3                   	ret    

f0103053 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103053:	55                   	push   %ebp
f0103054:	89 e5                	mov    %esp,%ebp
f0103056:	57                   	push   %edi
f0103057:	56                   	push   %esi
f0103058:	53                   	push   %ebx
f0103059:	83 ec 34             	sub    $0x34,%esp
f010305c:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int r;
	r = env_alloc(&e, 0);
f010305f:	6a 00                	push   $0x0
f0103061:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103064:	50                   	push   %eax
f0103065:	e8 5f fe ff ff       	call   f0102ec9 <env_alloc>
	if(r != 0)
f010306a:	83 c4 10             	add    $0x10,%esp
f010306d:	85 c0                	test   %eax,%eax
f010306f:	74 15                	je     f0103086 <env_create+0x33>
		panic("env_create: %e", r);
f0103071:	50                   	push   %eax
f0103072:	68 4a 6b 10 f0       	push   $0xf0106b4a
f0103077:	68 ad 01 00 00       	push   $0x1ad
f010307c:	68 19 6b 10 f0       	push   $0xf0106b19
f0103081:	e8 ba cf ff ff       	call   f0100040 <_panic>
	//if(env_alloc(&e,0) != 0)
	//	panic("env_alloc fail");
	e->env_type = type;
f0103086:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103089:	89 c2                	mov    %eax,%edx
f010308b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010308e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103091:	89 42 50             	mov    %eax,0x50(%edx)
	struct Elf *elf;
	// 强制类型转换，将binary后的内存空间内容按照结构ELF的格式读取
	elf = (struct Elf *)binary;
	// is this a valid ELF? 判断是否是ELF
	// ELF头开头的结构体叫做魔数,是一个16位的数组
	if(elf->e_magic != ELF_MAGIC)
f0103094:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f010309a:	74 17                	je     f01030b3 <env_create+0x60>
		panic("load segements fail");
f010309c:	83 ec 04             	sub    $0x4,%esp
f010309f:	68 59 6b 10 f0       	push   $0xf0106b59
f01030a4:	68 7a 01 00 00       	push   $0x17a
f01030a9:	68 19 6b 10 f0       	push   $0xf0106b19
f01030ae:	e8 8d cf ff ff       	call   f0100040 <_panic>
	// load each program segment (ignores ph flags)
	// e_phoff 程序头表的文件偏移地址
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
f01030b3:	89 fb                	mov    %edi,%ebx
f01030b5:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f01030b8:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01030bc:	c1 e6 05             	shl    $0x5,%esi
f01030bf:	01 de                	add    %ebx,%esi
	// 因为后面需要访问刚分配的内存，所以需要将env_pgdir装入cr3，使二级页表能够运作
	lcr3(PADDR(e->env_pgdir));
f01030c1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030c4:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030c7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030cc:	77 15                	ja     f01030e3 <env_create+0x90>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030ce:	50                   	push   %eax
f01030cf:	68 68 59 10 f0       	push   $0xf0105968
f01030d4:	68 80 01 00 00       	push   $0x180
f01030d9:	68 19 6b 10 f0       	push   $0xf0106b19
f01030de:	e8 5d cf ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01030e3:	05 00 00 00 10       	add    $0x10000000,%eax
f01030e8:	0f 22 d8             	mov    %eax,%cr3
f01030eb:	eb 60                	jmp    f010314d <env_create+0xfa>

	for (; ph < eph; ph++)
	{
		// 	(The ELF header should have ph->p_filesz <= ph->p_memsz.)
		if(ph->p_filesz > ph->p_memsz)
f01030ed:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01030f0:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f01030f3:	76 17                	jbe    f010310c <env_create+0xb9>
			panic("memory is not enough for file");
f01030f5:	83 ec 04             	sub    $0x4,%esp
f01030f8:	68 6d 6b 10 f0       	push   $0xf0106b6d
f01030fd:	68 86 01 00 00       	push   $0x186
f0103102:	68 19 6b 10 f0       	push   $0xf0106b19
f0103107:	e8 34 cf ff ff       	call   f0100040 <_panic>
		if(ph->p_type == ELF_PROG_LOAD)
f010310c:	83 3b 01             	cmpl   $0x1,(%ebx)
f010310f:	75 39                	jne    f010314a <env_create+0xf7>
		{
		//  Each segment's virtual address can be found in ph->p_va
		//  and its size in memory can be found in ph->p_memsz.
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0103111:	8b 53 08             	mov    0x8(%ebx),%edx
f0103114:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103117:	e8 1e fc ff ff       	call   f0102d3a <region_alloc>
		//  The ph->p_filesz bytes from the ELF binary, starting at
		//  'binary + ph->p_offset', should be copied to virtual address
		//  ph->p_va. 
			//memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f010311c:	83 ec 04             	sub    $0x4,%esp
f010311f:	ff 73 10             	pushl  0x10(%ebx)
f0103122:	89 f8                	mov    %edi,%eax
f0103124:	03 43 04             	add    0x4(%ebx),%eax
f0103127:	50                   	push   %eax
f0103128:	ff 73 08             	pushl  0x8(%ebx)
f010312b:	e8 86 1b 00 00       	call   f0104cb6 <memmove>
        //	Any remaining memory bytes should be cleared to zero.
		    memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
f0103130:	8b 43 10             	mov    0x10(%ebx),%eax
f0103133:	83 c4 0c             	add    $0xc,%esp
f0103136:	8b 53 14             	mov    0x14(%ebx),%edx
f0103139:	29 c2                	sub    %eax,%edx
f010313b:	52                   	push   %edx
f010313c:	6a 00                	push   $0x0
f010313e:	03 43 08             	add    0x8(%ebx),%eax
f0103141:	50                   	push   %eax
f0103142:	e8 22 1b 00 00       	call   f0104c69 <memset>
f0103147:	83 c4 10             	add    $0x10,%esp
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
	eph = ph + elf->e_phnum;
	// 因为后面需要访问刚分配的内存，所以需要将env_pgdir装入cr3，使二级页表能够运作
	lcr3(PADDR(e->env_pgdir));

	for (; ph < eph; ph++)
f010314a:	83 c3 20             	add    $0x20,%ebx
f010314d:	39 de                	cmp    %ebx,%esi
f010314f:	77 9c                	ja     f01030ed <env_create+0x9a>
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
        //	Any remaining memory bytes should be cleared to zero.
		    memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
		}
	}
	e->env_tf.tf_eip = elf->e_entry;
f0103151:	8b 47 18             	mov    0x18(%edi),%eax
f0103154:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103157:	89 47 30             	mov    %eax,0x30(%edi)
	lcr3(PADDR(kern_pgdir));
f010315a:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010315f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103164:	77 15                	ja     f010317b <env_create+0x128>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103166:	50                   	push   %eax
f0103167:	68 68 59 10 f0       	push   $0xf0105968
f010316c:	68 96 01 00 00       	push   $0x196
f0103171:	68 19 6b 10 f0       	push   $0xf0106b19
f0103176:	e8 c5 ce ff ff       	call   f0100040 <_panic>
f010317b:	05 00 00 00 10       	add    $0x10000000,%eax
f0103180:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *) USTACKTOP-PGSIZE, PGSIZE);
f0103183:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103188:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f010318d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103190:	e8 a5 fb ff ff       	call   f0102d3a <region_alloc>
		panic("env_create: %e", r);
	//if(env_alloc(&e,0) != 0)
	//	panic("env_alloc fail");
	e->env_type = type;
	load_icode(e, binary);
}
f0103195:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103198:	5b                   	pop    %ebx
f0103199:	5e                   	pop    %esi
f010319a:	5f                   	pop    %edi
f010319b:	5d                   	pop    %ebp
f010319c:	c3                   	ret    

f010319d <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f010319d:	55                   	push   %ebp
f010319e:	89 e5                	mov    %esp,%ebp
f01031a0:	57                   	push   %edi
f01031a1:	56                   	push   %esi
f01031a2:	53                   	push   %ebx
f01031a3:	83 ec 1c             	sub    $0x1c,%esp
f01031a6:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01031a9:	e8 dc 20 00 00       	call   f010528a <cpunum>
f01031ae:	6b c0 74             	imul   $0x74,%eax,%eax
f01031b1:	39 b8 28 b0 22 f0    	cmp    %edi,-0xfdd4fd8(%eax)
f01031b7:	75 29                	jne    f01031e2 <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f01031b9:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031be:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031c3:	77 15                	ja     f01031da <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031c5:	50                   	push   %eax
f01031c6:	68 68 59 10 f0       	push   $0xf0105968
f01031cb:	68 c2 01 00 00       	push   $0x1c2
f01031d0:	68 19 6b 10 f0       	push   $0xf0106b19
f01031d5:	e8 66 ce ff ff       	call   f0100040 <_panic>
f01031da:	05 00 00 00 10       	add    $0x10000000,%eax
f01031df:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01031e2:	8b 5f 48             	mov    0x48(%edi),%ebx
f01031e5:	e8 a0 20 00 00       	call   f010528a <cpunum>
f01031ea:	6b c0 74             	imul   $0x74,%eax,%eax
f01031ed:	ba 00 00 00 00       	mov    $0x0,%edx
f01031f2:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f01031f9:	74 11                	je     f010320c <env_free+0x6f>
f01031fb:	e8 8a 20 00 00       	call   f010528a <cpunum>
f0103200:	6b c0 74             	imul   $0x74,%eax,%eax
f0103203:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103209:	8b 50 48             	mov    0x48(%eax),%edx
f010320c:	83 ec 04             	sub    $0x4,%esp
f010320f:	53                   	push   %ebx
f0103210:	52                   	push   %edx
f0103211:	68 8b 6b 10 f0       	push   $0xf0106b8b
f0103216:	e8 53 04 00 00       	call   f010366e <cprintf>
f010321b:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010321e:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103225:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103228:	89 d0                	mov    %edx,%eax
f010322a:	c1 e0 02             	shl    $0x2,%eax
f010322d:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103230:	8b 47 60             	mov    0x60(%edi),%eax
f0103233:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103236:	f7 c6 01 00 00 00    	test   $0x1,%esi
f010323c:	0f 84 a8 00 00 00    	je     f01032ea <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103242:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103248:	89 f0                	mov    %esi,%eax
f010324a:	c1 e8 0c             	shr    $0xc,%eax
f010324d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103250:	39 05 88 ae 22 f0    	cmp    %eax,0xf022ae88
f0103256:	77 15                	ja     f010326d <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103258:	56                   	push   %esi
f0103259:	68 44 59 10 f0       	push   $0xf0105944
f010325e:	68 d1 01 00 00       	push   $0x1d1
f0103263:	68 19 6b 10 f0       	push   $0xf0106b19
f0103268:	e8 d3 cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010326d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103270:	c1 e0 16             	shl    $0x16,%eax
f0103273:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103276:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f010327b:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103282:	01 
f0103283:	74 17                	je     f010329c <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103285:	83 ec 08             	sub    $0x8,%esp
f0103288:	89 d8                	mov    %ebx,%eax
f010328a:	c1 e0 0c             	shl    $0xc,%eax
f010328d:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103290:	50                   	push   %eax
f0103291:	ff 77 60             	pushl  0x60(%edi)
f0103294:	e8 72 de ff ff       	call   f010110b <page_remove>
f0103299:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010329c:	83 c3 01             	add    $0x1,%ebx
f010329f:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01032a5:	75 d4                	jne    f010327b <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01032a7:	8b 47 60             	mov    0x60(%edi),%eax
f01032aa:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01032ad:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01032b4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01032b7:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f01032bd:	72 14                	jb     f01032d3 <env_free+0x136>
		panic("pa2page called with invalid pa");
f01032bf:	83 ec 04             	sub    $0x4,%esp
f01032c2:	68 a8 5f 10 f0       	push   $0xf0105fa8
f01032c7:	6a 51                	push   $0x51
f01032c9:	68 ed 67 10 f0       	push   $0xf01067ed
f01032ce:	e8 6d cd ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01032d3:	83 ec 0c             	sub    $0xc,%esp
f01032d6:	a1 90 ae 22 f0       	mov    0xf022ae90,%eax
f01032db:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01032de:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01032e1:	50                   	push   %eax
f01032e2:	e8 5e dc ff ff       	call   f0100f45 <page_decref>
f01032e7:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01032ea:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01032ee:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032f1:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01032f6:	0f 85 29 ff ff ff    	jne    f0103225 <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01032fc:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01032ff:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103304:	77 15                	ja     f010331b <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103306:	50                   	push   %eax
f0103307:	68 68 59 10 f0       	push   $0xf0105968
f010330c:	68 df 01 00 00       	push   $0x1df
f0103311:	68 19 6b 10 f0       	push   $0xf0106b19
f0103316:	e8 25 cd ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f010331b:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103322:	05 00 00 00 10       	add    $0x10000000,%eax
f0103327:	c1 e8 0c             	shr    $0xc,%eax
f010332a:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f0103330:	72 14                	jb     f0103346 <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f0103332:	83 ec 04             	sub    $0x4,%esp
f0103335:	68 a8 5f 10 f0       	push   $0xf0105fa8
f010333a:	6a 51                	push   $0x51
f010333c:	68 ed 67 10 f0       	push   $0xf01067ed
f0103341:	e8 fa cc ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103346:	83 ec 0c             	sub    $0xc,%esp
f0103349:	8b 15 90 ae 22 f0    	mov    0xf022ae90,%edx
f010334f:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103352:	50                   	push   %eax
f0103353:	e8 ed db ff ff       	call   f0100f45 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103358:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f010335f:	a1 4c a2 22 f0       	mov    0xf022a24c,%eax
f0103364:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103367:	89 3d 4c a2 22 f0    	mov    %edi,0xf022a24c
}
f010336d:	83 c4 10             	add    $0x10,%esp
f0103370:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103373:	5b                   	pop    %ebx
f0103374:	5e                   	pop    %esi
f0103375:	5f                   	pop    %edi
f0103376:	5d                   	pop    %ebp
f0103377:	c3                   	ret    

f0103378 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103378:	55                   	push   %ebp
f0103379:	89 e5                	mov    %esp,%ebp
f010337b:	53                   	push   %ebx
f010337c:	83 ec 04             	sub    $0x4,%esp
f010337f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103382:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103386:	75 19                	jne    f01033a1 <env_destroy+0x29>
f0103388:	e8 fd 1e 00 00       	call   f010528a <cpunum>
f010338d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103390:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f0103396:	74 09                	je     f01033a1 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103398:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f010339f:	eb 33                	jmp    f01033d4 <env_destroy+0x5c>
	}

	env_free(e);
f01033a1:	83 ec 0c             	sub    $0xc,%esp
f01033a4:	53                   	push   %ebx
f01033a5:	e8 f3 fd ff ff       	call   f010319d <env_free>

	if (curenv == e) {
f01033aa:	e8 db 1e 00 00       	call   f010528a <cpunum>
f01033af:	6b c0 74             	imul   $0x74,%eax,%eax
f01033b2:	83 c4 10             	add    $0x10,%esp
f01033b5:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f01033bb:	75 17                	jne    f01033d4 <env_destroy+0x5c>
		curenv = NULL;
f01033bd:	e8 c8 1e 00 00       	call   f010528a <cpunum>
f01033c2:	6b c0 74             	imul   $0x74,%eax,%eax
f01033c5:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f01033cc:	00 00 00 
		sched_yield();
f01033cf:	e8 48 0c 00 00       	call   f010401c <sched_yield>
	}
}
f01033d4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01033d7:	c9                   	leave  
f01033d8:	c3                   	ret    

f01033d9 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01033d9:	55                   	push   %ebp
f01033da:	89 e5                	mov    %esp,%ebp
f01033dc:	53                   	push   %ebx
f01033dd:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01033e0:	e8 a5 1e 00 00       	call   f010528a <cpunum>
f01033e5:	6b c0 74             	imul   $0x74,%eax,%eax
f01033e8:	8b 98 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%ebx
f01033ee:	e8 97 1e 00 00       	call   f010528a <cpunum>
f01033f3:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f01033f6:	8b 65 08             	mov    0x8(%ebp),%esp
f01033f9:	61                   	popa   
f01033fa:	07                   	pop    %es
f01033fb:	1f                   	pop    %ds
f01033fc:	83 c4 08             	add    $0x8,%esp
f01033ff:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103400:	83 ec 04             	sub    $0x4,%esp
f0103403:	68 a1 6b 10 f0       	push   $0xf0106ba1
f0103408:	68 15 02 00 00       	push   $0x215
f010340d:	68 19 6b 10 f0       	push   $0xf0106b19
f0103412:	e8 29 cc ff ff       	call   f0100040 <_panic>

f0103417 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103417:	55                   	push   %ebp
f0103418:	89 e5                	mov    %esp,%ebp
f010341a:	53                   	push   %ebx
f010341b:	83 ec 04             	sub    $0x4,%esp
f010341e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv && curenv->env_status == ENV_RUNNING)
f0103421:	e8 64 1e 00 00       	call   f010528a <cpunum>
f0103426:	6b c0 74             	imul   $0x74,%eax,%eax
f0103429:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103430:	74 29                	je     f010345b <env_run+0x44>
f0103432:	e8 53 1e 00 00       	call   f010528a <cpunum>
f0103437:	6b c0 74             	imul   $0x74,%eax,%eax
f010343a:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103440:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103444:	75 15                	jne    f010345b <env_run+0x44>
		curenv->env_status = ENV_RUNNABLE;
f0103446:	e8 3f 1e 00 00       	call   f010528a <cpunum>
f010344b:	6b c0 74             	imul   $0x74,%eax,%eax
f010344e:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103454:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	curenv = e;
f010345b:	e8 2a 1e 00 00       	call   f010528a <cpunum>
f0103460:	6b c0 74             	imul   $0x74,%eax,%eax
f0103463:	89 98 28 b0 22 f0    	mov    %ebx,-0xfdd4fd8(%eax)
	curenv->env_status = ENV_RUNNING;
f0103469:	e8 1c 1e 00 00       	call   f010528a <cpunum>
f010346e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103471:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103477:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f010347e:	e8 07 1e 00 00       	call   f010528a <cpunum>
f0103483:	6b c0 74             	imul   $0x74,%eax,%eax
f0103486:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010348c:	83 40 58 01          	addl   $0x1,0x58(%eax)
	cprintf("%o \n",(physaddr_t)curenv->env_pgdir);
f0103490:	e8 f5 1d 00 00       	call   f010528a <cpunum>
f0103495:	83 ec 08             	sub    $0x8,%esp
f0103498:	6b c0 74             	imul   $0x74,%eax,%eax
f010349b:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01034a1:	ff 70 60             	pushl  0x60(%eax)
f01034a4:	68 ad 6b 10 f0       	push   $0xf0106bad
f01034a9:	e8 c0 01 00 00       	call   f010366e <cprintf>
	lcr3(PADDR(curenv->env_pgdir));
f01034ae:	e8 d7 1d 00 00       	call   f010528a <cpunum>
f01034b3:	6b c0 74             	imul   $0x74,%eax,%eax
f01034b6:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01034bc:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034bf:	83 c4 10             	add    $0x10,%esp
f01034c2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034c7:	77 15                	ja     f01034de <env_run+0xc7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034c9:	50                   	push   %eax
f01034ca:	68 68 59 10 f0       	push   $0xf0105968
f01034cf:	68 39 02 00 00       	push   $0x239
f01034d4:	68 19 6b 10 f0       	push   $0xf0106b19
f01034d9:	e8 62 cb ff ff       	call   f0100040 <_panic>
f01034de:	05 00 00 00 10       	add    $0x10000000,%eax
f01034e3:	0f 22 d8             	mov    %eax,%cr3

	env_pop_tf(&e->env_tf);
f01034e6:	83 ec 0c             	sub    $0xc,%esp
f01034e9:	53                   	push   %ebx
f01034ea:	e8 ea fe ff ff       	call   f01033d9 <env_pop_tf>

f01034ef <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01034ef:	55                   	push   %ebp
f01034f0:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01034f2:	ba 70 00 00 00       	mov    $0x70,%edx
f01034f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01034fa:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01034fb:	ba 71 00 00 00       	mov    $0x71,%edx
f0103500:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103501:	0f b6 c0             	movzbl %al,%eax
}
f0103504:	5d                   	pop    %ebp
f0103505:	c3                   	ret    

f0103506 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103506:	55                   	push   %ebp
f0103507:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103509:	ba 70 00 00 00       	mov    $0x70,%edx
f010350e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103511:	ee                   	out    %al,(%dx)
f0103512:	ba 71 00 00 00       	mov    $0x71,%edx
f0103517:	8b 45 0c             	mov    0xc(%ebp),%eax
f010351a:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010351b:	5d                   	pop    %ebp
f010351c:	c3                   	ret    

f010351d <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f010351d:	55                   	push   %ebp
f010351e:	89 e5                	mov    %esp,%ebp
f0103520:	56                   	push   %esi
f0103521:	53                   	push   %ebx
f0103522:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103525:	66 a3 a8 f3 11 f0    	mov    %ax,0xf011f3a8
	if (!didinit)
f010352b:	80 3d 50 a2 22 f0 00 	cmpb   $0x0,0xf022a250
f0103532:	74 5a                	je     f010358e <irq_setmask_8259A+0x71>
f0103534:	89 c6                	mov    %eax,%esi
f0103536:	ba 21 00 00 00       	mov    $0x21,%edx
f010353b:	ee                   	out    %al,(%dx)
f010353c:	66 c1 e8 08          	shr    $0x8,%ax
f0103540:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103545:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f0103546:	83 ec 0c             	sub    $0xc,%esp
f0103549:	68 b2 6b 10 f0       	push   $0xf0106bb2
f010354e:	e8 1b 01 00 00       	call   f010366e <cprintf>
f0103553:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103556:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f010355b:	0f b7 f6             	movzwl %si,%esi
f010355e:	f7 d6                	not    %esi
f0103560:	0f a3 de             	bt     %ebx,%esi
f0103563:	73 11                	jae    f0103576 <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f0103565:	83 ec 08             	sub    $0x8,%esp
f0103568:	53                   	push   %ebx
f0103569:	68 45 70 10 f0       	push   $0xf0107045
f010356e:	e8 fb 00 00 00       	call   f010366e <cprintf>
f0103573:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103576:	83 c3 01             	add    $0x1,%ebx
f0103579:	83 fb 10             	cmp    $0x10,%ebx
f010357c:	75 e2                	jne    f0103560 <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f010357e:	83 ec 0c             	sub    $0xc,%esp
f0103581:	68 a9 5c 10 f0       	push   $0xf0105ca9
f0103586:	e8 e3 00 00 00       	call   f010366e <cprintf>
f010358b:	83 c4 10             	add    $0x10,%esp
}
f010358e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103591:	5b                   	pop    %ebx
f0103592:	5e                   	pop    %esi
f0103593:	5d                   	pop    %ebp
f0103594:	c3                   	ret    

f0103595 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f0103595:	c6 05 50 a2 22 f0 01 	movb   $0x1,0xf022a250
f010359c:	ba 21 00 00 00       	mov    $0x21,%edx
f01035a1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01035a6:	ee                   	out    %al,(%dx)
f01035a7:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035ac:	ee                   	out    %al,(%dx)
f01035ad:	ba 20 00 00 00       	mov    $0x20,%edx
f01035b2:	b8 11 00 00 00       	mov    $0x11,%eax
f01035b7:	ee                   	out    %al,(%dx)
f01035b8:	ba 21 00 00 00       	mov    $0x21,%edx
f01035bd:	b8 20 00 00 00       	mov    $0x20,%eax
f01035c2:	ee                   	out    %al,(%dx)
f01035c3:	b8 04 00 00 00       	mov    $0x4,%eax
f01035c8:	ee                   	out    %al,(%dx)
f01035c9:	b8 03 00 00 00       	mov    $0x3,%eax
f01035ce:	ee                   	out    %al,(%dx)
f01035cf:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035d4:	b8 11 00 00 00       	mov    $0x11,%eax
f01035d9:	ee                   	out    %al,(%dx)
f01035da:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035df:	b8 28 00 00 00       	mov    $0x28,%eax
f01035e4:	ee                   	out    %al,(%dx)
f01035e5:	b8 02 00 00 00       	mov    $0x2,%eax
f01035ea:	ee                   	out    %al,(%dx)
f01035eb:	b8 01 00 00 00       	mov    $0x1,%eax
f01035f0:	ee                   	out    %al,(%dx)
f01035f1:	ba 20 00 00 00       	mov    $0x20,%edx
f01035f6:	b8 68 00 00 00       	mov    $0x68,%eax
f01035fb:	ee                   	out    %al,(%dx)
f01035fc:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103601:	ee                   	out    %al,(%dx)
f0103602:	ba a0 00 00 00       	mov    $0xa0,%edx
f0103607:	b8 68 00 00 00       	mov    $0x68,%eax
f010360c:	ee                   	out    %al,(%dx)
f010360d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103612:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0103613:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f010361a:	66 83 f8 ff          	cmp    $0xffff,%ax
f010361e:	74 13                	je     f0103633 <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103620:	55                   	push   %ebp
f0103621:	89 e5                	mov    %esp,%ebp
f0103623:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103626:	0f b7 c0             	movzwl %ax,%eax
f0103629:	50                   	push   %eax
f010362a:	e8 ee fe ff ff       	call   f010351d <irq_setmask_8259A>
f010362f:	83 c4 10             	add    $0x10,%esp
}
f0103632:	c9                   	leave  
f0103633:	f3 c3                	repz ret 

f0103635 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103635:	55                   	push   %ebp
f0103636:	89 e5                	mov    %esp,%ebp
f0103638:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010363b:	ff 75 08             	pushl  0x8(%ebp)
f010363e:	e8 fb d0 ff ff       	call   f010073e <cputchar>
	*cnt++;
}
f0103643:	83 c4 10             	add    $0x10,%esp
f0103646:	c9                   	leave  
f0103647:	c3                   	ret    

f0103648 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103648:	55                   	push   %ebp
f0103649:	89 e5                	mov    %esp,%ebp
f010364b:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010364e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103655:	ff 75 0c             	pushl  0xc(%ebp)
f0103658:	ff 75 08             	pushl  0x8(%ebp)
f010365b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010365e:	50                   	push   %eax
f010365f:	68 35 36 10 f0       	push   $0xf0103635
f0103664:	e8 94 0f 00 00       	call   f01045fd <vprintfmt>
	return cnt;
}
f0103669:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010366c:	c9                   	leave  
f010366d:	c3                   	ret    

f010366e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010366e:	55                   	push   %ebp
f010366f:	89 e5                	mov    %esp,%ebp
f0103671:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103674:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103677:	50                   	push   %eax
f0103678:	ff 75 08             	pushl  0x8(%ebp)
f010367b:	e8 c8 ff ff ff       	call   f0103648 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103680:	c9                   	leave  
f0103681:	c3                   	ret    

f0103682 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103682:	55                   	push   %ebp
f0103683:	89 e5                	mov    %esp,%ebp
f0103685:	57                   	push   %edi
f0103686:	56                   	push   %esi
f0103687:	53                   	push   %ebx
f0103688:	83 ec 0c             	sub    $0xc,%esp
	// get a triple fault.  If you set up an individual CPU's TSS
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//
	// LAB 4: Your code here:
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - thiscpu->cpu_id*(KSTKSIZE + KSTKGAP);
f010368b:	e8 fa 1b 00 00       	call   f010528a <cpunum>
f0103690:	89 c3                	mov    %eax,%ebx
f0103692:	e8 f3 1b 00 00       	call   f010528a <cpunum>
f0103697:	6b d3 74             	imul   $0x74,%ebx,%edx
f010369a:	6b c0 74             	imul   $0x74,%eax,%eax
f010369d:	0f b6 88 20 b0 22 f0 	movzbl -0xfdd4fe0(%eax),%ecx
f01036a4:	c1 e1 10             	shl    $0x10,%ecx
f01036a7:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
f01036ac:	29 c8                	sub    %ecx,%eax
f01036ae:	89 82 30 b0 22 f0    	mov    %eax,-0xfdd4fd0(%edx)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f01036b4:	e8 d1 1b 00 00       	call   f010528a <cpunum>
f01036b9:	6b c0 74             	imul   $0x74,%eax,%eax
f01036bc:	66 c7 80 34 b0 22 f0 	movw   $0x10,-0xfdd4fcc(%eax)
f01036c3:	10 00 
	// when we trap to the kernel.
	//ts.ts_esp0 = KSTACKTOP;
	//ts.ts_ss0 = GD_KD;

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + cpunum()] = SEG16(STS_T32A, (uint32_t) (&(thiscpu->cpu_ts)),
f01036c5:	e8 c0 1b 00 00       	call   f010528a <cpunum>
f01036ca:	8d 58 05             	lea    0x5(%eax),%ebx
f01036cd:	e8 b8 1b 00 00       	call   f010528a <cpunum>
f01036d2:	89 c7                	mov    %eax,%edi
f01036d4:	e8 b1 1b 00 00       	call   f010528a <cpunum>
f01036d9:	89 c6                	mov    %eax,%esi
f01036db:	e8 aa 1b 00 00       	call   f010528a <cpunum>
f01036e0:	66 c7 04 dd 40 f3 11 	movw   $0x67,-0xfee0cc0(,%ebx,8)
f01036e7:	f0 67 00 
f01036ea:	6b ff 74             	imul   $0x74,%edi,%edi
f01036ed:	81 c7 2c b0 22 f0    	add    $0xf022b02c,%edi
f01036f3:	66 89 3c dd 42 f3 11 	mov    %di,-0xfee0cbe(,%ebx,8)
f01036fa:	f0 
f01036fb:	6b d6 74             	imul   $0x74,%esi,%edx
f01036fe:	81 c2 2c b0 22 f0    	add    $0xf022b02c,%edx
f0103704:	c1 ea 10             	shr    $0x10,%edx
f0103707:	88 14 dd 44 f3 11 f0 	mov    %dl,-0xfee0cbc(,%ebx,8)
f010370e:	c6 04 dd 45 f3 11 f0 	movb   $0x99,-0xfee0cbb(,%ebx,8)
f0103715:	99 
f0103716:	c6 04 dd 46 f3 11 f0 	movb   $0x40,-0xfee0cba(,%ebx,8)
f010371d:	40 
f010371e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103721:	05 2c b0 22 f0       	add    $0xf022b02c,%eax
f0103726:	c1 e8 18             	shr    $0x18,%eax
f0103729:	88 04 dd 47 f3 11 f0 	mov    %al,-0xfee0cb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + cpunum()].sd_s = 0;
f0103730:	e8 55 1b 00 00       	call   f010528a <cpunum>
f0103735:	80 24 c5 6d f3 11 f0 	andb   $0xef,-0xfee0c93(,%eax,8)
f010373c:	ef 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (cpunum() << 3));
f010373d:	e8 48 1b 00 00       	call   f010528a <cpunum>
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0103742:	8d 04 c5 28 00 00 00 	lea    0x28(,%eax,8),%eax
f0103749:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f010374c:	b8 ac f3 11 f0       	mov    $0xf011f3ac,%eax
f0103751:	0f 01 18             	lidtl  (%eax)

	// Load the IDT
	lidt(&idt_pd);
}
f0103754:	83 c4 0c             	add    $0xc,%esp
f0103757:	5b                   	pop    %ebx
f0103758:	5e                   	pop    %esi
f0103759:	5f                   	pop    %edi
f010375a:	5d                   	pop    %ebp
f010375b:	c3                   	ret    

f010375c <trap_init>:
}


void
trap_init(void)
{
f010375c:	55                   	push   %ebp
f010375d:	89 e5                	mov    %esp,%ebp
f010375f:	83 ec 08             	sub    $0x8,%esp
	
	void floating_point_error();

	void system_call();

	SETGATE(idt[T_DIVIDE], 1, GD_KT, divide_error, 0);
f0103762:	b8 e2 3e 10 f0       	mov    $0xf0103ee2,%eax
f0103767:	66 a3 60 a2 22 f0    	mov    %ax,0xf022a260
f010376d:	66 c7 05 62 a2 22 f0 	movw   $0x8,0xf022a262
f0103774:	08 00 
f0103776:	c6 05 64 a2 22 f0 00 	movb   $0x0,0xf022a264
f010377d:	c6 05 65 a2 22 f0 8f 	movb   $0x8f,0xf022a265
f0103784:	c1 e8 10             	shr    $0x10,%eax
f0103787:	66 a3 66 a2 22 f0    	mov    %ax,0xf022a266
	SETGATE(idt[T_DEBUG], 1, GD_KT, debug_exception, 0);
f010378d:	b8 e8 3e 10 f0       	mov    $0xf0103ee8,%eax
f0103792:	66 a3 68 a2 22 f0    	mov    %ax,0xf022a268
f0103798:	66 c7 05 6a a2 22 f0 	movw   $0x8,0xf022a26a
f010379f:	08 00 
f01037a1:	c6 05 6c a2 22 f0 00 	movb   $0x0,0xf022a26c
f01037a8:	c6 05 6d a2 22 f0 8f 	movb   $0x8f,0xf022a26d
f01037af:	c1 e8 10             	shr    $0x10,%eax
f01037b2:	66 a3 6e a2 22 f0    	mov    %ax,0xf022a26e
	SETGATE(idt[T_NMI], 1, GD_KT, non_maskable_interrupt, 0);
f01037b8:	b8 ee 3e 10 f0       	mov    $0xf0103eee,%eax
f01037bd:	66 a3 70 a2 22 f0    	mov    %ax,0xf022a270
f01037c3:	66 c7 05 72 a2 22 f0 	movw   $0x8,0xf022a272
f01037ca:	08 00 
f01037cc:	c6 05 74 a2 22 f0 00 	movb   $0x0,0xf022a274
f01037d3:	c6 05 75 a2 22 f0 8f 	movb   $0x8f,0xf022a275
f01037da:	c1 e8 10             	shr    $0x10,%eax
f01037dd:	66 a3 76 a2 22 f0    	mov    %ax,0xf022a276
	SETGATE(idt[T_BRKPT], 1, GD_KT, break_point, 3);//!
f01037e3:	b8 f4 3e 10 f0       	mov    $0xf0103ef4,%eax
f01037e8:	66 a3 78 a2 22 f0    	mov    %ax,0xf022a278
f01037ee:	66 c7 05 7a a2 22 f0 	movw   $0x8,0xf022a27a
f01037f5:	08 00 
f01037f7:	c6 05 7c a2 22 f0 00 	movb   $0x0,0xf022a27c
f01037fe:	c6 05 7d a2 22 f0 ef 	movb   $0xef,0xf022a27d
f0103805:	c1 e8 10             	shr    $0x10,%eax
f0103808:	66 a3 7e a2 22 f0    	mov    %ax,0xf022a27e
	SETGATE(idt[T_OFLOW], 1, GD_KT, overflow, 0);
f010380e:	b8 fa 3e 10 f0       	mov    $0xf0103efa,%eax
f0103813:	66 a3 80 a2 22 f0    	mov    %ax,0xf022a280
f0103819:	66 c7 05 82 a2 22 f0 	movw   $0x8,0xf022a282
f0103820:	08 00 
f0103822:	c6 05 84 a2 22 f0 00 	movb   $0x0,0xf022a284
f0103829:	c6 05 85 a2 22 f0 8f 	movb   $0x8f,0xf022a285
f0103830:	c1 e8 10             	shr    $0x10,%eax
f0103833:	66 a3 86 a2 22 f0    	mov    %ax,0xf022a286
	SETGATE(idt[T_BOUND], 1, GD_KT, bounds_check, 0);
f0103839:	b8 00 3f 10 f0       	mov    $0xf0103f00,%eax
f010383e:	66 a3 88 a2 22 f0    	mov    %ax,0xf022a288
f0103844:	66 c7 05 8a a2 22 f0 	movw   $0x8,0xf022a28a
f010384b:	08 00 
f010384d:	c6 05 8c a2 22 f0 00 	movb   $0x0,0xf022a28c
f0103854:	c6 05 8d a2 22 f0 8f 	movb   $0x8f,0xf022a28d
f010385b:	c1 e8 10             	shr    $0x10,%eax
f010385e:	66 a3 8e a2 22 f0    	mov    %ax,0xf022a28e
	SETGATE(idt[T_ILLOP], 1, GD_KT, illegal_opcode, 0);
f0103864:	b8 06 3f 10 f0       	mov    $0xf0103f06,%eax
f0103869:	66 a3 90 a2 22 f0    	mov    %ax,0xf022a290
f010386f:	66 c7 05 92 a2 22 f0 	movw   $0x8,0xf022a292
f0103876:	08 00 
f0103878:	c6 05 94 a2 22 f0 00 	movb   $0x0,0xf022a294
f010387f:	c6 05 95 a2 22 f0 8f 	movb   $0x8f,0xf022a295
f0103886:	c1 e8 10             	shr    $0x10,%eax
f0103889:	66 a3 96 a2 22 f0    	mov    %ax,0xf022a296
	SETGATE(idt[T_DEVICE], 1, GD_KT, device_not_available, 0);
f010388f:	b8 0c 3f 10 f0       	mov    $0xf0103f0c,%eax
f0103894:	66 a3 98 a2 22 f0    	mov    %ax,0xf022a298
f010389a:	66 c7 05 9a a2 22 f0 	movw   $0x8,0xf022a29a
f01038a1:	08 00 
f01038a3:	c6 05 9c a2 22 f0 00 	movb   $0x0,0xf022a29c
f01038aa:	c6 05 9d a2 22 f0 8f 	movb   $0x8f,0xf022a29d
f01038b1:	c1 e8 10             	shr    $0x10,%eax
f01038b4:	66 a3 9e a2 22 f0    	mov    %ax,0xf022a29e
	SETGATE(idt[T_DBLFLT], 1, GD_KT, double_fault, 0);
f01038ba:	b8 12 3f 10 f0       	mov    $0xf0103f12,%eax
f01038bf:	66 a3 a0 a2 22 f0    	mov    %ax,0xf022a2a0
f01038c5:	66 c7 05 a2 a2 22 f0 	movw   $0x8,0xf022a2a2
f01038cc:	08 00 
f01038ce:	c6 05 a4 a2 22 f0 00 	movb   $0x0,0xf022a2a4
f01038d5:	c6 05 a5 a2 22 f0 8f 	movb   $0x8f,0xf022a2a5
f01038dc:	c1 e8 10             	shr    $0x10,%eax
f01038df:	66 a3 a6 a2 22 f0    	mov    %ax,0xf022a2a6

	SETGATE(idt[T_TSS], 1, GD_KT, invalid_task_switch_segment, 0);
f01038e5:	b8 16 3f 10 f0       	mov    $0xf0103f16,%eax
f01038ea:	66 a3 b0 a2 22 f0    	mov    %ax,0xf022a2b0
f01038f0:	66 c7 05 b2 a2 22 f0 	movw   $0x8,0xf022a2b2
f01038f7:	08 00 
f01038f9:	c6 05 b4 a2 22 f0 00 	movb   $0x0,0xf022a2b4
f0103900:	c6 05 b5 a2 22 f0 8f 	movb   $0x8f,0xf022a2b5
f0103907:	c1 e8 10             	shr    $0x10,%eax
f010390a:	66 a3 b6 a2 22 f0    	mov    %ax,0xf022a2b6
	SETGATE(idt[T_SEGNP], 1, GD_KT, segment_not_present, 0);
f0103910:	b8 1a 3f 10 f0       	mov    $0xf0103f1a,%eax
f0103915:	66 a3 b8 a2 22 f0    	mov    %ax,0xf022a2b8
f010391b:	66 c7 05 ba a2 22 f0 	movw   $0x8,0xf022a2ba
f0103922:	08 00 
f0103924:	c6 05 bc a2 22 f0 00 	movb   $0x0,0xf022a2bc
f010392b:	c6 05 bd a2 22 f0 8f 	movb   $0x8f,0xf022a2bd
f0103932:	c1 e8 10             	shr    $0x10,%eax
f0103935:	66 a3 be a2 22 f0    	mov    %ax,0xf022a2be
	SETGATE(idt[T_STACK], 1, GD_KT, stack_exception, 0);
f010393b:	b8 1e 3f 10 f0       	mov    $0xf0103f1e,%eax
f0103940:	66 a3 c0 a2 22 f0    	mov    %ax,0xf022a2c0
f0103946:	66 c7 05 c2 a2 22 f0 	movw   $0x8,0xf022a2c2
f010394d:	08 00 
f010394f:	c6 05 c4 a2 22 f0 00 	movb   $0x0,0xf022a2c4
f0103956:	c6 05 c5 a2 22 f0 8f 	movb   $0x8f,0xf022a2c5
f010395d:	c1 e8 10             	shr    $0x10,%eax
f0103960:	66 a3 c6 a2 22 f0    	mov    %ax,0xf022a2c6
	SETGATE(idt[T_GPFLT], 1, GD_KT, general_protection_fault, 0);
f0103966:	b8 22 3f 10 f0       	mov    $0xf0103f22,%eax
f010396b:	66 a3 c8 a2 22 f0    	mov    %ax,0xf022a2c8
f0103971:	66 c7 05 ca a2 22 f0 	movw   $0x8,0xf022a2ca
f0103978:	08 00 
f010397a:	c6 05 cc a2 22 f0 00 	movb   $0x0,0xf022a2cc
f0103981:	c6 05 cd a2 22 f0 8f 	movb   $0x8f,0xf022a2cd
f0103988:	c1 e8 10             	shr    $0x10,%eax
f010398b:	66 a3 ce a2 22 f0    	mov    %ax,0xf022a2ce
	SETGATE(idt[T_PGFLT], 1, GD_KT, page_fault, 0);
f0103991:	b8 26 3f 10 f0       	mov    $0xf0103f26,%eax
f0103996:	66 a3 d0 a2 22 f0    	mov    %ax,0xf022a2d0
f010399c:	66 c7 05 d2 a2 22 f0 	movw   $0x8,0xf022a2d2
f01039a3:	08 00 
f01039a5:	c6 05 d4 a2 22 f0 00 	movb   $0x0,0xf022a2d4
f01039ac:	c6 05 d5 a2 22 f0 8f 	movb   $0x8f,0xf022a2d5
f01039b3:	c1 e8 10             	shr    $0x10,%eax
f01039b6:	66 a3 d6 a2 22 f0    	mov    %ax,0xf022a2d6

	SETGATE(idt[T_FPERR], 1, GD_KT, floating_point_error, 0);
f01039bc:	b8 2a 3f 10 f0       	mov    $0xf0103f2a,%eax
f01039c1:	66 a3 e0 a2 22 f0    	mov    %ax,0xf022a2e0
f01039c7:	66 c7 05 e2 a2 22 f0 	movw   $0x8,0xf022a2e2
f01039ce:	08 00 
f01039d0:	c6 05 e4 a2 22 f0 00 	movb   $0x0,0xf022a2e4
f01039d7:	c6 05 e5 a2 22 f0 8f 	movb   $0x8f,0xf022a2e5
f01039de:	c1 e8 10             	shr    $0x10,%eax
f01039e1:	66 a3 e6 a2 22 f0    	mov    %ax,0xf022a2e6

	SETGATE(idt[T_SYSCALL], 0, GD_KT, system_call, 3);
f01039e7:	b8 30 3f 10 f0       	mov    $0xf0103f30,%eax
f01039ec:	66 a3 e0 a3 22 f0    	mov    %ax,0xf022a3e0
f01039f2:	66 c7 05 e2 a3 22 f0 	movw   $0x8,0xf022a3e2
f01039f9:	08 00 
f01039fb:	c6 05 e4 a3 22 f0 00 	movb   $0x0,0xf022a3e4
f0103a02:	c6 05 e5 a3 22 f0 ee 	movb   $0xee,0xf022a3e5
f0103a09:	c1 e8 10             	shr    $0x10,%eax
f0103a0c:	66 a3 e6 a3 22 f0    	mov    %ax,0xf022a3e6

	// Per-CPU setup 
	trap_init_percpu();
f0103a12:	e8 6b fc ff ff       	call   f0103682 <trap_init_percpu>
}
f0103a17:	c9                   	leave  
f0103a18:	c3                   	ret    

f0103a19 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103a19:	55                   	push   %ebp
f0103a1a:	89 e5                	mov    %esp,%ebp
f0103a1c:	53                   	push   %ebx
f0103a1d:	83 ec 0c             	sub    $0xc,%esp
f0103a20:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103a23:	ff 33                	pushl  (%ebx)
f0103a25:	68 c6 6b 10 f0       	push   $0xf0106bc6
f0103a2a:	e8 3f fc ff ff       	call   f010366e <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103a2f:	83 c4 08             	add    $0x8,%esp
f0103a32:	ff 73 04             	pushl  0x4(%ebx)
f0103a35:	68 d5 6b 10 f0       	push   $0xf0106bd5
f0103a3a:	e8 2f fc ff ff       	call   f010366e <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103a3f:	83 c4 08             	add    $0x8,%esp
f0103a42:	ff 73 08             	pushl  0x8(%ebx)
f0103a45:	68 e4 6b 10 f0       	push   $0xf0106be4
f0103a4a:	e8 1f fc ff ff       	call   f010366e <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103a4f:	83 c4 08             	add    $0x8,%esp
f0103a52:	ff 73 0c             	pushl  0xc(%ebx)
f0103a55:	68 f3 6b 10 f0       	push   $0xf0106bf3
f0103a5a:	e8 0f fc ff ff       	call   f010366e <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103a5f:	83 c4 08             	add    $0x8,%esp
f0103a62:	ff 73 10             	pushl  0x10(%ebx)
f0103a65:	68 02 6c 10 f0       	push   $0xf0106c02
f0103a6a:	e8 ff fb ff ff       	call   f010366e <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103a6f:	83 c4 08             	add    $0x8,%esp
f0103a72:	ff 73 14             	pushl  0x14(%ebx)
f0103a75:	68 11 6c 10 f0       	push   $0xf0106c11
f0103a7a:	e8 ef fb ff ff       	call   f010366e <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103a7f:	83 c4 08             	add    $0x8,%esp
f0103a82:	ff 73 18             	pushl  0x18(%ebx)
f0103a85:	68 20 6c 10 f0       	push   $0xf0106c20
f0103a8a:	e8 df fb ff ff       	call   f010366e <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103a8f:	83 c4 08             	add    $0x8,%esp
f0103a92:	ff 73 1c             	pushl  0x1c(%ebx)
f0103a95:	68 2f 6c 10 f0       	push   $0xf0106c2f
f0103a9a:	e8 cf fb ff ff       	call   f010366e <cprintf>
}
f0103a9f:	83 c4 10             	add    $0x10,%esp
f0103aa2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103aa5:	c9                   	leave  
f0103aa6:	c3                   	ret    

f0103aa7 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103aa7:	55                   	push   %ebp
f0103aa8:	89 e5                	mov    %esp,%ebp
f0103aaa:	56                   	push   %esi
f0103aab:	53                   	push   %ebx
f0103aac:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103aaf:	e8 d6 17 00 00       	call   f010528a <cpunum>
f0103ab4:	83 ec 04             	sub    $0x4,%esp
f0103ab7:	50                   	push   %eax
f0103ab8:	53                   	push   %ebx
f0103ab9:	68 93 6c 10 f0       	push   $0xf0106c93
f0103abe:	e8 ab fb ff ff       	call   f010366e <cprintf>
	print_regs(&tf->tf_regs);
f0103ac3:	89 1c 24             	mov    %ebx,(%esp)
f0103ac6:	e8 4e ff ff ff       	call   f0103a19 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103acb:	83 c4 08             	add    $0x8,%esp
f0103ace:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103ad2:	50                   	push   %eax
f0103ad3:	68 b1 6c 10 f0       	push   $0xf0106cb1
f0103ad8:	e8 91 fb ff ff       	call   f010366e <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103add:	83 c4 08             	add    $0x8,%esp
f0103ae0:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103ae4:	50                   	push   %eax
f0103ae5:	68 c4 6c 10 f0       	push   $0xf0106cc4
f0103aea:	e8 7f fb ff ff       	call   f010366e <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103aef:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103af2:	83 c4 10             	add    $0x10,%esp
f0103af5:	83 f8 13             	cmp    $0x13,%eax
f0103af8:	77 09                	ja     f0103b03 <print_trapframe+0x5c>
		return excnames[trapno];
f0103afa:	8b 14 85 60 6f 10 f0 	mov    -0xfef90a0(,%eax,4),%edx
f0103b01:	eb 1f                	jmp    f0103b22 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103b03:	83 f8 30             	cmp    $0x30,%eax
f0103b06:	74 15                	je     f0103b1d <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103b08:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103b0b:	83 fa 10             	cmp    $0x10,%edx
f0103b0e:	b9 5d 6c 10 f0       	mov    $0xf0106c5d,%ecx
f0103b13:	ba 4a 6c 10 f0       	mov    $0xf0106c4a,%edx
f0103b18:	0f 43 d1             	cmovae %ecx,%edx
f0103b1b:	eb 05                	jmp    f0103b22 <print_trapframe+0x7b>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103b1d:	ba 3e 6c 10 f0       	mov    $0xf0106c3e,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b22:	83 ec 04             	sub    $0x4,%esp
f0103b25:	52                   	push   %edx
f0103b26:	50                   	push   %eax
f0103b27:	68 d7 6c 10 f0       	push   $0xf0106cd7
f0103b2c:	e8 3d fb ff ff       	call   f010366e <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103b31:	83 c4 10             	add    $0x10,%esp
f0103b34:	3b 1d 60 aa 22 f0    	cmp    0xf022aa60,%ebx
f0103b3a:	75 1a                	jne    f0103b56 <print_trapframe+0xaf>
f0103b3c:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b40:	75 14                	jne    f0103b56 <print_trapframe+0xaf>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103b42:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103b45:	83 ec 08             	sub    $0x8,%esp
f0103b48:	50                   	push   %eax
f0103b49:	68 e9 6c 10 f0       	push   $0xf0106ce9
f0103b4e:	e8 1b fb ff ff       	call   f010366e <cprintf>
f0103b53:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103b56:	83 ec 08             	sub    $0x8,%esp
f0103b59:	ff 73 2c             	pushl  0x2c(%ebx)
f0103b5c:	68 f8 6c 10 f0       	push   $0xf0106cf8
f0103b61:	e8 08 fb ff ff       	call   f010366e <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103b66:	83 c4 10             	add    $0x10,%esp
f0103b69:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b6d:	75 49                	jne    f0103bb8 <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103b6f:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103b72:	89 c2                	mov    %eax,%edx
f0103b74:	83 e2 01             	and    $0x1,%edx
f0103b77:	ba 77 6c 10 f0       	mov    $0xf0106c77,%edx
f0103b7c:	b9 6c 6c 10 f0       	mov    $0xf0106c6c,%ecx
f0103b81:	0f 44 ca             	cmove  %edx,%ecx
f0103b84:	89 c2                	mov    %eax,%edx
f0103b86:	83 e2 02             	and    $0x2,%edx
f0103b89:	ba 89 6c 10 f0       	mov    $0xf0106c89,%edx
f0103b8e:	be 83 6c 10 f0       	mov    $0xf0106c83,%esi
f0103b93:	0f 45 d6             	cmovne %esi,%edx
f0103b96:	83 e0 04             	and    $0x4,%eax
f0103b99:	be a6 6d 10 f0       	mov    $0xf0106da6,%esi
f0103b9e:	b8 8e 6c 10 f0       	mov    $0xf0106c8e,%eax
f0103ba3:	0f 44 c6             	cmove  %esi,%eax
f0103ba6:	51                   	push   %ecx
f0103ba7:	52                   	push   %edx
f0103ba8:	50                   	push   %eax
f0103ba9:	68 06 6d 10 f0       	push   $0xf0106d06
f0103bae:	e8 bb fa ff ff       	call   f010366e <cprintf>
f0103bb3:	83 c4 10             	add    $0x10,%esp
f0103bb6:	eb 10                	jmp    f0103bc8 <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103bb8:	83 ec 0c             	sub    $0xc,%esp
f0103bbb:	68 a9 5c 10 f0       	push   $0xf0105ca9
f0103bc0:	e8 a9 fa ff ff       	call   f010366e <cprintf>
f0103bc5:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103bc8:	83 ec 08             	sub    $0x8,%esp
f0103bcb:	ff 73 30             	pushl  0x30(%ebx)
f0103bce:	68 15 6d 10 f0       	push   $0xf0106d15
f0103bd3:	e8 96 fa ff ff       	call   f010366e <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103bd8:	83 c4 08             	add    $0x8,%esp
f0103bdb:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103bdf:	50                   	push   %eax
f0103be0:	68 24 6d 10 f0       	push   $0xf0106d24
f0103be5:	e8 84 fa ff ff       	call   f010366e <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103bea:	83 c4 08             	add    $0x8,%esp
f0103bed:	ff 73 38             	pushl  0x38(%ebx)
f0103bf0:	68 37 6d 10 f0       	push   $0xf0106d37
f0103bf5:	e8 74 fa ff ff       	call   f010366e <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103bfa:	83 c4 10             	add    $0x10,%esp
f0103bfd:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c01:	74 25                	je     f0103c28 <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103c03:	83 ec 08             	sub    $0x8,%esp
f0103c06:	ff 73 3c             	pushl  0x3c(%ebx)
f0103c09:	68 46 6d 10 f0       	push   $0xf0106d46
f0103c0e:	e8 5b fa ff ff       	call   f010366e <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103c13:	83 c4 08             	add    $0x8,%esp
f0103c16:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103c1a:	50                   	push   %eax
f0103c1b:	68 55 6d 10 f0       	push   $0xf0106d55
f0103c20:	e8 49 fa ff ff       	call   f010366e <cprintf>
f0103c25:	83 c4 10             	add    $0x10,%esp
	}
}
f0103c28:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103c2b:	5b                   	pop    %ebx
f0103c2c:	5e                   	pop    %esi
f0103c2d:	5d                   	pop    %ebp
f0103c2e:	c3                   	ret    

f0103c2f <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103c2f:	55                   	push   %ebp
f0103c30:	89 e5                	mov    %esp,%ebp
f0103c32:	57                   	push   %edi
f0103c33:	56                   	push   %esi
f0103c34:	53                   	push   %ebx
f0103c35:	83 ec 0c             	sub    $0xc,%esp
f0103c38:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103c3b:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs & 3) == 0) //缺页中断发生在内核中
f0103c3e:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c42:	75 17                	jne    f0103c5b <page_fault_handler+0x2c>
    	panic("page fault happen in kernel mode!\n");
f0103c44:	83 ec 04             	sub    $0x4,%esp
f0103c47:	68 10 6f 10 f0       	push   $0xf0106f10
f0103c4c:	68 52 01 00 00       	push   $0x152
f0103c51:	68 68 6d 10 f0       	push   $0xf0106d68
f0103c56:	e8 e5 c3 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c5b:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103c5e:	e8 27 16 00 00       	call   f010528a <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c63:	57                   	push   %edi
f0103c64:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103c65:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c68:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103c6e:	ff 70 48             	pushl  0x48(%eax)
f0103c71:	68 34 6f 10 f0       	push   $0xf0106f34
f0103c76:	e8 f3 f9 ff ff       	call   f010366e <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103c7b:	89 1c 24             	mov    %ebx,(%esp)
f0103c7e:	e8 24 fe ff ff       	call   f0103aa7 <print_trapframe>
	env_destroy(curenv);
f0103c83:	e8 02 16 00 00       	call   f010528a <cpunum>
f0103c88:	83 c4 04             	add    $0x4,%esp
f0103c8b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c8e:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103c94:	e8 df f6 ff ff       	call   f0103378 <env_destroy>
}
f0103c99:	83 c4 10             	add    $0x10,%esp
f0103c9c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103c9f:	5b                   	pop    %ebx
f0103ca0:	5e                   	pop    %esi
f0103ca1:	5f                   	pop    %edi
f0103ca2:	5d                   	pop    %ebp
f0103ca3:	c3                   	ret    

f0103ca4 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103ca4:	55                   	push   %ebp
f0103ca5:	89 e5                	mov    %esp,%ebp
f0103ca7:	57                   	push   %edi
f0103ca8:	56                   	push   %esi
f0103ca9:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103cac:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103cad:	83 3d 80 ae 22 f0 00 	cmpl   $0x0,0xf022ae80
f0103cb4:	74 01                	je     f0103cb7 <trap+0x13>
		asm volatile("hlt");
f0103cb6:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103cb7:	e8 ce 15 00 00       	call   f010528a <cpunum>
f0103cbc:	6b d0 74             	imul   $0x74,%eax,%edx
f0103cbf:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103cc5:	b8 01 00 00 00       	mov    $0x1,%eax
f0103cca:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103cce:	83 f8 02             	cmp    $0x2,%eax
f0103cd1:	75 10                	jne    f0103ce3 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103cd3:	83 ec 0c             	sub    $0xc,%esp
f0103cd6:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103cdb:	e8 18 18 00 00       	call   f01054f8 <spin_lock>
f0103ce0:	83 c4 10             	add    $0x10,%esp

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103ce3:	9c                   	pushf  
f0103ce4:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103ce5:	f6 c4 02             	test   $0x2,%ah
f0103ce8:	74 19                	je     f0103d03 <trap+0x5f>
f0103cea:	68 74 6d 10 f0       	push   $0xf0106d74
f0103cef:	68 07 68 10 f0       	push   $0xf0106807
f0103cf4:	68 1d 01 00 00       	push   $0x11d
f0103cf9:	68 68 6d 10 f0       	push   $0xf0106d68
f0103cfe:	e8 3d c3 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103d03:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d07:	83 e0 03             	and    $0x3,%eax
f0103d0a:	66 83 f8 03          	cmp    $0x3,%ax
f0103d0e:	0f 85 90 00 00 00    	jne    f0103da4 <trap+0x100>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		assert(curenv);
f0103d14:	e8 71 15 00 00       	call   f010528a <cpunum>
f0103d19:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d1c:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103d23:	75 19                	jne    f0103d3e <trap+0x9a>
f0103d25:	68 8d 6d 10 f0       	push   $0xf0106d8d
f0103d2a:	68 07 68 10 f0       	push   $0xf0106807
f0103d2f:	68 24 01 00 00       	push   $0x124
f0103d34:	68 68 6d 10 f0       	push   $0xf0106d68
f0103d39:	e8 02 c3 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103d3e:	e8 47 15 00 00       	call   f010528a <cpunum>
f0103d43:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d46:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103d4c:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103d50:	75 2d                	jne    f0103d7f <trap+0xdb>
			env_free(curenv);
f0103d52:	e8 33 15 00 00       	call   f010528a <cpunum>
f0103d57:	83 ec 0c             	sub    $0xc,%esp
f0103d5a:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d5d:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103d63:	e8 35 f4 ff ff       	call   f010319d <env_free>
			curenv = NULL;
f0103d68:	e8 1d 15 00 00       	call   f010528a <cpunum>
f0103d6d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d70:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103d77:	00 00 00 
			sched_yield();
f0103d7a:	e8 9d 02 00 00       	call   f010401c <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103d7f:	e8 06 15 00 00       	call   f010528a <cpunum>
f0103d84:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d87:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103d8d:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103d92:	89 c7                	mov    %eax,%edi
f0103d94:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103d96:	e8 ef 14 00 00       	call   f010528a <cpunum>
f0103d9b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d9e:	8b b0 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103da4:	89 35 60 aa 22 f0    	mov    %esi,0xf022aa60
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch (tf->tf_trapno)
f0103daa:	8b 46 28             	mov    0x28(%esi),%eax
f0103dad:	83 f8 0e             	cmp    $0xe,%eax
f0103db0:	74 0c                	je     f0103dbe <trap+0x11a>
f0103db2:	83 f8 30             	cmp    $0x30,%eax
f0103db5:	74 23                	je     f0103dda <trap+0x136>
f0103db7:	83 f8 03             	cmp    $0x3,%eax
f0103dba:	75 3e                	jne    f0103dfa <trap+0x156>
f0103dbc:	eb 0e                	jmp    f0103dcc <trap+0x128>
	{
	case T_PGFLT:
		page_fault_handler(tf);
f0103dbe:	83 ec 0c             	sub    $0xc,%esp
f0103dc1:	56                   	push   %esi
f0103dc2:	e8 68 fe ff ff       	call   f0103c2f <page_fault_handler>
f0103dc7:	83 c4 10             	add    $0x10,%esp
f0103dca:	eb 73                	jmp    f0103e3f <trap+0x19b>
		break;
	case T_BRKPT:
		monitor(tf);
f0103dcc:	83 ec 0c             	sub    $0xc,%esp
f0103dcf:	56                   	push   %esi
f0103dd0:	e8 14 cb ff ff       	call   f01008e9 <monitor>
f0103dd5:	83 c4 10             	add    $0x10,%esp
f0103dd8:	eb 65                	jmp    f0103e3f <trap+0x19b>
		break;
	case T_SYSCALL:
		tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, 
f0103dda:	8b 46 18             	mov    0x18(%esi),%eax
f0103ddd:	83 ec 08             	sub    $0x8,%esp
f0103de0:	ff 76 04             	pushl  0x4(%esi)
f0103de3:	ff 36                	pushl  (%esi)
f0103de5:	50                   	push   %eax
f0103de6:	50                   	push   %eax
f0103de7:	ff 76 14             	pushl  0x14(%esi)
f0103dea:	ff 76 1c             	pushl  0x1c(%esi)
f0103ded:	e8 37 02 00 00       	call   f0104029 <syscall>
f0103df2:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103df5:	83 c4 20             	add    $0x20,%esp
f0103df8:	eb 45                	jmp    f0103e3f <trap+0x19b>
		tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx, tf->tf_regs.reg_ecx, 
		tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
		break;
	default:
		// Unexpected trap: The user process or the kernel has a bug.
		print_trapframe(tf);
f0103dfa:	83 ec 0c             	sub    $0xc,%esp
f0103dfd:	56                   	push   %esi
f0103dfe:	e8 a4 fc ff ff       	call   f0103aa7 <print_trapframe>
		if (tf->tf_cs == GD_KT)
f0103e03:	83 c4 10             	add    $0x10,%esp
f0103e06:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103e0b:	75 17                	jne    f0103e24 <trap+0x180>
			panic("unhandled trap in kernel");
f0103e0d:	83 ec 04             	sub    $0x4,%esp
f0103e10:	68 94 6d 10 f0       	push   $0xf0106d94
f0103e15:	68 eb 00 00 00       	push   $0xeb
f0103e1a:	68 68 6d 10 f0       	push   $0xf0106d68
f0103e1f:	e8 1c c2 ff ff       	call   f0100040 <_panic>
		else
		{
			env_destroy(curenv);
f0103e24:	e8 61 14 00 00       	call   f010528a <cpunum>
f0103e29:	83 ec 0c             	sub    $0xc,%esp
f0103e2c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e2f:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103e35:	e8 3e f5 ff ff       	call   f0103378 <env_destroy>
f0103e3a:	83 c4 10             	add    $0x10,%esp
f0103e3d:	eb 63                	jmp    f0103ea2 <trap+0x1fe>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103e3f:	83 7e 28 27          	cmpl   $0x27,0x28(%esi)
f0103e43:	75 1a                	jne    f0103e5f <trap+0x1bb>
		cprintf("Spurious interrupt on irq 7\n");
f0103e45:	83 ec 0c             	sub    $0xc,%esp
f0103e48:	68 ad 6d 10 f0       	push   $0xf0106dad
f0103e4d:	e8 1c f8 ff ff       	call   f010366e <cprintf>
		print_trapframe(tf);
f0103e52:	89 34 24             	mov    %esi,(%esp)
f0103e55:	e8 4d fc ff ff       	call   f0103aa7 <print_trapframe>
f0103e5a:	83 c4 10             	add    $0x10,%esp
f0103e5d:	eb 43                	jmp    f0103ea2 <trap+0x1fe>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103e5f:	83 ec 0c             	sub    $0xc,%esp
f0103e62:	56                   	push   %esi
f0103e63:	e8 3f fc ff ff       	call   f0103aa7 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103e68:	83 c4 10             	add    $0x10,%esp
f0103e6b:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103e70:	75 17                	jne    f0103e89 <trap+0x1e5>
		panic("unhandled trap in kernel");
f0103e72:	83 ec 04             	sub    $0x4,%esp
f0103e75:	68 94 6d 10 f0       	push   $0xf0106d94
f0103e7a:	68 03 01 00 00       	push   $0x103
f0103e7f:	68 68 6d 10 f0       	push   $0xf0106d68
f0103e84:	e8 b7 c1 ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f0103e89:	e8 fc 13 00 00       	call   f010528a <cpunum>
f0103e8e:	83 ec 0c             	sub    $0xc,%esp
f0103e91:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e94:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103e9a:	e8 d9 f4 ff ff       	call   f0103378 <env_destroy>
f0103e9f:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103ea2:	e8 e3 13 00 00       	call   f010528a <cpunum>
f0103ea7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eaa:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103eb1:	74 2a                	je     f0103edd <trap+0x239>
f0103eb3:	e8 d2 13 00 00       	call   f010528a <cpunum>
f0103eb8:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ebb:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103ec1:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103ec5:	75 16                	jne    f0103edd <trap+0x239>
		env_run(curenv);
f0103ec7:	e8 be 13 00 00       	call   f010528a <cpunum>
f0103ecc:	83 ec 0c             	sub    $0xc,%esp
f0103ecf:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ed2:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103ed8:	e8 3a f5 ff ff       	call   f0103417 <env_run>
	else
		sched_yield();
f0103edd:	e8 3a 01 00 00       	call   f010401c <sched_yield>

f0103ee2 <divide_error>:
 * Lab 3: Your code here for generating entry points for the different traps.
 */



	TRAPHANDLER_NOEC(divide_error, T_DIVIDE) 
f0103ee2:	6a 00                	push   $0x0
f0103ee4:	6a 00                	push   $0x0
f0103ee6:	eb 4e                	jmp    f0103f36 <_alltraps>

f0103ee8 <debug_exception>:
	TRAPHANDLER_NOEC(debug_exception, T_DEBUG) 
f0103ee8:	6a 00                	push   $0x0
f0103eea:	6a 01                	push   $0x1
f0103eec:	eb 48                	jmp    f0103f36 <_alltraps>

f0103eee <non_maskable_interrupt>:
	TRAPHANDLER_NOEC(non_maskable_interrupt, T_NMI) 
f0103eee:	6a 00                	push   $0x0
f0103ef0:	6a 02                	push   $0x2
f0103ef2:	eb 42                	jmp    f0103f36 <_alltraps>

f0103ef4 <break_point>:
	TRAPHANDLER_NOEC(break_point, T_BRKPT)// inc/x86.中有breakpoint同名函数
f0103ef4:	6a 00                	push   $0x0
f0103ef6:	6a 03                	push   $0x3
f0103ef8:	eb 3c                	jmp    f0103f36 <_alltraps>

f0103efa <overflow>:
	TRAPHANDLER_NOEC(overflow, T_OFLOW) 
f0103efa:	6a 00                	push   $0x0
f0103efc:	6a 04                	push   $0x4
f0103efe:	eb 36                	jmp    f0103f36 <_alltraps>

f0103f00 <bounds_check>:
	TRAPHANDLER_NOEC(bounds_check, T_BOUND) 
f0103f00:	6a 00                	push   $0x0
f0103f02:	6a 05                	push   $0x5
f0103f04:	eb 30                	jmp    f0103f36 <_alltraps>

f0103f06 <illegal_opcode>:
	TRAPHANDLER_NOEC(illegal_opcode, T_ILLOP) 
f0103f06:	6a 00                	push   $0x0
f0103f08:	6a 06                	push   $0x6
f0103f0a:	eb 2a                	jmp    f0103f36 <_alltraps>

f0103f0c <device_not_available>:
	TRAPHANDLER_NOEC(device_not_available, T_DEVICE) 
f0103f0c:	6a 00                	push   $0x0
f0103f0e:	6a 07                	push   $0x7
f0103f10:	eb 24                	jmp    f0103f36 <_alltraps>

f0103f12 <double_fault>:
	TRAPHANDLER(double_fault, T_DBLFLT) 
f0103f12:	6a 08                	push   $0x8
f0103f14:	eb 20                	jmp    f0103f36 <_alltraps>

f0103f16 <invalid_task_switch_segment>:

	TRAPHANDLER(invalid_task_switch_segment, T_TSS) 
f0103f16:	6a 0a                	push   $0xa
f0103f18:	eb 1c                	jmp    f0103f36 <_alltraps>

f0103f1a <segment_not_present>:
	TRAPHANDLER(segment_not_present, T_SEGNP) 
f0103f1a:	6a 0b                	push   $0xb
f0103f1c:	eb 18                	jmp    f0103f36 <_alltraps>

f0103f1e <stack_exception>:
	TRAPHANDLER(stack_exception, T_STACK) 
f0103f1e:	6a 0c                	push   $0xc
f0103f20:	eb 14                	jmp    f0103f36 <_alltraps>

f0103f22 <general_protection_fault>:
	TRAPHANDLER(general_protection_fault, T_GPFLT) 
f0103f22:	6a 0d                	push   $0xd
f0103f24:	eb 10                	jmp    f0103f36 <_alltraps>

f0103f26 <page_fault>:
	TRAPHANDLER(page_fault, T_PGFLT) 
f0103f26:	6a 0e                	push   $0xe
f0103f28:	eb 0c                	jmp    f0103f36 <_alltraps>

f0103f2a <floating_point_error>:

	TRAPHANDLER_NOEC(floating_point_error, T_FPERR) 
f0103f2a:	6a 00                	push   $0x0
f0103f2c:	6a 10                	push   $0x10
f0103f2e:	eb 06                	jmp    f0103f36 <_alltraps>

f0103f30 <system_call>:
	//x86手册9.10中没有说明aligment check && machine check
	//&& SIMD floating point error是否返回error code，故没写上
	TRAPHANDLER_NOEC(system_call, T_SYSCALL)
f0103f30:	6a 00                	push   $0x0
f0103f32:	6a 30                	push   $0x30
f0103f34:	eb 00                	jmp    f0103f36 <_alltraps>

f0103f36 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
f0103f36:	1e                   	push   %ds
	pushl %es
f0103f37:	06                   	push   %es
	pushal
f0103f38:	60                   	pusha  

	mov $GD_KD,%eax
f0103f39:	b8 10 00 00 00       	mov    $0x10,%eax
	mov %eax,%ds
f0103f3e:	8e d8                	mov    %eax,%ds
	mov %eax,%es
f0103f40:	8e c0                	mov    %eax,%es
	
	pushl %esp  //压入trap()的参数tf，%esp指向Trapframe结构的起始地址
f0103f42:	54                   	push   %esp
	call trap
f0103f43:	e8 5c fd ff ff       	call   f0103ca4 <trap>

f0103f48 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0103f48:	55                   	push   %ebp
f0103f49:	89 e5                	mov    %esp,%ebp
f0103f4b:	83 ec 08             	sub    $0x8,%esp
f0103f4e:	a1 48 a2 22 f0       	mov    0xf022a248,%eax
f0103f53:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103f56:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0103f5b:	8b 02                	mov    (%edx),%eax
f0103f5d:	83 e8 01             	sub    $0x1,%eax
f0103f60:	83 f8 02             	cmp    $0x2,%eax
f0103f63:	76 10                	jbe    f0103f75 <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103f65:	83 c1 01             	add    $0x1,%ecx
f0103f68:	83 c2 7c             	add    $0x7c,%edx
f0103f6b:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103f71:	75 e8                	jne    f0103f5b <sched_halt+0x13>
f0103f73:	eb 08                	jmp    f0103f7d <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0103f75:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103f7b:	75 1f                	jne    f0103f9c <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0103f7d:	83 ec 0c             	sub    $0xc,%esp
f0103f80:	68 b0 6f 10 f0       	push   $0xf0106fb0
f0103f85:	e8 e4 f6 ff ff       	call   f010366e <cprintf>
f0103f8a:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0103f8d:	83 ec 0c             	sub    $0xc,%esp
f0103f90:	6a 00                	push   $0x0
f0103f92:	e8 52 c9 ff ff       	call   f01008e9 <monitor>
f0103f97:	83 c4 10             	add    $0x10,%esp
f0103f9a:	eb f1                	jmp    f0103f8d <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0103f9c:	e8 e9 12 00 00       	call   f010528a <cpunum>
f0103fa1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fa4:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103fab:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0103fae:	a1 8c ae 22 f0       	mov    0xf022ae8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103fb3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103fb8:	77 12                	ja     f0103fcc <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103fba:	50                   	push   %eax
f0103fbb:	68 68 59 10 f0       	push   $0xf0105968
f0103fc0:	6a 3d                	push   $0x3d
f0103fc2:	68 d9 6f 10 f0       	push   $0xf0106fd9
f0103fc7:	e8 74 c0 ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103fcc:	05 00 00 00 10       	add    $0x10000000,%eax
f0103fd1:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0103fd4:	e8 b1 12 00 00       	call   f010528a <cpunum>
f0103fd9:	6b d0 74             	imul   $0x74,%eax,%edx
f0103fdc:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103fe2:	b8 02 00 00 00       	mov    $0x2,%eax
f0103fe7:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103feb:	83 ec 0c             	sub    $0xc,%esp
f0103fee:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103ff3:	e8 9d 15 00 00       	call   f0105595 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103ff8:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0103ffa:	e8 8b 12 00 00       	call   f010528a <cpunum>
f0103fff:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f0104002:	8b 80 30 b0 22 f0    	mov    -0xfdd4fd0(%eax),%eax
f0104008:	bd 00 00 00 00       	mov    $0x0,%ebp
f010400d:	89 c4                	mov    %eax,%esp
f010400f:	6a 00                	push   $0x0
f0104011:	6a 00                	push   $0x0
f0104013:	fb                   	sti    
f0104014:	f4                   	hlt    
f0104015:	eb fd                	jmp    f0104014 <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0104017:	83 c4 10             	add    $0x10,%esp
f010401a:	c9                   	leave  
f010401b:	c3                   	ret    

f010401c <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f010401c:	55                   	push   %ebp
f010401d:	89 e5                	mov    %esp,%ebp
f010401f:	83 ec 08             	sub    $0x8,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.

	// sched_halt never returns
	sched_halt();
f0104022:	e8 21 ff ff ff       	call   f0103f48 <sched_halt>
}
f0104027:	c9                   	leave  
f0104028:	c3                   	ret    

f0104029 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104029:	55                   	push   %ebp
f010402a:	89 e5                	mov    %esp,%ebp
f010402c:	53                   	push   %ebx
f010402d:	83 ec 14             	sub    $0x14,%esp
f0104030:	8b 45 08             	mov    0x8(%ebp),%eax
	// LAB 3: Your code here.

	//panic("syscall not implemented");
	int ret;

	switch (syscallno) {
f0104033:	83 f8 01             	cmp    $0x1,%eax
f0104036:	74 53                	je     f010408b <syscall+0x62>
f0104038:	83 f8 01             	cmp    $0x1,%eax
f010403b:	72 13                	jb     f0104050 <syscall+0x27>
f010403d:	83 f8 02             	cmp    $0x2,%eax
f0104040:	0f 84 db 00 00 00    	je     f0104121 <syscall+0xf8>
f0104046:	83 f8 03             	cmp    $0x3,%eax
f0104049:	74 4a                	je     f0104095 <syscall+0x6c>
f010404b:	e9 e4 00 00 00       	jmp    f0104134 <syscall+0x10b>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f0104050:	e8 35 12 00 00       	call   f010528a <cpunum>
f0104055:	6a 04                	push   $0x4
f0104057:	ff 75 10             	pushl  0x10(%ebp)
f010405a:	ff 75 0c             	pushl  0xc(%ebp)
f010405d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104060:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0104066:	e8 85 ec ff ff       	call   f0102cf0 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f010406b:	83 c4 0c             	add    $0xc,%esp
f010406e:	ff 75 0c             	pushl  0xc(%ebp)
f0104071:	ff 75 10             	pushl  0x10(%ebp)
f0104074:	68 e6 6f 10 f0       	push   $0xf0106fe6
f0104079:	e8 f0 f5 ff ff       	call   f010366e <cprintf>
f010407e:	83 c4 10             	add    $0x10,%esp
	int ret;

	switch (syscallno) {
	case SYS_cputs:
		sys_cputs((const char*)a1,(size_t)a2);
		ret = 0;//其他函数都return 0
f0104081:	b8 00 00 00 00       	mov    $0x0,%eax
f0104086:	e9 ae 00 00 00       	jmp    f0104139 <syscall+0x110>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f010408b:	e8 3f c5 ff ff       	call   f01005cf <cons_getc>
		sys_cputs((const char*)a1,(size_t)a2);
		ret = 0;//其他函数都return 0
		break;
	case SYS_cgetc:
		ret = sys_cgetc();
		break;
f0104090:	e9 a4 00 00 00       	jmp    f0104139 <syscall+0x110>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104095:	83 ec 04             	sub    $0x4,%esp
f0104098:	6a 01                	push   $0x1
f010409a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010409d:	50                   	push   %eax
f010409e:	ff 75 0c             	pushl  0xc(%ebp)
f01040a1:	e8 18 ed ff ff       	call   f0102dbe <envid2env>
f01040a6:	83 c4 10             	add    $0x10,%esp
f01040a9:	85 c0                	test   %eax,%eax
f01040ab:	0f 88 88 00 00 00    	js     f0104139 <syscall+0x110>
		return r;
	if (e == curenv)
f01040b1:	e8 d4 11 00 00       	call   f010528a <cpunum>
f01040b6:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01040b9:	6b c0 74             	imul   $0x74,%eax,%eax
f01040bc:	39 90 28 b0 22 f0    	cmp    %edx,-0xfdd4fd8(%eax)
f01040c2:	75 23                	jne    f01040e7 <syscall+0xbe>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f01040c4:	e8 c1 11 00 00       	call   f010528a <cpunum>
f01040c9:	83 ec 08             	sub    $0x8,%esp
f01040cc:	6b c0 74             	imul   $0x74,%eax,%eax
f01040cf:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01040d5:	ff 70 48             	pushl  0x48(%eax)
f01040d8:	68 eb 6f 10 f0       	push   $0xf0106feb
f01040dd:	e8 8c f5 ff ff       	call   f010366e <cprintf>
f01040e2:	83 c4 10             	add    $0x10,%esp
f01040e5:	eb 25                	jmp    f010410c <syscall+0xe3>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f01040e7:	8b 5a 48             	mov    0x48(%edx),%ebx
f01040ea:	e8 9b 11 00 00       	call   f010528a <cpunum>
f01040ef:	83 ec 04             	sub    $0x4,%esp
f01040f2:	53                   	push   %ebx
f01040f3:	6b c0 74             	imul   $0x74,%eax,%eax
f01040f6:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01040fc:	ff 70 48             	pushl  0x48(%eax)
f01040ff:	68 06 70 10 f0       	push   $0xf0107006
f0104104:	e8 65 f5 ff ff       	call   f010366e <cprintf>
f0104109:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f010410c:	83 ec 0c             	sub    $0xc,%esp
f010410f:	ff 75 f4             	pushl  -0xc(%ebp)
f0104112:	e8 61 f2 ff ff       	call   f0103378 <env_destroy>
f0104117:	83 c4 10             	add    $0x10,%esp
	return 0;
f010411a:	b8 00 00 00 00       	mov    $0x0,%eax
f010411f:	eb 18                	jmp    f0104139 <syscall+0x110>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104121:	e8 64 11 00 00       	call   f010528a <cpunum>
f0104126:	6b c0 74             	imul   $0x74,%eax,%eax
f0104129:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010412f:	8b 40 48             	mov    0x48(%eax),%eax
	case SYS_env_destroy:
		ret = sys_env_destroy((envid_t)a1);
		break;
	case SYS_getenvid:
		ret = sys_getenvid();
		break;
f0104132:	eb 05                	jmp    f0104139 <syscall+0x110>
	default:
		return -E_NO_SYS;
f0104134:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
	}
	return ret;
}
f0104139:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010413c:	c9                   	leave  
f010413d:	c3                   	ret    

f010413e <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010413e:	55                   	push   %ebp
f010413f:	89 e5                	mov    %esp,%ebp
f0104141:	57                   	push   %edi
f0104142:	56                   	push   %esi
f0104143:	53                   	push   %ebx
f0104144:	83 ec 14             	sub    $0x14,%esp
f0104147:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010414a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010414d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104150:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104153:	8b 1a                	mov    (%edx),%ebx
f0104155:	8b 01                	mov    (%ecx),%eax
f0104157:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010415a:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104161:	eb 7f                	jmp    f01041e2 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0104163:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104166:	01 d8                	add    %ebx,%eax
f0104168:	89 c6                	mov    %eax,%esi
f010416a:	c1 ee 1f             	shr    $0x1f,%esi
f010416d:	01 c6                	add    %eax,%esi
f010416f:	d1 fe                	sar    %esi
f0104171:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104174:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104177:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010417a:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010417c:	eb 03                	jmp    f0104181 <stab_binsearch+0x43>
			m--;
f010417e:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104181:	39 c3                	cmp    %eax,%ebx
f0104183:	7f 0d                	jg     f0104192 <stab_binsearch+0x54>
f0104185:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104189:	83 ea 0c             	sub    $0xc,%edx
f010418c:	39 f9                	cmp    %edi,%ecx
f010418e:	75 ee                	jne    f010417e <stab_binsearch+0x40>
f0104190:	eb 05                	jmp    f0104197 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104192:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0104195:	eb 4b                	jmp    f01041e2 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104197:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010419a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010419d:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01041a1:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01041a4:	76 11                	jbe    f01041b7 <stab_binsearch+0x79>
			*region_left = m;
f01041a6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01041a9:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01041ab:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01041ae:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01041b5:	eb 2b                	jmp    f01041e2 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01041b7:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01041ba:	73 14                	jae    f01041d0 <stab_binsearch+0x92>
			*region_right = m - 1;
f01041bc:	83 e8 01             	sub    $0x1,%eax
f01041bf:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01041c2:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01041c5:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01041c7:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01041ce:	eb 12                	jmp    f01041e2 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01041d0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01041d3:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01041d5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01041d9:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01041db:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01041e2:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01041e5:	0f 8e 78 ff ff ff    	jle    f0104163 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01041eb:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01041ef:	75 0f                	jne    f0104200 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01041f1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01041f4:	8b 00                	mov    (%eax),%eax
f01041f6:	83 e8 01             	sub    $0x1,%eax
f01041f9:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01041fc:	89 06                	mov    %eax,(%esi)
f01041fe:	eb 2c                	jmp    f010422c <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104200:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104203:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104205:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104208:	8b 0e                	mov    (%esi),%ecx
f010420a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010420d:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104210:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104213:	eb 03                	jmp    f0104218 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104215:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104218:	39 c8                	cmp    %ecx,%eax
f010421a:	7e 0b                	jle    f0104227 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010421c:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104220:	83 ea 0c             	sub    $0xc,%edx
f0104223:	39 df                	cmp    %ebx,%edi
f0104225:	75 ee                	jne    f0104215 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104227:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010422a:	89 06                	mov    %eax,(%esi)
	}
}
f010422c:	83 c4 14             	add    $0x14,%esp
f010422f:	5b                   	pop    %ebx
f0104230:	5e                   	pop    %esi
f0104231:	5f                   	pop    %edi
f0104232:	5d                   	pop    %ebp
f0104233:	c3                   	ret    

f0104234 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104234:	55                   	push   %ebp
f0104235:	89 e5                	mov    %esp,%ebp
f0104237:	57                   	push   %edi
f0104238:	56                   	push   %esi
f0104239:	53                   	push   %ebx
f010423a:	83 ec 3c             	sub    $0x3c,%esp
f010423d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104240:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104243:	c7 06 1e 70 10 f0    	movl   $0xf010701e,(%esi)
	info->eip_line = 0;
f0104249:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0104250:	c7 46 08 1e 70 10 f0 	movl   $0xf010701e,0x8(%esi)
	info->eip_fn_namelen = 9;
f0104257:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010425e:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0104261:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104268:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010426e:	0f 87 92 00 00 00    	ja     f0104306 <debuginfo_eip+0xd2>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0)
f0104274:	e8 11 10 00 00       	call   f010528a <cpunum>
f0104279:	6a 04                	push   $0x4
f010427b:	6a 10                	push   $0x10
f010427d:	68 00 00 20 00       	push   $0x200000
f0104282:	6b c0 74             	imul   $0x74,%eax,%eax
f0104285:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f010428b:	e8 d1 e9 ff ff       	call   f0102c61 <user_mem_check>
f0104290:	83 c4 10             	add    $0x10,%esp
f0104293:	85 c0                	test   %eax,%eax
f0104295:	0f 85 01 02 00 00    	jne    f010449c <debuginfo_eip+0x268>
			return -1;
		stabs = usd->stabs;
f010429b:	a1 00 00 20 00       	mov    0x200000,%eax
f01042a0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f01042a3:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f01042a9:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f01042af:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f01042b2:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01042b8:	89 55 d0             	mov    %edx,-0x30(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, sizeof(struct UserStabData), PTE_U) != 0)
f01042bb:	e8 ca 0f 00 00       	call   f010528a <cpunum>
f01042c0:	6a 04                	push   $0x4
f01042c2:	6a 10                	push   $0x10
f01042c4:	ff 75 d4             	pushl  -0x2c(%ebp)
f01042c7:	6b c0 74             	imul   $0x74,%eax,%eax
f01042ca:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f01042d0:	e8 8c e9 ff ff       	call   f0102c61 <user_mem_check>
f01042d5:	83 c4 10             	add    $0x10,%esp
f01042d8:	85 c0                	test   %eax,%eax
f01042da:	0f 85 c3 01 00 00    	jne    f01044a3 <debuginfo_eip+0x26f>
			return -1;
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
f01042e0:	e8 a5 0f 00 00       	call   f010528a <cpunum>
f01042e5:	6a 04                	push   $0x4
f01042e7:	6a 10                	push   $0x10
f01042e9:	ff 75 cc             	pushl  -0x34(%ebp)
f01042ec:	6b c0 74             	imul   $0x74,%eax,%eax
f01042ef:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f01042f5:	e8 67 e9 ff ff       	call   f0102c61 <user_mem_check>
f01042fa:	83 c4 10             	add    $0x10,%esp
f01042fd:	85 c0                	test   %eax,%eax
f01042ff:	74 1f                	je     f0104320 <debuginfo_eip+0xec>
f0104301:	e9 a4 01 00 00       	jmp    f01044aa <debuginfo_eip+0x276>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104306:	c7 45 d0 4f 41 11 f0 	movl   $0xf011414f,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010430d:	c7 45 cc 7d 0b 11 f0 	movl   $0xf0110b7d,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104314:	bb 7c 0b 11 f0       	mov    $0xf0110b7c,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104319:	c7 45 d4 f8 74 10 f0 	movl   $0xf01074f8,-0x2c(%ebp)
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104320:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104323:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0104326:	0f 83 85 01 00 00    	jae    f01044b1 <debuginfo_eip+0x27d>
f010432c:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104330:	0f 85 82 01 00 00    	jne    f01044b8 <debuginfo_eip+0x284>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104336:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010433d:	2b 5d d4             	sub    -0x2c(%ebp),%ebx
f0104340:	c1 fb 02             	sar    $0x2,%ebx
f0104343:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f0104349:	83 e8 01             	sub    $0x1,%eax
f010434c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010434f:	83 ec 08             	sub    $0x8,%esp
f0104352:	57                   	push   %edi
f0104353:	6a 64                	push   $0x64
f0104355:	8d 55 e0             	lea    -0x20(%ebp),%edx
f0104358:	89 d1                	mov    %edx,%ecx
f010435a:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010435d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104360:	89 d8                	mov    %ebx,%eax
f0104362:	e8 d7 fd ff ff       	call   f010413e <stab_binsearch>
	if (lfile == 0)
f0104367:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010436a:	83 c4 10             	add    $0x10,%esp
f010436d:	85 c0                	test   %eax,%eax
f010436f:	0f 84 4a 01 00 00    	je     f01044bf <debuginfo_eip+0x28b>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104375:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104378:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010437b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010437e:	83 ec 08             	sub    $0x8,%esp
f0104381:	57                   	push   %edi
f0104382:	6a 24                	push   $0x24
f0104384:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0104387:	89 d1                	mov    %edx,%ecx
f0104389:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010438c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f010438f:	89 d8                	mov    %ebx,%eax
f0104391:	e8 a8 fd ff ff       	call   f010413e <stab_binsearch>

	if (lfun <= rfun) {
f0104396:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104399:	83 c4 10             	add    $0x10,%esp
f010439c:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010439f:	7f 25                	jg     f01043c6 <debuginfo_eip+0x192>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01043a1:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01043a4:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01043a7:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01043aa:	8b 02                	mov    (%edx),%eax
f01043ac:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01043af:	2b 4d cc             	sub    -0x34(%ebp),%ecx
f01043b2:	39 c8                	cmp    %ecx,%eax
f01043b4:	73 06                	jae    f01043bc <debuginfo_eip+0x188>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01043b6:	03 45 cc             	add    -0x34(%ebp),%eax
f01043b9:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01043bc:	8b 42 08             	mov    0x8(%edx),%eax
f01043bf:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f01043c2:	29 c7                	sub    %eax,%edi
f01043c4:	eb 06                	jmp    f01043cc <debuginfo_eip+0x198>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01043c6:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f01043c9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01043cc:	83 ec 08             	sub    $0x8,%esp
f01043cf:	6a 3a                	push   $0x3a
f01043d1:	ff 76 08             	pushl  0x8(%esi)
f01043d4:	e8 74 08 00 00       	call   f0104c4d <strfind>
f01043d9:	2b 46 08             	sub    0x8(%esi),%eax
f01043dc:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
f01043df:	83 c4 08             	add    $0x8,%esp
f01043e2:	2b 7e 10             	sub    0x10(%esi),%edi
f01043e5:	57                   	push   %edi
f01043e6:	6a 44                	push   $0x44
f01043e8:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01043eb:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01043ee:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01043f1:	89 f8                	mov    %edi,%eax
f01043f3:	e8 46 fd ff ff       	call   f010413e <stab_binsearch>
	if (lfun > rfun) 
f01043f8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01043fb:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01043fe:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0104401:	83 c4 10             	add    $0x10,%esp
f0104404:	39 c8                	cmp    %ecx,%eax
f0104406:	0f 8f ba 00 00 00    	jg     f01044c6 <debuginfo_eip+0x292>
       	  return -1;
        info->eip_line = stabs[lfun].n_desc;
f010440c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010440f:	89 fa                	mov    %edi,%edx
f0104411:	8d 04 87             	lea    (%edi,%eax,4),%eax
f0104414:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0104417:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f010441b:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010441e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104421:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104424:	8d 04 82             	lea    (%edx,%eax,4),%eax
f0104427:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f010442a:	eb 06                	jmp    f0104432 <debuginfo_eip+0x1fe>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010442c:	83 eb 01             	sub    $0x1,%ebx
f010442f:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104432:	39 fb                	cmp    %edi,%ebx
f0104434:	7c 32                	jl     f0104468 <debuginfo_eip+0x234>
	       && stabs[lline].n_type != N_SOL
f0104436:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f010443a:	80 fa 84             	cmp    $0x84,%dl
f010443d:	74 0b                	je     f010444a <debuginfo_eip+0x216>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010443f:	80 fa 64             	cmp    $0x64,%dl
f0104442:	75 e8                	jne    f010442c <debuginfo_eip+0x1f8>
f0104444:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0104448:	74 e2                	je     f010442c <debuginfo_eip+0x1f8>
f010444a:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010444d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104450:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104453:	8b 04 87             	mov    (%edi,%eax,4),%eax
f0104456:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0104459:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010445c:	29 fa                	sub    %edi,%edx
f010445e:	39 d0                	cmp    %edx,%eax
f0104460:	73 09                	jae    f010446b <debuginfo_eip+0x237>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104462:	01 f8                	add    %edi,%eax
f0104464:	89 06                	mov    %eax,(%esi)
f0104466:	eb 03                	jmp    f010446b <debuginfo_eip+0x237>
f0104468:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010446b:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104470:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0104473:	39 cf                	cmp    %ecx,%edi
f0104475:	7d 5b                	jge    f01044d2 <debuginfo_eip+0x29e>
		for (lline = lfun + 1;
f0104477:	89 f8                	mov    %edi,%eax
f0104479:	83 c0 01             	add    $0x1,%eax
f010447c:	8b 55 c0             	mov    -0x40(%ebp),%edx
f010447f:	eb 07                	jmp    f0104488 <debuginfo_eip+0x254>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104481:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0104485:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104488:	39 c8                	cmp    %ecx,%eax
f010448a:	74 41                	je     f01044cd <debuginfo_eip+0x299>
f010448c:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010448f:	80 7a 04 a0          	cmpb   $0xa0,0x4(%edx)
f0104493:	74 ec                	je     f0104481 <debuginfo_eip+0x24d>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104495:	b8 00 00 00 00       	mov    $0x0,%eax
f010449a:	eb 36                	jmp    f01044d2 <debuginfo_eip+0x29e>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f010449c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01044a1:	eb 2f                	jmp    f01044d2 <debuginfo_eip+0x29e>
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f01044a3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01044a8:	eb 28                	jmp    f01044d2 <debuginfo_eip+0x29e>
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f01044aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01044af:	eb 21                	jmp    f01044d2 <debuginfo_eip+0x29e>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01044b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01044b6:	eb 1a                	jmp    f01044d2 <debuginfo_eip+0x29e>
f01044b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01044bd:	eb 13                	jmp    f01044d2 <debuginfo_eip+0x29e>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01044bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01044c4:	eb 0c                	jmp    f01044d2 <debuginfo_eip+0x29e>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
	if (lfun > rfun) 
       	  return -1;
f01044c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01044cb:	eb 05                	jmp    f01044d2 <debuginfo_eip+0x29e>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01044cd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01044d2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01044d5:	5b                   	pop    %ebx
f01044d6:	5e                   	pop    %esi
f01044d7:	5f                   	pop    %edi
f01044d8:	5d                   	pop    %ebp
f01044d9:	c3                   	ret    

f01044da <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01044da:	55                   	push   %ebp
f01044db:	89 e5                	mov    %esp,%ebp
f01044dd:	57                   	push   %edi
f01044de:	56                   	push   %esi
f01044df:	53                   	push   %ebx
f01044e0:	83 ec 1c             	sub    $0x1c,%esp
f01044e3:	89 c7                	mov    %eax,%edi
f01044e5:	89 d6                	mov    %edx,%esi
f01044e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01044ea:	8b 55 0c             	mov    0xc(%ebp),%edx
f01044ed:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01044f0:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01044f3:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01044f6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01044fb:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01044fe:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104501:	39 d3                	cmp    %edx,%ebx
f0104503:	72 05                	jb     f010450a <printnum+0x30>
f0104505:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104508:	77 45                	ja     f010454f <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010450a:	83 ec 0c             	sub    $0xc,%esp
f010450d:	ff 75 18             	pushl  0x18(%ebp)
f0104510:	8b 45 14             	mov    0x14(%ebp),%eax
f0104513:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104516:	53                   	push   %ebx
f0104517:	ff 75 10             	pushl  0x10(%ebp)
f010451a:	83 ec 08             	sub    $0x8,%esp
f010451d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104520:	ff 75 e0             	pushl  -0x20(%ebp)
f0104523:	ff 75 dc             	pushl  -0x24(%ebp)
f0104526:	ff 75 d8             	pushl  -0x28(%ebp)
f0104529:	e8 62 11 00 00       	call   f0105690 <__udivdi3>
f010452e:	83 c4 18             	add    $0x18,%esp
f0104531:	52                   	push   %edx
f0104532:	50                   	push   %eax
f0104533:	89 f2                	mov    %esi,%edx
f0104535:	89 f8                	mov    %edi,%eax
f0104537:	e8 9e ff ff ff       	call   f01044da <printnum>
f010453c:	83 c4 20             	add    $0x20,%esp
f010453f:	eb 18                	jmp    f0104559 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104541:	83 ec 08             	sub    $0x8,%esp
f0104544:	56                   	push   %esi
f0104545:	ff 75 18             	pushl  0x18(%ebp)
f0104548:	ff d7                	call   *%edi
f010454a:	83 c4 10             	add    $0x10,%esp
f010454d:	eb 03                	jmp    f0104552 <printnum+0x78>
f010454f:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104552:	83 eb 01             	sub    $0x1,%ebx
f0104555:	85 db                	test   %ebx,%ebx
f0104557:	7f e8                	jg     f0104541 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104559:	83 ec 08             	sub    $0x8,%esp
f010455c:	56                   	push   %esi
f010455d:	83 ec 04             	sub    $0x4,%esp
f0104560:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104563:	ff 75 e0             	pushl  -0x20(%ebp)
f0104566:	ff 75 dc             	pushl  -0x24(%ebp)
f0104569:	ff 75 d8             	pushl  -0x28(%ebp)
f010456c:	e8 4f 12 00 00       	call   f01057c0 <__umoddi3>
f0104571:	83 c4 14             	add    $0x14,%esp
f0104574:	0f be 80 28 70 10 f0 	movsbl -0xfef8fd8(%eax),%eax
f010457b:	50                   	push   %eax
f010457c:	ff d7                	call   *%edi
}
f010457e:	83 c4 10             	add    $0x10,%esp
f0104581:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104584:	5b                   	pop    %ebx
f0104585:	5e                   	pop    %esi
f0104586:	5f                   	pop    %edi
f0104587:	5d                   	pop    %ebp
f0104588:	c3                   	ret    

f0104589 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104589:	55                   	push   %ebp
f010458a:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010458c:	83 fa 01             	cmp    $0x1,%edx
f010458f:	7e 0e                	jle    f010459f <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104591:	8b 10                	mov    (%eax),%edx
f0104593:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104596:	89 08                	mov    %ecx,(%eax)
f0104598:	8b 02                	mov    (%edx),%eax
f010459a:	8b 52 04             	mov    0x4(%edx),%edx
f010459d:	eb 22                	jmp    f01045c1 <getuint+0x38>
	else if (lflag)
f010459f:	85 d2                	test   %edx,%edx
f01045a1:	74 10                	je     f01045b3 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01045a3:	8b 10                	mov    (%eax),%edx
f01045a5:	8d 4a 04             	lea    0x4(%edx),%ecx
f01045a8:	89 08                	mov    %ecx,(%eax)
f01045aa:	8b 02                	mov    (%edx),%eax
f01045ac:	ba 00 00 00 00       	mov    $0x0,%edx
f01045b1:	eb 0e                	jmp    f01045c1 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01045b3:	8b 10                	mov    (%eax),%edx
f01045b5:	8d 4a 04             	lea    0x4(%edx),%ecx
f01045b8:	89 08                	mov    %ecx,(%eax)
f01045ba:	8b 02                	mov    (%edx),%eax
f01045bc:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01045c1:	5d                   	pop    %ebp
f01045c2:	c3                   	ret    

f01045c3 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01045c3:	55                   	push   %ebp
f01045c4:	89 e5                	mov    %esp,%ebp
f01045c6:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01045c9:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01045cd:	8b 10                	mov    (%eax),%edx
f01045cf:	3b 50 04             	cmp    0x4(%eax),%edx
f01045d2:	73 0a                	jae    f01045de <sprintputch+0x1b>
		*b->buf++ = ch;
f01045d4:	8d 4a 01             	lea    0x1(%edx),%ecx
f01045d7:	89 08                	mov    %ecx,(%eax)
f01045d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01045dc:	88 02                	mov    %al,(%edx)
}
f01045de:	5d                   	pop    %ebp
f01045df:	c3                   	ret    

f01045e0 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01045e0:	55                   	push   %ebp
f01045e1:	89 e5                	mov    %esp,%ebp
f01045e3:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01045e6:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01045e9:	50                   	push   %eax
f01045ea:	ff 75 10             	pushl  0x10(%ebp)
f01045ed:	ff 75 0c             	pushl  0xc(%ebp)
f01045f0:	ff 75 08             	pushl  0x8(%ebp)
f01045f3:	e8 05 00 00 00       	call   f01045fd <vprintfmt>
	va_end(ap);
}
f01045f8:	83 c4 10             	add    $0x10,%esp
f01045fb:	c9                   	leave  
f01045fc:	c3                   	ret    

f01045fd <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01045fd:	55                   	push   %ebp
f01045fe:	89 e5                	mov    %esp,%ebp
f0104600:	57                   	push   %edi
f0104601:	56                   	push   %esi
f0104602:	53                   	push   %ebx
f0104603:	83 ec 2c             	sub    $0x2c,%esp
f0104606:	8b 75 08             	mov    0x8(%ebp),%esi
f0104609:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010460c:	8b 7d 10             	mov    0x10(%ebp),%edi
f010460f:	eb 12                	jmp    f0104623 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104611:	85 c0                	test   %eax,%eax
f0104613:	0f 84 89 03 00 00    	je     f01049a2 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0104619:	83 ec 08             	sub    $0x8,%esp
f010461c:	53                   	push   %ebx
f010461d:	50                   	push   %eax
f010461e:	ff d6                	call   *%esi
f0104620:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104623:	83 c7 01             	add    $0x1,%edi
f0104626:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010462a:	83 f8 25             	cmp    $0x25,%eax
f010462d:	75 e2                	jne    f0104611 <vprintfmt+0x14>
f010462f:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104633:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010463a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104641:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104648:	ba 00 00 00 00       	mov    $0x0,%edx
f010464d:	eb 07                	jmp    f0104656 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010464f:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104652:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104656:	8d 47 01             	lea    0x1(%edi),%eax
f0104659:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010465c:	0f b6 07             	movzbl (%edi),%eax
f010465f:	0f b6 c8             	movzbl %al,%ecx
f0104662:	83 e8 23             	sub    $0x23,%eax
f0104665:	3c 55                	cmp    $0x55,%al
f0104667:	0f 87 1a 03 00 00    	ja     f0104987 <vprintfmt+0x38a>
f010466d:	0f b6 c0             	movzbl %al,%eax
f0104670:	ff 24 85 e0 70 10 f0 	jmp    *-0xfef8f20(,%eax,4)
f0104677:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010467a:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010467e:	eb d6                	jmp    f0104656 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104680:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104683:	b8 00 00 00 00       	mov    $0x0,%eax
f0104688:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010468b:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010468e:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0104692:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104695:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104698:	83 fa 09             	cmp    $0x9,%edx
f010469b:	77 39                	ja     f01046d6 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010469d:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01046a0:	eb e9                	jmp    f010468b <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01046a2:	8b 45 14             	mov    0x14(%ebp),%eax
f01046a5:	8d 48 04             	lea    0x4(%eax),%ecx
f01046a8:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01046ab:	8b 00                	mov    (%eax),%eax
f01046ad:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046b0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01046b3:	eb 27                	jmp    f01046dc <vprintfmt+0xdf>
f01046b5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01046b8:	85 c0                	test   %eax,%eax
f01046ba:	b9 00 00 00 00       	mov    $0x0,%ecx
f01046bf:	0f 49 c8             	cmovns %eax,%ecx
f01046c2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046c5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01046c8:	eb 8c                	jmp    f0104656 <vprintfmt+0x59>
f01046ca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01046cd:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01046d4:	eb 80                	jmp    f0104656 <vprintfmt+0x59>
f01046d6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01046d9:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f01046dc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01046e0:	0f 89 70 ff ff ff    	jns    f0104656 <vprintfmt+0x59>
				width = precision, precision = -1;
f01046e6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01046e9:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01046ec:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01046f3:	e9 5e ff ff ff       	jmp    f0104656 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01046f8:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046fb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01046fe:	e9 53 ff ff ff       	jmp    f0104656 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104703:	8b 45 14             	mov    0x14(%ebp),%eax
f0104706:	8d 50 04             	lea    0x4(%eax),%edx
f0104709:	89 55 14             	mov    %edx,0x14(%ebp)
f010470c:	83 ec 08             	sub    $0x8,%esp
f010470f:	53                   	push   %ebx
f0104710:	ff 30                	pushl  (%eax)
f0104712:	ff d6                	call   *%esi
			break;
f0104714:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104717:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010471a:	e9 04 ff ff ff       	jmp    f0104623 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010471f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104722:	8d 50 04             	lea    0x4(%eax),%edx
f0104725:	89 55 14             	mov    %edx,0x14(%ebp)
f0104728:	8b 00                	mov    (%eax),%eax
f010472a:	99                   	cltd   
f010472b:	31 d0                	xor    %edx,%eax
f010472d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010472f:	83 f8 09             	cmp    $0x9,%eax
f0104732:	7f 0b                	jg     f010473f <vprintfmt+0x142>
f0104734:	8b 14 85 40 72 10 f0 	mov    -0xfef8dc0(,%eax,4),%edx
f010473b:	85 d2                	test   %edx,%edx
f010473d:	75 18                	jne    f0104757 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f010473f:	50                   	push   %eax
f0104740:	68 40 70 10 f0       	push   $0xf0107040
f0104745:	53                   	push   %ebx
f0104746:	56                   	push   %esi
f0104747:	e8 94 fe ff ff       	call   f01045e0 <printfmt>
f010474c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010474f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104752:	e9 cc fe ff ff       	jmp    f0104623 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104757:	52                   	push   %edx
f0104758:	68 19 68 10 f0       	push   $0xf0106819
f010475d:	53                   	push   %ebx
f010475e:	56                   	push   %esi
f010475f:	e8 7c fe ff ff       	call   f01045e0 <printfmt>
f0104764:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104767:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010476a:	e9 b4 fe ff ff       	jmp    f0104623 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010476f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104772:	8d 50 04             	lea    0x4(%eax),%edx
f0104775:	89 55 14             	mov    %edx,0x14(%ebp)
f0104778:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010477a:	85 ff                	test   %edi,%edi
f010477c:	b8 39 70 10 f0       	mov    $0xf0107039,%eax
f0104781:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104784:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104788:	0f 8e 94 00 00 00    	jle    f0104822 <vprintfmt+0x225>
f010478e:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104792:	0f 84 98 00 00 00    	je     f0104830 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104798:	83 ec 08             	sub    $0x8,%esp
f010479b:	ff 75 d0             	pushl  -0x30(%ebp)
f010479e:	57                   	push   %edi
f010479f:	e8 5f 03 00 00       	call   f0104b03 <strnlen>
f01047a4:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01047a7:	29 c1                	sub    %eax,%ecx
f01047a9:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f01047ac:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01047af:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01047b3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01047b6:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01047b9:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01047bb:	eb 0f                	jmp    f01047cc <vprintfmt+0x1cf>
					putch(padc, putdat);
f01047bd:	83 ec 08             	sub    $0x8,%esp
f01047c0:	53                   	push   %ebx
f01047c1:	ff 75 e0             	pushl  -0x20(%ebp)
f01047c4:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01047c6:	83 ef 01             	sub    $0x1,%edi
f01047c9:	83 c4 10             	add    $0x10,%esp
f01047cc:	85 ff                	test   %edi,%edi
f01047ce:	7f ed                	jg     f01047bd <vprintfmt+0x1c0>
f01047d0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01047d3:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01047d6:	85 c9                	test   %ecx,%ecx
f01047d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01047dd:	0f 49 c1             	cmovns %ecx,%eax
f01047e0:	29 c1                	sub    %eax,%ecx
f01047e2:	89 75 08             	mov    %esi,0x8(%ebp)
f01047e5:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01047e8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01047eb:	89 cb                	mov    %ecx,%ebx
f01047ed:	eb 4d                	jmp    f010483c <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01047ef:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01047f3:	74 1b                	je     f0104810 <vprintfmt+0x213>
f01047f5:	0f be c0             	movsbl %al,%eax
f01047f8:	83 e8 20             	sub    $0x20,%eax
f01047fb:	83 f8 5e             	cmp    $0x5e,%eax
f01047fe:	76 10                	jbe    f0104810 <vprintfmt+0x213>
					putch('?', putdat);
f0104800:	83 ec 08             	sub    $0x8,%esp
f0104803:	ff 75 0c             	pushl  0xc(%ebp)
f0104806:	6a 3f                	push   $0x3f
f0104808:	ff 55 08             	call   *0x8(%ebp)
f010480b:	83 c4 10             	add    $0x10,%esp
f010480e:	eb 0d                	jmp    f010481d <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0104810:	83 ec 08             	sub    $0x8,%esp
f0104813:	ff 75 0c             	pushl  0xc(%ebp)
f0104816:	52                   	push   %edx
f0104817:	ff 55 08             	call   *0x8(%ebp)
f010481a:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010481d:	83 eb 01             	sub    $0x1,%ebx
f0104820:	eb 1a                	jmp    f010483c <vprintfmt+0x23f>
f0104822:	89 75 08             	mov    %esi,0x8(%ebp)
f0104825:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104828:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010482b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010482e:	eb 0c                	jmp    f010483c <vprintfmt+0x23f>
f0104830:	89 75 08             	mov    %esi,0x8(%ebp)
f0104833:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104836:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104839:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010483c:	83 c7 01             	add    $0x1,%edi
f010483f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104843:	0f be d0             	movsbl %al,%edx
f0104846:	85 d2                	test   %edx,%edx
f0104848:	74 23                	je     f010486d <vprintfmt+0x270>
f010484a:	85 f6                	test   %esi,%esi
f010484c:	78 a1                	js     f01047ef <vprintfmt+0x1f2>
f010484e:	83 ee 01             	sub    $0x1,%esi
f0104851:	79 9c                	jns    f01047ef <vprintfmt+0x1f2>
f0104853:	89 df                	mov    %ebx,%edi
f0104855:	8b 75 08             	mov    0x8(%ebp),%esi
f0104858:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010485b:	eb 18                	jmp    f0104875 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010485d:	83 ec 08             	sub    $0x8,%esp
f0104860:	53                   	push   %ebx
f0104861:	6a 20                	push   $0x20
f0104863:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104865:	83 ef 01             	sub    $0x1,%edi
f0104868:	83 c4 10             	add    $0x10,%esp
f010486b:	eb 08                	jmp    f0104875 <vprintfmt+0x278>
f010486d:	89 df                	mov    %ebx,%edi
f010486f:	8b 75 08             	mov    0x8(%ebp),%esi
f0104872:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104875:	85 ff                	test   %edi,%edi
f0104877:	7f e4                	jg     f010485d <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104879:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010487c:	e9 a2 fd ff ff       	jmp    f0104623 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104881:	83 fa 01             	cmp    $0x1,%edx
f0104884:	7e 16                	jle    f010489c <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0104886:	8b 45 14             	mov    0x14(%ebp),%eax
f0104889:	8d 50 08             	lea    0x8(%eax),%edx
f010488c:	89 55 14             	mov    %edx,0x14(%ebp)
f010488f:	8b 50 04             	mov    0x4(%eax),%edx
f0104892:	8b 00                	mov    (%eax),%eax
f0104894:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104897:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010489a:	eb 32                	jmp    f01048ce <vprintfmt+0x2d1>
	else if (lflag)
f010489c:	85 d2                	test   %edx,%edx
f010489e:	74 18                	je     f01048b8 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f01048a0:	8b 45 14             	mov    0x14(%ebp),%eax
f01048a3:	8d 50 04             	lea    0x4(%eax),%edx
f01048a6:	89 55 14             	mov    %edx,0x14(%ebp)
f01048a9:	8b 00                	mov    (%eax),%eax
f01048ab:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01048ae:	89 c1                	mov    %eax,%ecx
f01048b0:	c1 f9 1f             	sar    $0x1f,%ecx
f01048b3:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01048b6:	eb 16                	jmp    f01048ce <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f01048b8:	8b 45 14             	mov    0x14(%ebp),%eax
f01048bb:	8d 50 04             	lea    0x4(%eax),%edx
f01048be:	89 55 14             	mov    %edx,0x14(%ebp)
f01048c1:	8b 00                	mov    (%eax),%eax
f01048c3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01048c6:	89 c1                	mov    %eax,%ecx
f01048c8:	c1 f9 1f             	sar    $0x1f,%ecx
f01048cb:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01048ce:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01048d1:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01048d4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01048d9:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01048dd:	79 74                	jns    f0104953 <vprintfmt+0x356>
				putch('-', putdat);
f01048df:	83 ec 08             	sub    $0x8,%esp
f01048e2:	53                   	push   %ebx
f01048e3:	6a 2d                	push   $0x2d
f01048e5:	ff d6                	call   *%esi
				num = -(long long) num;
f01048e7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01048ea:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01048ed:	f7 d8                	neg    %eax
f01048ef:	83 d2 00             	adc    $0x0,%edx
f01048f2:	f7 da                	neg    %edx
f01048f4:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01048f7:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01048fc:	eb 55                	jmp    f0104953 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01048fe:	8d 45 14             	lea    0x14(%ebp),%eax
f0104901:	e8 83 fc ff ff       	call   f0104589 <getuint>
			base = 10;
f0104906:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010490b:	eb 46                	jmp    f0104953 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f010490d:	8d 45 14             	lea    0x14(%ebp),%eax
f0104910:	e8 74 fc ff ff       	call   f0104589 <getuint>
			base = 8;
f0104915:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010491a:	eb 37                	jmp    f0104953 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f010491c:	83 ec 08             	sub    $0x8,%esp
f010491f:	53                   	push   %ebx
f0104920:	6a 30                	push   $0x30
f0104922:	ff d6                	call   *%esi
			putch('x', putdat);
f0104924:	83 c4 08             	add    $0x8,%esp
f0104927:	53                   	push   %ebx
f0104928:	6a 78                	push   $0x78
f010492a:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010492c:	8b 45 14             	mov    0x14(%ebp),%eax
f010492f:	8d 50 04             	lea    0x4(%eax),%edx
f0104932:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104935:	8b 00                	mov    (%eax),%eax
f0104937:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010493c:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010493f:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104944:	eb 0d                	jmp    f0104953 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104946:	8d 45 14             	lea    0x14(%ebp),%eax
f0104949:	e8 3b fc ff ff       	call   f0104589 <getuint>
			base = 16;
f010494e:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104953:	83 ec 0c             	sub    $0xc,%esp
f0104956:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010495a:	57                   	push   %edi
f010495b:	ff 75 e0             	pushl  -0x20(%ebp)
f010495e:	51                   	push   %ecx
f010495f:	52                   	push   %edx
f0104960:	50                   	push   %eax
f0104961:	89 da                	mov    %ebx,%edx
f0104963:	89 f0                	mov    %esi,%eax
f0104965:	e8 70 fb ff ff       	call   f01044da <printnum>
			break;
f010496a:	83 c4 20             	add    $0x20,%esp
f010496d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104970:	e9 ae fc ff ff       	jmp    f0104623 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104975:	83 ec 08             	sub    $0x8,%esp
f0104978:	53                   	push   %ebx
f0104979:	51                   	push   %ecx
f010497a:	ff d6                	call   *%esi
			break;
f010497c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010497f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104982:	e9 9c fc ff ff       	jmp    f0104623 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104987:	83 ec 08             	sub    $0x8,%esp
f010498a:	53                   	push   %ebx
f010498b:	6a 25                	push   $0x25
f010498d:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010498f:	83 c4 10             	add    $0x10,%esp
f0104992:	eb 03                	jmp    f0104997 <vprintfmt+0x39a>
f0104994:	83 ef 01             	sub    $0x1,%edi
f0104997:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010499b:	75 f7                	jne    f0104994 <vprintfmt+0x397>
f010499d:	e9 81 fc ff ff       	jmp    f0104623 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01049a2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01049a5:	5b                   	pop    %ebx
f01049a6:	5e                   	pop    %esi
f01049a7:	5f                   	pop    %edi
f01049a8:	5d                   	pop    %ebp
f01049a9:	c3                   	ret    

f01049aa <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01049aa:	55                   	push   %ebp
f01049ab:	89 e5                	mov    %esp,%ebp
f01049ad:	83 ec 18             	sub    $0x18,%esp
f01049b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01049b3:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01049b6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01049b9:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01049bd:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01049c0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01049c7:	85 c0                	test   %eax,%eax
f01049c9:	74 26                	je     f01049f1 <vsnprintf+0x47>
f01049cb:	85 d2                	test   %edx,%edx
f01049cd:	7e 22                	jle    f01049f1 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01049cf:	ff 75 14             	pushl  0x14(%ebp)
f01049d2:	ff 75 10             	pushl  0x10(%ebp)
f01049d5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01049d8:	50                   	push   %eax
f01049d9:	68 c3 45 10 f0       	push   $0xf01045c3
f01049de:	e8 1a fc ff ff       	call   f01045fd <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01049e3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01049e6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01049e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01049ec:	83 c4 10             	add    $0x10,%esp
f01049ef:	eb 05                	jmp    f01049f6 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01049f1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01049f6:	c9                   	leave  
f01049f7:	c3                   	ret    

f01049f8 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01049f8:	55                   	push   %ebp
f01049f9:	89 e5                	mov    %esp,%ebp
f01049fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01049fe:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104a01:	50                   	push   %eax
f0104a02:	ff 75 10             	pushl  0x10(%ebp)
f0104a05:	ff 75 0c             	pushl  0xc(%ebp)
f0104a08:	ff 75 08             	pushl  0x8(%ebp)
f0104a0b:	e8 9a ff ff ff       	call   f01049aa <vsnprintf>
	va_end(ap);

	return rc;
}
f0104a10:	c9                   	leave  
f0104a11:	c3                   	ret    

f0104a12 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104a12:	55                   	push   %ebp
f0104a13:	89 e5                	mov    %esp,%ebp
f0104a15:	57                   	push   %edi
f0104a16:	56                   	push   %esi
f0104a17:	53                   	push   %ebx
f0104a18:	83 ec 0c             	sub    $0xc,%esp
f0104a1b:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104a1e:	85 c0                	test   %eax,%eax
f0104a20:	74 11                	je     f0104a33 <readline+0x21>
		cprintf("%s", prompt);
f0104a22:	83 ec 08             	sub    $0x8,%esp
f0104a25:	50                   	push   %eax
f0104a26:	68 19 68 10 f0       	push   $0xf0106819
f0104a2b:	e8 3e ec ff ff       	call   f010366e <cprintf>
f0104a30:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104a33:	83 ec 0c             	sub    $0xc,%esp
f0104a36:	6a 00                	push   $0x0
f0104a38:	e8 22 bd ff ff       	call   f010075f <iscons>
f0104a3d:	89 c7                	mov    %eax,%edi
f0104a3f:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104a42:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104a47:	e8 02 bd ff ff       	call   f010074e <getchar>
f0104a4c:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104a4e:	85 c0                	test   %eax,%eax
f0104a50:	79 18                	jns    f0104a6a <readline+0x58>
			cprintf("read error: %e\n", c);
f0104a52:	83 ec 08             	sub    $0x8,%esp
f0104a55:	50                   	push   %eax
f0104a56:	68 68 72 10 f0       	push   $0xf0107268
f0104a5b:	e8 0e ec ff ff       	call   f010366e <cprintf>
			return NULL;
f0104a60:	83 c4 10             	add    $0x10,%esp
f0104a63:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a68:	eb 79                	jmp    f0104ae3 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104a6a:	83 f8 08             	cmp    $0x8,%eax
f0104a6d:	0f 94 c2             	sete   %dl
f0104a70:	83 f8 7f             	cmp    $0x7f,%eax
f0104a73:	0f 94 c0             	sete   %al
f0104a76:	08 c2                	or     %al,%dl
f0104a78:	74 1a                	je     f0104a94 <readline+0x82>
f0104a7a:	85 f6                	test   %esi,%esi
f0104a7c:	7e 16                	jle    f0104a94 <readline+0x82>
			if (echoing)
f0104a7e:	85 ff                	test   %edi,%edi
f0104a80:	74 0d                	je     f0104a8f <readline+0x7d>
				cputchar('\b');
f0104a82:	83 ec 0c             	sub    $0xc,%esp
f0104a85:	6a 08                	push   $0x8
f0104a87:	e8 b2 bc ff ff       	call   f010073e <cputchar>
f0104a8c:	83 c4 10             	add    $0x10,%esp
			i--;
f0104a8f:	83 ee 01             	sub    $0x1,%esi
f0104a92:	eb b3                	jmp    f0104a47 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104a94:	83 fb 1f             	cmp    $0x1f,%ebx
f0104a97:	7e 23                	jle    f0104abc <readline+0xaa>
f0104a99:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104a9f:	7f 1b                	jg     f0104abc <readline+0xaa>
			if (echoing)
f0104aa1:	85 ff                	test   %edi,%edi
f0104aa3:	74 0c                	je     f0104ab1 <readline+0x9f>
				cputchar(c);
f0104aa5:	83 ec 0c             	sub    $0xc,%esp
f0104aa8:	53                   	push   %ebx
f0104aa9:	e8 90 bc ff ff       	call   f010073e <cputchar>
f0104aae:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104ab1:	88 9e 80 aa 22 f0    	mov    %bl,-0xfdd5580(%esi)
f0104ab7:	8d 76 01             	lea    0x1(%esi),%esi
f0104aba:	eb 8b                	jmp    f0104a47 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104abc:	83 fb 0a             	cmp    $0xa,%ebx
f0104abf:	74 05                	je     f0104ac6 <readline+0xb4>
f0104ac1:	83 fb 0d             	cmp    $0xd,%ebx
f0104ac4:	75 81                	jne    f0104a47 <readline+0x35>
			if (echoing)
f0104ac6:	85 ff                	test   %edi,%edi
f0104ac8:	74 0d                	je     f0104ad7 <readline+0xc5>
				cputchar('\n');
f0104aca:	83 ec 0c             	sub    $0xc,%esp
f0104acd:	6a 0a                	push   $0xa
f0104acf:	e8 6a bc ff ff       	call   f010073e <cputchar>
f0104ad4:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104ad7:	c6 86 80 aa 22 f0 00 	movb   $0x0,-0xfdd5580(%esi)
			return buf;
f0104ade:	b8 80 aa 22 f0       	mov    $0xf022aa80,%eax
		}
	}
}
f0104ae3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104ae6:	5b                   	pop    %ebx
f0104ae7:	5e                   	pop    %esi
f0104ae8:	5f                   	pop    %edi
f0104ae9:	5d                   	pop    %ebp
f0104aea:	c3                   	ret    

f0104aeb <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104aeb:	55                   	push   %ebp
f0104aec:	89 e5                	mov    %esp,%ebp
f0104aee:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104af1:	b8 00 00 00 00       	mov    $0x0,%eax
f0104af6:	eb 03                	jmp    f0104afb <strlen+0x10>
		n++;
f0104af8:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104afb:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104aff:	75 f7                	jne    f0104af8 <strlen+0xd>
		n++;
	return n;
}
f0104b01:	5d                   	pop    %ebp
f0104b02:	c3                   	ret    

f0104b03 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104b03:	55                   	push   %ebp
f0104b04:	89 e5                	mov    %esp,%ebp
f0104b06:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104b09:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104b0c:	ba 00 00 00 00       	mov    $0x0,%edx
f0104b11:	eb 03                	jmp    f0104b16 <strnlen+0x13>
		n++;
f0104b13:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104b16:	39 c2                	cmp    %eax,%edx
f0104b18:	74 08                	je     f0104b22 <strnlen+0x1f>
f0104b1a:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104b1e:	75 f3                	jne    f0104b13 <strnlen+0x10>
f0104b20:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104b22:	5d                   	pop    %ebp
f0104b23:	c3                   	ret    

f0104b24 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104b24:	55                   	push   %ebp
f0104b25:	89 e5                	mov    %esp,%ebp
f0104b27:	53                   	push   %ebx
f0104b28:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b2b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104b2e:	89 c2                	mov    %eax,%edx
f0104b30:	83 c2 01             	add    $0x1,%edx
f0104b33:	83 c1 01             	add    $0x1,%ecx
f0104b36:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104b3a:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104b3d:	84 db                	test   %bl,%bl
f0104b3f:	75 ef                	jne    f0104b30 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104b41:	5b                   	pop    %ebx
f0104b42:	5d                   	pop    %ebp
f0104b43:	c3                   	ret    

f0104b44 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104b44:	55                   	push   %ebp
f0104b45:	89 e5                	mov    %esp,%ebp
f0104b47:	53                   	push   %ebx
f0104b48:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104b4b:	53                   	push   %ebx
f0104b4c:	e8 9a ff ff ff       	call   f0104aeb <strlen>
f0104b51:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104b54:	ff 75 0c             	pushl  0xc(%ebp)
f0104b57:	01 d8                	add    %ebx,%eax
f0104b59:	50                   	push   %eax
f0104b5a:	e8 c5 ff ff ff       	call   f0104b24 <strcpy>
	return dst;
}
f0104b5f:	89 d8                	mov    %ebx,%eax
f0104b61:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104b64:	c9                   	leave  
f0104b65:	c3                   	ret    

f0104b66 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104b66:	55                   	push   %ebp
f0104b67:	89 e5                	mov    %esp,%ebp
f0104b69:	56                   	push   %esi
f0104b6a:	53                   	push   %ebx
f0104b6b:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b6e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104b71:	89 f3                	mov    %esi,%ebx
f0104b73:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104b76:	89 f2                	mov    %esi,%edx
f0104b78:	eb 0f                	jmp    f0104b89 <strncpy+0x23>
		*dst++ = *src;
f0104b7a:	83 c2 01             	add    $0x1,%edx
f0104b7d:	0f b6 01             	movzbl (%ecx),%eax
f0104b80:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104b83:	80 39 01             	cmpb   $0x1,(%ecx)
f0104b86:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104b89:	39 da                	cmp    %ebx,%edx
f0104b8b:	75 ed                	jne    f0104b7a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104b8d:	89 f0                	mov    %esi,%eax
f0104b8f:	5b                   	pop    %ebx
f0104b90:	5e                   	pop    %esi
f0104b91:	5d                   	pop    %ebp
f0104b92:	c3                   	ret    

f0104b93 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104b93:	55                   	push   %ebp
f0104b94:	89 e5                	mov    %esp,%ebp
f0104b96:	56                   	push   %esi
f0104b97:	53                   	push   %ebx
f0104b98:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b9b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104b9e:	8b 55 10             	mov    0x10(%ebp),%edx
f0104ba1:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104ba3:	85 d2                	test   %edx,%edx
f0104ba5:	74 21                	je     f0104bc8 <strlcpy+0x35>
f0104ba7:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104bab:	89 f2                	mov    %esi,%edx
f0104bad:	eb 09                	jmp    f0104bb8 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104baf:	83 c2 01             	add    $0x1,%edx
f0104bb2:	83 c1 01             	add    $0x1,%ecx
f0104bb5:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104bb8:	39 c2                	cmp    %eax,%edx
f0104bba:	74 09                	je     f0104bc5 <strlcpy+0x32>
f0104bbc:	0f b6 19             	movzbl (%ecx),%ebx
f0104bbf:	84 db                	test   %bl,%bl
f0104bc1:	75 ec                	jne    f0104baf <strlcpy+0x1c>
f0104bc3:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104bc5:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104bc8:	29 f0                	sub    %esi,%eax
}
f0104bca:	5b                   	pop    %ebx
f0104bcb:	5e                   	pop    %esi
f0104bcc:	5d                   	pop    %ebp
f0104bcd:	c3                   	ret    

f0104bce <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104bce:	55                   	push   %ebp
f0104bcf:	89 e5                	mov    %esp,%ebp
f0104bd1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104bd4:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104bd7:	eb 06                	jmp    f0104bdf <strcmp+0x11>
		p++, q++;
f0104bd9:	83 c1 01             	add    $0x1,%ecx
f0104bdc:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104bdf:	0f b6 01             	movzbl (%ecx),%eax
f0104be2:	84 c0                	test   %al,%al
f0104be4:	74 04                	je     f0104bea <strcmp+0x1c>
f0104be6:	3a 02                	cmp    (%edx),%al
f0104be8:	74 ef                	je     f0104bd9 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104bea:	0f b6 c0             	movzbl %al,%eax
f0104bed:	0f b6 12             	movzbl (%edx),%edx
f0104bf0:	29 d0                	sub    %edx,%eax
}
f0104bf2:	5d                   	pop    %ebp
f0104bf3:	c3                   	ret    

f0104bf4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104bf4:	55                   	push   %ebp
f0104bf5:	89 e5                	mov    %esp,%ebp
f0104bf7:	53                   	push   %ebx
f0104bf8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bfb:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104bfe:	89 c3                	mov    %eax,%ebx
f0104c00:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104c03:	eb 06                	jmp    f0104c0b <strncmp+0x17>
		n--, p++, q++;
f0104c05:	83 c0 01             	add    $0x1,%eax
f0104c08:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104c0b:	39 d8                	cmp    %ebx,%eax
f0104c0d:	74 15                	je     f0104c24 <strncmp+0x30>
f0104c0f:	0f b6 08             	movzbl (%eax),%ecx
f0104c12:	84 c9                	test   %cl,%cl
f0104c14:	74 04                	je     f0104c1a <strncmp+0x26>
f0104c16:	3a 0a                	cmp    (%edx),%cl
f0104c18:	74 eb                	je     f0104c05 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104c1a:	0f b6 00             	movzbl (%eax),%eax
f0104c1d:	0f b6 12             	movzbl (%edx),%edx
f0104c20:	29 d0                	sub    %edx,%eax
f0104c22:	eb 05                	jmp    f0104c29 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104c24:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104c29:	5b                   	pop    %ebx
f0104c2a:	5d                   	pop    %ebp
f0104c2b:	c3                   	ret    

f0104c2c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104c2c:	55                   	push   %ebp
f0104c2d:	89 e5                	mov    %esp,%ebp
f0104c2f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c32:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104c36:	eb 07                	jmp    f0104c3f <strchr+0x13>
		if (*s == c)
f0104c38:	38 ca                	cmp    %cl,%dl
f0104c3a:	74 0f                	je     f0104c4b <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104c3c:	83 c0 01             	add    $0x1,%eax
f0104c3f:	0f b6 10             	movzbl (%eax),%edx
f0104c42:	84 d2                	test   %dl,%dl
f0104c44:	75 f2                	jne    f0104c38 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104c46:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104c4b:	5d                   	pop    %ebp
f0104c4c:	c3                   	ret    

f0104c4d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104c4d:	55                   	push   %ebp
f0104c4e:	89 e5                	mov    %esp,%ebp
f0104c50:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c53:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104c57:	eb 03                	jmp    f0104c5c <strfind+0xf>
f0104c59:	83 c0 01             	add    $0x1,%eax
f0104c5c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104c5f:	38 ca                	cmp    %cl,%dl
f0104c61:	74 04                	je     f0104c67 <strfind+0x1a>
f0104c63:	84 d2                	test   %dl,%dl
f0104c65:	75 f2                	jne    f0104c59 <strfind+0xc>
			break;
	return (char *) s;
}
f0104c67:	5d                   	pop    %ebp
f0104c68:	c3                   	ret    

f0104c69 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104c69:	55                   	push   %ebp
f0104c6a:	89 e5                	mov    %esp,%ebp
f0104c6c:	57                   	push   %edi
f0104c6d:	56                   	push   %esi
f0104c6e:	53                   	push   %ebx
f0104c6f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104c72:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104c75:	85 c9                	test   %ecx,%ecx
f0104c77:	74 36                	je     f0104caf <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104c79:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104c7f:	75 28                	jne    f0104ca9 <memset+0x40>
f0104c81:	f6 c1 03             	test   $0x3,%cl
f0104c84:	75 23                	jne    f0104ca9 <memset+0x40>
		c &= 0xFF;
f0104c86:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104c8a:	89 d3                	mov    %edx,%ebx
f0104c8c:	c1 e3 08             	shl    $0x8,%ebx
f0104c8f:	89 d6                	mov    %edx,%esi
f0104c91:	c1 e6 18             	shl    $0x18,%esi
f0104c94:	89 d0                	mov    %edx,%eax
f0104c96:	c1 e0 10             	shl    $0x10,%eax
f0104c99:	09 f0                	or     %esi,%eax
f0104c9b:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0104c9d:	89 d8                	mov    %ebx,%eax
f0104c9f:	09 d0                	or     %edx,%eax
f0104ca1:	c1 e9 02             	shr    $0x2,%ecx
f0104ca4:	fc                   	cld    
f0104ca5:	f3 ab                	rep stos %eax,%es:(%edi)
f0104ca7:	eb 06                	jmp    f0104caf <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104ca9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104cac:	fc                   	cld    
f0104cad:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104caf:	89 f8                	mov    %edi,%eax
f0104cb1:	5b                   	pop    %ebx
f0104cb2:	5e                   	pop    %esi
f0104cb3:	5f                   	pop    %edi
f0104cb4:	5d                   	pop    %ebp
f0104cb5:	c3                   	ret    

f0104cb6 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104cb6:	55                   	push   %ebp
f0104cb7:	89 e5                	mov    %esp,%ebp
f0104cb9:	57                   	push   %edi
f0104cba:	56                   	push   %esi
f0104cbb:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cbe:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104cc1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104cc4:	39 c6                	cmp    %eax,%esi
f0104cc6:	73 35                	jae    f0104cfd <memmove+0x47>
f0104cc8:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104ccb:	39 d0                	cmp    %edx,%eax
f0104ccd:	73 2e                	jae    f0104cfd <memmove+0x47>
		s += n;
		d += n;
f0104ccf:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104cd2:	89 d6                	mov    %edx,%esi
f0104cd4:	09 fe                	or     %edi,%esi
f0104cd6:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104cdc:	75 13                	jne    f0104cf1 <memmove+0x3b>
f0104cde:	f6 c1 03             	test   $0x3,%cl
f0104ce1:	75 0e                	jne    f0104cf1 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104ce3:	83 ef 04             	sub    $0x4,%edi
f0104ce6:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104ce9:	c1 e9 02             	shr    $0x2,%ecx
f0104cec:	fd                   	std    
f0104ced:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104cef:	eb 09                	jmp    f0104cfa <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104cf1:	83 ef 01             	sub    $0x1,%edi
f0104cf4:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104cf7:	fd                   	std    
f0104cf8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104cfa:	fc                   	cld    
f0104cfb:	eb 1d                	jmp    f0104d1a <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104cfd:	89 f2                	mov    %esi,%edx
f0104cff:	09 c2                	or     %eax,%edx
f0104d01:	f6 c2 03             	test   $0x3,%dl
f0104d04:	75 0f                	jne    f0104d15 <memmove+0x5f>
f0104d06:	f6 c1 03             	test   $0x3,%cl
f0104d09:	75 0a                	jne    f0104d15 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0104d0b:	c1 e9 02             	shr    $0x2,%ecx
f0104d0e:	89 c7                	mov    %eax,%edi
f0104d10:	fc                   	cld    
f0104d11:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104d13:	eb 05                	jmp    f0104d1a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104d15:	89 c7                	mov    %eax,%edi
f0104d17:	fc                   	cld    
f0104d18:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104d1a:	5e                   	pop    %esi
f0104d1b:	5f                   	pop    %edi
f0104d1c:	5d                   	pop    %ebp
f0104d1d:	c3                   	ret    

f0104d1e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104d1e:	55                   	push   %ebp
f0104d1f:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104d21:	ff 75 10             	pushl  0x10(%ebp)
f0104d24:	ff 75 0c             	pushl  0xc(%ebp)
f0104d27:	ff 75 08             	pushl  0x8(%ebp)
f0104d2a:	e8 87 ff ff ff       	call   f0104cb6 <memmove>
}
f0104d2f:	c9                   	leave  
f0104d30:	c3                   	ret    

f0104d31 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104d31:	55                   	push   %ebp
f0104d32:	89 e5                	mov    %esp,%ebp
f0104d34:	56                   	push   %esi
f0104d35:	53                   	push   %ebx
f0104d36:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d39:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104d3c:	89 c6                	mov    %eax,%esi
f0104d3e:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104d41:	eb 1a                	jmp    f0104d5d <memcmp+0x2c>
		if (*s1 != *s2)
f0104d43:	0f b6 08             	movzbl (%eax),%ecx
f0104d46:	0f b6 1a             	movzbl (%edx),%ebx
f0104d49:	38 d9                	cmp    %bl,%cl
f0104d4b:	74 0a                	je     f0104d57 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104d4d:	0f b6 c1             	movzbl %cl,%eax
f0104d50:	0f b6 db             	movzbl %bl,%ebx
f0104d53:	29 d8                	sub    %ebx,%eax
f0104d55:	eb 0f                	jmp    f0104d66 <memcmp+0x35>
		s1++, s2++;
f0104d57:	83 c0 01             	add    $0x1,%eax
f0104d5a:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104d5d:	39 f0                	cmp    %esi,%eax
f0104d5f:	75 e2                	jne    f0104d43 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104d61:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104d66:	5b                   	pop    %ebx
f0104d67:	5e                   	pop    %esi
f0104d68:	5d                   	pop    %ebp
f0104d69:	c3                   	ret    

f0104d6a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104d6a:	55                   	push   %ebp
f0104d6b:	89 e5                	mov    %esp,%ebp
f0104d6d:	53                   	push   %ebx
f0104d6e:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104d71:	89 c1                	mov    %eax,%ecx
f0104d73:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104d76:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104d7a:	eb 0a                	jmp    f0104d86 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104d7c:	0f b6 10             	movzbl (%eax),%edx
f0104d7f:	39 da                	cmp    %ebx,%edx
f0104d81:	74 07                	je     f0104d8a <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104d83:	83 c0 01             	add    $0x1,%eax
f0104d86:	39 c8                	cmp    %ecx,%eax
f0104d88:	72 f2                	jb     f0104d7c <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104d8a:	5b                   	pop    %ebx
f0104d8b:	5d                   	pop    %ebp
f0104d8c:	c3                   	ret    

f0104d8d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104d8d:	55                   	push   %ebp
f0104d8e:	89 e5                	mov    %esp,%ebp
f0104d90:	57                   	push   %edi
f0104d91:	56                   	push   %esi
f0104d92:	53                   	push   %ebx
f0104d93:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104d96:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104d99:	eb 03                	jmp    f0104d9e <strtol+0x11>
		s++;
f0104d9b:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104d9e:	0f b6 01             	movzbl (%ecx),%eax
f0104da1:	3c 20                	cmp    $0x20,%al
f0104da3:	74 f6                	je     f0104d9b <strtol+0xe>
f0104da5:	3c 09                	cmp    $0x9,%al
f0104da7:	74 f2                	je     f0104d9b <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104da9:	3c 2b                	cmp    $0x2b,%al
f0104dab:	75 0a                	jne    f0104db7 <strtol+0x2a>
		s++;
f0104dad:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104db0:	bf 00 00 00 00       	mov    $0x0,%edi
f0104db5:	eb 11                	jmp    f0104dc8 <strtol+0x3b>
f0104db7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104dbc:	3c 2d                	cmp    $0x2d,%al
f0104dbe:	75 08                	jne    f0104dc8 <strtol+0x3b>
		s++, neg = 1;
f0104dc0:	83 c1 01             	add    $0x1,%ecx
f0104dc3:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104dc8:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104dce:	75 15                	jne    f0104de5 <strtol+0x58>
f0104dd0:	80 39 30             	cmpb   $0x30,(%ecx)
f0104dd3:	75 10                	jne    f0104de5 <strtol+0x58>
f0104dd5:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104dd9:	75 7c                	jne    f0104e57 <strtol+0xca>
		s += 2, base = 16;
f0104ddb:	83 c1 02             	add    $0x2,%ecx
f0104dde:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104de3:	eb 16                	jmp    f0104dfb <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104de5:	85 db                	test   %ebx,%ebx
f0104de7:	75 12                	jne    f0104dfb <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104de9:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104dee:	80 39 30             	cmpb   $0x30,(%ecx)
f0104df1:	75 08                	jne    f0104dfb <strtol+0x6e>
		s++, base = 8;
f0104df3:	83 c1 01             	add    $0x1,%ecx
f0104df6:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104dfb:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e00:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104e03:	0f b6 11             	movzbl (%ecx),%edx
f0104e06:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104e09:	89 f3                	mov    %esi,%ebx
f0104e0b:	80 fb 09             	cmp    $0x9,%bl
f0104e0e:	77 08                	ja     f0104e18 <strtol+0x8b>
			dig = *s - '0';
f0104e10:	0f be d2             	movsbl %dl,%edx
f0104e13:	83 ea 30             	sub    $0x30,%edx
f0104e16:	eb 22                	jmp    f0104e3a <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104e18:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104e1b:	89 f3                	mov    %esi,%ebx
f0104e1d:	80 fb 19             	cmp    $0x19,%bl
f0104e20:	77 08                	ja     f0104e2a <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104e22:	0f be d2             	movsbl %dl,%edx
f0104e25:	83 ea 57             	sub    $0x57,%edx
f0104e28:	eb 10                	jmp    f0104e3a <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104e2a:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104e2d:	89 f3                	mov    %esi,%ebx
f0104e2f:	80 fb 19             	cmp    $0x19,%bl
f0104e32:	77 16                	ja     f0104e4a <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104e34:	0f be d2             	movsbl %dl,%edx
f0104e37:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104e3a:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104e3d:	7d 0b                	jge    f0104e4a <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104e3f:	83 c1 01             	add    $0x1,%ecx
f0104e42:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104e46:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104e48:	eb b9                	jmp    f0104e03 <strtol+0x76>

	if (endptr)
f0104e4a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104e4e:	74 0d                	je     f0104e5d <strtol+0xd0>
		*endptr = (char *) s;
f0104e50:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104e53:	89 0e                	mov    %ecx,(%esi)
f0104e55:	eb 06                	jmp    f0104e5d <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104e57:	85 db                	test   %ebx,%ebx
f0104e59:	74 98                	je     f0104df3 <strtol+0x66>
f0104e5b:	eb 9e                	jmp    f0104dfb <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104e5d:	89 c2                	mov    %eax,%edx
f0104e5f:	f7 da                	neg    %edx
f0104e61:	85 ff                	test   %edi,%edi
f0104e63:	0f 45 c2             	cmovne %edx,%eax
}
f0104e66:	5b                   	pop    %ebx
f0104e67:	5e                   	pop    %esi
f0104e68:	5f                   	pop    %edi
f0104e69:	5d                   	pop    %ebp
f0104e6a:	c3                   	ret    
f0104e6b:	90                   	nop

f0104e6c <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0104e6c:	fa                   	cli    

	xorw    %ax, %ax
f0104e6d:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0104e6f:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104e71:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104e73:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0104e75:	0f 01 16             	lgdtl  (%esi)
f0104e78:	74 70                	je     f0104eea <mpsearch1+0x3>
	movl    %cr0, %eax
f0104e7a:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0104e7d:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0104e81:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0104e84:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0104e8a:	08 00                	or     %al,(%eax)

f0104e8c <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0104e8c:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0104e90:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104e92:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104e94:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0104e96:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0104e9a:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0104e9c:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0104e9e:	b8 00 d0 11 00       	mov    $0x11d000,%eax
	movl    %eax, %cr3
f0104ea3:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0104ea6:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0104ea9:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0104eae:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0104eb1:	8b 25 84 ae 22 f0    	mov    0xf022ae84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0104eb7:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0104ebc:	b8 a7 01 10 f0       	mov    $0xf01001a7,%eax
	call    *%eax
f0104ec1:	ff d0                	call   *%eax

f0104ec3 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0104ec3:	eb fe                	jmp    f0104ec3 <spin>
f0104ec5:	8d 76 00             	lea    0x0(%esi),%esi

f0104ec8 <gdt>:
	...
f0104ed0:	ff                   	(bad)  
f0104ed1:	ff 00                	incl   (%eax)
f0104ed3:	00 00                	add    %al,(%eax)
f0104ed5:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0104edc:	00                   	.byte 0x0
f0104edd:	92                   	xchg   %eax,%edx
f0104ede:	cf                   	iret   
	...

f0104ee0 <gdtdesc>:
f0104ee0:	17                   	pop    %ss
f0104ee1:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0104ee6 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0104ee6:	90                   	nop

f0104ee7 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0104ee7:	55                   	push   %ebp
f0104ee8:	89 e5                	mov    %esp,%ebp
f0104eea:	57                   	push   %edi
f0104eeb:	56                   	push   %esi
f0104eec:	53                   	push   %ebx
f0104eed:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104ef0:	8b 0d 88 ae 22 f0    	mov    0xf022ae88,%ecx
f0104ef6:	89 c3                	mov    %eax,%ebx
f0104ef8:	c1 eb 0c             	shr    $0xc,%ebx
f0104efb:	39 cb                	cmp    %ecx,%ebx
f0104efd:	72 12                	jb     f0104f11 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104eff:	50                   	push   %eax
f0104f00:	68 44 59 10 f0       	push   $0xf0105944
f0104f05:	6a 57                	push   $0x57
f0104f07:	68 05 74 10 f0       	push   $0xf0107405
f0104f0c:	e8 2f b1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104f11:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0104f17:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104f19:	89 c2                	mov    %eax,%edx
f0104f1b:	c1 ea 0c             	shr    $0xc,%edx
f0104f1e:	39 ca                	cmp    %ecx,%edx
f0104f20:	72 12                	jb     f0104f34 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104f22:	50                   	push   %eax
f0104f23:	68 44 59 10 f0       	push   $0xf0105944
f0104f28:	6a 57                	push   $0x57
f0104f2a:	68 05 74 10 f0       	push   $0xf0107405
f0104f2f:	e8 0c b1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104f34:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0104f3a:	eb 2f                	jmp    f0104f6b <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104f3c:	83 ec 04             	sub    $0x4,%esp
f0104f3f:	6a 04                	push   $0x4
f0104f41:	68 15 74 10 f0       	push   $0xf0107415
f0104f46:	53                   	push   %ebx
f0104f47:	e8 e5 fd ff ff       	call   f0104d31 <memcmp>
f0104f4c:	83 c4 10             	add    $0x10,%esp
f0104f4f:	85 c0                	test   %eax,%eax
f0104f51:	75 15                	jne    f0104f68 <mpsearch1+0x81>
f0104f53:	89 da                	mov    %ebx,%edx
f0104f55:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0104f58:	0f b6 0a             	movzbl (%edx),%ecx
f0104f5b:	01 c8                	add    %ecx,%eax
f0104f5d:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0104f60:	39 d7                	cmp    %edx,%edi
f0104f62:	75 f4                	jne    f0104f58 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104f64:	84 c0                	test   %al,%al
f0104f66:	74 0e                	je     f0104f76 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0104f68:	83 c3 10             	add    $0x10,%ebx
f0104f6b:	39 f3                	cmp    %esi,%ebx
f0104f6d:	72 cd                	jb     f0104f3c <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0104f6f:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f74:	eb 02                	jmp    f0104f78 <mpsearch1+0x91>
f0104f76:	89 d8                	mov    %ebx,%eax
}
f0104f78:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104f7b:	5b                   	pop    %ebx
f0104f7c:	5e                   	pop    %esi
f0104f7d:	5f                   	pop    %edi
f0104f7e:	5d                   	pop    %ebp
f0104f7f:	c3                   	ret    

f0104f80 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0104f80:	55                   	push   %ebp
f0104f81:	89 e5                	mov    %esp,%ebp
f0104f83:	57                   	push   %edi
f0104f84:	56                   	push   %esi
f0104f85:	53                   	push   %ebx
f0104f86:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0104f89:	c7 05 c0 b3 22 f0 20 	movl   $0xf022b020,0xf022b3c0
f0104f90:	b0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104f93:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f0104f9a:	75 16                	jne    f0104fb2 <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104f9c:	68 00 04 00 00       	push   $0x400
f0104fa1:	68 44 59 10 f0       	push   $0xf0105944
f0104fa6:	6a 6f                	push   $0x6f
f0104fa8:	68 05 74 10 f0       	push   $0xf0107405
f0104fad:	e8 8e b0 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0104fb2:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0104fb9:	85 c0                	test   %eax,%eax
f0104fbb:	74 16                	je     f0104fd3 <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f0104fbd:	c1 e0 04             	shl    $0x4,%eax
f0104fc0:	ba 00 04 00 00       	mov    $0x400,%edx
f0104fc5:	e8 1d ff ff ff       	call   f0104ee7 <mpsearch1>
f0104fca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104fcd:	85 c0                	test   %eax,%eax
f0104fcf:	75 3c                	jne    f010500d <mp_init+0x8d>
f0104fd1:	eb 20                	jmp    f0104ff3 <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f0104fd3:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0104fda:	c1 e0 0a             	shl    $0xa,%eax
f0104fdd:	2d 00 04 00 00       	sub    $0x400,%eax
f0104fe2:	ba 00 04 00 00       	mov    $0x400,%edx
f0104fe7:	e8 fb fe ff ff       	call   f0104ee7 <mpsearch1>
f0104fec:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104fef:	85 c0                	test   %eax,%eax
f0104ff1:	75 1a                	jne    f010500d <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0104ff3:	ba 00 00 01 00       	mov    $0x10000,%edx
f0104ff8:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0104ffd:	e8 e5 fe ff ff       	call   f0104ee7 <mpsearch1>
f0105002:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105005:	85 c0                	test   %eax,%eax
f0105007:	0f 84 5d 02 00 00    	je     f010526a <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f010500d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105010:	8b 70 04             	mov    0x4(%eax),%esi
f0105013:	85 f6                	test   %esi,%esi
f0105015:	74 06                	je     f010501d <mp_init+0x9d>
f0105017:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f010501b:	74 15                	je     f0105032 <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f010501d:	83 ec 0c             	sub    $0xc,%esp
f0105020:	68 78 72 10 f0       	push   $0xf0107278
f0105025:	e8 44 e6 ff ff       	call   f010366e <cprintf>
f010502a:	83 c4 10             	add    $0x10,%esp
f010502d:	e9 38 02 00 00       	jmp    f010526a <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105032:	89 f0                	mov    %esi,%eax
f0105034:	c1 e8 0c             	shr    $0xc,%eax
f0105037:	3b 05 88 ae 22 f0    	cmp    0xf022ae88,%eax
f010503d:	72 15                	jb     f0105054 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010503f:	56                   	push   %esi
f0105040:	68 44 59 10 f0       	push   $0xf0105944
f0105045:	68 90 00 00 00       	push   $0x90
f010504a:	68 05 74 10 f0       	push   $0xf0107405
f010504f:	e8 ec af ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105054:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f010505a:	83 ec 04             	sub    $0x4,%esp
f010505d:	6a 04                	push   $0x4
f010505f:	68 1a 74 10 f0       	push   $0xf010741a
f0105064:	53                   	push   %ebx
f0105065:	e8 c7 fc ff ff       	call   f0104d31 <memcmp>
f010506a:	83 c4 10             	add    $0x10,%esp
f010506d:	85 c0                	test   %eax,%eax
f010506f:	74 15                	je     f0105086 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105071:	83 ec 0c             	sub    $0xc,%esp
f0105074:	68 a8 72 10 f0       	push   $0xf01072a8
f0105079:	e8 f0 e5 ff ff       	call   f010366e <cprintf>
f010507e:	83 c4 10             	add    $0x10,%esp
f0105081:	e9 e4 01 00 00       	jmp    f010526a <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105086:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f010508a:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f010508e:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105091:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105096:	b8 00 00 00 00       	mov    $0x0,%eax
f010509b:	eb 0d                	jmp    f01050aa <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f010509d:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f01050a4:	f0 
f01050a5:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01050a7:	83 c0 01             	add    $0x1,%eax
f01050aa:	39 c7                	cmp    %eax,%edi
f01050ac:	75 ef                	jne    f010509d <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01050ae:	84 d2                	test   %dl,%dl
f01050b0:	74 15                	je     f01050c7 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f01050b2:	83 ec 0c             	sub    $0xc,%esp
f01050b5:	68 dc 72 10 f0       	push   $0xf01072dc
f01050ba:	e8 af e5 ff ff       	call   f010366e <cprintf>
f01050bf:	83 c4 10             	add    $0x10,%esp
f01050c2:	e9 a3 01 00 00       	jmp    f010526a <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f01050c7:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f01050cb:	3c 01                	cmp    $0x1,%al
f01050cd:	74 1d                	je     f01050ec <mp_init+0x16c>
f01050cf:	3c 04                	cmp    $0x4,%al
f01050d1:	74 19                	je     f01050ec <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f01050d3:	83 ec 08             	sub    $0x8,%esp
f01050d6:	0f b6 c0             	movzbl %al,%eax
f01050d9:	50                   	push   %eax
f01050da:	68 00 73 10 f0       	push   $0xf0107300
f01050df:	e8 8a e5 ff ff       	call   f010366e <cprintf>
f01050e4:	83 c4 10             	add    $0x10,%esp
f01050e7:	e9 7e 01 00 00       	jmp    f010526a <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01050ec:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f01050f0:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01050f4:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01050f9:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f01050fe:	01 ce                	add    %ecx,%esi
f0105100:	eb 0d                	jmp    f010510f <mp_init+0x18f>
f0105102:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f0105109:	f0 
f010510a:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010510c:	83 c0 01             	add    $0x1,%eax
f010510f:	39 c7                	cmp    %eax,%edi
f0105111:	75 ef                	jne    f0105102 <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105113:	89 d0                	mov    %edx,%eax
f0105115:	02 43 2a             	add    0x2a(%ebx),%al
f0105118:	74 15                	je     f010512f <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f010511a:	83 ec 0c             	sub    $0xc,%esp
f010511d:	68 20 73 10 f0       	push   $0xf0107320
f0105122:	e8 47 e5 ff ff       	call   f010366e <cprintf>
f0105127:	83 c4 10             	add    $0x10,%esp
f010512a:	e9 3b 01 00 00       	jmp    f010526a <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f010512f:	85 db                	test   %ebx,%ebx
f0105131:	0f 84 33 01 00 00    	je     f010526a <mp_init+0x2ea>
		return;
	ismp = 1;
f0105137:	c7 05 00 b0 22 f0 01 	movl   $0x1,0xf022b000
f010513e:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105141:	8b 43 24             	mov    0x24(%ebx),%eax
f0105144:	a3 00 c0 26 f0       	mov    %eax,0xf026c000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105149:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f010514c:	be 00 00 00 00       	mov    $0x0,%esi
f0105151:	e9 85 00 00 00       	jmp    f01051db <mp_init+0x25b>
		switch (*p) {
f0105156:	0f b6 07             	movzbl (%edi),%eax
f0105159:	84 c0                	test   %al,%al
f010515b:	74 06                	je     f0105163 <mp_init+0x1e3>
f010515d:	3c 04                	cmp    $0x4,%al
f010515f:	77 55                	ja     f01051b6 <mp_init+0x236>
f0105161:	eb 4e                	jmp    f01051b1 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105163:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105167:	74 11                	je     f010517a <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f0105169:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f0105170:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f0105175:	a3 c0 b3 22 f0       	mov    %eax,0xf022b3c0
			if (ncpu < NCPU) {
f010517a:	a1 c4 b3 22 f0       	mov    0xf022b3c4,%eax
f010517f:	83 f8 07             	cmp    $0x7,%eax
f0105182:	7f 13                	jg     f0105197 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f0105184:	6b d0 74             	imul   $0x74,%eax,%edx
f0105187:	88 82 20 b0 22 f0    	mov    %al,-0xfdd4fe0(%edx)
				ncpu++;
f010518d:	83 c0 01             	add    $0x1,%eax
f0105190:	a3 c4 b3 22 f0       	mov    %eax,0xf022b3c4
f0105195:	eb 15                	jmp    f01051ac <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105197:	83 ec 08             	sub    $0x8,%esp
f010519a:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f010519e:	50                   	push   %eax
f010519f:	68 50 73 10 f0       	push   $0xf0107350
f01051a4:	e8 c5 e4 ff ff       	call   f010366e <cprintf>
f01051a9:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f01051ac:	83 c7 14             	add    $0x14,%edi
			continue;
f01051af:	eb 27                	jmp    f01051d8 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f01051b1:	83 c7 08             	add    $0x8,%edi
			continue;
f01051b4:	eb 22                	jmp    f01051d8 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f01051b6:	83 ec 08             	sub    $0x8,%esp
f01051b9:	0f b6 c0             	movzbl %al,%eax
f01051bc:	50                   	push   %eax
f01051bd:	68 78 73 10 f0       	push   $0xf0107378
f01051c2:	e8 a7 e4 ff ff       	call   f010366e <cprintf>
			ismp = 0;
f01051c7:	c7 05 00 b0 22 f0 00 	movl   $0x0,0xf022b000
f01051ce:	00 00 00 
			i = conf->entry;
f01051d1:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f01051d5:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01051d8:	83 c6 01             	add    $0x1,%esi
f01051db:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f01051df:	39 c6                	cmp    %eax,%esi
f01051e1:	0f 82 6f ff ff ff    	jb     f0105156 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f01051e7:	a1 c0 b3 22 f0       	mov    0xf022b3c0,%eax
f01051ec:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01051f3:	83 3d 00 b0 22 f0 00 	cmpl   $0x0,0xf022b000
f01051fa:	75 26                	jne    f0105222 <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f01051fc:	c7 05 c4 b3 22 f0 01 	movl   $0x1,0xf022b3c4
f0105203:	00 00 00 
		lapicaddr = 0;
f0105206:	c7 05 00 c0 26 f0 00 	movl   $0x0,0xf026c000
f010520d:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105210:	83 ec 0c             	sub    $0xc,%esp
f0105213:	68 98 73 10 f0       	push   $0xf0107398
f0105218:	e8 51 e4 ff ff       	call   f010366e <cprintf>
		return;
f010521d:	83 c4 10             	add    $0x10,%esp
f0105220:	eb 48                	jmp    f010526a <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105222:	83 ec 04             	sub    $0x4,%esp
f0105225:	ff 35 c4 b3 22 f0    	pushl  0xf022b3c4
f010522b:	0f b6 00             	movzbl (%eax),%eax
f010522e:	50                   	push   %eax
f010522f:	68 1f 74 10 f0       	push   $0xf010741f
f0105234:	e8 35 e4 ff ff       	call   f010366e <cprintf>

	if (mp->imcrp) {
f0105239:	83 c4 10             	add    $0x10,%esp
f010523c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010523f:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105243:	74 25                	je     f010526a <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105245:	83 ec 0c             	sub    $0xc,%esp
f0105248:	68 c4 73 10 f0       	push   $0xf01073c4
f010524d:	e8 1c e4 ff ff       	call   f010366e <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105252:	ba 22 00 00 00       	mov    $0x22,%edx
f0105257:	b8 70 00 00 00       	mov    $0x70,%eax
f010525c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010525d:	ba 23 00 00 00       	mov    $0x23,%edx
f0105262:	ec                   	in     (%dx),%al
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105263:	83 c8 01             	or     $0x1,%eax
f0105266:	ee                   	out    %al,(%dx)
f0105267:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f010526a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010526d:	5b                   	pop    %ebx
f010526e:	5e                   	pop    %esi
f010526f:	5f                   	pop    %edi
f0105270:	5d                   	pop    %ebp
f0105271:	c3                   	ret    

f0105272 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105272:	55                   	push   %ebp
f0105273:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105275:	8b 0d 04 c0 26 f0    	mov    0xf026c004,%ecx
f010527b:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f010527e:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105280:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f0105285:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105288:	5d                   	pop    %ebp
f0105289:	c3                   	ret    

f010528a <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f010528a:	55                   	push   %ebp
f010528b:	89 e5                	mov    %esp,%ebp
	if (lapic)
f010528d:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f0105292:	85 c0                	test   %eax,%eax
f0105294:	74 08                	je     f010529e <cpunum+0x14>
		return lapic[ID] >> 24;
f0105296:	8b 40 20             	mov    0x20(%eax),%eax
f0105299:	c1 e8 18             	shr    $0x18,%eax
f010529c:	eb 05                	jmp    f01052a3 <cpunum+0x19>
	return 0;
f010529e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01052a3:	5d                   	pop    %ebp
f01052a4:	c3                   	ret    

f01052a5 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f01052a5:	a1 00 c0 26 f0       	mov    0xf026c000,%eax
f01052aa:	85 c0                	test   %eax,%eax
f01052ac:	0f 84 21 01 00 00    	je     f01053d3 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f01052b2:	55                   	push   %ebp
f01052b3:	89 e5                	mov    %esp,%ebp
f01052b5:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f01052b8:	68 00 10 00 00       	push   $0x1000
f01052bd:	50                   	push   %eax
f01052be:	e8 f7 be ff ff       	call   f01011ba <mmio_map_region>
f01052c3:	a3 04 c0 26 f0       	mov    %eax,0xf026c004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f01052c8:	ba 27 01 00 00       	mov    $0x127,%edx
f01052cd:	b8 3c 00 00 00       	mov    $0x3c,%eax
f01052d2:	e8 9b ff ff ff       	call   f0105272 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f01052d7:	ba 0b 00 00 00       	mov    $0xb,%edx
f01052dc:	b8 f8 00 00 00       	mov    $0xf8,%eax
f01052e1:	e8 8c ff ff ff       	call   f0105272 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f01052e6:	ba 20 00 02 00       	mov    $0x20020,%edx
f01052eb:	b8 c8 00 00 00       	mov    $0xc8,%eax
f01052f0:	e8 7d ff ff ff       	call   f0105272 <lapicw>
	lapicw(TICR, 10000000); 
f01052f5:	ba 80 96 98 00       	mov    $0x989680,%edx
f01052fa:	b8 e0 00 00 00       	mov    $0xe0,%eax
f01052ff:	e8 6e ff ff ff       	call   f0105272 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105304:	e8 81 ff ff ff       	call   f010528a <cpunum>
f0105309:	6b c0 74             	imul   $0x74,%eax,%eax
f010530c:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f0105311:	83 c4 10             	add    $0x10,%esp
f0105314:	39 05 c0 b3 22 f0    	cmp    %eax,0xf022b3c0
f010531a:	74 0f                	je     f010532b <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f010531c:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105321:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105326:	e8 47 ff ff ff       	call   f0105272 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f010532b:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105330:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105335:	e8 38 ff ff ff       	call   f0105272 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f010533a:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f010533f:	8b 40 30             	mov    0x30(%eax),%eax
f0105342:	c1 e8 10             	shr    $0x10,%eax
f0105345:	3c 03                	cmp    $0x3,%al
f0105347:	76 0f                	jbe    f0105358 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105349:	ba 00 00 01 00       	mov    $0x10000,%edx
f010534e:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105353:	e8 1a ff ff ff       	call   f0105272 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105358:	ba 33 00 00 00       	mov    $0x33,%edx
f010535d:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105362:	e8 0b ff ff ff       	call   f0105272 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105367:	ba 00 00 00 00       	mov    $0x0,%edx
f010536c:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105371:	e8 fc fe ff ff       	call   f0105272 <lapicw>
	lapicw(ESR, 0);
f0105376:	ba 00 00 00 00       	mov    $0x0,%edx
f010537b:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105380:	e8 ed fe ff ff       	call   f0105272 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105385:	ba 00 00 00 00       	mov    $0x0,%edx
f010538a:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010538f:	e8 de fe ff ff       	call   f0105272 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105394:	ba 00 00 00 00       	mov    $0x0,%edx
f0105399:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010539e:	e8 cf fe ff ff       	call   f0105272 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f01053a3:	ba 00 85 08 00       	mov    $0x88500,%edx
f01053a8:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01053ad:	e8 c0 fe ff ff       	call   f0105272 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f01053b2:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f01053b8:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01053be:	f6 c4 10             	test   $0x10,%ah
f01053c1:	75 f5                	jne    f01053b8 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f01053c3:	ba 00 00 00 00       	mov    $0x0,%edx
f01053c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01053cd:	e8 a0 fe ff ff       	call   f0105272 <lapicw>
}
f01053d2:	c9                   	leave  
f01053d3:	f3 c3                	repz ret 

f01053d5 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f01053d5:	83 3d 04 c0 26 f0 00 	cmpl   $0x0,0xf026c004
f01053dc:	74 13                	je     f01053f1 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f01053de:	55                   	push   %ebp
f01053df:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f01053e1:	ba 00 00 00 00       	mov    $0x0,%edx
f01053e6:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01053eb:	e8 82 fe ff ff       	call   f0105272 <lapicw>
}
f01053f0:	5d                   	pop    %ebp
f01053f1:	f3 c3                	repz ret 

f01053f3 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f01053f3:	55                   	push   %ebp
f01053f4:	89 e5                	mov    %esp,%ebp
f01053f6:	56                   	push   %esi
f01053f7:	53                   	push   %ebx
f01053f8:	8b 75 08             	mov    0x8(%ebp),%esi
f01053fb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01053fe:	ba 70 00 00 00       	mov    $0x70,%edx
f0105403:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105408:	ee                   	out    %al,(%dx)
f0105409:	ba 71 00 00 00       	mov    $0x71,%edx
f010540e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105413:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105414:	83 3d 88 ae 22 f0 00 	cmpl   $0x0,0xf022ae88
f010541b:	75 19                	jne    f0105436 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010541d:	68 67 04 00 00       	push   $0x467
f0105422:	68 44 59 10 f0       	push   $0xf0105944
f0105427:	68 98 00 00 00       	push   $0x98
f010542c:	68 3c 74 10 f0       	push   $0xf010743c
f0105431:	e8 0a ac ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105436:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f010543d:	00 00 
	wrv[1] = addr >> 4;
f010543f:	89 d8                	mov    %ebx,%eax
f0105441:	c1 e8 04             	shr    $0x4,%eax
f0105444:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f010544a:	c1 e6 18             	shl    $0x18,%esi
f010544d:	89 f2                	mov    %esi,%edx
f010544f:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105454:	e8 19 fe ff ff       	call   f0105272 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105459:	ba 00 c5 00 00       	mov    $0xc500,%edx
f010545e:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105463:	e8 0a fe ff ff       	call   f0105272 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105468:	ba 00 85 00 00       	mov    $0x8500,%edx
f010546d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105472:	e8 fb fd ff ff       	call   f0105272 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105477:	c1 eb 0c             	shr    $0xc,%ebx
f010547a:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f010547d:	89 f2                	mov    %esi,%edx
f010547f:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105484:	e8 e9 fd ff ff       	call   f0105272 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105489:	89 da                	mov    %ebx,%edx
f010548b:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105490:	e8 dd fd ff ff       	call   f0105272 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105495:	89 f2                	mov    %esi,%edx
f0105497:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010549c:	e8 d1 fd ff ff       	call   f0105272 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01054a1:	89 da                	mov    %ebx,%edx
f01054a3:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01054a8:	e8 c5 fd ff ff       	call   f0105272 <lapicw>
		microdelay(200);
	}
}
f01054ad:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01054b0:	5b                   	pop    %ebx
f01054b1:	5e                   	pop    %esi
f01054b2:	5d                   	pop    %ebp
f01054b3:	c3                   	ret    

f01054b4 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f01054b4:	55                   	push   %ebp
f01054b5:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f01054b7:	8b 55 08             	mov    0x8(%ebp),%edx
f01054ba:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f01054c0:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01054c5:	e8 a8 fd ff ff       	call   f0105272 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f01054ca:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f01054d0:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01054d6:	f6 c4 10             	test   $0x10,%ah
f01054d9:	75 f5                	jne    f01054d0 <lapic_ipi+0x1c>
		;
}
f01054db:	5d                   	pop    %ebp
f01054dc:	c3                   	ret    

f01054dd <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f01054dd:	55                   	push   %ebp
f01054de:	89 e5                	mov    %esp,%ebp
f01054e0:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f01054e3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f01054e9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01054ec:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f01054ef:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f01054f6:	5d                   	pop    %ebp
f01054f7:	c3                   	ret    

f01054f8 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f01054f8:	55                   	push   %ebp
f01054f9:	89 e5                	mov    %esp,%ebp
f01054fb:	56                   	push   %esi
f01054fc:	53                   	push   %ebx
f01054fd:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105500:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105503:	74 14                	je     f0105519 <spin_lock+0x21>
f0105505:	8b 73 08             	mov    0x8(%ebx),%esi
f0105508:	e8 7d fd ff ff       	call   f010528a <cpunum>
f010550d:	6b c0 74             	imul   $0x74,%eax,%eax
f0105510:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105515:	39 c6                	cmp    %eax,%esi
f0105517:	74 07                	je     f0105520 <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0105519:	ba 01 00 00 00       	mov    $0x1,%edx
f010551e:	eb 20                	jmp    f0105540 <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105520:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105523:	e8 62 fd ff ff       	call   f010528a <cpunum>
f0105528:	83 ec 0c             	sub    $0xc,%esp
f010552b:	53                   	push   %ebx
f010552c:	50                   	push   %eax
f010552d:	68 4c 74 10 f0       	push   $0xf010744c
f0105532:	6a 41                	push   $0x41
f0105534:	68 b0 74 10 f0       	push   $0xf01074b0
f0105539:	e8 02 ab ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f010553e:	f3 90                	pause  
f0105540:	89 d0                	mov    %edx,%eax
f0105542:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105545:	85 c0                	test   %eax,%eax
f0105547:	75 f5                	jne    f010553e <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105549:	e8 3c fd ff ff       	call   f010528a <cpunum>
f010554e:	6b c0 74             	imul   $0x74,%eax,%eax
f0105551:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f0105556:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105559:	83 c3 0c             	add    $0xc,%ebx

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010555c:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f010555e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105563:	eb 0b                	jmp    f0105570 <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105565:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105568:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f010556b:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f010556d:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105570:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105576:	76 11                	jbe    f0105589 <spin_lock+0x91>
f0105578:	83 f8 09             	cmp    $0x9,%eax
f010557b:	7e e8                	jle    f0105565 <spin_lock+0x6d>
f010557d:	eb 0a                	jmp    f0105589 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f010557f:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105586:	83 c0 01             	add    $0x1,%eax
f0105589:	83 f8 09             	cmp    $0x9,%eax
f010558c:	7e f1                	jle    f010557f <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f010558e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105591:	5b                   	pop    %ebx
f0105592:	5e                   	pop    %esi
f0105593:	5d                   	pop    %ebp
f0105594:	c3                   	ret    

f0105595 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105595:	55                   	push   %ebp
f0105596:	89 e5                	mov    %esp,%ebp
f0105598:	57                   	push   %edi
f0105599:	56                   	push   %esi
f010559a:	53                   	push   %ebx
f010559b:	83 ec 4c             	sub    $0x4c,%esp
f010559e:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f01055a1:	83 3e 00             	cmpl   $0x0,(%esi)
f01055a4:	74 18                	je     f01055be <spin_unlock+0x29>
f01055a6:	8b 5e 08             	mov    0x8(%esi),%ebx
f01055a9:	e8 dc fc ff ff       	call   f010528a <cpunum>
f01055ae:	6b c0 74             	imul   $0x74,%eax,%eax
f01055b1:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f01055b6:	39 c3                	cmp    %eax,%ebx
f01055b8:	0f 84 a5 00 00 00    	je     f0105663 <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f01055be:	83 ec 04             	sub    $0x4,%esp
f01055c1:	6a 28                	push   $0x28
f01055c3:	8d 46 0c             	lea    0xc(%esi),%eax
f01055c6:	50                   	push   %eax
f01055c7:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f01055ca:	53                   	push   %ebx
f01055cb:	e8 e6 f6 ff ff       	call   f0104cb6 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f01055d0:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f01055d3:	0f b6 38             	movzbl (%eax),%edi
f01055d6:	8b 76 04             	mov    0x4(%esi),%esi
f01055d9:	e8 ac fc ff ff       	call   f010528a <cpunum>
f01055de:	57                   	push   %edi
f01055df:	56                   	push   %esi
f01055e0:	50                   	push   %eax
f01055e1:	68 78 74 10 f0       	push   $0xf0107478
f01055e6:	e8 83 e0 ff ff       	call   f010366e <cprintf>
f01055eb:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f01055ee:	8d 7d a8             	lea    -0x58(%ebp),%edi
f01055f1:	eb 54                	jmp    f0105647 <spin_unlock+0xb2>
f01055f3:	83 ec 08             	sub    $0x8,%esp
f01055f6:	57                   	push   %edi
f01055f7:	50                   	push   %eax
f01055f8:	e8 37 ec ff ff       	call   f0104234 <debuginfo_eip>
f01055fd:	83 c4 10             	add    $0x10,%esp
f0105600:	85 c0                	test   %eax,%eax
f0105602:	78 27                	js     f010562b <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105604:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105606:	83 ec 04             	sub    $0x4,%esp
f0105609:	89 c2                	mov    %eax,%edx
f010560b:	2b 55 b8             	sub    -0x48(%ebp),%edx
f010560e:	52                   	push   %edx
f010560f:	ff 75 b0             	pushl  -0x50(%ebp)
f0105612:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105615:	ff 75 ac             	pushl  -0x54(%ebp)
f0105618:	ff 75 a8             	pushl  -0x58(%ebp)
f010561b:	50                   	push   %eax
f010561c:	68 c0 74 10 f0       	push   $0xf01074c0
f0105621:	e8 48 e0 ff ff       	call   f010366e <cprintf>
f0105626:	83 c4 20             	add    $0x20,%esp
f0105629:	eb 12                	jmp    f010563d <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f010562b:	83 ec 08             	sub    $0x8,%esp
f010562e:	ff 36                	pushl  (%esi)
f0105630:	68 d7 74 10 f0       	push   $0xf01074d7
f0105635:	e8 34 e0 ff ff       	call   f010366e <cprintf>
f010563a:	83 c4 10             	add    $0x10,%esp
f010563d:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105640:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105643:	39 c3                	cmp    %eax,%ebx
f0105645:	74 08                	je     f010564f <spin_unlock+0xba>
f0105647:	89 de                	mov    %ebx,%esi
f0105649:	8b 03                	mov    (%ebx),%eax
f010564b:	85 c0                	test   %eax,%eax
f010564d:	75 a4                	jne    f01055f3 <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f010564f:	83 ec 04             	sub    $0x4,%esp
f0105652:	68 df 74 10 f0       	push   $0xf01074df
f0105657:	6a 67                	push   $0x67
f0105659:	68 b0 74 10 f0       	push   $0xf01074b0
f010565e:	e8 dd a9 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105663:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f010566a:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0105671:	b8 00 00 00 00       	mov    $0x0,%eax
f0105676:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0105679:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010567c:	5b                   	pop    %ebx
f010567d:	5e                   	pop    %esi
f010567e:	5f                   	pop    %edi
f010567f:	5d                   	pop    %ebp
f0105680:	c3                   	ret    
f0105681:	66 90                	xchg   %ax,%ax
f0105683:	66 90                	xchg   %ax,%ax
f0105685:	66 90                	xchg   %ax,%ax
f0105687:	66 90                	xchg   %ax,%ax
f0105689:	66 90                	xchg   %ax,%ax
f010568b:	66 90                	xchg   %ax,%ax
f010568d:	66 90                	xchg   %ax,%ax
f010568f:	90                   	nop

f0105690 <__udivdi3>:
f0105690:	55                   	push   %ebp
f0105691:	57                   	push   %edi
f0105692:	56                   	push   %esi
f0105693:	53                   	push   %ebx
f0105694:	83 ec 1c             	sub    $0x1c,%esp
f0105697:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010569b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010569f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01056a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01056a7:	85 f6                	test   %esi,%esi
f01056a9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01056ad:	89 ca                	mov    %ecx,%edx
f01056af:	89 f8                	mov    %edi,%eax
f01056b1:	75 3d                	jne    f01056f0 <__udivdi3+0x60>
f01056b3:	39 cf                	cmp    %ecx,%edi
f01056b5:	0f 87 c5 00 00 00    	ja     f0105780 <__udivdi3+0xf0>
f01056bb:	85 ff                	test   %edi,%edi
f01056bd:	89 fd                	mov    %edi,%ebp
f01056bf:	75 0b                	jne    f01056cc <__udivdi3+0x3c>
f01056c1:	b8 01 00 00 00       	mov    $0x1,%eax
f01056c6:	31 d2                	xor    %edx,%edx
f01056c8:	f7 f7                	div    %edi
f01056ca:	89 c5                	mov    %eax,%ebp
f01056cc:	89 c8                	mov    %ecx,%eax
f01056ce:	31 d2                	xor    %edx,%edx
f01056d0:	f7 f5                	div    %ebp
f01056d2:	89 c1                	mov    %eax,%ecx
f01056d4:	89 d8                	mov    %ebx,%eax
f01056d6:	89 cf                	mov    %ecx,%edi
f01056d8:	f7 f5                	div    %ebp
f01056da:	89 c3                	mov    %eax,%ebx
f01056dc:	89 d8                	mov    %ebx,%eax
f01056de:	89 fa                	mov    %edi,%edx
f01056e0:	83 c4 1c             	add    $0x1c,%esp
f01056e3:	5b                   	pop    %ebx
f01056e4:	5e                   	pop    %esi
f01056e5:	5f                   	pop    %edi
f01056e6:	5d                   	pop    %ebp
f01056e7:	c3                   	ret    
f01056e8:	90                   	nop
f01056e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01056f0:	39 ce                	cmp    %ecx,%esi
f01056f2:	77 74                	ja     f0105768 <__udivdi3+0xd8>
f01056f4:	0f bd fe             	bsr    %esi,%edi
f01056f7:	83 f7 1f             	xor    $0x1f,%edi
f01056fa:	0f 84 98 00 00 00    	je     f0105798 <__udivdi3+0x108>
f0105700:	bb 20 00 00 00       	mov    $0x20,%ebx
f0105705:	89 f9                	mov    %edi,%ecx
f0105707:	89 c5                	mov    %eax,%ebp
f0105709:	29 fb                	sub    %edi,%ebx
f010570b:	d3 e6                	shl    %cl,%esi
f010570d:	89 d9                	mov    %ebx,%ecx
f010570f:	d3 ed                	shr    %cl,%ebp
f0105711:	89 f9                	mov    %edi,%ecx
f0105713:	d3 e0                	shl    %cl,%eax
f0105715:	09 ee                	or     %ebp,%esi
f0105717:	89 d9                	mov    %ebx,%ecx
f0105719:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010571d:	89 d5                	mov    %edx,%ebp
f010571f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105723:	d3 ed                	shr    %cl,%ebp
f0105725:	89 f9                	mov    %edi,%ecx
f0105727:	d3 e2                	shl    %cl,%edx
f0105729:	89 d9                	mov    %ebx,%ecx
f010572b:	d3 e8                	shr    %cl,%eax
f010572d:	09 c2                	or     %eax,%edx
f010572f:	89 d0                	mov    %edx,%eax
f0105731:	89 ea                	mov    %ebp,%edx
f0105733:	f7 f6                	div    %esi
f0105735:	89 d5                	mov    %edx,%ebp
f0105737:	89 c3                	mov    %eax,%ebx
f0105739:	f7 64 24 0c          	mull   0xc(%esp)
f010573d:	39 d5                	cmp    %edx,%ebp
f010573f:	72 10                	jb     f0105751 <__udivdi3+0xc1>
f0105741:	8b 74 24 08          	mov    0x8(%esp),%esi
f0105745:	89 f9                	mov    %edi,%ecx
f0105747:	d3 e6                	shl    %cl,%esi
f0105749:	39 c6                	cmp    %eax,%esi
f010574b:	73 07                	jae    f0105754 <__udivdi3+0xc4>
f010574d:	39 d5                	cmp    %edx,%ebp
f010574f:	75 03                	jne    f0105754 <__udivdi3+0xc4>
f0105751:	83 eb 01             	sub    $0x1,%ebx
f0105754:	31 ff                	xor    %edi,%edi
f0105756:	89 d8                	mov    %ebx,%eax
f0105758:	89 fa                	mov    %edi,%edx
f010575a:	83 c4 1c             	add    $0x1c,%esp
f010575d:	5b                   	pop    %ebx
f010575e:	5e                   	pop    %esi
f010575f:	5f                   	pop    %edi
f0105760:	5d                   	pop    %ebp
f0105761:	c3                   	ret    
f0105762:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105768:	31 ff                	xor    %edi,%edi
f010576a:	31 db                	xor    %ebx,%ebx
f010576c:	89 d8                	mov    %ebx,%eax
f010576e:	89 fa                	mov    %edi,%edx
f0105770:	83 c4 1c             	add    $0x1c,%esp
f0105773:	5b                   	pop    %ebx
f0105774:	5e                   	pop    %esi
f0105775:	5f                   	pop    %edi
f0105776:	5d                   	pop    %ebp
f0105777:	c3                   	ret    
f0105778:	90                   	nop
f0105779:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105780:	89 d8                	mov    %ebx,%eax
f0105782:	f7 f7                	div    %edi
f0105784:	31 ff                	xor    %edi,%edi
f0105786:	89 c3                	mov    %eax,%ebx
f0105788:	89 d8                	mov    %ebx,%eax
f010578a:	89 fa                	mov    %edi,%edx
f010578c:	83 c4 1c             	add    $0x1c,%esp
f010578f:	5b                   	pop    %ebx
f0105790:	5e                   	pop    %esi
f0105791:	5f                   	pop    %edi
f0105792:	5d                   	pop    %ebp
f0105793:	c3                   	ret    
f0105794:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105798:	39 ce                	cmp    %ecx,%esi
f010579a:	72 0c                	jb     f01057a8 <__udivdi3+0x118>
f010579c:	31 db                	xor    %ebx,%ebx
f010579e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01057a2:	0f 87 34 ff ff ff    	ja     f01056dc <__udivdi3+0x4c>
f01057a8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01057ad:	e9 2a ff ff ff       	jmp    f01056dc <__udivdi3+0x4c>
f01057b2:	66 90                	xchg   %ax,%ax
f01057b4:	66 90                	xchg   %ax,%ax
f01057b6:	66 90                	xchg   %ax,%ax
f01057b8:	66 90                	xchg   %ax,%ax
f01057ba:	66 90                	xchg   %ax,%ax
f01057bc:	66 90                	xchg   %ax,%ax
f01057be:	66 90                	xchg   %ax,%ax

f01057c0 <__umoddi3>:
f01057c0:	55                   	push   %ebp
f01057c1:	57                   	push   %edi
f01057c2:	56                   	push   %esi
f01057c3:	53                   	push   %ebx
f01057c4:	83 ec 1c             	sub    $0x1c,%esp
f01057c7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01057cb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01057cf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01057d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01057d7:	85 d2                	test   %edx,%edx
f01057d9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01057dd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01057e1:	89 f3                	mov    %esi,%ebx
f01057e3:	89 3c 24             	mov    %edi,(%esp)
f01057e6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01057ea:	75 1c                	jne    f0105808 <__umoddi3+0x48>
f01057ec:	39 f7                	cmp    %esi,%edi
f01057ee:	76 50                	jbe    f0105840 <__umoddi3+0x80>
f01057f0:	89 c8                	mov    %ecx,%eax
f01057f2:	89 f2                	mov    %esi,%edx
f01057f4:	f7 f7                	div    %edi
f01057f6:	89 d0                	mov    %edx,%eax
f01057f8:	31 d2                	xor    %edx,%edx
f01057fa:	83 c4 1c             	add    $0x1c,%esp
f01057fd:	5b                   	pop    %ebx
f01057fe:	5e                   	pop    %esi
f01057ff:	5f                   	pop    %edi
f0105800:	5d                   	pop    %ebp
f0105801:	c3                   	ret    
f0105802:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105808:	39 f2                	cmp    %esi,%edx
f010580a:	89 d0                	mov    %edx,%eax
f010580c:	77 52                	ja     f0105860 <__umoddi3+0xa0>
f010580e:	0f bd ea             	bsr    %edx,%ebp
f0105811:	83 f5 1f             	xor    $0x1f,%ebp
f0105814:	75 5a                	jne    f0105870 <__umoddi3+0xb0>
f0105816:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010581a:	0f 82 e0 00 00 00    	jb     f0105900 <__umoddi3+0x140>
f0105820:	39 0c 24             	cmp    %ecx,(%esp)
f0105823:	0f 86 d7 00 00 00    	jbe    f0105900 <__umoddi3+0x140>
f0105829:	8b 44 24 08          	mov    0x8(%esp),%eax
f010582d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105831:	83 c4 1c             	add    $0x1c,%esp
f0105834:	5b                   	pop    %ebx
f0105835:	5e                   	pop    %esi
f0105836:	5f                   	pop    %edi
f0105837:	5d                   	pop    %ebp
f0105838:	c3                   	ret    
f0105839:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105840:	85 ff                	test   %edi,%edi
f0105842:	89 fd                	mov    %edi,%ebp
f0105844:	75 0b                	jne    f0105851 <__umoddi3+0x91>
f0105846:	b8 01 00 00 00       	mov    $0x1,%eax
f010584b:	31 d2                	xor    %edx,%edx
f010584d:	f7 f7                	div    %edi
f010584f:	89 c5                	mov    %eax,%ebp
f0105851:	89 f0                	mov    %esi,%eax
f0105853:	31 d2                	xor    %edx,%edx
f0105855:	f7 f5                	div    %ebp
f0105857:	89 c8                	mov    %ecx,%eax
f0105859:	f7 f5                	div    %ebp
f010585b:	89 d0                	mov    %edx,%eax
f010585d:	eb 99                	jmp    f01057f8 <__umoddi3+0x38>
f010585f:	90                   	nop
f0105860:	89 c8                	mov    %ecx,%eax
f0105862:	89 f2                	mov    %esi,%edx
f0105864:	83 c4 1c             	add    $0x1c,%esp
f0105867:	5b                   	pop    %ebx
f0105868:	5e                   	pop    %esi
f0105869:	5f                   	pop    %edi
f010586a:	5d                   	pop    %ebp
f010586b:	c3                   	ret    
f010586c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105870:	8b 34 24             	mov    (%esp),%esi
f0105873:	bf 20 00 00 00       	mov    $0x20,%edi
f0105878:	89 e9                	mov    %ebp,%ecx
f010587a:	29 ef                	sub    %ebp,%edi
f010587c:	d3 e0                	shl    %cl,%eax
f010587e:	89 f9                	mov    %edi,%ecx
f0105880:	89 f2                	mov    %esi,%edx
f0105882:	d3 ea                	shr    %cl,%edx
f0105884:	89 e9                	mov    %ebp,%ecx
f0105886:	09 c2                	or     %eax,%edx
f0105888:	89 d8                	mov    %ebx,%eax
f010588a:	89 14 24             	mov    %edx,(%esp)
f010588d:	89 f2                	mov    %esi,%edx
f010588f:	d3 e2                	shl    %cl,%edx
f0105891:	89 f9                	mov    %edi,%ecx
f0105893:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105897:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010589b:	d3 e8                	shr    %cl,%eax
f010589d:	89 e9                	mov    %ebp,%ecx
f010589f:	89 c6                	mov    %eax,%esi
f01058a1:	d3 e3                	shl    %cl,%ebx
f01058a3:	89 f9                	mov    %edi,%ecx
f01058a5:	89 d0                	mov    %edx,%eax
f01058a7:	d3 e8                	shr    %cl,%eax
f01058a9:	89 e9                	mov    %ebp,%ecx
f01058ab:	09 d8                	or     %ebx,%eax
f01058ad:	89 d3                	mov    %edx,%ebx
f01058af:	89 f2                	mov    %esi,%edx
f01058b1:	f7 34 24             	divl   (%esp)
f01058b4:	89 d6                	mov    %edx,%esi
f01058b6:	d3 e3                	shl    %cl,%ebx
f01058b8:	f7 64 24 04          	mull   0x4(%esp)
f01058bc:	39 d6                	cmp    %edx,%esi
f01058be:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01058c2:	89 d1                	mov    %edx,%ecx
f01058c4:	89 c3                	mov    %eax,%ebx
f01058c6:	72 08                	jb     f01058d0 <__umoddi3+0x110>
f01058c8:	75 11                	jne    f01058db <__umoddi3+0x11b>
f01058ca:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01058ce:	73 0b                	jae    f01058db <__umoddi3+0x11b>
f01058d0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01058d4:	1b 14 24             	sbb    (%esp),%edx
f01058d7:	89 d1                	mov    %edx,%ecx
f01058d9:	89 c3                	mov    %eax,%ebx
f01058db:	8b 54 24 08          	mov    0x8(%esp),%edx
f01058df:	29 da                	sub    %ebx,%edx
f01058e1:	19 ce                	sbb    %ecx,%esi
f01058e3:	89 f9                	mov    %edi,%ecx
f01058e5:	89 f0                	mov    %esi,%eax
f01058e7:	d3 e0                	shl    %cl,%eax
f01058e9:	89 e9                	mov    %ebp,%ecx
f01058eb:	d3 ea                	shr    %cl,%edx
f01058ed:	89 e9                	mov    %ebp,%ecx
f01058ef:	d3 ee                	shr    %cl,%esi
f01058f1:	09 d0                	or     %edx,%eax
f01058f3:	89 f2                	mov    %esi,%edx
f01058f5:	83 c4 1c             	add    $0x1c,%esp
f01058f8:	5b                   	pop    %ebx
f01058f9:	5e                   	pop    %esi
f01058fa:	5f                   	pop    %edi
f01058fb:	5d                   	pop    %ebp
f01058fc:	c3                   	ret    
f01058fd:	8d 76 00             	lea    0x0(%esi),%esi
f0105900:	29 f9                	sub    %edi,%ecx
f0105902:	19 d6                	sbb    %edx,%esi
f0105904:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105908:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010590c:	e9 18 ff ff ff       	jmp    f0105829 <__umoddi3+0x69>

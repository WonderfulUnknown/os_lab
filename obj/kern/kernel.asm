
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
f0100048:	83 3d 00 af 22 f0 00 	cmpl   $0x0,0xf022af00
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 00 af 22 f0    	mov    %esi,0xf022af00

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 85 52 00 00       	call   f01052e6 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 80 59 10 f0       	push   $0xf0105980
f010006d:	e8 d6 36 00 00       	call   f0103748 <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 a6 36 00 00       	call   f0103722 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 09 5d 10 f0 	movl   $0xf0105d09,(%esp)
f0100083:	e8 c0 36 00 00       	call   f0103748 <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 87 08 00 00       	call   f010091c <monitor>
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
f01000b3:	e8 0b 4c 00 00       	call   f0104cc3 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 8f 05 00 00       	call   f010064c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 ec 59 10 f0       	push   $0xf01059ec
f01000ca:	e8 79 36 00 00       	call   f0103748 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 38 12 00 00       	call   f010130c <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 8c 2e 00 00       	call   f0102f65 <env_init>
	trap_init();
f01000d9:	e8 db 36 00 00       	call   f01037b9 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 f9 4e 00 00       	call   f0104fdc <mp_init>
	lapic_init();
f01000e3:	e8 19 52 00 00       	call   f0105301 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 82 35 00 00       	call   f010366f <pic_init>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000ed:	83 c4 10             	add    $0x10,%esp
f01000f0:	83 3d 08 af 22 f0 07 	cmpl   $0x7,0xf022af08
f01000f7:	77 16                	ja     f010010f <i386_init+0x75>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01000f9:	68 00 70 00 00       	push   $0x7000
f01000fe:	68 a4 59 10 f0       	push   $0xf01059a4
f0100103:	6a 53                	push   $0x53
f0100105:	68 07 5a 10 f0       	push   $0xf0105a07
f010010a:	e8 31 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010010f:	83 ec 04             	sub    $0x4,%esp
f0100112:	b8 42 4f 10 f0       	mov    $0xf0104f42,%eax
f0100117:	2d c8 4e 10 f0       	sub    $0xf0104ec8,%eax
f010011c:	50                   	push   %eax
f010011d:	68 c8 4e 10 f0       	push   $0xf0104ec8
f0100122:	68 00 70 00 f0       	push   $0xf0007000
f0100127:	e8 e4 4b 00 00       	call   f0104d10 <memmove>
f010012c:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010012f:	bb 20 b0 22 f0       	mov    $0xf022b020,%ebx
f0100134:	eb 4d                	jmp    f0100183 <i386_init+0xe9>
		if (c == cpus + cpunum())  // We've started already.
f0100136:	e8 ab 51 00 00       	call   f01052e6 <cpunum>
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
f010015f:	a3 04 af 22 f0       	mov    %eax,0xf022af04
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100164:	83 ec 08             	sub    $0x8,%esp
f0100167:	68 00 70 00 00       	push   $0x7000
f010016c:	0f b6 03             	movzbl (%ebx),%eax
f010016f:	50                   	push   %eax
f0100170:	e8 da 52 00 00       	call   f010544f <lapic_startap>
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
f010019d:	e8 8b 2f 00 00       	call   f010312d <env_create>
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001a2:	e8 cf 3e 00 00       	call   f0104076 <sched_yield>

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
f01001ad:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001b2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001b7:	77 12                	ja     f01001cb <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001b9:	50                   	push   %eax
f01001ba:	68 c8 59 10 f0       	push   $0xf01059c8
f01001bf:	6a 6a                	push   $0x6a
f01001c1:	68 07 5a 10 f0       	push   $0xf0105a07
f01001c6:	e8 75 fe ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01001cb:	05 00 00 00 10       	add    $0x10000000,%eax
f01001d0:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001d3:	e8 0e 51 00 00       	call   f01052e6 <cpunum>
f01001d8:	83 ec 08             	sub    $0x8,%esp
f01001db:	50                   	push   %eax
f01001dc:	68 13 5a 10 f0       	push   $0xf0105a13
f01001e1:	e8 62 35 00 00       	call   f0103748 <cprintf>

	lapic_init();
f01001e6:	e8 16 51 00 00       	call   f0105301 <lapic_init>
	env_init_percpu();
f01001eb:	e8 45 2d 00 00       	call   f0102f35 <env_init_percpu>
	trap_init_percpu();
f01001f0:	e8 67 35 00 00       	call   f010375c <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f01001f5:	e8 ec 50 00 00       	call   f01052e6 <cpunum>
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
f0100221:	68 29 5a 10 f0       	push   $0xf0105a29
f0100226:	e8 1d 35 00 00       	call   f0103748 <cprintf>
	vcprintf(fmt, ap);
f010022b:	83 c4 08             	add    $0x8,%esp
f010022e:	53                   	push   %ebx
f010022f:	ff 75 10             	pushl  0x10(%ebp)
f0100232:	e8 eb 34 00 00       	call   f0103722 <vcprintf>
	cprintf("\n");
f0100237:	c7 04 24 09 5d 10 f0 	movl   $0xf0105d09,(%esp)
f010023e:	e8 05 35 00 00       	call   f0103748 <cprintf>
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
f01002f5:	0f b6 82 a0 5b 10 f0 	movzbl -0xfefa460(%edx),%eax
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
f0100331:	0f b6 82 a0 5b 10 f0 	movzbl -0xfefa460(%edx),%eax
f0100338:	0b 05 00 a0 22 f0    	or     0xf022a000,%eax
f010033e:	0f b6 8a a0 5a 10 f0 	movzbl -0xfefa560(%edx),%ecx
f0100345:	31 c8                	xor    %ecx,%eax
f0100347:	a3 00 a0 22 f0       	mov    %eax,0xf022a000

	c = charcode[shift & (CTL | SHIFT)][data];
f010034c:	89 c1                	mov    %eax,%ecx
f010034e:	83 e1 03             	and    $0x3,%ecx
f0100351:	8b 0c 8d 80 5a 10 f0 	mov    -0xfefa580(,%ecx,4),%ecx
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
f010038f:	68 43 5a 10 f0       	push   $0xf0105a43
f0100394:	e8 af 33 00 00       	call   f0103748 <cprintf>
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
cga_putc(int c)
{
	// if no attribute given, then use black on white
	//if (!(c & ~0xFF))
	//	c |= 0x0700;
	if (!(c & ~0xFF)){
f010043b:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100441:	75 3d                	jne    f0100480 <cons_putc+0xc8>
    	  char ch = c & 0xFF;
    	    if (ch > 47 && ch < 58) {
f0100443:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100447:	83 e8 30             	sub    $0x30,%eax
f010044a:	3c 09                	cmp    $0x9,%al
f010044c:	77 08                	ja     f0100456 <cons_putc+0x9e>
              c |= 0x0100;
f010044e:	81 cf 00 01 00 00    	or     $0x100,%edi
f0100454:	eb 2a                	jmp    f0100480 <cons_putc+0xc8>
    	    }
	    else if (ch > 64 && ch < 91) {
f0100456:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010045a:	83 e8 41             	sub    $0x41,%eax
f010045d:	3c 19                	cmp    $0x19,%al
f010045f:	77 08                	ja     f0100469 <cons_putc+0xb1>
              c |= 0x0200;
f0100461:	81 cf 00 02 00 00    	or     $0x200,%edi
f0100467:	eb 17                	jmp    f0100480 <cons_putc+0xc8>
    	    }
	    else if (ch > 96 && ch < 123) {
f0100469:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010046d:	83 e8 61             	sub    $0x61,%eax
              c |= 0x0300;
f0100470:	89 fa                	mov    %edi,%edx
f0100472:	80 ce 03             	or     $0x3,%dh
f0100475:	81 cf 00 04 00 00    	or     $0x400,%edi
f010047b:	3c 19                	cmp    $0x19,%al
f010047d:	0f 46 fa             	cmovbe %edx,%edi
    	    }
	    else {
              c |= 0x0400;
    	    }
	}
	switch (c & 0xff) {
f0100480:	89 f8                	mov    %edi,%eax
f0100482:	0f b6 c0             	movzbl %al,%eax
f0100485:	83 f8 09             	cmp    $0x9,%eax
f0100488:	74 74                	je     f01004fe <cons_putc+0x146>
f010048a:	83 f8 09             	cmp    $0x9,%eax
f010048d:	7f 0a                	jg     f0100499 <cons_putc+0xe1>
f010048f:	83 f8 08             	cmp    $0x8,%eax
f0100492:	74 14                	je     f01004a8 <cons_putc+0xf0>
f0100494:	e9 99 00 00 00       	jmp    f0100532 <cons_putc+0x17a>
f0100499:	83 f8 0a             	cmp    $0xa,%eax
f010049c:	74 3a                	je     f01004d8 <cons_putc+0x120>
f010049e:	83 f8 0d             	cmp    $0xd,%eax
f01004a1:	74 3d                	je     f01004e0 <cons_putc+0x128>
f01004a3:	e9 8a 00 00 00       	jmp    f0100532 <cons_putc+0x17a>
	case '\b':
		if (crt_pos > 0) {
f01004a8:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f01004af:	66 85 c0             	test   %ax,%ax
f01004b2:	0f 84 e6 00 00 00    	je     f010059e <cons_putc+0x1e6>
			crt_pos--;
f01004b8:	83 e8 01             	sub    $0x1,%eax
f01004bb:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004c1:	0f b7 c0             	movzwl %ax,%eax
f01004c4:	66 81 e7 00 ff       	and    $0xff00,%di
f01004c9:	83 cf 20             	or     $0x20,%edi
f01004cc:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f01004d2:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004d6:	eb 78                	jmp    f0100550 <cons_putc+0x198>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004d8:	66 83 05 28 a2 22 f0 	addw   $0x50,0xf022a228
f01004df:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004e0:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f01004e7:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004ed:	c1 e8 16             	shr    $0x16,%eax
f01004f0:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004f3:	c1 e0 04             	shl    $0x4,%eax
f01004f6:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228
f01004fc:	eb 52                	jmp    f0100550 <cons_putc+0x198>
		break;
	case '\t':
		cons_putc(' ');
f01004fe:	b8 20 00 00 00       	mov    $0x20,%eax
f0100503:	e8 b0 fe ff ff       	call   f01003b8 <cons_putc>
		cons_putc(' ');
f0100508:	b8 20 00 00 00       	mov    $0x20,%eax
f010050d:	e8 a6 fe ff ff       	call   f01003b8 <cons_putc>
		cons_putc(' ');
f0100512:	b8 20 00 00 00       	mov    $0x20,%eax
f0100517:	e8 9c fe ff ff       	call   f01003b8 <cons_putc>
		cons_putc(' ');
f010051c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100521:	e8 92 fe ff ff       	call   f01003b8 <cons_putc>
		cons_putc(' ');
f0100526:	b8 20 00 00 00       	mov    $0x20,%eax
f010052b:	e8 88 fe ff ff       	call   f01003b8 <cons_putc>
f0100530:	eb 1e                	jmp    f0100550 <cons_putc+0x198>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100532:	0f b7 05 28 a2 22 f0 	movzwl 0xf022a228,%eax
f0100539:	8d 50 01             	lea    0x1(%eax),%edx
f010053c:	66 89 15 28 a2 22 f0 	mov    %dx,0xf022a228
f0100543:	0f b7 c0             	movzwl %ax,%eax
f0100546:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f010054c:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100550:	66 81 3d 28 a2 22 f0 	cmpw   $0x7cf,0xf022a228
f0100557:	cf 07 
f0100559:	76 43                	jbe    f010059e <cons_putc+0x1e6>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010055b:	a1 2c a2 22 f0       	mov    0xf022a22c,%eax
f0100560:	83 ec 04             	sub    $0x4,%esp
f0100563:	68 00 0f 00 00       	push   $0xf00
f0100568:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010056e:	52                   	push   %edx
f010056f:	50                   	push   %eax
f0100570:	e8 9b 47 00 00       	call   f0104d10 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100575:	8b 15 2c a2 22 f0    	mov    0xf022a22c,%edx
f010057b:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100581:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100587:	83 c4 10             	add    $0x10,%esp
f010058a:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010058f:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100592:	39 d0                	cmp    %edx,%eax
f0100594:	75 f4                	jne    f010058a <cons_putc+0x1d2>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100596:	66 83 2d 28 a2 22 f0 	subw   $0x50,0xf022a228
f010059d:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010059e:	8b 0d 30 a2 22 f0    	mov    0xf022a230,%ecx
f01005a4:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005a9:	89 ca                	mov    %ecx,%edx
f01005ab:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005ac:	0f b7 1d 28 a2 22 f0 	movzwl 0xf022a228,%ebx
f01005b3:	8d 71 01             	lea    0x1(%ecx),%esi
f01005b6:	89 d8                	mov    %ebx,%eax
f01005b8:	66 c1 e8 08          	shr    $0x8,%ax
f01005bc:	89 f2                	mov    %esi,%edx
f01005be:	ee                   	out    %al,(%dx)
f01005bf:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005c4:	89 ca                	mov    %ecx,%edx
f01005c6:	ee                   	out    %al,(%dx)
f01005c7:	89 d8                	mov    %ebx,%eax
f01005c9:	89 f2                	mov    %esi,%edx
f01005cb:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005cc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005cf:	5b                   	pop    %ebx
f01005d0:	5e                   	pop    %esi
f01005d1:	5f                   	pop    %edi
f01005d2:	5d                   	pop    %ebp
f01005d3:	c3                   	ret    

f01005d4 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005d4:	80 3d 34 a2 22 f0 00 	cmpb   $0x0,0xf022a234
f01005db:	74 11                	je     f01005ee <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005dd:	55                   	push   %ebp
f01005de:	89 e5                	mov    %esp,%ebp
f01005e0:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005e3:	b8 4b 02 10 f0       	mov    $0xf010024b,%eax
f01005e8:	e8 7d fc ff ff       	call   f010026a <cons_intr>
}
f01005ed:	c9                   	leave  
f01005ee:	f3 c3                	repz ret 

f01005f0 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005f0:	55                   	push   %ebp
f01005f1:	89 e5                	mov    %esp,%ebp
f01005f3:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005f6:	b8 ad 02 10 f0       	mov    $0xf01002ad,%eax
f01005fb:	e8 6a fc ff ff       	call   f010026a <cons_intr>
}
f0100600:	c9                   	leave  
f0100601:	c3                   	ret    

f0100602 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100602:	55                   	push   %ebp
f0100603:	89 e5                	mov    %esp,%ebp
f0100605:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100608:	e8 c7 ff ff ff       	call   f01005d4 <serial_intr>
	kbd_intr();
f010060d:	e8 de ff ff ff       	call   f01005f0 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100612:	a1 20 a2 22 f0       	mov    0xf022a220,%eax
f0100617:	3b 05 24 a2 22 f0    	cmp    0xf022a224,%eax
f010061d:	74 26                	je     f0100645 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f010061f:	8d 50 01             	lea    0x1(%eax),%edx
f0100622:	89 15 20 a2 22 f0    	mov    %edx,0xf022a220
f0100628:	0f b6 88 20 a0 22 f0 	movzbl -0xfdd5fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010062f:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100631:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100637:	75 11                	jne    f010064a <cons_getc+0x48>
			cons.rpos = 0;
f0100639:	c7 05 20 a2 22 f0 00 	movl   $0x0,0xf022a220
f0100640:	00 00 00 
f0100643:	eb 05                	jmp    f010064a <cons_getc+0x48>
		return c;
	}
	return 0;
f0100645:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010064a:	c9                   	leave  
f010064b:	c3                   	ret    

f010064c <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010064c:	55                   	push   %ebp
f010064d:	89 e5                	mov    %esp,%ebp
f010064f:	57                   	push   %edi
f0100650:	56                   	push   %esi
f0100651:	53                   	push   %ebx
f0100652:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100655:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010065c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100663:	5a a5 
	if (*cp != 0xA55A) {
f0100665:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010066c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100670:	74 11                	je     f0100683 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100672:	c7 05 30 a2 22 f0 b4 	movl   $0x3b4,0xf022a230
f0100679:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010067c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100681:	eb 16                	jmp    f0100699 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100683:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010068a:	c7 05 30 a2 22 f0 d4 	movl   $0x3d4,0xf022a230
f0100691:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100694:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100699:	8b 3d 30 a2 22 f0    	mov    0xf022a230,%edi
f010069f:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006a4:	89 fa                	mov    %edi,%edx
f01006a6:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006a7:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006aa:	89 da                	mov    %ebx,%edx
f01006ac:	ec                   	in     (%dx),%al
f01006ad:	0f b6 c8             	movzbl %al,%ecx
f01006b0:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006b3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006b8:	89 fa                	mov    %edi,%edx
f01006ba:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006bb:	89 da                	mov    %ebx,%edx
f01006bd:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006be:	89 35 2c a2 22 f0    	mov    %esi,0xf022a22c
	crt_pos = pos;
f01006c4:	0f b6 c0             	movzbl %al,%eax
f01006c7:	09 c8                	or     %ecx,%eax
f01006c9:	66 a3 28 a2 22 f0    	mov    %ax,0xf022a228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006cf:	e8 1c ff ff ff       	call   f01005f0 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f01006d4:	83 ec 0c             	sub    $0xc,%esp
f01006d7:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f01006de:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006e3:	50                   	push   %eax
f01006e4:	e8 0e 2f 00 00       	call   f01035f7 <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006e9:	be fa 03 00 00       	mov    $0x3fa,%esi
f01006ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f3:	89 f2                	mov    %esi,%edx
f01006f5:	ee                   	out    %al,(%dx)
f01006f6:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01006fb:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100700:	ee                   	out    %al,(%dx)
f0100701:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100706:	b8 0c 00 00 00       	mov    $0xc,%eax
f010070b:	89 da                	mov    %ebx,%edx
f010070d:	ee                   	out    %al,(%dx)
f010070e:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100713:	b8 00 00 00 00       	mov    $0x0,%eax
f0100718:	ee                   	out    %al,(%dx)
f0100719:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010071e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100723:	ee                   	out    %al,(%dx)
f0100724:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100729:	b8 00 00 00 00       	mov    $0x0,%eax
f010072e:	ee                   	out    %al,(%dx)
f010072f:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100734:	b8 01 00 00 00       	mov    $0x1,%eax
f0100739:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010073a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010073f:	ec                   	in     (%dx),%al
f0100740:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100742:	83 c4 10             	add    $0x10,%esp
f0100745:	3c ff                	cmp    $0xff,%al
f0100747:	0f 95 05 34 a2 22 f0 	setne  0xf022a234
f010074e:	89 f2                	mov    %esi,%edx
f0100750:	ec                   	in     (%dx),%al
f0100751:	89 da                	mov    %ebx,%edx
f0100753:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100754:	80 f9 ff             	cmp    $0xff,%cl
f0100757:	75 10                	jne    f0100769 <cons_init+0x11d>
		cprintf("Serial port does not exist!\n");
f0100759:	83 ec 0c             	sub    $0xc,%esp
f010075c:	68 4f 5a 10 f0       	push   $0xf0105a4f
f0100761:	e8 e2 2f 00 00       	call   f0103748 <cprintf>
f0100766:	83 c4 10             	add    $0x10,%esp
}
f0100769:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010076c:	5b                   	pop    %ebx
f010076d:	5e                   	pop    %esi
f010076e:	5f                   	pop    %edi
f010076f:	5d                   	pop    %ebp
f0100770:	c3                   	ret    

f0100771 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100771:	55                   	push   %ebp
f0100772:	89 e5                	mov    %esp,%ebp
f0100774:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100777:	8b 45 08             	mov    0x8(%ebp),%eax
f010077a:	e8 39 fc ff ff       	call   f01003b8 <cons_putc>
}
f010077f:	c9                   	leave  
f0100780:	c3                   	ret    

f0100781 <getchar>:

int
getchar(void)
{
f0100781:	55                   	push   %ebp
f0100782:	89 e5                	mov    %esp,%ebp
f0100784:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100787:	e8 76 fe ff ff       	call   f0100602 <cons_getc>
f010078c:	85 c0                	test   %eax,%eax
f010078e:	74 f7                	je     f0100787 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100790:	c9                   	leave  
f0100791:	c3                   	ret    

f0100792 <iscons>:

int
iscons(int fdnum)
{
f0100792:	55                   	push   %ebp
f0100793:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100795:	b8 01 00 00 00       	mov    $0x1,%eax
f010079a:	5d                   	pop    %ebp
f010079b:	c3                   	ret    

f010079c <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010079c:	55                   	push   %ebp
f010079d:	89 e5                	mov    %esp,%ebp
f010079f:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007a2:	68 a0 5c 10 f0       	push   $0xf0105ca0
f01007a7:	68 be 5c 10 f0       	push   $0xf0105cbe
f01007ac:	68 c3 5c 10 f0       	push   $0xf0105cc3
f01007b1:	e8 92 2f 00 00       	call   f0103748 <cprintf>
f01007b6:	83 c4 0c             	add    $0xc,%esp
f01007b9:	68 58 5d 10 f0       	push   $0xf0105d58
f01007be:	68 cc 5c 10 f0       	push   $0xf0105ccc
f01007c3:	68 c3 5c 10 f0       	push   $0xf0105cc3
f01007c8:	e8 7b 2f 00 00       	call   f0103748 <cprintf>
f01007cd:	83 c4 0c             	add    $0xc,%esp
f01007d0:	68 80 5d 10 f0       	push   $0xf0105d80
f01007d5:	68 d5 5c 10 f0       	push   $0xf0105cd5
f01007da:	68 c3 5c 10 f0       	push   $0xf0105cc3
f01007df:	e8 64 2f 00 00       	call   f0103748 <cprintf>
	return 0;
}
f01007e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007e9:	c9                   	leave  
f01007ea:	c3                   	ret    

f01007eb <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007eb:	55                   	push   %ebp
f01007ec:	89 e5                	mov    %esp,%ebp
f01007ee:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007f1:	68 df 5c 10 f0       	push   $0xf0105cdf
f01007f6:	e8 4d 2f 00 00       	call   f0103748 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007fb:	83 c4 08             	add    $0x8,%esp
f01007fe:	68 0c 00 10 00       	push   $0x10000c
f0100803:	68 a8 5d 10 f0       	push   $0xf0105da8
f0100808:	e8 3b 2f 00 00       	call   f0103748 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010080d:	83 c4 0c             	add    $0xc,%esp
f0100810:	68 0c 00 10 00       	push   $0x10000c
f0100815:	68 0c 00 10 f0       	push   $0xf010000c
f010081a:	68 d0 5d 10 f0       	push   $0xf0105dd0
f010081f:	e8 24 2f 00 00       	call   f0103748 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100824:	83 c4 0c             	add    $0xc,%esp
f0100827:	68 61 59 10 00       	push   $0x105961
f010082c:	68 61 59 10 f0       	push   $0xf0105961
f0100831:	68 f4 5d 10 f0       	push   $0xf0105df4
f0100836:	e8 0d 2f 00 00       	call   f0103748 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010083b:	83 c4 0c             	add    $0xc,%esp
f010083e:	68 98 95 22 00       	push   $0x229598
f0100843:	68 98 95 22 f0       	push   $0xf0229598
f0100848:	68 18 5e 10 f0       	push   $0xf0105e18
f010084d:	e8 f6 2e 00 00       	call   f0103748 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100852:	83 c4 0c             	add    $0xc,%esp
f0100855:	68 08 c0 26 00       	push   $0x26c008
f010085a:	68 08 c0 26 f0       	push   $0xf026c008
f010085f:	68 3c 5e 10 f0       	push   $0xf0105e3c
f0100864:	e8 df 2e 00 00       	call   f0103748 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100869:	b8 07 c4 26 f0       	mov    $0xf026c407,%eax
f010086e:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100873:	83 c4 08             	add    $0x8,%esp
f0100876:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010087b:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100881:	85 c0                	test   %eax,%eax
f0100883:	0f 48 c2             	cmovs  %edx,%eax
f0100886:	c1 f8 0a             	sar    $0xa,%eax
f0100889:	50                   	push   %eax
f010088a:	68 60 5e 10 f0       	push   $0xf0105e60
f010088f:	e8 b4 2e 00 00       	call   f0103748 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100894:	b8 00 00 00 00       	mov    $0x0,%eax
f0100899:	c9                   	leave  
f010089a:	c3                   	ret    

f010089b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010089b:	55                   	push   %ebp
f010089c:	89 e5                	mov    %esp,%ebp
f010089e:	57                   	push   %edi
f010089f:	56                   	push   %esi
f01008a0:	53                   	push   %ebx
f01008a1:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01008a4:	89 eb                	mov    %ebp,%ebx
	struct Eipdebuginfo info;        
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();
	
	cprintf("Stack backtrace:\r\n");
f01008a6:	68 f8 5c 10 f0       	push   $0xf0105cf8
f01008ab:	e8 98 2e 00 00       	call   f0103748 <cprintf>
    	while (ebp!=0)
f01008b0:	83 c4 10             	add    $0x10,%esp
    	{
	eip = ebp[1];
       	cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);//%08x 补0输出8位16进制数
	debuginfo_eip((uintptr_t)eip,&info);
f01008b3:	8d 7d d0             	lea    -0x30(%ebp),%edi
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();
	
	cprintf("Stack backtrace:\r\n");
    	while (ebp!=0)
f01008b6:	eb 53                	jmp    f010090b <mon_backtrace+0x70>
    	{
	eip = ebp[1];
f01008b8:	8b 73 04             	mov    0x4(%ebx),%esi
       	cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);//%08x 补0输出8位16进制数
f01008bb:	ff 73 18             	pushl  0x18(%ebx)
f01008be:	ff 73 14             	pushl  0x14(%ebx)
f01008c1:	ff 73 10             	pushl  0x10(%ebx)
f01008c4:	ff 73 0c             	pushl  0xc(%ebx)
f01008c7:	ff 73 08             	pushl  0x8(%ebx)
f01008ca:	56                   	push   %esi
f01008cb:	53                   	push   %ebx
f01008cc:	68 8c 5e 10 f0       	push   $0xf0105e8c
f01008d1:	e8 72 2e 00 00       	call   f0103748 <cprintf>
	debuginfo_eip((uintptr_t)eip,&info);
f01008d6:	83 c4 18             	add    $0x18,%esp
f01008d9:	57                   	push   %edi
f01008da:	56                   	push   %esi
f01008db:	e8 ae 39 00 00       	call   f010428e <debuginfo_eip>
	cprintf("%s:%d", info.eip_file, info.eip_line);
f01008e0:	83 c4 0c             	add    $0xc,%esp
f01008e3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008e6:	ff 75 d0             	pushl  -0x30(%ebp)
f01008e9:	68 0b 5d 10 f0       	push   $0xf0105d0b
f01008ee:	e8 55 2e 00 00       	call   f0103748 <cprintf>
        cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name,info.eip_fn_addr);
f01008f3:	ff 75 e0             	pushl  -0x20(%ebp)
f01008f6:	ff 75 d8             	pushl  -0x28(%ebp)
f01008f9:	ff 75 dc             	pushl  -0x24(%ebp)
f01008fc:	68 11 5d 10 f0       	push   $0xf0105d11
f0100901:	e8 42 2e 00 00       	call   f0103748 <cprintf>
   	ebp = (uint32_t *)ebp[0];
f0100906:	8b 1b                	mov    (%ebx),%ebx
f0100908:	83 c4 20             	add    $0x20,%esp
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();
	
	cprintf("Stack backtrace:\r\n");
    	while (ebp!=0)
f010090b:	85 db                	test   %ebx,%ebx
f010090d:	75 a9                	jne    f01008b8 <mon_backtrace+0x1d>
	cprintf("%s:%d", info.eip_file, info.eip_line);
        cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name,info.eip_fn_addr);
   	ebp = (uint32_t *)ebp[0];
    	}
    	return 0;
}
f010090f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100914:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100917:	5b                   	pop    %ebx
f0100918:	5e                   	pop    %esi
f0100919:	5f                   	pop    %edi
f010091a:	5d                   	pop    %ebp
f010091b:	c3                   	ret    

f010091c <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010091c:	55                   	push   %ebp
f010091d:	89 e5                	mov    %esp,%ebp
f010091f:	57                   	push   %edi
f0100920:	56                   	push   %esi
f0100921:	53                   	push   %ebx
f0100922:	83 ec 58             	sub    $0x58,%esp
	char *buf; 
	cprintf("Welcome to the JOS kernel monitor!\n");
f0100925:	68 c4 5e 10 f0       	push   $0xf0105ec4
f010092a:	e8 19 2e 00 00       	call   f0103748 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010092f:	c7 04 24 e8 5e 10 f0 	movl   $0xf0105ee8,(%esp)
f0100936:	e8 0d 2e 00 00       	call   f0103748 <cprintf>

	if (tf != NULL)
f010093b:	83 c4 10             	add    $0x10,%esp
f010093e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100942:	74 0e                	je     f0100952 <monitor+0x36>
		print_trapframe(tf);
f0100944:	83 ec 0c             	sub    $0xc,%esp
f0100947:	ff 75 08             	pushl  0x8(%ebp)
f010094a:	e8 b2 31 00 00       	call   f0103b01 <print_trapframe>
f010094f:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100952:	83 ec 0c             	sub    $0xc,%esp
f0100955:	68 1c 5d 10 f0       	push   $0xf0105d1c
f010095a:	e8 0d 41 00 00       	call   f0104a6c <readline>
f010095f:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100961:	83 c4 10             	add    $0x10,%esp
f0100964:	85 c0                	test   %eax,%eax
f0100966:	74 ea                	je     f0100952 <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100968:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010096f:	be 00 00 00 00       	mov    $0x0,%esi
f0100974:	eb 0a                	jmp    f0100980 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100976:	c6 03 00             	movb   $0x0,(%ebx)
f0100979:	89 f7                	mov    %esi,%edi
f010097b:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010097e:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100980:	0f b6 03             	movzbl (%ebx),%eax
f0100983:	84 c0                	test   %al,%al
f0100985:	74 63                	je     f01009ea <monitor+0xce>
f0100987:	83 ec 08             	sub    $0x8,%esp
f010098a:	0f be c0             	movsbl %al,%eax
f010098d:	50                   	push   %eax
f010098e:	68 20 5d 10 f0       	push   $0xf0105d20
f0100993:	e8 ee 42 00 00       	call   f0104c86 <strchr>
f0100998:	83 c4 10             	add    $0x10,%esp
f010099b:	85 c0                	test   %eax,%eax
f010099d:	75 d7                	jne    f0100976 <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f010099f:	80 3b 00             	cmpb   $0x0,(%ebx)
f01009a2:	74 46                	je     f01009ea <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01009a4:	83 fe 0f             	cmp    $0xf,%esi
f01009a7:	75 14                	jne    f01009bd <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009a9:	83 ec 08             	sub    $0x8,%esp
f01009ac:	6a 10                	push   $0x10
f01009ae:	68 25 5d 10 f0       	push   $0xf0105d25
f01009b3:	e8 90 2d 00 00       	call   f0103748 <cprintf>
f01009b8:	83 c4 10             	add    $0x10,%esp
f01009bb:	eb 95                	jmp    f0100952 <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01009bd:	8d 7e 01             	lea    0x1(%esi),%edi
f01009c0:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009c4:	eb 03                	jmp    f01009c9 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01009c6:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009c9:	0f b6 03             	movzbl (%ebx),%eax
f01009cc:	84 c0                	test   %al,%al
f01009ce:	74 ae                	je     f010097e <monitor+0x62>
f01009d0:	83 ec 08             	sub    $0x8,%esp
f01009d3:	0f be c0             	movsbl %al,%eax
f01009d6:	50                   	push   %eax
f01009d7:	68 20 5d 10 f0       	push   $0xf0105d20
f01009dc:	e8 a5 42 00 00       	call   f0104c86 <strchr>
f01009e1:	83 c4 10             	add    $0x10,%esp
f01009e4:	85 c0                	test   %eax,%eax
f01009e6:	74 de                	je     f01009c6 <monitor+0xaa>
f01009e8:	eb 94                	jmp    f010097e <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01009ea:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009f1:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009f2:	85 f6                	test   %esi,%esi
f01009f4:	0f 84 58 ff ff ff    	je     f0100952 <monitor+0x36>
f01009fa:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009ff:	83 ec 08             	sub    $0x8,%esp
f0100a02:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a05:	ff 34 85 20 5f 10 f0 	pushl  -0xfefa0e0(,%eax,4)
f0100a0c:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a0f:	e8 14 42 00 00       	call   f0104c28 <strcmp>
f0100a14:	83 c4 10             	add    $0x10,%esp
f0100a17:	85 c0                	test   %eax,%eax
f0100a19:	75 21                	jne    f0100a3c <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f0100a1b:	83 ec 04             	sub    $0x4,%esp
f0100a1e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a21:	ff 75 08             	pushl  0x8(%ebp)
f0100a24:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a27:	52                   	push   %edx
f0100a28:	56                   	push   %esi
f0100a29:	ff 14 85 28 5f 10 f0 	call   *-0xfefa0d8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a30:	83 c4 10             	add    $0x10,%esp
f0100a33:	85 c0                	test   %eax,%eax
f0100a35:	78 25                	js     f0100a5c <monitor+0x140>
f0100a37:	e9 16 ff ff ff       	jmp    f0100952 <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100a3c:	83 c3 01             	add    $0x1,%ebx
f0100a3f:	83 fb 03             	cmp    $0x3,%ebx
f0100a42:	75 bb                	jne    f01009ff <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a44:	83 ec 08             	sub    $0x8,%esp
f0100a47:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a4a:	68 42 5d 10 f0       	push   $0xf0105d42
f0100a4f:	e8 f4 2c 00 00       	call   f0103748 <cprintf>
f0100a54:	83 c4 10             	add    $0x10,%esp
f0100a57:	e9 f6 fe ff ff       	jmp    f0100952 <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a5c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a5f:	5b                   	pop    %ebx
f0100a60:	5e                   	pop    %esi
f0100a61:	5f                   	pop    %edi
f0100a62:	5d                   	pop    %ebp
f0100a63:	c3                   	ret    

f0100a64 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a64:	55                   	push   %ebp
f0100a65:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a67:	83 3d 3c a2 22 f0 00 	cmpl   $0x0,0xf022a23c
f0100a6e:	75 11                	jne    f0100a81 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a70:	ba 07 d0 26 f0       	mov    $0xf026d007,%edx
f0100a75:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a7b:	89 15 3c a2 22 f0    	mov    %edx,0xf022a23c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100a81:	8b 0d 3c a2 22 f0    	mov    0xf022a23c,%ecx
	nextfree += n;
	nextfree = ROUNDUP( (char*)nextfree, PGSIZE);
f0100a87:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100a8e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a94:	89 15 3c a2 22 f0    	mov    %edx,0xf022a23c
	//nextfree += ROUNDUP(n,PGSIZE);
	return result;
}
f0100a9a:	89 c8                	mov    %ecx,%eax
f0100a9c:	5d                   	pop    %ebp
f0100a9d:	c3                   	ret    

f0100a9e <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.
int num = 0;
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a9e:	55                   	push   %ebp
f0100a9f:	89 e5                	mov    %esp,%ebp
f0100aa1:	56                   	push   %esi
f0100aa2:	53                   	push   %ebx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100aa3:	89 d1                	mov    %edx,%ecx
f0100aa5:	c1 e9 16             	shr    $0x16,%ecx
f0100aa8:	8d 0c 88             	lea    (%eax,%ecx,4),%ecx
	
	if (!(*pgdir & PTE_P))
f0100aab:	8b 01                	mov    (%ecx),%eax
f0100aad:	a8 01                	test   $0x1,%al
f0100aaf:	75 2c                	jne    f0100add <check_va2pa+0x3f>
	{

		cprintf("va %x ,pgdir %x ,times %d, return %d, 1\n", va, pgdir, ++num, ~0);
f0100ab1:	a1 38 a2 22 f0       	mov    0xf022a238,%eax
f0100ab6:	83 c0 01             	add    $0x1,%eax
f0100ab9:	a3 38 a2 22 f0       	mov    %eax,0xf022a238
f0100abe:	83 ec 0c             	sub    $0xc,%esp
f0100ac1:	6a ff                	push   $0xffffffff
f0100ac3:	50                   	push   %eax
f0100ac4:	51                   	push   %ecx
f0100ac5:	52                   	push   %edx
f0100ac6:	68 44 5f 10 f0       	push   $0xf0105f44
f0100acb:	e8 78 2c 00 00       	call   f0103748 <cprintf>
		return ~0;
f0100ad0:	83 c4 20             	add    $0x20,%esp
f0100ad3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ad8:	e9 97 00 00 00       	jmp    f0100b74 <check_va2pa+0xd6>
	}
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100add:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ae2:	89 c3                	mov    %eax,%ebx
f0100ae4:	c1 eb 0c             	shr    $0xc,%ebx
f0100ae7:	3b 1d 08 af 22 f0    	cmp    0xf022af08,%ebx
f0100aed:	72 15                	jb     f0100b04 <check_va2pa+0x66>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100aef:	50                   	push   %eax
f0100af0:	68 a4 59 10 f0       	push   $0xf01059a4
f0100af5:	68 e0 03 00 00       	push   $0x3e0
f0100afa:	68 f5 68 10 f0       	push   $0xf01068f5
f0100aff:	e8 3c f5 ff ff       	call   f0100040 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100b04:	89 d3                	mov    %edx,%ebx
f0100b06:	c1 eb 0a             	shr    $0xa,%ebx
f0100b09:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100b0f:	8d 9c 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%ebx
f0100b16:	8b 03                	mov    (%ebx),%eax
f0100b18:	a8 01                	test   $0x1,%al
f0100b1a:	75 29                	jne    f0100b45 <check_va2pa+0xa7>
	{
		cprintf("va %x ,pgdir %x ,times %d, return %d, 2\n", va, pgdir, ++num, ~0);
f0100b1c:	a1 38 a2 22 f0       	mov    0xf022a238,%eax
f0100b21:	83 c0 01             	add    $0x1,%eax
f0100b24:	a3 38 a2 22 f0       	mov    %eax,0xf022a238
f0100b29:	83 ec 0c             	sub    $0xc,%esp
f0100b2c:	6a ff                	push   $0xffffffff
f0100b2e:	50                   	push   %eax
f0100b2f:	51                   	push   %ecx
f0100b30:	52                   	push   %edx
f0100b31:	68 70 5f 10 f0       	push   $0xf0105f70
f0100b36:	e8 0d 2c 00 00       	call   f0103748 <cprintf>
		return ~0;
f0100b3b:	83 c4 20             	add    $0x20,%esp
f0100b3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b43:	eb 2f                	jmp    f0100b74 <check_va2pa+0xd6>
	}
	cprintf("va %x ,pgdir %x ,times %d, return %x \n", va, pgdir, ++num, PTE_ADDR(p[PTX(va)]));
f0100b45:	8b 35 38 a2 22 f0    	mov    0xf022a238,%esi
f0100b4b:	83 c6 01             	add    $0x1,%esi
f0100b4e:	89 35 38 a2 22 f0    	mov    %esi,0xf022a238
f0100b54:	83 ec 0c             	sub    $0xc,%esp
f0100b57:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b5c:	50                   	push   %eax
f0100b5d:	56                   	push   %esi
f0100b5e:	51                   	push   %ecx
f0100b5f:	52                   	push   %edx
f0100b60:	68 9c 5f 10 f0       	push   $0xf0105f9c
f0100b65:	e8 de 2b 00 00       	call   f0103748 <cprintf>
	return PTE_ADDR(p[PTX(va)]);
f0100b6a:	8b 03                	mov    (%ebx),%eax
f0100b6c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b71:	83 c4 20             	add    $0x20,%esp
}
f0100b74:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100b77:	5b                   	pop    %ebx
f0100b78:	5e                   	pop    %esi
f0100b79:	5d                   	pop    %ebp
f0100b7a:	c3                   	ret    

f0100b7b <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100b7b:	55                   	push   %ebp
f0100b7c:	89 e5                	mov    %esp,%ebp
f0100b7e:	57                   	push   %edi
f0100b7f:	56                   	push   %esi
f0100b80:	53                   	push   %ebx
f0100b81:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b84:	84 c0                	test   %al,%al
f0100b86:	0f 85 91 02 00 00    	jne    f0100e1d <check_page_free_list+0x2a2>
f0100b8c:	e9 9e 02 00 00       	jmp    f0100e2f <check_page_free_list+0x2b4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100b91:	83 ec 04             	sub    $0x4,%esp
f0100b94:	68 c4 5f 10 f0       	push   $0xf0105fc4
f0100b99:	68 10 03 00 00       	push   $0x310
f0100b9e:	68 f5 68 10 f0       	push   $0xf01068f5
f0100ba3:	e8 98 f4 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100ba8:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100bab:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100bae:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bb1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100bb4:	89 c2                	mov    %eax,%edx
f0100bb6:	2b 15 10 af 22 f0    	sub    0xf022af10,%edx
f0100bbc:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100bc2:	0f 95 c2             	setne  %dl
f0100bc5:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100bc8:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100bcc:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100bce:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bd2:	8b 00                	mov    (%eax),%eax
f0100bd4:	85 c0                	test   %eax,%eax
f0100bd6:	75 dc                	jne    f0100bb4 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100bd8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bdb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100be1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100be4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100be7:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100be9:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100bec:	a3 44 a2 22 f0       	mov    %eax,0xf022a244
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bf1:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bf6:	8b 1d 44 a2 22 f0    	mov    0xf022a244,%ebx
f0100bfc:	eb 53                	jmp    f0100c51 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bfe:	89 d8                	mov    %ebx,%eax
f0100c00:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f0100c06:	c1 f8 03             	sar    $0x3,%eax
f0100c09:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c0c:	89 c2                	mov    %eax,%edx
f0100c0e:	c1 ea 16             	shr    $0x16,%edx
f0100c11:	39 f2                	cmp    %esi,%edx
f0100c13:	73 3a                	jae    f0100c4f <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c15:	89 c2                	mov    %eax,%edx
f0100c17:	c1 ea 0c             	shr    $0xc,%edx
f0100c1a:	3b 15 08 af 22 f0    	cmp    0xf022af08,%edx
f0100c20:	72 12                	jb     f0100c34 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c22:	50                   	push   %eax
f0100c23:	68 a4 59 10 f0       	push   $0xf01059a4
f0100c28:	6a 58                	push   $0x58
f0100c2a:	68 01 69 10 f0       	push   $0xf0106901
f0100c2f:	e8 0c f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100c34:	83 ec 04             	sub    $0x4,%esp
f0100c37:	68 80 00 00 00       	push   $0x80
f0100c3c:	68 97 00 00 00       	push   $0x97
f0100c41:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c46:	50                   	push   %eax
f0100c47:	e8 77 40 00 00       	call   f0104cc3 <memset>
f0100c4c:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c4f:	8b 1b                	mov    (%ebx),%ebx
f0100c51:	85 db                	test   %ebx,%ebx
f0100c53:	75 a9                	jne    f0100bfe <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100c55:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c5a:	e8 05 fe ff ff       	call   f0100a64 <boot_alloc>
f0100c5f:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c62:	8b 15 44 a2 22 f0    	mov    0xf022a244,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c68:	8b 0d 10 af 22 f0    	mov    0xf022af10,%ecx
		assert(pp < pages + npages);
f0100c6e:	a1 08 af 22 f0       	mov    0xf022af08,%eax
f0100c73:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100c76:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100c79:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c7c:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c7f:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c84:	e9 52 01 00 00       	jmp    f0100ddb <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c89:	39 ca                	cmp    %ecx,%edx
f0100c8b:	73 19                	jae    f0100ca6 <check_page_free_list+0x12b>
f0100c8d:	68 0f 69 10 f0       	push   $0xf010690f
f0100c92:	68 1b 69 10 f0       	push   $0xf010691b
f0100c97:	68 2a 03 00 00       	push   $0x32a
f0100c9c:	68 f5 68 10 f0       	push   $0xf01068f5
f0100ca1:	e8 9a f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100ca6:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100ca9:	72 19                	jb     f0100cc4 <check_page_free_list+0x149>
f0100cab:	68 30 69 10 f0       	push   $0xf0106930
f0100cb0:	68 1b 69 10 f0       	push   $0xf010691b
f0100cb5:	68 2b 03 00 00       	push   $0x32b
f0100cba:	68 f5 68 10 f0       	push   $0xf01068f5
f0100cbf:	e8 7c f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cc4:	89 d0                	mov    %edx,%eax
f0100cc6:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100cc9:	a8 07                	test   $0x7,%al
f0100ccb:	74 19                	je     f0100ce6 <check_page_free_list+0x16b>
f0100ccd:	68 e8 5f 10 f0       	push   $0xf0105fe8
f0100cd2:	68 1b 69 10 f0       	push   $0xf010691b
f0100cd7:	68 2c 03 00 00       	push   $0x32c
f0100cdc:	68 f5 68 10 f0       	push   $0xf01068f5
f0100ce1:	e8 5a f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ce6:	c1 f8 03             	sar    $0x3,%eax
f0100ce9:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100cec:	85 c0                	test   %eax,%eax
f0100cee:	75 19                	jne    f0100d09 <check_page_free_list+0x18e>
f0100cf0:	68 44 69 10 f0       	push   $0xf0106944
f0100cf5:	68 1b 69 10 f0       	push   $0xf010691b
f0100cfa:	68 2f 03 00 00       	push   $0x32f
f0100cff:	68 f5 68 10 f0       	push   $0xf01068f5
f0100d04:	e8 37 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d09:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100d0e:	75 19                	jne    f0100d29 <check_page_free_list+0x1ae>
f0100d10:	68 55 69 10 f0       	push   $0xf0106955
f0100d15:	68 1b 69 10 f0       	push   $0xf010691b
f0100d1a:	68 30 03 00 00       	push   $0x330
f0100d1f:	68 f5 68 10 f0       	push   $0xf01068f5
f0100d24:	e8 17 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d29:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100d2e:	75 19                	jne    f0100d49 <check_page_free_list+0x1ce>
f0100d30:	68 1c 60 10 f0       	push   $0xf010601c
f0100d35:	68 1b 69 10 f0       	push   $0xf010691b
f0100d3a:	68 31 03 00 00       	push   $0x331
f0100d3f:	68 f5 68 10 f0       	push   $0xf01068f5
f0100d44:	e8 f7 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d49:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d4e:	75 19                	jne    f0100d69 <check_page_free_list+0x1ee>
f0100d50:	68 6e 69 10 f0       	push   $0xf010696e
f0100d55:	68 1b 69 10 f0       	push   $0xf010691b
f0100d5a:	68 32 03 00 00       	push   $0x332
f0100d5f:	68 f5 68 10 f0       	push   $0xf01068f5
f0100d64:	e8 d7 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d69:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d6e:	0f 86 de 00 00 00    	jbe    f0100e52 <check_page_free_list+0x2d7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d74:	89 c7                	mov    %eax,%edi
f0100d76:	c1 ef 0c             	shr    $0xc,%edi
f0100d79:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100d7c:	77 12                	ja     f0100d90 <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d7e:	50                   	push   %eax
f0100d7f:	68 a4 59 10 f0       	push   $0xf01059a4
f0100d84:	6a 58                	push   $0x58
f0100d86:	68 01 69 10 f0       	push   $0xf0106901
f0100d8b:	e8 b0 f2 ff ff       	call   f0100040 <_panic>
f0100d90:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100d96:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100d99:	0f 86 a7 00 00 00    	jbe    f0100e46 <check_page_free_list+0x2cb>
f0100d9f:	68 40 60 10 f0       	push   $0xf0106040
f0100da4:	68 1b 69 10 f0       	push   $0xf010691b
f0100da9:	68 33 03 00 00       	push   $0x333
f0100dae:	68 f5 68 10 f0       	push   $0xf01068f5
f0100db3:	e8 88 f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100db8:	68 88 69 10 f0       	push   $0xf0106988
f0100dbd:	68 1b 69 10 f0       	push   $0xf010691b
f0100dc2:	68 35 03 00 00       	push   $0x335
f0100dc7:	68 f5 68 10 f0       	push   $0xf01068f5
f0100dcc:	e8 6f f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100dd1:	83 c6 01             	add    $0x1,%esi
f0100dd4:	eb 03                	jmp    f0100dd9 <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100dd6:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dd9:	8b 12                	mov    (%edx),%edx
f0100ddb:	85 d2                	test   %edx,%edx
f0100ddd:	0f 85 a6 fe ff ff    	jne    f0100c89 <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100de3:	85 f6                	test   %esi,%esi
f0100de5:	7f 19                	jg     f0100e00 <check_page_free_list+0x285>
f0100de7:	68 a5 69 10 f0       	push   $0xf01069a5
f0100dec:	68 1b 69 10 f0       	push   $0xf010691b
f0100df1:	68 3d 03 00 00       	push   $0x33d
f0100df6:	68 f5 68 10 f0       	push   $0xf01068f5
f0100dfb:	e8 40 f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100e00:	85 db                	test   %ebx,%ebx
f0100e02:	7f 5e                	jg     f0100e62 <check_page_free_list+0x2e7>
f0100e04:	68 b7 69 10 f0       	push   $0xf01069b7
f0100e09:	68 1b 69 10 f0       	push   $0xf010691b
f0100e0e:	68 3e 03 00 00       	push   $0x33e
f0100e13:	68 f5 68 10 f0       	push   $0xf01068f5
f0100e18:	e8 23 f2 ff ff       	call   f0100040 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100e1d:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
f0100e22:	85 c0                	test   %eax,%eax
f0100e24:	0f 85 7e fd ff ff    	jne    f0100ba8 <check_page_free_list+0x2d>
f0100e2a:	e9 62 fd ff ff       	jmp    f0100b91 <check_page_free_list+0x16>
f0100e2f:	83 3d 44 a2 22 f0 00 	cmpl   $0x0,0xf022a244
f0100e36:	0f 84 55 fd ff ff    	je     f0100b91 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e3c:	be 00 04 00 00       	mov    $0x400,%esi
f0100e41:	e9 b0 fd ff ff       	jmp    f0100bf6 <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100e46:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e4b:	75 89                	jne    f0100dd6 <check_page_free_list+0x25b>
f0100e4d:	e9 66 ff ff ff       	jmp    f0100db8 <check_page_free_list+0x23d>
f0100e52:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e57:	0f 85 74 ff ff ff    	jne    f0100dd1 <check_page_free_list+0x256>
f0100e5d:	e9 56 ff ff ff       	jmp    f0100db8 <check_page_free_list+0x23d>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100e62:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e65:	5b                   	pop    %ebx
f0100e66:	5e                   	pop    %esi
f0100e67:	5f                   	pop    %edi
f0100e68:	5d                   	pop    %ebp
f0100e69:	c3                   	ret    

f0100e6a <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100e6a:	55                   	push   %ebp
f0100e6b:	89 e5                	mov    %esp,%ebp
f0100e6d:	56                   	push   %esi
f0100e6e:	53                   	push   %ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!

	//  1) Mark physical page 0 as in use.
	pages[0].pp_ref = 1;
f0100e6f:	a1 10 af 22 f0       	mov    0xf022af10,%eax
f0100e74:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;	
f0100e7a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	size_t i;
	//临界点是否等于可能存在问题
	for (i = 1; i < npages; i++) {
f0100e80:	be 08 00 00 00       	mov    $0x8,%esi
f0100e85:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100e8a:	e9 c7 00 00 00       	jmp    f0100f56 <page_init+0xec>
		//lab4
		if (i == ROUNDUP(MPENTRY_PADDR, PGSIZE) / PGSIZE) {
f0100e8f:	83 fb 07             	cmp    $0x7,%ebx
f0100e92:	75 17                	jne    f0100eab <page_init+0x41>
        	pages[i].pp_ref = 1;
f0100e94:	a1 10 af 22 f0       	mov    0xf022af10,%eax
f0100e99:	66 c7 40 3c 01 00    	movw   $0x1,0x3c(%eax)
			pages[i].pp_link = NULL;
f0100e9f:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
        	continue;
f0100ea6:	e9 a5 00 00 00       	jmp    f0100f50 <page_init+0xe6>
    	}

		
	//  2) The rest of base memory
		if(i < npages_basemem){
f0100eab:	3b 1d 48 a2 22 f0    	cmp    0xf022a248,%ebx
f0100eb1:	73 25                	jae    f0100ed8 <page_init+0x6e>
			pages[i].pp_ref = 0;
f0100eb3:	89 f0                	mov    %esi,%eax
f0100eb5:	03 05 10 af 22 f0    	add    0xf022af10,%eax
f0100ebb:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100ec1:	8b 15 44 a2 22 f0    	mov    0xf022a244,%edx
f0100ec7:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100ec9:	89 f0                	mov    %esi,%eax
f0100ecb:	03 05 10 af 22 f0    	add    0xf022af10,%eax
f0100ed1:	a3 44 a2 22 f0       	mov    %eax,0xf022a244
f0100ed6:	eb 78                	jmp    f0100f50 <page_init+0xe6>
		}
	//  3) Then comes the IO hole 
		else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE){
f0100ed8:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100ede:	83 f8 5f             	cmp    $0x5f,%eax
f0100ee1:	77 16                	ja     f0100ef9 <page_init+0x8f>
			pages[i].pp_ref = 1;
f0100ee3:	89 f0                	mov    %esi,%eax
f0100ee5:	03 05 10 af 22 f0    	add    0xf022af10,%eax
f0100eeb:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100ef1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100ef7:	eb 57                	jmp    f0100f50 <page_init+0xe6>
		}
	//  4) Then extended memory
		else if(i >= EXTPHYSMEM/PGSIZE && i< ((int)boot_alloc(0) - KERNBASE)/PGSIZE){
f0100ef9:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100eff:	76 2c                	jbe    f0100f2d <page_init+0xc3>
f0100f01:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f06:	e8 59 fb ff ff       	call   f0100a64 <boot_alloc>
f0100f0b:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f10:	c1 e8 0c             	shr    $0xc,%eax
f0100f13:	39 c3                	cmp    %eax,%ebx
f0100f15:	73 16                	jae    f0100f2d <page_init+0xc3>
			pages[i].pp_ref = 1;
f0100f17:	89 f0                	mov    %esi,%eax
f0100f19:	03 05 10 af 22 f0    	add    0xf022af10,%eax
f0100f1f:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100f25:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100f2b:	eb 23                	jmp    f0100f50 <page_init+0xe6>
		}
		else{
			pages[i].pp_ref = 0;
f0100f2d:	89 f0                	mov    %esi,%eax
f0100f2f:	03 05 10 af 22 f0    	add    0xf022af10,%eax
f0100f35:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100f3b:	8b 15 44 a2 22 f0    	mov    0xf022a244,%edx
f0100f41:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100f43:	89 f0                	mov    %esi,%eax
f0100f45:	03 05 10 af 22 f0    	add    0xf022af10,%eax
f0100f4b:	a3 44 a2 22 f0       	mov    %eax,0xf022a244
	//  1) Mark physical page 0 as in use.
	pages[0].pp_ref = 1;
	pages[0].pp_link = NULL;	
	size_t i;
	//临界点是否等于可能存在问题
	for (i = 1; i < npages; i++) {
f0100f50:	83 c3 01             	add    $0x1,%ebx
f0100f53:	83 c6 08             	add    $0x8,%esi
f0100f56:	3b 1d 08 af 22 f0    	cmp    0xf022af08,%ebx
f0100f5c:	0f 82 2d ff ff ff    	jb     f0100e8f <page_init+0x25>

	//要在循环里判断，否者该项以及在page_free_list中
	//i = ROUNDUP(MPENTRY_PADDR, PGSIZE) / PGSIZE;
	//pages[i].pp_ref = 1;
	//pages[i].pp_link = NULL;
}
f0100f62:	5b                   	pop    %ebx
f0100f63:	5e                   	pop    %esi
f0100f64:	5d                   	pop    %ebp
f0100f65:	c3                   	ret    

f0100f66 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100f66:	55                   	push   %ebp
f0100f67:	89 e5                	mov    %esp,%ebp
f0100f69:	53                   	push   %ebx
f0100f6a:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	//cprintf("page_alloc\r\n");
	if(page_free_list == NULL)
f0100f6d:	8b 1d 44 a2 22 f0    	mov    0xf022a244,%ebx
f0100f73:	85 db                	test   %ebx,%ebx
f0100f75:	74 6e                	je     f0100fe5 <page_alloc+0x7f>
		//addr = page2kva(page_free_list);
		//int *iq,*ip;
		//iq=ip;//将把ip中的值拷贝到iq中，这样，指针iq也将指向ip指向的对象
		struct PageInfo *Page;
		Page = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100f77:	8b 03                	mov    (%ebx),%eax
f0100f79:	a3 44 a2 22 f0       	mov    %eax,0xf022a244
		//page_free_list->pp_link = NULL;
		Page->pp_link = NULL;
f0100f7e:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		//Page->pp_ref = 1;
		Page->pp_ref = 0;
f0100f84:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		cprintf("page_alloc\r\n");
f0100f8a:	83 ec 0c             	sub    $0xc,%esp
f0100f8d:	68 c8 69 10 f0       	push   $0xf01069c8
f0100f92:	e8 b1 27 00 00       	call   f0103748 <cprintf>
		if(alloc_flags & ALLOC_ZERO)
f0100f97:	83 c4 10             	add    $0x10,%esp
f0100f9a:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100f9e:	74 45                	je     f0100fe5 <page_alloc+0x7f>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fa0:	89 d8                	mov    %ebx,%eax
f0100fa2:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f0100fa8:	c1 f8 03             	sar    $0x3,%eax
f0100fab:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fae:	89 c2                	mov    %eax,%edx
f0100fb0:	c1 ea 0c             	shr    $0xc,%edx
f0100fb3:	3b 15 08 af 22 f0    	cmp    0xf022af08,%edx
f0100fb9:	72 12                	jb     f0100fcd <page_alloc+0x67>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fbb:	50                   	push   %eax
f0100fbc:	68 a4 59 10 f0       	push   $0xf01059a4
f0100fc1:	6a 58                	push   $0x58
f0100fc3:	68 01 69 10 f0       	push   $0xf0106901
f0100fc8:	e8 73 f0 ff ff       	call   f0100040 <_panic>
			memset(page2kva(Page),'\0',PGSIZE);
f0100fcd:	83 ec 04             	sub    $0x4,%esp
f0100fd0:	68 00 10 00 00       	push   $0x1000
f0100fd5:	6a 00                	push   $0x0
f0100fd7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100fdc:	50                   	push   %eax
f0100fdd:	e8 e1 3c 00 00       	call   f0104cc3 <memset>
f0100fe2:	83 c4 10             	add    $0x10,%esp
			// memset(page2kva(page_free_list),0,PGSIZE);
		return Page;
	}
}
f0100fe5:	89 d8                	mov    %ebx,%eax
f0100fe7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fea:	c9                   	leave  
f0100feb:	c3                   	ret    

f0100fec <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100fec:	55                   	push   %ebp
f0100fed:	89 e5                	mov    %esp,%ebp
f0100fef:	83 ec 14             	sub    $0x14,%esp
f0100ff2:	8b 45 08             	mov    0x8(%ebp),%eax
	//  	panic("can't free the page");
	//  	return;
	// }
	//	cprinf("can't free the page");
	//pp->pp_link = page_free_list->pp_link;	
	pp->pp_link = page_free_list;
f0100ff5:	8b 15 44 a2 22 f0    	mov    0xf022a244,%edx
f0100ffb:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100ffd:	a3 44 a2 22 f0       	mov    %eax,0xf022a244
	//pp->pp_ref = 0;
	cprintf("page_free\r\n");
f0101002:	68 d5 69 10 f0       	push   $0xf01069d5
f0101007:	e8 3c 27 00 00       	call   f0103748 <cprintf>
}
f010100c:	83 c4 10             	add    $0x10,%esp
f010100f:	c9                   	leave  
f0101010:	c3                   	ret    

f0101011 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101011:	55                   	push   %ebp
f0101012:	89 e5                	mov    %esp,%ebp
f0101014:	83 ec 08             	sub    $0x8,%esp
f0101017:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f010101a:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010101e:	83 e8 01             	sub    $0x1,%eax
f0101021:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101025:	66 85 c0             	test   %ax,%ax
f0101028:	75 0c                	jne    f0101036 <page_decref+0x25>
		page_free(pp);
f010102a:	83 ec 0c             	sub    $0xc,%esp
f010102d:	52                   	push   %edx
f010102e:	e8 b9 ff ff ff       	call   f0100fec <page_free>
f0101033:	83 c4 10             	add    $0x10,%esp
}
f0101036:	c9                   	leave  
f0101037:	c3                   	ret    

f0101038 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101038:	55                   	push   %ebp
f0101039:	89 e5                	mov    %esp,%ebp
f010103b:	56                   	push   %esi
f010103c:	53                   	push   %ebx
f010103d:	8b 45 0c             	mov    0xc(%ebp),%eax
	// Fill this function in
	uint32_t pd_number,pt_number,pt_addr;//,page_number,page_addr;
	pte_t *pte = NULL;
	struct PageInfo *Page;
	pd_number = PDX(va);
	pt_number = PTX(va);
f0101040:	89 c6                	mov    %eax,%esi
f0101042:	c1 ee 0c             	shr    $0xc,%esi
f0101045:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	if(pgdir[pd_number] & PTE_P)
f010104b:	c1 e8 16             	shr    $0x16,%eax
f010104e:	8d 1c 85 00 00 00 00 	lea    0x0(,%eax,4),%ebx
f0101055:	03 5d 08             	add    0x8(%ebp),%ebx
f0101058:	8b 03                	mov    (%ebx),%eax
f010105a:	a8 01                	test   $0x1,%al
f010105c:	74 2e                	je     f010108c <pgdir_walk+0x54>
		pte = KADDR(PTE_ADDR(pgdir[pd_number]));
f010105e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101063:	89 c2                	mov    %eax,%edx
f0101065:	c1 ea 0c             	shr    $0xc,%edx
f0101068:	39 15 08 af 22 f0    	cmp    %edx,0xf022af08
f010106e:	77 15                	ja     f0101085 <pgdir_walk+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101070:	50                   	push   %eax
f0101071:	68 a4 59 10 f0       	push   $0xf01059a4
f0101076:	68 c8 01 00 00       	push   $0x1c8
f010107b:	68 f5 68 10 f0       	push   $0xf01068f5
f0101080:	e8 bb ef ff ff       	call   f0100040 <_panic>
	if(!pte){
f0101085:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010108a:	75 58                	jne    f01010e4 <pgdir_walk+0xac>
		if(!create)
f010108c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101090:	74 57                	je     f01010e9 <pgdir_walk+0xb1>
	 		return NULL;
	 	Page = page_alloc(create);
f0101092:	83 ec 0c             	sub    $0xc,%esp
f0101095:	ff 75 10             	pushl  0x10(%ebp)
f0101098:	e8 c9 fe ff ff       	call   f0100f66 <page_alloc>
		if(!Page)
f010109d:	83 c4 10             	add    $0x10,%esp
f01010a0:	85 c0                	test   %eax,%eax
f01010a2:	74 4c                	je     f01010f0 <pgdir_walk+0xb8>
			return NULL;
		Page->pp_ref ++;
f01010a4:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010a9:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f01010af:	89 c2                	mov    %eax,%edx
f01010b1:	c1 fa 03             	sar    $0x3,%edx
f01010b4:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010b7:	89 d0                	mov    %edx,%eax
f01010b9:	c1 e8 0c             	shr    $0xc,%eax
f01010bc:	3b 05 08 af 22 f0    	cmp    0xf022af08,%eax
f01010c2:	72 15                	jb     f01010d9 <pgdir_walk+0xa1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010c4:	52                   	push   %edx
f01010c5:	68 a4 59 10 f0       	push   $0xf01059a4
f01010ca:	68 d0 01 00 00       	push   $0x1d0
f01010cf:	68 f5 68 10 f0       	push   $0xf01068f5
f01010d4:	e8 67 ef ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01010d9:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	 	pte = KADDR(page2pa(Page));		
		// pgdir[pd_number] = page2pa(Page);
		pgdir[pd_number] = page2pa(Page) | PTE_P | PTE_W | PTE_U;
f01010df:	83 ca 07             	or     $0x7,%edx
f01010e2:	89 13                	mov    %edx,(%ebx)
	}
	return &(pte[pt_number]);
f01010e4:	8d 04 b0             	lea    (%eax,%esi,4),%eax
f01010e7:	eb 0c                	jmp    f01010f5 <pgdir_walk+0xbd>
	pt_number = PTX(va);
	if(pgdir[pd_number] & PTE_P)
		pte = KADDR(PTE_ADDR(pgdir[pd_number]));
	if(!pte){
		if(!create)
	 		return NULL;
f01010e9:	b8 00 00 00 00       	mov    $0x0,%eax
f01010ee:	eb 05                	jmp    f01010f5 <pgdir_walk+0xbd>
	 	Page = page_alloc(create);
		if(!Page)
			return NULL;
f01010f0:	b8 00 00 00 00       	mov    $0x0,%eax
	// //不确定page_alloc函数里应该填入的参数,page_alloc(int alloc_flags)
	// 	Page = page_alloc(create);
	// 	page_addr = page2pa(Page);
	// }
	// return page_addr;
}
f01010f5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01010f8:	5b                   	pop    %ebx
f01010f9:	5e                   	pop    %esi
f01010fa:	5d                   	pop    %ebp
f01010fb:	c3                   	ret    

f01010fc <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01010fc:	55                   	push   %ebp
f01010fd:	89 e5                	mov    %esp,%ebp
f01010ff:	57                   	push   %edi
f0101100:	56                   	push   %esi
f0101101:	53                   	push   %ebx
f0101102:	83 ec 20             	sub    $0x20,%esp
f0101105:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101108:	89 d7                	mov    %edx,%edi
f010110a:	89 cb                	mov    %ecx,%ebx
	// Fill this function in
	pte_t *pte = NULL;
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
f010110c:	ff 75 08             	pushl  0x8(%ebp)
f010110f:	52                   	push   %edx
f0101110:	68 88 60 10 f0       	push   $0xf0106088
f0101115:	e8 2e 26 00 00       	call   f0103748 <cprintf>
	for(int i = 0;i < PGNUM(size);i += PGSIZE){
f010111a:	c1 eb 0c             	shr    $0xc,%ebx
f010111d:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101120:	83 c4 10             	add    $0x10,%esp
f0101123:	bb 00 00 00 00       	mov    $0x0,%ebx
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
f0101128:	8b 45 0c             	mov    0xc(%ebp),%eax
f010112b:	83 c8 01             	or     $0x1,%eax
f010112e:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte = NULL;
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for(int i = 0;i < PGNUM(size);i += PGSIZE){
f0101131:	eb 1f                	jmp    f0101152 <boot_map_region+0x56>
		pte = pgdir_walk(pgdir, (void *)va, 1);
f0101133:	83 ec 04             	sub    $0x4,%esp
f0101136:	6a 01                	push   $0x1
f0101138:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f010113b:	50                   	push   %eax
f010113c:	ff 75 e0             	pushl  -0x20(%ebp)
f010113f:	e8 f4 fe ff ff       	call   f0101038 <pgdir_walk>
		*pte = (pa | perm | PTE_P);
f0101144:	0b 75 dc             	or     -0x24(%ebp),%esi
f0101147:	89 30                	mov    %esi,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte = NULL;
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for(int i = 0;i < PGNUM(size);i += PGSIZE){
f0101149:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010114f:	83 c4 10             	add    $0x10,%esp
f0101152:	89 de                	mov    %ebx,%esi
f0101154:	03 75 08             	add    0x8(%ebp),%esi
f0101157:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f010115a:	77 d7                	ja     f0101133 <boot_map_region+0x37>
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f010115c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010115f:	5b                   	pop    %ebx
f0101160:	5e                   	pop    %esi
f0101161:	5f                   	pop    %edi
f0101162:	5d                   	pop    %ebp
f0101163:	c3                   	ret    

f0101164 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101164:	55                   	push   %ebp
f0101165:	89 e5                	mov    %esp,%ebp
f0101167:	53                   	push   %ebx
f0101168:	83 ec 08             	sub    $0x8,%esp
f010116b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
f010116e:	6a 00                	push   $0x0
f0101170:	ff 75 0c             	pushl  0xc(%ebp)
f0101173:	ff 75 08             	pushl  0x8(%ebp)
f0101176:	e8 bd fe ff ff       	call   f0101038 <pgdir_walk>
	if(!pte)
f010117b:	83 c4 10             	add    $0x10,%esp
f010117e:	85 c0                	test   %eax,%eax
f0101180:	74 32                	je     f01011b4 <page_lookup+0x50>
		return NULL;
	if(pte_store)
f0101182:	85 db                	test   %ebx,%ebx
f0101184:	74 02                	je     f0101188 <page_lookup+0x24>
		*pte_store = pte;
f0101186:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101188:	8b 00                	mov    (%eax),%eax
f010118a:	c1 e8 0c             	shr    $0xc,%eax
f010118d:	3b 05 08 af 22 f0    	cmp    0xf022af08,%eax
f0101193:	72 14                	jb     f01011a9 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0101195:	83 ec 04             	sub    $0x4,%esp
f0101198:	68 bc 60 10 f0       	push   $0xf01060bc
f010119d:	6a 51                	push   $0x51
f010119f:	68 01 69 10 f0       	push   $0xf0106901
f01011a4:	e8 97 ee ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f01011a9:	8b 15 10 af 22 f0    	mov    0xf022af10,%edx
f01011af:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	return pa2page(PTE_ADDR(*pte));
f01011b2:	eb 05                	jmp    f01011b9 <page_lookup+0x55>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
	if(!pte)
		return NULL;
f01011b4:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f01011b9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01011bc:	c9                   	leave  
f01011bd:	c3                   	ret    

f01011be <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01011be:	55                   	push   %ebp
f01011bf:	89 e5                	mov    %esp,%ebp
f01011c1:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f01011c4:	e8 1d 41 00 00       	call   f01052e6 <cpunum>
f01011c9:	6b c0 74             	imul   $0x74,%eax,%eax
f01011cc:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f01011d3:	74 16                	je     f01011eb <tlb_invalidate+0x2d>
f01011d5:	e8 0c 41 00 00       	call   f01052e6 <cpunum>
f01011da:	6b c0 74             	imul   $0x74,%eax,%eax
f01011dd:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01011e3:	8b 55 08             	mov    0x8(%ebp),%edx
f01011e6:	39 50 60             	cmp    %edx,0x60(%eax)
f01011e9:	75 06                	jne    f01011f1 <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01011eb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011ee:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f01011f1:	c9                   	leave  
f01011f2:	c3                   	ret    

f01011f3 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01011f3:	55                   	push   %ebp
f01011f4:	89 e5                	mov    %esp,%ebp
f01011f6:	57                   	push   %edi
f01011f7:	56                   	push   %esi
f01011f8:	53                   	push   %ebx
f01011f9:	83 ec 20             	sub    $0x20,%esp
f01011fc:	8b 75 08             	mov    0x8(%ebp),%esi
f01011ff:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pte_t *pte;
	// pte_t *pte,**pte_store;
	// pte = pgdir_walk(pgdir, (void *)va, 0);
	// pte_store = &pte;
	struct PageInfo *Page;
	Page = page_lookup(pgdir, va, &pte);
f0101202:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101205:	50                   	push   %eax
f0101206:	57                   	push   %edi
f0101207:	56                   	push   %esi
f0101208:	e8 57 ff ff ff       	call   f0101164 <page_lookup>
	// Page = page_lookup(pgdir, va, pte_store);
	if(Page){
f010120d:	83 c4 10             	add    $0x10,%esp
f0101210:	85 c0                	test   %eax,%eax
f0101212:	74 20                	je     f0101234 <page_remove+0x41>
f0101214:	89 c3                	mov    %eax,%ebx
		// Page->pp_ref --;
		tlb_invalidate(pgdir, va);
f0101216:	83 ec 08             	sub    $0x8,%esp
f0101219:	57                   	push   %edi
f010121a:	56                   	push   %esi
f010121b:	e8 9e ff ff ff       	call   f01011be <tlb_invalidate>
		page_decref(Page);
f0101220:	89 1c 24             	mov    %ebx,(%esp)
f0101223:	e8 e9 fd ff ff       	call   f0101011 <page_decref>
		*pte = 0;//将对应的页表项清空
f0101228:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010122b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101231:	83 c4 10             	add    $0x10,%esp
	}
}
f0101234:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101237:	5b                   	pop    %ebx
f0101238:	5e                   	pop    %esi
f0101239:	5f                   	pop    %edi
f010123a:	5d                   	pop    %ebp
f010123b:	c3                   	ret    

f010123c <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010123c:	55                   	push   %ebp
f010123d:	89 e5                	mov    %esp,%ebp
f010123f:	57                   	push   %edi
f0101240:	56                   	push   %esi
f0101241:	53                   	push   %ebx
f0101242:	83 ec 10             	sub    $0x10,%esp
f0101245:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101248:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
f010124b:	6a 01                	push   $0x1
f010124d:	57                   	push   %edi
f010124e:	ff 75 08             	pushl  0x8(%ebp)
f0101251:	e8 e2 fd ff ff       	call   f0101038 <pgdir_walk>
	if(!pte)
f0101256:	83 c4 10             	add    $0x10,%esp
f0101259:	85 c0                	test   %eax,%eax
f010125b:	74 38                	je     f0101295 <page_insert+0x59>
f010125d:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	pp->pp_ref++;
f010125f:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	//删除旧映射关系 
    if((*pte) & PTE_P)
f0101264:	f6 00 01             	testb  $0x1,(%eax)
f0101267:	74 0f                	je     f0101278 <page_insert+0x3c>
        page_remove(pgdir, va);
f0101269:	83 ec 08             	sub    $0x8,%esp
f010126c:	57                   	push   %edi
f010126d:	ff 75 08             	pushl  0x8(%ebp)
f0101270:	e8 7e ff ff ff       	call   f01011f3 <page_remove>
f0101275:	83 c4 10             	add    $0x10,%esp
	//pp ->pp_ref++;
    *pte = page2pa(pp) | perm | PTE_P;
f0101278:	2b 1d 10 af 22 f0    	sub    0xf022af10,%ebx
f010127e:	c1 fb 03             	sar    $0x3,%ebx
f0101281:	c1 e3 0c             	shl    $0xc,%ebx
f0101284:	8b 45 14             	mov    0x14(%ebp),%eax
f0101287:	83 c8 01             	or     $0x1,%eax
f010128a:	09 c3                	or     %eax,%ebx
f010128c:	89 1e                	mov    %ebx,(%esi)
	return 0;
f010128e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101293:	eb 05                	jmp    f010129a <page_insert+0x5e>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
	if(!pte)
		return -E_NO_MEM;
f0101295:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	// 		page_remove(pgdir, va); 
	// }
	// //pp->pp_ref++;
    // *pte = page2pa(pp) | perm | PTE_P;
	// return 0;
}
f010129a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010129d:	5b                   	pop    %ebx
f010129e:	5e                   	pop    %esi
f010129f:	5f                   	pop    %edi
f01012a0:	5d                   	pop    %ebp
f01012a1:	c3                   	ret    

f01012a2 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01012a2:	55                   	push   %ebp
f01012a3:	89 e5                	mov    %esp,%ebp
f01012a5:	53                   	push   %ebx
f01012a6:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	size = ROUNDUP(size, PGSIZE);
f01012a9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012ac:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f01012b2:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	pa = ROUNDDOWN(pa, PGSIZE);
f01012b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01012bb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	
	if(base + size > MMIOLIM)
f01012c0:	8b 15 00 f3 11 f0    	mov    0xf011f300,%edx
f01012c6:	8d 0c 13             	lea    (%ebx,%edx,1),%ecx
f01012c9:	81 f9 00 00 c0 ef    	cmp    $0xefc00000,%ecx
f01012cf:	76 17                	jbe    f01012e8 <mmio_map_region+0x46>
		panic("MMIOLIM is not enough");
f01012d1:	83 ec 04             	sub    $0x4,%esp
f01012d4:	68 e1 69 10 f0       	push   $0xf01069e1
f01012d9:	68 b6 02 00 00       	push   $0x2b6
f01012de:	68 f5 68 10 f0       	push   $0xf01068f5
f01012e3:	e8 58 ed ff ff       	call   f0100040 <_panic>

	boot_map_region(kern_pgdir, base, size, pa, PTE_PCD|PTE_PWT|PTE_W);
f01012e8:	83 ec 08             	sub    $0x8,%esp
f01012eb:	6a 1a                	push   $0x1a
f01012ed:	50                   	push   %eax
f01012ee:	89 d9                	mov    %ebx,%ecx
f01012f0:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f01012f5:	e8 02 fe ff ff       	call   f01010fc <boot_map_region>
	base += size;//每次映射到不同的页面
f01012fa:	a1 00 f3 11 f0       	mov    0xf011f300,%eax
f01012ff:	01 c3                	add    %eax,%ebx
f0101301:	89 1d 00 f3 11 f0    	mov    %ebx,0xf011f300
	return (void *)(base-size);
	//panic("mmio_map_region not implemented");
}
f0101307:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010130a:	c9                   	leave  
f010130b:	c3                   	ret    

f010130c <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010130c:	55                   	push   %ebp
f010130d:	89 e5                	mov    %esp,%ebp
f010130f:	57                   	push   %edi
f0101310:	56                   	push   %esi
f0101311:	53                   	push   %ebx
f0101312:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101315:	6a 15                	push   $0x15
f0101317:	e8 ad 22 00 00       	call   f01035c9 <mc146818_read>
f010131c:	89 c3                	mov    %eax,%ebx
f010131e:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101325:	e8 9f 22 00 00       	call   f01035c9 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010132a:	c1 e0 08             	shl    $0x8,%eax
f010132d:	09 d8                	or     %ebx,%eax
f010132f:	c1 e0 0a             	shl    $0xa,%eax
f0101332:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101338:	85 c0                	test   %eax,%eax
f010133a:	0f 48 c2             	cmovs  %edx,%eax
f010133d:	c1 f8 0c             	sar    $0xc,%eax
f0101340:	a3 48 a2 22 f0       	mov    %eax,0xf022a248
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101345:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010134c:	e8 78 22 00 00       	call   f01035c9 <mc146818_read>
f0101351:	89 c3                	mov    %eax,%ebx
f0101353:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010135a:	e8 6a 22 00 00       	call   f01035c9 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010135f:	c1 e0 08             	shl    $0x8,%eax
f0101362:	09 d8                	or     %ebx,%eax
f0101364:	c1 e0 0a             	shl    $0xa,%eax
f0101367:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010136d:	83 c4 10             	add    $0x10,%esp
f0101370:	85 c0                	test   %eax,%eax
f0101372:	0f 48 c2             	cmovs  %edx,%eax
f0101375:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101378:	85 c0                	test   %eax,%eax
f010137a:	74 0e                	je     f010138a <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010137c:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101382:	89 15 08 af 22 f0    	mov    %edx,0xf022af08
f0101388:	eb 0c                	jmp    f0101396 <mem_init+0x8a>
	else
		npages = npages_basemem;
f010138a:	8b 15 48 a2 22 f0    	mov    0xf022a248,%edx
f0101390:	89 15 08 af 22 f0    	mov    %edx,0xf022af08

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101396:	c1 e0 0c             	shl    $0xc,%eax
f0101399:	c1 e8 0a             	shr    $0xa,%eax
f010139c:	50                   	push   %eax
f010139d:	a1 48 a2 22 f0       	mov    0xf022a248,%eax
f01013a2:	c1 e0 0c             	shl    $0xc,%eax
f01013a5:	c1 e8 0a             	shr    $0xa,%eax
f01013a8:	50                   	push   %eax
f01013a9:	a1 08 af 22 f0       	mov    0xf022af08,%eax
f01013ae:	c1 e0 0c             	shl    $0xc,%eax
f01013b1:	c1 e8 0a             	shr    $0xa,%eax
f01013b4:	50                   	push   %eax
f01013b5:	68 dc 60 10 f0       	push   $0xf01060dc
f01013ba:	e8 89 23 00 00       	call   f0103748 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01013bf:	b8 00 10 00 00       	mov    $0x1000,%eax
f01013c4:	e8 9b f6 ff ff       	call   f0100a64 <boot_alloc>
f01013c9:	a3 0c af 22 f0       	mov    %eax,0xf022af0c
	memset(kern_pgdir, 0, PGSIZE);
f01013ce:	83 c4 0c             	add    $0xc,%esp
f01013d1:	68 00 10 00 00       	push   $0x1000
f01013d6:	6a 00                	push   $0x0
f01013d8:	50                   	push   %eax
f01013d9:	e8 e5 38 00 00       	call   f0104cc3 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013de:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01013e3:	83 c4 10             	add    $0x10,%esp
f01013e6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013eb:	77 15                	ja     f0101402 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01013ed:	50                   	push   %eax
f01013ee:	68 c8 59 10 f0       	push   $0xf01059c8
f01013f3:	68 90 00 00 00       	push   $0x90
f01013f8:	68 f5 68 10 f0       	push   $0xf01068f5
f01013fd:	e8 3e ec ff ff       	call   f0100040 <_panic>
f0101402:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101408:	83 ca 05             	or     $0x5,%edx
f010140b:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f0101411:	a1 08 af 22 f0       	mov    0xf022af08,%eax
f0101416:	c1 e0 03             	shl    $0x3,%eax
f0101419:	e8 46 f6 ff ff       	call   f0100a64 <boot_alloc>
f010141e:	a3 10 af 22 f0       	mov    %eax,0xf022af10
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101423:	83 ec 04             	sub    $0x4,%esp
f0101426:	8b 0d 08 af 22 f0    	mov    0xf022af08,%ecx
f010142c:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101433:	52                   	push   %edx
f0101434:	6a 00                	push   $0x0
f0101436:	50                   	push   %eax
f0101437:	e8 87 38 00 00       	call   f0104cc3 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*)boot_alloc(NENV * sizeof(struct Env));
f010143c:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101441:	e8 1e f6 ff ff       	call   f0100a64 <boot_alloc>
f0101446:	a3 4c a2 22 f0       	mov    %eax,0xf022a24c
	memset(envs, 0, NENV * sizeof(struct Env));
f010144b:	83 c4 0c             	add    $0xc,%esp
f010144e:	68 00 f0 01 00       	push   $0x1f000
f0101453:	6a 00                	push   $0x0
f0101455:	50                   	push   %eax
f0101456:	e8 68 38 00 00       	call   f0104cc3 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010145b:	e8 0a fa ff ff       	call   f0100e6a <page_init>

	check_page_free_list(1);
f0101460:	b8 01 00 00 00       	mov    $0x1,%eax
f0101465:	e8 11 f7 ff ff       	call   f0100b7b <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010146a:	83 c4 10             	add    $0x10,%esp
f010146d:	83 3d 10 af 22 f0 00 	cmpl   $0x0,0xf022af10
f0101474:	75 17                	jne    f010148d <mem_init+0x181>
		panic("'pages' is a null pointer!");
f0101476:	83 ec 04             	sub    $0x4,%esp
f0101479:	68 f7 69 10 f0       	push   $0xf01069f7
f010147e:	68 4f 03 00 00       	push   $0x34f
f0101483:	68 f5 68 10 f0       	push   $0xf01068f5
f0101488:	e8 b3 eb ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010148d:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
f0101492:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101497:	eb 05                	jmp    f010149e <mem_init+0x192>
		++nfree;
f0101499:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010149c:	8b 00                	mov    (%eax),%eax
f010149e:	85 c0                	test   %eax,%eax
f01014a0:	75 f7                	jne    f0101499 <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014a2:	83 ec 0c             	sub    $0xc,%esp
f01014a5:	6a 00                	push   $0x0
f01014a7:	e8 ba fa ff ff       	call   f0100f66 <page_alloc>
f01014ac:	89 c7                	mov    %eax,%edi
f01014ae:	83 c4 10             	add    $0x10,%esp
f01014b1:	85 c0                	test   %eax,%eax
f01014b3:	75 19                	jne    f01014ce <mem_init+0x1c2>
f01014b5:	68 12 6a 10 f0       	push   $0xf0106a12
f01014ba:	68 1b 69 10 f0       	push   $0xf010691b
f01014bf:	68 57 03 00 00       	push   $0x357
f01014c4:	68 f5 68 10 f0       	push   $0xf01068f5
f01014c9:	e8 72 eb ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01014ce:	83 ec 0c             	sub    $0xc,%esp
f01014d1:	6a 00                	push   $0x0
f01014d3:	e8 8e fa ff ff       	call   f0100f66 <page_alloc>
f01014d8:	89 c6                	mov    %eax,%esi
f01014da:	83 c4 10             	add    $0x10,%esp
f01014dd:	85 c0                	test   %eax,%eax
f01014df:	75 19                	jne    f01014fa <mem_init+0x1ee>
f01014e1:	68 28 6a 10 f0       	push   $0xf0106a28
f01014e6:	68 1b 69 10 f0       	push   $0xf010691b
f01014eb:	68 58 03 00 00       	push   $0x358
f01014f0:	68 f5 68 10 f0       	push   $0xf01068f5
f01014f5:	e8 46 eb ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01014fa:	83 ec 0c             	sub    $0xc,%esp
f01014fd:	6a 00                	push   $0x0
f01014ff:	e8 62 fa ff ff       	call   f0100f66 <page_alloc>
f0101504:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101507:	83 c4 10             	add    $0x10,%esp
f010150a:	85 c0                	test   %eax,%eax
f010150c:	75 19                	jne    f0101527 <mem_init+0x21b>
f010150e:	68 3e 6a 10 f0       	push   $0xf0106a3e
f0101513:	68 1b 69 10 f0       	push   $0xf010691b
f0101518:	68 59 03 00 00       	push   $0x359
f010151d:	68 f5 68 10 f0       	push   $0xf01068f5
f0101522:	e8 19 eb ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101527:	39 f7                	cmp    %esi,%edi
f0101529:	75 19                	jne    f0101544 <mem_init+0x238>
f010152b:	68 54 6a 10 f0       	push   $0xf0106a54
f0101530:	68 1b 69 10 f0       	push   $0xf010691b
f0101535:	68 5c 03 00 00       	push   $0x35c
f010153a:	68 f5 68 10 f0       	push   $0xf01068f5
f010153f:	e8 fc ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101544:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101547:	39 c7                	cmp    %eax,%edi
f0101549:	74 04                	je     f010154f <mem_init+0x243>
f010154b:	39 c6                	cmp    %eax,%esi
f010154d:	75 19                	jne    f0101568 <mem_init+0x25c>
f010154f:	68 18 61 10 f0       	push   $0xf0106118
f0101554:	68 1b 69 10 f0       	push   $0xf010691b
f0101559:	68 5d 03 00 00       	push   $0x35d
f010155e:	68 f5 68 10 f0       	push   $0xf01068f5
f0101563:	e8 d8 ea ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101568:	8b 0d 10 af 22 f0    	mov    0xf022af10,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010156e:	8b 15 08 af 22 f0    	mov    0xf022af08,%edx
f0101574:	c1 e2 0c             	shl    $0xc,%edx
f0101577:	89 f8                	mov    %edi,%eax
f0101579:	29 c8                	sub    %ecx,%eax
f010157b:	c1 f8 03             	sar    $0x3,%eax
f010157e:	c1 e0 0c             	shl    $0xc,%eax
f0101581:	39 d0                	cmp    %edx,%eax
f0101583:	72 19                	jb     f010159e <mem_init+0x292>
f0101585:	68 66 6a 10 f0       	push   $0xf0106a66
f010158a:	68 1b 69 10 f0       	push   $0xf010691b
f010158f:	68 5e 03 00 00       	push   $0x35e
f0101594:	68 f5 68 10 f0       	push   $0xf01068f5
f0101599:	e8 a2 ea ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010159e:	89 f0                	mov    %esi,%eax
f01015a0:	29 c8                	sub    %ecx,%eax
f01015a2:	c1 f8 03             	sar    $0x3,%eax
f01015a5:	c1 e0 0c             	shl    $0xc,%eax
f01015a8:	39 c2                	cmp    %eax,%edx
f01015aa:	77 19                	ja     f01015c5 <mem_init+0x2b9>
f01015ac:	68 83 6a 10 f0       	push   $0xf0106a83
f01015b1:	68 1b 69 10 f0       	push   $0xf010691b
f01015b6:	68 5f 03 00 00       	push   $0x35f
f01015bb:	68 f5 68 10 f0       	push   $0xf01068f5
f01015c0:	e8 7b ea ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01015c5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015c8:	29 c8                	sub    %ecx,%eax
f01015ca:	c1 f8 03             	sar    $0x3,%eax
f01015cd:	c1 e0 0c             	shl    $0xc,%eax
f01015d0:	39 c2                	cmp    %eax,%edx
f01015d2:	77 19                	ja     f01015ed <mem_init+0x2e1>
f01015d4:	68 a0 6a 10 f0       	push   $0xf0106aa0
f01015d9:	68 1b 69 10 f0       	push   $0xf010691b
f01015de:	68 60 03 00 00       	push   $0x360
f01015e3:	68 f5 68 10 f0       	push   $0xf01068f5
f01015e8:	e8 53 ea ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015ed:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
f01015f2:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015f5:	c7 05 44 a2 22 f0 00 	movl   $0x0,0xf022a244
f01015fc:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015ff:	83 ec 0c             	sub    $0xc,%esp
f0101602:	6a 00                	push   $0x0
f0101604:	e8 5d f9 ff ff       	call   f0100f66 <page_alloc>
f0101609:	83 c4 10             	add    $0x10,%esp
f010160c:	85 c0                	test   %eax,%eax
f010160e:	74 19                	je     f0101629 <mem_init+0x31d>
f0101610:	68 bd 6a 10 f0       	push   $0xf0106abd
f0101615:	68 1b 69 10 f0       	push   $0xf010691b
f010161a:	68 67 03 00 00       	push   $0x367
f010161f:	68 f5 68 10 f0       	push   $0xf01068f5
f0101624:	e8 17 ea ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101629:	83 ec 0c             	sub    $0xc,%esp
f010162c:	57                   	push   %edi
f010162d:	e8 ba f9 ff ff       	call   f0100fec <page_free>
	page_free(pp1);
f0101632:	89 34 24             	mov    %esi,(%esp)
f0101635:	e8 b2 f9 ff ff       	call   f0100fec <page_free>
	page_free(pp2);
f010163a:	83 c4 04             	add    $0x4,%esp
f010163d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101640:	e8 a7 f9 ff ff       	call   f0100fec <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101645:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010164c:	e8 15 f9 ff ff       	call   f0100f66 <page_alloc>
f0101651:	89 c6                	mov    %eax,%esi
f0101653:	83 c4 10             	add    $0x10,%esp
f0101656:	85 c0                	test   %eax,%eax
f0101658:	75 19                	jne    f0101673 <mem_init+0x367>
f010165a:	68 12 6a 10 f0       	push   $0xf0106a12
f010165f:	68 1b 69 10 f0       	push   $0xf010691b
f0101664:	68 6e 03 00 00       	push   $0x36e
f0101669:	68 f5 68 10 f0       	push   $0xf01068f5
f010166e:	e8 cd e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101673:	83 ec 0c             	sub    $0xc,%esp
f0101676:	6a 00                	push   $0x0
f0101678:	e8 e9 f8 ff ff       	call   f0100f66 <page_alloc>
f010167d:	89 c7                	mov    %eax,%edi
f010167f:	83 c4 10             	add    $0x10,%esp
f0101682:	85 c0                	test   %eax,%eax
f0101684:	75 19                	jne    f010169f <mem_init+0x393>
f0101686:	68 28 6a 10 f0       	push   $0xf0106a28
f010168b:	68 1b 69 10 f0       	push   $0xf010691b
f0101690:	68 6f 03 00 00       	push   $0x36f
f0101695:	68 f5 68 10 f0       	push   $0xf01068f5
f010169a:	e8 a1 e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010169f:	83 ec 0c             	sub    $0xc,%esp
f01016a2:	6a 00                	push   $0x0
f01016a4:	e8 bd f8 ff ff       	call   f0100f66 <page_alloc>
f01016a9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016ac:	83 c4 10             	add    $0x10,%esp
f01016af:	85 c0                	test   %eax,%eax
f01016b1:	75 19                	jne    f01016cc <mem_init+0x3c0>
f01016b3:	68 3e 6a 10 f0       	push   $0xf0106a3e
f01016b8:	68 1b 69 10 f0       	push   $0xf010691b
f01016bd:	68 70 03 00 00       	push   $0x370
f01016c2:	68 f5 68 10 f0       	push   $0xf01068f5
f01016c7:	e8 74 e9 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016cc:	39 fe                	cmp    %edi,%esi
f01016ce:	75 19                	jne    f01016e9 <mem_init+0x3dd>
f01016d0:	68 54 6a 10 f0       	push   $0xf0106a54
f01016d5:	68 1b 69 10 f0       	push   $0xf010691b
f01016da:	68 72 03 00 00       	push   $0x372
f01016df:	68 f5 68 10 f0       	push   $0xf01068f5
f01016e4:	e8 57 e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016e9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016ec:	39 c7                	cmp    %eax,%edi
f01016ee:	74 04                	je     f01016f4 <mem_init+0x3e8>
f01016f0:	39 c6                	cmp    %eax,%esi
f01016f2:	75 19                	jne    f010170d <mem_init+0x401>
f01016f4:	68 18 61 10 f0       	push   $0xf0106118
f01016f9:	68 1b 69 10 f0       	push   $0xf010691b
f01016fe:	68 73 03 00 00       	push   $0x373
f0101703:	68 f5 68 10 f0       	push   $0xf01068f5
f0101708:	e8 33 e9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010170d:	83 ec 0c             	sub    $0xc,%esp
f0101710:	6a 00                	push   $0x0
f0101712:	e8 4f f8 ff ff       	call   f0100f66 <page_alloc>
f0101717:	83 c4 10             	add    $0x10,%esp
f010171a:	85 c0                	test   %eax,%eax
f010171c:	74 19                	je     f0101737 <mem_init+0x42b>
f010171e:	68 bd 6a 10 f0       	push   $0xf0106abd
f0101723:	68 1b 69 10 f0       	push   $0xf010691b
f0101728:	68 74 03 00 00       	push   $0x374
f010172d:	68 f5 68 10 f0       	push   $0xf01068f5
f0101732:	e8 09 e9 ff ff       	call   f0100040 <_panic>
f0101737:	89 f0                	mov    %esi,%eax
f0101739:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f010173f:	c1 f8 03             	sar    $0x3,%eax
f0101742:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101745:	89 c2                	mov    %eax,%edx
f0101747:	c1 ea 0c             	shr    $0xc,%edx
f010174a:	3b 15 08 af 22 f0    	cmp    0xf022af08,%edx
f0101750:	72 12                	jb     f0101764 <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101752:	50                   	push   %eax
f0101753:	68 a4 59 10 f0       	push   $0xf01059a4
f0101758:	6a 58                	push   $0x58
f010175a:	68 01 69 10 f0       	push   $0xf0106901
f010175f:	e8 dc e8 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101764:	83 ec 04             	sub    $0x4,%esp
f0101767:	68 00 10 00 00       	push   $0x1000
f010176c:	6a 01                	push   $0x1
f010176e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101773:	50                   	push   %eax
f0101774:	e8 4a 35 00 00       	call   f0104cc3 <memset>
	page_free(pp0);
f0101779:	89 34 24             	mov    %esi,(%esp)
f010177c:	e8 6b f8 ff ff       	call   f0100fec <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101781:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101788:	e8 d9 f7 ff ff       	call   f0100f66 <page_alloc>
f010178d:	83 c4 10             	add    $0x10,%esp
f0101790:	85 c0                	test   %eax,%eax
f0101792:	75 19                	jne    f01017ad <mem_init+0x4a1>
f0101794:	68 cc 6a 10 f0       	push   $0xf0106acc
f0101799:	68 1b 69 10 f0       	push   $0xf010691b
f010179e:	68 79 03 00 00       	push   $0x379
f01017a3:	68 f5 68 10 f0       	push   $0xf01068f5
f01017a8:	e8 93 e8 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01017ad:	39 c6                	cmp    %eax,%esi
f01017af:	74 19                	je     f01017ca <mem_init+0x4be>
f01017b1:	68 ea 6a 10 f0       	push   $0xf0106aea
f01017b6:	68 1b 69 10 f0       	push   $0xf010691b
f01017bb:	68 7a 03 00 00       	push   $0x37a
f01017c0:	68 f5 68 10 f0       	push   $0xf01068f5
f01017c5:	e8 76 e8 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017ca:	89 f0                	mov    %esi,%eax
f01017cc:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f01017d2:	c1 f8 03             	sar    $0x3,%eax
f01017d5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017d8:	89 c2                	mov    %eax,%edx
f01017da:	c1 ea 0c             	shr    $0xc,%edx
f01017dd:	3b 15 08 af 22 f0    	cmp    0xf022af08,%edx
f01017e3:	72 12                	jb     f01017f7 <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017e5:	50                   	push   %eax
f01017e6:	68 a4 59 10 f0       	push   $0xf01059a4
f01017eb:	6a 58                	push   $0x58
f01017ed:	68 01 69 10 f0       	push   $0xf0106901
f01017f2:	e8 49 e8 ff ff       	call   f0100040 <_panic>
f01017f7:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01017fd:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101803:	80 38 00             	cmpb   $0x0,(%eax)
f0101806:	74 19                	je     f0101821 <mem_init+0x515>
f0101808:	68 fa 6a 10 f0       	push   $0xf0106afa
f010180d:	68 1b 69 10 f0       	push   $0xf010691b
f0101812:	68 7d 03 00 00       	push   $0x37d
f0101817:	68 f5 68 10 f0       	push   $0xf01068f5
f010181c:	e8 1f e8 ff ff       	call   f0100040 <_panic>
f0101821:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101824:	39 d0                	cmp    %edx,%eax
f0101826:	75 db                	jne    f0101803 <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101828:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010182b:	a3 44 a2 22 f0       	mov    %eax,0xf022a244

	// free the pages we took
	page_free(pp0);
f0101830:	83 ec 0c             	sub    $0xc,%esp
f0101833:	56                   	push   %esi
f0101834:	e8 b3 f7 ff ff       	call   f0100fec <page_free>
	page_free(pp1);
f0101839:	89 3c 24             	mov    %edi,(%esp)
f010183c:	e8 ab f7 ff ff       	call   f0100fec <page_free>
	page_free(pp2);
f0101841:	83 c4 04             	add    $0x4,%esp
f0101844:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101847:	e8 a0 f7 ff ff       	call   f0100fec <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010184c:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
f0101851:	83 c4 10             	add    $0x10,%esp
f0101854:	eb 05                	jmp    f010185b <mem_init+0x54f>
		--nfree;
f0101856:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101859:	8b 00                	mov    (%eax),%eax
f010185b:	85 c0                	test   %eax,%eax
f010185d:	75 f7                	jne    f0101856 <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f010185f:	85 db                	test   %ebx,%ebx
f0101861:	74 19                	je     f010187c <mem_init+0x570>
f0101863:	68 04 6b 10 f0       	push   $0xf0106b04
f0101868:	68 1b 69 10 f0       	push   $0xf010691b
f010186d:	68 8a 03 00 00       	push   $0x38a
f0101872:	68 f5 68 10 f0       	push   $0xf01068f5
f0101877:	e8 c4 e7 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010187c:	83 ec 0c             	sub    $0xc,%esp
f010187f:	68 38 61 10 f0       	push   $0xf0106138
f0101884:	e8 bf 1e 00 00       	call   f0103748 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101889:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101890:	e8 d1 f6 ff ff       	call   f0100f66 <page_alloc>
f0101895:	89 c7                	mov    %eax,%edi
f0101897:	83 c4 10             	add    $0x10,%esp
f010189a:	85 c0                	test   %eax,%eax
f010189c:	75 19                	jne    f01018b7 <mem_init+0x5ab>
f010189e:	68 12 6a 10 f0       	push   $0xf0106a12
f01018a3:	68 1b 69 10 f0       	push   $0xf010691b
f01018a8:	68 f9 03 00 00       	push   $0x3f9
f01018ad:	68 f5 68 10 f0       	push   $0xf01068f5
f01018b2:	e8 89 e7 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01018b7:	83 ec 0c             	sub    $0xc,%esp
f01018ba:	6a 00                	push   $0x0
f01018bc:	e8 a5 f6 ff ff       	call   f0100f66 <page_alloc>
f01018c1:	89 c3                	mov    %eax,%ebx
f01018c3:	83 c4 10             	add    $0x10,%esp
f01018c6:	85 c0                	test   %eax,%eax
f01018c8:	75 19                	jne    f01018e3 <mem_init+0x5d7>
f01018ca:	68 28 6a 10 f0       	push   $0xf0106a28
f01018cf:	68 1b 69 10 f0       	push   $0xf010691b
f01018d4:	68 fa 03 00 00       	push   $0x3fa
f01018d9:	68 f5 68 10 f0       	push   $0xf01068f5
f01018de:	e8 5d e7 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01018e3:	83 ec 0c             	sub    $0xc,%esp
f01018e6:	6a 00                	push   $0x0
f01018e8:	e8 79 f6 ff ff       	call   f0100f66 <page_alloc>
f01018ed:	89 c6                	mov    %eax,%esi
f01018ef:	83 c4 10             	add    $0x10,%esp
f01018f2:	85 c0                	test   %eax,%eax
f01018f4:	75 19                	jne    f010190f <mem_init+0x603>
f01018f6:	68 3e 6a 10 f0       	push   $0xf0106a3e
f01018fb:	68 1b 69 10 f0       	push   $0xf010691b
f0101900:	68 fb 03 00 00       	push   $0x3fb
f0101905:	68 f5 68 10 f0       	push   $0xf01068f5
f010190a:	e8 31 e7 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010190f:	39 df                	cmp    %ebx,%edi
f0101911:	75 19                	jne    f010192c <mem_init+0x620>
f0101913:	68 54 6a 10 f0       	push   $0xf0106a54
f0101918:	68 1b 69 10 f0       	push   $0xf010691b
f010191d:	68 fe 03 00 00       	push   $0x3fe
f0101922:	68 f5 68 10 f0       	push   $0xf01068f5
f0101927:	e8 14 e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010192c:	39 c3                	cmp    %eax,%ebx
f010192e:	74 04                	je     f0101934 <mem_init+0x628>
f0101930:	39 c7                	cmp    %eax,%edi
f0101932:	75 19                	jne    f010194d <mem_init+0x641>
f0101934:	68 18 61 10 f0       	push   $0xf0106118
f0101939:	68 1b 69 10 f0       	push   $0xf010691b
f010193e:	68 ff 03 00 00       	push   $0x3ff
f0101943:	68 f5 68 10 f0       	push   $0xf01068f5
f0101948:	e8 f3 e6 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010194d:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
f0101952:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	page_free_list = 0;
f0101955:	c7 05 44 a2 22 f0 00 	movl   $0x0,0xf022a244
f010195c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010195f:	83 ec 0c             	sub    $0xc,%esp
f0101962:	6a 00                	push   $0x0
f0101964:	e8 fd f5 ff ff       	call   f0100f66 <page_alloc>
f0101969:	83 c4 10             	add    $0x10,%esp
f010196c:	85 c0                	test   %eax,%eax
f010196e:	74 19                	je     f0101989 <mem_init+0x67d>
f0101970:	68 bd 6a 10 f0       	push   $0xf0106abd
f0101975:	68 1b 69 10 f0       	push   $0xf010691b
f010197a:	68 06 04 00 00       	push   $0x406
f010197f:	68 f5 68 10 f0       	push   $0xf01068f5
f0101984:	e8 b7 e6 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101989:	83 ec 04             	sub    $0x4,%esp
f010198c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010198f:	50                   	push   %eax
f0101990:	6a 00                	push   $0x0
f0101992:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101998:	e8 c7 f7 ff ff       	call   f0101164 <page_lookup>
f010199d:	83 c4 10             	add    $0x10,%esp
f01019a0:	85 c0                	test   %eax,%eax
f01019a2:	74 19                	je     f01019bd <mem_init+0x6b1>
f01019a4:	68 58 61 10 f0       	push   $0xf0106158
f01019a9:	68 1b 69 10 f0       	push   $0xf010691b
f01019ae:	68 09 04 00 00       	push   $0x409
f01019b3:	68 f5 68 10 f0       	push   $0xf01068f5
f01019b8:	e8 83 e6 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019bd:	6a 02                	push   $0x2
f01019bf:	6a 00                	push   $0x0
f01019c1:	53                   	push   %ebx
f01019c2:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f01019c8:	e8 6f f8 ff ff       	call   f010123c <page_insert>
f01019cd:	83 c4 10             	add    $0x10,%esp
f01019d0:	85 c0                	test   %eax,%eax
f01019d2:	78 19                	js     f01019ed <mem_init+0x6e1>
f01019d4:	68 90 61 10 f0       	push   $0xf0106190
f01019d9:	68 1b 69 10 f0       	push   $0xf010691b
f01019de:	68 0c 04 00 00       	push   $0x40c
f01019e3:	68 f5 68 10 f0       	push   $0xf01068f5
f01019e8:	e8 53 e6 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019ed:	83 ec 0c             	sub    $0xc,%esp
f01019f0:	57                   	push   %edi
f01019f1:	e8 f6 f5 ff ff       	call   f0100fec <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019f6:	6a 02                	push   $0x2
f01019f8:	6a 00                	push   $0x0
f01019fa:	53                   	push   %ebx
f01019fb:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101a01:	e8 36 f8 ff ff       	call   f010123c <page_insert>
f0101a06:	83 c4 20             	add    $0x20,%esp
f0101a09:	85 c0                	test   %eax,%eax
f0101a0b:	74 19                	je     f0101a26 <mem_init+0x71a>
f0101a0d:	68 c0 61 10 f0       	push   $0xf01061c0
f0101a12:	68 1b 69 10 f0       	push   $0xf010691b
f0101a17:	68 10 04 00 00       	push   $0x410
f0101a1c:	68 f5 68 10 f0       	push   $0xf01068f5
f0101a21:	e8 1a e6 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a26:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0101a2b:	8b 08                	mov    (%eax),%ecx
f0101a2d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101a33:	89 fa                	mov    %edi,%edx
f0101a35:	2b 15 10 af 22 f0    	sub    0xf022af10,%edx
f0101a3b:	c1 fa 03             	sar    $0x3,%edx
f0101a3e:	c1 e2 0c             	shl    $0xc,%edx
f0101a41:	39 d1                	cmp    %edx,%ecx
f0101a43:	74 19                	je     f0101a5e <mem_init+0x752>
f0101a45:	68 f0 61 10 f0       	push   $0xf01061f0
f0101a4a:	68 1b 69 10 f0       	push   $0xf010691b
f0101a4f:	68 11 04 00 00       	push   $0x411
f0101a54:	68 f5 68 10 f0       	push   $0xf01068f5
f0101a59:	e8 e2 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a5e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a63:	e8 36 f0 ff ff       	call   f0100a9e <check_va2pa>
f0101a68:	89 da                	mov    %ebx,%edx
f0101a6a:	2b 15 10 af 22 f0    	sub    0xf022af10,%edx
f0101a70:	c1 fa 03             	sar    $0x3,%edx
f0101a73:	c1 e2 0c             	shl    $0xc,%edx
f0101a76:	39 d0                	cmp    %edx,%eax
f0101a78:	74 19                	je     f0101a93 <mem_init+0x787>
f0101a7a:	68 18 62 10 f0       	push   $0xf0106218
f0101a7f:	68 1b 69 10 f0       	push   $0xf010691b
f0101a84:	68 12 04 00 00       	push   $0x412
f0101a89:	68 f5 68 10 f0       	push   $0xf01068f5
f0101a8e:	e8 ad e5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101a93:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a98:	74 19                	je     f0101ab3 <mem_init+0x7a7>
f0101a9a:	68 0f 6b 10 f0       	push   $0xf0106b0f
f0101a9f:	68 1b 69 10 f0       	push   $0xf010691b
f0101aa4:	68 13 04 00 00       	push   $0x413
f0101aa9:	68 f5 68 10 f0       	push   $0xf01068f5
f0101aae:	e8 8d e5 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101ab3:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101ab8:	74 19                	je     f0101ad3 <mem_init+0x7c7>
f0101aba:	68 20 6b 10 f0       	push   $0xf0106b20
f0101abf:	68 1b 69 10 f0       	push   $0xf010691b
f0101ac4:	68 14 04 00 00       	push   $0x414
f0101ac9:	68 f5 68 10 f0       	push   $0xf01068f5
f0101ace:	e8 6d e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ad3:	6a 02                	push   $0x2
f0101ad5:	68 00 10 00 00       	push   $0x1000
f0101ada:	56                   	push   %esi
f0101adb:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101ae1:	e8 56 f7 ff ff       	call   f010123c <page_insert>
f0101ae6:	83 c4 10             	add    $0x10,%esp
f0101ae9:	85 c0                	test   %eax,%eax
f0101aeb:	74 19                	je     f0101b06 <mem_init+0x7fa>
f0101aed:	68 48 62 10 f0       	push   $0xf0106248
f0101af2:	68 1b 69 10 f0       	push   $0xf010691b
f0101af7:	68 17 04 00 00       	push   $0x417
f0101afc:	68 f5 68 10 f0       	push   $0xf01068f5
f0101b01:	e8 3a e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b06:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b0b:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0101b10:	e8 89 ef ff ff       	call   f0100a9e <check_va2pa>
f0101b15:	89 f2                	mov    %esi,%edx
f0101b17:	2b 15 10 af 22 f0    	sub    0xf022af10,%edx
f0101b1d:	c1 fa 03             	sar    $0x3,%edx
f0101b20:	c1 e2 0c             	shl    $0xc,%edx
f0101b23:	39 d0                	cmp    %edx,%eax
f0101b25:	74 19                	je     f0101b40 <mem_init+0x834>
f0101b27:	68 84 62 10 f0       	push   $0xf0106284
f0101b2c:	68 1b 69 10 f0       	push   $0xf010691b
f0101b31:	68 18 04 00 00       	push   $0x418
f0101b36:	68 f5 68 10 f0       	push   $0xf01068f5
f0101b3b:	e8 00 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b40:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b45:	74 19                	je     f0101b60 <mem_init+0x854>
f0101b47:	68 31 6b 10 f0       	push   $0xf0106b31
f0101b4c:	68 1b 69 10 f0       	push   $0xf010691b
f0101b51:	68 19 04 00 00       	push   $0x419
f0101b56:	68 f5 68 10 f0       	push   $0xf01068f5
f0101b5b:	e8 e0 e4 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b60:	83 ec 0c             	sub    $0xc,%esp
f0101b63:	6a 00                	push   $0x0
f0101b65:	e8 fc f3 ff ff       	call   f0100f66 <page_alloc>
f0101b6a:	83 c4 10             	add    $0x10,%esp
f0101b6d:	85 c0                	test   %eax,%eax
f0101b6f:	74 19                	je     f0101b8a <mem_init+0x87e>
f0101b71:	68 bd 6a 10 f0       	push   $0xf0106abd
f0101b76:	68 1b 69 10 f0       	push   $0xf010691b
f0101b7b:	68 1c 04 00 00       	push   $0x41c
f0101b80:	68 f5 68 10 f0       	push   $0xf01068f5
f0101b85:	e8 b6 e4 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b8a:	6a 02                	push   $0x2
f0101b8c:	68 00 10 00 00       	push   $0x1000
f0101b91:	56                   	push   %esi
f0101b92:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101b98:	e8 9f f6 ff ff       	call   f010123c <page_insert>
f0101b9d:	83 c4 10             	add    $0x10,%esp
f0101ba0:	85 c0                	test   %eax,%eax
f0101ba2:	74 19                	je     f0101bbd <mem_init+0x8b1>
f0101ba4:	68 48 62 10 f0       	push   $0xf0106248
f0101ba9:	68 1b 69 10 f0       	push   $0xf010691b
f0101bae:	68 1f 04 00 00       	push   $0x41f
f0101bb3:	68 f5 68 10 f0       	push   $0xf01068f5
f0101bb8:	e8 83 e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bbd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bc2:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0101bc7:	e8 d2 ee ff ff       	call   f0100a9e <check_va2pa>
f0101bcc:	89 f2                	mov    %esi,%edx
f0101bce:	2b 15 10 af 22 f0    	sub    0xf022af10,%edx
f0101bd4:	c1 fa 03             	sar    $0x3,%edx
f0101bd7:	c1 e2 0c             	shl    $0xc,%edx
f0101bda:	39 d0                	cmp    %edx,%eax
f0101bdc:	74 19                	je     f0101bf7 <mem_init+0x8eb>
f0101bde:	68 84 62 10 f0       	push   $0xf0106284
f0101be3:	68 1b 69 10 f0       	push   $0xf010691b
f0101be8:	68 20 04 00 00       	push   $0x420
f0101bed:	68 f5 68 10 f0       	push   $0xf01068f5
f0101bf2:	e8 49 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101bf7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bfc:	74 19                	je     f0101c17 <mem_init+0x90b>
f0101bfe:	68 31 6b 10 f0       	push   $0xf0106b31
f0101c03:	68 1b 69 10 f0       	push   $0xf010691b
f0101c08:	68 21 04 00 00       	push   $0x421
f0101c0d:	68 f5 68 10 f0       	push   $0xf01068f5
f0101c12:	e8 29 e4 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c17:	83 ec 0c             	sub    $0xc,%esp
f0101c1a:	6a 00                	push   $0x0
f0101c1c:	e8 45 f3 ff ff       	call   f0100f66 <page_alloc>
f0101c21:	83 c4 10             	add    $0x10,%esp
f0101c24:	85 c0                	test   %eax,%eax
f0101c26:	74 19                	je     f0101c41 <mem_init+0x935>
f0101c28:	68 bd 6a 10 f0       	push   $0xf0106abd
f0101c2d:	68 1b 69 10 f0       	push   $0xf010691b
f0101c32:	68 25 04 00 00       	push   $0x425
f0101c37:	68 f5 68 10 f0       	push   $0xf01068f5
f0101c3c:	e8 ff e3 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c41:	8b 15 0c af 22 f0    	mov    0xf022af0c,%edx
f0101c47:	8b 02                	mov    (%edx),%eax
f0101c49:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c4e:	89 c1                	mov    %eax,%ecx
f0101c50:	c1 e9 0c             	shr    $0xc,%ecx
f0101c53:	3b 0d 08 af 22 f0    	cmp    0xf022af08,%ecx
f0101c59:	72 15                	jb     f0101c70 <mem_init+0x964>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101c5b:	50                   	push   %eax
f0101c5c:	68 a4 59 10 f0       	push   $0xf01059a4
f0101c61:	68 28 04 00 00       	push   $0x428
f0101c66:	68 f5 68 10 f0       	push   $0xf01068f5
f0101c6b:	e8 d0 e3 ff ff       	call   f0100040 <_panic>
f0101c70:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c75:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c78:	83 ec 04             	sub    $0x4,%esp
f0101c7b:	6a 00                	push   $0x0
f0101c7d:	68 00 10 00 00       	push   $0x1000
f0101c82:	52                   	push   %edx
f0101c83:	e8 b0 f3 ff ff       	call   f0101038 <pgdir_walk>
f0101c88:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101c8b:	8d 51 04             	lea    0x4(%ecx),%edx
f0101c8e:	83 c4 10             	add    $0x10,%esp
f0101c91:	39 d0                	cmp    %edx,%eax
f0101c93:	74 19                	je     f0101cae <mem_init+0x9a2>
f0101c95:	68 b4 62 10 f0       	push   $0xf01062b4
f0101c9a:	68 1b 69 10 f0       	push   $0xf010691b
f0101c9f:	68 29 04 00 00       	push   $0x429
f0101ca4:	68 f5 68 10 f0       	push   $0xf01068f5
f0101ca9:	e8 92 e3 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101cae:	6a 06                	push   $0x6
f0101cb0:	68 00 10 00 00       	push   $0x1000
f0101cb5:	56                   	push   %esi
f0101cb6:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101cbc:	e8 7b f5 ff ff       	call   f010123c <page_insert>
f0101cc1:	83 c4 10             	add    $0x10,%esp
f0101cc4:	85 c0                	test   %eax,%eax
f0101cc6:	74 19                	je     f0101ce1 <mem_init+0x9d5>
f0101cc8:	68 f4 62 10 f0       	push   $0xf01062f4
f0101ccd:	68 1b 69 10 f0       	push   $0xf010691b
f0101cd2:	68 2c 04 00 00       	push   $0x42c
f0101cd7:	68 f5 68 10 f0       	push   $0xf01068f5
f0101cdc:	e8 5f e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ce1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ce6:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0101ceb:	e8 ae ed ff ff       	call   f0100a9e <check_va2pa>
f0101cf0:	89 f2                	mov    %esi,%edx
f0101cf2:	2b 15 10 af 22 f0    	sub    0xf022af10,%edx
f0101cf8:	c1 fa 03             	sar    $0x3,%edx
f0101cfb:	c1 e2 0c             	shl    $0xc,%edx
f0101cfe:	39 d0                	cmp    %edx,%eax
f0101d00:	74 19                	je     f0101d1b <mem_init+0xa0f>
f0101d02:	68 84 62 10 f0       	push   $0xf0106284
f0101d07:	68 1b 69 10 f0       	push   $0xf010691b
f0101d0c:	68 2d 04 00 00       	push   $0x42d
f0101d11:	68 f5 68 10 f0       	push   $0xf01068f5
f0101d16:	e8 25 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101d1b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d20:	74 19                	je     f0101d3b <mem_init+0xa2f>
f0101d22:	68 31 6b 10 f0       	push   $0xf0106b31
f0101d27:	68 1b 69 10 f0       	push   $0xf010691b
f0101d2c:	68 2e 04 00 00       	push   $0x42e
f0101d31:	68 f5 68 10 f0       	push   $0xf01068f5
f0101d36:	e8 05 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d3b:	83 ec 04             	sub    $0x4,%esp
f0101d3e:	6a 00                	push   $0x0
f0101d40:	68 00 10 00 00       	push   $0x1000
f0101d45:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101d4b:	e8 e8 f2 ff ff       	call   f0101038 <pgdir_walk>
f0101d50:	83 c4 10             	add    $0x10,%esp
f0101d53:	f6 00 04             	testb  $0x4,(%eax)
f0101d56:	75 19                	jne    f0101d71 <mem_init+0xa65>
f0101d58:	68 34 63 10 f0       	push   $0xf0106334
f0101d5d:	68 1b 69 10 f0       	push   $0xf010691b
f0101d62:	68 2f 04 00 00       	push   $0x42f
f0101d67:	68 f5 68 10 f0       	push   $0xf01068f5
f0101d6c:	e8 cf e2 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d71:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0101d76:	f6 00 04             	testb  $0x4,(%eax)
f0101d79:	75 19                	jne    f0101d94 <mem_init+0xa88>
f0101d7b:	68 42 6b 10 f0       	push   $0xf0106b42
f0101d80:	68 1b 69 10 f0       	push   $0xf010691b
f0101d85:	68 30 04 00 00       	push   $0x430
f0101d8a:	68 f5 68 10 f0       	push   $0xf01068f5
f0101d8f:	e8 ac e2 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d94:	6a 02                	push   $0x2
f0101d96:	68 00 10 00 00       	push   $0x1000
f0101d9b:	56                   	push   %esi
f0101d9c:	50                   	push   %eax
f0101d9d:	e8 9a f4 ff ff       	call   f010123c <page_insert>
f0101da2:	83 c4 10             	add    $0x10,%esp
f0101da5:	85 c0                	test   %eax,%eax
f0101da7:	74 19                	je     f0101dc2 <mem_init+0xab6>
f0101da9:	68 48 62 10 f0       	push   $0xf0106248
f0101dae:	68 1b 69 10 f0       	push   $0xf010691b
f0101db3:	68 33 04 00 00       	push   $0x433
f0101db8:	68 f5 68 10 f0       	push   $0xf01068f5
f0101dbd:	e8 7e e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101dc2:	83 ec 04             	sub    $0x4,%esp
f0101dc5:	6a 00                	push   $0x0
f0101dc7:	68 00 10 00 00       	push   $0x1000
f0101dcc:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101dd2:	e8 61 f2 ff ff       	call   f0101038 <pgdir_walk>
f0101dd7:	83 c4 10             	add    $0x10,%esp
f0101dda:	f6 00 02             	testb  $0x2,(%eax)
f0101ddd:	75 19                	jne    f0101df8 <mem_init+0xaec>
f0101ddf:	68 68 63 10 f0       	push   $0xf0106368
f0101de4:	68 1b 69 10 f0       	push   $0xf010691b
f0101de9:	68 34 04 00 00       	push   $0x434
f0101dee:	68 f5 68 10 f0       	push   $0xf01068f5
f0101df3:	e8 48 e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101df8:	83 ec 04             	sub    $0x4,%esp
f0101dfb:	6a 00                	push   $0x0
f0101dfd:	68 00 10 00 00       	push   $0x1000
f0101e02:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101e08:	e8 2b f2 ff ff       	call   f0101038 <pgdir_walk>
f0101e0d:	83 c4 10             	add    $0x10,%esp
f0101e10:	f6 00 04             	testb  $0x4,(%eax)
f0101e13:	74 19                	je     f0101e2e <mem_init+0xb22>
f0101e15:	68 9c 63 10 f0       	push   $0xf010639c
f0101e1a:	68 1b 69 10 f0       	push   $0xf010691b
f0101e1f:	68 35 04 00 00       	push   $0x435
f0101e24:	68 f5 68 10 f0       	push   $0xf01068f5
f0101e29:	e8 12 e2 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e2e:	6a 02                	push   $0x2
f0101e30:	68 00 00 40 00       	push   $0x400000
f0101e35:	57                   	push   %edi
f0101e36:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101e3c:	e8 fb f3 ff ff       	call   f010123c <page_insert>
f0101e41:	83 c4 10             	add    $0x10,%esp
f0101e44:	85 c0                	test   %eax,%eax
f0101e46:	78 19                	js     f0101e61 <mem_init+0xb55>
f0101e48:	68 d4 63 10 f0       	push   $0xf01063d4
f0101e4d:	68 1b 69 10 f0       	push   $0xf010691b
f0101e52:	68 38 04 00 00       	push   $0x438
f0101e57:	68 f5 68 10 f0       	push   $0xf01068f5
f0101e5c:	e8 df e1 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e61:	6a 02                	push   $0x2
f0101e63:	68 00 10 00 00       	push   $0x1000
f0101e68:	53                   	push   %ebx
f0101e69:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101e6f:	e8 c8 f3 ff ff       	call   f010123c <page_insert>
f0101e74:	83 c4 10             	add    $0x10,%esp
f0101e77:	85 c0                	test   %eax,%eax
f0101e79:	74 19                	je     f0101e94 <mem_init+0xb88>
f0101e7b:	68 0c 64 10 f0       	push   $0xf010640c
f0101e80:	68 1b 69 10 f0       	push   $0xf010691b
f0101e85:	68 3b 04 00 00       	push   $0x43b
f0101e8a:	68 f5 68 10 f0       	push   $0xf01068f5
f0101e8f:	e8 ac e1 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e94:	83 ec 04             	sub    $0x4,%esp
f0101e97:	6a 00                	push   $0x0
f0101e99:	68 00 10 00 00       	push   $0x1000
f0101e9e:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101ea4:	e8 8f f1 ff ff       	call   f0101038 <pgdir_walk>
f0101ea9:	83 c4 10             	add    $0x10,%esp
f0101eac:	f6 00 04             	testb  $0x4,(%eax)
f0101eaf:	74 19                	je     f0101eca <mem_init+0xbbe>
f0101eb1:	68 9c 63 10 f0       	push   $0xf010639c
f0101eb6:	68 1b 69 10 f0       	push   $0xf010691b
f0101ebb:	68 3c 04 00 00       	push   $0x43c
f0101ec0:	68 f5 68 10 f0       	push   $0xf01068f5
f0101ec5:	e8 76 e1 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101eca:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ecf:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0101ed4:	e8 c5 eb ff ff       	call   f0100a9e <check_va2pa>
f0101ed9:	89 da                	mov    %ebx,%edx
f0101edb:	2b 15 10 af 22 f0    	sub    0xf022af10,%edx
f0101ee1:	c1 fa 03             	sar    $0x3,%edx
f0101ee4:	c1 e2 0c             	shl    $0xc,%edx
f0101ee7:	39 d0                	cmp    %edx,%eax
f0101ee9:	74 19                	je     f0101f04 <mem_init+0xbf8>
f0101eeb:	68 48 64 10 f0       	push   $0xf0106448
f0101ef0:	68 1b 69 10 f0       	push   $0xf010691b
f0101ef5:	68 3f 04 00 00       	push   $0x43f
f0101efa:	68 f5 68 10 f0       	push   $0xf01068f5
f0101eff:	e8 3c e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f04:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f09:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0101f0e:	e8 8b eb ff ff       	call   f0100a9e <check_va2pa>
f0101f13:	89 da                	mov    %ebx,%edx
f0101f15:	2b 15 10 af 22 f0    	sub    0xf022af10,%edx
f0101f1b:	c1 fa 03             	sar    $0x3,%edx
f0101f1e:	c1 e2 0c             	shl    $0xc,%edx
f0101f21:	39 d0                	cmp    %edx,%eax
f0101f23:	74 19                	je     f0101f3e <mem_init+0xc32>
f0101f25:	68 74 64 10 f0       	push   $0xf0106474
f0101f2a:	68 1b 69 10 f0       	push   $0xf010691b
f0101f2f:	68 40 04 00 00       	push   $0x440
f0101f34:	68 f5 68 10 f0       	push   $0xf01068f5
f0101f39:	e8 02 e1 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101f3e:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101f43:	74 19                	je     f0101f5e <mem_init+0xc52>
f0101f45:	68 58 6b 10 f0       	push   $0xf0106b58
f0101f4a:	68 1b 69 10 f0       	push   $0xf010691b
f0101f4f:	68 42 04 00 00       	push   $0x442
f0101f54:	68 f5 68 10 f0       	push   $0xf01068f5
f0101f59:	e8 e2 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101f5e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f63:	74 19                	je     f0101f7e <mem_init+0xc72>
f0101f65:	68 69 6b 10 f0       	push   $0xf0106b69
f0101f6a:	68 1b 69 10 f0       	push   $0xf010691b
f0101f6f:	68 43 04 00 00       	push   $0x443
f0101f74:	68 f5 68 10 f0       	push   $0xf01068f5
f0101f79:	e8 c2 e0 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101f7e:	83 ec 0c             	sub    $0xc,%esp
f0101f81:	6a 00                	push   $0x0
f0101f83:	e8 de ef ff ff       	call   f0100f66 <page_alloc>
f0101f88:	83 c4 10             	add    $0x10,%esp
f0101f8b:	85 c0                	test   %eax,%eax
f0101f8d:	74 04                	je     f0101f93 <mem_init+0xc87>
f0101f8f:	39 c6                	cmp    %eax,%esi
f0101f91:	74 19                	je     f0101fac <mem_init+0xca0>
f0101f93:	68 a4 64 10 f0       	push   $0xf01064a4
f0101f98:	68 1b 69 10 f0       	push   $0xf010691b
f0101f9d:	68 46 04 00 00       	push   $0x446
f0101fa2:	68 f5 68 10 f0       	push   $0xf01068f5
f0101fa7:	e8 94 e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101fac:	83 ec 08             	sub    $0x8,%esp
f0101faf:	6a 00                	push   $0x0
f0101fb1:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101fb7:	e8 37 f2 ff ff       	call   f01011f3 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101fbc:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fc1:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0101fc6:	e8 d3 ea ff ff       	call   f0100a9e <check_va2pa>
f0101fcb:	83 c4 10             	add    $0x10,%esp
f0101fce:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fd1:	74 19                	je     f0101fec <mem_init+0xce0>
f0101fd3:	68 c8 64 10 f0       	push   $0xf01064c8
f0101fd8:	68 1b 69 10 f0       	push   $0xf010691b
f0101fdd:	68 4a 04 00 00       	push   $0x44a
f0101fe2:	68 f5 68 10 f0       	push   $0xf01068f5
f0101fe7:	e8 54 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101fec:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ff1:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0101ff6:	e8 a3 ea ff ff       	call   f0100a9e <check_va2pa>
f0101ffb:	89 da                	mov    %ebx,%edx
f0101ffd:	2b 15 10 af 22 f0    	sub    0xf022af10,%edx
f0102003:	c1 fa 03             	sar    $0x3,%edx
f0102006:	c1 e2 0c             	shl    $0xc,%edx
f0102009:	39 d0                	cmp    %edx,%eax
f010200b:	74 19                	je     f0102026 <mem_init+0xd1a>
f010200d:	68 74 64 10 f0       	push   $0xf0106474
f0102012:	68 1b 69 10 f0       	push   $0xf010691b
f0102017:	68 4b 04 00 00       	push   $0x44b
f010201c:	68 f5 68 10 f0       	push   $0xf01068f5
f0102021:	e8 1a e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102026:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010202b:	74 19                	je     f0102046 <mem_init+0xd3a>
f010202d:	68 0f 6b 10 f0       	push   $0xf0106b0f
f0102032:	68 1b 69 10 f0       	push   $0xf010691b
f0102037:	68 4c 04 00 00       	push   $0x44c
f010203c:	68 f5 68 10 f0       	push   $0xf01068f5
f0102041:	e8 fa df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102046:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010204b:	74 19                	je     f0102066 <mem_init+0xd5a>
f010204d:	68 69 6b 10 f0       	push   $0xf0106b69
f0102052:	68 1b 69 10 f0       	push   $0xf010691b
f0102057:	68 4d 04 00 00       	push   $0x44d
f010205c:	68 f5 68 10 f0       	push   $0xf01068f5
f0102061:	e8 da df ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102066:	6a 00                	push   $0x0
f0102068:	68 00 10 00 00       	push   $0x1000
f010206d:	53                   	push   %ebx
f010206e:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0102074:	e8 c3 f1 ff ff       	call   f010123c <page_insert>
f0102079:	83 c4 10             	add    $0x10,%esp
f010207c:	85 c0                	test   %eax,%eax
f010207e:	74 19                	je     f0102099 <mem_init+0xd8d>
f0102080:	68 ec 64 10 f0       	push   $0xf01064ec
f0102085:	68 1b 69 10 f0       	push   $0xf010691b
f010208a:	68 50 04 00 00       	push   $0x450
f010208f:	68 f5 68 10 f0       	push   $0xf01068f5
f0102094:	e8 a7 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0102099:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010209e:	75 19                	jne    f01020b9 <mem_init+0xdad>
f01020a0:	68 7a 6b 10 f0       	push   $0xf0106b7a
f01020a5:	68 1b 69 10 f0       	push   $0xf010691b
f01020aa:	68 51 04 00 00       	push   $0x451
f01020af:	68 f5 68 10 f0       	push   $0xf01068f5
f01020b4:	e8 87 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f01020b9:	83 3b 00             	cmpl   $0x0,(%ebx)
f01020bc:	74 19                	je     f01020d7 <mem_init+0xdcb>
f01020be:	68 86 6b 10 f0       	push   $0xf0106b86
f01020c3:	68 1b 69 10 f0       	push   $0xf010691b
f01020c8:	68 52 04 00 00       	push   $0x452
f01020cd:	68 f5 68 10 f0       	push   $0xf01068f5
f01020d2:	e8 69 df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01020d7:	83 ec 08             	sub    $0x8,%esp
f01020da:	68 00 10 00 00       	push   $0x1000
f01020df:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f01020e5:	e8 09 f1 ff ff       	call   f01011f3 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01020ea:	ba 00 00 00 00       	mov    $0x0,%edx
f01020ef:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f01020f4:	e8 a5 e9 ff ff       	call   f0100a9e <check_va2pa>
f01020f9:	83 c4 10             	add    $0x10,%esp
f01020fc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020ff:	74 19                	je     f010211a <mem_init+0xe0e>
f0102101:	68 c8 64 10 f0       	push   $0xf01064c8
f0102106:	68 1b 69 10 f0       	push   $0xf010691b
f010210b:	68 56 04 00 00       	push   $0x456
f0102110:	68 f5 68 10 f0       	push   $0xf01068f5
f0102115:	e8 26 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010211a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010211f:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0102124:	e8 75 e9 ff ff       	call   f0100a9e <check_va2pa>
f0102129:	83 f8 ff             	cmp    $0xffffffff,%eax
f010212c:	74 19                	je     f0102147 <mem_init+0xe3b>
f010212e:	68 24 65 10 f0       	push   $0xf0106524
f0102133:	68 1b 69 10 f0       	push   $0xf010691b
f0102138:	68 57 04 00 00       	push   $0x457
f010213d:	68 f5 68 10 f0       	push   $0xf01068f5
f0102142:	e8 f9 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102147:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010214c:	74 19                	je     f0102167 <mem_init+0xe5b>
f010214e:	68 9b 6b 10 f0       	push   $0xf0106b9b
f0102153:	68 1b 69 10 f0       	push   $0xf010691b
f0102158:	68 58 04 00 00       	push   $0x458
f010215d:	68 f5 68 10 f0       	push   $0xf01068f5
f0102162:	e8 d9 de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102167:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010216c:	74 19                	je     f0102187 <mem_init+0xe7b>
f010216e:	68 69 6b 10 f0       	push   $0xf0106b69
f0102173:	68 1b 69 10 f0       	push   $0xf010691b
f0102178:	68 59 04 00 00       	push   $0x459
f010217d:	68 f5 68 10 f0       	push   $0xf01068f5
f0102182:	e8 b9 de ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102187:	83 ec 0c             	sub    $0xc,%esp
f010218a:	6a 00                	push   $0x0
f010218c:	e8 d5 ed ff ff       	call   f0100f66 <page_alloc>
f0102191:	83 c4 10             	add    $0x10,%esp
f0102194:	39 c3                	cmp    %eax,%ebx
f0102196:	75 04                	jne    f010219c <mem_init+0xe90>
f0102198:	85 c0                	test   %eax,%eax
f010219a:	75 19                	jne    f01021b5 <mem_init+0xea9>
f010219c:	68 4c 65 10 f0       	push   $0xf010654c
f01021a1:	68 1b 69 10 f0       	push   $0xf010691b
f01021a6:	68 5c 04 00 00       	push   $0x45c
f01021ab:	68 f5 68 10 f0       	push   $0xf01068f5
f01021b0:	e8 8b de ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01021b5:	83 ec 0c             	sub    $0xc,%esp
f01021b8:	6a 00                	push   $0x0
f01021ba:	e8 a7 ed ff ff       	call   f0100f66 <page_alloc>
f01021bf:	83 c4 10             	add    $0x10,%esp
f01021c2:	85 c0                	test   %eax,%eax
f01021c4:	74 19                	je     f01021df <mem_init+0xed3>
f01021c6:	68 bd 6a 10 f0       	push   $0xf0106abd
f01021cb:	68 1b 69 10 f0       	push   $0xf010691b
f01021d0:	68 5f 04 00 00       	push   $0x45f
f01021d5:	68 f5 68 10 f0       	push   $0xf01068f5
f01021da:	e8 61 de ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01021df:	8b 0d 0c af 22 f0    	mov    0xf022af0c,%ecx
f01021e5:	8b 11                	mov    (%ecx),%edx
f01021e7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01021ed:	89 f8                	mov    %edi,%eax
f01021ef:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f01021f5:	c1 f8 03             	sar    $0x3,%eax
f01021f8:	c1 e0 0c             	shl    $0xc,%eax
f01021fb:	39 c2                	cmp    %eax,%edx
f01021fd:	74 19                	je     f0102218 <mem_init+0xf0c>
f01021ff:	68 f0 61 10 f0       	push   $0xf01061f0
f0102204:	68 1b 69 10 f0       	push   $0xf010691b
f0102209:	68 62 04 00 00       	push   $0x462
f010220e:	68 f5 68 10 f0       	push   $0xf01068f5
f0102213:	e8 28 de ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102218:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010221e:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102223:	74 19                	je     f010223e <mem_init+0xf32>
f0102225:	68 20 6b 10 f0       	push   $0xf0106b20
f010222a:	68 1b 69 10 f0       	push   $0xf010691b
f010222f:	68 64 04 00 00       	push   $0x464
f0102234:	68 f5 68 10 f0       	push   $0xf01068f5
f0102239:	e8 02 de ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f010223e:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102244:	83 ec 0c             	sub    $0xc,%esp
f0102247:	57                   	push   %edi
f0102248:	e8 9f ed ff ff       	call   f0100fec <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010224d:	83 c4 0c             	add    $0xc,%esp
f0102250:	6a 01                	push   $0x1
f0102252:	68 00 10 40 00       	push   $0x401000
f0102257:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f010225d:	e8 d6 ed ff ff       	call   f0101038 <pgdir_walk>
f0102262:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102265:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102268:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f010226d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102270:	8b 40 04             	mov    0x4(%eax),%eax
f0102273:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102278:	8b 0d 08 af 22 f0    	mov    0xf022af08,%ecx
f010227e:	89 c2                	mov    %eax,%edx
f0102280:	c1 ea 0c             	shr    $0xc,%edx
f0102283:	83 c4 10             	add    $0x10,%esp
f0102286:	39 ca                	cmp    %ecx,%edx
f0102288:	72 15                	jb     f010229f <mem_init+0xf93>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010228a:	50                   	push   %eax
f010228b:	68 a4 59 10 f0       	push   $0xf01059a4
f0102290:	68 6b 04 00 00       	push   $0x46b
f0102295:	68 f5 68 10 f0       	push   $0xf01068f5
f010229a:	e8 a1 dd ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010229f:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f01022a4:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01022a7:	74 19                	je     f01022c2 <mem_init+0xfb6>
f01022a9:	68 ac 6b 10 f0       	push   $0xf0106bac
f01022ae:	68 1b 69 10 f0       	push   $0xf010691b
f01022b3:	68 6c 04 00 00       	push   $0x46c
f01022b8:	68 f5 68 10 f0       	push   $0xf01068f5
f01022bd:	e8 7e dd ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01022c2:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01022c5:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01022cc:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01022d2:	89 f8                	mov    %edi,%eax
f01022d4:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f01022da:	c1 f8 03             	sar    $0x3,%eax
f01022dd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022e0:	89 c2                	mov    %eax,%edx
f01022e2:	c1 ea 0c             	shr    $0xc,%edx
f01022e5:	39 d1                	cmp    %edx,%ecx
f01022e7:	77 12                	ja     f01022fb <mem_init+0xfef>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022e9:	50                   	push   %eax
f01022ea:	68 a4 59 10 f0       	push   $0xf01059a4
f01022ef:	6a 58                	push   $0x58
f01022f1:	68 01 69 10 f0       	push   $0xf0106901
f01022f6:	e8 45 dd ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01022fb:	83 ec 04             	sub    $0x4,%esp
f01022fe:	68 00 10 00 00       	push   $0x1000
f0102303:	68 ff 00 00 00       	push   $0xff
f0102308:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010230d:	50                   	push   %eax
f010230e:	e8 b0 29 00 00       	call   f0104cc3 <memset>
	page_free(pp0);
f0102313:	89 3c 24             	mov    %edi,(%esp)
f0102316:	e8 d1 ec ff ff       	call   f0100fec <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010231b:	83 c4 0c             	add    $0xc,%esp
f010231e:	6a 01                	push   $0x1
f0102320:	6a 00                	push   $0x0
f0102322:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0102328:	e8 0b ed ff ff       	call   f0101038 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010232d:	89 fa                	mov    %edi,%edx
f010232f:	2b 15 10 af 22 f0    	sub    0xf022af10,%edx
f0102335:	c1 fa 03             	sar    $0x3,%edx
f0102338:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010233b:	89 d0                	mov    %edx,%eax
f010233d:	c1 e8 0c             	shr    $0xc,%eax
f0102340:	83 c4 10             	add    $0x10,%esp
f0102343:	3b 05 08 af 22 f0    	cmp    0xf022af08,%eax
f0102349:	72 12                	jb     f010235d <mem_init+0x1051>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010234b:	52                   	push   %edx
f010234c:	68 a4 59 10 f0       	push   $0xf01059a4
f0102351:	6a 58                	push   $0x58
f0102353:	68 01 69 10 f0       	push   $0xf0106901
f0102358:	e8 e3 dc ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010235d:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102363:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102366:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010236c:	f6 00 01             	testb  $0x1,(%eax)
f010236f:	74 19                	je     f010238a <mem_init+0x107e>
f0102371:	68 c4 6b 10 f0       	push   $0xf0106bc4
f0102376:	68 1b 69 10 f0       	push   $0xf010691b
f010237b:	68 76 04 00 00       	push   $0x476
f0102380:	68 f5 68 10 f0       	push   $0xf01068f5
f0102385:	e8 b6 dc ff ff       	call   f0100040 <_panic>
f010238a:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010238d:	39 d0                	cmp    %edx,%eax
f010238f:	75 db                	jne    f010236c <mem_init+0x1060>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102391:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0102396:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010239c:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// give free list back
	page_free_list = fl;
f01023a2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023a5:	a3 44 a2 22 f0       	mov    %eax,0xf022a244

	// free the pages we took
	page_free(pp0);
f01023aa:	83 ec 0c             	sub    $0xc,%esp
f01023ad:	57                   	push   %edi
f01023ae:	e8 39 ec ff ff       	call   f0100fec <page_free>
	page_free(pp1);
f01023b3:	89 1c 24             	mov    %ebx,(%esp)
f01023b6:	e8 31 ec ff ff       	call   f0100fec <page_free>
	page_free(pp2);
f01023bb:	89 34 24             	mov    %esi,(%esp)
f01023be:	e8 29 ec ff ff       	call   f0100fec <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f01023c3:	83 c4 08             	add    $0x8,%esp
f01023c6:	68 01 10 00 00       	push   $0x1001
f01023cb:	6a 00                	push   $0x0
f01023cd:	e8 d0 ee ff ff       	call   f01012a2 <mmio_map_region>
f01023d2:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f01023d4:	83 c4 08             	add    $0x8,%esp
f01023d7:	68 00 10 00 00       	push   $0x1000
f01023dc:	6a 00                	push   $0x0
f01023de:	e8 bf ee ff ff       	call   f01012a2 <mmio_map_region>
f01023e3:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f01023e5:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f01023eb:	83 c4 10             	add    $0x10,%esp
f01023ee:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01023f4:	76 07                	jbe    f01023fd <mem_init+0x10f1>
f01023f6:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f01023fb:	76 19                	jbe    f0102416 <mem_init+0x110a>
f01023fd:	68 70 65 10 f0       	push   $0xf0106570
f0102402:	68 1b 69 10 f0       	push   $0xf010691b
f0102407:	68 86 04 00 00       	push   $0x486
f010240c:	68 f5 68 10 f0       	push   $0xf01068f5
f0102411:	e8 2a dc ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102416:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f010241c:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102422:	77 08                	ja     f010242c <mem_init+0x1120>
f0102424:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010242a:	77 19                	ja     f0102445 <mem_init+0x1139>
f010242c:	68 98 65 10 f0       	push   $0xf0106598
f0102431:	68 1b 69 10 f0       	push   $0xf010691b
f0102436:	68 87 04 00 00       	push   $0x487
f010243b:	68 f5 68 10 f0       	push   $0xf01068f5
f0102440:	e8 fb db ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102445:	89 da                	mov    %ebx,%edx
f0102447:	09 f2                	or     %esi,%edx
f0102449:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f010244f:	74 19                	je     f010246a <mem_init+0x115e>
f0102451:	68 c0 65 10 f0       	push   $0xf01065c0
f0102456:	68 1b 69 10 f0       	push   $0xf010691b
f010245b:	68 89 04 00 00       	push   $0x489
f0102460:	68 f5 68 10 f0       	push   $0xf01068f5
f0102465:	e8 d6 db ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f010246a:	39 c6                	cmp    %eax,%esi
f010246c:	73 19                	jae    f0102487 <mem_init+0x117b>
f010246e:	68 db 6b 10 f0       	push   $0xf0106bdb
f0102473:	68 1b 69 10 f0       	push   $0xf010691b
f0102478:	68 8b 04 00 00       	push   $0x48b
f010247d:	68 f5 68 10 f0       	push   $0xf01068f5
f0102482:	e8 b9 db ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102487:	89 da                	mov    %ebx,%edx
f0102489:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f010248e:	e8 0b e6 ff ff       	call   f0100a9e <check_va2pa>
f0102493:	85 c0                	test   %eax,%eax
f0102495:	74 19                	je     f01024b0 <mem_init+0x11a4>
f0102497:	68 e8 65 10 f0       	push   $0xf01065e8
f010249c:	68 1b 69 10 f0       	push   $0xf010691b
f01024a1:	68 8d 04 00 00       	push   $0x48d
f01024a6:	68 f5 68 10 f0       	push   $0xf01068f5
f01024ab:	e8 90 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f01024b0:	8d bb 00 10 00 00    	lea    0x1000(%ebx),%edi
f01024b6:	89 fa                	mov    %edi,%edx
f01024b8:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f01024bd:	e8 dc e5 ff ff       	call   f0100a9e <check_va2pa>
f01024c2:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01024c7:	74 19                	je     f01024e2 <mem_init+0x11d6>
f01024c9:	68 0c 66 10 f0       	push   $0xf010660c
f01024ce:	68 1b 69 10 f0       	push   $0xf010691b
f01024d3:	68 8e 04 00 00       	push   $0x48e
f01024d8:	68 f5 68 10 f0       	push   $0xf01068f5
f01024dd:	e8 5e db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f01024e2:	89 f2                	mov    %esi,%edx
f01024e4:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f01024e9:	e8 b0 e5 ff ff       	call   f0100a9e <check_va2pa>
f01024ee:	85 c0                	test   %eax,%eax
f01024f0:	74 19                	je     f010250b <mem_init+0x11ff>
f01024f2:	68 3c 66 10 f0       	push   $0xf010663c
f01024f7:	68 1b 69 10 f0       	push   $0xf010691b
f01024fc:	68 8f 04 00 00       	push   $0x48f
f0102501:	68 f5 68 10 f0       	push   $0xf01068f5
f0102506:	e8 35 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f010250b:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102511:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0102516:	e8 83 e5 ff ff       	call   f0100a9e <check_va2pa>
f010251b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010251e:	74 19                	je     f0102539 <mem_init+0x122d>
f0102520:	68 60 66 10 f0       	push   $0xf0106660
f0102525:	68 1b 69 10 f0       	push   $0xf010691b
f010252a:	68 90 04 00 00       	push   $0x490
f010252f:	68 f5 68 10 f0       	push   $0xf01068f5
f0102534:	e8 07 db ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102539:	83 ec 04             	sub    $0x4,%esp
f010253c:	6a 00                	push   $0x0
f010253e:	53                   	push   %ebx
f010253f:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0102545:	e8 ee ea ff ff       	call   f0101038 <pgdir_walk>
f010254a:	83 c4 10             	add    $0x10,%esp
f010254d:	f6 00 1a             	testb  $0x1a,(%eax)
f0102550:	75 19                	jne    f010256b <mem_init+0x125f>
f0102552:	68 8c 66 10 f0       	push   $0xf010668c
f0102557:	68 1b 69 10 f0       	push   $0xf010691b
f010255c:	68 92 04 00 00       	push   $0x492
f0102561:	68 f5 68 10 f0       	push   $0xf01068f5
f0102566:	e8 d5 da ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f010256b:	83 ec 04             	sub    $0x4,%esp
f010256e:	6a 00                	push   $0x0
f0102570:	53                   	push   %ebx
f0102571:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0102577:	e8 bc ea ff ff       	call   f0101038 <pgdir_walk>
f010257c:	8b 00                	mov    (%eax),%eax
f010257e:	83 c4 10             	add    $0x10,%esp
f0102581:	83 e0 04             	and    $0x4,%eax
f0102584:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102587:	74 19                	je     f01025a2 <mem_init+0x1296>
f0102589:	68 d0 66 10 f0       	push   $0xf01066d0
f010258e:	68 1b 69 10 f0       	push   $0xf010691b
f0102593:	68 93 04 00 00       	push   $0x493
f0102598:	68 f5 68 10 f0       	push   $0xf01068f5
f010259d:	e8 9e da ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f01025a2:	83 ec 04             	sub    $0x4,%esp
f01025a5:	6a 00                	push   $0x0
f01025a7:	53                   	push   %ebx
f01025a8:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f01025ae:	e8 85 ea ff ff       	call   f0101038 <pgdir_walk>
f01025b3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f01025b9:	83 c4 0c             	add    $0xc,%esp
f01025bc:	6a 00                	push   $0x0
f01025be:	57                   	push   %edi
f01025bf:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f01025c5:	e8 6e ea ff ff       	call   f0101038 <pgdir_walk>
f01025ca:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f01025d0:	83 c4 0c             	add    $0xc,%esp
f01025d3:	6a 00                	push   $0x0
f01025d5:	56                   	push   %esi
f01025d6:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f01025dc:	e8 57 ea ff ff       	call   f0101038 <pgdir_walk>
f01025e1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f01025e7:	c7 04 24 ed 6b 10 f0 	movl   $0xf0106bed,(%esp)
f01025ee:	e8 55 11 00 00       	call   f0103748 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U | PTE_P);
f01025f3:	a1 10 af 22 f0       	mov    0xf022af10,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025f8:	83 c4 10             	add    $0x10,%esp
f01025fb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102600:	77 15                	ja     f0102617 <mem_init+0x130b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102602:	50                   	push   %eax
f0102603:	68 c8 59 10 f0       	push   $0xf01059c8
f0102608:	68 b7 00 00 00       	push   $0xb7
f010260d:	68 f5 68 10 f0       	push   $0xf01068f5
f0102612:	e8 29 da ff ff       	call   f0100040 <_panic>
f0102617:	83 ec 08             	sub    $0x8,%esp
f010261a:	6a 05                	push   $0x5
f010261c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102621:	50                   	push   %eax
f0102622:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102627:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010262c:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0102631:	e8 c6 ea ff ff       	call   f01010fc <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U | PTE_P);
f0102636:	a1 4c a2 22 f0       	mov    0xf022a24c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010263b:	83 c4 10             	add    $0x10,%esp
f010263e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102643:	77 15                	ja     f010265a <mem_init+0x134e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102645:	50                   	push   %eax
f0102646:	68 c8 59 10 f0       	push   $0xf01059c8
f010264b:	68 bf 00 00 00       	push   $0xbf
f0102650:	68 f5 68 10 f0       	push   $0xf01068f5
f0102655:	e8 e6 d9 ff ff       	call   f0100040 <_panic>
f010265a:	83 ec 08             	sub    $0x8,%esp
f010265d:	6a 05                	push   $0x5
f010265f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102664:	50                   	push   %eax
f0102665:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010266a:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010266f:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0102674:	e8 83 ea ff ff       	call   f01010fc <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102679:	83 c4 10             	add    $0x10,%esp
f010267c:	b8 00 50 11 f0       	mov    $0xf0115000,%eax
f0102681:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102686:	77 15                	ja     f010269d <mem_init+0x1391>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102688:	50                   	push   %eax
f0102689:	68 c8 59 10 f0       	push   $0xf01059c8
f010268e:	68 cb 00 00 00       	push   $0xcb
f0102693:	68 f5 68 10 f0       	push   $0xf01068f5
f0102698:	e8 a3 d9 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f010269d:	83 ec 08             	sub    $0x8,%esp
f01026a0:	6a 02                	push   $0x2
f01026a2:	68 00 50 11 00       	push   $0x115000
f01026a7:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026ac:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01026b1:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f01026b6:	e8 41 ea ff ff       	call   f01010fc <boot_map_region>
f01026bb:	c7 45 d4 00 c0 22 f0 	movl   $0xf022c000,-0x2c(%ebp)
f01026c2:	83 c4 10             	add    $0x10,%esp
f01026c5:	bb 00 c0 22 f0       	mov    $0xf022c000,%ebx
f01026ca:	be 00 00 00 f0       	mov    $0xf0000000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026cf:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01026d5:	77 15                	ja     f01026ec <mem_init+0x13e0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026d7:	53                   	push   %ebx
f01026d8:	68 c8 59 10 f0       	push   $0xf01059c8
f01026dd:	68 0b 01 00 00       	push   $0x10b
f01026e2:	68 f5 68 10 f0       	push   $0xf01068f5
f01026e7:	e8 54 d9 ff ff       	call   f0100040 <_panic>
	// LAB 4: Your code here:
	uintptr_t kstacktop_i;
	for(int i = 0;i < NCPU;i++)
	{
		kstacktop_i = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
		boot_map_region(kern_pgdir, kstacktop_i, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W|PTE_P);
f01026ec:	83 ec 08             	sub    $0x8,%esp
f01026ef:	6a 03                	push   $0x3
f01026f1:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f01026f7:	50                   	push   %eax
f01026f8:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026fd:	89 f2                	mov    %esi,%edx
f01026ff:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0102704:	e8 f3 e9 ff ff       	call   f01010fc <boot_map_region>
f0102709:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f010270f:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//             Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	uintptr_t kstacktop_i;
	for(int i = 0;i < NCPU;i++)
f0102715:	83 c4 10             	add    $0x10,%esp
f0102718:	81 fb 00 c0 26 f0    	cmp    $0xf026c000,%ebx
f010271e:	75 af                	jne    f01026cf <mem_init+0x13c3>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102720:	8b 3d 0c af 22 f0    	mov    0xf022af0c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102726:	a1 08 af 22 f0       	mov    0xf022af08,%eax
f010272b:	8d 34 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%esi
f0102732:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for (i = 0; i < n; i += PGSIZE)
f0102738:	bb 00 00 00 00       	mov    $0x0,%ebx
f010273d:	eb 5a                	jmp    f0102799 <mem_init+0x148d>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010273f:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102745:	89 f8                	mov    %edi,%eax
f0102747:	e8 52 e3 ff ff       	call   f0100a9e <check_va2pa>
f010274c:	8b 15 10 af 22 f0    	mov    0xf022af10,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102752:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102758:	77 15                	ja     f010276f <mem_init+0x1463>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010275a:	52                   	push   %edx
f010275b:	68 c8 59 10 f0       	push   $0xf01059c8
f0102760:	68 a2 03 00 00       	push   $0x3a2
f0102765:	68 f5 68 10 f0       	push   $0xf01068f5
f010276a:	e8 d1 d8 ff ff       	call   f0100040 <_panic>
f010276f:	8d 94 1a 00 00 00 10 	lea    0x10000000(%edx,%ebx,1),%edx
f0102776:	39 d0                	cmp    %edx,%eax
f0102778:	74 19                	je     f0102793 <mem_init+0x1487>
f010277a:	68 04 67 10 f0       	push   $0xf0106704
f010277f:	68 1b 69 10 f0       	push   $0xf010691b
f0102784:	68 a2 03 00 00       	push   $0x3a2
f0102789:	68 f5 68 10 f0       	push   $0xf01068f5
f010278e:	e8 ad d8 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102793:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102799:	39 de                	cmp    %ebx,%esi
f010279b:	77 a2                	ja     f010273f <mem_init+0x1433>
f010279d:	bb 00 00 00 00       	mov    $0x0,%ebx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01027a2:	8d 93 00 00 c0 ee    	lea    -0x11400000(%ebx),%edx
f01027a8:	89 f8                	mov    %edi,%eax
f01027aa:	e8 ef e2 ff ff       	call   f0100a9e <check_va2pa>
f01027af:	8b 15 4c a2 22 f0    	mov    0xf022a24c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027b5:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01027bb:	77 15                	ja     f01027d2 <mem_init+0x14c6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027bd:	52                   	push   %edx
f01027be:	68 c8 59 10 f0       	push   $0xf01059c8
f01027c3:	68 a7 03 00 00       	push   $0x3a7
f01027c8:	68 f5 68 10 f0       	push   $0xf01068f5
f01027cd:	e8 6e d8 ff ff       	call   f0100040 <_panic>
f01027d2:	8d 94 1a 00 00 00 10 	lea    0x10000000(%edx,%ebx,1),%edx
f01027d9:	39 d0                	cmp    %edx,%eax
f01027db:	74 19                	je     f01027f6 <mem_init+0x14ea>
f01027dd:	68 38 67 10 f0       	push   $0xf0106738
f01027e2:	68 1b 69 10 f0       	push   $0xf010691b
f01027e7:	68 a7 03 00 00       	push   $0x3a7
f01027ec:	68 f5 68 10 f0       	push   $0xf01068f5
f01027f1:	e8 4a d8 ff ff       	call   f0100040 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01027f6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01027fc:	81 fb 00 f0 01 00    	cmp    $0x1f000,%ebx
f0102802:	75 9e                	jne    f01027a2 <mem_init+0x1496>
f0102804:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102809:	eb 30                	jmp    f010283b <mem_init+0x152f>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010280b:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102811:	89 f8                	mov    %edi,%eax
f0102813:	e8 86 e2 ff ff       	call   f0100a9e <check_va2pa>
f0102818:	39 c3                	cmp    %eax,%ebx
f010281a:	74 19                	je     f0102835 <mem_init+0x1529>
f010281c:	68 6c 67 10 f0       	push   $0xf010676c
f0102821:	68 1b 69 10 f0       	push   $0xf010691b
f0102826:	68 ab 03 00 00       	push   $0x3ab
f010282b:	68 f5 68 10 f0       	push   $0xf01068f5
f0102830:	e8 0b d8 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102835:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010283b:	a1 08 af 22 f0       	mov    0xf022af08,%eax
f0102840:	c1 e0 0c             	shl    $0xc,%eax
f0102843:	39 c3                	cmp    %eax,%ebx
f0102845:	72 c4                	jb     f010280b <mem_init+0x14ff>
f0102847:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f010284c:	89 75 cc             	mov    %esi,-0x34(%ebp)
f010284f:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102852:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102855:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f010285b:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f010285e:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102860:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102863:	05 00 80 00 20       	add    $0x20008000,%eax
f0102868:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010286b:	89 da                	mov    %ebx,%edx
f010286d:	89 f8                	mov    %edi,%eax
f010286f:	e8 2a e2 ff ff       	call   f0100a9e <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102874:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f010287a:	77 15                	ja     f0102891 <mem_init+0x1585>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010287c:	56                   	push   %esi
f010287d:	68 c8 59 10 f0       	push   $0xf01059c8
f0102882:	68 b3 03 00 00       	push   $0x3b3
f0102887:	68 f5 68 10 f0       	push   $0xf01068f5
f010288c:	e8 af d7 ff ff       	call   f0100040 <_panic>
f0102891:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102894:	8d 94 0b 00 c0 22 f0 	lea    -0xfdd4000(%ebx,%ecx,1),%edx
f010289b:	39 d0                	cmp    %edx,%eax
f010289d:	74 19                	je     f01028b8 <mem_init+0x15ac>
f010289f:	68 94 67 10 f0       	push   $0xf0106794
f01028a4:	68 1b 69 10 f0       	push   $0xf010691b
f01028a9:	68 b3 03 00 00       	push   $0x3b3
f01028ae:	68 f5 68 10 f0       	push   $0xf01068f5
f01028b3:	e8 88 d7 ff ff       	call   f0100040 <_panic>
f01028b8:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01028be:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f01028c1:	75 a8                	jne    f010286b <mem_init+0x155f>
f01028c3:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01028c6:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f01028cc:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01028cf:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f01028d1:	89 da                	mov    %ebx,%edx
f01028d3:	89 f8                	mov    %edi,%eax
f01028d5:	e8 c4 e1 ff ff       	call   f0100a9e <check_va2pa>
f01028da:	83 f8 ff             	cmp    $0xffffffff,%eax
f01028dd:	74 19                	je     f01028f8 <mem_init+0x15ec>
f01028df:	68 dc 67 10 f0       	push   $0xf01067dc
f01028e4:	68 1b 69 10 f0       	push   $0xf010691b
f01028e9:	68 b5 03 00 00       	push   $0x3b5
f01028ee:	68 f5 68 10 f0       	push   $0xf01068f5
f01028f3:	e8 48 d7 ff ff       	call   f0100040 <_panic>
f01028f8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f01028fe:	39 f3                	cmp    %esi,%ebx
f0102900:	75 cf                	jne    f01028d1 <mem_init+0x15c5>
f0102902:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102905:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f010290c:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f0102913:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102919:	b8 00 c0 26 f0       	mov    $0xf026c000,%eax
f010291e:	39 f0                	cmp    %esi,%eax
f0102920:	0f 85 2c ff ff ff    	jne    f0102852 <mem_init+0x1546>
f0102926:	b8 00 00 00 00       	mov    $0x0,%eax
f010292b:	eb 2a                	jmp    f0102957 <mem_init+0x164b>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010292d:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102933:	83 fa 04             	cmp    $0x4,%edx
f0102936:	77 1f                	ja     f0102957 <mem_init+0x164b>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102938:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f010293c:	75 7e                	jne    f01029bc <mem_init+0x16b0>
f010293e:	68 06 6c 10 f0       	push   $0xf0106c06
f0102943:	68 1b 69 10 f0       	push   $0xf010691b
f0102948:	68 c0 03 00 00       	push   $0x3c0
f010294d:	68 f5 68 10 f0       	push   $0xf01068f5
f0102952:	e8 e9 d6 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102957:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010295c:	76 3f                	jbe    f010299d <mem_init+0x1691>
				assert(pgdir[i] & PTE_P);
f010295e:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102961:	f6 c2 01             	test   $0x1,%dl
f0102964:	75 19                	jne    f010297f <mem_init+0x1673>
f0102966:	68 06 6c 10 f0       	push   $0xf0106c06
f010296b:	68 1b 69 10 f0       	push   $0xf010691b
f0102970:	68 c4 03 00 00       	push   $0x3c4
f0102975:	68 f5 68 10 f0       	push   $0xf01068f5
f010297a:	e8 c1 d6 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f010297f:	f6 c2 02             	test   $0x2,%dl
f0102982:	75 38                	jne    f01029bc <mem_init+0x16b0>
f0102984:	68 17 6c 10 f0       	push   $0xf0106c17
f0102989:	68 1b 69 10 f0       	push   $0xf010691b
f010298e:	68 c5 03 00 00       	push   $0x3c5
f0102993:	68 f5 68 10 f0       	push   $0xf01068f5
f0102998:	e8 a3 d6 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f010299d:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01029a1:	74 19                	je     f01029bc <mem_init+0x16b0>
f01029a3:	68 28 6c 10 f0       	push   $0xf0106c28
f01029a8:	68 1b 69 10 f0       	push   $0xf010691b
f01029ad:	68 c7 03 00 00       	push   $0x3c7
f01029b2:	68 f5 68 10 f0       	push   $0xf01068f5
f01029b7:	e8 84 d6 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01029bc:	83 c0 01             	add    $0x1,%eax
f01029bf:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01029c4:	0f 86 63 ff ff ff    	jbe    f010292d <mem_init+0x1621>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01029ca:	83 ec 0c             	sub    $0xc,%esp
f01029cd:	68 00 68 10 f0       	push   $0xf0106800
f01029d2:	e8 71 0d 00 00       	call   f0103748 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01029d7:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029dc:	83 c4 10             	add    $0x10,%esp
f01029df:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029e4:	77 15                	ja     f01029fb <mem_init+0x16ef>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029e6:	50                   	push   %eax
f01029e7:	68 c8 59 10 f0       	push   $0xf01059c8
f01029ec:	68 e2 00 00 00       	push   $0xe2
f01029f1:	68 f5 68 10 f0       	push   $0xf01068f5
f01029f6:	e8 45 d6 ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01029fb:	05 00 00 00 10       	add    $0x10000000,%eax
f0102a00:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102a03:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a08:	e8 6e e1 ff ff       	call   f0100b7b <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102a0d:	0f 20 c0             	mov    %cr0,%eax
f0102a10:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102a13:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102a18:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a1b:	83 ec 0c             	sub    $0xc,%esp
f0102a1e:	6a 00                	push   $0x0
f0102a20:	e8 41 e5 ff ff       	call   f0100f66 <page_alloc>
f0102a25:	89 c3                	mov    %eax,%ebx
f0102a27:	83 c4 10             	add    $0x10,%esp
f0102a2a:	85 c0                	test   %eax,%eax
f0102a2c:	75 19                	jne    f0102a47 <mem_init+0x173b>
f0102a2e:	68 12 6a 10 f0       	push   $0xf0106a12
f0102a33:	68 1b 69 10 f0       	push   $0xf010691b
f0102a38:	68 a8 04 00 00       	push   $0x4a8
f0102a3d:	68 f5 68 10 f0       	push   $0xf01068f5
f0102a42:	e8 f9 d5 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102a47:	83 ec 0c             	sub    $0xc,%esp
f0102a4a:	6a 00                	push   $0x0
f0102a4c:	e8 15 e5 ff ff       	call   f0100f66 <page_alloc>
f0102a51:	89 c7                	mov    %eax,%edi
f0102a53:	83 c4 10             	add    $0x10,%esp
f0102a56:	85 c0                	test   %eax,%eax
f0102a58:	75 19                	jne    f0102a73 <mem_init+0x1767>
f0102a5a:	68 28 6a 10 f0       	push   $0xf0106a28
f0102a5f:	68 1b 69 10 f0       	push   $0xf010691b
f0102a64:	68 a9 04 00 00       	push   $0x4a9
f0102a69:	68 f5 68 10 f0       	push   $0xf01068f5
f0102a6e:	e8 cd d5 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102a73:	83 ec 0c             	sub    $0xc,%esp
f0102a76:	6a 00                	push   $0x0
f0102a78:	e8 e9 e4 ff ff       	call   f0100f66 <page_alloc>
f0102a7d:	89 c6                	mov    %eax,%esi
f0102a7f:	83 c4 10             	add    $0x10,%esp
f0102a82:	85 c0                	test   %eax,%eax
f0102a84:	75 19                	jne    f0102a9f <mem_init+0x1793>
f0102a86:	68 3e 6a 10 f0       	push   $0xf0106a3e
f0102a8b:	68 1b 69 10 f0       	push   $0xf010691b
f0102a90:	68 aa 04 00 00       	push   $0x4aa
f0102a95:	68 f5 68 10 f0       	push   $0xf01068f5
f0102a9a:	e8 a1 d5 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102a9f:	83 ec 0c             	sub    $0xc,%esp
f0102aa2:	53                   	push   %ebx
f0102aa3:	e8 44 e5 ff ff       	call   f0100fec <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102aa8:	89 f8                	mov    %edi,%eax
f0102aaa:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f0102ab0:	c1 f8 03             	sar    $0x3,%eax
f0102ab3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ab6:	89 c2                	mov    %eax,%edx
f0102ab8:	c1 ea 0c             	shr    $0xc,%edx
f0102abb:	83 c4 10             	add    $0x10,%esp
f0102abe:	3b 15 08 af 22 f0    	cmp    0xf022af08,%edx
f0102ac4:	72 12                	jb     f0102ad8 <mem_init+0x17cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ac6:	50                   	push   %eax
f0102ac7:	68 a4 59 10 f0       	push   $0xf01059a4
f0102acc:	6a 58                	push   $0x58
f0102ace:	68 01 69 10 f0       	push   $0xf0106901
f0102ad3:	e8 68 d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102ad8:	83 ec 04             	sub    $0x4,%esp
f0102adb:	68 00 10 00 00       	push   $0x1000
f0102ae0:	6a 01                	push   $0x1
f0102ae2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102ae7:	50                   	push   %eax
f0102ae8:	e8 d6 21 00 00       	call   f0104cc3 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102aed:	89 f0                	mov    %esi,%eax
f0102aef:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f0102af5:	c1 f8 03             	sar    $0x3,%eax
f0102af8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102afb:	89 c2                	mov    %eax,%edx
f0102afd:	c1 ea 0c             	shr    $0xc,%edx
f0102b00:	83 c4 10             	add    $0x10,%esp
f0102b03:	3b 15 08 af 22 f0    	cmp    0xf022af08,%edx
f0102b09:	72 12                	jb     f0102b1d <mem_init+0x1811>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b0b:	50                   	push   %eax
f0102b0c:	68 a4 59 10 f0       	push   $0xf01059a4
f0102b11:	6a 58                	push   $0x58
f0102b13:	68 01 69 10 f0       	push   $0xf0106901
f0102b18:	e8 23 d5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102b1d:	83 ec 04             	sub    $0x4,%esp
f0102b20:	68 00 10 00 00       	push   $0x1000
f0102b25:	6a 02                	push   $0x2
f0102b27:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b2c:	50                   	push   %eax
f0102b2d:	e8 91 21 00 00       	call   f0104cc3 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b32:	6a 02                	push   $0x2
f0102b34:	68 00 10 00 00       	push   $0x1000
f0102b39:	57                   	push   %edi
f0102b3a:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0102b40:	e8 f7 e6 ff ff       	call   f010123c <page_insert>
	assert(pp1->pp_ref == 1);
f0102b45:	83 c4 20             	add    $0x20,%esp
f0102b48:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102b4d:	74 19                	je     f0102b68 <mem_init+0x185c>
f0102b4f:	68 0f 6b 10 f0       	push   $0xf0106b0f
f0102b54:	68 1b 69 10 f0       	push   $0xf010691b
f0102b59:	68 af 04 00 00       	push   $0x4af
f0102b5e:	68 f5 68 10 f0       	push   $0xf01068f5
f0102b63:	e8 d8 d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b68:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102b6f:	01 01 01 
f0102b72:	74 19                	je     f0102b8d <mem_init+0x1881>
f0102b74:	68 20 68 10 f0       	push   $0xf0106820
f0102b79:	68 1b 69 10 f0       	push   $0xf010691b
f0102b7e:	68 b0 04 00 00       	push   $0x4b0
f0102b83:	68 f5 68 10 f0       	push   $0xf01068f5
f0102b88:	e8 b3 d4 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b8d:	6a 02                	push   $0x2
f0102b8f:	68 00 10 00 00       	push   $0x1000
f0102b94:	56                   	push   %esi
f0102b95:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0102b9b:	e8 9c e6 ff ff       	call   f010123c <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102ba0:	83 c4 10             	add    $0x10,%esp
f0102ba3:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102baa:	02 02 02 
f0102bad:	74 19                	je     f0102bc8 <mem_init+0x18bc>
f0102baf:	68 44 68 10 f0       	push   $0xf0106844
f0102bb4:	68 1b 69 10 f0       	push   $0xf010691b
f0102bb9:	68 b2 04 00 00       	push   $0x4b2
f0102bbe:	68 f5 68 10 f0       	push   $0xf01068f5
f0102bc3:	e8 78 d4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102bc8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102bcd:	74 19                	je     f0102be8 <mem_init+0x18dc>
f0102bcf:	68 31 6b 10 f0       	push   $0xf0106b31
f0102bd4:	68 1b 69 10 f0       	push   $0xf010691b
f0102bd9:	68 b3 04 00 00       	push   $0x4b3
f0102bde:	68 f5 68 10 f0       	push   $0xf01068f5
f0102be3:	e8 58 d4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102be8:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102bed:	74 19                	je     f0102c08 <mem_init+0x18fc>
f0102bef:	68 9b 6b 10 f0       	push   $0xf0106b9b
f0102bf4:	68 1b 69 10 f0       	push   $0xf010691b
f0102bf9:	68 b4 04 00 00       	push   $0x4b4
f0102bfe:	68 f5 68 10 f0       	push   $0xf01068f5
f0102c03:	e8 38 d4 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c08:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c0f:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c12:	89 f0                	mov    %esi,%eax
f0102c14:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f0102c1a:	c1 f8 03             	sar    $0x3,%eax
f0102c1d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c20:	89 c2                	mov    %eax,%edx
f0102c22:	c1 ea 0c             	shr    $0xc,%edx
f0102c25:	3b 15 08 af 22 f0    	cmp    0xf022af08,%edx
f0102c2b:	72 12                	jb     f0102c3f <mem_init+0x1933>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c2d:	50                   	push   %eax
f0102c2e:	68 a4 59 10 f0       	push   $0xf01059a4
f0102c33:	6a 58                	push   $0x58
f0102c35:	68 01 69 10 f0       	push   $0xf0106901
f0102c3a:	e8 01 d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102c3f:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102c46:	03 03 03 
f0102c49:	74 19                	je     f0102c64 <mem_init+0x1958>
f0102c4b:	68 68 68 10 f0       	push   $0xf0106868
f0102c50:	68 1b 69 10 f0       	push   $0xf010691b
f0102c55:	68 b6 04 00 00       	push   $0x4b6
f0102c5a:	68 f5 68 10 f0       	push   $0xf01068f5
f0102c5f:	e8 dc d3 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c64:	83 ec 08             	sub    $0x8,%esp
f0102c67:	68 00 10 00 00       	push   $0x1000
f0102c6c:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0102c72:	e8 7c e5 ff ff       	call   f01011f3 <page_remove>
	assert(pp2->pp_ref == 0);
f0102c77:	83 c4 10             	add    $0x10,%esp
f0102c7a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102c7f:	74 19                	je     f0102c9a <mem_init+0x198e>
f0102c81:	68 69 6b 10 f0       	push   $0xf0106b69
f0102c86:	68 1b 69 10 f0       	push   $0xf010691b
f0102c8b:	68 b8 04 00 00       	push   $0x4b8
f0102c90:	68 f5 68 10 f0       	push   $0xf01068f5
f0102c95:	e8 a6 d3 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c9a:	8b 0d 0c af 22 f0    	mov    0xf022af0c,%ecx
f0102ca0:	8b 11                	mov    (%ecx),%edx
f0102ca2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102ca8:	89 d8                	mov    %ebx,%eax
f0102caa:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f0102cb0:	c1 f8 03             	sar    $0x3,%eax
f0102cb3:	c1 e0 0c             	shl    $0xc,%eax
f0102cb6:	39 c2                	cmp    %eax,%edx
f0102cb8:	74 19                	je     f0102cd3 <mem_init+0x19c7>
f0102cba:	68 f0 61 10 f0       	push   $0xf01061f0
f0102cbf:	68 1b 69 10 f0       	push   $0xf010691b
f0102cc4:	68 bb 04 00 00       	push   $0x4bb
f0102cc9:	68 f5 68 10 f0       	push   $0xf01068f5
f0102cce:	e8 6d d3 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102cd3:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102cd9:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102cde:	74 19                	je     f0102cf9 <mem_init+0x19ed>
f0102ce0:	68 20 6b 10 f0       	push   $0xf0106b20
f0102ce5:	68 1b 69 10 f0       	push   $0xf010691b
f0102cea:	68 bd 04 00 00       	push   $0x4bd
f0102cef:	68 f5 68 10 f0       	push   $0xf01068f5
f0102cf4:	e8 47 d3 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102cf9:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102cff:	83 ec 0c             	sub    $0xc,%esp
f0102d02:	53                   	push   %ebx
f0102d03:	e8 e4 e2 ff ff       	call   f0100fec <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102d08:	c7 04 24 94 68 10 f0 	movl   $0xf0106894,(%esp)
f0102d0f:	e8 34 0a 00 00       	call   f0103748 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102d14:	83 c4 10             	add    $0x10,%esp
f0102d17:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d1a:	5b                   	pop    %ebx
f0102d1b:	5e                   	pop    %esi
f0102d1c:	5f                   	pop    %edi
f0102d1d:	5d                   	pop    %ebp
f0102d1e:	c3                   	ret    

f0102d1f <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102d1f:	55                   	push   %ebp
f0102d20:	89 e5                	mov    %esp,%ebp
f0102d22:	57                   	push   %edi
f0102d23:	56                   	push   %esi
f0102d24:	53                   	push   %ebx
f0102d25:	83 ec 1c             	sub    $0x1c,%esp
f0102d28:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102d2b:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	uint32_t start = (uint32_t)ROUNDDOWN(va, PGSIZE);
f0102d2e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d31:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t end = (uint32_t)ROUNDUP(va+len, PGSIZE);
f0102d37:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d3a:	03 45 10             	add    0x10(%ebp),%eax
f0102d3d:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102d42:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102d47:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(uint32_t i = start;i < end;i += PGSIZE)
f0102d4a:	eb 50                	jmp    f0102d9c <user_mem_check+0x7d>
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, (void *)i, 0);
f0102d4c:	83 ec 04             	sub    $0x4,%esp
f0102d4f:	6a 00                	push   $0x0
f0102d51:	53                   	push   %ebx
f0102d52:	ff 77 60             	pushl  0x60(%edi)
f0102d55:	e8 de e2 ff ff       	call   f0101038 <pgdir_walk>
// A user program can access a virtual address if (1) the address is below
// ULIM, and (2) the page table gives it permission. 
		//不满足的条件:1.地址大于ULIM 2.pte不存在 3.pte没有PTE_P的权限位 
		//4.pte的权限比perm高，说明当前权限无法访问对应内存
		if(i >= ULIM || !pte || !(*pte & PTE_P) || (*pte & perm) != perm)
f0102d5a:	83 c4 10             	add    $0x10,%esp
f0102d5d:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102d63:	77 10                	ja     f0102d75 <user_mem_check+0x56>
f0102d65:	85 c0                	test   %eax,%eax
f0102d67:	74 0c                	je     f0102d75 <user_mem_check+0x56>
f0102d69:	8b 00                	mov    (%eax),%eax
f0102d6b:	a8 01                	test   $0x1,%al
f0102d6d:	74 06                	je     f0102d75 <user_mem_check+0x56>
f0102d6f:	21 f0                	and    %esi,%eax
f0102d71:	39 c6                	cmp    %eax,%esi
f0102d73:	74 21                	je     f0102d96 <user_mem_check+0x77>
		{
// If there is an error, set the 'user_mem_check_addr' variable to the first
// erroneous virtual address.
			//如果出错的是va之前的地址，需要返回的也应该是va的地址
			if(i < (uint32_t)va)
f0102d75:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0102d78:	73 0f                	jae    f0102d89 <user_mem_check+0x6a>
				user_mem_check_addr = (uint32_t)va;
f0102d7a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d7d:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
			else 
				user_mem_check_addr = i;
			return -E_FAULT;
f0102d82:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d87:	eb 1d                	jmp    f0102da6 <user_mem_check+0x87>
// erroneous virtual address.
			//如果出错的是va之前的地址，需要返回的也应该是va的地址
			if(i < (uint32_t)va)
				user_mem_check_addr = (uint32_t)va;
			else 
				user_mem_check_addr = i;
f0102d89:	89 1d 40 a2 22 f0    	mov    %ebx,0xf022a240
			return -E_FAULT;
f0102d8f:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102d94:	eb 10                	jmp    f0102da6 <user_mem_check+0x87>
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	uint32_t start = (uint32_t)ROUNDDOWN(va, PGSIZE);
	uint32_t end = (uint32_t)ROUNDUP(va+len, PGSIZE);
	for(uint32_t i = start;i < end;i += PGSIZE)
f0102d96:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102d9c:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102d9f:	72 ab                	jb     f0102d4c <user_mem_check+0x2d>
			else 
				user_mem_check_addr = i;
			return -E_FAULT;
		} 
	}
	return 0;
f0102da1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102da6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102da9:	5b                   	pop    %ebx
f0102daa:	5e                   	pop    %esi
f0102dab:	5f                   	pop    %edi
f0102dac:	5d                   	pop    %ebp
f0102dad:	c3                   	ret    

f0102dae <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102dae:	55                   	push   %ebp
f0102daf:	89 e5                	mov    %esp,%ebp
f0102db1:	53                   	push   %ebx
f0102db2:	83 ec 04             	sub    $0x4,%esp
f0102db5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102db8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dbb:	83 c8 04             	or     $0x4,%eax
f0102dbe:	50                   	push   %eax
f0102dbf:	ff 75 10             	pushl  0x10(%ebp)
f0102dc2:	ff 75 0c             	pushl  0xc(%ebp)
f0102dc5:	53                   	push   %ebx
f0102dc6:	e8 54 ff ff ff       	call   f0102d1f <user_mem_check>
f0102dcb:	83 c4 10             	add    $0x10,%esp
f0102dce:	85 c0                	test   %eax,%eax
f0102dd0:	79 21                	jns    f0102df3 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102dd2:	83 ec 04             	sub    $0x4,%esp
f0102dd5:	ff 35 40 a2 22 f0    	pushl  0xf022a240
f0102ddb:	ff 73 48             	pushl  0x48(%ebx)
f0102dde:	68 c0 68 10 f0       	push   $0xf01068c0
f0102de3:	e8 60 09 00 00       	call   f0103748 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102de8:	89 1c 24             	mov    %ebx,(%esp)
f0102deb:	e8 62 06 00 00       	call   f0103452 <env_destroy>
f0102df0:	83 c4 10             	add    $0x10,%esp
	}
}
f0102df3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102df6:	c9                   	leave  
f0102df7:	c3                   	ret    

f0102df8 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102df8:	55                   	push   %ebp
f0102df9:	89 e5                	mov    %esp,%ebp
f0102dfb:	57                   	push   %edi
f0102dfc:	56                   	push   %esi
f0102dfd:	53                   	push   %ebx
f0102dfe:	83 ec 14             	sub    $0x14,%esp
f0102e01:	89 c7                	mov    %eax,%edi
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	//boot_map_region(e->env_pgdir, va, len, PADDR(envs), PTE_P | PTE_U | PTE_W);
	uint32_t start,end;
	start = ROUNDDOWN((uint32_t)va, PGSIZE);
f0102e03:	89 d3                	mov    %edx,%ebx
f0102e05:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	end = ROUNDUP((uint32_t)(va + len), PGSIZE);
f0102e0b:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102e12:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	cprintf("start=%d \n",start);
f0102e18:	53                   	push   %ebx
f0102e19:	68 36 6c 10 f0       	push   $0xf0106c36
f0102e1e:	e8 25 09 00 00       	call   f0103748 <cprintf>
	cprintf("end=%d \n",end);
f0102e23:	83 c4 08             	add    $0x8,%esp
f0102e26:	56                   	push   %esi
f0102e27:	68 41 6c 10 f0       	push   $0xf0106c41
f0102e2c:	e8 17 09 00 00       	call   f0103748 <cprintf>

	struct PageInfo *Page;
	int r;
	for(int i = start;i < end;i += PGSIZE)
f0102e31:	83 c4 10             	add    $0x10,%esp
f0102e34:	eb 56                	jmp    f0102e8c <region_alloc+0x94>
	{
		Page = page_alloc(0);
f0102e36:	83 ec 0c             	sub    $0xc,%esp
f0102e39:	6a 00                	push   $0x0
f0102e3b:	e8 26 e1 ff ff       	call   f0100f66 <page_alloc>
		if(!Page)
f0102e40:	83 c4 10             	add    $0x10,%esp
f0102e43:	85 c0                	test   %eax,%eax
f0102e45:	75 17                	jne    f0102e5e <region_alloc+0x66>
			panic("page_alloc fail");
f0102e47:	83 ec 04             	sub    $0x4,%esp
f0102e4a:	68 4a 6c 10 f0       	push   $0xf0106c4a
f0102e4f:	68 34 01 00 00       	push   $0x134
f0102e54:	68 5a 6c 10 f0       	push   $0xf0106c5a
f0102e59:	e8 e2 d1 ff ff       	call   f0100040 <_panic>
		//r = page_insert(e->env_pgdir, Page, va, PTE_P | PTE_U | PTE_W);
		r = page_insert(e->env_pgdir, Page, (void *)i, PTE_U | PTE_W);
f0102e5e:	6a 06                	push   $0x6
f0102e60:	53                   	push   %ebx
f0102e61:	50                   	push   %eax
f0102e62:	ff 77 60             	pushl  0x60(%edi)
f0102e65:	e8 d2 e3 ff ff       	call   f010123c <page_insert>
		if(r != 0)
f0102e6a:	83 c4 10             	add    $0x10,%esp
f0102e6d:	85 c0                	test   %eax,%eax
f0102e6f:	74 15                	je     f0102e86 <region_alloc+0x8e>
			panic("region_alloc: %e", r);
f0102e71:	50                   	push   %eax
f0102e72:	68 65 6c 10 f0       	push   $0xf0106c65
f0102e77:	68 38 01 00 00       	push   $0x138
f0102e7c:	68 5a 6c 10 f0       	push   $0xf0106c5a
f0102e81:	e8 ba d1 ff ff       	call   f0100040 <_panic>
	cprintf("start=%d \n",start);
	cprintf("end=%d \n",end);

	struct PageInfo *Page;
	int r;
	for(int i = start;i < end;i += PGSIZE)
f0102e86:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102e8c:	39 de                	cmp    %ebx,%esi
f0102e8e:	77 a6                	ja     f0102e36 <region_alloc+0x3e>
		r = page_insert(e->env_pgdir, Page, (void *)i, PTE_U | PTE_W);
		if(r != 0)
			panic("region_alloc: %e", r);
			//panic("region_alloc fail");
	}
}
f0102e90:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e93:	5b                   	pop    %ebx
f0102e94:	5e                   	pop    %esi
f0102e95:	5f                   	pop    %edi
f0102e96:	5d                   	pop    %ebp
f0102e97:	c3                   	ret    

f0102e98 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102e98:	55                   	push   %ebp
f0102e99:	89 e5                	mov    %esp,%ebp
f0102e9b:	56                   	push   %esi
f0102e9c:	53                   	push   %ebx
f0102e9d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ea0:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102ea3:	85 c0                	test   %eax,%eax
f0102ea5:	75 1a                	jne    f0102ec1 <envid2env+0x29>
		*env_store = curenv;
f0102ea7:	e8 3a 24 00 00       	call   f01052e6 <cpunum>
f0102eac:	6b c0 74             	imul   $0x74,%eax,%eax
f0102eaf:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102eb5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102eb8:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102eba:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ebf:	eb 70                	jmp    f0102f31 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102ec1:	89 c3                	mov    %eax,%ebx
f0102ec3:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102ec9:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102ecc:	03 1d 4c a2 22 f0    	add    0xf022a24c,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102ed2:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102ed6:	74 05                	je     f0102edd <envid2env+0x45>
f0102ed8:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102edb:	74 10                	je     f0102eed <envid2env+0x55>
		*env_store = 0;
f0102edd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ee0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102ee6:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102eeb:	eb 44                	jmp    f0102f31 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102eed:	84 d2                	test   %dl,%dl
f0102eef:	74 36                	je     f0102f27 <envid2env+0x8f>
f0102ef1:	e8 f0 23 00 00       	call   f01052e6 <cpunum>
f0102ef6:	6b c0 74             	imul   $0x74,%eax,%eax
f0102ef9:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f0102eff:	74 26                	je     f0102f27 <envid2env+0x8f>
f0102f01:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102f04:	e8 dd 23 00 00       	call   f01052e6 <cpunum>
f0102f09:	6b c0 74             	imul   $0x74,%eax,%eax
f0102f0c:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102f12:	3b 70 48             	cmp    0x48(%eax),%esi
f0102f15:	74 10                	je     f0102f27 <envid2env+0x8f>
		*env_store = 0;
f0102f17:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f1a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102f20:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102f25:	eb 0a                	jmp    f0102f31 <envid2env+0x99>
	}

	*env_store = e;
f0102f27:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f2a:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102f2c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102f31:	5b                   	pop    %ebx
f0102f32:	5e                   	pop    %esi
f0102f33:	5d                   	pop    %ebp
f0102f34:	c3                   	ret    

f0102f35 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102f35:	55                   	push   %ebp
f0102f36:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102f38:	b8 20 f3 11 f0       	mov    $0xf011f320,%eax
f0102f3d:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102f40:	b8 23 00 00 00       	mov    $0x23,%eax
f0102f45:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102f47:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102f49:	b8 10 00 00 00       	mov    $0x10,%eax
f0102f4e:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102f50:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102f52:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102f54:	ea 5b 2f 10 f0 08 00 	ljmp   $0x8,$0xf0102f5b
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102f5b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f60:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102f63:	5d                   	pop    %ebp
f0102f64:	c3                   	ret    

f0102f65 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102f65:	55                   	push   %ebp
f0102f66:	89 e5                	mov    %esp,%ebp
f0102f68:	56                   	push   %esi
f0102f69:	53                   	push   %ebx
	// LAB 3: Your code here.
	// struct Env* envs;
	// env_free_list = NULL;
	for(int i = NENV - 1;i >= 0;i--)
	{
		envs[i].env_id = 0;
f0102f6a:	8b 35 4c a2 22 f0    	mov    0xf022a24c,%esi
f0102f70:	8b 15 50 a2 22 f0    	mov    0xf022a250,%edx
f0102f76:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102f7c:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102f7f:	89 c1                	mov    %eax,%ecx
f0102f81:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f0102f88:	89 50 44             	mov    %edx,0x44(%eax)
f0102f8b:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];
f0102f8e:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	// struct Env* envs;
	// env_free_list = NULL;
	for(int i = NENV - 1;i >= 0;i--)
f0102f90:	39 d8                	cmp    %ebx,%eax
f0102f92:	75 eb                	jne    f0102f7f <env_init+0x1a>
f0102f94:	89 35 50 a2 22 f0    	mov    %esi,0xf022a250
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
		//envs[i].env_status = 
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f0102f9a:	e8 96 ff ff ff       	call   f0102f35 <env_init_percpu>
}
f0102f9f:	5b                   	pop    %ebx
f0102fa0:	5e                   	pop    %esi
f0102fa1:	5d                   	pop    %ebp
f0102fa2:	c3                   	ret    

f0102fa3 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102fa3:	55                   	push   %ebp
f0102fa4:	89 e5                	mov    %esp,%ebp
f0102fa6:	56                   	push   %esi
f0102fa7:	53                   	push   %ebx
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102fa8:	8b 1d 50 a2 22 f0    	mov    0xf022a250,%ebx
f0102fae:	85 db                	test   %ebx,%ebx
f0102fb0:	0f 84 64 01 00 00    	je     f010311a <env_alloc+0x177>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102fb6:	83 ec 0c             	sub    $0xc,%esp
f0102fb9:	6a 01                	push   $0x1
f0102fbb:	e8 a6 df ff ff       	call   f0100f66 <page_alloc>
f0102fc0:	89 c6                	mov    %eax,%esi
f0102fc2:	83 c4 10             	add    $0x10,%esp
f0102fc5:	85 c0                	test   %eax,%eax
f0102fc7:	0f 84 54 01 00 00    	je     f0103121 <env_alloc+0x17e>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102fcd:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f0102fd3:	c1 f8 03             	sar    $0x3,%eax
f0102fd6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102fd9:	89 c2                	mov    %eax,%edx
f0102fdb:	c1 ea 0c             	shr    $0xc,%edx
f0102fde:	3b 15 08 af 22 f0    	cmp    0xf022af08,%edx
f0102fe4:	72 12                	jb     f0102ff8 <env_alloc+0x55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102fe6:	50                   	push   %eax
f0102fe7:	68 a4 59 10 f0       	push   $0xf01059a4
f0102fec:	6a 58                	push   $0x58
f0102fee:	68 01 69 10 f0       	push   $0xf0106901
f0102ff3:	e8 48 d0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102ff8:	2d 00 00 00 10       	sub    $0x10000000,%eax
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	// p = page_alloc(ALLOC_ZERO);
	e->env_pgdir = page2kva(p);
f0102ffd:	89 43 60             	mov    %eax,0x60(%ebx)
	//memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
	memmove(e->env_pgdir, kern_pgdir, PGSIZE);
f0103000:	83 ec 04             	sub    $0x4,%esp
f0103003:	68 00 10 00 00       	push   $0x1000
f0103008:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f010300e:	50                   	push   %eax
f010300f:	e8 fc 1c 00 00       	call   f0104d10 <memmove>
	p->pp_ref++;
f0103014:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103019:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010301c:	83 c4 10             	add    $0x10,%esp
f010301f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103024:	77 15                	ja     f010303b <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103026:	50                   	push   %eax
f0103027:	68 c8 59 10 f0       	push   $0xf01059c8
f010302c:	68 c9 00 00 00       	push   $0xc9
f0103031:	68 5a 6c 10 f0       	push   $0xf0106c5a
f0103036:	e8 05 d0 ff ff       	call   f0100040 <_panic>
f010303b:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103041:	83 ca 05             	or     $0x5,%edx
f0103044:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010304a:	8b 43 48             	mov    0x48(%ebx),%eax
f010304d:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103052:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103057:	ba 00 10 00 00       	mov    $0x1000,%edx
f010305c:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010305f:	89 da                	mov    %ebx,%edx
f0103061:	2b 15 4c a2 22 f0    	sub    0xf022a24c,%edx
f0103067:	c1 fa 02             	sar    $0x2,%edx
f010306a:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0103070:	09 d0                	or     %edx,%eax
f0103072:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103075:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103078:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f010307b:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103082:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103089:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103090:	83 ec 04             	sub    $0x4,%esp
f0103093:	6a 44                	push   $0x44
f0103095:	6a 00                	push   $0x0
f0103097:	53                   	push   %ebx
f0103098:	e8 26 1c 00 00       	call   f0104cc3 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f010309d:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01030a3:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01030a9:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01030af:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01030b6:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f01030bc:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f01030c3:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f01030c7:	8b 43 44             	mov    0x44(%ebx),%eax
f01030ca:	a3 50 a2 22 f0       	mov    %eax,0xf022a250
	*newenv_store = e;
f01030cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01030d2:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01030d4:	8b 5b 48             	mov    0x48(%ebx),%ebx
f01030d7:	e8 0a 22 00 00       	call   f01052e6 <cpunum>
f01030dc:	6b c0 74             	imul   $0x74,%eax,%eax
f01030df:	83 c4 10             	add    $0x10,%esp
f01030e2:	ba 00 00 00 00       	mov    $0x0,%edx
f01030e7:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f01030ee:	74 11                	je     f0103101 <env_alloc+0x15e>
f01030f0:	e8 f1 21 00 00       	call   f01052e6 <cpunum>
f01030f5:	6b c0 74             	imul   $0x74,%eax,%eax
f01030f8:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01030fe:	8b 50 48             	mov    0x48(%eax),%edx
f0103101:	83 ec 04             	sub    $0x4,%esp
f0103104:	53                   	push   %ebx
f0103105:	52                   	push   %edx
f0103106:	68 76 6c 10 f0       	push   $0xf0106c76
f010310b:	e8 38 06 00 00       	call   f0103748 <cprintf>
	return 0;
f0103110:	83 c4 10             	add    $0x10,%esp
f0103113:	b8 00 00 00 00       	mov    $0x0,%eax
f0103118:	eb 0c                	jmp    f0103126 <env_alloc+0x183>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f010311a:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010311f:	eb 05                	jmp    f0103126 <env_alloc+0x183>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103121:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103126:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103129:	5b                   	pop    %ebx
f010312a:	5e                   	pop    %esi
f010312b:	5d                   	pop    %ebp
f010312c:	c3                   	ret    

f010312d <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010312d:	55                   	push   %ebp
f010312e:	89 e5                	mov    %esp,%ebp
f0103130:	57                   	push   %edi
f0103131:	56                   	push   %esi
f0103132:	53                   	push   %ebx
f0103133:	83 ec 34             	sub    $0x34,%esp
f0103136:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int r;
	r = env_alloc(&e, 0);
f0103139:	6a 00                	push   $0x0
f010313b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010313e:	50                   	push   %eax
f010313f:	e8 5f fe ff ff       	call   f0102fa3 <env_alloc>
	if(r != 0)
f0103144:	83 c4 10             	add    $0x10,%esp
f0103147:	85 c0                	test   %eax,%eax
f0103149:	74 15                	je     f0103160 <env_create+0x33>
		panic("env_create: %e", r);
f010314b:	50                   	push   %eax
f010314c:	68 8b 6c 10 f0       	push   $0xf0106c8b
f0103151:	68 ad 01 00 00       	push   $0x1ad
f0103156:	68 5a 6c 10 f0       	push   $0xf0106c5a
f010315b:	e8 e0 ce ff ff       	call   f0100040 <_panic>
	//if(env_alloc(&e,0) != 0)
	//	panic("env_alloc fail");
	e->env_type = type;
f0103160:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103163:	89 c2                	mov    %eax,%edx
f0103165:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103168:	8b 45 0c             	mov    0xc(%ebp),%eax
f010316b:	89 42 50             	mov    %eax,0x50(%edx)
	struct Elf *elf;
	// 强制类型转换，将binary后的内存空间内容按照结构ELF的格式读取
	elf = (struct Elf *)binary;
	// is this a valid ELF? 判断是否是ELF
	// ELF头开头的结构体叫做魔数,是一个16位的数组
	if(elf->e_magic != ELF_MAGIC)
f010316e:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103174:	74 17                	je     f010318d <env_create+0x60>
		panic("load segements fail");
f0103176:	83 ec 04             	sub    $0x4,%esp
f0103179:	68 9a 6c 10 f0       	push   $0xf0106c9a
f010317e:	68 7a 01 00 00       	push   $0x17a
f0103183:	68 5a 6c 10 f0       	push   $0xf0106c5a
f0103188:	e8 b3 ce ff ff       	call   f0100040 <_panic>
	// load each program segment (ignores ph flags)
	// e_phoff 程序头表的文件偏移地址
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
f010318d:	89 fb                	mov    %edi,%ebx
f010318f:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f0103192:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103196:	c1 e6 05             	shl    $0x5,%esi
f0103199:	01 de                	add    %ebx,%esi
	// 因为后面需要访问刚分配的内存，所以需要将env_pgdir装入cr3，使二级页表能够运作
	lcr3(PADDR(e->env_pgdir));
f010319b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010319e:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031a1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031a6:	77 15                	ja     f01031bd <env_create+0x90>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031a8:	50                   	push   %eax
f01031a9:	68 c8 59 10 f0       	push   $0xf01059c8
f01031ae:	68 80 01 00 00       	push   $0x180
f01031b3:	68 5a 6c 10 f0       	push   $0xf0106c5a
f01031b8:	e8 83 ce ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01031bd:	05 00 00 00 10       	add    $0x10000000,%eax
f01031c2:	0f 22 d8             	mov    %eax,%cr3
f01031c5:	eb 60                	jmp    f0103227 <env_create+0xfa>

	for (; ph < eph; ph++)
	{
		// 	(The ELF header should have ph->p_filesz <= ph->p_memsz.)
		if(ph->p_filesz > ph->p_memsz)
f01031c7:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01031ca:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f01031cd:	76 17                	jbe    f01031e6 <env_create+0xb9>
			panic("memory is not enough for file");
f01031cf:	83 ec 04             	sub    $0x4,%esp
f01031d2:	68 ae 6c 10 f0       	push   $0xf0106cae
f01031d7:	68 86 01 00 00       	push   $0x186
f01031dc:	68 5a 6c 10 f0       	push   $0xf0106c5a
f01031e1:	e8 5a ce ff ff       	call   f0100040 <_panic>
		if(ph->p_type == ELF_PROG_LOAD)
f01031e6:	83 3b 01             	cmpl   $0x1,(%ebx)
f01031e9:	75 39                	jne    f0103224 <env_create+0xf7>
		{
		//  Each segment's virtual address can be found in ph->p_va
		//  and its size in memory can be found in ph->p_memsz.
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f01031eb:	8b 53 08             	mov    0x8(%ebx),%edx
f01031ee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031f1:	e8 02 fc ff ff       	call   f0102df8 <region_alloc>
		//  The ph->p_filesz bytes from the ELF binary, starting at
		//  'binary + ph->p_offset', should be copied to virtual address
		//  ph->p_va. 
			//memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f01031f6:	83 ec 04             	sub    $0x4,%esp
f01031f9:	ff 73 10             	pushl  0x10(%ebx)
f01031fc:	89 f8                	mov    %edi,%eax
f01031fe:	03 43 04             	add    0x4(%ebx),%eax
f0103201:	50                   	push   %eax
f0103202:	ff 73 08             	pushl  0x8(%ebx)
f0103205:	e8 06 1b 00 00       	call   f0104d10 <memmove>
        //	Any remaining memory bytes should be cleared to zero.
		    memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
f010320a:	8b 43 10             	mov    0x10(%ebx),%eax
f010320d:	83 c4 0c             	add    $0xc,%esp
f0103210:	8b 53 14             	mov    0x14(%ebx),%edx
f0103213:	29 c2                	sub    %eax,%edx
f0103215:	52                   	push   %edx
f0103216:	6a 00                	push   $0x0
f0103218:	03 43 08             	add    0x8(%ebx),%eax
f010321b:	50                   	push   %eax
f010321c:	e8 a2 1a 00 00       	call   f0104cc3 <memset>
f0103221:	83 c4 10             	add    $0x10,%esp
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
	eph = ph + elf->e_phnum;
	// 因为后面需要访问刚分配的内存，所以需要将env_pgdir装入cr3，使二级页表能够运作
	lcr3(PADDR(e->env_pgdir));

	for (; ph < eph; ph++)
f0103224:	83 c3 20             	add    $0x20,%ebx
f0103227:	39 de                	cmp    %ebx,%esi
f0103229:	77 9c                	ja     f01031c7 <env_create+0x9a>
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
        //	Any remaining memory bytes should be cleared to zero.
		    memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
		}
	}
	e->env_tf.tf_eip = elf->e_entry;
f010322b:	8b 47 18             	mov    0x18(%edi),%eax
f010322e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103231:	89 47 30             	mov    %eax,0x30(%edi)
	lcr3(PADDR(kern_pgdir));
f0103234:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103239:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010323e:	77 15                	ja     f0103255 <env_create+0x128>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103240:	50                   	push   %eax
f0103241:	68 c8 59 10 f0       	push   $0xf01059c8
f0103246:	68 96 01 00 00       	push   $0x196
f010324b:	68 5a 6c 10 f0       	push   $0xf0106c5a
f0103250:	e8 eb cd ff ff       	call   f0100040 <_panic>
f0103255:	05 00 00 00 10       	add    $0x10000000,%eax
f010325a:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *) USTACKTOP-PGSIZE, PGSIZE);
f010325d:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103262:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103267:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010326a:	e8 89 fb ff ff       	call   f0102df8 <region_alloc>
		panic("env_create: %e", r);
	//if(env_alloc(&e,0) != 0)
	//	panic("env_alloc fail");
	e->env_type = type;
	load_icode(e, binary);
}
f010326f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103272:	5b                   	pop    %ebx
f0103273:	5e                   	pop    %esi
f0103274:	5f                   	pop    %edi
f0103275:	5d                   	pop    %ebp
f0103276:	c3                   	ret    

f0103277 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103277:	55                   	push   %ebp
f0103278:	89 e5                	mov    %esp,%ebp
f010327a:	57                   	push   %edi
f010327b:	56                   	push   %esi
f010327c:	53                   	push   %ebx
f010327d:	83 ec 1c             	sub    $0x1c,%esp
f0103280:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103283:	e8 5e 20 00 00       	call   f01052e6 <cpunum>
f0103288:	6b c0 74             	imul   $0x74,%eax,%eax
f010328b:	39 b8 28 b0 22 f0    	cmp    %edi,-0xfdd4fd8(%eax)
f0103291:	75 29                	jne    f01032bc <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f0103293:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103298:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010329d:	77 15                	ja     f01032b4 <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010329f:	50                   	push   %eax
f01032a0:	68 c8 59 10 f0       	push   $0xf01059c8
f01032a5:	68 c2 01 00 00       	push   $0x1c2
f01032aa:	68 5a 6c 10 f0       	push   $0xf0106c5a
f01032af:	e8 8c cd ff ff       	call   f0100040 <_panic>
f01032b4:	05 00 00 00 10       	add    $0x10000000,%eax
f01032b9:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01032bc:	8b 5f 48             	mov    0x48(%edi),%ebx
f01032bf:	e8 22 20 00 00       	call   f01052e6 <cpunum>
f01032c4:	6b c0 74             	imul   $0x74,%eax,%eax
f01032c7:	ba 00 00 00 00       	mov    $0x0,%edx
f01032cc:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f01032d3:	74 11                	je     f01032e6 <env_free+0x6f>
f01032d5:	e8 0c 20 00 00       	call   f01052e6 <cpunum>
f01032da:	6b c0 74             	imul   $0x74,%eax,%eax
f01032dd:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01032e3:	8b 50 48             	mov    0x48(%eax),%edx
f01032e6:	83 ec 04             	sub    $0x4,%esp
f01032e9:	53                   	push   %ebx
f01032ea:	52                   	push   %edx
f01032eb:	68 cc 6c 10 f0       	push   $0xf0106ccc
f01032f0:	e8 53 04 00 00       	call   f0103748 <cprintf>
f01032f5:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01032f8:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01032ff:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103302:	89 d0                	mov    %edx,%eax
f0103304:	c1 e0 02             	shl    $0x2,%eax
f0103307:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010330a:	8b 47 60             	mov    0x60(%edi),%eax
f010330d:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103310:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103316:	0f 84 a8 00 00 00    	je     f01033c4 <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010331c:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103322:	89 f0                	mov    %esi,%eax
f0103324:	c1 e8 0c             	shr    $0xc,%eax
f0103327:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010332a:	39 05 08 af 22 f0    	cmp    %eax,0xf022af08
f0103330:	77 15                	ja     f0103347 <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103332:	56                   	push   %esi
f0103333:	68 a4 59 10 f0       	push   $0xf01059a4
f0103338:	68 d1 01 00 00       	push   $0x1d1
f010333d:	68 5a 6c 10 f0       	push   $0xf0106c5a
f0103342:	e8 f9 cc ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103347:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010334a:	c1 e0 16             	shl    $0x16,%eax
f010334d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103350:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103355:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f010335c:	01 
f010335d:	74 17                	je     f0103376 <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010335f:	83 ec 08             	sub    $0x8,%esp
f0103362:	89 d8                	mov    %ebx,%eax
f0103364:	c1 e0 0c             	shl    $0xc,%eax
f0103367:	0b 45 e4             	or     -0x1c(%ebp),%eax
f010336a:	50                   	push   %eax
f010336b:	ff 77 60             	pushl  0x60(%edi)
f010336e:	e8 80 de ff ff       	call   f01011f3 <page_remove>
f0103373:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103376:	83 c3 01             	add    $0x1,%ebx
f0103379:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f010337f:	75 d4                	jne    f0103355 <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103381:	8b 47 60             	mov    0x60(%edi),%eax
f0103384:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103387:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010338e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103391:	3b 05 08 af 22 f0    	cmp    0xf022af08,%eax
f0103397:	72 14                	jb     f01033ad <env_free+0x136>
		panic("pa2page called with invalid pa");
f0103399:	83 ec 04             	sub    $0x4,%esp
f010339c:	68 bc 60 10 f0       	push   $0xf01060bc
f01033a1:	6a 51                	push   $0x51
f01033a3:	68 01 69 10 f0       	push   $0xf0106901
f01033a8:	e8 93 cc ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01033ad:	83 ec 0c             	sub    $0xc,%esp
f01033b0:	a1 10 af 22 f0       	mov    0xf022af10,%eax
f01033b5:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01033b8:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01033bb:	50                   	push   %eax
f01033bc:	e8 50 dc ff ff       	call   f0101011 <page_decref>
f01033c1:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01033c4:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01033c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01033cb:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01033d0:	0f 85 29 ff ff ff    	jne    f01032ff <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01033d6:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033d9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033de:	77 15                	ja     f01033f5 <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033e0:	50                   	push   %eax
f01033e1:	68 c8 59 10 f0       	push   $0xf01059c8
f01033e6:	68 df 01 00 00       	push   $0x1df
f01033eb:	68 5a 6c 10 f0       	push   $0xf0106c5a
f01033f0:	e8 4b cc ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f01033f5:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01033fc:	05 00 00 00 10       	add    $0x10000000,%eax
f0103401:	c1 e8 0c             	shr    $0xc,%eax
f0103404:	3b 05 08 af 22 f0    	cmp    0xf022af08,%eax
f010340a:	72 14                	jb     f0103420 <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f010340c:	83 ec 04             	sub    $0x4,%esp
f010340f:	68 bc 60 10 f0       	push   $0xf01060bc
f0103414:	6a 51                	push   $0x51
f0103416:	68 01 69 10 f0       	push   $0xf0106901
f010341b:	e8 20 cc ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103420:	83 ec 0c             	sub    $0xc,%esp
f0103423:	8b 15 10 af 22 f0    	mov    0xf022af10,%edx
f0103429:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010342c:	50                   	push   %eax
f010342d:	e8 df db ff ff       	call   f0101011 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103432:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103439:	a1 50 a2 22 f0       	mov    0xf022a250,%eax
f010343e:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103441:	89 3d 50 a2 22 f0    	mov    %edi,0xf022a250
}
f0103447:	83 c4 10             	add    $0x10,%esp
f010344a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010344d:	5b                   	pop    %ebx
f010344e:	5e                   	pop    %esi
f010344f:	5f                   	pop    %edi
f0103450:	5d                   	pop    %ebp
f0103451:	c3                   	ret    

f0103452 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103452:	55                   	push   %ebp
f0103453:	89 e5                	mov    %esp,%ebp
f0103455:	53                   	push   %ebx
f0103456:	83 ec 04             	sub    $0x4,%esp
f0103459:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f010345c:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103460:	75 19                	jne    f010347b <env_destroy+0x29>
f0103462:	e8 7f 1e 00 00       	call   f01052e6 <cpunum>
f0103467:	6b c0 74             	imul   $0x74,%eax,%eax
f010346a:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f0103470:	74 09                	je     f010347b <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103472:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103479:	eb 33                	jmp    f01034ae <env_destroy+0x5c>
	}

	env_free(e);
f010347b:	83 ec 0c             	sub    $0xc,%esp
f010347e:	53                   	push   %ebx
f010347f:	e8 f3 fd ff ff       	call   f0103277 <env_free>

	if (curenv == e) {
f0103484:	e8 5d 1e 00 00       	call   f01052e6 <cpunum>
f0103489:	6b c0 74             	imul   $0x74,%eax,%eax
f010348c:	83 c4 10             	add    $0x10,%esp
f010348f:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f0103495:	75 17                	jne    f01034ae <env_destroy+0x5c>
		curenv = NULL;
f0103497:	e8 4a 1e 00 00       	call   f01052e6 <cpunum>
f010349c:	6b c0 74             	imul   $0x74,%eax,%eax
f010349f:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f01034a6:	00 00 00 
		sched_yield();
f01034a9:	e8 c8 0b 00 00       	call   f0104076 <sched_yield>
	}
}
f01034ae:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01034b1:	c9                   	leave  
f01034b2:	c3                   	ret    

f01034b3 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01034b3:	55                   	push   %ebp
f01034b4:	89 e5                	mov    %esp,%ebp
f01034b6:	53                   	push   %ebx
f01034b7:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01034ba:	e8 27 1e 00 00       	call   f01052e6 <cpunum>
f01034bf:	6b c0 74             	imul   $0x74,%eax,%eax
f01034c2:	8b 98 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%ebx
f01034c8:	e8 19 1e 00 00       	call   f01052e6 <cpunum>
f01034cd:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f01034d0:	8b 65 08             	mov    0x8(%ebp),%esp
f01034d3:	61                   	popa   
f01034d4:	07                   	pop    %es
f01034d5:	1f                   	pop    %ds
f01034d6:	83 c4 08             	add    $0x8,%esp
f01034d9:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01034da:	83 ec 04             	sub    $0x4,%esp
f01034dd:	68 e2 6c 10 f0       	push   $0xf0106ce2
f01034e2:	68 15 02 00 00       	push   $0x215
f01034e7:	68 5a 6c 10 f0       	push   $0xf0106c5a
f01034ec:	e8 4f cb ff ff       	call   f0100040 <_panic>

f01034f1 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01034f1:	55                   	push   %ebp
f01034f2:	89 e5                	mov    %esp,%ebp
f01034f4:	53                   	push   %ebx
f01034f5:	83 ec 04             	sub    $0x4,%esp
f01034f8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv && curenv->env_status == ENV_RUNNING)
f01034fb:	e8 e6 1d 00 00       	call   f01052e6 <cpunum>
f0103500:	6b c0 74             	imul   $0x74,%eax,%eax
f0103503:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f010350a:	74 29                	je     f0103535 <env_run+0x44>
f010350c:	e8 d5 1d 00 00       	call   f01052e6 <cpunum>
f0103511:	6b c0 74             	imul   $0x74,%eax,%eax
f0103514:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010351a:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010351e:	75 15                	jne    f0103535 <env_run+0x44>
		curenv->env_status = ENV_RUNNABLE;
f0103520:	e8 c1 1d 00 00       	call   f01052e6 <cpunum>
f0103525:	6b c0 74             	imul   $0x74,%eax,%eax
f0103528:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010352e:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	curenv = e;
f0103535:	e8 ac 1d 00 00       	call   f01052e6 <cpunum>
f010353a:	6b c0 74             	imul   $0x74,%eax,%eax
f010353d:	89 98 28 b0 22 f0    	mov    %ebx,-0xfdd4fd8(%eax)
	curenv->env_status = ENV_RUNNING;
f0103543:	e8 9e 1d 00 00       	call   f01052e6 <cpunum>
f0103548:	6b c0 74             	imul   $0x74,%eax,%eax
f010354b:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103551:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0103558:	e8 89 1d 00 00       	call   f01052e6 <cpunum>
f010355d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103560:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103566:	83 40 58 01          	addl   $0x1,0x58(%eax)
	cprintf("%o \n",(physaddr_t)curenv->env_pgdir);
f010356a:	e8 77 1d 00 00       	call   f01052e6 <cpunum>
f010356f:	83 ec 08             	sub    $0x8,%esp
f0103572:	6b c0 74             	imul   $0x74,%eax,%eax
f0103575:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010357b:	ff 70 60             	pushl  0x60(%eax)
f010357e:	68 ee 6c 10 f0       	push   $0xf0106cee
f0103583:	e8 c0 01 00 00       	call   f0103748 <cprintf>
	lcr3(PADDR(curenv->env_pgdir));
f0103588:	e8 59 1d 00 00       	call   f01052e6 <cpunum>
f010358d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103590:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103596:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103599:	83 c4 10             	add    $0x10,%esp
f010359c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01035a1:	77 15                	ja     f01035b8 <env_run+0xc7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01035a3:	50                   	push   %eax
f01035a4:	68 c8 59 10 f0       	push   $0xf01059c8
f01035a9:	68 39 02 00 00       	push   $0x239
f01035ae:	68 5a 6c 10 f0       	push   $0xf0106c5a
f01035b3:	e8 88 ca ff ff       	call   f0100040 <_panic>
f01035b8:	05 00 00 00 10       	add    $0x10000000,%eax
f01035bd:	0f 22 d8             	mov    %eax,%cr3

	env_pop_tf(&e->env_tf);
f01035c0:	83 ec 0c             	sub    $0xc,%esp
f01035c3:	53                   	push   %ebx
f01035c4:	e8 ea fe ff ff       	call   f01034b3 <env_pop_tf>

f01035c9 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01035c9:	55                   	push   %ebp
f01035ca:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01035cc:	ba 70 00 00 00       	mov    $0x70,%edx
f01035d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01035d4:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01035d5:	ba 71 00 00 00       	mov    $0x71,%edx
f01035da:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01035db:	0f b6 c0             	movzbl %al,%eax
}
f01035de:	5d                   	pop    %ebp
f01035df:	c3                   	ret    

f01035e0 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01035e0:	55                   	push   %ebp
f01035e1:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01035e3:	ba 70 00 00 00       	mov    $0x70,%edx
f01035e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01035eb:	ee                   	out    %al,(%dx)
f01035ec:	ba 71 00 00 00       	mov    $0x71,%edx
f01035f1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035f4:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01035f5:	5d                   	pop    %ebp
f01035f6:	c3                   	ret    

f01035f7 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f01035f7:	55                   	push   %ebp
f01035f8:	89 e5                	mov    %esp,%ebp
f01035fa:	56                   	push   %esi
f01035fb:	53                   	push   %ebx
f01035fc:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f01035ff:	66 a3 a8 f3 11 f0    	mov    %ax,0xf011f3a8
	if (!didinit)
f0103605:	80 3d 54 a2 22 f0 00 	cmpb   $0x0,0xf022a254
f010360c:	74 5a                	je     f0103668 <irq_setmask_8259A+0x71>
f010360e:	89 c6                	mov    %eax,%esi
f0103610:	ba 21 00 00 00       	mov    $0x21,%edx
f0103615:	ee                   	out    %al,(%dx)
f0103616:	66 c1 e8 08          	shr    $0x8,%ax
f010361a:	ba a1 00 00 00       	mov    $0xa1,%edx
f010361f:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f0103620:	83 ec 0c             	sub    $0xc,%esp
f0103623:	68 f3 6c 10 f0       	push   $0xf0106cf3
f0103628:	e8 1b 01 00 00       	call   f0103748 <cprintf>
f010362d:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103630:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103635:	0f b7 f6             	movzwl %si,%esi
f0103638:	f7 d6                	not    %esi
f010363a:	0f a3 de             	bt     %ebx,%esi
f010363d:	73 11                	jae    f0103650 <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f010363f:	83 ec 08             	sub    $0x8,%esp
f0103642:	53                   	push   %ebx
f0103643:	68 85 71 10 f0       	push   $0xf0107185
f0103648:	e8 fb 00 00 00       	call   f0103748 <cprintf>
f010364d:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103650:	83 c3 01             	add    $0x1,%ebx
f0103653:	83 fb 10             	cmp    $0x10,%ebx
f0103656:	75 e2                	jne    f010363a <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103658:	83 ec 0c             	sub    $0xc,%esp
f010365b:	68 09 5d 10 f0       	push   $0xf0105d09
f0103660:	e8 e3 00 00 00       	call   f0103748 <cprintf>
f0103665:	83 c4 10             	add    $0x10,%esp
}
f0103668:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010366b:	5b                   	pop    %ebx
f010366c:	5e                   	pop    %esi
f010366d:	5d                   	pop    %ebp
f010366e:	c3                   	ret    

f010366f <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f010366f:	c6 05 54 a2 22 f0 01 	movb   $0x1,0xf022a254
f0103676:	ba 21 00 00 00       	mov    $0x21,%edx
f010367b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103680:	ee                   	out    %al,(%dx)
f0103681:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103686:	ee                   	out    %al,(%dx)
f0103687:	ba 20 00 00 00       	mov    $0x20,%edx
f010368c:	b8 11 00 00 00       	mov    $0x11,%eax
f0103691:	ee                   	out    %al,(%dx)
f0103692:	ba 21 00 00 00       	mov    $0x21,%edx
f0103697:	b8 20 00 00 00       	mov    $0x20,%eax
f010369c:	ee                   	out    %al,(%dx)
f010369d:	b8 04 00 00 00       	mov    $0x4,%eax
f01036a2:	ee                   	out    %al,(%dx)
f01036a3:	b8 03 00 00 00       	mov    $0x3,%eax
f01036a8:	ee                   	out    %al,(%dx)
f01036a9:	ba a0 00 00 00       	mov    $0xa0,%edx
f01036ae:	b8 11 00 00 00       	mov    $0x11,%eax
f01036b3:	ee                   	out    %al,(%dx)
f01036b4:	ba a1 00 00 00       	mov    $0xa1,%edx
f01036b9:	b8 28 00 00 00       	mov    $0x28,%eax
f01036be:	ee                   	out    %al,(%dx)
f01036bf:	b8 02 00 00 00       	mov    $0x2,%eax
f01036c4:	ee                   	out    %al,(%dx)
f01036c5:	b8 01 00 00 00       	mov    $0x1,%eax
f01036ca:	ee                   	out    %al,(%dx)
f01036cb:	ba 20 00 00 00       	mov    $0x20,%edx
f01036d0:	b8 68 00 00 00       	mov    $0x68,%eax
f01036d5:	ee                   	out    %al,(%dx)
f01036d6:	b8 0a 00 00 00       	mov    $0xa,%eax
f01036db:	ee                   	out    %al,(%dx)
f01036dc:	ba a0 00 00 00       	mov    $0xa0,%edx
f01036e1:	b8 68 00 00 00       	mov    $0x68,%eax
f01036e6:	ee                   	out    %al,(%dx)
f01036e7:	b8 0a 00 00 00       	mov    $0xa,%eax
f01036ec:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01036ed:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f01036f4:	66 83 f8 ff          	cmp    $0xffff,%ax
f01036f8:	74 13                	je     f010370d <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f01036fa:	55                   	push   %ebp
f01036fb:	89 e5                	mov    %esp,%ebp
f01036fd:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103700:	0f b7 c0             	movzwl %ax,%eax
f0103703:	50                   	push   %eax
f0103704:	e8 ee fe ff ff       	call   f01035f7 <irq_setmask_8259A>
f0103709:	83 c4 10             	add    $0x10,%esp
}
f010370c:	c9                   	leave  
f010370d:	f3 c3                	repz ret 

f010370f <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010370f:	55                   	push   %ebp
f0103710:	89 e5                	mov    %esp,%ebp
f0103712:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103715:	ff 75 08             	pushl  0x8(%ebp)
f0103718:	e8 54 d0 ff ff       	call   f0100771 <cputchar>
	*cnt++;
}
f010371d:	83 c4 10             	add    $0x10,%esp
f0103720:	c9                   	leave  
f0103721:	c3                   	ret    

f0103722 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103722:	55                   	push   %ebp
f0103723:	89 e5                	mov    %esp,%ebp
f0103725:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103728:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010372f:	ff 75 0c             	pushl  0xc(%ebp)
f0103732:	ff 75 08             	pushl  0x8(%ebp)
f0103735:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103738:	50                   	push   %eax
f0103739:	68 0f 37 10 f0       	push   $0xf010370f
f010373e:	e8 14 0f 00 00       	call   f0104657 <vprintfmt>
	return cnt;
}
f0103743:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103746:	c9                   	leave  
f0103747:	c3                   	ret    

f0103748 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103748:	55                   	push   %ebp
f0103749:	89 e5                	mov    %esp,%ebp
f010374b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010374e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103751:	50                   	push   %eax
f0103752:	ff 75 08             	pushl  0x8(%ebp)
f0103755:	e8 c8 ff ff ff       	call   f0103722 <vcprintf>
	va_end(ap);

	return cnt;
}
f010375a:	c9                   	leave  
f010375b:	c3                   	ret    

f010375c <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f010375c:	55                   	push   %ebp
f010375d:	89 e5                	mov    %esp,%ebp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f010375f:	b8 80 aa 22 f0       	mov    $0xf022aa80,%eax
f0103764:	c7 05 84 aa 22 f0 00 	movl   $0xf0000000,0xf022aa84
f010376b:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f010376e:	66 c7 05 88 aa 22 f0 	movw   $0x10,0xf022aa88
f0103775:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103777:	66 c7 05 68 f3 11 f0 	movw   $0x67,0xf011f368
f010377e:	67 00 
f0103780:	66 a3 6a f3 11 f0    	mov    %ax,0xf011f36a
f0103786:	89 c2                	mov    %eax,%edx
f0103788:	c1 ea 10             	shr    $0x10,%edx
f010378b:	88 15 6c f3 11 f0    	mov    %dl,0xf011f36c
f0103791:	c6 05 6e f3 11 f0 40 	movb   $0x40,0xf011f36e
f0103798:	c1 e8 18             	shr    $0x18,%eax
f010379b:	a2 6f f3 11 f0       	mov    %al,0xf011f36f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f01037a0:	c6 05 6d f3 11 f0 89 	movb   $0x89,0xf011f36d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01037a7:	b8 28 00 00 00       	mov    $0x28,%eax
f01037ac:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01037af:	b8 ac f3 11 f0       	mov    $0xf011f3ac,%eax
f01037b4:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f01037b7:	5d                   	pop    %ebp
f01037b8:	c3                   	ret    

f01037b9 <trap_init>:
}


void
trap_init(void)
{
f01037b9:	55                   	push   %ebp
f01037ba:	89 e5                	mov    %esp,%ebp
	
	void floating_point_error();

	void system_call();

	SETGATE(idt[T_DIVIDE], 1, GD_KT, divide_error, 0);
f01037bc:	b8 3c 3f 10 f0       	mov    $0xf0103f3c,%eax
f01037c1:	66 a3 60 a2 22 f0    	mov    %ax,0xf022a260
f01037c7:	66 c7 05 62 a2 22 f0 	movw   $0x8,0xf022a262
f01037ce:	08 00 
f01037d0:	c6 05 64 a2 22 f0 00 	movb   $0x0,0xf022a264
f01037d7:	c6 05 65 a2 22 f0 8f 	movb   $0x8f,0xf022a265
f01037de:	c1 e8 10             	shr    $0x10,%eax
f01037e1:	66 a3 66 a2 22 f0    	mov    %ax,0xf022a266
	SETGATE(idt[T_DEBUG], 1, GD_KT, debug_exception, 0);
f01037e7:	b8 42 3f 10 f0       	mov    $0xf0103f42,%eax
f01037ec:	66 a3 68 a2 22 f0    	mov    %ax,0xf022a268
f01037f2:	66 c7 05 6a a2 22 f0 	movw   $0x8,0xf022a26a
f01037f9:	08 00 
f01037fb:	c6 05 6c a2 22 f0 00 	movb   $0x0,0xf022a26c
f0103802:	c6 05 6d a2 22 f0 8f 	movb   $0x8f,0xf022a26d
f0103809:	c1 e8 10             	shr    $0x10,%eax
f010380c:	66 a3 6e a2 22 f0    	mov    %ax,0xf022a26e
	SETGATE(idt[T_NMI], 1, GD_KT, non_maskable_interrupt, 0);
f0103812:	b8 48 3f 10 f0       	mov    $0xf0103f48,%eax
f0103817:	66 a3 70 a2 22 f0    	mov    %ax,0xf022a270
f010381d:	66 c7 05 72 a2 22 f0 	movw   $0x8,0xf022a272
f0103824:	08 00 
f0103826:	c6 05 74 a2 22 f0 00 	movb   $0x0,0xf022a274
f010382d:	c6 05 75 a2 22 f0 8f 	movb   $0x8f,0xf022a275
f0103834:	c1 e8 10             	shr    $0x10,%eax
f0103837:	66 a3 76 a2 22 f0    	mov    %ax,0xf022a276
	SETGATE(idt[T_BRKPT], 1, GD_KT, break_point, 3);//!
f010383d:	b8 4e 3f 10 f0       	mov    $0xf0103f4e,%eax
f0103842:	66 a3 78 a2 22 f0    	mov    %ax,0xf022a278
f0103848:	66 c7 05 7a a2 22 f0 	movw   $0x8,0xf022a27a
f010384f:	08 00 
f0103851:	c6 05 7c a2 22 f0 00 	movb   $0x0,0xf022a27c
f0103858:	c6 05 7d a2 22 f0 ef 	movb   $0xef,0xf022a27d
f010385f:	c1 e8 10             	shr    $0x10,%eax
f0103862:	66 a3 7e a2 22 f0    	mov    %ax,0xf022a27e
	SETGATE(idt[T_OFLOW], 1, GD_KT, overflow, 0);
f0103868:	b8 54 3f 10 f0       	mov    $0xf0103f54,%eax
f010386d:	66 a3 80 a2 22 f0    	mov    %ax,0xf022a280
f0103873:	66 c7 05 82 a2 22 f0 	movw   $0x8,0xf022a282
f010387a:	08 00 
f010387c:	c6 05 84 a2 22 f0 00 	movb   $0x0,0xf022a284
f0103883:	c6 05 85 a2 22 f0 8f 	movb   $0x8f,0xf022a285
f010388a:	c1 e8 10             	shr    $0x10,%eax
f010388d:	66 a3 86 a2 22 f0    	mov    %ax,0xf022a286
	SETGATE(idt[T_BOUND], 1, GD_KT, bounds_check, 0);
f0103893:	b8 5a 3f 10 f0       	mov    $0xf0103f5a,%eax
f0103898:	66 a3 88 a2 22 f0    	mov    %ax,0xf022a288
f010389e:	66 c7 05 8a a2 22 f0 	movw   $0x8,0xf022a28a
f01038a5:	08 00 
f01038a7:	c6 05 8c a2 22 f0 00 	movb   $0x0,0xf022a28c
f01038ae:	c6 05 8d a2 22 f0 8f 	movb   $0x8f,0xf022a28d
f01038b5:	c1 e8 10             	shr    $0x10,%eax
f01038b8:	66 a3 8e a2 22 f0    	mov    %ax,0xf022a28e
	SETGATE(idt[T_ILLOP], 1, GD_KT, illegal_opcode, 0);
f01038be:	b8 60 3f 10 f0       	mov    $0xf0103f60,%eax
f01038c3:	66 a3 90 a2 22 f0    	mov    %ax,0xf022a290
f01038c9:	66 c7 05 92 a2 22 f0 	movw   $0x8,0xf022a292
f01038d0:	08 00 
f01038d2:	c6 05 94 a2 22 f0 00 	movb   $0x0,0xf022a294
f01038d9:	c6 05 95 a2 22 f0 8f 	movb   $0x8f,0xf022a295
f01038e0:	c1 e8 10             	shr    $0x10,%eax
f01038e3:	66 a3 96 a2 22 f0    	mov    %ax,0xf022a296
	SETGATE(idt[T_DEVICE], 1, GD_KT, device_not_available, 0);
f01038e9:	b8 66 3f 10 f0       	mov    $0xf0103f66,%eax
f01038ee:	66 a3 98 a2 22 f0    	mov    %ax,0xf022a298
f01038f4:	66 c7 05 9a a2 22 f0 	movw   $0x8,0xf022a29a
f01038fb:	08 00 
f01038fd:	c6 05 9c a2 22 f0 00 	movb   $0x0,0xf022a29c
f0103904:	c6 05 9d a2 22 f0 8f 	movb   $0x8f,0xf022a29d
f010390b:	c1 e8 10             	shr    $0x10,%eax
f010390e:	66 a3 9e a2 22 f0    	mov    %ax,0xf022a29e
	SETGATE(idt[T_DBLFLT], 1, GD_KT, double_fault, 0);
f0103914:	b8 6c 3f 10 f0       	mov    $0xf0103f6c,%eax
f0103919:	66 a3 a0 a2 22 f0    	mov    %ax,0xf022a2a0
f010391f:	66 c7 05 a2 a2 22 f0 	movw   $0x8,0xf022a2a2
f0103926:	08 00 
f0103928:	c6 05 a4 a2 22 f0 00 	movb   $0x0,0xf022a2a4
f010392f:	c6 05 a5 a2 22 f0 8f 	movb   $0x8f,0xf022a2a5
f0103936:	c1 e8 10             	shr    $0x10,%eax
f0103939:	66 a3 a6 a2 22 f0    	mov    %ax,0xf022a2a6

	SETGATE(idt[T_TSS], 1, GD_KT, invalid_task_switch_segment, 0);
f010393f:	b8 70 3f 10 f0       	mov    $0xf0103f70,%eax
f0103944:	66 a3 b0 a2 22 f0    	mov    %ax,0xf022a2b0
f010394a:	66 c7 05 b2 a2 22 f0 	movw   $0x8,0xf022a2b2
f0103951:	08 00 
f0103953:	c6 05 b4 a2 22 f0 00 	movb   $0x0,0xf022a2b4
f010395a:	c6 05 b5 a2 22 f0 8f 	movb   $0x8f,0xf022a2b5
f0103961:	c1 e8 10             	shr    $0x10,%eax
f0103964:	66 a3 b6 a2 22 f0    	mov    %ax,0xf022a2b6
	SETGATE(idt[T_SEGNP], 1, GD_KT, segment_not_present, 0);
f010396a:	b8 74 3f 10 f0       	mov    $0xf0103f74,%eax
f010396f:	66 a3 b8 a2 22 f0    	mov    %ax,0xf022a2b8
f0103975:	66 c7 05 ba a2 22 f0 	movw   $0x8,0xf022a2ba
f010397c:	08 00 
f010397e:	c6 05 bc a2 22 f0 00 	movb   $0x0,0xf022a2bc
f0103985:	c6 05 bd a2 22 f0 8f 	movb   $0x8f,0xf022a2bd
f010398c:	c1 e8 10             	shr    $0x10,%eax
f010398f:	66 a3 be a2 22 f0    	mov    %ax,0xf022a2be
	SETGATE(idt[T_STACK], 1, GD_KT, stack_exception, 0);
f0103995:	b8 78 3f 10 f0       	mov    $0xf0103f78,%eax
f010399a:	66 a3 c0 a2 22 f0    	mov    %ax,0xf022a2c0
f01039a0:	66 c7 05 c2 a2 22 f0 	movw   $0x8,0xf022a2c2
f01039a7:	08 00 
f01039a9:	c6 05 c4 a2 22 f0 00 	movb   $0x0,0xf022a2c4
f01039b0:	c6 05 c5 a2 22 f0 8f 	movb   $0x8f,0xf022a2c5
f01039b7:	c1 e8 10             	shr    $0x10,%eax
f01039ba:	66 a3 c6 a2 22 f0    	mov    %ax,0xf022a2c6
	SETGATE(idt[T_GPFLT], 1, GD_KT, general_protection_fault, 0);
f01039c0:	b8 7c 3f 10 f0       	mov    $0xf0103f7c,%eax
f01039c5:	66 a3 c8 a2 22 f0    	mov    %ax,0xf022a2c8
f01039cb:	66 c7 05 ca a2 22 f0 	movw   $0x8,0xf022a2ca
f01039d2:	08 00 
f01039d4:	c6 05 cc a2 22 f0 00 	movb   $0x0,0xf022a2cc
f01039db:	c6 05 cd a2 22 f0 8f 	movb   $0x8f,0xf022a2cd
f01039e2:	c1 e8 10             	shr    $0x10,%eax
f01039e5:	66 a3 ce a2 22 f0    	mov    %ax,0xf022a2ce
	SETGATE(idt[T_PGFLT], 1, GD_KT, page_fault, 0);
f01039eb:	b8 80 3f 10 f0       	mov    $0xf0103f80,%eax
f01039f0:	66 a3 d0 a2 22 f0    	mov    %ax,0xf022a2d0
f01039f6:	66 c7 05 d2 a2 22 f0 	movw   $0x8,0xf022a2d2
f01039fd:	08 00 
f01039ff:	c6 05 d4 a2 22 f0 00 	movb   $0x0,0xf022a2d4
f0103a06:	c6 05 d5 a2 22 f0 8f 	movb   $0x8f,0xf022a2d5
f0103a0d:	c1 e8 10             	shr    $0x10,%eax
f0103a10:	66 a3 d6 a2 22 f0    	mov    %ax,0xf022a2d6

	SETGATE(idt[T_FPERR], 1, GD_KT, floating_point_error, 0);
f0103a16:	b8 84 3f 10 f0       	mov    $0xf0103f84,%eax
f0103a1b:	66 a3 e0 a2 22 f0    	mov    %ax,0xf022a2e0
f0103a21:	66 c7 05 e2 a2 22 f0 	movw   $0x8,0xf022a2e2
f0103a28:	08 00 
f0103a2a:	c6 05 e4 a2 22 f0 00 	movb   $0x0,0xf022a2e4
f0103a31:	c6 05 e5 a2 22 f0 8f 	movb   $0x8f,0xf022a2e5
f0103a38:	c1 e8 10             	shr    $0x10,%eax
f0103a3b:	66 a3 e6 a2 22 f0    	mov    %ax,0xf022a2e6

	SETGATE(idt[T_SYSCALL], 0, GD_KT, system_call, 3);
f0103a41:	b8 8a 3f 10 f0       	mov    $0xf0103f8a,%eax
f0103a46:	66 a3 e0 a3 22 f0    	mov    %ax,0xf022a3e0
f0103a4c:	66 c7 05 e2 a3 22 f0 	movw   $0x8,0xf022a3e2
f0103a53:	08 00 
f0103a55:	c6 05 e4 a3 22 f0 00 	movb   $0x0,0xf022a3e4
f0103a5c:	c6 05 e5 a3 22 f0 ee 	movb   $0xee,0xf022a3e5
f0103a63:	c1 e8 10             	shr    $0x10,%eax
f0103a66:	66 a3 e6 a3 22 f0    	mov    %ax,0xf022a3e6

	// Per-CPU setup 
	trap_init_percpu();
f0103a6c:	e8 eb fc ff ff       	call   f010375c <trap_init_percpu>
}
f0103a71:	5d                   	pop    %ebp
f0103a72:	c3                   	ret    

f0103a73 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103a73:	55                   	push   %ebp
f0103a74:	89 e5                	mov    %esp,%ebp
f0103a76:	53                   	push   %ebx
f0103a77:	83 ec 0c             	sub    $0xc,%esp
f0103a7a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103a7d:	ff 33                	pushl  (%ebx)
f0103a7f:	68 07 6d 10 f0       	push   $0xf0106d07
f0103a84:	e8 bf fc ff ff       	call   f0103748 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103a89:	83 c4 08             	add    $0x8,%esp
f0103a8c:	ff 73 04             	pushl  0x4(%ebx)
f0103a8f:	68 16 6d 10 f0       	push   $0xf0106d16
f0103a94:	e8 af fc ff ff       	call   f0103748 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103a99:	83 c4 08             	add    $0x8,%esp
f0103a9c:	ff 73 08             	pushl  0x8(%ebx)
f0103a9f:	68 25 6d 10 f0       	push   $0xf0106d25
f0103aa4:	e8 9f fc ff ff       	call   f0103748 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103aa9:	83 c4 08             	add    $0x8,%esp
f0103aac:	ff 73 0c             	pushl  0xc(%ebx)
f0103aaf:	68 34 6d 10 f0       	push   $0xf0106d34
f0103ab4:	e8 8f fc ff ff       	call   f0103748 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103ab9:	83 c4 08             	add    $0x8,%esp
f0103abc:	ff 73 10             	pushl  0x10(%ebx)
f0103abf:	68 43 6d 10 f0       	push   $0xf0106d43
f0103ac4:	e8 7f fc ff ff       	call   f0103748 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103ac9:	83 c4 08             	add    $0x8,%esp
f0103acc:	ff 73 14             	pushl  0x14(%ebx)
f0103acf:	68 52 6d 10 f0       	push   $0xf0106d52
f0103ad4:	e8 6f fc ff ff       	call   f0103748 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103ad9:	83 c4 08             	add    $0x8,%esp
f0103adc:	ff 73 18             	pushl  0x18(%ebx)
f0103adf:	68 61 6d 10 f0       	push   $0xf0106d61
f0103ae4:	e8 5f fc ff ff       	call   f0103748 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103ae9:	83 c4 08             	add    $0x8,%esp
f0103aec:	ff 73 1c             	pushl  0x1c(%ebx)
f0103aef:	68 70 6d 10 f0       	push   $0xf0106d70
f0103af4:	e8 4f fc ff ff       	call   f0103748 <cprintf>
}
f0103af9:	83 c4 10             	add    $0x10,%esp
f0103afc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103aff:	c9                   	leave  
f0103b00:	c3                   	ret    

f0103b01 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103b01:	55                   	push   %ebp
f0103b02:	89 e5                	mov    %esp,%ebp
f0103b04:	56                   	push   %esi
f0103b05:	53                   	push   %ebx
f0103b06:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103b09:	e8 d8 17 00 00       	call   f01052e6 <cpunum>
f0103b0e:	83 ec 04             	sub    $0x4,%esp
f0103b11:	50                   	push   %eax
f0103b12:	53                   	push   %ebx
f0103b13:	68 d4 6d 10 f0       	push   $0xf0106dd4
f0103b18:	e8 2b fc ff ff       	call   f0103748 <cprintf>
	print_regs(&tf->tf_regs);
f0103b1d:	89 1c 24             	mov    %ebx,(%esp)
f0103b20:	e8 4e ff ff ff       	call   f0103a73 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103b25:	83 c4 08             	add    $0x8,%esp
f0103b28:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103b2c:	50                   	push   %eax
f0103b2d:	68 f2 6d 10 f0       	push   $0xf0106df2
f0103b32:	e8 11 fc ff ff       	call   f0103748 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103b37:	83 c4 08             	add    $0x8,%esp
f0103b3a:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103b3e:	50                   	push   %eax
f0103b3f:	68 05 6e 10 f0       	push   $0xf0106e05
f0103b44:	e8 ff fb ff ff       	call   f0103748 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b49:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103b4c:	83 c4 10             	add    $0x10,%esp
f0103b4f:	83 f8 13             	cmp    $0x13,%eax
f0103b52:	77 09                	ja     f0103b5d <print_trapframe+0x5c>
		return excnames[trapno];
f0103b54:	8b 14 85 a0 70 10 f0 	mov    -0xfef8f60(,%eax,4),%edx
f0103b5b:	eb 1f                	jmp    f0103b7c <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103b5d:	83 f8 30             	cmp    $0x30,%eax
f0103b60:	74 15                	je     f0103b77 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103b62:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103b65:	83 fa 10             	cmp    $0x10,%edx
f0103b68:	b9 9e 6d 10 f0       	mov    $0xf0106d9e,%ecx
f0103b6d:	ba 8b 6d 10 f0       	mov    $0xf0106d8b,%edx
f0103b72:	0f 43 d1             	cmovae %ecx,%edx
f0103b75:	eb 05                	jmp    f0103b7c <print_trapframe+0x7b>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103b77:	ba 7f 6d 10 f0       	mov    $0xf0106d7f,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b7c:	83 ec 04             	sub    $0x4,%esp
f0103b7f:	52                   	push   %edx
f0103b80:	50                   	push   %eax
f0103b81:	68 18 6e 10 f0       	push   $0xf0106e18
f0103b86:	e8 bd fb ff ff       	call   f0103748 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103b8b:	83 c4 10             	add    $0x10,%esp
f0103b8e:	3b 1d 60 aa 22 f0    	cmp    0xf022aa60,%ebx
f0103b94:	75 1a                	jne    f0103bb0 <print_trapframe+0xaf>
f0103b96:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103b9a:	75 14                	jne    f0103bb0 <print_trapframe+0xaf>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103b9c:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103b9f:	83 ec 08             	sub    $0x8,%esp
f0103ba2:	50                   	push   %eax
f0103ba3:	68 2a 6e 10 f0       	push   $0xf0106e2a
f0103ba8:	e8 9b fb ff ff       	call   f0103748 <cprintf>
f0103bad:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103bb0:	83 ec 08             	sub    $0x8,%esp
f0103bb3:	ff 73 2c             	pushl  0x2c(%ebx)
f0103bb6:	68 39 6e 10 f0       	push   $0xf0106e39
f0103bbb:	e8 88 fb ff ff       	call   f0103748 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103bc0:	83 c4 10             	add    $0x10,%esp
f0103bc3:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103bc7:	75 49                	jne    f0103c12 <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103bc9:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103bcc:	89 c2                	mov    %eax,%edx
f0103bce:	83 e2 01             	and    $0x1,%edx
f0103bd1:	ba b8 6d 10 f0       	mov    $0xf0106db8,%edx
f0103bd6:	b9 ad 6d 10 f0       	mov    $0xf0106dad,%ecx
f0103bdb:	0f 44 ca             	cmove  %edx,%ecx
f0103bde:	89 c2                	mov    %eax,%edx
f0103be0:	83 e2 02             	and    $0x2,%edx
f0103be3:	ba ca 6d 10 f0       	mov    $0xf0106dca,%edx
f0103be8:	be c4 6d 10 f0       	mov    $0xf0106dc4,%esi
f0103bed:	0f 45 d6             	cmovne %esi,%edx
f0103bf0:	83 e0 04             	and    $0x4,%eax
f0103bf3:	be e7 6e 10 f0       	mov    $0xf0106ee7,%esi
f0103bf8:	b8 cf 6d 10 f0       	mov    $0xf0106dcf,%eax
f0103bfd:	0f 44 c6             	cmove  %esi,%eax
f0103c00:	51                   	push   %ecx
f0103c01:	52                   	push   %edx
f0103c02:	50                   	push   %eax
f0103c03:	68 47 6e 10 f0       	push   $0xf0106e47
f0103c08:	e8 3b fb ff ff       	call   f0103748 <cprintf>
f0103c0d:	83 c4 10             	add    $0x10,%esp
f0103c10:	eb 10                	jmp    f0103c22 <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103c12:	83 ec 0c             	sub    $0xc,%esp
f0103c15:	68 09 5d 10 f0       	push   $0xf0105d09
f0103c1a:	e8 29 fb ff ff       	call   f0103748 <cprintf>
f0103c1f:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103c22:	83 ec 08             	sub    $0x8,%esp
f0103c25:	ff 73 30             	pushl  0x30(%ebx)
f0103c28:	68 56 6e 10 f0       	push   $0xf0106e56
f0103c2d:	e8 16 fb ff ff       	call   f0103748 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103c32:	83 c4 08             	add    $0x8,%esp
f0103c35:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103c39:	50                   	push   %eax
f0103c3a:	68 65 6e 10 f0       	push   $0xf0106e65
f0103c3f:	e8 04 fb ff ff       	call   f0103748 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103c44:	83 c4 08             	add    $0x8,%esp
f0103c47:	ff 73 38             	pushl  0x38(%ebx)
f0103c4a:	68 78 6e 10 f0       	push   $0xf0106e78
f0103c4f:	e8 f4 fa ff ff       	call   f0103748 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103c54:	83 c4 10             	add    $0x10,%esp
f0103c57:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c5b:	74 25                	je     f0103c82 <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103c5d:	83 ec 08             	sub    $0x8,%esp
f0103c60:	ff 73 3c             	pushl  0x3c(%ebx)
f0103c63:	68 87 6e 10 f0       	push   $0xf0106e87
f0103c68:	e8 db fa ff ff       	call   f0103748 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103c6d:	83 c4 08             	add    $0x8,%esp
f0103c70:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103c74:	50                   	push   %eax
f0103c75:	68 96 6e 10 f0       	push   $0xf0106e96
f0103c7a:	e8 c9 fa ff ff       	call   f0103748 <cprintf>
f0103c7f:	83 c4 10             	add    $0x10,%esp
	}
}
f0103c82:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103c85:	5b                   	pop    %ebx
f0103c86:	5e                   	pop    %esi
f0103c87:	5d                   	pop    %ebp
f0103c88:	c3                   	ret    

f0103c89 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103c89:	55                   	push   %ebp
f0103c8a:	89 e5                	mov    %esp,%ebp
f0103c8c:	57                   	push   %edi
f0103c8d:	56                   	push   %esi
f0103c8e:	53                   	push   %ebx
f0103c8f:	83 ec 0c             	sub    $0xc,%esp
f0103c92:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103c95:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs & 3) == 0) //缺页中断发生在内核中
f0103c98:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c9c:	75 17                	jne    f0103cb5 <page_fault_handler+0x2c>
    	panic("page fault happen in kernel mode!\n");
f0103c9e:	83 ec 04             	sub    $0x4,%esp
f0103ca1:	68 50 70 10 f0       	push   $0xf0107050
f0103ca6:	68 51 01 00 00       	push   $0x151
f0103cab:	68 a9 6e 10 f0       	push   $0xf0106ea9
f0103cb0:	e8 8b c3 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103cb5:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103cb8:	e8 29 16 00 00       	call   f01052e6 <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103cbd:	57                   	push   %edi
f0103cbe:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103cbf:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103cc2:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103cc8:	ff 70 48             	pushl  0x48(%eax)
f0103ccb:	68 74 70 10 f0       	push   $0xf0107074
f0103cd0:	e8 73 fa ff ff       	call   f0103748 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103cd5:	89 1c 24             	mov    %ebx,(%esp)
f0103cd8:	e8 24 fe ff ff       	call   f0103b01 <print_trapframe>
	env_destroy(curenv);
f0103cdd:	e8 04 16 00 00       	call   f01052e6 <cpunum>
f0103ce2:	83 c4 04             	add    $0x4,%esp
f0103ce5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ce8:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103cee:	e8 5f f7 ff ff       	call   f0103452 <env_destroy>
}
f0103cf3:	83 c4 10             	add    $0x10,%esp
f0103cf6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103cf9:	5b                   	pop    %ebx
f0103cfa:	5e                   	pop    %esi
f0103cfb:	5f                   	pop    %edi
f0103cfc:	5d                   	pop    %ebp
f0103cfd:	c3                   	ret    

f0103cfe <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103cfe:	55                   	push   %ebp
f0103cff:	89 e5                	mov    %esp,%ebp
f0103d01:	57                   	push   %edi
f0103d02:	56                   	push   %esi
f0103d03:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103d06:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103d07:	83 3d 00 af 22 f0 00 	cmpl   $0x0,0xf022af00
f0103d0e:	74 01                	je     f0103d11 <trap+0x13>
		asm volatile("hlt");
f0103d10:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103d11:	e8 d0 15 00 00       	call   f01052e6 <cpunum>
f0103d16:	6b d0 74             	imul   $0x74,%eax,%edx
f0103d19:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103d1f:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d24:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103d28:	83 f8 02             	cmp    $0x2,%eax
f0103d2b:	75 10                	jne    f0103d3d <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103d2d:	83 ec 0c             	sub    $0xc,%esp
f0103d30:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103d35:	e8 1a 18 00 00       	call   f0105554 <spin_lock>
f0103d3a:	83 c4 10             	add    $0x10,%esp

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103d3d:	9c                   	pushf  
f0103d3e:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d3f:	f6 c4 02             	test   $0x2,%ah
f0103d42:	74 19                	je     f0103d5d <trap+0x5f>
f0103d44:	68 b5 6e 10 f0       	push   $0xf0106eb5
f0103d49:	68 1b 69 10 f0       	push   $0xf010691b
f0103d4e:	68 1c 01 00 00       	push   $0x11c
f0103d53:	68 a9 6e 10 f0       	push   $0xf0106ea9
f0103d58:	e8 e3 c2 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103d5d:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d61:	83 e0 03             	and    $0x3,%eax
f0103d64:	66 83 f8 03          	cmp    $0x3,%ax
f0103d68:	0f 85 90 00 00 00    	jne    f0103dfe <trap+0x100>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		assert(curenv);
f0103d6e:	e8 73 15 00 00       	call   f01052e6 <cpunum>
f0103d73:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d76:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103d7d:	75 19                	jne    f0103d98 <trap+0x9a>
f0103d7f:	68 ce 6e 10 f0       	push   $0xf0106ece
f0103d84:	68 1b 69 10 f0       	push   $0xf010691b
f0103d89:	68 23 01 00 00       	push   $0x123
f0103d8e:	68 a9 6e 10 f0       	push   $0xf0106ea9
f0103d93:	e8 a8 c2 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103d98:	e8 49 15 00 00       	call   f01052e6 <cpunum>
f0103d9d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103da0:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103da6:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103daa:	75 2d                	jne    f0103dd9 <trap+0xdb>
			env_free(curenv);
f0103dac:	e8 35 15 00 00       	call   f01052e6 <cpunum>
f0103db1:	83 ec 0c             	sub    $0xc,%esp
f0103db4:	6b c0 74             	imul   $0x74,%eax,%eax
f0103db7:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103dbd:	e8 b5 f4 ff ff       	call   f0103277 <env_free>
			curenv = NULL;
f0103dc2:	e8 1f 15 00 00       	call   f01052e6 <cpunum>
f0103dc7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dca:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103dd1:	00 00 00 
			sched_yield();
f0103dd4:	e8 9d 02 00 00       	call   f0104076 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103dd9:	e8 08 15 00 00       	call   f01052e6 <cpunum>
f0103dde:	6b c0 74             	imul   $0x74,%eax,%eax
f0103de1:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103de7:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103dec:	89 c7                	mov    %eax,%edi
f0103dee:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103df0:	e8 f1 14 00 00       	call   f01052e6 <cpunum>
f0103df5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103df8:	8b b0 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103dfe:	89 35 60 aa 22 f0    	mov    %esi,0xf022aa60
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch (tf->tf_trapno)
f0103e04:	8b 46 28             	mov    0x28(%esi),%eax
f0103e07:	83 f8 0e             	cmp    $0xe,%eax
f0103e0a:	74 0c                	je     f0103e18 <trap+0x11a>
f0103e0c:	83 f8 30             	cmp    $0x30,%eax
f0103e0f:	74 23                	je     f0103e34 <trap+0x136>
f0103e11:	83 f8 03             	cmp    $0x3,%eax
f0103e14:	75 3e                	jne    f0103e54 <trap+0x156>
f0103e16:	eb 0e                	jmp    f0103e26 <trap+0x128>
	{
	case T_PGFLT:
		page_fault_handler(tf);
f0103e18:	83 ec 0c             	sub    $0xc,%esp
f0103e1b:	56                   	push   %esi
f0103e1c:	e8 68 fe ff ff       	call   f0103c89 <page_fault_handler>
f0103e21:	83 c4 10             	add    $0x10,%esp
f0103e24:	eb 73                	jmp    f0103e99 <trap+0x19b>
		break;
	case T_BRKPT:
		monitor(tf);
f0103e26:	83 ec 0c             	sub    $0xc,%esp
f0103e29:	56                   	push   %esi
f0103e2a:	e8 ed ca ff ff       	call   f010091c <monitor>
f0103e2f:	83 c4 10             	add    $0x10,%esp
f0103e32:	eb 65                	jmp    f0103e99 <trap+0x19b>
		break;
	case T_SYSCALL:
		tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, 
f0103e34:	8b 46 18             	mov    0x18(%esi),%eax
f0103e37:	83 ec 08             	sub    $0x8,%esp
f0103e3a:	ff 76 04             	pushl  0x4(%esi)
f0103e3d:	ff 36                	pushl  (%esi)
f0103e3f:	50                   	push   %eax
f0103e40:	50                   	push   %eax
f0103e41:	ff 76 14             	pushl  0x14(%esi)
f0103e44:	ff 76 1c             	pushl  0x1c(%esi)
f0103e47:	e8 37 02 00 00       	call   f0104083 <syscall>
f0103e4c:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103e4f:	83 c4 20             	add    $0x20,%esp
f0103e52:	eb 45                	jmp    f0103e99 <trap+0x19b>
		tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx, tf->tf_regs.reg_ecx, 
		tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
		break;
	default:
		// Unexpected trap: The user process or the kernel has a bug.
		print_trapframe(tf);
f0103e54:	83 ec 0c             	sub    $0xc,%esp
f0103e57:	56                   	push   %esi
f0103e58:	e8 a4 fc ff ff       	call   f0103b01 <print_trapframe>
		if (tf->tf_cs == GD_KT)
f0103e5d:	83 c4 10             	add    $0x10,%esp
f0103e60:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103e65:	75 17                	jne    f0103e7e <trap+0x180>
			panic("unhandled trap in kernel");
f0103e67:	83 ec 04             	sub    $0x4,%esp
f0103e6a:	68 d5 6e 10 f0       	push   $0xf0106ed5
f0103e6f:	68 ea 00 00 00       	push   $0xea
f0103e74:	68 a9 6e 10 f0       	push   $0xf0106ea9
f0103e79:	e8 c2 c1 ff ff       	call   f0100040 <_panic>
		else
		{
			env_destroy(curenv);
f0103e7e:	e8 63 14 00 00       	call   f01052e6 <cpunum>
f0103e83:	83 ec 0c             	sub    $0xc,%esp
f0103e86:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e89:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103e8f:	e8 be f5 ff ff       	call   f0103452 <env_destroy>
f0103e94:	83 c4 10             	add    $0x10,%esp
f0103e97:	eb 63                	jmp    f0103efc <trap+0x1fe>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103e99:	83 7e 28 27          	cmpl   $0x27,0x28(%esi)
f0103e9d:	75 1a                	jne    f0103eb9 <trap+0x1bb>
		cprintf("Spurious interrupt on irq 7\n");
f0103e9f:	83 ec 0c             	sub    $0xc,%esp
f0103ea2:	68 ee 6e 10 f0       	push   $0xf0106eee
f0103ea7:	e8 9c f8 ff ff       	call   f0103748 <cprintf>
		print_trapframe(tf);
f0103eac:	89 34 24             	mov    %esi,(%esp)
f0103eaf:	e8 4d fc ff ff       	call   f0103b01 <print_trapframe>
f0103eb4:	83 c4 10             	add    $0x10,%esp
f0103eb7:	eb 43                	jmp    f0103efc <trap+0x1fe>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103eb9:	83 ec 0c             	sub    $0xc,%esp
f0103ebc:	56                   	push   %esi
f0103ebd:	e8 3f fc ff ff       	call   f0103b01 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103ec2:	83 c4 10             	add    $0x10,%esp
f0103ec5:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103eca:	75 17                	jne    f0103ee3 <trap+0x1e5>
		panic("unhandled trap in kernel");
f0103ecc:	83 ec 04             	sub    $0x4,%esp
f0103ecf:	68 d5 6e 10 f0       	push   $0xf0106ed5
f0103ed4:	68 02 01 00 00       	push   $0x102
f0103ed9:	68 a9 6e 10 f0       	push   $0xf0106ea9
f0103ede:	e8 5d c1 ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f0103ee3:	e8 fe 13 00 00       	call   f01052e6 <cpunum>
f0103ee8:	83 ec 0c             	sub    $0xc,%esp
f0103eeb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eee:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103ef4:	e8 59 f5 ff ff       	call   f0103452 <env_destroy>
f0103ef9:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103efc:	e8 e5 13 00 00       	call   f01052e6 <cpunum>
f0103f01:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f04:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103f0b:	74 2a                	je     f0103f37 <trap+0x239>
f0103f0d:	e8 d4 13 00 00       	call   f01052e6 <cpunum>
f0103f12:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f15:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103f1b:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103f1f:	75 16                	jne    f0103f37 <trap+0x239>
		env_run(curenv);
f0103f21:	e8 c0 13 00 00       	call   f01052e6 <cpunum>
f0103f26:	83 ec 0c             	sub    $0xc,%esp
f0103f29:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f2c:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103f32:	e8 ba f5 ff ff       	call   f01034f1 <env_run>
	else
		sched_yield();
f0103f37:	e8 3a 01 00 00       	call   f0104076 <sched_yield>

f0103f3c <divide_error>:
 * Lab 3: Your code here for generating entry points for the different traps.
 */



	TRAPHANDLER_NOEC(divide_error, T_DIVIDE) 
f0103f3c:	6a 00                	push   $0x0
f0103f3e:	6a 00                	push   $0x0
f0103f40:	eb 4e                	jmp    f0103f90 <_alltraps>

f0103f42 <debug_exception>:
	TRAPHANDLER_NOEC(debug_exception, T_DEBUG) 
f0103f42:	6a 00                	push   $0x0
f0103f44:	6a 01                	push   $0x1
f0103f46:	eb 48                	jmp    f0103f90 <_alltraps>

f0103f48 <non_maskable_interrupt>:
	TRAPHANDLER_NOEC(non_maskable_interrupt, T_NMI) 
f0103f48:	6a 00                	push   $0x0
f0103f4a:	6a 02                	push   $0x2
f0103f4c:	eb 42                	jmp    f0103f90 <_alltraps>

f0103f4e <break_point>:
	TRAPHANDLER_NOEC(break_point, T_BRKPT)// inc/x86.中有breakpoint同名函数
f0103f4e:	6a 00                	push   $0x0
f0103f50:	6a 03                	push   $0x3
f0103f52:	eb 3c                	jmp    f0103f90 <_alltraps>

f0103f54 <overflow>:
	TRAPHANDLER_NOEC(overflow, T_OFLOW) 
f0103f54:	6a 00                	push   $0x0
f0103f56:	6a 04                	push   $0x4
f0103f58:	eb 36                	jmp    f0103f90 <_alltraps>

f0103f5a <bounds_check>:
	TRAPHANDLER_NOEC(bounds_check, T_BOUND) 
f0103f5a:	6a 00                	push   $0x0
f0103f5c:	6a 05                	push   $0x5
f0103f5e:	eb 30                	jmp    f0103f90 <_alltraps>

f0103f60 <illegal_opcode>:
	TRAPHANDLER_NOEC(illegal_opcode, T_ILLOP) 
f0103f60:	6a 00                	push   $0x0
f0103f62:	6a 06                	push   $0x6
f0103f64:	eb 2a                	jmp    f0103f90 <_alltraps>

f0103f66 <device_not_available>:
	TRAPHANDLER_NOEC(device_not_available, T_DEVICE) 
f0103f66:	6a 00                	push   $0x0
f0103f68:	6a 07                	push   $0x7
f0103f6a:	eb 24                	jmp    f0103f90 <_alltraps>

f0103f6c <double_fault>:
	TRAPHANDLER(double_fault, T_DBLFLT) 
f0103f6c:	6a 08                	push   $0x8
f0103f6e:	eb 20                	jmp    f0103f90 <_alltraps>

f0103f70 <invalid_task_switch_segment>:

	TRAPHANDLER(invalid_task_switch_segment, T_TSS) 
f0103f70:	6a 0a                	push   $0xa
f0103f72:	eb 1c                	jmp    f0103f90 <_alltraps>

f0103f74 <segment_not_present>:
	TRAPHANDLER(segment_not_present, T_SEGNP) 
f0103f74:	6a 0b                	push   $0xb
f0103f76:	eb 18                	jmp    f0103f90 <_alltraps>

f0103f78 <stack_exception>:
	TRAPHANDLER(stack_exception, T_STACK) 
f0103f78:	6a 0c                	push   $0xc
f0103f7a:	eb 14                	jmp    f0103f90 <_alltraps>

f0103f7c <general_protection_fault>:
	TRAPHANDLER(general_protection_fault, T_GPFLT) 
f0103f7c:	6a 0d                	push   $0xd
f0103f7e:	eb 10                	jmp    f0103f90 <_alltraps>

f0103f80 <page_fault>:
	TRAPHANDLER(page_fault, T_PGFLT) 
f0103f80:	6a 0e                	push   $0xe
f0103f82:	eb 0c                	jmp    f0103f90 <_alltraps>

f0103f84 <floating_point_error>:

	TRAPHANDLER_NOEC(floating_point_error, T_FPERR) 
f0103f84:	6a 00                	push   $0x0
f0103f86:	6a 10                	push   $0x10
f0103f88:	eb 06                	jmp    f0103f90 <_alltraps>

f0103f8a <system_call>:
	//x86手册9.10中没有说明aligment check && machine check
	//&& SIMD floating point error是否返回error code，故没写上
	TRAPHANDLER_NOEC(system_call, T_SYSCALL)
f0103f8a:	6a 00                	push   $0x0
f0103f8c:	6a 30                	push   $0x30
f0103f8e:	eb 00                	jmp    f0103f90 <_alltraps>

f0103f90 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
f0103f90:	1e                   	push   %ds
	pushl %es
f0103f91:	06                   	push   %es
	pushal
f0103f92:	60                   	pusha  

	mov $GD_KD,%eax
f0103f93:	b8 10 00 00 00       	mov    $0x10,%eax
	mov %eax,%ds
f0103f98:	8e d8                	mov    %eax,%ds
	mov %eax,%es
f0103f9a:	8e c0                	mov    %eax,%es
	
	pushl %esp  //压入trap()的参数tf，%esp指向Trapframe结构的起始地址
f0103f9c:	54                   	push   %esp
	call trap
f0103f9d:	e8 5c fd ff ff       	call   f0103cfe <trap>

f0103fa2 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0103fa2:	55                   	push   %ebp
f0103fa3:	89 e5                	mov    %esp,%ebp
f0103fa5:	83 ec 08             	sub    $0x8,%esp
f0103fa8:	a1 4c a2 22 f0       	mov    0xf022a24c,%eax
f0103fad:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103fb0:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0103fb5:	8b 02                	mov    (%edx),%eax
f0103fb7:	83 e8 01             	sub    $0x1,%eax
f0103fba:	83 f8 02             	cmp    $0x2,%eax
f0103fbd:	76 10                	jbe    f0103fcf <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103fbf:	83 c1 01             	add    $0x1,%ecx
f0103fc2:	83 c2 7c             	add    $0x7c,%edx
f0103fc5:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103fcb:	75 e8                	jne    f0103fb5 <sched_halt+0x13>
f0103fcd:	eb 08                	jmp    f0103fd7 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0103fcf:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103fd5:	75 1f                	jne    f0103ff6 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0103fd7:	83 ec 0c             	sub    $0xc,%esp
f0103fda:	68 f0 70 10 f0       	push   $0xf01070f0
f0103fdf:	e8 64 f7 ff ff       	call   f0103748 <cprintf>
f0103fe4:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0103fe7:	83 ec 0c             	sub    $0xc,%esp
f0103fea:	6a 00                	push   $0x0
f0103fec:	e8 2b c9 ff ff       	call   f010091c <monitor>
f0103ff1:	83 c4 10             	add    $0x10,%esp
f0103ff4:	eb f1                	jmp    f0103fe7 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0103ff6:	e8 eb 12 00 00       	call   f01052e6 <cpunum>
f0103ffb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ffe:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0104005:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0104008:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010400d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104012:	77 12                	ja     f0104026 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104014:	50                   	push   %eax
f0104015:	68 c8 59 10 f0       	push   $0xf01059c8
f010401a:	6a 3d                	push   $0x3d
f010401c:	68 19 71 10 f0       	push   $0xf0107119
f0104021:	e8 1a c0 ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0104026:	05 00 00 00 10       	add    $0x10000000,%eax
f010402b:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f010402e:	e8 b3 12 00 00       	call   f01052e6 <cpunum>
f0104033:	6b d0 74             	imul   $0x74,%eax,%edx
f0104036:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f010403c:	b8 02 00 00 00       	mov    $0x2,%eax
f0104041:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0104045:	83 ec 0c             	sub    $0xc,%esp
f0104048:	68 c0 f3 11 f0       	push   $0xf011f3c0
f010404d:	e8 9f 15 00 00       	call   f01055f1 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0104052:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104054:	e8 8d 12 00 00       	call   f01052e6 <cpunum>
f0104059:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f010405c:	8b 80 30 b0 22 f0    	mov    -0xfdd4fd0(%eax),%eax
f0104062:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104067:	89 c4                	mov    %eax,%esp
f0104069:	6a 00                	push   $0x0
f010406b:	6a 00                	push   $0x0
f010406d:	fb                   	sti    
f010406e:	f4                   	hlt    
f010406f:	eb fd                	jmp    f010406e <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0104071:	83 c4 10             	add    $0x10,%esp
f0104074:	c9                   	leave  
f0104075:	c3                   	ret    

f0104076 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0104076:	55                   	push   %ebp
f0104077:	89 e5                	mov    %esp,%ebp
f0104079:	83 ec 08             	sub    $0x8,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.

	// sched_halt never returns
	sched_halt();
f010407c:	e8 21 ff ff ff       	call   f0103fa2 <sched_halt>
}
f0104081:	c9                   	leave  
f0104082:	c3                   	ret    

f0104083 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104083:	55                   	push   %ebp
f0104084:	89 e5                	mov    %esp,%ebp
f0104086:	53                   	push   %ebx
f0104087:	83 ec 14             	sub    $0x14,%esp
f010408a:	8b 45 08             	mov    0x8(%ebp),%eax
	// LAB 3: Your code here.

	//panic("syscall not implemented");
	int ret;

	switch (syscallno) {
f010408d:	83 f8 01             	cmp    $0x1,%eax
f0104090:	74 53                	je     f01040e5 <syscall+0x62>
f0104092:	83 f8 01             	cmp    $0x1,%eax
f0104095:	72 13                	jb     f01040aa <syscall+0x27>
f0104097:	83 f8 02             	cmp    $0x2,%eax
f010409a:	0f 84 db 00 00 00    	je     f010417b <syscall+0xf8>
f01040a0:	83 f8 03             	cmp    $0x3,%eax
f01040a3:	74 4a                	je     f01040ef <syscall+0x6c>
f01040a5:	e9 e4 00 00 00       	jmp    f010418e <syscall+0x10b>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f01040aa:	e8 37 12 00 00       	call   f01052e6 <cpunum>
f01040af:	6a 04                	push   $0x4
f01040b1:	ff 75 10             	pushl  0x10(%ebp)
f01040b4:	ff 75 0c             	pushl  0xc(%ebp)
f01040b7:	6b c0 74             	imul   $0x74,%eax,%eax
f01040ba:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f01040c0:	e8 e9 ec ff ff       	call   f0102dae <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01040c5:	83 c4 0c             	add    $0xc,%esp
f01040c8:	ff 75 0c             	pushl  0xc(%ebp)
f01040cb:	ff 75 10             	pushl  0x10(%ebp)
f01040ce:	68 26 71 10 f0       	push   $0xf0107126
f01040d3:	e8 70 f6 ff ff       	call   f0103748 <cprintf>
f01040d8:	83 c4 10             	add    $0x10,%esp
	int ret;

	switch (syscallno) {
	case SYS_cputs:
		sys_cputs((const char*)a1,(size_t)a2);
		ret = 0;//其他函数都return 0
f01040db:	b8 00 00 00 00       	mov    $0x0,%eax
f01040e0:	e9 ae 00 00 00       	jmp    f0104193 <syscall+0x110>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01040e5:	e8 18 c5 ff ff       	call   f0100602 <cons_getc>
		sys_cputs((const char*)a1,(size_t)a2);
		ret = 0;//其他函数都return 0
		break;
	case SYS_cgetc:
		ret = sys_cgetc();
		break;
f01040ea:	e9 a4 00 00 00       	jmp    f0104193 <syscall+0x110>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01040ef:	83 ec 04             	sub    $0x4,%esp
f01040f2:	6a 01                	push   $0x1
f01040f4:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01040f7:	50                   	push   %eax
f01040f8:	ff 75 0c             	pushl  0xc(%ebp)
f01040fb:	e8 98 ed ff ff       	call   f0102e98 <envid2env>
f0104100:	83 c4 10             	add    $0x10,%esp
f0104103:	85 c0                	test   %eax,%eax
f0104105:	0f 88 88 00 00 00    	js     f0104193 <syscall+0x110>
		return r;
	if (e == curenv)
f010410b:	e8 d6 11 00 00       	call   f01052e6 <cpunum>
f0104110:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104113:	6b c0 74             	imul   $0x74,%eax,%eax
f0104116:	39 90 28 b0 22 f0    	cmp    %edx,-0xfdd4fd8(%eax)
f010411c:	75 23                	jne    f0104141 <syscall+0xbe>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f010411e:	e8 c3 11 00 00       	call   f01052e6 <cpunum>
f0104123:	83 ec 08             	sub    $0x8,%esp
f0104126:	6b c0 74             	imul   $0x74,%eax,%eax
f0104129:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010412f:	ff 70 48             	pushl  0x48(%eax)
f0104132:	68 2b 71 10 f0       	push   $0xf010712b
f0104137:	e8 0c f6 ff ff       	call   f0103748 <cprintf>
f010413c:	83 c4 10             	add    $0x10,%esp
f010413f:	eb 25                	jmp    f0104166 <syscall+0xe3>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104141:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104144:	e8 9d 11 00 00       	call   f01052e6 <cpunum>
f0104149:	83 ec 04             	sub    $0x4,%esp
f010414c:	53                   	push   %ebx
f010414d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104150:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104156:	ff 70 48             	pushl  0x48(%eax)
f0104159:	68 46 71 10 f0       	push   $0xf0107146
f010415e:	e8 e5 f5 ff ff       	call   f0103748 <cprintf>
f0104163:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0104166:	83 ec 0c             	sub    $0xc,%esp
f0104169:	ff 75 f4             	pushl  -0xc(%ebp)
f010416c:	e8 e1 f2 ff ff       	call   f0103452 <env_destroy>
f0104171:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104174:	b8 00 00 00 00       	mov    $0x0,%eax
f0104179:	eb 18                	jmp    f0104193 <syscall+0x110>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f010417b:	e8 66 11 00 00       	call   f01052e6 <cpunum>
f0104180:	6b c0 74             	imul   $0x74,%eax,%eax
f0104183:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104189:	8b 40 48             	mov    0x48(%eax),%eax
	case SYS_env_destroy:
		ret = sys_env_destroy((envid_t)a1);
		break;
	case SYS_getenvid:
		ret = sys_getenvid();
		break;
f010418c:	eb 05                	jmp    f0104193 <syscall+0x110>
	default:
		return -E_NO_SYS;
f010418e:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
	}
	return ret;
}
f0104193:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104196:	c9                   	leave  
f0104197:	c3                   	ret    

f0104198 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104198:	55                   	push   %ebp
f0104199:	89 e5                	mov    %esp,%ebp
f010419b:	57                   	push   %edi
f010419c:	56                   	push   %esi
f010419d:	53                   	push   %ebx
f010419e:	83 ec 14             	sub    $0x14,%esp
f01041a1:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01041a4:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01041a7:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01041aa:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01041ad:	8b 1a                	mov    (%edx),%ebx
f01041af:	8b 01                	mov    (%ecx),%eax
f01041b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01041b4:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01041bb:	eb 7f                	jmp    f010423c <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01041bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01041c0:	01 d8                	add    %ebx,%eax
f01041c2:	89 c6                	mov    %eax,%esi
f01041c4:	c1 ee 1f             	shr    $0x1f,%esi
f01041c7:	01 c6                	add    %eax,%esi
f01041c9:	d1 fe                	sar    %esi
f01041cb:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01041ce:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01041d1:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01041d4:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01041d6:	eb 03                	jmp    f01041db <stab_binsearch+0x43>
			m--;
f01041d8:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01041db:	39 c3                	cmp    %eax,%ebx
f01041dd:	7f 0d                	jg     f01041ec <stab_binsearch+0x54>
f01041df:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01041e3:	83 ea 0c             	sub    $0xc,%edx
f01041e6:	39 f9                	cmp    %edi,%ecx
f01041e8:	75 ee                	jne    f01041d8 <stab_binsearch+0x40>
f01041ea:	eb 05                	jmp    f01041f1 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01041ec:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01041ef:	eb 4b                	jmp    f010423c <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01041f1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01041f4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01041f7:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01041fb:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01041fe:	76 11                	jbe    f0104211 <stab_binsearch+0x79>
			*region_left = m;
f0104200:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104203:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104205:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104208:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010420f:	eb 2b                	jmp    f010423c <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104211:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104214:	73 14                	jae    f010422a <stab_binsearch+0x92>
			*region_right = m - 1;
f0104216:	83 e8 01             	sub    $0x1,%eax
f0104219:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010421c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010421f:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104221:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104228:	eb 12                	jmp    f010423c <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010422a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010422d:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010422f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104233:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104235:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010423c:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010423f:	0f 8e 78 ff ff ff    	jle    f01041bd <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104245:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104249:	75 0f                	jne    f010425a <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010424b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010424e:	8b 00                	mov    (%eax),%eax
f0104250:	83 e8 01             	sub    $0x1,%eax
f0104253:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104256:	89 06                	mov    %eax,(%esi)
f0104258:	eb 2c                	jmp    f0104286 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010425a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010425d:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010425f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104262:	8b 0e                	mov    (%esi),%ecx
f0104264:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104267:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010426a:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010426d:	eb 03                	jmp    f0104272 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010426f:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104272:	39 c8                	cmp    %ecx,%eax
f0104274:	7e 0b                	jle    f0104281 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0104276:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010427a:	83 ea 0c             	sub    $0xc,%edx
f010427d:	39 df                	cmp    %ebx,%edi
f010427f:	75 ee                	jne    f010426f <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104281:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104284:	89 06                	mov    %eax,(%esi)
	}
}
f0104286:	83 c4 14             	add    $0x14,%esp
f0104289:	5b                   	pop    %ebx
f010428a:	5e                   	pop    %esi
f010428b:	5f                   	pop    %edi
f010428c:	5d                   	pop    %ebp
f010428d:	c3                   	ret    

f010428e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010428e:	55                   	push   %ebp
f010428f:	89 e5                	mov    %esp,%ebp
f0104291:	57                   	push   %edi
f0104292:	56                   	push   %esi
f0104293:	53                   	push   %ebx
f0104294:	83 ec 3c             	sub    $0x3c,%esp
f0104297:	8b 7d 08             	mov    0x8(%ebp),%edi
f010429a:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010429d:	c7 06 5e 71 10 f0    	movl   $0xf010715e,(%esi)
	info->eip_line = 0;
f01042a3:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01042aa:	c7 46 08 5e 71 10 f0 	movl   $0xf010715e,0x8(%esi)
	info->eip_fn_namelen = 9;
f01042b1:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01042b8:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01042bb:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01042c2:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01042c8:	0f 87 92 00 00 00    	ja     f0104360 <debuginfo_eip+0xd2>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0)
f01042ce:	e8 13 10 00 00       	call   f01052e6 <cpunum>
f01042d3:	6a 04                	push   $0x4
f01042d5:	6a 10                	push   $0x10
f01042d7:	68 00 00 20 00       	push   $0x200000
f01042dc:	6b c0 74             	imul   $0x74,%eax,%eax
f01042df:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f01042e5:	e8 35 ea ff ff       	call   f0102d1f <user_mem_check>
f01042ea:	83 c4 10             	add    $0x10,%esp
f01042ed:	85 c0                	test   %eax,%eax
f01042ef:	0f 85 01 02 00 00    	jne    f01044f6 <debuginfo_eip+0x268>
			return -1;
		stabs = usd->stabs;
f01042f5:	a1 00 00 20 00       	mov    0x200000,%eax
f01042fa:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f01042fd:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f0104303:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0104309:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f010430c:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0104312:	89 55 d0             	mov    %edx,-0x30(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, sizeof(struct UserStabData), PTE_U) != 0)
f0104315:	e8 cc 0f 00 00       	call   f01052e6 <cpunum>
f010431a:	6a 04                	push   $0x4
f010431c:	6a 10                	push   $0x10
f010431e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0104321:	6b c0 74             	imul   $0x74,%eax,%eax
f0104324:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f010432a:	e8 f0 e9 ff ff       	call   f0102d1f <user_mem_check>
f010432f:	83 c4 10             	add    $0x10,%esp
f0104332:	85 c0                	test   %eax,%eax
f0104334:	0f 85 c3 01 00 00    	jne    f01044fd <debuginfo_eip+0x26f>
			return -1;
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
f010433a:	e8 a7 0f 00 00       	call   f01052e6 <cpunum>
f010433f:	6a 04                	push   $0x4
f0104341:	6a 10                	push   $0x10
f0104343:	ff 75 cc             	pushl  -0x34(%ebp)
f0104346:	6b c0 74             	imul   $0x74,%eax,%eax
f0104349:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f010434f:	e8 cb e9 ff ff       	call   f0102d1f <user_mem_check>
f0104354:	83 c4 10             	add    $0x10,%esp
f0104357:	85 c0                	test   %eax,%eax
f0104359:	74 1f                	je     f010437a <debuginfo_eip+0xec>
f010435b:	e9 a4 01 00 00       	jmp    f0104504 <debuginfo_eip+0x276>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104360:	c7 45 d0 c9 42 11 f0 	movl   $0xf01142c9,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104367:	c7 45 cc d5 0c 11 f0 	movl   $0xf0110cd5,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f010436e:	bb d4 0c 11 f0       	mov    $0xf0110cd4,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104373:	c7 45 d4 38 76 10 f0 	movl   $0xf0107638,-0x2c(%ebp)
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010437a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010437d:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0104380:	0f 83 85 01 00 00    	jae    f010450b <debuginfo_eip+0x27d>
f0104386:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f010438a:	0f 85 82 01 00 00    	jne    f0104512 <debuginfo_eip+0x284>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104390:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104397:	2b 5d d4             	sub    -0x2c(%ebp),%ebx
f010439a:	c1 fb 02             	sar    $0x2,%ebx
f010439d:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f01043a3:	83 e8 01             	sub    $0x1,%eax
f01043a6:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01043a9:	83 ec 08             	sub    $0x8,%esp
f01043ac:	57                   	push   %edi
f01043ad:	6a 64                	push   $0x64
f01043af:	8d 55 e0             	lea    -0x20(%ebp),%edx
f01043b2:	89 d1                	mov    %edx,%ecx
f01043b4:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01043b7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01043ba:	89 d8                	mov    %ebx,%eax
f01043bc:	e8 d7 fd ff ff       	call   f0104198 <stab_binsearch>
	if (lfile == 0)
f01043c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043c4:	83 c4 10             	add    $0x10,%esp
f01043c7:	85 c0                	test   %eax,%eax
f01043c9:	0f 84 4a 01 00 00    	je     f0104519 <debuginfo_eip+0x28b>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01043cf:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01043d2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01043d5:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01043d8:	83 ec 08             	sub    $0x8,%esp
f01043db:	57                   	push   %edi
f01043dc:	6a 24                	push   $0x24
f01043de:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01043e1:	89 d1                	mov    %edx,%ecx
f01043e3:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01043e6:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f01043e9:	89 d8                	mov    %ebx,%eax
f01043eb:	e8 a8 fd ff ff       	call   f0104198 <stab_binsearch>

	if (lfun <= rfun) {
f01043f0:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01043f3:	83 c4 10             	add    $0x10,%esp
f01043f6:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f01043f9:	7f 25                	jg     f0104420 <debuginfo_eip+0x192>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01043fb:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01043fe:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104401:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104404:	8b 02                	mov    (%edx),%eax
f0104406:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0104409:	2b 4d cc             	sub    -0x34(%ebp),%ecx
f010440c:	39 c8                	cmp    %ecx,%eax
f010440e:	73 06                	jae    f0104416 <debuginfo_eip+0x188>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104410:	03 45 cc             	add    -0x34(%ebp),%eax
f0104413:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104416:	8b 42 08             	mov    0x8(%edx),%eax
f0104419:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f010441c:	29 c7                	sub    %eax,%edi
f010441e:	eb 06                	jmp    f0104426 <debuginfo_eip+0x198>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104420:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0104423:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104426:	83 ec 08             	sub    $0x8,%esp
f0104429:	6a 3a                	push   $0x3a
f010442b:	ff 76 08             	pushl  0x8(%esi)
f010442e:	e8 74 08 00 00       	call   f0104ca7 <strfind>
f0104433:	2b 46 08             	sub    0x8(%esi),%eax
f0104436:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
f0104439:	83 c4 08             	add    $0x8,%esp
f010443c:	2b 7e 10             	sub    0x10(%esi),%edi
f010443f:	57                   	push   %edi
f0104440:	6a 44                	push   $0x44
f0104442:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104445:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104448:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010444b:	89 f8                	mov    %edi,%eax
f010444d:	e8 46 fd ff ff       	call   f0104198 <stab_binsearch>
	if (lfun > rfun) 
f0104452:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104455:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0104458:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f010445b:	83 c4 10             	add    $0x10,%esp
f010445e:	39 c8                	cmp    %ecx,%eax
f0104460:	0f 8f ba 00 00 00    	jg     f0104520 <debuginfo_eip+0x292>
       	  return -1;
        info->eip_line = stabs[lfun].n_desc;
f0104466:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104469:	89 fa                	mov    %edi,%edx
f010446b:	8d 04 87             	lea    (%edi,%eax,4),%eax
f010446e:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0104471:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f0104475:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104478:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010447b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010447e:	8d 04 82             	lea    (%edx,%eax,4),%eax
f0104481:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0104484:	eb 06                	jmp    f010448c <debuginfo_eip+0x1fe>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0104486:	83 eb 01             	sub    $0x1,%ebx
f0104489:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010448c:	39 fb                	cmp    %edi,%ebx
f010448e:	7c 32                	jl     f01044c2 <debuginfo_eip+0x234>
	       && stabs[lline].n_type != N_SOL
f0104490:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0104494:	80 fa 84             	cmp    $0x84,%dl
f0104497:	74 0b                	je     f01044a4 <debuginfo_eip+0x216>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104499:	80 fa 64             	cmp    $0x64,%dl
f010449c:	75 e8                	jne    f0104486 <debuginfo_eip+0x1f8>
f010449e:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01044a2:	74 e2                	je     f0104486 <debuginfo_eip+0x1f8>
f01044a4:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01044a7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01044aa:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01044ad:	8b 04 87             	mov    (%edi,%eax,4),%eax
f01044b0:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01044b3:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01044b6:	29 fa                	sub    %edi,%edx
f01044b8:	39 d0                	cmp    %edx,%eax
f01044ba:	73 09                	jae    f01044c5 <debuginfo_eip+0x237>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01044bc:	01 f8                	add    %edi,%eax
f01044be:	89 06                	mov    %eax,(%esi)
f01044c0:	eb 03                	jmp    f01044c5 <debuginfo_eip+0x237>
f01044c2:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01044c5:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01044ca:	8b 7d c8             	mov    -0x38(%ebp),%edi
f01044cd:	39 cf                	cmp    %ecx,%edi
f01044cf:	7d 5b                	jge    f010452c <debuginfo_eip+0x29e>
		for (lline = lfun + 1;
f01044d1:	89 f8                	mov    %edi,%eax
f01044d3:	83 c0 01             	add    $0x1,%eax
f01044d6:	8b 55 c0             	mov    -0x40(%ebp),%edx
f01044d9:	eb 07                	jmp    f01044e2 <debuginfo_eip+0x254>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01044db:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01044df:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01044e2:	39 c8                	cmp    %ecx,%eax
f01044e4:	74 41                	je     f0104527 <debuginfo_eip+0x299>
f01044e6:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01044e9:	80 7a 04 a0          	cmpb   $0xa0,0x4(%edx)
f01044ed:	74 ec                	je     f01044db <debuginfo_eip+0x24d>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01044ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01044f4:	eb 36                	jmp    f010452c <debuginfo_eip+0x29e>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f01044f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01044fb:	eb 2f                	jmp    f010452c <debuginfo_eip+0x29e>
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f01044fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104502:	eb 28                	jmp    f010452c <debuginfo_eip+0x29e>
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f0104504:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104509:	eb 21                	jmp    f010452c <debuginfo_eip+0x29e>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010450b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104510:	eb 1a                	jmp    f010452c <debuginfo_eip+0x29e>
f0104512:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104517:	eb 13                	jmp    f010452c <debuginfo_eip+0x29e>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104519:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010451e:	eb 0c                	jmp    f010452c <debuginfo_eip+0x29e>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
	if (lfun > rfun) 
       	  return -1;
f0104520:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104525:	eb 05                	jmp    f010452c <debuginfo_eip+0x29e>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104527:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010452c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010452f:	5b                   	pop    %ebx
f0104530:	5e                   	pop    %esi
f0104531:	5f                   	pop    %edi
f0104532:	5d                   	pop    %ebp
f0104533:	c3                   	ret    

f0104534 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104534:	55                   	push   %ebp
f0104535:	89 e5                	mov    %esp,%ebp
f0104537:	57                   	push   %edi
f0104538:	56                   	push   %esi
f0104539:	53                   	push   %ebx
f010453a:	83 ec 1c             	sub    $0x1c,%esp
f010453d:	89 c7                	mov    %eax,%edi
f010453f:	89 d6                	mov    %edx,%esi
f0104541:	8b 45 08             	mov    0x8(%ebp),%eax
f0104544:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104547:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010454a:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010454d:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104550:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104555:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104558:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010455b:	39 d3                	cmp    %edx,%ebx
f010455d:	72 05                	jb     f0104564 <printnum+0x30>
f010455f:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104562:	77 45                	ja     f01045a9 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104564:	83 ec 0c             	sub    $0xc,%esp
f0104567:	ff 75 18             	pushl  0x18(%ebp)
f010456a:	8b 45 14             	mov    0x14(%ebp),%eax
f010456d:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104570:	53                   	push   %ebx
f0104571:	ff 75 10             	pushl  0x10(%ebp)
f0104574:	83 ec 08             	sub    $0x8,%esp
f0104577:	ff 75 e4             	pushl  -0x1c(%ebp)
f010457a:	ff 75 e0             	pushl  -0x20(%ebp)
f010457d:	ff 75 dc             	pushl  -0x24(%ebp)
f0104580:	ff 75 d8             	pushl  -0x28(%ebp)
f0104583:	e8 58 11 00 00       	call   f01056e0 <__udivdi3>
f0104588:	83 c4 18             	add    $0x18,%esp
f010458b:	52                   	push   %edx
f010458c:	50                   	push   %eax
f010458d:	89 f2                	mov    %esi,%edx
f010458f:	89 f8                	mov    %edi,%eax
f0104591:	e8 9e ff ff ff       	call   f0104534 <printnum>
f0104596:	83 c4 20             	add    $0x20,%esp
f0104599:	eb 18                	jmp    f01045b3 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010459b:	83 ec 08             	sub    $0x8,%esp
f010459e:	56                   	push   %esi
f010459f:	ff 75 18             	pushl  0x18(%ebp)
f01045a2:	ff d7                	call   *%edi
f01045a4:	83 c4 10             	add    $0x10,%esp
f01045a7:	eb 03                	jmp    f01045ac <printnum+0x78>
f01045a9:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01045ac:	83 eb 01             	sub    $0x1,%ebx
f01045af:	85 db                	test   %ebx,%ebx
f01045b1:	7f e8                	jg     f010459b <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01045b3:	83 ec 08             	sub    $0x8,%esp
f01045b6:	56                   	push   %esi
f01045b7:	83 ec 04             	sub    $0x4,%esp
f01045ba:	ff 75 e4             	pushl  -0x1c(%ebp)
f01045bd:	ff 75 e0             	pushl  -0x20(%ebp)
f01045c0:	ff 75 dc             	pushl  -0x24(%ebp)
f01045c3:	ff 75 d8             	pushl  -0x28(%ebp)
f01045c6:	e8 45 12 00 00       	call   f0105810 <__umoddi3>
f01045cb:	83 c4 14             	add    $0x14,%esp
f01045ce:	0f be 80 68 71 10 f0 	movsbl -0xfef8e98(%eax),%eax
f01045d5:	50                   	push   %eax
f01045d6:	ff d7                	call   *%edi
}
f01045d8:	83 c4 10             	add    $0x10,%esp
f01045db:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01045de:	5b                   	pop    %ebx
f01045df:	5e                   	pop    %esi
f01045e0:	5f                   	pop    %edi
f01045e1:	5d                   	pop    %ebp
f01045e2:	c3                   	ret    

f01045e3 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01045e3:	55                   	push   %ebp
f01045e4:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01045e6:	83 fa 01             	cmp    $0x1,%edx
f01045e9:	7e 0e                	jle    f01045f9 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01045eb:	8b 10                	mov    (%eax),%edx
f01045ed:	8d 4a 08             	lea    0x8(%edx),%ecx
f01045f0:	89 08                	mov    %ecx,(%eax)
f01045f2:	8b 02                	mov    (%edx),%eax
f01045f4:	8b 52 04             	mov    0x4(%edx),%edx
f01045f7:	eb 22                	jmp    f010461b <getuint+0x38>
	else if (lflag)
f01045f9:	85 d2                	test   %edx,%edx
f01045fb:	74 10                	je     f010460d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01045fd:	8b 10                	mov    (%eax),%edx
f01045ff:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104602:	89 08                	mov    %ecx,(%eax)
f0104604:	8b 02                	mov    (%edx),%eax
f0104606:	ba 00 00 00 00       	mov    $0x0,%edx
f010460b:	eb 0e                	jmp    f010461b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010460d:	8b 10                	mov    (%eax),%edx
f010460f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104612:	89 08                	mov    %ecx,(%eax)
f0104614:	8b 02                	mov    (%edx),%eax
f0104616:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010461b:	5d                   	pop    %ebp
f010461c:	c3                   	ret    

f010461d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010461d:	55                   	push   %ebp
f010461e:	89 e5                	mov    %esp,%ebp
f0104620:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104623:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104627:	8b 10                	mov    (%eax),%edx
f0104629:	3b 50 04             	cmp    0x4(%eax),%edx
f010462c:	73 0a                	jae    f0104638 <sprintputch+0x1b>
		*b->buf++ = ch;
f010462e:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104631:	89 08                	mov    %ecx,(%eax)
f0104633:	8b 45 08             	mov    0x8(%ebp),%eax
f0104636:	88 02                	mov    %al,(%edx)
}
f0104638:	5d                   	pop    %ebp
f0104639:	c3                   	ret    

f010463a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010463a:	55                   	push   %ebp
f010463b:	89 e5                	mov    %esp,%ebp
f010463d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104640:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104643:	50                   	push   %eax
f0104644:	ff 75 10             	pushl  0x10(%ebp)
f0104647:	ff 75 0c             	pushl  0xc(%ebp)
f010464a:	ff 75 08             	pushl  0x8(%ebp)
f010464d:	e8 05 00 00 00       	call   f0104657 <vprintfmt>
	va_end(ap);
}
f0104652:	83 c4 10             	add    $0x10,%esp
f0104655:	c9                   	leave  
f0104656:	c3                   	ret    

f0104657 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104657:	55                   	push   %ebp
f0104658:	89 e5                	mov    %esp,%ebp
f010465a:	57                   	push   %edi
f010465b:	56                   	push   %esi
f010465c:	53                   	push   %ebx
f010465d:	83 ec 2c             	sub    $0x2c,%esp
f0104660:	8b 75 08             	mov    0x8(%ebp),%esi
f0104663:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104666:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104669:	eb 12                	jmp    f010467d <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010466b:	85 c0                	test   %eax,%eax
f010466d:	0f 84 89 03 00 00    	je     f01049fc <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0104673:	83 ec 08             	sub    $0x8,%esp
f0104676:	53                   	push   %ebx
f0104677:	50                   	push   %eax
f0104678:	ff d6                	call   *%esi
f010467a:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010467d:	83 c7 01             	add    $0x1,%edi
f0104680:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104684:	83 f8 25             	cmp    $0x25,%eax
f0104687:	75 e2                	jne    f010466b <vprintfmt+0x14>
f0104689:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f010468d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104694:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010469b:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01046a2:	ba 00 00 00 00       	mov    $0x0,%edx
f01046a7:	eb 07                	jmp    f01046b0 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046a9:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01046ac:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046b0:	8d 47 01             	lea    0x1(%edi),%eax
f01046b3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01046b6:	0f b6 07             	movzbl (%edi),%eax
f01046b9:	0f b6 c8             	movzbl %al,%ecx
f01046bc:	83 e8 23             	sub    $0x23,%eax
f01046bf:	3c 55                	cmp    $0x55,%al
f01046c1:	0f 87 1a 03 00 00    	ja     f01049e1 <vprintfmt+0x38a>
f01046c7:	0f b6 c0             	movzbl %al,%eax
f01046ca:	ff 24 85 20 72 10 f0 	jmp    *-0xfef8de0(,%eax,4)
f01046d1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01046d4:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01046d8:	eb d6                	jmp    f01046b0 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046da:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01046dd:	b8 00 00 00 00       	mov    $0x0,%eax
f01046e2:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01046e5:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01046e8:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f01046ec:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f01046ef:	8d 51 d0             	lea    -0x30(%ecx),%edx
f01046f2:	83 fa 09             	cmp    $0x9,%edx
f01046f5:	77 39                	ja     f0104730 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01046f7:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01046fa:	eb e9                	jmp    f01046e5 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01046fc:	8b 45 14             	mov    0x14(%ebp),%eax
f01046ff:	8d 48 04             	lea    0x4(%eax),%ecx
f0104702:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104705:	8b 00                	mov    (%eax),%eax
f0104707:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010470a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f010470d:	eb 27                	jmp    f0104736 <vprintfmt+0xdf>
f010470f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104712:	85 c0                	test   %eax,%eax
f0104714:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104719:	0f 49 c8             	cmovns %eax,%ecx
f010471c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010471f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104722:	eb 8c                	jmp    f01046b0 <vprintfmt+0x59>
f0104724:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104727:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010472e:	eb 80                	jmp    f01046b0 <vprintfmt+0x59>
f0104730:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104733:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104736:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010473a:	0f 89 70 ff ff ff    	jns    f01046b0 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104740:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104743:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104746:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010474d:	e9 5e ff ff ff       	jmp    f01046b0 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104752:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104755:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104758:	e9 53 ff ff ff       	jmp    f01046b0 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010475d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104760:	8d 50 04             	lea    0x4(%eax),%edx
f0104763:	89 55 14             	mov    %edx,0x14(%ebp)
f0104766:	83 ec 08             	sub    $0x8,%esp
f0104769:	53                   	push   %ebx
f010476a:	ff 30                	pushl  (%eax)
f010476c:	ff d6                	call   *%esi
			break;
f010476e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104771:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104774:	e9 04 ff ff ff       	jmp    f010467d <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104779:	8b 45 14             	mov    0x14(%ebp),%eax
f010477c:	8d 50 04             	lea    0x4(%eax),%edx
f010477f:	89 55 14             	mov    %edx,0x14(%ebp)
f0104782:	8b 00                	mov    (%eax),%eax
f0104784:	99                   	cltd   
f0104785:	31 d0                	xor    %edx,%eax
f0104787:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104789:	83 f8 09             	cmp    $0x9,%eax
f010478c:	7f 0b                	jg     f0104799 <vprintfmt+0x142>
f010478e:	8b 14 85 80 73 10 f0 	mov    -0xfef8c80(,%eax,4),%edx
f0104795:	85 d2                	test   %edx,%edx
f0104797:	75 18                	jne    f01047b1 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0104799:	50                   	push   %eax
f010479a:	68 80 71 10 f0       	push   $0xf0107180
f010479f:	53                   	push   %ebx
f01047a0:	56                   	push   %esi
f01047a1:	e8 94 fe ff ff       	call   f010463a <printfmt>
f01047a6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01047a9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01047ac:	e9 cc fe ff ff       	jmp    f010467d <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f01047b1:	52                   	push   %edx
f01047b2:	68 2d 69 10 f0       	push   $0xf010692d
f01047b7:	53                   	push   %ebx
f01047b8:	56                   	push   %esi
f01047b9:	e8 7c fe ff ff       	call   f010463a <printfmt>
f01047be:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01047c1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01047c4:	e9 b4 fe ff ff       	jmp    f010467d <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01047c9:	8b 45 14             	mov    0x14(%ebp),%eax
f01047cc:	8d 50 04             	lea    0x4(%eax),%edx
f01047cf:	89 55 14             	mov    %edx,0x14(%ebp)
f01047d2:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01047d4:	85 ff                	test   %edi,%edi
f01047d6:	b8 79 71 10 f0       	mov    $0xf0107179,%eax
f01047db:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01047de:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01047e2:	0f 8e 94 00 00 00    	jle    f010487c <vprintfmt+0x225>
f01047e8:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01047ec:	0f 84 98 00 00 00    	je     f010488a <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f01047f2:	83 ec 08             	sub    $0x8,%esp
f01047f5:	ff 75 d0             	pushl  -0x30(%ebp)
f01047f8:	57                   	push   %edi
f01047f9:	e8 5f 03 00 00       	call   f0104b5d <strnlen>
f01047fe:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0104801:	29 c1                	sub    %eax,%ecx
f0104803:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104806:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104809:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010480d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104810:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104813:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104815:	eb 0f                	jmp    f0104826 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0104817:	83 ec 08             	sub    $0x8,%esp
f010481a:	53                   	push   %ebx
f010481b:	ff 75 e0             	pushl  -0x20(%ebp)
f010481e:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104820:	83 ef 01             	sub    $0x1,%edi
f0104823:	83 c4 10             	add    $0x10,%esp
f0104826:	85 ff                	test   %edi,%edi
f0104828:	7f ed                	jg     f0104817 <vprintfmt+0x1c0>
f010482a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010482d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104830:	85 c9                	test   %ecx,%ecx
f0104832:	b8 00 00 00 00       	mov    $0x0,%eax
f0104837:	0f 49 c1             	cmovns %ecx,%eax
f010483a:	29 c1                	sub    %eax,%ecx
f010483c:	89 75 08             	mov    %esi,0x8(%ebp)
f010483f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104842:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104845:	89 cb                	mov    %ecx,%ebx
f0104847:	eb 4d                	jmp    f0104896 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104849:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010484d:	74 1b                	je     f010486a <vprintfmt+0x213>
f010484f:	0f be c0             	movsbl %al,%eax
f0104852:	83 e8 20             	sub    $0x20,%eax
f0104855:	83 f8 5e             	cmp    $0x5e,%eax
f0104858:	76 10                	jbe    f010486a <vprintfmt+0x213>
					putch('?', putdat);
f010485a:	83 ec 08             	sub    $0x8,%esp
f010485d:	ff 75 0c             	pushl  0xc(%ebp)
f0104860:	6a 3f                	push   $0x3f
f0104862:	ff 55 08             	call   *0x8(%ebp)
f0104865:	83 c4 10             	add    $0x10,%esp
f0104868:	eb 0d                	jmp    f0104877 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f010486a:	83 ec 08             	sub    $0x8,%esp
f010486d:	ff 75 0c             	pushl  0xc(%ebp)
f0104870:	52                   	push   %edx
f0104871:	ff 55 08             	call   *0x8(%ebp)
f0104874:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104877:	83 eb 01             	sub    $0x1,%ebx
f010487a:	eb 1a                	jmp    f0104896 <vprintfmt+0x23f>
f010487c:	89 75 08             	mov    %esi,0x8(%ebp)
f010487f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104882:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104885:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104888:	eb 0c                	jmp    f0104896 <vprintfmt+0x23f>
f010488a:	89 75 08             	mov    %esi,0x8(%ebp)
f010488d:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104890:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104893:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104896:	83 c7 01             	add    $0x1,%edi
f0104899:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010489d:	0f be d0             	movsbl %al,%edx
f01048a0:	85 d2                	test   %edx,%edx
f01048a2:	74 23                	je     f01048c7 <vprintfmt+0x270>
f01048a4:	85 f6                	test   %esi,%esi
f01048a6:	78 a1                	js     f0104849 <vprintfmt+0x1f2>
f01048a8:	83 ee 01             	sub    $0x1,%esi
f01048ab:	79 9c                	jns    f0104849 <vprintfmt+0x1f2>
f01048ad:	89 df                	mov    %ebx,%edi
f01048af:	8b 75 08             	mov    0x8(%ebp),%esi
f01048b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01048b5:	eb 18                	jmp    f01048cf <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01048b7:	83 ec 08             	sub    $0x8,%esp
f01048ba:	53                   	push   %ebx
f01048bb:	6a 20                	push   $0x20
f01048bd:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01048bf:	83 ef 01             	sub    $0x1,%edi
f01048c2:	83 c4 10             	add    $0x10,%esp
f01048c5:	eb 08                	jmp    f01048cf <vprintfmt+0x278>
f01048c7:	89 df                	mov    %ebx,%edi
f01048c9:	8b 75 08             	mov    0x8(%ebp),%esi
f01048cc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01048cf:	85 ff                	test   %edi,%edi
f01048d1:	7f e4                	jg     f01048b7 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01048d3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01048d6:	e9 a2 fd ff ff       	jmp    f010467d <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01048db:	83 fa 01             	cmp    $0x1,%edx
f01048de:	7e 16                	jle    f01048f6 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01048e0:	8b 45 14             	mov    0x14(%ebp),%eax
f01048e3:	8d 50 08             	lea    0x8(%eax),%edx
f01048e6:	89 55 14             	mov    %edx,0x14(%ebp)
f01048e9:	8b 50 04             	mov    0x4(%eax),%edx
f01048ec:	8b 00                	mov    (%eax),%eax
f01048ee:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01048f1:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01048f4:	eb 32                	jmp    f0104928 <vprintfmt+0x2d1>
	else if (lflag)
f01048f6:	85 d2                	test   %edx,%edx
f01048f8:	74 18                	je     f0104912 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f01048fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01048fd:	8d 50 04             	lea    0x4(%eax),%edx
f0104900:	89 55 14             	mov    %edx,0x14(%ebp)
f0104903:	8b 00                	mov    (%eax),%eax
f0104905:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104908:	89 c1                	mov    %eax,%ecx
f010490a:	c1 f9 1f             	sar    $0x1f,%ecx
f010490d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104910:	eb 16                	jmp    f0104928 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0104912:	8b 45 14             	mov    0x14(%ebp),%eax
f0104915:	8d 50 04             	lea    0x4(%eax),%edx
f0104918:	89 55 14             	mov    %edx,0x14(%ebp)
f010491b:	8b 00                	mov    (%eax),%eax
f010491d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104920:	89 c1                	mov    %eax,%ecx
f0104922:	c1 f9 1f             	sar    $0x1f,%ecx
f0104925:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104928:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010492b:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010492e:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104933:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104937:	79 74                	jns    f01049ad <vprintfmt+0x356>
				putch('-', putdat);
f0104939:	83 ec 08             	sub    $0x8,%esp
f010493c:	53                   	push   %ebx
f010493d:	6a 2d                	push   $0x2d
f010493f:	ff d6                	call   *%esi
				num = -(long long) num;
f0104941:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104944:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104947:	f7 d8                	neg    %eax
f0104949:	83 d2 00             	adc    $0x0,%edx
f010494c:	f7 da                	neg    %edx
f010494e:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0104951:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104956:	eb 55                	jmp    f01049ad <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104958:	8d 45 14             	lea    0x14(%ebp),%eax
f010495b:	e8 83 fc ff ff       	call   f01045e3 <getuint>
			base = 10;
f0104960:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104965:	eb 46                	jmp    f01049ad <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0104967:	8d 45 14             	lea    0x14(%ebp),%eax
f010496a:	e8 74 fc ff ff       	call   f01045e3 <getuint>
			base = 8;
f010496f:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104974:	eb 37                	jmp    f01049ad <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0104976:	83 ec 08             	sub    $0x8,%esp
f0104979:	53                   	push   %ebx
f010497a:	6a 30                	push   $0x30
f010497c:	ff d6                	call   *%esi
			putch('x', putdat);
f010497e:	83 c4 08             	add    $0x8,%esp
f0104981:	53                   	push   %ebx
f0104982:	6a 78                	push   $0x78
f0104984:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104986:	8b 45 14             	mov    0x14(%ebp),%eax
f0104989:	8d 50 04             	lea    0x4(%eax),%edx
f010498c:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010498f:	8b 00                	mov    (%eax),%eax
f0104991:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0104996:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104999:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f010499e:	eb 0d                	jmp    f01049ad <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01049a0:	8d 45 14             	lea    0x14(%ebp),%eax
f01049a3:	e8 3b fc ff ff       	call   f01045e3 <getuint>
			base = 16;
f01049a8:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01049ad:	83 ec 0c             	sub    $0xc,%esp
f01049b0:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01049b4:	57                   	push   %edi
f01049b5:	ff 75 e0             	pushl  -0x20(%ebp)
f01049b8:	51                   	push   %ecx
f01049b9:	52                   	push   %edx
f01049ba:	50                   	push   %eax
f01049bb:	89 da                	mov    %ebx,%edx
f01049bd:	89 f0                	mov    %esi,%eax
f01049bf:	e8 70 fb ff ff       	call   f0104534 <printnum>
			break;
f01049c4:	83 c4 20             	add    $0x20,%esp
f01049c7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01049ca:	e9 ae fc ff ff       	jmp    f010467d <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01049cf:	83 ec 08             	sub    $0x8,%esp
f01049d2:	53                   	push   %ebx
f01049d3:	51                   	push   %ecx
f01049d4:	ff d6                	call   *%esi
			break;
f01049d6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01049d9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01049dc:	e9 9c fc ff ff       	jmp    f010467d <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01049e1:	83 ec 08             	sub    $0x8,%esp
f01049e4:	53                   	push   %ebx
f01049e5:	6a 25                	push   $0x25
f01049e7:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01049e9:	83 c4 10             	add    $0x10,%esp
f01049ec:	eb 03                	jmp    f01049f1 <vprintfmt+0x39a>
f01049ee:	83 ef 01             	sub    $0x1,%edi
f01049f1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01049f5:	75 f7                	jne    f01049ee <vprintfmt+0x397>
f01049f7:	e9 81 fc ff ff       	jmp    f010467d <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01049fc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01049ff:	5b                   	pop    %ebx
f0104a00:	5e                   	pop    %esi
f0104a01:	5f                   	pop    %edi
f0104a02:	5d                   	pop    %ebp
f0104a03:	c3                   	ret    

f0104a04 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104a04:	55                   	push   %ebp
f0104a05:	89 e5                	mov    %esp,%ebp
f0104a07:	83 ec 18             	sub    $0x18,%esp
f0104a0a:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a0d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104a10:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104a13:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104a17:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104a1a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104a21:	85 c0                	test   %eax,%eax
f0104a23:	74 26                	je     f0104a4b <vsnprintf+0x47>
f0104a25:	85 d2                	test   %edx,%edx
f0104a27:	7e 22                	jle    f0104a4b <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104a29:	ff 75 14             	pushl  0x14(%ebp)
f0104a2c:	ff 75 10             	pushl  0x10(%ebp)
f0104a2f:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104a32:	50                   	push   %eax
f0104a33:	68 1d 46 10 f0       	push   $0xf010461d
f0104a38:	e8 1a fc ff ff       	call   f0104657 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104a3d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104a40:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104a43:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104a46:	83 c4 10             	add    $0x10,%esp
f0104a49:	eb 05                	jmp    f0104a50 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104a4b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104a50:	c9                   	leave  
f0104a51:	c3                   	ret    

f0104a52 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104a52:	55                   	push   %ebp
f0104a53:	89 e5                	mov    %esp,%ebp
f0104a55:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104a58:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104a5b:	50                   	push   %eax
f0104a5c:	ff 75 10             	pushl  0x10(%ebp)
f0104a5f:	ff 75 0c             	pushl  0xc(%ebp)
f0104a62:	ff 75 08             	pushl  0x8(%ebp)
f0104a65:	e8 9a ff ff ff       	call   f0104a04 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104a6a:	c9                   	leave  
f0104a6b:	c3                   	ret    

f0104a6c <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104a6c:	55                   	push   %ebp
f0104a6d:	89 e5                	mov    %esp,%ebp
f0104a6f:	57                   	push   %edi
f0104a70:	56                   	push   %esi
f0104a71:	53                   	push   %ebx
f0104a72:	83 ec 0c             	sub    $0xc,%esp
f0104a75:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104a78:	85 c0                	test   %eax,%eax
f0104a7a:	74 11                	je     f0104a8d <readline+0x21>
		cprintf("%s", prompt);
f0104a7c:	83 ec 08             	sub    $0x8,%esp
f0104a7f:	50                   	push   %eax
f0104a80:	68 2d 69 10 f0       	push   $0xf010692d
f0104a85:	e8 be ec ff ff       	call   f0103748 <cprintf>
f0104a8a:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104a8d:	83 ec 0c             	sub    $0xc,%esp
f0104a90:	6a 00                	push   $0x0
f0104a92:	e8 fb bc ff ff       	call   f0100792 <iscons>
f0104a97:	89 c7                	mov    %eax,%edi
f0104a99:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104a9c:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104aa1:	e8 db bc ff ff       	call   f0100781 <getchar>
f0104aa6:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104aa8:	85 c0                	test   %eax,%eax
f0104aaa:	79 18                	jns    f0104ac4 <readline+0x58>
			cprintf("read error: %e\n", c);
f0104aac:	83 ec 08             	sub    $0x8,%esp
f0104aaf:	50                   	push   %eax
f0104ab0:	68 a8 73 10 f0       	push   $0xf01073a8
f0104ab5:	e8 8e ec ff ff       	call   f0103748 <cprintf>
			return NULL;
f0104aba:	83 c4 10             	add    $0x10,%esp
f0104abd:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ac2:	eb 79                	jmp    f0104b3d <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104ac4:	83 f8 08             	cmp    $0x8,%eax
f0104ac7:	0f 94 c2             	sete   %dl
f0104aca:	83 f8 7f             	cmp    $0x7f,%eax
f0104acd:	0f 94 c0             	sete   %al
f0104ad0:	08 c2                	or     %al,%dl
f0104ad2:	74 1a                	je     f0104aee <readline+0x82>
f0104ad4:	85 f6                	test   %esi,%esi
f0104ad6:	7e 16                	jle    f0104aee <readline+0x82>
			if (echoing)
f0104ad8:	85 ff                	test   %edi,%edi
f0104ada:	74 0d                	je     f0104ae9 <readline+0x7d>
				cputchar('\b');
f0104adc:	83 ec 0c             	sub    $0xc,%esp
f0104adf:	6a 08                	push   $0x8
f0104ae1:	e8 8b bc ff ff       	call   f0100771 <cputchar>
f0104ae6:	83 c4 10             	add    $0x10,%esp
			i--;
f0104ae9:	83 ee 01             	sub    $0x1,%esi
f0104aec:	eb b3                	jmp    f0104aa1 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104aee:	83 fb 1f             	cmp    $0x1f,%ebx
f0104af1:	7e 23                	jle    f0104b16 <readline+0xaa>
f0104af3:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104af9:	7f 1b                	jg     f0104b16 <readline+0xaa>
			if (echoing)
f0104afb:	85 ff                	test   %edi,%edi
f0104afd:	74 0c                	je     f0104b0b <readline+0x9f>
				cputchar(c);
f0104aff:	83 ec 0c             	sub    $0xc,%esp
f0104b02:	53                   	push   %ebx
f0104b03:	e8 69 bc ff ff       	call   f0100771 <cputchar>
f0104b08:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104b0b:	88 9e 00 ab 22 f0    	mov    %bl,-0xfdd5500(%esi)
f0104b11:	8d 76 01             	lea    0x1(%esi),%esi
f0104b14:	eb 8b                	jmp    f0104aa1 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104b16:	83 fb 0a             	cmp    $0xa,%ebx
f0104b19:	74 05                	je     f0104b20 <readline+0xb4>
f0104b1b:	83 fb 0d             	cmp    $0xd,%ebx
f0104b1e:	75 81                	jne    f0104aa1 <readline+0x35>
			if (echoing)
f0104b20:	85 ff                	test   %edi,%edi
f0104b22:	74 0d                	je     f0104b31 <readline+0xc5>
				cputchar('\n');
f0104b24:	83 ec 0c             	sub    $0xc,%esp
f0104b27:	6a 0a                	push   $0xa
f0104b29:	e8 43 bc ff ff       	call   f0100771 <cputchar>
f0104b2e:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104b31:	c6 86 00 ab 22 f0 00 	movb   $0x0,-0xfdd5500(%esi)
			return buf;
f0104b38:	b8 00 ab 22 f0       	mov    $0xf022ab00,%eax
		}
	}
}
f0104b3d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104b40:	5b                   	pop    %ebx
f0104b41:	5e                   	pop    %esi
f0104b42:	5f                   	pop    %edi
f0104b43:	5d                   	pop    %ebp
f0104b44:	c3                   	ret    

f0104b45 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104b45:	55                   	push   %ebp
f0104b46:	89 e5                	mov    %esp,%ebp
f0104b48:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104b4b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b50:	eb 03                	jmp    f0104b55 <strlen+0x10>
		n++;
f0104b52:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104b55:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104b59:	75 f7                	jne    f0104b52 <strlen+0xd>
		n++;
	return n;
}
f0104b5b:	5d                   	pop    %ebp
f0104b5c:	c3                   	ret    

f0104b5d <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104b5d:	55                   	push   %ebp
f0104b5e:	89 e5                	mov    %esp,%ebp
f0104b60:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104b63:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104b66:	ba 00 00 00 00       	mov    $0x0,%edx
f0104b6b:	eb 03                	jmp    f0104b70 <strnlen+0x13>
		n++;
f0104b6d:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104b70:	39 c2                	cmp    %eax,%edx
f0104b72:	74 08                	je     f0104b7c <strnlen+0x1f>
f0104b74:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104b78:	75 f3                	jne    f0104b6d <strnlen+0x10>
f0104b7a:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104b7c:	5d                   	pop    %ebp
f0104b7d:	c3                   	ret    

f0104b7e <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104b7e:	55                   	push   %ebp
f0104b7f:	89 e5                	mov    %esp,%ebp
f0104b81:	53                   	push   %ebx
f0104b82:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b85:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104b88:	89 c2                	mov    %eax,%edx
f0104b8a:	83 c2 01             	add    $0x1,%edx
f0104b8d:	83 c1 01             	add    $0x1,%ecx
f0104b90:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104b94:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104b97:	84 db                	test   %bl,%bl
f0104b99:	75 ef                	jne    f0104b8a <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104b9b:	5b                   	pop    %ebx
f0104b9c:	5d                   	pop    %ebp
f0104b9d:	c3                   	ret    

f0104b9e <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104b9e:	55                   	push   %ebp
f0104b9f:	89 e5                	mov    %esp,%ebp
f0104ba1:	53                   	push   %ebx
f0104ba2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104ba5:	53                   	push   %ebx
f0104ba6:	e8 9a ff ff ff       	call   f0104b45 <strlen>
f0104bab:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104bae:	ff 75 0c             	pushl  0xc(%ebp)
f0104bb1:	01 d8                	add    %ebx,%eax
f0104bb3:	50                   	push   %eax
f0104bb4:	e8 c5 ff ff ff       	call   f0104b7e <strcpy>
	return dst;
}
f0104bb9:	89 d8                	mov    %ebx,%eax
f0104bbb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104bbe:	c9                   	leave  
f0104bbf:	c3                   	ret    

f0104bc0 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104bc0:	55                   	push   %ebp
f0104bc1:	89 e5                	mov    %esp,%ebp
f0104bc3:	56                   	push   %esi
f0104bc4:	53                   	push   %ebx
f0104bc5:	8b 75 08             	mov    0x8(%ebp),%esi
f0104bc8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104bcb:	89 f3                	mov    %esi,%ebx
f0104bcd:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104bd0:	89 f2                	mov    %esi,%edx
f0104bd2:	eb 0f                	jmp    f0104be3 <strncpy+0x23>
		*dst++ = *src;
f0104bd4:	83 c2 01             	add    $0x1,%edx
f0104bd7:	0f b6 01             	movzbl (%ecx),%eax
f0104bda:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104bdd:	80 39 01             	cmpb   $0x1,(%ecx)
f0104be0:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104be3:	39 da                	cmp    %ebx,%edx
f0104be5:	75 ed                	jne    f0104bd4 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104be7:	89 f0                	mov    %esi,%eax
f0104be9:	5b                   	pop    %ebx
f0104bea:	5e                   	pop    %esi
f0104beb:	5d                   	pop    %ebp
f0104bec:	c3                   	ret    

f0104bed <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104bed:	55                   	push   %ebp
f0104bee:	89 e5                	mov    %esp,%ebp
f0104bf0:	56                   	push   %esi
f0104bf1:	53                   	push   %ebx
f0104bf2:	8b 75 08             	mov    0x8(%ebp),%esi
f0104bf5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104bf8:	8b 55 10             	mov    0x10(%ebp),%edx
f0104bfb:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104bfd:	85 d2                	test   %edx,%edx
f0104bff:	74 21                	je     f0104c22 <strlcpy+0x35>
f0104c01:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104c05:	89 f2                	mov    %esi,%edx
f0104c07:	eb 09                	jmp    f0104c12 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104c09:	83 c2 01             	add    $0x1,%edx
f0104c0c:	83 c1 01             	add    $0x1,%ecx
f0104c0f:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104c12:	39 c2                	cmp    %eax,%edx
f0104c14:	74 09                	je     f0104c1f <strlcpy+0x32>
f0104c16:	0f b6 19             	movzbl (%ecx),%ebx
f0104c19:	84 db                	test   %bl,%bl
f0104c1b:	75 ec                	jne    f0104c09 <strlcpy+0x1c>
f0104c1d:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104c1f:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104c22:	29 f0                	sub    %esi,%eax
}
f0104c24:	5b                   	pop    %ebx
f0104c25:	5e                   	pop    %esi
f0104c26:	5d                   	pop    %ebp
f0104c27:	c3                   	ret    

f0104c28 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104c28:	55                   	push   %ebp
f0104c29:	89 e5                	mov    %esp,%ebp
f0104c2b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104c2e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104c31:	eb 06                	jmp    f0104c39 <strcmp+0x11>
		p++, q++;
f0104c33:	83 c1 01             	add    $0x1,%ecx
f0104c36:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104c39:	0f b6 01             	movzbl (%ecx),%eax
f0104c3c:	84 c0                	test   %al,%al
f0104c3e:	74 04                	je     f0104c44 <strcmp+0x1c>
f0104c40:	3a 02                	cmp    (%edx),%al
f0104c42:	74 ef                	je     f0104c33 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104c44:	0f b6 c0             	movzbl %al,%eax
f0104c47:	0f b6 12             	movzbl (%edx),%edx
f0104c4a:	29 d0                	sub    %edx,%eax
}
f0104c4c:	5d                   	pop    %ebp
f0104c4d:	c3                   	ret    

f0104c4e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104c4e:	55                   	push   %ebp
f0104c4f:	89 e5                	mov    %esp,%ebp
f0104c51:	53                   	push   %ebx
f0104c52:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c55:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c58:	89 c3                	mov    %eax,%ebx
f0104c5a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104c5d:	eb 06                	jmp    f0104c65 <strncmp+0x17>
		n--, p++, q++;
f0104c5f:	83 c0 01             	add    $0x1,%eax
f0104c62:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104c65:	39 d8                	cmp    %ebx,%eax
f0104c67:	74 15                	je     f0104c7e <strncmp+0x30>
f0104c69:	0f b6 08             	movzbl (%eax),%ecx
f0104c6c:	84 c9                	test   %cl,%cl
f0104c6e:	74 04                	je     f0104c74 <strncmp+0x26>
f0104c70:	3a 0a                	cmp    (%edx),%cl
f0104c72:	74 eb                	je     f0104c5f <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104c74:	0f b6 00             	movzbl (%eax),%eax
f0104c77:	0f b6 12             	movzbl (%edx),%edx
f0104c7a:	29 d0                	sub    %edx,%eax
f0104c7c:	eb 05                	jmp    f0104c83 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104c7e:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104c83:	5b                   	pop    %ebx
f0104c84:	5d                   	pop    %ebp
f0104c85:	c3                   	ret    

f0104c86 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104c86:	55                   	push   %ebp
f0104c87:	89 e5                	mov    %esp,%ebp
f0104c89:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c8c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104c90:	eb 07                	jmp    f0104c99 <strchr+0x13>
		if (*s == c)
f0104c92:	38 ca                	cmp    %cl,%dl
f0104c94:	74 0f                	je     f0104ca5 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104c96:	83 c0 01             	add    $0x1,%eax
f0104c99:	0f b6 10             	movzbl (%eax),%edx
f0104c9c:	84 d2                	test   %dl,%dl
f0104c9e:	75 f2                	jne    f0104c92 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104ca0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104ca5:	5d                   	pop    %ebp
f0104ca6:	c3                   	ret    

f0104ca7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104ca7:	55                   	push   %ebp
f0104ca8:	89 e5                	mov    %esp,%ebp
f0104caa:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cad:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104cb1:	eb 03                	jmp    f0104cb6 <strfind+0xf>
f0104cb3:	83 c0 01             	add    $0x1,%eax
f0104cb6:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104cb9:	38 ca                	cmp    %cl,%dl
f0104cbb:	74 04                	je     f0104cc1 <strfind+0x1a>
f0104cbd:	84 d2                	test   %dl,%dl
f0104cbf:	75 f2                	jne    f0104cb3 <strfind+0xc>
			break;
	return (char *) s;
}
f0104cc1:	5d                   	pop    %ebp
f0104cc2:	c3                   	ret    

f0104cc3 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104cc3:	55                   	push   %ebp
f0104cc4:	89 e5                	mov    %esp,%ebp
f0104cc6:	57                   	push   %edi
f0104cc7:	56                   	push   %esi
f0104cc8:	53                   	push   %ebx
f0104cc9:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104ccc:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104ccf:	85 c9                	test   %ecx,%ecx
f0104cd1:	74 36                	je     f0104d09 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104cd3:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104cd9:	75 28                	jne    f0104d03 <memset+0x40>
f0104cdb:	f6 c1 03             	test   $0x3,%cl
f0104cde:	75 23                	jne    f0104d03 <memset+0x40>
		c &= 0xFF;
f0104ce0:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104ce4:	89 d3                	mov    %edx,%ebx
f0104ce6:	c1 e3 08             	shl    $0x8,%ebx
f0104ce9:	89 d6                	mov    %edx,%esi
f0104ceb:	c1 e6 18             	shl    $0x18,%esi
f0104cee:	89 d0                	mov    %edx,%eax
f0104cf0:	c1 e0 10             	shl    $0x10,%eax
f0104cf3:	09 f0                	or     %esi,%eax
f0104cf5:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0104cf7:	89 d8                	mov    %ebx,%eax
f0104cf9:	09 d0                	or     %edx,%eax
f0104cfb:	c1 e9 02             	shr    $0x2,%ecx
f0104cfe:	fc                   	cld    
f0104cff:	f3 ab                	rep stos %eax,%es:(%edi)
f0104d01:	eb 06                	jmp    f0104d09 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104d03:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d06:	fc                   	cld    
f0104d07:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104d09:	89 f8                	mov    %edi,%eax
f0104d0b:	5b                   	pop    %ebx
f0104d0c:	5e                   	pop    %esi
f0104d0d:	5f                   	pop    %edi
f0104d0e:	5d                   	pop    %ebp
f0104d0f:	c3                   	ret    

f0104d10 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104d10:	55                   	push   %ebp
f0104d11:	89 e5                	mov    %esp,%ebp
f0104d13:	57                   	push   %edi
f0104d14:	56                   	push   %esi
f0104d15:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d18:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104d1b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104d1e:	39 c6                	cmp    %eax,%esi
f0104d20:	73 35                	jae    f0104d57 <memmove+0x47>
f0104d22:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104d25:	39 d0                	cmp    %edx,%eax
f0104d27:	73 2e                	jae    f0104d57 <memmove+0x47>
		s += n;
		d += n;
f0104d29:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104d2c:	89 d6                	mov    %edx,%esi
f0104d2e:	09 fe                	or     %edi,%esi
f0104d30:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104d36:	75 13                	jne    f0104d4b <memmove+0x3b>
f0104d38:	f6 c1 03             	test   $0x3,%cl
f0104d3b:	75 0e                	jne    f0104d4b <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104d3d:	83 ef 04             	sub    $0x4,%edi
f0104d40:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104d43:	c1 e9 02             	shr    $0x2,%ecx
f0104d46:	fd                   	std    
f0104d47:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104d49:	eb 09                	jmp    f0104d54 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104d4b:	83 ef 01             	sub    $0x1,%edi
f0104d4e:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104d51:	fd                   	std    
f0104d52:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104d54:	fc                   	cld    
f0104d55:	eb 1d                	jmp    f0104d74 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104d57:	89 f2                	mov    %esi,%edx
f0104d59:	09 c2                	or     %eax,%edx
f0104d5b:	f6 c2 03             	test   $0x3,%dl
f0104d5e:	75 0f                	jne    f0104d6f <memmove+0x5f>
f0104d60:	f6 c1 03             	test   $0x3,%cl
f0104d63:	75 0a                	jne    f0104d6f <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0104d65:	c1 e9 02             	shr    $0x2,%ecx
f0104d68:	89 c7                	mov    %eax,%edi
f0104d6a:	fc                   	cld    
f0104d6b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104d6d:	eb 05                	jmp    f0104d74 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104d6f:	89 c7                	mov    %eax,%edi
f0104d71:	fc                   	cld    
f0104d72:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104d74:	5e                   	pop    %esi
f0104d75:	5f                   	pop    %edi
f0104d76:	5d                   	pop    %ebp
f0104d77:	c3                   	ret    

f0104d78 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104d78:	55                   	push   %ebp
f0104d79:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104d7b:	ff 75 10             	pushl  0x10(%ebp)
f0104d7e:	ff 75 0c             	pushl  0xc(%ebp)
f0104d81:	ff 75 08             	pushl  0x8(%ebp)
f0104d84:	e8 87 ff ff ff       	call   f0104d10 <memmove>
}
f0104d89:	c9                   	leave  
f0104d8a:	c3                   	ret    

f0104d8b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104d8b:	55                   	push   %ebp
f0104d8c:	89 e5                	mov    %esp,%ebp
f0104d8e:	56                   	push   %esi
f0104d8f:	53                   	push   %ebx
f0104d90:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d93:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104d96:	89 c6                	mov    %eax,%esi
f0104d98:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104d9b:	eb 1a                	jmp    f0104db7 <memcmp+0x2c>
		if (*s1 != *s2)
f0104d9d:	0f b6 08             	movzbl (%eax),%ecx
f0104da0:	0f b6 1a             	movzbl (%edx),%ebx
f0104da3:	38 d9                	cmp    %bl,%cl
f0104da5:	74 0a                	je     f0104db1 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104da7:	0f b6 c1             	movzbl %cl,%eax
f0104daa:	0f b6 db             	movzbl %bl,%ebx
f0104dad:	29 d8                	sub    %ebx,%eax
f0104daf:	eb 0f                	jmp    f0104dc0 <memcmp+0x35>
		s1++, s2++;
f0104db1:	83 c0 01             	add    $0x1,%eax
f0104db4:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104db7:	39 f0                	cmp    %esi,%eax
f0104db9:	75 e2                	jne    f0104d9d <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104dbb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104dc0:	5b                   	pop    %ebx
f0104dc1:	5e                   	pop    %esi
f0104dc2:	5d                   	pop    %ebp
f0104dc3:	c3                   	ret    

f0104dc4 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104dc4:	55                   	push   %ebp
f0104dc5:	89 e5                	mov    %esp,%ebp
f0104dc7:	53                   	push   %ebx
f0104dc8:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104dcb:	89 c1                	mov    %eax,%ecx
f0104dcd:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104dd0:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104dd4:	eb 0a                	jmp    f0104de0 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104dd6:	0f b6 10             	movzbl (%eax),%edx
f0104dd9:	39 da                	cmp    %ebx,%edx
f0104ddb:	74 07                	je     f0104de4 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104ddd:	83 c0 01             	add    $0x1,%eax
f0104de0:	39 c8                	cmp    %ecx,%eax
f0104de2:	72 f2                	jb     f0104dd6 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104de4:	5b                   	pop    %ebx
f0104de5:	5d                   	pop    %ebp
f0104de6:	c3                   	ret    

f0104de7 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104de7:	55                   	push   %ebp
f0104de8:	89 e5                	mov    %esp,%ebp
f0104dea:	57                   	push   %edi
f0104deb:	56                   	push   %esi
f0104dec:	53                   	push   %ebx
f0104ded:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104df0:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104df3:	eb 03                	jmp    f0104df8 <strtol+0x11>
		s++;
f0104df5:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104df8:	0f b6 01             	movzbl (%ecx),%eax
f0104dfb:	3c 20                	cmp    $0x20,%al
f0104dfd:	74 f6                	je     f0104df5 <strtol+0xe>
f0104dff:	3c 09                	cmp    $0x9,%al
f0104e01:	74 f2                	je     f0104df5 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104e03:	3c 2b                	cmp    $0x2b,%al
f0104e05:	75 0a                	jne    f0104e11 <strtol+0x2a>
		s++;
f0104e07:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104e0a:	bf 00 00 00 00       	mov    $0x0,%edi
f0104e0f:	eb 11                	jmp    f0104e22 <strtol+0x3b>
f0104e11:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104e16:	3c 2d                	cmp    $0x2d,%al
f0104e18:	75 08                	jne    f0104e22 <strtol+0x3b>
		s++, neg = 1;
f0104e1a:	83 c1 01             	add    $0x1,%ecx
f0104e1d:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104e22:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104e28:	75 15                	jne    f0104e3f <strtol+0x58>
f0104e2a:	80 39 30             	cmpb   $0x30,(%ecx)
f0104e2d:	75 10                	jne    f0104e3f <strtol+0x58>
f0104e2f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104e33:	75 7c                	jne    f0104eb1 <strtol+0xca>
		s += 2, base = 16;
f0104e35:	83 c1 02             	add    $0x2,%ecx
f0104e38:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104e3d:	eb 16                	jmp    f0104e55 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104e3f:	85 db                	test   %ebx,%ebx
f0104e41:	75 12                	jne    f0104e55 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104e43:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104e48:	80 39 30             	cmpb   $0x30,(%ecx)
f0104e4b:	75 08                	jne    f0104e55 <strtol+0x6e>
		s++, base = 8;
f0104e4d:	83 c1 01             	add    $0x1,%ecx
f0104e50:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104e55:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e5a:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104e5d:	0f b6 11             	movzbl (%ecx),%edx
f0104e60:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104e63:	89 f3                	mov    %esi,%ebx
f0104e65:	80 fb 09             	cmp    $0x9,%bl
f0104e68:	77 08                	ja     f0104e72 <strtol+0x8b>
			dig = *s - '0';
f0104e6a:	0f be d2             	movsbl %dl,%edx
f0104e6d:	83 ea 30             	sub    $0x30,%edx
f0104e70:	eb 22                	jmp    f0104e94 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104e72:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104e75:	89 f3                	mov    %esi,%ebx
f0104e77:	80 fb 19             	cmp    $0x19,%bl
f0104e7a:	77 08                	ja     f0104e84 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104e7c:	0f be d2             	movsbl %dl,%edx
f0104e7f:	83 ea 57             	sub    $0x57,%edx
f0104e82:	eb 10                	jmp    f0104e94 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104e84:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104e87:	89 f3                	mov    %esi,%ebx
f0104e89:	80 fb 19             	cmp    $0x19,%bl
f0104e8c:	77 16                	ja     f0104ea4 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104e8e:	0f be d2             	movsbl %dl,%edx
f0104e91:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104e94:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104e97:	7d 0b                	jge    f0104ea4 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104e99:	83 c1 01             	add    $0x1,%ecx
f0104e9c:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104ea0:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104ea2:	eb b9                	jmp    f0104e5d <strtol+0x76>

	if (endptr)
f0104ea4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104ea8:	74 0d                	je     f0104eb7 <strtol+0xd0>
		*endptr = (char *) s;
f0104eaa:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104ead:	89 0e                	mov    %ecx,(%esi)
f0104eaf:	eb 06                	jmp    f0104eb7 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104eb1:	85 db                	test   %ebx,%ebx
f0104eb3:	74 98                	je     f0104e4d <strtol+0x66>
f0104eb5:	eb 9e                	jmp    f0104e55 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104eb7:	89 c2                	mov    %eax,%edx
f0104eb9:	f7 da                	neg    %edx
f0104ebb:	85 ff                	test   %edi,%edi
f0104ebd:	0f 45 c2             	cmovne %edx,%eax
}
f0104ec0:	5b                   	pop    %ebx
f0104ec1:	5e                   	pop    %esi
f0104ec2:	5f                   	pop    %edi
f0104ec3:	5d                   	pop    %ebp
f0104ec4:	c3                   	ret    
f0104ec5:	66 90                	xchg   %ax,%ax
f0104ec7:	90                   	nop

f0104ec8 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0104ec8:	fa                   	cli    

	xorw    %ax, %ax
f0104ec9:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0104ecb:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104ecd:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104ecf:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0104ed1:	0f 01 16             	lgdtl  (%esi)
f0104ed4:	74 70                	je     f0104f46 <mpsearch1+0x3>
	movl    %cr0, %eax
f0104ed6:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0104ed9:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0104edd:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0104ee0:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0104ee6:	08 00                	or     %al,(%eax)

f0104ee8 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0104ee8:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0104eec:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104eee:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104ef0:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0104ef2:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0104ef6:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0104ef8:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0104efa:	b8 00 d0 11 00       	mov    $0x11d000,%eax
	movl    %eax, %cr3
f0104eff:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0104f02:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0104f05:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0104f0a:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0104f0d:	8b 25 04 af 22 f0    	mov    0xf022af04,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0104f13:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0104f18:	b8 a7 01 10 f0       	mov    $0xf01001a7,%eax
	call    *%eax
f0104f1d:	ff d0                	call   *%eax

f0104f1f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0104f1f:	eb fe                	jmp    f0104f1f <spin>
f0104f21:	8d 76 00             	lea    0x0(%esi),%esi

f0104f24 <gdt>:
	...
f0104f2c:	ff                   	(bad)  
f0104f2d:	ff 00                	incl   (%eax)
f0104f2f:	00 00                	add    %al,(%eax)
f0104f31:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0104f38:	00                   	.byte 0x0
f0104f39:	92                   	xchg   %eax,%edx
f0104f3a:	cf                   	iret   
	...

f0104f3c <gdtdesc>:
f0104f3c:	17                   	pop    %ss
f0104f3d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0104f42 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0104f42:	90                   	nop

f0104f43 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0104f43:	55                   	push   %ebp
f0104f44:	89 e5                	mov    %esp,%ebp
f0104f46:	57                   	push   %edi
f0104f47:	56                   	push   %esi
f0104f48:	53                   	push   %ebx
f0104f49:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104f4c:	8b 0d 08 af 22 f0    	mov    0xf022af08,%ecx
f0104f52:	89 c3                	mov    %eax,%ebx
f0104f54:	c1 eb 0c             	shr    $0xc,%ebx
f0104f57:	39 cb                	cmp    %ecx,%ebx
f0104f59:	72 12                	jb     f0104f6d <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104f5b:	50                   	push   %eax
f0104f5c:	68 a4 59 10 f0       	push   $0xf01059a4
f0104f61:	6a 57                	push   $0x57
f0104f63:	68 45 75 10 f0       	push   $0xf0107545
f0104f68:	e8 d3 b0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104f6d:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0104f73:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104f75:	89 c2                	mov    %eax,%edx
f0104f77:	c1 ea 0c             	shr    $0xc,%edx
f0104f7a:	39 ca                	cmp    %ecx,%edx
f0104f7c:	72 12                	jb     f0104f90 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104f7e:	50                   	push   %eax
f0104f7f:	68 a4 59 10 f0       	push   $0xf01059a4
f0104f84:	6a 57                	push   $0x57
f0104f86:	68 45 75 10 f0       	push   $0xf0107545
f0104f8b:	e8 b0 b0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104f90:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0104f96:	eb 2f                	jmp    f0104fc7 <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104f98:	83 ec 04             	sub    $0x4,%esp
f0104f9b:	6a 04                	push   $0x4
f0104f9d:	68 55 75 10 f0       	push   $0xf0107555
f0104fa2:	53                   	push   %ebx
f0104fa3:	e8 e3 fd ff ff       	call   f0104d8b <memcmp>
f0104fa8:	83 c4 10             	add    $0x10,%esp
f0104fab:	85 c0                	test   %eax,%eax
f0104fad:	75 15                	jne    f0104fc4 <mpsearch1+0x81>
f0104faf:	89 da                	mov    %ebx,%edx
f0104fb1:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0104fb4:	0f b6 0a             	movzbl (%edx),%ecx
f0104fb7:	01 c8                	add    %ecx,%eax
f0104fb9:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0104fbc:	39 d7                	cmp    %edx,%edi
f0104fbe:	75 f4                	jne    f0104fb4 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104fc0:	84 c0                	test   %al,%al
f0104fc2:	74 0e                	je     f0104fd2 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0104fc4:	83 c3 10             	add    $0x10,%ebx
f0104fc7:	39 f3                	cmp    %esi,%ebx
f0104fc9:	72 cd                	jb     f0104f98 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0104fcb:	b8 00 00 00 00       	mov    $0x0,%eax
f0104fd0:	eb 02                	jmp    f0104fd4 <mpsearch1+0x91>
f0104fd2:	89 d8                	mov    %ebx,%eax
}
f0104fd4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104fd7:	5b                   	pop    %ebx
f0104fd8:	5e                   	pop    %esi
f0104fd9:	5f                   	pop    %edi
f0104fda:	5d                   	pop    %ebp
f0104fdb:	c3                   	ret    

f0104fdc <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0104fdc:	55                   	push   %ebp
f0104fdd:	89 e5                	mov    %esp,%ebp
f0104fdf:	57                   	push   %edi
f0104fe0:	56                   	push   %esi
f0104fe1:	53                   	push   %ebx
f0104fe2:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0104fe5:	c7 05 c0 b3 22 f0 20 	movl   $0xf022b020,0xf022b3c0
f0104fec:	b0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104fef:	83 3d 08 af 22 f0 00 	cmpl   $0x0,0xf022af08
f0104ff6:	75 16                	jne    f010500e <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104ff8:	68 00 04 00 00       	push   $0x400
f0104ffd:	68 a4 59 10 f0       	push   $0xf01059a4
f0105002:	6a 6f                	push   $0x6f
f0105004:	68 45 75 10 f0       	push   $0xf0107545
f0105009:	e8 32 b0 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f010500e:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105015:	85 c0                	test   %eax,%eax
f0105017:	74 16                	je     f010502f <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f0105019:	c1 e0 04             	shl    $0x4,%eax
f010501c:	ba 00 04 00 00       	mov    $0x400,%edx
f0105021:	e8 1d ff ff ff       	call   f0104f43 <mpsearch1>
f0105026:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105029:	85 c0                	test   %eax,%eax
f010502b:	75 3c                	jne    f0105069 <mp_init+0x8d>
f010502d:	eb 20                	jmp    f010504f <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f010502f:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105036:	c1 e0 0a             	shl    $0xa,%eax
f0105039:	2d 00 04 00 00       	sub    $0x400,%eax
f010503e:	ba 00 04 00 00       	mov    $0x400,%edx
f0105043:	e8 fb fe ff ff       	call   f0104f43 <mpsearch1>
f0105048:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010504b:	85 c0                	test   %eax,%eax
f010504d:	75 1a                	jne    f0105069 <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f010504f:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105054:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105059:	e8 e5 fe ff ff       	call   f0104f43 <mpsearch1>
f010505e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105061:	85 c0                	test   %eax,%eax
f0105063:	0f 84 5d 02 00 00    	je     f01052c6 <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0105069:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010506c:	8b 70 04             	mov    0x4(%eax),%esi
f010506f:	85 f6                	test   %esi,%esi
f0105071:	74 06                	je     f0105079 <mp_init+0x9d>
f0105073:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105077:	74 15                	je     f010508e <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f0105079:	83 ec 0c             	sub    $0xc,%esp
f010507c:	68 b8 73 10 f0       	push   $0xf01073b8
f0105081:	e8 c2 e6 ff ff       	call   f0103748 <cprintf>
f0105086:	83 c4 10             	add    $0x10,%esp
f0105089:	e9 38 02 00 00       	jmp    f01052c6 <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010508e:	89 f0                	mov    %esi,%eax
f0105090:	c1 e8 0c             	shr    $0xc,%eax
f0105093:	3b 05 08 af 22 f0    	cmp    0xf022af08,%eax
f0105099:	72 15                	jb     f01050b0 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010509b:	56                   	push   %esi
f010509c:	68 a4 59 10 f0       	push   $0xf01059a4
f01050a1:	68 90 00 00 00       	push   $0x90
f01050a6:	68 45 75 10 f0       	push   $0xf0107545
f01050ab:	e8 90 af ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01050b0:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f01050b6:	83 ec 04             	sub    $0x4,%esp
f01050b9:	6a 04                	push   $0x4
f01050bb:	68 5a 75 10 f0       	push   $0xf010755a
f01050c0:	53                   	push   %ebx
f01050c1:	e8 c5 fc ff ff       	call   f0104d8b <memcmp>
f01050c6:	83 c4 10             	add    $0x10,%esp
f01050c9:	85 c0                	test   %eax,%eax
f01050cb:	74 15                	je     f01050e2 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01050cd:	83 ec 0c             	sub    $0xc,%esp
f01050d0:	68 e8 73 10 f0       	push   $0xf01073e8
f01050d5:	e8 6e e6 ff ff       	call   f0103748 <cprintf>
f01050da:	83 c4 10             	add    $0x10,%esp
f01050dd:	e9 e4 01 00 00       	jmp    f01052c6 <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01050e2:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f01050e6:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f01050ea:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01050ed:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01050f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01050f7:	eb 0d                	jmp    f0105106 <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f01050f9:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105100:	f0 
f0105101:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105103:	83 c0 01             	add    $0x1,%eax
f0105106:	39 c7                	cmp    %eax,%edi
f0105108:	75 ef                	jne    f01050f9 <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010510a:	84 d2                	test   %dl,%dl
f010510c:	74 15                	je     f0105123 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f010510e:	83 ec 0c             	sub    $0xc,%esp
f0105111:	68 1c 74 10 f0       	push   $0xf010741c
f0105116:	e8 2d e6 ff ff       	call   f0103748 <cprintf>
f010511b:	83 c4 10             	add    $0x10,%esp
f010511e:	e9 a3 01 00 00       	jmp    f01052c6 <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105123:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105127:	3c 01                	cmp    $0x1,%al
f0105129:	74 1d                	je     f0105148 <mp_init+0x16c>
f010512b:	3c 04                	cmp    $0x4,%al
f010512d:	74 19                	je     f0105148 <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f010512f:	83 ec 08             	sub    $0x8,%esp
f0105132:	0f b6 c0             	movzbl %al,%eax
f0105135:	50                   	push   %eax
f0105136:	68 40 74 10 f0       	push   $0xf0107440
f010513b:	e8 08 e6 ff ff       	call   f0103748 <cprintf>
f0105140:	83 c4 10             	add    $0x10,%esp
f0105143:	e9 7e 01 00 00       	jmp    f01052c6 <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105148:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f010514c:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105150:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105155:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f010515a:	01 ce                	add    %ecx,%esi
f010515c:	eb 0d                	jmp    f010516b <mp_init+0x18f>
f010515e:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f0105165:	f0 
f0105166:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105168:	83 c0 01             	add    $0x1,%eax
f010516b:	39 c7                	cmp    %eax,%edi
f010516d:	75 ef                	jne    f010515e <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010516f:	89 d0                	mov    %edx,%eax
f0105171:	02 43 2a             	add    0x2a(%ebx),%al
f0105174:	74 15                	je     f010518b <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105176:	83 ec 0c             	sub    $0xc,%esp
f0105179:	68 60 74 10 f0       	push   $0xf0107460
f010517e:	e8 c5 e5 ff ff       	call   f0103748 <cprintf>
f0105183:	83 c4 10             	add    $0x10,%esp
f0105186:	e9 3b 01 00 00       	jmp    f01052c6 <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f010518b:	85 db                	test   %ebx,%ebx
f010518d:	0f 84 33 01 00 00    	je     f01052c6 <mp_init+0x2ea>
		return;
	ismp = 1;
f0105193:	c7 05 00 b0 22 f0 01 	movl   $0x1,0xf022b000
f010519a:	00 00 00 
	lapicaddr = conf->lapicaddr;
f010519d:	8b 43 24             	mov    0x24(%ebx),%eax
f01051a0:	a3 00 c0 26 f0       	mov    %eax,0xf026c000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01051a5:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f01051a8:	be 00 00 00 00       	mov    $0x0,%esi
f01051ad:	e9 85 00 00 00       	jmp    f0105237 <mp_init+0x25b>
		switch (*p) {
f01051b2:	0f b6 07             	movzbl (%edi),%eax
f01051b5:	84 c0                	test   %al,%al
f01051b7:	74 06                	je     f01051bf <mp_init+0x1e3>
f01051b9:	3c 04                	cmp    $0x4,%al
f01051bb:	77 55                	ja     f0105212 <mp_init+0x236>
f01051bd:	eb 4e                	jmp    f010520d <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01051bf:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01051c3:	74 11                	je     f01051d6 <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f01051c5:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f01051cc:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01051d1:	a3 c0 b3 22 f0       	mov    %eax,0xf022b3c0
			if (ncpu < NCPU) {
f01051d6:	a1 c4 b3 22 f0       	mov    0xf022b3c4,%eax
f01051db:	83 f8 07             	cmp    $0x7,%eax
f01051de:	7f 13                	jg     f01051f3 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f01051e0:	6b d0 74             	imul   $0x74,%eax,%edx
f01051e3:	88 82 20 b0 22 f0    	mov    %al,-0xfdd4fe0(%edx)
				ncpu++;
f01051e9:	83 c0 01             	add    $0x1,%eax
f01051ec:	a3 c4 b3 22 f0       	mov    %eax,0xf022b3c4
f01051f1:	eb 15                	jmp    f0105208 <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01051f3:	83 ec 08             	sub    $0x8,%esp
f01051f6:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f01051fa:	50                   	push   %eax
f01051fb:	68 90 74 10 f0       	push   $0xf0107490
f0105200:	e8 43 e5 ff ff       	call   f0103748 <cprintf>
f0105205:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105208:	83 c7 14             	add    $0x14,%edi
			continue;
f010520b:	eb 27                	jmp    f0105234 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f010520d:	83 c7 08             	add    $0x8,%edi
			continue;
f0105210:	eb 22                	jmp    f0105234 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105212:	83 ec 08             	sub    $0x8,%esp
f0105215:	0f b6 c0             	movzbl %al,%eax
f0105218:	50                   	push   %eax
f0105219:	68 b8 74 10 f0       	push   $0xf01074b8
f010521e:	e8 25 e5 ff ff       	call   f0103748 <cprintf>
			ismp = 0;
f0105223:	c7 05 00 b0 22 f0 00 	movl   $0x0,0xf022b000
f010522a:	00 00 00 
			i = conf->entry;
f010522d:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105231:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105234:	83 c6 01             	add    $0x1,%esi
f0105237:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f010523b:	39 c6                	cmp    %eax,%esi
f010523d:	0f 82 6f ff ff ff    	jb     f01051b2 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105243:	a1 c0 b3 22 f0       	mov    0xf022b3c0,%eax
f0105248:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f010524f:	83 3d 00 b0 22 f0 00 	cmpl   $0x0,0xf022b000
f0105256:	75 26                	jne    f010527e <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105258:	c7 05 c4 b3 22 f0 01 	movl   $0x1,0xf022b3c4
f010525f:	00 00 00 
		lapicaddr = 0;
f0105262:	c7 05 00 c0 26 f0 00 	movl   $0x0,0xf026c000
f0105269:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f010526c:	83 ec 0c             	sub    $0xc,%esp
f010526f:	68 d8 74 10 f0       	push   $0xf01074d8
f0105274:	e8 cf e4 ff ff       	call   f0103748 <cprintf>
		return;
f0105279:	83 c4 10             	add    $0x10,%esp
f010527c:	eb 48                	jmp    f01052c6 <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f010527e:	83 ec 04             	sub    $0x4,%esp
f0105281:	ff 35 c4 b3 22 f0    	pushl  0xf022b3c4
f0105287:	0f b6 00             	movzbl (%eax),%eax
f010528a:	50                   	push   %eax
f010528b:	68 5f 75 10 f0       	push   $0xf010755f
f0105290:	e8 b3 e4 ff ff       	call   f0103748 <cprintf>

	if (mp->imcrp) {
f0105295:	83 c4 10             	add    $0x10,%esp
f0105298:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010529b:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f010529f:	74 25                	je     f01052c6 <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f01052a1:	83 ec 0c             	sub    $0xc,%esp
f01052a4:	68 04 75 10 f0       	push   $0xf0107504
f01052a9:	e8 9a e4 ff ff       	call   f0103748 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01052ae:	ba 22 00 00 00       	mov    $0x22,%edx
f01052b3:	b8 70 00 00 00       	mov    $0x70,%eax
f01052b8:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01052b9:	ba 23 00 00 00       	mov    $0x23,%edx
f01052be:	ec                   	in     (%dx),%al
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01052bf:	83 c8 01             	or     $0x1,%eax
f01052c2:	ee                   	out    %al,(%dx)
f01052c3:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f01052c6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01052c9:	5b                   	pop    %ebx
f01052ca:	5e                   	pop    %esi
f01052cb:	5f                   	pop    %edi
f01052cc:	5d                   	pop    %ebp
f01052cd:	c3                   	ret    

f01052ce <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01052ce:	55                   	push   %ebp
f01052cf:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01052d1:	8b 0d 04 c0 26 f0    	mov    0xf026c004,%ecx
f01052d7:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01052da:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01052dc:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f01052e1:	8b 40 20             	mov    0x20(%eax),%eax
}
f01052e4:	5d                   	pop    %ebp
f01052e5:	c3                   	ret    

f01052e6 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01052e6:	55                   	push   %ebp
f01052e7:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01052e9:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f01052ee:	85 c0                	test   %eax,%eax
f01052f0:	74 08                	je     f01052fa <cpunum+0x14>
		return lapic[ID] >> 24;
f01052f2:	8b 40 20             	mov    0x20(%eax),%eax
f01052f5:	c1 e8 18             	shr    $0x18,%eax
f01052f8:	eb 05                	jmp    f01052ff <cpunum+0x19>
	return 0;
f01052fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01052ff:	5d                   	pop    %ebp
f0105300:	c3                   	ret    

f0105301 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105301:	a1 00 c0 26 f0       	mov    0xf026c000,%eax
f0105306:	85 c0                	test   %eax,%eax
f0105308:	0f 84 21 01 00 00    	je     f010542f <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f010530e:	55                   	push   %ebp
f010530f:	89 e5                	mov    %esp,%ebp
f0105311:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105314:	68 00 10 00 00       	push   $0x1000
f0105319:	50                   	push   %eax
f010531a:	e8 83 bf ff ff       	call   f01012a2 <mmio_map_region>
f010531f:	a3 04 c0 26 f0       	mov    %eax,0xf026c004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105324:	ba 27 01 00 00       	mov    $0x127,%edx
f0105329:	b8 3c 00 00 00       	mov    $0x3c,%eax
f010532e:	e8 9b ff ff ff       	call   f01052ce <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105333:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105338:	b8 f8 00 00 00       	mov    $0xf8,%eax
f010533d:	e8 8c ff ff ff       	call   f01052ce <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105342:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105347:	b8 c8 00 00 00       	mov    $0xc8,%eax
f010534c:	e8 7d ff ff ff       	call   f01052ce <lapicw>
	lapicw(TICR, 10000000); 
f0105351:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105356:	b8 e0 00 00 00       	mov    $0xe0,%eax
f010535b:	e8 6e ff ff ff       	call   f01052ce <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105360:	e8 81 ff ff ff       	call   f01052e6 <cpunum>
f0105365:	6b c0 74             	imul   $0x74,%eax,%eax
f0105368:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f010536d:	83 c4 10             	add    $0x10,%esp
f0105370:	39 05 c0 b3 22 f0    	cmp    %eax,0xf022b3c0
f0105376:	74 0f                	je     f0105387 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105378:	ba 00 00 01 00       	mov    $0x10000,%edx
f010537d:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105382:	e8 47 ff ff ff       	call   f01052ce <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105387:	ba 00 00 01 00       	mov    $0x10000,%edx
f010538c:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105391:	e8 38 ff ff ff       	call   f01052ce <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105396:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f010539b:	8b 40 30             	mov    0x30(%eax),%eax
f010539e:	c1 e8 10             	shr    $0x10,%eax
f01053a1:	3c 03                	cmp    $0x3,%al
f01053a3:	76 0f                	jbe    f01053b4 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f01053a5:	ba 00 00 01 00       	mov    $0x10000,%edx
f01053aa:	b8 d0 00 00 00       	mov    $0xd0,%eax
f01053af:	e8 1a ff ff ff       	call   f01052ce <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f01053b4:	ba 33 00 00 00       	mov    $0x33,%edx
f01053b9:	b8 dc 00 00 00       	mov    $0xdc,%eax
f01053be:	e8 0b ff ff ff       	call   f01052ce <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f01053c3:	ba 00 00 00 00       	mov    $0x0,%edx
f01053c8:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01053cd:	e8 fc fe ff ff       	call   f01052ce <lapicw>
	lapicw(ESR, 0);
f01053d2:	ba 00 00 00 00       	mov    $0x0,%edx
f01053d7:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01053dc:	e8 ed fe ff ff       	call   f01052ce <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f01053e1:	ba 00 00 00 00       	mov    $0x0,%edx
f01053e6:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01053eb:	e8 de fe ff ff       	call   f01052ce <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f01053f0:	ba 00 00 00 00       	mov    $0x0,%edx
f01053f5:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01053fa:	e8 cf fe ff ff       	call   f01052ce <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f01053ff:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105404:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105409:	e8 c0 fe ff ff       	call   f01052ce <lapicw>
	while(lapic[ICRLO] & DELIVS)
f010540e:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f0105414:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010541a:	f6 c4 10             	test   $0x10,%ah
f010541d:	75 f5                	jne    f0105414 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f010541f:	ba 00 00 00 00       	mov    $0x0,%edx
f0105424:	b8 20 00 00 00       	mov    $0x20,%eax
f0105429:	e8 a0 fe ff ff       	call   f01052ce <lapicw>
}
f010542e:	c9                   	leave  
f010542f:	f3 c3                	repz ret 

f0105431 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105431:	83 3d 04 c0 26 f0 00 	cmpl   $0x0,0xf026c004
f0105438:	74 13                	je     f010544d <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010543a:	55                   	push   %ebp
f010543b:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f010543d:	ba 00 00 00 00       	mov    $0x0,%edx
f0105442:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105447:	e8 82 fe ff ff       	call   f01052ce <lapicw>
}
f010544c:	5d                   	pop    %ebp
f010544d:	f3 c3                	repz ret 

f010544f <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f010544f:	55                   	push   %ebp
f0105450:	89 e5                	mov    %esp,%ebp
f0105452:	56                   	push   %esi
f0105453:	53                   	push   %ebx
f0105454:	8b 75 08             	mov    0x8(%ebp),%esi
f0105457:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010545a:	ba 70 00 00 00       	mov    $0x70,%edx
f010545f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105464:	ee                   	out    %al,(%dx)
f0105465:	ba 71 00 00 00       	mov    $0x71,%edx
f010546a:	b8 0a 00 00 00       	mov    $0xa,%eax
f010546f:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105470:	83 3d 08 af 22 f0 00 	cmpl   $0x0,0xf022af08
f0105477:	75 19                	jne    f0105492 <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105479:	68 67 04 00 00       	push   $0x467
f010547e:	68 a4 59 10 f0       	push   $0xf01059a4
f0105483:	68 98 00 00 00       	push   $0x98
f0105488:	68 7c 75 10 f0       	push   $0xf010757c
f010548d:	e8 ae ab ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105492:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105499:	00 00 
	wrv[1] = addr >> 4;
f010549b:	89 d8                	mov    %ebx,%eax
f010549d:	c1 e8 04             	shr    $0x4,%eax
f01054a0:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f01054a6:	c1 e6 18             	shl    $0x18,%esi
f01054a9:	89 f2                	mov    %esi,%edx
f01054ab:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01054b0:	e8 19 fe ff ff       	call   f01052ce <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f01054b5:	ba 00 c5 00 00       	mov    $0xc500,%edx
f01054ba:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01054bf:	e8 0a fe ff ff       	call   f01052ce <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f01054c4:	ba 00 85 00 00       	mov    $0x8500,%edx
f01054c9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01054ce:	e8 fb fd ff ff       	call   f01052ce <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01054d3:	c1 eb 0c             	shr    $0xc,%ebx
f01054d6:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01054d9:	89 f2                	mov    %esi,%edx
f01054db:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01054e0:	e8 e9 fd ff ff       	call   f01052ce <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01054e5:	89 da                	mov    %ebx,%edx
f01054e7:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01054ec:	e8 dd fd ff ff       	call   f01052ce <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01054f1:	89 f2                	mov    %esi,%edx
f01054f3:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01054f8:	e8 d1 fd ff ff       	call   f01052ce <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01054fd:	89 da                	mov    %ebx,%edx
f01054ff:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105504:	e8 c5 fd ff ff       	call   f01052ce <lapicw>
		microdelay(200);
	}
}
f0105509:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010550c:	5b                   	pop    %ebx
f010550d:	5e                   	pop    %esi
f010550e:	5d                   	pop    %ebp
f010550f:	c3                   	ret    

f0105510 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105510:	55                   	push   %ebp
f0105511:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105513:	8b 55 08             	mov    0x8(%ebp),%edx
f0105516:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f010551c:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105521:	e8 a8 fd ff ff       	call   f01052ce <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105526:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f010552c:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105532:	f6 c4 10             	test   $0x10,%ah
f0105535:	75 f5                	jne    f010552c <lapic_ipi+0x1c>
		;
}
f0105537:	5d                   	pop    %ebp
f0105538:	c3                   	ret    

f0105539 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105539:	55                   	push   %ebp
f010553a:	89 e5                	mov    %esp,%ebp
f010553c:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f010553f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105545:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105548:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f010554b:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105552:	5d                   	pop    %ebp
f0105553:	c3                   	ret    

f0105554 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105554:	55                   	push   %ebp
f0105555:	89 e5                	mov    %esp,%ebp
f0105557:	56                   	push   %esi
f0105558:	53                   	push   %ebx
f0105559:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f010555c:	83 3b 00             	cmpl   $0x0,(%ebx)
f010555f:	74 14                	je     f0105575 <spin_lock+0x21>
f0105561:	8b 73 08             	mov    0x8(%ebx),%esi
f0105564:	e8 7d fd ff ff       	call   f01052e6 <cpunum>
f0105569:	6b c0 74             	imul   $0x74,%eax,%eax
f010556c:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105571:	39 c6                	cmp    %eax,%esi
f0105573:	74 07                	je     f010557c <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0105575:	ba 01 00 00 00       	mov    $0x1,%edx
f010557a:	eb 20                	jmp    f010559c <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f010557c:	8b 5b 04             	mov    0x4(%ebx),%ebx
f010557f:	e8 62 fd ff ff       	call   f01052e6 <cpunum>
f0105584:	83 ec 0c             	sub    $0xc,%esp
f0105587:	53                   	push   %ebx
f0105588:	50                   	push   %eax
f0105589:	68 8c 75 10 f0       	push   $0xf010758c
f010558e:	6a 41                	push   $0x41
f0105590:	68 f0 75 10 f0       	push   $0xf01075f0
f0105595:	e8 a6 aa ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f010559a:	f3 90                	pause  
f010559c:	89 d0                	mov    %edx,%eax
f010559e:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f01055a1:	85 c0                	test   %eax,%eax
f01055a3:	75 f5                	jne    f010559a <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f01055a5:	e8 3c fd ff ff       	call   f01052e6 <cpunum>
f01055aa:	6b c0 74             	imul   $0x74,%eax,%eax
f01055ad:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01055b2:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f01055b5:	83 c3 0c             	add    $0xc,%ebx

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01055b8:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01055ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01055bf:	eb 0b                	jmp    f01055cc <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f01055c1:	8b 4a 04             	mov    0x4(%edx),%ecx
f01055c4:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f01055c7:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01055c9:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f01055cc:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f01055d2:	76 11                	jbe    f01055e5 <spin_lock+0x91>
f01055d4:	83 f8 09             	cmp    $0x9,%eax
f01055d7:	7e e8                	jle    f01055c1 <spin_lock+0x6d>
f01055d9:	eb 0a                	jmp    f01055e5 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f01055db:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f01055e2:	83 c0 01             	add    $0x1,%eax
f01055e5:	83 f8 09             	cmp    $0x9,%eax
f01055e8:	7e f1                	jle    f01055db <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f01055ea:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01055ed:	5b                   	pop    %ebx
f01055ee:	5e                   	pop    %esi
f01055ef:	5d                   	pop    %ebp
f01055f0:	c3                   	ret    

f01055f1 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f01055f1:	55                   	push   %ebp
f01055f2:	89 e5                	mov    %esp,%ebp
f01055f4:	57                   	push   %edi
f01055f5:	56                   	push   %esi
f01055f6:	53                   	push   %ebx
f01055f7:	83 ec 4c             	sub    $0x4c,%esp
f01055fa:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f01055fd:	83 3e 00             	cmpl   $0x0,(%esi)
f0105600:	74 18                	je     f010561a <spin_unlock+0x29>
f0105602:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105605:	e8 dc fc ff ff       	call   f01052e6 <cpunum>
f010560a:	6b c0 74             	imul   $0x74,%eax,%eax
f010560d:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105612:	39 c3                	cmp    %eax,%ebx
f0105614:	0f 84 a5 00 00 00    	je     f01056bf <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f010561a:	83 ec 04             	sub    $0x4,%esp
f010561d:	6a 28                	push   $0x28
f010561f:	8d 46 0c             	lea    0xc(%esi),%eax
f0105622:	50                   	push   %eax
f0105623:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105626:	53                   	push   %ebx
f0105627:	e8 e4 f6 ff ff       	call   f0104d10 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f010562c:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f010562f:	0f b6 38             	movzbl (%eax),%edi
f0105632:	8b 76 04             	mov    0x4(%esi),%esi
f0105635:	e8 ac fc ff ff       	call   f01052e6 <cpunum>
f010563a:	57                   	push   %edi
f010563b:	56                   	push   %esi
f010563c:	50                   	push   %eax
f010563d:	68 b8 75 10 f0       	push   $0xf01075b8
f0105642:	e8 01 e1 ff ff       	call   f0103748 <cprintf>
f0105647:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f010564a:	8d 7d a8             	lea    -0x58(%ebp),%edi
f010564d:	eb 54                	jmp    f01056a3 <spin_unlock+0xb2>
f010564f:	83 ec 08             	sub    $0x8,%esp
f0105652:	57                   	push   %edi
f0105653:	50                   	push   %eax
f0105654:	e8 35 ec ff ff       	call   f010428e <debuginfo_eip>
f0105659:	83 c4 10             	add    $0x10,%esp
f010565c:	85 c0                	test   %eax,%eax
f010565e:	78 27                	js     f0105687 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105660:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105662:	83 ec 04             	sub    $0x4,%esp
f0105665:	89 c2                	mov    %eax,%edx
f0105667:	2b 55 b8             	sub    -0x48(%ebp),%edx
f010566a:	52                   	push   %edx
f010566b:	ff 75 b0             	pushl  -0x50(%ebp)
f010566e:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105671:	ff 75 ac             	pushl  -0x54(%ebp)
f0105674:	ff 75 a8             	pushl  -0x58(%ebp)
f0105677:	50                   	push   %eax
f0105678:	68 00 76 10 f0       	push   $0xf0107600
f010567d:	e8 c6 e0 ff ff       	call   f0103748 <cprintf>
f0105682:	83 c4 20             	add    $0x20,%esp
f0105685:	eb 12                	jmp    f0105699 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105687:	83 ec 08             	sub    $0x8,%esp
f010568a:	ff 36                	pushl  (%esi)
f010568c:	68 17 76 10 f0       	push   $0xf0107617
f0105691:	e8 b2 e0 ff ff       	call   f0103748 <cprintf>
f0105696:	83 c4 10             	add    $0x10,%esp
f0105699:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f010569c:	8d 45 e8             	lea    -0x18(%ebp),%eax
f010569f:	39 c3                	cmp    %eax,%ebx
f01056a1:	74 08                	je     f01056ab <spin_unlock+0xba>
f01056a3:	89 de                	mov    %ebx,%esi
f01056a5:	8b 03                	mov    (%ebx),%eax
f01056a7:	85 c0                	test   %eax,%eax
f01056a9:	75 a4                	jne    f010564f <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f01056ab:	83 ec 04             	sub    $0x4,%esp
f01056ae:	68 1f 76 10 f0       	push   $0xf010761f
f01056b3:	6a 67                	push   $0x67
f01056b5:	68 f0 75 10 f0       	push   $0xf01075f0
f01056ba:	e8 81 a9 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f01056bf:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f01056c6:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f01056cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01056d2:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f01056d5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01056d8:	5b                   	pop    %ebx
f01056d9:	5e                   	pop    %esi
f01056da:	5f                   	pop    %edi
f01056db:	5d                   	pop    %ebp
f01056dc:	c3                   	ret    
f01056dd:	66 90                	xchg   %ax,%ax
f01056df:	90                   	nop

f01056e0 <__udivdi3>:
f01056e0:	55                   	push   %ebp
f01056e1:	57                   	push   %edi
f01056e2:	56                   	push   %esi
f01056e3:	53                   	push   %ebx
f01056e4:	83 ec 1c             	sub    $0x1c,%esp
f01056e7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01056eb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01056ef:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01056f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01056f7:	85 f6                	test   %esi,%esi
f01056f9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01056fd:	89 ca                	mov    %ecx,%edx
f01056ff:	89 f8                	mov    %edi,%eax
f0105701:	75 3d                	jne    f0105740 <__udivdi3+0x60>
f0105703:	39 cf                	cmp    %ecx,%edi
f0105705:	0f 87 c5 00 00 00    	ja     f01057d0 <__udivdi3+0xf0>
f010570b:	85 ff                	test   %edi,%edi
f010570d:	89 fd                	mov    %edi,%ebp
f010570f:	75 0b                	jne    f010571c <__udivdi3+0x3c>
f0105711:	b8 01 00 00 00       	mov    $0x1,%eax
f0105716:	31 d2                	xor    %edx,%edx
f0105718:	f7 f7                	div    %edi
f010571a:	89 c5                	mov    %eax,%ebp
f010571c:	89 c8                	mov    %ecx,%eax
f010571e:	31 d2                	xor    %edx,%edx
f0105720:	f7 f5                	div    %ebp
f0105722:	89 c1                	mov    %eax,%ecx
f0105724:	89 d8                	mov    %ebx,%eax
f0105726:	89 cf                	mov    %ecx,%edi
f0105728:	f7 f5                	div    %ebp
f010572a:	89 c3                	mov    %eax,%ebx
f010572c:	89 d8                	mov    %ebx,%eax
f010572e:	89 fa                	mov    %edi,%edx
f0105730:	83 c4 1c             	add    $0x1c,%esp
f0105733:	5b                   	pop    %ebx
f0105734:	5e                   	pop    %esi
f0105735:	5f                   	pop    %edi
f0105736:	5d                   	pop    %ebp
f0105737:	c3                   	ret    
f0105738:	90                   	nop
f0105739:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105740:	39 ce                	cmp    %ecx,%esi
f0105742:	77 74                	ja     f01057b8 <__udivdi3+0xd8>
f0105744:	0f bd fe             	bsr    %esi,%edi
f0105747:	83 f7 1f             	xor    $0x1f,%edi
f010574a:	0f 84 98 00 00 00    	je     f01057e8 <__udivdi3+0x108>
f0105750:	bb 20 00 00 00       	mov    $0x20,%ebx
f0105755:	89 f9                	mov    %edi,%ecx
f0105757:	89 c5                	mov    %eax,%ebp
f0105759:	29 fb                	sub    %edi,%ebx
f010575b:	d3 e6                	shl    %cl,%esi
f010575d:	89 d9                	mov    %ebx,%ecx
f010575f:	d3 ed                	shr    %cl,%ebp
f0105761:	89 f9                	mov    %edi,%ecx
f0105763:	d3 e0                	shl    %cl,%eax
f0105765:	09 ee                	or     %ebp,%esi
f0105767:	89 d9                	mov    %ebx,%ecx
f0105769:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010576d:	89 d5                	mov    %edx,%ebp
f010576f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105773:	d3 ed                	shr    %cl,%ebp
f0105775:	89 f9                	mov    %edi,%ecx
f0105777:	d3 e2                	shl    %cl,%edx
f0105779:	89 d9                	mov    %ebx,%ecx
f010577b:	d3 e8                	shr    %cl,%eax
f010577d:	09 c2                	or     %eax,%edx
f010577f:	89 d0                	mov    %edx,%eax
f0105781:	89 ea                	mov    %ebp,%edx
f0105783:	f7 f6                	div    %esi
f0105785:	89 d5                	mov    %edx,%ebp
f0105787:	89 c3                	mov    %eax,%ebx
f0105789:	f7 64 24 0c          	mull   0xc(%esp)
f010578d:	39 d5                	cmp    %edx,%ebp
f010578f:	72 10                	jb     f01057a1 <__udivdi3+0xc1>
f0105791:	8b 74 24 08          	mov    0x8(%esp),%esi
f0105795:	89 f9                	mov    %edi,%ecx
f0105797:	d3 e6                	shl    %cl,%esi
f0105799:	39 c6                	cmp    %eax,%esi
f010579b:	73 07                	jae    f01057a4 <__udivdi3+0xc4>
f010579d:	39 d5                	cmp    %edx,%ebp
f010579f:	75 03                	jne    f01057a4 <__udivdi3+0xc4>
f01057a1:	83 eb 01             	sub    $0x1,%ebx
f01057a4:	31 ff                	xor    %edi,%edi
f01057a6:	89 d8                	mov    %ebx,%eax
f01057a8:	89 fa                	mov    %edi,%edx
f01057aa:	83 c4 1c             	add    $0x1c,%esp
f01057ad:	5b                   	pop    %ebx
f01057ae:	5e                   	pop    %esi
f01057af:	5f                   	pop    %edi
f01057b0:	5d                   	pop    %ebp
f01057b1:	c3                   	ret    
f01057b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01057b8:	31 ff                	xor    %edi,%edi
f01057ba:	31 db                	xor    %ebx,%ebx
f01057bc:	89 d8                	mov    %ebx,%eax
f01057be:	89 fa                	mov    %edi,%edx
f01057c0:	83 c4 1c             	add    $0x1c,%esp
f01057c3:	5b                   	pop    %ebx
f01057c4:	5e                   	pop    %esi
f01057c5:	5f                   	pop    %edi
f01057c6:	5d                   	pop    %ebp
f01057c7:	c3                   	ret    
f01057c8:	90                   	nop
f01057c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01057d0:	89 d8                	mov    %ebx,%eax
f01057d2:	f7 f7                	div    %edi
f01057d4:	31 ff                	xor    %edi,%edi
f01057d6:	89 c3                	mov    %eax,%ebx
f01057d8:	89 d8                	mov    %ebx,%eax
f01057da:	89 fa                	mov    %edi,%edx
f01057dc:	83 c4 1c             	add    $0x1c,%esp
f01057df:	5b                   	pop    %ebx
f01057e0:	5e                   	pop    %esi
f01057e1:	5f                   	pop    %edi
f01057e2:	5d                   	pop    %ebp
f01057e3:	c3                   	ret    
f01057e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01057e8:	39 ce                	cmp    %ecx,%esi
f01057ea:	72 0c                	jb     f01057f8 <__udivdi3+0x118>
f01057ec:	31 db                	xor    %ebx,%ebx
f01057ee:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01057f2:	0f 87 34 ff ff ff    	ja     f010572c <__udivdi3+0x4c>
f01057f8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01057fd:	e9 2a ff ff ff       	jmp    f010572c <__udivdi3+0x4c>
f0105802:	66 90                	xchg   %ax,%ax
f0105804:	66 90                	xchg   %ax,%ax
f0105806:	66 90                	xchg   %ax,%ax
f0105808:	66 90                	xchg   %ax,%ax
f010580a:	66 90                	xchg   %ax,%ax
f010580c:	66 90                	xchg   %ax,%ax
f010580e:	66 90                	xchg   %ax,%ax

f0105810 <__umoddi3>:
f0105810:	55                   	push   %ebp
f0105811:	57                   	push   %edi
f0105812:	56                   	push   %esi
f0105813:	53                   	push   %ebx
f0105814:	83 ec 1c             	sub    $0x1c,%esp
f0105817:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010581b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010581f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105823:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105827:	85 d2                	test   %edx,%edx
f0105829:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010582d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105831:	89 f3                	mov    %esi,%ebx
f0105833:	89 3c 24             	mov    %edi,(%esp)
f0105836:	89 74 24 04          	mov    %esi,0x4(%esp)
f010583a:	75 1c                	jne    f0105858 <__umoddi3+0x48>
f010583c:	39 f7                	cmp    %esi,%edi
f010583e:	76 50                	jbe    f0105890 <__umoddi3+0x80>
f0105840:	89 c8                	mov    %ecx,%eax
f0105842:	89 f2                	mov    %esi,%edx
f0105844:	f7 f7                	div    %edi
f0105846:	89 d0                	mov    %edx,%eax
f0105848:	31 d2                	xor    %edx,%edx
f010584a:	83 c4 1c             	add    $0x1c,%esp
f010584d:	5b                   	pop    %ebx
f010584e:	5e                   	pop    %esi
f010584f:	5f                   	pop    %edi
f0105850:	5d                   	pop    %ebp
f0105851:	c3                   	ret    
f0105852:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105858:	39 f2                	cmp    %esi,%edx
f010585a:	89 d0                	mov    %edx,%eax
f010585c:	77 52                	ja     f01058b0 <__umoddi3+0xa0>
f010585e:	0f bd ea             	bsr    %edx,%ebp
f0105861:	83 f5 1f             	xor    $0x1f,%ebp
f0105864:	75 5a                	jne    f01058c0 <__umoddi3+0xb0>
f0105866:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010586a:	0f 82 e0 00 00 00    	jb     f0105950 <__umoddi3+0x140>
f0105870:	39 0c 24             	cmp    %ecx,(%esp)
f0105873:	0f 86 d7 00 00 00    	jbe    f0105950 <__umoddi3+0x140>
f0105879:	8b 44 24 08          	mov    0x8(%esp),%eax
f010587d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105881:	83 c4 1c             	add    $0x1c,%esp
f0105884:	5b                   	pop    %ebx
f0105885:	5e                   	pop    %esi
f0105886:	5f                   	pop    %edi
f0105887:	5d                   	pop    %ebp
f0105888:	c3                   	ret    
f0105889:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105890:	85 ff                	test   %edi,%edi
f0105892:	89 fd                	mov    %edi,%ebp
f0105894:	75 0b                	jne    f01058a1 <__umoddi3+0x91>
f0105896:	b8 01 00 00 00       	mov    $0x1,%eax
f010589b:	31 d2                	xor    %edx,%edx
f010589d:	f7 f7                	div    %edi
f010589f:	89 c5                	mov    %eax,%ebp
f01058a1:	89 f0                	mov    %esi,%eax
f01058a3:	31 d2                	xor    %edx,%edx
f01058a5:	f7 f5                	div    %ebp
f01058a7:	89 c8                	mov    %ecx,%eax
f01058a9:	f7 f5                	div    %ebp
f01058ab:	89 d0                	mov    %edx,%eax
f01058ad:	eb 99                	jmp    f0105848 <__umoddi3+0x38>
f01058af:	90                   	nop
f01058b0:	89 c8                	mov    %ecx,%eax
f01058b2:	89 f2                	mov    %esi,%edx
f01058b4:	83 c4 1c             	add    $0x1c,%esp
f01058b7:	5b                   	pop    %ebx
f01058b8:	5e                   	pop    %esi
f01058b9:	5f                   	pop    %edi
f01058ba:	5d                   	pop    %ebp
f01058bb:	c3                   	ret    
f01058bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01058c0:	8b 34 24             	mov    (%esp),%esi
f01058c3:	bf 20 00 00 00       	mov    $0x20,%edi
f01058c8:	89 e9                	mov    %ebp,%ecx
f01058ca:	29 ef                	sub    %ebp,%edi
f01058cc:	d3 e0                	shl    %cl,%eax
f01058ce:	89 f9                	mov    %edi,%ecx
f01058d0:	89 f2                	mov    %esi,%edx
f01058d2:	d3 ea                	shr    %cl,%edx
f01058d4:	89 e9                	mov    %ebp,%ecx
f01058d6:	09 c2                	or     %eax,%edx
f01058d8:	89 d8                	mov    %ebx,%eax
f01058da:	89 14 24             	mov    %edx,(%esp)
f01058dd:	89 f2                	mov    %esi,%edx
f01058df:	d3 e2                	shl    %cl,%edx
f01058e1:	89 f9                	mov    %edi,%ecx
f01058e3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01058e7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01058eb:	d3 e8                	shr    %cl,%eax
f01058ed:	89 e9                	mov    %ebp,%ecx
f01058ef:	89 c6                	mov    %eax,%esi
f01058f1:	d3 e3                	shl    %cl,%ebx
f01058f3:	89 f9                	mov    %edi,%ecx
f01058f5:	89 d0                	mov    %edx,%eax
f01058f7:	d3 e8                	shr    %cl,%eax
f01058f9:	89 e9                	mov    %ebp,%ecx
f01058fb:	09 d8                	or     %ebx,%eax
f01058fd:	89 d3                	mov    %edx,%ebx
f01058ff:	89 f2                	mov    %esi,%edx
f0105901:	f7 34 24             	divl   (%esp)
f0105904:	89 d6                	mov    %edx,%esi
f0105906:	d3 e3                	shl    %cl,%ebx
f0105908:	f7 64 24 04          	mull   0x4(%esp)
f010590c:	39 d6                	cmp    %edx,%esi
f010590e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105912:	89 d1                	mov    %edx,%ecx
f0105914:	89 c3                	mov    %eax,%ebx
f0105916:	72 08                	jb     f0105920 <__umoddi3+0x110>
f0105918:	75 11                	jne    f010592b <__umoddi3+0x11b>
f010591a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010591e:	73 0b                	jae    f010592b <__umoddi3+0x11b>
f0105920:	2b 44 24 04          	sub    0x4(%esp),%eax
f0105924:	1b 14 24             	sbb    (%esp),%edx
f0105927:	89 d1                	mov    %edx,%ecx
f0105929:	89 c3                	mov    %eax,%ebx
f010592b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010592f:	29 da                	sub    %ebx,%edx
f0105931:	19 ce                	sbb    %ecx,%esi
f0105933:	89 f9                	mov    %edi,%ecx
f0105935:	89 f0                	mov    %esi,%eax
f0105937:	d3 e0                	shl    %cl,%eax
f0105939:	89 e9                	mov    %ebp,%ecx
f010593b:	d3 ea                	shr    %cl,%edx
f010593d:	89 e9                	mov    %ebp,%ecx
f010593f:	d3 ee                	shr    %cl,%esi
f0105941:	09 d0                	or     %edx,%eax
f0105943:	89 f2                	mov    %esi,%edx
f0105945:	83 c4 1c             	add    $0x1c,%esp
f0105948:	5b                   	pop    %ebx
f0105949:	5e                   	pop    %esi
f010594a:	5f                   	pop    %edi
f010594b:	5d                   	pop    %ebp
f010594c:	c3                   	ret    
f010594d:	8d 76 00             	lea    0x0(%esi),%esi
f0105950:	29 f9                	sub    %edi,%ecx
f0105952:	19 d6                	sbb    %edx,%esi
f0105954:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105958:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010595c:	e9 18 ff ff ff       	jmp    f0105879 <__umoddi3+0x69>

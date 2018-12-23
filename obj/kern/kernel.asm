
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
f010005c:	e8 91 51 00 00       	call   f01051f2 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 80 58 10 f0       	push   $0xf0105880
f010006d:	e8 e1 35 00 00       	call   f0103653 <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 b1 35 00 00       	call   f010362d <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 09 5c 10 f0 	movl   $0xf0105c09,(%esp)
f0100083:	e8 cb 35 00 00       	call   f0103653 <cprintf>
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
f01000b3:	e8 17 4b 00 00       	call   f0104bcf <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 8f 05 00 00       	call   f010064c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 ec 58 10 f0       	push   $0xf01058ec
f01000ca:	e8 84 35 00 00       	call   f0103653 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 98 11 00 00       	call   f010126c <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 97 2d 00 00       	call   f0102e70 <env_init>
	trap_init();
f01000d9:	e8 e6 35 00 00       	call   f01036c4 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 05 4e 00 00       	call   f0104ee8 <mp_init>
	lapic_init();
f01000e3:	e8 25 51 00 00       	call   f010520d <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 8d 34 00 00       	call   f010357a <pic_init>
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
f01000fe:	68 a4 58 10 f0       	push   $0xf01058a4
f0100103:	6a 53                	push   $0x53
f0100105:	68 07 59 10 f0       	push   $0xf0105907
f010010a:	e8 31 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010010f:	83 ec 04             	sub    $0x4,%esp
f0100112:	b8 4e 4e 10 f0       	mov    $0xf0104e4e,%eax
f0100117:	2d d4 4d 10 f0       	sub    $0xf0104dd4,%eax
f010011c:	50                   	push   %eax
f010011d:	68 d4 4d 10 f0       	push   $0xf0104dd4
f0100122:	68 00 70 00 f0       	push   $0xf0007000
f0100127:	e8 f0 4a 00 00       	call   f0104c1c <memmove>
f010012c:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010012f:	bb 20 b0 22 f0       	mov    $0xf022b020,%ebx
f0100134:	eb 4d                	jmp    f0100183 <i386_init+0xe9>
		if (c == cpus + cpunum())  // We've started already.
f0100136:	e8 b7 50 00 00       	call   f01051f2 <cpunum>
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
f0100170:	e8 e6 51 00 00       	call   f010535b <lapic_startap>
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
f010019d:	e8 96 2e 00 00       	call   f0103038 <env_create>
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001a2:	e8 db 3d 00 00       	call   f0103f82 <sched_yield>

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
f01001ba:	68 c8 58 10 f0       	push   $0xf01058c8
f01001bf:	6a 6a                	push   $0x6a
f01001c1:	68 07 59 10 f0       	push   $0xf0105907
f01001c6:	e8 75 fe ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01001cb:	05 00 00 00 10       	add    $0x10000000,%eax
f01001d0:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001d3:	e8 1a 50 00 00       	call   f01051f2 <cpunum>
f01001d8:	83 ec 08             	sub    $0x8,%esp
f01001db:	50                   	push   %eax
f01001dc:	68 13 59 10 f0       	push   $0xf0105913
f01001e1:	e8 6d 34 00 00       	call   f0103653 <cprintf>

	lapic_init();
f01001e6:	e8 22 50 00 00       	call   f010520d <lapic_init>
	env_init_percpu();
f01001eb:	e8 50 2c 00 00       	call   f0102e40 <env_init_percpu>
	trap_init_percpu();
f01001f0:	e8 72 34 00 00       	call   f0103667 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f01001f5:	e8 f8 4f 00 00       	call   f01051f2 <cpunum>
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
f0100221:	68 29 59 10 f0       	push   $0xf0105929
f0100226:	e8 28 34 00 00       	call   f0103653 <cprintf>
	vcprintf(fmt, ap);
f010022b:	83 c4 08             	add    $0x8,%esp
f010022e:	53                   	push   %ebx
f010022f:	ff 75 10             	pushl  0x10(%ebp)
f0100232:	e8 f6 33 00 00       	call   f010362d <vcprintf>
	cprintf("\n");
f0100237:	c7 04 24 09 5c 10 f0 	movl   $0xf0105c09,(%esp)
f010023e:	e8 10 34 00 00       	call   f0103653 <cprintf>
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
f01002f5:	0f b6 82 a0 5a 10 f0 	movzbl -0xfefa560(%edx),%eax
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
f0100331:	0f b6 82 a0 5a 10 f0 	movzbl -0xfefa560(%edx),%eax
f0100338:	0b 05 00 a0 22 f0    	or     0xf022a000,%eax
f010033e:	0f b6 8a a0 59 10 f0 	movzbl -0xfefa660(%edx),%ecx
f0100345:	31 c8                	xor    %ecx,%eax
f0100347:	a3 00 a0 22 f0       	mov    %eax,0xf022a000

	c = charcode[shift & (CTL | SHIFT)][data];
f010034c:	89 c1                	mov    %eax,%ecx
f010034e:	83 e1 03             	and    $0x3,%ecx
f0100351:	8b 0c 8d 80 59 10 f0 	mov    -0xfefa680(,%ecx,4),%ecx
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
f010038f:	68 43 59 10 f0       	push   $0xf0105943
f0100394:	e8 ba 32 00 00       	call   f0103653 <cprintf>
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
f0100570:	e8 a7 46 00 00       	call   f0104c1c <memmove>
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
f01006e4:	e8 19 2e 00 00       	call   f0103502 <irq_setmask_8259A>
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
f010075c:	68 4f 59 10 f0       	push   $0xf010594f
f0100761:	e8 ed 2e 00 00       	call   f0103653 <cprintf>
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
f01007a2:	68 a0 5b 10 f0       	push   $0xf0105ba0
f01007a7:	68 be 5b 10 f0       	push   $0xf0105bbe
f01007ac:	68 c3 5b 10 f0       	push   $0xf0105bc3
f01007b1:	e8 9d 2e 00 00       	call   f0103653 <cprintf>
f01007b6:	83 c4 0c             	add    $0xc,%esp
f01007b9:	68 58 5c 10 f0       	push   $0xf0105c58
f01007be:	68 cc 5b 10 f0       	push   $0xf0105bcc
f01007c3:	68 c3 5b 10 f0       	push   $0xf0105bc3
f01007c8:	e8 86 2e 00 00       	call   f0103653 <cprintf>
f01007cd:	83 c4 0c             	add    $0xc,%esp
f01007d0:	68 80 5c 10 f0       	push   $0xf0105c80
f01007d5:	68 d5 5b 10 f0       	push   $0xf0105bd5
f01007da:	68 c3 5b 10 f0       	push   $0xf0105bc3
f01007df:	e8 6f 2e 00 00       	call   f0103653 <cprintf>
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
f01007f1:	68 df 5b 10 f0       	push   $0xf0105bdf
f01007f6:	e8 58 2e 00 00       	call   f0103653 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007fb:	83 c4 08             	add    $0x8,%esp
f01007fe:	68 0c 00 10 00       	push   $0x10000c
f0100803:	68 a8 5c 10 f0       	push   $0xf0105ca8
f0100808:	e8 46 2e 00 00       	call   f0103653 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010080d:	83 c4 0c             	add    $0xc,%esp
f0100810:	68 0c 00 10 00       	push   $0x10000c
f0100815:	68 0c 00 10 f0       	push   $0xf010000c
f010081a:	68 d0 5c 10 f0       	push   $0xf0105cd0
f010081f:	e8 2f 2e 00 00       	call   f0103653 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100824:	83 c4 0c             	add    $0xc,%esp
f0100827:	68 71 58 10 00       	push   $0x105871
f010082c:	68 71 58 10 f0       	push   $0xf0105871
f0100831:	68 f4 5c 10 f0       	push   $0xf0105cf4
f0100836:	e8 18 2e 00 00       	call   f0103653 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010083b:	83 c4 0c             	add    $0xc,%esp
f010083e:	68 98 95 22 00       	push   $0x229598
f0100843:	68 98 95 22 f0       	push   $0xf0229598
f0100848:	68 18 5d 10 f0       	push   $0xf0105d18
f010084d:	e8 01 2e 00 00       	call   f0103653 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100852:	83 c4 0c             	add    $0xc,%esp
f0100855:	68 08 c0 26 00       	push   $0x26c008
f010085a:	68 08 c0 26 f0       	push   $0xf026c008
f010085f:	68 3c 5d 10 f0       	push   $0xf0105d3c
f0100864:	e8 ea 2d 00 00       	call   f0103653 <cprintf>
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
f010088a:	68 60 5d 10 f0       	push   $0xf0105d60
f010088f:	e8 bf 2d 00 00       	call   f0103653 <cprintf>
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
f01008a6:	68 f8 5b 10 f0       	push   $0xf0105bf8
f01008ab:	e8 a3 2d 00 00       	call   f0103653 <cprintf>
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
f01008cc:	68 8c 5d 10 f0       	push   $0xf0105d8c
f01008d1:	e8 7d 2d 00 00       	call   f0103653 <cprintf>
	debuginfo_eip((uintptr_t)eip,&info);
f01008d6:	83 c4 18             	add    $0x18,%esp
f01008d9:	57                   	push   %edi
f01008da:	56                   	push   %esi
f01008db:	e8 ba 38 00 00       	call   f010419a <debuginfo_eip>
	cprintf("%s:%d", info.eip_file, info.eip_line);
f01008e0:	83 c4 0c             	add    $0xc,%esp
f01008e3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008e6:	ff 75 d0             	pushl  -0x30(%ebp)
f01008e9:	68 0b 5c 10 f0       	push   $0xf0105c0b
f01008ee:	e8 60 2d 00 00       	call   f0103653 <cprintf>
        cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name,info.eip_fn_addr);
f01008f3:	ff 75 e0             	pushl  -0x20(%ebp)
f01008f6:	ff 75 d8             	pushl  -0x28(%ebp)
f01008f9:	ff 75 dc             	pushl  -0x24(%ebp)
f01008fc:	68 11 5c 10 f0       	push   $0xf0105c11
f0100901:	e8 4d 2d 00 00       	call   f0103653 <cprintf>
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
f0100925:	68 c4 5d 10 f0       	push   $0xf0105dc4
f010092a:	e8 24 2d 00 00       	call   f0103653 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010092f:	c7 04 24 e8 5d 10 f0 	movl   $0xf0105de8,(%esp)
f0100936:	e8 18 2d 00 00       	call   f0103653 <cprintf>

	if (tf != NULL)
f010093b:	83 c4 10             	add    $0x10,%esp
f010093e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100942:	74 0e                	je     f0100952 <monitor+0x36>
		print_trapframe(tf);
f0100944:	83 ec 0c             	sub    $0xc,%esp
f0100947:	ff 75 08             	pushl  0x8(%ebp)
f010094a:	e8 bd 30 00 00       	call   f0103a0c <print_trapframe>
f010094f:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100952:	83 ec 0c             	sub    $0xc,%esp
f0100955:	68 1c 5c 10 f0       	push   $0xf0105c1c
f010095a:	e8 19 40 00 00       	call   f0104978 <readline>
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
f010098e:	68 20 5c 10 f0       	push   $0xf0105c20
f0100993:	e8 fa 41 00 00       	call   f0104b92 <strchr>
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
f01009ae:	68 25 5c 10 f0       	push   $0xf0105c25
f01009b3:	e8 9b 2c 00 00       	call   f0103653 <cprintf>
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
f01009d7:	68 20 5c 10 f0       	push   $0xf0105c20
f01009dc:	e8 b1 41 00 00       	call   f0104b92 <strchr>
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
f0100a05:	ff 34 85 20 5e 10 f0 	pushl  -0xfefa1e0(,%eax,4)
f0100a0c:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a0f:	e8 20 41 00 00       	call   f0104b34 <strcmp>
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
f0100a29:	ff 14 85 28 5e 10 f0 	call   *-0xfefa1d8(,%eax,4)
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
f0100a4a:	68 42 5c 10 f0       	push   $0xf0105c42
f0100a4f:	e8 ff 2b 00 00       	call   f0103653 <cprintf>
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
f0100a67:	83 3d 38 a2 22 f0 00 	cmpl   $0x0,0xf022a238
f0100a6e:	75 11                	jne    f0100a81 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a70:	ba 07 d0 26 f0       	mov    $0xf026d007,%edx
f0100a75:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a7b:	89 15 38 a2 22 f0    	mov    %edx,0xf022a238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100a81:	8b 0d 38 a2 22 f0    	mov    0xf022a238,%ecx
	nextfree += n;
	nextfree = ROUNDUP( (char*)nextfree, PGSIZE);
f0100a87:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100a8e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a94:	89 15 38 a2 22 f0    	mov    %edx,0xf022a238
	//nextfree += ROUNDUP(n,PGSIZE);
	return result;
}
f0100a9a:	89 c8                	mov    %ecx,%eax
f0100a9c:	5d                   	pop    %ebp
f0100a9d:	c3                   	ret    

f0100a9e <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100a9e:	89 d1                	mov    %edx,%ecx
f0100aa0:	c1 e9 16             	shr    $0x16,%ecx
f0100aa3:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100aa6:	a8 01                	test   $0x1,%al
f0100aa8:	74 52                	je     f0100afc <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100aaa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100aaf:	89 c1                	mov    %eax,%ecx
f0100ab1:	c1 e9 0c             	shr    $0xc,%ecx
f0100ab4:	3b 0d 08 af 22 f0    	cmp    0xf022af08,%ecx
f0100aba:	72 1b                	jb     f0100ad7 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100abc:	55                   	push   %ebp
f0100abd:	89 e5                	mov    %esp,%ebp
f0100abf:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ac2:	50                   	push   %eax
f0100ac3:	68 a4 58 10 f0       	push   $0xf01058a4
f0100ac8:	68 dc 03 00 00       	push   $0x3dc
f0100acd:	68 41 67 10 f0       	push   $0xf0106741
f0100ad2:	e8 69 f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100ad7:	c1 ea 0c             	shr    $0xc,%edx
f0100ada:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100ae0:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100ae7:	89 c2                	mov    %eax,%edx
f0100ae9:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100aec:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100af1:	85 d2                	test   %edx,%edx
f0100af3:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100af8:	0f 44 c2             	cmove  %edx,%eax
f0100afb:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100afc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b01:	c3                   	ret    

f0100b02 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100b02:	55                   	push   %ebp
f0100b03:	89 e5                	mov    %esp,%ebp
f0100b05:	57                   	push   %edi
f0100b06:	56                   	push   %esi
f0100b07:	53                   	push   %ebx
f0100b08:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b0b:	84 c0                	test   %al,%al
f0100b0d:	0f 85 91 02 00 00    	jne    f0100da4 <check_page_free_list+0x2a2>
f0100b13:	e9 9e 02 00 00       	jmp    f0100db6 <check_page_free_list+0x2b4>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100b18:	83 ec 04             	sub    $0x4,%esp
f0100b1b:	68 44 5e 10 f0       	push   $0xf0105e44
f0100b20:	68 11 03 00 00       	push   $0x311
f0100b25:	68 41 67 10 f0       	push   $0xf0106741
f0100b2a:	e8 11 f5 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100b2f:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b32:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b35:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b38:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b3b:	89 c2                	mov    %eax,%edx
f0100b3d:	2b 15 10 af 22 f0    	sub    0xf022af10,%edx
f0100b43:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b49:	0f 95 c2             	setne  %dl
f0100b4c:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b4f:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b53:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b55:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b59:	8b 00                	mov    (%eax),%eax
f0100b5b:	85 c0                	test   %eax,%eax
f0100b5d:	75 dc                	jne    f0100b3b <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b5f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b62:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b68:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b6b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b6e:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b70:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b73:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b78:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b7d:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f0100b83:	eb 53                	jmp    f0100bd8 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b85:	89 d8                	mov    %ebx,%eax
f0100b87:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f0100b8d:	c1 f8 03             	sar    $0x3,%eax
f0100b90:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b93:	89 c2                	mov    %eax,%edx
f0100b95:	c1 ea 16             	shr    $0x16,%edx
f0100b98:	39 f2                	cmp    %esi,%edx
f0100b9a:	73 3a                	jae    f0100bd6 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b9c:	89 c2                	mov    %eax,%edx
f0100b9e:	c1 ea 0c             	shr    $0xc,%edx
f0100ba1:	3b 15 08 af 22 f0    	cmp    0xf022af08,%edx
f0100ba7:	72 12                	jb     f0100bbb <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ba9:	50                   	push   %eax
f0100baa:	68 a4 58 10 f0       	push   $0xf01058a4
f0100baf:	6a 58                	push   $0x58
f0100bb1:	68 4d 67 10 f0       	push   $0xf010674d
f0100bb6:	e8 85 f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100bbb:	83 ec 04             	sub    $0x4,%esp
f0100bbe:	68 80 00 00 00       	push   $0x80
f0100bc3:	68 97 00 00 00       	push   $0x97
f0100bc8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bcd:	50                   	push   %eax
f0100bce:	e8 fc 3f 00 00       	call   f0104bcf <memset>
f0100bd3:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bd6:	8b 1b                	mov    (%ebx),%ebx
f0100bd8:	85 db                	test   %ebx,%ebx
f0100bda:	75 a9                	jne    f0100b85 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100bdc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100be1:	e8 7e fe ff ff       	call   f0100a64 <boot_alloc>
f0100be6:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100be9:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bef:	8b 0d 10 af 22 f0    	mov    0xf022af10,%ecx
		assert(pp < pages + npages);
f0100bf5:	a1 08 af 22 f0       	mov    0xf022af08,%eax
f0100bfa:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100bfd:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100c00:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c03:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c06:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c0b:	e9 52 01 00 00       	jmp    f0100d62 <check_page_free_list+0x260>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c10:	39 ca                	cmp    %ecx,%edx
f0100c12:	73 19                	jae    f0100c2d <check_page_free_list+0x12b>
f0100c14:	68 5b 67 10 f0       	push   $0xf010675b
f0100c19:	68 67 67 10 f0       	push   $0xf0106767
f0100c1e:	68 2b 03 00 00       	push   $0x32b
f0100c23:	68 41 67 10 f0       	push   $0xf0106741
f0100c28:	e8 13 f4 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c2d:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c30:	72 19                	jb     f0100c4b <check_page_free_list+0x149>
f0100c32:	68 7c 67 10 f0       	push   $0xf010677c
f0100c37:	68 67 67 10 f0       	push   $0xf0106767
f0100c3c:	68 2c 03 00 00       	push   $0x32c
f0100c41:	68 41 67 10 f0       	push   $0xf0106741
f0100c46:	e8 f5 f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c4b:	89 d0                	mov    %edx,%eax
f0100c4d:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c50:	a8 07                	test   $0x7,%al
f0100c52:	74 19                	je     f0100c6d <check_page_free_list+0x16b>
f0100c54:	68 68 5e 10 f0       	push   $0xf0105e68
f0100c59:	68 67 67 10 f0       	push   $0xf0106767
f0100c5e:	68 2d 03 00 00       	push   $0x32d
f0100c63:	68 41 67 10 f0       	push   $0xf0106741
f0100c68:	e8 d3 f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c6d:	c1 f8 03             	sar    $0x3,%eax
f0100c70:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c73:	85 c0                	test   %eax,%eax
f0100c75:	75 19                	jne    f0100c90 <check_page_free_list+0x18e>
f0100c77:	68 90 67 10 f0       	push   $0xf0106790
f0100c7c:	68 67 67 10 f0       	push   $0xf0106767
f0100c81:	68 30 03 00 00       	push   $0x330
f0100c86:	68 41 67 10 f0       	push   $0xf0106741
f0100c8b:	e8 b0 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c90:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c95:	75 19                	jne    f0100cb0 <check_page_free_list+0x1ae>
f0100c97:	68 a1 67 10 f0       	push   $0xf01067a1
f0100c9c:	68 67 67 10 f0       	push   $0xf0106767
f0100ca1:	68 31 03 00 00       	push   $0x331
f0100ca6:	68 41 67 10 f0       	push   $0xf0106741
f0100cab:	e8 90 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cb0:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cb5:	75 19                	jne    f0100cd0 <check_page_free_list+0x1ce>
f0100cb7:	68 9c 5e 10 f0       	push   $0xf0105e9c
f0100cbc:	68 67 67 10 f0       	push   $0xf0106767
f0100cc1:	68 32 03 00 00       	push   $0x332
f0100cc6:	68 41 67 10 f0       	push   $0xf0106741
f0100ccb:	e8 70 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cd0:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cd5:	75 19                	jne    f0100cf0 <check_page_free_list+0x1ee>
f0100cd7:	68 ba 67 10 f0       	push   $0xf01067ba
f0100cdc:	68 67 67 10 f0       	push   $0xf0106767
f0100ce1:	68 33 03 00 00       	push   $0x333
f0100ce6:	68 41 67 10 f0       	push   $0xf0106741
f0100ceb:	e8 50 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cf0:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cf5:	0f 86 de 00 00 00    	jbe    f0100dd9 <check_page_free_list+0x2d7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cfb:	89 c7                	mov    %eax,%edi
f0100cfd:	c1 ef 0c             	shr    $0xc,%edi
f0100d00:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0100d03:	77 12                	ja     f0100d17 <check_page_free_list+0x215>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d05:	50                   	push   %eax
f0100d06:	68 a4 58 10 f0       	push   $0xf01058a4
f0100d0b:	6a 58                	push   $0x58
f0100d0d:	68 4d 67 10 f0       	push   $0xf010674d
f0100d12:	e8 29 f3 ff ff       	call   f0100040 <_panic>
f0100d17:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
f0100d1d:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0100d20:	0f 86 a7 00 00 00    	jbe    f0100dcd <check_page_free_list+0x2cb>
f0100d26:	68 c0 5e 10 f0       	push   $0xf0105ec0
f0100d2b:	68 67 67 10 f0       	push   $0xf0106767
f0100d30:	68 34 03 00 00       	push   $0x334
f0100d35:	68 41 67 10 f0       	push   $0xf0106741
f0100d3a:	e8 01 f3 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d3f:	68 d4 67 10 f0       	push   $0xf01067d4
f0100d44:	68 67 67 10 f0       	push   $0xf0106767
f0100d49:	68 36 03 00 00       	push   $0x336
f0100d4e:	68 41 67 10 f0       	push   $0xf0106741
f0100d53:	e8 e8 f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d58:	83 c6 01             	add    $0x1,%esi
f0100d5b:	eb 03                	jmp    f0100d60 <check_page_free_list+0x25e>
		else
			++nfree_extmem;
f0100d5d:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d60:	8b 12                	mov    (%edx),%edx
f0100d62:	85 d2                	test   %edx,%edx
f0100d64:	0f 85 a6 fe ff ff    	jne    f0100c10 <check_page_free_list+0x10e>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d6a:	85 f6                	test   %esi,%esi
f0100d6c:	7f 19                	jg     f0100d87 <check_page_free_list+0x285>
f0100d6e:	68 f1 67 10 f0       	push   $0xf01067f1
f0100d73:	68 67 67 10 f0       	push   $0xf0106767
f0100d78:	68 3e 03 00 00       	push   $0x33e
f0100d7d:	68 41 67 10 f0       	push   $0xf0106741
f0100d82:	e8 b9 f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100d87:	85 db                	test   %ebx,%ebx
f0100d89:	7f 5e                	jg     f0100de9 <check_page_free_list+0x2e7>
f0100d8b:	68 03 68 10 f0       	push   $0xf0106803
f0100d90:	68 67 67 10 f0       	push   $0xf0106767
f0100d95:	68 3f 03 00 00       	push   $0x33f
f0100d9a:	68 41 67 10 f0       	push   $0xf0106741
f0100d9f:	e8 9c f2 ff ff       	call   f0100040 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100da4:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0100da9:	85 c0                	test   %eax,%eax
f0100dab:	0f 85 7e fd ff ff    	jne    f0100b2f <check_page_free_list+0x2d>
f0100db1:	e9 62 fd ff ff       	jmp    f0100b18 <check_page_free_list+0x16>
f0100db6:	83 3d 40 a2 22 f0 00 	cmpl   $0x0,0xf022a240
f0100dbd:	0f 84 55 fd ff ff    	je     f0100b18 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100dc3:	be 00 04 00 00       	mov    $0x400,%esi
f0100dc8:	e9 b0 fd ff ff       	jmp    f0100b7d <check_page_free_list+0x7b>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100dcd:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100dd2:	75 89                	jne    f0100d5d <check_page_free_list+0x25b>
f0100dd4:	e9 66 ff ff ff       	jmp    f0100d3f <check_page_free_list+0x23d>
f0100dd9:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100dde:	0f 85 74 ff ff ff    	jne    f0100d58 <check_page_free_list+0x256>
f0100de4:	e9 56 ff ff ff       	jmp    f0100d3f <check_page_free_list+0x23d>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100de9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100dec:	5b                   	pop    %ebx
f0100ded:	5e                   	pop    %esi
f0100dee:	5f                   	pop    %edi
f0100def:	5d                   	pop    %ebp
f0100df0:	c3                   	ret    

f0100df1 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100df1:	55                   	push   %ebp
f0100df2:	89 e5                	mov    %esp,%ebp
f0100df4:	56                   	push   %esi
f0100df5:	53                   	push   %ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!

	//  1) Mark physical page 0 as in use.
	pages[0].pp_ref = 1;
f0100df6:	a1 10 af 22 f0       	mov    0xf022af10,%eax
f0100dfb:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;	
f0100e01:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	size_t i;
	//临界点是否等于可能存在问题
	for (i = 1; i < npages; i++) {
f0100e07:	be 08 00 00 00       	mov    $0x8,%esi
f0100e0c:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100e11:	e9 ab 00 00 00       	jmp    f0100ec1 <page_init+0xd0>
        // 	continue;
    	// }

		
	//  2) The rest of base memory
		if(i < npages_basemem){
f0100e16:	3b 1d 44 a2 22 f0    	cmp    0xf022a244,%ebx
f0100e1c:	73 25                	jae    f0100e43 <page_init+0x52>
			pages[i].pp_ref = 0;
f0100e1e:	89 f0                	mov    %esi,%eax
f0100e20:	03 05 10 af 22 f0    	add    0xf022af10,%eax
f0100e26:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100e2c:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100e32:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100e34:	89 f0                	mov    %esi,%eax
f0100e36:	03 05 10 af 22 f0    	add    0xf022af10,%eax
f0100e3c:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
f0100e41:	eb 78                	jmp    f0100ebb <page_init+0xca>
		}
	//  3) Then comes the IO hole 
		else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE){
f0100e43:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100e49:	83 f8 5f             	cmp    $0x5f,%eax
f0100e4c:	77 16                	ja     f0100e64 <page_init+0x73>
			pages[i].pp_ref = 1;
f0100e4e:	89 f0                	mov    %esi,%eax
f0100e50:	03 05 10 af 22 f0    	add    0xf022af10,%eax
f0100e56:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100e5c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100e62:	eb 57                	jmp    f0100ebb <page_init+0xca>
		}
	//  4) Then extended memory
		else if(i >= EXTPHYSMEM/PGSIZE && i< ((int)boot_alloc(0) - KERNBASE)/PGSIZE){
f0100e64:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100e6a:	76 2c                	jbe    f0100e98 <page_init+0xa7>
f0100e6c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e71:	e8 ee fb ff ff       	call   f0100a64 <boot_alloc>
f0100e76:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e7b:	c1 e8 0c             	shr    $0xc,%eax
f0100e7e:	39 c3                	cmp    %eax,%ebx
f0100e80:	73 16                	jae    f0100e98 <page_init+0xa7>
			pages[i].pp_ref = 1;
f0100e82:	89 f0                	mov    %esi,%eax
f0100e84:	03 05 10 af 22 f0    	add    0xf022af10,%eax
f0100e8a:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100e90:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100e96:	eb 23                	jmp    f0100ebb <page_init+0xca>
		}
		else{
			pages[i].pp_ref = 0;
f0100e98:	89 f0                	mov    %esi,%eax
f0100e9a:	03 05 10 af 22 f0    	add    0xf022af10,%eax
f0100ea0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100ea6:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100eac:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100eae:	89 f0                	mov    %esi,%eax
f0100eb0:	03 05 10 af 22 f0    	add    0xf022af10,%eax
f0100eb6:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
	//  1) Mark physical page 0 as in use.
	pages[0].pp_ref = 1;
	pages[0].pp_link = NULL;	
	size_t i;
	//临界点是否等于可能存在问题
	for (i = 1; i < npages; i++) {
f0100ebb:	83 c3 01             	add    $0x1,%ebx
f0100ebe:	83 c6 08             	add    $0x8,%esi
f0100ec1:	3b 1d 08 af 22 f0    	cmp    0xf022af08,%ebx
f0100ec7:	0f 82 49 ff ff ff    	jb     f0100e16 <page_init+0x25>
		}
	}

	//i = ROUNDUP(MPENTRY_PADDR, PGSIZE) / PGSIZE;
	i = MPENTRY_PADDR / PGSIZE;
	pages[i].pp_ref = 1;
f0100ecd:	a1 10 af 22 f0       	mov    0xf022af10,%eax
f0100ed2:	66 c7 40 3c 01 00    	movw   $0x1,0x3c(%eax)
	pages[i].pp_link = NULL;
f0100ed8:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
}
f0100edf:	5b                   	pop    %ebx
f0100ee0:	5e                   	pop    %esi
f0100ee1:	5d                   	pop    %ebp
f0100ee2:	c3                   	ret    

f0100ee3 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100ee3:	55                   	push   %ebp
f0100ee4:	89 e5                	mov    %esp,%ebp
f0100ee6:	53                   	push   %ebx
f0100ee7:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	//cprintf("page_alloc\r\n");
	if(page_free_list == NULL)
f0100eea:	8b 1d 40 a2 22 f0    	mov    0xf022a240,%ebx
f0100ef0:	85 db                	test   %ebx,%ebx
f0100ef2:	74 6e                	je     f0100f62 <page_alloc+0x7f>
		//addr = page2kva(page_free_list);
		//int *iq,*ip;
		//iq=ip;//将把ip中的值拷贝到iq中，这样，指针iq也将指向ip指向的对象
		struct PageInfo *Page;
		Page = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100ef4:	8b 03                	mov    (%ebx),%eax
f0100ef6:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
		//page_free_list->pp_link = NULL;
		Page->pp_link = NULL;
f0100efb:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		//Page->pp_ref = 1;
		Page->pp_ref = 0;
f0100f01:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		cprintf("page_alloc\r\n");
f0100f07:	83 ec 0c             	sub    $0xc,%esp
f0100f0a:	68 14 68 10 f0       	push   $0xf0106814
f0100f0f:	e8 3f 27 00 00       	call   f0103653 <cprintf>
		if(alloc_flags & ALLOC_ZERO)
f0100f14:	83 c4 10             	add    $0x10,%esp
f0100f17:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100f1b:	74 45                	je     f0100f62 <page_alloc+0x7f>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f1d:	89 d8                	mov    %ebx,%eax
f0100f1f:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f0100f25:	c1 f8 03             	sar    $0x3,%eax
f0100f28:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f2b:	89 c2                	mov    %eax,%edx
f0100f2d:	c1 ea 0c             	shr    $0xc,%edx
f0100f30:	3b 15 08 af 22 f0    	cmp    0xf022af08,%edx
f0100f36:	72 12                	jb     f0100f4a <page_alloc+0x67>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f38:	50                   	push   %eax
f0100f39:	68 a4 58 10 f0       	push   $0xf01058a4
f0100f3e:	6a 58                	push   $0x58
f0100f40:	68 4d 67 10 f0       	push   $0xf010674d
f0100f45:	e8 f6 f0 ff ff       	call   f0100040 <_panic>
			memset(page2kva(Page),'\0',PGSIZE);
f0100f4a:	83 ec 04             	sub    $0x4,%esp
f0100f4d:	68 00 10 00 00       	push   $0x1000
f0100f52:	6a 00                	push   $0x0
f0100f54:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f59:	50                   	push   %eax
f0100f5a:	e8 70 3c 00 00       	call   f0104bcf <memset>
f0100f5f:	83 c4 10             	add    $0x10,%esp
			// memset(page2kva(page_free_list),0,PGSIZE);
		return Page;
	}
}
f0100f62:	89 d8                	mov    %ebx,%eax
f0100f64:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f67:	c9                   	leave  
f0100f68:	c3                   	ret    

f0100f69 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100f69:	55                   	push   %ebp
f0100f6a:	89 e5                	mov    %esp,%ebp
f0100f6c:	83 ec 14             	sub    $0x14,%esp
f0100f6f:	8b 45 08             	mov    0x8(%ebp),%eax
	//  	panic("can't free the page");
	//  	return;
	// }
	//	cprinf("can't free the page");
	//pp->pp_link = page_free_list->pp_link;	
	pp->pp_link = page_free_list;
f0100f72:	8b 15 40 a2 22 f0    	mov    0xf022a240,%edx
f0100f78:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f7a:	a3 40 a2 22 f0       	mov    %eax,0xf022a240
	//pp->pp_ref = 0;
	cprintf("page_free\r\n");
f0100f7f:	68 21 68 10 f0       	push   $0xf0106821
f0100f84:	e8 ca 26 00 00       	call   f0103653 <cprintf>
}
f0100f89:	83 c4 10             	add    $0x10,%esp
f0100f8c:	c9                   	leave  
f0100f8d:	c3                   	ret    

f0100f8e <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100f8e:	55                   	push   %ebp
f0100f8f:	89 e5                	mov    %esp,%ebp
f0100f91:	83 ec 08             	sub    $0x8,%esp
f0100f94:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100f97:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100f9b:	83 e8 01             	sub    $0x1,%eax
f0100f9e:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100fa2:	66 85 c0             	test   %ax,%ax
f0100fa5:	75 0c                	jne    f0100fb3 <page_decref+0x25>
		page_free(pp);
f0100fa7:	83 ec 0c             	sub    $0xc,%esp
f0100faa:	52                   	push   %edx
f0100fab:	e8 b9 ff ff ff       	call   f0100f69 <page_free>
f0100fb0:	83 c4 10             	add    $0x10,%esp
}
f0100fb3:	c9                   	leave  
f0100fb4:	c3                   	ret    

f0100fb5 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100fb5:	55                   	push   %ebp
f0100fb6:	89 e5                	mov    %esp,%ebp
f0100fb8:	56                   	push   %esi
f0100fb9:	53                   	push   %ebx
f0100fba:	8b 45 0c             	mov    0xc(%ebp),%eax
	// Fill this function in
	uint32_t pd_number,pt_number,pt_addr;//,page_number,page_addr;
	pte_t *pte = NULL;
	struct PageInfo *Page;
	pd_number = PDX(va);
	pt_number = PTX(va);
f0100fbd:	89 c6                	mov    %eax,%esi
f0100fbf:	c1 ee 0c             	shr    $0xc,%esi
f0100fc2:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	if(pgdir[pd_number] & PTE_P)
f0100fc8:	c1 e8 16             	shr    $0x16,%eax
f0100fcb:	8d 1c 85 00 00 00 00 	lea    0x0(,%eax,4),%ebx
f0100fd2:	03 5d 08             	add    0x8(%ebp),%ebx
f0100fd5:	8b 03                	mov    (%ebx),%eax
f0100fd7:	a8 01                	test   $0x1,%al
f0100fd9:	74 2e                	je     f0101009 <pgdir_walk+0x54>
		pte = KADDR(PTE_ADDR(pgdir[pd_number]));
f0100fdb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fe0:	89 c2                	mov    %eax,%edx
f0100fe2:	c1 ea 0c             	shr    $0xc,%edx
f0100fe5:	39 15 08 af 22 f0    	cmp    %edx,0xf022af08
f0100feb:	77 15                	ja     f0101002 <pgdir_walk+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fed:	50                   	push   %eax
f0100fee:	68 a4 58 10 f0       	push   $0xf01058a4
f0100ff3:	68 c2 01 00 00       	push   $0x1c2
f0100ff8:	68 41 67 10 f0       	push   $0xf0106741
f0100ffd:	e8 3e f0 ff ff       	call   f0100040 <_panic>
	if(!pte){
f0101002:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101007:	75 58                	jne    f0101061 <pgdir_walk+0xac>
		if(!create)
f0101009:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010100d:	74 57                	je     f0101066 <pgdir_walk+0xb1>
	 		return NULL;
	 	Page = page_alloc(create);
f010100f:	83 ec 0c             	sub    $0xc,%esp
f0101012:	ff 75 10             	pushl  0x10(%ebp)
f0101015:	e8 c9 fe ff ff       	call   f0100ee3 <page_alloc>
		if(!Page)
f010101a:	83 c4 10             	add    $0x10,%esp
f010101d:	85 c0                	test   %eax,%eax
f010101f:	74 4c                	je     f010106d <pgdir_walk+0xb8>
			return NULL;
		Page->pp_ref ++;
f0101021:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101026:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f010102c:	89 c2                	mov    %eax,%edx
f010102e:	c1 fa 03             	sar    $0x3,%edx
f0101031:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101034:	89 d0                	mov    %edx,%eax
f0101036:	c1 e8 0c             	shr    $0xc,%eax
f0101039:	3b 05 08 af 22 f0    	cmp    0xf022af08,%eax
f010103f:	72 15                	jb     f0101056 <pgdir_walk+0xa1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101041:	52                   	push   %edx
f0101042:	68 a4 58 10 f0       	push   $0xf01058a4
f0101047:	68 ca 01 00 00       	push   $0x1ca
f010104c:	68 41 67 10 f0       	push   $0xf0106741
f0101051:	e8 ea ef ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101056:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	 	pte = KADDR(page2pa(Page));		
		// pgdir[pd_number] = page2pa(Page);
		pgdir[pd_number] = page2pa(Page) | PTE_P | PTE_W | PTE_U;
f010105c:	83 ca 07             	or     $0x7,%edx
f010105f:	89 13                	mov    %edx,(%ebx)
	}
	return &(pte[pt_number]);
f0101061:	8d 04 b0             	lea    (%eax,%esi,4),%eax
f0101064:	eb 0c                	jmp    f0101072 <pgdir_walk+0xbd>
	pt_number = PTX(va);
	if(pgdir[pd_number] & PTE_P)
		pte = KADDR(PTE_ADDR(pgdir[pd_number]));
	if(!pte){
		if(!create)
	 		return NULL;
f0101066:	b8 00 00 00 00       	mov    $0x0,%eax
f010106b:	eb 05                	jmp    f0101072 <pgdir_walk+0xbd>
	 	Page = page_alloc(create);
		if(!Page)
			return NULL;
f010106d:	b8 00 00 00 00       	mov    $0x0,%eax
	// //不确定page_alloc函数里应该填入的参数,page_alloc(int alloc_flags)
	// 	Page = page_alloc(create);
	// 	page_addr = page2pa(Page);
	// }
	// return page_addr;
}
f0101072:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101075:	5b                   	pop    %ebx
f0101076:	5e                   	pop    %esi
f0101077:	5d                   	pop    %ebp
f0101078:	c3                   	ret    

f0101079 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101079:	55                   	push   %ebp
f010107a:	89 e5                	mov    %esp,%ebp
f010107c:	57                   	push   %edi
f010107d:	56                   	push   %esi
f010107e:	53                   	push   %ebx
f010107f:	83 ec 1c             	sub    $0x1c,%esp
f0101082:	89 c7                	mov    %eax,%edi
f0101084:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101087:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	pte_t *pte = NULL;
	for(int i = 0;i < size;i += PGSIZE){
f010108a:	bb 00 00 00 00       	mov    $0x0,%ebx
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
f010108f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101092:	83 c8 01             	or     $0x1,%eax
f0101095:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte = NULL;
	for(int i = 0;i < size;i += PGSIZE){
f0101098:	eb 1f                	jmp    f01010b9 <boot_map_region+0x40>
		pte = pgdir_walk(pgdir, (void *)va, 1);
f010109a:	83 ec 04             	sub    $0x4,%esp
f010109d:	6a 01                	push   $0x1
f010109f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010a2:	01 d8                	add    %ebx,%eax
f01010a4:	50                   	push   %eax
f01010a5:	57                   	push   %edi
f01010a6:	e8 0a ff ff ff       	call   f0100fb5 <pgdir_walk>
		*pte = (pa | perm | PTE_P);
f01010ab:	0b 75 dc             	or     -0x24(%ebp),%esi
f01010ae:	89 30                	mov    %esi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte = NULL;
	for(int i = 0;i < size;i += PGSIZE){
f01010b0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01010b6:	83 c4 10             	add    $0x10,%esp
f01010b9:	89 de                	mov    %ebx,%esi
f01010bb:	03 75 08             	add    0x8(%ebp),%esi
f01010be:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f01010c1:	77 d7                	ja     f010109a <boot_map_region+0x21>
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f01010c3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010c6:	5b                   	pop    %ebx
f01010c7:	5e                   	pop    %esi
f01010c8:	5f                   	pop    %edi
f01010c9:	5d                   	pop    %ebp
f01010ca:	c3                   	ret    

f01010cb <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01010cb:	55                   	push   %ebp
f01010cc:	89 e5                	mov    %esp,%ebp
f01010ce:	53                   	push   %ebx
f01010cf:	83 ec 08             	sub    $0x8,%esp
f01010d2:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
f01010d5:	6a 00                	push   $0x0
f01010d7:	ff 75 0c             	pushl  0xc(%ebp)
f01010da:	ff 75 08             	pushl  0x8(%ebp)
f01010dd:	e8 d3 fe ff ff       	call   f0100fb5 <pgdir_walk>
	if(!pte)
f01010e2:	83 c4 10             	add    $0x10,%esp
f01010e5:	85 c0                	test   %eax,%eax
f01010e7:	74 32                	je     f010111b <page_lookup+0x50>
		return NULL;
	if(pte_store)
f01010e9:	85 db                	test   %ebx,%ebx
f01010eb:	74 02                	je     f01010ef <page_lookup+0x24>
		*pte_store = pte;
f01010ed:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010ef:	8b 00                	mov    (%eax),%eax
f01010f1:	c1 e8 0c             	shr    $0xc,%eax
f01010f4:	3b 05 08 af 22 f0    	cmp    0xf022af08,%eax
f01010fa:	72 14                	jb     f0101110 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f01010fc:	83 ec 04             	sub    $0x4,%esp
f01010ff:	68 08 5f 10 f0       	push   $0xf0105f08
f0101104:	6a 51                	push   $0x51
f0101106:	68 4d 67 10 f0       	push   $0xf010674d
f010110b:	e8 30 ef ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0101110:	8b 15 10 af 22 f0    	mov    0xf022af10,%edx
f0101116:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	return pa2page(PTE_ADDR(*pte));
f0101119:	eb 05                	jmp    f0101120 <page_lookup+0x55>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
	if(!pte)
		return NULL;
f010111b:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f0101120:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101123:	c9                   	leave  
f0101124:	c3                   	ret    

f0101125 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101125:	55                   	push   %ebp
f0101126:	89 e5                	mov    %esp,%ebp
f0101128:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f010112b:	e8 c2 40 00 00       	call   f01051f2 <cpunum>
f0101130:	6b c0 74             	imul   $0x74,%eax,%eax
f0101133:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f010113a:	74 16                	je     f0101152 <tlb_invalidate+0x2d>
f010113c:	e8 b1 40 00 00       	call   f01051f2 <cpunum>
f0101141:	6b c0 74             	imul   $0x74,%eax,%eax
f0101144:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010114a:	8b 55 08             	mov    0x8(%ebp),%edx
f010114d:	39 50 60             	cmp    %edx,0x60(%eax)
f0101150:	75 06                	jne    f0101158 <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101152:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101155:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0101158:	c9                   	leave  
f0101159:	c3                   	ret    

f010115a <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010115a:	55                   	push   %ebp
f010115b:	89 e5                	mov    %esp,%ebp
f010115d:	57                   	push   %edi
f010115e:	56                   	push   %esi
f010115f:	53                   	push   %ebx
f0101160:	83 ec 20             	sub    $0x20,%esp
f0101163:	8b 75 08             	mov    0x8(%ebp),%esi
f0101166:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pte_t *pte;
	// pte_t *pte,**pte_store;
	// pte = pgdir_walk(pgdir, (void *)va, 0);
	// pte_store = &pte;
	struct PageInfo *Page;
	Page = page_lookup(pgdir, va, &pte);
f0101169:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010116c:	50                   	push   %eax
f010116d:	57                   	push   %edi
f010116e:	56                   	push   %esi
f010116f:	e8 57 ff ff ff       	call   f01010cb <page_lookup>
	// Page = page_lookup(pgdir, va, pte_store);
	if(Page){
f0101174:	83 c4 10             	add    $0x10,%esp
f0101177:	85 c0                	test   %eax,%eax
f0101179:	74 20                	je     f010119b <page_remove+0x41>
f010117b:	89 c3                	mov    %eax,%ebx
		// Page->pp_ref --;
		tlb_invalidate(pgdir, va);
f010117d:	83 ec 08             	sub    $0x8,%esp
f0101180:	57                   	push   %edi
f0101181:	56                   	push   %esi
f0101182:	e8 9e ff ff ff       	call   f0101125 <tlb_invalidate>
		page_decref(Page);
f0101187:	89 1c 24             	mov    %ebx,(%esp)
f010118a:	e8 ff fd ff ff       	call   f0100f8e <page_decref>
		*pte = 0;//将对应的页表项清空
f010118f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101192:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101198:	83 c4 10             	add    $0x10,%esp
	}
}
f010119b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010119e:	5b                   	pop    %ebx
f010119f:	5e                   	pop    %esi
f01011a0:	5f                   	pop    %edi
f01011a1:	5d                   	pop    %ebp
f01011a2:	c3                   	ret    

f01011a3 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01011a3:	55                   	push   %ebp
f01011a4:	89 e5                	mov    %esp,%ebp
f01011a6:	57                   	push   %edi
f01011a7:	56                   	push   %esi
f01011a8:	53                   	push   %ebx
f01011a9:	83 ec 10             	sub    $0x10,%esp
f01011ac:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01011af:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
f01011b2:	6a 01                	push   $0x1
f01011b4:	57                   	push   %edi
f01011b5:	ff 75 08             	pushl  0x8(%ebp)
f01011b8:	e8 f8 fd ff ff       	call   f0100fb5 <pgdir_walk>
	if(!pte)
f01011bd:	83 c4 10             	add    $0x10,%esp
f01011c0:	85 c0                	test   %eax,%eax
f01011c2:	74 38                	je     f01011fc <page_insert+0x59>
f01011c4:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	pp->pp_ref++;
f01011c6:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	//删除旧映射关系 
    if((*pte) & PTE_P)
f01011cb:	f6 00 01             	testb  $0x1,(%eax)
f01011ce:	74 0f                	je     f01011df <page_insert+0x3c>
        page_remove(pgdir, va);
f01011d0:	83 ec 08             	sub    $0x8,%esp
f01011d3:	57                   	push   %edi
f01011d4:	ff 75 08             	pushl  0x8(%ebp)
f01011d7:	e8 7e ff ff ff       	call   f010115a <page_remove>
f01011dc:	83 c4 10             	add    $0x10,%esp
	//pp ->pp_ref++;
    *pte = page2pa(pp) | perm | PTE_P;
f01011df:	2b 1d 10 af 22 f0    	sub    0xf022af10,%ebx
f01011e5:	c1 fb 03             	sar    $0x3,%ebx
f01011e8:	c1 e3 0c             	shl    $0xc,%ebx
f01011eb:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ee:	83 c8 01             	or     $0x1,%eax
f01011f1:	09 c3                	or     %eax,%ebx
f01011f3:	89 1e                	mov    %ebx,(%esi)
	return 0;
f01011f5:	b8 00 00 00 00       	mov    $0x0,%eax
f01011fa:	eb 05                	jmp    f0101201 <page_insert+0x5e>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
	if(!pte)
		return -E_NO_MEM;
f01011fc:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	// 		page_remove(pgdir, va); 
	// }
	// //pp->pp_ref++;
    // *pte = page2pa(pp) | perm | PTE_P;
	// return 0;
}
f0101201:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101204:	5b                   	pop    %ebx
f0101205:	5e                   	pop    %esi
f0101206:	5f                   	pop    %edi
f0101207:	5d                   	pop    %ebp
f0101208:	c3                   	ret    

f0101209 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f0101209:	55                   	push   %ebp
f010120a:	89 e5                	mov    %esp,%ebp
f010120c:	53                   	push   %ebx
f010120d:	83 ec 04             	sub    $0x4,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	size_t rounded_size = ROUNDUP(size, PGSIZE);
f0101210:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101213:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0101219:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx

    if (base + rounded_size > MMIOLIM) panic("overflow MMIOLIM");
f010121f:	8b 15 00 f3 11 f0    	mov    0xf011f300,%edx
f0101225:	8d 04 13             	lea    (%ebx,%edx,1),%eax
f0101228:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f010122d:	76 17                	jbe    f0101246 <mmio_map_region+0x3d>
f010122f:	83 ec 04             	sub    $0x4,%esp
f0101232:	68 2d 68 10 f0       	push   $0xf010682d
f0101237:	68 ad 02 00 00       	push   $0x2ad
f010123c:	68 41 67 10 f0       	push   $0xf0106741
f0101241:	e8 fa ed ff ff       	call   f0100040 <_panic>
    boot_map_region(kern_pgdir, base, rounded_size, pa, PTE_W|PTE_PCD|PTE_PWT);
f0101246:	83 ec 08             	sub    $0x8,%esp
f0101249:	6a 1a                	push   $0x1a
f010124b:	ff 75 08             	pushl  0x8(%ebp)
f010124e:	89 d9                	mov    %ebx,%ecx
f0101250:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0101255:	e8 1f fe ff ff       	call   f0101079 <boot_map_region>
    uintptr_t res_region_base = base;   
f010125a:	a1 00 f3 11 f0       	mov    0xf011f300,%eax
    base += rounded_size;       
f010125f:	01 c3                	add    %eax,%ebx
f0101261:	89 1d 00 f3 11 f0    	mov    %ebx,0xf011f300

	// boot_map_region(kern_pgdir, base, size, pa, PTE_PCD|PTE_PWT|PTE_W);
	// base += size;//每次映射到不同的页面
	// return (void *)(base-size);
	//panic("mmio_map_region not implemented");
}
f0101267:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010126a:	c9                   	leave  
f010126b:	c3                   	ret    

f010126c <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010126c:	55                   	push   %ebp
f010126d:	89 e5                	mov    %esp,%ebp
f010126f:	57                   	push   %edi
f0101270:	56                   	push   %esi
f0101271:	53                   	push   %ebx
f0101272:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101275:	6a 15                	push   $0x15
f0101277:	e8 58 22 00 00       	call   f01034d4 <mc146818_read>
f010127c:	89 c3                	mov    %eax,%ebx
f010127e:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101285:	e8 4a 22 00 00       	call   f01034d4 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010128a:	c1 e0 08             	shl    $0x8,%eax
f010128d:	09 d8                	or     %ebx,%eax
f010128f:	c1 e0 0a             	shl    $0xa,%eax
f0101292:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101298:	85 c0                	test   %eax,%eax
f010129a:	0f 48 c2             	cmovs  %edx,%eax
f010129d:	c1 f8 0c             	sar    $0xc,%eax
f01012a0:	a3 44 a2 22 f0       	mov    %eax,0xf022a244
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01012a5:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01012ac:	e8 23 22 00 00       	call   f01034d4 <mc146818_read>
f01012b1:	89 c3                	mov    %eax,%ebx
f01012b3:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01012ba:	e8 15 22 00 00       	call   f01034d4 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01012bf:	c1 e0 08             	shl    $0x8,%eax
f01012c2:	09 d8                	or     %ebx,%eax
f01012c4:	c1 e0 0a             	shl    $0xa,%eax
f01012c7:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01012cd:	83 c4 10             	add    $0x10,%esp
f01012d0:	85 c0                	test   %eax,%eax
f01012d2:	0f 48 c2             	cmovs  %edx,%eax
f01012d5:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01012d8:	85 c0                	test   %eax,%eax
f01012da:	74 0e                	je     f01012ea <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01012dc:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01012e2:	89 15 08 af 22 f0    	mov    %edx,0xf022af08
f01012e8:	eb 0c                	jmp    f01012f6 <mem_init+0x8a>
	else
		npages = npages_basemem;
f01012ea:	8b 15 44 a2 22 f0    	mov    0xf022a244,%edx
f01012f0:	89 15 08 af 22 f0    	mov    %edx,0xf022af08

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012f6:	c1 e0 0c             	shl    $0xc,%eax
f01012f9:	c1 e8 0a             	shr    $0xa,%eax
f01012fc:	50                   	push   %eax
f01012fd:	a1 44 a2 22 f0       	mov    0xf022a244,%eax
f0101302:	c1 e0 0c             	shl    $0xc,%eax
f0101305:	c1 e8 0a             	shr    $0xa,%eax
f0101308:	50                   	push   %eax
f0101309:	a1 08 af 22 f0       	mov    0xf022af08,%eax
f010130e:	c1 e0 0c             	shl    $0xc,%eax
f0101311:	c1 e8 0a             	shr    $0xa,%eax
f0101314:	50                   	push   %eax
f0101315:	68 28 5f 10 f0       	push   $0xf0105f28
f010131a:	e8 34 23 00 00       	call   f0103653 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010131f:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101324:	e8 3b f7 ff ff       	call   f0100a64 <boot_alloc>
f0101329:	a3 0c af 22 f0       	mov    %eax,0xf022af0c
	memset(kern_pgdir, 0, PGSIZE);
f010132e:	83 c4 0c             	add    $0xc,%esp
f0101331:	68 00 10 00 00       	push   $0x1000
f0101336:	6a 00                	push   $0x0
f0101338:	50                   	push   %eax
f0101339:	e8 91 38 00 00       	call   f0104bcf <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010133e:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101343:	83 c4 10             	add    $0x10,%esp
f0101346:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010134b:	77 15                	ja     f0101362 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010134d:	50                   	push   %eax
f010134e:	68 c8 58 10 f0       	push   $0xf01058c8
f0101353:	68 90 00 00 00       	push   $0x90
f0101358:	68 41 67 10 f0       	push   $0xf0106741
f010135d:	e8 de ec ff ff       	call   f0100040 <_panic>
f0101362:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101368:	83 ca 05             	or     $0x5,%edx
f010136b:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f0101371:	a1 08 af 22 f0       	mov    0xf022af08,%eax
f0101376:	c1 e0 03             	shl    $0x3,%eax
f0101379:	e8 e6 f6 ff ff       	call   f0100a64 <boot_alloc>
f010137e:	a3 10 af 22 f0       	mov    %eax,0xf022af10
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101383:	83 ec 04             	sub    $0x4,%esp
f0101386:	8b 0d 08 af 22 f0    	mov    0xf022af08,%ecx
f010138c:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101393:	52                   	push   %edx
f0101394:	6a 00                	push   $0x0
f0101396:	50                   	push   %eax
f0101397:	e8 33 38 00 00       	call   f0104bcf <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*)boot_alloc(NENV * sizeof(struct Env));
f010139c:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f01013a1:	e8 be f6 ff ff       	call   f0100a64 <boot_alloc>
f01013a6:	a3 48 a2 22 f0       	mov    %eax,0xf022a248
	memset(envs, 0, NENV * sizeof(struct Env));
f01013ab:	83 c4 0c             	add    $0xc,%esp
f01013ae:	68 00 f0 01 00       	push   $0x1f000
f01013b3:	6a 00                	push   $0x0
f01013b5:	50                   	push   %eax
f01013b6:	e8 14 38 00 00       	call   f0104bcf <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01013bb:	e8 31 fa ff ff       	call   f0100df1 <page_init>

	check_page_free_list(1);
f01013c0:	b8 01 00 00 00       	mov    $0x1,%eax
f01013c5:	e8 38 f7 ff ff       	call   f0100b02 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01013ca:	83 c4 10             	add    $0x10,%esp
f01013cd:	83 3d 10 af 22 f0 00 	cmpl   $0x0,0xf022af10
f01013d4:	75 17                	jne    f01013ed <mem_init+0x181>
		panic("'pages' is a null pointer!");
f01013d6:	83 ec 04             	sub    $0x4,%esp
f01013d9:	68 3e 68 10 f0       	push   $0xf010683e
f01013de:	68 50 03 00 00       	push   $0x350
f01013e3:	68 41 67 10 f0       	push   $0xf0106741
f01013e8:	e8 53 ec ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013ed:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f01013f2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01013f7:	eb 05                	jmp    f01013fe <mem_init+0x192>
		++nfree;
f01013f9:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013fc:	8b 00                	mov    (%eax),%eax
f01013fe:	85 c0                	test   %eax,%eax
f0101400:	75 f7                	jne    f01013f9 <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101402:	83 ec 0c             	sub    $0xc,%esp
f0101405:	6a 00                	push   $0x0
f0101407:	e8 d7 fa ff ff       	call   f0100ee3 <page_alloc>
f010140c:	89 c7                	mov    %eax,%edi
f010140e:	83 c4 10             	add    $0x10,%esp
f0101411:	85 c0                	test   %eax,%eax
f0101413:	75 19                	jne    f010142e <mem_init+0x1c2>
f0101415:	68 59 68 10 f0       	push   $0xf0106859
f010141a:	68 67 67 10 f0       	push   $0xf0106767
f010141f:	68 58 03 00 00       	push   $0x358
f0101424:	68 41 67 10 f0       	push   $0xf0106741
f0101429:	e8 12 ec ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010142e:	83 ec 0c             	sub    $0xc,%esp
f0101431:	6a 00                	push   $0x0
f0101433:	e8 ab fa ff ff       	call   f0100ee3 <page_alloc>
f0101438:	89 c6                	mov    %eax,%esi
f010143a:	83 c4 10             	add    $0x10,%esp
f010143d:	85 c0                	test   %eax,%eax
f010143f:	75 19                	jne    f010145a <mem_init+0x1ee>
f0101441:	68 6f 68 10 f0       	push   $0xf010686f
f0101446:	68 67 67 10 f0       	push   $0xf0106767
f010144b:	68 59 03 00 00       	push   $0x359
f0101450:	68 41 67 10 f0       	push   $0xf0106741
f0101455:	e8 e6 eb ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010145a:	83 ec 0c             	sub    $0xc,%esp
f010145d:	6a 00                	push   $0x0
f010145f:	e8 7f fa ff ff       	call   f0100ee3 <page_alloc>
f0101464:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101467:	83 c4 10             	add    $0x10,%esp
f010146a:	85 c0                	test   %eax,%eax
f010146c:	75 19                	jne    f0101487 <mem_init+0x21b>
f010146e:	68 85 68 10 f0       	push   $0xf0106885
f0101473:	68 67 67 10 f0       	push   $0xf0106767
f0101478:	68 5a 03 00 00       	push   $0x35a
f010147d:	68 41 67 10 f0       	push   $0xf0106741
f0101482:	e8 b9 eb ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101487:	39 f7                	cmp    %esi,%edi
f0101489:	75 19                	jne    f01014a4 <mem_init+0x238>
f010148b:	68 9b 68 10 f0       	push   $0xf010689b
f0101490:	68 67 67 10 f0       	push   $0xf0106767
f0101495:	68 5d 03 00 00       	push   $0x35d
f010149a:	68 41 67 10 f0       	push   $0xf0106741
f010149f:	e8 9c eb ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014a4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014a7:	39 c6                	cmp    %eax,%esi
f01014a9:	74 04                	je     f01014af <mem_init+0x243>
f01014ab:	39 c7                	cmp    %eax,%edi
f01014ad:	75 19                	jne    f01014c8 <mem_init+0x25c>
f01014af:	68 64 5f 10 f0       	push   $0xf0105f64
f01014b4:	68 67 67 10 f0       	push   $0xf0106767
f01014b9:	68 5e 03 00 00       	push   $0x35e
f01014be:	68 41 67 10 f0       	push   $0xf0106741
f01014c3:	e8 78 eb ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014c8:	8b 0d 10 af 22 f0    	mov    0xf022af10,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014ce:	8b 15 08 af 22 f0    	mov    0xf022af08,%edx
f01014d4:	c1 e2 0c             	shl    $0xc,%edx
f01014d7:	89 f8                	mov    %edi,%eax
f01014d9:	29 c8                	sub    %ecx,%eax
f01014db:	c1 f8 03             	sar    $0x3,%eax
f01014de:	c1 e0 0c             	shl    $0xc,%eax
f01014e1:	39 d0                	cmp    %edx,%eax
f01014e3:	72 19                	jb     f01014fe <mem_init+0x292>
f01014e5:	68 ad 68 10 f0       	push   $0xf01068ad
f01014ea:	68 67 67 10 f0       	push   $0xf0106767
f01014ef:	68 5f 03 00 00       	push   $0x35f
f01014f4:	68 41 67 10 f0       	push   $0xf0106741
f01014f9:	e8 42 eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01014fe:	89 f0                	mov    %esi,%eax
f0101500:	29 c8                	sub    %ecx,%eax
f0101502:	c1 f8 03             	sar    $0x3,%eax
f0101505:	c1 e0 0c             	shl    $0xc,%eax
f0101508:	39 c2                	cmp    %eax,%edx
f010150a:	77 19                	ja     f0101525 <mem_init+0x2b9>
f010150c:	68 ca 68 10 f0       	push   $0xf01068ca
f0101511:	68 67 67 10 f0       	push   $0xf0106767
f0101516:	68 60 03 00 00       	push   $0x360
f010151b:	68 41 67 10 f0       	push   $0xf0106741
f0101520:	e8 1b eb ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101525:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101528:	29 c8                	sub    %ecx,%eax
f010152a:	c1 f8 03             	sar    $0x3,%eax
f010152d:	c1 e0 0c             	shl    $0xc,%eax
f0101530:	39 c2                	cmp    %eax,%edx
f0101532:	77 19                	ja     f010154d <mem_init+0x2e1>
f0101534:	68 e7 68 10 f0       	push   $0xf01068e7
f0101539:	68 67 67 10 f0       	push   $0xf0106767
f010153e:	68 61 03 00 00       	push   $0x361
f0101543:	68 41 67 10 f0       	push   $0xf0106741
f0101548:	e8 f3 ea ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010154d:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f0101552:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101555:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f010155c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010155f:	83 ec 0c             	sub    $0xc,%esp
f0101562:	6a 00                	push   $0x0
f0101564:	e8 7a f9 ff ff       	call   f0100ee3 <page_alloc>
f0101569:	83 c4 10             	add    $0x10,%esp
f010156c:	85 c0                	test   %eax,%eax
f010156e:	74 19                	je     f0101589 <mem_init+0x31d>
f0101570:	68 04 69 10 f0       	push   $0xf0106904
f0101575:	68 67 67 10 f0       	push   $0xf0106767
f010157a:	68 68 03 00 00       	push   $0x368
f010157f:	68 41 67 10 f0       	push   $0xf0106741
f0101584:	e8 b7 ea ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101589:	83 ec 0c             	sub    $0xc,%esp
f010158c:	57                   	push   %edi
f010158d:	e8 d7 f9 ff ff       	call   f0100f69 <page_free>
	page_free(pp1);
f0101592:	89 34 24             	mov    %esi,(%esp)
f0101595:	e8 cf f9 ff ff       	call   f0100f69 <page_free>
	page_free(pp2);
f010159a:	83 c4 04             	add    $0x4,%esp
f010159d:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015a0:	e8 c4 f9 ff ff       	call   f0100f69 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015a5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015ac:	e8 32 f9 ff ff       	call   f0100ee3 <page_alloc>
f01015b1:	89 c6                	mov    %eax,%esi
f01015b3:	83 c4 10             	add    $0x10,%esp
f01015b6:	85 c0                	test   %eax,%eax
f01015b8:	75 19                	jne    f01015d3 <mem_init+0x367>
f01015ba:	68 59 68 10 f0       	push   $0xf0106859
f01015bf:	68 67 67 10 f0       	push   $0xf0106767
f01015c4:	68 6f 03 00 00       	push   $0x36f
f01015c9:	68 41 67 10 f0       	push   $0xf0106741
f01015ce:	e8 6d ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01015d3:	83 ec 0c             	sub    $0xc,%esp
f01015d6:	6a 00                	push   $0x0
f01015d8:	e8 06 f9 ff ff       	call   f0100ee3 <page_alloc>
f01015dd:	89 c7                	mov    %eax,%edi
f01015df:	83 c4 10             	add    $0x10,%esp
f01015e2:	85 c0                	test   %eax,%eax
f01015e4:	75 19                	jne    f01015ff <mem_init+0x393>
f01015e6:	68 6f 68 10 f0       	push   $0xf010686f
f01015eb:	68 67 67 10 f0       	push   $0xf0106767
f01015f0:	68 70 03 00 00       	push   $0x370
f01015f5:	68 41 67 10 f0       	push   $0xf0106741
f01015fa:	e8 41 ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01015ff:	83 ec 0c             	sub    $0xc,%esp
f0101602:	6a 00                	push   $0x0
f0101604:	e8 da f8 ff ff       	call   f0100ee3 <page_alloc>
f0101609:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010160c:	83 c4 10             	add    $0x10,%esp
f010160f:	85 c0                	test   %eax,%eax
f0101611:	75 19                	jne    f010162c <mem_init+0x3c0>
f0101613:	68 85 68 10 f0       	push   $0xf0106885
f0101618:	68 67 67 10 f0       	push   $0xf0106767
f010161d:	68 71 03 00 00       	push   $0x371
f0101622:	68 41 67 10 f0       	push   $0xf0106741
f0101627:	e8 14 ea ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010162c:	39 fe                	cmp    %edi,%esi
f010162e:	75 19                	jne    f0101649 <mem_init+0x3dd>
f0101630:	68 9b 68 10 f0       	push   $0xf010689b
f0101635:	68 67 67 10 f0       	push   $0xf0106767
f010163a:	68 73 03 00 00       	push   $0x373
f010163f:	68 41 67 10 f0       	push   $0xf0106741
f0101644:	e8 f7 e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101649:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010164c:	39 c7                	cmp    %eax,%edi
f010164e:	74 04                	je     f0101654 <mem_init+0x3e8>
f0101650:	39 c6                	cmp    %eax,%esi
f0101652:	75 19                	jne    f010166d <mem_init+0x401>
f0101654:	68 64 5f 10 f0       	push   $0xf0105f64
f0101659:	68 67 67 10 f0       	push   $0xf0106767
f010165e:	68 74 03 00 00       	push   $0x374
f0101663:	68 41 67 10 f0       	push   $0xf0106741
f0101668:	e8 d3 e9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010166d:	83 ec 0c             	sub    $0xc,%esp
f0101670:	6a 00                	push   $0x0
f0101672:	e8 6c f8 ff ff       	call   f0100ee3 <page_alloc>
f0101677:	83 c4 10             	add    $0x10,%esp
f010167a:	85 c0                	test   %eax,%eax
f010167c:	74 19                	je     f0101697 <mem_init+0x42b>
f010167e:	68 04 69 10 f0       	push   $0xf0106904
f0101683:	68 67 67 10 f0       	push   $0xf0106767
f0101688:	68 75 03 00 00       	push   $0x375
f010168d:	68 41 67 10 f0       	push   $0xf0106741
f0101692:	e8 a9 e9 ff ff       	call   f0100040 <_panic>
f0101697:	89 f0                	mov    %esi,%eax
f0101699:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f010169f:	c1 f8 03             	sar    $0x3,%eax
f01016a2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016a5:	89 c2                	mov    %eax,%edx
f01016a7:	c1 ea 0c             	shr    $0xc,%edx
f01016aa:	3b 15 08 af 22 f0    	cmp    0xf022af08,%edx
f01016b0:	72 12                	jb     f01016c4 <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016b2:	50                   	push   %eax
f01016b3:	68 a4 58 10 f0       	push   $0xf01058a4
f01016b8:	6a 58                	push   $0x58
f01016ba:	68 4d 67 10 f0       	push   $0xf010674d
f01016bf:	e8 7c e9 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01016c4:	83 ec 04             	sub    $0x4,%esp
f01016c7:	68 00 10 00 00       	push   $0x1000
f01016cc:	6a 01                	push   $0x1
f01016ce:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016d3:	50                   	push   %eax
f01016d4:	e8 f6 34 00 00       	call   f0104bcf <memset>
	page_free(pp0);
f01016d9:	89 34 24             	mov    %esi,(%esp)
f01016dc:	e8 88 f8 ff ff       	call   f0100f69 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016e1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016e8:	e8 f6 f7 ff ff       	call   f0100ee3 <page_alloc>
f01016ed:	83 c4 10             	add    $0x10,%esp
f01016f0:	85 c0                	test   %eax,%eax
f01016f2:	75 19                	jne    f010170d <mem_init+0x4a1>
f01016f4:	68 13 69 10 f0       	push   $0xf0106913
f01016f9:	68 67 67 10 f0       	push   $0xf0106767
f01016fe:	68 7a 03 00 00       	push   $0x37a
f0101703:	68 41 67 10 f0       	push   $0xf0106741
f0101708:	e8 33 e9 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f010170d:	39 c6                	cmp    %eax,%esi
f010170f:	74 19                	je     f010172a <mem_init+0x4be>
f0101711:	68 31 69 10 f0       	push   $0xf0106931
f0101716:	68 67 67 10 f0       	push   $0xf0106767
f010171b:	68 7b 03 00 00       	push   $0x37b
f0101720:	68 41 67 10 f0       	push   $0xf0106741
f0101725:	e8 16 e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010172a:	89 f0                	mov    %esi,%eax
f010172c:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f0101732:	c1 f8 03             	sar    $0x3,%eax
f0101735:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101738:	89 c2                	mov    %eax,%edx
f010173a:	c1 ea 0c             	shr    $0xc,%edx
f010173d:	3b 15 08 af 22 f0    	cmp    0xf022af08,%edx
f0101743:	72 12                	jb     f0101757 <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101745:	50                   	push   %eax
f0101746:	68 a4 58 10 f0       	push   $0xf01058a4
f010174b:	6a 58                	push   $0x58
f010174d:	68 4d 67 10 f0       	push   $0xf010674d
f0101752:	e8 e9 e8 ff ff       	call   f0100040 <_panic>
f0101757:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010175d:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101763:	80 38 00             	cmpb   $0x0,(%eax)
f0101766:	74 19                	je     f0101781 <mem_init+0x515>
f0101768:	68 41 69 10 f0       	push   $0xf0106941
f010176d:	68 67 67 10 f0       	push   $0xf0106767
f0101772:	68 7e 03 00 00       	push   $0x37e
f0101777:	68 41 67 10 f0       	push   $0xf0106741
f010177c:	e8 bf e8 ff ff       	call   f0100040 <_panic>
f0101781:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101784:	39 d0                	cmp    %edx,%eax
f0101786:	75 db                	jne    f0101763 <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101788:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010178b:	a3 40 a2 22 f0       	mov    %eax,0xf022a240

	// free the pages we took
	page_free(pp0);
f0101790:	83 ec 0c             	sub    $0xc,%esp
f0101793:	56                   	push   %esi
f0101794:	e8 d0 f7 ff ff       	call   f0100f69 <page_free>
	page_free(pp1);
f0101799:	89 3c 24             	mov    %edi,(%esp)
f010179c:	e8 c8 f7 ff ff       	call   f0100f69 <page_free>
	page_free(pp2);
f01017a1:	83 c4 04             	add    $0x4,%esp
f01017a4:	ff 75 d4             	pushl  -0x2c(%ebp)
f01017a7:	e8 bd f7 ff ff       	call   f0100f69 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017ac:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f01017b1:	83 c4 10             	add    $0x10,%esp
f01017b4:	eb 05                	jmp    f01017bb <mem_init+0x54f>
		--nfree;
f01017b6:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017b9:	8b 00                	mov    (%eax),%eax
f01017bb:	85 c0                	test   %eax,%eax
f01017bd:	75 f7                	jne    f01017b6 <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f01017bf:	85 db                	test   %ebx,%ebx
f01017c1:	74 19                	je     f01017dc <mem_init+0x570>
f01017c3:	68 4b 69 10 f0       	push   $0xf010694b
f01017c8:	68 67 67 10 f0       	push   $0xf0106767
f01017cd:	68 8b 03 00 00       	push   $0x38b
f01017d2:	68 41 67 10 f0       	push   $0xf0106741
f01017d7:	e8 64 e8 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017dc:	83 ec 0c             	sub    $0xc,%esp
f01017df:	68 84 5f 10 f0       	push   $0xf0105f84
f01017e4:	e8 6a 1e 00 00       	call   f0103653 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017e9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017f0:	e8 ee f6 ff ff       	call   f0100ee3 <page_alloc>
f01017f5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017f8:	83 c4 10             	add    $0x10,%esp
f01017fb:	85 c0                	test   %eax,%eax
f01017fd:	75 19                	jne    f0101818 <mem_init+0x5ac>
f01017ff:	68 59 68 10 f0       	push   $0xf0106859
f0101804:	68 67 67 10 f0       	push   $0xf0106767
f0101809:	68 f1 03 00 00       	push   $0x3f1
f010180e:	68 41 67 10 f0       	push   $0xf0106741
f0101813:	e8 28 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101818:	83 ec 0c             	sub    $0xc,%esp
f010181b:	6a 00                	push   $0x0
f010181d:	e8 c1 f6 ff ff       	call   f0100ee3 <page_alloc>
f0101822:	89 c3                	mov    %eax,%ebx
f0101824:	83 c4 10             	add    $0x10,%esp
f0101827:	85 c0                	test   %eax,%eax
f0101829:	75 19                	jne    f0101844 <mem_init+0x5d8>
f010182b:	68 6f 68 10 f0       	push   $0xf010686f
f0101830:	68 67 67 10 f0       	push   $0xf0106767
f0101835:	68 f2 03 00 00       	push   $0x3f2
f010183a:	68 41 67 10 f0       	push   $0xf0106741
f010183f:	e8 fc e7 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101844:	83 ec 0c             	sub    $0xc,%esp
f0101847:	6a 00                	push   $0x0
f0101849:	e8 95 f6 ff ff       	call   f0100ee3 <page_alloc>
f010184e:	89 c6                	mov    %eax,%esi
f0101850:	83 c4 10             	add    $0x10,%esp
f0101853:	85 c0                	test   %eax,%eax
f0101855:	75 19                	jne    f0101870 <mem_init+0x604>
f0101857:	68 85 68 10 f0       	push   $0xf0106885
f010185c:	68 67 67 10 f0       	push   $0xf0106767
f0101861:	68 f3 03 00 00       	push   $0x3f3
f0101866:	68 41 67 10 f0       	push   $0xf0106741
f010186b:	e8 d0 e7 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101870:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101873:	75 19                	jne    f010188e <mem_init+0x622>
f0101875:	68 9b 68 10 f0       	push   $0xf010689b
f010187a:	68 67 67 10 f0       	push   $0xf0106767
f010187f:	68 f6 03 00 00       	push   $0x3f6
f0101884:	68 41 67 10 f0       	push   $0xf0106741
f0101889:	e8 b2 e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010188e:	39 c3                	cmp    %eax,%ebx
f0101890:	74 05                	je     f0101897 <mem_init+0x62b>
f0101892:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101895:	75 19                	jne    f01018b0 <mem_init+0x644>
f0101897:	68 64 5f 10 f0       	push   $0xf0105f64
f010189c:	68 67 67 10 f0       	push   $0xf0106767
f01018a1:	68 f7 03 00 00       	push   $0x3f7
f01018a6:	68 41 67 10 f0       	push   $0xf0106741
f01018ab:	e8 90 e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018b0:	a1 40 a2 22 f0       	mov    0xf022a240,%eax
f01018b5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01018b8:	c7 05 40 a2 22 f0 00 	movl   $0x0,0xf022a240
f01018bf:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01018c2:	83 ec 0c             	sub    $0xc,%esp
f01018c5:	6a 00                	push   $0x0
f01018c7:	e8 17 f6 ff ff       	call   f0100ee3 <page_alloc>
f01018cc:	83 c4 10             	add    $0x10,%esp
f01018cf:	85 c0                	test   %eax,%eax
f01018d1:	74 19                	je     f01018ec <mem_init+0x680>
f01018d3:	68 04 69 10 f0       	push   $0xf0106904
f01018d8:	68 67 67 10 f0       	push   $0xf0106767
f01018dd:	68 fe 03 00 00       	push   $0x3fe
f01018e2:	68 41 67 10 f0       	push   $0xf0106741
f01018e7:	e8 54 e7 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01018ec:	83 ec 04             	sub    $0x4,%esp
f01018ef:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01018f2:	50                   	push   %eax
f01018f3:	6a 00                	push   $0x0
f01018f5:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f01018fb:	e8 cb f7 ff ff       	call   f01010cb <page_lookup>
f0101900:	83 c4 10             	add    $0x10,%esp
f0101903:	85 c0                	test   %eax,%eax
f0101905:	74 19                	je     f0101920 <mem_init+0x6b4>
f0101907:	68 a4 5f 10 f0       	push   $0xf0105fa4
f010190c:	68 67 67 10 f0       	push   $0xf0106767
f0101911:	68 01 04 00 00       	push   $0x401
f0101916:	68 41 67 10 f0       	push   $0xf0106741
f010191b:	e8 20 e7 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101920:	6a 02                	push   $0x2
f0101922:	6a 00                	push   $0x0
f0101924:	53                   	push   %ebx
f0101925:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f010192b:	e8 73 f8 ff ff       	call   f01011a3 <page_insert>
f0101930:	83 c4 10             	add    $0x10,%esp
f0101933:	85 c0                	test   %eax,%eax
f0101935:	78 19                	js     f0101950 <mem_init+0x6e4>
f0101937:	68 dc 5f 10 f0       	push   $0xf0105fdc
f010193c:	68 67 67 10 f0       	push   $0xf0106767
f0101941:	68 04 04 00 00       	push   $0x404
f0101946:	68 41 67 10 f0       	push   $0xf0106741
f010194b:	e8 f0 e6 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101950:	83 ec 0c             	sub    $0xc,%esp
f0101953:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101956:	e8 0e f6 ff ff       	call   f0100f69 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010195b:	6a 02                	push   $0x2
f010195d:	6a 00                	push   $0x0
f010195f:	53                   	push   %ebx
f0101960:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101966:	e8 38 f8 ff ff       	call   f01011a3 <page_insert>
f010196b:	83 c4 20             	add    $0x20,%esp
f010196e:	85 c0                	test   %eax,%eax
f0101970:	74 19                	je     f010198b <mem_init+0x71f>
f0101972:	68 0c 60 10 f0       	push   $0xf010600c
f0101977:	68 67 67 10 f0       	push   $0xf0106767
f010197c:	68 08 04 00 00       	push   $0x408
f0101981:	68 41 67 10 f0       	push   $0xf0106741
f0101986:	e8 b5 e6 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010198b:	8b 3d 0c af 22 f0    	mov    0xf022af0c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101991:	a1 10 af 22 f0       	mov    0xf022af10,%eax
f0101996:	89 c1                	mov    %eax,%ecx
f0101998:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010199b:	8b 17                	mov    (%edi),%edx
f010199d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01019a3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019a6:	29 c8                	sub    %ecx,%eax
f01019a8:	c1 f8 03             	sar    $0x3,%eax
f01019ab:	c1 e0 0c             	shl    $0xc,%eax
f01019ae:	39 c2                	cmp    %eax,%edx
f01019b0:	74 19                	je     f01019cb <mem_init+0x75f>
f01019b2:	68 3c 60 10 f0       	push   $0xf010603c
f01019b7:	68 67 67 10 f0       	push   $0xf0106767
f01019bc:	68 09 04 00 00       	push   $0x409
f01019c1:	68 41 67 10 f0       	push   $0xf0106741
f01019c6:	e8 75 e6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01019cb:	ba 00 00 00 00       	mov    $0x0,%edx
f01019d0:	89 f8                	mov    %edi,%eax
f01019d2:	e8 c7 f0 ff ff       	call   f0100a9e <check_va2pa>
f01019d7:	89 da                	mov    %ebx,%edx
f01019d9:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01019dc:	c1 fa 03             	sar    $0x3,%edx
f01019df:	c1 e2 0c             	shl    $0xc,%edx
f01019e2:	39 d0                	cmp    %edx,%eax
f01019e4:	74 19                	je     f01019ff <mem_init+0x793>
f01019e6:	68 64 60 10 f0       	push   $0xf0106064
f01019eb:	68 67 67 10 f0       	push   $0xf0106767
f01019f0:	68 0a 04 00 00       	push   $0x40a
f01019f5:	68 41 67 10 f0       	push   $0xf0106741
f01019fa:	e8 41 e6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01019ff:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a04:	74 19                	je     f0101a1f <mem_init+0x7b3>
f0101a06:	68 56 69 10 f0       	push   $0xf0106956
f0101a0b:	68 67 67 10 f0       	push   $0xf0106767
f0101a10:	68 0b 04 00 00       	push   $0x40b
f0101a15:	68 41 67 10 f0       	push   $0xf0106741
f0101a1a:	e8 21 e6 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101a1f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a22:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a27:	74 19                	je     f0101a42 <mem_init+0x7d6>
f0101a29:	68 67 69 10 f0       	push   $0xf0106967
f0101a2e:	68 67 67 10 f0       	push   $0xf0106767
f0101a33:	68 0c 04 00 00       	push   $0x40c
f0101a38:	68 41 67 10 f0       	push   $0xf0106741
f0101a3d:	e8 fe e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a42:	6a 02                	push   $0x2
f0101a44:	68 00 10 00 00       	push   $0x1000
f0101a49:	56                   	push   %esi
f0101a4a:	57                   	push   %edi
f0101a4b:	e8 53 f7 ff ff       	call   f01011a3 <page_insert>
f0101a50:	83 c4 10             	add    $0x10,%esp
f0101a53:	85 c0                	test   %eax,%eax
f0101a55:	74 19                	je     f0101a70 <mem_init+0x804>
f0101a57:	68 94 60 10 f0       	push   $0xf0106094
f0101a5c:	68 67 67 10 f0       	push   $0xf0106767
f0101a61:	68 0f 04 00 00       	push   $0x40f
f0101a66:	68 41 67 10 f0       	push   $0xf0106741
f0101a6b:	e8 d0 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a70:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a75:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0101a7a:	e8 1f f0 ff ff       	call   f0100a9e <check_va2pa>
f0101a7f:	89 f2                	mov    %esi,%edx
f0101a81:	2b 15 10 af 22 f0    	sub    0xf022af10,%edx
f0101a87:	c1 fa 03             	sar    $0x3,%edx
f0101a8a:	c1 e2 0c             	shl    $0xc,%edx
f0101a8d:	39 d0                	cmp    %edx,%eax
f0101a8f:	74 19                	je     f0101aaa <mem_init+0x83e>
f0101a91:	68 d0 60 10 f0       	push   $0xf01060d0
f0101a96:	68 67 67 10 f0       	push   $0xf0106767
f0101a9b:	68 10 04 00 00       	push   $0x410
f0101aa0:	68 41 67 10 f0       	push   $0xf0106741
f0101aa5:	e8 96 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101aaa:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101aaf:	74 19                	je     f0101aca <mem_init+0x85e>
f0101ab1:	68 78 69 10 f0       	push   $0xf0106978
f0101ab6:	68 67 67 10 f0       	push   $0xf0106767
f0101abb:	68 11 04 00 00       	push   $0x411
f0101ac0:	68 41 67 10 f0       	push   $0xf0106741
f0101ac5:	e8 76 e5 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101aca:	83 ec 0c             	sub    $0xc,%esp
f0101acd:	6a 00                	push   $0x0
f0101acf:	e8 0f f4 ff ff       	call   f0100ee3 <page_alloc>
f0101ad4:	83 c4 10             	add    $0x10,%esp
f0101ad7:	85 c0                	test   %eax,%eax
f0101ad9:	74 19                	je     f0101af4 <mem_init+0x888>
f0101adb:	68 04 69 10 f0       	push   $0xf0106904
f0101ae0:	68 67 67 10 f0       	push   $0xf0106767
f0101ae5:	68 14 04 00 00       	push   $0x414
f0101aea:	68 41 67 10 f0       	push   $0xf0106741
f0101aef:	e8 4c e5 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101af4:	6a 02                	push   $0x2
f0101af6:	68 00 10 00 00       	push   $0x1000
f0101afb:	56                   	push   %esi
f0101afc:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101b02:	e8 9c f6 ff ff       	call   f01011a3 <page_insert>
f0101b07:	83 c4 10             	add    $0x10,%esp
f0101b0a:	85 c0                	test   %eax,%eax
f0101b0c:	74 19                	je     f0101b27 <mem_init+0x8bb>
f0101b0e:	68 94 60 10 f0       	push   $0xf0106094
f0101b13:	68 67 67 10 f0       	push   $0xf0106767
f0101b18:	68 17 04 00 00       	push   $0x417
f0101b1d:	68 41 67 10 f0       	push   $0xf0106741
f0101b22:	e8 19 e5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b27:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b2c:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0101b31:	e8 68 ef ff ff       	call   f0100a9e <check_va2pa>
f0101b36:	89 f2                	mov    %esi,%edx
f0101b38:	2b 15 10 af 22 f0    	sub    0xf022af10,%edx
f0101b3e:	c1 fa 03             	sar    $0x3,%edx
f0101b41:	c1 e2 0c             	shl    $0xc,%edx
f0101b44:	39 d0                	cmp    %edx,%eax
f0101b46:	74 19                	je     f0101b61 <mem_init+0x8f5>
f0101b48:	68 d0 60 10 f0       	push   $0xf01060d0
f0101b4d:	68 67 67 10 f0       	push   $0xf0106767
f0101b52:	68 18 04 00 00       	push   $0x418
f0101b57:	68 41 67 10 f0       	push   $0xf0106741
f0101b5c:	e8 df e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101b61:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b66:	74 19                	je     f0101b81 <mem_init+0x915>
f0101b68:	68 78 69 10 f0       	push   $0xf0106978
f0101b6d:	68 67 67 10 f0       	push   $0xf0106767
f0101b72:	68 19 04 00 00       	push   $0x419
f0101b77:	68 41 67 10 f0       	push   $0xf0106741
f0101b7c:	e8 bf e4 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b81:	83 ec 0c             	sub    $0xc,%esp
f0101b84:	6a 00                	push   $0x0
f0101b86:	e8 58 f3 ff ff       	call   f0100ee3 <page_alloc>
f0101b8b:	83 c4 10             	add    $0x10,%esp
f0101b8e:	85 c0                	test   %eax,%eax
f0101b90:	74 19                	je     f0101bab <mem_init+0x93f>
f0101b92:	68 04 69 10 f0       	push   $0xf0106904
f0101b97:	68 67 67 10 f0       	push   $0xf0106767
f0101b9c:	68 1d 04 00 00       	push   $0x41d
f0101ba1:	68 41 67 10 f0       	push   $0xf0106741
f0101ba6:	e8 95 e4 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101bab:	8b 15 0c af 22 f0    	mov    0xf022af0c,%edx
f0101bb1:	8b 02                	mov    (%edx),%eax
f0101bb3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101bb8:	89 c1                	mov    %eax,%ecx
f0101bba:	c1 e9 0c             	shr    $0xc,%ecx
f0101bbd:	3b 0d 08 af 22 f0    	cmp    0xf022af08,%ecx
f0101bc3:	72 15                	jb     f0101bda <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101bc5:	50                   	push   %eax
f0101bc6:	68 a4 58 10 f0       	push   $0xf01058a4
f0101bcb:	68 20 04 00 00       	push   $0x420
f0101bd0:	68 41 67 10 f0       	push   $0xf0106741
f0101bd5:	e8 66 e4 ff ff       	call   f0100040 <_panic>
f0101bda:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101bdf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101be2:	83 ec 04             	sub    $0x4,%esp
f0101be5:	6a 00                	push   $0x0
f0101be7:	68 00 10 00 00       	push   $0x1000
f0101bec:	52                   	push   %edx
f0101bed:	e8 c3 f3 ff ff       	call   f0100fb5 <pgdir_walk>
f0101bf2:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101bf5:	8d 51 04             	lea    0x4(%ecx),%edx
f0101bf8:	83 c4 10             	add    $0x10,%esp
f0101bfb:	39 d0                	cmp    %edx,%eax
f0101bfd:	74 19                	je     f0101c18 <mem_init+0x9ac>
f0101bff:	68 00 61 10 f0       	push   $0xf0106100
f0101c04:	68 67 67 10 f0       	push   $0xf0106767
f0101c09:	68 21 04 00 00       	push   $0x421
f0101c0e:	68 41 67 10 f0       	push   $0xf0106741
f0101c13:	e8 28 e4 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c18:	6a 06                	push   $0x6
f0101c1a:	68 00 10 00 00       	push   $0x1000
f0101c1f:	56                   	push   %esi
f0101c20:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101c26:	e8 78 f5 ff ff       	call   f01011a3 <page_insert>
f0101c2b:	83 c4 10             	add    $0x10,%esp
f0101c2e:	85 c0                	test   %eax,%eax
f0101c30:	74 19                	je     f0101c4b <mem_init+0x9df>
f0101c32:	68 40 61 10 f0       	push   $0xf0106140
f0101c37:	68 67 67 10 f0       	push   $0xf0106767
f0101c3c:	68 24 04 00 00       	push   $0x424
f0101c41:	68 41 67 10 f0       	push   $0xf0106741
f0101c46:	e8 f5 e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c4b:	8b 3d 0c af 22 f0    	mov    0xf022af0c,%edi
f0101c51:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c56:	89 f8                	mov    %edi,%eax
f0101c58:	e8 41 ee ff ff       	call   f0100a9e <check_va2pa>
f0101c5d:	89 f2                	mov    %esi,%edx
f0101c5f:	2b 15 10 af 22 f0    	sub    0xf022af10,%edx
f0101c65:	c1 fa 03             	sar    $0x3,%edx
f0101c68:	c1 e2 0c             	shl    $0xc,%edx
f0101c6b:	39 d0                	cmp    %edx,%eax
f0101c6d:	74 19                	je     f0101c88 <mem_init+0xa1c>
f0101c6f:	68 d0 60 10 f0       	push   $0xf01060d0
f0101c74:	68 67 67 10 f0       	push   $0xf0106767
f0101c79:	68 25 04 00 00       	push   $0x425
f0101c7e:	68 41 67 10 f0       	push   $0xf0106741
f0101c83:	e8 b8 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101c88:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c8d:	74 19                	je     f0101ca8 <mem_init+0xa3c>
f0101c8f:	68 78 69 10 f0       	push   $0xf0106978
f0101c94:	68 67 67 10 f0       	push   $0xf0106767
f0101c99:	68 26 04 00 00       	push   $0x426
f0101c9e:	68 41 67 10 f0       	push   $0xf0106741
f0101ca3:	e8 98 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101ca8:	83 ec 04             	sub    $0x4,%esp
f0101cab:	6a 00                	push   $0x0
f0101cad:	68 00 10 00 00       	push   $0x1000
f0101cb2:	57                   	push   %edi
f0101cb3:	e8 fd f2 ff ff       	call   f0100fb5 <pgdir_walk>
f0101cb8:	83 c4 10             	add    $0x10,%esp
f0101cbb:	f6 00 04             	testb  $0x4,(%eax)
f0101cbe:	75 19                	jne    f0101cd9 <mem_init+0xa6d>
f0101cc0:	68 80 61 10 f0       	push   $0xf0106180
f0101cc5:	68 67 67 10 f0       	push   $0xf0106767
f0101cca:	68 27 04 00 00       	push   $0x427
f0101ccf:	68 41 67 10 f0       	push   $0xf0106741
f0101cd4:	e8 67 e3 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101cd9:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0101cde:	f6 00 04             	testb  $0x4,(%eax)
f0101ce1:	75 19                	jne    f0101cfc <mem_init+0xa90>
f0101ce3:	68 89 69 10 f0       	push   $0xf0106989
f0101ce8:	68 67 67 10 f0       	push   $0xf0106767
f0101ced:	68 28 04 00 00       	push   $0x428
f0101cf2:	68 41 67 10 f0       	push   $0xf0106741
f0101cf7:	e8 44 e3 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101cfc:	6a 02                	push   $0x2
f0101cfe:	68 00 10 00 00       	push   $0x1000
f0101d03:	56                   	push   %esi
f0101d04:	50                   	push   %eax
f0101d05:	e8 99 f4 ff ff       	call   f01011a3 <page_insert>
f0101d0a:	83 c4 10             	add    $0x10,%esp
f0101d0d:	85 c0                	test   %eax,%eax
f0101d0f:	74 19                	je     f0101d2a <mem_init+0xabe>
f0101d11:	68 94 60 10 f0       	push   $0xf0106094
f0101d16:	68 67 67 10 f0       	push   $0xf0106767
f0101d1b:	68 2b 04 00 00       	push   $0x42b
f0101d20:	68 41 67 10 f0       	push   $0xf0106741
f0101d25:	e8 16 e3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d2a:	83 ec 04             	sub    $0x4,%esp
f0101d2d:	6a 00                	push   $0x0
f0101d2f:	68 00 10 00 00       	push   $0x1000
f0101d34:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101d3a:	e8 76 f2 ff ff       	call   f0100fb5 <pgdir_walk>
f0101d3f:	83 c4 10             	add    $0x10,%esp
f0101d42:	f6 00 02             	testb  $0x2,(%eax)
f0101d45:	75 19                	jne    f0101d60 <mem_init+0xaf4>
f0101d47:	68 b4 61 10 f0       	push   $0xf01061b4
f0101d4c:	68 67 67 10 f0       	push   $0xf0106767
f0101d51:	68 2c 04 00 00       	push   $0x42c
f0101d56:	68 41 67 10 f0       	push   $0xf0106741
f0101d5b:	e8 e0 e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d60:	83 ec 04             	sub    $0x4,%esp
f0101d63:	6a 00                	push   $0x0
f0101d65:	68 00 10 00 00       	push   $0x1000
f0101d6a:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101d70:	e8 40 f2 ff ff       	call   f0100fb5 <pgdir_walk>
f0101d75:	83 c4 10             	add    $0x10,%esp
f0101d78:	f6 00 04             	testb  $0x4,(%eax)
f0101d7b:	74 19                	je     f0101d96 <mem_init+0xb2a>
f0101d7d:	68 e8 61 10 f0       	push   $0xf01061e8
f0101d82:	68 67 67 10 f0       	push   $0xf0106767
f0101d87:	68 2d 04 00 00       	push   $0x42d
f0101d8c:	68 41 67 10 f0       	push   $0xf0106741
f0101d91:	e8 aa e2 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d96:	6a 02                	push   $0x2
f0101d98:	68 00 00 40 00       	push   $0x400000
f0101d9d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101da0:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101da6:	e8 f8 f3 ff ff       	call   f01011a3 <page_insert>
f0101dab:	83 c4 10             	add    $0x10,%esp
f0101dae:	85 c0                	test   %eax,%eax
f0101db0:	78 19                	js     f0101dcb <mem_init+0xb5f>
f0101db2:	68 20 62 10 f0       	push   $0xf0106220
f0101db7:	68 67 67 10 f0       	push   $0xf0106767
f0101dbc:	68 30 04 00 00       	push   $0x430
f0101dc1:	68 41 67 10 f0       	push   $0xf0106741
f0101dc6:	e8 75 e2 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101dcb:	6a 02                	push   $0x2
f0101dcd:	68 00 10 00 00       	push   $0x1000
f0101dd2:	53                   	push   %ebx
f0101dd3:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101dd9:	e8 c5 f3 ff ff       	call   f01011a3 <page_insert>
f0101dde:	83 c4 10             	add    $0x10,%esp
f0101de1:	85 c0                	test   %eax,%eax
f0101de3:	74 19                	je     f0101dfe <mem_init+0xb92>
f0101de5:	68 58 62 10 f0       	push   $0xf0106258
f0101dea:	68 67 67 10 f0       	push   $0xf0106767
f0101def:	68 33 04 00 00       	push   $0x433
f0101df4:	68 41 67 10 f0       	push   $0xf0106741
f0101df9:	e8 42 e2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101dfe:	83 ec 04             	sub    $0x4,%esp
f0101e01:	6a 00                	push   $0x0
f0101e03:	68 00 10 00 00       	push   $0x1000
f0101e08:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101e0e:	e8 a2 f1 ff ff       	call   f0100fb5 <pgdir_walk>
f0101e13:	83 c4 10             	add    $0x10,%esp
f0101e16:	f6 00 04             	testb  $0x4,(%eax)
f0101e19:	74 19                	je     f0101e34 <mem_init+0xbc8>
f0101e1b:	68 e8 61 10 f0       	push   $0xf01061e8
f0101e20:	68 67 67 10 f0       	push   $0xf0106767
f0101e25:	68 34 04 00 00       	push   $0x434
f0101e2a:	68 41 67 10 f0       	push   $0xf0106741
f0101e2f:	e8 0c e2 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e34:	8b 3d 0c af 22 f0    	mov    0xf022af0c,%edi
f0101e3a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e3f:	89 f8                	mov    %edi,%eax
f0101e41:	e8 58 ec ff ff       	call   f0100a9e <check_va2pa>
f0101e46:	89 c1                	mov    %eax,%ecx
f0101e48:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e4b:	89 d8                	mov    %ebx,%eax
f0101e4d:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f0101e53:	c1 f8 03             	sar    $0x3,%eax
f0101e56:	c1 e0 0c             	shl    $0xc,%eax
f0101e59:	39 c1                	cmp    %eax,%ecx
f0101e5b:	74 19                	je     f0101e76 <mem_init+0xc0a>
f0101e5d:	68 94 62 10 f0       	push   $0xf0106294
f0101e62:	68 67 67 10 f0       	push   $0xf0106767
f0101e67:	68 37 04 00 00       	push   $0x437
f0101e6c:	68 41 67 10 f0       	push   $0xf0106741
f0101e71:	e8 ca e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e76:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e7b:	89 f8                	mov    %edi,%eax
f0101e7d:	e8 1c ec ff ff       	call   f0100a9e <check_va2pa>
f0101e82:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101e85:	74 19                	je     f0101ea0 <mem_init+0xc34>
f0101e87:	68 c0 62 10 f0       	push   $0xf01062c0
f0101e8c:	68 67 67 10 f0       	push   $0xf0106767
f0101e91:	68 38 04 00 00       	push   $0x438
f0101e96:	68 41 67 10 f0       	push   $0xf0106741
f0101e9b:	e8 a0 e1 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101ea0:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ea5:	74 19                	je     f0101ec0 <mem_init+0xc54>
f0101ea7:	68 9f 69 10 f0       	push   $0xf010699f
f0101eac:	68 67 67 10 f0       	push   $0xf0106767
f0101eb1:	68 3a 04 00 00       	push   $0x43a
f0101eb6:	68 41 67 10 f0       	push   $0xf0106741
f0101ebb:	e8 80 e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101ec0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ec5:	74 19                	je     f0101ee0 <mem_init+0xc74>
f0101ec7:	68 b0 69 10 f0       	push   $0xf01069b0
f0101ecc:	68 67 67 10 f0       	push   $0xf0106767
f0101ed1:	68 3b 04 00 00       	push   $0x43b
f0101ed6:	68 41 67 10 f0       	push   $0xf0106741
f0101edb:	e8 60 e1 ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101ee0:	83 ec 0c             	sub    $0xc,%esp
f0101ee3:	6a 00                	push   $0x0
f0101ee5:	e8 f9 ef ff ff       	call   f0100ee3 <page_alloc>
f0101eea:	83 c4 10             	add    $0x10,%esp
f0101eed:	85 c0                	test   %eax,%eax
f0101eef:	74 04                	je     f0101ef5 <mem_init+0xc89>
f0101ef1:	39 c6                	cmp    %eax,%esi
f0101ef3:	74 19                	je     f0101f0e <mem_init+0xca2>
f0101ef5:	68 f0 62 10 f0       	push   $0xf01062f0
f0101efa:	68 67 67 10 f0       	push   $0xf0106767
f0101eff:	68 3e 04 00 00       	push   $0x43e
f0101f04:	68 41 67 10 f0       	push   $0xf0106741
f0101f09:	e8 32 e1 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f0e:	83 ec 08             	sub    $0x8,%esp
f0101f11:	6a 00                	push   $0x0
f0101f13:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0101f19:	e8 3c f2 ff ff       	call   f010115a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f1e:	8b 3d 0c af 22 f0    	mov    0xf022af0c,%edi
f0101f24:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f29:	89 f8                	mov    %edi,%eax
f0101f2b:	e8 6e eb ff ff       	call   f0100a9e <check_va2pa>
f0101f30:	83 c4 10             	add    $0x10,%esp
f0101f33:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f36:	74 19                	je     f0101f51 <mem_init+0xce5>
f0101f38:	68 14 63 10 f0       	push   $0xf0106314
f0101f3d:	68 67 67 10 f0       	push   $0xf0106767
f0101f42:	68 42 04 00 00       	push   $0x442
f0101f47:	68 41 67 10 f0       	push   $0xf0106741
f0101f4c:	e8 ef e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f51:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f56:	89 f8                	mov    %edi,%eax
f0101f58:	e8 41 eb ff ff       	call   f0100a9e <check_va2pa>
f0101f5d:	89 da                	mov    %ebx,%edx
f0101f5f:	2b 15 10 af 22 f0    	sub    0xf022af10,%edx
f0101f65:	c1 fa 03             	sar    $0x3,%edx
f0101f68:	c1 e2 0c             	shl    $0xc,%edx
f0101f6b:	39 d0                	cmp    %edx,%eax
f0101f6d:	74 19                	je     f0101f88 <mem_init+0xd1c>
f0101f6f:	68 c0 62 10 f0       	push   $0xf01062c0
f0101f74:	68 67 67 10 f0       	push   $0xf0106767
f0101f79:	68 43 04 00 00       	push   $0x443
f0101f7e:	68 41 67 10 f0       	push   $0xf0106741
f0101f83:	e8 b8 e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101f88:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101f8d:	74 19                	je     f0101fa8 <mem_init+0xd3c>
f0101f8f:	68 56 69 10 f0       	push   $0xf0106956
f0101f94:	68 67 67 10 f0       	push   $0xf0106767
f0101f99:	68 44 04 00 00       	push   $0x444
f0101f9e:	68 41 67 10 f0       	push   $0xf0106741
f0101fa3:	e8 98 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0101fa8:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101fad:	74 19                	je     f0101fc8 <mem_init+0xd5c>
f0101faf:	68 b0 69 10 f0       	push   $0xf01069b0
f0101fb4:	68 67 67 10 f0       	push   $0xf0106767
f0101fb9:	68 45 04 00 00       	push   $0x445
f0101fbe:	68 41 67 10 f0       	push   $0xf0106741
f0101fc3:	e8 78 e0 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101fc8:	6a 00                	push   $0x0
f0101fca:	68 00 10 00 00       	push   $0x1000
f0101fcf:	53                   	push   %ebx
f0101fd0:	57                   	push   %edi
f0101fd1:	e8 cd f1 ff ff       	call   f01011a3 <page_insert>
f0101fd6:	83 c4 10             	add    $0x10,%esp
f0101fd9:	85 c0                	test   %eax,%eax
f0101fdb:	74 19                	je     f0101ff6 <mem_init+0xd8a>
f0101fdd:	68 38 63 10 f0       	push   $0xf0106338
f0101fe2:	68 67 67 10 f0       	push   $0xf0106767
f0101fe7:	68 48 04 00 00       	push   $0x448
f0101fec:	68 41 67 10 f0       	push   $0xf0106741
f0101ff1:	e8 4a e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0101ff6:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ffb:	75 19                	jne    f0102016 <mem_init+0xdaa>
f0101ffd:	68 c1 69 10 f0       	push   $0xf01069c1
f0102002:	68 67 67 10 f0       	push   $0xf0106767
f0102007:	68 49 04 00 00       	push   $0x449
f010200c:	68 41 67 10 f0       	push   $0xf0106741
f0102011:	e8 2a e0 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102016:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102019:	74 19                	je     f0102034 <mem_init+0xdc8>
f010201b:	68 cd 69 10 f0       	push   $0xf01069cd
f0102020:	68 67 67 10 f0       	push   $0xf0106767
f0102025:	68 4a 04 00 00       	push   $0x44a
f010202a:	68 41 67 10 f0       	push   $0xf0106741
f010202f:	e8 0c e0 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102034:	83 ec 08             	sub    $0x8,%esp
f0102037:	68 00 10 00 00       	push   $0x1000
f010203c:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0102042:	e8 13 f1 ff ff       	call   f010115a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102047:	8b 3d 0c af 22 f0    	mov    0xf022af0c,%edi
f010204d:	ba 00 00 00 00       	mov    $0x0,%edx
f0102052:	89 f8                	mov    %edi,%eax
f0102054:	e8 45 ea ff ff       	call   f0100a9e <check_va2pa>
f0102059:	83 c4 10             	add    $0x10,%esp
f010205c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010205f:	74 19                	je     f010207a <mem_init+0xe0e>
f0102061:	68 14 63 10 f0       	push   $0xf0106314
f0102066:	68 67 67 10 f0       	push   $0xf0106767
f010206b:	68 4e 04 00 00       	push   $0x44e
f0102070:	68 41 67 10 f0       	push   $0xf0106741
f0102075:	e8 c6 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010207a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010207f:	89 f8                	mov    %edi,%eax
f0102081:	e8 18 ea ff ff       	call   f0100a9e <check_va2pa>
f0102086:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102089:	74 19                	je     f01020a4 <mem_init+0xe38>
f010208b:	68 70 63 10 f0       	push   $0xf0106370
f0102090:	68 67 67 10 f0       	push   $0xf0106767
f0102095:	68 4f 04 00 00       	push   $0x44f
f010209a:	68 41 67 10 f0       	push   $0xf0106741
f010209f:	e8 9c df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01020a4:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01020a9:	74 19                	je     f01020c4 <mem_init+0xe58>
f01020ab:	68 e2 69 10 f0       	push   $0xf01069e2
f01020b0:	68 67 67 10 f0       	push   $0xf0106767
f01020b5:	68 50 04 00 00       	push   $0x450
f01020ba:	68 41 67 10 f0       	push   $0xf0106741
f01020bf:	e8 7c df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01020c4:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020c9:	74 19                	je     f01020e4 <mem_init+0xe78>
f01020cb:	68 b0 69 10 f0       	push   $0xf01069b0
f01020d0:	68 67 67 10 f0       	push   $0xf0106767
f01020d5:	68 51 04 00 00       	push   $0x451
f01020da:	68 41 67 10 f0       	push   $0xf0106741
f01020df:	e8 5c df ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01020e4:	83 ec 0c             	sub    $0xc,%esp
f01020e7:	6a 00                	push   $0x0
f01020e9:	e8 f5 ed ff ff       	call   f0100ee3 <page_alloc>
f01020ee:	83 c4 10             	add    $0x10,%esp
f01020f1:	39 c3                	cmp    %eax,%ebx
f01020f3:	75 04                	jne    f01020f9 <mem_init+0xe8d>
f01020f5:	85 c0                	test   %eax,%eax
f01020f7:	75 19                	jne    f0102112 <mem_init+0xea6>
f01020f9:	68 98 63 10 f0       	push   $0xf0106398
f01020fe:	68 67 67 10 f0       	push   $0xf0106767
f0102103:	68 54 04 00 00       	push   $0x454
f0102108:	68 41 67 10 f0       	push   $0xf0106741
f010210d:	e8 2e df ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102112:	83 ec 0c             	sub    $0xc,%esp
f0102115:	6a 00                	push   $0x0
f0102117:	e8 c7 ed ff ff       	call   f0100ee3 <page_alloc>
f010211c:	83 c4 10             	add    $0x10,%esp
f010211f:	85 c0                	test   %eax,%eax
f0102121:	74 19                	je     f010213c <mem_init+0xed0>
f0102123:	68 04 69 10 f0       	push   $0xf0106904
f0102128:	68 67 67 10 f0       	push   $0xf0106767
f010212d:	68 57 04 00 00       	push   $0x457
f0102132:	68 41 67 10 f0       	push   $0xf0106741
f0102137:	e8 04 df ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010213c:	8b 0d 0c af 22 f0    	mov    0xf022af0c,%ecx
f0102142:	8b 11                	mov    (%ecx),%edx
f0102144:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010214a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010214d:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f0102153:	c1 f8 03             	sar    $0x3,%eax
f0102156:	c1 e0 0c             	shl    $0xc,%eax
f0102159:	39 c2                	cmp    %eax,%edx
f010215b:	74 19                	je     f0102176 <mem_init+0xf0a>
f010215d:	68 3c 60 10 f0       	push   $0xf010603c
f0102162:	68 67 67 10 f0       	push   $0xf0106767
f0102167:	68 5a 04 00 00       	push   $0x45a
f010216c:	68 41 67 10 f0       	push   $0xf0106741
f0102171:	e8 ca de ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102176:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010217c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010217f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102184:	74 19                	je     f010219f <mem_init+0xf33>
f0102186:	68 67 69 10 f0       	push   $0xf0106967
f010218b:	68 67 67 10 f0       	push   $0xf0106767
f0102190:	68 5c 04 00 00       	push   $0x45c
f0102195:	68 41 67 10 f0       	push   $0xf0106741
f010219a:	e8 a1 de ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f010219f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021a2:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01021a8:	83 ec 0c             	sub    $0xc,%esp
f01021ab:	50                   	push   %eax
f01021ac:	e8 b8 ed ff ff       	call   f0100f69 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01021b1:	83 c4 0c             	add    $0xc,%esp
f01021b4:	6a 01                	push   $0x1
f01021b6:	68 00 10 40 00       	push   $0x401000
f01021bb:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f01021c1:	e8 ef ed ff ff       	call   f0100fb5 <pgdir_walk>
f01021c6:	89 c7                	mov    %eax,%edi
f01021c8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01021cb:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f01021d0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021d3:	8b 40 04             	mov    0x4(%eax),%eax
f01021d6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01021db:	8b 0d 08 af 22 f0    	mov    0xf022af08,%ecx
f01021e1:	89 c2                	mov    %eax,%edx
f01021e3:	c1 ea 0c             	shr    $0xc,%edx
f01021e6:	83 c4 10             	add    $0x10,%esp
f01021e9:	39 ca                	cmp    %ecx,%edx
f01021eb:	72 15                	jb     f0102202 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01021ed:	50                   	push   %eax
f01021ee:	68 a4 58 10 f0       	push   $0xf01058a4
f01021f3:	68 63 04 00 00       	push   $0x463
f01021f8:	68 41 67 10 f0       	push   $0xf0106741
f01021fd:	e8 3e de ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102202:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102207:	39 c7                	cmp    %eax,%edi
f0102209:	74 19                	je     f0102224 <mem_init+0xfb8>
f010220b:	68 f3 69 10 f0       	push   $0xf01069f3
f0102210:	68 67 67 10 f0       	push   $0xf0106767
f0102215:	68 64 04 00 00       	push   $0x464
f010221a:	68 41 67 10 f0       	push   $0xf0106741
f010221f:	e8 1c de ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102224:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102227:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f010222e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102231:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102237:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f010223d:	c1 f8 03             	sar    $0x3,%eax
f0102240:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102243:	89 c2                	mov    %eax,%edx
f0102245:	c1 ea 0c             	shr    $0xc,%edx
f0102248:	39 d1                	cmp    %edx,%ecx
f010224a:	77 12                	ja     f010225e <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010224c:	50                   	push   %eax
f010224d:	68 a4 58 10 f0       	push   $0xf01058a4
f0102252:	6a 58                	push   $0x58
f0102254:	68 4d 67 10 f0       	push   $0xf010674d
f0102259:	e8 e2 dd ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010225e:	83 ec 04             	sub    $0x4,%esp
f0102261:	68 00 10 00 00       	push   $0x1000
f0102266:	68 ff 00 00 00       	push   $0xff
f010226b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102270:	50                   	push   %eax
f0102271:	e8 59 29 00 00       	call   f0104bcf <memset>
	page_free(pp0);
f0102276:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102279:	89 3c 24             	mov    %edi,(%esp)
f010227c:	e8 e8 ec ff ff       	call   f0100f69 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102281:	83 c4 0c             	add    $0xc,%esp
f0102284:	6a 01                	push   $0x1
f0102286:	6a 00                	push   $0x0
f0102288:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f010228e:	e8 22 ed ff ff       	call   f0100fb5 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102293:	89 fa                	mov    %edi,%edx
f0102295:	2b 15 10 af 22 f0    	sub    0xf022af10,%edx
f010229b:	c1 fa 03             	sar    $0x3,%edx
f010229e:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01022a1:	89 d0                	mov    %edx,%eax
f01022a3:	c1 e8 0c             	shr    $0xc,%eax
f01022a6:	83 c4 10             	add    $0x10,%esp
f01022a9:	3b 05 08 af 22 f0    	cmp    0xf022af08,%eax
f01022af:	72 12                	jb     f01022c3 <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022b1:	52                   	push   %edx
f01022b2:	68 a4 58 10 f0       	push   $0xf01058a4
f01022b7:	6a 58                	push   $0x58
f01022b9:	68 4d 67 10 f0       	push   $0xf010674d
f01022be:	e8 7d dd ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01022c3:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01022c9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01022cc:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01022d2:	f6 00 01             	testb  $0x1,(%eax)
f01022d5:	74 19                	je     f01022f0 <mem_init+0x1084>
f01022d7:	68 0b 6a 10 f0       	push   $0xf0106a0b
f01022dc:	68 67 67 10 f0       	push   $0xf0106767
f01022e1:	68 6e 04 00 00       	push   $0x46e
f01022e6:	68 41 67 10 f0       	push   $0xf0106741
f01022eb:	e8 50 dd ff ff       	call   f0100040 <_panic>
f01022f0:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01022f3:	39 d0                	cmp    %edx,%eax
f01022f5:	75 db                	jne    f01022d2 <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01022f7:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f01022fc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102302:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102305:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010230b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010230e:	89 0d 40 a2 22 f0    	mov    %ecx,0xf022a240

	// free the pages we took
	page_free(pp0);
f0102314:	83 ec 0c             	sub    $0xc,%esp
f0102317:	50                   	push   %eax
f0102318:	e8 4c ec ff ff       	call   f0100f69 <page_free>
	page_free(pp1);
f010231d:	89 1c 24             	mov    %ebx,(%esp)
f0102320:	e8 44 ec ff ff       	call   f0100f69 <page_free>
	page_free(pp2);
f0102325:	89 34 24             	mov    %esi,(%esp)
f0102328:	e8 3c ec ff ff       	call   f0100f69 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f010232d:	83 c4 08             	add    $0x8,%esp
f0102330:	68 01 10 00 00       	push   $0x1001
f0102335:	6a 00                	push   $0x0
f0102337:	e8 cd ee ff ff       	call   f0101209 <mmio_map_region>
f010233c:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f010233e:	83 c4 08             	add    $0x8,%esp
f0102341:	68 00 10 00 00       	push   $0x1000
f0102346:	6a 00                	push   $0x0
f0102348:	e8 bc ee ff ff       	call   f0101209 <mmio_map_region>
f010234d:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f010234f:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f0102355:	83 c4 10             	add    $0x10,%esp
f0102358:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f010235e:	76 07                	jbe    f0102367 <mem_init+0x10fb>
f0102360:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102365:	76 19                	jbe    f0102380 <mem_init+0x1114>
f0102367:	68 bc 63 10 f0       	push   $0xf01063bc
f010236c:	68 67 67 10 f0       	push   $0xf0106767
f0102371:	68 7e 04 00 00       	push   $0x47e
f0102376:	68 41 67 10 f0       	push   $0xf0106741
f010237b:	e8 c0 dc ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102380:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f0102386:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f010238c:	77 08                	ja     f0102396 <mem_init+0x112a>
f010238e:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102394:	77 19                	ja     f01023af <mem_init+0x1143>
f0102396:	68 e4 63 10 f0       	push   $0xf01063e4
f010239b:	68 67 67 10 f0       	push   $0xf0106767
f01023a0:	68 7f 04 00 00       	push   $0x47f
f01023a5:	68 41 67 10 f0       	push   $0xf0106741
f01023aa:	e8 91 dc ff ff       	call   f0100040 <_panic>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f01023af:	89 da                	mov    %ebx,%edx
f01023b1:	09 f2                	or     %esi,%edx
f01023b3:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f01023b9:	74 19                	je     f01023d4 <mem_init+0x1168>
f01023bb:	68 0c 64 10 f0       	push   $0xf010640c
f01023c0:	68 67 67 10 f0       	push   $0xf0106767
f01023c5:	68 81 04 00 00       	push   $0x481
f01023ca:	68 41 67 10 f0       	push   $0xf0106741
f01023cf:	e8 6c dc ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f01023d4:	39 c6                	cmp    %eax,%esi
f01023d6:	73 19                	jae    f01023f1 <mem_init+0x1185>
f01023d8:	68 22 6a 10 f0       	push   $0xf0106a22
f01023dd:	68 67 67 10 f0       	push   $0xf0106767
f01023e2:	68 83 04 00 00       	push   $0x483
f01023e7:	68 41 67 10 f0       	push   $0xf0106741
f01023ec:	e8 4f dc ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f01023f1:	8b 3d 0c af 22 f0    	mov    0xf022af0c,%edi
f01023f7:	89 da                	mov    %ebx,%edx
f01023f9:	89 f8                	mov    %edi,%eax
f01023fb:	e8 9e e6 ff ff       	call   f0100a9e <check_va2pa>
f0102400:	85 c0                	test   %eax,%eax
f0102402:	74 19                	je     f010241d <mem_init+0x11b1>
f0102404:	68 34 64 10 f0       	push   $0xf0106434
f0102409:	68 67 67 10 f0       	push   $0xf0106767
f010240e:	68 85 04 00 00       	push   $0x485
f0102413:	68 41 67 10 f0       	push   $0xf0106741
f0102418:	e8 23 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f010241d:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102423:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102426:	89 c2                	mov    %eax,%edx
f0102428:	89 f8                	mov    %edi,%eax
f010242a:	e8 6f e6 ff ff       	call   f0100a9e <check_va2pa>
f010242f:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102434:	74 19                	je     f010244f <mem_init+0x11e3>
f0102436:	68 58 64 10 f0       	push   $0xf0106458
f010243b:	68 67 67 10 f0       	push   $0xf0106767
f0102440:	68 86 04 00 00       	push   $0x486
f0102445:	68 41 67 10 f0       	push   $0xf0106741
f010244a:	e8 f1 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f010244f:	89 f2                	mov    %esi,%edx
f0102451:	89 f8                	mov    %edi,%eax
f0102453:	e8 46 e6 ff ff       	call   f0100a9e <check_va2pa>
f0102458:	85 c0                	test   %eax,%eax
f010245a:	74 19                	je     f0102475 <mem_init+0x1209>
f010245c:	68 88 64 10 f0       	push   $0xf0106488
f0102461:	68 67 67 10 f0       	push   $0xf0106767
f0102466:	68 87 04 00 00       	push   $0x487
f010246b:	68 41 67 10 f0       	push   $0xf0106741
f0102470:	e8 cb db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102475:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f010247b:	89 f8                	mov    %edi,%eax
f010247d:	e8 1c e6 ff ff       	call   f0100a9e <check_va2pa>
f0102482:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102485:	74 19                	je     f01024a0 <mem_init+0x1234>
f0102487:	68 ac 64 10 f0       	push   $0xf01064ac
f010248c:	68 67 67 10 f0       	push   $0xf0106767
f0102491:	68 88 04 00 00       	push   $0x488
f0102496:	68 41 67 10 f0       	push   $0xf0106741
f010249b:	e8 a0 db ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f01024a0:	83 ec 04             	sub    $0x4,%esp
f01024a3:	6a 00                	push   $0x0
f01024a5:	53                   	push   %ebx
f01024a6:	57                   	push   %edi
f01024a7:	e8 09 eb ff ff       	call   f0100fb5 <pgdir_walk>
f01024ac:	83 c4 10             	add    $0x10,%esp
f01024af:	f6 00 1a             	testb  $0x1a,(%eax)
f01024b2:	75 19                	jne    f01024cd <mem_init+0x1261>
f01024b4:	68 d8 64 10 f0       	push   $0xf01064d8
f01024b9:	68 67 67 10 f0       	push   $0xf0106767
f01024be:	68 8a 04 00 00       	push   $0x48a
f01024c3:	68 41 67 10 f0       	push   $0xf0106741
f01024c8:	e8 73 db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f01024cd:	83 ec 04             	sub    $0x4,%esp
f01024d0:	6a 00                	push   $0x0
f01024d2:	53                   	push   %ebx
f01024d3:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f01024d9:	e8 d7 ea ff ff       	call   f0100fb5 <pgdir_walk>
f01024de:	8b 00                	mov    (%eax),%eax
f01024e0:	83 c4 10             	add    $0x10,%esp
f01024e3:	83 e0 04             	and    $0x4,%eax
f01024e6:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01024e9:	74 19                	je     f0102504 <mem_init+0x1298>
f01024eb:	68 1c 65 10 f0       	push   $0xf010651c
f01024f0:	68 67 67 10 f0       	push   $0xf0106767
f01024f5:	68 8b 04 00 00       	push   $0x48b
f01024fa:	68 41 67 10 f0       	push   $0xf0106741
f01024ff:	e8 3c db ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102504:	83 ec 04             	sub    $0x4,%esp
f0102507:	6a 00                	push   $0x0
f0102509:	53                   	push   %ebx
f010250a:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0102510:	e8 a0 ea ff ff       	call   f0100fb5 <pgdir_walk>
f0102515:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f010251b:	83 c4 0c             	add    $0xc,%esp
f010251e:	6a 00                	push   $0x0
f0102520:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102523:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0102529:	e8 87 ea ff ff       	call   f0100fb5 <pgdir_walk>
f010252e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102534:	83 c4 0c             	add    $0xc,%esp
f0102537:	6a 00                	push   $0x0
f0102539:	56                   	push   %esi
f010253a:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0102540:	e8 70 ea ff ff       	call   f0100fb5 <pgdir_walk>
f0102545:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f010254b:	c7 04 24 34 6a 10 f0 	movl   $0xf0106a34,(%esp)
f0102552:	e8 fc 10 00 00       	call   f0103653 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U | PTE_P);
f0102557:	a1 10 af 22 f0       	mov    0xf022af10,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010255c:	83 c4 10             	add    $0x10,%esp
f010255f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102564:	77 15                	ja     f010257b <mem_init+0x130f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102566:	50                   	push   %eax
f0102567:	68 c8 58 10 f0       	push   $0xf01058c8
f010256c:	68 b7 00 00 00       	push   $0xb7
f0102571:	68 41 67 10 f0       	push   $0xf0106741
f0102576:	e8 c5 da ff ff       	call   f0100040 <_panic>
f010257b:	83 ec 08             	sub    $0x8,%esp
f010257e:	6a 05                	push   $0x5
f0102580:	05 00 00 00 10       	add    $0x10000000,%eax
f0102585:	50                   	push   %eax
f0102586:	b9 00 00 40 00       	mov    $0x400000,%ecx
f010258b:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102590:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f0102595:	e8 df ea ff ff       	call   f0101079 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U | PTE_P);
f010259a:	a1 48 a2 22 f0       	mov    0xf022a248,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010259f:	83 c4 10             	add    $0x10,%esp
f01025a2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025a7:	77 15                	ja     f01025be <mem_init+0x1352>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025a9:	50                   	push   %eax
f01025aa:	68 c8 58 10 f0       	push   $0xf01058c8
f01025af:	68 bf 00 00 00       	push   $0xbf
f01025b4:	68 41 67 10 f0       	push   $0xf0106741
f01025b9:	e8 82 da ff ff       	call   f0100040 <_panic>
f01025be:	83 ec 08             	sub    $0x8,%esp
f01025c1:	6a 05                	push   $0x5
f01025c3:	05 00 00 00 10       	add    $0x10000000,%eax
f01025c8:	50                   	push   %eax
f01025c9:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01025ce:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01025d3:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f01025d8:	e8 9c ea ff ff       	call   f0101079 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025dd:	83 c4 10             	add    $0x10,%esp
f01025e0:	b8 00 50 11 f0       	mov    $0xf0115000,%eax
f01025e5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025ea:	77 15                	ja     f0102601 <mem_init+0x1395>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025ec:	50                   	push   %eax
f01025ed:	68 c8 58 10 f0       	push   $0xf01058c8
f01025f2:	68 cb 00 00 00       	push   $0xcb
f01025f7:	68 41 67 10 f0       	push   $0xf0106741
f01025fc:	e8 3f da ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102601:	83 ec 08             	sub    $0x8,%esp
f0102604:	6a 02                	push   $0x2
f0102606:	68 00 50 11 00       	push   $0x115000
f010260b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102610:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102615:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
f010261a:	e8 5a ea ff ff       	call   f0101079 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010261f:	8b 3d 0c af 22 f0    	mov    0xf022af0c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102625:	a1 08 af 22 f0       	mov    0xf022af08,%eax
f010262a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010262d:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102634:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102639:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010263c:	8b 35 10 af 22 f0    	mov    0xf022af10,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102642:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0102645:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102648:	bb 00 00 00 00       	mov    $0x0,%ebx
f010264d:	eb 55                	jmp    f01026a4 <mem_init+0x1438>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010264f:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102655:	89 f8                	mov    %edi,%eax
f0102657:	e8 42 e4 ff ff       	call   f0100a9e <check_va2pa>
f010265c:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102663:	77 15                	ja     f010267a <mem_init+0x140e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102665:	56                   	push   %esi
f0102666:	68 c8 58 10 f0       	push   $0xf01058c8
f010266b:	68 a3 03 00 00       	push   $0x3a3
f0102670:	68 41 67 10 f0       	push   $0xf0106741
f0102675:	e8 c6 d9 ff ff       	call   f0100040 <_panic>
f010267a:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f0102681:	39 d0                	cmp    %edx,%eax
f0102683:	74 19                	je     f010269e <mem_init+0x1432>
f0102685:	68 50 65 10 f0       	push   $0xf0106550
f010268a:	68 67 67 10 f0       	push   $0xf0106767
f010268f:	68 a3 03 00 00       	push   $0x3a3
f0102694:	68 41 67 10 f0       	push   $0xf0106741
f0102699:	e8 a2 d9 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010269e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01026a4:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01026a7:	77 a6                	ja     f010264f <mem_init+0x13e3>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01026a9:	8b 35 48 a2 22 f0    	mov    0xf022a248,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026af:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01026b2:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f01026b7:	89 da                	mov    %ebx,%edx
f01026b9:	89 f8                	mov    %edi,%eax
f01026bb:	e8 de e3 ff ff       	call   f0100a9e <check_va2pa>
f01026c0:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01026c7:	77 15                	ja     f01026de <mem_init+0x1472>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026c9:	56                   	push   %esi
f01026ca:	68 c8 58 10 f0       	push   $0xf01058c8
f01026cf:	68 a8 03 00 00       	push   $0x3a8
f01026d4:	68 41 67 10 f0       	push   $0xf0106741
f01026d9:	e8 62 d9 ff ff       	call   f0100040 <_panic>
f01026de:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f01026e5:	39 d0                	cmp    %edx,%eax
f01026e7:	74 19                	je     f0102702 <mem_init+0x1496>
f01026e9:	68 84 65 10 f0       	push   $0xf0106584
f01026ee:	68 67 67 10 f0       	push   $0xf0106767
f01026f3:	68 a8 03 00 00       	push   $0x3a8
f01026f8:	68 41 67 10 f0       	push   $0xf0106741
f01026fd:	e8 3e d9 ff ff       	call   f0100040 <_panic>
f0102702:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102708:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f010270e:	75 a7                	jne    f01026b7 <mem_init+0x144b>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102710:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0102713:	c1 e6 0c             	shl    $0xc,%esi
f0102716:	bb 00 00 00 00       	mov    $0x0,%ebx
f010271b:	eb 30                	jmp    f010274d <mem_init+0x14e1>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010271d:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102723:	89 f8                	mov    %edi,%eax
f0102725:	e8 74 e3 ff ff       	call   f0100a9e <check_va2pa>
f010272a:	39 c3                	cmp    %eax,%ebx
f010272c:	74 19                	je     f0102747 <mem_init+0x14db>
f010272e:	68 b8 65 10 f0       	push   $0xf01065b8
f0102733:	68 67 67 10 f0       	push   $0xf0106767
f0102738:	68 ac 03 00 00       	push   $0x3ac
f010273d:	68 41 67 10 f0       	push   $0xf0106741
f0102742:	e8 f9 d8 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102747:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010274d:	39 f3                	cmp    %esi,%ebx
f010274f:	72 cc                	jb     f010271d <mem_init+0x14b1>
f0102751:	be 00 c0 22 f0       	mov    $0xf022c000,%esi
f0102756:	c7 45 cc 00 80 ff ef 	movl   $0xefff8000,-0x34(%ebp)
f010275d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102760:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f0102766:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0102769:	89 c3                	mov    %eax,%ebx
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f010276b:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010276e:	05 00 80 00 20       	add    $0x20008000,%eax
f0102773:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102776:	89 da                	mov    %ebx,%edx
f0102778:	89 f8                	mov    %edi,%eax
f010277a:	e8 1f e3 ff ff       	call   f0100a9e <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010277f:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102785:	77 15                	ja     f010279c <mem_init+0x1530>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102787:	56                   	push   %esi
f0102788:	68 c8 58 10 f0       	push   $0xf01058c8
f010278d:	68 b4 03 00 00       	push   $0x3b4
f0102792:	68 41 67 10 f0       	push   $0xf0106741
f0102797:	e8 a4 d8 ff ff       	call   f0100040 <_panic>
f010279c:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010279f:	8d 94 0b 00 c0 22 f0 	lea    -0xfdd4000(%ebx,%ecx,1),%edx
f01027a6:	39 d0                	cmp    %edx,%eax
f01027a8:	74 19                	je     f01027c3 <mem_init+0x1557>
f01027aa:	68 e0 65 10 f0       	push   $0xf01065e0
f01027af:	68 67 67 10 f0       	push   $0xf0106767
f01027b4:	68 b4 03 00 00       	push   $0x3b4
f01027b9:	68 41 67 10 f0       	push   $0xf0106741
f01027be:	e8 7d d8 ff ff       	call   f0100040 <_panic>
f01027c3:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01027c9:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01027cc:	75 a8                	jne    f0102776 <mem_init+0x150a>
f01027ce:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01027d1:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f01027d7:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01027da:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f01027dc:	89 da                	mov    %ebx,%edx
f01027de:	89 f8                	mov    %edi,%eax
f01027e0:	e8 b9 e2 ff ff       	call   f0100a9e <check_va2pa>
f01027e5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01027e8:	74 19                	je     f0102803 <mem_init+0x1597>
f01027ea:	68 28 66 10 f0       	push   $0xf0106628
f01027ef:	68 67 67 10 f0       	push   $0xf0106767
f01027f4:	68 b6 03 00 00       	push   $0x3b6
f01027f9:	68 41 67 10 f0       	push   $0xf0106741
f01027fe:	e8 3d d8 ff ff       	call   f0100040 <_panic>
f0102803:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102809:	39 de                	cmp    %ebx,%esi
f010280b:	75 cf                	jne    f01027dc <mem_init+0x1570>
f010280d:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102810:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f0102817:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f010281e:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102824:	b8 00 c0 26 f0       	mov    $0xf026c000,%eax
f0102829:	39 f0                	cmp    %esi,%eax
f010282b:	0f 85 2c ff ff ff    	jne    f010275d <mem_init+0x14f1>
f0102831:	b8 00 00 00 00       	mov    $0x0,%eax
f0102836:	eb 2a                	jmp    f0102862 <mem_init+0x15f6>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102838:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f010283e:	83 fa 04             	cmp    $0x4,%edx
f0102841:	77 1f                	ja     f0102862 <mem_init+0x15f6>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102843:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102847:	75 7e                	jne    f01028c7 <mem_init+0x165b>
f0102849:	68 4d 6a 10 f0       	push   $0xf0106a4d
f010284e:	68 67 67 10 f0       	push   $0xf0106767
f0102853:	68 c1 03 00 00       	push   $0x3c1
f0102858:	68 41 67 10 f0       	push   $0xf0106741
f010285d:	e8 de d7 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102862:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102867:	76 3f                	jbe    f01028a8 <mem_init+0x163c>
				assert(pgdir[i] & PTE_P);
f0102869:	8b 14 87             	mov    (%edi,%eax,4),%edx
f010286c:	f6 c2 01             	test   $0x1,%dl
f010286f:	75 19                	jne    f010288a <mem_init+0x161e>
f0102871:	68 4d 6a 10 f0       	push   $0xf0106a4d
f0102876:	68 67 67 10 f0       	push   $0xf0106767
f010287b:	68 c5 03 00 00       	push   $0x3c5
f0102880:	68 41 67 10 f0       	push   $0xf0106741
f0102885:	e8 b6 d7 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f010288a:	f6 c2 02             	test   $0x2,%dl
f010288d:	75 38                	jne    f01028c7 <mem_init+0x165b>
f010288f:	68 5e 6a 10 f0       	push   $0xf0106a5e
f0102894:	68 67 67 10 f0       	push   $0xf0106767
f0102899:	68 c6 03 00 00       	push   $0x3c6
f010289e:	68 41 67 10 f0       	push   $0xf0106741
f01028a3:	e8 98 d7 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f01028a8:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01028ac:	74 19                	je     f01028c7 <mem_init+0x165b>
f01028ae:	68 6f 6a 10 f0       	push   $0xf0106a6f
f01028b3:	68 67 67 10 f0       	push   $0xf0106767
f01028b8:	68 c8 03 00 00       	push   $0x3c8
f01028bd:	68 41 67 10 f0       	push   $0xf0106741
f01028c2:	e8 79 d7 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01028c7:	83 c0 01             	add    $0x1,%eax
f01028ca:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01028cf:	0f 86 63 ff ff ff    	jbe    f0102838 <mem_init+0x15cc>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01028d5:	83 ec 0c             	sub    $0xc,%esp
f01028d8:	68 4c 66 10 f0       	push   $0xf010664c
f01028dd:	e8 71 0d 00 00       	call   f0103653 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01028e2:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028e7:	83 c4 10             	add    $0x10,%esp
f01028ea:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01028ef:	77 15                	ja     f0102906 <mem_init+0x169a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028f1:	50                   	push   %eax
f01028f2:	68 c8 58 10 f0       	push   $0xf01058c8
f01028f7:	68 e2 00 00 00       	push   $0xe2
f01028fc:	68 41 67 10 f0       	push   $0xf0106741
f0102901:	e8 3a d7 ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102906:	05 00 00 00 10       	add    $0x10000000,%eax
f010290b:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010290e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102913:	e8 ea e1 ff ff       	call   f0100b02 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102918:	0f 20 c0             	mov    %cr0,%eax
f010291b:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f010291e:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102923:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102926:	83 ec 0c             	sub    $0xc,%esp
f0102929:	6a 00                	push   $0x0
f010292b:	e8 b3 e5 ff ff       	call   f0100ee3 <page_alloc>
f0102930:	89 c3                	mov    %eax,%ebx
f0102932:	83 c4 10             	add    $0x10,%esp
f0102935:	85 c0                	test   %eax,%eax
f0102937:	75 19                	jne    f0102952 <mem_init+0x16e6>
f0102939:	68 59 68 10 f0       	push   $0xf0106859
f010293e:	68 67 67 10 f0       	push   $0xf0106767
f0102943:	68 a0 04 00 00       	push   $0x4a0
f0102948:	68 41 67 10 f0       	push   $0xf0106741
f010294d:	e8 ee d6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102952:	83 ec 0c             	sub    $0xc,%esp
f0102955:	6a 00                	push   $0x0
f0102957:	e8 87 e5 ff ff       	call   f0100ee3 <page_alloc>
f010295c:	89 c7                	mov    %eax,%edi
f010295e:	83 c4 10             	add    $0x10,%esp
f0102961:	85 c0                	test   %eax,%eax
f0102963:	75 19                	jne    f010297e <mem_init+0x1712>
f0102965:	68 6f 68 10 f0       	push   $0xf010686f
f010296a:	68 67 67 10 f0       	push   $0xf0106767
f010296f:	68 a1 04 00 00       	push   $0x4a1
f0102974:	68 41 67 10 f0       	push   $0xf0106741
f0102979:	e8 c2 d6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010297e:	83 ec 0c             	sub    $0xc,%esp
f0102981:	6a 00                	push   $0x0
f0102983:	e8 5b e5 ff ff       	call   f0100ee3 <page_alloc>
f0102988:	89 c6                	mov    %eax,%esi
f010298a:	83 c4 10             	add    $0x10,%esp
f010298d:	85 c0                	test   %eax,%eax
f010298f:	75 19                	jne    f01029aa <mem_init+0x173e>
f0102991:	68 85 68 10 f0       	push   $0xf0106885
f0102996:	68 67 67 10 f0       	push   $0xf0106767
f010299b:	68 a2 04 00 00       	push   $0x4a2
f01029a0:	68 41 67 10 f0       	push   $0xf0106741
f01029a5:	e8 96 d6 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f01029aa:	83 ec 0c             	sub    $0xc,%esp
f01029ad:	53                   	push   %ebx
f01029ae:	e8 b6 e5 ff ff       	call   f0100f69 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029b3:	89 f8                	mov    %edi,%eax
f01029b5:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f01029bb:	c1 f8 03             	sar    $0x3,%eax
f01029be:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029c1:	89 c2                	mov    %eax,%edx
f01029c3:	c1 ea 0c             	shr    $0xc,%edx
f01029c6:	83 c4 10             	add    $0x10,%esp
f01029c9:	3b 15 08 af 22 f0    	cmp    0xf022af08,%edx
f01029cf:	72 12                	jb     f01029e3 <mem_init+0x1777>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029d1:	50                   	push   %eax
f01029d2:	68 a4 58 10 f0       	push   $0xf01058a4
f01029d7:	6a 58                	push   $0x58
f01029d9:	68 4d 67 10 f0       	push   $0xf010674d
f01029de:	e8 5d d6 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01029e3:	83 ec 04             	sub    $0x4,%esp
f01029e6:	68 00 10 00 00       	push   $0x1000
f01029eb:	6a 01                	push   $0x1
f01029ed:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029f2:	50                   	push   %eax
f01029f3:	e8 d7 21 00 00       	call   f0104bcf <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029f8:	89 f0                	mov    %esi,%eax
f01029fa:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f0102a00:	c1 f8 03             	sar    $0x3,%eax
f0102a03:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a06:	89 c2                	mov    %eax,%edx
f0102a08:	c1 ea 0c             	shr    $0xc,%edx
f0102a0b:	83 c4 10             	add    $0x10,%esp
f0102a0e:	3b 15 08 af 22 f0    	cmp    0xf022af08,%edx
f0102a14:	72 12                	jb     f0102a28 <mem_init+0x17bc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a16:	50                   	push   %eax
f0102a17:	68 a4 58 10 f0       	push   $0xf01058a4
f0102a1c:	6a 58                	push   $0x58
f0102a1e:	68 4d 67 10 f0       	push   $0xf010674d
f0102a23:	e8 18 d6 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102a28:	83 ec 04             	sub    $0x4,%esp
f0102a2b:	68 00 10 00 00       	push   $0x1000
f0102a30:	6a 02                	push   $0x2
f0102a32:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a37:	50                   	push   %eax
f0102a38:	e8 92 21 00 00       	call   f0104bcf <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102a3d:	6a 02                	push   $0x2
f0102a3f:	68 00 10 00 00       	push   $0x1000
f0102a44:	57                   	push   %edi
f0102a45:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0102a4b:	e8 53 e7 ff ff       	call   f01011a3 <page_insert>
	assert(pp1->pp_ref == 1);
f0102a50:	83 c4 20             	add    $0x20,%esp
f0102a53:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102a58:	74 19                	je     f0102a73 <mem_init+0x1807>
f0102a5a:	68 56 69 10 f0       	push   $0xf0106956
f0102a5f:	68 67 67 10 f0       	push   $0xf0106767
f0102a64:	68 a7 04 00 00       	push   $0x4a7
f0102a69:	68 41 67 10 f0       	push   $0xf0106741
f0102a6e:	e8 cd d5 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102a73:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102a7a:	01 01 01 
f0102a7d:	74 19                	je     f0102a98 <mem_init+0x182c>
f0102a7f:	68 6c 66 10 f0       	push   $0xf010666c
f0102a84:	68 67 67 10 f0       	push   $0xf0106767
f0102a89:	68 a8 04 00 00       	push   $0x4a8
f0102a8e:	68 41 67 10 f0       	push   $0xf0106741
f0102a93:	e8 a8 d5 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102a98:	6a 02                	push   $0x2
f0102a9a:	68 00 10 00 00       	push   $0x1000
f0102a9f:	56                   	push   %esi
f0102aa0:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0102aa6:	e8 f8 e6 ff ff       	call   f01011a3 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102aab:	83 c4 10             	add    $0x10,%esp
f0102aae:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102ab5:	02 02 02 
f0102ab8:	74 19                	je     f0102ad3 <mem_init+0x1867>
f0102aba:	68 90 66 10 f0       	push   $0xf0106690
f0102abf:	68 67 67 10 f0       	push   $0xf0106767
f0102ac4:	68 aa 04 00 00       	push   $0x4aa
f0102ac9:	68 41 67 10 f0       	push   $0xf0106741
f0102ace:	e8 6d d5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102ad3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102ad8:	74 19                	je     f0102af3 <mem_init+0x1887>
f0102ada:	68 78 69 10 f0       	push   $0xf0106978
f0102adf:	68 67 67 10 f0       	push   $0xf0106767
f0102ae4:	68 ab 04 00 00       	push   $0x4ab
f0102ae9:	68 41 67 10 f0       	push   $0xf0106741
f0102aee:	e8 4d d5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102af3:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102af8:	74 19                	je     f0102b13 <mem_init+0x18a7>
f0102afa:	68 e2 69 10 f0       	push   $0xf01069e2
f0102aff:	68 67 67 10 f0       	push   $0xf0106767
f0102b04:	68 ac 04 00 00       	push   $0x4ac
f0102b09:	68 41 67 10 f0       	push   $0xf0106741
f0102b0e:	e8 2d d5 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b13:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b1a:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b1d:	89 f0                	mov    %esi,%eax
f0102b1f:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f0102b25:	c1 f8 03             	sar    $0x3,%eax
f0102b28:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b2b:	89 c2                	mov    %eax,%edx
f0102b2d:	c1 ea 0c             	shr    $0xc,%edx
f0102b30:	3b 15 08 af 22 f0    	cmp    0xf022af08,%edx
f0102b36:	72 12                	jb     f0102b4a <mem_init+0x18de>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b38:	50                   	push   %eax
f0102b39:	68 a4 58 10 f0       	push   $0xf01058a4
f0102b3e:	6a 58                	push   $0x58
f0102b40:	68 4d 67 10 f0       	push   $0xf010674d
f0102b45:	e8 f6 d4 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102b4a:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102b51:	03 03 03 
f0102b54:	74 19                	je     f0102b6f <mem_init+0x1903>
f0102b56:	68 b4 66 10 f0       	push   $0xf01066b4
f0102b5b:	68 67 67 10 f0       	push   $0xf0106767
f0102b60:	68 ae 04 00 00       	push   $0x4ae
f0102b65:	68 41 67 10 f0       	push   $0xf0106741
f0102b6a:	e8 d1 d4 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102b6f:	83 ec 08             	sub    $0x8,%esp
f0102b72:	68 00 10 00 00       	push   $0x1000
f0102b77:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0102b7d:	e8 d8 e5 ff ff       	call   f010115a <page_remove>
	assert(pp2->pp_ref == 0);
f0102b82:	83 c4 10             	add    $0x10,%esp
f0102b85:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102b8a:	74 19                	je     f0102ba5 <mem_init+0x1939>
f0102b8c:	68 b0 69 10 f0       	push   $0xf01069b0
f0102b91:	68 67 67 10 f0       	push   $0xf0106767
f0102b96:	68 b0 04 00 00       	push   $0x4b0
f0102b9b:	68 41 67 10 f0       	push   $0xf0106741
f0102ba0:	e8 9b d4 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102ba5:	8b 0d 0c af 22 f0    	mov    0xf022af0c,%ecx
f0102bab:	8b 11                	mov    (%ecx),%edx
f0102bad:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102bb3:	89 d8                	mov    %ebx,%eax
f0102bb5:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f0102bbb:	c1 f8 03             	sar    $0x3,%eax
f0102bbe:	c1 e0 0c             	shl    $0xc,%eax
f0102bc1:	39 c2                	cmp    %eax,%edx
f0102bc3:	74 19                	je     f0102bde <mem_init+0x1972>
f0102bc5:	68 3c 60 10 f0       	push   $0xf010603c
f0102bca:	68 67 67 10 f0       	push   $0xf0106767
f0102bcf:	68 b3 04 00 00       	push   $0x4b3
f0102bd4:	68 41 67 10 f0       	push   $0xf0106741
f0102bd9:	e8 62 d4 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102bde:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102be4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102be9:	74 19                	je     f0102c04 <mem_init+0x1998>
f0102beb:	68 67 69 10 f0       	push   $0xf0106967
f0102bf0:	68 67 67 10 f0       	push   $0xf0106767
f0102bf5:	68 b5 04 00 00       	push   $0x4b5
f0102bfa:	68 41 67 10 f0       	push   $0xf0106741
f0102bff:	e8 3c d4 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102c04:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102c0a:	83 ec 0c             	sub    $0xc,%esp
f0102c0d:	53                   	push   %ebx
f0102c0e:	e8 56 e3 ff ff       	call   f0100f69 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102c13:	c7 04 24 e0 66 10 f0 	movl   $0xf01066e0,(%esp)
f0102c1a:	e8 34 0a 00 00       	call   f0103653 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102c1f:	83 c4 10             	add    $0x10,%esp
f0102c22:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c25:	5b                   	pop    %ebx
f0102c26:	5e                   	pop    %esi
f0102c27:	5f                   	pop    %edi
f0102c28:	5d                   	pop    %ebp
f0102c29:	c3                   	ret    

f0102c2a <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102c2a:	55                   	push   %ebp
f0102c2b:	89 e5                	mov    %esp,%ebp
f0102c2d:	57                   	push   %edi
f0102c2e:	56                   	push   %esi
f0102c2f:	53                   	push   %ebx
f0102c30:	83 ec 1c             	sub    $0x1c,%esp
f0102c33:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102c36:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	uint32_t start = (uint32_t)ROUNDDOWN(va, PGSIZE);
f0102c39:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102c3c:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t end = (uint32_t)ROUNDUP(va+len, PGSIZE);
f0102c42:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c45:	03 45 10             	add    0x10(%ebp),%eax
f0102c48:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102c4d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102c52:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(uint32_t i = start;i < end;i += PGSIZE)
f0102c55:	eb 50                	jmp    f0102ca7 <user_mem_check+0x7d>
	{
		pte_t *pte = pgdir_walk(env->env_pgdir, (void *)i, 0);
f0102c57:	83 ec 04             	sub    $0x4,%esp
f0102c5a:	6a 00                	push   $0x0
f0102c5c:	53                   	push   %ebx
f0102c5d:	ff 77 60             	pushl  0x60(%edi)
f0102c60:	e8 50 e3 ff ff       	call   f0100fb5 <pgdir_walk>
// A user program can access a virtual address if (1) the address is below
// ULIM, and (2) the page table gives it permission. 
		//不满足的条件:1.地址大于ULIM 2.pte不存在 3.pte没有PTE_P的权限位 
		//4.pte的权限比perm高，说明当前权限无法访问对应内存
		if(i >= ULIM || !pte || !(*pte & PTE_P) || (*pte & perm) != perm)
f0102c65:	83 c4 10             	add    $0x10,%esp
f0102c68:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102c6e:	77 10                	ja     f0102c80 <user_mem_check+0x56>
f0102c70:	85 c0                	test   %eax,%eax
f0102c72:	74 0c                	je     f0102c80 <user_mem_check+0x56>
f0102c74:	8b 00                	mov    (%eax),%eax
f0102c76:	a8 01                	test   $0x1,%al
f0102c78:	74 06                	je     f0102c80 <user_mem_check+0x56>
f0102c7a:	21 f0                	and    %esi,%eax
f0102c7c:	39 c6                	cmp    %eax,%esi
f0102c7e:	74 21                	je     f0102ca1 <user_mem_check+0x77>
		{
// If there is an error, set the 'user_mem_check_addr' variable to the first
// erroneous virtual address.
			//如果出错的是va之前的地址，需要返回的也应该是va的地址
			if(i < (uint32_t)va)
f0102c80:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0102c83:	73 0f                	jae    f0102c94 <user_mem_check+0x6a>
				user_mem_check_addr = (uint32_t)va;
f0102c85:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c88:	a3 3c a2 22 f0       	mov    %eax,0xf022a23c
			else 
				user_mem_check_addr = i;
			return -E_FAULT;
f0102c8d:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102c92:	eb 1d                	jmp    f0102cb1 <user_mem_check+0x87>
// erroneous virtual address.
			//如果出错的是va之前的地址，需要返回的也应该是va的地址
			if(i < (uint32_t)va)
				user_mem_check_addr = (uint32_t)va;
			else 
				user_mem_check_addr = i;
f0102c94:	89 1d 3c a2 22 f0    	mov    %ebx,0xf022a23c
			return -E_FAULT;
f0102c9a:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102c9f:	eb 10                	jmp    f0102cb1 <user_mem_check+0x87>
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	uint32_t start = (uint32_t)ROUNDDOWN(va, PGSIZE);
	uint32_t end = (uint32_t)ROUNDUP(va+len, PGSIZE);
	for(uint32_t i = start;i < end;i += PGSIZE)
f0102ca1:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102ca7:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102caa:	72 ab                	jb     f0102c57 <user_mem_check+0x2d>
			else 
				user_mem_check_addr = i;
			return -E_FAULT;
		} 
	}
	return 0;
f0102cac:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102cb1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102cb4:	5b                   	pop    %ebx
f0102cb5:	5e                   	pop    %esi
f0102cb6:	5f                   	pop    %edi
f0102cb7:	5d                   	pop    %ebp
f0102cb8:	c3                   	ret    

f0102cb9 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102cb9:	55                   	push   %ebp
f0102cba:	89 e5                	mov    %esp,%ebp
f0102cbc:	53                   	push   %ebx
f0102cbd:	83 ec 04             	sub    $0x4,%esp
f0102cc0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102cc3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cc6:	83 c8 04             	or     $0x4,%eax
f0102cc9:	50                   	push   %eax
f0102cca:	ff 75 10             	pushl  0x10(%ebp)
f0102ccd:	ff 75 0c             	pushl  0xc(%ebp)
f0102cd0:	53                   	push   %ebx
f0102cd1:	e8 54 ff ff ff       	call   f0102c2a <user_mem_check>
f0102cd6:	83 c4 10             	add    $0x10,%esp
f0102cd9:	85 c0                	test   %eax,%eax
f0102cdb:	79 21                	jns    f0102cfe <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102cdd:	83 ec 04             	sub    $0x4,%esp
f0102ce0:	ff 35 3c a2 22 f0    	pushl  0xf022a23c
f0102ce6:	ff 73 48             	pushl  0x48(%ebx)
f0102ce9:	68 0c 67 10 f0       	push   $0xf010670c
f0102cee:	e8 60 09 00 00       	call   f0103653 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102cf3:	89 1c 24             	mov    %ebx,(%esp)
f0102cf6:	e8 62 06 00 00       	call   f010335d <env_destroy>
f0102cfb:	83 c4 10             	add    $0x10,%esp
	}
}
f0102cfe:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102d01:	c9                   	leave  
f0102d02:	c3                   	ret    

f0102d03 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102d03:	55                   	push   %ebp
f0102d04:	89 e5                	mov    %esp,%ebp
f0102d06:	57                   	push   %edi
f0102d07:	56                   	push   %esi
f0102d08:	53                   	push   %ebx
f0102d09:	83 ec 14             	sub    $0x14,%esp
f0102d0c:	89 c7                	mov    %eax,%edi
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	//boot_map_region(e->env_pgdir, va, len, PADDR(envs), PTE_P | PTE_U | PTE_W);
	uint32_t start,end;
	start = ROUNDDOWN((uint32_t)va, PGSIZE);
f0102d0e:	89 d3                	mov    %edx,%ebx
f0102d10:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	end = ROUNDUP((uint32_t)(va + len), PGSIZE);
f0102d16:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102d1d:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	cprintf("start=%d \n",start);
f0102d23:	53                   	push   %ebx
f0102d24:	68 7d 6a 10 f0       	push   $0xf0106a7d
f0102d29:	e8 25 09 00 00       	call   f0103653 <cprintf>
	cprintf("end=%d \n",end);
f0102d2e:	83 c4 08             	add    $0x8,%esp
f0102d31:	56                   	push   %esi
f0102d32:	68 88 6a 10 f0       	push   $0xf0106a88
f0102d37:	e8 17 09 00 00       	call   f0103653 <cprintf>

	struct PageInfo *Page;
	int r;
	for(int i = start;i < end;i += PGSIZE)
f0102d3c:	83 c4 10             	add    $0x10,%esp
f0102d3f:	eb 56                	jmp    f0102d97 <region_alloc+0x94>
	{
		Page = page_alloc(0);
f0102d41:	83 ec 0c             	sub    $0xc,%esp
f0102d44:	6a 00                	push   $0x0
f0102d46:	e8 98 e1 ff ff       	call   f0100ee3 <page_alloc>
		if(!Page)
f0102d4b:	83 c4 10             	add    $0x10,%esp
f0102d4e:	85 c0                	test   %eax,%eax
f0102d50:	75 17                	jne    f0102d69 <region_alloc+0x66>
			panic("page_alloc fail");
f0102d52:	83 ec 04             	sub    $0x4,%esp
f0102d55:	68 91 6a 10 f0       	push   $0xf0106a91
f0102d5a:	68 34 01 00 00       	push   $0x134
f0102d5f:	68 a1 6a 10 f0       	push   $0xf0106aa1
f0102d64:	e8 d7 d2 ff ff       	call   f0100040 <_panic>
		//r = page_insert(e->env_pgdir, Page, va, PTE_P | PTE_U | PTE_W);
		r = page_insert(e->env_pgdir, Page, (void *)i, PTE_U | PTE_W);
f0102d69:	6a 06                	push   $0x6
f0102d6b:	53                   	push   %ebx
f0102d6c:	50                   	push   %eax
f0102d6d:	ff 77 60             	pushl  0x60(%edi)
f0102d70:	e8 2e e4 ff ff       	call   f01011a3 <page_insert>
		if(r != 0)
f0102d75:	83 c4 10             	add    $0x10,%esp
f0102d78:	85 c0                	test   %eax,%eax
f0102d7a:	74 15                	je     f0102d91 <region_alloc+0x8e>
			panic("region_alloc: %e", r);
f0102d7c:	50                   	push   %eax
f0102d7d:	68 ac 6a 10 f0       	push   $0xf0106aac
f0102d82:	68 38 01 00 00       	push   $0x138
f0102d87:	68 a1 6a 10 f0       	push   $0xf0106aa1
f0102d8c:	e8 af d2 ff ff       	call   f0100040 <_panic>
	cprintf("start=%d \n",start);
	cprintf("end=%d \n",end);

	struct PageInfo *Page;
	int r;
	for(int i = start;i < end;i += PGSIZE)
f0102d91:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102d97:	39 de                	cmp    %ebx,%esi
f0102d99:	77 a6                	ja     f0102d41 <region_alloc+0x3e>
		r = page_insert(e->env_pgdir, Page, (void *)i, PTE_U | PTE_W);
		if(r != 0)
			panic("region_alloc: %e", r);
			//panic("region_alloc fail");
	}
}
f0102d9b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102d9e:	5b                   	pop    %ebx
f0102d9f:	5e                   	pop    %esi
f0102da0:	5f                   	pop    %edi
f0102da1:	5d                   	pop    %ebp
f0102da2:	c3                   	ret    

f0102da3 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102da3:	55                   	push   %ebp
f0102da4:	89 e5                	mov    %esp,%ebp
f0102da6:	56                   	push   %esi
f0102da7:	53                   	push   %ebx
f0102da8:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dab:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102dae:	85 c0                	test   %eax,%eax
f0102db0:	75 1a                	jne    f0102dcc <envid2env+0x29>
		*env_store = curenv;
f0102db2:	e8 3b 24 00 00       	call   f01051f2 <cpunum>
f0102db7:	6b c0 74             	imul   $0x74,%eax,%eax
f0102dba:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102dc0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102dc3:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102dc5:	b8 00 00 00 00       	mov    $0x0,%eax
f0102dca:	eb 70                	jmp    f0102e3c <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102dcc:	89 c3                	mov    %eax,%ebx
f0102dce:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102dd4:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102dd7:	03 1d 48 a2 22 f0    	add    0xf022a248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102ddd:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102de1:	74 05                	je     f0102de8 <envid2env+0x45>
f0102de3:	3b 43 48             	cmp    0x48(%ebx),%eax
f0102de6:	74 10                	je     f0102df8 <envid2env+0x55>
		*env_store = 0;
f0102de8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102deb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102df1:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102df6:	eb 44                	jmp    f0102e3c <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102df8:	84 d2                	test   %dl,%dl
f0102dfa:	74 36                	je     f0102e32 <envid2env+0x8f>
f0102dfc:	e8 f1 23 00 00       	call   f01051f2 <cpunum>
f0102e01:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e04:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f0102e0a:	74 26                	je     f0102e32 <envid2env+0x8f>
f0102e0c:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102e0f:	e8 de 23 00 00       	call   f01051f2 <cpunum>
f0102e14:	6b c0 74             	imul   $0x74,%eax,%eax
f0102e17:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0102e1d:	3b 70 48             	cmp    0x48(%eax),%esi
f0102e20:	74 10                	je     f0102e32 <envid2env+0x8f>
		*env_store = 0;
f0102e22:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e25:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102e2b:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102e30:	eb 0a                	jmp    f0102e3c <envid2env+0x99>
	}

	*env_store = e;
f0102e32:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e35:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102e37:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102e3c:	5b                   	pop    %ebx
f0102e3d:	5e                   	pop    %esi
f0102e3e:	5d                   	pop    %ebp
f0102e3f:	c3                   	ret    

f0102e40 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102e40:	55                   	push   %ebp
f0102e41:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102e43:	b8 20 f3 11 f0       	mov    $0xf011f320,%eax
f0102e48:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102e4b:	b8 23 00 00 00       	mov    $0x23,%eax
f0102e50:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102e52:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102e54:	b8 10 00 00 00       	mov    $0x10,%eax
f0102e59:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102e5b:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102e5d:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102e5f:	ea 66 2e 10 f0 08 00 	ljmp   $0x8,$0xf0102e66
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102e66:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e6b:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102e6e:	5d                   	pop    %ebp
f0102e6f:	c3                   	ret    

f0102e70 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102e70:	55                   	push   %ebp
f0102e71:	89 e5                	mov    %esp,%ebp
f0102e73:	56                   	push   %esi
f0102e74:	53                   	push   %ebx
	// LAB 3: Your code here.
	// struct Env* envs;
	// env_free_list = NULL;
	for(int i = NENV - 1;i >= 0;i--)
	{
		envs[i].env_id = 0;
f0102e75:	8b 35 48 a2 22 f0    	mov    0xf022a248,%esi
f0102e7b:	8b 15 4c a2 22 f0    	mov    0xf022a24c,%edx
f0102e81:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f0102e87:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f0102e8a:	89 c1                	mov    %eax,%ecx
f0102e8c:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f0102e93:	89 50 44             	mov    %edx,0x44(%eax)
f0102e96:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];
f0102e99:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	// struct Env* envs;
	// env_free_list = NULL;
	for(int i = NENV - 1;i >= 0;i--)
f0102e9b:	39 d8                	cmp    %ebx,%eax
f0102e9d:	75 eb                	jne    f0102e8a <env_init+0x1a>
f0102e9f:	89 35 4c a2 22 f0    	mov    %esi,0xf022a24c
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
		//envs[i].env_status = 
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f0102ea5:	e8 96 ff ff ff       	call   f0102e40 <env_init_percpu>
}
f0102eaa:	5b                   	pop    %ebx
f0102eab:	5e                   	pop    %esi
f0102eac:	5d                   	pop    %ebp
f0102ead:	c3                   	ret    

f0102eae <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102eae:	55                   	push   %ebp
f0102eaf:	89 e5                	mov    %esp,%ebp
f0102eb1:	56                   	push   %esi
f0102eb2:	53                   	push   %ebx
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102eb3:	8b 1d 4c a2 22 f0    	mov    0xf022a24c,%ebx
f0102eb9:	85 db                	test   %ebx,%ebx
f0102ebb:	0f 84 64 01 00 00    	je     f0103025 <env_alloc+0x177>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102ec1:	83 ec 0c             	sub    $0xc,%esp
f0102ec4:	6a 01                	push   $0x1
f0102ec6:	e8 18 e0 ff ff       	call   f0100ee3 <page_alloc>
f0102ecb:	89 c6                	mov    %eax,%esi
f0102ecd:	83 c4 10             	add    $0x10,%esp
f0102ed0:	85 c0                	test   %eax,%eax
f0102ed2:	0f 84 54 01 00 00    	je     f010302c <env_alloc+0x17e>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102ed8:	2b 05 10 af 22 f0    	sub    0xf022af10,%eax
f0102ede:	c1 f8 03             	sar    $0x3,%eax
f0102ee1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ee4:	89 c2                	mov    %eax,%edx
f0102ee6:	c1 ea 0c             	shr    $0xc,%edx
f0102ee9:	3b 15 08 af 22 f0    	cmp    0xf022af08,%edx
f0102eef:	72 12                	jb     f0102f03 <env_alloc+0x55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ef1:	50                   	push   %eax
f0102ef2:	68 a4 58 10 f0       	push   $0xf01058a4
f0102ef7:	6a 58                	push   $0x58
f0102ef9:	68 4d 67 10 f0       	push   $0xf010674d
f0102efe:	e8 3d d1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102f03:	2d 00 00 00 10       	sub    $0x10000000,%eax
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	// p = page_alloc(ALLOC_ZERO);
	e->env_pgdir = page2kva(p);
f0102f08:	89 43 60             	mov    %eax,0x60(%ebx)
	//memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
	memmove(e->env_pgdir, kern_pgdir, PGSIZE);
f0102f0b:	83 ec 04             	sub    $0x4,%esp
f0102f0e:	68 00 10 00 00       	push   $0x1000
f0102f13:	ff 35 0c af 22 f0    	pushl  0xf022af0c
f0102f19:	50                   	push   %eax
f0102f1a:	e8 fd 1c 00 00       	call   f0104c1c <memmove>
	p->pp_ref++;
f0102f1f:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102f24:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f27:	83 c4 10             	add    $0x10,%esp
f0102f2a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102f2f:	77 15                	ja     f0102f46 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f31:	50                   	push   %eax
f0102f32:	68 c8 58 10 f0       	push   $0xf01058c8
f0102f37:	68 c9 00 00 00       	push   $0xc9
f0102f3c:	68 a1 6a 10 f0       	push   $0xf0106aa1
f0102f41:	e8 fa d0 ff ff       	call   f0100040 <_panic>
f0102f46:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102f4c:	83 ca 05             	or     $0x5,%edx
f0102f4f:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102f55:	8b 43 48             	mov    0x48(%ebx),%eax
f0102f58:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102f5d:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102f62:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102f67:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102f6a:	89 da                	mov    %ebx,%edx
f0102f6c:	2b 15 48 a2 22 f0    	sub    0xf022a248,%edx
f0102f72:	c1 fa 02             	sar    $0x2,%edx
f0102f75:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0102f7b:	09 d0                	or     %edx,%eax
f0102f7d:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102f80:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f83:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102f86:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102f8d:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102f94:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102f9b:	83 ec 04             	sub    $0x4,%esp
f0102f9e:	6a 44                	push   $0x44
f0102fa0:	6a 00                	push   $0x0
f0102fa2:	53                   	push   %ebx
f0102fa3:	e8 27 1c 00 00       	call   f0104bcf <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102fa8:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102fae:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102fb4:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102fba:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102fc1:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0102fc7:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0102fce:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0102fd2:	8b 43 44             	mov    0x44(%ebx),%eax
f0102fd5:	a3 4c a2 22 f0       	mov    %eax,0xf022a24c
	*newenv_store = e;
f0102fda:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fdd:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102fdf:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0102fe2:	e8 0b 22 00 00       	call   f01051f2 <cpunum>
f0102fe7:	6b c0 74             	imul   $0x74,%eax,%eax
f0102fea:	83 c4 10             	add    $0x10,%esp
f0102fed:	ba 00 00 00 00       	mov    $0x0,%edx
f0102ff2:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0102ff9:	74 11                	je     f010300c <env_alloc+0x15e>
f0102ffb:	e8 f2 21 00 00       	call   f01051f2 <cpunum>
f0103000:	6b c0 74             	imul   $0x74,%eax,%eax
f0103003:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103009:	8b 50 48             	mov    0x48(%eax),%edx
f010300c:	83 ec 04             	sub    $0x4,%esp
f010300f:	53                   	push   %ebx
f0103010:	52                   	push   %edx
f0103011:	68 bd 6a 10 f0       	push   $0xf0106abd
f0103016:	e8 38 06 00 00       	call   f0103653 <cprintf>
	return 0;
f010301b:	83 c4 10             	add    $0x10,%esp
f010301e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103023:	eb 0c                	jmp    f0103031 <env_alloc+0x183>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103025:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010302a:	eb 05                	jmp    f0103031 <env_alloc+0x183>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f010302c:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103031:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103034:	5b                   	pop    %ebx
f0103035:	5e                   	pop    %esi
f0103036:	5d                   	pop    %ebp
f0103037:	c3                   	ret    

f0103038 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103038:	55                   	push   %ebp
f0103039:	89 e5                	mov    %esp,%ebp
f010303b:	57                   	push   %edi
f010303c:	56                   	push   %esi
f010303d:	53                   	push   %ebx
f010303e:	83 ec 34             	sub    $0x34,%esp
f0103041:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int r;
	r = env_alloc(&e, 0);
f0103044:	6a 00                	push   $0x0
f0103046:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103049:	50                   	push   %eax
f010304a:	e8 5f fe ff ff       	call   f0102eae <env_alloc>
	if(r != 0)
f010304f:	83 c4 10             	add    $0x10,%esp
f0103052:	85 c0                	test   %eax,%eax
f0103054:	74 15                	je     f010306b <env_create+0x33>
		panic("env_create: %e", r);
f0103056:	50                   	push   %eax
f0103057:	68 d2 6a 10 f0       	push   $0xf0106ad2
f010305c:	68 ad 01 00 00       	push   $0x1ad
f0103061:	68 a1 6a 10 f0       	push   $0xf0106aa1
f0103066:	e8 d5 cf ff ff       	call   f0100040 <_panic>
	//if(env_alloc(&e,0) != 0)
	//	panic("env_alloc fail");
	e->env_type = type;
f010306b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010306e:	89 c2                	mov    %eax,%edx
f0103070:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103073:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103076:	89 42 50             	mov    %eax,0x50(%edx)
	struct Elf *elf;
	// 强制类型转换，将binary后的内存空间内容按照结构ELF的格式读取
	elf = (struct Elf *)binary;
	// is this a valid ELF? 判断是否是ELF
	// ELF头开头的结构体叫做魔数,是一个16位的数组
	if(elf->e_magic != ELF_MAGIC)
f0103079:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f010307f:	74 17                	je     f0103098 <env_create+0x60>
		panic("load segements fail");
f0103081:	83 ec 04             	sub    $0x4,%esp
f0103084:	68 e1 6a 10 f0       	push   $0xf0106ae1
f0103089:	68 7a 01 00 00       	push   $0x17a
f010308e:	68 a1 6a 10 f0       	push   $0xf0106aa1
f0103093:	e8 a8 cf ff ff       	call   f0100040 <_panic>
	// load each program segment (ignores ph flags)
	// e_phoff 程序头表的文件偏移地址
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
f0103098:	89 fb                	mov    %edi,%ebx
f010309a:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f010309d:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01030a1:	c1 e6 05             	shl    $0x5,%esi
f01030a4:	01 de                	add    %ebx,%esi
	// 因为后面需要访问刚分配的内存，所以需要将env_pgdir装入cr3，使二级页表能够运作
	lcr3(PADDR(e->env_pgdir));
f01030a6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030a9:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030ac:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030b1:	77 15                	ja     f01030c8 <env_create+0x90>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030b3:	50                   	push   %eax
f01030b4:	68 c8 58 10 f0       	push   $0xf01058c8
f01030b9:	68 80 01 00 00       	push   $0x180
f01030be:	68 a1 6a 10 f0       	push   $0xf0106aa1
f01030c3:	e8 78 cf ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01030c8:	05 00 00 00 10       	add    $0x10000000,%eax
f01030cd:	0f 22 d8             	mov    %eax,%cr3
f01030d0:	eb 60                	jmp    f0103132 <env_create+0xfa>

	for (; ph < eph; ph++)
	{
		// 	(The ELF header should have ph->p_filesz <= ph->p_memsz.)
		if(ph->p_filesz > ph->p_memsz)
f01030d2:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01030d5:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f01030d8:	76 17                	jbe    f01030f1 <env_create+0xb9>
			panic("memory is not enough for file");
f01030da:	83 ec 04             	sub    $0x4,%esp
f01030dd:	68 f5 6a 10 f0       	push   $0xf0106af5
f01030e2:	68 86 01 00 00       	push   $0x186
f01030e7:	68 a1 6a 10 f0       	push   $0xf0106aa1
f01030ec:	e8 4f cf ff ff       	call   f0100040 <_panic>
		if(ph->p_type == ELF_PROG_LOAD)
f01030f1:	83 3b 01             	cmpl   $0x1,(%ebx)
f01030f4:	75 39                	jne    f010312f <env_create+0xf7>
		{
		//  Each segment's virtual address can be found in ph->p_va
		//  and its size in memory can be found in ph->p_memsz.
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f01030f6:	8b 53 08             	mov    0x8(%ebx),%edx
f01030f9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030fc:	e8 02 fc ff ff       	call   f0102d03 <region_alloc>
		//  The ph->p_filesz bytes from the ELF binary, starting at
		//  'binary + ph->p_offset', should be copied to virtual address
		//  ph->p_va. 
			//memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0103101:	83 ec 04             	sub    $0x4,%esp
f0103104:	ff 73 10             	pushl  0x10(%ebx)
f0103107:	89 f8                	mov    %edi,%eax
f0103109:	03 43 04             	add    0x4(%ebx),%eax
f010310c:	50                   	push   %eax
f010310d:	ff 73 08             	pushl  0x8(%ebx)
f0103110:	e8 07 1b 00 00       	call   f0104c1c <memmove>
        //	Any remaining memory bytes should be cleared to zero.
		    memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
f0103115:	8b 43 10             	mov    0x10(%ebx),%eax
f0103118:	83 c4 0c             	add    $0xc,%esp
f010311b:	8b 53 14             	mov    0x14(%ebx),%edx
f010311e:	29 c2                	sub    %eax,%edx
f0103120:	52                   	push   %edx
f0103121:	6a 00                	push   $0x0
f0103123:	03 43 08             	add    0x8(%ebx),%eax
f0103126:	50                   	push   %eax
f0103127:	e8 a3 1a 00 00       	call   f0104bcf <memset>
f010312c:	83 c4 10             	add    $0x10,%esp
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
	eph = ph + elf->e_phnum;
	// 因为后面需要访问刚分配的内存，所以需要将env_pgdir装入cr3，使二级页表能够运作
	lcr3(PADDR(e->env_pgdir));

	for (; ph < eph; ph++)
f010312f:	83 c3 20             	add    $0x20,%ebx
f0103132:	39 de                	cmp    %ebx,%esi
f0103134:	77 9c                	ja     f01030d2 <env_create+0x9a>
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
        //	Any remaining memory bytes should be cleared to zero.
		    memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
		}
	}
	e->env_tf.tf_eip = elf->e_entry;
f0103136:	8b 47 18             	mov    0x18(%edi),%eax
f0103139:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010313c:	89 47 30             	mov    %eax,0x30(%edi)
	lcr3(PADDR(kern_pgdir));
f010313f:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103144:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103149:	77 15                	ja     f0103160 <env_create+0x128>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010314b:	50                   	push   %eax
f010314c:	68 c8 58 10 f0       	push   $0xf01058c8
f0103151:	68 96 01 00 00       	push   $0x196
f0103156:	68 a1 6a 10 f0       	push   $0xf0106aa1
f010315b:	e8 e0 ce ff ff       	call   f0100040 <_panic>
f0103160:	05 00 00 00 10       	add    $0x10000000,%eax
f0103165:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *) USTACKTOP-PGSIZE, PGSIZE);
f0103168:	b9 00 10 00 00       	mov    $0x1000,%ecx
f010316d:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103172:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103175:	e8 89 fb ff ff       	call   f0102d03 <region_alloc>
		panic("env_create: %e", r);
	//if(env_alloc(&e,0) != 0)
	//	panic("env_alloc fail");
	e->env_type = type;
	load_icode(e, binary);
}
f010317a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010317d:	5b                   	pop    %ebx
f010317e:	5e                   	pop    %esi
f010317f:	5f                   	pop    %edi
f0103180:	5d                   	pop    %ebp
f0103181:	c3                   	ret    

f0103182 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103182:	55                   	push   %ebp
f0103183:	89 e5                	mov    %esp,%ebp
f0103185:	57                   	push   %edi
f0103186:	56                   	push   %esi
f0103187:	53                   	push   %ebx
f0103188:	83 ec 1c             	sub    $0x1c,%esp
f010318b:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f010318e:	e8 5f 20 00 00       	call   f01051f2 <cpunum>
f0103193:	6b c0 74             	imul   $0x74,%eax,%eax
f0103196:	39 b8 28 b0 22 f0    	cmp    %edi,-0xfdd4fd8(%eax)
f010319c:	75 29                	jne    f01031c7 <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f010319e:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031a3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031a8:	77 15                	ja     f01031bf <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031aa:	50                   	push   %eax
f01031ab:	68 c8 58 10 f0       	push   $0xf01058c8
f01031b0:	68 c2 01 00 00       	push   $0x1c2
f01031b5:	68 a1 6a 10 f0       	push   $0xf0106aa1
f01031ba:	e8 81 ce ff ff       	call   f0100040 <_panic>
f01031bf:	05 00 00 00 10       	add    $0x10000000,%eax
f01031c4:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01031c7:	8b 5f 48             	mov    0x48(%edi),%ebx
f01031ca:	e8 23 20 00 00       	call   f01051f2 <cpunum>
f01031cf:	6b c0 74             	imul   $0x74,%eax,%eax
f01031d2:	ba 00 00 00 00       	mov    $0x0,%edx
f01031d7:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f01031de:	74 11                	je     f01031f1 <env_free+0x6f>
f01031e0:	e8 0d 20 00 00       	call   f01051f2 <cpunum>
f01031e5:	6b c0 74             	imul   $0x74,%eax,%eax
f01031e8:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01031ee:	8b 50 48             	mov    0x48(%eax),%edx
f01031f1:	83 ec 04             	sub    $0x4,%esp
f01031f4:	53                   	push   %ebx
f01031f5:	52                   	push   %edx
f01031f6:	68 13 6b 10 f0       	push   $0xf0106b13
f01031fb:	e8 53 04 00 00       	call   f0103653 <cprintf>
f0103200:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103203:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010320a:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010320d:	89 d0                	mov    %edx,%eax
f010320f:	c1 e0 02             	shl    $0x2,%eax
f0103212:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103215:	8b 47 60             	mov    0x60(%edi),%eax
f0103218:	8b 34 90             	mov    (%eax,%edx,4),%esi
f010321b:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103221:	0f 84 a8 00 00 00    	je     f01032cf <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103227:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010322d:	89 f0                	mov    %esi,%eax
f010322f:	c1 e8 0c             	shr    $0xc,%eax
f0103232:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103235:	39 05 08 af 22 f0    	cmp    %eax,0xf022af08
f010323b:	77 15                	ja     f0103252 <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010323d:	56                   	push   %esi
f010323e:	68 a4 58 10 f0       	push   $0xf01058a4
f0103243:	68 d1 01 00 00       	push   $0x1d1
f0103248:	68 a1 6a 10 f0       	push   $0xf0106aa1
f010324d:	e8 ee cd ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103252:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103255:	c1 e0 16             	shl    $0x16,%eax
f0103258:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010325b:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103260:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103267:	01 
f0103268:	74 17                	je     f0103281 <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010326a:	83 ec 08             	sub    $0x8,%esp
f010326d:	89 d8                	mov    %ebx,%eax
f010326f:	c1 e0 0c             	shl    $0xc,%eax
f0103272:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103275:	50                   	push   %eax
f0103276:	ff 77 60             	pushl  0x60(%edi)
f0103279:	e8 dc de ff ff       	call   f010115a <page_remove>
f010327e:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103281:	83 c3 01             	add    $0x1,%ebx
f0103284:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f010328a:	75 d4                	jne    f0103260 <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f010328c:	8b 47 60             	mov    0x60(%edi),%eax
f010328f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103292:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103299:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010329c:	3b 05 08 af 22 f0    	cmp    0xf022af08,%eax
f01032a2:	72 14                	jb     f01032b8 <env_free+0x136>
		panic("pa2page called with invalid pa");
f01032a4:	83 ec 04             	sub    $0x4,%esp
f01032a7:	68 08 5f 10 f0       	push   $0xf0105f08
f01032ac:	6a 51                	push   $0x51
f01032ae:	68 4d 67 10 f0       	push   $0xf010674d
f01032b3:	e8 88 cd ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01032b8:	83 ec 0c             	sub    $0xc,%esp
f01032bb:	a1 10 af 22 f0       	mov    0xf022af10,%eax
f01032c0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01032c3:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01032c6:	50                   	push   %eax
f01032c7:	e8 c2 dc ff ff       	call   f0100f8e <page_decref>
f01032cc:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01032cf:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01032d3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01032d6:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01032db:	0f 85 29 ff ff ff    	jne    f010320a <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01032e1:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01032e4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01032e9:	77 15                	ja     f0103300 <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01032eb:	50                   	push   %eax
f01032ec:	68 c8 58 10 f0       	push   $0xf01058c8
f01032f1:	68 df 01 00 00       	push   $0x1df
f01032f6:	68 a1 6a 10 f0       	push   $0xf0106aa1
f01032fb:	e8 40 cd ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103300:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103307:	05 00 00 00 10       	add    $0x10000000,%eax
f010330c:	c1 e8 0c             	shr    $0xc,%eax
f010330f:	3b 05 08 af 22 f0    	cmp    0xf022af08,%eax
f0103315:	72 14                	jb     f010332b <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f0103317:	83 ec 04             	sub    $0x4,%esp
f010331a:	68 08 5f 10 f0       	push   $0xf0105f08
f010331f:	6a 51                	push   $0x51
f0103321:	68 4d 67 10 f0       	push   $0xf010674d
f0103326:	e8 15 cd ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f010332b:	83 ec 0c             	sub    $0xc,%esp
f010332e:	8b 15 10 af 22 f0    	mov    0xf022af10,%edx
f0103334:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103337:	50                   	push   %eax
f0103338:	e8 51 dc ff ff       	call   f0100f8e <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010333d:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103344:	a1 4c a2 22 f0       	mov    0xf022a24c,%eax
f0103349:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010334c:	89 3d 4c a2 22 f0    	mov    %edi,0xf022a24c
}
f0103352:	83 c4 10             	add    $0x10,%esp
f0103355:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103358:	5b                   	pop    %ebx
f0103359:	5e                   	pop    %esi
f010335a:	5f                   	pop    %edi
f010335b:	5d                   	pop    %ebp
f010335c:	c3                   	ret    

f010335d <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f010335d:	55                   	push   %ebp
f010335e:	89 e5                	mov    %esp,%ebp
f0103360:	53                   	push   %ebx
f0103361:	83 ec 04             	sub    $0x4,%esp
f0103364:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103367:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f010336b:	75 19                	jne    f0103386 <env_destroy+0x29>
f010336d:	e8 80 1e 00 00       	call   f01051f2 <cpunum>
f0103372:	6b c0 74             	imul   $0x74,%eax,%eax
f0103375:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f010337b:	74 09                	je     f0103386 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f010337d:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103384:	eb 33                	jmp    f01033b9 <env_destroy+0x5c>
	}

	env_free(e);
f0103386:	83 ec 0c             	sub    $0xc,%esp
f0103389:	53                   	push   %ebx
f010338a:	e8 f3 fd ff ff       	call   f0103182 <env_free>

	if (curenv == e) {
f010338f:	e8 5e 1e 00 00       	call   f01051f2 <cpunum>
f0103394:	6b c0 74             	imul   $0x74,%eax,%eax
f0103397:	83 c4 10             	add    $0x10,%esp
f010339a:	3b 98 28 b0 22 f0    	cmp    -0xfdd4fd8(%eax),%ebx
f01033a0:	75 17                	jne    f01033b9 <env_destroy+0x5c>
		curenv = NULL;
f01033a2:	e8 4b 1e 00 00       	call   f01051f2 <cpunum>
f01033a7:	6b c0 74             	imul   $0x74,%eax,%eax
f01033aa:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f01033b1:	00 00 00 
		sched_yield();
f01033b4:	e8 c9 0b 00 00       	call   f0103f82 <sched_yield>
	}
}
f01033b9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01033bc:	c9                   	leave  
f01033bd:	c3                   	ret    

f01033be <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01033be:	55                   	push   %ebp
f01033bf:	89 e5                	mov    %esp,%ebp
f01033c1:	53                   	push   %ebx
f01033c2:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01033c5:	e8 28 1e 00 00       	call   f01051f2 <cpunum>
f01033ca:	6b c0 74             	imul   $0x74,%eax,%eax
f01033cd:	8b 98 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%ebx
f01033d3:	e8 1a 1e 00 00       	call   f01051f2 <cpunum>
f01033d8:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f01033db:	8b 65 08             	mov    0x8(%ebp),%esp
f01033de:	61                   	popa   
f01033df:	07                   	pop    %es
f01033e0:	1f                   	pop    %ds
f01033e1:	83 c4 08             	add    $0x8,%esp
f01033e4:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01033e5:	83 ec 04             	sub    $0x4,%esp
f01033e8:	68 29 6b 10 f0       	push   $0xf0106b29
f01033ed:	68 15 02 00 00       	push   $0x215
f01033f2:	68 a1 6a 10 f0       	push   $0xf0106aa1
f01033f7:	e8 44 cc ff ff       	call   f0100040 <_panic>

f01033fc <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01033fc:	55                   	push   %ebp
f01033fd:	89 e5                	mov    %esp,%ebp
f01033ff:	53                   	push   %ebx
f0103400:	83 ec 04             	sub    $0x4,%esp
f0103403:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv && curenv->env_status == ENV_RUNNING)
f0103406:	e8 e7 1d 00 00       	call   f01051f2 <cpunum>
f010340b:	6b c0 74             	imul   $0x74,%eax,%eax
f010340e:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103415:	74 29                	je     f0103440 <env_run+0x44>
f0103417:	e8 d6 1d 00 00       	call   f01051f2 <cpunum>
f010341c:	6b c0 74             	imul   $0x74,%eax,%eax
f010341f:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103425:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103429:	75 15                	jne    f0103440 <env_run+0x44>
		curenv->env_status = ENV_RUNNABLE;
f010342b:	e8 c2 1d 00 00       	call   f01051f2 <cpunum>
f0103430:	6b c0 74             	imul   $0x74,%eax,%eax
f0103433:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103439:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	curenv = e;
f0103440:	e8 ad 1d 00 00       	call   f01051f2 <cpunum>
f0103445:	6b c0 74             	imul   $0x74,%eax,%eax
f0103448:	89 98 28 b0 22 f0    	mov    %ebx,-0xfdd4fd8(%eax)
	curenv->env_status = ENV_RUNNING;
f010344e:	e8 9f 1d 00 00       	call   f01051f2 <cpunum>
f0103453:	6b c0 74             	imul   $0x74,%eax,%eax
f0103456:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010345c:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0103463:	e8 8a 1d 00 00       	call   f01051f2 <cpunum>
f0103468:	6b c0 74             	imul   $0x74,%eax,%eax
f010346b:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103471:	83 40 58 01          	addl   $0x1,0x58(%eax)
	cprintf("%o \n",(physaddr_t)curenv->env_pgdir);
f0103475:	e8 78 1d 00 00       	call   f01051f2 <cpunum>
f010347a:	83 ec 08             	sub    $0x8,%esp
f010347d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103480:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103486:	ff 70 60             	pushl  0x60(%eax)
f0103489:	68 35 6b 10 f0       	push   $0xf0106b35
f010348e:	e8 c0 01 00 00       	call   f0103653 <cprintf>
	lcr3(PADDR(curenv->env_pgdir));
f0103493:	e8 5a 1d 00 00       	call   f01051f2 <cpunum>
f0103498:	6b c0 74             	imul   $0x74,%eax,%eax
f010349b:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f01034a1:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034a4:	83 c4 10             	add    $0x10,%esp
f01034a7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034ac:	77 15                	ja     f01034c3 <env_run+0xc7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034ae:	50                   	push   %eax
f01034af:	68 c8 58 10 f0       	push   $0xf01058c8
f01034b4:	68 39 02 00 00       	push   $0x239
f01034b9:	68 a1 6a 10 f0       	push   $0xf0106aa1
f01034be:	e8 7d cb ff ff       	call   f0100040 <_panic>
f01034c3:	05 00 00 00 10       	add    $0x10000000,%eax
f01034c8:	0f 22 d8             	mov    %eax,%cr3

	env_pop_tf(&e->env_tf);
f01034cb:	83 ec 0c             	sub    $0xc,%esp
f01034ce:	53                   	push   %ebx
f01034cf:	e8 ea fe ff ff       	call   f01033be <env_pop_tf>

f01034d4 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01034d4:	55                   	push   %ebp
f01034d5:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01034d7:	ba 70 00 00 00       	mov    $0x70,%edx
f01034dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01034df:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01034e0:	ba 71 00 00 00       	mov    $0x71,%edx
f01034e5:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01034e6:	0f b6 c0             	movzbl %al,%eax
}
f01034e9:	5d                   	pop    %ebp
f01034ea:	c3                   	ret    

f01034eb <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01034eb:	55                   	push   %ebp
f01034ec:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01034ee:	ba 70 00 00 00       	mov    $0x70,%edx
f01034f3:	8b 45 08             	mov    0x8(%ebp),%eax
f01034f6:	ee                   	out    %al,(%dx)
f01034f7:	ba 71 00 00 00       	mov    $0x71,%edx
f01034fc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034ff:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103500:	5d                   	pop    %ebp
f0103501:	c3                   	ret    

f0103502 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103502:	55                   	push   %ebp
f0103503:	89 e5                	mov    %esp,%ebp
f0103505:	56                   	push   %esi
f0103506:	53                   	push   %ebx
f0103507:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f010350a:	66 a3 a8 f3 11 f0    	mov    %ax,0xf011f3a8
	if (!didinit)
f0103510:	80 3d 50 a2 22 f0 00 	cmpb   $0x0,0xf022a250
f0103517:	74 5a                	je     f0103573 <irq_setmask_8259A+0x71>
f0103519:	89 c6                	mov    %eax,%esi
f010351b:	ba 21 00 00 00       	mov    $0x21,%edx
f0103520:	ee                   	out    %al,(%dx)
f0103521:	66 c1 e8 08          	shr    $0x8,%ax
f0103525:	ba a1 00 00 00       	mov    $0xa1,%edx
f010352a:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
f010352b:	83 ec 0c             	sub    $0xc,%esp
f010352e:	68 3a 6b 10 f0       	push   $0xf0106b3a
f0103533:	e8 1b 01 00 00       	call   f0103653 <cprintf>
f0103538:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f010353b:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103540:	0f b7 f6             	movzwl %si,%esi
f0103543:	f7 d6                	not    %esi
f0103545:	0f a3 de             	bt     %ebx,%esi
f0103548:	73 11                	jae    f010355b <irq_setmask_8259A+0x59>
			cprintf(" %d", i);
f010354a:	83 ec 08             	sub    $0x8,%esp
f010354d:	53                   	push   %ebx
f010354e:	68 c5 6f 10 f0       	push   $0xf0106fc5
f0103553:	e8 fb 00 00 00       	call   f0103653 <cprintf>
f0103558:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f010355b:	83 c3 01             	add    $0x1,%ebx
f010355e:	83 fb 10             	cmp    $0x10,%ebx
f0103561:	75 e2                	jne    f0103545 <irq_setmask_8259A+0x43>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103563:	83 ec 0c             	sub    $0xc,%esp
f0103566:	68 09 5c 10 f0       	push   $0xf0105c09
f010356b:	e8 e3 00 00 00       	call   f0103653 <cprintf>
f0103570:	83 c4 10             	add    $0x10,%esp
}
f0103573:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103576:	5b                   	pop    %ebx
f0103577:	5e                   	pop    %esi
f0103578:	5d                   	pop    %ebp
f0103579:	c3                   	ret    

f010357a <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f010357a:	c6 05 50 a2 22 f0 01 	movb   $0x1,0xf022a250
f0103581:	ba 21 00 00 00       	mov    $0x21,%edx
f0103586:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010358b:	ee                   	out    %al,(%dx)
f010358c:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103591:	ee                   	out    %al,(%dx)
f0103592:	ba 20 00 00 00       	mov    $0x20,%edx
f0103597:	b8 11 00 00 00       	mov    $0x11,%eax
f010359c:	ee                   	out    %al,(%dx)
f010359d:	ba 21 00 00 00       	mov    $0x21,%edx
f01035a2:	b8 20 00 00 00       	mov    $0x20,%eax
f01035a7:	ee                   	out    %al,(%dx)
f01035a8:	b8 04 00 00 00       	mov    $0x4,%eax
f01035ad:	ee                   	out    %al,(%dx)
f01035ae:	b8 03 00 00 00       	mov    $0x3,%eax
f01035b3:	ee                   	out    %al,(%dx)
f01035b4:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035b9:	b8 11 00 00 00       	mov    $0x11,%eax
f01035be:	ee                   	out    %al,(%dx)
f01035bf:	ba a1 00 00 00       	mov    $0xa1,%edx
f01035c4:	b8 28 00 00 00       	mov    $0x28,%eax
f01035c9:	ee                   	out    %al,(%dx)
f01035ca:	b8 02 00 00 00       	mov    $0x2,%eax
f01035cf:	ee                   	out    %al,(%dx)
f01035d0:	b8 01 00 00 00       	mov    $0x1,%eax
f01035d5:	ee                   	out    %al,(%dx)
f01035d6:	ba 20 00 00 00       	mov    $0x20,%edx
f01035db:	b8 68 00 00 00       	mov    $0x68,%eax
f01035e0:	ee                   	out    %al,(%dx)
f01035e1:	b8 0a 00 00 00       	mov    $0xa,%eax
f01035e6:	ee                   	out    %al,(%dx)
f01035e7:	ba a0 00 00 00       	mov    $0xa0,%edx
f01035ec:	b8 68 00 00 00       	mov    $0x68,%eax
f01035f1:	ee                   	out    %al,(%dx)
f01035f2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01035f7:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01035f8:	0f b7 05 a8 f3 11 f0 	movzwl 0xf011f3a8,%eax
f01035ff:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103603:	74 13                	je     f0103618 <pic_init+0x9e>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103605:	55                   	push   %ebp
f0103606:	89 e5                	mov    %esp,%ebp
f0103608:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f010360b:	0f b7 c0             	movzwl %ax,%eax
f010360e:	50                   	push   %eax
f010360f:	e8 ee fe ff ff       	call   f0103502 <irq_setmask_8259A>
f0103614:	83 c4 10             	add    $0x10,%esp
}
f0103617:	c9                   	leave  
f0103618:	f3 c3                	repz ret 

f010361a <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010361a:	55                   	push   %ebp
f010361b:	89 e5                	mov    %esp,%ebp
f010361d:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103620:	ff 75 08             	pushl  0x8(%ebp)
f0103623:	e8 49 d1 ff ff       	call   f0100771 <cputchar>
	*cnt++;
}
f0103628:	83 c4 10             	add    $0x10,%esp
f010362b:	c9                   	leave  
f010362c:	c3                   	ret    

f010362d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010362d:	55                   	push   %ebp
f010362e:	89 e5                	mov    %esp,%ebp
f0103630:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103633:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010363a:	ff 75 0c             	pushl  0xc(%ebp)
f010363d:	ff 75 08             	pushl  0x8(%ebp)
f0103640:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103643:	50                   	push   %eax
f0103644:	68 1a 36 10 f0       	push   $0xf010361a
f0103649:	e8 15 0f 00 00       	call   f0104563 <vprintfmt>
	return cnt;
}
f010364e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103651:	c9                   	leave  
f0103652:	c3                   	ret    

f0103653 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103653:	55                   	push   %ebp
f0103654:	89 e5                	mov    %esp,%ebp
f0103656:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103659:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010365c:	50                   	push   %eax
f010365d:	ff 75 08             	pushl  0x8(%ebp)
f0103660:	e8 c8 ff ff ff       	call   f010362d <vcprintf>
	va_end(ap);

	return cnt;
}
f0103665:	c9                   	leave  
f0103666:	c3                   	ret    

f0103667 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103667:	55                   	push   %ebp
f0103668:	89 e5                	mov    %esp,%ebp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f010366a:	b8 80 aa 22 f0       	mov    $0xf022aa80,%eax
f010366f:	c7 05 84 aa 22 f0 00 	movl   $0xf0000000,0xf022aa84
f0103676:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103679:	66 c7 05 88 aa 22 f0 	movw   $0x10,0xf022aa88
f0103680:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103682:	66 c7 05 68 f3 11 f0 	movw   $0x67,0xf011f368
f0103689:	67 00 
f010368b:	66 a3 6a f3 11 f0    	mov    %ax,0xf011f36a
f0103691:	89 c2                	mov    %eax,%edx
f0103693:	c1 ea 10             	shr    $0x10,%edx
f0103696:	88 15 6c f3 11 f0    	mov    %dl,0xf011f36c
f010369c:	c6 05 6e f3 11 f0 40 	movb   $0x40,0xf011f36e
f01036a3:	c1 e8 18             	shr    $0x18,%eax
f01036a6:	a2 6f f3 11 f0       	mov    %al,0xf011f36f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f01036ab:	c6 05 6d f3 11 f0 89 	movb   $0x89,0xf011f36d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01036b2:	b8 28 00 00 00       	mov    $0x28,%eax
f01036b7:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01036ba:	b8 ac f3 11 f0       	mov    $0xf011f3ac,%eax
f01036bf:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f01036c2:	5d                   	pop    %ebp
f01036c3:	c3                   	ret    

f01036c4 <trap_init>:
}


void
trap_init(void)
{
f01036c4:	55                   	push   %ebp
f01036c5:	89 e5                	mov    %esp,%ebp
	
	void floating_point_error();

	void system_call();

	SETGATE(idt[T_DIVIDE], 1, GD_KT, divide_error, 0);
f01036c7:	b8 48 3e 10 f0       	mov    $0xf0103e48,%eax
f01036cc:	66 a3 60 a2 22 f0    	mov    %ax,0xf022a260
f01036d2:	66 c7 05 62 a2 22 f0 	movw   $0x8,0xf022a262
f01036d9:	08 00 
f01036db:	c6 05 64 a2 22 f0 00 	movb   $0x0,0xf022a264
f01036e2:	c6 05 65 a2 22 f0 8f 	movb   $0x8f,0xf022a265
f01036e9:	c1 e8 10             	shr    $0x10,%eax
f01036ec:	66 a3 66 a2 22 f0    	mov    %ax,0xf022a266
	SETGATE(idt[T_DEBUG], 1, GD_KT, debug_exception, 0);
f01036f2:	b8 4e 3e 10 f0       	mov    $0xf0103e4e,%eax
f01036f7:	66 a3 68 a2 22 f0    	mov    %ax,0xf022a268
f01036fd:	66 c7 05 6a a2 22 f0 	movw   $0x8,0xf022a26a
f0103704:	08 00 
f0103706:	c6 05 6c a2 22 f0 00 	movb   $0x0,0xf022a26c
f010370d:	c6 05 6d a2 22 f0 8f 	movb   $0x8f,0xf022a26d
f0103714:	c1 e8 10             	shr    $0x10,%eax
f0103717:	66 a3 6e a2 22 f0    	mov    %ax,0xf022a26e
	SETGATE(idt[T_NMI], 1, GD_KT, non_maskable_interrupt, 0);
f010371d:	b8 54 3e 10 f0       	mov    $0xf0103e54,%eax
f0103722:	66 a3 70 a2 22 f0    	mov    %ax,0xf022a270
f0103728:	66 c7 05 72 a2 22 f0 	movw   $0x8,0xf022a272
f010372f:	08 00 
f0103731:	c6 05 74 a2 22 f0 00 	movb   $0x0,0xf022a274
f0103738:	c6 05 75 a2 22 f0 8f 	movb   $0x8f,0xf022a275
f010373f:	c1 e8 10             	shr    $0x10,%eax
f0103742:	66 a3 76 a2 22 f0    	mov    %ax,0xf022a276
	SETGATE(idt[T_BRKPT], 1, GD_KT, break_point, 3);//!
f0103748:	b8 5a 3e 10 f0       	mov    $0xf0103e5a,%eax
f010374d:	66 a3 78 a2 22 f0    	mov    %ax,0xf022a278
f0103753:	66 c7 05 7a a2 22 f0 	movw   $0x8,0xf022a27a
f010375a:	08 00 
f010375c:	c6 05 7c a2 22 f0 00 	movb   $0x0,0xf022a27c
f0103763:	c6 05 7d a2 22 f0 ef 	movb   $0xef,0xf022a27d
f010376a:	c1 e8 10             	shr    $0x10,%eax
f010376d:	66 a3 7e a2 22 f0    	mov    %ax,0xf022a27e
	SETGATE(idt[T_OFLOW], 1, GD_KT, overflow, 0);
f0103773:	b8 60 3e 10 f0       	mov    $0xf0103e60,%eax
f0103778:	66 a3 80 a2 22 f0    	mov    %ax,0xf022a280
f010377e:	66 c7 05 82 a2 22 f0 	movw   $0x8,0xf022a282
f0103785:	08 00 
f0103787:	c6 05 84 a2 22 f0 00 	movb   $0x0,0xf022a284
f010378e:	c6 05 85 a2 22 f0 8f 	movb   $0x8f,0xf022a285
f0103795:	c1 e8 10             	shr    $0x10,%eax
f0103798:	66 a3 86 a2 22 f0    	mov    %ax,0xf022a286
	SETGATE(idt[T_BOUND], 1, GD_KT, bounds_check, 0);
f010379e:	b8 66 3e 10 f0       	mov    $0xf0103e66,%eax
f01037a3:	66 a3 88 a2 22 f0    	mov    %ax,0xf022a288
f01037a9:	66 c7 05 8a a2 22 f0 	movw   $0x8,0xf022a28a
f01037b0:	08 00 
f01037b2:	c6 05 8c a2 22 f0 00 	movb   $0x0,0xf022a28c
f01037b9:	c6 05 8d a2 22 f0 8f 	movb   $0x8f,0xf022a28d
f01037c0:	c1 e8 10             	shr    $0x10,%eax
f01037c3:	66 a3 8e a2 22 f0    	mov    %ax,0xf022a28e
	SETGATE(idt[T_ILLOP], 1, GD_KT, illegal_opcode, 0);
f01037c9:	b8 6c 3e 10 f0       	mov    $0xf0103e6c,%eax
f01037ce:	66 a3 90 a2 22 f0    	mov    %ax,0xf022a290
f01037d4:	66 c7 05 92 a2 22 f0 	movw   $0x8,0xf022a292
f01037db:	08 00 
f01037dd:	c6 05 94 a2 22 f0 00 	movb   $0x0,0xf022a294
f01037e4:	c6 05 95 a2 22 f0 8f 	movb   $0x8f,0xf022a295
f01037eb:	c1 e8 10             	shr    $0x10,%eax
f01037ee:	66 a3 96 a2 22 f0    	mov    %ax,0xf022a296
	SETGATE(idt[T_DEVICE], 1, GD_KT, device_not_available, 0);
f01037f4:	b8 72 3e 10 f0       	mov    $0xf0103e72,%eax
f01037f9:	66 a3 98 a2 22 f0    	mov    %ax,0xf022a298
f01037ff:	66 c7 05 9a a2 22 f0 	movw   $0x8,0xf022a29a
f0103806:	08 00 
f0103808:	c6 05 9c a2 22 f0 00 	movb   $0x0,0xf022a29c
f010380f:	c6 05 9d a2 22 f0 8f 	movb   $0x8f,0xf022a29d
f0103816:	c1 e8 10             	shr    $0x10,%eax
f0103819:	66 a3 9e a2 22 f0    	mov    %ax,0xf022a29e
	SETGATE(idt[T_DBLFLT], 1, GD_KT, double_fault, 0);
f010381f:	b8 78 3e 10 f0       	mov    $0xf0103e78,%eax
f0103824:	66 a3 a0 a2 22 f0    	mov    %ax,0xf022a2a0
f010382a:	66 c7 05 a2 a2 22 f0 	movw   $0x8,0xf022a2a2
f0103831:	08 00 
f0103833:	c6 05 a4 a2 22 f0 00 	movb   $0x0,0xf022a2a4
f010383a:	c6 05 a5 a2 22 f0 8f 	movb   $0x8f,0xf022a2a5
f0103841:	c1 e8 10             	shr    $0x10,%eax
f0103844:	66 a3 a6 a2 22 f0    	mov    %ax,0xf022a2a6

	SETGATE(idt[T_TSS], 1, GD_KT, invalid_task_switch_segment, 0);
f010384a:	b8 7c 3e 10 f0       	mov    $0xf0103e7c,%eax
f010384f:	66 a3 b0 a2 22 f0    	mov    %ax,0xf022a2b0
f0103855:	66 c7 05 b2 a2 22 f0 	movw   $0x8,0xf022a2b2
f010385c:	08 00 
f010385e:	c6 05 b4 a2 22 f0 00 	movb   $0x0,0xf022a2b4
f0103865:	c6 05 b5 a2 22 f0 8f 	movb   $0x8f,0xf022a2b5
f010386c:	c1 e8 10             	shr    $0x10,%eax
f010386f:	66 a3 b6 a2 22 f0    	mov    %ax,0xf022a2b6
	SETGATE(idt[T_SEGNP], 1, GD_KT, segment_not_present, 0);
f0103875:	b8 80 3e 10 f0       	mov    $0xf0103e80,%eax
f010387a:	66 a3 b8 a2 22 f0    	mov    %ax,0xf022a2b8
f0103880:	66 c7 05 ba a2 22 f0 	movw   $0x8,0xf022a2ba
f0103887:	08 00 
f0103889:	c6 05 bc a2 22 f0 00 	movb   $0x0,0xf022a2bc
f0103890:	c6 05 bd a2 22 f0 8f 	movb   $0x8f,0xf022a2bd
f0103897:	c1 e8 10             	shr    $0x10,%eax
f010389a:	66 a3 be a2 22 f0    	mov    %ax,0xf022a2be
	SETGATE(idt[T_STACK], 1, GD_KT, stack_exception, 0);
f01038a0:	b8 84 3e 10 f0       	mov    $0xf0103e84,%eax
f01038a5:	66 a3 c0 a2 22 f0    	mov    %ax,0xf022a2c0
f01038ab:	66 c7 05 c2 a2 22 f0 	movw   $0x8,0xf022a2c2
f01038b2:	08 00 
f01038b4:	c6 05 c4 a2 22 f0 00 	movb   $0x0,0xf022a2c4
f01038bb:	c6 05 c5 a2 22 f0 8f 	movb   $0x8f,0xf022a2c5
f01038c2:	c1 e8 10             	shr    $0x10,%eax
f01038c5:	66 a3 c6 a2 22 f0    	mov    %ax,0xf022a2c6
	SETGATE(idt[T_GPFLT], 1, GD_KT, general_protection_fault, 0);
f01038cb:	b8 88 3e 10 f0       	mov    $0xf0103e88,%eax
f01038d0:	66 a3 c8 a2 22 f0    	mov    %ax,0xf022a2c8
f01038d6:	66 c7 05 ca a2 22 f0 	movw   $0x8,0xf022a2ca
f01038dd:	08 00 
f01038df:	c6 05 cc a2 22 f0 00 	movb   $0x0,0xf022a2cc
f01038e6:	c6 05 cd a2 22 f0 8f 	movb   $0x8f,0xf022a2cd
f01038ed:	c1 e8 10             	shr    $0x10,%eax
f01038f0:	66 a3 ce a2 22 f0    	mov    %ax,0xf022a2ce
	SETGATE(idt[T_PGFLT], 1, GD_KT, page_fault, 0);
f01038f6:	b8 8c 3e 10 f0       	mov    $0xf0103e8c,%eax
f01038fb:	66 a3 d0 a2 22 f0    	mov    %ax,0xf022a2d0
f0103901:	66 c7 05 d2 a2 22 f0 	movw   $0x8,0xf022a2d2
f0103908:	08 00 
f010390a:	c6 05 d4 a2 22 f0 00 	movb   $0x0,0xf022a2d4
f0103911:	c6 05 d5 a2 22 f0 8f 	movb   $0x8f,0xf022a2d5
f0103918:	c1 e8 10             	shr    $0x10,%eax
f010391b:	66 a3 d6 a2 22 f0    	mov    %ax,0xf022a2d6

	SETGATE(idt[T_FPERR], 1, GD_KT, floating_point_error, 0);
f0103921:	b8 90 3e 10 f0       	mov    $0xf0103e90,%eax
f0103926:	66 a3 e0 a2 22 f0    	mov    %ax,0xf022a2e0
f010392c:	66 c7 05 e2 a2 22 f0 	movw   $0x8,0xf022a2e2
f0103933:	08 00 
f0103935:	c6 05 e4 a2 22 f0 00 	movb   $0x0,0xf022a2e4
f010393c:	c6 05 e5 a2 22 f0 8f 	movb   $0x8f,0xf022a2e5
f0103943:	c1 e8 10             	shr    $0x10,%eax
f0103946:	66 a3 e6 a2 22 f0    	mov    %ax,0xf022a2e6

	SETGATE(idt[T_SYSCALL], 0, GD_KT, system_call, 3);
f010394c:	b8 96 3e 10 f0       	mov    $0xf0103e96,%eax
f0103951:	66 a3 e0 a3 22 f0    	mov    %ax,0xf022a3e0
f0103957:	66 c7 05 e2 a3 22 f0 	movw   $0x8,0xf022a3e2
f010395e:	08 00 
f0103960:	c6 05 e4 a3 22 f0 00 	movb   $0x0,0xf022a3e4
f0103967:	c6 05 e5 a3 22 f0 ee 	movb   $0xee,0xf022a3e5
f010396e:	c1 e8 10             	shr    $0x10,%eax
f0103971:	66 a3 e6 a3 22 f0    	mov    %ax,0xf022a3e6

	// Per-CPU setup 
	trap_init_percpu();
f0103977:	e8 eb fc ff ff       	call   f0103667 <trap_init_percpu>
}
f010397c:	5d                   	pop    %ebp
f010397d:	c3                   	ret    

f010397e <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f010397e:	55                   	push   %ebp
f010397f:	89 e5                	mov    %esp,%ebp
f0103981:	53                   	push   %ebx
f0103982:	83 ec 0c             	sub    $0xc,%esp
f0103985:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103988:	ff 33                	pushl  (%ebx)
f010398a:	68 4e 6b 10 f0       	push   $0xf0106b4e
f010398f:	e8 bf fc ff ff       	call   f0103653 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103994:	83 c4 08             	add    $0x8,%esp
f0103997:	ff 73 04             	pushl  0x4(%ebx)
f010399a:	68 5d 6b 10 f0       	push   $0xf0106b5d
f010399f:	e8 af fc ff ff       	call   f0103653 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01039a4:	83 c4 08             	add    $0x8,%esp
f01039a7:	ff 73 08             	pushl  0x8(%ebx)
f01039aa:	68 6c 6b 10 f0       	push   $0xf0106b6c
f01039af:	e8 9f fc ff ff       	call   f0103653 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01039b4:	83 c4 08             	add    $0x8,%esp
f01039b7:	ff 73 0c             	pushl  0xc(%ebx)
f01039ba:	68 7b 6b 10 f0       	push   $0xf0106b7b
f01039bf:	e8 8f fc ff ff       	call   f0103653 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01039c4:	83 c4 08             	add    $0x8,%esp
f01039c7:	ff 73 10             	pushl  0x10(%ebx)
f01039ca:	68 8a 6b 10 f0       	push   $0xf0106b8a
f01039cf:	e8 7f fc ff ff       	call   f0103653 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01039d4:	83 c4 08             	add    $0x8,%esp
f01039d7:	ff 73 14             	pushl  0x14(%ebx)
f01039da:	68 99 6b 10 f0       	push   $0xf0106b99
f01039df:	e8 6f fc ff ff       	call   f0103653 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01039e4:	83 c4 08             	add    $0x8,%esp
f01039e7:	ff 73 18             	pushl  0x18(%ebx)
f01039ea:	68 a8 6b 10 f0       	push   $0xf0106ba8
f01039ef:	e8 5f fc ff ff       	call   f0103653 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01039f4:	83 c4 08             	add    $0x8,%esp
f01039f7:	ff 73 1c             	pushl  0x1c(%ebx)
f01039fa:	68 b7 6b 10 f0       	push   $0xf0106bb7
f01039ff:	e8 4f fc ff ff       	call   f0103653 <cprintf>
}
f0103a04:	83 c4 10             	add    $0x10,%esp
f0103a07:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a0a:	c9                   	leave  
f0103a0b:	c3                   	ret    

f0103a0c <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103a0c:	55                   	push   %ebp
f0103a0d:	89 e5                	mov    %esp,%ebp
f0103a0f:	56                   	push   %esi
f0103a10:	53                   	push   %ebx
f0103a11:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103a14:	e8 d9 17 00 00       	call   f01051f2 <cpunum>
f0103a19:	83 ec 04             	sub    $0x4,%esp
f0103a1c:	50                   	push   %eax
f0103a1d:	53                   	push   %ebx
f0103a1e:	68 1b 6c 10 f0       	push   $0xf0106c1b
f0103a23:	e8 2b fc ff ff       	call   f0103653 <cprintf>
	print_regs(&tf->tf_regs);
f0103a28:	89 1c 24             	mov    %ebx,(%esp)
f0103a2b:	e8 4e ff ff ff       	call   f010397e <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103a30:	83 c4 08             	add    $0x8,%esp
f0103a33:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103a37:	50                   	push   %eax
f0103a38:	68 39 6c 10 f0       	push   $0xf0106c39
f0103a3d:	e8 11 fc ff ff       	call   f0103653 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103a42:	83 c4 08             	add    $0x8,%esp
f0103a45:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103a49:	50                   	push   %eax
f0103a4a:	68 4c 6c 10 f0       	push   $0xf0106c4c
f0103a4f:	e8 ff fb ff ff       	call   f0103653 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103a54:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103a57:	83 c4 10             	add    $0x10,%esp
f0103a5a:	83 f8 13             	cmp    $0x13,%eax
f0103a5d:	77 09                	ja     f0103a68 <print_trapframe+0x5c>
		return excnames[trapno];
f0103a5f:	8b 14 85 e0 6e 10 f0 	mov    -0xfef9120(,%eax,4),%edx
f0103a66:	eb 1f                	jmp    f0103a87 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103a68:	83 f8 30             	cmp    $0x30,%eax
f0103a6b:	74 15                	je     f0103a82 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103a6d:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103a70:	83 fa 10             	cmp    $0x10,%edx
f0103a73:	b9 e5 6b 10 f0       	mov    $0xf0106be5,%ecx
f0103a78:	ba d2 6b 10 f0       	mov    $0xf0106bd2,%edx
f0103a7d:	0f 43 d1             	cmovae %ecx,%edx
f0103a80:	eb 05                	jmp    f0103a87 <print_trapframe+0x7b>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103a82:	ba c6 6b 10 f0       	mov    $0xf0106bc6,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103a87:	83 ec 04             	sub    $0x4,%esp
f0103a8a:	52                   	push   %edx
f0103a8b:	50                   	push   %eax
f0103a8c:	68 5f 6c 10 f0       	push   $0xf0106c5f
f0103a91:	e8 bd fb ff ff       	call   f0103653 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103a96:	83 c4 10             	add    $0x10,%esp
f0103a99:	3b 1d 60 aa 22 f0    	cmp    0xf022aa60,%ebx
f0103a9f:	75 1a                	jne    f0103abb <print_trapframe+0xaf>
f0103aa1:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103aa5:	75 14                	jne    f0103abb <print_trapframe+0xaf>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103aa7:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103aaa:	83 ec 08             	sub    $0x8,%esp
f0103aad:	50                   	push   %eax
f0103aae:	68 71 6c 10 f0       	push   $0xf0106c71
f0103ab3:	e8 9b fb ff ff       	call   f0103653 <cprintf>
f0103ab8:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103abb:	83 ec 08             	sub    $0x8,%esp
f0103abe:	ff 73 2c             	pushl  0x2c(%ebx)
f0103ac1:	68 80 6c 10 f0       	push   $0xf0106c80
f0103ac6:	e8 88 fb ff ff       	call   f0103653 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103acb:	83 c4 10             	add    $0x10,%esp
f0103ace:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103ad2:	75 49                	jne    f0103b1d <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103ad4:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103ad7:	89 c2                	mov    %eax,%edx
f0103ad9:	83 e2 01             	and    $0x1,%edx
f0103adc:	ba ff 6b 10 f0       	mov    $0xf0106bff,%edx
f0103ae1:	b9 f4 6b 10 f0       	mov    $0xf0106bf4,%ecx
f0103ae6:	0f 44 ca             	cmove  %edx,%ecx
f0103ae9:	89 c2                	mov    %eax,%edx
f0103aeb:	83 e2 02             	and    $0x2,%edx
f0103aee:	ba 11 6c 10 f0       	mov    $0xf0106c11,%edx
f0103af3:	be 0b 6c 10 f0       	mov    $0xf0106c0b,%esi
f0103af8:	0f 45 d6             	cmovne %esi,%edx
f0103afb:	83 e0 04             	and    $0x4,%eax
f0103afe:	be 2e 6d 10 f0       	mov    $0xf0106d2e,%esi
f0103b03:	b8 16 6c 10 f0       	mov    $0xf0106c16,%eax
f0103b08:	0f 44 c6             	cmove  %esi,%eax
f0103b0b:	51                   	push   %ecx
f0103b0c:	52                   	push   %edx
f0103b0d:	50                   	push   %eax
f0103b0e:	68 8e 6c 10 f0       	push   $0xf0106c8e
f0103b13:	e8 3b fb ff ff       	call   f0103653 <cprintf>
f0103b18:	83 c4 10             	add    $0x10,%esp
f0103b1b:	eb 10                	jmp    f0103b2d <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103b1d:	83 ec 0c             	sub    $0xc,%esp
f0103b20:	68 09 5c 10 f0       	push   $0xf0105c09
f0103b25:	e8 29 fb ff ff       	call   f0103653 <cprintf>
f0103b2a:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103b2d:	83 ec 08             	sub    $0x8,%esp
f0103b30:	ff 73 30             	pushl  0x30(%ebx)
f0103b33:	68 9d 6c 10 f0       	push   $0xf0106c9d
f0103b38:	e8 16 fb ff ff       	call   f0103653 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103b3d:	83 c4 08             	add    $0x8,%esp
f0103b40:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103b44:	50                   	push   %eax
f0103b45:	68 ac 6c 10 f0       	push   $0xf0106cac
f0103b4a:	e8 04 fb ff ff       	call   f0103653 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103b4f:	83 c4 08             	add    $0x8,%esp
f0103b52:	ff 73 38             	pushl  0x38(%ebx)
f0103b55:	68 bf 6c 10 f0       	push   $0xf0106cbf
f0103b5a:	e8 f4 fa ff ff       	call   f0103653 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103b5f:	83 c4 10             	add    $0x10,%esp
f0103b62:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103b66:	74 25                	je     f0103b8d <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103b68:	83 ec 08             	sub    $0x8,%esp
f0103b6b:	ff 73 3c             	pushl  0x3c(%ebx)
f0103b6e:	68 ce 6c 10 f0       	push   $0xf0106cce
f0103b73:	e8 db fa ff ff       	call   f0103653 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103b78:	83 c4 08             	add    $0x8,%esp
f0103b7b:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103b7f:	50                   	push   %eax
f0103b80:	68 dd 6c 10 f0       	push   $0xf0106cdd
f0103b85:	e8 c9 fa ff ff       	call   f0103653 <cprintf>
f0103b8a:	83 c4 10             	add    $0x10,%esp
	}
}
f0103b8d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103b90:	5b                   	pop    %ebx
f0103b91:	5e                   	pop    %esi
f0103b92:	5d                   	pop    %ebp
f0103b93:	c3                   	ret    

f0103b94 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103b94:	55                   	push   %ebp
f0103b95:	89 e5                	mov    %esp,%ebp
f0103b97:	57                   	push   %edi
f0103b98:	56                   	push   %esi
f0103b99:	53                   	push   %ebx
f0103b9a:	83 ec 0c             	sub    $0xc,%esp
f0103b9d:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103ba0:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs & 3) == 0) //缺页中断发生在内核中
f0103ba3:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103ba7:	75 17                	jne    f0103bc0 <page_fault_handler+0x2c>
    	panic("page fault happen in kernel mode!\n");
f0103ba9:	83 ec 04             	sub    $0x4,%esp
f0103bac:	68 98 6e 10 f0       	push   $0xf0106e98
f0103bb1:	68 51 01 00 00       	push   $0x151
f0103bb6:	68 f0 6c 10 f0       	push   $0xf0106cf0
f0103bbb:	e8 80 c4 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103bc0:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0103bc3:	e8 2a 16 00 00       	call   f01051f2 <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103bc8:	57                   	push   %edi
f0103bc9:	56                   	push   %esi
		curenv->env_id, fault_va, tf->tf_eip);
f0103bca:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103bcd:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103bd3:	ff 70 48             	pushl  0x48(%eax)
f0103bd6:	68 bc 6e 10 f0       	push   $0xf0106ebc
f0103bdb:	e8 73 fa ff ff       	call   f0103653 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103be0:	89 1c 24             	mov    %ebx,(%esp)
f0103be3:	e8 24 fe ff ff       	call   f0103a0c <print_trapframe>
	env_destroy(curenv);
f0103be8:	e8 05 16 00 00       	call   f01051f2 <cpunum>
f0103bed:	83 c4 04             	add    $0x4,%esp
f0103bf0:	6b c0 74             	imul   $0x74,%eax,%eax
f0103bf3:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103bf9:	e8 5f f7 ff ff       	call   f010335d <env_destroy>
}
f0103bfe:	83 c4 10             	add    $0x10,%esp
f0103c01:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103c04:	5b                   	pop    %ebx
f0103c05:	5e                   	pop    %esi
f0103c06:	5f                   	pop    %edi
f0103c07:	5d                   	pop    %ebp
f0103c08:	c3                   	ret    

f0103c09 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103c09:	55                   	push   %ebp
f0103c0a:	89 e5                	mov    %esp,%ebp
f0103c0c:	57                   	push   %edi
f0103c0d:	56                   	push   %esi
f0103c0e:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103c11:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103c12:	83 3d 00 af 22 f0 00 	cmpl   $0x0,0xf022af00
f0103c19:	74 01                	je     f0103c1c <trap+0x13>
		asm volatile("hlt");
f0103c1b:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103c1c:	e8 d1 15 00 00       	call   f01051f2 <cpunum>
f0103c21:	6b d0 74             	imul   $0x74,%eax,%edx
f0103c24:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103c2a:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c2f:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103c33:	83 f8 02             	cmp    $0x2,%eax
f0103c36:	75 10                	jne    f0103c48 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103c38:	83 ec 0c             	sub    $0xc,%esp
f0103c3b:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103c40:	e8 1b 18 00 00       	call   f0105460 <spin_lock>
f0103c45:	83 c4 10             	add    $0x10,%esp

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103c48:	9c                   	pushf  
f0103c49:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103c4a:	f6 c4 02             	test   $0x2,%ah
f0103c4d:	74 19                	je     f0103c68 <trap+0x5f>
f0103c4f:	68 fc 6c 10 f0       	push   $0xf0106cfc
f0103c54:	68 67 67 10 f0       	push   $0xf0106767
f0103c59:	68 1c 01 00 00       	push   $0x11c
f0103c5e:	68 f0 6c 10 f0       	push   $0xf0106cf0
f0103c63:	e8 d8 c3 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103c68:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103c6c:	83 e0 03             	and    $0x3,%eax
f0103c6f:	66 83 f8 03          	cmp    $0x3,%ax
f0103c73:	0f 85 90 00 00 00    	jne    f0103d09 <trap+0x100>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		assert(curenv);
f0103c79:	e8 74 15 00 00       	call   f01051f2 <cpunum>
f0103c7e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c81:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103c88:	75 19                	jne    f0103ca3 <trap+0x9a>
f0103c8a:	68 15 6d 10 f0       	push   $0xf0106d15
f0103c8f:	68 67 67 10 f0       	push   $0xf0106767
f0103c94:	68 23 01 00 00       	push   $0x123
f0103c99:	68 f0 6c 10 f0       	push   $0xf0106cf0
f0103c9e:	e8 9d c3 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103ca3:	e8 4a 15 00 00       	call   f01051f2 <cpunum>
f0103ca8:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cab:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103cb1:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103cb5:	75 2d                	jne    f0103ce4 <trap+0xdb>
			env_free(curenv);
f0103cb7:	e8 36 15 00 00       	call   f01051f2 <cpunum>
f0103cbc:	83 ec 0c             	sub    $0xc,%esp
f0103cbf:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cc2:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103cc8:	e8 b5 f4 ff ff       	call   f0103182 <env_free>
			curenv = NULL;
f0103ccd:	e8 20 15 00 00       	call   f01051f2 <cpunum>
f0103cd2:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cd5:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103cdc:	00 00 00 
			sched_yield();
f0103cdf:	e8 9e 02 00 00       	call   f0103f82 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103ce4:	e8 09 15 00 00       	call   f01051f2 <cpunum>
f0103ce9:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cec:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103cf2:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103cf7:	89 c7                	mov    %eax,%edi
f0103cf9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103cfb:	e8 f2 14 00 00       	call   f01051f2 <cpunum>
f0103d00:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d03:	8b b0 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103d09:	89 35 60 aa 22 f0    	mov    %esi,0xf022aa60
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch (tf->tf_trapno)
f0103d0f:	8b 46 28             	mov    0x28(%esi),%eax
f0103d12:	83 f8 0e             	cmp    $0xe,%eax
f0103d15:	74 0c                	je     f0103d23 <trap+0x11a>
f0103d17:	83 f8 30             	cmp    $0x30,%eax
f0103d1a:	74 23                	je     f0103d3f <trap+0x136>
f0103d1c:	83 f8 03             	cmp    $0x3,%eax
f0103d1f:	75 3e                	jne    f0103d5f <trap+0x156>
f0103d21:	eb 0e                	jmp    f0103d31 <trap+0x128>
	{
	case T_PGFLT:
		page_fault_handler(tf);
f0103d23:	83 ec 0c             	sub    $0xc,%esp
f0103d26:	56                   	push   %esi
f0103d27:	e8 68 fe ff ff       	call   f0103b94 <page_fault_handler>
f0103d2c:	83 c4 10             	add    $0x10,%esp
f0103d2f:	eb 73                	jmp    f0103da4 <trap+0x19b>
		break;
	case T_BRKPT:
		monitor(tf);
f0103d31:	83 ec 0c             	sub    $0xc,%esp
f0103d34:	56                   	push   %esi
f0103d35:	e8 e2 cb ff ff       	call   f010091c <monitor>
f0103d3a:	83 c4 10             	add    $0x10,%esp
f0103d3d:	eb 65                	jmp    f0103da4 <trap+0x19b>
		break;
	case T_SYSCALL:
		tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, 
f0103d3f:	8b 46 18             	mov    0x18(%esi),%eax
f0103d42:	83 ec 08             	sub    $0x8,%esp
f0103d45:	ff 76 04             	pushl  0x4(%esi)
f0103d48:	ff 36                	pushl  (%esi)
f0103d4a:	50                   	push   %eax
f0103d4b:	50                   	push   %eax
f0103d4c:	ff 76 14             	pushl  0x14(%esi)
f0103d4f:	ff 76 1c             	pushl  0x1c(%esi)
f0103d52:	e8 38 02 00 00       	call   f0103f8f <syscall>
f0103d57:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103d5a:	83 c4 20             	add    $0x20,%esp
f0103d5d:	eb 45                	jmp    f0103da4 <trap+0x19b>
		tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx, tf->tf_regs.reg_ecx, 
		tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
		break;
	default:
		// Unexpected trap: The user process or the kernel has a bug.
		print_trapframe(tf);
f0103d5f:	83 ec 0c             	sub    $0xc,%esp
f0103d62:	56                   	push   %esi
f0103d63:	e8 a4 fc ff ff       	call   f0103a0c <print_trapframe>
		if (tf->tf_cs == GD_KT)
f0103d68:	83 c4 10             	add    $0x10,%esp
f0103d6b:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103d70:	75 17                	jne    f0103d89 <trap+0x180>
			panic("unhandled trap in kernel");
f0103d72:	83 ec 04             	sub    $0x4,%esp
f0103d75:	68 1c 6d 10 f0       	push   $0xf0106d1c
f0103d7a:	68 ea 00 00 00       	push   $0xea
f0103d7f:	68 f0 6c 10 f0       	push   $0xf0106cf0
f0103d84:	e8 b7 c2 ff ff       	call   f0100040 <_panic>
		else
		{
			env_destroy(curenv);
f0103d89:	e8 64 14 00 00       	call   f01051f2 <cpunum>
f0103d8e:	83 ec 0c             	sub    $0xc,%esp
f0103d91:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d94:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103d9a:	e8 be f5 ff ff       	call   f010335d <env_destroy>
f0103d9f:	83 c4 10             	add    $0x10,%esp
f0103da2:	eb 63                	jmp    f0103e07 <trap+0x1fe>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103da4:	83 7e 28 27          	cmpl   $0x27,0x28(%esi)
f0103da8:	75 1a                	jne    f0103dc4 <trap+0x1bb>
		cprintf("Spurious interrupt on irq 7\n");
f0103daa:	83 ec 0c             	sub    $0xc,%esp
f0103dad:	68 35 6d 10 f0       	push   $0xf0106d35
f0103db2:	e8 9c f8 ff ff       	call   f0103653 <cprintf>
		print_trapframe(tf);
f0103db7:	89 34 24             	mov    %esi,(%esp)
f0103dba:	e8 4d fc ff ff       	call   f0103a0c <print_trapframe>
f0103dbf:	83 c4 10             	add    $0x10,%esp
f0103dc2:	eb 43                	jmp    f0103e07 <trap+0x1fe>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103dc4:	83 ec 0c             	sub    $0xc,%esp
f0103dc7:	56                   	push   %esi
f0103dc8:	e8 3f fc ff ff       	call   f0103a0c <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103dcd:	83 c4 10             	add    $0x10,%esp
f0103dd0:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103dd5:	75 17                	jne    f0103dee <trap+0x1e5>
		panic("unhandled trap in kernel");
f0103dd7:	83 ec 04             	sub    $0x4,%esp
f0103dda:	68 1c 6d 10 f0       	push   $0xf0106d1c
f0103ddf:	68 02 01 00 00       	push   $0x102
f0103de4:	68 f0 6c 10 f0       	push   $0xf0106cf0
f0103de9:	e8 52 c2 ff ff       	call   f0100040 <_panic>
	else {
		env_destroy(curenv);
f0103dee:	e8 ff 13 00 00       	call   f01051f2 <cpunum>
f0103df3:	83 ec 0c             	sub    $0xc,%esp
f0103df6:	6b c0 74             	imul   $0x74,%eax,%eax
f0103df9:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103dff:	e8 59 f5 ff ff       	call   f010335d <env_destroy>
f0103e04:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103e07:	e8 e6 13 00 00       	call   f01051f2 <cpunum>
f0103e0c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e0f:	83 b8 28 b0 22 f0 00 	cmpl   $0x0,-0xfdd4fd8(%eax)
f0103e16:	74 2a                	je     f0103e42 <trap+0x239>
f0103e18:	e8 d5 13 00 00       	call   f01051f2 <cpunum>
f0103e1d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e20:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0103e26:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103e2a:	75 16                	jne    f0103e42 <trap+0x239>
		env_run(curenv);
f0103e2c:	e8 c1 13 00 00       	call   f01051f2 <cpunum>
f0103e31:	83 ec 0c             	sub    $0xc,%esp
f0103e34:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e37:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103e3d:	e8 ba f5 ff ff       	call   f01033fc <env_run>
	else
		sched_yield();
f0103e42:	e8 3b 01 00 00       	call   f0103f82 <sched_yield>
f0103e47:	90                   	nop

f0103e48 <divide_error>:
 * Lab 3: Your code here for generating entry points for the different traps.
 */



	TRAPHANDLER_NOEC(divide_error, T_DIVIDE) 
f0103e48:	6a 00                	push   $0x0
f0103e4a:	6a 00                	push   $0x0
f0103e4c:	eb 4e                	jmp    f0103e9c <_alltraps>

f0103e4e <debug_exception>:
	TRAPHANDLER_NOEC(debug_exception, T_DEBUG) 
f0103e4e:	6a 00                	push   $0x0
f0103e50:	6a 01                	push   $0x1
f0103e52:	eb 48                	jmp    f0103e9c <_alltraps>

f0103e54 <non_maskable_interrupt>:
	TRAPHANDLER_NOEC(non_maskable_interrupt, T_NMI) 
f0103e54:	6a 00                	push   $0x0
f0103e56:	6a 02                	push   $0x2
f0103e58:	eb 42                	jmp    f0103e9c <_alltraps>

f0103e5a <break_point>:
	TRAPHANDLER_NOEC(break_point, T_BRKPT)// inc/x86.中有breakpoint同名函数
f0103e5a:	6a 00                	push   $0x0
f0103e5c:	6a 03                	push   $0x3
f0103e5e:	eb 3c                	jmp    f0103e9c <_alltraps>

f0103e60 <overflow>:
	TRAPHANDLER_NOEC(overflow, T_OFLOW) 
f0103e60:	6a 00                	push   $0x0
f0103e62:	6a 04                	push   $0x4
f0103e64:	eb 36                	jmp    f0103e9c <_alltraps>

f0103e66 <bounds_check>:
	TRAPHANDLER_NOEC(bounds_check, T_BOUND) 
f0103e66:	6a 00                	push   $0x0
f0103e68:	6a 05                	push   $0x5
f0103e6a:	eb 30                	jmp    f0103e9c <_alltraps>

f0103e6c <illegal_opcode>:
	TRAPHANDLER_NOEC(illegal_opcode, T_ILLOP) 
f0103e6c:	6a 00                	push   $0x0
f0103e6e:	6a 06                	push   $0x6
f0103e70:	eb 2a                	jmp    f0103e9c <_alltraps>

f0103e72 <device_not_available>:
	TRAPHANDLER_NOEC(device_not_available, T_DEVICE) 
f0103e72:	6a 00                	push   $0x0
f0103e74:	6a 07                	push   $0x7
f0103e76:	eb 24                	jmp    f0103e9c <_alltraps>

f0103e78 <double_fault>:
	TRAPHANDLER(double_fault, T_DBLFLT) 
f0103e78:	6a 08                	push   $0x8
f0103e7a:	eb 20                	jmp    f0103e9c <_alltraps>

f0103e7c <invalid_task_switch_segment>:

	TRAPHANDLER(invalid_task_switch_segment, T_TSS) 
f0103e7c:	6a 0a                	push   $0xa
f0103e7e:	eb 1c                	jmp    f0103e9c <_alltraps>

f0103e80 <segment_not_present>:
	TRAPHANDLER(segment_not_present, T_SEGNP) 
f0103e80:	6a 0b                	push   $0xb
f0103e82:	eb 18                	jmp    f0103e9c <_alltraps>

f0103e84 <stack_exception>:
	TRAPHANDLER(stack_exception, T_STACK) 
f0103e84:	6a 0c                	push   $0xc
f0103e86:	eb 14                	jmp    f0103e9c <_alltraps>

f0103e88 <general_protection_fault>:
	TRAPHANDLER(general_protection_fault, T_GPFLT) 
f0103e88:	6a 0d                	push   $0xd
f0103e8a:	eb 10                	jmp    f0103e9c <_alltraps>

f0103e8c <page_fault>:
	TRAPHANDLER(page_fault, T_PGFLT) 
f0103e8c:	6a 0e                	push   $0xe
f0103e8e:	eb 0c                	jmp    f0103e9c <_alltraps>

f0103e90 <floating_point_error>:

	TRAPHANDLER_NOEC(floating_point_error, T_FPERR) 
f0103e90:	6a 00                	push   $0x0
f0103e92:	6a 10                	push   $0x10
f0103e94:	eb 06                	jmp    f0103e9c <_alltraps>

f0103e96 <system_call>:
	//x86手册9.10中没有说明aligment check && machine check
	//&& SIMD floating point error是否返回error code，故没写上
	TRAPHANDLER_NOEC(system_call, T_SYSCALL)
f0103e96:	6a 00                	push   $0x0
f0103e98:	6a 30                	push   $0x30
f0103e9a:	eb 00                	jmp    f0103e9c <_alltraps>

f0103e9c <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
f0103e9c:	1e                   	push   %ds
	pushl %es
f0103e9d:	06                   	push   %es
	pushal
f0103e9e:	60                   	pusha  

	mov $GD_KD,%eax
f0103e9f:	b8 10 00 00 00       	mov    $0x10,%eax
	mov %eax,%ds
f0103ea4:	8e d8                	mov    %eax,%ds
	mov %eax,%es
f0103ea6:	8e c0                	mov    %eax,%es
	
	pushl %esp  //压入trap()的参数tf，%esp指向Trapframe结构的起始地址
f0103ea8:	54                   	push   %esp
	call trap
f0103ea9:	e8 5b fd ff ff       	call   f0103c09 <trap>

f0103eae <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0103eae:	55                   	push   %ebp
f0103eaf:	89 e5                	mov    %esp,%ebp
f0103eb1:	83 ec 08             	sub    $0x8,%esp
f0103eb4:	a1 48 a2 22 f0       	mov    0xf022a248,%eax
f0103eb9:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103ebc:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0103ec1:	8b 02                	mov    (%edx),%eax
f0103ec3:	83 e8 01             	sub    $0x1,%eax
f0103ec6:	83 f8 02             	cmp    $0x2,%eax
f0103ec9:	76 10                	jbe    f0103edb <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103ecb:	83 c1 01             	add    $0x1,%ecx
f0103ece:	83 c2 7c             	add    $0x7c,%edx
f0103ed1:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103ed7:	75 e8                	jne    f0103ec1 <sched_halt+0x13>
f0103ed9:	eb 08                	jmp    f0103ee3 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0103edb:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103ee1:	75 1f                	jne    f0103f02 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0103ee3:	83 ec 0c             	sub    $0xc,%esp
f0103ee6:	68 30 6f 10 f0       	push   $0xf0106f30
f0103eeb:	e8 63 f7 ff ff       	call   f0103653 <cprintf>
f0103ef0:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0103ef3:	83 ec 0c             	sub    $0xc,%esp
f0103ef6:	6a 00                	push   $0x0
f0103ef8:	e8 1f ca ff ff       	call   f010091c <monitor>
f0103efd:	83 c4 10             	add    $0x10,%esp
f0103f00:	eb f1                	jmp    f0103ef3 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0103f02:	e8 eb 12 00 00       	call   f01051f2 <cpunum>
f0103f07:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f0a:	c7 80 28 b0 22 f0 00 	movl   $0x0,-0xfdd4fd8(%eax)
f0103f11:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0103f14:	a1 0c af 22 f0       	mov    0xf022af0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103f19:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103f1e:	77 12                	ja     f0103f32 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103f20:	50                   	push   %eax
f0103f21:	68 c8 58 10 f0       	push   $0xf01058c8
f0103f26:	6a 3d                	push   $0x3d
f0103f28:	68 59 6f 10 f0       	push   $0xf0106f59
f0103f2d:	e8 0e c1 ff ff       	call   f0100040 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103f32:	05 00 00 00 10       	add    $0x10000000,%eax
f0103f37:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0103f3a:	e8 b3 12 00 00       	call   f01051f2 <cpunum>
f0103f3f:	6b d0 74             	imul   $0x74,%eax,%edx
f0103f42:	81 c2 20 b0 22 f0    	add    $0xf022b020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103f48:	b8 02 00 00 00       	mov    $0x2,%eax
f0103f4d:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103f51:	83 ec 0c             	sub    $0xc,%esp
f0103f54:	68 c0 f3 11 f0       	push   $0xf011f3c0
f0103f59:	e8 9f 15 00 00       	call   f01054fd <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103f5e:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0103f60:	e8 8d 12 00 00       	call   f01051f2 <cpunum>
f0103f65:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f0103f68:	8b 80 30 b0 22 f0    	mov    -0xfdd4fd0(%eax),%eax
f0103f6e:	bd 00 00 00 00       	mov    $0x0,%ebp
f0103f73:	89 c4                	mov    %eax,%esp
f0103f75:	6a 00                	push   $0x0
f0103f77:	6a 00                	push   $0x0
f0103f79:	fb                   	sti    
f0103f7a:	f4                   	hlt    
f0103f7b:	eb fd                	jmp    f0103f7a <sched_halt+0xcc>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0103f7d:	83 c4 10             	add    $0x10,%esp
f0103f80:	c9                   	leave  
f0103f81:	c3                   	ret    

f0103f82 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0103f82:	55                   	push   %ebp
f0103f83:	89 e5                	mov    %esp,%ebp
f0103f85:	83 ec 08             	sub    $0x8,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.

	// sched_halt never returns
	sched_halt();
f0103f88:	e8 21 ff ff ff       	call   f0103eae <sched_halt>
}
f0103f8d:	c9                   	leave  
f0103f8e:	c3                   	ret    

f0103f8f <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103f8f:	55                   	push   %ebp
f0103f90:	89 e5                	mov    %esp,%ebp
f0103f92:	53                   	push   %ebx
f0103f93:	83 ec 14             	sub    $0x14,%esp
f0103f96:	8b 45 08             	mov    0x8(%ebp),%eax
	// LAB 3: Your code here.

	//panic("syscall not implemented");
	int ret;

	switch (syscallno) {
f0103f99:	83 f8 01             	cmp    $0x1,%eax
f0103f9c:	74 53                	je     f0103ff1 <syscall+0x62>
f0103f9e:	83 f8 01             	cmp    $0x1,%eax
f0103fa1:	72 13                	jb     f0103fb6 <syscall+0x27>
f0103fa3:	83 f8 02             	cmp    $0x2,%eax
f0103fa6:	0f 84 db 00 00 00    	je     f0104087 <syscall+0xf8>
f0103fac:	83 f8 03             	cmp    $0x3,%eax
f0103faf:	74 4a                	je     f0103ffb <syscall+0x6c>
f0103fb1:	e9 e4 00 00 00       	jmp    f010409a <syscall+0x10b>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_U);
f0103fb6:	e8 37 12 00 00       	call   f01051f2 <cpunum>
f0103fbb:	6a 04                	push   $0x4
f0103fbd:	ff 75 10             	pushl  0x10(%ebp)
f0103fc0:	ff 75 0c             	pushl  0xc(%ebp)
f0103fc3:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fc6:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0103fcc:	e8 e8 ec ff ff       	call   f0102cb9 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103fd1:	83 c4 0c             	add    $0xc,%esp
f0103fd4:	ff 75 0c             	pushl  0xc(%ebp)
f0103fd7:	ff 75 10             	pushl  0x10(%ebp)
f0103fda:	68 66 6f 10 f0       	push   $0xf0106f66
f0103fdf:	e8 6f f6 ff ff       	call   f0103653 <cprintf>
f0103fe4:	83 c4 10             	add    $0x10,%esp
	int ret;

	switch (syscallno) {
	case SYS_cputs:
		sys_cputs((const char*)a1,(size_t)a2);
		ret = 0;//其他函数都return 0
f0103fe7:	b8 00 00 00 00       	mov    $0x0,%eax
f0103fec:	e9 ae 00 00 00       	jmp    f010409f <syscall+0x110>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0103ff1:	e8 0c c6 ff ff       	call   f0100602 <cons_getc>
		sys_cputs((const char*)a1,(size_t)a2);
		ret = 0;//其他函数都return 0
		break;
	case SYS_cgetc:
		ret = sys_cgetc();
		break;
f0103ff6:	e9 a4 00 00 00       	jmp    f010409f <syscall+0x110>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103ffb:	83 ec 04             	sub    $0x4,%esp
f0103ffe:	6a 01                	push   $0x1
f0104000:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104003:	50                   	push   %eax
f0104004:	ff 75 0c             	pushl  0xc(%ebp)
f0104007:	e8 97 ed ff ff       	call   f0102da3 <envid2env>
f010400c:	83 c4 10             	add    $0x10,%esp
f010400f:	85 c0                	test   %eax,%eax
f0104011:	0f 88 88 00 00 00    	js     f010409f <syscall+0x110>
		return r;
	if (e == curenv)
f0104017:	e8 d6 11 00 00       	call   f01051f2 <cpunum>
f010401c:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010401f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104022:	39 90 28 b0 22 f0    	cmp    %edx,-0xfdd4fd8(%eax)
f0104028:	75 23                	jne    f010404d <syscall+0xbe>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f010402a:	e8 c3 11 00 00       	call   f01051f2 <cpunum>
f010402f:	83 ec 08             	sub    $0x8,%esp
f0104032:	6b c0 74             	imul   $0x74,%eax,%eax
f0104035:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f010403b:	ff 70 48             	pushl  0x48(%eax)
f010403e:	68 6b 6f 10 f0       	push   $0xf0106f6b
f0104043:	e8 0b f6 ff ff       	call   f0103653 <cprintf>
f0104048:	83 c4 10             	add    $0x10,%esp
f010404b:	eb 25                	jmp    f0104072 <syscall+0xe3>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010404d:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104050:	e8 9d 11 00 00       	call   f01051f2 <cpunum>
f0104055:	83 ec 04             	sub    $0x4,%esp
f0104058:	53                   	push   %ebx
f0104059:	6b c0 74             	imul   $0x74,%eax,%eax
f010405c:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104062:	ff 70 48             	pushl  0x48(%eax)
f0104065:	68 86 6f 10 f0       	push   $0xf0106f86
f010406a:	e8 e4 f5 ff ff       	call   f0103653 <cprintf>
f010406f:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0104072:	83 ec 0c             	sub    $0xc,%esp
f0104075:	ff 75 f4             	pushl  -0xc(%ebp)
f0104078:	e8 e0 f2 ff ff       	call   f010335d <env_destroy>
f010407d:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104080:	b8 00 00 00 00       	mov    $0x0,%eax
f0104085:	eb 18                	jmp    f010409f <syscall+0x110>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104087:	e8 66 11 00 00       	call   f01051f2 <cpunum>
f010408c:	6b c0 74             	imul   $0x74,%eax,%eax
f010408f:	8b 80 28 b0 22 f0    	mov    -0xfdd4fd8(%eax),%eax
f0104095:	8b 40 48             	mov    0x48(%eax),%eax
	case SYS_env_destroy:
		ret = sys_env_destroy((envid_t)a1);
		break;
	case SYS_getenvid:
		ret = sys_getenvid();
		break;
f0104098:	eb 05                	jmp    f010409f <syscall+0x110>
	default:
		return -E_NO_SYS;
f010409a:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
	}
	return ret;
}
f010409f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01040a2:	c9                   	leave  
f01040a3:	c3                   	ret    

f01040a4 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01040a4:	55                   	push   %ebp
f01040a5:	89 e5                	mov    %esp,%ebp
f01040a7:	57                   	push   %edi
f01040a8:	56                   	push   %esi
f01040a9:	53                   	push   %ebx
f01040aa:	83 ec 14             	sub    $0x14,%esp
f01040ad:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01040b0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01040b3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01040b6:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01040b9:	8b 1a                	mov    (%edx),%ebx
f01040bb:	8b 01                	mov    (%ecx),%eax
f01040bd:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01040c0:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01040c7:	eb 7f                	jmp    f0104148 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01040c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01040cc:	01 d8                	add    %ebx,%eax
f01040ce:	89 c6                	mov    %eax,%esi
f01040d0:	c1 ee 1f             	shr    $0x1f,%esi
f01040d3:	01 c6                	add    %eax,%esi
f01040d5:	d1 fe                	sar    %esi
f01040d7:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01040da:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01040dd:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01040e0:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01040e2:	eb 03                	jmp    f01040e7 <stab_binsearch+0x43>
			m--;
f01040e4:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01040e7:	39 c3                	cmp    %eax,%ebx
f01040e9:	7f 0d                	jg     f01040f8 <stab_binsearch+0x54>
f01040eb:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01040ef:	83 ea 0c             	sub    $0xc,%edx
f01040f2:	39 f9                	cmp    %edi,%ecx
f01040f4:	75 ee                	jne    f01040e4 <stab_binsearch+0x40>
f01040f6:	eb 05                	jmp    f01040fd <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01040f8:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01040fb:	eb 4b                	jmp    f0104148 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01040fd:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104100:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104103:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104107:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010410a:	76 11                	jbe    f010411d <stab_binsearch+0x79>
			*region_left = m;
f010410c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010410f:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104111:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104114:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010411b:	eb 2b                	jmp    f0104148 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010411d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104120:	73 14                	jae    f0104136 <stab_binsearch+0x92>
			*region_right = m - 1;
f0104122:	83 e8 01             	sub    $0x1,%eax
f0104125:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104128:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010412b:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010412d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104134:	eb 12                	jmp    f0104148 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104136:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104139:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010413b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010413f:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104141:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104148:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010414b:	0f 8e 78 ff ff ff    	jle    f01040c9 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104151:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104155:	75 0f                	jne    f0104166 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0104157:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010415a:	8b 00                	mov    (%eax),%eax
f010415c:	83 e8 01             	sub    $0x1,%eax
f010415f:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104162:	89 06                	mov    %eax,(%esi)
f0104164:	eb 2c                	jmp    f0104192 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104166:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104169:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010416b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010416e:	8b 0e                	mov    (%esi),%ecx
f0104170:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104173:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104176:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104179:	eb 03                	jmp    f010417e <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010417b:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010417e:	39 c8                	cmp    %ecx,%eax
f0104180:	7e 0b                	jle    f010418d <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0104182:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104186:	83 ea 0c             	sub    $0xc,%edx
f0104189:	39 df                	cmp    %ebx,%edi
f010418b:	75 ee                	jne    f010417b <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010418d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104190:	89 06                	mov    %eax,(%esi)
	}
}
f0104192:	83 c4 14             	add    $0x14,%esp
f0104195:	5b                   	pop    %ebx
f0104196:	5e                   	pop    %esi
f0104197:	5f                   	pop    %edi
f0104198:	5d                   	pop    %ebp
f0104199:	c3                   	ret    

f010419a <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010419a:	55                   	push   %ebp
f010419b:	89 e5                	mov    %esp,%ebp
f010419d:	57                   	push   %edi
f010419e:	56                   	push   %esi
f010419f:	53                   	push   %ebx
f01041a0:	83 ec 3c             	sub    $0x3c,%esp
f01041a3:	8b 7d 08             	mov    0x8(%ebp),%edi
f01041a6:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01041a9:	c7 06 9e 6f 10 f0    	movl   $0xf0106f9e,(%esi)
	info->eip_line = 0;
f01041af:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01041b6:	c7 46 08 9e 6f 10 f0 	movl   $0xf0106f9e,0x8(%esi)
	info->eip_fn_namelen = 9;
f01041bd:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01041c4:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01041c7:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01041ce:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01041d4:	0f 87 92 00 00 00    	ja     f010426c <debuginfo_eip+0xd2>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0)
f01041da:	e8 13 10 00 00       	call   f01051f2 <cpunum>
f01041df:	6a 04                	push   $0x4
f01041e1:	6a 10                	push   $0x10
f01041e3:	68 00 00 20 00       	push   $0x200000
f01041e8:	6b c0 74             	imul   $0x74,%eax,%eax
f01041eb:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f01041f1:	e8 34 ea ff ff       	call   f0102c2a <user_mem_check>
f01041f6:	83 c4 10             	add    $0x10,%esp
f01041f9:	85 c0                	test   %eax,%eax
f01041fb:	0f 85 01 02 00 00    	jne    f0104402 <debuginfo_eip+0x268>
			return -1;
		stabs = usd->stabs;
f0104201:	a1 00 00 20 00       	mov    0x200000,%eax
f0104206:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f0104209:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f010420f:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0104215:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f0104218:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f010421e:	89 55 d0             	mov    %edx,-0x30(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, sizeof(struct UserStabData), PTE_U) != 0)
f0104221:	e8 cc 0f 00 00       	call   f01051f2 <cpunum>
f0104226:	6a 04                	push   $0x4
f0104228:	6a 10                	push   $0x10
f010422a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010422d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104230:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f0104236:	e8 ef e9 ff ff       	call   f0102c2a <user_mem_check>
f010423b:	83 c4 10             	add    $0x10,%esp
f010423e:	85 c0                	test   %eax,%eax
f0104240:	0f 85 c3 01 00 00    	jne    f0104409 <debuginfo_eip+0x26f>
			return -1;
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
f0104246:	e8 a7 0f 00 00       	call   f01051f2 <cpunum>
f010424b:	6a 04                	push   $0x4
f010424d:	6a 10                	push   $0x10
f010424f:	ff 75 cc             	pushl  -0x34(%ebp)
f0104252:	6b c0 74             	imul   $0x74,%eax,%eax
f0104255:	ff b0 28 b0 22 f0    	pushl  -0xfdd4fd8(%eax)
f010425b:	e8 ca e9 ff ff       	call   f0102c2a <user_mem_check>
f0104260:	83 c4 10             	add    $0x10,%esp
f0104263:	85 c0                	test   %eax,%eax
f0104265:	74 1f                	je     f0104286 <debuginfo_eip+0xec>
f0104267:	e9 a4 01 00 00       	jmp    f0104410 <debuginfo_eip+0x276>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010426c:	c7 45 d0 22 41 11 f0 	movl   $0xf0114122,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104273:	c7 45 cc 21 0b 11 f0 	movl   $0xf0110b21,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f010427a:	bb 20 0b 11 f0       	mov    $0xf0110b20,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f010427f:	c7 45 d4 78 74 10 f0 	movl   $0xf0107478,-0x2c(%ebp)
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104286:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104289:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f010428c:	0f 83 85 01 00 00    	jae    f0104417 <debuginfo_eip+0x27d>
f0104292:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104296:	0f 85 82 01 00 00    	jne    f010441e <debuginfo_eip+0x284>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010429c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01042a3:	2b 5d d4             	sub    -0x2c(%ebp),%ebx
f01042a6:	c1 fb 02             	sar    $0x2,%ebx
f01042a9:	69 c3 ab aa aa aa    	imul   $0xaaaaaaab,%ebx,%eax
f01042af:	83 e8 01             	sub    $0x1,%eax
f01042b2:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01042b5:	83 ec 08             	sub    $0x8,%esp
f01042b8:	57                   	push   %edi
f01042b9:	6a 64                	push   $0x64
f01042bb:	8d 55 e0             	lea    -0x20(%ebp),%edx
f01042be:	89 d1                	mov    %edx,%ecx
f01042c0:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01042c3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01042c6:	89 d8                	mov    %ebx,%eax
f01042c8:	e8 d7 fd ff ff       	call   f01040a4 <stab_binsearch>
	if (lfile == 0)
f01042cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01042d0:	83 c4 10             	add    $0x10,%esp
f01042d3:	85 c0                	test   %eax,%eax
f01042d5:	0f 84 4a 01 00 00    	je     f0104425 <debuginfo_eip+0x28b>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01042db:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01042de:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01042e1:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01042e4:	83 ec 08             	sub    $0x8,%esp
f01042e7:	57                   	push   %edi
f01042e8:	6a 24                	push   $0x24
f01042ea:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01042ed:	89 d1                	mov    %edx,%ecx
f01042ef:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01042f2:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f01042f5:	89 d8                	mov    %ebx,%eax
f01042f7:	e8 a8 fd ff ff       	call   f01040a4 <stab_binsearch>

	if (lfun <= rfun) {
f01042fc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01042ff:	83 c4 10             	add    $0x10,%esp
f0104302:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0104305:	7f 25                	jg     f010432c <debuginfo_eip+0x192>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104307:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010430a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010430d:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104310:	8b 02                	mov    (%edx),%eax
f0104312:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0104315:	2b 4d cc             	sub    -0x34(%ebp),%ecx
f0104318:	39 c8                	cmp    %ecx,%eax
f010431a:	73 06                	jae    f0104322 <debuginfo_eip+0x188>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010431c:	03 45 cc             	add    -0x34(%ebp),%eax
f010431f:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104322:	8b 42 08             	mov    0x8(%edx),%eax
f0104325:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f0104328:	29 c7                	sub    %eax,%edi
f010432a:	eb 06                	jmp    f0104332 <debuginfo_eip+0x198>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010432c:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f010432f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104332:	83 ec 08             	sub    $0x8,%esp
f0104335:	6a 3a                	push   $0x3a
f0104337:	ff 76 08             	pushl  0x8(%esi)
f010433a:	e8 74 08 00 00       	call   f0104bb3 <strfind>
f010433f:	2b 46 08             	sub    0x8(%esi),%eax
f0104342:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
f0104345:	83 c4 08             	add    $0x8,%esp
f0104348:	2b 7e 10             	sub    0x10(%esi),%edi
f010434b:	57                   	push   %edi
f010434c:	6a 44                	push   $0x44
f010434e:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104351:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104354:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104357:	89 f8                	mov    %edi,%eax
f0104359:	e8 46 fd ff ff       	call   f01040a4 <stab_binsearch>
	if (lfun > rfun) 
f010435e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104361:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0104364:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0104367:	83 c4 10             	add    $0x10,%esp
f010436a:	39 c8                	cmp    %ecx,%eax
f010436c:	0f 8f ba 00 00 00    	jg     f010442c <debuginfo_eip+0x292>
       	  return -1;
        info->eip_line = stabs[lfun].n_desc;
f0104372:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104375:	89 fa                	mov    %edi,%edx
f0104377:	8d 04 87             	lea    (%edi,%eax,4),%eax
f010437a:	89 45 c0             	mov    %eax,-0x40(%ebp)
f010437d:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f0104381:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104384:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104387:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010438a:	8d 04 82             	lea    (%edx,%eax,4),%eax
f010438d:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0104390:	eb 06                	jmp    f0104398 <debuginfo_eip+0x1fe>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0104392:	83 eb 01             	sub    $0x1,%ebx
f0104395:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104398:	39 fb                	cmp    %edi,%ebx
f010439a:	7c 32                	jl     f01043ce <debuginfo_eip+0x234>
	       && stabs[lline].n_type != N_SOL
f010439c:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01043a0:	80 fa 84             	cmp    $0x84,%dl
f01043a3:	74 0b                	je     f01043b0 <debuginfo_eip+0x216>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01043a5:	80 fa 64             	cmp    $0x64,%dl
f01043a8:	75 e8                	jne    f0104392 <debuginfo_eip+0x1f8>
f01043aa:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01043ae:	74 e2                	je     f0104392 <debuginfo_eip+0x1f8>
f01043b0:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01043b3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01043b6:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01043b9:	8b 04 87             	mov    (%edi,%eax,4),%eax
f01043bc:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01043bf:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01043c2:	29 fa                	sub    %edi,%edx
f01043c4:	39 d0                	cmp    %edx,%eax
f01043c6:	73 09                	jae    f01043d1 <debuginfo_eip+0x237>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01043c8:	01 f8                	add    %edi,%eax
f01043ca:	89 06                	mov    %eax,(%esi)
f01043cc:	eb 03                	jmp    f01043d1 <debuginfo_eip+0x237>
f01043ce:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01043d1:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01043d6:	8b 7d c8             	mov    -0x38(%ebp),%edi
f01043d9:	39 cf                	cmp    %ecx,%edi
f01043db:	7d 5b                	jge    f0104438 <debuginfo_eip+0x29e>
		for (lline = lfun + 1;
f01043dd:	89 f8                	mov    %edi,%eax
f01043df:	83 c0 01             	add    $0x1,%eax
f01043e2:	8b 55 c0             	mov    -0x40(%ebp),%edx
f01043e5:	eb 07                	jmp    f01043ee <debuginfo_eip+0x254>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01043e7:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01043eb:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01043ee:	39 c8                	cmp    %ecx,%eax
f01043f0:	74 41                	je     f0104433 <debuginfo_eip+0x299>
f01043f2:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01043f5:	80 7a 04 a0          	cmpb   $0xa0,0x4(%edx)
f01043f9:	74 ec                	je     f01043e7 <debuginfo_eip+0x24d>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01043fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0104400:	eb 36                	jmp    f0104438 <debuginfo_eip+0x29e>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)usd, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f0104402:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104407:	eb 2f                	jmp    f0104438 <debuginfo_eip+0x29e>
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if(user_mem_check(curenv, (void *)stabs, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f0104409:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010440e:	eb 28                	jmp    f0104438 <debuginfo_eip+0x29e>
		if(user_mem_check(curenv, (void *)stabstr, sizeof(struct UserStabData), PTE_U) != 0)
			return -1;
f0104410:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104415:	eb 21                	jmp    f0104438 <debuginfo_eip+0x29e>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104417:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010441c:	eb 1a                	jmp    f0104438 <debuginfo_eip+0x29e>
f010441e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104423:	eb 13                	jmp    f0104438 <debuginfo_eip+0x29e>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104425:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010442a:	eb 0c                	jmp    f0104438 <debuginfo_eip+0x29e>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
	if (lfun > rfun) 
       	  return -1;
f010442c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104431:	eb 05                	jmp    f0104438 <debuginfo_eip+0x29e>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104433:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104438:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010443b:	5b                   	pop    %ebx
f010443c:	5e                   	pop    %esi
f010443d:	5f                   	pop    %edi
f010443e:	5d                   	pop    %ebp
f010443f:	c3                   	ret    

f0104440 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104440:	55                   	push   %ebp
f0104441:	89 e5                	mov    %esp,%ebp
f0104443:	57                   	push   %edi
f0104444:	56                   	push   %esi
f0104445:	53                   	push   %ebx
f0104446:	83 ec 1c             	sub    $0x1c,%esp
f0104449:	89 c7                	mov    %eax,%edi
f010444b:	89 d6                	mov    %edx,%esi
f010444d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104450:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104453:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104456:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104459:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010445c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104461:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104464:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0104467:	39 d3                	cmp    %edx,%ebx
f0104469:	72 05                	jb     f0104470 <printnum+0x30>
f010446b:	39 45 10             	cmp    %eax,0x10(%ebp)
f010446e:	77 45                	ja     f01044b5 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104470:	83 ec 0c             	sub    $0xc,%esp
f0104473:	ff 75 18             	pushl  0x18(%ebp)
f0104476:	8b 45 14             	mov    0x14(%ebp),%eax
f0104479:	8d 58 ff             	lea    -0x1(%eax),%ebx
f010447c:	53                   	push   %ebx
f010447d:	ff 75 10             	pushl  0x10(%ebp)
f0104480:	83 ec 08             	sub    $0x8,%esp
f0104483:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104486:	ff 75 e0             	pushl  -0x20(%ebp)
f0104489:	ff 75 dc             	pushl  -0x24(%ebp)
f010448c:	ff 75 d8             	pushl  -0x28(%ebp)
f010448f:	e8 5c 11 00 00       	call   f01055f0 <__udivdi3>
f0104494:	83 c4 18             	add    $0x18,%esp
f0104497:	52                   	push   %edx
f0104498:	50                   	push   %eax
f0104499:	89 f2                	mov    %esi,%edx
f010449b:	89 f8                	mov    %edi,%eax
f010449d:	e8 9e ff ff ff       	call   f0104440 <printnum>
f01044a2:	83 c4 20             	add    $0x20,%esp
f01044a5:	eb 18                	jmp    f01044bf <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01044a7:	83 ec 08             	sub    $0x8,%esp
f01044aa:	56                   	push   %esi
f01044ab:	ff 75 18             	pushl  0x18(%ebp)
f01044ae:	ff d7                	call   *%edi
f01044b0:	83 c4 10             	add    $0x10,%esp
f01044b3:	eb 03                	jmp    f01044b8 <printnum+0x78>
f01044b5:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01044b8:	83 eb 01             	sub    $0x1,%ebx
f01044bb:	85 db                	test   %ebx,%ebx
f01044bd:	7f e8                	jg     f01044a7 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01044bf:	83 ec 08             	sub    $0x8,%esp
f01044c2:	56                   	push   %esi
f01044c3:	83 ec 04             	sub    $0x4,%esp
f01044c6:	ff 75 e4             	pushl  -0x1c(%ebp)
f01044c9:	ff 75 e0             	pushl  -0x20(%ebp)
f01044cc:	ff 75 dc             	pushl  -0x24(%ebp)
f01044cf:	ff 75 d8             	pushl  -0x28(%ebp)
f01044d2:	e8 49 12 00 00       	call   f0105720 <__umoddi3>
f01044d7:	83 c4 14             	add    $0x14,%esp
f01044da:	0f be 80 a8 6f 10 f0 	movsbl -0xfef9058(%eax),%eax
f01044e1:	50                   	push   %eax
f01044e2:	ff d7                	call   *%edi
}
f01044e4:	83 c4 10             	add    $0x10,%esp
f01044e7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01044ea:	5b                   	pop    %ebx
f01044eb:	5e                   	pop    %esi
f01044ec:	5f                   	pop    %edi
f01044ed:	5d                   	pop    %ebp
f01044ee:	c3                   	ret    

f01044ef <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01044ef:	55                   	push   %ebp
f01044f0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01044f2:	83 fa 01             	cmp    $0x1,%edx
f01044f5:	7e 0e                	jle    f0104505 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01044f7:	8b 10                	mov    (%eax),%edx
f01044f9:	8d 4a 08             	lea    0x8(%edx),%ecx
f01044fc:	89 08                	mov    %ecx,(%eax)
f01044fe:	8b 02                	mov    (%edx),%eax
f0104500:	8b 52 04             	mov    0x4(%edx),%edx
f0104503:	eb 22                	jmp    f0104527 <getuint+0x38>
	else if (lflag)
f0104505:	85 d2                	test   %edx,%edx
f0104507:	74 10                	je     f0104519 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104509:	8b 10                	mov    (%eax),%edx
f010450b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010450e:	89 08                	mov    %ecx,(%eax)
f0104510:	8b 02                	mov    (%edx),%eax
f0104512:	ba 00 00 00 00       	mov    $0x0,%edx
f0104517:	eb 0e                	jmp    f0104527 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104519:	8b 10                	mov    (%eax),%edx
f010451b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010451e:	89 08                	mov    %ecx,(%eax)
f0104520:	8b 02                	mov    (%edx),%eax
f0104522:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104527:	5d                   	pop    %ebp
f0104528:	c3                   	ret    

f0104529 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104529:	55                   	push   %ebp
f010452a:	89 e5                	mov    %esp,%ebp
f010452c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010452f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104533:	8b 10                	mov    (%eax),%edx
f0104535:	3b 50 04             	cmp    0x4(%eax),%edx
f0104538:	73 0a                	jae    f0104544 <sprintputch+0x1b>
		*b->buf++ = ch;
f010453a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010453d:	89 08                	mov    %ecx,(%eax)
f010453f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104542:	88 02                	mov    %al,(%edx)
}
f0104544:	5d                   	pop    %ebp
f0104545:	c3                   	ret    

f0104546 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104546:	55                   	push   %ebp
f0104547:	89 e5                	mov    %esp,%ebp
f0104549:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010454c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010454f:	50                   	push   %eax
f0104550:	ff 75 10             	pushl  0x10(%ebp)
f0104553:	ff 75 0c             	pushl  0xc(%ebp)
f0104556:	ff 75 08             	pushl  0x8(%ebp)
f0104559:	e8 05 00 00 00       	call   f0104563 <vprintfmt>
	va_end(ap);
}
f010455e:	83 c4 10             	add    $0x10,%esp
f0104561:	c9                   	leave  
f0104562:	c3                   	ret    

f0104563 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104563:	55                   	push   %ebp
f0104564:	89 e5                	mov    %esp,%ebp
f0104566:	57                   	push   %edi
f0104567:	56                   	push   %esi
f0104568:	53                   	push   %ebx
f0104569:	83 ec 2c             	sub    $0x2c,%esp
f010456c:	8b 75 08             	mov    0x8(%ebp),%esi
f010456f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104572:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104575:	eb 12                	jmp    f0104589 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104577:	85 c0                	test   %eax,%eax
f0104579:	0f 84 89 03 00 00    	je     f0104908 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f010457f:	83 ec 08             	sub    $0x8,%esp
f0104582:	53                   	push   %ebx
f0104583:	50                   	push   %eax
f0104584:	ff d6                	call   *%esi
f0104586:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104589:	83 c7 01             	add    $0x1,%edi
f010458c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104590:	83 f8 25             	cmp    $0x25,%eax
f0104593:	75 e2                	jne    f0104577 <vprintfmt+0x14>
f0104595:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104599:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01045a0:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01045a7:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01045ae:	ba 00 00 00 00       	mov    $0x0,%edx
f01045b3:	eb 07                	jmp    f01045bc <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045b5:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01045b8:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045bc:	8d 47 01             	lea    0x1(%edi),%eax
f01045bf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01045c2:	0f b6 07             	movzbl (%edi),%eax
f01045c5:	0f b6 c8             	movzbl %al,%ecx
f01045c8:	83 e8 23             	sub    $0x23,%eax
f01045cb:	3c 55                	cmp    $0x55,%al
f01045cd:	0f 87 1a 03 00 00    	ja     f01048ed <vprintfmt+0x38a>
f01045d3:	0f b6 c0             	movzbl %al,%eax
f01045d6:	ff 24 85 60 70 10 f0 	jmp    *-0xfef8fa0(,%eax,4)
f01045dd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01045e0:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01045e4:	eb d6                	jmp    f01045bc <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045e6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01045e9:	b8 00 00 00 00       	mov    $0x0,%eax
f01045ee:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01045f1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01045f4:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f01045f8:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f01045fb:	8d 51 d0             	lea    -0x30(%ecx),%edx
f01045fe:	83 fa 09             	cmp    $0x9,%edx
f0104601:	77 39                	ja     f010463c <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104603:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104606:	eb e9                	jmp    f01045f1 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104608:	8b 45 14             	mov    0x14(%ebp),%eax
f010460b:	8d 48 04             	lea    0x4(%eax),%ecx
f010460e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104611:	8b 00                	mov    (%eax),%eax
f0104613:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104616:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104619:	eb 27                	jmp    f0104642 <vprintfmt+0xdf>
f010461b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010461e:	85 c0                	test   %eax,%eax
f0104620:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104625:	0f 49 c8             	cmovns %eax,%ecx
f0104628:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010462b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010462e:	eb 8c                	jmp    f01045bc <vprintfmt+0x59>
f0104630:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104633:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010463a:	eb 80                	jmp    f01045bc <vprintfmt+0x59>
f010463c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010463f:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104642:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104646:	0f 89 70 ff ff ff    	jns    f01045bc <vprintfmt+0x59>
				width = precision, precision = -1;
f010464c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010464f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104652:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104659:	e9 5e ff ff ff       	jmp    f01045bc <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010465e:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104661:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104664:	e9 53 ff ff ff       	jmp    f01045bc <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104669:	8b 45 14             	mov    0x14(%ebp),%eax
f010466c:	8d 50 04             	lea    0x4(%eax),%edx
f010466f:	89 55 14             	mov    %edx,0x14(%ebp)
f0104672:	83 ec 08             	sub    $0x8,%esp
f0104675:	53                   	push   %ebx
f0104676:	ff 30                	pushl  (%eax)
f0104678:	ff d6                	call   *%esi
			break;
f010467a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010467d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104680:	e9 04 ff ff ff       	jmp    f0104589 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104685:	8b 45 14             	mov    0x14(%ebp),%eax
f0104688:	8d 50 04             	lea    0x4(%eax),%edx
f010468b:	89 55 14             	mov    %edx,0x14(%ebp)
f010468e:	8b 00                	mov    (%eax),%eax
f0104690:	99                   	cltd   
f0104691:	31 d0                	xor    %edx,%eax
f0104693:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104695:	83 f8 09             	cmp    $0x9,%eax
f0104698:	7f 0b                	jg     f01046a5 <vprintfmt+0x142>
f010469a:	8b 14 85 c0 71 10 f0 	mov    -0xfef8e40(,%eax,4),%edx
f01046a1:	85 d2                	test   %edx,%edx
f01046a3:	75 18                	jne    f01046bd <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f01046a5:	50                   	push   %eax
f01046a6:	68 c0 6f 10 f0       	push   $0xf0106fc0
f01046ab:	53                   	push   %ebx
f01046ac:	56                   	push   %esi
f01046ad:	e8 94 fe ff ff       	call   f0104546 <printfmt>
f01046b2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046b5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01046b8:	e9 cc fe ff ff       	jmp    f0104589 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f01046bd:	52                   	push   %edx
f01046be:	68 79 67 10 f0       	push   $0xf0106779
f01046c3:	53                   	push   %ebx
f01046c4:	56                   	push   %esi
f01046c5:	e8 7c fe ff ff       	call   f0104546 <printfmt>
f01046ca:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01046cd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01046d0:	e9 b4 fe ff ff       	jmp    f0104589 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01046d5:	8b 45 14             	mov    0x14(%ebp),%eax
f01046d8:	8d 50 04             	lea    0x4(%eax),%edx
f01046db:	89 55 14             	mov    %edx,0x14(%ebp)
f01046de:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01046e0:	85 ff                	test   %edi,%edi
f01046e2:	b8 b9 6f 10 f0       	mov    $0xf0106fb9,%eax
f01046e7:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01046ea:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01046ee:	0f 8e 94 00 00 00    	jle    f0104788 <vprintfmt+0x225>
f01046f4:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01046f8:	0f 84 98 00 00 00    	je     f0104796 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f01046fe:	83 ec 08             	sub    $0x8,%esp
f0104701:	ff 75 d0             	pushl  -0x30(%ebp)
f0104704:	57                   	push   %edi
f0104705:	e8 5f 03 00 00       	call   f0104a69 <strnlen>
f010470a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010470d:	29 c1                	sub    %eax,%ecx
f010470f:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104712:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104715:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104719:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010471c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010471f:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104721:	eb 0f                	jmp    f0104732 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0104723:	83 ec 08             	sub    $0x8,%esp
f0104726:	53                   	push   %ebx
f0104727:	ff 75 e0             	pushl  -0x20(%ebp)
f010472a:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010472c:	83 ef 01             	sub    $0x1,%edi
f010472f:	83 c4 10             	add    $0x10,%esp
f0104732:	85 ff                	test   %edi,%edi
f0104734:	7f ed                	jg     f0104723 <vprintfmt+0x1c0>
f0104736:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104739:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010473c:	85 c9                	test   %ecx,%ecx
f010473e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104743:	0f 49 c1             	cmovns %ecx,%eax
f0104746:	29 c1                	sub    %eax,%ecx
f0104748:	89 75 08             	mov    %esi,0x8(%ebp)
f010474b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010474e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104751:	89 cb                	mov    %ecx,%ebx
f0104753:	eb 4d                	jmp    f01047a2 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104755:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104759:	74 1b                	je     f0104776 <vprintfmt+0x213>
f010475b:	0f be c0             	movsbl %al,%eax
f010475e:	83 e8 20             	sub    $0x20,%eax
f0104761:	83 f8 5e             	cmp    $0x5e,%eax
f0104764:	76 10                	jbe    f0104776 <vprintfmt+0x213>
					putch('?', putdat);
f0104766:	83 ec 08             	sub    $0x8,%esp
f0104769:	ff 75 0c             	pushl  0xc(%ebp)
f010476c:	6a 3f                	push   $0x3f
f010476e:	ff 55 08             	call   *0x8(%ebp)
f0104771:	83 c4 10             	add    $0x10,%esp
f0104774:	eb 0d                	jmp    f0104783 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0104776:	83 ec 08             	sub    $0x8,%esp
f0104779:	ff 75 0c             	pushl  0xc(%ebp)
f010477c:	52                   	push   %edx
f010477d:	ff 55 08             	call   *0x8(%ebp)
f0104780:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104783:	83 eb 01             	sub    $0x1,%ebx
f0104786:	eb 1a                	jmp    f01047a2 <vprintfmt+0x23f>
f0104788:	89 75 08             	mov    %esi,0x8(%ebp)
f010478b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010478e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104791:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104794:	eb 0c                	jmp    f01047a2 <vprintfmt+0x23f>
f0104796:	89 75 08             	mov    %esi,0x8(%ebp)
f0104799:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010479c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010479f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01047a2:	83 c7 01             	add    $0x1,%edi
f01047a5:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01047a9:	0f be d0             	movsbl %al,%edx
f01047ac:	85 d2                	test   %edx,%edx
f01047ae:	74 23                	je     f01047d3 <vprintfmt+0x270>
f01047b0:	85 f6                	test   %esi,%esi
f01047b2:	78 a1                	js     f0104755 <vprintfmt+0x1f2>
f01047b4:	83 ee 01             	sub    $0x1,%esi
f01047b7:	79 9c                	jns    f0104755 <vprintfmt+0x1f2>
f01047b9:	89 df                	mov    %ebx,%edi
f01047bb:	8b 75 08             	mov    0x8(%ebp),%esi
f01047be:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01047c1:	eb 18                	jmp    f01047db <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01047c3:	83 ec 08             	sub    $0x8,%esp
f01047c6:	53                   	push   %ebx
f01047c7:	6a 20                	push   $0x20
f01047c9:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01047cb:	83 ef 01             	sub    $0x1,%edi
f01047ce:	83 c4 10             	add    $0x10,%esp
f01047d1:	eb 08                	jmp    f01047db <vprintfmt+0x278>
f01047d3:	89 df                	mov    %ebx,%edi
f01047d5:	8b 75 08             	mov    0x8(%ebp),%esi
f01047d8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01047db:	85 ff                	test   %edi,%edi
f01047dd:	7f e4                	jg     f01047c3 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01047df:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01047e2:	e9 a2 fd ff ff       	jmp    f0104589 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01047e7:	83 fa 01             	cmp    $0x1,%edx
f01047ea:	7e 16                	jle    f0104802 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01047ec:	8b 45 14             	mov    0x14(%ebp),%eax
f01047ef:	8d 50 08             	lea    0x8(%eax),%edx
f01047f2:	89 55 14             	mov    %edx,0x14(%ebp)
f01047f5:	8b 50 04             	mov    0x4(%eax),%edx
f01047f8:	8b 00                	mov    (%eax),%eax
f01047fa:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01047fd:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104800:	eb 32                	jmp    f0104834 <vprintfmt+0x2d1>
	else if (lflag)
f0104802:	85 d2                	test   %edx,%edx
f0104804:	74 18                	je     f010481e <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0104806:	8b 45 14             	mov    0x14(%ebp),%eax
f0104809:	8d 50 04             	lea    0x4(%eax),%edx
f010480c:	89 55 14             	mov    %edx,0x14(%ebp)
f010480f:	8b 00                	mov    (%eax),%eax
f0104811:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104814:	89 c1                	mov    %eax,%ecx
f0104816:	c1 f9 1f             	sar    $0x1f,%ecx
f0104819:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010481c:	eb 16                	jmp    f0104834 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f010481e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104821:	8d 50 04             	lea    0x4(%eax),%edx
f0104824:	89 55 14             	mov    %edx,0x14(%ebp)
f0104827:	8b 00                	mov    (%eax),%eax
f0104829:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010482c:	89 c1                	mov    %eax,%ecx
f010482e:	c1 f9 1f             	sar    $0x1f,%ecx
f0104831:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104834:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104837:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010483a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010483f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104843:	79 74                	jns    f01048b9 <vprintfmt+0x356>
				putch('-', putdat);
f0104845:	83 ec 08             	sub    $0x8,%esp
f0104848:	53                   	push   %ebx
f0104849:	6a 2d                	push   $0x2d
f010484b:	ff d6                	call   *%esi
				num = -(long long) num;
f010484d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104850:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104853:	f7 d8                	neg    %eax
f0104855:	83 d2 00             	adc    $0x0,%edx
f0104858:	f7 da                	neg    %edx
f010485a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010485d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104862:	eb 55                	jmp    f01048b9 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104864:	8d 45 14             	lea    0x14(%ebp),%eax
f0104867:	e8 83 fc ff ff       	call   f01044ef <getuint>
			base = 10;
f010486c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104871:	eb 46                	jmp    f01048b9 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0104873:	8d 45 14             	lea    0x14(%ebp),%eax
f0104876:	e8 74 fc ff ff       	call   f01044ef <getuint>
			base = 8;
f010487b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104880:	eb 37                	jmp    f01048b9 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0104882:	83 ec 08             	sub    $0x8,%esp
f0104885:	53                   	push   %ebx
f0104886:	6a 30                	push   $0x30
f0104888:	ff d6                	call   *%esi
			putch('x', putdat);
f010488a:	83 c4 08             	add    $0x8,%esp
f010488d:	53                   	push   %ebx
f010488e:	6a 78                	push   $0x78
f0104890:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104892:	8b 45 14             	mov    0x14(%ebp),%eax
f0104895:	8d 50 04             	lea    0x4(%eax),%edx
f0104898:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010489b:	8b 00                	mov    (%eax),%eax
f010489d:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01048a2:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01048a5:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01048aa:	eb 0d                	jmp    f01048b9 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01048ac:	8d 45 14             	lea    0x14(%ebp),%eax
f01048af:	e8 3b fc ff ff       	call   f01044ef <getuint>
			base = 16;
f01048b4:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01048b9:	83 ec 0c             	sub    $0xc,%esp
f01048bc:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01048c0:	57                   	push   %edi
f01048c1:	ff 75 e0             	pushl  -0x20(%ebp)
f01048c4:	51                   	push   %ecx
f01048c5:	52                   	push   %edx
f01048c6:	50                   	push   %eax
f01048c7:	89 da                	mov    %ebx,%edx
f01048c9:	89 f0                	mov    %esi,%eax
f01048cb:	e8 70 fb ff ff       	call   f0104440 <printnum>
			break;
f01048d0:	83 c4 20             	add    $0x20,%esp
f01048d3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01048d6:	e9 ae fc ff ff       	jmp    f0104589 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01048db:	83 ec 08             	sub    $0x8,%esp
f01048de:	53                   	push   %ebx
f01048df:	51                   	push   %ecx
f01048e0:	ff d6                	call   *%esi
			break;
f01048e2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01048e5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01048e8:	e9 9c fc ff ff       	jmp    f0104589 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01048ed:	83 ec 08             	sub    $0x8,%esp
f01048f0:	53                   	push   %ebx
f01048f1:	6a 25                	push   $0x25
f01048f3:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01048f5:	83 c4 10             	add    $0x10,%esp
f01048f8:	eb 03                	jmp    f01048fd <vprintfmt+0x39a>
f01048fa:	83 ef 01             	sub    $0x1,%edi
f01048fd:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104901:	75 f7                	jne    f01048fa <vprintfmt+0x397>
f0104903:	e9 81 fc ff ff       	jmp    f0104589 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0104908:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010490b:	5b                   	pop    %ebx
f010490c:	5e                   	pop    %esi
f010490d:	5f                   	pop    %edi
f010490e:	5d                   	pop    %ebp
f010490f:	c3                   	ret    

f0104910 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104910:	55                   	push   %ebp
f0104911:	89 e5                	mov    %esp,%ebp
f0104913:	83 ec 18             	sub    $0x18,%esp
f0104916:	8b 45 08             	mov    0x8(%ebp),%eax
f0104919:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010491c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010491f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104923:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104926:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010492d:	85 c0                	test   %eax,%eax
f010492f:	74 26                	je     f0104957 <vsnprintf+0x47>
f0104931:	85 d2                	test   %edx,%edx
f0104933:	7e 22                	jle    f0104957 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104935:	ff 75 14             	pushl  0x14(%ebp)
f0104938:	ff 75 10             	pushl  0x10(%ebp)
f010493b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010493e:	50                   	push   %eax
f010493f:	68 29 45 10 f0       	push   $0xf0104529
f0104944:	e8 1a fc ff ff       	call   f0104563 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104949:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010494c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010494f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104952:	83 c4 10             	add    $0x10,%esp
f0104955:	eb 05                	jmp    f010495c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104957:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010495c:	c9                   	leave  
f010495d:	c3                   	ret    

f010495e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010495e:	55                   	push   %ebp
f010495f:	89 e5                	mov    %esp,%ebp
f0104961:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104964:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104967:	50                   	push   %eax
f0104968:	ff 75 10             	pushl  0x10(%ebp)
f010496b:	ff 75 0c             	pushl  0xc(%ebp)
f010496e:	ff 75 08             	pushl  0x8(%ebp)
f0104971:	e8 9a ff ff ff       	call   f0104910 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104976:	c9                   	leave  
f0104977:	c3                   	ret    

f0104978 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104978:	55                   	push   %ebp
f0104979:	89 e5                	mov    %esp,%ebp
f010497b:	57                   	push   %edi
f010497c:	56                   	push   %esi
f010497d:	53                   	push   %ebx
f010497e:	83 ec 0c             	sub    $0xc,%esp
f0104981:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104984:	85 c0                	test   %eax,%eax
f0104986:	74 11                	je     f0104999 <readline+0x21>
		cprintf("%s", prompt);
f0104988:	83 ec 08             	sub    $0x8,%esp
f010498b:	50                   	push   %eax
f010498c:	68 79 67 10 f0       	push   $0xf0106779
f0104991:	e8 bd ec ff ff       	call   f0103653 <cprintf>
f0104996:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104999:	83 ec 0c             	sub    $0xc,%esp
f010499c:	6a 00                	push   $0x0
f010499e:	e8 ef bd ff ff       	call   f0100792 <iscons>
f01049a3:	89 c7                	mov    %eax,%edi
f01049a5:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01049a8:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01049ad:	e8 cf bd ff ff       	call   f0100781 <getchar>
f01049b2:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01049b4:	85 c0                	test   %eax,%eax
f01049b6:	79 18                	jns    f01049d0 <readline+0x58>
			cprintf("read error: %e\n", c);
f01049b8:	83 ec 08             	sub    $0x8,%esp
f01049bb:	50                   	push   %eax
f01049bc:	68 e8 71 10 f0       	push   $0xf01071e8
f01049c1:	e8 8d ec ff ff       	call   f0103653 <cprintf>
			return NULL;
f01049c6:	83 c4 10             	add    $0x10,%esp
f01049c9:	b8 00 00 00 00       	mov    $0x0,%eax
f01049ce:	eb 79                	jmp    f0104a49 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01049d0:	83 f8 08             	cmp    $0x8,%eax
f01049d3:	0f 94 c2             	sete   %dl
f01049d6:	83 f8 7f             	cmp    $0x7f,%eax
f01049d9:	0f 94 c0             	sete   %al
f01049dc:	08 c2                	or     %al,%dl
f01049de:	74 1a                	je     f01049fa <readline+0x82>
f01049e0:	85 f6                	test   %esi,%esi
f01049e2:	7e 16                	jle    f01049fa <readline+0x82>
			if (echoing)
f01049e4:	85 ff                	test   %edi,%edi
f01049e6:	74 0d                	je     f01049f5 <readline+0x7d>
				cputchar('\b');
f01049e8:	83 ec 0c             	sub    $0xc,%esp
f01049eb:	6a 08                	push   $0x8
f01049ed:	e8 7f bd ff ff       	call   f0100771 <cputchar>
f01049f2:	83 c4 10             	add    $0x10,%esp
			i--;
f01049f5:	83 ee 01             	sub    $0x1,%esi
f01049f8:	eb b3                	jmp    f01049ad <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01049fa:	83 fb 1f             	cmp    $0x1f,%ebx
f01049fd:	7e 23                	jle    f0104a22 <readline+0xaa>
f01049ff:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104a05:	7f 1b                	jg     f0104a22 <readline+0xaa>
			if (echoing)
f0104a07:	85 ff                	test   %edi,%edi
f0104a09:	74 0c                	je     f0104a17 <readline+0x9f>
				cputchar(c);
f0104a0b:	83 ec 0c             	sub    $0xc,%esp
f0104a0e:	53                   	push   %ebx
f0104a0f:	e8 5d bd ff ff       	call   f0100771 <cputchar>
f0104a14:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104a17:	88 9e 00 ab 22 f0    	mov    %bl,-0xfdd5500(%esi)
f0104a1d:	8d 76 01             	lea    0x1(%esi),%esi
f0104a20:	eb 8b                	jmp    f01049ad <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104a22:	83 fb 0a             	cmp    $0xa,%ebx
f0104a25:	74 05                	je     f0104a2c <readline+0xb4>
f0104a27:	83 fb 0d             	cmp    $0xd,%ebx
f0104a2a:	75 81                	jne    f01049ad <readline+0x35>
			if (echoing)
f0104a2c:	85 ff                	test   %edi,%edi
f0104a2e:	74 0d                	je     f0104a3d <readline+0xc5>
				cputchar('\n');
f0104a30:	83 ec 0c             	sub    $0xc,%esp
f0104a33:	6a 0a                	push   $0xa
f0104a35:	e8 37 bd ff ff       	call   f0100771 <cputchar>
f0104a3a:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104a3d:	c6 86 00 ab 22 f0 00 	movb   $0x0,-0xfdd5500(%esi)
			return buf;
f0104a44:	b8 00 ab 22 f0       	mov    $0xf022ab00,%eax
		}
	}
}
f0104a49:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104a4c:	5b                   	pop    %ebx
f0104a4d:	5e                   	pop    %esi
f0104a4e:	5f                   	pop    %edi
f0104a4f:	5d                   	pop    %ebp
f0104a50:	c3                   	ret    

f0104a51 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104a51:	55                   	push   %ebp
f0104a52:	89 e5                	mov    %esp,%ebp
f0104a54:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104a57:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a5c:	eb 03                	jmp    f0104a61 <strlen+0x10>
		n++;
f0104a5e:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104a61:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104a65:	75 f7                	jne    f0104a5e <strlen+0xd>
		n++;
	return n;
}
f0104a67:	5d                   	pop    %ebp
f0104a68:	c3                   	ret    

f0104a69 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104a69:	55                   	push   %ebp
f0104a6a:	89 e5                	mov    %esp,%ebp
f0104a6c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104a6f:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104a72:	ba 00 00 00 00       	mov    $0x0,%edx
f0104a77:	eb 03                	jmp    f0104a7c <strnlen+0x13>
		n++;
f0104a79:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104a7c:	39 c2                	cmp    %eax,%edx
f0104a7e:	74 08                	je     f0104a88 <strnlen+0x1f>
f0104a80:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104a84:	75 f3                	jne    f0104a79 <strnlen+0x10>
f0104a86:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104a88:	5d                   	pop    %ebp
f0104a89:	c3                   	ret    

f0104a8a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104a8a:	55                   	push   %ebp
f0104a8b:	89 e5                	mov    %esp,%ebp
f0104a8d:	53                   	push   %ebx
f0104a8e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a91:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104a94:	89 c2                	mov    %eax,%edx
f0104a96:	83 c2 01             	add    $0x1,%edx
f0104a99:	83 c1 01             	add    $0x1,%ecx
f0104a9c:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104aa0:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104aa3:	84 db                	test   %bl,%bl
f0104aa5:	75 ef                	jne    f0104a96 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104aa7:	5b                   	pop    %ebx
f0104aa8:	5d                   	pop    %ebp
f0104aa9:	c3                   	ret    

f0104aaa <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104aaa:	55                   	push   %ebp
f0104aab:	89 e5                	mov    %esp,%ebp
f0104aad:	53                   	push   %ebx
f0104aae:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104ab1:	53                   	push   %ebx
f0104ab2:	e8 9a ff ff ff       	call   f0104a51 <strlen>
f0104ab7:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104aba:	ff 75 0c             	pushl  0xc(%ebp)
f0104abd:	01 d8                	add    %ebx,%eax
f0104abf:	50                   	push   %eax
f0104ac0:	e8 c5 ff ff ff       	call   f0104a8a <strcpy>
	return dst;
}
f0104ac5:	89 d8                	mov    %ebx,%eax
f0104ac7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104aca:	c9                   	leave  
f0104acb:	c3                   	ret    

f0104acc <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104acc:	55                   	push   %ebp
f0104acd:	89 e5                	mov    %esp,%ebp
f0104acf:	56                   	push   %esi
f0104ad0:	53                   	push   %ebx
f0104ad1:	8b 75 08             	mov    0x8(%ebp),%esi
f0104ad4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104ad7:	89 f3                	mov    %esi,%ebx
f0104ad9:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104adc:	89 f2                	mov    %esi,%edx
f0104ade:	eb 0f                	jmp    f0104aef <strncpy+0x23>
		*dst++ = *src;
f0104ae0:	83 c2 01             	add    $0x1,%edx
f0104ae3:	0f b6 01             	movzbl (%ecx),%eax
f0104ae6:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104ae9:	80 39 01             	cmpb   $0x1,(%ecx)
f0104aec:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104aef:	39 da                	cmp    %ebx,%edx
f0104af1:	75 ed                	jne    f0104ae0 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104af3:	89 f0                	mov    %esi,%eax
f0104af5:	5b                   	pop    %ebx
f0104af6:	5e                   	pop    %esi
f0104af7:	5d                   	pop    %ebp
f0104af8:	c3                   	ret    

f0104af9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104af9:	55                   	push   %ebp
f0104afa:	89 e5                	mov    %esp,%ebp
f0104afc:	56                   	push   %esi
f0104afd:	53                   	push   %ebx
f0104afe:	8b 75 08             	mov    0x8(%ebp),%esi
f0104b01:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104b04:	8b 55 10             	mov    0x10(%ebp),%edx
f0104b07:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104b09:	85 d2                	test   %edx,%edx
f0104b0b:	74 21                	je     f0104b2e <strlcpy+0x35>
f0104b0d:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104b11:	89 f2                	mov    %esi,%edx
f0104b13:	eb 09                	jmp    f0104b1e <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104b15:	83 c2 01             	add    $0x1,%edx
f0104b18:	83 c1 01             	add    $0x1,%ecx
f0104b1b:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104b1e:	39 c2                	cmp    %eax,%edx
f0104b20:	74 09                	je     f0104b2b <strlcpy+0x32>
f0104b22:	0f b6 19             	movzbl (%ecx),%ebx
f0104b25:	84 db                	test   %bl,%bl
f0104b27:	75 ec                	jne    f0104b15 <strlcpy+0x1c>
f0104b29:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104b2b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104b2e:	29 f0                	sub    %esi,%eax
}
f0104b30:	5b                   	pop    %ebx
f0104b31:	5e                   	pop    %esi
f0104b32:	5d                   	pop    %ebp
f0104b33:	c3                   	ret    

f0104b34 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104b34:	55                   	push   %ebp
f0104b35:	89 e5                	mov    %esp,%ebp
f0104b37:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104b3a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104b3d:	eb 06                	jmp    f0104b45 <strcmp+0x11>
		p++, q++;
f0104b3f:	83 c1 01             	add    $0x1,%ecx
f0104b42:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104b45:	0f b6 01             	movzbl (%ecx),%eax
f0104b48:	84 c0                	test   %al,%al
f0104b4a:	74 04                	je     f0104b50 <strcmp+0x1c>
f0104b4c:	3a 02                	cmp    (%edx),%al
f0104b4e:	74 ef                	je     f0104b3f <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104b50:	0f b6 c0             	movzbl %al,%eax
f0104b53:	0f b6 12             	movzbl (%edx),%edx
f0104b56:	29 d0                	sub    %edx,%eax
}
f0104b58:	5d                   	pop    %ebp
f0104b59:	c3                   	ret    

f0104b5a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104b5a:	55                   	push   %ebp
f0104b5b:	89 e5                	mov    %esp,%ebp
f0104b5d:	53                   	push   %ebx
f0104b5e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b61:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104b64:	89 c3                	mov    %eax,%ebx
f0104b66:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104b69:	eb 06                	jmp    f0104b71 <strncmp+0x17>
		n--, p++, q++;
f0104b6b:	83 c0 01             	add    $0x1,%eax
f0104b6e:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104b71:	39 d8                	cmp    %ebx,%eax
f0104b73:	74 15                	je     f0104b8a <strncmp+0x30>
f0104b75:	0f b6 08             	movzbl (%eax),%ecx
f0104b78:	84 c9                	test   %cl,%cl
f0104b7a:	74 04                	je     f0104b80 <strncmp+0x26>
f0104b7c:	3a 0a                	cmp    (%edx),%cl
f0104b7e:	74 eb                	je     f0104b6b <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104b80:	0f b6 00             	movzbl (%eax),%eax
f0104b83:	0f b6 12             	movzbl (%edx),%edx
f0104b86:	29 d0                	sub    %edx,%eax
f0104b88:	eb 05                	jmp    f0104b8f <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104b8a:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104b8f:	5b                   	pop    %ebx
f0104b90:	5d                   	pop    %ebp
f0104b91:	c3                   	ret    

f0104b92 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104b92:	55                   	push   %ebp
f0104b93:	89 e5                	mov    %esp,%ebp
f0104b95:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b98:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104b9c:	eb 07                	jmp    f0104ba5 <strchr+0x13>
		if (*s == c)
f0104b9e:	38 ca                	cmp    %cl,%dl
f0104ba0:	74 0f                	je     f0104bb1 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104ba2:	83 c0 01             	add    $0x1,%eax
f0104ba5:	0f b6 10             	movzbl (%eax),%edx
f0104ba8:	84 d2                	test   %dl,%dl
f0104baa:	75 f2                	jne    f0104b9e <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104bac:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104bb1:	5d                   	pop    %ebp
f0104bb2:	c3                   	ret    

f0104bb3 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104bb3:	55                   	push   %ebp
f0104bb4:	89 e5                	mov    %esp,%ebp
f0104bb6:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bb9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104bbd:	eb 03                	jmp    f0104bc2 <strfind+0xf>
f0104bbf:	83 c0 01             	add    $0x1,%eax
f0104bc2:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104bc5:	38 ca                	cmp    %cl,%dl
f0104bc7:	74 04                	je     f0104bcd <strfind+0x1a>
f0104bc9:	84 d2                	test   %dl,%dl
f0104bcb:	75 f2                	jne    f0104bbf <strfind+0xc>
			break;
	return (char *) s;
}
f0104bcd:	5d                   	pop    %ebp
f0104bce:	c3                   	ret    

f0104bcf <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104bcf:	55                   	push   %ebp
f0104bd0:	89 e5                	mov    %esp,%ebp
f0104bd2:	57                   	push   %edi
f0104bd3:	56                   	push   %esi
f0104bd4:	53                   	push   %ebx
f0104bd5:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104bd8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104bdb:	85 c9                	test   %ecx,%ecx
f0104bdd:	74 36                	je     f0104c15 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104bdf:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104be5:	75 28                	jne    f0104c0f <memset+0x40>
f0104be7:	f6 c1 03             	test   $0x3,%cl
f0104bea:	75 23                	jne    f0104c0f <memset+0x40>
		c &= 0xFF;
f0104bec:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104bf0:	89 d3                	mov    %edx,%ebx
f0104bf2:	c1 e3 08             	shl    $0x8,%ebx
f0104bf5:	89 d6                	mov    %edx,%esi
f0104bf7:	c1 e6 18             	shl    $0x18,%esi
f0104bfa:	89 d0                	mov    %edx,%eax
f0104bfc:	c1 e0 10             	shl    $0x10,%eax
f0104bff:	09 f0                	or     %esi,%eax
f0104c01:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0104c03:	89 d8                	mov    %ebx,%eax
f0104c05:	09 d0                	or     %edx,%eax
f0104c07:	c1 e9 02             	shr    $0x2,%ecx
f0104c0a:	fc                   	cld    
f0104c0b:	f3 ab                	rep stos %eax,%es:(%edi)
f0104c0d:	eb 06                	jmp    f0104c15 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104c0f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c12:	fc                   	cld    
f0104c13:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104c15:	89 f8                	mov    %edi,%eax
f0104c17:	5b                   	pop    %ebx
f0104c18:	5e                   	pop    %esi
f0104c19:	5f                   	pop    %edi
f0104c1a:	5d                   	pop    %ebp
f0104c1b:	c3                   	ret    

f0104c1c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104c1c:	55                   	push   %ebp
f0104c1d:	89 e5                	mov    %esp,%ebp
f0104c1f:	57                   	push   %edi
f0104c20:	56                   	push   %esi
f0104c21:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c24:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104c27:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104c2a:	39 c6                	cmp    %eax,%esi
f0104c2c:	73 35                	jae    f0104c63 <memmove+0x47>
f0104c2e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104c31:	39 d0                	cmp    %edx,%eax
f0104c33:	73 2e                	jae    f0104c63 <memmove+0x47>
		s += n;
		d += n;
f0104c35:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104c38:	89 d6                	mov    %edx,%esi
f0104c3a:	09 fe                	or     %edi,%esi
f0104c3c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104c42:	75 13                	jne    f0104c57 <memmove+0x3b>
f0104c44:	f6 c1 03             	test   $0x3,%cl
f0104c47:	75 0e                	jne    f0104c57 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104c49:	83 ef 04             	sub    $0x4,%edi
f0104c4c:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104c4f:	c1 e9 02             	shr    $0x2,%ecx
f0104c52:	fd                   	std    
f0104c53:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104c55:	eb 09                	jmp    f0104c60 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104c57:	83 ef 01             	sub    $0x1,%edi
f0104c5a:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104c5d:	fd                   	std    
f0104c5e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104c60:	fc                   	cld    
f0104c61:	eb 1d                	jmp    f0104c80 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104c63:	89 f2                	mov    %esi,%edx
f0104c65:	09 c2                	or     %eax,%edx
f0104c67:	f6 c2 03             	test   $0x3,%dl
f0104c6a:	75 0f                	jne    f0104c7b <memmove+0x5f>
f0104c6c:	f6 c1 03             	test   $0x3,%cl
f0104c6f:	75 0a                	jne    f0104c7b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0104c71:	c1 e9 02             	shr    $0x2,%ecx
f0104c74:	89 c7                	mov    %eax,%edi
f0104c76:	fc                   	cld    
f0104c77:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104c79:	eb 05                	jmp    f0104c80 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104c7b:	89 c7                	mov    %eax,%edi
f0104c7d:	fc                   	cld    
f0104c7e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104c80:	5e                   	pop    %esi
f0104c81:	5f                   	pop    %edi
f0104c82:	5d                   	pop    %ebp
f0104c83:	c3                   	ret    

f0104c84 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104c84:	55                   	push   %ebp
f0104c85:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104c87:	ff 75 10             	pushl  0x10(%ebp)
f0104c8a:	ff 75 0c             	pushl  0xc(%ebp)
f0104c8d:	ff 75 08             	pushl  0x8(%ebp)
f0104c90:	e8 87 ff ff ff       	call   f0104c1c <memmove>
}
f0104c95:	c9                   	leave  
f0104c96:	c3                   	ret    

f0104c97 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104c97:	55                   	push   %ebp
f0104c98:	89 e5                	mov    %esp,%ebp
f0104c9a:	56                   	push   %esi
f0104c9b:	53                   	push   %ebx
f0104c9c:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c9f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104ca2:	89 c6                	mov    %eax,%esi
f0104ca4:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104ca7:	eb 1a                	jmp    f0104cc3 <memcmp+0x2c>
		if (*s1 != *s2)
f0104ca9:	0f b6 08             	movzbl (%eax),%ecx
f0104cac:	0f b6 1a             	movzbl (%edx),%ebx
f0104caf:	38 d9                	cmp    %bl,%cl
f0104cb1:	74 0a                	je     f0104cbd <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104cb3:	0f b6 c1             	movzbl %cl,%eax
f0104cb6:	0f b6 db             	movzbl %bl,%ebx
f0104cb9:	29 d8                	sub    %ebx,%eax
f0104cbb:	eb 0f                	jmp    f0104ccc <memcmp+0x35>
		s1++, s2++;
f0104cbd:	83 c0 01             	add    $0x1,%eax
f0104cc0:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104cc3:	39 f0                	cmp    %esi,%eax
f0104cc5:	75 e2                	jne    f0104ca9 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104cc7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104ccc:	5b                   	pop    %ebx
f0104ccd:	5e                   	pop    %esi
f0104cce:	5d                   	pop    %ebp
f0104ccf:	c3                   	ret    

f0104cd0 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104cd0:	55                   	push   %ebp
f0104cd1:	89 e5                	mov    %esp,%ebp
f0104cd3:	53                   	push   %ebx
f0104cd4:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104cd7:	89 c1                	mov    %eax,%ecx
f0104cd9:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104cdc:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104ce0:	eb 0a                	jmp    f0104cec <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104ce2:	0f b6 10             	movzbl (%eax),%edx
f0104ce5:	39 da                	cmp    %ebx,%edx
f0104ce7:	74 07                	je     f0104cf0 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104ce9:	83 c0 01             	add    $0x1,%eax
f0104cec:	39 c8                	cmp    %ecx,%eax
f0104cee:	72 f2                	jb     f0104ce2 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104cf0:	5b                   	pop    %ebx
f0104cf1:	5d                   	pop    %ebp
f0104cf2:	c3                   	ret    

f0104cf3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104cf3:	55                   	push   %ebp
f0104cf4:	89 e5                	mov    %esp,%ebp
f0104cf6:	57                   	push   %edi
f0104cf7:	56                   	push   %esi
f0104cf8:	53                   	push   %ebx
f0104cf9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104cfc:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104cff:	eb 03                	jmp    f0104d04 <strtol+0x11>
		s++;
f0104d01:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104d04:	0f b6 01             	movzbl (%ecx),%eax
f0104d07:	3c 20                	cmp    $0x20,%al
f0104d09:	74 f6                	je     f0104d01 <strtol+0xe>
f0104d0b:	3c 09                	cmp    $0x9,%al
f0104d0d:	74 f2                	je     f0104d01 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104d0f:	3c 2b                	cmp    $0x2b,%al
f0104d11:	75 0a                	jne    f0104d1d <strtol+0x2a>
		s++;
f0104d13:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104d16:	bf 00 00 00 00       	mov    $0x0,%edi
f0104d1b:	eb 11                	jmp    f0104d2e <strtol+0x3b>
f0104d1d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104d22:	3c 2d                	cmp    $0x2d,%al
f0104d24:	75 08                	jne    f0104d2e <strtol+0x3b>
		s++, neg = 1;
f0104d26:	83 c1 01             	add    $0x1,%ecx
f0104d29:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104d2e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104d34:	75 15                	jne    f0104d4b <strtol+0x58>
f0104d36:	80 39 30             	cmpb   $0x30,(%ecx)
f0104d39:	75 10                	jne    f0104d4b <strtol+0x58>
f0104d3b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104d3f:	75 7c                	jne    f0104dbd <strtol+0xca>
		s += 2, base = 16;
f0104d41:	83 c1 02             	add    $0x2,%ecx
f0104d44:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104d49:	eb 16                	jmp    f0104d61 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104d4b:	85 db                	test   %ebx,%ebx
f0104d4d:	75 12                	jne    f0104d61 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104d4f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104d54:	80 39 30             	cmpb   $0x30,(%ecx)
f0104d57:	75 08                	jne    f0104d61 <strtol+0x6e>
		s++, base = 8;
f0104d59:	83 c1 01             	add    $0x1,%ecx
f0104d5c:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104d61:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d66:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104d69:	0f b6 11             	movzbl (%ecx),%edx
f0104d6c:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104d6f:	89 f3                	mov    %esi,%ebx
f0104d71:	80 fb 09             	cmp    $0x9,%bl
f0104d74:	77 08                	ja     f0104d7e <strtol+0x8b>
			dig = *s - '0';
f0104d76:	0f be d2             	movsbl %dl,%edx
f0104d79:	83 ea 30             	sub    $0x30,%edx
f0104d7c:	eb 22                	jmp    f0104da0 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104d7e:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104d81:	89 f3                	mov    %esi,%ebx
f0104d83:	80 fb 19             	cmp    $0x19,%bl
f0104d86:	77 08                	ja     f0104d90 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104d88:	0f be d2             	movsbl %dl,%edx
f0104d8b:	83 ea 57             	sub    $0x57,%edx
f0104d8e:	eb 10                	jmp    f0104da0 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104d90:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104d93:	89 f3                	mov    %esi,%ebx
f0104d95:	80 fb 19             	cmp    $0x19,%bl
f0104d98:	77 16                	ja     f0104db0 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104d9a:	0f be d2             	movsbl %dl,%edx
f0104d9d:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104da0:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104da3:	7d 0b                	jge    f0104db0 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104da5:	83 c1 01             	add    $0x1,%ecx
f0104da8:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104dac:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104dae:	eb b9                	jmp    f0104d69 <strtol+0x76>

	if (endptr)
f0104db0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104db4:	74 0d                	je     f0104dc3 <strtol+0xd0>
		*endptr = (char *) s;
f0104db6:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104db9:	89 0e                	mov    %ecx,(%esi)
f0104dbb:	eb 06                	jmp    f0104dc3 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104dbd:	85 db                	test   %ebx,%ebx
f0104dbf:	74 98                	je     f0104d59 <strtol+0x66>
f0104dc1:	eb 9e                	jmp    f0104d61 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104dc3:	89 c2                	mov    %eax,%edx
f0104dc5:	f7 da                	neg    %edx
f0104dc7:	85 ff                	test   %edi,%edi
f0104dc9:	0f 45 c2             	cmovne %edx,%eax
}
f0104dcc:	5b                   	pop    %ebx
f0104dcd:	5e                   	pop    %esi
f0104dce:	5f                   	pop    %edi
f0104dcf:	5d                   	pop    %ebp
f0104dd0:	c3                   	ret    
f0104dd1:	66 90                	xchg   %ax,%ax
f0104dd3:	90                   	nop

f0104dd4 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0104dd4:	fa                   	cli    

	xorw    %ax, %ax
f0104dd5:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0104dd7:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104dd9:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104ddb:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0104ddd:	0f 01 16             	lgdtl  (%esi)
f0104de0:	74 70                	je     f0104e52 <mpsearch1+0x3>
	movl    %cr0, %eax
f0104de2:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0104de5:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0104de9:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0104dec:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0104df2:	08 00                	or     %al,(%eax)

f0104df4 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0104df4:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0104df8:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104dfa:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104dfc:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0104dfe:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0104e02:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0104e04:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0104e06:	b8 00 d0 11 00       	mov    $0x11d000,%eax
	movl    %eax, %cr3
f0104e0b:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0104e0e:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0104e11:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0104e16:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0104e19:	8b 25 04 af 22 f0    	mov    0xf022af04,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0104e1f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0104e24:	b8 a7 01 10 f0       	mov    $0xf01001a7,%eax
	call    *%eax
f0104e29:	ff d0                	call   *%eax

f0104e2b <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0104e2b:	eb fe                	jmp    f0104e2b <spin>
f0104e2d:	8d 76 00             	lea    0x0(%esi),%esi

f0104e30 <gdt>:
	...
f0104e38:	ff                   	(bad)  
f0104e39:	ff 00                	incl   (%eax)
f0104e3b:	00 00                	add    %al,(%eax)
f0104e3d:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0104e44:	00                   	.byte 0x0
f0104e45:	92                   	xchg   %eax,%edx
f0104e46:	cf                   	iret   
	...

f0104e48 <gdtdesc>:
f0104e48:	17                   	pop    %ss
f0104e49:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0104e4e <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0104e4e:	90                   	nop

f0104e4f <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0104e4f:	55                   	push   %ebp
f0104e50:	89 e5                	mov    %esp,%ebp
f0104e52:	57                   	push   %edi
f0104e53:	56                   	push   %esi
f0104e54:	53                   	push   %ebx
f0104e55:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104e58:	8b 0d 08 af 22 f0    	mov    0xf022af08,%ecx
f0104e5e:	89 c3                	mov    %eax,%ebx
f0104e60:	c1 eb 0c             	shr    $0xc,%ebx
f0104e63:	39 cb                	cmp    %ecx,%ebx
f0104e65:	72 12                	jb     f0104e79 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104e67:	50                   	push   %eax
f0104e68:	68 a4 58 10 f0       	push   $0xf01058a4
f0104e6d:	6a 57                	push   $0x57
f0104e6f:	68 85 73 10 f0       	push   $0xf0107385
f0104e74:	e8 c7 b1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104e79:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0104e7f:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104e81:	89 c2                	mov    %eax,%edx
f0104e83:	c1 ea 0c             	shr    $0xc,%edx
f0104e86:	39 ca                	cmp    %ecx,%edx
f0104e88:	72 12                	jb     f0104e9c <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104e8a:	50                   	push   %eax
f0104e8b:	68 a4 58 10 f0       	push   $0xf01058a4
f0104e90:	6a 57                	push   $0x57
f0104e92:	68 85 73 10 f0       	push   $0xf0107385
f0104e97:	e8 a4 b1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104e9c:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0104ea2:	eb 2f                	jmp    f0104ed3 <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104ea4:	83 ec 04             	sub    $0x4,%esp
f0104ea7:	6a 04                	push   $0x4
f0104ea9:	68 95 73 10 f0       	push   $0xf0107395
f0104eae:	53                   	push   %ebx
f0104eaf:	e8 e3 fd ff ff       	call   f0104c97 <memcmp>
f0104eb4:	83 c4 10             	add    $0x10,%esp
f0104eb7:	85 c0                	test   %eax,%eax
f0104eb9:	75 15                	jne    f0104ed0 <mpsearch1+0x81>
f0104ebb:	89 da                	mov    %ebx,%edx
f0104ebd:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0104ec0:	0f b6 0a             	movzbl (%edx),%ecx
f0104ec3:	01 c8                	add    %ecx,%eax
f0104ec5:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0104ec8:	39 d7                	cmp    %edx,%edi
f0104eca:	75 f4                	jne    f0104ec0 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104ecc:	84 c0                	test   %al,%al
f0104ece:	74 0e                	je     f0104ede <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0104ed0:	83 c3 10             	add    $0x10,%ebx
f0104ed3:	39 f3                	cmp    %esi,%ebx
f0104ed5:	72 cd                	jb     f0104ea4 <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0104ed7:	b8 00 00 00 00       	mov    $0x0,%eax
f0104edc:	eb 02                	jmp    f0104ee0 <mpsearch1+0x91>
f0104ede:	89 d8                	mov    %ebx,%eax
}
f0104ee0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104ee3:	5b                   	pop    %ebx
f0104ee4:	5e                   	pop    %esi
f0104ee5:	5f                   	pop    %edi
f0104ee6:	5d                   	pop    %ebp
f0104ee7:	c3                   	ret    

f0104ee8 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0104ee8:	55                   	push   %ebp
f0104ee9:	89 e5                	mov    %esp,%ebp
f0104eeb:	57                   	push   %edi
f0104eec:	56                   	push   %esi
f0104eed:	53                   	push   %ebx
f0104eee:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0104ef1:	c7 05 c0 b3 22 f0 20 	movl   $0xf022b020,0xf022b3c0
f0104ef8:	b0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104efb:	83 3d 08 af 22 f0 00 	cmpl   $0x0,0xf022af08
f0104f02:	75 16                	jne    f0104f1a <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104f04:	68 00 04 00 00       	push   $0x400
f0104f09:	68 a4 58 10 f0       	push   $0xf01058a4
f0104f0e:	6a 6f                	push   $0x6f
f0104f10:	68 85 73 10 f0       	push   $0xf0107385
f0104f15:	e8 26 b1 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0104f1a:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0104f21:	85 c0                	test   %eax,%eax
f0104f23:	74 16                	je     f0104f3b <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
		if ((mp = mpsearch1(p, 1024)))
f0104f25:	c1 e0 04             	shl    $0x4,%eax
f0104f28:	ba 00 04 00 00       	mov    $0x400,%edx
f0104f2d:	e8 1d ff ff ff       	call   f0104e4f <mpsearch1>
f0104f32:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104f35:	85 c0                	test   %eax,%eax
f0104f37:	75 3c                	jne    f0104f75 <mp_init+0x8d>
f0104f39:	eb 20                	jmp    f0104f5b <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
		if ((mp = mpsearch1(p - 1024, 1024)))
f0104f3b:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0104f42:	c1 e0 0a             	shl    $0xa,%eax
f0104f45:	2d 00 04 00 00       	sub    $0x400,%eax
f0104f4a:	ba 00 04 00 00       	mov    $0x400,%edx
f0104f4f:	e8 fb fe ff ff       	call   f0104e4f <mpsearch1>
f0104f54:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104f57:	85 c0                	test   %eax,%eax
f0104f59:	75 1a                	jne    f0104f75 <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0104f5b:	ba 00 00 01 00       	mov    $0x10000,%edx
f0104f60:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0104f65:	e8 e5 fe ff ff       	call   f0104e4f <mpsearch1>
f0104f6a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0104f6d:	85 c0                	test   %eax,%eax
f0104f6f:	0f 84 5d 02 00 00    	je     f01051d2 <mp_init+0x2ea>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0104f75:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104f78:	8b 70 04             	mov    0x4(%eax),%esi
f0104f7b:	85 f6                	test   %esi,%esi
f0104f7d:	74 06                	je     f0104f85 <mp_init+0x9d>
f0104f7f:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0104f83:	74 15                	je     f0104f9a <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f0104f85:	83 ec 0c             	sub    $0xc,%esp
f0104f88:	68 f8 71 10 f0       	push   $0xf01071f8
f0104f8d:	e8 c1 e6 ff ff       	call   f0103653 <cprintf>
f0104f92:	83 c4 10             	add    $0x10,%esp
f0104f95:	e9 38 02 00 00       	jmp    f01051d2 <mp_init+0x2ea>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104f9a:	89 f0                	mov    %esi,%eax
f0104f9c:	c1 e8 0c             	shr    $0xc,%eax
f0104f9f:	3b 05 08 af 22 f0    	cmp    0xf022af08,%eax
f0104fa5:	72 15                	jb     f0104fbc <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104fa7:	56                   	push   %esi
f0104fa8:	68 a4 58 10 f0       	push   $0xf01058a4
f0104fad:	68 90 00 00 00       	push   $0x90
f0104fb2:	68 85 73 10 f0       	push   $0xf0107385
f0104fb7:	e8 84 b0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104fbc:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f0104fc2:	83 ec 04             	sub    $0x4,%esp
f0104fc5:	6a 04                	push   $0x4
f0104fc7:	68 9a 73 10 f0       	push   $0xf010739a
f0104fcc:	53                   	push   %ebx
f0104fcd:	e8 c5 fc ff ff       	call   f0104c97 <memcmp>
f0104fd2:	83 c4 10             	add    $0x10,%esp
f0104fd5:	85 c0                	test   %eax,%eax
f0104fd7:	74 15                	je     f0104fee <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0104fd9:	83 ec 0c             	sub    $0xc,%esp
f0104fdc:	68 28 72 10 f0       	push   $0xf0107228
f0104fe1:	e8 6d e6 ff ff       	call   f0103653 <cprintf>
f0104fe6:	83 c4 10             	add    $0x10,%esp
f0104fe9:	e9 e4 01 00 00       	jmp    f01051d2 <mp_init+0x2ea>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0104fee:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f0104ff2:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f0104ff6:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0104ff9:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0104ffe:	b8 00 00 00 00       	mov    $0x0,%eax
f0105003:	eb 0d                	jmp    f0105012 <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f0105005:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f010500c:	f0 
f010500d:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010500f:	83 c0 01             	add    $0x1,%eax
f0105012:	39 c7                	cmp    %eax,%edi
f0105014:	75 ef                	jne    f0105005 <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105016:	84 d2                	test   %dl,%dl
f0105018:	74 15                	je     f010502f <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f010501a:	83 ec 0c             	sub    $0xc,%esp
f010501d:	68 5c 72 10 f0       	push   $0xf010725c
f0105022:	e8 2c e6 ff ff       	call   f0103653 <cprintf>
f0105027:	83 c4 10             	add    $0x10,%esp
f010502a:	e9 a3 01 00 00       	jmp    f01051d2 <mp_init+0x2ea>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f010502f:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105033:	3c 01                	cmp    $0x1,%al
f0105035:	74 1d                	je     f0105054 <mp_init+0x16c>
f0105037:	3c 04                	cmp    $0x4,%al
f0105039:	74 19                	je     f0105054 <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f010503b:	83 ec 08             	sub    $0x8,%esp
f010503e:	0f b6 c0             	movzbl %al,%eax
f0105041:	50                   	push   %eax
f0105042:	68 80 72 10 f0       	push   $0xf0107280
f0105047:	e8 07 e6 ff ff       	call   f0103653 <cprintf>
f010504c:	83 c4 10             	add    $0x10,%esp
f010504f:	e9 7e 01 00 00       	jmp    f01051d2 <mp_init+0x2ea>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105054:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f0105058:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f010505c:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105061:	b8 00 00 00 00       	mov    $0x0,%eax
		sum += ((uint8_t *)addr)[i];
f0105066:	01 ce                	add    %ecx,%esi
f0105068:	eb 0d                	jmp    f0105077 <mp_init+0x18f>
f010506a:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f0105071:	f0 
f0105072:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105074:	83 c0 01             	add    $0x1,%eax
f0105077:	39 c7                	cmp    %eax,%edi
f0105079:	75 ef                	jne    f010506a <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010507b:	89 d0                	mov    %edx,%eax
f010507d:	02 43 2a             	add    0x2a(%ebx),%al
f0105080:	74 15                	je     f0105097 <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105082:	83 ec 0c             	sub    $0xc,%esp
f0105085:	68 a0 72 10 f0       	push   $0xf01072a0
f010508a:	e8 c4 e5 ff ff       	call   f0103653 <cprintf>
f010508f:	83 c4 10             	add    $0x10,%esp
f0105092:	e9 3b 01 00 00       	jmp    f01051d2 <mp_init+0x2ea>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f0105097:	85 db                	test   %ebx,%ebx
f0105099:	0f 84 33 01 00 00    	je     f01051d2 <mp_init+0x2ea>
		return;
	ismp = 1;
f010509f:	c7 05 00 b0 22 f0 01 	movl   $0x1,0xf022b000
f01050a6:	00 00 00 
	lapicaddr = conf->lapicaddr;
f01050a9:	8b 43 24             	mov    0x24(%ebx),%eax
f01050ac:	a3 00 c0 26 f0       	mov    %eax,0xf026c000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01050b1:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f01050b4:	be 00 00 00 00       	mov    $0x0,%esi
f01050b9:	e9 85 00 00 00       	jmp    f0105143 <mp_init+0x25b>
		switch (*p) {
f01050be:	0f b6 07             	movzbl (%edi),%eax
f01050c1:	84 c0                	test   %al,%al
f01050c3:	74 06                	je     f01050cb <mp_init+0x1e3>
f01050c5:	3c 04                	cmp    $0x4,%al
f01050c7:	77 55                	ja     f010511e <mp_init+0x236>
f01050c9:	eb 4e                	jmp    f0105119 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01050cb:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01050cf:	74 11                	je     f01050e2 <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f01050d1:	6b 05 c4 b3 22 f0 74 	imul   $0x74,0xf022b3c4,%eax
f01050d8:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01050dd:	a3 c0 b3 22 f0       	mov    %eax,0xf022b3c0
			if (ncpu < NCPU) {
f01050e2:	a1 c4 b3 22 f0       	mov    0xf022b3c4,%eax
f01050e7:	83 f8 07             	cmp    $0x7,%eax
f01050ea:	7f 13                	jg     f01050ff <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f01050ec:	6b d0 74             	imul   $0x74,%eax,%edx
f01050ef:	88 82 20 b0 22 f0    	mov    %al,-0xfdd4fe0(%edx)
				ncpu++;
f01050f5:	83 c0 01             	add    $0x1,%eax
f01050f8:	a3 c4 b3 22 f0       	mov    %eax,0xf022b3c4
f01050fd:	eb 15                	jmp    f0105114 <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01050ff:	83 ec 08             	sub    $0x8,%esp
f0105102:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0105106:	50                   	push   %eax
f0105107:	68 d0 72 10 f0       	push   $0xf01072d0
f010510c:	e8 42 e5 ff ff       	call   f0103653 <cprintf>
f0105111:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105114:	83 c7 14             	add    $0x14,%edi
			continue;
f0105117:	eb 27                	jmp    f0105140 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105119:	83 c7 08             	add    $0x8,%edi
			continue;
f010511c:	eb 22                	jmp    f0105140 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f010511e:	83 ec 08             	sub    $0x8,%esp
f0105121:	0f b6 c0             	movzbl %al,%eax
f0105124:	50                   	push   %eax
f0105125:	68 f8 72 10 f0       	push   $0xf01072f8
f010512a:	e8 24 e5 ff ff       	call   f0103653 <cprintf>
			ismp = 0;
f010512f:	c7 05 00 b0 22 f0 00 	movl   $0x0,0xf022b000
f0105136:	00 00 00 
			i = conf->entry;
f0105139:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f010513d:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105140:	83 c6 01             	add    $0x1,%esi
f0105143:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0105147:	39 c6                	cmp    %eax,%esi
f0105149:	0f 82 6f ff ff ff    	jb     f01050be <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f010514f:	a1 c0 b3 22 f0       	mov    0xf022b3c0,%eax
f0105154:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f010515b:	83 3d 00 b0 22 f0 00 	cmpl   $0x0,0xf022b000
f0105162:	75 26                	jne    f010518a <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105164:	c7 05 c4 b3 22 f0 01 	movl   $0x1,0xf022b3c4
f010516b:	00 00 00 
		lapicaddr = 0;
f010516e:	c7 05 00 c0 26 f0 00 	movl   $0x0,0xf026c000
f0105175:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105178:	83 ec 0c             	sub    $0xc,%esp
f010517b:	68 18 73 10 f0       	push   $0xf0107318
f0105180:	e8 ce e4 ff ff       	call   f0103653 <cprintf>
		return;
f0105185:	83 c4 10             	add    $0x10,%esp
f0105188:	eb 48                	jmp    f01051d2 <mp_init+0x2ea>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f010518a:	83 ec 04             	sub    $0x4,%esp
f010518d:	ff 35 c4 b3 22 f0    	pushl  0xf022b3c4
f0105193:	0f b6 00             	movzbl (%eax),%eax
f0105196:	50                   	push   %eax
f0105197:	68 9f 73 10 f0       	push   $0xf010739f
f010519c:	e8 b2 e4 ff ff       	call   f0103653 <cprintf>

	if (mp->imcrp) {
f01051a1:	83 c4 10             	add    $0x10,%esp
f01051a4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01051a7:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f01051ab:	74 25                	je     f01051d2 <mp_init+0x2ea>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f01051ad:	83 ec 0c             	sub    $0xc,%esp
f01051b0:	68 44 73 10 f0       	push   $0xf0107344
f01051b5:	e8 99 e4 ff ff       	call   f0103653 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01051ba:	ba 22 00 00 00       	mov    $0x22,%edx
f01051bf:	b8 70 00 00 00       	mov    $0x70,%eax
f01051c4:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01051c5:	ba 23 00 00 00       	mov    $0x23,%edx
f01051ca:	ec                   	in     (%dx),%al
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01051cb:	83 c8 01             	or     $0x1,%eax
f01051ce:	ee                   	out    %al,(%dx)
f01051cf:	83 c4 10             	add    $0x10,%esp
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f01051d2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01051d5:	5b                   	pop    %ebx
f01051d6:	5e                   	pop    %esi
f01051d7:	5f                   	pop    %edi
f01051d8:	5d                   	pop    %ebp
f01051d9:	c3                   	ret    

f01051da <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01051da:	55                   	push   %ebp
f01051db:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01051dd:	8b 0d 04 c0 26 f0    	mov    0xf026c004,%ecx
f01051e3:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01051e6:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01051e8:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f01051ed:	8b 40 20             	mov    0x20(%eax),%eax
}
f01051f0:	5d                   	pop    %ebp
f01051f1:	c3                   	ret    

f01051f2 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01051f2:	55                   	push   %ebp
f01051f3:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01051f5:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f01051fa:	85 c0                	test   %eax,%eax
f01051fc:	74 08                	je     f0105206 <cpunum+0x14>
		return lapic[ID] >> 24;
f01051fe:	8b 40 20             	mov    0x20(%eax),%eax
f0105201:	c1 e8 18             	shr    $0x18,%eax
f0105204:	eb 05                	jmp    f010520b <cpunum+0x19>
	return 0;
f0105206:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010520b:	5d                   	pop    %ebp
f010520c:	c3                   	ret    

f010520d <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f010520d:	a1 00 c0 26 f0       	mov    0xf026c000,%eax
f0105212:	85 c0                	test   %eax,%eax
f0105214:	0f 84 21 01 00 00    	je     f010533b <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f010521a:	55                   	push   %ebp
f010521b:	89 e5                	mov    %esp,%ebp
f010521d:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105220:	68 00 10 00 00       	push   $0x1000
f0105225:	50                   	push   %eax
f0105226:	e8 de bf ff ff       	call   f0101209 <mmio_map_region>
f010522b:	a3 04 c0 26 f0       	mov    %eax,0xf026c004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105230:	ba 27 01 00 00       	mov    $0x127,%edx
f0105235:	b8 3c 00 00 00       	mov    $0x3c,%eax
f010523a:	e8 9b ff ff ff       	call   f01051da <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f010523f:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105244:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105249:	e8 8c ff ff ff       	call   f01051da <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f010524e:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105253:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105258:	e8 7d ff ff ff       	call   f01051da <lapicw>
	lapicw(TICR, 10000000); 
f010525d:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105262:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105267:	e8 6e ff ff ff       	call   f01051da <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f010526c:	e8 81 ff ff ff       	call   f01051f2 <cpunum>
f0105271:	6b c0 74             	imul   $0x74,%eax,%eax
f0105274:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f0105279:	83 c4 10             	add    $0x10,%esp
f010527c:	39 05 c0 b3 22 f0    	cmp    %eax,0xf022b3c0
f0105282:	74 0f                	je     f0105293 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105284:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105289:	b8 d4 00 00 00       	mov    $0xd4,%eax
f010528e:	e8 47 ff ff ff       	call   f01051da <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105293:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105298:	b8 d8 00 00 00       	mov    $0xd8,%eax
f010529d:	e8 38 ff ff ff       	call   f01051da <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f01052a2:	a1 04 c0 26 f0       	mov    0xf026c004,%eax
f01052a7:	8b 40 30             	mov    0x30(%eax),%eax
f01052aa:	c1 e8 10             	shr    $0x10,%eax
f01052ad:	3c 03                	cmp    $0x3,%al
f01052af:	76 0f                	jbe    f01052c0 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f01052b1:	ba 00 00 01 00       	mov    $0x10000,%edx
f01052b6:	b8 d0 00 00 00       	mov    $0xd0,%eax
f01052bb:	e8 1a ff ff ff       	call   f01051da <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f01052c0:	ba 33 00 00 00       	mov    $0x33,%edx
f01052c5:	b8 dc 00 00 00       	mov    $0xdc,%eax
f01052ca:	e8 0b ff ff ff       	call   f01051da <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f01052cf:	ba 00 00 00 00       	mov    $0x0,%edx
f01052d4:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01052d9:	e8 fc fe ff ff       	call   f01051da <lapicw>
	lapicw(ESR, 0);
f01052de:	ba 00 00 00 00       	mov    $0x0,%edx
f01052e3:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01052e8:	e8 ed fe ff ff       	call   f01051da <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f01052ed:	ba 00 00 00 00       	mov    $0x0,%edx
f01052f2:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01052f7:	e8 de fe ff ff       	call   f01051da <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f01052fc:	ba 00 00 00 00       	mov    $0x0,%edx
f0105301:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105306:	e8 cf fe ff ff       	call   f01051da <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f010530b:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105310:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105315:	e8 c0 fe ff ff       	call   f01051da <lapicw>
	while(lapic[ICRLO] & DELIVS)
f010531a:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f0105320:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105326:	f6 c4 10             	test   $0x10,%ah
f0105329:	75 f5                	jne    f0105320 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f010532b:	ba 00 00 00 00       	mov    $0x0,%edx
f0105330:	b8 20 00 00 00       	mov    $0x20,%eax
f0105335:	e8 a0 fe ff ff       	call   f01051da <lapicw>
}
f010533a:	c9                   	leave  
f010533b:	f3 c3                	repz ret 

f010533d <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f010533d:	83 3d 04 c0 26 f0 00 	cmpl   $0x0,0xf026c004
f0105344:	74 13                	je     f0105359 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105346:	55                   	push   %ebp
f0105347:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105349:	ba 00 00 00 00       	mov    $0x0,%edx
f010534e:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105353:	e8 82 fe ff ff       	call   f01051da <lapicw>
}
f0105358:	5d                   	pop    %ebp
f0105359:	f3 c3                	repz ret 

f010535b <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f010535b:	55                   	push   %ebp
f010535c:	89 e5                	mov    %esp,%ebp
f010535e:	56                   	push   %esi
f010535f:	53                   	push   %ebx
f0105360:	8b 75 08             	mov    0x8(%ebp),%esi
f0105363:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105366:	ba 70 00 00 00       	mov    $0x70,%edx
f010536b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105370:	ee                   	out    %al,(%dx)
f0105371:	ba 71 00 00 00       	mov    $0x71,%edx
f0105376:	b8 0a 00 00 00       	mov    $0xa,%eax
f010537b:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010537c:	83 3d 08 af 22 f0 00 	cmpl   $0x0,0xf022af08
f0105383:	75 19                	jne    f010539e <lapic_startap+0x43>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105385:	68 67 04 00 00       	push   $0x467
f010538a:	68 a4 58 10 f0       	push   $0xf01058a4
f010538f:	68 98 00 00 00       	push   $0x98
f0105394:	68 bc 73 10 f0       	push   $0xf01073bc
f0105399:	e8 a2 ac ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f010539e:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f01053a5:	00 00 
	wrv[1] = addr >> 4;
f01053a7:	89 d8                	mov    %ebx,%eax
f01053a9:	c1 e8 04             	shr    $0x4,%eax
f01053ac:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f01053b2:	c1 e6 18             	shl    $0x18,%esi
f01053b5:	89 f2                	mov    %esi,%edx
f01053b7:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01053bc:	e8 19 fe ff ff       	call   f01051da <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f01053c1:	ba 00 c5 00 00       	mov    $0xc500,%edx
f01053c6:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01053cb:	e8 0a fe ff ff       	call   f01051da <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f01053d0:	ba 00 85 00 00       	mov    $0x8500,%edx
f01053d5:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01053da:	e8 fb fd ff ff       	call   f01051da <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01053df:	c1 eb 0c             	shr    $0xc,%ebx
f01053e2:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01053e5:	89 f2                	mov    %esi,%edx
f01053e7:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01053ec:	e8 e9 fd ff ff       	call   f01051da <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01053f1:	89 da                	mov    %ebx,%edx
f01053f3:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01053f8:	e8 dd fd ff ff       	call   f01051da <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01053fd:	89 f2                	mov    %esi,%edx
f01053ff:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105404:	e8 d1 fd ff ff       	call   f01051da <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105409:	89 da                	mov    %ebx,%edx
f010540b:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105410:	e8 c5 fd ff ff       	call   f01051da <lapicw>
		microdelay(200);
	}
}
f0105415:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105418:	5b                   	pop    %ebx
f0105419:	5e                   	pop    %esi
f010541a:	5d                   	pop    %ebp
f010541b:	c3                   	ret    

f010541c <lapic_ipi>:

void
lapic_ipi(int vector)
{
f010541c:	55                   	push   %ebp
f010541d:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f010541f:	8b 55 08             	mov    0x8(%ebp),%edx
f0105422:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105428:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010542d:	e8 a8 fd ff ff       	call   f01051da <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105432:	8b 15 04 c0 26 f0    	mov    0xf026c004,%edx
f0105438:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010543e:	f6 c4 10             	test   $0x10,%ah
f0105441:	75 f5                	jne    f0105438 <lapic_ipi+0x1c>
		;
}
f0105443:	5d                   	pop    %ebp
f0105444:	c3                   	ret    

f0105445 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105445:	55                   	push   %ebp
f0105446:	89 e5                	mov    %esp,%ebp
f0105448:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f010544b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105451:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105454:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105457:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f010545e:	5d                   	pop    %ebp
f010545f:	c3                   	ret    

f0105460 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105460:	55                   	push   %ebp
f0105461:	89 e5                	mov    %esp,%ebp
f0105463:	56                   	push   %esi
f0105464:	53                   	push   %ebx
f0105465:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105468:	83 3b 00             	cmpl   $0x0,(%ebx)
f010546b:	74 14                	je     f0105481 <spin_lock+0x21>
f010546d:	8b 73 08             	mov    0x8(%ebx),%esi
f0105470:	e8 7d fd ff ff       	call   f01051f2 <cpunum>
f0105475:	6b c0 74             	imul   $0x74,%eax,%eax
f0105478:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f010547d:	39 c6                	cmp    %eax,%esi
f010547f:	74 07                	je     f0105488 <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0105481:	ba 01 00 00 00       	mov    $0x1,%edx
f0105486:	eb 20                	jmp    f01054a8 <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105488:	8b 5b 04             	mov    0x4(%ebx),%ebx
f010548b:	e8 62 fd ff ff       	call   f01051f2 <cpunum>
f0105490:	83 ec 0c             	sub    $0xc,%esp
f0105493:	53                   	push   %ebx
f0105494:	50                   	push   %eax
f0105495:	68 cc 73 10 f0       	push   $0xf01073cc
f010549a:	6a 41                	push   $0x41
f010549c:	68 30 74 10 f0       	push   $0xf0107430
f01054a1:	e8 9a ab ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f01054a6:	f3 90                	pause  
f01054a8:	89 d0                	mov    %edx,%eax
f01054aa:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f01054ad:	85 c0                	test   %eax,%eax
f01054af:	75 f5                	jne    f01054a6 <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f01054b1:	e8 3c fd ff ff       	call   f01051f2 <cpunum>
f01054b6:	6b c0 74             	imul   $0x74,%eax,%eax
f01054b9:	05 20 b0 22 f0       	add    $0xf022b020,%eax
f01054be:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f01054c1:	83 c3 0c             	add    $0xc,%ebx

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01054c4:	89 ea                	mov    %ebp,%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01054c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01054cb:	eb 0b                	jmp    f01054d8 <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f01054cd:	8b 4a 04             	mov    0x4(%edx),%ecx
f01054d0:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f01054d3:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01054d5:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f01054d8:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f01054de:	76 11                	jbe    f01054f1 <spin_lock+0x91>
f01054e0:	83 f8 09             	cmp    $0x9,%eax
f01054e3:	7e e8                	jle    f01054cd <spin_lock+0x6d>
f01054e5:	eb 0a                	jmp    f01054f1 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f01054e7:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f01054ee:	83 c0 01             	add    $0x1,%eax
f01054f1:	83 f8 09             	cmp    $0x9,%eax
f01054f4:	7e f1                	jle    f01054e7 <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f01054f6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01054f9:	5b                   	pop    %ebx
f01054fa:	5e                   	pop    %esi
f01054fb:	5d                   	pop    %ebp
f01054fc:	c3                   	ret    

f01054fd <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f01054fd:	55                   	push   %ebp
f01054fe:	89 e5                	mov    %esp,%ebp
f0105500:	57                   	push   %edi
f0105501:	56                   	push   %esi
f0105502:	53                   	push   %ebx
f0105503:	83 ec 4c             	sub    $0x4c,%esp
f0105506:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105509:	83 3e 00             	cmpl   $0x0,(%esi)
f010550c:	74 18                	je     f0105526 <spin_unlock+0x29>
f010550e:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105511:	e8 dc fc ff ff       	call   f01051f2 <cpunum>
f0105516:	6b c0 74             	imul   $0x74,%eax,%eax
f0105519:	05 20 b0 22 f0       	add    $0xf022b020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f010551e:	39 c3                	cmp    %eax,%ebx
f0105520:	0f 84 a5 00 00 00    	je     f01055cb <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105526:	83 ec 04             	sub    $0x4,%esp
f0105529:	6a 28                	push   $0x28
f010552b:	8d 46 0c             	lea    0xc(%esi),%eax
f010552e:	50                   	push   %eax
f010552f:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105532:	53                   	push   %ebx
f0105533:	e8 e4 f6 ff ff       	call   f0104c1c <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105538:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f010553b:	0f b6 38             	movzbl (%eax),%edi
f010553e:	8b 76 04             	mov    0x4(%esi),%esi
f0105541:	e8 ac fc ff ff       	call   f01051f2 <cpunum>
f0105546:	57                   	push   %edi
f0105547:	56                   	push   %esi
f0105548:	50                   	push   %eax
f0105549:	68 f8 73 10 f0       	push   $0xf01073f8
f010554e:	e8 00 e1 ff ff       	call   f0103653 <cprintf>
f0105553:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105556:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105559:	eb 54                	jmp    f01055af <spin_unlock+0xb2>
f010555b:	83 ec 08             	sub    $0x8,%esp
f010555e:	57                   	push   %edi
f010555f:	50                   	push   %eax
f0105560:	e8 35 ec ff ff       	call   f010419a <debuginfo_eip>
f0105565:	83 c4 10             	add    $0x10,%esp
f0105568:	85 c0                	test   %eax,%eax
f010556a:	78 27                	js     f0105593 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f010556c:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f010556e:	83 ec 04             	sub    $0x4,%esp
f0105571:	89 c2                	mov    %eax,%edx
f0105573:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105576:	52                   	push   %edx
f0105577:	ff 75 b0             	pushl  -0x50(%ebp)
f010557a:	ff 75 b4             	pushl  -0x4c(%ebp)
f010557d:	ff 75 ac             	pushl  -0x54(%ebp)
f0105580:	ff 75 a8             	pushl  -0x58(%ebp)
f0105583:	50                   	push   %eax
f0105584:	68 40 74 10 f0       	push   $0xf0107440
f0105589:	e8 c5 e0 ff ff       	call   f0103653 <cprintf>
f010558e:	83 c4 20             	add    $0x20,%esp
f0105591:	eb 12                	jmp    f01055a5 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105593:	83 ec 08             	sub    $0x8,%esp
f0105596:	ff 36                	pushl  (%esi)
f0105598:	68 57 74 10 f0       	push   $0xf0107457
f010559d:	e8 b1 e0 ff ff       	call   f0103653 <cprintf>
f01055a2:	83 c4 10             	add    $0x10,%esp
f01055a5:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f01055a8:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01055ab:	39 c3                	cmp    %eax,%ebx
f01055ad:	74 08                	je     f01055b7 <spin_unlock+0xba>
f01055af:	89 de                	mov    %ebx,%esi
f01055b1:	8b 03                	mov    (%ebx),%eax
f01055b3:	85 c0                	test   %eax,%eax
f01055b5:	75 a4                	jne    f010555b <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f01055b7:	83 ec 04             	sub    $0x4,%esp
f01055ba:	68 5f 74 10 f0       	push   $0xf010745f
f01055bf:	6a 67                	push   $0x67
f01055c1:	68 30 74 10 f0       	push   $0xf0107430
f01055c6:	e8 75 aa ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f01055cb:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f01055d2:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f01055d9:	b8 00 00 00 00       	mov    $0x0,%eax
f01055de:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f01055e1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01055e4:	5b                   	pop    %ebx
f01055e5:	5e                   	pop    %esi
f01055e6:	5f                   	pop    %edi
f01055e7:	5d                   	pop    %ebp
f01055e8:	c3                   	ret    
f01055e9:	66 90                	xchg   %ax,%ax
f01055eb:	66 90                	xchg   %ax,%ax
f01055ed:	66 90                	xchg   %ax,%ax
f01055ef:	90                   	nop

f01055f0 <__udivdi3>:
f01055f0:	55                   	push   %ebp
f01055f1:	57                   	push   %edi
f01055f2:	56                   	push   %esi
f01055f3:	53                   	push   %ebx
f01055f4:	83 ec 1c             	sub    $0x1c,%esp
f01055f7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01055fb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01055ff:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0105603:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105607:	85 f6                	test   %esi,%esi
f0105609:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010560d:	89 ca                	mov    %ecx,%edx
f010560f:	89 f8                	mov    %edi,%eax
f0105611:	75 3d                	jne    f0105650 <__udivdi3+0x60>
f0105613:	39 cf                	cmp    %ecx,%edi
f0105615:	0f 87 c5 00 00 00    	ja     f01056e0 <__udivdi3+0xf0>
f010561b:	85 ff                	test   %edi,%edi
f010561d:	89 fd                	mov    %edi,%ebp
f010561f:	75 0b                	jne    f010562c <__udivdi3+0x3c>
f0105621:	b8 01 00 00 00       	mov    $0x1,%eax
f0105626:	31 d2                	xor    %edx,%edx
f0105628:	f7 f7                	div    %edi
f010562a:	89 c5                	mov    %eax,%ebp
f010562c:	89 c8                	mov    %ecx,%eax
f010562e:	31 d2                	xor    %edx,%edx
f0105630:	f7 f5                	div    %ebp
f0105632:	89 c1                	mov    %eax,%ecx
f0105634:	89 d8                	mov    %ebx,%eax
f0105636:	89 cf                	mov    %ecx,%edi
f0105638:	f7 f5                	div    %ebp
f010563a:	89 c3                	mov    %eax,%ebx
f010563c:	89 d8                	mov    %ebx,%eax
f010563e:	89 fa                	mov    %edi,%edx
f0105640:	83 c4 1c             	add    $0x1c,%esp
f0105643:	5b                   	pop    %ebx
f0105644:	5e                   	pop    %esi
f0105645:	5f                   	pop    %edi
f0105646:	5d                   	pop    %ebp
f0105647:	c3                   	ret    
f0105648:	90                   	nop
f0105649:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105650:	39 ce                	cmp    %ecx,%esi
f0105652:	77 74                	ja     f01056c8 <__udivdi3+0xd8>
f0105654:	0f bd fe             	bsr    %esi,%edi
f0105657:	83 f7 1f             	xor    $0x1f,%edi
f010565a:	0f 84 98 00 00 00    	je     f01056f8 <__udivdi3+0x108>
f0105660:	bb 20 00 00 00       	mov    $0x20,%ebx
f0105665:	89 f9                	mov    %edi,%ecx
f0105667:	89 c5                	mov    %eax,%ebp
f0105669:	29 fb                	sub    %edi,%ebx
f010566b:	d3 e6                	shl    %cl,%esi
f010566d:	89 d9                	mov    %ebx,%ecx
f010566f:	d3 ed                	shr    %cl,%ebp
f0105671:	89 f9                	mov    %edi,%ecx
f0105673:	d3 e0                	shl    %cl,%eax
f0105675:	09 ee                	or     %ebp,%esi
f0105677:	89 d9                	mov    %ebx,%ecx
f0105679:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010567d:	89 d5                	mov    %edx,%ebp
f010567f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105683:	d3 ed                	shr    %cl,%ebp
f0105685:	89 f9                	mov    %edi,%ecx
f0105687:	d3 e2                	shl    %cl,%edx
f0105689:	89 d9                	mov    %ebx,%ecx
f010568b:	d3 e8                	shr    %cl,%eax
f010568d:	09 c2                	or     %eax,%edx
f010568f:	89 d0                	mov    %edx,%eax
f0105691:	89 ea                	mov    %ebp,%edx
f0105693:	f7 f6                	div    %esi
f0105695:	89 d5                	mov    %edx,%ebp
f0105697:	89 c3                	mov    %eax,%ebx
f0105699:	f7 64 24 0c          	mull   0xc(%esp)
f010569d:	39 d5                	cmp    %edx,%ebp
f010569f:	72 10                	jb     f01056b1 <__udivdi3+0xc1>
f01056a1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01056a5:	89 f9                	mov    %edi,%ecx
f01056a7:	d3 e6                	shl    %cl,%esi
f01056a9:	39 c6                	cmp    %eax,%esi
f01056ab:	73 07                	jae    f01056b4 <__udivdi3+0xc4>
f01056ad:	39 d5                	cmp    %edx,%ebp
f01056af:	75 03                	jne    f01056b4 <__udivdi3+0xc4>
f01056b1:	83 eb 01             	sub    $0x1,%ebx
f01056b4:	31 ff                	xor    %edi,%edi
f01056b6:	89 d8                	mov    %ebx,%eax
f01056b8:	89 fa                	mov    %edi,%edx
f01056ba:	83 c4 1c             	add    $0x1c,%esp
f01056bd:	5b                   	pop    %ebx
f01056be:	5e                   	pop    %esi
f01056bf:	5f                   	pop    %edi
f01056c0:	5d                   	pop    %ebp
f01056c1:	c3                   	ret    
f01056c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01056c8:	31 ff                	xor    %edi,%edi
f01056ca:	31 db                	xor    %ebx,%ebx
f01056cc:	89 d8                	mov    %ebx,%eax
f01056ce:	89 fa                	mov    %edi,%edx
f01056d0:	83 c4 1c             	add    $0x1c,%esp
f01056d3:	5b                   	pop    %ebx
f01056d4:	5e                   	pop    %esi
f01056d5:	5f                   	pop    %edi
f01056d6:	5d                   	pop    %ebp
f01056d7:	c3                   	ret    
f01056d8:	90                   	nop
f01056d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01056e0:	89 d8                	mov    %ebx,%eax
f01056e2:	f7 f7                	div    %edi
f01056e4:	31 ff                	xor    %edi,%edi
f01056e6:	89 c3                	mov    %eax,%ebx
f01056e8:	89 d8                	mov    %ebx,%eax
f01056ea:	89 fa                	mov    %edi,%edx
f01056ec:	83 c4 1c             	add    $0x1c,%esp
f01056ef:	5b                   	pop    %ebx
f01056f0:	5e                   	pop    %esi
f01056f1:	5f                   	pop    %edi
f01056f2:	5d                   	pop    %ebp
f01056f3:	c3                   	ret    
f01056f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01056f8:	39 ce                	cmp    %ecx,%esi
f01056fa:	72 0c                	jb     f0105708 <__udivdi3+0x118>
f01056fc:	31 db                	xor    %ebx,%ebx
f01056fe:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0105702:	0f 87 34 ff ff ff    	ja     f010563c <__udivdi3+0x4c>
f0105708:	bb 01 00 00 00       	mov    $0x1,%ebx
f010570d:	e9 2a ff ff ff       	jmp    f010563c <__udivdi3+0x4c>
f0105712:	66 90                	xchg   %ax,%ax
f0105714:	66 90                	xchg   %ax,%ax
f0105716:	66 90                	xchg   %ax,%ax
f0105718:	66 90                	xchg   %ax,%ax
f010571a:	66 90                	xchg   %ax,%ax
f010571c:	66 90                	xchg   %ax,%ax
f010571e:	66 90                	xchg   %ax,%ax

f0105720 <__umoddi3>:
f0105720:	55                   	push   %ebp
f0105721:	57                   	push   %edi
f0105722:	56                   	push   %esi
f0105723:	53                   	push   %ebx
f0105724:	83 ec 1c             	sub    $0x1c,%esp
f0105727:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010572b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010572f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105733:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105737:	85 d2                	test   %edx,%edx
f0105739:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010573d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105741:	89 f3                	mov    %esi,%ebx
f0105743:	89 3c 24             	mov    %edi,(%esp)
f0105746:	89 74 24 04          	mov    %esi,0x4(%esp)
f010574a:	75 1c                	jne    f0105768 <__umoddi3+0x48>
f010574c:	39 f7                	cmp    %esi,%edi
f010574e:	76 50                	jbe    f01057a0 <__umoddi3+0x80>
f0105750:	89 c8                	mov    %ecx,%eax
f0105752:	89 f2                	mov    %esi,%edx
f0105754:	f7 f7                	div    %edi
f0105756:	89 d0                	mov    %edx,%eax
f0105758:	31 d2                	xor    %edx,%edx
f010575a:	83 c4 1c             	add    $0x1c,%esp
f010575d:	5b                   	pop    %ebx
f010575e:	5e                   	pop    %esi
f010575f:	5f                   	pop    %edi
f0105760:	5d                   	pop    %ebp
f0105761:	c3                   	ret    
f0105762:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105768:	39 f2                	cmp    %esi,%edx
f010576a:	89 d0                	mov    %edx,%eax
f010576c:	77 52                	ja     f01057c0 <__umoddi3+0xa0>
f010576e:	0f bd ea             	bsr    %edx,%ebp
f0105771:	83 f5 1f             	xor    $0x1f,%ebp
f0105774:	75 5a                	jne    f01057d0 <__umoddi3+0xb0>
f0105776:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010577a:	0f 82 e0 00 00 00    	jb     f0105860 <__umoddi3+0x140>
f0105780:	39 0c 24             	cmp    %ecx,(%esp)
f0105783:	0f 86 d7 00 00 00    	jbe    f0105860 <__umoddi3+0x140>
f0105789:	8b 44 24 08          	mov    0x8(%esp),%eax
f010578d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105791:	83 c4 1c             	add    $0x1c,%esp
f0105794:	5b                   	pop    %ebx
f0105795:	5e                   	pop    %esi
f0105796:	5f                   	pop    %edi
f0105797:	5d                   	pop    %ebp
f0105798:	c3                   	ret    
f0105799:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01057a0:	85 ff                	test   %edi,%edi
f01057a2:	89 fd                	mov    %edi,%ebp
f01057a4:	75 0b                	jne    f01057b1 <__umoddi3+0x91>
f01057a6:	b8 01 00 00 00       	mov    $0x1,%eax
f01057ab:	31 d2                	xor    %edx,%edx
f01057ad:	f7 f7                	div    %edi
f01057af:	89 c5                	mov    %eax,%ebp
f01057b1:	89 f0                	mov    %esi,%eax
f01057b3:	31 d2                	xor    %edx,%edx
f01057b5:	f7 f5                	div    %ebp
f01057b7:	89 c8                	mov    %ecx,%eax
f01057b9:	f7 f5                	div    %ebp
f01057bb:	89 d0                	mov    %edx,%eax
f01057bd:	eb 99                	jmp    f0105758 <__umoddi3+0x38>
f01057bf:	90                   	nop
f01057c0:	89 c8                	mov    %ecx,%eax
f01057c2:	89 f2                	mov    %esi,%edx
f01057c4:	83 c4 1c             	add    $0x1c,%esp
f01057c7:	5b                   	pop    %ebx
f01057c8:	5e                   	pop    %esi
f01057c9:	5f                   	pop    %edi
f01057ca:	5d                   	pop    %ebp
f01057cb:	c3                   	ret    
f01057cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01057d0:	8b 34 24             	mov    (%esp),%esi
f01057d3:	bf 20 00 00 00       	mov    $0x20,%edi
f01057d8:	89 e9                	mov    %ebp,%ecx
f01057da:	29 ef                	sub    %ebp,%edi
f01057dc:	d3 e0                	shl    %cl,%eax
f01057de:	89 f9                	mov    %edi,%ecx
f01057e0:	89 f2                	mov    %esi,%edx
f01057e2:	d3 ea                	shr    %cl,%edx
f01057e4:	89 e9                	mov    %ebp,%ecx
f01057e6:	09 c2                	or     %eax,%edx
f01057e8:	89 d8                	mov    %ebx,%eax
f01057ea:	89 14 24             	mov    %edx,(%esp)
f01057ed:	89 f2                	mov    %esi,%edx
f01057ef:	d3 e2                	shl    %cl,%edx
f01057f1:	89 f9                	mov    %edi,%ecx
f01057f3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01057f7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01057fb:	d3 e8                	shr    %cl,%eax
f01057fd:	89 e9                	mov    %ebp,%ecx
f01057ff:	89 c6                	mov    %eax,%esi
f0105801:	d3 e3                	shl    %cl,%ebx
f0105803:	89 f9                	mov    %edi,%ecx
f0105805:	89 d0                	mov    %edx,%eax
f0105807:	d3 e8                	shr    %cl,%eax
f0105809:	89 e9                	mov    %ebp,%ecx
f010580b:	09 d8                	or     %ebx,%eax
f010580d:	89 d3                	mov    %edx,%ebx
f010580f:	89 f2                	mov    %esi,%edx
f0105811:	f7 34 24             	divl   (%esp)
f0105814:	89 d6                	mov    %edx,%esi
f0105816:	d3 e3                	shl    %cl,%ebx
f0105818:	f7 64 24 04          	mull   0x4(%esp)
f010581c:	39 d6                	cmp    %edx,%esi
f010581e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0105822:	89 d1                	mov    %edx,%ecx
f0105824:	89 c3                	mov    %eax,%ebx
f0105826:	72 08                	jb     f0105830 <__umoddi3+0x110>
f0105828:	75 11                	jne    f010583b <__umoddi3+0x11b>
f010582a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010582e:	73 0b                	jae    f010583b <__umoddi3+0x11b>
f0105830:	2b 44 24 04          	sub    0x4(%esp),%eax
f0105834:	1b 14 24             	sbb    (%esp),%edx
f0105837:	89 d1                	mov    %edx,%ecx
f0105839:	89 c3                	mov    %eax,%ebx
f010583b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010583f:	29 da                	sub    %ebx,%edx
f0105841:	19 ce                	sbb    %ecx,%esi
f0105843:	89 f9                	mov    %edi,%ecx
f0105845:	89 f0                	mov    %esi,%eax
f0105847:	d3 e0                	shl    %cl,%eax
f0105849:	89 e9                	mov    %ebp,%ecx
f010584b:	d3 ea                	shr    %cl,%edx
f010584d:	89 e9                	mov    %ebp,%ecx
f010584f:	d3 ee                	shr    %cl,%esi
f0105851:	09 d0                	or     %edx,%eax
f0105853:	89 f2                	mov    %esi,%edx
f0105855:	83 c4 1c             	add    $0x1c,%esp
f0105858:	5b                   	pop    %ebx
f0105859:	5e                   	pop    %esi
f010585a:	5f                   	pop    %edi
f010585b:	5d                   	pop    %ebp
f010585c:	c3                   	ret    
f010585d:	8d 76 00             	lea    0x0(%esi),%esi
f0105860:	29 f9                	sub    %edi,%ecx
f0105862:	19 d6                	sbb    %edx,%esi
f0105864:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105868:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010586c:	e9 18 ff ff ff       	jmp    f0105789 <__umoddi3+0x69>

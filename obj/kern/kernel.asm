
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
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
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
f0100034:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 49 11 f0       	mov    $0xf0114970,%eax
f010004b:	2d 00 43 11 f0       	sub    $0xf0114300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 43 11 f0       	push   $0xf0114300
f0100058:	e8 61 1f 00 00       	call   f0101fbe <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 bb 04 00 00       	call   f010051d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 60 24 10 f0       	push   $0xf0102460
f010006f:	e8 96 14 00 00       	call   f010150a <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 68 0d 00 00       	call   f0100de1 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 4a 07 00 00       	call   f01007d0 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 49 11 f0 00 	cmpl   $0x0,0xf0114960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 49 11 f0    	mov    %esi,0xf0114960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 7b 24 10 f0       	push   $0xf010247b
f01000b5:	e8 50 14 00 00       	call   f010150a <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 20 14 00 00       	call   f01014e4 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 69 27 10 f0 	movl   $0xf0102769,(%esp)
f01000cb:	e8 3a 14 00 00       	call   f010150a <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 f3 06 00 00       	call   f01007d0 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 93 24 10 f0       	push   $0xf0102493
f01000f7:	e8 0e 14 00 00       	call   f010150a <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 dc 13 00 00       	call   f01014e4 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 69 27 10 f0 	movl   $0xf0102769,(%esp)
f010010f:	e8 f6 13 00 00       	call   f010150a <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 45 11 f0    	mov    0xf0114524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 45 11 f0    	mov    %edx,0xf0114524
f0100159:	88 81 20 43 11 f0    	mov    %al,-0xfeebce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 45 11 f0 00 	movl   $0x0,0xf0114524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f0 00 00 00    	je     f010027c <kbd_proc_data+0xfe>
f010018c:	ba 60 00 00 00       	mov    $0x60,%edx
f0100191:	ec                   	in     (%dx),%al
f0100192:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100194:	3c e0                	cmp    $0xe0,%al
f0100196:	75 0d                	jne    f01001a5 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f0100198:	83 0d 00 43 11 f0 40 	orl    $0x40,0xf0114300
		return 0;
f010019f:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001a4:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001a5:	55                   	push   %ebp
f01001a6:	89 e5                	mov    %esp,%ebp
f01001a8:	53                   	push   %ebx
f01001a9:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001ac:	84 c0                	test   %al,%al
f01001ae:	79 36                	jns    f01001e6 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b0:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001b6:	89 cb                	mov    %ecx,%ebx
f01001b8:	83 e3 40             	and    $0x40,%ebx
f01001bb:	83 e0 7f             	and    $0x7f,%eax
f01001be:	85 db                	test   %ebx,%ebx
f01001c0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001c3:	0f b6 d2             	movzbl %dl,%edx
f01001c6:	0f b6 82 00 26 10 f0 	movzbl -0xfefda00(%edx),%eax
f01001cd:	83 c8 40             	or     $0x40,%eax
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	f7 d0                	not    %eax
f01001d5:	21 c8                	and    %ecx,%eax
f01001d7:	a3 00 43 11 f0       	mov    %eax,0xf0114300
		return 0;
f01001dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e1:	e9 9e 00 00 00       	jmp    f0100284 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e6:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001ec:	f6 c1 40             	test   $0x40,%cl
f01001ef:	74 0e                	je     f01001ff <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f1:	83 c8 80             	or     $0xffffff80,%eax
f01001f4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f9:	89 0d 00 43 11 f0    	mov    %ecx,0xf0114300
	}

	shift |= shiftcode[data];
f01001ff:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100202:	0f b6 82 00 26 10 f0 	movzbl -0xfefda00(%edx),%eax
f0100209:	0b 05 00 43 11 f0    	or     0xf0114300,%eax
f010020f:	0f b6 8a 00 25 10 f0 	movzbl -0xfefdb00(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 43 11 f0       	mov    %eax,0xf0114300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d e0 24 10 f0 	mov    -0xfefdb20(,%ecx,4),%ecx
f0100229:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010022d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100230:	a8 08                	test   $0x8,%al
f0100232:	74 1b                	je     f010024f <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100234:	89 da                	mov    %ebx,%edx
f0100236:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100239:	83 f9 19             	cmp    $0x19,%ecx
f010023c:	77 05                	ja     f0100243 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f010023e:	83 eb 20             	sub    $0x20,%ebx
f0100241:	eb 0c                	jmp    f010024f <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100243:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100246:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100249:	83 fa 19             	cmp    $0x19,%edx
f010024c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010024f:	f7 d0                	not    %eax
f0100251:	a8 06                	test   $0x6,%al
f0100253:	75 2d                	jne    f0100282 <kbd_proc_data+0x104>
f0100255:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010025b:	75 25                	jne    f0100282 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f010025d:	83 ec 0c             	sub    $0xc,%esp
f0100260:	68 ad 24 10 f0       	push   $0xf01024ad
f0100265:	e8 a0 12 00 00       	call   f010150a <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010026a:	ba 92 00 00 00       	mov    $0x92,%edx
f010026f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100274:	ee                   	out    %al,(%dx)
f0100275:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100278:	89 d8                	mov    %ebx,%eax
f010027a:	eb 08                	jmp    f0100284 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010027c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100281:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100282:	89 d8                	mov    %ebx,%eax
}
f0100284:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100287:	c9                   	leave  
f0100288:	c3                   	ret    

f0100289 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100289:	55                   	push   %ebp
f010028a:	89 e5                	mov    %esp,%ebp
f010028c:	57                   	push   %edi
f010028d:	56                   	push   %esi
f010028e:	53                   	push   %ebx
f010028f:	83 ec 1c             	sub    $0x1c,%esp
f0100292:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100294:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100299:	be fd 03 00 00       	mov    $0x3fd,%esi
f010029e:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002a3:	eb 09                	jmp    f01002ae <cons_putc+0x25>
f01002a5:	89 ca                	mov    %ecx,%edx
f01002a7:	ec                   	in     (%dx),%al
f01002a8:	ec                   	in     (%dx),%al
f01002a9:	ec                   	in     (%dx),%al
f01002aa:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002ab:	83 c3 01             	add    $0x1,%ebx
f01002ae:	89 f2                	mov    %esi,%edx
f01002b0:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002b1:	a8 20                	test   $0x20,%al
f01002b3:	75 08                	jne    f01002bd <cons_putc+0x34>
f01002b5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002bb:	7e e8                	jle    f01002a5 <cons_putc+0x1c>
f01002bd:	89 f8                	mov    %edi,%eax
f01002bf:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c2:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002c7:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002c8:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002cd:	be 79 03 00 00       	mov    $0x379,%esi
f01002d2:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d7:	eb 09                	jmp    f01002e2 <cons_putc+0x59>
f01002d9:	89 ca                	mov    %ecx,%edx
f01002db:	ec                   	in     (%dx),%al
f01002dc:	ec                   	in     (%dx),%al
f01002dd:	ec                   	in     (%dx),%al
f01002de:	ec                   	in     (%dx),%al
f01002df:	83 c3 01             	add    $0x1,%ebx
f01002e2:	89 f2                	mov    %esi,%edx
f01002e4:	ec                   	in     (%dx),%al
f01002e5:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002eb:	7f 04                	jg     f01002f1 <cons_putc+0x68>
f01002ed:	84 c0                	test   %al,%al
f01002ef:	79 e8                	jns    f01002d9 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002f1:	ba 78 03 00 00       	mov    $0x378,%edx
f01002f6:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f01002fa:	ee                   	out    %al,(%dx)
f01002fb:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100300:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100305:	ee                   	out    %al,(%dx)
f0100306:	b8 08 00 00 00       	mov    $0x8,%eax
f010030b:	ee                   	out    %al,(%dx)
cga_putc(int c)
{
	// if no attribute given, then use black on white
	//if (!(c & ~0xFF))
	//	c |= 0x0700;
	if (!(c & ~0xFF)){
f010030c:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100312:	75 3d                	jne    f0100351 <cons_putc+0xc8>
    	  char ch = c & 0xFF;
    	    if (ch > 47 && ch < 58) {
f0100314:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100318:	83 e8 30             	sub    $0x30,%eax
f010031b:	3c 09                	cmp    $0x9,%al
f010031d:	77 08                	ja     f0100327 <cons_putc+0x9e>
              c |= 0x0100;
f010031f:	81 cf 00 01 00 00    	or     $0x100,%edi
f0100325:	eb 2a                	jmp    f0100351 <cons_putc+0xc8>
    	    }
	    else if (ch > 64 && ch < 91) {
f0100327:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010032b:	83 e8 41             	sub    $0x41,%eax
f010032e:	3c 19                	cmp    $0x19,%al
f0100330:	77 08                	ja     f010033a <cons_putc+0xb1>
              c |= 0x0200;
f0100332:	81 cf 00 02 00 00    	or     $0x200,%edi
f0100338:	eb 17                	jmp    f0100351 <cons_putc+0xc8>
    	    }
	    else if (ch > 96 && ch < 123) {
f010033a:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010033e:	83 e8 61             	sub    $0x61,%eax
              c |= 0x0300;
f0100341:	89 fa                	mov    %edi,%edx
f0100343:	80 ce 03             	or     $0x3,%dh
f0100346:	81 cf 00 04 00 00    	or     $0x400,%edi
f010034c:	3c 19                	cmp    $0x19,%al
f010034e:	0f 46 fa             	cmovbe %edx,%edi
    	    }
	    else {
              c |= 0x0400;
    	    }
	}
	switch (c & 0xff) {
f0100351:	89 f8                	mov    %edi,%eax
f0100353:	0f b6 c0             	movzbl %al,%eax
f0100356:	83 f8 09             	cmp    $0x9,%eax
f0100359:	74 74                	je     f01003cf <cons_putc+0x146>
f010035b:	83 f8 09             	cmp    $0x9,%eax
f010035e:	7f 0a                	jg     f010036a <cons_putc+0xe1>
f0100360:	83 f8 08             	cmp    $0x8,%eax
f0100363:	74 14                	je     f0100379 <cons_putc+0xf0>
f0100365:	e9 99 00 00 00       	jmp    f0100403 <cons_putc+0x17a>
f010036a:	83 f8 0a             	cmp    $0xa,%eax
f010036d:	74 3a                	je     f01003a9 <cons_putc+0x120>
f010036f:	83 f8 0d             	cmp    $0xd,%eax
f0100372:	74 3d                	je     f01003b1 <cons_putc+0x128>
f0100374:	e9 8a 00 00 00       	jmp    f0100403 <cons_putc+0x17a>
	case '\b':
		if (crt_pos > 0) {
f0100379:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f0100380:	66 85 c0             	test   %ax,%ax
f0100383:	0f 84 e6 00 00 00    	je     f010046f <cons_putc+0x1e6>
			crt_pos--;
f0100389:	83 e8 01             	sub    $0x1,%eax
f010038c:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100392:	0f b7 c0             	movzwl %ax,%eax
f0100395:	66 81 e7 00 ff       	and    $0xff00,%di
f010039a:	83 cf 20             	or     $0x20,%edi
f010039d:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f01003a3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003a7:	eb 78                	jmp    f0100421 <cons_putc+0x198>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003a9:	66 83 05 28 45 11 f0 	addw   $0x50,0xf0114528
f01003b0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003b1:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f01003b8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003be:	c1 e8 16             	shr    $0x16,%eax
f01003c1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003c4:	c1 e0 04             	shl    $0x4,%eax
f01003c7:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
f01003cd:	eb 52                	jmp    f0100421 <cons_putc+0x198>
		break;
	case '\t':
		cons_putc(' ');
f01003cf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d4:	e8 b0 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003d9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003de:	e8 a6 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003e3:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e8:	e8 9c fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003ed:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f2:	e8 92 fe ff ff       	call   f0100289 <cons_putc>
		cons_putc(' ');
f01003f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fc:	e8 88 fe ff ff       	call   f0100289 <cons_putc>
f0100401:	eb 1e                	jmp    f0100421 <cons_putc+0x198>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100403:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f010040a:	8d 50 01             	lea    0x1(%eax),%edx
f010040d:	66 89 15 28 45 11 f0 	mov    %dx,0xf0114528
f0100414:	0f b7 c0             	movzwl %ax,%eax
f0100417:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f010041d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100421:	66 81 3d 28 45 11 f0 	cmpw   $0x7cf,0xf0114528
f0100428:	cf 07 
f010042a:	76 43                	jbe    f010046f <cons_putc+0x1e6>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010042c:	a1 2c 45 11 f0       	mov    0xf011452c,%eax
f0100431:	83 ec 04             	sub    $0x4,%esp
f0100434:	68 00 0f 00 00       	push   $0xf00
f0100439:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010043f:	52                   	push   %edx
f0100440:	50                   	push   %eax
f0100441:	e8 c5 1b 00 00       	call   f010200b <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100446:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f010044c:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100452:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100458:	83 c4 10             	add    $0x10,%esp
f010045b:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100460:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100463:	39 d0                	cmp    %edx,%eax
f0100465:	75 f4                	jne    f010045b <cons_putc+0x1d2>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100467:	66 83 2d 28 45 11 f0 	subw   $0x50,0xf0114528
f010046e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010046f:	8b 0d 30 45 11 f0    	mov    0xf0114530,%ecx
f0100475:	b8 0e 00 00 00       	mov    $0xe,%eax
f010047a:	89 ca                	mov    %ecx,%edx
f010047c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010047d:	0f b7 1d 28 45 11 f0 	movzwl 0xf0114528,%ebx
f0100484:	8d 71 01             	lea    0x1(%ecx),%esi
f0100487:	89 d8                	mov    %ebx,%eax
f0100489:	66 c1 e8 08          	shr    $0x8,%ax
f010048d:	89 f2                	mov    %esi,%edx
f010048f:	ee                   	out    %al,(%dx)
f0100490:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100495:	89 ca                	mov    %ecx,%edx
f0100497:	ee                   	out    %al,(%dx)
f0100498:	89 d8                	mov    %ebx,%eax
f010049a:	89 f2                	mov    %esi,%edx
f010049c:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010049d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004a0:	5b                   	pop    %ebx
f01004a1:	5e                   	pop    %esi
f01004a2:	5f                   	pop    %edi
f01004a3:	5d                   	pop    %ebp
f01004a4:	c3                   	ret    

f01004a5 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004a5:	80 3d 34 45 11 f0 00 	cmpb   $0x0,0xf0114534
f01004ac:	74 11                	je     f01004bf <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004b4:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f01004b9:	e8 7d fc ff ff       	call   f010013b <cons_intr>
}
f01004be:	c9                   	leave  
f01004bf:	f3 c3                	repz ret 

f01004c1 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004c1:	55                   	push   %ebp
f01004c2:	89 e5                	mov    %esp,%ebp
f01004c4:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004c7:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004cc:	e8 6a fc ff ff       	call   f010013b <cons_intr>
}
f01004d1:	c9                   	leave  
f01004d2:	c3                   	ret    

f01004d3 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004d3:	55                   	push   %ebp
f01004d4:	89 e5                	mov    %esp,%ebp
f01004d6:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004d9:	e8 c7 ff ff ff       	call   f01004a5 <serial_intr>
	kbd_intr();
f01004de:	e8 de ff ff ff       	call   f01004c1 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004e3:	a1 20 45 11 f0       	mov    0xf0114520,%eax
f01004e8:	3b 05 24 45 11 f0    	cmp    0xf0114524,%eax
f01004ee:	74 26                	je     f0100516 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004f0:	8d 50 01             	lea    0x1(%eax),%edx
f01004f3:	89 15 20 45 11 f0    	mov    %edx,0xf0114520
f01004f9:	0f b6 88 20 43 11 f0 	movzbl -0xfeebce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100500:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100502:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100508:	75 11                	jne    f010051b <cons_getc+0x48>
			cons.rpos = 0;
f010050a:	c7 05 20 45 11 f0 00 	movl   $0x0,0xf0114520
f0100511:	00 00 00 
f0100514:	eb 05                	jmp    f010051b <cons_getc+0x48>
		return c;
	}
	return 0;
f0100516:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010051b:	c9                   	leave  
f010051c:	c3                   	ret    

f010051d <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010051d:	55                   	push   %ebp
f010051e:	89 e5                	mov    %esp,%ebp
f0100520:	57                   	push   %edi
f0100521:	56                   	push   %esi
f0100522:	53                   	push   %ebx
f0100523:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100526:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010052d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100534:	5a a5 
	if (*cp != 0xA55A) {
f0100536:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010053d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100541:	74 11                	je     f0100554 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100543:	c7 05 30 45 11 f0 b4 	movl   $0x3b4,0xf0114530
f010054a:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010054d:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100552:	eb 16                	jmp    f010056a <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100554:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010055b:	c7 05 30 45 11 f0 d4 	movl   $0x3d4,0xf0114530
f0100562:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100565:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010056a:	8b 3d 30 45 11 f0    	mov    0xf0114530,%edi
f0100570:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100575:	89 fa                	mov    %edi,%edx
f0100577:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100578:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057b:	89 da                	mov    %ebx,%edx
f010057d:	ec                   	in     (%dx),%al
f010057e:	0f b6 c8             	movzbl %al,%ecx
f0100581:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100584:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100589:	89 fa                	mov    %edi,%edx
f010058b:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010058c:	89 da                	mov    %ebx,%edx
f010058e:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010058f:	89 35 2c 45 11 f0    	mov    %esi,0xf011452c
	crt_pos = pos;
f0100595:	0f b6 c0             	movzbl %al,%eax
f0100598:	09 c8                	or     %ecx,%eax
f010059a:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005a0:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	89 f2                	mov    %esi,%edx
f01005ac:	ee                   	out    %al,(%dx)
f01005ad:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005b7:	ee                   	out    %al,(%dx)
f01005b8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005bd:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005c2:	89 da                	mov    %ebx,%edx
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01005cf:	ee                   	out    %al,(%dx)
f01005d0:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005d5:	b8 03 00 00 00       	mov    $0x3,%eax
f01005da:	ee                   	out    %al,(%dx)
f01005db:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005e0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e5:	ee                   	out    %al,(%dx)
f01005e6:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005eb:	b8 01 00 00 00       	mov    $0x1,%eax
f01005f0:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005f1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005f6:	ec                   	in     (%dx),%al
f01005f7:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005f9:	3c ff                	cmp    $0xff,%al
f01005fb:	0f 95 05 34 45 11 f0 	setne  0xf0114534
f0100602:	89 f2                	mov    %esi,%edx
f0100604:	ec                   	in     (%dx),%al
f0100605:	89 da                	mov    %ebx,%edx
f0100607:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100608:	80 f9 ff             	cmp    $0xff,%cl
f010060b:	75 10                	jne    f010061d <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f010060d:	83 ec 0c             	sub    $0xc,%esp
f0100610:	68 b9 24 10 f0       	push   $0xf01024b9
f0100615:	e8 f0 0e 00 00       	call   f010150a <cprintf>
f010061a:	83 c4 10             	add    $0x10,%esp
}
f010061d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100620:	5b                   	pop    %ebx
f0100621:	5e                   	pop    %esi
f0100622:	5f                   	pop    %edi
f0100623:	5d                   	pop    %ebp
f0100624:	c3                   	ret    

f0100625 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100625:	55                   	push   %ebp
f0100626:	89 e5                	mov    %esp,%ebp
f0100628:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010062b:	8b 45 08             	mov    0x8(%ebp),%eax
f010062e:	e8 56 fc ff ff       	call   f0100289 <cons_putc>
}
f0100633:	c9                   	leave  
f0100634:	c3                   	ret    

f0100635 <getchar>:

int
getchar(void)
{
f0100635:	55                   	push   %ebp
f0100636:	89 e5                	mov    %esp,%ebp
f0100638:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010063b:	e8 93 fe ff ff       	call   f01004d3 <cons_getc>
f0100640:	85 c0                	test   %eax,%eax
f0100642:	74 f7                	je     f010063b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100644:	c9                   	leave  
f0100645:	c3                   	ret    

f0100646 <iscons>:

int
iscons(int fdnum)
{
f0100646:	55                   	push   %ebp
f0100647:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100649:	b8 01 00 00 00       	mov    $0x1,%eax
f010064e:	5d                   	pop    %ebp
f010064f:	c3                   	ret    

f0100650 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100650:	55                   	push   %ebp
f0100651:	89 e5                	mov    %esp,%ebp
f0100653:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100656:	68 00 27 10 f0       	push   $0xf0102700
f010065b:	68 1e 27 10 f0       	push   $0xf010271e
f0100660:	68 23 27 10 f0       	push   $0xf0102723
f0100665:	e8 a0 0e 00 00       	call   f010150a <cprintf>
f010066a:	83 c4 0c             	add    $0xc,%esp
f010066d:	68 b8 27 10 f0       	push   $0xf01027b8
f0100672:	68 2c 27 10 f0       	push   $0xf010272c
f0100677:	68 23 27 10 f0       	push   $0xf0102723
f010067c:	e8 89 0e 00 00       	call   f010150a <cprintf>
f0100681:	83 c4 0c             	add    $0xc,%esp
f0100684:	68 e0 27 10 f0       	push   $0xf01027e0
f0100689:	68 35 27 10 f0       	push   $0xf0102735
f010068e:	68 23 27 10 f0       	push   $0xf0102723
f0100693:	e8 72 0e 00 00       	call   f010150a <cprintf>
	return 0;
}
f0100698:	b8 00 00 00 00       	mov    $0x0,%eax
f010069d:	c9                   	leave  
f010069e:	c3                   	ret    

f010069f <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010069f:	55                   	push   %ebp
f01006a0:	89 e5                	mov    %esp,%ebp
f01006a2:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006a5:	68 3f 27 10 f0       	push   $0xf010273f
f01006aa:	e8 5b 0e 00 00       	call   f010150a <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006af:	83 c4 08             	add    $0x8,%esp
f01006b2:	68 0c 00 10 00       	push   $0x10000c
f01006b7:	68 08 28 10 f0       	push   $0xf0102808
f01006bc:	e8 49 0e 00 00       	call   f010150a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006c1:	83 c4 0c             	add    $0xc,%esp
f01006c4:	68 0c 00 10 00       	push   $0x10000c
f01006c9:	68 0c 00 10 f0       	push   $0xf010000c
f01006ce:	68 30 28 10 f0       	push   $0xf0102830
f01006d3:	e8 32 0e 00 00       	call   f010150a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d8:	83 c4 0c             	add    $0xc,%esp
f01006db:	68 41 24 10 00       	push   $0x102441
f01006e0:	68 41 24 10 f0       	push   $0xf0102441
f01006e5:	68 54 28 10 f0       	push   $0xf0102854
f01006ea:	e8 1b 0e 00 00       	call   f010150a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ef:	83 c4 0c             	add    $0xc,%esp
f01006f2:	68 00 43 11 00       	push   $0x114300
f01006f7:	68 00 43 11 f0       	push   $0xf0114300
f01006fc:	68 78 28 10 f0       	push   $0xf0102878
f0100701:	e8 04 0e 00 00       	call   f010150a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100706:	83 c4 0c             	add    $0xc,%esp
f0100709:	68 70 49 11 00       	push   $0x114970
f010070e:	68 70 49 11 f0       	push   $0xf0114970
f0100713:	68 9c 28 10 f0       	push   $0xf010289c
f0100718:	e8 ed 0d 00 00       	call   f010150a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010071d:	b8 6f 4d 11 f0       	mov    $0xf0114d6f,%eax
f0100722:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100727:	83 c4 08             	add    $0x8,%esp
f010072a:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010072f:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100735:	85 c0                	test   %eax,%eax
f0100737:	0f 48 c2             	cmovs  %edx,%eax
f010073a:	c1 f8 0a             	sar    $0xa,%eax
f010073d:	50                   	push   %eax
f010073e:	68 c0 28 10 f0       	push   $0xf01028c0
f0100743:	e8 c2 0d 00 00       	call   f010150a <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100748:	b8 00 00 00 00       	mov    $0x0,%eax
f010074d:	c9                   	leave  
f010074e:	c3                   	ret    

f010074f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010074f:	55                   	push   %ebp
f0100750:	89 e5                	mov    %esp,%ebp
f0100752:	57                   	push   %edi
f0100753:	56                   	push   %esi
f0100754:	53                   	push   %ebx
f0100755:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100758:	89 eb                	mov    %ebp,%ebx
	struct Eipdebuginfo info;        
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();
	
	cprintf("Stack backtrace:\r\n");
f010075a:	68 58 27 10 f0       	push   $0xf0102758
f010075f:	e8 a6 0d 00 00       	call   f010150a <cprintf>
    	while (ebp!=0)
f0100764:	83 c4 10             	add    $0x10,%esp
    	{
	eip = ebp[1];
       	cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);//%08x 补0输出8位16进制数
	debuginfo_eip((uintptr_t)eip,&info);
f0100767:	8d 7d d0             	lea    -0x30(%ebp),%edi
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();
	
	cprintf("Stack backtrace:\r\n");
    	while (ebp!=0)
f010076a:	eb 53                	jmp    f01007bf <mon_backtrace+0x70>
    	{
	eip = ebp[1];
f010076c:	8b 73 04             	mov    0x4(%ebx),%esi
       	cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);//%08x 补0输出8位16进制数
f010076f:	ff 73 18             	pushl  0x18(%ebx)
f0100772:	ff 73 14             	pushl  0x14(%ebx)
f0100775:	ff 73 10             	pushl  0x10(%ebx)
f0100778:	ff 73 0c             	pushl  0xc(%ebx)
f010077b:	ff 73 08             	pushl  0x8(%ebx)
f010077e:	56                   	push   %esi
f010077f:	53                   	push   %ebx
f0100780:	68 ec 28 10 f0       	push   $0xf01028ec
f0100785:	e8 80 0d 00 00       	call   f010150a <cprintf>
	debuginfo_eip((uintptr_t)eip,&info);
f010078a:	83 c4 18             	add    $0x18,%esp
f010078d:	57                   	push   %edi
f010078e:	56                   	push   %esi
f010078f:	e8 80 0e 00 00       	call   f0101614 <debuginfo_eip>
	cprintf("%s:%d", info.eip_file, info.eip_line);
f0100794:	83 c4 0c             	add    $0xc,%esp
f0100797:	ff 75 d4             	pushl  -0x2c(%ebp)
f010079a:	ff 75 d0             	pushl  -0x30(%ebp)
f010079d:	68 6b 27 10 f0       	push   $0xf010276b
f01007a2:	e8 63 0d 00 00       	call   f010150a <cprintf>
        cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name,info.eip_fn_addr);
f01007a7:	ff 75 e0             	pushl  -0x20(%ebp)
f01007aa:	ff 75 d8             	pushl  -0x28(%ebp)
f01007ad:	ff 75 dc             	pushl  -0x24(%ebp)
f01007b0:	68 71 27 10 f0       	push   $0xf0102771
f01007b5:	e8 50 0d 00 00       	call   f010150a <cprintf>
   	ebp = (uint32_t *)ebp[0];
f01007ba:	8b 1b                	mov    (%ebx),%ebx
f01007bc:	83 c4 20             	add    $0x20,%esp
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();
	
	cprintf("Stack backtrace:\r\n");
    	while (ebp!=0)
f01007bf:	85 db                	test   %ebx,%ebx
f01007c1:	75 a9                	jne    f010076c <mon_backtrace+0x1d>
	cprintf("%s:%d", info.eip_file, info.eip_line);
        cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name,info.eip_fn_addr);
   	ebp = (uint32_t *)ebp[0];
    	}
    	return 0;
}
f01007c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01007c8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007cb:	5b                   	pop    %ebx
f01007cc:	5e                   	pop    %esi
f01007cd:	5f                   	pop    %edi
f01007ce:	5d                   	pop    %ebp
f01007cf:	c3                   	ret    

f01007d0 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007d0:	55                   	push   %ebp
f01007d1:	89 e5                	mov    %esp,%ebp
f01007d3:	57                   	push   %edi
f01007d4:	56                   	push   %esi
f01007d5:	53                   	push   %ebx
f01007d6:	83 ec 58             	sub    $0x58,%esp
	char *buf; 
	cprintf("Welcome to the JOS kernel monitor!\n");
f01007d9:	68 24 29 10 f0       	push   $0xf0102924
f01007de:	e8 27 0d 00 00       	call   f010150a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007e3:	c7 04 24 48 29 10 f0 	movl   $0xf0102948,(%esp)
f01007ea:	e8 1b 0d 00 00       	call   f010150a <cprintf>
f01007ef:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007f2:	83 ec 0c             	sub    $0xc,%esp
f01007f5:	68 7c 27 10 f0       	push   $0xf010277c
f01007fa:	e8 68 15 00 00       	call   f0101d67 <readline>
f01007ff:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100801:	83 c4 10             	add    $0x10,%esp
f0100804:	85 c0                	test   %eax,%eax
f0100806:	74 ea                	je     f01007f2 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100808:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010080f:	be 00 00 00 00       	mov    $0x0,%esi
f0100814:	eb 0a                	jmp    f0100820 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100816:	c6 03 00             	movb   $0x0,(%ebx)
f0100819:	89 f7                	mov    %esi,%edi
f010081b:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010081e:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100820:	0f b6 03             	movzbl (%ebx),%eax
f0100823:	84 c0                	test   %al,%al
f0100825:	74 63                	je     f010088a <monitor+0xba>
f0100827:	83 ec 08             	sub    $0x8,%esp
f010082a:	0f be c0             	movsbl %al,%eax
f010082d:	50                   	push   %eax
f010082e:	68 80 27 10 f0       	push   $0xf0102780
f0100833:	e8 49 17 00 00       	call   f0101f81 <strchr>
f0100838:	83 c4 10             	add    $0x10,%esp
f010083b:	85 c0                	test   %eax,%eax
f010083d:	75 d7                	jne    f0100816 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f010083f:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100842:	74 46                	je     f010088a <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100844:	83 fe 0f             	cmp    $0xf,%esi
f0100847:	75 14                	jne    f010085d <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100849:	83 ec 08             	sub    $0x8,%esp
f010084c:	6a 10                	push   $0x10
f010084e:	68 85 27 10 f0       	push   $0xf0102785
f0100853:	e8 b2 0c 00 00       	call   f010150a <cprintf>
f0100858:	83 c4 10             	add    $0x10,%esp
f010085b:	eb 95                	jmp    f01007f2 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f010085d:	8d 7e 01             	lea    0x1(%esi),%edi
f0100860:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100864:	eb 03                	jmp    f0100869 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100866:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100869:	0f b6 03             	movzbl (%ebx),%eax
f010086c:	84 c0                	test   %al,%al
f010086e:	74 ae                	je     f010081e <monitor+0x4e>
f0100870:	83 ec 08             	sub    $0x8,%esp
f0100873:	0f be c0             	movsbl %al,%eax
f0100876:	50                   	push   %eax
f0100877:	68 80 27 10 f0       	push   $0xf0102780
f010087c:	e8 00 17 00 00       	call   f0101f81 <strchr>
f0100881:	83 c4 10             	add    $0x10,%esp
f0100884:	85 c0                	test   %eax,%eax
f0100886:	74 de                	je     f0100866 <monitor+0x96>
f0100888:	eb 94                	jmp    f010081e <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f010088a:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100891:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100892:	85 f6                	test   %esi,%esi
f0100894:	0f 84 58 ff ff ff    	je     f01007f2 <monitor+0x22>
f010089a:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010089f:	83 ec 08             	sub    $0x8,%esp
f01008a2:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008a5:	ff 34 85 80 29 10 f0 	pushl  -0xfefd680(,%eax,4)
f01008ac:	ff 75 a8             	pushl  -0x58(%ebp)
f01008af:	e8 6f 16 00 00       	call   f0101f23 <strcmp>
f01008b4:	83 c4 10             	add    $0x10,%esp
f01008b7:	85 c0                	test   %eax,%eax
f01008b9:	75 21                	jne    f01008dc <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01008bb:	83 ec 04             	sub    $0x4,%esp
f01008be:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008c1:	ff 75 08             	pushl  0x8(%ebp)
f01008c4:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008c7:	52                   	push   %edx
f01008c8:	56                   	push   %esi
f01008c9:	ff 14 85 88 29 10 f0 	call   *-0xfefd678(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008d0:	83 c4 10             	add    $0x10,%esp
f01008d3:	85 c0                	test   %eax,%eax
f01008d5:	78 25                	js     f01008fc <monitor+0x12c>
f01008d7:	e9 16 ff ff ff       	jmp    f01007f2 <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008dc:	83 c3 01             	add    $0x1,%ebx
f01008df:	83 fb 03             	cmp    $0x3,%ebx
f01008e2:	75 bb                	jne    f010089f <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008e4:	83 ec 08             	sub    $0x8,%esp
f01008e7:	ff 75 a8             	pushl  -0x58(%ebp)
f01008ea:	68 a2 27 10 f0       	push   $0xf01027a2
f01008ef:	e8 16 0c 00 00       	call   f010150a <cprintf>
f01008f4:	83 c4 10             	add    $0x10,%esp
f01008f7:	e9 f6 fe ff ff       	jmp    f01007f2 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008fc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008ff:	5b                   	pop    %ebx
f0100900:	5e                   	pop    %esi
f0100901:	5f                   	pop    %edi
f0100902:	5d                   	pop    %ebp
f0100903:	c3                   	ret    

f0100904 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100904:	55                   	push   %ebp
f0100905:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100907:	83 3d 38 45 11 f0 00 	cmpl   $0x0,0xf0114538
f010090e:	75 11                	jne    f0100921 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100910:	ba 6f 59 11 f0       	mov    $0xf011596f,%edx
f0100915:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010091b:	89 15 38 45 11 f0    	mov    %edx,0xf0114538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100921:	8b 0d 38 45 11 f0    	mov    0xf0114538,%ecx
	nextfree += n;
	nextfree = ROUNDUP( (char*)nextfree, PGSIZE);
f0100927:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f010092e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100934:	89 15 38 45 11 f0    	mov    %edx,0xf0114538
	//nextfree += ROUNDUP(n,PGSIZE);
	return result;
}
f010093a:	89 c8                	mov    %ecx,%eax
f010093c:	5d                   	pop    %ebp
f010093d:	c3                   	ret    

f010093e <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f010093e:	89 d1                	mov    %edx,%ecx
f0100940:	c1 e9 16             	shr    $0x16,%ecx
f0100943:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100946:	a8 01                	test   $0x1,%al
f0100948:	74 52                	je     f010099c <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010094a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010094f:	89 c1                	mov    %eax,%ecx
f0100951:	c1 e9 0c             	shr    $0xc,%ecx
f0100954:	3b 0d 64 49 11 f0    	cmp    0xf0114964,%ecx
f010095a:	72 1b                	jb     f0100977 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f010095c:	55                   	push   %ebp
f010095d:	89 e5                	mov    %esp,%ebp
f010095f:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100962:	50                   	push   %eax
f0100963:	68 a4 29 10 f0       	push   $0xf01029a4
f0100968:	68 c0 02 00 00       	push   $0x2c0
f010096d:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100972:	e8 14 f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100977:	c1 ea 0c             	shr    $0xc,%edx
f010097a:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100980:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100987:	89 c2                	mov    %eax,%edx
f0100989:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f010098c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100991:	85 d2                	test   %edx,%edx
f0100993:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100998:	0f 44 c2             	cmove  %edx,%eax
f010099b:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f010099c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009a1:	c3                   	ret    

f01009a2 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009a2:	55                   	push   %ebp
f01009a3:	89 e5                	mov    %esp,%ebp
f01009a5:	57                   	push   %edi
f01009a6:	56                   	push   %esi
f01009a7:	53                   	push   %ebx
f01009a8:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009ab:	84 c0                	test   %al,%al
f01009ad:	0f 85 72 02 00 00    	jne    f0100c25 <check_page_free_list+0x283>
f01009b3:	e9 7f 02 00 00       	jmp    f0100c37 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009b8:	83 ec 04             	sub    $0x4,%esp
f01009bb:	68 c8 29 10 f0       	push   $0xf01029c8
f01009c0:	68 03 02 00 00       	push   $0x203
f01009c5:	68 5c 2b 10 f0       	push   $0xf0102b5c
f01009ca:	e8 bc f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009cf:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009d2:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009d5:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01009d8:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01009db:	89 c2                	mov    %eax,%edx
f01009dd:	2b 15 6c 49 11 f0    	sub    0xf011496c,%edx
f01009e3:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01009e9:	0f 95 c2             	setne  %dl
f01009ec:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01009ef:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01009f3:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009f5:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009f9:	8b 00                	mov    (%eax),%eax
f01009fb:	85 c0                	test   %eax,%eax
f01009fd:	75 dc                	jne    f01009db <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01009ff:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a02:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a08:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a0b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a0e:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a10:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a13:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a18:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a1d:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f0100a23:	eb 53                	jmp    f0100a78 <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a25:	89 d8                	mov    %ebx,%eax
f0100a27:	2b 05 6c 49 11 f0    	sub    0xf011496c,%eax
f0100a2d:	c1 f8 03             	sar    $0x3,%eax
f0100a30:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a33:	89 c2                	mov    %eax,%edx
f0100a35:	c1 ea 16             	shr    $0x16,%edx
f0100a38:	39 f2                	cmp    %esi,%edx
f0100a3a:	73 3a                	jae    f0100a76 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a3c:	89 c2                	mov    %eax,%edx
f0100a3e:	c1 ea 0c             	shr    $0xc,%edx
f0100a41:	3b 15 64 49 11 f0    	cmp    0xf0114964,%edx
f0100a47:	72 12                	jb     f0100a5b <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a49:	50                   	push   %eax
f0100a4a:	68 a4 29 10 f0       	push   $0xf01029a4
f0100a4f:	6a 52                	push   $0x52
f0100a51:	68 68 2b 10 f0       	push   $0xf0102b68
f0100a56:	e8 30 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a5b:	83 ec 04             	sub    $0x4,%esp
f0100a5e:	68 80 00 00 00       	push   $0x80
f0100a63:	68 97 00 00 00       	push   $0x97
f0100a68:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a6d:	50                   	push   %eax
f0100a6e:	e8 4b 15 00 00       	call   f0101fbe <memset>
f0100a73:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a76:	8b 1b                	mov    (%ebx),%ebx
f0100a78:	85 db                	test   %ebx,%ebx
f0100a7a:	75 a9                	jne    f0100a25 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a7c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a81:	e8 7e fe ff ff       	call   f0100904 <boot_alloc>
f0100a86:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a89:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a8f:	8b 0d 6c 49 11 f0    	mov    0xf011496c,%ecx
		assert(pp < pages + npages);
f0100a95:	a1 64 49 11 f0       	mov    0xf0114964,%eax
f0100a9a:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a9d:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aa0:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100aa3:	be 00 00 00 00       	mov    $0x0,%esi
f0100aa8:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100aab:	e9 30 01 00 00       	jmp    f0100be0 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ab0:	39 ca                	cmp    %ecx,%edx
f0100ab2:	73 19                	jae    f0100acd <check_page_free_list+0x12b>
f0100ab4:	68 76 2b 10 f0       	push   $0xf0102b76
f0100ab9:	68 82 2b 10 f0       	push   $0xf0102b82
f0100abe:	68 1d 02 00 00       	push   $0x21d
f0100ac3:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100ac8:	e8 be f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100acd:	39 fa                	cmp    %edi,%edx
f0100acf:	72 19                	jb     f0100aea <check_page_free_list+0x148>
f0100ad1:	68 97 2b 10 f0       	push   $0xf0102b97
f0100ad6:	68 82 2b 10 f0       	push   $0xf0102b82
f0100adb:	68 1e 02 00 00       	push   $0x21e
f0100ae0:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100ae5:	e8 a1 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aea:	89 d0                	mov    %edx,%eax
f0100aec:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100aef:	a8 07                	test   $0x7,%al
f0100af1:	74 19                	je     f0100b0c <check_page_free_list+0x16a>
f0100af3:	68 ec 29 10 f0       	push   $0xf01029ec
f0100af8:	68 82 2b 10 f0       	push   $0xf0102b82
f0100afd:	68 1f 02 00 00       	push   $0x21f
f0100b02:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100b07:	e8 7f f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b0c:	c1 f8 03             	sar    $0x3,%eax
f0100b0f:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b12:	85 c0                	test   %eax,%eax
f0100b14:	75 19                	jne    f0100b2f <check_page_free_list+0x18d>
f0100b16:	68 ab 2b 10 f0       	push   $0xf0102bab
f0100b1b:	68 82 2b 10 f0       	push   $0xf0102b82
f0100b20:	68 22 02 00 00       	push   $0x222
f0100b25:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100b2a:	e8 5c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b2f:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b34:	75 19                	jne    f0100b4f <check_page_free_list+0x1ad>
f0100b36:	68 bc 2b 10 f0       	push   $0xf0102bbc
f0100b3b:	68 82 2b 10 f0       	push   $0xf0102b82
f0100b40:	68 23 02 00 00       	push   $0x223
f0100b45:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100b4a:	e8 3c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b4f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b54:	75 19                	jne    f0100b6f <check_page_free_list+0x1cd>
f0100b56:	68 20 2a 10 f0       	push   $0xf0102a20
f0100b5b:	68 82 2b 10 f0       	push   $0xf0102b82
f0100b60:	68 24 02 00 00       	push   $0x224
f0100b65:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100b6a:	e8 1c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b6f:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b74:	75 19                	jne    f0100b8f <check_page_free_list+0x1ed>
f0100b76:	68 d5 2b 10 f0       	push   $0xf0102bd5
f0100b7b:	68 82 2b 10 f0       	push   $0xf0102b82
f0100b80:	68 25 02 00 00       	push   $0x225
f0100b85:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100b8a:	e8 fc f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b8f:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b94:	76 3f                	jbe    f0100bd5 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b96:	89 c3                	mov    %eax,%ebx
f0100b98:	c1 eb 0c             	shr    $0xc,%ebx
f0100b9b:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b9e:	77 12                	ja     f0100bb2 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ba0:	50                   	push   %eax
f0100ba1:	68 a4 29 10 f0       	push   $0xf01029a4
f0100ba6:	6a 52                	push   $0x52
f0100ba8:	68 68 2b 10 f0       	push   $0xf0102b68
f0100bad:	e8 d9 f4 ff ff       	call   f010008b <_panic>
f0100bb2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bb7:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bba:	76 1e                	jbe    f0100bda <check_page_free_list+0x238>
f0100bbc:	68 44 2a 10 f0       	push   $0xf0102a44
f0100bc1:	68 82 2b 10 f0       	push   $0xf0102b82
f0100bc6:	68 26 02 00 00       	push   $0x226
f0100bcb:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100bd0:	e8 b6 f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bd5:	83 c6 01             	add    $0x1,%esi
f0100bd8:	eb 04                	jmp    f0100bde <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100bda:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bde:	8b 12                	mov    (%edx),%edx
f0100be0:	85 d2                	test   %edx,%edx
f0100be2:	0f 85 c8 fe ff ff    	jne    f0100ab0 <check_page_free_list+0x10e>
f0100be8:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100beb:	85 f6                	test   %esi,%esi
f0100bed:	7f 19                	jg     f0100c08 <check_page_free_list+0x266>
f0100bef:	68 ef 2b 10 f0       	push   $0xf0102bef
f0100bf4:	68 82 2b 10 f0       	push   $0xf0102b82
f0100bf9:	68 2e 02 00 00       	push   $0x22e
f0100bfe:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100c03:	e8 83 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c08:	85 db                	test   %ebx,%ebx
f0100c0a:	7f 42                	jg     f0100c4e <check_page_free_list+0x2ac>
f0100c0c:	68 01 2c 10 f0       	push   $0xf0102c01
f0100c11:	68 82 2b 10 f0       	push   $0xf0102b82
f0100c16:	68 2f 02 00 00       	push   $0x22f
f0100c1b:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100c20:	e8 66 f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c25:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100c2a:	85 c0                	test   %eax,%eax
f0100c2c:	0f 85 9d fd ff ff    	jne    f01009cf <check_page_free_list+0x2d>
f0100c32:	e9 81 fd ff ff       	jmp    f01009b8 <check_page_free_list+0x16>
f0100c37:	83 3d 3c 45 11 f0 00 	cmpl   $0x0,0xf011453c
f0100c3e:	0f 84 74 fd ff ff    	je     f01009b8 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c44:	be 00 04 00 00       	mov    $0x400,%esi
f0100c49:	e9 cf fd ff ff       	jmp    f0100a1d <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c4e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c51:	5b                   	pop    %ebx
f0100c52:	5e                   	pop    %esi
f0100c53:	5f                   	pop    %edi
f0100c54:	5d                   	pop    %ebp
f0100c55:	c3                   	ret    

f0100c56 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c56:	55                   	push   %ebp
f0100c57:	89 e5                	mov    %esp,%ebp
f0100c59:	56                   	push   %esi
f0100c5a:	53                   	push   %ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!

	//  1) Mark physical page 0 as in use.
	pages[0].pp_ref = 1;
f0100c5b:	a1 6c 49 11 f0       	mov    0xf011496c,%eax
f0100c60:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;	
f0100c66:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	size_t i;
	//临界点是否等于可能存在问题
	for (i = 1; i < npages; i++) {
f0100c6c:	be 08 00 00 00       	mov    $0x8,%esi
f0100c71:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100c76:	e9 ab 00 00 00       	jmp    f0100d26 <page_init+0xd0>
	//  2) The rest of base memory
		if(i < npages_basemem){
f0100c7b:	3b 1d 40 45 11 f0    	cmp    0xf0114540,%ebx
f0100c81:	73 25                	jae    f0100ca8 <page_init+0x52>
			pages[i].pp_ref = 0;
f0100c83:	89 f0                	mov    %esi,%eax
f0100c85:	03 05 6c 49 11 f0    	add    0xf011496c,%eax
f0100c8b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100c91:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
f0100c97:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100c99:	89 f0                	mov    %esi,%eax
f0100c9b:	03 05 6c 49 11 f0    	add    0xf011496c,%eax
f0100ca1:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
f0100ca6:	eb 78                	jmp    f0100d20 <page_init+0xca>
		}
	//  3) Then comes the IO hole 
		else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE){
f0100ca8:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100cae:	83 f8 5f             	cmp    $0x5f,%eax
f0100cb1:	77 16                	ja     f0100cc9 <page_init+0x73>
			pages[i].pp_ref = 1;
f0100cb3:	89 f0                	mov    %esi,%eax
f0100cb5:	03 05 6c 49 11 f0    	add    0xf011496c,%eax
f0100cbb:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100cc1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100cc7:	eb 57                	jmp    f0100d20 <page_init+0xca>
		}
	//  4) Then extended memory
		else if(i >= EXTPHYSMEM/PGSIZE && i< ((int)boot_alloc(0) - KERNBASE)/PGSIZE){
f0100cc9:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100ccf:	76 2c                	jbe    f0100cfd <page_init+0xa7>
f0100cd1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cd6:	e8 29 fc ff ff       	call   f0100904 <boot_alloc>
f0100cdb:	05 00 00 00 10       	add    $0x10000000,%eax
f0100ce0:	c1 e8 0c             	shr    $0xc,%eax
f0100ce3:	39 c3                	cmp    %eax,%ebx
f0100ce5:	73 16                	jae    f0100cfd <page_init+0xa7>
			pages[i].pp_ref = 1;
f0100ce7:	89 f0                	mov    %esi,%eax
f0100ce9:	03 05 6c 49 11 f0    	add    0xf011496c,%eax
f0100cef:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100cf5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100cfb:	eb 23                	jmp    f0100d20 <page_init+0xca>
		}
		else{
			pages[i].pp_ref = 0;
f0100cfd:	89 f0                	mov    %esi,%eax
f0100cff:	03 05 6c 49 11 f0    	add    0xf011496c,%eax
f0100d05:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100d0b:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
f0100d11:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100d13:	89 f0                	mov    %esi,%eax
f0100d15:	03 05 6c 49 11 f0    	add    0xf011496c,%eax
f0100d1b:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
	//  1) Mark physical page 0 as in use.
	pages[0].pp_ref = 1;
	pages[0].pp_link = NULL;	
	size_t i;
	//临界点是否等于可能存在问题
	for (i = 1; i < npages; i++) {
f0100d20:	83 c3 01             	add    $0x1,%ebx
f0100d23:	83 c6 08             	add    $0x8,%esi
f0100d26:	3b 1d 64 49 11 f0    	cmp    0xf0114964,%ebx
f0100d2c:	0f 82 49 ff ff ff    	jb     f0100c7b <page_init+0x25>
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100d32:	5b                   	pop    %ebx
f0100d33:	5e                   	pop    %esi
f0100d34:	5d                   	pop    %ebp
f0100d35:	c3                   	ret    

f0100d36 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d36:	55                   	push   %ebp
f0100d37:	89 e5                	mov    %esp,%ebp
f0100d39:	53                   	push   %ebx
f0100d3a:	83 ec 04             	sub    $0x4,%esp
	// pages[i].pp_link = NULL;
	// return pages[i];
	//size_t addr;
	//cprintf("page_alloc\r\n");

	if(page_free_list == NULL)
f0100d3d:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f0100d43:	85 db                	test   %ebx,%ebx
f0100d45:	74 6e                	je     f0100db5 <page_alloc+0x7f>
		//addr = page2kva(page_free_list);
		//int *iq,*ip;
		//iq=ip;//将把ip中的值拷贝到iq中，这样，指针iq也将指向ip指向的对象
		struct PageInfo *Page;
		Page = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100d47:	8b 03                	mov    (%ebx),%eax
f0100d49:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
		//page_free_list->pp_link = NULL;
		Page->pp_link = NULL;
f0100d4e:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		Page->pp_ref = 1;
f0100d54:	66 c7 43 04 01 00    	movw   $0x1,0x4(%ebx)
		cprintf("page_alloc\r\n");
f0100d5a:	83 ec 0c             	sub    $0xc,%esp
f0100d5d:	68 12 2c 10 f0       	push   $0xf0102c12
f0100d62:	e8 a3 07 00 00       	call   f010150a <cprintf>
		if(alloc_flags & ALLOC_ZERO)
f0100d67:	83 c4 10             	add    $0x10,%esp
f0100d6a:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d6e:	74 45                	je     f0100db5 <page_alloc+0x7f>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d70:	89 d8                	mov    %ebx,%eax
f0100d72:	2b 05 6c 49 11 f0    	sub    0xf011496c,%eax
f0100d78:	c1 f8 03             	sar    $0x3,%eax
f0100d7b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d7e:	89 c2                	mov    %eax,%edx
f0100d80:	c1 ea 0c             	shr    $0xc,%edx
f0100d83:	3b 15 64 49 11 f0    	cmp    0xf0114964,%edx
f0100d89:	72 12                	jb     f0100d9d <page_alloc+0x67>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d8b:	50                   	push   %eax
f0100d8c:	68 a4 29 10 f0       	push   $0xf01029a4
f0100d91:	6a 52                	push   $0x52
f0100d93:	68 68 2b 10 f0       	push   $0xf0102b68
f0100d98:	e8 ee f2 ff ff       	call   f010008b <_panic>
			memset(page2kva(Page),'\0',PGSIZE);
f0100d9d:	83 ec 04             	sub    $0x4,%esp
f0100da0:	68 00 10 00 00       	push   $0x1000
f0100da5:	6a 00                	push   $0x0
f0100da7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dac:	50                   	push   %eax
f0100dad:	e8 0c 12 00 00       	call   f0101fbe <memset>
f0100db2:	83 c4 10             	add    $0x10,%esp
			// memset(page2kva(page_free_list),0,PGSIZE);
		return Page;
	}
}
f0100db5:	89 d8                	mov    %ebx,%eax
f0100db7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100dba:	c9                   	leave  
f0100dbb:	c3                   	ret    

f0100dbc <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100dbc:	55                   	push   %ebp
f0100dbd:	89 e5                	mov    %esp,%ebp
f0100dbf:	83 ec 14             	sub    $0x14,%esp
f0100dc2:	8b 45 08             	mov    0x8(%ebp),%eax
	//  	panic("can't free the page");
	//  	return;
	// }
	//	cprinf("can't free the page");
	//pp->pp_link = page_free_list->pp_link;	
	pp->pp_link = page_free_list;
f0100dc5:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
f0100dcb:	89 10                	mov    %edx,(%eax)
	//page_free_list->pp_link = pp;
	// page_free_list = &pp;
	page_free_list = pp;
f0100dcd:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
	//pp->pp_ref = 0;
	cprintf("page_free\r\n");
f0100dd2:	68 1f 2c 10 f0       	push   $0xf0102c1f
f0100dd7:	e8 2e 07 00 00       	call   f010150a <cprintf>
}
f0100ddc:	83 c4 10             	add    $0x10,%esp
f0100ddf:	c9                   	leave  
f0100de0:	c3                   	ret    

f0100de1 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100de1:	55                   	push   %ebp
f0100de2:	89 e5                	mov    %esp,%ebp
f0100de4:	57                   	push   %edi
f0100de5:	56                   	push   %esi
f0100de6:	53                   	push   %ebx
f0100de7:	83 ec 28             	sub    $0x28,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100dea:	6a 15                	push   $0x15
f0100dec:	e8 b2 06 00 00       	call   f01014a3 <mc146818_read>
f0100df1:	89 c3                	mov    %eax,%ebx
f0100df3:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0100dfa:	e8 a4 06 00 00       	call   f01014a3 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100dff:	c1 e0 08             	shl    $0x8,%eax
f0100e02:	09 d8                	or     %ebx,%eax
f0100e04:	c1 e0 0a             	shl    $0xa,%eax
f0100e07:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100e0d:	85 c0                	test   %eax,%eax
f0100e0f:	0f 48 c2             	cmovs  %edx,%eax
f0100e12:	c1 f8 0c             	sar    $0xc,%eax
f0100e15:	a3 40 45 11 f0       	mov    %eax,0xf0114540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100e1a:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0100e21:	e8 7d 06 00 00       	call   f01014a3 <mc146818_read>
f0100e26:	89 c3                	mov    %eax,%ebx
f0100e28:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0100e2f:	e8 6f 06 00 00       	call   f01014a3 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0100e34:	c1 e0 08             	shl    $0x8,%eax
f0100e37:	09 d8                	or     %ebx,%eax
f0100e39:	c1 e0 0a             	shl    $0xa,%eax
f0100e3c:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100e42:	83 c4 10             	add    $0x10,%esp
f0100e45:	85 c0                	test   %eax,%eax
f0100e47:	0f 48 c2             	cmovs  %edx,%eax
f0100e4a:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0100e4d:	85 c0                	test   %eax,%eax
f0100e4f:	74 0e                	je     f0100e5f <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0100e51:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0100e57:	89 15 64 49 11 f0    	mov    %edx,0xf0114964
f0100e5d:	eb 0c                	jmp    f0100e6b <mem_init+0x8a>
	else
		npages = npages_basemem;
f0100e5f:	8b 15 40 45 11 f0    	mov    0xf0114540,%edx
f0100e65:	89 15 64 49 11 f0    	mov    %edx,0xf0114964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100e6b:	c1 e0 0c             	shl    $0xc,%eax
f0100e6e:	c1 e8 0a             	shr    $0xa,%eax
f0100e71:	50                   	push   %eax
f0100e72:	a1 40 45 11 f0       	mov    0xf0114540,%eax
f0100e77:	c1 e0 0c             	shl    $0xc,%eax
f0100e7a:	c1 e8 0a             	shr    $0xa,%eax
f0100e7d:	50                   	push   %eax
f0100e7e:	a1 64 49 11 f0       	mov    0xf0114964,%eax
f0100e83:	c1 e0 0c             	shl    $0xc,%eax
f0100e86:	c1 e8 0a             	shr    $0xa,%eax
f0100e89:	50                   	push   %eax
f0100e8a:	68 8c 2a 10 f0       	push   $0xf0102a8c
f0100e8f:	e8 76 06 00 00       	call   f010150a <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100e94:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100e99:	e8 66 fa ff ff       	call   f0100904 <boot_alloc>
f0100e9e:	a3 68 49 11 f0       	mov    %eax,0xf0114968
	memset(kern_pgdir, 0, PGSIZE);
f0100ea3:	83 c4 0c             	add    $0xc,%esp
f0100ea6:	68 00 10 00 00       	push   $0x1000
f0100eab:	6a 00                	push   $0x0
f0100ead:	50                   	push   %eax
f0100eae:	e8 0b 11 00 00       	call   f0101fbe <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100eb3:	a1 68 49 11 f0       	mov    0xf0114968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100eb8:	83 c4 10             	add    $0x10,%esp
f0100ebb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100ec0:	77 15                	ja     f0100ed7 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ec2:	50                   	push   %eax
f0100ec3:	68 c8 2a 10 f0       	push   $0xf0102ac8
f0100ec8:	68 8d 00 00 00       	push   $0x8d
f0100ecd:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100ed2:	e8 b4 f1 ff ff       	call   f010008b <_panic>
f0100ed7:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100edd:	83 ca 05             	or     $0x5,%edx
f0100ee0:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f0100ee6:	a1 64 49 11 f0       	mov    0xf0114964,%eax
f0100eeb:	c1 e0 03             	shl    $0x3,%eax
f0100eee:	e8 11 fa ff ff       	call   f0100904 <boot_alloc>
f0100ef3:	a3 6c 49 11 f0       	mov    %eax,0xf011496c
	memset(pages,0,npages * sizeof(struct PageInfo));
f0100ef8:	83 ec 04             	sub    $0x4,%esp
f0100efb:	8b 0d 64 49 11 f0    	mov    0xf0114964,%ecx
f0100f01:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0100f08:	52                   	push   %edx
f0100f09:	6a 00                	push   $0x0
f0100f0b:	50                   	push   %eax
f0100f0c:	e8 ad 10 00 00       	call   f0101fbe <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0100f11:	e8 40 fd ff ff       	call   f0100c56 <page_init>

	check_page_free_list(1);
f0100f16:	b8 01 00 00 00       	mov    $0x1,%eax
f0100f1b:	e8 82 fa ff ff       	call   f01009a2 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0100f20:	83 c4 10             	add    $0x10,%esp
f0100f23:	83 3d 6c 49 11 f0 00 	cmpl   $0x0,0xf011496c
f0100f2a:	75 17                	jne    f0100f43 <mem_init+0x162>
		panic("'pages' is a null pointer!");
f0100f2c:	83 ec 04             	sub    $0x4,%esp
f0100f2f:	68 2b 2c 10 f0       	push   $0xf0102c2b
f0100f34:	68 40 02 00 00       	push   $0x240
f0100f39:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100f3e:	e8 48 f1 ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100f43:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100f48:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100f4d:	eb 05                	jmp    f0100f54 <mem_init+0x173>
		++nfree;
f0100f4f:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100f52:	8b 00                	mov    (%eax),%eax
f0100f54:	85 c0                	test   %eax,%eax
f0100f56:	75 f7                	jne    f0100f4f <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0100f58:	83 ec 0c             	sub    $0xc,%esp
f0100f5b:	6a 00                	push   $0x0
f0100f5d:	e8 d4 fd ff ff       	call   f0100d36 <page_alloc>
f0100f62:	89 c7                	mov    %eax,%edi
f0100f64:	83 c4 10             	add    $0x10,%esp
f0100f67:	85 c0                	test   %eax,%eax
f0100f69:	75 19                	jne    f0100f84 <mem_init+0x1a3>
f0100f6b:	68 46 2c 10 f0       	push   $0xf0102c46
f0100f70:	68 82 2b 10 f0       	push   $0xf0102b82
f0100f75:	68 48 02 00 00       	push   $0x248
f0100f7a:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100f7f:	e8 07 f1 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0100f84:	83 ec 0c             	sub    $0xc,%esp
f0100f87:	6a 00                	push   $0x0
f0100f89:	e8 a8 fd ff ff       	call   f0100d36 <page_alloc>
f0100f8e:	89 c6                	mov    %eax,%esi
f0100f90:	83 c4 10             	add    $0x10,%esp
f0100f93:	85 c0                	test   %eax,%eax
f0100f95:	75 19                	jne    f0100fb0 <mem_init+0x1cf>
f0100f97:	68 5c 2c 10 f0       	push   $0xf0102c5c
f0100f9c:	68 82 2b 10 f0       	push   $0xf0102b82
f0100fa1:	68 49 02 00 00       	push   $0x249
f0100fa6:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100fab:	e8 db f0 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0100fb0:	83 ec 0c             	sub    $0xc,%esp
f0100fb3:	6a 00                	push   $0x0
f0100fb5:	e8 7c fd ff ff       	call   f0100d36 <page_alloc>
f0100fba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100fbd:	83 c4 10             	add    $0x10,%esp
f0100fc0:	85 c0                	test   %eax,%eax
f0100fc2:	75 19                	jne    f0100fdd <mem_init+0x1fc>
f0100fc4:	68 72 2c 10 f0       	push   $0xf0102c72
f0100fc9:	68 82 2b 10 f0       	push   $0xf0102b82
f0100fce:	68 4a 02 00 00       	push   $0x24a
f0100fd3:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100fd8:	e8 ae f0 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0100fdd:	39 f7                	cmp    %esi,%edi
f0100fdf:	75 19                	jne    f0100ffa <mem_init+0x219>
f0100fe1:	68 88 2c 10 f0       	push   $0xf0102c88
f0100fe6:	68 82 2b 10 f0       	push   $0xf0102b82
f0100feb:	68 4d 02 00 00       	push   $0x24d
f0100ff0:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0100ff5:	e8 91 f0 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0100ffa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ffd:	39 c7                	cmp    %eax,%edi
f0100fff:	74 04                	je     f0101005 <mem_init+0x224>
f0101001:	39 c6                	cmp    %eax,%esi
f0101003:	75 19                	jne    f010101e <mem_init+0x23d>
f0101005:	68 ec 2a 10 f0       	push   $0xf0102aec
f010100a:	68 82 2b 10 f0       	push   $0xf0102b82
f010100f:	68 4e 02 00 00       	push   $0x24e
f0101014:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0101019:	e8 6d f0 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010101e:	8b 0d 6c 49 11 f0    	mov    0xf011496c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101024:	8b 15 64 49 11 f0    	mov    0xf0114964,%edx
f010102a:	c1 e2 0c             	shl    $0xc,%edx
f010102d:	89 f8                	mov    %edi,%eax
f010102f:	29 c8                	sub    %ecx,%eax
f0101031:	c1 f8 03             	sar    $0x3,%eax
f0101034:	c1 e0 0c             	shl    $0xc,%eax
f0101037:	39 d0                	cmp    %edx,%eax
f0101039:	72 19                	jb     f0101054 <mem_init+0x273>
f010103b:	68 9a 2c 10 f0       	push   $0xf0102c9a
f0101040:	68 82 2b 10 f0       	push   $0xf0102b82
f0101045:	68 4f 02 00 00       	push   $0x24f
f010104a:	68 5c 2b 10 f0       	push   $0xf0102b5c
f010104f:	e8 37 f0 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101054:	89 f0                	mov    %esi,%eax
f0101056:	29 c8                	sub    %ecx,%eax
f0101058:	c1 f8 03             	sar    $0x3,%eax
f010105b:	c1 e0 0c             	shl    $0xc,%eax
f010105e:	39 c2                	cmp    %eax,%edx
f0101060:	77 19                	ja     f010107b <mem_init+0x29a>
f0101062:	68 b7 2c 10 f0       	push   $0xf0102cb7
f0101067:	68 82 2b 10 f0       	push   $0xf0102b82
f010106c:	68 50 02 00 00       	push   $0x250
f0101071:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0101076:	e8 10 f0 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010107b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010107e:	29 c8                	sub    %ecx,%eax
f0101080:	c1 f8 03             	sar    $0x3,%eax
f0101083:	c1 e0 0c             	shl    $0xc,%eax
f0101086:	39 c2                	cmp    %eax,%edx
f0101088:	77 19                	ja     f01010a3 <mem_init+0x2c2>
f010108a:	68 d4 2c 10 f0       	push   $0xf0102cd4
f010108f:	68 82 2b 10 f0       	push   $0xf0102b82
f0101094:	68 51 02 00 00       	push   $0x251
f0101099:	68 5c 2b 10 f0       	push   $0xf0102b5c
f010109e:	e8 e8 ef ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01010a3:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f01010a8:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f01010ab:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f01010b2:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01010b5:	83 ec 0c             	sub    $0xc,%esp
f01010b8:	6a 00                	push   $0x0
f01010ba:	e8 77 fc ff ff       	call   f0100d36 <page_alloc>
f01010bf:	83 c4 10             	add    $0x10,%esp
f01010c2:	85 c0                	test   %eax,%eax
f01010c4:	74 19                	je     f01010df <mem_init+0x2fe>
f01010c6:	68 f1 2c 10 f0       	push   $0xf0102cf1
f01010cb:	68 82 2b 10 f0       	push   $0xf0102b82
f01010d0:	68 58 02 00 00       	push   $0x258
f01010d5:	68 5c 2b 10 f0       	push   $0xf0102b5c
f01010da:	e8 ac ef ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01010df:	83 ec 0c             	sub    $0xc,%esp
f01010e2:	57                   	push   %edi
f01010e3:	e8 d4 fc ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f01010e8:	89 34 24             	mov    %esi,(%esp)
f01010eb:	e8 cc fc ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f01010f0:	83 c4 04             	add    $0x4,%esp
f01010f3:	ff 75 e4             	pushl  -0x1c(%ebp)
f01010f6:	e8 c1 fc ff ff       	call   f0100dbc <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01010fb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101102:	e8 2f fc ff ff       	call   f0100d36 <page_alloc>
f0101107:	89 c6                	mov    %eax,%esi
f0101109:	83 c4 10             	add    $0x10,%esp
f010110c:	85 c0                	test   %eax,%eax
f010110e:	75 19                	jne    f0101129 <mem_init+0x348>
f0101110:	68 46 2c 10 f0       	push   $0xf0102c46
f0101115:	68 82 2b 10 f0       	push   $0xf0102b82
f010111a:	68 5f 02 00 00       	push   $0x25f
f010111f:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0101124:	e8 62 ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101129:	83 ec 0c             	sub    $0xc,%esp
f010112c:	6a 00                	push   $0x0
f010112e:	e8 03 fc ff ff       	call   f0100d36 <page_alloc>
f0101133:	89 c7                	mov    %eax,%edi
f0101135:	83 c4 10             	add    $0x10,%esp
f0101138:	85 c0                	test   %eax,%eax
f010113a:	75 19                	jne    f0101155 <mem_init+0x374>
f010113c:	68 5c 2c 10 f0       	push   $0xf0102c5c
f0101141:	68 82 2b 10 f0       	push   $0xf0102b82
f0101146:	68 60 02 00 00       	push   $0x260
f010114b:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0101150:	e8 36 ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101155:	83 ec 0c             	sub    $0xc,%esp
f0101158:	6a 00                	push   $0x0
f010115a:	e8 d7 fb ff ff       	call   f0100d36 <page_alloc>
f010115f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101162:	83 c4 10             	add    $0x10,%esp
f0101165:	85 c0                	test   %eax,%eax
f0101167:	75 19                	jne    f0101182 <mem_init+0x3a1>
f0101169:	68 72 2c 10 f0       	push   $0xf0102c72
f010116e:	68 82 2b 10 f0       	push   $0xf0102b82
f0101173:	68 61 02 00 00       	push   $0x261
f0101178:	68 5c 2b 10 f0       	push   $0xf0102b5c
f010117d:	e8 09 ef ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101182:	39 fe                	cmp    %edi,%esi
f0101184:	75 19                	jne    f010119f <mem_init+0x3be>
f0101186:	68 88 2c 10 f0       	push   $0xf0102c88
f010118b:	68 82 2b 10 f0       	push   $0xf0102b82
f0101190:	68 63 02 00 00       	push   $0x263
f0101195:	68 5c 2b 10 f0       	push   $0xf0102b5c
f010119a:	e8 ec ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010119f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01011a2:	39 c7                	cmp    %eax,%edi
f01011a4:	74 04                	je     f01011aa <mem_init+0x3c9>
f01011a6:	39 c6                	cmp    %eax,%esi
f01011a8:	75 19                	jne    f01011c3 <mem_init+0x3e2>
f01011aa:	68 ec 2a 10 f0       	push   $0xf0102aec
f01011af:	68 82 2b 10 f0       	push   $0xf0102b82
f01011b4:	68 64 02 00 00       	push   $0x264
f01011b9:	68 5c 2b 10 f0       	push   $0xf0102b5c
f01011be:	e8 c8 ee ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01011c3:	83 ec 0c             	sub    $0xc,%esp
f01011c6:	6a 00                	push   $0x0
f01011c8:	e8 69 fb ff ff       	call   f0100d36 <page_alloc>
f01011cd:	83 c4 10             	add    $0x10,%esp
f01011d0:	85 c0                	test   %eax,%eax
f01011d2:	74 19                	je     f01011ed <mem_init+0x40c>
f01011d4:	68 f1 2c 10 f0       	push   $0xf0102cf1
f01011d9:	68 82 2b 10 f0       	push   $0xf0102b82
f01011de:	68 65 02 00 00       	push   $0x265
f01011e3:	68 5c 2b 10 f0       	push   $0xf0102b5c
f01011e8:	e8 9e ee ff ff       	call   f010008b <_panic>
f01011ed:	89 f0                	mov    %esi,%eax
f01011ef:	2b 05 6c 49 11 f0    	sub    0xf011496c,%eax
f01011f5:	c1 f8 03             	sar    $0x3,%eax
f01011f8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011fb:	89 c2                	mov    %eax,%edx
f01011fd:	c1 ea 0c             	shr    $0xc,%edx
f0101200:	3b 15 64 49 11 f0    	cmp    0xf0114964,%edx
f0101206:	72 12                	jb     f010121a <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101208:	50                   	push   %eax
f0101209:	68 a4 29 10 f0       	push   $0xf01029a4
f010120e:	6a 52                	push   $0x52
f0101210:	68 68 2b 10 f0       	push   $0xf0102b68
f0101215:	e8 71 ee ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010121a:	83 ec 04             	sub    $0x4,%esp
f010121d:	68 00 10 00 00       	push   $0x1000
f0101222:	6a 01                	push   $0x1
f0101224:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101229:	50                   	push   %eax
f010122a:	e8 8f 0d 00 00       	call   f0101fbe <memset>
	page_free(pp0);
f010122f:	89 34 24             	mov    %esi,(%esp)
f0101232:	e8 85 fb ff ff       	call   f0100dbc <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101237:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010123e:	e8 f3 fa ff ff       	call   f0100d36 <page_alloc>
f0101243:	83 c4 10             	add    $0x10,%esp
f0101246:	85 c0                	test   %eax,%eax
f0101248:	75 19                	jne    f0101263 <mem_init+0x482>
f010124a:	68 00 2d 10 f0       	push   $0xf0102d00
f010124f:	68 82 2b 10 f0       	push   $0xf0102b82
f0101254:	68 6a 02 00 00       	push   $0x26a
f0101259:	68 5c 2b 10 f0       	push   $0xf0102b5c
f010125e:	e8 28 ee ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101263:	39 c6                	cmp    %eax,%esi
f0101265:	74 19                	je     f0101280 <mem_init+0x49f>
f0101267:	68 1e 2d 10 f0       	push   $0xf0102d1e
f010126c:	68 82 2b 10 f0       	push   $0xf0102b82
f0101271:	68 6b 02 00 00       	push   $0x26b
f0101276:	68 5c 2b 10 f0       	push   $0xf0102b5c
f010127b:	e8 0b ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101280:	89 f0                	mov    %esi,%eax
f0101282:	2b 05 6c 49 11 f0    	sub    0xf011496c,%eax
f0101288:	c1 f8 03             	sar    $0x3,%eax
f010128b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010128e:	89 c2                	mov    %eax,%edx
f0101290:	c1 ea 0c             	shr    $0xc,%edx
f0101293:	3b 15 64 49 11 f0    	cmp    0xf0114964,%edx
f0101299:	72 12                	jb     f01012ad <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010129b:	50                   	push   %eax
f010129c:	68 a4 29 10 f0       	push   $0xf01029a4
f01012a1:	6a 52                	push   $0x52
f01012a3:	68 68 2b 10 f0       	push   $0xf0102b68
f01012a8:	e8 de ed ff ff       	call   f010008b <_panic>
f01012ad:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01012b3:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01012b9:	80 38 00             	cmpb   $0x0,(%eax)
f01012bc:	74 19                	je     f01012d7 <mem_init+0x4f6>
f01012be:	68 2e 2d 10 f0       	push   $0xf0102d2e
f01012c3:	68 82 2b 10 f0       	push   $0xf0102b82
f01012c8:	68 6e 02 00 00       	push   $0x26e
f01012cd:	68 5c 2b 10 f0       	push   $0xf0102b5c
f01012d2:	e8 b4 ed ff ff       	call   f010008b <_panic>
f01012d7:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01012da:	39 d0                	cmp    %edx,%eax
f01012dc:	75 db                	jne    f01012b9 <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01012de:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01012e1:	a3 3c 45 11 f0       	mov    %eax,0xf011453c

	// free the pages we took
	page_free(pp0);
f01012e6:	83 ec 0c             	sub    $0xc,%esp
f01012e9:	56                   	push   %esi
f01012ea:	e8 cd fa ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f01012ef:	89 3c 24             	mov    %edi,(%esp)
f01012f2:	e8 c5 fa ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f01012f7:	83 c4 04             	add    $0x4,%esp
f01012fa:	ff 75 e4             	pushl  -0x1c(%ebp)
f01012fd:	e8 ba fa ff ff       	call   f0100dbc <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101302:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0101307:	83 c4 10             	add    $0x10,%esp
f010130a:	eb 05                	jmp    f0101311 <mem_init+0x530>
		--nfree;
f010130c:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010130f:	8b 00                	mov    (%eax),%eax
f0101311:	85 c0                	test   %eax,%eax
f0101313:	75 f7                	jne    f010130c <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f0101315:	85 db                	test   %ebx,%ebx
f0101317:	74 19                	je     f0101332 <mem_init+0x551>
f0101319:	68 38 2d 10 f0       	push   $0xf0102d38
f010131e:	68 82 2b 10 f0       	push   $0xf0102b82
f0101323:	68 7b 02 00 00       	push   $0x27b
f0101328:	68 5c 2b 10 f0       	push   $0xf0102b5c
f010132d:	e8 59 ed ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101332:	83 ec 0c             	sub    $0xc,%esp
f0101335:	68 0c 2b 10 f0       	push   $0xf0102b0c
f010133a:	e8 cb 01 00 00       	call   f010150a <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010133f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101346:	e8 eb f9 ff ff       	call   f0100d36 <page_alloc>
f010134b:	89 c3                	mov    %eax,%ebx
f010134d:	83 c4 10             	add    $0x10,%esp
f0101350:	85 c0                	test   %eax,%eax
f0101352:	75 19                	jne    f010136d <mem_init+0x58c>
f0101354:	68 46 2c 10 f0       	push   $0xf0102c46
f0101359:	68 82 2b 10 f0       	push   $0xf0102b82
f010135e:	68 d4 02 00 00       	push   $0x2d4
f0101363:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0101368:	e8 1e ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010136d:	83 ec 0c             	sub    $0xc,%esp
f0101370:	6a 00                	push   $0x0
f0101372:	e8 bf f9 ff ff       	call   f0100d36 <page_alloc>
f0101377:	89 c6                	mov    %eax,%esi
f0101379:	83 c4 10             	add    $0x10,%esp
f010137c:	85 c0                	test   %eax,%eax
f010137e:	75 19                	jne    f0101399 <mem_init+0x5b8>
f0101380:	68 5c 2c 10 f0       	push   $0xf0102c5c
f0101385:	68 82 2b 10 f0       	push   $0xf0102b82
f010138a:	68 d5 02 00 00       	push   $0x2d5
f010138f:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0101394:	e8 f2 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101399:	83 ec 0c             	sub    $0xc,%esp
f010139c:	6a 00                	push   $0x0
f010139e:	e8 93 f9 ff ff       	call   f0100d36 <page_alloc>
f01013a3:	83 c4 10             	add    $0x10,%esp
f01013a6:	85 c0                	test   %eax,%eax
f01013a8:	75 19                	jne    f01013c3 <mem_init+0x5e2>
f01013aa:	68 72 2c 10 f0       	push   $0xf0102c72
f01013af:	68 82 2b 10 f0       	push   $0xf0102b82
f01013b4:	68 d6 02 00 00       	push   $0x2d6
f01013b9:	68 5c 2b 10 f0       	push   $0xf0102b5c
f01013be:	e8 c8 ec ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013c3:	39 f3                	cmp    %esi,%ebx
f01013c5:	75 19                	jne    f01013e0 <mem_init+0x5ff>
f01013c7:	68 88 2c 10 f0       	push   $0xf0102c88
f01013cc:	68 82 2b 10 f0       	push   $0xf0102b82
f01013d1:	68 d9 02 00 00       	push   $0x2d9
f01013d6:	68 5c 2b 10 f0       	push   $0xf0102b5c
f01013db:	e8 ab ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013e0:	39 c6                	cmp    %eax,%esi
f01013e2:	74 04                	je     f01013e8 <mem_init+0x607>
f01013e4:	39 c3                	cmp    %eax,%ebx
f01013e6:	75 19                	jne    f0101401 <mem_init+0x620>
f01013e8:	68 ec 2a 10 f0       	push   $0xf0102aec
f01013ed:	68 82 2b 10 f0       	push   $0xf0102b82
f01013f2:	68 da 02 00 00       	push   $0x2da
f01013f7:	68 5c 2b 10 f0       	push   $0xf0102b5c
f01013fc:	e8 8a ec ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f0101401:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f0101408:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010140b:	83 ec 0c             	sub    $0xc,%esp
f010140e:	6a 00                	push   $0x0
f0101410:	e8 21 f9 ff ff       	call   f0100d36 <page_alloc>
f0101415:	83 c4 10             	add    $0x10,%esp
f0101418:	85 c0                	test   %eax,%eax
f010141a:	74 19                	je     f0101435 <mem_init+0x654>
f010141c:	68 f1 2c 10 f0       	push   $0xf0102cf1
f0101421:	68 82 2b 10 f0       	push   $0xf0102b82
f0101426:	68 e1 02 00 00       	push   $0x2e1
f010142b:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0101430:	e8 56 ec ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101435:	68 2c 2b 10 f0       	push   $0xf0102b2c
f010143a:	68 82 2b 10 f0       	push   $0xf0102b82
f010143f:	68 e7 02 00 00       	push   $0x2e7
f0101444:	68 5c 2b 10 f0       	push   $0xf0102b5c
f0101449:	e8 3d ec ff ff       	call   f010008b <_panic>

f010144e <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f010144e:	55                   	push   %ebp
f010144f:	89 e5                	mov    %esp,%ebp
f0101451:	83 ec 08             	sub    $0x8,%esp
f0101454:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101457:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010145b:	83 e8 01             	sub    $0x1,%eax
f010145e:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101462:	66 85 c0             	test   %ax,%ax
f0101465:	75 0c                	jne    f0101473 <page_decref+0x25>
		page_free(pp);
f0101467:	83 ec 0c             	sub    $0xc,%esp
f010146a:	52                   	push   %edx
f010146b:	e8 4c f9 ff ff       	call   f0100dbc <page_free>
f0101470:	83 c4 10             	add    $0x10,%esp
}
f0101473:	c9                   	leave  
f0101474:	c3                   	ret    

f0101475 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101475:	55                   	push   %ebp
f0101476:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0101478:	b8 00 00 00 00       	mov    $0x0,%eax
f010147d:	5d                   	pop    %ebp
f010147e:	c3                   	ret    

f010147f <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010147f:	55                   	push   %ebp
f0101480:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0101482:	b8 00 00 00 00       	mov    $0x0,%eax
f0101487:	5d                   	pop    %ebp
f0101488:	c3                   	ret    

f0101489 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101489:	55                   	push   %ebp
f010148a:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f010148c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101491:	5d                   	pop    %ebp
f0101492:	c3                   	ret    

f0101493 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101493:	55                   	push   %ebp
f0101494:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0101496:	5d                   	pop    %ebp
f0101497:	c3                   	ret    

f0101498 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101498:	55                   	push   %ebp
f0101499:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010149b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010149e:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01014a1:	5d                   	pop    %ebp
f01014a2:	c3                   	ret    

f01014a3 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01014a3:	55                   	push   %ebp
f01014a4:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01014a6:	ba 70 00 00 00       	mov    $0x70,%edx
f01014ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01014ae:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01014af:	ba 71 00 00 00       	mov    $0x71,%edx
f01014b4:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01014b5:	0f b6 c0             	movzbl %al,%eax
}
f01014b8:	5d                   	pop    %ebp
f01014b9:	c3                   	ret    

f01014ba <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01014ba:	55                   	push   %ebp
f01014bb:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01014bd:	ba 70 00 00 00       	mov    $0x70,%edx
f01014c2:	8b 45 08             	mov    0x8(%ebp),%eax
f01014c5:	ee                   	out    %al,(%dx)
f01014c6:	ba 71 00 00 00       	mov    $0x71,%edx
f01014cb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014ce:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01014cf:	5d                   	pop    %ebp
f01014d0:	c3                   	ret    

f01014d1 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01014d1:	55                   	push   %ebp
f01014d2:	89 e5                	mov    %esp,%ebp
f01014d4:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01014d7:	ff 75 08             	pushl  0x8(%ebp)
f01014da:	e8 46 f1 ff ff       	call   f0100625 <cputchar>
	*cnt++;
}
f01014df:	83 c4 10             	add    $0x10,%esp
f01014e2:	c9                   	leave  
f01014e3:	c3                   	ret    

f01014e4 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01014e4:	55                   	push   %ebp
f01014e5:	89 e5                	mov    %esp,%ebp
f01014e7:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01014ea:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01014f1:	ff 75 0c             	pushl  0xc(%ebp)
f01014f4:	ff 75 08             	pushl  0x8(%ebp)
f01014f7:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01014fa:	50                   	push   %eax
f01014fb:	68 d1 14 10 f0       	push   $0xf01014d1
f0101500:	e8 4d 04 00 00       	call   f0101952 <vprintfmt>
	return cnt;
}
f0101505:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101508:	c9                   	leave  
f0101509:	c3                   	ret    

f010150a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010150a:	55                   	push   %ebp
f010150b:	89 e5                	mov    %esp,%ebp
f010150d:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0101510:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101513:	50                   	push   %eax
f0101514:	ff 75 08             	pushl  0x8(%ebp)
f0101517:	e8 c8 ff ff ff       	call   f01014e4 <vcprintf>
	va_end(ap);

	return cnt;
}
f010151c:	c9                   	leave  
f010151d:	c3                   	ret    

f010151e <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010151e:	55                   	push   %ebp
f010151f:	89 e5                	mov    %esp,%ebp
f0101521:	57                   	push   %edi
f0101522:	56                   	push   %esi
f0101523:	53                   	push   %ebx
f0101524:	83 ec 14             	sub    $0x14,%esp
f0101527:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010152a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010152d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101530:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101533:	8b 1a                	mov    (%edx),%ebx
f0101535:	8b 01                	mov    (%ecx),%eax
f0101537:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010153a:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0101541:	eb 7f                	jmp    f01015c2 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0101543:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101546:	01 d8                	add    %ebx,%eax
f0101548:	89 c6                	mov    %eax,%esi
f010154a:	c1 ee 1f             	shr    $0x1f,%esi
f010154d:	01 c6                	add    %eax,%esi
f010154f:	d1 fe                	sar    %esi
f0101551:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0101554:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101557:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010155a:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010155c:	eb 03                	jmp    f0101561 <stab_binsearch+0x43>
			m--;
f010155e:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101561:	39 c3                	cmp    %eax,%ebx
f0101563:	7f 0d                	jg     f0101572 <stab_binsearch+0x54>
f0101565:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0101569:	83 ea 0c             	sub    $0xc,%edx
f010156c:	39 f9                	cmp    %edi,%ecx
f010156e:	75 ee                	jne    f010155e <stab_binsearch+0x40>
f0101570:	eb 05                	jmp    f0101577 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0101572:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0101575:	eb 4b                	jmp    f01015c2 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0101577:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010157a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010157d:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0101581:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0101584:	76 11                	jbe    f0101597 <stab_binsearch+0x79>
			*region_left = m;
f0101586:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101589:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010158b:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010158e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0101595:	eb 2b                	jmp    f01015c2 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0101597:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010159a:	73 14                	jae    f01015b0 <stab_binsearch+0x92>
			*region_right = m - 1;
f010159c:	83 e8 01             	sub    $0x1,%eax
f010159f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01015a2:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01015a5:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01015a7:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01015ae:	eb 12                	jmp    f01015c2 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01015b0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01015b3:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01015b5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01015b9:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01015bb:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01015c2:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01015c5:	0f 8e 78 ff ff ff    	jle    f0101543 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01015cb:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01015cf:	75 0f                	jne    f01015e0 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01015d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01015d4:	8b 00                	mov    (%eax),%eax
f01015d6:	83 e8 01             	sub    $0x1,%eax
f01015d9:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01015dc:	89 06                	mov    %eax,(%esi)
f01015de:	eb 2c                	jmp    f010160c <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01015e0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01015e3:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01015e5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01015e8:	8b 0e                	mov    (%esi),%ecx
f01015ea:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01015ed:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01015f0:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01015f3:	eb 03                	jmp    f01015f8 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01015f5:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01015f8:	39 c8                	cmp    %ecx,%eax
f01015fa:	7e 0b                	jle    f0101607 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01015fc:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0101600:	83 ea 0c             	sub    $0xc,%edx
f0101603:	39 df                	cmp    %ebx,%edi
f0101605:	75 ee                	jne    f01015f5 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0101607:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010160a:	89 06                	mov    %eax,(%esi)
	}
}
f010160c:	83 c4 14             	add    $0x14,%esp
f010160f:	5b                   	pop    %ebx
f0101610:	5e                   	pop    %esi
f0101611:	5f                   	pop    %edi
f0101612:	5d                   	pop    %ebp
f0101613:	c3                   	ret    

f0101614 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0101614:	55                   	push   %ebp
f0101615:	89 e5                	mov    %esp,%ebp
f0101617:	57                   	push   %edi
f0101618:	56                   	push   %esi
f0101619:	53                   	push   %ebx
f010161a:	83 ec 2c             	sub    $0x2c,%esp
f010161d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101620:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101623:	c7 06 43 2d 10 f0    	movl   $0xf0102d43,(%esi)
	info->eip_line = 0;
f0101629:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0101630:	c7 46 08 43 2d 10 f0 	movl   $0xf0102d43,0x8(%esi)
	info->eip_fn_namelen = 9;
f0101637:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010163e:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0101641:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101648:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010164e:	76 11                	jbe    f0101661 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101650:	b8 74 97 10 f0       	mov    $0xf0109774,%eax
f0101655:	3d 79 7a 10 f0       	cmp    $0xf0107a79,%eax
f010165a:	77 19                	ja     f0101675 <debuginfo_eip+0x61>
f010165c:	e9 a5 01 00 00       	jmp    f0101806 <debuginfo_eip+0x1f2>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0101661:	83 ec 04             	sub    $0x4,%esp
f0101664:	68 4d 2d 10 f0       	push   $0xf0102d4d
f0101669:	6a 7f                	push   $0x7f
f010166b:	68 5a 2d 10 f0       	push   $0xf0102d5a
f0101670:	e8 16 ea ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101675:	80 3d 73 97 10 f0 00 	cmpb   $0x0,0xf0109773
f010167c:	0f 85 8b 01 00 00    	jne    f010180d <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0101682:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0101689:	b8 78 7a 10 f0       	mov    $0xf0107a78,%eax
f010168e:	2d 90 2f 10 f0       	sub    $0xf0102f90,%eax
f0101693:	c1 f8 02             	sar    $0x2,%eax
f0101696:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010169c:	83 e8 01             	sub    $0x1,%eax
f010169f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01016a2:	83 ec 08             	sub    $0x8,%esp
f01016a5:	57                   	push   %edi
f01016a6:	6a 64                	push   $0x64
f01016a8:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01016ab:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01016ae:	b8 90 2f 10 f0       	mov    $0xf0102f90,%eax
f01016b3:	e8 66 fe ff ff       	call   f010151e <stab_binsearch>
	if (lfile == 0)
f01016b8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01016bb:	83 c4 10             	add    $0x10,%esp
f01016be:	85 c0                	test   %eax,%eax
f01016c0:	0f 84 4e 01 00 00    	je     f0101814 <debuginfo_eip+0x200>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01016c6:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01016c9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01016cc:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01016cf:	83 ec 08             	sub    $0x8,%esp
f01016d2:	57                   	push   %edi
f01016d3:	6a 24                	push   $0x24
f01016d5:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01016d8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01016db:	b8 90 2f 10 f0       	mov    $0xf0102f90,%eax
f01016e0:	e8 39 fe ff ff       	call   f010151e <stab_binsearch>

	if (lfun <= rfun) {
f01016e5:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01016e8:	83 c4 10             	add    $0x10,%esp
f01016eb:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f01016ee:	7f 33                	jg     f0101723 <debuginfo_eip+0x10f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01016f0:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01016f3:	c1 e0 02             	shl    $0x2,%eax
f01016f6:	8d 90 90 2f 10 f0    	lea    -0xfefd070(%eax),%edx
f01016fc:	8b 88 90 2f 10 f0    	mov    -0xfefd070(%eax),%ecx
f0101702:	b8 74 97 10 f0       	mov    $0xf0109774,%eax
f0101707:	2d 79 7a 10 f0       	sub    $0xf0107a79,%eax
f010170c:	39 c1                	cmp    %eax,%ecx
f010170e:	73 09                	jae    f0101719 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0101710:	81 c1 79 7a 10 f0    	add    $0xf0107a79,%ecx
f0101716:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0101719:	8b 42 08             	mov    0x8(%edx),%eax
f010171c:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f010171f:	29 c7                	sub    %eax,%edi
f0101721:	eb 06                	jmp    f0101729 <debuginfo_eip+0x115>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0101723:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0101726:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101729:	83 ec 08             	sub    $0x8,%esp
f010172c:	6a 3a                	push   $0x3a
f010172e:	ff 76 08             	pushl  0x8(%esi)
f0101731:	e8 6c 08 00 00       	call   f0101fa2 <strfind>
f0101736:	2b 46 08             	sub    0x8(%esi),%eax
f0101739:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
f010173c:	83 c4 08             	add    $0x8,%esp
f010173f:	2b 7e 10             	sub    0x10(%esi),%edi
f0101742:	57                   	push   %edi
f0101743:	6a 44                	push   $0x44
f0101745:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0101748:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010174b:	b8 90 2f 10 f0       	mov    $0xf0102f90,%eax
f0101750:	e8 c9 fd ff ff       	call   f010151e <stab_binsearch>
	if (lfun > rfun) 
f0101755:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101758:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010175b:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f010175e:	83 c4 10             	add    $0x10,%esp
f0101761:	39 c8                	cmp    %ecx,%eax
f0101763:	0f 8f b2 00 00 00    	jg     f010181b <debuginfo_eip+0x207>
       	  return -1;
        info->eip_line = stabs[lfun].n_desc;
f0101769:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010176c:	8d 04 85 90 2f 10 f0 	lea    -0xfefd070(,%eax,4),%eax
f0101773:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101776:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f010177a:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010177d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101780:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0101783:	8d 04 85 90 2f 10 f0 	lea    -0xfefd070(,%eax,4),%eax
f010178a:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f010178d:	eb 06                	jmp    f0101795 <debuginfo_eip+0x181>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010178f:	83 eb 01             	sub    $0x1,%ebx
f0101792:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101795:	39 fb                	cmp    %edi,%ebx
f0101797:	7c 39                	jl     f01017d2 <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f0101799:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f010179d:	80 fa 84             	cmp    $0x84,%dl
f01017a0:	74 0b                	je     f01017ad <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01017a2:	80 fa 64             	cmp    $0x64,%dl
f01017a5:	75 e8                	jne    f010178f <debuginfo_eip+0x17b>
f01017a7:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01017ab:	74 e2                	je     f010178f <debuginfo_eip+0x17b>
f01017ad:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01017b0:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01017b3:	8b 14 85 90 2f 10 f0 	mov    -0xfefd070(,%eax,4),%edx
f01017ba:	b8 74 97 10 f0       	mov    $0xf0109774,%eax
f01017bf:	2d 79 7a 10 f0       	sub    $0xf0107a79,%eax
f01017c4:	39 c2                	cmp    %eax,%edx
f01017c6:	73 0d                	jae    f01017d5 <debuginfo_eip+0x1c1>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01017c8:	81 c2 79 7a 10 f0    	add    $0xf0107a79,%edx
f01017ce:	89 16                	mov    %edx,(%esi)
f01017d0:	eb 03                	jmp    f01017d5 <debuginfo_eip+0x1c1>
f01017d2:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01017d5:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01017da:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01017dd:	39 cf                	cmp    %ecx,%edi
f01017df:	7d 46                	jge    f0101827 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
f01017e1:	89 f8                	mov    %edi,%eax
f01017e3:	83 c0 01             	add    $0x1,%eax
f01017e6:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01017e9:	eb 07                	jmp    f01017f2 <debuginfo_eip+0x1de>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01017eb:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01017ef:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01017f2:	39 c8                	cmp    %ecx,%eax
f01017f4:	74 2c                	je     f0101822 <debuginfo_eip+0x20e>
f01017f6:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01017f9:	80 7a 04 a0          	cmpb   $0xa0,0x4(%edx)
f01017fd:	74 ec                	je     f01017eb <debuginfo_eip+0x1d7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01017ff:	b8 00 00 00 00       	mov    $0x0,%eax
f0101804:	eb 21                	jmp    f0101827 <debuginfo_eip+0x213>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0101806:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010180b:	eb 1a                	jmp    f0101827 <debuginfo_eip+0x213>
f010180d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101812:	eb 13                	jmp    f0101827 <debuginfo_eip+0x213>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0101814:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101819:	eb 0c                	jmp    f0101827 <debuginfo_eip+0x213>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
	if (lfun > rfun) 
       	  return -1;
f010181b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101820:	eb 05                	jmp    f0101827 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101822:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101827:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010182a:	5b                   	pop    %ebx
f010182b:	5e                   	pop    %esi
f010182c:	5f                   	pop    %edi
f010182d:	5d                   	pop    %ebp
f010182e:	c3                   	ret    

f010182f <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010182f:	55                   	push   %ebp
f0101830:	89 e5                	mov    %esp,%ebp
f0101832:	57                   	push   %edi
f0101833:	56                   	push   %esi
f0101834:	53                   	push   %ebx
f0101835:	83 ec 1c             	sub    $0x1c,%esp
f0101838:	89 c7                	mov    %eax,%edi
f010183a:	89 d6                	mov    %edx,%esi
f010183c:	8b 45 08             	mov    0x8(%ebp),%eax
f010183f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101842:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101845:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101848:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010184b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101850:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101853:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101856:	39 d3                	cmp    %edx,%ebx
f0101858:	72 05                	jb     f010185f <printnum+0x30>
f010185a:	39 45 10             	cmp    %eax,0x10(%ebp)
f010185d:	77 45                	ja     f01018a4 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010185f:	83 ec 0c             	sub    $0xc,%esp
f0101862:	ff 75 18             	pushl  0x18(%ebp)
f0101865:	8b 45 14             	mov    0x14(%ebp),%eax
f0101868:	8d 58 ff             	lea    -0x1(%eax),%ebx
f010186b:	53                   	push   %ebx
f010186c:	ff 75 10             	pushl  0x10(%ebp)
f010186f:	83 ec 08             	sub    $0x8,%esp
f0101872:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101875:	ff 75 e0             	pushl  -0x20(%ebp)
f0101878:	ff 75 dc             	pushl  -0x24(%ebp)
f010187b:	ff 75 d8             	pushl  -0x28(%ebp)
f010187e:	e8 3d 09 00 00       	call   f01021c0 <__udivdi3>
f0101883:	83 c4 18             	add    $0x18,%esp
f0101886:	52                   	push   %edx
f0101887:	50                   	push   %eax
f0101888:	89 f2                	mov    %esi,%edx
f010188a:	89 f8                	mov    %edi,%eax
f010188c:	e8 9e ff ff ff       	call   f010182f <printnum>
f0101891:	83 c4 20             	add    $0x20,%esp
f0101894:	eb 18                	jmp    f01018ae <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101896:	83 ec 08             	sub    $0x8,%esp
f0101899:	56                   	push   %esi
f010189a:	ff 75 18             	pushl  0x18(%ebp)
f010189d:	ff d7                	call   *%edi
f010189f:	83 c4 10             	add    $0x10,%esp
f01018a2:	eb 03                	jmp    f01018a7 <printnum+0x78>
f01018a4:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01018a7:	83 eb 01             	sub    $0x1,%ebx
f01018aa:	85 db                	test   %ebx,%ebx
f01018ac:	7f e8                	jg     f0101896 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01018ae:	83 ec 08             	sub    $0x8,%esp
f01018b1:	56                   	push   %esi
f01018b2:	83 ec 04             	sub    $0x4,%esp
f01018b5:	ff 75 e4             	pushl  -0x1c(%ebp)
f01018b8:	ff 75 e0             	pushl  -0x20(%ebp)
f01018bb:	ff 75 dc             	pushl  -0x24(%ebp)
f01018be:	ff 75 d8             	pushl  -0x28(%ebp)
f01018c1:	e8 2a 0a 00 00       	call   f01022f0 <__umoddi3>
f01018c6:	83 c4 14             	add    $0x14,%esp
f01018c9:	0f be 80 68 2d 10 f0 	movsbl -0xfefd298(%eax),%eax
f01018d0:	50                   	push   %eax
f01018d1:	ff d7                	call   *%edi
}
f01018d3:	83 c4 10             	add    $0x10,%esp
f01018d6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01018d9:	5b                   	pop    %ebx
f01018da:	5e                   	pop    %esi
f01018db:	5f                   	pop    %edi
f01018dc:	5d                   	pop    %ebp
f01018dd:	c3                   	ret    

f01018de <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01018de:	55                   	push   %ebp
f01018df:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01018e1:	83 fa 01             	cmp    $0x1,%edx
f01018e4:	7e 0e                	jle    f01018f4 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01018e6:	8b 10                	mov    (%eax),%edx
f01018e8:	8d 4a 08             	lea    0x8(%edx),%ecx
f01018eb:	89 08                	mov    %ecx,(%eax)
f01018ed:	8b 02                	mov    (%edx),%eax
f01018ef:	8b 52 04             	mov    0x4(%edx),%edx
f01018f2:	eb 22                	jmp    f0101916 <getuint+0x38>
	else if (lflag)
f01018f4:	85 d2                	test   %edx,%edx
f01018f6:	74 10                	je     f0101908 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01018f8:	8b 10                	mov    (%eax),%edx
f01018fa:	8d 4a 04             	lea    0x4(%edx),%ecx
f01018fd:	89 08                	mov    %ecx,(%eax)
f01018ff:	8b 02                	mov    (%edx),%eax
f0101901:	ba 00 00 00 00       	mov    $0x0,%edx
f0101906:	eb 0e                	jmp    f0101916 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0101908:	8b 10                	mov    (%eax),%edx
f010190a:	8d 4a 04             	lea    0x4(%edx),%ecx
f010190d:	89 08                	mov    %ecx,(%eax)
f010190f:	8b 02                	mov    (%edx),%eax
f0101911:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0101916:	5d                   	pop    %ebp
f0101917:	c3                   	ret    

f0101918 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101918:	55                   	push   %ebp
f0101919:	89 e5                	mov    %esp,%ebp
f010191b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010191e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101922:	8b 10                	mov    (%eax),%edx
f0101924:	3b 50 04             	cmp    0x4(%eax),%edx
f0101927:	73 0a                	jae    f0101933 <sprintputch+0x1b>
		*b->buf++ = ch;
f0101929:	8d 4a 01             	lea    0x1(%edx),%ecx
f010192c:	89 08                	mov    %ecx,(%eax)
f010192e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101931:	88 02                	mov    %al,(%edx)
}
f0101933:	5d                   	pop    %ebp
f0101934:	c3                   	ret    

f0101935 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101935:	55                   	push   %ebp
f0101936:	89 e5                	mov    %esp,%ebp
f0101938:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010193b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010193e:	50                   	push   %eax
f010193f:	ff 75 10             	pushl  0x10(%ebp)
f0101942:	ff 75 0c             	pushl  0xc(%ebp)
f0101945:	ff 75 08             	pushl  0x8(%ebp)
f0101948:	e8 05 00 00 00       	call   f0101952 <vprintfmt>
	va_end(ap);
}
f010194d:	83 c4 10             	add    $0x10,%esp
f0101950:	c9                   	leave  
f0101951:	c3                   	ret    

f0101952 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101952:	55                   	push   %ebp
f0101953:	89 e5                	mov    %esp,%ebp
f0101955:	57                   	push   %edi
f0101956:	56                   	push   %esi
f0101957:	53                   	push   %ebx
f0101958:	83 ec 2c             	sub    $0x2c,%esp
f010195b:	8b 75 08             	mov    0x8(%ebp),%esi
f010195e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101961:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101964:	eb 12                	jmp    f0101978 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0101966:	85 c0                	test   %eax,%eax
f0101968:	0f 84 89 03 00 00    	je     f0101cf7 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f010196e:	83 ec 08             	sub    $0x8,%esp
f0101971:	53                   	push   %ebx
f0101972:	50                   	push   %eax
f0101973:	ff d6                	call   *%esi
f0101975:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101978:	83 c7 01             	add    $0x1,%edi
f010197b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010197f:	83 f8 25             	cmp    $0x25,%eax
f0101982:	75 e2                	jne    f0101966 <vprintfmt+0x14>
f0101984:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0101988:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010198f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101996:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f010199d:	ba 00 00 00 00       	mov    $0x0,%edx
f01019a2:	eb 07                	jmp    f01019ab <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019a4:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01019a7:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019ab:	8d 47 01             	lea    0x1(%edi),%eax
f01019ae:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01019b1:	0f b6 07             	movzbl (%edi),%eax
f01019b4:	0f b6 c8             	movzbl %al,%ecx
f01019b7:	83 e8 23             	sub    $0x23,%eax
f01019ba:	3c 55                	cmp    $0x55,%al
f01019bc:	0f 87 1a 03 00 00    	ja     f0101cdc <vprintfmt+0x38a>
f01019c2:	0f b6 c0             	movzbl %al,%eax
f01019c5:	ff 24 85 00 2e 10 f0 	jmp    *-0xfefd200(,%eax,4)
f01019cc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01019cf:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01019d3:	eb d6                	jmp    f01019ab <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019d5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01019d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01019dd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01019e0:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01019e3:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f01019e7:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f01019ea:	8d 51 d0             	lea    -0x30(%ecx),%edx
f01019ed:	83 fa 09             	cmp    $0x9,%edx
f01019f0:	77 39                	ja     f0101a2b <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01019f2:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01019f5:	eb e9                	jmp    f01019e0 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01019f7:	8b 45 14             	mov    0x14(%ebp),%eax
f01019fa:	8d 48 04             	lea    0x4(%eax),%ecx
f01019fd:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101a00:	8b 00                	mov    (%eax),%eax
f0101a02:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a05:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101a08:	eb 27                	jmp    f0101a31 <vprintfmt+0xdf>
f0101a0a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101a0d:	85 c0                	test   %eax,%eax
f0101a0f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101a14:	0f 49 c8             	cmovns %eax,%ecx
f0101a17:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a1a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a1d:	eb 8c                	jmp    f01019ab <vprintfmt+0x59>
f0101a1f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101a22:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0101a29:	eb 80                	jmp    f01019ab <vprintfmt+0x59>
f0101a2b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101a2e:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0101a31:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101a35:	0f 89 70 ff ff ff    	jns    f01019ab <vprintfmt+0x59>
				width = precision, precision = -1;
f0101a3b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a3e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101a41:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101a48:	e9 5e ff ff ff       	jmp    f01019ab <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101a4d:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a50:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101a53:	e9 53 ff ff ff       	jmp    f01019ab <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101a58:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a5b:	8d 50 04             	lea    0x4(%eax),%edx
f0101a5e:	89 55 14             	mov    %edx,0x14(%ebp)
f0101a61:	83 ec 08             	sub    $0x8,%esp
f0101a64:	53                   	push   %ebx
f0101a65:	ff 30                	pushl  (%eax)
f0101a67:	ff d6                	call   *%esi
			break;
f0101a69:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a6c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0101a6f:	e9 04 ff ff ff       	jmp    f0101978 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101a74:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a77:	8d 50 04             	lea    0x4(%eax),%edx
f0101a7a:	89 55 14             	mov    %edx,0x14(%ebp)
f0101a7d:	8b 00                	mov    (%eax),%eax
f0101a7f:	99                   	cltd   
f0101a80:	31 d0                	xor    %edx,%eax
f0101a82:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101a84:	83 f8 07             	cmp    $0x7,%eax
f0101a87:	7f 0b                	jg     f0101a94 <vprintfmt+0x142>
f0101a89:	8b 14 85 60 2f 10 f0 	mov    -0xfefd0a0(,%eax,4),%edx
f0101a90:	85 d2                	test   %edx,%edx
f0101a92:	75 18                	jne    f0101aac <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0101a94:	50                   	push   %eax
f0101a95:	68 80 2d 10 f0       	push   $0xf0102d80
f0101a9a:	53                   	push   %ebx
f0101a9b:	56                   	push   %esi
f0101a9c:	e8 94 fe ff ff       	call   f0101935 <printfmt>
f0101aa1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101aa4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101aa7:	e9 cc fe ff ff       	jmp    f0101978 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0101aac:	52                   	push   %edx
f0101aad:	68 94 2b 10 f0       	push   $0xf0102b94
f0101ab2:	53                   	push   %ebx
f0101ab3:	56                   	push   %esi
f0101ab4:	e8 7c fe ff ff       	call   f0101935 <printfmt>
f0101ab9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101abc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101abf:	e9 b4 fe ff ff       	jmp    f0101978 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101ac4:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ac7:	8d 50 04             	lea    0x4(%eax),%edx
f0101aca:	89 55 14             	mov    %edx,0x14(%ebp)
f0101acd:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101acf:	85 ff                	test   %edi,%edi
f0101ad1:	b8 79 2d 10 f0       	mov    $0xf0102d79,%eax
f0101ad6:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101ad9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101add:	0f 8e 94 00 00 00    	jle    f0101b77 <vprintfmt+0x225>
f0101ae3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101ae7:	0f 84 98 00 00 00    	je     f0101b85 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101aed:	83 ec 08             	sub    $0x8,%esp
f0101af0:	ff 75 d0             	pushl  -0x30(%ebp)
f0101af3:	57                   	push   %edi
f0101af4:	e8 5f 03 00 00       	call   f0101e58 <strnlen>
f0101af9:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101afc:	29 c1                	sub    %eax,%ecx
f0101afe:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101b01:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101b04:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101b08:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101b0b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101b0e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101b10:	eb 0f                	jmp    f0101b21 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0101b12:	83 ec 08             	sub    $0x8,%esp
f0101b15:	53                   	push   %ebx
f0101b16:	ff 75 e0             	pushl  -0x20(%ebp)
f0101b19:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101b1b:	83 ef 01             	sub    $0x1,%edi
f0101b1e:	83 c4 10             	add    $0x10,%esp
f0101b21:	85 ff                	test   %edi,%edi
f0101b23:	7f ed                	jg     f0101b12 <vprintfmt+0x1c0>
f0101b25:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101b28:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101b2b:	85 c9                	test   %ecx,%ecx
f0101b2d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b32:	0f 49 c1             	cmovns %ecx,%eax
f0101b35:	29 c1                	sub    %eax,%ecx
f0101b37:	89 75 08             	mov    %esi,0x8(%ebp)
f0101b3a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101b3d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101b40:	89 cb                	mov    %ecx,%ebx
f0101b42:	eb 4d                	jmp    f0101b91 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101b44:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101b48:	74 1b                	je     f0101b65 <vprintfmt+0x213>
f0101b4a:	0f be c0             	movsbl %al,%eax
f0101b4d:	83 e8 20             	sub    $0x20,%eax
f0101b50:	83 f8 5e             	cmp    $0x5e,%eax
f0101b53:	76 10                	jbe    f0101b65 <vprintfmt+0x213>
					putch('?', putdat);
f0101b55:	83 ec 08             	sub    $0x8,%esp
f0101b58:	ff 75 0c             	pushl  0xc(%ebp)
f0101b5b:	6a 3f                	push   $0x3f
f0101b5d:	ff 55 08             	call   *0x8(%ebp)
f0101b60:	83 c4 10             	add    $0x10,%esp
f0101b63:	eb 0d                	jmp    f0101b72 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0101b65:	83 ec 08             	sub    $0x8,%esp
f0101b68:	ff 75 0c             	pushl  0xc(%ebp)
f0101b6b:	52                   	push   %edx
f0101b6c:	ff 55 08             	call   *0x8(%ebp)
f0101b6f:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101b72:	83 eb 01             	sub    $0x1,%ebx
f0101b75:	eb 1a                	jmp    f0101b91 <vprintfmt+0x23f>
f0101b77:	89 75 08             	mov    %esi,0x8(%ebp)
f0101b7a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101b7d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101b80:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101b83:	eb 0c                	jmp    f0101b91 <vprintfmt+0x23f>
f0101b85:	89 75 08             	mov    %esi,0x8(%ebp)
f0101b88:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101b8b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101b8e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101b91:	83 c7 01             	add    $0x1,%edi
f0101b94:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101b98:	0f be d0             	movsbl %al,%edx
f0101b9b:	85 d2                	test   %edx,%edx
f0101b9d:	74 23                	je     f0101bc2 <vprintfmt+0x270>
f0101b9f:	85 f6                	test   %esi,%esi
f0101ba1:	78 a1                	js     f0101b44 <vprintfmt+0x1f2>
f0101ba3:	83 ee 01             	sub    $0x1,%esi
f0101ba6:	79 9c                	jns    f0101b44 <vprintfmt+0x1f2>
f0101ba8:	89 df                	mov    %ebx,%edi
f0101baa:	8b 75 08             	mov    0x8(%ebp),%esi
f0101bad:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101bb0:	eb 18                	jmp    f0101bca <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101bb2:	83 ec 08             	sub    $0x8,%esp
f0101bb5:	53                   	push   %ebx
f0101bb6:	6a 20                	push   $0x20
f0101bb8:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101bba:	83 ef 01             	sub    $0x1,%edi
f0101bbd:	83 c4 10             	add    $0x10,%esp
f0101bc0:	eb 08                	jmp    f0101bca <vprintfmt+0x278>
f0101bc2:	89 df                	mov    %ebx,%edi
f0101bc4:	8b 75 08             	mov    0x8(%ebp),%esi
f0101bc7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101bca:	85 ff                	test   %edi,%edi
f0101bcc:	7f e4                	jg     f0101bb2 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101bce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101bd1:	e9 a2 fd ff ff       	jmp    f0101978 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101bd6:	83 fa 01             	cmp    $0x1,%edx
f0101bd9:	7e 16                	jle    f0101bf1 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101bdb:	8b 45 14             	mov    0x14(%ebp),%eax
f0101bde:	8d 50 08             	lea    0x8(%eax),%edx
f0101be1:	89 55 14             	mov    %edx,0x14(%ebp)
f0101be4:	8b 50 04             	mov    0x4(%eax),%edx
f0101be7:	8b 00                	mov    (%eax),%eax
f0101be9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101bec:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101bef:	eb 32                	jmp    f0101c23 <vprintfmt+0x2d1>
	else if (lflag)
f0101bf1:	85 d2                	test   %edx,%edx
f0101bf3:	74 18                	je     f0101c0d <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0101bf5:	8b 45 14             	mov    0x14(%ebp),%eax
f0101bf8:	8d 50 04             	lea    0x4(%eax),%edx
f0101bfb:	89 55 14             	mov    %edx,0x14(%ebp)
f0101bfe:	8b 00                	mov    (%eax),%eax
f0101c00:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101c03:	89 c1                	mov    %eax,%ecx
f0101c05:	c1 f9 1f             	sar    $0x1f,%ecx
f0101c08:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101c0b:	eb 16                	jmp    f0101c23 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0101c0d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c10:	8d 50 04             	lea    0x4(%eax),%edx
f0101c13:	89 55 14             	mov    %edx,0x14(%ebp)
f0101c16:	8b 00                	mov    (%eax),%eax
f0101c18:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101c1b:	89 c1                	mov    %eax,%ecx
f0101c1d:	c1 f9 1f             	sar    $0x1f,%ecx
f0101c20:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101c23:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101c26:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101c29:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101c2e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101c32:	79 74                	jns    f0101ca8 <vprintfmt+0x356>
				putch('-', putdat);
f0101c34:	83 ec 08             	sub    $0x8,%esp
f0101c37:	53                   	push   %ebx
f0101c38:	6a 2d                	push   $0x2d
f0101c3a:	ff d6                	call   *%esi
				num = -(long long) num;
f0101c3c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101c3f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101c42:	f7 d8                	neg    %eax
f0101c44:	83 d2 00             	adc    $0x0,%edx
f0101c47:	f7 da                	neg    %edx
f0101c49:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101c4c:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101c51:	eb 55                	jmp    f0101ca8 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101c53:	8d 45 14             	lea    0x14(%ebp),%eax
f0101c56:	e8 83 fc ff ff       	call   f01018de <getuint>
			base = 10;
f0101c5b:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101c60:	eb 46                	jmp    f0101ca8 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101c62:	8d 45 14             	lea    0x14(%ebp),%eax
f0101c65:	e8 74 fc ff ff       	call   f01018de <getuint>
			base = 8;
f0101c6a:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101c6f:	eb 37                	jmp    f0101ca8 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0101c71:	83 ec 08             	sub    $0x8,%esp
f0101c74:	53                   	push   %ebx
f0101c75:	6a 30                	push   $0x30
f0101c77:	ff d6                	call   *%esi
			putch('x', putdat);
f0101c79:	83 c4 08             	add    $0x8,%esp
f0101c7c:	53                   	push   %ebx
f0101c7d:	6a 78                	push   $0x78
f0101c7f:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101c81:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c84:	8d 50 04             	lea    0x4(%eax),%edx
f0101c87:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101c8a:	8b 00                	mov    (%eax),%eax
f0101c8c:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101c91:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101c94:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101c99:	eb 0d                	jmp    f0101ca8 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101c9b:	8d 45 14             	lea    0x14(%ebp),%eax
f0101c9e:	e8 3b fc ff ff       	call   f01018de <getuint>
			base = 16;
f0101ca3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101ca8:	83 ec 0c             	sub    $0xc,%esp
f0101cab:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101caf:	57                   	push   %edi
f0101cb0:	ff 75 e0             	pushl  -0x20(%ebp)
f0101cb3:	51                   	push   %ecx
f0101cb4:	52                   	push   %edx
f0101cb5:	50                   	push   %eax
f0101cb6:	89 da                	mov    %ebx,%edx
f0101cb8:	89 f0                	mov    %esi,%eax
f0101cba:	e8 70 fb ff ff       	call   f010182f <printnum>
			break;
f0101cbf:	83 c4 20             	add    $0x20,%esp
f0101cc2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101cc5:	e9 ae fc ff ff       	jmp    f0101978 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101cca:	83 ec 08             	sub    $0x8,%esp
f0101ccd:	53                   	push   %ebx
f0101cce:	51                   	push   %ecx
f0101ccf:	ff d6                	call   *%esi
			break;
f0101cd1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101cd4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101cd7:	e9 9c fc ff ff       	jmp    f0101978 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101cdc:	83 ec 08             	sub    $0x8,%esp
f0101cdf:	53                   	push   %ebx
f0101ce0:	6a 25                	push   $0x25
f0101ce2:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101ce4:	83 c4 10             	add    $0x10,%esp
f0101ce7:	eb 03                	jmp    f0101cec <vprintfmt+0x39a>
f0101ce9:	83 ef 01             	sub    $0x1,%edi
f0101cec:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101cf0:	75 f7                	jne    f0101ce9 <vprintfmt+0x397>
f0101cf2:	e9 81 fc ff ff       	jmp    f0101978 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101cf7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101cfa:	5b                   	pop    %ebx
f0101cfb:	5e                   	pop    %esi
f0101cfc:	5f                   	pop    %edi
f0101cfd:	5d                   	pop    %ebp
f0101cfe:	c3                   	ret    

f0101cff <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101cff:	55                   	push   %ebp
f0101d00:	89 e5                	mov    %esp,%ebp
f0101d02:	83 ec 18             	sub    $0x18,%esp
f0101d05:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d08:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101d0b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101d0e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101d12:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101d15:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101d1c:	85 c0                	test   %eax,%eax
f0101d1e:	74 26                	je     f0101d46 <vsnprintf+0x47>
f0101d20:	85 d2                	test   %edx,%edx
f0101d22:	7e 22                	jle    f0101d46 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101d24:	ff 75 14             	pushl  0x14(%ebp)
f0101d27:	ff 75 10             	pushl  0x10(%ebp)
f0101d2a:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101d2d:	50                   	push   %eax
f0101d2e:	68 18 19 10 f0       	push   $0xf0101918
f0101d33:	e8 1a fc ff ff       	call   f0101952 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101d38:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101d3b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101d3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101d41:	83 c4 10             	add    $0x10,%esp
f0101d44:	eb 05                	jmp    f0101d4b <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101d46:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101d4b:	c9                   	leave  
f0101d4c:	c3                   	ret    

f0101d4d <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101d4d:	55                   	push   %ebp
f0101d4e:	89 e5                	mov    %esp,%ebp
f0101d50:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101d53:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101d56:	50                   	push   %eax
f0101d57:	ff 75 10             	pushl  0x10(%ebp)
f0101d5a:	ff 75 0c             	pushl  0xc(%ebp)
f0101d5d:	ff 75 08             	pushl  0x8(%ebp)
f0101d60:	e8 9a ff ff ff       	call   f0101cff <vsnprintf>
	va_end(ap);

	return rc;
}
f0101d65:	c9                   	leave  
f0101d66:	c3                   	ret    

f0101d67 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101d67:	55                   	push   %ebp
f0101d68:	89 e5                	mov    %esp,%ebp
f0101d6a:	57                   	push   %edi
f0101d6b:	56                   	push   %esi
f0101d6c:	53                   	push   %ebx
f0101d6d:	83 ec 0c             	sub    $0xc,%esp
f0101d70:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101d73:	85 c0                	test   %eax,%eax
f0101d75:	74 11                	je     f0101d88 <readline+0x21>
		cprintf("%s", prompt);
f0101d77:	83 ec 08             	sub    $0x8,%esp
f0101d7a:	50                   	push   %eax
f0101d7b:	68 94 2b 10 f0       	push   $0xf0102b94
f0101d80:	e8 85 f7 ff ff       	call   f010150a <cprintf>
f0101d85:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101d88:	83 ec 0c             	sub    $0xc,%esp
f0101d8b:	6a 00                	push   $0x0
f0101d8d:	e8 b4 e8 ff ff       	call   f0100646 <iscons>
f0101d92:	89 c7                	mov    %eax,%edi
f0101d94:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101d97:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101d9c:	e8 94 e8 ff ff       	call   f0100635 <getchar>
f0101da1:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101da3:	85 c0                	test   %eax,%eax
f0101da5:	79 18                	jns    f0101dbf <readline+0x58>
			cprintf("read error: %e\n", c);
f0101da7:	83 ec 08             	sub    $0x8,%esp
f0101daa:	50                   	push   %eax
f0101dab:	68 80 2f 10 f0       	push   $0xf0102f80
f0101db0:	e8 55 f7 ff ff       	call   f010150a <cprintf>
			return NULL;
f0101db5:	83 c4 10             	add    $0x10,%esp
f0101db8:	b8 00 00 00 00       	mov    $0x0,%eax
f0101dbd:	eb 79                	jmp    f0101e38 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101dbf:	83 f8 08             	cmp    $0x8,%eax
f0101dc2:	0f 94 c2             	sete   %dl
f0101dc5:	83 f8 7f             	cmp    $0x7f,%eax
f0101dc8:	0f 94 c0             	sete   %al
f0101dcb:	08 c2                	or     %al,%dl
f0101dcd:	74 1a                	je     f0101de9 <readline+0x82>
f0101dcf:	85 f6                	test   %esi,%esi
f0101dd1:	7e 16                	jle    f0101de9 <readline+0x82>
			if (echoing)
f0101dd3:	85 ff                	test   %edi,%edi
f0101dd5:	74 0d                	je     f0101de4 <readline+0x7d>
				cputchar('\b');
f0101dd7:	83 ec 0c             	sub    $0xc,%esp
f0101dda:	6a 08                	push   $0x8
f0101ddc:	e8 44 e8 ff ff       	call   f0100625 <cputchar>
f0101de1:	83 c4 10             	add    $0x10,%esp
			i--;
f0101de4:	83 ee 01             	sub    $0x1,%esi
f0101de7:	eb b3                	jmp    f0101d9c <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101de9:	83 fb 1f             	cmp    $0x1f,%ebx
f0101dec:	7e 23                	jle    f0101e11 <readline+0xaa>
f0101dee:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101df4:	7f 1b                	jg     f0101e11 <readline+0xaa>
			if (echoing)
f0101df6:	85 ff                	test   %edi,%edi
f0101df8:	74 0c                	je     f0101e06 <readline+0x9f>
				cputchar(c);
f0101dfa:	83 ec 0c             	sub    $0xc,%esp
f0101dfd:	53                   	push   %ebx
f0101dfe:	e8 22 e8 ff ff       	call   f0100625 <cputchar>
f0101e03:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101e06:	88 9e 60 45 11 f0    	mov    %bl,-0xfeebaa0(%esi)
f0101e0c:	8d 76 01             	lea    0x1(%esi),%esi
f0101e0f:	eb 8b                	jmp    f0101d9c <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101e11:	83 fb 0a             	cmp    $0xa,%ebx
f0101e14:	74 05                	je     f0101e1b <readline+0xb4>
f0101e16:	83 fb 0d             	cmp    $0xd,%ebx
f0101e19:	75 81                	jne    f0101d9c <readline+0x35>
			if (echoing)
f0101e1b:	85 ff                	test   %edi,%edi
f0101e1d:	74 0d                	je     f0101e2c <readline+0xc5>
				cputchar('\n');
f0101e1f:	83 ec 0c             	sub    $0xc,%esp
f0101e22:	6a 0a                	push   $0xa
f0101e24:	e8 fc e7 ff ff       	call   f0100625 <cputchar>
f0101e29:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101e2c:	c6 86 60 45 11 f0 00 	movb   $0x0,-0xfeebaa0(%esi)
			return buf;
f0101e33:	b8 60 45 11 f0       	mov    $0xf0114560,%eax
		}
	}
}
f0101e38:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101e3b:	5b                   	pop    %ebx
f0101e3c:	5e                   	pop    %esi
f0101e3d:	5f                   	pop    %edi
f0101e3e:	5d                   	pop    %ebp
f0101e3f:	c3                   	ret    

f0101e40 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101e40:	55                   	push   %ebp
f0101e41:	89 e5                	mov    %esp,%ebp
f0101e43:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101e46:	b8 00 00 00 00       	mov    $0x0,%eax
f0101e4b:	eb 03                	jmp    f0101e50 <strlen+0x10>
		n++;
f0101e4d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101e50:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101e54:	75 f7                	jne    f0101e4d <strlen+0xd>
		n++;
	return n;
}
f0101e56:	5d                   	pop    %ebp
f0101e57:	c3                   	ret    

f0101e58 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101e58:	55                   	push   %ebp
f0101e59:	89 e5                	mov    %esp,%ebp
f0101e5b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101e5e:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101e61:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e66:	eb 03                	jmp    f0101e6b <strnlen+0x13>
		n++;
f0101e68:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101e6b:	39 c2                	cmp    %eax,%edx
f0101e6d:	74 08                	je     f0101e77 <strnlen+0x1f>
f0101e6f:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101e73:	75 f3                	jne    f0101e68 <strnlen+0x10>
f0101e75:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101e77:	5d                   	pop    %ebp
f0101e78:	c3                   	ret    

f0101e79 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101e79:	55                   	push   %ebp
f0101e7a:	89 e5                	mov    %esp,%ebp
f0101e7c:	53                   	push   %ebx
f0101e7d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e80:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101e83:	89 c2                	mov    %eax,%edx
f0101e85:	83 c2 01             	add    $0x1,%edx
f0101e88:	83 c1 01             	add    $0x1,%ecx
f0101e8b:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101e8f:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101e92:	84 db                	test   %bl,%bl
f0101e94:	75 ef                	jne    f0101e85 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101e96:	5b                   	pop    %ebx
f0101e97:	5d                   	pop    %ebp
f0101e98:	c3                   	ret    

f0101e99 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101e99:	55                   	push   %ebp
f0101e9a:	89 e5                	mov    %esp,%ebp
f0101e9c:	53                   	push   %ebx
f0101e9d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101ea0:	53                   	push   %ebx
f0101ea1:	e8 9a ff ff ff       	call   f0101e40 <strlen>
f0101ea6:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101ea9:	ff 75 0c             	pushl  0xc(%ebp)
f0101eac:	01 d8                	add    %ebx,%eax
f0101eae:	50                   	push   %eax
f0101eaf:	e8 c5 ff ff ff       	call   f0101e79 <strcpy>
	return dst;
}
f0101eb4:	89 d8                	mov    %ebx,%eax
f0101eb6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101eb9:	c9                   	leave  
f0101eba:	c3                   	ret    

f0101ebb <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101ebb:	55                   	push   %ebp
f0101ebc:	89 e5                	mov    %esp,%ebp
f0101ebe:	56                   	push   %esi
f0101ebf:	53                   	push   %ebx
f0101ec0:	8b 75 08             	mov    0x8(%ebp),%esi
f0101ec3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101ec6:	89 f3                	mov    %esi,%ebx
f0101ec8:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101ecb:	89 f2                	mov    %esi,%edx
f0101ecd:	eb 0f                	jmp    f0101ede <strncpy+0x23>
		*dst++ = *src;
f0101ecf:	83 c2 01             	add    $0x1,%edx
f0101ed2:	0f b6 01             	movzbl (%ecx),%eax
f0101ed5:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101ed8:	80 39 01             	cmpb   $0x1,(%ecx)
f0101edb:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101ede:	39 da                	cmp    %ebx,%edx
f0101ee0:	75 ed                	jne    f0101ecf <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101ee2:	89 f0                	mov    %esi,%eax
f0101ee4:	5b                   	pop    %ebx
f0101ee5:	5e                   	pop    %esi
f0101ee6:	5d                   	pop    %ebp
f0101ee7:	c3                   	ret    

f0101ee8 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101ee8:	55                   	push   %ebp
f0101ee9:	89 e5                	mov    %esp,%ebp
f0101eeb:	56                   	push   %esi
f0101eec:	53                   	push   %ebx
f0101eed:	8b 75 08             	mov    0x8(%ebp),%esi
f0101ef0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101ef3:	8b 55 10             	mov    0x10(%ebp),%edx
f0101ef6:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101ef8:	85 d2                	test   %edx,%edx
f0101efa:	74 21                	je     f0101f1d <strlcpy+0x35>
f0101efc:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101f00:	89 f2                	mov    %esi,%edx
f0101f02:	eb 09                	jmp    f0101f0d <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101f04:	83 c2 01             	add    $0x1,%edx
f0101f07:	83 c1 01             	add    $0x1,%ecx
f0101f0a:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101f0d:	39 c2                	cmp    %eax,%edx
f0101f0f:	74 09                	je     f0101f1a <strlcpy+0x32>
f0101f11:	0f b6 19             	movzbl (%ecx),%ebx
f0101f14:	84 db                	test   %bl,%bl
f0101f16:	75 ec                	jne    f0101f04 <strlcpy+0x1c>
f0101f18:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101f1a:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101f1d:	29 f0                	sub    %esi,%eax
}
f0101f1f:	5b                   	pop    %ebx
f0101f20:	5e                   	pop    %esi
f0101f21:	5d                   	pop    %ebp
f0101f22:	c3                   	ret    

f0101f23 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101f23:	55                   	push   %ebp
f0101f24:	89 e5                	mov    %esp,%ebp
f0101f26:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101f29:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101f2c:	eb 06                	jmp    f0101f34 <strcmp+0x11>
		p++, q++;
f0101f2e:	83 c1 01             	add    $0x1,%ecx
f0101f31:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101f34:	0f b6 01             	movzbl (%ecx),%eax
f0101f37:	84 c0                	test   %al,%al
f0101f39:	74 04                	je     f0101f3f <strcmp+0x1c>
f0101f3b:	3a 02                	cmp    (%edx),%al
f0101f3d:	74 ef                	je     f0101f2e <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101f3f:	0f b6 c0             	movzbl %al,%eax
f0101f42:	0f b6 12             	movzbl (%edx),%edx
f0101f45:	29 d0                	sub    %edx,%eax
}
f0101f47:	5d                   	pop    %ebp
f0101f48:	c3                   	ret    

f0101f49 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101f49:	55                   	push   %ebp
f0101f4a:	89 e5                	mov    %esp,%ebp
f0101f4c:	53                   	push   %ebx
f0101f4d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f50:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101f53:	89 c3                	mov    %eax,%ebx
f0101f55:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101f58:	eb 06                	jmp    f0101f60 <strncmp+0x17>
		n--, p++, q++;
f0101f5a:	83 c0 01             	add    $0x1,%eax
f0101f5d:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101f60:	39 d8                	cmp    %ebx,%eax
f0101f62:	74 15                	je     f0101f79 <strncmp+0x30>
f0101f64:	0f b6 08             	movzbl (%eax),%ecx
f0101f67:	84 c9                	test   %cl,%cl
f0101f69:	74 04                	je     f0101f6f <strncmp+0x26>
f0101f6b:	3a 0a                	cmp    (%edx),%cl
f0101f6d:	74 eb                	je     f0101f5a <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101f6f:	0f b6 00             	movzbl (%eax),%eax
f0101f72:	0f b6 12             	movzbl (%edx),%edx
f0101f75:	29 d0                	sub    %edx,%eax
f0101f77:	eb 05                	jmp    f0101f7e <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101f79:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101f7e:	5b                   	pop    %ebx
f0101f7f:	5d                   	pop    %ebp
f0101f80:	c3                   	ret    

f0101f81 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101f81:	55                   	push   %ebp
f0101f82:	89 e5                	mov    %esp,%ebp
f0101f84:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f87:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101f8b:	eb 07                	jmp    f0101f94 <strchr+0x13>
		if (*s == c)
f0101f8d:	38 ca                	cmp    %cl,%dl
f0101f8f:	74 0f                	je     f0101fa0 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101f91:	83 c0 01             	add    $0x1,%eax
f0101f94:	0f b6 10             	movzbl (%eax),%edx
f0101f97:	84 d2                	test   %dl,%dl
f0101f99:	75 f2                	jne    f0101f8d <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101f9b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101fa0:	5d                   	pop    %ebp
f0101fa1:	c3                   	ret    

f0101fa2 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101fa2:	55                   	push   %ebp
f0101fa3:	89 e5                	mov    %esp,%ebp
f0101fa5:	8b 45 08             	mov    0x8(%ebp),%eax
f0101fa8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101fac:	eb 03                	jmp    f0101fb1 <strfind+0xf>
f0101fae:	83 c0 01             	add    $0x1,%eax
f0101fb1:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101fb4:	38 ca                	cmp    %cl,%dl
f0101fb6:	74 04                	je     f0101fbc <strfind+0x1a>
f0101fb8:	84 d2                	test   %dl,%dl
f0101fba:	75 f2                	jne    f0101fae <strfind+0xc>
			break;
	return (char *) s;
}
f0101fbc:	5d                   	pop    %ebp
f0101fbd:	c3                   	ret    

f0101fbe <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101fbe:	55                   	push   %ebp
f0101fbf:	89 e5                	mov    %esp,%ebp
f0101fc1:	57                   	push   %edi
f0101fc2:	56                   	push   %esi
f0101fc3:	53                   	push   %ebx
f0101fc4:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101fc7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101fca:	85 c9                	test   %ecx,%ecx
f0101fcc:	74 36                	je     f0102004 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101fce:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101fd4:	75 28                	jne    f0101ffe <memset+0x40>
f0101fd6:	f6 c1 03             	test   $0x3,%cl
f0101fd9:	75 23                	jne    f0101ffe <memset+0x40>
		c &= 0xFF;
f0101fdb:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101fdf:	89 d3                	mov    %edx,%ebx
f0101fe1:	c1 e3 08             	shl    $0x8,%ebx
f0101fe4:	89 d6                	mov    %edx,%esi
f0101fe6:	c1 e6 18             	shl    $0x18,%esi
f0101fe9:	89 d0                	mov    %edx,%eax
f0101feb:	c1 e0 10             	shl    $0x10,%eax
f0101fee:	09 f0                	or     %esi,%eax
f0101ff0:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101ff2:	89 d8                	mov    %ebx,%eax
f0101ff4:	09 d0                	or     %edx,%eax
f0101ff6:	c1 e9 02             	shr    $0x2,%ecx
f0101ff9:	fc                   	cld    
f0101ffa:	f3 ab                	rep stos %eax,%es:(%edi)
f0101ffc:	eb 06                	jmp    f0102004 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101ffe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102001:	fc                   	cld    
f0102002:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0102004:	89 f8                	mov    %edi,%eax
f0102006:	5b                   	pop    %ebx
f0102007:	5e                   	pop    %esi
f0102008:	5f                   	pop    %edi
f0102009:	5d                   	pop    %ebp
f010200a:	c3                   	ret    

f010200b <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010200b:	55                   	push   %ebp
f010200c:	89 e5                	mov    %esp,%ebp
f010200e:	57                   	push   %edi
f010200f:	56                   	push   %esi
f0102010:	8b 45 08             	mov    0x8(%ebp),%eax
f0102013:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102016:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0102019:	39 c6                	cmp    %eax,%esi
f010201b:	73 35                	jae    f0102052 <memmove+0x47>
f010201d:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102020:	39 d0                	cmp    %edx,%eax
f0102022:	73 2e                	jae    f0102052 <memmove+0x47>
		s += n;
		d += n;
f0102024:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102027:	89 d6                	mov    %edx,%esi
f0102029:	09 fe                	or     %edi,%esi
f010202b:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0102031:	75 13                	jne    f0102046 <memmove+0x3b>
f0102033:	f6 c1 03             	test   $0x3,%cl
f0102036:	75 0e                	jne    f0102046 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0102038:	83 ef 04             	sub    $0x4,%edi
f010203b:	8d 72 fc             	lea    -0x4(%edx),%esi
f010203e:	c1 e9 02             	shr    $0x2,%ecx
f0102041:	fd                   	std    
f0102042:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102044:	eb 09                	jmp    f010204f <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0102046:	83 ef 01             	sub    $0x1,%edi
f0102049:	8d 72 ff             	lea    -0x1(%edx),%esi
f010204c:	fd                   	std    
f010204d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010204f:	fc                   	cld    
f0102050:	eb 1d                	jmp    f010206f <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102052:	89 f2                	mov    %esi,%edx
f0102054:	09 c2                	or     %eax,%edx
f0102056:	f6 c2 03             	test   $0x3,%dl
f0102059:	75 0f                	jne    f010206a <memmove+0x5f>
f010205b:	f6 c1 03             	test   $0x3,%cl
f010205e:	75 0a                	jne    f010206a <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0102060:	c1 e9 02             	shr    $0x2,%ecx
f0102063:	89 c7                	mov    %eax,%edi
f0102065:	fc                   	cld    
f0102066:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102068:	eb 05                	jmp    f010206f <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010206a:	89 c7                	mov    %eax,%edi
f010206c:	fc                   	cld    
f010206d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010206f:	5e                   	pop    %esi
f0102070:	5f                   	pop    %edi
f0102071:	5d                   	pop    %ebp
f0102072:	c3                   	ret    

f0102073 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0102073:	55                   	push   %ebp
f0102074:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0102076:	ff 75 10             	pushl  0x10(%ebp)
f0102079:	ff 75 0c             	pushl  0xc(%ebp)
f010207c:	ff 75 08             	pushl  0x8(%ebp)
f010207f:	e8 87 ff ff ff       	call   f010200b <memmove>
}
f0102084:	c9                   	leave  
f0102085:	c3                   	ret    

f0102086 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0102086:	55                   	push   %ebp
f0102087:	89 e5                	mov    %esp,%ebp
f0102089:	56                   	push   %esi
f010208a:	53                   	push   %ebx
f010208b:	8b 45 08             	mov    0x8(%ebp),%eax
f010208e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102091:	89 c6                	mov    %eax,%esi
f0102093:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102096:	eb 1a                	jmp    f01020b2 <memcmp+0x2c>
		if (*s1 != *s2)
f0102098:	0f b6 08             	movzbl (%eax),%ecx
f010209b:	0f b6 1a             	movzbl (%edx),%ebx
f010209e:	38 d9                	cmp    %bl,%cl
f01020a0:	74 0a                	je     f01020ac <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01020a2:	0f b6 c1             	movzbl %cl,%eax
f01020a5:	0f b6 db             	movzbl %bl,%ebx
f01020a8:	29 d8                	sub    %ebx,%eax
f01020aa:	eb 0f                	jmp    f01020bb <memcmp+0x35>
		s1++, s2++;
f01020ac:	83 c0 01             	add    $0x1,%eax
f01020af:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01020b2:	39 f0                	cmp    %esi,%eax
f01020b4:	75 e2                	jne    f0102098 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01020b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01020bb:	5b                   	pop    %ebx
f01020bc:	5e                   	pop    %esi
f01020bd:	5d                   	pop    %ebp
f01020be:	c3                   	ret    

f01020bf <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01020bf:	55                   	push   %ebp
f01020c0:	89 e5                	mov    %esp,%ebp
f01020c2:	53                   	push   %ebx
f01020c3:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01020c6:	89 c1                	mov    %eax,%ecx
f01020c8:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01020cb:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01020cf:	eb 0a                	jmp    f01020db <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01020d1:	0f b6 10             	movzbl (%eax),%edx
f01020d4:	39 da                	cmp    %ebx,%edx
f01020d6:	74 07                	je     f01020df <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01020d8:	83 c0 01             	add    $0x1,%eax
f01020db:	39 c8                	cmp    %ecx,%eax
f01020dd:	72 f2                	jb     f01020d1 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01020df:	5b                   	pop    %ebx
f01020e0:	5d                   	pop    %ebp
f01020e1:	c3                   	ret    

f01020e2 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01020e2:	55                   	push   %ebp
f01020e3:	89 e5                	mov    %esp,%ebp
f01020e5:	57                   	push   %edi
f01020e6:	56                   	push   %esi
f01020e7:	53                   	push   %ebx
f01020e8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01020eb:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01020ee:	eb 03                	jmp    f01020f3 <strtol+0x11>
		s++;
f01020f0:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01020f3:	0f b6 01             	movzbl (%ecx),%eax
f01020f6:	3c 20                	cmp    $0x20,%al
f01020f8:	74 f6                	je     f01020f0 <strtol+0xe>
f01020fa:	3c 09                	cmp    $0x9,%al
f01020fc:	74 f2                	je     f01020f0 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01020fe:	3c 2b                	cmp    $0x2b,%al
f0102100:	75 0a                	jne    f010210c <strtol+0x2a>
		s++;
f0102102:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0102105:	bf 00 00 00 00       	mov    $0x0,%edi
f010210a:	eb 11                	jmp    f010211d <strtol+0x3b>
f010210c:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0102111:	3c 2d                	cmp    $0x2d,%al
f0102113:	75 08                	jne    f010211d <strtol+0x3b>
		s++, neg = 1;
f0102115:	83 c1 01             	add    $0x1,%ecx
f0102118:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010211d:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0102123:	75 15                	jne    f010213a <strtol+0x58>
f0102125:	80 39 30             	cmpb   $0x30,(%ecx)
f0102128:	75 10                	jne    f010213a <strtol+0x58>
f010212a:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010212e:	75 7c                	jne    f01021ac <strtol+0xca>
		s += 2, base = 16;
f0102130:	83 c1 02             	add    $0x2,%ecx
f0102133:	bb 10 00 00 00       	mov    $0x10,%ebx
f0102138:	eb 16                	jmp    f0102150 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010213a:	85 db                	test   %ebx,%ebx
f010213c:	75 12                	jne    f0102150 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010213e:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0102143:	80 39 30             	cmpb   $0x30,(%ecx)
f0102146:	75 08                	jne    f0102150 <strtol+0x6e>
		s++, base = 8;
f0102148:	83 c1 01             	add    $0x1,%ecx
f010214b:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0102150:	b8 00 00 00 00       	mov    $0x0,%eax
f0102155:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0102158:	0f b6 11             	movzbl (%ecx),%edx
f010215b:	8d 72 d0             	lea    -0x30(%edx),%esi
f010215e:	89 f3                	mov    %esi,%ebx
f0102160:	80 fb 09             	cmp    $0x9,%bl
f0102163:	77 08                	ja     f010216d <strtol+0x8b>
			dig = *s - '0';
f0102165:	0f be d2             	movsbl %dl,%edx
f0102168:	83 ea 30             	sub    $0x30,%edx
f010216b:	eb 22                	jmp    f010218f <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010216d:	8d 72 9f             	lea    -0x61(%edx),%esi
f0102170:	89 f3                	mov    %esi,%ebx
f0102172:	80 fb 19             	cmp    $0x19,%bl
f0102175:	77 08                	ja     f010217f <strtol+0x9d>
			dig = *s - 'a' + 10;
f0102177:	0f be d2             	movsbl %dl,%edx
f010217a:	83 ea 57             	sub    $0x57,%edx
f010217d:	eb 10                	jmp    f010218f <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010217f:	8d 72 bf             	lea    -0x41(%edx),%esi
f0102182:	89 f3                	mov    %esi,%ebx
f0102184:	80 fb 19             	cmp    $0x19,%bl
f0102187:	77 16                	ja     f010219f <strtol+0xbd>
			dig = *s - 'A' + 10;
f0102189:	0f be d2             	movsbl %dl,%edx
f010218c:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010218f:	3b 55 10             	cmp    0x10(%ebp),%edx
f0102192:	7d 0b                	jge    f010219f <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0102194:	83 c1 01             	add    $0x1,%ecx
f0102197:	0f af 45 10          	imul   0x10(%ebp),%eax
f010219b:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010219d:	eb b9                	jmp    f0102158 <strtol+0x76>

	if (endptr)
f010219f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01021a3:	74 0d                	je     f01021b2 <strtol+0xd0>
		*endptr = (char *) s;
f01021a5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01021a8:	89 0e                	mov    %ecx,(%esi)
f01021aa:	eb 06                	jmp    f01021b2 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01021ac:	85 db                	test   %ebx,%ebx
f01021ae:	74 98                	je     f0102148 <strtol+0x66>
f01021b0:	eb 9e                	jmp    f0102150 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01021b2:	89 c2                	mov    %eax,%edx
f01021b4:	f7 da                	neg    %edx
f01021b6:	85 ff                	test   %edi,%edi
f01021b8:	0f 45 c2             	cmovne %edx,%eax
}
f01021bb:	5b                   	pop    %ebx
f01021bc:	5e                   	pop    %esi
f01021bd:	5f                   	pop    %edi
f01021be:	5d                   	pop    %ebp
f01021bf:	c3                   	ret    

f01021c0 <__udivdi3>:
f01021c0:	55                   	push   %ebp
f01021c1:	57                   	push   %edi
f01021c2:	56                   	push   %esi
f01021c3:	53                   	push   %ebx
f01021c4:	83 ec 1c             	sub    $0x1c,%esp
f01021c7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01021cb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01021cf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01021d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01021d7:	85 f6                	test   %esi,%esi
f01021d9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01021dd:	89 ca                	mov    %ecx,%edx
f01021df:	89 f8                	mov    %edi,%eax
f01021e1:	75 3d                	jne    f0102220 <__udivdi3+0x60>
f01021e3:	39 cf                	cmp    %ecx,%edi
f01021e5:	0f 87 c5 00 00 00    	ja     f01022b0 <__udivdi3+0xf0>
f01021eb:	85 ff                	test   %edi,%edi
f01021ed:	89 fd                	mov    %edi,%ebp
f01021ef:	75 0b                	jne    f01021fc <__udivdi3+0x3c>
f01021f1:	b8 01 00 00 00       	mov    $0x1,%eax
f01021f6:	31 d2                	xor    %edx,%edx
f01021f8:	f7 f7                	div    %edi
f01021fa:	89 c5                	mov    %eax,%ebp
f01021fc:	89 c8                	mov    %ecx,%eax
f01021fe:	31 d2                	xor    %edx,%edx
f0102200:	f7 f5                	div    %ebp
f0102202:	89 c1                	mov    %eax,%ecx
f0102204:	89 d8                	mov    %ebx,%eax
f0102206:	89 cf                	mov    %ecx,%edi
f0102208:	f7 f5                	div    %ebp
f010220a:	89 c3                	mov    %eax,%ebx
f010220c:	89 d8                	mov    %ebx,%eax
f010220e:	89 fa                	mov    %edi,%edx
f0102210:	83 c4 1c             	add    $0x1c,%esp
f0102213:	5b                   	pop    %ebx
f0102214:	5e                   	pop    %esi
f0102215:	5f                   	pop    %edi
f0102216:	5d                   	pop    %ebp
f0102217:	c3                   	ret    
f0102218:	90                   	nop
f0102219:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102220:	39 ce                	cmp    %ecx,%esi
f0102222:	77 74                	ja     f0102298 <__udivdi3+0xd8>
f0102224:	0f bd fe             	bsr    %esi,%edi
f0102227:	83 f7 1f             	xor    $0x1f,%edi
f010222a:	0f 84 98 00 00 00    	je     f01022c8 <__udivdi3+0x108>
f0102230:	bb 20 00 00 00       	mov    $0x20,%ebx
f0102235:	89 f9                	mov    %edi,%ecx
f0102237:	89 c5                	mov    %eax,%ebp
f0102239:	29 fb                	sub    %edi,%ebx
f010223b:	d3 e6                	shl    %cl,%esi
f010223d:	89 d9                	mov    %ebx,%ecx
f010223f:	d3 ed                	shr    %cl,%ebp
f0102241:	89 f9                	mov    %edi,%ecx
f0102243:	d3 e0                	shl    %cl,%eax
f0102245:	09 ee                	or     %ebp,%esi
f0102247:	89 d9                	mov    %ebx,%ecx
f0102249:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010224d:	89 d5                	mov    %edx,%ebp
f010224f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102253:	d3 ed                	shr    %cl,%ebp
f0102255:	89 f9                	mov    %edi,%ecx
f0102257:	d3 e2                	shl    %cl,%edx
f0102259:	89 d9                	mov    %ebx,%ecx
f010225b:	d3 e8                	shr    %cl,%eax
f010225d:	09 c2                	or     %eax,%edx
f010225f:	89 d0                	mov    %edx,%eax
f0102261:	89 ea                	mov    %ebp,%edx
f0102263:	f7 f6                	div    %esi
f0102265:	89 d5                	mov    %edx,%ebp
f0102267:	89 c3                	mov    %eax,%ebx
f0102269:	f7 64 24 0c          	mull   0xc(%esp)
f010226d:	39 d5                	cmp    %edx,%ebp
f010226f:	72 10                	jb     f0102281 <__udivdi3+0xc1>
f0102271:	8b 74 24 08          	mov    0x8(%esp),%esi
f0102275:	89 f9                	mov    %edi,%ecx
f0102277:	d3 e6                	shl    %cl,%esi
f0102279:	39 c6                	cmp    %eax,%esi
f010227b:	73 07                	jae    f0102284 <__udivdi3+0xc4>
f010227d:	39 d5                	cmp    %edx,%ebp
f010227f:	75 03                	jne    f0102284 <__udivdi3+0xc4>
f0102281:	83 eb 01             	sub    $0x1,%ebx
f0102284:	31 ff                	xor    %edi,%edi
f0102286:	89 d8                	mov    %ebx,%eax
f0102288:	89 fa                	mov    %edi,%edx
f010228a:	83 c4 1c             	add    $0x1c,%esp
f010228d:	5b                   	pop    %ebx
f010228e:	5e                   	pop    %esi
f010228f:	5f                   	pop    %edi
f0102290:	5d                   	pop    %ebp
f0102291:	c3                   	ret    
f0102292:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102298:	31 ff                	xor    %edi,%edi
f010229a:	31 db                	xor    %ebx,%ebx
f010229c:	89 d8                	mov    %ebx,%eax
f010229e:	89 fa                	mov    %edi,%edx
f01022a0:	83 c4 1c             	add    $0x1c,%esp
f01022a3:	5b                   	pop    %ebx
f01022a4:	5e                   	pop    %esi
f01022a5:	5f                   	pop    %edi
f01022a6:	5d                   	pop    %ebp
f01022a7:	c3                   	ret    
f01022a8:	90                   	nop
f01022a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01022b0:	89 d8                	mov    %ebx,%eax
f01022b2:	f7 f7                	div    %edi
f01022b4:	31 ff                	xor    %edi,%edi
f01022b6:	89 c3                	mov    %eax,%ebx
f01022b8:	89 d8                	mov    %ebx,%eax
f01022ba:	89 fa                	mov    %edi,%edx
f01022bc:	83 c4 1c             	add    $0x1c,%esp
f01022bf:	5b                   	pop    %ebx
f01022c0:	5e                   	pop    %esi
f01022c1:	5f                   	pop    %edi
f01022c2:	5d                   	pop    %ebp
f01022c3:	c3                   	ret    
f01022c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01022c8:	39 ce                	cmp    %ecx,%esi
f01022ca:	72 0c                	jb     f01022d8 <__udivdi3+0x118>
f01022cc:	31 db                	xor    %ebx,%ebx
f01022ce:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01022d2:	0f 87 34 ff ff ff    	ja     f010220c <__udivdi3+0x4c>
f01022d8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01022dd:	e9 2a ff ff ff       	jmp    f010220c <__udivdi3+0x4c>
f01022e2:	66 90                	xchg   %ax,%ax
f01022e4:	66 90                	xchg   %ax,%ax
f01022e6:	66 90                	xchg   %ax,%ax
f01022e8:	66 90                	xchg   %ax,%ax
f01022ea:	66 90                	xchg   %ax,%ax
f01022ec:	66 90                	xchg   %ax,%ax
f01022ee:	66 90                	xchg   %ax,%ax

f01022f0 <__umoddi3>:
f01022f0:	55                   	push   %ebp
f01022f1:	57                   	push   %edi
f01022f2:	56                   	push   %esi
f01022f3:	53                   	push   %ebx
f01022f4:	83 ec 1c             	sub    $0x1c,%esp
f01022f7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01022fb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01022ff:	8b 74 24 34          	mov    0x34(%esp),%esi
f0102303:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102307:	85 d2                	test   %edx,%edx
f0102309:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010230d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102311:	89 f3                	mov    %esi,%ebx
f0102313:	89 3c 24             	mov    %edi,(%esp)
f0102316:	89 74 24 04          	mov    %esi,0x4(%esp)
f010231a:	75 1c                	jne    f0102338 <__umoddi3+0x48>
f010231c:	39 f7                	cmp    %esi,%edi
f010231e:	76 50                	jbe    f0102370 <__umoddi3+0x80>
f0102320:	89 c8                	mov    %ecx,%eax
f0102322:	89 f2                	mov    %esi,%edx
f0102324:	f7 f7                	div    %edi
f0102326:	89 d0                	mov    %edx,%eax
f0102328:	31 d2                	xor    %edx,%edx
f010232a:	83 c4 1c             	add    $0x1c,%esp
f010232d:	5b                   	pop    %ebx
f010232e:	5e                   	pop    %esi
f010232f:	5f                   	pop    %edi
f0102330:	5d                   	pop    %ebp
f0102331:	c3                   	ret    
f0102332:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102338:	39 f2                	cmp    %esi,%edx
f010233a:	89 d0                	mov    %edx,%eax
f010233c:	77 52                	ja     f0102390 <__umoddi3+0xa0>
f010233e:	0f bd ea             	bsr    %edx,%ebp
f0102341:	83 f5 1f             	xor    $0x1f,%ebp
f0102344:	75 5a                	jne    f01023a0 <__umoddi3+0xb0>
f0102346:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010234a:	0f 82 e0 00 00 00    	jb     f0102430 <__umoddi3+0x140>
f0102350:	39 0c 24             	cmp    %ecx,(%esp)
f0102353:	0f 86 d7 00 00 00    	jbe    f0102430 <__umoddi3+0x140>
f0102359:	8b 44 24 08          	mov    0x8(%esp),%eax
f010235d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0102361:	83 c4 1c             	add    $0x1c,%esp
f0102364:	5b                   	pop    %ebx
f0102365:	5e                   	pop    %esi
f0102366:	5f                   	pop    %edi
f0102367:	5d                   	pop    %ebp
f0102368:	c3                   	ret    
f0102369:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102370:	85 ff                	test   %edi,%edi
f0102372:	89 fd                	mov    %edi,%ebp
f0102374:	75 0b                	jne    f0102381 <__umoddi3+0x91>
f0102376:	b8 01 00 00 00       	mov    $0x1,%eax
f010237b:	31 d2                	xor    %edx,%edx
f010237d:	f7 f7                	div    %edi
f010237f:	89 c5                	mov    %eax,%ebp
f0102381:	89 f0                	mov    %esi,%eax
f0102383:	31 d2                	xor    %edx,%edx
f0102385:	f7 f5                	div    %ebp
f0102387:	89 c8                	mov    %ecx,%eax
f0102389:	f7 f5                	div    %ebp
f010238b:	89 d0                	mov    %edx,%eax
f010238d:	eb 99                	jmp    f0102328 <__umoddi3+0x38>
f010238f:	90                   	nop
f0102390:	89 c8                	mov    %ecx,%eax
f0102392:	89 f2                	mov    %esi,%edx
f0102394:	83 c4 1c             	add    $0x1c,%esp
f0102397:	5b                   	pop    %ebx
f0102398:	5e                   	pop    %esi
f0102399:	5f                   	pop    %edi
f010239a:	5d                   	pop    %ebp
f010239b:	c3                   	ret    
f010239c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01023a0:	8b 34 24             	mov    (%esp),%esi
f01023a3:	bf 20 00 00 00       	mov    $0x20,%edi
f01023a8:	89 e9                	mov    %ebp,%ecx
f01023aa:	29 ef                	sub    %ebp,%edi
f01023ac:	d3 e0                	shl    %cl,%eax
f01023ae:	89 f9                	mov    %edi,%ecx
f01023b0:	89 f2                	mov    %esi,%edx
f01023b2:	d3 ea                	shr    %cl,%edx
f01023b4:	89 e9                	mov    %ebp,%ecx
f01023b6:	09 c2                	or     %eax,%edx
f01023b8:	89 d8                	mov    %ebx,%eax
f01023ba:	89 14 24             	mov    %edx,(%esp)
f01023bd:	89 f2                	mov    %esi,%edx
f01023bf:	d3 e2                	shl    %cl,%edx
f01023c1:	89 f9                	mov    %edi,%ecx
f01023c3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01023c7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01023cb:	d3 e8                	shr    %cl,%eax
f01023cd:	89 e9                	mov    %ebp,%ecx
f01023cf:	89 c6                	mov    %eax,%esi
f01023d1:	d3 e3                	shl    %cl,%ebx
f01023d3:	89 f9                	mov    %edi,%ecx
f01023d5:	89 d0                	mov    %edx,%eax
f01023d7:	d3 e8                	shr    %cl,%eax
f01023d9:	89 e9                	mov    %ebp,%ecx
f01023db:	09 d8                	or     %ebx,%eax
f01023dd:	89 d3                	mov    %edx,%ebx
f01023df:	89 f2                	mov    %esi,%edx
f01023e1:	f7 34 24             	divl   (%esp)
f01023e4:	89 d6                	mov    %edx,%esi
f01023e6:	d3 e3                	shl    %cl,%ebx
f01023e8:	f7 64 24 04          	mull   0x4(%esp)
f01023ec:	39 d6                	cmp    %edx,%esi
f01023ee:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01023f2:	89 d1                	mov    %edx,%ecx
f01023f4:	89 c3                	mov    %eax,%ebx
f01023f6:	72 08                	jb     f0102400 <__umoddi3+0x110>
f01023f8:	75 11                	jne    f010240b <__umoddi3+0x11b>
f01023fa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01023fe:	73 0b                	jae    f010240b <__umoddi3+0x11b>
f0102400:	2b 44 24 04          	sub    0x4(%esp),%eax
f0102404:	1b 14 24             	sbb    (%esp),%edx
f0102407:	89 d1                	mov    %edx,%ecx
f0102409:	89 c3                	mov    %eax,%ebx
f010240b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010240f:	29 da                	sub    %ebx,%edx
f0102411:	19 ce                	sbb    %ecx,%esi
f0102413:	89 f9                	mov    %edi,%ecx
f0102415:	89 f0                	mov    %esi,%eax
f0102417:	d3 e0                	shl    %cl,%eax
f0102419:	89 e9                	mov    %ebp,%ecx
f010241b:	d3 ea                	shr    %cl,%edx
f010241d:	89 e9                	mov    %ebp,%ecx
f010241f:	d3 ee                	shr    %cl,%esi
f0102421:	09 d0                	or     %edx,%eax
f0102423:	89 f2                	mov    %esi,%edx
f0102425:	83 c4 1c             	add    $0x1c,%esp
f0102428:	5b                   	pop    %ebx
f0102429:	5e                   	pop    %esi
f010242a:	5f                   	pop    %edi
f010242b:	5d                   	pop    %ebp
f010242c:	c3                   	ret    
f010242d:	8d 76 00             	lea    0x0(%esi),%esi
f0102430:	29 f9                	sub    %edi,%ecx
f0102432:	19 d6                	sbb    %edx,%esi
f0102434:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102438:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010243c:	e9 18 ff ff ff       	jmp    f0102359 <__umoddi3+0x69>

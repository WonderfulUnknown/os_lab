
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
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
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
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

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
f0100046:	b8 70 69 11 f0       	mov    $0xf0116970,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 63 11 f0       	push   $0xf0116300
f0100058:	e8 69 31 00 00       	call   f01031c6 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 bb 04 00 00       	call   f010051d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 60 36 10 f0       	push   $0xf0103660
f010006f:	e8 9e 26 00 00       	call   f0102712 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 a0 0f 00 00       	call   f0101019 <mem_init>
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
f0100093:	83 3d 60 69 11 f0 00 	cmpl   $0x0,0xf0116960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 69 11 f0    	mov    %esi,0xf0116960

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
f01000b0:	68 7b 36 10 f0       	push   $0xf010367b
f01000b5:	e8 58 26 00 00       	call   f0102712 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 28 26 00 00       	call   f01026ec <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 69 39 10 f0 	movl   $0xf0103969,(%esp)
f01000cb:	e8 42 26 00 00       	call   f0102712 <cprintf>
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
f01000f2:	68 93 36 10 f0       	push   $0xf0103693
f01000f7:	e8 16 26 00 00       	call   f0102712 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 e4 25 00 00       	call   f01026ec <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 69 39 10 f0 	movl   $0xf0103969,(%esp)
f010010f:	e8 fe 25 00 00       	call   f0102712 <cprintf>
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
f010014a:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f0100159:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
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
f0100198:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
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
f01001b0:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001b6:	89 cb                	mov    %ecx,%ebx
f01001b8:	83 e3 40             	and    $0x40,%ebx
f01001bb:	83 e0 7f             	and    $0x7f,%eax
f01001be:	85 db                	test   %ebx,%ebx
f01001c0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001c3:	0f b6 d2             	movzbl %dl,%edx
f01001c6:	0f b6 82 00 38 10 f0 	movzbl -0xfefc800(%edx),%eax
f01001cd:	83 c8 40             	or     $0x40,%eax
f01001d0:	0f b6 c0             	movzbl %al,%eax
f01001d3:	f7 d0                	not    %eax
f01001d5:	21 c8                	and    %ecx,%eax
f01001d7:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f01001dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e1:	e9 9e 00 00 00       	jmp    f0100284 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001e6:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01001ec:	f6 c1 40             	test   $0x40,%cl
f01001ef:	74 0e                	je     f01001ff <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f1:	83 c8 80             	or     $0xffffff80,%eax
f01001f4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001f6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001f9:	89 0d 00 63 11 f0    	mov    %ecx,0xf0116300
	}

	shift |= shiftcode[data];
f01001ff:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100202:	0f b6 82 00 38 10 f0 	movzbl -0xfefc800(%edx),%eax
f0100209:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f010020f:	0f b6 8a 00 37 10 f0 	movzbl -0xfefc900(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d e0 36 10 f0 	mov    -0xfefc920(,%ecx,4),%ecx
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
f0100260:	68 ad 36 10 f0       	push   $0xf01036ad
f0100265:	e8 a8 24 00 00       	call   f0102712 <cprintf>
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
f0100379:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f0100380:	66 85 c0             	test   %ax,%ax
f0100383:	0f 84 e6 00 00 00    	je     f010046f <cons_putc+0x1e6>
			crt_pos--;
f0100389:	83 e8 01             	sub    $0x1,%eax
f010038c:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100392:	0f b7 c0             	movzwl %ax,%eax
f0100395:	66 81 e7 00 ff       	and    $0xff00,%di
f010039a:	83 cf 20             	or     $0x20,%edi
f010039d:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f01003a3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003a7:	eb 78                	jmp    f0100421 <cons_putc+0x198>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003a9:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f01003b0:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003b1:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f01003b8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003be:	c1 e8 16             	shr    $0x16,%eax
f01003c1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003c4:	c1 e0 04             	shl    $0x4,%eax
f01003c7:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
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
f0100403:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f010040a:	8d 50 01             	lea    0x1(%eax),%edx
f010040d:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
f0100414:	0f b7 c0             	movzwl %ax,%eax
f0100417:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f010041d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100421:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f0100428:	cf 07 
f010042a:	76 43                	jbe    f010046f <cons_putc+0x1e6>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010042c:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f0100431:	83 ec 04             	sub    $0x4,%esp
f0100434:	68 00 0f 00 00       	push   $0xf00
f0100439:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010043f:	52                   	push   %edx
f0100440:	50                   	push   %eax
f0100441:	e8 cd 2d 00 00       	call   f0103213 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100446:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
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
f0100467:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f010046e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010046f:	8b 0d 30 65 11 f0    	mov    0xf0116530,%ecx
f0100475:	b8 0e 00 00 00       	mov    $0xe,%eax
f010047a:	89 ca                	mov    %ecx,%edx
f010047c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010047d:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
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
f01004a5:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
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
f01004e3:	a1 20 65 11 f0       	mov    0xf0116520,%eax
f01004e8:	3b 05 24 65 11 f0    	cmp    0xf0116524,%eax
f01004ee:	74 26                	je     f0100516 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004f0:	8d 50 01             	lea    0x1(%eax),%edx
f01004f3:	89 15 20 65 11 f0    	mov    %edx,0xf0116520
f01004f9:	0f b6 88 20 63 11 f0 	movzbl -0xfee9ce0(%eax),%ecx
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
f010050a:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
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
f0100543:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
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
f010055b:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
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
f010056a:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
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
f010058f:	89 35 2c 65 11 f0    	mov    %esi,0xf011652c
	crt_pos = pos;
f0100595:	0f b6 c0             	movzbl %al,%eax
f0100598:	09 c8                	or     %ecx,%eax
f010059a:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
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
f01005fb:	0f 95 05 34 65 11 f0 	setne  0xf0116534
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
f0100610:	68 b9 36 10 f0       	push   $0xf01036b9
f0100615:	e8 f8 20 00 00       	call   f0102712 <cprintf>
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
f0100656:	68 00 39 10 f0       	push   $0xf0103900
f010065b:	68 1e 39 10 f0       	push   $0xf010391e
f0100660:	68 23 39 10 f0       	push   $0xf0103923
f0100665:	e8 a8 20 00 00       	call   f0102712 <cprintf>
f010066a:	83 c4 0c             	add    $0xc,%esp
f010066d:	68 b8 39 10 f0       	push   $0xf01039b8
f0100672:	68 2c 39 10 f0       	push   $0xf010392c
f0100677:	68 23 39 10 f0       	push   $0xf0103923
f010067c:	e8 91 20 00 00       	call   f0102712 <cprintf>
f0100681:	83 c4 0c             	add    $0xc,%esp
f0100684:	68 e0 39 10 f0       	push   $0xf01039e0
f0100689:	68 35 39 10 f0       	push   $0xf0103935
f010068e:	68 23 39 10 f0       	push   $0xf0103923
f0100693:	e8 7a 20 00 00       	call   f0102712 <cprintf>
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
f01006a5:	68 3f 39 10 f0       	push   $0xf010393f
f01006aa:	e8 63 20 00 00       	call   f0102712 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006af:	83 c4 08             	add    $0x8,%esp
f01006b2:	68 0c 00 10 00       	push   $0x10000c
f01006b7:	68 08 3a 10 f0       	push   $0xf0103a08
f01006bc:	e8 51 20 00 00       	call   f0102712 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006c1:	83 c4 0c             	add    $0xc,%esp
f01006c4:	68 0c 00 10 00       	push   $0x10000c
f01006c9:	68 0c 00 10 f0       	push   $0xf010000c
f01006ce:	68 30 3a 10 f0       	push   $0xf0103a30
f01006d3:	e8 3a 20 00 00       	call   f0102712 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d8:	83 c4 0c             	add    $0xc,%esp
f01006db:	68 51 36 10 00       	push   $0x103651
f01006e0:	68 51 36 10 f0       	push   $0xf0103651
f01006e5:	68 54 3a 10 f0       	push   $0xf0103a54
f01006ea:	e8 23 20 00 00       	call   f0102712 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ef:	83 c4 0c             	add    $0xc,%esp
f01006f2:	68 00 63 11 00       	push   $0x116300
f01006f7:	68 00 63 11 f0       	push   $0xf0116300
f01006fc:	68 78 3a 10 f0       	push   $0xf0103a78
f0100701:	e8 0c 20 00 00       	call   f0102712 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100706:	83 c4 0c             	add    $0xc,%esp
f0100709:	68 70 69 11 00       	push   $0x116970
f010070e:	68 70 69 11 f0       	push   $0xf0116970
f0100713:	68 9c 3a 10 f0       	push   $0xf0103a9c
f0100718:	e8 f5 1f 00 00       	call   f0102712 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010071d:	b8 6f 6d 11 f0       	mov    $0xf0116d6f,%eax
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
f010073e:	68 c0 3a 10 f0       	push   $0xf0103ac0
f0100743:	e8 ca 1f 00 00       	call   f0102712 <cprintf>
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
f010075a:	68 58 39 10 f0       	push   $0xf0103958
f010075f:	e8 ae 1f 00 00       	call   f0102712 <cprintf>
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
f0100780:	68 ec 3a 10 f0       	push   $0xf0103aec
f0100785:	e8 88 1f 00 00       	call   f0102712 <cprintf>
	debuginfo_eip((uintptr_t)eip,&info);
f010078a:	83 c4 18             	add    $0x18,%esp
f010078d:	57                   	push   %edi
f010078e:	56                   	push   %esi
f010078f:	e8 88 20 00 00       	call   f010281c <debuginfo_eip>
	cprintf("%s:%d", info.eip_file, info.eip_line);
f0100794:	83 c4 0c             	add    $0xc,%esp
f0100797:	ff 75 d4             	pushl  -0x2c(%ebp)
f010079a:	ff 75 d0             	pushl  -0x30(%ebp)
f010079d:	68 6b 39 10 f0       	push   $0xf010396b
f01007a2:	e8 6b 1f 00 00       	call   f0102712 <cprintf>
        cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name,info.eip_fn_addr);
f01007a7:	ff 75 e0             	pushl  -0x20(%ebp)
f01007aa:	ff 75 d8             	pushl  -0x28(%ebp)
f01007ad:	ff 75 dc             	pushl  -0x24(%ebp)
f01007b0:	68 71 39 10 f0       	push   $0xf0103971
f01007b5:	e8 58 1f 00 00       	call   f0102712 <cprintf>
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
f01007d9:	68 24 3b 10 f0       	push   $0xf0103b24
f01007de:	e8 2f 1f 00 00       	call   f0102712 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007e3:	c7 04 24 48 3b 10 f0 	movl   $0xf0103b48,(%esp)
f01007ea:	e8 23 1f 00 00       	call   f0102712 <cprintf>
f01007ef:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007f2:	83 ec 0c             	sub    $0xc,%esp
f01007f5:	68 7c 39 10 f0       	push   $0xf010397c
f01007fa:	e8 70 27 00 00       	call   f0102f6f <readline>
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
f010082e:	68 80 39 10 f0       	push   $0xf0103980
f0100833:	e8 51 29 00 00       	call   f0103189 <strchr>
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
f010084e:	68 85 39 10 f0       	push   $0xf0103985
f0100853:	e8 ba 1e 00 00       	call   f0102712 <cprintf>
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
f0100877:	68 80 39 10 f0       	push   $0xf0103980
f010087c:	e8 08 29 00 00       	call   f0103189 <strchr>
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
f01008a5:	ff 34 85 80 3b 10 f0 	pushl  -0xfefc480(,%eax,4)
f01008ac:	ff 75 a8             	pushl  -0x58(%ebp)
f01008af:	e8 77 28 00 00       	call   f010312b <strcmp>
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
f01008c9:	ff 14 85 88 3b 10 f0 	call   *-0xfefc478(,%eax,4)


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
f01008ea:	68 a2 39 10 f0       	push   $0xf01039a2
f01008ef:	e8 1e 1e 00 00       	call   f0102712 <cprintf>
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
f0100907:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f010090e:	75 11                	jne    f0100921 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100910:	ba 6f 79 11 f0       	mov    $0xf011796f,%edx
f0100915:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010091b:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100921:	8b 0d 38 65 11 f0    	mov    0xf0116538,%ecx
	nextfree += n;
	nextfree = ROUNDUP( (char*)nextfree, PGSIZE);
f0100927:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f010092e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100934:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
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
f0100954:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
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
f0100963:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100968:	68 1d 03 00 00       	push   $0x31d
f010096d:	68 f8 42 10 f0       	push   $0xf01042f8
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
f01009bb:	68 c8 3b 10 f0       	push   $0xf0103bc8
f01009c0:	68 60 02 00 00       	push   $0x260
f01009c5:	68 f8 42 10 f0       	push   $0xf01042f8
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
f01009dd:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
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
f0100a13:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
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
f0100a1d:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100a23:	eb 53                	jmp    f0100a78 <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a25:	89 d8                	mov    %ebx,%eax
f0100a27:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
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
f0100a41:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100a47:	72 12                	jb     f0100a5b <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a49:	50                   	push   %eax
f0100a4a:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100a4f:	6a 52                	push   $0x52
f0100a51:	68 04 43 10 f0       	push   $0xf0104304
f0100a56:	e8 30 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a5b:	83 ec 04             	sub    $0x4,%esp
f0100a5e:	68 80 00 00 00       	push   $0x80
f0100a63:	68 97 00 00 00       	push   $0x97
f0100a68:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a6d:	50                   	push   %eax
f0100a6e:	e8 53 27 00 00       	call   f01031c6 <memset>
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
f0100a89:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a8f:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
		assert(pp < pages + npages);
f0100a95:	a1 64 69 11 f0       	mov    0xf0116964,%eax
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
f0100ab4:	68 12 43 10 f0       	push   $0xf0104312
f0100ab9:	68 1e 43 10 f0       	push   $0xf010431e
f0100abe:	68 7a 02 00 00       	push   $0x27a
f0100ac3:	68 f8 42 10 f0       	push   $0xf01042f8
f0100ac8:	e8 be f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100acd:	39 fa                	cmp    %edi,%edx
f0100acf:	72 19                	jb     f0100aea <check_page_free_list+0x148>
f0100ad1:	68 33 43 10 f0       	push   $0xf0104333
f0100ad6:	68 1e 43 10 f0       	push   $0xf010431e
f0100adb:	68 7b 02 00 00       	push   $0x27b
f0100ae0:	68 f8 42 10 f0       	push   $0xf01042f8
f0100ae5:	e8 a1 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aea:	89 d0                	mov    %edx,%eax
f0100aec:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100aef:	a8 07                	test   $0x7,%al
f0100af1:	74 19                	je     f0100b0c <check_page_free_list+0x16a>
f0100af3:	68 ec 3b 10 f0       	push   $0xf0103bec
f0100af8:	68 1e 43 10 f0       	push   $0xf010431e
f0100afd:	68 7c 02 00 00       	push   $0x27c
f0100b02:	68 f8 42 10 f0       	push   $0xf01042f8
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
f0100b16:	68 47 43 10 f0       	push   $0xf0104347
f0100b1b:	68 1e 43 10 f0       	push   $0xf010431e
f0100b20:	68 7f 02 00 00       	push   $0x27f
f0100b25:	68 f8 42 10 f0       	push   $0xf01042f8
f0100b2a:	e8 5c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b2f:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b34:	75 19                	jne    f0100b4f <check_page_free_list+0x1ad>
f0100b36:	68 58 43 10 f0       	push   $0xf0104358
f0100b3b:	68 1e 43 10 f0       	push   $0xf010431e
f0100b40:	68 80 02 00 00       	push   $0x280
f0100b45:	68 f8 42 10 f0       	push   $0xf01042f8
f0100b4a:	e8 3c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b4f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b54:	75 19                	jne    f0100b6f <check_page_free_list+0x1cd>
f0100b56:	68 20 3c 10 f0       	push   $0xf0103c20
f0100b5b:	68 1e 43 10 f0       	push   $0xf010431e
f0100b60:	68 81 02 00 00       	push   $0x281
f0100b65:	68 f8 42 10 f0       	push   $0xf01042f8
f0100b6a:	e8 1c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b6f:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b74:	75 19                	jne    f0100b8f <check_page_free_list+0x1ed>
f0100b76:	68 71 43 10 f0       	push   $0xf0104371
f0100b7b:	68 1e 43 10 f0       	push   $0xf010431e
f0100b80:	68 82 02 00 00       	push   $0x282
f0100b85:	68 f8 42 10 f0       	push   $0xf01042f8
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
f0100ba1:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100ba6:	6a 52                	push   $0x52
f0100ba8:	68 04 43 10 f0       	push   $0xf0104304
f0100bad:	e8 d9 f4 ff ff       	call   f010008b <_panic>
f0100bb2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bb7:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bba:	76 1e                	jbe    f0100bda <check_page_free_list+0x238>
f0100bbc:	68 44 3c 10 f0       	push   $0xf0103c44
f0100bc1:	68 1e 43 10 f0       	push   $0xf010431e
f0100bc6:	68 83 02 00 00       	push   $0x283
f0100bcb:	68 f8 42 10 f0       	push   $0xf01042f8
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
f0100bef:	68 8b 43 10 f0       	push   $0xf010438b
f0100bf4:	68 1e 43 10 f0       	push   $0xf010431e
f0100bf9:	68 8b 02 00 00       	push   $0x28b
f0100bfe:	68 f8 42 10 f0       	push   $0xf01042f8
f0100c03:	e8 83 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c08:	85 db                	test   %ebx,%ebx
f0100c0a:	7f 42                	jg     f0100c4e <check_page_free_list+0x2ac>
f0100c0c:	68 9d 43 10 f0       	push   $0xf010439d
f0100c11:	68 1e 43 10 f0       	push   $0xf010431e
f0100c16:	68 8c 02 00 00       	push   $0x28c
f0100c1b:	68 f8 42 10 f0       	push   $0xf01042f8
f0100c20:	e8 66 f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c25:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100c2a:	85 c0                	test   %eax,%eax
f0100c2c:	0f 85 9d fd ff ff    	jne    f01009cf <check_page_free_list+0x2d>
f0100c32:	e9 81 fd ff ff       	jmp    f01009b8 <check_page_free_list+0x16>
f0100c37:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
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
f0100c5b:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
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
f0100c7b:	3b 1d 40 65 11 f0    	cmp    0xf0116540,%ebx
f0100c81:	73 25                	jae    f0100ca8 <page_init+0x52>
			pages[i].pp_ref = 0;
f0100c83:	89 f0                	mov    %esi,%eax
f0100c85:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100c8b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100c91:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100c97:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100c99:	89 f0                	mov    %esi,%eax
f0100c9b:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100ca1:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
f0100ca6:	eb 78                	jmp    f0100d20 <page_init+0xca>
		}
	//  3) Then comes the IO hole 
		else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE){
f0100ca8:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100cae:	83 f8 5f             	cmp    $0x5f,%eax
f0100cb1:	77 16                	ja     f0100cc9 <page_init+0x73>
			pages[i].pp_ref = 1;
f0100cb3:	89 f0                	mov    %esi,%eax
f0100cb5:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
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
f0100ce9:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100cef:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100cf5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100cfb:	eb 23                	jmp    f0100d20 <page_init+0xca>
		}
		else{
			pages[i].pp_ref = 0;
f0100cfd:	89 f0                	mov    %esi,%eax
f0100cff:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100d05:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100d0b:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100d11:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100d13:	89 f0                	mov    %esi,%eax
f0100d15:	03 05 6c 69 11 f0    	add    0xf011696c,%eax
f0100d1b:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	//  1) Mark physical page 0 as in use.
	pages[0].pp_ref = 1;
	pages[0].pp_link = NULL;	
	size_t i;
	//临界点是否等于可能存在问题
	for (i = 1; i < npages; i++) {
f0100d20:	83 c3 01             	add    $0x1,%ebx
f0100d23:	83 c6 08             	add    $0x8,%esi
f0100d26:	3b 1d 64 69 11 f0    	cmp    0xf0116964,%ebx
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
	// Fill this function in
	//cprintf("page_alloc\r\n");
	if(page_free_list == NULL)
f0100d3d:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100d43:	85 db                	test   %ebx,%ebx
f0100d45:	74 6e                	je     f0100db5 <page_alloc+0x7f>
		//addr = page2kva(page_free_list);
		//int *iq,*ip;
		//iq=ip;//将把ip中的值拷贝到iq中，这样，指针iq也将指向ip指向的对象
		struct PageInfo *Page;
		Page = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100d47:	8b 03                	mov    (%ebx),%eax
f0100d49:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
		//page_free_list->pp_link = NULL;
		Page->pp_link = NULL;
f0100d4e:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		//Page->pp_ref = 1;
		Page->pp_ref = 0;
f0100d54:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		cprintf("page_alloc\r\n");
f0100d5a:	83 ec 0c             	sub    $0xc,%esp
f0100d5d:	68 ae 43 10 f0       	push   $0xf01043ae
f0100d62:	e8 ab 19 00 00       	call   f0102712 <cprintf>
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
f0100d72:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100d78:	c1 f8 03             	sar    $0x3,%eax
f0100d7b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d7e:	89 c2                	mov    %eax,%edx
f0100d80:	c1 ea 0c             	shr    $0xc,%edx
f0100d83:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0100d89:	72 12                	jb     f0100d9d <page_alloc+0x67>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d8b:	50                   	push   %eax
f0100d8c:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100d91:	6a 52                	push   $0x52
f0100d93:	68 04 43 10 f0       	push   $0xf0104304
f0100d98:	e8 ee f2 ff ff       	call   f010008b <_panic>
			memset(page2kva(Page),'\0',PGSIZE);
f0100d9d:	83 ec 04             	sub    $0x4,%esp
f0100da0:	68 00 10 00 00       	push   $0x1000
f0100da5:	6a 00                	push   $0x0
f0100da7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dac:	50                   	push   %eax
f0100dad:	e8 14 24 00 00       	call   f01031c6 <memset>
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
f0100dc5:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100dcb:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100dcd:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	//pp->pp_ref = 0;
	cprintf("page_free\r\n");
f0100dd2:	68 bb 43 10 f0       	push   $0xf01043bb
f0100dd7:	e8 36 19 00 00       	call   f0102712 <cprintf>
}
f0100ddc:	83 c4 10             	add    $0x10,%esp
f0100ddf:	c9                   	leave  
f0100de0:	c3                   	ret    

f0100de1 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100de1:	55                   	push   %ebp
f0100de2:	89 e5                	mov    %esp,%ebp
f0100de4:	83 ec 08             	sub    $0x8,%esp
f0100de7:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100dea:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100dee:	83 e8 01             	sub    $0x1,%eax
f0100df1:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100df5:	66 85 c0             	test   %ax,%ax
f0100df8:	75 0c                	jne    f0100e06 <page_decref+0x25>
		page_free(pp);
f0100dfa:	83 ec 0c             	sub    $0xc,%esp
f0100dfd:	52                   	push   %edx
f0100dfe:	e8 b9 ff ff ff       	call   f0100dbc <page_free>
f0100e03:	83 c4 10             	add    $0x10,%esp
}
f0100e06:	c9                   	leave  
f0100e07:	c3                   	ret    

f0100e08 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e08:	55                   	push   %ebp
f0100e09:	89 e5                	mov    %esp,%ebp
f0100e0b:	56                   	push   %esi
f0100e0c:	53                   	push   %ebx
f0100e0d:	8b 45 0c             	mov    0xc(%ebp),%eax
	// Fill this function in
	uint32_t pd_number,pt_number,pt_addr;//,page_number,page_addr;
	pte_t *pte = NULL;
	struct PageInfo *Page;
	pd_number = PDX(va);
	pt_number = PTX(va);
f0100e10:	89 c6                	mov    %eax,%esi
f0100e12:	c1 ee 0c             	shr    $0xc,%esi
f0100e15:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	if(pgdir[pd_number] & PTE_P)
f0100e1b:	c1 e8 16             	shr    $0x16,%eax
f0100e1e:	8d 1c 85 00 00 00 00 	lea    0x0(,%eax,4),%ebx
f0100e25:	03 5d 08             	add    0x8(%ebp),%ebx
f0100e28:	8b 03                	mov    (%ebx),%eax
f0100e2a:	a8 01                	test   $0x1,%al
f0100e2c:	74 2e                	je     f0100e5c <pgdir_walk+0x54>
		pte = KADDR(PTE_ADDR(pgdir[pd_number]));
f0100e2e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e33:	89 c2                	mov    %eax,%edx
f0100e35:	c1 ea 0c             	shr    $0xc,%edx
f0100e38:	39 15 64 69 11 f0    	cmp    %edx,0xf0116964
f0100e3e:	77 15                	ja     f0100e55 <pgdir_walk+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e40:	50                   	push   %eax
f0100e41:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100e46:	68 86 01 00 00       	push   $0x186
f0100e4b:	68 f8 42 10 f0       	push   $0xf01042f8
f0100e50:	e8 36 f2 ff ff       	call   f010008b <_panic>
	if(!pte){
f0100e55:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e5a:	75 58                	jne    f0100eb4 <pgdir_walk+0xac>
		if(!create)
f0100e5c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e60:	74 57                	je     f0100eb9 <pgdir_walk+0xb1>
	 		return NULL;
	 	Page = page_alloc(create);
f0100e62:	83 ec 0c             	sub    $0xc,%esp
f0100e65:	ff 75 10             	pushl  0x10(%ebp)
f0100e68:	e8 c9 fe ff ff       	call   f0100d36 <page_alloc>
		if(!Page)
f0100e6d:	83 c4 10             	add    $0x10,%esp
f0100e70:	85 c0                	test   %eax,%eax
f0100e72:	74 4c                	je     f0100ec0 <pgdir_walk+0xb8>
			return NULL;
		Page->pp_ref ++;
f0100e74:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e79:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0100e7f:	89 c2                	mov    %eax,%edx
f0100e81:	c1 fa 03             	sar    $0x3,%edx
f0100e84:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e87:	89 d0                	mov    %edx,%eax
f0100e89:	c1 e8 0c             	shr    $0xc,%eax
f0100e8c:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0100e92:	72 15                	jb     f0100ea9 <pgdir_walk+0xa1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e94:	52                   	push   %edx
f0100e95:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100e9a:	68 8e 01 00 00       	push   $0x18e
f0100e9f:	68 f8 42 10 f0       	push   $0xf01042f8
f0100ea4:	e8 e2 f1 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100ea9:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	 	pte = KADDR(page2pa(Page));		
		// pgdir[pd_number] = page2pa(Page);
		pgdir[pd_number] = page2pa(Page) | PTE_P | PTE_W | PTE_U;
f0100eaf:	83 ca 07             	or     $0x7,%edx
f0100eb2:	89 13                	mov    %edx,(%ebx)
	}
	return &(pte[pt_number]);
f0100eb4:	8d 04 b0             	lea    (%eax,%esi,4),%eax
f0100eb7:	eb 0c                	jmp    f0100ec5 <pgdir_walk+0xbd>
	pt_number = PTX(va);
	if(pgdir[pd_number] & PTE_P)
		pte = KADDR(PTE_ADDR(pgdir[pd_number]));
	if(!pte){
		if(!create)
	 		return NULL;
f0100eb9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ebe:	eb 05                	jmp    f0100ec5 <pgdir_walk+0xbd>
	 	Page = page_alloc(create);
		if(!Page)
			return NULL;
f0100ec0:	b8 00 00 00 00       	mov    $0x0,%eax
	// //不确定page_alloc函数里应该填入的参数,page_alloc(int alloc_flags)
	// 	Page = page_alloc(create);
	// 	page_addr = page2pa(Page);
	// }
	// return page_addr;
}
f0100ec5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ec8:	5b                   	pop    %ebx
f0100ec9:	5e                   	pop    %esi
f0100eca:	5d                   	pop    %ebp
f0100ecb:	c3                   	ret    

f0100ecc <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100ecc:	55                   	push   %ebp
f0100ecd:	89 e5                	mov    %esp,%ebp
f0100ecf:	57                   	push   %edi
f0100ed0:	56                   	push   %esi
f0100ed1:	53                   	push   %ebx
f0100ed2:	83 ec 1c             	sub    $0x1c,%esp
f0100ed5:	89 c7                	mov    %eax,%edi
f0100ed7:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100eda:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	pte_t *pte = NULL;
	for(int i = 0;i < size;i += PGSIZE){
f0100edd:	bb 00 00 00 00       	mov    $0x0,%ebx
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
f0100ee2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ee5:	83 c8 01             	or     $0x1,%eax
f0100ee8:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte = NULL;
	for(int i = 0;i < size;i += PGSIZE){
f0100eeb:	eb 1f                	jmp    f0100f0c <boot_map_region+0x40>
		pte = pgdir_walk(pgdir, (void *)va, 1);
f0100eed:	83 ec 04             	sub    $0x4,%esp
f0100ef0:	6a 01                	push   $0x1
f0100ef2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ef5:	01 d8                	add    %ebx,%eax
f0100ef7:	50                   	push   %eax
f0100ef8:	57                   	push   %edi
f0100ef9:	e8 0a ff ff ff       	call   f0100e08 <pgdir_walk>
		*pte = (pa | perm | PTE_P);
f0100efe:	0b 75 dc             	or     -0x24(%ebp),%esi
f0100f01:	89 30                	mov    %esi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte = NULL;
	for(int i = 0;i < size;i += PGSIZE){
f0100f03:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f09:	83 c4 10             	add    $0x10,%esp
f0100f0c:	89 de                	mov    %ebx,%esi
f0100f0e:	03 75 08             	add    0x8(%ebp),%esi
f0100f11:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0100f14:	77 d7                	ja     f0100eed <boot_map_region+0x21>
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f0100f16:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f19:	5b                   	pop    %ebx
f0100f1a:	5e                   	pop    %esi
f0100f1b:	5f                   	pop    %edi
f0100f1c:	5d                   	pop    %ebp
f0100f1d:	c3                   	ret    

f0100f1e <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f1e:	55                   	push   %ebp
f0100f1f:	89 e5                	mov    %esp,%ebp
f0100f21:	53                   	push   %ebx
f0100f22:	83 ec 08             	sub    $0x8,%esp
f0100f25:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
f0100f28:	6a 00                	push   $0x0
f0100f2a:	ff 75 0c             	pushl  0xc(%ebp)
f0100f2d:	ff 75 08             	pushl  0x8(%ebp)
f0100f30:	e8 d3 fe ff ff       	call   f0100e08 <pgdir_walk>
	if(!pte)
f0100f35:	83 c4 10             	add    $0x10,%esp
f0100f38:	85 c0                	test   %eax,%eax
f0100f3a:	74 32                	je     f0100f6e <page_lookup+0x50>
		return NULL;
	if(pte_store)
f0100f3c:	85 db                	test   %ebx,%ebx
f0100f3e:	74 02                	je     f0100f42 <page_lookup+0x24>
		*pte_store = pte;
f0100f40:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f42:	8b 00                	mov    (%eax),%eax
f0100f44:	c1 e8 0c             	shr    $0xc,%eax
f0100f47:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0100f4d:	72 14                	jb     f0100f63 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100f4f:	83 ec 04             	sub    $0x4,%esp
f0100f52:	68 8c 3c 10 f0       	push   $0xf0103c8c
f0100f57:	6a 4b                	push   $0x4b
f0100f59:	68 04 43 10 f0       	push   $0xf0104304
f0100f5e:	e8 28 f1 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100f63:	8b 15 6c 69 11 f0    	mov    0xf011696c,%edx
f0100f69:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	return pa2page(PTE_ADDR(*pte));
f0100f6c:	eb 05                	jmp    f0100f73 <page_lookup+0x55>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
	if(!pte)
		return NULL;
f0100f6e:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f0100f73:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f76:	c9                   	leave  
f0100f77:	c3                   	ret    

f0100f78 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100f78:	55                   	push   %ebp
f0100f79:	89 e5                	mov    %esp,%ebp
f0100f7b:	53                   	push   %ebx
f0100f7c:	83 ec 18             	sub    $0x18,%esp
f0100f7f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	// pte_t *pte,**pte_store;
	// pte = pgdir_walk(pgdir, (void *)va, 0);
	// pte_store = &pte;
	struct PageInfo *Page;
	Page = page_lookup(pgdir, va, &pte);
f0100f82:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100f85:	50                   	push   %eax
f0100f86:	53                   	push   %ebx
f0100f87:	ff 75 08             	pushl  0x8(%ebp)
f0100f8a:	e8 8f ff ff ff       	call   f0100f1e <page_lookup>
	// Page = page_lookup(pgdir, va, pte_store);
	if(Page){
f0100f8f:	83 c4 10             	add    $0x10,%esp
f0100f92:	85 c0                	test   %eax,%eax
f0100f94:	74 18                	je     f0100fae <page_remove+0x36>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f96:	0f 01 3b             	invlpg (%ebx)
		// Page->pp_ref --;
		tlb_invalidate(pgdir, va);
		page_decref(Page);
f0100f99:	83 ec 0c             	sub    $0xc,%esp
f0100f9c:	50                   	push   %eax
f0100f9d:	e8 3f fe ff ff       	call   f0100de1 <page_decref>
		*pte = 0;//将对应的页表项清空
f0100fa2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100fa5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100fab:	83 c4 10             	add    $0x10,%esp
	}
}
f0100fae:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fb1:	c9                   	leave  
f0100fb2:	c3                   	ret    

f0100fb3 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100fb3:	55                   	push   %ebp
f0100fb4:	89 e5                	mov    %esp,%ebp
f0100fb6:	57                   	push   %edi
f0100fb7:	56                   	push   %esi
f0100fb8:	53                   	push   %ebx
f0100fb9:	83 ec 10             	sub    $0x10,%esp
f0100fbc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fbf:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
f0100fc2:	6a 01                	push   $0x1
f0100fc4:	57                   	push   %edi
f0100fc5:	ff 75 08             	pushl  0x8(%ebp)
f0100fc8:	e8 3b fe ff ff       	call   f0100e08 <pgdir_walk>
	if(!pte)
f0100fcd:	83 c4 10             	add    $0x10,%esp
f0100fd0:	85 c0                	test   %eax,%eax
f0100fd2:	74 38                	je     f010100c <page_insert+0x59>
f0100fd4:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	pp->pp_ref++;
f0100fd6:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	//删除旧映射关系 
    if((*pte) & PTE_P)
f0100fdb:	f6 00 01             	testb  $0x1,(%eax)
f0100fde:	74 0f                	je     f0100fef <page_insert+0x3c>
        page_remove(pgdir, va);
f0100fe0:	83 ec 08             	sub    $0x8,%esp
f0100fe3:	57                   	push   %edi
f0100fe4:	ff 75 08             	pushl  0x8(%ebp)
f0100fe7:	e8 8c ff ff ff       	call   f0100f78 <page_remove>
f0100fec:	83 c4 10             	add    $0x10,%esp
	//pp ->pp_ref++;
    *pte = page2pa(pp) | perm | PTE_P;
f0100fef:	2b 1d 6c 69 11 f0    	sub    0xf011696c,%ebx
f0100ff5:	c1 fb 03             	sar    $0x3,%ebx
f0100ff8:	c1 e3 0c             	shl    $0xc,%ebx
f0100ffb:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ffe:	83 c8 01             	or     $0x1,%eax
f0101001:	09 c3                	or     %eax,%ebx
f0101003:	89 1e                	mov    %ebx,(%esi)
	return 0;
f0101005:	b8 00 00 00 00       	mov    $0x0,%eax
f010100a:	eb 05                	jmp    f0101011 <page_insert+0x5e>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
	if(!pte)
		return -E_NO_MEM;
f010100c:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	// 		page_remove(pgdir, va); 
	// }
	// //pp->pp_ref++;
    // *pte = page2pa(pp) | perm | PTE_P;
	// return 0;
}
f0101011:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101014:	5b                   	pop    %ebx
f0101015:	5e                   	pop    %esi
f0101016:	5f                   	pop    %edi
f0101017:	5d                   	pop    %ebp
f0101018:	c3                   	ret    

f0101019 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101019:	55                   	push   %ebp
f010101a:	89 e5                	mov    %esp,%ebp
f010101c:	57                   	push   %edi
f010101d:	56                   	push   %esi
f010101e:	53                   	push   %ebx
f010101f:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101022:	6a 15                	push   $0x15
f0101024:	e8 82 16 00 00       	call   f01026ab <mc146818_read>
f0101029:	89 c3                	mov    %eax,%ebx
f010102b:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101032:	e8 74 16 00 00       	call   f01026ab <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101037:	c1 e0 08             	shl    $0x8,%eax
f010103a:	09 d8                	or     %ebx,%eax
f010103c:	c1 e0 0a             	shl    $0xa,%eax
f010103f:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101045:	85 c0                	test   %eax,%eax
f0101047:	0f 48 c2             	cmovs  %edx,%eax
f010104a:	c1 f8 0c             	sar    $0xc,%eax
f010104d:	a3 40 65 11 f0       	mov    %eax,0xf0116540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101052:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101059:	e8 4d 16 00 00       	call   f01026ab <mc146818_read>
f010105e:	89 c3                	mov    %eax,%ebx
f0101060:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101067:	e8 3f 16 00 00       	call   f01026ab <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010106c:	c1 e0 08             	shl    $0x8,%eax
f010106f:	09 d8                	or     %ebx,%eax
f0101071:	c1 e0 0a             	shl    $0xa,%eax
f0101074:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010107a:	83 c4 10             	add    $0x10,%esp
f010107d:	85 c0                	test   %eax,%eax
f010107f:	0f 48 c2             	cmovs  %edx,%eax
f0101082:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101085:	85 c0                	test   %eax,%eax
f0101087:	74 0e                	je     f0101097 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101089:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010108f:	89 15 64 69 11 f0    	mov    %edx,0xf0116964
f0101095:	eb 0c                	jmp    f01010a3 <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101097:	8b 15 40 65 11 f0    	mov    0xf0116540,%edx
f010109d:	89 15 64 69 11 f0    	mov    %edx,0xf0116964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010a3:	c1 e0 0c             	shl    $0xc,%eax
f01010a6:	c1 e8 0a             	shr    $0xa,%eax
f01010a9:	50                   	push   %eax
f01010aa:	a1 40 65 11 f0       	mov    0xf0116540,%eax
f01010af:	c1 e0 0c             	shl    $0xc,%eax
f01010b2:	c1 e8 0a             	shr    $0xa,%eax
f01010b5:	50                   	push   %eax
f01010b6:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f01010bb:	c1 e0 0c             	shl    $0xc,%eax
f01010be:	c1 e8 0a             	shr    $0xa,%eax
f01010c1:	50                   	push   %eax
f01010c2:	68 ac 3c 10 f0       	push   $0xf0103cac
f01010c7:	e8 46 16 00 00       	call   f0102712 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010cc:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010d1:	e8 2e f8 ff ff       	call   f0100904 <boot_alloc>
f01010d6:	a3 68 69 11 f0       	mov    %eax,0xf0116968
	memset(kern_pgdir, 0, PGSIZE);
f01010db:	83 c4 0c             	add    $0xc,%esp
f01010de:	68 00 10 00 00       	push   $0x1000
f01010e3:	6a 00                	push   $0x0
f01010e5:	50                   	push   %eax
f01010e6:	e8 db 20 00 00       	call   f01031c6 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010eb:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010f0:	83 c4 10             	add    $0x10,%esp
f01010f3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010f8:	77 15                	ja     f010110f <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010fa:	50                   	push   %eax
f01010fb:	68 e8 3c 10 f0       	push   $0xf0103ce8
f0101100:	68 8d 00 00 00       	push   $0x8d
f0101105:	68 f8 42 10 f0       	push   $0xf01042f8
f010110a:	e8 7c ef ff ff       	call   f010008b <_panic>
f010110f:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101115:	83 ca 05             	or     $0x5,%edx
f0101118:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f010111e:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0101123:	c1 e0 03             	shl    $0x3,%eax
f0101126:	e8 d9 f7 ff ff       	call   f0100904 <boot_alloc>
f010112b:	a3 6c 69 11 f0       	mov    %eax,0xf011696c
	memset(pages,0,npages * sizeof(struct PageInfo));
f0101130:	83 ec 04             	sub    $0x4,%esp
f0101133:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0101139:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101140:	52                   	push   %edx
f0101141:	6a 00                	push   $0x0
f0101143:	50                   	push   %eax
f0101144:	e8 7d 20 00 00       	call   f01031c6 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101149:	e8 08 fb ff ff       	call   f0100c56 <page_init>

	check_page_free_list(1);
f010114e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101153:	e8 4a f8 ff ff       	call   f01009a2 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101158:	83 c4 10             	add    $0x10,%esp
f010115b:	83 3d 6c 69 11 f0 00 	cmpl   $0x0,0xf011696c
f0101162:	75 17                	jne    f010117b <mem_init+0x162>
		panic("'pages' is a null pointer!");
f0101164:	83 ec 04             	sub    $0x4,%esp
f0101167:	68 c7 43 10 f0       	push   $0xf01043c7
f010116c:	68 9d 02 00 00       	push   $0x29d
f0101171:	68 f8 42 10 f0       	push   $0xf01042f8
f0101176:	e8 10 ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010117b:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101180:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101185:	eb 05                	jmp    f010118c <mem_init+0x173>
		++nfree;
f0101187:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010118a:	8b 00                	mov    (%eax),%eax
f010118c:	85 c0                	test   %eax,%eax
f010118e:	75 f7                	jne    f0101187 <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101190:	83 ec 0c             	sub    $0xc,%esp
f0101193:	6a 00                	push   $0x0
f0101195:	e8 9c fb ff ff       	call   f0100d36 <page_alloc>
f010119a:	89 c7                	mov    %eax,%edi
f010119c:	83 c4 10             	add    $0x10,%esp
f010119f:	85 c0                	test   %eax,%eax
f01011a1:	75 19                	jne    f01011bc <mem_init+0x1a3>
f01011a3:	68 e2 43 10 f0       	push   $0xf01043e2
f01011a8:	68 1e 43 10 f0       	push   $0xf010431e
f01011ad:	68 a5 02 00 00       	push   $0x2a5
f01011b2:	68 f8 42 10 f0       	push   $0xf01042f8
f01011b7:	e8 cf ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01011bc:	83 ec 0c             	sub    $0xc,%esp
f01011bf:	6a 00                	push   $0x0
f01011c1:	e8 70 fb ff ff       	call   f0100d36 <page_alloc>
f01011c6:	89 c6                	mov    %eax,%esi
f01011c8:	83 c4 10             	add    $0x10,%esp
f01011cb:	85 c0                	test   %eax,%eax
f01011cd:	75 19                	jne    f01011e8 <mem_init+0x1cf>
f01011cf:	68 f8 43 10 f0       	push   $0xf01043f8
f01011d4:	68 1e 43 10 f0       	push   $0xf010431e
f01011d9:	68 a6 02 00 00       	push   $0x2a6
f01011de:	68 f8 42 10 f0       	push   $0xf01042f8
f01011e3:	e8 a3 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01011e8:	83 ec 0c             	sub    $0xc,%esp
f01011eb:	6a 00                	push   $0x0
f01011ed:	e8 44 fb ff ff       	call   f0100d36 <page_alloc>
f01011f2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01011f5:	83 c4 10             	add    $0x10,%esp
f01011f8:	85 c0                	test   %eax,%eax
f01011fa:	75 19                	jne    f0101215 <mem_init+0x1fc>
f01011fc:	68 0e 44 10 f0       	push   $0xf010440e
f0101201:	68 1e 43 10 f0       	push   $0xf010431e
f0101206:	68 a7 02 00 00       	push   $0x2a7
f010120b:	68 f8 42 10 f0       	push   $0xf01042f8
f0101210:	e8 76 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101215:	39 f7                	cmp    %esi,%edi
f0101217:	75 19                	jne    f0101232 <mem_init+0x219>
f0101219:	68 24 44 10 f0       	push   $0xf0104424
f010121e:	68 1e 43 10 f0       	push   $0xf010431e
f0101223:	68 aa 02 00 00       	push   $0x2aa
f0101228:	68 f8 42 10 f0       	push   $0xf01042f8
f010122d:	e8 59 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101232:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101235:	39 c6                	cmp    %eax,%esi
f0101237:	74 04                	je     f010123d <mem_init+0x224>
f0101239:	39 c7                	cmp    %eax,%edi
f010123b:	75 19                	jne    f0101256 <mem_init+0x23d>
f010123d:	68 0c 3d 10 f0       	push   $0xf0103d0c
f0101242:	68 1e 43 10 f0       	push   $0xf010431e
f0101247:	68 ab 02 00 00       	push   $0x2ab
f010124c:	68 f8 42 10 f0       	push   $0xf01042f8
f0101251:	e8 35 ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101256:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010125c:	8b 15 64 69 11 f0    	mov    0xf0116964,%edx
f0101262:	c1 e2 0c             	shl    $0xc,%edx
f0101265:	89 f8                	mov    %edi,%eax
f0101267:	29 c8                	sub    %ecx,%eax
f0101269:	c1 f8 03             	sar    $0x3,%eax
f010126c:	c1 e0 0c             	shl    $0xc,%eax
f010126f:	39 d0                	cmp    %edx,%eax
f0101271:	72 19                	jb     f010128c <mem_init+0x273>
f0101273:	68 36 44 10 f0       	push   $0xf0104436
f0101278:	68 1e 43 10 f0       	push   $0xf010431e
f010127d:	68 ac 02 00 00       	push   $0x2ac
f0101282:	68 f8 42 10 f0       	push   $0xf01042f8
f0101287:	e8 ff ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010128c:	89 f0                	mov    %esi,%eax
f010128e:	29 c8                	sub    %ecx,%eax
f0101290:	c1 f8 03             	sar    $0x3,%eax
f0101293:	c1 e0 0c             	shl    $0xc,%eax
f0101296:	39 c2                	cmp    %eax,%edx
f0101298:	77 19                	ja     f01012b3 <mem_init+0x29a>
f010129a:	68 53 44 10 f0       	push   $0xf0104453
f010129f:	68 1e 43 10 f0       	push   $0xf010431e
f01012a4:	68 ad 02 00 00       	push   $0x2ad
f01012a9:	68 f8 42 10 f0       	push   $0xf01042f8
f01012ae:	e8 d8 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012b3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012b6:	29 c8                	sub    %ecx,%eax
f01012b8:	c1 f8 03             	sar    $0x3,%eax
f01012bb:	c1 e0 0c             	shl    $0xc,%eax
f01012be:	39 c2                	cmp    %eax,%edx
f01012c0:	77 19                	ja     f01012db <mem_init+0x2c2>
f01012c2:	68 70 44 10 f0       	push   $0xf0104470
f01012c7:	68 1e 43 10 f0       	push   $0xf010431e
f01012cc:	68 ae 02 00 00       	push   $0x2ae
f01012d1:	68 f8 42 10 f0       	push   $0xf01042f8
f01012d6:	e8 b0 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012db:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01012e0:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01012e3:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01012ea:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01012ed:	83 ec 0c             	sub    $0xc,%esp
f01012f0:	6a 00                	push   $0x0
f01012f2:	e8 3f fa ff ff       	call   f0100d36 <page_alloc>
f01012f7:	83 c4 10             	add    $0x10,%esp
f01012fa:	85 c0                	test   %eax,%eax
f01012fc:	74 19                	je     f0101317 <mem_init+0x2fe>
f01012fe:	68 8d 44 10 f0       	push   $0xf010448d
f0101303:	68 1e 43 10 f0       	push   $0xf010431e
f0101308:	68 b5 02 00 00       	push   $0x2b5
f010130d:	68 f8 42 10 f0       	push   $0xf01042f8
f0101312:	e8 74 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101317:	83 ec 0c             	sub    $0xc,%esp
f010131a:	57                   	push   %edi
f010131b:	e8 9c fa ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f0101320:	89 34 24             	mov    %esi,(%esp)
f0101323:	e8 94 fa ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f0101328:	83 c4 04             	add    $0x4,%esp
f010132b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010132e:	e8 89 fa ff ff       	call   f0100dbc <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101333:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010133a:	e8 f7 f9 ff ff       	call   f0100d36 <page_alloc>
f010133f:	89 c6                	mov    %eax,%esi
f0101341:	83 c4 10             	add    $0x10,%esp
f0101344:	85 c0                	test   %eax,%eax
f0101346:	75 19                	jne    f0101361 <mem_init+0x348>
f0101348:	68 e2 43 10 f0       	push   $0xf01043e2
f010134d:	68 1e 43 10 f0       	push   $0xf010431e
f0101352:	68 bc 02 00 00       	push   $0x2bc
f0101357:	68 f8 42 10 f0       	push   $0xf01042f8
f010135c:	e8 2a ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101361:	83 ec 0c             	sub    $0xc,%esp
f0101364:	6a 00                	push   $0x0
f0101366:	e8 cb f9 ff ff       	call   f0100d36 <page_alloc>
f010136b:	89 c7                	mov    %eax,%edi
f010136d:	83 c4 10             	add    $0x10,%esp
f0101370:	85 c0                	test   %eax,%eax
f0101372:	75 19                	jne    f010138d <mem_init+0x374>
f0101374:	68 f8 43 10 f0       	push   $0xf01043f8
f0101379:	68 1e 43 10 f0       	push   $0xf010431e
f010137e:	68 bd 02 00 00       	push   $0x2bd
f0101383:	68 f8 42 10 f0       	push   $0xf01042f8
f0101388:	e8 fe ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010138d:	83 ec 0c             	sub    $0xc,%esp
f0101390:	6a 00                	push   $0x0
f0101392:	e8 9f f9 ff ff       	call   f0100d36 <page_alloc>
f0101397:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010139a:	83 c4 10             	add    $0x10,%esp
f010139d:	85 c0                	test   %eax,%eax
f010139f:	75 19                	jne    f01013ba <mem_init+0x3a1>
f01013a1:	68 0e 44 10 f0       	push   $0xf010440e
f01013a6:	68 1e 43 10 f0       	push   $0xf010431e
f01013ab:	68 be 02 00 00       	push   $0x2be
f01013b0:	68 f8 42 10 f0       	push   $0xf01042f8
f01013b5:	e8 d1 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013ba:	39 fe                	cmp    %edi,%esi
f01013bc:	75 19                	jne    f01013d7 <mem_init+0x3be>
f01013be:	68 24 44 10 f0       	push   $0xf0104424
f01013c3:	68 1e 43 10 f0       	push   $0xf010431e
f01013c8:	68 c0 02 00 00       	push   $0x2c0
f01013cd:	68 f8 42 10 f0       	push   $0xf01042f8
f01013d2:	e8 b4 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013d7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013da:	39 c7                	cmp    %eax,%edi
f01013dc:	74 04                	je     f01013e2 <mem_init+0x3c9>
f01013de:	39 c6                	cmp    %eax,%esi
f01013e0:	75 19                	jne    f01013fb <mem_init+0x3e2>
f01013e2:	68 0c 3d 10 f0       	push   $0xf0103d0c
f01013e7:	68 1e 43 10 f0       	push   $0xf010431e
f01013ec:	68 c1 02 00 00       	push   $0x2c1
f01013f1:	68 f8 42 10 f0       	push   $0xf01042f8
f01013f6:	e8 90 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01013fb:	83 ec 0c             	sub    $0xc,%esp
f01013fe:	6a 00                	push   $0x0
f0101400:	e8 31 f9 ff ff       	call   f0100d36 <page_alloc>
f0101405:	83 c4 10             	add    $0x10,%esp
f0101408:	85 c0                	test   %eax,%eax
f010140a:	74 19                	je     f0101425 <mem_init+0x40c>
f010140c:	68 8d 44 10 f0       	push   $0xf010448d
f0101411:	68 1e 43 10 f0       	push   $0xf010431e
f0101416:	68 c2 02 00 00       	push   $0x2c2
f010141b:	68 f8 42 10 f0       	push   $0xf01042f8
f0101420:	e8 66 ec ff ff       	call   f010008b <_panic>
f0101425:	89 f0                	mov    %esi,%eax
f0101427:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010142d:	c1 f8 03             	sar    $0x3,%eax
f0101430:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101433:	89 c2                	mov    %eax,%edx
f0101435:	c1 ea 0c             	shr    $0xc,%edx
f0101438:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f010143e:	72 12                	jb     f0101452 <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101440:	50                   	push   %eax
f0101441:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0101446:	6a 52                	push   $0x52
f0101448:	68 04 43 10 f0       	push   $0xf0104304
f010144d:	e8 39 ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101452:	83 ec 04             	sub    $0x4,%esp
f0101455:	68 00 10 00 00       	push   $0x1000
f010145a:	6a 01                	push   $0x1
f010145c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101461:	50                   	push   %eax
f0101462:	e8 5f 1d 00 00       	call   f01031c6 <memset>
	page_free(pp0);
f0101467:	89 34 24             	mov    %esi,(%esp)
f010146a:	e8 4d f9 ff ff       	call   f0100dbc <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010146f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101476:	e8 bb f8 ff ff       	call   f0100d36 <page_alloc>
f010147b:	83 c4 10             	add    $0x10,%esp
f010147e:	85 c0                	test   %eax,%eax
f0101480:	75 19                	jne    f010149b <mem_init+0x482>
f0101482:	68 9c 44 10 f0       	push   $0xf010449c
f0101487:	68 1e 43 10 f0       	push   $0xf010431e
f010148c:	68 c7 02 00 00       	push   $0x2c7
f0101491:	68 f8 42 10 f0       	push   $0xf01042f8
f0101496:	e8 f0 eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f010149b:	39 c6                	cmp    %eax,%esi
f010149d:	74 19                	je     f01014b8 <mem_init+0x49f>
f010149f:	68 ba 44 10 f0       	push   $0xf01044ba
f01014a4:	68 1e 43 10 f0       	push   $0xf010431e
f01014a9:	68 c8 02 00 00       	push   $0x2c8
f01014ae:	68 f8 42 10 f0       	push   $0xf01042f8
f01014b3:	e8 d3 eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014b8:	89 f0                	mov    %esi,%eax
f01014ba:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01014c0:	c1 f8 03             	sar    $0x3,%eax
f01014c3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014c6:	89 c2                	mov    %eax,%edx
f01014c8:	c1 ea 0c             	shr    $0xc,%edx
f01014cb:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01014d1:	72 12                	jb     f01014e5 <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014d3:	50                   	push   %eax
f01014d4:	68 a4 3b 10 f0       	push   $0xf0103ba4
f01014d9:	6a 52                	push   $0x52
f01014db:	68 04 43 10 f0       	push   $0xf0104304
f01014e0:	e8 a6 eb ff ff       	call   f010008b <_panic>
f01014e5:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01014eb:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014f1:	80 38 00             	cmpb   $0x0,(%eax)
f01014f4:	74 19                	je     f010150f <mem_init+0x4f6>
f01014f6:	68 ca 44 10 f0       	push   $0xf01044ca
f01014fb:	68 1e 43 10 f0       	push   $0xf010431e
f0101500:	68 cb 02 00 00       	push   $0x2cb
f0101505:	68 f8 42 10 f0       	push   $0xf01042f8
f010150a:	e8 7c eb ff ff       	call   f010008b <_panic>
f010150f:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101512:	39 d0                	cmp    %edx,%eax
f0101514:	75 db                	jne    f01014f1 <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101516:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101519:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f010151e:	83 ec 0c             	sub    $0xc,%esp
f0101521:	56                   	push   %esi
f0101522:	e8 95 f8 ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f0101527:	89 3c 24             	mov    %edi,(%esp)
f010152a:	e8 8d f8 ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f010152f:	83 c4 04             	add    $0x4,%esp
f0101532:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101535:	e8 82 f8 ff ff       	call   f0100dbc <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010153a:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010153f:	83 c4 10             	add    $0x10,%esp
f0101542:	eb 05                	jmp    f0101549 <mem_init+0x530>
		--nfree;
f0101544:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101547:	8b 00                	mov    (%eax),%eax
f0101549:	85 c0                	test   %eax,%eax
f010154b:	75 f7                	jne    f0101544 <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f010154d:	85 db                	test   %ebx,%ebx
f010154f:	74 19                	je     f010156a <mem_init+0x551>
f0101551:	68 d4 44 10 f0       	push   $0xf01044d4
f0101556:	68 1e 43 10 f0       	push   $0xf010431e
f010155b:	68 d8 02 00 00       	push   $0x2d8
f0101560:	68 f8 42 10 f0       	push   $0xf01042f8
f0101565:	e8 21 eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010156a:	83 ec 0c             	sub    $0xc,%esp
f010156d:	68 2c 3d 10 f0       	push   $0xf0103d2c
f0101572:	e8 9b 11 00 00       	call   f0102712 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101577:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010157e:	e8 b3 f7 ff ff       	call   f0100d36 <page_alloc>
f0101583:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101586:	83 c4 10             	add    $0x10,%esp
f0101589:	85 c0                	test   %eax,%eax
f010158b:	75 19                	jne    f01015a6 <mem_init+0x58d>
f010158d:	68 e2 43 10 f0       	push   $0xf01043e2
f0101592:	68 1e 43 10 f0       	push   $0xf010431e
f0101597:	68 31 03 00 00       	push   $0x331
f010159c:	68 f8 42 10 f0       	push   $0xf01042f8
f01015a1:	e8 e5 ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01015a6:	83 ec 0c             	sub    $0xc,%esp
f01015a9:	6a 00                	push   $0x0
f01015ab:	e8 86 f7 ff ff       	call   f0100d36 <page_alloc>
f01015b0:	89 c3                	mov    %eax,%ebx
f01015b2:	83 c4 10             	add    $0x10,%esp
f01015b5:	85 c0                	test   %eax,%eax
f01015b7:	75 19                	jne    f01015d2 <mem_init+0x5b9>
f01015b9:	68 f8 43 10 f0       	push   $0xf01043f8
f01015be:	68 1e 43 10 f0       	push   $0xf010431e
f01015c3:	68 32 03 00 00       	push   $0x332
f01015c8:	68 f8 42 10 f0       	push   $0xf01042f8
f01015cd:	e8 b9 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01015d2:	83 ec 0c             	sub    $0xc,%esp
f01015d5:	6a 00                	push   $0x0
f01015d7:	e8 5a f7 ff ff       	call   f0100d36 <page_alloc>
f01015dc:	89 c6                	mov    %eax,%esi
f01015de:	83 c4 10             	add    $0x10,%esp
f01015e1:	85 c0                	test   %eax,%eax
f01015e3:	75 19                	jne    f01015fe <mem_init+0x5e5>
f01015e5:	68 0e 44 10 f0       	push   $0xf010440e
f01015ea:	68 1e 43 10 f0       	push   $0xf010431e
f01015ef:	68 33 03 00 00       	push   $0x333
f01015f4:	68 f8 42 10 f0       	push   $0xf01042f8
f01015f9:	e8 8d ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015fe:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101601:	75 19                	jne    f010161c <mem_init+0x603>
f0101603:	68 24 44 10 f0       	push   $0xf0104424
f0101608:	68 1e 43 10 f0       	push   $0xf010431e
f010160d:	68 36 03 00 00       	push   $0x336
f0101612:	68 f8 42 10 f0       	push   $0xf01042f8
f0101617:	e8 6f ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010161c:	39 c3                	cmp    %eax,%ebx
f010161e:	74 05                	je     f0101625 <mem_init+0x60c>
f0101620:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101623:	75 19                	jne    f010163e <mem_init+0x625>
f0101625:	68 0c 3d 10 f0       	push   $0xf0103d0c
f010162a:	68 1e 43 10 f0       	push   $0xf010431e
f010162f:	68 37 03 00 00       	push   $0x337
f0101634:	68 f8 42 10 f0       	push   $0xf01042f8
f0101639:	e8 4d ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010163e:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101643:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101646:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f010164d:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101650:	83 ec 0c             	sub    $0xc,%esp
f0101653:	6a 00                	push   $0x0
f0101655:	e8 dc f6 ff ff       	call   f0100d36 <page_alloc>
f010165a:	83 c4 10             	add    $0x10,%esp
f010165d:	85 c0                	test   %eax,%eax
f010165f:	74 19                	je     f010167a <mem_init+0x661>
f0101661:	68 8d 44 10 f0       	push   $0xf010448d
f0101666:	68 1e 43 10 f0       	push   $0xf010431e
f010166b:	68 3e 03 00 00       	push   $0x33e
f0101670:	68 f8 42 10 f0       	push   $0xf01042f8
f0101675:	e8 11 ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010167a:	83 ec 04             	sub    $0x4,%esp
f010167d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101680:	50                   	push   %eax
f0101681:	6a 00                	push   $0x0
f0101683:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101689:	e8 90 f8 ff ff       	call   f0100f1e <page_lookup>
f010168e:	83 c4 10             	add    $0x10,%esp
f0101691:	85 c0                	test   %eax,%eax
f0101693:	74 19                	je     f01016ae <mem_init+0x695>
f0101695:	68 4c 3d 10 f0       	push   $0xf0103d4c
f010169a:	68 1e 43 10 f0       	push   $0xf010431e
f010169f:	68 41 03 00 00       	push   $0x341
f01016a4:	68 f8 42 10 f0       	push   $0xf01042f8
f01016a9:	e8 dd e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016ae:	6a 02                	push   $0x2
f01016b0:	6a 00                	push   $0x0
f01016b2:	53                   	push   %ebx
f01016b3:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01016b9:	e8 f5 f8 ff ff       	call   f0100fb3 <page_insert>
f01016be:	83 c4 10             	add    $0x10,%esp
f01016c1:	85 c0                	test   %eax,%eax
f01016c3:	78 19                	js     f01016de <mem_init+0x6c5>
f01016c5:	68 84 3d 10 f0       	push   $0xf0103d84
f01016ca:	68 1e 43 10 f0       	push   $0xf010431e
f01016cf:	68 44 03 00 00       	push   $0x344
f01016d4:	68 f8 42 10 f0       	push   $0xf01042f8
f01016d9:	e8 ad e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01016de:	83 ec 0c             	sub    $0xc,%esp
f01016e1:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016e4:	e8 d3 f6 ff ff       	call   f0100dbc <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01016e9:	6a 02                	push   $0x2
f01016eb:	6a 00                	push   $0x0
f01016ed:	53                   	push   %ebx
f01016ee:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01016f4:	e8 ba f8 ff ff       	call   f0100fb3 <page_insert>
f01016f9:	83 c4 20             	add    $0x20,%esp
f01016fc:	85 c0                	test   %eax,%eax
f01016fe:	74 19                	je     f0101719 <mem_init+0x700>
f0101700:	68 b4 3d 10 f0       	push   $0xf0103db4
f0101705:	68 1e 43 10 f0       	push   $0xf010431e
f010170a:	68 48 03 00 00       	push   $0x348
f010170f:	68 f8 42 10 f0       	push   $0xf01042f8
f0101714:	e8 72 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101719:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010171f:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0101724:	89 c1                	mov    %eax,%ecx
f0101726:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101729:	8b 17                	mov    (%edi),%edx
f010172b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101731:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101734:	29 c8                	sub    %ecx,%eax
f0101736:	c1 f8 03             	sar    $0x3,%eax
f0101739:	c1 e0 0c             	shl    $0xc,%eax
f010173c:	39 c2                	cmp    %eax,%edx
f010173e:	74 19                	je     f0101759 <mem_init+0x740>
f0101740:	68 e4 3d 10 f0       	push   $0xf0103de4
f0101745:	68 1e 43 10 f0       	push   $0xf010431e
f010174a:	68 49 03 00 00       	push   $0x349
f010174f:	68 f8 42 10 f0       	push   $0xf01042f8
f0101754:	e8 32 e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101759:	ba 00 00 00 00       	mov    $0x0,%edx
f010175e:	89 f8                	mov    %edi,%eax
f0101760:	e8 d9 f1 ff ff       	call   f010093e <check_va2pa>
f0101765:	89 da                	mov    %ebx,%edx
f0101767:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010176a:	c1 fa 03             	sar    $0x3,%edx
f010176d:	c1 e2 0c             	shl    $0xc,%edx
f0101770:	39 d0                	cmp    %edx,%eax
f0101772:	74 19                	je     f010178d <mem_init+0x774>
f0101774:	68 0c 3e 10 f0       	push   $0xf0103e0c
f0101779:	68 1e 43 10 f0       	push   $0xf010431e
f010177e:	68 4a 03 00 00       	push   $0x34a
f0101783:	68 f8 42 10 f0       	push   $0xf01042f8
f0101788:	e8 fe e8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f010178d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101792:	74 19                	je     f01017ad <mem_init+0x794>
f0101794:	68 df 44 10 f0       	push   $0xf01044df
f0101799:	68 1e 43 10 f0       	push   $0xf010431e
f010179e:	68 4b 03 00 00       	push   $0x34b
f01017a3:	68 f8 42 10 f0       	push   $0xf01042f8
f01017a8:	e8 de e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01017ad:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017b0:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01017b5:	74 19                	je     f01017d0 <mem_init+0x7b7>
f01017b7:	68 f0 44 10 f0       	push   $0xf01044f0
f01017bc:	68 1e 43 10 f0       	push   $0xf010431e
f01017c1:	68 4c 03 00 00       	push   $0x34c
f01017c6:	68 f8 42 10 f0       	push   $0xf01042f8
f01017cb:	e8 bb e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017d0:	6a 02                	push   $0x2
f01017d2:	68 00 10 00 00       	push   $0x1000
f01017d7:	56                   	push   %esi
f01017d8:	57                   	push   %edi
f01017d9:	e8 d5 f7 ff ff       	call   f0100fb3 <page_insert>
f01017de:	83 c4 10             	add    $0x10,%esp
f01017e1:	85 c0                	test   %eax,%eax
f01017e3:	74 19                	je     f01017fe <mem_init+0x7e5>
f01017e5:	68 3c 3e 10 f0       	push   $0xf0103e3c
f01017ea:	68 1e 43 10 f0       	push   $0xf010431e
f01017ef:	68 4f 03 00 00       	push   $0x34f
f01017f4:	68 f8 42 10 f0       	push   $0xf01042f8
f01017f9:	e8 8d e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017fe:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101803:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101808:	e8 31 f1 ff ff       	call   f010093e <check_va2pa>
f010180d:	89 f2                	mov    %esi,%edx
f010180f:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101815:	c1 fa 03             	sar    $0x3,%edx
f0101818:	c1 e2 0c             	shl    $0xc,%edx
f010181b:	39 d0                	cmp    %edx,%eax
f010181d:	74 19                	je     f0101838 <mem_init+0x81f>
f010181f:	68 78 3e 10 f0       	push   $0xf0103e78
f0101824:	68 1e 43 10 f0       	push   $0xf010431e
f0101829:	68 50 03 00 00       	push   $0x350
f010182e:	68 f8 42 10 f0       	push   $0xf01042f8
f0101833:	e8 53 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101838:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010183d:	74 19                	je     f0101858 <mem_init+0x83f>
f010183f:	68 01 45 10 f0       	push   $0xf0104501
f0101844:	68 1e 43 10 f0       	push   $0xf010431e
f0101849:	68 51 03 00 00       	push   $0x351
f010184e:	68 f8 42 10 f0       	push   $0xf01042f8
f0101853:	e8 33 e8 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101858:	83 ec 0c             	sub    $0xc,%esp
f010185b:	6a 00                	push   $0x0
f010185d:	e8 d4 f4 ff ff       	call   f0100d36 <page_alloc>
f0101862:	83 c4 10             	add    $0x10,%esp
f0101865:	85 c0                	test   %eax,%eax
f0101867:	74 19                	je     f0101882 <mem_init+0x869>
f0101869:	68 8d 44 10 f0       	push   $0xf010448d
f010186e:	68 1e 43 10 f0       	push   $0xf010431e
f0101873:	68 54 03 00 00       	push   $0x354
f0101878:	68 f8 42 10 f0       	push   $0xf01042f8
f010187d:	e8 09 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101882:	6a 02                	push   $0x2
f0101884:	68 00 10 00 00       	push   $0x1000
f0101889:	56                   	push   %esi
f010188a:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101890:	e8 1e f7 ff ff       	call   f0100fb3 <page_insert>
f0101895:	83 c4 10             	add    $0x10,%esp
f0101898:	85 c0                	test   %eax,%eax
f010189a:	74 19                	je     f01018b5 <mem_init+0x89c>
f010189c:	68 3c 3e 10 f0       	push   $0xf0103e3c
f01018a1:	68 1e 43 10 f0       	push   $0xf010431e
f01018a6:	68 57 03 00 00       	push   $0x357
f01018ab:	68 f8 42 10 f0       	push   $0xf01042f8
f01018b0:	e8 d6 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018b5:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018ba:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01018bf:	e8 7a f0 ff ff       	call   f010093e <check_va2pa>
f01018c4:	89 f2                	mov    %esi,%edx
f01018c6:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01018cc:	c1 fa 03             	sar    $0x3,%edx
f01018cf:	c1 e2 0c             	shl    $0xc,%edx
f01018d2:	39 d0                	cmp    %edx,%eax
f01018d4:	74 19                	je     f01018ef <mem_init+0x8d6>
f01018d6:	68 78 3e 10 f0       	push   $0xf0103e78
f01018db:	68 1e 43 10 f0       	push   $0xf010431e
f01018e0:	68 58 03 00 00       	push   $0x358
f01018e5:	68 f8 42 10 f0       	push   $0xf01042f8
f01018ea:	e8 9c e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018ef:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018f4:	74 19                	je     f010190f <mem_init+0x8f6>
f01018f6:	68 01 45 10 f0       	push   $0xf0104501
f01018fb:	68 1e 43 10 f0       	push   $0xf010431e
f0101900:	68 59 03 00 00       	push   $0x359
f0101905:	68 f8 42 10 f0       	push   $0xf01042f8
f010190a:	e8 7c e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010190f:	83 ec 0c             	sub    $0xc,%esp
f0101912:	6a 00                	push   $0x0
f0101914:	e8 1d f4 ff ff       	call   f0100d36 <page_alloc>
f0101919:	83 c4 10             	add    $0x10,%esp
f010191c:	85 c0                	test   %eax,%eax
f010191e:	74 19                	je     f0101939 <mem_init+0x920>
f0101920:	68 8d 44 10 f0       	push   $0xf010448d
f0101925:	68 1e 43 10 f0       	push   $0xf010431e
f010192a:	68 5d 03 00 00       	push   $0x35d
f010192f:	68 f8 42 10 f0       	push   $0xf01042f8
f0101934:	e8 52 e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101939:	8b 15 68 69 11 f0    	mov    0xf0116968,%edx
f010193f:	8b 02                	mov    (%edx),%eax
f0101941:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101946:	89 c1                	mov    %eax,%ecx
f0101948:	c1 e9 0c             	shr    $0xc,%ecx
f010194b:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f0101951:	72 15                	jb     f0101968 <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101953:	50                   	push   %eax
f0101954:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0101959:	68 60 03 00 00       	push   $0x360
f010195e:	68 f8 42 10 f0       	push   $0xf01042f8
f0101963:	e8 23 e7 ff ff       	call   f010008b <_panic>
f0101968:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010196d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101970:	83 ec 04             	sub    $0x4,%esp
f0101973:	6a 00                	push   $0x0
f0101975:	68 00 10 00 00       	push   $0x1000
f010197a:	52                   	push   %edx
f010197b:	e8 88 f4 ff ff       	call   f0100e08 <pgdir_walk>
f0101980:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101983:	8d 51 04             	lea    0x4(%ecx),%edx
f0101986:	83 c4 10             	add    $0x10,%esp
f0101989:	39 d0                	cmp    %edx,%eax
f010198b:	74 19                	je     f01019a6 <mem_init+0x98d>
f010198d:	68 a8 3e 10 f0       	push   $0xf0103ea8
f0101992:	68 1e 43 10 f0       	push   $0xf010431e
f0101997:	68 61 03 00 00       	push   $0x361
f010199c:	68 f8 42 10 f0       	push   $0xf01042f8
f01019a1:	e8 e5 e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019a6:	6a 06                	push   $0x6
f01019a8:	68 00 10 00 00       	push   $0x1000
f01019ad:	56                   	push   %esi
f01019ae:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01019b4:	e8 fa f5 ff ff       	call   f0100fb3 <page_insert>
f01019b9:	83 c4 10             	add    $0x10,%esp
f01019bc:	85 c0                	test   %eax,%eax
f01019be:	74 19                	je     f01019d9 <mem_init+0x9c0>
f01019c0:	68 e8 3e 10 f0       	push   $0xf0103ee8
f01019c5:	68 1e 43 10 f0       	push   $0xf010431e
f01019ca:	68 64 03 00 00       	push   $0x364
f01019cf:	68 f8 42 10 f0       	push   $0xf01042f8
f01019d4:	e8 b2 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019d9:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f01019df:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019e4:	89 f8                	mov    %edi,%eax
f01019e6:	e8 53 ef ff ff       	call   f010093e <check_va2pa>
f01019eb:	89 f2                	mov    %esi,%edx
f01019ed:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01019f3:	c1 fa 03             	sar    $0x3,%edx
f01019f6:	c1 e2 0c             	shl    $0xc,%edx
f01019f9:	39 d0                	cmp    %edx,%eax
f01019fb:	74 19                	je     f0101a16 <mem_init+0x9fd>
f01019fd:	68 78 3e 10 f0       	push   $0xf0103e78
f0101a02:	68 1e 43 10 f0       	push   $0xf010431e
f0101a07:	68 65 03 00 00       	push   $0x365
f0101a0c:	68 f8 42 10 f0       	push   $0xf01042f8
f0101a11:	e8 75 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a16:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a1b:	74 19                	je     f0101a36 <mem_init+0xa1d>
f0101a1d:	68 01 45 10 f0       	push   $0xf0104501
f0101a22:	68 1e 43 10 f0       	push   $0xf010431e
f0101a27:	68 66 03 00 00       	push   $0x366
f0101a2c:	68 f8 42 10 f0       	push   $0xf01042f8
f0101a31:	e8 55 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a36:	83 ec 04             	sub    $0x4,%esp
f0101a39:	6a 00                	push   $0x0
f0101a3b:	68 00 10 00 00       	push   $0x1000
f0101a40:	57                   	push   %edi
f0101a41:	e8 c2 f3 ff ff       	call   f0100e08 <pgdir_walk>
f0101a46:	83 c4 10             	add    $0x10,%esp
f0101a49:	f6 00 04             	testb  $0x4,(%eax)
f0101a4c:	75 19                	jne    f0101a67 <mem_init+0xa4e>
f0101a4e:	68 28 3f 10 f0       	push   $0xf0103f28
f0101a53:	68 1e 43 10 f0       	push   $0xf010431e
f0101a58:	68 67 03 00 00       	push   $0x367
f0101a5d:	68 f8 42 10 f0       	push   $0xf01042f8
f0101a62:	e8 24 e6 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a67:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101a6c:	f6 00 04             	testb  $0x4,(%eax)
f0101a6f:	75 19                	jne    f0101a8a <mem_init+0xa71>
f0101a71:	68 12 45 10 f0       	push   $0xf0104512
f0101a76:	68 1e 43 10 f0       	push   $0xf010431e
f0101a7b:	68 68 03 00 00       	push   $0x368
f0101a80:	68 f8 42 10 f0       	push   $0xf01042f8
f0101a85:	e8 01 e6 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a8a:	6a 02                	push   $0x2
f0101a8c:	68 00 10 00 00       	push   $0x1000
f0101a91:	56                   	push   %esi
f0101a92:	50                   	push   %eax
f0101a93:	e8 1b f5 ff ff       	call   f0100fb3 <page_insert>
f0101a98:	83 c4 10             	add    $0x10,%esp
f0101a9b:	85 c0                	test   %eax,%eax
f0101a9d:	74 19                	je     f0101ab8 <mem_init+0xa9f>
f0101a9f:	68 3c 3e 10 f0       	push   $0xf0103e3c
f0101aa4:	68 1e 43 10 f0       	push   $0xf010431e
f0101aa9:	68 6b 03 00 00       	push   $0x36b
f0101aae:	68 f8 42 10 f0       	push   $0xf01042f8
f0101ab3:	e8 d3 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ab8:	83 ec 04             	sub    $0x4,%esp
f0101abb:	6a 00                	push   $0x0
f0101abd:	68 00 10 00 00       	push   $0x1000
f0101ac2:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ac8:	e8 3b f3 ff ff       	call   f0100e08 <pgdir_walk>
f0101acd:	83 c4 10             	add    $0x10,%esp
f0101ad0:	f6 00 02             	testb  $0x2,(%eax)
f0101ad3:	75 19                	jne    f0101aee <mem_init+0xad5>
f0101ad5:	68 5c 3f 10 f0       	push   $0xf0103f5c
f0101ada:	68 1e 43 10 f0       	push   $0xf010431e
f0101adf:	68 6c 03 00 00       	push   $0x36c
f0101ae4:	68 f8 42 10 f0       	push   $0xf01042f8
f0101ae9:	e8 9d e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101aee:	83 ec 04             	sub    $0x4,%esp
f0101af1:	6a 00                	push   $0x0
f0101af3:	68 00 10 00 00       	push   $0x1000
f0101af8:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101afe:	e8 05 f3 ff ff       	call   f0100e08 <pgdir_walk>
f0101b03:	83 c4 10             	add    $0x10,%esp
f0101b06:	f6 00 04             	testb  $0x4,(%eax)
f0101b09:	74 19                	je     f0101b24 <mem_init+0xb0b>
f0101b0b:	68 90 3f 10 f0       	push   $0xf0103f90
f0101b10:	68 1e 43 10 f0       	push   $0xf010431e
f0101b15:	68 6d 03 00 00       	push   $0x36d
f0101b1a:	68 f8 42 10 f0       	push   $0xf01042f8
f0101b1f:	e8 67 e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b24:	6a 02                	push   $0x2
f0101b26:	68 00 00 40 00       	push   $0x400000
f0101b2b:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b2e:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b34:	e8 7a f4 ff ff       	call   f0100fb3 <page_insert>
f0101b39:	83 c4 10             	add    $0x10,%esp
f0101b3c:	85 c0                	test   %eax,%eax
f0101b3e:	78 19                	js     f0101b59 <mem_init+0xb40>
f0101b40:	68 c8 3f 10 f0       	push   $0xf0103fc8
f0101b45:	68 1e 43 10 f0       	push   $0xf010431e
f0101b4a:	68 70 03 00 00       	push   $0x370
f0101b4f:	68 f8 42 10 f0       	push   $0xf01042f8
f0101b54:	e8 32 e5 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b59:	6a 02                	push   $0x2
f0101b5b:	68 00 10 00 00       	push   $0x1000
f0101b60:	53                   	push   %ebx
f0101b61:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b67:	e8 47 f4 ff ff       	call   f0100fb3 <page_insert>
f0101b6c:	83 c4 10             	add    $0x10,%esp
f0101b6f:	85 c0                	test   %eax,%eax
f0101b71:	74 19                	je     f0101b8c <mem_init+0xb73>
f0101b73:	68 00 40 10 f0       	push   $0xf0104000
f0101b78:	68 1e 43 10 f0       	push   $0xf010431e
f0101b7d:	68 73 03 00 00       	push   $0x373
f0101b82:	68 f8 42 10 f0       	push   $0xf01042f8
f0101b87:	e8 ff e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b8c:	83 ec 04             	sub    $0x4,%esp
f0101b8f:	6a 00                	push   $0x0
f0101b91:	68 00 10 00 00       	push   $0x1000
f0101b96:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b9c:	e8 67 f2 ff ff       	call   f0100e08 <pgdir_walk>
f0101ba1:	83 c4 10             	add    $0x10,%esp
f0101ba4:	f6 00 04             	testb  $0x4,(%eax)
f0101ba7:	74 19                	je     f0101bc2 <mem_init+0xba9>
f0101ba9:	68 90 3f 10 f0       	push   $0xf0103f90
f0101bae:	68 1e 43 10 f0       	push   $0xf010431e
f0101bb3:	68 74 03 00 00       	push   $0x374
f0101bb8:	68 f8 42 10 f0       	push   $0xf01042f8
f0101bbd:	e8 c9 e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101bc2:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101bc8:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bcd:	89 f8                	mov    %edi,%eax
f0101bcf:	e8 6a ed ff ff       	call   f010093e <check_va2pa>
f0101bd4:	89 c1                	mov    %eax,%ecx
f0101bd6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101bd9:	89 d8                	mov    %ebx,%eax
f0101bdb:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101be1:	c1 f8 03             	sar    $0x3,%eax
f0101be4:	c1 e0 0c             	shl    $0xc,%eax
f0101be7:	39 c1                	cmp    %eax,%ecx
f0101be9:	74 19                	je     f0101c04 <mem_init+0xbeb>
f0101beb:	68 3c 40 10 f0       	push   $0xf010403c
f0101bf0:	68 1e 43 10 f0       	push   $0xf010431e
f0101bf5:	68 77 03 00 00       	push   $0x377
f0101bfa:	68 f8 42 10 f0       	push   $0xf01042f8
f0101bff:	e8 87 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c04:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c09:	89 f8                	mov    %edi,%eax
f0101c0b:	e8 2e ed ff ff       	call   f010093e <check_va2pa>
f0101c10:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c13:	74 19                	je     f0101c2e <mem_init+0xc15>
f0101c15:	68 68 40 10 f0       	push   $0xf0104068
f0101c1a:	68 1e 43 10 f0       	push   $0xf010431e
f0101c1f:	68 78 03 00 00       	push   $0x378
f0101c24:	68 f8 42 10 f0       	push   $0xf01042f8
f0101c29:	e8 5d e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c2e:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c33:	74 19                	je     f0101c4e <mem_init+0xc35>
f0101c35:	68 28 45 10 f0       	push   $0xf0104528
f0101c3a:	68 1e 43 10 f0       	push   $0xf010431e
f0101c3f:	68 7a 03 00 00       	push   $0x37a
f0101c44:	68 f8 42 10 f0       	push   $0xf01042f8
f0101c49:	e8 3d e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c4e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c53:	74 19                	je     f0101c6e <mem_init+0xc55>
f0101c55:	68 39 45 10 f0       	push   $0xf0104539
f0101c5a:	68 1e 43 10 f0       	push   $0xf010431e
f0101c5f:	68 7b 03 00 00       	push   $0x37b
f0101c64:	68 f8 42 10 f0       	push   $0xf01042f8
f0101c69:	e8 1d e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c6e:	83 ec 0c             	sub    $0xc,%esp
f0101c71:	6a 00                	push   $0x0
f0101c73:	e8 be f0 ff ff       	call   f0100d36 <page_alloc>
f0101c78:	83 c4 10             	add    $0x10,%esp
f0101c7b:	85 c0                	test   %eax,%eax
f0101c7d:	74 04                	je     f0101c83 <mem_init+0xc6a>
f0101c7f:	39 c6                	cmp    %eax,%esi
f0101c81:	74 19                	je     f0101c9c <mem_init+0xc83>
f0101c83:	68 98 40 10 f0       	push   $0xf0104098
f0101c88:	68 1e 43 10 f0       	push   $0xf010431e
f0101c8d:	68 7e 03 00 00       	push   $0x37e
f0101c92:	68 f8 42 10 f0       	push   $0xf01042f8
f0101c97:	e8 ef e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101c9c:	83 ec 08             	sub    $0x8,%esp
f0101c9f:	6a 00                	push   $0x0
f0101ca1:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ca7:	e8 cc f2 ff ff       	call   f0100f78 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cac:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101cb2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cb7:	89 f8                	mov    %edi,%eax
f0101cb9:	e8 80 ec ff ff       	call   f010093e <check_va2pa>
f0101cbe:	83 c4 10             	add    $0x10,%esp
f0101cc1:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101cc4:	74 19                	je     f0101cdf <mem_init+0xcc6>
f0101cc6:	68 bc 40 10 f0       	push   $0xf01040bc
f0101ccb:	68 1e 43 10 f0       	push   $0xf010431e
f0101cd0:	68 82 03 00 00       	push   $0x382
f0101cd5:	68 f8 42 10 f0       	push   $0xf01042f8
f0101cda:	e8 ac e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cdf:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ce4:	89 f8                	mov    %edi,%eax
f0101ce6:	e8 53 ec ff ff       	call   f010093e <check_va2pa>
f0101ceb:	89 da                	mov    %ebx,%edx
f0101ced:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101cf3:	c1 fa 03             	sar    $0x3,%edx
f0101cf6:	c1 e2 0c             	shl    $0xc,%edx
f0101cf9:	39 d0                	cmp    %edx,%eax
f0101cfb:	74 19                	je     f0101d16 <mem_init+0xcfd>
f0101cfd:	68 68 40 10 f0       	push   $0xf0104068
f0101d02:	68 1e 43 10 f0       	push   $0xf010431e
f0101d07:	68 83 03 00 00       	push   $0x383
f0101d0c:	68 f8 42 10 f0       	push   $0xf01042f8
f0101d11:	e8 75 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d16:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d1b:	74 19                	je     f0101d36 <mem_init+0xd1d>
f0101d1d:	68 df 44 10 f0       	push   $0xf01044df
f0101d22:	68 1e 43 10 f0       	push   $0xf010431e
f0101d27:	68 84 03 00 00       	push   $0x384
f0101d2c:	68 f8 42 10 f0       	push   $0xf01042f8
f0101d31:	e8 55 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d36:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d3b:	74 19                	je     f0101d56 <mem_init+0xd3d>
f0101d3d:	68 39 45 10 f0       	push   $0xf0104539
f0101d42:	68 1e 43 10 f0       	push   $0xf010431e
f0101d47:	68 85 03 00 00       	push   $0x385
f0101d4c:	68 f8 42 10 f0       	push   $0xf01042f8
f0101d51:	e8 35 e3 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d56:	6a 00                	push   $0x0
f0101d58:	68 00 10 00 00       	push   $0x1000
f0101d5d:	53                   	push   %ebx
f0101d5e:	57                   	push   %edi
f0101d5f:	e8 4f f2 ff ff       	call   f0100fb3 <page_insert>
f0101d64:	83 c4 10             	add    $0x10,%esp
f0101d67:	85 c0                	test   %eax,%eax
f0101d69:	74 19                	je     f0101d84 <mem_init+0xd6b>
f0101d6b:	68 e0 40 10 f0       	push   $0xf01040e0
f0101d70:	68 1e 43 10 f0       	push   $0xf010431e
f0101d75:	68 88 03 00 00       	push   $0x388
f0101d7a:	68 f8 42 10 f0       	push   $0xf01042f8
f0101d7f:	e8 07 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101d84:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d89:	75 19                	jne    f0101da4 <mem_init+0xd8b>
f0101d8b:	68 4a 45 10 f0       	push   $0xf010454a
f0101d90:	68 1e 43 10 f0       	push   $0xf010431e
f0101d95:	68 89 03 00 00       	push   $0x389
f0101d9a:	68 f8 42 10 f0       	push   $0xf01042f8
f0101d9f:	e8 e7 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101da4:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101da7:	74 19                	je     f0101dc2 <mem_init+0xda9>
f0101da9:	68 56 45 10 f0       	push   $0xf0104556
f0101dae:	68 1e 43 10 f0       	push   $0xf010431e
f0101db3:	68 8a 03 00 00       	push   $0x38a
f0101db8:	68 f8 42 10 f0       	push   $0xf01042f8
f0101dbd:	e8 c9 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101dc2:	83 ec 08             	sub    $0x8,%esp
f0101dc5:	68 00 10 00 00       	push   $0x1000
f0101dca:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101dd0:	e8 a3 f1 ff ff       	call   f0100f78 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101dd5:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101ddb:	ba 00 00 00 00       	mov    $0x0,%edx
f0101de0:	89 f8                	mov    %edi,%eax
f0101de2:	e8 57 eb ff ff       	call   f010093e <check_va2pa>
f0101de7:	83 c4 10             	add    $0x10,%esp
f0101dea:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ded:	74 19                	je     f0101e08 <mem_init+0xdef>
f0101def:	68 bc 40 10 f0       	push   $0xf01040bc
f0101df4:	68 1e 43 10 f0       	push   $0xf010431e
f0101df9:	68 8e 03 00 00       	push   $0x38e
f0101dfe:	68 f8 42 10 f0       	push   $0xf01042f8
f0101e03:	e8 83 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e08:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e0d:	89 f8                	mov    %edi,%eax
f0101e0f:	e8 2a eb ff ff       	call   f010093e <check_va2pa>
f0101e14:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e17:	74 19                	je     f0101e32 <mem_init+0xe19>
f0101e19:	68 18 41 10 f0       	push   $0xf0104118
f0101e1e:	68 1e 43 10 f0       	push   $0xf010431e
f0101e23:	68 8f 03 00 00       	push   $0x38f
f0101e28:	68 f8 42 10 f0       	push   $0xf01042f8
f0101e2d:	e8 59 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e32:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e37:	74 19                	je     f0101e52 <mem_init+0xe39>
f0101e39:	68 6b 45 10 f0       	push   $0xf010456b
f0101e3e:	68 1e 43 10 f0       	push   $0xf010431e
f0101e43:	68 90 03 00 00       	push   $0x390
f0101e48:	68 f8 42 10 f0       	push   $0xf01042f8
f0101e4d:	e8 39 e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e52:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e57:	74 19                	je     f0101e72 <mem_init+0xe59>
f0101e59:	68 39 45 10 f0       	push   $0xf0104539
f0101e5e:	68 1e 43 10 f0       	push   $0xf010431e
f0101e63:	68 91 03 00 00       	push   $0x391
f0101e68:	68 f8 42 10 f0       	push   $0xf01042f8
f0101e6d:	e8 19 e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e72:	83 ec 0c             	sub    $0xc,%esp
f0101e75:	6a 00                	push   $0x0
f0101e77:	e8 ba ee ff ff       	call   f0100d36 <page_alloc>
f0101e7c:	83 c4 10             	add    $0x10,%esp
f0101e7f:	39 c3                	cmp    %eax,%ebx
f0101e81:	75 04                	jne    f0101e87 <mem_init+0xe6e>
f0101e83:	85 c0                	test   %eax,%eax
f0101e85:	75 19                	jne    f0101ea0 <mem_init+0xe87>
f0101e87:	68 40 41 10 f0       	push   $0xf0104140
f0101e8c:	68 1e 43 10 f0       	push   $0xf010431e
f0101e91:	68 94 03 00 00       	push   $0x394
f0101e96:	68 f8 42 10 f0       	push   $0xf01042f8
f0101e9b:	e8 eb e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ea0:	83 ec 0c             	sub    $0xc,%esp
f0101ea3:	6a 00                	push   $0x0
f0101ea5:	e8 8c ee ff ff       	call   f0100d36 <page_alloc>
f0101eaa:	83 c4 10             	add    $0x10,%esp
f0101ead:	85 c0                	test   %eax,%eax
f0101eaf:	74 19                	je     f0101eca <mem_init+0xeb1>
f0101eb1:	68 8d 44 10 f0       	push   $0xf010448d
f0101eb6:	68 1e 43 10 f0       	push   $0xf010431e
f0101ebb:	68 97 03 00 00       	push   $0x397
f0101ec0:	68 f8 42 10 f0       	push   $0xf01042f8
f0101ec5:	e8 c1 e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101eca:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0101ed0:	8b 11                	mov    (%ecx),%edx
f0101ed2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ed8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101edb:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101ee1:	c1 f8 03             	sar    $0x3,%eax
f0101ee4:	c1 e0 0c             	shl    $0xc,%eax
f0101ee7:	39 c2                	cmp    %eax,%edx
f0101ee9:	74 19                	je     f0101f04 <mem_init+0xeeb>
f0101eeb:	68 e4 3d 10 f0       	push   $0xf0103de4
f0101ef0:	68 1e 43 10 f0       	push   $0xf010431e
f0101ef5:	68 9a 03 00 00       	push   $0x39a
f0101efa:	68 f8 42 10 f0       	push   $0xf01042f8
f0101eff:	e8 87 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101f04:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f0a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f0d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f12:	74 19                	je     f0101f2d <mem_init+0xf14>
f0101f14:	68 f0 44 10 f0       	push   $0xf01044f0
f0101f19:	68 1e 43 10 f0       	push   $0xf010431e
f0101f1e:	68 9c 03 00 00       	push   $0x39c
f0101f23:	68 f8 42 10 f0       	push   $0xf01042f8
f0101f28:	e8 5e e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f2d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f30:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f36:	83 ec 0c             	sub    $0xc,%esp
f0101f39:	50                   	push   %eax
f0101f3a:	e8 7d ee ff ff       	call   f0100dbc <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f3f:	83 c4 0c             	add    $0xc,%esp
f0101f42:	6a 01                	push   $0x1
f0101f44:	68 00 10 40 00       	push   $0x401000
f0101f49:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101f4f:	e8 b4 ee ff ff       	call   f0100e08 <pgdir_walk>
f0101f54:	89 c7                	mov    %eax,%edi
f0101f56:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f59:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101f5e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f61:	8b 40 04             	mov    0x4(%eax),%eax
f0101f64:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f69:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0101f6f:	89 c2                	mov    %eax,%edx
f0101f71:	c1 ea 0c             	shr    $0xc,%edx
f0101f74:	83 c4 10             	add    $0x10,%esp
f0101f77:	39 ca                	cmp    %ecx,%edx
f0101f79:	72 15                	jb     f0101f90 <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f7b:	50                   	push   %eax
f0101f7c:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0101f81:	68 a3 03 00 00       	push   $0x3a3
f0101f86:	68 f8 42 10 f0       	push   $0xf01042f8
f0101f8b:	e8 fb e0 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f90:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f95:	39 c7                	cmp    %eax,%edi
f0101f97:	74 19                	je     f0101fb2 <mem_init+0xf99>
f0101f99:	68 7c 45 10 f0       	push   $0xf010457c
f0101f9e:	68 1e 43 10 f0       	push   $0xf010431e
f0101fa3:	68 a4 03 00 00       	push   $0x3a4
f0101fa8:	68 f8 42 10 f0       	push   $0xf01042f8
f0101fad:	e8 d9 e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101fb2:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fb5:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101fbc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fbf:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fc5:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101fcb:	c1 f8 03             	sar    $0x3,%eax
f0101fce:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fd1:	89 c2                	mov    %eax,%edx
f0101fd3:	c1 ea 0c             	shr    $0xc,%edx
f0101fd6:	39 d1                	cmp    %edx,%ecx
f0101fd8:	77 12                	ja     f0101fec <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fda:	50                   	push   %eax
f0101fdb:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0101fe0:	6a 52                	push   $0x52
f0101fe2:	68 04 43 10 f0       	push   $0xf0104304
f0101fe7:	e8 9f e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101fec:	83 ec 04             	sub    $0x4,%esp
f0101fef:	68 00 10 00 00       	push   $0x1000
f0101ff4:	68 ff 00 00 00       	push   $0xff
f0101ff9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ffe:	50                   	push   %eax
f0101fff:	e8 c2 11 00 00       	call   f01031c6 <memset>
	page_free(pp0);
f0102004:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102007:	89 3c 24             	mov    %edi,(%esp)
f010200a:	e8 ad ed ff ff       	call   f0100dbc <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010200f:	83 c4 0c             	add    $0xc,%esp
f0102012:	6a 01                	push   $0x1
f0102014:	6a 00                	push   $0x0
f0102016:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010201c:	e8 e7 ed ff ff       	call   f0100e08 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102021:	89 fa                	mov    %edi,%edx
f0102023:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0102029:	c1 fa 03             	sar    $0x3,%edx
f010202c:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010202f:	89 d0                	mov    %edx,%eax
f0102031:	c1 e8 0c             	shr    $0xc,%eax
f0102034:	83 c4 10             	add    $0x10,%esp
f0102037:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f010203d:	72 12                	jb     f0102051 <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010203f:	52                   	push   %edx
f0102040:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0102045:	6a 52                	push   $0x52
f0102047:	68 04 43 10 f0       	push   $0xf0104304
f010204c:	e8 3a e0 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0102051:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102057:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010205a:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102060:	f6 00 01             	testb  $0x1,(%eax)
f0102063:	74 19                	je     f010207e <mem_init+0x1065>
f0102065:	68 94 45 10 f0       	push   $0xf0104594
f010206a:	68 1e 43 10 f0       	push   $0xf010431e
f010206f:	68 ae 03 00 00       	push   $0x3ae
f0102074:	68 f8 42 10 f0       	push   $0xf01042f8
f0102079:	e8 0d e0 ff ff       	call   f010008b <_panic>
f010207e:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102081:	39 d0                	cmp    %edx,%eax
f0102083:	75 db                	jne    f0102060 <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102085:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010208a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102090:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102093:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102099:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010209c:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f01020a2:	83 ec 0c             	sub    $0xc,%esp
f01020a5:	50                   	push   %eax
f01020a6:	e8 11 ed ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f01020ab:	89 1c 24             	mov    %ebx,(%esp)
f01020ae:	e8 09 ed ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f01020b3:	89 34 24             	mov    %esi,(%esp)
f01020b6:	e8 01 ed ff ff       	call   f0100dbc <page_free>

	cprintf("check_page() succeeded!\n");
f01020bb:	c7 04 24 ab 45 10 f0 	movl   $0xf01045ab,(%esp)
f01020c2:	e8 4b 06 00 00       	call   f0102712 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U | PTE_P);
f01020c7:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020cc:	83 c4 10             	add    $0x10,%esp
f01020cf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020d4:	77 15                	ja     f01020eb <mem_init+0x10d2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020d6:	50                   	push   %eax
f01020d7:	68 e8 3c 10 f0       	push   $0xf0103ce8
f01020dc:	68 af 00 00 00       	push   $0xaf
f01020e1:	68 f8 42 10 f0       	push   $0xf01042f8
f01020e6:	e8 a0 df ff ff       	call   f010008b <_panic>
f01020eb:	83 ec 08             	sub    $0x8,%esp
f01020ee:	6a 05                	push   $0x5
f01020f0:	05 00 00 00 10       	add    $0x10000000,%eax
f01020f5:	50                   	push   %eax
f01020f6:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020fb:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102100:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102105:	e8 c2 ed ff ff       	call   f0100ecc <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010210a:	83 c4 10             	add    $0x10,%esp
f010210d:	b8 00 c0 10 f0       	mov    $0xf010c000,%eax
f0102112:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102117:	77 15                	ja     f010212e <mem_init+0x1115>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102119:	50                   	push   %eax
f010211a:	68 e8 3c 10 f0       	push   $0xf0103ce8
f010211f:	68 bb 00 00 00       	push   $0xbb
f0102124:	68 f8 42 10 f0       	push   $0xf01042f8
f0102129:	e8 5d df ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f010212e:	83 ec 08             	sub    $0x8,%esp
f0102131:	6a 02                	push   $0x2
f0102133:	68 00 c0 10 00       	push   $0x10c000
f0102138:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010213d:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102142:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102147:	e8 80 ed ff ff       	call   f0100ecc <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff-KERNBASE, 0, PTE_W);
f010214c:	83 c4 08             	add    $0x8,%esp
f010214f:	6a 02                	push   $0x2
f0102151:	6a 00                	push   $0x0
f0102153:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102158:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010215d:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102162:	e8 65 ed ff ff       	call   f0100ecc <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102167:	8b 35 68 69 11 f0    	mov    0xf0116968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010216d:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0102172:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102175:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010217c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102181:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102184:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010218a:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010218d:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102190:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102195:	eb 55                	jmp    f01021ec <mem_init+0x11d3>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102197:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f010219d:	89 f0                	mov    %esi,%eax
f010219f:	e8 9a e7 ff ff       	call   f010093e <check_va2pa>
f01021a4:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01021ab:	77 15                	ja     f01021c2 <mem_init+0x11a9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021ad:	57                   	push   %edi
f01021ae:	68 e8 3c 10 f0       	push   $0xf0103ce8
f01021b3:	68 f0 02 00 00       	push   $0x2f0
f01021b8:	68 f8 42 10 f0       	push   $0xf01042f8
f01021bd:	e8 c9 de ff ff       	call   f010008b <_panic>
f01021c2:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01021c9:	39 c2                	cmp    %eax,%edx
f01021cb:	74 19                	je     f01021e6 <mem_init+0x11cd>
f01021cd:	68 64 41 10 f0       	push   $0xf0104164
f01021d2:	68 1e 43 10 f0       	push   $0xf010431e
f01021d7:	68 f0 02 00 00       	push   $0x2f0
f01021dc:	68 f8 42 10 f0       	push   $0xf01042f8
f01021e1:	e8 a5 de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021e6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01021ec:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01021ef:	77 a6                	ja     f0102197 <mem_init+0x117e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01021f1:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01021f4:	c1 e7 0c             	shl    $0xc,%edi
f01021f7:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021fc:	eb 30                	jmp    f010222e <mem_init+0x1215>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01021fe:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102204:	89 f0                	mov    %esi,%eax
f0102206:	e8 33 e7 ff ff       	call   f010093e <check_va2pa>
f010220b:	39 c3                	cmp    %eax,%ebx
f010220d:	74 19                	je     f0102228 <mem_init+0x120f>
f010220f:	68 98 41 10 f0       	push   $0xf0104198
f0102214:	68 1e 43 10 f0       	push   $0xf010431e
f0102219:	68 f5 02 00 00       	push   $0x2f5
f010221e:	68 f8 42 10 f0       	push   $0xf01042f8
f0102223:	e8 63 de ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102228:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010222e:	39 fb                	cmp    %edi,%ebx
f0102230:	72 cc                	jb     f01021fe <mem_init+0x11e5>
f0102232:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102237:	89 da                	mov    %ebx,%edx
f0102239:	89 f0                	mov    %esi,%eax
f010223b:	e8 fe e6 ff ff       	call   f010093e <check_va2pa>
f0102240:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f0102246:	39 c2                	cmp    %eax,%edx
f0102248:	74 19                	je     f0102263 <mem_init+0x124a>
f010224a:	68 c0 41 10 f0       	push   $0xf01041c0
f010224f:	68 1e 43 10 f0       	push   $0xf010431e
f0102254:	68 f9 02 00 00       	push   $0x2f9
f0102259:	68 f8 42 10 f0       	push   $0xf01042f8
f010225e:	e8 28 de ff ff       	call   f010008b <_panic>
f0102263:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102269:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f010226f:	75 c6                	jne    f0102237 <mem_init+0x121e>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102271:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102276:	89 f0                	mov    %esi,%eax
f0102278:	e8 c1 e6 ff ff       	call   f010093e <check_va2pa>
f010227d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102280:	74 51                	je     f01022d3 <mem_init+0x12ba>
f0102282:	68 08 42 10 f0       	push   $0xf0104208
f0102287:	68 1e 43 10 f0       	push   $0xf010431e
f010228c:	68 fa 02 00 00       	push   $0x2fa
f0102291:	68 f8 42 10 f0       	push   $0xf01042f8
f0102296:	e8 f0 dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010229b:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01022a0:	72 36                	jb     f01022d8 <mem_init+0x12bf>
f01022a2:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01022a7:	76 07                	jbe    f01022b0 <mem_init+0x1297>
f01022a9:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022ae:	75 28                	jne    f01022d8 <mem_init+0x12bf>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01022b0:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01022b4:	0f 85 83 00 00 00    	jne    f010233d <mem_init+0x1324>
f01022ba:	68 c4 45 10 f0       	push   $0xf01045c4
f01022bf:	68 1e 43 10 f0       	push   $0xf010431e
f01022c4:	68 02 03 00 00       	push   $0x302
f01022c9:	68 f8 42 10 f0       	push   $0xf01042f8
f01022ce:	e8 b8 dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022d3:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01022d8:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022dd:	76 3f                	jbe    f010231e <mem_init+0x1305>
				assert(pgdir[i] & PTE_P);
f01022df:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01022e2:	f6 c2 01             	test   $0x1,%dl
f01022e5:	75 19                	jne    f0102300 <mem_init+0x12e7>
f01022e7:	68 c4 45 10 f0       	push   $0xf01045c4
f01022ec:	68 1e 43 10 f0       	push   $0xf010431e
f01022f1:	68 06 03 00 00       	push   $0x306
f01022f6:	68 f8 42 10 f0       	push   $0xf01042f8
f01022fb:	e8 8b dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102300:	f6 c2 02             	test   $0x2,%dl
f0102303:	75 38                	jne    f010233d <mem_init+0x1324>
f0102305:	68 d5 45 10 f0       	push   $0xf01045d5
f010230a:	68 1e 43 10 f0       	push   $0xf010431e
f010230f:	68 07 03 00 00       	push   $0x307
f0102314:	68 f8 42 10 f0       	push   $0xf01042f8
f0102319:	e8 6d dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f010231e:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102322:	74 19                	je     f010233d <mem_init+0x1324>
f0102324:	68 e6 45 10 f0       	push   $0xf01045e6
f0102329:	68 1e 43 10 f0       	push   $0xf010431e
f010232e:	68 09 03 00 00       	push   $0x309
f0102333:	68 f8 42 10 f0       	push   $0xf01042f8
f0102338:	e8 4e dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010233d:	83 c0 01             	add    $0x1,%eax
f0102340:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102345:	0f 86 50 ff ff ff    	jbe    f010229b <mem_init+0x1282>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010234b:	83 ec 0c             	sub    $0xc,%esp
f010234e:	68 38 42 10 f0       	push   $0xf0104238
f0102353:	e8 ba 03 00 00       	call   f0102712 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102358:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010235d:	83 c4 10             	add    $0x10,%esp
f0102360:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102365:	77 15                	ja     f010237c <mem_init+0x1363>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102367:	50                   	push   %eax
f0102368:	68 e8 3c 10 f0       	push   $0xf0103ce8
f010236d:	68 cf 00 00 00       	push   $0xcf
f0102372:	68 f8 42 10 f0       	push   $0xf01042f8
f0102377:	e8 0f dd ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010237c:	05 00 00 00 10       	add    $0x10000000,%eax
f0102381:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102384:	b8 00 00 00 00       	mov    $0x0,%eax
f0102389:	e8 14 e6 ff ff       	call   f01009a2 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f010238e:	0f 20 c0             	mov    %cr0,%eax
f0102391:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102394:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102399:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010239c:	83 ec 0c             	sub    $0xc,%esp
f010239f:	6a 00                	push   $0x0
f01023a1:	e8 90 e9 ff ff       	call   f0100d36 <page_alloc>
f01023a6:	89 c3                	mov    %eax,%ebx
f01023a8:	83 c4 10             	add    $0x10,%esp
f01023ab:	85 c0                	test   %eax,%eax
f01023ad:	75 19                	jne    f01023c8 <mem_init+0x13af>
f01023af:	68 e2 43 10 f0       	push   $0xf01043e2
f01023b4:	68 1e 43 10 f0       	push   $0xf010431e
f01023b9:	68 c9 03 00 00       	push   $0x3c9
f01023be:	68 f8 42 10 f0       	push   $0xf01042f8
f01023c3:	e8 c3 dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01023c8:	83 ec 0c             	sub    $0xc,%esp
f01023cb:	6a 00                	push   $0x0
f01023cd:	e8 64 e9 ff ff       	call   f0100d36 <page_alloc>
f01023d2:	89 c7                	mov    %eax,%edi
f01023d4:	83 c4 10             	add    $0x10,%esp
f01023d7:	85 c0                	test   %eax,%eax
f01023d9:	75 19                	jne    f01023f4 <mem_init+0x13db>
f01023db:	68 f8 43 10 f0       	push   $0xf01043f8
f01023e0:	68 1e 43 10 f0       	push   $0xf010431e
f01023e5:	68 ca 03 00 00       	push   $0x3ca
f01023ea:	68 f8 42 10 f0       	push   $0xf01042f8
f01023ef:	e8 97 dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01023f4:	83 ec 0c             	sub    $0xc,%esp
f01023f7:	6a 00                	push   $0x0
f01023f9:	e8 38 e9 ff ff       	call   f0100d36 <page_alloc>
f01023fe:	89 c6                	mov    %eax,%esi
f0102400:	83 c4 10             	add    $0x10,%esp
f0102403:	85 c0                	test   %eax,%eax
f0102405:	75 19                	jne    f0102420 <mem_init+0x1407>
f0102407:	68 0e 44 10 f0       	push   $0xf010440e
f010240c:	68 1e 43 10 f0       	push   $0xf010431e
f0102411:	68 cb 03 00 00       	push   $0x3cb
f0102416:	68 f8 42 10 f0       	push   $0xf01042f8
f010241b:	e8 6b dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102420:	83 ec 0c             	sub    $0xc,%esp
f0102423:	53                   	push   %ebx
f0102424:	e8 93 e9 ff ff       	call   f0100dbc <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102429:	89 f8                	mov    %edi,%eax
f010242b:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102431:	c1 f8 03             	sar    $0x3,%eax
f0102434:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102437:	89 c2                	mov    %eax,%edx
f0102439:	c1 ea 0c             	shr    $0xc,%edx
f010243c:	83 c4 10             	add    $0x10,%esp
f010243f:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102445:	72 12                	jb     f0102459 <mem_init+0x1440>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102447:	50                   	push   %eax
f0102448:	68 a4 3b 10 f0       	push   $0xf0103ba4
f010244d:	6a 52                	push   $0x52
f010244f:	68 04 43 10 f0       	push   $0xf0104304
f0102454:	e8 32 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102459:	83 ec 04             	sub    $0x4,%esp
f010245c:	68 00 10 00 00       	push   $0x1000
f0102461:	6a 01                	push   $0x1
f0102463:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102468:	50                   	push   %eax
f0102469:	e8 58 0d 00 00       	call   f01031c6 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010246e:	89 f0                	mov    %esi,%eax
f0102470:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102476:	c1 f8 03             	sar    $0x3,%eax
f0102479:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010247c:	89 c2                	mov    %eax,%edx
f010247e:	c1 ea 0c             	shr    $0xc,%edx
f0102481:	83 c4 10             	add    $0x10,%esp
f0102484:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f010248a:	72 12                	jb     f010249e <mem_init+0x1485>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010248c:	50                   	push   %eax
f010248d:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0102492:	6a 52                	push   $0x52
f0102494:	68 04 43 10 f0       	push   $0xf0104304
f0102499:	e8 ed db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f010249e:	83 ec 04             	sub    $0x4,%esp
f01024a1:	68 00 10 00 00       	push   $0x1000
f01024a6:	6a 02                	push   $0x2
f01024a8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024ad:	50                   	push   %eax
f01024ae:	e8 13 0d 00 00       	call   f01031c6 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01024b3:	6a 02                	push   $0x2
f01024b5:	68 00 10 00 00       	push   $0x1000
f01024ba:	57                   	push   %edi
f01024bb:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01024c1:	e8 ed ea ff ff       	call   f0100fb3 <page_insert>
	assert(pp1->pp_ref == 1);
f01024c6:	83 c4 20             	add    $0x20,%esp
f01024c9:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01024ce:	74 19                	je     f01024e9 <mem_init+0x14d0>
f01024d0:	68 df 44 10 f0       	push   $0xf01044df
f01024d5:	68 1e 43 10 f0       	push   $0xf010431e
f01024da:	68 d0 03 00 00       	push   $0x3d0
f01024df:	68 f8 42 10 f0       	push   $0xf01042f8
f01024e4:	e8 a2 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01024e9:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01024f0:	01 01 01 
f01024f3:	74 19                	je     f010250e <mem_init+0x14f5>
f01024f5:	68 58 42 10 f0       	push   $0xf0104258
f01024fa:	68 1e 43 10 f0       	push   $0xf010431e
f01024ff:	68 d1 03 00 00       	push   $0x3d1
f0102504:	68 f8 42 10 f0       	push   $0xf01042f8
f0102509:	e8 7d db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010250e:	6a 02                	push   $0x2
f0102510:	68 00 10 00 00       	push   $0x1000
f0102515:	56                   	push   %esi
f0102516:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010251c:	e8 92 ea ff ff       	call   f0100fb3 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102521:	83 c4 10             	add    $0x10,%esp
f0102524:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010252b:	02 02 02 
f010252e:	74 19                	je     f0102549 <mem_init+0x1530>
f0102530:	68 7c 42 10 f0       	push   $0xf010427c
f0102535:	68 1e 43 10 f0       	push   $0xf010431e
f010253a:	68 d3 03 00 00       	push   $0x3d3
f010253f:	68 f8 42 10 f0       	push   $0xf01042f8
f0102544:	e8 42 db ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0102549:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010254e:	74 19                	je     f0102569 <mem_init+0x1550>
f0102550:	68 01 45 10 f0       	push   $0xf0104501
f0102555:	68 1e 43 10 f0       	push   $0xf010431e
f010255a:	68 d4 03 00 00       	push   $0x3d4
f010255f:	68 f8 42 10 f0       	push   $0xf01042f8
f0102564:	e8 22 db ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0102569:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010256e:	74 19                	je     f0102589 <mem_init+0x1570>
f0102570:	68 6b 45 10 f0       	push   $0xf010456b
f0102575:	68 1e 43 10 f0       	push   $0xf010431e
f010257a:	68 d5 03 00 00       	push   $0x3d5
f010257f:	68 f8 42 10 f0       	push   $0xf01042f8
f0102584:	e8 02 db ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102589:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102590:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102593:	89 f0                	mov    %esi,%eax
f0102595:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010259b:	c1 f8 03             	sar    $0x3,%eax
f010259e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025a1:	89 c2                	mov    %eax,%edx
f01025a3:	c1 ea 0c             	shr    $0xc,%edx
f01025a6:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01025ac:	72 12                	jb     f01025c0 <mem_init+0x15a7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025ae:	50                   	push   %eax
f01025af:	68 a4 3b 10 f0       	push   $0xf0103ba4
f01025b4:	6a 52                	push   $0x52
f01025b6:	68 04 43 10 f0       	push   $0xf0104304
f01025bb:	e8 cb da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01025c0:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01025c7:	03 03 03 
f01025ca:	74 19                	je     f01025e5 <mem_init+0x15cc>
f01025cc:	68 a0 42 10 f0       	push   $0xf01042a0
f01025d1:	68 1e 43 10 f0       	push   $0xf010431e
f01025d6:	68 d7 03 00 00       	push   $0x3d7
f01025db:	68 f8 42 10 f0       	push   $0xf01042f8
f01025e0:	e8 a6 da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025e5:	83 ec 08             	sub    $0x8,%esp
f01025e8:	68 00 10 00 00       	push   $0x1000
f01025ed:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01025f3:	e8 80 e9 ff ff       	call   f0100f78 <page_remove>
	assert(pp2->pp_ref == 0);
f01025f8:	83 c4 10             	add    $0x10,%esp
f01025fb:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102600:	74 19                	je     f010261b <mem_init+0x1602>
f0102602:	68 39 45 10 f0       	push   $0xf0104539
f0102607:	68 1e 43 10 f0       	push   $0xf010431e
f010260c:	68 d9 03 00 00       	push   $0x3d9
f0102611:	68 f8 42 10 f0       	push   $0xf01042f8
f0102616:	e8 70 da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010261b:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0102621:	8b 11                	mov    (%ecx),%edx
f0102623:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102629:	89 d8                	mov    %ebx,%eax
f010262b:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102631:	c1 f8 03             	sar    $0x3,%eax
f0102634:	c1 e0 0c             	shl    $0xc,%eax
f0102637:	39 c2                	cmp    %eax,%edx
f0102639:	74 19                	je     f0102654 <mem_init+0x163b>
f010263b:	68 e4 3d 10 f0       	push   $0xf0103de4
f0102640:	68 1e 43 10 f0       	push   $0xf010431e
f0102645:	68 dc 03 00 00       	push   $0x3dc
f010264a:	68 f8 42 10 f0       	push   $0xf01042f8
f010264f:	e8 37 da ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0102654:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010265a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010265f:	74 19                	je     f010267a <mem_init+0x1661>
f0102661:	68 f0 44 10 f0       	push   $0xf01044f0
f0102666:	68 1e 43 10 f0       	push   $0xf010431e
f010266b:	68 de 03 00 00       	push   $0x3de
f0102670:	68 f8 42 10 f0       	push   $0xf01042f8
f0102675:	e8 11 da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f010267a:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102680:	83 ec 0c             	sub    $0xc,%esp
f0102683:	53                   	push   %ebx
f0102684:	e8 33 e7 ff ff       	call   f0100dbc <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102689:	c7 04 24 cc 42 10 f0 	movl   $0xf01042cc,(%esp)
f0102690:	e8 7d 00 00 00       	call   f0102712 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102695:	83 c4 10             	add    $0x10,%esp
f0102698:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010269b:	5b                   	pop    %ebx
f010269c:	5e                   	pop    %esi
f010269d:	5f                   	pop    %edi
f010269e:	5d                   	pop    %ebp
f010269f:	c3                   	ret    

f01026a0 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01026a0:	55                   	push   %ebp
f01026a1:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01026a3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026a6:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01026a9:	5d                   	pop    %ebp
f01026aa:	c3                   	ret    

f01026ab <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01026ab:	55                   	push   %ebp
f01026ac:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01026ae:	ba 70 00 00 00       	mov    $0x70,%edx
f01026b3:	8b 45 08             	mov    0x8(%ebp),%eax
f01026b6:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01026b7:	ba 71 00 00 00       	mov    $0x71,%edx
f01026bc:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01026bd:	0f b6 c0             	movzbl %al,%eax
}
f01026c0:	5d                   	pop    %ebp
f01026c1:	c3                   	ret    

f01026c2 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01026c2:	55                   	push   %ebp
f01026c3:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01026c5:	ba 70 00 00 00       	mov    $0x70,%edx
f01026ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01026cd:	ee                   	out    %al,(%dx)
f01026ce:	ba 71 00 00 00       	mov    $0x71,%edx
f01026d3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026d6:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01026d7:	5d                   	pop    %ebp
f01026d8:	c3                   	ret    

f01026d9 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01026d9:	55                   	push   %ebp
f01026da:	89 e5                	mov    %esp,%ebp
f01026dc:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01026df:	ff 75 08             	pushl  0x8(%ebp)
f01026e2:	e8 3e df ff ff       	call   f0100625 <cputchar>
	*cnt++;
}
f01026e7:	83 c4 10             	add    $0x10,%esp
f01026ea:	c9                   	leave  
f01026eb:	c3                   	ret    

f01026ec <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01026ec:	55                   	push   %ebp
f01026ed:	89 e5                	mov    %esp,%ebp
f01026ef:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01026f2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01026f9:	ff 75 0c             	pushl  0xc(%ebp)
f01026fc:	ff 75 08             	pushl  0x8(%ebp)
f01026ff:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102702:	50                   	push   %eax
f0102703:	68 d9 26 10 f0       	push   $0xf01026d9
f0102708:	e8 4d 04 00 00       	call   f0102b5a <vprintfmt>
	return cnt;
}
f010270d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102710:	c9                   	leave  
f0102711:	c3                   	ret    

f0102712 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102712:	55                   	push   %ebp
f0102713:	89 e5                	mov    %esp,%ebp
f0102715:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102718:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010271b:	50                   	push   %eax
f010271c:	ff 75 08             	pushl  0x8(%ebp)
f010271f:	e8 c8 ff ff ff       	call   f01026ec <vcprintf>
	va_end(ap);

	return cnt;
}
f0102724:	c9                   	leave  
f0102725:	c3                   	ret    

f0102726 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102726:	55                   	push   %ebp
f0102727:	89 e5                	mov    %esp,%ebp
f0102729:	57                   	push   %edi
f010272a:	56                   	push   %esi
f010272b:	53                   	push   %ebx
f010272c:	83 ec 14             	sub    $0x14,%esp
f010272f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102732:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102735:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102738:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010273b:	8b 1a                	mov    (%edx),%ebx
f010273d:	8b 01                	mov    (%ecx),%eax
f010273f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102742:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102749:	eb 7f                	jmp    f01027ca <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010274b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010274e:	01 d8                	add    %ebx,%eax
f0102750:	89 c6                	mov    %eax,%esi
f0102752:	c1 ee 1f             	shr    $0x1f,%esi
f0102755:	01 c6                	add    %eax,%esi
f0102757:	d1 fe                	sar    %esi
f0102759:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010275c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010275f:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0102762:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102764:	eb 03                	jmp    f0102769 <stab_binsearch+0x43>
			m--;
f0102766:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102769:	39 c3                	cmp    %eax,%ebx
f010276b:	7f 0d                	jg     f010277a <stab_binsearch+0x54>
f010276d:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102771:	83 ea 0c             	sub    $0xc,%edx
f0102774:	39 f9                	cmp    %edi,%ecx
f0102776:	75 ee                	jne    f0102766 <stab_binsearch+0x40>
f0102778:	eb 05                	jmp    f010277f <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010277a:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010277d:	eb 4b                	jmp    f01027ca <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010277f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102782:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102785:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102789:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010278c:	76 11                	jbe    f010279f <stab_binsearch+0x79>
			*region_left = m;
f010278e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102791:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102793:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102796:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010279d:	eb 2b                	jmp    f01027ca <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010279f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01027a2:	73 14                	jae    f01027b8 <stab_binsearch+0x92>
			*region_right = m - 1;
f01027a4:	83 e8 01             	sub    $0x1,%eax
f01027a7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01027aa:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027ad:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027af:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01027b6:	eb 12                	jmp    f01027ca <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01027b8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027bb:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01027bd:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01027c1:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027c3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01027ca:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01027cd:	0f 8e 78 ff ff ff    	jle    f010274b <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01027d3:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01027d7:	75 0f                	jne    f01027e8 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01027d9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027dc:	8b 00                	mov    (%eax),%eax
f01027de:	83 e8 01             	sub    $0x1,%eax
f01027e1:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027e4:	89 06                	mov    %eax,(%esi)
f01027e6:	eb 2c                	jmp    f0102814 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027e8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027eb:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01027ed:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027f0:	8b 0e                	mov    (%esi),%ecx
f01027f2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027f5:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01027f8:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027fb:	eb 03                	jmp    f0102800 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01027fd:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102800:	39 c8                	cmp    %ecx,%eax
f0102802:	7e 0b                	jle    f010280f <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102804:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102808:	83 ea 0c             	sub    $0xc,%edx
f010280b:	39 df                	cmp    %ebx,%edi
f010280d:	75 ee                	jne    f01027fd <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010280f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102812:	89 06                	mov    %eax,(%esi)
	}
}
f0102814:	83 c4 14             	add    $0x14,%esp
f0102817:	5b                   	pop    %ebx
f0102818:	5e                   	pop    %esi
f0102819:	5f                   	pop    %edi
f010281a:	5d                   	pop    %ebp
f010281b:	c3                   	ret    

f010281c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010281c:	55                   	push   %ebp
f010281d:	89 e5                	mov    %esp,%ebp
f010281f:	57                   	push   %edi
f0102820:	56                   	push   %esi
f0102821:	53                   	push   %ebx
f0102822:	83 ec 2c             	sub    $0x2c,%esp
f0102825:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102828:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010282b:	c7 06 f4 45 10 f0    	movl   $0xf01045f4,(%esi)
	info->eip_line = 0;
f0102831:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0102838:	c7 46 08 f4 45 10 f0 	movl   $0xf01045f4,0x8(%esi)
	info->eip_fn_namelen = 9;
f010283f:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0102846:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0102849:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102850:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0102856:	76 11                	jbe    f0102869 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102858:	b8 5d be 10 f0       	mov    $0xf010be5d,%eax
f010285d:	3d b9 a0 10 f0       	cmp    $0xf010a0b9,%eax
f0102862:	77 19                	ja     f010287d <debuginfo_eip+0x61>
f0102864:	e9 a5 01 00 00       	jmp    f0102a0e <debuginfo_eip+0x1f2>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102869:	83 ec 04             	sub    $0x4,%esp
f010286c:	68 fe 45 10 f0       	push   $0xf01045fe
f0102871:	6a 7f                	push   $0x7f
f0102873:	68 0b 46 10 f0       	push   $0xf010460b
f0102878:	e8 0e d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010287d:	80 3d 5c be 10 f0 00 	cmpb   $0x0,0xf010be5c
f0102884:	0f 85 8b 01 00 00    	jne    f0102a15 <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010288a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102891:	b8 b8 a0 10 f0       	mov    $0xf010a0b8,%eax
f0102896:	2d 50 48 10 f0       	sub    $0xf0104850,%eax
f010289b:	c1 f8 02             	sar    $0x2,%eax
f010289e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01028a4:	83 e8 01             	sub    $0x1,%eax
f01028a7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01028aa:	83 ec 08             	sub    $0x8,%esp
f01028ad:	57                   	push   %edi
f01028ae:	6a 64                	push   $0x64
f01028b0:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01028b3:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01028b6:	b8 50 48 10 f0       	mov    $0xf0104850,%eax
f01028bb:	e8 66 fe ff ff       	call   f0102726 <stab_binsearch>
	if (lfile == 0)
f01028c0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01028c3:	83 c4 10             	add    $0x10,%esp
f01028c6:	85 c0                	test   %eax,%eax
f01028c8:	0f 84 4e 01 00 00    	je     f0102a1c <debuginfo_eip+0x200>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01028ce:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01028d1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01028d4:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01028d7:	83 ec 08             	sub    $0x8,%esp
f01028da:	57                   	push   %edi
f01028db:	6a 24                	push   $0x24
f01028dd:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01028e0:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01028e3:	b8 50 48 10 f0       	mov    $0xf0104850,%eax
f01028e8:	e8 39 fe ff ff       	call   f0102726 <stab_binsearch>

	if (lfun <= rfun) {
f01028ed:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01028f0:	83 c4 10             	add    $0x10,%esp
f01028f3:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f01028f6:	7f 33                	jg     f010292b <debuginfo_eip+0x10f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01028f8:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01028fb:	c1 e0 02             	shl    $0x2,%eax
f01028fe:	8d 90 50 48 10 f0    	lea    -0xfefb7b0(%eax),%edx
f0102904:	8b 88 50 48 10 f0    	mov    -0xfefb7b0(%eax),%ecx
f010290a:	b8 5d be 10 f0       	mov    $0xf010be5d,%eax
f010290f:	2d b9 a0 10 f0       	sub    $0xf010a0b9,%eax
f0102914:	39 c1                	cmp    %eax,%ecx
f0102916:	73 09                	jae    f0102921 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102918:	81 c1 b9 a0 10 f0    	add    $0xf010a0b9,%ecx
f010291e:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102921:	8b 42 08             	mov    0x8(%edx),%eax
f0102924:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f0102927:	29 c7                	sub    %eax,%edi
f0102929:	eb 06                	jmp    f0102931 <debuginfo_eip+0x115>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010292b:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f010292e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102931:	83 ec 08             	sub    $0x8,%esp
f0102934:	6a 3a                	push   $0x3a
f0102936:	ff 76 08             	pushl  0x8(%esi)
f0102939:	e8 6c 08 00 00       	call   f01031aa <strfind>
f010293e:	2b 46 08             	sub    0x8(%esi),%eax
f0102941:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
f0102944:	83 c4 08             	add    $0x8,%esp
f0102947:	2b 7e 10             	sub    0x10(%esi),%edi
f010294a:	57                   	push   %edi
f010294b:	6a 44                	push   $0x44
f010294d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102950:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102953:	b8 50 48 10 f0       	mov    $0xf0104850,%eax
f0102958:	e8 c9 fd ff ff       	call   f0102726 <stab_binsearch>
	if (lfun > rfun) 
f010295d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102960:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102963:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0102966:	83 c4 10             	add    $0x10,%esp
f0102969:	39 c8                	cmp    %ecx,%eax
f010296b:	0f 8f b2 00 00 00    	jg     f0102a23 <debuginfo_eip+0x207>
       	  return -1;
        info->eip_line = stabs[lfun].n_desc;
f0102971:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102974:	8d 04 85 50 48 10 f0 	lea    -0xfefb7b0(,%eax,4),%eax
f010297b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010297e:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f0102982:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102985:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102988:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010298b:	8d 04 85 50 48 10 f0 	lea    -0xfefb7b0(,%eax,4),%eax
f0102992:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0102995:	eb 06                	jmp    f010299d <debuginfo_eip+0x181>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0102997:	83 eb 01             	sub    $0x1,%ebx
f010299a:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010299d:	39 fb                	cmp    %edi,%ebx
f010299f:	7c 39                	jl     f01029da <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f01029a1:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01029a5:	80 fa 84             	cmp    $0x84,%dl
f01029a8:	74 0b                	je     f01029b5 <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01029aa:	80 fa 64             	cmp    $0x64,%dl
f01029ad:	75 e8                	jne    f0102997 <debuginfo_eip+0x17b>
f01029af:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01029b3:	74 e2                	je     f0102997 <debuginfo_eip+0x17b>
f01029b5:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01029b8:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01029bb:	8b 14 85 50 48 10 f0 	mov    -0xfefb7b0(,%eax,4),%edx
f01029c2:	b8 5d be 10 f0       	mov    $0xf010be5d,%eax
f01029c7:	2d b9 a0 10 f0       	sub    $0xf010a0b9,%eax
f01029cc:	39 c2                	cmp    %eax,%edx
f01029ce:	73 0d                	jae    f01029dd <debuginfo_eip+0x1c1>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01029d0:	81 c2 b9 a0 10 f0    	add    $0xf010a0b9,%edx
f01029d6:	89 16                	mov    %edx,(%esi)
f01029d8:	eb 03                	jmp    f01029dd <debuginfo_eip+0x1c1>
f01029da:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029dd:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029e2:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01029e5:	39 cf                	cmp    %ecx,%edi
f01029e7:	7d 46                	jge    f0102a2f <debuginfo_eip+0x213>
		for (lline = lfun + 1;
f01029e9:	89 f8                	mov    %edi,%eax
f01029eb:	83 c0 01             	add    $0x1,%eax
f01029ee:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01029f1:	eb 07                	jmp    f01029fa <debuginfo_eip+0x1de>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01029f3:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01029f7:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01029fa:	39 c8                	cmp    %ecx,%eax
f01029fc:	74 2c                	je     f0102a2a <debuginfo_eip+0x20e>
f01029fe:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102a01:	80 7a 04 a0          	cmpb   $0xa0,0x4(%edx)
f0102a05:	74 ec                	je     f01029f3 <debuginfo_eip+0x1d7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a07:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a0c:	eb 21                	jmp    f0102a2f <debuginfo_eip+0x213>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a0e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a13:	eb 1a                	jmp    f0102a2f <debuginfo_eip+0x213>
f0102a15:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a1a:	eb 13                	jmp    f0102a2f <debuginfo_eip+0x213>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a1c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a21:	eb 0c                	jmp    f0102a2f <debuginfo_eip+0x213>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
	if (lfun > rfun) 
       	  return -1;
f0102a23:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a28:	eb 05                	jmp    f0102a2f <debuginfo_eip+0x213>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a2a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a2f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a32:	5b                   	pop    %ebx
f0102a33:	5e                   	pop    %esi
f0102a34:	5f                   	pop    %edi
f0102a35:	5d                   	pop    %ebp
f0102a36:	c3                   	ret    

f0102a37 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a37:	55                   	push   %ebp
f0102a38:	89 e5                	mov    %esp,%ebp
f0102a3a:	57                   	push   %edi
f0102a3b:	56                   	push   %esi
f0102a3c:	53                   	push   %ebx
f0102a3d:	83 ec 1c             	sub    $0x1c,%esp
f0102a40:	89 c7                	mov    %eax,%edi
f0102a42:	89 d6                	mov    %edx,%esi
f0102a44:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a47:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a4a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102a4d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102a50:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102a53:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a58:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102a5b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102a5e:	39 d3                	cmp    %edx,%ebx
f0102a60:	72 05                	jb     f0102a67 <printnum+0x30>
f0102a62:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102a65:	77 45                	ja     f0102aac <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102a67:	83 ec 0c             	sub    $0xc,%esp
f0102a6a:	ff 75 18             	pushl  0x18(%ebp)
f0102a6d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a70:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102a73:	53                   	push   %ebx
f0102a74:	ff 75 10             	pushl  0x10(%ebp)
f0102a77:	83 ec 08             	sub    $0x8,%esp
f0102a7a:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a7d:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a80:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a83:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a86:	e8 45 09 00 00       	call   f01033d0 <__udivdi3>
f0102a8b:	83 c4 18             	add    $0x18,%esp
f0102a8e:	52                   	push   %edx
f0102a8f:	50                   	push   %eax
f0102a90:	89 f2                	mov    %esi,%edx
f0102a92:	89 f8                	mov    %edi,%eax
f0102a94:	e8 9e ff ff ff       	call   f0102a37 <printnum>
f0102a99:	83 c4 20             	add    $0x20,%esp
f0102a9c:	eb 18                	jmp    f0102ab6 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102a9e:	83 ec 08             	sub    $0x8,%esp
f0102aa1:	56                   	push   %esi
f0102aa2:	ff 75 18             	pushl  0x18(%ebp)
f0102aa5:	ff d7                	call   *%edi
f0102aa7:	83 c4 10             	add    $0x10,%esp
f0102aaa:	eb 03                	jmp    f0102aaf <printnum+0x78>
f0102aac:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102aaf:	83 eb 01             	sub    $0x1,%ebx
f0102ab2:	85 db                	test   %ebx,%ebx
f0102ab4:	7f e8                	jg     f0102a9e <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102ab6:	83 ec 08             	sub    $0x8,%esp
f0102ab9:	56                   	push   %esi
f0102aba:	83 ec 04             	sub    $0x4,%esp
f0102abd:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102ac0:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ac3:	ff 75 dc             	pushl  -0x24(%ebp)
f0102ac6:	ff 75 d8             	pushl  -0x28(%ebp)
f0102ac9:	e8 32 0a 00 00       	call   f0103500 <__umoddi3>
f0102ace:	83 c4 14             	add    $0x14,%esp
f0102ad1:	0f be 80 19 46 10 f0 	movsbl -0xfefb9e7(%eax),%eax
f0102ad8:	50                   	push   %eax
f0102ad9:	ff d7                	call   *%edi
}
f0102adb:	83 c4 10             	add    $0x10,%esp
f0102ade:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ae1:	5b                   	pop    %ebx
f0102ae2:	5e                   	pop    %esi
f0102ae3:	5f                   	pop    %edi
f0102ae4:	5d                   	pop    %ebp
f0102ae5:	c3                   	ret    

f0102ae6 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102ae6:	55                   	push   %ebp
f0102ae7:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102ae9:	83 fa 01             	cmp    $0x1,%edx
f0102aec:	7e 0e                	jle    f0102afc <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102aee:	8b 10                	mov    (%eax),%edx
f0102af0:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102af3:	89 08                	mov    %ecx,(%eax)
f0102af5:	8b 02                	mov    (%edx),%eax
f0102af7:	8b 52 04             	mov    0x4(%edx),%edx
f0102afa:	eb 22                	jmp    f0102b1e <getuint+0x38>
	else if (lflag)
f0102afc:	85 d2                	test   %edx,%edx
f0102afe:	74 10                	je     f0102b10 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102b00:	8b 10                	mov    (%eax),%edx
f0102b02:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b05:	89 08                	mov    %ecx,(%eax)
f0102b07:	8b 02                	mov    (%edx),%eax
f0102b09:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b0e:	eb 0e                	jmp    f0102b1e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102b10:	8b 10                	mov    (%eax),%edx
f0102b12:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b15:	89 08                	mov    %ecx,(%eax)
f0102b17:	8b 02                	mov    (%edx),%eax
f0102b19:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102b1e:	5d                   	pop    %ebp
f0102b1f:	c3                   	ret    

f0102b20 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b20:	55                   	push   %ebp
f0102b21:	89 e5                	mov    %esp,%ebp
f0102b23:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b26:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b2a:	8b 10                	mov    (%eax),%edx
f0102b2c:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b2f:	73 0a                	jae    f0102b3b <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b31:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b34:	89 08                	mov    %ecx,(%eax)
f0102b36:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b39:	88 02                	mov    %al,(%edx)
}
f0102b3b:	5d                   	pop    %ebp
f0102b3c:	c3                   	ret    

f0102b3d <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b3d:	55                   	push   %ebp
f0102b3e:	89 e5                	mov    %esp,%ebp
f0102b40:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b43:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b46:	50                   	push   %eax
f0102b47:	ff 75 10             	pushl  0x10(%ebp)
f0102b4a:	ff 75 0c             	pushl  0xc(%ebp)
f0102b4d:	ff 75 08             	pushl  0x8(%ebp)
f0102b50:	e8 05 00 00 00       	call   f0102b5a <vprintfmt>
	va_end(ap);
}
f0102b55:	83 c4 10             	add    $0x10,%esp
f0102b58:	c9                   	leave  
f0102b59:	c3                   	ret    

f0102b5a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102b5a:	55                   	push   %ebp
f0102b5b:	89 e5                	mov    %esp,%ebp
f0102b5d:	57                   	push   %edi
f0102b5e:	56                   	push   %esi
f0102b5f:	53                   	push   %ebx
f0102b60:	83 ec 2c             	sub    $0x2c,%esp
f0102b63:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b66:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b69:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102b6c:	eb 12                	jmp    f0102b80 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102b6e:	85 c0                	test   %eax,%eax
f0102b70:	0f 84 89 03 00 00    	je     f0102eff <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102b76:	83 ec 08             	sub    $0x8,%esp
f0102b79:	53                   	push   %ebx
f0102b7a:	50                   	push   %eax
f0102b7b:	ff d6                	call   *%esi
f0102b7d:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102b80:	83 c7 01             	add    $0x1,%edi
f0102b83:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102b87:	83 f8 25             	cmp    $0x25,%eax
f0102b8a:	75 e2                	jne    f0102b6e <vprintfmt+0x14>
f0102b8c:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102b90:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102b97:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b9e:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102ba5:	ba 00 00 00 00       	mov    $0x0,%edx
f0102baa:	eb 07                	jmp    f0102bb3 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bac:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102baf:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bb3:	8d 47 01             	lea    0x1(%edi),%eax
f0102bb6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102bb9:	0f b6 07             	movzbl (%edi),%eax
f0102bbc:	0f b6 c8             	movzbl %al,%ecx
f0102bbf:	83 e8 23             	sub    $0x23,%eax
f0102bc2:	3c 55                	cmp    $0x55,%al
f0102bc4:	0f 87 1a 03 00 00    	ja     f0102ee4 <vprintfmt+0x38a>
f0102bca:	0f b6 c0             	movzbl %al,%eax
f0102bcd:	ff 24 85 c0 46 10 f0 	jmp    *-0xfefb940(,%eax,4)
f0102bd4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102bd7:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102bdb:	eb d6                	jmp    f0102bb3 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bdd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102be0:	b8 00 00 00 00       	mov    $0x0,%eax
f0102be5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102be8:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102beb:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102bef:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102bf2:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102bf5:	83 fa 09             	cmp    $0x9,%edx
f0102bf8:	77 39                	ja     f0102c33 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102bfa:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102bfd:	eb e9                	jmp    f0102be8 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102bff:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c02:	8d 48 04             	lea    0x4(%eax),%ecx
f0102c05:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102c08:	8b 00                	mov    (%eax),%eax
f0102c0a:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c0d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c10:	eb 27                	jmp    f0102c39 <vprintfmt+0xdf>
f0102c12:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c15:	85 c0                	test   %eax,%eax
f0102c17:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102c1c:	0f 49 c8             	cmovns %eax,%ecx
f0102c1f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c22:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c25:	eb 8c                	jmp    f0102bb3 <vprintfmt+0x59>
f0102c27:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c2a:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c31:	eb 80                	jmp    f0102bb3 <vprintfmt+0x59>
f0102c33:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102c36:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c39:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c3d:	0f 89 70 ff ff ff    	jns    f0102bb3 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c43:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c46:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c49:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c50:	e9 5e ff ff ff       	jmp    f0102bb3 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102c55:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c58:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102c5b:	e9 53 ff ff ff       	jmp    f0102bb3 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c60:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c63:	8d 50 04             	lea    0x4(%eax),%edx
f0102c66:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c69:	83 ec 08             	sub    $0x8,%esp
f0102c6c:	53                   	push   %ebx
f0102c6d:	ff 30                	pushl  (%eax)
f0102c6f:	ff d6                	call   *%esi
			break;
f0102c71:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c74:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102c77:	e9 04 ff ff ff       	jmp    f0102b80 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c7c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c7f:	8d 50 04             	lea    0x4(%eax),%edx
f0102c82:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c85:	8b 00                	mov    (%eax),%eax
f0102c87:	99                   	cltd   
f0102c88:	31 d0                	xor    %edx,%eax
f0102c8a:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102c8c:	83 f8 07             	cmp    $0x7,%eax
f0102c8f:	7f 0b                	jg     f0102c9c <vprintfmt+0x142>
f0102c91:	8b 14 85 20 48 10 f0 	mov    -0xfefb7e0(,%eax,4),%edx
f0102c98:	85 d2                	test   %edx,%edx
f0102c9a:	75 18                	jne    f0102cb4 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102c9c:	50                   	push   %eax
f0102c9d:	68 31 46 10 f0       	push   $0xf0104631
f0102ca2:	53                   	push   %ebx
f0102ca3:	56                   	push   %esi
f0102ca4:	e8 94 fe ff ff       	call   f0102b3d <printfmt>
f0102ca9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102caf:	e9 cc fe ff ff       	jmp    f0102b80 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102cb4:	52                   	push   %edx
f0102cb5:	68 30 43 10 f0       	push   $0xf0104330
f0102cba:	53                   	push   %ebx
f0102cbb:	56                   	push   %esi
f0102cbc:	e8 7c fe ff ff       	call   f0102b3d <printfmt>
f0102cc1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cc4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cc7:	e9 b4 fe ff ff       	jmp    f0102b80 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102ccc:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ccf:	8d 50 04             	lea    0x4(%eax),%edx
f0102cd2:	89 55 14             	mov    %edx,0x14(%ebp)
f0102cd5:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102cd7:	85 ff                	test   %edi,%edi
f0102cd9:	b8 2a 46 10 f0       	mov    $0xf010462a,%eax
f0102cde:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102ce1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102ce5:	0f 8e 94 00 00 00    	jle    f0102d7f <vprintfmt+0x225>
f0102ceb:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102cef:	0f 84 98 00 00 00    	je     f0102d8d <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cf5:	83 ec 08             	sub    $0x8,%esp
f0102cf8:	ff 75 d0             	pushl  -0x30(%ebp)
f0102cfb:	57                   	push   %edi
f0102cfc:	e8 5f 03 00 00       	call   f0103060 <strnlen>
f0102d01:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d04:	29 c1                	sub    %eax,%ecx
f0102d06:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102d09:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102d0c:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d10:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d13:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102d16:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d18:	eb 0f                	jmp    f0102d29 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102d1a:	83 ec 08             	sub    $0x8,%esp
f0102d1d:	53                   	push   %ebx
f0102d1e:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d21:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d23:	83 ef 01             	sub    $0x1,%edi
f0102d26:	83 c4 10             	add    $0x10,%esp
f0102d29:	85 ff                	test   %edi,%edi
f0102d2b:	7f ed                	jg     f0102d1a <vprintfmt+0x1c0>
f0102d2d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d30:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d33:	85 c9                	test   %ecx,%ecx
f0102d35:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d3a:	0f 49 c1             	cmovns %ecx,%eax
f0102d3d:	29 c1                	sub    %eax,%ecx
f0102d3f:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d42:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d45:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d48:	89 cb                	mov    %ecx,%ebx
f0102d4a:	eb 4d                	jmp    f0102d99 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102d4c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102d50:	74 1b                	je     f0102d6d <vprintfmt+0x213>
f0102d52:	0f be c0             	movsbl %al,%eax
f0102d55:	83 e8 20             	sub    $0x20,%eax
f0102d58:	83 f8 5e             	cmp    $0x5e,%eax
f0102d5b:	76 10                	jbe    f0102d6d <vprintfmt+0x213>
					putch('?', putdat);
f0102d5d:	83 ec 08             	sub    $0x8,%esp
f0102d60:	ff 75 0c             	pushl  0xc(%ebp)
f0102d63:	6a 3f                	push   $0x3f
f0102d65:	ff 55 08             	call   *0x8(%ebp)
f0102d68:	83 c4 10             	add    $0x10,%esp
f0102d6b:	eb 0d                	jmp    f0102d7a <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102d6d:	83 ec 08             	sub    $0x8,%esp
f0102d70:	ff 75 0c             	pushl  0xc(%ebp)
f0102d73:	52                   	push   %edx
f0102d74:	ff 55 08             	call   *0x8(%ebp)
f0102d77:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102d7a:	83 eb 01             	sub    $0x1,%ebx
f0102d7d:	eb 1a                	jmp    f0102d99 <vprintfmt+0x23f>
f0102d7f:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d82:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d85:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d88:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d8b:	eb 0c                	jmp    f0102d99 <vprintfmt+0x23f>
f0102d8d:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d90:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d93:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d96:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d99:	83 c7 01             	add    $0x1,%edi
f0102d9c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102da0:	0f be d0             	movsbl %al,%edx
f0102da3:	85 d2                	test   %edx,%edx
f0102da5:	74 23                	je     f0102dca <vprintfmt+0x270>
f0102da7:	85 f6                	test   %esi,%esi
f0102da9:	78 a1                	js     f0102d4c <vprintfmt+0x1f2>
f0102dab:	83 ee 01             	sub    $0x1,%esi
f0102dae:	79 9c                	jns    f0102d4c <vprintfmt+0x1f2>
f0102db0:	89 df                	mov    %ebx,%edi
f0102db2:	8b 75 08             	mov    0x8(%ebp),%esi
f0102db5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102db8:	eb 18                	jmp    f0102dd2 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102dba:	83 ec 08             	sub    $0x8,%esp
f0102dbd:	53                   	push   %ebx
f0102dbe:	6a 20                	push   $0x20
f0102dc0:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102dc2:	83 ef 01             	sub    $0x1,%edi
f0102dc5:	83 c4 10             	add    $0x10,%esp
f0102dc8:	eb 08                	jmp    f0102dd2 <vprintfmt+0x278>
f0102dca:	89 df                	mov    %ebx,%edi
f0102dcc:	8b 75 08             	mov    0x8(%ebp),%esi
f0102dcf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102dd2:	85 ff                	test   %edi,%edi
f0102dd4:	7f e4                	jg     f0102dba <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102dd6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102dd9:	e9 a2 fd ff ff       	jmp    f0102b80 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102dde:	83 fa 01             	cmp    $0x1,%edx
f0102de1:	7e 16                	jle    f0102df9 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102de3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102de6:	8d 50 08             	lea    0x8(%eax),%edx
f0102de9:	89 55 14             	mov    %edx,0x14(%ebp)
f0102dec:	8b 50 04             	mov    0x4(%eax),%edx
f0102def:	8b 00                	mov    (%eax),%eax
f0102df1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102df4:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102df7:	eb 32                	jmp    f0102e2b <vprintfmt+0x2d1>
	else if (lflag)
f0102df9:	85 d2                	test   %edx,%edx
f0102dfb:	74 18                	je     f0102e15 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102dfd:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e00:	8d 50 04             	lea    0x4(%eax),%edx
f0102e03:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e06:	8b 00                	mov    (%eax),%eax
f0102e08:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e0b:	89 c1                	mov    %eax,%ecx
f0102e0d:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e10:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e13:	eb 16                	jmp    f0102e2b <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102e15:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e18:	8d 50 04             	lea    0x4(%eax),%edx
f0102e1b:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e1e:	8b 00                	mov    (%eax),%eax
f0102e20:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e23:	89 c1                	mov    %eax,%ecx
f0102e25:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e28:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e2b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e2e:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e31:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e36:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e3a:	79 74                	jns    f0102eb0 <vprintfmt+0x356>
				putch('-', putdat);
f0102e3c:	83 ec 08             	sub    $0x8,%esp
f0102e3f:	53                   	push   %ebx
f0102e40:	6a 2d                	push   $0x2d
f0102e42:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e44:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e47:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102e4a:	f7 d8                	neg    %eax
f0102e4c:	83 d2 00             	adc    $0x0,%edx
f0102e4f:	f7 da                	neg    %edx
f0102e51:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102e54:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102e59:	eb 55                	jmp    f0102eb0 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102e5b:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e5e:	e8 83 fc ff ff       	call   f0102ae6 <getuint>
			base = 10;
f0102e63:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102e68:	eb 46                	jmp    f0102eb0 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0102e6a:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e6d:	e8 74 fc ff ff       	call   f0102ae6 <getuint>
			base = 8;
f0102e72:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102e77:	eb 37                	jmp    f0102eb0 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0102e79:	83 ec 08             	sub    $0x8,%esp
f0102e7c:	53                   	push   %ebx
f0102e7d:	6a 30                	push   $0x30
f0102e7f:	ff d6                	call   *%esi
			putch('x', putdat);
f0102e81:	83 c4 08             	add    $0x8,%esp
f0102e84:	53                   	push   %ebx
f0102e85:	6a 78                	push   $0x78
f0102e87:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102e89:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e8c:	8d 50 04             	lea    0x4(%eax),%edx
f0102e8f:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102e92:	8b 00                	mov    (%eax),%eax
f0102e94:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102e99:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102e9c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102ea1:	eb 0d                	jmp    f0102eb0 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102ea3:	8d 45 14             	lea    0x14(%ebp),%eax
f0102ea6:	e8 3b fc ff ff       	call   f0102ae6 <getuint>
			base = 16;
f0102eab:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102eb0:	83 ec 0c             	sub    $0xc,%esp
f0102eb3:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102eb7:	57                   	push   %edi
f0102eb8:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ebb:	51                   	push   %ecx
f0102ebc:	52                   	push   %edx
f0102ebd:	50                   	push   %eax
f0102ebe:	89 da                	mov    %ebx,%edx
f0102ec0:	89 f0                	mov    %esi,%eax
f0102ec2:	e8 70 fb ff ff       	call   f0102a37 <printnum>
			break;
f0102ec7:	83 c4 20             	add    $0x20,%esp
f0102eca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ecd:	e9 ae fc ff ff       	jmp    f0102b80 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102ed2:	83 ec 08             	sub    $0x8,%esp
f0102ed5:	53                   	push   %ebx
f0102ed6:	51                   	push   %ecx
f0102ed7:	ff d6                	call   *%esi
			break;
f0102ed9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102edc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102edf:	e9 9c fc ff ff       	jmp    f0102b80 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102ee4:	83 ec 08             	sub    $0x8,%esp
f0102ee7:	53                   	push   %ebx
f0102ee8:	6a 25                	push   $0x25
f0102eea:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102eec:	83 c4 10             	add    $0x10,%esp
f0102eef:	eb 03                	jmp    f0102ef4 <vprintfmt+0x39a>
f0102ef1:	83 ef 01             	sub    $0x1,%edi
f0102ef4:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102ef8:	75 f7                	jne    f0102ef1 <vprintfmt+0x397>
f0102efa:	e9 81 fc ff ff       	jmp    f0102b80 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102eff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f02:	5b                   	pop    %ebx
f0102f03:	5e                   	pop    %esi
f0102f04:	5f                   	pop    %edi
f0102f05:	5d                   	pop    %ebp
f0102f06:	c3                   	ret    

f0102f07 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102f07:	55                   	push   %ebp
f0102f08:	89 e5                	mov    %esp,%ebp
f0102f0a:	83 ec 18             	sub    $0x18,%esp
f0102f0d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f10:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102f13:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f16:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102f1a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f1d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102f24:	85 c0                	test   %eax,%eax
f0102f26:	74 26                	je     f0102f4e <vsnprintf+0x47>
f0102f28:	85 d2                	test   %edx,%edx
f0102f2a:	7e 22                	jle    f0102f4e <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102f2c:	ff 75 14             	pushl  0x14(%ebp)
f0102f2f:	ff 75 10             	pushl  0x10(%ebp)
f0102f32:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102f35:	50                   	push   %eax
f0102f36:	68 20 2b 10 f0       	push   $0xf0102b20
f0102f3b:	e8 1a fc ff ff       	call   f0102b5a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102f40:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102f43:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102f46:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f49:	83 c4 10             	add    $0x10,%esp
f0102f4c:	eb 05                	jmp    f0102f53 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102f4e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102f53:	c9                   	leave  
f0102f54:	c3                   	ret    

f0102f55 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102f55:	55                   	push   %ebp
f0102f56:	89 e5                	mov    %esp,%ebp
f0102f58:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102f5b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102f5e:	50                   	push   %eax
f0102f5f:	ff 75 10             	pushl  0x10(%ebp)
f0102f62:	ff 75 0c             	pushl  0xc(%ebp)
f0102f65:	ff 75 08             	pushl  0x8(%ebp)
f0102f68:	e8 9a ff ff ff       	call   f0102f07 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102f6d:	c9                   	leave  
f0102f6e:	c3                   	ret    

f0102f6f <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102f6f:	55                   	push   %ebp
f0102f70:	89 e5                	mov    %esp,%ebp
f0102f72:	57                   	push   %edi
f0102f73:	56                   	push   %esi
f0102f74:	53                   	push   %ebx
f0102f75:	83 ec 0c             	sub    $0xc,%esp
f0102f78:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102f7b:	85 c0                	test   %eax,%eax
f0102f7d:	74 11                	je     f0102f90 <readline+0x21>
		cprintf("%s", prompt);
f0102f7f:	83 ec 08             	sub    $0x8,%esp
f0102f82:	50                   	push   %eax
f0102f83:	68 30 43 10 f0       	push   $0xf0104330
f0102f88:	e8 85 f7 ff ff       	call   f0102712 <cprintf>
f0102f8d:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102f90:	83 ec 0c             	sub    $0xc,%esp
f0102f93:	6a 00                	push   $0x0
f0102f95:	e8 ac d6 ff ff       	call   f0100646 <iscons>
f0102f9a:	89 c7                	mov    %eax,%edi
f0102f9c:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102f9f:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102fa4:	e8 8c d6 ff ff       	call   f0100635 <getchar>
f0102fa9:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102fab:	85 c0                	test   %eax,%eax
f0102fad:	79 18                	jns    f0102fc7 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102faf:	83 ec 08             	sub    $0x8,%esp
f0102fb2:	50                   	push   %eax
f0102fb3:	68 40 48 10 f0       	push   $0xf0104840
f0102fb8:	e8 55 f7 ff ff       	call   f0102712 <cprintf>
			return NULL;
f0102fbd:	83 c4 10             	add    $0x10,%esp
f0102fc0:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fc5:	eb 79                	jmp    f0103040 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102fc7:	83 f8 08             	cmp    $0x8,%eax
f0102fca:	0f 94 c2             	sete   %dl
f0102fcd:	83 f8 7f             	cmp    $0x7f,%eax
f0102fd0:	0f 94 c0             	sete   %al
f0102fd3:	08 c2                	or     %al,%dl
f0102fd5:	74 1a                	je     f0102ff1 <readline+0x82>
f0102fd7:	85 f6                	test   %esi,%esi
f0102fd9:	7e 16                	jle    f0102ff1 <readline+0x82>
			if (echoing)
f0102fdb:	85 ff                	test   %edi,%edi
f0102fdd:	74 0d                	je     f0102fec <readline+0x7d>
				cputchar('\b');
f0102fdf:	83 ec 0c             	sub    $0xc,%esp
f0102fe2:	6a 08                	push   $0x8
f0102fe4:	e8 3c d6 ff ff       	call   f0100625 <cputchar>
f0102fe9:	83 c4 10             	add    $0x10,%esp
			i--;
f0102fec:	83 ee 01             	sub    $0x1,%esi
f0102fef:	eb b3                	jmp    f0102fa4 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102ff1:	83 fb 1f             	cmp    $0x1f,%ebx
f0102ff4:	7e 23                	jle    f0103019 <readline+0xaa>
f0102ff6:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102ffc:	7f 1b                	jg     f0103019 <readline+0xaa>
			if (echoing)
f0102ffe:	85 ff                	test   %edi,%edi
f0103000:	74 0c                	je     f010300e <readline+0x9f>
				cputchar(c);
f0103002:	83 ec 0c             	sub    $0xc,%esp
f0103005:	53                   	push   %ebx
f0103006:	e8 1a d6 ff ff       	call   f0100625 <cputchar>
f010300b:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010300e:	88 9e 60 65 11 f0    	mov    %bl,-0xfee9aa0(%esi)
f0103014:	8d 76 01             	lea    0x1(%esi),%esi
f0103017:	eb 8b                	jmp    f0102fa4 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103019:	83 fb 0a             	cmp    $0xa,%ebx
f010301c:	74 05                	je     f0103023 <readline+0xb4>
f010301e:	83 fb 0d             	cmp    $0xd,%ebx
f0103021:	75 81                	jne    f0102fa4 <readline+0x35>
			if (echoing)
f0103023:	85 ff                	test   %edi,%edi
f0103025:	74 0d                	je     f0103034 <readline+0xc5>
				cputchar('\n');
f0103027:	83 ec 0c             	sub    $0xc,%esp
f010302a:	6a 0a                	push   $0xa
f010302c:	e8 f4 d5 ff ff       	call   f0100625 <cputchar>
f0103031:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103034:	c6 86 60 65 11 f0 00 	movb   $0x0,-0xfee9aa0(%esi)
			return buf;
f010303b:	b8 60 65 11 f0       	mov    $0xf0116560,%eax
		}
	}
}
f0103040:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103043:	5b                   	pop    %ebx
f0103044:	5e                   	pop    %esi
f0103045:	5f                   	pop    %edi
f0103046:	5d                   	pop    %ebp
f0103047:	c3                   	ret    

f0103048 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103048:	55                   	push   %ebp
f0103049:	89 e5                	mov    %esp,%ebp
f010304b:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010304e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103053:	eb 03                	jmp    f0103058 <strlen+0x10>
		n++;
f0103055:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103058:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010305c:	75 f7                	jne    f0103055 <strlen+0xd>
		n++;
	return n;
}
f010305e:	5d                   	pop    %ebp
f010305f:	c3                   	ret    

f0103060 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103060:	55                   	push   %ebp
f0103061:	89 e5                	mov    %esp,%ebp
f0103063:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103066:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103069:	ba 00 00 00 00       	mov    $0x0,%edx
f010306e:	eb 03                	jmp    f0103073 <strnlen+0x13>
		n++;
f0103070:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103073:	39 c2                	cmp    %eax,%edx
f0103075:	74 08                	je     f010307f <strnlen+0x1f>
f0103077:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010307b:	75 f3                	jne    f0103070 <strnlen+0x10>
f010307d:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010307f:	5d                   	pop    %ebp
f0103080:	c3                   	ret    

f0103081 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103081:	55                   	push   %ebp
f0103082:	89 e5                	mov    %esp,%ebp
f0103084:	53                   	push   %ebx
f0103085:	8b 45 08             	mov    0x8(%ebp),%eax
f0103088:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010308b:	89 c2                	mov    %eax,%edx
f010308d:	83 c2 01             	add    $0x1,%edx
f0103090:	83 c1 01             	add    $0x1,%ecx
f0103093:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103097:	88 5a ff             	mov    %bl,-0x1(%edx)
f010309a:	84 db                	test   %bl,%bl
f010309c:	75 ef                	jne    f010308d <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010309e:	5b                   	pop    %ebx
f010309f:	5d                   	pop    %ebp
f01030a0:	c3                   	ret    

f01030a1 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01030a1:	55                   	push   %ebp
f01030a2:	89 e5                	mov    %esp,%ebp
f01030a4:	53                   	push   %ebx
f01030a5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01030a8:	53                   	push   %ebx
f01030a9:	e8 9a ff ff ff       	call   f0103048 <strlen>
f01030ae:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01030b1:	ff 75 0c             	pushl  0xc(%ebp)
f01030b4:	01 d8                	add    %ebx,%eax
f01030b6:	50                   	push   %eax
f01030b7:	e8 c5 ff ff ff       	call   f0103081 <strcpy>
	return dst;
}
f01030bc:	89 d8                	mov    %ebx,%eax
f01030be:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030c1:	c9                   	leave  
f01030c2:	c3                   	ret    

f01030c3 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01030c3:	55                   	push   %ebp
f01030c4:	89 e5                	mov    %esp,%ebp
f01030c6:	56                   	push   %esi
f01030c7:	53                   	push   %ebx
f01030c8:	8b 75 08             	mov    0x8(%ebp),%esi
f01030cb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030ce:	89 f3                	mov    %esi,%ebx
f01030d0:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030d3:	89 f2                	mov    %esi,%edx
f01030d5:	eb 0f                	jmp    f01030e6 <strncpy+0x23>
		*dst++ = *src;
f01030d7:	83 c2 01             	add    $0x1,%edx
f01030da:	0f b6 01             	movzbl (%ecx),%eax
f01030dd:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01030e0:	80 39 01             	cmpb   $0x1,(%ecx)
f01030e3:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030e6:	39 da                	cmp    %ebx,%edx
f01030e8:	75 ed                	jne    f01030d7 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01030ea:	89 f0                	mov    %esi,%eax
f01030ec:	5b                   	pop    %ebx
f01030ed:	5e                   	pop    %esi
f01030ee:	5d                   	pop    %ebp
f01030ef:	c3                   	ret    

f01030f0 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01030f0:	55                   	push   %ebp
f01030f1:	89 e5                	mov    %esp,%ebp
f01030f3:	56                   	push   %esi
f01030f4:	53                   	push   %ebx
f01030f5:	8b 75 08             	mov    0x8(%ebp),%esi
f01030f8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030fb:	8b 55 10             	mov    0x10(%ebp),%edx
f01030fe:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103100:	85 d2                	test   %edx,%edx
f0103102:	74 21                	je     f0103125 <strlcpy+0x35>
f0103104:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103108:	89 f2                	mov    %esi,%edx
f010310a:	eb 09                	jmp    f0103115 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010310c:	83 c2 01             	add    $0x1,%edx
f010310f:	83 c1 01             	add    $0x1,%ecx
f0103112:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103115:	39 c2                	cmp    %eax,%edx
f0103117:	74 09                	je     f0103122 <strlcpy+0x32>
f0103119:	0f b6 19             	movzbl (%ecx),%ebx
f010311c:	84 db                	test   %bl,%bl
f010311e:	75 ec                	jne    f010310c <strlcpy+0x1c>
f0103120:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103122:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103125:	29 f0                	sub    %esi,%eax
}
f0103127:	5b                   	pop    %ebx
f0103128:	5e                   	pop    %esi
f0103129:	5d                   	pop    %ebp
f010312a:	c3                   	ret    

f010312b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010312b:	55                   	push   %ebp
f010312c:	89 e5                	mov    %esp,%ebp
f010312e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103131:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103134:	eb 06                	jmp    f010313c <strcmp+0x11>
		p++, q++;
f0103136:	83 c1 01             	add    $0x1,%ecx
f0103139:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010313c:	0f b6 01             	movzbl (%ecx),%eax
f010313f:	84 c0                	test   %al,%al
f0103141:	74 04                	je     f0103147 <strcmp+0x1c>
f0103143:	3a 02                	cmp    (%edx),%al
f0103145:	74 ef                	je     f0103136 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103147:	0f b6 c0             	movzbl %al,%eax
f010314a:	0f b6 12             	movzbl (%edx),%edx
f010314d:	29 d0                	sub    %edx,%eax
}
f010314f:	5d                   	pop    %ebp
f0103150:	c3                   	ret    

f0103151 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103151:	55                   	push   %ebp
f0103152:	89 e5                	mov    %esp,%ebp
f0103154:	53                   	push   %ebx
f0103155:	8b 45 08             	mov    0x8(%ebp),%eax
f0103158:	8b 55 0c             	mov    0xc(%ebp),%edx
f010315b:	89 c3                	mov    %eax,%ebx
f010315d:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103160:	eb 06                	jmp    f0103168 <strncmp+0x17>
		n--, p++, q++;
f0103162:	83 c0 01             	add    $0x1,%eax
f0103165:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103168:	39 d8                	cmp    %ebx,%eax
f010316a:	74 15                	je     f0103181 <strncmp+0x30>
f010316c:	0f b6 08             	movzbl (%eax),%ecx
f010316f:	84 c9                	test   %cl,%cl
f0103171:	74 04                	je     f0103177 <strncmp+0x26>
f0103173:	3a 0a                	cmp    (%edx),%cl
f0103175:	74 eb                	je     f0103162 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103177:	0f b6 00             	movzbl (%eax),%eax
f010317a:	0f b6 12             	movzbl (%edx),%edx
f010317d:	29 d0                	sub    %edx,%eax
f010317f:	eb 05                	jmp    f0103186 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103181:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103186:	5b                   	pop    %ebx
f0103187:	5d                   	pop    %ebp
f0103188:	c3                   	ret    

f0103189 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103189:	55                   	push   %ebp
f010318a:	89 e5                	mov    %esp,%ebp
f010318c:	8b 45 08             	mov    0x8(%ebp),%eax
f010318f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103193:	eb 07                	jmp    f010319c <strchr+0x13>
		if (*s == c)
f0103195:	38 ca                	cmp    %cl,%dl
f0103197:	74 0f                	je     f01031a8 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103199:	83 c0 01             	add    $0x1,%eax
f010319c:	0f b6 10             	movzbl (%eax),%edx
f010319f:	84 d2                	test   %dl,%dl
f01031a1:	75 f2                	jne    f0103195 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01031a3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01031a8:	5d                   	pop    %ebp
f01031a9:	c3                   	ret    

f01031aa <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01031aa:	55                   	push   %ebp
f01031ab:	89 e5                	mov    %esp,%ebp
f01031ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01031b0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01031b4:	eb 03                	jmp    f01031b9 <strfind+0xf>
f01031b6:	83 c0 01             	add    $0x1,%eax
f01031b9:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01031bc:	38 ca                	cmp    %cl,%dl
f01031be:	74 04                	je     f01031c4 <strfind+0x1a>
f01031c0:	84 d2                	test   %dl,%dl
f01031c2:	75 f2                	jne    f01031b6 <strfind+0xc>
			break;
	return (char *) s;
}
f01031c4:	5d                   	pop    %ebp
f01031c5:	c3                   	ret    

f01031c6 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01031c6:	55                   	push   %ebp
f01031c7:	89 e5                	mov    %esp,%ebp
f01031c9:	57                   	push   %edi
f01031ca:	56                   	push   %esi
f01031cb:	53                   	push   %ebx
f01031cc:	8b 7d 08             	mov    0x8(%ebp),%edi
f01031cf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01031d2:	85 c9                	test   %ecx,%ecx
f01031d4:	74 36                	je     f010320c <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01031d6:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01031dc:	75 28                	jne    f0103206 <memset+0x40>
f01031de:	f6 c1 03             	test   $0x3,%cl
f01031e1:	75 23                	jne    f0103206 <memset+0x40>
		c &= 0xFF;
f01031e3:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01031e7:	89 d3                	mov    %edx,%ebx
f01031e9:	c1 e3 08             	shl    $0x8,%ebx
f01031ec:	89 d6                	mov    %edx,%esi
f01031ee:	c1 e6 18             	shl    $0x18,%esi
f01031f1:	89 d0                	mov    %edx,%eax
f01031f3:	c1 e0 10             	shl    $0x10,%eax
f01031f6:	09 f0                	or     %esi,%eax
f01031f8:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01031fa:	89 d8                	mov    %ebx,%eax
f01031fc:	09 d0                	or     %edx,%eax
f01031fe:	c1 e9 02             	shr    $0x2,%ecx
f0103201:	fc                   	cld    
f0103202:	f3 ab                	rep stos %eax,%es:(%edi)
f0103204:	eb 06                	jmp    f010320c <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103206:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103209:	fc                   	cld    
f010320a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010320c:	89 f8                	mov    %edi,%eax
f010320e:	5b                   	pop    %ebx
f010320f:	5e                   	pop    %esi
f0103210:	5f                   	pop    %edi
f0103211:	5d                   	pop    %ebp
f0103212:	c3                   	ret    

f0103213 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103213:	55                   	push   %ebp
f0103214:	89 e5                	mov    %esp,%ebp
f0103216:	57                   	push   %edi
f0103217:	56                   	push   %esi
f0103218:	8b 45 08             	mov    0x8(%ebp),%eax
f010321b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010321e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103221:	39 c6                	cmp    %eax,%esi
f0103223:	73 35                	jae    f010325a <memmove+0x47>
f0103225:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103228:	39 d0                	cmp    %edx,%eax
f010322a:	73 2e                	jae    f010325a <memmove+0x47>
		s += n;
		d += n;
f010322c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010322f:	89 d6                	mov    %edx,%esi
f0103231:	09 fe                	or     %edi,%esi
f0103233:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103239:	75 13                	jne    f010324e <memmove+0x3b>
f010323b:	f6 c1 03             	test   $0x3,%cl
f010323e:	75 0e                	jne    f010324e <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103240:	83 ef 04             	sub    $0x4,%edi
f0103243:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103246:	c1 e9 02             	shr    $0x2,%ecx
f0103249:	fd                   	std    
f010324a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010324c:	eb 09                	jmp    f0103257 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010324e:	83 ef 01             	sub    $0x1,%edi
f0103251:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103254:	fd                   	std    
f0103255:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103257:	fc                   	cld    
f0103258:	eb 1d                	jmp    f0103277 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010325a:	89 f2                	mov    %esi,%edx
f010325c:	09 c2                	or     %eax,%edx
f010325e:	f6 c2 03             	test   $0x3,%dl
f0103261:	75 0f                	jne    f0103272 <memmove+0x5f>
f0103263:	f6 c1 03             	test   $0x3,%cl
f0103266:	75 0a                	jne    f0103272 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103268:	c1 e9 02             	shr    $0x2,%ecx
f010326b:	89 c7                	mov    %eax,%edi
f010326d:	fc                   	cld    
f010326e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103270:	eb 05                	jmp    f0103277 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103272:	89 c7                	mov    %eax,%edi
f0103274:	fc                   	cld    
f0103275:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103277:	5e                   	pop    %esi
f0103278:	5f                   	pop    %edi
f0103279:	5d                   	pop    %ebp
f010327a:	c3                   	ret    

f010327b <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010327b:	55                   	push   %ebp
f010327c:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010327e:	ff 75 10             	pushl  0x10(%ebp)
f0103281:	ff 75 0c             	pushl  0xc(%ebp)
f0103284:	ff 75 08             	pushl  0x8(%ebp)
f0103287:	e8 87 ff ff ff       	call   f0103213 <memmove>
}
f010328c:	c9                   	leave  
f010328d:	c3                   	ret    

f010328e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010328e:	55                   	push   %ebp
f010328f:	89 e5                	mov    %esp,%ebp
f0103291:	56                   	push   %esi
f0103292:	53                   	push   %ebx
f0103293:	8b 45 08             	mov    0x8(%ebp),%eax
f0103296:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103299:	89 c6                	mov    %eax,%esi
f010329b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010329e:	eb 1a                	jmp    f01032ba <memcmp+0x2c>
		if (*s1 != *s2)
f01032a0:	0f b6 08             	movzbl (%eax),%ecx
f01032a3:	0f b6 1a             	movzbl (%edx),%ebx
f01032a6:	38 d9                	cmp    %bl,%cl
f01032a8:	74 0a                	je     f01032b4 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01032aa:	0f b6 c1             	movzbl %cl,%eax
f01032ad:	0f b6 db             	movzbl %bl,%ebx
f01032b0:	29 d8                	sub    %ebx,%eax
f01032b2:	eb 0f                	jmp    f01032c3 <memcmp+0x35>
		s1++, s2++;
f01032b4:	83 c0 01             	add    $0x1,%eax
f01032b7:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01032ba:	39 f0                	cmp    %esi,%eax
f01032bc:	75 e2                	jne    f01032a0 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01032be:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032c3:	5b                   	pop    %ebx
f01032c4:	5e                   	pop    %esi
f01032c5:	5d                   	pop    %ebp
f01032c6:	c3                   	ret    

f01032c7 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01032c7:	55                   	push   %ebp
f01032c8:	89 e5                	mov    %esp,%ebp
f01032ca:	53                   	push   %ebx
f01032cb:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01032ce:	89 c1                	mov    %eax,%ecx
f01032d0:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01032d3:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032d7:	eb 0a                	jmp    f01032e3 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01032d9:	0f b6 10             	movzbl (%eax),%edx
f01032dc:	39 da                	cmp    %ebx,%edx
f01032de:	74 07                	je     f01032e7 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032e0:	83 c0 01             	add    $0x1,%eax
f01032e3:	39 c8                	cmp    %ecx,%eax
f01032e5:	72 f2                	jb     f01032d9 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01032e7:	5b                   	pop    %ebx
f01032e8:	5d                   	pop    %ebp
f01032e9:	c3                   	ret    

f01032ea <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01032ea:	55                   	push   %ebp
f01032eb:	89 e5                	mov    %esp,%ebp
f01032ed:	57                   	push   %edi
f01032ee:	56                   	push   %esi
f01032ef:	53                   	push   %ebx
f01032f0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01032f3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032f6:	eb 03                	jmp    f01032fb <strtol+0x11>
		s++;
f01032f8:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032fb:	0f b6 01             	movzbl (%ecx),%eax
f01032fe:	3c 20                	cmp    $0x20,%al
f0103300:	74 f6                	je     f01032f8 <strtol+0xe>
f0103302:	3c 09                	cmp    $0x9,%al
f0103304:	74 f2                	je     f01032f8 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103306:	3c 2b                	cmp    $0x2b,%al
f0103308:	75 0a                	jne    f0103314 <strtol+0x2a>
		s++;
f010330a:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010330d:	bf 00 00 00 00       	mov    $0x0,%edi
f0103312:	eb 11                	jmp    f0103325 <strtol+0x3b>
f0103314:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103319:	3c 2d                	cmp    $0x2d,%al
f010331b:	75 08                	jne    f0103325 <strtol+0x3b>
		s++, neg = 1;
f010331d:	83 c1 01             	add    $0x1,%ecx
f0103320:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103325:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010332b:	75 15                	jne    f0103342 <strtol+0x58>
f010332d:	80 39 30             	cmpb   $0x30,(%ecx)
f0103330:	75 10                	jne    f0103342 <strtol+0x58>
f0103332:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103336:	75 7c                	jne    f01033b4 <strtol+0xca>
		s += 2, base = 16;
f0103338:	83 c1 02             	add    $0x2,%ecx
f010333b:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103340:	eb 16                	jmp    f0103358 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103342:	85 db                	test   %ebx,%ebx
f0103344:	75 12                	jne    f0103358 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103346:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010334b:	80 39 30             	cmpb   $0x30,(%ecx)
f010334e:	75 08                	jne    f0103358 <strtol+0x6e>
		s++, base = 8;
f0103350:	83 c1 01             	add    $0x1,%ecx
f0103353:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103358:	b8 00 00 00 00       	mov    $0x0,%eax
f010335d:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103360:	0f b6 11             	movzbl (%ecx),%edx
f0103363:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103366:	89 f3                	mov    %esi,%ebx
f0103368:	80 fb 09             	cmp    $0x9,%bl
f010336b:	77 08                	ja     f0103375 <strtol+0x8b>
			dig = *s - '0';
f010336d:	0f be d2             	movsbl %dl,%edx
f0103370:	83 ea 30             	sub    $0x30,%edx
f0103373:	eb 22                	jmp    f0103397 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103375:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103378:	89 f3                	mov    %esi,%ebx
f010337a:	80 fb 19             	cmp    $0x19,%bl
f010337d:	77 08                	ja     f0103387 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010337f:	0f be d2             	movsbl %dl,%edx
f0103382:	83 ea 57             	sub    $0x57,%edx
f0103385:	eb 10                	jmp    f0103397 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103387:	8d 72 bf             	lea    -0x41(%edx),%esi
f010338a:	89 f3                	mov    %esi,%ebx
f010338c:	80 fb 19             	cmp    $0x19,%bl
f010338f:	77 16                	ja     f01033a7 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103391:	0f be d2             	movsbl %dl,%edx
f0103394:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103397:	3b 55 10             	cmp    0x10(%ebp),%edx
f010339a:	7d 0b                	jge    f01033a7 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010339c:	83 c1 01             	add    $0x1,%ecx
f010339f:	0f af 45 10          	imul   0x10(%ebp),%eax
f01033a3:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01033a5:	eb b9                	jmp    f0103360 <strtol+0x76>

	if (endptr)
f01033a7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01033ab:	74 0d                	je     f01033ba <strtol+0xd0>
		*endptr = (char *) s;
f01033ad:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033b0:	89 0e                	mov    %ecx,(%esi)
f01033b2:	eb 06                	jmp    f01033ba <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033b4:	85 db                	test   %ebx,%ebx
f01033b6:	74 98                	je     f0103350 <strtol+0x66>
f01033b8:	eb 9e                	jmp    f0103358 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01033ba:	89 c2                	mov    %eax,%edx
f01033bc:	f7 da                	neg    %edx
f01033be:	85 ff                	test   %edi,%edi
f01033c0:	0f 45 c2             	cmovne %edx,%eax
}
f01033c3:	5b                   	pop    %ebx
f01033c4:	5e                   	pop    %esi
f01033c5:	5f                   	pop    %edi
f01033c6:	5d                   	pop    %ebp
f01033c7:	c3                   	ret    
f01033c8:	66 90                	xchg   %ax,%ax
f01033ca:	66 90                	xchg   %ax,%ax
f01033cc:	66 90                	xchg   %ax,%ax
f01033ce:	66 90                	xchg   %ax,%ax

f01033d0 <__udivdi3>:
f01033d0:	55                   	push   %ebp
f01033d1:	57                   	push   %edi
f01033d2:	56                   	push   %esi
f01033d3:	53                   	push   %ebx
f01033d4:	83 ec 1c             	sub    $0x1c,%esp
f01033d7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01033db:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01033df:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01033e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01033e7:	85 f6                	test   %esi,%esi
f01033e9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01033ed:	89 ca                	mov    %ecx,%edx
f01033ef:	89 f8                	mov    %edi,%eax
f01033f1:	75 3d                	jne    f0103430 <__udivdi3+0x60>
f01033f3:	39 cf                	cmp    %ecx,%edi
f01033f5:	0f 87 c5 00 00 00    	ja     f01034c0 <__udivdi3+0xf0>
f01033fb:	85 ff                	test   %edi,%edi
f01033fd:	89 fd                	mov    %edi,%ebp
f01033ff:	75 0b                	jne    f010340c <__udivdi3+0x3c>
f0103401:	b8 01 00 00 00       	mov    $0x1,%eax
f0103406:	31 d2                	xor    %edx,%edx
f0103408:	f7 f7                	div    %edi
f010340a:	89 c5                	mov    %eax,%ebp
f010340c:	89 c8                	mov    %ecx,%eax
f010340e:	31 d2                	xor    %edx,%edx
f0103410:	f7 f5                	div    %ebp
f0103412:	89 c1                	mov    %eax,%ecx
f0103414:	89 d8                	mov    %ebx,%eax
f0103416:	89 cf                	mov    %ecx,%edi
f0103418:	f7 f5                	div    %ebp
f010341a:	89 c3                	mov    %eax,%ebx
f010341c:	89 d8                	mov    %ebx,%eax
f010341e:	89 fa                	mov    %edi,%edx
f0103420:	83 c4 1c             	add    $0x1c,%esp
f0103423:	5b                   	pop    %ebx
f0103424:	5e                   	pop    %esi
f0103425:	5f                   	pop    %edi
f0103426:	5d                   	pop    %ebp
f0103427:	c3                   	ret    
f0103428:	90                   	nop
f0103429:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103430:	39 ce                	cmp    %ecx,%esi
f0103432:	77 74                	ja     f01034a8 <__udivdi3+0xd8>
f0103434:	0f bd fe             	bsr    %esi,%edi
f0103437:	83 f7 1f             	xor    $0x1f,%edi
f010343a:	0f 84 98 00 00 00    	je     f01034d8 <__udivdi3+0x108>
f0103440:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103445:	89 f9                	mov    %edi,%ecx
f0103447:	89 c5                	mov    %eax,%ebp
f0103449:	29 fb                	sub    %edi,%ebx
f010344b:	d3 e6                	shl    %cl,%esi
f010344d:	89 d9                	mov    %ebx,%ecx
f010344f:	d3 ed                	shr    %cl,%ebp
f0103451:	89 f9                	mov    %edi,%ecx
f0103453:	d3 e0                	shl    %cl,%eax
f0103455:	09 ee                	or     %ebp,%esi
f0103457:	89 d9                	mov    %ebx,%ecx
f0103459:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010345d:	89 d5                	mov    %edx,%ebp
f010345f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103463:	d3 ed                	shr    %cl,%ebp
f0103465:	89 f9                	mov    %edi,%ecx
f0103467:	d3 e2                	shl    %cl,%edx
f0103469:	89 d9                	mov    %ebx,%ecx
f010346b:	d3 e8                	shr    %cl,%eax
f010346d:	09 c2                	or     %eax,%edx
f010346f:	89 d0                	mov    %edx,%eax
f0103471:	89 ea                	mov    %ebp,%edx
f0103473:	f7 f6                	div    %esi
f0103475:	89 d5                	mov    %edx,%ebp
f0103477:	89 c3                	mov    %eax,%ebx
f0103479:	f7 64 24 0c          	mull   0xc(%esp)
f010347d:	39 d5                	cmp    %edx,%ebp
f010347f:	72 10                	jb     f0103491 <__udivdi3+0xc1>
f0103481:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103485:	89 f9                	mov    %edi,%ecx
f0103487:	d3 e6                	shl    %cl,%esi
f0103489:	39 c6                	cmp    %eax,%esi
f010348b:	73 07                	jae    f0103494 <__udivdi3+0xc4>
f010348d:	39 d5                	cmp    %edx,%ebp
f010348f:	75 03                	jne    f0103494 <__udivdi3+0xc4>
f0103491:	83 eb 01             	sub    $0x1,%ebx
f0103494:	31 ff                	xor    %edi,%edi
f0103496:	89 d8                	mov    %ebx,%eax
f0103498:	89 fa                	mov    %edi,%edx
f010349a:	83 c4 1c             	add    $0x1c,%esp
f010349d:	5b                   	pop    %ebx
f010349e:	5e                   	pop    %esi
f010349f:	5f                   	pop    %edi
f01034a0:	5d                   	pop    %ebp
f01034a1:	c3                   	ret    
f01034a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01034a8:	31 ff                	xor    %edi,%edi
f01034aa:	31 db                	xor    %ebx,%ebx
f01034ac:	89 d8                	mov    %ebx,%eax
f01034ae:	89 fa                	mov    %edi,%edx
f01034b0:	83 c4 1c             	add    $0x1c,%esp
f01034b3:	5b                   	pop    %ebx
f01034b4:	5e                   	pop    %esi
f01034b5:	5f                   	pop    %edi
f01034b6:	5d                   	pop    %ebp
f01034b7:	c3                   	ret    
f01034b8:	90                   	nop
f01034b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034c0:	89 d8                	mov    %ebx,%eax
f01034c2:	f7 f7                	div    %edi
f01034c4:	31 ff                	xor    %edi,%edi
f01034c6:	89 c3                	mov    %eax,%ebx
f01034c8:	89 d8                	mov    %ebx,%eax
f01034ca:	89 fa                	mov    %edi,%edx
f01034cc:	83 c4 1c             	add    $0x1c,%esp
f01034cf:	5b                   	pop    %ebx
f01034d0:	5e                   	pop    %esi
f01034d1:	5f                   	pop    %edi
f01034d2:	5d                   	pop    %ebp
f01034d3:	c3                   	ret    
f01034d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01034d8:	39 ce                	cmp    %ecx,%esi
f01034da:	72 0c                	jb     f01034e8 <__udivdi3+0x118>
f01034dc:	31 db                	xor    %ebx,%ebx
f01034de:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01034e2:	0f 87 34 ff ff ff    	ja     f010341c <__udivdi3+0x4c>
f01034e8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01034ed:	e9 2a ff ff ff       	jmp    f010341c <__udivdi3+0x4c>
f01034f2:	66 90                	xchg   %ax,%ax
f01034f4:	66 90                	xchg   %ax,%ax
f01034f6:	66 90                	xchg   %ax,%ax
f01034f8:	66 90                	xchg   %ax,%ax
f01034fa:	66 90                	xchg   %ax,%ax
f01034fc:	66 90                	xchg   %ax,%ax
f01034fe:	66 90                	xchg   %ax,%ax

f0103500 <__umoddi3>:
f0103500:	55                   	push   %ebp
f0103501:	57                   	push   %edi
f0103502:	56                   	push   %esi
f0103503:	53                   	push   %ebx
f0103504:	83 ec 1c             	sub    $0x1c,%esp
f0103507:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010350b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010350f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103513:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103517:	85 d2                	test   %edx,%edx
f0103519:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010351d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103521:	89 f3                	mov    %esi,%ebx
f0103523:	89 3c 24             	mov    %edi,(%esp)
f0103526:	89 74 24 04          	mov    %esi,0x4(%esp)
f010352a:	75 1c                	jne    f0103548 <__umoddi3+0x48>
f010352c:	39 f7                	cmp    %esi,%edi
f010352e:	76 50                	jbe    f0103580 <__umoddi3+0x80>
f0103530:	89 c8                	mov    %ecx,%eax
f0103532:	89 f2                	mov    %esi,%edx
f0103534:	f7 f7                	div    %edi
f0103536:	89 d0                	mov    %edx,%eax
f0103538:	31 d2                	xor    %edx,%edx
f010353a:	83 c4 1c             	add    $0x1c,%esp
f010353d:	5b                   	pop    %ebx
f010353e:	5e                   	pop    %esi
f010353f:	5f                   	pop    %edi
f0103540:	5d                   	pop    %ebp
f0103541:	c3                   	ret    
f0103542:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103548:	39 f2                	cmp    %esi,%edx
f010354a:	89 d0                	mov    %edx,%eax
f010354c:	77 52                	ja     f01035a0 <__umoddi3+0xa0>
f010354e:	0f bd ea             	bsr    %edx,%ebp
f0103551:	83 f5 1f             	xor    $0x1f,%ebp
f0103554:	75 5a                	jne    f01035b0 <__umoddi3+0xb0>
f0103556:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010355a:	0f 82 e0 00 00 00    	jb     f0103640 <__umoddi3+0x140>
f0103560:	39 0c 24             	cmp    %ecx,(%esp)
f0103563:	0f 86 d7 00 00 00    	jbe    f0103640 <__umoddi3+0x140>
f0103569:	8b 44 24 08          	mov    0x8(%esp),%eax
f010356d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103571:	83 c4 1c             	add    $0x1c,%esp
f0103574:	5b                   	pop    %ebx
f0103575:	5e                   	pop    %esi
f0103576:	5f                   	pop    %edi
f0103577:	5d                   	pop    %ebp
f0103578:	c3                   	ret    
f0103579:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103580:	85 ff                	test   %edi,%edi
f0103582:	89 fd                	mov    %edi,%ebp
f0103584:	75 0b                	jne    f0103591 <__umoddi3+0x91>
f0103586:	b8 01 00 00 00       	mov    $0x1,%eax
f010358b:	31 d2                	xor    %edx,%edx
f010358d:	f7 f7                	div    %edi
f010358f:	89 c5                	mov    %eax,%ebp
f0103591:	89 f0                	mov    %esi,%eax
f0103593:	31 d2                	xor    %edx,%edx
f0103595:	f7 f5                	div    %ebp
f0103597:	89 c8                	mov    %ecx,%eax
f0103599:	f7 f5                	div    %ebp
f010359b:	89 d0                	mov    %edx,%eax
f010359d:	eb 99                	jmp    f0103538 <__umoddi3+0x38>
f010359f:	90                   	nop
f01035a0:	89 c8                	mov    %ecx,%eax
f01035a2:	89 f2                	mov    %esi,%edx
f01035a4:	83 c4 1c             	add    $0x1c,%esp
f01035a7:	5b                   	pop    %ebx
f01035a8:	5e                   	pop    %esi
f01035a9:	5f                   	pop    %edi
f01035aa:	5d                   	pop    %ebp
f01035ab:	c3                   	ret    
f01035ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01035b0:	8b 34 24             	mov    (%esp),%esi
f01035b3:	bf 20 00 00 00       	mov    $0x20,%edi
f01035b8:	89 e9                	mov    %ebp,%ecx
f01035ba:	29 ef                	sub    %ebp,%edi
f01035bc:	d3 e0                	shl    %cl,%eax
f01035be:	89 f9                	mov    %edi,%ecx
f01035c0:	89 f2                	mov    %esi,%edx
f01035c2:	d3 ea                	shr    %cl,%edx
f01035c4:	89 e9                	mov    %ebp,%ecx
f01035c6:	09 c2                	or     %eax,%edx
f01035c8:	89 d8                	mov    %ebx,%eax
f01035ca:	89 14 24             	mov    %edx,(%esp)
f01035cd:	89 f2                	mov    %esi,%edx
f01035cf:	d3 e2                	shl    %cl,%edx
f01035d1:	89 f9                	mov    %edi,%ecx
f01035d3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01035d7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01035db:	d3 e8                	shr    %cl,%eax
f01035dd:	89 e9                	mov    %ebp,%ecx
f01035df:	89 c6                	mov    %eax,%esi
f01035e1:	d3 e3                	shl    %cl,%ebx
f01035e3:	89 f9                	mov    %edi,%ecx
f01035e5:	89 d0                	mov    %edx,%eax
f01035e7:	d3 e8                	shr    %cl,%eax
f01035e9:	89 e9                	mov    %ebp,%ecx
f01035eb:	09 d8                	or     %ebx,%eax
f01035ed:	89 d3                	mov    %edx,%ebx
f01035ef:	89 f2                	mov    %esi,%edx
f01035f1:	f7 34 24             	divl   (%esp)
f01035f4:	89 d6                	mov    %edx,%esi
f01035f6:	d3 e3                	shl    %cl,%ebx
f01035f8:	f7 64 24 04          	mull   0x4(%esp)
f01035fc:	39 d6                	cmp    %edx,%esi
f01035fe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103602:	89 d1                	mov    %edx,%ecx
f0103604:	89 c3                	mov    %eax,%ebx
f0103606:	72 08                	jb     f0103610 <__umoddi3+0x110>
f0103608:	75 11                	jne    f010361b <__umoddi3+0x11b>
f010360a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010360e:	73 0b                	jae    f010361b <__umoddi3+0x11b>
f0103610:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103614:	1b 14 24             	sbb    (%esp),%edx
f0103617:	89 d1                	mov    %edx,%ecx
f0103619:	89 c3                	mov    %eax,%ebx
f010361b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010361f:	29 da                	sub    %ebx,%edx
f0103621:	19 ce                	sbb    %ecx,%esi
f0103623:	89 f9                	mov    %edi,%ecx
f0103625:	89 f0                	mov    %esi,%eax
f0103627:	d3 e0                	shl    %cl,%eax
f0103629:	89 e9                	mov    %ebp,%ecx
f010362b:	d3 ea                	shr    %cl,%edx
f010362d:	89 e9                	mov    %ebp,%ecx
f010362f:	d3 ee                	shr    %cl,%esi
f0103631:	09 d0                	or     %edx,%eax
f0103633:	89 f2                	mov    %esi,%edx
f0103635:	83 c4 1c             	add    $0x1c,%esp
f0103638:	5b                   	pop    %ebx
f0103639:	5e                   	pop    %esi
f010363a:	5f                   	pop    %edi
f010363b:	5d                   	pop    %ebp
f010363c:	c3                   	ret    
f010363d:	8d 76 00             	lea    0x0(%esi),%esi
f0103640:	29 f9                	sub    %edi,%ecx
f0103642:	19 d6                	sbb    %edx,%esi
f0103644:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103648:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010364c:	e9 18 ff ff ff       	jmp    f0103569 <__umoddi3+0x69>

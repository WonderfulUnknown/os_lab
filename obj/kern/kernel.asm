
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
f0100058:	e8 d0 30 00 00       	call   f010312d <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 bb 04 00 00       	call   f010051d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 c0 35 10 f0       	push   $0xf01035c0
f010006f:	e8 05 26 00 00       	call   f0102679 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 81 0f 00 00       	call   f0100ffa <mem_init>
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
f01000b0:	68 db 35 10 f0       	push   $0xf01035db
f01000b5:	e8 bf 25 00 00       	call   f0102679 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 8f 25 00 00       	call   f0102653 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 c9 38 10 f0 	movl   $0xf01038c9,(%esp)
f01000cb:	e8 a9 25 00 00       	call   f0102679 <cprintf>
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
f01000f2:	68 f3 35 10 f0       	push   $0xf01035f3
f01000f7:	e8 7d 25 00 00       	call   f0102679 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 4b 25 00 00       	call   f0102653 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 c9 38 10 f0 	movl   $0xf01038c9,(%esp)
f010010f:	e8 65 25 00 00       	call   f0102679 <cprintf>
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
f01001c6:	0f b6 82 60 37 10 f0 	movzbl -0xfefc8a0(%edx),%eax
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
f0100202:	0f b6 82 60 37 10 f0 	movzbl -0xfefc8a0(%edx),%eax
f0100209:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f010020f:	0f b6 8a 60 36 10 f0 	movzbl -0xfefc9a0(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d 40 36 10 f0 	mov    -0xfefc9c0(,%ecx,4),%ecx
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
f0100260:	68 0d 36 10 f0       	push   $0xf010360d
f0100265:	e8 0f 24 00 00       	call   f0102679 <cprintf>
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
f0100441:	e8 34 2d 00 00       	call   f010317a <memmove>
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
f0100610:	68 19 36 10 f0       	push   $0xf0103619
f0100615:	e8 5f 20 00 00       	call   f0102679 <cprintf>
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
f0100656:	68 60 38 10 f0       	push   $0xf0103860
f010065b:	68 7e 38 10 f0       	push   $0xf010387e
f0100660:	68 83 38 10 f0       	push   $0xf0103883
f0100665:	e8 0f 20 00 00       	call   f0102679 <cprintf>
f010066a:	83 c4 0c             	add    $0xc,%esp
f010066d:	68 18 39 10 f0       	push   $0xf0103918
f0100672:	68 8c 38 10 f0       	push   $0xf010388c
f0100677:	68 83 38 10 f0       	push   $0xf0103883
f010067c:	e8 f8 1f 00 00       	call   f0102679 <cprintf>
f0100681:	83 c4 0c             	add    $0xc,%esp
f0100684:	68 40 39 10 f0       	push   $0xf0103940
f0100689:	68 95 38 10 f0       	push   $0xf0103895
f010068e:	68 83 38 10 f0       	push   $0xf0103883
f0100693:	e8 e1 1f 00 00       	call   f0102679 <cprintf>
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
f01006a5:	68 9f 38 10 f0       	push   $0xf010389f
f01006aa:	e8 ca 1f 00 00       	call   f0102679 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006af:	83 c4 08             	add    $0x8,%esp
f01006b2:	68 0c 00 10 00       	push   $0x10000c
f01006b7:	68 68 39 10 f0       	push   $0xf0103968
f01006bc:	e8 b8 1f 00 00       	call   f0102679 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006c1:	83 c4 0c             	add    $0xc,%esp
f01006c4:	68 0c 00 10 00       	push   $0x10000c
f01006c9:	68 0c 00 10 f0       	push   $0xf010000c
f01006ce:	68 90 39 10 f0       	push   $0xf0103990
f01006d3:	e8 a1 1f 00 00       	call   f0102679 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d8:	83 c4 0c             	add    $0xc,%esp
f01006db:	68 b1 35 10 00       	push   $0x1035b1
f01006e0:	68 b1 35 10 f0       	push   $0xf01035b1
f01006e5:	68 b4 39 10 f0       	push   $0xf01039b4
f01006ea:	e8 8a 1f 00 00       	call   f0102679 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ef:	83 c4 0c             	add    $0xc,%esp
f01006f2:	68 00 63 11 00       	push   $0x116300
f01006f7:	68 00 63 11 f0       	push   $0xf0116300
f01006fc:	68 d8 39 10 f0       	push   $0xf01039d8
f0100701:	e8 73 1f 00 00       	call   f0102679 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100706:	83 c4 0c             	add    $0xc,%esp
f0100709:	68 70 69 11 00       	push   $0x116970
f010070e:	68 70 69 11 f0       	push   $0xf0116970
f0100713:	68 fc 39 10 f0       	push   $0xf01039fc
f0100718:	e8 5c 1f 00 00       	call   f0102679 <cprintf>
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
f010073e:	68 20 3a 10 f0       	push   $0xf0103a20
f0100743:	e8 31 1f 00 00       	call   f0102679 <cprintf>
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
f010075a:	68 b8 38 10 f0       	push   $0xf01038b8
f010075f:	e8 15 1f 00 00       	call   f0102679 <cprintf>
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
f0100780:	68 4c 3a 10 f0       	push   $0xf0103a4c
f0100785:	e8 ef 1e 00 00       	call   f0102679 <cprintf>
	debuginfo_eip((uintptr_t)eip,&info);
f010078a:	83 c4 18             	add    $0x18,%esp
f010078d:	57                   	push   %edi
f010078e:	56                   	push   %esi
f010078f:	e8 ef 1f 00 00       	call   f0102783 <debuginfo_eip>
	cprintf("%s:%d", info.eip_file, info.eip_line);
f0100794:	83 c4 0c             	add    $0xc,%esp
f0100797:	ff 75 d4             	pushl  -0x2c(%ebp)
f010079a:	ff 75 d0             	pushl  -0x30(%ebp)
f010079d:	68 cb 38 10 f0       	push   $0xf01038cb
f01007a2:	e8 d2 1e 00 00       	call   f0102679 <cprintf>
        cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name,info.eip_fn_addr);
f01007a7:	ff 75 e0             	pushl  -0x20(%ebp)
f01007aa:	ff 75 d8             	pushl  -0x28(%ebp)
f01007ad:	ff 75 dc             	pushl  -0x24(%ebp)
f01007b0:	68 d1 38 10 f0       	push   $0xf01038d1
f01007b5:	e8 bf 1e 00 00       	call   f0102679 <cprintf>
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
f01007d9:	68 84 3a 10 f0       	push   $0xf0103a84
f01007de:	e8 96 1e 00 00       	call   f0102679 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007e3:	c7 04 24 a8 3a 10 f0 	movl   $0xf0103aa8,(%esp)
f01007ea:	e8 8a 1e 00 00       	call   f0102679 <cprintf>
f01007ef:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007f2:	83 ec 0c             	sub    $0xc,%esp
f01007f5:	68 dc 38 10 f0       	push   $0xf01038dc
f01007fa:	e8 d7 26 00 00       	call   f0102ed6 <readline>
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
f010082e:	68 e0 38 10 f0       	push   $0xf01038e0
f0100833:	e8 b8 28 00 00       	call   f01030f0 <strchr>
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
f010084e:	68 e5 38 10 f0       	push   $0xf01038e5
f0100853:	e8 21 1e 00 00       	call   f0102679 <cprintf>
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
f0100877:	68 e0 38 10 f0       	push   $0xf01038e0
f010087c:	e8 6f 28 00 00       	call   f01030f0 <strchr>
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
f01008a5:	ff 34 85 e0 3a 10 f0 	pushl  -0xfefc520(,%eax,4)
f01008ac:	ff 75 a8             	pushl  -0x58(%ebp)
f01008af:	e8 de 27 00 00       	call   f0103092 <strcmp>
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
f01008c9:	ff 14 85 e8 3a 10 f0 	call   *-0xfefc518(,%eax,4)


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
f01008ea:	68 02 39 10 f0       	push   $0xf0103902
f01008ef:	e8 85 1d 00 00       	call   f0102679 <cprintf>
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
f0100963:	68 04 3b 10 f0       	push   $0xf0103b04
f0100968:	68 1d 03 00 00       	push   $0x31d
f010096d:	68 58 42 10 f0       	push   $0xf0104258
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
f01009bb:	68 28 3b 10 f0       	push   $0xf0103b28
f01009c0:	68 60 02 00 00       	push   $0x260
f01009c5:	68 58 42 10 f0       	push   $0xf0104258
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
f0100a4a:	68 04 3b 10 f0       	push   $0xf0103b04
f0100a4f:	6a 52                	push   $0x52
f0100a51:	68 64 42 10 f0       	push   $0xf0104264
f0100a56:	e8 30 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a5b:	83 ec 04             	sub    $0x4,%esp
f0100a5e:	68 80 00 00 00       	push   $0x80
f0100a63:	68 97 00 00 00       	push   $0x97
f0100a68:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a6d:	50                   	push   %eax
f0100a6e:	e8 ba 26 00 00       	call   f010312d <memset>
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
f0100ab4:	68 72 42 10 f0       	push   $0xf0104272
f0100ab9:	68 7e 42 10 f0       	push   $0xf010427e
f0100abe:	68 7a 02 00 00       	push   $0x27a
f0100ac3:	68 58 42 10 f0       	push   $0xf0104258
f0100ac8:	e8 be f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100acd:	39 fa                	cmp    %edi,%edx
f0100acf:	72 19                	jb     f0100aea <check_page_free_list+0x148>
f0100ad1:	68 93 42 10 f0       	push   $0xf0104293
f0100ad6:	68 7e 42 10 f0       	push   $0xf010427e
f0100adb:	68 7b 02 00 00       	push   $0x27b
f0100ae0:	68 58 42 10 f0       	push   $0xf0104258
f0100ae5:	e8 a1 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aea:	89 d0                	mov    %edx,%eax
f0100aec:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100aef:	a8 07                	test   $0x7,%al
f0100af1:	74 19                	je     f0100b0c <check_page_free_list+0x16a>
f0100af3:	68 4c 3b 10 f0       	push   $0xf0103b4c
f0100af8:	68 7e 42 10 f0       	push   $0xf010427e
f0100afd:	68 7c 02 00 00       	push   $0x27c
f0100b02:	68 58 42 10 f0       	push   $0xf0104258
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
f0100b16:	68 a7 42 10 f0       	push   $0xf01042a7
f0100b1b:	68 7e 42 10 f0       	push   $0xf010427e
f0100b20:	68 7f 02 00 00       	push   $0x27f
f0100b25:	68 58 42 10 f0       	push   $0xf0104258
f0100b2a:	e8 5c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b2f:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b34:	75 19                	jne    f0100b4f <check_page_free_list+0x1ad>
f0100b36:	68 b8 42 10 f0       	push   $0xf01042b8
f0100b3b:	68 7e 42 10 f0       	push   $0xf010427e
f0100b40:	68 80 02 00 00       	push   $0x280
f0100b45:	68 58 42 10 f0       	push   $0xf0104258
f0100b4a:	e8 3c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b4f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b54:	75 19                	jne    f0100b6f <check_page_free_list+0x1cd>
f0100b56:	68 80 3b 10 f0       	push   $0xf0103b80
f0100b5b:	68 7e 42 10 f0       	push   $0xf010427e
f0100b60:	68 81 02 00 00       	push   $0x281
f0100b65:	68 58 42 10 f0       	push   $0xf0104258
f0100b6a:	e8 1c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b6f:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b74:	75 19                	jne    f0100b8f <check_page_free_list+0x1ed>
f0100b76:	68 d1 42 10 f0       	push   $0xf01042d1
f0100b7b:	68 7e 42 10 f0       	push   $0xf010427e
f0100b80:	68 82 02 00 00       	push   $0x282
f0100b85:	68 58 42 10 f0       	push   $0xf0104258
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
f0100ba1:	68 04 3b 10 f0       	push   $0xf0103b04
f0100ba6:	6a 52                	push   $0x52
f0100ba8:	68 64 42 10 f0       	push   $0xf0104264
f0100bad:	e8 d9 f4 ff ff       	call   f010008b <_panic>
f0100bb2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bb7:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bba:	76 1e                	jbe    f0100bda <check_page_free_list+0x238>
f0100bbc:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100bc1:	68 7e 42 10 f0       	push   $0xf010427e
f0100bc6:	68 83 02 00 00       	push   $0x283
f0100bcb:	68 58 42 10 f0       	push   $0xf0104258
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
f0100bef:	68 eb 42 10 f0       	push   $0xf01042eb
f0100bf4:	68 7e 42 10 f0       	push   $0xf010427e
f0100bf9:	68 8b 02 00 00       	push   $0x28b
f0100bfe:	68 58 42 10 f0       	push   $0xf0104258
f0100c03:	e8 83 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c08:	85 db                	test   %ebx,%ebx
f0100c0a:	7f 42                	jg     f0100c4e <check_page_free_list+0x2ac>
f0100c0c:	68 fd 42 10 f0       	push   $0xf01042fd
f0100c11:	68 7e 42 10 f0       	push   $0xf010427e
f0100c16:	68 8c 02 00 00       	push   $0x28c
f0100c1b:	68 58 42 10 f0       	push   $0xf0104258
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
f0100d5d:	68 0e 43 10 f0       	push   $0xf010430e
f0100d62:	e8 12 19 00 00       	call   f0102679 <cprintf>
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
f0100d8c:	68 04 3b 10 f0       	push   $0xf0103b04
f0100d91:	6a 52                	push   $0x52
f0100d93:	68 64 42 10 f0       	push   $0xf0104264
f0100d98:	e8 ee f2 ff ff       	call   f010008b <_panic>
			memset(page2kva(Page),'\0',PGSIZE);
f0100d9d:	83 ec 04             	sub    $0x4,%esp
f0100da0:	68 00 10 00 00       	push   $0x1000
f0100da5:	6a 00                	push   $0x0
f0100da7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dac:	50                   	push   %eax
f0100dad:	e8 7b 23 00 00       	call   f010312d <memset>
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
f0100dd2:	68 1b 43 10 f0       	push   $0xf010431b
f0100dd7:	e8 9d 18 00 00       	call   f0102679 <cprintf>
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
f0100e41:	68 04 3b 10 f0       	push   $0xf0103b04
f0100e46:	68 86 01 00 00       	push   $0x186
f0100e4b:	68 58 42 10 f0       	push   $0xf0104258
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
f0100e95:	68 04 3b 10 f0       	push   $0xf0103b04
f0100e9a:	68 8e 01 00 00       	push   $0x18e
f0100e9f:	68 58 42 10 f0       	push   $0xf0104258
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

f0100ecc <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100ecc:	55                   	push   %ebp
f0100ecd:	89 e5                	mov    %esp,%ebp
f0100ecf:	53                   	push   %ebx
f0100ed0:	83 ec 08             	sub    $0x8,%esp
f0100ed3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
f0100ed6:	6a 00                	push   $0x0
f0100ed8:	ff 75 0c             	pushl  0xc(%ebp)
f0100edb:	ff 75 08             	pushl  0x8(%ebp)
f0100ede:	e8 25 ff ff ff       	call   f0100e08 <pgdir_walk>
	if(!pte)
f0100ee3:	83 c4 10             	add    $0x10,%esp
f0100ee6:	85 c0                	test   %eax,%eax
f0100ee8:	74 32                	je     f0100f1c <page_lookup+0x50>
		return NULL;
	if(pte_store)
f0100eea:	85 db                	test   %ebx,%ebx
f0100eec:	74 02                	je     f0100ef0 <page_lookup+0x24>
		*pte_store = pte;
f0100eee:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ef0:	8b 00                	mov    (%eax),%eax
f0100ef2:	c1 e8 0c             	shr    $0xc,%eax
f0100ef5:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0100efb:	72 14                	jb     f0100f11 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100efd:	83 ec 04             	sub    $0x4,%esp
f0100f00:	68 ec 3b 10 f0       	push   $0xf0103bec
f0100f05:	6a 4b                	push   $0x4b
f0100f07:	68 64 42 10 f0       	push   $0xf0104264
f0100f0c:	e8 7a f1 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100f11:	8b 15 6c 69 11 f0    	mov    0xf011696c,%edx
f0100f17:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	return pa2page(PTE_ADDR(*pte));
f0100f1a:	eb 05                	jmp    f0100f21 <page_lookup+0x55>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
	if(!pte)
		return NULL;
f0100f1c:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f0100f21:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f24:	c9                   	leave  
f0100f25:	c3                   	ret    

f0100f26 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100f26:	55                   	push   %ebp
f0100f27:	89 e5                	mov    %esp,%ebp
f0100f29:	53                   	push   %ebx
f0100f2a:	83 ec 18             	sub    $0x18,%esp
f0100f2d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	// pte_t *pte,**pte_store;
	// pte = pgdir_walk(pgdir, (void *)va, 0);
	// pte_store = &pte;
	struct PageInfo *Page;
	Page = page_lookup(pgdir, va, &pte);
f0100f30:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100f33:	50                   	push   %eax
f0100f34:	53                   	push   %ebx
f0100f35:	ff 75 08             	pushl  0x8(%ebp)
f0100f38:	e8 8f ff ff ff       	call   f0100ecc <page_lookup>
	// Page = page_lookup(pgdir, va, pte_store);
	if(Page){
f0100f3d:	83 c4 10             	add    $0x10,%esp
f0100f40:	85 c0                	test   %eax,%eax
f0100f42:	74 18                	je     f0100f5c <page_remove+0x36>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f44:	0f 01 3b             	invlpg (%ebx)
		// Page->pp_ref --;
		tlb_invalidate(pgdir, va);
		page_decref(Page);
f0100f47:	83 ec 0c             	sub    $0xc,%esp
f0100f4a:	50                   	push   %eax
f0100f4b:	e8 91 fe ff ff       	call   f0100de1 <page_decref>
		*pte = 0;//将对应的页表项清空
f0100f50:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f53:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100f59:	83 c4 10             	add    $0x10,%esp
	}
}
f0100f5c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f5f:	c9                   	leave  
f0100f60:	c3                   	ret    

f0100f61 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100f61:	55                   	push   %ebp
f0100f62:	89 e5                	mov    %esp,%ebp
f0100f64:	57                   	push   %edi
f0100f65:	56                   	push   %esi
f0100f66:	53                   	push   %ebx
f0100f67:	83 ec 10             	sub    $0x10,%esp
f0100f6a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f6d:	8b 7d 10             	mov    0x10(%ebp),%edi
	// //pp ->pp_ref++;
    // *pte = page2pa(pp) | perm | PTE_P;
	// return 0;

	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
f0100f70:	6a 01                	push   $0x1
f0100f72:	57                   	push   %edi
f0100f73:	ff 75 08             	pushl  0x8(%ebp)
f0100f76:	e8 8d fe ff ff       	call   f0100e08 <pgdir_walk>
	if(!pte)
f0100f7b:	83 c4 10             	add    $0x10,%esp
f0100f7e:	85 c0                	test   %eax,%eax
f0100f80:	74 6b                	je     f0100fed <page_insert+0x8c>
f0100f82:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	pp->pp_ref++;
f0100f84:	0f b7 4b 04          	movzwl 0x4(%ebx),%ecx
f0100f88:	8d 41 01             	lea    0x1(%ecx),%eax
f0100f8b:	66 89 43 04          	mov    %ax,0x4(%ebx)
	//页表项已经存在，即该虚拟地址已经映射到物理页了 
	if(*pte & PTE_P) { 
f0100f8f:	8b 06                	mov    (%esi),%eax
f0100f91:	a8 01                	test   $0x1,%al
f0100f93:	74 3b                	je     f0100fd0 <page_insert+0x6f>
		if(page2pa(pp) == PTE_ADDR(*pte)) { 
f0100f95:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100f9a:	89 da                	mov    %ebx,%edx
f0100f9c:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0100fa2:	c1 fa 03             	sar    $0x3,%edx
f0100fa5:	c1 e2 0c             	shl    $0xc,%edx
f0100fa8:	39 d0                	cmp    %edx,%eax
f0100faa:	75 15                	jne    f0100fc1 <page_insert+0x60>
			//映射到之前的页，更改权限 
			pp->pp_ref--;
f0100fac:	66 89 4b 04          	mov    %cx,0x4(%ebx)
			*pte = page2pa(pp) | perm | PTE_P;
f0100fb0:	8b 55 14             	mov    0x14(%ebp),%edx
f0100fb3:	83 ca 01             	or     $0x1,%edx
f0100fb6:	09 d0                	or     %edx,%eax
f0100fb8:	89 06                	mov    %eax,(%esi)
			return 0; 
f0100fba:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fbf:	eb 31                	jmp    f0100ff2 <page_insert+0x91>
		}
	 //删除旧映射关系 
		else
			page_remove(pgdir, va); 
f0100fc1:	83 ec 08             	sub    $0x8,%esp
f0100fc4:	57                   	push   %edi
f0100fc5:	ff 75 08             	pushl  0x8(%ebp)
f0100fc8:	e8 59 ff ff ff       	call   f0100f26 <page_remove>
f0100fcd:	83 c4 10             	add    $0x10,%esp
	}
	//pp->pp_ref++;
    *pte = page2pa(pp) | perm | PTE_P;
f0100fd0:	2b 1d 6c 69 11 f0    	sub    0xf011696c,%ebx
f0100fd6:	c1 fb 03             	sar    $0x3,%ebx
f0100fd9:	c1 e3 0c             	shl    $0xc,%ebx
f0100fdc:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fdf:	83 c8 01             	or     $0x1,%eax
f0100fe2:	09 c3                	or     %eax,%ebx
f0100fe4:	89 1e                	mov    %ebx,(%esi)
	return 0;
f0100fe6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100feb:	eb 05                	jmp    f0100ff2 <page_insert+0x91>
	// return 0;

	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
	if(!pte)
		return -E_NO_MEM;
f0100fed:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
			page_remove(pgdir, va); 
	}
	//pp->pp_ref++;
    *pte = page2pa(pp) | perm | PTE_P;
	return 0;
}
f0100ff2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ff5:	5b                   	pop    %ebx
f0100ff6:	5e                   	pop    %esi
f0100ff7:	5f                   	pop    %edi
f0100ff8:	5d                   	pop    %ebp
f0100ff9:	c3                   	ret    

f0100ffa <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100ffa:	55                   	push   %ebp
f0100ffb:	89 e5                	mov    %esp,%ebp
f0100ffd:	57                   	push   %edi
f0100ffe:	56                   	push   %esi
f0100fff:	53                   	push   %ebx
f0101000:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101003:	6a 15                	push   $0x15
f0101005:	e8 08 16 00 00       	call   f0102612 <mc146818_read>
f010100a:	89 c3                	mov    %eax,%ebx
f010100c:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101013:	e8 fa 15 00 00       	call   f0102612 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101018:	c1 e0 08             	shl    $0x8,%eax
f010101b:	09 d8                	or     %ebx,%eax
f010101d:	c1 e0 0a             	shl    $0xa,%eax
f0101020:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101026:	85 c0                	test   %eax,%eax
f0101028:	0f 48 c2             	cmovs  %edx,%eax
f010102b:	c1 f8 0c             	sar    $0xc,%eax
f010102e:	a3 40 65 11 f0       	mov    %eax,0xf0116540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101033:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010103a:	e8 d3 15 00 00       	call   f0102612 <mc146818_read>
f010103f:	89 c3                	mov    %eax,%ebx
f0101041:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101048:	e8 c5 15 00 00       	call   f0102612 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010104d:	c1 e0 08             	shl    $0x8,%eax
f0101050:	09 d8                	or     %ebx,%eax
f0101052:	c1 e0 0a             	shl    $0xa,%eax
f0101055:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010105b:	83 c4 10             	add    $0x10,%esp
f010105e:	85 c0                	test   %eax,%eax
f0101060:	0f 48 c2             	cmovs  %edx,%eax
f0101063:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101066:	85 c0                	test   %eax,%eax
f0101068:	74 0e                	je     f0101078 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010106a:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101070:	89 15 64 69 11 f0    	mov    %edx,0xf0116964
f0101076:	eb 0c                	jmp    f0101084 <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101078:	8b 15 40 65 11 f0    	mov    0xf0116540,%edx
f010107e:	89 15 64 69 11 f0    	mov    %edx,0xf0116964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101084:	c1 e0 0c             	shl    $0xc,%eax
f0101087:	c1 e8 0a             	shr    $0xa,%eax
f010108a:	50                   	push   %eax
f010108b:	a1 40 65 11 f0       	mov    0xf0116540,%eax
f0101090:	c1 e0 0c             	shl    $0xc,%eax
f0101093:	c1 e8 0a             	shr    $0xa,%eax
f0101096:	50                   	push   %eax
f0101097:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f010109c:	c1 e0 0c             	shl    $0xc,%eax
f010109f:	c1 e8 0a             	shr    $0xa,%eax
f01010a2:	50                   	push   %eax
f01010a3:	68 0c 3c 10 f0       	push   $0xf0103c0c
f01010a8:	e8 cc 15 00 00       	call   f0102679 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010ad:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010b2:	e8 4d f8 ff ff       	call   f0100904 <boot_alloc>
f01010b7:	a3 68 69 11 f0       	mov    %eax,0xf0116968
	memset(kern_pgdir, 0, PGSIZE);
f01010bc:	83 c4 0c             	add    $0xc,%esp
f01010bf:	68 00 10 00 00       	push   $0x1000
f01010c4:	6a 00                	push   $0x0
f01010c6:	50                   	push   %eax
f01010c7:	e8 61 20 00 00       	call   f010312d <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010cc:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010d1:	83 c4 10             	add    $0x10,%esp
f01010d4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010d9:	77 15                	ja     f01010f0 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010db:	50                   	push   %eax
f01010dc:	68 48 3c 10 f0       	push   $0xf0103c48
f01010e1:	68 8d 00 00 00       	push   $0x8d
f01010e6:	68 58 42 10 f0       	push   $0xf0104258
f01010eb:	e8 9b ef ff ff       	call   f010008b <_panic>
f01010f0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01010f6:	83 ca 05             	or     $0x5,%edx
f01010f9:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f01010ff:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0101104:	c1 e0 03             	shl    $0x3,%eax
f0101107:	e8 f8 f7 ff ff       	call   f0100904 <boot_alloc>
f010110c:	a3 6c 69 11 f0       	mov    %eax,0xf011696c
	memset(pages,0,npages * sizeof(struct PageInfo));
f0101111:	83 ec 04             	sub    $0x4,%esp
f0101114:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f010111a:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101121:	52                   	push   %edx
f0101122:	6a 00                	push   $0x0
f0101124:	50                   	push   %eax
f0101125:	e8 03 20 00 00       	call   f010312d <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010112a:	e8 27 fb ff ff       	call   f0100c56 <page_init>

	check_page_free_list(1);
f010112f:	b8 01 00 00 00       	mov    $0x1,%eax
f0101134:	e8 69 f8 ff ff       	call   f01009a2 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101139:	83 c4 10             	add    $0x10,%esp
f010113c:	83 3d 6c 69 11 f0 00 	cmpl   $0x0,0xf011696c
f0101143:	75 17                	jne    f010115c <mem_init+0x162>
		panic("'pages' is a null pointer!");
f0101145:	83 ec 04             	sub    $0x4,%esp
f0101148:	68 27 43 10 f0       	push   $0xf0104327
f010114d:	68 9d 02 00 00       	push   $0x29d
f0101152:	68 58 42 10 f0       	push   $0xf0104258
f0101157:	e8 2f ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010115c:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101161:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101166:	eb 05                	jmp    f010116d <mem_init+0x173>
		++nfree;
f0101168:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010116b:	8b 00                	mov    (%eax),%eax
f010116d:	85 c0                	test   %eax,%eax
f010116f:	75 f7                	jne    f0101168 <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101171:	83 ec 0c             	sub    $0xc,%esp
f0101174:	6a 00                	push   $0x0
f0101176:	e8 bb fb ff ff       	call   f0100d36 <page_alloc>
f010117b:	89 c7                	mov    %eax,%edi
f010117d:	83 c4 10             	add    $0x10,%esp
f0101180:	85 c0                	test   %eax,%eax
f0101182:	75 19                	jne    f010119d <mem_init+0x1a3>
f0101184:	68 42 43 10 f0       	push   $0xf0104342
f0101189:	68 7e 42 10 f0       	push   $0xf010427e
f010118e:	68 a5 02 00 00       	push   $0x2a5
f0101193:	68 58 42 10 f0       	push   $0xf0104258
f0101198:	e8 ee ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010119d:	83 ec 0c             	sub    $0xc,%esp
f01011a0:	6a 00                	push   $0x0
f01011a2:	e8 8f fb ff ff       	call   f0100d36 <page_alloc>
f01011a7:	89 c6                	mov    %eax,%esi
f01011a9:	83 c4 10             	add    $0x10,%esp
f01011ac:	85 c0                	test   %eax,%eax
f01011ae:	75 19                	jne    f01011c9 <mem_init+0x1cf>
f01011b0:	68 58 43 10 f0       	push   $0xf0104358
f01011b5:	68 7e 42 10 f0       	push   $0xf010427e
f01011ba:	68 a6 02 00 00       	push   $0x2a6
f01011bf:	68 58 42 10 f0       	push   $0xf0104258
f01011c4:	e8 c2 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01011c9:	83 ec 0c             	sub    $0xc,%esp
f01011cc:	6a 00                	push   $0x0
f01011ce:	e8 63 fb ff ff       	call   f0100d36 <page_alloc>
f01011d3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01011d6:	83 c4 10             	add    $0x10,%esp
f01011d9:	85 c0                	test   %eax,%eax
f01011db:	75 19                	jne    f01011f6 <mem_init+0x1fc>
f01011dd:	68 6e 43 10 f0       	push   $0xf010436e
f01011e2:	68 7e 42 10 f0       	push   $0xf010427e
f01011e7:	68 a7 02 00 00       	push   $0x2a7
f01011ec:	68 58 42 10 f0       	push   $0xf0104258
f01011f1:	e8 95 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01011f6:	39 f7                	cmp    %esi,%edi
f01011f8:	75 19                	jne    f0101213 <mem_init+0x219>
f01011fa:	68 84 43 10 f0       	push   $0xf0104384
f01011ff:	68 7e 42 10 f0       	push   $0xf010427e
f0101204:	68 aa 02 00 00       	push   $0x2aa
f0101209:	68 58 42 10 f0       	push   $0xf0104258
f010120e:	e8 78 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101213:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101216:	39 c6                	cmp    %eax,%esi
f0101218:	74 04                	je     f010121e <mem_init+0x224>
f010121a:	39 c7                	cmp    %eax,%edi
f010121c:	75 19                	jne    f0101237 <mem_init+0x23d>
f010121e:	68 6c 3c 10 f0       	push   $0xf0103c6c
f0101223:	68 7e 42 10 f0       	push   $0xf010427e
f0101228:	68 ab 02 00 00       	push   $0x2ab
f010122d:	68 58 42 10 f0       	push   $0xf0104258
f0101232:	e8 54 ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101237:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010123d:	8b 15 64 69 11 f0    	mov    0xf0116964,%edx
f0101243:	c1 e2 0c             	shl    $0xc,%edx
f0101246:	89 f8                	mov    %edi,%eax
f0101248:	29 c8                	sub    %ecx,%eax
f010124a:	c1 f8 03             	sar    $0x3,%eax
f010124d:	c1 e0 0c             	shl    $0xc,%eax
f0101250:	39 d0                	cmp    %edx,%eax
f0101252:	72 19                	jb     f010126d <mem_init+0x273>
f0101254:	68 96 43 10 f0       	push   $0xf0104396
f0101259:	68 7e 42 10 f0       	push   $0xf010427e
f010125e:	68 ac 02 00 00       	push   $0x2ac
f0101263:	68 58 42 10 f0       	push   $0xf0104258
f0101268:	e8 1e ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010126d:	89 f0                	mov    %esi,%eax
f010126f:	29 c8                	sub    %ecx,%eax
f0101271:	c1 f8 03             	sar    $0x3,%eax
f0101274:	c1 e0 0c             	shl    $0xc,%eax
f0101277:	39 c2                	cmp    %eax,%edx
f0101279:	77 19                	ja     f0101294 <mem_init+0x29a>
f010127b:	68 b3 43 10 f0       	push   $0xf01043b3
f0101280:	68 7e 42 10 f0       	push   $0xf010427e
f0101285:	68 ad 02 00 00       	push   $0x2ad
f010128a:	68 58 42 10 f0       	push   $0xf0104258
f010128f:	e8 f7 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101294:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101297:	29 c8                	sub    %ecx,%eax
f0101299:	c1 f8 03             	sar    $0x3,%eax
f010129c:	c1 e0 0c             	shl    $0xc,%eax
f010129f:	39 c2                	cmp    %eax,%edx
f01012a1:	77 19                	ja     f01012bc <mem_init+0x2c2>
f01012a3:	68 d0 43 10 f0       	push   $0xf01043d0
f01012a8:	68 7e 42 10 f0       	push   $0xf010427e
f01012ad:	68 ae 02 00 00       	push   $0x2ae
f01012b2:	68 58 42 10 f0       	push   $0xf0104258
f01012b7:	e8 cf ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012bc:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01012c1:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01012c4:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01012cb:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01012ce:	83 ec 0c             	sub    $0xc,%esp
f01012d1:	6a 00                	push   $0x0
f01012d3:	e8 5e fa ff ff       	call   f0100d36 <page_alloc>
f01012d8:	83 c4 10             	add    $0x10,%esp
f01012db:	85 c0                	test   %eax,%eax
f01012dd:	74 19                	je     f01012f8 <mem_init+0x2fe>
f01012df:	68 ed 43 10 f0       	push   $0xf01043ed
f01012e4:	68 7e 42 10 f0       	push   $0xf010427e
f01012e9:	68 b5 02 00 00       	push   $0x2b5
f01012ee:	68 58 42 10 f0       	push   $0xf0104258
f01012f3:	e8 93 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01012f8:	83 ec 0c             	sub    $0xc,%esp
f01012fb:	57                   	push   %edi
f01012fc:	e8 bb fa ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f0101301:	89 34 24             	mov    %esi,(%esp)
f0101304:	e8 b3 fa ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f0101309:	83 c4 04             	add    $0x4,%esp
f010130c:	ff 75 d4             	pushl  -0x2c(%ebp)
f010130f:	e8 a8 fa ff ff       	call   f0100dbc <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101314:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010131b:	e8 16 fa ff ff       	call   f0100d36 <page_alloc>
f0101320:	89 c6                	mov    %eax,%esi
f0101322:	83 c4 10             	add    $0x10,%esp
f0101325:	85 c0                	test   %eax,%eax
f0101327:	75 19                	jne    f0101342 <mem_init+0x348>
f0101329:	68 42 43 10 f0       	push   $0xf0104342
f010132e:	68 7e 42 10 f0       	push   $0xf010427e
f0101333:	68 bc 02 00 00       	push   $0x2bc
f0101338:	68 58 42 10 f0       	push   $0xf0104258
f010133d:	e8 49 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101342:	83 ec 0c             	sub    $0xc,%esp
f0101345:	6a 00                	push   $0x0
f0101347:	e8 ea f9 ff ff       	call   f0100d36 <page_alloc>
f010134c:	89 c7                	mov    %eax,%edi
f010134e:	83 c4 10             	add    $0x10,%esp
f0101351:	85 c0                	test   %eax,%eax
f0101353:	75 19                	jne    f010136e <mem_init+0x374>
f0101355:	68 58 43 10 f0       	push   $0xf0104358
f010135a:	68 7e 42 10 f0       	push   $0xf010427e
f010135f:	68 bd 02 00 00       	push   $0x2bd
f0101364:	68 58 42 10 f0       	push   $0xf0104258
f0101369:	e8 1d ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010136e:	83 ec 0c             	sub    $0xc,%esp
f0101371:	6a 00                	push   $0x0
f0101373:	e8 be f9 ff ff       	call   f0100d36 <page_alloc>
f0101378:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010137b:	83 c4 10             	add    $0x10,%esp
f010137e:	85 c0                	test   %eax,%eax
f0101380:	75 19                	jne    f010139b <mem_init+0x3a1>
f0101382:	68 6e 43 10 f0       	push   $0xf010436e
f0101387:	68 7e 42 10 f0       	push   $0xf010427e
f010138c:	68 be 02 00 00       	push   $0x2be
f0101391:	68 58 42 10 f0       	push   $0xf0104258
f0101396:	e8 f0 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010139b:	39 fe                	cmp    %edi,%esi
f010139d:	75 19                	jne    f01013b8 <mem_init+0x3be>
f010139f:	68 84 43 10 f0       	push   $0xf0104384
f01013a4:	68 7e 42 10 f0       	push   $0xf010427e
f01013a9:	68 c0 02 00 00       	push   $0x2c0
f01013ae:	68 58 42 10 f0       	push   $0xf0104258
f01013b3:	e8 d3 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013bb:	39 c7                	cmp    %eax,%edi
f01013bd:	74 04                	je     f01013c3 <mem_init+0x3c9>
f01013bf:	39 c6                	cmp    %eax,%esi
f01013c1:	75 19                	jne    f01013dc <mem_init+0x3e2>
f01013c3:	68 6c 3c 10 f0       	push   $0xf0103c6c
f01013c8:	68 7e 42 10 f0       	push   $0xf010427e
f01013cd:	68 c1 02 00 00       	push   $0x2c1
f01013d2:	68 58 42 10 f0       	push   $0xf0104258
f01013d7:	e8 af ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01013dc:	83 ec 0c             	sub    $0xc,%esp
f01013df:	6a 00                	push   $0x0
f01013e1:	e8 50 f9 ff ff       	call   f0100d36 <page_alloc>
f01013e6:	83 c4 10             	add    $0x10,%esp
f01013e9:	85 c0                	test   %eax,%eax
f01013eb:	74 19                	je     f0101406 <mem_init+0x40c>
f01013ed:	68 ed 43 10 f0       	push   $0xf01043ed
f01013f2:	68 7e 42 10 f0       	push   $0xf010427e
f01013f7:	68 c2 02 00 00       	push   $0x2c2
f01013fc:	68 58 42 10 f0       	push   $0xf0104258
f0101401:	e8 85 ec ff ff       	call   f010008b <_panic>
f0101406:	89 f0                	mov    %esi,%eax
f0101408:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010140e:	c1 f8 03             	sar    $0x3,%eax
f0101411:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101414:	89 c2                	mov    %eax,%edx
f0101416:	c1 ea 0c             	shr    $0xc,%edx
f0101419:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f010141f:	72 12                	jb     f0101433 <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101421:	50                   	push   %eax
f0101422:	68 04 3b 10 f0       	push   $0xf0103b04
f0101427:	6a 52                	push   $0x52
f0101429:	68 64 42 10 f0       	push   $0xf0104264
f010142e:	e8 58 ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101433:	83 ec 04             	sub    $0x4,%esp
f0101436:	68 00 10 00 00       	push   $0x1000
f010143b:	6a 01                	push   $0x1
f010143d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101442:	50                   	push   %eax
f0101443:	e8 e5 1c 00 00       	call   f010312d <memset>
	page_free(pp0);
f0101448:	89 34 24             	mov    %esi,(%esp)
f010144b:	e8 6c f9 ff ff       	call   f0100dbc <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101450:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101457:	e8 da f8 ff ff       	call   f0100d36 <page_alloc>
f010145c:	83 c4 10             	add    $0x10,%esp
f010145f:	85 c0                	test   %eax,%eax
f0101461:	75 19                	jne    f010147c <mem_init+0x482>
f0101463:	68 fc 43 10 f0       	push   $0xf01043fc
f0101468:	68 7e 42 10 f0       	push   $0xf010427e
f010146d:	68 c7 02 00 00       	push   $0x2c7
f0101472:	68 58 42 10 f0       	push   $0xf0104258
f0101477:	e8 0f ec ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f010147c:	39 c6                	cmp    %eax,%esi
f010147e:	74 19                	je     f0101499 <mem_init+0x49f>
f0101480:	68 1a 44 10 f0       	push   $0xf010441a
f0101485:	68 7e 42 10 f0       	push   $0xf010427e
f010148a:	68 c8 02 00 00       	push   $0x2c8
f010148f:	68 58 42 10 f0       	push   $0xf0104258
f0101494:	e8 f2 eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101499:	89 f0                	mov    %esi,%eax
f010149b:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01014a1:	c1 f8 03             	sar    $0x3,%eax
f01014a4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014a7:	89 c2                	mov    %eax,%edx
f01014a9:	c1 ea 0c             	shr    $0xc,%edx
f01014ac:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01014b2:	72 12                	jb     f01014c6 <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014b4:	50                   	push   %eax
f01014b5:	68 04 3b 10 f0       	push   $0xf0103b04
f01014ba:	6a 52                	push   $0x52
f01014bc:	68 64 42 10 f0       	push   $0xf0104264
f01014c1:	e8 c5 eb ff ff       	call   f010008b <_panic>
f01014c6:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01014cc:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014d2:	80 38 00             	cmpb   $0x0,(%eax)
f01014d5:	74 19                	je     f01014f0 <mem_init+0x4f6>
f01014d7:	68 2a 44 10 f0       	push   $0xf010442a
f01014dc:	68 7e 42 10 f0       	push   $0xf010427e
f01014e1:	68 cb 02 00 00       	push   $0x2cb
f01014e6:	68 58 42 10 f0       	push   $0xf0104258
f01014eb:	e8 9b eb ff ff       	call   f010008b <_panic>
f01014f0:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01014f3:	39 d0                	cmp    %edx,%eax
f01014f5:	75 db                	jne    f01014d2 <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01014f7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014fa:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f01014ff:	83 ec 0c             	sub    $0xc,%esp
f0101502:	56                   	push   %esi
f0101503:	e8 b4 f8 ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f0101508:	89 3c 24             	mov    %edi,(%esp)
f010150b:	e8 ac f8 ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f0101510:	83 c4 04             	add    $0x4,%esp
f0101513:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101516:	e8 a1 f8 ff ff       	call   f0100dbc <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010151b:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101520:	83 c4 10             	add    $0x10,%esp
f0101523:	eb 05                	jmp    f010152a <mem_init+0x530>
		--nfree;
f0101525:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101528:	8b 00                	mov    (%eax),%eax
f010152a:	85 c0                	test   %eax,%eax
f010152c:	75 f7                	jne    f0101525 <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f010152e:	85 db                	test   %ebx,%ebx
f0101530:	74 19                	je     f010154b <mem_init+0x551>
f0101532:	68 34 44 10 f0       	push   $0xf0104434
f0101537:	68 7e 42 10 f0       	push   $0xf010427e
f010153c:	68 d8 02 00 00       	push   $0x2d8
f0101541:	68 58 42 10 f0       	push   $0xf0104258
f0101546:	e8 40 eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010154b:	83 ec 0c             	sub    $0xc,%esp
f010154e:	68 8c 3c 10 f0       	push   $0xf0103c8c
f0101553:	e8 21 11 00 00       	call   f0102679 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101558:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010155f:	e8 d2 f7 ff ff       	call   f0100d36 <page_alloc>
f0101564:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101567:	83 c4 10             	add    $0x10,%esp
f010156a:	85 c0                	test   %eax,%eax
f010156c:	75 19                	jne    f0101587 <mem_init+0x58d>
f010156e:	68 42 43 10 f0       	push   $0xf0104342
f0101573:	68 7e 42 10 f0       	push   $0xf010427e
f0101578:	68 31 03 00 00       	push   $0x331
f010157d:	68 58 42 10 f0       	push   $0xf0104258
f0101582:	e8 04 eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101587:	83 ec 0c             	sub    $0xc,%esp
f010158a:	6a 00                	push   $0x0
f010158c:	e8 a5 f7 ff ff       	call   f0100d36 <page_alloc>
f0101591:	89 c3                	mov    %eax,%ebx
f0101593:	83 c4 10             	add    $0x10,%esp
f0101596:	85 c0                	test   %eax,%eax
f0101598:	75 19                	jne    f01015b3 <mem_init+0x5b9>
f010159a:	68 58 43 10 f0       	push   $0xf0104358
f010159f:	68 7e 42 10 f0       	push   $0xf010427e
f01015a4:	68 32 03 00 00       	push   $0x332
f01015a9:	68 58 42 10 f0       	push   $0xf0104258
f01015ae:	e8 d8 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01015b3:	83 ec 0c             	sub    $0xc,%esp
f01015b6:	6a 00                	push   $0x0
f01015b8:	e8 79 f7 ff ff       	call   f0100d36 <page_alloc>
f01015bd:	89 c6                	mov    %eax,%esi
f01015bf:	83 c4 10             	add    $0x10,%esp
f01015c2:	85 c0                	test   %eax,%eax
f01015c4:	75 19                	jne    f01015df <mem_init+0x5e5>
f01015c6:	68 6e 43 10 f0       	push   $0xf010436e
f01015cb:	68 7e 42 10 f0       	push   $0xf010427e
f01015d0:	68 33 03 00 00       	push   $0x333
f01015d5:	68 58 42 10 f0       	push   $0xf0104258
f01015da:	e8 ac ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015df:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01015e2:	75 19                	jne    f01015fd <mem_init+0x603>
f01015e4:	68 84 43 10 f0       	push   $0xf0104384
f01015e9:	68 7e 42 10 f0       	push   $0xf010427e
f01015ee:	68 36 03 00 00       	push   $0x336
f01015f3:	68 58 42 10 f0       	push   $0xf0104258
f01015f8:	e8 8e ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015fd:	39 c3                	cmp    %eax,%ebx
f01015ff:	74 05                	je     f0101606 <mem_init+0x60c>
f0101601:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101604:	75 19                	jne    f010161f <mem_init+0x625>
f0101606:	68 6c 3c 10 f0       	push   $0xf0103c6c
f010160b:	68 7e 42 10 f0       	push   $0xf010427e
f0101610:	68 37 03 00 00       	push   $0x337
f0101615:	68 58 42 10 f0       	push   $0xf0104258
f010161a:	e8 6c ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010161f:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101624:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101627:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f010162e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101631:	83 ec 0c             	sub    $0xc,%esp
f0101634:	6a 00                	push   $0x0
f0101636:	e8 fb f6 ff ff       	call   f0100d36 <page_alloc>
f010163b:	83 c4 10             	add    $0x10,%esp
f010163e:	85 c0                	test   %eax,%eax
f0101640:	74 19                	je     f010165b <mem_init+0x661>
f0101642:	68 ed 43 10 f0       	push   $0xf01043ed
f0101647:	68 7e 42 10 f0       	push   $0xf010427e
f010164c:	68 3e 03 00 00       	push   $0x33e
f0101651:	68 58 42 10 f0       	push   $0xf0104258
f0101656:	e8 30 ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010165b:	83 ec 04             	sub    $0x4,%esp
f010165e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101661:	50                   	push   %eax
f0101662:	6a 00                	push   $0x0
f0101664:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010166a:	e8 5d f8 ff ff       	call   f0100ecc <page_lookup>
f010166f:	83 c4 10             	add    $0x10,%esp
f0101672:	85 c0                	test   %eax,%eax
f0101674:	74 19                	je     f010168f <mem_init+0x695>
f0101676:	68 ac 3c 10 f0       	push   $0xf0103cac
f010167b:	68 7e 42 10 f0       	push   $0xf010427e
f0101680:	68 41 03 00 00       	push   $0x341
f0101685:	68 58 42 10 f0       	push   $0xf0104258
f010168a:	e8 fc e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010168f:	6a 02                	push   $0x2
f0101691:	6a 00                	push   $0x0
f0101693:	53                   	push   %ebx
f0101694:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010169a:	e8 c2 f8 ff ff       	call   f0100f61 <page_insert>
f010169f:	83 c4 10             	add    $0x10,%esp
f01016a2:	85 c0                	test   %eax,%eax
f01016a4:	78 19                	js     f01016bf <mem_init+0x6c5>
f01016a6:	68 e4 3c 10 f0       	push   $0xf0103ce4
f01016ab:	68 7e 42 10 f0       	push   $0xf010427e
f01016b0:	68 44 03 00 00       	push   $0x344
f01016b5:	68 58 42 10 f0       	push   $0xf0104258
f01016ba:	e8 cc e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01016bf:	83 ec 0c             	sub    $0xc,%esp
f01016c2:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016c5:	e8 f2 f6 ff ff       	call   f0100dbc <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01016ca:	6a 02                	push   $0x2
f01016cc:	6a 00                	push   $0x0
f01016ce:	53                   	push   %ebx
f01016cf:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01016d5:	e8 87 f8 ff ff       	call   f0100f61 <page_insert>
f01016da:	83 c4 20             	add    $0x20,%esp
f01016dd:	85 c0                	test   %eax,%eax
f01016df:	74 19                	je     f01016fa <mem_init+0x700>
f01016e1:	68 14 3d 10 f0       	push   $0xf0103d14
f01016e6:	68 7e 42 10 f0       	push   $0xf010427e
f01016eb:	68 48 03 00 00       	push   $0x348
f01016f0:	68 58 42 10 f0       	push   $0xf0104258
f01016f5:	e8 91 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01016fa:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101700:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f0101705:	89 c1                	mov    %eax,%ecx
f0101707:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010170a:	8b 17                	mov    (%edi),%edx
f010170c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101712:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101715:	29 c8                	sub    %ecx,%eax
f0101717:	c1 f8 03             	sar    $0x3,%eax
f010171a:	c1 e0 0c             	shl    $0xc,%eax
f010171d:	39 c2                	cmp    %eax,%edx
f010171f:	74 19                	je     f010173a <mem_init+0x740>
f0101721:	68 44 3d 10 f0       	push   $0xf0103d44
f0101726:	68 7e 42 10 f0       	push   $0xf010427e
f010172b:	68 49 03 00 00       	push   $0x349
f0101730:	68 58 42 10 f0       	push   $0xf0104258
f0101735:	e8 51 e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010173a:	ba 00 00 00 00       	mov    $0x0,%edx
f010173f:	89 f8                	mov    %edi,%eax
f0101741:	e8 f8 f1 ff ff       	call   f010093e <check_va2pa>
f0101746:	89 da                	mov    %ebx,%edx
f0101748:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010174b:	c1 fa 03             	sar    $0x3,%edx
f010174e:	c1 e2 0c             	shl    $0xc,%edx
f0101751:	39 d0                	cmp    %edx,%eax
f0101753:	74 19                	je     f010176e <mem_init+0x774>
f0101755:	68 6c 3d 10 f0       	push   $0xf0103d6c
f010175a:	68 7e 42 10 f0       	push   $0xf010427e
f010175f:	68 4a 03 00 00       	push   $0x34a
f0101764:	68 58 42 10 f0       	push   $0xf0104258
f0101769:	e8 1d e9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f010176e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101773:	74 19                	je     f010178e <mem_init+0x794>
f0101775:	68 3f 44 10 f0       	push   $0xf010443f
f010177a:	68 7e 42 10 f0       	push   $0xf010427e
f010177f:	68 4b 03 00 00       	push   $0x34b
f0101784:	68 58 42 10 f0       	push   $0xf0104258
f0101789:	e8 fd e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f010178e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101791:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101796:	74 19                	je     f01017b1 <mem_init+0x7b7>
f0101798:	68 50 44 10 f0       	push   $0xf0104450
f010179d:	68 7e 42 10 f0       	push   $0xf010427e
f01017a2:	68 4c 03 00 00       	push   $0x34c
f01017a7:	68 58 42 10 f0       	push   $0xf0104258
f01017ac:	e8 da e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017b1:	6a 02                	push   $0x2
f01017b3:	68 00 10 00 00       	push   $0x1000
f01017b8:	56                   	push   %esi
f01017b9:	57                   	push   %edi
f01017ba:	e8 a2 f7 ff ff       	call   f0100f61 <page_insert>
f01017bf:	83 c4 10             	add    $0x10,%esp
f01017c2:	85 c0                	test   %eax,%eax
f01017c4:	74 19                	je     f01017df <mem_init+0x7e5>
f01017c6:	68 9c 3d 10 f0       	push   $0xf0103d9c
f01017cb:	68 7e 42 10 f0       	push   $0xf010427e
f01017d0:	68 4f 03 00 00       	push   $0x34f
f01017d5:	68 58 42 10 f0       	push   $0xf0104258
f01017da:	e8 ac e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017df:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017e4:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01017e9:	e8 50 f1 ff ff       	call   f010093e <check_va2pa>
f01017ee:	89 f2                	mov    %esi,%edx
f01017f0:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01017f6:	c1 fa 03             	sar    $0x3,%edx
f01017f9:	c1 e2 0c             	shl    $0xc,%edx
f01017fc:	39 d0                	cmp    %edx,%eax
f01017fe:	74 19                	je     f0101819 <mem_init+0x81f>
f0101800:	68 d8 3d 10 f0       	push   $0xf0103dd8
f0101805:	68 7e 42 10 f0       	push   $0xf010427e
f010180a:	68 50 03 00 00       	push   $0x350
f010180f:	68 58 42 10 f0       	push   $0xf0104258
f0101814:	e8 72 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101819:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010181e:	74 19                	je     f0101839 <mem_init+0x83f>
f0101820:	68 61 44 10 f0       	push   $0xf0104461
f0101825:	68 7e 42 10 f0       	push   $0xf010427e
f010182a:	68 51 03 00 00       	push   $0x351
f010182f:	68 58 42 10 f0       	push   $0xf0104258
f0101834:	e8 52 e8 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101839:	83 ec 0c             	sub    $0xc,%esp
f010183c:	6a 00                	push   $0x0
f010183e:	e8 f3 f4 ff ff       	call   f0100d36 <page_alloc>
f0101843:	83 c4 10             	add    $0x10,%esp
f0101846:	85 c0                	test   %eax,%eax
f0101848:	74 19                	je     f0101863 <mem_init+0x869>
f010184a:	68 ed 43 10 f0       	push   $0xf01043ed
f010184f:	68 7e 42 10 f0       	push   $0xf010427e
f0101854:	68 54 03 00 00       	push   $0x354
f0101859:	68 58 42 10 f0       	push   $0xf0104258
f010185e:	e8 28 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101863:	6a 02                	push   $0x2
f0101865:	68 00 10 00 00       	push   $0x1000
f010186a:	56                   	push   %esi
f010186b:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101871:	e8 eb f6 ff ff       	call   f0100f61 <page_insert>
f0101876:	83 c4 10             	add    $0x10,%esp
f0101879:	85 c0                	test   %eax,%eax
f010187b:	74 19                	je     f0101896 <mem_init+0x89c>
f010187d:	68 9c 3d 10 f0       	push   $0xf0103d9c
f0101882:	68 7e 42 10 f0       	push   $0xf010427e
f0101887:	68 57 03 00 00       	push   $0x357
f010188c:	68 58 42 10 f0       	push   $0xf0104258
f0101891:	e8 f5 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101896:	ba 00 10 00 00       	mov    $0x1000,%edx
f010189b:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01018a0:	e8 99 f0 ff ff       	call   f010093e <check_va2pa>
f01018a5:	89 f2                	mov    %esi,%edx
f01018a7:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01018ad:	c1 fa 03             	sar    $0x3,%edx
f01018b0:	c1 e2 0c             	shl    $0xc,%edx
f01018b3:	39 d0                	cmp    %edx,%eax
f01018b5:	74 19                	je     f01018d0 <mem_init+0x8d6>
f01018b7:	68 d8 3d 10 f0       	push   $0xf0103dd8
f01018bc:	68 7e 42 10 f0       	push   $0xf010427e
f01018c1:	68 58 03 00 00       	push   $0x358
f01018c6:	68 58 42 10 f0       	push   $0xf0104258
f01018cb:	e8 bb e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018d0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018d5:	74 19                	je     f01018f0 <mem_init+0x8f6>
f01018d7:	68 61 44 10 f0       	push   $0xf0104461
f01018dc:	68 7e 42 10 f0       	push   $0xf010427e
f01018e1:	68 59 03 00 00       	push   $0x359
f01018e6:	68 58 42 10 f0       	push   $0xf0104258
f01018eb:	e8 9b e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01018f0:	83 ec 0c             	sub    $0xc,%esp
f01018f3:	6a 00                	push   $0x0
f01018f5:	e8 3c f4 ff ff       	call   f0100d36 <page_alloc>
f01018fa:	83 c4 10             	add    $0x10,%esp
f01018fd:	85 c0                	test   %eax,%eax
f01018ff:	74 19                	je     f010191a <mem_init+0x920>
f0101901:	68 ed 43 10 f0       	push   $0xf01043ed
f0101906:	68 7e 42 10 f0       	push   $0xf010427e
f010190b:	68 5d 03 00 00       	push   $0x35d
f0101910:	68 58 42 10 f0       	push   $0xf0104258
f0101915:	e8 71 e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010191a:	8b 15 68 69 11 f0    	mov    0xf0116968,%edx
f0101920:	8b 02                	mov    (%edx),%eax
f0101922:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101927:	89 c1                	mov    %eax,%ecx
f0101929:	c1 e9 0c             	shr    $0xc,%ecx
f010192c:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f0101932:	72 15                	jb     f0101949 <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101934:	50                   	push   %eax
f0101935:	68 04 3b 10 f0       	push   $0xf0103b04
f010193a:	68 60 03 00 00       	push   $0x360
f010193f:	68 58 42 10 f0       	push   $0xf0104258
f0101944:	e8 42 e7 ff ff       	call   f010008b <_panic>
f0101949:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010194e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101951:	83 ec 04             	sub    $0x4,%esp
f0101954:	6a 00                	push   $0x0
f0101956:	68 00 10 00 00       	push   $0x1000
f010195b:	52                   	push   %edx
f010195c:	e8 a7 f4 ff ff       	call   f0100e08 <pgdir_walk>
f0101961:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101964:	8d 51 04             	lea    0x4(%ecx),%edx
f0101967:	83 c4 10             	add    $0x10,%esp
f010196a:	39 d0                	cmp    %edx,%eax
f010196c:	74 19                	je     f0101987 <mem_init+0x98d>
f010196e:	68 08 3e 10 f0       	push   $0xf0103e08
f0101973:	68 7e 42 10 f0       	push   $0xf010427e
f0101978:	68 61 03 00 00       	push   $0x361
f010197d:	68 58 42 10 f0       	push   $0xf0104258
f0101982:	e8 04 e7 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101987:	6a 06                	push   $0x6
f0101989:	68 00 10 00 00       	push   $0x1000
f010198e:	56                   	push   %esi
f010198f:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101995:	e8 c7 f5 ff ff       	call   f0100f61 <page_insert>
f010199a:	83 c4 10             	add    $0x10,%esp
f010199d:	85 c0                	test   %eax,%eax
f010199f:	74 19                	je     f01019ba <mem_init+0x9c0>
f01019a1:	68 48 3e 10 f0       	push   $0xf0103e48
f01019a6:	68 7e 42 10 f0       	push   $0xf010427e
f01019ab:	68 64 03 00 00       	push   $0x364
f01019b0:	68 58 42 10 f0       	push   $0xf0104258
f01019b5:	e8 d1 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019ba:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f01019c0:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019c5:	89 f8                	mov    %edi,%eax
f01019c7:	e8 72 ef ff ff       	call   f010093e <check_va2pa>
f01019cc:	89 f2                	mov    %esi,%edx
f01019ce:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01019d4:	c1 fa 03             	sar    $0x3,%edx
f01019d7:	c1 e2 0c             	shl    $0xc,%edx
f01019da:	39 d0                	cmp    %edx,%eax
f01019dc:	74 19                	je     f01019f7 <mem_init+0x9fd>
f01019de:	68 d8 3d 10 f0       	push   $0xf0103dd8
f01019e3:	68 7e 42 10 f0       	push   $0xf010427e
f01019e8:	68 65 03 00 00       	push   $0x365
f01019ed:	68 58 42 10 f0       	push   $0xf0104258
f01019f2:	e8 94 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01019f7:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019fc:	74 19                	je     f0101a17 <mem_init+0xa1d>
f01019fe:	68 61 44 10 f0       	push   $0xf0104461
f0101a03:	68 7e 42 10 f0       	push   $0xf010427e
f0101a08:	68 66 03 00 00       	push   $0x366
f0101a0d:	68 58 42 10 f0       	push   $0xf0104258
f0101a12:	e8 74 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a17:	83 ec 04             	sub    $0x4,%esp
f0101a1a:	6a 00                	push   $0x0
f0101a1c:	68 00 10 00 00       	push   $0x1000
f0101a21:	57                   	push   %edi
f0101a22:	e8 e1 f3 ff ff       	call   f0100e08 <pgdir_walk>
f0101a27:	83 c4 10             	add    $0x10,%esp
f0101a2a:	f6 00 04             	testb  $0x4,(%eax)
f0101a2d:	75 19                	jne    f0101a48 <mem_init+0xa4e>
f0101a2f:	68 88 3e 10 f0       	push   $0xf0103e88
f0101a34:	68 7e 42 10 f0       	push   $0xf010427e
f0101a39:	68 67 03 00 00       	push   $0x367
f0101a3e:	68 58 42 10 f0       	push   $0xf0104258
f0101a43:	e8 43 e6 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a48:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101a4d:	f6 00 04             	testb  $0x4,(%eax)
f0101a50:	75 19                	jne    f0101a6b <mem_init+0xa71>
f0101a52:	68 72 44 10 f0       	push   $0xf0104472
f0101a57:	68 7e 42 10 f0       	push   $0xf010427e
f0101a5c:	68 68 03 00 00       	push   $0x368
f0101a61:	68 58 42 10 f0       	push   $0xf0104258
f0101a66:	e8 20 e6 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a6b:	6a 02                	push   $0x2
f0101a6d:	68 00 10 00 00       	push   $0x1000
f0101a72:	56                   	push   %esi
f0101a73:	50                   	push   %eax
f0101a74:	e8 e8 f4 ff ff       	call   f0100f61 <page_insert>
f0101a79:	83 c4 10             	add    $0x10,%esp
f0101a7c:	85 c0                	test   %eax,%eax
f0101a7e:	74 19                	je     f0101a99 <mem_init+0xa9f>
f0101a80:	68 9c 3d 10 f0       	push   $0xf0103d9c
f0101a85:	68 7e 42 10 f0       	push   $0xf010427e
f0101a8a:	68 6b 03 00 00       	push   $0x36b
f0101a8f:	68 58 42 10 f0       	push   $0xf0104258
f0101a94:	e8 f2 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101a99:	83 ec 04             	sub    $0x4,%esp
f0101a9c:	6a 00                	push   $0x0
f0101a9e:	68 00 10 00 00       	push   $0x1000
f0101aa3:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101aa9:	e8 5a f3 ff ff       	call   f0100e08 <pgdir_walk>
f0101aae:	83 c4 10             	add    $0x10,%esp
f0101ab1:	f6 00 02             	testb  $0x2,(%eax)
f0101ab4:	75 19                	jne    f0101acf <mem_init+0xad5>
f0101ab6:	68 bc 3e 10 f0       	push   $0xf0103ebc
f0101abb:	68 7e 42 10 f0       	push   $0xf010427e
f0101ac0:	68 6c 03 00 00       	push   $0x36c
f0101ac5:	68 58 42 10 f0       	push   $0xf0104258
f0101aca:	e8 bc e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101acf:	83 ec 04             	sub    $0x4,%esp
f0101ad2:	6a 00                	push   $0x0
f0101ad4:	68 00 10 00 00       	push   $0x1000
f0101ad9:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101adf:	e8 24 f3 ff ff       	call   f0100e08 <pgdir_walk>
f0101ae4:	83 c4 10             	add    $0x10,%esp
f0101ae7:	f6 00 04             	testb  $0x4,(%eax)
f0101aea:	74 19                	je     f0101b05 <mem_init+0xb0b>
f0101aec:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0101af1:	68 7e 42 10 f0       	push   $0xf010427e
f0101af6:	68 6d 03 00 00       	push   $0x36d
f0101afb:	68 58 42 10 f0       	push   $0xf0104258
f0101b00:	e8 86 e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b05:	6a 02                	push   $0x2
f0101b07:	68 00 00 40 00       	push   $0x400000
f0101b0c:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b0f:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b15:	e8 47 f4 ff ff       	call   f0100f61 <page_insert>
f0101b1a:	83 c4 10             	add    $0x10,%esp
f0101b1d:	85 c0                	test   %eax,%eax
f0101b1f:	78 19                	js     f0101b3a <mem_init+0xb40>
f0101b21:	68 28 3f 10 f0       	push   $0xf0103f28
f0101b26:	68 7e 42 10 f0       	push   $0xf010427e
f0101b2b:	68 70 03 00 00       	push   $0x370
f0101b30:	68 58 42 10 f0       	push   $0xf0104258
f0101b35:	e8 51 e5 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b3a:	6a 02                	push   $0x2
f0101b3c:	68 00 10 00 00       	push   $0x1000
f0101b41:	53                   	push   %ebx
f0101b42:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b48:	e8 14 f4 ff ff       	call   f0100f61 <page_insert>
f0101b4d:	83 c4 10             	add    $0x10,%esp
f0101b50:	85 c0                	test   %eax,%eax
f0101b52:	74 19                	je     f0101b6d <mem_init+0xb73>
f0101b54:	68 60 3f 10 f0       	push   $0xf0103f60
f0101b59:	68 7e 42 10 f0       	push   $0xf010427e
f0101b5e:	68 73 03 00 00       	push   $0x373
f0101b63:	68 58 42 10 f0       	push   $0xf0104258
f0101b68:	e8 1e e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b6d:	83 ec 04             	sub    $0x4,%esp
f0101b70:	6a 00                	push   $0x0
f0101b72:	68 00 10 00 00       	push   $0x1000
f0101b77:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b7d:	e8 86 f2 ff ff       	call   f0100e08 <pgdir_walk>
f0101b82:	83 c4 10             	add    $0x10,%esp
f0101b85:	f6 00 04             	testb  $0x4,(%eax)
f0101b88:	74 19                	je     f0101ba3 <mem_init+0xba9>
f0101b8a:	68 f0 3e 10 f0       	push   $0xf0103ef0
f0101b8f:	68 7e 42 10 f0       	push   $0xf010427e
f0101b94:	68 74 03 00 00       	push   $0x374
f0101b99:	68 58 42 10 f0       	push   $0xf0104258
f0101b9e:	e8 e8 e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ba3:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101ba9:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bae:	89 f8                	mov    %edi,%eax
f0101bb0:	e8 89 ed ff ff       	call   f010093e <check_va2pa>
f0101bb5:	89 c1                	mov    %eax,%ecx
f0101bb7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101bba:	89 d8                	mov    %ebx,%eax
f0101bbc:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101bc2:	c1 f8 03             	sar    $0x3,%eax
f0101bc5:	c1 e0 0c             	shl    $0xc,%eax
f0101bc8:	39 c1                	cmp    %eax,%ecx
f0101bca:	74 19                	je     f0101be5 <mem_init+0xbeb>
f0101bcc:	68 9c 3f 10 f0       	push   $0xf0103f9c
f0101bd1:	68 7e 42 10 f0       	push   $0xf010427e
f0101bd6:	68 77 03 00 00       	push   $0x377
f0101bdb:	68 58 42 10 f0       	push   $0xf0104258
f0101be0:	e8 a6 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101be5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bea:	89 f8                	mov    %edi,%eax
f0101bec:	e8 4d ed ff ff       	call   f010093e <check_va2pa>
f0101bf1:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101bf4:	74 19                	je     f0101c0f <mem_init+0xc15>
f0101bf6:	68 c8 3f 10 f0       	push   $0xf0103fc8
f0101bfb:	68 7e 42 10 f0       	push   $0xf010427e
f0101c00:	68 78 03 00 00       	push   $0x378
f0101c05:	68 58 42 10 f0       	push   $0xf0104258
f0101c0a:	e8 7c e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c0f:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c14:	74 19                	je     f0101c2f <mem_init+0xc35>
f0101c16:	68 88 44 10 f0       	push   $0xf0104488
f0101c1b:	68 7e 42 10 f0       	push   $0xf010427e
f0101c20:	68 7a 03 00 00       	push   $0x37a
f0101c25:	68 58 42 10 f0       	push   $0xf0104258
f0101c2a:	e8 5c e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c2f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c34:	74 19                	je     f0101c4f <mem_init+0xc55>
f0101c36:	68 99 44 10 f0       	push   $0xf0104499
f0101c3b:	68 7e 42 10 f0       	push   $0xf010427e
f0101c40:	68 7b 03 00 00       	push   $0x37b
f0101c45:	68 58 42 10 f0       	push   $0xf0104258
f0101c4a:	e8 3c e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c4f:	83 ec 0c             	sub    $0xc,%esp
f0101c52:	6a 00                	push   $0x0
f0101c54:	e8 dd f0 ff ff       	call   f0100d36 <page_alloc>
f0101c59:	83 c4 10             	add    $0x10,%esp
f0101c5c:	85 c0                	test   %eax,%eax
f0101c5e:	74 04                	je     f0101c64 <mem_init+0xc6a>
f0101c60:	39 c6                	cmp    %eax,%esi
f0101c62:	74 19                	je     f0101c7d <mem_init+0xc83>
f0101c64:	68 f8 3f 10 f0       	push   $0xf0103ff8
f0101c69:	68 7e 42 10 f0       	push   $0xf010427e
f0101c6e:	68 7e 03 00 00       	push   $0x37e
f0101c73:	68 58 42 10 f0       	push   $0xf0104258
f0101c78:	e8 0e e4 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101c7d:	83 ec 08             	sub    $0x8,%esp
f0101c80:	6a 00                	push   $0x0
f0101c82:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101c88:	e8 99 f2 ff ff       	call   f0100f26 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101c8d:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101c93:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c98:	89 f8                	mov    %edi,%eax
f0101c9a:	e8 9f ec ff ff       	call   f010093e <check_va2pa>
f0101c9f:	83 c4 10             	add    $0x10,%esp
f0101ca2:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ca5:	74 19                	je     f0101cc0 <mem_init+0xcc6>
f0101ca7:	68 1c 40 10 f0       	push   $0xf010401c
f0101cac:	68 7e 42 10 f0       	push   $0xf010427e
f0101cb1:	68 82 03 00 00       	push   $0x382
f0101cb6:	68 58 42 10 f0       	push   $0xf0104258
f0101cbb:	e8 cb e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101cc0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cc5:	89 f8                	mov    %edi,%eax
f0101cc7:	e8 72 ec ff ff       	call   f010093e <check_va2pa>
f0101ccc:	89 da                	mov    %ebx,%edx
f0101cce:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101cd4:	c1 fa 03             	sar    $0x3,%edx
f0101cd7:	c1 e2 0c             	shl    $0xc,%edx
f0101cda:	39 d0                	cmp    %edx,%eax
f0101cdc:	74 19                	je     f0101cf7 <mem_init+0xcfd>
f0101cde:	68 c8 3f 10 f0       	push   $0xf0103fc8
f0101ce3:	68 7e 42 10 f0       	push   $0xf010427e
f0101ce8:	68 83 03 00 00       	push   $0x383
f0101ced:	68 58 42 10 f0       	push   $0xf0104258
f0101cf2:	e8 94 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101cf7:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101cfc:	74 19                	je     f0101d17 <mem_init+0xd1d>
f0101cfe:	68 3f 44 10 f0       	push   $0xf010443f
f0101d03:	68 7e 42 10 f0       	push   $0xf010427e
f0101d08:	68 84 03 00 00       	push   $0x384
f0101d0d:	68 58 42 10 f0       	push   $0xf0104258
f0101d12:	e8 74 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d17:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d1c:	74 19                	je     f0101d37 <mem_init+0xd3d>
f0101d1e:	68 99 44 10 f0       	push   $0xf0104499
f0101d23:	68 7e 42 10 f0       	push   $0xf010427e
f0101d28:	68 85 03 00 00       	push   $0x385
f0101d2d:	68 58 42 10 f0       	push   $0xf0104258
f0101d32:	e8 54 e3 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d37:	6a 00                	push   $0x0
f0101d39:	68 00 10 00 00       	push   $0x1000
f0101d3e:	53                   	push   %ebx
f0101d3f:	57                   	push   %edi
f0101d40:	e8 1c f2 ff ff       	call   f0100f61 <page_insert>
f0101d45:	83 c4 10             	add    $0x10,%esp
f0101d48:	85 c0                	test   %eax,%eax
f0101d4a:	74 19                	je     f0101d65 <mem_init+0xd6b>
f0101d4c:	68 40 40 10 f0       	push   $0xf0104040
f0101d51:	68 7e 42 10 f0       	push   $0xf010427e
f0101d56:	68 88 03 00 00       	push   $0x388
f0101d5b:	68 58 42 10 f0       	push   $0xf0104258
f0101d60:	e8 26 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101d65:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d6a:	75 19                	jne    f0101d85 <mem_init+0xd8b>
f0101d6c:	68 aa 44 10 f0       	push   $0xf01044aa
f0101d71:	68 7e 42 10 f0       	push   $0xf010427e
f0101d76:	68 89 03 00 00       	push   $0x389
f0101d7b:	68 58 42 10 f0       	push   $0xf0104258
f0101d80:	e8 06 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101d85:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101d88:	74 19                	je     f0101da3 <mem_init+0xda9>
f0101d8a:	68 b6 44 10 f0       	push   $0xf01044b6
f0101d8f:	68 7e 42 10 f0       	push   $0xf010427e
f0101d94:	68 8a 03 00 00       	push   $0x38a
f0101d99:	68 58 42 10 f0       	push   $0xf0104258
f0101d9e:	e8 e8 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101da3:	83 ec 08             	sub    $0x8,%esp
f0101da6:	68 00 10 00 00       	push   $0x1000
f0101dab:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101db1:	e8 70 f1 ff ff       	call   f0100f26 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101db6:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101dbc:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dc1:	89 f8                	mov    %edi,%eax
f0101dc3:	e8 76 eb ff ff       	call   f010093e <check_va2pa>
f0101dc8:	83 c4 10             	add    $0x10,%esp
f0101dcb:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dce:	74 19                	je     f0101de9 <mem_init+0xdef>
f0101dd0:	68 1c 40 10 f0       	push   $0xf010401c
f0101dd5:	68 7e 42 10 f0       	push   $0xf010427e
f0101dda:	68 8e 03 00 00       	push   $0x38e
f0101ddf:	68 58 42 10 f0       	push   $0xf0104258
f0101de4:	e8 a2 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101de9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dee:	89 f8                	mov    %edi,%eax
f0101df0:	e8 49 eb ff ff       	call   f010093e <check_va2pa>
f0101df5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101df8:	74 19                	je     f0101e13 <mem_init+0xe19>
f0101dfa:	68 78 40 10 f0       	push   $0xf0104078
f0101dff:	68 7e 42 10 f0       	push   $0xf010427e
f0101e04:	68 8f 03 00 00       	push   $0x38f
f0101e09:	68 58 42 10 f0       	push   $0xf0104258
f0101e0e:	e8 78 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e13:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e18:	74 19                	je     f0101e33 <mem_init+0xe39>
f0101e1a:	68 cb 44 10 f0       	push   $0xf01044cb
f0101e1f:	68 7e 42 10 f0       	push   $0xf010427e
f0101e24:	68 90 03 00 00       	push   $0x390
f0101e29:	68 58 42 10 f0       	push   $0xf0104258
f0101e2e:	e8 58 e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e33:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e38:	74 19                	je     f0101e53 <mem_init+0xe59>
f0101e3a:	68 99 44 10 f0       	push   $0xf0104499
f0101e3f:	68 7e 42 10 f0       	push   $0xf010427e
f0101e44:	68 91 03 00 00       	push   $0x391
f0101e49:	68 58 42 10 f0       	push   $0xf0104258
f0101e4e:	e8 38 e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e53:	83 ec 0c             	sub    $0xc,%esp
f0101e56:	6a 00                	push   $0x0
f0101e58:	e8 d9 ee ff ff       	call   f0100d36 <page_alloc>
f0101e5d:	83 c4 10             	add    $0x10,%esp
f0101e60:	39 c3                	cmp    %eax,%ebx
f0101e62:	75 04                	jne    f0101e68 <mem_init+0xe6e>
f0101e64:	85 c0                	test   %eax,%eax
f0101e66:	75 19                	jne    f0101e81 <mem_init+0xe87>
f0101e68:	68 a0 40 10 f0       	push   $0xf01040a0
f0101e6d:	68 7e 42 10 f0       	push   $0xf010427e
f0101e72:	68 94 03 00 00       	push   $0x394
f0101e77:	68 58 42 10 f0       	push   $0xf0104258
f0101e7c:	e8 0a e2 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e81:	83 ec 0c             	sub    $0xc,%esp
f0101e84:	6a 00                	push   $0x0
f0101e86:	e8 ab ee ff ff       	call   f0100d36 <page_alloc>
f0101e8b:	83 c4 10             	add    $0x10,%esp
f0101e8e:	85 c0                	test   %eax,%eax
f0101e90:	74 19                	je     f0101eab <mem_init+0xeb1>
f0101e92:	68 ed 43 10 f0       	push   $0xf01043ed
f0101e97:	68 7e 42 10 f0       	push   $0xf010427e
f0101e9c:	68 97 03 00 00       	push   $0x397
f0101ea1:	68 58 42 10 f0       	push   $0xf0104258
f0101ea6:	e8 e0 e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101eab:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0101eb1:	8b 11                	mov    (%ecx),%edx
f0101eb3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101eb9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ebc:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101ec2:	c1 f8 03             	sar    $0x3,%eax
f0101ec5:	c1 e0 0c             	shl    $0xc,%eax
f0101ec8:	39 c2                	cmp    %eax,%edx
f0101eca:	74 19                	je     f0101ee5 <mem_init+0xeeb>
f0101ecc:	68 44 3d 10 f0       	push   $0xf0103d44
f0101ed1:	68 7e 42 10 f0       	push   $0xf010427e
f0101ed6:	68 9a 03 00 00       	push   $0x39a
f0101edb:	68 58 42 10 f0       	push   $0xf0104258
f0101ee0:	e8 a6 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101ee5:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101eeb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eee:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ef3:	74 19                	je     f0101f0e <mem_init+0xf14>
f0101ef5:	68 50 44 10 f0       	push   $0xf0104450
f0101efa:	68 7e 42 10 f0       	push   $0xf010427e
f0101eff:	68 9c 03 00 00       	push   $0x39c
f0101f04:	68 58 42 10 f0       	push   $0xf0104258
f0101f09:	e8 7d e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f11:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f17:	83 ec 0c             	sub    $0xc,%esp
f0101f1a:	50                   	push   %eax
f0101f1b:	e8 9c ee ff ff       	call   f0100dbc <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f20:	83 c4 0c             	add    $0xc,%esp
f0101f23:	6a 01                	push   $0x1
f0101f25:	68 00 10 40 00       	push   $0x401000
f0101f2a:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101f30:	e8 d3 ee ff ff       	call   f0100e08 <pgdir_walk>
f0101f35:	89 c7                	mov    %eax,%edi
f0101f37:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f3a:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101f3f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f42:	8b 40 04             	mov    0x4(%eax),%eax
f0101f45:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f4a:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0101f50:	89 c2                	mov    %eax,%edx
f0101f52:	c1 ea 0c             	shr    $0xc,%edx
f0101f55:	83 c4 10             	add    $0x10,%esp
f0101f58:	39 ca                	cmp    %ecx,%edx
f0101f5a:	72 15                	jb     f0101f71 <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f5c:	50                   	push   %eax
f0101f5d:	68 04 3b 10 f0       	push   $0xf0103b04
f0101f62:	68 a3 03 00 00       	push   $0x3a3
f0101f67:	68 58 42 10 f0       	push   $0xf0104258
f0101f6c:	e8 1a e1 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f71:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f76:	39 c7                	cmp    %eax,%edi
f0101f78:	74 19                	je     f0101f93 <mem_init+0xf99>
f0101f7a:	68 dc 44 10 f0       	push   $0xf01044dc
f0101f7f:	68 7e 42 10 f0       	push   $0xf010427e
f0101f84:	68 a4 03 00 00       	push   $0x3a4
f0101f89:	68 58 42 10 f0       	push   $0xf0104258
f0101f8e:	e8 f8 e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101f93:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f96:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101f9d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fa0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fa6:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101fac:	c1 f8 03             	sar    $0x3,%eax
f0101faf:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fb2:	89 c2                	mov    %eax,%edx
f0101fb4:	c1 ea 0c             	shr    $0xc,%edx
f0101fb7:	39 d1                	cmp    %edx,%ecx
f0101fb9:	77 12                	ja     f0101fcd <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fbb:	50                   	push   %eax
f0101fbc:	68 04 3b 10 f0       	push   $0xf0103b04
f0101fc1:	6a 52                	push   $0x52
f0101fc3:	68 64 42 10 f0       	push   $0xf0104264
f0101fc8:	e8 be e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101fcd:	83 ec 04             	sub    $0x4,%esp
f0101fd0:	68 00 10 00 00       	push   $0x1000
f0101fd5:	68 ff 00 00 00       	push   $0xff
f0101fda:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101fdf:	50                   	push   %eax
f0101fe0:	e8 48 11 00 00       	call   f010312d <memset>
	page_free(pp0);
f0101fe5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101fe8:	89 3c 24             	mov    %edi,(%esp)
f0101feb:	e8 cc ed ff ff       	call   f0100dbc <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101ff0:	83 c4 0c             	add    $0xc,%esp
f0101ff3:	6a 01                	push   $0x1
f0101ff5:	6a 00                	push   $0x0
f0101ff7:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ffd:	e8 06 ee ff ff       	call   f0100e08 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102002:	89 fa                	mov    %edi,%edx
f0102004:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f010200a:	c1 fa 03             	sar    $0x3,%edx
f010200d:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102010:	89 d0                	mov    %edx,%eax
f0102012:	c1 e8 0c             	shr    $0xc,%eax
f0102015:	83 c4 10             	add    $0x10,%esp
f0102018:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f010201e:	72 12                	jb     f0102032 <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102020:	52                   	push   %edx
f0102021:	68 04 3b 10 f0       	push   $0xf0103b04
f0102026:	6a 52                	push   $0x52
f0102028:	68 64 42 10 f0       	push   $0xf0104264
f010202d:	e8 59 e0 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0102032:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102038:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010203b:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102041:	f6 00 01             	testb  $0x1,(%eax)
f0102044:	74 19                	je     f010205f <mem_init+0x1065>
f0102046:	68 f4 44 10 f0       	push   $0xf01044f4
f010204b:	68 7e 42 10 f0       	push   $0xf010427e
f0102050:	68 ae 03 00 00       	push   $0x3ae
f0102055:	68 58 42 10 f0       	push   $0xf0104258
f010205a:	e8 2c e0 ff ff       	call   f010008b <_panic>
f010205f:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102062:	39 d0                	cmp    %edx,%eax
f0102064:	75 db                	jne    f0102041 <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102066:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010206b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102071:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102074:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010207a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010207d:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f0102083:	83 ec 0c             	sub    $0xc,%esp
f0102086:	50                   	push   %eax
f0102087:	e8 30 ed ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f010208c:	89 1c 24             	mov    %ebx,(%esp)
f010208f:	e8 28 ed ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f0102094:	89 34 24             	mov    %esi,(%esp)
f0102097:	e8 20 ed ff ff       	call   f0100dbc <page_free>

	cprintf("check_page() succeeded!\n");
f010209c:	c7 04 24 0b 45 10 f0 	movl   $0xf010450b,(%esp)
f01020a3:	e8 d1 05 00 00       	call   f0102679 <cprintf>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01020a8:	8b 35 68 69 11 f0    	mov    0xf0116968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01020ae:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f01020b3:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01020b6:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01020bd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01020c2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01020c5:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020cb:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01020ce:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01020d1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01020d6:	eb 55                	jmp    f010212d <mem_init+0x1133>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01020d8:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01020de:	89 f0                	mov    %esi,%eax
f01020e0:	e8 59 e8 ff ff       	call   f010093e <check_va2pa>
f01020e5:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01020ec:	77 15                	ja     f0102103 <mem_init+0x1109>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020ee:	57                   	push   %edi
f01020ef:	68 48 3c 10 f0       	push   $0xf0103c48
f01020f4:	68 f0 02 00 00       	push   $0x2f0
f01020f9:	68 58 42 10 f0       	push   $0xf0104258
f01020fe:	e8 88 df ff ff       	call   f010008b <_panic>
f0102103:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f010210a:	39 d0                	cmp    %edx,%eax
f010210c:	74 19                	je     f0102127 <mem_init+0x112d>
f010210e:	68 c4 40 10 f0       	push   $0xf01040c4
f0102113:	68 7e 42 10 f0       	push   $0xf010427e
f0102118:	68 f0 02 00 00       	push   $0x2f0
f010211d:	68 58 42 10 f0       	push   $0xf0104258
f0102122:	e8 64 df ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102127:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010212d:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0102130:	77 a6                	ja     f01020d8 <mem_init+0x10de>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102132:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102135:	c1 e7 0c             	shl    $0xc,%edi
f0102138:	bb 00 00 00 00       	mov    $0x0,%ebx
f010213d:	eb 30                	jmp    f010216f <mem_init+0x1175>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010213f:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102145:	89 f0                	mov    %esi,%eax
f0102147:	e8 f2 e7 ff ff       	call   f010093e <check_va2pa>
f010214c:	39 c3                	cmp    %eax,%ebx
f010214e:	74 19                	je     f0102169 <mem_init+0x116f>
f0102150:	68 f8 40 10 f0       	push   $0xf01040f8
f0102155:	68 7e 42 10 f0       	push   $0xf010427e
f010215a:	68 f5 02 00 00       	push   $0x2f5
f010215f:	68 58 42 10 f0       	push   $0xf0104258
f0102164:	e8 22 df ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102169:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010216f:	39 fb                	cmp    %edi,%ebx
f0102171:	72 cc                	jb     f010213f <mem_init+0x1145>
f0102173:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102178:	bf 00 c0 10 f0       	mov    $0xf010c000,%edi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010217d:	89 da                	mov    %ebx,%edx
f010217f:	89 f0                	mov    %esi,%eax
f0102181:	e8 b8 e7 ff ff       	call   f010093e <check_va2pa>
f0102186:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f010218c:	77 19                	ja     f01021a7 <mem_init+0x11ad>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010218e:	68 00 c0 10 f0       	push   $0xf010c000
f0102193:	68 48 3c 10 f0       	push   $0xf0103c48
f0102198:	68 f9 02 00 00       	push   $0x2f9
f010219d:	68 58 42 10 f0       	push   $0xf0104258
f01021a2:	e8 e4 de ff ff       	call   f010008b <_panic>
f01021a7:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f01021ad:	39 d0                	cmp    %edx,%eax
f01021af:	74 19                	je     f01021ca <mem_init+0x11d0>
f01021b1:	68 20 41 10 f0       	push   $0xf0104120
f01021b6:	68 7e 42 10 f0       	push   $0xf010427e
f01021bb:	68 f9 02 00 00       	push   $0x2f9
f01021c0:	68 58 42 10 f0       	push   $0xf0104258
f01021c5:	e8 c1 de ff ff       	call   f010008b <_panic>
f01021ca:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01021d0:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01021d6:	75 a5                	jne    f010217d <mem_init+0x1183>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01021d8:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01021dd:	89 f0                	mov    %esi,%eax
f01021df:	e8 5a e7 ff ff       	call   f010093e <check_va2pa>
f01021e4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021e7:	74 51                	je     f010223a <mem_init+0x1240>
f01021e9:	68 68 41 10 f0       	push   $0xf0104168
f01021ee:	68 7e 42 10 f0       	push   $0xf010427e
f01021f3:	68 fa 02 00 00       	push   $0x2fa
f01021f8:	68 58 42 10 f0       	push   $0xf0104258
f01021fd:	e8 89 de ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102202:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102207:	72 36                	jb     f010223f <mem_init+0x1245>
f0102209:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010220e:	76 07                	jbe    f0102217 <mem_init+0x121d>
f0102210:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102215:	75 28                	jne    f010223f <mem_init+0x1245>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102217:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f010221b:	0f 85 83 00 00 00    	jne    f01022a4 <mem_init+0x12aa>
f0102221:	68 24 45 10 f0       	push   $0xf0104524
f0102226:	68 7e 42 10 f0       	push   $0xf010427e
f010222b:	68 02 03 00 00       	push   $0x302
f0102230:	68 58 42 10 f0       	push   $0xf0104258
f0102235:	e8 51 de ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010223a:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010223f:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102244:	76 3f                	jbe    f0102285 <mem_init+0x128b>
				assert(pgdir[i] & PTE_P);
f0102246:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102249:	f6 c2 01             	test   $0x1,%dl
f010224c:	75 19                	jne    f0102267 <mem_init+0x126d>
f010224e:	68 24 45 10 f0       	push   $0xf0104524
f0102253:	68 7e 42 10 f0       	push   $0xf010427e
f0102258:	68 06 03 00 00       	push   $0x306
f010225d:	68 58 42 10 f0       	push   $0xf0104258
f0102262:	e8 24 de ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102267:	f6 c2 02             	test   $0x2,%dl
f010226a:	75 38                	jne    f01022a4 <mem_init+0x12aa>
f010226c:	68 35 45 10 f0       	push   $0xf0104535
f0102271:	68 7e 42 10 f0       	push   $0xf010427e
f0102276:	68 07 03 00 00       	push   $0x307
f010227b:	68 58 42 10 f0       	push   $0xf0104258
f0102280:	e8 06 de ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102285:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102289:	74 19                	je     f01022a4 <mem_init+0x12aa>
f010228b:	68 46 45 10 f0       	push   $0xf0104546
f0102290:	68 7e 42 10 f0       	push   $0xf010427e
f0102295:	68 09 03 00 00       	push   $0x309
f010229a:	68 58 42 10 f0       	push   $0xf0104258
f010229f:	e8 e7 dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01022a4:	83 c0 01             	add    $0x1,%eax
f01022a7:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01022ac:	0f 86 50 ff ff ff    	jbe    f0102202 <mem_init+0x1208>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01022b2:	83 ec 0c             	sub    $0xc,%esp
f01022b5:	68 98 41 10 f0       	push   $0xf0104198
f01022ba:	e8 ba 03 00 00       	call   f0102679 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01022bf:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01022c4:	83 c4 10             	add    $0x10,%esp
f01022c7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01022cc:	77 15                	ja     f01022e3 <mem_init+0x12e9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01022ce:	50                   	push   %eax
f01022cf:	68 48 3c 10 f0       	push   $0xf0103c48
f01022d4:	68 cf 00 00 00       	push   $0xcf
f01022d9:	68 58 42 10 f0       	push   $0xf0104258
f01022de:	e8 a8 dd ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01022e3:	05 00 00 00 10       	add    $0x10000000,%eax
f01022e8:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01022eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01022f0:	e8 ad e6 ff ff       	call   f01009a2 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01022f5:	0f 20 c0             	mov    %cr0,%eax
f01022f8:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01022fb:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102300:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102303:	83 ec 0c             	sub    $0xc,%esp
f0102306:	6a 00                	push   $0x0
f0102308:	e8 29 ea ff ff       	call   f0100d36 <page_alloc>
f010230d:	89 c3                	mov    %eax,%ebx
f010230f:	83 c4 10             	add    $0x10,%esp
f0102312:	85 c0                	test   %eax,%eax
f0102314:	75 19                	jne    f010232f <mem_init+0x1335>
f0102316:	68 42 43 10 f0       	push   $0xf0104342
f010231b:	68 7e 42 10 f0       	push   $0xf010427e
f0102320:	68 c9 03 00 00       	push   $0x3c9
f0102325:	68 58 42 10 f0       	push   $0xf0104258
f010232a:	e8 5c dd ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010232f:	83 ec 0c             	sub    $0xc,%esp
f0102332:	6a 00                	push   $0x0
f0102334:	e8 fd e9 ff ff       	call   f0100d36 <page_alloc>
f0102339:	89 c7                	mov    %eax,%edi
f010233b:	83 c4 10             	add    $0x10,%esp
f010233e:	85 c0                	test   %eax,%eax
f0102340:	75 19                	jne    f010235b <mem_init+0x1361>
f0102342:	68 58 43 10 f0       	push   $0xf0104358
f0102347:	68 7e 42 10 f0       	push   $0xf010427e
f010234c:	68 ca 03 00 00       	push   $0x3ca
f0102351:	68 58 42 10 f0       	push   $0xf0104258
f0102356:	e8 30 dd ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010235b:	83 ec 0c             	sub    $0xc,%esp
f010235e:	6a 00                	push   $0x0
f0102360:	e8 d1 e9 ff ff       	call   f0100d36 <page_alloc>
f0102365:	89 c6                	mov    %eax,%esi
f0102367:	83 c4 10             	add    $0x10,%esp
f010236a:	85 c0                	test   %eax,%eax
f010236c:	75 19                	jne    f0102387 <mem_init+0x138d>
f010236e:	68 6e 43 10 f0       	push   $0xf010436e
f0102373:	68 7e 42 10 f0       	push   $0xf010427e
f0102378:	68 cb 03 00 00       	push   $0x3cb
f010237d:	68 58 42 10 f0       	push   $0xf0104258
f0102382:	e8 04 dd ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102387:	83 ec 0c             	sub    $0xc,%esp
f010238a:	53                   	push   %ebx
f010238b:	e8 2c ea ff ff       	call   f0100dbc <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102390:	89 f8                	mov    %edi,%eax
f0102392:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102398:	c1 f8 03             	sar    $0x3,%eax
f010239b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010239e:	89 c2                	mov    %eax,%edx
f01023a0:	c1 ea 0c             	shr    $0xc,%edx
f01023a3:	83 c4 10             	add    $0x10,%esp
f01023a6:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01023ac:	72 12                	jb     f01023c0 <mem_init+0x13c6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023ae:	50                   	push   %eax
f01023af:	68 04 3b 10 f0       	push   $0xf0103b04
f01023b4:	6a 52                	push   $0x52
f01023b6:	68 64 42 10 f0       	push   $0xf0104264
f01023bb:	e8 cb dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01023c0:	83 ec 04             	sub    $0x4,%esp
f01023c3:	68 00 10 00 00       	push   $0x1000
f01023c8:	6a 01                	push   $0x1
f01023ca:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01023cf:	50                   	push   %eax
f01023d0:	e8 58 0d 00 00       	call   f010312d <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01023d5:	89 f0                	mov    %esi,%eax
f01023d7:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01023dd:	c1 f8 03             	sar    $0x3,%eax
f01023e0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023e3:	89 c2                	mov    %eax,%edx
f01023e5:	c1 ea 0c             	shr    $0xc,%edx
f01023e8:	83 c4 10             	add    $0x10,%esp
f01023eb:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01023f1:	72 12                	jb     f0102405 <mem_init+0x140b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023f3:	50                   	push   %eax
f01023f4:	68 04 3b 10 f0       	push   $0xf0103b04
f01023f9:	6a 52                	push   $0x52
f01023fb:	68 64 42 10 f0       	push   $0xf0104264
f0102400:	e8 86 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102405:	83 ec 04             	sub    $0x4,%esp
f0102408:	68 00 10 00 00       	push   $0x1000
f010240d:	6a 02                	push   $0x2
f010240f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102414:	50                   	push   %eax
f0102415:	e8 13 0d 00 00       	call   f010312d <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010241a:	6a 02                	push   $0x2
f010241c:	68 00 10 00 00       	push   $0x1000
f0102421:	57                   	push   %edi
f0102422:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102428:	e8 34 eb ff ff       	call   f0100f61 <page_insert>
	assert(pp1->pp_ref == 1);
f010242d:	83 c4 20             	add    $0x20,%esp
f0102430:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102435:	74 19                	je     f0102450 <mem_init+0x1456>
f0102437:	68 3f 44 10 f0       	push   $0xf010443f
f010243c:	68 7e 42 10 f0       	push   $0xf010427e
f0102441:	68 d0 03 00 00       	push   $0x3d0
f0102446:	68 58 42 10 f0       	push   $0xf0104258
f010244b:	e8 3b dc ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102450:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102457:	01 01 01 
f010245a:	74 19                	je     f0102475 <mem_init+0x147b>
f010245c:	68 b8 41 10 f0       	push   $0xf01041b8
f0102461:	68 7e 42 10 f0       	push   $0xf010427e
f0102466:	68 d1 03 00 00       	push   $0x3d1
f010246b:	68 58 42 10 f0       	push   $0xf0104258
f0102470:	e8 16 dc ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102475:	6a 02                	push   $0x2
f0102477:	68 00 10 00 00       	push   $0x1000
f010247c:	56                   	push   %esi
f010247d:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102483:	e8 d9 ea ff ff       	call   f0100f61 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102488:	83 c4 10             	add    $0x10,%esp
f010248b:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102492:	02 02 02 
f0102495:	74 19                	je     f01024b0 <mem_init+0x14b6>
f0102497:	68 dc 41 10 f0       	push   $0xf01041dc
f010249c:	68 7e 42 10 f0       	push   $0xf010427e
f01024a1:	68 d3 03 00 00       	push   $0x3d3
f01024a6:	68 58 42 10 f0       	push   $0xf0104258
f01024ab:	e8 db db ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01024b0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01024b5:	74 19                	je     f01024d0 <mem_init+0x14d6>
f01024b7:	68 61 44 10 f0       	push   $0xf0104461
f01024bc:	68 7e 42 10 f0       	push   $0xf010427e
f01024c1:	68 d4 03 00 00       	push   $0x3d4
f01024c6:	68 58 42 10 f0       	push   $0xf0104258
f01024cb:	e8 bb db ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01024d0:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01024d5:	74 19                	je     f01024f0 <mem_init+0x14f6>
f01024d7:	68 cb 44 10 f0       	push   $0xf01044cb
f01024dc:	68 7e 42 10 f0       	push   $0xf010427e
f01024e1:	68 d5 03 00 00       	push   $0x3d5
f01024e6:	68 58 42 10 f0       	push   $0xf0104258
f01024eb:	e8 9b db ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01024f0:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01024f7:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024fa:	89 f0                	mov    %esi,%eax
f01024fc:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102502:	c1 f8 03             	sar    $0x3,%eax
f0102505:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102508:	89 c2                	mov    %eax,%edx
f010250a:	c1 ea 0c             	shr    $0xc,%edx
f010250d:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102513:	72 12                	jb     f0102527 <mem_init+0x152d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102515:	50                   	push   %eax
f0102516:	68 04 3b 10 f0       	push   $0xf0103b04
f010251b:	6a 52                	push   $0x52
f010251d:	68 64 42 10 f0       	push   $0xf0104264
f0102522:	e8 64 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102527:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010252e:	03 03 03 
f0102531:	74 19                	je     f010254c <mem_init+0x1552>
f0102533:	68 00 42 10 f0       	push   $0xf0104200
f0102538:	68 7e 42 10 f0       	push   $0xf010427e
f010253d:	68 d7 03 00 00       	push   $0x3d7
f0102542:	68 58 42 10 f0       	push   $0xf0104258
f0102547:	e8 3f db ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010254c:	83 ec 08             	sub    $0x8,%esp
f010254f:	68 00 10 00 00       	push   $0x1000
f0102554:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010255a:	e8 c7 e9 ff ff       	call   f0100f26 <page_remove>
	assert(pp2->pp_ref == 0);
f010255f:	83 c4 10             	add    $0x10,%esp
f0102562:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102567:	74 19                	je     f0102582 <mem_init+0x1588>
f0102569:	68 99 44 10 f0       	push   $0xf0104499
f010256e:	68 7e 42 10 f0       	push   $0xf010427e
f0102573:	68 d9 03 00 00       	push   $0x3d9
f0102578:	68 58 42 10 f0       	push   $0xf0104258
f010257d:	e8 09 db ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102582:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0102588:	8b 11                	mov    (%ecx),%edx
f010258a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102590:	89 d8                	mov    %ebx,%eax
f0102592:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102598:	c1 f8 03             	sar    $0x3,%eax
f010259b:	c1 e0 0c             	shl    $0xc,%eax
f010259e:	39 c2                	cmp    %eax,%edx
f01025a0:	74 19                	je     f01025bb <mem_init+0x15c1>
f01025a2:	68 44 3d 10 f0       	push   $0xf0103d44
f01025a7:	68 7e 42 10 f0       	push   $0xf010427e
f01025ac:	68 dc 03 00 00       	push   $0x3dc
f01025b1:	68 58 42 10 f0       	push   $0xf0104258
f01025b6:	e8 d0 da ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01025bb:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01025c1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01025c6:	74 19                	je     f01025e1 <mem_init+0x15e7>
f01025c8:	68 50 44 10 f0       	push   $0xf0104450
f01025cd:	68 7e 42 10 f0       	push   $0xf010427e
f01025d2:	68 de 03 00 00       	push   $0x3de
f01025d7:	68 58 42 10 f0       	push   $0xf0104258
f01025dc:	e8 aa da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01025e1:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01025e7:	83 ec 0c             	sub    $0xc,%esp
f01025ea:	53                   	push   %ebx
f01025eb:	e8 cc e7 ff ff       	call   f0100dbc <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01025f0:	c7 04 24 2c 42 10 f0 	movl   $0xf010422c,(%esp)
f01025f7:	e8 7d 00 00 00       	call   f0102679 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01025fc:	83 c4 10             	add    $0x10,%esp
f01025ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102602:	5b                   	pop    %ebx
f0102603:	5e                   	pop    %esi
f0102604:	5f                   	pop    %edi
f0102605:	5d                   	pop    %ebp
f0102606:	c3                   	ret    

f0102607 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102607:	55                   	push   %ebp
f0102608:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010260a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010260d:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102610:	5d                   	pop    %ebp
f0102611:	c3                   	ret    

f0102612 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102612:	55                   	push   %ebp
f0102613:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102615:	ba 70 00 00 00       	mov    $0x70,%edx
f010261a:	8b 45 08             	mov    0x8(%ebp),%eax
f010261d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010261e:	ba 71 00 00 00       	mov    $0x71,%edx
f0102623:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102624:	0f b6 c0             	movzbl %al,%eax
}
f0102627:	5d                   	pop    %ebp
f0102628:	c3                   	ret    

f0102629 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102629:	55                   	push   %ebp
f010262a:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010262c:	ba 70 00 00 00       	mov    $0x70,%edx
f0102631:	8b 45 08             	mov    0x8(%ebp),%eax
f0102634:	ee                   	out    %al,(%dx)
f0102635:	ba 71 00 00 00       	mov    $0x71,%edx
f010263a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010263d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010263e:	5d                   	pop    %ebp
f010263f:	c3                   	ret    

f0102640 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102640:	55                   	push   %ebp
f0102641:	89 e5                	mov    %esp,%ebp
f0102643:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102646:	ff 75 08             	pushl  0x8(%ebp)
f0102649:	e8 d7 df ff ff       	call   f0100625 <cputchar>
	*cnt++;
}
f010264e:	83 c4 10             	add    $0x10,%esp
f0102651:	c9                   	leave  
f0102652:	c3                   	ret    

f0102653 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102653:	55                   	push   %ebp
f0102654:	89 e5                	mov    %esp,%ebp
f0102656:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102659:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102660:	ff 75 0c             	pushl  0xc(%ebp)
f0102663:	ff 75 08             	pushl  0x8(%ebp)
f0102666:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102669:	50                   	push   %eax
f010266a:	68 40 26 10 f0       	push   $0xf0102640
f010266f:	e8 4d 04 00 00       	call   f0102ac1 <vprintfmt>
	return cnt;
}
f0102674:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102677:	c9                   	leave  
f0102678:	c3                   	ret    

f0102679 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102679:	55                   	push   %ebp
f010267a:	89 e5                	mov    %esp,%ebp
f010267c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010267f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102682:	50                   	push   %eax
f0102683:	ff 75 08             	pushl  0x8(%ebp)
f0102686:	e8 c8 ff ff ff       	call   f0102653 <vcprintf>
	va_end(ap);

	return cnt;
}
f010268b:	c9                   	leave  
f010268c:	c3                   	ret    

f010268d <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010268d:	55                   	push   %ebp
f010268e:	89 e5                	mov    %esp,%ebp
f0102690:	57                   	push   %edi
f0102691:	56                   	push   %esi
f0102692:	53                   	push   %ebx
f0102693:	83 ec 14             	sub    $0x14,%esp
f0102696:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102699:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010269c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010269f:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01026a2:	8b 1a                	mov    (%edx),%ebx
f01026a4:	8b 01                	mov    (%ecx),%eax
f01026a6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01026a9:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01026b0:	eb 7f                	jmp    f0102731 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01026b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01026b5:	01 d8                	add    %ebx,%eax
f01026b7:	89 c6                	mov    %eax,%esi
f01026b9:	c1 ee 1f             	shr    $0x1f,%esi
f01026bc:	01 c6                	add    %eax,%esi
f01026be:	d1 fe                	sar    %esi
f01026c0:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01026c3:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01026c6:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01026c9:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01026cb:	eb 03                	jmp    f01026d0 <stab_binsearch+0x43>
			m--;
f01026cd:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01026d0:	39 c3                	cmp    %eax,%ebx
f01026d2:	7f 0d                	jg     f01026e1 <stab_binsearch+0x54>
f01026d4:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01026d8:	83 ea 0c             	sub    $0xc,%edx
f01026db:	39 f9                	cmp    %edi,%ecx
f01026dd:	75 ee                	jne    f01026cd <stab_binsearch+0x40>
f01026df:	eb 05                	jmp    f01026e6 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01026e1:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01026e4:	eb 4b                	jmp    f0102731 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01026e6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01026e9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01026ec:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01026f0:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01026f3:	76 11                	jbe    f0102706 <stab_binsearch+0x79>
			*region_left = m;
f01026f5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01026f8:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01026fa:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01026fd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102704:	eb 2b                	jmp    f0102731 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102706:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102709:	73 14                	jae    f010271f <stab_binsearch+0x92>
			*region_right = m - 1;
f010270b:	83 e8 01             	sub    $0x1,%eax
f010270e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102711:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102714:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102716:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010271d:	eb 12                	jmp    f0102731 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010271f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102722:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102724:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102728:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010272a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102731:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102734:	0f 8e 78 ff ff ff    	jle    f01026b2 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010273a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010273e:	75 0f                	jne    f010274f <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0102740:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102743:	8b 00                	mov    (%eax),%eax
f0102745:	83 e8 01             	sub    $0x1,%eax
f0102748:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010274b:	89 06                	mov    %eax,(%esi)
f010274d:	eb 2c                	jmp    f010277b <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010274f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102752:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102754:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102757:	8b 0e                	mov    (%esi),%ecx
f0102759:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010275c:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010275f:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102762:	eb 03                	jmp    f0102767 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102764:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102767:	39 c8                	cmp    %ecx,%eax
f0102769:	7e 0b                	jle    f0102776 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010276b:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010276f:	83 ea 0c             	sub    $0xc,%edx
f0102772:	39 df                	cmp    %ebx,%edi
f0102774:	75 ee                	jne    f0102764 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102776:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102779:	89 06                	mov    %eax,(%esi)
	}
}
f010277b:	83 c4 14             	add    $0x14,%esp
f010277e:	5b                   	pop    %ebx
f010277f:	5e                   	pop    %esi
f0102780:	5f                   	pop    %edi
f0102781:	5d                   	pop    %ebp
f0102782:	c3                   	ret    

f0102783 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102783:	55                   	push   %ebp
f0102784:	89 e5                	mov    %esp,%ebp
f0102786:	57                   	push   %edi
f0102787:	56                   	push   %esi
f0102788:	53                   	push   %ebx
f0102789:	83 ec 2c             	sub    $0x2c,%esp
f010278c:	8b 7d 08             	mov    0x8(%ebp),%edi
f010278f:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102792:	c7 06 54 45 10 f0    	movl   $0xf0104554,(%esi)
	info->eip_line = 0;
f0102798:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010279f:	c7 46 08 54 45 10 f0 	movl   $0xf0104554,0x8(%esi)
	info->eip_fn_namelen = 9;
f01027a6:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01027ad:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01027b0:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01027b7:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01027bd:	76 11                	jbe    f01027d0 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01027bf:	b8 83 bc 10 f0       	mov    $0xf010bc83,%eax
f01027c4:	3d 1d 9f 10 f0       	cmp    $0xf0109f1d,%eax
f01027c9:	77 19                	ja     f01027e4 <debuginfo_eip+0x61>
f01027cb:	e9 a5 01 00 00       	jmp    f0102975 <debuginfo_eip+0x1f2>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01027d0:	83 ec 04             	sub    $0x4,%esp
f01027d3:	68 5e 45 10 f0       	push   $0xf010455e
f01027d8:	6a 7f                	push   $0x7f
f01027da:	68 6b 45 10 f0       	push   $0xf010456b
f01027df:	e8 a7 d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01027e4:	80 3d 82 bc 10 f0 00 	cmpb   $0x0,0xf010bc82
f01027eb:	0f 85 8b 01 00 00    	jne    f010297c <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01027f1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01027f8:	b8 1c 9f 10 f0       	mov    $0xf0109f1c,%eax
f01027fd:	2d b0 47 10 f0       	sub    $0xf01047b0,%eax
f0102802:	c1 f8 02             	sar    $0x2,%eax
f0102805:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010280b:	83 e8 01             	sub    $0x1,%eax
f010280e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102811:	83 ec 08             	sub    $0x8,%esp
f0102814:	57                   	push   %edi
f0102815:	6a 64                	push   $0x64
f0102817:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010281a:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010281d:	b8 b0 47 10 f0       	mov    $0xf01047b0,%eax
f0102822:	e8 66 fe ff ff       	call   f010268d <stab_binsearch>
	if (lfile == 0)
f0102827:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010282a:	83 c4 10             	add    $0x10,%esp
f010282d:	85 c0                	test   %eax,%eax
f010282f:	0f 84 4e 01 00 00    	je     f0102983 <debuginfo_eip+0x200>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102835:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102838:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010283b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010283e:	83 ec 08             	sub    $0x8,%esp
f0102841:	57                   	push   %edi
f0102842:	6a 24                	push   $0x24
f0102844:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102847:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010284a:	b8 b0 47 10 f0       	mov    $0xf01047b0,%eax
f010284f:	e8 39 fe ff ff       	call   f010268d <stab_binsearch>

	if (lfun <= rfun) {
f0102854:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102857:	83 c4 10             	add    $0x10,%esp
f010285a:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010285d:	7f 33                	jg     f0102892 <debuginfo_eip+0x10f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010285f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102862:	c1 e0 02             	shl    $0x2,%eax
f0102865:	8d 90 b0 47 10 f0    	lea    -0xfefb850(%eax),%edx
f010286b:	8b 88 b0 47 10 f0    	mov    -0xfefb850(%eax),%ecx
f0102871:	b8 83 bc 10 f0       	mov    $0xf010bc83,%eax
f0102876:	2d 1d 9f 10 f0       	sub    $0xf0109f1d,%eax
f010287b:	39 c1                	cmp    %eax,%ecx
f010287d:	73 09                	jae    f0102888 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010287f:	81 c1 1d 9f 10 f0    	add    $0xf0109f1d,%ecx
f0102885:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102888:	8b 42 08             	mov    0x8(%edx),%eax
f010288b:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f010288e:	29 c7                	sub    %eax,%edi
f0102890:	eb 06                	jmp    f0102898 <debuginfo_eip+0x115>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102892:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0102895:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102898:	83 ec 08             	sub    $0x8,%esp
f010289b:	6a 3a                	push   $0x3a
f010289d:	ff 76 08             	pushl  0x8(%esi)
f01028a0:	e8 6c 08 00 00       	call   f0103111 <strfind>
f01028a5:	2b 46 08             	sub    0x8(%esi),%eax
f01028a8:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
f01028ab:	83 c4 08             	add    $0x8,%esp
f01028ae:	2b 7e 10             	sub    0x10(%esi),%edi
f01028b1:	57                   	push   %edi
f01028b2:	6a 44                	push   $0x44
f01028b4:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01028b7:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01028ba:	b8 b0 47 10 f0       	mov    $0xf01047b0,%eax
f01028bf:	e8 c9 fd ff ff       	call   f010268d <stab_binsearch>
	if (lfun > rfun) 
f01028c4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01028c7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01028ca:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01028cd:	83 c4 10             	add    $0x10,%esp
f01028d0:	39 c8                	cmp    %ecx,%eax
f01028d2:	0f 8f b2 00 00 00    	jg     f010298a <debuginfo_eip+0x207>
       	  return -1;
        info->eip_line = stabs[lfun].n_desc;
f01028d8:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01028db:	8d 04 85 b0 47 10 f0 	lea    -0xfefb850(,%eax,4),%eax
f01028e2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01028e5:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f01028e9:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01028ec:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01028ef:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01028f2:	8d 04 85 b0 47 10 f0 	lea    -0xfefb850(,%eax,4),%eax
f01028f9:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01028fc:	eb 06                	jmp    f0102904 <debuginfo_eip+0x181>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01028fe:	83 eb 01             	sub    $0x1,%ebx
f0102901:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102904:	39 fb                	cmp    %edi,%ebx
f0102906:	7c 39                	jl     f0102941 <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f0102908:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f010290c:	80 fa 84             	cmp    $0x84,%dl
f010290f:	74 0b                	je     f010291c <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102911:	80 fa 64             	cmp    $0x64,%dl
f0102914:	75 e8                	jne    f01028fe <debuginfo_eip+0x17b>
f0102916:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f010291a:	74 e2                	je     f01028fe <debuginfo_eip+0x17b>
f010291c:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010291f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102922:	8b 14 85 b0 47 10 f0 	mov    -0xfefb850(,%eax,4),%edx
f0102929:	b8 83 bc 10 f0       	mov    $0xf010bc83,%eax
f010292e:	2d 1d 9f 10 f0       	sub    $0xf0109f1d,%eax
f0102933:	39 c2                	cmp    %eax,%edx
f0102935:	73 0d                	jae    f0102944 <debuginfo_eip+0x1c1>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102937:	81 c2 1d 9f 10 f0    	add    $0xf0109f1d,%edx
f010293d:	89 16                	mov    %edx,(%esi)
f010293f:	eb 03                	jmp    f0102944 <debuginfo_eip+0x1c1>
f0102941:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102944:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102949:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010294c:	39 cf                	cmp    %ecx,%edi
f010294e:	7d 46                	jge    f0102996 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
f0102950:	89 f8                	mov    %edi,%eax
f0102952:	83 c0 01             	add    $0x1,%eax
f0102955:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0102958:	eb 07                	jmp    f0102961 <debuginfo_eip+0x1de>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010295a:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f010295e:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102961:	39 c8                	cmp    %ecx,%eax
f0102963:	74 2c                	je     f0102991 <debuginfo_eip+0x20e>
f0102965:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102968:	80 7a 04 a0          	cmpb   $0xa0,0x4(%edx)
f010296c:	74 ec                	je     f010295a <debuginfo_eip+0x1d7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010296e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102973:	eb 21                	jmp    f0102996 <debuginfo_eip+0x213>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102975:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010297a:	eb 1a                	jmp    f0102996 <debuginfo_eip+0x213>
f010297c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102981:	eb 13                	jmp    f0102996 <debuginfo_eip+0x213>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102983:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102988:	eb 0c                	jmp    f0102996 <debuginfo_eip+0x213>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
	if (lfun > rfun) 
       	  return -1;
f010298a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010298f:	eb 05                	jmp    f0102996 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102991:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102996:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102999:	5b                   	pop    %ebx
f010299a:	5e                   	pop    %esi
f010299b:	5f                   	pop    %edi
f010299c:	5d                   	pop    %ebp
f010299d:	c3                   	ret    

f010299e <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010299e:	55                   	push   %ebp
f010299f:	89 e5                	mov    %esp,%ebp
f01029a1:	57                   	push   %edi
f01029a2:	56                   	push   %esi
f01029a3:	53                   	push   %ebx
f01029a4:	83 ec 1c             	sub    $0x1c,%esp
f01029a7:	89 c7                	mov    %eax,%edi
f01029a9:	89 d6                	mov    %edx,%esi
f01029ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01029ae:	8b 55 0c             	mov    0xc(%ebp),%edx
f01029b1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01029b4:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01029b7:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01029ba:	bb 00 00 00 00       	mov    $0x0,%ebx
f01029bf:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01029c2:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01029c5:	39 d3                	cmp    %edx,%ebx
f01029c7:	72 05                	jb     f01029ce <printnum+0x30>
f01029c9:	39 45 10             	cmp    %eax,0x10(%ebp)
f01029cc:	77 45                	ja     f0102a13 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01029ce:	83 ec 0c             	sub    $0xc,%esp
f01029d1:	ff 75 18             	pushl  0x18(%ebp)
f01029d4:	8b 45 14             	mov    0x14(%ebp),%eax
f01029d7:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01029da:	53                   	push   %ebx
f01029db:	ff 75 10             	pushl  0x10(%ebp)
f01029de:	83 ec 08             	sub    $0x8,%esp
f01029e1:	ff 75 e4             	pushl  -0x1c(%ebp)
f01029e4:	ff 75 e0             	pushl  -0x20(%ebp)
f01029e7:	ff 75 dc             	pushl  -0x24(%ebp)
f01029ea:	ff 75 d8             	pushl  -0x28(%ebp)
f01029ed:	e8 3e 09 00 00       	call   f0103330 <__udivdi3>
f01029f2:	83 c4 18             	add    $0x18,%esp
f01029f5:	52                   	push   %edx
f01029f6:	50                   	push   %eax
f01029f7:	89 f2                	mov    %esi,%edx
f01029f9:	89 f8                	mov    %edi,%eax
f01029fb:	e8 9e ff ff ff       	call   f010299e <printnum>
f0102a00:	83 c4 20             	add    $0x20,%esp
f0102a03:	eb 18                	jmp    f0102a1d <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102a05:	83 ec 08             	sub    $0x8,%esp
f0102a08:	56                   	push   %esi
f0102a09:	ff 75 18             	pushl  0x18(%ebp)
f0102a0c:	ff d7                	call   *%edi
f0102a0e:	83 c4 10             	add    $0x10,%esp
f0102a11:	eb 03                	jmp    f0102a16 <printnum+0x78>
f0102a13:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102a16:	83 eb 01             	sub    $0x1,%ebx
f0102a19:	85 db                	test   %ebx,%ebx
f0102a1b:	7f e8                	jg     f0102a05 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102a1d:	83 ec 08             	sub    $0x8,%esp
f0102a20:	56                   	push   %esi
f0102a21:	83 ec 04             	sub    $0x4,%esp
f0102a24:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a27:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a2a:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a2d:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a30:	e8 2b 0a 00 00       	call   f0103460 <__umoddi3>
f0102a35:	83 c4 14             	add    $0x14,%esp
f0102a38:	0f be 80 79 45 10 f0 	movsbl -0xfefba87(%eax),%eax
f0102a3f:	50                   	push   %eax
f0102a40:	ff d7                	call   *%edi
}
f0102a42:	83 c4 10             	add    $0x10,%esp
f0102a45:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a48:	5b                   	pop    %ebx
f0102a49:	5e                   	pop    %esi
f0102a4a:	5f                   	pop    %edi
f0102a4b:	5d                   	pop    %ebp
f0102a4c:	c3                   	ret    

f0102a4d <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102a4d:	55                   	push   %ebp
f0102a4e:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102a50:	83 fa 01             	cmp    $0x1,%edx
f0102a53:	7e 0e                	jle    f0102a63 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102a55:	8b 10                	mov    (%eax),%edx
f0102a57:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102a5a:	89 08                	mov    %ecx,(%eax)
f0102a5c:	8b 02                	mov    (%edx),%eax
f0102a5e:	8b 52 04             	mov    0x4(%edx),%edx
f0102a61:	eb 22                	jmp    f0102a85 <getuint+0x38>
	else if (lflag)
f0102a63:	85 d2                	test   %edx,%edx
f0102a65:	74 10                	je     f0102a77 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102a67:	8b 10                	mov    (%eax),%edx
f0102a69:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102a6c:	89 08                	mov    %ecx,(%eax)
f0102a6e:	8b 02                	mov    (%edx),%eax
f0102a70:	ba 00 00 00 00       	mov    $0x0,%edx
f0102a75:	eb 0e                	jmp    f0102a85 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102a77:	8b 10                	mov    (%eax),%edx
f0102a79:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102a7c:	89 08                	mov    %ecx,(%eax)
f0102a7e:	8b 02                	mov    (%edx),%eax
f0102a80:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102a85:	5d                   	pop    %ebp
f0102a86:	c3                   	ret    

f0102a87 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102a87:	55                   	push   %ebp
f0102a88:	89 e5                	mov    %esp,%ebp
f0102a8a:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102a8d:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102a91:	8b 10                	mov    (%eax),%edx
f0102a93:	3b 50 04             	cmp    0x4(%eax),%edx
f0102a96:	73 0a                	jae    f0102aa2 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102a98:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102a9b:	89 08                	mov    %ecx,(%eax)
f0102a9d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102aa0:	88 02                	mov    %al,(%edx)
}
f0102aa2:	5d                   	pop    %ebp
f0102aa3:	c3                   	ret    

f0102aa4 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102aa4:	55                   	push   %ebp
f0102aa5:	89 e5                	mov    %esp,%ebp
f0102aa7:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102aaa:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102aad:	50                   	push   %eax
f0102aae:	ff 75 10             	pushl  0x10(%ebp)
f0102ab1:	ff 75 0c             	pushl  0xc(%ebp)
f0102ab4:	ff 75 08             	pushl  0x8(%ebp)
f0102ab7:	e8 05 00 00 00       	call   f0102ac1 <vprintfmt>
	va_end(ap);
}
f0102abc:	83 c4 10             	add    $0x10,%esp
f0102abf:	c9                   	leave  
f0102ac0:	c3                   	ret    

f0102ac1 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102ac1:	55                   	push   %ebp
f0102ac2:	89 e5                	mov    %esp,%ebp
f0102ac4:	57                   	push   %edi
f0102ac5:	56                   	push   %esi
f0102ac6:	53                   	push   %ebx
f0102ac7:	83 ec 2c             	sub    $0x2c,%esp
f0102aca:	8b 75 08             	mov    0x8(%ebp),%esi
f0102acd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ad0:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102ad3:	eb 12                	jmp    f0102ae7 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102ad5:	85 c0                	test   %eax,%eax
f0102ad7:	0f 84 89 03 00 00    	je     f0102e66 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102add:	83 ec 08             	sub    $0x8,%esp
f0102ae0:	53                   	push   %ebx
f0102ae1:	50                   	push   %eax
f0102ae2:	ff d6                	call   *%esi
f0102ae4:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102ae7:	83 c7 01             	add    $0x1,%edi
f0102aea:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102aee:	83 f8 25             	cmp    $0x25,%eax
f0102af1:	75 e2                	jne    f0102ad5 <vprintfmt+0x14>
f0102af3:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102af7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102afe:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b05:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102b0c:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b11:	eb 07                	jmp    f0102b1a <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b13:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102b16:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b1a:	8d 47 01             	lea    0x1(%edi),%eax
f0102b1d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102b20:	0f b6 07             	movzbl (%edi),%eax
f0102b23:	0f b6 c8             	movzbl %al,%ecx
f0102b26:	83 e8 23             	sub    $0x23,%eax
f0102b29:	3c 55                	cmp    $0x55,%al
f0102b2b:	0f 87 1a 03 00 00    	ja     f0102e4b <vprintfmt+0x38a>
f0102b31:	0f b6 c0             	movzbl %al,%eax
f0102b34:	ff 24 85 20 46 10 f0 	jmp    *-0xfefb9e0(,%eax,4)
f0102b3b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102b3e:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102b42:	eb d6                	jmp    f0102b1a <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b44:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b47:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b4c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102b4f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102b52:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102b56:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102b59:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102b5c:	83 fa 09             	cmp    $0x9,%edx
f0102b5f:	77 39                	ja     f0102b9a <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102b61:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102b64:	eb e9                	jmp    f0102b4f <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102b66:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b69:	8d 48 04             	lea    0x4(%eax),%ecx
f0102b6c:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102b6f:	8b 00                	mov    (%eax),%eax
f0102b71:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b74:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102b77:	eb 27                	jmp    f0102ba0 <vprintfmt+0xdf>
f0102b79:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102b7c:	85 c0                	test   %eax,%eax
f0102b7e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102b83:	0f 49 c8             	cmovns %eax,%ecx
f0102b86:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b89:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b8c:	eb 8c                	jmp    f0102b1a <vprintfmt+0x59>
f0102b8e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102b91:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102b98:	eb 80                	jmp    f0102b1a <vprintfmt+0x59>
f0102b9a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102b9d:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102ba0:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102ba4:	0f 89 70 ff ff ff    	jns    f0102b1a <vprintfmt+0x59>
				width = precision, precision = -1;
f0102baa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102bad:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102bb0:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102bb7:	e9 5e ff ff ff       	jmp    f0102b1a <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102bbc:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bbf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102bc2:	e9 53 ff ff ff       	jmp    f0102b1a <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102bc7:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bca:	8d 50 04             	lea    0x4(%eax),%edx
f0102bcd:	89 55 14             	mov    %edx,0x14(%ebp)
f0102bd0:	83 ec 08             	sub    $0x8,%esp
f0102bd3:	53                   	push   %ebx
f0102bd4:	ff 30                	pushl  (%eax)
f0102bd6:	ff d6                	call   *%esi
			break;
f0102bd8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bdb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102bde:	e9 04 ff ff ff       	jmp    f0102ae7 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102be3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102be6:	8d 50 04             	lea    0x4(%eax),%edx
f0102be9:	89 55 14             	mov    %edx,0x14(%ebp)
f0102bec:	8b 00                	mov    (%eax),%eax
f0102bee:	99                   	cltd   
f0102bef:	31 d0                	xor    %edx,%eax
f0102bf1:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102bf3:	83 f8 07             	cmp    $0x7,%eax
f0102bf6:	7f 0b                	jg     f0102c03 <vprintfmt+0x142>
f0102bf8:	8b 14 85 80 47 10 f0 	mov    -0xfefb880(,%eax,4),%edx
f0102bff:	85 d2                	test   %edx,%edx
f0102c01:	75 18                	jne    f0102c1b <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102c03:	50                   	push   %eax
f0102c04:	68 91 45 10 f0       	push   $0xf0104591
f0102c09:	53                   	push   %ebx
f0102c0a:	56                   	push   %esi
f0102c0b:	e8 94 fe ff ff       	call   f0102aa4 <printfmt>
f0102c10:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c13:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102c16:	e9 cc fe ff ff       	jmp    f0102ae7 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102c1b:	52                   	push   %edx
f0102c1c:	68 90 42 10 f0       	push   $0xf0104290
f0102c21:	53                   	push   %ebx
f0102c22:	56                   	push   %esi
f0102c23:	e8 7c fe ff ff       	call   f0102aa4 <printfmt>
f0102c28:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c2b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c2e:	e9 b4 fe ff ff       	jmp    f0102ae7 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102c33:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c36:	8d 50 04             	lea    0x4(%eax),%edx
f0102c39:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c3c:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102c3e:	85 ff                	test   %edi,%edi
f0102c40:	b8 8a 45 10 f0       	mov    $0xf010458a,%eax
f0102c45:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102c48:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c4c:	0f 8e 94 00 00 00    	jle    f0102ce6 <vprintfmt+0x225>
f0102c52:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102c56:	0f 84 98 00 00 00    	je     f0102cf4 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c5c:	83 ec 08             	sub    $0x8,%esp
f0102c5f:	ff 75 d0             	pushl  -0x30(%ebp)
f0102c62:	57                   	push   %edi
f0102c63:	e8 5f 03 00 00       	call   f0102fc7 <strnlen>
f0102c68:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102c6b:	29 c1                	sub    %eax,%ecx
f0102c6d:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102c70:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102c73:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102c77:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c7a:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102c7d:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c7f:	eb 0f                	jmp    f0102c90 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102c81:	83 ec 08             	sub    $0x8,%esp
f0102c84:	53                   	push   %ebx
f0102c85:	ff 75 e0             	pushl  -0x20(%ebp)
f0102c88:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c8a:	83 ef 01             	sub    $0x1,%edi
f0102c8d:	83 c4 10             	add    $0x10,%esp
f0102c90:	85 ff                	test   %edi,%edi
f0102c92:	7f ed                	jg     f0102c81 <vprintfmt+0x1c0>
f0102c94:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c97:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102c9a:	85 c9                	test   %ecx,%ecx
f0102c9c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ca1:	0f 49 c1             	cmovns %ecx,%eax
f0102ca4:	29 c1                	sub    %eax,%ecx
f0102ca6:	89 75 08             	mov    %esi,0x8(%ebp)
f0102ca9:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102cac:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102caf:	89 cb                	mov    %ecx,%ebx
f0102cb1:	eb 4d                	jmp    f0102d00 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102cb3:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102cb7:	74 1b                	je     f0102cd4 <vprintfmt+0x213>
f0102cb9:	0f be c0             	movsbl %al,%eax
f0102cbc:	83 e8 20             	sub    $0x20,%eax
f0102cbf:	83 f8 5e             	cmp    $0x5e,%eax
f0102cc2:	76 10                	jbe    f0102cd4 <vprintfmt+0x213>
					putch('?', putdat);
f0102cc4:	83 ec 08             	sub    $0x8,%esp
f0102cc7:	ff 75 0c             	pushl  0xc(%ebp)
f0102cca:	6a 3f                	push   $0x3f
f0102ccc:	ff 55 08             	call   *0x8(%ebp)
f0102ccf:	83 c4 10             	add    $0x10,%esp
f0102cd2:	eb 0d                	jmp    f0102ce1 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102cd4:	83 ec 08             	sub    $0x8,%esp
f0102cd7:	ff 75 0c             	pushl  0xc(%ebp)
f0102cda:	52                   	push   %edx
f0102cdb:	ff 55 08             	call   *0x8(%ebp)
f0102cde:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102ce1:	83 eb 01             	sub    $0x1,%ebx
f0102ce4:	eb 1a                	jmp    f0102d00 <vprintfmt+0x23f>
f0102ce6:	89 75 08             	mov    %esi,0x8(%ebp)
f0102ce9:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102cec:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102cef:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102cf2:	eb 0c                	jmp    f0102d00 <vprintfmt+0x23f>
f0102cf4:	89 75 08             	mov    %esi,0x8(%ebp)
f0102cf7:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102cfa:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102cfd:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d00:	83 c7 01             	add    $0x1,%edi
f0102d03:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102d07:	0f be d0             	movsbl %al,%edx
f0102d0a:	85 d2                	test   %edx,%edx
f0102d0c:	74 23                	je     f0102d31 <vprintfmt+0x270>
f0102d0e:	85 f6                	test   %esi,%esi
f0102d10:	78 a1                	js     f0102cb3 <vprintfmt+0x1f2>
f0102d12:	83 ee 01             	sub    $0x1,%esi
f0102d15:	79 9c                	jns    f0102cb3 <vprintfmt+0x1f2>
f0102d17:	89 df                	mov    %ebx,%edi
f0102d19:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d1c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d1f:	eb 18                	jmp    f0102d39 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102d21:	83 ec 08             	sub    $0x8,%esp
f0102d24:	53                   	push   %ebx
f0102d25:	6a 20                	push   $0x20
f0102d27:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102d29:	83 ef 01             	sub    $0x1,%edi
f0102d2c:	83 c4 10             	add    $0x10,%esp
f0102d2f:	eb 08                	jmp    f0102d39 <vprintfmt+0x278>
f0102d31:	89 df                	mov    %ebx,%edi
f0102d33:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d36:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d39:	85 ff                	test   %edi,%edi
f0102d3b:	7f e4                	jg     f0102d21 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d40:	e9 a2 fd ff ff       	jmp    f0102ae7 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102d45:	83 fa 01             	cmp    $0x1,%edx
f0102d48:	7e 16                	jle    f0102d60 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102d4a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d4d:	8d 50 08             	lea    0x8(%eax),%edx
f0102d50:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d53:	8b 50 04             	mov    0x4(%eax),%edx
f0102d56:	8b 00                	mov    (%eax),%eax
f0102d58:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d5b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102d5e:	eb 32                	jmp    f0102d92 <vprintfmt+0x2d1>
	else if (lflag)
f0102d60:	85 d2                	test   %edx,%edx
f0102d62:	74 18                	je     f0102d7c <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102d64:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d67:	8d 50 04             	lea    0x4(%eax),%edx
f0102d6a:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d6d:	8b 00                	mov    (%eax),%eax
f0102d6f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d72:	89 c1                	mov    %eax,%ecx
f0102d74:	c1 f9 1f             	sar    $0x1f,%ecx
f0102d77:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102d7a:	eb 16                	jmp    f0102d92 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102d7c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d7f:	8d 50 04             	lea    0x4(%eax),%edx
f0102d82:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d85:	8b 00                	mov    (%eax),%eax
f0102d87:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d8a:	89 c1                	mov    %eax,%ecx
f0102d8c:	c1 f9 1f             	sar    $0x1f,%ecx
f0102d8f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102d92:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102d95:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102d98:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102d9d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102da1:	79 74                	jns    f0102e17 <vprintfmt+0x356>
				putch('-', putdat);
f0102da3:	83 ec 08             	sub    $0x8,%esp
f0102da6:	53                   	push   %ebx
f0102da7:	6a 2d                	push   $0x2d
f0102da9:	ff d6                	call   *%esi
				num = -(long long) num;
f0102dab:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102dae:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102db1:	f7 d8                	neg    %eax
f0102db3:	83 d2 00             	adc    $0x0,%edx
f0102db6:	f7 da                	neg    %edx
f0102db8:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102dbb:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102dc0:	eb 55                	jmp    f0102e17 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102dc2:	8d 45 14             	lea    0x14(%ebp),%eax
f0102dc5:	e8 83 fc ff ff       	call   f0102a4d <getuint>
			base = 10;
f0102dca:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102dcf:	eb 46                	jmp    f0102e17 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0102dd1:	8d 45 14             	lea    0x14(%ebp),%eax
f0102dd4:	e8 74 fc ff ff       	call   f0102a4d <getuint>
			base = 8;
f0102dd9:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102dde:	eb 37                	jmp    f0102e17 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0102de0:	83 ec 08             	sub    $0x8,%esp
f0102de3:	53                   	push   %ebx
f0102de4:	6a 30                	push   $0x30
f0102de6:	ff d6                	call   *%esi
			putch('x', putdat);
f0102de8:	83 c4 08             	add    $0x8,%esp
f0102deb:	53                   	push   %ebx
f0102dec:	6a 78                	push   $0x78
f0102dee:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102df0:	8b 45 14             	mov    0x14(%ebp),%eax
f0102df3:	8d 50 04             	lea    0x4(%eax),%edx
f0102df6:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102df9:	8b 00                	mov    (%eax),%eax
f0102dfb:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102e00:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102e03:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102e08:	eb 0d                	jmp    f0102e17 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102e0a:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e0d:	e8 3b fc ff ff       	call   f0102a4d <getuint>
			base = 16;
f0102e12:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102e17:	83 ec 0c             	sub    $0xc,%esp
f0102e1a:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102e1e:	57                   	push   %edi
f0102e1f:	ff 75 e0             	pushl  -0x20(%ebp)
f0102e22:	51                   	push   %ecx
f0102e23:	52                   	push   %edx
f0102e24:	50                   	push   %eax
f0102e25:	89 da                	mov    %ebx,%edx
f0102e27:	89 f0                	mov    %esi,%eax
f0102e29:	e8 70 fb ff ff       	call   f010299e <printnum>
			break;
f0102e2e:	83 c4 20             	add    $0x20,%esp
f0102e31:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e34:	e9 ae fc ff ff       	jmp    f0102ae7 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102e39:	83 ec 08             	sub    $0x8,%esp
f0102e3c:	53                   	push   %ebx
f0102e3d:	51                   	push   %ecx
f0102e3e:	ff d6                	call   *%esi
			break;
f0102e40:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e43:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102e46:	e9 9c fc ff ff       	jmp    f0102ae7 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102e4b:	83 ec 08             	sub    $0x8,%esp
f0102e4e:	53                   	push   %ebx
f0102e4f:	6a 25                	push   $0x25
f0102e51:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102e53:	83 c4 10             	add    $0x10,%esp
f0102e56:	eb 03                	jmp    f0102e5b <vprintfmt+0x39a>
f0102e58:	83 ef 01             	sub    $0x1,%edi
f0102e5b:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102e5f:	75 f7                	jne    f0102e58 <vprintfmt+0x397>
f0102e61:	e9 81 fc ff ff       	jmp    f0102ae7 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102e66:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e69:	5b                   	pop    %ebx
f0102e6a:	5e                   	pop    %esi
f0102e6b:	5f                   	pop    %edi
f0102e6c:	5d                   	pop    %ebp
f0102e6d:	c3                   	ret    

f0102e6e <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102e6e:	55                   	push   %ebp
f0102e6f:	89 e5                	mov    %esp,%ebp
f0102e71:	83 ec 18             	sub    $0x18,%esp
f0102e74:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e77:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102e7a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102e7d:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102e81:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102e84:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102e8b:	85 c0                	test   %eax,%eax
f0102e8d:	74 26                	je     f0102eb5 <vsnprintf+0x47>
f0102e8f:	85 d2                	test   %edx,%edx
f0102e91:	7e 22                	jle    f0102eb5 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102e93:	ff 75 14             	pushl  0x14(%ebp)
f0102e96:	ff 75 10             	pushl  0x10(%ebp)
f0102e99:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102e9c:	50                   	push   %eax
f0102e9d:	68 87 2a 10 f0       	push   $0xf0102a87
f0102ea2:	e8 1a fc ff ff       	call   f0102ac1 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102ea7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102eaa:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102ead:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102eb0:	83 c4 10             	add    $0x10,%esp
f0102eb3:	eb 05                	jmp    f0102eba <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102eb5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102eba:	c9                   	leave  
f0102ebb:	c3                   	ret    

f0102ebc <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102ebc:	55                   	push   %ebp
f0102ebd:	89 e5                	mov    %esp,%ebp
f0102ebf:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102ec2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102ec5:	50                   	push   %eax
f0102ec6:	ff 75 10             	pushl  0x10(%ebp)
f0102ec9:	ff 75 0c             	pushl  0xc(%ebp)
f0102ecc:	ff 75 08             	pushl  0x8(%ebp)
f0102ecf:	e8 9a ff ff ff       	call   f0102e6e <vsnprintf>
	va_end(ap);

	return rc;
}
f0102ed4:	c9                   	leave  
f0102ed5:	c3                   	ret    

f0102ed6 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102ed6:	55                   	push   %ebp
f0102ed7:	89 e5                	mov    %esp,%ebp
f0102ed9:	57                   	push   %edi
f0102eda:	56                   	push   %esi
f0102edb:	53                   	push   %ebx
f0102edc:	83 ec 0c             	sub    $0xc,%esp
f0102edf:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102ee2:	85 c0                	test   %eax,%eax
f0102ee4:	74 11                	je     f0102ef7 <readline+0x21>
		cprintf("%s", prompt);
f0102ee6:	83 ec 08             	sub    $0x8,%esp
f0102ee9:	50                   	push   %eax
f0102eea:	68 90 42 10 f0       	push   $0xf0104290
f0102eef:	e8 85 f7 ff ff       	call   f0102679 <cprintf>
f0102ef4:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102ef7:	83 ec 0c             	sub    $0xc,%esp
f0102efa:	6a 00                	push   $0x0
f0102efc:	e8 45 d7 ff ff       	call   f0100646 <iscons>
f0102f01:	89 c7                	mov    %eax,%edi
f0102f03:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102f06:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102f0b:	e8 25 d7 ff ff       	call   f0100635 <getchar>
f0102f10:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102f12:	85 c0                	test   %eax,%eax
f0102f14:	79 18                	jns    f0102f2e <readline+0x58>
			cprintf("read error: %e\n", c);
f0102f16:	83 ec 08             	sub    $0x8,%esp
f0102f19:	50                   	push   %eax
f0102f1a:	68 a0 47 10 f0       	push   $0xf01047a0
f0102f1f:	e8 55 f7 ff ff       	call   f0102679 <cprintf>
			return NULL;
f0102f24:	83 c4 10             	add    $0x10,%esp
f0102f27:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f2c:	eb 79                	jmp    f0102fa7 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102f2e:	83 f8 08             	cmp    $0x8,%eax
f0102f31:	0f 94 c2             	sete   %dl
f0102f34:	83 f8 7f             	cmp    $0x7f,%eax
f0102f37:	0f 94 c0             	sete   %al
f0102f3a:	08 c2                	or     %al,%dl
f0102f3c:	74 1a                	je     f0102f58 <readline+0x82>
f0102f3e:	85 f6                	test   %esi,%esi
f0102f40:	7e 16                	jle    f0102f58 <readline+0x82>
			if (echoing)
f0102f42:	85 ff                	test   %edi,%edi
f0102f44:	74 0d                	je     f0102f53 <readline+0x7d>
				cputchar('\b');
f0102f46:	83 ec 0c             	sub    $0xc,%esp
f0102f49:	6a 08                	push   $0x8
f0102f4b:	e8 d5 d6 ff ff       	call   f0100625 <cputchar>
f0102f50:	83 c4 10             	add    $0x10,%esp
			i--;
f0102f53:	83 ee 01             	sub    $0x1,%esi
f0102f56:	eb b3                	jmp    f0102f0b <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102f58:	83 fb 1f             	cmp    $0x1f,%ebx
f0102f5b:	7e 23                	jle    f0102f80 <readline+0xaa>
f0102f5d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102f63:	7f 1b                	jg     f0102f80 <readline+0xaa>
			if (echoing)
f0102f65:	85 ff                	test   %edi,%edi
f0102f67:	74 0c                	je     f0102f75 <readline+0x9f>
				cputchar(c);
f0102f69:	83 ec 0c             	sub    $0xc,%esp
f0102f6c:	53                   	push   %ebx
f0102f6d:	e8 b3 d6 ff ff       	call   f0100625 <cputchar>
f0102f72:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0102f75:	88 9e 60 65 11 f0    	mov    %bl,-0xfee9aa0(%esi)
f0102f7b:	8d 76 01             	lea    0x1(%esi),%esi
f0102f7e:	eb 8b                	jmp    f0102f0b <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0102f80:	83 fb 0a             	cmp    $0xa,%ebx
f0102f83:	74 05                	je     f0102f8a <readline+0xb4>
f0102f85:	83 fb 0d             	cmp    $0xd,%ebx
f0102f88:	75 81                	jne    f0102f0b <readline+0x35>
			if (echoing)
f0102f8a:	85 ff                	test   %edi,%edi
f0102f8c:	74 0d                	je     f0102f9b <readline+0xc5>
				cputchar('\n');
f0102f8e:	83 ec 0c             	sub    $0xc,%esp
f0102f91:	6a 0a                	push   $0xa
f0102f93:	e8 8d d6 ff ff       	call   f0100625 <cputchar>
f0102f98:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0102f9b:	c6 86 60 65 11 f0 00 	movb   $0x0,-0xfee9aa0(%esi)
			return buf;
f0102fa2:	b8 60 65 11 f0       	mov    $0xf0116560,%eax
		}
	}
}
f0102fa7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102faa:	5b                   	pop    %ebx
f0102fab:	5e                   	pop    %esi
f0102fac:	5f                   	pop    %edi
f0102fad:	5d                   	pop    %ebp
f0102fae:	c3                   	ret    

f0102faf <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0102faf:	55                   	push   %ebp
f0102fb0:	89 e5                	mov    %esp,%ebp
f0102fb2:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102fb5:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fba:	eb 03                	jmp    f0102fbf <strlen+0x10>
		n++;
f0102fbc:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0102fbf:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0102fc3:	75 f7                	jne    f0102fbc <strlen+0xd>
		n++;
	return n;
}
f0102fc5:	5d                   	pop    %ebp
f0102fc6:	c3                   	ret    

f0102fc7 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102fc7:	55                   	push   %ebp
f0102fc8:	89 e5                	mov    %esp,%ebp
f0102fca:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102fcd:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102fd0:	ba 00 00 00 00       	mov    $0x0,%edx
f0102fd5:	eb 03                	jmp    f0102fda <strnlen+0x13>
		n++;
f0102fd7:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102fda:	39 c2                	cmp    %eax,%edx
f0102fdc:	74 08                	je     f0102fe6 <strnlen+0x1f>
f0102fde:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0102fe2:	75 f3                	jne    f0102fd7 <strnlen+0x10>
f0102fe4:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0102fe6:	5d                   	pop    %ebp
f0102fe7:	c3                   	ret    

f0102fe8 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102fe8:	55                   	push   %ebp
f0102fe9:	89 e5                	mov    %esp,%ebp
f0102feb:	53                   	push   %ebx
f0102fec:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fef:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0102ff2:	89 c2                	mov    %eax,%edx
f0102ff4:	83 c2 01             	add    $0x1,%edx
f0102ff7:	83 c1 01             	add    $0x1,%ecx
f0102ffa:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0102ffe:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103001:	84 db                	test   %bl,%bl
f0103003:	75 ef                	jne    f0102ff4 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103005:	5b                   	pop    %ebx
f0103006:	5d                   	pop    %ebp
f0103007:	c3                   	ret    

f0103008 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103008:	55                   	push   %ebp
f0103009:	89 e5                	mov    %esp,%ebp
f010300b:	53                   	push   %ebx
f010300c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010300f:	53                   	push   %ebx
f0103010:	e8 9a ff ff ff       	call   f0102faf <strlen>
f0103015:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103018:	ff 75 0c             	pushl  0xc(%ebp)
f010301b:	01 d8                	add    %ebx,%eax
f010301d:	50                   	push   %eax
f010301e:	e8 c5 ff ff ff       	call   f0102fe8 <strcpy>
	return dst;
}
f0103023:	89 d8                	mov    %ebx,%eax
f0103025:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103028:	c9                   	leave  
f0103029:	c3                   	ret    

f010302a <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010302a:	55                   	push   %ebp
f010302b:	89 e5                	mov    %esp,%ebp
f010302d:	56                   	push   %esi
f010302e:	53                   	push   %ebx
f010302f:	8b 75 08             	mov    0x8(%ebp),%esi
f0103032:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103035:	89 f3                	mov    %esi,%ebx
f0103037:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010303a:	89 f2                	mov    %esi,%edx
f010303c:	eb 0f                	jmp    f010304d <strncpy+0x23>
		*dst++ = *src;
f010303e:	83 c2 01             	add    $0x1,%edx
f0103041:	0f b6 01             	movzbl (%ecx),%eax
f0103044:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103047:	80 39 01             	cmpb   $0x1,(%ecx)
f010304a:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010304d:	39 da                	cmp    %ebx,%edx
f010304f:	75 ed                	jne    f010303e <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103051:	89 f0                	mov    %esi,%eax
f0103053:	5b                   	pop    %ebx
f0103054:	5e                   	pop    %esi
f0103055:	5d                   	pop    %ebp
f0103056:	c3                   	ret    

f0103057 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103057:	55                   	push   %ebp
f0103058:	89 e5                	mov    %esp,%ebp
f010305a:	56                   	push   %esi
f010305b:	53                   	push   %ebx
f010305c:	8b 75 08             	mov    0x8(%ebp),%esi
f010305f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103062:	8b 55 10             	mov    0x10(%ebp),%edx
f0103065:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103067:	85 d2                	test   %edx,%edx
f0103069:	74 21                	je     f010308c <strlcpy+0x35>
f010306b:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010306f:	89 f2                	mov    %esi,%edx
f0103071:	eb 09                	jmp    f010307c <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103073:	83 c2 01             	add    $0x1,%edx
f0103076:	83 c1 01             	add    $0x1,%ecx
f0103079:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010307c:	39 c2                	cmp    %eax,%edx
f010307e:	74 09                	je     f0103089 <strlcpy+0x32>
f0103080:	0f b6 19             	movzbl (%ecx),%ebx
f0103083:	84 db                	test   %bl,%bl
f0103085:	75 ec                	jne    f0103073 <strlcpy+0x1c>
f0103087:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103089:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010308c:	29 f0                	sub    %esi,%eax
}
f010308e:	5b                   	pop    %ebx
f010308f:	5e                   	pop    %esi
f0103090:	5d                   	pop    %ebp
f0103091:	c3                   	ret    

f0103092 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103092:	55                   	push   %ebp
f0103093:	89 e5                	mov    %esp,%ebp
f0103095:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103098:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010309b:	eb 06                	jmp    f01030a3 <strcmp+0x11>
		p++, q++;
f010309d:	83 c1 01             	add    $0x1,%ecx
f01030a0:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01030a3:	0f b6 01             	movzbl (%ecx),%eax
f01030a6:	84 c0                	test   %al,%al
f01030a8:	74 04                	je     f01030ae <strcmp+0x1c>
f01030aa:	3a 02                	cmp    (%edx),%al
f01030ac:	74 ef                	je     f010309d <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01030ae:	0f b6 c0             	movzbl %al,%eax
f01030b1:	0f b6 12             	movzbl (%edx),%edx
f01030b4:	29 d0                	sub    %edx,%eax
}
f01030b6:	5d                   	pop    %ebp
f01030b7:	c3                   	ret    

f01030b8 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01030b8:	55                   	push   %ebp
f01030b9:	89 e5                	mov    %esp,%ebp
f01030bb:	53                   	push   %ebx
f01030bc:	8b 45 08             	mov    0x8(%ebp),%eax
f01030bf:	8b 55 0c             	mov    0xc(%ebp),%edx
f01030c2:	89 c3                	mov    %eax,%ebx
f01030c4:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01030c7:	eb 06                	jmp    f01030cf <strncmp+0x17>
		n--, p++, q++;
f01030c9:	83 c0 01             	add    $0x1,%eax
f01030cc:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01030cf:	39 d8                	cmp    %ebx,%eax
f01030d1:	74 15                	je     f01030e8 <strncmp+0x30>
f01030d3:	0f b6 08             	movzbl (%eax),%ecx
f01030d6:	84 c9                	test   %cl,%cl
f01030d8:	74 04                	je     f01030de <strncmp+0x26>
f01030da:	3a 0a                	cmp    (%edx),%cl
f01030dc:	74 eb                	je     f01030c9 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01030de:	0f b6 00             	movzbl (%eax),%eax
f01030e1:	0f b6 12             	movzbl (%edx),%edx
f01030e4:	29 d0                	sub    %edx,%eax
f01030e6:	eb 05                	jmp    f01030ed <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01030e8:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01030ed:	5b                   	pop    %ebx
f01030ee:	5d                   	pop    %ebp
f01030ef:	c3                   	ret    

f01030f0 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01030f0:	55                   	push   %ebp
f01030f1:	89 e5                	mov    %esp,%ebp
f01030f3:	8b 45 08             	mov    0x8(%ebp),%eax
f01030f6:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01030fa:	eb 07                	jmp    f0103103 <strchr+0x13>
		if (*s == c)
f01030fc:	38 ca                	cmp    %cl,%dl
f01030fe:	74 0f                	je     f010310f <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103100:	83 c0 01             	add    $0x1,%eax
f0103103:	0f b6 10             	movzbl (%eax),%edx
f0103106:	84 d2                	test   %dl,%dl
f0103108:	75 f2                	jne    f01030fc <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010310a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010310f:	5d                   	pop    %ebp
f0103110:	c3                   	ret    

f0103111 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103111:	55                   	push   %ebp
f0103112:	89 e5                	mov    %esp,%ebp
f0103114:	8b 45 08             	mov    0x8(%ebp),%eax
f0103117:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010311b:	eb 03                	jmp    f0103120 <strfind+0xf>
f010311d:	83 c0 01             	add    $0x1,%eax
f0103120:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103123:	38 ca                	cmp    %cl,%dl
f0103125:	74 04                	je     f010312b <strfind+0x1a>
f0103127:	84 d2                	test   %dl,%dl
f0103129:	75 f2                	jne    f010311d <strfind+0xc>
			break;
	return (char *) s;
}
f010312b:	5d                   	pop    %ebp
f010312c:	c3                   	ret    

f010312d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010312d:	55                   	push   %ebp
f010312e:	89 e5                	mov    %esp,%ebp
f0103130:	57                   	push   %edi
f0103131:	56                   	push   %esi
f0103132:	53                   	push   %ebx
f0103133:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103136:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103139:	85 c9                	test   %ecx,%ecx
f010313b:	74 36                	je     f0103173 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010313d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103143:	75 28                	jne    f010316d <memset+0x40>
f0103145:	f6 c1 03             	test   $0x3,%cl
f0103148:	75 23                	jne    f010316d <memset+0x40>
		c &= 0xFF;
f010314a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010314e:	89 d3                	mov    %edx,%ebx
f0103150:	c1 e3 08             	shl    $0x8,%ebx
f0103153:	89 d6                	mov    %edx,%esi
f0103155:	c1 e6 18             	shl    $0x18,%esi
f0103158:	89 d0                	mov    %edx,%eax
f010315a:	c1 e0 10             	shl    $0x10,%eax
f010315d:	09 f0                	or     %esi,%eax
f010315f:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103161:	89 d8                	mov    %ebx,%eax
f0103163:	09 d0                	or     %edx,%eax
f0103165:	c1 e9 02             	shr    $0x2,%ecx
f0103168:	fc                   	cld    
f0103169:	f3 ab                	rep stos %eax,%es:(%edi)
f010316b:	eb 06                	jmp    f0103173 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010316d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103170:	fc                   	cld    
f0103171:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103173:	89 f8                	mov    %edi,%eax
f0103175:	5b                   	pop    %ebx
f0103176:	5e                   	pop    %esi
f0103177:	5f                   	pop    %edi
f0103178:	5d                   	pop    %ebp
f0103179:	c3                   	ret    

f010317a <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010317a:	55                   	push   %ebp
f010317b:	89 e5                	mov    %esp,%ebp
f010317d:	57                   	push   %edi
f010317e:	56                   	push   %esi
f010317f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103182:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103185:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103188:	39 c6                	cmp    %eax,%esi
f010318a:	73 35                	jae    f01031c1 <memmove+0x47>
f010318c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010318f:	39 d0                	cmp    %edx,%eax
f0103191:	73 2e                	jae    f01031c1 <memmove+0x47>
		s += n;
		d += n;
f0103193:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103196:	89 d6                	mov    %edx,%esi
f0103198:	09 fe                	or     %edi,%esi
f010319a:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01031a0:	75 13                	jne    f01031b5 <memmove+0x3b>
f01031a2:	f6 c1 03             	test   $0x3,%cl
f01031a5:	75 0e                	jne    f01031b5 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01031a7:	83 ef 04             	sub    $0x4,%edi
f01031aa:	8d 72 fc             	lea    -0x4(%edx),%esi
f01031ad:	c1 e9 02             	shr    $0x2,%ecx
f01031b0:	fd                   	std    
f01031b1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01031b3:	eb 09                	jmp    f01031be <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01031b5:	83 ef 01             	sub    $0x1,%edi
f01031b8:	8d 72 ff             	lea    -0x1(%edx),%esi
f01031bb:	fd                   	std    
f01031bc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01031be:	fc                   	cld    
f01031bf:	eb 1d                	jmp    f01031de <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01031c1:	89 f2                	mov    %esi,%edx
f01031c3:	09 c2                	or     %eax,%edx
f01031c5:	f6 c2 03             	test   $0x3,%dl
f01031c8:	75 0f                	jne    f01031d9 <memmove+0x5f>
f01031ca:	f6 c1 03             	test   $0x3,%cl
f01031cd:	75 0a                	jne    f01031d9 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01031cf:	c1 e9 02             	shr    $0x2,%ecx
f01031d2:	89 c7                	mov    %eax,%edi
f01031d4:	fc                   	cld    
f01031d5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01031d7:	eb 05                	jmp    f01031de <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01031d9:	89 c7                	mov    %eax,%edi
f01031db:	fc                   	cld    
f01031dc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01031de:	5e                   	pop    %esi
f01031df:	5f                   	pop    %edi
f01031e0:	5d                   	pop    %ebp
f01031e1:	c3                   	ret    

f01031e2 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01031e2:	55                   	push   %ebp
f01031e3:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01031e5:	ff 75 10             	pushl  0x10(%ebp)
f01031e8:	ff 75 0c             	pushl  0xc(%ebp)
f01031eb:	ff 75 08             	pushl  0x8(%ebp)
f01031ee:	e8 87 ff ff ff       	call   f010317a <memmove>
}
f01031f3:	c9                   	leave  
f01031f4:	c3                   	ret    

f01031f5 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01031f5:	55                   	push   %ebp
f01031f6:	89 e5                	mov    %esp,%ebp
f01031f8:	56                   	push   %esi
f01031f9:	53                   	push   %ebx
f01031fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01031fd:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103200:	89 c6                	mov    %eax,%esi
f0103202:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103205:	eb 1a                	jmp    f0103221 <memcmp+0x2c>
		if (*s1 != *s2)
f0103207:	0f b6 08             	movzbl (%eax),%ecx
f010320a:	0f b6 1a             	movzbl (%edx),%ebx
f010320d:	38 d9                	cmp    %bl,%cl
f010320f:	74 0a                	je     f010321b <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103211:	0f b6 c1             	movzbl %cl,%eax
f0103214:	0f b6 db             	movzbl %bl,%ebx
f0103217:	29 d8                	sub    %ebx,%eax
f0103219:	eb 0f                	jmp    f010322a <memcmp+0x35>
		s1++, s2++;
f010321b:	83 c0 01             	add    $0x1,%eax
f010321e:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103221:	39 f0                	cmp    %esi,%eax
f0103223:	75 e2                	jne    f0103207 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103225:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010322a:	5b                   	pop    %ebx
f010322b:	5e                   	pop    %esi
f010322c:	5d                   	pop    %ebp
f010322d:	c3                   	ret    

f010322e <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010322e:	55                   	push   %ebp
f010322f:	89 e5                	mov    %esp,%ebp
f0103231:	53                   	push   %ebx
f0103232:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103235:	89 c1                	mov    %eax,%ecx
f0103237:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010323a:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010323e:	eb 0a                	jmp    f010324a <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103240:	0f b6 10             	movzbl (%eax),%edx
f0103243:	39 da                	cmp    %ebx,%edx
f0103245:	74 07                	je     f010324e <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103247:	83 c0 01             	add    $0x1,%eax
f010324a:	39 c8                	cmp    %ecx,%eax
f010324c:	72 f2                	jb     f0103240 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010324e:	5b                   	pop    %ebx
f010324f:	5d                   	pop    %ebp
f0103250:	c3                   	ret    

f0103251 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103251:	55                   	push   %ebp
f0103252:	89 e5                	mov    %esp,%ebp
f0103254:	57                   	push   %edi
f0103255:	56                   	push   %esi
f0103256:	53                   	push   %ebx
f0103257:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010325a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010325d:	eb 03                	jmp    f0103262 <strtol+0x11>
		s++;
f010325f:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103262:	0f b6 01             	movzbl (%ecx),%eax
f0103265:	3c 20                	cmp    $0x20,%al
f0103267:	74 f6                	je     f010325f <strtol+0xe>
f0103269:	3c 09                	cmp    $0x9,%al
f010326b:	74 f2                	je     f010325f <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010326d:	3c 2b                	cmp    $0x2b,%al
f010326f:	75 0a                	jne    f010327b <strtol+0x2a>
		s++;
f0103271:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103274:	bf 00 00 00 00       	mov    $0x0,%edi
f0103279:	eb 11                	jmp    f010328c <strtol+0x3b>
f010327b:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103280:	3c 2d                	cmp    $0x2d,%al
f0103282:	75 08                	jne    f010328c <strtol+0x3b>
		s++, neg = 1;
f0103284:	83 c1 01             	add    $0x1,%ecx
f0103287:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010328c:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103292:	75 15                	jne    f01032a9 <strtol+0x58>
f0103294:	80 39 30             	cmpb   $0x30,(%ecx)
f0103297:	75 10                	jne    f01032a9 <strtol+0x58>
f0103299:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010329d:	75 7c                	jne    f010331b <strtol+0xca>
		s += 2, base = 16;
f010329f:	83 c1 02             	add    $0x2,%ecx
f01032a2:	bb 10 00 00 00       	mov    $0x10,%ebx
f01032a7:	eb 16                	jmp    f01032bf <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01032a9:	85 db                	test   %ebx,%ebx
f01032ab:	75 12                	jne    f01032bf <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01032ad:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01032b2:	80 39 30             	cmpb   $0x30,(%ecx)
f01032b5:	75 08                	jne    f01032bf <strtol+0x6e>
		s++, base = 8;
f01032b7:	83 c1 01             	add    $0x1,%ecx
f01032ba:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01032bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01032c4:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01032c7:	0f b6 11             	movzbl (%ecx),%edx
f01032ca:	8d 72 d0             	lea    -0x30(%edx),%esi
f01032cd:	89 f3                	mov    %esi,%ebx
f01032cf:	80 fb 09             	cmp    $0x9,%bl
f01032d2:	77 08                	ja     f01032dc <strtol+0x8b>
			dig = *s - '0';
f01032d4:	0f be d2             	movsbl %dl,%edx
f01032d7:	83 ea 30             	sub    $0x30,%edx
f01032da:	eb 22                	jmp    f01032fe <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01032dc:	8d 72 9f             	lea    -0x61(%edx),%esi
f01032df:	89 f3                	mov    %esi,%ebx
f01032e1:	80 fb 19             	cmp    $0x19,%bl
f01032e4:	77 08                	ja     f01032ee <strtol+0x9d>
			dig = *s - 'a' + 10;
f01032e6:	0f be d2             	movsbl %dl,%edx
f01032e9:	83 ea 57             	sub    $0x57,%edx
f01032ec:	eb 10                	jmp    f01032fe <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01032ee:	8d 72 bf             	lea    -0x41(%edx),%esi
f01032f1:	89 f3                	mov    %esi,%ebx
f01032f3:	80 fb 19             	cmp    $0x19,%bl
f01032f6:	77 16                	ja     f010330e <strtol+0xbd>
			dig = *s - 'A' + 10;
f01032f8:	0f be d2             	movsbl %dl,%edx
f01032fb:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01032fe:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103301:	7d 0b                	jge    f010330e <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103303:	83 c1 01             	add    $0x1,%ecx
f0103306:	0f af 45 10          	imul   0x10(%ebp),%eax
f010330a:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010330c:	eb b9                	jmp    f01032c7 <strtol+0x76>

	if (endptr)
f010330e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103312:	74 0d                	je     f0103321 <strtol+0xd0>
		*endptr = (char *) s;
f0103314:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103317:	89 0e                	mov    %ecx,(%esi)
f0103319:	eb 06                	jmp    f0103321 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010331b:	85 db                	test   %ebx,%ebx
f010331d:	74 98                	je     f01032b7 <strtol+0x66>
f010331f:	eb 9e                	jmp    f01032bf <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103321:	89 c2                	mov    %eax,%edx
f0103323:	f7 da                	neg    %edx
f0103325:	85 ff                	test   %edi,%edi
f0103327:	0f 45 c2             	cmovne %edx,%eax
}
f010332a:	5b                   	pop    %ebx
f010332b:	5e                   	pop    %esi
f010332c:	5f                   	pop    %edi
f010332d:	5d                   	pop    %ebp
f010332e:	c3                   	ret    
f010332f:	90                   	nop

f0103330 <__udivdi3>:
f0103330:	55                   	push   %ebp
f0103331:	57                   	push   %edi
f0103332:	56                   	push   %esi
f0103333:	53                   	push   %ebx
f0103334:	83 ec 1c             	sub    $0x1c,%esp
f0103337:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010333b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010333f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103343:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103347:	85 f6                	test   %esi,%esi
f0103349:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010334d:	89 ca                	mov    %ecx,%edx
f010334f:	89 f8                	mov    %edi,%eax
f0103351:	75 3d                	jne    f0103390 <__udivdi3+0x60>
f0103353:	39 cf                	cmp    %ecx,%edi
f0103355:	0f 87 c5 00 00 00    	ja     f0103420 <__udivdi3+0xf0>
f010335b:	85 ff                	test   %edi,%edi
f010335d:	89 fd                	mov    %edi,%ebp
f010335f:	75 0b                	jne    f010336c <__udivdi3+0x3c>
f0103361:	b8 01 00 00 00       	mov    $0x1,%eax
f0103366:	31 d2                	xor    %edx,%edx
f0103368:	f7 f7                	div    %edi
f010336a:	89 c5                	mov    %eax,%ebp
f010336c:	89 c8                	mov    %ecx,%eax
f010336e:	31 d2                	xor    %edx,%edx
f0103370:	f7 f5                	div    %ebp
f0103372:	89 c1                	mov    %eax,%ecx
f0103374:	89 d8                	mov    %ebx,%eax
f0103376:	89 cf                	mov    %ecx,%edi
f0103378:	f7 f5                	div    %ebp
f010337a:	89 c3                	mov    %eax,%ebx
f010337c:	89 d8                	mov    %ebx,%eax
f010337e:	89 fa                	mov    %edi,%edx
f0103380:	83 c4 1c             	add    $0x1c,%esp
f0103383:	5b                   	pop    %ebx
f0103384:	5e                   	pop    %esi
f0103385:	5f                   	pop    %edi
f0103386:	5d                   	pop    %ebp
f0103387:	c3                   	ret    
f0103388:	90                   	nop
f0103389:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103390:	39 ce                	cmp    %ecx,%esi
f0103392:	77 74                	ja     f0103408 <__udivdi3+0xd8>
f0103394:	0f bd fe             	bsr    %esi,%edi
f0103397:	83 f7 1f             	xor    $0x1f,%edi
f010339a:	0f 84 98 00 00 00    	je     f0103438 <__udivdi3+0x108>
f01033a0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01033a5:	89 f9                	mov    %edi,%ecx
f01033a7:	89 c5                	mov    %eax,%ebp
f01033a9:	29 fb                	sub    %edi,%ebx
f01033ab:	d3 e6                	shl    %cl,%esi
f01033ad:	89 d9                	mov    %ebx,%ecx
f01033af:	d3 ed                	shr    %cl,%ebp
f01033b1:	89 f9                	mov    %edi,%ecx
f01033b3:	d3 e0                	shl    %cl,%eax
f01033b5:	09 ee                	or     %ebp,%esi
f01033b7:	89 d9                	mov    %ebx,%ecx
f01033b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033bd:	89 d5                	mov    %edx,%ebp
f01033bf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01033c3:	d3 ed                	shr    %cl,%ebp
f01033c5:	89 f9                	mov    %edi,%ecx
f01033c7:	d3 e2                	shl    %cl,%edx
f01033c9:	89 d9                	mov    %ebx,%ecx
f01033cb:	d3 e8                	shr    %cl,%eax
f01033cd:	09 c2                	or     %eax,%edx
f01033cf:	89 d0                	mov    %edx,%eax
f01033d1:	89 ea                	mov    %ebp,%edx
f01033d3:	f7 f6                	div    %esi
f01033d5:	89 d5                	mov    %edx,%ebp
f01033d7:	89 c3                	mov    %eax,%ebx
f01033d9:	f7 64 24 0c          	mull   0xc(%esp)
f01033dd:	39 d5                	cmp    %edx,%ebp
f01033df:	72 10                	jb     f01033f1 <__udivdi3+0xc1>
f01033e1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01033e5:	89 f9                	mov    %edi,%ecx
f01033e7:	d3 e6                	shl    %cl,%esi
f01033e9:	39 c6                	cmp    %eax,%esi
f01033eb:	73 07                	jae    f01033f4 <__udivdi3+0xc4>
f01033ed:	39 d5                	cmp    %edx,%ebp
f01033ef:	75 03                	jne    f01033f4 <__udivdi3+0xc4>
f01033f1:	83 eb 01             	sub    $0x1,%ebx
f01033f4:	31 ff                	xor    %edi,%edi
f01033f6:	89 d8                	mov    %ebx,%eax
f01033f8:	89 fa                	mov    %edi,%edx
f01033fa:	83 c4 1c             	add    $0x1c,%esp
f01033fd:	5b                   	pop    %ebx
f01033fe:	5e                   	pop    %esi
f01033ff:	5f                   	pop    %edi
f0103400:	5d                   	pop    %ebp
f0103401:	c3                   	ret    
f0103402:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103408:	31 ff                	xor    %edi,%edi
f010340a:	31 db                	xor    %ebx,%ebx
f010340c:	89 d8                	mov    %ebx,%eax
f010340e:	89 fa                	mov    %edi,%edx
f0103410:	83 c4 1c             	add    $0x1c,%esp
f0103413:	5b                   	pop    %ebx
f0103414:	5e                   	pop    %esi
f0103415:	5f                   	pop    %edi
f0103416:	5d                   	pop    %ebp
f0103417:	c3                   	ret    
f0103418:	90                   	nop
f0103419:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103420:	89 d8                	mov    %ebx,%eax
f0103422:	f7 f7                	div    %edi
f0103424:	31 ff                	xor    %edi,%edi
f0103426:	89 c3                	mov    %eax,%ebx
f0103428:	89 d8                	mov    %ebx,%eax
f010342a:	89 fa                	mov    %edi,%edx
f010342c:	83 c4 1c             	add    $0x1c,%esp
f010342f:	5b                   	pop    %ebx
f0103430:	5e                   	pop    %esi
f0103431:	5f                   	pop    %edi
f0103432:	5d                   	pop    %ebp
f0103433:	c3                   	ret    
f0103434:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103438:	39 ce                	cmp    %ecx,%esi
f010343a:	72 0c                	jb     f0103448 <__udivdi3+0x118>
f010343c:	31 db                	xor    %ebx,%ebx
f010343e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103442:	0f 87 34 ff ff ff    	ja     f010337c <__udivdi3+0x4c>
f0103448:	bb 01 00 00 00       	mov    $0x1,%ebx
f010344d:	e9 2a ff ff ff       	jmp    f010337c <__udivdi3+0x4c>
f0103452:	66 90                	xchg   %ax,%ax
f0103454:	66 90                	xchg   %ax,%ax
f0103456:	66 90                	xchg   %ax,%ax
f0103458:	66 90                	xchg   %ax,%ax
f010345a:	66 90                	xchg   %ax,%ax
f010345c:	66 90                	xchg   %ax,%ax
f010345e:	66 90                	xchg   %ax,%ax

f0103460 <__umoddi3>:
f0103460:	55                   	push   %ebp
f0103461:	57                   	push   %edi
f0103462:	56                   	push   %esi
f0103463:	53                   	push   %ebx
f0103464:	83 ec 1c             	sub    $0x1c,%esp
f0103467:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010346b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010346f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103473:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103477:	85 d2                	test   %edx,%edx
f0103479:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010347d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103481:	89 f3                	mov    %esi,%ebx
f0103483:	89 3c 24             	mov    %edi,(%esp)
f0103486:	89 74 24 04          	mov    %esi,0x4(%esp)
f010348a:	75 1c                	jne    f01034a8 <__umoddi3+0x48>
f010348c:	39 f7                	cmp    %esi,%edi
f010348e:	76 50                	jbe    f01034e0 <__umoddi3+0x80>
f0103490:	89 c8                	mov    %ecx,%eax
f0103492:	89 f2                	mov    %esi,%edx
f0103494:	f7 f7                	div    %edi
f0103496:	89 d0                	mov    %edx,%eax
f0103498:	31 d2                	xor    %edx,%edx
f010349a:	83 c4 1c             	add    $0x1c,%esp
f010349d:	5b                   	pop    %ebx
f010349e:	5e                   	pop    %esi
f010349f:	5f                   	pop    %edi
f01034a0:	5d                   	pop    %ebp
f01034a1:	c3                   	ret    
f01034a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01034a8:	39 f2                	cmp    %esi,%edx
f01034aa:	89 d0                	mov    %edx,%eax
f01034ac:	77 52                	ja     f0103500 <__umoddi3+0xa0>
f01034ae:	0f bd ea             	bsr    %edx,%ebp
f01034b1:	83 f5 1f             	xor    $0x1f,%ebp
f01034b4:	75 5a                	jne    f0103510 <__umoddi3+0xb0>
f01034b6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01034ba:	0f 82 e0 00 00 00    	jb     f01035a0 <__umoddi3+0x140>
f01034c0:	39 0c 24             	cmp    %ecx,(%esp)
f01034c3:	0f 86 d7 00 00 00    	jbe    f01035a0 <__umoddi3+0x140>
f01034c9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01034cd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01034d1:	83 c4 1c             	add    $0x1c,%esp
f01034d4:	5b                   	pop    %ebx
f01034d5:	5e                   	pop    %esi
f01034d6:	5f                   	pop    %edi
f01034d7:	5d                   	pop    %ebp
f01034d8:	c3                   	ret    
f01034d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034e0:	85 ff                	test   %edi,%edi
f01034e2:	89 fd                	mov    %edi,%ebp
f01034e4:	75 0b                	jne    f01034f1 <__umoddi3+0x91>
f01034e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01034eb:	31 d2                	xor    %edx,%edx
f01034ed:	f7 f7                	div    %edi
f01034ef:	89 c5                	mov    %eax,%ebp
f01034f1:	89 f0                	mov    %esi,%eax
f01034f3:	31 d2                	xor    %edx,%edx
f01034f5:	f7 f5                	div    %ebp
f01034f7:	89 c8                	mov    %ecx,%eax
f01034f9:	f7 f5                	div    %ebp
f01034fb:	89 d0                	mov    %edx,%eax
f01034fd:	eb 99                	jmp    f0103498 <__umoddi3+0x38>
f01034ff:	90                   	nop
f0103500:	89 c8                	mov    %ecx,%eax
f0103502:	89 f2                	mov    %esi,%edx
f0103504:	83 c4 1c             	add    $0x1c,%esp
f0103507:	5b                   	pop    %ebx
f0103508:	5e                   	pop    %esi
f0103509:	5f                   	pop    %edi
f010350a:	5d                   	pop    %ebp
f010350b:	c3                   	ret    
f010350c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103510:	8b 34 24             	mov    (%esp),%esi
f0103513:	bf 20 00 00 00       	mov    $0x20,%edi
f0103518:	89 e9                	mov    %ebp,%ecx
f010351a:	29 ef                	sub    %ebp,%edi
f010351c:	d3 e0                	shl    %cl,%eax
f010351e:	89 f9                	mov    %edi,%ecx
f0103520:	89 f2                	mov    %esi,%edx
f0103522:	d3 ea                	shr    %cl,%edx
f0103524:	89 e9                	mov    %ebp,%ecx
f0103526:	09 c2                	or     %eax,%edx
f0103528:	89 d8                	mov    %ebx,%eax
f010352a:	89 14 24             	mov    %edx,(%esp)
f010352d:	89 f2                	mov    %esi,%edx
f010352f:	d3 e2                	shl    %cl,%edx
f0103531:	89 f9                	mov    %edi,%ecx
f0103533:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103537:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010353b:	d3 e8                	shr    %cl,%eax
f010353d:	89 e9                	mov    %ebp,%ecx
f010353f:	89 c6                	mov    %eax,%esi
f0103541:	d3 e3                	shl    %cl,%ebx
f0103543:	89 f9                	mov    %edi,%ecx
f0103545:	89 d0                	mov    %edx,%eax
f0103547:	d3 e8                	shr    %cl,%eax
f0103549:	89 e9                	mov    %ebp,%ecx
f010354b:	09 d8                	or     %ebx,%eax
f010354d:	89 d3                	mov    %edx,%ebx
f010354f:	89 f2                	mov    %esi,%edx
f0103551:	f7 34 24             	divl   (%esp)
f0103554:	89 d6                	mov    %edx,%esi
f0103556:	d3 e3                	shl    %cl,%ebx
f0103558:	f7 64 24 04          	mull   0x4(%esp)
f010355c:	39 d6                	cmp    %edx,%esi
f010355e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103562:	89 d1                	mov    %edx,%ecx
f0103564:	89 c3                	mov    %eax,%ebx
f0103566:	72 08                	jb     f0103570 <__umoddi3+0x110>
f0103568:	75 11                	jne    f010357b <__umoddi3+0x11b>
f010356a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010356e:	73 0b                	jae    f010357b <__umoddi3+0x11b>
f0103570:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103574:	1b 14 24             	sbb    (%esp),%edx
f0103577:	89 d1                	mov    %edx,%ecx
f0103579:	89 c3                	mov    %eax,%ebx
f010357b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010357f:	29 da                	sub    %ebx,%edx
f0103581:	19 ce                	sbb    %ecx,%esi
f0103583:	89 f9                	mov    %edi,%ecx
f0103585:	89 f0                	mov    %esi,%eax
f0103587:	d3 e0                	shl    %cl,%eax
f0103589:	89 e9                	mov    %ebp,%ecx
f010358b:	d3 ea                	shr    %cl,%edx
f010358d:	89 e9                	mov    %ebp,%ecx
f010358f:	d3 ee                	shr    %cl,%esi
f0103591:	09 d0                	or     %edx,%eax
f0103593:	89 f2                	mov    %esi,%edx
f0103595:	83 c4 1c             	add    $0x1c,%esp
f0103598:	5b                   	pop    %ebx
f0103599:	5e                   	pop    %esi
f010359a:	5f                   	pop    %edi
f010359b:	5d                   	pop    %ebp
f010359c:	c3                   	ret    
f010359d:	8d 76 00             	lea    0x0(%esi),%esi
f01035a0:	29 f9                	sub    %edi,%ecx
f01035a2:	19 d6                	sbb    %edx,%esi
f01035a4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035a8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035ac:	e9 18 ff ff ff       	jmp    f01034c9 <__umoddi3+0x69>

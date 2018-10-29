
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
f0100058:	e8 72 31 00 00       	call   f01031cf <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 bb 04 00 00       	call   f010051d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 80 36 10 f0       	push   $0xf0103680
f010006f:	e8 a7 26 00 00       	call   f010271b <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 a9 0f 00 00       	call   f0101022 <mem_init>
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
f01000b0:	68 9b 36 10 f0       	push   $0xf010369b
f01000b5:	e8 61 26 00 00       	call   f010271b <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 31 26 00 00       	call   f01026f5 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 89 39 10 f0 	movl   $0xf0103989,(%esp)
f01000cb:	e8 4b 26 00 00       	call   f010271b <cprintf>
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
f01000f2:	68 b3 36 10 f0       	push   $0xf01036b3
f01000f7:	e8 1f 26 00 00       	call   f010271b <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 ed 25 00 00       	call   f01026f5 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 89 39 10 f0 	movl   $0xf0103989,(%esp)
f010010f:	e8 07 26 00 00       	call   f010271b <cprintf>
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
f01001c6:	0f b6 82 20 38 10 f0 	movzbl -0xfefc7e0(%edx),%eax
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
f0100202:	0f b6 82 20 38 10 f0 	movzbl -0xfefc7e0(%edx),%eax
f0100209:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f010020f:	0f b6 8a 20 37 10 f0 	movzbl -0xfefc8e0(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d 00 37 10 f0 	mov    -0xfefc900(,%ecx,4),%ecx
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
f0100260:	68 cd 36 10 f0       	push   $0xf01036cd
f0100265:	e8 b1 24 00 00       	call   f010271b <cprintf>
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
f0100441:	e8 d6 2d 00 00       	call   f010321c <memmove>
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
f0100610:	68 d9 36 10 f0       	push   $0xf01036d9
f0100615:	e8 01 21 00 00       	call   f010271b <cprintf>
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
f0100656:	68 20 39 10 f0       	push   $0xf0103920
f010065b:	68 3e 39 10 f0       	push   $0xf010393e
f0100660:	68 43 39 10 f0       	push   $0xf0103943
f0100665:	e8 b1 20 00 00       	call   f010271b <cprintf>
f010066a:	83 c4 0c             	add    $0xc,%esp
f010066d:	68 d8 39 10 f0       	push   $0xf01039d8
f0100672:	68 4c 39 10 f0       	push   $0xf010394c
f0100677:	68 43 39 10 f0       	push   $0xf0103943
f010067c:	e8 9a 20 00 00       	call   f010271b <cprintf>
f0100681:	83 c4 0c             	add    $0xc,%esp
f0100684:	68 00 3a 10 f0       	push   $0xf0103a00
f0100689:	68 55 39 10 f0       	push   $0xf0103955
f010068e:	68 43 39 10 f0       	push   $0xf0103943
f0100693:	e8 83 20 00 00       	call   f010271b <cprintf>
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
f01006a5:	68 5f 39 10 f0       	push   $0xf010395f
f01006aa:	e8 6c 20 00 00       	call   f010271b <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006af:	83 c4 08             	add    $0x8,%esp
f01006b2:	68 0c 00 10 00       	push   $0x10000c
f01006b7:	68 28 3a 10 f0       	push   $0xf0103a28
f01006bc:	e8 5a 20 00 00       	call   f010271b <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006c1:	83 c4 0c             	add    $0xc,%esp
f01006c4:	68 0c 00 10 00       	push   $0x10000c
f01006c9:	68 0c 00 10 f0       	push   $0xf010000c
f01006ce:	68 50 3a 10 f0       	push   $0xf0103a50
f01006d3:	e8 43 20 00 00       	call   f010271b <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d8:	83 c4 0c             	add    $0xc,%esp
f01006db:	68 61 36 10 00       	push   $0x103661
f01006e0:	68 61 36 10 f0       	push   $0xf0103661
f01006e5:	68 74 3a 10 f0       	push   $0xf0103a74
f01006ea:	e8 2c 20 00 00       	call   f010271b <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ef:	83 c4 0c             	add    $0xc,%esp
f01006f2:	68 00 63 11 00       	push   $0x116300
f01006f7:	68 00 63 11 f0       	push   $0xf0116300
f01006fc:	68 98 3a 10 f0       	push   $0xf0103a98
f0100701:	e8 15 20 00 00       	call   f010271b <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100706:	83 c4 0c             	add    $0xc,%esp
f0100709:	68 70 69 11 00       	push   $0x116970
f010070e:	68 70 69 11 f0       	push   $0xf0116970
f0100713:	68 bc 3a 10 f0       	push   $0xf0103abc
f0100718:	e8 fe 1f 00 00       	call   f010271b <cprintf>
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
f010073e:	68 e0 3a 10 f0       	push   $0xf0103ae0
f0100743:	e8 d3 1f 00 00       	call   f010271b <cprintf>
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
f010075a:	68 78 39 10 f0       	push   $0xf0103978
f010075f:	e8 b7 1f 00 00       	call   f010271b <cprintf>
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
f0100780:	68 0c 3b 10 f0       	push   $0xf0103b0c
f0100785:	e8 91 1f 00 00       	call   f010271b <cprintf>
	debuginfo_eip((uintptr_t)eip,&info);
f010078a:	83 c4 18             	add    $0x18,%esp
f010078d:	57                   	push   %edi
f010078e:	56                   	push   %esi
f010078f:	e8 91 20 00 00       	call   f0102825 <debuginfo_eip>
	cprintf("%s:%d", info.eip_file, info.eip_line);
f0100794:	83 c4 0c             	add    $0xc,%esp
f0100797:	ff 75 d4             	pushl  -0x2c(%ebp)
f010079a:	ff 75 d0             	pushl  -0x30(%ebp)
f010079d:	68 8b 39 10 f0       	push   $0xf010398b
f01007a2:	e8 74 1f 00 00       	call   f010271b <cprintf>
        cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name,info.eip_fn_addr);
f01007a7:	ff 75 e0             	pushl  -0x20(%ebp)
f01007aa:	ff 75 d8             	pushl  -0x28(%ebp)
f01007ad:	ff 75 dc             	pushl  -0x24(%ebp)
f01007b0:	68 91 39 10 f0       	push   $0xf0103991
f01007b5:	e8 61 1f 00 00       	call   f010271b <cprintf>
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
f01007d9:	68 44 3b 10 f0       	push   $0xf0103b44
f01007de:	e8 38 1f 00 00       	call   f010271b <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007e3:	c7 04 24 68 3b 10 f0 	movl   $0xf0103b68,(%esp)
f01007ea:	e8 2c 1f 00 00       	call   f010271b <cprintf>
f01007ef:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007f2:	83 ec 0c             	sub    $0xc,%esp
f01007f5:	68 9c 39 10 f0       	push   $0xf010399c
f01007fa:	e8 79 27 00 00       	call   f0102f78 <readline>
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
f010082e:	68 a0 39 10 f0       	push   $0xf01039a0
f0100833:	e8 5a 29 00 00       	call   f0103192 <strchr>
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
f010084e:	68 a5 39 10 f0       	push   $0xf01039a5
f0100853:	e8 c3 1e 00 00       	call   f010271b <cprintf>
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
f0100877:	68 a0 39 10 f0       	push   $0xf01039a0
f010087c:	e8 11 29 00 00       	call   f0103192 <strchr>
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
f01008a5:	ff 34 85 a0 3b 10 f0 	pushl  -0xfefc460(,%eax,4)
f01008ac:	ff 75 a8             	pushl  -0x58(%ebp)
f01008af:	e8 80 28 00 00       	call   f0103134 <strcmp>
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
f01008c9:	ff 14 85 a8 3b 10 f0 	call   *-0xfefc458(,%eax,4)


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
f01008ea:	68 c2 39 10 f0       	push   $0xf01039c2
f01008ef:	e8 27 1e 00 00       	call   f010271b <cprintf>
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
f0100963:	68 c4 3b 10 f0       	push   $0xf0103bc4
f0100968:	68 1d 03 00 00       	push   $0x31d
f010096d:	68 18 43 10 f0       	push   $0xf0104318
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
f01009bb:	68 e8 3b 10 f0       	push   $0xf0103be8
f01009c0:	68 60 02 00 00       	push   $0x260
f01009c5:	68 18 43 10 f0       	push   $0xf0104318
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
f0100a4a:	68 c4 3b 10 f0       	push   $0xf0103bc4
f0100a4f:	6a 52                	push   $0x52
f0100a51:	68 24 43 10 f0       	push   $0xf0104324
f0100a56:	e8 30 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a5b:	83 ec 04             	sub    $0x4,%esp
f0100a5e:	68 80 00 00 00       	push   $0x80
f0100a63:	68 97 00 00 00       	push   $0x97
f0100a68:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a6d:	50                   	push   %eax
f0100a6e:	e8 5c 27 00 00       	call   f01031cf <memset>
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
f0100ab4:	68 32 43 10 f0       	push   $0xf0104332
f0100ab9:	68 3e 43 10 f0       	push   $0xf010433e
f0100abe:	68 7a 02 00 00       	push   $0x27a
f0100ac3:	68 18 43 10 f0       	push   $0xf0104318
f0100ac8:	e8 be f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100acd:	39 fa                	cmp    %edi,%edx
f0100acf:	72 19                	jb     f0100aea <check_page_free_list+0x148>
f0100ad1:	68 53 43 10 f0       	push   $0xf0104353
f0100ad6:	68 3e 43 10 f0       	push   $0xf010433e
f0100adb:	68 7b 02 00 00       	push   $0x27b
f0100ae0:	68 18 43 10 f0       	push   $0xf0104318
f0100ae5:	e8 a1 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aea:	89 d0                	mov    %edx,%eax
f0100aec:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100aef:	a8 07                	test   $0x7,%al
f0100af1:	74 19                	je     f0100b0c <check_page_free_list+0x16a>
f0100af3:	68 0c 3c 10 f0       	push   $0xf0103c0c
f0100af8:	68 3e 43 10 f0       	push   $0xf010433e
f0100afd:	68 7c 02 00 00       	push   $0x27c
f0100b02:	68 18 43 10 f0       	push   $0xf0104318
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
f0100b16:	68 67 43 10 f0       	push   $0xf0104367
f0100b1b:	68 3e 43 10 f0       	push   $0xf010433e
f0100b20:	68 7f 02 00 00       	push   $0x27f
f0100b25:	68 18 43 10 f0       	push   $0xf0104318
f0100b2a:	e8 5c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b2f:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b34:	75 19                	jne    f0100b4f <check_page_free_list+0x1ad>
f0100b36:	68 78 43 10 f0       	push   $0xf0104378
f0100b3b:	68 3e 43 10 f0       	push   $0xf010433e
f0100b40:	68 80 02 00 00       	push   $0x280
f0100b45:	68 18 43 10 f0       	push   $0xf0104318
f0100b4a:	e8 3c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b4f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b54:	75 19                	jne    f0100b6f <check_page_free_list+0x1cd>
f0100b56:	68 40 3c 10 f0       	push   $0xf0103c40
f0100b5b:	68 3e 43 10 f0       	push   $0xf010433e
f0100b60:	68 81 02 00 00       	push   $0x281
f0100b65:	68 18 43 10 f0       	push   $0xf0104318
f0100b6a:	e8 1c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b6f:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b74:	75 19                	jne    f0100b8f <check_page_free_list+0x1ed>
f0100b76:	68 91 43 10 f0       	push   $0xf0104391
f0100b7b:	68 3e 43 10 f0       	push   $0xf010433e
f0100b80:	68 82 02 00 00       	push   $0x282
f0100b85:	68 18 43 10 f0       	push   $0xf0104318
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
f0100ba1:	68 c4 3b 10 f0       	push   $0xf0103bc4
f0100ba6:	6a 52                	push   $0x52
f0100ba8:	68 24 43 10 f0       	push   $0xf0104324
f0100bad:	e8 d9 f4 ff ff       	call   f010008b <_panic>
f0100bb2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bb7:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bba:	76 1e                	jbe    f0100bda <check_page_free_list+0x238>
f0100bbc:	68 64 3c 10 f0       	push   $0xf0103c64
f0100bc1:	68 3e 43 10 f0       	push   $0xf010433e
f0100bc6:	68 83 02 00 00       	push   $0x283
f0100bcb:	68 18 43 10 f0       	push   $0xf0104318
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
f0100bef:	68 ab 43 10 f0       	push   $0xf01043ab
f0100bf4:	68 3e 43 10 f0       	push   $0xf010433e
f0100bf9:	68 8b 02 00 00       	push   $0x28b
f0100bfe:	68 18 43 10 f0       	push   $0xf0104318
f0100c03:	e8 83 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c08:	85 db                	test   %ebx,%ebx
f0100c0a:	7f 42                	jg     f0100c4e <check_page_free_list+0x2ac>
f0100c0c:	68 bd 43 10 f0       	push   $0xf01043bd
f0100c11:	68 3e 43 10 f0       	push   $0xf010433e
f0100c16:	68 8c 02 00 00       	push   $0x28c
f0100c1b:	68 18 43 10 f0       	push   $0xf0104318
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
f0100d5d:	68 ce 43 10 f0       	push   $0xf01043ce
f0100d62:	e8 b4 19 00 00       	call   f010271b <cprintf>
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
f0100d8c:	68 c4 3b 10 f0       	push   $0xf0103bc4
f0100d91:	6a 52                	push   $0x52
f0100d93:	68 24 43 10 f0       	push   $0xf0104324
f0100d98:	e8 ee f2 ff ff       	call   f010008b <_panic>
			memset(page2kva(Page),'\0',PGSIZE);
f0100d9d:	83 ec 04             	sub    $0x4,%esp
f0100da0:	68 00 10 00 00       	push   $0x1000
f0100da5:	6a 00                	push   $0x0
f0100da7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dac:	50                   	push   %eax
f0100dad:	e8 1d 24 00 00       	call   f01031cf <memset>
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
f0100dd2:	68 db 43 10 f0       	push   $0xf01043db
f0100dd7:	e8 3f 19 00 00       	call   f010271b <cprintf>
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
f0100e41:	68 c4 3b 10 f0       	push   $0xf0103bc4
f0100e46:	68 86 01 00 00       	push   $0x186
f0100e4b:	68 18 43 10 f0       	push   $0xf0104318
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
f0100e95:	68 c4 3b 10 f0       	push   $0xf0103bc4
f0100e9a:	68 8e 01 00 00       	push   $0x18e
f0100e9f:	68 18 43 10 f0       	push   $0xf0104318
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
f0100ed5:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100ed8:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	pte_t *pte;
	for(int i = 0;i < size;i++){
f0100edb:	89 d3                	mov    %edx,%ebx
f0100edd:	bf 00 00 00 00       	mov    $0x0,%edi
f0100ee2:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ee5:	29 d0                	sub    %edx,%eax
f0100ee7:	89 45 e0             	mov    %eax,-0x20(%ebp)
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
f0100eea:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100eed:	83 c8 01             	or     $0x1,%eax
f0100ef0:	89 45 d8             	mov    %eax,-0x28(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte;
	for(int i = 0;i < size;i++){
f0100ef3:	eb 1f                	jmp    f0100f14 <boot_map_region+0x48>
		pte = pgdir_walk(pgdir, (void *)va, 1);
f0100ef5:	83 ec 04             	sub    $0x4,%esp
f0100ef8:	6a 01                	push   $0x1
f0100efa:	53                   	push   %ebx
f0100efb:	ff 75 dc             	pushl  -0x24(%ebp)
f0100efe:	e8 05 ff ff ff       	call   f0100e08 <pgdir_walk>
		*pte = (pa | perm | PTE_P);
f0100f03:	0b 75 d8             	or     -0x28(%ebp),%esi
f0100f06:	89 30                	mov    %esi,(%eax)
		va += PGSIZE;
f0100f08:	81 c3 00 10 00 00    	add    $0x1000,%ebx
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte;
	for(int i = 0;i < size;i++){
f0100f0e:	83 c7 01             	add    $0x1,%edi
f0100f11:	83 c4 10             	add    $0x10,%esp
f0100f14:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f17:	8d 34 18             	lea    (%eax,%ebx,1),%esi
f0100f1a:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0100f1d:	75 d6                	jne    f0100ef5 <boot_map_region+0x29>
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f0100f1f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f22:	5b                   	pop    %ebx
f0100f23:	5e                   	pop    %esi
f0100f24:	5f                   	pop    %edi
f0100f25:	5d                   	pop    %ebp
f0100f26:	c3                   	ret    

f0100f27 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f27:	55                   	push   %ebp
f0100f28:	89 e5                	mov    %esp,%ebp
f0100f2a:	53                   	push   %ebx
f0100f2b:	83 ec 08             	sub    $0x8,%esp
f0100f2e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
f0100f31:	6a 00                	push   $0x0
f0100f33:	ff 75 0c             	pushl  0xc(%ebp)
f0100f36:	ff 75 08             	pushl  0x8(%ebp)
f0100f39:	e8 ca fe ff ff       	call   f0100e08 <pgdir_walk>
	if(!pte)
f0100f3e:	83 c4 10             	add    $0x10,%esp
f0100f41:	85 c0                	test   %eax,%eax
f0100f43:	74 32                	je     f0100f77 <page_lookup+0x50>
		return NULL;
	if(pte_store)
f0100f45:	85 db                	test   %ebx,%ebx
f0100f47:	74 02                	je     f0100f4b <page_lookup+0x24>
		*pte_store = pte;
f0100f49:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f4b:	8b 00                	mov    (%eax),%eax
f0100f4d:	c1 e8 0c             	shr    $0xc,%eax
f0100f50:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0100f56:	72 14                	jb     f0100f6c <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100f58:	83 ec 04             	sub    $0x4,%esp
f0100f5b:	68 ac 3c 10 f0       	push   $0xf0103cac
f0100f60:	6a 4b                	push   $0x4b
f0100f62:	68 24 43 10 f0       	push   $0xf0104324
f0100f67:	e8 1f f1 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100f6c:	8b 15 6c 69 11 f0    	mov    0xf011696c,%edx
f0100f72:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	return pa2page(PTE_ADDR(*pte));
f0100f75:	eb 05                	jmp    f0100f7c <page_lookup+0x55>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
	if(!pte)
		return NULL;
f0100f77:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f0100f7c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f7f:	c9                   	leave  
f0100f80:	c3                   	ret    

f0100f81 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100f81:	55                   	push   %ebp
f0100f82:	89 e5                	mov    %esp,%ebp
f0100f84:	53                   	push   %ebx
f0100f85:	83 ec 18             	sub    $0x18,%esp
f0100f88:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	// pte_t *pte,**pte_store;
	// pte = pgdir_walk(pgdir, (void *)va, 0);
	// pte_store = &pte;
	struct PageInfo *Page;
	Page = page_lookup(pgdir, va, &pte);
f0100f8b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100f8e:	50                   	push   %eax
f0100f8f:	53                   	push   %ebx
f0100f90:	ff 75 08             	pushl  0x8(%ebp)
f0100f93:	e8 8f ff ff ff       	call   f0100f27 <page_lookup>
	// Page = page_lookup(pgdir, va, pte_store);
	if(Page){
f0100f98:	83 c4 10             	add    $0x10,%esp
f0100f9b:	85 c0                	test   %eax,%eax
f0100f9d:	74 18                	je     f0100fb7 <page_remove+0x36>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f9f:	0f 01 3b             	invlpg (%ebx)
		// Page->pp_ref --;
		tlb_invalidate(pgdir, va);
		page_decref(Page);
f0100fa2:	83 ec 0c             	sub    $0xc,%esp
f0100fa5:	50                   	push   %eax
f0100fa6:	e8 36 fe ff ff       	call   f0100de1 <page_decref>
		*pte = 0;//将对应的页表项清空
f0100fab:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100fae:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100fb4:	83 c4 10             	add    $0x10,%esp
	}
}
f0100fb7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fba:	c9                   	leave  
f0100fbb:	c3                   	ret    

f0100fbc <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100fbc:	55                   	push   %ebp
f0100fbd:	89 e5                	mov    %esp,%ebp
f0100fbf:	57                   	push   %edi
f0100fc0:	56                   	push   %esi
f0100fc1:	53                   	push   %ebx
f0100fc2:	83 ec 10             	sub    $0x10,%esp
f0100fc5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fc8:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
f0100fcb:	6a 01                	push   $0x1
f0100fcd:	57                   	push   %edi
f0100fce:	ff 75 08             	pushl  0x8(%ebp)
f0100fd1:	e8 32 fe ff ff       	call   f0100e08 <pgdir_walk>
	if(!pte)
f0100fd6:	83 c4 10             	add    $0x10,%esp
f0100fd9:	85 c0                	test   %eax,%eax
f0100fdb:	74 38                	je     f0101015 <page_insert+0x59>
f0100fdd:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	pp->pp_ref++;
f0100fdf:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	//删除旧映射关系 
    if((*pte) & PTE_P)
f0100fe4:	f6 00 01             	testb  $0x1,(%eax)
f0100fe7:	74 0f                	je     f0100ff8 <page_insert+0x3c>
        page_remove(pgdir, va);
f0100fe9:	83 ec 08             	sub    $0x8,%esp
f0100fec:	57                   	push   %edi
f0100fed:	ff 75 08             	pushl  0x8(%ebp)
f0100ff0:	e8 8c ff ff ff       	call   f0100f81 <page_remove>
f0100ff5:	83 c4 10             	add    $0x10,%esp
	//pp ->pp_ref++;
    *pte = page2pa(pp) | perm | PTE_P;
f0100ff8:	2b 1d 6c 69 11 f0    	sub    0xf011696c,%ebx
f0100ffe:	c1 fb 03             	sar    $0x3,%ebx
f0101001:	c1 e3 0c             	shl    $0xc,%ebx
f0101004:	8b 45 14             	mov    0x14(%ebp),%eax
f0101007:	83 c8 01             	or     $0x1,%eax
f010100a:	09 c3                	or     %eax,%ebx
f010100c:	89 1e                	mov    %ebx,(%esi)
	return 0;
f010100e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101013:	eb 05                	jmp    f010101a <page_insert+0x5e>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
	if(!pte)
		return -E_NO_MEM;
f0101015:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	// 		page_remove(pgdir, va); 
	// }
	// //pp->pp_ref++;
    // *pte = page2pa(pp) | perm | PTE_P;
	// return 0;
}
f010101a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010101d:	5b                   	pop    %ebx
f010101e:	5e                   	pop    %esi
f010101f:	5f                   	pop    %edi
f0101020:	5d                   	pop    %ebp
f0101021:	c3                   	ret    

f0101022 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101022:	55                   	push   %ebp
f0101023:	89 e5                	mov    %esp,%ebp
f0101025:	57                   	push   %edi
f0101026:	56                   	push   %esi
f0101027:	53                   	push   %ebx
f0101028:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010102b:	6a 15                	push   $0x15
f010102d:	e8 82 16 00 00       	call   f01026b4 <mc146818_read>
f0101032:	89 c3                	mov    %eax,%ebx
f0101034:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010103b:	e8 74 16 00 00       	call   f01026b4 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101040:	c1 e0 08             	shl    $0x8,%eax
f0101043:	09 d8                	or     %ebx,%eax
f0101045:	c1 e0 0a             	shl    $0xa,%eax
f0101048:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010104e:	85 c0                	test   %eax,%eax
f0101050:	0f 48 c2             	cmovs  %edx,%eax
f0101053:	c1 f8 0c             	sar    $0xc,%eax
f0101056:	a3 40 65 11 f0       	mov    %eax,0xf0116540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010105b:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101062:	e8 4d 16 00 00       	call   f01026b4 <mc146818_read>
f0101067:	89 c3                	mov    %eax,%ebx
f0101069:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101070:	e8 3f 16 00 00       	call   f01026b4 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101075:	c1 e0 08             	shl    $0x8,%eax
f0101078:	09 d8                	or     %ebx,%eax
f010107a:	c1 e0 0a             	shl    $0xa,%eax
f010107d:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101083:	83 c4 10             	add    $0x10,%esp
f0101086:	85 c0                	test   %eax,%eax
f0101088:	0f 48 c2             	cmovs  %edx,%eax
f010108b:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010108e:	85 c0                	test   %eax,%eax
f0101090:	74 0e                	je     f01010a0 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101092:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101098:	89 15 64 69 11 f0    	mov    %edx,0xf0116964
f010109e:	eb 0c                	jmp    f01010ac <mem_init+0x8a>
	else
		npages = npages_basemem;
f01010a0:	8b 15 40 65 11 f0    	mov    0xf0116540,%edx
f01010a6:	89 15 64 69 11 f0    	mov    %edx,0xf0116964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010ac:	c1 e0 0c             	shl    $0xc,%eax
f01010af:	c1 e8 0a             	shr    $0xa,%eax
f01010b2:	50                   	push   %eax
f01010b3:	a1 40 65 11 f0       	mov    0xf0116540,%eax
f01010b8:	c1 e0 0c             	shl    $0xc,%eax
f01010bb:	c1 e8 0a             	shr    $0xa,%eax
f01010be:	50                   	push   %eax
f01010bf:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f01010c4:	c1 e0 0c             	shl    $0xc,%eax
f01010c7:	c1 e8 0a             	shr    $0xa,%eax
f01010ca:	50                   	push   %eax
f01010cb:	68 cc 3c 10 f0       	push   $0xf0103ccc
f01010d0:	e8 46 16 00 00       	call   f010271b <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010d5:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010da:	e8 25 f8 ff ff       	call   f0100904 <boot_alloc>
f01010df:	a3 68 69 11 f0       	mov    %eax,0xf0116968
	memset(kern_pgdir, 0, PGSIZE);
f01010e4:	83 c4 0c             	add    $0xc,%esp
f01010e7:	68 00 10 00 00       	push   $0x1000
f01010ec:	6a 00                	push   $0x0
f01010ee:	50                   	push   %eax
f01010ef:	e8 db 20 00 00       	call   f01031cf <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010f4:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010f9:	83 c4 10             	add    $0x10,%esp
f01010fc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101101:	77 15                	ja     f0101118 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101103:	50                   	push   %eax
f0101104:	68 08 3d 10 f0       	push   $0xf0103d08
f0101109:	68 8d 00 00 00       	push   $0x8d
f010110e:	68 18 43 10 f0       	push   $0xf0104318
f0101113:	e8 73 ef ff ff       	call   f010008b <_panic>
f0101118:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010111e:	83 ca 05             	or     $0x5,%edx
f0101121:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f0101127:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f010112c:	c1 e0 03             	shl    $0x3,%eax
f010112f:	e8 d0 f7 ff ff       	call   f0100904 <boot_alloc>
f0101134:	a3 6c 69 11 f0       	mov    %eax,0xf011696c
	memset(pages,0,npages * sizeof(struct PageInfo));
f0101139:	83 ec 04             	sub    $0x4,%esp
f010113c:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0101142:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101149:	52                   	push   %edx
f010114a:	6a 00                	push   $0x0
f010114c:	50                   	push   %eax
f010114d:	e8 7d 20 00 00       	call   f01031cf <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101152:	e8 ff fa ff ff       	call   f0100c56 <page_init>

	check_page_free_list(1);
f0101157:	b8 01 00 00 00       	mov    $0x1,%eax
f010115c:	e8 41 f8 ff ff       	call   f01009a2 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101161:	83 c4 10             	add    $0x10,%esp
f0101164:	83 3d 6c 69 11 f0 00 	cmpl   $0x0,0xf011696c
f010116b:	75 17                	jne    f0101184 <mem_init+0x162>
		panic("'pages' is a null pointer!");
f010116d:	83 ec 04             	sub    $0x4,%esp
f0101170:	68 e7 43 10 f0       	push   $0xf01043e7
f0101175:	68 9d 02 00 00       	push   $0x29d
f010117a:	68 18 43 10 f0       	push   $0xf0104318
f010117f:	e8 07 ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101184:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101189:	bb 00 00 00 00       	mov    $0x0,%ebx
f010118e:	eb 05                	jmp    f0101195 <mem_init+0x173>
		++nfree;
f0101190:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101193:	8b 00                	mov    (%eax),%eax
f0101195:	85 c0                	test   %eax,%eax
f0101197:	75 f7                	jne    f0101190 <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101199:	83 ec 0c             	sub    $0xc,%esp
f010119c:	6a 00                	push   $0x0
f010119e:	e8 93 fb ff ff       	call   f0100d36 <page_alloc>
f01011a3:	89 c7                	mov    %eax,%edi
f01011a5:	83 c4 10             	add    $0x10,%esp
f01011a8:	85 c0                	test   %eax,%eax
f01011aa:	75 19                	jne    f01011c5 <mem_init+0x1a3>
f01011ac:	68 02 44 10 f0       	push   $0xf0104402
f01011b1:	68 3e 43 10 f0       	push   $0xf010433e
f01011b6:	68 a5 02 00 00       	push   $0x2a5
f01011bb:	68 18 43 10 f0       	push   $0xf0104318
f01011c0:	e8 c6 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01011c5:	83 ec 0c             	sub    $0xc,%esp
f01011c8:	6a 00                	push   $0x0
f01011ca:	e8 67 fb ff ff       	call   f0100d36 <page_alloc>
f01011cf:	89 c6                	mov    %eax,%esi
f01011d1:	83 c4 10             	add    $0x10,%esp
f01011d4:	85 c0                	test   %eax,%eax
f01011d6:	75 19                	jne    f01011f1 <mem_init+0x1cf>
f01011d8:	68 18 44 10 f0       	push   $0xf0104418
f01011dd:	68 3e 43 10 f0       	push   $0xf010433e
f01011e2:	68 a6 02 00 00       	push   $0x2a6
f01011e7:	68 18 43 10 f0       	push   $0xf0104318
f01011ec:	e8 9a ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01011f1:	83 ec 0c             	sub    $0xc,%esp
f01011f4:	6a 00                	push   $0x0
f01011f6:	e8 3b fb ff ff       	call   f0100d36 <page_alloc>
f01011fb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01011fe:	83 c4 10             	add    $0x10,%esp
f0101201:	85 c0                	test   %eax,%eax
f0101203:	75 19                	jne    f010121e <mem_init+0x1fc>
f0101205:	68 2e 44 10 f0       	push   $0xf010442e
f010120a:	68 3e 43 10 f0       	push   $0xf010433e
f010120f:	68 a7 02 00 00       	push   $0x2a7
f0101214:	68 18 43 10 f0       	push   $0xf0104318
f0101219:	e8 6d ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010121e:	39 f7                	cmp    %esi,%edi
f0101220:	75 19                	jne    f010123b <mem_init+0x219>
f0101222:	68 44 44 10 f0       	push   $0xf0104444
f0101227:	68 3e 43 10 f0       	push   $0xf010433e
f010122c:	68 aa 02 00 00       	push   $0x2aa
f0101231:	68 18 43 10 f0       	push   $0xf0104318
f0101236:	e8 50 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010123b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010123e:	39 c6                	cmp    %eax,%esi
f0101240:	74 04                	je     f0101246 <mem_init+0x224>
f0101242:	39 c7                	cmp    %eax,%edi
f0101244:	75 19                	jne    f010125f <mem_init+0x23d>
f0101246:	68 2c 3d 10 f0       	push   $0xf0103d2c
f010124b:	68 3e 43 10 f0       	push   $0xf010433e
f0101250:	68 ab 02 00 00       	push   $0x2ab
f0101255:	68 18 43 10 f0       	push   $0xf0104318
f010125a:	e8 2c ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010125f:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101265:	8b 15 64 69 11 f0    	mov    0xf0116964,%edx
f010126b:	c1 e2 0c             	shl    $0xc,%edx
f010126e:	89 f8                	mov    %edi,%eax
f0101270:	29 c8                	sub    %ecx,%eax
f0101272:	c1 f8 03             	sar    $0x3,%eax
f0101275:	c1 e0 0c             	shl    $0xc,%eax
f0101278:	39 d0                	cmp    %edx,%eax
f010127a:	72 19                	jb     f0101295 <mem_init+0x273>
f010127c:	68 56 44 10 f0       	push   $0xf0104456
f0101281:	68 3e 43 10 f0       	push   $0xf010433e
f0101286:	68 ac 02 00 00       	push   $0x2ac
f010128b:	68 18 43 10 f0       	push   $0xf0104318
f0101290:	e8 f6 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101295:	89 f0                	mov    %esi,%eax
f0101297:	29 c8                	sub    %ecx,%eax
f0101299:	c1 f8 03             	sar    $0x3,%eax
f010129c:	c1 e0 0c             	shl    $0xc,%eax
f010129f:	39 c2                	cmp    %eax,%edx
f01012a1:	77 19                	ja     f01012bc <mem_init+0x29a>
f01012a3:	68 73 44 10 f0       	push   $0xf0104473
f01012a8:	68 3e 43 10 f0       	push   $0xf010433e
f01012ad:	68 ad 02 00 00       	push   $0x2ad
f01012b2:	68 18 43 10 f0       	push   $0xf0104318
f01012b7:	e8 cf ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012bc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012bf:	29 c8                	sub    %ecx,%eax
f01012c1:	c1 f8 03             	sar    $0x3,%eax
f01012c4:	c1 e0 0c             	shl    $0xc,%eax
f01012c7:	39 c2                	cmp    %eax,%edx
f01012c9:	77 19                	ja     f01012e4 <mem_init+0x2c2>
f01012cb:	68 90 44 10 f0       	push   $0xf0104490
f01012d0:	68 3e 43 10 f0       	push   $0xf010433e
f01012d5:	68 ae 02 00 00       	push   $0x2ae
f01012da:	68 18 43 10 f0       	push   $0xf0104318
f01012df:	e8 a7 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012e4:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01012e9:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01012ec:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01012f3:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01012f6:	83 ec 0c             	sub    $0xc,%esp
f01012f9:	6a 00                	push   $0x0
f01012fb:	e8 36 fa ff ff       	call   f0100d36 <page_alloc>
f0101300:	83 c4 10             	add    $0x10,%esp
f0101303:	85 c0                	test   %eax,%eax
f0101305:	74 19                	je     f0101320 <mem_init+0x2fe>
f0101307:	68 ad 44 10 f0       	push   $0xf01044ad
f010130c:	68 3e 43 10 f0       	push   $0xf010433e
f0101311:	68 b5 02 00 00       	push   $0x2b5
f0101316:	68 18 43 10 f0       	push   $0xf0104318
f010131b:	e8 6b ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101320:	83 ec 0c             	sub    $0xc,%esp
f0101323:	57                   	push   %edi
f0101324:	e8 93 fa ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f0101329:	89 34 24             	mov    %esi,(%esp)
f010132c:	e8 8b fa ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f0101331:	83 c4 04             	add    $0x4,%esp
f0101334:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101337:	e8 80 fa ff ff       	call   f0100dbc <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010133c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101343:	e8 ee f9 ff ff       	call   f0100d36 <page_alloc>
f0101348:	89 c6                	mov    %eax,%esi
f010134a:	83 c4 10             	add    $0x10,%esp
f010134d:	85 c0                	test   %eax,%eax
f010134f:	75 19                	jne    f010136a <mem_init+0x348>
f0101351:	68 02 44 10 f0       	push   $0xf0104402
f0101356:	68 3e 43 10 f0       	push   $0xf010433e
f010135b:	68 bc 02 00 00       	push   $0x2bc
f0101360:	68 18 43 10 f0       	push   $0xf0104318
f0101365:	e8 21 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010136a:	83 ec 0c             	sub    $0xc,%esp
f010136d:	6a 00                	push   $0x0
f010136f:	e8 c2 f9 ff ff       	call   f0100d36 <page_alloc>
f0101374:	89 c7                	mov    %eax,%edi
f0101376:	83 c4 10             	add    $0x10,%esp
f0101379:	85 c0                	test   %eax,%eax
f010137b:	75 19                	jne    f0101396 <mem_init+0x374>
f010137d:	68 18 44 10 f0       	push   $0xf0104418
f0101382:	68 3e 43 10 f0       	push   $0xf010433e
f0101387:	68 bd 02 00 00       	push   $0x2bd
f010138c:	68 18 43 10 f0       	push   $0xf0104318
f0101391:	e8 f5 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101396:	83 ec 0c             	sub    $0xc,%esp
f0101399:	6a 00                	push   $0x0
f010139b:	e8 96 f9 ff ff       	call   f0100d36 <page_alloc>
f01013a0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013a3:	83 c4 10             	add    $0x10,%esp
f01013a6:	85 c0                	test   %eax,%eax
f01013a8:	75 19                	jne    f01013c3 <mem_init+0x3a1>
f01013aa:	68 2e 44 10 f0       	push   $0xf010442e
f01013af:	68 3e 43 10 f0       	push   $0xf010433e
f01013b4:	68 be 02 00 00       	push   $0x2be
f01013b9:	68 18 43 10 f0       	push   $0xf0104318
f01013be:	e8 c8 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013c3:	39 fe                	cmp    %edi,%esi
f01013c5:	75 19                	jne    f01013e0 <mem_init+0x3be>
f01013c7:	68 44 44 10 f0       	push   $0xf0104444
f01013cc:	68 3e 43 10 f0       	push   $0xf010433e
f01013d1:	68 c0 02 00 00       	push   $0x2c0
f01013d6:	68 18 43 10 f0       	push   $0xf0104318
f01013db:	e8 ab ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013e0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013e3:	39 c7                	cmp    %eax,%edi
f01013e5:	74 04                	je     f01013eb <mem_init+0x3c9>
f01013e7:	39 c6                	cmp    %eax,%esi
f01013e9:	75 19                	jne    f0101404 <mem_init+0x3e2>
f01013eb:	68 2c 3d 10 f0       	push   $0xf0103d2c
f01013f0:	68 3e 43 10 f0       	push   $0xf010433e
f01013f5:	68 c1 02 00 00       	push   $0x2c1
f01013fa:	68 18 43 10 f0       	push   $0xf0104318
f01013ff:	e8 87 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101404:	83 ec 0c             	sub    $0xc,%esp
f0101407:	6a 00                	push   $0x0
f0101409:	e8 28 f9 ff ff       	call   f0100d36 <page_alloc>
f010140e:	83 c4 10             	add    $0x10,%esp
f0101411:	85 c0                	test   %eax,%eax
f0101413:	74 19                	je     f010142e <mem_init+0x40c>
f0101415:	68 ad 44 10 f0       	push   $0xf01044ad
f010141a:	68 3e 43 10 f0       	push   $0xf010433e
f010141f:	68 c2 02 00 00       	push   $0x2c2
f0101424:	68 18 43 10 f0       	push   $0xf0104318
f0101429:	e8 5d ec ff ff       	call   f010008b <_panic>
f010142e:	89 f0                	mov    %esi,%eax
f0101430:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101436:	c1 f8 03             	sar    $0x3,%eax
f0101439:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010143c:	89 c2                	mov    %eax,%edx
f010143e:	c1 ea 0c             	shr    $0xc,%edx
f0101441:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0101447:	72 12                	jb     f010145b <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101449:	50                   	push   %eax
f010144a:	68 c4 3b 10 f0       	push   $0xf0103bc4
f010144f:	6a 52                	push   $0x52
f0101451:	68 24 43 10 f0       	push   $0xf0104324
f0101456:	e8 30 ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010145b:	83 ec 04             	sub    $0x4,%esp
f010145e:	68 00 10 00 00       	push   $0x1000
f0101463:	6a 01                	push   $0x1
f0101465:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010146a:	50                   	push   %eax
f010146b:	e8 5f 1d 00 00       	call   f01031cf <memset>
	page_free(pp0);
f0101470:	89 34 24             	mov    %esi,(%esp)
f0101473:	e8 44 f9 ff ff       	call   f0100dbc <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101478:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010147f:	e8 b2 f8 ff ff       	call   f0100d36 <page_alloc>
f0101484:	83 c4 10             	add    $0x10,%esp
f0101487:	85 c0                	test   %eax,%eax
f0101489:	75 19                	jne    f01014a4 <mem_init+0x482>
f010148b:	68 bc 44 10 f0       	push   $0xf01044bc
f0101490:	68 3e 43 10 f0       	push   $0xf010433e
f0101495:	68 c7 02 00 00       	push   $0x2c7
f010149a:	68 18 43 10 f0       	push   $0xf0104318
f010149f:	e8 e7 eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01014a4:	39 c6                	cmp    %eax,%esi
f01014a6:	74 19                	je     f01014c1 <mem_init+0x49f>
f01014a8:	68 da 44 10 f0       	push   $0xf01044da
f01014ad:	68 3e 43 10 f0       	push   $0xf010433e
f01014b2:	68 c8 02 00 00       	push   $0x2c8
f01014b7:	68 18 43 10 f0       	push   $0xf0104318
f01014bc:	e8 ca eb ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014c1:	89 f0                	mov    %esi,%eax
f01014c3:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01014c9:	c1 f8 03             	sar    $0x3,%eax
f01014cc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014cf:	89 c2                	mov    %eax,%edx
f01014d1:	c1 ea 0c             	shr    $0xc,%edx
f01014d4:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01014da:	72 12                	jb     f01014ee <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014dc:	50                   	push   %eax
f01014dd:	68 c4 3b 10 f0       	push   $0xf0103bc4
f01014e2:	6a 52                	push   $0x52
f01014e4:	68 24 43 10 f0       	push   $0xf0104324
f01014e9:	e8 9d eb ff ff       	call   f010008b <_panic>
f01014ee:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01014f4:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014fa:	80 38 00             	cmpb   $0x0,(%eax)
f01014fd:	74 19                	je     f0101518 <mem_init+0x4f6>
f01014ff:	68 ea 44 10 f0       	push   $0xf01044ea
f0101504:	68 3e 43 10 f0       	push   $0xf010433e
f0101509:	68 cb 02 00 00       	push   $0x2cb
f010150e:	68 18 43 10 f0       	push   $0xf0104318
f0101513:	e8 73 eb ff ff       	call   f010008b <_panic>
f0101518:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010151b:	39 d0                	cmp    %edx,%eax
f010151d:	75 db                	jne    f01014fa <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010151f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101522:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f0101527:	83 ec 0c             	sub    $0xc,%esp
f010152a:	56                   	push   %esi
f010152b:	e8 8c f8 ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f0101530:	89 3c 24             	mov    %edi,(%esp)
f0101533:	e8 84 f8 ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f0101538:	83 c4 04             	add    $0x4,%esp
f010153b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010153e:	e8 79 f8 ff ff       	call   f0100dbc <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101543:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101548:	83 c4 10             	add    $0x10,%esp
f010154b:	eb 05                	jmp    f0101552 <mem_init+0x530>
		--nfree;
f010154d:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101550:	8b 00                	mov    (%eax),%eax
f0101552:	85 c0                	test   %eax,%eax
f0101554:	75 f7                	jne    f010154d <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f0101556:	85 db                	test   %ebx,%ebx
f0101558:	74 19                	je     f0101573 <mem_init+0x551>
f010155a:	68 f4 44 10 f0       	push   $0xf01044f4
f010155f:	68 3e 43 10 f0       	push   $0xf010433e
f0101564:	68 d8 02 00 00       	push   $0x2d8
f0101569:	68 18 43 10 f0       	push   $0xf0104318
f010156e:	e8 18 eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101573:	83 ec 0c             	sub    $0xc,%esp
f0101576:	68 4c 3d 10 f0       	push   $0xf0103d4c
f010157b:	e8 9b 11 00 00       	call   f010271b <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101580:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101587:	e8 aa f7 ff ff       	call   f0100d36 <page_alloc>
f010158c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010158f:	83 c4 10             	add    $0x10,%esp
f0101592:	85 c0                	test   %eax,%eax
f0101594:	75 19                	jne    f01015af <mem_init+0x58d>
f0101596:	68 02 44 10 f0       	push   $0xf0104402
f010159b:	68 3e 43 10 f0       	push   $0xf010433e
f01015a0:	68 31 03 00 00       	push   $0x331
f01015a5:	68 18 43 10 f0       	push   $0xf0104318
f01015aa:	e8 dc ea ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01015af:	83 ec 0c             	sub    $0xc,%esp
f01015b2:	6a 00                	push   $0x0
f01015b4:	e8 7d f7 ff ff       	call   f0100d36 <page_alloc>
f01015b9:	89 c3                	mov    %eax,%ebx
f01015bb:	83 c4 10             	add    $0x10,%esp
f01015be:	85 c0                	test   %eax,%eax
f01015c0:	75 19                	jne    f01015db <mem_init+0x5b9>
f01015c2:	68 18 44 10 f0       	push   $0xf0104418
f01015c7:	68 3e 43 10 f0       	push   $0xf010433e
f01015cc:	68 32 03 00 00       	push   $0x332
f01015d1:	68 18 43 10 f0       	push   $0xf0104318
f01015d6:	e8 b0 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01015db:	83 ec 0c             	sub    $0xc,%esp
f01015de:	6a 00                	push   $0x0
f01015e0:	e8 51 f7 ff ff       	call   f0100d36 <page_alloc>
f01015e5:	89 c6                	mov    %eax,%esi
f01015e7:	83 c4 10             	add    $0x10,%esp
f01015ea:	85 c0                	test   %eax,%eax
f01015ec:	75 19                	jne    f0101607 <mem_init+0x5e5>
f01015ee:	68 2e 44 10 f0       	push   $0xf010442e
f01015f3:	68 3e 43 10 f0       	push   $0xf010433e
f01015f8:	68 33 03 00 00       	push   $0x333
f01015fd:	68 18 43 10 f0       	push   $0xf0104318
f0101602:	e8 84 ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101607:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010160a:	75 19                	jne    f0101625 <mem_init+0x603>
f010160c:	68 44 44 10 f0       	push   $0xf0104444
f0101611:	68 3e 43 10 f0       	push   $0xf010433e
f0101616:	68 36 03 00 00       	push   $0x336
f010161b:	68 18 43 10 f0       	push   $0xf0104318
f0101620:	e8 66 ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101625:	39 c3                	cmp    %eax,%ebx
f0101627:	74 05                	je     f010162e <mem_init+0x60c>
f0101629:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010162c:	75 19                	jne    f0101647 <mem_init+0x625>
f010162e:	68 2c 3d 10 f0       	push   $0xf0103d2c
f0101633:	68 3e 43 10 f0       	push   $0xf010433e
f0101638:	68 37 03 00 00       	push   $0x337
f010163d:	68 18 43 10 f0       	push   $0xf0104318
f0101642:	e8 44 ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101647:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010164c:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010164f:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0101656:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101659:	83 ec 0c             	sub    $0xc,%esp
f010165c:	6a 00                	push   $0x0
f010165e:	e8 d3 f6 ff ff       	call   f0100d36 <page_alloc>
f0101663:	83 c4 10             	add    $0x10,%esp
f0101666:	85 c0                	test   %eax,%eax
f0101668:	74 19                	je     f0101683 <mem_init+0x661>
f010166a:	68 ad 44 10 f0       	push   $0xf01044ad
f010166f:	68 3e 43 10 f0       	push   $0xf010433e
f0101674:	68 3e 03 00 00       	push   $0x33e
f0101679:	68 18 43 10 f0       	push   $0xf0104318
f010167e:	e8 08 ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101683:	83 ec 04             	sub    $0x4,%esp
f0101686:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101689:	50                   	push   %eax
f010168a:	6a 00                	push   $0x0
f010168c:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101692:	e8 90 f8 ff ff       	call   f0100f27 <page_lookup>
f0101697:	83 c4 10             	add    $0x10,%esp
f010169a:	85 c0                	test   %eax,%eax
f010169c:	74 19                	je     f01016b7 <mem_init+0x695>
f010169e:	68 6c 3d 10 f0       	push   $0xf0103d6c
f01016a3:	68 3e 43 10 f0       	push   $0xf010433e
f01016a8:	68 41 03 00 00       	push   $0x341
f01016ad:	68 18 43 10 f0       	push   $0xf0104318
f01016b2:	e8 d4 e9 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016b7:	6a 02                	push   $0x2
f01016b9:	6a 00                	push   $0x0
f01016bb:	53                   	push   %ebx
f01016bc:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01016c2:	e8 f5 f8 ff ff       	call   f0100fbc <page_insert>
f01016c7:	83 c4 10             	add    $0x10,%esp
f01016ca:	85 c0                	test   %eax,%eax
f01016cc:	78 19                	js     f01016e7 <mem_init+0x6c5>
f01016ce:	68 a4 3d 10 f0       	push   $0xf0103da4
f01016d3:	68 3e 43 10 f0       	push   $0xf010433e
f01016d8:	68 44 03 00 00       	push   $0x344
f01016dd:	68 18 43 10 f0       	push   $0xf0104318
f01016e2:	e8 a4 e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01016e7:	83 ec 0c             	sub    $0xc,%esp
f01016ea:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016ed:	e8 ca f6 ff ff       	call   f0100dbc <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01016f2:	6a 02                	push   $0x2
f01016f4:	6a 00                	push   $0x0
f01016f6:	53                   	push   %ebx
f01016f7:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01016fd:	e8 ba f8 ff ff       	call   f0100fbc <page_insert>
f0101702:	83 c4 20             	add    $0x20,%esp
f0101705:	85 c0                	test   %eax,%eax
f0101707:	74 19                	je     f0101722 <mem_init+0x700>
f0101709:	68 d4 3d 10 f0       	push   $0xf0103dd4
f010170e:	68 3e 43 10 f0       	push   $0xf010433e
f0101713:	68 48 03 00 00       	push   $0x348
f0101718:	68 18 43 10 f0       	push   $0xf0104318
f010171d:	e8 69 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101722:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101728:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f010172d:	89 c1                	mov    %eax,%ecx
f010172f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101732:	8b 17                	mov    (%edi),%edx
f0101734:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010173a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010173d:	29 c8                	sub    %ecx,%eax
f010173f:	c1 f8 03             	sar    $0x3,%eax
f0101742:	c1 e0 0c             	shl    $0xc,%eax
f0101745:	39 c2                	cmp    %eax,%edx
f0101747:	74 19                	je     f0101762 <mem_init+0x740>
f0101749:	68 04 3e 10 f0       	push   $0xf0103e04
f010174e:	68 3e 43 10 f0       	push   $0xf010433e
f0101753:	68 49 03 00 00       	push   $0x349
f0101758:	68 18 43 10 f0       	push   $0xf0104318
f010175d:	e8 29 e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101762:	ba 00 00 00 00       	mov    $0x0,%edx
f0101767:	89 f8                	mov    %edi,%eax
f0101769:	e8 d0 f1 ff ff       	call   f010093e <check_va2pa>
f010176e:	89 da                	mov    %ebx,%edx
f0101770:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101773:	c1 fa 03             	sar    $0x3,%edx
f0101776:	c1 e2 0c             	shl    $0xc,%edx
f0101779:	39 d0                	cmp    %edx,%eax
f010177b:	74 19                	je     f0101796 <mem_init+0x774>
f010177d:	68 2c 3e 10 f0       	push   $0xf0103e2c
f0101782:	68 3e 43 10 f0       	push   $0xf010433e
f0101787:	68 4a 03 00 00       	push   $0x34a
f010178c:	68 18 43 10 f0       	push   $0xf0104318
f0101791:	e8 f5 e8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101796:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010179b:	74 19                	je     f01017b6 <mem_init+0x794>
f010179d:	68 ff 44 10 f0       	push   $0xf01044ff
f01017a2:	68 3e 43 10 f0       	push   $0xf010433e
f01017a7:	68 4b 03 00 00       	push   $0x34b
f01017ac:	68 18 43 10 f0       	push   $0xf0104318
f01017b1:	e8 d5 e8 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01017b6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017b9:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01017be:	74 19                	je     f01017d9 <mem_init+0x7b7>
f01017c0:	68 10 45 10 f0       	push   $0xf0104510
f01017c5:	68 3e 43 10 f0       	push   $0xf010433e
f01017ca:	68 4c 03 00 00       	push   $0x34c
f01017cf:	68 18 43 10 f0       	push   $0xf0104318
f01017d4:	e8 b2 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01017d9:	6a 02                	push   $0x2
f01017db:	68 00 10 00 00       	push   $0x1000
f01017e0:	56                   	push   %esi
f01017e1:	57                   	push   %edi
f01017e2:	e8 d5 f7 ff ff       	call   f0100fbc <page_insert>
f01017e7:	83 c4 10             	add    $0x10,%esp
f01017ea:	85 c0                	test   %eax,%eax
f01017ec:	74 19                	je     f0101807 <mem_init+0x7e5>
f01017ee:	68 5c 3e 10 f0       	push   $0xf0103e5c
f01017f3:	68 3e 43 10 f0       	push   $0xf010433e
f01017f8:	68 4f 03 00 00       	push   $0x34f
f01017fd:	68 18 43 10 f0       	push   $0xf0104318
f0101802:	e8 84 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101807:	ba 00 10 00 00       	mov    $0x1000,%edx
f010180c:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101811:	e8 28 f1 ff ff       	call   f010093e <check_va2pa>
f0101816:	89 f2                	mov    %esi,%edx
f0101818:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f010181e:	c1 fa 03             	sar    $0x3,%edx
f0101821:	c1 e2 0c             	shl    $0xc,%edx
f0101824:	39 d0                	cmp    %edx,%eax
f0101826:	74 19                	je     f0101841 <mem_init+0x81f>
f0101828:	68 98 3e 10 f0       	push   $0xf0103e98
f010182d:	68 3e 43 10 f0       	push   $0xf010433e
f0101832:	68 50 03 00 00       	push   $0x350
f0101837:	68 18 43 10 f0       	push   $0xf0104318
f010183c:	e8 4a e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101841:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101846:	74 19                	je     f0101861 <mem_init+0x83f>
f0101848:	68 21 45 10 f0       	push   $0xf0104521
f010184d:	68 3e 43 10 f0       	push   $0xf010433e
f0101852:	68 51 03 00 00       	push   $0x351
f0101857:	68 18 43 10 f0       	push   $0xf0104318
f010185c:	e8 2a e8 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101861:	83 ec 0c             	sub    $0xc,%esp
f0101864:	6a 00                	push   $0x0
f0101866:	e8 cb f4 ff ff       	call   f0100d36 <page_alloc>
f010186b:	83 c4 10             	add    $0x10,%esp
f010186e:	85 c0                	test   %eax,%eax
f0101870:	74 19                	je     f010188b <mem_init+0x869>
f0101872:	68 ad 44 10 f0       	push   $0xf01044ad
f0101877:	68 3e 43 10 f0       	push   $0xf010433e
f010187c:	68 54 03 00 00       	push   $0x354
f0101881:	68 18 43 10 f0       	push   $0xf0104318
f0101886:	e8 00 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010188b:	6a 02                	push   $0x2
f010188d:	68 00 10 00 00       	push   $0x1000
f0101892:	56                   	push   %esi
f0101893:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101899:	e8 1e f7 ff ff       	call   f0100fbc <page_insert>
f010189e:	83 c4 10             	add    $0x10,%esp
f01018a1:	85 c0                	test   %eax,%eax
f01018a3:	74 19                	je     f01018be <mem_init+0x89c>
f01018a5:	68 5c 3e 10 f0       	push   $0xf0103e5c
f01018aa:	68 3e 43 10 f0       	push   $0xf010433e
f01018af:	68 57 03 00 00       	push   $0x357
f01018b4:	68 18 43 10 f0       	push   $0xf0104318
f01018b9:	e8 cd e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018be:	ba 00 10 00 00       	mov    $0x1000,%edx
f01018c3:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01018c8:	e8 71 f0 ff ff       	call   f010093e <check_va2pa>
f01018cd:	89 f2                	mov    %esi,%edx
f01018cf:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01018d5:	c1 fa 03             	sar    $0x3,%edx
f01018d8:	c1 e2 0c             	shl    $0xc,%edx
f01018db:	39 d0                	cmp    %edx,%eax
f01018dd:	74 19                	je     f01018f8 <mem_init+0x8d6>
f01018df:	68 98 3e 10 f0       	push   $0xf0103e98
f01018e4:	68 3e 43 10 f0       	push   $0xf010433e
f01018e9:	68 58 03 00 00       	push   $0x358
f01018ee:	68 18 43 10 f0       	push   $0xf0104318
f01018f3:	e8 93 e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01018f8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018fd:	74 19                	je     f0101918 <mem_init+0x8f6>
f01018ff:	68 21 45 10 f0       	push   $0xf0104521
f0101904:	68 3e 43 10 f0       	push   $0xf010433e
f0101909:	68 59 03 00 00       	push   $0x359
f010190e:	68 18 43 10 f0       	push   $0xf0104318
f0101913:	e8 73 e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101918:	83 ec 0c             	sub    $0xc,%esp
f010191b:	6a 00                	push   $0x0
f010191d:	e8 14 f4 ff ff       	call   f0100d36 <page_alloc>
f0101922:	83 c4 10             	add    $0x10,%esp
f0101925:	85 c0                	test   %eax,%eax
f0101927:	74 19                	je     f0101942 <mem_init+0x920>
f0101929:	68 ad 44 10 f0       	push   $0xf01044ad
f010192e:	68 3e 43 10 f0       	push   $0xf010433e
f0101933:	68 5d 03 00 00       	push   $0x35d
f0101938:	68 18 43 10 f0       	push   $0xf0104318
f010193d:	e8 49 e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101942:	8b 15 68 69 11 f0    	mov    0xf0116968,%edx
f0101948:	8b 02                	mov    (%edx),%eax
f010194a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010194f:	89 c1                	mov    %eax,%ecx
f0101951:	c1 e9 0c             	shr    $0xc,%ecx
f0101954:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f010195a:	72 15                	jb     f0101971 <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010195c:	50                   	push   %eax
f010195d:	68 c4 3b 10 f0       	push   $0xf0103bc4
f0101962:	68 60 03 00 00       	push   $0x360
f0101967:	68 18 43 10 f0       	push   $0xf0104318
f010196c:	e8 1a e7 ff ff       	call   f010008b <_panic>
f0101971:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101976:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101979:	83 ec 04             	sub    $0x4,%esp
f010197c:	6a 00                	push   $0x0
f010197e:	68 00 10 00 00       	push   $0x1000
f0101983:	52                   	push   %edx
f0101984:	e8 7f f4 ff ff       	call   f0100e08 <pgdir_walk>
f0101989:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010198c:	8d 51 04             	lea    0x4(%ecx),%edx
f010198f:	83 c4 10             	add    $0x10,%esp
f0101992:	39 d0                	cmp    %edx,%eax
f0101994:	74 19                	je     f01019af <mem_init+0x98d>
f0101996:	68 c8 3e 10 f0       	push   $0xf0103ec8
f010199b:	68 3e 43 10 f0       	push   $0xf010433e
f01019a0:	68 61 03 00 00       	push   $0x361
f01019a5:	68 18 43 10 f0       	push   $0xf0104318
f01019aa:	e8 dc e6 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019af:	6a 06                	push   $0x6
f01019b1:	68 00 10 00 00       	push   $0x1000
f01019b6:	56                   	push   %esi
f01019b7:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01019bd:	e8 fa f5 ff ff       	call   f0100fbc <page_insert>
f01019c2:	83 c4 10             	add    $0x10,%esp
f01019c5:	85 c0                	test   %eax,%eax
f01019c7:	74 19                	je     f01019e2 <mem_init+0x9c0>
f01019c9:	68 08 3f 10 f0       	push   $0xf0103f08
f01019ce:	68 3e 43 10 f0       	push   $0xf010433e
f01019d3:	68 64 03 00 00       	push   $0x364
f01019d8:	68 18 43 10 f0       	push   $0xf0104318
f01019dd:	e8 a9 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019e2:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f01019e8:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019ed:	89 f8                	mov    %edi,%eax
f01019ef:	e8 4a ef ff ff       	call   f010093e <check_va2pa>
f01019f4:	89 f2                	mov    %esi,%edx
f01019f6:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01019fc:	c1 fa 03             	sar    $0x3,%edx
f01019ff:	c1 e2 0c             	shl    $0xc,%edx
f0101a02:	39 d0                	cmp    %edx,%eax
f0101a04:	74 19                	je     f0101a1f <mem_init+0x9fd>
f0101a06:	68 98 3e 10 f0       	push   $0xf0103e98
f0101a0b:	68 3e 43 10 f0       	push   $0xf010433e
f0101a10:	68 65 03 00 00       	push   $0x365
f0101a15:	68 18 43 10 f0       	push   $0xf0104318
f0101a1a:	e8 6c e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a1f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a24:	74 19                	je     f0101a3f <mem_init+0xa1d>
f0101a26:	68 21 45 10 f0       	push   $0xf0104521
f0101a2b:	68 3e 43 10 f0       	push   $0xf010433e
f0101a30:	68 66 03 00 00       	push   $0x366
f0101a35:	68 18 43 10 f0       	push   $0xf0104318
f0101a3a:	e8 4c e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a3f:	83 ec 04             	sub    $0x4,%esp
f0101a42:	6a 00                	push   $0x0
f0101a44:	68 00 10 00 00       	push   $0x1000
f0101a49:	57                   	push   %edi
f0101a4a:	e8 b9 f3 ff ff       	call   f0100e08 <pgdir_walk>
f0101a4f:	83 c4 10             	add    $0x10,%esp
f0101a52:	f6 00 04             	testb  $0x4,(%eax)
f0101a55:	75 19                	jne    f0101a70 <mem_init+0xa4e>
f0101a57:	68 48 3f 10 f0       	push   $0xf0103f48
f0101a5c:	68 3e 43 10 f0       	push   $0xf010433e
f0101a61:	68 67 03 00 00       	push   $0x367
f0101a66:	68 18 43 10 f0       	push   $0xf0104318
f0101a6b:	e8 1b e6 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a70:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101a75:	f6 00 04             	testb  $0x4,(%eax)
f0101a78:	75 19                	jne    f0101a93 <mem_init+0xa71>
f0101a7a:	68 32 45 10 f0       	push   $0xf0104532
f0101a7f:	68 3e 43 10 f0       	push   $0xf010433e
f0101a84:	68 68 03 00 00       	push   $0x368
f0101a89:	68 18 43 10 f0       	push   $0xf0104318
f0101a8e:	e8 f8 e5 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a93:	6a 02                	push   $0x2
f0101a95:	68 00 10 00 00       	push   $0x1000
f0101a9a:	56                   	push   %esi
f0101a9b:	50                   	push   %eax
f0101a9c:	e8 1b f5 ff ff       	call   f0100fbc <page_insert>
f0101aa1:	83 c4 10             	add    $0x10,%esp
f0101aa4:	85 c0                	test   %eax,%eax
f0101aa6:	74 19                	je     f0101ac1 <mem_init+0xa9f>
f0101aa8:	68 5c 3e 10 f0       	push   $0xf0103e5c
f0101aad:	68 3e 43 10 f0       	push   $0xf010433e
f0101ab2:	68 6b 03 00 00       	push   $0x36b
f0101ab7:	68 18 43 10 f0       	push   $0xf0104318
f0101abc:	e8 ca e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ac1:	83 ec 04             	sub    $0x4,%esp
f0101ac4:	6a 00                	push   $0x0
f0101ac6:	68 00 10 00 00       	push   $0x1000
f0101acb:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ad1:	e8 32 f3 ff ff       	call   f0100e08 <pgdir_walk>
f0101ad6:	83 c4 10             	add    $0x10,%esp
f0101ad9:	f6 00 02             	testb  $0x2,(%eax)
f0101adc:	75 19                	jne    f0101af7 <mem_init+0xad5>
f0101ade:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0101ae3:	68 3e 43 10 f0       	push   $0xf010433e
f0101ae8:	68 6c 03 00 00       	push   $0x36c
f0101aed:	68 18 43 10 f0       	push   $0xf0104318
f0101af2:	e8 94 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101af7:	83 ec 04             	sub    $0x4,%esp
f0101afa:	6a 00                	push   $0x0
f0101afc:	68 00 10 00 00       	push   $0x1000
f0101b01:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b07:	e8 fc f2 ff ff       	call   f0100e08 <pgdir_walk>
f0101b0c:	83 c4 10             	add    $0x10,%esp
f0101b0f:	f6 00 04             	testb  $0x4,(%eax)
f0101b12:	74 19                	je     f0101b2d <mem_init+0xb0b>
f0101b14:	68 b0 3f 10 f0       	push   $0xf0103fb0
f0101b19:	68 3e 43 10 f0       	push   $0xf010433e
f0101b1e:	68 6d 03 00 00       	push   $0x36d
f0101b23:	68 18 43 10 f0       	push   $0xf0104318
f0101b28:	e8 5e e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b2d:	6a 02                	push   $0x2
f0101b2f:	68 00 00 40 00       	push   $0x400000
f0101b34:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b37:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b3d:	e8 7a f4 ff ff       	call   f0100fbc <page_insert>
f0101b42:	83 c4 10             	add    $0x10,%esp
f0101b45:	85 c0                	test   %eax,%eax
f0101b47:	78 19                	js     f0101b62 <mem_init+0xb40>
f0101b49:	68 e8 3f 10 f0       	push   $0xf0103fe8
f0101b4e:	68 3e 43 10 f0       	push   $0xf010433e
f0101b53:	68 70 03 00 00       	push   $0x370
f0101b58:	68 18 43 10 f0       	push   $0xf0104318
f0101b5d:	e8 29 e5 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b62:	6a 02                	push   $0x2
f0101b64:	68 00 10 00 00       	push   $0x1000
f0101b69:	53                   	push   %ebx
f0101b6a:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b70:	e8 47 f4 ff ff       	call   f0100fbc <page_insert>
f0101b75:	83 c4 10             	add    $0x10,%esp
f0101b78:	85 c0                	test   %eax,%eax
f0101b7a:	74 19                	je     f0101b95 <mem_init+0xb73>
f0101b7c:	68 20 40 10 f0       	push   $0xf0104020
f0101b81:	68 3e 43 10 f0       	push   $0xf010433e
f0101b86:	68 73 03 00 00       	push   $0x373
f0101b8b:	68 18 43 10 f0       	push   $0xf0104318
f0101b90:	e8 f6 e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b95:	83 ec 04             	sub    $0x4,%esp
f0101b98:	6a 00                	push   $0x0
f0101b9a:	68 00 10 00 00       	push   $0x1000
f0101b9f:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ba5:	e8 5e f2 ff ff       	call   f0100e08 <pgdir_walk>
f0101baa:	83 c4 10             	add    $0x10,%esp
f0101bad:	f6 00 04             	testb  $0x4,(%eax)
f0101bb0:	74 19                	je     f0101bcb <mem_init+0xba9>
f0101bb2:	68 b0 3f 10 f0       	push   $0xf0103fb0
f0101bb7:	68 3e 43 10 f0       	push   $0xf010433e
f0101bbc:	68 74 03 00 00       	push   $0x374
f0101bc1:	68 18 43 10 f0       	push   $0xf0104318
f0101bc6:	e8 c0 e4 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101bcb:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101bd1:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bd6:	89 f8                	mov    %edi,%eax
f0101bd8:	e8 61 ed ff ff       	call   f010093e <check_va2pa>
f0101bdd:	89 c1                	mov    %eax,%ecx
f0101bdf:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101be2:	89 d8                	mov    %ebx,%eax
f0101be4:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101bea:	c1 f8 03             	sar    $0x3,%eax
f0101bed:	c1 e0 0c             	shl    $0xc,%eax
f0101bf0:	39 c1                	cmp    %eax,%ecx
f0101bf2:	74 19                	je     f0101c0d <mem_init+0xbeb>
f0101bf4:	68 5c 40 10 f0       	push   $0xf010405c
f0101bf9:	68 3e 43 10 f0       	push   $0xf010433e
f0101bfe:	68 77 03 00 00       	push   $0x377
f0101c03:	68 18 43 10 f0       	push   $0xf0104318
f0101c08:	e8 7e e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c0d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c12:	89 f8                	mov    %edi,%eax
f0101c14:	e8 25 ed ff ff       	call   f010093e <check_va2pa>
f0101c19:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c1c:	74 19                	je     f0101c37 <mem_init+0xc15>
f0101c1e:	68 88 40 10 f0       	push   $0xf0104088
f0101c23:	68 3e 43 10 f0       	push   $0xf010433e
f0101c28:	68 78 03 00 00       	push   $0x378
f0101c2d:	68 18 43 10 f0       	push   $0xf0104318
f0101c32:	e8 54 e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c37:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c3c:	74 19                	je     f0101c57 <mem_init+0xc35>
f0101c3e:	68 48 45 10 f0       	push   $0xf0104548
f0101c43:	68 3e 43 10 f0       	push   $0xf010433e
f0101c48:	68 7a 03 00 00       	push   $0x37a
f0101c4d:	68 18 43 10 f0       	push   $0xf0104318
f0101c52:	e8 34 e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101c57:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c5c:	74 19                	je     f0101c77 <mem_init+0xc55>
f0101c5e:	68 59 45 10 f0       	push   $0xf0104559
f0101c63:	68 3e 43 10 f0       	push   $0xf010433e
f0101c68:	68 7b 03 00 00       	push   $0x37b
f0101c6d:	68 18 43 10 f0       	push   $0xf0104318
f0101c72:	e8 14 e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c77:	83 ec 0c             	sub    $0xc,%esp
f0101c7a:	6a 00                	push   $0x0
f0101c7c:	e8 b5 f0 ff ff       	call   f0100d36 <page_alloc>
f0101c81:	83 c4 10             	add    $0x10,%esp
f0101c84:	85 c0                	test   %eax,%eax
f0101c86:	74 04                	je     f0101c8c <mem_init+0xc6a>
f0101c88:	39 c6                	cmp    %eax,%esi
f0101c8a:	74 19                	je     f0101ca5 <mem_init+0xc83>
f0101c8c:	68 b8 40 10 f0       	push   $0xf01040b8
f0101c91:	68 3e 43 10 f0       	push   $0xf010433e
f0101c96:	68 7e 03 00 00       	push   $0x37e
f0101c9b:	68 18 43 10 f0       	push   $0xf0104318
f0101ca0:	e8 e6 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ca5:	83 ec 08             	sub    $0x8,%esp
f0101ca8:	6a 00                	push   $0x0
f0101caa:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101cb0:	e8 cc f2 ff ff       	call   f0100f81 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cb5:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101cbb:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cc0:	89 f8                	mov    %edi,%eax
f0101cc2:	e8 77 ec ff ff       	call   f010093e <check_va2pa>
f0101cc7:	83 c4 10             	add    $0x10,%esp
f0101cca:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ccd:	74 19                	je     f0101ce8 <mem_init+0xcc6>
f0101ccf:	68 dc 40 10 f0       	push   $0xf01040dc
f0101cd4:	68 3e 43 10 f0       	push   $0xf010433e
f0101cd9:	68 82 03 00 00       	push   $0x382
f0101cde:	68 18 43 10 f0       	push   $0xf0104318
f0101ce3:	e8 a3 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ce8:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ced:	89 f8                	mov    %edi,%eax
f0101cef:	e8 4a ec ff ff       	call   f010093e <check_va2pa>
f0101cf4:	89 da                	mov    %ebx,%edx
f0101cf6:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101cfc:	c1 fa 03             	sar    $0x3,%edx
f0101cff:	c1 e2 0c             	shl    $0xc,%edx
f0101d02:	39 d0                	cmp    %edx,%eax
f0101d04:	74 19                	je     f0101d1f <mem_init+0xcfd>
f0101d06:	68 88 40 10 f0       	push   $0xf0104088
f0101d0b:	68 3e 43 10 f0       	push   $0xf010433e
f0101d10:	68 83 03 00 00       	push   $0x383
f0101d15:	68 18 43 10 f0       	push   $0xf0104318
f0101d1a:	e8 6c e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101d1f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d24:	74 19                	je     f0101d3f <mem_init+0xd1d>
f0101d26:	68 ff 44 10 f0       	push   $0xf01044ff
f0101d2b:	68 3e 43 10 f0       	push   $0xf010433e
f0101d30:	68 84 03 00 00       	push   $0x384
f0101d35:	68 18 43 10 f0       	push   $0xf0104318
f0101d3a:	e8 4c e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101d3f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d44:	74 19                	je     f0101d5f <mem_init+0xd3d>
f0101d46:	68 59 45 10 f0       	push   $0xf0104559
f0101d4b:	68 3e 43 10 f0       	push   $0xf010433e
f0101d50:	68 85 03 00 00       	push   $0x385
f0101d55:	68 18 43 10 f0       	push   $0xf0104318
f0101d5a:	e8 2c e3 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d5f:	6a 00                	push   $0x0
f0101d61:	68 00 10 00 00       	push   $0x1000
f0101d66:	53                   	push   %ebx
f0101d67:	57                   	push   %edi
f0101d68:	e8 4f f2 ff ff       	call   f0100fbc <page_insert>
f0101d6d:	83 c4 10             	add    $0x10,%esp
f0101d70:	85 c0                	test   %eax,%eax
f0101d72:	74 19                	je     f0101d8d <mem_init+0xd6b>
f0101d74:	68 00 41 10 f0       	push   $0xf0104100
f0101d79:	68 3e 43 10 f0       	push   $0xf010433e
f0101d7e:	68 88 03 00 00       	push   $0x388
f0101d83:	68 18 43 10 f0       	push   $0xf0104318
f0101d88:	e8 fe e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101d8d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d92:	75 19                	jne    f0101dad <mem_init+0xd8b>
f0101d94:	68 6a 45 10 f0       	push   $0xf010456a
f0101d99:	68 3e 43 10 f0       	push   $0xf010433e
f0101d9e:	68 89 03 00 00       	push   $0x389
f0101da3:	68 18 43 10 f0       	push   $0xf0104318
f0101da8:	e8 de e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101dad:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101db0:	74 19                	je     f0101dcb <mem_init+0xda9>
f0101db2:	68 76 45 10 f0       	push   $0xf0104576
f0101db7:	68 3e 43 10 f0       	push   $0xf010433e
f0101dbc:	68 8a 03 00 00       	push   $0x38a
f0101dc1:	68 18 43 10 f0       	push   $0xf0104318
f0101dc6:	e8 c0 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101dcb:	83 ec 08             	sub    $0x8,%esp
f0101dce:	68 00 10 00 00       	push   $0x1000
f0101dd3:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101dd9:	e8 a3 f1 ff ff       	call   f0100f81 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101dde:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101de4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101de9:	89 f8                	mov    %edi,%eax
f0101deb:	e8 4e eb ff ff       	call   f010093e <check_va2pa>
f0101df0:	83 c4 10             	add    $0x10,%esp
f0101df3:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101df6:	74 19                	je     f0101e11 <mem_init+0xdef>
f0101df8:	68 dc 40 10 f0       	push   $0xf01040dc
f0101dfd:	68 3e 43 10 f0       	push   $0xf010433e
f0101e02:	68 8e 03 00 00       	push   $0x38e
f0101e07:	68 18 43 10 f0       	push   $0xf0104318
f0101e0c:	e8 7a e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e11:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e16:	89 f8                	mov    %edi,%eax
f0101e18:	e8 21 eb ff ff       	call   f010093e <check_va2pa>
f0101e1d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e20:	74 19                	je     f0101e3b <mem_init+0xe19>
f0101e22:	68 38 41 10 f0       	push   $0xf0104138
f0101e27:	68 3e 43 10 f0       	push   $0xf010433e
f0101e2c:	68 8f 03 00 00       	push   $0x38f
f0101e31:	68 18 43 10 f0       	push   $0xf0104318
f0101e36:	e8 50 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101e3b:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e40:	74 19                	je     f0101e5b <mem_init+0xe39>
f0101e42:	68 8b 45 10 f0       	push   $0xf010458b
f0101e47:	68 3e 43 10 f0       	push   $0xf010433e
f0101e4c:	68 90 03 00 00       	push   $0x390
f0101e51:	68 18 43 10 f0       	push   $0xf0104318
f0101e56:	e8 30 e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e5b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e60:	74 19                	je     f0101e7b <mem_init+0xe59>
f0101e62:	68 59 45 10 f0       	push   $0xf0104559
f0101e67:	68 3e 43 10 f0       	push   $0xf010433e
f0101e6c:	68 91 03 00 00       	push   $0x391
f0101e71:	68 18 43 10 f0       	push   $0xf0104318
f0101e76:	e8 10 e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e7b:	83 ec 0c             	sub    $0xc,%esp
f0101e7e:	6a 00                	push   $0x0
f0101e80:	e8 b1 ee ff ff       	call   f0100d36 <page_alloc>
f0101e85:	83 c4 10             	add    $0x10,%esp
f0101e88:	39 c3                	cmp    %eax,%ebx
f0101e8a:	75 04                	jne    f0101e90 <mem_init+0xe6e>
f0101e8c:	85 c0                	test   %eax,%eax
f0101e8e:	75 19                	jne    f0101ea9 <mem_init+0xe87>
f0101e90:	68 60 41 10 f0       	push   $0xf0104160
f0101e95:	68 3e 43 10 f0       	push   $0xf010433e
f0101e9a:	68 94 03 00 00       	push   $0x394
f0101e9f:	68 18 43 10 f0       	push   $0xf0104318
f0101ea4:	e8 e2 e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ea9:	83 ec 0c             	sub    $0xc,%esp
f0101eac:	6a 00                	push   $0x0
f0101eae:	e8 83 ee ff ff       	call   f0100d36 <page_alloc>
f0101eb3:	83 c4 10             	add    $0x10,%esp
f0101eb6:	85 c0                	test   %eax,%eax
f0101eb8:	74 19                	je     f0101ed3 <mem_init+0xeb1>
f0101eba:	68 ad 44 10 f0       	push   $0xf01044ad
f0101ebf:	68 3e 43 10 f0       	push   $0xf010433e
f0101ec4:	68 97 03 00 00       	push   $0x397
f0101ec9:	68 18 43 10 f0       	push   $0xf0104318
f0101ece:	e8 b8 e1 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ed3:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0101ed9:	8b 11                	mov    (%ecx),%edx
f0101edb:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ee1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ee4:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101eea:	c1 f8 03             	sar    $0x3,%eax
f0101eed:	c1 e0 0c             	shl    $0xc,%eax
f0101ef0:	39 c2                	cmp    %eax,%edx
f0101ef2:	74 19                	je     f0101f0d <mem_init+0xeeb>
f0101ef4:	68 04 3e 10 f0       	push   $0xf0103e04
f0101ef9:	68 3e 43 10 f0       	push   $0xf010433e
f0101efe:	68 9a 03 00 00       	push   $0x39a
f0101f03:	68 18 43 10 f0       	push   $0xf0104318
f0101f08:	e8 7e e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101f0d:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f13:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f16:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f1b:	74 19                	je     f0101f36 <mem_init+0xf14>
f0101f1d:	68 10 45 10 f0       	push   $0xf0104510
f0101f22:	68 3e 43 10 f0       	push   $0xf010433e
f0101f27:	68 9c 03 00 00       	push   $0x39c
f0101f2c:	68 18 43 10 f0       	push   $0xf0104318
f0101f31:	e8 55 e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101f36:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f39:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f3f:	83 ec 0c             	sub    $0xc,%esp
f0101f42:	50                   	push   %eax
f0101f43:	e8 74 ee ff ff       	call   f0100dbc <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f48:	83 c4 0c             	add    $0xc,%esp
f0101f4b:	6a 01                	push   $0x1
f0101f4d:	68 00 10 40 00       	push   $0x401000
f0101f52:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101f58:	e8 ab ee ff ff       	call   f0100e08 <pgdir_walk>
f0101f5d:	89 c7                	mov    %eax,%edi
f0101f5f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f62:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101f67:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f6a:	8b 40 04             	mov    0x4(%eax),%eax
f0101f6d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f72:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0101f78:	89 c2                	mov    %eax,%edx
f0101f7a:	c1 ea 0c             	shr    $0xc,%edx
f0101f7d:	83 c4 10             	add    $0x10,%esp
f0101f80:	39 ca                	cmp    %ecx,%edx
f0101f82:	72 15                	jb     f0101f99 <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f84:	50                   	push   %eax
f0101f85:	68 c4 3b 10 f0       	push   $0xf0103bc4
f0101f8a:	68 a3 03 00 00       	push   $0x3a3
f0101f8f:	68 18 43 10 f0       	push   $0xf0104318
f0101f94:	e8 f2 e0 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f99:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f9e:	39 c7                	cmp    %eax,%edi
f0101fa0:	74 19                	je     f0101fbb <mem_init+0xf99>
f0101fa2:	68 9c 45 10 f0       	push   $0xf010459c
f0101fa7:	68 3e 43 10 f0       	push   $0xf010433e
f0101fac:	68 a4 03 00 00       	push   $0x3a4
f0101fb1:	68 18 43 10 f0       	push   $0xf0104318
f0101fb6:	e8 d0 e0 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101fbb:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101fbe:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101fc5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fc8:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fce:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101fd4:	c1 f8 03             	sar    $0x3,%eax
f0101fd7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fda:	89 c2                	mov    %eax,%edx
f0101fdc:	c1 ea 0c             	shr    $0xc,%edx
f0101fdf:	39 d1                	cmp    %edx,%ecx
f0101fe1:	77 12                	ja     f0101ff5 <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fe3:	50                   	push   %eax
f0101fe4:	68 c4 3b 10 f0       	push   $0xf0103bc4
f0101fe9:	6a 52                	push   $0x52
f0101feb:	68 24 43 10 f0       	push   $0xf0104324
f0101ff0:	e8 96 e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101ff5:	83 ec 04             	sub    $0x4,%esp
f0101ff8:	68 00 10 00 00       	push   $0x1000
f0101ffd:	68 ff 00 00 00       	push   $0xff
f0102002:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102007:	50                   	push   %eax
f0102008:	e8 c2 11 00 00       	call   f01031cf <memset>
	page_free(pp0);
f010200d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102010:	89 3c 24             	mov    %edi,(%esp)
f0102013:	e8 a4 ed ff ff       	call   f0100dbc <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102018:	83 c4 0c             	add    $0xc,%esp
f010201b:	6a 01                	push   $0x1
f010201d:	6a 00                	push   $0x0
f010201f:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102025:	e8 de ed ff ff       	call   f0100e08 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010202a:	89 fa                	mov    %edi,%edx
f010202c:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0102032:	c1 fa 03             	sar    $0x3,%edx
f0102035:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102038:	89 d0                	mov    %edx,%eax
f010203a:	c1 e8 0c             	shr    $0xc,%eax
f010203d:	83 c4 10             	add    $0x10,%esp
f0102040:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0102046:	72 12                	jb     f010205a <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102048:	52                   	push   %edx
f0102049:	68 c4 3b 10 f0       	push   $0xf0103bc4
f010204e:	6a 52                	push   $0x52
f0102050:	68 24 43 10 f0       	push   $0xf0104324
f0102055:	e8 31 e0 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f010205a:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102060:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102063:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102069:	f6 00 01             	testb  $0x1,(%eax)
f010206c:	74 19                	je     f0102087 <mem_init+0x1065>
f010206e:	68 b4 45 10 f0       	push   $0xf01045b4
f0102073:	68 3e 43 10 f0       	push   $0xf010433e
f0102078:	68 ae 03 00 00       	push   $0x3ae
f010207d:	68 18 43 10 f0       	push   $0xf0104318
f0102082:	e8 04 e0 ff ff       	call   f010008b <_panic>
f0102087:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010208a:	39 d0                	cmp    %edx,%eax
f010208c:	75 db                	jne    f0102069 <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010208e:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102093:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102099:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010209c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020a2:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01020a5:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f01020ab:	83 ec 0c             	sub    $0xc,%esp
f01020ae:	50                   	push   %eax
f01020af:	e8 08 ed ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f01020b4:	89 1c 24             	mov    %ebx,(%esp)
f01020b7:	e8 00 ed ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f01020bc:	89 34 24             	mov    %esi,(%esp)
f01020bf:	e8 f8 ec ff ff       	call   f0100dbc <page_free>

	cprintf("check_page() succeeded!\n");
f01020c4:	c7 04 24 cb 45 10 f0 	movl   $0xf01045cb,(%esp)
f01020cb:	e8 4b 06 00 00       	call   f010271b <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U | PTE_P);
f01020d0:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020d5:	83 c4 10             	add    $0x10,%esp
f01020d8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020dd:	77 15                	ja     f01020f4 <mem_init+0x10d2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020df:	50                   	push   %eax
f01020e0:	68 08 3d 10 f0       	push   $0xf0103d08
f01020e5:	68 af 00 00 00       	push   $0xaf
f01020ea:	68 18 43 10 f0       	push   $0xf0104318
f01020ef:	e8 97 df ff ff       	call   f010008b <_panic>
f01020f4:	83 ec 08             	sub    $0x8,%esp
f01020f7:	6a 05                	push   $0x5
f01020f9:	05 00 00 00 10       	add    $0x10000000,%eax
f01020fe:	50                   	push   %eax
f01020ff:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102104:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102109:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010210e:	e8 b9 ed ff ff       	call   f0100ecc <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102113:	83 c4 10             	add    $0x10,%esp
f0102116:	b8 00 c0 10 f0       	mov    $0xf010c000,%eax
f010211b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102120:	77 15                	ja     f0102137 <mem_init+0x1115>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102122:	50                   	push   %eax
f0102123:	68 08 3d 10 f0       	push   $0xf0103d08
f0102128:	68 bb 00 00 00       	push   $0xbb
f010212d:	68 18 43 10 f0       	push   $0xf0104318
f0102132:	e8 54 df ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTACKTOP, KSTACKTOP, PADDR(bootstack), PTE_W);
f0102137:	83 ec 08             	sub    $0x8,%esp
f010213a:	6a 02                	push   $0x2
f010213c:	68 00 c0 10 00       	push   $0x10c000
f0102141:	b9 00 00 00 f0       	mov    $0xf0000000,%ecx
f0102146:	ba 00 00 00 00       	mov    $0x0,%edx
f010214b:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102150:	e8 77 ed ff ff       	call   f0100ecc <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff-KERNBASE, 0, PTE_W);
f0102155:	83 c4 08             	add    $0x8,%esp
f0102158:	6a 02                	push   $0x2
f010215a:	6a 00                	push   $0x0
f010215c:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102161:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102166:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010216b:	e8 5c ed ff ff       	call   f0100ecc <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102170:	8b 35 68 69 11 f0    	mov    0xf0116968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102176:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f010217b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010217e:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102185:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010218a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010218d:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102193:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102196:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102199:	bb 00 00 00 00       	mov    $0x0,%ebx
f010219e:	eb 55                	jmp    f01021f5 <mem_init+0x11d3>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01021a0:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01021a6:	89 f0                	mov    %esi,%eax
f01021a8:	e8 91 e7 ff ff       	call   f010093e <check_va2pa>
f01021ad:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01021b4:	77 15                	ja     f01021cb <mem_init+0x11a9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021b6:	57                   	push   %edi
f01021b7:	68 08 3d 10 f0       	push   $0xf0103d08
f01021bc:	68 f0 02 00 00       	push   $0x2f0
f01021c1:	68 18 43 10 f0       	push   $0xf0104318
f01021c6:	e8 c0 de ff ff       	call   f010008b <_panic>
f01021cb:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01021d2:	39 c2                	cmp    %eax,%edx
f01021d4:	74 19                	je     f01021ef <mem_init+0x11cd>
f01021d6:	68 84 41 10 f0       	push   $0xf0104184
f01021db:	68 3e 43 10 f0       	push   $0xf010433e
f01021e0:	68 f0 02 00 00       	push   $0x2f0
f01021e5:	68 18 43 10 f0       	push   $0xf0104318
f01021ea:	e8 9c de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021ef:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01021f5:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01021f8:	77 a6                	ja     f01021a0 <mem_init+0x117e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01021fa:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01021fd:	c1 e7 0c             	shl    $0xc,%edi
f0102200:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102205:	eb 30                	jmp    f0102237 <mem_init+0x1215>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102207:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f010220d:	89 f0                	mov    %esi,%eax
f010220f:	e8 2a e7 ff ff       	call   f010093e <check_va2pa>
f0102214:	39 c3                	cmp    %eax,%ebx
f0102216:	74 19                	je     f0102231 <mem_init+0x120f>
f0102218:	68 b8 41 10 f0       	push   $0xf01041b8
f010221d:	68 3e 43 10 f0       	push   $0xf010433e
f0102222:	68 f5 02 00 00       	push   $0x2f5
f0102227:	68 18 43 10 f0       	push   $0xf0104318
f010222c:	e8 5a de ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102231:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102237:	39 fb                	cmp    %edi,%ebx
f0102239:	72 cc                	jb     f0102207 <mem_init+0x11e5>
f010223b:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102240:	89 da                	mov    %ebx,%edx
f0102242:	89 f0                	mov    %esi,%eax
f0102244:	e8 f5 e6 ff ff       	call   f010093e <check_va2pa>
f0102249:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f010224f:	39 c2                	cmp    %eax,%edx
f0102251:	74 19                	je     f010226c <mem_init+0x124a>
f0102253:	68 e0 41 10 f0       	push   $0xf01041e0
f0102258:	68 3e 43 10 f0       	push   $0xf010433e
f010225d:	68 f9 02 00 00       	push   $0x2f9
f0102262:	68 18 43 10 f0       	push   $0xf0104318
f0102267:	e8 1f de ff ff       	call   f010008b <_panic>
f010226c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102272:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102278:	75 c6                	jne    f0102240 <mem_init+0x121e>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010227a:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010227f:	89 f0                	mov    %esi,%eax
f0102281:	e8 b8 e6 ff ff       	call   f010093e <check_va2pa>
f0102286:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102289:	74 51                	je     f01022dc <mem_init+0x12ba>
f010228b:	68 28 42 10 f0       	push   $0xf0104228
f0102290:	68 3e 43 10 f0       	push   $0xf010433e
f0102295:	68 fa 02 00 00       	push   $0x2fa
f010229a:	68 18 43 10 f0       	push   $0xf0104318
f010229f:	e8 e7 dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01022a4:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01022a9:	72 36                	jb     f01022e1 <mem_init+0x12bf>
f01022ab:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01022b0:	76 07                	jbe    f01022b9 <mem_init+0x1297>
f01022b2:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022b7:	75 28                	jne    f01022e1 <mem_init+0x12bf>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01022b9:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01022bd:	0f 85 83 00 00 00    	jne    f0102346 <mem_init+0x1324>
f01022c3:	68 e4 45 10 f0       	push   $0xf01045e4
f01022c8:	68 3e 43 10 f0       	push   $0xf010433e
f01022cd:	68 02 03 00 00       	push   $0x302
f01022d2:	68 18 43 10 f0       	push   $0xf0104318
f01022d7:	e8 af dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022dc:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01022e1:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022e6:	76 3f                	jbe    f0102327 <mem_init+0x1305>
				assert(pgdir[i] & PTE_P);
f01022e8:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01022eb:	f6 c2 01             	test   $0x1,%dl
f01022ee:	75 19                	jne    f0102309 <mem_init+0x12e7>
f01022f0:	68 e4 45 10 f0       	push   $0xf01045e4
f01022f5:	68 3e 43 10 f0       	push   $0xf010433e
f01022fa:	68 06 03 00 00       	push   $0x306
f01022ff:	68 18 43 10 f0       	push   $0xf0104318
f0102304:	e8 82 dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102309:	f6 c2 02             	test   $0x2,%dl
f010230c:	75 38                	jne    f0102346 <mem_init+0x1324>
f010230e:	68 f5 45 10 f0       	push   $0xf01045f5
f0102313:	68 3e 43 10 f0       	push   $0xf010433e
f0102318:	68 07 03 00 00       	push   $0x307
f010231d:	68 18 43 10 f0       	push   $0xf0104318
f0102322:	e8 64 dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102327:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f010232b:	74 19                	je     f0102346 <mem_init+0x1324>
f010232d:	68 06 46 10 f0       	push   $0xf0104606
f0102332:	68 3e 43 10 f0       	push   $0xf010433e
f0102337:	68 09 03 00 00       	push   $0x309
f010233c:	68 18 43 10 f0       	push   $0xf0104318
f0102341:	e8 45 dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102346:	83 c0 01             	add    $0x1,%eax
f0102349:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010234e:	0f 86 50 ff ff ff    	jbe    f01022a4 <mem_init+0x1282>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102354:	83 ec 0c             	sub    $0xc,%esp
f0102357:	68 58 42 10 f0       	push   $0xf0104258
f010235c:	e8 ba 03 00 00       	call   f010271b <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102361:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102366:	83 c4 10             	add    $0x10,%esp
f0102369:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010236e:	77 15                	ja     f0102385 <mem_init+0x1363>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102370:	50                   	push   %eax
f0102371:	68 08 3d 10 f0       	push   $0xf0103d08
f0102376:	68 cf 00 00 00       	push   $0xcf
f010237b:	68 18 43 10 f0       	push   $0xf0104318
f0102380:	e8 06 dd ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102385:	05 00 00 00 10       	add    $0x10000000,%eax
f010238a:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010238d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102392:	e8 0b e6 ff ff       	call   f01009a2 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102397:	0f 20 c0             	mov    %cr0,%eax
f010239a:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f010239d:	0d 23 00 05 80       	or     $0x80050023,%eax
f01023a2:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01023a5:	83 ec 0c             	sub    $0xc,%esp
f01023a8:	6a 00                	push   $0x0
f01023aa:	e8 87 e9 ff ff       	call   f0100d36 <page_alloc>
f01023af:	89 c3                	mov    %eax,%ebx
f01023b1:	83 c4 10             	add    $0x10,%esp
f01023b4:	85 c0                	test   %eax,%eax
f01023b6:	75 19                	jne    f01023d1 <mem_init+0x13af>
f01023b8:	68 02 44 10 f0       	push   $0xf0104402
f01023bd:	68 3e 43 10 f0       	push   $0xf010433e
f01023c2:	68 c9 03 00 00       	push   $0x3c9
f01023c7:	68 18 43 10 f0       	push   $0xf0104318
f01023cc:	e8 ba dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01023d1:	83 ec 0c             	sub    $0xc,%esp
f01023d4:	6a 00                	push   $0x0
f01023d6:	e8 5b e9 ff ff       	call   f0100d36 <page_alloc>
f01023db:	89 c7                	mov    %eax,%edi
f01023dd:	83 c4 10             	add    $0x10,%esp
f01023e0:	85 c0                	test   %eax,%eax
f01023e2:	75 19                	jne    f01023fd <mem_init+0x13db>
f01023e4:	68 18 44 10 f0       	push   $0xf0104418
f01023e9:	68 3e 43 10 f0       	push   $0xf010433e
f01023ee:	68 ca 03 00 00       	push   $0x3ca
f01023f3:	68 18 43 10 f0       	push   $0xf0104318
f01023f8:	e8 8e dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01023fd:	83 ec 0c             	sub    $0xc,%esp
f0102400:	6a 00                	push   $0x0
f0102402:	e8 2f e9 ff ff       	call   f0100d36 <page_alloc>
f0102407:	89 c6                	mov    %eax,%esi
f0102409:	83 c4 10             	add    $0x10,%esp
f010240c:	85 c0                	test   %eax,%eax
f010240e:	75 19                	jne    f0102429 <mem_init+0x1407>
f0102410:	68 2e 44 10 f0       	push   $0xf010442e
f0102415:	68 3e 43 10 f0       	push   $0xf010433e
f010241a:	68 cb 03 00 00       	push   $0x3cb
f010241f:	68 18 43 10 f0       	push   $0xf0104318
f0102424:	e8 62 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102429:	83 ec 0c             	sub    $0xc,%esp
f010242c:	53                   	push   %ebx
f010242d:	e8 8a e9 ff ff       	call   f0100dbc <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102432:	89 f8                	mov    %edi,%eax
f0102434:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010243a:	c1 f8 03             	sar    $0x3,%eax
f010243d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102440:	89 c2                	mov    %eax,%edx
f0102442:	c1 ea 0c             	shr    $0xc,%edx
f0102445:	83 c4 10             	add    $0x10,%esp
f0102448:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f010244e:	72 12                	jb     f0102462 <mem_init+0x1440>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102450:	50                   	push   %eax
f0102451:	68 c4 3b 10 f0       	push   $0xf0103bc4
f0102456:	6a 52                	push   $0x52
f0102458:	68 24 43 10 f0       	push   $0xf0104324
f010245d:	e8 29 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102462:	83 ec 04             	sub    $0x4,%esp
f0102465:	68 00 10 00 00       	push   $0x1000
f010246a:	6a 01                	push   $0x1
f010246c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102471:	50                   	push   %eax
f0102472:	e8 58 0d 00 00       	call   f01031cf <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102477:	89 f0                	mov    %esi,%eax
f0102479:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010247f:	c1 f8 03             	sar    $0x3,%eax
f0102482:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102485:	89 c2                	mov    %eax,%edx
f0102487:	c1 ea 0c             	shr    $0xc,%edx
f010248a:	83 c4 10             	add    $0x10,%esp
f010248d:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102493:	72 12                	jb     f01024a7 <mem_init+0x1485>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102495:	50                   	push   %eax
f0102496:	68 c4 3b 10 f0       	push   $0xf0103bc4
f010249b:	6a 52                	push   $0x52
f010249d:	68 24 43 10 f0       	push   $0xf0104324
f01024a2:	e8 e4 db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01024a7:	83 ec 04             	sub    $0x4,%esp
f01024aa:	68 00 10 00 00       	push   $0x1000
f01024af:	6a 02                	push   $0x2
f01024b1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024b6:	50                   	push   %eax
f01024b7:	e8 13 0d 00 00       	call   f01031cf <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01024bc:	6a 02                	push   $0x2
f01024be:	68 00 10 00 00       	push   $0x1000
f01024c3:	57                   	push   %edi
f01024c4:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01024ca:	e8 ed ea ff ff       	call   f0100fbc <page_insert>
	assert(pp1->pp_ref == 1);
f01024cf:	83 c4 20             	add    $0x20,%esp
f01024d2:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01024d7:	74 19                	je     f01024f2 <mem_init+0x14d0>
f01024d9:	68 ff 44 10 f0       	push   $0xf01044ff
f01024de:	68 3e 43 10 f0       	push   $0xf010433e
f01024e3:	68 d0 03 00 00       	push   $0x3d0
f01024e8:	68 18 43 10 f0       	push   $0xf0104318
f01024ed:	e8 99 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01024f2:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01024f9:	01 01 01 
f01024fc:	74 19                	je     f0102517 <mem_init+0x14f5>
f01024fe:	68 78 42 10 f0       	push   $0xf0104278
f0102503:	68 3e 43 10 f0       	push   $0xf010433e
f0102508:	68 d1 03 00 00       	push   $0x3d1
f010250d:	68 18 43 10 f0       	push   $0xf0104318
f0102512:	e8 74 db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102517:	6a 02                	push   $0x2
f0102519:	68 00 10 00 00       	push   $0x1000
f010251e:	56                   	push   %esi
f010251f:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102525:	e8 92 ea ff ff       	call   f0100fbc <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010252a:	83 c4 10             	add    $0x10,%esp
f010252d:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102534:	02 02 02 
f0102537:	74 19                	je     f0102552 <mem_init+0x1530>
f0102539:	68 9c 42 10 f0       	push   $0xf010429c
f010253e:	68 3e 43 10 f0       	push   $0xf010433e
f0102543:	68 d3 03 00 00       	push   $0x3d3
f0102548:	68 18 43 10 f0       	push   $0xf0104318
f010254d:	e8 39 db ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0102552:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102557:	74 19                	je     f0102572 <mem_init+0x1550>
f0102559:	68 21 45 10 f0       	push   $0xf0104521
f010255e:	68 3e 43 10 f0       	push   $0xf010433e
f0102563:	68 d4 03 00 00       	push   $0x3d4
f0102568:	68 18 43 10 f0       	push   $0xf0104318
f010256d:	e8 19 db ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0102572:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102577:	74 19                	je     f0102592 <mem_init+0x1570>
f0102579:	68 8b 45 10 f0       	push   $0xf010458b
f010257e:	68 3e 43 10 f0       	push   $0xf010433e
f0102583:	68 d5 03 00 00       	push   $0x3d5
f0102588:	68 18 43 10 f0       	push   $0xf0104318
f010258d:	e8 f9 da ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102592:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102599:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010259c:	89 f0                	mov    %esi,%eax
f010259e:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01025a4:	c1 f8 03             	sar    $0x3,%eax
f01025a7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025aa:	89 c2                	mov    %eax,%edx
f01025ac:	c1 ea 0c             	shr    $0xc,%edx
f01025af:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01025b5:	72 12                	jb     f01025c9 <mem_init+0x15a7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025b7:	50                   	push   %eax
f01025b8:	68 c4 3b 10 f0       	push   $0xf0103bc4
f01025bd:	6a 52                	push   $0x52
f01025bf:	68 24 43 10 f0       	push   $0xf0104324
f01025c4:	e8 c2 da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01025c9:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01025d0:	03 03 03 
f01025d3:	74 19                	je     f01025ee <mem_init+0x15cc>
f01025d5:	68 c0 42 10 f0       	push   $0xf01042c0
f01025da:	68 3e 43 10 f0       	push   $0xf010433e
f01025df:	68 d7 03 00 00       	push   $0x3d7
f01025e4:	68 18 43 10 f0       	push   $0xf0104318
f01025e9:	e8 9d da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025ee:	83 ec 08             	sub    $0x8,%esp
f01025f1:	68 00 10 00 00       	push   $0x1000
f01025f6:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01025fc:	e8 80 e9 ff ff       	call   f0100f81 <page_remove>
	assert(pp2->pp_ref == 0);
f0102601:	83 c4 10             	add    $0x10,%esp
f0102604:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102609:	74 19                	je     f0102624 <mem_init+0x1602>
f010260b:	68 59 45 10 f0       	push   $0xf0104559
f0102610:	68 3e 43 10 f0       	push   $0xf010433e
f0102615:	68 d9 03 00 00       	push   $0x3d9
f010261a:	68 18 43 10 f0       	push   $0xf0104318
f010261f:	e8 67 da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102624:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f010262a:	8b 11                	mov    (%ecx),%edx
f010262c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102632:	89 d8                	mov    %ebx,%eax
f0102634:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010263a:	c1 f8 03             	sar    $0x3,%eax
f010263d:	c1 e0 0c             	shl    $0xc,%eax
f0102640:	39 c2                	cmp    %eax,%edx
f0102642:	74 19                	je     f010265d <mem_init+0x163b>
f0102644:	68 04 3e 10 f0       	push   $0xf0103e04
f0102649:	68 3e 43 10 f0       	push   $0xf010433e
f010264e:	68 dc 03 00 00       	push   $0x3dc
f0102653:	68 18 43 10 f0       	push   $0xf0104318
f0102658:	e8 2e da ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f010265d:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102663:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102668:	74 19                	je     f0102683 <mem_init+0x1661>
f010266a:	68 10 45 10 f0       	push   $0xf0104510
f010266f:	68 3e 43 10 f0       	push   $0xf010433e
f0102674:	68 de 03 00 00       	push   $0x3de
f0102679:	68 18 43 10 f0       	push   $0xf0104318
f010267e:	e8 08 da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0102683:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102689:	83 ec 0c             	sub    $0xc,%esp
f010268c:	53                   	push   %ebx
f010268d:	e8 2a e7 ff ff       	call   f0100dbc <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102692:	c7 04 24 ec 42 10 f0 	movl   $0xf01042ec,(%esp)
f0102699:	e8 7d 00 00 00       	call   f010271b <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010269e:	83 c4 10             	add    $0x10,%esp
f01026a1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01026a4:	5b                   	pop    %ebx
f01026a5:	5e                   	pop    %esi
f01026a6:	5f                   	pop    %edi
f01026a7:	5d                   	pop    %ebp
f01026a8:	c3                   	ret    

f01026a9 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01026a9:	55                   	push   %ebp
f01026aa:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01026ac:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026af:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01026b2:	5d                   	pop    %ebp
f01026b3:	c3                   	ret    

f01026b4 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01026b4:	55                   	push   %ebp
f01026b5:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01026b7:	ba 70 00 00 00       	mov    $0x70,%edx
f01026bc:	8b 45 08             	mov    0x8(%ebp),%eax
f01026bf:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01026c0:	ba 71 00 00 00       	mov    $0x71,%edx
f01026c5:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01026c6:	0f b6 c0             	movzbl %al,%eax
}
f01026c9:	5d                   	pop    %ebp
f01026ca:	c3                   	ret    

f01026cb <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01026cb:	55                   	push   %ebp
f01026cc:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01026ce:	ba 70 00 00 00       	mov    $0x70,%edx
f01026d3:	8b 45 08             	mov    0x8(%ebp),%eax
f01026d6:	ee                   	out    %al,(%dx)
f01026d7:	ba 71 00 00 00       	mov    $0x71,%edx
f01026dc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026df:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01026e0:	5d                   	pop    %ebp
f01026e1:	c3                   	ret    

f01026e2 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01026e2:	55                   	push   %ebp
f01026e3:	89 e5                	mov    %esp,%ebp
f01026e5:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01026e8:	ff 75 08             	pushl  0x8(%ebp)
f01026eb:	e8 35 df ff ff       	call   f0100625 <cputchar>
	*cnt++;
}
f01026f0:	83 c4 10             	add    $0x10,%esp
f01026f3:	c9                   	leave  
f01026f4:	c3                   	ret    

f01026f5 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01026f5:	55                   	push   %ebp
f01026f6:	89 e5                	mov    %esp,%ebp
f01026f8:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01026fb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102702:	ff 75 0c             	pushl  0xc(%ebp)
f0102705:	ff 75 08             	pushl  0x8(%ebp)
f0102708:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010270b:	50                   	push   %eax
f010270c:	68 e2 26 10 f0       	push   $0xf01026e2
f0102711:	e8 4d 04 00 00       	call   f0102b63 <vprintfmt>
	return cnt;
}
f0102716:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102719:	c9                   	leave  
f010271a:	c3                   	ret    

f010271b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010271b:	55                   	push   %ebp
f010271c:	89 e5                	mov    %esp,%ebp
f010271e:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102721:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102724:	50                   	push   %eax
f0102725:	ff 75 08             	pushl  0x8(%ebp)
f0102728:	e8 c8 ff ff ff       	call   f01026f5 <vcprintf>
	va_end(ap);

	return cnt;
}
f010272d:	c9                   	leave  
f010272e:	c3                   	ret    

f010272f <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010272f:	55                   	push   %ebp
f0102730:	89 e5                	mov    %esp,%ebp
f0102732:	57                   	push   %edi
f0102733:	56                   	push   %esi
f0102734:	53                   	push   %ebx
f0102735:	83 ec 14             	sub    $0x14,%esp
f0102738:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010273b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010273e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102741:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102744:	8b 1a                	mov    (%edx),%ebx
f0102746:	8b 01                	mov    (%ecx),%eax
f0102748:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010274b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102752:	eb 7f                	jmp    f01027d3 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102754:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102757:	01 d8                	add    %ebx,%eax
f0102759:	89 c6                	mov    %eax,%esi
f010275b:	c1 ee 1f             	shr    $0x1f,%esi
f010275e:	01 c6                	add    %eax,%esi
f0102760:	d1 fe                	sar    %esi
f0102762:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102765:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102768:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010276b:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010276d:	eb 03                	jmp    f0102772 <stab_binsearch+0x43>
			m--;
f010276f:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102772:	39 c3                	cmp    %eax,%ebx
f0102774:	7f 0d                	jg     f0102783 <stab_binsearch+0x54>
f0102776:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010277a:	83 ea 0c             	sub    $0xc,%edx
f010277d:	39 f9                	cmp    %edi,%ecx
f010277f:	75 ee                	jne    f010276f <stab_binsearch+0x40>
f0102781:	eb 05                	jmp    f0102788 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102783:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102786:	eb 4b                	jmp    f01027d3 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102788:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010278b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010278e:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102792:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102795:	76 11                	jbe    f01027a8 <stab_binsearch+0x79>
			*region_left = m;
f0102797:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010279a:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010279c:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010279f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01027a6:	eb 2b                	jmp    f01027d3 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01027a8:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01027ab:	73 14                	jae    f01027c1 <stab_binsearch+0x92>
			*region_right = m - 1;
f01027ad:	83 e8 01             	sub    $0x1,%eax
f01027b0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01027b3:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027b6:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027b8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01027bf:	eb 12                	jmp    f01027d3 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01027c1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027c4:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01027c6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01027ca:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027cc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01027d3:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01027d6:	0f 8e 78 ff ff ff    	jle    f0102754 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01027dc:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01027e0:	75 0f                	jne    f01027f1 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01027e2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027e5:	8b 00                	mov    (%eax),%eax
f01027e7:	83 e8 01             	sub    $0x1,%eax
f01027ea:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027ed:	89 06                	mov    %eax,(%esi)
f01027ef:	eb 2c                	jmp    f010281d <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027f1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027f4:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01027f6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027f9:	8b 0e                	mov    (%esi),%ecx
f01027fb:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027fe:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102801:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102804:	eb 03                	jmp    f0102809 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102806:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102809:	39 c8                	cmp    %ecx,%eax
f010280b:	7e 0b                	jle    f0102818 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010280d:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102811:	83 ea 0c             	sub    $0xc,%edx
f0102814:	39 df                	cmp    %ebx,%edi
f0102816:	75 ee                	jne    f0102806 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102818:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010281b:	89 06                	mov    %eax,(%esi)
	}
}
f010281d:	83 c4 14             	add    $0x14,%esp
f0102820:	5b                   	pop    %ebx
f0102821:	5e                   	pop    %esi
f0102822:	5f                   	pop    %edi
f0102823:	5d                   	pop    %ebp
f0102824:	c3                   	ret    

f0102825 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102825:	55                   	push   %ebp
f0102826:	89 e5                	mov    %esp,%ebp
f0102828:	57                   	push   %edi
f0102829:	56                   	push   %esi
f010282a:	53                   	push   %ebx
f010282b:	83 ec 2c             	sub    $0x2c,%esp
f010282e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102831:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102834:	c7 06 14 46 10 f0    	movl   $0xf0104614,(%esi)
	info->eip_line = 0;
f010283a:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0102841:	c7 46 08 14 46 10 f0 	movl   $0xf0104614,0x8(%esi)
	info->eip_fn_namelen = 9;
f0102848:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010284f:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0102852:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102859:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010285f:	76 11                	jbe    f0102872 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102861:	b8 89 be 10 f0       	mov    $0xf010be89,%eax
f0102866:	3d e5 a0 10 f0       	cmp    $0xf010a0e5,%eax
f010286b:	77 19                	ja     f0102886 <debuginfo_eip+0x61>
f010286d:	e9 a5 01 00 00       	jmp    f0102a17 <debuginfo_eip+0x1f2>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102872:	83 ec 04             	sub    $0x4,%esp
f0102875:	68 1e 46 10 f0       	push   $0xf010461e
f010287a:	6a 7f                	push   $0x7f
f010287c:	68 2b 46 10 f0       	push   $0xf010462b
f0102881:	e8 05 d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102886:	80 3d 88 be 10 f0 00 	cmpb   $0x0,0xf010be88
f010288d:	0f 85 8b 01 00 00    	jne    f0102a1e <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102893:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010289a:	b8 e4 a0 10 f0       	mov    $0xf010a0e4,%eax
f010289f:	2d 70 48 10 f0       	sub    $0xf0104870,%eax
f01028a4:	c1 f8 02             	sar    $0x2,%eax
f01028a7:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01028ad:	83 e8 01             	sub    $0x1,%eax
f01028b0:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01028b3:	83 ec 08             	sub    $0x8,%esp
f01028b6:	57                   	push   %edi
f01028b7:	6a 64                	push   $0x64
f01028b9:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01028bc:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01028bf:	b8 70 48 10 f0       	mov    $0xf0104870,%eax
f01028c4:	e8 66 fe ff ff       	call   f010272f <stab_binsearch>
	if (lfile == 0)
f01028c9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01028cc:	83 c4 10             	add    $0x10,%esp
f01028cf:	85 c0                	test   %eax,%eax
f01028d1:	0f 84 4e 01 00 00    	je     f0102a25 <debuginfo_eip+0x200>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01028d7:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01028da:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01028dd:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01028e0:	83 ec 08             	sub    $0x8,%esp
f01028e3:	57                   	push   %edi
f01028e4:	6a 24                	push   $0x24
f01028e6:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01028e9:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01028ec:	b8 70 48 10 f0       	mov    $0xf0104870,%eax
f01028f1:	e8 39 fe ff ff       	call   f010272f <stab_binsearch>

	if (lfun <= rfun) {
f01028f6:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01028f9:	83 c4 10             	add    $0x10,%esp
f01028fc:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f01028ff:	7f 33                	jg     f0102934 <debuginfo_eip+0x10f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102901:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102904:	c1 e0 02             	shl    $0x2,%eax
f0102907:	8d 90 70 48 10 f0    	lea    -0xfefb790(%eax),%edx
f010290d:	8b 88 70 48 10 f0    	mov    -0xfefb790(%eax),%ecx
f0102913:	b8 89 be 10 f0       	mov    $0xf010be89,%eax
f0102918:	2d e5 a0 10 f0       	sub    $0xf010a0e5,%eax
f010291d:	39 c1                	cmp    %eax,%ecx
f010291f:	73 09                	jae    f010292a <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102921:	81 c1 e5 a0 10 f0    	add    $0xf010a0e5,%ecx
f0102927:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010292a:	8b 42 08             	mov    0x8(%edx),%eax
f010292d:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f0102930:	29 c7                	sub    %eax,%edi
f0102932:	eb 06                	jmp    f010293a <debuginfo_eip+0x115>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102934:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0102937:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010293a:	83 ec 08             	sub    $0x8,%esp
f010293d:	6a 3a                	push   $0x3a
f010293f:	ff 76 08             	pushl  0x8(%esi)
f0102942:	e8 6c 08 00 00       	call   f01031b3 <strfind>
f0102947:	2b 46 08             	sub    0x8(%esi),%eax
f010294a:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
f010294d:	83 c4 08             	add    $0x8,%esp
f0102950:	2b 7e 10             	sub    0x10(%esi),%edi
f0102953:	57                   	push   %edi
f0102954:	6a 44                	push   $0x44
f0102956:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102959:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010295c:	b8 70 48 10 f0       	mov    $0xf0104870,%eax
f0102961:	e8 c9 fd ff ff       	call   f010272f <stab_binsearch>
	if (lfun > rfun) 
f0102966:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102969:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010296c:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f010296f:	83 c4 10             	add    $0x10,%esp
f0102972:	39 c8                	cmp    %ecx,%eax
f0102974:	0f 8f b2 00 00 00    	jg     f0102a2c <debuginfo_eip+0x207>
       	  return -1;
        info->eip_line = stabs[lfun].n_desc;
f010297a:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010297d:	8d 04 85 70 48 10 f0 	lea    -0xfefb790(,%eax,4),%eax
f0102984:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102987:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f010298b:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010298e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102991:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102994:	8d 04 85 70 48 10 f0 	lea    -0xfefb790(,%eax,4),%eax
f010299b:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f010299e:	eb 06                	jmp    f01029a6 <debuginfo_eip+0x181>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01029a0:	83 eb 01             	sub    $0x1,%ebx
f01029a3:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01029a6:	39 fb                	cmp    %edi,%ebx
f01029a8:	7c 39                	jl     f01029e3 <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f01029aa:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01029ae:	80 fa 84             	cmp    $0x84,%dl
f01029b1:	74 0b                	je     f01029be <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01029b3:	80 fa 64             	cmp    $0x64,%dl
f01029b6:	75 e8                	jne    f01029a0 <debuginfo_eip+0x17b>
f01029b8:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01029bc:	74 e2                	je     f01029a0 <debuginfo_eip+0x17b>
f01029be:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01029c1:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01029c4:	8b 14 85 70 48 10 f0 	mov    -0xfefb790(,%eax,4),%edx
f01029cb:	b8 89 be 10 f0       	mov    $0xf010be89,%eax
f01029d0:	2d e5 a0 10 f0       	sub    $0xf010a0e5,%eax
f01029d5:	39 c2                	cmp    %eax,%edx
f01029d7:	73 0d                	jae    f01029e6 <debuginfo_eip+0x1c1>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01029d9:	81 c2 e5 a0 10 f0    	add    $0xf010a0e5,%edx
f01029df:	89 16                	mov    %edx,(%esi)
f01029e1:	eb 03                	jmp    f01029e6 <debuginfo_eip+0x1c1>
f01029e3:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029e6:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029eb:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01029ee:	39 cf                	cmp    %ecx,%edi
f01029f0:	7d 46                	jge    f0102a38 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
f01029f2:	89 f8                	mov    %edi,%eax
f01029f4:	83 c0 01             	add    $0x1,%eax
f01029f7:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01029fa:	eb 07                	jmp    f0102a03 <debuginfo_eip+0x1de>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01029fc:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102a00:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102a03:	39 c8                	cmp    %ecx,%eax
f0102a05:	74 2c                	je     f0102a33 <debuginfo_eip+0x20e>
f0102a07:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102a0a:	80 7a 04 a0          	cmpb   $0xa0,0x4(%edx)
f0102a0e:	74 ec                	je     f01029fc <debuginfo_eip+0x1d7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a10:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a15:	eb 21                	jmp    f0102a38 <debuginfo_eip+0x213>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a1c:	eb 1a                	jmp    f0102a38 <debuginfo_eip+0x213>
f0102a1e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a23:	eb 13                	jmp    f0102a38 <debuginfo_eip+0x213>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a25:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a2a:	eb 0c                	jmp    f0102a38 <debuginfo_eip+0x213>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
	if (lfun > rfun) 
       	  return -1;
f0102a2c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a31:	eb 05                	jmp    f0102a38 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a33:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a38:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a3b:	5b                   	pop    %ebx
f0102a3c:	5e                   	pop    %esi
f0102a3d:	5f                   	pop    %edi
f0102a3e:	5d                   	pop    %ebp
f0102a3f:	c3                   	ret    

f0102a40 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a40:	55                   	push   %ebp
f0102a41:	89 e5                	mov    %esp,%ebp
f0102a43:	57                   	push   %edi
f0102a44:	56                   	push   %esi
f0102a45:	53                   	push   %ebx
f0102a46:	83 ec 1c             	sub    $0x1c,%esp
f0102a49:	89 c7                	mov    %eax,%edi
f0102a4b:	89 d6                	mov    %edx,%esi
f0102a4d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a50:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a53:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102a56:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102a59:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102a5c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a61:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102a64:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102a67:	39 d3                	cmp    %edx,%ebx
f0102a69:	72 05                	jb     f0102a70 <printnum+0x30>
f0102a6b:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102a6e:	77 45                	ja     f0102ab5 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102a70:	83 ec 0c             	sub    $0xc,%esp
f0102a73:	ff 75 18             	pushl  0x18(%ebp)
f0102a76:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a79:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102a7c:	53                   	push   %ebx
f0102a7d:	ff 75 10             	pushl  0x10(%ebp)
f0102a80:	83 ec 08             	sub    $0x8,%esp
f0102a83:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a86:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a89:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a8c:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a8f:	e8 4c 09 00 00       	call   f01033e0 <__udivdi3>
f0102a94:	83 c4 18             	add    $0x18,%esp
f0102a97:	52                   	push   %edx
f0102a98:	50                   	push   %eax
f0102a99:	89 f2                	mov    %esi,%edx
f0102a9b:	89 f8                	mov    %edi,%eax
f0102a9d:	e8 9e ff ff ff       	call   f0102a40 <printnum>
f0102aa2:	83 c4 20             	add    $0x20,%esp
f0102aa5:	eb 18                	jmp    f0102abf <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102aa7:	83 ec 08             	sub    $0x8,%esp
f0102aaa:	56                   	push   %esi
f0102aab:	ff 75 18             	pushl  0x18(%ebp)
f0102aae:	ff d7                	call   *%edi
f0102ab0:	83 c4 10             	add    $0x10,%esp
f0102ab3:	eb 03                	jmp    f0102ab8 <printnum+0x78>
f0102ab5:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102ab8:	83 eb 01             	sub    $0x1,%ebx
f0102abb:	85 db                	test   %ebx,%ebx
f0102abd:	7f e8                	jg     f0102aa7 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102abf:	83 ec 08             	sub    $0x8,%esp
f0102ac2:	56                   	push   %esi
f0102ac3:	83 ec 04             	sub    $0x4,%esp
f0102ac6:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102ac9:	ff 75 e0             	pushl  -0x20(%ebp)
f0102acc:	ff 75 dc             	pushl  -0x24(%ebp)
f0102acf:	ff 75 d8             	pushl  -0x28(%ebp)
f0102ad2:	e8 39 0a 00 00       	call   f0103510 <__umoddi3>
f0102ad7:	83 c4 14             	add    $0x14,%esp
f0102ada:	0f be 80 39 46 10 f0 	movsbl -0xfefb9c7(%eax),%eax
f0102ae1:	50                   	push   %eax
f0102ae2:	ff d7                	call   *%edi
}
f0102ae4:	83 c4 10             	add    $0x10,%esp
f0102ae7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102aea:	5b                   	pop    %ebx
f0102aeb:	5e                   	pop    %esi
f0102aec:	5f                   	pop    %edi
f0102aed:	5d                   	pop    %ebp
f0102aee:	c3                   	ret    

f0102aef <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102aef:	55                   	push   %ebp
f0102af0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102af2:	83 fa 01             	cmp    $0x1,%edx
f0102af5:	7e 0e                	jle    f0102b05 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102af7:	8b 10                	mov    (%eax),%edx
f0102af9:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102afc:	89 08                	mov    %ecx,(%eax)
f0102afe:	8b 02                	mov    (%edx),%eax
f0102b00:	8b 52 04             	mov    0x4(%edx),%edx
f0102b03:	eb 22                	jmp    f0102b27 <getuint+0x38>
	else if (lflag)
f0102b05:	85 d2                	test   %edx,%edx
f0102b07:	74 10                	je     f0102b19 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102b09:	8b 10                	mov    (%eax),%edx
f0102b0b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b0e:	89 08                	mov    %ecx,(%eax)
f0102b10:	8b 02                	mov    (%edx),%eax
f0102b12:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b17:	eb 0e                	jmp    f0102b27 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102b19:	8b 10                	mov    (%eax),%edx
f0102b1b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b1e:	89 08                	mov    %ecx,(%eax)
f0102b20:	8b 02                	mov    (%edx),%eax
f0102b22:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102b27:	5d                   	pop    %ebp
f0102b28:	c3                   	ret    

f0102b29 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b29:	55                   	push   %ebp
f0102b2a:	89 e5                	mov    %esp,%ebp
f0102b2c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b2f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b33:	8b 10                	mov    (%eax),%edx
f0102b35:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b38:	73 0a                	jae    f0102b44 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b3a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b3d:	89 08                	mov    %ecx,(%eax)
f0102b3f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b42:	88 02                	mov    %al,(%edx)
}
f0102b44:	5d                   	pop    %ebp
f0102b45:	c3                   	ret    

f0102b46 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b46:	55                   	push   %ebp
f0102b47:	89 e5                	mov    %esp,%ebp
f0102b49:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b4c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b4f:	50                   	push   %eax
f0102b50:	ff 75 10             	pushl  0x10(%ebp)
f0102b53:	ff 75 0c             	pushl  0xc(%ebp)
f0102b56:	ff 75 08             	pushl  0x8(%ebp)
f0102b59:	e8 05 00 00 00       	call   f0102b63 <vprintfmt>
	va_end(ap);
}
f0102b5e:	83 c4 10             	add    $0x10,%esp
f0102b61:	c9                   	leave  
f0102b62:	c3                   	ret    

f0102b63 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102b63:	55                   	push   %ebp
f0102b64:	89 e5                	mov    %esp,%ebp
f0102b66:	57                   	push   %edi
f0102b67:	56                   	push   %esi
f0102b68:	53                   	push   %ebx
f0102b69:	83 ec 2c             	sub    $0x2c,%esp
f0102b6c:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b6f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b72:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102b75:	eb 12                	jmp    f0102b89 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102b77:	85 c0                	test   %eax,%eax
f0102b79:	0f 84 89 03 00 00    	je     f0102f08 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102b7f:	83 ec 08             	sub    $0x8,%esp
f0102b82:	53                   	push   %ebx
f0102b83:	50                   	push   %eax
f0102b84:	ff d6                	call   *%esi
f0102b86:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102b89:	83 c7 01             	add    $0x1,%edi
f0102b8c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102b90:	83 f8 25             	cmp    $0x25,%eax
f0102b93:	75 e2                	jne    f0102b77 <vprintfmt+0x14>
f0102b95:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102b99:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102ba0:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102ba7:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102bae:	ba 00 00 00 00       	mov    $0x0,%edx
f0102bb3:	eb 07                	jmp    f0102bbc <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bb5:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102bb8:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bbc:	8d 47 01             	lea    0x1(%edi),%eax
f0102bbf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102bc2:	0f b6 07             	movzbl (%edi),%eax
f0102bc5:	0f b6 c8             	movzbl %al,%ecx
f0102bc8:	83 e8 23             	sub    $0x23,%eax
f0102bcb:	3c 55                	cmp    $0x55,%al
f0102bcd:	0f 87 1a 03 00 00    	ja     f0102eed <vprintfmt+0x38a>
f0102bd3:	0f b6 c0             	movzbl %al,%eax
f0102bd6:	ff 24 85 e0 46 10 f0 	jmp    *-0xfefb920(,%eax,4)
f0102bdd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102be0:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102be4:	eb d6                	jmp    f0102bbc <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102be6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102be9:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bee:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102bf1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102bf4:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102bf8:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102bfb:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102bfe:	83 fa 09             	cmp    $0x9,%edx
f0102c01:	77 39                	ja     f0102c3c <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102c03:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102c06:	eb e9                	jmp    f0102bf1 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102c08:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c0b:	8d 48 04             	lea    0x4(%eax),%ecx
f0102c0e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102c11:	8b 00                	mov    (%eax),%eax
f0102c13:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c16:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102c19:	eb 27                	jmp    f0102c42 <vprintfmt+0xdf>
f0102c1b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102c1e:	85 c0                	test   %eax,%eax
f0102c20:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102c25:	0f 49 c8             	cmovns %eax,%ecx
f0102c28:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c2b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c2e:	eb 8c                	jmp    f0102bbc <vprintfmt+0x59>
f0102c30:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c33:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c3a:	eb 80                	jmp    f0102bbc <vprintfmt+0x59>
f0102c3c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102c3f:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c42:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c46:	0f 89 70 ff ff ff    	jns    f0102bbc <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c4c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c4f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c52:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c59:	e9 5e ff ff ff       	jmp    f0102bbc <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102c5e:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c61:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102c64:	e9 53 ff ff ff       	jmp    f0102bbc <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c69:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c6c:	8d 50 04             	lea    0x4(%eax),%edx
f0102c6f:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c72:	83 ec 08             	sub    $0x8,%esp
f0102c75:	53                   	push   %ebx
f0102c76:	ff 30                	pushl  (%eax)
f0102c78:	ff d6                	call   *%esi
			break;
f0102c7a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c7d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102c80:	e9 04 ff ff ff       	jmp    f0102b89 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c85:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c88:	8d 50 04             	lea    0x4(%eax),%edx
f0102c8b:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c8e:	8b 00                	mov    (%eax),%eax
f0102c90:	99                   	cltd   
f0102c91:	31 d0                	xor    %edx,%eax
f0102c93:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102c95:	83 f8 07             	cmp    $0x7,%eax
f0102c98:	7f 0b                	jg     f0102ca5 <vprintfmt+0x142>
f0102c9a:	8b 14 85 40 48 10 f0 	mov    -0xfefb7c0(,%eax,4),%edx
f0102ca1:	85 d2                	test   %edx,%edx
f0102ca3:	75 18                	jne    f0102cbd <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102ca5:	50                   	push   %eax
f0102ca6:	68 51 46 10 f0       	push   $0xf0104651
f0102cab:	53                   	push   %ebx
f0102cac:	56                   	push   %esi
f0102cad:	e8 94 fe ff ff       	call   f0102b46 <printfmt>
f0102cb2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cb5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102cb8:	e9 cc fe ff ff       	jmp    f0102b89 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102cbd:	52                   	push   %edx
f0102cbe:	68 50 43 10 f0       	push   $0xf0104350
f0102cc3:	53                   	push   %ebx
f0102cc4:	56                   	push   %esi
f0102cc5:	e8 7c fe ff ff       	call   f0102b46 <printfmt>
f0102cca:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ccd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cd0:	e9 b4 fe ff ff       	jmp    f0102b89 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102cd5:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cd8:	8d 50 04             	lea    0x4(%eax),%edx
f0102cdb:	89 55 14             	mov    %edx,0x14(%ebp)
f0102cde:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102ce0:	85 ff                	test   %edi,%edi
f0102ce2:	b8 4a 46 10 f0       	mov    $0xf010464a,%eax
f0102ce7:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102cea:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102cee:	0f 8e 94 00 00 00    	jle    f0102d88 <vprintfmt+0x225>
f0102cf4:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102cf8:	0f 84 98 00 00 00    	je     f0102d96 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cfe:	83 ec 08             	sub    $0x8,%esp
f0102d01:	ff 75 d0             	pushl  -0x30(%ebp)
f0102d04:	57                   	push   %edi
f0102d05:	e8 5f 03 00 00       	call   f0103069 <strnlen>
f0102d0a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d0d:	29 c1                	sub    %eax,%ecx
f0102d0f:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102d12:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102d15:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102d19:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d1c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102d1f:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d21:	eb 0f                	jmp    f0102d32 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102d23:	83 ec 08             	sub    $0x8,%esp
f0102d26:	53                   	push   %ebx
f0102d27:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d2a:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d2c:	83 ef 01             	sub    $0x1,%edi
f0102d2f:	83 c4 10             	add    $0x10,%esp
f0102d32:	85 ff                	test   %edi,%edi
f0102d34:	7f ed                	jg     f0102d23 <vprintfmt+0x1c0>
f0102d36:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d39:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d3c:	85 c9                	test   %ecx,%ecx
f0102d3e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d43:	0f 49 c1             	cmovns %ecx,%eax
f0102d46:	29 c1                	sub    %eax,%ecx
f0102d48:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d4b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d4e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d51:	89 cb                	mov    %ecx,%ebx
f0102d53:	eb 4d                	jmp    f0102da2 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102d55:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102d59:	74 1b                	je     f0102d76 <vprintfmt+0x213>
f0102d5b:	0f be c0             	movsbl %al,%eax
f0102d5e:	83 e8 20             	sub    $0x20,%eax
f0102d61:	83 f8 5e             	cmp    $0x5e,%eax
f0102d64:	76 10                	jbe    f0102d76 <vprintfmt+0x213>
					putch('?', putdat);
f0102d66:	83 ec 08             	sub    $0x8,%esp
f0102d69:	ff 75 0c             	pushl  0xc(%ebp)
f0102d6c:	6a 3f                	push   $0x3f
f0102d6e:	ff 55 08             	call   *0x8(%ebp)
f0102d71:	83 c4 10             	add    $0x10,%esp
f0102d74:	eb 0d                	jmp    f0102d83 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102d76:	83 ec 08             	sub    $0x8,%esp
f0102d79:	ff 75 0c             	pushl  0xc(%ebp)
f0102d7c:	52                   	push   %edx
f0102d7d:	ff 55 08             	call   *0x8(%ebp)
f0102d80:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102d83:	83 eb 01             	sub    $0x1,%ebx
f0102d86:	eb 1a                	jmp    f0102da2 <vprintfmt+0x23f>
f0102d88:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d8b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d8e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d91:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d94:	eb 0c                	jmp    f0102da2 <vprintfmt+0x23f>
f0102d96:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d99:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d9c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d9f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102da2:	83 c7 01             	add    $0x1,%edi
f0102da5:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102da9:	0f be d0             	movsbl %al,%edx
f0102dac:	85 d2                	test   %edx,%edx
f0102dae:	74 23                	je     f0102dd3 <vprintfmt+0x270>
f0102db0:	85 f6                	test   %esi,%esi
f0102db2:	78 a1                	js     f0102d55 <vprintfmt+0x1f2>
f0102db4:	83 ee 01             	sub    $0x1,%esi
f0102db7:	79 9c                	jns    f0102d55 <vprintfmt+0x1f2>
f0102db9:	89 df                	mov    %ebx,%edi
f0102dbb:	8b 75 08             	mov    0x8(%ebp),%esi
f0102dbe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102dc1:	eb 18                	jmp    f0102ddb <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102dc3:	83 ec 08             	sub    $0x8,%esp
f0102dc6:	53                   	push   %ebx
f0102dc7:	6a 20                	push   $0x20
f0102dc9:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102dcb:	83 ef 01             	sub    $0x1,%edi
f0102dce:	83 c4 10             	add    $0x10,%esp
f0102dd1:	eb 08                	jmp    f0102ddb <vprintfmt+0x278>
f0102dd3:	89 df                	mov    %ebx,%edi
f0102dd5:	8b 75 08             	mov    0x8(%ebp),%esi
f0102dd8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ddb:	85 ff                	test   %edi,%edi
f0102ddd:	7f e4                	jg     f0102dc3 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ddf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102de2:	e9 a2 fd ff ff       	jmp    f0102b89 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102de7:	83 fa 01             	cmp    $0x1,%edx
f0102dea:	7e 16                	jle    f0102e02 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102dec:	8b 45 14             	mov    0x14(%ebp),%eax
f0102def:	8d 50 08             	lea    0x8(%eax),%edx
f0102df2:	89 55 14             	mov    %edx,0x14(%ebp)
f0102df5:	8b 50 04             	mov    0x4(%eax),%edx
f0102df8:	8b 00                	mov    (%eax),%eax
f0102dfa:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102dfd:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102e00:	eb 32                	jmp    f0102e34 <vprintfmt+0x2d1>
	else if (lflag)
f0102e02:	85 d2                	test   %edx,%edx
f0102e04:	74 18                	je     f0102e1e <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102e06:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e09:	8d 50 04             	lea    0x4(%eax),%edx
f0102e0c:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e0f:	8b 00                	mov    (%eax),%eax
f0102e11:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e14:	89 c1                	mov    %eax,%ecx
f0102e16:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e19:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102e1c:	eb 16                	jmp    f0102e34 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102e1e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e21:	8d 50 04             	lea    0x4(%eax),%edx
f0102e24:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e27:	8b 00                	mov    (%eax),%eax
f0102e29:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e2c:	89 c1                	mov    %eax,%ecx
f0102e2e:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e31:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e34:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e37:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e3a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e3f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e43:	79 74                	jns    f0102eb9 <vprintfmt+0x356>
				putch('-', putdat);
f0102e45:	83 ec 08             	sub    $0x8,%esp
f0102e48:	53                   	push   %ebx
f0102e49:	6a 2d                	push   $0x2d
f0102e4b:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e4d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e50:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102e53:	f7 d8                	neg    %eax
f0102e55:	83 d2 00             	adc    $0x0,%edx
f0102e58:	f7 da                	neg    %edx
f0102e5a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102e5d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102e62:	eb 55                	jmp    f0102eb9 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102e64:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e67:	e8 83 fc ff ff       	call   f0102aef <getuint>
			base = 10;
f0102e6c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102e71:	eb 46                	jmp    f0102eb9 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0102e73:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e76:	e8 74 fc ff ff       	call   f0102aef <getuint>
			base = 8;
f0102e7b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102e80:	eb 37                	jmp    f0102eb9 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0102e82:	83 ec 08             	sub    $0x8,%esp
f0102e85:	53                   	push   %ebx
f0102e86:	6a 30                	push   $0x30
f0102e88:	ff d6                	call   *%esi
			putch('x', putdat);
f0102e8a:	83 c4 08             	add    $0x8,%esp
f0102e8d:	53                   	push   %ebx
f0102e8e:	6a 78                	push   $0x78
f0102e90:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102e92:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e95:	8d 50 04             	lea    0x4(%eax),%edx
f0102e98:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102e9b:	8b 00                	mov    (%eax),%eax
f0102e9d:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102ea2:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102ea5:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102eaa:	eb 0d                	jmp    f0102eb9 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102eac:	8d 45 14             	lea    0x14(%ebp),%eax
f0102eaf:	e8 3b fc ff ff       	call   f0102aef <getuint>
			base = 16;
f0102eb4:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102eb9:	83 ec 0c             	sub    $0xc,%esp
f0102ebc:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102ec0:	57                   	push   %edi
f0102ec1:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ec4:	51                   	push   %ecx
f0102ec5:	52                   	push   %edx
f0102ec6:	50                   	push   %eax
f0102ec7:	89 da                	mov    %ebx,%edx
f0102ec9:	89 f0                	mov    %esi,%eax
f0102ecb:	e8 70 fb ff ff       	call   f0102a40 <printnum>
			break;
f0102ed0:	83 c4 20             	add    $0x20,%esp
f0102ed3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ed6:	e9 ae fc ff ff       	jmp    f0102b89 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102edb:	83 ec 08             	sub    $0x8,%esp
f0102ede:	53                   	push   %ebx
f0102edf:	51                   	push   %ecx
f0102ee0:	ff d6                	call   *%esi
			break;
f0102ee2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ee5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102ee8:	e9 9c fc ff ff       	jmp    f0102b89 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102eed:	83 ec 08             	sub    $0x8,%esp
f0102ef0:	53                   	push   %ebx
f0102ef1:	6a 25                	push   $0x25
f0102ef3:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102ef5:	83 c4 10             	add    $0x10,%esp
f0102ef8:	eb 03                	jmp    f0102efd <vprintfmt+0x39a>
f0102efa:	83 ef 01             	sub    $0x1,%edi
f0102efd:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102f01:	75 f7                	jne    f0102efa <vprintfmt+0x397>
f0102f03:	e9 81 fc ff ff       	jmp    f0102b89 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102f08:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f0b:	5b                   	pop    %ebx
f0102f0c:	5e                   	pop    %esi
f0102f0d:	5f                   	pop    %edi
f0102f0e:	5d                   	pop    %ebp
f0102f0f:	c3                   	ret    

f0102f10 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102f10:	55                   	push   %ebp
f0102f11:	89 e5                	mov    %esp,%ebp
f0102f13:	83 ec 18             	sub    $0x18,%esp
f0102f16:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f19:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102f1c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f1f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102f23:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f26:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102f2d:	85 c0                	test   %eax,%eax
f0102f2f:	74 26                	je     f0102f57 <vsnprintf+0x47>
f0102f31:	85 d2                	test   %edx,%edx
f0102f33:	7e 22                	jle    f0102f57 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102f35:	ff 75 14             	pushl  0x14(%ebp)
f0102f38:	ff 75 10             	pushl  0x10(%ebp)
f0102f3b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102f3e:	50                   	push   %eax
f0102f3f:	68 29 2b 10 f0       	push   $0xf0102b29
f0102f44:	e8 1a fc ff ff       	call   f0102b63 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102f49:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102f4c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102f4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f52:	83 c4 10             	add    $0x10,%esp
f0102f55:	eb 05                	jmp    f0102f5c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102f57:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102f5c:	c9                   	leave  
f0102f5d:	c3                   	ret    

f0102f5e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102f5e:	55                   	push   %ebp
f0102f5f:	89 e5                	mov    %esp,%ebp
f0102f61:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102f64:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102f67:	50                   	push   %eax
f0102f68:	ff 75 10             	pushl  0x10(%ebp)
f0102f6b:	ff 75 0c             	pushl  0xc(%ebp)
f0102f6e:	ff 75 08             	pushl  0x8(%ebp)
f0102f71:	e8 9a ff ff ff       	call   f0102f10 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102f76:	c9                   	leave  
f0102f77:	c3                   	ret    

f0102f78 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102f78:	55                   	push   %ebp
f0102f79:	89 e5                	mov    %esp,%ebp
f0102f7b:	57                   	push   %edi
f0102f7c:	56                   	push   %esi
f0102f7d:	53                   	push   %ebx
f0102f7e:	83 ec 0c             	sub    $0xc,%esp
f0102f81:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102f84:	85 c0                	test   %eax,%eax
f0102f86:	74 11                	je     f0102f99 <readline+0x21>
		cprintf("%s", prompt);
f0102f88:	83 ec 08             	sub    $0x8,%esp
f0102f8b:	50                   	push   %eax
f0102f8c:	68 50 43 10 f0       	push   $0xf0104350
f0102f91:	e8 85 f7 ff ff       	call   f010271b <cprintf>
f0102f96:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102f99:	83 ec 0c             	sub    $0xc,%esp
f0102f9c:	6a 00                	push   $0x0
f0102f9e:	e8 a3 d6 ff ff       	call   f0100646 <iscons>
f0102fa3:	89 c7                	mov    %eax,%edi
f0102fa5:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102fa8:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102fad:	e8 83 d6 ff ff       	call   f0100635 <getchar>
f0102fb2:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102fb4:	85 c0                	test   %eax,%eax
f0102fb6:	79 18                	jns    f0102fd0 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102fb8:	83 ec 08             	sub    $0x8,%esp
f0102fbb:	50                   	push   %eax
f0102fbc:	68 60 48 10 f0       	push   $0xf0104860
f0102fc1:	e8 55 f7 ff ff       	call   f010271b <cprintf>
			return NULL;
f0102fc6:	83 c4 10             	add    $0x10,%esp
f0102fc9:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fce:	eb 79                	jmp    f0103049 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102fd0:	83 f8 08             	cmp    $0x8,%eax
f0102fd3:	0f 94 c2             	sete   %dl
f0102fd6:	83 f8 7f             	cmp    $0x7f,%eax
f0102fd9:	0f 94 c0             	sete   %al
f0102fdc:	08 c2                	or     %al,%dl
f0102fde:	74 1a                	je     f0102ffa <readline+0x82>
f0102fe0:	85 f6                	test   %esi,%esi
f0102fe2:	7e 16                	jle    f0102ffa <readline+0x82>
			if (echoing)
f0102fe4:	85 ff                	test   %edi,%edi
f0102fe6:	74 0d                	je     f0102ff5 <readline+0x7d>
				cputchar('\b');
f0102fe8:	83 ec 0c             	sub    $0xc,%esp
f0102feb:	6a 08                	push   $0x8
f0102fed:	e8 33 d6 ff ff       	call   f0100625 <cputchar>
f0102ff2:	83 c4 10             	add    $0x10,%esp
			i--;
f0102ff5:	83 ee 01             	sub    $0x1,%esi
f0102ff8:	eb b3                	jmp    f0102fad <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102ffa:	83 fb 1f             	cmp    $0x1f,%ebx
f0102ffd:	7e 23                	jle    f0103022 <readline+0xaa>
f0102fff:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103005:	7f 1b                	jg     f0103022 <readline+0xaa>
			if (echoing)
f0103007:	85 ff                	test   %edi,%edi
f0103009:	74 0c                	je     f0103017 <readline+0x9f>
				cputchar(c);
f010300b:	83 ec 0c             	sub    $0xc,%esp
f010300e:	53                   	push   %ebx
f010300f:	e8 11 d6 ff ff       	call   f0100625 <cputchar>
f0103014:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103017:	88 9e 60 65 11 f0    	mov    %bl,-0xfee9aa0(%esi)
f010301d:	8d 76 01             	lea    0x1(%esi),%esi
f0103020:	eb 8b                	jmp    f0102fad <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103022:	83 fb 0a             	cmp    $0xa,%ebx
f0103025:	74 05                	je     f010302c <readline+0xb4>
f0103027:	83 fb 0d             	cmp    $0xd,%ebx
f010302a:	75 81                	jne    f0102fad <readline+0x35>
			if (echoing)
f010302c:	85 ff                	test   %edi,%edi
f010302e:	74 0d                	je     f010303d <readline+0xc5>
				cputchar('\n');
f0103030:	83 ec 0c             	sub    $0xc,%esp
f0103033:	6a 0a                	push   $0xa
f0103035:	e8 eb d5 ff ff       	call   f0100625 <cputchar>
f010303a:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010303d:	c6 86 60 65 11 f0 00 	movb   $0x0,-0xfee9aa0(%esi)
			return buf;
f0103044:	b8 60 65 11 f0       	mov    $0xf0116560,%eax
		}
	}
}
f0103049:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010304c:	5b                   	pop    %ebx
f010304d:	5e                   	pop    %esi
f010304e:	5f                   	pop    %edi
f010304f:	5d                   	pop    %ebp
f0103050:	c3                   	ret    

f0103051 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103051:	55                   	push   %ebp
f0103052:	89 e5                	mov    %esp,%ebp
f0103054:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103057:	b8 00 00 00 00       	mov    $0x0,%eax
f010305c:	eb 03                	jmp    f0103061 <strlen+0x10>
		n++;
f010305e:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103061:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103065:	75 f7                	jne    f010305e <strlen+0xd>
		n++;
	return n;
}
f0103067:	5d                   	pop    %ebp
f0103068:	c3                   	ret    

f0103069 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103069:	55                   	push   %ebp
f010306a:	89 e5                	mov    %esp,%ebp
f010306c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010306f:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103072:	ba 00 00 00 00       	mov    $0x0,%edx
f0103077:	eb 03                	jmp    f010307c <strnlen+0x13>
		n++;
f0103079:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010307c:	39 c2                	cmp    %eax,%edx
f010307e:	74 08                	je     f0103088 <strnlen+0x1f>
f0103080:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103084:	75 f3                	jne    f0103079 <strnlen+0x10>
f0103086:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103088:	5d                   	pop    %ebp
f0103089:	c3                   	ret    

f010308a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010308a:	55                   	push   %ebp
f010308b:	89 e5                	mov    %esp,%ebp
f010308d:	53                   	push   %ebx
f010308e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103091:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103094:	89 c2                	mov    %eax,%edx
f0103096:	83 c2 01             	add    $0x1,%edx
f0103099:	83 c1 01             	add    $0x1,%ecx
f010309c:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01030a0:	88 5a ff             	mov    %bl,-0x1(%edx)
f01030a3:	84 db                	test   %bl,%bl
f01030a5:	75 ef                	jne    f0103096 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01030a7:	5b                   	pop    %ebx
f01030a8:	5d                   	pop    %ebp
f01030a9:	c3                   	ret    

f01030aa <strcat>:

char *
strcat(char *dst, const char *src)
{
f01030aa:	55                   	push   %ebp
f01030ab:	89 e5                	mov    %esp,%ebp
f01030ad:	53                   	push   %ebx
f01030ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01030b1:	53                   	push   %ebx
f01030b2:	e8 9a ff ff ff       	call   f0103051 <strlen>
f01030b7:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01030ba:	ff 75 0c             	pushl  0xc(%ebp)
f01030bd:	01 d8                	add    %ebx,%eax
f01030bf:	50                   	push   %eax
f01030c0:	e8 c5 ff ff ff       	call   f010308a <strcpy>
	return dst;
}
f01030c5:	89 d8                	mov    %ebx,%eax
f01030c7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030ca:	c9                   	leave  
f01030cb:	c3                   	ret    

f01030cc <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01030cc:	55                   	push   %ebp
f01030cd:	89 e5                	mov    %esp,%ebp
f01030cf:	56                   	push   %esi
f01030d0:	53                   	push   %ebx
f01030d1:	8b 75 08             	mov    0x8(%ebp),%esi
f01030d4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030d7:	89 f3                	mov    %esi,%ebx
f01030d9:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030dc:	89 f2                	mov    %esi,%edx
f01030de:	eb 0f                	jmp    f01030ef <strncpy+0x23>
		*dst++ = *src;
f01030e0:	83 c2 01             	add    $0x1,%edx
f01030e3:	0f b6 01             	movzbl (%ecx),%eax
f01030e6:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01030e9:	80 39 01             	cmpb   $0x1,(%ecx)
f01030ec:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030ef:	39 da                	cmp    %ebx,%edx
f01030f1:	75 ed                	jne    f01030e0 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01030f3:	89 f0                	mov    %esi,%eax
f01030f5:	5b                   	pop    %ebx
f01030f6:	5e                   	pop    %esi
f01030f7:	5d                   	pop    %ebp
f01030f8:	c3                   	ret    

f01030f9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01030f9:	55                   	push   %ebp
f01030fa:	89 e5                	mov    %esp,%ebp
f01030fc:	56                   	push   %esi
f01030fd:	53                   	push   %ebx
f01030fe:	8b 75 08             	mov    0x8(%ebp),%esi
f0103101:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103104:	8b 55 10             	mov    0x10(%ebp),%edx
f0103107:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103109:	85 d2                	test   %edx,%edx
f010310b:	74 21                	je     f010312e <strlcpy+0x35>
f010310d:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103111:	89 f2                	mov    %esi,%edx
f0103113:	eb 09                	jmp    f010311e <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103115:	83 c2 01             	add    $0x1,%edx
f0103118:	83 c1 01             	add    $0x1,%ecx
f010311b:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010311e:	39 c2                	cmp    %eax,%edx
f0103120:	74 09                	je     f010312b <strlcpy+0x32>
f0103122:	0f b6 19             	movzbl (%ecx),%ebx
f0103125:	84 db                	test   %bl,%bl
f0103127:	75 ec                	jne    f0103115 <strlcpy+0x1c>
f0103129:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010312b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010312e:	29 f0                	sub    %esi,%eax
}
f0103130:	5b                   	pop    %ebx
f0103131:	5e                   	pop    %esi
f0103132:	5d                   	pop    %ebp
f0103133:	c3                   	ret    

f0103134 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103134:	55                   	push   %ebp
f0103135:	89 e5                	mov    %esp,%ebp
f0103137:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010313a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010313d:	eb 06                	jmp    f0103145 <strcmp+0x11>
		p++, q++;
f010313f:	83 c1 01             	add    $0x1,%ecx
f0103142:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103145:	0f b6 01             	movzbl (%ecx),%eax
f0103148:	84 c0                	test   %al,%al
f010314a:	74 04                	je     f0103150 <strcmp+0x1c>
f010314c:	3a 02                	cmp    (%edx),%al
f010314e:	74 ef                	je     f010313f <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103150:	0f b6 c0             	movzbl %al,%eax
f0103153:	0f b6 12             	movzbl (%edx),%edx
f0103156:	29 d0                	sub    %edx,%eax
}
f0103158:	5d                   	pop    %ebp
f0103159:	c3                   	ret    

f010315a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010315a:	55                   	push   %ebp
f010315b:	89 e5                	mov    %esp,%ebp
f010315d:	53                   	push   %ebx
f010315e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103161:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103164:	89 c3                	mov    %eax,%ebx
f0103166:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103169:	eb 06                	jmp    f0103171 <strncmp+0x17>
		n--, p++, q++;
f010316b:	83 c0 01             	add    $0x1,%eax
f010316e:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103171:	39 d8                	cmp    %ebx,%eax
f0103173:	74 15                	je     f010318a <strncmp+0x30>
f0103175:	0f b6 08             	movzbl (%eax),%ecx
f0103178:	84 c9                	test   %cl,%cl
f010317a:	74 04                	je     f0103180 <strncmp+0x26>
f010317c:	3a 0a                	cmp    (%edx),%cl
f010317e:	74 eb                	je     f010316b <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103180:	0f b6 00             	movzbl (%eax),%eax
f0103183:	0f b6 12             	movzbl (%edx),%edx
f0103186:	29 d0                	sub    %edx,%eax
f0103188:	eb 05                	jmp    f010318f <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010318a:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010318f:	5b                   	pop    %ebx
f0103190:	5d                   	pop    %ebp
f0103191:	c3                   	ret    

f0103192 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103192:	55                   	push   %ebp
f0103193:	89 e5                	mov    %esp,%ebp
f0103195:	8b 45 08             	mov    0x8(%ebp),%eax
f0103198:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010319c:	eb 07                	jmp    f01031a5 <strchr+0x13>
		if (*s == c)
f010319e:	38 ca                	cmp    %cl,%dl
f01031a0:	74 0f                	je     f01031b1 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01031a2:	83 c0 01             	add    $0x1,%eax
f01031a5:	0f b6 10             	movzbl (%eax),%edx
f01031a8:	84 d2                	test   %dl,%dl
f01031aa:	75 f2                	jne    f010319e <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01031ac:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01031b1:	5d                   	pop    %ebp
f01031b2:	c3                   	ret    

f01031b3 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01031b3:	55                   	push   %ebp
f01031b4:	89 e5                	mov    %esp,%ebp
f01031b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01031b9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01031bd:	eb 03                	jmp    f01031c2 <strfind+0xf>
f01031bf:	83 c0 01             	add    $0x1,%eax
f01031c2:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01031c5:	38 ca                	cmp    %cl,%dl
f01031c7:	74 04                	je     f01031cd <strfind+0x1a>
f01031c9:	84 d2                	test   %dl,%dl
f01031cb:	75 f2                	jne    f01031bf <strfind+0xc>
			break;
	return (char *) s;
}
f01031cd:	5d                   	pop    %ebp
f01031ce:	c3                   	ret    

f01031cf <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01031cf:	55                   	push   %ebp
f01031d0:	89 e5                	mov    %esp,%ebp
f01031d2:	57                   	push   %edi
f01031d3:	56                   	push   %esi
f01031d4:	53                   	push   %ebx
f01031d5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01031d8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01031db:	85 c9                	test   %ecx,%ecx
f01031dd:	74 36                	je     f0103215 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01031df:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01031e5:	75 28                	jne    f010320f <memset+0x40>
f01031e7:	f6 c1 03             	test   $0x3,%cl
f01031ea:	75 23                	jne    f010320f <memset+0x40>
		c &= 0xFF;
f01031ec:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01031f0:	89 d3                	mov    %edx,%ebx
f01031f2:	c1 e3 08             	shl    $0x8,%ebx
f01031f5:	89 d6                	mov    %edx,%esi
f01031f7:	c1 e6 18             	shl    $0x18,%esi
f01031fa:	89 d0                	mov    %edx,%eax
f01031fc:	c1 e0 10             	shl    $0x10,%eax
f01031ff:	09 f0                	or     %esi,%eax
f0103201:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0103203:	89 d8                	mov    %ebx,%eax
f0103205:	09 d0                	or     %edx,%eax
f0103207:	c1 e9 02             	shr    $0x2,%ecx
f010320a:	fc                   	cld    
f010320b:	f3 ab                	rep stos %eax,%es:(%edi)
f010320d:	eb 06                	jmp    f0103215 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010320f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103212:	fc                   	cld    
f0103213:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103215:	89 f8                	mov    %edi,%eax
f0103217:	5b                   	pop    %ebx
f0103218:	5e                   	pop    %esi
f0103219:	5f                   	pop    %edi
f010321a:	5d                   	pop    %ebp
f010321b:	c3                   	ret    

f010321c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010321c:	55                   	push   %ebp
f010321d:	89 e5                	mov    %esp,%ebp
f010321f:	57                   	push   %edi
f0103220:	56                   	push   %esi
f0103221:	8b 45 08             	mov    0x8(%ebp),%eax
f0103224:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103227:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010322a:	39 c6                	cmp    %eax,%esi
f010322c:	73 35                	jae    f0103263 <memmove+0x47>
f010322e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103231:	39 d0                	cmp    %edx,%eax
f0103233:	73 2e                	jae    f0103263 <memmove+0x47>
		s += n;
		d += n;
f0103235:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103238:	89 d6                	mov    %edx,%esi
f010323a:	09 fe                	or     %edi,%esi
f010323c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103242:	75 13                	jne    f0103257 <memmove+0x3b>
f0103244:	f6 c1 03             	test   $0x3,%cl
f0103247:	75 0e                	jne    f0103257 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103249:	83 ef 04             	sub    $0x4,%edi
f010324c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010324f:	c1 e9 02             	shr    $0x2,%ecx
f0103252:	fd                   	std    
f0103253:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103255:	eb 09                	jmp    f0103260 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103257:	83 ef 01             	sub    $0x1,%edi
f010325a:	8d 72 ff             	lea    -0x1(%edx),%esi
f010325d:	fd                   	std    
f010325e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103260:	fc                   	cld    
f0103261:	eb 1d                	jmp    f0103280 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103263:	89 f2                	mov    %esi,%edx
f0103265:	09 c2                	or     %eax,%edx
f0103267:	f6 c2 03             	test   $0x3,%dl
f010326a:	75 0f                	jne    f010327b <memmove+0x5f>
f010326c:	f6 c1 03             	test   $0x3,%cl
f010326f:	75 0a                	jne    f010327b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103271:	c1 e9 02             	shr    $0x2,%ecx
f0103274:	89 c7                	mov    %eax,%edi
f0103276:	fc                   	cld    
f0103277:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103279:	eb 05                	jmp    f0103280 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010327b:	89 c7                	mov    %eax,%edi
f010327d:	fc                   	cld    
f010327e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103280:	5e                   	pop    %esi
f0103281:	5f                   	pop    %edi
f0103282:	5d                   	pop    %ebp
f0103283:	c3                   	ret    

f0103284 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103284:	55                   	push   %ebp
f0103285:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103287:	ff 75 10             	pushl  0x10(%ebp)
f010328a:	ff 75 0c             	pushl  0xc(%ebp)
f010328d:	ff 75 08             	pushl  0x8(%ebp)
f0103290:	e8 87 ff ff ff       	call   f010321c <memmove>
}
f0103295:	c9                   	leave  
f0103296:	c3                   	ret    

f0103297 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103297:	55                   	push   %ebp
f0103298:	89 e5                	mov    %esp,%ebp
f010329a:	56                   	push   %esi
f010329b:	53                   	push   %ebx
f010329c:	8b 45 08             	mov    0x8(%ebp),%eax
f010329f:	8b 55 0c             	mov    0xc(%ebp),%edx
f01032a2:	89 c6                	mov    %eax,%esi
f01032a4:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01032a7:	eb 1a                	jmp    f01032c3 <memcmp+0x2c>
		if (*s1 != *s2)
f01032a9:	0f b6 08             	movzbl (%eax),%ecx
f01032ac:	0f b6 1a             	movzbl (%edx),%ebx
f01032af:	38 d9                	cmp    %bl,%cl
f01032b1:	74 0a                	je     f01032bd <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01032b3:	0f b6 c1             	movzbl %cl,%eax
f01032b6:	0f b6 db             	movzbl %bl,%ebx
f01032b9:	29 d8                	sub    %ebx,%eax
f01032bb:	eb 0f                	jmp    f01032cc <memcmp+0x35>
		s1++, s2++;
f01032bd:	83 c0 01             	add    $0x1,%eax
f01032c0:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01032c3:	39 f0                	cmp    %esi,%eax
f01032c5:	75 e2                	jne    f01032a9 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01032c7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032cc:	5b                   	pop    %ebx
f01032cd:	5e                   	pop    %esi
f01032ce:	5d                   	pop    %ebp
f01032cf:	c3                   	ret    

f01032d0 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01032d0:	55                   	push   %ebp
f01032d1:	89 e5                	mov    %esp,%ebp
f01032d3:	53                   	push   %ebx
f01032d4:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01032d7:	89 c1                	mov    %eax,%ecx
f01032d9:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01032dc:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032e0:	eb 0a                	jmp    f01032ec <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01032e2:	0f b6 10             	movzbl (%eax),%edx
f01032e5:	39 da                	cmp    %ebx,%edx
f01032e7:	74 07                	je     f01032f0 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032e9:	83 c0 01             	add    $0x1,%eax
f01032ec:	39 c8                	cmp    %ecx,%eax
f01032ee:	72 f2                	jb     f01032e2 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01032f0:	5b                   	pop    %ebx
f01032f1:	5d                   	pop    %ebp
f01032f2:	c3                   	ret    

f01032f3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01032f3:	55                   	push   %ebp
f01032f4:	89 e5                	mov    %esp,%ebp
f01032f6:	57                   	push   %edi
f01032f7:	56                   	push   %esi
f01032f8:	53                   	push   %ebx
f01032f9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01032fc:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032ff:	eb 03                	jmp    f0103304 <strtol+0x11>
		s++;
f0103301:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103304:	0f b6 01             	movzbl (%ecx),%eax
f0103307:	3c 20                	cmp    $0x20,%al
f0103309:	74 f6                	je     f0103301 <strtol+0xe>
f010330b:	3c 09                	cmp    $0x9,%al
f010330d:	74 f2                	je     f0103301 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010330f:	3c 2b                	cmp    $0x2b,%al
f0103311:	75 0a                	jne    f010331d <strtol+0x2a>
		s++;
f0103313:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103316:	bf 00 00 00 00       	mov    $0x0,%edi
f010331b:	eb 11                	jmp    f010332e <strtol+0x3b>
f010331d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103322:	3c 2d                	cmp    $0x2d,%al
f0103324:	75 08                	jne    f010332e <strtol+0x3b>
		s++, neg = 1;
f0103326:	83 c1 01             	add    $0x1,%ecx
f0103329:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010332e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103334:	75 15                	jne    f010334b <strtol+0x58>
f0103336:	80 39 30             	cmpb   $0x30,(%ecx)
f0103339:	75 10                	jne    f010334b <strtol+0x58>
f010333b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010333f:	75 7c                	jne    f01033bd <strtol+0xca>
		s += 2, base = 16;
f0103341:	83 c1 02             	add    $0x2,%ecx
f0103344:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103349:	eb 16                	jmp    f0103361 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010334b:	85 db                	test   %ebx,%ebx
f010334d:	75 12                	jne    f0103361 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010334f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103354:	80 39 30             	cmpb   $0x30,(%ecx)
f0103357:	75 08                	jne    f0103361 <strtol+0x6e>
		s++, base = 8;
f0103359:	83 c1 01             	add    $0x1,%ecx
f010335c:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103361:	b8 00 00 00 00       	mov    $0x0,%eax
f0103366:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103369:	0f b6 11             	movzbl (%ecx),%edx
f010336c:	8d 72 d0             	lea    -0x30(%edx),%esi
f010336f:	89 f3                	mov    %esi,%ebx
f0103371:	80 fb 09             	cmp    $0x9,%bl
f0103374:	77 08                	ja     f010337e <strtol+0x8b>
			dig = *s - '0';
f0103376:	0f be d2             	movsbl %dl,%edx
f0103379:	83 ea 30             	sub    $0x30,%edx
f010337c:	eb 22                	jmp    f01033a0 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010337e:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103381:	89 f3                	mov    %esi,%ebx
f0103383:	80 fb 19             	cmp    $0x19,%bl
f0103386:	77 08                	ja     f0103390 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103388:	0f be d2             	movsbl %dl,%edx
f010338b:	83 ea 57             	sub    $0x57,%edx
f010338e:	eb 10                	jmp    f01033a0 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103390:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103393:	89 f3                	mov    %esi,%ebx
f0103395:	80 fb 19             	cmp    $0x19,%bl
f0103398:	77 16                	ja     f01033b0 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010339a:	0f be d2             	movsbl %dl,%edx
f010339d:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01033a0:	3b 55 10             	cmp    0x10(%ebp),%edx
f01033a3:	7d 0b                	jge    f01033b0 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01033a5:	83 c1 01             	add    $0x1,%ecx
f01033a8:	0f af 45 10          	imul   0x10(%ebp),%eax
f01033ac:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01033ae:	eb b9                	jmp    f0103369 <strtol+0x76>

	if (endptr)
f01033b0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01033b4:	74 0d                	je     f01033c3 <strtol+0xd0>
		*endptr = (char *) s;
f01033b6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033b9:	89 0e                	mov    %ecx,(%esi)
f01033bb:	eb 06                	jmp    f01033c3 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033bd:	85 db                	test   %ebx,%ebx
f01033bf:	74 98                	je     f0103359 <strtol+0x66>
f01033c1:	eb 9e                	jmp    f0103361 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01033c3:	89 c2                	mov    %eax,%edx
f01033c5:	f7 da                	neg    %edx
f01033c7:	85 ff                	test   %edi,%edi
f01033c9:	0f 45 c2             	cmovne %edx,%eax
}
f01033cc:	5b                   	pop    %ebx
f01033cd:	5e                   	pop    %esi
f01033ce:	5f                   	pop    %edi
f01033cf:	5d                   	pop    %ebp
f01033d0:	c3                   	ret    
f01033d1:	66 90                	xchg   %ax,%ax
f01033d3:	66 90                	xchg   %ax,%ax
f01033d5:	66 90                	xchg   %ax,%ax
f01033d7:	66 90                	xchg   %ax,%ax
f01033d9:	66 90                	xchg   %ax,%ax
f01033db:	66 90                	xchg   %ax,%ax
f01033dd:	66 90                	xchg   %ax,%ax
f01033df:	90                   	nop

f01033e0 <__udivdi3>:
f01033e0:	55                   	push   %ebp
f01033e1:	57                   	push   %edi
f01033e2:	56                   	push   %esi
f01033e3:	53                   	push   %ebx
f01033e4:	83 ec 1c             	sub    $0x1c,%esp
f01033e7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01033eb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01033ef:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01033f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01033f7:	85 f6                	test   %esi,%esi
f01033f9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01033fd:	89 ca                	mov    %ecx,%edx
f01033ff:	89 f8                	mov    %edi,%eax
f0103401:	75 3d                	jne    f0103440 <__udivdi3+0x60>
f0103403:	39 cf                	cmp    %ecx,%edi
f0103405:	0f 87 c5 00 00 00    	ja     f01034d0 <__udivdi3+0xf0>
f010340b:	85 ff                	test   %edi,%edi
f010340d:	89 fd                	mov    %edi,%ebp
f010340f:	75 0b                	jne    f010341c <__udivdi3+0x3c>
f0103411:	b8 01 00 00 00       	mov    $0x1,%eax
f0103416:	31 d2                	xor    %edx,%edx
f0103418:	f7 f7                	div    %edi
f010341a:	89 c5                	mov    %eax,%ebp
f010341c:	89 c8                	mov    %ecx,%eax
f010341e:	31 d2                	xor    %edx,%edx
f0103420:	f7 f5                	div    %ebp
f0103422:	89 c1                	mov    %eax,%ecx
f0103424:	89 d8                	mov    %ebx,%eax
f0103426:	89 cf                	mov    %ecx,%edi
f0103428:	f7 f5                	div    %ebp
f010342a:	89 c3                	mov    %eax,%ebx
f010342c:	89 d8                	mov    %ebx,%eax
f010342e:	89 fa                	mov    %edi,%edx
f0103430:	83 c4 1c             	add    $0x1c,%esp
f0103433:	5b                   	pop    %ebx
f0103434:	5e                   	pop    %esi
f0103435:	5f                   	pop    %edi
f0103436:	5d                   	pop    %ebp
f0103437:	c3                   	ret    
f0103438:	90                   	nop
f0103439:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103440:	39 ce                	cmp    %ecx,%esi
f0103442:	77 74                	ja     f01034b8 <__udivdi3+0xd8>
f0103444:	0f bd fe             	bsr    %esi,%edi
f0103447:	83 f7 1f             	xor    $0x1f,%edi
f010344a:	0f 84 98 00 00 00    	je     f01034e8 <__udivdi3+0x108>
f0103450:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103455:	89 f9                	mov    %edi,%ecx
f0103457:	89 c5                	mov    %eax,%ebp
f0103459:	29 fb                	sub    %edi,%ebx
f010345b:	d3 e6                	shl    %cl,%esi
f010345d:	89 d9                	mov    %ebx,%ecx
f010345f:	d3 ed                	shr    %cl,%ebp
f0103461:	89 f9                	mov    %edi,%ecx
f0103463:	d3 e0                	shl    %cl,%eax
f0103465:	09 ee                	or     %ebp,%esi
f0103467:	89 d9                	mov    %ebx,%ecx
f0103469:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010346d:	89 d5                	mov    %edx,%ebp
f010346f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103473:	d3 ed                	shr    %cl,%ebp
f0103475:	89 f9                	mov    %edi,%ecx
f0103477:	d3 e2                	shl    %cl,%edx
f0103479:	89 d9                	mov    %ebx,%ecx
f010347b:	d3 e8                	shr    %cl,%eax
f010347d:	09 c2                	or     %eax,%edx
f010347f:	89 d0                	mov    %edx,%eax
f0103481:	89 ea                	mov    %ebp,%edx
f0103483:	f7 f6                	div    %esi
f0103485:	89 d5                	mov    %edx,%ebp
f0103487:	89 c3                	mov    %eax,%ebx
f0103489:	f7 64 24 0c          	mull   0xc(%esp)
f010348d:	39 d5                	cmp    %edx,%ebp
f010348f:	72 10                	jb     f01034a1 <__udivdi3+0xc1>
f0103491:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103495:	89 f9                	mov    %edi,%ecx
f0103497:	d3 e6                	shl    %cl,%esi
f0103499:	39 c6                	cmp    %eax,%esi
f010349b:	73 07                	jae    f01034a4 <__udivdi3+0xc4>
f010349d:	39 d5                	cmp    %edx,%ebp
f010349f:	75 03                	jne    f01034a4 <__udivdi3+0xc4>
f01034a1:	83 eb 01             	sub    $0x1,%ebx
f01034a4:	31 ff                	xor    %edi,%edi
f01034a6:	89 d8                	mov    %ebx,%eax
f01034a8:	89 fa                	mov    %edi,%edx
f01034aa:	83 c4 1c             	add    $0x1c,%esp
f01034ad:	5b                   	pop    %ebx
f01034ae:	5e                   	pop    %esi
f01034af:	5f                   	pop    %edi
f01034b0:	5d                   	pop    %ebp
f01034b1:	c3                   	ret    
f01034b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01034b8:	31 ff                	xor    %edi,%edi
f01034ba:	31 db                	xor    %ebx,%ebx
f01034bc:	89 d8                	mov    %ebx,%eax
f01034be:	89 fa                	mov    %edi,%edx
f01034c0:	83 c4 1c             	add    $0x1c,%esp
f01034c3:	5b                   	pop    %ebx
f01034c4:	5e                   	pop    %esi
f01034c5:	5f                   	pop    %edi
f01034c6:	5d                   	pop    %ebp
f01034c7:	c3                   	ret    
f01034c8:	90                   	nop
f01034c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034d0:	89 d8                	mov    %ebx,%eax
f01034d2:	f7 f7                	div    %edi
f01034d4:	31 ff                	xor    %edi,%edi
f01034d6:	89 c3                	mov    %eax,%ebx
f01034d8:	89 d8                	mov    %ebx,%eax
f01034da:	89 fa                	mov    %edi,%edx
f01034dc:	83 c4 1c             	add    $0x1c,%esp
f01034df:	5b                   	pop    %ebx
f01034e0:	5e                   	pop    %esi
f01034e1:	5f                   	pop    %edi
f01034e2:	5d                   	pop    %ebp
f01034e3:	c3                   	ret    
f01034e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01034e8:	39 ce                	cmp    %ecx,%esi
f01034ea:	72 0c                	jb     f01034f8 <__udivdi3+0x118>
f01034ec:	31 db                	xor    %ebx,%ebx
f01034ee:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01034f2:	0f 87 34 ff ff ff    	ja     f010342c <__udivdi3+0x4c>
f01034f8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01034fd:	e9 2a ff ff ff       	jmp    f010342c <__udivdi3+0x4c>
f0103502:	66 90                	xchg   %ax,%ax
f0103504:	66 90                	xchg   %ax,%ax
f0103506:	66 90                	xchg   %ax,%ax
f0103508:	66 90                	xchg   %ax,%ax
f010350a:	66 90                	xchg   %ax,%ax
f010350c:	66 90                	xchg   %ax,%ax
f010350e:	66 90                	xchg   %ax,%ax

f0103510 <__umoddi3>:
f0103510:	55                   	push   %ebp
f0103511:	57                   	push   %edi
f0103512:	56                   	push   %esi
f0103513:	53                   	push   %ebx
f0103514:	83 ec 1c             	sub    $0x1c,%esp
f0103517:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010351b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010351f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103523:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103527:	85 d2                	test   %edx,%edx
f0103529:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010352d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103531:	89 f3                	mov    %esi,%ebx
f0103533:	89 3c 24             	mov    %edi,(%esp)
f0103536:	89 74 24 04          	mov    %esi,0x4(%esp)
f010353a:	75 1c                	jne    f0103558 <__umoddi3+0x48>
f010353c:	39 f7                	cmp    %esi,%edi
f010353e:	76 50                	jbe    f0103590 <__umoddi3+0x80>
f0103540:	89 c8                	mov    %ecx,%eax
f0103542:	89 f2                	mov    %esi,%edx
f0103544:	f7 f7                	div    %edi
f0103546:	89 d0                	mov    %edx,%eax
f0103548:	31 d2                	xor    %edx,%edx
f010354a:	83 c4 1c             	add    $0x1c,%esp
f010354d:	5b                   	pop    %ebx
f010354e:	5e                   	pop    %esi
f010354f:	5f                   	pop    %edi
f0103550:	5d                   	pop    %ebp
f0103551:	c3                   	ret    
f0103552:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103558:	39 f2                	cmp    %esi,%edx
f010355a:	89 d0                	mov    %edx,%eax
f010355c:	77 52                	ja     f01035b0 <__umoddi3+0xa0>
f010355e:	0f bd ea             	bsr    %edx,%ebp
f0103561:	83 f5 1f             	xor    $0x1f,%ebp
f0103564:	75 5a                	jne    f01035c0 <__umoddi3+0xb0>
f0103566:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010356a:	0f 82 e0 00 00 00    	jb     f0103650 <__umoddi3+0x140>
f0103570:	39 0c 24             	cmp    %ecx,(%esp)
f0103573:	0f 86 d7 00 00 00    	jbe    f0103650 <__umoddi3+0x140>
f0103579:	8b 44 24 08          	mov    0x8(%esp),%eax
f010357d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103581:	83 c4 1c             	add    $0x1c,%esp
f0103584:	5b                   	pop    %ebx
f0103585:	5e                   	pop    %esi
f0103586:	5f                   	pop    %edi
f0103587:	5d                   	pop    %ebp
f0103588:	c3                   	ret    
f0103589:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103590:	85 ff                	test   %edi,%edi
f0103592:	89 fd                	mov    %edi,%ebp
f0103594:	75 0b                	jne    f01035a1 <__umoddi3+0x91>
f0103596:	b8 01 00 00 00       	mov    $0x1,%eax
f010359b:	31 d2                	xor    %edx,%edx
f010359d:	f7 f7                	div    %edi
f010359f:	89 c5                	mov    %eax,%ebp
f01035a1:	89 f0                	mov    %esi,%eax
f01035a3:	31 d2                	xor    %edx,%edx
f01035a5:	f7 f5                	div    %ebp
f01035a7:	89 c8                	mov    %ecx,%eax
f01035a9:	f7 f5                	div    %ebp
f01035ab:	89 d0                	mov    %edx,%eax
f01035ad:	eb 99                	jmp    f0103548 <__umoddi3+0x38>
f01035af:	90                   	nop
f01035b0:	89 c8                	mov    %ecx,%eax
f01035b2:	89 f2                	mov    %esi,%edx
f01035b4:	83 c4 1c             	add    $0x1c,%esp
f01035b7:	5b                   	pop    %ebx
f01035b8:	5e                   	pop    %esi
f01035b9:	5f                   	pop    %edi
f01035ba:	5d                   	pop    %ebp
f01035bb:	c3                   	ret    
f01035bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01035c0:	8b 34 24             	mov    (%esp),%esi
f01035c3:	bf 20 00 00 00       	mov    $0x20,%edi
f01035c8:	89 e9                	mov    %ebp,%ecx
f01035ca:	29 ef                	sub    %ebp,%edi
f01035cc:	d3 e0                	shl    %cl,%eax
f01035ce:	89 f9                	mov    %edi,%ecx
f01035d0:	89 f2                	mov    %esi,%edx
f01035d2:	d3 ea                	shr    %cl,%edx
f01035d4:	89 e9                	mov    %ebp,%ecx
f01035d6:	09 c2                	or     %eax,%edx
f01035d8:	89 d8                	mov    %ebx,%eax
f01035da:	89 14 24             	mov    %edx,(%esp)
f01035dd:	89 f2                	mov    %esi,%edx
f01035df:	d3 e2                	shl    %cl,%edx
f01035e1:	89 f9                	mov    %edi,%ecx
f01035e3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01035e7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01035eb:	d3 e8                	shr    %cl,%eax
f01035ed:	89 e9                	mov    %ebp,%ecx
f01035ef:	89 c6                	mov    %eax,%esi
f01035f1:	d3 e3                	shl    %cl,%ebx
f01035f3:	89 f9                	mov    %edi,%ecx
f01035f5:	89 d0                	mov    %edx,%eax
f01035f7:	d3 e8                	shr    %cl,%eax
f01035f9:	89 e9                	mov    %ebp,%ecx
f01035fb:	09 d8                	or     %ebx,%eax
f01035fd:	89 d3                	mov    %edx,%ebx
f01035ff:	89 f2                	mov    %esi,%edx
f0103601:	f7 34 24             	divl   (%esp)
f0103604:	89 d6                	mov    %edx,%esi
f0103606:	d3 e3                	shl    %cl,%ebx
f0103608:	f7 64 24 04          	mull   0x4(%esp)
f010360c:	39 d6                	cmp    %edx,%esi
f010360e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103612:	89 d1                	mov    %edx,%ecx
f0103614:	89 c3                	mov    %eax,%ebx
f0103616:	72 08                	jb     f0103620 <__umoddi3+0x110>
f0103618:	75 11                	jne    f010362b <__umoddi3+0x11b>
f010361a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010361e:	73 0b                	jae    f010362b <__umoddi3+0x11b>
f0103620:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103624:	1b 14 24             	sbb    (%esp),%edx
f0103627:	89 d1                	mov    %edx,%ecx
f0103629:	89 c3                	mov    %eax,%ebx
f010362b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010362f:	29 da                	sub    %ebx,%edx
f0103631:	19 ce                	sbb    %ecx,%esi
f0103633:	89 f9                	mov    %edi,%ecx
f0103635:	89 f0                	mov    %esi,%eax
f0103637:	d3 e0                	shl    %cl,%eax
f0103639:	89 e9                	mov    %ebp,%ecx
f010363b:	d3 ea                	shr    %cl,%edx
f010363d:	89 e9                	mov    %ebp,%ecx
f010363f:	d3 ee                	shr    %cl,%esi
f0103641:	09 d0                	or     %edx,%eax
f0103643:	89 f2                	mov    %esi,%edx
f0103645:	83 c4 1c             	add    $0x1c,%esp
f0103648:	5b                   	pop    %ebx
f0103649:	5e                   	pop    %esi
f010364a:	5f                   	pop    %edi
f010364b:	5d                   	pop    %ebp
f010364c:	c3                   	ret    
f010364d:	8d 76 00             	lea    0x0(%esi),%esi
f0103650:	29 f9                	sub    %edi,%ecx
f0103652:	19 d6                	sbb    %edx,%esi
f0103654:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103658:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010365c:	e9 18 ff ff ff       	jmp    f0103579 <__umoddi3+0x69>

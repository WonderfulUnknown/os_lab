
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
f0100058:	e8 9d 30 00 00       	call   f01030fa <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 bb 04 00 00       	call   f010051d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 a0 35 10 f0       	push   $0xf01035a0
f010006f:	e8 d2 25 00 00       	call   f0102646 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 4e 0f 00 00       	call   f0100fc7 <mem_init>
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
f01000b0:	68 bb 35 10 f0       	push   $0xf01035bb
f01000b5:	e8 8c 25 00 00       	call   f0102646 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 5c 25 00 00       	call   f0102620 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 a9 38 10 f0 	movl   $0xf01038a9,(%esp)
f01000cb:	e8 76 25 00 00       	call   f0102646 <cprintf>
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
f01000f2:	68 d3 35 10 f0       	push   $0xf01035d3
f01000f7:	e8 4a 25 00 00       	call   f0102646 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 18 25 00 00       	call   f0102620 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 a9 38 10 f0 	movl   $0xf01038a9,(%esp)
f010010f:	e8 32 25 00 00       	call   f0102646 <cprintf>
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
f01001c6:	0f b6 82 40 37 10 f0 	movzbl -0xfefc8c0(%edx),%eax
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
f0100202:	0f b6 82 40 37 10 f0 	movzbl -0xfefc8c0(%edx),%eax
f0100209:	0b 05 00 63 11 f0    	or     0xf0116300,%eax
f010020f:	0f b6 8a 40 36 10 f0 	movzbl -0xfefc9c0(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 63 11 f0       	mov    %eax,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d 20 36 10 f0 	mov    -0xfefc9e0(,%ecx,4),%ecx
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
f0100260:	68 ed 35 10 f0       	push   $0xf01035ed
f0100265:	e8 dc 23 00 00       	call   f0102646 <cprintf>
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
f0100441:	e8 01 2d 00 00       	call   f0103147 <memmove>
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
f0100610:	68 f9 35 10 f0       	push   $0xf01035f9
f0100615:	e8 2c 20 00 00       	call   f0102646 <cprintf>
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
f0100656:	68 40 38 10 f0       	push   $0xf0103840
f010065b:	68 5e 38 10 f0       	push   $0xf010385e
f0100660:	68 63 38 10 f0       	push   $0xf0103863
f0100665:	e8 dc 1f 00 00       	call   f0102646 <cprintf>
f010066a:	83 c4 0c             	add    $0xc,%esp
f010066d:	68 f8 38 10 f0       	push   $0xf01038f8
f0100672:	68 6c 38 10 f0       	push   $0xf010386c
f0100677:	68 63 38 10 f0       	push   $0xf0103863
f010067c:	e8 c5 1f 00 00       	call   f0102646 <cprintf>
f0100681:	83 c4 0c             	add    $0xc,%esp
f0100684:	68 20 39 10 f0       	push   $0xf0103920
f0100689:	68 75 38 10 f0       	push   $0xf0103875
f010068e:	68 63 38 10 f0       	push   $0xf0103863
f0100693:	e8 ae 1f 00 00       	call   f0102646 <cprintf>
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
f01006a5:	68 7f 38 10 f0       	push   $0xf010387f
f01006aa:	e8 97 1f 00 00       	call   f0102646 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006af:	83 c4 08             	add    $0x8,%esp
f01006b2:	68 0c 00 10 00       	push   $0x10000c
f01006b7:	68 48 39 10 f0       	push   $0xf0103948
f01006bc:	e8 85 1f 00 00       	call   f0102646 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006c1:	83 c4 0c             	add    $0xc,%esp
f01006c4:	68 0c 00 10 00       	push   $0x10000c
f01006c9:	68 0c 00 10 f0       	push   $0xf010000c
f01006ce:	68 70 39 10 f0       	push   $0xf0103970
f01006d3:	e8 6e 1f 00 00       	call   f0102646 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d8:	83 c4 0c             	add    $0xc,%esp
f01006db:	68 81 35 10 00       	push   $0x103581
f01006e0:	68 81 35 10 f0       	push   $0xf0103581
f01006e5:	68 94 39 10 f0       	push   $0xf0103994
f01006ea:	e8 57 1f 00 00       	call   f0102646 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ef:	83 c4 0c             	add    $0xc,%esp
f01006f2:	68 00 63 11 00       	push   $0x116300
f01006f7:	68 00 63 11 f0       	push   $0xf0116300
f01006fc:	68 b8 39 10 f0       	push   $0xf01039b8
f0100701:	e8 40 1f 00 00       	call   f0102646 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100706:	83 c4 0c             	add    $0xc,%esp
f0100709:	68 70 69 11 00       	push   $0x116970
f010070e:	68 70 69 11 f0       	push   $0xf0116970
f0100713:	68 dc 39 10 f0       	push   $0xf01039dc
f0100718:	e8 29 1f 00 00       	call   f0102646 <cprintf>
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
f010073e:	68 00 3a 10 f0       	push   $0xf0103a00
f0100743:	e8 fe 1e 00 00       	call   f0102646 <cprintf>
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
f010075a:	68 98 38 10 f0       	push   $0xf0103898
f010075f:	e8 e2 1e 00 00       	call   f0102646 <cprintf>
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
f0100780:	68 2c 3a 10 f0       	push   $0xf0103a2c
f0100785:	e8 bc 1e 00 00       	call   f0102646 <cprintf>
	debuginfo_eip((uintptr_t)eip,&info);
f010078a:	83 c4 18             	add    $0x18,%esp
f010078d:	57                   	push   %edi
f010078e:	56                   	push   %esi
f010078f:	e8 bc 1f 00 00       	call   f0102750 <debuginfo_eip>
	cprintf("%s:%d", info.eip_file, info.eip_line);
f0100794:	83 c4 0c             	add    $0xc,%esp
f0100797:	ff 75 d4             	pushl  -0x2c(%ebp)
f010079a:	ff 75 d0             	pushl  -0x30(%ebp)
f010079d:	68 ab 38 10 f0       	push   $0xf01038ab
f01007a2:	e8 9f 1e 00 00       	call   f0102646 <cprintf>
        cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name,info.eip_fn_addr);
f01007a7:	ff 75 e0             	pushl  -0x20(%ebp)
f01007aa:	ff 75 d8             	pushl  -0x28(%ebp)
f01007ad:	ff 75 dc             	pushl  -0x24(%ebp)
f01007b0:	68 b1 38 10 f0       	push   $0xf01038b1
f01007b5:	e8 8c 1e 00 00       	call   f0102646 <cprintf>
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
f01007d9:	68 64 3a 10 f0       	push   $0xf0103a64
f01007de:	e8 63 1e 00 00       	call   f0102646 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007e3:	c7 04 24 88 3a 10 f0 	movl   $0xf0103a88,(%esp)
f01007ea:	e8 57 1e 00 00       	call   f0102646 <cprintf>
f01007ef:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007f2:	83 ec 0c             	sub    $0xc,%esp
f01007f5:	68 bc 38 10 f0       	push   $0xf01038bc
f01007fa:	e8 a4 26 00 00       	call   f0102ea3 <readline>
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
f010082e:	68 c0 38 10 f0       	push   $0xf01038c0
f0100833:	e8 85 28 00 00       	call   f01030bd <strchr>
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
f010084e:	68 c5 38 10 f0       	push   $0xf01038c5
f0100853:	e8 ee 1d 00 00       	call   f0102646 <cprintf>
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
f0100877:	68 c0 38 10 f0       	push   $0xf01038c0
f010087c:	e8 3c 28 00 00       	call   f01030bd <strchr>
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
f01008a5:	ff 34 85 c0 3a 10 f0 	pushl  -0xfefc540(,%eax,4)
f01008ac:	ff 75 a8             	pushl  -0x58(%ebp)
f01008af:	e8 ab 27 00 00       	call   f010305f <strcmp>
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
f01008c9:	ff 14 85 c8 3a 10 f0 	call   *-0xfefc538(,%eax,4)


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
f01008ea:	68 e2 38 10 f0       	push   $0xf01038e2
f01008ef:	e8 52 1d 00 00       	call   f0102646 <cprintf>
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
f0100963:	68 e4 3a 10 f0       	push   $0xf0103ae4
f0100968:	68 07 03 00 00       	push   $0x307
f010096d:	68 38 42 10 f0       	push   $0xf0104238
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
f01009bb:	68 08 3b 10 f0       	push   $0xf0103b08
f01009c0:	68 4a 02 00 00       	push   $0x24a
f01009c5:	68 38 42 10 f0       	push   $0xf0104238
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
f0100a4a:	68 e4 3a 10 f0       	push   $0xf0103ae4
f0100a4f:	6a 52                	push   $0x52
f0100a51:	68 44 42 10 f0       	push   $0xf0104244
f0100a56:	e8 30 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a5b:	83 ec 04             	sub    $0x4,%esp
f0100a5e:	68 80 00 00 00       	push   $0x80
f0100a63:	68 97 00 00 00       	push   $0x97
f0100a68:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a6d:	50                   	push   %eax
f0100a6e:	e8 87 26 00 00       	call   f01030fa <memset>
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
f0100ab4:	68 52 42 10 f0       	push   $0xf0104252
f0100ab9:	68 5e 42 10 f0       	push   $0xf010425e
f0100abe:	68 64 02 00 00       	push   $0x264
f0100ac3:	68 38 42 10 f0       	push   $0xf0104238
f0100ac8:	e8 be f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100acd:	39 fa                	cmp    %edi,%edx
f0100acf:	72 19                	jb     f0100aea <check_page_free_list+0x148>
f0100ad1:	68 73 42 10 f0       	push   $0xf0104273
f0100ad6:	68 5e 42 10 f0       	push   $0xf010425e
f0100adb:	68 65 02 00 00       	push   $0x265
f0100ae0:	68 38 42 10 f0       	push   $0xf0104238
f0100ae5:	e8 a1 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aea:	89 d0                	mov    %edx,%eax
f0100aec:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100aef:	a8 07                	test   $0x7,%al
f0100af1:	74 19                	je     f0100b0c <check_page_free_list+0x16a>
f0100af3:	68 2c 3b 10 f0       	push   $0xf0103b2c
f0100af8:	68 5e 42 10 f0       	push   $0xf010425e
f0100afd:	68 66 02 00 00       	push   $0x266
f0100b02:	68 38 42 10 f0       	push   $0xf0104238
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
f0100b16:	68 87 42 10 f0       	push   $0xf0104287
f0100b1b:	68 5e 42 10 f0       	push   $0xf010425e
f0100b20:	68 69 02 00 00       	push   $0x269
f0100b25:	68 38 42 10 f0       	push   $0xf0104238
f0100b2a:	e8 5c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b2f:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b34:	75 19                	jne    f0100b4f <check_page_free_list+0x1ad>
f0100b36:	68 98 42 10 f0       	push   $0xf0104298
f0100b3b:	68 5e 42 10 f0       	push   $0xf010425e
f0100b40:	68 6a 02 00 00       	push   $0x26a
f0100b45:	68 38 42 10 f0       	push   $0xf0104238
f0100b4a:	e8 3c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b4f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b54:	75 19                	jne    f0100b6f <check_page_free_list+0x1cd>
f0100b56:	68 60 3b 10 f0       	push   $0xf0103b60
f0100b5b:	68 5e 42 10 f0       	push   $0xf010425e
f0100b60:	68 6b 02 00 00       	push   $0x26b
f0100b65:	68 38 42 10 f0       	push   $0xf0104238
f0100b6a:	e8 1c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b6f:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b74:	75 19                	jne    f0100b8f <check_page_free_list+0x1ed>
f0100b76:	68 b1 42 10 f0       	push   $0xf01042b1
f0100b7b:	68 5e 42 10 f0       	push   $0xf010425e
f0100b80:	68 6c 02 00 00       	push   $0x26c
f0100b85:	68 38 42 10 f0       	push   $0xf0104238
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
f0100ba1:	68 e4 3a 10 f0       	push   $0xf0103ae4
f0100ba6:	6a 52                	push   $0x52
f0100ba8:	68 44 42 10 f0       	push   $0xf0104244
f0100bad:	e8 d9 f4 ff ff       	call   f010008b <_panic>
f0100bb2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bb7:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bba:	76 1e                	jbe    f0100bda <check_page_free_list+0x238>
f0100bbc:	68 84 3b 10 f0       	push   $0xf0103b84
f0100bc1:	68 5e 42 10 f0       	push   $0xf010425e
f0100bc6:	68 6d 02 00 00       	push   $0x26d
f0100bcb:	68 38 42 10 f0       	push   $0xf0104238
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
f0100bef:	68 cb 42 10 f0       	push   $0xf01042cb
f0100bf4:	68 5e 42 10 f0       	push   $0xf010425e
f0100bf9:	68 75 02 00 00       	push   $0x275
f0100bfe:	68 38 42 10 f0       	push   $0xf0104238
f0100c03:	e8 83 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c08:	85 db                	test   %ebx,%ebx
f0100c0a:	7f 42                	jg     f0100c4e <check_page_free_list+0x2ac>
f0100c0c:	68 dd 42 10 f0       	push   $0xf01042dd
f0100c11:	68 5e 42 10 f0       	push   $0xf010425e
f0100c16:	68 76 02 00 00       	push   $0x276
f0100c1b:	68 38 42 10 f0       	push   $0xf0104238
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
f0100d5d:	68 ee 42 10 f0       	push   $0xf01042ee
f0100d62:	e8 df 18 00 00       	call   f0102646 <cprintf>
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
f0100d8c:	68 e4 3a 10 f0       	push   $0xf0103ae4
f0100d91:	6a 52                	push   $0x52
f0100d93:	68 44 42 10 f0       	push   $0xf0104244
f0100d98:	e8 ee f2 ff ff       	call   f010008b <_panic>
			memset(page2kva(Page),'\0',PGSIZE);
f0100d9d:	83 ec 04             	sub    $0x4,%esp
f0100da0:	68 00 10 00 00       	push   $0x1000
f0100da5:	6a 00                	push   $0x0
f0100da7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dac:	50                   	push   %eax
f0100dad:	e8 48 23 00 00       	call   f01030fa <memset>
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
f0100dd2:	68 fb 42 10 f0       	push   $0xf01042fb
f0100dd7:	e8 6a 18 00 00       	call   f0102646 <cprintf>
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
f0100e41:	68 e4 3a 10 f0       	push   $0xf0103ae4
f0100e46:	68 86 01 00 00       	push   $0x186
f0100e4b:	68 38 42 10 f0       	push   $0xf0104238
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
f0100e95:	68 e4 3a 10 f0       	push   $0xf0103ae4
f0100e9a:	68 8e 01 00 00       	push   $0x18e
f0100e9f:	68 38 42 10 f0       	push   $0xf0104238
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
f0100f00:	68 cc 3b 10 f0       	push   $0xf0103bcc
f0100f05:	6a 4b                	push   $0x4b
f0100f07:	68 44 42 10 f0       	push   $0xf0104244
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
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
f0100f70:	6a 01                	push   $0x1
f0100f72:	57                   	push   %edi
f0100f73:	ff 75 08             	pushl  0x8(%ebp)
f0100f76:	e8 8d fe ff ff       	call   f0100e08 <pgdir_walk>
	if (!pte)
f0100f7b:	83 c4 10             	add    $0x10,%esp
f0100f7e:	85 c0                	test   %eax,%eax
f0100f80:	74 38                	je     f0100fba <page_insert+0x59>
f0100f82:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	//删除之前存在的映射关系 
    if((*pte) & PTE_P)
f0100f84:	f6 00 01             	testb  $0x1,(%eax)
f0100f87:	74 0f                	je     f0100f98 <page_insert+0x37>
        page_remove(pgdir, va);
f0100f89:	83 ec 08             	sub    $0x8,%esp
f0100f8c:	57                   	push   %edi
f0100f8d:	ff 75 08             	pushl  0x8(%ebp)
f0100f90:	e8 91 ff ff ff       	call   f0100f26 <page_remove>
f0100f95:	83 c4 10             	add    $0x10,%esp
	pp->pp_ref++;
f0100f98:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
    *pte = page2pa(pp) | perm | PTE_P;
f0100f9d:	2b 1d 6c 69 11 f0    	sub    0xf011696c,%ebx
f0100fa3:	c1 fb 03             	sar    $0x3,%ebx
f0100fa6:	c1 e3 0c             	shl    $0xc,%ebx
f0100fa9:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fac:	83 c8 01             	or     $0x1,%eax
f0100faf:	09 c3                	or     %eax,%ebx
f0100fb1:	89 1e                	mov    %ebx,(%esi)
	return 0;
f0100fb3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fb8:	eb 05                	jmp    f0100fbf <page_insert+0x5e>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
	if (!pte)
		return -E_NO_MEM;
f0100fba:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    if((*pte) & PTE_P)
        page_remove(pgdir, va);
	pp->pp_ref++;
    *pte = page2pa(pp) | perm | PTE_P;
	return 0;
}
f0100fbf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fc2:	5b                   	pop    %ebx
f0100fc3:	5e                   	pop    %esi
f0100fc4:	5f                   	pop    %edi
f0100fc5:	5d                   	pop    %ebp
f0100fc6:	c3                   	ret    

f0100fc7 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100fc7:	55                   	push   %ebp
f0100fc8:	89 e5                	mov    %esp,%ebp
f0100fca:	57                   	push   %edi
f0100fcb:	56                   	push   %esi
f0100fcc:	53                   	push   %ebx
f0100fcd:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100fd0:	6a 15                	push   $0x15
f0100fd2:	e8 08 16 00 00       	call   f01025df <mc146818_read>
f0100fd7:	89 c3                	mov    %eax,%ebx
f0100fd9:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0100fe0:	e8 fa 15 00 00       	call   f01025df <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100fe5:	c1 e0 08             	shl    $0x8,%eax
f0100fe8:	09 d8                	or     %ebx,%eax
f0100fea:	c1 e0 0a             	shl    $0xa,%eax
f0100fed:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100ff3:	85 c0                	test   %eax,%eax
f0100ff5:	0f 48 c2             	cmovs  %edx,%eax
f0100ff8:	c1 f8 0c             	sar    $0xc,%eax
f0100ffb:	a3 40 65 11 f0       	mov    %eax,0xf0116540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101000:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101007:	e8 d3 15 00 00       	call   f01025df <mc146818_read>
f010100c:	89 c3                	mov    %eax,%ebx
f010100e:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101015:	e8 c5 15 00 00       	call   f01025df <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010101a:	c1 e0 08             	shl    $0x8,%eax
f010101d:	09 d8                	or     %ebx,%eax
f010101f:	c1 e0 0a             	shl    $0xa,%eax
f0101022:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101028:	83 c4 10             	add    $0x10,%esp
f010102b:	85 c0                	test   %eax,%eax
f010102d:	0f 48 c2             	cmovs  %edx,%eax
f0101030:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101033:	85 c0                	test   %eax,%eax
f0101035:	74 0e                	je     f0101045 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101037:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010103d:	89 15 64 69 11 f0    	mov    %edx,0xf0116964
f0101043:	eb 0c                	jmp    f0101051 <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101045:	8b 15 40 65 11 f0    	mov    0xf0116540,%edx
f010104b:	89 15 64 69 11 f0    	mov    %edx,0xf0116964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101051:	c1 e0 0c             	shl    $0xc,%eax
f0101054:	c1 e8 0a             	shr    $0xa,%eax
f0101057:	50                   	push   %eax
f0101058:	a1 40 65 11 f0       	mov    0xf0116540,%eax
f010105d:	c1 e0 0c             	shl    $0xc,%eax
f0101060:	c1 e8 0a             	shr    $0xa,%eax
f0101063:	50                   	push   %eax
f0101064:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0101069:	c1 e0 0c             	shl    $0xc,%eax
f010106c:	c1 e8 0a             	shr    $0xa,%eax
f010106f:	50                   	push   %eax
f0101070:	68 ec 3b 10 f0       	push   $0xf0103bec
f0101075:	e8 cc 15 00 00       	call   f0102646 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010107a:	b8 00 10 00 00       	mov    $0x1000,%eax
f010107f:	e8 80 f8 ff ff       	call   f0100904 <boot_alloc>
f0101084:	a3 68 69 11 f0       	mov    %eax,0xf0116968
	memset(kern_pgdir, 0, PGSIZE);
f0101089:	83 c4 0c             	add    $0xc,%esp
f010108c:	68 00 10 00 00       	push   $0x1000
f0101091:	6a 00                	push   $0x0
f0101093:	50                   	push   %eax
f0101094:	e8 61 20 00 00       	call   f01030fa <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101099:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010109e:	83 c4 10             	add    $0x10,%esp
f01010a1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010a6:	77 15                	ja     f01010bd <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010a8:	50                   	push   %eax
f01010a9:	68 28 3c 10 f0       	push   $0xf0103c28
f01010ae:	68 8d 00 00 00       	push   $0x8d
f01010b3:	68 38 42 10 f0       	push   $0xf0104238
f01010b8:	e8 ce ef ff ff       	call   f010008b <_panic>
f01010bd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01010c3:	83 ca 05             	or     $0x5,%edx
f01010c6:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f01010cc:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f01010d1:	c1 e0 03             	shl    $0x3,%eax
f01010d4:	e8 2b f8 ff ff       	call   f0100904 <boot_alloc>
f01010d9:	a3 6c 69 11 f0       	mov    %eax,0xf011696c
	memset(pages,0,npages * sizeof(struct PageInfo));
f01010de:	83 ec 04             	sub    $0x4,%esp
f01010e1:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f01010e7:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01010ee:	52                   	push   %edx
f01010ef:	6a 00                	push   $0x0
f01010f1:	50                   	push   %eax
f01010f2:	e8 03 20 00 00       	call   f01030fa <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01010f7:	e8 5a fb ff ff       	call   f0100c56 <page_init>

	check_page_free_list(1);
f01010fc:	b8 01 00 00 00       	mov    $0x1,%eax
f0101101:	e8 9c f8 ff ff       	call   f01009a2 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101106:	83 c4 10             	add    $0x10,%esp
f0101109:	83 3d 6c 69 11 f0 00 	cmpl   $0x0,0xf011696c
f0101110:	75 17                	jne    f0101129 <mem_init+0x162>
		panic("'pages' is a null pointer!");
f0101112:	83 ec 04             	sub    $0x4,%esp
f0101115:	68 07 43 10 f0       	push   $0xf0104307
f010111a:	68 87 02 00 00       	push   $0x287
f010111f:	68 38 42 10 f0       	push   $0xf0104238
f0101124:	e8 62 ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101129:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010112e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101133:	eb 05                	jmp    f010113a <mem_init+0x173>
		++nfree;
f0101135:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101138:	8b 00                	mov    (%eax),%eax
f010113a:	85 c0                	test   %eax,%eax
f010113c:	75 f7                	jne    f0101135 <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010113e:	83 ec 0c             	sub    $0xc,%esp
f0101141:	6a 00                	push   $0x0
f0101143:	e8 ee fb ff ff       	call   f0100d36 <page_alloc>
f0101148:	89 c7                	mov    %eax,%edi
f010114a:	83 c4 10             	add    $0x10,%esp
f010114d:	85 c0                	test   %eax,%eax
f010114f:	75 19                	jne    f010116a <mem_init+0x1a3>
f0101151:	68 22 43 10 f0       	push   $0xf0104322
f0101156:	68 5e 42 10 f0       	push   $0xf010425e
f010115b:	68 8f 02 00 00       	push   $0x28f
f0101160:	68 38 42 10 f0       	push   $0xf0104238
f0101165:	e8 21 ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010116a:	83 ec 0c             	sub    $0xc,%esp
f010116d:	6a 00                	push   $0x0
f010116f:	e8 c2 fb ff ff       	call   f0100d36 <page_alloc>
f0101174:	89 c6                	mov    %eax,%esi
f0101176:	83 c4 10             	add    $0x10,%esp
f0101179:	85 c0                	test   %eax,%eax
f010117b:	75 19                	jne    f0101196 <mem_init+0x1cf>
f010117d:	68 38 43 10 f0       	push   $0xf0104338
f0101182:	68 5e 42 10 f0       	push   $0xf010425e
f0101187:	68 90 02 00 00       	push   $0x290
f010118c:	68 38 42 10 f0       	push   $0xf0104238
f0101191:	e8 f5 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101196:	83 ec 0c             	sub    $0xc,%esp
f0101199:	6a 00                	push   $0x0
f010119b:	e8 96 fb ff ff       	call   f0100d36 <page_alloc>
f01011a0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01011a3:	83 c4 10             	add    $0x10,%esp
f01011a6:	85 c0                	test   %eax,%eax
f01011a8:	75 19                	jne    f01011c3 <mem_init+0x1fc>
f01011aa:	68 4e 43 10 f0       	push   $0xf010434e
f01011af:	68 5e 42 10 f0       	push   $0xf010425e
f01011b4:	68 91 02 00 00       	push   $0x291
f01011b9:	68 38 42 10 f0       	push   $0xf0104238
f01011be:	e8 c8 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01011c3:	39 f7                	cmp    %esi,%edi
f01011c5:	75 19                	jne    f01011e0 <mem_init+0x219>
f01011c7:	68 64 43 10 f0       	push   $0xf0104364
f01011cc:	68 5e 42 10 f0       	push   $0xf010425e
f01011d1:	68 94 02 00 00       	push   $0x294
f01011d6:	68 38 42 10 f0       	push   $0xf0104238
f01011db:	e8 ab ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01011e0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011e3:	39 c6                	cmp    %eax,%esi
f01011e5:	74 04                	je     f01011eb <mem_init+0x224>
f01011e7:	39 c7                	cmp    %eax,%edi
f01011e9:	75 19                	jne    f0101204 <mem_init+0x23d>
f01011eb:	68 4c 3c 10 f0       	push   $0xf0103c4c
f01011f0:	68 5e 42 10 f0       	push   $0xf010425e
f01011f5:	68 95 02 00 00       	push   $0x295
f01011fa:	68 38 42 10 f0       	push   $0xf0104238
f01011ff:	e8 87 ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101204:	8b 0d 6c 69 11 f0    	mov    0xf011696c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010120a:	8b 15 64 69 11 f0    	mov    0xf0116964,%edx
f0101210:	c1 e2 0c             	shl    $0xc,%edx
f0101213:	89 f8                	mov    %edi,%eax
f0101215:	29 c8                	sub    %ecx,%eax
f0101217:	c1 f8 03             	sar    $0x3,%eax
f010121a:	c1 e0 0c             	shl    $0xc,%eax
f010121d:	39 d0                	cmp    %edx,%eax
f010121f:	72 19                	jb     f010123a <mem_init+0x273>
f0101221:	68 76 43 10 f0       	push   $0xf0104376
f0101226:	68 5e 42 10 f0       	push   $0xf010425e
f010122b:	68 96 02 00 00       	push   $0x296
f0101230:	68 38 42 10 f0       	push   $0xf0104238
f0101235:	e8 51 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010123a:	89 f0                	mov    %esi,%eax
f010123c:	29 c8                	sub    %ecx,%eax
f010123e:	c1 f8 03             	sar    $0x3,%eax
f0101241:	c1 e0 0c             	shl    $0xc,%eax
f0101244:	39 c2                	cmp    %eax,%edx
f0101246:	77 19                	ja     f0101261 <mem_init+0x29a>
f0101248:	68 93 43 10 f0       	push   $0xf0104393
f010124d:	68 5e 42 10 f0       	push   $0xf010425e
f0101252:	68 97 02 00 00       	push   $0x297
f0101257:	68 38 42 10 f0       	push   $0xf0104238
f010125c:	e8 2a ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101261:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101264:	29 c8                	sub    %ecx,%eax
f0101266:	c1 f8 03             	sar    $0x3,%eax
f0101269:	c1 e0 0c             	shl    $0xc,%eax
f010126c:	39 c2                	cmp    %eax,%edx
f010126e:	77 19                	ja     f0101289 <mem_init+0x2c2>
f0101270:	68 b0 43 10 f0       	push   $0xf01043b0
f0101275:	68 5e 42 10 f0       	push   $0xf010425e
f010127a:	68 98 02 00 00       	push   $0x298
f010127f:	68 38 42 10 f0       	push   $0xf0104238
f0101284:	e8 02 ee ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101289:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010128e:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101291:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0101298:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010129b:	83 ec 0c             	sub    $0xc,%esp
f010129e:	6a 00                	push   $0x0
f01012a0:	e8 91 fa ff ff       	call   f0100d36 <page_alloc>
f01012a5:	83 c4 10             	add    $0x10,%esp
f01012a8:	85 c0                	test   %eax,%eax
f01012aa:	74 19                	je     f01012c5 <mem_init+0x2fe>
f01012ac:	68 cd 43 10 f0       	push   $0xf01043cd
f01012b1:	68 5e 42 10 f0       	push   $0xf010425e
f01012b6:	68 9f 02 00 00       	push   $0x29f
f01012bb:	68 38 42 10 f0       	push   $0xf0104238
f01012c0:	e8 c6 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01012c5:	83 ec 0c             	sub    $0xc,%esp
f01012c8:	57                   	push   %edi
f01012c9:	e8 ee fa ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f01012ce:	89 34 24             	mov    %esi,(%esp)
f01012d1:	e8 e6 fa ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f01012d6:	83 c4 04             	add    $0x4,%esp
f01012d9:	ff 75 d4             	pushl  -0x2c(%ebp)
f01012dc:	e8 db fa ff ff       	call   f0100dbc <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012e1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012e8:	e8 49 fa ff ff       	call   f0100d36 <page_alloc>
f01012ed:	89 c6                	mov    %eax,%esi
f01012ef:	83 c4 10             	add    $0x10,%esp
f01012f2:	85 c0                	test   %eax,%eax
f01012f4:	75 19                	jne    f010130f <mem_init+0x348>
f01012f6:	68 22 43 10 f0       	push   $0xf0104322
f01012fb:	68 5e 42 10 f0       	push   $0xf010425e
f0101300:	68 a6 02 00 00       	push   $0x2a6
f0101305:	68 38 42 10 f0       	push   $0xf0104238
f010130a:	e8 7c ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010130f:	83 ec 0c             	sub    $0xc,%esp
f0101312:	6a 00                	push   $0x0
f0101314:	e8 1d fa ff ff       	call   f0100d36 <page_alloc>
f0101319:	89 c7                	mov    %eax,%edi
f010131b:	83 c4 10             	add    $0x10,%esp
f010131e:	85 c0                	test   %eax,%eax
f0101320:	75 19                	jne    f010133b <mem_init+0x374>
f0101322:	68 38 43 10 f0       	push   $0xf0104338
f0101327:	68 5e 42 10 f0       	push   $0xf010425e
f010132c:	68 a7 02 00 00       	push   $0x2a7
f0101331:	68 38 42 10 f0       	push   $0xf0104238
f0101336:	e8 50 ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010133b:	83 ec 0c             	sub    $0xc,%esp
f010133e:	6a 00                	push   $0x0
f0101340:	e8 f1 f9 ff ff       	call   f0100d36 <page_alloc>
f0101345:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101348:	83 c4 10             	add    $0x10,%esp
f010134b:	85 c0                	test   %eax,%eax
f010134d:	75 19                	jne    f0101368 <mem_init+0x3a1>
f010134f:	68 4e 43 10 f0       	push   $0xf010434e
f0101354:	68 5e 42 10 f0       	push   $0xf010425e
f0101359:	68 a8 02 00 00       	push   $0x2a8
f010135e:	68 38 42 10 f0       	push   $0xf0104238
f0101363:	e8 23 ed ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101368:	39 fe                	cmp    %edi,%esi
f010136a:	75 19                	jne    f0101385 <mem_init+0x3be>
f010136c:	68 64 43 10 f0       	push   $0xf0104364
f0101371:	68 5e 42 10 f0       	push   $0xf010425e
f0101376:	68 aa 02 00 00       	push   $0x2aa
f010137b:	68 38 42 10 f0       	push   $0xf0104238
f0101380:	e8 06 ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101385:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101388:	39 c7                	cmp    %eax,%edi
f010138a:	74 04                	je     f0101390 <mem_init+0x3c9>
f010138c:	39 c6                	cmp    %eax,%esi
f010138e:	75 19                	jne    f01013a9 <mem_init+0x3e2>
f0101390:	68 4c 3c 10 f0       	push   $0xf0103c4c
f0101395:	68 5e 42 10 f0       	push   $0xf010425e
f010139a:	68 ab 02 00 00       	push   $0x2ab
f010139f:	68 38 42 10 f0       	push   $0xf0104238
f01013a4:	e8 e2 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01013a9:	83 ec 0c             	sub    $0xc,%esp
f01013ac:	6a 00                	push   $0x0
f01013ae:	e8 83 f9 ff ff       	call   f0100d36 <page_alloc>
f01013b3:	83 c4 10             	add    $0x10,%esp
f01013b6:	85 c0                	test   %eax,%eax
f01013b8:	74 19                	je     f01013d3 <mem_init+0x40c>
f01013ba:	68 cd 43 10 f0       	push   $0xf01043cd
f01013bf:	68 5e 42 10 f0       	push   $0xf010425e
f01013c4:	68 ac 02 00 00       	push   $0x2ac
f01013c9:	68 38 42 10 f0       	push   $0xf0104238
f01013ce:	e8 b8 ec ff ff       	call   f010008b <_panic>
f01013d3:	89 f0                	mov    %esi,%eax
f01013d5:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01013db:	c1 f8 03             	sar    $0x3,%eax
f01013de:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013e1:	89 c2                	mov    %eax,%edx
f01013e3:	c1 ea 0c             	shr    $0xc,%edx
f01013e6:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01013ec:	72 12                	jb     f0101400 <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01013ee:	50                   	push   %eax
f01013ef:	68 e4 3a 10 f0       	push   $0xf0103ae4
f01013f4:	6a 52                	push   $0x52
f01013f6:	68 44 42 10 f0       	push   $0xf0104244
f01013fb:	e8 8b ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101400:	83 ec 04             	sub    $0x4,%esp
f0101403:	68 00 10 00 00       	push   $0x1000
f0101408:	6a 01                	push   $0x1
f010140a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010140f:	50                   	push   %eax
f0101410:	e8 e5 1c 00 00       	call   f01030fa <memset>
	page_free(pp0);
f0101415:	89 34 24             	mov    %esi,(%esp)
f0101418:	e8 9f f9 ff ff       	call   f0100dbc <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010141d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101424:	e8 0d f9 ff ff       	call   f0100d36 <page_alloc>
f0101429:	83 c4 10             	add    $0x10,%esp
f010142c:	85 c0                	test   %eax,%eax
f010142e:	75 19                	jne    f0101449 <mem_init+0x482>
f0101430:	68 dc 43 10 f0       	push   $0xf01043dc
f0101435:	68 5e 42 10 f0       	push   $0xf010425e
f010143a:	68 b1 02 00 00       	push   $0x2b1
f010143f:	68 38 42 10 f0       	push   $0xf0104238
f0101444:	e8 42 ec ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101449:	39 c6                	cmp    %eax,%esi
f010144b:	74 19                	je     f0101466 <mem_init+0x49f>
f010144d:	68 fa 43 10 f0       	push   $0xf01043fa
f0101452:	68 5e 42 10 f0       	push   $0xf010425e
f0101457:	68 b2 02 00 00       	push   $0x2b2
f010145c:	68 38 42 10 f0       	push   $0xf0104238
f0101461:	e8 25 ec ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101466:	89 f0                	mov    %esi,%eax
f0101468:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f010146e:	c1 f8 03             	sar    $0x3,%eax
f0101471:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101474:	89 c2                	mov    %eax,%edx
f0101476:	c1 ea 0c             	shr    $0xc,%edx
f0101479:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f010147f:	72 12                	jb     f0101493 <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101481:	50                   	push   %eax
f0101482:	68 e4 3a 10 f0       	push   $0xf0103ae4
f0101487:	6a 52                	push   $0x52
f0101489:	68 44 42 10 f0       	push   $0xf0104244
f010148e:	e8 f8 eb ff ff       	call   f010008b <_panic>
f0101493:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101499:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010149f:	80 38 00             	cmpb   $0x0,(%eax)
f01014a2:	74 19                	je     f01014bd <mem_init+0x4f6>
f01014a4:	68 0a 44 10 f0       	push   $0xf010440a
f01014a9:	68 5e 42 10 f0       	push   $0xf010425e
f01014ae:	68 b5 02 00 00       	push   $0x2b5
f01014b3:	68 38 42 10 f0       	push   $0xf0104238
f01014b8:	e8 ce eb ff ff       	call   f010008b <_panic>
f01014bd:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01014c0:	39 d0                	cmp    %edx,%eax
f01014c2:	75 db                	jne    f010149f <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01014c4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014c7:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f01014cc:	83 ec 0c             	sub    $0xc,%esp
f01014cf:	56                   	push   %esi
f01014d0:	e8 e7 f8 ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f01014d5:	89 3c 24             	mov    %edi,(%esp)
f01014d8:	e8 df f8 ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f01014dd:	83 c4 04             	add    $0x4,%esp
f01014e0:	ff 75 d4             	pushl  -0x2c(%ebp)
f01014e3:	e8 d4 f8 ff ff       	call   f0100dbc <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01014e8:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01014ed:	83 c4 10             	add    $0x10,%esp
f01014f0:	eb 05                	jmp    f01014f7 <mem_init+0x530>
		--nfree;
f01014f2:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01014f5:	8b 00                	mov    (%eax),%eax
f01014f7:	85 c0                	test   %eax,%eax
f01014f9:	75 f7                	jne    f01014f2 <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f01014fb:	85 db                	test   %ebx,%ebx
f01014fd:	74 19                	je     f0101518 <mem_init+0x551>
f01014ff:	68 14 44 10 f0       	push   $0xf0104414
f0101504:	68 5e 42 10 f0       	push   $0xf010425e
f0101509:	68 c2 02 00 00       	push   $0x2c2
f010150e:	68 38 42 10 f0       	push   $0xf0104238
f0101513:	e8 73 eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101518:	83 ec 0c             	sub    $0xc,%esp
f010151b:	68 6c 3c 10 f0       	push   $0xf0103c6c
f0101520:	e8 21 11 00 00       	call   f0102646 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101525:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010152c:	e8 05 f8 ff ff       	call   f0100d36 <page_alloc>
f0101531:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101534:	83 c4 10             	add    $0x10,%esp
f0101537:	85 c0                	test   %eax,%eax
f0101539:	75 19                	jne    f0101554 <mem_init+0x58d>
f010153b:	68 22 43 10 f0       	push   $0xf0104322
f0101540:	68 5e 42 10 f0       	push   $0xf010425e
f0101545:	68 1b 03 00 00       	push   $0x31b
f010154a:	68 38 42 10 f0       	push   $0xf0104238
f010154f:	e8 37 eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101554:	83 ec 0c             	sub    $0xc,%esp
f0101557:	6a 00                	push   $0x0
f0101559:	e8 d8 f7 ff ff       	call   f0100d36 <page_alloc>
f010155e:	89 c3                	mov    %eax,%ebx
f0101560:	83 c4 10             	add    $0x10,%esp
f0101563:	85 c0                	test   %eax,%eax
f0101565:	75 19                	jne    f0101580 <mem_init+0x5b9>
f0101567:	68 38 43 10 f0       	push   $0xf0104338
f010156c:	68 5e 42 10 f0       	push   $0xf010425e
f0101571:	68 1c 03 00 00       	push   $0x31c
f0101576:	68 38 42 10 f0       	push   $0xf0104238
f010157b:	e8 0b eb ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101580:	83 ec 0c             	sub    $0xc,%esp
f0101583:	6a 00                	push   $0x0
f0101585:	e8 ac f7 ff ff       	call   f0100d36 <page_alloc>
f010158a:	89 c6                	mov    %eax,%esi
f010158c:	83 c4 10             	add    $0x10,%esp
f010158f:	85 c0                	test   %eax,%eax
f0101591:	75 19                	jne    f01015ac <mem_init+0x5e5>
f0101593:	68 4e 43 10 f0       	push   $0xf010434e
f0101598:	68 5e 42 10 f0       	push   $0xf010425e
f010159d:	68 1d 03 00 00       	push   $0x31d
f01015a2:	68 38 42 10 f0       	push   $0xf0104238
f01015a7:	e8 df ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015ac:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01015af:	75 19                	jne    f01015ca <mem_init+0x603>
f01015b1:	68 64 43 10 f0       	push   $0xf0104364
f01015b6:	68 5e 42 10 f0       	push   $0xf010425e
f01015bb:	68 20 03 00 00       	push   $0x320
f01015c0:	68 38 42 10 f0       	push   $0xf0104238
f01015c5:	e8 c1 ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015ca:	39 c3                	cmp    %eax,%ebx
f01015cc:	74 05                	je     f01015d3 <mem_init+0x60c>
f01015ce:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01015d1:	75 19                	jne    f01015ec <mem_init+0x625>
f01015d3:	68 4c 3c 10 f0       	push   $0xf0103c4c
f01015d8:	68 5e 42 10 f0       	push   $0xf010425e
f01015dd:	68 21 03 00 00       	push   $0x321
f01015e2:	68 38 42 10 f0       	push   $0xf0104238
f01015e7:	e8 9f ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015ec:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01015f1:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015f4:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01015fb:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015fe:	83 ec 0c             	sub    $0xc,%esp
f0101601:	6a 00                	push   $0x0
f0101603:	e8 2e f7 ff ff       	call   f0100d36 <page_alloc>
f0101608:	83 c4 10             	add    $0x10,%esp
f010160b:	85 c0                	test   %eax,%eax
f010160d:	74 19                	je     f0101628 <mem_init+0x661>
f010160f:	68 cd 43 10 f0       	push   $0xf01043cd
f0101614:	68 5e 42 10 f0       	push   $0xf010425e
f0101619:	68 28 03 00 00       	push   $0x328
f010161e:	68 38 42 10 f0       	push   $0xf0104238
f0101623:	e8 63 ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101628:	83 ec 04             	sub    $0x4,%esp
f010162b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010162e:	50                   	push   %eax
f010162f:	6a 00                	push   $0x0
f0101631:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101637:	e8 90 f8 ff ff       	call   f0100ecc <page_lookup>
f010163c:	83 c4 10             	add    $0x10,%esp
f010163f:	85 c0                	test   %eax,%eax
f0101641:	74 19                	je     f010165c <mem_init+0x695>
f0101643:	68 8c 3c 10 f0       	push   $0xf0103c8c
f0101648:	68 5e 42 10 f0       	push   $0xf010425e
f010164d:	68 2b 03 00 00       	push   $0x32b
f0101652:	68 38 42 10 f0       	push   $0xf0104238
f0101657:	e8 2f ea ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010165c:	6a 02                	push   $0x2
f010165e:	6a 00                	push   $0x0
f0101660:	53                   	push   %ebx
f0101661:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101667:	e8 f5 f8 ff ff       	call   f0100f61 <page_insert>
f010166c:	83 c4 10             	add    $0x10,%esp
f010166f:	85 c0                	test   %eax,%eax
f0101671:	78 19                	js     f010168c <mem_init+0x6c5>
f0101673:	68 c4 3c 10 f0       	push   $0xf0103cc4
f0101678:	68 5e 42 10 f0       	push   $0xf010425e
f010167d:	68 2e 03 00 00       	push   $0x32e
f0101682:	68 38 42 10 f0       	push   $0xf0104238
f0101687:	e8 ff e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010168c:	83 ec 0c             	sub    $0xc,%esp
f010168f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101692:	e8 25 f7 ff ff       	call   f0100dbc <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101697:	6a 02                	push   $0x2
f0101699:	6a 00                	push   $0x0
f010169b:	53                   	push   %ebx
f010169c:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01016a2:	e8 ba f8 ff ff       	call   f0100f61 <page_insert>
f01016a7:	83 c4 20             	add    $0x20,%esp
f01016aa:	85 c0                	test   %eax,%eax
f01016ac:	74 19                	je     f01016c7 <mem_init+0x700>
f01016ae:	68 f4 3c 10 f0       	push   $0xf0103cf4
f01016b3:	68 5e 42 10 f0       	push   $0xf010425e
f01016b8:	68 32 03 00 00       	push   $0x332
f01016bd:	68 38 42 10 f0       	push   $0xf0104238
f01016c2:	e8 c4 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01016c7:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016cd:	a1 6c 69 11 f0       	mov    0xf011696c,%eax
f01016d2:	89 c1                	mov    %eax,%ecx
f01016d4:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01016d7:	8b 17                	mov    (%edi),%edx
f01016d9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01016df:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016e2:	29 c8                	sub    %ecx,%eax
f01016e4:	c1 f8 03             	sar    $0x3,%eax
f01016e7:	c1 e0 0c             	shl    $0xc,%eax
f01016ea:	39 c2                	cmp    %eax,%edx
f01016ec:	74 19                	je     f0101707 <mem_init+0x740>
f01016ee:	68 24 3d 10 f0       	push   $0xf0103d24
f01016f3:	68 5e 42 10 f0       	push   $0xf010425e
f01016f8:	68 33 03 00 00       	push   $0x333
f01016fd:	68 38 42 10 f0       	push   $0xf0104238
f0101702:	e8 84 e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101707:	ba 00 00 00 00       	mov    $0x0,%edx
f010170c:	89 f8                	mov    %edi,%eax
f010170e:	e8 2b f2 ff ff       	call   f010093e <check_va2pa>
f0101713:	89 da                	mov    %ebx,%edx
f0101715:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101718:	c1 fa 03             	sar    $0x3,%edx
f010171b:	c1 e2 0c             	shl    $0xc,%edx
f010171e:	39 d0                	cmp    %edx,%eax
f0101720:	74 19                	je     f010173b <mem_init+0x774>
f0101722:	68 4c 3d 10 f0       	push   $0xf0103d4c
f0101727:	68 5e 42 10 f0       	push   $0xf010425e
f010172c:	68 34 03 00 00       	push   $0x334
f0101731:	68 38 42 10 f0       	push   $0xf0104238
f0101736:	e8 50 e9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f010173b:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101740:	74 19                	je     f010175b <mem_init+0x794>
f0101742:	68 1f 44 10 f0       	push   $0xf010441f
f0101747:	68 5e 42 10 f0       	push   $0xf010425e
f010174c:	68 35 03 00 00       	push   $0x335
f0101751:	68 38 42 10 f0       	push   $0xf0104238
f0101756:	e8 30 e9 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f010175b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010175e:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101763:	74 19                	je     f010177e <mem_init+0x7b7>
f0101765:	68 30 44 10 f0       	push   $0xf0104430
f010176a:	68 5e 42 10 f0       	push   $0xf010425e
f010176f:	68 36 03 00 00       	push   $0x336
f0101774:	68 38 42 10 f0       	push   $0xf0104238
f0101779:	e8 0d e9 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010177e:	6a 02                	push   $0x2
f0101780:	68 00 10 00 00       	push   $0x1000
f0101785:	56                   	push   %esi
f0101786:	57                   	push   %edi
f0101787:	e8 d5 f7 ff ff       	call   f0100f61 <page_insert>
f010178c:	83 c4 10             	add    $0x10,%esp
f010178f:	85 c0                	test   %eax,%eax
f0101791:	74 19                	je     f01017ac <mem_init+0x7e5>
f0101793:	68 7c 3d 10 f0       	push   $0xf0103d7c
f0101798:	68 5e 42 10 f0       	push   $0xf010425e
f010179d:	68 39 03 00 00       	push   $0x339
f01017a2:	68 38 42 10 f0       	push   $0xf0104238
f01017a7:	e8 df e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017ac:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017b1:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f01017b6:	e8 83 f1 ff ff       	call   f010093e <check_va2pa>
f01017bb:	89 f2                	mov    %esi,%edx
f01017bd:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01017c3:	c1 fa 03             	sar    $0x3,%edx
f01017c6:	c1 e2 0c             	shl    $0xc,%edx
f01017c9:	39 d0                	cmp    %edx,%eax
f01017cb:	74 19                	je     f01017e6 <mem_init+0x81f>
f01017cd:	68 b8 3d 10 f0       	push   $0xf0103db8
f01017d2:	68 5e 42 10 f0       	push   $0xf010425e
f01017d7:	68 3a 03 00 00       	push   $0x33a
f01017dc:	68 38 42 10 f0       	push   $0xf0104238
f01017e1:	e8 a5 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01017e6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01017eb:	74 19                	je     f0101806 <mem_init+0x83f>
f01017ed:	68 41 44 10 f0       	push   $0xf0104441
f01017f2:	68 5e 42 10 f0       	push   $0xf010425e
f01017f7:	68 3b 03 00 00       	push   $0x33b
f01017fc:	68 38 42 10 f0       	push   $0xf0104238
f0101801:	e8 85 e8 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101806:	83 ec 0c             	sub    $0xc,%esp
f0101809:	6a 00                	push   $0x0
f010180b:	e8 26 f5 ff ff       	call   f0100d36 <page_alloc>
f0101810:	83 c4 10             	add    $0x10,%esp
f0101813:	85 c0                	test   %eax,%eax
f0101815:	74 19                	je     f0101830 <mem_init+0x869>
f0101817:	68 cd 43 10 f0       	push   $0xf01043cd
f010181c:	68 5e 42 10 f0       	push   $0xf010425e
f0101821:	68 3e 03 00 00       	push   $0x33e
f0101826:	68 38 42 10 f0       	push   $0xf0104238
f010182b:	e8 5b e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101830:	6a 02                	push   $0x2
f0101832:	68 00 10 00 00       	push   $0x1000
f0101837:	56                   	push   %esi
f0101838:	ff 35 68 69 11 f0    	pushl  0xf0116968
f010183e:	e8 1e f7 ff ff       	call   f0100f61 <page_insert>
f0101843:	83 c4 10             	add    $0x10,%esp
f0101846:	85 c0                	test   %eax,%eax
f0101848:	74 19                	je     f0101863 <mem_init+0x89c>
f010184a:	68 7c 3d 10 f0       	push   $0xf0103d7c
f010184f:	68 5e 42 10 f0       	push   $0xf010425e
f0101854:	68 41 03 00 00       	push   $0x341
f0101859:	68 38 42 10 f0       	push   $0xf0104238
f010185e:	e8 28 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101863:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101868:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f010186d:	e8 cc f0 ff ff       	call   f010093e <check_va2pa>
f0101872:	89 f2                	mov    %esi,%edx
f0101874:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f010187a:	c1 fa 03             	sar    $0x3,%edx
f010187d:	c1 e2 0c             	shl    $0xc,%edx
f0101880:	39 d0                	cmp    %edx,%eax
f0101882:	74 19                	je     f010189d <mem_init+0x8d6>
f0101884:	68 b8 3d 10 f0       	push   $0xf0103db8
f0101889:	68 5e 42 10 f0       	push   $0xf010425e
f010188e:	68 42 03 00 00       	push   $0x342
f0101893:	68 38 42 10 f0       	push   $0xf0104238
f0101898:	e8 ee e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010189d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018a2:	74 19                	je     f01018bd <mem_init+0x8f6>
f01018a4:	68 41 44 10 f0       	push   $0xf0104441
f01018a9:	68 5e 42 10 f0       	push   $0xf010425e
f01018ae:	68 43 03 00 00       	push   $0x343
f01018b3:	68 38 42 10 f0       	push   $0xf0104238
f01018b8:	e8 ce e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01018bd:	83 ec 0c             	sub    $0xc,%esp
f01018c0:	6a 00                	push   $0x0
f01018c2:	e8 6f f4 ff ff       	call   f0100d36 <page_alloc>
f01018c7:	83 c4 10             	add    $0x10,%esp
f01018ca:	85 c0                	test   %eax,%eax
f01018cc:	74 19                	je     f01018e7 <mem_init+0x920>
f01018ce:	68 cd 43 10 f0       	push   $0xf01043cd
f01018d3:	68 5e 42 10 f0       	push   $0xf010425e
f01018d8:	68 47 03 00 00       	push   $0x347
f01018dd:	68 38 42 10 f0       	push   $0xf0104238
f01018e2:	e8 a4 e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01018e7:	8b 15 68 69 11 f0    	mov    0xf0116968,%edx
f01018ed:	8b 02                	mov    (%edx),%eax
f01018ef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018f4:	89 c1                	mov    %eax,%ecx
f01018f6:	c1 e9 0c             	shr    $0xc,%ecx
f01018f9:	3b 0d 64 69 11 f0    	cmp    0xf0116964,%ecx
f01018ff:	72 15                	jb     f0101916 <mem_init+0x94f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101901:	50                   	push   %eax
f0101902:	68 e4 3a 10 f0       	push   $0xf0103ae4
f0101907:	68 4a 03 00 00       	push   $0x34a
f010190c:	68 38 42 10 f0       	push   $0xf0104238
f0101911:	e8 75 e7 ff ff       	call   f010008b <_panic>
f0101916:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010191b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010191e:	83 ec 04             	sub    $0x4,%esp
f0101921:	6a 00                	push   $0x0
f0101923:	68 00 10 00 00       	push   $0x1000
f0101928:	52                   	push   %edx
f0101929:	e8 da f4 ff ff       	call   f0100e08 <pgdir_walk>
f010192e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101931:	8d 51 04             	lea    0x4(%ecx),%edx
f0101934:	83 c4 10             	add    $0x10,%esp
f0101937:	39 d0                	cmp    %edx,%eax
f0101939:	74 19                	je     f0101954 <mem_init+0x98d>
f010193b:	68 e8 3d 10 f0       	push   $0xf0103de8
f0101940:	68 5e 42 10 f0       	push   $0xf010425e
f0101945:	68 4b 03 00 00       	push   $0x34b
f010194a:	68 38 42 10 f0       	push   $0xf0104238
f010194f:	e8 37 e7 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101954:	6a 06                	push   $0x6
f0101956:	68 00 10 00 00       	push   $0x1000
f010195b:	56                   	push   %esi
f010195c:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101962:	e8 fa f5 ff ff       	call   f0100f61 <page_insert>
f0101967:	83 c4 10             	add    $0x10,%esp
f010196a:	85 c0                	test   %eax,%eax
f010196c:	74 19                	je     f0101987 <mem_init+0x9c0>
f010196e:	68 28 3e 10 f0       	push   $0xf0103e28
f0101973:	68 5e 42 10 f0       	push   $0xf010425e
f0101978:	68 4e 03 00 00       	push   $0x34e
f010197d:	68 38 42 10 f0       	push   $0xf0104238
f0101982:	e8 04 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101987:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f010198d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101992:	89 f8                	mov    %edi,%eax
f0101994:	e8 a5 ef ff ff       	call   f010093e <check_va2pa>
f0101999:	89 f2                	mov    %esi,%edx
f010199b:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f01019a1:	c1 fa 03             	sar    $0x3,%edx
f01019a4:	c1 e2 0c             	shl    $0xc,%edx
f01019a7:	39 d0                	cmp    %edx,%eax
f01019a9:	74 19                	je     f01019c4 <mem_init+0x9fd>
f01019ab:	68 b8 3d 10 f0       	push   $0xf0103db8
f01019b0:	68 5e 42 10 f0       	push   $0xf010425e
f01019b5:	68 4f 03 00 00       	push   $0x34f
f01019ba:	68 38 42 10 f0       	push   $0xf0104238
f01019bf:	e8 c7 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01019c4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019c9:	74 19                	je     f01019e4 <mem_init+0xa1d>
f01019cb:	68 41 44 10 f0       	push   $0xf0104441
f01019d0:	68 5e 42 10 f0       	push   $0xf010425e
f01019d5:	68 50 03 00 00       	push   $0x350
f01019da:	68 38 42 10 f0       	push   $0xf0104238
f01019df:	e8 a7 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01019e4:	83 ec 04             	sub    $0x4,%esp
f01019e7:	6a 00                	push   $0x0
f01019e9:	68 00 10 00 00       	push   $0x1000
f01019ee:	57                   	push   %edi
f01019ef:	e8 14 f4 ff ff       	call   f0100e08 <pgdir_walk>
f01019f4:	83 c4 10             	add    $0x10,%esp
f01019f7:	f6 00 04             	testb  $0x4,(%eax)
f01019fa:	75 19                	jne    f0101a15 <mem_init+0xa4e>
f01019fc:	68 68 3e 10 f0       	push   $0xf0103e68
f0101a01:	68 5e 42 10 f0       	push   $0xf010425e
f0101a06:	68 51 03 00 00       	push   $0x351
f0101a0b:	68 38 42 10 f0       	push   $0xf0104238
f0101a10:	e8 76 e6 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a15:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101a1a:	f6 00 04             	testb  $0x4,(%eax)
f0101a1d:	75 19                	jne    f0101a38 <mem_init+0xa71>
f0101a1f:	68 52 44 10 f0       	push   $0xf0104452
f0101a24:	68 5e 42 10 f0       	push   $0xf010425e
f0101a29:	68 52 03 00 00       	push   $0x352
f0101a2e:	68 38 42 10 f0       	push   $0xf0104238
f0101a33:	e8 53 e6 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a38:	6a 02                	push   $0x2
f0101a3a:	68 00 10 00 00       	push   $0x1000
f0101a3f:	56                   	push   %esi
f0101a40:	50                   	push   %eax
f0101a41:	e8 1b f5 ff ff       	call   f0100f61 <page_insert>
f0101a46:	83 c4 10             	add    $0x10,%esp
f0101a49:	85 c0                	test   %eax,%eax
f0101a4b:	74 19                	je     f0101a66 <mem_init+0xa9f>
f0101a4d:	68 7c 3d 10 f0       	push   $0xf0103d7c
f0101a52:	68 5e 42 10 f0       	push   $0xf010425e
f0101a57:	68 55 03 00 00       	push   $0x355
f0101a5c:	68 38 42 10 f0       	push   $0xf0104238
f0101a61:	e8 25 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101a66:	83 ec 04             	sub    $0x4,%esp
f0101a69:	6a 00                	push   $0x0
f0101a6b:	68 00 10 00 00       	push   $0x1000
f0101a70:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101a76:	e8 8d f3 ff ff       	call   f0100e08 <pgdir_walk>
f0101a7b:	83 c4 10             	add    $0x10,%esp
f0101a7e:	f6 00 02             	testb  $0x2,(%eax)
f0101a81:	75 19                	jne    f0101a9c <mem_init+0xad5>
f0101a83:	68 9c 3e 10 f0       	push   $0xf0103e9c
f0101a88:	68 5e 42 10 f0       	push   $0xf010425e
f0101a8d:	68 56 03 00 00       	push   $0x356
f0101a92:	68 38 42 10 f0       	push   $0xf0104238
f0101a97:	e8 ef e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101a9c:	83 ec 04             	sub    $0x4,%esp
f0101a9f:	6a 00                	push   $0x0
f0101aa1:	68 00 10 00 00       	push   $0x1000
f0101aa6:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101aac:	e8 57 f3 ff ff       	call   f0100e08 <pgdir_walk>
f0101ab1:	83 c4 10             	add    $0x10,%esp
f0101ab4:	f6 00 04             	testb  $0x4,(%eax)
f0101ab7:	74 19                	je     f0101ad2 <mem_init+0xb0b>
f0101ab9:	68 d0 3e 10 f0       	push   $0xf0103ed0
f0101abe:	68 5e 42 10 f0       	push   $0xf010425e
f0101ac3:	68 57 03 00 00       	push   $0x357
f0101ac8:	68 38 42 10 f0       	push   $0xf0104238
f0101acd:	e8 b9 e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101ad2:	6a 02                	push   $0x2
f0101ad4:	68 00 00 40 00       	push   $0x400000
f0101ad9:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101adc:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101ae2:	e8 7a f4 ff ff       	call   f0100f61 <page_insert>
f0101ae7:	83 c4 10             	add    $0x10,%esp
f0101aea:	85 c0                	test   %eax,%eax
f0101aec:	78 19                	js     f0101b07 <mem_init+0xb40>
f0101aee:	68 08 3f 10 f0       	push   $0xf0103f08
f0101af3:	68 5e 42 10 f0       	push   $0xf010425e
f0101af8:	68 5a 03 00 00       	push   $0x35a
f0101afd:	68 38 42 10 f0       	push   $0xf0104238
f0101b02:	e8 84 e5 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b07:	6a 02                	push   $0x2
f0101b09:	68 00 10 00 00       	push   $0x1000
f0101b0e:	53                   	push   %ebx
f0101b0f:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b15:	e8 47 f4 ff ff       	call   f0100f61 <page_insert>
f0101b1a:	83 c4 10             	add    $0x10,%esp
f0101b1d:	85 c0                	test   %eax,%eax
f0101b1f:	74 19                	je     f0101b3a <mem_init+0xb73>
f0101b21:	68 40 3f 10 f0       	push   $0xf0103f40
f0101b26:	68 5e 42 10 f0       	push   $0xf010425e
f0101b2b:	68 5d 03 00 00       	push   $0x35d
f0101b30:	68 38 42 10 f0       	push   $0xf0104238
f0101b35:	e8 51 e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b3a:	83 ec 04             	sub    $0x4,%esp
f0101b3d:	6a 00                	push   $0x0
f0101b3f:	68 00 10 00 00       	push   $0x1000
f0101b44:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101b4a:	e8 b9 f2 ff ff       	call   f0100e08 <pgdir_walk>
f0101b4f:	83 c4 10             	add    $0x10,%esp
f0101b52:	f6 00 04             	testb  $0x4,(%eax)
f0101b55:	74 19                	je     f0101b70 <mem_init+0xba9>
f0101b57:	68 d0 3e 10 f0       	push   $0xf0103ed0
f0101b5c:	68 5e 42 10 f0       	push   $0xf010425e
f0101b61:	68 5e 03 00 00       	push   $0x35e
f0101b66:	68 38 42 10 f0       	push   $0xf0104238
f0101b6b:	e8 1b e5 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101b70:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101b76:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b7b:	89 f8                	mov    %edi,%eax
f0101b7d:	e8 bc ed ff ff       	call   f010093e <check_va2pa>
f0101b82:	89 c1                	mov    %eax,%ecx
f0101b84:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b87:	89 d8                	mov    %ebx,%eax
f0101b89:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101b8f:	c1 f8 03             	sar    $0x3,%eax
f0101b92:	c1 e0 0c             	shl    $0xc,%eax
f0101b95:	39 c1                	cmp    %eax,%ecx
f0101b97:	74 19                	je     f0101bb2 <mem_init+0xbeb>
f0101b99:	68 7c 3f 10 f0       	push   $0xf0103f7c
f0101b9e:	68 5e 42 10 f0       	push   $0xf010425e
f0101ba3:	68 61 03 00 00       	push   $0x361
f0101ba8:	68 38 42 10 f0       	push   $0xf0104238
f0101bad:	e8 d9 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101bb2:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bb7:	89 f8                	mov    %edi,%eax
f0101bb9:	e8 80 ed ff ff       	call   f010093e <check_va2pa>
f0101bbe:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101bc1:	74 19                	je     f0101bdc <mem_init+0xc15>
f0101bc3:	68 a8 3f 10 f0       	push   $0xf0103fa8
f0101bc8:	68 5e 42 10 f0       	push   $0xf010425e
f0101bcd:	68 62 03 00 00       	push   $0x362
f0101bd2:	68 38 42 10 f0       	push   $0xf0104238
f0101bd7:	e8 af e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101bdc:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101be1:	74 19                	je     f0101bfc <mem_init+0xc35>
f0101be3:	68 68 44 10 f0       	push   $0xf0104468
f0101be8:	68 5e 42 10 f0       	push   $0xf010425e
f0101bed:	68 64 03 00 00       	push   $0x364
f0101bf2:	68 38 42 10 f0       	push   $0xf0104238
f0101bf7:	e8 8f e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101bfc:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c01:	74 19                	je     f0101c1c <mem_init+0xc55>
f0101c03:	68 79 44 10 f0       	push   $0xf0104479
f0101c08:	68 5e 42 10 f0       	push   $0xf010425e
f0101c0d:	68 65 03 00 00       	push   $0x365
f0101c12:	68 38 42 10 f0       	push   $0xf0104238
f0101c17:	e8 6f e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c1c:	83 ec 0c             	sub    $0xc,%esp
f0101c1f:	6a 00                	push   $0x0
f0101c21:	e8 10 f1 ff ff       	call   f0100d36 <page_alloc>
f0101c26:	83 c4 10             	add    $0x10,%esp
f0101c29:	85 c0                	test   %eax,%eax
f0101c2b:	74 04                	je     f0101c31 <mem_init+0xc6a>
f0101c2d:	39 c6                	cmp    %eax,%esi
f0101c2f:	74 19                	je     f0101c4a <mem_init+0xc83>
f0101c31:	68 d8 3f 10 f0       	push   $0xf0103fd8
f0101c36:	68 5e 42 10 f0       	push   $0xf010425e
f0101c3b:	68 68 03 00 00       	push   $0x368
f0101c40:	68 38 42 10 f0       	push   $0xf0104238
f0101c45:	e8 41 e4 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101c4a:	83 ec 08             	sub    $0x8,%esp
f0101c4d:	6a 00                	push   $0x0
f0101c4f:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101c55:	e8 cc f2 ff ff       	call   f0100f26 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101c5a:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101c60:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c65:	89 f8                	mov    %edi,%eax
f0101c67:	e8 d2 ec ff ff       	call   f010093e <check_va2pa>
f0101c6c:	83 c4 10             	add    $0x10,%esp
f0101c6f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101c72:	74 19                	je     f0101c8d <mem_init+0xcc6>
f0101c74:	68 fc 3f 10 f0       	push   $0xf0103ffc
f0101c79:	68 5e 42 10 f0       	push   $0xf010425e
f0101c7e:	68 6c 03 00 00       	push   $0x36c
f0101c83:	68 38 42 10 f0       	push   $0xf0104238
f0101c88:	e8 fe e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c8d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c92:	89 f8                	mov    %edi,%eax
f0101c94:	e8 a5 ec ff ff       	call   f010093e <check_va2pa>
f0101c99:	89 da                	mov    %ebx,%edx
f0101c9b:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101ca1:	c1 fa 03             	sar    $0x3,%edx
f0101ca4:	c1 e2 0c             	shl    $0xc,%edx
f0101ca7:	39 d0                	cmp    %edx,%eax
f0101ca9:	74 19                	je     f0101cc4 <mem_init+0xcfd>
f0101cab:	68 a8 3f 10 f0       	push   $0xf0103fa8
f0101cb0:	68 5e 42 10 f0       	push   $0xf010425e
f0101cb5:	68 6d 03 00 00       	push   $0x36d
f0101cba:	68 38 42 10 f0       	push   $0xf0104238
f0101cbf:	e8 c7 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101cc4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101cc9:	74 19                	je     f0101ce4 <mem_init+0xd1d>
f0101ccb:	68 1f 44 10 f0       	push   $0xf010441f
f0101cd0:	68 5e 42 10 f0       	push   $0xf010425e
f0101cd5:	68 6e 03 00 00       	push   $0x36e
f0101cda:	68 38 42 10 f0       	push   $0xf0104238
f0101cdf:	e8 a7 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101ce4:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ce9:	74 19                	je     f0101d04 <mem_init+0xd3d>
f0101ceb:	68 79 44 10 f0       	push   $0xf0104479
f0101cf0:	68 5e 42 10 f0       	push   $0xf010425e
f0101cf5:	68 6f 03 00 00       	push   $0x36f
f0101cfa:	68 38 42 10 f0       	push   $0xf0104238
f0101cff:	e8 87 e3 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d04:	6a 00                	push   $0x0
f0101d06:	68 00 10 00 00       	push   $0x1000
f0101d0b:	53                   	push   %ebx
f0101d0c:	57                   	push   %edi
f0101d0d:	e8 4f f2 ff ff       	call   f0100f61 <page_insert>
f0101d12:	83 c4 10             	add    $0x10,%esp
f0101d15:	85 c0                	test   %eax,%eax
f0101d17:	74 19                	je     f0101d32 <mem_init+0xd6b>
f0101d19:	68 20 40 10 f0       	push   $0xf0104020
f0101d1e:	68 5e 42 10 f0       	push   $0xf010425e
f0101d23:	68 72 03 00 00       	push   $0x372
f0101d28:	68 38 42 10 f0       	push   $0xf0104238
f0101d2d:	e8 59 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101d32:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d37:	75 19                	jne    f0101d52 <mem_init+0xd8b>
f0101d39:	68 8a 44 10 f0       	push   $0xf010448a
f0101d3e:	68 5e 42 10 f0       	push   $0xf010425e
f0101d43:	68 73 03 00 00       	push   $0x373
f0101d48:	68 38 42 10 f0       	push   $0xf0104238
f0101d4d:	e8 39 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101d52:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101d55:	74 19                	je     f0101d70 <mem_init+0xda9>
f0101d57:	68 96 44 10 f0       	push   $0xf0104496
f0101d5c:	68 5e 42 10 f0       	push   $0xf010425e
f0101d61:	68 74 03 00 00       	push   $0x374
f0101d66:	68 38 42 10 f0       	push   $0xf0104238
f0101d6b:	e8 1b e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101d70:	83 ec 08             	sub    $0x8,%esp
f0101d73:	68 00 10 00 00       	push   $0x1000
f0101d78:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101d7e:	e8 a3 f1 ff ff       	call   f0100f26 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d83:	8b 3d 68 69 11 f0    	mov    0xf0116968,%edi
f0101d89:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d8e:	89 f8                	mov    %edi,%eax
f0101d90:	e8 a9 eb ff ff       	call   f010093e <check_va2pa>
f0101d95:	83 c4 10             	add    $0x10,%esp
f0101d98:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d9b:	74 19                	je     f0101db6 <mem_init+0xdef>
f0101d9d:	68 fc 3f 10 f0       	push   $0xf0103ffc
f0101da2:	68 5e 42 10 f0       	push   $0xf010425e
f0101da7:	68 78 03 00 00       	push   $0x378
f0101dac:	68 38 42 10 f0       	push   $0xf0104238
f0101db1:	e8 d5 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101db6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dbb:	89 f8                	mov    %edi,%eax
f0101dbd:	e8 7c eb ff ff       	call   f010093e <check_va2pa>
f0101dc2:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dc5:	74 19                	je     f0101de0 <mem_init+0xe19>
f0101dc7:	68 58 40 10 f0       	push   $0xf0104058
f0101dcc:	68 5e 42 10 f0       	push   $0xf010425e
f0101dd1:	68 79 03 00 00       	push   $0x379
f0101dd6:	68 38 42 10 f0       	push   $0xf0104238
f0101ddb:	e8 ab e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101de0:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101de5:	74 19                	je     f0101e00 <mem_init+0xe39>
f0101de7:	68 ab 44 10 f0       	push   $0xf01044ab
f0101dec:	68 5e 42 10 f0       	push   $0xf010425e
f0101df1:	68 7a 03 00 00       	push   $0x37a
f0101df6:	68 38 42 10 f0       	push   $0xf0104238
f0101dfb:	e8 8b e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e00:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e05:	74 19                	je     f0101e20 <mem_init+0xe59>
f0101e07:	68 79 44 10 f0       	push   $0xf0104479
f0101e0c:	68 5e 42 10 f0       	push   $0xf010425e
f0101e11:	68 7b 03 00 00       	push   $0x37b
f0101e16:	68 38 42 10 f0       	push   $0xf0104238
f0101e1b:	e8 6b e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e20:	83 ec 0c             	sub    $0xc,%esp
f0101e23:	6a 00                	push   $0x0
f0101e25:	e8 0c ef ff ff       	call   f0100d36 <page_alloc>
f0101e2a:	83 c4 10             	add    $0x10,%esp
f0101e2d:	39 c3                	cmp    %eax,%ebx
f0101e2f:	75 04                	jne    f0101e35 <mem_init+0xe6e>
f0101e31:	85 c0                	test   %eax,%eax
f0101e33:	75 19                	jne    f0101e4e <mem_init+0xe87>
f0101e35:	68 80 40 10 f0       	push   $0xf0104080
f0101e3a:	68 5e 42 10 f0       	push   $0xf010425e
f0101e3f:	68 7e 03 00 00       	push   $0x37e
f0101e44:	68 38 42 10 f0       	push   $0xf0104238
f0101e49:	e8 3d e2 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e4e:	83 ec 0c             	sub    $0xc,%esp
f0101e51:	6a 00                	push   $0x0
f0101e53:	e8 de ee ff ff       	call   f0100d36 <page_alloc>
f0101e58:	83 c4 10             	add    $0x10,%esp
f0101e5b:	85 c0                	test   %eax,%eax
f0101e5d:	74 19                	je     f0101e78 <mem_init+0xeb1>
f0101e5f:	68 cd 43 10 f0       	push   $0xf01043cd
f0101e64:	68 5e 42 10 f0       	push   $0xf010425e
f0101e69:	68 81 03 00 00       	push   $0x381
f0101e6e:	68 38 42 10 f0       	push   $0xf0104238
f0101e73:	e8 13 e2 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e78:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0101e7e:	8b 11                	mov    (%ecx),%edx
f0101e80:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e86:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e89:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101e8f:	c1 f8 03             	sar    $0x3,%eax
f0101e92:	c1 e0 0c             	shl    $0xc,%eax
f0101e95:	39 c2                	cmp    %eax,%edx
f0101e97:	74 19                	je     f0101eb2 <mem_init+0xeeb>
f0101e99:	68 24 3d 10 f0       	push   $0xf0103d24
f0101e9e:	68 5e 42 10 f0       	push   $0xf010425e
f0101ea3:	68 84 03 00 00       	push   $0x384
f0101ea8:	68 38 42 10 f0       	push   $0xf0104238
f0101ead:	e8 d9 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101eb2:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101eb8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ebb:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ec0:	74 19                	je     f0101edb <mem_init+0xf14>
f0101ec2:	68 30 44 10 f0       	push   $0xf0104430
f0101ec7:	68 5e 42 10 f0       	push   $0xf010425e
f0101ecc:	68 86 03 00 00       	push   $0x386
f0101ed1:	68 38 42 10 f0       	push   $0xf0104238
f0101ed6:	e8 b0 e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101edb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ede:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101ee4:	83 ec 0c             	sub    $0xc,%esp
f0101ee7:	50                   	push   %eax
f0101ee8:	e8 cf ee ff ff       	call   f0100dbc <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101eed:	83 c4 0c             	add    $0xc,%esp
f0101ef0:	6a 01                	push   $0x1
f0101ef2:	68 00 10 40 00       	push   $0x401000
f0101ef7:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101efd:	e8 06 ef ff ff       	call   f0100e08 <pgdir_walk>
f0101f02:	89 c7                	mov    %eax,%edi
f0101f04:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f07:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0101f0c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f0f:	8b 40 04             	mov    0x4(%eax),%eax
f0101f12:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f17:	8b 0d 64 69 11 f0    	mov    0xf0116964,%ecx
f0101f1d:	89 c2                	mov    %eax,%edx
f0101f1f:	c1 ea 0c             	shr    $0xc,%edx
f0101f22:	83 c4 10             	add    $0x10,%esp
f0101f25:	39 ca                	cmp    %ecx,%edx
f0101f27:	72 15                	jb     f0101f3e <mem_init+0xf77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f29:	50                   	push   %eax
f0101f2a:	68 e4 3a 10 f0       	push   $0xf0103ae4
f0101f2f:	68 8d 03 00 00       	push   $0x38d
f0101f34:	68 38 42 10 f0       	push   $0xf0104238
f0101f39:	e8 4d e1 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f3e:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f43:	39 c7                	cmp    %eax,%edi
f0101f45:	74 19                	je     f0101f60 <mem_init+0xf99>
f0101f47:	68 bc 44 10 f0       	push   $0xf01044bc
f0101f4c:	68 5e 42 10 f0       	push   $0xf010425e
f0101f51:	68 8e 03 00 00       	push   $0x38e
f0101f56:	68 38 42 10 f0       	push   $0xf0104238
f0101f5b:	e8 2b e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101f60:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f63:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101f6a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f6d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f73:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0101f79:	c1 f8 03             	sar    $0x3,%eax
f0101f7c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f7f:	89 c2                	mov    %eax,%edx
f0101f81:	c1 ea 0c             	shr    $0xc,%edx
f0101f84:	39 d1                	cmp    %edx,%ecx
f0101f86:	77 12                	ja     f0101f9a <mem_init+0xfd3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f88:	50                   	push   %eax
f0101f89:	68 e4 3a 10 f0       	push   $0xf0103ae4
f0101f8e:	6a 52                	push   $0x52
f0101f90:	68 44 42 10 f0       	push   $0xf0104244
f0101f95:	e8 f1 e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101f9a:	83 ec 04             	sub    $0x4,%esp
f0101f9d:	68 00 10 00 00       	push   $0x1000
f0101fa2:	68 ff 00 00 00       	push   $0xff
f0101fa7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101fac:	50                   	push   %eax
f0101fad:	e8 48 11 00 00       	call   f01030fa <memset>
	page_free(pp0);
f0101fb2:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101fb5:	89 3c 24             	mov    %edi,(%esp)
f0101fb8:	e8 ff ed ff ff       	call   f0100dbc <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101fbd:	83 c4 0c             	add    $0xc,%esp
f0101fc0:	6a 01                	push   $0x1
f0101fc2:	6a 00                	push   $0x0
f0101fc4:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0101fca:	e8 39 ee ff ff       	call   f0100e08 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fcf:	89 fa                	mov    %edi,%edx
f0101fd1:	2b 15 6c 69 11 f0    	sub    0xf011696c,%edx
f0101fd7:	c1 fa 03             	sar    $0x3,%edx
f0101fda:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fdd:	89 d0                	mov    %edx,%eax
f0101fdf:	c1 e8 0c             	shr    $0xc,%eax
f0101fe2:	83 c4 10             	add    $0x10,%esp
f0101fe5:	3b 05 64 69 11 f0    	cmp    0xf0116964,%eax
f0101feb:	72 12                	jb     f0101fff <mem_init+0x1038>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fed:	52                   	push   %edx
f0101fee:	68 e4 3a 10 f0       	push   $0xf0103ae4
f0101ff3:	6a 52                	push   $0x52
f0101ff5:	68 44 42 10 f0       	push   $0xf0104244
f0101ffa:	e8 8c e0 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0101fff:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102005:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102008:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010200e:	f6 00 01             	testb  $0x1,(%eax)
f0102011:	74 19                	je     f010202c <mem_init+0x1065>
f0102013:	68 d4 44 10 f0       	push   $0xf01044d4
f0102018:	68 5e 42 10 f0       	push   $0xf010425e
f010201d:	68 98 03 00 00       	push   $0x398
f0102022:	68 38 42 10 f0       	push   $0xf0104238
f0102027:	e8 5f e0 ff ff       	call   f010008b <_panic>
f010202c:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010202f:	39 d0                	cmp    %edx,%eax
f0102031:	75 db                	jne    f010200e <mem_init+0x1047>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102033:	a1 68 69 11 f0       	mov    0xf0116968,%eax
f0102038:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010203e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102041:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102047:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010204a:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f0102050:	83 ec 0c             	sub    $0xc,%esp
f0102053:	50                   	push   %eax
f0102054:	e8 63 ed ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f0102059:	89 1c 24             	mov    %ebx,(%esp)
f010205c:	e8 5b ed ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f0102061:	89 34 24             	mov    %esi,(%esp)
f0102064:	e8 53 ed ff ff       	call   f0100dbc <page_free>

	cprintf("check_page() succeeded!\n");
f0102069:	c7 04 24 eb 44 10 f0 	movl   $0xf01044eb,(%esp)
f0102070:	e8 d1 05 00 00       	call   f0102646 <cprintf>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102075:	8b 35 68 69 11 f0    	mov    0xf0116968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010207b:	a1 64 69 11 f0       	mov    0xf0116964,%eax
f0102080:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102083:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010208a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010208f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102092:	8b 3d 6c 69 11 f0    	mov    0xf011696c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102098:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010209b:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010209e:	bb 00 00 00 00       	mov    $0x0,%ebx
f01020a3:	eb 55                	jmp    f01020fa <mem_init+0x1133>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01020a5:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f01020ab:	89 f0                	mov    %esi,%eax
f01020ad:	e8 8c e8 ff ff       	call   f010093e <check_va2pa>
f01020b2:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f01020b9:	77 15                	ja     f01020d0 <mem_init+0x1109>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020bb:	57                   	push   %edi
f01020bc:	68 28 3c 10 f0       	push   $0xf0103c28
f01020c1:	68 da 02 00 00       	push   $0x2da
f01020c6:	68 38 42 10 f0       	push   $0xf0104238
f01020cb:	e8 bb df ff ff       	call   f010008b <_panic>
f01020d0:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01020d7:	39 d0                	cmp    %edx,%eax
f01020d9:	74 19                	je     f01020f4 <mem_init+0x112d>
f01020db:	68 a4 40 10 f0       	push   $0xf01040a4
f01020e0:	68 5e 42 10 f0       	push   $0xf010425e
f01020e5:	68 da 02 00 00       	push   $0x2da
f01020ea:	68 38 42 10 f0       	push   $0xf0104238
f01020ef:	e8 97 df ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01020f4:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01020fa:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01020fd:	77 a6                	ja     f01020a5 <mem_init+0x10de>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01020ff:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102102:	c1 e7 0c             	shl    $0xc,%edi
f0102105:	bb 00 00 00 00       	mov    $0x0,%ebx
f010210a:	eb 30                	jmp    f010213c <mem_init+0x1175>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010210c:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102112:	89 f0                	mov    %esi,%eax
f0102114:	e8 25 e8 ff ff       	call   f010093e <check_va2pa>
f0102119:	39 c3                	cmp    %eax,%ebx
f010211b:	74 19                	je     f0102136 <mem_init+0x116f>
f010211d:	68 d8 40 10 f0       	push   $0xf01040d8
f0102122:	68 5e 42 10 f0       	push   $0xf010425e
f0102127:	68 df 02 00 00       	push   $0x2df
f010212c:	68 38 42 10 f0       	push   $0xf0104238
f0102131:	e8 55 df ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102136:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010213c:	39 fb                	cmp    %edi,%ebx
f010213e:	72 cc                	jb     f010210c <mem_init+0x1145>
f0102140:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102145:	bf 00 c0 10 f0       	mov    $0xf010c000,%edi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010214a:	89 da                	mov    %ebx,%edx
f010214c:	89 f0                	mov    %esi,%eax
f010214e:	e8 eb e7 ff ff       	call   f010093e <check_va2pa>
f0102153:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0102159:	77 19                	ja     f0102174 <mem_init+0x11ad>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010215b:	68 00 c0 10 f0       	push   $0xf010c000
f0102160:	68 28 3c 10 f0       	push   $0xf0103c28
f0102165:	68 e3 02 00 00       	push   $0x2e3
f010216a:	68 38 42 10 f0       	push   $0xf0104238
f010216f:	e8 17 df ff ff       	call   f010008b <_panic>
f0102174:	8d 93 00 40 11 10    	lea    0x10114000(%ebx),%edx
f010217a:	39 d0                	cmp    %edx,%eax
f010217c:	74 19                	je     f0102197 <mem_init+0x11d0>
f010217e:	68 00 41 10 f0       	push   $0xf0104100
f0102183:	68 5e 42 10 f0       	push   $0xf010425e
f0102188:	68 e3 02 00 00       	push   $0x2e3
f010218d:	68 38 42 10 f0       	push   $0xf0104238
f0102192:	e8 f4 de ff ff       	call   f010008b <_panic>
f0102197:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010219d:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01021a3:	75 a5                	jne    f010214a <mem_init+0x1183>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01021a5:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01021aa:	89 f0                	mov    %esi,%eax
f01021ac:	e8 8d e7 ff ff       	call   f010093e <check_va2pa>
f01021b1:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021b4:	74 51                	je     f0102207 <mem_init+0x1240>
f01021b6:	68 48 41 10 f0       	push   $0xf0104148
f01021bb:	68 5e 42 10 f0       	push   $0xf010425e
f01021c0:	68 e4 02 00 00       	push   $0x2e4
f01021c5:	68 38 42 10 f0       	push   $0xf0104238
f01021ca:	e8 bc de ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01021cf:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01021d4:	72 36                	jb     f010220c <mem_init+0x1245>
f01021d6:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01021db:	76 07                	jbe    f01021e4 <mem_init+0x121d>
f01021dd:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01021e2:	75 28                	jne    f010220c <mem_init+0x1245>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01021e4:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01021e8:	0f 85 83 00 00 00    	jne    f0102271 <mem_init+0x12aa>
f01021ee:	68 04 45 10 f0       	push   $0xf0104504
f01021f3:	68 5e 42 10 f0       	push   $0xf010425e
f01021f8:	68 ec 02 00 00       	push   $0x2ec
f01021fd:	68 38 42 10 f0       	push   $0xf0104238
f0102202:	e8 84 de ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102207:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010220c:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102211:	76 3f                	jbe    f0102252 <mem_init+0x128b>
				assert(pgdir[i] & PTE_P);
f0102213:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102216:	f6 c2 01             	test   $0x1,%dl
f0102219:	75 19                	jne    f0102234 <mem_init+0x126d>
f010221b:	68 04 45 10 f0       	push   $0xf0104504
f0102220:	68 5e 42 10 f0       	push   $0xf010425e
f0102225:	68 f0 02 00 00       	push   $0x2f0
f010222a:	68 38 42 10 f0       	push   $0xf0104238
f010222f:	e8 57 de ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0102234:	f6 c2 02             	test   $0x2,%dl
f0102237:	75 38                	jne    f0102271 <mem_init+0x12aa>
f0102239:	68 15 45 10 f0       	push   $0xf0104515
f010223e:	68 5e 42 10 f0       	push   $0xf010425e
f0102243:	68 f1 02 00 00       	push   $0x2f1
f0102248:	68 38 42 10 f0       	push   $0xf0104238
f010224d:	e8 39 de ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0102252:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102256:	74 19                	je     f0102271 <mem_init+0x12aa>
f0102258:	68 26 45 10 f0       	push   $0xf0104526
f010225d:	68 5e 42 10 f0       	push   $0xf010425e
f0102262:	68 f3 02 00 00       	push   $0x2f3
f0102267:	68 38 42 10 f0       	push   $0xf0104238
f010226c:	e8 1a de ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102271:	83 c0 01             	add    $0x1,%eax
f0102274:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102279:	0f 86 50 ff ff ff    	jbe    f01021cf <mem_init+0x1208>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010227f:	83 ec 0c             	sub    $0xc,%esp
f0102282:	68 78 41 10 f0       	push   $0xf0104178
f0102287:	e8 ba 03 00 00       	call   f0102646 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010228c:	a1 68 69 11 f0       	mov    0xf0116968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102291:	83 c4 10             	add    $0x10,%esp
f0102294:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102299:	77 15                	ja     f01022b0 <mem_init+0x12e9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010229b:	50                   	push   %eax
f010229c:	68 28 3c 10 f0       	push   $0xf0103c28
f01022a1:	68 cf 00 00 00       	push   $0xcf
f01022a6:	68 38 42 10 f0       	push   $0xf0104238
f01022ab:	e8 db dd ff ff       	call   f010008b <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01022b0:	05 00 00 00 10       	add    $0x10000000,%eax
f01022b5:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01022b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01022bd:	e8 e0 e6 ff ff       	call   f01009a2 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01022c2:	0f 20 c0             	mov    %cr0,%eax
f01022c5:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01022c8:	0d 23 00 05 80       	or     $0x80050023,%eax
f01022cd:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01022d0:	83 ec 0c             	sub    $0xc,%esp
f01022d3:	6a 00                	push   $0x0
f01022d5:	e8 5c ea ff ff       	call   f0100d36 <page_alloc>
f01022da:	89 c3                	mov    %eax,%ebx
f01022dc:	83 c4 10             	add    $0x10,%esp
f01022df:	85 c0                	test   %eax,%eax
f01022e1:	75 19                	jne    f01022fc <mem_init+0x1335>
f01022e3:	68 22 43 10 f0       	push   $0xf0104322
f01022e8:	68 5e 42 10 f0       	push   $0xf010425e
f01022ed:	68 b3 03 00 00       	push   $0x3b3
f01022f2:	68 38 42 10 f0       	push   $0xf0104238
f01022f7:	e8 8f dd ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01022fc:	83 ec 0c             	sub    $0xc,%esp
f01022ff:	6a 00                	push   $0x0
f0102301:	e8 30 ea ff ff       	call   f0100d36 <page_alloc>
f0102306:	89 c7                	mov    %eax,%edi
f0102308:	83 c4 10             	add    $0x10,%esp
f010230b:	85 c0                	test   %eax,%eax
f010230d:	75 19                	jne    f0102328 <mem_init+0x1361>
f010230f:	68 38 43 10 f0       	push   $0xf0104338
f0102314:	68 5e 42 10 f0       	push   $0xf010425e
f0102319:	68 b4 03 00 00       	push   $0x3b4
f010231e:	68 38 42 10 f0       	push   $0xf0104238
f0102323:	e8 63 dd ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0102328:	83 ec 0c             	sub    $0xc,%esp
f010232b:	6a 00                	push   $0x0
f010232d:	e8 04 ea ff ff       	call   f0100d36 <page_alloc>
f0102332:	89 c6                	mov    %eax,%esi
f0102334:	83 c4 10             	add    $0x10,%esp
f0102337:	85 c0                	test   %eax,%eax
f0102339:	75 19                	jne    f0102354 <mem_init+0x138d>
f010233b:	68 4e 43 10 f0       	push   $0xf010434e
f0102340:	68 5e 42 10 f0       	push   $0xf010425e
f0102345:	68 b5 03 00 00       	push   $0x3b5
f010234a:	68 38 42 10 f0       	push   $0xf0104238
f010234f:	e8 37 dd ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102354:	83 ec 0c             	sub    $0xc,%esp
f0102357:	53                   	push   %ebx
f0102358:	e8 5f ea ff ff       	call   f0100dbc <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010235d:	89 f8                	mov    %edi,%eax
f010235f:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102365:	c1 f8 03             	sar    $0x3,%eax
f0102368:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010236b:	89 c2                	mov    %eax,%edx
f010236d:	c1 ea 0c             	shr    $0xc,%edx
f0102370:	83 c4 10             	add    $0x10,%esp
f0102373:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f0102379:	72 12                	jb     f010238d <mem_init+0x13c6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010237b:	50                   	push   %eax
f010237c:	68 e4 3a 10 f0       	push   $0xf0103ae4
f0102381:	6a 52                	push   $0x52
f0102383:	68 44 42 10 f0       	push   $0xf0104244
f0102388:	e8 fe dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010238d:	83 ec 04             	sub    $0x4,%esp
f0102390:	68 00 10 00 00       	push   $0x1000
f0102395:	6a 01                	push   $0x1
f0102397:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010239c:	50                   	push   %eax
f010239d:	e8 58 0d 00 00       	call   f01030fa <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01023a2:	89 f0                	mov    %esi,%eax
f01023a4:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01023aa:	c1 f8 03             	sar    $0x3,%eax
f01023ad:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023b0:	89 c2                	mov    %eax,%edx
f01023b2:	c1 ea 0c             	shr    $0xc,%edx
f01023b5:	83 c4 10             	add    $0x10,%esp
f01023b8:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01023be:	72 12                	jb     f01023d2 <mem_init+0x140b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023c0:	50                   	push   %eax
f01023c1:	68 e4 3a 10 f0       	push   $0xf0103ae4
f01023c6:	6a 52                	push   $0x52
f01023c8:	68 44 42 10 f0       	push   $0xf0104244
f01023cd:	e8 b9 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01023d2:	83 ec 04             	sub    $0x4,%esp
f01023d5:	68 00 10 00 00       	push   $0x1000
f01023da:	6a 02                	push   $0x2
f01023dc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01023e1:	50                   	push   %eax
f01023e2:	e8 13 0d 00 00       	call   f01030fa <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01023e7:	6a 02                	push   $0x2
f01023e9:	68 00 10 00 00       	push   $0x1000
f01023ee:	57                   	push   %edi
f01023ef:	ff 35 68 69 11 f0    	pushl  0xf0116968
f01023f5:	e8 67 eb ff ff       	call   f0100f61 <page_insert>
	assert(pp1->pp_ref == 1);
f01023fa:	83 c4 20             	add    $0x20,%esp
f01023fd:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102402:	74 19                	je     f010241d <mem_init+0x1456>
f0102404:	68 1f 44 10 f0       	push   $0xf010441f
f0102409:	68 5e 42 10 f0       	push   $0xf010425e
f010240e:	68 ba 03 00 00       	push   $0x3ba
f0102413:	68 38 42 10 f0       	push   $0xf0104238
f0102418:	e8 6e dc ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010241d:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102424:	01 01 01 
f0102427:	74 19                	je     f0102442 <mem_init+0x147b>
f0102429:	68 98 41 10 f0       	push   $0xf0104198
f010242e:	68 5e 42 10 f0       	push   $0xf010425e
f0102433:	68 bb 03 00 00       	push   $0x3bb
f0102438:	68 38 42 10 f0       	push   $0xf0104238
f010243d:	e8 49 dc ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102442:	6a 02                	push   $0x2
f0102444:	68 00 10 00 00       	push   $0x1000
f0102449:	56                   	push   %esi
f010244a:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102450:	e8 0c eb ff ff       	call   f0100f61 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102455:	83 c4 10             	add    $0x10,%esp
f0102458:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010245f:	02 02 02 
f0102462:	74 19                	je     f010247d <mem_init+0x14b6>
f0102464:	68 bc 41 10 f0       	push   $0xf01041bc
f0102469:	68 5e 42 10 f0       	push   $0xf010425e
f010246e:	68 bd 03 00 00       	push   $0x3bd
f0102473:	68 38 42 10 f0       	push   $0xf0104238
f0102478:	e8 0e dc ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010247d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102482:	74 19                	je     f010249d <mem_init+0x14d6>
f0102484:	68 41 44 10 f0       	push   $0xf0104441
f0102489:	68 5e 42 10 f0       	push   $0xf010425e
f010248e:	68 be 03 00 00       	push   $0x3be
f0102493:	68 38 42 10 f0       	push   $0xf0104238
f0102498:	e8 ee db ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f010249d:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01024a2:	74 19                	je     f01024bd <mem_init+0x14f6>
f01024a4:	68 ab 44 10 f0       	push   $0xf01044ab
f01024a9:	68 5e 42 10 f0       	push   $0xf010425e
f01024ae:	68 bf 03 00 00       	push   $0x3bf
f01024b3:	68 38 42 10 f0       	push   $0xf0104238
f01024b8:	e8 ce db ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01024bd:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01024c4:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024c7:	89 f0                	mov    %esi,%eax
f01024c9:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f01024cf:	c1 f8 03             	sar    $0x3,%eax
f01024d2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024d5:	89 c2                	mov    %eax,%edx
f01024d7:	c1 ea 0c             	shr    $0xc,%edx
f01024da:	3b 15 64 69 11 f0    	cmp    0xf0116964,%edx
f01024e0:	72 12                	jb     f01024f4 <mem_init+0x152d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024e2:	50                   	push   %eax
f01024e3:	68 e4 3a 10 f0       	push   $0xf0103ae4
f01024e8:	6a 52                	push   $0x52
f01024ea:	68 44 42 10 f0       	push   $0xf0104244
f01024ef:	e8 97 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01024f4:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01024fb:	03 03 03 
f01024fe:	74 19                	je     f0102519 <mem_init+0x1552>
f0102500:	68 e0 41 10 f0       	push   $0xf01041e0
f0102505:	68 5e 42 10 f0       	push   $0xf010425e
f010250a:	68 c1 03 00 00       	push   $0x3c1
f010250f:	68 38 42 10 f0       	push   $0xf0104238
f0102514:	e8 72 db ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102519:	83 ec 08             	sub    $0x8,%esp
f010251c:	68 00 10 00 00       	push   $0x1000
f0102521:	ff 35 68 69 11 f0    	pushl  0xf0116968
f0102527:	e8 fa e9 ff ff       	call   f0100f26 <page_remove>
	assert(pp2->pp_ref == 0);
f010252c:	83 c4 10             	add    $0x10,%esp
f010252f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102534:	74 19                	je     f010254f <mem_init+0x1588>
f0102536:	68 79 44 10 f0       	push   $0xf0104479
f010253b:	68 5e 42 10 f0       	push   $0xf010425e
f0102540:	68 c3 03 00 00       	push   $0x3c3
f0102545:	68 38 42 10 f0       	push   $0xf0104238
f010254a:	e8 3c db ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010254f:	8b 0d 68 69 11 f0    	mov    0xf0116968,%ecx
f0102555:	8b 11                	mov    (%ecx),%edx
f0102557:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010255d:	89 d8                	mov    %ebx,%eax
f010255f:	2b 05 6c 69 11 f0    	sub    0xf011696c,%eax
f0102565:	c1 f8 03             	sar    $0x3,%eax
f0102568:	c1 e0 0c             	shl    $0xc,%eax
f010256b:	39 c2                	cmp    %eax,%edx
f010256d:	74 19                	je     f0102588 <mem_init+0x15c1>
f010256f:	68 24 3d 10 f0       	push   $0xf0103d24
f0102574:	68 5e 42 10 f0       	push   $0xf010425e
f0102579:	68 c6 03 00 00       	push   $0x3c6
f010257e:	68 38 42 10 f0       	push   $0xf0104238
f0102583:	e8 03 db ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0102588:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010258e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102593:	74 19                	je     f01025ae <mem_init+0x15e7>
f0102595:	68 30 44 10 f0       	push   $0xf0104430
f010259a:	68 5e 42 10 f0       	push   $0xf010425e
f010259f:	68 c8 03 00 00       	push   $0x3c8
f01025a4:	68 38 42 10 f0       	push   $0xf0104238
f01025a9:	e8 dd da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01025ae:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01025b4:	83 ec 0c             	sub    $0xc,%esp
f01025b7:	53                   	push   %ebx
f01025b8:	e8 ff e7 ff ff       	call   f0100dbc <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01025bd:	c7 04 24 0c 42 10 f0 	movl   $0xf010420c,(%esp)
f01025c4:	e8 7d 00 00 00       	call   f0102646 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01025c9:	83 c4 10             	add    $0x10,%esp
f01025cc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01025cf:	5b                   	pop    %ebx
f01025d0:	5e                   	pop    %esi
f01025d1:	5f                   	pop    %edi
f01025d2:	5d                   	pop    %ebp
f01025d3:	c3                   	ret    

f01025d4 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01025d4:	55                   	push   %ebp
f01025d5:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01025d7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025da:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01025dd:	5d                   	pop    %ebp
f01025de:	c3                   	ret    

f01025df <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01025df:	55                   	push   %ebp
f01025e0:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01025e2:	ba 70 00 00 00       	mov    $0x70,%edx
f01025e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01025ea:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01025eb:	ba 71 00 00 00       	mov    $0x71,%edx
f01025f0:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01025f1:	0f b6 c0             	movzbl %al,%eax
}
f01025f4:	5d                   	pop    %ebp
f01025f5:	c3                   	ret    

f01025f6 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01025f6:	55                   	push   %ebp
f01025f7:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01025f9:	ba 70 00 00 00       	mov    $0x70,%edx
f01025fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0102601:	ee                   	out    %al,(%dx)
f0102602:	ba 71 00 00 00       	mov    $0x71,%edx
f0102607:	8b 45 0c             	mov    0xc(%ebp),%eax
f010260a:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010260b:	5d                   	pop    %ebp
f010260c:	c3                   	ret    

f010260d <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010260d:	55                   	push   %ebp
f010260e:	89 e5                	mov    %esp,%ebp
f0102610:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102613:	ff 75 08             	pushl  0x8(%ebp)
f0102616:	e8 0a e0 ff ff       	call   f0100625 <cputchar>
	*cnt++;
}
f010261b:	83 c4 10             	add    $0x10,%esp
f010261e:	c9                   	leave  
f010261f:	c3                   	ret    

f0102620 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102620:	55                   	push   %ebp
f0102621:	89 e5                	mov    %esp,%ebp
f0102623:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102626:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010262d:	ff 75 0c             	pushl  0xc(%ebp)
f0102630:	ff 75 08             	pushl  0x8(%ebp)
f0102633:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102636:	50                   	push   %eax
f0102637:	68 0d 26 10 f0       	push   $0xf010260d
f010263c:	e8 4d 04 00 00       	call   f0102a8e <vprintfmt>
	return cnt;
}
f0102641:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102644:	c9                   	leave  
f0102645:	c3                   	ret    

f0102646 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102646:	55                   	push   %ebp
f0102647:	89 e5                	mov    %esp,%ebp
f0102649:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010264c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010264f:	50                   	push   %eax
f0102650:	ff 75 08             	pushl  0x8(%ebp)
f0102653:	e8 c8 ff ff ff       	call   f0102620 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102658:	c9                   	leave  
f0102659:	c3                   	ret    

f010265a <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010265a:	55                   	push   %ebp
f010265b:	89 e5                	mov    %esp,%ebp
f010265d:	57                   	push   %edi
f010265e:	56                   	push   %esi
f010265f:	53                   	push   %ebx
f0102660:	83 ec 14             	sub    $0x14,%esp
f0102663:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102666:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102669:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010266c:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010266f:	8b 1a                	mov    (%edx),%ebx
f0102671:	8b 01                	mov    (%ecx),%eax
f0102673:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102676:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010267d:	eb 7f                	jmp    f01026fe <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010267f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102682:	01 d8                	add    %ebx,%eax
f0102684:	89 c6                	mov    %eax,%esi
f0102686:	c1 ee 1f             	shr    $0x1f,%esi
f0102689:	01 c6                	add    %eax,%esi
f010268b:	d1 fe                	sar    %esi
f010268d:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102690:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102693:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0102696:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102698:	eb 03                	jmp    f010269d <stab_binsearch+0x43>
			m--;
f010269a:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010269d:	39 c3                	cmp    %eax,%ebx
f010269f:	7f 0d                	jg     f01026ae <stab_binsearch+0x54>
f01026a1:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01026a5:	83 ea 0c             	sub    $0xc,%edx
f01026a8:	39 f9                	cmp    %edi,%ecx
f01026aa:	75 ee                	jne    f010269a <stab_binsearch+0x40>
f01026ac:	eb 05                	jmp    f01026b3 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01026ae:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01026b1:	eb 4b                	jmp    f01026fe <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01026b3:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01026b6:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01026b9:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01026bd:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01026c0:	76 11                	jbe    f01026d3 <stab_binsearch+0x79>
			*region_left = m;
f01026c2:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01026c5:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01026c7:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01026ca:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01026d1:	eb 2b                	jmp    f01026fe <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01026d3:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01026d6:	73 14                	jae    f01026ec <stab_binsearch+0x92>
			*region_right = m - 1;
f01026d8:	83 e8 01             	sub    $0x1,%eax
f01026db:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01026de:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01026e1:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01026e3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01026ea:	eb 12                	jmp    f01026fe <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01026ec:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01026ef:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01026f1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01026f5:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01026f7:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01026fe:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102701:	0f 8e 78 ff ff ff    	jle    f010267f <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102707:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010270b:	75 0f                	jne    f010271c <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010270d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102710:	8b 00                	mov    (%eax),%eax
f0102712:	83 e8 01             	sub    $0x1,%eax
f0102715:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102718:	89 06                	mov    %eax,(%esi)
f010271a:	eb 2c                	jmp    f0102748 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010271c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010271f:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102721:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102724:	8b 0e                	mov    (%esi),%ecx
f0102726:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102729:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010272c:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010272f:	eb 03                	jmp    f0102734 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102731:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102734:	39 c8                	cmp    %ecx,%eax
f0102736:	7e 0b                	jle    f0102743 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102738:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010273c:	83 ea 0c             	sub    $0xc,%edx
f010273f:	39 df                	cmp    %ebx,%edi
f0102741:	75 ee                	jne    f0102731 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102743:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102746:	89 06                	mov    %eax,(%esi)
	}
}
f0102748:	83 c4 14             	add    $0x14,%esp
f010274b:	5b                   	pop    %ebx
f010274c:	5e                   	pop    %esi
f010274d:	5f                   	pop    %edi
f010274e:	5d                   	pop    %ebp
f010274f:	c3                   	ret    

f0102750 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102750:	55                   	push   %ebp
f0102751:	89 e5                	mov    %esp,%ebp
f0102753:	57                   	push   %edi
f0102754:	56                   	push   %esi
f0102755:	53                   	push   %ebx
f0102756:	83 ec 2c             	sub    $0x2c,%esp
f0102759:	8b 7d 08             	mov    0x8(%ebp),%edi
f010275c:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010275f:	c7 06 34 45 10 f0    	movl   $0xf0104534,(%esi)
	info->eip_line = 0;
f0102765:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010276c:	c7 46 08 34 45 10 f0 	movl   $0xf0104534,0x8(%esi)
	info->eip_fn_namelen = 9;
f0102773:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010277a:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f010277d:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102784:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010278a:	76 11                	jbe    f010279d <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010278c:	b8 33 bc 10 f0       	mov    $0xf010bc33,%eax
f0102791:	3d cd 9e 10 f0       	cmp    $0xf0109ecd,%eax
f0102796:	77 19                	ja     f01027b1 <debuginfo_eip+0x61>
f0102798:	e9 a5 01 00 00       	jmp    f0102942 <debuginfo_eip+0x1f2>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f010279d:	83 ec 04             	sub    $0x4,%esp
f01027a0:	68 3e 45 10 f0       	push   $0xf010453e
f01027a5:	6a 7f                	push   $0x7f
f01027a7:	68 4b 45 10 f0       	push   $0xf010454b
f01027ac:	e8 da d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01027b1:	80 3d 32 bc 10 f0 00 	cmpb   $0x0,0xf010bc32
f01027b8:	0f 85 8b 01 00 00    	jne    f0102949 <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01027be:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01027c5:	b8 cc 9e 10 f0       	mov    $0xf0109ecc,%eax
f01027ca:	2d 90 47 10 f0       	sub    $0xf0104790,%eax
f01027cf:	c1 f8 02             	sar    $0x2,%eax
f01027d2:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01027d8:	83 e8 01             	sub    $0x1,%eax
f01027db:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01027de:	83 ec 08             	sub    $0x8,%esp
f01027e1:	57                   	push   %edi
f01027e2:	6a 64                	push   $0x64
f01027e4:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01027e7:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01027ea:	b8 90 47 10 f0       	mov    $0xf0104790,%eax
f01027ef:	e8 66 fe ff ff       	call   f010265a <stab_binsearch>
	if (lfile == 0)
f01027f4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027f7:	83 c4 10             	add    $0x10,%esp
f01027fa:	85 c0                	test   %eax,%eax
f01027fc:	0f 84 4e 01 00 00    	je     f0102950 <debuginfo_eip+0x200>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102802:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102805:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102808:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010280b:	83 ec 08             	sub    $0x8,%esp
f010280e:	57                   	push   %edi
f010280f:	6a 24                	push   $0x24
f0102811:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102814:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102817:	b8 90 47 10 f0       	mov    $0xf0104790,%eax
f010281c:	e8 39 fe ff ff       	call   f010265a <stab_binsearch>

	if (lfun <= rfun) {
f0102821:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102824:	83 c4 10             	add    $0x10,%esp
f0102827:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010282a:	7f 33                	jg     f010285f <debuginfo_eip+0x10f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010282c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010282f:	c1 e0 02             	shl    $0x2,%eax
f0102832:	8d 90 90 47 10 f0    	lea    -0xfefb870(%eax),%edx
f0102838:	8b 88 90 47 10 f0    	mov    -0xfefb870(%eax),%ecx
f010283e:	b8 33 bc 10 f0       	mov    $0xf010bc33,%eax
f0102843:	2d cd 9e 10 f0       	sub    $0xf0109ecd,%eax
f0102848:	39 c1                	cmp    %eax,%ecx
f010284a:	73 09                	jae    f0102855 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010284c:	81 c1 cd 9e 10 f0    	add    $0xf0109ecd,%ecx
f0102852:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102855:	8b 42 08             	mov    0x8(%edx),%eax
f0102858:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f010285b:	29 c7                	sub    %eax,%edi
f010285d:	eb 06                	jmp    f0102865 <debuginfo_eip+0x115>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010285f:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0102862:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102865:	83 ec 08             	sub    $0x8,%esp
f0102868:	6a 3a                	push   $0x3a
f010286a:	ff 76 08             	pushl  0x8(%esi)
f010286d:	e8 6c 08 00 00       	call   f01030de <strfind>
f0102872:	2b 46 08             	sub    0x8(%esi),%eax
f0102875:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
f0102878:	83 c4 08             	add    $0x8,%esp
f010287b:	2b 7e 10             	sub    0x10(%esi),%edi
f010287e:	57                   	push   %edi
f010287f:	6a 44                	push   $0x44
f0102881:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102884:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102887:	b8 90 47 10 f0       	mov    $0xf0104790,%eax
f010288c:	e8 c9 fd ff ff       	call   f010265a <stab_binsearch>
	if (lfun > rfun) 
f0102891:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102894:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102897:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f010289a:	83 c4 10             	add    $0x10,%esp
f010289d:	39 c8                	cmp    %ecx,%eax
f010289f:	0f 8f b2 00 00 00    	jg     f0102957 <debuginfo_eip+0x207>
       	  return -1;
        info->eip_line = stabs[lfun].n_desc;
f01028a5:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01028a8:	8d 04 85 90 47 10 f0 	lea    -0xfefb870(,%eax,4),%eax
f01028af:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01028b2:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f01028b6:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01028b9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01028bc:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01028bf:	8d 04 85 90 47 10 f0 	lea    -0xfefb870(,%eax,4),%eax
f01028c6:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01028c9:	eb 06                	jmp    f01028d1 <debuginfo_eip+0x181>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01028cb:	83 eb 01             	sub    $0x1,%ebx
f01028ce:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01028d1:	39 fb                	cmp    %edi,%ebx
f01028d3:	7c 39                	jl     f010290e <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f01028d5:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01028d9:	80 fa 84             	cmp    $0x84,%dl
f01028dc:	74 0b                	je     f01028e9 <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01028de:	80 fa 64             	cmp    $0x64,%dl
f01028e1:	75 e8                	jne    f01028cb <debuginfo_eip+0x17b>
f01028e3:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01028e7:	74 e2                	je     f01028cb <debuginfo_eip+0x17b>
f01028e9:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01028ec:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01028ef:	8b 14 85 90 47 10 f0 	mov    -0xfefb870(,%eax,4),%edx
f01028f6:	b8 33 bc 10 f0       	mov    $0xf010bc33,%eax
f01028fb:	2d cd 9e 10 f0       	sub    $0xf0109ecd,%eax
f0102900:	39 c2                	cmp    %eax,%edx
f0102902:	73 0d                	jae    f0102911 <debuginfo_eip+0x1c1>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102904:	81 c2 cd 9e 10 f0    	add    $0xf0109ecd,%edx
f010290a:	89 16                	mov    %edx,(%esi)
f010290c:	eb 03                	jmp    f0102911 <debuginfo_eip+0x1c1>
f010290e:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102911:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102916:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102919:	39 cf                	cmp    %ecx,%edi
f010291b:	7d 46                	jge    f0102963 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
f010291d:	89 f8                	mov    %edi,%eax
f010291f:	83 c0 01             	add    $0x1,%eax
f0102922:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0102925:	eb 07                	jmp    f010292e <debuginfo_eip+0x1de>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102927:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f010292b:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010292e:	39 c8                	cmp    %ecx,%eax
f0102930:	74 2c                	je     f010295e <debuginfo_eip+0x20e>
f0102932:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102935:	80 7a 04 a0          	cmpb   $0xa0,0x4(%edx)
f0102939:	74 ec                	je     f0102927 <debuginfo_eip+0x1d7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010293b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102940:	eb 21                	jmp    f0102963 <debuginfo_eip+0x213>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102942:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102947:	eb 1a                	jmp    f0102963 <debuginfo_eip+0x213>
f0102949:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010294e:	eb 13                	jmp    f0102963 <debuginfo_eip+0x213>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102950:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102955:	eb 0c                	jmp    f0102963 <debuginfo_eip+0x213>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
	if (lfun > rfun) 
       	  return -1;
f0102957:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010295c:	eb 05                	jmp    f0102963 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010295e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102963:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102966:	5b                   	pop    %ebx
f0102967:	5e                   	pop    %esi
f0102968:	5f                   	pop    %edi
f0102969:	5d                   	pop    %ebp
f010296a:	c3                   	ret    

f010296b <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010296b:	55                   	push   %ebp
f010296c:	89 e5                	mov    %esp,%ebp
f010296e:	57                   	push   %edi
f010296f:	56                   	push   %esi
f0102970:	53                   	push   %ebx
f0102971:	83 ec 1c             	sub    $0x1c,%esp
f0102974:	89 c7                	mov    %eax,%edi
f0102976:	89 d6                	mov    %edx,%esi
f0102978:	8b 45 08             	mov    0x8(%ebp),%eax
f010297b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010297e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102981:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102984:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102987:	bb 00 00 00 00       	mov    $0x0,%ebx
f010298c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010298f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102992:	39 d3                	cmp    %edx,%ebx
f0102994:	72 05                	jb     f010299b <printnum+0x30>
f0102996:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102999:	77 45                	ja     f01029e0 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010299b:	83 ec 0c             	sub    $0xc,%esp
f010299e:	ff 75 18             	pushl  0x18(%ebp)
f01029a1:	8b 45 14             	mov    0x14(%ebp),%eax
f01029a4:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01029a7:	53                   	push   %ebx
f01029a8:	ff 75 10             	pushl  0x10(%ebp)
f01029ab:	83 ec 08             	sub    $0x8,%esp
f01029ae:	ff 75 e4             	pushl  -0x1c(%ebp)
f01029b1:	ff 75 e0             	pushl  -0x20(%ebp)
f01029b4:	ff 75 dc             	pushl  -0x24(%ebp)
f01029b7:	ff 75 d8             	pushl  -0x28(%ebp)
f01029ba:	e8 41 09 00 00       	call   f0103300 <__udivdi3>
f01029bf:	83 c4 18             	add    $0x18,%esp
f01029c2:	52                   	push   %edx
f01029c3:	50                   	push   %eax
f01029c4:	89 f2                	mov    %esi,%edx
f01029c6:	89 f8                	mov    %edi,%eax
f01029c8:	e8 9e ff ff ff       	call   f010296b <printnum>
f01029cd:	83 c4 20             	add    $0x20,%esp
f01029d0:	eb 18                	jmp    f01029ea <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01029d2:	83 ec 08             	sub    $0x8,%esp
f01029d5:	56                   	push   %esi
f01029d6:	ff 75 18             	pushl  0x18(%ebp)
f01029d9:	ff d7                	call   *%edi
f01029db:	83 c4 10             	add    $0x10,%esp
f01029de:	eb 03                	jmp    f01029e3 <printnum+0x78>
f01029e0:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01029e3:	83 eb 01             	sub    $0x1,%ebx
f01029e6:	85 db                	test   %ebx,%ebx
f01029e8:	7f e8                	jg     f01029d2 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01029ea:	83 ec 08             	sub    $0x8,%esp
f01029ed:	56                   	push   %esi
f01029ee:	83 ec 04             	sub    $0x4,%esp
f01029f1:	ff 75 e4             	pushl  -0x1c(%ebp)
f01029f4:	ff 75 e0             	pushl  -0x20(%ebp)
f01029f7:	ff 75 dc             	pushl  -0x24(%ebp)
f01029fa:	ff 75 d8             	pushl  -0x28(%ebp)
f01029fd:	e8 2e 0a 00 00       	call   f0103430 <__umoddi3>
f0102a02:	83 c4 14             	add    $0x14,%esp
f0102a05:	0f be 80 59 45 10 f0 	movsbl -0xfefbaa7(%eax),%eax
f0102a0c:	50                   	push   %eax
f0102a0d:	ff d7                	call   *%edi
}
f0102a0f:	83 c4 10             	add    $0x10,%esp
f0102a12:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a15:	5b                   	pop    %ebx
f0102a16:	5e                   	pop    %esi
f0102a17:	5f                   	pop    %edi
f0102a18:	5d                   	pop    %ebp
f0102a19:	c3                   	ret    

f0102a1a <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102a1a:	55                   	push   %ebp
f0102a1b:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102a1d:	83 fa 01             	cmp    $0x1,%edx
f0102a20:	7e 0e                	jle    f0102a30 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102a22:	8b 10                	mov    (%eax),%edx
f0102a24:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102a27:	89 08                	mov    %ecx,(%eax)
f0102a29:	8b 02                	mov    (%edx),%eax
f0102a2b:	8b 52 04             	mov    0x4(%edx),%edx
f0102a2e:	eb 22                	jmp    f0102a52 <getuint+0x38>
	else if (lflag)
f0102a30:	85 d2                	test   %edx,%edx
f0102a32:	74 10                	je     f0102a44 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102a34:	8b 10                	mov    (%eax),%edx
f0102a36:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102a39:	89 08                	mov    %ecx,(%eax)
f0102a3b:	8b 02                	mov    (%edx),%eax
f0102a3d:	ba 00 00 00 00       	mov    $0x0,%edx
f0102a42:	eb 0e                	jmp    f0102a52 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102a44:	8b 10                	mov    (%eax),%edx
f0102a46:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102a49:	89 08                	mov    %ecx,(%eax)
f0102a4b:	8b 02                	mov    (%edx),%eax
f0102a4d:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102a52:	5d                   	pop    %ebp
f0102a53:	c3                   	ret    

f0102a54 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102a54:	55                   	push   %ebp
f0102a55:	89 e5                	mov    %esp,%ebp
f0102a57:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102a5a:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102a5e:	8b 10                	mov    (%eax),%edx
f0102a60:	3b 50 04             	cmp    0x4(%eax),%edx
f0102a63:	73 0a                	jae    f0102a6f <sprintputch+0x1b>
		*b->buf++ = ch;
f0102a65:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102a68:	89 08                	mov    %ecx,(%eax)
f0102a6a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a6d:	88 02                	mov    %al,(%edx)
}
f0102a6f:	5d                   	pop    %ebp
f0102a70:	c3                   	ret    

f0102a71 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102a71:	55                   	push   %ebp
f0102a72:	89 e5                	mov    %esp,%ebp
f0102a74:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102a77:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102a7a:	50                   	push   %eax
f0102a7b:	ff 75 10             	pushl  0x10(%ebp)
f0102a7e:	ff 75 0c             	pushl  0xc(%ebp)
f0102a81:	ff 75 08             	pushl  0x8(%ebp)
f0102a84:	e8 05 00 00 00       	call   f0102a8e <vprintfmt>
	va_end(ap);
}
f0102a89:	83 c4 10             	add    $0x10,%esp
f0102a8c:	c9                   	leave  
f0102a8d:	c3                   	ret    

f0102a8e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102a8e:	55                   	push   %ebp
f0102a8f:	89 e5                	mov    %esp,%ebp
f0102a91:	57                   	push   %edi
f0102a92:	56                   	push   %esi
f0102a93:	53                   	push   %ebx
f0102a94:	83 ec 2c             	sub    $0x2c,%esp
f0102a97:	8b 75 08             	mov    0x8(%ebp),%esi
f0102a9a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102a9d:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102aa0:	eb 12                	jmp    f0102ab4 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102aa2:	85 c0                	test   %eax,%eax
f0102aa4:	0f 84 89 03 00 00    	je     f0102e33 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102aaa:	83 ec 08             	sub    $0x8,%esp
f0102aad:	53                   	push   %ebx
f0102aae:	50                   	push   %eax
f0102aaf:	ff d6                	call   *%esi
f0102ab1:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102ab4:	83 c7 01             	add    $0x1,%edi
f0102ab7:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102abb:	83 f8 25             	cmp    $0x25,%eax
f0102abe:	75 e2                	jne    f0102aa2 <vprintfmt+0x14>
f0102ac0:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102ac4:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102acb:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102ad2:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102ad9:	ba 00 00 00 00       	mov    $0x0,%edx
f0102ade:	eb 07                	jmp    f0102ae7 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ae0:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102ae3:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ae7:	8d 47 01             	lea    0x1(%edi),%eax
f0102aea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102aed:	0f b6 07             	movzbl (%edi),%eax
f0102af0:	0f b6 c8             	movzbl %al,%ecx
f0102af3:	83 e8 23             	sub    $0x23,%eax
f0102af6:	3c 55                	cmp    $0x55,%al
f0102af8:	0f 87 1a 03 00 00    	ja     f0102e18 <vprintfmt+0x38a>
f0102afe:	0f b6 c0             	movzbl %al,%eax
f0102b01:	ff 24 85 00 46 10 f0 	jmp    *-0xfefba00(,%eax,4)
f0102b08:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102b0b:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102b0f:	eb d6                	jmp    f0102ae7 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b11:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b14:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b19:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102b1c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102b1f:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102b23:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102b26:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102b29:	83 fa 09             	cmp    $0x9,%edx
f0102b2c:	77 39                	ja     f0102b67 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102b2e:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102b31:	eb e9                	jmp    f0102b1c <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102b33:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b36:	8d 48 04             	lea    0x4(%eax),%ecx
f0102b39:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102b3c:	8b 00                	mov    (%eax),%eax
f0102b3e:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b41:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102b44:	eb 27                	jmp    f0102b6d <vprintfmt+0xdf>
f0102b46:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102b49:	85 c0                	test   %eax,%eax
f0102b4b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102b50:	0f 49 c8             	cmovns %eax,%ecx
f0102b53:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b56:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b59:	eb 8c                	jmp    f0102ae7 <vprintfmt+0x59>
f0102b5b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102b5e:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102b65:	eb 80                	jmp    f0102ae7 <vprintfmt+0x59>
f0102b67:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102b6a:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102b6d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102b71:	0f 89 70 ff ff ff    	jns    f0102ae7 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102b77:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102b7a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102b7d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b84:	e9 5e ff ff ff       	jmp    f0102ae7 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102b89:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b8c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102b8f:	e9 53 ff ff ff       	jmp    f0102ae7 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102b94:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b97:	8d 50 04             	lea    0x4(%eax),%edx
f0102b9a:	89 55 14             	mov    %edx,0x14(%ebp)
f0102b9d:	83 ec 08             	sub    $0x8,%esp
f0102ba0:	53                   	push   %ebx
f0102ba1:	ff 30                	pushl  (%eax)
f0102ba3:	ff d6                	call   *%esi
			break;
f0102ba5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ba8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102bab:	e9 04 ff ff ff       	jmp    f0102ab4 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102bb0:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bb3:	8d 50 04             	lea    0x4(%eax),%edx
f0102bb6:	89 55 14             	mov    %edx,0x14(%ebp)
f0102bb9:	8b 00                	mov    (%eax),%eax
f0102bbb:	99                   	cltd   
f0102bbc:	31 d0                	xor    %edx,%eax
f0102bbe:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102bc0:	83 f8 07             	cmp    $0x7,%eax
f0102bc3:	7f 0b                	jg     f0102bd0 <vprintfmt+0x142>
f0102bc5:	8b 14 85 60 47 10 f0 	mov    -0xfefb8a0(,%eax,4),%edx
f0102bcc:	85 d2                	test   %edx,%edx
f0102bce:	75 18                	jne    f0102be8 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102bd0:	50                   	push   %eax
f0102bd1:	68 71 45 10 f0       	push   $0xf0104571
f0102bd6:	53                   	push   %ebx
f0102bd7:	56                   	push   %esi
f0102bd8:	e8 94 fe ff ff       	call   f0102a71 <printfmt>
f0102bdd:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102be0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102be3:	e9 cc fe ff ff       	jmp    f0102ab4 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102be8:	52                   	push   %edx
f0102be9:	68 70 42 10 f0       	push   $0xf0104270
f0102bee:	53                   	push   %ebx
f0102bef:	56                   	push   %esi
f0102bf0:	e8 7c fe ff ff       	call   f0102a71 <printfmt>
f0102bf5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bf8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bfb:	e9 b4 fe ff ff       	jmp    f0102ab4 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102c00:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c03:	8d 50 04             	lea    0x4(%eax),%edx
f0102c06:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c09:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102c0b:	85 ff                	test   %edi,%edi
f0102c0d:	b8 6a 45 10 f0       	mov    $0xf010456a,%eax
f0102c12:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102c15:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c19:	0f 8e 94 00 00 00    	jle    f0102cb3 <vprintfmt+0x225>
f0102c1f:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102c23:	0f 84 98 00 00 00    	je     f0102cc1 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c29:	83 ec 08             	sub    $0x8,%esp
f0102c2c:	ff 75 d0             	pushl  -0x30(%ebp)
f0102c2f:	57                   	push   %edi
f0102c30:	e8 5f 03 00 00       	call   f0102f94 <strnlen>
f0102c35:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102c38:	29 c1                	sub    %eax,%ecx
f0102c3a:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102c3d:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102c40:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102c44:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c47:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102c4a:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c4c:	eb 0f                	jmp    f0102c5d <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102c4e:	83 ec 08             	sub    $0x8,%esp
f0102c51:	53                   	push   %ebx
f0102c52:	ff 75 e0             	pushl  -0x20(%ebp)
f0102c55:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c57:	83 ef 01             	sub    $0x1,%edi
f0102c5a:	83 c4 10             	add    $0x10,%esp
f0102c5d:	85 ff                	test   %edi,%edi
f0102c5f:	7f ed                	jg     f0102c4e <vprintfmt+0x1c0>
f0102c61:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c64:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102c67:	85 c9                	test   %ecx,%ecx
f0102c69:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c6e:	0f 49 c1             	cmovns %ecx,%eax
f0102c71:	29 c1                	sub    %eax,%ecx
f0102c73:	89 75 08             	mov    %esi,0x8(%ebp)
f0102c76:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102c79:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102c7c:	89 cb                	mov    %ecx,%ebx
f0102c7e:	eb 4d                	jmp    f0102ccd <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102c80:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102c84:	74 1b                	je     f0102ca1 <vprintfmt+0x213>
f0102c86:	0f be c0             	movsbl %al,%eax
f0102c89:	83 e8 20             	sub    $0x20,%eax
f0102c8c:	83 f8 5e             	cmp    $0x5e,%eax
f0102c8f:	76 10                	jbe    f0102ca1 <vprintfmt+0x213>
					putch('?', putdat);
f0102c91:	83 ec 08             	sub    $0x8,%esp
f0102c94:	ff 75 0c             	pushl  0xc(%ebp)
f0102c97:	6a 3f                	push   $0x3f
f0102c99:	ff 55 08             	call   *0x8(%ebp)
f0102c9c:	83 c4 10             	add    $0x10,%esp
f0102c9f:	eb 0d                	jmp    f0102cae <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102ca1:	83 ec 08             	sub    $0x8,%esp
f0102ca4:	ff 75 0c             	pushl  0xc(%ebp)
f0102ca7:	52                   	push   %edx
f0102ca8:	ff 55 08             	call   *0x8(%ebp)
f0102cab:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102cae:	83 eb 01             	sub    $0x1,%ebx
f0102cb1:	eb 1a                	jmp    f0102ccd <vprintfmt+0x23f>
f0102cb3:	89 75 08             	mov    %esi,0x8(%ebp)
f0102cb6:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102cb9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102cbc:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102cbf:	eb 0c                	jmp    f0102ccd <vprintfmt+0x23f>
f0102cc1:	89 75 08             	mov    %esi,0x8(%ebp)
f0102cc4:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102cc7:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102cca:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102ccd:	83 c7 01             	add    $0x1,%edi
f0102cd0:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102cd4:	0f be d0             	movsbl %al,%edx
f0102cd7:	85 d2                	test   %edx,%edx
f0102cd9:	74 23                	je     f0102cfe <vprintfmt+0x270>
f0102cdb:	85 f6                	test   %esi,%esi
f0102cdd:	78 a1                	js     f0102c80 <vprintfmt+0x1f2>
f0102cdf:	83 ee 01             	sub    $0x1,%esi
f0102ce2:	79 9c                	jns    f0102c80 <vprintfmt+0x1f2>
f0102ce4:	89 df                	mov    %ebx,%edi
f0102ce6:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ce9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102cec:	eb 18                	jmp    f0102d06 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102cee:	83 ec 08             	sub    $0x8,%esp
f0102cf1:	53                   	push   %ebx
f0102cf2:	6a 20                	push   $0x20
f0102cf4:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102cf6:	83 ef 01             	sub    $0x1,%edi
f0102cf9:	83 c4 10             	add    $0x10,%esp
f0102cfc:	eb 08                	jmp    f0102d06 <vprintfmt+0x278>
f0102cfe:	89 df                	mov    %ebx,%edi
f0102d00:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d03:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d06:	85 ff                	test   %edi,%edi
f0102d08:	7f e4                	jg     f0102cee <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d0a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d0d:	e9 a2 fd ff ff       	jmp    f0102ab4 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102d12:	83 fa 01             	cmp    $0x1,%edx
f0102d15:	7e 16                	jle    f0102d2d <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102d17:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d1a:	8d 50 08             	lea    0x8(%eax),%edx
f0102d1d:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d20:	8b 50 04             	mov    0x4(%eax),%edx
f0102d23:	8b 00                	mov    (%eax),%eax
f0102d25:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d28:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102d2b:	eb 32                	jmp    f0102d5f <vprintfmt+0x2d1>
	else if (lflag)
f0102d2d:	85 d2                	test   %edx,%edx
f0102d2f:	74 18                	je     f0102d49 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102d31:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d34:	8d 50 04             	lea    0x4(%eax),%edx
f0102d37:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d3a:	8b 00                	mov    (%eax),%eax
f0102d3c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d3f:	89 c1                	mov    %eax,%ecx
f0102d41:	c1 f9 1f             	sar    $0x1f,%ecx
f0102d44:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102d47:	eb 16                	jmp    f0102d5f <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102d49:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d4c:	8d 50 04             	lea    0x4(%eax),%edx
f0102d4f:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d52:	8b 00                	mov    (%eax),%eax
f0102d54:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d57:	89 c1                	mov    %eax,%ecx
f0102d59:	c1 f9 1f             	sar    $0x1f,%ecx
f0102d5c:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102d5f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102d62:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102d65:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102d6a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102d6e:	79 74                	jns    f0102de4 <vprintfmt+0x356>
				putch('-', putdat);
f0102d70:	83 ec 08             	sub    $0x8,%esp
f0102d73:	53                   	push   %ebx
f0102d74:	6a 2d                	push   $0x2d
f0102d76:	ff d6                	call   *%esi
				num = -(long long) num;
f0102d78:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102d7b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102d7e:	f7 d8                	neg    %eax
f0102d80:	83 d2 00             	adc    $0x0,%edx
f0102d83:	f7 da                	neg    %edx
f0102d85:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102d88:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102d8d:	eb 55                	jmp    f0102de4 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102d8f:	8d 45 14             	lea    0x14(%ebp),%eax
f0102d92:	e8 83 fc ff ff       	call   f0102a1a <getuint>
			base = 10;
f0102d97:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102d9c:	eb 46                	jmp    f0102de4 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0102d9e:	8d 45 14             	lea    0x14(%ebp),%eax
f0102da1:	e8 74 fc ff ff       	call   f0102a1a <getuint>
			base = 8;
f0102da6:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102dab:	eb 37                	jmp    f0102de4 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0102dad:	83 ec 08             	sub    $0x8,%esp
f0102db0:	53                   	push   %ebx
f0102db1:	6a 30                	push   $0x30
f0102db3:	ff d6                	call   *%esi
			putch('x', putdat);
f0102db5:	83 c4 08             	add    $0x8,%esp
f0102db8:	53                   	push   %ebx
f0102db9:	6a 78                	push   $0x78
f0102dbb:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102dbd:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dc0:	8d 50 04             	lea    0x4(%eax),%edx
f0102dc3:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102dc6:	8b 00                	mov    (%eax),%eax
f0102dc8:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102dcd:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102dd0:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102dd5:	eb 0d                	jmp    f0102de4 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102dd7:	8d 45 14             	lea    0x14(%ebp),%eax
f0102dda:	e8 3b fc ff ff       	call   f0102a1a <getuint>
			base = 16;
f0102ddf:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102de4:	83 ec 0c             	sub    $0xc,%esp
f0102de7:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102deb:	57                   	push   %edi
f0102dec:	ff 75 e0             	pushl  -0x20(%ebp)
f0102def:	51                   	push   %ecx
f0102df0:	52                   	push   %edx
f0102df1:	50                   	push   %eax
f0102df2:	89 da                	mov    %ebx,%edx
f0102df4:	89 f0                	mov    %esi,%eax
f0102df6:	e8 70 fb ff ff       	call   f010296b <printnum>
			break;
f0102dfb:	83 c4 20             	add    $0x20,%esp
f0102dfe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e01:	e9 ae fc ff ff       	jmp    f0102ab4 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102e06:	83 ec 08             	sub    $0x8,%esp
f0102e09:	53                   	push   %ebx
f0102e0a:	51                   	push   %ecx
f0102e0b:	ff d6                	call   *%esi
			break;
f0102e0d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e10:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102e13:	e9 9c fc ff ff       	jmp    f0102ab4 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102e18:	83 ec 08             	sub    $0x8,%esp
f0102e1b:	53                   	push   %ebx
f0102e1c:	6a 25                	push   $0x25
f0102e1e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102e20:	83 c4 10             	add    $0x10,%esp
f0102e23:	eb 03                	jmp    f0102e28 <vprintfmt+0x39a>
f0102e25:	83 ef 01             	sub    $0x1,%edi
f0102e28:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102e2c:	75 f7                	jne    f0102e25 <vprintfmt+0x397>
f0102e2e:	e9 81 fc ff ff       	jmp    f0102ab4 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102e33:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e36:	5b                   	pop    %ebx
f0102e37:	5e                   	pop    %esi
f0102e38:	5f                   	pop    %edi
f0102e39:	5d                   	pop    %ebp
f0102e3a:	c3                   	ret    

f0102e3b <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102e3b:	55                   	push   %ebp
f0102e3c:	89 e5                	mov    %esp,%ebp
f0102e3e:	83 ec 18             	sub    $0x18,%esp
f0102e41:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e44:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102e47:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102e4a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102e4e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102e51:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102e58:	85 c0                	test   %eax,%eax
f0102e5a:	74 26                	je     f0102e82 <vsnprintf+0x47>
f0102e5c:	85 d2                	test   %edx,%edx
f0102e5e:	7e 22                	jle    f0102e82 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102e60:	ff 75 14             	pushl  0x14(%ebp)
f0102e63:	ff 75 10             	pushl  0x10(%ebp)
f0102e66:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102e69:	50                   	push   %eax
f0102e6a:	68 54 2a 10 f0       	push   $0xf0102a54
f0102e6f:	e8 1a fc ff ff       	call   f0102a8e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102e74:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102e77:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102e7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102e7d:	83 c4 10             	add    $0x10,%esp
f0102e80:	eb 05                	jmp    f0102e87 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102e82:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102e87:	c9                   	leave  
f0102e88:	c3                   	ret    

f0102e89 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102e89:	55                   	push   %ebp
f0102e8a:	89 e5                	mov    %esp,%ebp
f0102e8c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102e8f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102e92:	50                   	push   %eax
f0102e93:	ff 75 10             	pushl  0x10(%ebp)
f0102e96:	ff 75 0c             	pushl  0xc(%ebp)
f0102e99:	ff 75 08             	pushl  0x8(%ebp)
f0102e9c:	e8 9a ff ff ff       	call   f0102e3b <vsnprintf>
	va_end(ap);

	return rc;
}
f0102ea1:	c9                   	leave  
f0102ea2:	c3                   	ret    

f0102ea3 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102ea3:	55                   	push   %ebp
f0102ea4:	89 e5                	mov    %esp,%ebp
f0102ea6:	57                   	push   %edi
f0102ea7:	56                   	push   %esi
f0102ea8:	53                   	push   %ebx
f0102ea9:	83 ec 0c             	sub    $0xc,%esp
f0102eac:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102eaf:	85 c0                	test   %eax,%eax
f0102eb1:	74 11                	je     f0102ec4 <readline+0x21>
		cprintf("%s", prompt);
f0102eb3:	83 ec 08             	sub    $0x8,%esp
f0102eb6:	50                   	push   %eax
f0102eb7:	68 70 42 10 f0       	push   $0xf0104270
f0102ebc:	e8 85 f7 ff ff       	call   f0102646 <cprintf>
f0102ec1:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102ec4:	83 ec 0c             	sub    $0xc,%esp
f0102ec7:	6a 00                	push   $0x0
f0102ec9:	e8 78 d7 ff ff       	call   f0100646 <iscons>
f0102ece:	89 c7                	mov    %eax,%edi
f0102ed0:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102ed3:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102ed8:	e8 58 d7 ff ff       	call   f0100635 <getchar>
f0102edd:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102edf:	85 c0                	test   %eax,%eax
f0102ee1:	79 18                	jns    f0102efb <readline+0x58>
			cprintf("read error: %e\n", c);
f0102ee3:	83 ec 08             	sub    $0x8,%esp
f0102ee6:	50                   	push   %eax
f0102ee7:	68 80 47 10 f0       	push   $0xf0104780
f0102eec:	e8 55 f7 ff ff       	call   f0102646 <cprintf>
			return NULL;
f0102ef1:	83 c4 10             	add    $0x10,%esp
f0102ef4:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ef9:	eb 79                	jmp    f0102f74 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102efb:	83 f8 08             	cmp    $0x8,%eax
f0102efe:	0f 94 c2             	sete   %dl
f0102f01:	83 f8 7f             	cmp    $0x7f,%eax
f0102f04:	0f 94 c0             	sete   %al
f0102f07:	08 c2                	or     %al,%dl
f0102f09:	74 1a                	je     f0102f25 <readline+0x82>
f0102f0b:	85 f6                	test   %esi,%esi
f0102f0d:	7e 16                	jle    f0102f25 <readline+0x82>
			if (echoing)
f0102f0f:	85 ff                	test   %edi,%edi
f0102f11:	74 0d                	je     f0102f20 <readline+0x7d>
				cputchar('\b');
f0102f13:	83 ec 0c             	sub    $0xc,%esp
f0102f16:	6a 08                	push   $0x8
f0102f18:	e8 08 d7 ff ff       	call   f0100625 <cputchar>
f0102f1d:	83 c4 10             	add    $0x10,%esp
			i--;
f0102f20:	83 ee 01             	sub    $0x1,%esi
f0102f23:	eb b3                	jmp    f0102ed8 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102f25:	83 fb 1f             	cmp    $0x1f,%ebx
f0102f28:	7e 23                	jle    f0102f4d <readline+0xaa>
f0102f2a:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102f30:	7f 1b                	jg     f0102f4d <readline+0xaa>
			if (echoing)
f0102f32:	85 ff                	test   %edi,%edi
f0102f34:	74 0c                	je     f0102f42 <readline+0x9f>
				cputchar(c);
f0102f36:	83 ec 0c             	sub    $0xc,%esp
f0102f39:	53                   	push   %ebx
f0102f3a:	e8 e6 d6 ff ff       	call   f0100625 <cputchar>
f0102f3f:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0102f42:	88 9e 60 65 11 f0    	mov    %bl,-0xfee9aa0(%esi)
f0102f48:	8d 76 01             	lea    0x1(%esi),%esi
f0102f4b:	eb 8b                	jmp    f0102ed8 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0102f4d:	83 fb 0a             	cmp    $0xa,%ebx
f0102f50:	74 05                	je     f0102f57 <readline+0xb4>
f0102f52:	83 fb 0d             	cmp    $0xd,%ebx
f0102f55:	75 81                	jne    f0102ed8 <readline+0x35>
			if (echoing)
f0102f57:	85 ff                	test   %edi,%edi
f0102f59:	74 0d                	je     f0102f68 <readline+0xc5>
				cputchar('\n');
f0102f5b:	83 ec 0c             	sub    $0xc,%esp
f0102f5e:	6a 0a                	push   $0xa
f0102f60:	e8 c0 d6 ff ff       	call   f0100625 <cputchar>
f0102f65:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0102f68:	c6 86 60 65 11 f0 00 	movb   $0x0,-0xfee9aa0(%esi)
			return buf;
f0102f6f:	b8 60 65 11 f0       	mov    $0xf0116560,%eax
		}
	}
}
f0102f74:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f77:	5b                   	pop    %ebx
f0102f78:	5e                   	pop    %esi
f0102f79:	5f                   	pop    %edi
f0102f7a:	5d                   	pop    %ebp
f0102f7b:	c3                   	ret    

f0102f7c <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0102f7c:	55                   	push   %ebp
f0102f7d:	89 e5                	mov    %esp,%ebp
f0102f7f:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102f82:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f87:	eb 03                	jmp    f0102f8c <strlen+0x10>
		n++;
f0102f89:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0102f8c:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0102f90:	75 f7                	jne    f0102f89 <strlen+0xd>
		n++;
	return n;
}
f0102f92:	5d                   	pop    %ebp
f0102f93:	c3                   	ret    

f0102f94 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102f94:	55                   	push   %ebp
f0102f95:	89 e5                	mov    %esp,%ebp
f0102f97:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102f9a:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102f9d:	ba 00 00 00 00       	mov    $0x0,%edx
f0102fa2:	eb 03                	jmp    f0102fa7 <strnlen+0x13>
		n++;
f0102fa4:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102fa7:	39 c2                	cmp    %eax,%edx
f0102fa9:	74 08                	je     f0102fb3 <strnlen+0x1f>
f0102fab:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0102faf:	75 f3                	jne    f0102fa4 <strnlen+0x10>
f0102fb1:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0102fb3:	5d                   	pop    %ebp
f0102fb4:	c3                   	ret    

f0102fb5 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102fb5:	55                   	push   %ebp
f0102fb6:	89 e5                	mov    %esp,%ebp
f0102fb8:	53                   	push   %ebx
f0102fb9:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fbc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0102fbf:	89 c2                	mov    %eax,%edx
f0102fc1:	83 c2 01             	add    $0x1,%edx
f0102fc4:	83 c1 01             	add    $0x1,%ecx
f0102fc7:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0102fcb:	88 5a ff             	mov    %bl,-0x1(%edx)
f0102fce:	84 db                	test   %bl,%bl
f0102fd0:	75 ef                	jne    f0102fc1 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0102fd2:	5b                   	pop    %ebx
f0102fd3:	5d                   	pop    %ebp
f0102fd4:	c3                   	ret    

f0102fd5 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0102fd5:	55                   	push   %ebp
f0102fd6:	89 e5                	mov    %esp,%ebp
f0102fd8:	53                   	push   %ebx
f0102fd9:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0102fdc:	53                   	push   %ebx
f0102fdd:	e8 9a ff ff ff       	call   f0102f7c <strlen>
f0102fe2:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0102fe5:	ff 75 0c             	pushl  0xc(%ebp)
f0102fe8:	01 d8                	add    %ebx,%eax
f0102fea:	50                   	push   %eax
f0102feb:	e8 c5 ff ff ff       	call   f0102fb5 <strcpy>
	return dst;
}
f0102ff0:	89 d8                	mov    %ebx,%eax
f0102ff2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102ff5:	c9                   	leave  
f0102ff6:	c3                   	ret    

f0102ff7 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0102ff7:	55                   	push   %ebp
f0102ff8:	89 e5                	mov    %esp,%ebp
f0102ffa:	56                   	push   %esi
f0102ffb:	53                   	push   %ebx
f0102ffc:	8b 75 08             	mov    0x8(%ebp),%esi
f0102fff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103002:	89 f3                	mov    %esi,%ebx
f0103004:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103007:	89 f2                	mov    %esi,%edx
f0103009:	eb 0f                	jmp    f010301a <strncpy+0x23>
		*dst++ = *src;
f010300b:	83 c2 01             	add    $0x1,%edx
f010300e:	0f b6 01             	movzbl (%ecx),%eax
f0103011:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103014:	80 39 01             	cmpb   $0x1,(%ecx)
f0103017:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010301a:	39 da                	cmp    %ebx,%edx
f010301c:	75 ed                	jne    f010300b <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010301e:	89 f0                	mov    %esi,%eax
f0103020:	5b                   	pop    %ebx
f0103021:	5e                   	pop    %esi
f0103022:	5d                   	pop    %ebp
f0103023:	c3                   	ret    

f0103024 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103024:	55                   	push   %ebp
f0103025:	89 e5                	mov    %esp,%ebp
f0103027:	56                   	push   %esi
f0103028:	53                   	push   %ebx
f0103029:	8b 75 08             	mov    0x8(%ebp),%esi
f010302c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010302f:	8b 55 10             	mov    0x10(%ebp),%edx
f0103032:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103034:	85 d2                	test   %edx,%edx
f0103036:	74 21                	je     f0103059 <strlcpy+0x35>
f0103038:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010303c:	89 f2                	mov    %esi,%edx
f010303e:	eb 09                	jmp    f0103049 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103040:	83 c2 01             	add    $0x1,%edx
f0103043:	83 c1 01             	add    $0x1,%ecx
f0103046:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103049:	39 c2                	cmp    %eax,%edx
f010304b:	74 09                	je     f0103056 <strlcpy+0x32>
f010304d:	0f b6 19             	movzbl (%ecx),%ebx
f0103050:	84 db                	test   %bl,%bl
f0103052:	75 ec                	jne    f0103040 <strlcpy+0x1c>
f0103054:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103056:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103059:	29 f0                	sub    %esi,%eax
}
f010305b:	5b                   	pop    %ebx
f010305c:	5e                   	pop    %esi
f010305d:	5d                   	pop    %ebp
f010305e:	c3                   	ret    

f010305f <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010305f:	55                   	push   %ebp
f0103060:	89 e5                	mov    %esp,%ebp
f0103062:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103065:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103068:	eb 06                	jmp    f0103070 <strcmp+0x11>
		p++, q++;
f010306a:	83 c1 01             	add    $0x1,%ecx
f010306d:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103070:	0f b6 01             	movzbl (%ecx),%eax
f0103073:	84 c0                	test   %al,%al
f0103075:	74 04                	je     f010307b <strcmp+0x1c>
f0103077:	3a 02                	cmp    (%edx),%al
f0103079:	74 ef                	je     f010306a <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010307b:	0f b6 c0             	movzbl %al,%eax
f010307e:	0f b6 12             	movzbl (%edx),%edx
f0103081:	29 d0                	sub    %edx,%eax
}
f0103083:	5d                   	pop    %ebp
f0103084:	c3                   	ret    

f0103085 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103085:	55                   	push   %ebp
f0103086:	89 e5                	mov    %esp,%ebp
f0103088:	53                   	push   %ebx
f0103089:	8b 45 08             	mov    0x8(%ebp),%eax
f010308c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010308f:	89 c3                	mov    %eax,%ebx
f0103091:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103094:	eb 06                	jmp    f010309c <strncmp+0x17>
		n--, p++, q++;
f0103096:	83 c0 01             	add    $0x1,%eax
f0103099:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010309c:	39 d8                	cmp    %ebx,%eax
f010309e:	74 15                	je     f01030b5 <strncmp+0x30>
f01030a0:	0f b6 08             	movzbl (%eax),%ecx
f01030a3:	84 c9                	test   %cl,%cl
f01030a5:	74 04                	je     f01030ab <strncmp+0x26>
f01030a7:	3a 0a                	cmp    (%edx),%cl
f01030a9:	74 eb                	je     f0103096 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01030ab:	0f b6 00             	movzbl (%eax),%eax
f01030ae:	0f b6 12             	movzbl (%edx),%edx
f01030b1:	29 d0                	sub    %edx,%eax
f01030b3:	eb 05                	jmp    f01030ba <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01030b5:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01030ba:	5b                   	pop    %ebx
f01030bb:	5d                   	pop    %ebp
f01030bc:	c3                   	ret    

f01030bd <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01030bd:	55                   	push   %ebp
f01030be:	89 e5                	mov    %esp,%ebp
f01030c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01030c3:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01030c7:	eb 07                	jmp    f01030d0 <strchr+0x13>
		if (*s == c)
f01030c9:	38 ca                	cmp    %cl,%dl
f01030cb:	74 0f                	je     f01030dc <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01030cd:	83 c0 01             	add    $0x1,%eax
f01030d0:	0f b6 10             	movzbl (%eax),%edx
f01030d3:	84 d2                	test   %dl,%dl
f01030d5:	75 f2                	jne    f01030c9 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01030d7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01030dc:	5d                   	pop    %ebp
f01030dd:	c3                   	ret    

f01030de <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01030de:	55                   	push   %ebp
f01030df:	89 e5                	mov    %esp,%ebp
f01030e1:	8b 45 08             	mov    0x8(%ebp),%eax
f01030e4:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01030e8:	eb 03                	jmp    f01030ed <strfind+0xf>
f01030ea:	83 c0 01             	add    $0x1,%eax
f01030ed:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01030f0:	38 ca                	cmp    %cl,%dl
f01030f2:	74 04                	je     f01030f8 <strfind+0x1a>
f01030f4:	84 d2                	test   %dl,%dl
f01030f6:	75 f2                	jne    f01030ea <strfind+0xc>
			break;
	return (char *) s;
}
f01030f8:	5d                   	pop    %ebp
f01030f9:	c3                   	ret    

f01030fa <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01030fa:	55                   	push   %ebp
f01030fb:	89 e5                	mov    %esp,%ebp
f01030fd:	57                   	push   %edi
f01030fe:	56                   	push   %esi
f01030ff:	53                   	push   %ebx
f0103100:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103103:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103106:	85 c9                	test   %ecx,%ecx
f0103108:	74 36                	je     f0103140 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010310a:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103110:	75 28                	jne    f010313a <memset+0x40>
f0103112:	f6 c1 03             	test   $0x3,%cl
f0103115:	75 23                	jne    f010313a <memset+0x40>
		c &= 0xFF;
f0103117:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010311b:	89 d3                	mov    %edx,%ebx
f010311d:	c1 e3 08             	shl    $0x8,%ebx
f0103120:	89 d6                	mov    %edx,%esi
f0103122:	c1 e6 18             	shl    $0x18,%esi
f0103125:	89 d0                	mov    %edx,%eax
f0103127:	c1 e0 10             	shl    $0x10,%eax
f010312a:	09 f0                	or     %esi,%eax
f010312c:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010312e:	89 d8                	mov    %ebx,%eax
f0103130:	09 d0                	or     %edx,%eax
f0103132:	c1 e9 02             	shr    $0x2,%ecx
f0103135:	fc                   	cld    
f0103136:	f3 ab                	rep stos %eax,%es:(%edi)
f0103138:	eb 06                	jmp    f0103140 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010313a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010313d:	fc                   	cld    
f010313e:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103140:	89 f8                	mov    %edi,%eax
f0103142:	5b                   	pop    %ebx
f0103143:	5e                   	pop    %esi
f0103144:	5f                   	pop    %edi
f0103145:	5d                   	pop    %ebp
f0103146:	c3                   	ret    

f0103147 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103147:	55                   	push   %ebp
f0103148:	89 e5                	mov    %esp,%ebp
f010314a:	57                   	push   %edi
f010314b:	56                   	push   %esi
f010314c:	8b 45 08             	mov    0x8(%ebp),%eax
f010314f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103152:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103155:	39 c6                	cmp    %eax,%esi
f0103157:	73 35                	jae    f010318e <memmove+0x47>
f0103159:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010315c:	39 d0                	cmp    %edx,%eax
f010315e:	73 2e                	jae    f010318e <memmove+0x47>
		s += n;
		d += n;
f0103160:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103163:	89 d6                	mov    %edx,%esi
f0103165:	09 fe                	or     %edi,%esi
f0103167:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010316d:	75 13                	jne    f0103182 <memmove+0x3b>
f010316f:	f6 c1 03             	test   $0x3,%cl
f0103172:	75 0e                	jne    f0103182 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103174:	83 ef 04             	sub    $0x4,%edi
f0103177:	8d 72 fc             	lea    -0x4(%edx),%esi
f010317a:	c1 e9 02             	shr    $0x2,%ecx
f010317d:	fd                   	std    
f010317e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103180:	eb 09                	jmp    f010318b <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103182:	83 ef 01             	sub    $0x1,%edi
f0103185:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103188:	fd                   	std    
f0103189:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010318b:	fc                   	cld    
f010318c:	eb 1d                	jmp    f01031ab <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010318e:	89 f2                	mov    %esi,%edx
f0103190:	09 c2                	or     %eax,%edx
f0103192:	f6 c2 03             	test   $0x3,%dl
f0103195:	75 0f                	jne    f01031a6 <memmove+0x5f>
f0103197:	f6 c1 03             	test   $0x3,%cl
f010319a:	75 0a                	jne    f01031a6 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010319c:	c1 e9 02             	shr    $0x2,%ecx
f010319f:	89 c7                	mov    %eax,%edi
f01031a1:	fc                   	cld    
f01031a2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01031a4:	eb 05                	jmp    f01031ab <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01031a6:	89 c7                	mov    %eax,%edi
f01031a8:	fc                   	cld    
f01031a9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01031ab:	5e                   	pop    %esi
f01031ac:	5f                   	pop    %edi
f01031ad:	5d                   	pop    %ebp
f01031ae:	c3                   	ret    

f01031af <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01031af:	55                   	push   %ebp
f01031b0:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01031b2:	ff 75 10             	pushl  0x10(%ebp)
f01031b5:	ff 75 0c             	pushl  0xc(%ebp)
f01031b8:	ff 75 08             	pushl  0x8(%ebp)
f01031bb:	e8 87 ff ff ff       	call   f0103147 <memmove>
}
f01031c0:	c9                   	leave  
f01031c1:	c3                   	ret    

f01031c2 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01031c2:	55                   	push   %ebp
f01031c3:	89 e5                	mov    %esp,%ebp
f01031c5:	56                   	push   %esi
f01031c6:	53                   	push   %ebx
f01031c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01031ca:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031cd:	89 c6                	mov    %eax,%esi
f01031cf:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01031d2:	eb 1a                	jmp    f01031ee <memcmp+0x2c>
		if (*s1 != *s2)
f01031d4:	0f b6 08             	movzbl (%eax),%ecx
f01031d7:	0f b6 1a             	movzbl (%edx),%ebx
f01031da:	38 d9                	cmp    %bl,%cl
f01031dc:	74 0a                	je     f01031e8 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01031de:	0f b6 c1             	movzbl %cl,%eax
f01031e1:	0f b6 db             	movzbl %bl,%ebx
f01031e4:	29 d8                	sub    %ebx,%eax
f01031e6:	eb 0f                	jmp    f01031f7 <memcmp+0x35>
		s1++, s2++;
f01031e8:	83 c0 01             	add    $0x1,%eax
f01031eb:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01031ee:	39 f0                	cmp    %esi,%eax
f01031f0:	75 e2                	jne    f01031d4 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01031f2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01031f7:	5b                   	pop    %ebx
f01031f8:	5e                   	pop    %esi
f01031f9:	5d                   	pop    %ebp
f01031fa:	c3                   	ret    

f01031fb <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01031fb:	55                   	push   %ebp
f01031fc:	89 e5                	mov    %esp,%ebp
f01031fe:	53                   	push   %ebx
f01031ff:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103202:	89 c1                	mov    %eax,%ecx
f0103204:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103207:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010320b:	eb 0a                	jmp    f0103217 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010320d:	0f b6 10             	movzbl (%eax),%edx
f0103210:	39 da                	cmp    %ebx,%edx
f0103212:	74 07                	je     f010321b <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103214:	83 c0 01             	add    $0x1,%eax
f0103217:	39 c8                	cmp    %ecx,%eax
f0103219:	72 f2                	jb     f010320d <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010321b:	5b                   	pop    %ebx
f010321c:	5d                   	pop    %ebp
f010321d:	c3                   	ret    

f010321e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010321e:	55                   	push   %ebp
f010321f:	89 e5                	mov    %esp,%ebp
f0103221:	57                   	push   %edi
f0103222:	56                   	push   %esi
f0103223:	53                   	push   %ebx
f0103224:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103227:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010322a:	eb 03                	jmp    f010322f <strtol+0x11>
		s++;
f010322c:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010322f:	0f b6 01             	movzbl (%ecx),%eax
f0103232:	3c 20                	cmp    $0x20,%al
f0103234:	74 f6                	je     f010322c <strtol+0xe>
f0103236:	3c 09                	cmp    $0x9,%al
f0103238:	74 f2                	je     f010322c <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010323a:	3c 2b                	cmp    $0x2b,%al
f010323c:	75 0a                	jne    f0103248 <strtol+0x2a>
		s++;
f010323e:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103241:	bf 00 00 00 00       	mov    $0x0,%edi
f0103246:	eb 11                	jmp    f0103259 <strtol+0x3b>
f0103248:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010324d:	3c 2d                	cmp    $0x2d,%al
f010324f:	75 08                	jne    f0103259 <strtol+0x3b>
		s++, neg = 1;
f0103251:	83 c1 01             	add    $0x1,%ecx
f0103254:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103259:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010325f:	75 15                	jne    f0103276 <strtol+0x58>
f0103261:	80 39 30             	cmpb   $0x30,(%ecx)
f0103264:	75 10                	jne    f0103276 <strtol+0x58>
f0103266:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010326a:	75 7c                	jne    f01032e8 <strtol+0xca>
		s += 2, base = 16;
f010326c:	83 c1 02             	add    $0x2,%ecx
f010326f:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103274:	eb 16                	jmp    f010328c <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103276:	85 db                	test   %ebx,%ebx
f0103278:	75 12                	jne    f010328c <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010327a:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010327f:	80 39 30             	cmpb   $0x30,(%ecx)
f0103282:	75 08                	jne    f010328c <strtol+0x6e>
		s++, base = 8;
f0103284:	83 c1 01             	add    $0x1,%ecx
f0103287:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010328c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103291:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103294:	0f b6 11             	movzbl (%ecx),%edx
f0103297:	8d 72 d0             	lea    -0x30(%edx),%esi
f010329a:	89 f3                	mov    %esi,%ebx
f010329c:	80 fb 09             	cmp    $0x9,%bl
f010329f:	77 08                	ja     f01032a9 <strtol+0x8b>
			dig = *s - '0';
f01032a1:	0f be d2             	movsbl %dl,%edx
f01032a4:	83 ea 30             	sub    $0x30,%edx
f01032a7:	eb 22                	jmp    f01032cb <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01032a9:	8d 72 9f             	lea    -0x61(%edx),%esi
f01032ac:	89 f3                	mov    %esi,%ebx
f01032ae:	80 fb 19             	cmp    $0x19,%bl
f01032b1:	77 08                	ja     f01032bb <strtol+0x9d>
			dig = *s - 'a' + 10;
f01032b3:	0f be d2             	movsbl %dl,%edx
f01032b6:	83 ea 57             	sub    $0x57,%edx
f01032b9:	eb 10                	jmp    f01032cb <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01032bb:	8d 72 bf             	lea    -0x41(%edx),%esi
f01032be:	89 f3                	mov    %esi,%ebx
f01032c0:	80 fb 19             	cmp    $0x19,%bl
f01032c3:	77 16                	ja     f01032db <strtol+0xbd>
			dig = *s - 'A' + 10;
f01032c5:	0f be d2             	movsbl %dl,%edx
f01032c8:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01032cb:	3b 55 10             	cmp    0x10(%ebp),%edx
f01032ce:	7d 0b                	jge    f01032db <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01032d0:	83 c1 01             	add    $0x1,%ecx
f01032d3:	0f af 45 10          	imul   0x10(%ebp),%eax
f01032d7:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01032d9:	eb b9                	jmp    f0103294 <strtol+0x76>

	if (endptr)
f01032db:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01032df:	74 0d                	je     f01032ee <strtol+0xd0>
		*endptr = (char *) s;
f01032e1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01032e4:	89 0e                	mov    %ecx,(%esi)
f01032e6:	eb 06                	jmp    f01032ee <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01032e8:	85 db                	test   %ebx,%ebx
f01032ea:	74 98                	je     f0103284 <strtol+0x66>
f01032ec:	eb 9e                	jmp    f010328c <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01032ee:	89 c2                	mov    %eax,%edx
f01032f0:	f7 da                	neg    %edx
f01032f2:	85 ff                	test   %edi,%edi
f01032f4:	0f 45 c2             	cmovne %edx,%eax
}
f01032f7:	5b                   	pop    %ebx
f01032f8:	5e                   	pop    %esi
f01032f9:	5f                   	pop    %edi
f01032fa:	5d                   	pop    %ebp
f01032fb:	c3                   	ret    
f01032fc:	66 90                	xchg   %ax,%ax
f01032fe:	66 90                	xchg   %ax,%ax

f0103300 <__udivdi3>:
f0103300:	55                   	push   %ebp
f0103301:	57                   	push   %edi
f0103302:	56                   	push   %esi
f0103303:	53                   	push   %ebx
f0103304:	83 ec 1c             	sub    $0x1c,%esp
f0103307:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010330b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010330f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103313:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103317:	85 f6                	test   %esi,%esi
f0103319:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010331d:	89 ca                	mov    %ecx,%edx
f010331f:	89 f8                	mov    %edi,%eax
f0103321:	75 3d                	jne    f0103360 <__udivdi3+0x60>
f0103323:	39 cf                	cmp    %ecx,%edi
f0103325:	0f 87 c5 00 00 00    	ja     f01033f0 <__udivdi3+0xf0>
f010332b:	85 ff                	test   %edi,%edi
f010332d:	89 fd                	mov    %edi,%ebp
f010332f:	75 0b                	jne    f010333c <__udivdi3+0x3c>
f0103331:	b8 01 00 00 00       	mov    $0x1,%eax
f0103336:	31 d2                	xor    %edx,%edx
f0103338:	f7 f7                	div    %edi
f010333a:	89 c5                	mov    %eax,%ebp
f010333c:	89 c8                	mov    %ecx,%eax
f010333e:	31 d2                	xor    %edx,%edx
f0103340:	f7 f5                	div    %ebp
f0103342:	89 c1                	mov    %eax,%ecx
f0103344:	89 d8                	mov    %ebx,%eax
f0103346:	89 cf                	mov    %ecx,%edi
f0103348:	f7 f5                	div    %ebp
f010334a:	89 c3                	mov    %eax,%ebx
f010334c:	89 d8                	mov    %ebx,%eax
f010334e:	89 fa                	mov    %edi,%edx
f0103350:	83 c4 1c             	add    $0x1c,%esp
f0103353:	5b                   	pop    %ebx
f0103354:	5e                   	pop    %esi
f0103355:	5f                   	pop    %edi
f0103356:	5d                   	pop    %ebp
f0103357:	c3                   	ret    
f0103358:	90                   	nop
f0103359:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103360:	39 ce                	cmp    %ecx,%esi
f0103362:	77 74                	ja     f01033d8 <__udivdi3+0xd8>
f0103364:	0f bd fe             	bsr    %esi,%edi
f0103367:	83 f7 1f             	xor    $0x1f,%edi
f010336a:	0f 84 98 00 00 00    	je     f0103408 <__udivdi3+0x108>
f0103370:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103375:	89 f9                	mov    %edi,%ecx
f0103377:	89 c5                	mov    %eax,%ebp
f0103379:	29 fb                	sub    %edi,%ebx
f010337b:	d3 e6                	shl    %cl,%esi
f010337d:	89 d9                	mov    %ebx,%ecx
f010337f:	d3 ed                	shr    %cl,%ebp
f0103381:	89 f9                	mov    %edi,%ecx
f0103383:	d3 e0                	shl    %cl,%eax
f0103385:	09 ee                	or     %ebp,%esi
f0103387:	89 d9                	mov    %ebx,%ecx
f0103389:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010338d:	89 d5                	mov    %edx,%ebp
f010338f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103393:	d3 ed                	shr    %cl,%ebp
f0103395:	89 f9                	mov    %edi,%ecx
f0103397:	d3 e2                	shl    %cl,%edx
f0103399:	89 d9                	mov    %ebx,%ecx
f010339b:	d3 e8                	shr    %cl,%eax
f010339d:	09 c2                	or     %eax,%edx
f010339f:	89 d0                	mov    %edx,%eax
f01033a1:	89 ea                	mov    %ebp,%edx
f01033a3:	f7 f6                	div    %esi
f01033a5:	89 d5                	mov    %edx,%ebp
f01033a7:	89 c3                	mov    %eax,%ebx
f01033a9:	f7 64 24 0c          	mull   0xc(%esp)
f01033ad:	39 d5                	cmp    %edx,%ebp
f01033af:	72 10                	jb     f01033c1 <__udivdi3+0xc1>
f01033b1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01033b5:	89 f9                	mov    %edi,%ecx
f01033b7:	d3 e6                	shl    %cl,%esi
f01033b9:	39 c6                	cmp    %eax,%esi
f01033bb:	73 07                	jae    f01033c4 <__udivdi3+0xc4>
f01033bd:	39 d5                	cmp    %edx,%ebp
f01033bf:	75 03                	jne    f01033c4 <__udivdi3+0xc4>
f01033c1:	83 eb 01             	sub    $0x1,%ebx
f01033c4:	31 ff                	xor    %edi,%edi
f01033c6:	89 d8                	mov    %ebx,%eax
f01033c8:	89 fa                	mov    %edi,%edx
f01033ca:	83 c4 1c             	add    $0x1c,%esp
f01033cd:	5b                   	pop    %ebx
f01033ce:	5e                   	pop    %esi
f01033cf:	5f                   	pop    %edi
f01033d0:	5d                   	pop    %ebp
f01033d1:	c3                   	ret    
f01033d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01033d8:	31 ff                	xor    %edi,%edi
f01033da:	31 db                	xor    %ebx,%ebx
f01033dc:	89 d8                	mov    %ebx,%eax
f01033de:	89 fa                	mov    %edi,%edx
f01033e0:	83 c4 1c             	add    $0x1c,%esp
f01033e3:	5b                   	pop    %ebx
f01033e4:	5e                   	pop    %esi
f01033e5:	5f                   	pop    %edi
f01033e6:	5d                   	pop    %ebp
f01033e7:	c3                   	ret    
f01033e8:	90                   	nop
f01033e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01033f0:	89 d8                	mov    %ebx,%eax
f01033f2:	f7 f7                	div    %edi
f01033f4:	31 ff                	xor    %edi,%edi
f01033f6:	89 c3                	mov    %eax,%ebx
f01033f8:	89 d8                	mov    %ebx,%eax
f01033fa:	89 fa                	mov    %edi,%edx
f01033fc:	83 c4 1c             	add    $0x1c,%esp
f01033ff:	5b                   	pop    %ebx
f0103400:	5e                   	pop    %esi
f0103401:	5f                   	pop    %edi
f0103402:	5d                   	pop    %ebp
f0103403:	c3                   	ret    
f0103404:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103408:	39 ce                	cmp    %ecx,%esi
f010340a:	72 0c                	jb     f0103418 <__udivdi3+0x118>
f010340c:	31 db                	xor    %ebx,%ebx
f010340e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103412:	0f 87 34 ff ff ff    	ja     f010334c <__udivdi3+0x4c>
f0103418:	bb 01 00 00 00       	mov    $0x1,%ebx
f010341d:	e9 2a ff ff ff       	jmp    f010334c <__udivdi3+0x4c>
f0103422:	66 90                	xchg   %ax,%ax
f0103424:	66 90                	xchg   %ax,%ax
f0103426:	66 90                	xchg   %ax,%ax
f0103428:	66 90                	xchg   %ax,%ax
f010342a:	66 90                	xchg   %ax,%ax
f010342c:	66 90                	xchg   %ax,%ax
f010342e:	66 90                	xchg   %ax,%ax

f0103430 <__umoddi3>:
f0103430:	55                   	push   %ebp
f0103431:	57                   	push   %edi
f0103432:	56                   	push   %esi
f0103433:	53                   	push   %ebx
f0103434:	83 ec 1c             	sub    $0x1c,%esp
f0103437:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010343b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010343f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103443:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103447:	85 d2                	test   %edx,%edx
f0103449:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010344d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103451:	89 f3                	mov    %esi,%ebx
f0103453:	89 3c 24             	mov    %edi,(%esp)
f0103456:	89 74 24 04          	mov    %esi,0x4(%esp)
f010345a:	75 1c                	jne    f0103478 <__umoddi3+0x48>
f010345c:	39 f7                	cmp    %esi,%edi
f010345e:	76 50                	jbe    f01034b0 <__umoddi3+0x80>
f0103460:	89 c8                	mov    %ecx,%eax
f0103462:	89 f2                	mov    %esi,%edx
f0103464:	f7 f7                	div    %edi
f0103466:	89 d0                	mov    %edx,%eax
f0103468:	31 d2                	xor    %edx,%edx
f010346a:	83 c4 1c             	add    $0x1c,%esp
f010346d:	5b                   	pop    %ebx
f010346e:	5e                   	pop    %esi
f010346f:	5f                   	pop    %edi
f0103470:	5d                   	pop    %ebp
f0103471:	c3                   	ret    
f0103472:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103478:	39 f2                	cmp    %esi,%edx
f010347a:	89 d0                	mov    %edx,%eax
f010347c:	77 52                	ja     f01034d0 <__umoddi3+0xa0>
f010347e:	0f bd ea             	bsr    %edx,%ebp
f0103481:	83 f5 1f             	xor    $0x1f,%ebp
f0103484:	75 5a                	jne    f01034e0 <__umoddi3+0xb0>
f0103486:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010348a:	0f 82 e0 00 00 00    	jb     f0103570 <__umoddi3+0x140>
f0103490:	39 0c 24             	cmp    %ecx,(%esp)
f0103493:	0f 86 d7 00 00 00    	jbe    f0103570 <__umoddi3+0x140>
f0103499:	8b 44 24 08          	mov    0x8(%esp),%eax
f010349d:	8b 54 24 04          	mov    0x4(%esp),%edx
f01034a1:	83 c4 1c             	add    $0x1c,%esp
f01034a4:	5b                   	pop    %ebx
f01034a5:	5e                   	pop    %esi
f01034a6:	5f                   	pop    %edi
f01034a7:	5d                   	pop    %ebp
f01034a8:	c3                   	ret    
f01034a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034b0:	85 ff                	test   %edi,%edi
f01034b2:	89 fd                	mov    %edi,%ebp
f01034b4:	75 0b                	jne    f01034c1 <__umoddi3+0x91>
f01034b6:	b8 01 00 00 00       	mov    $0x1,%eax
f01034bb:	31 d2                	xor    %edx,%edx
f01034bd:	f7 f7                	div    %edi
f01034bf:	89 c5                	mov    %eax,%ebp
f01034c1:	89 f0                	mov    %esi,%eax
f01034c3:	31 d2                	xor    %edx,%edx
f01034c5:	f7 f5                	div    %ebp
f01034c7:	89 c8                	mov    %ecx,%eax
f01034c9:	f7 f5                	div    %ebp
f01034cb:	89 d0                	mov    %edx,%eax
f01034cd:	eb 99                	jmp    f0103468 <__umoddi3+0x38>
f01034cf:	90                   	nop
f01034d0:	89 c8                	mov    %ecx,%eax
f01034d2:	89 f2                	mov    %esi,%edx
f01034d4:	83 c4 1c             	add    $0x1c,%esp
f01034d7:	5b                   	pop    %ebx
f01034d8:	5e                   	pop    %esi
f01034d9:	5f                   	pop    %edi
f01034da:	5d                   	pop    %ebp
f01034db:	c3                   	ret    
f01034dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01034e0:	8b 34 24             	mov    (%esp),%esi
f01034e3:	bf 20 00 00 00       	mov    $0x20,%edi
f01034e8:	89 e9                	mov    %ebp,%ecx
f01034ea:	29 ef                	sub    %ebp,%edi
f01034ec:	d3 e0                	shl    %cl,%eax
f01034ee:	89 f9                	mov    %edi,%ecx
f01034f0:	89 f2                	mov    %esi,%edx
f01034f2:	d3 ea                	shr    %cl,%edx
f01034f4:	89 e9                	mov    %ebp,%ecx
f01034f6:	09 c2                	or     %eax,%edx
f01034f8:	89 d8                	mov    %ebx,%eax
f01034fa:	89 14 24             	mov    %edx,(%esp)
f01034fd:	89 f2                	mov    %esi,%edx
f01034ff:	d3 e2                	shl    %cl,%edx
f0103501:	89 f9                	mov    %edi,%ecx
f0103503:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103507:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010350b:	d3 e8                	shr    %cl,%eax
f010350d:	89 e9                	mov    %ebp,%ecx
f010350f:	89 c6                	mov    %eax,%esi
f0103511:	d3 e3                	shl    %cl,%ebx
f0103513:	89 f9                	mov    %edi,%ecx
f0103515:	89 d0                	mov    %edx,%eax
f0103517:	d3 e8                	shr    %cl,%eax
f0103519:	89 e9                	mov    %ebp,%ecx
f010351b:	09 d8                	or     %ebx,%eax
f010351d:	89 d3                	mov    %edx,%ebx
f010351f:	89 f2                	mov    %esi,%edx
f0103521:	f7 34 24             	divl   (%esp)
f0103524:	89 d6                	mov    %edx,%esi
f0103526:	d3 e3                	shl    %cl,%ebx
f0103528:	f7 64 24 04          	mull   0x4(%esp)
f010352c:	39 d6                	cmp    %edx,%esi
f010352e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103532:	89 d1                	mov    %edx,%ecx
f0103534:	89 c3                	mov    %eax,%ebx
f0103536:	72 08                	jb     f0103540 <__umoddi3+0x110>
f0103538:	75 11                	jne    f010354b <__umoddi3+0x11b>
f010353a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010353e:	73 0b                	jae    f010354b <__umoddi3+0x11b>
f0103540:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103544:	1b 14 24             	sbb    (%esp),%edx
f0103547:	89 d1                	mov    %edx,%ecx
f0103549:	89 c3                	mov    %eax,%ebx
f010354b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010354f:	29 da                	sub    %ebx,%edx
f0103551:	19 ce                	sbb    %ecx,%esi
f0103553:	89 f9                	mov    %edi,%ecx
f0103555:	89 f0                	mov    %esi,%eax
f0103557:	d3 e0                	shl    %cl,%eax
f0103559:	89 e9                	mov    %ebp,%ecx
f010355b:	d3 ea                	shr    %cl,%edx
f010355d:	89 e9                	mov    %ebp,%ecx
f010355f:	d3 ee                	shr    %cl,%esi
f0103561:	09 d0                	or     %edx,%eax
f0103563:	89 f2                	mov    %esi,%edx
f0103565:	83 c4 1c             	add    $0x1c,%esp
f0103568:	5b                   	pop    %ebx
f0103569:	5e                   	pop    %esi
f010356a:	5f                   	pop    %edi
f010356b:	5d                   	pop    %ebp
f010356c:	c3                   	ret    
f010356d:	8d 76 00             	lea    0x0(%esi),%esi
f0103570:	29 f9                	sub    %edi,%ecx
f0103572:	19 d6                	sbb    %edx,%esi
f0103574:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103578:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010357c:	e9 18 ff ff ff       	jmp    f0103499 <__umoddi3+0x69>

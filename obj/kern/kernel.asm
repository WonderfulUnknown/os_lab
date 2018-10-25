
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
f0100058:	e8 87 1f 00 00       	call   f0101fe4 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 bb 04 00 00       	call   f010051d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 80 24 10 f0       	push   $0xf0102480
f010006f:	e8 bc 14 00 00       	call   f0101530 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 8e 0d 00 00       	call   f0100e07 <mem_init>
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
f01000b0:	68 9b 24 10 f0       	push   $0xf010249b
f01000b5:	e8 76 14 00 00       	call   f0101530 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 46 14 00 00       	call   f010150a <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 89 27 10 f0 	movl   $0xf0102789,(%esp)
f01000cb:	e8 60 14 00 00       	call   f0101530 <cprintf>
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
f01000f2:	68 b3 24 10 f0       	push   $0xf01024b3
f01000f7:	e8 34 14 00 00       	call   f0101530 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 02 14 00 00       	call   f010150a <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 89 27 10 f0 	movl   $0xf0102789,(%esp)
f010010f:	e8 1c 14 00 00       	call   f0101530 <cprintf>
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
f01001c6:	0f b6 82 20 26 10 f0 	movzbl -0xfefd9e0(%edx),%eax
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
f0100202:	0f b6 82 20 26 10 f0 	movzbl -0xfefd9e0(%edx),%eax
f0100209:	0b 05 00 43 11 f0    	or     0xf0114300,%eax
f010020f:	0f b6 8a 20 25 10 f0 	movzbl -0xfefdae0(%edx),%ecx
f0100216:	31 c8                	xor    %ecx,%eax
f0100218:	a3 00 43 11 f0       	mov    %eax,0xf0114300

	c = charcode[shift & (CTL | SHIFT)][data];
f010021d:	89 c1                	mov    %eax,%ecx
f010021f:	83 e1 03             	and    $0x3,%ecx
f0100222:	8b 0c 8d 00 25 10 f0 	mov    -0xfefdb00(,%ecx,4),%ecx
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
f0100260:	68 cd 24 10 f0       	push   $0xf01024cd
f0100265:	e8 c6 12 00 00       	call   f0101530 <cprintf>
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
f0100441:	e8 eb 1b 00 00       	call   f0102031 <memmove>
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
f0100610:	68 d9 24 10 f0       	push   $0xf01024d9
f0100615:	e8 16 0f 00 00       	call   f0101530 <cprintf>
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
f0100656:	68 20 27 10 f0       	push   $0xf0102720
f010065b:	68 3e 27 10 f0       	push   $0xf010273e
f0100660:	68 43 27 10 f0       	push   $0xf0102743
f0100665:	e8 c6 0e 00 00       	call   f0101530 <cprintf>
f010066a:	83 c4 0c             	add    $0xc,%esp
f010066d:	68 d8 27 10 f0       	push   $0xf01027d8
f0100672:	68 4c 27 10 f0       	push   $0xf010274c
f0100677:	68 43 27 10 f0       	push   $0xf0102743
f010067c:	e8 af 0e 00 00       	call   f0101530 <cprintf>
f0100681:	83 c4 0c             	add    $0xc,%esp
f0100684:	68 00 28 10 f0       	push   $0xf0102800
f0100689:	68 55 27 10 f0       	push   $0xf0102755
f010068e:	68 43 27 10 f0       	push   $0xf0102743
f0100693:	e8 98 0e 00 00       	call   f0101530 <cprintf>
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
f01006a5:	68 5f 27 10 f0       	push   $0xf010275f
f01006aa:	e8 81 0e 00 00       	call   f0101530 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006af:	83 c4 08             	add    $0x8,%esp
f01006b2:	68 0c 00 10 00       	push   $0x10000c
f01006b7:	68 28 28 10 f0       	push   $0xf0102828
f01006bc:	e8 6f 0e 00 00       	call   f0101530 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006c1:	83 c4 0c             	add    $0xc,%esp
f01006c4:	68 0c 00 10 00       	push   $0x10000c
f01006c9:	68 0c 00 10 f0       	push   $0xf010000c
f01006ce:	68 50 28 10 f0       	push   $0xf0102850
f01006d3:	e8 58 0e 00 00       	call   f0101530 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d8:	83 c4 0c             	add    $0xc,%esp
f01006db:	68 71 24 10 00       	push   $0x102471
f01006e0:	68 71 24 10 f0       	push   $0xf0102471
f01006e5:	68 74 28 10 f0       	push   $0xf0102874
f01006ea:	e8 41 0e 00 00       	call   f0101530 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ef:	83 c4 0c             	add    $0xc,%esp
f01006f2:	68 00 43 11 00       	push   $0x114300
f01006f7:	68 00 43 11 f0       	push   $0xf0114300
f01006fc:	68 98 28 10 f0       	push   $0xf0102898
f0100701:	e8 2a 0e 00 00       	call   f0101530 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100706:	83 c4 0c             	add    $0xc,%esp
f0100709:	68 70 49 11 00       	push   $0x114970
f010070e:	68 70 49 11 f0       	push   $0xf0114970
f0100713:	68 bc 28 10 f0       	push   $0xf01028bc
f0100718:	e8 13 0e 00 00       	call   f0101530 <cprintf>
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
f010073e:	68 e0 28 10 f0       	push   $0xf01028e0
f0100743:	e8 e8 0d 00 00       	call   f0101530 <cprintf>
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
f010075a:	68 78 27 10 f0       	push   $0xf0102778
f010075f:	e8 cc 0d 00 00       	call   f0101530 <cprintf>
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
f0100780:	68 0c 29 10 f0       	push   $0xf010290c
f0100785:	e8 a6 0d 00 00       	call   f0101530 <cprintf>
	debuginfo_eip((uintptr_t)eip,&info);
f010078a:	83 c4 18             	add    $0x18,%esp
f010078d:	57                   	push   %edi
f010078e:	56                   	push   %esi
f010078f:	e8 a6 0e 00 00       	call   f010163a <debuginfo_eip>
	cprintf("%s:%d", info.eip_file, info.eip_line);
f0100794:	83 c4 0c             	add    $0xc,%esp
f0100797:	ff 75 d4             	pushl  -0x2c(%ebp)
f010079a:	ff 75 d0             	pushl  -0x30(%ebp)
f010079d:	68 8b 27 10 f0       	push   $0xf010278b
f01007a2:	e8 89 0d 00 00       	call   f0101530 <cprintf>
        cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name,info.eip_fn_addr);
f01007a7:	ff 75 e0             	pushl  -0x20(%ebp)
f01007aa:	ff 75 d8             	pushl  -0x28(%ebp)
f01007ad:	ff 75 dc             	pushl  -0x24(%ebp)
f01007b0:	68 91 27 10 f0       	push   $0xf0102791
f01007b5:	e8 76 0d 00 00       	call   f0101530 <cprintf>
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
f01007d9:	68 44 29 10 f0       	push   $0xf0102944
f01007de:	e8 4d 0d 00 00       	call   f0101530 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007e3:	c7 04 24 68 29 10 f0 	movl   $0xf0102968,(%esp)
f01007ea:	e8 41 0d 00 00       	call   f0101530 <cprintf>
f01007ef:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007f2:	83 ec 0c             	sub    $0xc,%esp
f01007f5:	68 9c 27 10 f0       	push   $0xf010279c
f01007fa:	e8 8e 15 00 00       	call   f0101d8d <readline>
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
f010082e:	68 a0 27 10 f0       	push   $0xf01027a0
f0100833:	e8 6f 17 00 00       	call   f0101fa7 <strchr>
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
f010084e:	68 a5 27 10 f0       	push   $0xf01027a5
f0100853:	e8 d8 0c 00 00       	call   f0101530 <cprintf>
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
f0100877:	68 a0 27 10 f0       	push   $0xf01027a0
f010087c:	e8 26 17 00 00       	call   f0101fa7 <strchr>
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
f01008a5:	ff 34 85 a0 29 10 f0 	pushl  -0xfefd660(,%eax,4)
f01008ac:	ff 75 a8             	pushl  -0x58(%ebp)
f01008af:	e8 95 16 00 00       	call   f0101f49 <strcmp>
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
f01008c9:	ff 14 85 a8 29 10 f0 	call   *-0xfefd658(,%eax,4)


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
f01008ea:	68 c2 27 10 f0       	push   $0xf01027c2
f01008ef:	e8 3c 0c 00 00       	call   f0101530 <cprintf>
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
f0100963:	68 c4 29 10 f0       	push   $0xf01029c4
f0100968:	68 c0 02 00 00       	push   $0x2c0
f010096d:	68 7c 2b 10 f0       	push   $0xf0102b7c
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
f01009bb:	68 e8 29 10 f0       	push   $0xf01029e8
f01009c0:	68 03 02 00 00       	push   $0x203
f01009c5:	68 7c 2b 10 f0       	push   $0xf0102b7c
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
f0100a4a:	68 c4 29 10 f0       	push   $0xf01029c4
f0100a4f:	6a 52                	push   $0x52
f0100a51:	68 88 2b 10 f0       	push   $0xf0102b88
f0100a56:	e8 30 f6 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a5b:	83 ec 04             	sub    $0x4,%esp
f0100a5e:	68 80 00 00 00       	push   $0x80
f0100a63:	68 97 00 00 00       	push   $0x97
f0100a68:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a6d:	50                   	push   %eax
f0100a6e:	e8 71 15 00 00       	call   f0101fe4 <memset>
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
f0100ab4:	68 96 2b 10 f0       	push   $0xf0102b96
f0100ab9:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100abe:	68 1d 02 00 00       	push   $0x21d
f0100ac3:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100ac8:	e8 be f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100acd:	39 fa                	cmp    %edi,%edx
f0100acf:	72 19                	jb     f0100aea <check_page_free_list+0x148>
f0100ad1:	68 b7 2b 10 f0       	push   $0xf0102bb7
f0100ad6:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100adb:	68 1e 02 00 00       	push   $0x21e
f0100ae0:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100ae5:	e8 a1 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aea:	89 d0                	mov    %edx,%eax
f0100aec:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100aef:	a8 07                	test   $0x7,%al
f0100af1:	74 19                	je     f0100b0c <check_page_free_list+0x16a>
f0100af3:	68 0c 2a 10 f0       	push   $0xf0102a0c
f0100af8:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100afd:	68 1f 02 00 00       	push   $0x21f
f0100b02:	68 7c 2b 10 f0       	push   $0xf0102b7c
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
f0100b16:	68 cb 2b 10 f0       	push   $0xf0102bcb
f0100b1b:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100b20:	68 22 02 00 00       	push   $0x222
f0100b25:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100b2a:	e8 5c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b2f:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b34:	75 19                	jne    f0100b4f <check_page_free_list+0x1ad>
f0100b36:	68 dc 2b 10 f0       	push   $0xf0102bdc
f0100b3b:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100b40:	68 23 02 00 00       	push   $0x223
f0100b45:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100b4a:	e8 3c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b4f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b54:	75 19                	jne    f0100b6f <check_page_free_list+0x1cd>
f0100b56:	68 40 2a 10 f0       	push   $0xf0102a40
f0100b5b:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100b60:	68 24 02 00 00       	push   $0x224
f0100b65:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100b6a:	e8 1c f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b6f:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b74:	75 19                	jne    f0100b8f <check_page_free_list+0x1ed>
f0100b76:	68 f5 2b 10 f0       	push   $0xf0102bf5
f0100b7b:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100b80:	68 25 02 00 00       	push   $0x225
f0100b85:	68 7c 2b 10 f0       	push   $0xf0102b7c
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
f0100ba1:	68 c4 29 10 f0       	push   $0xf01029c4
f0100ba6:	6a 52                	push   $0x52
f0100ba8:	68 88 2b 10 f0       	push   $0xf0102b88
f0100bad:	e8 d9 f4 ff ff       	call   f010008b <_panic>
f0100bb2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bb7:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bba:	76 1e                	jbe    f0100bda <check_page_free_list+0x238>
f0100bbc:	68 64 2a 10 f0       	push   $0xf0102a64
f0100bc1:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100bc6:	68 26 02 00 00       	push   $0x226
f0100bcb:	68 7c 2b 10 f0       	push   $0xf0102b7c
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
f0100bef:	68 0f 2c 10 f0       	push   $0xf0102c0f
f0100bf4:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100bf9:	68 2e 02 00 00       	push   $0x22e
f0100bfe:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100c03:	e8 83 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c08:	85 db                	test   %ebx,%ebx
f0100c0a:	7f 42                	jg     f0100c4e <check_page_free_list+0x2ac>
f0100c0c:	68 21 2c 10 f0       	push   $0xf0102c21
f0100c11:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100c16:	68 2f 02 00 00       	push   $0x22f
f0100c1b:	68 7c 2b 10 f0       	push   $0xf0102b7c
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
f0100d5d:	68 32 2c 10 f0       	push   $0xf0102c32
f0100d62:	e8 c9 07 00 00       	call   f0101530 <cprintf>
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
f0100d8c:	68 c4 29 10 f0       	push   $0xf01029c4
f0100d91:	6a 52                	push   $0x52
f0100d93:	68 88 2b 10 f0       	push   $0xf0102b88
f0100d98:	e8 ee f2 ff ff       	call   f010008b <_panic>
			memset(page2kva(Page),'\0',PGSIZE);
f0100d9d:	83 ec 04             	sub    $0x4,%esp
f0100da0:	68 00 10 00 00       	push   $0x1000
f0100da5:	6a 00                	push   $0x0
f0100da7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dac:	50                   	push   %eax
f0100dad:	e8 32 12 00 00       	call   f0101fe4 <memset>
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
f0100dbf:	83 ec 08             	sub    $0x8,%esp
f0100dc2:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.

	//if(!pp->pp_ref){
	if(pp->pp_link != 0  || pp->pp_ref != 0){
f0100dc5:	83 38 00             	cmpl   $0x0,(%eax)
f0100dc8:	75 07                	jne    f0100dd1 <page_free+0x15>
f0100dca:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100dcf:	74 17                	je     f0100de8 <page_free+0x2c>
		panic("can't free the page");
f0100dd1:	83 ec 04             	sub    $0x4,%esp
f0100dd4:	68 3f 2c 10 f0       	push   $0xf0102c3f
f0100dd9:	68 59 01 00 00       	push   $0x159
f0100dde:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100de3:	e8 a3 f2 ff ff       	call   f010008b <_panic>
		return;
	}
	//	cprinf("can't free the page");
	//pp->pp_link = page_free_list->pp_link;	
	pp->pp_link = page_free_list;
f0100de8:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
f0100dee:	89 10                	mov    %edx,(%eax)
	//page_free_list->pp_link = pp;
	// page_free_list = &pp;
	page_free_list = pp;
f0100df0:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
	//pp->pp_ref = 0;
	cprintf("page_free\r\n");
f0100df5:	83 ec 0c             	sub    $0xc,%esp
f0100df8:	68 53 2c 10 f0       	push   $0xf0102c53
f0100dfd:	e8 2e 07 00 00       	call   f0101530 <cprintf>
}
f0100e02:	83 c4 10             	add    $0x10,%esp
f0100e05:	c9                   	leave  
f0100e06:	c3                   	ret    

f0100e07 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100e07:	55                   	push   %ebp
f0100e08:	89 e5                	mov    %esp,%ebp
f0100e0a:	57                   	push   %edi
f0100e0b:	56                   	push   %esi
f0100e0c:	53                   	push   %ebx
f0100e0d:	83 ec 28             	sub    $0x28,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100e10:	6a 15                	push   $0x15
f0100e12:	e8 b2 06 00 00       	call   f01014c9 <mc146818_read>
f0100e17:	89 c3                	mov    %eax,%ebx
f0100e19:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0100e20:	e8 a4 06 00 00       	call   f01014c9 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100e25:	c1 e0 08             	shl    $0x8,%eax
f0100e28:	09 d8                	or     %ebx,%eax
f0100e2a:	c1 e0 0a             	shl    $0xa,%eax
f0100e2d:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100e33:	85 c0                	test   %eax,%eax
f0100e35:	0f 48 c2             	cmovs  %edx,%eax
f0100e38:	c1 f8 0c             	sar    $0xc,%eax
f0100e3b:	a3 40 45 11 f0       	mov    %eax,0xf0114540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100e40:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0100e47:	e8 7d 06 00 00       	call   f01014c9 <mc146818_read>
f0100e4c:	89 c3                	mov    %eax,%ebx
f0100e4e:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0100e55:	e8 6f 06 00 00       	call   f01014c9 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0100e5a:	c1 e0 08             	shl    $0x8,%eax
f0100e5d:	09 d8                	or     %ebx,%eax
f0100e5f:	c1 e0 0a             	shl    $0xa,%eax
f0100e62:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100e68:	83 c4 10             	add    $0x10,%esp
f0100e6b:	85 c0                	test   %eax,%eax
f0100e6d:	0f 48 c2             	cmovs  %edx,%eax
f0100e70:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0100e73:	85 c0                	test   %eax,%eax
f0100e75:	74 0e                	je     f0100e85 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0100e77:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0100e7d:	89 15 64 49 11 f0    	mov    %edx,0xf0114964
f0100e83:	eb 0c                	jmp    f0100e91 <mem_init+0x8a>
	else
		npages = npages_basemem;
f0100e85:	8b 15 40 45 11 f0    	mov    0xf0114540,%edx
f0100e8b:	89 15 64 49 11 f0    	mov    %edx,0xf0114964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100e91:	c1 e0 0c             	shl    $0xc,%eax
f0100e94:	c1 e8 0a             	shr    $0xa,%eax
f0100e97:	50                   	push   %eax
f0100e98:	a1 40 45 11 f0       	mov    0xf0114540,%eax
f0100e9d:	c1 e0 0c             	shl    $0xc,%eax
f0100ea0:	c1 e8 0a             	shr    $0xa,%eax
f0100ea3:	50                   	push   %eax
f0100ea4:	a1 64 49 11 f0       	mov    0xf0114964,%eax
f0100ea9:	c1 e0 0c             	shl    $0xc,%eax
f0100eac:	c1 e8 0a             	shr    $0xa,%eax
f0100eaf:	50                   	push   %eax
f0100eb0:	68 ac 2a 10 f0       	push   $0xf0102aac
f0100eb5:	e8 76 06 00 00       	call   f0101530 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100eba:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100ebf:	e8 40 fa ff ff       	call   f0100904 <boot_alloc>
f0100ec4:	a3 68 49 11 f0       	mov    %eax,0xf0114968
	memset(kern_pgdir, 0, PGSIZE);
f0100ec9:	83 c4 0c             	add    $0xc,%esp
f0100ecc:	68 00 10 00 00       	push   $0x1000
f0100ed1:	6a 00                	push   $0x0
f0100ed3:	50                   	push   %eax
f0100ed4:	e8 0b 11 00 00       	call   f0101fe4 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100ed9:	a1 68 49 11 f0       	mov    0xf0114968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ede:	83 c4 10             	add    $0x10,%esp
f0100ee1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100ee6:	77 15                	ja     f0100efd <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ee8:	50                   	push   %eax
f0100ee9:	68 e8 2a 10 f0       	push   $0xf0102ae8
f0100eee:	68 8d 00 00 00       	push   $0x8d
f0100ef3:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100ef8:	e8 8e f1 ff ff       	call   f010008b <_panic>
f0100efd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100f03:	83 ca 05             	or     $0x5,%edx
f0100f06:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f0100f0c:	a1 64 49 11 f0       	mov    0xf0114964,%eax
f0100f11:	c1 e0 03             	shl    $0x3,%eax
f0100f14:	e8 eb f9 ff ff       	call   f0100904 <boot_alloc>
f0100f19:	a3 6c 49 11 f0       	mov    %eax,0xf011496c
	memset(pages,0,npages * sizeof(struct PageInfo));
f0100f1e:	83 ec 04             	sub    $0x4,%esp
f0100f21:	8b 0d 64 49 11 f0    	mov    0xf0114964,%ecx
f0100f27:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0100f2e:	52                   	push   %edx
f0100f2f:	6a 00                	push   $0x0
f0100f31:	50                   	push   %eax
f0100f32:	e8 ad 10 00 00       	call   f0101fe4 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0100f37:	e8 1a fd ff ff       	call   f0100c56 <page_init>

	check_page_free_list(1);
f0100f3c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100f41:	e8 5c fa ff ff       	call   f01009a2 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0100f46:	83 c4 10             	add    $0x10,%esp
f0100f49:	83 3d 6c 49 11 f0 00 	cmpl   $0x0,0xf011496c
f0100f50:	75 17                	jne    f0100f69 <mem_init+0x162>
		panic("'pages' is a null pointer!");
f0100f52:	83 ec 04             	sub    $0x4,%esp
f0100f55:	68 5f 2c 10 f0       	push   $0xf0102c5f
f0100f5a:	68 40 02 00 00       	push   $0x240
f0100f5f:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100f64:	e8 22 f1 ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100f69:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100f6e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100f73:	eb 05                	jmp    f0100f7a <mem_init+0x173>
		++nfree;
f0100f75:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100f78:	8b 00                	mov    (%eax),%eax
f0100f7a:	85 c0                	test   %eax,%eax
f0100f7c:	75 f7                	jne    f0100f75 <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0100f7e:	83 ec 0c             	sub    $0xc,%esp
f0100f81:	6a 00                	push   $0x0
f0100f83:	e8 ae fd ff ff       	call   f0100d36 <page_alloc>
f0100f88:	89 c7                	mov    %eax,%edi
f0100f8a:	83 c4 10             	add    $0x10,%esp
f0100f8d:	85 c0                	test   %eax,%eax
f0100f8f:	75 19                	jne    f0100faa <mem_init+0x1a3>
f0100f91:	68 7a 2c 10 f0       	push   $0xf0102c7a
f0100f96:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100f9b:	68 48 02 00 00       	push   $0x248
f0100fa0:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100fa5:	e8 e1 f0 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0100faa:	83 ec 0c             	sub    $0xc,%esp
f0100fad:	6a 00                	push   $0x0
f0100faf:	e8 82 fd ff ff       	call   f0100d36 <page_alloc>
f0100fb4:	89 c6                	mov    %eax,%esi
f0100fb6:	83 c4 10             	add    $0x10,%esp
f0100fb9:	85 c0                	test   %eax,%eax
f0100fbb:	75 19                	jne    f0100fd6 <mem_init+0x1cf>
f0100fbd:	68 90 2c 10 f0       	push   $0xf0102c90
f0100fc2:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100fc7:	68 49 02 00 00       	push   $0x249
f0100fcc:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100fd1:	e8 b5 f0 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0100fd6:	83 ec 0c             	sub    $0xc,%esp
f0100fd9:	6a 00                	push   $0x0
f0100fdb:	e8 56 fd ff ff       	call   f0100d36 <page_alloc>
f0100fe0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100fe3:	83 c4 10             	add    $0x10,%esp
f0100fe6:	85 c0                	test   %eax,%eax
f0100fe8:	75 19                	jne    f0101003 <mem_init+0x1fc>
f0100fea:	68 a6 2c 10 f0       	push   $0xf0102ca6
f0100fef:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100ff4:	68 4a 02 00 00       	push   $0x24a
f0100ff9:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100ffe:	e8 88 f0 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101003:	39 f7                	cmp    %esi,%edi
f0101005:	75 19                	jne    f0101020 <mem_init+0x219>
f0101007:	68 bc 2c 10 f0       	push   $0xf0102cbc
f010100c:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101011:	68 4d 02 00 00       	push   $0x24d
f0101016:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010101b:	e8 6b f0 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101020:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101023:	39 c7                	cmp    %eax,%edi
f0101025:	74 04                	je     f010102b <mem_init+0x224>
f0101027:	39 c6                	cmp    %eax,%esi
f0101029:	75 19                	jne    f0101044 <mem_init+0x23d>
f010102b:	68 0c 2b 10 f0       	push   $0xf0102b0c
f0101030:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101035:	68 4e 02 00 00       	push   $0x24e
f010103a:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010103f:	e8 47 f0 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101044:	8b 0d 6c 49 11 f0    	mov    0xf011496c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010104a:	8b 15 64 49 11 f0    	mov    0xf0114964,%edx
f0101050:	c1 e2 0c             	shl    $0xc,%edx
f0101053:	89 f8                	mov    %edi,%eax
f0101055:	29 c8                	sub    %ecx,%eax
f0101057:	c1 f8 03             	sar    $0x3,%eax
f010105a:	c1 e0 0c             	shl    $0xc,%eax
f010105d:	39 d0                	cmp    %edx,%eax
f010105f:	72 19                	jb     f010107a <mem_init+0x273>
f0101061:	68 ce 2c 10 f0       	push   $0xf0102cce
f0101066:	68 a2 2b 10 f0       	push   $0xf0102ba2
f010106b:	68 4f 02 00 00       	push   $0x24f
f0101070:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101075:	e8 11 f0 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010107a:	89 f0                	mov    %esi,%eax
f010107c:	29 c8                	sub    %ecx,%eax
f010107e:	c1 f8 03             	sar    $0x3,%eax
f0101081:	c1 e0 0c             	shl    $0xc,%eax
f0101084:	39 c2                	cmp    %eax,%edx
f0101086:	77 19                	ja     f01010a1 <mem_init+0x29a>
f0101088:	68 eb 2c 10 f0       	push   $0xf0102ceb
f010108d:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101092:	68 50 02 00 00       	push   $0x250
f0101097:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010109c:	e8 ea ef ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01010a1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010a4:	29 c8                	sub    %ecx,%eax
f01010a6:	c1 f8 03             	sar    $0x3,%eax
f01010a9:	c1 e0 0c             	shl    $0xc,%eax
f01010ac:	39 c2                	cmp    %eax,%edx
f01010ae:	77 19                	ja     f01010c9 <mem_init+0x2c2>
f01010b0:	68 08 2d 10 f0       	push   $0xf0102d08
f01010b5:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01010ba:	68 51 02 00 00       	push   $0x251
f01010bf:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01010c4:	e8 c2 ef ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01010c9:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f01010ce:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f01010d1:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f01010d8:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01010db:	83 ec 0c             	sub    $0xc,%esp
f01010de:	6a 00                	push   $0x0
f01010e0:	e8 51 fc ff ff       	call   f0100d36 <page_alloc>
f01010e5:	83 c4 10             	add    $0x10,%esp
f01010e8:	85 c0                	test   %eax,%eax
f01010ea:	74 19                	je     f0101105 <mem_init+0x2fe>
f01010ec:	68 25 2d 10 f0       	push   $0xf0102d25
f01010f1:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01010f6:	68 58 02 00 00       	push   $0x258
f01010fb:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101100:	e8 86 ef ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101105:	83 ec 0c             	sub    $0xc,%esp
f0101108:	57                   	push   %edi
f0101109:	e8 ae fc ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f010110e:	89 34 24             	mov    %esi,(%esp)
f0101111:	e8 a6 fc ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f0101116:	83 c4 04             	add    $0x4,%esp
f0101119:	ff 75 e4             	pushl  -0x1c(%ebp)
f010111c:	e8 9b fc ff ff       	call   f0100dbc <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101121:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101128:	e8 09 fc ff ff       	call   f0100d36 <page_alloc>
f010112d:	89 c6                	mov    %eax,%esi
f010112f:	83 c4 10             	add    $0x10,%esp
f0101132:	85 c0                	test   %eax,%eax
f0101134:	75 19                	jne    f010114f <mem_init+0x348>
f0101136:	68 7a 2c 10 f0       	push   $0xf0102c7a
f010113b:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101140:	68 5f 02 00 00       	push   $0x25f
f0101145:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010114a:	e8 3c ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010114f:	83 ec 0c             	sub    $0xc,%esp
f0101152:	6a 00                	push   $0x0
f0101154:	e8 dd fb ff ff       	call   f0100d36 <page_alloc>
f0101159:	89 c7                	mov    %eax,%edi
f010115b:	83 c4 10             	add    $0x10,%esp
f010115e:	85 c0                	test   %eax,%eax
f0101160:	75 19                	jne    f010117b <mem_init+0x374>
f0101162:	68 90 2c 10 f0       	push   $0xf0102c90
f0101167:	68 a2 2b 10 f0       	push   $0xf0102ba2
f010116c:	68 60 02 00 00       	push   $0x260
f0101171:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101176:	e8 10 ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010117b:	83 ec 0c             	sub    $0xc,%esp
f010117e:	6a 00                	push   $0x0
f0101180:	e8 b1 fb ff ff       	call   f0100d36 <page_alloc>
f0101185:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101188:	83 c4 10             	add    $0x10,%esp
f010118b:	85 c0                	test   %eax,%eax
f010118d:	75 19                	jne    f01011a8 <mem_init+0x3a1>
f010118f:	68 a6 2c 10 f0       	push   $0xf0102ca6
f0101194:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101199:	68 61 02 00 00       	push   $0x261
f010119e:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01011a3:	e8 e3 ee ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01011a8:	39 fe                	cmp    %edi,%esi
f01011aa:	75 19                	jne    f01011c5 <mem_init+0x3be>
f01011ac:	68 bc 2c 10 f0       	push   $0xf0102cbc
f01011b1:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01011b6:	68 63 02 00 00       	push   $0x263
f01011bb:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01011c0:	e8 c6 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01011c5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01011c8:	39 c7                	cmp    %eax,%edi
f01011ca:	74 04                	je     f01011d0 <mem_init+0x3c9>
f01011cc:	39 c6                	cmp    %eax,%esi
f01011ce:	75 19                	jne    f01011e9 <mem_init+0x3e2>
f01011d0:	68 0c 2b 10 f0       	push   $0xf0102b0c
f01011d5:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01011da:	68 64 02 00 00       	push   $0x264
f01011df:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01011e4:	e8 a2 ee ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01011e9:	83 ec 0c             	sub    $0xc,%esp
f01011ec:	6a 00                	push   $0x0
f01011ee:	e8 43 fb ff ff       	call   f0100d36 <page_alloc>
f01011f3:	83 c4 10             	add    $0x10,%esp
f01011f6:	85 c0                	test   %eax,%eax
f01011f8:	74 19                	je     f0101213 <mem_init+0x40c>
f01011fa:	68 25 2d 10 f0       	push   $0xf0102d25
f01011ff:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101204:	68 65 02 00 00       	push   $0x265
f0101209:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010120e:	e8 78 ee ff ff       	call   f010008b <_panic>
f0101213:	89 f0                	mov    %esi,%eax
f0101215:	2b 05 6c 49 11 f0    	sub    0xf011496c,%eax
f010121b:	c1 f8 03             	sar    $0x3,%eax
f010121e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101221:	89 c2                	mov    %eax,%edx
f0101223:	c1 ea 0c             	shr    $0xc,%edx
f0101226:	3b 15 64 49 11 f0    	cmp    0xf0114964,%edx
f010122c:	72 12                	jb     f0101240 <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010122e:	50                   	push   %eax
f010122f:	68 c4 29 10 f0       	push   $0xf01029c4
f0101234:	6a 52                	push   $0x52
f0101236:	68 88 2b 10 f0       	push   $0xf0102b88
f010123b:	e8 4b ee ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101240:	83 ec 04             	sub    $0x4,%esp
f0101243:	68 00 10 00 00       	push   $0x1000
f0101248:	6a 01                	push   $0x1
f010124a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010124f:	50                   	push   %eax
f0101250:	e8 8f 0d 00 00       	call   f0101fe4 <memset>
	page_free(pp0);
f0101255:	89 34 24             	mov    %esi,(%esp)
f0101258:	e8 5f fb ff ff       	call   f0100dbc <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010125d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101264:	e8 cd fa ff ff       	call   f0100d36 <page_alloc>
f0101269:	83 c4 10             	add    $0x10,%esp
f010126c:	85 c0                	test   %eax,%eax
f010126e:	75 19                	jne    f0101289 <mem_init+0x482>
f0101270:	68 34 2d 10 f0       	push   $0xf0102d34
f0101275:	68 a2 2b 10 f0       	push   $0xf0102ba2
f010127a:	68 6a 02 00 00       	push   $0x26a
f010127f:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101284:	e8 02 ee ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101289:	39 c6                	cmp    %eax,%esi
f010128b:	74 19                	je     f01012a6 <mem_init+0x49f>
f010128d:	68 52 2d 10 f0       	push   $0xf0102d52
f0101292:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101297:	68 6b 02 00 00       	push   $0x26b
f010129c:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01012a1:	e8 e5 ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012a6:	89 f0                	mov    %esi,%eax
f01012a8:	2b 05 6c 49 11 f0    	sub    0xf011496c,%eax
f01012ae:	c1 f8 03             	sar    $0x3,%eax
f01012b1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012b4:	89 c2                	mov    %eax,%edx
f01012b6:	c1 ea 0c             	shr    $0xc,%edx
f01012b9:	3b 15 64 49 11 f0    	cmp    0xf0114964,%edx
f01012bf:	72 12                	jb     f01012d3 <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012c1:	50                   	push   %eax
f01012c2:	68 c4 29 10 f0       	push   $0xf01029c4
f01012c7:	6a 52                	push   $0x52
f01012c9:	68 88 2b 10 f0       	push   $0xf0102b88
f01012ce:	e8 b8 ed ff ff       	call   f010008b <_panic>
f01012d3:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01012d9:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01012df:	80 38 00             	cmpb   $0x0,(%eax)
f01012e2:	74 19                	je     f01012fd <mem_init+0x4f6>
f01012e4:	68 62 2d 10 f0       	push   $0xf0102d62
f01012e9:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01012ee:	68 6e 02 00 00       	push   $0x26e
f01012f3:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01012f8:	e8 8e ed ff ff       	call   f010008b <_panic>
f01012fd:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101300:	39 d0                	cmp    %edx,%eax
f0101302:	75 db                	jne    f01012df <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101304:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101307:	a3 3c 45 11 f0       	mov    %eax,0xf011453c

	// free the pages we took
	page_free(pp0);
f010130c:	83 ec 0c             	sub    $0xc,%esp
f010130f:	56                   	push   %esi
f0101310:	e8 a7 fa ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f0101315:	89 3c 24             	mov    %edi,(%esp)
f0101318:	e8 9f fa ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f010131d:	83 c4 04             	add    $0x4,%esp
f0101320:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101323:	e8 94 fa ff ff       	call   f0100dbc <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101328:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f010132d:	83 c4 10             	add    $0x10,%esp
f0101330:	eb 05                	jmp    f0101337 <mem_init+0x530>
		--nfree;
f0101332:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101335:	8b 00                	mov    (%eax),%eax
f0101337:	85 c0                	test   %eax,%eax
f0101339:	75 f7                	jne    f0101332 <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f010133b:	85 db                	test   %ebx,%ebx
f010133d:	74 19                	je     f0101358 <mem_init+0x551>
f010133f:	68 6c 2d 10 f0       	push   $0xf0102d6c
f0101344:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101349:	68 7b 02 00 00       	push   $0x27b
f010134e:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101353:	e8 33 ed ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101358:	83 ec 0c             	sub    $0xc,%esp
f010135b:	68 2c 2b 10 f0       	push   $0xf0102b2c
f0101360:	e8 cb 01 00 00       	call   f0101530 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101365:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010136c:	e8 c5 f9 ff ff       	call   f0100d36 <page_alloc>
f0101371:	89 c3                	mov    %eax,%ebx
f0101373:	83 c4 10             	add    $0x10,%esp
f0101376:	85 c0                	test   %eax,%eax
f0101378:	75 19                	jne    f0101393 <mem_init+0x58c>
f010137a:	68 7a 2c 10 f0       	push   $0xf0102c7a
f010137f:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101384:	68 d4 02 00 00       	push   $0x2d4
f0101389:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010138e:	e8 f8 ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101393:	83 ec 0c             	sub    $0xc,%esp
f0101396:	6a 00                	push   $0x0
f0101398:	e8 99 f9 ff ff       	call   f0100d36 <page_alloc>
f010139d:	89 c6                	mov    %eax,%esi
f010139f:	83 c4 10             	add    $0x10,%esp
f01013a2:	85 c0                	test   %eax,%eax
f01013a4:	75 19                	jne    f01013bf <mem_init+0x5b8>
f01013a6:	68 90 2c 10 f0       	push   $0xf0102c90
f01013ab:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01013b0:	68 d5 02 00 00       	push   $0x2d5
f01013b5:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01013ba:	e8 cc ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013bf:	83 ec 0c             	sub    $0xc,%esp
f01013c2:	6a 00                	push   $0x0
f01013c4:	e8 6d f9 ff ff       	call   f0100d36 <page_alloc>
f01013c9:	83 c4 10             	add    $0x10,%esp
f01013cc:	85 c0                	test   %eax,%eax
f01013ce:	75 19                	jne    f01013e9 <mem_init+0x5e2>
f01013d0:	68 a6 2c 10 f0       	push   $0xf0102ca6
f01013d5:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01013da:	68 d6 02 00 00       	push   $0x2d6
f01013df:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01013e4:	e8 a2 ec ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013e9:	39 f3                	cmp    %esi,%ebx
f01013eb:	75 19                	jne    f0101406 <mem_init+0x5ff>
f01013ed:	68 bc 2c 10 f0       	push   $0xf0102cbc
f01013f2:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01013f7:	68 d9 02 00 00       	push   $0x2d9
f01013fc:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101401:	e8 85 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101406:	39 c6                	cmp    %eax,%esi
f0101408:	74 04                	je     f010140e <mem_init+0x607>
f010140a:	39 c3                	cmp    %eax,%ebx
f010140c:	75 19                	jne    f0101427 <mem_init+0x620>
f010140e:	68 0c 2b 10 f0       	push   $0xf0102b0c
f0101413:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101418:	68 da 02 00 00       	push   $0x2da
f010141d:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101422:	e8 64 ec ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f0101427:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f010142e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101431:	83 ec 0c             	sub    $0xc,%esp
f0101434:	6a 00                	push   $0x0
f0101436:	e8 fb f8 ff ff       	call   f0100d36 <page_alloc>
f010143b:	83 c4 10             	add    $0x10,%esp
f010143e:	85 c0                	test   %eax,%eax
f0101440:	74 19                	je     f010145b <mem_init+0x654>
f0101442:	68 25 2d 10 f0       	push   $0xf0102d25
f0101447:	68 a2 2b 10 f0       	push   $0xf0102ba2
f010144c:	68 e1 02 00 00       	push   $0x2e1
f0101451:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101456:	e8 30 ec ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010145b:	68 4c 2b 10 f0       	push   $0xf0102b4c
f0101460:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101465:	68 e7 02 00 00       	push   $0x2e7
f010146a:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010146f:	e8 17 ec ff ff       	call   f010008b <_panic>

f0101474 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101474:	55                   	push   %ebp
f0101475:	89 e5                	mov    %esp,%ebp
f0101477:	83 ec 08             	sub    $0x8,%esp
f010147a:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f010147d:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101481:	83 e8 01             	sub    $0x1,%eax
f0101484:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101488:	66 85 c0             	test   %ax,%ax
f010148b:	75 0c                	jne    f0101499 <page_decref+0x25>
		page_free(pp);
f010148d:	83 ec 0c             	sub    $0xc,%esp
f0101490:	52                   	push   %edx
f0101491:	e8 26 f9 ff ff       	call   f0100dbc <page_free>
f0101496:	83 c4 10             	add    $0x10,%esp
}
f0101499:	c9                   	leave  
f010149a:	c3                   	ret    

f010149b <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f010149b:	55                   	push   %ebp
f010149c:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f010149e:	b8 00 00 00 00       	mov    $0x0,%eax
f01014a3:	5d                   	pop    %ebp
f01014a4:	c3                   	ret    

f01014a5 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01014a5:	55                   	push   %ebp
f01014a6:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f01014a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01014ad:	5d                   	pop    %ebp
f01014ae:	c3                   	ret    

f01014af <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01014af:	55                   	push   %ebp
f01014b0:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01014b2:	b8 00 00 00 00       	mov    $0x0,%eax
f01014b7:	5d                   	pop    %ebp
f01014b8:	c3                   	ret    

f01014b9 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01014b9:	55                   	push   %ebp
f01014ba:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f01014bc:	5d                   	pop    %ebp
f01014bd:	c3                   	ret    

f01014be <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01014be:	55                   	push   %ebp
f01014bf:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01014c1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014c4:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01014c7:	5d                   	pop    %ebp
f01014c8:	c3                   	ret    

f01014c9 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01014c9:	55                   	push   %ebp
f01014ca:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01014cc:	ba 70 00 00 00       	mov    $0x70,%edx
f01014d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01014d4:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01014d5:	ba 71 00 00 00       	mov    $0x71,%edx
f01014da:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01014db:	0f b6 c0             	movzbl %al,%eax
}
f01014de:	5d                   	pop    %ebp
f01014df:	c3                   	ret    

f01014e0 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01014e0:	55                   	push   %ebp
f01014e1:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01014e3:	ba 70 00 00 00       	mov    $0x70,%edx
f01014e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01014eb:	ee                   	out    %al,(%dx)
f01014ec:	ba 71 00 00 00       	mov    $0x71,%edx
f01014f1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014f4:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01014f5:	5d                   	pop    %ebp
f01014f6:	c3                   	ret    

f01014f7 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01014f7:	55                   	push   %ebp
f01014f8:	89 e5                	mov    %esp,%ebp
f01014fa:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01014fd:	ff 75 08             	pushl  0x8(%ebp)
f0101500:	e8 20 f1 ff ff       	call   f0100625 <cputchar>
	*cnt++;
}
f0101505:	83 c4 10             	add    $0x10,%esp
f0101508:	c9                   	leave  
f0101509:	c3                   	ret    

f010150a <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010150a:	55                   	push   %ebp
f010150b:	89 e5                	mov    %esp,%ebp
f010150d:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0101510:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0101517:	ff 75 0c             	pushl  0xc(%ebp)
f010151a:	ff 75 08             	pushl  0x8(%ebp)
f010151d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101520:	50                   	push   %eax
f0101521:	68 f7 14 10 f0       	push   $0xf01014f7
f0101526:	e8 4d 04 00 00       	call   f0101978 <vprintfmt>
	return cnt;
}
f010152b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010152e:	c9                   	leave  
f010152f:	c3                   	ret    

f0101530 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0101530:	55                   	push   %ebp
f0101531:	89 e5                	mov    %esp,%ebp
f0101533:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0101536:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101539:	50                   	push   %eax
f010153a:	ff 75 08             	pushl  0x8(%ebp)
f010153d:	e8 c8 ff ff ff       	call   f010150a <vcprintf>
	va_end(ap);

	return cnt;
}
f0101542:	c9                   	leave  
f0101543:	c3                   	ret    

f0101544 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0101544:	55                   	push   %ebp
f0101545:	89 e5                	mov    %esp,%ebp
f0101547:	57                   	push   %edi
f0101548:	56                   	push   %esi
f0101549:	53                   	push   %ebx
f010154a:	83 ec 14             	sub    $0x14,%esp
f010154d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101550:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101553:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101556:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101559:	8b 1a                	mov    (%edx),%ebx
f010155b:	8b 01                	mov    (%ecx),%eax
f010155d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101560:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0101567:	eb 7f                	jmp    f01015e8 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0101569:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010156c:	01 d8                	add    %ebx,%eax
f010156e:	89 c6                	mov    %eax,%esi
f0101570:	c1 ee 1f             	shr    $0x1f,%esi
f0101573:	01 c6                	add    %eax,%esi
f0101575:	d1 fe                	sar    %esi
f0101577:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010157a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010157d:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0101580:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101582:	eb 03                	jmp    f0101587 <stab_binsearch+0x43>
			m--;
f0101584:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101587:	39 c3                	cmp    %eax,%ebx
f0101589:	7f 0d                	jg     f0101598 <stab_binsearch+0x54>
f010158b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010158f:	83 ea 0c             	sub    $0xc,%edx
f0101592:	39 f9                	cmp    %edi,%ecx
f0101594:	75 ee                	jne    f0101584 <stab_binsearch+0x40>
f0101596:	eb 05                	jmp    f010159d <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0101598:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010159b:	eb 4b                	jmp    f01015e8 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010159d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01015a0:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01015a3:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01015a7:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01015aa:	76 11                	jbe    f01015bd <stab_binsearch+0x79>
			*region_left = m;
f01015ac:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01015af:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01015b1:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01015b4:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01015bb:	eb 2b                	jmp    f01015e8 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01015bd:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01015c0:	73 14                	jae    f01015d6 <stab_binsearch+0x92>
			*region_right = m - 1;
f01015c2:	83 e8 01             	sub    $0x1,%eax
f01015c5:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01015c8:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01015cb:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01015cd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01015d4:	eb 12                	jmp    f01015e8 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01015d6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01015d9:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01015db:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01015df:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01015e1:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01015e8:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01015eb:	0f 8e 78 ff ff ff    	jle    f0101569 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01015f1:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01015f5:	75 0f                	jne    f0101606 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01015f7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01015fa:	8b 00                	mov    (%eax),%eax
f01015fc:	83 e8 01             	sub    $0x1,%eax
f01015ff:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101602:	89 06                	mov    %eax,(%esi)
f0101604:	eb 2c                	jmp    f0101632 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101606:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101609:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010160b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010160e:	8b 0e                	mov    (%esi),%ecx
f0101610:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101613:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0101616:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101619:	eb 03                	jmp    f010161e <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010161b:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010161e:	39 c8                	cmp    %ecx,%eax
f0101620:	7e 0b                	jle    f010162d <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0101622:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0101626:	83 ea 0c             	sub    $0xc,%edx
f0101629:	39 df                	cmp    %ebx,%edi
f010162b:	75 ee                	jne    f010161b <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010162d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101630:	89 06                	mov    %eax,(%esi)
	}
}
f0101632:	83 c4 14             	add    $0x14,%esp
f0101635:	5b                   	pop    %ebx
f0101636:	5e                   	pop    %esi
f0101637:	5f                   	pop    %edi
f0101638:	5d                   	pop    %ebp
f0101639:	c3                   	ret    

f010163a <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010163a:	55                   	push   %ebp
f010163b:	89 e5                	mov    %esp,%ebp
f010163d:	57                   	push   %edi
f010163e:	56                   	push   %esi
f010163f:	53                   	push   %ebx
f0101640:	83 ec 2c             	sub    $0x2c,%esp
f0101643:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101646:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101649:	c7 06 77 2d 10 f0    	movl   $0xf0102d77,(%esi)
	info->eip_line = 0;
f010164f:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0101656:	c7 46 08 77 2d 10 f0 	movl   $0xf0102d77,0x8(%esi)
	info->eip_fn_namelen = 9;
f010165d:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0101664:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0101667:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010166e:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0101674:	76 11                	jbe    f0101687 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101676:	b8 d8 97 10 f0       	mov    $0xf01097d8,%eax
f010167b:	3d dd 7a 10 f0       	cmp    $0xf0107add,%eax
f0101680:	77 19                	ja     f010169b <debuginfo_eip+0x61>
f0101682:	e9 a5 01 00 00       	jmp    f010182c <debuginfo_eip+0x1f2>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0101687:	83 ec 04             	sub    $0x4,%esp
f010168a:	68 81 2d 10 f0       	push   $0xf0102d81
f010168f:	6a 7f                	push   $0x7f
f0101691:	68 8e 2d 10 f0       	push   $0xf0102d8e
f0101696:	e8 f0 e9 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010169b:	80 3d d7 97 10 f0 00 	cmpb   $0x0,0xf01097d7
f01016a2:	0f 85 8b 01 00 00    	jne    f0101833 <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01016a8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01016af:	b8 dc 7a 10 f0       	mov    $0xf0107adc,%eax
f01016b4:	2d d0 2f 10 f0       	sub    $0xf0102fd0,%eax
f01016b9:	c1 f8 02             	sar    $0x2,%eax
f01016bc:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01016c2:	83 e8 01             	sub    $0x1,%eax
f01016c5:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01016c8:	83 ec 08             	sub    $0x8,%esp
f01016cb:	57                   	push   %edi
f01016cc:	6a 64                	push   $0x64
f01016ce:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01016d1:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01016d4:	b8 d0 2f 10 f0       	mov    $0xf0102fd0,%eax
f01016d9:	e8 66 fe ff ff       	call   f0101544 <stab_binsearch>
	if (lfile == 0)
f01016de:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01016e1:	83 c4 10             	add    $0x10,%esp
f01016e4:	85 c0                	test   %eax,%eax
f01016e6:	0f 84 4e 01 00 00    	je     f010183a <debuginfo_eip+0x200>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01016ec:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01016ef:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01016f2:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01016f5:	83 ec 08             	sub    $0x8,%esp
f01016f8:	57                   	push   %edi
f01016f9:	6a 24                	push   $0x24
f01016fb:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01016fe:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101701:	b8 d0 2f 10 f0       	mov    $0xf0102fd0,%eax
f0101706:	e8 39 fe ff ff       	call   f0101544 <stab_binsearch>

	if (lfun <= rfun) {
f010170b:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010170e:	83 c4 10             	add    $0x10,%esp
f0101711:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0101714:	7f 33                	jg     f0101749 <debuginfo_eip+0x10f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0101716:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0101719:	c1 e0 02             	shl    $0x2,%eax
f010171c:	8d 90 d0 2f 10 f0    	lea    -0xfefd030(%eax),%edx
f0101722:	8b 88 d0 2f 10 f0    	mov    -0xfefd030(%eax),%ecx
f0101728:	b8 d8 97 10 f0       	mov    $0xf01097d8,%eax
f010172d:	2d dd 7a 10 f0       	sub    $0xf0107add,%eax
f0101732:	39 c1                	cmp    %eax,%ecx
f0101734:	73 09                	jae    f010173f <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0101736:	81 c1 dd 7a 10 f0    	add    $0xf0107add,%ecx
f010173c:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010173f:	8b 42 08             	mov    0x8(%edx),%eax
f0101742:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f0101745:	29 c7                	sub    %eax,%edi
f0101747:	eb 06                	jmp    f010174f <debuginfo_eip+0x115>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0101749:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f010174c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010174f:	83 ec 08             	sub    $0x8,%esp
f0101752:	6a 3a                	push   $0x3a
f0101754:	ff 76 08             	pushl  0x8(%esi)
f0101757:	e8 6c 08 00 00       	call   f0101fc8 <strfind>
f010175c:	2b 46 08             	sub    0x8(%esi),%eax
f010175f:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
f0101762:	83 c4 08             	add    $0x8,%esp
f0101765:	2b 7e 10             	sub    0x10(%esi),%edi
f0101768:	57                   	push   %edi
f0101769:	6a 44                	push   $0x44
f010176b:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010176e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101771:	b8 d0 2f 10 f0       	mov    $0xf0102fd0,%eax
f0101776:	e8 c9 fd ff ff       	call   f0101544 <stab_binsearch>
	if (lfun > rfun) 
f010177b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010177e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101781:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0101784:	83 c4 10             	add    $0x10,%esp
f0101787:	39 c8                	cmp    %ecx,%eax
f0101789:	0f 8f b2 00 00 00    	jg     f0101841 <debuginfo_eip+0x207>
       	  return -1;
        info->eip_line = stabs[lfun].n_desc;
f010178f:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0101792:	8d 04 85 d0 2f 10 f0 	lea    -0xfefd030(,%eax,4),%eax
f0101799:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010179c:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f01017a0:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01017a3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01017a6:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01017a9:	8d 04 85 d0 2f 10 f0 	lea    -0xfefd030(,%eax,4),%eax
f01017b0:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01017b3:	eb 06                	jmp    f01017bb <debuginfo_eip+0x181>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01017b5:	83 eb 01             	sub    $0x1,%ebx
f01017b8:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01017bb:	39 fb                	cmp    %edi,%ebx
f01017bd:	7c 39                	jl     f01017f8 <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f01017bf:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01017c3:	80 fa 84             	cmp    $0x84,%dl
f01017c6:	74 0b                	je     f01017d3 <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01017c8:	80 fa 64             	cmp    $0x64,%dl
f01017cb:	75 e8                	jne    f01017b5 <debuginfo_eip+0x17b>
f01017cd:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01017d1:	74 e2                	je     f01017b5 <debuginfo_eip+0x17b>
f01017d3:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01017d6:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01017d9:	8b 14 85 d0 2f 10 f0 	mov    -0xfefd030(,%eax,4),%edx
f01017e0:	b8 d8 97 10 f0       	mov    $0xf01097d8,%eax
f01017e5:	2d dd 7a 10 f0       	sub    $0xf0107add,%eax
f01017ea:	39 c2                	cmp    %eax,%edx
f01017ec:	73 0d                	jae    f01017fb <debuginfo_eip+0x1c1>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01017ee:	81 c2 dd 7a 10 f0    	add    $0xf0107add,%edx
f01017f4:	89 16                	mov    %edx,(%esi)
f01017f6:	eb 03                	jmp    f01017fb <debuginfo_eip+0x1c1>
f01017f8:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01017fb:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101800:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101803:	39 cf                	cmp    %ecx,%edi
f0101805:	7d 46                	jge    f010184d <debuginfo_eip+0x213>
		for (lline = lfun + 1;
f0101807:	89 f8                	mov    %edi,%eax
f0101809:	83 c0 01             	add    $0x1,%eax
f010180c:	8b 55 cc             	mov    -0x34(%ebp),%edx
f010180f:	eb 07                	jmp    f0101818 <debuginfo_eip+0x1de>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0101811:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0101815:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0101818:	39 c8                	cmp    %ecx,%eax
f010181a:	74 2c                	je     f0101848 <debuginfo_eip+0x20e>
f010181c:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010181f:	80 7a 04 a0          	cmpb   $0xa0,0x4(%edx)
f0101823:	74 ec                	je     f0101811 <debuginfo_eip+0x1d7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101825:	b8 00 00 00 00       	mov    $0x0,%eax
f010182a:	eb 21                	jmp    f010184d <debuginfo_eip+0x213>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010182c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101831:	eb 1a                	jmp    f010184d <debuginfo_eip+0x213>
f0101833:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101838:	eb 13                	jmp    f010184d <debuginfo_eip+0x213>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f010183a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010183f:	eb 0c                	jmp    f010184d <debuginfo_eip+0x213>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
	if (lfun > rfun) 
       	  return -1;
f0101841:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101846:	eb 05                	jmp    f010184d <debuginfo_eip+0x213>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101848:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010184d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101850:	5b                   	pop    %ebx
f0101851:	5e                   	pop    %esi
f0101852:	5f                   	pop    %edi
f0101853:	5d                   	pop    %ebp
f0101854:	c3                   	ret    

f0101855 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101855:	55                   	push   %ebp
f0101856:	89 e5                	mov    %esp,%ebp
f0101858:	57                   	push   %edi
f0101859:	56                   	push   %esi
f010185a:	53                   	push   %ebx
f010185b:	83 ec 1c             	sub    $0x1c,%esp
f010185e:	89 c7                	mov    %eax,%edi
f0101860:	89 d6                	mov    %edx,%esi
f0101862:	8b 45 08             	mov    0x8(%ebp),%eax
f0101865:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101868:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010186b:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010186e:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101871:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101876:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101879:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010187c:	39 d3                	cmp    %edx,%ebx
f010187e:	72 05                	jb     f0101885 <printnum+0x30>
f0101880:	39 45 10             	cmp    %eax,0x10(%ebp)
f0101883:	77 45                	ja     f01018ca <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0101885:	83 ec 0c             	sub    $0xc,%esp
f0101888:	ff 75 18             	pushl  0x18(%ebp)
f010188b:	8b 45 14             	mov    0x14(%ebp),%eax
f010188e:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0101891:	53                   	push   %ebx
f0101892:	ff 75 10             	pushl  0x10(%ebp)
f0101895:	83 ec 08             	sub    $0x8,%esp
f0101898:	ff 75 e4             	pushl  -0x1c(%ebp)
f010189b:	ff 75 e0             	pushl  -0x20(%ebp)
f010189e:	ff 75 dc             	pushl  -0x24(%ebp)
f01018a1:	ff 75 d8             	pushl  -0x28(%ebp)
f01018a4:	e8 47 09 00 00       	call   f01021f0 <__udivdi3>
f01018a9:	83 c4 18             	add    $0x18,%esp
f01018ac:	52                   	push   %edx
f01018ad:	50                   	push   %eax
f01018ae:	89 f2                	mov    %esi,%edx
f01018b0:	89 f8                	mov    %edi,%eax
f01018b2:	e8 9e ff ff ff       	call   f0101855 <printnum>
f01018b7:	83 c4 20             	add    $0x20,%esp
f01018ba:	eb 18                	jmp    f01018d4 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01018bc:	83 ec 08             	sub    $0x8,%esp
f01018bf:	56                   	push   %esi
f01018c0:	ff 75 18             	pushl  0x18(%ebp)
f01018c3:	ff d7                	call   *%edi
f01018c5:	83 c4 10             	add    $0x10,%esp
f01018c8:	eb 03                	jmp    f01018cd <printnum+0x78>
f01018ca:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01018cd:	83 eb 01             	sub    $0x1,%ebx
f01018d0:	85 db                	test   %ebx,%ebx
f01018d2:	7f e8                	jg     f01018bc <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01018d4:	83 ec 08             	sub    $0x8,%esp
f01018d7:	56                   	push   %esi
f01018d8:	83 ec 04             	sub    $0x4,%esp
f01018db:	ff 75 e4             	pushl  -0x1c(%ebp)
f01018de:	ff 75 e0             	pushl  -0x20(%ebp)
f01018e1:	ff 75 dc             	pushl  -0x24(%ebp)
f01018e4:	ff 75 d8             	pushl  -0x28(%ebp)
f01018e7:	e8 34 0a 00 00       	call   f0102320 <__umoddi3>
f01018ec:	83 c4 14             	add    $0x14,%esp
f01018ef:	0f be 80 9c 2d 10 f0 	movsbl -0xfefd264(%eax),%eax
f01018f6:	50                   	push   %eax
f01018f7:	ff d7                	call   *%edi
}
f01018f9:	83 c4 10             	add    $0x10,%esp
f01018fc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01018ff:	5b                   	pop    %ebx
f0101900:	5e                   	pop    %esi
f0101901:	5f                   	pop    %edi
f0101902:	5d                   	pop    %ebp
f0101903:	c3                   	ret    

f0101904 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0101904:	55                   	push   %ebp
f0101905:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101907:	83 fa 01             	cmp    $0x1,%edx
f010190a:	7e 0e                	jle    f010191a <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010190c:	8b 10                	mov    (%eax),%edx
f010190e:	8d 4a 08             	lea    0x8(%edx),%ecx
f0101911:	89 08                	mov    %ecx,(%eax)
f0101913:	8b 02                	mov    (%edx),%eax
f0101915:	8b 52 04             	mov    0x4(%edx),%edx
f0101918:	eb 22                	jmp    f010193c <getuint+0x38>
	else if (lflag)
f010191a:	85 d2                	test   %edx,%edx
f010191c:	74 10                	je     f010192e <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010191e:	8b 10                	mov    (%eax),%edx
f0101920:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101923:	89 08                	mov    %ecx,(%eax)
f0101925:	8b 02                	mov    (%edx),%eax
f0101927:	ba 00 00 00 00       	mov    $0x0,%edx
f010192c:	eb 0e                	jmp    f010193c <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010192e:	8b 10                	mov    (%eax),%edx
f0101930:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101933:	89 08                	mov    %ecx,(%eax)
f0101935:	8b 02                	mov    (%edx),%eax
f0101937:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010193c:	5d                   	pop    %ebp
f010193d:	c3                   	ret    

f010193e <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010193e:	55                   	push   %ebp
f010193f:	89 e5                	mov    %esp,%ebp
f0101941:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101944:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101948:	8b 10                	mov    (%eax),%edx
f010194a:	3b 50 04             	cmp    0x4(%eax),%edx
f010194d:	73 0a                	jae    f0101959 <sprintputch+0x1b>
		*b->buf++ = ch;
f010194f:	8d 4a 01             	lea    0x1(%edx),%ecx
f0101952:	89 08                	mov    %ecx,(%eax)
f0101954:	8b 45 08             	mov    0x8(%ebp),%eax
f0101957:	88 02                	mov    %al,(%edx)
}
f0101959:	5d                   	pop    %ebp
f010195a:	c3                   	ret    

f010195b <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010195b:	55                   	push   %ebp
f010195c:	89 e5                	mov    %esp,%ebp
f010195e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0101961:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101964:	50                   	push   %eax
f0101965:	ff 75 10             	pushl  0x10(%ebp)
f0101968:	ff 75 0c             	pushl  0xc(%ebp)
f010196b:	ff 75 08             	pushl  0x8(%ebp)
f010196e:	e8 05 00 00 00       	call   f0101978 <vprintfmt>
	va_end(ap);
}
f0101973:	83 c4 10             	add    $0x10,%esp
f0101976:	c9                   	leave  
f0101977:	c3                   	ret    

f0101978 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101978:	55                   	push   %ebp
f0101979:	89 e5                	mov    %esp,%ebp
f010197b:	57                   	push   %edi
f010197c:	56                   	push   %esi
f010197d:	53                   	push   %ebx
f010197e:	83 ec 2c             	sub    $0x2c,%esp
f0101981:	8b 75 08             	mov    0x8(%ebp),%esi
f0101984:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101987:	8b 7d 10             	mov    0x10(%ebp),%edi
f010198a:	eb 12                	jmp    f010199e <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010198c:	85 c0                	test   %eax,%eax
f010198e:	0f 84 89 03 00 00    	je     f0101d1d <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0101994:	83 ec 08             	sub    $0x8,%esp
f0101997:	53                   	push   %ebx
f0101998:	50                   	push   %eax
f0101999:	ff d6                	call   *%esi
f010199b:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010199e:	83 c7 01             	add    $0x1,%edi
f01019a1:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01019a5:	83 f8 25             	cmp    $0x25,%eax
f01019a8:	75 e2                	jne    f010198c <vprintfmt+0x14>
f01019aa:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01019ae:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01019b5:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01019bc:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01019c3:	ba 00 00 00 00       	mov    $0x0,%edx
f01019c8:	eb 07                	jmp    f01019d1 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019ca:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01019cd:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019d1:	8d 47 01             	lea    0x1(%edi),%eax
f01019d4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01019d7:	0f b6 07             	movzbl (%edi),%eax
f01019da:	0f b6 c8             	movzbl %al,%ecx
f01019dd:	83 e8 23             	sub    $0x23,%eax
f01019e0:	3c 55                	cmp    $0x55,%al
f01019e2:	0f 87 1a 03 00 00    	ja     f0101d02 <vprintfmt+0x38a>
f01019e8:	0f b6 c0             	movzbl %al,%eax
f01019eb:	ff 24 85 40 2e 10 f0 	jmp    *-0xfefd1c0(,%eax,4)
f01019f2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01019f5:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01019f9:	eb d6                	jmp    f01019d1 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019fb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01019fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a03:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101a06:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101a09:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0101a0d:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0101a10:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0101a13:	83 fa 09             	cmp    $0x9,%edx
f0101a16:	77 39                	ja     f0101a51 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101a18:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0101a1b:	eb e9                	jmp    f0101a06 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101a1d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a20:	8d 48 04             	lea    0x4(%eax),%ecx
f0101a23:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101a26:	8b 00                	mov    (%eax),%eax
f0101a28:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a2b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101a2e:	eb 27                	jmp    f0101a57 <vprintfmt+0xdf>
f0101a30:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101a33:	85 c0                	test   %eax,%eax
f0101a35:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101a3a:	0f 49 c8             	cmovns %eax,%ecx
f0101a3d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a40:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a43:	eb 8c                	jmp    f01019d1 <vprintfmt+0x59>
f0101a45:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101a48:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0101a4f:	eb 80                	jmp    f01019d1 <vprintfmt+0x59>
f0101a51:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101a54:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0101a57:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101a5b:	0f 89 70 ff ff ff    	jns    f01019d1 <vprintfmt+0x59>
				width = precision, precision = -1;
f0101a61:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a64:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101a67:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101a6e:	e9 5e ff ff ff       	jmp    f01019d1 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101a73:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a76:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101a79:	e9 53 ff ff ff       	jmp    f01019d1 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101a7e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a81:	8d 50 04             	lea    0x4(%eax),%edx
f0101a84:	89 55 14             	mov    %edx,0x14(%ebp)
f0101a87:	83 ec 08             	sub    $0x8,%esp
f0101a8a:	53                   	push   %ebx
f0101a8b:	ff 30                	pushl  (%eax)
f0101a8d:	ff d6                	call   *%esi
			break;
f0101a8f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a92:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0101a95:	e9 04 ff ff ff       	jmp    f010199e <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101a9a:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a9d:	8d 50 04             	lea    0x4(%eax),%edx
f0101aa0:	89 55 14             	mov    %edx,0x14(%ebp)
f0101aa3:	8b 00                	mov    (%eax),%eax
f0101aa5:	99                   	cltd   
f0101aa6:	31 d0                	xor    %edx,%eax
f0101aa8:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101aaa:	83 f8 07             	cmp    $0x7,%eax
f0101aad:	7f 0b                	jg     f0101aba <vprintfmt+0x142>
f0101aaf:	8b 14 85 a0 2f 10 f0 	mov    -0xfefd060(,%eax,4),%edx
f0101ab6:	85 d2                	test   %edx,%edx
f0101ab8:	75 18                	jne    f0101ad2 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0101aba:	50                   	push   %eax
f0101abb:	68 b4 2d 10 f0       	push   $0xf0102db4
f0101ac0:	53                   	push   %ebx
f0101ac1:	56                   	push   %esi
f0101ac2:	e8 94 fe ff ff       	call   f010195b <printfmt>
f0101ac7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101aca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101acd:	e9 cc fe ff ff       	jmp    f010199e <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0101ad2:	52                   	push   %edx
f0101ad3:	68 b4 2b 10 f0       	push   $0xf0102bb4
f0101ad8:	53                   	push   %ebx
f0101ad9:	56                   	push   %esi
f0101ada:	e8 7c fe ff ff       	call   f010195b <printfmt>
f0101adf:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101ae2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101ae5:	e9 b4 fe ff ff       	jmp    f010199e <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101aea:	8b 45 14             	mov    0x14(%ebp),%eax
f0101aed:	8d 50 04             	lea    0x4(%eax),%edx
f0101af0:	89 55 14             	mov    %edx,0x14(%ebp)
f0101af3:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101af5:	85 ff                	test   %edi,%edi
f0101af7:	b8 ad 2d 10 f0       	mov    $0xf0102dad,%eax
f0101afc:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101aff:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101b03:	0f 8e 94 00 00 00    	jle    f0101b9d <vprintfmt+0x225>
f0101b09:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101b0d:	0f 84 98 00 00 00    	je     f0101bab <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101b13:	83 ec 08             	sub    $0x8,%esp
f0101b16:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b19:	57                   	push   %edi
f0101b1a:	e8 5f 03 00 00       	call   f0101e7e <strnlen>
f0101b1f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101b22:	29 c1                	sub    %eax,%ecx
f0101b24:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101b27:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101b2a:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101b2e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101b31:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101b34:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101b36:	eb 0f                	jmp    f0101b47 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0101b38:	83 ec 08             	sub    $0x8,%esp
f0101b3b:	53                   	push   %ebx
f0101b3c:	ff 75 e0             	pushl  -0x20(%ebp)
f0101b3f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101b41:	83 ef 01             	sub    $0x1,%edi
f0101b44:	83 c4 10             	add    $0x10,%esp
f0101b47:	85 ff                	test   %edi,%edi
f0101b49:	7f ed                	jg     f0101b38 <vprintfmt+0x1c0>
f0101b4b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101b4e:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101b51:	85 c9                	test   %ecx,%ecx
f0101b53:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b58:	0f 49 c1             	cmovns %ecx,%eax
f0101b5b:	29 c1                	sub    %eax,%ecx
f0101b5d:	89 75 08             	mov    %esi,0x8(%ebp)
f0101b60:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101b63:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101b66:	89 cb                	mov    %ecx,%ebx
f0101b68:	eb 4d                	jmp    f0101bb7 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101b6a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101b6e:	74 1b                	je     f0101b8b <vprintfmt+0x213>
f0101b70:	0f be c0             	movsbl %al,%eax
f0101b73:	83 e8 20             	sub    $0x20,%eax
f0101b76:	83 f8 5e             	cmp    $0x5e,%eax
f0101b79:	76 10                	jbe    f0101b8b <vprintfmt+0x213>
					putch('?', putdat);
f0101b7b:	83 ec 08             	sub    $0x8,%esp
f0101b7e:	ff 75 0c             	pushl  0xc(%ebp)
f0101b81:	6a 3f                	push   $0x3f
f0101b83:	ff 55 08             	call   *0x8(%ebp)
f0101b86:	83 c4 10             	add    $0x10,%esp
f0101b89:	eb 0d                	jmp    f0101b98 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0101b8b:	83 ec 08             	sub    $0x8,%esp
f0101b8e:	ff 75 0c             	pushl  0xc(%ebp)
f0101b91:	52                   	push   %edx
f0101b92:	ff 55 08             	call   *0x8(%ebp)
f0101b95:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101b98:	83 eb 01             	sub    $0x1,%ebx
f0101b9b:	eb 1a                	jmp    f0101bb7 <vprintfmt+0x23f>
f0101b9d:	89 75 08             	mov    %esi,0x8(%ebp)
f0101ba0:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101ba3:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101ba6:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101ba9:	eb 0c                	jmp    f0101bb7 <vprintfmt+0x23f>
f0101bab:	89 75 08             	mov    %esi,0x8(%ebp)
f0101bae:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101bb1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101bb4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101bb7:	83 c7 01             	add    $0x1,%edi
f0101bba:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101bbe:	0f be d0             	movsbl %al,%edx
f0101bc1:	85 d2                	test   %edx,%edx
f0101bc3:	74 23                	je     f0101be8 <vprintfmt+0x270>
f0101bc5:	85 f6                	test   %esi,%esi
f0101bc7:	78 a1                	js     f0101b6a <vprintfmt+0x1f2>
f0101bc9:	83 ee 01             	sub    $0x1,%esi
f0101bcc:	79 9c                	jns    f0101b6a <vprintfmt+0x1f2>
f0101bce:	89 df                	mov    %ebx,%edi
f0101bd0:	8b 75 08             	mov    0x8(%ebp),%esi
f0101bd3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101bd6:	eb 18                	jmp    f0101bf0 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101bd8:	83 ec 08             	sub    $0x8,%esp
f0101bdb:	53                   	push   %ebx
f0101bdc:	6a 20                	push   $0x20
f0101bde:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101be0:	83 ef 01             	sub    $0x1,%edi
f0101be3:	83 c4 10             	add    $0x10,%esp
f0101be6:	eb 08                	jmp    f0101bf0 <vprintfmt+0x278>
f0101be8:	89 df                	mov    %ebx,%edi
f0101bea:	8b 75 08             	mov    0x8(%ebp),%esi
f0101bed:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101bf0:	85 ff                	test   %edi,%edi
f0101bf2:	7f e4                	jg     f0101bd8 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101bf4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101bf7:	e9 a2 fd ff ff       	jmp    f010199e <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101bfc:	83 fa 01             	cmp    $0x1,%edx
f0101bff:	7e 16                	jle    f0101c17 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101c01:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c04:	8d 50 08             	lea    0x8(%eax),%edx
f0101c07:	89 55 14             	mov    %edx,0x14(%ebp)
f0101c0a:	8b 50 04             	mov    0x4(%eax),%edx
f0101c0d:	8b 00                	mov    (%eax),%eax
f0101c0f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101c12:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101c15:	eb 32                	jmp    f0101c49 <vprintfmt+0x2d1>
	else if (lflag)
f0101c17:	85 d2                	test   %edx,%edx
f0101c19:	74 18                	je     f0101c33 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0101c1b:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c1e:	8d 50 04             	lea    0x4(%eax),%edx
f0101c21:	89 55 14             	mov    %edx,0x14(%ebp)
f0101c24:	8b 00                	mov    (%eax),%eax
f0101c26:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101c29:	89 c1                	mov    %eax,%ecx
f0101c2b:	c1 f9 1f             	sar    $0x1f,%ecx
f0101c2e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101c31:	eb 16                	jmp    f0101c49 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0101c33:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c36:	8d 50 04             	lea    0x4(%eax),%edx
f0101c39:	89 55 14             	mov    %edx,0x14(%ebp)
f0101c3c:	8b 00                	mov    (%eax),%eax
f0101c3e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101c41:	89 c1                	mov    %eax,%ecx
f0101c43:	c1 f9 1f             	sar    $0x1f,%ecx
f0101c46:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101c49:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101c4c:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101c4f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101c54:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101c58:	79 74                	jns    f0101cce <vprintfmt+0x356>
				putch('-', putdat);
f0101c5a:	83 ec 08             	sub    $0x8,%esp
f0101c5d:	53                   	push   %ebx
f0101c5e:	6a 2d                	push   $0x2d
f0101c60:	ff d6                	call   *%esi
				num = -(long long) num;
f0101c62:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101c65:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101c68:	f7 d8                	neg    %eax
f0101c6a:	83 d2 00             	adc    $0x0,%edx
f0101c6d:	f7 da                	neg    %edx
f0101c6f:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101c72:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101c77:	eb 55                	jmp    f0101cce <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101c79:	8d 45 14             	lea    0x14(%ebp),%eax
f0101c7c:	e8 83 fc ff ff       	call   f0101904 <getuint>
			base = 10;
f0101c81:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101c86:	eb 46                	jmp    f0101cce <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101c88:	8d 45 14             	lea    0x14(%ebp),%eax
f0101c8b:	e8 74 fc ff ff       	call   f0101904 <getuint>
			base = 8;
f0101c90:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101c95:	eb 37                	jmp    f0101cce <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0101c97:	83 ec 08             	sub    $0x8,%esp
f0101c9a:	53                   	push   %ebx
f0101c9b:	6a 30                	push   $0x30
f0101c9d:	ff d6                	call   *%esi
			putch('x', putdat);
f0101c9f:	83 c4 08             	add    $0x8,%esp
f0101ca2:	53                   	push   %ebx
f0101ca3:	6a 78                	push   $0x78
f0101ca5:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101ca7:	8b 45 14             	mov    0x14(%ebp),%eax
f0101caa:	8d 50 04             	lea    0x4(%eax),%edx
f0101cad:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101cb0:	8b 00                	mov    (%eax),%eax
f0101cb2:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101cb7:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101cba:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101cbf:	eb 0d                	jmp    f0101cce <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101cc1:	8d 45 14             	lea    0x14(%ebp),%eax
f0101cc4:	e8 3b fc ff ff       	call   f0101904 <getuint>
			base = 16;
f0101cc9:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101cce:	83 ec 0c             	sub    $0xc,%esp
f0101cd1:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101cd5:	57                   	push   %edi
f0101cd6:	ff 75 e0             	pushl  -0x20(%ebp)
f0101cd9:	51                   	push   %ecx
f0101cda:	52                   	push   %edx
f0101cdb:	50                   	push   %eax
f0101cdc:	89 da                	mov    %ebx,%edx
f0101cde:	89 f0                	mov    %esi,%eax
f0101ce0:	e8 70 fb ff ff       	call   f0101855 <printnum>
			break;
f0101ce5:	83 c4 20             	add    $0x20,%esp
f0101ce8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101ceb:	e9 ae fc ff ff       	jmp    f010199e <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101cf0:	83 ec 08             	sub    $0x8,%esp
f0101cf3:	53                   	push   %ebx
f0101cf4:	51                   	push   %ecx
f0101cf5:	ff d6                	call   *%esi
			break;
f0101cf7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101cfa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101cfd:	e9 9c fc ff ff       	jmp    f010199e <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101d02:	83 ec 08             	sub    $0x8,%esp
f0101d05:	53                   	push   %ebx
f0101d06:	6a 25                	push   $0x25
f0101d08:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101d0a:	83 c4 10             	add    $0x10,%esp
f0101d0d:	eb 03                	jmp    f0101d12 <vprintfmt+0x39a>
f0101d0f:	83 ef 01             	sub    $0x1,%edi
f0101d12:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101d16:	75 f7                	jne    f0101d0f <vprintfmt+0x397>
f0101d18:	e9 81 fc ff ff       	jmp    f010199e <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101d1d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101d20:	5b                   	pop    %ebx
f0101d21:	5e                   	pop    %esi
f0101d22:	5f                   	pop    %edi
f0101d23:	5d                   	pop    %ebp
f0101d24:	c3                   	ret    

f0101d25 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101d25:	55                   	push   %ebp
f0101d26:	89 e5                	mov    %esp,%ebp
f0101d28:	83 ec 18             	sub    $0x18,%esp
f0101d2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d2e:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101d31:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101d34:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101d38:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101d3b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101d42:	85 c0                	test   %eax,%eax
f0101d44:	74 26                	je     f0101d6c <vsnprintf+0x47>
f0101d46:	85 d2                	test   %edx,%edx
f0101d48:	7e 22                	jle    f0101d6c <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101d4a:	ff 75 14             	pushl  0x14(%ebp)
f0101d4d:	ff 75 10             	pushl  0x10(%ebp)
f0101d50:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101d53:	50                   	push   %eax
f0101d54:	68 3e 19 10 f0       	push   $0xf010193e
f0101d59:	e8 1a fc ff ff       	call   f0101978 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101d5e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101d61:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101d64:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101d67:	83 c4 10             	add    $0x10,%esp
f0101d6a:	eb 05                	jmp    f0101d71 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101d6c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101d71:	c9                   	leave  
f0101d72:	c3                   	ret    

f0101d73 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101d73:	55                   	push   %ebp
f0101d74:	89 e5                	mov    %esp,%ebp
f0101d76:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101d79:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101d7c:	50                   	push   %eax
f0101d7d:	ff 75 10             	pushl  0x10(%ebp)
f0101d80:	ff 75 0c             	pushl  0xc(%ebp)
f0101d83:	ff 75 08             	pushl  0x8(%ebp)
f0101d86:	e8 9a ff ff ff       	call   f0101d25 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101d8b:	c9                   	leave  
f0101d8c:	c3                   	ret    

f0101d8d <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101d8d:	55                   	push   %ebp
f0101d8e:	89 e5                	mov    %esp,%ebp
f0101d90:	57                   	push   %edi
f0101d91:	56                   	push   %esi
f0101d92:	53                   	push   %ebx
f0101d93:	83 ec 0c             	sub    $0xc,%esp
f0101d96:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101d99:	85 c0                	test   %eax,%eax
f0101d9b:	74 11                	je     f0101dae <readline+0x21>
		cprintf("%s", prompt);
f0101d9d:	83 ec 08             	sub    $0x8,%esp
f0101da0:	50                   	push   %eax
f0101da1:	68 b4 2b 10 f0       	push   $0xf0102bb4
f0101da6:	e8 85 f7 ff ff       	call   f0101530 <cprintf>
f0101dab:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101dae:	83 ec 0c             	sub    $0xc,%esp
f0101db1:	6a 00                	push   $0x0
f0101db3:	e8 8e e8 ff ff       	call   f0100646 <iscons>
f0101db8:	89 c7                	mov    %eax,%edi
f0101dba:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101dbd:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101dc2:	e8 6e e8 ff ff       	call   f0100635 <getchar>
f0101dc7:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101dc9:	85 c0                	test   %eax,%eax
f0101dcb:	79 18                	jns    f0101de5 <readline+0x58>
			cprintf("read error: %e\n", c);
f0101dcd:	83 ec 08             	sub    $0x8,%esp
f0101dd0:	50                   	push   %eax
f0101dd1:	68 c0 2f 10 f0       	push   $0xf0102fc0
f0101dd6:	e8 55 f7 ff ff       	call   f0101530 <cprintf>
			return NULL;
f0101ddb:	83 c4 10             	add    $0x10,%esp
f0101dde:	b8 00 00 00 00       	mov    $0x0,%eax
f0101de3:	eb 79                	jmp    f0101e5e <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101de5:	83 f8 08             	cmp    $0x8,%eax
f0101de8:	0f 94 c2             	sete   %dl
f0101deb:	83 f8 7f             	cmp    $0x7f,%eax
f0101dee:	0f 94 c0             	sete   %al
f0101df1:	08 c2                	or     %al,%dl
f0101df3:	74 1a                	je     f0101e0f <readline+0x82>
f0101df5:	85 f6                	test   %esi,%esi
f0101df7:	7e 16                	jle    f0101e0f <readline+0x82>
			if (echoing)
f0101df9:	85 ff                	test   %edi,%edi
f0101dfb:	74 0d                	je     f0101e0a <readline+0x7d>
				cputchar('\b');
f0101dfd:	83 ec 0c             	sub    $0xc,%esp
f0101e00:	6a 08                	push   $0x8
f0101e02:	e8 1e e8 ff ff       	call   f0100625 <cputchar>
f0101e07:	83 c4 10             	add    $0x10,%esp
			i--;
f0101e0a:	83 ee 01             	sub    $0x1,%esi
f0101e0d:	eb b3                	jmp    f0101dc2 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101e0f:	83 fb 1f             	cmp    $0x1f,%ebx
f0101e12:	7e 23                	jle    f0101e37 <readline+0xaa>
f0101e14:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101e1a:	7f 1b                	jg     f0101e37 <readline+0xaa>
			if (echoing)
f0101e1c:	85 ff                	test   %edi,%edi
f0101e1e:	74 0c                	je     f0101e2c <readline+0x9f>
				cputchar(c);
f0101e20:	83 ec 0c             	sub    $0xc,%esp
f0101e23:	53                   	push   %ebx
f0101e24:	e8 fc e7 ff ff       	call   f0100625 <cputchar>
f0101e29:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101e2c:	88 9e 60 45 11 f0    	mov    %bl,-0xfeebaa0(%esi)
f0101e32:	8d 76 01             	lea    0x1(%esi),%esi
f0101e35:	eb 8b                	jmp    f0101dc2 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101e37:	83 fb 0a             	cmp    $0xa,%ebx
f0101e3a:	74 05                	je     f0101e41 <readline+0xb4>
f0101e3c:	83 fb 0d             	cmp    $0xd,%ebx
f0101e3f:	75 81                	jne    f0101dc2 <readline+0x35>
			if (echoing)
f0101e41:	85 ff                	test   %edi,%edi
f0101e43:	74 0d                	je     f0101e52 <readline+0xc5>
				cputchar('\n');
f0101e45:	83 ec 0c             	sub    $0xc,%esp
f0101e48:	6a 0a                	push   $0xa
f0101e4a:	e8 d6 e7 ff ff       	call   f0100625 <cputchar>
f0101e4f:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101e52:	c6 86 60 45 11 f0 00 	movb   $0x0,-0xfeebaa0(%esi)
			return buf;
f0101e59:	b8 60 45 11 f0       	mov    $0xf0114560,%eax
		}
	}
}
f0101e5e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101e61:	5b                   	pop    %ebx
f0101e62:	5e                   	pop    %esi
f0101e63:	5f                   	pop    %edi
f0101e64:	5d                   	pop    %ebp
f0101e65:	c3                   	ret    

f0101e66 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101e66:	55                   	push   %ebp
f0101e67:	89 e5                	mov    %esp,%ebp
f0101e69:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101e6c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101e71:	eb 03                	jmp    f0101e76 <strlen+0x10>
		n++;
f0101e73:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101e76:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101e7a:	75 f7                	jne    f0101e73 <strlen+0xd>
		n++;
	return n;
}
f0101e7c:	5d                   	pop    %ebp
f0101e7d:	c3                   	ret    

f0101e7e <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101e7e:	55                   	push   %ebp
f0101e7f:	89 e5                	mov    %esp,%ebp
f0101e81:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101e84:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101e87:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e8c:	eb 03                	jmp    f0101e91 <strnlen+0x13>
		n++;
f0101e8e:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101e91:	39 c2                	cmp    %eax,%edx
f0101e93:	74 08                	je     f0101e9d <strnlen+0x1f>
f0101e95:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101e99:	75 f3                	jne    f0101e8e <strnlen+0x10>
f0101e9b:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101e9d:	5d                   	pop    %ebp
f0101e9e:	c3                   	ret    

f0101e9f <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101e9f:	55                   	push   %ebp
f0101ea0:	89 e5                	mov    %esp,%ebp
f0101ea2:	53                   	push   %ebx
f0101ea3:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ea6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101ea9:	89 c2                	mov    %eax,%edx
f0101eab:	83 c2 01             	add    $0x1,%edx
f0101eae:	83 c1 01             	add    $0x1,%ecx
f0101eb1:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101eb5:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101eb8:	84 db                	test   %bl,%bl
f0101eba:	75 ef                	jne    f0101eab <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101ebc:	5b                   	pop    %ebx
f0101ebd:	5d                   	pop    %ebp
f0101ebe:	c3                   	ret    

f0101ebf <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101ebf:	55                   	push   %ebp
f0101ec0:	89 e5                	mov    %esp,%ebp
f0101ec2:	53                   	push   %ebx
f0101ec3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101ec6:	53                   	push   %ebx
f0101ec7:	e8 9a ff ff ff       	call   f0101e66 <strlen>
f0101ecc:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101ecf:	ff 75 0c             	pushl  0xc(%ebp)
f0101ed2:	01 d8                	add    %ebx,%eax
f0101ed4:	50                   	push   %eax
f0101ed5:	e8 c5 ff ff ff       	call   f0101e9f <strcpy>
	return dst;
}
f0101eda:	89 d8                	mov    %ebx,%eax
f0101edc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101edf:	c9                   	leave  
f0101ee0:	c3                   	ret    

f0101ee1 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101ee1:	55                   	push   %ebp
f0101ee2:	89 e5                	mov    %esp,%ebp
f0101ee4:	56                   	push   %esi
f0101ee5:	53                   	push   %ebx
f0101ee6:	8b 75 08             	mov    0x8(%ebp),%esi
f0101ee9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101eec:	89 f3                	mov    %esi,%ebx
f0101eee:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101ef1:	89 f2                	mov    %esi,%edx
f0101ef3:	eb 0f                	jmp    f0101f04 <strncpy+0x23>
		*dst++ = *src;
f0101ef5:	83 c2 01             	add    $0x1,%edx
f0101ef8:	0f b6 01             	movzbl (%ecx),%eax
f0101efb:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101efe:	80 39 01             	cmpb   $0x1,(%ecx)
f0101f01:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101f04:	39 da                	cmp    %ebx,%edx
f0101f06:	75 ed                	jne    f0101ef5 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101f08:	89 f0                	mov    %esi,%eax
f0101f0a:	5b                   	pop    %ebx
f0101f0b:	5e                   	pop    %esi
f0101f0c:	5d                   	pop    %ebp
f0101f0d:	c3                   	ret    

f0101f0e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101f0e:	55                   	push   %ebp
f0101f0f:	89 e5                	mov    %esp,%ebp
f0101f11:	56                   	push   %esi
f0101f12:	53                   	push   %ebx
f0101f13:	8b 75 08             	mov    0x8(%ebp),%esi
f0101f16:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101f19:	8b 55 10             	mov    0x10(%ebp),%edx
f0101f1c:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101f1e:	85 d2                	test   %edx,%edx
f0101f20:	74 21                	je     f0101f43 <strlcpy+0x35>
f0101f22:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101f26:	89 f2                	mov    %esi,%edx
f0101f28:	eb 09                	jmp    f0101f33 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101f2a:	83 c2 01             	add    $0x1,%edx
f0101f2d:	83 c1 01             	add    $0x1,%ecx
f0101f30:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101f33:	39 c2                	cmp    %eax,%edx
f0101f35:	74 09                	je     f0101f40 <strlcpy+0x32>
f0101f37:	0f b6 19             	movzbl (%ecx),%ebx
f0101f3a:	84 db                	test   %bl,%bl
f0101f3c:	75 ec                	jne    f0101f2a <strlcpy+0x1c>
f0101f3e:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101f40:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101f43:	29 f0                	sub    %esi,%eax
}
f0101f45:	5b                   	pop    %ebx
f0101f46:	5e                   	pop    %esi
f0101f47:	5d                   	pop    %ebp
f0101f48:	c3                   	ret    

f0101f49 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101f49:	55                   	push   %ebp
f0101f4a:	89 e5                	mov    %esp,%ebp
f0101f4c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101f4f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101f52:	eb 06                	jmp    f0101f5a <strcmp+0x11>
		p++, q++;
f0101f54:	83 c1 01             	add    $0x1,%ecx
f0101f57:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101f5a:	0f b6 01             	movzbl (%ecx),%eax
f0101f5d:	84 c0                	test   %al,%al
f0101f5f:	74 04                	je     f0101f65 <strcmp+0x1c>
f0101f61:	3a 02                	cmp    (%edx),%al
f0101f63:	74 ef                	je     f0101f54 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101f65:	0f b6 c0             	movzbl %al,%eax
f0101f68:	0f b6 12             	movzbl (%edx),%edx
f0101f6b:	29 d0                	sub    %edx,%eax
}
f0101f6d:	5d                   	pop    %ebp
f0101f6e:	c3                   	ret    

f0101f6f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101f6f:	55                   	push   %ebp
f0101f70:	89 e5                	mov    %esp,%ebp
f0101f72:	53                   	push   %ebx
f0101f73:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f76:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101f79:	89 c3                	mov    %eax,%ebx
f0101f7b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101f7e:	eb 06                	jmp    f0101f86 <strncmp+0x17>
		n--, p++, q++;
f0101f80:	83 c0 01             	add    $0x1,%eax
f0101f83:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101f86:	39 d8                	cmp    %ebx,%eax
f0101f88:	74 15                	je     f0101f9f <strncmp+0x30>
f0101f8a:	0f b6 08             	movzbl (%eax),%ecx
f0101f8d:	84 c9                	test   %cl,%cl
f0101f8f:	74 04                	je     f0101f95 <strncmp+0x26>
f0101f91:	3a 0a                	cmp    (%edx),%cl
f0101f93:	74 eb                	je     f0101f80 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101f95:	0f b6 00             	movzbl (%eax),%eax
f0101f98:	0f b6 12             	movzbl (%edx),%edx
f0101f9b:	29 d0                	sub    %edx,%eax
f0101f9d:	eb 05                	jmp    f0101fa4 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101f9f:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101fa4:	5b                   	pop    %ebx
f0101fa5:	5d                   	pop    %ebp
f0101fa6:	c3                   	ret    

f0101fa7 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101fa7:	55                   	push   %ebp
f0101fa8:	89 e5                	mov    %esp,%ebp
f0101faa:	8b 45 08             	mov    0x8(%ebp),%eax
f0101fad:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101fb1:	eb 07                	jmp    f0101fba <strchr+0x13>
		if (*s == c)
f0101fb3:	38 ca                	cmp    %cl,%dl
f0101fb5:	74 0f                	je     f0101fc6 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101fb7:	83 c0 01             	add    $0x1,%eax
f0101fba:	0f b6 10             	movzbl (%eax),%edx
f0101fbd:	84 d2                	test   %dl,%dl
f0101fbf:	75 f2                	jne    f0101fb3 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101fc1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101fc6:	5d                   	pop    %ebp
f0101fc7:	c3                   	ret    

f0101fc8 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101fc8:	55                   	push   %ebp
f0101fc9:	89 e5                	mov    %esp,%ebp
f0101fcb:	8b 45 08             	mov    0x8(%ebp),%eax
f0101fce:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101fd2:	eb 03                	jmp    f0101fd7 <strfind+0xf>
f0101fd4:	83 c0 01             	add    $0x1,%eax
f0101fd7:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101fda:	38 ca                	cmp    %cl,%dl
f0101fdc:	74 04                	je     f0101fe2 <strfind+0x1a>
f0101fde:	84 d2                	test   %dl,%dl
f0101fe0:	75 f2                	jne    f0101fd4 <strfind+0xc>
			break;
	return (char *) s;
}
f0101fe2:	5d                   	pop    %ebp
f0101fe3:	c3                   	ret    

f0101fe4 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101fe4:	55                   	push   %ebp
f0101fe5:	89 e5                	mov    %esp,%ebp
f0101fe7:	57                   	push   %edi
f0101fe8:	56                   	push   %esi
f0101fe9:	53                   	push   %ebx
f0101fea:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101fed:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101ff0:	85 c9                	test   %ecx,%ecx
f0101ff2:	74 36                	je     f010202a <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101ff4:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101ffa:	75 28                	jne    f0102024 <memset+0x40>
f0101ffc:	f6 c1 03             	test   $0x3,%cl
f0101fff:	75 23                	jne    f0102024 <memset+0x40>
		c &= 0xFF;
f0102001:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0102005:	89 d3                	mov    %edx,%ebx
f0102007:	c1 e3 08             	shl    $0x8,%ebx
f010200a:	89 d6                	mov    %edx,%esi
f010200c:	c1 e6 18             	shl    $0x18,%esi
f010200f:	89 d0                	mov    %edx,%eax
f0102011:	c1 e0 10             	shl    $0x10,%eax
f0102014:	09 f0                	or     %esi,%eax
f0102016:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0102018:	89 d8                	mov    %ebx,%eax
f010201a:	09 d0                	or     %edx,%eax
f010201c:	c1 e9 02             	shr    $0x2,%ecx
f010201f:	fc                   	cld    
f0102020:	f3 ab                	rep stos %eax,%es:(%edi)
f0102022:	eb 06                	jmp    f010202a <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0102024:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102027:	fc                   	cld    
f0102028:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010202a:	89 f8                	mov    %edi,%eax
f010202c:	5b                   	pop    %ebx
f010202d:	5e                   	pop    %esi
f010202e:	5f                   	pop    %edi
f010202f:	5d                   	pop    %ebp
f0102030:	c3                   	ret    

f0102031 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0102031:	55                   	push   %ebp
f0102032:	89 e5                	mov    %esp,%ebp
f0102034:	57                   	push   %edi
f0102035:	56                   	push   %esi
f0102036:	8b 45 08             	mov    0x8(%ebp),%eax
f0102039:	8b 75 0c             	mov    0xc(%ebp),%esi
f010203c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010203f:	39 c6                	cmp    %eax,%esi
f0102041:	73 35                	jae    f0102078 <memmove+0x47>
f0102043:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102046:	39 d0                	cmp    %edx,%eax
f0102048:	73 2e                	jae    f0102078 <memmove+0x47>
		s += n;
		d += n;
f010204a:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010204d:	89 d6                	mov    %edx,%esi
f010204f:	09 fe                	or     %edi,%esi
f0102051:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0102057:	75 13                	jne    f010206c <memmove+0x3b>
f0102059:	f6 c1 03             	test   $0x3,%cl
f010205c:	75 0e                	jne    f010206c <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010205e:	83 ef 04             	sub    $0x4,%edi
f0102061:	8d 72 fc             	lea    -0x4(%edx),%esi
f0102064:	c1 e9 02             	shr    $0x2,%ecx
f0102067:	fd                   	std    
f0102068:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010206a:	eb 09                	jmp    f0102075 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010206c:	83 ef 01             	sub    $0x1,%edi
f010206f:	8d 72 ff             	lea    -0x1(%edx),%esi
f0102072:	fd                   	std    
f0102073:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0102075:	fc                   	cld    
f0102076:	eb 1d                	jmp    f0102095 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102078:	89 f2                	mov    %esi,%edx
f010207a:	09 c2                	or     %eax,%edx
f010207c:	f6 c2 03             	test   $0x3,%dl
f010207f:	75 0f                	jne    f0102090 <memmove+0x5f>
f0102081:	f6 c1 03             	test   $0x3,%cl
f0102084:	75 0a                	jne    f0102090 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0102086:	c1 e9 02             	shr    $0x2,%ecx
f0102089:	89 c7                	mov    %eax,%edi
f010208b:	fc                   	cld    
f010208c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010208e:	eb 05                	jmp    f0102095 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0102090:	89 c7                	mov    %eax,%edi
f0102092:	fc                   	cld    
f0102093:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0102095:	5e                   	pop    %esi
f0102096:	5f                   	pop    %edi
f0102097:	5d                   	pop    %ebp
f0102098:	c3                   	ret    

f0102099 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0102099:	55                   	push   %ebp
f010209a:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010209c:	ff 75 10             	pushl  0x10(%ebp)
f010209f:	ff 75 0c             	pushl  0xc(%ebp)
f01020a2:	ff 75 08             	pushl  0x8(%ebp)
f01020a5:	e8 87 ff ff ff       	call   f0102031 <memmove>
}
f01020aa:	c9                   	leave  
f01020ab:	c3                   	ret    

f01020ac <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01020ac:	55                   	push   %ebp
f01020ad:	89 e5                	mov    %esp,%ebp
f01020af:	56                   	push   %esi
f01020b0:	53                   	push   %ebx
f01020b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01020b4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01020b7:	89 c6                	mov    %eax,%esi
f01020b9:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01020bc:	eb 1a                	jmp    f01020d8 <memcmp+0x2c>
		if (*s1 != *s2)
f01020be:	0f b6 08             	movzbl (%eax),%ecx
f01020c1:	0f b6 1a             	movzbl (%edx),%ebx
f01020c4:	38 d9                	cmp    %bl,%cl
f01020c6:	74 0a                	je     f01020d2 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01020c8:	0f b6 c1             	movzbl %cl,%eax
f01020cb:	0f b6 db             	movzbl %bl,%ebx
f01020ce:	29 d8                	sub    %ebx,%eax
f01020d0:	eb 0f                	jmp    f01020e1 <memcmp+0x35>
		s1++, s2++;
f01020d2:	83 c0 01             	add    $0x1,%eax
f01020d5:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01020d8:	39 f0                	cmp    %esi,%eax
f01020da:	75 e2                	jne    f01020be <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01020dc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01020e1:	5b                   	pop    %ebx
f01020e2:	5e                   	pop    %esi
f01020e3:	5d                   	pop    %ebp
f01020e4:	c3                   	ret    

f01020e5 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01020e5:	55                   	push   %ebp
f01020e6:	89 e5                	mov    %esp,%ebp
f01020e8:	53                   	push   %ebx
f01020e9:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01020ec:	89 c1                	mov    %eax,%ecx
f01020ee:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01020f1:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01020f5:	eb 0a                	jmp    f0102101 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01020f7:	0f b6 10             	movzbl (%eax),%edx
f01020fa:	39 da                	cmp    %ebx,%edx
f01020fc:	74 07                	je     f0102105 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01020fe:	83 c0 01             	add    $0x1,%eax
f0102101:	39 c8                	cmp    %ecx,%eax
f0102103:	72 f2                	jb     f01020f7 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0102105:	5b                   	pop    %ebx
f0102106:	5d                   	pop    %ebp
f0102107:	c3                   	ret    

f0102108 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0102108:	55                   	push   %ebp
f0102109:	89 e5                	mov    %esp,%ebp
f010210b:	57                   	push   %edi
f010210c:	56                   	push   %esi
f010210d:	53                   	push   %ebx
f010210e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102111:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102114:	eb 03                	jmp    f0102119 <strtol+0x11>
		s++;
f0102116:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102119:	0f b6 01             	movzbl (%ecx),%eax
f010211c:	3c 20                	cmp    $0x20,%al
f010211e:	74 f6                	je     f0102116 <strtol+0xe>
f0102120:	3c 09                	cmp    $0x9,%al
f0102122:	74 f2                	je     f0102116 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0102124:	3c 2b                	cmp    $0x2b,%al
f0102126:	75 0a                	jne    f0102132 <strtol+0x2a>
		s++;
f0102128:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010212b:	bf 00 00 00 00       	mov    $0x0,%edi
f0102130:	eb 11                	jmp    f0102143 <strtol+0x3b>
f0102132:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0102137:	3c 2d                	cmp    $0x2d,%al
f0102139:	75 08                	jne    f0102143 <strtol+0x3b>
		s++, neg = 1;
f010213b:	83 c1 01             	add    $0x1,%ecx
f010213e:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0102143:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0102149:	75 15                	jne    f0102160 <strtol+0x58>
f010214b:	80 39 30             	cmpb   $0x30,(%ecx)
f010214e:	75 10                	jne    f0102160 <strtol+0x58>
f0102150:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0102154:	75 7c                	jne    f01021d2 <strtol+0xca>
		s += 2, base = 16;
f0102156:	83 c1 02             	add    $0x2,%ecx
f0102159:	bb 10 00 00 00       	mov    $0x10,%ebx
f010215e:	eb 16                	jmp    f0102176 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0102160:	85 db                	test   %ebx,%ebx
f0102162:	75 12                	jne    f0102176 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0102164:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0102169:	80 39 30             	cmpb   $0x30,(%ecx)
f010216c:	75 08                	jne    f0102176 <strtol+0x6e>
		s++, base = 8;
f010216e:	83 c1 01             	add    $0x1,%ecx
f0102171:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0102176:	b8 00 00 00 00       	mov    $0x0,%eax
f010217b:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010217e:	0f b6 11             	movzbl (%ecx),%edx
f0102181:	8d 72 d0             	lea    -0x30(%edx),%esi
f0102184:	89 f3                	mov    %esi,%ebx
f0102186:	80 fb 09             	cmp    $0x9,%bl
f0102189:	77 08                	ja     f0102193 <strtol+0x8b>
			dig = *s - '0';
f010218b:	0f be d2             	movsbl %dl,%edx
f010218e:	83 ea 30             	sub    $0x30,%edx
f0102191:	eb 22                	jmp    f01021b5 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0102193:	8d 72 9f             	lea    -0x61(%edx),%esi
f0102196:	89 f3                	mov    %esi,%ebx
f0102198:	80 fb 19             	cmp    $0x19,%bl
f010219b:	77 08                	ja     f01021a5 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010219d:	0f be d2             	movsbl %dl,%edx
f01021a0:	83 ea 57             	sub    $0x57,%edx
f01021a3:	eb 10                	jmp    f01021b5 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01021a5:	8d 72 bf             	lea    -0x41(%edx),%esi
f01021a8:	89 f3                	mov    %esi,%ebx
f01021aa:	80 fb 19             	cmp    $0x19,%bl
f01021ad:	77 16                	ja     f01021c5 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01021af:	0f be d2             	movsbl %dl,%edx
f01021b2:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01021b5:	3b 55 10             	cmp    0x10(%ebp),%edx
f01021b8:	7d 0b                	jge    f01021c5 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01021ba:	83 c1 01             	add    $0x1,%ecx
f01021bd:	0f af 45 10          	imul   0x10(%ebp),%eax
f01021c1:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01021c3:	eb b9                	jmp    f010217e <strtol+0x76>

	if (endptr)
f01021c5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01021c9:	74 0d                	je     f01021d8 <strtol+0xd0>
		*endptr = (char *) s;
f01021cb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01021ce:	89 0e                	mov    %ecx,(%esi)
f01021d0:	eb 06                	jmp    f01021d8 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01021d2:	85 db                	test   %ebx,%ebx
f01021d4:	74 98                	je     f010216e <strtol+0x66>
f01021d6:	eb 9e                	jmp    f0102176 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01021d8:	89 c2                	mov    %eax,%edx
f01021da:	f7 da                	neg    %edx
f01021dc:	85 ff                	test   %edi,%edi
f01021de:	0f 45 c2             	cmovne %edx,%eax
}
f01021e1:	5b                   	pop    %ebx
f01021e2:	5e                   	pop    %esi
f01021e3:	5f                   	pop    %edi
f01021e4:	5d                   	pop    %ebp
f01021e5:	c3                   	ret    
f01021e6:	66 90                	xchg   %ax,%ax
f01021e8:	66 90                	xchg   %ax,%ax
f01021ea:	66 90                	xchg   %ax,%ax
f01021ec:	66 90                	xchg   %ax,%ax
f01021ee:	66 90                	xchg   %ax,%ax

f01021f0 <__udivdi3>:
f01021f0:	55                   	push   %ebp
f01021f1:	57                   	push   %edi
f01021f2:	56                   	push   %esi
f01021f3:	53                   	push   %ebx
f01021f4:	83 ec 1c             	sub    $0x1c,%esp
f01021f7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01021fb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01021ff:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0102203:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102207:	85 f6                	test   %esi,%esi
f0102209:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010220d:	89 ca                	mov    %ecx,%edx
f010220f:	89 f8                	mov    %edi,%eax
f0102211:	75 3d                	jne    f0102250 <__udivdi3+0x60>
f0102213:	39 cf                	cmp    %ecx,%edi
f0102215:	0f 87 c5 00 00 00    	ja     f01022e0 <__udivdi3+0xf0>
f010221b:	85 ff                	test   %edi,%edi
f010221d:	89 fd                	mov    %edi,%ebp
f010221f:	75 0b                	jne    f010222c <__udivdi3+0x3c>
f0102221:	b8 01 00 00 00       	mov    $0x1,%eax
f0102226:	31 d2                	xor    %edx,%edx
f0102228:	f7 f7                	div    %edi
f010222a:	89 c5                	mov    %eax,%ebp
f010222c:	89 c8                	mov    %ecx,%eax
f010222e:	31 d2                	xor    %edx,%edx
f0102230:	f7 f5                	div    %ebp
f0102232:	89 c1                	mov    %eax,%ecx
f0102234:	89 d8                	mov    %ebx,%eax
f0102236:	89 cf                	mov    %ecx,%edi
f0102238:	f7 f5                	div    %ebp
f010223a:	89 c3                	mov    %eax,%ebx
f010223c:	89 d8                	mov    %ebx,%eax
f010223e:	89 fa                	mov    %edi,%edx
f0102240:	83 c4 1c             	add    $0x1c,%esp
f0102243:	5b                   	pop    %ebx
f0102244:	5e                   	pop    %esi
f0102245:	5f                   	pop    %edi
f0102246:	5d                   	pop    %ebp
f0102247:	c3                   	ret    
f0102248:	90                   	nop
f0102249:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102250:	39 ce                	cmp    %ecx,%esi
f0102252:	77 74                	ja     f01022c8 <__udivdi3+0xd8>
f0102254:	0f bd fe             	bsr    %esi,%edi
f0102257:	83 f7 1f             	xor    $0x1f,%edi
f010225a:	0f 84 98 00 00 00    	je     f01022f8 <__udivdi3+0x108>
f0102260:	bb 20 00 00 00       	mov    $0x20,%ebx
f0102265:	89 f9                	mov    %edi,%ecx
f0102267:	89 c5                	mov    %eax,%ebp
f0102269:	29 fb                	sub    %edi,%ebx
f010226b:	d3 e6                	shl    %cl,%esi
f010226d:	89 d9                	mov    %ebx,%ecx
f010226f:	d3 ed                	shr    %cl,%ebp
f0102271:	89 f9                	mov    %edi,%ecx
f0102273:	d3 e0                	shl    %cl,%eax
f0102275:	09 ee                	or     %ebp,%esi
f0102277:	89 d9                	mov    %ebx,%ecx
f0102279:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010227d:	89 d5                	mov    %edx,%ebp
f010227f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102283:	d3 ed                	shr    %cl,%ebp
f0102285:	89 f9                	mov    %edi,%ecx
f0102287:	d3 e2                	shl    %cl,%edx
f0102289:	89 d9                	mov    %ebx,%ecx
f010228b:	d3 e8                	shr    %cl,%eax
f010228d:	09 c2                	or     %eax,%edx
f010228f:	89 d0                	mov    %edx,%eax
f0102291:	89 ea                	mov    %ebp,%edx
f0102293:	f7 f6                	div    %esi
f0102295:	89 d5                	mov    %edx,%ebp
f0102297:	89 c3                	mov    %eax,%ebx
f0102299:	f7 64 24 0c          	mull   0xc(%esp)
f010229d:	39 d5                	cmp    %edx,%ebp
f010229f:	72 10                	jb     f01022b1 <__udivdi3+0xc1>
f01022a1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01022a5:	89 f9                	mov    %edi,%ecx
f01022a7:	d3 e6                	shl    %cl,%esi
f01022a9:	39 c6                	cmp    %eax,%esi
f01022ab:	73 07                	jae    f01022b4 <__udivdi3+0xc4>
f01022ad:	39 d5                	cmp    %edx,%ebp
f01022af:	75 03                	jne    f01022b4 <__udivdi3+0xc4>
f01022b1:	83 eb 01             	sub    $0x1,%ebx
f01022b4:	31 ff                	xor    %edi,%edi
f01022b6:	89 d8                	mov    %ebx,%eax
f01022b8:	89 fa                	mov    %edi,%edx
f01022ba:	83 c4 1c             	add    $0x1c,%esp
f01022bd:	5b                   	pop    %ebx
f01022be:	5e                   	pop    %esi
f01022bf:	5f                   	pop    %edi
f01022c0:	5d                   	pop    %ebp
f01022c1:	c3                   	ret    
f01022c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01022c8:	31 ff                	xor    %edi,%edi
f01022ca:	31 db                	xor    %ebx,%ebx
f01022cc:	89 d8                	mov    %ebx,%eax
f01022ce:	89 fa                	mov    %edi,%edx
f01022d0:	83 c4 1c             	add    $0x1c,%esp
f01022d3:	5b                   	pop    %ebx
f01022d4:	5e                   	pop    %esi
f01022d5:	5f                   	pop    %edi
f01022d6:	5d                   	pop    %ebp
f01022d7:	c3                   	ret    
f01022d8:	90                   	nop
f01022d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01022e0:	89 d8                	mov    %ebx,%eax
f01022e2:	f7 f7                	div    %edi
f01022e4:	31 ff                	xor    %edi,%edi
f01022e6:	89 c3                	mov    %eax,%ebx
f01022e8:	89 d8                	mov    %ebx,%eax
f01022ea:	89 fa                	mov    %edi,%edx
f01022ec:	83 c4 1c             	add    $0x1c,%esp
f01022ef:	5b                   	pop    %ebx
f01022f0:	5e                   	pop    %esi
f01022f1:	5f                   	pop    %edi
f01022f2:	5d                   	pop    %ebp
f01022f3:	c3                   	ret    
f01022f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01022f8:	39 ce                	cmp    %ecx,%esi
f01022fa:	72 0c                	jb     f0102308 <__udivdi3+0x118>
f01022fc:	31 db                	xor    %ebx,%ebx
f01022fe:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0102302:	0f 87 34 ff ff ff    	ja     f010223c <__udivdi3+0x4c>
f0102308:	bb 01 00 00 00       	mov    $0x1,%ebx
f010230d:	e9 2a ff ff ff       	jmp    f010223c <__udivdi3+0x4c>
f0102312:	66 90                	xchg   %ax,%ax
f0102314:	66 90                	xchg   %ax,%ax
f0102316:	66 90                	xchg   %ax,%ax
f0102318:	66 90                	xchg   %ax,%ax
f010231a:	66 90                	xchg   %ax,%ax
f010231c:	66 90                	xchg   %ax,%ax
f010231e:	66 90                	xchg   %ax,%ax

f0102320 <__umoddi3>:
f0102320:	55                   	push   %ebp
f0102321:	57                   	push   %edi
f0102322:	56                   	push   %esi
f0102323:	53                   	push   %ebx
f0102324:	83 ec 1c             	sub    $0x1c,%esp
f0102327:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010232b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010232f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0102333:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102337:	85 d2                	test   %edx,%edx
f0102339:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010233d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102341:	89 f3                	mov    %esi,%ebx
f0102343:	89 3c 24             	mov    %edi,(%esp)
f0102346:	89 74 24 04          	mov    %esi,0x4(%esp)
f010234a:	75 1c                	jne    f0102368 <__umoddi3+0x48>
f010234c:	39 f7                	cmp    %esi,%edi
f010234e:	76 50                	jbe    f01023a0 <__umoddi3+0x80>
f0102350:	89 c8                	mov    %ecx,%eax
f0102352:	89 f2                	mov    %esi,%edx
f0102354:	f7 f7                	div    %edi
f0102356:	89 d0                	mov    %edx,%eax
f0102358:	31 d2                	xor    %edx,%edx
f010235a:	83 c4 1c             	add    $0x1c,%esp
f010235d:	5b                   	pop    %ebx
f010235e:	5e                   	pop    %esi
f010235f:	5f                   	pop    %edi
f0102360:	5d                   	pop    %ebp
f0102361:	c3                   	ret    
f0102362:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102368:	39 f2                	cmp    %esi,%edx
f010236a:	89 d0                	mov    %edx,%eax
f010236c:	77 52                	ja     f01023c0 <__umoddi3+0xa0>
f010236e:	0f bd ea             	bsr    %edx,%ebp
f0102371:	83 f5 1f             	xor    $0x1f,%ebp
f0102374:	75 5a                	jne    f01023d0 <__umoddi3+0xb0>
f0102376:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010237a:	0f 82 e0 00 00 00    	jb     f0102460 <__umoddi3+0x140>
f0102380:	39 0c 24             	cmp    %ecx,(%esp)
f0102383:	0f 86 d7 00 00 00    	jbe    f0102460 <__umoddi3+0x140>
f0102389:	8b 44 24 08          	mov    0x8(%esp),%eax
f010238d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0102391:	83 c4 1c             	add    $0x1c,%esp
f0102394:	5b                   	pop    %ebx
f0102395:	5e                   	pop    %esi
f0102396:	5f                   	pop    %edi
f0102397:	5d                   	pop    %ebp
f0102398:	c3                   	ret    
f0102399:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01023a0:	85 ff                	test   %edi,%edi
f01023a2:	89 fd                	mov    %edi,%ebp
f01023a4:	75 0b                	jne    f01023b1 <__umoddi3+0x91>
f01023a6:	b8 01 00 00 00       	mov    $0x1,%eax
f01023ab:	31 d2                	xor    %edx,%edx
f01023ad:	f7 f7                	div    %edi
f01023af:	89 c5                	mov    %eax,%ebp
f01023b1:	89 f0                	mov    %esi,%eax
f01023b3:	31 d2                	xor    %edx,%edx
f01023b5:	f7 f5                	div    %ebp
f01023b7:	89 c8                	mov    %ecx,%eax
f01023b9:	f7 f5                	div    %ebp
f01023bb:	89 d0                	mov    %edx,%eax
f01023bd:	eb 99                	jmp    f0102358 <__umoddi3+0x38>
f01023bf:	90                   	nop
f01023c0:	89 c8                	mov    %ecx,%eax
f01023c2:	89 f2                	mov    %esi,%edx
f01023c4:	83 c4 1c             	add    $0x1c,%esp
f01023c7:	5b                   	pop    %ebx
f01023c8:	5e                   	pop    %esi
f01023c9:	5f                   	pop    %edi
f01023ca:	5d                   	pop    %ebp
f01023cb:	c3                   	ret    
f01023cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01023d0:	8b 34 24             	mov    (%esp),%esi
f01023d3:	bf 20 00 00 00       	mov    $0x20,%edi
f01023d8:	89 e9                	mov    %ebp,%ecx
f01023da:	29 ef                	sub    %ebp,%edi
f01023dc:	d3 e0                	shl    %cl,%eax
f01023de:	89 f9                	mov    %edi,%ecx
f01023e0:	89 f2                	mov    %esi,%edx
f01023e2:	d3 ea                	shr    %cl,%edx
f01023e4:	89 e9                	mov    %ebp,%ecx
f01023e6:	09 c2                	or     %eax,%edx
f01023e8:	89 d8                	mov    %ebx,%eax
f01023ea:	89 14 24             	mov    %edx,(%esp)
f01023ed:	89 f2                	mov    %esi,%edx
f01023ef:	d3 e2                	shl    %cl,%edx
f01023f1:	89 f9                	mov    %edi,%ecx
f01023f3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01023f7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01023fb:	d3 e8                	shr    %cl,%eax
f01023fd:	89 e9                	mov    %ebp,%ecx
f01023ff:	89 c6                	mov    %eax,%esi
f0102401:	d3 e3                	shl    %cl,%ebx
f0102403:	89 f9                	mov    %edi,%ecx
f0102405:	89 d0                	mov    %edx,%eax
f0102407:	d3 e8                	shr    %cl,%eax
f0102409:	89 e9                	mov    %ebp,%ecx
f010240b:	09 d8                	or     %ebx,%eax
f010240d:	89 d3                	mov    %edx,%ebx
f010240f:	89 f2                	mov    %esi,%edx
f0102411:	f7 34 24             	divl   (%esp)
f0102414:	89 d6                	mov    %edx,%esi
f0102416:	d3 e3                	shl    %cl,%ebx
f0102418:	f7 64 24 04          	mull   0x4(%esp)
f010241c:	39 d6                	cmp    %edx,%esi
f010241e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102422:	89 d1                	mov    %edx,%ecx
f0102424:	89 c3                	mov    %eax,%ebx
f0102426:	72 08                	jb     f0102430 <__umoddi3+0x110>
f0102428:	75 11                	jne    f010243b <__umoddi3+0x11b>
f010242a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010242e:	73 0b                	jae    f010243b <__umoddi3+0x11b>
f0102430:	2b 44 24 04          	sub    0x4(%esp),%eax
f0102434:	1b 14 24             	sbb    (%esp),%edx
f0102437:	89 d1                	mov    %edx,%ecx
f0102439:	89 c3                	mov    %eax,%ebx
f010243b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010243f:	29 da                	sub    %ebx,%edx
f0102441:	19 ce                	sbb    %ecx,%esi
f0102443:	89 f9                	mov    %edi,%ecx
f0102445:	89 f0                	mov    %esi,%eax
f0102447:	d3 e0                	shl    %cl,%eax
f0102449:	89 e9                	mov    %ebp,%ecx
f010244b:	d3 ea                	shr    %cl,%edx
f010244d:	89 e9                	mov    %ebp,%ecx
f010244f:	d3 ee                	shr    %cl,%esi
f0102451:	09 d0                	or     %edx,%eax
f0102453:	89 f2                	mov    %esi,%edx
f0102455:	83 c4 1c             	add    $0x1c,%esp
f0102458:	5b                   	pop    %ebx
f0102459:	5e                   	pop    %esi
f010245a:	5f                   	pop    %edi
f010245b:	5d                   	pop    %ebp
f010245c:	c3                   	ret    
f010245d:	8d 76 00             	lea    0x0(%esi),%esi
f0102460:	29 f9                	sub    %edi,%ecx
f0102462:	19 d6                	sbb    %edx,%esi
f0102464:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102468:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010246c:	e9 18 ff ff ff       	jmp    f0102389 <__umoddi3+0x69>

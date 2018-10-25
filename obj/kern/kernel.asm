
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
f0100058:	e8 82 1f 00 00       	call   f0101fdf <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 bb 04 00 00       	call   f010051d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 80 24 10 f0       	push   $0xf0102480
f010006f:	e8 b7 14 00 00       	call   f010152b <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 89 0d 00 00       	call   f0100e02 <mem_init>
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
f01000b5:	e8 71 14 00 00       	call   f010152b <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 41 14 00 00       	call   f0101505 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 89 27 10 f0 	movl   $0xf0102789,(%esp)
f01000cb:	e8 5b 14 00 00       	call   f010152b <cprintf>
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
f01000f7:	e8 2f 14 00 00       	call   f010152b <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 fd 13 00 00       	call   f0101505 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 89 27 10 f0 	movl   $0xf0102789,(%esp)
f010010f:	e8 17 14 00 00       	call   f010152b <cprintf>
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
f0100265:	e8 c1 12 00 00       	call   f010152b <cprintf>
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
f0100441:	e8 e6 1b 00 00       	call   f010202c <memmove>
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
f0100615:	e8 11 0f 00 00       	call   f010152b <cprintf>
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
f0100665:	e8 c1 0e 00 00       	call   f010152b <cprintf>
f010066a:	83 c4 0c             	add    $0xc,%esp
f010066d:	68 d8 27 10 f0       	push   $0xf01027d8
f0100672:	68 4c 27 10 f0       	push   $0xf010274c
f0100677:	68 43 27 10 f0       	push   $0xf0102743
f010067c:	e8 aa 0e 00 00       	call   f010152b <cprintf>
f0100681:	83 c4 0c             	add    $0xc,%esp
f0100684:	68 00 28 10 f0       	push   $0xf0102800
f0100689:	68 55 27 10 f0       	push   $0xf0102755
f010068e:	68 43 27 10 f0       	push   $0xf0102743
f0100693:	e8 93 0e 00 00       	call   f010152b <cprintf>
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
f01006aa:	e8 7c 0e 00 00       	call   f010152b <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006af:	83 c4 08             	add    $0x8,%esp
f01006b2:	68 0c 00 10 00       	push   $0x10000c
f01006b7:	68 28 28 10 f0       	push   $0xf0102828
f01006bc:	e8 6a 0e 00 00       	call   f010152b <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006c1:	83 c4 0c             	add    $0xc,%esp
f01006c4:	68 0c 00 10 00       	push   $0x10000c
f01006c9:	68 0c 00 10 f0       	push   $0xf010000c
f01006ce:	68 50 28 10 f0       	push   $0xf0102850
f01006d3:	e8 53 0e 00 00       	call   f010152b <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d8:	83 c4 0c             	add    $0xc,%esp
f01006db:	68 71 24 10 00       	push   $0x102471
f01006e0:	68 71 24 10 f0       	push   $0xf0102471
f01006e5:	68 74 28 10 f0       	push   $0xf0102874
f01006ea:	e8 3c 0e 00 00       	call   f010152b <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ef:	83 c4 0c             	add    $0xc,%esp
f01006f2:	68 00 43 11 00       	push   $0x114300
f01006f7:	68 00 43 11 f0       	push   $0xf0114300
f01006fc:	68 98 28 10 f0       	push   $0xf0102898
f0100701:	e8 25 0e 00 00       	call   f010152b <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100706:	83 c4 0c             	add    $0xc,%esp
f0100709:	68 70 49 11 00       	push   $0x114970
f010070e:	68 70 49 11 f0       	push   $0xf0114970
f0100713:	68 bc 28 10 f0       	push   $0xf01028bc
f0100718:	e8 0e 0e 00 00       	call   f010152b <cprintf>
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
f0100743:	e8 e3 0d 00 00       	call   f010152b <cprintf>
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
f010075f:	e8 c7 0d 00 00       	call   f010152b <cprintf>
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
f0100785:	e8 a1 0d 00 00       	call   f010152b <cprintf>
	debuginfo_eip((uintptr_t)eip,&info);
f010078a:	83 c4 18             	add    $0x18,%esp
f010078d:	57                   	push   %edi
f010078e:	56                   	push   %esi
f010078f:	e8 a1 0e 00 00       	call   f0101635 <debuginfo_eip>
	cprintf("%s:%d", info.eip_file, info.eip_line);
f0100794:	83 c4 0c             	add    $0xc,%esp
f0100797:	ff 75 d4             	pushl  -0x2c(%ebp)
f010079a:	ff 75 d0             	pushl  -0x30(%ebp)
f010079d:	68 8b 27 10 f0       	push   $0xf010278b
f01007a2:	e8 84 0d 00 00       	call   f010152b <cprintf>
        cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name,info.eip_fn_addr);
f01007a7:	ff 75 e0             	pushl  -0x20(%ebp)
f01007aa:	ff 75 d8             	pushl  -0x28(%ebp)
f01007ad:	ff 75 dc             	pushl  -0x24(%ebp)
f01007b0:	68 91 27 10 f0       	push   $0xf0102791
f01007b5:	e8 71 0d 00 00       	call   f010152b <cprintf>
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
f01007de:	e8 48 0d 00 00       	call   f010152b <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007e3:	c7 04 24 68 29 10 f0 	movl   $0xf0102968,(%esp)
f01007ea:	e8 3c 0d 00 00       	call   f010152b <cprintf>
f01007ef:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007f2:	83 ec 0c             	sub    $0xc,%esp
f01007f5:	68 9c 27 10 f0       	push   $0xf010279c
f01007fa:	e8 89 15 00 00       	call   f0101d88 <readline>
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
f0100833:	e8 6a 17 00 00       	call   f0101fa2 <strchr>
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
f0100853:	e8 d3 0c 00 00       	call   f010152b <cprintf>
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
f010087c:	e8 21 17 00 00       	call   f0101fa2 <strchr>
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
f01008af:	e8 90 16 00 00       	call   f0101f44 <strcmp>
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
f01008ef:	e8 37 0c 00 00       	call   f010152b <cprintf>
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
f0100a6e:	e8 6c 15 00 00       	call   f0101fdf <memset>
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
f0100d62:	e8 c4 07 00 00       	call   f010152b <cprintf>
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
f0100dad:	e8 2d 12 00 00       	call   f0101fdf <memset>
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

	// if(pp->pp_link != 0  || pp->pp_ref != 0)
	if(pp->pp_ref){
f0100dc5:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100dca:	74 17                	je     f0100de3 <page_free+0x27>
		panic("can't free the page");
f0100dcc:	83 ec 04             	sub    $0x4,%esp
f0100dcf:	68 3f 2c 10 f0       	push   $0xf0102c3f
f0100dd4:	68 59 01 00 00       	push   $0x159
f0100dd9:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100dde:	e8 a8 f2 ff ff       	call   f010008b <_panic>
		return;
	}
	//	cprinf("can't free the page");
	//pp->pp_link = page_free_list->pp_link;	
	pp->pp_link = page_free_list;
f0100de3:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
f0100de9:	89 10                	mov    %edx,(%eax)
	//page_free_list->pp_link = pp;
	// page_free_list = &pp;
	page_free_list = pp;
f0100deb:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
	//pp->pp_ref = 0;
	cprintf("page_free\r\n");
f0100df0:	83 ec 0c             	sub    $0xc,%esp
f0100df3:	68 53 2c 10 f0       	push   $0xf0102c53
f0100df8:	e8 2e 07 00 00       	call   f010152b <cprintf>
}
f0100dfd:	83 c4 10             	add    $0x10,%esp
f0100e00:	c9                   	leave  
f0100e01:	c3                   	ret    

f0100e02 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100e02:	55                   	push   %ebp
f0100e03:	89 e5                	mov    %esp,%ebp
f0100e05:	57                   	push   %edi
f0100e06:	56                   	push   %esi
f0100e07:	53                   	push   %ebx
f0100e08:	83 ec 28             	sub    $0x28,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100e0b:	6a 15                	push   $0x15
f0100e0d:	e8 b2 06 00 00       	call   f01014c4 <mc146818_read>
f0100e12:	89 c3                	mov    %eax,%ebx
f0100e14:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0100e1b:	e8 a4 06 00 00       	call   f01014c4 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100e20:	c1 e0 08             	shl    $0x8,%eax
f0100e23:	09 d8                	or     %ebx,%eax
f0100e25:	c1 e0 0a             	shl    $0xa,%eax
f0100e28:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100e2e:	85 c0                	test   %eax,%eax
f0100e30:	0f 48 c2             	cmovs  %edx,%eax
f0100e33:	c1 f8 0c             	sar    $0xc,%eax
f0100e36:	a3 40 45 11 f0       	mov    %eax,0xf0114540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100e3b:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0100e42:	e8 7d 06 00 00       	call   f01014c4 <mc146818_read>
f0100e47:	89 c3                	mov    %eax,%ebx
f0100e49:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0100e50:	e8 6f 06 00 00       	call   f01014c4 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0100e55:	c1 e0 08             	shl    $0x8,%eax
f0100e58:	09 d8                	or     %ebx,%eax
f0100e5a:	c1 e0 0a             	shl    $0xa,%eax
f0100e5d:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100e63:	83 c4 10             	add    $0x10,%esp
f0100e66:	85 c0                	test   %eax,%eax
f0100e68:	0f 48 c2             	cmovs  %edx,%eax
f0100e6b:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0100e6e:	85 c0                	test   %eax,%eax
f0100e70:	74 0e                	je     f0100e80 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0100e72:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0100e78:	89 15 64 49 11 f0    	mov    %edx,0xf0114964
f0100e7e:	eb 0c                	jmp    f0100e8c <mem_init+0x8a>
	else
		npages = npages_basemem;
f0100e80:	8b 15 40 45 11 f0    	mov    0xf0114540,%edx
f0100e86:	89 15 64 49 11 f0    	mov    %edx,0xf0114964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100e8c:	c1 e0 0c             	shl    $0xc,%eax
f0100e8f:	c1 e8 0a             	shr    $0xa,%eax
f0100e92:	50                   	push   %eax
f0100e93:	a1 40 45 11 f0       	mov    0xf0114540,%eax
f0100e98:	c1 e0 0c             	shl    $0xc,%eax
f0100e9b:	c1 e8 0a             	shr    $0xa,%eax
f0100e9e:	50                   	push   %eax
f0100e9f:	a1 64 49 11 f0       	mov    0xf0114964,%eax
f0100ea4:	c1 e0 0c             	shl    $0xc,%eax
f0100ea7:	c1 e8 0a             	shr    $0xa,%eax
f0100eaa:	50                   	push   %eax
f0100eab:	68 ac 2a 10 f0       	push   $0xf0102aac
f0100eb0:	e8 76 06 00 00       	call   f010152b <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100eb5:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100eba:	e8 45 fa ff ff       	call   f0100904 <boot_alloc>
f0100ebf:	a3 68 49 11 f0       	mov    %eax,0xf0114968
	memset(kern_pgdir, 0, PGSIZE);
f0100ec4:	83 c4 0c             	add    $0xc,%esp
f0100ec7:	68 00 10 00 00       	push   $0x1000
f0100ecc:	6a 00                	push   $0x0
f0100ece:	50                   	push   %eax
f0100ecf:	e8 0b 11 00 00       	call   f0101fdf <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100ed4:	a1 68 49 11 f0       	mov    0xf0114968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ed9:	83 c4 10             	add    $0x10,%esp
f0100edc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100ee1:	77 15                	ja     f0100ef8 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ee3:	50                   	push   %eax
f0100ee4:	68 e8 2a 10 f0       	push   $0xf0102ae8
f0100ee9:	68 8d 00 00 00       	push   $0x8d
f0100eee:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100ef3:	e8 93 f1 ff ff       	call   f010008b <_panic>
f0100ef8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100efe:	83 ca 05             	or     $0x5,%edx
f0100f01:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f0100f07:	a1 64 49 11 f0       	mov    0xf0114964,%eax
f0100f0c:	c1 e0 03             	shl    $0x3,%eax
f0100f0f:	e8 f0 f9 ff ff       	call   f0100904 <boot_alloc>
f0100f14:	a3 6c 49 11 f0       	mov    %eax,0xf011496c
	memset(pages,0,npages * sizeof(struct PageInfo));
f0100f19:	83 ec 04             	sub    $0x4,%esp
f0100f1c:	8b 0d 64 49 11 f0    	mov    0xf0114964,%ecx
f0100f22:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0100f29:	52                   	push   %edx
f0100f2a:	6a 00                	push   $0x0
f0100f2c:	50                   	push   %eax
f0100f2d:	e8 ad 10 00 00       	call   f0101fdf <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0100f32:	e8 1f fd ff ff       	call   f0100c56 <page_init>

	check_page_free_list(1);
f0100f37:	b8 01 00 00 00       	mov    $0x1,%eax
f0100f3c:	e8 61 fa ff ff       	call   f01009a2 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0100f41:	83 c4 10             	add    $0x10,%esp
f0100f44:	83 3d 6c 49 11 f0 00 	cmpl   $0x0,0xf011496c
f0100f4b:	75 17                	jne    f0100f64 <mem_init+0x162>
		panic("'pages' is a null pointer!");
f0100f4d:	83 ec 04             	sub    $0x4,%esp
f0100f50:	68 5f 2c 10 f0       	push   $0xf0102c5f
f0100f55:	68 40 02 00 00       	push   $0x240
f0100f5a:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100f5f:	e8 27 f1 ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100f64:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100f69:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100f6e:	eb 05                	jmp    f0100f75 <mem_init+0x173>
		++nfree;
f0100f70:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100f73:	8b 00                	mov    (%eax),%eax
f0100f75:	85 c0                	test   %eax,%eax
f0100f77:	75 f7                	jne    f0100f70 <mem_init+0x16e>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0100f79:	83 ec 0c             	sub    $0xc,%esp
f0100f7c:	6a 00                	push   $0x0
f0100f7e:	e8 b3 fd ff ff       	call   f0100d36 <page_alloc>
f0100f83:	89 c7                	mov    %eax,%edi
f0100f85:	83 c4 10             	add    $0x10,%esp
f0100f88:	85 c0                	test   %eax,%eax
f0100f8a:	75 19                	jne    f0100fa5 <mem_init+0x1a3>
f0100f8c:	68 7a 2c 10 f0       	push   $0xf0102c7a
f0100f91:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100f96:	68 48 02 00 00       	push   $0x248
f0100f9b:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100fa0:	e8 e6 f0 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0100fa5:	83 ec 0c             	sub    $0xc,%esp
f0100fa8:	6a 00                	push   $0x0
f0100faa:	e8 87 fd ff ff       	call   f0100d36 <page_alloc>
f0100faf:	89 c6                	mov    %eax,%esi
f0100fb1:	83 c4 10             	add    $0x10,%esp
f0100fb4:	85 c0                	test   %eax,%eax
f0100fb6:	75 19                	jne    f0100fd1 <mem_init+0x1cf>
f0100fb8:	68 90 2c 10 f0       	push   $0xf0102c90
f0100fbd:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100fc2:	68 49 02 00 00       	push   $0x249
f0100fc7:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100fcc:	e8 ba f0 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0100fd1:	83 ec 0c             	sub    $0xc,%esp
f0100fd4:	6a 00                	push   $0x0
f0100fd6:	e8 5b fd ff ff       	call   f0100d36 <page_alloc>
f0100fdb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100fde:	83 c4 10             	add    $0x10,%esp
f0100fe1:	85 c0                	test   %eax,%eax
f0100fe3:	75 19                	jne    f0100ffe <mem_init+0x1fc>
f0100fe5:	68 a6 2c 10 f0       	push   $0xf0102ca6
f0100fea:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0100fef:	68 4a 02 00 00       	push   $0x24a
f0100ff4:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100ff9:	e8 8d f0 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0100ffe:	39 f7                	cmp    %esi,%edi
f0101000:	75 19                	jne    f010101b <mem_init+0x219>
f0101002:	68 bc 2c 10 f0       	push   $0xf0102cbc
f0101007:	68 a2 2b 10 f0       	push   $0xf0102ba2
f010100c:	68 4d 02 00 00       	push   $0x24d
f0101011:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101016:	e8 70 f0 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010101b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010101e:	39 c7                	cmp    %eax,%edi
f0101020:	74 04                	je     f0101026 <mem_init+0x224>
f0101022:	39 c6                	cmp    %eax,%esi
f0101024:	75 19                	jne    f010103f <mem_init+0x23d>
f0101026:	68 0c 2b 10 f0       	push   $0xf0102b0c
f010102b:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101030:	68 4e 02 00 00       	push   $0x24e
f0101035:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010103a:	e8 4c f0 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010103f:	8b 0d 6c 49 11 f0    	mov    0xf011496c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101045:	8b 15 64 49 11 f0    	mov    0xf0114964,%edx
f010104b:	c1 e2 0c             	shl    $0xc,%edx
f010104e:	89 f8                	mov    %edi,%eax
f0101050:	29 c8                	sub    %ecx,%eax
f0101052:	c1 f8 03             	sar    $0x3,%eax
f0101055:	c1 e0 0c             	shl    $0xc,%eax
f0101058:	39 d0                	cmp    %edx,%eax
f010105a:	72 19                	jb     f0101075 <mem_init+0x273>
f010105c:	68 ce 2c 10 f0       	push   $0xf0102cce
f0101061:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101066:	68 4f 02 00 00       	push   $0x24f
f010106b:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101070:	e8 16 f0 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101075:	89 f0                	mov    %esi,%eax
f0101077:	29 c8                	sub    %ecx,%eax
f0101079:	c1 f8 03             	sar    $0x3,%eax
f010107c:	c1 e0 0c             	shl    $0xc,%eax
f010107f:	39 c2                	cmp    %eax,%edx
f0101081:	77 19                	ja     f010109c <mem_init+0x29a>
f0101083:	68 eb 2c 10 f0       	push   $0xf0102ceb
f0101088:	68 a2 2b 10 f0       	push   $0xf0102ba2
f010108d:	68 50 02 00 00       	push   $0x250
f0101092:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101097:	e8 ef ef ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010109c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010109f:	29 c8                	sub    %ecx,%eax
f01010a1:	c1 f8 03             	sar    $0x3,%eax
f01010a4:	c1 e0 0c             	shl    $0xc,%eax
f01010a7:	39 c2                	cmp    %eax,%edx
f01010a9:	77 19                	ja     f01010c4 <mem_init+0x2c2>
f01010ab:	68 08 2d 10 f0       	push   $0xf0102d08
f01010b0:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01010b5:	68 51 02 00 00       	push   $0x251
f01010ba:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01010bf:	e8 c7 ef ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01010c4:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f01010c9:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f01010cc:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f01010d3:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01010d6:	83 ec 0c             	sub    $0xc,%esp
f01010d9:	6a 00                	push   $0x0
f01010db:	e8 56 fc ff ff       	call   f0100d36 <page_alloc>
f01010e0:	83 c4 10             	add    $0x10,%esp
f01010e3:	85 c0                	test   %eax,%eax
f01010e5:	74 19                	je     f0101100 <mem_init+0x2fe>
f01010e7:	68 25 2d 10 f0       	push   $0xf0102d25
f01010ec:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01010f1:	68 58 02 00 00       	push   $0x258
f01010f6:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01010fb:	e8 8b ef ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101100:	83 ec 0c             	sub    $0xc,%esp
f0101103:	57                   	push   %edi
f0101104:	e8 b3 fc ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f0101109:	89 34 24             	mov    %esi,(%esp)
f010110c:	e8 ab fc ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f0101111:	83 c4 04             	add    $0x4,%esp
f0101114:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101117:	e8 a0 fc ff ff       	call   f0100dbc <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010111c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101123:	e8 0e fc ff ff       	call   f0100d36 <page_alloc>
f0101128:	89 c6                	mov    %eax,%esi
f010112a:	83 c4 10             	add    $0x10,%esp
f010112d:	85 c0                	test   %eax,%eax
f010112f:	75 19                	jne    f010114a <mem_init+0x348>
f0101131:	68 7a 2c 10 f0       	push   $0xf0102c7a
f0101136:	68 a2 2b 10 f0       	push   $0xf0102ba2
f010113b:	68 5f 02 00 00       	push   $0x25f
f0101140:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101145:	e8 41 ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010114a:	83 ec 0c             	sub    $0xc,%esp
f010114d:	6a 00                	push   $0x0
f010114f:	e8 e2 fb ff ff       	call   f0100d36 <page_alloc>
f0101154:	89 c7                	mov    %eax,%edi
f0101156:	83 c4 10             	add    $0x10,%esp
f0101159:	85 c0                	test   %eax,%eax
f010115b:	75 19                	jne    f0101176 <mem_init+0x374>
f010115d:	68 90 2c 10 f0       	push   $0xf0102c90
f0101162:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101167:	68 60 02 00 00       	push   $0x260
f010116c:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101171:	e8 15 ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101176:	83 ec 0c             	sub    $0xc,%esp
f0101179:	6a 00                	push   $0x0
f010117b:	e8 b6 fb ff ff       	call   f0100d36 <page_alloc>
f0101180:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101183:	83 c4 10             	add    $0x10,%esp
f0101186:	85 c0                	test   %eax,%eax
f0101188:	75 19                	jne    f01011a3 <mem_init+0x3a1>
f010118a:	68 a6 2c 10 f0       	push   $0xf0102ca6
f010118f:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101194:	68 61 02 00 00       	push   $0x261
f0101199:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010119e:	e8 e8 ee ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01011a3:	39 fe                	cmp    %edi,%esi
f01011a5:	75 19                	jne    f01011c0 <mem_init+0x3be>
f01011a7:	68 bc 2c 10 f0       	push   $0xf0102cbc
f01011ac:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01011b1:	68 63 02 00 00       	push   $0x263
f01011b6:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01011bb:	e8 cb ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01011c0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01011c3:	39 c7                	cmp    %eax,%edi
f01011c5:	74 04                	je     f01011cb <mem_init+0x3c9>
f01011c7:	39 c6                	cmp    %eax,%esi
f01011c9:	75 19                	jne    f01011e4 <mem_init+0x3e2>
f01011cb:	68 0c 2b 10 f0       	push   $0xf0102b0c
f01011d0:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01011d5:	68 64 02 00 00       	push   $0x264
f01011da:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01011df:	e8 a7 ee ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01011e4:	83 ec 0c             	sub    $0xc,%esp
f01011e7:	6a 00                	push   $0x0
f01011e9:	e8 48 fb ff ff       	call   f0100d36 <page_alloc>
f01011ee:	83 c4 10             	add    $0x10,%esp
f01011f1:	85 c0                	test   %eax,%eax
f01011f3:	74 19                	je     f010120e <mem_init+0x40c>
f01011f5:	68 25 2d 10 f0       	push   $0xf0102d25
f01011fa:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01011ff:	68 65 02 00 00       	push   $0x265
f0101204:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101209:	e8 7d ee ff ff       	call   f010008b <_panic>
f010120e:	89 f0                	mov    %esi,%eax
f0101210:	2b 05 6c 49 11 f0    	sub    0xf011496c,%eax
f0101216:	c1 f8 03             	sar    $0x3,%eax
f0101219:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010121c:	89 c2                	mov    %eax,%edx
f010121e:	c1 ea 0c             	shr    $0xc,%edx
f0101221:	3b 15 64 49 11 f0    	cmp    0xf0114964,%edx
f0101227:	72 12                	jb     f010123b <mem_init+0x439>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101229:	50                   	push   %eax
f010122a:	68 c4 29 10 f0       	push   $0xf01029c4
f010122f:	6a 52                	push   $0x52
f0101231:	68 88 2b 10 f0       	push   $0xf0102b88
f0101236:	e8 50 ee ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010123b:	83 ec 04             	sub    $0x4,%esp
f010123e:	68 00 10 00 00       	push   $0x1000
f0101243:	6a 01                	push   $0x1
f0101245:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010124a:	50                   	push   %eax
f010124b:	e8 8f 0d 00 00       	call   f0101fdf <memset>
	page_free(pp0);
f0101250:	89 34 24             	mov    %esi,(%esp)
f0101253:	e8 64 fb ff ff       	call   f0100dbc <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101258:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010125f:	e8 d2 fa ff ff       	call   f0100d36 <page_alloc>
f0101264:	83 c4 10             	add    $0x10,%esp
f0101267:	85 c0                	test   %eax,%eax
f0101269:	75 19                	jne    f0101284 <mem_init+0x482>
f010126b:	68 34 2d 10 f0       	push   $0xf0102d34
f0101270:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101275:	68 6a 02 00 00       	push   $0x26a
f010127a:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010127f:	e8 07 ee ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101284:	39 c6                	cmp    %eax,%esi
f0101286:	74 19                	je     f01012a1 <mem_init+0x49f>
f0101288:	68 52 2d 10 f0       	push   $0xf0102d52
f010128d:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101292:	68 6b 02 00 00       	push   $0x26b
f0101297:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010129c:	e8 ea ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012a1:	89 f0                	mov    %esi,%eax
f01012a3:	2b 05 6c 49 11 f0    	sub    0xf011496c,%eax
f01012a9:	c1 f8 03             	sar    $0x3,%eax
f01012ac:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012af:	89 c2                	mov    %eax,%edx
f01012b1:	c1 ea 0c             	shr    $0xc,%edx
f01012b4:	3b 15 64 49 11 f0    	cmp    0xf0114964,%edx
f01012ba:	72 12                	jb     f01012ce <mem_init+0x4cc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012bc:	50                   	push   %eax
f01012bd:	68 c4 29 10 f0       	push   $0xf01029c4
f01012c2:	6a 52                	push   $0x52
f01012c4:	68 88 2b 10 f0       	push   $0xf0102b88
f01012c9:	e8 bd ed ff ff       	call   f010008b <_panic>
f01012ce:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01012d4:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01012da:	80 38 00             	cmpb   $0x0,(%eax)
f01012dd:	74 19                	je     f01012f8 <mem_init+0x4f6>
f01012df:	68 62 2d 10 f0       	push   $0xf0102d62
f01012e4:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01012e9:	68 6e 02 00 00       	push   $0x26e
f01012ee:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01012f3:	e8 93 ed ff ff       	call   f010008b <_panic>
f01012f8:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01012fb:	39 d0                	cmp    %edx,%eax
f01012fd:	75 db                	jne    f01012da <mem_init+0x4d8>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01012ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101302:	a3 3c 45 11 f0       	mov    %eax,0xf011453c

	// free the pages we took
	page_free(pp0);
f0101307:	83 ec 0c             	sub    $0xc,%esp
f010130a:	56                   	push   %esi
f010130b:	e8 ac fa ff ff       	call   f0100dbc <page_free>
	page_free(pp1);
f0101310:	89 3c 24             	mov    %edi,(%esp)
f0101313:	e8 a4 fa ff ff       	call   f0100dbc <page_free>
	page_free(pp2);
f0101318:	83 c4 04             	add    $0x4,%esp
f010131b:	ff 75 e4             	pushl  -0x1c(%ebp)
f010131e:	e8 99 fa ff ff       	call   f0100dbc <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101323:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0101328:	83 c4 10             	add    $0x10,%esp
f010132b:	eb 05                	jmp    f0101332 <mem_init+0x530>
		--nfree;
f010132d:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101330:	8b 00                	mov    (%eax),%eax
f0101332:	85 c0                	test   %eax,%eax
f0101334:	75 f7                	jne    f010132d <mem_init+0x52b>
		--nfree;
	assert(nfree == 0);
f0101336:	85 db                	test   %ebx,%ebx
f0101338:	74 19                	je     f0101353 <mem_init+0x551>
f010133a:	68 6c 2d 10 f0       	push   $0xf0102d6c
f010133f:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101344:	68 7b 02 00 00       	push   $0x27b
f0101349:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010134e:	e8 38 ed ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101353:	83 ec 0c             	sub    $0xc,%esp
f0101356:	68 2c 2b 10 f0       	push   $0xf0102b2c
f010135b:	e8 cb 01 00 00       	call   f010152b <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101360:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101367:	e8 ca f9 ff ff       	call   f0100d36 <page_alloc>
f010136c:	89 c3                	mov    %eax,%ebx
f010136e:	83 c4 10             	add    $0x10,%esp
f0101371:	85 c0                	test   %eax,%eax
f0101373:	75 19                	jne    f010138e <mem_init+0x58c>
f0101375:	68 7a 2c 10 f0       	push   $0xf0102c7a
f010137a:	68 a2 2b 10 f0       	push   $0xf0102ba2
f010137f:	68 d4 02 00 00       	push   $0x2d4
f0101384:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101389:	e8 fd ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010138e:	83 ec 0c             	sub    $0xc,%esp
f0101391:	6a 00                	push   $0x0
f0101393:	e8 9e f9 ff ff       	call   f0100d36 <page_alloc>
f0101398:	89 c6                	mov    %eax,%esi
f010139a:	83 c4 10             	add    $0x10,%esp
f010139d:	85 c0                	test   %eax,%eax
f010139f:	75 19                	jne    f01013ba <mem_init+0x5b8>
f01013a1:	68 90 2c 10 f0       	push   $0xf0102c90
f01013a6:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01013ab:	68 d5 02 00 00       	push   $0x2d5
f01013b0:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01013b5:	e8 d1 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013ba:	83 ec 0c             	sub    $0xc,%esp
f01013bd:	6a 00                	push   $0x0
f01013bf:	e8 72 f9 ff ff       	call   f0100d36 <page_alloc>
f01013c4:	83 c4 10             	add    $0x10,%esp
f01013c7:	85 c0                	test   %eax,%eax
f01013c9:	75 19                	jne    f01013e4 <mem_init+0x5e2>
f01013cb:	68 a6 2c 10 f0       	push   $0xf0102ca6
f01013d0:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01013d5:	68 d6 02 00 00       	push   $0x2d6
f01013da:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01013df:	e8 a7 ec ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013e4:	39 f3                	cmp    %esi,%ebx
f01013e6:	75 19                	jne    f0101401 <mem_init+0x5ff>
f01013e8:	68 bc 2c 10 f0       	push   $0xf0102cbc
f01013ed:	68 a2 2b 10 f0       	push   $0xf0102ba2
f01013f2:	68 d9 02 00 00       	push   $0x2d9
f01013f7:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01013fc:	e8 8a ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101401:	39 c6                	cmp    %eax,%esi
f0101403:	74 04                	je     f0101409 <mem_init+0x607>
f0101405:	39 c3                	cmp    %eax,%ebx
f0101407:	75 19                	jne    f0101422 <mem_init+0x620>
f0101409:	68 0c 2b 10 f0       	push   $0xf0102b0c
f010140e:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101413:	68 da 02 00 00       	push   $0x2da
f0101418:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010141d:	e8 69 ec ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f0101422:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f0101429:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010142c:	83 ec 0c             	sub    $0xc,%esp
f010142f:	6a 00                	push   $0x0
f0101431:	e8 00 f9 ff ff       	call   f0100d36 <page_alloc>
f0101436:	83 c4 10             	add    $0x10,%esp
f0101439:	85 c0                	test   %eax,%eax
f010143b:	74 19                	je     f0101456 <mem_init+0x654>
f010143d:	68 25 2d 10 f0       	push   $0xf0102d25
f0101442:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101447:	68 e1 02 00 00       	push   $0x2e1
f010144c:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101451:	e8 35 ec ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101456:	68 4c 2b 10 f0       	push   $0xf0102b4c
f010145b:	68 a2 2b 10 f0       	push   $0xf0102ba2
f0101460:	68 e7 02 00 00       	push   $0x2e7
f0101465:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010146a:	e8 1c ec ff ff       	call   f010008b <_panic>

f010146f <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f010146f:	55                   	push   %ebp
f0101470:	89 e5                	mov    %esp,%ebp
f0101472:	83 ec 08             	sub    $0x8,%esp
f0101475:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101478:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010147c:	83 e8 01             	sub    $0x1,%eax
f010147f:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101483:	66 85 c0             	test   %ax,%ax
f0101486:	75 0c                	jne    f0101494 <page_decref+0x25>
		page_free(pp);
f0101488:	83 ec 0c             	sub    $0xc,%esp
f010148b:	52                   	push   %edx
f010148c:	e8 2b f9 ff ff       	call   f0100dbc <page_free>
f0101491:	83 c4 10             	add    $0x10,%esp
}
f0101494:	c9                   	leave  
f0101495:	c3                   	ret    

f0101496 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101496:	55                   	push   %ebp
f0101497:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0101499:	b8 00 00 00 00       	mov    $0x0,%eax
f010149e:	5d                   	pop    %ebp
f010149f:	c3                   	ret    

f01014a0 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01014a0:	55                   	push   %ebp
f01014a1:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f01014a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01014a8:	5d                   	pop    %ebp
f01014a9:	c3                   	ret    

f01014aa <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01014aa:	55                   	push   %ebp
f01014ab:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01014ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01014b2:	5d                   	pop    %ebp
f01014b3:	c3                   	ret    

f01014b4 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01014b4:	55                   	push   %ebp
f01014b5:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f01014b7:	5d                   	pop    %ebp
f01014b8:	c3                   	ret    

f01014b9 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01014b9:	55                   	push   %ebp
f01014ba:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01014bc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014bf:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01014c2:	5d                   	pop    %ebp
f01014c3:	c3                   	ret    

f01014c4 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01014c4:	55                   	push   %ebp
f01014c5:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01014c7:	ba 70 00 00 00       	mov    $0x70,%edx
f01014cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01014cf:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01014d0:	ba 71 00 00 00       	mov    $0x71,%edx
f01014d5:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01014d6:	0f b6 c0             	movzbl %al,%eax
}
f01014d9:	5d                   	pop    %ebp
f01014da:	c3                   	ret    

f01014db <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01014db:	55                   	push   %ebp
f01014dc:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01014de:	ba 70 00 00 00       	mov    $0x70,%edx
f01014e3:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e6:	ee                   	out    %al,(%dx)
f01014e7:	ba 71 00 00 00       	mov    $0x71,%edx
f01014ec:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014ef:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01014f0:	5d                   	pop    %ebp
f01014f1:	c3                   	ret    

f01014f2 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01014f2:	55                   	push   %ebp
f01014f3:	89 e5                	mov    %esp,%ebp
f01014f5:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01014f8:	ff 75 08             	pushl  0x8(%ebp)
f01014fb:	e8 25 f1 ff ff       	call   f0100625 <cputchar>
	*cnt++;
}
f0101500:	83 c4 10             	add    $0x10,%esp
f0101503:	c9                   	leave  
f0101504:	c3                   	ret    

f0101505 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101505:	55                   	push   %ebp
f0101506:	89 e5                	mov    %esp,%ebp
f0101508:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010150b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0101512:	ff 75 0c             	pushl  0xc(%ebp)
f0101515:	ff 75 08             	pushl  0x8(%ebp)
f0101518:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010151b:	50                   	push   %eax
f010151c:	68 f2 14 10 f0       	push   $0xf01014f2
f0101521:	e8 4d 04 00 00       	call   f0101973 <vprintfmt>
	return cnt;
}
f0101526:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101529:	c9                   	leave  
f010152a:	c3                   	ret    

f010152b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010152b:	55                   	push   %ebp
f010152c:	89 e5                	mov    %esp,%ebp
f010152e:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0101531:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101534:	50                   	push   %eax
f0101535:	ff 75 08             	pushl  0x8(%ebp)
f0101538:	e8 c8 ff ff ff       	call   f0101505 <vcprintf>
	va_end(ap);

	return cnt;
}
f010153d:	c9                   	leave  
f010153e:	c3                   	ret    

f010153f <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010153f:	55                   	push   %ebp
f0101540:	89 e5                	mov    %esp,%ebp
f0101542:	57                   	push   %edi
f0101543:	56                   	push   %esi
f0101544:	53                   	push   %ebx
f0101545:	83 ec 14             	sub    $0x14,%esp
f0101548:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010154b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010154e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101551:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101554:	8b 1a                	mov    (%edx),%ebx
f0101556:	8b 01                	mov    (%ecx),%eax
f0101558:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010155b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0101562:	eb 7f                	jmp    f01015e3 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0101564:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101567:	01 d8                	add    %ebx,%eax
f0101569:	89 c6                	mov    %eax,%esi
f010156b:	c1 ee 1f             	shr    $0x1f,%esi
f010156e:	01 c6                	add    %eax,%esi
f0101570:	d1 fe                	sar    %esi
f0101572:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0101575:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101578:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010157b:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010157d:	eb 03                	jmp    f0101582 <stab_binsearch+0x43>
			m--;
f010157f:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101582:	39 c3                	cmp    %eax,%ebx
f0101584:	7f 0d                	jg     f0101593 <stab_binsearch+0x54>
f0101586:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010158a:	83 ea 0c             	sub    $0xc,%edx
f010158d:	39 f9                	cmp    %edi,%ecx
f010158f:	75 ee                	jne    f010157f <stab_binsearch+0x40>
f0101591:	eb 05                	jmp    f0101598 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0101593:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0101596:	eb 4b                	jmp    f01015e3 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0101598:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010159b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010159e:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01015a2:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01015a5:	76 11                	jbe    f01015b8 <stab_binsearch+0x79>
			*region_left = m;
f01015a7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01015aa:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01015ac:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01015af:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01015b6:	eb 2b                	jmp    f01015e3 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01015b8:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01015bb:	73 14                	jae    f01015d1 <stab_binsearch+0x92>
			*region_right = m - 1;
f01015bd:	83 e8 01             	sub    $0x1,%eax
f01015c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01015c3:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01015c6:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01015c8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01015cf:	eb 12                	jmp    f01015e3 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01015d1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01015d4:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01015d6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01015da:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01015dc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01015e3:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01015e6:	0f 8e 78 ff ff ff    	jle    f0101564 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01015ec:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01015f0:	75 0f                	jne    f0101601 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01015f2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01015f5:	8b 00                	mov    (%eax),%eax
f01015f7:	83 e8 01             	sub    $0x1,%eax
f01015fa:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01015fd:	89 06                	mov    %eax,(%esi)
f01015ff:	eb 2c                	jmp    f010162d <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101601:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101604:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0101606:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101609:	8b 0e                	mov    (%esi),%ecx
f010160b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010160e:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0101611:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101614:	eb 03                	jmp    f0101619 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0101616:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101619:	39 c8                	cmp    %ecx,%eax
f010161b:	7e 0b                	jle    f0101628 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010161d:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0101621:	83 ea 0c             	sub    $0xc,%edx
f0101624:	39 df                	cmp    %ebx,%edi
f0101626:	75 ee                	jne    f0101616 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0101628:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010162b:	89 06                	mov    %eax,(%esi)
	}
}
f010162d:	83 c4 14             	add    $0x14,%esp
f0101630:	5b                   	pop    %ebx
f0101631:	5e                   	pop    %esi
f0101632:	5f                   	pop    %edi
f0101633:	5d                   	pop    %ebp
f0101634:	c3                   	ret    

f0101635 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0101635:	55                   	push   %ebp
f0101636:	89 e5                	mov    %esp,%ebp
f0101638:	57                   	push   %edi
f0101639:	56                   	push   %esi
f010163a:	53                   	push   %ebx
f010163b:	83 ec 2c             	sub    $0x2c,%esp
f010163e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101641:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101644:	c7 06 77 2d 10 f0    	movl   $0xf0102d77,(%esi)
	info->eip_line = 0;
f010164a:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0101651:	c7 46 08 77 2d 10 f0 	movl   $0xf0102d77,0x8(%esi)
	info->eip_fn_namelen = 9;
f0101658:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010165f:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0101662:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101669:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010166f:	76 11                	jbe    f0101682 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101671:	b8 cc 97 10 f0       	mov    $0xf01097cc,%eax
f0101676:	3d d1 7a 10 f0       	cmp    $0xf0107ad1,%eax
f010167b:	77 19                	ja     f0101696 <debuginfo_eip+0x61>
f010167d:	e9 a5 01 00 00       	jmp    f0101827 <debuginfo_eip+0x1f2>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0101682:	83 ec 04             	sub    $0x4,%esp
f0101685:	68 81 2d 10 f0       	push   $0xf0102d81
f010168a:	6a 7f                	push   $0x7f
f010168c:	68 8e 2d 10 f0       	push   $0xf0102d8e
f0101691:	e8 f5 e9 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101696:	80 3d cb 97 10 f0 00 	cmpb   $0x0,0xf01097cb
f010169d:	0f 85 8b 01 00 00    	jne    f010182e <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01016a3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01016aa:	b8 d0 7a 10 f0       	mov    $0xf0107ad0,%eax
f01016af:	2d d0 2f 10 f0       	sub    $0xf0102fd0,%eax
f01016b4:	c1 f8 02             	sar    $0x2,%eax
f01016b7:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01016bd:	83 e8 01             	sub    $0x1,%eax
f01016c0:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01016c3:	83 ec 08             	sub    $0x8,%esp
f01016c6:	57                   	push   %edi
f01016c7:	6a 64                	push   $0x64
f01016c9:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01016cc:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01016cf:	b8 d0 2f 10 f0       	mov    $0xf0102fd0,%eax
f01016d4:	e8 66 fe ff ff       	call   f010153f <stab_binsearch>
	if (lfile == 0)
f01016d9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01016dc:	83 c4 10             	add    $0x10,%esp
f01016df:	85 c0                	test   %eax,%eax
f01016e1:	0f 84 4e 01 00 00    	je     f0101835 <debuginfo_eip+0x200>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01016e7:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01016ea:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01016ed:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01016f0:	83 ec 08             	sub    $0x8,%esp
f01016f3:	57                   	push   %edi
f01016f4:	6a 24                	push   $0x24
f01016f6:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01016f9:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01016fc:	b8 d0 2f 10 f0       	mov    $0xf0102fd0,%eax
f0101701:	e8 39 fe ff ff       	call   f010153f <stab_binsearch>

	if (lfun <= rfun) {
f0101706:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101709:	83 c4 10             	add    $0x10,%esp
f010170c:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010170f:	7f 33                	jg     f0101744 <debuginfo_eip+0x10f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0101711:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0101714:	c1 e0 02             	shl    $0x2,%eax
f0101717:	8d 90 d0 2f 10 f0    	lea    -0xfefd030(%eax),%edx
f010171d:	8b 88 d0 2f 10 f0    	mov    -0xfefd030(%eax),%ecx
f0101723:	b8 cc 97 10 f0       	mov    $0xf01097cc,%eax
f0101728:	2d d1 7a 10 f0       	sub    $0xf0107ad1,%eax
f010172d:	39 c1                	cmp    %eax,%ecx
f010172f:	73 09                	jae    f010173a <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0101731:	81 c1 d1 7a 10 f0    	add    $0xf0107ad1,%ecx
f0101737:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010173a:	8b 42 08             	mov    0x8(%edx),%eax
f010173d:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f0101740:	29 c7                	sub    %eax,%edi
f0101742:	eb 06                	jmp    f010174a <debuginfo_eip+0x115>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0101744:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0101747:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010174a:	83 ec 08             	sub    $0x8,%esp
f010174d:	6a 3a                	push   $0x3a
f010174f:	ff 76 08             	pushl  0x8(%esi)
f0101752:	e8 6c 08 00 00       	call   f0101fc3 <strfind>
f0101757:	2b 46 08             	sub    0x8(%esi),%eax
f010175a:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
f010175d:	83 c4 08             	add    $0x8,%esp
f0101760:	2b 7e 10             	sub    0x10(%esi),%edi
f0101763:	57                   	push   %edi
f0101764:	6a 44                	push   $0x44
f0101766:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0101769:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010176c:	b8 d0 2f 10 f0       	mov    $0xf0102fd0,%eax
f0101771:	e8 c9 fd ff ff       	call   f010153f <stab_binsearch>
	if (lfun > rfun) 
f0101776:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101779:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010177c:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f010177f:	83 c4 10             	add    $0x10,%esp
f0101782:	39 c8                	cmp    %ecx,%eax
f0101784:	0f 8f b2 00 00 00    	jg     f010183c <debuginfo_eip+0x207>
       	  return -1;
        info->eip_line = stabs[lfun].n_desc;
f010178a:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010178d:	8d 04 85 d0 2f 10 f0 	lea    -0xfefd030(,%eax,4),%eax
f0101794:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101797:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f010179b:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010179e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01017a1:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01017a4:	8d 04 85 d0 2f 10 f0 	lea    -0xfefd030(,%eax,4),%eax
f01017ab:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01017ae:	eb 06                	jmp    f01017b6 <debuginfo_eip+0x181>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01017b0:	83 eb 01             	sub    $0x1,%ebx
f01017b3:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01017b6:	39 fb                	cmp    %edi,%ebx
f01017b8:	7c 39                	jl     f01017f3 <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f01017ba:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f01017be:	80 fa 84             	cmp    $0x84,%dl
f01017c1:	74 0b                	je     f01017ce <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01017c3:	80 fa 64             	cmp    $0x64,%dl
f01017c6:	75 e8                	jne    f01017b0 <debuginfo_eip+0x17b>
f01017c8:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01017cc:	74 e2                	je     f01017b0 <debuginfo_eip+0x17b>
f01017ce:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01017d1:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01017d4:	8b 14 85 d0 2f 10 f0 	mov    -0xfefd030(,%eax,4),%edx
f01017db:	b8 cc 97 10 f0       	mov    $0xf01097cc,%eax
f01017e0:	2d d1 7a 10 f0       	sub    $0xf0107ad1,%eax
f01017e5:	39 c2                	cmp    %eax,%edx
f01017e7:	73 0d                	jae    f01017f6 <debuginfo_eip+0x1c1>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01017e9:	81 c2 d1 7a 10 f0    	add    $0xf0107ad1,%edx
f01017ef:	89 16                	mov    %edx,(%esi)
f01017f1:	eb 03                	jmp    f01017f6 <debuginfo_eip+0x1c1>
f01017f3:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01017f6:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01017fb:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01017fe:	39 cf                	cmp    %ecx,%edi
f0101800:	7d 46                	jge    f0101848 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
f0101802:	89 f8                	mov    %edi,%eax
f0101804:	83 c0 01             	add    $0x1,%eax
f0101807:	8b 55 cc             	mov    -0x34(%ebp),%edx
f010180a:	eb 07                	jmp    f0101813 <debuginfo_eip+0x1de>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010180c:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0101810:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0101813:	39 c8                	cmp    %ecx,%eax
f0101815:	74 2c                	je     f0101843 <debuginfo_eip+0x20e>
f0101817:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010181a:	80 7a 04 a0          	cmpb   $0xa0,0x4(%edx)
f010181e:	74 ec                	je     f010180c <debuginfo_eip+0x1d7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101820:	b8 00 00 00 00       	mov    $0x0,%eax
f0101825:	eb 21                	jmp    f0101848 <debuginfo_eip+0x213>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0101827:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010182c:	eb 1a                	jmp    f0101848 <debuginfo_eip+0x213>
f010182e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101833:	eb 13                	jmp    f0101848 <debuginfo_eip+0x213>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0101835:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010183a:	eb 0c                	jmp    f0101848 <debuginfo_eip+0x213>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
	if (lfun > rfun) 
       	  return -1;
f010183c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101841:	eb 05                	jmp    f0101848 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101843:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101848:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010184b:	5b                   	pop    %ebx
f010184c:	5e                   	pop    %esi
f010184d:	5f                   	pop    %edi
f010184e:	5d                   	pop    %ebp
f010184f:	c3                   	ret    

f0101850 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101850:	55                   	push   %ebp
f0101851:	89 e5                	mov    %esp,%ebp
f0101853:	57                   	push   %edi
f0101854:	56                   	push   %esi
f0101855:	53                   	push   %ebx
f0101856:	83 ec 1c             	sub    $0x1c,%esp
f0101859:	89 c7                	mov    %eax,%edi
f010185b:	89 d6                	mov    %edx,%esi
f010185d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101860:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101863:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101866:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101869:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010186c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101871:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101874:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101877:	39 d3                	cmp    %edx,%ebx
f0101879:	72 05                	jb     f0101880 <printnum+0x30>
f010187b:	39 45 10             	cmp    %eax,0x10(%ebp)
f010187e:	77 45                	ja     f01018c5 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0101880:	83 ec 0c             	sub    $0xc,%esp
f0101883:	ff 75 18             	pushl  0x18(%ebp)
f0101886:	8b 45 14             	mov    0x14(%ebp),%eax
f0101889:	8d 58 ff             	lea    -0x1(%eax),%ebx
f010188c:	53                   	push   %ebx
f010188d:	ff 75 10             	pushl  0x10(%ebp)
f0101890:	83 ec 08             	sub    $0x8,%esp
f0101893:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101896:	ff 75 e0             	pushl  -0x20(%ebp)
f0101899:	ff 75 dc             	pushl  -0x24(%ebp)
f010189c:	ff 75 d8             	pushl  -0x28(%ebp)
f010189f:	e8 4c 09 00 00       	call   f01021f0 <__udivdi3>
f01018a4:	83 c4 18             	add    $0x18,%esp
f01018a7:	52                   	push   %edx
f01018a8:	50                   	push   %eax
f01018a9:	89 f2                	mov    %esi,%edx
f01018ab:	89 f8                	mov    %edi,%eax
f01018ad:	e8 9e ff ff ff       	call   f0101850 <printnum>
f01018b2:	83 c4 20             	add    $0x20,%esp
f01018b5:	eb 18                	jmp    f01018cf <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01018b7:	83 ec 08             	sub    $0x8,%esp
f01018ba:	56                   	push   %esi
f01018bb:	ff 75 18             	pushl  0x18(%ebp)
f01018be:	ff d7                	call   *%edi
f01018c0:	83 c4 10             	add    $0x10,%esp
f01018c3:	eb 03                	jmp    f01018c8 <printnum+0x78>
f01018c5:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01018c8:	83 eb 01             	sub    $0x1,%ebx
f01018cb:	85 db                	test   %ebx,%ebx
f01018cd:	7f e8                	jg     f01018b7 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01018cf:	83 ec 08             	sub    $0x8,%esp
f01018d2:	56                   	push   %esi
f01018d3:	83 ec 04             	sub    $0x4,%esp
f01018d6:	ff 75 e4             	pushl  -0x1c(%ebp)
f01018d9:	ff 75 e0             	pushl  -0x20(%ebp)
f01018dc:	ff 75 dc             	pushl  -0x24(%ebp)
f01018df:	ff 75 d8             	pushl  -0x28(%ebp)
f01018e2:	e8 39 0a 00 00       	call   f0102320 <__umoddi3>
f01018e7:	83 c4 14             	add    $0x14,%esp
f01018ea:	0f be 80 9c 2d 10 f0 	movsbl -0xfefd264(%eax),%eax
f01018f1:	50                   	push   %eax
f01018f2:	ff d7                	call   *%edi
}
f01018f4:	83 c4 10             	add    $0x10,%esp
f01018f7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01018fa:	5b                   	pop    %ebx
f01018fb:	5e                   	pop    %esi
f01018fc:	5f                   	pop    %edi
f01018fd:	5d                   	pop    %ebp
f01018fe:	c3                   	ret    

f01018ff <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01018ff:	55                   	push   %ebp
f0101900:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101902:	83 fa 01             	cmp    $0x1,%edx
f0101905:	7e 0e                	jle    f0101915 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0101907:	8b 10                	mov    (%eax),%edx
f0101909:	8d 4a 08             	lea    0x8(%edx),%ecx
f010190c:	89 08                	mov    %ecx,(%eax)
f010190e:	8b 02                	mov    (%edx),%eax
f0101910:	8b 52 04             	mov    0x4(%edx),%edx
f0101913:	eb 22                	jmp    f0101937 <getuint+0x38>
	else if (lflag)
f0101915:	85 d2                	test   %edx,%edx
f0101917:	74 10                	je     f0101929 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0101919:	8b 10                	mov    (%eax),%edx
f010191b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010191e:	89 08                	mov    %ecx,(%eax)
f0101920:	8b 02                	mov    (%edx),%eax
f0101922:	ba 00 00 00 00       	mov    $0x0,%edx
f0101927:	eb 0e                	jmp    f0101937 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0101929:	8b 10                	mov    (%eax),%edx
f010192b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010192e:	89 08                	mov    %ecx,(%eax)
f0101930:	8b 02                	mov    (%edx),%eax
f0101932:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0101937:	5d                   	pop    %ebp
f0101938:	c3                   	ret    

f0101939 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101939:	55                   	push   %ebp
f010193a:	89 e5                	mov    %esp,%ebp
f010193c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010193f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101943:	8b 10                	mov    (%eax),%edx
f0101945:	3b 50 04             	cmp    0x4(%eax),%edx
f0101948:	73 0a                	jae    f0101954 <sprintputch+0x1b>
		*b->buf++ = ch;
f010194a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010194d:	89 08                	mov    %ecx,(%eax)
f010194f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101952:	88 02                	mov    %al,(%edx)
}
f0101954:	5d                   	pop    %ebp
f0101955:	c3                   	ret    

f0101956 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101956:	55                   	push   %ebp
f0101957:	89 e5                	mov    %esp,%ebp
f0101959:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010195c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010195f:	50                   	push   %eax
f0101960:	ff 75 10             	pushl  0x10(%ebp)
f0101963:	ff 75 0c             	pushl  0xc(%ebp)
f0101966:	ff 75 08             	pushl  0x8(%ebp)
f0101969:	e8 05 00 00 00       	call   f0101973 <vprintfmt>
	va_end(ap);
}
f010196e:	83 c4 10             	add    $0x10,%esp
f0101971:	c9                   	leave  
f0101972:	c3                   	ret    

f0101973 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101973:	55                   	push   %ebp
f0101974:	89 e5                	mov    %esp,%ebp
f0101976:	57                   	push   %edi
f0101977:	56                   	push   %esi
f0101978:	53                   	push   %ebx
f0101979:	83 ec 2c             	sub    $0x2c,%esp
f010197c:	8b 75 08             	mov    0x8(%ebp),%esi
f010197f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101982:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101985:	eb 12                	jmp    f0101999 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0101987:	85 c0                	test   %eax,%eax
f0101989:	0f 84 89 03 00 00    	je     f0101d18 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f010198f:	83 ec 08             	sub    $0x8,%esp
f0101992:	53                   	push   %ebx
f0101993:	50                   	push   %eax
f0101994:	ff d6                	call   *%esi
f0101996:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101999:	83 c7 01             	add    $0x1,%edi
f010199c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01019a0:	83 f8 25             	cmp    $0x25,%eax
f01019a3:	75 e2                	jne    f0101987 <vprintfmt+0x14>
f01019a5:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01019a9:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01019b0:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01019b7:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01019be:	ba 00 00 00 00       	mov    $0x0,%edx
f01019c3:	eb 07                	jmp    f01019cc <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019c5:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01019c8:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019cc:	8d 47 01             	lea    0x1(%edi),%eax
f01019cf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01019d2:	0f b6 07             	movzbl (%edi),%eax
f01019d5:	0f b6 c8             	movzbl %al,%ecx
f01019d8:	83 e8 23             	sub    $0x23,%eax
f01019db:	3c 55                	cmp    $0x55,%al
f01019dd:	0f 87 1a 03 00 00    	ja     f0101cfd <vprintfmt+0x38a>
f01019e3:	0f b6 c0             	movzbl %al,%eax
f01019e6:	ff 24 85 40 2e 10 f0 	jmp    *-0xfefd1c0(,%eax,4)
f01019ed:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01019f0:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01019f4:	eb d6                	jmp    f01019cc <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019f6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01019f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01019fe:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101a01:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101a04:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0101a08:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0101a0b:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0101a0e:	83 fa 09             	cmp    $0x9,%edx
f0101a11:	77 39                	ja     f0101a4c <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101a13:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0101a16:	eb e9                	jmp    f0101a01 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101a18:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a1b:	8d 48 04             	lea    0x4(%eax),%ecx
f0101a1e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101a21:	8b 00                	mov    (%eax),%eax
f0101a23:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a26:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101a29:	eb 27                	jmp    f0101a52 <vprintfmt+0xdf>
f0101a2b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101a2e:	85 c0                	test   %eax,%eax
f0101a30:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101a35:	0f 49 c8             	cmovns %eax,%ecx
f0101a38:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a3b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a3e:	eb 8c                	jmp    f01019cc <vprintfmt+0x59>
f0101a40:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101a43:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0101a4a:	eb 80                	jmp    f01019cc <vprintfmt+0x59>
f0101a4c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101a4f:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0101a52:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101a56:	0f 89 70 ff ff ff    	jns    f01019cc <vprintfmt+0x59>
				width = precision, precision = -1;
f0101a5c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a5f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101a62:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101a69:	e9 5e ff ff ff       	jmp    f01019cc <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101a6e:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a71:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101a74:	e9 53 ff ff ff       	jmp    f01019cc <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101a79:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a7c:	8d 50 04             	lea    0x4(%eax),%edx
f0101a7f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101a82:	83 ec 08             	sub    $0x8,%esp
f0101a85:	53                   	push   %ebx
f0101a86:	ff 30                	pushl  (%eax)
f0101a88:	ff d6                	call   *%esi
			break;
f0101a8a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a8d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0101a90:	e9 04 ff ff ff       	jmp    f0101999 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101a95:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a98:	8d 50 04             	lea    0x4(%eax),%edx
f0101a9b:	89 55 14             	mov    %edx,0x14(%ebp)
f0101a9e:	8b 00                	mov    (%eax),%eax
f0101aa0:	99                   	cltd   
f0101aa1:	31 d0                	xor    %edx,%eax
f0101aa3:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101aa5:	83 f8 07             	cmp    $0x7,%eax
f0101aa8:	7f 0b                	jg     f0101ab5 <vprintfmt+0x142>
f0101aaa:	8b 14 85 a0 2f 10 f0 	mov    -0xfefd060(,%eax,4),%edx
f0101ab1:	85 d2                	test   %edx,%edx
f0101ab3:	75 18                	jne    f0101acd <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0101ab5:	50                   	push   %eax
f0101ab6:	68 b4 2d 10 f0       	push   $0xf0102db4
f0101abb:	53                   	push   %ebx
f0101abc:	56                   	push   %esi
f0101abd:	e8 94 fe ff ff       	call   f0101956 <printfmt>
f0101ac2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101ac5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101ac8:	e9 cc fe ff ff       	jmp    f0101999 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0101acd:	52                   	push   %edx
f0101ace:	68 b4 2b 10 f0       	push   $0xf0102bb4
f0101ad3:	53                   	push   %ebx
f0101ad4:	56                   	push   %esi
f0101ad5:	e8 7c fe ff ff       	call   f0101956 <printfmt>
f0101ada:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101add:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101ae0:	e9 b4 fe ff ff       	jmp    f0101999 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101ae5:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ae8:	8d 50 04             	lea    0x4(%eax),%edx
f0101aeb:	89 55 14             	mov    %edx,0x14(%ebp)
f0101aee:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101af0:	85 ff                	test   %edi,%edi
f0101af2:	b8 ad 2d 10 f0       	mov    $0xf0102dad,%eax
f0101af7:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101afa:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101afe:	0f 8e 94 00 00 00    	jle    f0101b98 <vprintfmt+0x225>
f0101b04:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101b08:	0f 84 98 00 00 00    	je     f0101ba6 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101b0e:	83 ec 08             	sub    $0x8,%esp
f0101b11:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b14:	57                   	push   %edi
f0101b15:	e8 5f 03 00 00       	call   f0101e79 <strnlen>
f0101b1a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101b1d:	29 c1                	sub    %eax,%ecx
f0101b1f:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101b22:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101b25:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101b29:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101b2c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101b2f:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101b31:	eb 0f                	jmp    f0101b42 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0101b33:	83 ec 08             	sub    $0x8,%esp
f0101b36:	53                   	push   %ebx
f0101b37:	ff 75 e0             	pushl  -0x20(%ebp)
f0101b3a:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101b3c:	83 ef 01             	sub    $0x1,%edi
f0101b3f:	83 c4 10             	add    $0x10,%esp
f0101b42:	85 ff                	test   %edi,%edi
f0101b44:	7f ed                	jg     f0101b33 <vprintfmt+0x1c0>
f0101b46:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101b49:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101b4c:	85 c9                	test   %ecx,%ecx
f0101b4e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b53:	0f 49 c1             	cmovns %ecx,%eax
f0101b56:	29 c1                	sub    %eax,%ecx
f0101b58:	89 75 08             	mov    %esi,0x8(%ebp)
f0101b5b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101b5e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101b61:	89 cb                	mov    %ecx,%ebx
f0101b63:	eb 4d                	jmp    f0101bb2 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101b65:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101b69:	74 1b                	je     f0101b86 <vprintfmt+0x213>
f0101b6b:	0f be c0             	movsbl %al,%eax
f0101b6e:	83 e8 20             	sub    $0x20,%eax
f0101b71:	83 f8 5e             	cmp    $0x5e,%eax
f0101b74:	76 10                	jbe    f0101b86 <vprintfmt+0x213>
					putch('?', putdat);
f0101b76:	83 ec 08             	sub    $0x8,%esp
f0101b79:	ff 75 0c             	pushl  0xc(%ebp)
f0101b7c:	6a 3f                	push   $0x3f
f0101b7e:	ff 55 08             	call   *0x8(%ebp)
f0101b81:	83 c4 10             	add    $0x10,%esp
f0101b84:	eb 0d                	jmp    f0101b93 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0101b86:	83 ec 08             	sub    $0x8,%esp
f0101b89:	ff 75 0c             	pushl  0xc(%ebp)
f0101b8c:	52                   	push   %edx
f0101b8d:	ff 55 08             	call   *0x8(%ebp)
f0101b90:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101b93:	83 eb 01             	sub    $0x1,%ebx
f0101b96:	eb 1a                	jmp    f0101bb2 <vprintfmt+0x23f>
f0101b98:	89 75 08             	mov    %esi,0x8(%ebp)
f0101b9b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101b9e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101ba1:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101ba4:	eb 0c                	jmp    f0101bb2 <vprintfmt+0x23f>
f0101ba6:	89 75 08             	mov    %esi,0x8(%ebp)
f0101ba9:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101bac:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101baf:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101bb2:	83 c7 01             	add    $0x1,%edi
f0101bb5:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101bb9:	0f be d0             	movsbl %al,%edx
f0101bbc:	85 d2                	test   %edx,%edx
f0101bbe:	74 23                	je     f0101be3 <vprintfmt+0x270>
f0101bc0:	85 f6                	test   %esi,%esi
f0101bc2:	78 a1                	js     f0101b65 <vprintfmt+0x1f2>
f0101bc4:	83 ee 01             	sub    $0x1,%esi
f0101bc7:	79 9c                	jns    f0101b65 <vprintfmt+0x1f2>
f0101bc9:	89 df                	mov    %ebx,%edi
f0101bcb:	8b 75 08             	mov    0x8(%ebp),%esi
f0101bce:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101bd1:	eb 18                	jmp    f0101beb <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101bd3:	83 ec 08             	sub    $0x8,%esp
f0101bd6:	53                   	push   %ebx
f0101bd7:	6a 20                	push   $0x20
f0101bd9:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101bdb:	83 ef 01             	sub    $0x1,%edi
f0101bde:	83 c4 10             	add    $0x10,%esp
f0101be1:	eb 08                	jmp    f0101beb <vprintfmt+0x278>
f0101be3:	89 df                	mov    %ebx,%edi
f0101be5:	8b 75 08             	mov    0x8(%ebp),%esi
f0101be8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101beb:	85 ff                	test   %edi,%edi
f0101bed:	7f e4                	jg     f0101bd3 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101bef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101bf2:	e9 a2 fd ff ff       	jmp    f0101999 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101bf7:	83 fa 01             	cmp    $0x1,%edx
f0101bfa:	7e 16                	jle    f0101c12 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101bfc:	8b 45 14             	mov    0x14(%ebp),%eax
f0101bff:	8d 50 08             	lea    0x8(%eax),%edx
f0101c02:	89 55 14             	mov    %edx,0x14(%ebp)
f0101c05:	8b 50 04             	mov    0x4(%eax),%edx
f0101c08:	8b 00                	mov    (%eax),%eax
f0101c0a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101c0d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101c10:	eb 32                	jmp    f0101c44 <vprintfmt+0x2d1>
	else if (lflag)
f0101c12:	85 d2                	test   %edx,%edx
f0101c14:	74 18                	je     f0101c2e <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0101c16:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c19:	8d 50 04             	lea    0x4(%eax),%edx
f0101c1c:	89 55 14             	mov    %edx,0x14(%ebp)
f0101c1f:	8b 00                	mov    (%eax),%eax
f0101c21:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101c24:	89 c1                	mov    %eax,%ecx
f0101c26:	c1 f9 1f             	sar    $0x1f,%ecx
f0101c29:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101c2c:	eb 16                	jmp    f0101c44 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0101c2e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c31:	8d 50 04             	lea    0x4(%eax),%edx
f0101c34:	89 55 14             	mov    %edx,0x14(%ebp)
f0101c37:	8b 00                	mov    (%eax),%eax
f0101c39:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101c3c:	89 c1                	mov    %eax,%ecx
f0101c3e:	c1 f9 1f             	sar    $0x1f,%ecx
f0101c41:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101c44:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101c47:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101c4a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101c4f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101c53:	79 74                	jns    f0101cc9 <vprintfmt+0x356>
				putch('-', putdat);
f0101c55:	83 ec 08             	sub    $0x8,%esp
f0101c58:	53                   	push   %ebx
f0101c59:	6a 2d                	push   $0x2d
f0101c5b:	ff d6                	call   *%esi
				num = -(long long) num;
f0101c5d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101c60:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101c63:	f7 d8                	neg    %eax
f0101c65:	83 d2 00             	adc    $0x0,%edx
f0101c68:	f7 da                	neg    %edx
f0101c6a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101c6d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101c72:	eb 55                	jmp    f0101cc9 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101c74:	8d 45 14             	lea    0x14(%ebp),%eax
f0101c77:	e8 83 fc ff ff       	call   f01018ff <getuint>
			base = 10;
f0101c7c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101c81:	eb 46                	jmp    f0101cc9 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101c83:	8d 45 14             	lea    0x14(%ebp),%eax
f0101c86:	e8 74 fc ff ff       	call   f01018ff <getuint>
			base = 8;
f0101c8b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101c90:	eb 37                	jmp    f0101cc9 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0101c92:	83 ec 08             	sub    $0x8,%esp
f0101c95:	53                   	push   %ebx
f0101c96:	6a 30                	push   $0x30
f0101c98:	ff d6                	call   *%esi
			putch('x', putdat);
f0101c9a:	83 c4 08             	add    $0x8,%esp
f0101c9d:	53                   	push   %ebx
f0101c9e:	6a 78                	push   $0x78
f0101ca0:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101ca2:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ca5:	8d 50 04             	lea    0x4(%eax),%edx
f0101ca8:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101cab:	8b 00                	mov    (%eax),%eax
f0101cad:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101cb2:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101cb5:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101cba:	eb 0d                	jmp    f0101cc9 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101cbc:	8d 45 14             	lea    0x14(%ebp),%eax
f0101cbf:	e8 3b fc ff ff       	call   f01018ff <getuint>
			base = 16;
f0101cc4:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101cc9:	83 ec 0c             	sub    $0xc,%esp
f0101ccc:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101cd0:	57                   	push   %edi
f0101cd1:	ff 75 e0             	pushl  -0x20(%ebp)
f0101cd4:	51                   	push   %ecx
f0101cd5:	52                   	push   %edx
f0101cd6:	50                   	push   %eax
f0101cd7:	89 da                	mov    %ebx,%edx
f0101cd9:	89 f0                	mov    %esi,%eax
f0101cdb:	e8 70 fb ff ff       	call   f0101850 <printnum>
			break;
f0101ce0:	83 c4 20             	add    $0x20,%esp
f0101ce3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101ce6:	e9 ae fc ff ff       	jmp    f0101999 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101ceb:	83 ec 08             	sub    $0x8,%esp
f0101cee:	53                   	push   %ebx
f0101cef:	51                   	push   %ecx
f0101cf0:	ff d6                	call   *%esi
			break;
f0101cf2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101cf5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101cf8:	e9 9c fc ff ff       	jmp    f0101999 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101cfd:	83 ec 08             	sub    $0x8,%esp
f0101d00:	53                   	push   %ebx
f0101d01:	6a 25                	push   $0x25
f0101d03:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101d05:	83 c4 10             	add    $0x10,%esp
f0101d08:	eb 03                	jmp    f0101d0d <vprintfmt+0x39a>
f0101d0a:	83 ef 01             	sub    $0x1,%edi
f0101d0d:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101d11:	75 f7                	jne    f0101d0a <vprintfmt+0x397>
f0101d13:	e9 81 fc ff ff       	jmp    f0101999 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101d18:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101d1b:	5b                   	pop    %ebx
f0101d1c:	5e                   	pop    %esi
f0101d1d:	5f                   	pop    %edi
f0101d1e:	5d                   	pop    %ebp
f0101d1f:	c3                   	ret    

f0101d20 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101d20:	55                   	push   %ebp
f0101d21:	89 e5                	mov    %esp,%ebp
f0101d23:	83 ec 18             	sub    $0x18,%esp
f0101d26:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d29:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101d2c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101d2f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101d33:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101d36:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101d3d:	85 c0                	test   %eax,%eax
f0101d3f:	74 26                	je     f0101d67 <vsnprintf+0x47>
f0101d41:	85 d2                	test   %edx,%edx
f0101d43:	7e 22                	jle    f0101d67 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101d45:	ff 75 14             	pushl  0x14(%ebp)
f0101d48:	ff 75 10             	pushl  0x10(%ebp)
f0101d4b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101d4e:	50                   	push   %eax
f0101d4f:	68 39 19 10 f0       	push   $0xf0101939
f0101d54:	e8 1a fc ff ff       	call   f0101973 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101d59:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101d5c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101d5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101d62:	83 c4 10             	add    $0x10,%esp
f0101d65:	eb 05                	jmp    f0101d6c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101d67:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101d6c:	c9                   	leave  
f0101d6d:	c3                   	ret    

f0101d6e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101d6e:	55                   	push   %ebp
f0101d6f:	89 e5                	mov    %esp,%ebp
f0101d71:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101d74:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101d77:	50                   	push   %eax
f0101d78:	ff 75 10             	pushl  0x10(%ebp)
f0101d7b:	ff 75 0c             	pushl  0xc(%ebp)
f0101d7e:	ff 75 08             	pushl  0x8(%ebp)
f0101d81:	e8 9a ff ff ff       	call   f0101d20 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101d86:	c9                   	leave  
f0101d87:	c3                   	ret    

f0101d88 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101d88:	55                   	push   %ebp
f0101d89:	89 e5                	mov    %esp,%ebp
f0101d8b:	57                   	push   %edi
f0101d8c:	56                   	push   %esi
f0101d8d:	53                   	push   %ebx
f0101d8e:	83 ec 0c             	sub    $0xc,%esp
f0101d91:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101d94:	85 c0                	test   %eax,%eax
f0101d96:	74 11                	je     f0101da9 <readline+0x21>
		cprintf("%s", prompt);
f0101d98:	83 ec 08             	sub    $0x8,%esp
f0101d9b:	50                   	push   %eax
f0101d9c:	68 b4 2b 10 f0       	push   $0xf0102bb4
f0101da1:	e8 85 f7 ff ff       	call   f010152b <cprintf>
f0101da6:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101da9:	83 ec 0c             	sub    $0xc,%esp
f0101dac:	6a 00                	push   $0x0
f0101dae:	e8 93 e8 ff ff       	call   f0100646 <iscons>
f0101db3:	89 c7                	mov    %eax,%edi
f0101db5:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101db8:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101dbd:	e8 73 e8 ff ff       	call   f0100635 <getchar>
f0101dc2:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101dc4:	85 c0                	test   %eax,%eax
f0101dc6:	79 18                	jns    f0101de0 <readline+0x58>
			cprintf("read error: %e\n", c);
f0101dc8:	83 ec 08             	sub    $0x8,%esp
f0101dcb:	50                   	push   %eax
f0101dcc:	68 c0 2f 10 f0       	push   $0xf0102fc0
f0101dd1:	e8 55 f7 ff ff       	call   f010152b <cprintf>
			return NULL;
f0101dd6:	83 c4 10             	add    $0x10,%esp
f0101dd9:	b8 00 00 00 00       	mov    $0x0,%eax
f0101dde:	eb 79                	jmp    f0101e59 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101de0:	83 f8 08             	cmp    $0x8,%eax
f0101de3:	0f 94 c2             	sete   %dl
f0101de6:	83 f8 7f             	cmp    $0x7f,%eax
f0101de9:	0f 94 c0             	sete   %al
f0101dec:	08 c2                	or     %al,%dl
f0101dee:	74 1a                	je     f0101e0a <readline+0x82>
f0101df0:	85 f6                	test   %esi,%esi
f0101df2:	7e 16                	jle    f0101e0a <readline+0x82>
			if (echoing)
f0101df4:	85 ff                	test   %edi,%edi
f0101df6:	74 0d                	je     f0101e05 <readline+0x7d>
				cputchar('\b');
f0101df8:	83 ec 0c             	sub    $0xc,%esp
f0101dfb:	6a 08                	push   $0x8
f0101dfd:	e8 23 e8 ff ff       	call   f0100625 <cputchar>
f0101e02:	83 c4 10             	add    $0x10,%esp
			i--;
f0101e05:	83 ee 01             	sub    $0x1,%esi
f0101e08:	eb b3                	jmp    f0101dbd <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101e0a:	83 fb 1f             	cmp    $0x1f,%ebx
f0101e0d:	7e 23                	jle    f0101e32 <readline+0xaa>
f0101e0f:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101e15:	7f 1b                	jg     f0101e32 <readline+0xaa>
			if (echoing)
f0101e17:	85 ff                	test   %edi,%edi
f0101e19:	74 0c                	je     f0101e27 <readline+0x9f>
				cputchar(c);
f0101e1b:	83 ec 0c             	sub    $0xc,%esp
f0101e1e:	53                   	push   %ebx
f0101e1f:	e8 01 e8 ff ff       	call   f0100625 <cputchar>
f0101e24:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101e27:	88 9e 60 45 11 f0    	mov    %bl,-0xfeebaa0(%esi)
f0101e2d:	8d 76 01             	lea    0x1(%esi),%esi
f0101e30:	eb 8b                	jmp    f0101dbd <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101e32:	83 fb 0a             	cmp    $0xa,%ebx
f0101e35:	74 05                	je     f0101e3c <readline+0xb4>
f0101e37:	83 fb 0d             	cmp    $0xd,%ebx
f0101e3a:	75 81                	jne    f0101dbd <readline+0x35>
			if (echoing)
f0101e3c:	85 ff                	test   %edi,%edi
f0101e3e:	74 0d                	je     f0101e4d <readline+0xc5>
				cputchar('\n');
f0101e40:	83 ec 0c             	sub    $0xc,%esp
f0101e43:	6a 0a                	push   $0xa
f0101e45:	e8 db e7 ff ff       	call   f0100625 <cputchar>
f0101e4a:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101e4d:	c6 86 60 45 11 f0 00 	movb   $0x0,-0xfeebaa0(%esi)
			return buf;
f0101e54:	b8 60 45 11 f0       	mov    $0xf0114560,%eax
		}
	}
}
f0101e59:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101e5c:	5b                   	pop    %ebx
f0101e5d:	5e                   	pop    %esi
f0101e5e:	5f                   	pop    %edi
f0101e5f:	5d                   	pop    %ebp
f0101e60:	c3                   	ret    

f0101e61 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101e61:	55                   	push   %ebp
f0101e62:	89 e5                	mov    %esp,%ebp
f0101e64:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101e67:	b8 00 00 00 00       	mov    $0x0,%eax
f0101e6c:	eb 03                	jmp    f0101e71 <strlen+0x10>
		n++;
f0101e6e:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101e71:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101e75:	75 f7                	jne    f0101e6e <strlen+0xd>
		n++;
	return n;
}
f0101e77:	5d                   	pop    %ebp
f0101e78:	c3                   	ret    

f0101e79 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101e79:	55                   	push   %ebp
f0101e7a:	89 e5                	mov    %esp,%ebp
f0101e7c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101e7f:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101e82:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e87:	eb 03                	jmp    f0101e8c <strnlen+0x13>
		n++;
f0101e89:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101e8c:	39 c2                	cmp    %eax,%edx
f0101e8e:	74 08                	je     f0101e98 <strnlen+0x1f>
f0101e90:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101e94:	75 f3                	jne    f0101e89 <strnlen+0x10>
f0101e96:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101e98:	5d                   	pop    %ebp
f0101e99:	c3                   	ret    

f0101e9a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101e9a:	55                   	push   %ebp
f0101e9b:	89 e5                	mov    %esp,%ebp
f0101e9d:	53                   	push   %ebx
f0101e9e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ea1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101ea4:	89 c2                	mov    %eax,%edx
f0101ea6:	83 c2 01             	add    $0x1,%edx
f0101ea9:	83 c1 01             	add    $0x1,%ecx
f0101eac:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101eb0:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101eb3:	84 db                	test   %bl,%bl
f0101eb5:	75 ef                	jne    f0101ea6 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101eb7:	5b                   	pop    %ebx
f0101eb8:	5d                   	pop    %ebp
f0101eb9:	c3                   	ret    

f0101eba <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101eba:	55                   	push   %ebp
f0101ebb:	89 e5                	mov    %esp,%ebp
f0101ebd:	53                   	push   %ebx
f0101ebe:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101ec1:	53                   	push   %ebx
f0101ec2:	e8 9a ff ff ff       	call   f0101e61 <strlen>
f0101ec7:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101eca:	ff 75 0c             	pushl  0xc(%ebp)
f0101ecd:	01 d8                	add    %ebx,%eax
f0101ecf:	50                   	push   %eax
f0101ed0:	e8 c5 ff ff ff       	call   f0101e9a <strcpy>
	return dst;
}
f0101ed5:	89 d8                	mov    %ebx,%eax
f0101ed7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101eda:	c9                   	leave  
f0101edb:	c3                   	ret    

f0101edc <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101edc:	55                   	push   %ebp
f0101edd:	89 e5                	mov    %esp,%ebp
f0101edf:	56                   	push   %esi
f0101ee0:	53                   	push   %ebx
f0101ee1:	8b 75 08             	mov    0x8(%ebp),%esi
f0101ee4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101ee7:	89 f3                	mov    %esi,%ebx
f0101ee9:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101eec:	89 f2                	mov    %esi,%edx
f0101eee:	eb 0f                	jmp    f0101eff <strncpy+0x23>
		*dst++ = *src;
f0101ef0:	83 c2 01             	add    $0x1,%edx
f0101ef3:	0f b6 01             	movzbl (%ecx),%eax
f0101ef6:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101ef9:	80 39 01             	cmpb   $0x1,(%ecx)
f0101efc:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101eff:	39 da                	cmp    %ebx,%edx
f0101f01:	75 ed                	jne    f0101ef0 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101f03:	89 f0                	mov    %esi,%eax
f0101f05:	5b                   	pop    %ebx
f0101f06:	5e                   	pop    %esi
f0101f07:	5d                   	pop    %ebp
f0101f08:	c3                   	ret    

f0101f09 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101f09:	55                   	push   %ebp
f0101f0a:	89 e5                	mov    %esp,%ebp
f0101f0c:	56                   	push   %esi
f0101f0d:	53                   	push   %ebx
f0101f0e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101f11:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101f14:	8b 55 10             	mov    0x10(%ebp),%edx
f0101f17:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101f19:	85 d2                	test   %edx,%edx
f0101f1b:	74 21                	je     f0101f3e <strlcpy+0x35>
f0101f1d:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101f21:	89 f2                	mov    %esi,%edx
f0101f23:	eb 09                	jmp    f0101f2e <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101f25:	83 c2 01             	add    $0x1,%edx
f0101f28:	83 c1 01             	add    $0x1,%ecx
f0101f2b:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101f2e:	39 c2                	cmp    %eax,%edx
f0101f30:	74 09                	je     f0101f3b <strlcpy+0x32>
f0101f32:	0f b6 19             	movzbl (%ecx),%ebx
f0101f35:	84 db                	test   %bl,%bl
f0101f37:	75 ec                	jne    f0101f25 <strlcpy+0x1c>
f0101f39:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101f3b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101f3e:	29 f0                	sub    %esi,%eax
}
f0101f40:	5b                   	pop    %ebx
f0101f41:	5e                   	pop    %esi
f0101f42:	5d                   	pop    %ebp
f0101f43:	c3                   	ret    

f0101f44 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101f44:	55                   	push   %ebp
f0101f45:	89 e5                	mov    %esp,%ebp
f0101f47:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101f4a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101f4d:	eb 06                	jmp    f0101f55 <strcmp+0x11>
		p++, q++;
f0101f4f:	83 c1 01             	add    $0x1,%ecx
f0101f52:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101f55:	0f b6 01             	movzbl (%ecx),%eax
f0101f58:	84 c0                	test   %al,%al
f0101f5a:	74 04                	je     f0101f60 <strcmp+0x1c>
f0101f5c:	3a 02                	cmp    (%edx),%al
f0101f5e:	74 ef                	je     f0101f4f <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101f60:	0f b6 c0             	movzbl %al,%eax
f0101f63:	0f b6 12             	movzbl (%edx),%edx
f0101f66:	29 d0                	sub    %edx,%eax
}
f0101f68:	5d                   	pop    %ebp
f0101f69:	c3                   	ret    

f0101f6a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101f6a:	55                   	push   %ebp
f0101f6b:	89 e5                	mov    %esp,%ebp
f0101f6d:	53                   	push   %ebx
f0101f6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f71:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101f74:	89 c3                	mov    %eax,%ebx
f0101f76:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101f79:	eb 06                	jmp    f0101f81 <strncmp+0x17>
		n--, p++, q++;
f0101f7b:	83 c0 01             	add    $0x1,%eax
f0101f7e:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101f81:	39 d8                	cmp    %ebx,%eax
f0101f83:	74 15                	je     f0101f9a <strncmp+0x30>
f0101f85:	0f b6 08             	movzbl (%eax),%ecx
f0101f88:	84 c9                	test   %cl,%cl
f0101f8a:	74 04                	je     f0101f90 <strncmp+0x26>
f0101f8c:	3a 0a                	cmp    (%edx),%cl
f0101f8e:	74 eb                	je     f0101f7b <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101f90:	0f b6 00             	movzbl (%eax),%eax
f0101f93:	0f b6 12             	movzbl (%edx),%edx
f0101f96:	29 d0                	sub    %edx,%eax
f0101f98:	eb 05                	jmp    f0101f9f <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101f9a:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101f9f:	5b                   	pop    %ebx
f0101fa0:	5d                   	pop    %ebp
f0101fa1:	c3                   	ret    

f0101fa2 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101fa2:	55                   	push   %ebp
f0101fa3:	89 e5                	mov    %esp,%ebp
f0101fa5:	8b 45 08             	mov    0x8(%ebp),%eax
f0101fa8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101fac:	eb 07                	jmp    f0101fb5 <strchr+0x13>
		if (*s == c)
f0101fae:	38 ca                	cmp    %cl,%dl
f0101fb0:	74 0f                	je     f0101fc1 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101fb2:	83 c0 01             	add    $0x1,%eax
f0101fb5:	0f b6 10             	movzbl (%eax),%edx
f0101fb8:	84 d2                	test   %dl,%dl
f0101fba:	75 f2                	jne    f0101fae <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101fbc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101fc1:	5d                   	pop    %ebp
f0101fc2:	c3                   	ret    

f0101fc3 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101fc3:	55                   	push   %ebp
f0101fc4:	89 e5                	mov    %esp,%ebp
f0101fc6:	8b 45 08             	mov    0x8(%ebp),%eax
f0101fc9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101fcd:	eb 03                	jmp    f0101fd2 <strfind+0xf>
f0101fcf:	83 c0 01             	add    $0x1,%eax
f0101fd2:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101fd5:	38 ca                	cmp    %cl,%dl
f0101fd7:	74 04                	je     f0101fdd <strfind+0x1a>
f0101fd9:	84 d2                	test   %dl,%dl
f0101fdb:	75 f2                	jne    f0101fcf <strfind+0xc>
			break;
	return (char *) s;
}
f0101fdd:	5d                   	pop    %ebp
f0101fde:	c3                   	ret    

f0101fdf <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101fdf:	55                   	push   %ebp
f0101fe0:	89 e5                	mov    %esp,%ebp
f0101fe2:	57                   	push   %edi
f0101fe3:	56                   	push   %esi
f0101fe4:	53                   	push   %ebx
f0101fe5:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101fe8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101feb:	85 c9                	test   %ecx,%ecx
f0101fed:	74 36                	je     f0102025 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101fef:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101ff5:	75 28                	jne    f010201f <memset+0x40>
f0101ff7:	f6 c1 03             	test   $0x3,%cl
f0101ffa:	75 23                	jne    f010201f <memset+0x40>
		c &= 0xFF;
f0101ffc:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0102000:	89 d3                	mov    %edx,%ebx
f0102002:	c1 e3 08             	shl    $0x8,%ebx
f0102005:	89 d6                	mov    %edx,%esi
f0102007:	c1 e6 18             	shl    $0x18,%esi
f010200a:	89 d0                	mov    %edx,%eax
f010200c:	c1 e0 10             	shl    $0x10,%eax
f010200f:	09 f0                	or     %esi,%eax
f0102011:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0102013:	89 d8                	mov    %ebx,%eax
f0102015:	09 d0                	or     %edx,%eax
f0102017:	c1 e9 02             	shr    $0x2,%ecx
f010201a:	fc                   	cld    
f010201b:	f3 ab                	rep stos %eax,%es:(%edi)
f010201d:	eb 06                	jmp    f0102025 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010201f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102022:	fc                   	cld    
f0102023:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0102025:	89 f8                	mov    %edi,%eax
f0102027:	5b                   	pop    %ebx
f0102028:	5e                   	pop    %esi
f0102029:	5f                   	pop    %edi
f010202a:	5d                   	pop    %ebp
f010202b:	c3                   	ret    

f010202c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010202c:	55                   	push   %ebp
f010202d:	89 e5                	mov    %esp,%ebp
f010202f:	57                   	push   %edi
f0102030:	56                   	push   %esi
f0102031:	8b 45 08             	mov    0x8(%ebp),%eax
f0102034:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102037:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010203a:	39 c6                	cmp    %eax,%esi
f010203c:	73 35                	jae    f0102073 <memmove+0x47>
f010203e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102041:	39 d0                	cmp    %edx,%eax
f0102043:	73 2e                	jae    f0102073 <memmove+0x47>
		s += n;
		d += n;
f0102045:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102048:	89 d6                	mov    %edx,%esi
f010204a:	09 fe                	or     %edi,%esi
f010204c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0102052:	75 13                	jne    f0102067 <memmove+0x3b>
f0102054:	f6 c1 03             	test   $0x3,%cl
f0102057:	75 0e                	jne    f0102067 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0102059:	83 ef 04             	sub    $0x4,%edi
f010205c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010205f:	c1 e9 02             	shr    $0x2,%ecx
f0102062:	fd                   	std    
f0102063:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102065:	eb 09                	jmp    f0102070 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0102067:	83 ef 01             	sub    $0x1,%edi
f010206a:	8d 72 ff             	lea    -0x1(%edx),%esi
f010206d:	fd                   	std    
f010206e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0102070:	fc                   	cld    
f0102071:	eb 1d                	jmp    f0102090 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102073:	89 f2                	mov    %esi,%edx
f0102075:	09 c2                	or     %eax,%edx
f0102077:	f6 c2 03             	test   $0x3,%dl
f010207a:	75 0f                	jne    f010208b <memmove+0x5f>
f010207c:	f6 c1 03             	test   $0x3,%cl
f010207f:	75 0a                	jne    f010208b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0102081:	c1 e9 02             	shr    $0x2,%ecx
f0102084:	89 c7                	mov    %eax,%edi
f0102086:	fc                   	cld    
f0102087:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102089:	eb 05                	jmp    f0102090 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010208b:	89 c7                	mov    %eax,%edi
f010208d:	fc                   	cld    
f010208e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0102090:	5e                   	pop    %esi
f0102091:	5f                   	pop    %edi
f0102092:	5d                   	pop    %ebp
f0102093:	c3                   	ret    

f0102094 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0102094:	55                   	push   %ebp
f0102095:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0102097:	ff 75 10             	pushl  0x10(%ebp)
f010209a:	ff 75 0c             	pushl  0xc(%ebp)
f010209d:	ff 75 08             	pushl  0x8(%ebp)
f01020a0:	e8 87 ff ff ff       	call   f010202c <memmove>
}
f01020a5:	c9                   	leave  
f01020a6:	c3                   	ret    

f01020a7 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01020a7:	55                   	push   %ebp
f01020a8:	89 e5                	mov    %esp,%ebp
f01020aa:	56                   	push   %esi
f01020ab:	53                   	push   %ebx
f01020ac:	8b 45 08             	mov    0x8(%ebp),%eax
f01020af:	8b 55 0c             	mov    0xc(%ebp),%edx
f01020b2:	89 c6                	mov    %eax,%esi
f01020b4:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01020b7:	eb 1a                	jmp    f01020d3 <memcmp+0x2c>
		if (*s1 != *s2)
f01020b9:	0f b6 08             	movzbl (%eax),%ecx
f01020bc:	0f b6 1a             	movzbl (%edx),%ebx
f01020bf:	38 d9                	cmp    %bl,%cl
f01020c1:	74 0a                	je     f01020cd <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01020c3:	0f b6 c1             	movzbl %cl,%eax
f01020c6:	0f b6 db             	movzbl %bl,%ebx
f01020c9:	29 d8                	sub    %ebx,%eax
f01020cb:	eb 0f                	jmp    f01020dc <memcmp+0x35>
		s1++, s2++;
f01020cd:	83 c0 01             	add    $0x1,%eax
f01020d0:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01020d3:	39 f0                	cmp    %esi,%eax
f01020d5:	75 e2                	jne    f01020b9 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01020d7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01020dc:	5b                   	pop    %ebx
f01020dd:	5e                   	pop    %esi
f01020de:	5d                   	pop    %ebp
f01020df:	c3                   	ret    

f01020e0 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01020e0:	55                   	push   %ebp
f01020e1:	89 e5                	mov    %esp,%ebp
f01020e3:	53                   	push   %ebx
f01020e4:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01020e7:	89 c1                	mov    %eax,%ecx
f01020e9:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01020ec:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01020f0:	eb 0a                	jmp    f01020fc <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01020f2:	0f b6 10             	movzbl (%eax),%edx
f01020f5:	39 da                	cmp    %ebx,%edx
f01020f7:	74 07                	je     f0102100 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01020f9:	83 c0 01             	add    $0x1,%eax
f01020fc:	39 c8                	cmp    %ecx,%eax
f01020fe:	72 f2                	jb     f01020f2 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0102100:	5b                   	pop    %ebx
f0102101:	5d                   	pop    %ebp
f0102102:	c3                   	ret    

f0102103 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0102103:	55                   	push   %ebp
f0102104:	89 e5                	mov    %esp,%ebp
f0102106:	57                   	push   %edi
f0102107:	56                   	push   %esi
f0102108:	53                   	push   %ebx
f0102109:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010210c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010210f:	eb 03                	jmp    f0102114 <strtol+0x11>
		s++;
f0102111:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102114:	0f b6 01             	movzbl (%ecx),%eax
f0102117:	3c 20                	cmp    $0x20,%al
f0102119:	74 f6                	je     f0102111 <strtol+0xe>
f010211b:	3c 09                	cmp    $0x9,%al
f010211d:	74 f2                	je     f0102111 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010211f:	3c 2b                	cmp    $0x2b,%al
f0102121:	75 0a                	jne    f010212d <strtol+0x2a>
		s++;
f0102123:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0102126:	bf 00 00 00 00       	mov    $0x0,%edi
f010212b:	eb 11                	jmp    f010213e <strtol+0x3b>
f010212d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0102132:	3c 2d                	cmp    $0x2d,%al
f0102134:	75 08                	jne    f010213e <strtol+0x3b>
		s++, neg = 1;
f0102136:	83 c1 01             	add    $0x1,%ecx
f0102139:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010213e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0102144:	75 15                	jne    f010215b <strtol+0x58>
f0102146:	80 39 30             	cmpb   $0x30,(%ecx)
f0102149:	75 10                	jne    f010215b <strtol+0x58>
f010214b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010214f:	75 7c                	jne    f01021cd <strtol+0xca>
		s += 2, base = 16;
f0102151:	83 c1 02             	add    $0x2,%ecx
f0102154:	bb 10 00 00 00       	mov    $0x10,%ebx
f0102159:	eb 16                	jmp    f0102171 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010215b:	85 db                	test   %ebx,%ebx
f010215d:	75 12                	jne    f0102171 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010215f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0102164:	80 39 30             	cmpb   $0x30,(%ecx)
f0102167:	75 08                	jne    f0102171 <strtol+0x6e>
		s++, base = 8;
f0102169:	83 c1 01             	add    $0x1,%ecx
f010216c:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0102171:	b8 00 00 00 00       	mov    $0x0,%eax
f0102176:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0102179:	0f b6 11             	movzbl (%ecx),%edx
f010217c:	8d 72 d0             	lea    -0x30(%edx),%esi
f010217f:	89 f3                	mov    %esi,%ebx
f0102181:	80 fb 09             	cmp    $0x9,%bl
f0102184:	77 08                	ja     f010218e <strtol+0x8b>
			dig = *s - '0';
f0102186:	0f be d2             	movsbl %dl,%edx
f0102189:	83 ea 30             	sub    $0x30,%edx
f010218c:	eb 22                	jmp    f01021b0 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010218e:	8d 72 9f             	lea    -0x61(%edx),%esi
f0102191:	89 f3                	mov    %esi,%ebx
f0102193:	80 fb 19             	cmp    $0x19,%bl
f0102196:	77 08                	ja     f01021a0 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0102198:	0f be d2             	movsbl %dl,%edx
f010219b:	83 ea 57             	sub    $0x57,%edx
f010219e:	eb 10                	jmp    f01021b0 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01021a0:	8d 72 bf             	lea    -0x41(%edx),%esi
f01021a3:	89 f3                	mov    %esi,%ebx
f01021a5:	80 fb 19             	cmp    $0x19,%bl
f01021a8:	77 16                	ja     f01021c0 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01021aa:	0f be d2             	movsbl %dl,%edx
f01021ad:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01021b0:	3b 55 10             	cmp    0x10(%ebp),%edx
f01021b3:	7d 0b                	jge    f01021c0 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01021b5:	83 c1 01             	add    $0x1,%ecx
f01021b8:	0f af 45 10          	imul   0x10(%ebp),%eax
f01021bc:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01021be:	eb b9                	jmp    f0102179 <strtol+0x76>

	if (endptr)
f01021c0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01021c4:	74 0d                	je     f01021d3 <strtol+0xd0>
		*endptr = (char *) s;
f01021c6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01021c9:	89 0e                	mov    %ecx,(%esi)
f01021cb:	eb 06                	jmp    f01021d3 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01021cd:	85 db                	test   %ebx,%ebx
f01021cf:	74 98                	je     f0102169 <strtol+0x66>
f01021d1:	eb 9e                	jmp    f0102171 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01021d3:	89 c2                	mov    %eax,%edx
f01021d5:	f7 da                	neg    %edx
f01021d7:	85 ff                	test   %edi,%edi
f01021d9:	0f 45 c2             	cmovne %edx,%eax
}
f01021dc:	5b                   	pop    %ebx
f01021dd:	5e                   	pop    %esi
f01021de:	5f                   	pop    %edi
f01021df:	5d                   	pop    %ebp
f01021e0:	c3                   	ret    
f01021e1:	66 90                	xchg   %ax,%ax
f01021e3:	66 90                	xchg   %ax,%ax
f01021e5:	66 90                	xchg   %ax,%ax
f01021e7:	66 90                	xchg   %ax,%ax
f01021e9:	66 90                	xchg   %ax,%ax
f01021eb:	66 90                	xchg   %ax,%ax
f01021ed:	66 90                	xchg   %ax,%ax
f01021ef:	90                   	nop

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

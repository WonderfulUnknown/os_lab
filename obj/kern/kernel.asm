
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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 e0 18 10 f0       	push   $0xf01018e0
f0100050:	e8 43 09 00 00       	call   f0100998 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 2f 07 00 00       	call   f01007aa <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 fc 18 10 f0       	push   $0xf01018fc
f0100087:	e8 0c 09 00 00       	call   f0100998 <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 9b 13 00 00       	call   f010144c <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 c2 04 00 00       	call   f0100578 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 17 19 10 f0       	push   $0xf0101917
f01000c3:	e8 d0 08 00 00       	call   f0100998 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 4a 07 00 00       	call   f010082b <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 32 19 10 f0       	push   $0xf0101932
f0100110:	e8 83 08 00 00       	call   f0100998 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 53 08 00 00       	call   f0100972 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 29 1c 10 f0 	movl   $0xf0101c29,(%esp)
f0100126:	e8 6d 08 00 00       	call   f0100998 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 f3 06 00 00       	call   f010082b <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 4a 19 10 f0       	push   $0xf010194a
f0100152:	e8 41 08 00 00       	call   f0100998 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 0f 08 00 00       	call   f0100972 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 29 1c 10 f0 	movl   $0xf0101c29,(%esp)
f010016a:	e8 29 08 00 00       	call   f0100998 <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f0 00 00 00    	je     f01002d7 <kbd_proc_data+0xfe>
f01001e7:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ec:	ec                   	in     (%dx),%al
f01001ed:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001ef:	3c e0                	cmp    $0xe0,%al
f01001f1:	75 0d                	jne    f0100200 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001f3:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f01001fa:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001ff:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100200:	55                   	push   %ebp
f0100201:	89 e5                	mov    %esp,%ebp
f0100203:	53                   	push   %ebx
f0100204:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100207:	84 c0                	test   %al,%al
f0100209:	79 36                	jns    f0100241 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010020b:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100211:	89 cb                	mov    %ecx,%ebx
f0100213:	83 e3 40             	and    $0x40,%ebx
f0100216:	83 e0 7f             	and    $0x7f,%eax
f0100219:	85 db                	test   %ebx,%ebx
f010021b:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010021e:	0f b6 d2             	movzbl %dl,%edx
f0100221:	0f b6 82 c0 1a 10 f0 	movzbl -0xfefe540(%edx),%eax
f0100228:	83 c8 40             	or     $0x40,%eax
f010022b:	0f b6 c0             	movzbl %al,%eax
f010022e:	f7 d0                	not    %eax
f0100230:	21 c8                	and    %ecx,%eax
f0100232:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f0100237:	b8 00 00 00 00       	mov    $0x0,%eax
f010023c:	e9 9e 00 00 00       	jmp    f01002df <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100241:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100247:	f6 c1 40             	test   $0x40,%cl
f010024a:	74 0e                	je     f010025a <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010024c:	83 c8 80             	or     $0xffffff80,%eax
f010024f:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100251:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100254:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010025a:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010025d:	0f b6 82 c0 1a 10 f0 	movzbl -0xfefe540(%edx),%eax
f0100264:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f010026a:	0f b6 8a c0 19 10 f0 	movzbl -0xfefe640(%edx),%ecx
f0100271:	31 c8                	xor    %ecx,%eax
f0100273:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100278:	89 c1                	mov    %eax,%ecx
f010027a:	83 e1 03             	and    $0x3,%ecx
f010027d:	8b 0c 8d a0 19 10 f0 	mov    -0xfefe660(,%ecx,4),%ecx
f0100284:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100288:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010028b:	a8 08                	test   $0x8,%al
f010028d:	74 1b                	je     f01002aa <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f010028f:	89 da                	mov    %ebx,%edx
f0100291:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100294:	83 f9 19             	cmp    $0x19,%ecx
f0100297:	77 05                	ja     f010029e <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100299:	83 eb 20             	sub    $0x20,%ebx
f010029c:	eb 0c                	jmp    f01002aa <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f010029e:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a1:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a4:	83 fa 19             	cmp    $0x19,%edx
f01002a7:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002aa:	f7 d0                	not    %eax
f01002ac:	a8 06                	test   $0x6,%al
f01002ae:	75 2d                	jne    f01002dd <kbd_proc_data+0x104>
f01002b0:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002b6:	75 25                	jne    f01002dd <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002b8:	83 ec 0c             	sub    $0xc,%esp
f01002bb:	68 64 19 10 f0       	push   $0xf0101964
f01002c0:	e8 d3 06 00 00       	call   f0100998 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c5:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ca:	b8 03 00 00 00       	mov    $0x3,%eax
f01002cf:	ee                   	out    %al,(%dx)
f01002d0:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
f01002d5:	eb 08                	jmp    f01002df <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002dc:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002dd:	89 d8                	mov    %ebx,%eax
}
f01002df:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002e2:	c9                   	leave  
f01002e3:	c3                   	ret    

f01002e4 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002e4:	55                   	push   %ebp
f01002e5:	89 e5                	mov    %esp,%ebp
f01002e7:	57                   	push   %edi
f01002e8:	56                   	push   %esi
f01002e9:	53                   	push   %ebx
f01002ea:	83 ec 1c             	sub    $0x1c,%esp
f01002ed:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ef:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f4:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002f9:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fe:	eb 09                	jmp    f0100309 <cons_putc+0x25>
f0100300:	89 ca                	mov    %ecx,%edx
f0100302:	ec                   	in     (%dx),%al
f0100303:	ec                   	in     (%dx),%al
f0100304:	ec                   	in     (%dx),%al
f0100305:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100306:	83 c3 01             	add    $0x1,%ebx
f0100309:	89 f2                	mov    %esi,%edx
f010030b:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010030c:	a8 20                	test   $0x20,%al
f010030e:	75 08                	jne    f0100318 <cons_putc+0x34>
f0100310:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100316:	7e e8                	jle    f0100300 <cons_putc+0x1c>
f0100318:	89 f8                	mov    %edi,%eax
f010031a:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100322:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100323:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100328:	be 79 03 00 00       	mov    $0x379,%esi
f010032d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100332:	eb 09                	jmp    f010033d <cons_putc+0x59>
f0100334:	89 ca                	mov    %ecx,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	ec                   	in     (%dx),%al
f010033a:	83 c3 01             	add    $0x1,%ebx
f010033d:	89 f2                	mov    %esi,%edx
f010033f:	ec                   	in     (%dx),%al
f0100340:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100346:	7f 04                	jg     f010034c <cons_putc+0x68>
f0100348:	84 c0                	test   %al,%al
f010034a:	79 e8                	jns    f0100334 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100351:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100355:	ee                   	out    %al,(%dx)
f0100356:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010035b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100360:	ee                   	out    %al,(%dx)
f0100361:	b8 08 00 00 00       	mov    $0x8,%eax
f0100366:	ee                   	out    %al,(%dx)
cga_putc(int c)
{
	// if no attribute given, then use black on white
	//if (!(c & ~0xFF))
	//	c |= 0x0700;
	if (!(c & ~0xFF)){
f0100367:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f010036d:	75 3d                	jne    f01003ac <cons_putc+0xc8>
    	  char ch = c & 0xFF;
    	    if (ch > 47 && ch < 58) {
f010036f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100373:	83 e8 30             	sub    $0x30,%eax
f0100376:	3c 09                	cmp    $0x9,%al
f0100378:	77 08                	ja     f0100382 <cons_putc+0x9e>
              c |= 0x0100;
f010037a:	81 cf 00 01 00 00    	or     $0x100,%edi
f0100380:	eb 2a                	jmp    f01003ac <cons_putc+0xc8>
    	    }
	    else if (ch > 64 && ch < 91) {
f0100382:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100386:	83 e8 41             	sub    $0x41,%eax
f0100389:	3c 19                	cmp    $0x19,%al
f010038b:	77 08                	ja     f0100395 <cons_putc+0xb1>
              c |= 0x0200;
f010038d:	81 cf 00 02 00 00    	or     $0x200,%edi
f0100393:	eb 17                	jmp    f01003ac <cons_putc+0xc8>
    	    }
	    else if (ch > 96 && ch < 123) {
f0100395:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100399:	83 e8 61             	sub    $0x61,%eax
              c |= 0x0300;
f010039c:	89 fa                	mov    %edi,%edx
f010039e:	80 ce 03             	or     $0x3,%dh
f01003a1:	81 cf 00 04 00 00    	or     $0x400,%edi
f01003a7:	3c 19                	cmp    $0x19,%al
f01003a9:	0f 46 fa             	cmovbe %edx,%edi
    	    }
	    else {
              c |= 0x0400;
    	    }
	}
	switch (c & 0xff) {
f01003ac:	89 f8                	mov    %edi,%eax
f01003ae:	0f b6 c0             	movzbl %al,%eax
f01003b1:	83 f8 09             	cmp    $0x9,%eax
f01003b4:	74 74                	je     f010042a <cons_putc+0x146>
f01003b6:	83 f8 09             	cmp    $0x9,%eax
f01003b9:	7f 0a                	jg     f01003c5 <cons_putc+0xe1>
f01003bb:	83 f8 08             	cmp    $0x8,%eax
f01003be:	74 14                	je     f01003d4 <cons_putc+0xf0>
f01003c0:	e9 99 00 00 00       	jmp    f010045e <cons_putc+0x17a>
f01003c5:	83 f8 0a             	cmp    $0xa,%eax
f01003c8:	74 3a                	je     f0100404 <cons_putc+0x120>
f01003ca:	83 f8 0d             	cmp    $0xd,%eax
f01003cd:	74 3d                	je     f010040c <cons_putc+0x128>
f01003cf:	e9 8a 00 00 00       	jmp    f010045e <cons_putc+0x17a>
	case '\b':
		if (crt_pos > 0) {
f01003d4:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003db:	66 85 c0             	test   %ax,%ax
f01003de:	0f 84 e6 00 00 00    	je     f01004ca <cons_putc+0x1e6>
			crt_pos--;
f01003e4:	83 e8 01             	sub    $0x1,%eax
f01003e7:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003ed:	0f b7 c0             	movzwl %ax,%eax
f01003f0:	66 81 e7 00 ff       	and    $0xff00,%di
f01003f5:	83 cf 20             	or     $0x20,%edi
f01003f8:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003fe:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100402:	eb 78                	jmp    f010047c <cons_putc+0x198>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100404:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f010040b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010040c:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100413:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100419:	c1 e8 16             	shr    $0x16,%eax
f010041c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010041f:	c1 e0 04             	shl    $0x4,%eax
f0100422:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100428:	eb 52                	jmp    f010047c <cons_putc+0x198>
		break;
	case '\t':
		cons_putc(' ');
f010042a:	b8 20 00 00 00       	mov    $0x20,%eax
f010042f:	e8 b0 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100434:	b8 20 00 00 00       	mov    $0x20,%eax
f0100439:	e8 a6 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010043e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100443:	e8 9c fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100448:	b8 20 00 00 00       	mov    $0x20,%eax
f010044d:	e8 92 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100452:	b8 20 00 00 00       	mov    $0x20,%eax
f0100457:	e8 88 fe ff ff       	call   f01002e4 <cons_putc>
f010045c:	eb 1e                	jmp    f010047c <cons_putc+0x198>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010045e:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100465:	8d 50 01             	lea    0x1(%eax),%edx
f0100468:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010046f:	0f b7 c0             	movzwl %ax,%eax
f0100472:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100478:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010047c:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f0100483:	cf 07 
f0100485:	76 43                	jbe    f01004ca <cons_putc+0x1e6>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100487:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f010048c:	83 ec 04             	sub    $0x4,%esp
f010048f:	68 00 0f 00 00       	push   $0xf00
f0100494:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010049a:	52                   	push   %edx
f010049b:	50                   	push   %eax
f010049c:	e8 f8 0f 00 00       	call   f0101499 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01004a1:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01004a7:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004ad:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004b3:	83 c4 10             	add    $0x10,%esp
f01004b6:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004bb:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004be:	39 d0                	cmp    %edx,%eax
f01004c0:	75 f4                	jne    f01004b6 <cons_putc+0x1d2>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004c2:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004c9:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004ca:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004d0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004d5:	89 ca                	mov    %ecx,%edx
f01004d7:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004d8:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004df:	8d 71 01             	lea    0x1(%ecx),%esi
f01004e2:	89 d8                	mov    %ebx,%eax
f01004e4:	66 c1 e8 08          	shr    $0x8,%ax
f01004e8:	89 f2                	mov    %esi,%edx
f01004ea:	ee                   	out    %al,(%dx)
f01004eb:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004f0:	89 ca                	mov    %ecx,%edx
f01004f2:	ee                   	out    %al,(%dx)
f01004f3:	89 d8                	mov    %ebx,%eax
f01004f5:	89 f2                	mov    %esi,%edx
f01004f7:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004fb:	5b                   	pop    %ebx
f01004fc:	5e                   	pop    %esi
f01004fd:	5f                   	pop    %edi
f01004fe:	5d                   	pop    %ebp
f01004ff:	c3                   	ret    

f0100500 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100500:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f0100507:	74 11                	je     f010051a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100509:	55                   	push   %ebp
f010050a:	89 e5                	mov    %esp,%ebp
f010050c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010050f:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f0100514:	e8 7d fc ff ff       	call   f0100196 <cons_intr>
}
f0100519:	c9                   	leave  
f010051a:	f3 c3                	repz ret 

f010051c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010051c:	55                   	push   %ebp
f010051d:	89 e5                	mov    %esp,%ebp
f010051f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100522:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f0100527:	e8 6a fc ff ff       	call   f0100196 <cons_intr>
}
f010052c:	c9                   	leave  
f010052d:	c3                   	ret    

f010052e <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010052e:	55                   	push   %ebp
f010052f:	89 e5                	mov    %esp,%ebp
f0100531:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100534:	e8 c7 ff ff ff       	call   f0100500 <serial_intr>
	kbd_intr();
f0100539:	e8 de ff ff ff       	call   f010051c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010053e:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f0100543:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100549:	74 26                	je     f0100571 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f010054b:	8d 50 01             	lea    0x1(%eax),%edx
f010054e:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100554:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010055b:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010055d:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100563:	75 11                	jne    f0100576 <cons_getc+0x48>
			cons.rpos = 0;
f0100565:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f010056c:	00 00 00 
f010056f:	eb 05                	jmp    f0100576 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100571:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100576:	c9                   	leave  
f0100577:	c3                   	ret    

f0100578 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100578:	55                   	push   %ebp
f0100579:	89 e5                	mov    %esp,%ebp
f010057b:	57                   	push   %edi
f010057c:	56                   	push   %esi
f010057d:	53                   	push   %ebx
f010057e:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100581:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100588:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010058f:	5a a5 
	if (*cp != 0xA55A) {
f0100591:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100598:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010059c:	74 11                	je     f01005af <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010059e:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f01005a5:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005a8:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f01005ad:	eb 16                	jmp    f01005c5 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005af:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005b6:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005bd:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005c0:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005c5:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f01005cb:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005d0:	89 fa                	mov    %edi,%edx
f01005d2:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005d3:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d6:	89 da                	mov    %ebx,%edx
f01005d8:	ec                   	in     (%dx),%al
f01005d9:	0f b6 c8             	movzbl %al,%ecx
f01005dc:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005df:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005e4:	89 fa                	mov    %edi,%edx
f01005e6:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e7:	89 da                	mov    %ebx,%edx
f01005e9:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005ea:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005f0:	0f b6 c0             	movzbl %al,%eax
f01005f3:	09 c8                	or     %ecx,%eax
f01005f5:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005fb:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100600:	b8 00 00 00 00       	mov    $0x0,%eax
f0100605:	89 f2                	mov    %esi,%edx
f0100607:	ee                   	out    %al,(%dx)
f0100608:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010060d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100612:	ee                   	out    %al,(%dx)
f0100613:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100618:	b8 0c 00 00 00       	mov    $0xc,%eax
f010061d:	89 da                	mov    %ebx,%edx
f010061f:	ee                   	out    %al,(%dx)
f0100620:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100625:	b8 00 00 00 00       	mov    $0x0,%eax
f010062a:	ee                   	out    %al,(%dx)
f010062b:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100630:	b8 03 00 00 00       	mov    $0x3,%eax
f0100635:	ee                   	out    %al,(%dx)
f0100636:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010063b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100640:	ee                   	out    %al,(%dx)
f0100641:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100646:	b8 01 00 00 00       	mov    $0x1,%eax
f010064b:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010064c:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100651:	ec                   	in     (%dx),%al
f0100652:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100654:	3c ff                	cmp    $0xff,%al
f0100656:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f010065d:	89 f2                	mov    %esi,%edx
f010065f:	ec                   	in     (%dx),%al
f0100660:	89 da                	mov    %ebx,%edx
f0100662:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100663:	80 f9 ff             	cmp    $0xff,%cl
f0100666:	75 10                	jne    f0100678 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100668:	83 ec 0c             	sub    $0xc,%esp
f010066b:	68 70 19 10 f0       	push   $0xf0101970
f0100670:	e8 23 03 00 00       	call   f0100998 <cprintf>
f0100675:	83 c4 10             	add    $0x10,%esp
}
f0100678:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010067b:	5b                   	pop    %ebx
f010067c:	5e                   	pop    %esi
f010067d:	5f                   	pop    %edi
f010067e:	5d                   	pop    %ebp
f010067f:	c3                   	ret    

f0100680 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100686:	8b 45 08             	mov    0x8(%ebp),%eax
f0100689:	e8 56 fc ff ff       	call   f01002e4 <cons_putc>
}
f010068e:	c9                   	leave  
f010068f:	c3                   	ret    

f0100690 <getchar>:

int
getchar(void)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100696:	e8 93 fe ff ff       	call   f010052e <cons_getc>
f010069b:	85 c0                	test   %eax,%eax
f010069d:	74 f7                	je     f0100696 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010069f:	c9                   	leave  
f01006a0:	c3                   	ret    

f01006a1 <iscons>:

int
iscons(int fdnum)
{
f01006a1:	55                   	push   %ebp
f01006a2:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01006a4:	b8 01 00 00 00       	mov    $0x1,%eax
f01006a9:	5d                   	pop    %ebp
f01006aa:	c3                   	ret    

f01006ab <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006ab:	55                   	push   %ebp
f01006ac:	89 e5                	mov    %esp,%ebp
f01006ae:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006b1:	68 c0 1b 10 f0       	push   $0xf0101bc0
f01006b6:	68 de 1b 10 f0       	push   $0xf0101bde
f01006bb:	68 e3 1b 10 f0       	push   $0xf0101be3
f01006c0:	e8 d3 02 00 00       	call   f0100998 <cprintf>
f01006c5:	83 c4 0c             	add    $0xc,%esp
f01006c8:	68 78 1c 10 f0       	push   $0xf0101c78
f01006cd:	68 ec 1b 10 f0       	push   $0xf0101bec
f01006d2:	68 e3 1b 10 f0       	push   $0xf0101be3
f01006d7:	e8 bc 02 00 00       	call   f0100998 <cprintf>
f01006dc:	83 c4 0c             	add    $0xc,%esp
f01006df:	68 a0 1c 10 f0       	push   $0xf0101ca0
f01006e4:	68 f5 1b 10 f0       	push   $0xf0101bf5
f01006e9:	68 e3 1b 10 f0       	push   $0xf0101be3
f01006ee:	e8 a5 02 00 00       	call   f0100998 <cprintf>
	return 0;
}
f01006f3:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f8:	c9                   	leave  
f01006f9:	c3                   	ret    

f01006fa <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006fa:	55                   	push   %ebp
f01006fb:	89 e5                	mov    %esp,%ebp
f01006fd:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100700:	68 ff 1b 10 f0       	push   $0xf0101bff
f0100705:	e8 8e 02 00 00       	call   f0100998 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010070a:	83 c4 08             	add    $0x8,%esp
f010070d:	68 0c 00 10 00       	push   $0x10000c
f0100712:	68 c8 1c 10 f0       	push   $0xf0101cc8
f0100717:	e8 7c 02 00 00       	call   f0100998 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010071c:	83 c4 0c             	add    $0xc,%esp
f010071f:	68 0c 00 10 00       	push   $0x10000c
f0100724:	68 0c 00 10 f0       	push   $0xf010000c
f0100729:	68 f0 1c 10 f0       	push   $0xf0101cf0
f010072e:	e8 65 02 00 00       	call   f0100998 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100733:	83 c4 0c             	add    $0xc,%esp
f0100736:	68 d1 18 10 00       	push   $0x1018d1
f010073b:	68 d1 18 10 f0       	push   $0xf01018d1
f0100740:	68 14 1d 10 f0       	push   $0xf0101d14
f0100745:	e8 4e 02 00 00       	call   f0100998 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010074a:	83 c4 0c             	add    $0xc,%esp
f010074d:	68 00 23 11 00       	push   $0x112300
f0100752:	68 00 23 11 f0       	push   $0xf0112300
f0100757:	68 38 1d 10 f0       	push   $0xf0101d38
f010075c:	e8 37 02 00 00       	call   f0100998 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100761:	83 c4 0c             	add    $0xc,%esp
f0100764:	68 44 29 11 00       	push   $0x112944
f0100769:	68 44 29 11 f0       	push   $0xf0112944
f010076e:	68 5c 1d 10 f0       	push   $0xf0101d5c
f0100773:	e8 20 02 00 00       	call   f0100998 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100778:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010077d:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100782:	83 c4 08             	add    $0x8,%esp
f0100785:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010078a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100790:	85 c0                	test   %eax,%eax
f0100792:	0f 48 c2             	cmovs  %edx,%eax
f0100795:	c1 f8 0a             	sar    $0xa,%eax
f0100798:	50                   	push   %eax
f0100799:	68 80 1d 10 f0       	push   $0xf0101d80
f010079e:	e8 f5 01 00 00       	call   f0100998 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01007a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01007a8:	c9                   	leave  
f01007a9:	c3                   	ret    

f01007aa <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007aa:	55                   	push   %ebp
f01007ab:	89 e5                	mov    %esp,%ebp
f01007ad:	57                   	push   %edi
f01007ae:	56                   	push   %esi
f01007af:	53                   	push   %ebx
f01007b0:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007b3:	89 eb                	mov    %ebp,%ebx
	struct Eipdebuginfo info;        
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();
	
	cprintf("Stack backtrace:\r\n");
f01007b5:	68 18 1c 10 f0       	push   $0xf0101c18
f01007ba:	e8 d9 01 00 00       	call   f0100998 <cprintf>
    	while (ebp!=0)
f01007bf:	83 c4 10             	add    $0x10,%esp
    	{
	eip = ebp[1];
       	cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);
	debuginfo_eip((uintptr_t)eip,&info);
f01007c2:	8d 7d d0             	lea    -0x30(%ebp),%edi
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();
	
	cprintf("Stack backtrace:\r\n");
    	while (ebp!=0)
f01007c5:	eb 53                	jmp    f010081a <mon_backtrace+0x70>
    	{
	eip = ebp[1];
f01007c7:	8b 73 04             	mov    0x4(%ebx),%esi
       	cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);
f01007ca:	ff 73 18             	pushl  0x18(%ebx)
f01007cd:	ff 73 14             	pushl  0x14(%ebx)
f01007d0:	ff 73 10             	pushl  0x10(%ebx)
f01007d3:	ff 73 0c             	pushl  0xc(%ebx)
f01007d6:	ff 73 08             	pushl  0x8(%ebx)
f01007d9:	56                   	push   %esi
f01007da:	53                   	push   %ebx
f01007db:	68 ac 1d 10 f0       	push   $0xf0101dac
f01007e0:	e8 b3 01 00 00       	call   f0100998 <cprintf>
	debuginfo_eip((uintptr_t)eip,&info);
f01007e5:	83 c4 18             	add    $0x18,%esp
f01007e8:	57                   	push   %edi
f01007e9:	56                   	push   %esi
f01007ea:	e8 b3 02 00 00       	call   f0100aa2 <debuginfo_eip>
	cprintf("%s:%d", info.eip_file, info.eip_line);
f01007ef:	83 c4 0c             	add    $0xc,%esp
f01007f2:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007f5:	ff 75 d0             	pushl  -0x30(%ebp)
f01007f8:	68 2b 1c 10 f0       	push   $0xf0101c2b
f01007fd:	e8 96 01 00 00       	call   f0100998 <cprintf>
        cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name,info.eip_fn_addr);
f0100802:	ff 75 e0             	pushl  -0x20(%ebp)
f0100805:	ff 75 d8             	pushl  -0x28(%ebp)
f0100808:	ff 75 dc             	pushl  -0x24(%ebp)
f010080b:	68 31 1c 10 f0       	push   $0xf0101c31
f0100810:	e8 83 01 00 00       	call   f0100998 <cprintf>
   	ebp = (uint32_t *)ebp[0];
f0100815:	8b 1b                	mov    (%ebx),%ebx
f0100817:	83 c4 20             	add    $0x20,%esp
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();
	
	cprintf("Stack backtrace:\r\n");
    	while (ebp!=0)
f010081a:	85 db                	test   %ebx,%ebx
f010081c:	75 a9                	jne    f01007c7 <mon_backtrace+0x1d>
	cprintf("%s:%d", info.eip_file, info.eip_line);
        cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name,info.eip_fn_addr);
   	ebp = (uint32_t *)ebp[0];
    	}
    	return 0;
}
f010081e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100823:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100826:	5b                   	pop    %ebx
f0100827:	5e                   	pop    %esi
f0100828:	5f                   	pop    %edi
f0100829:	5d                   	pop    %ebp
f010082a:	c3                   	ret    

f010082b <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010082b:	55                   	push   %ebp
f010082c:	89 e5                	mov    %esp,%ebp
f010082e:	57                   	push   %edi
f010082f:	56                   	push   %esi
f0100830:	53                   	push   %ebx
f0100831:	83 ec 58             	sub    $0x58,%esp
	char *buf; 
	cprintf("Welcome to the JOS kernel monitor!\n");
f0100834:	68 e4 1d 10 f0       	push   $0xf0101de4
f0100839:	e8 5a 01 00 00       	call   f0100998 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010083e:	c7 04 24 08 1e 10 f0 	movl   $0xf0101e08,(%esp)
f0100845:	e8 4e 01 00 00       	call   f0100998 <cprintf>
f010084a:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010084d:	83 ec 0c             	sub    $0xc,%esp
f0100850:	68 3c 1c 10 f0       	push   $0xf0101c3c
f0100855:	e8 9b 09 00 00       	call   f01011f5 <readline>
f010085a:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010085c:	83 c4 10             	add    $0x10,%esp
f010085f:	85 c0                	test   %eax,%eax
f0100861:	74 ea                	je     f010084d <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100863:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010086a:	be 00 00 00 00       	mov    $0x0,%esi
f010086f:	eb 0a                	jmp    f010087b <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100871:	c6 03 00             	movb   $0x0,(%ebx)
f0100874:	89 f7                	mov    %esi,%edi
f0100876:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100879:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010087b:	0f b6 03             	movzbl (%ebx),%eax
f010087e:	84 c0                	test   %al,%al
f0100880:	74 63                	je     f01008e5 <monitor+0xba>
f0100882:	83 ec 08             	sub    $0x8,%esp
f0100885:	0f be c0             	movsbl %al,%eax
f0100888:	50                   	push   %eax
f0100889:	68 40 1c 10 f0       	push   $0xf0101c40
f010088e:	e8 7c 0b 00 00       	call   f010140f <strchr>
f0100893:	83 c4 10             	add    $0x10,%esp
f0100896:	85 c0                	test   %eax,%eax
f0100898:	75 d7                	jne    f0100871 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f010089a:	80 3b 00             	cmpb   $0x0,(%ebx)
f010089d:	74 46                	je     f01008e5 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010089f:	83 fe 0f             	cmp    $0xf,%esi
f01008a2:	75 14                	jne    f01008b8 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008a4:	83 ec 08             	sub    $0x8,%esp
f01008a7:	6a 10                	push   $0x10
f01008a9:	68 45 1c 10 f0       	push   $0xf0101c45
f01008ae:	e8 e5 00 00 00       	call   f0100998 <cprintf>
f01008b3:	83 c4 10             	add    $0x10,%esp
f01008b6:	eb 95                	jmp    f010084d <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01008b8:	8d 7e 01             	lea    0x1(%esi),%edi
f01008bb:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008bf:	eb 03                	jmp    f01008c4 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008c1:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008c4:	0f b6 03             	movzbl (%ebx),%eax
f01008c7:	84 c0                	test   %al,%al
f01008c9:	74 ae                	je     f0100879 <monitor+0x4e>
f01008cb:	83 ec 08             	sub    $0x8,%esp
f01008ce:	0f be c0             	movsbl %al,%eax
f01008d1:	50                   	push   %eax
f01008d2:	68 40 1c 10 f0       	push   $0xf0101c40
f01008d7:	e8 33 0b 00 00       	call   f010140f <strchr>
f01008dc:	83 c4 10             	add    $0x10,%esp
f01008df:	85 c0                	test   %eax,%eax
f01008e1:	74 de                	je     f01008c1 <monitor+0x96>
f01008e3:	eb 94                	jmp    f0100879 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01008e5:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008ec:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008ed:	85 f6                	test   %esi,%esi
f01008ef:	0f 84 58 ff ff ff    	je     f010084d <monitor+0x22>
f01008f5:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008fa:	83 ec 08             	sub    $0x8,%esp
f01008fd:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100900:	ff 34 85 40 1e 10 f0 	pushl  -0xfefe1c0(,%eax,4)
f0100907:	ff 75 a8             	pushl  -0x58(%ebp)
f010090a:	e8 a2 0a 00 00       	call   f01013b1 <strcmp>
f010090f:	83 c4 10             	add    $0x10,%esp
f0100912:	85 c0                	test   %eax,%eax
f0100914:	75 21                	jne    f0100937 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f0100916:	83 ec 04             	sub    $0x4,%esp
f0100919:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010091c:	ff 75 08             	pushl  0x8(%ebp)
f010091f:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100922:	52                   	push   %edx
f0100923:	56                   	push   %esi
f0100924:	ff 14 85 48 1e 10 f0 	call   *-0xfefe1b8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010092b:	83 c4 10             	add    $0x10,%esp
f010092e:	85 c0                	test   %eax,%eax
f0100930:	78 25                	js     f0100957 <monitor+0x12c>
f0100932:	e9 16 ff ff ff       	jmp    f010084d <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100937:	83 c3 01             	add    $0x1,%ebx
f010093a:	83 fb 03             	cmp    $0x3,%ebx
f010093d:	75 bb                	jne    f01008fa <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010093f:	83 ec 08             	sub    $0x8,%esp
f0100942:	ff 75 a8             	pushl  -0x58(%ebp)
f0100945:	68 62 1c 10 f0       	push   $0xf0101c62
f010094a:	e8 49 00 00 00       	call   f0100998 <cprintf>
f010094f:	83 c4 10             	add    $0x10,%esp
f0100952:	e9 f6 fe ff ff       	jmp    f010084d <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100957:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010095a:	5b                   	pop    %ebx
f010095b:	5e                   	pop    %esi
f010095c:	5f                   	pop    %edi
f010095d:	5d                   	pop    %ebp
f010095e:	c3                   	ret    

f010095f <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010095f:	55                   	push   %ebp
f0100960:	89 e5                	mov    %esp,%ebp
f0100962:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100965:	ff 75 08             	pushl  0x8(%ebp)
f0100968:	e8 13 fd ff ff       	call   f0100680 <cputchar>
	*cnt++;
}
f010096d:	83 c4 10             	add    $0x10,%esp
f0100970:	c9                   	leave  
f0100971:	c3                   	ret    

f0100972 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100972:	55                   	push   %ebp
f0100973:	89 e5                	mov    %esp,%ebp
f0100975:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100978:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010097f:	ff 75 0c             	pushl  0xc(%ebp)
f0100982:	ff 75 08             	pushl  0x8(%ebp)
f0100985:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100988:	50                   	push   %eax
f0100989:	68 5f 09 10 f0       	push   $0xf010095f
f010098e:	e8 4d 04 00 00       	call   f0100de0 <vprintfmt>
	return cnt;
}
f0100993:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100996:	c9                   	leave  
f0100997:	c3                   	ret    

f0100998 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100998:	55                   	push   %ebp
f0100999:	89 e5                	mov    %esp,%ebp
f010099b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010099e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009a1:	50                   	push   %eax
f01009a2:	ff 75 08             	pushl  0x8(%ebp)
f01009a5:	e8 c8 ff ff ff       	call   f0100972 <vcprintf>
	va_end(ap);

	return cnt;
}
f01009aa:	c9                   	leave  
f01009ab:	c3                   	ret    

f01009ac <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009ac:	55                   	push   %ebp
f01009ad:	89 e5                	mov    %esp,%ebp
f01009af:	57                   	push   %edi
f01009b0:	56                   	push   %esi
f01009b1:	53                   	push   %ebx
f01009b2:	83 ec 14             	sub    $0x14,%esp
f01009b5:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01009b8:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01009bb:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01009be:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009c1:	8b 1a                	mov    (%edx),%ebx
f01009c3:	8b 01                	mov    (%ecx),%eax
f01009c5:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009c8:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01009cf:	eb 7f                	jmp    f0100a50 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01009d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009d4:	01 d8                	add    %ebx,%eax
f01009d6:	89 c6                	mov    %eax,%esi
f01009d8:	c1 ee 1f             	shr    $0x1f,%esi
f01009db:	01 c6                	add    %eax,%esi
f01009dd:	d1 fe                	sar    %esi
f01009df:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01009e2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009e5:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009e8:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009ea:	eb 03                	jmp    f01009ef <stab_binsearch+0x43>
			m--;
f01009ec:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009ef:	39 c3                	cmp    %eax,%ebx
f01009f1:	7f 0d                	jg     f0100a00 <stab_binsearch+0x54>
f01009f3:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01009f7:	83 ea 0c             	sub    $0xc,%edx
f01009fa:	39 f9                	cmp    %edi,%ecx
f01009fc:	75 ee                	jne    f01009ec <stab_binsearch+0x40>
f01009fe:	eb 05                	jmp    f0100a05 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a00:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100a03:	eb 4b                	jmp    f0100a50 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a05:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a08:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a0b:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a0f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a12:	76 11                	jbe    f0100a25 <stab_binsearch+0x79>
			*region_left = m;
f0100a14:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a17:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100a19:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a1c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a23:	eb 2b                	jmp    f0100a50 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a25:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a28:	73 14                	jae    f0100a3e <stab_binsearch+0x92>
			*region_right = m - 1;
f0100a2a:	83 e8 01             	sub    $0x1,%eax
f0100a2d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a30:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a33:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a35:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a3c:	eb 12                	jmp    f0100a50 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a3e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a41:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a43:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a47:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a49:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a50:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a53:	0f 8e 78 ff ff ff    	jle    f01009d1 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a59:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a5d:	75 0f                	jne    f0100a6e <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a5f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a62:	8b 00                	mov    (%eax),%eax
f0100a64:	83 e8 01             	sub    $0x1,%eax
f0100a67:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a6a:	89 06                	mov    %eax,(%esi)
f0100a6c:	eb 2c                	jmp    f0100a9a <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a6e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a71:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a73:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a76:	8b 0e                	mov    (%esi),%ecx
f0100a78:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a7b:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a7e:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a81:	eb 03                	jmp    f0100a86 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a83:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a86:	39 c8                	cmp    %ecx,%eax
f0100a88:	7e 0b                	jle    f0100a95 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a8a:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a8e:	83 ea 0c             	sub    $0xc,%edx
f0100a91:	39 df                	cmp    %ebx,%edi
f0100a93:	75 ee                	jne    f0100a83 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a95:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a98:	89 06                	mov    %eax,(%esi)
	}
}
f0100a9a:	83 c4 14             	add    $0x14,%esp
f0100a9d:	5b                   	pop    %ebx
f0100a9e:	5e                   	pop    %esi
f0100a9f:	5f                   	pop    %edi
f0100aa0:	5d                   	pop    %ebp
f0100aa1:	c3                   	ret    

f0100aa2 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100aa2:	55                   	push   %ebp
f0100aa3:	89 e5                	mov    %esp,%ebp
f0100aa5:	57                   	push   %edi
f0100aa6:	56                   	push   %esi
f0100aa7:	53                   	push   %ebx
f0100aa8:	83 ec 2c             	sub    $0x2c,%esp
f0100aab:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100aae:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ab1:	c7 06 64 1e 10 f0    	movl   $0xf0101e64,(%esi)
	info->eip_line = 0;
f0100ab7:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100abe:	c7 46 08 64 1e 10 f0 	movl   $0xf0101e64,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100ac5:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100acc:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100acf:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ad6:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100adc:	76 11                	jbe    f0100aef <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ade:	b8 69 73 10 f0       	mov    $0xf0107369,%eax
f0100ae3:	3d 4d 5a 10 f0       	cmp    $0xf0105a4d,%eax
f0100ae8:	77 19                	ja     f0100b03 <debuginfo_eip+0x61>
f0100aea:	e9 a5 01 00 00       	jmp    f0100c94 <debuginfo_eip+0x1f2>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100aef:	83 ec 04             	sub    $0x4,%esp
f0100af2:	68 6e 1e 10 f0       	push   $0xf0101e6e
f0100af7:	6a 7f                	push   $0x7f
f0100af9:	68 7b 1e 10 f0       	push   $0xf0101e7b
f0100afe:	e8 e3 f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b03:	80 3d 68 73 10 f0 00 	cmpb   $0x0,0xf0107368
f0100b0a:	0f 85 8b 01 00 00    	jne    f0100c9b <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b10:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b17:	b8 4c 5a 10 f0       	mov    $0xf0105a4c,%eax
f0100b1c:	2d b0 20 10 f0       	sub    $0xf01020b0,%eax
f0100b21:	c1 f8 02             	sar    $0x2,%eax
f0100b24:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b2a:	83 e8 01             	sub    $0x1,%eax
f0100b2d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b30:	83 ec 08             	sub    $0x8,%esp
f0100b33:	57                   	push   %edi
f0100b34:	6a 64                	push   $0x64
f0100b36:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b39:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b3c:	b8 b0 20 10 f0       	mov    $0xf01020b0,%eax
f0100b41:	e8 66 fe ff ff       	call   f01009ac <stab_binsearch>
	if (lfile == 0)
f0100b46:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b49:	83 c4 10             	add    $0x10,%esp
f0100b4c:	85 c0                	test   %eax,%eax
f0100b4e:	0f 84 4e 01 00 00    	je     f0100ca2 <debuginfo_eip+0x200>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b54:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b57:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b5a:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b5d:	83 ec 08             	sub    $0x8,%esp
f0100b60:	57                   	push   %edi
f0100b61:	6a 24                	push   $0x24
f0100b63:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b66:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b69:	b8 b0 20 10 f0       	mov    $0xf01020b0,%eax
f0100b6e:	e8 39 fe ff ff       	call   f01009ac <stab_binsearch>

	if (lfun <= rfun) {
f0100b73:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100b76:	83 c4 10             	add    $0x10,%esp
f0100b79:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100b7c:	7f 33                	jg     f0100bb1 <debuginfo_eip+0x10f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b7e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b81:	c1 e0 02             	shl    $0x2,%eax
f0100b84:	8d 90 b0 20 10 f0    	lea    -0xfefdf50(%eax),%edx
f0100b8a:	8b 88 b0 20 10 f0    	mov    -0xfefdf50(%eax),%ecx
f0100b90:	b8 69 73 10 f0       	mov    $0xf0107369,%eax
f0100b95:	2d 4d 5a 10 f0       	sub    $0xf0105a4d,%eax
f0100b9a:	39 c1                	cmp    %eax,%ecx
f0100b9c:	73 09                	jae    f0100ba7 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b9e:	81 c1 4d 5a 10 f0    	add    $0xf0105a4d,%ecx
f0100ba4:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100ba7:	8b 42 08             	mov    0x8(%edx),%eax
f0100baa:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f0100bad:	29 c7                	sub    %eax,%edi
f0100baf:	eb 06                	jmp    f0100bb7 <debuginfo_eip+0x115>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bb1:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100bb4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bb7:	83 ec 08             	sub    $0x8,%esp
f0100bba:	6a 3a                	push   $0x3a
f0100bbc:	ff 76 08             	pushl  0x8(%esi)
f0100bbf:	e8 6c 08 00 00       	call   f0101430 <strfind>
f0100bc4:	2b 46 08             	sub    0x8(%esi),%eax
f0100bc7:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
f0100bca:	83 c4 08             	add    $0x8,%esp
f0100bcd:	2b 7e 10             	sub    0x10(%esi),%edi
f0100bd0:	57                   	push   %edi
f0100bd1:	6a 44                	push   $0x44
f0100bd3:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bd6:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bd9:	b8 b0 20 10 f0       	mov    $0xf01020b0,%eax
f0100bde:	e8 c9 fd ff ff       	call   f01009ac <stab_binsearch>
	if (lfun > rfun) 
f0100be3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100be6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100be9:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0100bec:	83 c4 10             	add    $0x10,%esp
f0100bef:	39 c8                	cmp    %ecx,%eax
f0100bf1:	0f 8f b2 00 00 00    	jg     f0100ca9 <debuginfo_eip+0x207>
       	  return -1;
        info->eip_line = stabs[lfun].n_desc;
f0100bf7:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100bfa:	8d 04 85 b0 20 10 f0 	lea    -0xfefdf50(,%eax,4),%eax
f0100c01:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100c04:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f0100c08:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c0b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c0e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c11:	8d 04 85 b0 20 10 f0 	lea    -0xfefdf50(,%eax,4),%eax
f0100c18:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100c1b:	eb 06                	jmp    f0100c23 <debuginfo_eip+0x181>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c1d:	83 eb 01             	sub    $0x1,%ebx
f0100c20:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c23:	39 fb                	cmp    %edi,%ebx
f0100c25:	7c 39                	jl     f0100c60 <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f0100c27:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100c2b:	80 fa 84             	cmp    $0x84,%dl
f0100c2e:	74 0b                	je     f0100c3b <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c30:	80 fa 64             	cmp    $0x64,%dl
f0100c33:	75 e8                	jne    f0100c1d <debuginfo_eip+0x17b>
f0100c35:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c39:	74 e2                	je     f0100c1d <debuginfo_eip+0x17b>
f0100c3b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c3e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c41:	8b 14 85 b0 20 10 f0 	mov    -0xfefdf50(,%eax,4),%edx
f0100c48:	b8 69 73 10 f0       	mov    $0xf0107369,%eax
f0100c4d:	2d 4d 5a 10 f0       	sub    $0xf0105a4d,%eax
f0100c52:	39 c2                	cmp    %eax,%edx
f0100c54:	73 0d                	jae    f0100c63 <debuginfo_eip+0x1c1>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c56:	81 c2 4d 5a 10 f0    	add    $0xf0105a4d,%edx
f0100c5c:	89 16                	mov    %edx,(%esi)
f0100c5e:	eb 03                	jmp    f0100c63 <debuginfo_eip+0x1c1>
f0100c60:	8b 4d d0             	mov    -0x30(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c63:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c68:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100c6b:	39 cf                	cmp    %ecx,%edi
f0100c6d:	7d 46                	jge    f0100cb5 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
f0100c6f:	89 f8                	mov    %edi,%eax
f0100c71:	83 c0 01             	add    $0x1,%eax
f0100c74:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0100c77:	eb 07                	jmp    f0100c80 <debuginfo_eip+0x1de>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c79:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c7d:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c80:	39 c8                	cmp    %ecx,%eax
f0100c82:	74 2c                	je     f0100cb0 <debuginfo_eip+0x20e>
f0100c84:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c87:	80 7a 04 a0          	cmpb   $0xa0,0x4(%edx)
f0100c8b:	74 ec                	je     f0100c79 <debuginfo_eip+0x1d7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c8d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c92:	eb 21                	jmp    f0100cb5 <debuginfo_eip+0x213>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c99:	eb 1a                	jmp    f0100cb5 <debuginfo_eip+0x213>
f0100c9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca0:	eb 13                	jmp    f0100cb5 <debuginfo_eip+0x213>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100ca2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca7:	eb 0c                	jmp    f0100cb5 <debuginfo_eip+0x213>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
	if (lfun > rfun) 
       	  return -1;
f0100ca9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cae:	eb 05                	jmp    f0100cb5 <debuginfo_eip+0x213>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cb0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cb5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cb8:	5b                   	pop    %ebx
f0100cb9:	5e                   	pop    %esi
f0100cba:	5f                   	pop    %edi
f0100cbb:	5d                   	pop    %ebp
f0100cbc:	c3                   	ret    

f0100cbd <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cbd:	55                   	push   %ebp
f0100cbe:	89 e5                	mov    %esp,%ebp
f0100cc0:	57                   	push   %edi
f0100cc1:	56                   	push   %esi
f0100cc2:	53                   	push   %ebx
f0100cc3:	83 ec 1c             	sub    $0x1c,%esp
f0100cc6:	89 c7                	mov    %eax,%edi
f0100cc8:	89 d6                	mov    %edx,%esi
f0100cca:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ccd:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100cd0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100cd3:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100cd6:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100cd9:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cde:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100ce1:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100ce4:	39 d3                	cmp    %edx,%ebx
f0100ce6:	72 05                	jb     f0100ced <printnum+0x30>
f0100ce8:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100ceb:	77 45                	ja     f0100d32 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ced:	83 ec 0c             	sub    $0xc,%esp
f0100cf0:	ff 75 18             	pushl  0x18(%ebp)
f0100cf3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100cf6:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100cf9:	53                   	push   %ebx
f0100cfa:	ff 75 10             	pushl  0x10(%ebp)
f0100cfd:	83 ec 08             	sub    $0x8,%esp
f0100d00:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d03:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d06:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d09:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d0c:	e8 3f 09 00 00       	call   f0101650 <__udivdi3>
f0100d11:	83 c4 18             	add    $0x18,%esp
f0100d14:	52                   	push   %edx
f0100d15:	50                   	push   %eax
f0100d16:	89 f2                	mov    %esi,%edx
f0100d18:	89 f8                	mov    %edi,%eax
f0100d1a:	e8 9e ff ff ff       	call   f0100cbd <printnum>
f0100d1f:	83 c4 20             	add    $0x20,%esp
f0100d22:	eb 18                	jmp    f0100d3c <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d24:	83 ec 08             	sub    $0x8,%esp
f0100d27:	56                   	push   %esi
f0100d28:	ff 75 18             	pushl  0x18(%ebp)
f0100d2b:	ff d7                	call   *%edi
f0100d2d:	83 c4 10             	add    $0x10,%esp
f0100d30:	eb 03                	jmp    f0100d35 <printnum+0x78>
f0100d32:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d35:	83 eb 01             	sub    $0x1,%ebx
f0100d38:	85 db                	test   %ebx,%ebx
f0100d3a:	7f e8                	jg     f0100d24 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d3c:	83 ec 08             	sub    $0x8,%esp
f0100d3f:	56                   	push   %esi
f0100d40:	83 ec 04             	sub    $0x4,%esp
f0100d43:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d46:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d49:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d4c:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d4f:	e8 2c 0a 00 00       	call   f0101780 <__umoddi3>
f0100d54:	83 c4 14             	add    $0x14,%esp
f0100d57:	0f be 80 89 1e 10 f0 	movsbl -0xfefe177(%eax),%eax
f0100d5e:	50                   	push   %eax
f0100d5f:	ff d7                	call   *%edi
}
f0100d61:	83 c4 10             	add    $0x10,%esp
f0100d64:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d67:	5b                   	pop    %ebx
f0100d68:	5e                   	pop    %esi
f0100d69:	5f                   	pop    %edi
f0100d6a:	5d                   	pop    %ebp
f0100d6b:	c3                   	ret    

f0100d6c <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d6c:	55                   	push   %ebp
f0100d6d:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d6f:	83 fa 01             	cmp    $0x1,%edx
f0100d72:	7e 0e                	jle    f0100d82 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d74:	8b 10                	mov    (%eax),%edx
f0100d76:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d79:	89 08                	mov    %ecx,(%eax)
f0100d7b:	8b 02                	mov    (%edx),%eax
f0100d7d:	8b 52 04             	mov    0x4(%edx),%edx
f0100d80:	eb 22                	jmp    f0100da4 <getuint+0x38>
	else if (lflag)
f0100d82:	85 d2                	test   %edx,%edx
f0100d84:	74 10                	je     f0100d96 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d86:	8b 10                	mov    (%eax),%edx
f0100d88:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d8b:	89 08                	mov    %ecx,(%eax)
f0100d8d:	8b 02                	mov    (%edx),%eax
f0100d8f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d94:	eb 0e                	jmp    f0100da4 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d96:	8b 10                	mov    (%eax),%edx
f0100d98:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d9b:	89 08                	mov    %ecx,(%eax)
f0100d9d:	8b 02                	mov    (%edx),%eax
f0100d9f:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100da4:	5d                   	pop    %ebp
f0100da5:	c3                   	ret    

f0100da6 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100da6:	55                   	push   %ebp
f0100da7:	89 e5                	mov    %esp,%ebp
f0100da9:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100dac:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100db0:	8b 10                	mov    (%eax),%edx
f0100db2:	3b 50 04             	cmp    0x4(%eax),%edx
f0100db5:	73 0a                	jae    f0100dc1 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100db7:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100dba:	89 08                	mov    %ecx,(%eax)
f0100dbc:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dbf:	88 02                	mov    %al,(%edx)
}
f0100dc1:	5d                   	pop    %ebp
f0100dc2:	c3                   	ret    

f0100dc3 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100dc3:	55                   	push   %ebp
f0100dc4:	89 e5                	mov    %esp,%ebp
f0100dc6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100dc9:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100dcc:	50                   	push   %eax
f0100dcd:	ff 75 10             	pushl  0x10(%ebp)
f0100dd0:	ff 75 0c             	pushl  0xc(%ebp)
f0100dd3:	ff 75 08             	pushl  0x8(%ebp)
f0100dd6:	e8 05 00 00 00       	call   f0100de0 <vprintfmt>
	va_end(ap);
}
f0100ddb:	83 c4 10             	add    $0x10,%esp
f0100dde:	c9                   	leave  
f0100ddf:	c3                   	ret    

f0100de0 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100de0:	55                   	push   %ebp
f0100de1:	89 e5                	mov    %esp,%ebp
f0100de3:	57                   	push   %edi
f0100de4:	56                   	push   %esi
f0100de5:	53                   	push   %ebx
f0100de6:	83 ec 2c             	sub    $0x2c,%esp
f0100de9:	8b 75 08             	mov    0x8(%ebp),%esi
f0100dec:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100def:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100df2:	eb 12                	jmp    f0100e06 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100df4:	85 c0                	test   %eax,%eax
f0100df6:	0f 84 89 03 00 00    	je     f0101185 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0100dfc:	83 ec 08             	sub    $0x8,%esp
f0100dff:	53                   	push   %ebx
f0100e00:	50                   	push   %eax
f0100e01:	ff d6                	call   *%esi
f0100e03:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e06:	83 c7 01             	add    $0x1,%edi
f0100e09:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100e0d:	83 f8 25             	cmp    $0x25,%eax
f0100e10:	75 e2                	jne    f0100df4 <vprintfmt+0x14>
f0100e12:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100e16:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e1d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e24:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100e2b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e30:	eb 07                	jmp    f0100e39 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e32:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e35:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e39:	8d 47 01             	lea    0x1(%edi),%eax
f0100e3c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e3f:	0f b6 07             	movzbl (%edi),%eax
f0100e42:	0f b6 c8             	movzbl %al,%ecx
f0100e45:	83 e8 23             	sub    $0x23,%eax
f0100e48:	3c 55                	cmp    $0x55,%al
f0100e4a:	0f 87 1a 03 00 00    	ja     f010116a <vprintfmt+0x38a>
f0100e50:	0f b6 c0             	movzbl %al,%eax
f0100e53:	ff 24 85 20 1f 10 f0 	jmp    *-0xfefe0e0(,%eax,4)
f0100e5a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e5d:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e61:	eb d6                	jmp    f0100e39 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e63:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e66:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e6b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e6e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100e71:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100e75:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100e78:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100e7b:	83 fa 09             	cmp    $0x9,%edx
f0100e7e:	77 39                	ja     f0100eb9 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e80:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e83:	eb e9                	jmp    f0100e6e <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e85:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e88:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e8b:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e8e:	8b 00                	mov    (%eax),%eax
f0100e90:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e93:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e96:	eb 27                	jmp    f0100ebf <vprintfmt+0xdf>
f0100e98:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e9b:	85 c0                	test   %eax,%eax
f0100e9d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ea2:	0f 49 c8             	cmovns %eax,%ecx
f0100ea5:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100eab:	eb 8c                	jmp    f0100e39 <vprintfmt+0x59>
f0100ead:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100eb0:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100eb7:	eb 80                	jmp    f0100e39 <vprintfmt+0x59>
f0100eb9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100ebc:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100ebf:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100ec3:	0f 89 70 ff ff ff    	jns    f0100e39 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100ec9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100ecc:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ecf:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100ed6:	e9 5e ff ff ff       	jmp    f0100e39 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100edb:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ede:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100ee1:	e9 53 ff ff ff       	jmp    f0100e39 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ee6:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ee9:	8d 50 04             	lea    0x4(%eax),%edx
f0100eec:	89 55 14             	mov    %edx,0x14(%ebp)
f0100eef:	83 ec 08             	sub    $0x8,%esp
f0100ef2:	53                   	push   %ebx
f0100ef3:	ff 30                	pushl  (%eax)
f0100ef5:	ff d6                	call   *%esi
			break;
f0100ef7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100efa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100efd:	e9 04 ff ff ff       	jmp    f0100e06 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f02:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f05:	8d 50 04             	lea    0x4(%eax),%edx
f0100f08:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f0b:	8b 00                	mov    (%eax),%eax
f0100f0d:	99                   	cltd   
f0100f0e:	31 d0                	xor    %edx,%eax
f0100f10:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f12:	83 f8 07             	cmp    $0x7,%eax
f0100f15:	7f 0b                	jg     f0100f22 <vprintfmt+0x142>
f0100f17:	8b 14 85 80 20 10 f0 	mov    -0xfefdf80(,%eax,4),%edx
f0100f1e:	85 d2                	test   %edx,%edx
f0100f20:	75 18                	jne    f0100f3a <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0100f22:	50                   	push   %eax
f0100f23:	68 a1 1e 10 f0       	push   $0xf0101ea1
f0100f28:	53                   	push   %ebx
f0100f29:	56                   	push   %esi
f0100f2a:	e8 94 fe ff ff       	call   f0100dc3 <printfmt>
f0100f2f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f32:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f35:	e9 cc fe ff ff       	jmp    f0100e06 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100f3a:	52                   	push   %edx
f0100f3b:	68 aa 1e 10 f0       	push   $0xf0101eaa
f0100f40:	53                   	push   %ebx
f0100f41:	56                   	push   %esi
f0100f42:	e8 7c fe ff ff       	call   f0100dc3 <printfmt>
f0100f47:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f4a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f4d:	e9 b4 fe ff ff       	jmp    f0100e06 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f52:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f55:	8d 50 04             	lea    0x4(%eax),%edx
f0100f58:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f5b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100f5d:	85 ff                	test   %edi,%edi
f0100f5f:	b8 9a 1e 10 f0       	mov    $0xf0101e9a,%eax
f0100f64:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100f67:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f6b:	0f 8e 94 00 00 00    	jle    f0101005 <vprintfmt+0x225>
f0100f71:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f75:	0f 84 98 00 00 00    	je     f0101013 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f7b:	83 ec 08             	sub    $0x8,%esp
f0100f7e:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f81:	57                   	push   %edi
f0100f82:	e8 5f 03 00 00       	call   f01012e6 <strnlen>
f0100f87:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f8a:	29 c1                	sub    %eax,%ecx
f0100f8c:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100f8f:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100f92:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100f96:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f99:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f9c:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f9e:	eb 0f                	jmp    f0100faf <vprintfmt+0x1cf>
					putch(padc, putdat);
f0100fa0:	83 ec 08             	sub    $0x8,%esp
f0100fa3:	53                   	push   %ebx
f0100fa4:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fa7:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fa9:	83 ef 01             	sub    $0x1,%edi
f0100fac:	83 c4 10             	add    $0x10,%esp
f0100faf:	85 ff                	test   %edi,%edi
f0100fb1:	7f ed                	jg     f0100fa0 <vprintfmt+0x1c0>
f0100fb3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100fb6:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100fb9:	85 c9                	test   %ecx,%ecx
f0100fbb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fc0:	0f 49 c1             	cmovns %ecx,%eax
f0100fc3:	29 c1                	sub    %eax,%ecx
f0100fc5:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fc8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fcb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fce:	89 cb                	mov    %ecx,%ebx
f0100fd0:	eb 4d                	jmp    f010101f <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fd2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fd6:	74 1b                	je     f0100ff3 <vprintfmt+0x213>
f0100fd8:	0f be c0             	movsbl %al,%eax
f0100fdb:	83 e8 20             	sub    $0x20,%eax
f0100fde:	83 f8 5e             	cmp    $0x5e,%eax
f0100fe1:	76 10                	jbe    f0100ff3 <vprintfmt+0x213>
					putch('?', putdat);
f0100fe3:	83 ec 08             	sub    $0x8,%esp
f0100fe6:	ff 75 0c             	pushl  0xc(%ebp)
f0100fe9:	6a 3f                	push   $0x3f
f0100feb:	ff 55 08             	call   *0x8(%ebp)
f0100fee:	83 c4 10             	add    $0x10,%esp
f0100ff1:	eb 0d                	jmp    f0101000 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0100ff3:	83 ec 08             	sub    $0x8,%esp
f0100ff6:	ff 75 0c             	pushl  0xc(%ebp)
f0100ff9:	52                   	push   %edx
f0100ffa:	ff 55 08             	call   *0x8(%ebp)
f0100ffd:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101000:	83 eb 01             	sub    $0x1,%ebx
f0101003:	eb 1a                	jmp    f010101f <vprintfmt+0x23f>
f0101005:	89 75 08             	mov    %esi,0x8(%ebp)
f0101008:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010100b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010100e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101011:	eb 0c                	jmp    f010101f <vprintfmt+0x23f>
f0101013:	89 75 08             	mov    %esi,0x8(%ebp)
f0101016:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101019:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010101c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010101f:	83 c7 01             	add    $0x1,%edi
f0101022:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101026:	0f be d0             	movsbl %al,%edx
f0101029:	85 d2                	test   %edx,%edx
f010102b:	74 23                	je     f0101050 <vprintfmt+0x270>
f010102d:	85 f6                	test   %esi,%esi
f010102f:	78 a1                	js     f0100fd2 <vprintfmt+0x1f2>
f0101031:	83 ee 01             	sub    $0x1,%esi
f0101034:	79 9c                	jns    f0100fd2 <vprintfmt+0x1f2>
f0101036:	89 df                	mov    %ebx,%edi
f0101038:	8b 75 08             	mov    0x8(%ebp),%esi
f010103b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010103e:	eb 18                	jmp    f0101058 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101040:	83 ec 08             	sub    $0x8,%esp
f0101043:	53                   	push   %ebx
f0101044:	6a 20                	push   $0x20
f0101046:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101048:	83 ef 01             	sub    $0x1,%edi
f010104b:	83 c4 10             	add    $0x10,%esp
f010104e:	eb 08                	jmp    f0101058 <vprintfmt+0x278>
f0101050:	89 df                	mov    %ebx,%edi
f0101052:	8b 75 08             	mov    0x8(%ebp),%esi
f0101055:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101058:	85 ff                	test   %edi,%edi
f010105a:	7f e4                	jg     f0101040 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010105c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010105f:	e9 a2 fd ff ff       	jmp    f0100e06 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101064:	83 fa 01             	cmp    $0x1,%edx
f0101067:	7e 16                	jle    f010107f <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101069:	8b 45 14             	mov    0x14(%ebp),%eax
f010106c:	8d 50 08             	lea    0x8(%eax),%edx
f010106f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101072:	8b 50 04             	mov    0x4(%eax),%edx
f0101075:	8b 00                	mov    (%eax),%eax
f0101077:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010107a:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010107d:	eb 32                	jmp    f01010b1 <vprintfmt+0x2d1>
	else if (lflag)
f010107f:	85 d2                	test   %edx,%edx
f0101081:	74 18                	je     f010109b <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0101083:	8b 45 14             	mov    0x14(%ebp),%eax
f0101086:	8d 50 04             	lea    0x4(%eax),%edx
f0101089:	89 55 14             	mov    %edx,0x14(%ebp)
f010108c:	8b 00                	mov    (%eax),%eax
f010108e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101091:	89 c1                	mov    %eax,%ecx
f0101093:	c1 f9 1f             	sar    $0x1f,%ecx
f0101096:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101099:	eb 16                	jmp    f01010b1 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f010109b:	8b 45 14             	mov    0x14(%ebp),%eax
f010109e:	8d 50 04             	lea    0x4(%eax),%edx
f01010a1:	89 55 14             	mov    %edx,0x14(%ebp)
f01010a4:	8b 00                	mov    (%eax),%eax
f01010a6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010a9:	89 c1                	mov    %eax,%ecx
f01010ab:	c1 f9 1f             	sar    $0x1f,%ecx
f01010ae:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010b1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010b4:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01010b7:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01010bc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010c0:	79 74                	jns    f0101136 <vprintfmt+0x356>
				putch('-', putdat);
f01010c2:	83 ec 08             	sub    $0x8,%esp
f01010c5:	53                   	push   %ebx
f01010c6:	6a 2d                	push   $0x2d
f01010c8:	ff d6                	call   *%esi
				num = -(long long) num;
f01010ca:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010cd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010d0:	f7 d8                	neg    %eax
f01010d2:	83 d2 00             	adc    $0x0,%edx
f01010d5:	f7 da                	neg    %edx
f01010d7:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01010da:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01010df:	eb 55                	jmp    f0101136 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010e1:	8d 45 14             	lea    0x14(%ebp),%eax
f01010e4:	e8 83 fc ff ff       	call   f0100d6c <getuint>
			base = 10;
f01010e9:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010ee:	eb 46                	jmp    f0101136 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01010f0:	8d 45 14             	lea    0x14(%ebp),%eax
f01010f3:	e8 74 fc ff ff       	call   f0100d6c <getuint>
			base = 8;
f01010f8:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01010fd:	eb 37                	jmp    f0101136 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f01010ff:	83 ec 08             	sub    $0x8,%esp
f0101102:	53                   	push   %ebx
f0101103:	6a 30                	push   $0x30
f0101105:	ff d6                	call   *%esi
			putch('x', putdat);
f0101107:	83 c4 08             	add    $0x8,%esp
f010110a:	53                   	push   %ebx
f010110b:	6a 78                	push   $0x78
f010110d:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010110f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101112:	8d 50 04             	lea    0x4(%eax),%edx
f0101115:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101118:	8b 00                	mov    (%eax),%eax
f010111a:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010111f:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101122:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101127:	eb 0d                	jmp    f0101136 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101129:	8d 45 14             	lea    0x14(%ebp),%eax
f010112c:	e8 3b fc ff ff       	call   f0100d6c <getuint>
			base = 16;
f0101131:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101136:	83 ec 0c             	sub    $0xc,%esp
f0101139:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010113d:	57                   	push   %edi
f010113e:	ff 75 e0             	pushl  -0x20(%ebp)
f0101141:	51                   	push   %ecx
f0101142:	52                   	push   %edx
f0101143:	50                   	push   %eax
f0101144:	89 da                	mov    %ebx,%edx
f0101146:	89 f0                	mov    %esi,%eax
f0101148:	e8 70 fb ff ff       	call   f0100cbd <printnum>
			break;
f010114d:	83 c4 20             	add    $0x20,%esp
f0101150:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101153:	e9 ae fc ff ff       	jmp    f0100e06 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101158:	83 ec 08             	sub    $0x8,%esp
f010115b:	53                   	push   %ebx
f010115c:	51                   	push   %ecx
f010115d:	ff d6                	call   *%esi
			break;
f010115f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101162:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101165:	e9 9c fc ff ff       	jmp    f0100e06 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010116a:	83 ec 08             	sub    $0x8,%esp
f010116d:	53                   	push   %ebx
f010116e:	6a 25                	push   $0x25
f0101170:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101172:	83 c4 10             	add    $0x10,%esp
f0101175:	eb 03                	jmp    f010117a <vprintfmt+0x39a>
f0101177:	83 ef 01             	sub    $0x1,%edi
f010117a:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010117e:	75 f7                	jne    f0101177 <vprintfmt+0x397>
f0101180:	e9 81 fc ff ff       	jmp    f0100e06 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101185:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101188:	5b                   	pop    %ebx
f0101189:	5e                   	pop    %esi
f010118a:	5f                   	pop    %edi
f010118b:	5d                   	pop    %ebp
f010118c:	c3                   	ret    

f010118d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010118d:	55                   	push   %ebp
f010118e:	89 e5                	mov    %esp,%ebp
f0101190:	83 ec 18             	sub    $0x18,%esp
f0101193:	8b 45 08             	mov    0x8(%ebp),%eax
f0101196:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101199:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010119c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011a0:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011a3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011aa:	85 c0                	test   %eax,%eax
f01011ac:	74 26                	je     f01011d4 <vsnprintf+0x47>
f01011ae:	85 d2                	test   %edx,%edx
f01011b0:	7e 22                	jle    f01011d4 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011b2:	ff 75 14             	pushl  0x14(%ebp)
f01011b5:	ff 75 10             	pushl  0x10(%ebp)
f01011b8:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011bb:	50                   	push   %eax
f01011bc:	68 a6 0d 10 f0       	push   $0xf0100da6
f01011c1:	e8 1a fc ff ff       	call   f0100de0 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011c6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011c9:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011cf:	83 c4 10             	add    $0x10,%esp
f01011d2:	eb 05                	jmp    f01011d9 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011d4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011d9:	c9                   	leave  
f01011da:	c3                   	ret    

f01011db <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011db:	55                   	push   %ebp
f01011dc:	89 e5                	mov    %esp,%ebp
f01011de:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011e1:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011e4:	50                   	push   %eax
f01011e5:	ff 75 10             	pushl  0x10(%ebp)
f01011e8:	ff 75 0c             	pushl  0xc(%ebp)
f01011eb:	ff 75 08             	pushl  0x8(%ebp)
f01011ee:	e8 9a ff ff ff       	call   f010118d <vsnprintf>
	va_end(ap);

	return rc;
}
f01011f3:	c9                   	leave  
f01011f4:	c3                   	ret    

f01011f5 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01011f5:	55                   	push   %ebp
f01011f6:	89 e5                	mov    %esp,%ebp
f01011f8:	57                   	push   %edi
f01011f9:	56                   	push   %esi
f01011fa:	53                   	push   %ebx
f01011fb:	83 ec 0c             	sub    $0xc,%esp
f01011fe:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101201:	85 c0                	test   %eax,%eax
f0101203:	74 11                	je     f0101216 <readline+0x21>
		cprintf("%s", prompt);
f0101205:	83 ec 08             	sub    $0x8,%esp
f0101208:	50                   	push   %eax
f0101209:	68 aa 1e 10 f0       	push   $0xf0101eaa
f010120e:	e8 85 f7 ff ff       	call   f0100998 <cprintf>
f0101213:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101216:	83 ec 0c             	sub    $0xc,%esp
f0101219:	6a 00                	push   $0x0
f010121b:	e8 81 f4 ff ff       	call   f01006a1 <iscons>
f0101220:	89 c7                	mov    %eax,%edi
f0101222:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101225:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010122a:	e8 61 f4 ff ff       	call   f0100690 <getchar>
f010122f:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101231:	85 c0                	test   %eax,%eax
f0101233:	79 18                	jns    f010124d <readline+0x58>
			cprintf("read error: %e\n", c);
f0101235:	83 ec 08             	sub    $0x8,%esp
f0101238:	50                   	push   %eax
f0101239:	68 a0 20 10 f0       	push   $0xf01020a0
f010123e:	e8 55 f7 ff ff       	call   f0100998 <cprintf>
			return NULL;
f0101243:	83 c4 10             	add    $0x10,%esp
f0101246:	b8 00 00 00 00       	mov    $0x0,%eax
f010124b:	eb 79                	jmp    f01012c6 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010124d:	83 f8 08             	cmp    $0x8,%eax
f0101250:	0f 94 c2             	sete   %dl
f0101253:	83 f8 7f             	cmp    $0x7f,%eax
f0101256:	0f 94 c0             	sete   %al
f0101259:	08 c2                	or     %al,%dl
f010125b:	74 1a                	je     f0101277 <readline+0x82>
f010125d:	85 f6                	test   %esi,%esi
f010125f:	7e 16                	jle    f0101277 <readline+0x82>
			if (echoing)
f0101261:	85 ff                	test   %edi,%edi
f0101263:	74 0d                	je     f0101272 <readline+0x7d>
				cputchar('\b');
f0101265:	83 ec 0c             	sub    $0xc,%esp
f0101268:	6a 08                	push   $0x8
f010126a:	e8 11 f4 ff ff       	call   f0100680 <cputchar>
f010126f:	83 c4 10             	add    $0x10,%esp
			i--;
f0101272:	83 ee 01             	sub    $0x1,%esi
f0101275:	eb b3                	jmp    f010122a <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101277:	83 fb 1f             	cmp    $0x1f,%ebx
f010127a:	7e 23                	jle    f010129f <readline+0xaa>
f010127c:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101282:	7f 1b                	jg     f010129f <readline+0xaa>
			if (echoing)
f0101284:	85 ff                	test   %edi,%edi
f0101286:	74 0c                	je     f0101294 <readline+0x9f>
				cputchar(c);
f0101288:	83 ec 0c             	sub    $0xc,%esp
f010128b:	53                   	push   %ebx
f010128c:	e8 ef f3 ff ff       	call   f0100680 <cputchar>
f0101291:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101294:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f010129a:	8d 76 01             	lea    0x1(%esi),%esi
f010129d:	eb 8b                	jmp    f010122a <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010129f:	83 fb 0a             	cmp    $0xa,%ebx
f01012a2:	74 05                	je     f01012a9 <readline+0xb4>
f01012a4:	83 fb 0d             	cmp    $0xd,%ebx
f01012a7:	75 81                	jne    f010122a <readline+0x35>
			if (echoing)
f01012a9:	85 ff                	test   %edi,%edi
f01012ab:	74 0d                	je     f01012ba <readline+0xc5>
				cputchar('\n');
f01012ad:	83 ec 0c             	sub    $0xc,%esp
f01012b0:	6a 0a                	push   $0xa
f01012b2:	e8 c9 f3 ff ff       	call   f0100680 <cputchar>
f01012b7:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01012ba:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01012c1:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01012c6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012c9:	5b                   	pop    %ebx
f01012ca:	5e                   	pop    %esi
f01012cb:	5f                   	pop    %edi
f01012cc:	5d                   	pop    %ebp
f01012cd:	c3                   	ret    

f01012ce <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012ce:	55                   	push   %ebp
f01012cf:	89 e5                	mov    %esp,%ebp
f01012d1:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01012d9:	eb 03                	jmp    f01012de <strlen+0x10>
		n++;
f01012db:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012de:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012e2:	75 f7                	jne    f01012db <strlen+0xd>
		n++;
	return n;
}
f01012e4:	5d                   	pop    %ebp
f01012e5:	c3                   	ret    

f01012e6 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012e6:	55                   	push   %ebp
f01012e7:	89 e5                	mov    %esp,%ebp
f01012e9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012ec:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012ef:	ba 00 00 00 00       	mov    $0x0,%edx
f01012f4:	eb 03                	jmp    f01012f9 <strnlen+0x13>
		n++;
f01012f6:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012f9:	39 c2                	cmp    %eax,%edx
f01012fb:	74 08                	je     f0101305 <strnlen+0x1f>
f01012fd:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101301:	75 f3                	jne    f01012f6 <strnlen+0x10>
f0101303:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101305:	5d                   	pop    %ebp
f0101306:	c3                   	ret    

f0101307 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101307:	55                   	push   %ebp
f0101308:	89 e5                	mov    %esp,%ebp
f010130a:	53                   	push   %ebx
f010130b:	8b 45 08             	mov    0x8(%ebp),%eax
f010130e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101311:	89 c2                	mov    %eax,%edx
f0101313:	83 c2 01             	add    $0x1,%edx
f0101316:	83 c1 01             	add    $0x1,%ecx
f0101319:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010131d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101320:	84 db                	test   %bl,%bl
f0101322:	75 ef                	jne    f0101313 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101324:	5b                   	pop    %ebx
f0101325:	5d                   	pop    %ebp
f0101326:	c3                   	ret    

f0101327 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101327:	55                   	push   %ebp
f0101328:	89 e5                	mov    %esp,%ebp
f010132a:	53                   	push   %ebx
f010132b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010132e:	53                   	push   %ebx
f010132f:	e8 9a ff ff ff       	call   f01012ce <strlen>
f0101334:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101337:	ff 75 0c             	pushl  0xc(%ebp)
f010133a:	01 d8                	add    %ebx,%eax
f010133c:	50                   	push   %eax
f010133d:	e8 c5 ff ff ff       	call   f0101307 <strcpy>
	return dst;
}
f0101342:	89 d8                	mov    %ebx,%eax
f0101344:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101347:	c9                   	leave  
f0101348:	c3                   	ret    

f0101349 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101349:	55                   	push   %ebp
f010134a:	89 e5                	mov    %esp,%ebp
f010134c:	56                   	push   %esi
f010134d:	53                   	push   %ebx
f010134e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101351:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101354:	89 f3                	mov    %esi,%ebx
f0101356:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101359:	89 f2                	mov    %esi,%edx
f010135b:	eb 0f                	jmp    f010136c <strncpy+0x23>
		*dst++ = *src;
f010135d:	83 c2 01             	add    $0x1,%edx
f0101360:	0f b6 01             	movzbl (%ecx),%eax
f0101363:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101366:	80 39 01             	cmpb   $0x1,(%ecx)
f0101369:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010136c:	39 da                	cmp    %ebx,%edx
f010136e:	75 ed                	jne    f010135d <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101370:	89 f0                	mov    %esi,%eax
f0101372:	5b                   	pop    %ebx
f0101373:	5e                   	pop    %esi
f0101374:	5d                   	pop    %ebp
f0101375:	c3                   	ret    

f0101376 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101376:	55                   	push   %ebp
f0101377:	89 e5                	mov    %esp,%ebp
f0101379:	56                   	push   %esi
f010137a:	53                   	push   %ebx
f010137b:	8b 75 08             	mov    0x8(%ebp),%esi
f010137e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101381:	8b 55 10             	mov    0x10(%ebp),%edx
f0101384:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101386:	85 d2                	test   %edx,%edx
f0101388:	74 21                	je     f01013ab <strlcpy+0x35>
f010138a:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010138e:	89 f2                	mov    %esi,%edx
f0101390:	eb 09                	jmp    f010139b <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101392:	83 c2 01             	add    $0x1,%edx
f0101395:	83 c1 01             	add    $0x1,%ecx
f0101398:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010139b:	39 c2                	cmp    %eax,%edx
f010139d:	74 09                	je     f01013a8 <strlcpy+0x32>
f010139f:	0f b6 19             	movzbl (%ecx),%ebx
f01013a2:	84 db                	test   %bl,%bl
f01013a4:	75 ec                	jne    f0101392 <strlcpy+0x1c>
f01013a6:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01013a8:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01013ab:	29 f0                	sub    %esi,%eax
}
f01013ad:	5b                   	pop    %ebx
f01013ae:	5e                   	pop    %esi
f01013af:	5d                   	pop    %ebp
f01013b0:	c3                   	ret    

f01013b1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013b1:	55                   	push   %ebp
f01013b2:	89 e5                	mov    %esp,%ebp
f01013b4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013b7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013ba:	eb 06                	jmp    f01013c2 <strcmp+0x11>
		p++, q++;
f01013bc:	83 c1 01             	add    $0x1,%ecx
f01013bf:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013c2:	0f b6 01             	movzbl (%ecx),%eax
f01013c5:	84 c0                	test   %al,%al
f01013c7:	74 04                	je     f01013cd <strcmp+0x1c>
f01013c9:	3a 02                	cmp    (%edx),%al
f01013cb:	74 ef                	je     f01013bc <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013cd:	0f b6 c0             	movzbl %al,%eax
f01013d0:	0f b6 12             	movzbl (%edx),%edx
f01013d3:	29 d0                	sub    %edx,%eax
}
f01013d5:	5d                   	pop    %ebp
f01013d6:	c3                   	ret    

f01013d7 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013d7:	55                   	push   %ebp
f01013d8:	89 e5                	mov    %esp,%ebp
f01013da:	53                   	push   %ebx
f01013db:	8b 45 08             	mov    0x8(%ebp),%eax
f01013de:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013e1:	89 c3                	mov    %eax,%ebx
f01013e3:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01013e6:	eb 06                	jmp    f01013ee <strncmp+0x17>
		n--, p++, q++;
f01013e8:	83 c0 01             	add    $0x1,%eax
f01013eb:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013ee:	39 d8                	cmp    %ebx,%eax
f01013f0:	74 15                	je     f0101407 <strncmp+0x30>
f01013f2:	0f b6 08             	movzbl (%eax),%ecx
f01013f5:	84 c9                	test   %cl,%cl
f01013f7:	74 04                	je     f01013fd <strncmp+0x26>
f01013f9:	3a 0a                	cmp    (%edx),%cl
f01013fb:	74 eb                	je     f01013e8 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01013fd:	0f b6 00             	movzbl (%eax),%eax
f0101400:	0f b6 12             	movzbl (%edx),%edx
f0101403:	29 d0                	sub    %edx,%eax
f0101405:	eb 05                	jmp    f010140c <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101407:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010140c:	5b                   	pop    %ebx
f010140d:	5d                   	pop    %ebp
f010140e:	c3                   	ret    

f010140f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010140f:	55                   	push   %ebp
f0101410:	89 e5                	mov    %esp,%ebp
f0101412:	8b 45 08             	mov    0x8(%ebp),%eax
f0101415:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101419:	eb 07                	jmp    f0101422 <strchr+0x13>
		if (*s == c)
f010141b:	38 ca                	cmp    %cl,%dl
f010141d:	74 0f                	je     f010142e <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010141f:	83 c0 01             	add    $0x1,%eax
f0101422:	0f b6 10             	movzbl (%eax),%edx
f0101425:	84 d2                	test   %dl,%dl
f0101427:	75 f2                	jne    f010141b <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101429:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010142e:	5d                   	pop    %ebp
f010142f:	c3                   	ret    

f0101430 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101430:	55                   	push   %ebp
f0101431:	89 e5                	mov    %esp,%ebp
f0101433:	8b 45 08             	mov    0x8(%ebp),%eax
f0101436:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010143a:	eb 03                	jmp    f010143f <strfind+0xf>
f010143c:	83 c0 01             	add    $0x1,%eax
f010143f:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101442:	38 ca                	cmp    %cl,%dl
f0101444:	74 04                	je     f010144a <strfind+0x1a>
f0101446:	84 d2                	test   %dl,%dl
f0101448:	75 f2                	jne    f010143c <strfind+0xc>
			break;
	return (char *) s;
}
f010144a:	5d                   	pop    %ebp
f010144b:	c3                   	ret    

f010144c <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010144c:	55                   	push   %ebp
f010144d:	89 e5                	mov    %esp,%ebp
f010144f:	57                   	push   %edi
f0101450:	56                   	push   %esi
f0101451:	53                   	push   %ebx
f0101452:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101455:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101458:	85 c9                	test   %ecx,%ecx
f010145a:	74 36                	je     f0101492 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010145c:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101462:	75 28                	jne    f010148c <memset+0x40>
f0101464:	f6 c1 03             	test   $0x3,%cl
f0101467:	75 23                	jne    f010148c <memset+0x40>
		c &= 0xFF;
f0101469:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010146d:	89 d3                	mov    %edx,%ebx
f010146f:	c1 e3 08             	shl    $0x8,%ebx
f0101472:	89 d6                	mov    %edx,%esi
f0101474:	c1 e6 18             	shl    $0x18,%esi
f0101477:	89 d0                	mov    %edx,%eax
f0101479:	c1 e0 10             	shl    $0x10,%eax
f010147c:	09 f0                	or     %esi,%eax
f010147e:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0101480:	89 d8                	mov    %ebx,%eax
f0101482:	09 d0                	or     %edx,%eax
f0101484:	c1 e9 02             	shr    $0x2,%ecx
f0101487:	fc                   	cld    
f0101488:	f3 ab                	rep stos %eax,%es:(%edi)
f010148a:	eb 06                	jmp    f0101492 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010148c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010148f:	fc                   	cld    
f0101490:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101492:	89 f8                	mov    %edi,%eax
f0101494:	5b                   	pop    %ebx
f0101495:	5e                   	pop    %esi
f0101496:	5f                   	pop    %edi
f0101497:	5d                   	pop    %ebp
f0101498:	c3                   	ret    

f0101499 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101499:	55                   	push   %ebp
f010149a:	89 e5                	mov    %esp,%ebp
f010149c:	57                   	push   %edi
f010149d:	56                   	push   %esi
f010149e:	8b 45 08             	mov    0x8(%ebp),%eax
f01014a1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014a4:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014a7:	39 c6                	cmp    %eax,%esi
f01014a9:	73 35                	jae    f01014e0 <memmove+0x47>
f01014ab:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014ae:	39 d0                	cmp    %edx,%eax
f01014b0:	73 2e                	jae    f01014e0 <memmove+0x47>
		s += n;
		d += n;
f01014b2:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014b5:	89 d6                	mov    %edx,%esi
f01014b7:	09 fe                	or     %edi,%esi
f01014b9:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01014bf:	75 13                	jne    f01014d4 <memmove+0x3b>
f01014c1:	f6 c1 03             	test   $0x3,%cl
f01014c4:	75 0e                	jne    f01014d4 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01014c6:	83 ef 04             	sub    $0x4,%edi
f01014c9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01014cc:	c1 e9 02             	shr    $0x2,%ecx
f01014cf:	fd                   	std    
f01014d0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014d2:	eb 09                	jmp    f01014dd <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01014d4:	83 ef 01             	sub    $0x1,%edi
f01014d7:	8d 72 ff             	lea    -0x1(%edx),%esi
f01014da:	fd                   	std    
f01014db:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01014dd:	fc                   	cld    
f01014de:	eb 1d                	jmp    f01014fd <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014e0:	89 f2                	mov    %esi,%edx
f01014e2:	09 c2                	or     %eax,%edx
f01014e4:	f6 c2 03             	test   $0x3,%dl
f01014e7:	75 0f                	jne    f01014f8 <memmove+0x5f>
f01014e9:	f6 c1 03             	test   $0x3,%cl
f01014ec:	75 0a                	jne    f01014f8 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01014ee:	c1 e9 02             	shr    $0x2,%ecx
f01014f1:	89 c7                	mov    %eax,%edi
f01014f3:	fc                   	cld    
f01014f4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014f6:	eb 05                	jmp    f01014fd <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01014f8:	89 c7                	mov    %eax,%edi
f01014fa:	fc                   	cld    
f01014fb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01014fd:	5e                   	pop    %esi
f01014fe:	5f                   	pop    %edi
f01014ff:	5d                   	pop    %ebp
f0101500:	c3                   	ret    

f0101501 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101501:	55                   	push   %ebp
f0101502:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101504:	ff 75 10             	pushl  0x10(%ebp)
f0101507:	ff 75 0c             	pushl  0xc(%ebp)
f010150a:	ff 75 08             	pushl  0x8(%ebp)
f010150d:	e8 87 ff ff ff       	call   f0101499 <memmove>
}
f0101512:	c9                   	leave  
f0101513:	c3                   	ret    

f0101514 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101514:	55                   	push   %ebp
f0101515:	89 e5                	mov    %esp,%ebp
f0101517:	56                   	push   %esi
f0101518:	53                   	push   %ebx
f0101519:	8b 45 08             	mov    0x8(%ebp),%eax
f010151c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010151f:	89 c6                	mov    %eax,%esi
f0101521:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101524:	eb 1a                	jmp    f0101540 <memcmp+0x2c>
		if (*s1 != *s2)
f0101526:	0f b6 08             	movzbl (%eax),%ecx
f0101529:	0f b6 1a             	movzbl (%edx),%ebx
f010152c:	38 d9                	cmp    %bl,%cl
f010152e:	74 0a                	je     f010153a <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101530:	0f b6 c1             	movzbl %cl,%eax
f0101533:	0f b6 db             	movzbl %bl,%ebx
f0101536:	29 d8                	sub    %ebx,%eax
f0101538:	eb 0f                	jmp    f0101549 <memcmp+0x35>
		s1++, s2++;
f010153a:	83 c0 01             	add    $0x1,%eax
f010153d:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101540:	39 f0                	cmp    %esi,%eax
f0101542:	75 e2                	jne    f0101526 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101544:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101549:	5b                   	pop    %ebx
f010154a:	5e                   	pop    %esi
f010154b:	5d                   	pop    %ebp
f010154c:	c3                   	ret    

f010154d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010154d:	55                   	push   %ebp
f010154e:	89 e5                	mov    %esp,%ebp
f0101550:	53                   	push   %ebx
f0101551:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101554:	89 c1                	mov    %eax,%ecx
f0101556:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0101559:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010155d:	eb 0a                	jmp    f0101569 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010155f:	0f b6 10             	movzbl (%eax),%edx
f0101562:	39 da                	cmp    %ebx,%edx
f0101564:	74 07                	je     f010156d <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101566:	83 c0 01             	add    $0x1,%eax
f0101569:	39 c8                	cmp    %ecx,%eax
f010156b:	72 f2                	jb     f010155f <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010156d:	5b                   	pop    %ebx
f010156e:	5d                   	pop    %ebp
f010156f:	c3                   	ret    

f0101570 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101570:	55                   	push   %ebp
f0101571:	89 e5                	mov    %esp,%ebp
f0101573:	57                   	push   %edi
f0101574:	56                   	push   %esi
f0101575:	53                   	push   %ebx
f0101576:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101579:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010157c:	eb 03                	jmp    f0101581 <strtol+0x11>
		s++;
f010157e:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101581:	0f b6 01             	movzbl (%ecx),%eax
f0101584:	3c 20                	cmp    $0x20,%al
f0101586:	74 f6                	je     f010157e <strtol+0xe>
f0101588:	3c 09                	cmp    $0x9,%al
f010158a:	74 f2                	je     f010157e <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010158c:	3c 2b                	cmp    $0x2b,%al
f010158e:	75 0a                	jne    f010159a <strtol+0x2a>
		s++;
f0101590:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101593:	bf 00 00 00 00       	mov    $0x0,%edi
f0101598:	eb 11                	jmp    f01015ab <strtol+0x3b>
f010159a:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010159f:	3c 2d                	cmp    $0x2d,%al
f01015a1:	75 08                	jne    f01015ab <strtol+0x3b>
		s++, neg = 1;
f01015a3:	83 c1 01             	add    $0x1,%ecx
f01015a6:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015ab:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01015b1:	75 15                	jne    f01015c8 <strtol+0x58>
f01015b3:	80 39 30             	cmpb   $0x30,(%ecx)
f01015b6:	75 10                	jne    f01015c8 <strtol+0x58>
f01015b8:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01015bc:	75 7c                	jne    f010163a <strtol+0xca>
		s += 2, base = 16;
f01015be:	83 c1 02             	add    $0x2,%ecx
f01015c1:	bb 10 00 00 00       	mov    $0x10,%ebx
f01015c6:	eb 16                	jmp    f01015de <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01015c8:	85 db                	test   %ebx,%ebx
f01015ca:	75 12                	jne    f01015de <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01015cc:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015d1:	80 39 30             	cmpb   $0x30,(%ecx)
f01015d4:	75 08                	jne    f01015de <strtol+0x6e>
		s++, base = 8;
f01015d6:	83 c1 01             	add    $0x1,%ecx
f01015d9:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01015de:	b8 00 00 00 00       	mov    $0x0,%eax
f01015e3:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01015e6:	0f b6 11             	movzbl (%ecx),%edx
f01015e9:	8d 72 d0             	lea    -0x30(%edx),%esi
f01015ec:	89 f3                	mov    %esi,%ebx
f01015ee:	80 fb 09             	cmp    $0x9,%bl
f01015f1:	77 08                	ja     f01015fb <strtol+0x8b>
			dig = *s - '0';
f01015f3:	0f be d2             	movsbl %dl,%edx
f01015f6:	83 ea 30             	sub    $0x30,%edx
f01015f9:	eb 22                	jmp    f010161d <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01015fb:	8d 72 9f             	lea    -0x61(%edx),%esi
f01015fe:	89 f3                	mov    %esi,%ebx
f0101600:	80 fb 19             	cmp    $0x19,%bl
f0101603:	77 08                	ja     f010160d <strtol+0x9d>
			dig = *s - 'a' + 10;
f0101605:	0f be d2             	movsbl %dl,%edx
f0101608:	83 ea 57             	sub    $0x57,%edx
f010160b:	eb 10                	jmp    f010161d <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010160d:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101610:	89 f3                	mov    %esi,%ebx
f0101612:	80 fb 19             	cmp    $0x19,%bl
f0101615:	77 16                	ja     f010162d <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101617:	0f be d2             	movsbl %dl,%edx
f010161a:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010161d:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101620:	7d 0b                	jge    f010162d <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0101622:	83 c1 01             	add    $0x1,%ecx
f0101625:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101629:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010162b:	eb b9                	jmp    f01015e6 <strtol+0x76>

	if (endptr)
f010162d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101631:	74 0d                	je     f0101640 <strtol+0xd0>
		*endptr = (char *) s;
f0101633:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101636:	89 0e                	mov    %ecx,(%esi)
f0101638:	eb 06                	jmp    f0101640 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010163a:	85 db                	test   %ebx,%ebx
f010163c:	74 98                	je     f01015d6 <strtol+0x66>
f010163e:	eb 9e                	jmp    f01015de <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0101640:	89 c2                	mov    %eax,%edx
f0101642:	f7 da                	neg    %edx
f0101644:	85 ff                	test   %edi,%edi
f0101646:	0f 45 c2             	cmovne %edx,%eax
}
f0101649:	5b                   	pop    %ebx
f010164a:	5e                   	pop    %esi
f010164b:	5f                   	pop    %edi
f010164c:	5d                   	pop    %ebp
f010164d:	c3                   	ret    
f010164e:	66 90                	xchg   %ax,%ax

f0101650 <__udivdi3>:
f0101650:	55                   	push   %ebp
f0101651:	57                   	push   %edi
f0101652:	56                   	push   %esi
f0101653:	53                   	push   %ebx
f0101654:	83 ec 1c             	sub    $0x1c,%esp
f0101657:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010165b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010165f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101663:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101667:	85 f6                	test   %esi,%esi
f0101669:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010166d:	89 ca                	mov    %ecx,%edx
f010166f:	89 f8                	mov    %edi,%eax
f0101671:	75 3d                	jne    f01016b0 <__udivdi3+0x60>
f0101673:	39 cf                	cmp    %ecx,%edi
f0101675:	0f 87 c5 00 00 00    	ja     f0101740 <__udivdi3+0xf0>
f010167b:	85 ff                	test   %edi,%edi
f010167d:	89 fd                	mov    %edi,%ebp
f010167f:	75 0b                	jne    f010168c <__udivdi3+0x3c>
f0101681:	b8 01 00 00 00       	mov    $0x1,%eax
f0101686:	31 d2                	xor    %edx,%edx
f0101688:	f7 f7                	div    %edi
f010168a:	89 c5                	mov    %eax,%ebp
f010168c:	89 c8                	mov    %ecx,%eax
f010168e:	31 d2                	xor    %edx,%edx
f0101690:	f7 f5                	div    %ebp
f0101692:	89 c1                	mov    %eax,%ecx
f0101694:	89 d8                	mov    %ebx,%eax
f0101696:	89 cf                	mov    %ecx,%edi
f0101698:	f7 f5                	div    %ebp
f010169a:	89 c3                	mov    %eax,%ebx
f010169c:	89 d8                	mov    %ebx,%eax
f010169e:	89 fa                	mov    %edi,%edx
f01016a0:	83 c4 1c             	add    $0x1c,%esp
f01016a3:	5b                   	pop    %ebx
f01016a4:	5e                   	pop    %esi
f01016a5:	5f                   	pop    %edi
f01016a6:	5d                   	pop    %ebp
f01016a7:	c3                   	ret    
f01016a8:	90                   	nop
f01016a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016b0:	39 ce                	cmp    %ecx,%esi
f01016b2:	77 74                	ja     f0101728 <__udivdi3+0xd8>
f01016b4:	0f bd fe             	bsr    %esi,%edi
f01016b7:	83 f7 1f             	xor    $0x1f,%edi
f01016ba:	0f 84 98 00 00 00    	je     f0101758 <__udivdi3+0x108>
f01016c0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01016c5:	89 f9                	mov    %edi,%ecx
f01016c7:	89 c5                	mov    %eax,%ebp
f01016c9:	29 fb                	sub    %edi,%ebx
f01016cb:	d3 e6                	shl    %cl,%esi
f01016cd:	89 d9                	mov    %ebx,%ecx
f01016cf:	d3 ed                	shr    %cl,%ebp
f01016d1:	89 f9                	mov    %edi,%ecx
f01016d3:	d3 e0                	shl    %cl,%eax
f01016d5:	09 ee                	or     %ebp,%esi
f01016d7:	89 d9                	mov    %ebx,%ecx
f01016d9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016dd:	89 d5                	mov    %edx,%ebp
f01016df:	8b 44 24 08          	mov    0x8(%esp),%eax
f01016e3:	d3 ed                	shr    %cl,%ebp
f01016e5:	89 f9                	mov    %edi,%ecx
f01016e7:	d3 e2                	shl    %cl,%edx
f01016e9:	89 d9                	mov    %ebx,%ecx
f01016eb:	d3 e8                	shr    %cl,%eax
f01016ed:	09 c2                	or     %eax,%edx
f01016ef:	89 d0                	mov    %edx,%eax
f01016f1:	89 ea                	mov    %ebp,%edx
f01016f3:	f7 f6                	div    %esi
f01016f5:	89 d5                	mov    %edx,%ebp
f01016f7:	89 c3                	mov    %eax,%ebx
f01016f9:	f7 64 24 0c          	mull   0xc(%esp)
f01016fd:	39 d5                	cmp    %edx,%ebp
f01016ff:	72 10                	jb     f0101711 <__udivdi3+0xc1>
f0101701:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101705:	89 f9                	mov    %edi,%ecx
f0101707:	d3 e6                	shl    %cl,%esi
f0101709:	39 c6                	cmp    %eax,%esi
f010170b:	73 07                	jae    f0101714 <__udivdi3+0xc4>
f010170d:	39 d5                	cmp    %edx,%ebp
f010170f:	75 03                	jne    f0101714 <__udivdi3+0xc4>
f0101711:	83 eb 01             	sub    $0x1,%ebx
f0101714:	31 ff                	xor    %edi,%edi
f0101716:	89 d8                	mov    %ebx,%eax
f0101718:	89 fa                	mov    %edi,%edx
f010171a:	83 c4 1c             	add    $0x1c,%esp
f010171d:	5b                   	pop    %ebx
f010171e:	5e                   	pop    %esi
f010171f:	5f                   	pop    %edi
f0101720:	5d                   	pop    %ebp
f0101721:	c3                   	ret    
f0101722:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101728:	31 ff                	xor    %edi,%edi
f010172a:	31 db                	xor    %ebx,%ebx
f010172c:	89 d8                	mov    %ebx,%eax
f010172e:	89 fa                	mov    %edi,%edx
f0101730:	83 c4 1c             	add    $0x1c,%esp
f0101733:	5b                   	pop    %ebx
f0101734:	5e                   	pop    %esi
f0101735:	5f                   	pop    %edi
f0101736:	5d                   	pop    %ebp
f0101737:	c3                   	ret    
f0101738:	90                   	nop
f0101739:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101740:	89 d8                	mov    %ebx,%eax
f0101742:	f7 f7                	div    %edi
f0101744:	31 ff                	xor    %edi,%edi
f0101746:	89 c3                	mov    %eax,%ebx
f0101748:	89 d8                	mov    %ebx,%eax
f010174a:	89 fa                	mov    %edi,%edx
f010174c:	83 c4 1c             	add    $0x1c,%esp
f010174f:	5b                   	pop    %ebx
f0101750:	5e                   	pop    %esi
f0101751:	5f                   	pop    %edi
f0101752:	5d                   	pop    %ebp
f0101753:	c3                   	ret    
f0101754:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101758:	39 ce                	cmp    %ecx,%esi
f010175a:	72 0c                	jb     f0101768 <__udivdi3+0x118>
f010175c:	31 db                	xor    %ebx,%ebx
f010175e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101762:	0f 87 34 ff ff ff    	ja     f010169c <__udivdi3+0x4c>
f0101768:	bb 01 00 00 00       	mov    $0x1,%ebx
f010176d:	e9 2a ff ff ff       	jmp    f010169c <__udivdi3+0x4c>
f0101772:	66 90                	xchg   %ax,%ax
f0101774:	66 90                	xchg   %ax,%ax
f0101776:	66 90                	xchg   %ax,%ax
f0101778:	66 90                	xchg   %ax,%ax
f010177a:	66 90                	xchg   %ax,%ax
f010177c:	66 90                	xchg   %ax,%ax
f010177e:	66 90                	xchg   %ax,%ax

f0101780 <__umoddi3>:
f0101780:	55                   	push   %ebp
f0101781:	57                   	push   %edi
f0101782:	56                   	push   %esi
f0101783:	53                   	push   %ebx
f0101784:	83 ec 1c             	sub    $0x1c,%esp
f0101787:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010178b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010178f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101793:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101797:	85 d2                	test   %edx,%edx
f0101799:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010179d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017a1:	89 f3                	mov    %esi,%ebx
f01017a3:	89 3c 24             	mov    %edi,(%esp)
f01017a6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01017aa:	75 1c                	jne    f01017c8 <__umoddi3+0x48>
f01017ac:	39 f7                	cmp    %esi,%edi
f01017ae:	76 50                	jbe    f0101800 <__umoddi3+0x80>
f01017b0:	89 c8                	mov    %ecx,%eax
f01017b2:	89 f2                	mov    %esi,%edx
f01017b4:	f7 f7                	div    %edi
f01017b6:	89 d0                	mov    %edx,%eax
f01017b8:	31 d2                	xor    %edx,%edx
f01017ba:	83 c4 1c             	add    $0x1c,%esp
f01017bd:	5b                   	pop    %ebx
f01017be:	5e                   	pop    %esi
f01017bf:	5f                   	pop    %edi
f01017c0:	5d                   	pop    %ebp
f01017c1:	c3                   	ret    
f01017c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017c8:	39 f2                	cmp    %esi,%edx
f01017ca:	89 d0                	mov    %edx,%eax
f01017cc:	77 52                	ja     f0101820 <__umoddi3+0xa0>
f01017ce:	0f bd ea             	bsr    %edx,%ebp
f01017d1:	83 f5 1f             	xor    $0x1f,%ebp
f01017d4:	75 5a                	jne    f0101830 <__umoddi3+0xb0>
f01017d6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01017da:	0f 82 e0 00 00 00    	jb     f01018c0 <__umoddi3+0x140>
f01017e0:	39 0c 24             	cmp    %ecx,(%esp)
f01017e3:	0f 86 d7 00 00 00    	jbe    f01018c0 <__umoddi3+0x140>
f01017e9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01017ed:	8b 54 24 04          	mov    0x4(%esp),%edx
f01017f1:	83 c4 1c             	add    $0x1c,%esp
f01017f4:	5b                   	pop    %ebx
f01017f5:	5e                   	pop    %esi
f01017f6:	5f                   	pop    %edi
f01017f7:	5d                   	pop    %ebp
f01017f8:	c3                   	ret    
f01017f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101800:	85 ff                	test   %edi,%edi
f0101802:	89 fd                	mov    %edi,%ebp
f0101804:	75 0b                	jne    f0101811 <__umoddi3+0x91>
f0101806:	b8 01 00 00 00       	mov    $0x1,%eax
f010180b:	31 d2                	xor    %edx,%edx
f010180d:	f7 f7                	div    %edi
f010180f:	89 c5                	mov    %eax,%ebp
f0101811:	89 f0                	mov    %esi,%eax
f0101813:	31 d2                	xor    %edx,%edx
f0101815:	f7 f5                	div    %ebp
f0101817:	89 c8                	mov    %ecx,%eax
f0101819:	f7 f5                	div    %ebp
f010181b:	89 d0                	mov    %edx,%eax
f010181d:	eb 99                	jmp    f01017b8 <__umoddi3+0x38>
f010181f:	90                   	nop
f0101820:	89 c8                	mov    %ecx,%eax
f0101822:	89 f2                	mov    %esi,%edx
f0101824:	83 c4 1c             	add    $0x1c,%esp
f0101827:	5b                   	pop    %ebx
f0101828:	5e                   	pop    %esi
f0101829:	5f                   	pop    %edi
f010182a:	5d                   	pop    %ebp
f010182b:	c3                   	ret    
f010182c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101830:	8b 34 24             	mov    (%esp),%esi
f0101833:	bf 20 00 00 00       	mov    $0x20,%edi
f0101838:	89 e9                	mov    %ebp,%ecx
f010183a:	29 ef                	sub    %ebp,%edi
f010183c:	d3 e0                	shl    %cl,%eax
f010183e:	89 f9                	mov    %edi,%ecx
f0101840:	89 f2                	mov    %esi,%edx
f0101842:	d3 ea                	shr    %cl,%edx
f0101844:	89 e9                	mov    %ebp,%ecx
f0101846:	09 c2                	or     %eax,%edx
f0101848:	89 d8                	mov    %ebx,%eax
f010184a:	89 14 24             	mov    %edx,(%esp)
f010184d:	89 f2                	mov    %esi,%edx
f010184f:	d3 e2                	shl    %cl,%edx
f0101851:	89 f9                	mov    %edi,%ecx
f0101853:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101857:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010185b:	d3 e8                	shr    %cl,%eax
f010185d:	89 e9                	mov    %ebp,%ecx
f010185f:	89 c6                	mov    %eax,%esi
f0101861:	d3 e3                	shl    %cl,%ebx
f0101863:	89 f9                	mov    %edi,%ecx
f0101865:	89 d0                	mov    %edx,%eax
f0101867:	d3 e8                	shr    %cl,%eax
f0101869:	89 e9                	mov    %ebp,%ecx
f010186b:	09 d8                	or     %ebx,%eax
f010186d:	89 d3                	mov    %edx,%ebx
f010186f:	89 f2                	mov    %esi,%edx
f0101871:	f7 34 24             	divl   (%esp)
f0101874:	89 d6                	mov    %edx,%esi
f0101876:	d3 e3                	shl    %cl,%ebx
f0101878:	f7 64 24 04          	mull   0x4(%esp)
f010187c:	39 d6                	cmp    %edx,%esi
f010187e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101882:	89 d1                	mov    %edx,%ecx
f0101884:	89 c3                	mov    %eax,%ebx
f0101886:	72 08                	jb     f0101890 <__umoddi3+0x110>
f0101888:	75 11                	jne    f010189b <__umoddi3+0x11b>
f010188a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010188e:	73 0b                	jae    f010189b <__umoddi3+0x11b>
f0101890:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101894:	1b 14 24             	sbb    (%esp),%edx
f0101897:	89 d1                	mov    %edx,%ecx
f0101899:	89 c3                	mov    %eax,%ebx
f010189b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010189f:	29 da                	sub    %ebx,%edx
f01018a1:	19 ce                	sbb    %ecx,%esi
f01018a3:	89 f9                	mov    %edi,%ecx
f01018a5:	89 f0                	mov    %esi,%eax
f01018a7:	d3 e0                	shl    %cl,%eax
f01018a9:	89 e9                	mov    %ebp,%ecx
f01018ab:	d3 ea                	shr    %cl,%edx
f01018ad:	89 e9                	mov    %ebp,%ecx
f01018af:	d3 ee                	shr    %cl,%esi
f01018b1:	09 d0                	or     %edx,%eax
f01018b3:	89 f2                	mov    %esi,%edx
f01018b5:	83 c4 1c             	add    $0x1c,%esp
f01018b8:	5b                   	pop    %ebx
f01018b9:	5e                   	pop    %esi
f01018ba:	5f                   	pop    %edi
f01018bb:	5d                   	pop    %ebp
f01018bc:	c3                   	ret    
f01018bd:	8d 76 00             	lea    0x0(%esi),%esi
f01018c0:	29 f9                	sub    %edi,%ecx
f01018c2:	19 d6                	sbb    %edx,%esi
f01018c4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01018c8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018cc:	e9 18 ff ff ff       	jmp    f01017e9 <__umoddi3+0x69>

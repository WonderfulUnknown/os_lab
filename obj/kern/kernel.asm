
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
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
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
f0100034:	bc 00 80 11 f0       	mov    $0xf0118000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


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
f0100046:	b8 50 4c 17 f0       	mov    $0xf0174c50,%eax
f010004b:	2d 26 3d 17 f0       	sub    $0xf0173d26,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 26 3d 17 f0       	push   $0xf0173d26
f0100058:	e8 e3 40 00 00       	call   f0104140 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 d0 04 00 00       	call   f0100532 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 e0 45 10 f0       	push   $0xf01045e0
f010006f:	e8 65 2e 00 00       	call   f0102ed9 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 c9 0f 00 00       	call   f0101042 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100079:	e8 7c 28 00 00       	call   f01028fa <env_init>
	trap_init();
f010007e:	e8 c7 2e 00 00       	call   f0102f4a <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100083:	83 c4 08             	add    $0x8,%esp
f0100086:	6a 00                	push   $0x0
f0100088:	68 c6 eb 12 f0       	push   $0xf012ebc6
f010008d:	e8 11 2a 00 00       	call   f0102aa3 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f0100092:	83 c4 04             	add    $0x4,%esp
f0100095:	ff 35 88 3f 17 f0    	pushl  0xf0173f88
f010009b:	e8 59 2d 00 00       	call   f0102df9 <env_run>

f01000a0 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	56                   	push   %esi
f01000a4:	53                   	push   %ebx
f01000a5:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000a8:	83 3d 40 4c 17 f0 00 	cmpl   $0x0,0xf0174c40
f01000af:	75 37                	jne    f01000e8 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000b1:	89 35 40 4c 17 f0    	mov    %esi,0xf0174c40

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000b7:	fa                   	cli    
f01000b8:	fc                   	cld    

	va_start(ap, fmt);
f01000b9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000bc:	83 ec 04             	sub    $0x4,%esp
f01000bf:	ff 75 0c             	pushl  0xc(%ebp)
f01000c2:	ff 75 08             	pushl  0x8(%ebp)
f01000c5:	68 fb 45 10 f0       	push   $0xf01045fb
f01000ca:	e8 0a 2e 00 00       	call   f0102ed9 <cprintf>
	vcprintf(fmt, ap);
f01000cf:	83 c4 08             	add    $0x8,%esp
f01000d2:	53                   	push   %ebx
f01000d3:	56                   	push   %esi
f01000d4:	e8 da 2d 00 00       	call   f0102eb3 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 e9 48 10 f0 	movl   $0xf01048e9,(%esp)
f01000e0:	e8 f4 2d 00 00       	call   f0102ed9 <cprintf>
	va_end(ap);
f01000e5:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e8:	83 ec 0c             	sub    $0xc,%esp
f01000eb:	6a 00                	push   $0x0
f01000ed:	e8 f3 06 00 00       	call   f01007e5 <monitor>
f01000f2:	83 c4 10             	add    $0x10,%esp
f01000f5:	eb f1                	jmp    f01000e8 <_panic+0x48>

f01000f7 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	53                   	push   %ebx
f01000fb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fe:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100101:	ff 75 0c             	pushl  0xc(%ebp)
f0100104:	ff 75 08             	pushl  0x8(%ebp)
f0100107:	68 13 46 10 f0       	push   $0xf0104613
f010010c:	e8 c8 2d 00 00       	call   f0102ed9 <cprintf>
	vcprintf(fmt, ap);
f0100111:	83 c4 08             	add    $0x8,%esp
f0100114:	53                   	push   %ebx
f0100115:	ff 75 10             	pushl  0x10(%ebp)
f0100118:	e8 96 2d 00 00       	call   f0102eb3 <vcprintf>
	cprintf("\n");
f010011d:	c7 04 24 e9 48 10 f0 	movl   $0xf01048e9,(%esp)
f0100124:	e8 b0 2d 00 00       	call   f0102ed9 <cprintf>
	va_end(ap);
}
f0100129:	83 c4 10             	add    $0x10,%esp
f010012c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010012f:	c9                   	leave  
f0100130:	c3                   	ret    

f0100131 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100131:	55                   	push   %ebp
f0100132:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100134:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100139:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010013a:	a8 01                	test   $0x1,%al
f010013c:	74 0b                	je     f0100149 <serial_proc_data+0x18>
f010013e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100143:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100144:	0f b6 c0             	movzbl %al,%eax
f0100147:	eb 05                	jmp    f010014e <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010014e:	5d                   	pop    %ebp
f010014f:	c3                   	ret    

f0100150 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 04             	sub    $0x4,%esp
f0100157:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100159:	eb 2b                	jmp    f0100186 <cons_intr+0x36>
		if (c == 0)
f010015b:	85 c0                	test   %eax,%eax
f010015d:	74 27                	je     f0100186 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010015f:	8b 0d 64 3f 17 f0    	mov    0xf0173f64,%ecx
f0100165:	8d 51 01             	lea    0x1(%ecx),%edx
f0100168:	89 15 64 3f 17 f0    	mov    %edx,0xf0173f64
f010016e:	88 81 60 3d 17 f0    	mov    %al,-0xfe8c2a0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100174:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010017a:	75 0a                	jne    f0100186 <cons_intr+0x36>
			cons.wpos = 0;
f010017c:	c7 05 64 3f 17 f0 00 	movl   $0x0,0xf0173f64
f0100183:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100186:	ff d3                	call   *%ebx
f0100188:	83 f8 ff             	cmp    $0xffffffff,%eax
f010018b:	75 ce                	jne    f010015b <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010018d:	83 c4 04             	add    $0x4,%esp
f0100190:	5b                   	pop    %ebx
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <kbd_proc_data>:
f0100193:	ba 64 00 00 00       	mov    $0x64,%edx
f0100198:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100199:	a8 01                	test   $0x1,%al
f010019b:	0f 84 f0 00 00 00    	je     f0100291 <kbd_proc_data+0xfe>
f01001a1:	ba 60 00 00 00       	mov    $0x60,%edx
f01001a6:	ec                   	in     (%dx),%al
f01001a7:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001a9:	3c e0                	cmp    $0xe0,%al
f01001ab:	75 0d                	jne    f01001ba <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001ad:	83 0d 40 3d 17 f0 40 	orl    $0x40,0xf0173d40
		return 0;
f01001b4:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001b9:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ba:	55                   	push   %ebp
f01001bb:	89 e5                	mov    %esp,%ebp
f01001bd:	53                   	push   %ebx
f01001be:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001c1:	84 c0                	test   %al,%al
f01001c3:	79 36                	jns    f01001fb <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001c5:	8b 0d 40 3d 17 f0    	mov    0xf0173d40,%ecx
f01001cb:	89 cb                	mov    %ecx,%ebx
f01001cd:	83 e3 40             	and    $0x40,%ebx
f01001d0:	83 e0 7f             	and    $0x7f,%eax
f01001d3:	85 db                	test   %ebx,%ebx
f01001d5:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001d8:	0f b6 d2             	movzbl %dl,%edx
f01001db:	0f b6 82 80 47 10 f0 	movzbl -0xfefb880(%edx),%eax
f01001e2:	83 c8 40             	or     $0x40,%eax
f01001e5:	0f b6 c0             	movzbl %al,%eax
f01001e8:	f7 d0                	not    %eax
f01001ea:	21 c8                	and    %ecx,%eax
f01001ec:	a3 40 3d 17 f0       	mov    %eax,0xf0173d40
		return 0;
f01001f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f6:	e9 9e 00 00 00       	jmp    f0100299 <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f01001fb:	8b 0d 40 3d 17 f0    	mov    0xf0173d40,%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 0d 40 3d 17 f0    	mov    %ecx,0xf0173d40
	}

	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100217:	0f b6 82 80 47 10 f0 	movzbl -0xfefb880(%edx),%eax
f010021e:	0b 05 40 3d 17 f0    	or     0xf0173d40,%eax
f0100224:	0f b6 8a 80 46 10 f0 	movzbl -0xfefb980(%edx),%ecx
f010022b:	31 c8                	xor    %ecx,%eax
f010022d:	a3 40 3d 17 f0       	mov    %eax,0xf0173d40

	c = charcode[shift & (CTL | SHIFT)][data];
f0100232:	89 c1                	mov    %eax,%ecx
f0100234:	83 e1 03             	and    $0x3,%ecx
f0100237:	8b 0c 8d 60 46 10 f0 	mov    -0xfefb9a0(,%ecx,4),%ecx
f010023e:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100242:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100245:	a8 08                	test   $0x8,%al
f0100247:	74 1b                	je     f0100264 <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100249:	89 da                	mov    %ebx,%edx
f010024b:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010024e:	83 f9 19             	cmp    $0x19,%ecx
f0100251:	77 05                	ja     f0100258 <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100253:	83 eb 20             	sub    $0x20,%ebx
f0100256:	eb 0c                	jmp    f0100264 <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100258:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010025b:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010025e:	83 fa 19             	cmp    $0x19,%edx
f0100261:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100264:	f7 d0                	not    %eax
f0100266:	a8 06                	test   $0x6,%al
f0100268:	75 2d                	jne    f0100297 <kbd_proc_data+0x104>
f010026a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100270:	75 25                	jne    f0100297 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f0100272:	83 ec 0c             	sub    $0xc,%esp
f0100275:	68 2d 46 10 f0       	push   $0xf010462d
f010027a:	e8 5a 2c 00 00       	call   f0102ed9 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010027f:	ba 92 00 00 00       	mov    $0x92,%edx
f0100284:	b8 03 00 00 00       	mov    $0x3,%eax
f0100289:	ee                   	out    %al,(%dx)
f010028a:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010028d:	89 d8                	mov    %ebx,%eax
f010028f:	eb 08                	jmp    f0100299 <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100291:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100296:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100297:	89 d8                	mov    %ebx,%eax
}
f0100299:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010029c:	c9                   	leave  
f010029d:	c3                   	ret    

f010029e <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010029e:	55                   	push   %ebp
f010029f:	89 e5                	mov    %esp,%ebp
f01002a1:	57                   	push   %edi
f01002a2:	56                   	push   %esi
f01002a3:	53                   	push   %ebx
f01002a4:	83 ec 1c             	sub    $0x1c,%esp
f01002a7:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a9:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002ae:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002b3:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b8:	eb 09                	jmp    f01002c3 <cons_putc+0x25>
f01002ba:	89 ca                	mov    %ecx,%edx
f01002bc:	ec                   	in     (%dx),%al
f01002bd:	ec                   	in     (%dx),%al
f01002be:	ec                   	in     (%dx),%al
f01002bf:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002c0:	83 c3 01             	add    $0x1,%ebx
f01002c3:	89 f2                	mov    %esi,%edx
f01002c5:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002c6:	a8 20                	test   $0x20,%al
f01002c8:	75 08                	jne    f01002d2 <cons_putc+0x34>
f01002ca:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002d0:	7e e8                	jle    f01002ba <cons_putc+0x1c>
f01002d2:	89 f8                	mov    %edi,%eax
f01002d4:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d7:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002dc:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002dd:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e2:	be 79 03 00 00       	mov    $0x379,%esi
f01002e7:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002ec:	eb 09                	jmp    f01002f7 <cons_putc+0x59>
f01002ee:	89 ca                	mov    %ecx,%edx
f01002f0:	ec                   	in     (%dx),%al
f01002f1:	ec                   	in     (%dx),%al
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	ec                   	in     (%dx),%al
f01002f4:	83 c3 01             	add    $0x1,%ebx
f01002f7:	89 f2                	mov    %esi,%edx
f01002f9:	ec                   	in     (%dx),%al
f01002fa:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100300:	7f 04                	jg     f0100306 <cons_putc+0x68>
f0100302:	84 c0                	test   %al,%al
f0100304:	79 e8                	jns    f01002ee <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100306:	ba 78 03 00 00       	mov    $0x378,%edx
f010030b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010030f:	ee                   	out    %al,(%dx)
f0100310:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100315:	b8 0d 00 00 00       	mov    $0xd,%eax
f010031a:	ee                   	out    %al,(%dx)
f010031b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100320:	ee                   	out    %al,(%dx)
cga_putc(int c)
{
	// if no attribute given, then use black on white
	//if (!(c & ~0xFF))
	//	c |= 0x0700;
	if (!(c & ~0xFF)){
f0100321:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100327:	75 3d                	jne    f0100366 <cons_putc+0xc8>
    	  char ch = c & 0xFF;
    	    if (ch > 47 && ch < 58) {
f0100329:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010032d:	83 e8 30             	sub    $0x30,%eax
f0100330:	3c 09                	cmp    $0x9,%al
f0100332:	77 08                	ja     f010033c <cons_putc+0x9e>
              c |= 0x0100;
f0100334:	81 cf 00 01 00 00    	or     $0x100,%edi
f010033a:	eb 2a                	jmp    f0100366 <cons_putc+0xc8>
    	    }
	    else if (ch > 64 && ch < 91) {
f010033c:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100340:	83 e8 41             	sub    $0x41,%eax
f0100343:	3c 19                	cmp    $0x19,%al
f0100345:	77 08                	ja     f010034f <cons_putc+0xb1>
              c |= 0x0200;
f0100347:	81 cf 00 02 00 00    	or     $0x200,%edi
f010034d:	eb 17                	jmp    f0100366 <cons_putc+0xc8>
    	    }
	    else if (ch > 96 && ch < 123) {
f010034f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100353:	83 e8 61             	sub    $0x61,%eax
              c |= 0x0300;
f0100356:	89 fa                	mov    %edi,%edx
f0100358:	80 ce 03             	or     $0x3,%dh
f010035b:	81 cf 00 04 00 00    	or     $0x400,%edi
f0100361:	3c 19                	cmp    $0x19,%al
f0100363:	0f 46 fa             	cmovbe %edx,%edi
    	    }
	    else {
              c |= 0x0400;
    	    }
	}
	switch (c & 0xff) {
f0100366:	89 f8                	mov    %edi,%eax
f0100368:	0f b6 c0             	movzbl %al,%eax
f010036b:	83 f8 09             	cmp    $0x9,%eax
f010036e:	74 74                	je     f01003e4 <cons_putc+0x146>
f0100370:	83 f8 09             	cmp    $0x9,%eax
f0100373:	7f 0a                	jg     f010037f <cons_putc+0xe1>
f0100375:	83 f8 08             	cmp    $0x8,%eax
f0100378:	74 14                	je     f010038e <cons_putc+0xf0>
f010037a:	e9 99 00 00 00       	jmp    f0100418 <cons_putc+0x17a>
f010037f:	83 f8 0a             	cmp    $0xa,%eax
f0100382:	74 3a                	je     f01003be <cons_putc+0x120>
f0100384:	83 f8 0d             	cmp    $0xd,%eax
f0100387:	74 3d                	je     f01003c6 <cons_putc+0x128>
f0100389:	e9 8a 00 00 00       	jmp    f0100418 <cons_putc+0x17a>
	case '\b':
		if (crt_pos > 0) {
f010038e:	0f b7 05 68 3f 17 f0 	movzwl 0xf0173f68,%eax
f0100395:	66 85 c0             	test   %ax,%ax
f0100398:	0f 84 e6 00 00 00    	je     f0100484 <cons_putc+0x1e6>
			crt_pos--;
f010039e:	83 e8 01             	sub    $0x1,%eax
f01003a1:	66 a3 68 3f 17 f0    	mov    %ax,0xf0173f68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003a7:	0f b7 c0             	movzwl %ax,%eax
f01003aa:	66 81 e7 00 ff       	and    $0xff00,%di
f01003af:	83 cf 20             	or     $0x20,%edi
f01003b2:	8b 15 6c 3f 17 f0    	mov    0xf0173f6c,%edx
f01003b8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003bc:	eb 78                	jmp    f0100436 <cons_putc+0x198>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003be:	66 83 05 68 3f 17 f0 	addw   $0x50,0xf0173f68
f01003c5:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003c6:	0f b7 05 68 3f 17 f0 	movzwl 0xf0173f68,%eax
f01003cd:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003d3:	c1 e8 16             	shr    $0x16,%eax
f01003d6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003d9:	c1 e0 04             	shl    $0x4,%eax
f01003dc:	66 a3 68 3f 17 f0    	mov    %ax,0xf0173f68
f01003e2:	eb 52                	jmp    f0100436 <cons_putc+0x198>
		break;
	case '\t':
		cons_putc(' ');
f01003e4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e9:	e8 b0 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003ee:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f3:	e8 a6 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f01003f8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fd:	e8 9c fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f0100402:	b8 20 00 00 00       	mov    $0x20,%eax
f0100407:	e8 92 fe ff ff       	call   f010029e <cons_putc>
		cons_putc(' ');
f010040c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100411:	e8 88 fe ff ff       	call   f010029e <cons_putc>
f0100416:	eb 1e                	jmp    f0100436 <cons_putc+0x198>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100418:	0f b7 05 68 3f 17 f0 	movzwl 0xf0173f68,%eax
f010041f:	8d 50 01             	lea    0x1(%eax),%edx
f0100422:	66 89 15 68 3f 17 f0 	mov    %dx,0xf0173f68
f0100429:	0f b7 c0             	movzwl %ax,%eax
f010042c:	8b 15 6c 3f 17 f0    	mov    0xf0173f6c,%edx
f0100432:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100436:	66 81 3d 68 3f 17 f0 	cmpw   $0x7cf,0xf0173f68
f010043d:	cf 07 
f010043f:	76 43                	jbe    f0100484 <cons_putc+0x1e6>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100441:	a1 6c 3f 17 f0       	mov    0xf0173f6c,%eax
f0100446:	83 ec 04             	sub    $0x4,%esp
f0100449:	68 00 0f 00 00       	push   $0xf00
f010044e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100454:	52                   	push   %edx
f0100455:	50                   	push   %eax
f0100456:	e8 32 3d 00 00       	call   f010418d <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010045b:	8b 15 6c 3f 17 f0    	mov    0xf0173f6c,%edx
f0100461:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100467:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010046d:	83 c4 10             	add    $0x10,%esp
f0100470:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100475:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100478:	39 d0                	cmp    %edx,%eax
f010047a:	75 f4                	jne    f0100470 <cons_putc+0x1d2>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010047c:	66 83 2d 68 3f 17 f0 	subw   $0x50,0xf0173f68
f0100483:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100484:	8b 0d 70 3f 17 f0    	mov    0xf0173f70,%ecx
f010048a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010048f:	89 ca                	mov    %ecx,%edx
f0100491:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100492:	0f b7 1d 68 3f 17 f0 	movzwl 0xf0173f68,%ebx
f0100499:	8d 71 01             	lea    0x1(%ecx),%esi
f010049c:	89 d8                	mov    %ebx,%eax
f010049e:	66 c1 e8 08          	shr    $0x8,%ax
f01004a2:	89 f2                	mov    %esi,%edx
f01004a4:	ee                   	out    %al,(%dx)
f01004a5:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004aa:	89 ca                	mov    %ecx,%edx
f01004ac:	ee                   	out    %al,(%dx)
f01004ad:	89 d8                	mov    %ebx,%eax
f01004af:	89 f2                	mov    %esi,%edx
f01004b1:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004b2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004b5:	5b                   	pop    %ebx
f01004b6:	5e                   	pop    %esi
f01004b7:	5f                   	pop    %edi
f01004b8:	5d                   	pop    %ebp
f01004b9:	c3                   	ret    

f01004ba <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004ba:	80 3d 74 3f 17 f0 00 	cmpb   $0x0,0xf0173f74
f01004c1:	74 11                	je     f01004d4 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004c3:	55                   	push   %ebp
f01004c4:	89 e5                	mov    %esp,%ebp
f01004c6:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004c9:	b8 31 01 10 f0       	mov    $0xf0100131,%eax
f01004ce:	e8 7d fc ff ff       	call   f0100150 <cons_intr>
}
f01004d3:	c9                   	leave  
f01004d4:	f3 c3                	repz ret 

f01004d6 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004d6:	55                   	push   %ebp
f01004d7:	89 e5                	mov    %esp,%ebp
f01004d9:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004dc:	b8 93 01 10 f0       	mov    $0xf0100193,%eax
f01004e1:	e8 6a fc ff ff       	call   f0100150 <cons_intr>
}
f01004e6:	c9                   	leave  
f01004e7:	c3                   	ret    

f01004e8 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004e8:	55                   	push   %ebp
f01004e9:	89 e5                	mov    %esp,%ebp
f01004eb:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004ee:	e8 c7 ff ff ff       	call   f01004ba <serial_intr>
	kbd_intr();
f01004f3:	e8 de ff ff ff       	call   f01004d6 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004f8:	a1 60 3f 17 f0       	mov    0xf0173f60,%eax
f01004fd:	3b 05 64 3f 17 f0    	cmp    0xf0173f64,%eax
f0100503:	74 26                	je     f010052b <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100505:	8d 50 01             	lea    0x1(%eax),%edx
f0100508:	89 15 60 3f 17 f0    	mov    %edx,0xf0173f60
f010050e:	0f b6 88 60 3d 17 f0 	movzbl -0xfe8c2a0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100515:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100517:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010051d:	75 11                	jne    f0100530 <cons_getc+0x48>
			cons.rpos = 0;
f010051f:	c7 05 60 3f 17 f0 00 	movl   $0x0,0xf0173f60
f0100526:	00 00 00 
f0100529:	eb 05                	jmp    f0100530 <cons_getc+0x48>
		return c;
	}
	return 0;
f010052b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100530:	c9                   	leave  
f0100531:	c3                   	ret    

f0100532 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100532:	55                   	push   %ebp
f0100533:	89 e5                	mov    %esp,%ebp
f0100535:	57                   	push   %edi
f0100536:	56                   	push   %esi
f0100537:	53                   	push   %ebx
f0100538:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010053b:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100542:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100549:	5a a5 
	if (*cp != 0xA55A) {
f010054b:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100552:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100556:	74 11                	je     f0100569 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100558:	c7 05 70 3f 17 f0 b4 	movl   $0x3b4,0xf0173f70
f010055f:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100562:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100567:	eb 16                	jmp    f010057f <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100569:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100570:	c7 05 70 3f 17 f0 d4 	movl   $0x3d4,0xf0173f70
f0100577:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010057a:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010057f:	8b 3d 70 3f 17 f0    	mov    0xf0173f70,%edi
f0100585:	b8 0e 00 00 00       	mov    $0xe,%eax
f010058a:	89 fa                	mov    %edi,%edx
f010058c:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010058d:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100590:	89 da                	mov    %ebx,%edx
f0100592:	ec                   	in     (%dx),%al
f0100593:	0f b6 c8             	movzbl %al,%ecx
f0100596:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100599:	b8 0f 00 00 00       	mov    $0xf,%eax
f010059e:	89 fa                	mov    %edi,%edx
f01005a0:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a1:	89 da                	mov    %ebx,%edx
f01005a3:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005a4:	89 35 6c 3f 17 f0    	mov    %esi,0xf0173f6c
	crt_pos = pos;
f01005aa:	0f b6 c0             	movzbl %al,%eax
f01005ad:	09 c8                	or     %ecx,%eax
f01005af:	66 a3 68 3f 17 f0    	mov    %ax,0xf0173f68
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005b5:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bf:	89 f2                	mov    %esi,%edx
f01005c1:	ee                   	out    %al,(%dx)
f01005c2:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005c7:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005cc:	ee                   	out    %al,(%dx)
f01005cd:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005d2:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005d7:	89 da                	mov    %ebx,%edx
f01005d9:	ee                   	out    %al,(%dx)
f01005da:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005df:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e4:	ee                   	out    %al,(%dx)
f01005e5:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005ea:	b8 03 00 00 00       	mov    $0x3,%eax
f01005ef:	ee                   	out    %al,(%dx)
f01005f0:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005f5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005fa:	ee                   	out    %al,(%dx)
f01005fb:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100600:	b8 01 00 00 00       	mov    $0x1,%eax
f0100605:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100606:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010060b:	ec                   	in     (%dx),%al
f010060c:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010060e:	3c ff                	cmp    $0xff,%al
f0100610:	0f 95 05 74 3f 17 f0 	setne  0xf0173f74
f0100617:	89 f2                	mov    %esi,%edx
f0100619:	ec                   	in     (%dx),%al
f010061a:	89 da                	mov    %ebx,%edx
f010061c:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010061d:	80 f9 ff             	cmp    $0xff,%cl
f0100620:	75 10                	jne    f0100632 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100622:	83 ec 0c             	sub    $0xc,%esp
f0100625:	68 39 46 10 f0       	push   $0xf0104639
f010062a:	e8 aa 28 00 00       	call   f0102ed9 <cprintf>
f010062f:	83 c4 10             	add    $0x10,%esp
}
f0100632:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100635:	5b                   	pop    %ebx
f0100636:	5e                   	pop    %esi
f0100637:	5f                   	pop    %edi
f0100638:	5d                   	pop    %ebp
f0100639:	c3                   	ret    

f010063a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010063a:	55                   	push   %ebp
f010063b:	89 e5                	mov    %esp,%ebp
f010063d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100640:	8b 45 08             	mov    0x8(%ebp),%eax
f0100643:	e8 56 fc ff ff       	call   f010029e <cons_putc>
}
f0100648:	c9                   	leave  
f0100649:	c3                   	ret    

f010064a <getchar>:

int
getchar(void)
{
f010064a:	55                   	push   %ebp
f010064b:	89 e5                	mov    %esp,%ebp
f010064d:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100650:	e8 93 fe ff ff       	call   f01004e8 <cons_getc>
f0100655:	85 c0                	test   %eax,%eax
f0100657:	74 f7                	je     f0100650 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100659:	c9                   	leave  
f010065a:	c3                   	ret    

f010065b <iscons>:

int
iscons(int fdnum)
{
f010065b:	55                   	push   %ebp
f010065c:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010065e:	b8 01 00 00 00       	mov    $0x1,%eax
f0100663:	5d                   	pop    %ebp
f0100664:	c3                   	ret    

f0100665 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100665:	55                   	push   %ebp
f0100666:	89 e5                	mov    %esp,%ebp
f0100668:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010066b:	68 80 48 10 f0       	push   $0xf0104880
f0100670:	68 9e 48 10 f0       	push   $0xf010489e
f0100675:	68 a3 48 10 f0       	push   $0xf01048a3
f010067a:	e8 5a 28 00 00       	call   f0102ed9 <cprintf>
f010067f:	83 c4 0c             	add    $0xc,%esp
f0100682:	68 38 49 10 f0       	push   $0xf0104938
f0100687:	68 ac 48 10 f0       	push   $0xf01048ac
f010068c:	68 a3 48 10 f0       	push   $0xf01048a3
f0100691:	e8 43 28 00 00       	call   f0102ed9 <cprintf>
f0100696:	83 c4 0c             	add    $0xc,%esp
f0100699:	68 60 49 10 f0       	push   $0xf0104960
f010069e:	68 b5 48 10 f0       	push   $0xf01048b5
f01006a3:	68 a3 48 10 f0       	push   $0xf01048a3
f01006a8:	e8 2c 28 00 00       	call   f0102ed9 <cprintf>
	return 0;
}
f01006ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01006b2:	c9                   	leave  
f01006b3:	c3                   	ret    

f01006b4 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006b4:	55                   	push   %ebp
f01006b5:	89 e5                	mov    %esp,%ebp
f01006b7:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006ba:	68 bf 48 10 f0       	push   $0xf01048bf
f01006bf:	e8 15 28 00 00       	call   f0102ed9 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006c4:	83 c4 08             	add    $0x8,%esp
f01006c7:	68 0c 00 10 00       	push   $0x10000c
f01006cc:	68 88 49 10 f0       	push   $0xf0104988
f01006d1:	e8 03 28 00 00       	call   f0102ed9 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006d6:	83 c4 0c             	add    $0xc,%esp
f01006d9:	68 0c 00 10 00       	push   $0x10000c
f01006de:	68 0c 00 10 f0       	push   $0xf010000c
f01006e3:	68 b0 49 10 f0       	push   $0xf01049b0
f01006e8:	e8 ec 27 00 00       	call   f0102ed9 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ed:	83 c4 0c             	add    $0xc,%esp
f01006f0:	68 d1 45 10 00       	push   $0x1045d1
f01006f5:	68 d1 45 10 f0       	push   $0xf01045d1
f01006fa:	68 d4 49 10 f0       	push   $0xf01049d4
f01006ff:	e8 d5 27 00 00       	call   f0102ed9 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100704:	83 c4 0c             	add    $0xc,%esp
f0100707:	68 26 3d 17 00       	push   $0x173d26
f010070c:	68 26 3d 17 f0       	push   $0xf0173d26
f0100711:	68 f8 49 10 f0       	push   $0xf01049f8
f0100716:	e8 be 27 00 00       	call   f0102ed9 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010071b:	83 c4 0c             	add    $0xc,%esp
f010071e:	68 50 4c 17 00       	push   $0x174c50
f0100723:	68 50 4c 17 f0       	push   $0xf0174c50
f0100728:	68 1c 4a 10 f0       	push   $0xf0104a1c
f010072d:	e8 a7 27 00 00       	call   f0102ed9 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100732:	b8 4f 50 17 f0       	mov    $0xf017504f,%eax
f0100737:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010073c:	83 c4 08             	add    $0x8,%esp
f010073f:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100744:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010074a:	85 c0                	test   %eax,%eax
f010074c:	0f 48 c2             	cmovs  %edx,%eax
f010074f:	c1 f8 0a             	sar    $0xa,%eax
f0100752:	50                   	push   %eax
f0100753:	68 40 4a 10 f0       	push   $0xf0104a40
f0100758:	e8 7c 27 00 00       	call   f0102ed9 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010075d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100762:	c9                   	leave  
f0100763:	c3                   	ret    

f0100764 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100764:	55                   	push   %ebp
f0100765:	89 e5                	mov    %esp,%ebp
f0100767:	57                   	push   %edi
f0100768:	56                   	push   %esi
f0100769:	53                   	push   %ebx
f010076a:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010076d:	89 eb                	mov    %ebp,%ebx
	struct Eipdebuginfo info;        
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();
	
	cprintf("Stack backtrace:\r\n");
f010076f:	68 d8 48 10 f0       	push   $0xf01048d8
f0100774:	e8 60 27 00 00       	call   f0102ed9 <cprintf>
    	while (ebp!=0)
f0100779:	83 c4 10             	add    $0x10,%esp
    	{
	eip = ebp[1];
       	cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);//%08x 补0输出8位16进制数
	debuginfo_eip((uintptr_t)eip,&info);
f010077c:	8d 7d d0             	lea    -0x30(%ebp),%edi
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();
	
	cprintf("Stack backtrace:\r\n");
    	while (ebp!=0)
f010077f:	eb 53                	jmp    f01007d4 <mon_backtrace+0x70>
    	{
	eip = ebp[1];
f0100781:	8b 73 04             	mov    0x4(%ebx),%esi
       	cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", ebp, eip, ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);//%08x 补0输出8位16进制数
f0100784:	ff 73 18             	pushl  0x18(%ebx)
f0100787:	ff 73 14             	pushl  0x14(%ebx)
f010078a:	ff 73 10             	pushl  0x10(%ebx)
f010078d:	ff 73 0c             	pushl  0xc(%ebx)
f0100790:	ff 73 08             	pushl  0x8(%ebx)
f0100793:	56                   	push   %esi
f0100794:	53                   	push   %ebx
f0100795:	68 6c 4a 10 f0       	push   $0xf0104a6c
f010079a:	e8 3a 27 00 00       	call   f0102ed9 <cprintf>
	debuginfo_eip((uintptr_t)eip,&info);
f010079f:	83 c4 18             	add    $0x18,%esp
f01007a2:	57                   	push   %edi
f01007a3:	56                   	push   %esi
f01007a4:	e8 f3 2f 00 00       	call   f010379c <debuginfo_eip>
	cprintf("%s:%d", info.eip_file, info.eip_line);
f01007a9:	83 c4 0c             	add    $0xc,%esp
f01007ac:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007af:	ff 75 d0             	pushl  -0x30(%ebp)
f01007b2:	68 eb 48 10 f0       	push   $0xf01048eb
f01007b7:	e8 1d 27 00 00       	call   f0102ed9 <cprintf>
        cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name,info.eip_fn_addr);
f01007bc:	ff 75 e0             	pushl  -0x20(%ebp)
f01007bf:	ff 75 d8             	pushl  -0x28(%ebp)
f01007c2:	ff 75 dc             	pushl  -0x24(%ebp)
f01007c5:	68 f1 48 10 f0       	push   $0xf01048f1
f01007ca:	e8 0a 27 00 00       	call   f0102ed9 <cprintf>
   	ebp = (uint32_t *)ebp[0];
f01007cf:	8b 1b                	mov    (%ebx),%ebx
f01007d1:	83 c4 20             	add    $0x20,%esp
	uint32_t *ebp,eip;

	ebp = (uint32_t *)read_ebp();
	
	cprintf("Stack backtrace:\r\n");
    	while (ebp!=0)
f01007d4:	85 db                	test   %ebx,%ebx
f01007d6:	75 a9                	jne    f0100781 <mon_backtrace+0x1d>
	cprintf("%s:%d", info.eip_file, info.eip_line);
        cprintf(": %.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name,info.eip_fn_addr);
   	ebp = (uint32_t *)ebp[0];
    	}
    	return 0;
}
f01007d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01007dd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007e0:	5b                   	pop    %ebx
f01007e1:	5e                   	pop    %esi
f01007e2:	5f                   	pop    %edi
f01007e3:	5d                   	pop    %ebp
f01007e4:	c3                   	ret    

f01007e5 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007e5:	55                   	push   %ebp
f01007e6:	89 e5                	mov    %esp,%ebp
f01007e8:	57                   	push   %edi
f01007e9:	56                   	push   %esi
f01007ea:	53                   	push   %ebx
f01007eb:	83 ec 58             	sub    $0x58,%esp
	char *buf; 
	cprintf("Welcome to the JOS kernel monitor!\n");
f01007ee:	68 a4 4a 10 f0       	push   $0xf0104aa4
f01007f3:	e8 e1 26 00 00       	call   f0102ed9 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007f8:	c7 04 24 c8 4a 10 f0 	movl   $0xf0104ac8,(%esp)
f01007ff:	e8 d5 26 00 00       	call   f0102ed9 <cprintf>

	if (tf != NULL)
f0100804:	83 c4 10             	add    $0x10,%esp
f0100807:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010080b:	74 0e                	je     f010081b <monitor+0x36>
		print_trapframe(tf);
f010080d:	83 ec 0c             	sub    $0xc,%esp
f0100810:	ff 75 08             	pushl  0x8(%ebp)
f0100813:	e8 7a 2a 00 00       	call   f0103292 <print_trapframe>
f0100818:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f010081b:	83 ec 0c             	sub    $0xc,%esp
f010081e:	68 fc 48 10 f0       	push   $0xf01048fc
f0100823:	e8 c1 36 00 00       	call   f0103ee9 <readline>
f0100828:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010082a:	83 c4 10             	add    $0x10,%esp
f010082d:	85 c0                	test   %eax,%eax
f010082f:	74 ea                	je     f010081b <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100831:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100838:	be 00 00 00 00       	mov    $0x0,%esi
f010083d:	eb 0a                	jmp    f0100849 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010083f:	c6 03 00             	movb   $0x0,(%ebx)
f0100842:	89 f7                	mov    %esi,%edi
f0100844:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100847:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100849:	0f b6 03             	movzbl (%ebx),%eax
f010084c:	84 c0                	test   %al,%al
f010084e:	74 63                	je     f01008b3 <monitor+0xce>
f0100850:	83 ec 08             	sub    $0x8,%esp
f0100853:	0f be c0             	movsbl %al,%eax
f0100856:	50                   	push   %eax
f0100857:	68 00 49 10 f0       	push   $0xf0104900
f010085c:	e8 a2 38 00 00       	call   f0104103 <strchr>
f0100861:	83 c4 10             	add    $0x10,%esp
f0100864:	85 c0                	test   %eax,%eax
f0100866:	75 d7                	jne    f010083f <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100868:	80 3b 00             	cmpb   $0x0,(%ebx)
f010086b:	74 46                	je     f01008b3 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010086d:	83 fe 0f             	cmp    $0xf,%esi
f0100870:	75 14                	jne    f0100886 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100872:	83 ec 08             	sub    $0x8,%esp
f0100875:	6a 10                	push   $0x10
f0100877:	68 05 49 10 f0       	push   $0xf0104905
f010087c:	e8 58 26 00 00       	call   f0102ed9 <cprintf>
f0100881:	83 c4 10             	add    $0x10,%esp
f0100884:	eb 95                	jmp    f010081b <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f0100886:	8d 7e 01             	lea    0x1(%esi),%edi
f0100889:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010088d:	eb 03                	jmp    f0100892 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010088f:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100892:	0f b6 03             	movzbl (%ebx),%eax
f0100895:	84 c0                	test   %al,%al
f0100897:	74 ae                	je     f0100847 <monitor+0x62>
f0100899:	83 ec 08             	sub    $0x8,%esp
f010089c:	0f be c0             	movsbl %al,%eax
f010089f:	50                   	push   %eax
f01008a0:	68 00 49 10 f0       	push   $0xf0104900
f01008a5:	e8 59 38 00 00       	call   f0104103 <strchr>
f01008aa:	83 c4 10             	add    $0x10,%esp
f01008ad:	85 c0                	test   %eax,%eax
f01008af:	74 de                	je     f010088f <monitor+0xaa>
f01008b1:	eb 94                	jmp    f0100847 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01008b3:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008ba:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008bb:	85 f6                	test   %esi,%esi
f01008bd:	0f 84 58 ff ff ff    	je     f010081b <monitor+0x36>
f01008c3:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008c8:	83 ec 08             	sub    $0x8,%esp
f01008cb:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008ce:	ff 34 85 00 4b 10 f0 	pushl  -0xfefb500(,%eax,4)
f01008d5:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d8:	e8 c8 37 00 00       	call   f01040a5 <strcmp>
f01008dd:	83 c4 10             	add    $0x10,%esp
f01008e0:	85 c0                	test   %eax,%eax
f01008e2:	75 21                	jne    f0100905 <monitor+0x120>
			return commands[i].func(argc, argv, tf);
f01008e4:	83 ec 04             	sub    $0x4,%esp
f01008e7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008ea:	ff 75 08             	pushl  0x8(%ebp)
f01008ed:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008f0:	52                   	push   %edx
f01008f1:	56                   	push   %esi
f01008f2:	ff 14 85 08 4b 10 f0 	call   *-0xfefb4f8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008f9:	83 c4 10             	add    $0x10,%esp
f01008fc:	85 c0                	test   %eax,%eax
f01008fe:	78 25                	js     f0100925 <monitor+0x140>
f0100900:	e9 16 ff ff ff       	jmp    f010081b <monitor+0x36>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100905:	83 c3 01             	add    $0x1,%ebx
f0100908:	83 fb 03             	cmp    $0x3,%ebx
f010090b:	75 bb                	jne    f01008c8 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010090d:	83 ec 08             	sub    $0x8,%esp
f0100910:	ff 75 a8             	pushl  -0x58(%ebp)
f0100913:	68 22 49 10 f0       	push   $0xf0104922
f0100918:	e8 bc 25 00 00       	call   f0102ed9 <cprintf>
f010091d:	83 c4 10             	add    $0x10,%esp
f0100920:	e9 f6 fe ff ff       	jmp    f010081b <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100925:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100928:	5b                   	pop    %ebx
f0100929:	5e                   	pop    %esi
f010092a:	5f                   	pop    %edi
f010092b:	5d                   	pop    %ebp
f010092c:	c3                   	ret    

f010092d <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f010092d:	55                   	push   %ebp
f010092e:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100930:	83 3d 78 3f 17 f0 00 	cmpl   $0x0,0xf0173f78
f0100937:	75 11                	jne    f010094a <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100939:	ba 4f 5c 17 f0       	mov    $0xf0175c4f,%edx
f010093e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100944:	89 15 78 3f 17 f0    	mov    %edx,0xf0173f78
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f010094a:	8b 0d 78 3f 17 f0    	mov    0xf0173f78,%ecx
	nextfree += n;
	nextfree = ROUNDUP( (char*)nextfree, PGSIZE);
f0100950:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100957:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010095d:	89 15 78 3f 17 f0    	mov    %edx,0xf0173f78
	//nextfree += ROUNDUP(n,PGSIZE);
	return result;
}
f0100963:	89 c8                	mov    %ecx,%eax
f0100965:	5d                   	pop    %ebp
f0100966:	c3                   	ret    

f0100967 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100967:	89 d1                	mov    %edx,%ecx
f0100969:	c1 e9 16             	shr    $0x16,%ecx
f010096c:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010096f:	a8 01                	test   $0x1,%al
f0100971:	74 52                	je     f01009c5 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100973:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100978:	89 c1                	mov    %eax,%ecx
f010097a:	c1 e9 0c             	shr    $0xc,%ecx
f010097d:	3b 0d 44 4c 17 f0    	cmp    0xf0174c44,%ecx
f0100983:	72 1b                	jb     f01009a0 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100985:	55                   	push   %ebp
f0100986:	89 e5                	mov    %esp,%ebp
f0100988:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010098b:	50                   	push   %eax
f010098c:	68 24 4b 10 f0       	push   $0xf0104b24
f0100991:	68 5d 03 00 00       	push   $0x35d
f0100996:	68 a9 52 10 f0       	push   $0xf01052a9
f010099b:	e8 00 f7 ff ff       	call   f01000a0 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009a0:	c1 ea 0c             	shr    $0xc,%edx
f01009a3:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009a9:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009b0:	89 c2                	mov    %eax,%edx
f01009b2:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009b5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009ba:	85 d2                	test   %edx,%edx
f01009bc:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009c1:	0f 44 c2             	cmove  %edx,%eax
f01009c4:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009ca:	c3                   	ret    

f01009cb <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009cb:	55                   	push   %ebp
f01009cc:	89 e5                	mov    %esp,%ebp
f01009ce:	57                   	push   %edi
f01009cf:	56                   	push   %esi
f01009d0:	53                   	push   %ebx
f01009d1:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009d4:	84 c0                	test   %al,%al
f01009d6:	0f 85 72 02 00 00    	jne    f0100c4e <check_page_free_list+0x283>
f01009dc:	e9 7f 02 00 00       	jmp    f0100c60 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009e1:	83 ec 04             	sub    $0x4,%esp
f01009e4:	68 48 4b 10 f0       	push   $0xf0104b48
f01009e9:	68 9b 02 00 00       	push   $0x29b
f01009ee:	68 a9 52 10 f0       	push   $0xf01052a9
f01009f3:	e8 a8 f6 ff ff       	call   f01000a0 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01009f8:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01009fb:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01009fe:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a01:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a04:	89 c2                	mov    %eax,%edx
f0100a06:	2b 15 4c 4c 17 f0    	sub    0xf0174c4c,%edx
f0100a0c:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a12:	0f 95 c2             	setne  %dl
f0100a15:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a18:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a1c:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a1e:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a22:	8b 00                	mov    (%eax),%eax
f0100a24:	85 c0                	test   %eax,%eax
f0100a26:	75 dc                	jne    f0100a04 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a28:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a2b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a31:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a34:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a37:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a39:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a3c:	a3 7c 3f 17 f0       	mov    %eax,0xf0173f7c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a41:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a46:	8b 1d 7c 3f 17 f0    	mov    0xf0173f7c,%ebx
f0100a4c:	eb 53                	jmp    f0100aa1 <check_page_free_list+0xd6>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a4e:	89 d8                	mov    %ebx,%eax
f0100a50:	2b 05 4c 4c 17 f0    	sub    0xf0174c4c,%eax
f0100a56:	c1 f8 03             	sar    $0x3,%eax
f0100a59:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a5c:	89 c2                	mov    %eax,%edx
f0100a5e:	c1 ea 16             	shr    $0x16,%edx
f0100a61:	39 f2                	cmp    %esi,%edx
f0100a63:	73 3a                	jae    f0100a9f <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a65:	89 c2                	mov    %eax,%edx
f0100a67:	c1 ea 0c             	shr    $0xc,%edx
f0100a6a:	3b 15 44 4c 17 f0    	cmp    0xf0174c44,%edx
f0100a70:	72 12                	jb     f0100a84 <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a72:	50                   	push   %eax
f0100a73:	68 24 4b 10 f0       	push   $0xf0104b24
f0100a78:	6a 56                	push   $0x56
f0100a7a:	68 b5 52 10 f0       	push   $0xf01052b5
f0100a7f:	e8 1c f6 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a84:	83 ec 04             	sub    $0x4,%esp
f0100a87:	68 80 00 00 00       	push   $0x80
f0100a8c:	68 97 00 00 00       	push   $0x97
f0100a91:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a96:	50                   	push   %eax
f0100a97:	e8 a4 36 00 00       	call   f0104140 <memset>
f0100a9c:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a9f:	8b 1b                	mov    (%ebx),%ebx
f0100aa1:	85 db                	test   %ebx,%ebx
f0100aa3:	75 a9                	jne    f0100a4e <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100aa5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100aaa:	e8 7e fe ff ff       	call   f010092d <boot_alloc>
f0100aaf:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ab2:	8b 15 7c 3f 17 f0    	mov    0xf0173f7c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ab8:	8b 0d 4c 4c 17 f0    	mov    0xf0174c4c,%ecx
		assert(pp < pages + npages);
f0100abe:	a1 44 4c 17 f0       	mov    0xf0174c44,%eax
f0100ac3:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100ac6:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ac9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100acc:	be 00 00 00 00       	mov    $0x0,%esi
f0100ad1:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ad4:	e9 30 01 00 00       	jmp    f0100c09 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ad9:	39 ca                	cmp    %ecx,%edx
f0100adb:	73 19                	jae    f0100af6 <check_page_free_list+0x12b>
f0100add:	68 c3 52 10 f0       	push   $0xf01052c3
f0100ae2:	68 cf 52 10 f0       	push   $0xf01052cf
f0100ae7:	68 b5 02 00 00       	push   $0x2b5
f0100aec:	68 a9 52 10 f0       	push   $0xf01052a9
f0100af1:	e8 aa f5 ff ff       	call   f01000a0 <_panic>
		assert(pp < pages + npages);
f0100af6:	39 fa                	cmp    %edi,%edx
f0100af8:	72 19                	jb     f0100b13 <check_page_free_list+0x148>
f0100afa:	68 e4 52 10 f0       	push   $0xf01052e4
f0100aff:	68 cf 52 10 f0       	push   $0xf01052cf
f0100b04:	68 b6 02 00 00       	push   $0x2b6
f0100b09:	68 a9 52 10 f0       	push   $0xf01052a9
f0100b0e:	e8 8d f5 ff ff       	call   f01000a0 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b13:	89 d0                	mov    %edx,%eax
f0100b15:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b18:	a8 07                	test   $0x7,%al
f0100b1a:	74 19                	je     f0100b35 <check_page_free_list+0x16a>
f0100b1c:	68 6c 4b 10 f0       	push   $0xf0104b6c
f0100b21:	68 cf 52 10 f0       	push   $0xf01052cf
f0100b26:	68 b7 02 00 00       	push   $0x2b7
f0100b2b:	68 a9 52 10 f0       	push   $0xf01052a9
f0100b30:	e8 6b f5 ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b35:	c1 f8 03             	sar    $0x3,%eax
f0100b38:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b3b:	85 c0                	test   %eax,%eax
f0100b3d:	75 19                	jne    f0100b58 <check_page_free_list+0x18d>
f0100b3f:	68 f8 52 10 f0       	push   $0xf01052f8
f0100b44:	68 cf 52 10 f0       	push   $0xf01052cf
f0100b49:	68 ba 02 00 00       	push   $0x2ba
f0100b4e:	68 a9 52 10 f0       	push   $0xf01052a9
f0100b53:	e8 48 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b58:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b5d:	75 19                	jne    f0100b78 <check_page_free_list+0x1ad>
f0100b5f:	68 09 53 10 f0       	push   $0xf0105309
f0100b64:	68 cf 52 10 f0       	push   $0xf01052cf
f0100b69:	68 bb 02 00 00       	push   $0x2bb
f0100b6e:	68 a9 52 10 f0       	push   $0xf01052a9
f0100b73:	e8 28 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b78:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b7d:	75 19                	jne    f0100b98 <check_page_free_list+0x1cd>
f0100b7f:	68 a0 4b 10 f0       	push   $0xf0104ba0
f0100b84:	68 cf 52 10 f0       	push   $0xf01052cf
f0100b89:	68 bc 02 00 00       	push   $0x2bc
f0100b8e:	68 a9 52 10 f0       	push   $0xf01052a9
f0100b93:	e8 08 f5 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b98:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b9d:	75 19                	jne    f0100bb8 <check_page_free_list+0x1ed>
f0100b9f:	68 22 53 10 f0       	push   $0xf0105322
f0100ba4:	68 cf 52 10 f0       	push   $0xf01052cf
f0100ba9:	68 bd 02 00 00       	push   $0x2bd
f0100bae:	68 a9 52 10 f0       	push   $0xf01052a9
f0100bb3:	e8 e8 f4 ff ff       	call   f01000a0 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bb8:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bbd:	76 3f                	jbe    f0100bfe <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bbf:	89 c3                	mov    %eax,%ebx
f0100bc1:	c1 eb 0c             	shr    $0xc,%ebx
f0100bc4:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100bc7:	77 12                	ja     f0100bdb <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bc9:	50                   	push   %eax
f0100bca:	68 24 4b 10 f0       	push   $0xf0104b24
f0100bcf:	6a 56                	push   $0x56
f0100bd1:	68 b5 52 10 f0       	push   $0xf01052b5
f0100bd6:	e8 c5 f4 ff ff       	call   f01000a0 <_panic>
f0100bdb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100be0:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100be3:	76 1e                	jbe    f0100c03 <check_page_free_list+0x238>
f0100be5:	68 c4 4b 10 f0       	push   $0xf0104bc4
f0100bea:	68 cf 52 10 f0       	push   $0xf01052cf
f0100bef:	68 be 02 00 00       	push   $0x2be
f0100bf4:	68 a9 52 10 f0       	push   $0xf01052a9
f0100bf9:	e8 a2 f4 ff ff       	call   f01000a0 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bfe:	83 c6 01             	add    $0x1,%esi
f0100c01:	eb 04                	jmp    f0100c07 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c03:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c07:	8b 12                	mov    (%edx),%edx
f0100c09:	85 d2                	test   %edx,%edx
f0100c0b:	0f 85 c8 fe ff ff    	jne    f0100ad9 <check_page_free_list+0x10e>
f0100c11:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c14:	85 f6                	test   %esi,%esi
f0100c16:	7f 19                	jg     f0100c31 <check_page_free_list+0x266>
f0100c18:	68 3c 53 10 f0       	push   $0xf010533c
f0100c1d:	68 cf 52 10 f0       	push   $0xf01052cf
f0100c22:	68 c6 02 00 00       	push   $0x2c6
f0100c27:	68 a9 52 10 f0       	push   $0xf01052a9
f0100c2c:	e8 6f f4 ff ff       	call   f01000a0 <_panic>
	assert(nfree_extmem > 0);
f0100c31:	85 db                	test   %ebx,%ebx
f0100c33:	7f 42                	jg     f0100c77 <check_page_free_list+0x2ac>
f0100c35:	68 4e 53 10 f0       	push   $0xf010534e
f0100c3a:	68 cf 52 10 f0       	push   $0xf01052cf
f0100c3f:	68 c7 02 00 00       	push   $0x2c7
f0100c44:	68 a9 52 10 f0       	push   $0xf01052a9
f0100c49:	e8 52 f4 ff ff       	call   f01000a0 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c4e:	a1 7c 3f 17 f0       	mov    0xf0173f7c,%eax
f0100c53:	85 c0                	test   %eax,%eax
f0100c55:	0f 85 9d fd ff ff    	jne    f01009f8 <check_page_free_list+0x2d>
f0100c5b:	e9 81 fd ff ff       	jmp    f01009e1 <check_page_free_list+0x16>
f0100c60:	83 3d 7c 3f 17 f0 00 	cmpl   $0x0,0xf0173f7c
f0100c67:	0f 84 74 fd ff ff    	je     f01009e1 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c6d:	be 00 04 00 00       	mov    $0x400,%esi
f0100c72:	e9 cf fd ff ff       	jmp    f0100a46 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c77:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c7a:	5b                   	pop    %ebx
f0100c7b:	5e                   	pop    %esi
f0100c7c:	5f                   	pop    %edi
f0100c7d:	5d                   	pop    %ebp
f0100c7e:	c3                   	ret    

f0100c7f <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c7f:	55                   	push   %ebp
f0100c80:	89 e5                	mov    %esp,%ebp
f0100c82:	56                   	push   %esi
f0100c83:	53                   	push   %ebx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!

	//  1) Mark physical page 0 as in use.
	pages[0].pp_ref = 1;
f0100c84:	a1 4c 4c 17 f0       	mov    0xf0174c4c,%eax
f0100c89:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;	
f0100c8f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	size_t i;
	//临界点是否等于可能存在问题
	for (i = 1; i < npages; i++) {
f0100c95:	be 08 00 00 00       	mov    $0x8,%esi
f0100c9a:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100c9f:	e9 ab 00 00 00       	jmp    f0100d4f <page_init+0xd0>
	//  2) The rest of base memory
		if(i < npages_basemem){
f0100ca4:	3b 1d 80 3f 17 f0    	cmp    0xf0173f80,%ebx
f0100caa:	73 25                	jae    f0100cd1 <page_init+0x52>
			pages[i].pp_ref = 0;
f0100cac:	89 f0                	mov    %esi,%eax
f0100cae:	03 05 4c 4c 17 f0    	add    0xf0174c4c,%eax
f0100cb4:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100cba:	8b 15 7c 3f 17 f0    	mov    0xf0173f7c,%edx
f0100cc0:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100cc2:	89 f0                	mov    %esi,%eax
f0100cc4:	03 05 4c 4c 17 f0    	add    0xf0174c4c,%eax
f0100cca:	a3 7c 3f 17 f0       	mov    %eax,0xf0173f7c
f0100ccf:	eb 78                	jmp    f0100d49 <page_init+0xca>
		}
	//  3) Then comes the IO hole 
		else if(i >= IOPHYSMEM/PGSIZE && i < EXTPHYSMEM/PGSIZE){
f0100cd1:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100cd7:	83 f8 5f             	cmp    $0x5f,%eax
f0100cda:	77 16                	ja     f0100cf2 <page_init+0x73>
			pages[i].pp_ref = 1;
f0100cdc:	89 f0                	mov    %esi,%eax
f0100cde:	03 05 4c 4c 17 f0    	add    0xf0174c4c,%eax
f0100ce4:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100cea:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100cf0:	eb 57                	jmp    f0100d49 <page_init+0xca>
		}
	//  4) Then extended memory
		else if(i >= EXTPHYSMEM/PGSIZE && i< ((int)boot_alloc(0) - KERNBASE)/PGSIZE){
f0100cf2:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100cf8:	76 2c                	jbe    f0100d26 <page_init+0xa7>
f0100cfa:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cff:	e8 29 fc ff ff       	call   f010092d <boot_alloc>
f0100d04:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d09:	c1 e8 0c             	shr    $0xc,%eax
f0100d0c:	39 c3                	cmp    %eax,%ebx
f0100d0e:	73 16                	jae    f0100d26 <page_init+0xa7>
			pages[i].pp_ref = 1;
f0100d10:	89 f0                	mov    %esi,%eax
f0100d12:	03 05 4c 4c 17 f0    	add    0xf0174c4c,%eax
f0100d18:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100d1e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100d24:	eb 23                	jmp    f0100d49 <page_init+0xca>
		}
		else{
			pages[i].pp_ref = 0;
f0100d26:	89 f0                	mov    %esi,%eax
f0100d28:	03 05 4c 4c 17 f0    	add    0xf0174c4c,%eax
f0100d2e:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100d34:	8b 15 7c 3f 17 f0    	mov    0xf0173f7c,%edx
f0100d3a:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100d3c:	89 f0                	mov    %esi,%eax
f0100d3e:	03 05 4c 4c 17 f0    	add    0xf0174c4c,%eax
f0100d44:	a3 7c 3f 17 f0       	mov    %eax,0xf0173f7c
	//  1) Mark physical page 0 as in use.
	pages[0].pp_ref = 1;
	pages[0].pp_link = NULL;	
	size_t i;
	//临界点是否等于可能存在问题
	for (i = 1; i < npages; i++) {
f0100d49:	83 c3 01             	add    $0x1,%ebx
f0100d4c:	83 c6 08             	add    $0x8,%esi
f0100d4f:	3b 1d 44 4c 17 f0    	cmp    0xf0174c44,%ebx
f0100d55:	0f 82 49 ff ff ff    	jb     f0100ca4 <page_init+0x25>
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100d5b:	5b                   	pop    %ebx
f0100d5c:	5e                   	pop    %esi
f0100d5d:	5d                   	pop    %ebp
f0100d5e:	c3                   	ret    

f0100d5f <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d5f:	55                   	push   %ebp
f0100d60:	89 e5                	mov    %esp,%ebp
f0100d62:	53                   	push   %ebx
f0100d63:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	//cprintf("page_alloc\r\n");
	if(page_free_list == NULL)
f0100d66:	8b 1d 7c 3f 17 f0    	mov    0xf0173f7c,%ebx
f0100d6c:	85 db                	test   %ebx,%ebx
f0100d6e:	74 6e                	je     f0100dde <page_alloc+0x7f>
		//addr = page2kva(page_free_list);
		//int *iq,*ip;
		//iq=ip;//将把ip中的值拷贝到iq中，这样，指针iq也将指向ip指向的对象
		struct PageInfo *Page;
		Page = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100d70:	8b 03                	mov    (%ebx),%eax
f0100d72:	a3 7c 3f 17 f0       	mov    %eax,0xf0173f7c
		//page_free_list->pp_link = NULL;
		Page->pp_link = NULL;
f0100d77:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		//Page->pp_ref = 1;
		Page->pp_ref = 0;
f0100d7d:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		cprintf("page_alloc\r\n");
f0100d83:	83 ec 0c             	sub    $0xc,%esp
f0100d86:	68 5f 53 10 f0       	push   $0xf010535f
f0100d8b:	e8 49 21 00 00       	call   f0102ed9 <cprintf>
		if(alloc_flags & ALLOC_ZERO)
f0100d90:	83 c4 10             	add    $0x10,%esp
f0100d93:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d97:	74 45                	je     f0100dde <page_alloc+0x7f>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d99:	89 d8                	mov    %ebx,%eax
f0100d9b:	2b 05 4c 4c 17 f0    	sub    0xf0174c4c,%eax
f0100da1:	c1 f8 03             	sar    $0x3,%eax
f0100da4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100da7:	89 c2                	mov    %eax,%edx
f0100da9:	c1 ea 0c             	shr    $0xc,%edx
f0100dac:	3b 15 44 4c 17 f0    	cmp    0xf0174c44,%edx
f0100db2:	72 12                	jb     f0100dc6 <page_alloc+0x67>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100db4:	50                   	push   %eax
f0100db5:	68 24 4b 10 f0       	push   $0xf0104b24
f0100dba:	6a 56                	push   $0x56
f0100dbc:	68 b5 52 10 f0       	push   $0xf01052b5
f0100dc1:	e8 da f2 ff ff       	call   f01000a0 <_panic>
			memset(page2kva(Page),'\0',PGSIZE);
f0100dc6:	83 ec 04             	sub    $0x4,%esp
f0100dc9:	68 00 10 00 00       	push   $0x1000
f0100dce:	6a 00                	push   $0x0
f0100dd0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dd5:	50                   	push   %eax
f0100dd6:	e8 65 33 00 00       	call   f0104140 <memset>
f0100ddb:	83 c4 10             	add    $0x10,%esp
			// memset(page2kva(page_free_list),0,PGSIZE);
		return Page;
	}
}
f0100dde:	89 d8                	mov    %ebx,%eax
f0100de0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100de3:	c9                   	leave  
f0100de4:	c3                   	ret    

f0100de5 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100de5:	55                   	push   %ebp
f0100de6:	89 e5                	mov    %esp,%ebp
f0100de8:	83 ec 14             	sub    $0x14,%esp
f0100deb:	8b 45 08             	mov    0x8(%ebp),%eax
	//  	panic("can't free the page");
	//  	return;
	// }
	//	cprinf("can't free the page");
	//pp->pp_link = page_free_list->pp_link;	
	pp->pp_link = page_free_list;
f0100dee:	8b 15 7c 3f 17 f0    	mov    0xf0173f7c,%edx
f0100df4:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100df6:	a3 7c 3f 17 f0       	mov    %eax,0xf0173f7c
	//pp->pp_ref = 0;
	cprintf("page_free\r\n");
f0100dfb:	68 6c 53 10 f0       	push   $0xf010536c
f0100e00:	e8 d4 20 00 00       	call   f0102ed9 <cprintf>
}
f0100e05:	83 c4 10             	add    $0x10,%esp
f0100e08:	c9                   	leave  
f0100e09:	c3                   	ret    

f0100e0a <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e0a:	55                   	push   %ebp
f0100e0b:	89 e5                	mov    %esp,%ebp
f0100e0d:	83 ec 08             	sub    $0x8,%esp
f0100e10:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e13:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100e17:	83 e8 01             	sub    $0x1,%eax
f0100e1a:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e1e:	66 85 c0             	test   %ax,%ax
f0100e21:	75 0c                	jne    f0100e2f <page_decref+0x25>
		page_free(pp);
f0100e23:	83 ec 0c             	sub    $0xc,%esp
f0100e26:	52                   	push   %edx
f0100e27:	e8 b9 ff ff ff       	call   f0100de5 <page_free>
f0100e2c:	83 c4 10             	add    $0x10,%esp
}
f0100e2f:	c9                   	leave  
f0100e30:	c3                   	ret    

f0100e31 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e31:	55                   	push   %ebp
f0100e32:	89 e5                	mov    %esp,%ebp
f0100e34:	56                   	push   %esi
f0100e35:	53                   	push   %ebx
f0100e36:	8b 45 0c             	mov    0xc(%ebp),%eax
	// Fill this function in
	uint32_t pd_number,pt_number,pt_addr;//,page_number,page_addr;
	pte_t *pte = NULL;
	struct PageInfo *Page;
	pd_number = PDX(va);
	pt_number = PTX(va);
f0100e39:	89 c6                	mov    %eax,%esi
f0100e3b:	c1 ee 0c             	shr    $0xc,%esi
f0100e3e:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	if(pgdir[pd_number] & PTE_P)
f0100e44:	c1 e8 16             	shr    $0x16,%eax
f0100e47:	8d 1c 85 00 00 00 00 	lea    0x0(,%eax,4),%ebx
f0100e4e:	03 5d 08             	add    0x8(%ebp),%ebx
f0100e51:	8b 03                	mov    (%ebx),%eax
f0100e53:	a8 01                	test   $0x1,%al
f0100e55:	74 2e                	je     f0100e85 <pgdir_walk+0x54>
		pte = KADDR(PTE_ADDR(pgdir[pd_number]));
f0100e57:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e5c:	89 c2                	mov    %eax,%edx
f0100e5e:	c1 ea 0c             	shr    $0xc,%edx
f0100e61:	39 15 44 4c 17 f0    	cmp    %edx,0xf0174c44
f0100e67:	77 15                	ja     f0100e7e <pgdir_walk+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e69:	50                   	push   %eax
f0100e6a:	68 24 4b 10 f0       	push   $0xf0104b24
f0100e6f:	68 94 01 00 00       	push   $0x194
f0100e74:	68 a9 52 10 f0       	push   $0xf01052a9
f0100e79:	e8 22 f2 ff ff       	call   f01000a0 <_panic>
	if(!pte){
f0100e7e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e83:	75 58                	jne    f0100edd <pgdir_walk+0xac>
		if(!create)
f0100e85:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e89:	74 57                	je     f0100ee2 <pgdir_walk+0xb1>
	 		return NULL;
	 	Page = page_alloc(create);
f0100e8b:	83 ec 0c             	sub    $0xc,%esp
f0100e8e:	ff 75 10             	pushl  0x10(%ebp)
f0100e91:	e8 c9 fe ff ff       	call   f0100d5f <page_alloc>
		if(!Page)
f0100e96:	83 c4 10             	add    $0x10,%esp
f0100e99:	85 c0                	test   %eax,%eax
f0100e9b:	74 4c                	je     f0100ee9 <pgdir_walk+0xb8>
			return NULL;
		Page->pp_ref ++;
f0100e9d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ea2:	2b 05 4c 4c 17 f0    	sub    0xf0174c4c,%eax
f0100ea8:	89 c2                	mov    %eax,%edx
f0100eaa:	c1 fa 03             	sar    $0x3,%edx
f0100ead:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eb0:	89 d0                	mov    %edx,%eax
f0100eb2:	c1 e8 0c             	shr    $0xc,%eax
f0100eb5:	3b 05 44 4c 17 f0    	cmp    0xf0174c44,%eax
f0100ebb:	72 15                	jb     f0100ed2 <pgdir_walk+0xa1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ebd:	52                   	push   %edx
f0100ebe:	68 24 4b 10 f0       	push   $0xf0104b24
f0100ec3:	68 9c 01 00 00       	push   $0x19c
f0100ec8:	68 a9 52 10 f0       	push   $0xf01052a9
f0100ecd:	e8 ce f1 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0100ed2:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	 	pte = KADDR(page2pa(Page));		
		// pgdir[pd_number] = page2pa(Page);
		pgdir[pd_number] = page2pa(Page) | PTE_P | PTE_W | PTE_U;
f0100ed8:	83 ca 07             	or     $0x7,%edx
f0100edb:	89 13                	mov    %edx,(%ebx)
	}
	return &(pte[pt_number]);
f0100edd:	8d 04 b0             	lea    (%eax,%esi,4),%eax
f0100ee0:	eb 0c                	jmp    f0100eee <pgdir_walk+0xbd>
	pt_number = PTX(va);
	if(pgdir[pd_number] & PTE_P)
		pte = KADDR(PTE_ADDR(pgdir[pd_number]));
	if(!pte){
		if(!create)
	 		return NULL;
f0100ee2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ee7:	eb 05                	jmp    f0100eee <pgdir_walk+0xbd>
	 	Page = page_alloc(create);
		if(!Page)
			return NULL;
f0100ee9:	b8 00 00 00 00       	mov    $0x0,%eax
	// //不确定page_alloc函数里应该填入的参数,page_alloc(int alloc_flags)
	// 	Page = page_alloc(create);
	// 	page_addr = page2pa(Page);
	// }
	// return page_addr;
}
f0100eee:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ef1:	5b                   	pop    %ebx
f0100ef2:	5e                   	pop    %esi
f0100ef3:	5d                   	pop    %ebp
f0100ef4:	c3                   	ret    

f0100ef5 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100ef5:	55                   	push   %ebp
f0100ef6:	89 e5                	mov    %esp,%ebp
f0100ef8:	57                   	push   %edi
f0100ef9:	56                   	push   %esi
f0100efa:	53                   	push   %ebx
f0100efb:	83 ec 1c             	sub    $0x1c,%esp
f0100efe:	89 c7                	mov    %eax,%edi
f0100f00:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100f03:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	pte_t *pte = NULL;
	for(int i = 0;i < size;i += PGSIZE){
f0100f06:	bb 00 00 00 00       	mov    $0x0,%ebx
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
f0100f0b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f0e:	83 c8 01             	or     $0x1,%eax
f0100f11:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte = NULL;
	for(int i = 0;i < size;i += PGSIZE){
f0100f14:	eb 1f                	jmp    f0100f35 <boot_map_region+0x40>
		pte = pgdir_walk(pgdir, (void *)va, 1);
f0100f16:	83 ec 04             	sub    $0x4,%esp
f0100f19:	6a 01                	push   $0x1
f0100f1b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f1e:	01 d8                	add    %ebx,%eax
f0100f20:	50                   	push   %eax
f0100f21:	57                   	push   %edi
f0100f22:	e8 0a ff ff ff       	call   f0100e31 <pgdir_walk>
		*pte = (pa | perm | PTE_P);
f0100f27:	0b 75 dc             	or     -0x24(%ebp),%esi
f0100f2a:	89 30                	mov    %esi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	pte_t *pte = NULL;
	for(int i = 0;i < size;i += PGSIZE){
f0100f2c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f32:	83 c4 10             	add    $0x10,%esp
f0100f35:	89 de                	mov    %ebx,%esi
f0100f37:	03 75 08             	add    0x8(%ebp),%esi
f0100f3a:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0100f3d:	77 d7                	ja     f0100f16 <boot_map_region+0x21>
		pte = pgdir_walk(pgdir, (void *)va, 1);
		*pte = (pa | perm | PTE_P);
		va += PGSIZE;
		pa += PGSIZE;
	}
}
f0100f3f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f42:	5b                   	pop    %ebx
f0100f43:	5e                   	pop    %esi
f0100f44:	5f                   	pop    %edi
f0100f45:	5d                   	pop    %ebp
f0100f46:	c3                   	ret    

f0100f47 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f47:	55                   	push   %ebp
f0100f48:	89 e5                	mov    %esp,%ebp
f0100f4a:	53                   	push   %ebx
f0100f4b:	83 ec 08             	sub    $0x8,%esp
f0100f4e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
f0100f51:	6a 00                	push   $0x0
f0100f53:	ff 75 0c             	pushl  0xc(%ebp)
f0100f56:	ff 75 08             	pushl  0x8(%ebp)
f0100f59:	e8 d3 fe ff ff       	call   f0100e31 <pgdir_walk>
	if(!pte)
f0100f5e:	83 c4 10             	add    $0x10,%esp
f0100f61:	85 c0                	test   %eax,%eax
f0100f63:	74 32                	je     f0100f97 <page_lookup+0x50>
		return NULL;
	if(pte_store)
f0100f65:	85 db                	test   %ebx,%ebx
f0100f67:	74 02                	je     f0100f6b <page_lookup+0x24>
		*pte_store = pte;
f0100f69:	89 03                	mov    %eax,(%ebx)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f6b:	8b 00                	mov    (%eax),%eax
f0100f6d:	c1 e8 0c             	shr    $0xc,%eax
f0100f70:	3b 05 44 4c 17 f0    	cmp    0xf0174c44,%eax
f0100f76:	72 14                	jb     f0100f8c <page_lookup+0x45>
		panic("pa2page called with invalid pa");
f0100f78:	83 ec 04             	sub    $0x4,%esp
f0100f7b:	68 0c 4c 10 f0       	push   $0xf0104c0c
f0100f80:	6a 4f                	push   $0x4f
f0100f82:	68 b5 52 10 f0       	push   $0xf01052b5
f0100f87:	e8 14 f1 ff ff       	call   f01000a0 <_panic>
	return &pages[PGNUM(pa)];
f0100f8c:	8b 15 4c 4c 17 f0    	mov    0xf0174c4c,%edx
f0100f92:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	return pa2page(PTE_ADDR(*pte));
f0100f95:	eb 05                	jmp    f0100f9c <page_lookup+0x55>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, (void *)va, 0);//只查询,create=0
	if(!pte)
		return NULL;
f0100f97:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store)
		*pte_store = pte;
	return pa2page(PTE_ADDR(*pte));
}
f0100f9c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f9f:	c9                   	leave  
f0100fa0:	c3                   	ret    

f0100fa1 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100fa1:	55                   	push   %ebp
f0100fa2:	89 e5                	mov    %esp,%ebp
f0100fa4:	53                   	push   %ebx
f0100fa5:	83 ec 18             	sub    $0x18,%esp
f0100fa8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	// pte_t *pte,**pte_store;
	// pte = pgdir_walk(pgdir, (void *)va, 0);
	// pte_store = &pte;
	struct PageInfo *Page;
	Page = page_lookup(pgdir, va, &pte);
f0100fab:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fae:	50                   	push   %eax
f0100faf:	53                   	push   %ebx
f0100fb0:	ff 75 08             	pushl  0x8(%ebp)
f0100fb3:	e8 8f ff ff ff       	call   f0100f47 <page_lookup>
	// Page = page_lookup(pgdir, va, pte_store);
	if(Page){
f0100fb8:	83 c4 10             	add    $0x10,%esp
f0100fbb:	85 c0                	test   %eax,%eax
f0100fbd:	74 18                	je     f0100fd7 <page_remove+0x36>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100fbf:	0f 01 3b             	invlpg (%ebx)
		// Page->pp_ref --;
		tlb_invalidate(pgdir, va);
		page_decref(Page);
f0100fc2:	83 ec 0c             	sub    $0xc,%esp
f0100fc5:	50                   	push   %eax
f0100fc6:	e8 3f fe ff ff       	call   f0100e0a <page_decref>
		*pte = 0;//将对应的页表项清空
f0100fcb:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100fce:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100fd4:	83 c4 10             	add    $0x10,%esp
	}
}
f0100fd7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fda:	c9                   	leave  
f0100fdb:	c3                   	ret    

f0100fdc <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100fdc:	55                   	push   %ebp
f0100fdd:	89 e5                	mov    %esp,%ebp
f0100fdf:	57                   	push   %edi
f0100fe0:	56                   	push   %esi
f0100fe1:	53                   	push   %ebx
f0100fe2:	83 ec 10             	sub    $0x10,%esp
f0100fe5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fe8:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
f0100feb:	6a 01                	push   $0x1
f0100fed:	57                   	push   %edi
f0100fee:	ff 75 08             	pushl  0x8(%ebp)
f0100ff1:	e8 3b fe ff ff       	call   f0100e31 <pgdir_walk>
	if(!pte)
f0100ff6:	83 c4 10             	add    $0x10,%esp
f0100ff9:	85 c0                	test   %eax,%eax
f0100ffb:	74 38                	je     f0101035 <page_insert+0x59>
f0100ffd:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	pp->pp_ref++;
f0100fff:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	//删除旧映射关系 
    if((*pte) & PTE_P)
f0101004:	f6 00 01             	testb  $0x1,(%eax)
f0101007:	74 0f                	je     f0101018 <page_insert+0x3c>
        page_remove(pgdir, va);
f0101009:	83 ec 08             	sub    $0x8,%esp
f010100c:	57                   	push   %edi
f010100d:	ff 75 08             	pushl  0x8(%ebp)
f0101010:	e8 8c ff ff ff       	call   f0100fa1 <page_remove>
f0101015:	83 c4 10             	add    $0x10,%esp
	//pp ->pp_ref++;
    *pte = page2pa(pp) | perm | PTE_P;
f0101018:	2b 1d 4c 4c 17 f0    	sub    0xf0174c4c,%ebx
f010101e:	c1 fb 03             	sar    $0x3,%ebx
f0101021:	c1 e3 0c             	shl    $0xc,%ebx
f0101024:	8b 45 14             	mov    0x14(%ebp),%eax
f0101027:	83 c8 01             	or     $0x1,%eax
f010102a:	09 c3                	or     %eax,%ebx
f010102c:	89 1e                	mov    %ebx,(%esi)
	return 0;
f010102e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101033:	eb 05                	jmp    f010103a <page_insert+0x5e>
{
	// Fill this function in
	pte_t *pte;
	pte = pgdir_walk(pgdir, va, 1); //查找对应的页表项，没有就创建
	if(!pte)
		return -E_NO_MEM;
f0101035:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	// 		page_remove(pgdir, va); 
	// }
	// //pp->pp_ref++;
    // *pte = page2pa(pp) | perm | PTE_P;
	// return 0;
}
f010103a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010103d:	5b                   	pop    %ebx
f010103e:	5e                   	pop    %esi
f010103f:	5f                   	pop    %edi
f0101040:	5d                   	pop    %ebp
f0101041:	c3                   	ret    

f0101042 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101042:	55                   	push   %ebp
f0101043:	89 e5                	mov    %esp,%ebp
f0101045:	57                   	push   %edi
f0101046:	56                   	push   %esi
f0101047:	53                   	push   %ebx
f0101048:	83 ec 38             	sub    $0x38,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010104b:	6a 15                	push   $0x15
f010104d:	e8 20 1e 00 00       	call   f0102e72 <mc146818_read>
f0101052:	89 c3                	mov    %eax,%ebx
f0101054:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010105b:	e8 12 1e 00 00       	call   f0102e72 <mc146818_read>
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101060:	c1 e0 08             	shl    $0x8,%eax
f0101063:	09 d8                	or     %ebx,%eax
f0101065:	c1 e0 0a             	shl    $0xa,%eax
f0101068:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010106e:	85 c0                	test   %eax,%eax
f0101070:	0f 48 c2             	cmovs  %edx,%eax
f0101073:	c1 f8 0c             	sar    $0xc,%eax
f0101076:	a3 80 3f 17 f0       	mov    %eax,0xf0173f80
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010107b:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101082:	e8 eb 1d 00 00       	call   f0102e72 <mc146818_read>
f0101087:	89 c3                	mov    %eax,%ebx
f0101089:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101090:	e8 dd 1d 00 00       	call   f0102e72 <mc146818_read>
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101095:	c1 e0 08             	shl    $0x8,%eax
f0101098:	09 d8                	or     %ebx,%eax
f010109a:	c1 e0 0a             	shl    $0xa,%eax
f010109d:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01010a3:	83 c4 10             	add    $0x10,%esp
f01010a6:	85 c0                	test   %eax,%eax
f01010a8:	0f 48 c2             	cmovs  %edx,%eax
f01010ab:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01010ae:	85 c0                	test   %eax,%eax
f01010b0:	74 0e                	je     f01010c0 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01010b2:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01010b8:	89 15 44 4c 17 f0    	mov    %edx,0xf0174c44
f01010be:	eb 0c                	jmp    f01010cc <mem_init+0x8a>
	else
		npages = npages_basemem;
f01010c0:	8b 15 80 3f 17 f0    	mov    0xf0173f80,%edx
f01010c6:	89 15 44 4c 17 f0    	mov    %edx,0xf0174c44

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010cc:	c1 e0 0c             	shl    $0xc,%eax
f01010cf:	c1 e8 0a             	shr    $0xa,%eax
f01010d2:	50                   	push   %eax
f01010d3:	a1 80 3f 17 f0       	mov    0xf0173f80,%eax
f01010d8:	c1 e0 0c             	shl    $0xc,%eax
f01010db:	c1 e8 0a             	shr    $0xa,%eax
f01010de:	50                   	push   %eax
f01010df:	a1 44 4c 17 f0       	mov    0xf0174c44,%eax
f01010e4:	c1 e0 0c             	shl    $0xc,%eax
f01010e7:	c1 e8 0a             	shr    $0xa,%eax
f01010ea:	50                   	push   %eax
f01010eb:	68 2c 4c 10 f0       	push   $0xf0104c2c
f01010f0:	e8 e4 1d 00 00       	call   f0102ed9 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01010f5:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010fa:	e8 2e f8 ff ff       	call   f010092d <boot_alloc>
f01010ff:	a3 48 4c 17 f0       	mov    %eax,0xf0174c48
	memset(kern_pgdir, 0, PGSIZE);
f0101104:	83 c4 0c             	add    $0xc,%esp
f0101107:	68 00 10 00 00       	push   $0x1000
f010110c:	6a 00                	push   $0x0
f010110e:	50                   	push   %eax
f010110f:	e8 2c 30 00 00       	call   f0104140 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101114:	a1 48 4c 17 f0       	mov    0xf0174c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101119:	83 c4 10             	add    $0x10,%esp
f010111c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101121:	77 15                	ja     f0101138 <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101123:	50                   	push   %eax
f0101124:	68 68 4c 10 f0       	push   $0xf0104c68
f0101129:	68 8e 00 00 00       	push   $0x8e
f010112e:	68 a9 52 10 f0       	push   $0xf01052a9
f0101133:	e8 68 ef ff ff       	call   f01000a0 <_panic>
f0101138:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010113e:	83 ca 05             	or     $0x5,%edx
f0101141:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f0101147:	a1 44 4c 17 f0       	mov    0xf0174c44,%eax
f010114c:	c1 e0 03             	shl    $0x3,%eax
f010114f:	e8 d9 f7 ff ff       	call   f010092d <boot_alloc>
f0101154:	a3 4c 4c 17 f0       	mov    %eax,0xf0174c4c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101159:	83 ec 04             	sub    $0x4,%esp
f010115c:	8b 3d 44 4c 17 f0    	mov    0xf0174c44,%edi
f0101162:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f0101169:	52                   	push   %edx
f010116a:	6a 00                	push   $0x0
f010116c:	50                   	push   %eax
f010116d:	e8 ce 2f 00 00       	call   f0104140 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env*)boot_alloc(NENV * sizeof(struct Env));
f0101172:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101177:	e8 b1 f7 ff ff       	call   f010092d <boot_alloc>
f010117c:	a3 88 3f 17 f0       	mov    %eax,0xf0173f88
	memset(envs, 0, NENV * sizeof(struct Env));
f0101181:	83 c4 0c             	add    $0xc,%esp
f0101184:	68 00 80 01 00       	push   $0x18000
f0101189:	6a 00                	push   $0x0
f010118b:	50                   	push   %eax
f010118c:	e8 af 2f 00 00       	call   f0104140 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101191:	e8 e9 fa ff ff       	call   f0100c7f <page_init>

	check_page_free_list(1);
f0101196:	b8 01 00 00 00       	mov    $0x1,%eax
f010119b:	e8 2b f8 ff ff       	call   f01009cb <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011a0:	83 c4 10             	add    $0x10,%esp
f01011a3:	83 3d 4c 4c 17 f0 00 	cmpl   $0x0,0xf0174c4c
f01011aa:	75 17                	jne    f01011c3 <mem_init+0x181>
		panic("'pages' is a null pointer!");
f01011ac:	83 ec 04             	sub    $0x4,%esp
f01011af:	68 78 53 10 f0       	push   $0xf0105378
f01011b4:	68 d8 02 00 00       	push   $0x2d8
f01011b9:	68 a9 52 10 f0       	push   $0xf01052a9
f01011be:	e8 dd ee ff ff       	call   f01000a0 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011c3:	a1 7c 3f 17 f0       	mov    0xf0173f7c,%eax
f01011c8:	bb 00 00 00 00       	mov    $0x0,%ebx
f01011cd:	eb 05                	jmp    f01011d4 <mem_init+0x192>
		++nfree;
f01011cf:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011d2:	8b 00                	mov    (%eax),%eax
f01011d4:	85 c0                	test   %eax,%eax
f01011d6:	75 f7                	jne    f01011cf <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011d8:	83 ec 0c             	sub    $0xc,%esp
f01011db:	6a 00                	push   $0x0
f01011dd:	e8 7d fb ff ff       	call   f0100d5f <page_alloc>
f01011e2:	89 c7                	mov    %eax,%edi
f01011e4:	83 c4 10             	add    $0x10,%esp
f01011e7:	85 c0                	test   %eax,%eax
f01011e9:	75 19                	jne    f0101204 <mem_init+0x1c2>
f01011eb:	68 93 53 10 f0       	push   $0xf0105393
f01011f0:	68 cf 52 10 f0       	push   $0xf01052cf
f01011f5:	68 e0 02 00 00       	push   $0x2e0
f01011fa:	68 a9 52 10 f0       	push   $0xf01052a9
f01011ff:	e8 9c ee ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f0101204:	83 ec 0c             	sub    $0xc,%esp
f0101207:	6a 00                	push   $0x0
f0101209:	e8 51 fb ff ff       	call   f0100d5f <page_alloc>
f010120e:	89 c6                	mov    %eax,%esi
f0101210:	83 c4 10             	add    $0x10,%esp
f0101213:	85 c0                	test   %eax,%eax
f0101215:	75 19                	jne    f0101230 <mem_init+0x1ee>
f0101217:	68 a9 53 10 f0       	push   $0xf01053a9
f010121c:	68 cf 52 10 f0       	push   $0xf01052cf
f0101221:	68 e1 02 00 00       	push   $0x2e1
f0101226:	68 a9 52 10 f0       	push   $0xf01052a9
f010122b:	e8 70 ee ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f0101230:	83 ec 0c             	sub    $0xc,%esp
f0101233:	6a 00                	push   $0x0
f0101235:	e8 25 fb ff ff       	call   f0100d5f <page_alloc>
f010123a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010123d:	83 c4 10             	add    $0x10,%esp
f0101240:	85 c0                	test   %eax,%eax
f0101242:	75 19                	jne    f010125d <mem_init+0x21b>
f0101244:	68 bf 53 10 f0       	push   $0xf01053bf
f0101249:	68 cf 52 10 f0       	push   $0xf01052cf
f010124e:	68 e2 02 00 00       	push   $0x2e2
f0101253:	68 a9 52 10 f0       	push   $0xf01052a9
f0101258:	e8 43 ee ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010125d:	39 f7                	cmp    %esi,%edi
f010125f:	75 19                	jne    f010127a <mem_init+0x238>
f0101261:	68 d5 53 10 f0       	push   $0xf01053d5
f0101266:	68 cf 52 10 f0       	push   $0xf01052cf
f010126b:	68 e5 02 00 00       	push   $0x2e5
f0101270:	68 a9 52 10 f0       	push   $0xf01052a9
f0101275:	e8 26 ee ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010127a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010127d:	39 c6                	cmp    %eax,%esi
f010127f:	74 04                	je     f0101285 <mem_init+0x243>
f0101281:	39 c7                	cmp    %eax,%edi
f0101283:	75 19                	jne    f010129e <mem_init+0x25c>
f0101285:	68 8c 4c 10 f0       	push   $0xf0104c8c
f010128a:	68 cf 52 10 f0       	push   $0xf01052cf
f010128f:	68 e6 02 00 00       	push   $0x2e6
f0101294:	68 a9 52 10 f0       	push   $0xf01052a9
f0101299:	e8 02 ee ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010129e:	8b 0d 4c 4c 17 f0    	mov    0xf0174c4c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01012a4:	8b 15 44 4c 17 f0    	mov    0xf0174c44,%edx
f01012aa:	c1 e2 0c             	shl    $0xc,%edx
f01012ad:	89 f8                	mov    %edi,%eax
f01012af:	29 c8                	sub    %ecx,%eax
f01012b1:	c1 f8 03             	sar    $0x3,%eax
f01012b4:	c1 e0 0c             	shl    $0xc,%eax
f01012b7:	39 d0                	cmp    %edx,%eax
f01012b9:	72 19                	jb     f01012d4 <mem_init+0x292>
f01012bb:	68 e7 53 10 f0       	push   $0xf01053e7
f01012c0:	68 cf 52 10 f0       	push   $0xf01052cf
f01012c5:	68 e7 02 00 00       	push   $0x2e7
f01012ca:	68 a9 52 10 f0       	push   $0xf01052a9
f01012cf:	e8 cc ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012d4:	89 f0                	mov    %esi,%eax
f01012d6:	29 c8                	sub    %ecx,%eax
f01012d8:	c1 f8 03             	sar    $0x3,%eax
f01012db:	c1 e0 0c             	shl    $0xc,%eax
f01012de:	39 c2                	cmp    %eax,%edx
f01012e0:	77 19                	ja     f01012fb <mem_init+0x2b9>
f01012e2:	68 04 54 10 f0       	push   $0xf0105404
f01012e7:	68 cf 52 10 f0       	push   $0xf01052cf
f01012ec:	68 e8 02 00 00       	push   $0x2e8
f01012f1:	68 a9 52 10 f0       	push   $0xf01052a9
f01012f6:	e8 a5 ed ff ff       	call   f01000a0 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012fb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012fe:	29 c8                	sub    %ecx,%eax
f0101300:	c1 f8 03             	sar    $0x3,%eax
f0101303:	c1 e0 0c             	shl    $0xc,%eax
f0101306:	39 c2                	cmp    %eax,%edx
f0101308:	77 19                	ja     f0101323 <mem_init+0x2e1>
f010130a:	68 21 54 10 f0       	push   $0xf0105421
f010130f:	68 cf 52 10 f0       	push   $0xf01052cf
f0101314:	68 e9 02 00 00       	push   $0x2e9
f0101319:	68 a9 52 10 f0       	push   $0xf01052a9
f010131e:	e8 7d ed ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101323:	a1 7c 3f 17 f0       	mov    0xf0173f7c,%eax
f0101328:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010132b:	c7 05 7c 3f 17 f0 00 	movl   $0x0,0xf0173f7c
f0101332:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101335:	83 ec 0c             	sub    $0xc,%esp
f0101338:	6a 00                	push   $0x0
f010133a:	e8 20 fa ff ff       	call   f0100d5f <page_alloc>
f010133f:	83 c4 10             	add    $0x10,%esp
f0101342:	85 c0                	test   %eax,%eax
f0101344:	74 19                	je     f010135f <mem_init+0x31d>
f0101346:	68 3e 54 10 f0       	push   $0xf010543e
f010134b:	68 cf 52 10 f0       	push   $0xf01052cf
f0101350:	68 f0 02 00 00       	push   $0x2f0
f0101355:	68 a9 52 10 f0       	push   $0xf01052a9
f010135a:	e8 41 ed ff ff       	call   f01000a0 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010135f:	83 ec 0c             	sub    $0xc,%esp
f0101362:	57                   	push   %edi
f0101363:	e8 7d fa ff ff       	call   f0100de5 <page_free>
	page_free(pp1);
f0101368:	89 34 24             	mov    %esi,(%esp)
f010136b:	e8 75 fa ff ff       	call   f0100de5 <page_free>
	page_free(pp2);
f0101370:	83 c4 04             	add    $0x4,%esp
f0101373:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101376:	e8 6a fa ff ff       	call   f0100de5 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010137b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101382:	e8 d8 f9 ff ff       	call   f0100d5f <page_alloc>
f0101387:	89 c6                	mov    %eax,%esi
f0101389:	83 c4 10             	add    $0x10,%esp
f010138c:	85 c0                	test   %eax,%eax
f010138e:	75 19                	jne    f01013a9 <mem_init+0x367>
f0101390:	68 93 53 10 f0       	push   $0xf0105393
f0101395:	68 cf 52 10 f0       	push   $0xf01052cf
f010139a:	68 f7 02 00 00       	push   $0x2f7
f010139f:	68 a9 52 10 f0       	push   $0xf01052a9
f01013a4:	e8 f7 ec ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01013a9:	83 ec 0c             	sub    $0xc,%esp
f01013ac:	6a 00                	push   $0x0
f01013ae:	e8 ac f9 ff ff       	call   f0100d5f <page_alloc>
f01013b3:	89 c7                	mov    %eax,%edi
f01013b5:	83 c4 10             	add    $0x10,%esp
f01013b8:	85 c0                	test   %eax,%eax
f01013ba:	75 19                	jne    f01013d5 <mem_init+0x393>
f01013bc:	68 a9 53 10 f0       	push   $0xf01053a9
f01013c1:	68 cf 52 10 f0       	push   $0xf01052cf
f01013c6:	68 f8 02 00 00       	push   $0x2f8
f01013cb:	68 a9 52 10 f0       	push   $0xf01052a9
f01013d0:	e8 cb ec ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01013d5:	83 ec 0c             	sub    $0xc,%esp
f01013d8:	6a 00                	push   $0x0
f01013da:	e8 80 f9 ff ff       	call   f0100d5f <page_alloc>
f01013df:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013e2:	83 c4 10             	add    $0x10,%esp
f01013e5:	85 c0                	test   %eax,%eax
f01013e7:	75 19                	jne    f0101402 <mem_init+0x3c0>
f01013e9:	68 bf 53 10 f0       	push   $0xf01053bf
f01013ee:	68 cf 52 10 f0       	push   $0xf01052cf
f01013f3:	68 f9 02 00 00       	push   $0x2f9
f01013f8:	68 a9 52 10 f0       	push   $0xf01052a9
f01013fd:	e8 9e ec ff ff       	call   f01000a0 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101402:	39 fe                	cmp    %edi,%esi
f0101404:	75 19                	jne    f010141f <mem_init+0x3dd>
f0101406:	68 d5 53 10 f0       	push   $0xf01053d5
f010140b:	68 cf 52 10 f0       	push   $0xf01052cf
f0101410:	68 fb 02 00 00       	push   $0x2fb
f0101415:	68 a9 52 10 f0       	push   $0xf01052a9
f010141a:	e8 81 ec ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010141f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101422:	39 c7                	cmp    %eax,%edi
f0101424:	74 04                	je     f010142a <mem_init+0x3e8>
f0101426:	39 c6                	cmp    %eax,%esi
f0101428:	75 19                	jne    f0101443 <mem_init+0x401>
f010142a:	68 8c 4c 10 f0       	push   $0xf0104c8c
f010142f:	68 cf 52 10 f0       	push   $0xf01052cf
f0101434:	68 fc 02 00 00       	push   $0x2fc
f0101439:	68 a9 52 10 f0       	push   $0xf01052a9
f010143e:	e8 5d ec ff ff       	call   f01000a0 <_panic>
	assert(!page_alloc(0));
f0101443:	83 ec 0c             	sub    $0xc,%esp
f0101446:	6a 00                	push   $0x0
f0101448:	e8 12 f9 ff ff       	call   f0100d5f <page_alloc>
f010144d:	83 c4 10             	add    $0x10,%esp
f0101450:	85 c0                	test   %eax,%eax
f0101452:	74 19                	je     f010146d <mem_init+0x42b>
f0101454:	68 3e 54 10 f0       	push   $0xf010543e
f0101459:	68 cf 52 10 f0       	push   $0xf01052cf
f010145e:	68 fd 02 00 00       	push   $0x2fd
f0101463:	68 a9 52 10 f0       	push   $0xf01052a9
f0101468:	e8 33 ec ff ff       	call   f01000a0 <_panic>
f010146d:	89 f0                	mov    %esi,%eax
f010146f:	2b 05 4c 4c 17 f0    	sub    0xf0174c4c,%eax
f0101475:	c1 f8 03             	sar    $0x3,%eax
f0101478:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010147b:	89 c2                	mov    %eax,%edx
f010147d:	c1 ea 0c             	shr    $0xc,%edx
f0101480:	3b 15 44 4c 17 f0    	cmp    0xf0174c44,%edx
f0101486:	72 12                	jb     f010149a <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101488:	50                   	push   %eax
f0101489:	68 24 4b 10 f0       	push   $0xf0104b24
f010148e:	6a 56                	push   $0x56
f0101490:	68 b5 52 10 f0       	push   $0xf01052b5
f0101495:	e8 06 ec ff ff       	call   f01000a0 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010149a:	83 ec 04             	sub    $0x4,%esp
f010149d:	68 00 10 00 00       	push   $0x1000
f01014a2:	6a 01                	push   $0x1
f01014a4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014a9:	50                   	push   %eax
f01014aa:	e8 91 2c 00 00       	call   f0104140 <memset>
	page_free(pp0);
f01014af:	89 34 24             	mov    %esi,(%esp)
f01014b2:	e8 2e f9 ff ff       	call   f0100de5 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014b7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014be:	e8 9c f8 ff ff       	call   f0100d5f <page_alloc>
f01014c3:	83 c4 10             	add    $0x10,%esp
f01014c6:	85 c0                	test   %eax,%eax
f01014c8:	75 19                	jne    f01014e3 <mem_init+0x4a1>
f01014ca:	68 4d 54 10 f0       	push   $0xf010544d
f01014cf:	68 cf 52 10 f0       	push   $0xf01052cf
f01014d4:	68 02 03 00 00       	push   $0x302
f01014d9:	68 a9 52 10 f0       	push   $0xf01052a9
f01014de:	e8 bd eb ff ff       	call   f01000a0 <_panic>
	assert(pp && pp0 == pp);
f01014e3:	39 c6                	cmp    %eax,%esi
f01014e5:	74 19                	je     f0101500 <mem_init+0x4be>
f01014e7:	68 6b 54 10 f0       	push   $0xf010546b
f01014ec:	68 cf 52 10 f0       	push   $0xf01052cf
f01014f1:	68 03 03 00 00       	push   $0x303
f01014f6:	68 a9 52 10 f0       	push   $0xf01052a9
f01014fb:	e8 a0 eb ff ff       	call   f01000a0 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101500:	89 f0                	mov    %esi,%eax
f0101502:	2b 05 4c 4c 17 f0    	sub    0xf0174c4c,%eax
f0101508:	c1 f8 03             	sar    $0x3,%eax
f010150b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010150e:	89 c2                	mov    %eax,%edx
f0101510:	c1 ea 0c             	shr    $0xc,%edx
f0101513:	3b 15 44 4c 17 f0    	cmp    0xf0174c44,%edx
f0101519:	72 12                	jb     f010152d <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010151b:	50                   	push   %eax
f010151c:	68 24 4b 10 f0       	push   $0xf0104b24
f0101521:	6a 56                	push   $0x56
f0101523:	68 b5 52 10 f0       	push   $0xf01052b5
f0101528:	e8 73 eb ff ff       	call   f01000a0 <_panic>
f010152d:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101533:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101539:	80 38 00             	cmpb   $0x0,(%eax)
f010153c:	74 19                	je     f0101557 <mem_init+0x515>
f010153e:	68 7b 54 10 f0       	push   $0xf010547b
f0101543:	68 cf 52 10 f0       	push   $0xf01052cf
f0101548:	68 06 03 00 00       	push   $0x306
f010154d:	68 a9 52 10 f0       	push   $0xf01052a9
f0101552:	e8 49 eb ff ff       	call   f01000a0 <_panic>
f0101557:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010155a:	39 d0                	cmp    %edx,%eax
f010155c:	75 db                	jne    f0101539 <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010155e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101561:	a3 7c 3f 17 f0       	mov    %eax,0xf0173f7c

	// free the pages we took
	page_free(pp0);
f0101566:	83 ec 0c             	sub    $0xc,%esp
f0101569:	56                   	push   %esi
f010156a:	e8 76 f8 ff ff       	call   f0100de5 <page_free>
	page_free(pp1);
f010156f:	89 3c 24             	mov    %edi,(%esp)
f0101572:	e8 6e f8 ff ff       	call   f0100de5 <page_free>
	page_free(pp2);
f0101577:	83 c4 04             	add    $0x4,%esp
f010157a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010157d:	e8 63 f8 ff ff       	call   f0100de5 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101582:	a1 7c 3f 17 f0       	mov    0xf0173f7c,%eax
f0101587:	83 c4 10             	add    $0x10,%esp
f010158a:	eb 05                	jmp    f0101591 <mem_init+0x54f>
		--nfree;
f010158c:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010158f:	8b 00                	mov    (%eax),%eax
f0101591:	85 c0                	test   %eax,%eax
f0101593:	75 f7                	jne    f010158c <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f0101595:	85 db                	test   %ebx,%ebx
f0101597:	74 19                	je     f01015b2 <mem_init+0x570>
f0101599:	68 85 54 10 f0       	push   $0xf0105485
f010159e:	68 cf 52 10 f0       	push   $0xf01052cf
f01015a3:	68 13 03 00 00       	push   $0x313
f01015a8:	68 a9 52 10 f0       	push   $0xf01052a9
f01015ad:	e8 ee ea ff ff       	call   f01000a0 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015b2:	83 ec 0c             	sub    $0xc,%esp
f01015b5:	68 ac 4c 10 f0       	push   $0xf0104cac
f01015ba:	e8 1a 19 00 00       	call   f0102ed9 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015bf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015c6:	e8 94 f7 ff ff       	call   f0100d5f <page_alloc>
f01015cb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015ce:	83 c4 10             	add    $0x10,%esp
f01015d1:	85 c0                	test   %eax,%eax
f01015d3:	75 19                	jne    f01015ee <mem_init+0x5ac>
f01015d5:	68 93 53 10 f0       	push   $0xf0105393
f01015da:	68 cf 52 10 f0       	push   $0xf01052cf
f01015df:	68 71 03 00 00       	push   $0x371
f01015e4:	68 a9 52 10 f0       	push   $0xf01052a9
f01015e9:	e8 b2 ea ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01015ee:	83 ec 0c             	sub    $0xc,%esp
f01015f1:	6a 00                	push   $0x0
f01015f3:	e8 67 f7 ff ff       	call   f0100d5f <page_alloc>
f01015f8:	89 c3                	mov    %eax,%ebx
f01015fa:	83 c4 10             	add    $0x10,%esp
f01015fd:	85 c0                	test   %eax,%eax
f01015ff:	75 19                	jne    f010161a <mem_init+0x5d8>
f0101601:	68 a9 53 10 f0       	push   $0xf01053a9
f0101606:	68 cf 52 10 f0       	push   $0xf01052cf
f010160b:	68 72 03 00 00       	push   $0x372
f0101610:	68 a9 52 10 f0       	push   $0xf01052a9
f0101615:	e8 86 ea ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f010161a:	83 ec 0c             	sub    $0xc,%esp
f010161d:	6a 00                	push   $0x0
f010161f:	e8 3b f7 ff ff       	call   f0100d5f <page_alloc>
f0101624:	89 c6                	mov    %eax,%esi
f0101626:	83 c4 10             	add    $0x10,%esp
f0101629:	85 c0                	test   %eax,%eax
f010162b:	75 19                	jne    f0101646 <mem_init+0x604>
f010162d:	68 bf 53 10 f0       	push   $0xf01053bf
f0101632:	68 cf 52 10 f0       	push   $0xf01052cf
f0101637:	68 73 03 00 00       	push   $0x373
f010163c:	68 a9 52 10 f0       	push   $0xf01052a9
f0101641:	e8 5a ea ff ff       	call   f01000a0 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101646:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101649:	75 19                	jne    f0101664 <mem_init+0x622>
f010164b:	68 d5 53 10 f0       	push   $0xf01053d5
f0101650:	68 cf 52 10 f0       	push   $0xf01052cf
f0101655:	68 76 03 00 00       	push   $0x376
f010165a:	68 a9 52 10 f0       	push   $0xf01052a9
f010165f:	e8 3c ea ff ff       	call   f01000a0 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101664:	39 c3                	cmp    %eax,%ebx
f0101666:	74 05                	je     f010166d <mem_init+0x62b>
f0101668:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010166b:	75 19                	jne    f0101686 <mem_init+0x644>
f010166d:	68 8c 4c 10 f0       	push   $0xf0104c8c
f0101672:	68 cf 52 10 f0       	push   $0xf01052cf
f0101677:	68 77 03 00 00       	push   $0x377
f010167c:	68 a9 52 10 f0       	push   $0xf01052a9
f0101681:	e8 1a ea ff ff       	call   f01000a0 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101686:	a1 7c 3f 17 f0       	mov    0xf0173f7c,%eax
f010168b:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010168e:	c7 05 7c 3f 17 f0 00 	movl   $0x0,0xf0173f7c
f0101695:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101698:	83 ec 0c             	sub    $0xc,%esp
f010169b:	6a 00                	push   $0x0
f010169d:	e8 bd f6 ff ff       	call   f0100d5f <page_alloc>
f01016a2:	83 c4 10             	add    $0x10,%esp
f01016a5:	85 c0                	test   %eax,%eax
f01016a7:	74 19                	je     f01016c2 <mem_init+0x680>
f01016a9:	68 3e 54 10 f0       	push   $0xf010543e
f01016ae:	68 cf 52 10 f0       	push   $0xf01052cf
f01016b3:	68 7e 03 00 00       	push   $0x37e
f01016b8:	68 a9 52 10 f0       	push   $0xf01052a9
f01016bd:	e8 de e9 ff ff       	call   f01000a0 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01016c2:	83 ec 04             	sub    $0x4,%esp
f01016c5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016c8:	50                   	push   %eax
f01016c9:	6a 00                	push   $0x0
f01016cb:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f01016d1:	e8 71 f8 ff ff       	call   f0100f47 <page_lookup>
f01016d6:	83 c4 10             	add    $0x10,%esp
f01016d9:	85 c0                	test   %eax,%eax
f01016db:	74 19                	je     f01016f6 <mem_init+0x6b4>
f01016dd:	68 cc 4c 10 f0       	push   $0xf0104ccc
f01016e2:	68 cf 52 10 f0       	push   $0xf01052cf
f01016e7:	68 81 03 00 00       	push   $0x381
f01016ec:	68 a9 52 10 f0       	push   $0xf01052a9
f01016f1:	e8 aa e9 ff ff       	call   f01000a0 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016f6:	6a 02                	push   $0x2
f01016f8:	6a 00                	push   $0x0
f01016fa:	53                   	push   %ebx
f01016fb:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f0101701:	e8 d6 f8 ff ff       	call   f0100fdc <page_insert>
f0101706:	83 c4 10             	add    $0x10,%esp
f0101709:	85 c0                	test   %eax,%eax
f010170b:	78 19                	js     f0101726 <mem_init+0x6e4>
f010170d:	68 04 4d 10 f0       	push   $0xf0104d04
f0101712:	68 cf 52 10 f0       	push   $0xf01052cf
f0101717:	68 84 03 00 00       	push   $0x384
f010171c:	68 a9 52 10 f0       	push   $0xf01052a9
f0101721:	e8 7a e9 ff ff       	call   f01000a0 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101726:	83 ec 0c             	sub    $0xc,%esp
f0101729:	ff 75 d4             	pushl  -0x2c(%ebp)
f010172c:	e8 b4 f6 ff ff       	call   f0100de5 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101731:	6a 02                	push   $0x2
f0101733:	6a 00                	push   $0x0
f0101735:	53                   	push   %ebx
f0101736:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f010173c:	e8 9b f8 ff ff       	call   f0100fdc <page_insert>
f0101741:	83 c4 20             	add    $0x20,%esp
f0101744:	85 c0                	test   %eax,%eax
f0101746:	74 19                	je     f0101761 <mem_init+0x71f>
f0101748:	68 34 4d 10 f0       	push   $0xf0104d34
f010174d:	68 cf 52 10 f0       	push   $0xf01052cf
f0101752:	68 88 03 00 00       	push   $0x388
f0101757:	68 a9 52 10 f0       	push   $0xf01052a9
f010175c:	e8 3f e9 ff ff       	call   f01000a0 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101761:	8b 3d 48 4c 17 f0    	mov    0xf0174c48,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101767:	a1 4c 4c 17 f0       	mov    0xf0174c4c,%eax
f010176c:	89 c1                	mov    %eax,%ecx
f010176e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101771:	8b 17                	mov    (%edi),%edx
f0101773:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101779:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010177c:	29 c8                	sub    %ecx,%eax
f010177e:	c1 f8 03             	sar    $0x3,%eax
f0101781:	c1 e0 0c             	shl    $0xc,%eax
f0101784:	39 c2                	cmp    %eax,%edx
f0101786:	74 19                	je     f01017a1 <mem_init+0x75f>
f0101788:	68 64 4d 10 f0       	push   $0xf0104d64
f010178d:	68 cf 52 10 f0       	push   $0xf01052cf
f0101792:	68 89 03 00 00       	push   $0x389
f0101797:	68 a9 52 10 f0       	push   $0xf01052a9
f010179c:	e8 ff e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01017a1:	ba 00 00 00 00       	mov    $0x0,%edx
f01017a6:	89 f8                	mov    %edi,%eax
f01017a8:	e8 ba f1 ff ff       	call   f0100967 <check_va2pa>
f01017ad:	89 da                	mov    %ebx,%edx
f01017af:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01017b2:	c1 fa 03             	sar    $0x3,%edx
f01017b5:	c1 e2 0c             	shl    $0xc,%edx
f01017b8:	39 d0                	cmp    %edx,%eax
f01017ba:	74 19                	je     f01017d5 <mem_init+0x793>
f01017bc:	68 8c 4d 10 f0       	push   $0xf0104d8c
f01017c1:	68 cf 52 10 f0       	push   $0xf01052cf
f01017c6:	68 8a 03 00 00       	push   $0x38a
f01017cb:	68 a9 52 10 f0       	push   $0xf01052a9
f01017d0:	e8 cb e8 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f01017d5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01017da:	74 19                	je     f01017f5 <mem_init+0x7b3>
f01017dc:	68 90 54 10 f0       	push   $0xf0105490
f01017e1:	68 cf 52 10 f0       	push   $0xf01052cf
f01017e6:	68 8b 03 00 00       	push   $0x38b
f01017eb:	68 a9 52 10 f0       	push   $0xf01052a9
f01017f0:	e8 ab e8 ff ff       	call   f01000a0 <_panic>
	assert(pp0->pp_ref == 1);
f01017f5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017f8:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01017fd:	74 19                	je     f0101818 <mem_init+0x7d6>
f01017ff:	68 a1 54 10 f0       	push   $0xf01054a1
f0101804:	68 cf 52 10 f0       	push   $0xf01052cf
f0101809:	68 8c 03 00 00       	push   $0x38c
f010180e:	68 a9 52 10 f0       	push   $0xf01052a9
f0101813:	e8 88 e8 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101818:	6a 02                	push   $0x2
f010181a:	68 00 10 00 00       	push   $0x1000
f010181f:	56                   	push   %esi
f0101820:	57                   	push   %edi
f0101821:	e8 b6 f7 ff ff       	call   f0100fdc <page_insert>
f0101826:	83 c4 10             	add    $0x10,%esp
f0101829:	85 c0                	test   %eax,%eax
f010182b:	74 19                	je     f0101846 <mem_init+0x804>
f010182d:	68 bc 4d 10 f0       	push   $0xf0104dbc
f0101832:	68 cf 52 10 f0       	push   $0xf01052cf
f0101837:	68 8f 03 00 00       	push   $0x38f
f010183c:	68 a9 52 10 f0       	push   $0xf01052a9
f0101841:	e8 5a e8 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101846:	ba 00 10 00 00       	mov    $0x1000,%edx
f010184b:	a1 48 4c 17 f0       	mov    0xf0174c48,%eax
f0101850:	e8 12 f1 ff ff       	call   f0100967 <check_va2pa>
f0101855:	89 f2                	mov    %esi,%edx
f0101857:	2b 15 4c 4c 17 f0    	sub    0xf0174c4c,%edx
f010185d:	c1 fa 03             	sar    $0x3,%edx
f0101860:	c1 e2 0c             	shl    $0xc,%edx
f0101863:	39 d0                	cmp    %edx,%eax
f0101865:	74 19                	je     f0101880 <mem_init+0x83e>
f0101867:	68 f8 4d 10 f0       	push   $0xf0104df8
f010186c:	68 cf 52 10 f0       	push   $0xf01052cf
f0101871:	68 90 03 00 00       	push   $0x390
f0101876:	68 a9 52 10 f0       	push   $0xf01052a9
f010187b:	e8 20 e8 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101880:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101885:	74 19                	je     f01018a0 <mem_init+0x85e>
f0101887:	68 b2 54 10 f0       	push   $0xf01054b2
f010188c:	68 cf 52 10 f0       	push   $0xf01052cf
f0101891:	68 91 03 00 00       	push   $0x391
f0101896:	68 a9 52 10 f0       	push   $0xf01052a9
f010189b:	e8 00 e8 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01018a0:	83 ec 0c             	sub    $0xc,%esp
f01018a3:	6a 00                	push   $0x0
f01018a5:	e8 b5 f4 ff ff       	call   f0100d5f <page_alloc>
f01018aa:	83 c4 10             	add    $0x10,%esp
f01018ad:	85 c0                	test   %eax,%eax
f01018af:	74 19                	je     f01018ca <mem_init+0x888>
f01018b1:	68 3e 54 10 f0       	push   $0xf010543e
f01018b6:	68 cf 52 10 f0       	push   $0xf01052cf
f01018bb:	68 94 03 00 00       	push   $0x394
f01018c0:	68 a9 52 10 f0       	push   $0xf01052a9
f01018c5:	e8 d6 e7 ff ff       	call   f01000a0 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018ca:	6a 02                	push   $0x2
f01018cc:	68 00 10 00 00       	push   $0x1000
f01018d1:	56                   	push   %esi
f01018d2:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f01018d8:	e8 ff f6 ff ff       	call   f0100fdc <page_insert>
f01018dd:	83 c4 10             	add    $0x10,%esp
f01018e0:	85 c0                	test   %eax,%eax
f01018e2:	74 19                	je     f01018fd <mem_init+0x8bb>
f01018e4:	68 bc 4d 10 f0       	push   $0xf0104dbc
f01018e9:	68 cf 52 10 f0       	push   $0xf01052cf
f01018ee:	68 97 03 00 00       	push   $0x397
f01018f3:	68 a9 52 10 f0       	push   $0xf01052a9
f01018f8:	e8 a3 e7 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01018fd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101902:	a1 48 4c 17 f0       	mov    0xf0174c48,%eax
f0101907:	e8 5b f0 ff ff       	call   f0100967 <check_va2pa>
f010190c:	89 f2                	mov    %esi,%edx
f010190e:	2b 15 4c 4c 17 f0    	sub    0xf0174c4c,%edx
f0101914:	c1 fa 03             	sar    $0x3,%edx
f0101917:	c1 e2 0c             	shl    $0xc,%edx
f010191a:	39 d0                	cmp    %edx,%eax
f010191c:	74 19                	je     f0101937 <mem_init+0x8f5>
f010191e:	68 f8 4d 10 f0       	push   $0xf0104df8
f0101923:	68 cf 52 10 f0       	push   $0xf01052cf
f0101928:	68 98 03 00 00       	push   $0x398
f010192d:	68 a9 52 10 f0       	push   $0xf01052a9
f0101932:	e8 69 e7 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101937:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010193c:	74 19                	je     f0101957 <mem_init+0x915>
f010193e:	68 b2 54 10 f0       	push   $0xf01054b2
f0101943:	68 cf 52 10 f0       	push   $0xf01052cf
f0101948:	68 99 03 00 00       	push   $0x399
f010194d:	68 a9 52 10 f0       	push   $0xf01052a9
f0101952:	e8 49 e7 ff ff       	call   f01000a0 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101957:	83 ec 0c             	sub    $0xc,%esp
f010195a:	6a 00                	push   $0x0
f010195c:	e8 fe f3 ff ff       	call   f0100d5f <page_alloc>
f0101961:	83 c4 10             	add    $0x10,%esp
f0101964:	85 c0                	test   %eax,%eax
f0101966:	74 19                	je     f0101981 <mem_init+0x93f>
f0101968:	68 3e 54 10 f0       	push   $0xf010543e
f010196d:	68 cf 52 10 f0       	push   $0xf01052cf
f0101972:	68 9d 03 00 00       	push   $0x39d
f0101977:	68 a9 52 10 f0       	push   $0xf01052a9
f010197c:	e8 1f e7 ff ff       	call   f01000a0 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101981:	8b 15 48 4c 17 f0    	mov    0xf0174c48,%edx
f0101987:	8b 02                	mov    (%edx),%eax
f0101989:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010198e:	89 c1                	mov    %eax,%ecx
f0101990:	c1 e9 0c             	shr    $0xc,%ecx
f0101993:	3b 0d 44 4c 17 f0    	cmp    0xf0174c44,%ecx
f0101999:	72 15                	jb     f01019b0 <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010199b:	50                   	push   %eax
f010199c:	68 24 4b 10 f0       	push   $0xf0104b24
f01019a1:	68 a0 03 00 00       	push   $0x3a0
f01019a6:	68 a9 52 10 f0       	push   $0xf01052a9
f01019ab:	e8 f0 e6 ff ff       	call   f01000a0 <_panic>
f01019b0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01019b5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01019b8:	83 ec 04             	sub    $0x4,%esp
f01019bb:	6a 00                	push   $0x0
f01019bd:	68 00 10 00 00       	push   $0x1000
f01019c2:	52                   	push   %edx
f01019c3:	e8 69 f4 ff ff       	call   f0100e31 <pgdir_walk>
f01019c8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01019cb:	8d 57 04             	lea    0x4(%edi),%edx
f01019ce:	83 c4 10             	add    $0x10,%esp
f01019d1:	39 d0                	cmp    %edx,%eax
f01019d3:	74 19                	je     f01019ee <mem_init+0x9ac>
f01019d5:	68 28 4e 10 f0       	push   $0xf0104e28
f01019da:	68 cf 52 10 f0       	push   $0xf01052cf
f01019df:	68 a1 03 00 00       	push   $0x3a1
f01019e4:	68 a9 52 10 f0       	push   $0xf01052a9
f01019e9:	e8 b2 e6 ff ff       	call   f01000a0 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01019ee:	6a 06                	push   $0x6
f01019f0:	68 00 10 00 00       	push   $0x1000
f01019f5:	56                   	push   %esi
f01019f6:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f01019fc:	e8 db f5 ff ff       	call   f0100fdc <page_insert>
f0101a01:	83 c4 10             	add    $0x10,%esp
f0101a04:	85 c0                	test   %eax,%eax
f0101a06:	74 19                	je     f0101a21 <mem_init+0x9df>
f0101a08:	68 68 4e 10 f0       	push   $0xf0104e68
f0101a0d:	68 cf 52 10 f0       	push   $0xf01052cf
f0101a12:	68 a4 03 00 00       	push   $0x3a4
f0101a17:	68 a9 52 10 f0       	push   $0xf01052a9
f0101a1c:	e8 7f e6 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a21:	8b 3d 48 4c 17 f0    	mov    0xf0174c48,%edi
f0101a27:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a2c:	89 f8                	mov    %edi,%eax
f0101a2e:	e8 34 ef ff ff       	call   f0100967 <check_va2pa>
f0101a33:	89 f2                	mov    %esi,%edx
f0101a35:	2b 15 4c 4c 17 f0    	sub    0xf0174c4c,%edx
f0101a3b:	c1 fa 03             	sar    $0x3,%edx
f0101a3e:	c1 e2 0c             	shl    $0xc,%edx
f0101a41:	39 d0                	cmp    %edx,%eax
f0101a43:	74 19                	je     f0101a5e <mem_init+0xa1c>
f0101a45:	68 f8 4d 10 f0       	push   $0xf0104df8
f0101a4a:	68 cf 52 10 f0       	push   $0xf01052cf
f0101a4f:	68 a5 03 00 00       	push   $0x3a5
f0101a54:	68 a9 52 10 f0       	push   $0xf01052a9
f0101a59:	e8 42 e6 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f0101a5e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a63:	74 19                	je     f0101a7e <mem_init+0xa3c>
f0101a65:	68 b2 54 10 f0       	push   $0xf01054b2
f0101a6a:	68 cf 52 10 f0       	push   $0xf01052cf
f0101a6f:	68 a6 03 00 00       	push   $0x3a6
f0101a74:	68 a9 52 10 f0       	push   $0xf01052a9
f0101a79:	e8 22 e6 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101a7e:	83 ec 04             	sub    $0x4,%esp
f0101a81:	6a 00                	push   $0x0
f0101a83:	68 00 10 00 00       	push   $0x1000
f0101a88:	57                   	push   %edi
f0101a89:	e8 a3 f3 ff ff       	call   f0100e31 <pgdir_walk>
f0101a8e:	83 c4 10             	add    $0x10,%esp
f0101a91:	f6 00 04             	testb  $0x4,(%eax)
f0101a94:	75 19                	jne    f0101aaf <mem_init+0xa6d>
f0101a96:	68 a8 4e 10 f0       	push   $0xf0104ea8
f0101a9b:	68 cf 52 10 f0       	push   $0xf01052cf
f0101aa0:	68 a7 03 00 00       	push   $0x3a7
f0101aa5:	68 a9 52 10 f0       	push   $0xf01052a9
f0101aaa:	e8 f1 e5 ff ff       	call   f01000a0 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101aaf:	a1 48 4c 17 f0       	mov    0xf0174c48,%eax
f0101ab4:	f6 00 04             	testb  $0x4,(%eax)
f0101ab7:	75 19                	jne    f0101ad2 <mem_init+0xa90>
f0101ab9:	68 c3 54 10 f0       	push   $0xf01054c3
f0101abe:	68 cf 52 10 f0       	push   $0xf01052cf
f0101ac3:	68 a8 03 00 00       	push   $0x3a8
f0101ac8:	68 a9 52 10 f0       	push   $0xf01052a9
f0101acd:	e8 ce e5 ff ff       	call   f01000a0 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ad2:	6a 02                	push   $0x2
f0101ad4:	68 00 10 00 00       	push   $0x1000
f0101ad9:	56                   	push   %esi
f0101ada:	50                   	push   %eax
f0101adb:	e8 fc f4 ff ff       	call   f0100fdc <page_insert>
f0101ae0:	83 c4 10             	add    $0x10,%esp
f0101ae3:	85 c0                	test   %eax,%eax
f0101ae5:	74 19                	je     f0101b00 <mem_init+0xabe>
f0101ae7:	68 bc 4d 10 f0       	push   $0xf0104dbc
f0101aec:	68 cf 52 10 f0       	push   $0xf01052cf
f0101af1:	68 ab 03 00 00       	push   $0x3ab
f0101af6:	68 a9 52 10 f0       	push   $0xf01052a9
f0101afb:	e8 a0 e5 ff ff       	call   f01000a0 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101b00:	83 ec 04             	sub    $0x4,%esp
f0101b03:	6a 00                	push   $0x0
f0101b05:	68 00 10 00 00       	push   $0x1000
f0101b0a:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f0101b10:	e8 1c f3 ff ff       	call   f0100e31 <pgdir_walk>
f0101b15:	83 c4 10             	add    $0x10,%esp
f0101b18:	f6 00 02             	testb  $0x2,(%eax)
f0101b1b:	75 19                	jne    f0101b36 <mem_init+0xaf4>
f0101b1d:	68 dc 4e 10 f0       	push   $0xf0104edc
f0101b22:	68 cf 52 10 f0       	push   $0xf01052cf
f0101b27:	68 ac 03 00 00       	push   $0x3ac
f0101b2c:	68 a9 52 10 f0       	push   $0xf01052a9
f0101b31:	e8 6a e5 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b36:	83 ec 04             	sub    $0x4,%esp
f0101b39:	6a 00                	push   $0x0
f0101b3b:	68 00 10 00 00       	push   $0x1000
f0101b40:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f0101b46:	e8 e6 f2 ff ff       	call   f0100e31 <pgdir_walk>
f0101b4b:	83 c4 10             	add    $0x10,%esp
f0101b4e:	f6 00 04             	testb  $0x4,(%eax)
f0101b51:	74 19                	je     f0101b6c <mem_init+0xb2a>
f0101b53:	68 10 4f 10 f0       	push   $0xf0104f10
f0101b58:	68 cf 52 10 f0       	push   $0xf01052cf
f0101b5d:	68 ad 03 00 00       	push   $0x3ad
f0101b62:	68 a9 52 10 f0       	push   $0xf01052a9
f0101b67:	e8 34 e5 ff ff       	call   f01000a0 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101b6c:	6a 02                	push   $0x2
f0101b6e:	68 00 00 40 00       	push   $0x400000
f0101b73:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b76:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f0101b7c:	e8 5b f4 ff ff       	call   f0100fdc <page_insert>
f0101b81:	83 c4 10             	add    $0x10,%esp
f0101b84:	85 c0                	test   %eax,%eax
f0101b86:	78 19                	js     f0101ba1 <mem_init+0xb5f>
f0101b88:	68 48 4f 10 f0       	push   $0xf0104f48
f0101b8d:	68 cf 52 10 f0       	push   $0xf01052cf
f0101b92:	68 b0 03 00 00       	push   $0x3b0
f0101b97:	68 a9 52 10 f0       	push   $0xf01052a9
f0101b9c:	e8 ff e4 ff ff       	call   f01000a0 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101ba1:	6a 02                	push   $0x2
f0101ba3:	68 00 10 00 00       	push   $0x1000
f0101ba8:	53                   	push   %ebx
f0101ba9:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f0101baf:	e8 28 f4 ff ff       	call   f0100fdc <page_insert>
f0101bb4:	83 c4 10             	add    $0x10,%esp
f0101bb7:	85 c0                	test   %eax,%eax
f0101bb9:	74 19                	je     f0101bd4 <mem_init+0xb92>
f0101bbb:	68 80 4f 10 f0       	push   $0xf0104f80
f0101bc0:	68 cf 52 10 f0       	push   $0xf01052cf
f0101bc5:	68 b3 03 00 00       	push   $0x3b3
f0101bca:	68 a9 52 10 f0       	push   $0xf01052a9
f0101bcf:	e8 cc e4 ff ff       	call   f01000a0 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bd4:	83 ec 04             	sub    $0x4,%esp
f0101bd7:	6a 00                	push   $0x0
f0101bd9:	68 00 10 00 00       	push   $0x1000
f0101bde:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f0101be4:	e8 48 f2 ff ff       	call   f0100e31 <pgdir_walk>
f0101be9:	83 c4 10             	add    $0x10,%esp
f0101bec:	f6 00 04             	testb  $0x4,(%eax)
f0101bef:	74 19                	je     f0101c0a <mem_init+0xbc8>
f0101bf1:	68 10 4f 10 f0       	push   $0xf0104f10
f0101bf6:	68 cf 52 10 f0       	push   $0xf01052cf
f0101bfb:	68 b4 03 00 00       	push   $0x3b4
f0101c00:	68 a9 52 10 f0       	push   $0xf01052a9
f0101c05:	e8 96 e4 ff ff       	call   f01000a0 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c0a:	8b 3d 48 4c 17 f0    	mov    0xf0174c48,%edi
f0101c10:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c15:	89 f8                	mov    %edi,%eax
f0101c17:	e8 4b ed ff ff       	call   f0100967 <check_va2pa>
f0101c1c:	89 c1                	mov    %eax,%ecx
f0101c1e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c21:	89 d8                	mov    %ebx,%eax
f0101c23:	2b 05 4c 4c 17 f0    	sub    0xf0174c4c,%eax
f0101c29:	c1 f8 03             	sar    $0x3,%eax
f0101c2c:	c1 e0 0c             	shl    $0xc,%eax
f0101c2f:	39 c1                	cmp    %eax,%ecx
f0101c31:	74 19                	je     f0101c4c <mem_init+0xc0a>
f0101c33:	68 bc 4f 10 f0       	push   $0xf0104fbc
f0101c38:	68 cf 52 10 f0       	push   $0xf01052cf
f0101c3d:	68 b7 03 00 00       	push   $0x3b7
f0101c42:	68 a9 52 10 f0       	push   $0xf01052a9
f0101c47:	e8 54 e4 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c4c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c51:	89 f8                	mov    %edi,%eax
f0101c53:	e8 0f ed ff ff       	call   f0100967 <check_va2pa>
f0101c58:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c5b:	74 19                	je     f0101c76 <mem_init+0xc34>
f0101c5d:	68 e8 4f 10 f0       	push   $0xf0104fe8
f0101c62:	68 cf 52 10 f0       	push   $0xf01052cf
f0101c67:	68 b8 03 00 00       	push   $0x3b8
f0101c6c:	68 a9 52 10 f0       	push   $0xf01052a9
f0101c71:	e8 2a e4 ff ff       	call   f01000a0 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101c76:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101c7b:	74 19                	je     f0101c96 <mem_init+0xc54>
f0101c7d:	68 d9 54 10 f0       	push   $0xf01054d9
f0101c82:	68 cf 52 10 f0       	push   $0xf01052cf
f0101c87:	68 ba 03 00 00       	push   $0x3ba
f0101c8c:	68 a9 52 10 f0       	push   $0xf01052a9
f0101c91:	e8 0a e4 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101c96:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c9b:	74 19                	je     f0101cb6 <mem_init+0xc74>
f0101c9d:	68 ea 54 10 f0       	push   $0xf01054ea
f0101ca2:	68 cf 52 10 f0       	push   $0xf01052cf
f0101ca7:	68 bb 03 00 00       	push   $0x3bb
f0101cac:	68 a9 52 10 f0       	push   $0xf01052a9
f0101cb1:	e8 ea e3 ff ff       	call   f01000a0 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101cb6:	83 ec 0c             	sub    $0xc,%esp
f0101cb9:	6a 00                	push   $0x0
f0101cbb:	e8 9f f0 ff ff       	call   f0100d5f <page_alloc>
f0101cc0:	83 c4 10             	add    $0x10,%esp
f0101cc3:	85 c0                	test   %eax,%eax
f0101cc5:	74 04                	je     f0101ccb <mem_init+0xc89>
f0101cc7:	39 c6                	cmp    %eax,%esi
f0101cc9:	74 19                	je     f0101ce4 <mem_init+0xca2>
f0101ccb:	68 18 50 10 f0       	push   $0xf0105018
f0101cd0:	68 cf 52 10 f0       	push   $0xf01052cf
f0101cd5:	68 be 03 00 00       	push   $0x3be
f0101cda:	68 a9 52 10 f0       	push   $0xf01052a9
f0101cdf:	e8 bc e3 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ce4:	83 ec 08             	sub    $0x8,%esp
f0101ce7:	6a 00                	push   $0x0
f0101ce9:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f0101cef:	e8 ad f2 ff ff       	call   f0100fa1 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cf4:	8b 3d 48 4c 17 f0    	mov    0xf0174c48,%edi
f0101cfa:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cff:	89 f8                	mov    %edi,%eax
f0101d01:	e8 61 ec ff ff       	call   f0100967 <check_va2pa>
f0101d06:	83 c4 10             	add    $0x10,%esp
f0101d09:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d0c:	74 19                	je     f0101d27 <mem_init+0xce5>
f0101d0e:	68 3c 50 10 f0       	push   $0xf010503c
f0101d13:	68 cf 52 10 f0       	push   $0xf01052cf
f0101d18:	68 c2 03 00 00       	push   $0x3c2
f0101d1d:	68 a9 52 10 f0       	push   $0xf01052a9
f0101d22:	e8 79 e3 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d27:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d2c:	89 f8                	mov    %edi,%eax
f0101d2e:	e8 34 ec ff ff       	call   f0100967 <check_va2pa>
f0101d33:	89 da                	mov    %ebx,%edx
f0101d35:	2b 15 4c 4c 17 f0    	sub    0xf0174c4c,%edx
f0101d3b:	c1 fa 03             	sar    $0x3,%edx
f0101d3e:	c1 e2 0c             	shl    $0xc,%edx
f0101d41:	39 d0                	cmp    %edx,%eax
f0101d43:	74 19                	je     f0101d5e <mem_init+0xd1c>
f0101d45:	68 e8 4f 10 f0       	push   $0xf0104fe8
f0101d4a:	68 cf 52 10 f0       	push   $0xf01052cf
f0101d4f:	68 c3 03 00 00       	push   $0x3c3
f0101d54:	68 a9 52 10 f0       	push   $0xf01052a9
f0101d59:	e8 42 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 1);
f0101d5e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d63:	74 19                	je     f0101d7e <mem_init+0xd3c>
f0101d65:	68 90 54 10 f0       	push   $0xf0105490
f0101d6a:	68 cf 52 10 f0       	push   $0xf01052cf
f0101d6f:	68 c4 03 00 00       	push   $0x3c4
f0101d74:	68 a9 52 10 f0       	push   $0xf01052a9
f0101d79:	e8 22 e3 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101d7e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d83:	74 19                	je     f0101d9e <mem_init+0xd5c>
f0101d85:	68 ea 54 10 f0       	push   $0xf01054ea
f0101d8a:	68 cf 52 10 f0       	push   $0xf01052cf
f0101d8f:	68 c5 03 00 00       	push   $0x3c5
f0101d94:	68 a9 52 10 f0       	push   $0xf01052a9
f0101d99:	e8 02 e3 ff ff       	call   f01000a0 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d9e:	6a 00                	push   $0x0
f0101da0:	68 00 10 00 00       	push   $0x1000
f0101da5:	53                   	push   %ebx
f0101da6:	57                   	push   %edi
f0101da7:	e8 30 f2 ff ff       	call   f0100fdc <page_insert>
f0101dac:	83 c4 10             	add    $0x10,%esp
f0101daf:	85 c0                	test   %eax,%eax
f0101db1:	74 19                	je     f0101dcc <mem_init+0xd8a>
f0101db3:	68 60 50 10 f0       	push   $0xf0105060
f0101db8:	68 cf 52 10 f0       	push   $0xf01052cf
f0101dbd:	68 c8 03 00 00       	push   $0x3c8
f0101dc2:	68 a9 52 10 f0       	push   $0xf01052a9
f0101dc7:	e8 d4 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref);
f0101dcc:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101dd1:	75 19                	jne    f0101dec <mem_init+0xdaa>
f0101dd3:	68 fb 54 10 f0       	push   $0xf01054fb
f0101dd8:	68 cf 52 10 f0       	push   $0xf01052cf
f0101ddd:	68 c9 03 00 00       	push   $0x3c9
f0101de2:	68 a9 52 10 f0       	push   $0xf01052a9
f0101de7:	e8 b4 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_link == NULL);
f0101dec:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101def:	74 19                	je     f0101e0a <mem_init+0xdc8>
f0101df1:	68 07 55 10 f0       	push   $0xf0105507
f0101df6:	68 cf 52 10 f0       	push   $0xf01052cf
f0101dfb:	68 ca 03 00 00       	push   $0x3ca
f0101e00:	68 a9 52 10 f0       	push   $0xf01052a9
f0101e05:	e8 96 e2 ff ff       	call   f01000a0 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e0a:	83 ec 08             	sub    $0x8,%esp
f0101e0d:	68 00 10 00 00       	push   $0x1000
f0101e12:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f0101e18:	e8 84 f1 ff ff       	call   f0100fa1 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e1d:	8b 3d 48 4c 17 f0    	mov    0xf0174c48,%edi
f0101e23:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e28:	89 f8                	mov    %edi,%eax
f0101e2a:	e8 38 eb ff ff       	call   f0100967 <check_va2pa>
f0101e2f:	83 c4 10             	add    $0x10,%esp
f0101e32:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e35:	74 19                	je     f0101e50 <mem_init+0xe0e>
f0101e37:	68 3c 50 10 f0       	push   $0xf010503c
f0101e3c:	68 cf 52 10 f0       	push   $0xf01052cf
f0101e41:	68 ce 03 00 00       	push   $0x3ce
f0101e46:	68 a9 52 10 f0       	push   $0xf01052a9
f0101e4b:	e8 50 e2 ff ff       	call   f01000a0 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e50:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e55:	89 f8                	mov    %edi,%eax
f0101e57:	e8 0b eb ff ff       	call   f0100967 <check_va2pa>
f0101e5c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e5f:	74 19                	je     f0101e7a <mem_init+0xe38>
f0101e61:	68 98 50 10 f0       	push   $0xf0105098
f0101e66:	68 cf 52 10 f0       	push   $0xf01052cf
f0101e6b:	68 cf 03 00 00       	push   $0x3cf
f0101e70:	68 a9 52 10 f0       	push   $0xf01052a9
f0101e75:	e8 26 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f0101e7a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e7f:	74 19                	je     f0101e9a <mem_init+0xe58>
f0101e81:	68 1c 55 10 f0       	push   $0xf010551c
f0101e86:	68 cf 52 10 f0       	push   $0xf01052cf
f0101e8b:	68 d0 03 00 00       	push   $0x3d0
f0101e90:	68 a9 52 10 f0       	push   $0xf01052a9
f0101e95:	e8 06 e2 ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 0);
f0101e9a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e9f:	74 19                	je     f0101eba <mem_init+0xe78>
f0101ea1:	68 ea 54 10 f0       	push   $0xf01054ea
f0101ea6:	68 cf 52 10 f0       	push   $0xf01052cf
f0101eab:	68 d1 03 00 00       	push   $0x3d1
f0101eb0:	68 a9 52 10 f0       	push   $0xf01052a9
f0101eb5:	e8 e6 e1 ff ff       	call   f01000a0 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101eba:	83 ec 0c             	sub    $0xc,%esp
f0101ebd:	6a 00                	push   $0x0
f0101ebf:	e8 9b ee ff ff       	call   f0100d5f <page_alloc>
f0101ec4:	83 c4 10             	add    $0x10,%esp
f0101ec7:	39 c3                	cmp    %eax,%ebx
f0101ec9:	75 04                	jne    f0101ecf <mem_init+0xe8d>
f0101ecb:	85 c0                	test   %eax,%eax
f0101ecd:	75 19                	jne    f0101ee8 <mem_init+0xea6>
f0101ecf:	68 c0 50 10 f0       	push   $0xf01050c0
f0101ed4:	68 cf 52 10 f0       	push   $0xf01052cf
f0101ed9:	68 d4 03 00 00       	push   $0x3d4
f0101ede:	68 a9 52 10 f0       	push   $0xf01052a9
f0101ee3:	e8 b8 e1 ff ff       	call   f01000a0 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ee8:	83 ec 0c             	sub    $0xc,%esp
f0101eeb:	6a 00                	push   $0x0
f0101eed:	e8 6d ee ff ff       	call   f0100d5f <page_alloc>
f0101ef2:	83 c4 10             	add    $0x10,%esp
f0101ef5:	85 c0                	test   %eax,%eax
f0101ef7:	74 19                	je     f0101f12 <mem_init+0xed0>
f0101ef9:	68 3e 54 10 f0       	push   $0xf010543e
f0101efe:	68 cf 52 10 f0       	push   $0xf01052cf
f0101f03:	68 d7 03 00 00       	push   $0x3d7
f0101f08:	68 a9 52 10 f0       	push   $0xf01052a9
f0101f0d:	e8 8e e1 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101f12:	8b 0d 48 4c 17 f0    	mov    0xf0174c48,%ecx
f0101f18:	8b 11                	mov    (%ecx),%edx
f0101f1a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f20:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f23:	2b 05 4c 4c 17 f0    	sub    0xf0174c4c,%eax
f0101f29:	c1 f8 03             	sar    $0x3,%eax
f0101f2c:	c1 e0 0c             	shl    $0xc,%eax
f0101f2f:	39 c2                	cmp    %eax,%edx
f0101f31:	74 19                	je     f0101f4c <mem_init+0xf0a>
f0101f33:	68 64 4d 10 f0       	push   $0xf0104d64
f0101f38:	68 cf 52 10 f0       	push   $0xf01052cf
f0101f3d:	68 da 03 00 00       	push   $0x3da
f0101f42:	68 a9 52 10 f0       	push   $0xf01052a9
f0101f47:	e8 54 e1 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0101f4c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f52:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f55:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f5a:	74 19                	je     f0101f75 <mem_init+0xf33>
f0101f5c:	68 a1 54 10 f0       	push   $0xf01054a1
f0101f61:	68 cf 52 10 f0       	push   $0xf01052cf
f0101f66:	68 dc 03 00 00       	push   $0x3dc
f0101f6b:	68 a9 52 10 f0       	push   $0xf01052a9
f0101f70:	e8 2b e1 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f0101f75:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f78:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f7e:	83 ec 0c             	sub    $0xc,%esp
f0101f81:	50                   	push   %eax
f0101f82:	e8 5e ee ff ff       	call   f0100de5 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f87:	83 c4 0c             	add    $0xc,%esp
f0101f8a:	6a 01                	push   $0x1
f0101f8c:	68 00 10 40 00       	push   $0x401000
f0101f91:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f0101f97:	e8 95 ee ff ff       	call   f0100e31 <pgdir_walk>
f0101f9c:	89 c7                	mov    %eax,%edi
f0101f9e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101fa1:	a1 48 4c 17 f0       	mov    0xf0174c48,%eax
f0101fa6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fa9:	8b 40 04             	mov    0x4(%eax),%eax
f0101fac:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fb1:	8b 0d 44 4c 17 f0    	mov    0xf0174c44,%ecx
f0101fb7:	89 c2                	mov    %eax,%edx
f0101fb9:	c1 ea 0c             	shr    $0xc,%edx
f0101fbc:	83 c4 10             	add    $0x10,%esp
f0101fbf:	39 ca                	cmp    %ecx,%edx
f0101fc1:	72 15                	jb     f0101fd8 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fc3:	50                   	push   %eax
f0101fc4:	68 24 4b 10 f0       	push   $0xf0104b24
f0101fc9:	68 e3 03 00 00       	push   $0x3e3
f0101fce:	68 a9 52 10 f0       	push   $0xf01052a9
f0101fd3:	e8 c8 e0 ff ff       	call   f01000a0 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101fd8:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101fdd:	39 c7                	cmp    %eax,%edi
f0101fdf:	74 19                	je     f0101ffa <mem_init+0xfb8>
f0101fe1:	68 2d 55 10 f0       	push   $0xf010552d
f0101fe6:	68 cf 52 10 f0       	push   $0xf01052cf
f0101feb:	68 e4 03 00 00       	push   $0x3e4
f0101ff0:	68 a9 52 10 f0       	push   $0xf01052a9
f0101ff5:	e8 a6 e0 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101ffa:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ffd:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0102004:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102007:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010200d:	2b 05 4c 4c 17 f0    	sub    0xf0174c4c,%eax
f0102013:	c1 f8 03             	sar    $0x3,%eax
f0102016:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102019:	89 c2                	mov    %eax,%edx
f010201b:	c1 ea 0c             	shr    $0xc,%edx
f010201e:	39 d1                	cmp    %edx,%ecx
f0102020:	77 12                	ja     f0102034 <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102022:	50                   	push   %eax
f0102023:	68 24 4b 10 f0       	push   $0xf0104b24
f0102028:	6a 56                	push   $0x56
f010202a:	68 b5 52 10 f0       	push   $0xf01052b5
f010202f:	e8 6c e0 ff ff       	call   f01000a0 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102034:	83 ec 04             	sub    $0x4,%esp
f0102037:	68 00 10 00 00       	push   $0x1000
f010203c:	68 ff 00 00 00       	push   $0xff
f0102041:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102046:	50                   	push   %eax
f0102047:	e8 f4 20 00 00       	call   f0104140 <memset>
	page_free(pp0);
f010204c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010204f:	89 3c 24             	mov    %edi,(%esp)
f0102052:	e8 8e ed ff ff       	call   f0100de5 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102057:	83 c4 0c             	add    $0xc,%esp
f010205a:	6a 01                	push   $0x1
f010205c:	6a 00                	push   $0x0
f010205e:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f0102064:	e8 c8 ed ff ff       	call   f0100e31 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102069:	89 fa                	mov    %edi,%edx
f010206b:	2b 15 4c 4c 17 f0    	sub    0xf0174c4c,%edx
f0102071:	c1 fa 03             	sar    $0x3,%edx
f0102074:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102077:	89 d0                	mov    %edx,%eax
f0102079:	c1 e8 0c             	shr    $0xc,%eax
f010207c:	83 c4 10             	add    $0x10,%esp
f010207f:	3b 05 44 4c 17 f0    	cmp    0xf0174c44,%eax
f0102085:	72 12                	jb     f0102099 <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102087:	52                   	push   %edx
f0102088:	68 24 4b 10 f0       	push   $0xf0104b24
f010208d:	6a 56                	push   $0x56
f010208f:	68 b5 52 10 f0       	push   $0xf01052b5
f0102094:	e8 07 e0 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f0102099:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010209f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020a2:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01020a8:	f6 00 01             	testb  $0x1,(%eax)
f01020ab:	74 19                	je     f01020c6 <mem_init+0x1084>
f01020ad:	68 45 55 10 f0       	push   $0xf0105545
f01020b2:	68 cf 52 10 f0       	push   $0xf01052cf
f01020b7:	68 ee 03 00 00       	push   $0x3ee
f01020bc:	68 a9 52 10 f0       	push   $0xf01052a9
f01020c1:	e8 da df ff ff       	call   f01000a0 <_panic>
f01020c6:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01020c9:	39 c2                	cmp    %eax,%edx
f01020cb:	75 db                	jne    f01020a8 <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01020cd:	a1 48 4c 17 f0       	mov    0xf0174c48,%eax
f01020d2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01020d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020db:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01020e1:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01020e4:	89 3d 7c 3f 17 f0    	mov    %edi,0xf0173f7c

	// free the pages we took
	page_free(pp0);
f01020ea:	83 ec 0c             	sub    $0xc,%esp
f01020ed:	50                   	push   %eax
f01020ee:	e8 f2 ec ff ff       	call   f0100de5 <page_free>
	page_free(pp1);
f01020f3:	89 1c 24             	mov    %ebx,(%esp)
f01020f6:	e8 ea ec ff ff       	call   f0100de5 <page_free>
	page_free(pp2);
f01020fb:	89 34 24             	mov    %esi,(%esp)
f01020fe:	e8 e2 ec ff ff       	call   f0100de5 <page_free>

	cprintf("check_page() succeeded!\n");
f0102103:	c7 04 24 5c 55 10 f0 	movl   $0xf010555c,(%esp)
f010210a:	e8 ca 0d 00 00       	call   f0102ed9 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U | PTE_P);
f010210f:	a1 4c 4c 17 f0       	mov    0xf0174c4c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102114:	83 c4 10             	add    $0x10,%esp
f0102117:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010211c:	77 15                	ja     f0102133 <mem_init+0x10f1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010211e:	50                   	push   %eax
f010211f:	68 68 4c 10 f0       	push   $0xf0104c68
f0102124:	68 b5 00 00 00       	push   $0xb5
f0102129:	68 a9 52 10 f0       	push   $0xf01052a9
f010212e:	e8 6d df ff ff       	call   f01000a0 <_panic>
f0102133:	83 ec 08             	sub    $0x8,%esp
f0102136:	6a 05                	push   $0x5
f0102138:	05 00 00 00 10       	add    $0x10000000,%eax
f010213d:	50                   	push   %eax
f010213e:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102143:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102148:	a1 48 4c 17 f0       	mov    0xf0174c48,%eax
f010214d:	e8 a3 ed ff ff       	call   f0100ef5 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U | PTE_P);
f0102152:	a1 88 3f 17 f0       	mov    0xf0173f88,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102157:	83 c4 10             	add    $0x10,%esp
f010215a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010215f:	77 15                	ja     f0102176 <mem_init+0x1134>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102161:	50                   	push   %eax
f0102162:	68 68 4c 10 f0       	push   $0xf0104c68
f0102167:	68 bd 00 00 00       	push   $0xbd
f010216c:	68 a9 52 10 f0       	push   $0xf01052a9
f0102171:	e8 2a df ff ff       	call   f01000a0 <_panic>
f0102176:	83 ec 08             	sub    $0x8,%esp
f0102179:	6a 05                	push   $0x5
f010217b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102180:	50                   	push   %eax
f0102181:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102186:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010218b:	a1 48 4c 17 f0       	mov    0xf0174c48,%eax
f0102190:	e8 60 ed ff ff       	call   f0100ef5 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102195:	83 c4 10             	add    $0x10,%esp
f0102198:	b8 00 00 11 f0       	mov    $0xf0110000,%eax
f010219d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01021a2:	77 15                	ja     f01021b9 <mem_init+0x1177>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01021a4:	50                   	push   %eax
f01021a5:	68 68 4c 10 f0       	push   $0xf0104c68
f01021aa:	68 c9 00 00 00       	push   $0xc9
f01021af:	68 a9 52 10 f0       	push   $0xf01052a9
f01021b4:	e8 e7 de ff ff       	call   f01000a0 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01021b9:	83 ec 08             	sub    $0x8,%esp
f01021bc:	6a 02                	push   $0x2
f01021be:	68 00 00 11 00       	push   $0x110000
f01021c3:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01021c8:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01021cd:	a1 48 4c 17 f0       	mov    0xf0174c48,%eax
f01021d2:	e8 1e ed ff ff       	call   f0100ef5 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff-KERNBASE, 0, PTE_W);
f01021d7:	83 c4 08             	add    $0x8,%esp
f01021da:	6a 02                	push   $0x2
f01021dc:	6a 00                	push   $0x0
f01021de:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01021e3:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01021e8:	a1 48 4c 17 f0       	mov    0xf0174c48,%eax
f01021ed:	e8 03 ed ff ff       	call   f0100ef5 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01021f2:	8b 1d 48 4c 17 f0    	mov    0xf0174c48,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01021f8:	a1 44 4c 17 f0       	mov    0xf0174c44,%eax
f01021fd:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102200:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102207:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010220c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010220f:	8b 3d 4c 4c 17 f0    	mov    0xf0174c4c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102215:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102218:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010221b:	be 00 00 00 00       	mov    $0x0,%esi
f0102220:	eb 55                	jmp    f0102277 <mem_init+0x1235>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102222:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0102228:	89 d8                	mov    %ebx,%eax
f010222a:	e8 38 e7 ff ff       	call   f0100967 <check_va2pa>
f010222f:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102236:	77 15                	ja     f010224d <mem_init+0x120b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102238:	57                   	push   %edi
f0102239:	68 68 4c 10 f0       	push   $0xf0104c68
f010223e:	68 2b 03 00 00       	push   $0x32b
f0102243:	68 a9 52 10 f0       	push   $0xf01052a9
f0102248:	e8 53 de ff ff       	call   f01000a0 <_panic>
f010224d:	8d 94 37 00 00 00 10 	lea    0x10000000(%edi,%esi,1),%edx
f0102254:	39 d0                	cmp    %edx,%eax
f0102256:	74 19                	je     f0102271 <mem_init+0x122f>
f0102258:	68 e4 50 10 f0       	push   $0xf01050e4
f010225d:	68 cf 52 10 f0       	push   $0xf01052cf
f0102262:	68 2b 03 00 00       	push   $0x32b
f0102267:	68 a9 52 10 f0       	push   $0xf01052a9
f010226c:	e8 2f de ff ff       	call   f01000a0 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102271:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102277:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f010227a:	77 a6                	ja     f0102222 <mem_init+0x11e0>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010227c:	8b 3d 88 3f 17 f0    	mov    0xf0173f88,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102282:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102285:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f010228a:	89 f2                	mov    %esi,%edx
f010228c:	89 d8                	mov    %ebx,%eax
f010228e:	e8 d4 e6 ff ff       	call   f0100967 <check_va2pa>
f0102293:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f010229a:	77 15                	ja     f01022b1 <mem_init+0x126f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010229c:	57                   	push   %edi
f010229d:	68 68 4c 10 f0       	push   $0xf0104c68
f01022a2:	68 30 03 00 00       	push   $0x330
f01022a7:	68 a9 52 10 f0       	push   $0xf01052a9
f01022ac:	e8 ef dd ff ff       	call   f01000a0 <_panic>
f01022b1:	8d 94 37 00 00 40 21 	lea    0x21400000(%edi,%esi,1),%edx
f01022b8:	39 c2                	cmp    %eax,%edx
f01022ba:	74 19                	je     f01022d5 <mem_init+0x1293>
f01022bc:	68 18 51 10 f0       	push   $0xf0105118
f01022c1:	68 cf 52 10 f0       	push   $0xf01052cf
f01022c6:	68 30 03 00 00       	push   $0x330
f01022cb:	68 a9 52 10 f0       	push   $0xf01052a9
f01022d0:	e8 cb dd ff ff       	call   f01000a0 <_panic>
f01022d5:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01022db:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f01022e1:	75 a7                	jne    f010228a <mem_init+0x1248>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01022e3:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01022e6:	c1 e7 0c             	shl    $0xc,%edi
f01022e9:	be 00 00 00 00       	mov    $0x0,%esi
f01022ee:	eb 30                	jmp    f0102320 <mem_init+0x12de>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01022f0:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f01022f6:	89 d8                	mov    %ebx,%eax
f01022f8:	e8 6a e6 ff ff       	call   f0100967 <check_va2pa>
f01022fd:	39 c6                	cmp    %eax,%esi
f01022ff:	74 19                	je     f010231a <mem_init+0x12d8>
f0102301:	68 4c 51 10 f0       	push   $0xf010514c
f0102306:	68 cf 52 10 f0       	push   $0xf01052cf
f010230b:	68 34 03 00 00       	push   $0x334
f0102310:	68 a9 52 10 f0       	push   $0xf01052a9
f0102315:	e8 86 dd ff ff       	call   f01000a0 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010231a:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102320:	39 fe                	cmp    %edi,%esi
f0102322:	72 cc                	jb     f01022f0 <mem_init+0x12ae>
f0102324:	be 00 80 ff ef       	mov    $0xefff8000,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102329:	89 f2                	mov    %esi,%edx
f010232b:	89 d8                	mov    %ebx,%eax
f010232d:	e8 35 e6 ff ff       	call   f0100967 <check_va2pa>
f0102332:	8d 96 00 80 11 10    	lea    0x10118000(%esi),%edx
f0102338:	39 c2                	cmp    %eax,%edx
f010233a:	74 19                	je     f0102355 <mem_init+0x1313>
f010233c:	68 74 51 10 f0       	push   $0xf0105174
f0102341:	68 cf 52 10 f0       	push   $0xf01052cf
f0102346:	68 38 03 00 00       	push   $0x338
f010234b:	68 a9 52 10 f0       	push   $0xf01052a9
f0102350:	e8 4b dd ff ff       	call   f01000a0 <_panic>
f0102355:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010235b:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102361:	75 c6                	jne    f0102329 <mem_init+0x12e7>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102363:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102368:	89 d8                	mov    %ebx,%eax
f010236a:	e8 f8 e5 ff ff       	call   f0100967 <check_va2pa>
f010236f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102372:	74 51                	je     f01023c5 <mem_init+0x1383>
f0102374:	68 bc 51 10 f0       	push   $0xf01051bc
f0102379:	68 cf 52 10 f0       	push   $0xf01052cf
f010237e:	68 39 03 00 00       	push   $0x339
f0102383:	68 a9 52 10 f0       	push   $0xf01052a9
f0102388:	e8 13 dd ff ff       	call   f01000a0 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010238d:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102392:	72 36                	jb     f01023ca <mem_init+0x1388>
f0102394:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102399:	76 07                	jbe    f01023a2 <mem_init+0x1360>
f010239b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01023a0:	75 28                	jne    f01023ca <mem_init+0x1388>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f01023a2:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01023a6:	0f 85 83 00 00 00    	jne    f010242f <mem_init+0x13ed>
f01023ac:	68 75 55 10 f0       	push   $0xf0105575
f01023b1:	68 cf 52 10 f0       	push   $0xf01052cf
f01023b6:	68 42 03 00 00       	push   $0x342
f01023bb:	68 a9 52 10 f0       	push   $0xf01052a9
f01023c0:	e8 db dc ff ff       	call   f01000a0 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023c5:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01023ca:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01023cf:	76 3f                	jbe    f0102410 <mem_init+0x13ce>
				assert(pgdir[i] & PTE_P);
f01023d1:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f01023d4:	f6 c2 01             	test   $0x1,%dl
f01023d7:	75 19                	jne    f01023f2 <mem_init+0x13b0>
f01023d9:	68 75 55 10 f0       	push   $0xf0105575
f01023de:	68 cf 52 10 f0       	push   $0xf01052cf
f01023e3:	68 46 03 00 00       	push   $0x346
f01023e8:	68 a9 52 10 f0       	push   $0xf01052a9
f01023ed:	e8 ae dc ff ff       	call   f01000a0 <_panic>
				assert(pgdir[i] & PTE_W);
f01023f2:	f6 c2 02             	test   $0x2,%dl
f01023f5:	75 38                	jne    f010242f <mem_init+0x13ed>
f01023f7:	68 86 55 10 f0       	push   $0xf0105586
f01023fc:	68 cf 52 10 f0       	push   $0xf01052cf
f0102401:	68 47 03 00 00       	push   $0x347
f0102406:	68 a9 52 10 f0       	push   $0xf01052a9
f010240b:	e8 90 dc ff ff       	call   f01000a0 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102410:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102414:	74 19                	je     f010242f <mem_init+0x13ed>
f0102416:	68 97 55 10 f0       	push   $0xf0105597
f010241b:	68 cf 52 10 f0       	push   $0xf01052cf
f0102420:	68 49 03 00 00       	push   $0x349
f0102425:	68 a9 52 10 f0       	push   $0xf01052a9
f010242a:	e8 71 dc ff ff       	call   f01000a0 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010242f:	83 c0 01             	add    $0x1,%eax
f0102432:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102437:	0f 86 50 ff ff ff    	jbe    f010238d <mem_init+0x134b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010243d:	83 ec 0c             	sub    $0xc,%esp
f0102440:	68 ec 51 10 f0       	push   $0xf01051ec
f0102445:	e8 8f 0a 00 00       	call   f0102ed9 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010244a:	a1 48 4c 17 f0       	mov    0xf0174c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010244f:	83 c4 10             	add    $0x10,%esp
f0102452:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102457:	77 15                	ja     f010246e <mem_init+0x142c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102459:	50                   	push   %eax
f010245a:	68 68 4c 10 f0       	push   $0xf0104c68
f010245f:	68 dd 00 00 00       	push   $0xdd
f0102464:	68 a9 52 10 f0       	push   $0xf01052a9
f0102469:	e8 32 dc ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010246e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102473:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102476:	b8 00 00 00 00       	mov    $0x0,%eax
f010247b:	e8 4b e5 ff ff       	call   f01009cb <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102480:	0f 20 c0             	mov    %cr0,%eax
f0102483:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102486:	0d 23 00 05 80       	or     $0x80050023,%eax
f010248b:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010248e:	83 ec 0c             	sub    $0xc,%esp
f0102491:	6a 00                	push   $0x0
f0102493:	e8 c7 e8 ff ff       	call   f0100d5f <page_alloc>
f0102498:	89 c3                	mov    %eax,%ebx
f010249a:	83 c4 10             	add    $0x10,%esp
f010249d:	85 c0                	test   %eax,%eax
f010249f:	75 19                	jne    f01024ba <mem_init+0x1478>
f01024a1:	68 93 53 10 f0       	push   $0xf0105393
f01024a6:	68 cf 52 10 f0       	push   $0xf01052cf
f01024ab:	68 09 04 00 00       	push   $0x409
f01024b0:	68 a9 52 10 f0       	push   $0xf01052a9
f01024b5:	e8 e6 db ff ff       	call   f01000a0 <_panic>
	assert((pp1 = page_alloc(0)));
f01024ba:	83 ec 0c             	sub    $0xc,%esp
f01024bd:	6a 00                	push   $0x0
f01024bf:	e8 9b e8 ff ff       	call   f0100d5f <page_alloc>
f01024c4:	89 c7                	mov    %eax,%edi
f01024c6:	83 c4 10             	add    $0x10,%esp
f01024c9:	85 c0                	test   %eax,%eax
f01024cb:	75 19                	jne    f01024e6 <mem_init+0x14a4>
f01024cd:	68 a9 53 10 f0       	push   $0xf01053a9
f01024d2:	68 cf 52 10 f0       	push   $0xf01052cf
f01024d7:	68 0a 04 00 00       	push   $0x40a
f01024dc:	68 a9 52 10 f0       	push   $0xf01052a9
f01024e1:	e8 ba db ff ff       	call   f01000a0 <_panic>
	assert((pp2 = page_alloc(0)));
f01024e6:	83 ec 0c             	sub    $0xc,%esp
f01024e9:	6a 00                	push   $0x0
f01024eb:	e8 6f e8 ff ff       	call   f0100d5f <page_alloc>
f01024f0:	89 c6                	mov    %eax,%esi
f01024f2:	83 c4 10             	add    $0x10,%esp
f01024f5:	85 c0                	test   %eax,%eax
f01024f7:	75 19                	jne    f0102512 <mem_init+0x14d0>
f01024f9:	68 bf 53 10 f0       	push   $0xf01053bf
f01024fe:	68 cf 52 10 f0       	push   $0xf01052cf
f0102503:	68 0b 04 00 00       	push   $0x40b
f0102508:	68 a9 52 10 f0       	push   $0xf01052a9
f010250d:	e8 8e db ff ff       	call   f01000a0 <_panic>
	page_free(pp0);
f0102512:	83 ec 0c             	sub    $0xc,%esp
f0102515:	53                   	push   %ebx
f0102516:	e8 ca e8 ff ff       	call   f0100de5 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010251b:	89 f8                	mov    %edi,%eax
f010251d:	2b 05 4c 4c 17 f0    	sub    0xf0174c4c,%eax
f0102523:	c1 f8 03             	sar    $0x3,%eax
f0102526:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102529:	89 c2                	mov    %eax,%edx
f010252b:	c1 ea 0c             	shr    $0xc,%edx
f010252e:	83 c4 10             	add    $0x10,%esp
f0102531:	3b 15 44 4c 17 f0    	cmp    0xf0174c44,%edx
f0102537:	72 12                	jb     f010254b <mem_init+0x1509>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102539:	50                   	push   %eax
f010253a:	68 24 4b 10 f0       	push   $0xf0104b24
f010253f:	6a 56                	push   $0x56
f0102541:	68 b5 52 10 f0       	push   $0xf01052b5
f0102546:	e8 55 db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010254b:	83 ec 04             	sub    $0x4,%esp
f010254e:	68 00 10 00 00       	push   $0x1000
f0102553:	6a 01                	push   $0x1
f0102555:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010255a:	50                   	push   %eax
f010255b:	e8 e0 1b 00 00       	call   f0104140 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102560:	89 f0                	mov    %esi,%eax
f0102562:	2b 05 4c 4c 17 f0    	sub    0xf0174c4c,%eax
f0102568:	c1 f8 03             	sar    $0x3,%eax
f010256b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010256e:	89 c2                	mov    %eax,%edx
f0102570:	c1 ea 0c             	shr    $0xc,%edx
f0102573:	83 c4 10             	add    $0x10,%esp
f0102576:	3b 15 44 4c 17 f0    	cmp    0xf0174c44,%edx
f010257c:	72 12                	jb     f0102590 <mem_init+0x154e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010257e:	50                   	push   %eax
f010257f:	68 24 4b 10 f0       	push   $0xf0104b24
f0102584:	6a 56                	push   $0x56
f0102586:	68 b5 52 10 f0       	push   $0xf01052b5
f010258b:	e8 10 db ff ff       	call   f01000a0 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102590:	83 ec 04             	sub    $0x4,%esp
f0102593:	68 00 10 00 00       	push   $0x1000
f0102598:	6a 02                	push   $0x2
f010259a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010259f:	50                   	push   %eax
f01025a0:	e8 9b 1b 00 00       	call   f0104140 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01025a5:	6a 02                	push   $0x2
f01025a7:	68 00 10 00 00       	push   $0x1000
f01025ac:	57                   	push   %edi
f01025ad:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f01025b3:	e8 24 ea ff ff       	call   f0100fdc <page_insert>
	assert(pp1->pp_ref == 1);
f01025b8:	83 c4 20             	add    $0x20,%esp
f01025bb:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01025c0:	74 19                	je     f01025db <mem_init+0x1599>
f01025c2:	68 90 54 10 f0       	push   $0xf0105490
f01025c7:	68 cf 52 10 f0       	push   $0xf01052cf
f01025cc:	68 10 04 00 00       	push   $0x410
f01025d1:	68 a9 52 10 f0       	push   $0xf01052a9
f01025d6:	e8 c5 da ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01025db:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01025e2:	01 01 01 
f01025e5:	74 19                	je     f0102600 <mem_init+0x15be>
f01025e7:	68 0c 52 10 f0       	push   $0xf010520c
f01025ec:	68 cf 52 10 f0       	push   $0xf01052cf
f01025f1:	68 11 04 00 00       	push   $0x411
f01025f6:	68 a9 52 10 f0       	push   $0xf01052a9
f01025fb:	e8 a0 da ff ff       	call   f01000a0 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102600:	6a 02                	push   $0x2
f0102602:	68 00 10 00 00       	push   $0x1000
f0102607:	56                   	push   %esi
f0102608:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f010260e:	e8 c9 e9 ff ff       	call   f0100fdc <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102613:	83 c4 10             	add    $0x10,%esp
f0102616:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010261d:	02 02 02 
f0102620:	74 19                	je     f010263b <mem_init+0x15f9>
f0102622:	68 30 52 10 f0       	push   $0xf0105230
f0102627:	68 cf 52 10 f0       	push   $0xf01052cf
f010262c:	68 13 04 00 00       	push   $0x413
f0102631:	68 a9 52 10 f0       	push   $0xf01052a9
f0102636:	e8 65 da ff ff       	call   f01000a0 <_panic>
	assert(pp2->pp_ref == 1);
f010263b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102640:	74 19                	je     f010265b <mem_init+0x1619>
f0102642:	68 b2 54 10 f0       	push   $0xf01054b2
f0102647:	68 cf 52 10 f0       	push   $0xf01052cf
f010264c:	68 14 04 00 00       	push   $0x414
f0102651:	68 a9 52 10 f0       	push   $0xf01052a9
f0102656:	e8 45 da ff ff       	call   f01000a0 <_panic>
	assert(pp1->pp_ref == 0);
f010265b:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102660:	74 19                	je     f010267b <mem_init+0x1639>
f0102662:	68 1c 55 10 f0       	push   $0xf010551c
f0102667:	68 cf 52 10 f0       	push   $0xf01052cf
f010266c:	68 15 04 00 00       	push   $0x415
f0102671:	68 a9 52 10 f0       	push   $0xf01052a9
f0102676:	e8 25 da ff ff       	call   f01000a0 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010267b:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102682:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102685:	89 f0                	mov    %esi,%eax
f0102687:	2b 05 4c 4c 17 f0    	sub    0xf0174c4c,%eax
f010268d:	c1 f8 03             	sar    $0x3,%eax
f0102690:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102693:	89 c2                	mov    %eax,%edx
f0102695:	c1 ea 0c             	shr    $0xc,%edx
f0102698:	3b 15 44 4c 17 f0    	cmp    0xf0174c44,%edx
f010269e:	72 12                	jb     f01026b2 <mem_init+0x1670>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026a0:	50                   	push   %eax
f01026a1:	68 24 4b 10 f0       	push   $0xf0104b24
f01026a6:	6a 56                	push   $0x56
f01026a8:	68 b5 52 10 f0       	push   $0xf01052b5
f01026ad:	e8 ee d9 ff ff       	call   f01000a0 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01026b2:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01026b9:	03 03 03 
f01026bc:	74 19                	je     f01026d7 <mem_init+0x1695>
f01026be:	68 54 52 10 f0       	push   $0xf0105254
f01026c3:	68 cf 52 10 f0       	push   $0xf01052cf
f01026c8:	68 17 04 00 00       	push   $0x417
f01026cd:	68 a9 52 10 f0       	push   $0xf01052a9
f01026d2:	e8 c9 d9 ff ff       	call   f01000a0 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01026d7:	83 ec 08             	sub    $0x8,%esp
f01026da:	68 00 10 00 00       	push   $0x1000
f01026df:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f01026e5:	e8 b7 e8 ff ff       	call   f0100fa1 <page_remove>
	assert(pp2->pp_ref == 0);
f01026ea:	83 c4 10             	add    $0x10,%esp
f01026ed:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01026f2:	74 19                	je     f010270d <mem_init+0x16cb>
f01026f4:	68 ea 54 10 f0       	push   $0xf01054ea
f01026f9:	68 cf 52 10 f0       	push   $0xf01052cf
f01026fe:	68 19 04 00 00       	push   $0x419
f0102703:	68 a9 52 10 f0       	push   $0xf01052a9
f0102708:	e8 93 d9 ff ff       	call   f01000a0 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010270d:	8b 0d 48 4c 17 f0    	mov    0xf0174c48,%ecx
f0102713:	8b 11                	mov    (%ecx),%edx
f0102715:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010271b:	89 d8                	mov    %ebx,%eax
f010271d:	2b 05 4c 4c 17 f0    	sub    0xf0174c4c,%eax
f0102723:	c1 f8 03             	sar    $0x3,%eax
f0102726:	c1 e0 0c             	shl    $0xc,%eax
f0102729:	39 c2                	cmp    %eax,%edx
f010272b:	74 19                	je     f0102746 <mem_init+0x1704>
f010272d:	68 64 4d 10 f0       	push   $0xf0104d64
f0102732:	68 cf 52 10 f0       	push   $0xf01052cf
f0102737:	68 1c 04 00 00       	push   $0x41c
f010273c:	68 a9 52 10 f0       	push   $0xf01052a9
f0102741:	e8 5a d9 ff ff       	call   f01000a0 <_panic>
	kern_pgdir[0] = 0;
f0102746:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010274c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102751:	74 19                	je     f010276c <mem_init+0x172a>
f0102753:	68 a1 54 10 f0       	push   $0xf01054a1
f0102758:	68 cf 52 10 f0       	push   $0xf01052cf
f010275d:	68 1e 04 00 00       	push   $0x41e
f0102762:	68 a9 52 10 f0       	push   $0xf01052a9
f0102767:	e8 34 d9 ff ff       	call   f01000a0 <_panic>
	pp0->pp_ref = 0;
f010276c:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102772:	83 ec 0c             	sub    $0xc,%esp
f0102775:	53                   	push   %ebx
f0102776:	e8 6a e6 ff ff       	call   f0100de5 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010277b:	c7 04 24 80 52 10 f0 	movl   $0xf0105280,(%esp)
f0102782:	e8 52 07 00 00       	call   f0102ed9 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102787:	83 c4 10             	add    $0x10,%esp
f010278a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010278d:	5b                   	pop    %ebx
f010278e:	5e                   	pop    %esi
f010278f:	5f                   	pop    %edi
f0102790:	5d                   	pop    %ebp
f0102791:	c3                   	ret    

f0102792 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102792:	55                   	push   %ebp
f0102793:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102795:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102798:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010279b:	5d                   	pop    %ebp
f010279c:	c3                   	ret    

f010279d <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f010279d:	55                   	push   %ebp
f010279e:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f01027a0:	b8 00 00 00 00       	mov    $0x0,%eax
f01027a5:	5d                   	pop    %ebp
f01027a6:	c3                   	ret    

f01027a7 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01027a7:	55                   	push   %ebp
f01027a8:	89 e5                	mov    %esp,%ebp
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
		cprintf("[%08x] user_mem_check assertion failure for "
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
	}
}
f01027aa:	5d                   	pop    %ebp
f01027ab:	c3                   	ret    

f01027ac <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01027ac:	55                   	push   %ebp
f01027ad:	89 e5                	mov    %esp,%ebp
f01027af:	57                   	push   %edi
f01027b0:	56                   	push   %esi
f01027b1:	53                   	push   %ebx
f01027b2:	83 ec 14             	sub    $0x14,%esp
f01027b5:	89 c7                	mov    %eax,%edi
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	//boot_map_region(e->env_pgdir, va, len, PADDR(envs), PTE_P | PTE_U | PTE_W);
	uint32_t start,end;
	start = ROUNDDOWN((uint32_t)va, PGSIZE);
f01027b7:	89 d3                	mov    %edx,%ebx
f01027b9:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	end = ROUNDUP((uint32_t)(va + len), PGSIZE);
f01027bf:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01027c6:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	cprintf("start=%d \n",start);
f01027cc:	53                   	push   %ebx
f01027cd:	68 a5 55 10 f0       	push   $0xf01055a5
f01027d2:	e8 02 07 00 00       	call   f0102ed9 <cprintf>
	cprintf("end=%d \n",end);
f01027d7:	83 c4 08             	add    $0x8,%esp
f01027da:	56                   	push   %esi
f01027db:	68 b0 55 10 f0       	push   $0xf01055b0
f01027e0:	e8 f4 06 00 00       	call   f0102ed9 <cprintf>

	struct PageInfo *Page;
	int r;
	for(int i = start;i < end;i += PGSIZE)
f01027e5:	83 c4 10             	add    $0x10,%esp
f01027e8:	eb 56                	jmp    f0102840 <region_alloc+0x94>
	{
		Page = page_alloc(0);
f01027ea:	83 ec 0c             	sub    $0xc,%esp
f01027ed:	6a 00                	push   $0x0
f01027ef:	e8 6b e5 ff ff       	call   f0100d5f <page_alloc>
		if(!Page)
f01027f4:	83 c4 10             	add    $0x10,%esp
f01027f7:	85 c0                	test   %eax,%eax
f01027f9:	75 17                	jne    f0102812 <region_alloc+0x66>
			panic("page_alloc fail");
f01027fb:	83 ec 04             	sub    $0x4,%esp
f01027fe:	68 b9 55 10 f0       	push   $0xf01055b9
f0102803:	68 28 01 00 00       	push   $0x128
f0102808:	68 c9 55 10 f0       	push   $0xf01055c9
f010280d:	e8 8e d8 ff ff       	call   f01000a0 <_panic>
		//r = page_insert(e->env_pgdir, Page, va, PTE_P | PTE_U | PTE_W);
		r = page_insert(e->env_pgdir, Page, (void *)i, PTE_U | PTE_W);
f0102812:	6a 06                	push   $0x6
f0102814:	53                   	push   %ebx
f0102815:	50                   	push   %eax
f0102816:	ff 77 5c             	pushl  0x5c(%edi)
f0102819:	e8 be e7 ff ff       	call   f0100fdc <page_insert>
		if(r != 0)
f010281e:	83 c4 10             	add    $0x10,%esp
f0102821:	85 c0                	test   %eax,%eax
f0102823:	74 15                	je     f010283a <region_alloc+0x8e>
			panic("region_alloc: %e", r);
f0102825:	50                   	push   %eax
f0102826:	68 d4 55 10 f0       	push   $0xf01055d4
f010282b:	68 2c 01 00 00       	push   $0x12c
f0102830:	68 c9 55 10 f0       	push   $0xf01055c9
f0102835:	e8 66 d8 ff ff       	call   f01000a0 <_panic>
	cprintf("start=%d \n",start);
	cprintf("end=%d \n",end);

	struct PageInfo *Page;
	int r;
	for(int i = start;i < end;i += PGSIZE)
f010283a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102840:	39 de                	cmp    %ebx,%esi
f0102842:	77 a6                	ja     f01027ea <region_alloc+0x3e>
		r = page_insert(e->env_pgdir, Page, (void *)i, PTE_U | PTE_W);
		if(r != 0)
			panic("region_alloc: %e", r);
			//panic("region_alloc fail");
	}
}
f0102844:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102847:	5b                   	pop    %ebx
f0102848:	5e                   	pop    %esi
f0102849:	5f                   	pop    %edi
f010284a:	5d                   	pop    %ebp
f010284b:	c3                   	ret    

f010284c <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010284c:	55                   	push   %ebp
f010284d:	89 e5                	mov    %esp,%ebp
f010284f:	8b 55 08             	mov    0x8(%ebp),%edx
f0102852:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102855:	85 d2                	test   %edx,%edx
f0102857:	75 11                	jne    f010286a <envid2env+0x1e>
		*env_store = curenv;
f0102859:	a1 84 3f 17 f0       	mov    0xf0173f84,%eax
f010285e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102861:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102863:	b8 00 00 00 00       	mov    $0x0,%eax
f0102868:	eb 5e                	jmp    f01028c8 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f010286a:	89 d0                	mov    %edx,%eax
f010286c:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102871:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102874:	c1 e0 05             	shl    $0x5,%eax
f0102877:	03 05 88 3f 17 f0    	add    0xf0173f88,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f010287d:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102881:	74 05                	je     f0102888 <envid2env+0x3c>
f0102883:	3b 50 48             	cmp    0x48(%eax),%edx
f0102886:	74 10                	je     f0102898 <envid2env+0x4c>
		*env_store = 0;
f0102888:	8b 45 0c             	mov    0xc(%ebp),%eax
f010288b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102891:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102896:	eb 30                	jmp    f01028c8 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102898:	84 c9                	test   %cl,%cl
f010289a:	74 22                	je     f01028be <envid2env+0x72>
f010289c:	8b 15 84 3f 17 f0    	mov    0xf0173f84,%edx
f01028a2:	39 d0                	cmp    %edx,%eax
f01028a4:	74 18                	je     f01028be <envid2env+0x72>
f01028a6:	8b 4a 48             	mov    0x48(%edx),%ecx
f01028a9:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f01028ac:	74 10                	je     f01028be <envid2env+0x72>
		*env_store = 0;
f01028ae:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028b1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01028b7:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01028bc:	eb 0a                	jmp    f01028c8 <envid2env+0x7c>
	}

	*env_store = e;
f01028be:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01028c1:	89 01                	mov    %eax,(%ecx)
	return 0;
f01028c3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01028c8:	5d                   	pop    %ebp
f01028c9:	c3                   	ret    

f01028ca <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01028ca:	55                   	push   %ebp
f01028cb:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f01028cd:	b8 00 a3 11 f0       	mov    $0xf011a300,%eax
f01028d2:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01028d5:	b8 23 00 00 00       	mov    $0x23,%eax
f01028da:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01028dc:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01028de:	b8 10 00 00 00       	mov    $0x10,%eax
f01028e3:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01028e5:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01028e7:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01028e9:	ea f0 28 10 f0 08 00 	ljmp   $0x8,$0xf01028f0
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f01028f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01028f5:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01028f8:	5d                   	pop    %ebp
f01028f9:	c3                   	ret    

f01028fa <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01028fa:	55                   	push   %ebp
f01028fb:	89 e5                	mov    %esp,%ebp
f01028fd:	56                   	push   %esi
f01028fe:	53                   	push   %ebx
	// LAB 3: Your code here.
	// struct Env* envs;
	// env_free_list = NULL;
	for(int i = NENV - 1;i >= 0;i--)
	{
		envs[i].env_id = 0;
f01028ff:	8b 35 88 3f 17 f0    	mov    0xf0173f88,%esi
f0102905:	8b 15 8c 3f 17 f0    	mov    0xf0173f8c,%edx
f010290b:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0102911:	8d 5e a0             	lea    -0x60(%esi),%ebx
f0102914:	89 c1                	mov    %eax,%ecx
f0102916:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f010291d:	89 50 44             	mov    %edx,0x44(%eax)
f0102920:	83 e8 60             	sub    $0x60,%eax
		env_free_list = &envs[i];
f0102923:	89 ca                	mov    %ecx,%edx
{
	// Set up envs array
	// LAB 3: Your code here.
	// struct Env* envs;
	// env_free_list = NULL;
	for(int i = NENV - 1;i >= 0;i--)
f0102925:	39 d8                	cmp    %ebx,%eax
f0102927:	75 eb                	jne    f0102914 <env_init+0x1a>
f0102929:	89 35 8c 3f 17 f0    	mov    %esi,0xf0173f8c
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
		//envs[i].env_status = 
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f010292f:	e8 96 ff ff ff       	call   f01028ca <env_init_percpu>
}
f0102934:	5b                   	pop    %ebx
f0102935:	5e                   	pop    %esi
f0102936:	5d                   	pop    %ebp
f0102937:	c3                   	ret    

f0102938 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102938:	55                   	push   %ebp
f0102939:	89 e5                	mov    %esp,%ebp
f010293b:	56                   	push   %esi
f010293c:	53                   	push   %ebx
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f010293d:	8b 1d 8c 3f 17 f0    	mov    0xf0173f8c,%ebx
f0102943:	85 db                	test   %ebx,%ebx
f0102945:	0f 84 45 01 00 00    	je     f0102a90 <env_alloc+0x158>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f010294b:	83 ec 0c             	sub    $0xc,%esp
f010294e:	6a 01                	push   $0x1
f0102950:	e8 0a e4 ff ff       	call   f0100d5f <page_alloc>
f0102955:	89 c6                	mov    %eax,%esi
f0102957:	83 c4 10             	add    $0x10,%esp
f010295a:	85 c0                	test   %eax,%eax
f010295c:	0f 84 35 01 00 00    	je     f0102a97 <env_alloc+0x15f>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102962:	2b 05 4c 4c 17 f0    	sub    0xf0174c4c,%eax
f0102968:	c1 f8 03             	sar    $0x3,%eax
f010296b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010296e:	89 c2                	mov    %eax,%edx
f0102970:	c1 ea 0c             	shr    $0xc,%edx
f0102973:	3b 15 44 4c 17 f0    	cmp    0xf0174c44,%edx
f0102979:	72 12                	jb     f010298d <env_alloc+0x55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010297b:	50                   	push   %eax
f010297c:	68 24 4b 10 f0       	push   $0xf0104b24
f0102981:	6a 56                	push   $0x56
f0102983:	68 b5 52 10 f0       	push   $0xf01052b5
f0102988:	e8 13 d7 ff ff       	call   f01000a0 <_panic>
	return (void *)(pa + KERNBASE);
f010298d:	2d 00 00 00 10       	sub    $0x10000000,%eax
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	// p = page_alloc(ALLOC_ZERO);
	e->env_pgdir = page2kva(p);
f0102992:	89 43 5c             	mov    %eax,0x5c(%ebx)
	//memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
	memmove(e->env_pgdir, kern_pgdir, PGSIZE);
f0102995:	83 ec 04             	sub    $0x4,%esp
f0102998:	68 00 10 00 00       	push   $0x1000
f010299d:	ff 35 48 4c 17 f0    	pushl  0xf0174c48
f01029a3:	50                   	push   %eax
f01029a4:	e8 e4 17 00 00       	call   f010418d <memmove>
	p->pp_ref++;
f01029a9:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01029ae:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01029b1:	83 c4 10             	add    $0x10,%esp
f01029b4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029b9:	77 15                	ja     f01029d0 <env_alloc+0x98>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029bb:	50                   	push   %eax
f01029bc:	68 68 4c 10 f0       	push   $0xf0104c68
f01029c1:	68 c6 00 00 00       	push   $0xc6
f01029c6:	68 c9 55 10 f0       	push   $0xf01055c9
f01029cb:	e8 d0 d6 ff ff       	call   f01000a0 <_panic>
f01029d0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01029d6:	83 ca 05             	or     $0x5,%edx
f01029d9:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01029df:	8b 43 48             	mov    0x48(%ebx),%eax
f01029e2:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01029e7:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01029ec:	ba 00 10 00 00       	mov    $0x1000,%edx
f01029f1:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01029f4:	89 da                	mov    %ebx,%edx
f01029f6:	2b 15 88 3f 17 f0    	sub    0xf0173f88,%edx
f01029fc:	c1 fa 05             	sar    $0x5,%edx
f01029ff:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102a05:	09 d0                	or     %edx,%eax
f0102a07:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102a0a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a0d:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102a10:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102a17:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102a1e:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102a25:	83 ec 04             	sub    $0x4,%esp
f0102a28:	6a 44                	push   $0x44
f0102a2a:	6a 00                	push   $0x0
f0102a2c:	53                   	push   %ebx
f0102a2d:	e8 0e 17 00 00       	call   f0104140 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102a32:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102a38:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102a3e:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102a44:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102a4b:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102a51:	8b 43 44             	mov    0x44(%ebx),%eax
f0102a54:	a3 8c 3f 17 f0       	mov    %eax,0xf0173f8c
	*newenv_store = e;
f0102a59:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a5c:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102a5e:	8b 53 48             	mov    0x48(%ebx),%edx
f0102a61:	a1 84 3f 17 f0       	mov    0xf0173f84,%eax
f0102a66:	83 c4 10             	add    $0x10,%esp
f0102a69:	85 c0                	test   %eax,%eax
f0102a6b:	74 05                	je     f0102a72 <env_alloc+0x13a>
f0102a6d:	8b 40 48             	mov    0x48(%eax),%eax
f0102a70:	eb 05                	jmp    f0102a77 <env_alloc+0x13f>
f0102a72:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a77:	83 ec 04             	sub    $0x4,%esp
f0102a7a:	52                   	push   %edx
f0102a7b:	50                   	push   %eax
f0102a7c:	68 e5 55 10 f0       	push   $0xf01055e5
f0102a81:	e8 53 04 00 00       	call   f0102ed9 <cprintf>
	return 0;
f0102a86:	83 c4 10             	add    $0x10,%esp
f0102a89:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a8e:	eb 0c                	jmp    f0102a9c <env_alloc+0x164>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102a90:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102a95:	eb 05                	jmp    f0102a9c <env_alloc+0x164>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102a97:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102a9c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0102a9f:	5b                   	pop    %ebx
f0102aa0:	5e                   	pop    %esi
f0102aa1:	5d                   	pop    %ebp
f0102aa2:	c3                   	ret    

f0102aa3 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102aa3:	55                   	push   %ebp
f0102aa4:	89 e5                	mov    %esp,%ebp
f0102aa6:	57                   	push   %edi
f0102aa7:	56                   	push   %esi
f0102aa8:	53                   	push   %ebx
f0102aa9:	83 ec 34             	sub    $0x34,%esp
f0102aac:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int r;
	r = env_alloc(&e, 0);
f0102aaf:	6a 00                	push   $0x0
f0102ab1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102ab4:	50                   	push   %eax
f0102ab5:	e8 7e fe ff ff       	call   f0102938 <env_alloc>
	if(r != 0)
f0102aba:	83 c4 10             	add    $0x10,%esp
f0102abd:	85 c0                	test   %eax,%eax
f0102abf:	74 15                	je     f0102ad6 <env_create+0x33>
		panic("env_create: %e", r);
f0102ac1:	50                   	push   %eax
f0102ac2:	68 fa 55 10 f0       	push   $0xf01055fa
f0102ac7:	68 a1 01 00 00       	push   $0x1a1
f0102acc:	68 c9 55 10 f0       	push   $0xf01055c9
f0102ad1:	e8 ca d5 ff ff       	call   f01000a0 <_panic>
	//if(env_alloc(&e,0) != 0)
	//	panic("env_alloc fail");
	e->env_type = type;
f0102ad6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ad9:	89 c2                	mov    %eax,%edx
f0102adb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102ade:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ae1:	89 42 50             	mov    %eax,0x50(%edx)
	struct Elf *elf;
	// 强制类型转换，将binary后的内存空间内容按照结构ELF的格式读取
	elf = (struct Elf *)binary;
	// is this a valid ELF?
	// ELF头开头的结构体叫做魔数,是一个16位的数组
	if(elf->e_magic != ELF_MAGIC)
f0102ae4:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102aea:	74 17                	je     f0102b03 <env_create+0x60>
		panic("load segements fail");
f0102aec:	83 ec 04             	sub    $0x4,%esp
f0102aef:	68 09 56 10 f0       	push   $0xf0105609
f0102af4:	68 6e 01 00 00       	push   $0x16e
f0102af9:	68 c9 55 10 f0       	push   $0xf01055c9
f0102afe:	e8 9d d5 ff ff       	call   f01000a0 <_panic>
	// load each program segment (ignores ph flags)
	// e_phoff 程序头表的文件偏移地址
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
f0102b03:	89 fb                	mov    %edi,%ebx
f0102b05:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f0102b08:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102b0c:	c1 e6 05             	shl    $0x5,%esi
f0102b0f:	01 de                	add    %ebx,%esi
	// 因为后面需要访问刚分配的内存，所以需要将env_pgdir装入cr3，使二级页表能够运作
	lcr3(PADDR(e->env_pgdir));
f0102b11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b14:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102b17:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b1c:	77 15                	ja     f0102b33 <env_create+0x90>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b1e:	50                   	push   %eax
f0102b1f:	68 68 4c 10 f0       	push   $0xf0104c68
f0102b24:	68 74 01 00 00       	push   $0x174
f0102b29:	68 c9 55 10 f0       	push   $0xf01055c9
f0102b2e:	e8 6d d5 ff ff       	call   f01000a0 <_panic>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102b33:	05 00 00 00 10       	add    $0x10000000,%eax
f0102b38:	0f 22 d8             	mov    %eax,%cr3
f0102b3b:	eb 60                	jmp    f0102b9d <env_create+0xfa>

	for (; ph < eph; ph++)
	{
		// 	(The ELF header should have ph->p_filesz <= ph->p_memsz.)
		if(ph->p_filesz > ph->p_memsz)
f0102b3d:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102b40:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f0102b43:	76 17                	jbe    f0102b5c <env_create+0xb9>
			panic("memory is not enough for file");
f0102b45:	83 ec 04             	sub    $0x4,%esp
f0102b48:	68 1d 56 10 f0       	push   $0xf010561d
f0102b4d:	68 7a 01 00 00       	push   $0x17a
f0102b52:	68 c9 55 10 f0       	push   $0xf01055c9
f0102b57:	e8 44 d5 ff ff       	call   f01000a0 <_panic>
		if(ph->p_type == ELF_PROG_LOAD)
f0102b5c:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102b5f:	75 39                	jne    f0102b9a <env_create+0xf7>
		{
		//  Each segment's virtual address can be found in ph->p_va
		//  and its size in memory can be found in ph->p_memsz.
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0102b61:	8b 53 08             	mov    0x8(%ebx),%edx
f0102b64:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b67:	e8 40 fc ff ff       	call   f01027ac <region_alloc>
		//  The ph->p_filesz bytes from the ELF binary, starting at
		//  'binary + ph->p_offset', should be copied to virtual address
		//  ph->p_va. 
			//memcpy((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0102b6c:	83 ec 04             	sub    $0x4,%esp
f0102b6f:	ff 73 10             	pushl  0x10(%ebx)
f0102b72:	89 f8                	mov    %edi,%eax
f0102b74:	03 43 04             	add    0x4(%ebx),%eax
f0102b77:	50                   	push   %eax
f0102b78:	ff 73 08             	pushl  0x8(%ebx)
f0102b7b:	e8 0d 16 00 00       	call   f010418d <memmove>
        //	Any remaining memory bytes should be cleared to zero.
		    memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
f0102b80:	8b 43 10             	mov    0x10(%ebx),%eax
f0102b83:	83 c4 0c             	add    $0xc,%esp
f0102b86:	8b 53 14             	mov    0x14(%ebx),%edx
f0102b89:	29 c2                	sub    %eax,%edx
f0102b8b:	52                   	push   %edx
f0102b8c:	6a 00                	push   $0x0
f0102b8e:	03 43 08             	add    0x8(%ebx),%eax
f0102b91:	50                   	push   %eax
f0102b92:	e8 a9 15 00 00       	call   f0104140 <memset>
f0102b97:	83 c4 10             	add    $0x10,%esp
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
	eph = ph + elf->e_phnum;
	// 因为后面需要访问刚分配的内存，所以需要将env_pgdir装入cr3，使二级页表能够运作
	lcr3(PADDR(e->env_pgdir));

	for (; ph < eph; ph++)
f0102b9a:	83 c3 20             	add    $0x20,%ebx
f0102b9d:	39 de                	cmp    %ebx,%esi
f0102b9f:	77 9c                	ja     f0102b3d <env_create+0x9a>
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
        //	Any remaining memory bytes should be cleared to zero.
		    memset((void *)ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
		}
	}
	e->env_tf.tf_eip = elf->e_entry;
f0102ba1:	8b 47 18             	mov    0x18(%edi),%eax
f0102ba4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102ba7:	89 47 30             	mov    %eax,0x30(%edi)
	lcr3(PADDR(kern_pgdir));
f0102baa:	a1 48 4c 17 f0       	mov    0xf0174c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102baf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102bb4:	77 15                	ja     f0102bcb <env_create+0x128>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102bb6:	50                   	push   %eax
f0102bb7:	68 68 4c 10 f0       	push   $0xf0104c68
f0102bbc:	68 8a 01 00 00       	push   $0x18a
f0102bc1:	68 c9 55 10 f0       	push   $0xf01055c9
f0102bc6:	e8 d5 d4 ff ff       	call   f01000a0 <_panic>
f0102bcb:	05 00 00 00 10       	add    $0x10000000,%eax
f0102bd0:	0f 22 d8             	mov    %eax,%cr3
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *) USTACKTOP-PGSIZE, PGSIZE);
f0102bd3:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102bd8:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102bdd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102be0:	e8 c7 fb ff ff       	call   f01027ac <region_alloc>
		panic("env_create: %e", r);
	//if(env_alloc(&e,0) != 0)
	//	panic("env_alloc fail");
	e->env_type = type;
	load_icode(e, binary);
}
f0102be5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102be8:	5b                   	pop    %ebx
f0102be9:	5e                   	pop    %esi
f0102bea:	5f                   	pop    %edi
f0102beb:	5d                   	pop    %ebp
f0102bec:	c3                   	ret    

f0102bed <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102bed:	55                   	push   %ebp
f0102bee:	89 e5                	mov    %esp,%ebp
f0102bf0:	57                   	push   %edi
f0102bf1:	56                   	push   %esi
f0102bf2:	53                   	push   %ebx
f0102bf3:	83 ec 1c             	sub    $0x1c,%esp
f0102bf6:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102bf9:	8b 15 84 3f 17 f0    	mov    0xf0173f84,%edx
f0102bff:	39 fa                	cmp    %edi,%edx
f0102c01:	75 29                	jne    f0102c2c <env_free+0x3f>
		lcr3(PADDR(kern_pgdir));
f0102c03:	a1 48 4c 17 f0       	mov    0xf0174c48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c08:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c0d:	77 15                	ja     f0102c24 <env_free+0x37>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c0f:	50                   	push   %eax
f0102c10:	68 68 4c 10 f0       	push   $0xf0104c68
f0102c15:	68 b6 01 00 00       	push   $0x1b6
f0102c1a:	68 c9 55 10 f0       	push   $0xf01055c9
f0102c1f:	e8 7c d4 ff ff       	call   f01000a0 <_panic>
f0102c24:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c29:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102c2c:	8b 4f 48             	mov    0x48(%edi),%ecx
f0102c2f:	85 d2                	test   %edx,%edx
f0102c31:	74 05                	je     f0102c38 <env_free+0x4b>
f0102c33:	8b 42 48             	mov    0x48(%edx),%eax
f0102c36:	eb 05                	jmp    f0102c3d <env_free+0x50>
f0102c38:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c3d:	83 ec 04             	sub    $0x4,%esp
f0102c40:	51                   	push   %ecx
f0102c41:	50                   	push   %eax
f0102c42:	68 3b 56 10 f0       	push   $0xf010563b
f0102c47:	e8 8d 02 00 00       	call   f0102ed9 <cprintf>
f0102c4c:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102c4f:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102c56:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102c59:	89 d0                	mov    %edx,%eax
f0102c5b:	c1 e0 02             	shl    $0x2,%eax
f0102c5e:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102c61:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102c64:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102c67:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102c6d:	0f 84 a8 00 00 00    	je     f0102d1b <env_free+0x12e>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102c73:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c79:	89 f0                	mov    %esi,%eax
f0102c7b:	c1 e8 0c             	shr    $0xc,%eax
f0102c7e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102c81:	39 05 44 4c 17 f0    	cmp    %eax,0xf0174c44
f0102c87:	77 15                	ja     f0102c9e <env_free+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c89:	56                   	push   %esi
f0102c8a:	68 24 4b 10 f0       	push   $0xf0104b24
f0102c8f:	68 c5 01 00 00       	push   $0x1c5
f0102c94:	68 c9 55 10 f0       	push   $0xf01055c9
f0102c99:	e8 02 d4 ff ff       	call   f01000a0 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102c9e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102ca1:	c1 e0 16             	shl    $0x16,%eax
f0102ca4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102ca7:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102cac:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102cb3:	01 
f0102cb4:	74 17                	je     f0102ccd <env_free+0xe0>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102cb6:	83 ec 08             	sub    $0x8,%esp
f0102cb9:	89 d8                	mov    %ebx,%eax
f0102cbb:	c1 e0 0c             	shl    $0xc,%eax
f0102cbe:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102cc1:	50                   	push   %eax
f0102cc2:	ff 77 5c             	pushl  0x5c(%edi)
f0102cc5:	e8 d7 e2 ff ff       	call   f0100fa1 <page_remove>
f0102cca:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102ccd:	83 c3 01             	add    $0x1,%ebx
f0102cd0:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102cd6:	75 d4                	jne    f0102cac <env_free+0xbf>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102cd8:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102cdb:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102cde:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ce5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102ce8:	3b 05 44 4c 17 f0    	cmp    0xf0174c44,%eax
f0102cee:	72 14                	jb     f0102d04 <env_free+0x117>
		panic("pa2page called with invalid pa");
f0102cf0:	83 ec 04             	sub    $0x4,%esp
f0102cf3:	68 0c 4c 10 f0       	push   $0xf0104c0c
f0102cf8:	6a 4f                	push   $0x4f
f0102cfa:	68 b5 52 10 f0       	push   $0xf01052b5
f0102cff:	e8 9c d3 ff ff       	call   f01000a0 <_panic>
		page_decref(pa2page(pa));
f0102d04:	83 ec 0c             	sub    $0xc,%esp
f0102d07:	a1 4c 4c 17 f0       	mov    0xf0174c4c,%eax
f0102d0c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102d0f:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0102d12:	50                   	push   %eax
f0102d13:	e8 f2 e0 ff ff       	call   f0100e0a <page_decref>
f0102d18:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d1b:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102d1f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d22:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102d27:	0f 85 29 ff ff ff    	jne    f0102c56 <env_free+0x69>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102d2d:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d30:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d35:	77 15                	ja     f0102d4c <env_free+0x15f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d37:	50                   	push   %eax
f0102d38:	68 68 4c 10 f0       	push   $0xf0104c68
f0102d3d:	68 d3 01 00 00       	push   $0x1d3
f0102d42:	68 c9 55 10 f0       	push   $0xf01055c9
f0102d47:	e8 54 d3 ff ff       	call   f01000a0 <_panic>
	e->env_pgdir = 0;
f0102d4c:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d53:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d58:	c1 e8 0c             	shr    $0xc,%eax
f0102d5b:	3b 05 44 4c 17 f0    	cmp    0xf0174c44,%eax
f0102d61:	72 14                	jb     f0102d77 <env_free+0x18a>
		panic("pa2page called with invalid pa");
f0102d63:	83 ec 04             	sub    $0x4,%esp
f0102d66:	68 0c 4c 10 f0       	push   $0xf0104c0c
f0102d6b:	6a 4f                	push   $0x4f
f0102d6d:	68 b5 52 10 f0       	push   $0xf01052b5
f0102d72:	e8 29 d3 ff ff       	call   f01000a0 <_panic>
	page_decref(pa2page(pa));
f0102d77:	83 ec 0c             	sub    $0xc,%esp
f0102d7a:	8b 15 4c 4c 17 f0    	mov    0xf0174c4c,%edx
f0102d80:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0102d83:	50                   	push   %eax
f0102d84:	e8 81 e0 ff ff       	call   f0100e0a <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102d89:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102d90:	a1 8c 3f 17 f0       	mov    0xf0173f8c,%eax
f0102d95:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102d98:	89 3d 8c 3f 17 f0    	mov    %edi,0xf0173f8c
}
f0102d9e:	83 c4 10             	add    $0x10,%esp
f0102da1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102da4:	5b                   	pop    %ebx
f0102da5:	5e                   	pop    %esi
f0102da6:	5f                   	pop    %edi
f0102da7:	5d                   	pop    %ebp
f0102da8:	c3                   	ret    

f0102da9 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102da9:	55                   	push   %ebp
f0102daa:	89 e5                	mov    %esp,%ebp
f0102dac:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102daf:	ff 75 08             	pushl  0x8(%ebp)
f0102db2:	e8 36 fe ff ff       	call   f0102bed <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102db7:	c7 04 24 64 56 10 f0 	movl   $0xf0105664,(%esp)
f0102dbe:	e8 16 01 00 00       	call   f0102ed9 <cprintf>
f0102dc3:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102dc6:	83 ec 0c             	sub    $0xc,%esp
f0102dc9:	6a 00                	push   $0x0
f0102dcb:	e8 15 da ff ff       	call   f01007e5 <monitor>
f0102dd0:	83 c4 10             	add    $0x10,%esp
f0102dd3:	eb f1                	jmp    f0102dc6 <env_destroy+0x1d>

f0102dd5 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102dd5:	55                   	push   %ebp
f0102dd6:	89 e5                	mov    %esp,%ebp
f0102dd8:	83 ec 0c             	sub    $0xc,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102ddb:	8b 65 08             	mov    0x8(%ebp),%esp
f0102dde:	61                   	popa   
f0102ddf:	07                   	pop    %es
f0102de0:	1f                   	pop    %ds
f0102de1:	83 c4 08             	add    $0x8,%esp
f0102de4:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102de5:	68 51 56 10 f0       	push   $0xf0105651
f0102dea:	68 fb 01 00 00       	push   $0x1fb
f0102def:	68 c9 55 10 f0       	push   $0xf01055c9
f0102df4:	e8 a7 d2 ff ff       	call   f01000a0 <_panic>

f0102df9 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102df9:	55                   	push   %ebp
f0102dfa:	89 e5                	mov    %esp,%ebp
f0102dfc:	53                   	push   %ebx
f0102dfd:	83 ec 04             	sub    $0x4,%esp
f0102e00:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv && curenv->env_status == ENV_RUNNING)
f0102e03:	a1 84 3f 17 f0       	mov    0xf0173f84,%eax
f0102e08:	85 c0                	test   %eax,%eax
f0102e0a:	74 0d                	je     f0102e19 <env_run+0x20>
f0102e0c:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0102e10:	75 07                	jne    f0102e19 <env_run+0x20>
		curenv->env_status = ENV_RUNNABLE;
f0102e12:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	curenv = e;
f0102e19:	89 1d 84 3f 17 f0    	mov    %ebx,0xf0173f84
	curenv->env_status = ENV_RUNNING;
f0102e1f:	c7 43 54 03 00 00 00 	movl   $0x3,0x54(%ebx)
	curenv->env_runs++;
f0102e26:	83 43 58 01          	addl   $0x1,0x58(%ebx)
	cprintf("%o \n",(physaddr_t)curenv->env_pgdir);
f0102e2a:	83 ec 08             	sub    $0x8,%esp
f0102e2d:	ff 73 5c             	pushl  0x5c(%ebx)
f0102e30:	68 5d 56 10 f0       	push   $0xf010565d
f0102e35:	e8 9f 00 00 00       	call   f0102ed9 <cprintf>
	lcr3(PADDR(curenv->env_pgdir));
f0102e3a:	a1 84 3f 17 f0       	mov    0xf0173f84,%eax
f0102e3f:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e42:	83 c4 10             	add    $0x10,%esp
f0102e45:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e4a:	77 15                	ja     f0102e61 <env_run+0x68>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e4c:	50                   	push   %eax
f0102e4d:	68 68 4c 10 f0       	push   $0xf0104c68
f0102e52:	68 1f 02 00 00       	push   $0x21f
f0102e57:	68 c9 55 10 f0       	push   $0xf01055c9
f0102e5c:	e8 3f d2 ff ff       	call   f01000a0 <_panic>
f0102e61:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e66:	0f 22 d8             	mov    %eax,%cr3

	env_pop_tf(&e->env_tf);
f0102e69:	83 ec 0c             	sub    $0xc,%esp
f0102e6c:	53                   	push   %ebx
f0102e6d:	e8 63 ff ff ff       	call   f0102dd5 <env_pop_tf>

f0102e72 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102e72:	55                   	push   %ebp
f0102e73:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e75:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e7a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e7d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102e7e:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e83:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102e84:	0f b6 c0             	movzbl %al,%eax
}
f0102e87:	5d                   	pop    %ebp
f0102e88:	c3                   	ret    

f0102e89 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102e89:	55                   	push   %ebp
f0102e8a:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e8c:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e91:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e94:	ee                   	out    %al,(%dx)
f0102e95:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e9a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e9d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102e9e:	5d                   	pop    %ebp
f0102e9f:	c3                   	ret    

f0102ea0 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102ea0:	55                   	push   %ebp
f0102ea1:	89 e5                	mov    %esp,%ebp
f0102ea3:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102ea6:	ff 75 08             	pushl  0x8(%ebp)
f0102ea9:	e8 8c d7 ff ff       	call   f010063a <cputchar>
	*cnt++;
}
f0102eae:	83 c4 10             	add    $0x10,%esp
f0102eb1:	c9                   	leave  
f0102eb2:	c3                   	ret    

f0102eb3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102eb3:	55                   	push   %ebp
f0102eb4:	89 e5                	mov    %esp,%ebp
f0102eb6:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102eb9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102ec0:	ff 75 0c             	pushl  0xc(%ebp)
f0102ec3:	ff 75 08             	pushl  0x8(%ebp)
f0102ec6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102ec9:	50                   	push   %eax
f0102eca:	68 a0 2e 10 f0       	push   $0xf0102ea0
f0102ecf:	e8 00 0c 00 00       	call   f0103ad4 <vprintfmt>
	return cnt;
}
f0102ed4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102ed7:	c9                   	leave  
f0102ed8:	c3                   	ret    

f0102ed9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102ed9:	55                   	push   %ebp
f0102eda:	89 e5                	mov    %esp,%ebp
f0102edc:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102edf:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102ee2:	50                   	push   %eax
f0102ee3:	ff 75 08             	pushl  0x8(%ebp)
f0102ee6:	e8 c8 ff ff ff       	call   f0102eb3 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102eeb:	c9                   	leave  
f0102eec:	c3                   	ret    

f0102eed <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0102eed:	55                   	push   %ebp
f0102eee:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0102ef0:	b8 c0 47 17 f0       	mov    $0xf01747c0,%eax
f0102ef5:	c7 05 c4 47 17 f0 00 	movl   $0xf0000000,0xf01747c4
f0102efc:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0102eff:	66 c7 05 c8 47 17 f0 	movw   $0x10,0xf01747c8
f0102f06:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0102f08:	66 c7 05 48 a3 11 f0 	movw   $0x67,0xf011a348
f0102f0f:	67 00 
f0102f11:	66 a3 4a a3 11 f0    	mov    %ax,0xf011a34a
f0102f17:	89 c2                	mov    %eax,%edx
f0102f19:	c1 ea 10             	shr    $0x10,%edx
f0102f1c:	88 15 4c a3 11 f0    	mov    %dl,0xf011a34c
f0102f22:	c6 05 4e a3 11 f0 40 	movb   $0x40,0xf011a34e
f0102f29:	c1 e8 18             	shr    $0x18,%eax
f0102f2c:	a2 4f a3 11 f0       	mov    %al,0xf011a34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0102f31:	c6 05 4d a3 11 f0 89 	movb   $0x89,0xf011a34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0102f38:	b8 28 00 00 00       	mov    $0x28,%eax
f0102f3d:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0102f40:	b8 50 a3 11 f0       	mov    $0xf011a350,%eax
f0102f45:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0102f48:	5d                   	pop    %ebp
f0102f49:	c3                   	ret    

f0102f4a <trap_init>:
}


void
trap_init(void)
{
f0102f4a:	55                   	push   %ebp
f0102f4b:	89 e5                	mov    %esp,%ebp
	
	void floating_point_error();

	void system_call();

	SETGATE(idt[T_DIVIDE], 1, GD_KT, divide_error, 0);
f0102f4d:	b8 80 35 10 f0       	mov    $0xf0103580,%eax
f0102f52:	66 a3 a0 3f 17 f0    	mov    %ax,0xf0173fa0
f0102f58:	66 c7 05 a2 3f 17 f0 	movw   $0x8,0xf0173fa2
f0102f5f:	08 00 
f0102f61:	c6 05 a4 3f 17 f0 00 	movb   $0x0,0xf0173fa4
f0102f68:	c6 05 a5 3f 17 f0 8f 	movb   $0x8f,0xf0173fa5
f0102f6f:	c1 e8 10             	shr    $0x10,%eax
f0102f72:	66 a3 a6 3f 17 f0    	mov    %ax,0xf0173fa6
	SETGATE(idt[T_DEBUG], 1, GD_KT, debug_exception, 0);
f0102f78:	b8 86 35 10 f0       	mov    $0xf0103586,%eax
f0102f7d:	66 a3 a8 3f 17 f0    	mov    %ax,0xf0173fa8
f0102f83:	66 c7 05 aa 3f 17 f0 	movw   $0x8,0xf0173faa
f0102f8a:	08 00 
f0102f8c:	c6 05 ac 3f 17 f0 00 	movb   $0x0,0xf0173fac
f0102f93:	c6 05 ad 3f 17 f0 8f 	movb   $0x8f,0xf0173fad
f0102f9a:	c1 e8 10             	shr    $0x10,%eax
f0102f9d:	66 a3 ae 3f 17 f0    	mov    %ax,0xf0173fae
	SETGATE(idt[T_NMI], 1, GD_KT, non_maskable_interrupt, 0);
f0102fa3:	b8 8c 35 10 f0       	mov    $0xf010358c,%eax
f0102fa8:	66 a3 b0 3f 17 f0    	mov    %ax,0xf0173fb0
f0102fae:	66 c7 05 b2 3f 17 f0 	movw   $0x8,0xf0173fb2
f0102fb5:	08 00 
f0102fb7:	c6 05 b4 3f 17 f0 00 	movb   $0x0,0xf0173fb4
f0102fbe:	c6 05 b5 3f 17 f0 8f 	movb   $0x8f,0xf0173fb5
f0102fc5:	c1 e8 10             	shr    $0x10,%eax
f0102fc8:	66 a3 b6 3f 17 f0    	mov    %ax,0xf0173fb6
	SETGATE(idt[T_BRKPT], 1, GD_KT, break_point, 3);//!
f0102fce:	b8 92 35 10 f0       	mov    $0xf0103592,%eax
f0102fd3:	66 a3 b8 3f 17 f0    	mov    %ax,0xf0173fb8
f0102fd9:	66 c7 05 ba 3f 17 f0 	movw   $0x8,0xf0173fba
f0102fe0:	08 00 
f0102fe2:	c6 05 bc 3f 17 f0 00 	movb   $0x0,0xf0173fbc
f0102fe9:	c6 05 bd 3f 17 f0 ef 	movb   $0xef,0xf0173fbd
f0102ff0:	c1 e8 10             	shr    $0x10,%eax
f0102ff3:	66 a3 be 3f 17 f0    	mov    %ax,0xf0173fbe
	SETGATE(idt[T_OFLOW], 1, GD_KT, overflow, 0);
f0102ff9:	b8 98 35 10 f0       	mov    $0xf0103598,%eax
f0102ffe:	66 a3 c0 3f 17 f0    	mov    %ax,0xf0173fc0
f0103004:	66 c7 05 c2 3f 17 f0 	movw   $0x8,0xf0173fc2
f010300b:	08 00 
f010300d:	c6 05 c4 3f 17 f0 00 	movb   $0x0,0xf0173fc4
f0103014:	c6 05 c5 3f 17 f0 8f 	movb   $0x8f,0xf0173fc5
f010301b:	c1 e8 10             	shr    $0x10,%eax
f010301e:	66 a3 c6 3f 17 f0    	mov    %ax,0xf0173fc6
	SETGATE(idt[T_BOUND], 1, GD_KT, bounds_check, 0);
f0103024:	b8 9e 35 10 f0       	mov    $0xf010359e,%eax
f0103029:	66 a3 c8 3f 17 f0    	mov    %ax,0xf0173fc8
f010302f:	66 c7 05 ca 3f 17 f0 	movw   $0x8,0xf0173fca
f0103036:	08 00 
f0103038:	c6 05 cc 3f 17 f0 00 	movb   $0x0,0xf0173fcc
f010303f:	c6 05 cd 3f 17 f0 8f 	movb   $0x8f,0xf0173fcd
f0103046:	c1 e8 10             	shr    $0x10,%eax
f0103049:	66 a3 ce 3f 17 f0    	mov    %ax,0xf0173fce
	SETGATE(idt[T_ILLOP], 1, GD_KT, illegal_opcode, 0);
f010304f:	b8 a4 35 10 f0       	mov    $0xf01035a4,%eax
f0103054:	66 a3 d0 3f 17 f0    	mov    %ax,0xf0173fd0
f010305a:	66 c7 05 d2 3f 17 f0 	movw   $0x8,0xf0173fd2
f0103061:	08 00 
f0103063:	c6 05 d4 3f 17 f0 00 	movb   $0x0,0xf0173fd4
f010306a:	c6 05 d5 3f 17 f0 8f 	movb   $0x8f,0xf0173fd5
f0103071:	c1 e8 10             	shr    $0x10,%eax
f0103074:	66 a3 d6 3f 17 f0    	mov    %ax,0xf0173fd6
	SETGATE(idt[T_DEVICE], 1, GD_KT, device_not_available, 0);
f010307a:	b8 aa 35 10 f0       	mov    $0xf01035aa,%eax
f010307f:	66 a3 d8 3f 17 f0    	mov    %ax,0xf0173fd8
f0103085:	66 c7 05 da 3f 17 f0 	movw   $0x8,0xf0173fda
f010308c:	08 00 
f010308e:	c6 05 dc 3f 17 f0 00 	movb   $0x0,0xf0173fdc
f0103095:	c6 05 dd 3f 17 f0 8f 	movb   $0x8f,0xf0173fdd
f010309c:	c1 e8 10             	shr    $0x10,%eax
f010309f:	66 a3 de 3f 17 f0    	mov    %ax,0xf0173fde
	SETGATE(idt[T_DBLFLT], 1, GD_KT, double_fault, 0);
f01030a5:	b8 b0 35 10 f0       	mov    $0xf01035b0,%eax
f01030aa:	66 a3 e0 3f 17 f0    	mov    %ax,0xf0173fe0
f01030b0:	66 c7 05 e2 3f 17 f0 	movw   $0x8,0xf0173fe2
f01030b7:	08 00 
f01030b9:	c6 05 e4 3f 17 f0 00 	movb   $0x0,0xf0173fe4
f01030c0:	c6 05 e5 3f 17 f0 8f 	movb   $0x8f,0xf0173fe5
f01030c7:	c1 e8 10             	shr    $0x10,%eax
f01030ca:	66 a3 e6 3f 17 f0    	mov    %ax,0xf0173fe6

	SETGATE(idt[T_TSS], 1, GD_KT, invalid_task_switch_segment, 0);
f01030d0:	b8 b4 35 10 f0       	mov    $0xf01035b4,%eax
f01030d5:	66 a3 f0 3f 17 f0    	mov    %ax,0xf0173ff0
f01030db:	66 c7 05 f2 3f 17 f0 	movw   $0x8,0xf0173ff2
f01030e2:	08 00 
f01030e4:	c6 05 f4 3f 17 f0 00 	movb   $0x0,0xf0173ff4
f01030eb:	c6 05 f5 3f 17 f0 8f 	movb   $0x8f,0xf0173ff5
f01030f2:	c1 e8 10             	shr    $0x10,%eax
f01030f5:	66 a3 f6 3f 17 f0    	mov    %ax,0xf0173ff6
	SETGATE(idt[T_SEGNP], 1, GD_KT, segment_not_present, 0);
f01030fb:	b8 b8 35 10 f0       	mov    $0xf01035b8,%eax
f0103100:	66 a3 f8 3f 17 f0    	mov    %ax,0xf0173ff8
f0103106:	66 c7 05 fa 3f 17 f0 	movw   $0x8,0xf0173ffa
f010310d:	08 00 
f010310f:	c6 05 fc 3f 17 f0 00 	movb   $0x0,0xf0173ffc
f0103116:	c6 05 fd 3f 17 f0 8f 	movb   $0x8f,0xf0173ffd
f010311d:	c1 e8 10             	shr    $0x10,%eax
f0103120:	66 a3 fe 3f 17 f0    	mov    %ax,0xf0173ffe
	SETGATE(idt[T_STACK], 1, GD_KT, stack_exception, 0);
f0103126:	b8 bc 35 10 f0       	mov    $0xf01035bc,%eax
f010312b:	66 a3 00 40 17 f0    	mov    %ax,0xf0174000
f0103131:	66 c7 05 02 40 17 f0 	movw   $0x8,0xf0174002
f0103138:	08 00 
f010313a:	c6 05 04 40 17 f0 00 	movb   $0x0,0xf0174004
f0103141:	c6 05 05 40 17 f0 8f 	movb   $0x8f,0xf0174005
f0103148:	c1 e8 10             	shr    $0x10,%eax
f010314b:	66 a3 06 40 17 f0    	mov    %ax,0xf0174006
	SETGATE(idt[T_GPFLT], 1, GD_KT, general_protection_fault, 0);
f0103151:	b8 c0 35 10 f0       	mov    $0xf01035c0,%eax
f0103156:	66 a3 08 40 17 f0    	mov    %ax,0xf0174008
f010315c:	66 c7 05 0a 40 17 f0 	movw   $0x8,0xf017400a
f0103163:	08 00 
f0103165:	c6 05 0c 40 17 f0 00 	movb   $0x0,0xf017400c
f010316c:	c6 05 0d 40 17 f0 8f 	movb   $0x8f,0xf017400d
f0103173:	c1 e8 10             	shr    $0x10,%eax
f0103176:	66 a3 0e 40 17 f0    	mov    %ax,0xf017400e
	SETGATE(idt[T_PGFLT], 1, GD_KT, page_fault, 0);
f010317c:	b8 c4 35 10 f0       	mov    $0xf01035c4,%eax
f0103181:	66 a3 10 40 17 f0    	mov    %ax,0xf0174010
f0103187:	66 c7 05 12 40 17 f0 	movw   $0x8,0xf0174012
f010318e:	08 00 
f0103190:	c6 05 14 40 17 f0 00 	movb   $0x0,0xf0174014
f0103197:	c6 05 15 40 17 f0 8f 	movb   $0x8f,0xf0174015
f010319e:	c1 e8 10             	shr    $0x10,%eax
f01031a1:	66 a3 16 40 17 f0    	mov    %ax,0xf0174016

	SETGATE(idt[T_FPERR], 1, GD_KT, floating_point_error, 0);
f01031a7:	b8 c8 35 10 f0       	mov    $0xf01035c8,%eax
f01031ac:	66 a3 20 40 17 f0    	mov    %ax,0xf0174020
f01031b2:	66 c7 05 22 40 17 f0 	movw   $0x8,0xf0174022
f01031b9:	08 00 
f01031bb:	c6 05 24 40 17 f0 00 	movb   $0x0,0xf0174024
f01031c2:	c6 05 25 40 17 f0 8f 	movb   $0x8f,0xf0174025
f01031c9:	c1 e8 10             	shr    $0x10,%eax
f01031cc:	66 a3 26 40 17 f0    	mov    %ax,0xf0174026

	SETGATE(idt[T_SYSCALL], 0, GD_KT, system_call, 3);
f01031d2:	b8 ce 35 10 f0       	mov    $0xf01035ce,%eax
f01031d7:	66 a3 20 41 17 f0    	mov    %ax,0xf0174120
f01031dd:	66 c7 05 22 41 17 f0 	movw   $0x8,0xf0174122
f01031e4:	08 00 
f01031e6:	c6 05 24 41 17 f0 00 	movb   $0x0,0xf0174124
f01031ed:	c6 05 25 41 17 f0 ee 	movb   $0xee,0xf0174125
f01031f4:	c1 e8 10             	shr    $0x10,%eax
f01031f7:	66 a3 26 41 17 f0    	mov    %ax,0xf0174126

	// Per-CPU setup 
	trap_init_percpu();
f01031fd:	e8 eb fc ff ff       	call   f0102eed <trap_init_percpu>
}
f0103202:	5d                   	pop    %ebp
f0103203:	c3                   	ret    

f0103204 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103204:	55                   	push   %ebp
f0103205:	89 e5                	mov    %esp,%ebp
f0103207:	53                   	push   %ebx
f0103208:	83 ec 0c             	sub    $0xc,%esp
f010320b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f010320e:	ff 33                	pushl  (%ebx)
f0103210:	68 9a 56 10 f0       	push   $0xf010569a
f0103215:	e8 bf fc ff ff       	call   f0102ed9 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f010321a:	83 c4 08             	add    $0x8,%esp
f010321d:	ff 73 04             	pushl  0x4(%ebx)
f0103220:	68 a9 56 10 f0       	push   $0xf01056a9
f0103225:	e8 af fc ff ff       	call   f0102ed9 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f010322a:	83 c4 08             	add    $0x8,%esp
f010322d:	ff 73 08             	pushl  0x8(%ebx)
f0103230:	68 b8 56 10 f0       	push   $0xf01056b8
f0103235:	e8 9f fc ff ff       	call   f0102ed9 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f010323a:	83 c4 08             	add    $0x8,%esp
f010323d:	ff 73 0c             	pushl  0xc(%ebx)
f0103240:	68 c7 56 10 f0       	push   $0xf01056c7
f0103245:	e8 8f fc ff ff       	call   f0102ed9 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f010324a:	83 c4 08             	add    $0x8,%esp
f010324d:	ff 73 10             	pushl  0x10(%ebx)
f0103250:	68 d6 56 10 f0       	push   $0xf01056d6
f0103255:	e8 7f fc ff ff       	call   f0102ed9 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f010325a:	83 c4 08             	add    $0x8,%esp
f010325d:	ff 73 14             	pushl  0x14(%ebx)
f0103260:	68 e5 56 10 f0       	push   $0xf01056e5
f0103265:	e8 6f fc ff ff       	call   f0102ed9 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010326a:	83 c4 08             	add    $0x8,%esp
f010326d:	ff 73 18             	pushl  0x18(%ebx)
f0103270:	68 f4 56 10 f0       	push   $0xf01056f4
f0103275:	e8 5f fc ff ff       	call   f0102ed9 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f010327a:	83 c4 08             	add    $0x8,%esp
f010327d:	ff 73 1c             	pushl  0x1c(%ebx)
f0103280:	68 03 57 10 f0       	push   $0xf0105703
f0103285:	e8 4f fc ff ff       	call   f0102ed9 <cprintf>
}
f010328a:	83 c4 10             	add    $0x10,%esp
f010328d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103290:	c9                   	leave  
f0103291:	c3                   	ret    

f0103292 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103292:	55                   	push   %ebp
f0103293:	89 e5                	mov    %esp,%ebp
f0103295:	56                   	push   %esi
f0103296:	53                   	push   %ebx
f0103297:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f010329a:	83 ec 08             	sub    $0x8,%esp
f010329d:	53                   	push   %ebx
f010329e:	68 39 58 10 f0       	push   $0xf0105839
f01032a3:	e8 31 fc ff ff       	call   f0102ed9 <cprintf>
	print_regs(&tf->tf_regs);
f01032a8:	89 1c 24             	mov    %ebx,(%esp)
f01032ab:	e8 54 ff ff ff       	call   f0103204 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01032b0:	83 c4 08             	add    $0x8,%esp
f01032b3:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01032b7:	50                   	push   %eax
f01032b8:	68 54 57 10 f0       	push   $0xf0105754
f01032bd:	e8 17 fc ff ff       	call   f0102ed9 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01032c2:	83 c4 08             	add    $0x8,%esp
f01032c5:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01032c9:	50                   	push   %eax
f01032ca:	68 67 57 10 f0       	push   $0xf0105767
f01032cf:	e8 05 fc ff ff       	call   f0102ed9 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01032d4:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f01032d7:	83 c4 10             	add    $0x10,%esp
f01032da:	83 f8 13             	cmp    $0x13,%eax
f01032dd:	77 09                	ja     f01032e8 <print_trapframe+0x56>
		return excnames[trapno];
f01032df:	8b 14 85 00 5a 10 f0 	mov    -0xfefa600(,%eax,4),%edx
f01032e6:	eb 10                	jmp    f01032f8 <print_trapframe+0x66>
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
f01032e8:	83 f8 30             	cmp    $0x30,%eax
f01032eb:	b9 1e 57 10 f0       	mov    $0xf010571e,%ecx
f01032f0:	ba 12 57 10 f0       	mov    $0xf0105712,%edx
f01032f5:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01032f8:	83 ec 04             	sub    $0x4,%esp
f01032fb:	52                   	push   %edx
f01032fc:	50                   	push   %eax
f01032fd:	68 7a 57 10 f0       	push   $0xf010577a
f0103302:	e8 d2 fb ff ff       	call   f0102ed9 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103307:	83 c4 10             	add    $0x10,%esp
f010330a:	3b 1d a0 47 17 f0    	cmp    0xf01747a0,%ebx
f0103310:	75 1a                	jne    f010332c <print_trapframe+0x9a>
f0103312:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103316:	75 14                	jne    f010332c <print_trapframe+0x9a>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103318:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f010331b:	83 ec 08             	sub    $0x8,%esp
f010331e:	50                   	push   %eax
f010331f:	68 8c 57 10 f0       	push   $0xf010578c
f0103324:	e8 b0 fb ff ff       	call   f0102ed9 <cprintf>
f0103329:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f010332c:	83 ec 08             	sub    $0x8,%esp
f010332f:	ff 73 2c             	pushl  0x2c(%ebx)
f0103332:	68 9b 57 10 f0       	push   $0xf010579b
f0103337:	e8 9d fb ff ff       	call   f0102ed9 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f010333c:	83 c4 10             	add    $0x10,%esp
f010333f:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103343:	75 49                	jne    f010338e <print_trapframe+0xfc>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103345:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103348:	89 c2                	mov    %eax,%edx
f010334a:	83 e2 01             	and    $0x1,%edx
f010334d:	ba 38 57 10 f0       	mov    $0xf0105738,%edx
f0103352:	b9 2d 57 10 f0       	mov    $0xf010572d,%ecx
f0103357:	0f 44 ca             	cmove  %edx,%ecx
f010335a:	89 c2                	mov    %eax,%edx
f010335c:	83 e2 02             	and    $0x2,%edx
f010335f:	ba 4a 57 10 f0       	mov    $0xf010574a,%edx
f0103364:	be 44 57 10 f0       	mov    $0xf0105744,%esi
f0103369:	0f 45 d6             	cmovne %esi,%edx
f010336c:	83 e0 04             	and    $0x4,%eax
f010336f:	be 64 58 10 f0       	mov    $0xf0105864,%esi
f0103374:	b8 4f 57 10 f0       	mov    $0xf010574f,%eax
f0103379:	0f 44 c6             	cmove  %esi,%eax
f010337c:	51                   	push   %ecx
f010337d:	52                   	push   %edx
f010337e:	50                   	push   %eax
f010337f:	68 a9 57 10 f0       	push   $0xf01057a9
f0103384:	e8 50 fb ff ff       	call   f0102ed9 <cprintf>
f0103389:	83 c4 10             	add    $0x10,%esp
f010338c:	eb 10                	jmp    f010339e <print_trapframe+0x10c>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f010338e:	83 ec 0c             	sub    $0xc,%esp
f0103391:	68 e9 48 10 f0       	push   $0xf01048e9
f0103396:	e8 3e fb ff ff       	call   f0102ed9 <cprintf>
f010339b:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010339e:	83 ec 08             	sub    $0x8,%esp
f01033a1:	ff 73 30             	pushl  0x30(%ebx)
f01033a4:	68 b8 57 10 f0       	push   $0xf01057b8
f01033a9:	e8 2b fb ff ff       	call   f0102ed9 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01033ae:	83 c4 08             	add    $0x8,%esp
f01033b1:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f01033b5:	50                   	push   %eax
f01033b6:	68 c7 57 10 f0       	push   $0xf01057c7
f01033bb:	e8 19 fb ff ff       	call   f0102ed9 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01033c0:	83 c4 08             	add    $0x8,%esp
f01033c3:	ff 73 38             	pushl  0x38(%ebx)
f01033c6:	68 da 57 10 f0       	push   $0xf01057da
f01033cb:	e8 09 fb ff ff       	call   f0102ed9 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01033d0:	83 c4 10             	add    $0x10,%esp
f01033d3:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01033d7:	74 25                	je     f01033fe <print_trapframe+0x16c>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01033d9:	83 ec 08             	sub    $0x8,%esp
f01033dc:	ff 73 3c             	pushl  0x3c(%ebx)
f01033df:	68 e9 57 10 f0       	push   $0xf01057e9
f01033e4:	e8 f0 fa ff ff       	call   f0102ed9 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01033e9:	83 c4 08             	add    $0x8,%esp
f01033ec:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01033f0:	50                   	push   %eax
f01033f1:	68 f8 57 10 f0       	push   $0xf01057f8
f01033f6:	e8 de fa ff ff       	call   f0102ed9 <cprintf>
f01033fb:	83 c4 10             	add    $0x10,%esp
	}
}
f01033fe:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103401:	5b                   	pop    %ebx
f0103402:	5e                   	pop    %esi
f0103403:	5d                   	pop    %ebp
f0103404:	c3                   	ret    

f0103405 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103405:	55                   	push   %ebp
f0103406:	89 e5                	mov    %esp,%ebp
f0103408:	53                   	push   %ebx
f0103409:	83 ec 04             	sub    $0x4,%esp
f010340c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010340f:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103412:	ff 73 30             	pushl  0x30(%ebx)
f0103415:	50                   	push   %eax
f0103416:	a1 84 3f 17 f0       	mov    0xf0173f84,%eax
f010341b:	ff 70 48             	pushl  0x48(%eax)
f010341e:	68 b0 59 10 f0       	push   $0xf01059b0
f0103423:	e8 b1 fa ff ff       	call   f0102ed9 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103428:	89 1c 24             	mov    %ebx,(%esp)
f010342b:	e8 62 fe ff ff       	call   f0103292 <print_trapframe>
	env_destroy(curenv);
f0103430:	83 c4 04             	add    $0x4,%esp
f0103433:	ff 35 84 3f 17 f0    	pushl  0xf0173f84
f0103439:	e8 6b f9 ff ff       	call   f0102da9 <env_destroy>
}
f010343e:	83 c4 10             	add    $0x10,%esp
f0103441:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103444:	c9                   	leave  
f0103445:	c3                   	ret    

f0103446 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103446:	55                   	push   %ebp
f0103447:	89 e5                	mov    %esp,%ebp
f0103449:	57                   	push   %edi
f010344a:	56                   	push   %esi
f010344b:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f010344e:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f010344f:	9c                   	pushf  
f0103450:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103451:	f6 c4 02             	test   $0x2,%ah
f0103454:	74 19                	je     f010346f <trap+0x29>
f0103456:	68 0b 58 10 f0       	push   $0xf010580b
f010345b:	68 cf 52 10 f0       	push   $0xf01052cf
f0103460:	68 df 00 00 00       	push   $0xdf
f0103465:	68 24 58 10 f0       	push   $0xf0105824
f010346a:	e8 31 cc ff ff       	call   f01000a0 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f010346f:	83 ec 08             	sub    $0x8,%esp
f0103472:	56                   	push   %esi
f0103473:	68 30 58 10 f0       	push   $0xf0105830
f0103478:	e8 5c fa ff ff       	call   f0102ed9 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f010347d:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103481:	83 e0 03             	and    $0x3,%eax
f0103484:	83 c4 10             	add    $0x10,%esp
f0103487:	66 83 f8 03          	cmp    $0x3,%ax
f010348b:	75 31                	jne    f01034be <trap+0x78>
		// Trapped from user mode.
		assert(curenv);
f010348d:	a1 84 3f 17 f0       	mov    0xf0173f84,%eax
f0103492:	85 c0                	test   %eax,%eax
f0103494:	75 19                	jne    f01034af <trap+0x69>
f0103496:	68 4b 58 10 f0       	push   $0xf010584b
f010349b:	68 cf 52 10 f0       	push   $0xf01052cf
f01034a0:	68 e5 00 00 00       	push   $0xe5
f01034a5:	68 24 58 10 f0       	push   $0xf0105824
f01034aa:	e8 f1 cb ff ff       	call   f01000a0 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01034af:	b9 11 00 00 00       	mov    $0x11,%ecx
f01034b4:	89 c7                	mov    %eax,%edi
f01034b6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01034b8:	8b 35 84 3f 17 f0    	mov    0xf0173f84,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01034be:	89 35 a0 47 17 f0    	mov    %esi,0xf01747a0
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch (tf->tf_trapno)
f01034c4:	8b 46 28             	mov    0x28(%esi),%eax
f01034c7:	83 f8 0e             	cmp    $0xe,%eax
f01034ca:	74 0c                	je     f01034d8 <trap+0x92>
f01034cc:	83 f8 30             	cmp    $0x30,%eax
f01034cf:	74 23                	je     f01034f4 <trap+0xae>
f01034d1:	83 f8 03             	cmp    $0x3,%eax
f01034d4:	75 3e                	jne    f0103514 <trap+0xce>
f01034d6:	eb 0e                	jmp    f01034e6 <trap+0xa0>
	{
	case T_PGFLT:
		page_fault_handler(tf);
f01034d8:	83 ec 0c             	sub    $0xc,%esp
f01034db:	56                   	push   %esi
f01034dc:	e8 24 ff ff ff       	call   f0103405 <page_fault_handler>
f01034e1:	83 c4 10             	add    $0x10,%esp
f01034e4:	eb 69                	jmp    f010354f <trap+0x109>
		break;
	case T_BRKPT:
		monitor(tf);
f01034e6:	83 ec 0c             	sub    $0xc,%esp
f01034e9:	56                   	push   %esi
f01034ea:	e8 f6 d2 ff ff       	call   f01007e5 <monitor>
f01034ef:	83 c4 10             	add    $0x10,%esp
f01034f2:	eb 5b                	jmp    f010354f <trap+0x109>
		break;
	case T_SYSCALL:
		tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, 
f01034f4:	8b 46 18             	mov    0x18(%esi),%eax
f01034f7:	83 ec 08             	sub    $0x8,%esp
f01034fa:	ff 76 04             	pushl  0x4(%esi)
f01034fd:	ff 36                	pushl  (%esi)
f01034ff:	50                   	push   %eax
f0103500:	50                   	push   %eax
f0103501:	ff 76 14             	pushl  0x14(%esi)
f0103504:	ff 76 1c             	pushl  0x1c(%esi)
f0103507:	e8 da 00 00 00       	call   f01035e6 <syscall>
f010350c:	89 46 1c             	mov    %eax,0x1c(%esi)
f010350f:	83 c4 20             	add    $0x20,%esp
f0103512:	eb 3b                	jmp    f010354f <trap+0x109>
		tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx, tf->tf_regs.reg_ecx, 
		tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
		break;
	default:
		// Unexpected trap: The user process or the kernel has a bug.
		print_trapframe(tf);
f0103514:	83 ec 0c             	sub    $0xc,%esp
f0103517:	56                   	push   %esi
f0103518:	e8 75 fd ff ff       	call   f0103292 <print_trapframe>
		if (tf->tf_cs == GD_KT)
f010351d:	83 c4 10             	add    $0x10,%esp
f0103520:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103525:	75 17                	jne    f010353e <trap+0xf8>
			panic("unhandled trap in kernel");
f0103527:	83 ec 04             	sub    $0x4,%esp
f010352a:	68 52 58 10 f0       	push   $0xf0105852
f010352f:	68 cc 00 00 00       	push   $0xcc
f0103534:	68 24 58 10 f0       	push   $0xf0105824
f0103539:	e8 62 cb ff ff       	call   f01000a0 <_panic>
		else
		{
			env_destroy(curenv);
f010353e:	83 ec 0c             	sub    $0xc,%esp
f0103541:	ff 35 84 3f 17 f0    	pushl  0xf0173f84
f0103547:	e8 5d f8 ff ff       	call   f0102da9 <env_destroy>
f010354c:	83 c4 10             	add    $0x10,%esp

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f010354f:	a1 84 3f 17 f0       	mov    0xf0173f84,%eax
f0103554:	85 c0                	test   %eax,%eax
f0103556:	74 06                	je     f010355e <trap+0x118>
f0103558:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010355c:	74 19                	je     f0103577 <trap+0x131>
f010355e:	68 d4 59 10 f0       	push   $0xf01059d4
f0103563:	68 cf 52 10 f0       	push   $0xf01052cf
f0103568:	68 f7 00 00 00       	push   $0xf7
f010356d:	68 24 58 10 f0       	push   $0xf0105824
f0103572:	e8 29 cb ff ff       	call   f01000a0 <_panic>
	env_run(curenv);
f0103577:	83 ec 0c             	sub    $0xc,%esp
f010357a:	50                   	push   %eax
f010357b:	e8 79 f8 ff ff       	call   f0102df9 <env_run>

f0103580 <divide_error>:
 * Lab 3: Your code here for generating entry points for the different traps.
 */



	TRAPHANDLER_NOEC(divide_error, T_DIVIDE) 
f0103580:	6a 00                	push   $0x0
f0103582:	6a 00                	push   $0x0
f0103584:	eb 4e                	jmp    f01035d4 <_alltraps>

f0103586 <debug_exception>:
	TRAPHANDLER_NOEC(debug_exception, T_DEBUG) 
f0103586:	6a 00                	push   $0x0
f0103588:	6a 01                	push   $0x1
f010358a:	eb 48                	jmp    f01035d4 <_alltraps>

f010358c <non_maskable_interrupt>:
	TRAPHANDLER_NOEC(non_maskable_interrupt, T_NMI) 
f010358c:	6a 00                	push   $0x0
f010358e:	6a 02                	push   $0x2
f0103590:	eb 42                	jmp    f01035d4 <_alltraps>

f0103592 <break_point>:
	TRAPHANDLER_NOEC(break_point, T_BRKPT)// inc/x86.中有breakpoint同名函数
f0103592:	6a 00                	push   $0x0
f0103594:	6a 03                	push   $0x3
f0103596:	eb 3c                	jmp    f01035d4 <_alltraps>

f0103598 <overflow>:
	TRAPHANDLER_NOEC(overflow, T_OFLOW) 
f0103598:	6a 00                	push   $0x0
f010359a:	6a 04                	push   $0x4
f010359c:	eb 36                	jmp    f01035d4 <_alltraps>

f010359e <bounds_check>:
	TRAPHANDLER_NOEC(bounds_check, T_BOUND) 
f010359e:	6a 00                	push   $0x0
f01035a0:	6a 05                	push   $0x5
f01035a2:	eb 30                	jmp    f01035d4 <_alltraps>

f01035a4 <illegal_opcode>:
	TRAPHANDLER_NOEC(illegal_opcode, T_ILLOP) 
f01035a4:	6a 00                	push   $0x0
f01035a6:	6a 06                	push   $0x6
f01035a8:	eb 2a                	jmp    f01035d4 <_alltraps>

f01035aa <device_not_available>:
	TRAPHANDLER_NOEC(device_not_available, T_DEVICE) 
f01035aa:	6a 00                	push   $0x0
f01035ac:	6a 07                	push   $0x7
f01035ae:	eb 24                	jmp    f01035d4 <_alltraps>

f01035b0 <double_fault>:
	TRAPHANDLER(double_fault, T_DBLFLT) 
f01035b0:	6a 08                	push   $0x8
f01035b2:	eb 20                	jmp    f01035d4 <_alltraps>

f01035b4 <invalid_task_switch_segment>:

	TRAPHANDLER(invalid_task_switch_segment, T_TSS) 
f01035b4:	6a 0a                	push   $0xa
f01035b6:	eb 1c                	jmp    f01035d4 <_alltraps>

f01035b8 <segment_not_present>:
	TRAPHANDLER(segment_not_present, T_SEGNP) 
f01035b8:	6a 0b                	push   $0xb
f01035ba:	eb 18                	jmp    f01035d4 <_alltraps>

f01035bc <stack_exception>:
	TRAPHANDLER(stack_exception, T_STACK) 
f01035bc:	6a 0c                	push   $0xc
f01035be:	eb 14                	jmp    f01035d4 <_alltraps>

f01035c0 <general_protection_fault>:
	TRAPHANDLER(general_protection_fault, T_GPFLT) 
f01035c0:	6a 0d                	push   $0xd
f01035c2:	eb 10                	jmp    f01035d4 <_alltraps>

f01035c4 <page_fault>:
	TRAPHANDLER(page_fault, T_PGFLT) 
f01035c4:	6a 0e                	push   $0xe
f01035c6:	eb 0c                	jmp    f01035d4 <_alltraps>

f01035c8 <floating_point_error>:

	TRAPHANDLER_NOEC(floating_point_error, T_FPERR) 
f01035c8:	6a 00                	push   $0x0
f01035ca:	6a 10                	push   $0x10
f01035cc:	eb 06                	jmp    f01035d4 <_alltraps>

f01035ce <system_call>:
	//x86手册9.10中没有说明aligment check && machine check
	//&& SIMD floating point error是否返回error code，故没写上
	TRAPHANDLER_NOEC(system_call, T_SYSCALL)
f01035ce:	6a 00                	push   $0x0
f01035d0:	6a 30                	push   $0x30
f01035d2:	eb 00                	jmp    f01035d4 <_alltraps>

f01035d4 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
f01035d4:	1e                   	push   %ds
	pushl %es
f01035d5:	06                   	push   %es
	pushal
f01035d6:	60                   	pusha  

	mov $GD_KD,%eax
f01035d7:	b8 10 00 00 00       	mov    $0x10,%eax
	mov %eax,%ds
f01035dc:	8e d8                	mov    %eax,%ds
	mov %eax,%es
f01035de:	8e c0                	mov    %eax,%es
	
	pushl %esp  //压入trap()的参数tf，%esp指向Trapframe结构的起始地址
f01035e0:	54                   	push   %esp
f01035e1:	e8 60 fe ff ff       	call   f0103446 <trap>

f01035e6 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01035e6:	55                   	push   %ebp
f01035e7:	89 e5                	mov    %esp,%ebp
f01035e9:	83 ec 18             	sub    $0x18,%esp
f01035ec:	8b 45 08             	mov    0x8(%ebp),%eax
	// LAB 3: Your code here.

	//panic("syscall not implemented");
	int ret;

	switch (syscallno) {
f01035ef:	83 f8 01             	cmp    $0x1,%eax
f01035f2:	74 35                	je     f0103629 <syscall+0x43>
f01035f4:	83 f8 01             	cmp    $0x1,%eax
f01035f7:	72 13                	jb     f010360c <syscall+0x26>
f01035f9:	83 f8 02             	cmp    $0x2,%eax
f01035fc:	0f 84 93 00 00 00    	je     f0103695 <syscall+0xaf>
f0103602:	83 f8 03             	cmp    $0x3,%eax
f0103605:	74 29                	je     f0103630 <syscall+0x4a>
f0103607:	e9 93 00 00 00       	jmp    f010369f <syscall+0xb9>
	// Destroy the environment if not.

	// LAB 3: Your code here.

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f010360c:	83 ec 04             	sub    $0x4,%esp
f010360f:	ff 75 0c             	pushl  0xc(%ebp)
f0103612:	ff 75 10             	pushl  0x10(%ebp)
f0103615:	68 50 5a 10 f0       	push   $0xf0105a50
f010361a:	e8 ba f8 ff ff       	call   f0102ed9 <cprintf>
f010361f:	83 c4 10             	add    $0x10,%esp
	int ret;

	switch (syscallno) {
	case SYS_cputs:
		sys_cputs((const char*)a1,(size_t)a2);
		ret = 0;//其他函数都return 0
f0103622:	b8 00 00 00 00       	mov    $0x0,%eax
f0103627:	eb 7b                	jmp    f01036a4 <syscall+0xbe>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0103629:	e8 ba ce ff ff       	call   f01004e8 <cons_getc>
		sys_cputs((const char*)a1,(size_t)a2);
		ret = 0;//其他函数都return 0
		break;
	case SYS_cgetc:
		ret = sys_cgetc();
		break;
f010362e:	eb 74                	jmp    f01036a4 <syscall+0xbe>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103630:	83 ec 04             	sub    $0x4,%esp
f0103633:	6a 01                	push   $0x1
f0103635:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103638:	50                   	push   %eax
f0103639:	ff 75 0c             	pushl  0xc(%ebp)
f010363c:	e8 0b f2 ff ff       	call   f010284c <envid2env>
f0103641:	83 c4 10             	add    $0x10,%esp
f0103644:	85 c0                	test   %eax,%eax
f0103646:	78 5c                	js     f01036a4 <syscall+0xbe>
		return r;
	if (e == curenv)
f0103648:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010364b:	8b 15 84 3f 17 f0    	mov    0xf0173f84,%edx
f0103651:	39 d0                	cmp    %edx,%eax
f0103653:	75 15                	jne    f010366a <syscall+0x84>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103655:	83 ec 08             	sub    $0x8,%esp
f0103658:	ff 70 48             	pushl  0x48(%eax)
f010365b:	68 55 5a 10 f0       	push   $0xf0105a55
f0103660:	e8 74 f8 ff ff       	call   f0102ed9 <cprintf>
f0103665:	83 c4 10             	add    $0x10,%esp
f0103668:	eb 16                	jmp    f0103680 <syscall+0x9a>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010366a:	83 ec 04             	sub    $0x4,%esp
f010366d:	ff 70 48             	pushl  0x48(%eax)
f0103670:	ff 72 48             	pushl  0x48(%edx)
f0103673:	68 70 5a 10 f0       	push   $0xf0105a70
f0103678:	e8 5c f8 ff ff       	call   f0102ed9 <cprintf>
f010367d:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0103680:	83 ec 0c             	sub    $0xc,%esp
f0103683:	ff 75 f4             	pushl  -0xc(%ebp)
f0103686:	e8 1e f7 ff ff       	call   f0102da9 <env_destroy>
f010368b:	83 c4 10             	add    $0x10,%esp
	return 0;
f010368e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103693:	eb 0f                	jmp    f01036a4 <syscall+0xbe>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103695:	a1 84 3f 17 f0       	mov    0xf0173f84,%eax
f010369a:	8b 40 48             	mov    0x48(%eax),%eax
	case SYS_env_destroy:
		ret = sys_env_destroy((envid_t)a1);
		break;
	case SYS_getenvid:
		ret = sys_getenvid();
		break;
f010369d:	eb 05                	jmp    f01036a4 <syscall+0xbe>
	default:
		return -E_NO_SYS;
f010369f:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
	}
	return ret;
}
f01036a4:	c9                   	leave  
f01036a5:	c3                   	ret    

f01036a6 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01036a6:	55                   	push   %ebp
f01036a7:	89 e5                	mov    %esp,%ebp
f01036a9:	57                   	push   %edi
f01036aa:	56                   	push   %esi
f01036ab:	53                   	push   %ebx
f01036ac:	83 ec 14             	sub    $0x14,%esp
f01036af:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01036b2:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01036b5:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01036b8:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01036bb:	8b 1a                	mov    (%edx),%ebx
f01036bd:	8b 01                	mov    (%ecx),%eax
f01036bf:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01036c2:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01036c9:	eb 7f                	jmp    f010374a <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01036cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01036ce:	01 d8                	add    %ebx,%eax
f01036d0:	89 c6                	mov    %eax,%esi
f01036d2:	c1 ee 1f             	shr    $0x1f,%esi
f01036d5:	01 c6                	add    %eax,%esi
f01036d7:	d1 fe                	sar    %esi
f01036d9:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01036dc:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01036df:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01036e2:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01036e4:	eb 03                	jmp    f01036e9 <stab_binsearch+0x43>
			m--;
f01036e6:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01036e9:	39 c3                	cmp    %eax,%ebx
f01036eb:	7f 0d                	jg     f01036fa <stab_binsearch+0x54>
f01036ed:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01036f1:	83 ea 0c             	sub    $0xc,%edx
f01036f4:	39 f9                	cmp    %edi,%ecx
f01036f6:	75 ee                	jne    f01036e6 <stab_binsearch+0x40>
f01036f8:	eb 05                	jmp    f01036ff <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01036fa:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01036fd:	eb 4b                	jmp    f010374a <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01036ff:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103702:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103705:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103709:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010370c:	76 11                	jbe    f010371f <stab_binsearch+0x79>
			*region_left = m;
f010370e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103711:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103713:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103716:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010371d:	eb 2b                	jmp    f010374a <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010371f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103722:	73 14                	jae    f0103738 <stab_binsearch+0x92>
			*region_right = m - 1;
f0103724:	83 e8 01             	sub    $0x1,%eax
f0103727:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010372a:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010372d:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010372f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103736:	eb 12                	jmp    f010374a <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103738:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010373b:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010373d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103741:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103743:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010374a:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010374d:	0f 8e 78 ff ff ff    	jle    f01036cb <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103753:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103757:	75 0f                	jne    f0103768 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103759:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010375c:	8b 00                	mov    (%eax),%eax
f010375e:	83 e8 01             	sub    $0x1,%eax
f0103761:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103764:	89 06                	mov    %eax,(%esi)
f0103766:	eb 2c                	jmp    f0103794 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103768:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010376b:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010376d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103770:	8b 0e                	mov    (%esi),%ecx
f0103772:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103775:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103778:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010377b:	eb 03                	jmp    f0103780 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010377d:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103780:	39 c8                	cmp    %ecx,%eax
f0103782:	7e 0b                	jle    f010378f <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0103784:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103788:	83 ea 0c             	sub    $0xc,%edx
f010378b:	39 df                	cmp    %ebx,%edi
f010378d:	75 ee                	jne    f010377d <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f010378f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103792:	89 06                	mov    %eax,(%esi)
	}
}
f0103794:	83 c4 14             	add    $0x14,%esp
f0103797:	5b                   	pop    %ebx
f0103798:	5e                   	pop    %esi
f0103799:	5f                   	pop    %edi
f010379a:	5d                   	pop    %ebp
f010379b:	c3                   	ret    

f010379c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010379c:	55                   	push   %ebp
f010379d:	89 e5                	mov    %esp,%ebp
f010379f:	57                   	push   %edi
f01037a0:	56                   	push   %esi
f01037a1:	53                   	push   %ebx
f01037a2:	83 ec 3c             	sub    $0x3c,%esp
f01037a5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01037a8:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01037ab:	c7 06 88 5a 10 f0    	movl   $0xf0105a88,(%esi)
	info->eip_line = 0;
f01037b1:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01037b8:	c7 46 08 88 5a 10 f0 	movl   $0xf0105a88,0x8(%esi)
	info->eip_fn_namelen = 9;
f01037bf:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01037c6:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01037c9:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01037d0:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01037d6:	77 21                	ja     f01037f9 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f01037d8:	a1 00 00 20 00       	mov    0x200000,%eax
f01037dd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f01037e0:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f01037e5:	8b 1d 08 00 20 00    	mov    0x200008,%ebx
f01037eb:	89 5d cc             	mov    %ebx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f01037ee:	8b 1d 0c 00 20 00    	mov    0x20000c,%ebx
f01037f4:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f01037f7:	eb 1a                	jmp    f0103813 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01037f9:	c7 45 d0 95 fc 10 f0 	movl   $0xf010fc95,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103800:	c7 45 cc 95 d2 10 f0 	movl   $0xf010d295,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103807:	b8 94 d2 10 f0       	mov    $0xf010d294,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f010380c:	c7 45 d4 b0 5c 10 f0 	movl   $0xf0105cb0,-0x2c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103813:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103816:	39 4d cc             	cmp    %ecx,-0x34(%ebp)
f0103819:	0f 83 69 01 00 00    	jae    f0103988 <debuginfo_eip+0x1ec>
f010381f:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0103823:	0f 85 66 01 00 00    	jne    f010398f <debuginfo_eip+0x1f3>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103829:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103830:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103833:	29 d8                	sub    %ebx,%eax
f0103835:	c1 f8 02             	sar    $0x2,%eax
f0103838:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010383e:	83 e8 01             	sub    $0x1,%eax
f0103841:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103844:	57                   	push   %edi
f0103845:	6a 64                	push   $0x64
f0103847:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010384a:	89 c1                	mov    %eax,%ecx
f010384c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010384f:	89 d8                	mov    %ebx,%eax
f0103851:	e8 50 fe ff ff       	call   f01036a6 <stab_binsearch>
	if (lfile == 0)
f0103856:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103859:	83 c4 08             	add    $0x8,%esp
f010385c:	85 c0                	test   %eax,%eax
f010385e:	0f 84 32 01 00 00    	je     f0103996 <debuginfo_eip+0x1fa>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103864:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103867:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010386a:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010386d:	57                   	push   %edi
f010386e:	6a 24                	push   $0x24
f0103870:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0103873:	89 c1                	mov    %eax,%ecx
f0103875:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103878:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f010387b:	89 d8                	mov    %ebx,%eax
f010387d:	e8 24 fe ff ff       	call   f01036a6 <stab_binsearch>

	if (lfun <= rfun) {
f0103882:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103885:	83 c4 08             	add    $0x8,%esp
f0103888:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f010388b:	7f 25                	jg     f01038b2 <debuginfo_eip+0x116>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010388d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103890:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103893:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103896:	8b 02                	mov    (%edx),%eax
f0103898:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010389b:	2b 4d cc             	sub    -0x34(%ebp),%ecx
f010389e:	39 c8                	cmp    %ecx,%eax
f01038a0:	73 06                	jae    f01038a8 <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01038a2:	03 45 cc             	add    -0x34(%ebp),%eax
f01038a5:	89 46 08             	mov    %eax,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01038a8:	8b 42 08             	mov    0x8(%edx),%eax
f01038ab:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f01038ae:	29 c7                	sub    %eax,%edi
f01038b0:	eb 06                	jmp    f01038b8 <debuginfo_eip+0x11c>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01038b2:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f01038b5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01038b8:	83 ec 08             	sub    $0x8,%esp
f01038bb:	6a 3a                	push   $0x3a
f01038bd:	ff 76 08             	pushl  0x8(%esi)
f01038c0:	e8 5f 08 00 00       	call   f0104124 <strfind>
f01038c5:	2b 46 08             	sub    0x8(%esi),%eax
f01038c8:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
f01038cb:	83 c4 08             	add    $0x8,%esp
f01038ce:	2b 7e 10             	sub    0x10(%esi),%edi
f01038d1:	57                   	push   %edi
f01038d2:	6a 44                	push   $0x44
f01038d4:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01038d7:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01038da:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01038dd:	89 f8                	mov    %edi,%eax
f01038df:	e8 c2 fd ff ff       	call   f01036a6 <stab_binsearch>
	if (lfun > rfun) 
f01038e4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01038e7:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01038ea:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01038ed:	83 c4 10             	add    $0x10,%esp
f01038f0:	39 c8                	cmp    %ecx,%eax
f01038f2:	0f 8f a5 00 00 00    	jg     f010399d <debuginfo_eip+0x201>
       	  return -1;
        info->eip_line = stabs[lfun].n_desc;
f01038f8:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01038fb:	89 fa                	mov    %edi,%edx
f01038fd:	8d 04 87             	lea    (%edi,%eax,4),%eax
f0103900:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0103903:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f0103907:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010390a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010390d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103910:	8d 04 82             	lea    (%edx,%eax,4),%eax
f0103913:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0103916:	eb 06                	jmp    f010391e <debuginfo_eip+0x182>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103918:	83 eb 01             	sub    $0x1,%ebx
f010391b:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010391e:	39 fb                	cmp    %edi,%ebx
f0103920:	7c 32                	jl     f0103954 <debuginfo_eip+0x1b8>
	       && stabs[lline].n_type != N_SOL
f0103922:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0103926:	80 fa 84             	cmp    $0x84,%dl
f0103929:	74 0b                	je     f0103936 <debuginfo_eip+0x19a>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010392b:	80 fa 64             	cmp    $0x64,%dl
f010392e:	75 e8                	jne    f0103918 <debuginfo_eip+0x17c>
f0103930:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0103934:	74 e2                	je     f0103918 <debuginfo_eip+0x17c>
f0103936:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103939:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010393c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010393f:	8b 04 87             	mov    (%edi,%eax,4),%eax
f0103942:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0103945:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0103948:	29 fa                	sub    %edi,%edx
f010394a:	39 d0                	cmp    %edx,%eax
f010394c:	73 09                	jae    f0103957 <debuginfo_eip+0x1bb>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010394e:	01 f8                	add    %edi,%eax
f0103950:	89 06                	mov    %eax,(%esi)
f0103952:	eb 03                	jmp    f0103957 <debuginfo_eip+0x1bb>
f0103954:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103957:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010395c:	8b 7d c8             	mov    -0x38(%ebp),%edi
f010395f:	39 cf                	cmp    %ecx,%edi
f0103961:	7d 46                	jge    f01039a9 <debuginfo_eip+0x20d>
		for (lline = lfun + 1;
f0103963:	89 f8                	mov    %edi,%eax
f0103965:	83 c0 01             	add    $0x1,%eax
f0103968:	8b 55 c0             	mov    -0x40(%ebp),%edx
f010396b:	eb 07                	jmp    f0103974 <debuginfo_eip+0x1d8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010396d:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0103971:	83 c0 01             	add    $0x1,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103974:	39 c8                	cmp    %ecx,%eax
f0103976:	74 2c                	je     f01039a4 <debuginfo_eip+0x208>
f0103978:	83 c2 0c             	add    $0xc,%edx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010397b:	80 7a 04 a0          	cmpb   $0xa0,0x4(%edx)
f010397f:	74 ec                	je     f010396d <debuginfo_eip+0x1d1>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103981:	b8 00 00 00 00       	mov    $0x0,%eax
f0103986:	eb 21                	jmp    f01039a9 <debuginfo_eip+0x20d>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103988:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010398d:	eb 1a                	jmp    f01039a9 <debuginfo_eip+0x20d>
f010398f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103994:	eb 13                	jmp    f01039a9 <debuginfo_eip+0x20d>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103996:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010399b:	eb 0c                	jmp    f01039a9 <debuginfo_eip+0x20d>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
	if (lfun > rfun) 
       	  return -1;
f010399d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01039a2:	eb 05                	jmp    f01039a9 <debuginfo_eip+0x20d>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01039a4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01039a9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01039ac:	5b                   	pop    %ebx
f01039ad:	5e                   	pop    %esi
f01039ae:	5f                   	pop    %edi
f01039af:	5d                   	pop    %ebp
f01039b0:	c3                   	ret    

f01039b1 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01039b1:	55                   	push   %ebp
f01039b2:	89 e5                	mov    %esp,%ebp
f01039b4:	57                   	push   %edi
f01039b5:	56                   	push   %esi
f01039b6:	53                   	push   %ebx
f01039b7:	83 ec 1c             	sub    $0x1c,%esp
f01039ba:	89 c7                	mov    %eax,%edi
f01039bc:	89 d6                	mov    %edx,%esi
f01039be:	8b 45 08             	mov    0x8(%ebp),%eax
f01039c1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01039c4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01039c7:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01039ca:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01039cd:	bb 00 00 00 00       	mov    $0x0,%ebx
f01039d2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01039d5:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01039d8:	39 d3                	cmp    %edx,%ebx
f01039da:	72 05                	jb     f01039e1 <printnum+0x30>
f01039dc:	39 45 10             	cmp    %eax,0x10(%ebp)
f01039df:	77 45                	ja     f0103a26 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01039e1:	83 ec 0c             	sub    $0xc,%esp
f01039e4:	ff 75 18             	pushl  0x18(%ebp)
f01039e7:	8b 45 14             	mov    0x14(%ebp),%eax
f01039ea:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01039ed:	53                   	push   %ebx
f01039ee:	ff 75 10             	pushl  0x10(%ebp)
f01039f1:	83 ec 08             	sub    $0x8,%esp
f01039f4:	ff 75 e4             	pushl  -0x1c(%ebp)
f01039f7:	ff 75 e0             	pushl  -0x20(%ebp)
f01039fa:	ff 75 dc             	pushl  -0x24(%ebp)
f01039fd:	ff 75 d8             	pushl  -0x28(%ebp)
f0103a00:	e8 4b 09 00 00       	call   f0104350 <__udivdi3>
f0103a05:	83 c4 18             	add    $0x18,%esp
f0103a08:	52                   	push   %edx
f0103a09:	50                   	push   %eax
f0103a0a:	89 f2                	mov    %esi,%edx
f0103a0c:	89 f8                	mov    %edi,%eax
f0103a0e:	e8 9e ff ff ff       	call   f01039b1 <printnum>
f0103a13:	83 c4 20             	add    $0x20,%esp
f0103a16:	eb 18                	jmp    f0103a30 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103a18:	83 ec 08             	sub    $0x8,%esp
f0103a1b:	56                   	push   %esi
f0103a1c:	ff 75 18             	pushl  0x18(%ebp)
f0103a1f:	ff d7                	call   *%edi
f0103a21:	83 c4 10             	add    $0x10,%esp
f0103a24:	eb 03                	jmp    f0103a29 <printnum+0x78>
f0103a26:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103a29:	83 eb 01             	sub    $0x1,%ebx
f0103a2c:	85 db                	test   %ebx,%ebx
f0103a2e:	7f e8                	jg     f0103a18 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103a30:	83 ec 08             	sub    $0x8,%esp
f0103a33:	56                   	push   %esi
f0103a34:	83 ec 04             	sub    $0x4,%esp
f0103a37:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103a3a:	ff 75 e0             	pushl  -0x20(%ebp)
f0103a3d:	ff 75 dc             	pushl  -0x24(%ebp)
f0103a40:	ff 75 d8             	pushl  -0x28(%ebp)
f0103a43:	e8 38 0a 00 00       	call   f0104480 <__umoddi3>
f0103a48:	83 c4 14             	add    $0x14,%esp
f0103a4b:	0f be 80 92 5a 10 f0 	movsbl -0xfefa56e(%eax),%eax
f0103a52:	50                   	push   %eax
f0103a53:	ff d7                	call   *%edi
}
f0103a55:	83 c4 10             	add    $0x10,%esp
f0103a58:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103a5b:	5b                   	pop    %ebx
f0103a5c:	5e                   	pop    %esi
f0103a5d:	5f                   	pop    %edi
f0103a5e:	5d                   	pop    %ebp
f0103a5f:	c3                   	ret    

f0103a60 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103a60:	55                   	push   %ebp
f0103a61:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103a63:	83 fa 01             	cmp    $0x1,%edx
f0103a66:	7e 0e                	jle    f0103a76 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103a68:	8b 10                	mov    (%eax),%edx
f0103a6a:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103a6d:	89 08                	mov    %ecx,(%eax)
f0103a6f:	8b 02                	mov    (%edx),%eax
f0103a71:	8b 52 04             	mov    0x4(%edx),%edx
f0103a74:	eb 22                	jmp    f0103a98 <getuint+0x38>
	else if (lflag)
f0103a76:	85 d2                	test   %edx,%edx
f0103a78:	74 10                	je     f0103a8a <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103a7a:	8b 10                	mov    (%eax),%edx
f0103a7c:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103a7f:	89 08                	mov    %ecx,(%eax)
f0103a81:	8b 02                	mov    (%edx),%eax
f0103a83:	ba 00 00 00 00       	mov    $0x0,%edx
f0103a88:	eb 0e                	jmp    f0103a98 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103a8a:	8b 10                	mov    (%eax),%edx
f0103a8c:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103a8f:	89 08                	mov    %ecx,(%eax)
f0103a91:	8b 02                	mov    (%edx),%eax
f0103a93:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103a98:	5d                   	pop    %ebp
f0103a99:	c3                   	ret    

f0103a9a <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103a9a:	55                   	push   %ebp
f0103a9b:	89 e5                	mov    %esp,%ebp
f0103a9d:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103aa0:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103aa4:	8b 10                	mov    (%eax),%edx
f0103aa6:	3b 50 04             	cmp    0x4(%eax),%edx
f0103aa9:	73 0a                	jae    f0103ab5 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103aab:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103aae:	89 08                	mov    %ecx,(%eax)
f0103ab0:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ab3:	88 02                	mov    %al,(%edx)
}
f0103ab5:	5d                   	pop    %ebp
f0103ab6:	c3                   	ret    

f0103ab7 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103ab7:	55                   	push   %ebp
f0103ab8:	89 e5                	mov    %esp,%ebp
f0103aba:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103abd:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103ac0:	50                   	push   %eax
f0103ac1:	ff 75 10             	pushl  0x10(%ebp)
f0103ac4:	ff 75 0c             	pushl  0xc(%ebp)
f0103ac7:	ff 75 08             	pushl  0x8(%ebp)
f0103aca:	e8 05 00 00 00       	call   f0103ad4 <vprintfmt>
	va_end(ap);
}
f0103acf:	83 c4 10             	add    $0x10,%esp
f0103ad2:	c9                   	leave  
f0103ad3:	c3                   	ret    

f0103ad4 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103ad4:	55                   	push   %ebp
f0103ad5:	89 e5                	mov    %esp,%ebp
f0103ad7:	57                   	push   %edi
f0103ad8:	56                   	push   %esi
f0103ad9:	53                   	push   %ebx
f0103ada:	83 ec 2c             	sub    $0x2c,%esp
f0103add:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ae0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103ae3:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103ae6:	eb 12                	jmp    f0103afa <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103ae8:	85 c0                	test   %eax,%eax
f0103aea:	0f 84 89 03 00 00    	je     f0103e79 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0103af0:	83 ec 08             	sub    $0x8,%esp
f0103af3:	53                   	push   %ebx
f0103af4:	50                   	push   %eax
f0103af5:	ff d6                	call   *%esi
f0103af7:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103afa:	83 c7 01             	add    $0x1,%edi
f0103afd:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103b01:	83 f8 25             	cmp    $0x25,%eax
f0103b04:	75 e2                	jne    f0103ae8 <vprintfmt+0x14>
f0103b06:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103b0a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103b11:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103b18:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103b1f:	ba 00 00 00 00       	mov    $0x0,%edx
f0103b24:	eb 07                	jmp    f0103b2d <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b26:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103b29:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b2d:	8d 47 01             	lea    0x1(%edi),%eax
f0103b30:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103b33:	0f b6 07             	movzbl (%edi),%eax
f0103b36:	0f b6 c8             	movzbl %al,%ecx
f0103b39:	83 e8 23             	sub    $0x23,%eax
f0103b3c:	3c 55                	cmp    $0x55,%al
f0103b3e:	0f 87 1a 03 00 00    	ja     f0103e5e <vprintfmt+0x38a>
f0103b44:	0f b6 c0             	movzbl %al,%eax
f0103b47:	ff 24 85 20 5b 10 f0 	jmp    *-0xfefa4e0(,%eax,4)
f0103b4e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103b51:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103b55:	eb d6                	jmp    f0103b2d <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b57:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103b5a:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b5f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103b62:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103b65:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103b69:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103b6c:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103b6f:	83 fa 09             	cmp    $0x9,%edx
f0103b72:	77 39                	ja     f0103bad <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103b74:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103b77:	eb e9                	jmp    f0103b62 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103b79:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b7c:	8d 48 04             	lea    0x4(%eax),%ecx
f0103b7f:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103b82:	8b 00                	mov    (%eax),%eax
f0103b84:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b87:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103b8a:	eb 27                	jmp    f0103bb3 <vprintfmt+0xdf>
f0103b8c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103b8f:	85 c0                	test   %eax,%eax
f0103b91:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103b96:	0f 49 c8             	cmovns %eax,%ecx
f0103b99:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b9c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103b9f:	eb 8c                	jmp    f0103b2d <vprintfmt+0x59>
f0103ba1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103ba4:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103bab:	eb 80                	jmp    f0103b2d <vprintfmt+0x59>
f0103bad:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103bb0:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103bb3:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103bb7:	0f 89 70 ff ff ff    	jns    f0103b2d <vprintfmt+0x59>
				width = precision, precision = -1;
f0103bbd:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103bc0:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103bc3:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103bca:	e9 5e ff ff ff       	jmp    f0103b2d <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103bcf:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103bd2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103bd5:	e9 53 ff ff ff       	jmp    f0103b2d <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103bda:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bdd:	8d 50 04             	lea    0x4(%eax),%edx
f0103be0:	89 55 14             	mov    %edx,0x14(%ebp)
f0103be3:	83 ec 08             	sub    $0x8,%esp
f0103be6:	53                   	push   %ebx
f0103be7:	ff 30                	pushl  (%eax)
f0103be9:	ff d6                	call   *%esi
			break;
f0103beb:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103bee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103bf1:	e9 04 ff ff ff       	jmp    f0103afa <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103bf6:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bf9:	8d 50 04             	lea    0x4(%eax),%edx
f0103bfc:	89 55 14             	mov    %edx,0x14(%ebp)
f0103bff:	8b 00                	mov    (%eax),%eax
f0103c01:	99                   	cltd   
f0103c02:	31 d0                	xor    %edx,%eax
f0103c04:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103c06:	83 f8 07             	cmp    $0x7,%eax
f0103c09:	7f 0b                	jg     f0103c16 <vprintfmt+0x142>
f0103c0b:	8b 14 85 80 5c 10 f0 	mov    -0xfefa380(,%eax,4),%edx
f0103c12:	85 d2                	test   %edx,%edx
f0103c14:	75 18                	jne    f0103c2e <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103c16:	50                   	push   %eax
f0103c17:	68 aa 5a 10 f0       	push   $0xf0105aaa
f0103c1c:	53                   	push   %ebx
f0103c1d:	56                   	push   %esi
f0103c1e:	e8 94 fe ff ff       	call   f0103ab7 <printfmt>
f0103c23:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c26:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103c29:	e9 cc fe ff ff       	jmp    f0103afa <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103c2e:	52                   	push   %edx
f0103c2f:	68 e1 52 10 f0       	push   $0xf01052e1
f0103c34:	53                   	push   %ebx
f0103c35:	56                   	push   %esi
f0103c36:	e8 7c fe ff ff       	call   f0103ab7 <printfmt>
f0103c3b:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c3e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c41:	e9 b4 fe ff ff       	jmp    f0103afa <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103c46:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c49:	8d 50 04             	lea    0x4(%eax),%edx
f0103c4c:	89 55 14             	mov    %edx,0x14(%ebp)
f0103c4f:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103c51:	85 ff                	test   %edi,%edi
f0103c53:	b8 a3 5a 10 f0       	mov    $0xf0105aa3,%eax
f0103c58:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103c5b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103c5f:	0f 8e 94 00 00 00    	jle    f0103cf9 <vprintfmt+0x225>
f0103c65:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103c69:	0f 84 98 00 00 00    	je     f0103d07 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103c6f:	83 ec 08             	sub    $0x8,%esp
f0103c72:	ff 75 d0             	pushl  -0x30(%ebp)
f0103c75:	57                   	push   %edi
f0103c76:	e8 5f 03 00 00       	call   f0103fda <strnlen>
f0103c7b:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103c7e:	29 c1                	sub    %eax,%ecx
f0103c80:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103c83:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103c86:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103c8a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103c8d:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103c90:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103c92:	eb 0f                	jmp    f0103ca3 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103c94:	83 ec 08             	sub    $0x8,%esp
f0103c97:	53                   	push   %ebx
f0103c98:	ff 75 e0             	pushl  -0x20(%ebp)
f0103c9b:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103c9d:	83 ef 01             	sub    $0x1,%edi
f0103ca0:	83 c4 10             	add    $0x10,%esp
f0103ca3:	85 ff                	test   %edi,%edi
f0103ca5:	7f ed                	jg     f0103c94 <vprintfmt+0x1c0>
f0103ca7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103caa:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103cad:	85 c9                	test   %ecx,%ecx
f0103caf:	b8 00 00 00 00       	mov    $0x0,%eax
f0103cb4:	0f 49 c1             	cmovns %ecx,%eax
f0103cb7:	29 c1                	sub    %eax,%ecx
f0103cb9:	89 75 08             	mov    %esi,0x8(%ebp)
f0103cbc:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103cbf:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103cc2:	89 cb                	mov    %ecx,%ebx
f0103cc4:	eb 4d                	jmp    f0103d13 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103cc6:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103cca:	74 1b                	je     f0103ce7 <vprintfmt+0x213>
f0103ccc:	0f be c0             	movsbl %al,%eax
f0103ccf:	83 e8 20             	sub    $0x20,%eax
f0103cd2:	83 f8 5e             	cmp    $0x5e,%eax
f0103cd5:	76 10                	jbe    f0103ce7 <vprintfmt+0x213>
					putch('?', putdat);
f0103cd7:	83 ec 08             	sub    $0x8,%esp
f0103cda:	ff 75 0c             	pushl  0xc(%ebp)
f0103cdd:	6a 3f                	push   $0x3f
f0103cdf:	ff 55 08             	call   *0x8(%ebp)
f0103ce2:	83 c4 10             	add    $0x10,%esp
f0103ce5:	eb 0d                	jmp    f0103cf4 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103ce7:	83 ec 08             	sub    $0x8,%esp
f0103cea:	ff 75 0c             	pushl  0xc(%ebp)
f0103ced:	52                   	push   %edx
f0103cee:	ff 55 08             	call   *0x8(%ebp)
f0103cf1:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103cf4:	83 eb 01             	sub    $0x1,%ebx
f0103cf7:	eb 1a                	jmp    f0103d13 <vprintfmt+0x23f>
f0103cf9:	89 75 08             	mov    %esi,0x8(%ebp)
f0103cfc:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103cff:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103d02:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103d05:	eb 0c                	jmp    f0103d13 <vprintfmt+0x23f>
f0103d07:	89 75 08             	mov    %esi,0x8(%ebp)
f0103d0a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103d0d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103d10:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103d13:	83 c7 01             	add    $0x1,%edi
f0103d16:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103d1a:	0f be d0             	movsbl %al,%edx
f0103d1d:	85 d2                	test   %edx,%edx
f0103d1f:	74 23                	je     f0103d44 <vprintfmt+0x270>
f0103d21:	85 f6                	test   %esi,%esi
f0103d23:	78 a1                	js     f0103cc6 <vprintfmt+0x1f2>
f0103d25:	83 ee 01             	sub    $0x1,%esi
f0103d28:	79 9c                	jns    f0103cc6 <vprintfmt+0x1f2>
f0103d2a:	89 df                	mov    %ebx,%edi
f0103d2c:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d2f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103d32:	eb 18                	jmp    f0103d4c <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103d34:	83 ec 08             	sub    $0x8,%esp
f0103d37:	53                   	push   %ebx
f0103d38:	6a 20                	push   $0x20
f0103d3a:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103d3c:	83 ef 01             	sub    $0x1,%edi
f0103d3f:	83 c4 10             	add    $0x10,%esp
f0103d42:	eb 08                	jmp    f0103d4c <vprintfmt+0x278>
f0103d44:	89 df                	mov    %ebx,%edi
f0103d46:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d49:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103d4c:	85 ff                	test   %edi,%edi
f0103d4e:	7f e4                	jg     f0103d34 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d50:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d53:	e9 a2 fd ff ff       	jmp    f0103afa <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103d58:	83 fa 01             	cmp    $0x1,%edx
f0103d5b:	7e 16                	jle    f0103d73 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103d5d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d60:	8d 50 08             	lea    0x8(%eax),%edx
f0103d63:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d66:	8b 50 04             	mov    0x4(%eax),%edx
f0103d69:	8b 00                	mov    (%eax),%eax
f0103d6b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103d6e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103d71:	eb 32                	jmp    f0103da5 <vprintfmt+0x2d1>
	else if (lflag)
f0103d73:	85 d2                	test   %edx,%edx
f0103d75:	74 18                	je     f0103d8f <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0103d77:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d7a:	8d 50 04             	lea    0x4(%eax),%edx
f0103d7d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d80:	8b 00                	mov    (%eax),%eax
f0103d82:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103d85:	89 c1                	mov    %eax,%ecx
f0103d87:	c1 f9 1f             	sar    $0x1f,%ecx
f0103d8a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0103d8d:	eb 16                	jmp    f0103da5 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0103d8f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d92:	8d 50 04             	lea    0x4(%eax),%edx
f0103d95:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d98:	8b 00                	mov    (%eax),%eax
f0103d9a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103d9d:	89 c1                	mov    %eax,%ecx
f0103d9f:	c1 f9 1f             	sar    $0x1f,%ecx
f0103da2:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103da5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103da8:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103dab:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103db0:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103db4:	79 74                	jns    f0103e2a <vprintfmt+0x356>
				putch('-', putdat);
f0103db6:	83 ec 08             	sub    $0x8,%esp
f0103db9:	53                   	push   %ebx
f0103dba:	6a 2d                	push   $0x2d
f0103dbc:	ff d6                	call   *%esi
				num = -(long long) num;
f0103dbe:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103dc1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103dc4:	f7 d8                	neg    %eax
f0103dc6:	83 d2 00             	adc    $0x0,%edx
f0103dc9:	f7 da                	neg    %edx
f0103dcb:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103dce:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103dd3:	eb 55                	jmp    f0103e2a <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103dd5:	8d 45 14             	lea    0x14(%ebp),%eax
f0103dd8:	e8 83 fc ff ff       	call   f0103a60 <getuint>
			base = 10;
f0103ddd:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103de2:	eb 46                	jmp    f0103e2a <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0103de4:	8d 45 14             	lea    0x14(%ebp),%eax
f0103de7:	e8 74 fc ff ff       	call   f0103a60 <getuint>
			base = 8;
f0103dec:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103df1:	eb 37                	jmp    f0103e2a <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0103df3:	83 ec 08             	sub    $0x8,%esp
f0103df6:	53                   	push   %ebx
f0103df7:	6a 30                	push   $0x30
f0103df9:	ff d6                	call   *%esi
			putch('x', putdat);
f0103dfb:	83 c4 08             	add    $0x8,%esp
f0103dfe:	53                   	push   %ebx
f0103dff:	6a 78                	push   $0x78
f0103e01:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103e03:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e06:	8d 50 04             	lea    0x4(%eax),%edx
f0103e09:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103e0c:	8b 00                	mov    (%eax),%eax
f0103e0e:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103e13:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103e16:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103e1b:	eb 0d                	jmp    f0103e2a <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103e1d:	8d 45 14             	lea    0x14(%ebp),%eax
f0103e20:	e8 3b fc ff ff       	call   f0103a60 <getuint>
			base = 16;
f0103e25:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103e2a:	83 ec 0c             	sub    $0xc,%esp
f0103e2d:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103e31:	57                   	push   %edi
f0103e32:	ff 75 e0             	pushl  -0x20(%ebp)
f0103e35:	51                   	push   %ecx
f0103e36:	52                   	push   %edx
f0103e37:	50                   	push   %eax
f0103e38:	89 da                	mov    %ebx,%edx
f0103e3a:	89 f0                	mov    %esi,%eax
f0103e3c:	e8 70 fb ff ff       	call   f01039b1 <printnum>
			break;
f0103e41:	83 c4 20             	add    $0x20,%esp
f0103e44:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103e47:	e9 ae fc ff ff       	jmp    f0103afa <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103e4c:	83 ec 08             	sub    $0x8,%esp
f0103e4f:	53                   	push   %ebx
f0103e50:	51                   	push   %ecx
f0103e51:	ff d6                	call   *%esi
			break;
f0103e53:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103e56:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103e59:	e9 9c fc ff ff       	jmp    f0103afa <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103e5e:	83 ec 08             	sub    $0x8,%esp
f0103e61:	53                   	push   %ebx
f0103e62:	6a 25                	push   $0x25
f0103e64:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103e66:	83 c4 10             	add    $0x10,%esp
f0103e69:	eb 03                	jmp    f0103e6e <vprintfmt+0x39a>
f0103e6b:	83 ef 01             	sub    $0x1,%edi
f0103e6e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103e72:	75 f7                	jne    f0103e6b <vprintfmt+0x397>
f0103e74:	e9 81 fc ff ff       	jmp    f0103afa <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103e79:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103e7c:	5b                   	pop    %ebx
f0103e7d:	5e                   	pop    %esi
f0103e7e:	5f                   	pop    %edi
f0103e7f:	5d                   	pop    %ebp
f0103e80:	c3                   	ret    

f0103e81 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103e81:	55                   	push   %ebp
f0103e82:	89 e5                	mov    %esp,%ebp
f0103e84:	83 ec 18             	sub    $0x18,%esp
f0103e87:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e8a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103e8d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103e90:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103e94:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103e97:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103e9e:	85 c0                	test   %eax,%eax
f0103ea0:	74 26                	je     f0103ec8 <vsnprintf+0x47>
f0103ea2:	85 d2                	test   %edx,%edx
f0103ea4:	7e 22                	jle    f0103ec8 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103ea6:	ff 75 14             	pushl  0x14(%ebp)
f0103ea9:	ff 75 10             	pushl  0x10(%ebp)
f0103eac:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103eaf:	50                   	push   %eax
f0103eb0:	68 9a 3a 10 f0       	push   $0xf0103a9a
f0103eb5:	e8 1a fc ff ff       	call   f0103ad4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103eba:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103ebd:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103ec0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103ec3:	83 c4 10             	add    $0x10,%esp
f0103ec6:	eb 05                	jmp    f0103ecd <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103ec8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103ecd:	c9                   	leave  
f0103ece:	c3                   	ret    

f0103ecf <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103ecf:	55                   	push   %ebp
f0103ed0:	89 e5                	mov    %esp,%ebp
f0103ed2:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103ed5:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103ed8:	50                   	push   %eax
f0103ed9:	ff 75 10             	pushl  0x10(%ebp)
f0103edc:	ff 75 0c             	pushl  0xc(%ebp)
f0103edf:	ff 75 08             	pushl  0x8(%ebp)
f0103ee2:	e8 9a ff ff ff       	call   f0103e81 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103ee7:	c9                   	leave  
f0103ee8:	c3                   	ret    

f0103ee9 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103ee9:	55                   	push   %ebp
f0103eea:	89 e5                	mov    %esp,%ebp
f0103eec:	57                   	push   %edi
f0103eed:	56                   	push   %esi
f0103eee:	53                   	push   %ebx
f0103eef:	83 ec 0c             	sub    $0xc,%esp
f0103ef2:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103ef5:	85 c0                	test   %eax,%eax
f0103ef7:	74 11                	je     f0103f0a <readline+0x21>
		cprintf("%s", prompt);
f0103ef9:	83 ec 08             	sub    $0x8,%esp
f0103efc:	50                   	push   %eax
f0103efd:	68 e1 52 10 f0       	push   $0xf01052e1
f0103f02:	e8 d2 ef ff ff       	call   f0102ed9 <cprintf>
f0103f07:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103f0a:	83 ec 0c             	sub    $0xc,%esp
f0103f0d:	6a 00                	push   $0x0
f0103f0f:	e8 47 c7 ff ff       	call   f010065b <iscons>
f0103f14:	89 c7                	mov    %eax,%edi
f0103f16:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103f19:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103f1e:	e8 27 c7 ff ff       	call   f010064a <getchar>
f0103f23:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103f25:	85 c0                	test   %eax,%eax
f0103f27:	79 18                	jns    f0103f41 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103f29:	83 ec 08             	sub    $0x8,%esp
f0103f2c:	50                   	push   %eax
f0103f2d:	68 a0 5c 10 f0       	push   $0xf0105ca0
f0103f32:	e8 a2 ef ff ff       	call   f0102ed9 <cprintf>
			return NULL;
f0103f37:	83 c4 10             	add    $0x10,%esp
f0103f3a:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f3f:	eb 79                	jmp    f0103fba <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103f41:	83 f8 08             	cmp    $0x8,%eax
f0103f44:	0f 94 c2             	sete   %dl
f0103f47:	83 f8 7f             	cmp    $0x7f,%eax
f0103f4a:	0f 94 c0             	sete   %al
f0103f4d:	08 c2                	or     %al,%dl
f0103f4f:	74 1a                	je     f0103f6b <readline+0x82>
f0103f51:	85 f6                	test   %esi,%esi
f0103f53:	7e 16                	jle    f0103f6b <readline+0x82>
			if (echoing)
f0103f55:	85 ff                	test   %edi,%edi
f0103f57:	74 0d                	je     f0103f66 <readline+0x7d>
				cputchar('\b');
f0103f59:	83 ec 0c             	sub    $0xc,%esp
f0103f5c:	6a 08                	push   $0x8
f0103f5e:	e8 d7 c6 ff ff       	call   f010063a <cputchar>
f0103f63:	83 c4 10             	add    $0x10,%esp
			i--;
f0103f66:	83 ee 01             	sub    $0x1,%esi
f0103f69:	eb b3                	jmp    f0103f1e <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103f6b:	83 fb 1f             	cmp    $0x1f,%ebx
f0103f6e:	7e 23                	jle    f0103f93 <readline+0xaa>
f0103f70:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103f76:	7f 1b                	jg     f0103f93 <readline+0xaa>
			if (echoing)
f0103f78:	85 ff                	test   %edi,%edi
f0103f7a:	74 0c                	je     f0103f88 <readline+0x9f>
				cputchar(c);
f0103f7c:	83 ec 0c             	sub    $0xc,%esp
f0103f7f:	53                   	push   %ebx
f0103f80:	e8 b5 c6 ff ff       	call   f010063a <cputchar>
f0103f85:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103f88:	88 9e 40 48 17 f0    	mov    %bl,-0xfe8b7c0(%esi)
f0103f8e:	8d 76 01             	lea    0x1(%esi),%esi
f0103f91:	eb 8b                	jmp    f0103f1e <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103f93:	83 fb 0a             	cmp    $0xa,%ebx
f0103f96:	74 05                	je     f0103f9d <readline+0xb4>
f0103f98:	83 fb 0d             	cmp    $0xd,%ebx
f0103f9b:	75 81                	jne    f0103f1e <readline+0x35>
			if (echoing)
f0103f9d:	85 ff                	test   %edi,%edi
f0103f9f:	74 0d                	je     f0103fae <readline+0xc5>
				cputchar('\n');
f0103fa1:	83 ec 0c             	sub    $0xc,%esp
f0103fa4:	6a 0a                	push   $0xa
f0103fa6:	e8 8f c6 ff ff       	call   f010063a <cputchar>
f0103fab:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103fae:	c6 86 40 48 17 f0 00 	movb   $0x0,-0xfe8b7c0(%esi)
			return buf;
f0103fb5:	b8 40 48 17 f0       	mov    $0xf0174840,%eax
		}
	}
}
f0103fba:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103fbd:	5b                   	pop    %ebx
f0103fbe:	5e                   	pop    %esi
f0103fbf:	5f                   	pop    %edi
f0103fc0:	5d                   	pop    %ebp
f0103fc1:	c3                   	ret    

f0103fc2 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103fc2:	55                   	push   %ebp
f0103fc3:	89 e5                	mov    %esp,%ebp
f0103fc5:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103fc8:	b8 00 00 00 00       	mov    $0x0,%eax
f0103fcd:	eb 03                	jmp    f0103fd2 <strlen+0x10>
		n++;
f0103fcf:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103fd2:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103fd6:	75 f7                	jne    f0103fcf <strlen+0xd>
		n++;
	return n;
}
f0103fd8:	5d                   	pop    %ebp
f0103fd9:	c3                   	ret    

f0103fda <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103fda:	55                   	push   %ebp
f0103fdb:	89 e5                	mov    %esp,%ebp
f0103fdd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103fe0:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103fe3:	ba 00 00 00 00       	mov    $0x0,%edx
f0103fe8:	eb 03                	jmp    f0103fed <strnlen+0x13>
		n++;
f0103fea:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103fed:	39 c2                	cmp    %eax,%edx
f0103fef:	74 08                	je     f0103ff9 <strnlen+0x1f>
f0103ff1:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103ff5:	75 f3                	jne    f0103fea <strnlen+0x10>
f0103ff7:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103ff9:	5d                   	pop    %ebp
f0103ffa:	c3                   	ret    

f0103ffb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103ffb:	55                   	push   %ebp
f0103ffc:	89 e5                	mov    %esp,%ebp
f0103ffe:	53                   	push   %ebx
f0103fff:	8b 45 08             	mov    0x8(%ebp),%eax
f0104002:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104005:	89 c2                	mov    %eax,%edx
f0104007:	83 c2 01             	add    $0x1,%edx
f010400a:	83 c1 01             	add    $0x1,%ecx
f010400d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104011:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104014:	84 db                	test   %bl,%bl
f0104016:	75 ef                	jne    f0104007 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104018:	5b                   	pop    %ebx
f0104019:	5d                   	pop    %ebp
f010401a:	c3                   	ret    

f010401b <strcat>:

char *
strcat(char *dst, const char *src)
{
f010401b:	55                   	push   %ebp
f010401c:	89 e5                	mov    %esp,%ebp
f010401e:	53                   	push   %ebx
f010401f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104022:	53                   	push   %ebx
f0104023:	e8 9a ff ff ff       	call   f0103fc2 <strlen>
f0104028:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010402b:	ff 75 0c             	pushl  0xc(%ebp)
f010402e:	01 d8                	add    %ebx,%eax
f0104030:	50                   	push   %eax
f0104031:	e8 c5 ff ff ff       	call   f0103ffb <strcpy>
	return dst;
}
f0104036:	89 d8                	mov    %ebx,%eax
f0104038:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010403b:	c9                   	leave  
f010403c:	c3                   	ret    

f010403d <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010403d:	55                   	push   %ebp
f010403e:	89 e5                	mov    %esp,%ebp
f0104040:	56                   	push   %esi
f0104041:	53                   	push   %ebx
f0104042:	8b 75 08             	mov    0x8(%ebp),%esi
f0104045:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104048:	89 f3                	mov    %esi,%ebx
f010404a:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010404d:	89 f2                	mov    %esi,%edx
f010404f:	eb 0f                	jmp    f0104060 <strncpy+0x23>
		*dst++ = *src;
f0104051:	83 c2 01             	add    $0x1,%edx
f0104054:	0f b6 01             	movzbl (%ecx),%eax
f0104057:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010405a:	80 39 01             	cmpb   $0x1,(%ecx)
f010405d:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104060:	39 da                	cmp    %ebx,%edx
f0104062:	75 ed                	jne    f0104051 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104064:	89 f0                	mov    %esi,%eax
f0104066:	5b                   	pop    %ebx
f0104067:	5e                   	pop    %esi
f0104068:	5d                   	pop    %ebp
f0104069:	c3                   	ret    

f010406a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010406a:	55                   	push   %ebp
f010406b:	89 e5                	mov    %esp,%ebp
f010406d:	56                   	push   %esi
f010406e:	53                   	push   %ebx
f010406f:	8b 75 08             	mov    0x8(%ebp),%esi
f0104072:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104075:	8b 55 10             	mov    0x10(%ebp),%edx
f0104078:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010407a:	85 d2                	test   %edx,%edx
f010407c:	74 21                	je     f010409f <strlcpy+0x35>
f010407e:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104082:	89 f2                	mov    %esi,%edx
f0104084:	eb 09                	jmp    f010408f <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104086:	83 c2 01             	add    $0x1,%edx
f0104089:	83 c1 01             	add    $0x1,%ecx
f010408c:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010408f:	39 c2                	cmp    %eax,%edx
f0104091:	74 09                	je     f010409c <strlcpy+0x32>
f0104093:	0f b6 19             	movzbl (%ecx),%ebx
f0104096:	84 db                	test   %bl,%bl
f0104098:	75 ec                	jne    f0104086 <strlcpy+0x1c>
f010409a:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010409c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010409f:	29 f0                	sub    %esi,%eax
}
f01040a1:	5b                   	pop    %ebx
f01040a2:	5e                   	pop    %esi
f01040a3:	5d                   	pop    %ebp
f01040a4:	c3                   	ret    

f01040a5 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01040a5:	55                   	push   %ebp
f01040a6:	89 e5                	mov    %esp,%ebp
f01040a8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01040ab:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01040ae:	eb 06                	jmp    f01040b6 <strcmp+0x11>
		p++, q++;
f01040b0:	83 c1 01             	add    $0x1,%ecx
f01040b3:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01040b6:	0f b6 01             	movzbl (%ecx),%eax
f01040b9:	84 c0                	test   %al,%al
f01040bb:	74 04                	je     f01040c1 <strcmp+0x1c>
f01040bd:	3a 02                	cmp    (%edx),%al
f01040bf:	74 ef                	je     f01040b0 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01040c1:	0f b6 c0             	movzbl %al,%eax
f01040c4:	0f b6 12             	movzbl (%edx),%edx
f01040c7:	29 d0                	sub    %edx,%eax
}
f01040c9:	5d                   	pop    %ebp
f01040ca:	c3                   	ret    

f01040cb <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01040cb:	55                   	push   %ebp
f01040cc:	89 e5                	mov    %esp,%ebp
f01040ce:	53                   	push   %ebx
f01040cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01040d2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01040d5:	89 c3                	mov    %eax,%ebx
f01040d7:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01040da:	eb 06                	jmp    f01040e2 <strncmp+0x17>
		n--, p++, q++;
f01040dc:	83 c0 01             	add    $0x1,%eax
f01040df:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01040e2:	39 d8                	cmp    %ebx,%eax
f01040e4:	74 15                	je     f01040fb <strncmp+0x30>
f01040e6:	0f b6 08             	movzbl (%eax),%ecx
f01040e9:	84 c9                	test   %cl,%cl
f01040eb:	74 04                	je     f01040f1 <strncmp+0x26>
f01040ed:	3a 0a                	cmp    (%edx),%cl
f01040ef:	74 eb                	je     f01040dc <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01040f1:	0f b6 00             	movzbl (%eax),%eax
f01040f4:	0f b6 12             	movzbl (%edx),%edx
f01040f7:	29 d0                	sub    %edx,%eax
f01040f9:	eb 05                	jmp    f0104100 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01040fb:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104100:	5b                   	pop    %ebx
f0104101:	5d                   	pop    %ebp
f0104102:	c3                   	ret    

f0104103 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104103:	55                   	push   %ebp
f0104104:	89 e5                	mov    %esp,%ebp
f0104106:	8b 45 08             	mov    0x8(%ebp),%eax
f0104109:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010410d:	eb 07                	jmp    f0104116 <strchr+0x13>
		if (*s == c)
f010410f:	38 ca                	cmp    %cl,%dl
f0104111:	74 0f                	je     f0104122 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104113:	83 c0 01             	add    $0x1,%eax
f0104116:	0f b6 10             	movzbl (%eax),%edx
f0104119:	84 d2                	test   %dl,%dl
f010411b:	75 f2                	jne    f010410f <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010411d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104122:	5d                   	pop    %ebp
f0104123:	c3                   	ret    

f0104124 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104124:	55                   	push   %ebp
f0104125:	89 e5                	mov    %esp,%ebp
f0104127:	8b 45 08             	mov    0x8(%ebp),%eax
f010412a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010412e:	eb 03                	jmp    f0104133 <strfind+0xf>
f0104130:	83 c0 01             	add    $0x1,%eax
f0104133:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104136:	38 ca                	cmp    %cl,%dl
f0104138:	74 04                	je     f010413e <strfind+0x1a>
f010413a:	84 d2                	test   %dl,%dl
f010413c:	75 f2                	jne    f0104130 <strfind+0xc>
			break;
	return (char *) s;
}
f010413e:	5d                   	pop    %ebp
f010413f:	c3                   	ret    

f0104140 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104140:	55                   	push   %ebp
f0104141:	89 e5                	mov    %esp,%ebp
f0104143:	57                   	push   %edi
f0104144:	56                   	push   %esi
f0104145:	53                   	push   %ebx
f0104146:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104149:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010414c:	85 c9                	test   %ecx,%ecx
f010414e:	74 36                	je     f0104186 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104150:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104156:	75 28                	jne    f0104180 <memset+0x40>
f0104158:	f6 c1 03             	test   $0x3,%cl
f010415b:	75 23                	jne    f0104180 <memset+0x40>
		c &= 0xFF;
f010415d:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104161:	89 d3                	mov    %edx,%ebx
f0104163:	c1 e3 08             	shl    $0x8,%ebx
f0104166:	89 d6                	mov    %edx,%esi
f0104168:	c1 e6 18             	shl    $0x18,%esi
f010416b:	89 d0                	mov    %edx,%eax
f010416d:	c1 e0 10             	shl    $0x10,%eax
f0104170:	09 f0                	or     %esi,%eax
f0104172:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0104174:	89 d8                	mov    %ebx,%eax
f0104176:	09 d0                	or     %edx,%eax
f0104178:	c1 e9 02             	shr    $0x2,%ecx
f010417b:	fc                   	cld    
f010417c:	f3 ab                	rep stos %eax,%es:(%edi)
f010417e:	eb 06                	jmp    f0104186 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104180:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104183:	fc                   	cld    
f0104184:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104186:	89 f8                	mov    %edi,%eax
f0104188:	5b                   	pop    %ebx
f0104189:	5e                   	pop    %esi
f010418a:	5f                   	pop    %edi
f010418b:	5d                   	pop    %ebp
f010418c:	c3                   	ret    

f010418d <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010418d:	55                   	push   %ebp
f010418e:	89 e5                	mov    %esp,%ebp
f0104190:	57                   	push   %edi
f0104191:	56                   	push   %esi
f0104192:	8b 45 08             	mov    0x8(%ebp),%eax
f0104195:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104198:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010419b:	39 c6                	cmp    %eax,%esi
f010419d:	73 35                	jae    f01041d4 <memmove+0x47>
f010419f:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01041a2:	39 d0                	cmp    %edx,%eax
f01041a4:	73 2e                	jae    f01041d4 <memmove+0x47>
		s += n;
		d += n;
f01041a6:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01041a9:	89 d6                	mov    %edx,%esi
f01041ab:	09 fe                	or     %edi,%esi
f01041ad:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01041b3:	75 13                	jne    f01041c8 <memmove+0x3b>
f01041b5:	f6 c1 03             	test   $0x3,%cl
f01041b8:	75 0e                	jne    f01041c8 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01041ba:	83 ef 04             	sub    $0x4,%edi
f01041bd:	8d 72 fc             	lea    -0x4(%edx),%esi
f01041c0:	c1 e9 02             	shr    $0x2,%ecx
f01041c3:	fd                   	std    
f01041c4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01041c6:	eb 09                	jmp    f01041d1 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01041c8:	83 ef 01             	sub    $0x1,%edi
f01041cb:	8d 72 ff             	lea    -0x1(%edx),%esi
f01041ce:	fd                   	std    
f01041cf:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01041d1:	fc                   	cld    
f01041d2:	eb 1d                	jmp    f01041f1 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01041d4:	89 f2                	mov    %esi,%edx
f01041d6:	09 c2                	or     %eax,%edx
f01041d8:	f6 c2 03             	test   $0x3,%dl
f01041db:	75 0f                	jne    f01041ec <memmove+0x5f>
f01041dd:	f6 c1 03             	test   $0x3,%cl
f01041e0:	75 0a                	jne    f01041ec <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01041e2:	c1 e9 02             	shr    $0x2,%ecx
f01041e5:	89 c7                	mov    %eax,%edi
f01041e7:	fc                   	cld    
f01041e8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01041ea:	eb 05                	jmp    f01041f1 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01041ec:	89 c7                	mov    %eax,%edi
f01041ee:	fc                   	cld    
f01041ef:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01041f1:	5e                   	pop    %esi
f01041f2:	5f                   	pop    %edi
f01041f3:	5d                   	pop    %ebp
f01041f4:	c3                   	ret    

f01041f5 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01041f5:	55                   	push   %ebp
f01041f6:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01041f8:	ff 75 10             	pushl  0x10(%ebp)
f01041fb:	ff 75 0c             	pushl  0xc(%ebp)
f01041fe:	ff 75 08             	pushl  0x8(%ebp)
f0104201:	e8 87 ff ff ff       	call   f010418d <memmove>
}
f0104206:	c9                   	leave  
f0104207:	c3                   	ret    

f0104208 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104208:	55                   	push   %ebp
f0104209:	89 e5                	mov    %esp,%ebp
f010420b:	56                   	push   %esi
f010420c:	53                   	push   %ebx
f010420d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104210:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104213:	89 c6                	mov    %eax,%esi
f0104215:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104218:	eb 1a                	jmp    f0104234 <memcmp+0x2c>
		if (*s1 != *s2)
f010421a:	0f b6 08             	movzbl (%eax),%ecx
f010421d:	0f b6 1a             	movzbl (%edx),%ebx
f0104220:	38 d9                	cmp    %bl,%cl
f0104222:	74 0a                	je     f010422e <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104224:	0f b6 c1             	movzbl %cl,%eax
f0104227:	0f b6 db             	movzbl %bl,%ebx
f010422a:	29 d8                	sub    %ebx,%eax
f010422c:	eb 0f                	jmp    f010423d <memcmp+0x35>
		s1++, s2++;
f010422e:	83 c0 01             	add    $0x1,%eax
f0104231:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104234:	39 f0                	cmp    %esi,%eax
f0104236:	75 e2                	jne    f010421a <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104238:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010423d:	5b                   	pop    %ebx
f010423e:	5e                   	pop    %esi
f010423f:	5d                   	pop    %ebp
f0104240:	c3                   	ret    

f0104241 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104241:	55                   	push   %ebp
f0104242:	89 e5                	mov    %esp,%ebp
f0104244:	53                   	push   %ebx
f0104245:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104248:	89 c1                	mov    %eax,%ecx
f010424a:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010424d:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104251:	eb 0a                	jmp    f010425d <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104253:	0f b6 10             	movzbl (%eax),%edx
f0104256:	39 da                	cmp    %ebx,%edx
f0104258:	74 07                	je     f0104261 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010425a:	83 c0 01             	add    $0x1,%eax
f010425d:	39 c8                	cmp    %ecx,%eax
f010425f:	72 f2                	jb     f0104253 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104261:	5b                   	pop    %ebx
f0104262:	5d                   	pop    %ebp
f0104263:	c3                   	ret    

f0104264 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104264:	55                   	push   %ebp
f0104265:	89 e5                	mov    %esp,%ebp
f0104267:	57                   	push   %edi
f0104268:	56                   	push   %esi
f0104269:	53                   	push   %ebx
f010426a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010426d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104270:	eb 03                	jmp    f0104275 <strtol+0x11>
		s++;
f0104272:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104275:	0f b6 01             	movzbl (%ecx),%eax
f0104278:	3c 20                	cmp    $0x20,%al
f010427a:	74 f6                	je     f0104272 <strtol+0xe>
f010427c:	3c 09                	cmp    $0x9,%al
f010427e:	74 f2                	je     f0104272 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104280:	3c 2b                	cmp    $0x2b,%al
f0104282:	75 0a                	jne    f010428e <strtol+0x2a>
		s++;
f0104284:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104287:	bf 00 00 00 00       	mov    $0x0,%edi
f010428c:	eb 11                	jmp    f010429f <strtol+0x3b>
f010428e:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104293:	3c 2d                	cmp    $0x2d,%al
f0104295:	75 08                	jne    f010429f <strtol+0x3b>
		s++, neg = 1;
f0104297:	83 c1 01             	add    $0x1,%ecx
f010429a:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010429f:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01042a5:	75 15                	jne    f01042bc <strtol+0x58>
f01042a7:	80 39 30             	cmpb   $0x30,(%ecx)
f01042aa:	75 10                	jne    f01042bc <strtol+0x58>
f01042ac:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01042b0:	75 7c                	jne    f010432e <strtol+0xca>
		s += 2, base = 16;
f01042b2:	83 c1 02             	add    $0x2,%ecx
f01042b5:	bb 10 00 00 00       	mov    $0x10,%ebx
f01042ba:	eb 16                	jmp    f01042d2 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01042bc:	85 db                	test   %ebx,%ebx
f01042be:	75 12                	jne    f01042d2 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01042c0:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01042c5:	80 39 30             	cmpb   $0x30,(%ecx)
f01042c8:	75 08                	jne    f01042d2 <strtol+0x6e>
		s++, base = 8;
f01042ca:	83 c1 01             	add    $0x1,%ecx
f01042cd:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01042d2:	b8 00 00 00 00       	mov    $0x0,%eax
f01042d7:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01042da:	0f b6 11             	movzbl (%ecx),%edx
f01042dd:	8d 72 d0             	lea    -0x30(%edx),%esi
f01042e0:	89 f3                	mov    %esi,%ebx
f01042e2:	80 fb 09             	cmp    $0x9,%bl
f01042e5:	77 08                	ja     f01042ef <strtol+0x8b>
			dig = *s - '0';
f01042e7:	0f be d2             	movsbl %dl,%edx
f01042ea:	83 ea 30             	sub    $0x30,%edx
f01042ed:	eb 22                	jmp    f0104311 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01042ef:	8d 72 9f             	lea    -0x61(%edx),%esi
f01042f2:	89 f3                	mov    %esi,%ebx
f01042f4:	80 fb 19             	cmp    $0x19,%bl
f01042f7:	77 08                	ja     f0104301 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01042f9:	0f be d2             	movsbl %dl,%edx
f01042fc:	83 ea 57             	sub    $0x57,%edx
f01042ff:	eb 10                	jmp    f0104311 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104301:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104304:	89 f3                	mov    %esi,%ebx
f0104306:	80 fb 19             	cmp    $0x19,%bl
f0104309:	77 16                	ja     f0104321 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010430b:	0f be d2             	movsbl %dl,%edx
f010430e:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104311:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104314:	7d 0b                	jge    f0104321 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104316:	83 c1 01             	add    $0x1,%ecx
f0104319:	0f af 45 10          	imul   0x10(%ebp),%eax
f010431d:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010431f:	eb b9                	jmp    f01042da <strtol+0x76>

	if (endptr)
f0104321:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104325:	74 0d                	je     f0104334 <strtol+0xd0>
		*endptr = (char *) s;
f0104327:	8b 75 0c             	mov    0xc(%ebp),%esi
f010432a:	89 0e                	mov    %ecx,(%esi)
f010432c:	eb 06                	jmp    f0104334 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010432e:	85 db                	test   %ebx,%ebx
f0104330:	74 98                	je     f01042ca <strtol+0x66>
f0104332:	eb 9e                	jmp    f01042d2 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104334:	89 c2                	mov    %eax,%edx
f0104336:	f7 da                	neg    %edx
f0104338:	85 ff                	test   %edi,%edi
f010433a:	0f 45 c2             	cmovne %edx,%eax
}
f010433d:	5b                   	pop    %ebx
f010433e:	5e                   	pop    %esi
f010433f:	5f                   	pop    %edi
f0104340:	5d                   	pop    %ebp
f0104341:	c3                   	ret    
f0104342:	66 90                	xchg   %ax,%ax
f0104344:	66 90                	xchg   %ax,%ax
f0104346:	66 90                	xchg   %ax,%ax
f0104348:	66 90                	xchg   %ax,%ax
f010434a:	66 90                	xchg   %ax,%ax
f010434c:	66 90                	xchg   %ax,%ax
f010434e:	66 90                	xchg   %ax,%ax

f0104350 <__udivdi3>:
f0104350:	55                   	push   %ebp
f0104351:	57                   	push   %edi
f0104352:	56                   	push   %esi
f0104353:	53                   	push   %ebx
f0104354:	83 ec 1c             	sub    $0x1c,%esp
f0104357:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010435b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010435f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0104363:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104367:	85 f6                	test   %esi,%esi
f0104369:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010436d:	89 ca                	mov    %ecx,%edx
f010436f:	89 f8                	mov    %edi,%eax
f0104371:	75 3d                	jne    f01043b0 <__udivdi3+0x60>
f0104373:	39 cf                	cmp    %ecx,%edi
f0104375:	0f 87 c5 00 00 00    	ja     f0104440 <__udivdi3+0xf0>
f010437b:	85 ff                	test   %edi,%edi
f010437d:	89 fd                	mov    %edi,%ebp
f010437f:	75 0b                	jne    f010438c <__udivdi3+0x3c>
f0104381:	b8 01 00 00 00       	mov    $0x1,%eax
f0104386:	31 d2                	xor    %edx,%edx
f0104388:	f7 f7                	div    %edi
f010438a:	89 c5                	mov    %eax,%ebp
f010438c:	89 c8                	mov    %ecx,%eax
f010438e:	31 d2                	xor    %edx,%edx
f0104390:	f7 f5                	div    %ebp
f0104392:	89 c1                	mov    %eax,%ecx
f0104394:	89 d8                	mov    %ebx,%eax
f0104396:	89 cf                	mov    %ecx,%edi
f0104398:	f7 f5                	div    %ebp
f010439a:	89 c3                	mov    %eax,%ebx
f010439c:	89 d8                	mov    %ebx,%eax
f010439e:	89 fa                	mov    %edi,%edx
f01043a0:	83 c4 1c             	add    $0x1c,%esp
f01043a3:	5b                   	pop    %ebx
f01043a4:	5e                   	pop    %esi
f01043a5:	5f                   	pop    %edi
f01043a6:	5d                   	pop    %ebp
f01043a7:	c3                   	ret    
f01043a8:	90                   	nop
f01043a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01043b0:	39 ce                	cmp    %ecx,%esi
f01043b2:	77 74                	ja     f0104428 <__udivdi3+0xd8>
f01043b4:	0f bd fe             	bsr    %esi,%edi
f01043b7:	83 f7 1f             	xor    $0x1f,%edi
f01043ba:	0f 84 98 00 00 00    	je     f0104458 <__udivdi3+0x108>
f01043c0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01043c5:	89 f9                	mov    %edi,%ecx
f01043c7:	89 c5                	mov    %eax,%ebp
f01043c9:	29 fb                	sub    %edi,%ebx
f01043cb:	d3 e6                	shl    %cl,%esi
f01043cd:	89 d9                	mov    %ebx,%ecx
f01043cf:	d3 ed                	shr    %cl,%ebp
f01043d1:	89 f9                	mov    %edi,%ecx
f01043d3:	d3 e0                	shl    %cl,%eax
f01043d5:	09 ee                	or     %ebp,%esi
f01043d7:	89 d9                	mov    %ebx,%ecx
f01043d9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01043dd:	89 d5                	mov    %edx,%ebp
f01043df:	8b 44 24 08          	mov    0x8(%esp),%eax
f01043e3:	d3 ed                	shr    %cl,%ebp
f01043e5:	89 f9                	mov    %edi,%ecx
f01043e7:	d3 e2                	shl    %cl,%edx
f01043e9:	89 d9                	mov    %ebx,%ecx
f01043eb:	d3 e8                	shr    %cl,%eax
f01043ed:	09 c2                	or     %eax,%edx
f01043ef:	89 d0                	mov    %edx,%eax
f01043f1:	89 ea                	mov    %ebp,%edx
f01043f3:	f7 f6                	div    %esi
f01043f5:	89 d5                	mov    %edx,%ebp
f01043f7:	89 c3                	mov    %eax,%ebx
f01043f9:	f7 64 24 0c          	mull   0xc(%esp)
f01043fd:	39 d5                	cmp    %edx,%ebp
f01043ff:	72 10                	jb     f0104411 <__udivdi3+0xc1>
f0104401:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104405:	89 f9                	mov    %edi,%ecx
f0104407:	d3 e6                	shl    %cl,%esi
f0104409:	39 c6                	cmp    %eax,%esi
f010440b:	73 07                	jae    f0104414 <__udivdi3+0xc4>
f010440d:	39 d5                	cmp    %edx,%ebp
f010440f:	75 03                	jne    f0104414 <__udivdi3+0xc4>
f0104411:	83 eb 01             	sub    $0x1,%ebx
f0104414:	31 ff                	xor    %edi,%edi
f0104416:	89 d8                	mov    %ebx,%eax
f0104418:	89 fa                	mov    %edi,%edx
f010441a:	83 c4 1c             	add    $0x1c,%esp
f010441d:	5b                   	pop    %ebx
f010441e:	5e                   	pop    %esi
f010441f:	5f                   	pop    %edi
f0104420:	5d                   	pop    %ebp
f0104421:	c3                   	ret    
f0104422:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104428:	31 ff                	xor    %edi,%edi
f010442a:	31 db                	xor    %ebx,%ebx
f010442c:	89 d8                	mov    %ebx,%eax
f010442e:	89 fa                	mov    %edi,%edx
f0104430:	83 c4 1c             	add    $0x1c,%esp
f0104433:	5b                   	pop    %ebx
f0104434:	5e                   	pop    %esi
f0104435:	5f                   	pop    %edi
f0104436:	5d                   	pop    %ebp
f0104437:	c3                   	ret    
f0104438:	90                   	nop
f0104439:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104440:	89 d8                	mov    %ebx,%eax
f0104442:	f7 f7                	div    %edi
f0104444:	31 ff                	xor    %edi,%edi
f0104446:	89 c3                	mov    %eax,%ebx
f0104448:	89 d8                	mov    %ebx,%eax
f010444a:	89 fa                	mov    %edi,%edx
f010444c:	83 c4 1c             	add    $0x1c,%esp
f010444f:	5b                   	pop    %ebx
f0104450:	5e                   	pop    %esi
f0104451:	5f                   	pop    %edi
f0104452:	5d                   	pop    %ebp
f0104453:	c3                   	ret    
f0104454:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104458:	39 ce                	cmp    %ecx,%esi
f010445a:	72 0c                	jb     f0104468 <__udivdi3+0x118>
f010445c:	31 db                	xor    %ebx,%ebx
f010445e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0104462:	0f 87 34 ff ff ff    	ja     f010439c <__udivdi3+0x4c>
f0104468:	bb 01 00 00 00       	mov    $0x1,%ebx
f010446d:	e9 2a ff ff ff       	jmp    f010439c <__udivdi3+0x4c>
f0104472:	66 90                	xchg   %ax,%ax
f0104474:	66 90                	xchg   %ax,%ax
f0104476:	66 90                	xchg   %ax,%ax
f0104478:	66 90                	xchg   %ax,%ax
f010447a:	66 90                	xchg   %ax,%ax
f010447c:	66 90                	xchg   %ax,%ax
f010447e:	66 90                	xchg   %ax,%ax

f0104480 <__umoddi3>:
f0104480:	55                   	push   %ebp
f0104481:	57                   	push   %edi
f0104482:	56                   	push   %esi
f0104483:	53                   	push   %ebx
f0104484:	83 ec 1c             	sub    $0x1c,%esp
f0104487:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010448b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010448f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104493:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104497:	85 d2                	test   %edx,%edx
f0104499:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010449d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01044a1:	89 f3                	mov    %esi,%ebx
f01044a3:	89 3c 24             	mov    %edi,(%esp)
f01044a6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01044aa:	75 1c                	jne    f01044c8 <__umoddi3+0x48>
f01044ac:	39 f7                	cmp    %esi,%edi
f01044ae:	76 50                	jbe    f0104500 <__umoddi3+0x80>
f01044b0:	89 c8                	mov    %ecx,%eax
f01044b2:	89 f2                	mov    %esi,%edx
f01044b4:	f7 f7                	div    %edi
f01044b6:	89 d0                	mov    %edx,%eax
f01044b8:	31 d2                	xor    %edx,%edx
f01044ba:	83 c4 1c             	add    $0x1c,%esp
f01044bd:	5b                   	pop    %ebx
f01044be:	5e                   	pop    %esi
f01044bf:	5f                   	pop    %edi
f01044c0:	5d                   	pop    %ebp
f01044c1:	c3                   	ret    
f01044c2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01044c8:	39 f2                	cmp    %esi,%edx
f01044ca:	89 d0                	mov    %edx,%eax
f01044cc:	77 52                	ja     f0104520 <__umoddi3+0xa0>
f01044ce:	0f bd ea             	bsr    %edx,%ebp
f01044d1:	83 f5 1f             	xor    $0x1f,%ebp
f01044d4:	75 5a                	jne    f0104530 <__umoddi3+0xb0>
f01044d6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01044da:	0f 82 e0 00 00 00    	jb     f01045c0 <__umoddi3+0x140>
f01044e0:	39 0c 24             	cmp    %ecx,(%esp)
f01044e3:	0f 86 d7 00 00 00    	jbe    f01045c0 <__umoddi3+0x140>
f01044e9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01044ed:	8b 54 24 04          	mov    0x4(%esp),%edx
f01044f1:	83 c4 1c             	add    $0x1c,%esp
f01044f4:	5b                   	pop    %ebx
f01044f5:	5e                   	pop    %esi
f01044f6:	5f                   	pop    %edi
f01044f7:	5d                   	pop    %ebp
f01044f8:	c3                   	ret    
f01044f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104500:	85 ff                	test   %edi,%edi
f0104502:	89 fd                	mov    %edi,%ebp
f0104504:	75 0b                	jne    f0104511 <__umoddi3+0x91>
f0104506:	b8 01 00 00 00       	mov    $0x1,%eax
f010450b:	31 d2                	xor    %edx,%edx
f010450d:	f7 f7                	div    %edi
f010450f:	89 c5                	mov    %eax,%ebp
f0104511:	89 f0                	mov    %esi,%eax
f0104513:	31 d2                	xor    %edx,%edx
f0104515:	f7 f5                	div    %ebp
f0104517:	89 c8                	mov    %ecx,%eax
f0104519:	f7 f5                	div    %ebp
f010451b:	89 d0                	mov    %edx,%eax
f010451d:	eb 99                	jmp    f01044b8 <__umoddi3+0x38>
f010451f:	90                   	nop
f0104520:	89 c8                	mov    %ecx,%eax
f0104522:	89 f2                	mov    %esi,%edx
f0104524:	83 c4 1c             	add    $0x1c,%esp
f0104527:	5b                   	pop    %ebx
f0104528:	5e                   	pop    %esi
f0104529:	5f                   	pop    %edi
f010452a:	5d                   	pop    %ebp
f010452b:	c3                   	ret    
f010452c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104530:	8b 34 24             	mov    (%esp),%esi
f0104533:	bf 20 00 00 00       	mov    $0x20,%edi
f0104538:	89 e9                	mov    %ebp,%ecx
f010453a:	29 ef                	sub    %ebp,%edi
f010453c:	d3 e0                	shl    %cl,%eax
f010453e:	89 f9                	mov    %edi,%ecx
f0104540:	89 f2                	mov    %esi,%edx
f0104542:	d3 ea                	shr    %cl,%edx
f0104544:	89 e9                	mov    %ebp,%ecx
f0104546:	09 c2                	or     %eax,%edx
f0104548:	89 d8                	mov    %ebx,%eax
f010454a:	89 14 24             	mov    %edx,(%esp)
f010454d:	89 f2                	mov    %esi,%edx
f010454f:	d3 e2                	shl    %cl,%edx
f0104551:	89 f9                	mov    %edi,%ecx
f0104553:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104557:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010455b:	d3 e8                	shr    %cl,%eax
f010455d:	89 e9                	mov    %ebp,%ecx
f010455f:	89 c6                	mov    %eax,%esi
f0104561:	d3 e3                	shl    %cl,%ebx
f0104563:	89 f9                	mov    %edi,%ecx
f0104565:	89 d0                	mov    %edx,%eax
f0104567:	d3 e8                	shr    %cl,%eax
f0104569:	89 e9                	mov    %ebp,%ecx
f010456b:	09 d8                	or     %ebx,%eax
f010456d:	89 d3                	mov    %edx,%ebx
f010456f:	89 f2                	mov    %esi,%edx
f0104571:	f7 34 24             	divl   (%esp)
f0104574:	89 d6                	mov    %edx,%esi
f0104576:	d3 e3                	shl    %cl,%ebx
f0104578:	f7 64 24 04          	mull   0x4(%esp)
f010457c:	39 d6                	cmp    %edx,%esi
f010457e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104582:	89 d1                	mov    %edx,%ecx
f0104584:	89 c3                	mov    %eax,%ebx
f0104586:	72 08                	jb     f0104590 <__umoddi3+0x110>
f0104588:	75 11                	jne    f010459b <__umoddi3+0x11b>
f010458a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010458e:	73 0b                	jae    f010459b <__umoddi3+0x11b>
f0104590:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104594:	1b 14 24             	sbb    (%esp),%edx
f0104597:	89 d1                	mov    %edx,%ecx
f0104599:	89 c3                	mov    %eax,%ebx
f010459b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010459f:	29 da                	sub    %ebx,%edx
f01045a1:	19 ce                	sbb    %ecx,%esi
f01045a3:	89 f9                	mov    %edi,%ecx
f01045a5:	89 f0                	mov    %esi,%eax
f01045a7:	d3 e0                	shl    %cl,%eax
f01045a9:	89 e9                	mov    %ebp,%ecx
f01045ab:	d3 ea                	shr    %cl,%edx
f01045ad:	89 e9                	mov    %ebp,%ecx
f01045af:	d3 ee                	shr    %cl,%esi
f01045b1:	09 d0                	or     %edx,%eax
f01045b3:	89 f2                	mov    %esi,%edx
f01045b5:	83 c4 1c             	add    $0x1c,%esp
f01045b8:	5b                   	pop    %ebx
f01045b9:	5e                   	pop    %esi
f01045ba:	5f                   	pop    %edi
f01045bb:	5d                   	pop    %ebp
f01045bc:	c3                   	ret    
f01045bd:	8d 76 00             	lea    0x0(%esi),%esi
f01045c0:	29 f9                	sub    %edi,%ecx
f01045c2:	19 d6                	sbb    %edx,%esi
f01045c4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01045c8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01045cc:	e9 18 ff ff ff       	jmp    f01044e9 <__umoddi3+0x69>

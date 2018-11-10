
obj/user/divzero：     文件格式 elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 2f 00 00 00       	call   800060 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

int zero;

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	zero = 0;
  800039:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800040:	00 00 00 
	cprintf("1/0 is %08x!\n", 1/zero);
  800043:	b8 01 00 00 00       	mov    $0x1,%eax
  800048:	b9 00 00 00 00       	mov    $0x0,%ecx
  80004d:	99                   	cltd   
  80004e:	f7 f9                	idiv   %ecx
  800050:	50                   	push   %eax
  800051:	68 80 0d 80 00       	push   $0x800d80
  800056:	e8 e0 00 00 00       	call   80013b <cprintf>
}
  80005b:	83 c4 10             	add    $0x10,%esp
  80005e:	c9                   	leave  
  80005f:	c3                   	ret    

00800060 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800060:	55                   	push   %ebp
  800061:	89 e5                	mov    %esp,%ebp
  800063:	83 ec 08             	sub    $0x8,%esp
  800066:	8b 45 08             	mov    0x8(%ebp),%eax
  800069:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80006c:	c7 05 08 20 80 00 00 	movl   $0x0,0x802008
  800073:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800076:	85 c0                	test   %eax,%eax
  800078:	7e 08                	jle    800082 <libmain+0x22>
		binaryname = argv[0];
  80007a:	8b 0a                	mov    (%edx),%ecx
  80007c:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800082:	83 ec 08             	sub    $0x8,%esp
  800085:	52                   	push   %edx
  800086:	50                   	push   %eax
  800087:	e8 a7 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008c:	e8 05 00 00 00       	call   800096 <exit>
}
  800091:	83 c4 10             	add    $0x10,%esp
  800094:	c9                   	leave  
  800095:	c3                   	ret    

00800096 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800096:	55                   	push   %ebp
  800097:	89 e5                	mov    %esp,%ebp
  800099:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80009c:	6a 00                	push   $0x0
  80009e:	e8 a1 09 00 00       	call   800a44 <sys_env_destroy>
}
  8000a3:	83 c4 10             	add    $0x10,%esp
  8000a6:	c9                   	leave  
  8000a7:	c3                   	ret    

008000a8 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000a8:	55                   	push   %ebp
  8000a9:	89 e5                	mov    %esp,%ebp
  8000ab:	53                   	push   %ebx
  8000ac:	83 ec 04             	sub    $0x4,%esp
  8000af:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000b2:	8b 13                	mov    (%ebx),%edx
  8000b4:	8d 42 01             	lea    0x1(%edx),%eax
  8000b7:	89 03                	mov    %eax,(%ebx)
  8000b9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000bc:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000c0:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000c5:	75 1a                	jne    8000e1 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000c7:	83 ec 08             	sub    $0x8,%esp
  8000ca:	68 ff 00 00 00       	push   $0xff
  8000cf:	8d 43 08             	lea    0x8(%ebx),%eax
  8000d2:	50                   	push   %eax
  8000d3:	e8 2f 09 00 00       	call   800a07 <sys_cputs>
		b->idx = 0;
  8000d8:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000de:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000e1:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000e5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000e8:	c9                   	leave  
  8000e9:	c3                   	ret    

008000ea <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000ea:	55                   	push   %ebp
  8000eb:	89 e5                	mov    %esp,%ebp
  8000ed:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000f3:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000fa:	00 00 00 
	b.cnt = 0;
  8000fd:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800104:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800107:	ff 75 0c             	pushl  0xc(%ebp)
  80010a:	ff 75 08             	pushl  0x8(%ebp)
  80010d:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800113:	50                   	push   %eax
  800114:	68 a8 00 80 00       	push   $0x8000a8
  800119:	e8 54 01 00 00       	call   800272 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80011e:	83 c4 08             	add    $0x8,%esp
  800121:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800127:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80012d:	50                   	push   %eax
  80012e:	e8 d4 08 00 00       	call   800a07 <sys_cputs>

	return b.cnt;
}
  800133:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800139:	c9                   	leave  
  80013a:	c3                   	ret    

0080013b <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80013b:	55                   	push   %ebp
  80013c:	89 e5                	mov    %esp,%ebp
  80013e:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800141:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800144:	50                   	push   %eax
  800145:	ff 75 08             	pushl  0x8(%ebp)
  800148:	e8 9d ff ff ff       	call   8000ea <vcprintf>
	va_end(ap);

	return cnt;
}
  80014d:	c9                   	leave  
  80014e:	c3                   	ret    

0080014f <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80014f:	55                   	push   %ebp
  800150:	89 e5                	mov    %esp,%ebp
  800152:	57                   	push   %edi
  800153:	56                   	push   %esi
  800154:	53                   	push   %ebx
  800155:	83 ec 1c             	sub    $0x1c,%esp
  800158:	89 c7                	mov    %eax,%edi
  80015a:	89 d6                	mov    %edx,%esi
  80015c:	8b 45 08             	mov    0x8(%ebp),%eax
  80015f:	8b 55 0c             	mov    0xc(%ebp),%edx
  800162:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800165:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800168:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80016b:	bb 00 00 00 00       	mov    $0x0,%ebx
  800170:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800173:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800176:	39 d3                	cmp    %edx,%ebx
  800178:	72 05                	jb     80017f <printnum+0x30>
  80017a:	39 45 10             	cmp    %eax,0x10(%ebp)
  80017d:	77 45                	ja     8001c4 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80017f:	83 ec 0c             	sub    $0xc,%esp
  800182:	ff 75 18             	pushl  0x18(%ebp)
  800185:	8b 45 14             	mov    0x14(%ebp),%eax
  800188:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80018b:	53                   	push   %ebx
  80018c:	ff 75 10             	pushl  0x10(%ebp)
  80018f:	83 ec 08             	sub    $0x8,%esp
  800192:	ff 75 e4             	pushl  -0x1c(%ebp)
  800195:	ff 75 e0             	pushl  -0x20(%ebp)
  800198:	ff 75 dc             	pushl  -0x24(%ebp)
  80019b:	ff 75 d8             	pushl  -0x28(%ebp)
  80019e:	e8 4d 09 00 00       	call   800af0 <__udivdi3>
  8001a3:	83 c4 18             	add    $0x18,%esp
  8001a6:	52                   	push   %edx
  8001a7:	50                   	push   %eax
  8001a8:	89 f2                	mov    %esi,%edx
  8001aa:	89 f8                	mov    %edi,%eax
  8001ac:	e8 9e ff ff ff       	call   80014f <printnum>
  8001b1:	83 c4 20             	add    $0x20,%esp
  8001b4:	eb 18                	jmp    8001ce <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001b6:	83 ec 08             	sub    $0x8,%esp
  8001b9:	56                   	push   %esi
  8001ba:	ff 75 18             	pushl  0x18(%ebp)
  8001bd:	ff d7                	call   *%edi
  8001bf:	83 c4 10             	add    $0x10,%esp
  8001c2:	eb 03                	jmp    8001c7 <printnum+0x78>
  8001c4:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001c7:	83 eb 01             	sub    $0x1,%ebx
  8001ca:	85 db                	test   %ebx,%ebx
  8001cc:	7f e8                	jg     8001b6 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001ce:	83 ec 08             	sub    $0x8,%esp
  8001d1:	56                   	push   %esi
  8001d2:	83 ec 04             	sub    $0x4,%esp
  8001d5:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001d8:	ff 75 e0             	pushl  -0x20(%ebp)
  8001db:	ff 75 dc             	pushl  -0x24(%ebp)
  8001de:	ff 75 d8             	pushl  -0x28(%ebp)
  8001e1:	e8 3a 0a 00 00       	call   800c20 <__umoddi3>
  8001e6:	83 c4 14             	add    $0x14,%esp
  8001e9:	0f be 80 98 0d 80 00 	movsbl 0x800d98(%eax),%eax
  8001f0:	50                   	push   %eax
  8001f1:	ff d7                	call   *%edi
}
  8001f3:	83 c4 10             	add    $0x10,%esp
  8001f6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001f9:	5b                   	pop    %ebx
  8001fa:	5e                   	pop    %esi
  8001fb:	5f                   	pop    %edi
  8001fc:	5d                   	pop    %ebp
  8001fd:	c3                   	ret    

008001fe <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8001fe:	55                   	push   %ebp
  8001ff:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800201:	83 fa 01             	cmp    $0x1,%edx
  800204:	7e 0e                	jle    800214 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800206:	8b 10                	mov    (%eax),%edx
  800208:	8d 4a 08             	lea    0x8(%edx),%ecx
  80020b:	89 08                	mov    %ecx,(%eax)
  80020d:	8b 02                	mov    (%edx),%eax
  80020f:	8b 52 04             	mov    0x4(%edx),%edx
  800212:	eb 22                	jmp    800236 <getuint+0x38>
	else if (lflag)
  800214:	85 d2                	test   %edx,%edx
  800216:	74 10                	je     800228 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800218:	8b 10                	mov    (%eax),%edx
  80021a:	8d 4a 04             	lea    0x4(%edx),%ecx
  80021d:	89 08                	mov    %ecx,(%eax)
  80021f:	8b 02                	mov    (%edx),%eax
  800221:	ba 00 00 00 00       	mov    $0x0,%edx
  800226:	eb 0e                	jmp    800236 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800228:	8b 10                	mov    (%eax),%edx
  80022a:	8d 4a 04             	lea    0x4(%edx),%ecx
  80022d:	89 08                	mov    %ecx,(%eax)
  80022f:	8b 02                	mov    (%edx),%eax
  800231:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800236:	5d                   	pop    %ebp
  800237:	c3                   	ret    

00800238 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800238:	55                   	push   %ebp
  800239:	89 e5                	mov    %esp,%ebp
  80023b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80023e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800242:	8b 10                	mov    (%eax),%edx
  800244:	3b 50 04             	cmp    0x4(%eax),%edx
  800247:	73 0a                	jae    800253 <sprintputch+0x1b>
		*b->buf++ = ch;
  800249:	8d 4a 01             	lea    0x1(%edx),%ecx
  80024c:	89 08                	mov    %ecx,(%eax)
  80024e:	8b 45 08             	mov    0x8(%ebp),%eax
  800251:	88 02                	mov    %al,(%edx)
}
  800253:	5d                   	pop    %ebp
  800254:	c3                   	ret    

00800255 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800255:	55                   	push   %ebp
  800256:	89 e5                	mov    %esp,%ebp
  800258:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80025b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80025e:	50                   	push   %eax
  80025f:	ff 75 10             	pushl  0x10(%ebp)
  800262:	ff 75 0c             	pushl  0xc(%ebp)
  800265:	ff 75 08             	pushl  0x8(%ebp)
  800268:	e8 05 00 00 00       	call   800272 <vprintfmt>
	va_end(ap);
}
  80026d:	83 c4 10             	add    $0x10,%esp
  800270:	c9                   	leave  
  800271:	c3                   	ret    

00800272 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800272:	55                   	push   %ebp
  800273:	89 e5                	mov    %esp,%ebp
  800275:	57                   	push   %edi
  800276:	56                   	push   %esi
  800277:	53                   	push   %ebx
  800278:	83 ec 2c             	sub    $0x2c,%esp
  80027b:	8b 75 08             	mov    0x8(%ebp),%esi
  80027e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800281:	8b 7d 10             	mov    0x10(%ebp),%edi
  800284:	eb 12                	jmp    800298 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800286:	85 c0                	test   %eax,%eax
  800288:	0f 84 89 03 00 00    	je     800617 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  80028e:	83 ec 08             	sub    $0x8,%esp
  800291:	53                   	push   %ebx
  800292:	50                   	push   %eax
  800293:	ff d6                	call   *%esi
  800295:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800298:	83 c7 01             	add    $0x1,%edi
  80029b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80029f:	83 f8 25             	cmp    $0x25,%eax
  8002a2:	75 e2                	jne    800286 <vprintfmt+0x14>
  8002a4:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8002a8:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8002af:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002b6:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8002bd:	ba 00 00 00 00       	mov    $0x0,%edx
  8002c2:	eb 07                	jmp    8002cb <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002c4:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8002c7:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002cb:	8d 47 01             	lea    0x1(%edi),%eax
  8002ce:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002d1:	0f b6 07             	movzbl (%edi),%eax
  8002d4:	0f b6 c8             	movzbl %al,%ecx
  8002d7:	83 e8 23             	sub    $0x23,%eax
  8002da:	3c 55                	cmp    $0x55,%al
  8002dc:	0f 87 1a 03 00 00    	ja     8005fc <vprintfmt+0x38a>
  8002e2:	0f b6 c0             	movzbl %al,%eax
  8002e5:	ff 24 85 40 0e 80 00 	jmp    *0x800e40(,%eax,4)
  8002ec:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8002ef:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8002f3:	eb d6                	jmp    8002cb <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002f5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002f8:	b8 00 00 00 00       	mov    $0x0,%eax
  8002fd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800300:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800303:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800307:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80030a:	8d 51 d0             	lea    -0x30(%ecx),%edx
  80030d:	83 fa 09             	cmp    $0x9,%edx
  800310:	77 39                	ja     80034b <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800312:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800315:	eb e9                	jmp    800300 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800317:	8b 45 14             	mov    0x14(%ebp),%eax
  80031a:	8d 48 04             	lea    0x4(%eax),%ecx
  80031d:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800320:	8b 00                	mov    (%eax),%eax
  800322:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800325:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800328:	eb 27                	jmp    800351 <vprintfmt+0xdf>
  80032a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80032d:	85 c0                	test   %eax,%eax
  80032f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800334:	0f 49 c8             	cmovns %eax,%ecx
  800337:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80033a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80033d:	eb 8c                	jmp    8002cb <vprintfmt+0x59>
  80033f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800342:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800349:	eb 80                	jmp    8002cb <vprintfmt+0x59>
  80034b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80034e:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800351:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800355:	0f 89 70 ff ff ff    	jns    8002cb <vprintfmt+0x59>
				width = precision, precision = -1;
  80035b:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80035e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800361:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800368:	e9 5e ff ff ff       	jmp    8002cb <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80036d:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800370:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800373:	e9 53 ff ff ff       	jmp    8002cb <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800378:	8b 45 14             	mov    0x14(%ebp),%eax
  80037b:	8d 50 04             	lea    0x4(%eax),%edx
  80037e:	89 55 14             	mov    %edx,0x14(%ebp)
  800381:	83 ec 08             	sub    $0x8,%esp
  800384:	53                   	push   %ebx
  800385:	ff 30                	pushl  (%eax)
  800387:	ff d6                	call   *%esi
			break;
  800389:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80038c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80038f:	e9 04 ff ff ff       	jmp    800298 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800394:	8b 45 14             	mov    0x14(%ebp),%eax
  800397:	8d 50 04             	lea    0x4(%eax),%edx
  80039a:	89 55 14             	mov    %edx,0x14(%ebp)
  80039d:	8b 00                	mov    (%eax),%eax
  80039f:	99                   	cltd   
  8003a0:	31 d0                	xor    %edx,%eax
  8003a2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003a4:	83 f8 07             	cmp    $0x7,%eax
  8003a7:	7f 0b                	jg     8003b4 <vprintfmt+0x142>
  8003a9:	8b 14 85 a0 0f 80 00 	mov    0x800fa0(,%eax,4),%edx
  8003b0:	85 d2                	test   %edx,%edx
  8003b2:	75 18                	jne    8003cc <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8003b4:	50                   	push   %eax
  8003b5:	68 b0 0d 80 00       	push   $0x800db0
  8003ba:	53                   	push   %ebx
  8003bb:	56                   	push   %esi
  8003bc:	e8 94 fe ff ff       	call   800255 <printfmt>
  8003c1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003c7:	e9 cc fe ff ff       	jmp    800298 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003cc:	52                   	push   %edx
  8003cd:	68 b9 0d 80 00       	push   $0x800db9
  8003d2:	53                   	push   %ebx
  8003d3:	56                   	push   %esi
  8003d4:	e8 7c fe ff ff       	call   800255 <printfmt>
  8003d9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003dc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003df:	e9 b4 fe ff ff       	jmp    800298 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8003e7:	8d 50 04             	lea    0x4(%eax),%edx
  8003ea:	89 55 14             	mov    %edx,0x14(%ebp)
  8003ed:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8003ef:	85 ff                	test   %edi,%edi
  8003f1:	b8 a9 0d 80 00       	mov    $0x800da9,%eax
  8003f6:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8003f9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003fd:	0f 8e 94 00 00 00    	jle    800497 <vprintfmt+0x225>
  800403:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800407:	0f 84 98 00 00 00    	je     8004a5 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  80040d:	83 ec 08             	sub    $0x8,%esp
  800410:	ff 75 d0             	pushl  -0x30(%ebp)
  800413:	57                   	push   %edi
  800414:	e8 86 02 00 00       	call   80069f <strnlen>
  800419:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80041c:	29 c1                	sub    %eax,%ecx
  80041e:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800421:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800424:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800428:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80042b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80042e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800430:	eb 0f                	jmp    800441 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800432:	83 ec 08             	sub    $0x8,%esp
  800435:	53                   	push   %ebx
  800436:	ff 75 e0             	pushl  -0x20(%ebp)
  800439:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80043b:	83 ef 01             	sub    $0x1,%edi
  80043e:	83 c4 10             	add    $0x10,%esp
  800441:	85 ff                	test   %edi,%edi
  800443:	7f ed                	jg     800432 <vprintfmt+0x1c0>
  800445:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800448:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80044b:	85 c9                	test   %ecx,%ecx
  80044d:	b8 00 00 00 00       	mov    $0x0,%eax
  800452:	0f 49 c1             	cmovns %ecx,%eax
  800455:	29 c1                	sub    %eax,%ecx
  800457:	89 75 08             	mov    %esi,0x8(%ebp)
  80045a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80045d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800460:	89 cb                	mov    %ecx,%ebx
  800462:	eb 4d                	jmp    8004b1 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800464:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800468:	74 1b                	je     800485 <vprintfmt+0x213>
  80046a:	0f be c0             	movsbl %al,%eax
  80046d:	83 e8 20             	sub    $0x20,%eax
  800470:	83 f8 5e             	cmp    $0x5e,%eax
  800473:	76 10                	jbe    800485 <vprintfmt+0x213>
					putch('?', putdat);
  800475:	83 ec 08             	sub    $0x8,%esp
  800478:	ff 75 0c             	pushl  0xc(%ebp)
  80047b:	6a 3f                	push   $0x3f
  80047d:	ff 55 08             	call   *0x8(%ebp)
  800480:	83 c4 10             	add    $0x10,%esp
  800483:	eb 0d                	jmp    800492 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800485:	83 ec 08             	sub    $0x8,%esp
  800488:	ff 75 0c             	pushl  0xc(%ebp)
  80048b:	52                   	push   %edx
  80048c:	ff 55 08             	call   *0x8(%ebp)
  80048f:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800492:	83 eb 01             	sub    $0x1,%ebx
  800495:	eb 1a                	jmp    8004b1 <vprintfmt+0x23f>
  800497:	89 75 08             	mov    %esi,0x8(%ebp)
  80049a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80049d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004a0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004a3:	eb 0c                	jmp    8004b1 <vprintfmt+0x23f>
  8004a5:	89 75 08             	mov    %esi,0x8(%ebp)
  8004a8:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004ab:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004ae:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004b1:	83 c7 01             	add    $0x1,%edi
  8004b4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004b8:	0f be d0             	movsbl %al,%edx
  8004bb:	85 d2                	test   %edx,%edx
  8004bd:	74 23                	je     8004e2 <vprintfmt+0x270>
  8004bf:	85 f6                	test   %esi,%esi
  8004c1:	78 a1                	js     800464 <vprintfmt+0x1f2>
  8004c3:	83 ee 01             	sub    $0x1,%esi
  8004c6:	79 9c                	jns    800464 <vprintfmt+0x1f2>
  8004c8:	89 df                	mov    %ebx,%edi
  8004ca:	8b 75 08             	mov    0x8(%ebp),%esi
  8004cd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004d0:	eb 18                	jmp    8004ea <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004d2:	83 ec 08             	sub    $0x8,%esp
  8004d5:	53                   	push   %ebx
  8004d6:	6a 20                	push   $0x20
  8004d8:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004da:	83 ef 01             	sub    $0x1,%edi
  8004dd:	83 c4 10             	add    $0x10,%esp
  8004e0:	eb 08                	jmp    8004ea <vprintfmt+0x278>
  8004e2:	89 df                	mov    %ebx,%edi
  8004e4:	8b 75 08             	mov    0x8(%ebp),%esi
  8004e7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004ea:	85 ff                	test   %edi,%edi
  8004ec:	7f e4                	jg     8004d2 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004f1:	e9 a2 fd ff ff       	jmp    800298 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8004f6:	83 fa 01             	cmp    $0x1,%edx
  8004f9:	7e 16                	jle    800511 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  8004fb:	8b 45 14             	mov    0x14(%ebp),%eax
  8004fe:	8d 50 08             	lea    0x8(%eax),%edx
  800501:	89 55 14             	mov    %edx,0x14(%ebp)
  800504:	8b 50 04             	mov    0x4(%eax),%edx
  800507:	8b 00                	mov    (%eax),%eax
  800509:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80050c:	89 55 dc             	mov    %edx,-0x24(%ebp)
  80050f:	eb 32                	jmp    800543 <vprintfmt+0x2d1>
	else if (lflag)
  800511:	85 d2                	test   %edx,%edx
  800513:	74 18                	je     80052d <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  800515:	8b 45 14             	mov    0x14(%ebp),%eax
  800518:	8d 50 04             	lea    0x4(%eax),%edx
  80051b:	89 55 14             	mov    %edx,0x14(%ebp)
  80051e:	8b 00                	mov    (%eax),%eax
  800520:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800523:	89 c1                	mov    %eax,%ecx
  800525:	c1 f9 1f             	sar    $0x1f,%ecx
  800528:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80052b:	eb 16                	jmp    800543 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  80052d:	8b 45 14             	mov    0x14(%ebp),%eax
  800530:	8d 50 04             	lea    0x4(%eax),%edx
  800533:	89 55 14             	mov    %edx,0x14(%ebp)
  800536:	8b 00                	mov    (%eax),%eax
  800538:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80053b:	89 c1                	mov    %eax,%ecx
  80053d:	c1 f9 1f             	sar    $0x1f,%ecx
  800540:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800543:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800546:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800549:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80054e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800552:	79 74                	jns    8005c8 <vprintfmt+0x356>
				putch('-', putdat);
  800554:	83 ec 08             	sub    $0x8,%esp
  800557:	53                   	push   %ebx
  800558:	6a 2d                	push   $0x2d
  80055a:	ff d6                	call   *%esi
				num = -(long long) num;
  80055c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80055f:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800562:	f7 d8                	neg    %eax
  800564:	83 d2 00             	adc    $0x0,%edx
  800567:	f7 da                	neg    %edx
  800569:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80056c:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800571:	eb 55                	jmp    8005c8 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800573:	8d 45 14             	lea    0x14(%ebp),%eax
  800576:	e8 83 fc ff ff       	call   8001fe <getuint>
			base = 10;
  80057b:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800580:	eb 46                	jmp    8005c8 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800582:	8d 45 14             	lea    0x14(%ebp),%eax
  800585:	e8 74 fc ff ff       	call   8001fe <getuint>
			base = 8;
  80058a:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80058f:	eb 37                	jmp    8005c8 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  800591:	83 ec 08             	sub    $0x8,%esp
  800594:	53                   	push   %ebx
  800595:	6a 30                	push   $0x30
  800597:	ff d6                	call   *%esi
			putch('x', putdat);
  800599:	83 c4 08             	add    $0x8,%esp
  80059c:	53                   	push   %ebx
  80059d:	6a 78                	push   $0x78
  80059f:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8005a1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a4:	8d 50 04             	lea    0x4(%eax),%edx
  8005a7:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8005aa:	8b 00                	mov    (%eax),%eax
  8005ac:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8005b1:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8005b4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8005b9:	eb 0d                	jmp    8005c8 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8005bb:	8d 45 14             	lea    0x14(%ebp),%eax
  8005be:	e8 3b fc ff ff       	call   8001fe <getuint>
			base = 16;
  8005c3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8005c8:	83 ec 0c             	sub    $0xc,%esp
  8005cb:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8005cf:	57                   	push   %edi
  8005d0:	ff 75 e0             	pushl  -0x20(%ebp)
  8005d3:	51                   	push   %ecx
  8005d4:	52                   	push   %edx
  8005d5:	50                   	push   %eax
  8005d6:	89 da                	mov    %ebx,%edx
  8005d8:	89 f0                	mov    %esi,%eax
  8005da:	e8 70 fb ff ff       	call   80014f <printnum>
			break;
  8005df:	83 c4 20             	add    $0x20,%esp
  8005e2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005e5:	e9 ae fc ff ff       	jmp    800298 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8005ea:	83 ec 08             	sub    $0x8,%esp
  8005ed:	53                   	push   %ebx
  8005ee:	51                   	push   %ecx
  8005ef:	ff d6                	call   *%esi
			break;
  8005f1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005f4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8005f7:	e9 9c fc ff ff       	jmp    800298 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8005fc:	83 ec 08             	sub    $0x8,%esp
  8005ff:	53                   	push   %ebx
  800600:	6a 25                	push   $0x25
  800602:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800604:	83 c4 10             	add    $0x10,%esp
  800607:	eb 03                	jmp    80060c <vprintfmt+0x39a>
  800609:	83 ef 01             	sub    $0x1,%edi
  80060c:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800610:	75 f7                	jne    800609 <vprintfmt+0x397>
  800612:	e9 81 fc ff ff       	jmp    800298 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800617:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80061a:	5b                   	pop    %ebx
  80061b:	5e                   	pop    %esi
  80061c:	5f                   	pop    %edi
  80061d:	5d                   	pop    %ebp
  80061e:	c3                   	ret    

0080061f <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80061f:	55                   	push   %ebp
  800620:	89 e5                	mov    %esp,%ebp
  800622:	83 ec 18             	sub    $0x18,%esp
  800625:	8b 45 08             	mov    0x8(%ebp),%eax
  800628:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80062b:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80062e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800632:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800635:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80063c:	85 c0                	test   %eax,%eax
  80063e:	74 26                	je     800666 <vsnprintf+0x47>
  800640:	85 d2                	test   %edx,%edx
  800642:	7e 22                	jle    800666 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800644:	ff 75 14             	pushl  0x14(%ebp)
  800647:	ff 75 10             	pushl  0x10(%ebp)
  80064a:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80064d:	50                   	push   %eax
  80064e:	68 38 02 80 00       	push   $0x800238
  800653:	e8 1a fc ff ff       	call   800272 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800658:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80065b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80065e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800661:	83 c4 10             	add    $0x10,%esp
  800664:	eb 05                	jmp    80066b <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800666:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80066b:	c9                   	leave  
  80066c:	c3                   	ret    

0080066d <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80066d:	55                   	push   %ebp
  80066e:	89 e5                	mov    %esp,%ebp
  800670:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800673:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800676:	50                   	push   %eax
  800677:	ff 75 10             	pushl  0x10(%ebp)
  80067a:	ff 75 0c             	pushl  0xc(%ebp)
  80067d:	ff 75 08             	pushl  0x8(%ebp)
  800680:	e8 9a ff ff ff       	call   80061f <vsnprintf>
	va_end(ap);

	return rc;
}
  800685:	c9                   	leave  
  800686:	c3                   	ret    

00800687 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800687:	55                   	push   %ebp
  800688:	89 e5                	mov    %esp,%ebp
  80068a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80068d:	b8 00 00 00 00       	mov    $0x0,%eax
  800692:	eb 03                	jmp    800697 <strlen+0x10>
		n++;
  800694:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800697:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80069b:	75 f7                	jne    800694 <strlen+0xd>
		n++;
	return n;
}
  80069d:	5d                   	pop    %ebp
  80069e:	c3                   	ret    

0080069f <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80069f:	55                   	push   %ebp
  8006a0:	89 e5                	mov    %esp,%ebp
  8006a2:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8006a5:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006a8:	ba 00 00 00 00       	mov    $0x0,%edx
  8006ad:	eb 03                	jmp    8006b2 <strnlen+0x13>
		n++;
  8006af:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006b2:	39 c2                	cmp    %eax,%edx
  8006b4:	74 08                	je     8006be <strnlen+0x1f>
  8006b6:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8006ba:	75 f3                	jne    8006af <strnlen+0x10>
  8006bc:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8006be:	5d                   	pop    %ebp
  8006bf:	c3                   	ret    

008006c0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8006c0:	55                   	push   %ebp
  8006c1:	89 e5                	mov    %esp,%ebp
  8006c3:	53                   	push   %ebx
  8006c4:	8b 45 08             	mov    0x8(%ebp),%eax
  8006c7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8006ca:	89 c2                	mov    %eax,%edx
  8006cc:	83 c2 01             	add    $0x1,%edx
  8006cf:	83 c1 01             	add    $0x1,%ecx
  8006d2:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8006d6:	88 5a ff             	mov    %bl,-0x1(%edx)
  8006d9:	84 db                	test   %bl,%bl
  8006db:	75 ef                	jne    8006cc <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8006dd:	5b                   	pop    %ebx
  8006de:	5d                   	pop    %ebp
  8006df:	c3                   	ret    

008006e0 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8006e0:	55                   	push   %ebp
  8006e1:	89 e5                	mov    %esp,%ebp
  8006e3:	53                   	push   %ebx
  8006e4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8006e7:	53                   	push   %ebx
  8006e8:	e8 9a ff ff ff       	call   800687 <strlen>
  8006ed:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8006f0:	ff 75 0c             	pushl  0xc(%ebp)
  8006f3:	01 d8                	add    %ebx,%eax
  8006f5:	50                   	push   %eax
  8006f6:	e8 c5 ff ff ff       	call   8006c0 <strcpy>
	return dst;
}
  8006fb:	89 d8                	mov    %ebx,%eax
  8006fd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800700:	c9                   	leave  
  800701:	c3                   	ret    

00800702 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800702:	55                   	push   %ebp
  800703:	89 e5                	mov    %esp,%ebp
  800705:	56                   	push   %esi
  800706:	53                   	push   %ebx
  800707:	8b 75 08             	mov    0x8(%ebp),%esi
  80070a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80070d:	89 f3                	mov    %esi,%ebx
  80070f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800712:	89 f2                	mov    %esi,%edx
  800714:	eb 0f                	jmp    800725 <strncpy+0x23>
		*dst++ = *src;
  800716:	83 c2 01             	add    $0x1,%edx
  800719:	0f b6 01             	movzbl (%ecx),%eax
  80071c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80071f:	80 39 01             	cmpb   $0x1,(%ecx)
  800722:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800725:	39 da                	cmp    %ebx,%edx
  800727:	75 ed                	jne    800716 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800729:	89 f0                	mov    %esi,%eax
  80072b:	5b                   	pop    %ebx
  80072c:	5e                   	pop    %esi
  80072d:	5d                   	pop    %ebp
  80072e:	c3                   	ret    

0080072f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80072f:	55                   	push   %ebp
  800730:	89 e5                	mov    %esp,%ebp
  800732:	56                   	push   %esi
  800733:	53                   	push   %ebx
  800734:	8b 75 08             	mov    0x8(%ebp),%esi
  800737:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80073a:	8b 55 10             	mov    0x10(%ebp),%edx
  80073d:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80073f:	85 d2                	test   %edx,%edx
  800741:	74 21                	je     800764 <strlcpy+0x35>
  800743:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800747:	89 f2                	mov    %esi,%edx
  800749:	eb 09                	jmp    800754 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80074b:	83 c2 01             	add    $0x1,%edx
  80074e:	83 c1 01             	add    $0x1,%ecx
  800751:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800754:	39 c2                	cmp    %eax,%edx
  800756:	74 09                	je     800761 <strlcpy+0x32>
  800758:	0f b6 19             	movzbl (%ecx),%ebx
  80075b:	84 db                	test   %bl,%bl
  80075d:	75 ec                	jne    80074b <strlcpy+0x1c>
  80075f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800761:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800764:	29 f0                	sub    %esi,%eax
}
  800766:	5b                   	pop    %ebx
  800767:	5e                   	pop    %esi
  800768:	5d                   	pop    %ebp
  800769:	c3                   	ret    

0080076a <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80076a:	55                   	push   %ebp
  80076b:	89 e5                	mov    %esp,%ebp
  80076d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800770:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800773:	eb 06                	jmp    80077b <strcmp+0x11>
		p++, q++;
  800775:	83 c1 01             	add    $0x1,%ecx
  800778:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80077b:	0f b6 01             	movzbl (%ecx),%eax
  80077e:	84 c0                	test   %al,%al
  800780:	74 04                	je     800786 <strcmp+0x1c>
  800782:	3a 02                	cmp    (%edx),%al
  800784:	74 ef                	je     800775 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800786:	0f b6 c0             	movzbl %al,%eax
  800789:	0f b6 12             	movzbl (%edx),%edx
  80078c:	29 d0                	sub    %edx,%eax
}
  80078e:	5d                   	pop    %ebp
  80078f:	c3                   	ret    

00800790 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800790:	55                   	push   %ebp
  800791:	89 e5                	mov    %esp,%ebp
  800793:	53                   	push   %ebx
  800794:	8b 45 08             	mov    0x8(%ebp),%eax
  800797:	8b 55 0c             	mov    0xc(%ebp),%edx
  80079a:	89 c3                	mov    %eax,%ebx
  80079c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80079f:	eb 06                	jmp    8007a7 <strncmp+0x17>
		n--, p++, q++;
  8007a1:	83 c0 01             	add    $0x1,%eax
  8007a4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8007a7:	39 d8                	cmp    %ebx,%eax
  8007a9:	74 15                	je     8007c0 <strncmp+0x30>
  8007ab:	0f b6 08             	movzbl (%eax),%ecx
  8007ae:	84 c9                	test   %cl,%cl
  8007b0:	74 04                	je     8007b6 <strncmp+0x26>
  8007b2:	3a 0a                	cmp    (%edx),%cl
  8007b4:	74 eb                	je     8007a1 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8007b6:	0f b6 00             	movzbl (%eax),%eax
  8007b9:	0f b6 12             	movzbl (%edx),%edx
  8007bc:	29 d0                	sub    %edx,%eax
  8007be:	eb 05                	jmp    8007c5 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8007c0:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8007c5:	5b                   	pop    %ebx
  8007c6:	5d                   	pop    %ebp
  8007c7:	c3                   	ret    

008007c8 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8007c8:	55                   	push   %ebp
  8007c9:	89 e5                	mov    %esp,%ebp
  8007cb:	8b 45 08             	mov    0x8(%ebp),%eax
  8007ce:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007d2:	eb 07                	jmp    8007db <strchr+0x13>
		if (*s == c)
  8007d4:	38 ca                	cmp    %cl,%dl
  8007d6:	74 0f                	je     8007e7 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8007d8:	83 c0 01             	add    $0x1,%eax
  8007db:	0f b6 10             	movzbl (%eax),%edx
  8007de:	84 d2                	test   %dl,%dl
  8007e0:	75 f2                	jne    8007d4 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8007e2:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8007e7:	5d                   	pop    %ebp
  8007e8:	c3                   	ret    

008007e9 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8007e9:	55                   	push   %ebp
  8007ea:	89 e5                	mov    %esp,%ebp
  8007ec:	8b 45 08             	mov    0x8(%ebp),%eax
  8007ef:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007f3:	eb 03                	jmp    8007f8 <strfind+0xf>
  8007f5:	83 c0 01             	add    $0x1,%eax
  8007f8:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8007fb:	38 ca                	cmp    %cl,%dl
  8007fd:	74 04                	je     800803 <strfind+0x1a>
  8007ff:	84 d2                	test   %dl,%dl
  800801:	75 f2                	jne    8007f5 <strfind+0xc>
			break;
	return (char *) s;
}
  800803:	5d                   	pop    %ebp
  800804:	c3                   	ret    

00800805 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800805:	55                   	push   %ebp
  800806:	89 e5                	mov    %esp,%ebp
  800808:	57                   	push   %edi
  800809:	56                   	push   %esi
  80080a:	53                   	push   %ebx
  80080b:	8b 7d 08             	mov    0x8(%ebp),%edi
  80080e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800811:	85 c9                	test   %ecx,%ecx
  800813:	74 36                	je     80084b <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800815:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80081b:	75 28                	jne    800845 <memset+0x40>
  80081d:	f6 c1 03             	test   $0x3,%cl
  800820:	75 23                	jne    800845 <memset+0x40>
		c &= 0xFF;
  800822:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800826:	89 d3                	mov    %edx,%ebx
  800828:	c1 e3 08             	shl    $0x8,%ebx
  80082b:	89 d6                	mov    %edx,%esi
  80082d:	c1 e6 18             	shl    $0x18,%esi
  800830:	89 d0                	mov    %edx,%eax
  800832:	c1 e0 10             	shl    $0x10,%eax
  800835:	09 f0                	or     %esi,%eax
  800837:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800839:	89 d8                	mov    %ebx,%eax
  80083b:	09 d0                	or     %edx,%eax
  80083d:	c1 e9 02             	shr    $0x2,%ecx
  800840:	fc                   	cld    
  800841:	f3 ab                	rep stos %eax,%es:(%edi)
  800843:	eb 06                	jmp    80084b <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800845:	8b 45 0c             	mov    0xc(%ebp),%eax
  800848:	fc                   	cld    
  800849:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80084b:	89 f8                	mov    %edi,%eax
  80084d:	5b                   	pop    %ebx
  80084e:	5e                   	pop    %esi
  80084f:	5f                   	pop    %edi
  800850:	5d                   	pop    %ebp
  800851:	c3                   	ret    

00800852 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800852:	55                   	push   %ebp
  800853:	89 e5                	mov    %esp,%ebp
  800855:	57                   	push   %edi
  800856:	56                   	push   %esi
  800857:	8b 45 08             	mov    0x8(%ebp),%eax
  80085a:	8b 75 0c             	mov    0xc(%ebp),%esi
  80085d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800860:	39 c6                	cmp    %eax,%esi
  800862:	73 35                	jae    800899 <memmove+0x47>
  800864:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800867:	39 d0                	cmp    %edx,%eax
  800869:	73 2e                	jae    800899 <memmove+0x47>
		s += n;
		d += n;
  80086b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80086e:	89 d6                	mov    %edx,%esi
  800870:	09 fe                	or     %edi,%esi
  800872:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800878:	75 13                	jne    80088d <memmove+0x3b>
  80087a:	f6 c1 03             	test   $0x3,%cl
  80087d:	75 0e                	jne    80088d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80087f:	83 ef 04             	sub    $0x4,%edi
  800882:	8d 72 fc             	lea    -0x4(%edx),%esi
  800885:	c1 e9 02             	shr    $0x2,%ecx
  800888:	fd                   	std    
  800889:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80088b:	eb 09                	jmp    800896 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80088d:	83 ef 01             	sub    $0x1,%edi
  800890:	8d 72 ff             	lea    -0x1(%edx),%esi
  800893:	fd                   	std    
  800894:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800896:	fc                   	cld    
  800897:	eb 1d                	jmp    8008b6 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800899:	89 f2                	mov    %esi,%edx
  80089b:	09 c2                	or     %eax,%edx
  80089d:	f6 c2 03             	test   $0x3,%dl
  8008a0:	75 0f                	jne    8008b1 <memmove+0x5f>
  8008a2:	f6 c1 03             	test   $0x3,%cl
  8008a5:	75 0a                	jne    8008b1 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8008a7:	c1 e9 02             	shr    $0x2,%ecx
  8008aa:	89 c7                	mov    %eax,%edi
  8008ac:	fc                   	cld    
  8008ad:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8008af:	eb 05                	jmp    8008b6 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8008b1:	89 c7                	mov    %eax,%edi
  8008b3:	fc                   	cld    
  8008b4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8008b6:	5e                   	pop    %esi
  8008b7:	5f                   	pop    %edi
  8008b8:	5d                   	pop    %ebp
  8008b9:	c3                   	ret    

008008ba <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8008ba:	55                   	push   %ebp
  8008bb:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8008bd:	ff 75 10             	pushl  0x10(%ebp)
  8008c0:	ff 75 0c             	pushl  0xc(%ebp)
  8008c3:	ff 75 08             	pushl  0x8(%ebp)
  8008c6:	e8 87 ff ff ff       	call   800852 <memmove>
}
  8008cb:	c9                   	leave  
  8008cc:	c3                   	ret    

008008cd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8008cd:	55                   	push   %ebp
  8008ce:	89 e5                	mov    %esp,%ebp
  8008d0:	56                   	push   %esi
  8008d1:	53                   	push   %ebx
  8008d2:	8b 45 08             	mov    0x8(%ebp),%eax
  8008d5:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008d8:	89 c6                	mov    %eax,%esi
  8008da:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008dd:	eb 1a                	jmp    8008f9 <memcmp+0x2c>
		if (*s1 != *s2)
  8008df:	0f b6 08             	movzbl (%eax),%ecx
  8008e2:	0f b6 1a             	movzbl (%edx),%ebx
  8008e5:	38 d9                	cmp    %bl,%cl
  8008e7:	74 0a                	je     8008f3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8008e9:	0f b6 c1             	movzbl %cl,%eax
  8008ec:	0f b6 db             	movzbl %bl,%ebx
  8008ef:	29 d8                	sub    %ebx,%eax
  8008f1:	eb 0f                	jmp    800902 <memcmp+0x35>
		s1++, s2++;
  8008f3:	83 c0 01             	add    $0x1,%eax
  8008f6:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008f9:	39 f0                	cmp    %esi,%eax
  8008fb:	75 e2                	jne    8008df <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8008fd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800902:	5b                   	pop    %ebx
  800903:	5e                   	pop    %esi
  800904:	5d                   	pop    %ebp
  800905:	c3                   	ret    

00800906 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800906:	55                   	push   %ebp
  800907:	89 e5                	mov    %esp,%ebp
  800909:	53                   	push   %ebx
  80090a:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  80090d:	89 c1                	mov    %eax,%ecx
  80090f:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800912:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800916:	eb 0a                	jmp    800922 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800918:	0f b6 10             	movzbl (%eax),%edx
  80091b:	39 da                	cmp    %ebx,%edx
  80091d:	74 07                	je     800926 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  80091f:	83 c0 01             	add    $0x1,%eax
  800922:	39 c8                	cmp    %ecx,%eax
  800924:	72 f2                	jb     800918 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800926:	5b                   	pop    %ebx
  800927:	5d                   	pop    %ebp
  800928:	c3                   	ret    

00800929 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800929:	55                   	push   %ebp
  80092a:	89 e5                	mov    %esp,%ebp
  80092c:	57                   	push   %edi
  80092d:	56                   	push   %esi
  80092e:	53                   	push   %ebx
  80092f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800932:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800935:	eb 03                	jmp    80093a <strtol+0x11>
		s++;
  800937:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  80093a:	0f b6 01             	movzbl (%ecx),%eax
  80093d:	3c 20                	cmp    $0x20,%al
  80093f:	74 f6                	je     800937 <strtol+0xe>
  800941:	3c 09                	cmp    $0x9,%al
  800943:	74 f2                	je     800937 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800945:	3c 2b                	cmp    $0x2b,%al
  800947:	75 0a                	jne    800953 <strtol+0x2a>
		s++;
  800949:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  80094c:	bf 00 00 00 00       	mov    $0x0,%edi
  800951:	eb 11                	jmp    800964 <strtol+0x3b>
  800953:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800958:	3c 2d                	cmp    $0x2d,%al
  80095a:	75 08                	jne    800964 <strtol+0x3b>
		s++, neg = 1;
  80095c:	83 c1 01             	add    $0x1,%ecx
  80095f:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800964:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  80096a:	75 15                	jne    800981 <strtol+0x58>
  80096c:	80 39 30             	cmpb   $0x30,(%ecx)
  80096f:	75 10                	jne    800981 <strtol+0x58>
  800971:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800975:	75 7c                	jne    8009f3 <strtol+0xca>
		s += 2, base = 16;
  800977:	83 c1 02             	add    $0x2,%ecx
  80097a:	bb 10 00 00 00       	mov    $0x10,%ebx
  80097f:	eb 16                	jmp    800997 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800981:	85 db                	test   %ebx,%ebx
  800983:	75 12                	jne    800997 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800985:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  80098a:	80 39 30             	cmpb   $0x30,(%ecx)
  80098d:	75 08                	jne    800997 <strtol+0x6e>
		s++, base = 8;
  80098f:	83 c1 01             	add    $0x1,%ecx
  800992:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800997:	b8 00 00 00 00       	mov    $0x0,%eax
  80099c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  80099f:	0f b6 11             	movzbl (%ecx),%edx
  8009a2:	8d 72 d0             	lea    -0x30(%edx),%esi
  8009a5:	89 f3                	mov    %esi,%ebx
  8009a7:	80 fb 09             	cmp    $0x9,%bl
  8009aa:	77 08                	ja     8009b4 <strtol+0x8b>
			dig = *s - '0';
  8009ac:	0f be d2             	movsbl %dl,%edx
  8009af:	83 ea 30             	sub    $0x30,%edx
  8009b2:	eb 22                	jmp    8009d6 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  8009b4:	8d 72 9f             	lea    -0x61(%edx),%esi
  8009b7:	89 f3                	mov    %esi,%ebx
  8009b9:	80 fb 19             	cmp    $0x19,%bl
  8009bc:	77 08                	ja     8009c6 <strtol+0x9d>
			dig = *s - 'a' + 10;
  8009be:	0f be d2             	movsbl %dl,%edx
  8009c1:	83 ea 57             	sub    $0x57,%edx
  8009c4:	eb 10                	jmp    8009d6 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  8009c6:	8d 72 bf             	lea    -0x41(%edx),%esi
  8009c9:	89 f3                	mov    %esi,%ebx
  8009cb:	80 fb 19             	cmp    $0x19,%bl
  8009ce:	77 16                	ja     8009e6 <strtol+0xbd>
			dig = *s - 'A' + 10;
  8009d0:	0f be d2             	movsbl %dl,%edx
  8009d3:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  8009d6:	3b 55 10             	cmp    0x10(%ebp),%edx
  8009d9:	7d 0b                	jge    8009e6 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  8009db:	83 c1 01             	add    $0x1,%ecx
  8009de:	0f af 45 10          	imul   0x10(%ebp),%eax
  8009e2:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  8009e4:	eb b9                	jmp    80099f <strtol+0x76>

	if (endptr)
  8009e6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8009ea:	74 0d                	je     8009f9 <strtol+0xd0>
		*endptr = (char *) s;
  8009ec:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009ef:	89 0e                	mov    %ecx,(%esi)
  8009f1:	eb 06                	jmp    8009f9 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  8009f3:	85 db                	test   %ebx,%ebx
  8009f5:	74 98                	je     80098f <strtol+0x66>
  8009f7:	eb 9e                	jmp    800997 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  8009f9:	89 c2                	mov    %eax,%edx
  8009fb:	f7 da                	neg    %edx
  8009fd:	85 ff                	test   %edi,%edi
  8009ff:	0f 45 c2             	cmovne %edx,%eax
}
  800a02:	5b                   	pop    %ebx
  800a03:	5e                   	pop    %esi
  800a04:	5f                   	pop    %edi
  800a05:	5d                   	pop    %ebp
  800a06:	c3                   	ret    

00800a07 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800a07:	55                   	push   %ebp
  800a08:	89 e5                	mov    %esp,%ebp
  800a0a:	57                   	push   %edi
  800a0b:	56                   	push   %esi
  800a0c:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a0d:	b8 00 00 00 00       	mov    $0x0,%eax
  800a12:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a15:	8b 55 08             	mov    0x8(%ebp),%edx
  800a18:	89 c3                	mov    %eax,%ebx
  800a1a:	89 c7                	mov    %eax,%edi
  800a1c:	89 c6                	mov    %eax,%esi
  800a1e:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800a20:	5b                   	pop    %ebx
  800a21:	5e                   	pop    %esi
  800a22:	5f                   	pop    %edi
  800a23:	5d                   	pop    %ebp
  800a24:	c3                   	ret    

00800a25 <sys_cgetc>:

int
sys_cgetc(void)
{
  800a25:	55                   	push   %ebp
  800a26:	89 e5                	mov    %esp,%ebp
  800a28:	57                   	push   %edi
  800a29:	56                   	push   %esi
  800a2a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a2b:	ba 00 00 00 00       	mov    $0x0,%edx
  800a30:	b8 01 00 00 00       	mov    $0x1,%eax
  800a35:	89 d1                	mov    %edx,%ecx
  800a37:	89 d3                	mov    %edx,%ebx
  800a39:	89 d7                	mov    %edx,%edi
  800a3b:	89 d6                	mov    %edx,%esi
  800a3d:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800a3f:	5b                   	pop    %ebx
  800a40:	5e                   	pop    %esi
  800a41:	5f                   	pop    %edi
  800a42:	5d                   	pop    %ebp
  800a43:	c3                   	ret    

00800a44 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800a44:	55                   	push   %ebp
  800a45:	89 e5                	mov    %esp,%ebp
  800a47:	57                   	push   %edi
  800a48:	56                   	push   %esi
  800a49:	53                   	push   %ebx
  800a4a:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a4d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800a52:	b8 03 00 00 00       	mov    $0x3,%eax
  800a57:	8b 55 08             	mov    0x8(%ebp),%edx
  800a5a:	89 cb                	mov    %ecx,%ebx
  800a5c:	89 cf                	mov    %ecx,%edi
  800a5e:	89 ce                	mov    %ecx,%esi
  800a60:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800a62:	85 c0                	test   %eax,%eax
  800a64:	7e 17                	jle    800a7d <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800a66:	83 ec 0c             	sub    $0xc,%esp
  800a69:	50                   	push   %eax
  800a6a:	6a 03                	push   $0x3
  800a6c:	68 c0 0f 80 00       	push   $0x800fc0
  800a71:	6a 23                	push   $0x23
  800a73:	68 dd 0f 80 00       	push   $0x800fdd
  800a78:	e8 27 00 00 00       	call   800aa4 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800a7d:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800a80:	5b                   	pop    %ebx
  800a81:	5e                   	pop    %esi
  800a82:	5f                   	pop    %edi
  800a83:	5d                   	pop    %ebp
  800a84:	c3                   	ret    

00800a85 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800a85:	55                   	push   %ebp
  800a86:	89 e5                	mov    %esp,%ebp
  800a88:	57                   	push   %edi
  800a89:	56                   	push   %esi
  800a8a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a8b:	ba 00 00 00 00       	mov    $0x0,%edx
  800a90:	b8 02 00 00 00       	mov    $0x2,%eax
  800a95:	89 d1                	mov    %edx,%ecx
  800a97:	89 d3                	mov    %edx,%ebx
  800a99:	89 d7                	mov    %edx,%edi
  800a9b:	89 d6                	mov    %edx,%esi
  800a9d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800a9f:	5b                   	pop    %ebx
  800aa0:	5e                   	pop    %esi
  800aa1:	5f                   	pop    %edi
  800aa2:	5d                   	pop    %ebp
  800aa3:	c3                   	ret    

00800aa4 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800aa4:	55                   	push   %ebp
  800aa5:	89 e5                	mov    %esp,%ebp
  800aa7:	56                   	push   %esi
  800aa8:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800aa9:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800aac:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800ab2:	e8 ce ff ff ff       	call   800a85 <sys_getenvid>
  800ab7:	83 ec 0c             	sub    $0xc,%esp
  800aba:	ff 75 0c             	pushl  0xc(%ebp)
  800abd:	ff 75 08             	pushl  0x8(%ebp)
  800ac0:	56                   	push   %esi
  800ac1:	50                   	push   %eax
  800ac2:	68 ec 0f 80 00       	push   $0x800fec
  800ac7:	e8 6f f6 ff ff       	call   80013b <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800acc:	83 c4 18             	add    $0x18,%esp
  800acf:	53                   	push   %ebx
  800ad0:	ff 75 10             	pushl  0x10(%ebp)
  800ad3:	e8 12 f6 ff ff       	call   8000ea <vcprintf>
	cprintf("\n");
  800ad8:	c7 04 24 8c 0d 80 00 	movl   $0x800d8c,(%esp)
  800adf:	e8 57 f6 ff ff       	call   80013b <cprintf>
  800ae4:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800ae7:	cc                   	int3   
  800ae8:	eb fd                	jmp    800ae7 <_panic+0x43>
  800aea:	66 90                	xchg   %ax,%ax
  800aec:	66 90                	xchg   %ax,%ax
  800aee:	66 90                	xchg   %ax,%ax

00800af0 <__udivdi3>:
  800af0:	55                   	push   %ebp
  800af1:	57                   	push   %edi
  800af2:	56                   	push   %esi
  800af3:	53                   	push   %ebx
  800af4:	83 ec 1c             	sub    $0x1c,%esp
  800af7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800afb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800aff:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b03:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b07:	85 f6                	test   %esi,%esi
  800b09:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b0d:	89 ca                	mov    %ecx,%edx
  800b0f:	89 f8                	mov    %edi,%eax
  800b11:	75 3d                	jne    800b50 <__udivdi3+0x60>
  800b13:	39 cf                	cmp    %ecx,%edi
  800b15:	0f 87 c5 00 00 00    	ja     800be0 <__udivdi3+0xf0>
  800b1b:	85 ff                	test   %edi,%edi
  800b1d:	89 fd                	mov    %edi,%ebp
  800b1f:	75 0b                	jne    800b2c <__udivdi3+0x3c>
  800b21:	b8 01 00 00 00       	mov    $0x1,%eax
  800b26:	31 d2                	xor    %edx,%edx
  800b28:	f7 f7                	div    %edi
  800b2a:	89 c5                	mov    %eax,%ebp
  800b2c:	89 c8                	mov    %ecx,%eax
  800b2e:	31 d2                	xor    %edx,%edx
  800b30:	f7 f5                	div    %ebp
  800b32:	89 c1                	mov    %eax,%ecx
  800b34:	89 d8                	mov    %ebx,%eax
  800b36:	89 cf                	mov    %ecx,%edi
  800b38:	f7 f5                	div    %ebp
  800b3a:	89 c3                	mov    %eax,%ebx
  800b3c:	89 d8                	mov    %ebx,%eax
  800b3e:	89 fa                	mov    %edi,%edx
  800b40:	83 c4 1c             	add    $0x1c,%esp
  800b43:	5b                   	pop    %ebx
  800b44:	5e                   	pop    %esi
  800b45:	5f                   	pop    %edi
  800b46:	5d                   	pop    %ebp
  800b47:	c3                   	ret    
  800b48:	90                   	nop
  800b49:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800b50:	39 ce                	cmp    %ecx,%esi
  800b52:	77 74                	ja     800bc8 <__udivdi3+0xd8>
  800b54:	0f bd fe             	bsr    %esi,%edi
  800b57:	83 f7 1f             	xor    $0x1f,%edi
  800b5a:	0f 84 98 00 00 00    	je     800bf8 <__udivdi3+0x108>
  800b60:	bb 20 00 00 00       	mov    $0x20,%ebx
  800b65:	89 f9                	mov    %edi,%ecx
  800b67:	89 c5                	mov    %eax,%ebp
  800b69:	29 fb                	sub    %edi,%ebx
  800b6b:	d3 e6                	shl    %cl,%esi
  800b6d:	89 d9                	mov    %ebx,%ecx
  800b6f:	d3 ed                	shr    %cl,%ebp
  800b71:	89 f9                	mov    %edi,%ecx
  800b73:	d3 e0                	shl    %cl,%eax
  800b75:	09 ee                	or     %ebp,%esi
  800b77:	89 d9                	mov    %ebx,%ecx
  800b79:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800b7d:	89 d5                	mov    %edx,%ebp
  800b7f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800b83:	d3 ed                	shr    %cl,%ebp
  800b85:	89 f9                	mov    %edi,%ecx
  800b87:	d3 e2                	shl    %cl,%edx
  800b89:	89 d9                	mov    %ebx,%ecx
  800b8b:	d3 e8                	shr    %cl,%eax
  800b8d:	09 c2                	or     %eax,%edx
  800b8f:	89 d0                	mov    %edx,%eax
  800b91:	89 ea                	mov    %ebp,%edx
  800b93:	f7 f6                	div    %esi
  800b95:	89 d5                	mov    %edx,%ebp
  800b97:	89 c3                	mov    %eax,%ebx
  800b99:	f7 64 24 0c          	mull   0xc(%esp)
  800b9d:	39 d5                	cmp    %edx,%ebp
  800b9f:	72 10                	jb     800bb1 <__udivdi3+0xc1>
  800ba1:	8b 74 24 08          	mov    0x8(%esp),%esi
  800ba5:	89 f9                	mov    %edi,%ecx
  800ba7:	d3 e6                	shl    %cl,%esi
  800ba9:	39 c6                	cmp    %eax,%esi
  800bab:	73 07                	jae    800bb4 <__udivdi3+0xc4>
  800bad:	39 d5                	cmp    %edx,%ebp
  800baf:	75 03                	jne    800bb4 <__udivdi3+0xc4>
  800bb1:	83 eb 01             	sub    $0x1,%ebx
  800bb4:	31 ff                	xor    %edi,%edi
  800bb6:	89 d8                	mov    %ebx,%eax
  800bb8:	89 fa                	mov    %edi,%edx
  800bba:	83 c4 1c             	add    $0x1c,%esp
  800bbd:	5b                   	pop    %ebx
  800bbe:	5e                   	pop    %esi
  800bbf:	5f                   	pop    %edi
  800bc0:	5d                   	pop    %ebp
  800bc1:	c3                   	ret    
  800bc2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800bc8:	31 ff                	xor    %edi,%edi
  800bca:	31 db                	xor    %ebx,%ebx
  800bcc:	89 d8                	mov    %ebx,%eax
  800bce:	89 fa                	mov    %edi,%edx
  800bd0:	83 c4 1c             	add    $0x1c,%esp
  800bd3:	5b                   	pop    %ebx
  800bd4:	5e                   	pop    %esi
  800bd5:	5f                   	pop    %edi
  800bd6:	5d                   	pop    %ebp
  800bd7:	c3                   	ret    
  800bd8:	90                   	nop
  800bd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800be0:	89 d8                	mov    %ebx,%eax
  800be2:	f7 f7                	div    %edi
  800be4:	31 ff                	xor    %edi,%edi
  800be6:	89 c3                	mov    %eax,%ebx
  800be8:	89 d8                	mov    %ebx,%eax
  800bea:	89 fa                	mov    %edi,%edx
  800bec:	83 c4 1c             	add    $0x1c,%esp
  800bef:	5b                   	pop    %ebx
  800bf0:	5e                   	pop    %esi
  800bf1:	5f                   	pop    %edi
  800bf2:	5d                   	pop    %ebp
  800bf3:	c3                   	ret    
  800bf4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800bf8:	39 ce                	cmp    %ecx,%esi
  800bfa:	72 0c                	jb     800c08 <__udivdi3+0x118>
  800bfc:	31 db                	xor    %ebx,%ebx
  800bfe:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c02:	0f 87 34 ff ff ff    	ja     800b3c <__udivdi3+0x4c>
  800c08:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c0d:	e9 2a ff ff ff       	jmp    800b3c <__udivdi3+0x4c>
  800c12:	66 90                	xchg   %ax,%ax
  800c14:	66 90                	xchg   %ax,%ax
  800c16:	66 90                	xchg   %ax,%ax
  800c18:	66 90                	xchg   %ax,%ax
  800c1a:	66 90                	xchg   %ax,%ax
  800c1c:	66 90                	xchg   %ax,%ax
  800c1e:	66 90                	xchg   %ax,%ax

00800c20 <__umoddi3>:
  800c20:	55                   	push   %ebp
  800c21:	57                   	push   %edi
  800c22:	56                   	push   %esi
  800c23:	53                   	push   %ebx
  800c24:	83 ec 1c             	sub    $0x1c,%esp
  800c27:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800c2b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800c2f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800c33:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c37:	85 d2                	test   %edx,%edx
  800c39:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800c3d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800c41:	89 f3                	mov    %esi,%ebx
  800c43:	89 3c 24             	mov    %edi,(%esp)
  800c46:	89 74 24 04          	mov    %esi,0x4(%esp)
  800c4a:	75 1c                	jne    800c68 <__umoddi3+0x48>
  800c4c:	39 f7                	cmp    %esi,%edi
  800c4e:	76 50                	jbe    800ca0 <__umoddi3+0x80>
  800c50:	89 c8                	mov    %ecx,%eax
  800c52:	89 f2                	mov    %esi,%edx
  800c54:	f7 f7                	div    %edi
  800c56:	89 d0                	mov    %edx,%eax
  800c58:	31 d2                	xor    %edx,%edx
  800c5a:	83 c4 1c             	add    $0x1c,%esp
  800c5d:	5b                   	pop    %ebx
  800c5e:	5e                   	pop    %esi
  800c5f:	5f                   	pop    %edi
  800c60:	5d                   	pop    %ebp
  800c61:	c3                   	ret    
  800c62:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c68:	39 f2                	cmp    %esi,%edx
  800c6a:	89 d0                	mov    %edx,%eax
  800c6c:	77 52                	ja     800cc0 <__umoddi3+0xa0>
  800c6e:	0f bd ea             	bsr    %edx,%ebp
  800c71:	83 f5 1f             	xor    $0x1f,%ebp
  800c74:	75 5a                	jne    800cd0 <__umoddi3+0xb0>
  800c76:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800c7a:	0f 82 e0 00 00 00    	jb     800d60 <__umoddi3+0x140>
  800c80:	39 0c 24             	cmp    %ecx,(%esp)
  800c83:	0f 86 d7 00 00 00    	jbe    800d60 <__umoddi3+0x140>
  800c89:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c8d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800c91:	83 c4 1c             	add    $0x1c,%esp
  800c94:	5b                   	pop    %ebx
  800c95:	5e                   	pop    %esi
  800c96:	5f                   	pop    %edi
  800c97:	5d                   	pop    %ebp
  800c98:	c3                   	ret    
  800c99:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800ca0:	85 ff                	test   %edi,%edi
  800ca2:	89 fd                	mov    %edi,%ebp
  800ca4:	75 0b                	jne    800cb1 <__umoddi3+0x91>
  800ca6:	b8 01 00 00 00       	mov    $0x1,%eax
  800cab:	31 d2                	xor    %edx,%edx
  800cad:	f7 f7                	div    %edi
  800caf:	89 c5                	mov    %eax,%ebp
  800cb1:	89 f0                	mov    %esi,%eax
  800cb3:	31 d2                	xor    %edx,%edx
  800cb5:	f7 f5                	div    %ebp
  800cb7:	89 c8                	mov    %ecx,%eax
  800cb9:	f7 f5                	div    %ebp
  800cbb:	89 d0                	mov    %edx,%eax
  800cbd:	eb 99                	jmp    800c58 <__umoddi3+0x38>
  800cbf:	90                   	nop
  800cc0:	89 c8                	mov    %ecx,%eax
  800cc2:	89 f2                	mov    %esi,%edx
  800cc4:	83 c4 1c             	add    $0x1c,%esp
  800cc7:	5b                   	pop    %ebx
  800cc8:	5e                   	pop    %esi
  800cc9:	5f                   	pop    %edi
  800cca:	5d                   	pop    %ebp
  800ccb:	c3                   	ret    
  800ccc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800cd0:	8b 34 24             	mov    (%esp),%esi
  800cd3:	bf 20 00 00 00       	mov    $0x20,%edi
  800cd8:	89 e9                	mov    %ebp,%ecx
  800cda:	29 ef                	sub    %ebp,%edi
  800cdc:	d3 e0                	shl    %cl,%eax
  800cde:	89 f9                	mov    %edi,%ecx
  800ce0:	89 f2                	mov    %esi,%edx
  800ce2:	d3 ea                	shr    %cl,%edx
  800ce4:	89 e9                	mov    %ebp,%ecx
  800ce6:	09 c2                	or     %eax,%edx
  800ce8:	89 d8                	mov    %ebx,%eax
  800cea:	89 14 24             	mov    %edx,(%esp)
  800ced:	89 f2                	mov    %esi,%edx
  800cef:	d3 e2                	shl    %cl,%edx
  800cf1:	89 f9                	mov    %edi,%ecx
  800cf3:	89 54 24 04          	mov    %edx,0x4(%esp)
  800cf7:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800cfb:	d3 e8                	shr    %cl,%eax
  800cfd:	89 e9                	mov    %ebp,%ecx
  800cff:	89 c6                	mov    %eax,%esi
  800d01:	d3 e3                	shl    %cl,%ebx
  800d03:	89 f9                	mov    %edi,%ecx
  800d05:	89 d0                	mov    %edx,%eax
  800d07:	d3 e8                	shr    %cl,%eax
  800d09:	89 e9                	mov    %ebp,%ecx
  800d0b:	09 d8                	or     %ebx,%eax
  800d0d:	89 d3                	mov    %edx,%ebx
  800d0f:	89 f2                	mov    %esi,%edx
  800d11:	f7 34 24             	divl   (%esp)
  800d14:	89 d6                	mov    %edx,%esi
  800d16:	d3 e3                	shl    %cl,%ebx
  800d18:	f7 64 24 04          	mull   0x4(%esp)
  800d1c:	39 d6                	cmp    %edx,%esi
  800d1e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d22:	89 d1                	mov    %edx,%ecx
  800d24:	89 c3                	mov    %eax,%ebx
  800d26:	72 08                	jb     800d30 <__umoddi3+0x110>
  800d28:	75 11                	jne    800d3b <__umoddi3+0x11b>
  800d2a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800d2e:	73 0b                	jae    800d3b <__umoddi3+0x11b>
  800d30:	2b 44 24 04          	sub    0x4(%esp),%eax
  800d34:	1b 14 24             	sbb    (%esp),%edx
  800d37:	89 d1                	mov    %edx,%ecx
  800d39:	89 c3                	mov    %eax,%ebx
  800d3b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800d3f:	29 da                	sub    %ebx,%edx
  800d41:	19 ce                	sbb    %ecx,%esi
  800d43:	89 f9                	mov    %edi,%ecx
  800d45:	89 f0                	mov    %esi,%eax
  800d47:	d3 e0                	shl    %cl,%eax
  800d49:	89 e9                	mov    %ebp,%ecx
  800d4b:	d3 ea                	shr    %cl,%edx
  800d4d:	89 e9                	mov    %ebp,%ecx
  800d4f:	d3 ee                	shr    %cl,%esi
  800d51:	09 d0                	or     %edx,%eax
  800d53:	89 f2                	mov    %esi,%edx
  800d55:	83 c4 1c             	add    $0x1c,%esp
  800d58:	5b                   	pop    %ebx
  800d59:	5e                   	pop    %esi
  800d5a:	5f                   	pop    %edi
  800d5b:	5d                   	pop    %ebp
  800d5c:	c3                   	ret    
  800d5d:	8d 76 00             	lea    0x0(%esi),%esi
  800d60:	29 f9                	sub    %edi,%ecx
  800d62:	19 d6                	sbb    %edx,%esi
  800d64:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d68:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d6c:	e9 18 ff ff ff       	jmp    800c89 <__umoddi3+0x69>

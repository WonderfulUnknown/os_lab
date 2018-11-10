
obj/user/faultread：     文件格式 elf32-i386


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
  80002c:	e8 1d 00 00 00       	call   80004e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	cprintf("I read %08x from location 0!\n", *(unsigned*)0);
  800039:	ff 35 00 00 00 00    	pushl  0x0
  80003f:	68 80 0d 80 00       	push   $0x800d80
  800044:	e8 e0 00 00 00       	call   800129 <cprintf>
}
  800049:	83 c4 10             	add    $0x10,%esp
  80004c:	c9                   	leave  
  80004d:	c3                   	ret    

0080004e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80004e:	55                   	push   %ebp
  80004f:	89 e5                	mov    %esp,%ebp
  800051:	83 ec 08             	sub    $0x8,%esp
  800054:	8b 45 08             	mov    0x8(%ebp),%eax
  800057:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80005a:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800061:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800064:	85 c0                	test   %eax,%eax
  800066:	7e 08                	jle    800070 <libmain+0x22>
		binaryname = argv[0];
  800068:	8b 0a                	mov    (%edx),%ecx
  80006a:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800070:	83 ec 08             	sub    $0x8,%esp
  800073:	52                   	push   %edx
  800074:	50                   	push   %eax
  800075:	e8 b9 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80007a:	e8 05 00 00 00       	call   800084 <exit>
}
  80007f:	83 c4 10             	add    $0x10,%esp
  800082:	c9                   	leave  
  800083:	c3                   	ret    

00800084 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800084:	55                   	push   %ebp
  800085:	89 e5                	mov    %esp,%ebp
  800087:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80008a:	6a 00                	push   $0x0
  80008c:	e8 a1 09 00 00       	call   800a32 <sys_env_destroy>
}
  800091:	83 c4 10             	add    $0x10,%esp
  800094:	c9                   	leave  
  800095:	c3                   	ret    

00800096 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800096:	55                   	push   %ebp
  800097:	89 e5                	mov    %esp,%ebp
  800099:	53                   	push   %ebx
  80009a:	83 ec 04             	sub    $0x4,%esp
  80009d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000a0:	8b 13                	mov    (%ebx),%edx
  8000a2:	8d 42 01             	lea    0x1(%edx),%eax
  8000a5:	89 03                	mov    %eax,(%ebx)
  8000a7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000aa:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000ae:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000b3:	75 1a                	jne    8000cf <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000b5:	83 ec 08             	sub    $0x8,%esp
  8000b8:	68 ff 00 00 00       	push   $0xff
  8000bd:	8d 43 08             	lea    0x8(%ebx),%eax
  8000c0:	50                   	push   %eax
  8000c1:	e8 2f 09 00 00       	call   8009f5 <sys_cputs>
		b->idx = 0;
  8000c6:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000cc:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000cf:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000d3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000d6:	c9                   	leave  
  8000d7:	c3                   	ret    

008000d8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000d8:	55                   	push   %ebp
  8000d9:	89 e5                	mov    %esp,%ebp
  8000db:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000e1:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000e8:	00 00 00 
	b.cnt = 0;
  8000eb:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8000f2:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8000f5:	ff 75 0c             	pushl  0xc(%ebp)
  8000f8:	ff 75 08             	pushl  0x8(%ebp)
  8000fb:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800101:	50                   	push   %eax
  800102:	68 96 00 80 00       	push   $0x800096
  800107:	e8 54 01 00 00       	call   800260 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80010c:	83 c4 08             	add    $0x8,%esp
  80010f:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800115:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80011b:	50                   	push   %eax
  80011c:	e8 d4 08 00 00       	call   8009f5 <sys_cputs>

	return b.cnt;
}
  800121:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800127:	c9                   	leave  
  800128:	c3                   	ret    

00800129 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800129:	55                   	push   %ebp
  80012a:	89 e5                	mov    %esp,%ebp
  80012c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80012f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800132:	50                   	push   %eax
  800133:	ff 75 08             	pushl  0x8(%ebp)
  800136:	e8 9d ff ff ff       	call   8000d8 <vcprintf>
	va_end(ap);

	return cnt;
}
  80013b:	c9                   	leave  
  80013c:	c3                   	ret    

0080013d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80013d:	55                   	push   %ebp
  80013e:	89 e5                	mov    %esp,%ebp
  800140:	57                   	push   %edi
  800141:	56                   	push   %esi
  800142:	53                   	push   %ebx
  800143:	83 ec 1c             	sub    $0x1c,%esp
  800146:	89 c7                	mov    %eax,%edi
  800148:	89 d6                	mov    %edx,%esi
  80014a:	8b 45 08             	mov    0x8(%ebp),%eax
  80014d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800150:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800153:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800156:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800159:	bb 00 00 00 00       	mov    $0x0,%ebx
  80015e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800161:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800164:	39 d3                	cmp    %edx,%ebx
  800166:	72 05                	jb     80016d <printnum+0x30>
  800168:	39 45 10             	cmp    %eax,0x10(%ebp)
  80016b:	77 45                	ja     8001b2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80016d:	83 ec 0c             	sub    $0xc,%esp
  800170:	ff 75 18             	pushl  0x18(%ebp)
  800173:	8b 45 14             	mov    0x14(%ebp),%eax
  800176:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800179:	53                   	push   %ebx
  80017a:	ff 75 10             	pushl  0x10(%ebp)
  80017d:	83 ec 08             	sub    $0x8,%esp
  800180:	ff 75 e4             	pushl  -0x1c(%ebp)
  800183:	ff 75 e0             	pushl  -0x20(%ebp)
  800186:	ff 75 dc             	pushl  -0x24(%ebp)
  800189:	ff 75 d8             	pushl  -0x28(%ebp)
  80018c:	e8 4f 09 00 00       	call   800ae0 <__udivdi3>
  800191:	83 c4 18             	add    $0x18,%esp
  800194:	52                   	push   %edx
  800195:	50                   	push   %eax
  800196:	89 f2                	mov    %esi,%edx
  800198:	89 f8                	mov    %edi,%eax
  80019a:	e8 9e ff ff ff       	call   80013d <printnum>
  80019f:	83 c4 20             	add    $0x20,%esp
  8001a2:	eb 18                	jmp    8001bc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001a4:	83 ec 08             	sub    $0x8,%esp
  8001a7:	56                   	push   %esi
  8001a8:	ff 75 18             	pushl  0x18(%ebp)
  8001ab:	ff d7                	call   *%edi
  8001ad:	83 c4 10             	add    $0x10,%esp
  8001b0:	eb 03                	jmp    8001b5 <printnum+0x78>
  8001b2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001b5:	83 eb 01             	sub    $0x1,%ebx
  8001b8:	85 db                	test   %ebx,%ebx
  8001ba:	7f e8                	jg     8001a4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001bc:	83 ec 08             	sub    $0x8,%esp
  8001bf:	56                   	push   %esi
  8001c0:	83 ec 04             	sub    $0x4,%esp
  8001c3:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001c6:	ff 75 e0             	pushl  -0x20(%ebp)
  8001c9:	ff 75 dc             	pushl  -0x24(%ebp)
  8001cc:	ff 75 d8             	pushl  -0x28(%ebp)
  8001cf:	e8 3c 0a 00 00       	call   800c10 <__umoddi3>
  8001d4:	83 c4 14             	add    $0x14,%esp
  8001d7:	0f be 80 a8 0d 80 00 	movsbl 0x800da8(%eax),%eax
  8001de:	50                   	push   %eax
  8001df:	ff d7                	call   *%edi
}
  8001e1:	83 c4 10             	add    $0x10,%esp
  8001e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001e7:	5b                   	pop    %ebx
  8001e8:	5e                   	pop    %esi
  8001e9:	5f                   	pop    %edi
  8001ea:	5d                   	pop    %ebp
  8001eb:	c3                   	ret    

008001ec <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8001ec:	55                   	push   %ebp
  8001ed:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8001ef:	83 fa 01             	cmp    $0x1,%edx
  8001f2:	7e 0e                	jle    800202 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8001f4:	8b 10                	mov    (%eax),%edx
  8001f6:	8d 4a 08             	lea    0x8(%edx),%ecx
  8001f9:	89 08                	mov    %ecx,(%eax)
  8001fb:	8b 02                	mov    (%edx),%eax
  8001fd:	8b 52 04             	mov    0x4(%edx),%edx
  800200:	eb 22                	jmp    800224 <getuint+0x38>
	else if (lflag)
  800202:	85 d2                	test   %edx,%edx
  800204:	74 10                	je     800216 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800206:	8b 10                	mov    (%eax),%edx
  800208:	8d 4a 04             	lea    0x4(%edx),%ecx
  80020b:	89 08                	mov    %ecx,(%eax)
  80020d:	8b 02                	mov    (%edx),%eax
  80020f:	ba 00 00 00 00       	mov    $0x0,%edx
  800214:	eb 0e                	jmp    800224 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800216:	8b 10                	mov    (%eax),%edx
  800218:	8d 4a 04             	lea    0x4(%edx),%ecx
  80021b:	89 08                	mov    %ecx,(%eax)
  80021d:	8b 02                	mov    (%edx),%eax
  80021f:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800224:	5d                   	pop    %ebp
  800225:	c3                   	ret    

00800226 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800226:	55                   	push   %ebp
  800227:	89 e5                	mov    %esp,%ebp
  800229:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80022c:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800230:	8b 10                	mov    (%eax),%edx
  800232:	3b 50 04             	cmp    0x4(%eax),%edx
  800235:	73 0a                	jae    800241 <sprintputch+0x1b>
		*b->buf++ = ch;
  800237:	8d 4a 01             	lea    0x1(%edx),%ecx
  80023a:	89 08                	mov    %ecx,(%eax)
  80023c:	8b 45 08             	mov    0x8(%ebp),%eax
  80023f:	88 02                	mov    %al,(%edx)
}
  800241:	5d                   	pop    %ebp
  800242:	c3                   	ret    

00800243 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800243:	55                   	push   %ebp
  800244:	89 e5                	mov    %esp,%ebp
  800246:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800249:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80024c:	50                   	push   %eax
  80024d:	ff 75 10             	pushl  0x10(%ebp)
  800250:	ff 75 0c             	pushl  0xc(%ebp)
  800253:	ff 75 08             	pushl  0x8(%ebp)
  800256:	e8 05 00 00 00       	call   800260 <vprintfmt>
	va_end(ap);
}
  80025b:	83 c4 10             	add    $0x10,%esp
  80025e:	c9                   	leave  
  80025f:	c3                   	ret    

00800260 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800260:	55                   	push   %ebp
  800261:	89 e5                	mov    %esp,%ebp
  800263:	57                   	push   %edi
  800264:	56                   	push   %esi
  800265:	53                   	push   %ebx
  800266:	83 ec 2c             	sub    $0x2c,%esp
  800269:	8b 75 08             	mov    0x8(%ebp),%esi
  80026c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80026f:	8b 7d 10             	mov    0x10(%ebp),%edi
  800272:	eb 12                	jmp    800286 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800274:	85 c0                	test   %eax,%eax
  800276:	0f 84 89 03 00 00    	je     800605 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  80027c:	83 ec 08             	sub    $0x8,%esp
  80027f:	53                   	push   %ebx
  800280:	50                   	push   %eax
  800281:	ff d6                	call   *%esi
  800283:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800286:	83 c7 01             	add    $0x1,%edi
  800289:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80028d:	83 f8 25             	cmp    $0x25,%eax
  800290:	75 e2                	jne    800274 <vprintfmt+0x14>
  800292:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800296:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80029d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002a4:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8002ab:	ba 00 00 00 00       	mov    $0x0,%edx
  8002b0:	eb 07                	jmp    8002b9 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002b2:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8002b5:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002b9:	8d 47 01             	lea    0x1(%edi),%eax
  8002bc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002bf:	0f b6 07             	movzbl (%edi),%eax
  8002c2:	0f b6 c8             	movzbl %al,%ecx
  8002c5:	83 e8 23             	sub    $0x23,%eax
  8002c8:	3c 55                	cmp    $0x55,%al
  8002ca:	0f 87 1a 03 00 00    	ja     8005ea <vprintfmt+0x38a>
  8002d0:	0f b6 c0             	movzbl %al,%eax
  8002d3:	ff 24 85 40 0e 80 00 	jmp    *0x800e40(,%eax,4)
  8002da:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8002dd:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8002e1:	eb d6                	jmp    8002b9 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002e3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002e6:	b8 00 00 00 00       	mov    $0x0,%eax
  8002eb:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8002ee:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8002f1:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  8002f5:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  8002f8:	8d 51 d0             	lea    -0x30(%ecx),%edx
  8002fb:	83 fa 09             	cmp    $0x9,%edx
  8002fe:	77 39                	ja     800339 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800300:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800303:	eb e9                	jmp    8002ee <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800305:	8b 45 14             	mov    0x14(%ebp),%eax
  800308:	8d 48 04             	lea    0x4(%eax),%ecx
  80030b:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80030e:	8b 00                	mov    (%eax),%eax
  800310:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800313:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800316:	eb 27                	jmp    80033f <vprintfmt+0xdf>
  800318:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80031b:	85 c0                	test   %eax,%eax
  80031d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800322:	0f 49 c8             	cmovns %eax,%ecx
  800325:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800328:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80032b:	eb 8c                	jmp    8002b9 <vprintfmt+0x59>
  80032d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800330:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800337:	eb 80                	jmp    8002b9 <vprintfmt+0x59>
  800339:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80033c:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80033f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800343:	0f 89 70 ff ff ff    	jns    8002b9 <vprintfmt+0x59>
				width = precision, precision = -1;
  800349:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80034c:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80034f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800356:	e9 5e ff ff ff       	jmp    8002b9 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80035b:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80035e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800361:	e9 53 ff ff ff       	jmp    8002b9 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800366:	8b 45 14             	mov    0x14(%ebp),%eax
  800369:	8d 50 04             	lea    0x4(%eax),%edx
  80036c:	89 55 14             	mov    %edx,0x14(%ebp)
  80036f:	83 ec 08             	sub    $0x8,%esp
  800372:	53                   	push   %ebx
  800373:	ff 30                	pushl  (%eax)
  800375:	ff d6                	call   *%esi
			break;
  800377:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80037a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80037d:	e9 04 ff ff ff       	jmp    800286 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800382:	8b 45 14             	mov    0x14(%ebp),%eax
  800385:	8d 50 04             	lea    0x4(%eax),%edx
  800388:	89 55 14             	mov    %edx,0x14(%ebp)
  80038b:	8b 00                	mov    (%eax),%eax
  80038d:	99                   	cltd   
  80038e:	31 d0                	xor    %edx,%eax
  800390:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800392:	83 f8 07             	cmp    $0x7,%eax
  800395:	7f 0b                	jg     8003a2 <vprintfmt+0x142>
  800397:	8b 14 85 a0 0f 80 00 	mov    0x800fa0(,%eax,4),%edx
  80039e:	85 d2                	test   %edx,%edx
  8003a0:	75 18                	jne    8003ba <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8003a2:	50                   	push   %eax
  8003a3:	68 c0 0d 80 00       	push   $0x800dc0
  8003a8:	53                   	push   %ebx
  8003a9:	56                   	push   %esi
  8003aa:	e8 94 fe ff ff       	call   800243 <printfmt>
  8003af:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003b5:	e9 cc fe ff ff       	jmp    800286 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003ba:	52                   	push   %edx
  8003bb:	68 c9 0d 80 00       	push   $0x800dc9
  8003c0:	53                   	push   %ebx
  8003c1:	56                   	push   %esi
  8003c2:	e8 7c fe ff ff       	call   800243 <printfmt>
  8003c7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003cd:	e9 b4 fe ff ff       	jmp    800286 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003d2:	8b 45 14             	mov    0x14(%ebp),%eax
  8003d5:	8d 50 04             	lea    0x4(%eax),%edx
  8003d8:	89 55 14             	mov    %edx,0x14(%ebp)
  8003db:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8003dd:	85 ff                	test   %edi,%edi
  8003df:	b8 b9 0d 80 00       	mov    $0x800db9,%eax
  8003e4:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8003e7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003eb:	0f 8e 94 00 00 00    	jle    800485 <vprintfmt+0x225>
  8003f1:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8003f5:	0f 84 98 00 00 00    	je     800493 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  8003fb:	83 ec 08             	sub    $0x8,%esp
  8003fe:	ff 75 d0             	pushl  -0x30(%ebp)
  800401:	57                   	push   %edi
  800402:	e8 86 02 00 00       	call   80068d <strnlen>
  800407:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80040a:	29 c1                	sub    %eax,%ecx
  80040c:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  80040f:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800412:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800416:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800419:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80041c:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80041e:	eb 0f                	jmp    80042f <vprintfmt+0x1cf>
					putch(padc, putdat);
  800420:	83 ec 08             	sub    $0x8,%esp
  800423:	53                   	push   %ebx
  800424:	ff 75 e0             	pushl  -0x20(%ebp)
  800427:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800429:	83 ef 01             	sub    $0x1,%edi
  80042c:	83 c4 10             	add    $0x10,%esp
  80042f:	85 ff                	test   %edi,%edi
  800431:	7f ed                	jg     800420 <vprintfmt+0x1c0>
  800433:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800436:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  800439:	85 c9                	test   %ecx,%ecx
  80043b:	b8 00 00 00 00       	mov    $0x0,%eax
  800440:	0f 49 c1             	cmovns %ecx,%eax
  800443:	29 c1                	sub    %eax,%ecx
  800445:	89 75 08             	mov    %esi,0x8(%ebp)
  800448:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80044b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80044e:	89 cb                	mov    %ecx,%ebx
  800450:	eb 4d                	jmp    80049f <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800452:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800456:	74 1b                	je     800473 <vprintfmt+0x213>
  800458:	0f be c0             	movsbl %al,%eax
  80045b:	83 e8 20             	sub    $0x20,%eax
  80045e:	83 f8 5e             	cmp    $0x5e,%eax
  800461:	76 10                	jbe    800473 <vprintfmt+0x213>
					putch('?', putdat);
  800463:	83 ec 08             	sub    $0x8,%esp
  800466:	ff 75 0c             	pushl  0xc(%ebp)
  800469:	6a 3f                	push   $0x3f
  80046b:	ff 55 08             	call   *0x8(%ebp)
  80046e:	83 c4 10             	add    $0x10,%esp
  800471:	eb 0d                	jmp    800480 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800473:	83 ec 08             	sub    $0x8,%esp
  800476:	ff 75 0c             	pushl  0xc(%ebp)
  800479:	52                   	push   %edx
  80047a:	ff 55 08             	call   *0x8(%ebp)
  80047d:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800480:	83 eb 01             	sub    $0x1,%ebx
  800483:	eb 1a                	jmp    80049f <vprintfmt+0x23f>
  800485:	89 75 08             	mov    %esi,0x8(%ebp)
  800488:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80048b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80048e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800491:	eb 0c                	jmp    80049f <vprintfmt+0x23f>
  800493:	89 75 08             	mov    %esi,0x8(%ebp)
  800496:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800499:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80049c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80049f:	83 c7 01             	add    $0x1,%edi
  8004a2:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004a6:	0f be d0             	movsbl %al,%edx
  8004a9:	85 d2                	test   %edx,%edx
  8004ab:	74 23                	je     8004d0 <vprintfmt+0x270>
  8004ad:	85 f6                	test   %esi,%esi
  8004af:	78 a1                	js     800452 <vprintfmt+0x1f2>
  8004b1:	83 ee 01             	sub    $0x1,%esi
  8004b4:	79 9c                	jns    800452 <vprintfmt+0x1f2>
  8004b6:	89 df                	mov    %ebx,%edi
  8004b8:	8b 75 08             	mov    0x8(%ebp),%esi
  8004bb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004be:	eb 18                	jmp    8004d8 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004c0:	83 ec 08             	sub    $0x8,%esp
  8004c3:	53                   	push   %ebx
  8004c4:	6a 20                	push   $0x20
  8004c6:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004c8:	83 ef 01             	sub    $0x1,%edi
  8004cb:	83 c4 10             	add    $0x10,%esp
  8004ce:	eb 08                	jmp    8004d8 <vprintfmt+0x278>
  8004d0:	89 df                	mov    %ebx,%edi
  8004d2:	8b 75 08             	mov    0x8(%ebp),%esi
  8004d5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004d8:	85 ff                	test   %edi,%edi
  8004da:	7f e4                	jg     8004c0 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004dc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004df:	e9 a2 fd ff ff       	jmp    800286 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8004e4:	83 fa 01             	cmp    $0x1,%edx
  8004e7:	7e 16                	jle    8004ff <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  8004e9:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ec:	8d 50 08             	lea    0x8(%eax),%edx
  8004ef:	89 55 14             	mov    %edx,0x14(%ebp)
  8004f2:	8b 50 04             	mov    0x4(%eax),%edx
  8004f5:	8b 00                	mov    (%eax),%eax
  8004f7:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004fa:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8004fd:	eb 32                	jmp    800531 <vprintfmt+0x2d1>
	else if (lflag)
  8004ff:	85 d2                	test   %edx,%edx
  800501:	74 18                	je     80051b <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  800503:	8b 45 14             	mov    0x14(%ebp),%eax
  800506:	8d 50 04             	lea    0x4(%eax),%edx
  800509:	89 55 14             	mov    %edx,0x14(%ebp)
  80050c:	8b 00                	mov    (%eax),%eax
  80050e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800511:	89 c1                	mov    %eax,%ecx
  800513:	c1 f9 1f             	sar    $0x1f,%ecx
  800516:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800519:	eb 16                	jmp    800531 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  80051b:	8b 45 14             	mov    0x14(%ebp),%eax
  80051e:	8d 50 04             	lea    0x4(%eax),%edx
  800521:	89 55 14             	mov    %edx,0x14(%ebp)
  800524:	8b 00                	mov    (%eax),%eax
  800526:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800529:	89 c1                	mov    %eax,%ecx
  80052b:	c1 f9 1f             	sar    $0x1f,%ecx
  80052e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800531:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800534:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800537:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80053c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800540:	79 74                	jns    8005b6 <vprintfmt+0x356>
				putch('-', putdat);
  800542:	83 ec 08             	sub    $0x8,%esp
  800545:	53                   	push   %ebx
  800546:	6a 2d                	push   $0x2d
  800548:	ff d6                	call   *%esi
				num = -(long long) num;
  80054a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80054d:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800550:	f7 d8                	neg    %eax
  800552:	83 d2 00             	adc    $0x0,%edx
  800555:	f7 da                	neg    %edx
  800557:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80055a:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80055f:	eb 55                	jmp    8005b6 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800561:	8d 45 14             	lea    0x14(%ebp),%eax
  800564:	e8 83 fc ff ff       	call   8001ec <getuint>
			base = 10;
  800569:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80056e:	eb 46                	jmp    8005b6 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800570:	8d 45 14             	lea    0x14(%ebp),%eax
  800573:	e8 74 fc ff ff       	call   8001ec <getuint>
			base = 8;
  800578:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80057d:	eb 37                	jmp    8005b6 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  80057f:	83 ec 08             	sub    $0x8,%esp
  800582:	53                   	push   %ebx
  800583:	6a 30                	push   $0x30
  800585:	ff d6                	call   *%esi
			putch('x', putdat);
  800587:	83 c4 08             	add    $0x8,%esp
  80058a:	53                   	push   %ebx
  80058b:	6a 78                	push   $0x78
  80058d:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80058f:	8b 45 14             	mov    0x14(%ebp),%eax
  800592:	8d 50 04             	lea    0x4(%eax),%edx
  800595:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800598:	8b 00                	mov    (%eax),%eax
  80059a:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  80059f:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8005a2:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8005a7:	eb 0d                	jmp    8005b6 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8005a9:	8d 45 14             	lea    0x14(%ebp),%eax
  8005ac:	e8 3b fc ff ff       	call   8001ec <getuint>
			base = 16;
  8005b1:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8005b6:	83 ec 0c             	sub    $0xc,%esp
  8005b9:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8005bd:	57                   	push   %edi
  8005be:	ff 75 e0             	pushl  -0x20(%ebp)
  8005c1:	51                   	push   %ecx
  8005c2:	52                   	push   %edx
  8005c3:	50                   	push   %eax
  8005c4:	89 da                	mov    %ebx,%edx
  8005c6:	89 f0                	mov    %esi,%eax
  8005c8:	e8 70 fb ff ff       	call   80013d <printnum>
			break;
  8005cd:	83 c4 20             	add    $0x20,%esp
  8005d0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005d3:	e9 ae fc ff ff       	jmp    800286 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8005d8:	83 ec 08             	sub    $0x8,%esp
  8005db:	53                   	push   %ebx
  8005dc:	51                   	push   %ecx
  8005dd:	ff d6                	call   *%esi
			break;
  8005df:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005e2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8005e5:	e9 9c fc ff ff       	jmp    800286 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8005ea:	83 ec 08             	sub    $0x8,%esp
  8005ed:	53                   	push   %ebx
  8005ee:	6a 25                	push   $0x25
  8005f0:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8005f2:	83 c4 10             	add    $0x10,%esp
  8005f5:	eb 03                	jmp    8005fa <vprintfmt+0x39a>
  8005f7:	83 ef 01             	sub    $0x1,%edi
  8005fa:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8005fe:	75 f7                	jne    8005f7 <vprintfmt+0x397>
  800600:	e9 81 fc ff ff       	jmp    800286 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800605:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800608:	5b                   	pop    %ebx
  800609:	5e                   	pop    %esi
  80060a:	5f                   	pop    %edi
  80060b:	5d                   	pop    %ebp
  80060c:	c3                   	ret    

0080060d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80060d:	55                   	push   %ebp
  80060e:	89 e5                	mov    %esp,%ebp
  800610:	83 ec 18             	sub    $0x18,%esp
  800613:	8b 45 08             	mov    0x8(%ebp),%eax
  800616:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800619:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80061c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800620:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800623:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80062a:	85 c0                	test   %eax,%eax
  80062c:	74 26                	je     800654 <vsnprintf+0x47>
  80062e:	85 d2                	test   %edx,%edx
  800630:	7e 22                	jle    800654 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800632:	ff 75 14             	pushl  0x14(%ebp)
  800635:	ff 75 10             	pushl  0x10(%ebp)
  800638:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80063b:	50                   	push   %eax
  80063c:	68 26 02 80 00       	push   $0x800226
  800641:	e8 1a fc ff ff       	call   800260 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800646:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800649:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80064c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80064f:	83 c4 10             	add    $0x10,%esp
  800652:	eb 05                	jmp    800659 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800654:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800659:	c9                   	leave  
  80065a:	c3                   	ret    

0080065b <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80065b:	55                   	push   %ebp
  80065c:	89 e5                	mov    %esp,%ebp
  80065e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800661:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800664:	50                   	push   %eax
  800665:	ff 75 10             	pushl  0x10(%ebp)
  800668:	ff 75 0c             	pushl  0xc(%ebp)
  80066b:	ff 75 08             	pushl  0x8(%ebp)
  80066e:	e8 9a ff ff ff       	call   80060d <vsnprintf>
	va_end(ap);

	return rc;
}
  800673:	c9                   	leave  
  800674:	c3                   	ret    

00800675 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800675:	55                   	push   %ebp
  800676:	89 e5                	mov    %esp,%ebp
  800678:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80067b:	b8 00 00 00 00       	mov    $0x0,%eax
  800680:	eb 03                	jmp    800685 <strlen+0x10>
		n++;
  800682:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800685:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800689:	75 f7                	jne    800682 <strlen+0xd>
		n++;
	return n;
}
  80068b:	5d                   	pop    %ebp
  80068c:	c3                   	ret    

0080068d <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80068d:	55                   	push   %ebp
  80068e:	89 e5                	mov    %esp,%ebp
  800690:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800693:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800696:	ba 00 00 00 00       	mov    $0x0,%edx
  80069b:	eb 03                	jmp    8006a0 <strnlen+0x13>
		n++;
  80069d:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006a0:	39 c2                	cmp    %eax,%edx
  8006a2:	74 08                	je     8006ac <strnlen+0x1f>
  8006a4:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8006a8:	75 f3                	jne    80069d <strnlen+0x10>
  8006aa:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8006ac:	5d                   	pop    %ebp
  8006ad:	c3                   	ret    

008006ae <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8006ae:	55                   	push   %ebp
  8006af:	89 e5                	mov    %esp,%ebp
  8006b1:	53                   	push   %ebx
  8006b2:	8b 45 08             	mov    0x8(%ebp),%eax
  8006b5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8006b8:	89 c2                	mov    %eax,%edx
  8006ba:	83 c2 01             	add    $0x1,%edx
  8006bd:	83 c1 01             	add    $0x1,%ecx
  8006c0:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8006c4:	88 5a ff             	mov    %bl,-0x1(%edx)
  8006c7:	84 db                	test   %bl,%bl
  8006c9:	75 ef                	jne    8006ba <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8006cb:	5b                   	pop    %ebx
  8006cc:	5d                   	pop    %ebp
  8006cd:	c3                   	ret    

008006ce <strcat>:

char *
strcat(char *dst, const char *src)
{
  8006ce:	55                   	push   %ebp
  8006cf:	89 e5                	mov    %esp,%ebp
  8006d1:	53                   	push   %ebx
  8006d2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8006d5:	53                   	push   %ebx
  8006d6:	e8 9a ff ff ff       	call   800675 <strlen>
  8006db:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8006de:	ff 75 0c             	pushl  0xc(%ebp)
  8006e1:	01 d8                	add    %ebx,%eax
  8006e3:	50                   	push   %eax
  8006e4:	e8 c5 ff ff ff       	call   8006ae <strcpy>
	return dst;
}
  8006e9:	89 d8                	mov    %ebx,%eax
  8006eb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8006ee:	c9                   	leave  
  8006ef:	c3                   	ret    

008006f0 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8006f0:	55                   	push   %ebp
  8006f1:	89 e5                	mov    %esp,%ebp
  8006f3:	56                   	push   %esi
  8006f4:	53                   	push   %ebx
  8006f5:	8b 75 08             	mov    0x8(%ebp),%esi
  8006f8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8006fb:	89 f3                	mov    %esi,%ebx
  8006fd:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800700:	89 f2                	mov    %esi,%edx
  800702:	eb 0f                	jmp    800713 <strncpy+0x23>
		*dst++ = *src;
  800704:	83 c2 01             	add    $0x1,%edx
  800707:	0f b6 01             	movzbl (%ecx),%eax
  80070a:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80070d:	80 39 01             	cmpb   $0x1,(%ecx)
  800710:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800713:	39 da                	cmp    %ebx,%edx
  800715:	75 ed                	jne    800704 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800717:	89 f0                	mov    %esi,%eax
  800719:	5b                   	pop    %ebx
  80071a:	5e                   	pop    %esi
  80071b:	5d                   	pop    %ebp
  80071c:	c3                   	ret    

0080071d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80071d:	55                   	push   %ebp
  80071e:	89 e5                	mov    %esp,%ebp
  800720:	56                   	push   %esi
  800721:	53                   	push   %ebx
  800722:	8b 75 08             	mov    0x8(%ebp),%esi
  800725:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800728:	8b 55 10             	mov    0x10(%ebp),%edx
  80072b:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80072d:	85 d2                	test   %edx,%edx
  80072f:	74 21                	je     800752 <strlcpy+0x35>
  800731:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800735:	89 f2                	mov    %esi,%edx
  800737:	eb 09                	jmp    800742 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800739:	83 c2 01             	add    $0x1,%edx
  80073c:	83 c1 01             	add    $0x1,%ecx
  80073f:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800742:	39 c2                	cmp    %eax,%edx
  800744:	74 09                	je     80074f <strlcpy+0x32>
  800746:	0f b6 19             	movzbl (%ecx),%ebx
  800749:	84 db                	test   %bl,%bl
  80074b:	75 ec                	jne    800739 <strlcpy+0x1c>
  80074d:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80074f:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800752:	29 f0                	sub    %esi,%eax
}
  800754:	5b                   	pop    %ebx
  800755:	5e                   	pop    %esi
  800756:	5d                   	pop    %ebp
  800757:	c3                   	ret    

00800758 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800758:	55                   	push   %ebp
  800759:	89 e5                	mov    %esp,%ebp
  80075b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80075e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800761:	eb 06                	jmp    800769 <strcmp+0x11>
		p++, q++;
  800763:	83 c1 01             	add    $0x1,%ecx
  800766:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800769:	0f b6 01             	movzbl (%ecx),%eax
  80076c:	84 c0                	test   %al,%al
  80076e:	74 04                	je     800774 <strcmp+0x1c>
  800770:	3a 02                	cmp    (%edx),%al
  800772:	74 ef                	je     800763 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800774:	0f b6 c0             	movzbl %al,%eax
  800777:	0f b6 12             	movzbl (%edx),%edx
  80077a:	29 d0                	sub    %edx,%eax
}
  80077c:	5d                   	pop    %ebp
  80077d:	c3                   	ret    

0080077e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80077e:	55                   	push   %ebp
  80077f:	89 e5                	mov    %esp,%ebp
  800781:	53                   	push   %ebx
  800782:	8b 45 08             	mov    0x8(%ebp),%eax
  800785:	8b 55 0c             	mov    0xc(%ebp),%edx
  800788:	89 c3                	mov    %eax,%ebx
  80078a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80078d:	eb 06                	jmp    800795 <strncmp+0x17>
		n--, p++, q++;
  80078f:	83 c0 01             	add    $0x1,%eax
  800792:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800795:	39 d8                	cmp    %ebx,%eax
  800797:	74 15                	je     8007ae <strncmp+0x30>
  800799:	0f b6 08             	movzbl (%eax),%ecx
  80079c:	84 c9                	test   %cl,%cl
  80079e:	74 04                	je     8007a4 <strncmp+0x26>
  8007a0:	3a 0a                	cmp    (%edx),%cl
  8007a2:	74 eb                	je     80078f <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8007a4:	0f b6 00             	movzbl (%eax),%eax
  8007a7:	0f b6 12             	movzbl (%edx),%edx
  8007aa:	29 d0                	sub    %edx,%eax
  8007ac:	eb 05                	jmp    8007b3 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8007ae:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8007b3:	5b                   	pop    %ebx
  8007b4:	5d                   	pop    %ebp
  8007b5:	c3                   	ret    

008007b6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8007b6:	55                   	push   %ebp
  8007b7:	89 e5                	mov    %esp,%ebp
  8007b9:	8b 45 08             	mov    0x8(%ebp),%eax
  8007bc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007c0:	eb 07                	jmp    8007c9 <strchr+0x13>
		if (*s == c)
  8007c2:	38 ca                	cmp    %cl,%dl
  8007c4:	74 0f                	je     8007d5 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8007c6:	83 c0 01             	add    $0x1,%eax
  8007c9:	0f b6 10             	movzbl (%eax),%edx
  8007cc:	84 d2                	test   %dl,%dl
  8007ce:	75 f2                	jne    8007c2 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8007d0:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8007d5:	5d                   	pop    %ebp
  8007d6:	c3                   	ret    

008007d7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8007d7:	55                   	push   %ebp
  8007d8:	89 e5                	mov    %esp,%ebp
  8007da:	8b 45 08             	mov    0x8(%ebp),%eax
  8007dd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007e1:	eb 03                	jmp    8007e6 <strfind+0xf>
  8007e3:	83 c0 01             	add    $0x1,%eax
  8007e6:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8007e9:	38 ca                	cmp    %cl,%dl
  8007eb:	74 04                	je     8007f1 <strfind+0x1a>
  8007ed:	84 d2                	test   %dl,%dl
  8007ef:	75 f2                	jne    8007e3 <strfind+0xc>
			break;
	return (char *) s;
}
  8007f1:	5d                   	pop    %ebp
  8007f2:	c3                   	ret    

008007f3 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8007f3:	55                   	push   %ebp
  8007f4:	89 e5                	mov    %esp,%ebp
  8007f6:	57                   	push   %edi
  8007f7:	56                   	push   %esi
  8007f8:	53                   	push   %ebx
  8007f9:	8b 7d 08             	mov    0x8(%ebp),%edi
  8007fc:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8007ff:	85 c9                	test   %ecx,%ecx
  800801:	74 36                	je     800839 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800803:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800809:	75 28                	jne    800833 <memset+0x40>
  80080b:	f6 c1 03             	test   $0x3,%cl
  80080e:	75 23                	jne    800833 <memset+0x40>
		c &= 0xFF;
  800810:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800814:	89 d3                	mov    %edx,%ebx
  800816:	c1 e3 08             	shl    $0x8,%ebx
  800819:	89 d6                	mov    %edx,%esi
  80081b:	c1 e6 18             	shl    $0x18,%esi
  80081e:	89 d0                	mov    %edx,%eax
  800820:	c1 e0 10             	shl    $0x10,%eax
  800823:	09 f0                	or     %esi,%eax
  800825:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800827:	89 d8                	mov    %ebx,%eax
  800829:	09 d0                	or     %edx,%eax
  80082b:	c1 e9 02             	shr    $0x2,%ecx
  80082e:	fc                   	cld    
  80082f:	f3 ab                	rep stos %eax,%es:(%edi)
  800831:	eb 06                	jmp    800839 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800833:	8b 45 0c             	mov    0xc(%ebp),%eax
  800836:	fc                   	cld    
  800837:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800839:	89 f8                	mov    %edi,%eax
  80083b:	5b                   	pop    %ebx
  80083c:	5e                   	pop    %esi
  80083d:	5f                   	pop    %edi
  80083e:	5d                   	pop    %ebp
  80083f:	c3                   	ret    

00800840 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800840:	55                   	push   %ebp
  800841:	89 e5                	mov    %esp,%ebp
  800843:	57                   	push   %edi
  800844:	56                   	push   %esi
  800845:	8b 45 08             	mov    0x8(%ebp),%eax
  800848:	8b 75 0c             	mov    0xc(%ebp),%esi
  80084b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80084e:	39 c6                	cmp    %eax,%esi
  800850:	73 35                	jae    800887 <memmove+0x47>
  800852:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800855:	39 d0                	cmp    %edx,%eax
  800857:	73 2e                	jae    800887 <memmove+0x47>
		s += n;
		d += n;
  800859:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80085c:	89 d6                	mov    %edx,%esi
  80085e:	09 fe                	or     %edi,%esi
  800860:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800866:	75 13                	jne    80087b <memmove+0x3b>
  800868:	f6 c1 03             	test   $0x3,%cl
  80086b:	75 0e                	jne    80087b <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80086d:	83 ef 04             	sub    $0x4,%edi
  800870:	8d 72 fc             	lea    -0x4(%edx),%esi
  800873:	c1 e9 02             	shr    $0x2,%ecx
  800876:	fd                   	std    
  800877:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800879:	eb 09                	jmp    800884 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80087b:	83 ef 01             	sub    $0x1,%edi
  80087e:	8d 72 ff             	lea    -0x1(%edx),%esi
  800881:	fd                   	std    
  800882:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800884:	fc                   	cld    
  800885:	eb 1d                	jmp    8008a4 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800887:	89 f2                	mov    %esi,%edx
  800889:	09 c2                	or     %eax,%edx
  80088b:	f6 c2 03             	test   $0x3,%dl
  80088e:	75 0f                	jne    80089f <memmove+0x5f>
  800890:	f6 c1 03             	test   $0x3,%cl
  800893:	75 0a                	jne    80089f <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800895:	c1 e9 02             	shr    $0x2,%ecx
  800898:	89 c7                	mov    %eax,%edi
  80089a:	fc                   	cld    
  80089b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80089d:	eb 05                	jmp    8008a4 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  80089f:	89 c7                	mov    %eax,%edi
  8008a1:	fc                   	cld    
  8008a2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8008a4:	5e                   	pop    %esi
  8008a5:	5f                   	pop    %edi
  8008a6:	5d                   	pop    %ebp
  8008a7:	c3                   	ret    

008008a8 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8008a8:	55                   	push   %ebp
  8008a9:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8008ab:	ff 75 10             	pushl  0x10(%ebp)
  8008ae:	ff 75 0c             	pushl  0xc(%ebp)
  8008b1:	ff 75 08             	pushl  0x8(%ebp)
  8008b4:	e8 87 ff ff ff       	call   800840 <memmove>
}
  8008b9:	c9                   	leave  
  8008ba:	c3                   	ret    

008008bb <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8008bb:	55                   	push   %ebp
  8008bc:	89 e5                	mov    %esp,%ebp
  8008be:	56                   	push   %esi
  8008bf:	53                   	push   %ebx
  8008c0:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c3:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008c6:	89 c6                	mov    %eax,%esi
  8008c8:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008cb:	eb 1a                	jmp    8008e7 <memcmp+0x2c>
		if (*s1 != *s2)
  8008cd:	0f b6 08             	movzbl (%eax),%ecx
  8008d0:	0f b6 1a             	movzbl (%edx),%ebx
  8008d3:	38 d9                	cmp    %bl,%cl
  8008d5:	74 0a                	je     8008e1 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8008d7:	0f b6 c1             	movzbl %cl,%eax
  8008da:	0f b6 db             	movzbl %bl,%ebx
  8008dd:	29 d8                	sub    %ebx,%eax
  8008df:	eb 0f                	jmp    8008f0 <memcmp+0x35>
		s1++, s2++;
  8008e1:	83 c0 01             	add    $0x1,%eax
  8008e4:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008e7:	39 f0                	cmp    %esi,%eax
  8008e9:	75 e2                	jne    8008cd <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8008eb:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008f0:	5b                   	pop    %ebx
  8008f1:	5e                   	pop    %esi
  8008f2:	5d                   	pop    %ebp
  8008f3:	c3                   	ret    

008008f4 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8008f4:	55                   	push   %ebp
  8008f5:	89 e5                	mov    %esp,%ebp
  8008f7:	53                   	push   %ebx
  8008f8:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8008fb:	89 c1                	mov    %eax,%ecx
  8008fd:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800900:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800904:	eb 0a                	jmp    800910 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800906:	0f b6 10             	movzbl (%eax),%edx
  800909:	39 da                	cmp    %ebx,%edx
  80090b:	74 07                	je     800914 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  80090d:	83 c0 01             	add    $0x1,%eax
  800910:	39 c8                	cmp    %ecx,%eax
  800912:	72 f2                	jb     800906 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800914:	5b                   	pop    %ebx
  800915:	5d                   	pop    %ebp
  800916:	c3                   	ret    

00800917 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800917:	55                   	push   %ebp
  800918:	89 e5                	mov    %esp,%ebp
  80091a:	57                   	push   %edi
  80091b:	56                   	push   %esi
  80091c:	53                   	push   %ebx
  80091d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800920:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800923:	eb 03                	jmp    800928 <strtol+0x11>
		s++;
  800925:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800928:	0f b6 01             	movzbl (%ecx),%eax
  80092b:	3c 20                	cmp    $0x20,%al
  80092d:	74 f6                	je     800925 <strtol+0xe>
  80092f:	3c 09                	cmp    $0x9,%al
  800931:	74 f2                	je     800925 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800933:	3c 2b                	cmp    $0x2b,%al
  800935:	75 0a                	jne    800941 <strtol+0x2a>
		s++;
  800937:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  80093a:	bf 00 00 00 00       	mov    $0x0,%edi
  80093f:	eb 11                	jmp    800952 <strtol+0x3b>
  800941:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800946:	3c 2d                	cmp    $0x2d,%al
  800948:	75 08                	jne    800952 <strtol+0x3b>
		s++, neg = 1;
  80094a:	83 c1 01             	add    $0x1,%ecx
  80094d:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800952:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800958:	75 15                	jne    80096f <strtol+0x58>
  80095a:	80 39 30             	cmpb   $0x30,(%ecx)
  80095d:	75 10                	jne    80096f <strtol+0x58>
  80095f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800963:	75 7c                	jne    8009e1 <strtol+0xca>
		s += 2, base = 16;
  800965:	83 c1 02             	add    $0x2,%ecx
  800968:	bb 10 00 00 00       	mov    $0x10,%ebx
  80096d:	eb 16                	jmp    800985 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  80096f:	85 db                	test   %ebx,%ebx
  800971:	75 12                	jne    800985 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800973:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800978:	80 39 30             	cmpb   $0x30,(%ecx)
  80097b:	75 08                	jne    800985 <strtol+0x6e>
		s++, base = 8;
  80097d:	83 c1 01             	add    $0x1,%ecx
  800980:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800985:	b8 00 00 00 00       	mov    $0x0,%eax
  80098a:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  80098d:	0f b6 11             	movzbl (%ecx),%edx
  800990:	8d 72 d0             	lea    -0x30(%edx),%esi
  800993:	89 f3                	mov    %esi,%ebx
  800995:	80 fb 09             	cmp    $0x9,%bl
  800998:	77 08                	ja     8009a2 <strtol+0x8b>
			dig = *s - '0';
  80099a:	0f be d2             	movsbl %dl,%edx
  80099d:	83 ea 30             	sub    $0x30,%edx
  8009a0:	eb 22                	jmp    8009c4 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  8009a2:	8d 72 9f             	lea    -0x61(%edx),%esi
  8009a5:	89 f3                	mov    %esi,%ebx
  8009a7:	80 fb 19             	cmp    $0x19,%bl
  8009aa:	77 08                	ja     8009b4 <strtol+0x9d>
			dig = *s - 'a' + 10;
  8009ac:	0f be d2             	movsbl %dl,%edx
  8009af:	83 ea 57             	sub    $0x57,%edx
  8009b2:	eb 10                	jmp    8009c4 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  8009b4:	8d 72 bf             	lea    -0x41(%edx),%esi
  8009b7:	89 f3                	mov    %esi,%ebx
  8009b9:	80 fb 19             	cmp    $0x19,%bl
  8009bc:	77 16                	ja     8009d4 <strtol+0xbd>
			dig = *s - 'A' + 10;
  8009be:	0f be d2             	movsbl %dl,%edx
  8009c1:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  8009c4:	3b 55 10             	cmp    0x10(%ebp),%edx
  8009c7:	7d 0b                	jge    8009d4 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  8009c9:	83 c1 01             	add    $0x1,%ecx
  8009cc:	0f af 45 10          	imul   0x10(%ebp),%eax
  8009d0:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  8009d2:	eb b9                	jmp    80098d <strtol+0x76>

	if (endptr)
  8009d4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8009d8:	74 0d                	je     8009e7 <strtol+0xd0>
		*endptr = (char *) s;
  8009da:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009dd:	89 0e                	mov    %ecx,(%esi)
  8009df:	eb 06                	jmp    8009e7 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  8009e1:	85 db                	test   %ebx,%ebx
  8009e3:	74 98                	je     80097d <strtol+0x66>
  8009e5:	eb 9e                	jmp    800985 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  8009e7:	89 c2                	mov    %eax,%edx
  8009e9:	f7 da                	neg    %edx
  8009eb:	85 ff                	test   %edi,%edi
  8009ed:	0f 45 c2             	cmovne %edx,%eax
}
  8009f0:	5b                   	pop    %ebx
  8009f1:	5e                   	pop    %esi
  8009f2:	5f                   	pop    %edi
  8009f3:	5d                   	pop    %ebp
  8009f4:	c3                   	ret    

008009f5 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8009f5:	55                   	push   %ebp
  8009f6:	89 e5                	mov    %esp,%ebp
  8009f8:	57                   	push   %edi
  8009f9:	56                   	push   %esi
  8009fa:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8009fb:	b8 00 00 00 00       	mov    $0x0,%eax
  800a00:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a03:	8b 55 08             	mov    0x8(%ebp),%edx
  800a06:	89 c3                	mov    %eax,%ebx
  800a08:	89 c7                	mov    %eax,%edi
  800a0a:	89 c6                	mov    %eax,%esi
  800a0c:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800a0e:	5b                   	pop    %ebx
  800a0f:	5e                   	pop    %esi
  800a10:	5f                   	pop    %edi
  800a11:	5d                   	pop    %ebp
  800a12:	c3                   	ret    

00800a13 <sys_cgetc>:

int
sys_cgetc(void)
{
  800a13:	55                   	push   %ebp
  800a14:	89 e5                	mov    %esp,%ebp
  800a16:	57                   	push   %edi
  800a17:	56                   	push   %esi
  800a18:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a19:	ba 00 00 00 00       	mov    $0x0,%edx
  800a1e:	b8 01 00 00 00       	mov    $0x1,%eax
  800a23:	89 d1                	mov    %edx,%ecx
  800a25:	89 d3                	mov    %edx,%ebx
  800a27:	89 d7                	mov    %edx,%edi
  800a29:	89 d6                	mov    %edx,%esi
  800a2b:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800a2d:	5b                   	pop    %ebx
  800a2e:	5e                   	pop    %esi
  800a2f:	5f                   	pop    %edi
  800a30:	5d                   	pop    %ebp
  800a31:	c3                   	ret    

00800a32 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800a32:	55                   	push   %ebp
  800a33:	89 e5                	mov    %esp,%ebp
  800a35:	57                   	push   %edi
  800a36:	56                   	push   %esi
  800a37:	53                   	push   %ebx
  800a38:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a3b:	b9 00 00 00 00       	mov    $0x0,%ecx
  800a40:	b8 03 00 00 00       	mov    $0x3,%eax
  800a45:	8b 55 08             	mov    0x8(%ebp),%edx
  800a48:	89 cb                	mov    %ecx,%ebx
  800a4a:	89 cf                	mov    %ecx,%edi
  800a4c:	89 ce                	mov    %ecx,%esi
  800a4e:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800a50:	85 c0                	test   %eax,%eax
  800a52:	7e 17                	jle    800a6b <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800a54:	83 ec 0c             	sub    $0xc,%esp
  800a57:	50                   	push   %eax
  800a58:	6a 03                	push   $0x3
  800a5a:	68 c0 0f 80 00       	push   $0x800fc0
  800a5f:	6a 23                	push   $0x23
  800a61:	68 dd 0f 80 00       	push   $0x800fdd
  800a66:	e8 27 00 00 00       	call   800a92 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800a6b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800a6e:	5b                   	pop    %ebx
  800a6f:	5e                   	pop    %esi
  800a70:	5f                   	pop    %edi
  800a71:	5d                   	pop    %ebp
  800a72:	c3                   	ret    

00800a73 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800a73:	55                   	push   %ebp
  800a74:	89 e5                	mov    %esp,%ebp
  800a76:	57                   	push   %edi
  800a77:	56                   	push   %esi
  800a78:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a79:	ba 00 00 00 00       	mov    $0x0,%edx
  800a7e:	b8 02 00 00 00       	mov    $0x2,%eax
  800a83:	89 d1                	mov    %edx,%ecx
  800a85:	89 d3                	mov    %edx,%ebx
  800a87:	89 d7                	mov    %edx,%edi
  800a89:	89 d6                	mov    %edx,%esi
  800a8b:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800a8d:	5b                   	pop    %ebx
  800a8e:	5e                   	pop    %esi
  800a8f:	5f                   	pop    %edi
  800a90:	5d                   	pop    %ebp
  800a91:	c3                   	ret    

00800a92 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800a92:	55                   	push   %ebp
  800a93:	89 e5                	mov    %esp,%ebp
  800a95:	56                   	push   %esi
  800a96:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800a97:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800a9a:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800aa0:	e8 ce ff ff ff       	call   800a73 <sys_getenvid>
  800aa5:	83 ec 0c             	sub    $0xc,%esp
  800aa8:	ff 75 0c             	pushl  0xc(%ebp)
  800aab:	ff 75 08             	pushl  0x8(%ebp)
  800aae:	56                   	push   %esi
  800aaf:	50                   	push   %eax
  800ab0:	68 ec 0f 80 00       	push   $0x800fec
  800ab5:	e8 6f f6 ff ff       	call   800129 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800aba:	83 c4 18             	add    $0x18,%esp
  800abd:	53                   	push   %ebx
  800abe:	ff 75 10             	pushl  0x10(%ebp)
  800ac1:	e8 12 f6 ff ff       	call   8000d8 <vcprintf>
	cprintf("\n");
  800ac6:	c7 04 24 9c 0d 80 00 	movl   $0x800d9c,(%esp)
  800acd:	e8 57 f6 ff ff       	call   800129 <cprintf>
  800ad2:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800ad5:	cc                   	int3   
  800ad6:	eb fd                	jmp    800ad5 <_panic+0x43>
  800ad8:	66 90                	xchg   %ax,%ax
  800ada:	66 90                	xchg   %ax,%ax
  800adc:	66 90                	xchg   %ax,%ax
  800ade:	66 90                	xchg   %ax,%ax

00800ae0 <__udivdi3>:
  800ae0:	55                   	push   %ebp
  800ae1:	57                   	push   %edi
  800ae2:	56                   	push   %esi
  800ae3:	53                   	push   %ebx
  800ae4:	83 ec 1c             	sub    $0x1c,%esp
  800ae7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800aeb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800aef:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800af3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800af7:	85 f6                	test   %esi,%esi
  800af9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800afd:	89 ca                	mov    %ecx,%edx
  800aff:	89 f8                	mov    %edi,%eax
  800b01:	75 3d                	jne    800b40 <__udivdi3+0x60>
  800b03:	39 cf                	cmp    %ecx,%edi
  800b05:	0f 87 c5 00 00 00    	ja     800bd0 <__udivdi3+0xf0>
  800b0b:	85 ff                	test   %edi,%edi
  800b0d:	89 fd                	mov    %edi,%ebp
  800b0f:	75 0b                	jne    800b1c <__udivdi3+0x3c>
  800b11:	b8 01 00 00 00       	mov    $0x1,%eax
  800b16:	31 d2                	xor    %edx,%edx
  800b18:	f7 f7                	div    %edi
  800b1a:	89 c5                	mov    %eax,%ebp
  800b1c:	89 c8                	mov    %ecx,%eax
  800b1e:	31 d2                	xor    %edx,%edx
  800b20:	f7 f5                	div    %ebp
  800b22:	89 c1                	mov    %eax,%ecx
  800b24:	89 d8                	mov    %ebx,%eax
  800b26:	89 cf                	mov    %ecx,%edi
  800b28:	f7 f5                	div    %ebp
  800b2a:	89 c3                	mov    %eax,%ebx
  800b2c:	89 d8                	mov    %ebx,%eax
  800b2e:	89 fa                	mov    %edi,%edx
  800b30:	83 c4 1c             	add    $0x1c,%esp
  800b33:	5b                   	pop    %ebx
  800b34:	5e                   	pop    %esi
  800b35:	5f                   	pop    %edi
  800b36:	5d                   	pop    %ebp
  800b37:	c3                   	ret    
  800b38:	90                   	nop
  800b39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800b40:	39 ce                	cmp    %ecx,%esi
  800b42:	77 74                	ja     800bb8 <__udivdi3+0xd8>
  800b44:	0f bd fe             	bsr    %esi,%edi
  800b47:	83 f7 1f             	xor    $0x1f,%edi
  800b4a:	0f 84 98 00 00 00    	je     800be8 <__udivdi3+0x108>
  800b50:	bb 20 00 00 00       	mov    $0x20,%ebx
  800b55:	89 f9                	mov    %edi,%ecx
  800b57:	89 c5                	mov    %eax,%ebp
  800b59:	29 fb                	sub    %edi,%ebx
  800b5b:	d3 e6                	shl    %cl,%esi
  800b5d:	89 d9                	mov    %ebx,%ecx
  800b5f:	d3 ed                	shr    %cl,%ebp
  800b61:	89 f9                	mov    %edi,%ecx
  800b63:	d3 e0                	shl    %cl,%eax
  800b65:	09 ee                	or     %ebp,%esi
  800b67:	89 d9                	mov    %ebx,%ecx
  800b69:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800b6d:	89 d5                	mov    %edx,%ebp
  800b6f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800b73:	d3 ed                	shr    %cl,%ebp
  800b75:	89 f9                	mov    %edi,%ecx
  800b77:	d3 e2                	shl    %cl,%edx
  800b79:	89 d9                	mov    %ebx,%ecx
  800b7b:	d3 e8                	shr    %cl,%eax
  800b7d:	09 c2                	or     %eax,%edx
  800b7f:	89 d0                	mov    %edx,%eax
  800b81:	89 ea                	mov    %ebp,%edx
  800b83:	f7 f6                	div    %esi
  800b85:	89 d5                	mov    %edx,%ebp
  800b87:	89 c3                	mov    %eax,%ebx
  800b89:	f7 64 24 0c          	mull   0xc(%esp)
  800b8d:	39 d5                	cmp    %edx,%ebp
  800b8f:	72 10                	jb     800ba1 <__udivdi3+0xc1>
  800b91:	8b 74 24 08          	mov    0x8(%esp),%esi
  800b95:	89 f9                	mov    %edi,%ecx
  800b97:	d3 e6                	shl    %cl,%esi
  800b99:	39 c6                	cmp    %eax,%esi
  800b9b:	73 07                	jae    800ba4 <__udivdi3+0xc4>
  800b9d:	39 d5                	cmp    %edx,%ebp
  800b9f:	75 03                	jne    800ba4 <__udivdi3+0xc4>
  800ba1:	83 eb 01             	sub    $0x1,%ebx
  800ba4:	31 ff                	xor    %edi,%edi
  800ba6:	89 d8                	mov    %ebx,%eax
  800ba8:	89 fa                	mov    %edi,%edx
  800baa:	83 c4 1c             	add    $0x1c,%esp
  800bad:	5b                   	pop    %ebx
  800bae:	5e                   	pop    %esi
  800baf:	5f                   	pop    %edi
  800bb0:	5d                   	pop    %ebp
  800bb1:	c3                   	ret    
  800bb2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800bb8:	31 ff                	xor    %edi,%edi
  800bba:	31 db                	xor    %ebx,%ebx
  800bbc:	89 d8                	mov    %ebx,%eax
  800bbe:	89 fa                	mov    %edi,%edx
  800bc0:	83 c4 1c             	add    $0x1c,%esp
  800bc3:	5b                   	pop    %ebx
  800bc4:	5e                   	pop    %esi
  800bc5:	5f                   	pop    %edi
  800bc6:	5d                   	pop    %ebp
  800bc7:	c3                   	ret    
  800bc8:	90                   	nop
  800bc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800bd0:	89 d8                	mov    %ebx,%eax
  800bd2:	f7 f7                	div    %edi
  800bd4:	31 ff                	xor    %edi,%edi
  800bd6:	89 c3                	mov    %eax,%ebx
  800bd8:	89 d8                	mov    %ebx,%eax
  800bda:	89 fa                	mov    %edi,%edx
  800bdc:	83 c4 1c             	add    $0x1c,%esp
  800bdf:	5b                   	pop    %ebx
  800be0:	5e                   	pop    %esi
  800be1:	5f                   	pop    %edi
  800be2:	5d                   	pop    %ebp
  800be3:	c3                   	ret    
  800be4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800be8:	39 ce                	cmp    %ecx,%esi
  800bea:	72 0c                	jb     800bf8 <__udivdi3+0x118>
  800bec:	31 db                	xor    %ebx,%ebx
  800bee:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800bf2:	0f 87 34 ff ff ff    	ja     800b2c <__udivdi3+0x4c>
  800bf8:	bb 01 00 00 00       	mov    $0x1,%ebx
  800bfd:	e9 2a ff ff ff       	jmp    800b2c <__udivdi3+0x4c>
  800c02:	66 90                	xchg   %ax,%ax
  800c04:	66 90                	xchg   %ax,%ax
  800c06:	66 90                	xchg   %ax,%ax
  800c08:	66 90                	xchg   %ax,%ax
  800c0a:	66 90                	xchg   %ax,%ax
  800c0c:	66 90                	xchg   %ax,%ax
  800c0e:	66 90                	xchg   %ax,%ax

00800c10 <__umoddi3>:
  800c10:	55                   	push   %ebp
  800c11:	57                   	push   %edi
  800c12:	56                   	push   %esi
  800c13:	53                   	push   %ebx
  800c14:	83 ec 1c             	sub    $0x1c,%esp
  800c17:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800c1b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800c1f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800c23:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c27:	85 d2                	test   %edx,%edx
  800c29:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800c2d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800c31:	89 f3                	mov    %esi,%ebx
  800c33:	89 3c 24             	mov    %edi,(%esp)
  800c36:	89 74 24 04          	mov    %esi,0x4(%esp)
  800c3a:	75 1c                	jne    800c58 <__umoddi3+0x48>
  800c3c:	39 f7                	cmp    %esi,%edi
  800c3e:	76 50                	jbe    800c90 <__umoddi3+0x80>
  800c40:	89 c8                	mov    %ecx,%eax
  800c42:	89 f2                	mov    %esi,%edx
  800c44:	f7 f7                	div    %edi
  800c46:	89 d0                	mov    %edx,%eax
  800c48:	31 d2                	xor    %edx,%edx
  800c4a:	83 c4 1c             	add    $0x1c,%esp
  800c4d:	5b                   	pop    %ebx
  800c4e:	5e                   	pop    %esi
  800c4f:	5f                   	pop    %edi
  800c50:	5d                   	pop    %ebp
  800c51:	c3                   	ret    
  800c52:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c58:	39 f2                	cmp    %esi,%edx
  800c5a:	89 d0                	mov    %edx,%eax
  800c5c:	77 52                	ja     800cb0 <__umoddi3+0xa0>
  800c5e:	0f bd ea             	bsr    %edx,%ebp
  800c61:	83 f5 1f             	xor    $0x1f,%ebp
  800c64:	75 5a                	jne    800cc0 <__umoddi3+0xb0>
  800c66:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800c6a:	0f 82 e0 00 00 00    	jb     800d50 <__umoddi3+0x140>
  800c70:	39 0c 24             	cmp    %ecx,(%esp)
  800c73:	0f 86 d7 00 00 00    	jbe    800d50 <__umoddi3+0x140>
  800c79:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c7d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800c81:	83 c4 1c             	add    $0x1c,%esp
  800c84:	5b                   	pop    %ebx
  800c85:	5e                   	pop    %esi
  800c86:	5f                   	pop    %edi
  800c87:	5d                   	pop    %ebp
  800c88:	c3                   	ret    
  800c89:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c90:	85 ff                	test   %edi,%edi
  800c92:	89 fd                	mov    %edi,%ebp
  800c94:	75 0b                	jne    800ca1 <__umoddi3+0x91>
  800c96:	b8 01 00 00 00       	mov    $0x1,%eax
  800c9b:	31 d2                	xor    %edx,%edx
  800c9d:	f7 f7                	div    %edi
  800c9f:	89 c5                	mov    %eax,%ebp
  800ca1:	89 f0                	mov    %esi,%eax
  800ca3:	31 d2                	xor    %edx,%edx
  800ca5:	f7 f5                	div    %ebp
  800ca7:	89 c8                	mov    %ecx,%eax
  800ca9:	f7 f5                	div    %ebp
  800cab:	89 d0                	mov    %edx,%eax
  800cad:	eb 99                	jmp    800c48 <__umoddi3+0x38>
  800caf:	90                   	nop
  800cb0:	89 c8                	mov    %ecx,%eax
  800cb2:	89 f2                	mov    %esi,%edx
  800cb4:	83 c4 1c             	add    $0x1c,%esp
  800cb7:	5b                   	pop    %ebx
  800cb8:	5e                   	pop    %esi
  800cb9:	5f                   	pop    %edi
  800cba:	5d                   	pop    %ebp
  800cbb:	c3                   	ret    
  800cbc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800cc0:	8b 34 24             	mov    (%esp),%esi
  800cc3:	bf 20 00 00 00       	mov    $0x20,%edi
  800cc8:	89 e9                	mov    %ebp,%ecx
  800cca:	29 ef                	sub    %ebp,%edi
  800ccc:	d3 e0                	shl    %cl,%eax
  800cce:	89 f9                	mov    %edi,%ecx
  800cd0:	89 f2                	mov    %esi,%edx
  800cd2:	d3 ea                	shr    %cl,%edx
  800cd4:	89 e9                	mov    %ebp,%ecx
  800cd6:	09 c2                	or     %eax,%edx
  800cd8:	89 d8                	mov    %ebx,%eax
  800cda:	89 14 24             	mov    %edx,(%esp)
  800cdd:	89 f2                	mov    %esi,%edx
  800cdf:	d3 e2                	shl    %cl,%edx
  800ce1:	89 f9                	mov    %edi,%ecx
  800ce3:	89 54 24 04          	mov    %edx,0x4(%esp)
  800ce7:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800ceb:	d3 e8                	shr    %cl,%eax
  800ced:	89 e9                	mov    %ebp,%ecx
  800cef:	89 c6                	mov    %eax,%esi
  800cf1:	d3 e3                	shl    %cl,%ebx
  800cf3:	89 f9                	mov    %edi,%ecx
  800cf5:	89 d0                	mov    %edx,%eax
  800cf7:	d3 e8                	shr    %cl,%eax
  800cf9:	89 e9                	mov    %ebp,%ecx
  800cfb:	09 d8                	or     %ebx,%eax
  800cfd:	89 d3                	mov    %edx,%ebx
  800cff:	89 f2                	mov    %esi,%edx
  800d01:	f7 34 24             	divl   (%esp)
  800d04:	89 d6                	mov    %edx,%esi
  800d06:	d3 e3                	shl    %cl,%ebx
  800d08:	f7 64 24 04          	mull   0x4(%esp)
  800d0c:	39 d6                	cmp    %edx,%esi
  800d0e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d12:	89 d1                	mov    %edx,%ecx
  800d14:	89 c3                	mov    %eax,%ebx
  800d16:	72 08                	jb     800d20 <__umoddi3+0x110>
  800d18:	75 11                	jne    800d2b <__umoddi3+0x11b>
  800d1a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800d1e:	73 0b                	jae    800d2b <__umoddi3+0x11b>
  800d20:	2b 44 24 04          	sub    0x4(%esp),%eax
  800d24:	1b 14 24             	sbb    (%esp),%edx
  800d27:	89 d1                	mov    %edx,%ecx
  800d29:	89 c3                	mov    %eax,%ebx
  800d2b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800d2f:	29 da                	sub    %ebx,%edx
  800d31:	19 ce                	sbb    %ecx,%esi
  800d33:	89 f9                	mov    %edi,%ecx
  800d35:	89 f0                	mov    %esi,%eax
  800d37:	d3 e0                	shl    %cl,%eax
  800d39:	89 e9                	mov    %ebp,%ecx
  800d3b:	d3 ea                	shr    %cl,%edx
  800d3d:	89 e9                	mov    %ebp,%ecx
  800d3f:	d3 ee                	shr    %cl,%esi
  800d41:	09 d0                	or     %edx,%eax
  800d43:	89 f2                	mov    %esi,%edx
  800d45:	83 c4 1c             	add    $0x1c,%esp
  800d48:	5b                   	pop    %ebx
  800d49:	5e                   	pop    %esi
  800d4a:	5f                   	pop    %edi
  800d4b:	5d                   	pop    %ebp
  800d4c:	c3                   	ret    
  800d4d:	8d 76 00             	lea    0x0(%esi),%esi
  800d50:	29 f9                	sub    %edi,%ecx
  800d52:	19 d6                	sbb    %edx,%esi
  800d54:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d58:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d5c:	e9 18 ff ff ff       	jmp    800c79 <__umoddi3+0x69>

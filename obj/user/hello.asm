
obj/user/hello：     文件格式 elf32-i386


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
  80002c:	e8 2d 00 00 00       	call   80005e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 14             	sub    $0x14,%esp
	cprintf("hello, world\n");
  800039:	68 80 0d 80 00       	push   $0x800d80
  80003e:	e8 f6 00 00 00       	call   800139 <cprintf>
	cprintf("i am environment %08x\n", thisenv->env_id);
  800043:	a1 04 20 80 00       	mov    0x802004,%eax
  800048:	8b 40 48             	mov    0x48(%eax),%eax
  80004b:	83 c4 08             	add    $0x8,%esp
  80004e:	50                   	push   %eax
  80004f:	68 8e 0d 80 00       	push   $0x800d8e
  800054:	e8 e0 00 00 00       	call   800139 <cprintf>
}
  800059:	83 c4 10             	add    $0x10,%esp
  80005c:	c9                   	leave  
  80005d:	c3                   	ret    

0080005e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80005e:	55                   	push   %ebp
  80005f:	89 e5                	mov    %esp,%ebp
  800061:	83 ec 08             	sub    $0x8,%esp
  800064:	8b 45 08             	mov    0x8(%ebp),%eax
  800067:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80006a:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800071:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800074:	85 c0                	test   %eax,%eax
  800076:	7e 08                	jle    800080 <libmain+0x22>
		binaryname = argv[0];
  800078:	8b 0a                	mov    (%edx),%ecx
  80007a:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800080:	83 ec 08             	sub    $0x8,%esp
  800083:	52                   	push   %edx
  800084:	50                   	push   %eax
  800085:	e8 a9 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008a:	e8 05 00 00 00       	call   800094 <exit>
}
  80008f:	83 c4 10             	add    $0x10,%esp
  800092:	c9                   	leave  
  800093:	c3                   	ret    

00800094 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800094:	55                   	push   %ebp
  800095:	89 e5                	mov    %esp,%ebp
  800097:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80009a:	6a 00                	push   $0x0
  80009c:	e8 a1 09 00 00       	call   800a42 <sys_env_destroy>
}
  8000a1:	83 c4 10             	add    $0x10,%esp
  8000a4:	c9                   	leave  
  8000a5:	c3                   	ret    

008000a6 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000a6:	55                   	push   %ebp
  8000a7:	89 e5                	mov    %esp,%ebp
  8000a9:	53                   	push   %ebx
  8000aa:	83 ec 04             	sub    $0x4,%esp
  8000ad:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000b0:	8b 13                	mov    (%ebx),%edx
  8000b2:	8d 42 01             	lea    0x1(%edx),%eax
  8000b5:	89 03                	mov    %eax,(%ebx)
  8000b7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000ba:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000be:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000c3:	75 1a                	jne    8000df <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000c5:	83 ec 08             	sub    $0x8,%esp
  8000c8:	68 ff 00 00 00       	push   $0xff
  8000cd:	8d 43 08             	lea    0x8(%ebx),%eax
  8000d0:	50                   	push   %eax
  8000d1:	e8 2f 09 00 00       	call   800a05 <sys_cputs>
		b->idx = 0;
  8000d6:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000dc:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000df:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000e3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000e6:	c9                   	leave  
  8000e7:	c3                   	ret    

008000e8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000e8:	55                   	push   %ebp
  8000e9:	89 e5                	mov    %esp,%ebp
  8000eb:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000f1:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000f8:	00 00 00 
	b.cnt = 0;
  8000fb:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800102:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800105:	ff 75 0c             	pushl  0xc(%ebp)
  800108:	ff 75 08             	pushl  0x8(%ebp)
  80010b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800111:	50                   	push   %eax
  800112:	68 a6 00 80 00       	push   $0x8000a6
  800117:	e8 54 01 00 00       	call   800270 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80011c:	83 c4 08             	add    $0x8,%esp
  80011f:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800125:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80012b:	50                   	push   %eax
  80012c:	e8 d4 08 00 00       	call   800a05 <sys_cputs>

	return b.cnt;
}
  800131:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800137:	c9                   	leave  
  800138:	c3                   	ret    

00800139 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800139:	55                   	push   %ebp
  80013a:	89 e5                	mov    %esp,%ebp
  80013c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80013f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800142:	50                   	push   %eax
  800143:	ff 75 08             	pushl  0x8(%ebp)
  800146:	e8 9d ff ff ff       	call   8000e8 <vcprintf>
	va_end(ap);

	return cnt;
}
  80014b:	c9                   	leave  
  80014c:	c3                   	ret    

0080014d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80014d:	55                   	push   %ebp
  80014e:	89 e5                	mov    %esp,%ebp
  800150:	57                   	push   %edi
  800151:	56                   	push   %esi
  800152:	53                   	push   %ebx
  800153:	83 ec 1c             	sub    $0x1c,%esp
  800156:	89 c7                	mov    %eax,%edi
  800158:	89 d6                	mov    %edx,%esi
  80015a:	8b 45 08             	mov    0x8(%ebp),%eax
  80015d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800160:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800163:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800166:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800169:	bb 00 00 00 00       	mov    $0x0,%ebx
  80016e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800171:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800174:	39 d3                	cmp    %edx,%ebx
  800176:	72 05                	jb     80017d <printnum+0x30>
  800178:	39 45 10             	cmp    %eax,0x10(%ebp)
  80017b:	77 45                	ja     8001c2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80017d:	83 ec 0c             	sub    $0xc,%esp
  800180:	ff 75 18             	pushl  0x18(%ebp)
  800183:	8b 45 14             	mov    0x14(%ebp),%eax
  800186:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800189:	53                   	push   %ebx
  80018a:	ff 75 10             	pushl  0x10(%ebp)
  80018d:	83 ec 08             	sub    $0x8,%esp
  800190:	ff 75 e4             	pushl  -0x1c(%ebp)
  800193:	ff 75 e0             	pushl  -0x20(%ebp)
  800196:	ff 75 dc             	pushl  -0x24(%ebp)
  800199:	ff 75 d8             	pushl  -0x28(%ebp)
  80019c:	e8 4f 09 00 00       	call   800af0 <__udivdi3>
  8001a1:	83 c4 18             	add    $0x18,%esp
  8001a4:	52                   	push   %edx
  8001a5:	50                   	push   %eax
  8001a6:	89 f2                	mov    %esi,%edx
  8001a8:	89 f8                	mov    %edi,%eax
  8001aa:	e8 9e ff ff ff       	call   80014d <printnum>
  8001af:	83 c4 20             	add    $0x20,%esp
  8001b2:	eb 18                	jmp    8001cc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001b4:	83 ec 08             	sub    $0x8,%esp
  8001b7:	56                   	push   %esi
  8001b8:	ff 75 18             	pushl  0x18(%ebp)
  8001bb:	ff d7                	call   *%edi
  8001bd:	83 c4 10             	add    $0x10,%esp
  8001c0:	eb 03                	jmp    8001c5 <printnum+0x78>
  8001c2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001c5:	83 eb 01             	sub    $0x1,%ebx
  8001c8:	85 db                	test   %ebx,%ebx
  8001ca:	7f e8                	jg     8001b4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001cc:	83 ec 08             	sub    $0x8,%esp
  8001cf:	56                   	push   %esi
  8001d0:	83 ec 04             	sub    $0x4,%esp
  8001d3:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001d6:	ff 75 e0             	pushl  -0x20(%ebp)
  8001d9:	ff 75 dc             	pushl  -0x24(%ebp)
  8001dc:	ff 75 d8             	pushl  -0x28(%ebp)
  8001df:	e8 3c 0a 00 00       	call   800c20 <__umoddi3>
  8001e4:	83 c4 14             	add    $0x14,%esp
  8001e7:	0f be 80 af 0d 80 00 	movsbl 0x800daf(%eax),%eax
  8001ee:	50                   	push   %eax
  8001ef:	ff d7                	call   *%edi
}
  8001f1:	83 c4 10             	add    $0x10,%esp
  8001f4:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001f7:	5b                   	pop    %ebx
  8001f8:	5e                   	pop    %esi
  8001f9:	5f                   	pop    %edi
  8001fa:	5d                   	pop    %ebp
  8001fb:	c3                   	ret    

008001fc <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8001fc:	55                   	push   %ebp
  8001fd:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8001ff:	83 fa 01             	cmp    $0x1,%edx
  800202:	7e 0e                	jle    800212 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800204:	8b 10                	mov    (%eax),%edx
  800206:	8d 4a 08             	lea    0x8(%edx),%ecx
  800209:	89 08                	mov    %ecx,(%eax)
  80020b:	8b 02                	mov    (%edx),%eax
  80020d:	8b 52 04             	mov    0x4(%edx),%edx
  800210:	eb 22                	jmp    800234 <getuint+0x38>
	else if (lflag)
  800212:	85 d2                	test   %edx,%edx
  800214:	74 10                	je     800226 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800216:	8b 10                	mov    (%eax),%edx
  800218:	8d 4a 04             	lea    0x4(%edx),%ecx
  80021b:	89 08                	mov    %ecx,(%eax)
  80021d:	8b 02                	mov    (%edx),%eax
  80021f:	ba 00 00 00 00       	mov    $0x0,%edx
  800224:	eb 0e                	jmp    800234 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800226:	8b 10                	mov    (%eax),%edx
  800228:	8d 4a 04             	lea    0x4(%edx),%ecx
  80022b:	89 08                	mov    %ecx,(%eax)
  80022d:	8b 02                	mov    (%edx),%eax
  80022f:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800234:	5d                   	pop    %ebp
  800235:	c3                   	ret    

00800236 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800236:	55                   	push   %ebp
  800237:	89 e5                	mov    %esp,%ebp
  800239:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80023c:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800240:	8b 10                	mov    (%eax),%edx
  800242:	3b 50 04             	cmp    0x4(%eax),%edx
  800245:	73 0a                	jae    800251 <sprintputch+0x1b>
		*b->buf++ = ch;
  800247:	8d 4a 01             	lea    0x1(%edx),%ecx
  80024a:	89 08                	mov    %ecx,(%eax)
  80024c:	8b 45 08             	mov    0x8(%ebp),%eax
  80024f:	88 02                	mov    %al,(%edx)
}
  800251:	5d                   	pop    %ebp
  800252:	c3                   	ret    

00800253 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800253:	55                   	push   %ebp
  800254:	89 e5                	mov    %esp,%ebp
  800256:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800259:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80025c:	50                   	push   %eax
  80025d:	ff 75 10             	pushl  0x10(%ebp)
  800260:	ff 75 0c             	pushl  0xc(%ebp)
  800263:	ff 75 08             	pushl  0x8(%ebp)
  800266:	e8 05 00 00 00       	call   800270 <vprintfmt>
	va_end(ap);
}
  80026b:	83 c4 10             	add    $0x10,%esp
  80026e:	c9                   	leave  
  80026f:	c3                   	ret    

00800270 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800270:	55                   	push   %ebp
  800271:	89 e5                	mov    %esp,%ebp
  800273:	57                   	push   %edi
  800274:	56                   	push   %esi
  800275:	53                   	push   %ebx
  800276:	83 ec 2c             	sub    $0x2c,%esp
  800279:	8b 75 08             	mov    0x8(%ebp),%esi
  80027c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80027f:	8b 7d 10             	mov    0x10(%ebp),%edi
  800282:	eb 12                	jmp    800296 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800284:	85 c0                	test   %eax,%eax
  800286:	0f 84 89 03 00 00    	je     800615 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  80028c:	83 ec 08             	sub    $0x8,%esp
  80028f:	53                   	push   %ebx
  800290:	50                   	push   %eax
  800291:	ff d6                	call   *%esi
  800293:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800296:	83 c7 01             	add    $0x1,%edi
  800299:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80029d:	83 f8 25             	cmp    $0x25,%eax
  8002a0:	75 e2                	jne    800284 <vprintfmt+0x14>
  8002a2:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8002a6:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8002ad:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002b4:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8002bb:	ba 00 00 00 00       	mov    $0x0,%edx
  8002c0:	eb 07                	jmp    8002c9 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002c2:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8002c5:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002c9:	8d 47 01             	lea    0x1(%edi),%eax
  8002cc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002cf:	0f b6 07             	movzbl (%edi),%eax
  8002d2:	0f b6 c8             	movzbl %al,%ecx
  8002d5:	83 e8 23             	sub    $0x23,%eax
  8002d8:	3c 55                	cmp    $0x55,%al
  8002da:	0f 87 1a 03 00 00    	ja     8005fa <vprintfmt+0x38a>
  8002e0:	0f b6 c0             	movzbl %al,%eax
  8002e3:	ff 24 85 40 0e 80 00 	jmp    *0x800e40(,%eax,4)
  8002ea:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8002ed:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8002f1:	eb d6                	jmp    8002c9 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002f3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002f6:	b8 00 00 00 00       	mov    $0x0,%eax
  8002fb:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8002fe:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800301:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800305:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  800308:	8d 51 d0             	lea    -0x30(%ecx),%edx
  80030b:	83 fa 09             	cmp    $0x9,%edx
  80030e:	77 39                	ja     800349 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800310:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800313:	eb e9                	jmp    8002fe <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800315:	8b 45 14             	mov    0x14(%ebp),%eax
  800318:	8d 48 04             	lea    0x4(%eax),%ecx
  80031b:	89 4d 14             	mov    %ecx,0x14(%ebp)
  80031e:	8b 00                	mov    (%eax),%eax
  800320:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800323:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800326:	eb 27                	jmp    80034f <vprintfmt+0xdf>
  800328:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80032b:	85 c0                	test   %eax,%eax
  80032d:	b9 00 00 00 00       	mov    $0x0,%ecx
  800332:	0f 49 c8             	cmovns %eax,%ecx
  800335:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800338:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80033b:	eb 8c                	jmp    8002c9 <vprintfmt+0x59>
  80033d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800340:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800347:	eb 80                	jmp    8002c9 <vprintfmt+0x59>
  800349:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80034c:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80034f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800353:	0f 89 70 ff ff ff    	jns    8002c9 <vprintfmt+0x59>
				width = precision, precision = -1;
  800359:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80035c:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80035f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800366:	e9 5e ff ff ff       	jmp    8002c9 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80036b:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80036e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800371:	e9 53 ff ff ff       	jmp    8002c9 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800376:	8b 45 14             	mov    0x14(%ebp),%eax
  800379:	8d 50 04             	lea    0x4(%eax),%edx
  80037c:	89 55 14             	mov    %edx,0x14(%ebp)
  80037f:	83 ec 08             	sub    $0x8,%esp
  800382:	53                   	push   %ebx
  800383:	ff 30                	pushl  (%eax)
  800385:	ff d6                	call   *%esi
			break;
  800387:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80038a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80038d:	e9 04 ff ff ff       	jmp    800296 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800392:	8b 45 14             	mov    0x14(%ebp),%eax
  800395:	8d 50 04             	lea    0x4(%eax),%edx
  800398:	89 55 14             	mov    %edx,0x14(%ebp)
  80039b:	8b 00                	mov    (%eax),%eax
  80039d:	99                   	cltd   
  80039e:	31 d0                	xor    %edx,%eax
  8003a0:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003a2:	83 f8 07             	cmp    $0x7,%eax
  8003a5:	7f 0b                	jg     8003b2 <vprintfmt+0x142>
  8003a7:	8b 14 85 a0 0f 80 00 	mov    0x800fa0(,%eax,4),%edx
  8003ae:	85 d2                	test   %edx,%edx
  8003b0:	75 18                	jne    8003ca <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8003b2:	50                   	push   %eax
  8003b3:	68 c7 0d 80 00       	push   $0x800dc7
  8003b8:	53                   	push   %ebx
  8003b9:	56                   	push   %esi
  8003ba:	e8 94 fe ff ff       	call   800253 <printfmt>
  8003bf:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003c5:	e9 cc fe ff ff       	jmp    800296 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003ca:	52                   	push   %edx
  8003cb:	68 d0 0d 80 00       	push   $0x800dd0
  8003d0:	53                   	push   %ebx
  8003d1:	56                   	push   %esi
  8003d2:	e8 7c fe ff ff       	call   800253 <printfmt>
  8003d7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003da:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003dd:	e9 b4 fe ff ff       	jmp    800296 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003e2:	8b 45 14             	mov    0x14(%ebp),%eax
  8003e5:	8d 50 04             	lea    0x4(%eax),%edx
  8003e8:	89 55 14             	mov    %edx,0x14(%ebp)
  8003eb:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8003ed:	85 ff                	test   %edi,%edi
  8003ef:	b8 c0 0d 80 00       	mov    $0x800dc0,%eax
  8003f4:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8003f7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003fb:	0f 8e 94 00 00 00    	jle    800495 <vprintfmt+0x225>
  800401:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800405:	0f 84 98 00 00 00    	je     8004a3 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  80040b:	83 ec 08             	sub    $0x8,%esp
  80040e:	ff 75 d0             	pushl  -0x30(%ebp)
  800411:	57                   	push   %edi
  800412:	e8 86 02 00 00       	call   80069d <strnlen>
  800417:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80041a:	29 c1                	sub    %eax,%ecx
  80041c:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  80041f:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800422:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800426:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800429:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80042c:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80042e:	eb 0f                	jmp    80043f <vprintfmt+0x1cf>
					putch(padc, putdat);
  800430:	83 ec 08             	sub    $0x8,%esp
  800433:	53                   	push   %ebx
  800434:	ff 75 e0             	pushl  -0x20(%ebp)
  800437:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800439:	83 ef 01             	sub    $0x1,%edi
  80043c:	83 c4 10             	add    $0x10,%esp
  80043f:	85 ff                	test   %edi,%edi
  800441:	7f ed                	jg     800430 <vprintfmt+0x1c0>
  800443:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800446:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  800449:	85 c9                	test   %ecx,%ecx
  80044b:	b8 00 00 00 00       	mov    $0x0,%eax
  800450:	0f 49 c1             	cmovns %ecx,%eax
  800453:	29 c1                	sub    %eax,%ecx
  800455:	89 75 08             	mov    %esi,0x8(%ebp)
  800458:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80045b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80045e:	89 cb                	mov    %ecx,%ebx
  800460:	eb 4d                	jmp    8004af <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800462:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800466:	74 1b                	je     800483 <vprintfmt+0x213>
  800468:	0f be c0             	movsbl %al,%eax
  80046b:	83 e8 20             	sub    $0x20,%eax
  80046e:	83 f8 5e             	cmp    $0x5e,%eax
  800471:	76 10                	jbe    800483 <vprintfmt+0x213>
					putch('?', putdat);
  800473:	83 ec 08             	sub    $0x8,%esp
  800476:	ff 75 0c             	pushl  0xc(%ebp)
  800479:	6a 3f                	push   $0x3f
  80047b:	ff 55 08             	call   *0x8(%ebp)
  80047e:	83 c4 10             	add    $0x10,%esp
  800481:	eb 0d                	jmp    800490 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800483:	83 ec 08             	sub    $0x8,%esp
  800486:	ff 75 0c             	pushl  0xc(%ebp)
  800489:	52                   	push   %edx
  80048a:	ff 55 08             	call   *0x8(%ebp)
  80048d:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800490:	83 eb 01             	sub    $0x1,%ebx
  800493:	eb 1a                	jmp    8004af <vprintfmt+0x23f>
  800495:	89 75 08             	mov    %esi,0x8(%ebp)
  800498:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80049b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80049e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004a1:	eb 0c                	jmp    8004af <vprintfmt+0x23f>
  8004a3:	89 75 08             	mov    %esi,0x8(%ebp)
  8004a6:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004a9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004ac:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004af:	83 c7 01             	add    $0x1,%edi
  8004b2:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004b6:	0f be d0             	movsbl %al,%edx
  8004b9:	85 d2                	test   %edx,%edx
  8004bb:	74 23                	je     8004e0 <vprintfmt+0x270>
  8004bd:	85 f6                	test   %esi,%esi
  8004bf:	78 a1                	js     800462 <vprintfmt+0x1f2>
  8004c1:	83 ee 01             	sub    $0x1,%esi
  8004c4:	79 9c                	jns    800462 <vprintfmt+0x1f2>
  8004c6:	89 df                	mov    %ebx,%edi
  8004c8:	8b 75 08             	mov    0x8(%ebp),%esi
  8004cb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004ce:	eb 18                	jmp    8004e8 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004d0:	83 ec 08             	sub    $0x8,%esp
  8004d3:	53                   	push   %ebx
  8004d4:	6a 20                	push   $0x20
  8004d6:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004d8:	83 ef 01             	sub    $0x1,%edi
  8004db:	83 c4 10             	add    $0x10,%esp
  8004de:	eb 08                	jmp    8004e8 <vprintfmt+0x278>
  8004e0:	89 df                	mov    %ebx,%edi
  8004e2:	8b 75 08             	mov    0x8(%ebp),%esi
  8004e5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004e8:	85 ff                	test   %edi,%edi
  8004ea:	7f e4                	jg     8004d0 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ec:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004ef:	e9 a2 fd ff ff       	jmp    800296 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8004f4:	83 fa 01             	cmp    $0x1,%edx
  8004f7:	7e 16                	jle    80050f <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  8004f9:	8b 45 14             	mov    0x14(%ebp),%eax
  8004fc:	8d 50 08             	lea    0x8(%eax),%edx
  8004ff:	89 55 14             	mov    %edx,0x14(%ebp)
  800502:	8b 50 04             	mov    0x4(%eax),%edx
  800505:	8b 00                	mov    (%eax),%eax
  800507:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80050a:	89 55 dc             	mov    %edx,-0x24(%ebp)
  80050d:	eb 32                	jmp    800541 <vprintfmt+0x2d1>
	else if (lflag)
  80050f:	85 d2                	test   %edx,%edx
  800511:	74 18                	je     80052b <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  800513:	8b 45 14             	mov    0x14(%ebp),%eax
  800516:	8d 50 04             	lea    0x4(%eax),%edx
  800519:	89 55 14             	mov    %edx,0x14(%ebp)
  80051c:	8b 00                	mov    (%eax),%eax
  80051e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800521:	89 c1                	mov    %eax,%ecx
  800523:	c1 f9 1f             	sar    $0x1f,%ecx
  800526:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800529:	eb 16                	jmp    800541 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  80052b:	8b 45 14             	mov    0x14(%ebp),%eax
  80052e:	8d 50 04             	lea    0x4(%eax),%edx
  800531:	89 55 14             	mov    %edx,0x14(%ebp)
  800534:	8b 00                	mov    (%eax),%eax
  800536:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800539:	89 c1                	mov    %eax,%ecx
  80053b:	c1 f9 1f             	sar    $0x1f,%ecx
  80053e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800541:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800544:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800547:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80054c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800550:	79 74                	jns    8005c6 <vprintfmt+0x356>
				putch('-', putdat);
  800552:	83 ec 08             	sub    $0x8,%esp
  800555:	53                   	push   %ebx
  800556:	6a 2d                	push   $0x2d
  800558:	ff d6                	call   *%esi
				num = -(long long) num;
  80055a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80055d:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800560:	f7 d8                	neg    %eax
  800562:	83 d2 00             	adc    $0x0,%edx
  800565:	f7 da                	neg    %edx
  800567:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80056a:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80056f:	eb 55                	jmp    8005c6 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800571:	8d 45 14             	lea    0x14(%ebp),%eax
  800574:	e8 83 fc ff ff       	call   8001fc <getuint>
			base = 10;
  800579:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80057e:	eb 46                	jmp    8005c6 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800580:	8d 45 14             	lea    0x14(%ebp),%eax
  800583:	e8 74 fc ff ff       	call   8001fc <getuint>
			base = 8;
  800588:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80058d:	eb 37                	jmp    8005c6 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  80058f:	83 ec 08             	sub    $0x8,%esp
  800592:	53                   	push   %ebx
  800593:	6a 30                	push   $0x30
  800595:	ff d6                	call   *%esi
			putch('x', putdat);
  800597:	83 c4 08             	add    $0x8,%esp
  80059a:	53                   	push   %ebx
  80059b:	6a 78                	push   $0x78
  80059d:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80059f:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a2:	8d 50 04             	lea    0x4(%eax),%edx
  8005a5:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8005a8:	8b 00                	mov    (%eax),%eax
  8005aa:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8005af:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8005b2:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8005b7:	eb 0d                	jmp    8005c6 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8005b9:	8d 45 14             	lea    0x14(%ebp),%eax
  8005bc:	e8 3b fc ff ff       	call   8001fc <getuint>
			base = 16;
  8005c1:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8005c6:	83 ec 0c             	sub    $0xc,%esp
  8005c9:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8005cd:	57                   	push   %edi
  8005ce:	ff 75 e0             	pushl  -0x20(%ebp)
  8005d1:	51                   	push   %ecx
  8005d2:	52                   	push   %edx
  8005d3:	50                   	push   %eax
  8005d4:	89 da                	mov    %ebx,%edx
  8005d6:	89 f0                	mov    %esi,%eax
  8005d8:	e8 70 fb ff ff       	call   80014d <printnum>
			break;
  8005dd:	83 c4 20             	add    $0x20,%esp
  8005e0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005e3:	e9 ae fc ff ff       	jmp    800296 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8005e8:	83 ec 08             	sub    $0x8,%esp
  8005eb:	53                   	push   %ebx
  8005ec:	51                   	push   %ecx
  8005ed:	ff d6                	call   *%esi
			break;
  8005ef:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005f2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8005f5:	e9 9c fc ff ff       	jmp    800296 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8005fa:	83 ec 08             	sub    $0x8,%esp
  8005fd:	53                   	push   %ebx
  8005fe:	6a 25                	push   $0x25
  800600:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800602:	83 c4 10             	add    $0x10,%esp
  800605:	eb 03                	jmp    80060a <vprintfmt+0x39a>
  800607:	83 ef 01             	sub    $0x1,%edi
  80060a:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  80060e:	75 f7                	jne    800607 <vprintfmt+0x397>
  800610:	e9 81 fc ff ff       	jmp    800296 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800615:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800618:	5b                   	pop    %ebx
  800619:	5e                   	pop    %esi
  80061a:	5f                   	pop    %edi
  80061b:	5d                   	pop    %ebp
  80061c:	c3                   	ret    

0080061d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80061d:	55                   	push   %ebp
  80061e:	89 e5                	mov    %esp,%ebp
  800620:	83 ec 18             	sub    $0x18,%esp
  800623:	8b 45 08             	mov    0x8(%ebp),%eax
  800626:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800629:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80062c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800630:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800633:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80063a:	85 c0                	test   %eax,%eax
  80063c:	74 26                	je     800664 <vsnprintf+0x47>
  80063e:	85 d2                	test   %edx,%edx
  800640:	7e 22                	jle    800664 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800642:	ff 75 14             	pushl  0x14(%ebp)
  800645:	ff 75 10             	pushl  0x10(%ebp)
  800648:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80064b:	50                   	push   %eax
  80064c:	68 36 02 80 00       	push   $0x800236
  800651:	e8 1a fc ff ff       	call   800270 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800656:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800659:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80065c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80065f:	83 c4 10             	add    $0x10,%esp
  800662:	eb 05                	jmp    800669 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800664:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800669:	c9                   	leave  
  80066a:	c3                   	ret    

0080066b <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80066b:	55                   	push   %ebp
  80066c:	89 e5                	mov    %esp,%ebp
  80066e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800671:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800674:	50                   	push   %eax
  800675:	ff 75 10             	pushl  0x10(%ebp)
  800678:	ff 75 0c             	pushl  0xc(%ebp)
  80067b:	ff 75 08             	pushl  0x8(%ebp)
  80067e:	e8 9a ff ff ff       	call   80061d <vsnprintf>
	va_end(ap);

	return rc;
}
  800683:	c9                   	leave  
  800684:	c3                   	ret    

00800685 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800685:	55                   	push   %ebp
  800686:	89 e5                	mov    %esp,%ebp
  800688:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80068b:	b8 00 00 00 00       	mov    $0x0,%eax
  800690:	eb 03                	jmp    800695 <strlen+0x10>
		n++;
  800692:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800695:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800699:	75 f7                	jne    800692 <strlen+0xd>
		n++;
	return n;
}
  80069b:	5d                   	pop    %ebp
  80069c:	c3                   	ret    

0080069d <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80069d:	55                   	push   %ebp
  80069e:	89 e5                	mov    %esp,%ebp
  8006a0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8006a3:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006a6:	ba 00 00 00 00       	mov    $0x0,%edx
  8006ab:	eb 03                	jmp    8006b0 <strnlen+0x13>
		n++;
  8006ad:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006b0:	39 c2                	cmp    %eax,%edx
  8006b2:	74 08                	je     8006bc <strnlen+0x1f>
  8006b4:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8006b8:	75 f3                	jne    8006ad <strnlen+0x10>
  8006ba:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8006bc:	5d                   	pop    %ebp
  8006bd:	c3                   	ret    

008006be <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8006be:	55                   	push   %ebp
  8006bf:	89 e5                	mov    %esp,%ebp
  8006c1:	53                   	push   %ebx
  8006c2:	8b 45 08             	mov    0x8(%ebp),%eax
  8006c5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8006c8:	89 c2                	mov    %eax,%edx
  8006ca:	83 c2 01             	add    $0x1,%edx
  8006cd:	83 c1 01             	add    $0x1,%ecx
  8006d0:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8006d4:	88 5a ff             	mov    %bl,-0x1(%edx)
  8006d7:	84 db                	test   %bl,%bl
  8006d9:	75 ef                	jne    8006ca <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8006db:	5b                   	pop    %ebx
  8006dc:	5d                   	pop    %ebp
  8006dd:	c3                   	ret    

008006de <strcat>:

char *
strcat(char *dst, const char *src)
{
  8006de:	55                   	push   %ebp
  8006df:	89 e5                	mov    %esp,%ebp
  8006e1:	53                   	push   %ebx
  8006e2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8006e5:	53                   	push   %ebx
  8006e6:	e8 9a ff ff ff       	call   800685 <strlen>
  8006eb:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8006ee:	ff 75 0c             	pushl  0xc(%ebp)
  8006f1:	01 d8                	add    %ebx,%eax
  8006f3:	50                   	push   %eax
  8006f4:	e8 c5 ff ff ff       	call   8006be <strcpy>
	return dst;
}
  8006f9:	89 d8                	mov    %ebx,%eax
  8006fb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8006fe:	c9                   	leave  
  8006ff:	c3                   	ret    

00800700 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800700:	55                   	push   %ebp
  800701:	89 e5                	mov    %esp,%ebp
  800703:	56                   	push   %esi
  800704:	53                   	push   %ebx
  800705:	8b 75 08             	mov    0x8(%ebp),%esi
  800708:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80070b:	89 f3                	mov    %esi,%ebx
  80070d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800710:	89 f2                	mov    %esi,%edx
  800712:	eb 0f                	jmp    800723 <strncpy+0x23>
		*dst++ = *src;
  800714:	83 c2 01             	add    $0x1,%edx
  800717:	0f b6 01             	movzbl (%ecx),%eax
  80071a:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80071d:	80 39 01             	cmpb   $0x1,(%ecx)
  800720:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800723:	39 da                	cmp    %ebx,%edx
  800725:	75 ed                	jne    800714 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800727:	89 f0                	mov    %esi,%eax
  800729:	5b                   	pop    %ebx
  80072a:	5e                   	pop    %esi
  80072b:	5d                   	pop    %ebp
  80072c:	c3                   	ret    

0080072d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80072d:	55                   	push   %ebp
  80072e:	89 e5                	mov    %esp,%ebp
  800730:	56                   	push   %esi
  800731:	53                   	push   %ebx
  800732:	8b 75 08             	mov    0x8(%ebp),%esi
  800735:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800738:	8b 55 10             	mov    0x10(%ebp),%edx
  80073b:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80073d:	85 d2                	test   %edx,%edx
  80073f:	74 21                	je     800762 <strlcpy+0x35>
  800741:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800745:	89 f2                	mov    %esi,%edx
  800747:	eb 09                	jmp    800752 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800749:	83 c2 01             	add    $0x1,%edx
  80074c:	83 c1 01             	add    $0x1,%ecx
  80074f:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800752:	39 c2                	cmp    %eax,%edx
  800754:	74 09                	je     80075f <strlcpy+0x32>
  800756:	0f b6 19             	movzbl (%ecx),%ebx
  800759:	84 db                	test   %bl,%bl
  80075b:	75 ec                	jne    800749 <strlcpy+0x1c>
  80075d:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80075f:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800762:	29 f0                	sub    %esi,%eax
}
  800764:	5b                   	pop    %ebx
  800765:	5e                   	pop    %esi
  800766:	5d                   	pop    %ebp
  800767:	c3                   	ret    

00800768 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800768:	55                   	push   %ebp
  800769:	89 e5                	mov    %esp,%ebp
  80076b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80076e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800771:	eb 06                	jmp    800779 <strcmp+0x11>
		p++, q++;
  800773:	83 c1 01             	add    $0x1,%ecx
  800776:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800779:	0f b6 01             	movzbl (%ecx),%eax
  80077c:	84 c0                	test   %al,%al
  80077e:	74 04                	je     800784 <strcmp+0x1c>
  800780:	3a 02                	cmp    (%edx),%al
  800782:	74 ef                	je     800773 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800784:	0f b6 c0             	movzbl %al,%eax
  800787:	0f b6 12             	movzbl (%edx),%edx
  80078a:	29 d0                	sub    %edx,%eax
}
  80078c:	5d                   	pop    %ebp
  80078d:	c3                   	ret    

0080078e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80078e:	55                   	push   %ebp
  80078f:	89 e5                	mov    %esp,%ebp
  800791:	53                   	push   %ebx
  800792:	8b 45 08             	mov    0x8(%ebp),%eax
  800795:	8b 55 0c             	mov    0xc(%ebp),%edx
  800798:	89 c3                	mov    %eax,%ebx
  80079a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80079d:	eb 06                	jmp    8007a5 <strncmp+0x17>
		n--, p++, q++;
  80079f:	83 c0 01             	add    $0x1,%eax
  8007a2:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8007a5:	39 d8                	cmp    %ebx,%eax
  8007a7:	74 15                	je     8007be <strncmp+0x30>
  8007a9:	0f b6 08             	movzbl (%eax),%ecx
  8007ac:	84 c9                	test   %cl,%cl
  8007ae:	74 04                	je     8007b4 <strncmp+0x26>
  8007b0:	3a 0a                	cmp    (%edx),%cl
  8007b2:	74 eb                	je     80079f <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8007b4:	0f b6 00             	movzbl (%eax),%eax
  8007b7:	0f b6 12             	movzbl (%edx),%edx
  8007ba:	29 d0                	sub    %edx,%eax
  8007bc:	eb 05                	jmp    8007c3 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8007be:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8007c3:	5b                   	pop    %ebx
  8007c4:	5d                   	pop    %ebp
  8007c5:	c3                   	ret    

008007c6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8007c6:	55                   	push   %ebp
  8007c7:	89 e5                	mov    %esp,%ebp
  8007c9:	8b 45 08             	mov    0x8(%ebp),%eax
  8007cc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007d0:	eb 07                	jmp    8007d9 <strchr+0x13>
		if (*s == c)
  8007d2:	38 ca                	cmp    %cl,%dl
  8007d4:	74 0f                	je     8007e5 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8007d6:	83 c0 01             	add    $0x1,%eax
  8007d9:	0f b6 10             	movzbl (%eax),%edx
  8007dc:	84 d2                	test   %dl,%dl
  8007de:	75 f2                	jne    8007d2 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8007e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8007e5:	5d                   	pop    %ebp
  8007e6:	c3                   	ret    

008007e7 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8007e7:	55                   	push   %ebp
  8007e8:	89 e5                	mov    %esp,%ebp
  8007ea:	8b 45 08             	mov    0x8(%ebp),%eax
  8007ed:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007f1:	eb 03                	jmp    8007f6 <strfind+0xf>
  8007f3:	83 c0 01             	add    $0x1,%eax
  8007f6:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8007f9:	38 ca                	cmp    %cl,%dl
  8007fb:	74 04                	je     800801 <strfind+0x1a>
  8007fd:	84 d2                	test   %dl,%dl
  8007ff:	75 f2                	jne    8007f3 <strfind+0xc>
			break;
	return (char *) s;
}
  800801:	5d                   	pop    %ebp
  800802:	c3                   	ret    

00800803 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800803:	55                   	push   %ebp
  800804:	89 e5                	mov    %esp,%ebp
  800806:	57                   	push   %edi
  800807:	56                   	push   %esi
  800808:	53                   	push   %ebx
  800809:	8b 7d 08             	mov    0x8(%ebp),%edi
  80080c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  80080f:	85 c9                	test   %ecx,%ecx
  800811:	74 36                	je     800849 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800813:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800819:	75 28                	jne    800843 <memset+0x40>
  80081b:	f6 c1 03             	test   $0x3,%cl
  80081e:	75 23                	jne    800843 <memset+0x40>
		c &= 0xFF;
  800820:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800824:	89 d3                	mov    %edx,%ebx
  800826:	c1 e3 08             	shl    $0x8,%ebx
  800829:	89 d6                	mov    %edx,%esi
  80082b:	c1 e6 18             	shl    $0x18,%esi
  80082e:	89 d0                	mov    %edx,%eax
  800830:	c1 e0 10             	shl    $0x10,%eax
  800833:	09 f0                	or     %esi,%eax
  800835:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800837:	89 d8                	mov    %ebx,%eax
  800839:	09 d0                	or     %edx,%eax
  80083b:	c1 e9 02             	shr    $0x2,%ecx
  80083e:	fc                   	cld    
  80083f:	f3 ab                	rep stos %eax,%es:(%edi)
  800841:	eb 06                	jmp    800849 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800843:	8b 45 0c             	mov    0xc(%ebp),%eax
  800846:	fc                   	cld    
  800847:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800849:	89 f8                	mov    %edi,%eax
  80084b:	5b                   	pop    %ebx
  80084c:	5e                   	pop    %esi
  80084d:	5f                   	pop    %edi
  80084e:	5d                   	pop    %ebp
  80084f:	c3                   	ret    

00800850 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800850:	55                   	push   %ebp
  800851:	89 e5                	mov    %esp,%ebp
  800853:	57                   	push   %edi
  800854:	56                   	push   %esi
  800855:	8b 45 08             	mov    0x8(%ebp),%eax
  800858:	8b 75 0c             	mov    0xc(%ebp),%esi
  80085b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80085e:	39 c6                	cmp    %eax,%esi
  800860:	73 35                	jae    800897 <memmove+0x47>
  800862:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800865:	39 d0                	cmp    %edx,%eax
  800867:	73 2e                	jae    800897 <memmove+0x47>
		s += n;
		d += n;
  800869:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80086c:	89 d6                	mov    %edx,%esi
  80086e:	09 fe                	or     %edi,%esi
  800870:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800876:	75 13                	jne    80088b <memmove+0x3b>
  800878:	f6 c1 03             	test   $0x3,%cl
  80087b:	75 0e                	jne    80088b <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80087d:	83 ef 04             	sub    $0x4,%edi
  800880:	8d 72 fc             	lea    -0x4(%edx),%esi
  800883:	c1 e9 02             	shr    $0x2,%ecx
  800886:	fd                   	std    
  800887:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800889:	eb 09                	jmp    800894 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80088b:	83 ef 01             	sub    $0x1,%edi
  80088e:	8d 72 ff             	lea    -0x1(%edx),%esi
  800891:	fd                   	std    
  800892:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800894:	fc                   	cld    
  800895:	eb 1d                	jmp    8008b4 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800897:	89 f2                	mov    %esi,%edx
  800899:	09 c2                	or     %eax,%edx
  80089b:	f6 c2 03             	test   $0x3,%dl
  80089e:	75 0f                	jne    8008af <memmove+0x5f>
  8008a0:	f6 c1 03             	test   $0x3,%cl
  8008a3:	75 0a                	jne    8008af <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8008a5:	c1 e9 02             	shr    $0x2,%ecx
  8008a8:	89 c7                	mov    %eax,%edi
  8008aa:	fc                   	cld    
  8008ab:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8008ad:	eb 05                	jmp    8008b4 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8008af:	89 c7                	mov    %eax,%edi
  8008b1:	fc                   	cld    
  8008b2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8008b4:	5e                   	pop    %esi
  8008b5:	5f                   	pop    %edi
  8008b6:	5d                   	pop    %ebp
  8008b7:	c3                   	ret    

008008b8 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8008b8:	55                   	push   %ebp
  8008b9:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8008bb:	ff 75 10             	pushl  0x10(%ebp)
  8008be:	ff 75 0c             	pushl  0xc(%ebp)
  8008c1:	ff 75 08             	pushl  0x8(%ebp)
  8008c4:	e8 87 ff ff ff       	call   800850 <memmove>
}
  8008c9:	c9                   	leave  
  8008ca:	c3                   	ret    

008008cb <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8008cb:	55                   	push   %ebp
  8008cc:	89 e5                	mov    %esp,%ebp
  8008ce:	56                   	push   %esi
  8008cf:	53                   	push   %ebx
  8008d0:	8b 45 08             	mov    0x8(%ebp),%eax
  8008d3:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008d6:	89 c6                	mov    %eax,%esi
  8008d8:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008db:	eb 1a                	jmp    8008f7 <memcmp+0x2c>
		if (*s1 != *s2)
  8008dd:	0f b6 08             	movzbl (%eax),%ecx
  8008e0:	0f b6 1a             	movzbl (%edx),%ebx
  8008e3:	38 d9                	cmp    %bl,%cl
  8008e5:	74 0a                	je     8008f1 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8008e7:	0f b6 c1             	movzbl %cl,%eax
  8008ea:	0f b6 db             	movzbl %bl,%ebx
  8008ed:	29 d8                	sub    %ebx,%eax
  8008ef:	eb 0f                	jmp    800900 <memcmp+0x35>
		s1++, s2++;
  8008f1:	83 c0 01             	add    $0x1,%eax
  8008f4:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008f7:	39 f0                	cmp    %esi,%eax
  8008f9:	75 e2                	jne    8008dd <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8008fb:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800900:	5b                   	pop    %ebx
  800901:	5e                   	pop    %esi
  800902:	5d                   	pop    %ebp
  800903:	c3                   	ret    

00800904 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800904:	55                   	push   %ebp
  800905:	89 e5                	mov    %esp,%ebp
  800907:	53                   	push   %ebx
  800908:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  80090b:	89 c1                	mov    %eax,%ecx
  80090d:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800910:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800914:	eb 0a                	jmp    800920 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800916:	0f b6 10             	movzbl (%eax),%edx
  800919:	39 da                	cmp    %ebx,%edx
  80091b:	74 07                	je     800924 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  80091d:	83 c0 01             	add    $0x1,%eax
  800920:	39 c8                	cmp    %ecx,%eax
  800922:	72 f2                	jb     800916 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800924:	5b                   	pop    %ebx
  800925:	5d                   	pop    %ebp
  800926:	c3                   	ret    

00800927 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800927:	55                   	push   %ebp
  800928:	89 e5                	mov    %esp,%ebp
  80092a:	57                   	push   %edi
  80092b:	56                   	push   %esi
  80092c:	53                   	push   %ebx
  80092d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800930:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800933:	eb 03                	jmp    800938 <strtol+0x11>
		s++;
  800935:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800938:	0f b6 01             	movzbl (%ecx),%eax
  80093b:	3c 20                	cmp    $0x20,%al
  80093d:	74 f6                	je     800935 <strtol+0xe>
  80093f:	3c 09                	cmp    $0x9,%al
  800941:	74 f2                	je     800935 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800943:	3c 2b                	cmp    $0x2b,%al
  800945:	75 0a                	jne    800951 <strtol+0x2a>
		s++;
  800947:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  80094a:	bf 00 00 00 00       	mov    $0x0,%edi
  80094f:	eb 11                	jmp    800962 <strtol+0x3b>
  800951:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800956:	3c 2d                	cmp    $0x2d,%al
  800958:	75 08                	jne    800962 <strtol+0x3b>
		s++, neg = 1;
  80095a:	83 c1 01             	add    $0x1,%ecx
  80095d:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800962:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800968:	75 15                	jne    80097f <strtol+0x58>
  80096a:	80 39 30             	cmpb   $0x30,(%ecx)
  80096d:	75 10                	jne    80097f <strtol+0x58>
  80096f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800973:	75 7c                	jne    8009f1 <strtol+0xca>
		s += 2, base = 16;
  800975:	83 c1 02             	add    $0x2,%ecx
  800978:	bb 10 00 00 00       	mov    $0x10,%ebx
  80097d:	eb 16                	jmp    800995 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  80097f:	85 db                	test   %ebx,%ebx
  800981:	75 12                	jne    800995 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800983:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800988:	80 39 30             	cmpb   $0x30,(%ecx)
  80098b:	75 08                	jne    800995 <strtol+0x6e>
		s++, base = 8;
  80098d:	83 c1 01             	add    $0x1,%ecx
  800990:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800995:	b8 00 00 00 00       	mov    $0x0,%eax
  80099a:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  80099d:	0f b6 11             	movzbl (%ecx),%edx
  8009a0:	8d 72 d0             	lea    -0x30(%edx),%esi
  8009a3:	89 f3                	mov    %esi,%ebx
  8009a5:	80 fb 09             	cmp    $0x9,%bl
  8009a8:	77 08                	ja     8009b2 <strtol+0x8b>
			dig = *s - '0';
  8009aa:	0f be d2             	movsbl %dl,%edx
  8009ad:	83 ea 30             	sub    $0x30,%edx
  8009b0:	eb 22                	jmp    8009d4 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  8009b2:	8d 72 9f             	lea    -0x61(%edx),%esi
  8009b5:	89 f3                	mov    %esi,%ebx
  8009b7:	80 fb 19             	cmp    $0x19,%bl
  8009ba:	77 08                	ja     8009c4 <strtol+0x9d>
			dig = *s - 'a' + 10;
  8009bc:	0f be d2             	movsbl %dl,%edx
  8009bf:	83 ea 57             	sub    $0x57,%edx
  8009c2:	eb 10                	jmp    8009d4 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  8009c4:	8d 72 bf             	lea    -0x41(%edx),%esi
  8009c7:	89 f3                	mov    %esi,%ebx
  8009c9:	80 fb 19             	cmp    $0x19,%bl
  8009cc:	77 16                	ja     8009e4 <strtol+0xbd>
			dig = *s - 'A' + 10;
  8009ce:	0f be d2             	movsbl %dl,%edx
  8009d1:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  8009d4:	3b 55 10             	cmp    0x10(%ebp),%edx
  8009d7:	7d 0b                	jge    8009e4 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  8009d9:	83 c1 01             	add    $0x1,%ecx
  8009dc:	0f af 45 10          	imul   0x10(%ebp),%eax
  8009e0:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  8009e2:	eb b9                	jmp    80099d <strtol+0x76>

	if (endptr)
  8009e4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8009e8:	74 0d                	je     8009f7 <strtol+0xd0>
		*endptr = (char *) s;
  8009ea:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009ed:	89 0e                	mov    %ecx,(%esi)
  8009ef:	eb 06                	jmp    8009f7 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  8009f1:	85 db                	test   %ebx,%ebx
  8009f3:	74 98                	je     80098d <strtol+0x66>
  8009f5:	eb 9e                	jmp    800995 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  8009f7:	89 c2                	mov    %eax,%edx
  8009f9:	f7 da                	neg    %edx
  8009fb:	85 ff                	test   %edi,%edi
  8009fd:	0f 45 c2             	cmovne %edx,%eax
}
  800a00:	5b                   	pop    %ebx
  800a01:	5e                   	pop    %esi
  800a02:	5f                   	pop    %edi
  800a03:	5d                   	pop    %ebp
  800a04:	c3                   	ret    

00800a05 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800a05:	55                   	push   %ebp
  800a06:	89 e5                	mov    %esp,%ebp
  800a08:	57                   	push   %edi
  800a09:	56                   	push   %esi
  800a0a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a0b:	b8 00 00 00 00       	mov    $0x0,%eax
  800a10:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a13:	8b 55 08             	mov    0x8(%ebp),%edx
  800a16:	89 c3                	mov    %eax,%ebx
  800a18:	89 c7                	mov    %eax,%edi
  800a1a:	89 c6                	mov    %eax,%esi
  800a1c:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800a1e:	5b                   	pop    %ebx
  800a1f:	5e                   	pop    %esi
  800a20:	5f                   	pop    %edi
  800a21:	5d                   	pop    %ebp
  800a22:	c3                   	ret    

00800a23 <sys_cgetc>:

int
sys_cgetc(void)
{
  800a23:	55                   	push   %ebp
  800a24:	89 e5                	mov    %esp,%ebp
  800a26:	57                   	push   %edi
  800a27:	56                   	push   %esi
  800a28:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a29:	ba 00 00 00 00       	mov    $0x0,%edx
  800a2e:	b8 01 00 00 00       	mov    $0x1,%eax
  800a33:	89 d1                	mov    %edx,%ecx
  800a35:	89 d3                	mov    %edx,%ebx
  800a37:	89 d7                	mov    %edx,%edi
  800a39:	89 d6                	mov    %edx,%esi
  800a3b:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800a3d:	5b                   	pop    %ebx
  800a3e:	5e                   	pop    %esi
  800a3f:	5f                   	pop    %edi
  800a40:	5d                   	pop    %ebp
  800a41:	c3                   	ret    

00800a42 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800a42:	55                   	push   %ebp
  800a43:	89 e5                	mov    %esp,%ebp
  800a45:	57                   	push   %edi
  800a46:	56                   	push   %esi
  800a47:	53                   	push   %ebx
  800a48:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a4b:	b9 00 00 00 00       	mov    $0x0,%ecx
  800a50:	b8 03 00 00 00       	mov    $0x3,%eax
  800a55:	8b 55 08             	mov    0x8(%ebp),%edx
  800a58:	89 cb                	mov    %ecx,%ebx
  800a5a:	89 cf                	mov    %ecx,%edi
  800a5c:	89 ce                	mov    %ecx,%esi
  800a5e:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800a60:	85 c0                	test   %eax,%eax
  800a62:	7e 17                	jle    800a7b <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800a64:	83 ec 0c             	sub    $0xc,%esp
  800a67:	50                   	push   %eax
  800a68:	6a 03                	push   $0x3
  800a6a:	68 c0 0f 80 00       	push   $0x800fc0
  800a6f:	6a 23                	push   $0x23
  800a71:	68 dd 0f 80 00       	push   $0x800fdd
  800a76:	e8 27 00 00 00       	call   800aa2 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800a7b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800a7e:	5b                   	pop    %ebx
  800a7f:	5e                   	pop    %esi
  800a80:	5f                   	pop    %edi
  800a81:	5d                   	pop    %ebp
  800a82:	c3                   	ret    

00800a83 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800a83:	55                   	push   %ebp
  800a84:	89 e5                	mov    %esp,%ebp
  800a86:	57                   	push   %edi
  800a87:	56                   	push   %esi
  800a88:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a89:	ba 00 00 00 00       	mov    $0x0,%edx
  800a8e:	b8 02 00 00 00       	mov    $0x2,%eax
  800a93:	89 d1                	mov    %edx,%ecx
  800a95:	89 d3                	mov    %edx,%ebx
  800a97:	89 d7                	mov    %edx,%edi
  800a99:	89 d6                	mov    %edx,%esi
  800a9b:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800a9d:	5b                   	pop    %ebx
  800a9e:	5e                   	pop    %esi
  800a9f:	5f                   	pop    %edi
  800aa0:	5d                   	pop    %ebp
  800aa1:	c3                   	ret    

00800aa2 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800aa2:	55                   	push   %ebp
  800aa3:	89 e5                	mov    %esp,%ebp
  800aa5:	56                   	push   %esi
  800aa6:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800aa7:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800aaa:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800ab0:	e8 ce ff ff ff       	call   800a83 <sys_getenvid>
  800ab5:	83 ec 0c             	sub    $0xc,%esp
  800ab8:	ff 75 0c             	pushl  0xc(%ebp)
  800abb:	ff 75 08             	pushl  0x8(%ebp)
  800abe:	56                   	push   %esi
  800abf:	50                   	push   %eax
  800ac0:	68 ec 0f 80 00       	push   $0x800fec
  800ac5:	e8 6f f6 ff ff       	call   800139 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800aca:	83 c4 18             	add    $0x18,%esp
  800acd:	53                   	push   %ebx
  800ace:	ff 75 10             	pushl  0x10(%ebp)
  800ad1:	e8 12 f6 ff ff       	call   8000e8 <vcprintf>
	cprintf("\n");
  800ad6:	c7 04 24 8c 0d 80 00 	movl   $0x800d8c,(%esp)
  800add:	e8 57 f6 ff ff       	call   800139 <cprintf>
  800ae2:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800ae5:	cc                   	int3   
  800ae6:	eb fd                	jmp    800ae5 <_panic+0x43>
  800ae8:	66 90                	xchg   %ax,%ax
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

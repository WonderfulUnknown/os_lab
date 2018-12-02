
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
  800051:	68 a0 0d 80 00       	push   $0x800da0
  800056:	e8 f3 00 00 00       	call   80014e <cprintf>
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
  800063:	56                   	push   %esi
  800064:	53                   	push   %ebx
  800065:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800068:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	//thisenv = 0;
	envid_t id = sys_getenvid();
  80006b:	e8 28 0a 00 00       	call   800a98 <sys_getenvid>
	thisenv = &envs[ENVX(id)];
  800070:	25 ff 03 00 00       	and    $0x3ff,%eax
  800075:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800078:	c1 e0 05             	shl    $0x5,%eax
  80007b:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800080:	a3 08 20 80 00       	mov    %eax,0x802008
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800085:	85 db                	test   %ebx,%ebx
  800087:	7e 07                	jle    800090 <libmain+0x30>
		binaryname = argv[0];
  800089:	8b 06                	mov    (%esi),%eax
  80008b:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800090:	83 ec 08             	sub    $0x8,%esp
  800093:	56                   	push   %esi
  800094:	53                   	push   %ebx
  800095:	e8 99 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80009a:	e8 0a 00 00 00       	call   8000a9 <exit>
}
  80009f:	83 c4 10             	add    $0x10,%esp
  8000a2:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8000a5:	5b                   	pop    %ebx
  8000a6:	5e                   	pop    %esi
  8000a7:	5d                   	pop    %ebp
  8000a8:	c3                   	ret    

008000a9 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000a9:	55                   	push   %ebp
  8000aa:	89 e5                	mov    %esp,%ebp
  8000ac:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8000af:	6a 00                	push   $0x0
  8000b1:	e8 a1 09 00 00       	call   800a57 <sys_env_destroy>
}
  8000b6:	83 c4 10             	add    $0x10,%esp
  8000b9:	c9                   	leave  
  8000ba:	c3                   	ret    

008000bb <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000bb:	55                   	push   %ebp
  8000bc:	89 e5                	mov    %esp,%ebp
  8000be:	53                   	push   %ebx
  8000bf:	83 ec 04             	sub    $0x4,%esp
  8000c2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000c5:	8b 13                	mov    (%ebx),%edx
  8000c7:	8d 42 01             	lea    0x1(%edx),%eax
  8000ca:	89 03                	mov    %eax,(%ebx)
  8000cc:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000cf:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000d3:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000d8:	75 1a                	jne    8000f4 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000da:	83 ec 08             	sub    $0x8,%esp
  8000dd:	68 ff 00 00 00       	push   $0xff
  8000e2:	8d 43 08             	lea    0x8(%ebx),%eax
  8000e5:	50                   	push   %eax
  8000e6:	e8 2f 09 00 00       	call   800a1a <sys_cputs>
		b->idx = 0;
  8000eb:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000f1:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000f4:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000f8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000fb:	c9                   	leave  
  8000fc:	c3                   	ret    

008000fd <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000fd:	55                   	push   %ebp
  8000fe:	89 e5                	mov    %esp,%ebp
  800100:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800106:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80010d:	00 00 00 
	b.cnt = 0;
  800110:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800117:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80011a:	ff 75 0c             	pushl  0xc(%ebp)
  80011d:	ff 75 08             	pushl  0x8(%ebp)
  800120:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800126:	50                   	push   %eax
  800127:	68 bb 00 80 00       	push   $0x8000bb
  80012c:	e8 54 01 00 00       	call   800285 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800131:	83 c4 08             	add    $0x8,%esp
  800134:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80013a:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800140:	50                   	push   %eax
  800141:	e8 d4 08 00 00       	call   800a1a <sys_cputs>

	return b.cnt;
}
  800146:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80014c:	c9                   	leave  
  80014d:	c3                   	ret    

0080014e <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80014e:	55                   	push   %ebp
  80014f:	89 e5                	mov    %esp,%ebp
  800151:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800154:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800157:	50                   	push   %eax
  800158:	ff 75 08             	pushl  0x8(%ebp)
  80015b:	e8 9d ff ff ff       	call   8000fd <vcprintf>
	va_end(ap);

	return cnt;
}
  800160:	c9                   	leave  
  800161:	c3                   	ret    

00800162 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800162:	55                   	push   %ebp
  800163:	89 e5                	mov    %esp,%ebp
  800165:	57                   	push   %edi
  800166:	56                   	push   %esi
  800167:	53                   	push   %ebx
  800168:	83 ec 1c             	sub    $0x1c,%esp
  80016b:	89 c7                	mov    %eax,%edi
  80016d:	89 d6                	mov    %edx,%esi
  80016f:	8b 45 08             	mov    0x8(%ebp),%eax
  800172:	8b 55 0c             	mov    0xc(%ebp),%edx
  800175:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800178:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80017b:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80017e:	bb 00 00 00 00       	mov    $0x0,%ebx
  800183:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800186:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800189:	39 d3                	cmp    %edx,%ebx
  80018b:	72 05                	jb     800192 <printnum+0x30>
  80018d:	39 45 10             	cmp    %eax,0x10(%ebp)
  800190:	77 45                	ja     8001d7 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800192:	83 ec 0c             	sub    $0xc,%esp
  800195:	ff 75 18             	pushl  0x18(%ebp)
  800198:	8b 45 14             	mov    0x14(%ebp),%eax
  80019b:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80019e:	53                   	push   %ebx
  80019f:	ff 75 10             	pushl  0x10(%ebp)
  8001a2:	83 ec 08             	sub    $0x8,%esp
  8001a5:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001a8:	ff 75 e0             	pushl  -0x20(%ebp)
  8001ab:	ff 75 dc             	pushl  -0x24(%ebp)
  8001ae:	ff 75 d8             	pushl  -0x28(%ebp)
  8001b1:	e8 4a 09 00 00       	call   800b00 <__udivdi3>
  8001b6:	83 c4 18             	add    $0x18,%esp
  8001b9:	52                   	push   %edx
  8001ba:	50                   	push   %eax
  8001bb:	89 f2                	mov    %esi,%edx
  8001bd:	89 f8                	mov    %edi,%eax
  8001bf:	e8 9e ff ff ff       	call   800162 <printnum>
  8001c4:	83 c4 20             	add    $0x20,%esp
  8001c7:	eb 18                	jmp    8001e1 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001c9:	83 ec 08             	sub    $0x8,%esp
  8001cc:	56                   	push   %esi
  8001cd:	ff 75 18             	pushl  0x18(%ebp)
  8001d0:	ff d7                	call   *%edi
  8001d2:	83 c4 10             	add    $0x10,%esp
  8001d5:	eb 03                	jmp    8001da <printnum+0x78>
  8001d7:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001da:	83 eb 01             	sub    $0x1,%ebx
  8001dd:	85 db                	test   %ebx,%ebx
  8001df:	7f e8                	jg     8001c9 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001e1:	83 ec 08             	sub    $0x8,%esp
  8001e4:	56                   	push   %esi
  8001e5:	83 ec 04             	sub    $0x4,%esp
  8001e8:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001eb:	ff 75 e0             	pushl  -0x20(%ebp)
  8001ee:	ff 75 dc             	pushl  -0x24(%ebp)
  8001f1:	ff 75 d8             	pushl  -0x28(%ebp)
  8001f4:	e8 37 0a 00 00       	call   800c30 <__umoddi3>
  8001f9:	83 c4 14             	add    $0x14,%esp
  8001fc:	0f be 80 b8 0d 80 00 	movsbl 0x800db8(%eax),%eax
  800203:	50                   	push   %eax
  800204:	ff d7                	call   *%edi
}
  800206:	83 c4 10             	add    $0x10,%esp
  800209:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80020c:	5b                   	pop    %ebx
  80020d:	5e                   	pop    %esi
  80020e:	5f                   	pop    %edi
  80020f:	5d                   	pop    %ebp
  800210:	c3                   	ret    

00800211 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800211:	55                   	push   %ebp
  800212:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800214:	83 fa 01             	cmp    $0x1,%edx
  800217:	7e 0e                	jle    800227 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800219:	8b 10                	mov    (%eax),%edx
  80021b:	8d 4a 08             	lea    0x8(%edx),%ecx
  80021e:	89 08                	mov    %ecx,(%eax)
  800220:	8b 02                	mov    (%edx),%eax
  800222:	8b 52 04             	mov    0x4(%edx),%edx
  800225:	eb 22                	jmp    800249 <getuint+0x38>
	else if (lflag)
  800227:	85 d2                	test   %edx,%edx
  800229:	74 10                	je     80023b <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80022b:	8b 10                	mov    (%eax),%edx
  80022d:	8d 4a 04             	lea    0x4(%edx),%ecx
  800230:	89 08                	mov    %ecx,(%eax)
  800232:	8b 02                	mov    (%edx),%eax
  800234:	ba 00 00 00 00       	mov    $0x0,%edx
  800239:	eb 0e                	jmp    800249 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80023b:	8b 10                	mov    (%eax),%edx
  80023d:	8d 4a 04             	lea    0x4(%edx),%ecx
  800240:	89 08                	mov    %ecx,(%eax)
  800242:	8b 02                	mov    (%edx),%eax
  800244:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800249:	5d                   	pop    %ebp
  80024a:	c3                   	ret    

0080024b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80024b:	55                   	push   %ebp
  80024c:	89 e5                	mov    %esp,%ebp
  80024e:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800251:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800255:	8b 10                	mov    (%eax),%edx
  800257:	3b 50 04             	cmp    0x4(%eax),%edx
  80025a:	73 0a                	jae    800266 <sprintputch+0x1b>
		*b->buf++ = ch;
  80025c:	8d 4a 01             	lea    0x1(%edx),%ecx
  80025f:	89 08                	mov    %ecx,(%eax)
  800261:	8b 45 08             	mov    0x8(%ebp),%eax
  800264:	88 02                	mov    %al,(%edx)
}
  800266:	5d                   	pop    %ebp
  800267:	c3                   	ret    

00800268 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800268:	55                   	push   %ebp
  800269:	89 e5                	mov    %esp,%ebp
  80026b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80026e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800271:	50                   	push   %eax
  800272:	ff 75 10             	pushl  0x10(%ebp)
  800275:	ff 75 0c             	pushl  0xc(%ebp)
  800278:	ff 75 08             	pushl  0x8(%ebp)
  80027b:	e8 05 00 00 00       	call   800285 <vprintfmt>
	va_end(ap);
}
  800280:	83 c4 10             	add    $0x10,%esp
  800283:	c9                   	leave  
  800284:	c3                   	ret    

00800285 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800285:	55                   	push   %ebp
  800286:	89 e5                	mov    %esp,%ebp
  800288:	57                   	push   %edi
  800289:	56                   	push   %esi
  80028a:	53                   	push   %ebx
  80028b:	83 ec 2c             	sub    $0x2c,%esp
  80028e:	8b 75 08             	mov    0x8(%ebp),%esi
  800291:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800294:	8b 7d 10             	mov    0x10(%ebp),%edi
  800297:	eb 12                	jmp    8002ab <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800299:	85 c0                	test   %eax,%eax
  80029b:	0f 84 89 03 00 00    	je     80062a <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  8002a1:	83 ec 08             	sub    $0x8,%esp
  8002a4:	53                   	push   %ebx
  8002a5:	50                   	push   %eax
  8002a6:	ff d6                	call   *%esi
  8002a8:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8002ab:	83 c7 01             	add    $0x1,%edi
  8002ae:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8002b2:	83 f8 25             	cmp    $0x25,%eax
  8002b5:	75 e2                	jne    800299 <vprintfmt+0x14>
  8002b7:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8002bb:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8002c2:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002c9:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8002d0:	ba 00 00 00 00       	mov    $0x0,%edx
  8002d5:	eb 07                	jmp    8002de <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002d7:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8002da:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002de:	8d 47 01             	lea    0x1(%edi),%eax
  8002e1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002e4:	0f b6 07             	movzbl (%edi),%eax
  8002e7:	0f b6 c8             	movzbl %al,%ecx
  8002ea:	83 e8 23             	sub    $0x23,%eax
  8002ed:	3c 55                	cmp    $0x55,%al
  8002ef:	0f 87 1a 03 00 00    	ja     80060f <vprintfmt+0x38a>
  8002f5:	0f b6 c0             	movzbl %al,%eax
  8002f8:	ff 24 85 60 0e 80 00 	jmp    *0x800e60(,%eax,4)
  8002ff:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800302:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800306:	eb d6                	jmp    8002de <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800308:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80030b:	b8 00 00 00 00       	mov    $0x0,%eax
  800310:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800313:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800316:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  80031a:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80031d:	8d 51 d0             	lea    -0x30(%ecx),%edx
  800320:	83 fa 09             	cmp    $0x9,%edx
  800323:	77 39                	ja     80035e <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800325:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800328:	eb e9                	jmp    800313 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80032a:	8b 45 14             	mov    0x14(%ebp),%eax
  80032d:	8d 48 04             	lea    0x4(%eax),%ecx
  800330:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800333:	8b 00                	mov    (%eax),%eax
  800335:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800338:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80033b:	eb 27                	jmp    800364 <vprintfmt+0xdf>
  80033d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800340:	85 c0                	test   %eax,%eax
  800342:	b9 00 00 00 00       	mov    $0x0,%ecx
  800347:	0f 49 c8             	cmovns %eax,%ecx
  80034a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80034d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800350:	eb 8c                	jmp    8002de <vprintfmt+0x59>
  800352:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800355:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80035c:	eb 80                	jmp    8002de <vprintfmt+0x59>
  80035e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800361:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800364:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800368:	0f 89 70 ff ff ff    	jns    8002de <vprintfmt+0x59>
				width = precision, precision = -1;
  80036e:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800371:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800374:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80037b:	e9 5e ff ff ff       	jmp    8002de <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800380:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800383:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800386:	e9 53 ff ff ff       	jmp    8002de <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80038b:	8b 45 14             	mov    0x14(%ebp),%eax
  80038e:	8d 50 04             	lea    0x4(%eax),%edx
  800391:	89 55 14             	mov    %edx,0x14(%ebp)
  800394:	83 ec 08             	sub    $0x8,%esp
  800397:	53                   	push   %ebx
  800398:	ff 30                	pushl  (%eax)
  80039a:	ff d6                	call   *%esi
			break;
  80039c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80039f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8003a2:	e9 04 ff ff ff       	jmp    8002ab <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003a7:	8b 45 14             	mov    0x14(%ebp),%eax
  8003aa:	8d 50 04             	lea    0x4(%eax),%edx
  8003ad:	89 55 14             	mov    %edx,0x14(%ebp)
  8003b0:	8b 00                	mov    (%eax),%eax
  8003b2:	99                   	cltd   
  8003b3:	31 d0                	xor    %edx,%eax
  8003b5:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003b7:	83 f8 07             	cmp    $0x7,%eax
  8003ba:	7f 0b                	jg     8003c7 <vprintfmt+0x142>
  8003bc:	8b 14 85 c0 0f 80 00 	mov    0x800fc0(,%eax,4),%edx
  8003c3:	85 d2                	test   %edx,%edx
  8003c5:	75 18                	jne    8003df <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8003c7:	50                   	push   %eax
  8003c8:	68 d0 0d 80 00       	push   $0x800dd0
  8003cd:	53                   	push   %ebx
  8003ce:	56                   	push   %esi
  8003cf:	e8 94 fe ff ff       	call   800268 <printfmt>
  8003d4:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003da:	e9 cc fe ff ff       	jmp    8002ab <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003df:	52                   	push   %edx
  8003e0:	68 d9 0d 80 00       	push   $0x800dd9
  8003e5:	53                   	push   %ebx
  8003e6:	56                   	push   %esi
  8003e7:	e8 7c fe ff ff       	call   800268 <printfmt>
  8003ec:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003f2:	e9 b4 fe ff ff       	jmp    8002ab <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003f7:	8b 45 14             	mov    0x14(%ebp),%eax
  8003fa:	8d 50 04             	lea    0x4(%eax),%edx
  8003fd:	89 55 14             	mov    %edx,0x14(%ebp)
  800400:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800402:	85 ff                	test   %edi,%edi
  800404:	b8 c9 0d 80 00       	mov    $0x800dc9,%eax
  800409:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  80040c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800410:	0f 8e 94 00 00 00    	jle    8004aa <vprintfmt+0x225>
  800416:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  80041a:	0f 84 98 00 00 00    	je     8004b8 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  800420:	83 ec 08             	sub    $0x8,%esp
  800423:	ff 75 d0             	pushl  -0x30(%ebp)
  800426:	57                   	push   %edi
  800427:	e8 86 02 00 00       	call   8006b2 <strnlen>
  80042c:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80042f:	29 c1                	sub    %eax,%ecx
  800431:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800434:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800437:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80043b:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80043e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800441:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800443:	eb 0f                	jmp    800454 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800445:	83 ec 08             	sub    $0x8,%esp
  800448:	53                   	push   %ebx
  800449:	ff 75 e0             	pushl  -0x20(%ebp)
  80044c:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80044e:	83 ef 01             	sub    $0x1,%edi
  800451:	83 c4 10             	add    $0x10,%esp
  800454:	85 ff                	test   %edi,%edi
  800456:	7f ed                	jg     800445 <vprintfmt+0x1c0>
  800458:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80045b:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80045e:	85 c9                	test   %ecx,%ecx
  800460:	b8 00 00 00 00       	mov    $0x0,%eax
  800465:	0f 49 c1             	cmovns %ecx,%eax
  800468:	29 c1                	sub    %eax,%ecx
  80046a:	89 75 08             	mov    %esi,0x8(%ebp)
  80046d:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800470:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800473:	89 cb                	mov    %ecx,%ebx
  800475:	eb 4d                	jmp    8004c4 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800477:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80047b:	74 1b                	je     800498 <vprintfmt+0x213>
  80047d:	0f be c0             	movsbl %al,%eax
  800480:	83 e8 20             	sub    $0x20,%eax
  800483:	83 f8 5e             	cmp    $0x5e,%eax
  800486:	76 10                	jbe    800498 <vprintfmt+0x213>
					putch('?', putdat);
  800488:	83 ec 08             	sub    $0x8,%esp
  80048b:	ff 75 0c             	pushl  0xc(%ebp)
  80048e:	6a 3f                	push   $0x3f
  800490:	ff 55 08             	call   *0x8(%ebp)
  800493:	83 c4 10             	add    $0x10,%esp
  800496:	eb 0d                	jmp    8004a5 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800498:	83 ec 08             	sub    $0x8,%esp
  80049b:	ff 75 0c             	pushl  0xc(%ebp)
  80049e:	52                   	push   %edx
  80049f:	ff 55 08             	call   *0x8(%ebp)
  8004a2:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004a5:	83 eb 01             	sub    $0x1,%ebx
  8004a8:	eb 1a                	jmp    8004c4 <vprintfmt+0x23f>
  8004aa:	89 75 08             	mov    %esi,0x8(%ebp)
  8004ad:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004b0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004b3:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004b6:	eb 0c                	jmp    8004c4 <vprintfmt+0x23f>
  8004b8:	89 75 08             	mov    %esi,0x8(%ebp)
  8004bb:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004be:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004c1:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004c4:	83 c7 01             	add    $0x1,%edi
  8004c7:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004cb:	0f be d0             	movsbl %al,%edx
  8004ce:	85 d2                	test   %edx,%edx
  8004d0:	74 23                	je     8004f5 <vprintfmt+0x270>
  8004d2:	85 f6                	test   %esi,%esi
  8004d4:	78 a1                	js     800477 <vprintfmt+0x1f2>
  8004d6:	83 ee 01             	sub    $0x1,%esi
  8004d9:	79 9c                	jns    800477 <vprintfmt+0x1f2>
  8004db:	89 df                	mov    %ebx,%edi
  8004dd:	8b 75 08             	mov    0x8(%ebp),%esi
  8004e0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004e3:	eb 18                	jmp    8004fd <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004e5:	83 ec 08             	sub    $0x8,%esp
  8004e8:	53                   	push   %ebx
  8004e9:	6a 20                	push   $0x20
  8004eb:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004ed:	83 ef 01             	sub    $0x1,%edi
  8004f0:	83 c4 10             	add    $0x10,%esp
  8004f3:	eb 08                	jmp    8004fd <vprintfmt+0x278>
  8004f5:	89 df                	mov    %ebx,%edi
  8004f7:	8b 75 08             	mov    0x8(%ebp),%esi
  8004fa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004fd:	85 ff                	test   %edi,%edi
  8004ff:	7f e4                	jg     8004e5 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800501:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800504:	e9 a2 fd ff ff       	jmp    8002ab <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800509:	83 fa 01             	cmp    $0x1,%edx
  80050c:	7e 16                	jle    800524 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  80050e:	8b 45 14             	mov    0x14(%ebp),%eax
  800511:	8d 50 08             	lea    0x8(%eax),%edx
  800514:	89 55 14             	mov    %edx,0x14(%ebp)
  800517:	8b 50 04             	mov    0x4(%eax),%edx
  80051a:	8b 00                	mov    (%eax),%eax
  80051c:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80051f:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800522:	eb 32                	jmp    800556 <vprintfmt+0x2d1>
	else if (lflag)
  800524:	85 d2                	test   %edx,%edx
  800526:	74 18                	je     800540 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  800528:	8b 45 14             	mov    0x14(%ebp),%eax
  80052b:	8d 50 04             	lea    0x4(%eax),%edx
  80052e:	89 55 14             	mov    %edx,0x14(%ebp)
  800531:	8b 00                	mov    (%eax),%eax
  800533:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800536:	89 c1                	mov    %eax,%ecx
  800538:	c1 f9 1f             	sar    $0x1f,%ecx
  80053b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80053e:	eb 16                	jmp    800556 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  800540:	8b 45 14             	mov    0x14(%ebp),%eax
  800543:	8d 50 04             	lea    0x4(%eax),%edx
  800546:	89 55 14             	mov    %edx,0x14(%ebp)
  800549:	8b 00                	mov    (%eax),%eax
  80054b:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80054e:	89 c1                	mov    %eax,%ecx
  800550:	c1 f9 1f             	sar    $0x1f,%ecx
  800553:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800556:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800559:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80055c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800561:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800565:	79 74                	jns    8005db <vprintfmt+0x356>
				putch('-', putdat);
  800567:	83 ec 08             	sub    $0x8,%esp
  80056a:	53                   	push   %ebx
  80056b:	6a 2d                	push   $0x2d
  80056d:	ff d6                	call   *%esi
				num = -(long long) num;
  80056f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800572:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800575:	f7 d8                	neg    %eax
  800577:	83 d2 00             	adc    $0x0,%edx
  80057a:	f7 da                	neg    %edx
  80057c:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80057f:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800584:	eb 55                	jmp    8005db <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800586:	8d 45 14             	lea    0x14(%ebp),%eax
  800589:	e8 83 fc ff ff       	call   800211 <getuint>
			base = 10;
  80058e:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800593:	eb 46                	jmp    8005db <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800595:	8d 45 14             	lea    0x14(%ebp),%eax
  800598:	e8 74 fc ff ff       	call   800211 <getuint>
			base = 8;
  80059d:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8005a2:	eb 37                	jmp    8005db <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  8005a4:	83 ec 08             	sub    $0x8,%esp
  8005a7:	53                   	push   %ebx
  8005a8:	6a 30                	push   $0x30
  8005aa:	ff d6                	call   *%esi
			putch('x', putdat);
  8005ac:	83 c4 08             	add    $0x8,%esp
  8005af:	53                   	push   %ebx
  8005b0:	6a 78                	push   $0x78
  8005b2:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8005b4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b7:	8d 50 04             	lea    0x4(%eax),%edx
  8005ba:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8005bd:	8b 00                	mov    (%eax),%eax
  8005bf:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8005c4:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8005c7:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8005cc:	eb 0d                	jmp    8005db <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8005ce:	8d 45 14             	lea    0x14(%ebp),%eax
  8005d1:	e8 3b fc ff ff       	call   800211 <getuint>
			base = 16;
  8005d6:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8005db:	83 ec 0c             	sub    $0xc,%esp
  8005de:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8005e2:	57                   	push   %edi
  8005e3:	ff 75 e0             	pushl  -0x20(%ebp)
  8005e6:	51                   	push   %ecx
  8005e7:	52                   	push   %edx
  8005e8:	50                   	push   %eax
  8005e9:	89 da                	mov    %ebx,%edx
  8005eb:	89 f0                	mov    %esi,%eax
  8005ed:	e8 70 fb ff ff       	call   800162 <printnum>
			break;
  8005f2:	83 c4 20             	add    $0x20,%esp
  8005f5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005f8:	e9 ae fc ff ff       	jmp    8002ab <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8005fd:	83 ec 08             	sub    $0x8,%esp
  800600:	53                   	push   %ebx
  800601:	51                   	push   %ecx
  800602:	ff d6                	call   *%esi
			break;
  800604:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800607:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  80060a:	e9 9c fc ff ff       	jmp    8002ab <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80060f:	83 ec 08             	sub    $0x8,%esp
  800612:	53                   	push   %ebx
  800613:	6a 25                	push   $0x25
  800615:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800617:	83 c4 10             	add    $0x10,%esp
  80061a:	eb 03                	jmp    80061f <vprintfmt+0x39a>
  80061c:	83 ef 01             	sub    $0x1,%edi
  80061f:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800623:	75 f7                	jne    80061c <vprintfmt+0x397>
  800625:	e9 81 fc ff ff       	jmp    8002ab <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  80062a:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80062d:	5b                   	pop    %ebx
  80062e:	5e                   	pop    %esi
  80062f:	5f                   	pop    %edi
  800630:	5d                   	pop    %ebp
  800631:	c3                   	ret    

00800632 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800632:	55                   	push   %ebp
  800633:	89 e5                	mov    %esp,%ebp
  800635:	83 ec 18             	sub    $0x18,%esp
  800638:	8b 45 08             	mov    0x8(%ebp),%eax
  80063b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80063e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800641:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800645:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800648:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80064f:	85 c0                	test   %eax,%eax
  800651:	74 26                	je     800679 <vsnprintf+0x47>
  800653:	85 d2                	test   %edx,%edx
  800655:	7e 22                	jle    800679 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800657:	ff 75 14             	pushl  0x14(%ebp)
  80065a:	ff 75 10             	pushl  0x10(%ebp)
  80065d:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800660:	50                   	push   %eax
  800661:	68 4b 02 80 00       	push   $0x80024b
  800666:	e8 1a fc ff ff       	call   800285 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80066b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80066e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800671:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800674:	83 c4 10             	add    $0x10,%esp
  800677:	eb 05                	jmp    80067e <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800679:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80067e:	c9                   	leave  
  80067f:	c3                   	ret    

00800680 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800680:	55                   	push   %ebp
  800681:	89 e5                	mov    %esp,%ebp
  800683:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800686:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800689:	50                   	push   %eax
  80068a:	ff 75 10             	pushl  0x10(%ebp)
  80068d:	ff 75 0c             	pushl  0xc(%ebp)
  800690:	ff 75 08             	pushl  0x8(%ebp)
  800693:	e8 9a ff ff ff       	call   800632 <vsnprintf>
	va_end(ap);

	return rc;
}
  800698:	c9                   	leave  
  800699:	c3                   	ret    

0080069a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80069a:	55                   	push   %ebp
  80069b:	89 e5                	mov    %esp,%ebp
  80069d:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8006a0:	b8 00 00 00 00       	mov    $0x0,%eax
  8006a5:	eb 03                	jmp    8006aa <strlen+0x10>
		n++;
  8006a7:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8006aa:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8006ae:	75 f7                	jne    8006a7 <strlen+0xd>
		n++;
	return n;
}
  8006b0:	5d                   	pop    %ebp
  8006b1:	c3                   	ret    

008006b2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8006b2:	55                   	push   %ebp
  8006b3:	89 e5                	mov    %esp,%ebp
  8006b5:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8006b8:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006bb:	ba 00 00 00 00       	mov    $0x0,%edx
  8006c0:	eb 03                	jmp    8006c5 <strnlen+0x13>
		n++;
  8006c2:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006c5:	39 c2                	cmp    %eax,%edx
  8006c7:	74 08                	je     8006d1 <strnlen+0x1f>
  8006c9:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8006cd:	75 f3                	jne    8006c2 <strnlen+0x10>
  8006cf:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8006d1:	5d                   	pop    %ebp
  8006d2:	c3                   	ret    

008006d3 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8006d3:	55                   	push   %ebp
  8006d4:	89 e5                	mov    %esp,%ebp
  8006d6:	53                   	push   %ebx
  8006d7:	8b 45 08             	mov    0x8(%ebp),%eax
  8006da:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8006dd:	89 c2                	mov    %eax,%edx
  8006df:	83 c2 01             	add    $0x1,%edx
  8006e2:	83 c1 01             	add    $0x1,%ecx
  8006e5:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8006e9:	88 5a ff             	mov    %bl,-0x1(%edx)
  8006ec:	84 db                	test   %bl,%bl
  8006ee:	75 ef                	jne    8006df <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8006f0:	5b                   	pop    %ebx
  8006f1:	5d                   	pop    %ebp
  8006f2:	c3                   	ret    

008006f3 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8006f3:	55                   	push   %ebp
  8006f4:	89 e5                	mov    %esp,%ebp
  8006f6:	53                   	push   %ebx
  8006f7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8006fa:	53                   	push   %ebx
  8006fb:	e8 9a ff ff ff       	call   80069a <strlen>
  800700:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800703:	ff 75 0c             	pushl  0xc(%ebp)
  800706:	01 d8                	add    %ebx,%eax
  800708:	50                   	push   %eax
  800709:	e8 c5 ff ff ff       	call   8006d3 <strcpy>
	return dst;
}
  80070e:	89 d8                	mov    %ebx,%eax
  800710:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800713:	c9                   	leave  
  800714:	c3                   	ret    

00800715 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800715:	55                   	push   %ebp
  800716:	89 e5                	mov    %esp,%ebp
  800718:	56                   	push   %esi
  800719:	53                   	push   %ebx
  80071a:	8b 75 08             	mov    0x8(%ebp),%esi
  80071d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800720:	89 f3                	mov    %esi,%ebx
  800722:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800725:	89 f2                	mov    %esi,%edx
  800727:	eb 0f                	jmp    800738 <strncpy+0x23>
		*dst++ = *src;
  800729:	83 c2 01             	add    $0x1,%edx
  80072c:	0f b6 01             	movzbl (%ecx),%eax
  80072f:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800732:	80 39 01             	cmpb   $0x1,(%ecx)
  800735:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800738:	39 da                	cmp    %ebx,%edx
  80073a:	75 ed                	jne    800729 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80073c:	89 f0                	mov    %esi,%eax
  80073e:	5b                   	pop    %ebx
  80073f:	5e                   	pop    %esi
  800740:	5d                   	pop    %ebp
  800741:	c3                   	ret    

00800742 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800742:	55                   	push   %ebp
  800743:	89 e5                	mov    %esp,%ebp
  800745:	56                   	push   %esi
  800746:	53                   	push   %ebx
  800747:	8b 75 08             	mov    0x8(%ebp),%esi
  80074a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80074d:	8b 55 10             	mov    0x10(%ebp),%edx
  800750:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800752:	85 d2                	test   %edx,%edx
  800754:	74 21                	je     800777 <strlcpy+0x35>
  800756:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  80075a:	89 f2                	mov    %esi,%edx
  80075c:	eb 09                	jmp    800767 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80075e:	83 c2 01             	add    $0x1,%edx
  800761:	83 c1 01             	add    $0x1,%ecx
  800764:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800767:	39 c2                	cmp    %eax,%edx
  800769:	74 09                	je     800774 <strlcpy+0x32>
  80076b:	0f b6 19             	movzbl (%ecx),%ebx
  80076e:	84 db                	test   %bl,%bl
  800770:	75 ec                	jne    80075e <strlcpy+0x1c>
  800772:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800774:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800777:	29 f0                	sub    %esi,%eax
}
  800779:	5b                   	pop    %ebx
  80077a:	5e                   	pop    %esi
  80077b:	5d                   	pop    %ebp
  80077c:	c3                   	ret    

0080077d <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80077d:	55                   	push   %ebp
  80077e:	89 e5                	mov    %esp,%ebp
  800780:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800783:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800786:	eb 06                	jmp    80078e <strcmp+0x11>
		p++, q++;
  800788:	83 c1 01             	add    $0x1,%ecx
  80078b:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80078e:	0f b6 01             	movzbl (%ecx),%eax
  800791:	84 c0                	test   %al,%al
  800793:	74 04                	je     800799 <strcmp+0x1c>
  800795:	3a 02                	cmp    (%edx),%al
  800797:	74 ef                	je     800788 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800799:	0f b6 c0             	movzbl %al,%eax
  80079c:	0f b6 12             	movzbl (%edx),%edx
  80079f:	29 d0                	sub    %edx,%eax
}
  8007a1:	5d                   	pop    %ebp
  8007a2:	c3                   	ret    

008007a3 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8007a3:	55                   	push   %ebp
  8007a4:	89 e5                	mov    %esp,%ebp
  8007a6:	53                   	push   %ebx
  8007a7:	8b 45 08             	mov    0x8(%ebp),%eax
  8007aa:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007ad:	89 c3                	mov    %eax,%ebx
  8007af:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8007b2:	eb 06                	jmp    8007ba <strncmp+0x17>
		n--, p++, q++;
  8007b4:	83 c0 01             	add    $0x1,%eax
  8007b7:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8007ba:	39 d8                	cmp    %ebx,%eax
  8007bc:	74 15                	je     8007d3 <strncmp+0x30>
  8007be:	0f b6 08             	movzbl (%eax),%ecx
  8007c1:	84 c9                	test   %cl,%cl
  8007c3:	74 04                	je     8007c9 <strncmp+0x26>
  8007c5:	3a 0a                	cmp    (%edx),%cl
  8007c7:	74 eb                	je     8007b4 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8007c9:	0f b6 00             	movzbl (%eax),%eax
  8007cc:	0f b6 12             	movzbl (%edx),%edx
  8007cf:	29 d0                	sub    %edx,%eax
  8007d1:	eb 05                	jmp    8007d8 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8007d3:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8007d8:	5b                   	pop    %ebx
  8007d9:	5d                   	pop    %ebp
  8007da:	c3                   	ret    

008007db <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8007db:	55                   	push   %ebp
  8007dc:	89 e5                	mov    %esp,%ebp
  8007de:	8b 45 08             	mov    0x8(%ebp),%eax
  8007e1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007e5:	eb 07                	jmp    8007ee <strchr+0x13>
		if (*s == c)
  8007e7:	38 ca                	cmp    %cl,%dl
  8007e9:	74 0f                	je     8007fa <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8007eb:	83 c0 01             	add    $0x1,%eax
  8007ee:	0f b6 10             	movzbl (%eax),%edx
  8007f1:	84 d2                	test   %dl,%dl
  8007f3:	75 f2                	jne    8007e7 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8007f5:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8007fa:	5d                   	pop    %ebp
  8007fb:	c3                   	ret    

008007fc <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8007fc:	55                   	push   %ebp
  8007fd:	89 e5                	mov    %esp,%ebp
  8007ff:	8b 45 08             	mov    0x8(%ebp),%eax
  800802:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800806:	eb 03                	jmp    80080b <strfind+0xf>
  800808:	83 c0 01             	add    $0x1,%eax
  80080b:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  80080e:	38 ca                	cmp    %cl,%dl
  800810:	74 04                	je     800816 <strfind+0x1a>
  800812:	84 d2                	test   %dl,%dl
  800814:	75 f2                	jne    800808 <strfind+0xc>
			break;
	return (char *) s;
}
  800816:	5d                   	pop    %ebp
  800817:	c3                   	ret    

00800818 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800818:	55                   	push   %ebp
  800819:	89 e5                	mov    %esp,%ebp
  80081b:	57                   	push   %edi
  80081c:	56                   	push   %esi
  80081d:	53                   	push   %ebx
  80081e:	8b 7d 08             	mov    0x8(%ebp),%edi
  800821:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800824:	85 c9                	test   %ecx,%ecx
  800826:	74 36                	je     80085e <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800828:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80082e:	75 28                	jne    800858 <memset+0x40>
  800830:	f6 c1 03             	test   $0x3,%cl
  800833:	75 23                	jne    800858 <memset+0x40>
		c &= 0xFF;
  800835:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800839:	89 d3                	mov    %edx,%ebx
  80083b:	c1 e3 08             	shl    $0x8,%ebx
  80083e:	89 d6                	mov    %edx,%esi
  800840:	c1 e6 18             	shl    $0x18,%esi
  800843:	89 d0                	mov    %edx,%eax
  800845:	c1 e0 10             	shl    $0x10,%eax
  800848:	09 f0                	or     %esi,%eax
  80084a:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  80084c:	89 d8                	mov    %ebx,%eax
  80084e:	09 d0                	or     %edx,%eax
  800850:	c1 e9 02             	shr    $0x2,%ecx
  800853:	fc                   	cld    
  800854:	f3 ab                	rep stos %eax,%es:(%edi)
  800856:	eb 06                	jmp    80085e <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800858:	8b 45 0c             	mov    0xc(%ebp),%eax
  80085b:	fc                   	cld    
  80085c:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80085e:	89 f8                	mov    %edi,%eax
  800860:	5b                   	pop    %ebx
  800861:	5e                   	pop    %esi
  800862:	5f                   	pop    %edi
  800863:	5d                   	pop    %ebp
  800864:	c3                   	ret    

00800865 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800865:	55                   	push   %ebp
  800866:	89 e5                	mov    %esp,%ebp
  800868:	57                   	push   %edi
  800869:	56                   	push   %esi
  80086a:	8b 45 08             	mov    0x8(%ebp),%eax
  80086d:	8b 75 0c             	mov    0xc(%ebp),%esi
  800870:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800873:	39 c6                	cmp    %eax,%esi
  800875:	73 35                	jae    8008ac <memmove+0x47>
  800877:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80087a:	39 d0                	cmp    %edx,%eax
  80087c:	73 2e                	jae    8008ac <memmove+0x47>
		s += n;
		d += n;
  80087e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800881:	89 d6                	mov    %edx,%esi
  800883:	09 fe                	or     %edi,%esi
  800885:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80088b:	75 13                	jne    8008a0 <memmove+0x3b>
  80088d:	f6 c1 03             	test   $0x3,%cl
  800890:	75 0e                	jne    8008a0 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800892:	83 ef 04             	sub    $0x4,%edi
  800895:	8d 72 fc             	lea    -0x4(%edx),%esi
  800898:	c1 e9 02             	shr    $0x2,%ecx
  80089b:	fd                   	std    
  80089c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80089e:	eb 09                	jmp    8008a9 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8008a0:	83 ef 01             	sub    $0x1,%edi
  8008a3:	8d 72 ff             	lea    -0x1(%edx),%esi
  8008a6:	fd                   	std    
  8008a7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8008a9:	fc                   	cld    
  8008aa:	eb 1d                	jmp    8008c9 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8008ac:	89 f2                	mov    %esi,%edx
  8008ae:	09 c2                	or     %eax,%edx
  8008b0:	f6 c2 03             	test   $0x3,%dl
  8008b3:	75 0f                	jne    8008c4 <memmove+0x5f>
  8008b5:	f6 c1 03             	test   $0x3,%cl
  8008b8:	75 0a                	jne    8008c4 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8008ba:	c1 e9 02             	shr    $0x2,%ecx
  8008bd:	89 c7                	mov    %eax,%edi
  8008bf:	fc                   	cld    
  8008c0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8008c2:	eb 05                	jmp    8008c9 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8008c4:	89 c7                	mov    %eax,%edi
  8008c6:	fc                   	cld    
  8008c7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8008c9:	5e                   	pop    %esi
  8008ca:	5f                   	pop    %edi
  8008cb:	5d                   	pop    %ebp
  8008cc:	c3                   	ret    

008008cd <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8008cd:	55                   	push   %ebp
  8008ce:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8008d0:	ff 75 10             	pushl  0x10(%ebp)
  8008d3:	ff 75 0c             	pushl  0xc(%ebp)
  8008d6:	ff 75 08             	pushl  0x8(%ebp)
  8008d9:	e8 87 ff ff ff       	call   800865 <memmove>
}
  8008de:	c9                   	leave  
  8008df:	c3                   	ret    

008008e0 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8008e0:	55                   	push   %ebp
  8008e1:	89 e5                	mov    %esp,%ebp
  8008e3:	56                   	push   %esi
  8008e4:	53                   	push   %ebx
  8008e5:	8b 45 08             	mov    0x8(%ebp),%eax
  8008e8:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008eb:	89 c6                	mov    %eax,%esi
  8008ed:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008f0:	eb 1a                	jmp    80090c <memcmp+0x2c>
		if (*s1 != *s2)
  8008f2:	0f b6 08             	movzbl (%eax),%ecx
  8008f5:	0f b6 1a             	movzbl (%edx),%ebx
  8008f8:	38 d9                	cmp    %bl,%cl
  8008fa:	74 0a                	je     800906 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8008fc:	0f b6 c1             	movzbl %cl,%eax
  8008ff:	0f b6 db             	movzbl %bl,%ebx
  800902:	29 d8                	sub    %ebx,%eax
  800904:	eb 0f                	jmp    800915 <memcmp+0x35>
		s1++, s2++;
  800906:	83 c0 01             	add    $0x1,%eax
  800909:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80090c:	39 f0                	cmp    %esi,%eax
  80090e:	75 e2                	jne    8008f2 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800910:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800915:	5b                   	pop    %ebx
  800916:	5e                   	pop    %esi
  800917:	5d                   	pop    %ebp
  800918:	c3                   	ret    

00800919 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800919:	55                   	push   %ebp
  80091a:	89 e5                	mov    %esp,%ebp
  80091c:	53                   	push   %ebx
  80091d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800920:	89 c1                	mov    %eax,%ecx
  800922:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800925:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800929:	eb 0a                	jmp    800935 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  80092b:	0f b6 10             	movzbl (%eax),%edx
  80092e:	39 da                	cmp    %ebx,%edx
  800930:	74 07                	je     800939 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800932:	83 c0 01             	add    $0x1,%eax
  800935:	39 c8                	cmp    %ecx,%eax
  800937:	72 f2                	jb     80092b <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800939:	5b                   	pop    %ebx
  80093a:	5d                   	pop    %ebp
  80093b:	c3                   	ret    

0080093c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  80093c:	55                   	push   %ebp
  80093d:	89 e5                	mov    %esp,%ebp
  80093f:	57                   	push   %edi
  800940:	56                   	push   %esi
  800941:	53                   	push   %ebx
  800942:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800945:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800948:	eb 03                	jmp    80094d <strtol+0x11>
		s++;
  80094a:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  80094d:	0f b6 01             	movzbl (%ecx),%eax
  800950:	3c 20                	cmp    $0x20,%al
  800952:	74 f6                	je     80094a <strtol+0xe>
  800954:	3c 09                	cmp    $0x9,%al
  800956:	74 f2                	je     80094a <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800958:	3c 2b                	cmp    $0x2b,%al
  80095a:	75 0a                	jne    800966 <strtol+0x2a>
		s++;
  80095c:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  80095f:	bf 00 00 00 00       	mov    $0x0,%edi
  800964:	eb 11                	jmp    800977 <strtol+0x3b>
  800966:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  80096b:	3c 2d                	cmp    $0x2d,%al
  80096d:	75 08                	jne    800977 <strtol+0x3b>
		s++, neg = 1;
  80096f:	83 c1 01             	add    $0x1,%ecx
  800972:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800977:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  80097d:	75 15                	jne    800994 <strtol+0x58>
  80097f:	80 39 30             	cmpb   $0x30,(%ecx)
  800982:	75 10                	jne    800994 <strtol+0x58>
  800984:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800988:	75 7c                	jne    800a06 <strtol+0xca>
		s += 2, base = 16;
  80098a:	83 c1 02             	add    $0x2,%ecx
  80098d:	bb 10 00 00 00       	mov    $0x10,%ebx
  800992:	eb 16                	jmp    8009aa <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800994:	85 db                	test   %ebx,%ebx
  800996:	75 12                	jne    8009aa <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800998:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  80099d:	80 39 30             	cmpb   $0x30,(%ecx)
  8009a0:	75 08                	jne    8009aa <strtol+0x6e>
		s++, base = 8;
  8009a2:	83 c1 01             	add    $0x1,%ecx
  8009a5:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  8009aa:	b8 00 00 00 00       	mov    $0x0,%eax
  8009af:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  8009b2:	0f b6 11             	movzbl (%ecx),%edx
  8009b5:	8d 72 d0             	lea    -0x30(%edx),%esi
  8009b8:	89 f3                	mov    %esi,%ebx
  8009ba:	80 fb 09             	cmp    $0x9,%bl
  8009bd:	77 08                	ja     8009c7 <strtol+0x8b>
			dig = *s - '0';
  8009bf:	0f be d2             	movsbl %dl,%edx
  8009c2:	83 ea 30             	sub    $0x30,%edx
  8009c5:	eb 22                	jmp    8009e9 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  8009c7:	8d 72 9f             	lea    -0x61(%edx),%esi
  8009ca:	89 f3                	mov    %esi,%ebx
  8009cc:	80 fb 19             	cmp    $0x19,%bl
  8009cf:	77 08                	ja     8009d9 <strtol+0x9d>
			dig = *s - 'a' + 10;
  8009d1:	0f be d2             	movsbl %dl,%edx
  8009d4:	83 ea 57             	sub    $0x57,%edx
  8009d7:	eb 10                	jmp    8009e9 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  8009d9:	8d 72 bf             	lea    -0x41(%edx),%esi
  8009dc:	89 f3                	mov    %esi,%ebx
  8009de:	80 fb 19             	cmp    $0x19,%bl
  8009e1:	77 16                	ja     8009f9 <strtol+0xbd>
			dig = *s - 'A' + 10;
  8009e3:	0f be d2             	movsbl %dl,%edx
  8009e6:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  8009e9:	3b 55 10             	cmp    0x10(%ebp),%edx
  8009ec:	7d 0b                	jge    8009f9 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  8009ee:	83 c1 01             	add    $0x1,%ecx
  8009f1:	0f af 45 10          	imul   0x10(%ebp),%eax
  8009f5:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  8009f7:	eb b9                	jmp    8009b2 <strtol+0x76>

	if (endptr)
  8009f9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8009fd:	74 0d                	je     800a0c <strtol+0xd0>
		*endptr = (char *) s;
  8009ff:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a02:	89 0e                	mov    %ecx,(%esi)
  800a04:	eb 06                	jmp    800a0c <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a06:	85 db                	test   %ebx,%ebx
  800a08:	74 98                	je     8009a2 <strtol+0x66>
  800a0a:	eb 9e                	jmp    8009aa <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800a0c:	89 c2                	mov    %eax,%edx
  800a0e:	f7 da                	neg    %edx
  800a10:	85 ff                	test   %edi,%edi
  800a12:	0f 45 c2             	cmovne %edx,%eax
}
  800a15:	5b                   	pop    %ebx
  800a16:	5e                   	pop    %esi
  800a17:	5f                   	pop    %edi
  800a18:	5d                   	pop    %ebp
  800a19:	c3                   	ret    

00800a1a <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800a1a:	55                   	push   %ebp
  800a1b:	89 e5                	mov    %esp,%ebp
  800a1d:	57                   	push   %edi
  800a1e:	56                   	push   %esi
  800a1f:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a20:	b8 00 00 00 00       	mov    $0x0,%eax
  800a25:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a28:	8b 55 08             	mov    0x8(%ebp),%edx
  800a2b:	89 c3                	mov    %eax,%ebx
  800a2d:	89 c7                	mov    %eax,%edi
  800a2f:	89 c6                	mov    %eax,%esi
  800a31:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800a33:	5b                   	pop    %ebx
  800a34:	5e                   	pop    %esi
  800a35:	5f                   	pop    %edi
  800a36:	5d                   	pop    %ebp
  800a37:	c3                   	ret    

00800a38 <sys_cgetc>:

int
sys_cgetc(void)
{
  800a38:	55                   	push   %ebp
  800a39:	89 e5                	mov    %esp,%ebp
  800a3b:	57                   	push   %edi
  800a3c:	56                   	push   %esi
  800a3d:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a3e:	ba 00 00 00 00       	mov    $0x0,%edx
  800a43:	b8 01 00 00 00       	mov    $0x1,%eax
  800a48:	89 d1                	mov    %edx,%ecx
  800a4a:	89 d3                	mov    %edx,%ebx
  800a4c:	89 d7                	mov    %edx,%edi
  800a4e:	89 d6                	mov    %edx,%esi
  800a50:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800a52:	5b                   	pop    %ebx
  800a53:	5e                   	pop    %esi
  800a54:	5f                   	pop    %edi
  800a55:	5d                   	pop    %ebp
  800a56:	c3                   	ret    

00800a57 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800a57:	55                   	push   %ebp
  800a58:	89 e5                	mov    %esp,%ebp
  800a5a:	57                   	push   %edi
  800a5b:	56                   	push   %esi
  800a5c:	53                   	push   %ebx
  800a5d:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a60:	b9 00 00 00 00       	mov    $0x0,%ecx
  800a65:	b8 03 00 00 00       	mov    $0x3,%eax
  800a6a:	8b 55 08             	mov    0x8(%ebp),%edx
  800a6d:	89 cb                	mov    %ecx,%ebx
  800a6f:	89 cf                	mov    %ecx,%edi
  800a71:	89 ce                	mov    %ecx,%esi
  800a73:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800a75:	85 c0                	test   %eax,%eax
  800a77:	7e 17                	jle    800a90 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800a79:	83 ec 0c             	sub    $0xc,%esp
  800a7c:	50                   	push   %eax
  800a7d:	6a 03                	push   $0x3
  800a7f:	68 e0 0f 80 00       	push   $0x800fe0
  800a84:	6a 23                	push   $0x23
  800a86:	68 fd 0f 80 00       	push   $0x800ffd
  800a8b:	e8 27 00 00 00       	call   800ab7 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800a90:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800a93:	5b                   	pop    %ebx
  800a94:	5e                   	pop    %esi
  800a95:	5f                   	pop    %edi
  800a96:	5d                   	pop    %ebp
  800a97:	c3                   	ret    

00800a98 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800a98:	55                   	push   %ebp
  800a99:	89 e5                	mov    %esp,%ebp
  800a9b:	57                   	push   %edi
  800a9c:	56                   	push   %esi
  800a9d:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a9e:	ba 00 00 00 00       	mov    $0x0,%edx
  800aa3:	b8 02 00 00 00       	mov    $0x2,%eax
  800aa8:	89 d1                	mov    %edx,%ecx
  800aaa:	89 d3                	mov    %edx,%ebx
  800aac:	89 d7                	mov    %edx,%edi
  800aae:	89 d6                	mov    %edx,%esi
  800ab0:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800ab2:	5b                   	pop    %ebx
  800ab3:	5e                   	pop    %esi
  800ab4:	5f                   	pop    %edi
  800ab5:	5d                   	pop    %ebp
  800ab6:	c3                   	ret    

00800ab7 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800ab7:	55                   	push   %ebp
  800ab8:	89 e5                	mov    %esp,%ebp
  800aba:	56                   	push   %esi
  800abb:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800abc:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800abf:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800ac5:	e8 ce ff ff ff       	call   800a98 <sys_getenvid>
  800aca:	83 ec 0c             	sub    $0xc,%esp
  800acd:	ff 75 0c             	pushl  0xc(%ebp)
  800ad0:	ff 75 08             	pushl  0x8(%ebp)
  800ad3:	56                   	push   %esi
  800ad4:	50                   	push   %eax
  800ad5:	68 0c 10 80 00       	push   $0x80100c
  800ada:	e8 6f f6 ff ff       	call   80014e <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800adf:	83 c4 18             	add    $0x18,%esp
  800ae2:	53                   	push   %ebx
  800ae3:	ff 75 10             	pushl  0x10(%ebp)
  800ae6:	e8 12 f6 ff ff       	call   8000fd <vcprintf>
	cprintf("\n");
  800aeb:	c7 04 24 ac 0d 80 00 	movl   $0x800dac,(%esp)
  800af2:	e8 57 f6 ff ff       	call   80014e <cprintf>
  800af7:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800afa:	cc                   	int3   
  800afb:	eb fd                	jmp    800afa <_panic+0x43>
  800afd:	66 90                	xchg   %ax,%ax
  800aff:	90                   	nop

00800b00 <__udivdi3>:
  800b00:	55                   	push   %ebp
  800b01:	57                   	push   %edi
  800b02:	56                   	push   %esi
  800b03:	53                   	push   %ebx
  800b04:	83 ec 1c             	sub    $0x1c,%esp
  800b07:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b0b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b0f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b13:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b17:	85 f6                	test   %esi,%esi
  800b19:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b1d:	89 ca                	mov    %ecx,%edx
  800b1f:	89 f8                	mov    %edi,%eax
  800b21:	75 3d                	jne    800b60 <__udivdi3+0x60>
  800b23:	39 cf                	cmp    %ecx,%edi
  800b25:	0f 87 c5 00 00 00    	ja     800bf0 <__udivdi3+0xf0>
  800b2b:	85 ff                	test   %edi,%edi
  800b2d:	89 fd                	mov    %edi,%ebp
  800b2f:	75 0b                	jne    800b3c <__udivdi3+0x3c>
  800b31:	b8 01 00 00 00       	mov    $0x1,%eax
  800b36:	31 d2                	xor    %edx,%edx
  800b38:	f7 f7                	div    %edi
  800b3a:	89 c5                	mov    %eax,%ebp
  800b3c:	89 c8                	mov    %ecx,%eax
  800b3e:	31 d2                	xor    %edx,%edx
  800b40:	f7 f5                	div    %ebp
  800b42:	89 c1                	mov    %eax,%ecx
  800b44:	89 d8                	mov    %ebx,%eax
  800b46:	89 cf                	mov    %ecx,%edi
  800b48:	f7 f5                	div    %ebp
  800b4a:	89 c3                	mov    %eax,%ebx
  800b4c:	89 d8                	mov    %ebx,%eax
  800b4e:	89 fa                	mov    %edi,%edx
  800b50:	83 c4 1c             	add    $0x1c,%esp
  800b53:	5b                   	pop    %ebx
  800b54:	5e                   	pop    %esi
  800b55:	5f                   	pop    %edi
  800b56:	5d                   	pop    %ebp
  800b57:	c3                   	ret    
  800b58:	90                   	nop
  800b59:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800b60:	39 ce                	cmp    %ecx,%esi
  800b62:	77 74                	ja     800bd8 <__udivdi3+0xd8>
  800b64:	0f bd fe             	bsr    %esi,%edi
  800b67:	83 f7 1f             	xor    $0x1f,%edi
  800b6a:	0f 84 98 00 00 00    	je     800c08 <__udivdi3+0x108>
  800b70:	bb 20 00 00 00       	mov    $0x20,%ebx
  800b75:	89 f9                	mov    %edi,%ecx
  800b77:	89 c5                	mov    %eax,%ebp
  800b79:	29 fb                	sub    %edi,%ebx
  800b7b:	d3 e6                	shl    %cl,%esi
  800b7d:	89 d9                	mov    %ebx,%ecx
  800b7f:	d3 ed                	shr    %cl,%ebp
  800b81:	89 f9                	mov    %edi,%ecx
  800b83:	d3 e0                	shl    %cl,%eax
  800b85:	09 ee                	or     %ebp,%esi
  800b87:	89 d9                	mov    %ebx,%ecx
  800b89:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800b8d:	89 d5                	mov    %edx,%ebp
  800b8f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800b93:	d3 ed                	shr    %cl,%ebp
  800b95:	89 f9                	mov    %edi,%ecx
  800b97:	d3 e2                	shl    %cl,%edx
  800b99:	89 d9                	mov    %ebx,%ecx
  800b9b:	d3 e8                	shr    %cl,%eax
  800b9d:	09 c2                	or     %eax,%edx
  800b9f:	89 d0                	mov    %edx,%eax
  800ba1:	89 ea                	mov    %ebp,%edx
  800ba3:	f7 f6                	div    %esi
  800ba5:	89 d5                	mov    %edx,%ebp
  800ba7:	89 c3                	mov    %eax,%ebx
  800ba9:	f7 64 24 0c          	mull   0xc(%esp)
  800bad:	39 d5                	cmp    %edx,%ebp
  800baf:	72 10                	jb     800bc1 <__udivdi3+0xc1>
  800bb1:	8b 74 24 08          	mov    0x8(%esp),%esi
  800bb5:	89 f9                	mov    %edi,%ecx
  800bb7:	d3 e6                	shl    %cl,%esi
  800bb9:	39 c6                	cmp    %eax,%esi
  800bbb:	73 07                	jae    800bc4 <__udivdi3+0xc4>
  800bbd:	39 d5                	cmp    %edx,%ebp
  800bbf:	75 03                	jne    800bc4 <__udivdi3+0xc4>
  800bc1:	83 eb 01             	sub    $0x1,%ebx
  800bc4:	31 ff                	xor    %edi,%edi
  800bc6:	89 d8                	mov    %ebx,%eax
  800bc8:	89 fa                	mov    %edi,%edx
  800bca:	83 c4 1c             	add    $0x1c,%esp
  800bcd:	5b                   	pop    %ebx
  800bce:	5e                   	pop    %esi
  800bcf:	5f                   	pop    %edi
  800bd0:	5d                   	pop    %ebp
  800bd1:	c3                   	ret    
  800bd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800bd8:	31 ff                	xor    %edi,%edi
  800bda:	31 db                	xor    %ebx,%ebx
  800bdc:	89 d8                	mov    %ebx,%eax
  800bde:	89 fa                	mov    %edi,%edx
  800be0:	83 c4 1c             	add    $0x1c,%esp
  800be3:	5b                   	pop    %ebx
  800be4:	5e                   	pop    %esi
  800be5:	5f                   	pop    %edi
  800be6:	5d                   	pop    %ebp
  800be7:	c3                   	ret    
  800be8:	90                   	nop
  800be9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800bf0:	89 d8                	mov    %ebx,%eax
  800bf2:	f7 f7                	div    %edi
  800bf4:	31 ff                	xor    %edi,%edi
  800bf6:	89 c3                	mov    %eax,%ebx
  800bf8:	89 d8                	mov    %ebx,%eax
  800bfa:	89 fa                	mov    %edi,%edx
  800bfc:	83 c4 1c             	add    $0x1c,%esp
  800bff:	5b                   	pop    %ebx
  800c00:	5e                   	pop    %esi
  800c01:	5f                   	pop    %edi
  800c02:	5d                   	pop    %ebp
  800c03:	c3                   	ret    
  800c04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c08:	39 ce                	cmp    %ecx,%esi
  800c0a:	72 0c                	jb     800c18 <__udivdi3+0x118>
  800c0c:	31 db                	xor    %ebx,%ebx
  800c0e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c12:	0f 87 34 ff ff ff    	ja     800b4c <__udivdi3+0x4c>
  800c18:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c1d:	e9 2a ff ff ff       	jmp    800b4c <__udivdi3+0x4c>
  800c22:	66 90                	xchg   %ax,%ax
  800c24:	66 90                	xchg   %ax,%ax
  800c26:	66 90                	xchg   %ax,%ax
  800c28:	66 90                	xchg   %ax,%ax
  800c2a:	66 90                	xchg   %ax,%ax
  800c2c:	66 90                	xchg   %ax,%ax
  800c2e:	66 90                	xchg   %ax,%ax

00800c30 <__umoddi3>:
  800c30:	55                   	push   %ebp
  800c31:	57                   	push   %edi
  800c32:	56                   	push   %esi
  800c33:	53                   	push   %ebx
  800c34:	83 ec 1c             	sub    $0x1c,%esp
  800c37:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800c3b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800c3f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800c43:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c47:	85 d2                	test   %edx,%edx
  800c49:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800c4d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800c51:	89 f3                	mov    %esi,%ebx
  800c53:	89 3c 24             	mov    %edi,(%esp)
  800c56:	89 74 24 04          	mov    %esi,0x4(%esp)
  800c5a:	75 1c                	jne    800c78 <__umoddi3+0x48>
  800c5c:	39 f7                	cmp    %esi,%edi
  800c5e:	76 50                	jbe    800cb0 <__umoddi3+0x80>
  800c60:	89 c8                	mov    %ecx,%eax
  800c62:	89 f2                	mov    %esi,%edx
  800c64:	f7 f7                	div    %edi
  800c66:	89 d0                	mov    %edx,%eax
  800c68:	31 d2                	xor    %edx,%edx
  800c6a:	83 c4 1c             	add    $0x1c,%esp
  800c6d:	5b                   	pop    %ebx
  800c6e:	5e                   	pop    %esi
  800c6f:	5f                   	pop    %edi
  800c70:	5d                   	pop    %ebp
  800c71:	c3                   	ret    
  800c72:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c78:	39 f2                	cmp    %esi,%edx
  800c7a:	89 d0                	mov    %edx,%eax
  800c7c:	77 52                	ja     800cd0 <__umoddi3+0xa0>
  800c7e:	0f bd ea             	bsr    %edx,%ebp
  800c81:	83 f5 1f             	xor    $0x1f,%ebp
  800c84:	75 5a                	jne    800ce0 <__umoddi3+0xb0>
  800c86:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800c8a:	0f 82 e0 00 00 00    	jb     800d70 <__umoddi3+0x140>
  800c90:	39 0c 24             	cmp    %ecx,(%esp)
  800c93:	0f 86 d7 00 00 00    	jbe    800d70 <__umoddi3+0x140>
  800c99:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c9d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800ca1:	83 c4 1c             	add    $0x1c,%esp
  800ca4:	5b                   	pop    %ebx
  800ca5:	5e                   	pop    %esi
  800ca6:	5f                   	pop    %edi
  800ca7:	5d                   	pop    %ebp
  800ca8:	c3                   	ret    
  800ca9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800cb0:	85 ff                	test   %edi,%edi
  800cb2:	89 fd                	mov    %edi,%ebp
  800cb4:	75 0b                	jne    800cc1 <__umoddi3+0x91>
  800cb6:	b8 01 00 00 00       	mov    $0x1,%eax
  800cbb:	31 d2                	xor    %edx,%edx
  800cbd:	f7 f7                	div    %edi
  800cbf:	89 c5                	mov    %eax,%ebp
  800cc1:	89 f0                	mov    %esi,%eax
  800cc3:	31 d2                	xor    %edx,%edx
  800cc5:	f7 f5                	div    %ebp
  800cc7:	89 c8                	mov    %ecx,%eax
  800cc9:	f7 f5                	div    %ebp
  800ccb:	89 d0                	mov    %edx,%eax
  800ccd:	eb 99                	jmp    800c68 <__umoddi3+0x38>
  800ccf:	90                   	nop
  800cd0:	89 c8                	mov    %ecx,%eax
  800cd2:	89 f2                	mov    %esi,%edx
  800cd4:	83 c4 1c             	add    $0x1c,%esp
  800cd7:	5b                   	pop    %ebx
  800cd8:	5e                   	pop    %esi
  800cd9:	5f                   	pop    %edi
  800cda:	5d                   	pop    %ebp
  800cdb:	c3                   	ret    
  800cdc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ce0:	8b 34 24             	mov    (%esp),%esi
  800ce3:	bf 20 00 00 00       	mov    $0x20,%edi
  800ce8:	89 e9                	mov    %ebp,%ecx
  800cea:	29 ef                	sub    %ebp,%edi
  800cec:	d3 e0                	shl    %cl,%eax
  800cee:	89 f9                	mov    %edi,%ecx
  800cf0:	89 f2                	mov    %esi,%edx
  800cf2:	d3 ea                	shr    %cl,%edx
  800cf4:	89 e9                	mov    %ebp,%ecx
  800cf6:	09 c2                	or     %eax,%edx
  800cf8:	89 d8                	mov    %ebx,%eax
  800cfa:	89 14 24             	mov    %edx,(%esp)
  800cfd:	89 f2                	mov    %esi,%edx
  800cff:	d3 e2                	shl    %cl,%edx
  800d01:	89 f9                	mov    %edi,%ecx
  800d03:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d07:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d0b:	d3 e8                	shr    %cl,%eax
  800d0d:	89 e9                	mov    %ebp,%ecx
  800d0f:	89 c6                	mov    %eax,%esi
  800d11:	d3 e3                	shl    %cl,%ebx
  800d13:	89 f9                	mov    %edi,%ecx
  800d15:	89 d0                	mov    %edx,%eax
  800d17:	d3 e8                	shr    %cl,%eax
  800d19:	89 e9                	mov    %ebp,%ecx
  800d1b:	09 d8                	or     %ebx,%eax
  800d1d:	89 d3                	mov    %edx,%ebx
  800d1f:	89 f2                	mov    %esi,%edx
  800d21:	f7 34 24             	divl   (%esp)
  800d24:	89 d6                	mov    %edx,%esi
  800d26:	d3 e3                	shl    %cl,%ebx
  800d28:	f7 64 24 04          	mull   0x4(%esp)
  800d2c:	39 d6                	cmp    %edx,%esi
  800d2e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d32:	89 d1                	mov    %edx,%ecx
  800d34:	89 c3                	mov    %eax,%ebx
  800d36:	72 08                	jb     800d40 <__umoddi3+0x110>
  800d38:	75 11                	jne    800d4b <__umoddi3+0x11b>
  800d3a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800d3e:	73 0b                	jae    800d4b <__umoddi3+0x11b>
  800d40:	2b 44 24 04          	sub    0x4(%esp),%eax
  800d44:	1b 14 24             	sbb    (%esp),%edx
  800d47:	89 d1                	mov    %edx,%ecx
  800d49:	89 c3                	mov    %eax,%ebx
  800d4b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800d4f:	29 da                	sub    %ebx,%edx
  800d51:	19 ce                	sbb    %ecx,%esi
  800d53:	89 f9                	mov    %edi,%ecx
  800d55:	89 f0                	mov    %esi,%eax
  800d57:	d3 e0                	shl    %cl,%eax
  800d59:	89 e9                	mov    %ebp,%ecx
  800d5b:	d3 ea                	shr    %cl,%edx
  800d5d:	89 e9                	mov    %ebp,%ecx
  800d5f:	d3 ee                	shr    %cl,%esi
  800d61:	09 d0                	or     %edx,%eax
  800d63:	89 f2                	mov    %esi,%edx
  800d65:	83 c4 1c             	add    $0x1c,%esp
  800d68:	5b                   	pop    %ebx
  800d69:	5e                   	pop    %esi
  800d6a:	5f                   	pop    %edi
  800d6b:	5d                   	pop    %ebp
  800d6c:	c3                   	ret    
  800d6d:	8d 76 00             	lea    0x0(%esi),%esi
  800d70:	29 f9                	sub    %edi,%ecx
  800d72:	19 d6                	sbb    %edx,%esi
  800d74:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d78:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d7c:	e9 18 ff ff ff       	jmp    800c99 <__umoddi3+0x69>

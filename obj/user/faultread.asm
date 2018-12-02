
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
  800044:	e8 f3 00 00 00       	call   80013c <cprintf>
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
  800051:	56                   	push   %esi
  800052:	53                   	push   %ebx
  800053:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800056:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	//thisenv = 0;
	envid_t id = sys_getenvid();
  800059:	e8 28 0a 00 00       	call   800a86 <sys_getenvid>
	thisenv = &envs[ENVX(id)];
  80005e:	25 ff 03 00 00       	and    $0x3ff,%eax
  800063:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800066:	c1 e0 05             	shl    $0x5,%eax
  800069:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80006e:	a3 04 20 80 00       	mov    %eax,0x802004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800073:	85 db                	test   %ebx,%ebx
  800075:	7e 07                	jle    80007e <libmain+0x30>
		binaryname = argv[0];
  800077:	8b 06                	mov    (%esi),%eax
  800079:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80007e:	83 ec 08             	sub    $0x8,%esp
  800081:	56                   	push   %esi
  800082:	53                   	push   %ebx
  800083:	e8 ab ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800088:	e8 0a 00 00 00       	call   800097 <exit>
}
  80008d:	83 c4 10             	add    $0x10,%esp
  800090:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800093:	5b                   	pop    %ebx
  800094:	5e                   	pop    %esi
  800095:	5d                   	pop    %ebp
  800096:	c3                   	ret    

00800097 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800097:	55                   	push   %ebp
  800098:	89 e5                	mov    %esp,%ebp
  80009a:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80009d:	6a 00                	push   $0x0
  80009f:	e8 a1 09 00 00       	call   800a45 <sys_env_destroy>
}
  8000a4:	83 c4 10             	add    $0x10,%esp
  8000a7:	c9                   	leave  
  8000a8:	c3                   	ret    

008000a9 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000a9:	55                   	push   %ebp
  8000aa:	89 e5                	mov    %esp,%ebp
  8000ac:	53                   	push   %ebx
  8000ad:	83 ec 04             	sub    $0x4,%esp
  8000b0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000b3:	8b 13                	mov    (%ebx),%edx
  8000b5:	8d 42 01             	lea    0x1(%edx),%eax
  8000b8:	89 03                	mov    %eax,(%ebx)
  8000ba:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000bd:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000c1:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000c6:	75 1a                	jne    8000e2 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000c8:	83 ec 08             	sub    $0x8,%esp
  8000cb:	68 ff 00 00 00       	push   $0xff
  8000d0:	8d 43 08             	lea    0x8(%ebx),%eax
  8000d3:	50                   	push   %eax
  8000d4:	e8 2f 09 00 00       	call   800a08 <sys_cputs>
		b->idx = 0;
  8000d9:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000df:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000e2:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000e6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000e9:	c9                   	leave  
  8000ea:	c3                   	ret    

008000eb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000eb:	55                   	push   %ebp
  8000ec:	89 e5                	mov    %esp,%ebp
  8000ee:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000f4:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000fb:	00 00 00 
	b.cnt = 0;
  8000fe:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800105:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800108:	ff 75 0c             	pushl  0xc(%ebp)
  80010b:	ff 75 08             	pushl  0x8(%ebp)
  80010e:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800114:	50                   	push   %eax
  800115:	68 a9 00 80 00       	push   $0x8000a9
  80011a:	e8 54 01 00 00       	call   800273 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80011f:	83 c4 08             	add    $0x8,%esp
  800122:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800128:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80012e:	50                   	push   %eax
  80012f:	e8 d4 08 00 00       	call   800a08 <sys_cputs>

	return b.cnt;
}
  800134:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80013a:	c9                   	leave  
  80013b:	c3                   	ret    

0080013c <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80013c:	55                   	push   %ebp
  80013d:	89 e5                	mov    %esp,%ebp
  80013f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800142:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800145:	50                   	push   %eax
  800146:	ff 75 08             	pushl  0x8(%ebp)
  800149:	e8 9d ff ff ff       	call   8000eb <vcprintf>
	va_end(ap);

	return cnt;
}
  80014e:	c9                   	leave  
  80014f:	c3                   	ret    

00800150 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800150:	55                   	push   %ebp
  800151:	89 e5                	mov    %esp,%ebp
  800153:	57                   	push   %edi
  800154:	56                   	push   %esi
  800155:	53                   	push   %ebx
  800156:	83 ec 1c             	sub    $0x1c,%esp
  800159:	89 c7                	mov    %eax,%edi
  80015b:	89 d6                	mov    %edx,%esi
  80015d:	8b 45 08             	mov    0x8(%ebp),%eax
  800160:	8b 55 0c             	mov    0xc(%ebp),%edx
  800163:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800166:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800169:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80016c:	bb 00 00 00 00       	mov    $0x0,%ebx
  800171:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800174:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800177:	39 d3                	cmp    %edx,%ebx
  800179:	72 05                	jb     800180 <printnum+0x30>
  80017b:	39 45 10             	cmp    %eax,0x10(%ebp)
  80017e:	77 45                	ja     8001c5 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800180:	83 ec 0c             	sub    $0xc,%esp
  800183:	ff 75 18             	pushl  0x18(%ebp)
  800186:	8b 45 14             	mov    0x14(%ebp),%eax
  800189:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80018c:	53                   	push   %ebx
  80018d:	ff 75 10             	pushl  0x10(%ebp)
  800190:	83 ec 08             	sub    $0x8,%esp
  800193:	ff 75 e4             	pushl  -0x1c(%ebp)
  800196:	ff 75 e0             	pushl  -0x20(%ebp)
  800199:	ff 75 dc             	pushl  -0x24(%ebp)
  80019c:	ff 75 d8             	pushl  -0x28(%ebp)
  80019f:	e8 4c 09 00 00       	call   800af0 <__udivdi3>
  8001a4:	83 c4 18             	add    $0x18,%esp
  8001a7:	52                   	push   %edx
  8001a8:	50                   	push   %eax
  8001a9:	89 f2                	mov    %esi,%edx
  8001ab:	89 f8                	mov    %edi,%eax
  8001ad:	e8 9e ff ff ff       	call   800150 <printnum>
  8001b2:	83 c4 20             	add    $0x20,%esp
  8001b5:	eb 18                	jmp    8001cf <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001b7:	83 ec 08             	sub    $0x8,%esp
  8001ba:	56                   	push   %esi
  8001bb:	ff 75 18             	pushl  0x18(%ebp)
  8001be:	ff d7                	call   *%edi
  8001c0:	83 c4 10             	add    $0x10,%esp
  8001c3:	eb 03                	jmp    8001c8 <printnum+0x78>
  8001c5:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001c8:	83 eb 01             	sub    $0x1,%ebx
  8001cb:	85 db                	test   %ebx,%ebx
  8001cd:	7f e8                	jg     8001b7 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001cf:	83 ec 08             	sub    $0x8,%esp
  8001d2:	56                   	push   %esi
  8001d3:	83 ec 04             	sub    $0x4,%esp
  8001d6:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001d9:	ff 75 e0             	pushl  -0x20(%ebp)
  8001dc:	ff 75 dc             	pushl  -0x24(%ebp)
  8001df:	ff 75 d8             	pushl  -0x28(%ebp)
  8001e2:	e8 39 0a 00 00       	call   800c20 <__umoddi3>
  8001e7:	83 c4 14             	add    $0x14,%esp
  8001ea:	0f be 80 a8 0d 80 00 	movsbl 0x800da8(%eax),%eax
  8001f1:	50                   	push   %eax
  8001f2:	ff d7                	call   *%edi
}
  8001f4:	83 c4 10             	add    $0x10,%esp
  8001f7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001fa:	5b                   	pop    %ebx
  8001fb:	5e                   	pop    %esi
  8001fc:	5f                   	pop    %edi
  8001fd:	5d                   	pop    %ebp
  8001fe:	c3                   	ret    

008001ff <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8001ff:	55                   	push   %ebp
  800200:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800202:	83 fa 01             	cmp    $0x1,%edx
  800205:	7e 0e                	jle    800215 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800207:	8b 10                	mov    (%eax),%edx
  800209:	8d 4a 08             	lea    0x8(%edx),%ecx
  80020c:	89 08                	mov    %ecx,(%eax)
  80020e:	8b 02                	mov    (%edx),%eax
  800210:	8b 52 04             	mov    0x4(%edx),%edx
  800213:	eb 22                	jmp    800237 <getuint+0x38>
	else if (lflag)
  800215:	85 d2                	test   %edx,%edx
  800217:	74 10                	je     800229 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800219:	8b 10                	mov    (%eax),%edx
  80021b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80021e:	89 08                	mov    %ecx,(%eax)
  800220:	8b 02                	mov    (%edx),%eax
  800222:	ba 00 00 00 00       	mov    $0x0,%edx
  800227:	eb 0e                	jmp    800237 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800229:	8b 10                	mov    (%eax),%edx
  80022b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80022e:	89 08                	mov    %ecx,(%eax)
  800230:	8b 02                	mov    (%edx),%eax
  800232:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800237:	5d                   	pop    %ebp
  800238:	c3                   	ret    

00800239 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800239:	55                   	push   %ebp
  80023a:	89 e5                	mov    %esp,%ebp
  80023c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80023f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800243:	8b 10                	mov    (%eax),%edx
  800245:	3b 50 04             	cmp    0x4(%eax),%edx
  800248:	73 0a                	jae    800254 <sprintputch+0x1b>
		*b->buf++ = ch;
  80024a:	8d 4a 01             	lea    0x1(%edx),%ecx
  80024d:	89 08                	mov    %ecx,(%eax)
  80024f:	8b 45 08             	mov    0x8(%ebp),%eax
  800252:	88 02                	mov    %al,(%edx)
}
  800254:	5d                   	pop    %ebp
  800255:	c3                   	ret    

00800256 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800256:	55                   	push   %ebp
  800257:	89 e5                	mov    %esp,%ebp
  800259:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80025c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80025f:	50                   	push   %eax
  800260:	ff 75 10             	pushl  0x10(%ebp)
  800263:	ff 75 0c             	pushl  0xc(%ebp)
  800266:	ff 75 08             	pushl  0x8(%ebp)
  800269:	e8 05 00 00 00       	call   800273 <vprintfmt>
	va_end(ap);
}
  80026e:	83 c4 10             	add    $0x10,%esp
  800271:	c9                   	leave  
  800272:	c3                   	ret    

00800273 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800273:	55                   	push   %ebp
  800274:	89 e5                	mov    %esp,%ebp
  800276:	57                   	push   %edi
  800277:	56                   	push   %esi
  800278:	53                   	push   %ebx
  800279:	83 ec 2c             	sub    $0x2c,%esp
  80027c:	8b 75 08             	mov    0x8(%ebp),%esi
  80027f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800282:	8b 7d 10             	mov    0x10(%ebp),%edi
  800285:	eb 12                	jmp    800299 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800287:	85 c0                	test   %eax,%eax
  800289:	0f 84 89 03 00 00    	je     800618 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  80028f:	83 ec 08             	sub    $0x8,%esp
  800292:	53                   	push   %ebx
  800293:	50                   	push   %eax
  800294:	ff d6                	call   *%esi
  800296:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800299:	83 c7 01             	add    $0x1,%edi
  80029c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8002a0:	83 f8 25             	cmp    $0x25,%eax
  8002a3:	75 e2                	jne    800287 <vprintfmt+0x14>
  8002a5:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8002a9:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8002b0:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002b7:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8002be:	ba 00 00 00 00       	mov    $0x0,%edx
  8002c3:	eb 07                	jmp    8002cc <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002c5:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8002c8:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002cc:	8d 47 01             	lea    0x1(%edi),%eax
  8002cf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8002d2:	0f b6 07             	movzbl (%edi),%eax
  8002d5:	0f b6 c8             	movzbl %al,%ecx
  8002d8:	83 e8 23             	sub    $0x23,%eax
  8002db:	3c 55                	cmp    $0x55,%al
  8002dd:	0f 87 1a 03 00 00    	ja     8005fd <vprintfmt+0x38a>
  8002e3:	0f b6 c0             	movzbl %al,%eax
  8002e6:	ff 24 85 40 0e 80 00 	jmp    *0x800e40(,%eax,4)
  8002ed:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8002f0:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8002f4:	eb d6                	jmp    8002cc <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002f6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8002f9:	b8 00 00 00 00       	mov    $0x0,%eax
  8002fe:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800301:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800304:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800308:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80030b:	8d 51 d0             	lea    -0x30(%ecx),%edx
  80030e:	83 fa 09             	cmp    $0x9,%edx
  800311:	77 39                	ja     80034c <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800313:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800316:	eb e9                	jmp    800301 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800318:	8b 45 14             	mov    0x14(%ebp),%eax
  80031b:	8d 48 04             	lea    0x4(%eax),%ecx
  80031e:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800321:	8b 00                	mov    (%eax),%eax
  800323:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800326:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800329:	eb 27                	jmp    800352 <vprintfmt+0xdf>
  80032b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80032e:	85 c0                	test   %eax,%eax
  800330:	b9 00 00 00 00       	mov    $0x0,%ecx
  800335:	0f 49 c8             	cmovns %eax,%ecx
  800338:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80033b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80033e:	eb 8c                	jmp    8002cc <vprintfmt+0x59>
  800340:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800343:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80034a:	eb 80                	jmp    8002cc <vprintfmt+0x59>
  80034c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80034f:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800352:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800356:	0f 89 70 ff ff ff    	jns    8002cc <vprintfmt+0x59>
				width = precision, precision = -1;
  80035c:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80035f:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800362:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800369:	e9 5e ff ff ff       	jmp    8002cc <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80036e:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800371:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800374:	e9 53 ff ff ff       	jmp    8002cc <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800379:	8b 45 14             	mov    0x14(%ebp),%eax
  80037c:	8d 50 04             	lea    0x4(%eax),%edx
  80037f:	89 55 14             	mov    %edx,0x14(%ebp)
  800382:	83 ec 08             	sub    $0x8,%esp
  800385:	53                   	push   %ebx
  800386:	ff 30                	pushl  (%eax)
  800388:	ff d6                	call   *%esi
			break;
  80038a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80038d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800390:	e9 04 ff ff ff       	jmp    800299 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800395:	8b 45 14             	mov    0x14(%ebp),%eax
  800398:	8d 50 04             	lea    0x4(%eax),%edx
  80039b:	89 55 14             	mov    %edx,0x14(%ebp)
  80039e:	8b 00                	mov    (%eax),%eax
  8003a0:	99                   	cltd   
  8003a1:	31 d0                	xor    %edx,%eax
  8003a3:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003a5:	83 f8 07             	cmp    $0x7,%eax
  8003a8:	7f 0b                	jg     8003b5 <vprintfmt+0x142>
  8003aa:	8b 14 85 a0 0f 80 00 	mov    0x800fa0(,%eax,4),%edx
  8003b1:	85 d2                	test   %edx,%edx
  8003b3:	75 18                	jne    8003cd <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8003b5:	50                   	push   %eax
  8003b6:	68 c0 0d 80 00       	push   $0x800dc0
  8003bb:	53                   	push   %ebx
  8003bc:	56                   	push   %esi
  8003bd:	e8 94 fe ff ff       	call   800256 <printfmt>
  8003c2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003c8:	e9 cc fe ff ff       	jmp    800299 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003cd:	52                   	push   %edx
  8003ce:	68 c9 0d 80 00       	push   $0x800dc9
  8003d3:	53                   	push   %ebx
  8003d4:	56                   	push   %esi
  8003d5:	e8 7c fe ff ff       	call   800256 <printfmt>
  8003da:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003dd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003e0:	e9 b4 fe ff ff       	jmp    800299 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8003e5:	8b 45 14             	mov    0x14(%ebp),%eax
  8003e8:	8d 50 04             	lea    0x4(%eax),%edx
  8003eb:	89 55 14             	mov    %edx,0x14(%ebp)
  8003ee:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8003f0:	85 ff                	test   %edi,%edi
  8003f2:	b8 b9 0d 80 00       	mov    $0x800db9,%eax
  8003f7:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8003fa:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8003fe:	0f 8e 94 00 00 00    	jle    800498 <vprintfmt+0x225>
  800404:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800408:	0f 84 98 00 00 00    	je     8004a6 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  80040e:	83 ec 08             	sub    $0x8,%esp
  800411:	ff 75 d0             	pushl  -0x30(%ebp)
  800414:	57                   	push   %edi
  800415:	e8 86 02 00 00       	call   8006a0 <strnlen>
  80041a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80041d:	29 c1                	sub    %eax,%ecx
  80041f:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800422:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800425:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800429:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80042c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80042f:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800431:	eb 0f                	jmp    800442 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800433:	83 ec 08             	sub    $0x8,%esp
  800436:	53                   	push   %ebx
  800437:	ff 75 e0             	pushl  -0x20(%ebp)
  80043a:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80043c:	83 ef 01             	sub    $0x1,%edi
  80043f:	83 c4 10             	add    $0x10,%esp
  800442:	85 ff                	test   %edi,%edi
  800444:	7f ed                	jg     800433 <vprintfmt+0x1c0>
  800446:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800449:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80044c:	85 c9                	test   %ecx,%ecx
  80044e:	b8 00 00 00 00       	mov    $0x0,%eax
  800453:	0f 49 c1             	cmovns %ecx,%eax
  800456:	29 c1                	sub    %eax,%ecx
  800458:	89 75 08             	mov    %esi,0x8(%ebp)
  80045b:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80045e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800461:	89 cb                	mov    %ecx,%ebx
  800463:	eb 4d                	jmp    8004b2 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800465:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800469:	74 1b                	je     800486 <vprintfmt+0x213>
  80046b:	0f be c0             	movsbl %al,%eax
  80046e:	83 e8 20             	sub    $0x20,%eax
  800471:	83 f8 5e             	cmp    $0x5e,%eax
  800474:	76 10                	jbe    800486 <vprintfmt+0x213>
					putch('?', putdat);
  800476:	83 ec 08             	sub    $0x8,%esp
  800479:	ff 75 0c             	pushl  0xc(%ebp)
  80047c:	6a 3f                	push   $0x3f
  80047e:	ff 55 08             	call   *0x8(%ebp)
  800481:	83 c4 10             	add    $0x10,%esp
  800484:	eb 0d                	jmp    800493 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800486:	83 ec 08             	sub    $0x8,%esp
  800489:	ff 75 0c             	pushl  0xc(%ebp)
  80048c:	52                   	push   %edx
  80048d:	ff 55 08             	call   *0x8(%ebp)
  800490:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800493:	83 eb 01             	sub    $0x1,%ebx
  800496:	eb 1a                	jmp    8004b2 <vprintfmt+0x23f>
  800498:	89 75 08             	mov    %esi,0x8(%ebp)
  80049b:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80049e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004a1:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004a4:	eb 0c                	jmp    8004b2 <vprintfmt+0x23f>
  8004a6:	89 75 08             	mov    %esi,0x8(%ebp)
  8004a9:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004ac:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004af:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004b2:	83 c7 01             	add    $0x1,%edi
  8004b5:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004b9:	0f be d0             	movsbl %al,%edx
  8004bc:	85 d2                	test   %edx,%edx
  8004be:	74 23                	je     8004e3 <vprintfmt+0x270>
  8004c0:	85 f6                	test   %esi,%esi
  8004c2:	78 a1                	js     800465 <vprintfmt+0x1f2>
  8004c4:	83 ee 01             	sub    $0x1,%esi
  8004c7:	79 9c                	jns    800465 <vprintfmt+0x1f2>
  8004c9:	89 df                	mov    %ebx,%edi
  8004cb:	8b 75 08             	mov    0x8(%ebp),%esi
  8004ce:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004d1:	eb 18                	jmp    8004eb <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8004d3:	83 ec 08             	sub    $0x8,%esp
  8004d6:	53                   	push   %ebx
  8004d7:	6a 20                	push   $0x20
  8004d9:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8004db:	83 ef 01             	sub    $0x1,%edi
  8004de:	83 c4 10             	add    $0x10,%esp
  8004e1:	eb 08                	jmp    8004eb <vprintfmt+0x278>
  8004e3:	89 df                	mov    %ebx,%edi
  8004e5:	8b 75 08             	mov    0x8(%ebp),%esi
  8004e8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8004eb:	85 ff                	test   %edi,%edi
  8004ed:	7f e4                	jg     8004d3 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004f2:	e9 a2 fd ff ff       	jmp    800299 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8004f7:	83 fa 01             	cmp    $0x1,%edx
  8004fa:	7e 16                	jle    800512 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  8004fc:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ff:	8d 50 08             	lea    0x8(%eax),%edx
  800502:	89 55 14             	mov    %edx,0x14(%ebp)
  800505:	8b 50 04             	mov    0x4(%eax),%edx
  800508:	8b 00                	mov    (%eax),%eax
  80050a:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80050d:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800510:	eb 32                	jmp    800544 <vprintfmt+0x2d1>
	else if (lflag)
  800512:	85 d2                	test   %edx,%edx
  800514:	74 18                	je     80052e <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  800516:	8b 45 14             	mov    0x14(%ebp),%eax
  800519:	8d 50 04             	lea    0x4(%eax),%edx
  80051c:	89 55 14             	mov    %edx,0x14(%ebp)
  80051f:	8b 00                	mov    (%eax),%eax
  800521:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800524:	89 c1                	mov    %eax,%ecx
  800526:	c1 f9 1f             	sar    $0x1f,%ecx
  800529:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80052c:	eb 16                	jmp    800544 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  80052e:	8b 45 14             	mov    0x14(%ebp),%eax
  800531:	8d 50 04             	lea    0x4(%eax),%edx
  800534:	89 55 14             	mov    %edx,0x14(%ebp)
  800537:	8b 00                	mov    (%eax),%eax
  800539:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80053c:	89 c1                	mov    %eax,%ecx
  80053e:	c1 f9 1f             	sar    $0x1f,%ecx
  800541:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800544:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800547:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80054a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80054f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800553:	79 74                	jns    8005c9 <vprintfmt+0x356>
				putch('-', putdat);
  800555:	83 ec 08             	sub    $0x8,%esp
  800558:	53                   	push   %ebx
  800559:	6a 2d                	push   $0x2d
  80055b:	ff d6                	call   *%esi
				num = -(long long) num;
  80055d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800560:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800563:	f7 d8                	neg    %eax
  800565:	83 d2 00             	adc    $0x0,%edx
  800568:	f7 da                	neg    %edx
  80056a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80056d:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800572:	eb 55                	jmp    8005c9 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800574:	8d 45 14             	lea    0x14(%ebp),%eax
  800577:	e8 83 fc ff ff       	call   8001ff <getuint>
			base = 10;
  80057c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800581:	eb 46                	jmp    8005c9 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800583:	8d 45 14             	lea    0x14(%ebp),%eax
  800586:	e8 74 fc ff ff       	call   8001ff <getuint>
			base = 8;
  80058b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800590:	eb 37                	jmp    8005c9 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  800592:	83 ec 08             	sub    $0x8,%esp
  800595:	53                   	push   %ebx
  800596:	6a 30                	push   $0x30
  800598:	ff d6                	call   *%esi
			putch('x', putdat);
  80059a:	83 c4 08             	add    $0x8,%esp
  80059d:	53                   	push   %ebx
  80059e:	6a 78                	push   $0x78
  8005a0:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8005a2:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a5:	8d 50 04             	lea    0x4(%eax),%edx
  8005a8:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8005ab:	8b 00                	mov    (%eax),%eax
  8005ad:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  8005b2:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8005b5:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8005ba:	eb 0d                	jmp    8005c9 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8005bc:	8d 45 14             	lea    0x14(%ebp),%eax
  8005bf:	e8 3b fc ff ff       	call   8001ff <getuint>
			base = 16;
  8005c4:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8005c9:	83 ec 0c             	sub    $0xc,%esp
  8005cc:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8005d0:	57                   	push   %edi
  8005d1:	ff 75 e0             	pushl  -0x20(%ebp)
  8005d4:	51                   	push   %ecx
  8005d5:	52                   	push   %edx
  8005d6:	50                   	push   %eax
  8005d7:	89 da                	mov    %ebx,%edx
  8005d9:	89 f0                	mov    %esi,%eax
  8005db:	e8 70 fb ff ff       	call   800150 <printnum>
			break;
  8005e0:	83 c4 20             	add    $0x20,%esp
  8005e3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005e6:	e9 ae fc ff ff       	jmp    800299 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8005eb:	83 ec 08             	sub    $0x8,%esp
  8005ee:	53                   	push   %ebx
  8005ef:	51                   	push   %ecx
  8005f0:	ff d6                	call   *%esi
			break;
  8005f2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005f5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8005f8:	e9 9c fc ff ff       	jmp    800299 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8005fd:	83 ec 08             	sub    $0x8,%esp
  800600:	53                   	push   %ebx
  800601:	6a 25                	push   $0x25
  800603:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800605:	83 c4 10             	add    $0x10,%esp
  800608:	eb 03                	jmp    80060d <vprintfmt+0x39a>
  80060a:	83 ef 01             	sub    $0x1,%edi
  80060d:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800611:	75 f7                	jne    80060a <vprintfmt+0x397>
  800613:	e9 81 fc ff ff       	jmp    800299 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800618:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80061b:	5b                   	pop    %ebx
  80061c:	5e                   	pop    %esi
  80061d:	5f                   	pop    %edi
  80061e:	5d                   	pop    %ebp
  80061f:	c3                   	ret    

00800620 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800620:	55                   	push   %ebp
  800621:	89 e5                	mov    %esp,%ebp
  800623:	83 ec 18             	sub    $0x18,%esp
  800626:	8b 45 08             	mov    0x8(%ebp),%eax
  800629:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80062c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80062f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800633:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800636:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80063d:	85 c0                	test   %eax,%eax
  80063f:	74 26                	je     800667 <vsnprintf+0x47>
  800641:	85 d2                	test   %edx,%edx
  800643:	7e 22                	jle    800667 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800645:	ff 75 14             	pushl  0x14(%ebp)
  800648:	ff 75 10             	pushl  0x10(%ebp)
  80064b:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80064e:	50                   	push   %eax
  80064f:	68 39 02 80 00       	push   $0x800239
  800654:	e8 1a fc ff ff       	call   800273 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800659:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80065c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80065f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800662:	83 c4 10             	add    $0x10,%esp
  800665:	eb 05                	jmp    80066c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800667:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80066c:	c9                   	leave  
  80066d:	c3                   	ret    

0080066e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80066e:	55                   	push   %ebp
  80066f:	89 e5                	mov    %esp,%ebp
  800671:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800674:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800677:	50                   	push   %eax
  800678:	ff 75 10             	pushl  0x10(%ebp)
  80067b:	ff 75 0c             	pushl  0xc(%ebp)
  80067e:	ff 75 08             	pushl  0x8(%ebp)
  800681:	e8 9a ff ff ff       	call   800620 <vsnprintf>
	va_end(ap);

	return rc;
}
  800686:	c9                   	leave  
  800687:	c3                   	ret    

00800688 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800688:	55                   	push   %ebp
  800689:	89 e5                	mov    %esp,%ebp
  80068b:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80068e:	b8 00 00 00 00       	mov    $0x0,%eax
  800693:	eb 03                	jmp    800698 <strlen+0x10>
		n++;
  800695:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800698:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80069c:	75 f7                	jne    800695 <strlen+0xd>
		n++;
	return n;
}
  80069e:	5d                   	pop    %ebp
  80069f:	c3                   	ret    

008006a0 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8006a0:	55                   	push   %ebp
  8006a1:	89 e5                	mov    %esp,%ebp
  8006a3:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8006a6:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006a9:	ba 00 00 00 00       	mov    $0x0,%edx
  8006ae:	eb 03                	jmp    8006b3 <strnlen+0x13>
		n++;
  8006b0:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8006b3:	39 c2                	cmp    %eax,%edx
  8006b5:	74 08                	je     8006bf <strnlen+0x1f>
  8006b7:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8006bb:	75 f3                	jne    8006b0 <strnlen+0x10>
  8006bd:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8006bf:	5d                   	pop    %ebp
  8006c0:	c3                   	ret    

008006c1 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8006c1:	55                   	push   %ebp
  8006c2:	89 e5                	mov    %esp,%ebp
  8006c4:	53                   	push   %ebx
  8006c5:	8b 45 08             	mov    0x8(%ebp),%eax
  8006c8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8006cb:	89 c2                	mov    %eax,%edx
  8006cd:	83 c2 01             	add    $0x1,%edx
  8006d0:	83 c1 01             	add    $0x1,%ecx
  8006d3:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8006d7:	88 5a ff             	mov    %bl,-0x1(%edx)
  8006da:	84 db                	test   %bl,%bl
  8006dc:	75 ef                	jne    8006cd <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8006de:	5b                   	pop    %ebx
  8006df:	5d                   	pop    %ebp
  8006e0:	c3                   	ret    

008006e1 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8006e1:	55                   	push   %ebp
  8006e2:	89 e5                	mov    %esp,%ebp
  8006e4:	53                   	push   %ebx
  8006e5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8006e8:	53                   	push   %ebx
  8006e9:	e8 9a ff ff ff       	call   800688 <strlen>
  8006ee:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8006f1:	ff 75 0c             	pushl  0xc(%ebp)
  8006f4:	01 d8                	add    %ebx,%eax
  8006f6:	50                   	push   %eax
  8006f7:	e8 c5 ff ff ff       	call   8006c1 <strcpy>
	return dst;
}
  8006fc:	89 d8                	mov    %ebx,%eax
  8006fe:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800701:	c9                   	leave  
  800702:	c3                   	ret    

00800703 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800703:	55                   	push   %ebp
  800704:	89 e5                	mov    %esp,%ebp
  800706:	56                   	push   %esi
  800707:	53                   	push   %ebx
  800708:	8b 75 08             	mov    0x8(%ebp),%esi
  80070b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80070e:	89 f3                	mov    %esi,%ebx
  800710:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800713:	89 f2                	mov    %esi,%edx
  800715:	eb 0f                	jmp    800726 <strncpy+0x23>
		*dst++ = *src;
  800717:	83 c2 01             	add    $0x1,%edx
  80071a:	0f b6 01             	movzbl (%ecx),%eax
  80071d:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800720:	80 39 01             	cmpb   $0x1,(%ecx)
  800723:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800726:	39 da                	cmp    %ebx,%edx
  800728:	75 ed                	jne    800717 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80072a:	89 f0                	mov    %esi,%eax
  80072c:	5b                   	pop    %ebx
  80072d:	5e                   	pop    %esi
  80072e:	5d                   	pop    %ebp
  80072f:	c3                   	ret    

00800730 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800730:	55                   	push   %ebp
  800731:	89 e5                	mov    %esp,%ebp
  800733:	56                   	push   %esi
  800734:	53                   	push   %ebx
  800735:	8b 75 08             	mov    0x8(%ebp),%esi
  800738:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80073b:	8b 55 10             	mov    0x10(%ebp),%edx
  80073e:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800740:	85 d2                	test   %edx,%edx
  800742:	74 21                	je     800765 <strlcpy+0x35>
  800744:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800748:	89 f2                	mov    %esi,%edx
  80074a:	eb 09                	jmp    800755 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80074c:	83 c2 01             	add    $0x1,%edx
  80074f:	83 c1 01             	add    $0x1,%ecx
  800752:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800755:	39 c2                	cmp    %eax,%edx
  800757:	74 09                	je     800762 <strlcpy+0x32>
  800759:	0f b6 19             	movzbl (%ecx),%ebx
  80075c:	84 db                	test   %bl,%bl
  80075e:	75 ec                	jne    80074c <strlcpy+0x1c>
  800760:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800762:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800765:	29 f0                	sub    %esi,%eax
}
  800767:	5b                   	pop    %ebx
  800768:	5e                   	pop    %esi
  800769:	5d                   	pop    %ebp
  80076a:	c3                   	ret    

0080076b <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80076b:	55                   	push   %ebp
  80076c:	89 e5                	mov    %esp,%ebp
  80076e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800771:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800774:	eb 06                	jmp    80077c <strcmp+0x11>
		p++, q++;
  800776:	83 c1 01             	add    $0x1,%ecx
  800779:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80077c:	0f b6 01             	movzbl (%ecx),%eax
  80077f:	84 c0                	test   %al,%al
  800781:	74 04                	je     800787 <strcmp+0x1c>
  800783:	3a 02                	cmp    (%edx),%al
  800785:	74 ef                	je     800776 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800787:	0f b6 c0             	movzbl %al,%eax
  80078a:	0f b6 12             	movzbl (%edx),%edx
  80078d:	29 d0                	sub    %edx,%eax
}
  80078f:	5d                   	pop    %ebp
  800790:	c3                   	ret    

00800791 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800791:	55                   	push   %ebp
  800792:	89 e5                	mov    %esp,%ebp
  800794:	53                   	push   %ebx
  800795:	8b 45 08             	mov    0x8(%ebp),%eax
  800798:	8b 55 0c             	mov    0xc(%ebp),%edx
  80079b:	89 c3                	mov    %eax,%ebx
  80079d:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8007a0:	eb 06                	jmp    8007a8 <strncmp+0x17>
		n--, p++, q++;
  8007a2:	83 c0 01             	add    $0x1,%eax
  8007a5:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8007a8:	39 d8                	cmp    %ebx,%eax
  8007aa:	74 15                	je     8007c1 <strncmp+0x30>
  8007ac:	0f b6 08             	movzbl (%eax),%ecx
  8007af:	84 c9                	test   %cl,%cl
  8007b1:	74 04                	je     8007b7 <strncmp+0x26>
  8007b3:	3a 0a                	cmp    (%edx),%cl
  8007b5:	74 eb                	je     8007a2 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8007b7:	0f b6 00             	movzbl (%eax),%eax
  8007ba:	0f b6 12             	movzbl (%edx),%edx
  8007bd:	29 d0                	sub    %edx,%eax
  8007bf:	eb 05                	jmp    8007c6 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8007c1:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8007c6:	5b                   	pop    %ebx
  8007c7:	5d                   	pop    %ebp
  8007c8:	c3                   	ret    

008007c9 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8007c9:	55                   	push   %ebp
  8007ca:	89 e5                	mov    %esp,%ebp
  8007cc:	8b 45 08             	mov    0x8(%ebp),%eax
  8007cf:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007d3:	eb 07                	jmp    8007dc <strchr+0x13>
		if (*s == c)
  8007d5:	38 ca                	cmp    %cl,%dl
  8007d7:	74 0f                	je     8007e8 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8007d9:	83 c0 01             	add    $0x1,%eax
  8007dc:	0f b6 10             	movzbl (%eax),%edx
  8007df:	84 d2                	test   %dl,%dl
  8007e1:	75 f2                	jne    8007d5 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8007e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8007e8:	5d                   	pop    %ebp
  8007e9:	c3                   	ret    

008007ea <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8007ea:	55                   	push   %ebp
  8007eb:	89 e5                	mov    %esp,%ebp
  8007ed:	8b 45 08             	mov    0x8(%ebp),%eax
  8007f0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007f4:	eb 03                	jmp    8007f9 <strfind+0xf>
  8007f6:	83 c0 01             	add    $0x1,%eax
  8007f9:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8007fc:	38 ca                	cmp    %cl,%dl
  8007fe:	74 04                	je     800804 <strfind+0x1a>
  800800:	84 d2                	test   %dl,%dl
  800802:	75 f2                	jne    8007f6 <strfind+0xc>
			break;
	return (char *) s;
}
  800804:	5d                   	pop    %ebp
  800805:	c3                   	ret    

00800806 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800806:	55                   	push   %ebp
  800807:	89 e5                	mov    %esp,%ebp
  800809:	57                   	push   %edi
  80080a:	56                   	push   %esi
  80080b:	53                   	push   %ebx
  80080c:	8b 7d 08             	mov    0x8(%ebp),%edi
  80080f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800812:	85 c9                	test   %ecx,%ecx
  800814:	74 36                	je     80084c <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800816:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80081c:	75 28                	jne    800846 <memset+0x40>
  80081e:	f6 c1 03             	test   $0x3,%cl
  800821:	75 23                	jne    800846 <memset+0x40>
		c &= 0xFF;
  800823:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800827:	89 d3                	mov    %edx,%ebx
  800829:	c1 e3 08             	shl    $0x8,%ebx
  80082c:	89 d6                	mov    %edx,%esi
  80082e:	c1 e6 18             	shl    $0x18,%esi
  800831:	89 d0                	mov    %edx,%eax
  800833:	c1 e0 10             	shl    $0x10,%eax
  800836:	09 f0                	or     %esi,%eax
  800838:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  80083a:	89 d8                	mov    %ebx,%eax
  80083c:	09 d0                	or     %edx,%eax
  80083e:	c1 e9 02             	shr    $0x2,%ecx
  800841:	fc                   	cld    
  800842:	f3 ab                	rep stos %eax,%es:(%edi)
  800844:	eb 06                	jmp    80084c <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800846:	8b 45 0c             	mov    0xc(%ebp),%eax
  800849:	fc                   	cld    
  80084a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80084c:	89 f8                	mov    %edi,%eax
  80084e:	5b                   	pop    %ebx
  80084f:	5e                   	pop    %esi
  800850:	5f                   	pop    %edi
  800851:	5d                   	pop    %ebp
  800852:	c3                   	ret    

00800853 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800853:	55                   	push   %ebp
  800854:	89 e5                	mov    %esp,%ebp
  800856:	57                   	push   %edi
  800857:	56                   	push   %esi
  800858:	8b 45 08             	mov    0x8(%ebp),%eax
  80085b:	8b 75 0c             	mov    0xc(%ebp),%esi
  80085e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800861:	39 c6                	cmp    %eax,%esi
  800863:	73 35                	jae    80089a <memmove+0x47>
  800865:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800868:	39 d0                	cmp    %edx,%eax
  80086a:	73 2e                	jae    80089a <memmove+0x47>
		s += n;
		d += n;
  80086c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80086f:	89 d6                	mov    %edx,%esi
  800871:	09 fe                	or     %edi,%esi
  800873:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800879:	75 13                	jne    80088e <memmove+0x3b>
  80087b:	f6 c1 03             	test   $0x3,%cl
  80087e:	75 0e                	jne    80088e <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800880:	83 ef 04             	sub    $0x4,%edi
  800883:	8d 72 fc             	lea    -0x4(%edx),%esi
  800886:	c1 e9 02             	shr    $0x2,%ecx
  800889:	fd                   	std    
  80088a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80088c:	eb 09                	jmp    800897 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80088e:	83 ef 01             	sub    $0x1,%edi
  800891:	8d 72 ff             	lea    -0x1(%edx),%esi
  800894:	fd                   	std    
  800895:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800897:	fc                   	cld    
  800898:	eb 1d                	jmp    8008b7 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80089a:	89 f2                	mov    %esi,%edx
  80089c:	09 c2                	or     %eax,%edx
  80089e:	f6 c2 03             	test   $0x3,%dl
  8008a1:	75 0f                	jne    8008b2 <memmove+0x5f>
  8008a3:	f6 c1 03             	test   $0x3,%cl
  8008a6:	75 0a                	jne    8008b2 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  8008a8:	c1 e9 02             	shr    $0x2,%ecx
  8008ab:	89 c7                	mov    %eax,%edi
  8008ad:	fc                   	cld    
  8008ae:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8008b0:	eb 05                	jmp    8008b7 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8008b2:	89 c7                	mov    %eax,%edi
  8008b4:	fc                   	cld    
  8008b5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8008b7:	5e                   	pop    %esi
  8008b8:	5f                   	pop    %edi
  8008b9:	5d                   	pop    %ebp
  8008ba:	c3                   	ret    

008008bb <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8008bb:	55                   	push   %ebp
  8008bc:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8008be:	ff 75 10             	pushl  0x10(%ebp)
  8008c1:	ff 75 0c             	pushl  0xc(%ebp)
  8008c4:	ff 75 08             	pushl  0x8(%ebp)
  8008c7:	e8 87 ff ff ff       	call   800853 <memmove>
}
  8008cc:	c9                   	leave  
  8008cd:	c3                   	ret    

008008ce <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8008ce:	55                   	push   %ebp
  8008cf:	89 e5                	mov    %esp,%ebp
  8008d1:	56                   	push   %esi
  8008d2:	53                   	push   %ebx
  8008d3:	8b 45 08             	mov    0x8(%ebp),%eax
  8008d6:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008d9:	89 c6                	mov    %eax,%esi
  8008db:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008de:	eb 1a                	jmp    8008fa <memcmp+0x2c>
		if (*s1 != *s2)
  8008e0:	0f b6 08             	movzbl (%eax),%ecx
  8008e3:	0f b6 1a             	movzbl (%edx),%ebx
  8008e6:	38 d9                	cmp    %bl,%cl
  8008e8:	74 0a                	je     8008f4 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8008ea:	0f b6 c1             	movzbl %cl,%eax
  8008ed:	0f b6 db             	movzbl %bl,%ebx
  8008f0:	29 d8                	sub    %ebx,%eax
  8008f2:	eb 0f                	jmp    800903 <memcmp+0x35>
		s1++, s2++;
  8008f4:	83 c0 01             	add    $0x1,%eax
  8008f7:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008fa:	39 f0                	cmp    %esi,%eax
  8008fc:	75 e2                	jne    8008e0 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8008fe:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800903:	5b                   	pop    %ebx
  800904:	5e                   	pop    %esi
  800905:	5d                   	pop    %ebp
  800906:	c3                   	ret    

00800907 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800907:	55                   	push   %ebp
  800908:	89 e5                	mov    %esp,%ebp
  80090a:	53                   	push   %ebx
  80090b:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  80090e:	89 c1                	mov    %eax,%ecx
  800910:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800913:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800917:	eb 0a                	jmp    800923 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800919:	0f b6 10             	movzbl (%eax),%edx
  80091c:	39 da                	cmp    %ebx,%edx
  80091e:	74 07                	je     800927 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800920:	83 c0 01             	add    $0x1,%eax
  800923:	39 c8                	cmp    %ecx,%eax
  800925:	72 f2                	jb     800919 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800927:	5b                   	pop    %ebx
  800928:	5d                   	pop    %ebp
  800929:	c3                   	ret    

0080092a <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  80092a:	55                   	push   %ebp
  80092b:	89 e5                	mov    %esp,%ebp
  80092d:	57                   	push   %edi
  80092e:	56                   	push   %esi
  80092f:	53                   	push   %ebx
  800930:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800933:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800936:	eb 03                	jmp    80093b <strtol+0x11>
		s++;
  800938:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  80093b:	0f b6 01             	movzbl (%ecx),%eax
  80093e:	3c 20                	cmp    $0x20,%al
  800940:	74 f6                	je     800938 <strtol+0xe>
  800942:	3c 09                	cmp    $0x9,%al
  800944:	74 f2                	je     800938 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800946:	3c 2b                	cmp    $0x2b,%al
  800948:	75 0a                	jne    800954 <strtol+0x2a>
		s++;
  80094a:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  80094d:	bf 00 00 00 00       	mov    $0x0,%edi
  800952:	eb 11                	jmp    800965 <strtol+0x3b>
  800954:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800959:	3c 2d                	cmp    $0x2d,%al
  80095b:	75 08                	jne    800965 <strtol+0x3b>
		s++, neg = 1;
  80095d:	83 c1 01             	add    $0x1,%ecx
  800960:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800965:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  80096b:	75 15                	jne    800982 <strtol+0x58>
  80096d:	80 39 30             	cmpb   $0x30,(%ecx)
  800970:	75 10                	jne    800982 <strtol+0x58>
  800972:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800976:	75 7c                	jne    8009f4 <strtol+0xca>
		s += 2, base = 16;
  800978:	83 c1 02             	add    $0x2,%ecx
  80097b:	bb 10 00 00 00       	mov    $0x10,%ebx
  800980:	eb 16                	jmp    800998 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800982:	85 db                	test   %ebx,%ebx
  800984:	75 12                	jne    800998 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800986:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  80098b:	80 39 30             	cmpb   $0x30,(%ecx)
  80098e:	75 08                	jne    800998 <strtol+0x6e>
		s++, base = 8;
  800990:	83 c1 01             	add    $0x1,%ecx
  800993:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800998:	b8 00 00 00 00       	mov    $0x0,%eax
  80099d:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  8009a0:	0f b6 11             	movzbl (%ecx),%edx
  8009a3:	8d 72 d0             	lea    -0x30(%edx),%esi
  8009a6:	89 f3                	mov    %esi,%ebx
  8009a8:	80 fb 09             	cmp    $0x9,%bl
  8009ab:	77 08                	ja     8009b5 <strtol+0x8b>
			dig = *s - '0';
  8009ad:	0f be d2             	movsbl %dl,%edx
  8009b0:	83 ea 30             	sub    $0x30,%edx
  8009b3:	eb 22                	jmp    8009d7 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  8009b5:	8d 72 9f             	lea    -0x61(%edx),%esi
  8009b8:	89 f3                	mov    %esi,%ebx
  8009ba:	80 fb 19             	cmp    $0x19,%bl
  8009bd:	77 08                	ja     8009c7 <strtol+0x9d>
			dig = *s - 'a' + 10;
  8009bf:	0f be d2             	movsbl %dl,%edx
  8009c2:	83 ea 57             	sub    $0x57,%edx
  8009c5:	eb 10                	jmp    8009d7 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  8009c7:	8d 72 bf             	lea    -0x41(%edx),%esi
  8009ca:	89 f3                	mov    %esi,%ebx
  8009cc:	80 fb 19             	cmp    $0x19,%bl
  8009cf:	77 16                	ja     8009e7 <strtol+0xbd>
			dig = *s - 'A' + 10;
  8009d1:	0f be d2             	movsbl %dl,%edx
  8009d4:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  8009d7:	3b 55 10             	cmp    0x10(%ebp),%edx
  8009da:	7d 0b                	jge    8009e7 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  8009dc:	83 c1 01             	add    $0x1,%ecx
  8009df:	0f af 45 10          	imul   0x10(%ebp),%eax
  8009e3:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  8009e5:	eb b9                	jmp    8009a0 <strtol+0x76>

	if (endptr)
  8009e7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8009eb:	74 0d                	je     8009fa <strtol+0xd0>
		*endptr = (char *) s;
  8009ed:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009f0:	89 0e                	mov    %ecx,(%esi)
  8009f2:	eb 06                	jmp    8009fa <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  8009f4:	85 db                	test   %ebx,%ebx
  8009f6:	74 98                	je     800990 <strtol+0x66>
  8009f8:	eb 9e                	jmp    800998 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  8009fa:	89 c2                	mov    %eax,%edx
  8009fc:	f7 da                	neg    %edx
  8009fe:	85 ff                	test   %edi,%edi
  800a00:	0f 45 c2             	cmovne %edx,%eax
}
  800a03:	5b                   	pop    %ebx
  800a04:	5e                   	pop    %esi
  800a05:	5f                   	pop    %edi
  800a06:	5d                   	pop    %ebp
  800a07:	c3                   	ret    

00800a08 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800a08:	55                   	push   %ebp
  800a09:	89 e5                	mov    %esp,%ebp
  800a0b:	57                   	push   %edi
  800a0c:	56                   	push   %esi
  800a0d:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a0e:	b8 00 00 00 00       	mov    $0x0,%eax
  800a13:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a16:	8b 55 08             	mov    0x8(%ebp),%edx
  800a19:	89 c3                	mov    %eax,%ebx
  800a1b:	89 c7                	mov    %eax,%edi
  800a1d:	89 c6                	mov    %eax,%esi
  800a1f:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800a21:	5b                   	pop    %ebx
  800a22:	5e                   	pop    %esi
  800a23:	5f                   	pop    %edi
  800a24:	5d                   	pop    %ebp
  800a25:	c3                   	ret    

00800a26 <sys_cgetc>:

int
sys_cgetc(void)
{
  800a26:	55                   	push   %ebp
  800a27:	89 e5                	mov    %esp,%ebp
  800a29:	57                   	push   %edi
  800a2a:	56                   	push   %esi
  800a2b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a2c:	ba 00 00 00 00       	mov    $0x0,%edx
  800a31:	b8 01 00 00 00       	mov    $0x1,%eax
  800a36:	89 d1                	mov    %edx,%ecx
  800a38:	89 d3                	mov    %edx,%ebx
  800a3a:	89 d7                	mov    %edx,%edi
  800a3c:	89 d6                	mov    %edx,%esi
  800a3e:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800a40:	5b                   	pop    %ebx
  800a41:	5e                   	pop    %esi
  800a42:	5f                   	pop    %edi
  800a43:	5d                   	pop    %ebp
  800a44:	c3                   	ret    

00800a45 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800a45:	55                   	push   %ebp
  800a46:	89 e5                	mov    %esp,%ebp
  800a48:	57                   	push   %edi
  800a49:	56                   	push   %esi
  800a4a:	53                   	push   %ebx
  800a4b:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a4e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800a53:	b8 03 00 00 00       	mov    $0x3,%eax
  800a58:	8b 55 08             	mov    0x8(%ebp),%edx
  800a5b:	89 cb                	mov    %ecx,%ebx
  800a5d:	89 cf                	mov    %ecx,%edi
  800a5f:	89 ce                	mov    %ecx,%esi
  800a61:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800a63:	85 c0                	test   %eax,%eax
  800a65:	7e 17                	jle    800a7e <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800a67:	83 ec 0c             	sub    $0xc,%esp
  800a6a:	50                   	push   %eax
  800a6b:	6a 03                	push   $0x3
  800a6d:	68 c0 0f 80 00       	push   $0x800fc0
  800a72:	6a 23                	push   $0x23
  800a74:	68 dd 0f 80 00       	push   $0x800fdd
  800a79:	e8 27 00 00 00       	call   800aa5 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800a7e:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800a81:	5b                   	pop    %ebx
  800a82:	5e                   	pop    %esi
  800a83:	5f                   	pop    %edi
  800a84:	5d                   	pop    %ebp
  800a85:	c3                   	ret    

00800a86 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800a86:	55                   	push   %ebp
  800a87:	89 e5                	mov    %esp,%ebp
  800a89:	57                   	push   %edi
  800a8a:	56                   	push   %esi
  800a8b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a8c:	ba 00 00 00 00       	mov    $0x0,%edx
  800a91:	b8 02 00 00 00       	mov    $0x2,%eax
  800a96:	89 d1                	mov    %edx,%ecx
  800a98:	89 d3                	mov    %edx,%ebx
  800a9a:	89 d7                	mov    %edx,%edi
  800a9c:	89 d6                	mov    %edx,%esi
  800a9e:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800aa0:	5b                   	pop    %ebx
  800aa1:	5e                   	pop    %esi
  800aa2:	5f                   	pop    %edi
  800aa3:	5d                   	pop    %ebp
  800aa4:	c3                   	ret    

00800aa5 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800aa5:	55                   	push   %ebp
  800aa6:	89 e5                	mov    %esp,%ebp
  800aa8:	56                   	push   %esi
  800aa9:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800aaa:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800aad:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800ab3:	e8 ce ff ff ff       	call   800a86 <sys_getenvid>
  800ab8:	83 ec 0c             	sub    $0xc,%esp
  800abb:	ff 75 0c             	pushl  0xc(%ebp)
  800abe:	ff 75 08             	pushl  0x8(%ebp)
  800ac1:	56                   	push   %esi
  800ac2:	50                   	push   %eax
  800ac3:	68 ec 0f 80 00       	push   $0x800fec
  800ac8:	e8 6f f6 ff ff       	call   80013c <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800acd:	83 c4 18             	add    $0x18,%esp
  800ad0:	53                   	push   %ebx
  800ad1:	ff 75 10             	pushl  0x10(%ebp)
  800ad4:	e8 12 f6 ff ff       	call   8000eb <vcprintf>
	cprintf("\n");
  800ad9:	c7 04 24 9c 0d 80 00 	movl   $0x800d9c,(%esp)
  800ae0:	e8 57 f6 ff ff       	call   80013c <cprintf>
  800ae5:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800ae8:	cc                   	int3   
  800ae9:	eb fd                	jmp    800ae8 <_panic+0x43>
  800aeb:	66 90                	xchg   %ax,%ax
  800aed:	66 90                	xchg   %ax,%ax
  800aef:	90                   	nop

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

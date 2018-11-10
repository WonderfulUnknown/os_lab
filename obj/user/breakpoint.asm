
obj/user/breakpoint：     文件格式 elf32-i386


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
  80002c:	e8 08 00 00 00       	call   800039 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	asm volatile("int $3");
  800036:	cc                   	int3   
}
  800037:	5d                   	pop    %ebp
  800038:	c3                   	ret    

00800039 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800039:	55                   	push   %ebp
  80003a:	89 e5                	mov    %esp,%ebp
  80003c:	83 ec 08             	sub    $0x8,%esp
  80003f:	8b 45 08             	mov    0x8(%ebp),%eax
  800042:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800045:	c7 05 04 10 80 00 00 	movl   $0x0,0x801004
  80004c:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80004f:	85 c0                	test   %eax,%eax
  800051:	7e 08                	jle    80005b <libmain+0x22>
		binaryname = argv[0];
  800053:	8b 0a                	mov    (%edx),%ecx
  800055:	89 0d 00 10 80 00    	mov    %ecx,0x801000

	// call user main routine
	umain(argc, argv);
  80005b:	83 ec 08             	sub    $0x8,%esp
  80005e:	52                   	push   %edx
  80005f:	50                   	push   %eax
  800060:	e8 ce ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800065:	e8 05 00 00 00       	call   80006f <exit>
}
  80006a:	83 c4 10             	add    $0x10,%esp
  80006d:	c9                   	leave  
  80006e:	c3                   	ret    

0080006f <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80006f:	55                   	push   %ebp
  800070:	89 e5                	mov    %esp,%ebp
  800072:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800075:	6a 00                	push   $0x0
  800077:	e8 42 00 00 00       	call   8000be <sys_env_destroy>
}
  80007c:	83 c4 10             	add    $0x10,%esp
  80007f:	c9                   	leave  
  800080:	c3                   	ret    

00800081 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800081:	55                   	push   %ebp
  800082:	89 e5                	mov    %esp,%ebp
  800084:	57                   	push   %edi
  800085:	56                   	push   %esi
  800086:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800087:	b8 00 00 00 00       	mov    $0x0,%eax
  80008c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80008f:	8b 55 08             	mov    0x8(%ebp),%edx
  800092:	89 c3                	mov    %eax,%ebx
  800094:	89 c7                	mov    %eax,%edi
  800096:	89 c6                	mov    %eax,%esi
  800098:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  80009a:	5b                   	pop    %ebx
  80009b:	5e                   	pop    %esi
  80009c:	5f                   	pop    %edi
  80009d:	5d                   	pop    %ebp
  80009e:	c3                   	ret    

0080009f <sys_cgetc>:

int
sys_cgetc(void)
{
  80009f:	55                   	push   %ebp
  8000a0:	89 e5                	mov    %esp,%ebp
  8000a2:	57                   	push   %edi
  8000a3:	56                   	push   %esi
  8000a4:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000a5:	ba 00 00 00 00       	mov    $0x0,%edx
  8000aa:	b8 01 00 00 00       	mov    $0x1,%eax
  8000af:	89 d1                	mov    %edx,%ecx
  8000b1:	89 d3                	mov    %edx,%ebx
  8000b3:	89 d7                	mov    %edx,%edi
  8000b5:	89 d6                	mov    %edx,%esi
  8000b7:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000b9:	5b                   	pop    %ebx
  8000ba:	5e                   	pop    %esi
  8000bb:	5f                   	pop    %edi
  8000bc:	5d                   	pop    %ebp
  8000bd:	c3                   	ret    

008000be <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000be:	55                   	push   %ebp
  8000bf:	89 e5                	mov    %esp,%ebp
  8000c1:	57                   	push   %edi
  8000c2:	56                   	push   %esi
  8000c3:	53                   	push   %ebx
  8000c4:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000c7:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000cc:	b8 03 00 00 00       	mov    $0x3,%eax
  8000d1:	8b 55 08             	mov    0x8(%ebp),%edx
  8000d4:	89 cb                	mov    %ecx,%ebx
  8000d6:	89 cf                	mov    %ecx,%edi
  8000d8:	89 ce                	mov    %ecx,%esi
  8000da:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000dc:	85 c0                	test   %eax,%eax
  8000de:	7e 17                	jle    8000f7 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000e0:	83 ec 0c             	sub    $0xc,%esp
  8000e3:	50                   	push   %eax
  8000e4:	6a 03                	push   $0x3
  8000e6:	68 6a 0d 80 00       	push   $0x800d6a
  8000eb:	6a 23                	push   $0x23
  8000ed:	68 87 0d 80 00       	push   $0x800d87
  8000f2:	e8 27 00 00 00       	call   80011e <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  8000f7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000fa:	5b                   	pop    %ebx
  8000fb:	5e                   	pop    %esi
  8000fc:	5f                   	pop    %edi
  8000fd:	5d                   	pop    %ebp
  8000fe:	c3                   	ret    

008000ff <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  8000ff:	55                   	push   %ebp
  800100:	89 e5                	mov    %esp,%ebp
  800102:	57                   	push   %edi
  800103:	56                   	push   %esi
  800104:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800105:	ba 00 00 00 00       	mov    $0x0,%edx
  80010a:	b8 02 00 00 00       	mov    $0x2,%eax
  80010f:	89 d1                	mov    %edx,%ecx
  800111:	89 d3                	mov    %edx,%ebx
  800113:	89 d7                	mov    %edx,%edi
  800115:	89 d6                	mov    %edx,%esi
  800117:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800119:	5b                   	pop    %ebx
  80011a:	5e                   	pop    %esi
  80011b:	5f                   	pop    %edi
  80011c:	5d                   	pop    %ebp
  80011d:	c3                   	ret    

0080011e <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80011e:	55                   	push   %ebp
  80011f:	89 e5                	mov    %esp,%ebp
  800121:	56                   	push   %esi
  800122:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800123:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800126:	8b 35 00 10 80 00    	mov    0x801000,%esi
  80012c:	e8 ce ff ff ff       	call   8000ff <sys_getenvid>
  800131:	83 ec 0c             	sub    $0xc,%esp
  800134:	ff 75 0c             	pushl  0xc(%ebp)
  800137:	ff 75 08             	pushl  0x8(%ebp)
  80013a:	56                   	push   %esi
  80013b:	50                   	push   %eax
  80013c:	68 98 0d 80 00       	push   $0x800d98
  800141:	e8 b1 00 00 00       	call   8001f7 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800146:	83 c4 18             	add    $0x18,%esp
  800149:	53                   	push   %ebx
  80014a:	ff 75 10             	pushl  0x10(%ebp)
  80014d:	e8 54 00 00 00       	call   8001a6 <vcprintf>
	cprintf("\n");
  800152:	c7 04 24 bc 0d 80 00 	movl   $0x800dbc,(%esp)
  800159:	e8 99 00 00 00       	call   8001f7 <cprintf>
  80015e:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800161:	cc                   	int3   
  800162:	eb fd                	jmp    800161 <_panic+0x43>

00800164 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800164:	55                   	push   %ebp
  800165:	89 e5                	mov    %esp,%ebp
  800167:	53                   	push   %ebx
  800168:	83 ec 04             	sub    $0x4,%esp
  80016b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80016e:	8b 13                	mov    (%ebx),%edx
  800170:	8d 42 01             	lea    0x1(%edx),%eax
  800173:	89 03                	mov    %eax,(%ebx)
  800175:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800178:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80017c:	3d ff 00 00 00       	cmp    $0xff,%eax
  800181:	75 1a                	jne    80019d <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800183:	83 ec 08             	sub    $0x8,%esp
  800186:	68 ff 00 00 00       	push   $0xff
  80018b:	8d 43 08             	lea    0x8(%ebx),%eax
  80018e:	50                   	push   %eax
  80018f:	e8 ed fe ff ff       	call   800081 <sys_cputs>
		b->idx = 0;
  800194:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  80019a:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  80019d:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001a1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001a4:	c9                   	leave  
  8001a5:	c3                   	ret    

008001a6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001a6:	55                   	push   %ebp
  8001a7:	89 e5                	mov    %esp,%ebp
  8001a9:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001af:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001b6:	00 00 00 
	b.cnt = 0;
  8001b9:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001c0:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001c3:	ff 75 0c             	pushl  0xc(%ebp)
  8001c6:	ff 75 08             	pushl  0x8(%ebp)
  8001c9:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001cf:	50                   	push   %eax
  8001d0:	68 64 01 80 00       	push   $0x800164
  8001d5:	e8 54 01 00 00       	call   80032e <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001da:	83 c4 08             	add    $0x8,%esp
  8001dd:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001e3:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001e9:	50                   	push   %eax
  8001ea:	e8 92 fe ff ff       	call   800081 <sys_cputs>

	return b.cnt;
}
  8001ef:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001f5:	c9                   	leave  
  8001f6:	c3                   	ret    

008001f7 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001f7:	55                   	push   %ebp
  8001f8:	89 e5                	mov    %esp,%ebp
  8001fa:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8001fd:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800200:	50                   	push   %eax
  800201:	ff 75 08             	pushl  0x8(%ebp)
  800204:	e8 9d ff ff ff       	call   8001a6 <vcprintf>
	va_end(ap);

	return cnt;
}
  800209:	c9                   	leave  
  80020a:	c3                   	ret    

0080020b <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80020b:	55                   	push   %ebp
  80020c:	89 e5                	mov    %esp,%ebp
  80020e:	57                   	push   %edi
  80020f:	56                   	push   %esi
  800210:	53                   	push   %ebx
  800211:	83 ec 1c             	sub    $0x1c,%esp
  800214:	89 c7                	mov    %eax,%edi
  800216:	89 d6                	mov    %edx,%esi
  800218:	8b 45 08             	mov    0x8(%ebp),%eax
  80021b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80021e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800221:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800224:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800227:	bb 00 00 00 00       	mov    $0x0,%ebx
  80022c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  80022f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800232:	39 d3                	cmp    %edx,%ebx
  800234:	72 05                	jb     80023b <printnum+0x30>
  800236:	39 45 10             	cmp    %eax,0x10(%ebp)
  800239:	77 45                	ja     800280 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80023b:	83 ec 0c             	sub    $0xc,%esp
  80023e:	ff 75 18             	pushl  0x18(%ebp)
  800241:	8b 45 14             	mov    0x14(%ebp),%eax
  800244:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800247:	53                   	push   %ebx
  800248:	ff 75 10             	pushl  0x10(%ebp)
  80024b:	83 ec 08             	sub    $0x8,%esp
  80024e:	ff 75 e4             	pushl  -0x1c(%ebp)
  800251:	ff 75 e0             	pushl  -0x20(%ebp)
  800254:	ff 75 dc             	pushl  -0x24(%ebp)
  800257:	ff 75 d8             	pushl  -0x28(%ebp)
  80025a:	e8 71 08 00 00       	call   800ad0 <__udivdi3>
  80025f:	83 c4 18             	add    $0x18,%esp
  800262:	52                   	push   %edx
  800263:	50                   	push   %eax
  800264:	89 f2                	mov    %esi,%edx
  800266:	89 f8                	mov    %edi,%eax
  800268:	e8 9e ff ff ff       	call   80020b <printnum>
  80026d:	83 c4 20             	add    $0x20,%esp
  800270:	eb 18                	jmp    80028a <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800272:	83 ec 08             	sub    $0x8,%esp
  800275:	56                   	push   %esi
  800276:	ff 75 18             	pushl  0x18(%ebp)
  800279:	ff d7                	call   *%edi
  80027b:	83 c4 10             	add    $0x10,%esp
  80027e:	eb 03                	jmp    800283 <printnum+0x78>
  800280:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800283:	83 eb 01             	sub    $0x1,%ebx
  800286:	85 db                	test   %ebx,%ebx
  800288:	7f e8                	jg     800272 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80028a:	83 ec 08             	sub    $0x8,%esp
  80028d:	56                   	push   %esi
  80028e:	83 ec 04             	sub    $0x4,%esp
  800291:	ff 75 e4             	pushl  -0x1c(%ebp)
  800294:	ff 75 e0             	pushl  -0x20(%ebp)
  800297:	ff 75 dc             	pushl  -0x24(%ebp)
  80029a:	ff 75 d8             	pushl  -0x28(%ebp)
  80029d:	e8 5e 09 00 00       	call   800c00 <__umoddi3>
  8002a2:	83 c4 14             	add    $0x14,%esp
  8002a5:	0f be 80 be 0d 80 00 	movsbl 0x800dbe(%eax),%eax
  8002ac:	50                   	push   %eax
  8002ad:	ff d7                	call   *%edi
}
  8002af:	83 c4 10             	add    $0x10,%esp
  8002b2:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002b5:	5b                   	pop    %ebx
  8002b6:	5e                   	pop    %esi
  8002b7:	5f                   	pop    %edi
  8002b8:	5d                   	pop    %ebp
  8002b9:	c3                   	ret    

008002ba <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002ba:	55                   	push   %ebp
  8002bb:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002bd:	83 fa 01             	cmp    $0x1,%edx
  8002c0:	7e 0e                	jle    8002d0 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002c2:	8b 10                	mov    (%eax),%edx
  8002c4:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002c7:	89 08                	mov    %ecx,(%eax)
  8002c9:	8b 02                	mov    (%edx),%eax
  8002cb:	8b 52 04             	mov    0x4(%edx),%edx
  8002ce:	eb 22                	jmp    8002f2 <getuint+0x38>
	else if (lflag)
  8002d0:	85 d2                	test   %edx,%edx
  8002d2:	74 10                	je     8002e4 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002d4:	8b 10                	mov    (%eax),%edx
  8002d6:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002d9:	89 08                	mov    %ecx,(%eax)
  8002db:	8b 02                	mov    (%edx),%eax
  8002dd:	ba 00 00 00 00       	mov    $0x0,%edx
  8002e2:	eb 0e                	jmp    8002f2 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8002e4:	8b 10                	mov    (%eax),%edx
  8002e6:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002e9:	89 08                	mov    %ecx,(%eax)
  8002eb:	8b 02                	mov    (%edx),%eax
  8002ed:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8002f2:	5d                   	pop    %ebp
  8002f3:	c3                   	ret    

008002f4 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002f4:	55                   	push   %ebp
  8002f5:	89 e5                	mov    %esp,%ebp
  8002f7:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002fa:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002fe:	8b 10                	mov    (%eax),%edx
  800300:	3b 50 04             	cmp    0x4(%eax),%edx
  800303:	73 0a                	jae    80030f <sprintputch+0x1b>
		*b->buf++ = ch;
  800305:	8d 4a 01             	lea    0x1(%edx),%ecx
  800308:	89 08                	mov    %ecx,(%eax)
  80030a:	8b 45 08             	mov    0x8(%ebp),%eax
  80030d:	88 02                	mov    %al,(%edx)
}
  80030f:	5d                   	pop    %ebp
  800310:	c3                   	ret    

00800311 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800311:	55                   	push   %ebp
  800312:	89 e5                	mov    %esp,%ebp
  800314:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800317:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80031a:	50                   	push   %eax
  80031b:	ff 75 10             	pushl  0x10(%ebp)
  80031e:	ff 75 0c             	pushl  0xc(%ebp)
  800321:	ff 75 08             	pushl  0x8(%ebp)
  800324:	e8 05 00 00 00       	call   80032e <vprintfmt>
	va_end(ap);
}
  800329:	83 c4 10             	add    $0x10,%esp
  80032c:	c9                   	leave  
  80032d:	c3                   	ret    

0080032e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80032e:	55                   	push   %ebp
  80032f:	89 e5                	mov    %esp,%ebp
  800331:	57                   	push   %edi
  800332:	56                   	push   %esi
  800333:	53                   	push   %ebx
  800334:	83 ec 2c             	sub    $0x2c,%esp
  800337:	8b 75 08             	mov    0x8(%ebp),%esi
  80033a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80033d:	8b 7d 10             	mov    0x10(%ebp),%edi
  800340:	eb 12                	jmp    800354 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800342:	85 c0                	test   %eax,%eax
  800344:	0f 84 89 03 00 00    	je     8006d3 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  80034a:	83 ec 08             	sub    $0x8,%esp
  80034d:	53                   	push   %ebx
  80034e:	50                   	push   %eax
  80034f:	ff d6                	call   *%esi
  800351:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800354:	83 c7 01             	add    $0x1,%edi
  800357:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80035b:	83 f8 25             	cmp    $0x25,%eax
  80035e:	75 e2                	jne    800342 <vprintfmt+0x14>
  800360:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800364:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80036b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800372:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800379:	ba 00 00 00 00       	mov    $0x0,%edx
  80037e:	eb 07                	jmp    800387 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800380:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800383:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800387:	8d 47 01             	lea    0x1(%edi),%eax
  80038a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80038d:	0f b6 07             	movzbl (%edi),%eax
  800390:	0f b6 c8             	movzbl %al,%ecx
  800393:	83 e8 23             	sub    $0x23,%eax
  800396:	3c 55                	cmp    $0x55,%al
  800398:	0f 87 1a 03 00 00    	ja     8006b8 <vprintfmt+0x38a>
  80039e:	0f b6 c0             	movzbl %al,%eax
  8003a1:	ff 24 85 60 0e 80 00 	jmp    *0x800e60(,%eax,4)
  8003a8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003ab:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003af:	eb d6                	jmp    800387 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003b4:	b8 00 00 00 00       	mov    $0x0,%eax
  8003b9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003bc:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003bf:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  8003c3:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  8003c6:	8d 51 d0             	lea    -0x30(%ecx),%edx
  8003c9:	83 fa 09             	cmp    $0x9,%edx
  8003cc:	77 39                	ja     800407 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003ce:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003d1:	eb e9                	jmp    8003bc <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003d3:	8b 45 14             	mov    0x14(%ebp),%eax
  8003d6:	8d 48 04             	lea    0x4(%eax),%ecx
  8003d9:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003dc:	8b 00                	mov    (%eax),%eax
  8003de:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003e1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003e4:	eb 27                	jmp    80040d <vprintfmt+0xdf>
  8003e6:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003e9:	85 c0                	test   %eax,%eax
  8003eb:	b9 00 00 00 00       	mov    $0x0,%ecx
  8003f0:	0f 49 c8             	cmovns %eax,%ecx
  8003f3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003f9:	eb 8c                	jmp    800387 <vprintfmt+0x59>
  8003fb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003fe:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800405:	eb 80                	jmp    800387 <vprintfmt+0x59>
  800407:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80040a:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80040d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800411:	0f 89 70 ff ff ff    	jns    800387 <vprintfmt+0x59>
				width = precision, precision = -1;
  800417:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80041a:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80041d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800424:	e9 5e ff ff ff       	jmp    800387 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800429:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80042c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80042f:	e9 53 ff ff ff       	jmp    800387 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800434:	8b 45 14             	mov    0x14(%ebp),%eax
  800437:	8d 50 04             	lea    0x4(%eax),%edx
  80043a:	89 55 14             	mov    %edx,0x14(%ebp)
  80043d:	83 ec 08             	sub    $0x8,%esp
  800440:	53                   	push   %ebx
  800441:	ff 30                	pushl  (%eax)
  800443:	ff d6                	call   *%esi
			break;
  800445:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800448:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80044b:	e9 04 ff ff ff       	jmp    800354 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800450:	8b 45 14             	mov    0x14(%ebp),%eax
  800453:	8d 50 04             	lea    0x4(%eax),%edx
  800456:	89 55 14             	mov    %edx,0x14(%ebp)
  800459:	8b 00                	mov    (%eax),%eax
  80045b:	99                   	cltd   
  80045c:	31 d0                	xor    %edx,%eax
  80045e:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800460:	83 f8 07             	cmp    $0x7,%eax
  800463:	7f 0b                	jg     800470 <vprintfmt+0x142>
  800465:	8b 14 85 c0 0f 80 00 	mov    0x800fc0(,%eax,4),%edx
  80046c:	85 d2                	test   %edx,%edx
  80046e:	75 18                	jne    800488 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800470:	50                   	push   %eax
  800471:	68 d6 0d 80 00       	push   $0x800dd6
  800476:	53                   	push   %ebx
  800477:	56                   	push   %esi
  800478:	e8 94 fe ff ff       	call   800311 <printfmt>
  80047d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800480:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800483:	e9 cc fe ff ff       	jmp    800354 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800488:	52                   	push   %edx
  800489:	68 df 0d 80 00       	push   $0x800ddf
  80048e:	53                   	push   %ebx
  80048f:	56                   	push   %esi
  800490:	e8 7c fe ff ff       	call   800311 <printfmt>
  800495:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800498:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80049b:	e9 b4 fe ff ff       	jmp    800354 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004a0:	8b 45 14             	mov    0x14(%ebp),%eax
  8004a3:	8d 50 04             	lea    0x4(%eax),%edx
  8004a6:	89 55 14             	mov    %edx,0x14(%ebp)
  8004a9:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004ab:	85 ff                	test   %edi,%edi
  8004ad:	b8 cf 0d 80 00       	mov    $0x800dcf,%eax
  8004b2:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004b5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004b9:	0f 8e 94 00 00 00    	jle    800553 <vprintfmt+0x225>
  8004bf:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004c3:	0f 84 98 00 00 00    	je     800561 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004c9:	83 ec 08             	sub    $0x8,%esp
  8004cc:	ff 75 d0             	pushl  -0x30(%ebp)
  8004cf:	57                   	push   %edi
  8004d0:	e8 86 02 00 00       	call   80075b <strnlen>
  8004d5:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004d8:	29 c1                	sub    %eax,%ecx
  8004da:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  8004dd:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004e0:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004e4:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004e7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004ea:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004ec:	eb 0f                	jmp    8004fd <vprintfmt+0x1cf>
					putch(padc, putdat);
  8004ee:	83 ec 08             	sub    $0x8,%esp
  8004f1:	53                   	push   %ebx
  8004f2:	ff 75 e0             	pushl  -0x20(%ebp)
  8004f5:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004f7:	83 ef 01             	sub    $0x1,%edi
  8004fa:	83 c4 10             	add    $0x10,%esp
  8004fd:	85 ff                	test   %edi,%edi
  8004ff:	7f ed                	jg     8004ee <vprintfmt+0x1c0>
  800501:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800504:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  800507:	85 c9                	test   %ecx,%ecx
  800509:	b8 00 00 00 00       	mov    $0x0,%eax
  80050e:	0f 49 c1             	cmovns %ecx,%eax
  800511:	29 c1                	sub    %eax,%ecx
  800513:	89 75 08             	mov    %esi,0x8(%ebp)
  800516:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800519:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80051c:	89 cb                	mov    %ecx,%ebx
  80051e:	eb 4d                	jmp    80056d <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800520:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800524:	74 1b                	je     800541 <vprintfmt+0x213>
  800526:	0f be c0             	movsbl %al,%eax
  800529:	83 e8 20             	sub    $0x20,%eax
  80052c:	83 f8 5e             	cmp    $0x5e,%eax
  80052f:	76 10                	jbe    800541 <vprintfmt+0x213>
					putch('?', putdat);
  800531:	83 ec 08             	sub    $0x8,%esp
  800534:	ff 75 0c             	pushl  0xc(%ebp)
  800537:	6a 3f                	push   $0x3f
  800539:	ff 55 08             	call   *0x8(%ebp)
  80053c:	83 c4 10             	add    $0x10,%esp
  80053f:	eb 0d                	jmp    80054e <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800541:	83 ec 08             	sub    $0x8,%esp
  800544:	ff 75 0c             	pushl  0xc(%ebp)
  800547:	52                   	push   %edx
  800548:	ff 55 08             	call   *0x8(%ebp)
  80054b:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80054e:	83 eb 01             	sub    $0x1,%ebx
  800551:	eb 1a                	jmp    80056d <vprintfmt+0x23f>
  800553:	89 75 08             	mov    %esi,0x8(%ebp)
  800556:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800559:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80055c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80055f:	eb 0c                	jmp    80056d <vprintfmt+0x23f>
  800561:	89 75 08             	mov    %esi,0x8(%ebp)
  800564:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800567:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80056a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80056d:	83 c7 01             	add    $0x1,%edi
  800570:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800574:	0f be d0             	movsbl %al,%edx
  800577:	85 d2                	test   %edx,%edx
  800579:	74 23                	je     80059e <vprintfmt+0x270>
  80057b:	85 f6                	test   %esi,%esi
  80057d:	78 a1                	js     800520 <vprintfmt+0x1f2>
  80057f:	83 ee 01             	sub    $0x1,%esi
  800582:	79 9c                	jns    800520 <vprintfmt+0x1f2>
  800584:	89 df                	mov    %ebx,%edi
  800586:	8b 75 08             	mov    0x8(%ebp),%esi
  800589:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80058c:	eb 18                	jmp    8005a6 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80058e:	83 ec 08             	sub    $0x8,%esp
  800591:	53                   	push   %ebx
  800592:	6a 20                	push   $0x20
  800594:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800596:	83 ef 01             	sub    $0x1,%edi
  800599:	83 c4 10             	add    $0x10,%esp
  80059c:	eb 08                	jmp    8005a6 <vprintfmt+0x278>
  80059e:	89 df                	mov    %ebx,%edi
  8005a0:	8b 75 08             	mov    0x8(%ebp),%esi
  8005a3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005a6:	85 ff                	test   %edi,%edi
  8005a8:	7f e4                	jg     80058e <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005aa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005ad:	e9 a2 fd ff ff       	jmp    800354 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005b2:	83 fa 01             	cmp    $0x1,%edx
  8005b5:	7e 16                	jle    8005cd <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  8005b7:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ba:	8d 50 08             	lea    0x8(%eax),%edx
  8005bd:	89 55 14             	mov    %edx,0x14(%ebp)
  8005c0:	8b 50 04             	mov    0x4(%eax),%edx
  8005c3:	8b 00                	mov    (%eax),%eax
  8005c5:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005c8:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005cb:	eb 32                	jmp    8005ff <vprintfmt+0x2d1>
	else if (lflag)
  8005cd:	85 d2                	test   %edx,%edx
  8005cf:	74 18                	je     8005e9 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  8005d1:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d4:	8d 50 04             	lea    0x4(%eax),%edx
  8005d7:	89 55 14             	mov    %edx,0x14(%ebp)
  8005da:	8b 00                	mov    (%eax),%eax
  8005dc:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005df:	89 c1                	mov    %eax,%ecx
  8005e1:	c1 f9 1f             	sar    $0x1f,%ecx
  8005e4:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005e7:	eb 16                	jmp    8005ff <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  8005e9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ec:	8d 50 04             	lea    0x4(%eax),%edx
  8005ef:	89 55 14             	mov    %edx,0x14(%ebp)
  8005f2:	8b 00                	mov    (%eax),%eax
  8005f4:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005f7:	89 c1                	mov    %eax,%ecx
  8005f9:	c1 f9 1f             	sar    $0x1f,%ecx
  8005fc:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005ff:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800602:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800605:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80060a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80060e:	79 74                	jns    800684 <vprintfmt+0x356>
				putch('-', putdat);
  800610:	83 ec 08             	sub    $0x8,%esp
  800613:	53                   	push   %ebx
  800614:	6a 2d                	push   $0x2d
  800616:	ff d6                	call   *%esi
				num = -(long long) num;
  800618:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80061b:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80061e:	f7 d8                	neg    %eax
  800620:	83 d2 00             	adc    $0x0,%edx
  800623:	f7 da                	neg    %edx
  800625:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800628:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80062d:	eb 55                	jmp    800684 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80062f:	8d 45 14             	lea    0x14(%ebp),%eax
  800632:	e8 83 fc ff ff       	call   8002ba <getuint>
			base = 10;
  800637:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80063c:	eb 46                	jmp    800684 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  80063e:	8d 45 14             	lea    0x14(%ebp),%eax
  800641:	e8 74 fc ff ff       	call   8002ba <getuint>
			base = 8;
  800646:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80064b:	eb 37                	jmp    800684 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  80064d:	83 ec 08             	sub    $0x8,%esp
  800650:	53                   	push   %ebx
  800651:	6a 30                	push   $0x30
  800653:	ff d6                	call   *%esi
			putch('x', putdat);
  800655:	83 c4 08             	add    $0x8,%esp
  800658:	53                   	push   %ebx
  800659:	6a 78                	push   $0x78
  80065b:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80065d:	8b 45 14             	mov    0x14(%ebp),%eax
  800660:	8d 50 04             	lea    0x4(%eax),%edx
  800663:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800666:	8b 00                	mov    (%eax),%eax
  800668:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  80066d:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800670:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800675:	eb 0d                	jmp    800684 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800677:	8d 45 14             	lea    0x14(%ebp),%eax
  80067a:	e8 3b fc ff ff       	call   8002ba <getuint>
			base = 16;
  80067f:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800684:	83 ec 0c             	sub    $0xc,%esp
  800687:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80068b:	57                   	push   %edi
  80068c:	ff 75 e0             	pushl  -0x20(%ebp)
  80068f:	51                   	push   %ecx
  800690:	52                   	push   %edx
  800691:	50                   	push   %eax
  800692:	89 da                	mov    %ebx,%edx
  800694:	89 f0                	mov    %esi,%eax
  800696:	e8 70 fb ff ff       	call   80020b <printnum>
			break;
  80069b:	83 c4 20             	add    $0x20,%esp
  80069e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006a1:	e9 ae fc ff ff       	jmp    800354 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006a6:	83 ec 08             	sub    $0x8,%esp
  8006a9:	53                   	push   %ebx
  8006aa:	51                   	push   %ecx
  8006ab:	ff d6                	call   *%esi
			break;
  8006ad:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006b0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006b3:	e9 9c fc ff ff       	jmp    800354 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006b8:	83 ec 08             	sub    $0x8,%esp
  8006bb:	53                   	push   %ebx
  8006bc:	6a 25                	push   $0x25
  8006be:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006c0:	83 c4 10             	add    $0x10,%esp
  8006c3:	eb 03                	jmp    8006c8 <vprintfmt+0x39a>
  8006c5:	83 ef 01             	sub    $0x1,%edi
  8006c8:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006cc:	75 f7                	jne    8006c5 <vprintfmt+0x397>
  8006ce:	e9 81 fc ff ff       	jmp    800354 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006d6:	5b                   	pop    %ebx
  8006d7:	5e                   	pop    %esi
  8006d8:	5f                   	pop    %edi
  8006d9:	5d                   	pop    %ebp
  8006da:	c3                   	ret    

008006db <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006db:	55                   	push   %ebp
  8006dc:	89 e5                	mov    %esp,%ebp
  8006de:	83 ec 18             	sub    $0x18,%esp
  8006e1:	8b 45 08             	mov    0x8(%ebp),%eax
  8006e4:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006e7:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006ea:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006ee:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006f1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006f8:	85 c0                	test   %eax,%eax
  8006fa:	74 26                	je     800722 <vsnprintf+0x47>
  8006fc:	85 d2                	test   %edx,%edx
  8006fe:	7e 22                	jle    800722 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800700:	ff 75 14             	pushl  0x14(%ebp)
  800703:	ff 75 10             	pushl  0x10(%ebp)
  800706:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800709:	50                   	push   %eax
  80070a:	68 f4 02 80 00       	push   $0x8002f4
  80070f:	e8 1a fc ff ff       	call   80032e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800714:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800717:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80071a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80071d:	83 c4 10             	add    $0x10,%esp
  800720:	eb 05                	jmp    800727 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800722:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800727:	c9                   	leave  
  800728:	c3                   	ret    

00800729 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800729:	55                   	push   %ebp
  80072a:	89 e5                	mov    %esp,%ebp
  80072c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80072f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800732:	50                   	push   %eax
  800733:	ff 75 10             	pushl  0x10(%ebp)
  800736:	ff 75 0c             	pushl  0xc(%ebp)
  800739:	ff 75 08             	pushl  0x8(%ebp)
  80073c:	e8 9a ff ff ff       	call   8006db <vsnprintf>
	va_end(ap);

	return rc;
}
  800741:	c9                   	leave  
  800742:	c3                   	ret    

00800743 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800743:	55                   	push   %ebp
  800744:	89 e5                	mov    %esp,%ebp
  800746:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800749:	b8 00 00 00 00       	mov    $0x0,%eax
  80074e:	eb 03                	jmp    800753 <strlen+0x10>
		n++;
  800750:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800753:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800757:	75 f7                	jne    800750 <strlen+0xd>
		n++;
	return n;
}
  800759:	5d                   	pop    %ebp
  80075a:	c3                   	ret    

0080075b <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80075b:	55                   	push   %ebp
  80075c:	89 e5                	mov    %esp,%ebp
  80075e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800761:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800764:	ba 00 00 00 00       	mov    $0x0,%edx
  800769:	eb 03                	jmp    80076e <strnlen+0x13>
		n++;
  80076b:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80076e:	39 c2                	cmp    %eax,%edx
  800770:	74 08                	je     80077a <strnlen+0x1f>
  800772:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800776:	75 f3                	jne    80076b <strnlen+0x10>
  800778:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80077a:	5d                   	pop    %ebp
  80077b:	c3                   	ret    

0080077c <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80077c:	55                   	push   %ebp
  80077d:	89 e5                	mov    %esp,%ebp
  80077f:	53                   	push   %ebx
  800780:	8b 45 08             	mov    0x8(%ebp),%eax
  800783:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800786:	89 c2                	mov    %eax,%edx
  800788:	83 c2 01             	add    $0x1,%edx
  80078b:	83 c1 01             	add    $0x1,%ecx
  80078e:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800792:	88 5a ff             	mov    %bl,-0x1(%edx)
  800795:	84 db                	test   %bl,%bl
  800797:	75 ef                	jne    800788 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800799:	5b                   	pop    %ebx
  80079a:	5d                   	pop    %ebp
  80079b:	c3                   	ret    

0080079c <strcat>:

char *
strcat(char *dst, const char *src)
{
  80079c:	55                   	push   %ebp
  80079d:	89 e5                	mov    %esp,%ebp
  80079f:	53                   	push   %ebx
  8007a0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007a3:	53                   	push   %ebx
  8007a4:	e8 9a ff ff ff       	call   800743 <strlen>
  8007a9:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007ac:	ff 75 0c             	pushl  0xc(%ebp)
  8007af:	01 d8                	add    %ebx,%eax
  8007b1:	50                   	push   %eax
  8007b2:	e8 c5 ff ff ff       	call   80077c <strcpy>
	return dst;
}
  8007b7:	89 d8                	mov    %ebx,%eax
  8007b9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007bc:	c9                   	leave  
  8007bd:	c3                   	ret    

008007be <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007be:	55                   	push   %ebp
  8007bf:	89 e5                	mov    %esp,%ebp
  8007c1:	56                   	push   %esi
  8007c2:	53                   	push   %ebx
  8007c3:	8b 75 08             	mov    0x8(%ebp),%esi
  8007c6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007c9:	89 f3                	mov    %esi,%ebx
  8007cb:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007ce:	89 f2                	mov    %esi,%edx
  8007d0:	eb 0f                	jmp    8007e1 <strncpy+0x23>
		*dst++ = *src;
  8007d2:	83 c2 01             	add    $0x1,%edx
  8007d5:	0f b6 01             	movzbl (%ecx),%eax
  8007d8:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007db:	80 39 01             	cmpb   $0x1,(%ecx)
  8007de:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007e1:	39 da                	cmp    %ebx,%edx
  8007e3:	75 ed                	jne    8007d2 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007e5:	89 f0                	mov    %esi,%eax
  8007e7:	5b                   	pop    %ebx
  8007e8:	5e                   	pop    %esi
  8007e9:	5d                   	pop    %ebp
  8007ea:	c3                   	ret    

008007eb <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007eb:	55                   	push   %ebp
  8007ec:	89 e5                	mov    %esp,%ebp
  8007ee:	56                   	push   %esi
  8007ef:	53                   	push   %ebx
  8007f0:	8b 75 08             	mov    0x8(%ebp),%esi
  8007f3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007f6:	8b 55 10             	mov    0x10(%ebp),%edx
  8007f9:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007fb:	85 d2                	test   %edx,%edx
  8007fd:	74 21                	je     800820 <strlcpy+0x35>
  8007ff:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800803:	89 f2                	mov    %esi,%edx
  800805:	eb 09                	jmp    800810 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800807:	83 c2 01             	add    $0x1,%edx
  80080a:	83 c1 01             	add    $0x1,%ecx
  80080d:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800810:	39 c2                	cmp    %eax,%edx
  800812:	74 09                	je     80081d <strlcpy+0x32>
  800814:	0f b6 19             	movzbl (%ecx),%ebx
  800817:	84 db                	test   %bl,%bl
  800819:	75 ec                	jne    800807 <strlcpy+0x1c>
  80081b:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80081d:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800820:	29 f0                	sub    %esi,%eax
}
  800822:	5b                   	pop    %ebx
  800823:	5e                   	pop    %esi
  800824:	5d                   	pop    %ebp
  800825:	c3                   	ret    

00800826 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800826:	55                   	push   %ebp
  800827:	89 e5                	mov    %esp,%ebp
  800829:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80082c:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80082f:	eb 06                	jmp    800837 <strcmp+0x11>
		p++, q++;
  800831:	83 c1 01             	add    $0x1,%ecx
  800834:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800837:	0f b6 01             	movzbl (%ecx),%eax
  80083a:	84 c0                	test   %al,%al
  80083c:	74 04                	je     800842 <strcmp+0x1c>
  80083e:	3a 02                	cmp    (%edx),%al
  800840:	74 ef                	je     800831 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800842:	0f b6 c0             	movzbl %al,%eax
  800845:	0f b6 12             	movzbl (%edx),%edx
  800848:	29 d0                	sub    %edx,%eax
}
  80084a:	5d                   	pop    %ebp
  80084b:	c3                   	ret    

0080084c <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80084c:	55                   	push   %ebp
  80084d:	89 e5                	mov    %esp,%ebp
  80084f:	53                   	push   %ebx
  800850:	8b 45 08             	mov    0x8(%ebp),%eax
  800853:	8b 55 0c             	mov    0xc(%ebp),%edx
  800856:	89 c3                	mov    %eax,%ebx
  800858:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80085b:	eb 06                	jmp    800863 <strncmp+0x17>
		n--, p++, q++;
  80085d:	83 c0 01             	add    $0x1,%eax
  800860:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800863:	39 d8                	cmp    %ebx,%eax
  800865:	74 15                	je     80087c <strncmp+0x30>
  800867:	0f b6 08             	movzbl (%eax),%ecx
  80086a:	84 c9                	test   %cl,%cl
  80086c:	74 04                	je     800872 <strncmp+0x26>
  80086e:	3a 0a                	cmp    (%edx),%cl
  800870:	74 eb                	je     80085d <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800872:	0f b6 00             	movzbl (%eax),%eax
  800875:	0f b6 12             	movzbl (%edx),%edx
  800878:	29 d0                	sub    %edx,%eax
  80087a:	eb 05                	jmp    800881 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80087c:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800881:	5b                   	pop    %ebx
  800882:	5d                   	pop    %ebp
  800883:	c3                   	ret    

00800884 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800884:	55                   	push   %ebp
  800885:	89 e5                	mov    %esp,%ebp
  800887:	8b 45 08             	mov    0x8(%ebp),%eax
  80088a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80088e:	eb 07                	jmp    800897 <strchr+0x13>
		if (*s == c)
  800890:	38 ca                	cmp    %cl,%dl
  800892:	74 0f                	je     8008a3 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800894:	83 c0 01             	add    $0x1,%eax
  800897:	0f b6 10             	movzbl (%eax),%edx
  80089a:	84 d2                	test   %dl,%dl
  80089c:	75 f2                	jne    800890 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  80089e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008a3:	5d                   	pop    %ebp
  8008a4:	c3                   	ret    

008008a5 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008a5:	55                   	push   %ebp
  8008a6:	89 e5                	mov    %esp,%ebp
  8008a8:	8b 45 08             	mov    0x8(%ebp),%eax
  8008ab:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008af:	eb 03                	jmp    8008b4 <strfind+0xf>
  8008b1:	83 c0 01             	add    $0x1,%eax
  8008b4:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008b7:	38 ca                	cmp    %cl,%dl
  8008b9:	74 04                	je     8008bf <strfind+0x1a>
  8008bb:	84 d2                	test   %dl,%dl
  8008bd:	75 f2                	jne    8008b1 <strfind+0xc>
			break;
	return (char *) s;
}
  8008bf:	5d                   	pop    %ebp
  8008c0:	c3                   	ret    

008008c1 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008c1:	55                   	push   %ebp
  8008c2:	89 e5                	mov    %esp,%ebp
  8008c4:	57                   	push   %edi
  8008c5:	56                   	push   %esi
  8008c6:	53                   	push   %ebx
  8008c7:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008ca:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008cd:	85 c9                	test   %ecx,%ecx
  8008cf:	74 36                	je     800907 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008d1:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008d7:	75 28                	jne    800901 <memset+0x40>
  8008d9:	f6 c1 03             	test   $0x3,%cl
  8008dc:	75 23                	jne    800901 <memset+0x40>
		c &= 0xFF;
  8008de:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008e2:	89 d3                	mov    %edx,%ebx
  8008e4:	c1 e3 08             	shl    $0x8,%ebx
  8008e7:	89 d6                	mov    %edx,%esi
  8008e9:	c1 e6 18             	shl    $0x18,%esi
  8008ec:	89 d0                	mov    %edx,%eax
  8008ee:	c1 e0 10             	shl    $0x10,%eax
  8008f1:	09 f0                	or     %esi,%eax
  8008f3:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8008f5:	89 d8                	mov    %ebx,%eax
  8008f7:	09 d0                	or     %edx,%eax
  8008f9:	c1 e9 02             	shr    $0x2,%ecx
  8008fc:	fc                   	cld    
  8008fd:	f3 ab                	rep stos %eax,%es:(%edi)
  8008ff:	eb 06                	jmp    800907 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800901:	8b 45 0c             	mov    0xc(%ebp),%eax
  800904:	fc                   	cld    
  800905:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800907:	89 f8                	mov    %edi,%eax
  800909:	5b                   	pop    %ebx
  80090a:	5e                   	pop    %esi
  80090b:	5f                   	pop    %edi
  80090c:	5d                   	pop    %ebp
  80090d:	c3                   	ret    

0080090e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80090e:	55                   	push   %ebp
  80090f:	89 e5                	mov    %esp,%ebp
  800911:	57                   	push   %edi
  800912:	56                   	push   %esi
  800913:	8b 45 08             	mov    0x8(%ebp),%eax
  800916:	8b 75 0c             	mov    0xc(%ebp),%esi
  800919:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80091c:	39 c6                	cmp    %eax,%esi
  80091e:	73 35                	jae    800955 <memmove+0x47>
  800920:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800923:	39 d0                	cmp    %edx,%eax
  800925:	73 2e                	jae    800955 <memmove+0x47>
		s += n;
		d += n;
  800927:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80092a:	89 d6                	mov    %edx,%esi
  80092c:	09 fe                	or     %edi,%esi
  80092e:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800934:	75 13                	jne    800949 <memmove+0x3b>
  800936:	f6 c1 03             	test   $0x3,%cl
  800939:	75 0e                	jne    800949 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80093b:	83 ef 04             	sub    $0x4,%edi
  80093e:	8d 72 fc             	lea    -0x4(%edx),%esi
  800941:	c1 e9 02             	shr    $0x2,%ecx
  800944:	fd                   	std    
  800945:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800947:	eb 09                	jmp    800952 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800949:	83 ef 01             	sub    $0x1,%edi
  80094c:	8d 72 ff             	lea    -0x1(%edx),%esi
  80094f:	fd                   	std    
  800950:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800952:	fc                   	cld    
  800953:	eb 1d                	jmp    800972 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800955:	89 f2                	mov    %esi,%edx
  800957:	09 c2                	or     %eax,%edx
  800959:	f6 c2 03             	test   $0x3,%dl
  80095c:	75 0f                	jne    80096d <memmove+0x5f>
  80095e:	f6 c1 03             	test   $0x3,%cl
  800961:	75 0a                	jne    80096d <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800963:	c1 e9 02             	shr    $0x2,%ecx
  800966:	89 c7                	mov    %eax,%edi
  800968:	fc                   	cld    
  800969:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80096b:	eb 05                	jmp    800972 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  80096d:	89 c7                	mov    %eax,%edi
  80096f:	fc                   	cld    
  800970:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800972:	5e                   	pop    %esi
  800973:	5f                   	pop    %edi
  800974:	5d                   	pop    %ebp
  800975:	c3                   	ret    

00800976 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800976:	55                   	push   %ebp
  800977:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800979:	ff 75 10             	pushl  0x10(%ebp)
  80097c:	ff 75 0c             	pushl  0xc(%ebp)
  80097f:	ff 75 08             	pushl  0x8(%ebp)
  800982:	e8 87 ff ff ff       	call   80090e <memmove>
}
  800987:	c9                   	leave  
  800988:	c3                   	ret    

00800989 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800989:	55                   	push   %ebp
  80098a:	89 e5                	mov    %esp,%ebp
  80098c:	56                   	push   %esi
  80098d:	53                   	push   %ebx
  80098e:	8b 45 08             	mov    0x8(%ebp),%eax
  800991:	8b 55 0c             	mov    0xc(%ebp),%edx
  800994:	89 c6                	mov    %eax,%esi
  800996:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800999:	eb 1a                	jmp    8009b5 <memcmp+0x2c>
		if (*s1 != *s2)
  80099b:	0f b6 08             	movzbl (%eax),%ecx
  80099e:	0f b6 1a             	movzbl (%edx),%ebx
  8009a1:	38 d9                	cmp    %bl,%cl
  8009a3:	74 0a                	je     8009af <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009a5:	0f b6 c1             	movzbl %cl,%eax
  8009a8:	0f b6 db             	movzbl %bl,%ebx
  8009ab:	29 d8                	sub    %ebx,%eax
  8009ad:	eb 0f                	jmp    8009be <memcmp+0x35>
		s1++, s2++;
  8009af:	83 c0 01             	add    $0x1,%eax
  8009b2:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009b5:	39 f0                	cmp    %esi,%eax
  8009b7:	75 e2                	jne    80099b <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009b9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009be:	5b                   	pop    %ebx
  8009bf:	5e                   	pop    %esi
  8009c0:	5d                   	pop    %ebp
  8009c1:	c3                   	ret    

008009c2 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009c2:	55                   	push   %ebp
  8009c3:	89 e5                	mov    %esp,%ebp
  8009c5:	53                   	push   %ebx
  8009c6:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009c9:	89 c1                	mov    %eax,%ecx
  8009cb:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009ce:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009d2:	eb 0a                	jmp    8009de <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009d4:	0f b6 10             	movzbl (%eax),%edx
  8009d7:	39 da                	cmp    %ebx,%edx
  8009d9:	74 07                	je     8009e2 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009db:	83 c0 01             	add    $0x1,%eax
  8009de:	39 c8                	cmp    %ecx,%eax
  8009e0:	72 f2                	jb     8009d4 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009e2:	5b                   	pop    %ebx
  8009e3:	5d                   	pop    %ebp
  8009e4:	c3                   	ret    

008009e5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009e5:	55                   	push   %ebp
  8009e6:	89 e5                	mov    %esp,%ebp
  8009e8:	57                   	push   %edi
  8009e9:	56                   	push   %esi
  8009ea:	53                   	push   %ebx
  8009eb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009ee:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009f1:	eb 03                	jmp    8009f6 <strtol+0x11>
		s++;
  8009f3:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009f6:	0f b6 01             	movzbl (%ecx),%eax
  8009f9:	3c 20                	cmp    $0x20,%al
  8009fb:	74 f6                	je     8009f3 <strtol+0xe>
  8009fd:	3c 09                	cmp    $0x9,%al
  8009ff:	74 f2                	je     8009f3 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a01:	3c 2b                	cmp    $0x2b,%al
  800a03:	75 0a                	jne    800a0f <strtol+0x2a>
		s++;
  800a05:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a08:	bf 00 00 00 00       	mov    $0x0,%edi
  800a0d:	eb 11                	jmp    800a20 <strtol+0x3b>
  800a0f:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a14:	3c 2d                	cmp    $0x2d,%al
  800a16:	75 08                	jne    800a20 <strtol+0x3b>
		s++, neg = 1;
  800a18:	83 c1 01             	add    $0x1,%ecx
  800a1b:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a20:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a26:	75 15                	jne    800a3d <strtol+0x58>
  800a28:	80 39 30             	cmpb   $0x30,(%ecx)
  800a2b:	75 10                	jne    800a3d <strtol+0x58>
  800a2d:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a31:	75 7c                	jne    800aaf <strtol+0xca>
		s += 2, base = 16;
  800a33:	83 c1 02             	add    $0x2,%ecx
  800a36:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a3b:	eb 16                	jmp    800a53 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a3d:	85 db                	test   %ebx,%ebx
  800a3f:	75 12                	jne    800a53 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a41:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a46:	80 39 30             	cmpb   $0x30,(%ecx)
  800a49:	75 08                	jne    800a53 <strtol+0x6e>
		s++, base = 8;
  800a4b:	83 c1 01             	add    $0x1,%ecx
  800a4e:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a53:	b8 00 00 00 00       	mov    $0x0,%eax
  800a58:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a5b:	0f b6 11             	movzbl (%ecx),%edx
  800a5e:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a61:	89 f3                	mov    %esi,%ebx
  800a63:	80 fb 09             	cmp    $0x9,%bl
  800a66:	77 08                	ja     800a70 <strtol+0x8b>
			dig = *s - '0';
  800a68:	0f be d2             	movsbl %dl,%edx
  800a6b:	83 ea 30             	sub    $0x30,%edx
  800a6e:	eb 22                	jmp    800a92 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a70:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a73:	89 f3                	mov    %esi,%ebx
  800a75:	80 fb 19             	cmp    $0x19,%bl
  800a78:	77 08                	ja     800a82 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a7a:	0f be d2             	movsbl %dl,%edx
  800a7d:	83 ea 57             	sub    $0x57,%edx
  800a80:	eb 10                	jmp    800a92 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a82:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a85:	89 f3                	mov    %esi,%ebx
  800a87:	80 fb 19             	cmp    $0x19,%bl
  800a8a:	77 16                	ja     800aa2 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a8c:	0f be d2             	movsbl %dl,%edx
  800a8f:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a92:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a95:	7d 0b                	jge    800aa2 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a97:	83 c1 01             	add    $0x1,%ecx
  800a9a:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a9e:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800aa0:	eb b9                	jmp    800a5b <strtol+0x76>

	if (endptr)
  800aa2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800aa6:	74 0d                	je     800ab5 <strtol+0xd0>
		*endptr = (char *) s;
  800aa8:	8b 75 0c             	mov    0xc(%ebp),%esi
  800aab:	89 0e                	mov    %ecx,(%esi)
  800aad:	eb 06                	jmp    800ab5 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800aaf:	85 db                	test   %ebx,%ebx
  800ab1:	74 98                	je     800a4b <strtol+0x66>
  800ab3:	eb 9e                	jmp    800a53 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800ab5:	89 c2                	mov    %eax,%edx
  800ab7:	f7 da                	neg    %edx
  800ab9:	85 ff                	test   %edi,%edi
  800abb:	0f 45 c2             	cmovne %edx,%eax
}
  800abe:	5b                   	pop    %ebx
  800abf:	5e                   	pop    %esi
  800ac0:	5f                   	pop    %edi
  800ac1:	5d                   	pop    %ebp
  800ac2:	c3                   	ret    
  800ac3:	66 90                	xchg   %ax,%ax
  800ac5:	66 90                	xchg   %ax,%ax
  800ac7:	66 90                	xchg   %ax,%ax
  800ac9:	66 90                	xchg   %ax,%ax
  800acb:	66 90                	xchg   %ax,%ax
  800acd:	66 90                	xchg   %ax,%ax
  800acf:	90                   	nop

00800ad0 <__udivdi3>:
  800ad0:	55                   	push   %ebp
  800ad1:	57                   	push   %edi
  800ad2:	56                   	push   %esi
  800ad3:	53                   	push   %ebx
  800ad4:	83 ec 1c             	sub    $0x1c,%esp
  800ad7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800adb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800adf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800ae3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800ae7:	85 f6                	test   %esi,%esi
  800ae9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800aed:	89 ca                	mov    %ecx,%edx
  800aef:	89 f8                	mov    %edi,%eax
  800af1:	75 3d                	jne    800b30 <__udivdi3+0x60>
  800af3:	39 cf                	cmp    %ecx,%edi
  800af5:	0f 87 c5 00 00 00    	ja     800bc0 <__udivdi3+0xf0>
  800afb:	85 ff                	test   %edi,%edi
  800afd:	89 fd                	mov    %edi,%ebp
  800aff:	75 0b                	jne    800b0c <__udivdi3+0x3c>
  800b01:	b8 01 00 00 00       	mov    $0x1,%eax
  800b06:	31 d2                	xor    %edx,%edx
  800b08:	f7 f7                	div    %edi
  800b0a:	89 c5                	mov    %eax,%ebp
  800b0c:	89 c8                	mov    %ecx,%eax
  800b0e:	31 d2                	xor    %edx,%edx
  800b10:	f7 f5                	div    %ebp
  800b12:	89 c1                	mov    %eax,%ecx
  800b14:	89 d8                	mov    %ebx,%eax
  800b16:	89 cf                	mov    %ecx,%edi
  800b18:	f7 f5                	div    %ebp
  800b1a:	89 c3                	mov    %eax,%ebx
  800b1c:	89 d8                	mov    %ebx,%eax
  800b1e:	89 fa                	mov    %edi,%edx
  800b20:	83 c4 1c             	add    $0x1c,%esp
  800b23:	5b                   	pop    %ebx
  800b24:	5e                   	pop    %esi
  800b25:	5f                   	pop    %edi
  800b26:	5d                   	pop    %ebp
  800b27:	c3                   	ret    
  800b28:	90                   	nop
  800b29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800b30:	39 ce                	cmp    %ecx,%esi
  800b32:	77 74                	ja     800ba8 <__udivdi3+0xd8>
  800b34:	0f bd fe             	bsr    %esi,%edi
  800b37:	83 f7 1f             	xor    $0x1f,%edi
  800b3a:	0f 84 98 00 00 00    	je     800bd8 <__udivdi3+0x108>
  800b40:	bb 20 00 00 00       	mov    $0x20,%ebx
  800b45:	89 f9                	mov    %edi,%ecx
  800b47:	89 c5                	mov    %eax,%ebp
  800b49:	29 fb                	sub    %edi,%ebx
  800b4b:	d3 e6                	shl    %cl,%esi
  800b4d:	89 d9                	mov    %ebx,%ecx
  800b4f:	d3 ed                	shr    %cl,%ebp
  800b51:	89 f9                	mov    %edi,%ecx
  800b53:	d3 e0                	shl    %cl,%eax
  800b55:	09 ee                	or     %ebp,%esi
  800b57:	89 d9                	mov    %ebx,%ecx
  800b59:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800b5d:	89 d5                	mov    %edx,%ebp
  800b5f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800b63:	d3 ed                	shr    %cl,%ebp
  800b65:	89 f9                	mov    %edi,%ecx
  800b67:	d3 e2                	shl    %cl,%edx
  800b69:	89 d9                	mov    %ebx,%ecx
  800b6b:	d3 e8                	shr    %cl,%eax
  800b6d:	09 c2                	or     %eax,%edx
  800b6f:	89 d0                	mov    %edx,%eax
  800b71:	89 ea                	mov    %ebp,%edx
  800b73:	f7 f6                	div    %esi
  800b75:	89 d5                	mov    %edx,%ebp
  800b77:	89 c3                	mov    %eax,%ebx
  800b79:	f7 64 24 0c          	mull   0xc(%esp)
  800b7d:	39 d5                	cmp    %edx,%ebp
  800b7f:	72 10                	jb     800b91 <__udivdi3+0xc1>
  800b81:	8b 74 24 08          	mov    0x8(%esp),%esi
  800b85:	89 f9                	mov    %edi,%ecx
  800b87:	d3 e6                	shl    %cl,%esi
  800b89:	39 c6                	cmp    %eax,%esi
  800b8b:	73 07                	jae    800b94 <__udivdi3+0xc4>
  800b8d:	39 d5                	cmp    %edx,%ebp
  800b8f:	75 03                	jne    800b94 <__udivdi3+0xc4>
  800b91:	83 eb 01             	sub    $0x1,%ebx
  800b94:	31 ff                	xor    %edi,%edi
  800b96:	89 d8                	mov    %ebx,%eax
  800b98:	89 fa                	mov    %edi,%edx
  800b9a:	83 c4 1c             	add    $0x1c,%esp
  800b9d:	5b                   	pop    %ebx
  800b9e:	5e                   	pop    %esi
  800b9f:	5f                   	pop    %edi
  800ba0:	5d                   	pop    %ebp
  800ba1:	c3                   	ret    
  800ba2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800ba8:	31 ff                	xor    %edi,%edi
  800baa:	31 db                	xor    %ebx,%ebx
  800bac:	89 d8                	mov    %ebx,%eax
  800bae:	89 fa                	mov    %edi,%edx
  800bb0:	83 c4 1c             	add    $0x1c,%esp
  800bb3:	5b                   	pop    %ebx
  800bb4:	5e                   	pop    %esi
  800bb5:	5f                   	pop    %edi
  800bb6:	5d                   	pop    %ebp
  800bb7:	c3                   	ret    
  800bb8:	90                   	nop
  800bb9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800bc0:	89 d8                	mov    %ebx,%eax
  800bc2:	f7 f7                	div    %edi
  800bc4:	31 ff                	xor    %edi,%edi
  800bc6:	89 c3                	mov    %eax,%ebx
  800bc8:	89 d8                	mov    %ebx,%eax
  800bca:	89 fa                	mov    %edi,%edx
  800bcc:	83 c4 1c             	add    $0x1c,%esp
  800bcf:	5b                   	pop    %ebx
  800bd0:	5e                   	pop    %esi
  800bd1:	5f                   	pop    %edi
  800bd2:	5d                   	pop    %ebp
  800bd3:	c3                   	ret    
  800bd4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800bd8:	39 ce                	cmp    %ecx,%esi
  800bda:	72 0c                	jb     800be8 <__udivdi3+0x118>
  800bdc:	31 db                	xor    %ebx,%ebx
  800bde:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800be2:	0f 87 34 ff ff ff    	ja     800b1c <__udivdi3+0x4c>
  800be8:	bb 01 00 00 00       	mov    $0x1,%ebx
  800bed:	e9 2a ff ff ff       	jmp    800b1c <__udivdi3+0x4c>
  800bf2:	66 90                	xchg   %ax,%ax
  800bf4:	66 90                	xchg   %ax,%ax
  800bf6:	66 90                	xchg   %ax,%ax
  800bf8:	66 90                	xchg   %ax,%ax
  800bfa:	66 90                	xchg   %ax,%ax
  800bfc:	66 90                	xchg   %ax,%ax
  800bfe:	66 90                	xchg   %ax,%ax

00800c00 <__umoddi3>:
  800c00:	55                   	push   %ebp
  800c01:	57                   	push   %edi
  800c02:	56                   	push   %esi
  800c03:	53                   	push   %ebx
  800c04:	83 ec 1c             	sub    $0x1c,%esp
  800c07:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800c0b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800c0f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800c13:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c17:	85 d2                	test   %edx,%edx
  800c19:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800c1d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800c21:	89 f3                	mov    %esi,%ebx
  800c23:	89 3c 24             	mov    %edi,(%esp)
  800c26:	89 74 24 04          	mov    %esi,0x4(%esp)
  800c2a:	75 1c                	jne    800c48 <__umoddi3+0x48>
  800c2c:	39 f7                	cmp    %esi,%edi
  800c2e:	76 50                	jbe    800c80 <__umoddi3+0x80>
  800c30:	89 c8                	mov    %ecx,%eax
  800c32:	89 f2                	mov    %esi,%edx
  800c34:	f7 f7                	div    %edi
  800c36:	89 d0                	mov    %edx,%eax
  800c38:	31 d2                	xor    %edx,%edx
  800c3a:	83 c4 1c             	add    $0x1c,%esp
  800c3d:	5b                   	pop    %ebx
  800c3e:	5e                   	pop    %esi
  800c3f:	5f                   	pop    %edi
  800c40:	5d                   	pop    %ebp
  800c41:	c3                   	ret    
  800c42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c48:	39 f2                	cmp    %esi,%edx
  800c4a:	89 d0                	mov    %edx,%eax
  800c4c:	77 52                	ja     800ca0 <__umoddi3+0xa0>
  800c4e:	0f bd ea             	bsr    %edx,%ebp
  800c51:	83 f5 1f             	xor    $0x1f,%ebp
  800c54:	75 5a                	jne    800cb0 <__umoddi3+0xb0>
  800c56:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800c5a:	0f 82 e0 00 00 00    	jb     800d40 <__umoddi3+0x140>
  800c60:	39 0c 24             	cmp    %ecx,(%esp)
  800c63:	0f 86 d7 00 00 00    	jbe    800d40 <__umoddi3+0x140>
  800c69:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c6d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800c71:	83 c4 1c             	add    $0x1c,%esp
  800c74:	5b                   	pop    %ebx
  800c75:	5e                   	pop    %esi
  800c76:	5f                   	pop    %edi
  800c77:	5d                   	pop    %ebp
  800c78:	c3                   	ret    
  800c79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c80:	85 ff                	test   %edi,%edi
  800c82:	89 fd                	mov    %edi,%ebp
  800c84:	75 0b                	jne    800c91 <__umoddi3+0x91>
  800c86:	b8 01 00 00 00       	mov    $0x1,%eax
  800c8b:	31 d2                	xor    %edx,%edx
  800c8d:	f7 f7                	div    %edi
  800c8f:	89 c5                	mov    %eax,%ebp
  800c91:	89 f0                	mov    %esi,%eax
  800c93:	31 d2                	xor    %edx,%edx
  800c95:	f7 f5                	div    %ebp
  800c97:	89 c8                	mov    %ecx,%eax
  800c99:	f7 f5                	div    %ebp
  800c9b:	89 d0                	mov    %edx,%eax
  800c9d:	eb 99                	jmp    800c38 <__umoddi3+0x38>
  800c9f:	90                   	nop
  800ca0:	89 c8                	mov    %ecx,%eax
  800ca2:	89 f2                	mov    %esi,%edx
  800ca4:	83 c4 1c             	add    $0x1c,%esp
  800ca7:	5b                   	pop    %ebx
  800ca8:	5e                   	pop    %esi
  800ca9:	5f                   	pop    %edi
  800caa:	5d                   	pop    %ebp
  800cab:	c3                   	ret    
  800cac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800cb0:	8b 34 24             	mov    (%esp),%esi
  800cb3:	bf 20 00 00 00       	mov    $0x20,%edi
  800cb8:	89 e9                	mov    %ebp,%ecx
  800cba:	29 ef                	sub    %ebp,%edi
  800cbc:	d3 e0                	shl    %cl,%eax
  800cbe:	89 f9                	mov    %edi,%ecx
  800cc0:	89 f2                	mov    %esi,%edx
  800cc2:	d3 ea                	shr    %cl,%edx
  800cc4:	89 e9                	mov    %ebp,%ecx
  800cc6:	09 c2                	or     %eax,%edx
  800cc8:	89 d8                	mov    %ebx,%eax
  800cca:	89 14 24             	mov    %edx,(%esp)
  800ccd:	89 f2                	mov    %esi,%edx
  800ccf:	d3 e2                	shl    %cl,%edx
  800cd1:	89 f9                	mov    %edi,%ecx
  800cd3:	89 54 24 04          	mov    %edx,0x4(%esp)
  800cd7:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800cdb:	d3 e8                	shr    %cl,%eax
  800cdd:	89 e9                	mov    %ebp,%ecx
  800cdf:	89 c6                	mov    %eax,%esi
  800ce1:	d3 e3                	shl    %cl,%ebx
  800ce3:	89 f9                	mov    %edi,%ecx
  800ce5:	89 d0                	mov    %edx,%eax
  800ce7:	d3 e8                	shr    %cl,%eax
  800ce9:	89 e9                	mov    %ebp,%ecx
  800ceb:	09 d8                	or     %ebx,%eax
  800ced:	89 d3                	mov    %edx,%ebx
  800cef:	89 f2                	mov    %esi,%edx
  800cf1:	f7 34 24             	divl   (%esp)
  800cf4:	89 d6                	mov    %edx,%esi
  800cf6:	d3 e3                	shl    %cl,%ebx
  800cf8:	f7 64 24 04          	mull   0x4(%esp)
  800cfc:	39 d6                	cmp    %edx,%esi
  800cfe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d02:	89 d1                	mov    %edx,%ecx
  800d04:	89 c3                	mov    %eax,%ebx
  800d06:	72 08                	jb     800d10 <__umoddi3+0x110>
  800d08:	75 11                	jne    800d1b <__umoddi3+0x11b>
  800d0a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800d0e:	73 0b                	jae    800d1b <__umoddi3+0x11b>
  800d10:	2b 44 24 04          	sub    0x4(%esp),%eax
  800d14:	1b 14 24             	sbb    (%esp),%edx
  800d17:	89 d1                	mov    %edx,%ecx
  800d19:	89 c3                	mov    %eax,%ebx
  800d1b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800d1f:	29 da                	sub    %ebx,%edx
  800d21:	19 ce                	sbb    %ecx,%esi
  800d23:	89 f9                	mov    %edi,%ecx
  800d25:	89 f0                	mov    %esi,%eax
  800d27:	d3 e0                	shl    %cl,%eax
  800d29:	89 e9                	mov    %ebp,%ecx
  800d2b:	d3 ea                	shr    %cl,%edx
  800d2d:	89 e9                	mov    %ebp,%ecx
  800d2f:	d3 ee                	shr    %cl,%esi
  800d31:	09 d0                	or     %edx,%eax
  800d33:	89 f2                	mov    %esi,%edx
  800d35:	83 c4 1c             	add    $0x1c,%esp
  800d38:	5b                   	pop    %ebx
  800d39:	5e                   	pop    %esi
  800d3a:	5f                   	pop    %edi
  800d3b:	5d                   	pop    %ebp
  800d3c:	c3                   	ret    
  800d3d:	8d 76 00             	lea    0x0(%esi),%esi
  800d40:	29 f9                	sub    %edi,%ecx
  800d42:	19 d6                	sbb    %edx,%esi
  800d44:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d48:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d4c:	e9 18 ff ff ff       	jmp    800c69 <__umoddi3+0x69>


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
  80003c:	56                   	push   %esi
  80003d:	53                   	push   %ebx
  80003e:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800041:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	//thisenv = 0;
	envid_t id = sys_getenvid();
  800044:	e8 c9 00 00 00       	call   800112 <sys_getenvid>
	thisenv = &envs[ENVX(id)];
  800049:	25 ff 03 00 00       	and    $0x3ff,%eax
  80004e:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800051:	c1 e0 05             	shl    $0x5,%eax
  800054:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800059:	a3 04 10 80 00       	mov    %eax,0x801004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  80005e:	85 db                	test   %ebx,%ebx
  800060:	7e 07                	jle    800069 <libmain+0x30>
		binaryname = argv[0];
  800062:	8b 06                	mov    (%esi),%eax
  800064:	a3 00 10 80 00       	mov    %eax,0x801000

	// call user main routine
	umain(argc, argv);
  800069:	83 ec 08             	sub    $0x8,%esp
  80006c:	56                   	push   %esi
  80006d:	53                   	push   %ebx
  80006e:	e8 c0 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800073:	e8 0a 00 00 00       	call   800082 <exit>
}
  800078:	83 c4 10             	add    $0x10,%esp
  80007b:	8d 65 f8             	lea    -0x8(%ebp),%esp
  80007e:	5b                   	pop    %ebx
  80007f:	5e                   	pop    %esi
  800080:	5d                   	pop    %ebp
  800081:	c3                   	ret    

00800082 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800082:	55                   	push   %ebp
  800083:	89 e5                	mov    %esp,%ebp
  800085:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800088:	6a 00                	push   $0x0
  80008a:	e8 42 00 00 00       	call   8000d1 <sys_env_destroy>
}
  80008f:	83 c4 10             	add    $0x10,%esp
  800092:	c9                   	leave  
  800093:	c3                   	ret    

00800094 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800094:	55                   	push   %ebp
  800095:	89 e5                	mov    %esp,%ebp
  800097:	57                   	push   %edi
  800098:	56                   	push   %esi
  800099:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80009a:	b8 00 00 00 00       	mov    $0x0,%eax
  80009f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000a2:	8b 55 08             	mov    0x8(%ebp),%edx
  8000a5:	89 c3                	mov    %eax,%ebx
  8000a7:	89 c7                	mov    %eax,%edi
  8000a9:	89 c6                	mov    %eax,%esi
  8000ab:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000ad:	5b                   	pop    %ebx
  8000ae:	5e                   	pop    %esi
  8000af:	5f                   	pop    %edi
  8000b0:	5d                   	pop    %ebp
  8000b1:	c3                   	ret    

008000b2 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000b2:	55                   	push   %ebp
  8000b3:	89 e5                	mov    %esp,%ebp
  8000b5:	57                   	push   %edi
  8000b6:	56                   	push   %esi
  8000b7:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000b8:	ba 00 00 00 00       	mov    $0x0,%edx
  8000bd:	b8 01 00 00 00       	mov    $0x1,%eax
  8000c2:	89 d1                	mov    %edx,%ecx
  8000c4:	89 d3                	mov    %edx,%ebx
  8000c6:	89 d7                	mov    %edx,%edi
  8000c8:	89 d6                	mov    %edx,%esi
  8000ca:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000cc:	5b                   	pop    %ebx
  8000cd:	5e                   	pop    %esi
  8000ce:	5f                   	pop    %edi
  8000cf:	5d                   	pop    %ebp
  8000d0:	c3                   	ret    

008000d1 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000d1:	55                   	push   %ebp
  8000d2:	89 e5                	mov    %esp,%ebp
  8000d4:	57                   	push   %edi
  8000d5:	56                   	push   %esi
  8000d6:	53                   	push   %ebx
  8000d7:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000da:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000df:	b8 03 00 00 00       	mov    $0x3,%eax
  8000e4:	8b 55 08             	mov    0x8(%ebp),%edx
  8000e7:	89 cb                	mov    %ecx,%ebx
  8000e9:	89 cf                	mov    %ecx,%edi
  8000eb:	89 ce                	mov    %ecx,%esi
  8000ed:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000ef:	85 c0                	test   %eax,%eax
  8000f1:	7e 17                	jle    80010a <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000f3:	83 ec 0c             	sub    $0xc,%esp
  8000f6:	50                   	push   %eax
  8000f7:	6a 03                	push   $0x3
  8000f9:	68 8a 0d 80 00       	push   $0x800d8a
  8000fe:	6a 23                	push   $0x23
  800100:	68 a7 0d 80 00       	push   $0x800da7
  800105:	e8 27 00 00 00       	call   800131 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  80010a:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80010d:	5b                   	pop    %ebx
  80010e:	5e                   	pop    %esi
  80010f:	5f                   	pop    %edi
  800110:	5d                   	pop    %ebp
  800111:	c3                   	ret    

00800112 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800112:	55                   	push   %ebp
  800113:	89 e5                	mov    %esp,%ebp
  800115:	57                   	push   %edi
  800116:	56                   	push   %esi
  800117:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800118:	ba 00 00 00 00       	mov    $0x0,%edx
  80011d:	b8 02 00 00 00       	mov    $0x2,%eax
  800122:	89 d1                	mov    %edx,%ecx
  800124:	89 d3                	mov    %edx,%ebx
  800126:	89 d7                	mov    %edx,%edi
  800128:	89 d6                	mov    %edx,%esi
  80012a:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80012c:	5b                   	pop    %ebx
  80012d:	5e                   	pop    %esi
  80012e:	5f                   	pop    %edi
  80012f:	5d                   	pop    %ebp
  800130:	c3                   	ret    

00800131 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800131:	55                   	push   %ebp
  800132:	89 e5                	mov    %esp,%ebp
  800134:	56                   	push   %esi
  800135:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800136:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800139:	8b 35 00 10 80 00    	mov    0x801000,%esi
  80013f:	e8 ce ff ff ff       	call   800112 <sys_getenvid>
  800144:	83 ec 0c             	sub    $0xc,%esp
  800147:	ff 75 0c             	pushl  0xc(%ebp)
  80014a:	ff 75 08             	pushl  0x8(%ebp)
  80014d:	56                   	push   %esi
  80014e:	50                   	push   %eax
  80014f:	68 b8 0d 80 00       	push   $0x800db8
  800154:	e8 b1 00 00 00       	call   80020a <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800159:	83 c4 18             	add    $0x18,%esp
  80015c:	53                   	push   %ebx
  80015d:	ff 75 10             	pushl  0x10(%ebp)
  800160:	e8 54 00 00 00       	call   8001b9 <vcprintf>
	cprintf("\n");
  800165:	c7 04 24 dc 0d 80 00 	movl   $0x800ddc,(%esp)
  80016c:	e8 99 00 00 00       	call   80020a <cprintf>
  800171:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800174:	cc                   	int3   
  800175:	eb fd                	jmp    800174 <_panic+0x43>

00800177 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800177:	55                   	push   %ebp
  800178:	89 e5                	mov    %esp,%ebp
  80017a:	53                   	push   %ebx
  80017b:	83 ec 04             	sub    $0x4,%esp
  80017e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800181:	8b 13                	mov    (%ebx),%edx
  800183:	8d 42 01             	lea    0x1(%edx),%eax
  800186:	89 03                	mov    %eax,(%ebx)
  800188:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80018b:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80018f:	3d ff 00 00 00       	cmp    $0xff,%eax
  800194:	75 1a                	jne    8001b0 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800196:	83 ec 08             	sub    $0x8,%esp
  800199:	68 ff 00 00 00       	push   $0xff
  80019e:	8d 43 08             	lea    0x8(%ebx),%eax
  8001a1:	50                   	push   %eax
  8001a2:	e8 ed fe ff ff       	call   800094 <sys_cputs>
		b->idx = 0;
  8001a7:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001ad:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001b0:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001b4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001b7:	c9                   	leave  
  8001b8:	c3                   	ret    

008001b9 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001b9:	55                   	push   %ebp
  8001ba:	89 e5                	mov    %esp,%ebp
  8001bc:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001c2:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001c9:	00 00 00 
	b.cnt = 0;
  8001cc:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001d3:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001d6:	ff 75 0c             	pushl  0xc(%ebp)
  8001d9:	ff 75 08             	pushl  0x8(%ebp)
  8001dc:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001e2:	50                   	push   %eax
  8001e3:	68 77 01 80 00       	push   $0x800177
  8001e8:	e8 54 01 00 00       	call   800341 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001ed:	83 c4 08             	add    $0x8,%esp
  8001f0:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001f6:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001fc:	50                   	push   %eax
  8001fd:	e8 92 fe ff ff       	call   800094 <sys_cputs>

	return b.cnt;
}
  800202:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800208:	c9                   	leave  
  800209:	c3                   	ret    

0080020a <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80020a:	55                   	push   %ebp
  80020b:	89 e5                	mov    %esp,%ebp
  80020d:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800210:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800213:	50                   	push   %eax
  800214:	ff 75 08             	pushl  0x8(%ebp)
  800217:	e8 9d ff ff ff       	call   8001b9 <vcprintf>
	va_end(ap);

	return cnt;
}
  80021c:	c9                   	leave  
  80021d:	c3                   	ret    

0080021e <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80021e:	55                   	push   %ebp
  80021f:	89 e5                	mov    %esp,%ebp
  800221:	57                   	push   %edi
  800222:	56                   	push   %esi
  800223:	53                   	push   %ebx
  800224:	83 ec 1c             	sub    $0x1c,%esp
  800227:	89 c7                	mov    %eax,%edi
  800229:	89 d6                	mov    %edx,%esi
  80022b:	8b 45 08             	mov    0x8(%ebp),%eax
  80022e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800231:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800234:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800237:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80023a:	bb 00 00 00 00       	mov    $0x0,%ebx
  80023f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800242:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800245:	39 d3                	cmp    %edx,%ebx
  800247:	72 05                	jb     80024e <printnum+0x30>
  800249:	39 45 10             	cmp    %eax,0x10(%ebp)
  80024c:	77 45                	ja     800293 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80024e:	83 ec 0c             	sub    $0xc,%esp
  800251:	ff 75 18             	pushl  0x18(%ebp)
  800254:	8b 45 14             	mov    0x14(%ebp),%eax
  800257:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80025a:	53                   	push   %ebx
  80025b:	ff 75 10             	pushl  0x10(%ebp)
  80025e:	83 ec 08             	sub    $0x8,%esp
  800261:	ff 75 e4             	pushl  -0x1c(%ebp)
  800264:	ff 75 e0             	pushl  -0x20(%ebp)
  800267:	ff 75 dc             	pushl  -0x24(%ebp)
  80026a:	ff 75 d8             	pushl  -0x28(%ebp)
  80026d:	e8 6e 08 00 00       	call   800ae0 <__udivdi3>
  800272:	83 c4 18             	add    $0x18,%esp
  800275:	52                   	push   %edx
  800276:	50                   	push   %eax
  800277:	89 f2                	mov    %esi,%edx
  800279:	89 f8                	mov    %edi,%eax
  80027b:	e8 9e ff ff ff       	call   80021e <printnum>
  800280:	83 c4 20             	add    $0x20,%esp
  800283:	eb 18                	jmp    80029d <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800285:	83 ec 08             	sub    $0x8,%esp
  800288:	56                   	push   %esi
  800289:	ff 75 18             	pushl  0x18(%ebp)
  80028c:	ff d7                	call   *%edi
  80028e:	83 c4 10             	add    $0x10,%esp
  800291:	eb 03                	jmp    800296 <printnum+0x78>
  800293:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800296:	83 eb 01             	sub    $0x1,%ebx
  800299:	85 db                	test   %ebx,%ebx
  80029b:	7f e8                	jg     800285 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80029d:	83 ec 08             	sub    $0x8,%esp
  8002a0:	56                   	push   %esi
  8002a1:	83 ec 04             	sub    $0x4,%esp
  8002a4:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002a7:	ff 75 e0             	pushl  -0x20(%ebp)
  8002aa:	ff 75 dc             	pushl  -0x24(%ebp)
  8002ad:	ff 75 d8             	pushl  -0x28(%ebp)
  8002b0:	e8 5b 09 00 00       	call   800c10 <__umoddi3>
  8002b5:	83 c4 14             	add    $0x14,%esp
  8002b8:	0f be 80 de 0d 80 00 	movsbl 0x800dde(%eax),%eax
  8002bf:	50                   	push   %eax
  8002c0:	ff d7                	call   *%edi
}
  8002c2:	83 c4 10             	add    $0x10,%esp
  8002c5:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002c8:	5b                   	pop    %ebx
  8002c9:	5e                   	pop    %esi
  8002ca:	5f                   	pop    %edi
  8002cb:	5d                   	pop    %ebp
  8002cc:	c3                   	ret    

008002cd <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002cd:	55                   	push   %ebp
  8002ce:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002d0:	83 fa 01             	cmp    $0x1,%edx
  8002d3:	7e 0e                	jle    8002e3 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002d5:	8b 10                	mov    (%eax),%edx
  8002d7:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002da:	89 08                	mov    %ecx,(%eax)
  8002dc:	8b 02                	mov    (%edx),%eax
  8002de:	8b 52 04             	mov    0x4(%edx),%edx
  8002e1:	eb 22                	jmp    800305 <getuint+0x38>
	else if (lflag)
  8002e3:	85 d2                	test   %edx,%edx
  8002e5:	74 10                	je     8002f7 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002e7:	8b 10                	mov    (%eax),%edx
  8002e9:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002ec:	89 08                	mov    %ecx,(%eax)
  8002ee:	8b 02                	mov    (%edx),%eax
  8002f0:	ba 00 00 00 00       	mov    $0x0,%edx
  8002f5:	eb 0e                	jmp    800305 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8002f7:	8b 10                	mov    (%eax),%edx
  8002f9:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002fc:	89 08                	mov    %ecx,(%eax)
  8002fe:	8b 02                	mov    (%edx),%eax
  800300:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800305:	5d                   	pop    %ebp
  800306:	c3                   	ret    

00800307 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800307:	55                   	push   %ebp
  800308:	89 e5                	mov    %esp,%ebp
  80030a:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80030d:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800311:	8b 10                	mov    (%eax),%edx
  800313:	3b 50 04             	cmp    0x4(%eax),%edx
  800316:	73 0a                	jae    800322 <sprintputch+0x1b>
		*b->buf++ = ch;
  800318:	8d 4a 01             	lea    0x1(%edx),%ecx
  80031b:	89 08                	mov    %ecx,(%eax)
  80031d:	8b 45 08             	mov    0x8(%ebp),%eax
  800320:	88 02                	mov    %al,(%edx)
}
  800322:	5d                   	pop    %ebp
  800323:	c3                   	ret    

00800324 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800324:	55                   	push   %ebp
  800325:	89 e5                	mov    %esp,%ebp
  800327:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80032a:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80032d:	50                   	push   %eax
  80032e:	ff 75 10             	pushl  0x10(%ebp)
  800331:	ff 75 0c             	pushl  0xc(%ebp)
  800334:	ff 75 08             	pushl  0x8(%ebp)
  800337:	e8 05 00 00 00       	call   800341 <vprintfmt>
	va_end(ap);
}
  80033c:	83 c4 10             	add    $0x10,%esp
  80033f:	c9                   	leave  
  800340:	c3                   	ret    

00800341 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800341:	55                   	push   %ebp
  800342:	89 e5                	mov    %esp,%ebp
  800344:	57                   	push   %edi
  800345:	56                   	push   %esi
  800346:	53                   	push   %ebx
  800347:	83 ec 2c             	sub    $0x2c,%esp
  80034a:	8b 75 08             	mov    0x8(%ebp),%esi
  80034d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800350:	8b 7d 10             	mov    0x10(%ebp),%edi
  800353:	eb 12                	jmp    800367 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800355:	85 c0                	test   %eax,%eax
  800357:	0f 84 89 03 00 00    	je     8006e6 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  80035d:	83 ec 08             	sub    $0x8,%esp
  800360:	53                   	push   %ebx
  800361:	50                   	push   %eax
  800362:	ff d6                	call   *%esi
  800364:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800367:	83 c7 01             	add    $0x1,%edi
  80036a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80036e:	83 f8 25             	cmp    $0x25,%eax
  800371:	75 e2                	jne    800355 <vprintfmt+0x14>
  800373:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800377:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80037e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800385:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80038c:	ba 00 00 00 00       	mov    $0x0,%edx
  800391:	eb 07                	jmp    80039a <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800393:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800396:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80039a:	8d 47 01             	lea    0x1(%edi),%eax
  80039d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003a0:	0f b6 07             	movzbl (%edi),%eax
  8003a3:	0f b6 c8             	movzbl %al,%ecx
  8003a6:	83 e8 23             	sub    $0x23,%eax
  8003a9:	3c 55                	cmp    $0x55,%al
  8003ab:	0f 87 1a 03 00 00    	ja     8006cb <vprintfmt+0x38a>
  8003b1:	0f b6 c0             	movzbl %al,%eax
  8003b4:	ff 24 85 80 0e 80 00 	jmp    *0x800e80(,%eax,4)
  8003bb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003be:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003c2:	eb d6                	jmp    80039a <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003c7:	b8 00 00 00 00       	mov    $0x0,%eax
  8003cc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003cf:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003d2:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  8003d6:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  8003d9:	8d 51 d0             	lea    -0x30(%ecx),%edx
  8003dc:	83 fa 09             	cmp    $0x9,%edx
  8003df:	77 39                	ja     80041a <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003e1:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003e4:	eb e9                	jmp    8003cf <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003e6:	8b 45 14             	mov    0x14(%ebp),%eax
  8003e9:	8d 48 04             	lea    0x4(%eax),%ecx
  8003ec:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003ef:	8b 00                	mov    (%eax),%eax
  8003f1:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003f7:	eb 27                	jmp    800420 <vprintfmt+0xdf>
  8003f9:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003fc:	85 c0                	test   %eax,%eax
  8003fe:	b9 00 00 00 00       	mov    $0x0,%ecx
  800403:	0f 49 c8             	cmovns %eax,%ecx
  800406:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800409:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80040c:	eb 8c                	jmp    80039a <vprintfmt+0x59>
  80040e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800411:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800418:	eb 80                	jmp    80039a <vprintfmt+0x59>
  80041a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80041d:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800420:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800424:	0f 89 70 ff ff ff    	jns    80039a <vprintfmt+0x59>
				width = precision, precision = -1;
  80042a:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80042d:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800430:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800437:	e9 5e ff ff ff       	jmp    80039a <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80043c:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80043f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800442:	e9 53 ff ff ff       	jmp    80039a <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800447:	8b 45 14             	mov    0x14(%ebp),%eax
  80044a:	8d 50 04             	lea    0x4(%eax),%edx
  80044d:	89 55 14             	mov    %edx,0x14(%ebp)
  800450:	83 ec 08             	sub    $0x8,%esp
  800453:	53                   	push   %ebx
  800454:	ff 30                	pushl  (%eax)
  800456:	ff d6                	call   *%esi
			break;
  800458:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80045b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80045e:	e9 04 ff ff ff       	jmp    800367 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800463:	8b 45 14             	mov    0x14(%ebp),%eax
  800466:	8d 50 04             	lea    0x4(%eax),%edx
  800469:	89 55 14             	mov    %edx,0x14(%ebp)
  80046c:	8b 00                	mov    (%eax),%eax
  80046e:	99                   	cltd   
  80046f:	31 d0                	xor    %edx,%eax
  800471:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800473:	83 f8 07             	cmp    $0x7,%eax
  800476:	7f 0b                	jg     800483 <vprintfmt+0x142>
  800478:	8b 14 85 e0 0f 80 00 	mov    0x800fe0(,%eax,4),%edx
  80047f:	85 d2                	test   %edx,%edx
  800481:	75 18                	jne    80049b <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800483:	50                   	push   %eax
  800484:	68 f6 0d 80 00       	push   $0x800df6
  800489:	53                   	push   %ebx
  80048a:	56                   	push   %esi
  80048b:	e8 94 fe ff ff       	call   800324 <printfmt>
  800490:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800493:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800496:	e9 cc fe ff ff       	jmp    800367 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80049b:	52                   	push   %edx
  80049c:	68 ff 0d 80 00       	push   $0x800dff
  8004a1:	53                   	push   %ebx
  8004a2:	56                   	push   %esi
  8004a3:	e8 7c fe ff ff       	call   800324 <printfmt>
  8004a8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004ae:	e9 b4 fe ff ff       	jmp    800367 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004b3:	8b 45 14             	mov    0x14(%ebp),%eax
  8004b6:	8d 50 04             	lea    0x4(%eax),%edx
  8004b9:	89 55 14             	mov    %edx,0x14(%ebp)
  8004bc:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004be:	85 ff                	test   %edi,%edi
  8004c0:	b8 ef 0d 80 00       	mov    $0x800def,%eax
  8004c5:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004c8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004cc:	0f 8e 94 00 00 00    	jle    800566 <vprintfmt+0x225>
  8004d2:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004d6:	0f 84 98 00 00 00    	je     800574 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004dc:	83 ec 08             	sub    $0x8,%esp
  8004df:	ff 75 d0             	pushl  -0x30(%ebp)
  8004e2:	57                   	push   %edi
  8004e3:	e8 86 02 00 00       	call   80076e <strnlen>
  8004e8:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004eb:	29 c1                	sub    %eax,%ecx
  8004ed:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  8004f0:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004f3:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004f7:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004fa:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004fd:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004ff:	eb 0f                	jmp    800510 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800501:	83 ec 08             	sub    $0x8,%esp
  800504:	53                   	push   %ebx
  800505:	ff 75 e0             	pushl  -0x20(%ebp)
  800508:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80050a:	83 ef 01             	sub    $0x1,%edi
  80050d:	83 c4 10             	add    $0x10,%esp
  800510:	85 ff                	test   %edi,%edi
  800512:	7f ed                	jg     800501 <vprintfmt+0x1c0>
  800514:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800517:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80051a:	85 c9                	test   %ecx,%ecx
  80051c:	b8 00 00 00 00       	mov    $0x0,%eax
  800521:	0f 49 c1             	cmovns %ecx,%eax
  800524:	29 c1                	sub    %eax,%ecx
  800526:	89 75 08             	mov    %esi,0x8(%ebp)
  800529:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80052c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80052f:	89 cb                	mov    %ecx,%ebx
  800531:	eb 4d                	jmp    800580 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800533:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800537:	74 1b                	je     800554 <vprintfmt+0x213>
  800539:	0f be c0             	movsbl %al,%eax
  80053c:	83 e8 20             	sub    $0x20,%eax
  80053f:	83 f8 5e             	cmp    $0x5e,%eax
  800542:	76 10                	jbe    800554 <vprintfmt+0x213>
					putch('?', putdat);
  800544:	83 ec 08             	sub    $0x8,%esp
  800547:	ff 75 0c             	pushl  0xc(%ebp)
  80054a:	6a 3f                	push   $0x3f
  80054c:	ff 55 08             	call   *0x8(%ebp)
  80054f:	83 c4 10             	add    $0x10,%esp
  800552:	eb 0d                	jmp    800561 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800554:	83 ec 08             	sub    $0x8,%esp
  800557:	ff 75 0c             	pushl  0xc(%ebp)
  80055a:	52                   	push   %edx
  80055b:	ff 55 08             	call   *0x8(%ebp)
  80055e:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800561:	83 eb 01             	sub    $0x1,%ebx
  800564:	eb 1a                	jmp    800580 <vprintfmt+0x23f>
  800566:	89 75 08             	mov    %esi,0x8(%ebp)
  800569:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80056c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80056f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800572:	eb 0c                	jmp    800580 <vprintfmt+0x23f>
  800574:	89 75 08             	mov    %esi,0x8(%ebp)
  800577:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80057a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80057d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800580:	83 c7 01             	add    $0x1,%edi
  800583:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800587:	0f be d0             	movsbl %al,%edx
  80058a:	85 d2                	test   %edx,%edx
  80058c:	74 23                	je     8005b1 <vprintfmt+0x270>
  80058e:	85 f6                	test   %esi,%esi
  800590:	78 a1                	js     800533 <vprintfmt+0x1f2>
  800592:	83 ee 01             	sub    $0x1,%esi
  800595:	79 9c                	jns    800533 <vprintfmt+0x1f2>
  800597:	89 df                	mov    %ebx,%edi
  800599:	8b 75 08             	mov    0x8(%ebp),%esi
  80059c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80059f:	eb 18                	jmp    8005b9 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005a1:	83 ec 08             	sub    $0x8,%esp
  8005a4:	53                   	push   %ebx
  8005a5:	6a 20                	push   $0x20
  8005a7:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005a9:	83 ef 01             	sub    $0x1,%edi
  8005ac:	83 c4 10             	add    $0x10,%esp
  8005af:	eb 08                	jmp    8005b9 <vprintfmt+0x278>
  8005b1:	89 df                	mov    %ebx,%edi
  8005b3:	8b 75 08             	mov    0x8(%ebp),%esi
  8005b6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005b9:	85 ff                	test   %edi,%edi
  8005bb:	7f e4                	jg     8005a1 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005bd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005c0:	e9 a2 fd ff ff       	jmp    800367 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005c5:	83 fa 01             	cmp    $0x1,%edx
  8005c8:	7e 16                	jle    8005e0 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  8005ca:	8b 45 14             	mov    0x14(%ebp),%eax
  8005cd:	8d 50 08             	lea    0x8(%eax),%edx
  8005d0:	89 55 14             	mov    %edx,0x14(%ebp)
  8005d3:	8b 50 04             	mov    0x4(%eax),%edx
  8005d6:	8b 00                	mov    (%eax),%eax
  8005d8:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005db:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005de:	eb 32                	jmp    800612 <vprintfmt+0x2d1>
	else if (lflag)
  8005e0:	85 d2                	test   %edx,%edx
  8005e2:	74 18                	je     8005fc <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  8005e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e7:	8d 50 04             	lea    0x4(%eax),%edx
  8005ea:	89 55 14             	mov    %edx,0x14(%ebp)
  8005ed:	8b 00                	mov    (%eax),%eax
  8005ef:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005f2:	89 c1                	mov    %eax,%ecx
  8005f4:	c1 f9 1f             	sar    $0x1f,%ecx
  8005f7:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005fa:	eb 16                	jmp    800612 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  8005fc:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ff:	8d 50 04             	lea    0x4(%eax),%edx
  800602:	89 55 14             	mov    %edx,0x14(%ebp)
  800605:	8b 00                	mov    (%eax),%eax
  800607:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80060a:	89 c1                	mov    %eax,%ecx
  80060c:	c1 f9 1f             	sar    $0x1f,%ecx
  80060f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800612:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800615:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800618:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80061d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800621:	79 74                	jns    800697 <vprintfmt+0x356>
				putch('-', putdat);
  800623:	83 ec 08             	sub    $0x8,%esp
  800626:	53                   	push   %ebx
  800627:	6a 2d                	push   $0x2d
  800629:	ff d6                	call   *%esi
				num = -(long long) num;
  80062b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80062e:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800631:	f7 d8                	neg    %eax
  800633:	83 d2 00             	adc    $0x0,%edx
  800636:	f7 da                	neg    %edx
  800638:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80063b:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800640:	eb 55                	jmp    800697 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800642:	8d 45 14             	lea    0x14(%ebp),%eax
  800645:	e8 83 fc ff ff       	call   8002cd <getuint>
			base = 10;
  80064a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80064f:	eb 46                	jmp    800697 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800651:	8d 45 14             	lea    0x14(%ebp),%eax
  800654:	e8 74 fc ff ff       	call   8002cd <getuint>
			base = 8;
  800659:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80065e:	eb 37                	jmp    800697 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  800660:	83 ec 08             	sub    $0x8,%esp
  800663:	53                   	push   %ebx
  800664:	6a 30                	push   $0x30
  800666:	ff d6                	call   *%esi
			putch('x', putdat);
  800668:	83 c4 08             	add    $0x8,%esp
  80066b:	53                   	push   %ebx
  80066c:	6a 78                	push   $0x78
  80066e:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800670:	8b 45 14             	mov    0x14(%ebp),%eax
  800673:	8d 50 04             	lea    0x4(%eax),%edx
  800676:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800679:	8b 00                	mov    (%eax),%eax
  80067b:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800680:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800683:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800688:	eb 0d                	jmp    800697 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  80068a:	8d 45 14             	lea    0x14(%ebp),%eax
  80068d:	e8 3b fc ff ff       	call   8002cd <getuint>
			base = 16;
  800692:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800697:	83 ec 0c             	sub    $0xc,%esp
  80069a:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80069e:	57                   	push   %edi
  80069f:	ff 75 e0             	pushl  -0x20(%ebp)
  8006a2:	51                   	push   %ecx
  8006a3:	52                   	push   %edx
  8006a4:	50                   	push   %eax
  8006a5:	89 da                	mov    %ebx,%edx
  8006a7:	89 f0                	mov    %esi,%eax
  8006a9:	e8 70 fb ff ff       	call   80021e <printnum>
			break;
  8006ae:	83 c4 20             	add    $0x20,%esp
  8006b1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006b4:	e9 ae fc ff ff       	jmp    800367 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006b9:	83 ec 08             	sub    $0x8,%esp
  8006bc:	53                   	push   %ebx
  8006bd:	51                   	push   %ecx
  8006be:	ff d6                	call   *%esi
			break;
  8006c0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006c3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006c6:	e9 9c fc ff ff       	jmp    800367 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006cb:	83 ec 08             	sub    $0x8,%esp
  8006ce:	53                   	push   %ebx
  8006cf:	6a 25                	push   $0x25
  8006d1:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006d3:	83 c4 10             	add    $0x10,%esp
  8006d6:	eb 03                	jmp    8006db <vprintfmt+0x39a>
  8006d8:	83 ef 01             	sub    $0x1,%edi
  8006db:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006df:	75 f7                	jne    8006d8 <vprintfmt+0x397>
  8006e1:	e9 81 fc ff ff       	jmp    800367 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006e9:	5b                   	pop    %ebx
  8006ea:	5e                   	pop    %esi
  8006eb:	5f                   	pop    %edi
  8006ec:	5d                   	pop    %ebp
  8006ed:	c3                   	ret    

008006ee <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006ee:	55                   	push   %ebp
  8006ef:	89 e5                	mov    %esp,%ebp
  8006f1:	83 ec 18             	sub    $0x18,%esp
  8006f4:	8b 45 08             	mov    0x8(%ebp),%eax
  8006f7:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006fa:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006fd:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800701:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800704:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80070b:	85 c0                	test   %eax,%eax
  80070d:	74 26                	je     800735 <vsnprintf+0x47>
  80070f:	85 d2                	test   %edx,%edx
  800711:	7e 22                	jle    800735 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800713:	ff 75 14             	pushl  0x14(%ebp)
  800716:	ff 75 10             	pushl  0x10(%ebp)
  800719:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80071c:	50                   	push   %eax
  80071d:	68 07 03 80 00       	push   $0x800307
  800722:	e8 1a fc ff ff       	call   800341 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800727:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80072a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80072d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800730:	83 c4 10             	add    $0x10,%esp
  800733:	eb 05                	jmp    80073a <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800735:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80073a:	c9                   	leave  
  80073b:	c3                   	ret    

0080073c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80073c:	55                   	push   %ebp
  80073d:	89 e5                	mov    %esp,%ebp
  80073f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800742:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800745:	50                   	push   %eax
  800746:	ff 75 10             	pushl  0x10(%ebp)
  800749:	ff 75 0c             	pushl  0xc(%ebp)
  80074c:	ff 75 08             	pushl  0x8(%ebp)
  80074f:	e8 9a ff ff ff       	call   8006ee <vsnprintf>
	va_end(ap);

	return rc;
}
  800754:	c9                   	leave  
  800755:	c3                   	ret    

00800756 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800756:	55                   	push   %ebp
  800757:	89 e5                	mov    %esp,%ebp
  800759:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80075c:	b8 00 00 00 00       	mov    $0x0,%eax
  800761:	eb 03                	jmp    800766 <strlen+0x10>
		n++;
  800763:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800766:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80076a:	75 f7                	jne    800763 <strlen+0xd>
		n++;
	return n;
}
  80076c:	5d                   	pop    %ebp
  80076d:	c3                   	ret    

0080076e <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80076e:	55                   	push   %ebp
  80076f:	89 e5                	mov    %esp,%ebp
  800771:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800774:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800777:	ba 00 00 00 00       	mov    $0x0,%edx
  80077c:	eb 03                	jmp    800781 <strnlen+0x13>
		n++;
  80077e:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800781:	39 c2                	cmp    %eax,%edx
  800783:	74 08                	je     80078d <strnlen+0x1f>
  800785:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800789:	75 f3                	jne    80077e <strnlen+0x10>
  80078b:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80078d:	5d                   	pop    %ebp
  80078e:	c3                   	ret    

0080078f <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80078f:	55                   	push   %ebp
  800790:	89 e5                	mov    %esp,%ebp
  800792:	53                   	push   %ebx
  800793:	8b 45 08             	mov    0x8(%ebp),%eax
  800796:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800799:	89 c2                	mov    %eax,%edx
  80079b:	83 c2 01             	add    $0x1,%edx
  80079e:	83 c1 01             	add    $0x1,%ecx
  8007a1:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007a5:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007a8:	84 db                	test   %bl,%bl
  8007aa:	75 ef                	jne    80079b <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007ac:	5b                   	pop    %ebx
  8007ad:	5d                   	pop    %ebp
  8007ae:	c3                   	ret    

008007af <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007af:	55                   	push   %ebp
  8007b0:	89 e5                	mov    %esp,%ebp
  8007b2:	53                   	push   %ebx
  8007b3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007b6:	53                   	push   %ebx
  8007b7:	e8 9a ff ff ff       	call   800756 <strlen>
  8007bc:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007bf:	ff 75 0c             	pushl  0xc(%ebp)
  8007c2:	01 d8                	add    %ebx,%eax
  8007c4:	50                   	push   %eax
  8007c5:	e8 c5 ff ff ff       	call   80078f <strcpy>
	return dst;
}
  8007ca:	89 d8                	mov    %ebx,%eax
  8007cc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007cf:	c9                   	leave  
  8007d0:	c3                   	ret    

008007d1 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007d1:	55                   	push   %ebp
  8007d2:	89 e5                	mov    %esp,%ebp
  8007d4:	56                   	push   %esi
  8007d5:	53                   	push   %ebx
  8007d6:	8b 75 08             	mov    0x8(%ebp),%esi
  8007d9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007dc:	89 f3                	mov    %esi,%ebx
  8007de:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007e1:	89 f2                	mov    %esi,%edx
  8007e3:	eb 0f                	jmp    8007f4 <strncpy+0x23>
		*dst++ = *src;
  8007e5:	83 c2 01             	add    $0x1,%edx
  8007e8:	0f b6 01             	movzbl (%ecx),%eax
  8007eb:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007ee:	80 39 01             	cmpb   $0x1,(%ecx)
  8007f1:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007f4:	39 da                	cmp    %ebx,%edx
  8007f6:	75 ed                	jne    8007e5 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007f8:	89 f0                	mov    %esi,%eax
  8007fa:	5b                   	pop    %ebx
  8007fb:	5e                   	pop    %esi
  8007fc:	5d                   	pop    %ebp
  8007fd:	c3                   	ret    

008007fe <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007fe:	55                   	push   %ebp
  8007ff:	89 e5                	mov    %esp,%ebp
  800801:	56                   	push   %esi
  800802:	53                   	push   %ebx
  800803:	8b 75 08             	mov    0x8(%ebp),%esi
  800806:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800809:	8b 55 10             	mov    0x10(%ebp),%edx
  80080c:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80080e:	85 d2                	test   %edx,%edx
  800810:	74 21                	je     800833 <strlcpy+0x35>
  800812:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800816:	89 f2                	mov    %esi,%edx
  800818:	eb 09                	jmp    800823 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80081a:	83 c2 01             	add    $0x1,%edx
  80081d:	83 c1 01             	add    $0x1,%ecx
  800820:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800823:	39 c2                	cmp    %eax,%edx
  800825:	74 09                	je     800830 <strlcpy+0x32>
  800827:	0f b6 19             	movzbl (%ecx),%ebx
  80082a:	84 db                	test   %bl,%bl
  80082c:	75 ec                	jne    80081a <strlcpy+0x1c>
  80082e:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800830:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800833:	29 f0                	sub    %esi,%eax
}
  800835:	5b                   	pop    %ebx
  800836:	5e                   	pop    %esi
  800837:	5d                   	pop    %ebp
  800838:	c3                   	ret    

00800839 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800839:	55                   	push   %ebp
  80083a:	89 e5                	mov    %esp,%ebp
  80083c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80083f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800842:	eb 06                	jmp    80084a <strcmp+0x11>
		p++, q++;
  800844:	83 c1 01             	add    $0x1,%ecx
  800847:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80084a:	0f b6 01             	movzbl (%ecx),%eax
  80084d:	84 c0                	test   %al,%al
  80084f:	74 04                	je     800855 <strcmp+0x1c>
  800851:	3a 02                	cmp    (%edx),%al
  800853:	74 ef                	je     800844 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800855:	0f b6 c0             	movzbl %al,%eax
  800858:	0f b6 12             	movzbl (%edx),%edx
  80085b:	29 d0                	sub    %edx,%eax
}
  80085d:	5d                   	pop    %ebp
  80085e:	c3                   	ret    

0080085f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80085f:	55                   	push   %ebp
  800860:	89 e5                	mov    %esp,%ebp
  800862:	53                   	push   %ebx
  800863:	8b 45 08             	mov    0x8(%ebp),%eax
  800866:	8b 55 0c             	mov    0xc(%ebp),%edx
  800869:	89 c3                	mov    %eax,%ebx
  80086b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80086e:	eb 06                	jmp    800876 <strncmp+0x17>
		n--, p++, q++;
  800870:	83 c0 01             	add    $0x1,%eax
  800873:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800876:	39 d8                	cmp    %ebx,%eax
  800878:	74 15                	je     80088f <strncmp+0x30>
  80087a:	0f b6 08             	movzbl (%eax),%ecx
  80087d:	84 c9                	test   %cl,%cl
  80087f:	74 04                	je     800885 <strncmp+0x26>
  800881:	3a 0a                	cmp    (%edx),%cl
  800883:	74 eb                	je     800870 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800885:	0f b6 00             	movzbl (%eax),%eax
  800888:	0f b6 12             	movzbl (%edx),%edx
  80088b:	29 d0                	sub    %edx,%eax
  80088d:	eb 05                	jmp    800894 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80088f:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800894:	5b                   	pop    %ebx
  800895:	5d                   	pop    %ebp
  800896:	c3                   	ret    

00800897 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800897:	55                   	push   %ebp
  800898:	89 e5                	mov    %esp,%ebp
  80089a:	8b 45 08             	mov    0x8(%ebp),%eax
  80089d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008a1:	eb 07                	jmp    8008aa <strchr+0x13>
		if (*s == c)
  8008a3:	38 ca                	cmp    %cl,%dl
  8008a5:	74 0f                	je     8008b6 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008a7:	83 c0 01             	add    $0x1,%eax
  8008aa:	0f b6 10             	movzbl (%eax),%edx
  8008ad:	84 d2                	test   %dl,%dl
  8008af:	75 f2                	jne    8008a3 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008b1:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008b6:	5d                   	pop    %ebp
  8008b7:	c3                   	ret    

008008b8 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008b8:	55                   	push   %ebp
  8008b9:	89 e5                	mov    %esp,%ebp
  8008bb:	8b 45 08             	mov    0x8(%ebp),%eax
  8008be:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008c2:	eb 03                	jmp    8008c7 <strfind+0xf>
  8008c4:	83 c0 01             	add    $0x1,%eax
  8008c7:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008ca:	38 ca                	cmp    %cl,%dl
  8008cc:	74 04                	je     8008d2 <strfind+0x1a>
  8008ce:	84 d2                	test   %dl,%dl
  8008d0:	75 f2                	jne    8008c4 <strfind+0xc>
			break;
	return (char *) s;
}
  8008d2:	5d                   	pop    %ebp
  8008d3:	c3                   	ret    

008008d4 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008d4:	55                   	push   %ebp
  8008d5:	89 e5                	mov    %esp,%ebp
  8008d7:	57                   	push   %edi
  8008d8:	56                   	push   %esi
  8008d9:	53                   	push   %ebx
  8008da:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008dd:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008e0:	85 c9                	test   %ecx,%ecx
  8008e2:	74 36                	je     80091a <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008e4:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008ea:	75 28                	jne    800914 <memset+0x40>
  8008ec:	f6 c1 03             	test   $0x3,%cl
  8008ef:	75 23                	jne    800914 <memset+0x40>
		c &= 0xFF;
  8008f1:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008f5:	89 d3                	mov    %edx,%ebx
  8008f7:	c1 e3 08             	shl    $0x8,%ebx
  8008fa:	89 d6                	mov    %edx,%esi
  8008fc:	c1 e6 18             	shl    $0x18,%esi
  8008ff:	89 d0                	mov    %edx,%eax
  800901:	c1 e0 10             	shl    $0x10,%eax
  800904:	09 f0                	or     %esi,%eax
  800906:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800908:	89 d8                	mov    %ebx,%eax
  80090a:	09 d0                	or     %edx,%eax
  80090c:	c1 e9 02             	shr    $0x2,%ecx
  80090f:	fc                   	cld    
  800910:	f3 ab                	rep stos %eax,%es:(%edi)
  800912:	eb 06                	jmp    80091a <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800914:	8b 45 0c             	mov    0xc(%ebp),%eax
  800917:	fc                   	cld    
  800918:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80091a:	89 f8                	mov    %edi,%eax
  80091c:	5b                   	pop    %ebx
  80091d:	5e                   	pop    %esi
  80091e:	5f                   	pop    %edi
  80091f:	5d                   	pop    %ebp
  800920:	c3                   	ret    

00800921 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800921:	55                   	push   %ebp
  800922:	89 e5                	mov    %esp,%ebp
  800924:	57                   	push   %edi
  800925:	56                   	push   %esi
  800926:	8b 45 08             	mov    0x8(%ebp),%eax
  800929:	8b 75 0c             	mov    0xc(%ebp),%esi
  80092c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80092f:	39 c6                	cmp    %eax,%esi
  800931:	73 35                	jae    800968 <memmove+0x47>
  800933:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800936:	39 d0                	cmp    %edx,%eax
  800938:	73 2e                	jae    800968 <memmove+0x47>
		s += n;
		d += n;
  80093a:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80093d:	89 d6                	mov    %edx,%esi
  80093f:	09 fe                	or     %edi,%esi
  800941:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800947:	75 13                	jne    80095c <memmove+0x3b>
  800949:	f6 c1 03             	test   $0x3,%cl
  80094c:	75 0e                	jne    80095c <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80094e:	83 ef 04             	sub    $0x4,%edi
  800951:	8d 72 fc             	lea    -0x4(%edx),%esi
  800954:	c1 e9 02             	shr    $0x2,%ecx
  800957:	fd                   	std    
  800958:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80095a:	eb 09                	jmp    800965 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80095c:	83 ef 01             	sub    $0x1,%edi
  80095f:	8d 72 ff             	lea    -0x1(%edx),%esi
  800962:	fd                   	std    
  800963:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800965:	fc                   	cld    
  800966:	eb 1d                	jmp    800985 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800968:	89 f2                	mov    %esi,%edx
  80096a:	09 c2                	or     %eax,%edx
  80096c:	f6 c2 03             	test   $0x3,%dl
  80096f:	75 0f                	jne    800980 <memmove+0x5f>
  800971:	f6 c1 03             	test   $0x3,%cl
  800974:	75 0a                	jne    800980 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800976:	c1 e9 02             	shr    $0x2,%ecx
  800979:	89 c7                	mov    %eax,%edi
  80097b:	fc                   	cld    
  80097c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80097e:	eb 05                	jmp    800985 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800980:	89 c7                	mov    %eax,%edi
  800982:	fc                   	cld    
  800983:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800985:	5e                   	pop    %esi
  800986:	5f                   	pop    %edi
  800987:	5d                   	pop    %ebp
  800988:	c3                   	ret    

00800989 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800989:	55                   	push   %ebp
  80098a:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  80098c:	ff 75 10             	pushl  0x10(%ebp)
  80098f:	ff 75 0c             	pushl  0xc(%ebp)
  800992:	ff 75 08             	pushl  0x8(%ebp)
  800995:	e8 87 ff ff ff       	call   800921 <memmove>
}
  80099a:	c9                   	leave  
  80099b:	c3                   	ret    

0080099c <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80099c:	55                   	push   %ebp
  80099d:	89 e5                	mov    %esp,%ebp
  80099f:	56                   	push   %esi
  8009a0:	53                   	push   %ebx
  8009a1:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a4:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009a7:	89 c6                	mov    %eax,%esi
  8009a9:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009ac:	eb 1a                	jmp    8009c8 <memcmp+0x2c>
		if (*s1 != *s2)
  8009ae:	0f b6 08             	movzbl (%eax),%ecx
  8009b1:	0f b6 1a             	movzbl (%edx),%ebx
  8009b4:	38 d9                	cmp    %bl,%cl
  8009b6:	74 0a                	je     8009c2 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009b8:	0f b6 c1             	movzbl %cl,%eax
  8009bb:	0f b6 db             	movzbl %bl,%ebx
  8009be:	29 d8                	sub    %ebx,%eax
  8009c0:	eb 0f                	jmp    8009d1 <memcmp+0x35>
		s1++, s2++;
  8009c2:	83 c0 01             	add    $0x1,%eax
  8009c5:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009c8:	39 f0                	cmp    %esi,%eax
  8009ca:	75 e2                	jne    8009ae <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009cc:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009d1:	5b                   	pop    %ebx
  8009d2:	5e                   	pop    %esi
  8009d3:	5d                   	pop    %ebp
  8009d4:	c3                   	ret    

008009d5 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009d5:	55                   	push   %ebp
  8009d6:	89 e5                	mov    %esp,%ebp
  8009d8:	53                   	push   %ebx
  8009d9:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009dc:	89 c1                	mov    %eax,%ecx
  8009de:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009e1:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009e5:	eb 0a                	jmp    8009f1 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009e7:	0f b6 10             	movzbl (%eax),%edx
  8009ea:	39 da                	cmp    %ebx,%edx
  8009ec:	74 07                	je     8009f5 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009ee:	83 c0 01             	add    $0x1,%eax
  8009f1:	39 c8                	cmp    %ecx,%eax
  8009f3:	72 f2                	jb     8009e7 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009f5:	5b                   	pop    %ebx
  8009f6:	5d                   	pop    %ebp
  8009f7:	c3                   	ret    

008009f8 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009f8:	55                   	push   %ebp
  8009f9:	89 e5                	mov    %esp,%ebp
  8009fb:	57                   	push   %edi
  8009fc:	56                   	push   %esi
  8009fd:	53                   	push   %ebx
  8009fe:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a01:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a04:	eb 03                	jmp    800a09 <strtol+0x11>
		s++;
  800a06:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a09:	0f b6 01             	movzbl (%ecx),%eax
  800a0c:	3c 20                	cmp    $0x20,%al
  800a0e:	74 f6                	je     800a06 <strtol+0xe>
  800a10:	3c 09                	cmp    $0x9,%al
  800a12:	74 f2                	je     800a06 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a14:	3c 2b                	cmp    $0x2b,%al
  800a16:	75 0a                	jne    800a22 <strtol+0x2a>
		s++;
  800a18:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a1b:	bf 00 00 00 00       	mov    $0x0,%edi
  800a20:	eb 11                	jmp    800a33 <strtol+0x3b>
  800a22:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a27:	3c 2d                	cmp    $0x2d,%al
  800a29:	75 08                	jne    800a33 <strtol+0x3b>
		s++, neg = 1;
  800a2b:	83 c1 01             	add    $0x1,%ecx
  800a2e:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a33:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a39:	75 15                	jne    800a50 <strtol+0x58>
  800a3b:	80 39 30             	cmpb   $0x30,(%ecx)
  800a3e:	75 10                	jne    800a50 <strtol+0x58>
  800a40:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a44:	75 7c                	jne    800ac2 <strtol+0xca>
		s += 2, base = 16;
  800a46:	83 c1 02             	add    $0x2,%ecx
  800a49:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a4e:	eb 16                	jmp    800a66 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a50:	85 db                	test   %ebx,%ebx
  800a52:	75 12                	jne    800a66 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a54:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a59:	80 39 30             	cmpb   $0x30,(%ecx)
  800a5c:	75 08                	jne    800a66 <strtol+0x6e>
		s++, base = 8;
  800a5e:	83 c1 01             	add    $0x1,%ecx
  800a61:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a66:	b8 00 00 00 00       	mov    $0x0,%eax
  800a6b:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a6e:	0f b6 11             	movzbl (%ecx),%edx
  800a71:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a74:	89 f3                	mov    %esi,%ebx
  800a76:	80 fb 09             	cmp    $0x9,%bl
  800a79:	77 08                	ja     800a83 <strtol+0x8b>
			dig = *s - '0';
  800a7b:	0f be d2             	movsbl %dl,%edx
  800a7e:	83 ea 30             	sub    $0x30,%edx
  800a81:	eb 22                	jmp    800aa5 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a83:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a86:	89 f3                	mov    %esi,%ebx
  800a88:	80 fb 19             	cmp    $0x19,%bl
  800a8b:	77 08                	ja     800a95 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a8d:	0f be d2             	movsbl %dl,%edx
  800a90:	83 ea 57             	sub    $0x57,%edx
  800a93:	eb 10                	jmp    800aa5 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a95:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a98:	89 f3                	mov    %esi,%ebx
  800a9a:	80 fb 19             	cmp    $0x19,%bl
  800a9d:	77 16                	ja     800ab5 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a9f:	0f be d2             	movsbl %dl,%edx
  800aa2:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800aa5:	3b 55 10             	cmp    0x10(%ebp),%edx
  800aa8:	7d 0b                	jge    800ab5 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800aaa:	83 c1 01             	add    $0x1,%ecx
  800aad:	0f af 45 10          	imul   0x10(%ebp),%eax
  800ab1:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ab3:	eb b9                	jmp    800a6e <strtol+0x76>

	if (endptr)
  800ab5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ab9:	74 0d                	je     800ac8 <strtol+0xd0>
		*endptr = (char *) s;
  800abb:	8b 75 0c             	mov    0xc(%ebp),%esi
  800abe:	89 0e                	mov    %ecx,(%esi)
  800ac0:	eb 06                	jmp    800ac8 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ac2:	85 db                	test   %ebx,%ebx
  800ac4:	74 98                	je     800a5e <strtol+0x66>
  800ac6:	eb 9e                	jmp    800a66 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800ac8:	89 c2                	mov    %eax,%edx
  800aca:	f7 da                	neg    %edx
  800acc:	85 ff                	test   %edi,%edi
  800ace:	0f 45 c2             	cmovne %edx,%eax
}
  800ad1:	5b                   	pop    %ebx
  800ad2:	5e                   	pop    %esi
  800ad3:	5f                   	pop    %edi
  800ad4:	5d                   	pop    %ebp
  800ad5:	c3                   	ret    
  800ad6:	66 90                	xchg   %ax,%ax
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

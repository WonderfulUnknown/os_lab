
obj/user/evilhello：     文件格式 elf32-i386


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
  80002c:	e8 19 00 00 00       	call   80004a <libmain>
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
	// try to print the kernel entry point as a string!  mua ha ha!
	sys_cputs((char*)0xf010000c, 100);
  800039:	6a 64                	push   $0x64
  80003b:	68 0c 00 10 f0       	push   $0xf010000c
  800040:	e8 4d 00 00 00       	call   800092 <sys_cputs>
}
  800045:	83 c4 10             	add    $0x10,%esp
  800048:	c9                   	leave  
  800049:	c3                   	ret    

0080004a <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80004a:	55                   	push   %ebp
  80004b:	89 e5                	mov    %esp,%ebp
  80004d:	83 ec 08             	sub    $0x8,%esp
  800050:	8b 45 08             	mov    0x8(%ebp),%eax
  800053:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  800056:	c7 05 04 10 80 00 00 	movl   $0x0,0x801004
  80005d:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800060:	85 c0                	test   %eax,%eax
  800062:	7e 08                	jle    80006c <libmain+0x22>
		binaryname = argv[0];
  800064:	8b 0a                	mov    (%edx),%ecx
  800066:	89 0d 00 10 80 00    	mov    %ecx,0x801000

	// call user main routine
	umain(argc, argv);
  80006c:	83 ec 08             	sub    $0x8,%esp
  80006f:	52                   	push   %edx
  800070:	50                   	push   %eax
  800071:	e8 bd ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800076:	e8 05 00 00 00       	call   800080 <exit>
}
  80007b:	83 c4 10             	add    $0x10,%esp
  80007e:	c9                   	leave  
  80007f:	c3                   	ret    

00800080 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800080:	55                   	push   %ebp
  800081:	89 e5                	mov    %esp,%ebp
  800083:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800086:	6a 00                	push   $0x0
  800088:	e8 42 00 00 00       	call   8000cf <sys_env_destroy>
}
  80008d:	83 c4 10             	add    $0x10,%esp
  800090:	c9                   	leave  
  800091:	c3                   	ret    

00800092 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800092:	55                   	push   %ebp
  800093:	89 e5                	mov    %esp,%ebp
  800095:	57                   	push   %edi
  800096:	56                   	push   %esi
  800097:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800098:	b8 00 00 00 00       	mov    $0x0,%eax
  80009d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000a0:	8b 55 08             	mov    0x8(%ebp),%edx
  8000a3:	89 c3                	mov    %eax,%ebx
  8000a5:	89 c7                	mov    %eax,%edi
  8000a7:	89 c6                	mov    %eax,%esi
  8000a9:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000ab:	5b                   	pop    %ebx
  8000ac:	5e                   	pop    %esi
  8000ad:	5f                   	pop    %edi
  8000ae:	5d                   	pop    %ebp
  8000af:	c3                   	ret    

008000b0 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000b0:	55                   	push   %ebp
  8000b1:	89 e5                	mov    %esp,%ebp
  8000b3:	57                   	push   %edi
  8000b4:	56                   	push   %esi
  8000b5:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000b6:	ba 00 00 00 00       	mov    $0x0,%edx
  8000bb:	b8 01 00 00 00       	mov    $0x1,%eax
  8000c0:	89 d1                	mov    %edx,%ecx
  8000c2:	89 d3                	mov    %edx,%ebx
  8000c4:	89 d7                	mov    %edx,%edi
  8000c6:	89 d6                	mov    %edx,%esi
  8000c8:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000ca:	5b                   	pop    %ebx
  8000cb:	5e                   	pop    %esi
  8000cc:	5f                   	pop    %edi
  8000cd:	5d                   	pop    %ebp
  8000ce:	c3                   	ret    

008000cf <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000cf:	55                   	push   %ebp
  8000d0:	89 e5                	mov    %esp,%ebp
  8000d2:	57                   	push   %edi
  8000d3:	56                   	push   %esi
  8000d4:	53                   	push   %ebx
  8000d5:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000d8:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000dd:	b8 03 00 00 00       	mov    $0x3,%eax
  8000e2:	8b 55 08             	mov    0x8(%ebp),%edx
  8000e5:	89 cb                	mov    %ecx,%ebx
  8000e7:	89 cf                	mov    %ecx,%edi
  8000e9:	89 ce                	mov    %ecx,%esi
  8000eb:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000ed:	85 c0                	test   %eax,%eax
  8000ef:	7e 17                	jle    800108 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000f1:	83 ec 0c             	sub    $0xc,%esp
  8000f4:	50                   	push   %eax
  8000f5:	6a 03                	push   $0x3
  8000f7:	68 8a 0d 80 00       	push   $0x800d8a
  8000fc:	6a 23                	push   $0x23
  8000fe:	68 a7 0d 80 00       	push   $0x800da7
  800103:	e8 27 00 00 00       	call   80012f <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800108:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80010b:	5b                   	pop    %ebx
  80010c:	5e                   	pop    %esi
  80010d:	5f                   	pop    %edi
  80010e:	5d                   	pop    %ebp
  80010f:	c3                   	ret    

00800110 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800110:	55                   	push   %ebp
  800111:	89 e5                	mov    %esp,%ebp
  800113:	57                   	push   %edi
  800114:	56                   	push   %esi
  800115:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800116:	ba 00 00 00 00       	mov    $0x0,%edx
  80011b:	b8 02 00 00 00       	mov    $0x2,%eax
  800120:	89 d1                	mov    %edx,%ecx
  800122:	89 d3                	mov    %edx,%ebx
  800124:	89 d7                	mov    %edx,%edi
  800126:	89 d6                	mov    %edx,%esi
  800128:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80012a:	5b                   	pop    %ebx
  80012b:	5e                   	pop    %esi
  80012c:	5f                   	pop    %edi
  80012d:	5d                   	pop    %ebp
  80012e:	c3                   	ret    

0080012f <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80012f:	55                   	push   %ebp
  800130:	89 e5                	mov    %esp,%ebp
  800132:	56                   	push   %esi
  800133:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800134:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800137:	8b 35 00 10 80 00    	mov    0x801000,%esi
  80013d:	e8 ce ff ff ff       	call   800110 <sys_getenvid>
  800142:	83 ec 0c             	sub    $0xc,%esp
  800145:	ff 75 0c             	pushl  0xc(%ebp)
  800148:	ff 75 08             	pushl  0x8(%ebp)
  80014b:	56                   	push   %esi
  80014c:	50                   	push   %eax
  80014d:	68 b8 0d 80 00       	push   $0x800db8
  800152:	e8 b1 00 00 00       	call   800208 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800157:	83 c4 18             	add    $0x18,%esp
  80015a:	53                   	push   %ebx
  80015b:	ff 75 10             	pushl  0x10(%ebp)
  80015e:	e8 54 00 00 00       	call   8001b7 <vcprintf>
	cprintf("\n");
  800163:	c7 04 24 dc 0d 80 00 	movl   $0x800ddc,(%esp)
  80016a:	e8 99 00 00 00       	call   800208 <cprintf>
  80016f:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800172:	cc                   	int3   
  800173:	eb fd                	jmp    800172 <_panic+0x43>

00800175 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800175:	55                   	push   %ebp
  800176:	89 e5                	mov    %esp,%ebp
  800178:	53                   	push   %ebx
  800179:	83 ec 04             	sub    $0x4,%esp
  80017c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80017f:	8b 13                	mov    (%ebx),%edx
  800181:	8d 42 01             	lea    0x1(%edx),%eax
  800184:	89 03                	mov    %eax,(%ebx)
  800186:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800189:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80018d:	3d ff 00 00 00       	cmp    $0xff,%eax
  800192:	75 1a                	jne    8001ae <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800194:	83 ec 08             	sub    $0x8,%esp
  800197:	68 ff 00 00 00       	push   $0xff
  80019c:	8d 43 08             	lea    0x8(%ebx),%eax
  80019f:	50                   	push   %eax
  8001a0:	e8 ed fe ff ff       	call   800092 <sys_cputs>
		b->idx = 0;
  8001a5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001ab:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001ae:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001b2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001b5:	c9                   	leave  
  8001b6:	c3                   	ret    

008001b7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001b7:	55                   	push   %ebp
  8001b8:	89 e5                	mov    %esp,%ebp
  8001ba:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001c0:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001c7:	00 00 00 
	b.cnt = 0;
  8001ca:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001d1:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001d4:	ff 75 0c             	pushl  0xc(%ebp)
  8001d7:	ff 75 08             	pushl  0x8(%ebp)
  8001da:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001e0:	50                   	push   %eax
  8001e1:	68 75 01 80 00       	push   $0x800175
  8001e6:	e8 54 01 00 00       	call   80033f <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001eb:	83 c4 08             	add    $0x8,%esp
  8001ee:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001f4:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001fa:	50                   	push   %eax
  8001fb:	e8 92 fe ff ff       	call   800092 <sys_cputs>

	return b.cnt;
}
  800200:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800206:	c9                   	leave  
  800207:	c3                   	ret    

00800208 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800208:	55                   	push   %ebp
  800209:	89 e5                	mov    %esp,%ebp
  80020b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80020e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800211:	50                   	push   %eax
  800212:	ff 75 08             	pushl  0x8(%ebp)
  800215:	e8 9d ff ff ff       	call   8001b7 <vcprintf>
	va_end(ap);

	return cnt;
}
  80021a:	c9                   	leave  
  80021b:	c3                   	ret    

0080021c <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80021c:	55                   	push   %ebp
  80021d:	89 e5                	mov    %esp,%ebp
  80021f:	57                   	push   %edi
  800220:	56                   	push   %esi
  800221:	53                   	push   %ebx
  800222:	83 ec 1c             	sub    $0x1c,%esp
  800225:	89 c7                	mov    %eax,%edi
  800227:	89 d6                	mov    %edx,%esi
  800229:	8b 45 08             	mov    0x8(%ebp),%eax
  80022c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80022f:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800232:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800235:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800238:	bb 00 00 00 00       	mov    $0x0,%ebx
  80023d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800240:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800243:	39 d3                	cmp    %edx,%ebx
  800245:	72 05                	jb     80024c <printnum+0x30>
  800247:	39 45 10             	cmp    %eax,0x10(%ebp)
  80024a:	77 45                	ja     800291 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80024c:	83 ec 0c             	sub    $0xc,%esp
  80024f:	ff 75 18             	pushl  0x18(%ebp)
  800252:	8b 45 14             	mov    0x14(%ebp),%eax
  800255:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800258:	53                   	push   %ebx
  800259:	ff 75 10             	pushl  0x10(%ebp)
  80025c:	83 ec 08             	sub    $0x8,%esp
  80025f:	ff 75 e4             	pushl  -0x1c(%ebp)
  800262:	ff 75 e0             	pushl  -0x20(%ebp)
  800265:	ff 75 dc             	pushl  -0x24(%ebp)
  800268:	ff 75 d8             	pushl  -0x28(%ebp)
  80026b:	e8 70 08 00 00       	call   800ae0 <__udivdi3>
  800270:	83 c4 18             	add    $0x18,%esp
  800273:	52                   	push   %edx
  800274:	50                   	push   %eax
  800275:	89 f2                	mov    %esi,%edx
  800277:	89 f8                	mov    %edi,%eax
  800279:	e8 9e ff ff ff       	call   80021c <printnum>
  80027e:	83 c4 20             	add    $0x20,%esp
  800281:	eb 18                	jmp    80029b <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800283:	83 ec 08             	sub    $0x8,%esp
  800286:	56                   	push   %esi
  800287:	ff 75 18             	pushl  0x18(%ebp)
  80028a:	ff d7                	call   *%edi
  80028c:	83 c4 10             	add    $0x10,%esp
  80028f:	eb 03                	jmp    800294 <printnum+0x78>
  800291:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800294:	83 eb 01             	sub    $0x1,%ebx
  800297:	85 db                	test   %ebx,%ebx
  800299:	7f e8                	jg     800283 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80029b:	83 ec 08             	sub    $0x8,%esp
  80029e:	56                   	push   %esi
  80029f:	83 ec 04             	sub    $0x4,%esp
  8002a2:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002a5:	ff 75 e0             	pushl  -0x20(%ebp)
  8002a8:	ff 75 dc             	pushl  -0x24(%ebp)
  8002ab:	ff 75 d8             	pushl  -0x28(%ebp)
  8002ae:	e8 5d 09 00 00       	call   800c10 <__umoddi3>
  8002b3:	83 c4 14             	add    $0x14,%esp
  8002b6:	0f be 80 de 0d 80 00 	movsbl 0x800dde(%eax),%eax
  8002bd:	50                   	push   %eax
  8002be:	ff d7                	call   *%edi
}
  8002c0:	83 c4 10             	add    $0x10,%esp
  8002c3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002c6:	5b                   	pop    %ebx
  8002c7:	5e                   	pop    %esi
  8002c8:	5f                   	pop    %edi
  8002c9:	5d                   	pop    %ebp
  8002ca:	c3                   	ret    

008002cb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002cb:	55                   	push   %ebp
  8002cc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002ce:	83 fa 01             	cmp    $0x1,%edx
  8002d1:	7e 0e                	jle    8002e1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002d3:	8b 10                	mov    (%eax),%edx
  8002d5:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002d8:	89 08                	mov    %ecx,(%eax)
  8002da:	8b 02                	mov    (%edx),%eax
  8002dc:	8b 52 04             	mov    0x4(%edx),%edx
  8002df:	eb 22                	jmp    800303 <getuint+0x38>
	else if (lflag)
  8002e1:	85 d2                	test   %edx,%edx
  8002e3:	74 10                	je     8002f5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002e5:	8b 10                	mov    (%eax),%edx
  8002e7:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002ea:	89 08                	mov    %ecx,(%eax)
  8002ec:	8b 02                	mov    (%edx),%eax
  8002ee:	ba 00 00 00 00       	mov    $0x0,%edx
  8002f3:	eb 0e                	jmp    800303 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8002f5:	8b 10                	mov    (%eax),%edx
  8002f7:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002fa:	89 08                	mov    %ecx,(%eax)
  8002fc:	8b 02                	mov    (%edx),%eax
  8002fe:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800303:	5d                   	pop    %ebp
  800304:	c3                   	ret    

00800305 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800305:	55                   	push   %ebp
  800306:	89 e5                	mov    %esp,%ebp
  800308:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80030b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  80030f:	8b 10                	mov    (%eax),%edx
  800311:	3b 50 04             	cmp    0x4(%eax),%edx
  800314:	73 0a                	jae    800320 <sprintputch+0x1b>
		*b->buf++ = ch;
  800316:	8d 4a 01             	lea    0x1(%edx),%ecx
  800319:	89 08                	mov    %ecx,(%eax)
  80031b:	8b 45 08             	mov    0x8(%ebp),%eax
  80031e:	88 02                	mov    %al,(%edx)
}
  800320:	5d                   	pop    %ebp
  800321:	c3                   	ret    

00800322 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800322:	55                   	push   %ebp
  800323:	89 e5                	mov    %esp,%ebp
  800325:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800328:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80032b:	50                   	push   %eax
  80032c:	ff 75 10             	pushl  0x10(%ebp)
  80032f:	ff 75 0c             	pushl  0xc(%ebp)
  800332:	ff 75 08             	pushl  0x8(%ebp)
  800335:	e8 05 00 00 00       	call   80033f <vprintfmt>
	va_end(ap);
}
  80033a:	83 c4 10             	add    $0x10,%esp
  80033d:	c9                   	leave  
  80033e:	c3                   	ret    

0080033f <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80033f:	55                   	push   %ebp
  800340:	89 e5                	mov    %esp,%ebp
  800342:	57                   	push   %edi
  800343:	56                   	push   %esi
  800344:	53                   	push   %ebx
  800345:	83 ec 2c             	sub    $0x2c,%esp
  800348:	8b 75 08             	mov    0x8(%ebp),%esi
  80034b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80034e:	8b 7d 10             	mov    0x10(%ebp),%edi
  800351:	eb 12                	jmp    800365 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800353:	85 c0                	test   %eax,%eax
  800355:	0f 84 89 03 00 00    	je     8006e4 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  80035b:	83 ec 08             	sub    $0x8,%esp
  80035e:	53                   	push   %ebx
  80035f:	50                   	push   %eax
  800360:	ff d6                	call   *%esi
  800362:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800365:	83 c7 01             	add    $0x1,%edi
  800368:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80036c:	83 f8 25             	cmp    $0x25,%eax
  80036f:	75 e2                	jne    800353 <vprintfmt+0x14>
  800371:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800375:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80037c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800383:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80038a:	ba 00 00 00 00       	mov    $0x0,%edx
  80038f:	eb 07                	jmp    800398 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800391:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800394:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800398:	8d 47 01             	lea    0x1(%edi),%eax
  80039b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80039e:	0f b6 07             	movzbl (%edi),%eax
  8003a1:	0f b6 c8             	movzbl %al,%ecx
  8003a4:	83 e8 23             	sub    $0x23,%eax
  8003a7:	3c 55                	cmp    $0x55,%al
  8003a9:	0f 87 1a 03 00 00    	ja     8006c9 <vprintfmt+0x38a>
  8003af:	0f b6 c0             	movzbl %al,%eax
  8003b2:	ff 24 85 80 0e 80 00 	jmp    *0x800e80(,%eax,4)
  8003b9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003bc:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003c0:	eb d6                	jmp    800398 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003c5:	b8 00 00 00 00       	mov    $0x0,%eax
  8003ca:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003cd:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003d0:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  8003d4:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  8003d7:	8d 51 d0             	lea    -0x30(%ecx),%edx
  8003da:	83 fa 09             	cmp    $0x9,%edx
  8003dd:	77 39                	ja     800418 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003df:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003e2:	eb e9                	jmp    8003cd <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8003e7:	8d 48 04             	lea    0x4(%eax),%ecx
  8003ea:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003ed:	8b 00                	mov    (%eax),%eax
  8003ef:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003f5:	eb 27                	jmp    80041e <vprintfmt+0xdf>
  8003f7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003fa:	85 c0                	test   %eax,%eax
  8003fc:	b9 00 00 00 00       	mov    $0x0,%ecx
  800401:	0f 49 c8             	cmovns %eax,%ecx
  800404:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800407:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80040a:	eb 8c                	jmp    800398 <vprintfmt+0x59>
  80040c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80040f:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800416:	eb 80                	jmp    800398 <vprintfmt+0x59>
  800418:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80041b:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80041e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800422:	0f 89 70 ff ff ff    	jns    800398 <vprintfmt+0x59>
				width = precision, precision = -1;
  800428:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80042b:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80042e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800435:	e9 5e ff ff ff       	jmp    800398 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80043a:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80043d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800440:	e9 53 ff ff ff       	jmp    800398 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800445:	8b 45 14             	mov    0x14(%ebp),%eax
  800448:	8d 50 04             	lea    0x4(%eax),%edx
  80044b:	89 55 14             	mov    %edx,0x14(%ebp)
  80044e:	83 ec 08             	sub    $0x8,%esp
  800451:	53                   	push   %ebx
  800452:	ff 30                	pushl  (%eax)
  800454:	ff d6                	call   *%esi
			break;
  800456:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800459:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80045c:	e9 04 ff ff ff       	jmp    800365 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800461:	8b 45 14             	mov    0x14(%ebp),%eax
  800464:	8d 50 04             	lea    0x4(%eax),%edx
  800467:	89 55 14             	mov    %edx,0x14(%ebp)
  80046a:	8b 00                	mov    (%eax),%eax
  80046c:	99                   	cltd   
  80046d:	31 d0                	xor    %edx,%eax
  80046f:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800471:	83 f8 07             	cmp    $0x7,%eax
  800474:	7f 0b                	jg     800481 <vprintfmt+0x142>
  800476:	8b 14 85 e0 0f 80 00 	mov    0x800fe0(,%eax,4),%edx
  80047d:	85 d2                	test   %edx,%edx
  80047f:	75 18                	jne    800499 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800481:	50                   	push   %eax
  800482:	68 f6 0d 80 00       	push   $0x800df6
  800487:	53                   	push   %ebx
  800488:	56                   	push   %esi
  800489:	e8 94 fe ff ff       	call   800322 <printfmt>
  80048e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800491:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800494:	e9 cc fe ff ff       	jmp    800365 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800499:	52                   	push   %edx
  80049a:	68 ff 0d 80 00       	push   $0x800dff
  80049f:	53                   	push   %ebx
  8004a0:	56                   	push   %esi
  8004a1:	e8 7c fe ff ff       	call   800322 <printfmt>
  8004a6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004a9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004ac:	e9 b4 fe ff ff       	jmp    800365 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004b1:	8b 45 14             	mov    0x14(%ebp),%eax
  8004b4:	8d 50 04             	lea    0x4(%eax),%edx
  8004b7:	89 55 14             	mov    %edx,0x14(%ebp)
  8004ba:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004bc:	85 ff                	test   %edi,%edi
  8004be:	b8 ef 0d 80 00       	mov    $0x800def,%eax
  8004c3:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004c6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004ca:	0f 8e 94 00 00 00    	jle    800564 <vprintfmt+0x225>
  8004d0:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004d4:	0f 84 98 00 00 00    	je     800572 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004da:	83 ec 08             	sub    $0x8,%esp
  8004dd:	ff 75 d0             	pushl  -0x30(%ebp)
  8004e0:	57                   	push   %edi
  8004e1:	e8 86 02 00 00       	call   80076c <strnlen>
  8004e6:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004e9:	29 c1                	sub    %eax,%ecx
  8004eb:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  8004ee:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004f1:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004f5:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004f8:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004fb:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004fd:	eb 0f                	jmp    80050e <vprintfmt+0x1cf>
					putch(padc, putdat);
  8004ff:	83 ec 08             	sub    $0x8,%esp
  800502:	53                   	push   %ebx
  800503:	ff 75 e0             	pushl  -0x20(%ebp)
  800506:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800508:	83 ef 01             	sub    $0x1,%edi
  80050b:	83 c4 10             	add    $0x10,%esp
  80050e:	85 ff                	test   %edi,%edi
  800510:	7f ed                	jg     8004ff <vprintfmt+0x1c0>
  800512:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800515:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  800518:	85 c9                	test   %ecx,%ecx
  80051a:	b8 00 00 00 00       	mov    $0x0,%eax
  80051f:	0f 49 c1             	cmovns %ecx,%eax
  800522:	29 c1                	sub    %eax,%ecx
  800524:	89 75 08             	mov    %esi,0x8(%ebp)
  800527:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80052a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80052d:	89 cb                	mov    %ecx,%ebx
  80052f:	eb 4d                	jmp    80057e <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800531:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800535:	74 1b                	je     800552 <vprintfmt+0x213>
  800537:	0f be c0             	movsbl %al,%eax
  80053a:	83 e8 20             	sub    $0x20,%eax
  80053d:	83 f8 5e             	cmp    $0x5e,%eax
  800540:	76 10                	jbe    800552 <vprintfmt+0x213>
					putch('?', putdat);
  800542:	83 ec 08             	sub    $0x8,%esp
  800545:	ff 75 0c             	pushl  0xc(%ebp)
  800548:	6a 3f                	push   $0x3f
  80054a:	ff 55 08             	call   *0x8(%ebp)
  80054d:	83 c4 10             	add    $0x10,%esp
  800550:	eb 0d                	jmp    80055f <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800552:	83 ec 08             	sub    $0x8,%esp
  800555:	ff 75 0c             	pushl  0xc(%ebp)
  800558:	52                   	push   %edx
  800559:	ff 55 08             	call   *0x8(%ebp)
  80055c:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80055f:	83 eb 01             	sub    $0x1,%ebx
  800562:	eb 1a                	jmp    80057e <vprintfmt+0x23f>
  800564:	89 75 08             	mov    %esi,0x8(%ebp)
  800567:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80056a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80056d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800570:	eb 0c                	jmp    80057e <vprintfmt+0x23f>
  800572:	89 75 08             	mov    %esi,0x8(%ebp)
  800575:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800578:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80057b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80057e:	83 c7 01             	add    $0x1,%edi
  800581:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800585:	0f be d0             	movsbl %al,%edx
  800588:	85 d2                	test   %edx,%edx
  80058a:	74 23                	je     8005af <vprintfmt+0x270>
  80058c:	85 f6                	test   %esi,%esi
  80058e:	78 a1                	js     800531 <vprintfmt+0x1f2>
  800590:	83 ee 01             	sub    $0x1,%esi
  800593:	79 9c                	jns    800531 <vprintfmt+0x1f2>
  800595:	89 df                	mov    %ebx,%edi
  800597:	8b 75 08             	mov    0x8(%ebp),%esi
  80059a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80059d:	eb 18                	jmp    8005b7 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  80059f:	83 ec 08             	sub    $0x8,%esp
  8005a2:	53                   	push   %ebx
  8005a3:	6a 20                	push   $0x20
  8005a5:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005a7:	83 ef 01             	sub    $0x1,%edi
  8005aa:	83 c4 10             	add    $0x10,%esp
  8005ad:	eb 08                	jmp    8005b7 <vprintfmt+0x278>
  8005af:	89 df                	mov    %ebx,%edi
  8005b1:	8b 75 08             	mov    0x8(%ebp),%esi
  8005b4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005b7:	85 ff                	test   %edi,%edi
  8005b9:	7f e4                	jg     80059f <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005bb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005be:	e9 a2 fd ff ff       	jmp    800365 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005c3:	83 fa 01             	cmp    $0x1,%edx
  8005c6:	7e 16                	jle    8005de <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  8005c8:	8b 45 14             	mov    0x14(%ebp),%eax
  8005cb:	8d 50 08             	lea    0x8(%eax),%edx
  8005ce:	89 55 14             	mov    %edx,0x14(%ebp)
  8005d1:	8b 50 04             	mov    0x4(%eax),%edx
  8005d4:	8b 00                	mov    (%eax),%eax
  8005d6:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005d9:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005dc:	eb 32                	jmp    800610 <vprintfmt+0x2d1>
	else if (lflag)
  8005de:	85 d2                	test   %edx,%edx
  8005e0:	74 18                	je     8005fa <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  8005e2:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e5:	8d 50 04             	lea    0x4(%eax),%edx
  8005e8:	89 55 14             	mov    %edx,0x14(%ebp)
  8005eb:	8b 00                	mov    (%eax),%eax
  8005ed:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005f0:	89 c1                	mov    %eax,%ecx
  8005f2:	c1 f9 1f             	sar    $0x1f,%ecx
  8005f5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005f8:	eb 16                	jmp    800610 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  8005fa:	8b 45 14             	mov    0x14(%ebp),%eax
  8005fd:	8d 50 04             	lea    0x4(%eax),%edx
  800600:	89 55 14             	mov    %edx,0x14(%ebp)
  800603:	8b 00                	mov    (%eax),%eax
  800605:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800608:	89 c1                	mov    %eax,%ecx
  80060a:	c1 f9 1f             	sar    $0x1f,%ecx
  80060d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800610:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800613:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800616:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80061b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80061f:	79 74                	jns    800695 <vprintfmt+0x356>
				putch('-', putdat);
  800621:	83 ec 08             	sub    $0x8,%esp
  800624:	53                   	push   %ebx
  800625:	6a 2d                	push   $0x2d
  800627:	ff d6                	call   *%esi
				num = -(long long) num;
  800629:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80062c:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80062f:	f7 d8                	neg    %eax
  800631:	83 d2 00             	adc    $0x0,%edx
  800634:	f7 da                	neg    %edx
  800636:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800639:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80063e:	eb 55                	jmp    800695 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800640:	8d 45 14             	lea    0x14(%ebp),%eax
  800643:	e8 83 fc ff ff       	call   8002cb <getuint>
			base = 10;
  800648:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80064d:	eb 46                	jmp    800695 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  80064f:	8d 45 14             	lea    0x14(%ebp),%eax
  800652:	e8 74 fc ff ff       	call   8002cb <getuint>
			base = 8;
  800657:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80065c:	eb 37                	jmp    800695 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  80065e:	83 ec 08             	sub    $0x8,%esp
  800661:	53                   	push   %ebx
  800662:	6a 30                	push   $0x30
  800664:	ff d6                	call   *%esi
			putch('x', putdat);
  800666:	83 c4 08             	add    $0x8,%esp
  800669:	53                   	push   %ebx
  80066a:	6a 78                	push   $0x78
  80066c:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80066e:	8b 45 14             	mov    0x14(%ebp),%eax
  800671:	8d 50 04             	lea    0x4(%eax),%edx
  800674:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800677:	8b 00                	mov    (%eax),%eax
  800679:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  80067e:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800681:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800686:	eb 0d                	jmp    800695 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800688:	8d 45 14             	lea    0x14(%ebp),%eax
  80068b:	e8 3b fc ff ff       	call   8002cb <getuint>
			base = 16;
  800690:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800695:	83 ec 0c             	sub    $0xc,%esp
  800698:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80069c:	57                   	push   %edi
  80069d:	ff 75 e0             	pushl  -0x20(%ebp)
  8006a0:	51                   	push   %ecx
  8006a1:	52                   	push   %edx
  8006a2:	50                   	push   %eax
  8006a3:	89 da                	mov    %ebx,%edx
  8006a5:	89 f0                	mov    %esi,%eax
  8006a7:	e8 70 fb ff ff       	call   80021c <printnum>
			break;
  8006ac:	83 c4 20             	add    $0x20,%esp
  8006af:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006b2:	e9 ae fc ff ff       	jmp    800365 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006b7:	83 ec 08             	sub    $0x8,%esp
  8006ba:	53                   	push   %ebx
  8006bb:	51                   	push   %ecx
  8006bc:	ff d6                	call   *%esi
			break;
  8006be:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006c1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006c4:	e9 9c fc ff ff       	jmp    800365 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006c9:	83 ec 08             	sub    $0x8,%esp
  8006cc:	53                   	push   %ebx
  8006cd:	6a 25                	push   $0x25
  8006cf:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006d1:	83 c4 10             	add    $0x10,%esp
  8006d4:	eb 03                	jmp    8006d9 <vprintfmt+0x39a>
  8006d6:	83 ef 01             	sub    $0x1,%edi
  8006d9:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006dd:	75 f7                	jne    8006d6 <vprintfmt+0x397>
  8006df:	e9 81 fc ff ff       	jmp    800365 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006e7:	5b                   	pop    %ebx
  8006e8:	5e                   	pop    %esi
  8006e9:	5f                   	pop    %edi
  8006ea:	5d                   	pop    %ebp
  8006eb:	c3                   	ret    

008006ec <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006ec:	55                   	push   %ebp
  8006ed:	89 e5                	mov    %esp,%ebp
  8006ef:	83 ec 18             	sub    $0x18,%esp
  8006f2:	8b 45 08             	mov    0x8(%ebp),%eax
  8006f5:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006f8:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006fb:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006ff:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800702:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800709:	85 c0                	test   %eax,%eax
  80070b:	74 26                	je     800733 <vsnprintf+0x47>
  80070d:	85 d2                	test   %edx,%edx
  80070f:	7e 22                	jle    800733 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800711:	ff 75 14             	pushl  0x14(%ebp)
  800714:	ff 75 10             	pushl  0x10(%ebp)
  800717:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80071a:	50                   	push   %eax
  80071b:	68 05 03 80 00       	push   $0x800305
  800720:	e8 1a fc ff ff       	call   80033f <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800725:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800728:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80072b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80072e:	83 c4 10             	add    $0x10,%esp
  800731:	eb 05                	jmp    800738 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800733:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800738:	c9                   	leave  
  800739:	c3                   	ret    

0080073a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80073a:	55                   	push   %ebp
  80073b:	89 e5                	mov    %esp,%ebp
  80073d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800740:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800743:	50                   	push   %eax
  800744:	ff 75 10             	pushl  0x10(%ebp)
  800747:	ff 75 0c             	pushl  0xc(%ebp)
  80074a:	ff 75 08             	pushl  0x8(%ebp)
  80074d:	e8 9a ff ff ff       	call   8006ec <vsnprintf>
	va_end(ap);

	return rc;
}
  800752:	c9                   	leave  
  800753:	c3                   	ret    

00800754 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800754:	55                   	push   %ebp
  800755:	89 e5                	mov    %esp,%ebp
  800757:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80075a:	b8 00 00 00 00       	mov    $0x0,%eax
  80075f:	eb 03                	jmp    800764 <strlen+0x10>
		n++;
  800761:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800764:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800768:	75 f7                	jne    800761 <strlen+0xd>
		n++;
	return n;
}
  80076a:	5d                   	pop    %ebp
  80076b:	c3                   	ret    

0080076c <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80076c:	55                   	push   %ebp
  80076d:	89 e5                	mov    %esp,%ebp
  80076f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800772:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800775:	ba 00 00 00 00       	mov    $0x0,%edx
  80077a:	eb 03                	jmp    80077f <strnlen+0x13>
		n++;
  80077c:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80077f:	39 c2                	cmp    %eax,%edx
  800781:	74 08                	je     80078b <strnlen+0x1f>
  800783:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800787:	75 f3                	jne    80077c <strnlen+0x10>
  800789:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80078b:	5d                   	pop    %ebp
  80078c:	c3                   	ret    

0080078d <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80078d:	55                   	push   %ebp
  80078e:	89 e5                	mov    %esp,%ebp
  800790:	53                   	push   %ebx
  800791:	8b 45 08             	mov    0x8(%ebp),%eax
  800794:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800797:	89 c2                	mov    %eax,%edx
  800799:	83 c2 01             	add    $0x1,%edx
  80079c:	83 c1 01             	add    $0x1,%ecx
  80079f:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007a3:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007a6:	84 db                	test   %bl,%bl
  8007a8:	75 ef                	jne    800799 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007aa:	5b                   	pop    %ebx
  8007ab:	5d                   	pop    %ebp
  8007ac:	c3                   	ret    

008007ad <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007ad:	55                   	push   %ebp
  8007ae:	89 e5                	mov    %esp,%ebp
  8007b0:	53                   	push   %ebx
  8007b1:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007b4:	53                   	push   %ebx
  8007b5:	e8 9a ff ff ff       	call   800754 <strlen>
  8007ba:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007bd:	ff 75 0c             	pushl  0xc(%ebp)
  8007c0:	01 d8                	add    %ebx,%eax
  8007c2:	50                   	push   %eax
  8007c3:	e8 c5 ff ff ff       	call   80078d <strcpy>
	return dst;
}
  8007c8:	89 d8                	mov    %ebx,%eax
  8007ca:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007cd:	c9                   	leave  
  8007ce:	c3                   	ret    

008007cf <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007cf:	55                   	push   %ebp
  8007d0:	89 e5                	mov    %esp,%ebp
  8007d2:	56                   	push   %esi
  8007d3:	53                   	push   %ebx
  8007d4:	8b 75 08             	mov    0x8(%ebp),%esi
  8007d7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007da:	89 f3                	mov    %esi,%ebx
  8007dc:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007df:	89 f2                	mov    %esi,%edx
  8007e1:	eb 0f                	jmp    8007f2 <strncpy+0x23>
		*dst++ = *src;
  8007e3:	83 c2 01             	add    $0x1,%edx
  8007e6:	0f b6 01             	movzbl (%ecx),%eax
  8007e9:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007ec:	80 39 01             	cmpb   $0x1,(%ecx)
  8007ef:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007f2:	39 da                	cmp    %ebx,%edx
  8007f4:	75 ed                	jne    8007e3 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007f6:	89 f0                	mov    %esi,%eax
  8007f8:	5b                   	pop    %ebx
  8007f9:	5e                   	pop    %esi
  8007fa:	5d                   	pop    %ebp
  8007fb:	c3                   	ret    

008007fc <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007fc:	55                   	push   %ebp
  8007fd:	89 e5                	mov    %esp,%ebp
  8007ff:	56                   	push   %esi
  800800:	53                   	push   %ebx
  800801:	8b 75 08             	mov    0x8(%ebp),%esi
  800804:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800807:	8b 55 10             	mov    0x10(%ebp),%edx
  80080a:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80080c:	85 d2                	test   %edx,%edx
  80080e:	74 21                	je     800831 <strlcpy+0x35>
  800810:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800814:	89 f2                	mov    %esi,%edx
  800816:	eb 09                	jmp    800821 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800818:	83 c2 01             	add    $0x1,%edx
  80081b:	83 c1 01             	add    $0x1,%ecx
  80081e:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800821:	39 c2                	cmp    %eax,%edx
  800823:	74 09                	je     80082e <strlcpy+0x32>
  800825:	0f b6 19             	movzbl (%ecx),%ebx
  800828:	84 db                	test   %bl,%bl
  80082a:	75 ec                	jne    800818 <strlcpy+0x1c>
  80082c:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80082e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800831:	29 f0                	sub    %esi,%eax
}
  800833:	5b                   	pop    %ebx
  800834:	5e                   	pop    %esi
  800835:	5d                   	pop    %ebp
  800836:	c3                   	ret    

00800837 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800837:	55                   	push   %ebp
  800838:	89 e5                	mov    %esp,%ebp
  80083a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80083d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800840:	eb 06                	jmp    800848 <strcmp+0x11>
		p++, q++;
  800842:	83 c1 01             	add    $0x1,%ecx
  800845:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800848:	0f b6 01             	movzbl (%ecx),%eax
  80084b:	84 c0                	test   %al,%al
  80084d:	74 04                	je     800853 <strcmp+0x1c>
  80084f:	3a 02                	cmp    (%edx),%al
  800851:	74 ef                	je     800842 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800853:	0f b6 c0             	movzbl %al,%eax
  800856:	0f b6 12             	movzbl (%edx),%edx
  800859:	29 d0                	sub    %edx,%eax
}
  80085b:	5d                   	pop    %ebp
  80085c:	c3                   	ret    

0080085d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80085d:	55                   	push   %ebp
  80085e:	89 e5                	mov    %esp,%ebp
  800860:	53                   	push   %ebx
  800861:	8b 45 08             	mov    0x8(%ebp),%eax
  800864:	8b 55 0c             	mov    0xc(%ebp),%edx
  800867:	89 c3                	mov    %eax,%ebx
  800869:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80086c:	eb 06                	jmp    800874 <strncmp+0x17>
		n--, p++, q++;
  80086e:	83 c0 01             	add    $0x1,%eax
  800871:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800874:	39 d8                	cmp    %ebx,%eax
  800876:	74 15                	je     80088d <strncmp+0x30>
  800878:	0f b6 08             	movzbl (%eax),%ecx
  80087b:	84 c9                	test   %cl,%cl
  80087d:	74 04                	je     800883 <strncmp+0x26>
  80087f:	3a 0a                	cmp    (%edx),%cl
  800881:	74 eb                	je     80086e <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800883:	0f b6 00             	movzbl (%eax),%eax
  800886:	0f b6 12             	movzbl (%edx),%edx
  800889:	29 d0                	sub    %edx,%eax
  80088b:	eb 05                	jmp    800892 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80088d:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800892:	5b                   	pop    %ebx
  800893:	5d                   	pop    %ebp
  800894:	c3                   	ret    

00800895 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800895:	55                   	push   %ebp
  800896:	89 e5                	mov    %esp,%ebp
  800898:	8b 45 08             	mov    0x8(%ebp),%eax
  80089b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  80089f:	eb 07                	jmp    8008a8 <strchr+0x13>
		if (*s == c)
  8008a1:	38 ca                	cmp    %cl,%dl
  8008a3:	74 0f                	je     8008b4 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008a5:	83 c0 01             	add    $0x1,%eax
  8008a8:	0f b6 10             	movzbl (%eax),%edx
  8008ab:	84 d2                	test   %dl,%dl
  8008ad:	75 f2                	jne    8008a1 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008af:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008b4:	5d                   	pop    %ebp
  8008b5:	c3                   	ret    

008008b6 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008b6:	55                   	push   %ebp
  8008b7:	89 e5                	mov    %esp,%ebp
  8008b9:	8b 45 08             	mov    0x8(%ebp),%eax
  8008bc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008c0:	eb 03                	jmp    8008c5 <strfind+0xf>
  8008c2:	83 c0 01             	add    $0x1,%eax
  8008c5:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008c8:	38 ca                	cmp    %cl,%dl
  8008ca:	74 04                	je     8008d0 <strfind+0x1a>
  8008cc:	84 d2                	test   %dl,%dl
  8008ce:	75 f2                	jne    8008c2 <strfind+0xc>
			break;
	return (char *) s;
}
  8008d0:	5d                   	pop    %ebp
  8008d1:	c3                   	ret    

008008d2 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008d2:	55                   	push   %ebp
  8008d3:	89 e5                	mov    %esp,%ebp
  8008d5:	57                   	push   %edi
  8008d6:	56                   	push   %esi
  8008d7:	53                   	push   %ebx
  8008d8:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008db:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008de:	85 c9                	test   %ecx,%ecx
  8008e0:	74 36                	je     800918 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008e2:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008e8:	75 28                	jne    800912 <memset+0x40>
  8008ea:	f6 c1 03             	test   $0x3,%cl
  8008ed:	75 23                	jne    800912 <memset+0x40>
		c &= 0xFF;
  8008ef:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008f3:	89 d3                	mov    %edx,%ebx
  8008f5:	c1 e3 08             	shl    $0x8,%ebx
  8008f8:	89 d6                	mov    %edx,%esi
  8008fa:	c1 e6 18             	shl    $0x18,%esi
  8008fd:	89 d0                	mov    %edx,%eax
  8008ff:	c1 e0 10             	shl    $0x10,%eax
  800902:	09 f0                	or     %esi,%eax
  800904:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800906:	89 d8                	mov    %ebx,%eax
  800908:	09 d0                	or     %edx,%eax
  80090a:	c1 e9 02             	shr    $0x2,%ecx
  80090d:	fc                   	cld    
  80090e:	f3 ab                	rep stos %eax,%es:(%edi)
  800910:	eb 06                	jmp    800918 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800912:	8b 45 0c             	mov    0xc(%ebp),%eax
  800915:	fc                   	cld    
  800916:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800918:	89 f8                	mov    %edi,%eax
  80091a:	5b                   	pop    %ebx
  80091b:	5e                   	pop    %esi
  80091c:	5f                   	pop    %edi
  80091d:	5d                   	pop    %ebp
  80091e:	c3                   	ret    

0080091f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80091f:	55                   	push   %ebp
  800920:	89 e5                	mov    %esp,%ebp
  800922:	57                   	push   %edi
  800923:	56                   	push   %esi
  800924:	8b 45 08             	mov    0x8(%ebp),%eax
  800927:	8b 75 0c             	mov    0xc(%ebp),%esi
  80092a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80092d:	39 c6                	cmp    %eax,%esi
  80092f:	73 35                	jae    800966 <memmove+0x47>
  800931:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800934:	39 d0                	cmp    %edx,%eax
  800936:	73 2e                	jae    800966 <memmove+0x47>
		s += n;
		d += n;
  800938:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80093b:	89 d6                	mov    %edx,%esi
  80093d:	09 fe                	or     %edi,%esi
  80093f:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800945:	75 13                	jne    80095a <memmove+0x3b>
  800947:	f6 c1 03             	test   $0x3,%cl
  80094a:	75 0e                	jne    80095a <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80094c:	83 ef 04             	sub    $0x4,%edi
  80094f:	8d 72 fc             	lea    -0x4(%edx),%esi
  800952:	c1 e9 02             	shr    $0x2,%ecx
  800955:	fd                   	std    
  800956:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800958:	eb 09                	jmp    800963 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80095a:	83 ef 01             	sub    $0x1,%edi
  80095d:	8d 72 ff             	lea    -0x1(%edx),%esi
  800960:	fd                   	std    
  800961:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800963:	fc                   	cld    
  800964:	eb 1d                	jmp    800983 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800966:	89 f2                	mov    %esi,%edx
  800968:	09 c2                	or     %eax,%edx
  80096a:	f6 c2 03             	test   $0x3,%dl
  80096d:	75 0f                	jne    80097e <memmove+0x5f>
  80096f:	f6 c1 03             	test   $0x3,%cl
  800972:	75 0a                	jne    80097e <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800974:	c1 e9 02             	shr    $0x2,%ecx
  800977:	89 c7                	mov    %eax,%edi
  800979:	fc                   	cld    
  80097a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80097c:	eb 05                	jmp    800983 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  80097e:	89 c7                	mov    %eax,%edi
  800980:	fc                   	cld    
  800981:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800983:	5e                   	pop    %esi
  800984:	5f                   	pop    %edi
  800985:	5d                   	pop    %ebp
  800986:	c3                   	ret    

00800987 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800987:	55                   	push   %ebp
  800988:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  80098a:	ff 75 10             	pushl  0x10(%ebp)
  80098d:	ff 75 0c             	pushl  0xc(%ebp)
  800990:	ff 75 08             	pushl  0x8(%ebp)
  800993:	e8 87 ff ff ff       	call   80091f <memmove>
}
  800998:	c9                   	leave  
  800999:	c3                   	ret    

0080099a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80099a:	55                   	push   %ebp
  80099b:	89 e5                	mov    %esp,%ebp
  80099d:	56                   	push   %esi
  80099e:	53                   	push   %ebx
  80099f:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a2:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009a5:	89 c6                	mov    %eax,%esi
  8009a7:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009aa:	eb 1a                	jmp    8009c6 <memcmp+0x2c>
		if (*s1 != *s2)
  8009ac:	0f b6 08             	movzbl (%eax),%ecx
  8009af:	0f b6 1a             	movzbl (%edx),%ebx
  8009b2:	38 d9                	cmp    %bl,%cl
  8009b4:	74 0a                	je     8009c0 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009b6:	0f b6 c1             	movzbl %cl,%eax
  8009b9:	0f b6 db             	movzbl %bl,%ebx
  8009bc:	29 d8                	sub    %ebx,%eax
  8009be:	eb 0f                	jmp    8009cf <memcmp+0x35>
		s1++, s2++;
  8009c0:	83 c0 01             	add    $0x1,%eax
  8009c3:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009c6:	39 f0                	cmp    %esi,%eax
  8009c8:	75 e2                	jne    8009ac <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009ca:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009cf:	5b                   	pop    %ebx
  8009d0:	5e                   	pop    %esi
  8009d1:	5d                   	pop    %ebp
  8009d2:	c3                   	ret    

008009d3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009d3:	55                   	push   %ebp
  8009d4:	89 e5                	mov    %esp,%ebp
  8009d6:	53                   	push   %ebx
  8009d7:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009da:	89 c1                	mov    %eax,%ecx
  8009dc:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009df:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009e3:	eb 0a                	jmp    8009ef <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009e5:	0f b6 10             	movzbl (%eax),%edx
  8009e8:	39 da                	cmp    %ebx,%edx
  8009ea:	74 07                	je     8009f3 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009ec:	83 c0 01             	add    $0x1,%eax
  8009ef:	39 c8                	cmp    %ecx,%eax
  8009f1:	72 f2                	jb     8009e5 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009f3:	5b                   	pop    %ebx
  8009f4:	5d                   	pop    %ebp
  8009f5:	c3                   	ret    

008009f6 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009f6:	55                   	push   %ebp
  8009f7:	89 e5                	mov    %esp,%ebp
  8009f9:	57                   	push   %edi
  8009fa:	56                   	push   %esi
  8009fb:	53                   	push   %ebx
  8009fc:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009ff:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a02:	eb 03                	jmp    800a07 <strtol+0x11>
		s++;
  800a04:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a07:	0f b6 01             	movzbl (%ecx),%eax
  800a0a:	3c 20                	cmp    $0x20,%al
  800a0c:	74 f6                	je     800a04 <strtol+0xe>
  800a0e:	3c 09                	cmp    $0x9,%al
  800a10:	74 f2                	je     800a04 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a12:	3c 2b                	cmp    $0x2b,%al
  800a14:	75 0a                	jne    800a20 <strtol+0x2a>
		s++;
  800a16:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a19:	bf 00 00 00 00       	mov    $0x0,%edi
  800a1e:	eb 11                	jmp    800a31 <strtol+0x3b>
  800a20:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a25:	3c 2d                	cmp    $0x2d,%al
  800a27:	75 08                	jne    800a31 <strtol+0x3b>
		s++, neg = 1;
  800a29:	83 c1 01             	add    $0x1,%ecx
  800a2c:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a31:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a37:	75 15                	jne    800a4e <strtol+0x58>
  800a39:	80 39 30             	cmpb   $0x30,(%ecx)
  800a3c:	75 10                	jne    800a4e <strtol+0x58>
  800a3e:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a42:	75 7c                	jne    800ac0 <strtol+0xca>
		s += 2, base = 16;
  800a44:	83 c1 02             	add    $0x2,%ecx
  800a47:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a4c:	eb 16                	jmp    800a64 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a4e:	85 db                	test   %ebx,%ebx
  800a50:	75 12                	jne    800a64 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a52:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a57:	80 39 30             	cmpb   $0x30,(%ecx)
  800a5a:	75 08                	jne    800a64 <strtol+0x6e>
		s++, base = 8;
  800a5c:	83 c1 01             	add    $0x1,%ecx
  800a5f:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a64:	b8 00 00 00 00       	mov    $0x0,%eax
  800a69:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a6c:	0f b6 11             	movzbl (%ecx),%edx
  800a6f:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a72:	89 f3                	mov    %esi,%ebx
  800a74:	80 fb 09             	cmp    $0x9,%bl
  800a77:	77 08                	ja     800a81 <strtol+0x8b>
			dig = *s - '0';
  800a79:	0f be d2             	movsbl %dl,%edx
  800a7c:	83 ea 30             	sub    $0x30,%edx
  800a7f:	eb 22                	jmp    800aa3 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a81:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a84:	89 f3                	mov    %esi,%ebx
  800a86:	80 fb 19             	cmp    $0x19,%bl
  800a89:	77 08                	ja     800a93 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a8b:	0f be d2             	movsbl %dl,%edx
  800a8e:	83 ea 57             	sub    $0x57,%edx
  800a91:	eb 10                	jmp    800aa3 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a93:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a96:	89 f3                	mov    %esi,%ebx
  800a98:	80 fb 19             	cmp    $0x19,%bl
  800a9b:	77 16                	ja     800ab3 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a9d:	0f be d2             	movsbl %dl,%edx
  800aa0:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800aa3:	3b 55 10             	cmp    0x10(%ebp),%edx
  800aa6:	7d 0b                	jge    800ab3 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800aa8:	83 c1 01             	add    $0x1,%ecx
  800aab:	0f af 45 10          	imul   0x10(%ebp),%eax
  800aaf:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ab1:	eb b9                	jmp    800a6c <strtol+0x76>

	if (endptr)
  800ab3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ab7:	74 0d                	je     800ac6 <strtol+0xd0>
		*endptr = (char *) s;
  800ab9:	8b 75 0c             	mov    0xc(%ebp),%esi
  800abc:	89 0e                	mov    %ecx,(%esi)
  800abe:	eb 06                	jmp    800ac6 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ac0:	85 db                	test   %ebx,%ebx
  800ac2:	74 98                	je     800a5c <strtol+0x66>
  800ac4:	eb 9e                	jmp    800a64 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800ac6:	89 c2                	mov    %eax,%edx
  800ac8:	f7 da                	neg    %edx
  800aca:	85 ff                	test   %edi,%edi
  800acc:	0f 45 c2             	cmovne %edx,%eax
}
  800acf:	5b                   	pop    %ebx
  800ad0:	5e                   	pop    %esi
  800ad1:	5f                   	pop    %edi
  800ad2:	5d                   	pop    %ebp
  800ad3:	c3                   	ret    
  800ad4:	66 90                	xchg   %ax,%ax
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

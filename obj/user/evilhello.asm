
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
  800040:	e8 60 00 00 00       	call   8000a5 <sys_cputs>
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
  80004d:	56                   	push   %esi
  80004e:	53                   	push   %ebx
  80004f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800052:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	//thisenv = 0;
	envid_t id = sys_getenvid();
  800055:	e8 c9 00 00 00       	call   800123 <sys_getenvid>
	thisenv = &envs[ENVX(id)];
  80005a:	25 ff 03 00 00       	and    $0x3ff,%eax
  80005f:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800062:	c1 e0 05             	shl    $0x5,%eax
  800065:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80006a:	a3 04 10 80 00       	mov    %eax,0x801004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  80006f:	85 db                	test   %ebx,%ebx
  800071:	7e 07                	jle    80007a <libmain+0x30>
		binaryname = argv[0];
  800073:	8b 06                	mov    (%esi),%eax
  800075:	a3 00 10 80 00       	mov    %eax,0x801000

	// call user main routine
	umain(argc, argv);
  80007a:	83 ec 08             	sub    $0x8,%esp
  80007d:	56                   	push   %esi
  80007e:	53                   	push   %ebx
  80007f:	e8 af ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800084:	e8 0a 00 00 00       	call   800093 <exit>
}
  800089:	83 c4 10             	add    $0x10,%esp
  80008c:	8d 65 f8             	lea    -0x8(%ebp),%esp
  80008f:	5b                   	pop    %ebx
  800090:	5e                   	pop    %esi
  800091:	5d                   	pop    %ebp
  800092:	c3                   	ret    

00800093 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800093:	55                   	push   %ebp
  800094:	89 e5                	mov    %esp,%ebp
  800096:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800099:	6a 00                	push   $0x0
  80009b:	e8 42 00 00 00       	call   8000e2 <sys_env_destroy>
}
  8000a0:	83 c4 10             	add    $0x10,%esp
  8000a3:	c9                   	leave  
  8000a4:	c3                   	ret    

008000a5 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000a5:	55                   	push   %ebp
  8000a6:	89 e5                	mov    %esp,%ebp
  8000a8:	57                   	push   %edi
  8000a9:	56                   	push   %esi
  8000aa:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000ab:	b8 00 00 00 00       	mov    $0x0,%eax
  8000b0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000b3:	8b 55 08             	mov    0x8(%ebp),%edx
  8000b6:	89 c3                	mov    %eax,%ebx
  8000b8:	89 c7                	mov    %eax,%edi
  8000ba:	89 c6                	mov    %eax,%esi
  8000bc:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000be:	5b                   	pop    %ebx
  8000bf:	5e                   	pop    %esi
  8000c0:	5f                   	pop    %edi
  8000c1:	5d                   	pop    %ebp
  8000c2:	c3                   	ret    

008000c3 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000c3:	55                   	push   %ebp
  8000c4:	89 e5                	mov    %esp,%ebp
  8000c6:	57                   	push   %edi
  8000c7:	56                   	push   %esi
  8000c8:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000c9:	ba 00 00 00 00       	mov    $0x0,%edx
  8000ce:	b8 01 00 00 00       	mov    $0x1,%eax
  8000d3:	89 d1                	mov    %edx,%ecx
  8000d5:	89 d3                	mov    %edx,%ebx
  8000d7:	89 d7                	mov    %edx,%edi
  8000d9:	89 d6                	mov    %edx,%esi
  8000db:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000dd:	5b                   	pop    %ebx
  8000de:	5e                   	pop    %esi
  8000df:	5f                   	pop    %edi
  8000e0:	5d                   	pop    %ebp
  8000e1:	c3                   	ret    

008000e2 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000e2:	55                   	push   %ebp
  8000e3:	89 e5                	mov    %esp,%ebp
  8000e5:	57                   	push   %edi
  8000e6:	56                   	push   %esi
  8000e7:	53                   	push   %ebx
  8000e8:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000eb:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000f0:	b8 03 00 00 00       	mov    $0x3,%eax
  8000f5:	8b 55 08             	mov    0x8(%ebp),%edx
  8000f8:	89 cb                	mov    %ecx,%ebx
  8000fa:	89 cf                	mov    %ecx,%edi
  8000fc:	89 ce                	mov    %ecx,%esi
  8000fe:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800100:	85 c0                	test   %eax,%eax
  800102:	7e 17                	jle    80011b <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800104:	83 ec 0c             	sub    $0xc,%esp
  800107:	50                   	push   %eax
  800108:	6a 03                	push   $0x3
  80010a:	68 8a 0d 80 00       	push   $0x800d8a
  80010f:	6a 23                	push   $0x23
  800111:	68 a7 0d 80 00       	push   $0x800da7
  800116:	e8 27 00 00 00       	call   800142 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  80011b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80011e:	5b                   	pop    %ebx
  80011f:	5e                   	pop    %esi
  800120:	5f                   	pop    %edi
  800121:	5d                   	pop    %ebp
  800122:	c3                   	ret    

00800123 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800123:	55                   	push   %ebp
  800124:	89 e5                	mov    %esp,%ebp
  800126:	57                   	push   %edi
  800127:	56                   	push   %esi
  800128:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800129:	ba 00 00 00 00       	mov    $0x0,%edx
  80012e:	b8 02 00 00 00       	mov    $0x2,%eax
  800133:	89 d1                	mov    %edx,%ecx
  800135:	89 d3                	mov    %edx,%ebx
  800137:	89 d7                	mov    %edx,%edi
  800139:	89 d6                	mov    %edx,%esi
  80013b:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80013d:	5b                   	pop    %ebx
  80013e:	5e                   	pop    %esi
  80013f:	5f                   	pop    %edi
  800140:	5d                   	pop    %ebp
  800141:	c3                   	ret    

00800142 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800142:	55                   	push   %ebp
  800143:	89 e5                	mov    %esp,%ebp
  800145:	56                   	push   %esi
  800146:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800147:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80014a:	8b 35 00 10 80 00    	mov    0x801000,%esi
  800150:	e8 ce ff ff ff       	call   800123 <sys_getenvid>
  800155:	83 ec 0c             	sub    $0xc,%esp
  800158:	ff 75 0c             	pushl  0xc(%ebp)
  80015b:	ff 75 08             	pushl  0x8(%ebp)
  80015e:	56                   	push   %esi
  80015f:	50                   	push   %eax
  800160:	68 b8 0d 80 00       	push   $0x800db8
  800165:	e8 b1 00 00 00       	call   80021b <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80016a:	83 c4 18             	add    $0x18,%esp
  80016d:	53                   	push   %ebx
  80016e:	ff 75 10             	pushl  0x10(%ebp)
  800171:	e8 54 00 00 00       	call   8001ca <vcprintf>
	cprintf("\n");
  800176:	c7 04 24 dc 0d 80 00 	movl   $0x800ddc,(%esp)
  80017d:	e8 99 00 00 00       	call   80021b <cprintf>
  800182:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800185:	cc                   	int3   
  800186:	eb fd                	jmp    800185 <_panic+0x43>

00800188 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800188:	55                   	push   %ebp
  800189:	89 e5                	mov    %esp,%ebp
  80018b:	53                   	push   %ebx
  80018c:	83 ec 04             	sub    $0x4,%esp
  80018f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800192:	8b 13                	mov    (%ebx),%edx
  800194:	8d 42 01             	lea    0x1(%edx),%eax
  800197:	89 03                	mov    %eax,(%ebx)
  800199:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80019c:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001a0:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001a5:	75 1a                	jne    8001c1 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8001a7:	83 ec 08             	sub    $0x8,%esp
  8001aa:	68 ff 00 00 00       	push   $0xff
  8001af:	8d 43 08             	lea    0x8(%ebx),%eax
  8001b2:	50                   	push   %eax
  8001b3:	e8 ed fe ff ff       	call   8000a5 <sys_cputs>
		b->idx = 0;
  8001b8:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001be:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001c1:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001c5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001c8:	c9                   	leave  
  8001c9:	c3                   	ret    

008001ca <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001ca:	55                   	push   %ebp
  8001cb:	89 e5                	mov    %esp,%ebp
  8001cd:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001d3:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001da:	00 00 00 
	b.cnt = 0;
  8001dd:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001e4:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001e7:	ff 75 0c             	pushl  0xc(%ebp)
  8001ea:	ff 75 08             	pushl  0x8(%ebp)
  8001ed:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001f3:	50                   	push   %eax
  8001f4:	68 88 01 80 00       	push   $0x800188
  8001f9:	e8 54 01 00 00       	call   800352 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001fe:	83 c4 08             	add    $0x8,%esp
  800201:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800207:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80020d:	50                   	push   %eax
  80020e:	e8 92 fe ff ff       	call   8000a5 <sys_cputs>

	return b.cnt;
}
  800213:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800219:	c9                   	leave  
  80021a:	c3                   	ret    

0080021b <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80021b:	55                   	push   %ebp
  80021c:	89 e5                	mov    %esp,%ebp
  80021e:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800221:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800224:	50                   	push   %eax
  800225:	ff 75 08             	pushl  0x8(%ebp)
  800228:	e8 9d ff ff ff       	call   8001ca <vcprintf>
	va_end(ap);

	return cnt;
}
  80022d:	c9                   	leave  
  80022e:	c3                   	ret    

0080022f <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80022f:	55                   	push   %ebp
  800230:	89 e5                	mov    %esp,%ebp
  800232:	57                   	push   %edi
  800233:	56                   	push   %esi
  800234:	53                   	push   %ebx
  800235:	83 ec 1c             	sub    $0x1c,%esp
  800238:	89 c7                	mov    %eax,%edi
  80023a:	89 d6                	mov    %edx,%esi
  80023c:	8b 45 08             	mov    0x8(%ebp),%eax
  80023f:	8b 55 0c             	mov    0xc(%ebp),%edx
  800242:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800245:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800248:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80024b:	bb 00 00 00 00       	mov    $0x0,%ebx
  800250:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800253:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800256:	39 d3                	cmp    %edx,%ebx
  800258:	72 05                	jb     80025f <printnum+0x30>
  80025a:	39 45 10             	cmp    %eax,0x10(%ebp)
  80025d:	77 45                	ja     8002a4 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80025f:	83 ec 0c             	sub    $0xc,%esp
  800262:	ff 75 18             	pushl  0x18(%ebp)
  800265:	8b 45 14             	mov    0x14(%ebp),%eax
  800268:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80026b:	53                   	push   %ebx
  80026c:	ff 75 10             	pushl  0x10(%ebp)
  80026f:	83 ec 08             	sub    $0x8,%esp
  800272:	ff 75 e4             	pushl  -0x1c(%ebp)
  800275:	ff 75 e0             	pushl  -0x20(%ebp)
  800278:	ff 75 dc             	pushl  -0x24(%ebp)
  80027b:	ff 75 d8             	pushl  -0x28(%ebp)
  80027e:	e8 6d 08 00 00       	call   800af0 <__udivdi3>
  800283:	83 c4 18             	add    $0x18,%esp
  800286:	52                   	push   %edx
  800287:	50                   	push   %eax
  800288:	89 f2                	mov    %esi,%edx
  80028a:	89 f8                	mov    %edi,%eax
  80028c:	e8 9e ff ff ff       	call   80022f <printnum>
  800291:	83 c4 20             	add    $0x20,%esp
  800294:	eb 18                	jmp    8002ae <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800296:	83 ec 08             	sub    $0x8,%esp
  800299:	56                   	push   %esi
  80029a:	ff 75 18             	pushl  0x18(%ebp)
  80029d:	ff d7                	call   *%edi
  80029f:	83 c4 10             	add    $0x10,%esp
  8002a2:	eb 03                	jmp    8002a7 <printnum+0x78>
  8002a4:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002a7:	83 eb 01             	sub    $0x1,%ebx
  8002aa:	85 db                	test   %ebx,%ebx
  8002ac:	7f e8                	jg     800296 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002ae:	83 ec 08             	sub    $0x8,%esp
  8002b1:	56                   	push   %esi
  8002b2:	83 ec 04             	sub    $0x4,%esp
  8002b5:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002b8:	ff 75 e0             	pushl  -0x20(%ebp)
  8002bb:	ff 75 dc             	pushl  -0x24(%ebp)
  8002be:	ff 75 d8             	pushl  -0x28(%ebp)
  8002c1:	e8 5a 09 00 00       	call   800c20 <__umoddi3>
  8002c6:	83 c4 14             	add    $0x14,%esp
  8002c9:	0f be 80 de 0d 80 00 	movsbl 0x800dde(%eax),%eax
  8002d0:	50                   	push   %eax
  8002d1:	ff d7                	call   *%edi
}
  8002d3:	83 c4 10             	add    $0x10,%esp
  8002d6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002d9:	5b                   	pop    %ebx
  8002da:	5e                   	pop    %esi
  8002db:	5f                   	pop    %edi
  8002dc:	5d                   	pop    %ebp
  8002dd:	c3                   	ret    

008002de <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002de:	55                   	push   %ebp
  8002df:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002e1:	83 fa 01             	cmp    $0x1,%edx
  8002e4:	7e 0e                	jle    8002f4 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002e6:	8b 10                	mov    (%eax),%edx
  8002e8:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002eb:	89 08                	mov    %ecx,(%eax)
  8002ed:	8b 02                	mov    (%edx),%eax
  8002ef:	8b 52 04             	mov    0x4(%edx),%edx
  8002f2:	eb 22                	jmp    800316 <getuint+0x38>
	else if (lflag)
  8002f4:	85 d2                	test   %edx,%edx
  8002f6:	74 10                	je     800308 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002f8:	8b 10                	mov    (%eax),%edx
  8002fa:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002fd:	89 08                	mov    %ecx,(%eax)
  8002ff:	8b 02                	mov    (%edx),%eax
  800301:	ba 00 00 00 00       	mov    $0x0,%edx
  800306:	eb 0e                	jmp    800316 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800308:	8b 10                	mov    (%eax),%edx
  80030a:	8d 4a 04             	lea    0x4(%edx),%ecx
  80030d:	89 08                	mov    %ecx,(%eax)
  80030f:	8b 02                	mov    (%edx),%eax
  800311:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800316:	5d                   	pop    %ebp
  800317:	c3                   	ret    

00800318 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800318:	55                   	push   %ebp
  800319:	89 e5                	mov    %esp,%ebp
  80031b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80031e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800322:	8b 10                	mov    (%eax),%edx
  800324:	3b 50 04             	cmp    0x4(%eax),%edx
  800327:	73 0a                	jae    800333 <sprintputch+0x1b>
		*b->buf++ = ch;
  800329:	8d 4a 01             	lea    0x1(%edx),%ecx
  80032c:	89 08                	mov    %ecx,(%eax)
  80032e:	8b 45 08             	mov    0x8(%ebp),%eax
  800331:	88 02                	mov    %al,(%edx)
}
  800333:	5d                   	pop    %ebp
  800334:	c3                   	ret    

00800335 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800335:	55                   	push   %ebp
  800336:	89 e5                	mov    %esp,%ebp
  800338:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80033b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80033e:	50                   	push   %eax
  80033f:	ff 75 10             	pushl  0x10(%ebp)
  800342:	ff 75 0c             	pushl  0xc(%ebp)
  800345:	ff 75 08             	pushl  0x8(%ebp)
  800348:	e8 05 00 00 00       	call   800352 <vprintfmt>
	va_end(ap);
}
  80034d:	83 c4 10             	add    $0x10,%esp
  800350:	c9                   	leave  
  800351:	c3                   	ret    

00800352 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800352:	55                   	push   %ebp
  800353:	89 e5                	mov    %esp,%ebp
  800355:	57                   	push   %edi
  800356:	56                   	push   %esi
  800357:	53                   	push   %ebx
  800358:	83 ec 2c             	sub    $0x2c,%esp
  80035b:	8b 75 08             	mov    0x8(%ebp),%esi
  80035e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800361:	8b 7d 10             	mov    0x10(%ebp),%edi
  800364:	eb 12                	jmp    800378 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800366:	85 c0                	test   %eax,%eax
  800368:	0f 84 89 03 00 00    	je     8006f7 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  80036e:	83 ec 08             	sub    $0x8,%esp
  800371:	53                   	push   %ebx
  800372:	50                   	push   %eax
  800373:	ff d6                	call   *%esi
  800375:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800378:	83 c7 01             	add    $0x1,%edi
  80037b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80037f:	83 f8 25             	cmp    $0x25,%eax
  800382:	75 e2                	jne    800366 <vprintfmt+0x14>
  800384:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800388:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80038f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800396:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80039d:	ba 00 00 00 00       	mov    $0x0,%edx
  8003a2:	eb 07                	jmp    8003ab <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a4:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8003a7:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ab:	8d 47 01             	lea    0x1(%edi),%eax
  8003ae:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003b1:	0f b6 07             	movzbl (%edi),%eax
  8003b4:	0f b6 c8             	movzbl %al,%ecx
  8003b7:	83 e8 23             	sub    $0x23,%eax
  8003ba:	3c 55                	cmp    $0x55,%al
  8003bc:	0f 87 1a 03 00 00    	ja     8006dc <vprintfmt+0x38a>
  8003c2:	0f b6 c0             	movzbl %al,%eax
  8003c5:	ff 24 85 80 0e 80 00 	jmp    *0x800e80(,%eax,4)
  8003cc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003cf:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003d3:	eb d6                	jmp    8003ab <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003d8:	b8 00 00 00 00       	mov    $0x0,%eax
  8003dd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003e0:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003e3:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  8003e7:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  8003ea:	8d 51 d0             	lea    -0x30(%ecx),%edx
  8003ed:	83 fa 09             	cmp    $0x9,%edx
  8003f0:	77 39                	ja     80042b <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003f2:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003f5:	eb e9                	jmp    8003e0 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003f7:	8b 45 14             	mov    0x14(%ebp),%eax
  8003fa:	8d 48 04             	lea    0x4(%eax),%ecx
  8003fd:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800400:	8b 00                	mov    (%eax),%eax
  800402:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800405:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800408:	eb 27                	jmp    800431 <vprintfmt+0xdf>
  80040a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80040d:	85 c0                	test   %eax,%eax
  80040f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800414:	0f 49 c8             	cmovns %eax,%ecx
  800417:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80041a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80041d:	eb 8c                	jmp    8003ab <vprintfmt+0x59>
  80041f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800422:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800429:	eb 80                	jmp    8003ab <vprintfmt+0x59>
  80042b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80042e:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800431:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800435:	0f 89 70 ff ff ff    	jns    8003ab <vprintfmt+0x59>
				width = precision, precision = -1;
  80043b:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80043e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800441:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800448:	e9 5e ff ff ff       	jmp    8003ab <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80044d:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800450:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800453:	e9 53 ff ff ff       	jmp    8003ab <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800458:	8b 45 14             	mov    0x14(%ebp),%eax
  80045b:	8d 50 04             	lea    0x4(%eax),%edx
  80045e:	89 55 14             	mov    %edx,0x14(%ebp)
  800461:	83 ec 08             	sub    $0x8,%esp
  800464:	53                   	push   %ebx
  800465:	ff 30                	pushl  (%eax)
  800467:	ff d6                	call   *%esi
			break;
  800469:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80046c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80046f:	e9 04 ff ff ff       	jmp    800378 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800474:	8b 45 14             	mov    0x14(%ebp),%eax
  800477:	8d 50 04             	lea    0x4(%eax),%edx
  80047a:	89 55 14             	mov    %edx,0x14(%ebp)
  80047d:	8b 00                	mov    (%eax),%eax
  80047f:	99                   	cltd   
  800480:	31 d0                	xor    %edx,%eax
  800482:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800484:	83 f8 07             	cmp    $0x7,%eax
  800487:	7f 0b                	jg     800494 <vprintfmt+0x142>
  800489:	8b 14 85 e0 0f 80 00 	mov    0x800fe0(,%eax,4),%edx
  800490:	85 d2                	test   %edx,%edx
  800492:	75 18                	jne    8004ac <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800494:	50                   	push   %eax
  800495:	68 f6 0d 80 00       	push   $0x800df6
  80049a:	53                   	push   %ebx
  80049b:	56                   	push   %esi
  80049c:	e8 94 fe ff ff       	call   800335 <printfmt>
  8004a1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004a4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8004a7:	e9 cc fe ff ff       	jmp    800378 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8004ac:	52                   	push   %edx
  8004ad:	68 ff 0d 80 00       	push   $0x800dff
  8004b2:	53                   	push   %ebx
  8004b3:	56                   	push   %esi
  8004b4:	e8 7c fe ff ff       	call   800335 <printfmt>
  8004b9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004bc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004bf:	e9 b4 fe ff ff       	jmp    800378 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004c4:	8b 45 14             	mov    0x14(%ebp),%eax
  8004c7:	8d 50 04             	lea    0x4(%eax),%edx
  8004ca:	89 55 14             	mov    %edx,0x14(%ebp)
  8004cd:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004cf:	85 ff                	test   %edi,%edi
  8004d1:	b8 ef 0d 80 00       	mov    $0x800def,%eax
  8004d6:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004d9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004dd:	0f 8e 94 00 00 00    	jle    800577 <vprintfmt+0x225>
  8004e3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004e7:	0f 84 98 00 00 00    	je     800585 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004ed:	83 ec 08             	sub    $0x8,%esp
  8004f0:	ff 75 d0             	pushl  -0x30(%ebp)
  8004f3:	57                   	push   %edi
  8004f4:	e8 86 02 00 00       	call   80077f <strnlen>
  8004f9:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004fc:	29 c1                	sub    %eax,%ecx
  8004fe:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800501:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800504:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800508:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80050b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80050e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800510:	eb 0f                	jmp    800521 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800512:	83 ec 08             	sub    $0x8,%esp
  800515:	53                   	push   %ebx
  800516:	ff 75 e0             	pushl  -0x20(%ebp)
  800519:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80051b:	83 ef 01             	sub    $0x1,%edi
  80051e:	83 c4 10             	add    $0x10,%esp
  800521:	85 ff                	test   %edi,%edi
  800523:	7f ed                	jg     800512 <vprintfmt+0x1c0>
  800525:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800528:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80052b:	85 c9                	test   %ecx,%ecx
  80052d:	b8 00 00 00 00       	mov    $0x0,%eax
  800532:	0f 49 c1             	cmovns %ecx,%eax
  800535:	29 c1                	sub    %eax,%ecx
  800537:	89 75 08             	mov    %esi,0x8(%ebp)
  80053a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80053d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800540:	89 cb                	mov    %ecx,%ebx
  800542:	eb 4d                	jmp    800591 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800544:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800548:	74 1b                	je     800565 <vprintfmt+0x213>
  80054a:	0f be c0             	movsbl %al,%eax
  80054d:	83 e8 20             	sub    $0x20,%eax
  800550:	83 f8 5e             	cmp    $0x5e,%eax
  800553:	76 10                	jbe    800565 <vprintfmt+0x213>
					putch('?', putdat);
  800555:	83 ec 08             	sub    $0x8,%esp
  800558:	ff 75 0c             	pushl  0xc(%ebp)
  80055b:	6a 3f                	push   $0x3f
  80055d:	ff 55 08             	call   *0x8(%ebp)
  800560:	83 c4 10             	add    $0x10,%esp
  800563:	eb 0d                	jmp    800572 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800565:	83 ec 08             	sub    $0x8,%esp
  800568:	ff 75 0c             	pushl  0xc(%ebp)
  80056b:	52                   	push   %edx
  80056c:	ff 55 08             	call   *0x8(%ebp)
  80056f:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800572:	83 eb 01             	sub    $0x1,%ebx
  800575:	eb 1a                	jmp    800591 <vprintfmt+0x23f>
  800577:	89 75 08             	mov    %esi,0x8(%ebp)
  80057a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80057d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800580:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800583:	eb 0c                	jmp    800591 <vprintfmt+0x23f>
  800585:	89 75 08             	mov    %esi,0x8(%ebp)
  800588:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80058b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80058e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800591:	83 c7 01             	add    $0x1,%edi
  800594:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800598:	0f be d0             	movsbl %al,%edx
  80059b:	85 d2                	test   %edx,%edx
  80059d:	74 23                	je     8005c2 <vprintfmt+0x270>
  80059f:	85 f6                	test   %esi,%esi
  8005a1:	78 a1                	js     800544 <vprintfmt+0x1f2>
  8005a3:	83 ee 01             	sub    $0x1,%esi
  8005a6:	79 9c                	jns    800544 <vprintfmt+0x1f2>
  8005a8:	89 df                	mov    %ebx,%edi
  8005aa:	8b 75 08             	mov    0x8(%ebp),%esi
  8005ad:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005b0:	eb 18                	jmp    8005ca <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005b2:	83 ec 08             	sub    $0x8,%esp
  8005b5:	53                   	push   %ebx
  8005b6:	6a 20                	push   $0x20
  8005b8:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005ba:	83 ef 01             	sub    $0x1,%edi
  8005bd:	83 c4 10             	add    $0x10,%esp
  8005c0:	eb 08                	jmp    8005ca <vprintfmt+0x278>
  8005c2:	89 df                	mov    %ebx,%edi
  8005c4:	8b 75 08             	mov    0x8(%ebp),%esi
  8005c7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005ca:	85 ff                	test   %edi,%edi
  8005cc:	7f e4                	jg     8005b2 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005ce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005d1:	e9 a2 fd ff ff       	jmp    800378 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005d6:	83 fa 01             	cmp    $0x1,%edx
  8005d9:	7e 16                	jle    8005f1 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  8005db:	8b 45 14             	mov    0x14(%ebp),%eax
  8005de:	8d 50 08             	lea    0x8(%eax),%edx
  8005e1:	89 55 14             	mov    %edx,0x14(%ebp)
  8005e4:	8b 50 04             	mov    0x4(%eax),%edx
  8005e7:	8b 00                	mov    (%eax),%eax
  8005e9:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005ec:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005ef:	eb 32                	jmp    800623 <vprintfmt+0x2d1>
	else if (lflag)
  8005f1:	85 d2                	test   %edx,%edx
  8005f3:	74 18                	je     80060d <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  8005f5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f8:	8d 50 04             	lea    0x4(%eax),%edx
  8005fb:	89 55 14             	mov    %edx,0x14(%ebp)
  8005fe:	8b 00                	mov    (%eax),%eax
  800600:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800603:	89 c1                	mov    %eax,%ecx
  800605:	c1 f9 1f             	sar    $0x1f,%ecx
  800608:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80060b:	eb 16                	jmp    800623 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  80060d:	8b 45 14             	mov    0x14(%ebp),%eax
  800610:	8d 50 04             	lea    0x4(%eax),%edx
  800613:	89 55 14             	mov    %edx,0x14(%ebp)
  800616:	8b 00                	mov    (%eax),%eax
  800618:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80061b:	89 c1                	mov    %eax,%ecx
  80061d:	c1 f9 1f             	sar    $0x1f,%ecx
  800620:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800623:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800626:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800629:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80062e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800632:	79 74                	jns    8006a8 <vprintfmt+0x356>
				putch('-', putdat);
  800634:	83 ec 08             	sub    $0x8,%esp
  800637:	53                   	push   %ebx
  800638:	6a 2d                	push   $0x2d
  80063a:	ff d6                	call   *%esi
				num = -(long long) num;
  80063c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80063f:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800642:	f7 d8                	neg    %eax
  800644:	83 d2 00             	adc    $0x0,%edx
  800647:	f7 da                	neg    %edx
  800649:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80064c:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800651:	eb 55                	jmp    8006a8 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800653:	8d 45 14             	lea    0x14(%ebp),%eax
  800656:	e8 83 fc ff ff       	call   8002de <getuint>
			base = 10;
  80065b:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800660:	eb 46                	jmp    8006a8 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800662:	8d 45 14             	lea    0x14(%ebp),%eax
  800665:	e8 74 fc ff ff       	call   8002de <getuint>
			base = 8;
  80066a:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80066f:	eb 37                	jmp    8006a8 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  800671:	83 ec 08             	sub    $0x8,%esp
  800674:	53                   	push   %ebx
  800675:	6a 30                	push   $0x30
  800677:	ff d6                	call   *%esi
			putch('x', putdat);
  800679:	83 c4 08             	add    $0x8,%esp
  80067c:	53                   	push   %ebx
  80067d:	6a 78                	push   $0x78
  80067f:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800681:	8b 45 14             	mov    0x14(%ebp),%eax
  800684:	8d 50 04             	lea    0x4(%eax),%edx
  800687:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80068a:	8b 00                	mov    (%eax),%eax
  80068c:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800691:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800694:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800699:	eb 0d                	jmp    8006a8 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  80069b:	8d 45 14             	lea    0x14(%ebp),%eax
  80069e:	e8 3b fc ff ff       	call   8002de <getuint>
			base = 16;
  8006a3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006a8:	83 ec 0c             	sub    $0xc,%esp
  8006ab:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8006af:	57                   	push   %edi
  8006b0:	ff 75 e0             	pushl  -0x20(%ebp)
  8006b3:	51                   	push   %ecx
  8006b4:	52                   	push   %edx
  8006b5:	50                   	push   %eax
  8006b6:	89 da                	mov    %ebx,%edx
  8006b8:	89 f0                	mov    %esi,%eax
  8006ba:	e8 70 fb ff ff       	call   80022f <printnum>
			break;
  8006bf:	83 c4 20             	add    $0x20,%esp
  8006c2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006c5:	e9 ae fc ff ff       	jmp    800378 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006ca:	83 ec 08             	sub    $0x8,%esp
  8006cd:	53                   	push   %ebx
  8006ce:	51                   	push   %ecx
  8006cf:	ff d6                	call   *%esi
			break;
  8006d1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006d4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006d7:	e9 9c fc ff ff       	jmp    800378 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006dc:	83 ec 08             	sub    $0x8,%esp
  8006df:	53                   	push   %ebx
  8006e0:	6a 25                	push   $0x25
  8006e2:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006e4:	83 c4 10             	add    $0x10,%esp
  8006e7:	eb 03                	jmp    8006ec <vprintfmt+0x39a>
  8006e9:	83 ef 01             	sub    $0x1,%edi
  8006ec:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006f0:	75 f7                	jne    8006e9 <vprintfmt+0x397>
  8006f2:	e9 81 fc ff ff       	jmp    800378 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006f7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006fa:	5b                   	pop    %ebx
  8006fb:	5e                   	pop    %esi
  8006fc:	5f                   	pop    %edi
  8006fd:	5d                   	pop    %ebp
  8006fe:	c3                   	ret    

008006ff <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006ff:	55                   	push   %ebp
  800700:	89 e5                	mov    %esp,%ebp
  800702:	83 ec 18             	sub    $0x18,%esp
  800705:	8b 45 08             	mov    0x8(%ebp),%eax
  800708:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80070b:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80070e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800712:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800715:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80071c:	85 c0                	test   %eax,%eax
  80071e:	74 26                	je     800746 <vsnprintf+0x47>
  800720:	85 d2                	test   %edx,%edx
  800722:	7e 22                	jle    800746 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800724:	ff 75 14             	pushl  0x14(%ebp)
  800727:	ff 75 10             	pushl  0x10(%ebp)
  80072a:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80072d:	50                   	push   %eax
  80072e:	68 18 03 80 00       	push   $0x800318
  800733:	e8 1a fc ff ff       	call   800352 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800738:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80073b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80073e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800741:	83 c4 10             	add    $0x10,%esp
  800744:	eb 05                	jmp    80074b <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800746:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80074b:	c9                   	leave  
  80074c:	c3                   	ret    

0080074d <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80074d:	55                   	push   %ebp
  80074e:	89 e5                	mov    %esp,%ebp
  800750:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800753:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800756:	50                   	push   %eax
  800757:	ff 75 10             	pushl  0x10(%ebp)
  80075a:	ff 75 0c             	pushl  0xc(%ebp)
  80075d:	ff 75 08             	pushl  0x8(%ebp)
  800760:	e8 9a ff ff ff       	call   8006ff <vsnprintf>
	va_end(ap);

	return rc;
}
  800765:	c9                   	leave  
  800766:	c3                   	ret    

00800767 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800767:	55                   	push   %ebp
  800768:	89 e5                	mov    %esp,%ebp
  80076a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80076d:	b8 00 00 00 00       	mov    $0x0,%eax
  800772:	eb 03                	jmp    800777 <strlen+0x10>
		n++;
  800774:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800777:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80077b:	75 f7                	jne    800774 <strlen+0xd>
		n++;
	return n;
}
  80077d:	5d                   	pop    %ebp
  80077e:	c3                   	ret    

0080077f <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80077f:	55                   	push   %ebp
  800780:	89 e5                	mov    %esp,%ebp
  800782:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800785:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800788:	ba 00 00 00 00       	mov    $0x0,%edx
  80078d:	eb 03                	jmp    800792 <strnlen+0x13>
		n++;
  80078f:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800792:	39 c2                	cmp    %eax,%edx
  800794:	74 08                	je     80079e <strnlen+0x1f>
  800796:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80079a:	75 f3                	jne    80078f <strnlen+0x10>
  80079c:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80079e:	5d                   	pop    %ebp
  80079f:	c3                   	ret    

008007a0 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007a0:	55                   	push   %ebp
  8007a1:	89 e5                	mov    %esp,%ebp
  8007a3:	53                   	push   %ebx
  8007a4:	8b 45 08             	mov    0x8(%ebp),%eax
  8007a7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007aa:	89 c2                	mov    %eax,%edx
  8007ac:	83 c2 01             	add    $0x1,%edx
  8007af:	83 c1 01             	add    $0x1,%ecx
  8007b2:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007b6:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007b9:	84 db                	test   %bl,%bl
  8007bb:	75 ef                	jne    8007ac <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007bd:	5b                   	pop    %ebx
  8007be:	5d                   	pop    %ebp
  8007bf:	c3                   	ret    

008007c0 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007c0:	55                   	push   %ebp
  8007c1:	89 e5                	mov    %esp,%ebp
  8007c3:	53                   	push   %ebx
  8007c4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007c7:	53                   	push   %ebx
  8007c8:	e8 9a ff ff ff       	call   800767 <strlen>
  8007cd:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007d0:	ff 75 0c             	pushl  0xc(%ebp)
  8007d3:	01 d8                	add    %ebx,%eax
  8007d5:	50                   	push   %eax
  8007d6:	e8 c5 ff ff ff       	call   8007a0 <strcpy>
	return dst;
}
  8007db:	89 d8                	mov    %ebx,%eax
  8007dd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007e0:	c9                   	leave  
  8007e1:	c3                   	ret    

008007e2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007e2:	55                   	push   %ebp
  8007e3:	89 e5                	mov    %esp,%ebp
  8007e5:	56                   	push   %esi
  8007e6:	53                   	push   %ebx
  8007e7:	8b 75 08             	mov    0x8(%ebp),%esi
  8007ea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007ed:	89 f3                	mov    %esi,%ebx
  8007ef:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007f2:	89 f2                	mov    %esi,%edx
  8007f4:	eb 0f                	jmp    800805 <strncpy+0x23>
		*dst++ = *src;
  8007f6:	83 c2 01             	add    $0x1,%edx
  8007f9:	0f b6 01             	movzbl (%ecx),%eax
  8007fc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007ff:	80 39 01             	cmpb   $0x1,(%ecx)
  800802:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800805:	39 da                	cmp    %ebx,%edx
  800807:	75 ed                	jne    8007f6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800809:	89 f0                	mov    %esi,%eax
  80080b:	5b                   	pop    %ebx
  80080c:	5e                   	pop    %esi
  80080d:	5d                   	pop    %ebp
  80080e:	c3                   	ret    

0080080f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80080f:	55                   	push   %ebp
  800810:	89 e5                	mov    %esp,%ebp
  800812:	56                   	push   %esi
  800813:	53                   	push   %ebx
  800814:	8b 75 08             	mov    0x8(%ebp),%esi
  800817:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80081a:	8b 55 10             	mov    0x10(%ebp),%edx
  80081d:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80081f:	85 d2                	test   %edx,%edx
  800821:	74 21                	je     800844 <strlcpy+0x35>
  800823:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800827:	89 f2                	mov    %esi,%edx
  800829:	eb 09                	jmp    800834 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80082b:	83 c2 01             	add    $0x1,%edx
  80082e:	83 c1 01             	add    $0x1,%ecx
  800831:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800834:	39 c2                	cmp    %eax,%edx
  800836:	74 09                	je     800841 <strlcpy+0x32>
  800838:	0f b6 19             	movzbl (%ecx),%ebx
  80083b:	84 db                	test   %bl,%bl
  80083d:	75 ec                	jne    80082b <strlcpy+0x1c>
  80083f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800841:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800844:	29 f0                	sub    %esi,%eax
}
  800846:	5b                   	pop    %ebx
  800847:	5e                   	pop    %esi
  800848:	5d                   	pop    %ebp
  800849:	c3                   	ret    

0080084a <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80084a:	55                   	push   %ebp
  80084b:	89 e5                	mov    %esp,%ebp
  80084d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800850:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800853:	eb 06                	jmp    80085b <strcmp+0x11>
		p++, q++;
  800855:	83 c1 01             	add    $0x1,%ecx
  800858:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80085b:	0f b6 01             	movzbl (%ecx),%eax
  80085e:	84 c0                	test   %al,%al
  800860:	74 04                	je     800866 <strcmp+0x1c>
  800862:	3a 02                	cmp    (%edx),%al
  800864:	74 ef                	je     800855 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800866:	0f b6 c0             	movzbl %al,%eax
  800869:	0f b6 12             	movzbl (%edx),%edx
  80086c:	29 d0                	sub    %edx,%eax
}
  80086e:	5d                   	pop    %ebp
  80086f:	c3                   	ret    

00800870 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800870:	55                   	push   %ebp
  800871:	89 e5                	mov    %esp,%ebp
  800873:	53                   	push   %ebx
  800874:	8b 45 08             	mov    0x8(%ebp),%eax
  800877:	8b 55 0c             	mov    0xc(%ebp),%edx
  80087a:	89 c3                	mov    %eax,%ebx
  80087c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80087f:	eb 06                	jmp    800887 <strncmp+0x17>
		n--, p++, q++;
  800881:	83 c0 01             	add    $0x1,%eax
  800884:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800887:	39 d8                	cmp    %ebx,%eax
  800889:	74 15                	je     8008a0 <strncmp+0x30>
  80088b:	0f b6 08             	movzbl (%eax),%ecx
  80088e:	84 c9                	test   %cl,%cl
  800890:	74 04                	je     800896 <strncmp+0x26>
  800892:	3a 0a                	cmp    (%edx),%cl
  800894:	74 eb                	je     800881 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800896:	0f b6 00             	movzbl (%eax),%eax
  800899:	0f b6 12             	movzbl (%edx),%edx
  80089c:	29 d0                	sub    %edx,%eax
  80089e:	eb 05                	jmp    8008a5 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008a0:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008a5:	5b                   	pop    %ebx
  8008a6:	5d                   	pop    %ebp
  8008a7:	c3                   	ret    

008008a8 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008a8:	55                   	push   %ebp
  8008a9:	89 e5                	mov    %esp,%ebp
  8008ab:	8b 45 08             	mov    0x8(%ebp),%eax
  8008ae:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008b2:	eb 07                	jmp    8008bb <strchr+0x13>
		if (*s == c)
  8008b4:	38 ca                	cmp    %cl,%dl
  8008b6:	74 0f                	je     8008c7 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008b8:	83 c0 01             	add    $0x1,%eax
  8008bb:	0f b6 10             	movzbl (%eax),%edx
  8008be:	84 d2                	test   %dl,%dl
  8008c0:	75 f2                	jne    8008b4 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008c7:	5d                   	pop    %ebp
  8008c8:	c3                   	ret    

008008c9 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008c9:	55                   	push   %ebp
  8008ca:	89 e5                	mov    %esp,%ebp
  8008cc:	8b 45 08             	mov    0x8(%ebp),%eax
  8008cf:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008d3:	eb 03                	jmp    8008d8 <strfind+0xf>
  8008d5:	83 c0 01             	add    $0x1,%eax
  8008d8:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008db:	38 ca                	cmp    %cl,%dl
  8008dd:	74 04                	je     8008e3 <strfind+0x1a>
  8008df:	84 d2                	test   %dl,%dl
  8008e1:	75 f2                	jne    8008d5 <strfind+0xc>
			break;
	return (char *) s;
}
  8008e3:	5d                   	pop    %ebp
  8008e4:	c3                   	ret    

008008e5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008e5:	55                   	push   %ebp
  8008e6:	89 e5                	mov    %esp,%ebp
  8008e8:	57                   	push   %edi
  8008e9:	56                   	push   %esi
  8008ea:	53                   	push   %ebx
  8008eb:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008ee:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008f1:	85 c9                	test   %ecx,%ecx
  8008f3:	74 36                	je     80092b <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008f5:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008fb:	75 28                	jne    800925 <memset+0x40>
  8008fd:	f6 c1 03             	test   $0x3,%cl
  800900:	75 23                	jne    800925 <memset+0x40>
		c &= 0xFF;
  800902:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800906:	89 d3                	mov    %edx,%ebx
  800908:	c1 e3 08             	shl    $0x8,%ebx
  80090b:	89 d6                	mov    %edx,%esi
  80090d:	c1 e6 18             	shl    $0x18,%esi
  800910:	89 d0                	mov    %edx,%eax
  800912:	c1 e0 10             	shl    $0x10,%eax
  800915:	09 f0                	or     %esi,%eax
  800917:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800919:	89 d8                	mov    %ebx,%eax
  80091b:	09 d0                	or     %edx,%eax
  80091d:	c1 e9 02             	shr    $0x2,%ecx
  800920:	fc                   	cld    
  800921:	f3 ab                	rep stos %eax,%es:(%edi)
  800923:	eb 06                	jmp    80092b <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800925:	8b 45 0c             	mov    0xc(%ebp),%eax
  800928:	fc                   	cld    
  800929:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80092b:	89 f8                	mov    %edi,%eax
  80092d:	5b                   	pop    %ebx
  80092e:	5e                   	pop    %esi
  80092f:	5f                   	pop    %edi
  800930:	5d                   	pop    %ebp
  800931:	c3                   	ret    

00800932 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800932:	55                   	push   %ebp
  800933:	89 e5                	mov    %esp,%ebp
  800935:	57                   	push   %edi
  800936:	56                   	push   %esi
  800937:	8b 45 08             	mov    0x8(%ebp),%eax
  80093a:	8b 75 0c             	mov    0xc(%ebp),%esi
  80093d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800940:	39 c6                	cmp    %eax,%esi
  800942:	73 35                	jae    800979 <memmove+0x47>
  800944:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800947:	39 d0                	cmp    %edx,%eax
  800949:	73 2e                	jae    800979 <memmove+0x47>
		s += n;
		d += n;
  80094b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80094e:	89 d6                	mov    %edx,%esi
  800950:	09 fe                	or     %edi,%esi
  800952:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800958:	75 13                	jne    80096d <memmove+0x3b>
  80095a:	f6 c1 03             	test   $0x3,%cl
  80095d:	75 0e                	jne    80096d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80095f:	83 ef 04             	sub    $0x4,%edi
  800962:	8d 72 fc             	lea    -0x4(%edx),%esi
  800965:	c1 e9 02             	shr    $0x2,%ecx
  800968:	fd                   	std    
  800969:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80096b:	eb 09                	jmp    800976 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80096d:	83 ef 01             	sub    $0x1,%edi
  800970:	8d 72 ff             	lea    -0x1(%edx),%esi
  800973:	fd                   	std    
  800974:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800976:	fc                   	cld    
  800977:	eb 1d                	jmp    800996 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800979:	89 f2                	mov    %esi,%edx
  80097b:	09 c2                	or     %eax,%edx
  80097d:	f6 c2 03             	test   $0x3,%dl
  800980:	75 0f                	jne    800991 <memmove+0x5f>
  800982:	f6 c1 03             	test   $0x3,%cl
  800985:	75 0a                	jne    800991 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800987:	c1 e9 02             	shr    $0x2,%ecx
  80098a:	89 c7                	mov    %eax,%edi
  80098c:	fc                   	cld    
  80098d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80098f:	eb 05                	jmp    800996 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800991:	89 c7                	mov    %eax,%edi
  800993:	fc                   	cld    
  800994:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800996:	5e                   	pop    %esi
  800997:	5f                   	pop    %edi
  800998:	5d                   	pop    %ebp
  800999:	c3                   	ret    

0080099a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80099a:	55                   	push   %ebp
  80099b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  80099d:	ff 75 10             	pushl  0x10(%ebp)
  8009a0:	ff 75 0c             	pushl  0xc(%ebp)
  8009a3:	ff 75 08             	pushl  0x8(%ebp)
  8009a6:	e8 87 ff ff ff       	call   800932 <memmove>
}
  8009ab:	c9                   	leave  
  8009ac:	c3                   	ret    

008009ad <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009ad:	55                   	push   %ebp
  8009ae:	89 e5                	mov    %esp,%ebp
  8009b0:	56                   	push   %esi
  8009b1:	53                   	push   %ebx
  8009b2:	8b 45 08             	mov    0x8(%ebp),%eax
  8009b5:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009b8:	89 c6                	mov    %eax,%esi
  8009ba:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009bd:	eb 1a                	jmp    8009d9 <memcmp+0x2c>
		if (*s1 != *s2)
  8009bf:	0f b6 08             	movzbl (%eax),%ecx
  8009c2:	0f b6 1a             	movzbl (%edx),%ebx
  8009c5:	38 d9                	cmp    %bl,%cl
  8009c7:	74 0a                	je     8009d3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009c9:	0f b6 c1             	movzbl %cl,%eax
  8009cc:	0f b6 db             	movzbl %bl,%ebx
  8009cf:	29 d8                	sub    %ebx,%eax
  8009d1:	eb 0f                	jmp    8009e2 <memcmp+0x35>
		s1++, s2++;
  8009d3:	83 c0 01             	add    $0x1,%eax
  8009d6:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009d9:	39 f0                	cmp    %esi,%eax
  8009db:	75 e2                	jne    8009bf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009e2:	5b                   	pop    %ebx
  8009e3:	5e                   	pop    %esi
  8009e4:	5d                   	pop    %ebp
  8009e5:	c3                   	ret    

008009e6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009e6:	55                   	push   %ebp
  8009e7:	89 e5                	mov    %esp,%ebp
  8009e9:	53                   	push   %ebx
  8009ea:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009ed:	89 c1                	mov    %eax,%ecx
  8009ef:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009f2:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009f6:	eb 0a                	jmp    800a02 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009f8:	0f b6 10             	movzbl (%eax),%edx
  8009fb:	39 da                	cmp    %ebx,%edx
  8009fd:	74 07                	je     800a06 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009ff:	83 c0 01             	add    $0x1,%eax
  800a02:	39 c8                	cmp    %ecx,%eax
  800a04:	72 f2                	jb     8009f8 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a06:	5b                   	pop    %ebx
  800a07:	5d                   	pop    %ebp
  800a08:	c3                   	ret    

00800a09 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a09:	55                   	push   %ebp
  800a0a:	89 e5                	mov    %esp,%ebp
  800a0c:	57                   	push   %edi
  800a0d:	56                   	push   %esi
  800a0e:	53                   	push   %ebx
  800a0f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a12:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a15:	eb 03                	jmp    800a1a <strtol+0x11>
		s++;
  800a17:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a1a:	0f b6 01             	movzbl (%ecx),%eax
  800a1d:	3c 20                	cmp    $0x20,%al
  800a1f:	74 f6                	je     800a17 <strtol+0xe>
  800a21:	3c 09                	cmp    $0x9,%al
  800a23:	74 f2                	je     800a17 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a25:	3c 2b                	cmp    $0x2b,%al
  800a27:	75 0a                	jne    800a33 <strtol+0x2a>
		s++;
  800a29:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a2c:	bf 00 00 00 00       	mov    $0x0,%edi
  800a31:	eb 11                	jmp    800a44 <strtol+0x3b>
  800a33:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a38:	3c 2d                	cmp    $0x2d,%al
  800a3a:	75 08                	jne    800a44 <strtol+0x3b>
		s++, neg = 1;
  800a3c:	83 c1 01             	add    $0x1,%ecx
  800a3f:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a44:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a4a:	75 15                	jne    800a61 <strtol+0x58>
  800a4c:	80 39 30             	cmpb   $0x30,(%ecx)
  800a4f:	75 10                	jne    800a61 <strtol+0x58>
  800a51:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a55:	75 7c                	jne    800ad3 <strtol+0xca>
		s += 2, base = 16;
  800a57:	83 c1 02             	add    $0x2,%ecx
  800a5a:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a5f:	eb 16                	jmp    800a77 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a61:	85 db                	test   %ebx,%ebx
  800a63:	75 12                	jne    800a77 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a65:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a6a:	80 39 30             	cmpb   $0x30,(%ecx)
  800a6d:	75 08                	jne    800a77 <strtol+0x6e>
		s++, base = 8;
  800a6f:	83 c1 01             	add    $0x1,%ecx
  800a72:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a77:	b8 00 00 00 00       	mov    $0x0,%eax
  800a7c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a7f:	0f b6 11             	movzbl (%ecx),%edx
  800a82:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a85:	89 f3                	mov    %esi,%ebx
  800a87:	80 fb 09             	cmp    $0x9,%bl
  800a8a:	77 08                	ja     800a94 <strtol+0x8b>
			dig = *s - '0';
  800a8c:	0f be d2             	movsbl %dl,%edx
  800a8f:	83 ea 30             	sub    $0x30,%edx
  800a92:	eb 22                	jmp    800ab6 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a94:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a97:	89 f3                	mov    %esi,%ebx
  800a99:	80 fb 19             	cmp    $0x19,%bl
  800a9c:	77 08                	ja     800aa6 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a9e:	0f be d2             	movsbl %dl,%edx
  800aa1:	83 ea 57             	sub    $0x57,%edx
  800aa4:	eb 10                	jmp    800ab6 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800aa6:	8d 72 bf             	lea    -0x41(%edx),%esi
  800aa9:	89 f3                	mov    %esi,%ebx
  800aab:	80 fb 19             	cmp    $0x19,%bl
  800aae:	77 16                	ja     800ac6 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800ab0:	0f be d2             	movsbl %dl,%edx
  800ab3:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800ab6:	3b 55 10             	cmp    0x10(%ebp),%edx
  800ab9:	7d 0b                	jge    800ac6 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800abb:	83 c1 01             	add    $0x1,%ecx
  800abe:	0f af 45 10          	imul   0x10(%ebp),%eax
  800ac2:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ac4:	eb b9                	jmp    800a7f <strtol+0x76>

	if (endptr)
  800ac6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800aca:	74 0d                	je     800ad9 <strtol+0xd0>
		*endptr = (char *) s;
  800acc:	8b 75 0c             	mov    0xc(%ebp),%esi
  800acf:	89 0e                	mov    %ecx,(%esi)
  800ad1:	eb 06                	jmp    800ad9 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ad3:	85 db                	test   %ebx,%ebx
  800ad5:	74 98                	je     800a6f <strtol+0x66>
  800ad7:	eb 9e                	jmp    800a77 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800ad9:	89 c2                	mov    %eax,%edx
  800adb:	f7 da                	neg    %edx
  800add:	85 ff                	test   %edi,%edi
  800adf:	0f 45 c2             	cmovne %edx,%eax
}
  800ae2:	5b                   	pop    %ebx
  800ae3:	5e                   	pop    %esi
  800ae4:	5f                   	pop    %edi
  800ae5:	5d                   	pop    %ebp
  800ae6:	c3                   	ret    
  800ae7:	66 90                	xchg   %ax,%ax
  800ae9:	66 90                	xchg   %ax,%ax
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

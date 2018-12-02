
obj/user/softint：     文件格式 elf32-i386


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
  80002c:	e8 09 00 00 00       	call   80003a <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	asm volatile("int $14");	// page fault
  800036:	cd 0e                	int    $0xe
}
  800038:	5d                   	pop    %ebp
  800039:	c3                   	ret    

0080003a <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80003a:	55                   	push   %ebp
  80003b:	89 e5                	mov    %esp,%ebp
  80003d:	56                   	push   %esi
  80003e:	53                   	push   %ebx
  80003f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800042:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	//thisenv = 0;
	envid_t id = sys_getenvid();
  800045:	e8 c9 00 00 00       	call   800113 <sys_getenvid>
	thisenv = &envs[ENVX(id)];
  80004a:	25 ff 03 00 00       	and    $0x3ff,%eax
  80004f:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800052:	c1 e0 05             	shl    $0x5,%eax
  800055:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80005a:	a3 04 10 80 00       	mov    %eax,0x801004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  80005f:	85 db                	test   %ebx,%ebx
  800061:	7e 07                	jle    80006a <libmain+0x30>
		binaryname = argv[0];
  800063:	8b 06                	mov    (%esi),%eax
  800065:	a3 00 10 80 00       	mov    %eax,0x801000

	// call user main routine
	umain(argc, argv);
  80006a:	83 ec 08             	sub    $0x8,%esp
  80006d:	56                   	push   %esi
  80006e:	53                   	push   %ebx
  80006f:	e8 bf ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800074:	e8 0a 00 00 00       	call   800083 <exit>
}
  800079:	83 c4 10             	add    $0x10,%esp
  80007c:	8d 65 f8             	lea    -0x8(%ebp),%esp
  80007f:	5b                   	pop    %ebx
  800080:	5e                   	pop    %esi
  800081:	5d                   	pop    %ebp
  800082:	c3                   	ret    

00800083 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800083:	55                   	push   %ebp
  800084:	89 e5                	mov    %esp,%ebp
  800086:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800089:	6a 00                	push   $0x0
  80008b:	e8 42 00 00 00       	call   8000d2 <sys_env_destroy>
}
  800090:	83 c4 10             	add    $0x10,%esp
  800093:	c9                   	leave  
  800094:	c3                   	ret    

00800095 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800095:	55                   	push   %ebp
  800096:	89 e5                	mov    %esp,%ebp
  800098:	57                   	push   %edi
  800099:	56                   	push   %esi
  80009a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80009b:	b8 00 00 00 00       	mov    $0x0,%eax
  8000a0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000a3:	8b 55 08             	mov    0x8(%ebp),%edx
  8000a6:	89 c3                	mov    %eax,%ebx
  8000a8:	89 c7                	mov    %eax,%edi
  8000aa:	89 c6                	mov    %eax,%esi
  8000ac:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000ae:	5b                   	pop    %ebx
  8000af:	5e                   	pop    %esi
  8000b0:	5f                   	pop    %edi
  8000b1:	5d                   	pop    %ebp
  8000b2:	c3                   	ret    

008000b3 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000b3:	55                   	push   %ebp
  8000b4:	89 e5                	mov    %esp,%ebp
  8000b6:	57                   	push   %edi
  8000b7:	56                   	push   %esi
  8000b8:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000b9:	ba 00 00 00 00       	mov    $0x0,%edx
  8000be:	b8 01 00 00 00       	mov    $0x1,%eax
  8000c3:	89 d1                	mov    %edx,%ecx
  8000c5:	89 d3                	mov    %edx,%ebx
  8000c7:	89 d7                	mov    %edx,%edi
  8000c9:	89 d6                	mov    %edx,%esi
  8000cb:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000cd:	5b                   	pop    %ebx
  8000ce:	5e                   	pop    %esi
  8000cf:	5f                   	pop    %edi
  8000d0:	5d                   	pop    %ebp
  8000d1:	c3                   	ret    

008000d2 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000d2:	55                   	push   %ebp
  8000d3:	89 e5                	mov    %esp,%ebp
  8000d5:	57                   	push   %edi
  8000d6:	56                   	push   %esi
  8000d7:	53                   	push   %ebx
  8000d8:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000db:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000e0:	b8 03 00 00 00       	mov    $0x3,%eax
  8000e5:	8b 55 08             	mov    0x8(%ebp),%edx
  8000e8:	89 cb                	mov    %ecx,%ebx
  8000ea:	89 cf                	mov    %ecx,%edi
  8000ec:	89 ce                	mov    %ecx,%esi
  8000ee:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000f0:	85 c0                	test   %eax,%eax
  8000f2:	7e 17                	jle    80010b <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000f4:	83 ec 0c             	sub    $0xc,%esp
  8000f7:	50                   	push   %eax
  8000f8:	6a 03                	push   $0x3
  8000fa:	68 8a 0d 80 00       	push   $0x800d8a
  8000ff:	6a 23                	push   $0x23
  800101:	68 a7 0d 80 00       	push   $0x800da7
  800106:	e8 27 00 00 00       	call   800132 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  80010b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80010e:	5b                   	pop    %ebx
  80010f:	5e                   	pop    %esi
  800110:	5f                   	pop    %edi
  800111:	5d                   	pop    %ebp
  800112:	c3                   	ret    

00800113 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800113:	55                   	push   %ebp
  800114:	89 e5                	mov    %esp,%ebp
  800116:	57                   	push   %edi
  800117:	56                   	push   %esi
  800118:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800119:	ba 00 00 00 00       	mov    $0x0,%edx
  80011e:	b8 02 00 00 00       	mov    $0x2,%eax
  800123:	89 d1                	mov    %edx,%ecx
  800125:	89 d3                	mov    %edx,%ebx
  800127:	89 d7                	mov    %edx,%edi
  800129:	89 d6                	mov    %edx,%esi
  80012b:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80012d:	5b                   	pop    %ebx
  80012e:	5e                   	pop    %esi
  80012f:	5f                   	pop    %edi
  800130:	5d                   	pop    %ebp
  800131:	c3                   	ret    

00800132 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800132:	55                   	push   %ebp
  800133:	89 e5                	mov    %esp,%ebp
  800135:	56                   	push   %esi
  800136:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800137:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80013a:	8b 35 00 10 80 00    	mov    0x801000,%esi
  800140:	e8 ce ff ff ff       	call   800113 <sys_getenvid>
  800145:	83 ec 0c             	sub    $0xc,%esp
  800148:	ff 75 0c             	pushl  0xc(%ebp)
  80014b:	ff 75 08             	pushl  0x8(%ebp)
  80014e:	56                   	push   %esi
  80014f:	50                   	push   %eax
  800150:	68 b8 0d 80 00       	push   $0x800db8
  800155:	e8 b1 00 00 00       	call   80020b <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80015a:	83 c4 18             	add    $0x18,%esp
  80015d:	53                   	push   %ebx
  80015e:	ff 75 10             	pushl  0x10(%ebp)
  800161:	e8 54 00 00 00       	call   8001ba <vcprintf>
	cprintf("\n");
  800166:	c7 04 24 dc 0d 80 00 	movl   $0x800ddc,(%esp)
  80016d:	e8 99 00 00 00       	call   80020b <cprintf>
  800172:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800175:	cc                   	int3   
  800176:	eb fd                	jmp    800175 <_panic+0x43>

00800178 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800178:	55                   	push   %ebp
  800179:	89 e5                	mov    %esp,%ebp
  80017b:	53                   	push   %ebx
  80017c:	83 ec 04             	sub    $0x4,%esp
  80017f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800182:	8b 13                	mov    (%ebx),%edx
  800184:	8d 42 01             	lea    0x1(%edx),%eax
  800187:	89 03                	mov    %eax,(%ebx)
  800189:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80018c:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800190:	3d ff 00 00 00       	cmp    $0xff,%eax
  800195:	75 1a                	jne    8001b1 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800197:	83 ec 08             	sub    $0x8,%esp
  80019a:	68 ff 00 00 00       	push   $0xff
  80019f:	8d 43 08             	lea    0x8(%ebx),%eax
  8001a2:	50                   	push   %eax
  8001a3:	e8 ed fe ff ff       	call   800095 <sys_cputs>
		b->idx = 0;
  8001a8:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001ae:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001b1:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001b5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001b8:	c9                   	leave  
  8001b9:	c3                   	ret    

008001ba <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001ba:	55                   	push   %ebp
  8001bb:	89 e5                	mov    %esp,%ebp
  8001bd:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001c3:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001ca:	00 00 00 
	b.cnt = 0;
  8001cd:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001d4:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001d7:	ff 75 0c             	pushl  0xc(%ebp)
  8001da:	ff 75 08             	pushl  0x8(%ebp)
  8001dd:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001e3:	50                   	push   %eax
  8001e4:	68 78 01 80 00       	push   $0x800178
  8001e9:	e8 54 01 00 00       	call   800342 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001ee:	83 c4 08             	add    $0x8,%esp
  8001f1:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001f7:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001fd:	50                   	push   %eax
  8001fe:	e8 92 fe ff ff       	call   800095 <sys_cputs>

	return b.cnt;
}
  800203:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800209:	c9                   	leave  
  80020a:	c3                   	ret    

0080020b <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80020b:	55                   	push   %ebp
  80020c:	89 e5                	mov    %esp,%ebp
  80020e:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800211:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800214:	50                   	push   %eax
  800215:	ff 75 08             	pushl  0x8(%ebp)
  800218:	e8 9d ff ff ff       	call   8001ba <vcprintf>
	va_end(ap);

	return cnt;
}
  80021d:	c9                   	leave  
  80021e:	c3                   	ret    

0080021f <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80021f:	55                   	push   %ebp
  800220:	89 e5                	mov    %esp,%ebp
  800222:	57                   	push   %edi
  800223:	56                   	push   %esi
  800224:	53                   	push   %ebx
  800225:	83 ec 1c             	sub    $0x1c,%esp
  800228:	89 c7                	mov    %eax,%edi
  80022a:	89 d6                	mov    %edx,%esi
  80022c:	8b 45 08             	mov    0x8(%ebp),%eax
  80022f:	8b 55 0c             	mov    0xc(%ebp),%edx
  800232:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800235:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800238:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80023b:	bb 00 00 00 00       	mov    $0x0,%ebx
  800240:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800243:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800246:	39 d3                	cmp    %edx,%ebx
  800248:	72 05                	jb     80024f <printnum+0x30>
  80024a:	39 45 10             	cmp    %eax,0x10(%ebp)
  80024d:	77 45                	ja     800294 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80024f:	83 ec 0c             	sub    $0xc,%esp
  800252:	ff 75 18             	pushl  0x18(%ebp)
  800255:	8b 45 14             	mov    0x14(%ebp),%eax
  800258:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80025b:	53                   	push   %ebx
  80025c:	ff 75 10             	pushl  0x10(%ebp)
  80025f:	83 ec 08             	sub    $0x8,%esp
  800262:	ff 75 e4             	pushl  -0x1c(%ebp)
  800265:	ff 75 e0             	pushl  -0x20(%ebp)
  800268:	ff 75 dc             	pushl  -0x24(%ebp)
  80026b:	ff 75 d8             	pushl  -0x28(%ebp)
  80026e:	e8 6d 08 00 00       	call   800ae0 <__udivdi3>
  800273:	83 c4 18             	add    $0x18,%esp
  800276:	52                   	push   %edx
  800277:	50                   	push   %eax
  800278:	89 f2                	mov    %esi,%edx
  80027a:	89 f8                	mov    %edi,%eax
  80027c:	e8 9e ff ff ff       	call   80021f <printnum>
  800281:	83 c4 20             	add    $0x20,%esp
  800284:	eb 18                	jmp    80029e <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800286:	83 ec 08             	sub    $0x8,%esp
  800289:	56                   	push   %esi
  80028a:	ff 75 18             	pushl  0x18(%ebp)
  80028d:	ff d7                	call   *%edi
  80028f:	83 c4 10             	add    $0x10,%esp
  800292:	eb 03                	jmp    800297 <printnum+0x78>
  800294:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800297:	83 eb 01             	sub    $0x1,%ebx
  80029a:	85 db                	test   %ebx,%ebx
  80029c:	7f e8                	jg     800286 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80029e:	83 ec 08             	sub    $0x8,%esp
  8002a1:	56                   	push   %esi
  8002a2:	83 ec 04             	sub    $0x4,%esp
  8002a5:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002a8:	ff 75 e0             	pushl  -0x20(%ebp)
  8002ab:	ff 75 dc             	pushl  -0x24(%ebp)
  8002ae:	ff 75 d8             	pushl  -0x28(%ebp)
  8002b1:	e8 5a 09 00 00       	call   800c10 <__umoddi3>
  8002b6:	83 c4 14             	add    $0x14,%esp
  8002b9:	0f be 80 de 0d 80 00 	movsbl 0x800dde(%eax),%eax
  8002c0:	50                   	push   %eax
  8002c1:	ff d7                	call   *%edi
}
  8002c3:	83 c4 10             	add    $0x10,%esp
  8002c6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002c9:	5b                   	pop    %ebx
  8002ca:	5e                   	pop    %esi
  8002cb:	5f                   	pop    %edi
  8002cc:	5d                   	pop    %ebp
  8002cd:	c3                   	ret    

008002ce <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002ce:	55                   	push   %ebp
  8002cf:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002d1:	83 fa 01             	cmp    $0x1,%edx
  8002d4:	7e 0e                	jle    8002e4 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002d6:	8b 10                	mov    (%eax),%edx
  8002d8:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002db:	89 08                	mov    %ecx,(%eax)
  8002dd:	8b 02                	mov    (%edx),%eax
  8002df:	8b 52 04             	mov    0x4(%edx),%edx
  8002e2:	eb 22                	jmp    800306 <getuint+0x38>
	else if (lflag)
  8002e4:	85 d2                	test   %edx,%edx
  8002e6:	74 10                	je     8002f8 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002e8:	8b 10                	mov    (%eax),%edx
  8002ea:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002ed:	89 08                	mov    %ecx,(%eax)
  8002ef:	8b 02                	mov    (%edx),%eax
  8002f1:	ba 00 00 00 00       	mov    $0x0,%edx
  8002f6:	eb 0e                	jmp    800306 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8002f8:	8b 10                	mov    (%eax),%edx
  8002fa:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002fd:	89 08                	mov    %ecx,(%eax)
  8002ff:	8b 02                	mov    (%edx),%eax
  800301:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800306:	5d                   	pop    %ebp
  800307:	c3                   	ret    

00800308 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800308:	55                   	push   %ebp
  800309:	89 e5                	mov    %esp,%ebp
  80030b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80030e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800312:	8b 10                	mov    (%eax),%edx
  800314:	3b 50 04             	cmp    0x4(%eax),%edx
  800317:	73 0a                	jae    800323 <sprintputch+0x1b>
		*b->buf++ = ch;
  800319:	8d 4a 01             	lea    0x1(%edx),%ecx
  80031c:	89 08                	mov    %ecx,(%eax)
  80031e:	8b 45 08             	mov    0x8(%ebp),%eax
  800321:	88 02                	mov    %al,(%edx)
}
  800323:	5d                   	pop    %ebp
  800324:	c3                   	ret    

00800325 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800325:	55                   	push   %ebp
  800326:	89 e5                	mov    %esp,%ebp
  800328:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80032b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80032e:	50                   	push   %eax
  80032f:	ff 75 10             	pushl  0x10(%ebp)
  800332:	ff 75 0c             	pushl  0xc(%ebp)
  800335:	ff 75 08             	pushl  0x8(%ebp)
  800338:	e8 05 00 00 00       	call   800342 <vprintfmt>
	va_end(ap);
}
  80033d:	83 c4 10             	add    $0x10,%esp
  800340:	c9                   	leave  
  800341:	c3                   	ret    

00800342 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800342:	55                   	push   %ebp
  800343:	89 e5                	mov    %esp,%ebp
  800345:	57                   	push   %edi
  800346:	56                   	push   %esi
  800347:	53                   	push   %ebx
  800348:	83 ec 2c             	sub    $0x2c,%esp
  80034b:	8b 75 08             	mov    0x8(%ebp),%esi
  80034e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800351:	8b 7d 10             	mov    0x10(%ebp),%edi
  800354:	eb 12                	jmp    800368 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800356:	85 c0                	test   %eax,%eax
  800358:	0f 84 89 03 00 00    	je     8006e7 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  80035e:	83 ec 08             	sub    $0x8,%esp
  800361:	53                   	push   %ebx
  800362:	50                   	push   %eax
  800363:	ff d6                	call   *%esi
  800365:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800368:	83 c7 01             	add    $0x1,%edi
  80036b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80036f:	83 f8 25             	cmp    $0x25,%eax
  800372:	75 e2                	jne    800356 <vprintfmt+0x14>
  800374:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800378:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80037f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800386:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80038d:	ba 00 00 00 00       	mov    $0x0,%edx
  800392:	eb 07                	jmp    80039b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800394:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800397:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80039b:	8d 47 01             	lea    0x1(%edi),%eax
  80039e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003a1:	0f b6 07             	movzbl (%edi),%eax
  8003a4:	0f b6 c8             	movzbl %al,%ecx
  8003a7:	83 e8 23             	sub    $0x23,%eax
  8003aa:	3c 55                	cmp    $0x55,%al
  8003ac:	0f 87 1a 03 00 00    	ja     8006cc <vprintfmt+0x38a>
  8003b2:	0f b6 c0             	movzbl %al,%eax
  8003b5:	ff 24 85 80 0e 80 00 	jmp    *0x800e80(,%eax,4)
  8003bc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003bf:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003c3:	eb d6                	jmp    80039b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003c8:	b8 00 00 00 00       	mov    $0x0,%eax
  8003cd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003d0:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003d3:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  8003d7:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  8003da:	8d 51 d0             	lea    -0x30(%ecx),%edx
  8003dd:	83 fa 09             	cmp    $0x9,%edx
  8003e0:	77 39                	ja     80041b <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003e2:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003e5:	eb e9                	jmp    8003d0 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003e7:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ea:	8d 48 04             	lea    0x4(%eax),%ecx
  8003ed:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003f0:	8b 00                	mov    (%eax),%eax
  8003f2:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003f8:	eb 27                	jmp    800421 <vprintfmt+0xdf>
  8003fa:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003fd:	85 c0                	test   %eax,%eax
  8003ff:	b9 00 00 00 00       	mov    $0x0,%ecx
  800404:	0f 49 c8             	cmovns %eax,%ecx
  800407:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80040a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80040d:	eb 8c                	jmp    80039b <vprintfmt+0x59>
  80040f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800412:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800419:	eb 80                	jmp    80039b <vprintfmt+0x59>
  80041b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80041e:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800421:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800425:	0f 89 70 ff ff ff    	jns    80039b <vprintfmt+0x59>
				width = precision, precision = -1;
  80042b:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80042e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800431:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800438:	e9 5e ff ff ff       	jmp    80039b <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80043d:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800440:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800443:	e9 53 ff ff ff       	jmp    80039b <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800448:	8b 45 14             	mov    0x14(%ebp),%eax
  80044b:	8d 50 04             	lea    0x4(%eax),%edx
  80044e:	89 55 14             	mov    %edx,0x14(%ebp)
  800451:	83 ec 08             	sub    $0x8,%esp
  800454:	53                   	push   %ebx
  800455:	ff 30                	pushl  (%eax)
  800457:	ff d6                	call   *%esi
			break;
  800459:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80045c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80045f:	e9 04 ff ff ff       	jmp    800368 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800464:	8b 45 14             	mov    0x14(%ebp),%eax
  800467:	8d 50 04             	lea    0x4(%eax),%edx
  80046a:	89 55 14             	mov    %edx,0x14(%ebp)
  80046d:	8b 00                	mov    (%eax),%eax
  80046f:	99                   	cltd   
  800470:	31 d0                	xor    %edx,%eax
  800472:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800474:	83 f8 07             	cmp    $0x7,%eax
  800477:	7f 0b                	jg     800484 <vprintfmt+0x142>
  800479:	8b 14 85 e0 0f 80 00 	mov    0x800fe0(,%eax,4),%edx
  800480:	85 d2                	test   %edx,%edx
  800482:	75 18                	jne    80049c <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800484:	50                   	push   %eax
  800485:	68 f6 0d 80 00       	push   $0x800df6
  80048a:	53                   	push   %ebx
  80048b:	56                   	push   %esi
  80048c:	e8 94 fe ff ff       	call   800325 <printfmt>
  800491:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800494:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800497:	e9 cc fe ff ff       	jmp    800368 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80049c:	52                   	push   %edx
  80049d:	68 ff 0d 80 00       	push   $0x800dff
  8004a2:	53                   	push   %ebx
  8004a3:	56                   	push   %esi
  8004a4:	e8 7c fe ff ff       	call   800325 <printfmt>
  8004a9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004af:	e9 b4 fe ff ff       	jmp    800368 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004b4:	8b 45 14             	mov    0x14(%ebp),%eax
  8004b7:	8d 50 04             	lea    0x4(%eax),%edx
  8004ba:	89 55 14             	mov    %edx,0x14(%ebp)
  8004bd:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004bf:	85 ff                	test   %edi,%edi
  8004c1:	b8 ef 0d 80 00       	mov    $0x800def,%eax
  8004c6:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004c9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004cd:	0f 8e 94 00 00 00    	jle    800567 <vprintfmt+0x225>
  8004d3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004d7:	0f 84 98 00 00 00    	je     800575 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004dd:	83 ec 08             	sub    $0x8,%esp
  8004e0:	ff 75 d0             	pushl  -0x30(%ebp)
  8004e3:	57                   	push   %edi
  8004e4:	e8 86 02 00 00       	call   80076f <strnlen>
  8004e9:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004ec:	29 c1                	sub    %eax,%ecx
  8004ee:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  8004f1:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004f4:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004f8:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004fb:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004fe:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800500:	eb 0f                	jmp    800511 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800502:	83 ec 08             	sub    $0x8,%esp
  800505:	53                   	push   %ebx
  800506:	ff 75 e0             	pushl  -0x20(%ebp)
  800509:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80050b:	83 ef 01             	sub    $0x1,%edi
  80050e:	83 c4 10             	add    $0x10,%esp
  800511:	85 ff                	test   %edi,%edi
  800513:	7f ed                	jg     800502 <vprintfmt+0x1c0>
  800515:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800518:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80051b:	85 c9                	test   %ecx,%ecx
  80051d:	b8 00 00 00 00       	mov    $0x0,%eax
  800522:	0f 49 c1             	cmovns %ecx,%eax
  800525:	29 c1                	sub    %eax,%ecx
  800527:	89 75 08             	mov    %esi,0x8(%ebp)
  80052a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80052d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800530:	89 cb                	mov    %ecx,%ebx
  800532:	eb 4d                	jmp    800581 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800534:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800538:	74 1b                	je     800555 <vprintfmt+0x213>
  80053a:	0f be c0             	movsbl %al,%eax
  80053d:	83 e8 20             	sub    $0x20,%eax
  800540:	83 f8 5e             	cmp    $0x5e,%eax
  800543:	76 10                	jbe    800555 <vprintfmt+0x213>
					putch('?', putdat);
  800545:	83 ec 08             	sub    $0x8,%esp
  800548:	ff 75 0c             	pushl  0xc(%ebp)
  80054b:	6a 3f                	push   $0x3f
  80054d:	ff 55 08             	call   *0x8(%ebp)
  800550:	83 c4 10             	add    $0x10,%esp
  800553:	eb 0d                	jmp    800562 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800555:	83 ec 08             	sub    $0x8,%esp
  800558:	ff 75 0c             	pushl  0xc(%ebp)
  80055b:	52                   	push   %edx
  80055c:	ff 55 08             	call   *0x8(%ebp)
  80055f:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800562:	83 eb 01             	sub    $0x1,%ebx
  800565:	eb 1a                	jmp    800581 <vprintfmt+0x23f>
  800567:	89 75 08             	mov    %esi,0x8(%ebp)
  80056a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80056d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800570:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800573:	eb 0c                	jmp    800581 <vprintfmt+0x23f>
  800575:	89 75 08             	mov    %esi,0x8(%ebp)
  800578:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80057b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80057e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800581:	83 c7 01             	add    $0x1,%edi
  800584:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800588:	0f be d0             	movsbl %al,%edx
  80058b:	85 d2                	test   %edx,%edx
  80058d:	74 23                	je     8005b2 <vprintfmt+0x270>
  80058f:	85 f6                	test   %esi,%esi
  800591:	78 a1                	js     800534 <vprintfmt+0x1f2>
  800593:	83 ee 01             	sub    $0x1,%esi
  800596:	79 9c                	jns    800534 <vprintfmt+0x1f2>
  800598:	89 df                	mov    %ebx,%edi
  80059a:	8b 75 08             	mov    0x8(%ebp),%esi
  80059d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005a0:	eb 18                	jmp    8005ba <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005a2:	83 ec 08             	sub    $0x8,%esp
  8005a5:	53                   	push   %ebx
  8005a6:	6a 20                	push   $0x20
  8005a8:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005aa:	83 ef 01             	sub    $0x1,%edi
  8005ad:	83 c4 10             	add    $0x10,%esp
  8005b0:	eb 08                	jmp    8005ba <vprintfmt+0x278>
  8005b2:	89 df                	mov    %ebx,%edi
  8005b4:	8b 75 08             	mov    0x8(%ebp),%esi
  8005b7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005ba:	85 ff                	test   %edi,%edi
  8005bc:	7f e4                	jg     8005a2 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005be:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005c1:	e9 a2 fd ff ff       	jmp    800368 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005c6:	83 fa 01             	cmp    $0x1,%edx
  8005c9:	7e 16                	jle    8005e1 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  8005cb:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ce:	8d 50 08             	lea    0x8(%eax),%edx
  8005d1:	89 55 14             	mov    %edx,0x14(%ebp)
  8005d4:	8b 50 04             	mov    0x4(%eax),%edx
  8005d7:	8b 00                	mov    (%eax),%eax
  8005d9:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005dc:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005df:	eb 32                	jmp    800613 <vprintfmt+0x2d1>
	else if (lflag)
  8005e1:	85 d2                	test   %edx,%edx
  8005e3:	74 18                	je     8005fd <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  8005e5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e8:	8d 50 04             	lea    0x4(%eax),%edx
  8005eb:	89 55 14             	mov    %edx,0x14(%ebp)
  8005ee:	8b 00                	mov    (%eax),%eax
  8005f0:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005f3:	89 c1                	mov    %eax,%ecx
  8005f5:	c1 f9 1f             	sar    $0x1f,%ecx
  8005f8:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005fb:	eb 16                	jmp    800613 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  8005fd:	8b 45 14             	mov    0x14(%ebp),%eax
  800600:	8d 50 04             	lea    0x4(%eax),%edx
  800603:	89 55 14             	mov    %edx,0x14(%ebp)
  800606:	8b 00                	mov    (%eax),%eax
  800608:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80060b:	89 c1                	mov    %eax,%ecx
  80060d:	c1 f9 1f             	sar    $0x1f,%ecx
  800610:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800613:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800616:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800619:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80061e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800622:	79 74                	jns    800698 <vprintfmt+0x356>
				putch('-', putdat);
  800624:	83 ec 08             	sub    $0x8,%esp
  800627:	53                   	push   %ebx
  800628:	6a 2d                	push   $0x2d
  80062a:	ff d6                	call   *%esi
				num = -(long long) num;
  80062c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80062f:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800632:	f7 d8                	neg    %eax
  800634:	83 d2 00             	adc    $0x0,%edx
  800637:	f7 da                	neg    %edx
  800639:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80063c:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800641:	eb 55                	jmp    800698 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800643:	8d 45 14             	lea    0x14(%ebp),%eax
  800646:	e8 83 fc ff ff       	call   8002ce <getuint>
			base = 10;
  80064b:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800650:	eb 46                	jmp    800698 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800652:	8d 45 14             	lea    0x14(%ebp),%eax
  800655:	e8 74 fc ff ff       	call   8002ce <getuint>
			base = 8;
  80065a:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80065f:	eb 37                	jmp    800698 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  800661:	83 ec 08             	sub    $0x8,%esp
  800664:	53                   	push   %ebx
  800665:	6a 30                	push   $0x30
  800667:	ff d6                	call   *%esi
			putch('x', putdat);
  800669:	83 c4 08             	add    $0x8,%esp
  80066c:	53                   	push   %ebx
  80066d:	6a 78                	push   $0x78
  80066f:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800671:	8b 45 14             	mov    0x14(%ebp),%eax
  800674:	8d 50 04             	lea    0x4(%eax),%edx
  800677:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80067a:	8b 00                	mov    (%eax),%eax
  80067c:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800681:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800684:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800689:	eb 0d                	jmp    800698 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  80068b:	8d 45 14             	lea    0x14(%ebp),%eax
  80068e:	e8 3b fc ff ff       	call   8002ce <getuint>
			base = 16;
  800693:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800698:	83 ec 0c             	sub    $0xc,%esp
  80069b:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80069f:	57                   	push   %edi
  8006a0:	ff 75 e0             	pushl  -0x20(%ebp)
  8006a3:	51                   	push   %ecx
  8006a4:	52                   	push   %edx
  8006a5:	50                   	push   %eax
  8006a6:	89 da                	mov    %ebx,%edx
  8006a8:	89 f0                	mov    %esi,%eax
  8006aa:	e8 70 fb ff ff       	call   80021f <printnum>
			break;
  8006af:	83 c4 20             	add    $0x20,%esp
  8006b2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006b5:	e9 ae fc ff ff       	jmp    800368 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006ba:	83 ec 08             	sub    $0x8,%esp
  8006bd:	53                   	push   %ebx
  8006be:	51                   	push   %ecx
  8006bf:	ff d6                	call   *%esi
			break;
  8006c1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006c4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006c7:	e9 9c fc ff ff       	jmp    800368 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006cc:	83 ec 08             	sub    $0x8,%esp
  8006cf:	53                   	push   %ebx
  8006d0:	6a 25                	push   $0x25
  8006d2:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006d4:	83 c4 10             	add    $0x10,%esp
  8006d7:	eb 03                	jmp    8006dc <vprintfmt+0x39a>
  8006d9:	83 ef 01             	sub    $0x1,%edi
  8006dc:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006e0:	75 f7                	jne    8006d9 <vprintfmt+0x397>
  8006e2:	e9 81 fc ff ff       	jmp    800368 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006e7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006ea:	5b                   	pop    %ebx
  8006eb:	5e                   	pop    %esi
  8006ec:	5f                   	pop    %edi
  8006ed:	5d                   	pop    %ebp
  8006ee:	c3                   	ret    

008006ef <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006ef:	55                   	push   %ebp
  8006f0:	89 e5                	mov    %esp,%ebp
  8006f2:	83 ec 18             	sub    $0x18,%esp
  8006f5:	8b 45 08             	mov    0x8(%ebp),%eax
  8006f8:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006fb:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006fe:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800702:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800705:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80070c:	85 c0                	test   %eax,%eax
  80070e:	74 26                	je     800736 <vsnprintf+0x47>
  800710:	85 d2                	test   %edx,%edx
  800712:	7e 22                	jle    800736 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800714:	ff 75 14             	pushl  0x14(%ebp)
  800717:	ff 75 10             	pushl  0x10(%ebp)
  80071a:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80071d:	50                   	push   %eax
  80071e:	68 08 03 80 00       	push   $0x800308
  800723:	e8 1a fc ff ff       	call   800342 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800728:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80072b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80072e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800731:	83 c4 10             	add    $0x10,%esp
  800734:	eb 05                	jmp    80073b <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800736:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80073b:	c9                   	leave  
  80073c:	c3                   	ret    

0080073d <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80073d:	55                   	push   %ebp
  80073e:	89 e5                	mov    %esp,%ebp
  800740:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800743:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800746:	50                   	push   %eax
  800747:	ff 75 10             	pushl  0x10(%ebp)
  80074a:	ff 75 0c             	pushl  0xc(%ebp)
  80074d:	ff 75 08             	pushl  0x8(%ebp)
  800750:	e8 9a ff ff ff       	call   8006ef <vsnprintf>
	va_end(ap);

	return rc;
}
  800755:	c9                   	leave  
  800756:	c3                   	ret    

00800757 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800757:	55                   	push   %ebp
  800758:	89 e5                	mov    %esp,%ebp
  80075a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80075d:	b8 00 00 00 00       	mov    $0x0,%eax
  800762:	eb 03                	jmp    800767 <strlen+0x10>
		n++;
  800764:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800767:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80076b:	75 f7                	jne    800764 <strlen+0xd>
		n++;
	return n;
}
  80076d:	5d                   	pop    %ebp
  80076e:	c3                   	ret    

0080076f <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80076f:	55                   	push   %ebp
  800770:	89 e5                	mov    %esp,%ebp
  800772:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800775:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800778:	ba 00 00 00 00       	mov    $0x0,%edx
  80077d:	eb 03                	jmp    800782 <strnlen+0x13>
		n++;
  80077f:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800782:	39 c2                	cmp    %eax,%edx
  800784:	74 08                	je     80078e <strnlen+0x1f>
  800786:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80078a:	75 f3                	jne    80077f <strnlen+0x10>
  80078c:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80078e:	5d                   	pop    %ebp
  80078f:	c3                   	ret    

00800790 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800790:	55                   	push   %ebp
  800791:	89 e5                	mov    %esp,%ebp
  800793:	53                   	push   %ebx
  800794:	8b 45 08             	mov    0x8(%ebp),%eax
  800797:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80079a:	89 c2                	mov    %eax,%edx
  80079c:	83 c2 01             	add    $0x1,%edx
  80079f:	83 c1 01             	add    $0x1,%ecx
  8007a2:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007a6:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007a9:	84 db                	test   %bl,%bl
  8007ab:	75 ef                	jne    80079c <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007ad:	5b                   	pop    %ebx
  8007ae:	5d                   	pop    %ebp
  8007af:	c3                   	ret    

008007b0 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007b0:	55                   	push   %ebp
  8007b1:	89 e5                	mov    %esp,%ebp
  8007b3:	53                   	push   %ebx
  8007b4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007b7:	53                   	push   %ebx
  8007b8:	e8 9a ff ff ff       	call   800757 <strlen>
  8007bd:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007c0:	ff 75 0c             	pushl  0xc(%ebp)
  8007c3:	01 d8                	add    %ebx,%eax
  8007c5:	50                   	push   %eax
  8007c6:	e8 c5 ff ff ff       	call   800790 <strcpy>
	return dst;
}
  8007cb:	89 d8                	mov    %ebx,%eax
  8007cd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007d0:	c9                   	leave  
  8007d1:	c3                   	ret    

008007d2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007d2:	55                   	push   %ebp
  8007d3:	89 e5                	mov    %esp,%ebp
  8007d5:	56                   	push   %esi
  8007d6:	53                   	push   %ebx
  8007d7:	8b 75 08             	mov    0x8(%ebp),%esi
  8007da:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007dd:	89 f3                	mov    %esi,%ebx
  8007df:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007e2:	89 f2                	mov    %esi,%edx
  8007e4:	eb 0f                	jmp    8007f5 <strncpy+0x23>
		*dst++ = *src;
  8007e6:	83 c2 01             	add    $0x1,%edx
  8007e9:	0f b6 01             	movzbl (%ecx),%eax
  8007ec:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007ef:	80 39 01             	cmpb   $0x1,(%ecx)
  8007f2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007f5:	39 da                	cmp    %ebx,%edx
  8007f7:	75 ed                	jne    8007e6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007f9:	89 f0                	mov    %esi,%eax
  8007fb:	5b                   	pop    %ebx
  8007fc:	5e                   	pop    %esi
  8007fd:	5d                   	pop    %ebp
  8007fe:	c3                   	ret    

008007ff <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007ff:	55                   	push   %ebp
  800800:	89 e5                	mov    %esp,%ebp
  800802:	56                   	push   %esi
  800803:	53                   	push   %ebx
  800804:	8b 75 08             	mov    0x8(%ebp),%esi
  800807:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80080a:	8b 55 10             	mov    0x10(%ebp),%edx
  80080d:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80080f:	85 d2                	test   %edx,%edx
  800811:	74 21                	je     800834 <strlcpy+0x35>
  800813:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800817:	89 f2                	mov    %esi,%edx
  800819:	eb 09                	jmp    800824 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80081b:	83 c2 01             	add    $0x1,%edx
  80081e:	83 c1 01             	add    $0x1,%ecx
  800821:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800824:	39 c2                	cmp    %eax,%edx
  800826:	74 09                	je     800831 <strlcpy+0x32>
  800828:	0f b6 19             	movzbl (%ecx),%ebx
  80082b:	84 db                	test   %bl,%bl
  80082d:	75 ec                	jne    80081b <strlcpy+0x1c>
  80082f:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800831:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800834:	29 f0                	sub    %esi,%eax
}
  800836:	5b                   	pop    %ebx
  800837:	5e                   	pop    %esi
  800838:	5d                   	pop    %ebp
  800839:	c3                   	ret    

0080083a <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80083a:	55                   	push   %ebp
  80083b:	89 e5                	mov    %esp,%ebp
  80083d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800840:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800843:	eb 06                	jmp    80084b <strcmp+0x11>
		p++, q++;
  800845:	83 c1 01             	add    $0x1,%ecx
  800848:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80084b:	0f b6 01             	movzbl (%ecx),%eax
  80084e:	84 c0                	test   %al,%al
  800850:	74 04                	je     800856 <strcmp+0x1c>
  800852:	3a 02                	cmp    (%edx),%al
  800854:	74 ef                	je     800845 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800856:	0f b6 c0             	movzbl %al,%eax
  800859:	0f b6 12             	movzbl (%edx),%edx
  80085c:	29 d0                	sub    %edx,%eax
}
  80085e:	5d                   	pop    %ebp
  80085f:	c3                   	ret    

00800860 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800860:	55                   	push   %ebp
  800861:	89 e5                	mov    %esp,%ebp
  800863:	53                   	push   %ebx
  800864:	8b 45 08             	mov    0x8(%ebp),%eax
  800867:	8b 55 0c             	mov    0xc(%ebp),%edx
  80086a:	89 c3                	mov    %eax,%ebx
  80086c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80086f:	eb 06                	jmp    800877 <strncmp+0x17>
		n--, p++, q++;
  800871:	83 c0 01             	add    $0x1,%eax
  800874:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800877:	39 d8                	cmp    %ebx,%eax
  800879:	74 15                	je     800890 <strncmp+0x30>
  80087b:	0f b6 08             	movzbl (%eax),%ecx
  80087e:	84 c9                	test   %cl,%cl
  800880:	74 04                	je     800886 <strncmp+0x26>
  800882:	3a 0a                	cmp    (%edx),%cl
  800884:	74 eb                	je     800871 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800886:	0f b6 00             	movzbl (%eax),%eax
  800889:	0f b6 12             	movzbl (%edx),%edx
  80088c:	29 d0                	sub    %edx,%eax
  80088e:	eb 05                	jmp    800895 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800890:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800895:	5b                   	pop    %ebx
  800896:	5d                   	pop    %ebp
  800897:	c3                   	ret    

00800898 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800898:	55                   	push   %ebp
  800899:	89 e5                	mov    %esp,%ebp
  80089b:	8b 45 08             	mov    0x8(%ebp),%eax
  80089e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008a2:	eb 07                	jmp    8008ab <strchr+0x13>
		if (*s == c)
  8008a4:	38 ca                	cmp    %cl,%dl
  8008a6:	74 0f                	je     8008b7 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008a8:	83 c0 01             	add    $0x1,%eax
  8008ab:	0f b6 10             	movzbl (%eax),%edx
  8008ae:	84 d2                	test   %dl,%dl
  8008b0:	75 f2                	jne    8008a4 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008b2:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008b7:	5d                   	pop    %ebp
  8008b8:	c3                   	ret    

008008b9 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008b9:	55                   	push   %ebp
  8008ba:	89 e5                	mov    %esp,%ebp
  8008bc:	8b 45 08             	mov    0x8(%ebp),%eax
  8008bf:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008c3:	eb 03                	jmp    8008c8 <strfind+0xf>
  8008c5:	83 c0 01             	add    $0x1,%eax
  8008c8:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008cb:	38 ca                	cmp    %cl,%dl
  8008cd:	74 04                	je     8008d3 <strfind+0x1a>
  8008cf:	84 d2                	test   %dl,%dl
  8008d1:	75 f2                	jne    8008c5 <strfind+0xc>
			break;
	return (char *) s;
}
  8008d3:	5d                   	pop    %ebp
  8008d4:	c3                   	ret    

008008d5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008d5:	55                   	push   %ebp
  8008d6:	89 e5                	mov    %esp,%ebp
  8008d8:	57                   	push   %edi
  8008d9:	56                   	push   %esi
  8008da:	53                   	push   %ebx
  8008db:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008de:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008e1:	85 c9                	test   %ecx,%ecx
  8008e3:	74 36                	je     80091b <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008e5:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008eb:	75 28                	jne    800915 <memset+0x40>
  8008ed:	f6 c1 03             	test   $0x3,%cl
  8008f0:	75 23                	jne    800915 <memset+0x40>
		c &= 0xFF;
  8008f2:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008f6:	89 d3                	mov    %edx,%ebx
  8008f8:	c1 e3 08             	shl    $0x8,%ebx
  8008fb:	89 d6                	mov    %edx,%esi
  8008fd:	c1 e6 18             	shl    $0x18,%esi
  800900:	89 d0                	mov    %edx,%eax
  800902:	c1 e0 10             	shl    $0x10,%eax
  800905:	09 f0                	or     %esi,%eax
  800907:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800909:	89 d8                	mov    %ebx,%eax
  80090b:	09 d0                	or     %edx,%eax
  80090d:	c1 e9 02             	shr    $0x2,%ecx
  800910:	fc                   	cld    
  800911:	f3 ab                	rep stos %eax,%es:(%edi)
  800913:	eb 06                	jmp    80091b <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800915:	8b 45 0c             	mov    0xc(%ebp),%eax
  800918:	fc                   	cld    
  800919:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80091b:	89 f8                	mov    %edi,%eax
  80091d:	5b                   	pop    %ebx
  80091e:	5e                   	pop    %esi
  80091f:	5f                   	pop    %edi
  800920:	5d                   	pop    %ebp
  800921:	c3                   	ret    

00800922 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800922:	55                   	push   %ebp
  800923:	89 e5                	mov    %esp,%ebp
  800925:	57                   	push   %edi
  800926:	56                   	push   %esi
  800927:	8b 45 08             	mov    0x8(%ebp),%eax
  80092a:	8b 75 0c             	mov    0xc(%ebp),%esi
  80092d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800930:	39 c6                	cmp    %eax,%esi
  800932:	73 35                	jae    800969 <memmove+0x47>
  800934:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800937:	39 d0                	cmp    %edx,%eax
  800939:	73 2e                	jae    800969 <memmove+0x47>
		s += n;
		d += n;
  80093b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80093e:	89 d6                	mov    %edx,%esi
  800940:	09 fe                	or     %edi,%esi
  800942:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800948:	75 13                	jne    80095d <memmove+0x3b>
  80094a:	f6 c1 03             	test   $0x3,%cl
  80094d:	75 0e                	jne    80095d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80094f:	83 ef 04             	sub    $0x4,%edi
  800952:	8d 72 fc             	lea    -0x4(%edx),%esi
  800955:	c1 e9 02             	shr    $0x2,%ecx
  800958:	fd                   	std    
  800959:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80095b:	eb 09                	jmp    800966 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80095d:	83 ef 01             	sub    $0x1,%edi
  800960:	8d 72 ff             	lea    -0x1(%edx),%esi
  800963:	fd                   	std    
  800964:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800966:	fc                   	cld    
  800967:	eb 1d                	jmp    800986 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800969:	89 f2                	mov    %esi,%edx
  80096b:	09 c2                	or     %eax,%edx
  80096d:	f6 c2 03             	test   $0x3,%dl
  800970:	75 0f                	jne    800981 <memmove+0x5f>
  800972:	f6 c1 03             	test   $0x3,%cl
  800975:	75 0a                	jne    800981 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800977:	c1 e9 02             	shr    $0x2,%ecx
  80097a:	89 c7                	mov    %eax,%edi
  80097c:	fc                   	cld    
  80097d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80097f:	eb 05                	jmp    800986 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800981:	89 c7                	mov    %eax,%edi
  800983:	fc                   	cld    
  800984:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800986:	5e                   	pop    %esi
  800987:	5f                   	pop    %edi
  800988:	5d                   	pop    %ebp
  800989:	c3                   	ret    

0080098a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80098a:	55                   	push   %ebp
  80098b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  80098d:	ff 75 10             	pushl  0x10(%ebp)
  800990:	ff 75 0c             	pushl  0xc(%ebp)
  800993:	ff 75 08             	pushl  0x8(%ebp)
  800996:	e8 87 ff ff ff       	call   800922 <memmove>
}
  80099b:	c9                   	leave  
  80099c:	c3                   	ret    

0080099d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80099d:	55                   	push   %ebp
  80099e:	89 e5                	mov    %esp,%ebp
  8009a0:	56                   	push   %esi
  8009a1:	53                   	push   %ebx
  8009a2:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a5:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009a8:	89 c6                	mov    %eax,%esi
  8009aa:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009ad:	eb 1a                	jmp    8009c9 <memcmp+0x2c>
		if (*s1 != *s2)
  8009af:	0f b6 08             	movzbl (%eax),%ecx
  8009b2:	0f b6 1a             	movzbl (%edx),%ebx
  8009b5:	38 d9                	cmp    %bl,%cl
  8009b7:	74 0a                	je     8009c3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009b9:	0f b6 c1             	movzbl %cl,%eax
  8009bc:	0f b6 db             	movzbl %bl,%ebx
  8009bf:	29 d8                	sub    %ebx,%eax
  8009c1:	eb 0f                	jmp    8009d2 <memcmp+0x35>
		s1++, s2++;
  8009c3:	83 c0 01             	add    $0x1,%eax
  8009c6:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009c9:	39 f0                	cmp    %esi,%eax
  8009cb:	75 e2                	jne    8009af <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009cd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009d2:	5b                   	pop    %ebx
  8009d3:	5e                   	pop    %esi
  8009d4:	5d                   	pop    %ebp
  8009d5:	c3                   	ret    

008009d6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009d6:	55                   	push   %ebp
  8009d7:	89 e5                	mov    %esp,%ebp
  8009d9:	53                   	push   %ebx
  8009da:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009dd:	89 c1                	mov    %eax,%ecx
  8009df:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009e2:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009e6:	eb 0a                	jmp    8009f2 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009e8:	0f b6 10             	movzbl (%eax),%edx
  8009eb:	39 da                	cmp    %ebx,%edx
  8009ed:	74 07                	je     8009f6 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009ef:	83 c0 01             	add    $0x1,%eax
  8009f2:	39 c8                	cmp    %ecx,%eax
  8009f4:	72 f2                	jb     8009e8 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009f6:	5b                   	pop    %ebx
  8009f7:	5d                   	pop    %ebp
  8009f8:	c3                   	ret    

008009f9 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009f9:	55                   	push   %ebp
  8009fa:	89 e5                	mov    %esp,%ebp
  8009fc:	57                   	push   %edi
  8009fd:	56                   	push   %esi
  8009fe:	53                   	push   %ebx
  8009ff:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a02:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a05:	eb 03                	jmp    800a0a <strtol+0x11>
		s++;
  800a07:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a0a:	0f b6 01             	movzbl (%ecx),%eax
  800a0d:	3c 20                	cmp    $0x20,%al
  800a0f:	74 f6                	je     800a07 <strtol+0xe>
  800a11:	3c 09                	cmp    $0x9,%al
  800a13:	74 f2                	je     800a07 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a15:	3c 2b                	cmp    $0x2b,%al
  800a17:	75 0a                	jne    800a23 <strtol+0x2a>
		s++;
  800a19:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a1c:	bf 00 00 00 00       	mov    $0x0,%edi
  800a21:	eb 11                	jmp    800a34 <strtol+0x3b>
  800a23:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a28:	3c 2d                	cmp    $0x2d,%al
  800a2a:	75 08                	jne    800a34 <strtol+0x3b>
		s++, neg = 1;
  800a2c:	83 c1 01             	add    $0x1,%ecx
  800a2f:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a34:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a3a:	75 15                	jne    800a51 <strtol+0x58>
  800a3c:	80 39 30             	cmpb   $0x30,(%ecx)
  800a3f:	75 10                	jne    800a51 <strtol+0x58>
  800a41:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a45:	75 7c                	jne    800ac3 <strtol+0xca>
		s += 2, base = 16;
  800a47:	83 c1 02             	add    $0x2,%ecx
  800a4a:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a4f:	eb 16                	jmp    800a67 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a51:	85 db                	test   %ebx,%ebx
  800a53:	75 12                	jne    800a67 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a55:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a5a:	80 39 30             	cmpb   $0x30,(%ecx)
  800a5d:	75 08                	jne    800a67 <strtol+0x6e>
		s++, base = 8;
  800a5f:	83 c1 01             	add    $0x1,%ecx
  800a62:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a67:	b8 00 00 00 00       	mov    $0x0,%eax
  800a6c:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a6f:	0f b6 11             	movzbl (%ecx),%edx
  800a72:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a75:	89 f3                	mov    %esi,%ebx
  800a77:	80 fb 09             	cmp    $0x9,%bl
  800a7a:	77 08                	ja     800a84 <strtol+0x8b>
			dig = *s - '0';
  800a7c:	0f be d2             	movsbl %dl,%edx
  800a7f:	83 ea 30             	sub    $0x30,%edx
  800a82:	eb 22                	jmp    800aa6 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a84:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a87:	89 f3                	mov    %esi,%ebx
  800a89:	80 fb 19             	cmp    $0x19,%bl
  800a8c:	77 08                	ja     800a96 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a8e:	0f be d2             	movsbl %dl,%edx
  800a91:	83 ea 57             	sub    $0x57,%edx
  800a94:	eb 10                	jmp    800aa6 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a96:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a99:	89 f3                	mov    %esi,%ebx
  800a9b:	80 fb 19             	cmp    $0x19,%bl
  800a9e:	77 16                	ja     800ab6 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800aa0:	0f be d2             	movsbl %dl,%edx
  800aa3:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800aa6:	3b 55 10             	cmp    0x10(%ebp),%edx
  800aa9:	7d 0b                	jge    800ab6 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800aab:	83 c1 01             	add    $0x1,%ecx
  800aae:	0f af 45 10          	imul   0x10(%ebp),%eax
  800ab2:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ab4:	eb b9                	jmp    800a6f <strtol+0x76>

	if (endptr)
  800ab6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800aba:	74 0d                	je     800ac9 <strtol+0xd0>
		*endptr = (char *) s;
  800abc:	8b 75 0c             	mov    0xc(%ebp),%esi
  800abf:	89 0e                	mov    %ecx,(%esi)
  800ac1:	eb 06                	jmp    800ac9 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ac3:	85 db                	test   %ebx,%ebx
  800ac5:	74 98                	je     800a5f <strtol+0x66>
  800ac7:	eb 9e                	jmp    800a67 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800ac9:	89 c2                	mov    %eax,%edx
  800acb:	f7 da                	neg    %edx
  800acd:	85 ff                	test   %edi,%edi
  800acf:	0f 45 c2             	cmovne %edx,%eax
}
  800ad2:	5b                   	pop    %ebx
  800ad3:	5e                   	pop    %esi
  800ad4:	5f                   	pop    %edi
  800ad5:	5d                   	pop    %ebp
  800ad6:	c3                   	ret    
  800ad7:	66 90                	xchg   %ax,%ax
  800ad9:	66 90                	xchg   %ax,%ax
  800adb:	66 90                	xchg   %ax,%ax
  800add:	66 90                	xchg   %ax,%ax
  800adf:	90                   	nop

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

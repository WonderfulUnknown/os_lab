
obj/user/badsegment：     文件格式 elf32-i386


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
  80002c:	e8 0d 00 00 00       	call   80003e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	// Try to load the kernel's TSS selector into the DS register.
	asm volatile("movw $0x28,%ax; movw %ax,%ds");
  800036:	66 b8 28 00          	mov    $0x28,%ax
  80003a:	8e d8                	mov    %eax,%ds
}
  80003c:	5d                   	pop    %ebp
  80003d:	c3                   	ret    

0080003e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80003e:	55                   	push   %ebp
  80003f:	89 e5                	mov    %esp,%ebp
  800041:	56                   	push   %esi
  800042:	53                   	push   %ebx
  800043:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800046:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	//thisenv = 0;
	envid_t id = sys_getenvid();
  800049:	e8 c9 00 00 00       	call   800117 <sys_getenvid>
	thisenv = &envs[ENVX(id)];
  80004e:	25 ff 03 00 00       	and    $0x3ff,%eax
  800053:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800056:	c1 e0 05             	shl    $0x5,%eax
  800059:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80005e:	a3 04 10 80 00       	mov    %eax,0x801004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800063:	85 db                	test   %ebx,%ebx
  800065:	7e 07                	jle    80006e <libmain+0x30>
		binaryname = argv[0];
  800067:	8b 06                	mov    (%esi),%eax
  800069:	a3 00 10 80 00       	mov    %eax,0x801000

	// call user main routine
	umain(argc, argv);
  80006e:	83 ec 08             	sub    $0x8,%esp
  800071:	56                   	push   %esi
  800072:	53                   	push   %ebx
  800073:	e8 bb ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800078:	e8 0a 00 00 00       	call   800087 <exit>
}
  80007d:	83 c4 10             	add    $0x10,%esp
  800080:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800083:	5b                   	pop    %ebx
  800084:	5e                   	pop    %esi
  800085:	5d                   	pop    %ebp
  800086:	c3                   	ret    

00800087 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800087:	55                   	push   %ebp
  800088:	89 e5                	mov    %esp,%ebp
  80008a:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80008d:	6a 00                	push   $0x0
  80008f:	e8 42 00 00 00       	call   8000d6 <sys_env_destroy>
}
  800094:	83 c4 10             	add    $0x10,%esp
  800097:	c9                   	leave  
  800098:	c3                   	ret    

00800099 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800099:	55                   	push   %ebp
  80009a:	89 e5                	mov    %esp,%ebp
  80009c:	57                   	push   %edi
  80009d:	56                   	push   %esi
  80009e:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80009f:	b8 00 00 00 00       	mov    $0x0,%eax
  8000a4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000a7:	8b 55 08             	mov    0x8(%ebp),%edx
  8000aa:	89 c3                	mov    %eax,%ebx
  8000ac:	89 c7                	mov    %eax,%edi
  8000ae:	89 c6                	mov    %eax,%esi
  8000b0:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000b2:	5b                   	pop    %ebx
  8000b3:	5e                   	pop    %esi
  8000b4:	5f                   	pop    %edi
  8000b5:	5d                   	pop    %ebp
  8000b6:	c3                   	ret    

008000b7 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000b7:	55                   	push   %ebp
  8000b8:	89 e5                	mov    %esp,%ebp
  8000ba:	57                   	push   %edi
  8000bb:	56                   	push   %esi
  8000bc:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000bd:	ba 00 00 00 00       	mov    $0x0,%edx
  8000c2:	b8 01 00 00 00       	mov    $0x1,%eax
  8000c7:	89 d1                	mov    %edx,%ecx
  8000c9:	89 d3                	mov    %edx,%ebx
  8000cb:	89 d7                	mov    %edx,%edi
  8000cd:	89 d6                	mov    %edx,%esi
  8000cf:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000d1:	5b                   	pop    %ebx
  8000d2:	5e                   	pop    %esi
  8000d3:	5f                   	pop    %edi
  8000d4:	5d                   	pop    %ebp
  8000d5:	c3                   	ret    

008000d6 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000d6:	55                   	push   %ebp
  8000d7:	89 e5                	mov    %esp,%ebp
  8000d9:	57                   	push   %edi
  8000da:	56                   	push   %esi
  8000db:	53                   	push   %ebx
  8000dc:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000df:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000e4:	b8 03 00 00 00       	mov    $0x3,%eax
  8000e9:	8b 55 08             	mov    0x8(%ebp),%edx
  8000ec:	89 cb                	mov    %ecx,%ebx
  8000ee:	89 cf                	mov    %ecx,%edi
  8000f0:	89 ce                	mov    %ecx,%esi
  8000f2:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000f4:	85 c0                	test   %eax,%eax
  8000f6:	7e 17                	jle    80010f <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000f8:	83 ec 0c             	sub    $0xc,%esp
  8000fb:	50                   	push   %eax
  8000fc:	6a 03                	push   $0x3
  8000fe:	68 8a 0d 80 00       	push   $0x800d8a
  800103:	6a 23                	push   $0x23
  800105:	68 a7 0d 80 00       	push   $0x800da7
  80010a:	e8 27 00 00 00       	call   800136 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  80010f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800112:	5b                   	pop    %ebx
  800113:	5e                   	pop    %esi
  800114:	5f                   	pop    %edi
  800115:	5d                   	pop    %ebp
  800116:	c3                   	ret    

00800117 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800117:	55                   	push   %ebp
  800118:	89 e5                	mov    %esp,%ebp
  80011a:	57                   	push   %edi
  80011b:	56                   	push   %esi
  80011c:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80011d:	ba 00 00 00 00       	mov    $0x0,%edx
  800122:	b8 02 00 00 00       	mov    $0x2,%eax
  800127:	89 d1                	mov    %edx,%ecx
  800129:	89 d3                	mov    %edx,%ebx
  80012b:	89 d7                	mov    %edx,%edi
  80012d:	89 d6                	mov    %edx,%esi
  80012f:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800131:	5b                   	pop    %ebx
  800132:	5e                   	pop    %esi
  800133:	5f                   	pop    %edi
  800134:	5d                   	pop    %ebp
  800135:	c3                   	ret    

00800136 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800136:	55                   	push   %ebp
  800137:	89 e5                	mov    %esp,%ebp
  800139:	56                   	push   %esi
  80013a:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  80013b:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80013e:	8b 35 00 10 80 00    	mov    0x801000,%esi
  800144:	e8 ce ff ff ff       	call   800117 <sys_getenvid>
  800149:	83 ec 0c             	sub    $0xc,%esp
  80014c:	ff 75 0c             	pushl  0xc(%ebp)
  80014f:	ff 75 08             	pushl  0x8(%ebp)
  800152:	56                   	push   %esi
  800153:	50                   	push   %eax
  800154:	68 b8 0d 80 00       	push   $0x800db8
  800159:	e8 b1 00 00 00       	call   80020f <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80015e:	83 c4 18             	add    $0x18,%esp
  800161:	53                   	push   %ebx
  800162:	ff 75 10             	pushl  0x10(%ebp)
  800165:	e8 54 00 00 00       	call   8001be <vcprintf>
	cprintf("\n");
  80016a:	c7 04 24 dc 0d 80 00 	movl   $0x800ddc,(%esp)
  800171:	e8 99 00 00 00       	call   80020f <cprintf>
  800176:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800179:	cc                   	int3   
  80017a:	eb fd                	jmp    800179 <_panic+0x43>

0080017c <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80017c:	55                   	push   %ebp
  80017d:	89 e5                	mov    %esp,%ebp
  80017f:	53                   	push   %ebx
  800180:	83 ec 04             	sub    $0x4,%esp
  800183:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800186:	8b 13                	mov    (%ebx),%edx
  800188:	8d 42 01             	lea    0x1(%edx),%eax
  80018b:	89 03                	mov    %eax,(%ebx)
  80018d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800190:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800194:	3d ff 00 00 00       	cmp    $0xff,%eax
  800199:	75 1a                	jne    8001b5 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  80019b:	83 ec 08             	sub    $0x8,%esp
  80019e:	68 ff 00 00 00       	push   $0xff
  8001a3:	8d 43 08             	lea    0x8(%ebx),%eax
  8001a6:	50                   	push   %eax
  8001a7:	e8 ed fe ff ff       	call   800099 <sys_cputs>
		b->idx = 0;
  8001ac:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001b2:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001b5:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001b9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001bc:	c9                   	leave  
  8001bd:	c3                   	ret    

008001be <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001be:	55                   	push   %ebp
  8001bf:	89 e5                	mov    %esp,%ebp
  8001c1:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001c7:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001ce:	00 00 00 
	b.cnt = 0;
  8001d1:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001d8:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001db:	ff 75 0c             	pushl  0xc(%ebp)
  8001de:	ff 75 08             	pushl  0x8(%ebp)
  8001e1:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001e7:	50                   	push   %eax
  8001e8:	68 7c 01 80 00       	push   $0x80017c
  8001ed:	e8 54 01 00 00       	call   800346 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001f2:	83 c4 08             	add    $0x8,%esp
  8001f5:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001fb:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800201:	50                   	push   %eax
  800202:	e8 92 fe ff ff       	call   800099 <sys_cputs>

	return b.cnt;
}
  800207:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80020d:	c9                   	leave  
  80020e:	c3                   	ret    

0080020f <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80020f:	55                   	push   %ebp
  800210:	89 e5                	mov    %esp,%ebp
  800212:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800215:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800218:	50                   	push   %eax
  800219:	ff 75 08             	pushl  0x8(%ebp)
  80021c:	e8 9d ff ff ff       	call   8001be <vcprintf>
	va_end(ap);

	return cnt;
}
  800221:	c9                   	leave  
  800222:	c3                   	ret    

00800223 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800223:	55                   	push   %ebp
  800224:	89 e5                	mov    %esp,%ebp
  800226:	57                   	push   %edi
  800227:	56                   	push   %esi
  800228:	53                   	push   %ebx
  800229:	83 ec 1c             	sub    $0x1c,%esp
  80022c:	89 c7                	mov    %eax,%edi
  80022e:	89 d6                	mov    %edx,%esi
  800230:	8b 45 08             	mov    0x8(%ebp),%eax
  800233:	8b 55 0c             	mov    0xc(%ebp),%edx
  800236:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800239:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80023c:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80023f:	bb 00 00 00 00       	mov    $0x0,%ebx
  800244:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800247:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80024a:	39 d3                	cmp    %edx,%ebx
  80024c:	72 05                	jb     800253 <printnum+0x30>
  80024e:	39 45 10             	cmp    %eax,0x10(%ebp)
  800251:	77 45                	ja     800298 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800253:	83 ec 0c             	sub    $0xc,%esp
  800256:	ff 75 18             	pushl  0x18(%ebp)
  800259:	8b 45 14             	mov    0x14(%ebp),%eax
  80025c:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80025f:	53                   	push   %ebx
  800260:	ff 75 10             	pushl  0x10(%ebp)
  800263:	83 ec 08             	sub    $0x8,%esp
  800266:	ff 75 e4             	pushl  -0x1c(%ebp)
  800269:	ff 75 e0             	pushl  -0x20(%ebp)
  80026c:	ff 75 dc             	pushl  -0x24(%ebp)
  80026f:	ff 75 d8             	pushl  -0x28(%ebp)
  800272:	e8 69 08 00 00       	call   800ae0 <__udivdi3>
  800277:	83 c4 18             	add    $0x18,%esp
  80027a:	52                   	push   %edx
  80027b:	50                   	push   %eax
  80027c:	89 f2                	mov    %esi,%edx
  80027e:	89 f8                	mov    %edi,%eax
  800280:	e8 9e ff ff ff       	call   800223 <printnum>
  800285:	83 c4 20             	add    $0x20,%esp
  800288:	eb 18                	jmp    8002a2 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80028a:	83 ec 08             	sub    $0x8,%esp
  80028d:	56                   	push   %esi
  80028e:	ff 75 18             	pushl  0x18(%ebp)
  800291:	ff d7                	call   *%edi
  800293:	83 c4 10             	add    $0x10,%esp
  800296:	eb 03                	jmp    80029b <printnum+0x78>
  800298:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80029b:	83 eb 01             	sub    $0x1,%ebx
  80029e:	85 db                	test   %ebx,%ebx
  8002a0:	7f e8                	jg     80028a <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002a2:	83 ec 08             	sub    $0x8,%esp
  8002a5:	56                   	push   %esi
  8002a6:	83 ec 04             	sub    $0x4,%esp
  8002a9:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002ac:	ff 75 e0             	pushl  -0x20(%ebp)
  8002af:	ff 75 dc             	pushl  -0x24(%ebp)
  8002b2:	ff 75 d8             	pushl  -0x28(%ebp)
  8002b5:	e8 56 09 00 00       	call   800c10 <__umoddi3>
  8002ba:	83 c4 14             	add    $0x14,%esp
  8002bd:	0f be 80 de 0d 80 00 	movsbl 0x800dde(%eax),%eax
  8002c4:	50                   	push   %eax
  8002c5:	ff d7                	call   *%edi
}
  8002c7:	83 c4 10             	add    $0x10,%esp
  8002ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002cd:	5b                   	pop    %ebx
  8002ce:	5e                   	pop    %esi
  8002cf:	5f                   	pop    %edi
  8002d0:	5d                   	pop    %ebp
  8002d1:	c3                   	ret    

008002d2 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002d2:	55                   	push   %ebp
  8002d3:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002d5:	83 fa 01             	cmp    $0x1,%edx
  8002d8:	7e 0e                	jle    8002e8 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002da:	8b 10                	mov    (%eax),%edx
  8002dc:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002df:	89 08                	mov    %ecx,(%eax)
  8002e1:	8b 02                	mov    (%edx),%eax
  8002e3:	8b 52 04             	mov    0x4(%edx),%edx
  8002e6:	eb 22                	jmp    80030a <getuint+0x38>
	else if (lflag)
  8002e8:	85 d2                	test   %edx,%edx
  8002ea:	74 10                	je     8002fc <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002ec:	8b 10                	mov    (%eax),%edx
  8002ee:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002f1:	89 08                	mov    %ecx,(%eax)
  8002f3:	8b 02                	mov    (%edx),%eax
  8002f5:	ba 00 00 00 00       	mov    $0x0,%edx
  8002fa:	eb 0e                	jmp    80030a <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8002fc:	8b 10                	mov    (%eax),%edx
  8002fe:	8d 4a 04             	lea    0x4(%edx),%ecx
  800301:	89 08                	mov    %ecx,(%eax)
  800303:	8b 02                	mov    (%edx),%eax
  800305:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80030a:	5d                   	pop    %ebp
  80030b:	c3                   	ret    

0080030c <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80030c:	55                   	push   %ebp
  80030d:	89 e5                	mov    %esp,%ebp
  80030f:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800312:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800316:	8b 10                	mov    (%eax),%edx
  800318:	3b 50 04             	cmp    0x4(%eax),%edx
  80031b:	73 0a                	jae    800327 <sprintputch+0x1b>
		*b->buf++ = ch;
  80031d:	8d 4a 01             	lea    0x1(%edx),%ecx
  800320:	89 08                	mov    %ecx,(%eax)
  800322:	8b 45 08             	mov    0x8(%ebp),%eax
  800325:	88 02                	mov    %al,(%edx)
}
  800327:	5d                   	pop    %ebp
  800328:	c3                   	ret    

00800329 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800329:	55                   	push   %ebp
  80032a:	89 e5                	mov    %esp,%ebp
  80032c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80032f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800332:	50                   	push   %eax
  800333:	ff 75 10             	pushl  0x10(%ebp)
  800336:	ff 75 0c             	pushl  0xc(%ebp)
  800339:	ff 75 08             	pushl  0x8(%ebp)
  80033c:	e8 05 00 00 00       	call   800346 <vprintfmt>
	va_end(ap);
}
  800341:	83 c4 10             	add    $0x10,%esp
  800344:	c9                   	leave  
  800345:	c3                   	ret    

00800346 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800346:	55                   	push   %ebp
  800347:	89 e5                	mov    %esp,%ebp
  800349:	57                   	push   %edi
  80034a:	56                   	push   %esi
  80034b:	53                   	push   %ebx
  80034c:	83 ec 2c             	sub    $0x2c,%esp
  80034f:	8b 75 08             	mov    0x8(%ebp),%esi
  800352:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800355:	8b 7d 10             	mov    0x10(%ebp),%edi
  800358:	eb 12                	jmp    80036c <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80035a:	85 c0                	test   %eax,%eax
  80035c:	0f 84 89 03 00 00    	je     8006eb <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  800362:	83 ec 08             	sub    $0x8,%esp
  800365:	53                   	push   %ebx
  800366:	50                   	push   %eax
  800367:	ff d6                	call   *%esi
  800369:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80036c:	83 c7 01             	add    $0x1,%edi
  80036f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800373:	83 f8 25             	cmp    $0x25,%eax
  800376:	75 e2                	jne    80035a <vprintfmt+0x14>
  800378:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80037c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800383:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80038a:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800391:	ba 00 00 00 00       	mov    $0x0,%edx
  800396:	eb 07                	jmp    80039f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800398:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80039b:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80039f:	8d 47 01             	lea    0x1(%edi),%eax
  8003a2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003a5:	0f b6 07             	movzbl (%edi),%eax
  8003a8:	0f b6 c8             	movzbl %al,%ecx
  8003ab:	83 e8 23             	sub    $0x23,%eax
  8003ae:	3c 55                	cmp    $0x55,%al
  8003b0:	0f 87 1a 03 00 00    	ja     8006d0 <vprintfmt+0x38a>
  8003b6:	0f b6 c0             	movzbl %al,%eax
  8003b9:	ff 24 85 80 0e 80 00 	jmp    *0x800e80(,%eax,4)
  8003c0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003c3:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003c7:	eb d6                	jmp    80039f <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003c9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003cc:	b8 00 00 00 00       	mov    $0x0,%eax
  8003d1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003d4:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003d7:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  8003db:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  8003de:	8d 51 d0             	lea    -0x30(%ecx),%edx
  8003e1:	83 fa 09             	cmp    $0x9,%edx
  8003e4:	77 39                	ja     80041f <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003e6:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003e9:	eb e9                	jmp    8003d4 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003eb:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ee:	8d 48 04             	lea    0x4(%eax),%ecx
  8003f1:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003f4:	8b 00                	mov    (%eax),%eax
  8003f6:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003fc:	eb 27                	jmp    800425 <vprintfmt+0xdf>
  8003fe:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800401:	85 c0                	test   %eax,%eax
  800403:	b9 00 00 00 00       	mov    $0x0,%ecx
  800408:	0f 49 c8             	cmovns %eax,%ecx
  80040b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80040e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800411:	eb 8c                	jmp    80039f <vprintfmt+0x59>
  800413:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800416:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80041d:	eb 80                	jmp    80039f <vprintfmt+0x59>
  80041f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800422:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800425:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800429:	0f 89 70 ff ff ff    	jns    80039f <vprintfmt+0x59>
				width = precision, precision = -1;
  80042f:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800432:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800435:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80043c:	e9 5e ff ff ff       	jmp    80039f <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800441:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800444:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800447:	e9 53 ff ff ff       	jmp    80039f <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80044c:	8b 45 14             	mov    0x14(%ebp),%eax
  80044f:	8d 50 04             	lea    0x4(%eax),%edx
  800452:	89 55 14             	mov    %edx,0x14(%ebp)
  800455:	83 ec 08             	sub    $0x8,%esp
  800458:	53                   	push   %ebx
  800459:	ff 30                	pushl  (%eax)
  80045b:	ff d6                	call   *%esi
			break;
  80045d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800460:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800463:	e9 04 ff ff ff       	jmp    80036c <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800468:	8b 45 14             	mov    0x14(%ebp),%eax
  80046b:	8d 50 04             	lea    0x4(%eax),%edx
  80046e:	89 55 14             	mov    %edx,0x14(%ebp)
  800471:	8b 00                	mov    (%eax),%eax
  800473:	99                   	cltd   
  800474:	31 d0                	xor    %edx,%eax
  800476:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800478:	83 f8 07             	cmp    $0x7,%eax
  80047b:	7f 0b                	jg     800488 <vprintfmt+0x142>
  80047d:	8b 14 85 e0 0f 80 00 	mov    0x800fe0(,%eax,4),%edx
  800484:	85 d2                	test   %edx,%edx
  800486:	75 18                	jne    8004a0 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800488:	50                   	push   %eax
  800489:	68 f6 0d 80 00       	push   $0x800df6
  80048e:	53                   	push   %ebx
  80048f:	56                   	push   %esi
  800490:	e8 94 fe ff ff       	call   800329 <printfmt>
  800495:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800498:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80049b:	e9 cc fe ff ff       	jmp    80036c <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8004a0:	52                   	push   %edx
  8004a1:	68 ff 0d 80 00       	push   $0x800dff
  8004a6:	53                   	push   %ebx
  8004a7:	56                   	push   %esi
  8004a8:	e8 7c fe ff ff       	call   800329 <printfmt>
  8004ad:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004b0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004b3:	e9 b4 fe ff ff       	jmp    80036c <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004b8:	8b 45 14             	mov    0x14(%ebp),%eax
  8004bb:	8d 50 04             	lea    0x4(%eax),%edx
  8004be:	89 55 14             	mov    %edx,0x14(%ebp)
  8004c1:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004c3:	85 ff                	test   %edi,%edi
  8004c5:	b8 ef 0d 80 00       	mov    $0x800def,%eax
  8004ca:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004cd:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004d1:	0f 8e 94 00 00 00    	jle    80056b <vprintfmt+0x225>
  8004d7:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004db:	0f 84 98 00 00 00    	je     800579 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004e1:	83 ec 08             	sub    $0x8,%esp
  8004e4:	ff 75 d0             	pushl  -0x30(%ebp)
  8004e7:	57                   	push   %edi
  8004e8:	e8 86 02 00 00       	call   800773 <strnlen>
  8004ed:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004f0:	29 c1                	sub    %eax,%ecx
  8004f2:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  8004f5:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004f8:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004fc:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004ff:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800502:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800504:	eb 0f                	jmp    800515 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800506:	83 ec 08             	sub    $0x8,%esp
  800509:	53                   	push   %ebx
  80050a:	ff 75 e0             	pushl  -0x20(%ebp)
  80050d:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80050f:	83 ef 01             	sub    $0x1,%edi
  800512:	83 c4 10             	add    $0x10,%esp
  800515:	85 ff                	test   %edi,%edi
  800517:	7f ed                	jg     800506 <vprintfmt+0x1c0>
  800519:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80051c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80051f:	85 c9                	test   %ecx,%ecx
  800521:	b8 00 00 00 00       	mov    $0x0,%eax
  800526:	0f 49 c1             	cmovns %ecx,%eax
  800529:	29 c1                	sub    %eax,%ecx
  80052b:	89 75 08             	mov    %esi,0x8(%ebp)
  80052e:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800531:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800534:	89 cb                	mov    %ecx,%ebx
  800536:	eb 4d                	jmp    800585 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800538:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80053c:	74 1b                	je     800559 <vprintfmt+0x213>
  80053e:	0f be c0             	movsbl %al,%eax
  800541:	83 e8 20             	sub    $0x20,%eax
  800544:	83 f8 5e             	cmp    $0x5e,%eax
  800547:	76 10                	jbe    800559 <vprintfmt+0x213>
					putch('?', putdat);
  800549:	83 ec 08             	sub    $0x8,%esp
  80054c:	ff 75 0c             	pushl  0xc(%ebp)
  80054f:	6a 3f                	push   $0x3f
  800551:	ff 55 08             	call   *0x8(%ebp)
  800554:	83 c4 10             	add    $0x10,%esp
  800557:	eb 0d                	jmp    800566 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800559:	83 ec 08             	sub    $0x8,%esp
  80055c:	ff 75 0c             	pushl  0xc(%ebp)
  80055f:	52                   	push   %edx
  800560:	ff 55 08             	call   *0x8(%ebp)
  800563:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800566:	83 eb 01             	sub    $0x1,%ebx
  800569:	eb 1a                	jmp    800585 <vprintfmt+0x23f>
  80056b:	89 75 08             	mov    %esi,0x8(%ebp)
  80056e:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800571:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800574:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800577:	eb 0c                	jmp    800585 <vprintfmt+0x23f>
  800579:	89 75 08             	mov    %esi,0x8(%ebp)
  80057c:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80057f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800582:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800585:	83 c7 01             	add    $0x1,%edi
  800588:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80058c:	0f be d0             	movsbl %al,%edx
  80058f:	85 d2                	test   %edx,%edx
  800591:	74 23                	je     8005b6 <vprintfmt+0x270>
  800593:	85 f6                	test   %esi,%esi
  800595:	78 a1                	js     800538 <vprintfmt+0x1f2>
  800597:	83 ee 01             	sub    $0x1,%esi
  80059a:	79 9c                	jns    800538 <vprintfmt+0x1f2>
  80059c:	89 df                	mov    %ebx,%edi
  80059e:	8b 75 08             	mov    0x8(%ebp),%esi
  8005a1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005a4:	eb 18                	jmp    8005be <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005a6:	83 ec 08             	sub    $0x8,%esp
  8005a9:	53                   	push   %ebx
  8005aa:	6a 20                	push   $0x20
  8005ac:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005ae:	83 ef 01             	sub    $0x1,%edi
  8005b1:	83 c4 10             	add    $0x10,%esp
  8005b4:	eb 08                	jmp    8005be <vprintfmt+0x278>
  8005b6:	89 df                	mov    %ebx,%edi
  8005b8:	8b 75 08             	mov    0x8(%ebp),%esi
  8005bb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005be:	85 ff                	test   %edi,%edi
  8005c0:	7f e4                	jg     8005a6 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005c2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005c5:	e9 a2 fd ff ff       	jmp    80036c <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005ca:	83 fa 01             	cmp    $0x1,%edx
  8005cd:	7e 16                	jle    8005e5 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  8005cf:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d2:	8d 50 08             	lea    0x8(%eax),%edx
  8005d5:	89 55 14             	mov    %edx,0x14(%ebp)
  8005d8:	8b 50 04             	mov    0x4(%eax),%edx
  8005db:	8b 00                	mov    (%eax),%eax
  8005dd:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005e0:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005e3:	eb 32                	jmp    800617 <vprintfmt+0x2d1>
	else if (lflag)
  8005e5:	85 d2                	test   %edx,%edx
  8005e7:	74 18                	je     800601 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  8005e9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ec:	8d 50 04             	lea    0x4(%eax),%edx
  8005ef:	89 55 14             	mov    %edx,0x14(%ebp)
  8005f2:	8b 00                	mov    (%eax),%eax
  8005f4:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005f7:	89 c1                	mov    %eax,%ecx
  8005f9:	c1 f9 1f             	sar    $0x1f,%ecx
  8005fc:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005ff:	eb 16                	jmp    800617 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  800601:	8b 45 14             	mov    0x14(%ebp),%eax
  800604:	8d 50 04             	lea    0x4(%eax),%edx
  800607:	89 55 14             	mov    %edx,0x14(%ebp)
  80060a:	8b 00                	mov    (%eax),%eax
  80060c:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80060f:	89 c1                	mov    %eax,%ecx
  800611:	c1 f9 1f             	sar    $0x1f,%ecx
  800614:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800617:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80061a:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80061d:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800622:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800626:	79 74                	jns    80069c <vprintfmt+0x356>
				putch('-', putdat);
  800628:	83 ec 08             	sub    $0x8,%esp
  80062b:	53                   	push   %ebx
  80062c:	6a 2d                	push   $0x2d
  80062e:	ff d6                	call   *%esi
				num = -(long long) num;
  800630:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800633:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800636:	f7 d8                	neg    %eax
  800638:	83 d2 00             	adc    $0x0,%edx
  80063b:	f7 da                	neg    %edx
  80063d:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800640:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800645:	eb 55                	jmp    80069c <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800647:	8d 45 14             	lea    0x14(%ebp),%eax
  80064a:	e8 83 fc ff ff       	call   8002d2 <getuint>
			base = 10;
  80064f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800654:	eb 46                	jmp    80069c <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800656:	8d 45 14             	lea    0x14(%ebp),%eax
  800659:	e8 74 fc ff ff       	call   8002d2 <getuint>
			base = 8;
  80065e:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800663:	eb 37                	jmp    80069c <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  800665:	83 ec 08             	sub    $0x8,%esp
  800668:	53                   	push   %ebx
  800669:	6a 30                	push   $0x30
  80066b:	ff d6                	call   *%esi
			putch('x', putdat);
  80066d:	83 c4 08             	add    $0x8,%esp
  800670:	53                   	push   %ebx
  800671:	6a 78                	push   $0x78
  800673:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800675:	8b 45 14             	mov    0x14(%ebp),%eax
  800678:	8d 50 04             	lea    0x4(%eax),%edx
  80067b:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80067e:	8b 00                	mov    (%eax),%eax
  800680:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800685:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800688:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  80068d:	eb 0d                	jmp    80069c <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  80068f:	8d 45 14             	lea    0x14(%ebp),%eax
  800692:	e8 3b fc ff ff       	call   8002d2 <getuint>
			base = 16;
  800697:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  80069c:	83 ec 0c             	sub    $0xc,%esp
  80069f:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8006a3:	57                   	push   %edi
  8006a4:	ff 75 e0             	pushl  -0x20(%ebp)
  8006a7:	51                   	push   %ecx
  8006a8:	52                   	push   %edx
  8006a9:	50                   	push   %eax
  8006aa:	89 da                	mov    %ebx,%edx
  8006ac:	89 f0                	mov    %esi,%eax
  8006ae:	e8 70 fb ff ff       	call   800223 <printnum>
			break;
  8006b3:	83 c4 20             	add    $0x20,%esp
  8006b6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006b9:	e9 ae fc ff ff       	jmp    80036c <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006be:	83 ec 08             	sub    $0x8,%esp
  8006c1:	53                   	push   %ebx
  8006c2:	51                   	push   %ecx
  8006c3:	ff d6                	call   *%esi
			break;
  8006c5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006c8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006cb:	e9 9c fc ff ff       	jmp    80036c <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006d0:	83 ec 08             	sub    $0x8,%esp
  8006d3:	53                   	push   %ebx
  8006d4:	6a 25                	push   $0x25
  8006d6:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006d8:	83 c4 10             	add    $0x10,%esp
  8006db:	eb 03                	jmp    8006e0 <vprintfmt+0x39a>
  8006dd:	83 ef 01             	sub    $0x1,%edi
  8006e0:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006e4:	75 f7                	jne    8006dd <vprintfmt+0x397>
  8006e6:	e9 81 fc ff ff       	jmp    80036c <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006eb:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006ee:	5b                   	pop    %ebx
  8006ef:	5e                   	pop    %esi
  8006f0:	5f                   	pop    %edi
  8006f1:	5d                   	pop    %ebp
  8006f2:	c3                   	ret    

008006f3 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006f3:	55                   	push   %ebp
  8006f4:	89 e5                	mov    %esp,%ebp
  8006f6:	83 ec 18             	sub    $0x18,%esp
  8006f9:	8b 45 08             	mov    0x8(%ebp),%eax
  8006fc:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006ff:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800702:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800706:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800709:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800710:	85 c0                	test   %eax,%eax
  800712:	74 26                	je     80073a <vsnprintf+0x47>
  800714:	85 d2                	test   %edx,%edx
  800716:	7e 22                	jle    80073a <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800718:	ff 75 14             	pushl  0x14(%ebp)
  80071b:	ff 75 10             	pushl  0x10(%ebp)
  80071e:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800721:	50                   	push   %eax
  800722:	68 0c 03 80 00       	push   $0x80030c
  800727:	e8 1a fc ff ff       	call   800346 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80072c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80072f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800732:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800735:	83 c4 10             	add    $0x10,%esp
  800738:	eb 05                	jmp    80073f <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  80073a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80073f:	c9                   	leave  
  800740:	c3                   	ret    

00800741 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800741:	55                   	push   %ebp
  800742:	89 e5                	mov    %esp,%ebp
  800744:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800747:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  80074a:	50                   	push   %eax
  80074b:	ff 75 10             	pushl  0x10(%ebp)
  80074e:	ff 75 0c             	pushl  0xc(%ebp)
  800751:	ff 75 08             	pushl  0x8(%ebp)
  800754:	e8 9a ff ff ff       	call   8006f3 <vsnprintf>
	va_end(ap);

	return rc;
}
  800759:	c9                   	leave  
  80075a:	c3                   	ret    

0080075b <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80075b:	55                   	push   %ebp
  80075c:	89 e5                	mov    %esp,%ebp
  80075e:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800761:	b8 00 00 00 00       	mov    $0x0,%eax
  800766:	eb 03                	jmp    80076b <strlen+0x10>
		n++;
  800768:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80076b:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80076f:	75 f7                	jne    800768 <strlen+0xd>
		n++;
	return n;
}
  800771:	5d                   	pop    %ebp
  800772:	c3                   	ret    

00800773 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800773:	55                   	push   %ebp
  800774:	89 e5                	mov    %esp,%ebp
  800776:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800779:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80077c:	ba 00 00 00 00       	mov    $0x0,%edx
  800781:	eb 03                	jmp    800786 <strnlen+0x13>
		n++;
  800783:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800786:	39 c2                	cmp    %eax,%edx
  800788:	74 08                	je     800792 <strnlen+0x1f>
  80078a:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80078e:	75 f3                	jne    800783 <strnlen+0x10>
  800790:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800792:	5d                   	pop    %ebp
  800793:	c3                   	ret    

00800794 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800794:	55                   	push   %ebp
  800795:	89 e5                	mov    %esp,%ebp
  800797:	53                   	push   %ebx
  800798:	8b 45 08             	mov    0x8(%ebp),%eax
  80079b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80079e:	89 c2                	mov    %eax,%edx
  8007a0:	83 c2 01             	add    $0x1,%edx
  8007a3:	83 c1 01             	add    $0x1,%ecx
  8007a6:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007aa:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007ad:	84 db                	test   %bl,%bl
  8007af:	75 ef                	jne    8007a0 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007b1:	5b                   	pop    %ebx
  8007b2:	5d                   	pop    %ebp
  8007b3:	c3                   	ret    

008007b4 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007b4:	55                   	push   %ebp
  8007b5:	89 e5                	mov    %esp,%ebp
  8007b7:	53                   	push   %ebx
  8007b8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007bb:	53                   	push   %ebx
  8007bc:	e8 9a ff ff ff       	call   80075b <strlen>
  8007c1:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007c4:	ff 75 0c             	pushl  0xc(%ebp)
  8007c7:	01 d8                	add    %ebx,%eax
  8007c9:	50                   	push   %eax
  8007ca:	e8 c5 ff ff ff       	call   800794 <strcpy>
	return dst;
}
  8007cf:	89 d8                	mov    %ebx,%eax
  8007d1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007d4:	c9                   	leave  
  8007d5:	c3                   	ret    

008007d6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007d6:	55                   	push   %ebp
  8007d7:	89 e5                	mov    %esp,%ebp
  8007d9:	56                   	push   %esi
  8007da:	53                   	push   %ebx
  8007db:	8b 75 08             	mov    0x8(%ebp),%esi
  8007de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007e1:	89 f3                	mov    %esi,%ebx
  8007e3:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007e6:	89 f2                	mov    %esi,%edx
  8007e8:	eb 0f                	jmp    8007f9 <strncpy+0x23>
		*dst++ = *src;
  8007ea:	83 c2 01             	add    $0x1,%edx
  8007ed:	0f b6 01             	movzbl (%ecx),%eax
  8007f0:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007f3:	80 39 01             	cmpb   $0x1,(%ecx)
  8007f6:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007f9:	39 da                	cmp    %ebx,%edx
  8007fb:	75 ed                	jne    8007ea <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007fd:	89 f0                	mov    %esi,%eax
  8007ff:	5b                   	pop    %ebx
  800800:	5e                   	pop    %esi
  800801:	5d                   	pop    %ebp
  800802:	c3                   	ret    

00800803 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800803:	55                   	push   %ebp
  800804:	89 e5                	mov    %esp,%ebp
  800806:	56                   	push   %esi
  800807:	53                   	push   %ebx
  800808:	8b 75 08             	mov    0x8(%ebp),%esi
  80080b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80080e:	8b 55 10             	mov    0x10(%ebp),%edx
  800811:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800813:	85 d2                	test   %edx,%edx
  800815:	74 21                	je     800838 <strlcpy+0x35>
  800817:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  80081b:	89 f2                	mov    %esi,%edx
  80081d:	eb 09                	jmp    800828 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80081f:	83 c2 01             	add    $0x1,%edx
  800822:	83 c1 01             	add    $0x1,%ecx
  800825:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800828:	39 c2                	cmp    %eax,%edx
  80082a:	74 09                	je     800835 <strlcpy+0x32>
  80082c:	0f b6 19             	movzbl (%ecx),%ebx
  80082f:	84 db                	test   %bl,%bl
  800831:	75 ec                	jne    80081f <strlcpy+0x1c>
  800833:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800835:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800838:	29 f0                	sub    %esi,%eax
}
  80083a:	5b                   	pop    %ebx
  80083b:	5e                   	pop    %esi
  80083c:	5d                   	pop    %ebp
  80083d:	c3                   	ret    

0080083e <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80083e:	55                   	push   %ebp
  80083f:	89 e5                	mov    %esp,%ebp
  800841:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800844:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800847:	eb 06                	jmp    80084f <strcmp+0x11>
		p++, q++;
  800849:	83 c1 01             	add    $0x1,%ecx
  80084c:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80084f:	0f b6 01             	movzbl (%ecx),%eax
  800852:	84 c0                	test   %al,%al
  800854:	74 04                	je     80085a <strcmp+0x1c>
  800856:	3a 02                	cmp    (%edx),%al
  800858:	74 ef                	je     800849 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  80085a:	0f b6 c0             	movzbl %al,%eax
  80085d:	0f b6 12             	movzbl (%edx),%edx
  800860:	29 d0                	sub    %edx,%eax
}
  800862:	5d                   	pop    %ebp
  800863:	c3                   	ret    

00800864 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800864:	55                   	push   %ebp
  800865:	89 e5                	mov    %esp,%ebp
  800867:	53                   	push   %ebx
  800868:	8b 45 08             	mov    0x8(%ebp),%eax
  80086b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80086e:	89 c3                	mov    %eax,%ebx
  800870:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800873:	eb 06                	jmp    80087b <strncmp+0x17>
		n--, p++, q++;
  800875:	83 c0 01             	add    $0x1,%eax
  800878:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80087b:	39 d8                	cmp    %ebx,%eax
  80087d:	74 15                	je     800894 <strncmp+0x30>
  80087f:	0f b6 08             	movzbl (%eax),%ecx
  800882:	84 c9                	test   %cl,%cl
  800884:	74 04                	je     80088a <strncmp+0x26>
  800886:	3a 0a                	cmp    (%edx),%cl
  800888:	74 eb                	je     800875 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80088a:	0f b6 00             	movzbl (%eax),%eax
  80088d:	0f b6 12             	movzbl (%edx),%edx
  800890:	29 d0                	sub    %edx,%eax
  800892:	eb 05                	jmp    800899 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800894:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800899:	5b                   	pop    %ebx
  80089a:	5d                   	pop    %ebp
  80089b:	c3                   	ret    

0080089c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80089c:	55                   	push   %ebp
  80089d:	89 e5                	mov    %esp,%ebp
  80089f:	8b 45 08             	mov    0x8(%ebp),%eax
  8008a2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008a6:	eb 07                	jmp    8008af <strchr+0x13>
		if (*s == c)
  8008a8:	38 ca                	cmp    %cl,%dl
  8008aa:	74 0f                	je     8008bb <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008ac:	83 c0 01             	add    $0x1,%eax
  8008af:	0f b6 10             	movzbl (%eax),%edx
  8008b2:	84 d2                	test   %dl,%dl
  8008b4:	75 f2                	jne    8008a8 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008bb:	5d                   	pop    %ebp
  8008bc:	c3                   	ret    

008008bd <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008bd:	55                   	push   %ebp
  8008be:	89 e5                	mov    %esp,%ebp
  8008c0:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c3:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008c7:	eb 03                	jmp    8008cc <strfind+0xf>
  8008c9:	83 c0 01             	add    $0x1,%eax
  8008cc:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008cf:	38 ca                	cmp    %cl,%dl
  8008d1:	74 04                	je     8008d7 <strfind+0x1a>
  8008d3:	84 d2                	test   %dl,%dl
  8008d5:	75 f2                	jne    8008c9 <strfind+0xc>
			break;
	return (char *) s;
}
  8008d7:	5d                   	pop    %ebp
  8008d8:	c3                   	ret    

008008d9 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008d9:	55                   	push   %ebp
  8008da:	89 e5                	mov    %esp,%ebp
  8008dc:	57                   	push   %edi
  8008dd:	56                   	push   %esi
  8008de:	53                   	push   %ebx
  8008df:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008e2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008e5:	85 c9                	test   %ecx,%ecx
  8008e7:	74 36                	je     80091f <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008e9:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008ef:	75 28                	jne    800919 <memset+0x40>
  8008f1:	f6 c1 03             	test   $0x3,%cl
  8008f4:	75 23                	jne    800919 <memset+0x40>
		c &= 0xFF;
  8008f6:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008fa:	89 d3                	mov    %edx,%ebx
  8008fc:	c1 e3 08             	shl    $0x8,%ebx
  8008ff:	89 d6                	mov    %edx,%esi
  800901:	c1 e6 18             	shl    $0x18,%esi
  800904:	89 d0                	mov    %edx,%eax
  800906:	c1 e0 10             	shl    $0x10,%eax
  800909:	09 f0                	or     %esi,%eax
  80090b:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  80090d:	89 d8                	mov    %ebx,%eax
  80090f:	09 d0                	or     %edx,%eax
  800911:	c1 e9 02             	shr    $0x2,%ecx
  800914:	fc                   	cld    
  800915:	f3 ab                	rep stos %eax,%es:(%edi)
  800917:	eb 06                	jmp    80091f <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800919:	8b 45 0c             	mov    0xc(%ebp),%eax
  80091c:	fc                   	cld    
  80091d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80091f:	89 f8                	mov    %edi,%eax
  800921:	5b                   	pop    %ebx
  800922:	5e                   	pop    %esi
  800923:	5f                   	pop    %edi
  800924:	5d                   	pop    %ebp
  800925:	c3                   	ret    

00800926 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800926:	55                   	push   %ebp
  800927:	89 e5                	mov    %esp,%ebp
  800929:	57                   	push   %edi
  80092a:	56                   	push   %esi
  80092b:	8b 45 08             	mov    0x8(%ebp),%eax
  80092e:	8b 75 0c             	mov    0xc(%ebp),%esi
  800931:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800934:	39 c6                	cmp    %eax,%esi
  800936:	73 35                	jae    80096d <memmove+0x47>
  800938:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80093b:	39 d0                	cmp    %edx,%eax
  80093d:	73 2e                	jae    80096d <memmove+0x47>
		s += n;
		d += n;
  80093f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800942:	89 d6                	mov    %edx,%esi
  800944:	09 fe                	or     %edi,%esi
  800946:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80094c:	75 13                	jne    800961 <memmove+0x3b>
  80094e:	f6 c1 03             	test   $0x3,%cl
  800951:	75 0e                	jne    800961 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800953:	83 ef 04             	sub    $0x4,%edi
  800956:	8d 72 fc             	lea    -0x4(%edx),%esi
  800959:	c1 e9 02             	shr    $0x2,%ecx
  80095c:	fd                   	std    
  80095d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80095f:	eb 09                	jmp    80096a <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800961:	83 ef 01             	sub    $0x1,%edi
  800964:	8d 72 ff             	lea    -0x1(%edx),%esi
  800967:	fd                   	std    
  800968:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80096a:	fc                   	cld    
  80096b:	eb 1d                	jmp    80098a <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80096d:	89 f2                	mov    %esi,%edx
  80096f:	09 c2                	or     %eax,%edx
  800971:	f6 c2 03             	test   $0x3,%dl
  800974:	75 0f                	jne    800985 <memmove+0x5f>
  800976:	f6 c1 03             	test   $0x3,%cl
  800979:	75 0a                	jne    800985 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  80097b:	c1 e9 02             	shr    $0x2,%ecx
  80097e:	89 c7                	mov    %eax,%edi
  800980:	fc                   	cld    
  800981:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800983:	eb 05                	jmp    80098a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800985:	89 c7                	mov    %eax,%edi
  800987:	fc                   	cld    
  800988:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  80098a:	5e                   	pop    %esi
  80098b:	5f                   	pop    %edi
  80098c:	5d                   	pop    %ebp
  80098d:	c3                   	ret    

0080098e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80098e:	55                   	push   %ebp
  80098f:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800991:	ff 75 10             	pushl  0x10(%ebp)
  800994:	ff 75 0c             	pushl  0xc(%ebp)
  800997:	ff 75 08             	pushl  0x8(%ebp)
  80099a:	e8 87 ff ff ff       	call   800926 <memmove>
}
  80099f:	c9                   	leave  
  8009a0:	c3                   	ret    

008009a1 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009a1:	55                   	push   %ebp
  8009a2:	89 e5                	mov    %esp,%ebp
  8009a4:	56                   	push   %esi
  8009a5:	53                   	push   %ebx
  8009a6:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009ac:	89 c6                	mov    %eax,%esi
  8009ae:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009b1:	eb 1a                	jmp    8009cd <memcmp+0x2c>
		if (*s1 != *s2)
  8009b3:	0f b6 08             	movzbl (%eax),%ecx
  8009b6:	0f b6 1a             	movzbl (%edx),%ebx
  8009b9:	38 d9                	cmp    %bl,%cl
  8009bb:	74 0a                	je     8009c7 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009bd:	0f b6 c1             	movzbl %cl,%eax
  8009c0:	0f b6 db             	movzbl %bl,%ebx
  8009c3:	29 d8                	sub    %ebx,%eax
  8009c5:	eb 0f                	jmp    8009d6 <memcmp+0x35>
		s1++, s2++;
  8009c7:	83 c0 01             	add    $0x1,%eax
  8009ca:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009cd:	39 f0                	cmp    %esi,%eax
  8009cf:	75 e2                	jne    8009b3 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009d1:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009d6:	5b                   	pop    %ebx
  8009d7:	5e                   	pop    %esi
  8009d8:	5d                   	pop    %ebp
  8009d9:	c3                   	ret    

008009da <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009da:	55                   	push   %ebp
  8009db:	89 e5                	mov    %esp,%ebp
  8009dd:	53                   	push   %ebx
  8009de:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009e1:	89 c1                	mov    %eax,%ecx
  8009e3:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009e6:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009ea:	eb 0a                	jmp    8009f6 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009ec:	0f b6 10             	movzbl (%eax),%edx
  8009ef:	39 da                	cmp    %ebx,%edx
  8009f1:	74 07                	je     8009fa <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009f3:	83 c0 01             	add    $0x1,%eax
  8009f6:	39 c8                	cmp    %ecx,%eax
  8009f8:	72 f2                	jb     8009ec <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009fa:	5b                   	pop    %ebx
  8009fb:	5d                   	pop    %ebp
  8009fc:	c3                   	ret    

008009fd <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009fd:	55                   	push   %ebp
  8009fe:	89 e5                	mov    %esp,%ebp
  800a00:	57                   	push   %edi
  800a01:	56                   	push   %esi
  800a02:	53                   	push   %ebx
  800a03:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a06:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a09:	eb 03                	jmp    800a0e <strtol+0x11>
		s++;
  800a0b:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a0e:	0f b6 01             	movzbl (%ecx),%eax
  800a11:	3c 20                	cmp    $0x20,%al
  800a13:	74 f6                	je     800a0b <strtol+0xe>
  800a15:	3c 09                	cmp    $0x9,%al
  800a17:	74 f2                	je     800a0b <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a19:	3c 2b                	cmp    $0x2b,%al
  800a1b:	75 0a                	jne    800a27 <strtol+0x2a>
		s++;
  800a1d:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a20:	bf 00 00 00 00       	mov    $0x0,%edi
  800a25:	eb 11                	jmp    800a38 <strtol+0x3b>
  800a27:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a2c:	3c 2d                	cmp    $0x2d,%al
  800a2e:	75 08                	jne    800a38 <strtol+0x3b>
		s++, neg = 1;
  800a30:	83 c1 01             	add    $0x1,%ecx
  800a33:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a38:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a3e:	75 15                	jne    800a55 <strtol+0x58>
  800a40:	80 39 30             	cmpb   $0x30,(%ecx)
  800a43:	75 10                	jne    800a55 <strtol+0x58>
  800a45:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a49:	75 7c                	jne    800ac7 <strtol+0xca>
		s += 2, base = 16;
  800a4b:	83 c1 02             	add    $0x2,%ecx
  800a4e:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a53:	eb 16                	jmp    800a6b <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a55:	85 db                	test   %ebx,%ebx
  800a57:	75 12                	jne    800a6b <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a59:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a5e:	80 39 30             	cmpb   $0x30,(%ecx)
  800a61:	75 08                	jne    800a6b <strtol+0x6e>
		s++, base = 8;
  800a63:	83 c1 01             	add    $0x1,%ecx
  800a66:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a6b:	b8 00 00 00 00       	mov    $0x0,%eax
  800a70:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a73:	0f b6 11             	movzbl (%ecx),%edx
  800a76:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a79:	89 f3                	mov    %esi,%ebx
  800a7b:	80 fb 09             	cmp    $0x9,%bl
  800a7e:	77 08                	ja     800a88 <strtol+0x8b>
			dig = *s - '0';
  800a80:	0f be d2             	movsbl %dl,%edx
  800a83:	83 ea 30             	sub    $0x30,%edx
  800a86:	eb 22                	jmp    800aaa <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a88:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a8b:	89 f3                	mov    %esi,%ebx
  800a8d:	80 fb 19             	cmp    $0x19,%bl
  800a90:	77 08                	ja     800a9a <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a92:	0f be d2             	movsbl %dl,%edx
  800a95:	83 ea 57             	sub    $0x57,%edx
  800a98:	eb 10                	jmp    800aaa <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a9a:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a9d:	89 f3                	mov    %esi,%ebx
  800a9f:	80 fb 19             	cmp    $0x19,%bl
  800aa2:	77 16                	ja     800aba <strtol+0xbd>
			dig = *s - 'A' + 10;
  800aa4:	0f be d2             	movsbl %dl,%edx
  800aa7:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800aaa:	3b 55 10             	cmp    0x10(%ebp),%edx
  800aad:	7d 0b                	jge    800aba <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800aaf:	83 c1 01             	add    $0x1,%ecx
  800ab2:	0f af 45 10          	imul   0x10(%ebp),%eax
  800ab6:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ab8:	eb b9                	jmp    800a73 <strtol+0x76>

	if (endptr)
  800aba:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800abe:	74 0d                	je     800acd <strtol+0xd0>
		*endptr = (char *) s;
  800ac0:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ac3:	89 0e                	mov    %ecx,(%esi)
  800ac5:	eb 06                	jmp    800acd <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ac7:	85 db                	test   %ebx,%ebx
  800ac9:	74 98                	je     800a63 <strtol+0x66>
  800acb:	eb 9e                	jmp    800a6b <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800acd:	89 c2                	mov    %eax,%edx
  800acf:	f7 da                	neg    %edx
  800ad1:	85 ff                	test   %edi,%edi
  800ad3:	0f 45 c2             	cmovne %edx,%eax
}
  800ad6:	5b                   	pop    %ebx
  800ad7:	5e                   	pop    %esi
  800ad8:	5f                   	pop    %edi
  800ad9:	5d                   	pop    %ebp
  800ada:	c3                   	ret    
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

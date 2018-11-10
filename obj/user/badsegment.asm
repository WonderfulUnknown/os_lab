
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
  800041:	83 ec 08             	sub    $0x8,%esp
  800044:	8b 45 08             	mov    0x8(%ebp),%eax
  800047:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80004a:	c7 05 04 10 80 00 00 	movl   $0x0,0x801004
  800051:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800054:	85 c0                	test   %eax,%eax
  800056:	7e 08                	jle    800060 <libmain+0x22>
		binaryname = argv[0];
  800058:	8b 0a                	mov    (%edx),%ecx
  80005a:	89 0d 00 10 80 00    	mov    %ecx,0x801000

	// call user main routine
	umain(argc, argv);
  800060:	83 ec 08             	sub    $0x8,%esp
  800063:	52                   	push   %edx
  800064:	50                   	push   %eax
  800065:	e8 c9 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80006a:	e8 05 00 00 00       	call   800074 <exit>
}
  80006f:	83 c4 10             	add    $0x10,%esp
  800072:	c9                   	leave  
  800073:	c3                   	ret    

00800074 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800074:	55                   	push   %ebp
  800075:	89 e5                	mov    %esp,%ebp
  800077:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80007a:	6a 00                	push   $0x0
  80007c:	e8 42 00 00 00       	call   8000c3 <sys_env_destroy>
}
  800081:	83 c4 10             	add    $0x10,%esp
  800084:	c9                   	leave  
  800085:	c3                   	ret    

00800086 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800086:	55                   	push   %ebp
  800087:	89 e5                	mov    %esp,%ebp
  800089:	57                   	push   %edi
  80008a:	56                   	push   %esi
  80008b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80008c:	b8 00 00 00 00       	mov    $0x0,%eax
  800091:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800094:	8b 55 08             	mov    0x8(%ebp),%edx
  800097:	89 c3                	mov    %eax,%ebx
  800099:	89 c7                	mov    %eax,%edi
  80009b:	89 c6                	mov    %eax,%esi
  80009d:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  80009f:	5b                   	pop    %ebx
  8000a0:	5e                   	pop    %esi
  8000a1:	5f                   	pop    %edi
  8000a2:	5d                   	pop    %ebp
  8000a3:	c3                   	ret    

008000a4 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000a4:	55                   	push   %ebp
  8000a5:	89 e5                	mov    %esp,%ebp
  8000a7:	57                   	push   %edi
  8000a8:	56                   	push   %esi
  8000a9:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000aa:	ba 00 00 00 00       	mov    $0x0,%edx
  8000af:	b8 01 00 00 00       	mov    $0x1,%eax
  8000b4:	89 d1                	mov    %edx,%ecx
  8000b6:	89 d3                	mov    %edx,%ebx
  8000b8:	89 d7                	mov    %edx,%edi
  8000ba:	89 d6                	mov    %edx,%esi
  8000bc:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000be:	5b                   	pop    %ebx
  8000bf:	5e                   	pop    %esi
  8000c0:	5f                   	pop    %edi
  8000c1:	5d                   	pop    %ebp
  8000c2:	c3                   	ret    

008000c3 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000c3:	55                   	push   %ebp
  8000c4:	89 e5                	mov    %esp,%ebp
  8000c6:	57                   	push   %edi
  8000c7:	56                   	push   %esi
  8000c8:	53                   	push   %ebx
  8000c9:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000cc:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000d1:	b8 03 00 00 00       	mov    $0x3,%eax
  8000d6:	8b 55 08             	mov    0x8(%ebp),%edx
  8000d9:	89 cb                	mov    %ecx,%ebx
  8000db:	89 cf                	mov    %ecx,%edi
  8000dd:	89 ce                	mov    %ecx,%esi
  8000df:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000e1:	85 c0                	test   %eax,%eax
  8000e3:	7e 17                	jle    8000fc <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000e5:	83 ec 0c             	sub    $0xc,%esp
  8000e8:	50                   	push   %eax
  8000e9:	6a 03                	push   $0x3
  8000eb:	68 6a 0d 80 00       	push   $0x800d6a
  8000f0:	6a 23                	push   $0x23
  8000f2:	68 87 0d 80 00       	push   $0x800d87
  8000f7:	e8 27 00 00 00       	call   800123 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  8000fc:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8000ff:	5b                   	pop    %ebx
  800100:	5e                   	pop    %esi
  800101:	5f                   	pop    %edi
  800102:	5d                   	pop    %ebp
  800103:	c3                   	ret    

00800104 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800104:	55                   	push   %ebp
  800105:	89 e5                	mov    %esp,%ebp
  800107:	57                   	push   %edi
  800108:	56                   	push   %esi
  800109:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80010a:	ba 00 00 00 00       	mov    $0x0,%edx
  80010f:	b8 02 00 00 00       	mov    $0x2,%eax
  800114:	89 d1                	mov    %edx,%ecx
  800116:	89 d3                	mov    %edx,%ebx
  800118:	89 d7                	mov    %edx,%edi
  80011a:	89 d6                	mov    %edx,%esi
  80011c:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80011e:	5b                   	pop    %ebx
  80011f:	5e                   	pop    %esi
  800120:	5f                   	pop    %edi
  800121:	5d                   	pop    %ebp
  800122:	c3                   	ret    

00800123 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800123:	55                   	push   %ebp
  800124:	89 e5                	mov    %esp,%ebp
  800126:	56                   	push   %esi
  800127:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800128:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80012b:	8b 35 00 10 80 00    	mov    0x801000,%esi
  800131:	e8 ce ff ff ff       	call   800104 <sys_getenvid>
  800136:	83 ec 0c             	sub    $0xc,%esp
  800139:	ff 75 0c             	pushl  0xc(%ebp)
  80013c:	ff 75 08             	pushl  0x8(%ebp)
  80013f:	56                   	push   %esi
  800140:	50                   	push   %eax
  800141:	68 98 0d 80 00       	push   $0x800d98
  800146:	e8 b1 00 00 00       	call   8001fc <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80014b:	83 c4 18             	add    $0x18,%esp
  80014e:	53                   	push   %ebx
  80014f:	ff 75 10             	pushl  0x10(%ebp)
  800152:	e8 54 00 00 00       	call   8001ab <vcprintf>
	cprintf("\n");
  800157:	c7 04 24 bc 0d 80 00 	movl   $0x800dbc,(%esp)
  80015e:	e8 99 00 00 00       	call   8001fc <cprintf>
  800163:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800166:	cc                   	int3   
  800167:	eb fd                	jmp    800166 <_panic+0x43>

00800169 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800169:	55                   	push   %ebp
  80016a:	89 e5                	mov    %esp,%ebp
  80016c:	53                   	push   %ebx
  80016d:	83 ec 04             	sub    $0x4,%esp
  800170:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800173:	8b 13                	mov    (%ebx),%edx
  800175:	8d 42 01             	lea    0x1(%edx),%eax
  800178:	89 03                	mov    %eax,(%ebx)
  80017a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80017d:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800181:	3d ff 00 00 00       	cmp    $0xff,%eax
  800186:	75 1a                	jne    8001a2 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800188:	83 ec 08             	sub    $0x8,%esp
  80018b:	68 ff 00 00 00       	push   $0xff
  800190:	8d 43 08             	lea    0x8(%ebx),%eax
  800193:	50                   	push   %eax
  800194:	e8 ed fe ff ff       	call   800086 <sys_cputs>
		b->idx = 0;
  800199:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  80019f:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001a2:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001a6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001a9:	c9                   	leave  
  8001aa:	c3                   	ret    

008001ab <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001ab:	55                   	push   %ebp
  8001ac:	89 e5                	mov    %esp,%ebp
  8001ae:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001b4:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001bb:	00 00 00 
	b.cnt = 0;
  8001be:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001c5:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001c8:	ff 75 0c             	pushl  0xc(%ebp)
  8001cb:	ff 75 08             	pushl  0x8(%ebp)
  8001ce:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001d4:	50                   	push   %eax
  8001d5:	68 69 01 80 00       	push   $0x800169
  8001da:	e8 54 01 00 00       	call   800333 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001df:	83 c4 08             	add    $0x8,%esp
  8001e2:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001e8:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001ee:	50                   	push   %eax
  8001ef:	e8 92 fe ff ff       	call   800086 <sys_cputs>

	return b.cnt;
}
  8001f4:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001fa:	c9                   	leave  
  8001fb:	c3                   	ret    

008001fc <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001fc:	55                   	push   %ebp
  8001fd:	89 e5                	mov    %esp,%ebp
  8001ff:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800202:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800205:	50                   	push   %eax
  800206:	ff 75 08             	pushl  0x8(%ebp)
  800209:	e8 9d ff ff ff       	call   8001ab <vcprintf>
	va_end(ap);

	return cnt;
}
  80020e:	c9                   	leave  
  80020f:	c3                   	ret    

00800210 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800210:	55                   	push   %ebp
  800211:	89 e5                	mov    %esp,%ebp
  800213:	57                   	push   %edi
  800214:	56                   	push   %esi
  800215:	53                   	push   %ebx
  800216:	83 ec 1c             	sub    $0x1c,%esp
  800219:	89 c7                	mov    %eax,%edi
  80021b:	89 d6                	mov    %edx,%esi
  80021d:	8b 45 08             	mov    0x8(%ebp),%eax
  800220:	8b 55 0c             	mov    0xc(%ebp),%edx
  800223:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800226:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800229:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80022c:	bb 00 00 00 00       	mov    $0x0,%ebx
  800231:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800234:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800237:	39 d3                	cmp    %edx,%ebx
  800239:	72 05                	jb     800240 <printnum+0x30>
  80023b:	39 45 10             	cmp    %eax,0x10(%ebp)
  80023e:	77 45                	ja     800285 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800240:	83 ec 0c             	sub    $0xc,%esp
  800243:	ff 75 18             	pushl  0x18(%ebp)
  800246:	8b 45 14             	mov    0x14(%ebp),%eax
  800249:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80024c:	53                   	push   %ebx
  80024d:	ff 75 10             	pushl  0x10(%ebp)
  800250:	83 ec 08             	sub    $0x8,%esp
  800253:	ff 75 e4             	pushl  -0x1c(%ebp)
  800256:	ff 75 e0             	pushl  -0x20(%ebp)
  800259:	ff 75 dc             	pushl  -0x24(%ebp)
  80025c:	ff 75 d8             	pushl  -0x28(%ebp)
  80025f:	e8 6c 08 00 00       	call   800ad0 <__udivdi3>
  800264:	83 c4 18             	add    $0x18,%esp
  800267:	52                   	push   %edx
  800268:	50                   	push   %eax
  800269:	89 f2                	mov    %esi,%edx
  80026b:	89 f8                	mov    %edi,%eax
  80026d:	e8 9e ff ff ff       	call   800210 <printnum>
  800272:	83 c4 20             	add    $0x20,%esp
  800275:	eb 18                	jmp    80028f <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800277:	83 ec 08             	sub    $0x8,%esp
  80027a:	56                   	push   %esi
  80027b:	ff 75 18             	pushl  0x18(%ebp)
  80027e:	ff d7                	call   *%edi
  800280:	83 c4 10             	add    $0x10,%esp
  800283:	eb 03                	jmp    800288 <printnum+0x78>
  800285:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800288:	83 eb 01             	sub    $0x1,%ebx
  80028b:	85 db                	test   %ebx,%ebx
  80028d:	7f e8                	jg     800277 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80028f:	83 ec 08             	sub    $0x8,%esp
  800292:	56                   	push   %esi
  800293:	83 ec 04             	sub    $0x4,%esp
  800296:	ff 75 e4             	pushl  -0x1c(%ebp)
  800299:	ff 75 e0             	pushl  -0x20(%ebp)
  80029c:	ff 75 dc             	pushl  -0x24(%ebp)
  80029f:	ff 75 d8             	pushl  -0x28(%ebp)
  8002a2:	e8 59 09 00 00       	call   800c00 <__umoddi3>
  8002a7:	83 c4 14             	add    $0x14,%esp
  8002aa:	0f be 80 be 0d 80 00 	movsbl 0x800dbe(%eax),%eax
  8002b1:	50                   	push   %eax
  8002b2:	ff d7                	call   *%edi
}
  8002b4:	83 c4 10             	add    $0x10,%esp
  8002b7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002ba:	5b                   	pop    %ebx
  8002bb:	5e                   	pop    %esi
  8002bc:	5f                   	pop    %edi
  8002bd:	5d                   	pop    %ebp
  8002be:	c3                   	ret    

008002bf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002bf:	55                   	push   %ebp
  8002c0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002c2:	83 fa 01             	cmp    $0x1,%edx
  8002c5:	7e 0e                	jle    8002d5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002c7:	8b 10                	mov    (%eax),%edx
  8002c9:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002cc:	89 08                	mov    %ecx,(%eax)
  8002ce:	8b 02                	mov    (%edx),%eax
  8002d0:	8b 52 04             	mov    0x4(%edx),%edx
  8002d3:	eb 22                	jmp    8002f7 <getuint+0x38>
	else if (lflag)
  8002d5:	85 d2                	test   %edx,%edx
  8002d7:	74 10                	je     8002e9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002d9:	8b 10                	mov    (%eax),%edx
  8002db:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002de:	89 08                	mov    %ecx,(%eax)
  8002e0:	8b 02                	mov    (%edx),%eax
  8002e2:	ba 00 00 00 00       	mov    $0x0,%edx
  8002e7:	eb 0e                	jmp    8002f7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8002e9:	8b 10                	mov    (%eax),%edx
  8002eb:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002ee:	89 08                	mov    %ecx,(%eax)
  8002f0:	8b 02                	mov    (%edx),%eax
  8002f2:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8002f7:	5d                   	pop    %ebp
  8002f8:	c3                   	ret    

008002f9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002f9:	55                   	push   %ebp
  8002fa:	89 e5                	mov    %esp,%ebp
  8002fc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002ff:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800303:	8b 10                	mov    (%eax),%edx
  800305:	3b 50 04             	cmp    0x4(%eax),%edx
  800308:	73 0a                	jae    800314 <sprintputch+0x1b>
		*b->buf++ = ch;
  80030a:	8d 4a 01             	lea    0x1(%edx),%ecx
  80030d:	89 08                	mov    %ecx,(%eax)
  80030f:	8b 45 08             	mov    0x8(%ebp),%eax
  800312:	88 02                	mov    %al,(%edx)
}
  800314:	5d                   	pop    %ebp
  800315:	c3                   	ret    

00800316 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800316:	55                   	push   %ebp
  800317:	89 e5                	mov    %esp,%ebp
  800319:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80031c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80031f:	50                   	push   %eax
  800320:	ff 75 10             	pushl  0x10(%ebp)
  800323:	ff 75 0c             	pushl  0xc(%ebp)
  800326:	ff 75 08             	pushl  0x8(%ebp)
  800329:	e8 05 00 00 00       	call   800333 <vprintfmt>
	va_end(ap);
}
  80032e:	83 c4 10             	add    $0x10,%esp
  800331:	c9                   	leave  
  800332:	c3                   	ret    

00800333 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800333:	55                   	push   %ebp
  800334:	89 e5                	mov    %esp,%ebp
  800336:	57                   	push   %edi
  800337:	56                   	push   %esi
  800338:	53                   	push   %ebx
  800339:	83 ec 2c             	sub    $0x2c,%esp
  80033c:	8b 75 08             	mov    0x8(%ebp),%esi
  80033f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800342:	8b 7d 10             	mov    0x10(%ebp),%edi
  800345:	eb 12                	jmp    800359 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800347:	85 c0                	test   %eax,%eax
  800349:	0f 84 89 03 00 00    	je     8006d8 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  80034f:	83 ec 08             	sub    $0x8,%esp
  800352:	53                   	push   %ebx
  800353:	50                   	push   %eax
  800354:	ff d6                	call   *%esi
  800356:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800359:	83 c7 01             	add    $0x1,%edi
  80035c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800360:	83 f8 25             	cmp    $0x25,%eax
  800363:	75 e2                	jne    800347 <vprintfmt+0x14>
  800365:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800369:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800370:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800377:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80037e:	ba 00 00 00 00       	mov    $0x0,%edx
  800383:	eb 07                	jmp    80038c <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800385:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  800388:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80038c:	8d 47 01             	lea    0x1(%edi),%eax
  80038f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800392:	0f b6 07             	movzbl (%edi),%eax
  800395:	0f b6 c8             	movzbl %al,%ecx
  800398:	83 e8 23             	sub    $0x23,%eax
  80039b:	3c 55                	cmp    $0x55,%al
  80039d:	0f 87 1a 03 00 00    	ja     8006bd <vprintfmt+0x38a>
  8003a3:	0f b6 c0             	movzbl %al,%eax
  8003a6:	ff 24 85 60 0e 80 00 	jmp    *0x800e60(,%eax,4)
  8003ad:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003b0:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003b4:	eb d6                	jmp    80038c <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003b9:	b8 00 00 00 00       	mov    $0x0,%eax
  8003be:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003c1:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003c4:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  8003c8:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  8003cb:	8d 51 d0             	lea    -0x30(%ecx),%edx
  8003ce:	83 fa 09             	cmp    $0x9,%edx
  8003d1:	77 39                	ja     80040c <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003d3:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003d6:	eb e9                	jmp    8003c1 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003d8:	8b 45 14             	mov    0x14(%ebp),%eax
  8003db:	8d 48 04             	lea    0x4(%eax),%ecx
  8003de:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003e1:	8b 00                	mov    (%eax),%eax
  8003e3:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003e6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003e9:	eb 27                	jmp    800412 <vprintfmt+0xdf>
  8003eb:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003ee:	85 c0                	test   %eax,%eax
  8003f0:	b9 00 00 00 00       	mov    $0x0,%ecx
  8003f5:	0f 49 c8             	cmovns %eax,%ecx
  8003f8:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003fb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003fe:	eb 8c                	jmp    80038c <vprintfmt+0x59>
  800400:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800403:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80040a:	eb 80                	jmp    80038c <vprintfmt+0x59>
  80040c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80040f:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800412:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800416:	0f 89 70 ff ff ff    	jns    80038c <vprintfmt+0x59>
				width = precision, precision = -1;
  80041c:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80041f:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800422:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800429:	e9 5e ff ff ff       	jmp    80038c <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80042e:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800431:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800434:	e9 53 ff ff ff       	jmp    80038c <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800439:	8b 45 14             	mov    0x14(%ebp),%eax
  80043c:	8d 50 04             	lea    0x4(%eax),%edx
  80043f:	89 55 14             	mov    %edx,0x14(%ebp)
  800442:	83 ec 08             	sub    $0x8,%esp
  800445:	53                   	push   %ebx
  800446:	ff 30                	pushl  (%eax)
  800448:	ff d6                	call   *%esi
			break;
  80044a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80044d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800450:	e9 04 ff ff ff       	jmp    800359 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800455:	8b 45 14             	mov    0x14(%ebp),%eax
  800458:	8d 50 04             	lea    0x4(%eax),%edx
  80045b:	89 55 14             	mov    %edx,0x14(%ebp)
  80045e:	8b 00                	mov    (%eax),%eax
  800460:	99                   	cltd   
  800461:	31 d0                	xor    %edx,%eax
  800463:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800465:	83 f8 07             	cmp    $0x7,%eax
  800468:	7f 0b                	jg     800475 <vprintfmt+0x142>
  80046a:	8b 14 85 c0 0f 80 00 	mov    0x800fc0(,%eax,4),%edx
  800471:	85 d2                	test   %edx,%edx
  800473:	75 18                	jne    80048d <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800475:	50                   	push   %eax
  800476:	68 d6 0d 80 00       	push   $0x800dd6
  80047b:	53                   	push   %ebx
  80047c:	56                   	push   %esi
  80047d:	e8 94 fe ff ff       	call   800316 <printfmt>
  800482:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800485:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  800488:	e9 cc fe ff ff       	jmp    800359 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  80048d:	52                   	push   %edx
  80048e:	68 df 0d 80 00       	push   $0x800ddf
  800493:	53                   	push   %ebx
  800494:	56                   	push   %esi
  800495:	e8 7c fe ff ff       	call   800316 <printfmt>
  80049a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80049d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004a0:	e9 b4 fe ff ff       	jmp    800359 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004a5:	8b 45 14             	mov    0x14(%ebp),%eax
  8004a8:	8d 50 04             	lea    0x4(%eax),%edx
  8004ab:	89 55 14             	mov    %edx,0x14(%ebp)
  8004ae:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004b0:	85 ff                	test   %edi,%edi
  8004b2:	b8 cf 0d 80 00       	mov    $0x800dcf,%eax
  8004b7:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004ba:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004be:	0f 8e 94 00 00 00    	jle    800558 <vprintfmt+0x225>
  8004c4:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004c8:	0f 84 98 00 00 00    	je     800566 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004ce:	83 ec 08             	sub    $0x8,%esp
  8004d1:	ff 75 d0             	pushl  -0x30(%ebp)
  8004d4:	57                   	push   %edi
  8004d5:	e8 86 02 00 00       	call   800760 <strnlen>
  8004da:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004dd:	29 c1                	sub    %eax,%ecx
  8004df:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  8004e2:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8004e5:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8004e9:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004ec:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8004ef:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004f1:	eb 0f                	jmp    800502 <vprintfmt+0x1cf>
					putch(padc, putdat);
  8004f3:	83 ec 08             	sub    $0x8,%esp
  8004f6:	53                   	push   %ebx
  8004f7:	ff 75 e0             	pushl  -0x20(%ebp)
  8004fa:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004fc:	83 ef 01             	sub    $0x1,%edi
  8004ff:	83 c4 10             	add    $0x10,%esp
  800502:	85 ff                	test   %edi,%edi
  800504:	7f ed                	jg     8004f3 <vprintfmt+0x1c0>
  800506:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800509:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80050c:	85 c9                	test   %ecx,%ecx
  80050e:	b8 00 00 00 00       	mov    $0x0,%eax
  800513:	0f 49 c1             	cmovns %ecx,%eax
  800516:	29 c1                	sub    %eax,%ecx
  800518:	89 75 08             	mov    %esi,0x8(%ebp)
  80051b:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80051e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800521:	89 cb                	mov    %ecx,%ebx
  800523:	eb 4d                	jmp    800572 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800525:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800529:	74 1b                	je     800546 <vprintfmt+0x213>
  80052b:	0f be c0             	movsbl %al,%eax
  80052e:	83 e8 20             	sub    $0x20,%eax
  800531:	83 f8 5e             	cmp    $0x5e,%eax
  800534:	76 10                	jbe    800546 <vprintfmt+0x213>
					putch('?', putdat);
  800536:	83 ec 08             	sub    $0x8,%esp
  800539:	ff 75 0c             	pushl  0xc(%ebp)
  80053c:	6a 3f                	push   $0x3f
  80053e:	ff 55 08             	call   *0x8(%ebp)
  800541:	83 c4 10             	add    $0x10,%esp
  800544:	eb 0d                	jmp    800553 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800546:	83 ec 08             	sub    $0x8,%esp
  800549:	ff 75 0c             	pushl  0xc(%ebp)
  80054c:	52                   	push   %edx
  80054d:	ff 55 08             	call   *0x8(%ebp)
  800550:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800553:	83 eb 01             	sub    $0x1,%ebx
  800556:	eb 1a                	jmp    800572 <vprintfmt+0x23f>
  800558:	89 75 08             	mov    %esi,0x8(%ebp)
  80055b:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80055e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800561:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800564:	eb 0c                	jmp    800572 <vprintfmt+0x23f>
  800566:	89 75 08             	mov    %esi,0x8(%ebp)
  800569:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80056c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80056f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800572:	83 c7 01             	add    $0x1,%edi
  800575:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800579:	0f be d0             	movsbl %al,%edx
  80057c:	85 d2                	test   %edx,%edx
  80057e:	74 23                	je     8005a3 <vprintfmt+0x270>
  800580:	85 f6                	test   %esi,%esi
  800582:	78 a1                	js     800525 <vprintfmt+0x1f2>
  800584:	83 ee 01             	sub    $0x1,%esi
  800587:	79 9c                	jns    800525 <vprintfmt+0x1f2>
  800589:	89 df                	mov    %ebx,%edi
  80058b:	8b 75 08             	mov    0x8(%ebp),%esi
  80058e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800591:	eb 18                	jmp    8005ab <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800593:	83 ec 08             	sub    $0x8,%esp
  800596:	53                   	push   %ebx
  800597:	6a 20                	push   $0x20
  800599:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80059b:	83 ef 01             	sub    $0x1,%edi
  80059e:	83 c4 10             	add    $0x10,%esp
  8005a1:	eb 08                	jmp    8005ab <vprintfmt+0x278>
  8005a3:	89 df                	mov    %ebx,%edi
  8005a5:	8b 75 08             	mov    0x8(%ebp),%esi
  8005a8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005ab:	85 ff                	test   %edi,%edi
  8005ad:	7f e4                	jg     800593 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005af:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005b2:	e9 a2 fd ff ff       	jmp    800359 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005b7:	83 fa 01             	cmp    $0x1,%edx
  8005ba:	7e 16                	jle    8005d2 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  8005bc:	8b 45 14             	mov    0x14(%ebp),%eax
  8005bf:	8d 50 08             	lea    0x8(%eax),%edx
  8005c2:	89 55 14             	mov    %edx,0x14(%ebp)
  8005c5:	8b 50 04             	mov    0x4(%eax),%edx
  8005c8:	8b 00                	mov    (%eax),%eax
  8005ca:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005cd:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005d0:	eb 32                	jmp    800604 <vprintfmt+0x2d1>
	else if (lflag)
  8005d2:	85 d2                	test   %edx,%edx
  8005d4:	74 18                	je     8005ee <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  8005d6:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d9:	8d 50 04             	lea    0x4(%eax),%edx
  8005dc:	89 55 14             	mov    %edx,0x14(%ebp)
  8005df:	8b 00                	mov    (%eax),%eax
  8005e1:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005e4:	89 c1                	mov    %eax,%ecx
  8005e6:	c1 f9 1f             	sar    $0x1f,%ecx
  8005e9:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8005ec:	eb 16                	jmp    800604 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  8005ee:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f1:	8d 50 04             	lea    0x4(%eax),%edx
  8005f4:	89 55 14             	mov    %edx,0x14(%ebp)
  8005f7:	8b 00                	mov    (%eax),%eax
  8005f9:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005fc:	89 c1                	mov    %eax,%ecx
  8005fe:	c1 f9 1f             	sar    $0x1f,%ecx
  800601:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800604:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800607:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80060a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80060f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800613:	79 74                	jns    800689 <vprintfmt+0x356>
				putch('-', putdat);
  800615:	83 ec 08             	sub    $0x8,%esp
  800618:	53                   	push   %ebx
  800619:	6a 2d                	push   $0x2d
  80061b:	ff d6                	call   *%esi
				num = -(long long) num;
  80061d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800620:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800623:	f7 d8                	neg    %eax
  800625:	83 d2 00             	adc    $0x0,%edx
  800628:	f7 da                	neg    %edx
  80062a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80062d:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800632:	eb 55                	jmp    800689 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800634:	8d 45 14             	lea    0x14(%ebp),%eax
  800637:	e8 83 fc ff ff       	call   8002bf <getuint>
			base = 10;
  80063c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800641:	eb 46                	jmp    800689 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800643:	8d 45 14             	lea    0x14(%ebp),%eax
  800646:	e8 74 fc ff ff       	call   8002bf <getuint>
			base = 8;
  80064b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800650:	eb 37                	jmp    800689 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  800652:	83 ec 08             	sub    $0x8,%esp
  800655:	53                   	push   %ebx
  800656:	6a 30                	push   $0x30
  800658:	ff d6                	call   *%esi
			putch('x', putdat);
  80065a:	83 c4 08             	add    $0x8,%esp
  80065d:	53                   	push   %ebx
  80065e:	6a 78                	push   $0x78
  800660:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800662:	8b 45 14             	mov    0x14(%ebp),%eax
  800665:	8d 50 04             	lea    0x4(%eax),%edx
  800668:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80066b:	8b 00                	mov    (%eax),%eax
  80066d:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800672:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800675:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  80067a:	eb 0d                	jmp    800689 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  80067c:	8d 45 14             	lea    0x14(%ebp),%eax
  80067f:	e8 3b fc ff ff       	call   8002bf <getuint>
			base = 16;
  800684:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800689:	83 ec 0c             	sub    $0xc,%esp
  80068c:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800690:	57                   	push   %edi
  800691:	ff 75 e0             	pushl  -0x20(%ebp)
  800694:	51                   	push   %ecx
  800695:	52                   	push   %edx
  800696:	50                   	push   %eax
  800697:	89 da                	mov    %ebx,%edx
  800699:	89 f0                	mov    %esi,%eax
  80069b:	e8 70 fb ff ff       	call   800210 <printnum>
			break;
  8006a0:	83 c4 20             	add    $0x20,%esp
  8006a3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006a6:	e9 ae fc ff ff       	jmp    800359 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006ab:	83 ec 08             	sub    $0x8,%esp
  8006ae:	53                   	push   %ebx
  8006af:	51                   	push   %ecx
  8006b0:	ff d6                	call   *%esi
			break;
  8006b2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006b5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006b8:	e9 9c fc ff ff       	jmp    800359 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006bd:	83 ec 08             	sub    $0x8,%esp
  8006c0:	53                   	push   %ebx
  8006c1:	6a 25                	push   $0x25
  8006c3:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006c5:	83 c4 10             	add    $0x10,%esp
  8006c8:	eb 03                	jmp    8006cd <vprintfmt+0x39a>
  8006ca:	83 ef 01             	sub    $0x1,%edi
  8006cd:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006d1:	75 f7                	jne    8006ca <vprintfmt+0x397>
  8006d3:	e9 81 fc ff ff       	jmp    800359 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006d8:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006db:	5b                   	pop    %ebx
  8006dc:	5e                   	pop    %esi
  8006dd:	5f                   	pop    %edi
  8006de:	5d                   	pop    %ebp
  8006df:	c3                   	ret    

008006e0 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006e0:	55                   	push   %ebp
  8006e1:	89 e5                	mov    %esp,%ebp
  8006e3:	83 ec 18             	sub    $0x18,%esp
  8006e6:	8b 45 08             	mov    0x8(%ebp),%eax
  8006e9:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006ec:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006ef:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006f3:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006f6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006fd:	85 c0                	test   %eax,%eax
  8006ff:	74 26                	je     800727 <vsnprintf+0x47>
  800701:	85 d2                	test   %edx,%edx
  800703:	7e 22                	jle    800727 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800705:	ff 75 14             	pushl  0x14(%ebp)
  800708:	ff 75 10             	pushl  0x10(%ebp)
  80070b:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80070e:	50                   	push   %eax
  80070f:	68 f9 02 80 00       	push   $0x8002f9
  800714:	e8 1a fc ff ff       	call   800333 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800719:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80071c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80071f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800722:	83 c4 10             	add    $0x10,%esp
  800725:	eb 05                	jmp    80072c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800727:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80072c:	c9                   	leave  
  80072d:	c3                   	ret    

0080072e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80072e:	55                   	push   %ebp
  80072f:	89 e5                	mov    %esp,%ebp
  800731:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800734:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800737:	50                   	push   %eax
  800738:	ff 75 10             	pushl  0x10(%ebp)
  80073b:	ff 75 0c             	pushl  0xc(%ebp)
  80073e:	ff 75 08             	pushl  0x8(%ebp)
  800741:	e8 9a ff ff ff       	call   8006e0 <vsnprintf>
	va_end(ap);

	return rc;
}
  800746:	c9                   	leave  
  800747:	c3                   	ret    

00800748 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800748:	55                   	push   %ebp
  800749:	89 e5                	mov    %esp,%ebp
  80074b:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80074e:	b8 00 00 00 00       	mov    $0x0,%eax
  800753:	eb 03                	jmp    800758 <strlen+0x10>
		n++;
  800755:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800758:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80075c:	75 f7                	jne    800755 <strlen+0xd>
		n++;
	return n;
}
  80075e:	5d                   	pop    %ebp
  80075f:	c3                   	ret    

00800760 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800760:	55                   	push   %ebp
  800761:	89 e5                	mov    %esp,%ebp
  800763:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800766:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800769:	ba 00 00 00 00       	mov    $0x0,%edx
  80076e:	eb 03                	jmp    800773 <strnlen+0x13>
		n++;
  800770:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800773:	39 c2                	cmp    %eax,%edx
  800775:	74 08                	je     80077f <strnlen+0x1f>
  800777:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80077b:	75 f3                	jne    800770 <strnlen+0x10>
  80077d:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80077f:	5d                   	pop    %ebp
  800780:	c3                   	ret    

00800781 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800781:	55                   	push   %ebp
  800782:	89 e5                	mov    %esp,%ebp
  800784:	53                   	push   %ebx
  800785:	8b 45 08             	mov    0x8(%ebp),%eax
  800788:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80078b:	89 c2                	mov    %eax,%edx
  80078d:	83 c2 01             	add    $0x1,%edx
  800790:	83 c1 01             	add    $0x1,%ecx
  800793:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800797:	88 5a ff             	mov    %bl,-0x1(%edx)
  80079a:	84 db                	test   %bl,%bl
  80079c:	75 ef                	jne    80078d <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  80079e:	5b                   	pop    %ebx
  80079f:	5d                   	pop    %ebp
  8007a0:	c3                   	ret    

008007a1 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007a1:	55                   	push   %ebp
  8007a2:	89 e5                	mov    %esp,%ebp
  8007a4:	53                   	push   %ebx
  8007a5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007a8:	53                   	push   %ebx
  8007a9:	e8 9a ff ff ff       	call   800748 <strlen>
  8007ae:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007b1:	ff 75 0c             	pushl  0xc(%ebp)
  8007b4:	01 d8                	add    %ebx,%eax
  8007b6:	50                   	push   %eax
  8007b7:	e8 c5 ff ff ff       	call   800781 <strcpy>
	return dst;
}
  8007bc:	89 d8                	mov    %ebx,%eax
  8007be:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007c1:	c9                   	leave  
  8007c2:	c3                   	ret    

008007c3 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007c3:	55                   	push   %ebp
  8007c4:	89 e5                	mov    %esp,%ebp
  8007c6:	56                   	push   %esi
  8007c7:	53                   	push   %ebx
  8007c8:	8b 75 08             	mov    0x8(%ebp),%esi
  8007cb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007ce:	89 f3                	mov    %esi,%ebx
  8007d0:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007d3:	89 f2                	mov    %esi,%edx
  8007d5:	eb 0f                	jmp    8007e6 <strncpy+0x23>
		*dst++ = *src;
  8007d7:	83 c2 01             	add    $0x1,%edx
  8007da:	0f b6 01             	movzbl (%ecx),%eax
  8007dd:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007e0:	80 39 01             	cmpb   $0x1,(%ecx)
  8007e3:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007e6:	39 da                	cmp    %ebx,%edx
  8007e8:	75 ed                	jne    8007d7 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007ea:	89 f0                	mov    %esi,%eax
  8007ec:	5b                   	pop    %ebx
  8007ed:	5e                   	pop    %esi
  8007ee:	5d                   	pop    %ebp
  8007ef:	c3                   	ret    

008007f0 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007f0:	55                   	push   %ebp
  8007f1:	89 e5                	mov    %esp,%ebp
  8007f3:	56                   	push   %esi
  8007f4:	53                   	push   %ebx
  8007f5:	8b 75 08             	mov    0x8(%ebp),%esi
  8007f8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007fb:	8b 55 10             	mov    0x10(%ebp),%edx
  8007fe:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800800:	85 d2                	test   %edx,%edx
  800802:	74 21                	je     800825 <strlcpy+0x35>
  800804:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800808:	89 f2                	mov    %esi,%edx
  80080a:	eb 09                	jmp    800815 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80080c:	83 c2 01             	add    $0x1,%edx
  80080f:	83 c1 01             	add    $0x1,%ecx
  800812:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800815:	39 c2                	cmp    %eax,%edx
  800817:	74 09                	je     800822 <strlcpy+0x32>
  800819:	0f b6 19             	movzbl (%ecx),%ebx
  80081c:	84 db                	test   %bl,%bl
  80081e:	75 ec                	jne    80080c <strlcpy+0x1c>
  800820:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800822:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800825:	29 f0                	sub    %esi,%eax
}
  800827:	5b                   	pop    %ebx
  800828:	5e                   	pop    %esi
  800829:	5d                   	pop    %ebp
  80082a:	c3                   	ret    

0080082b <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80082b:	55                   	push   %ebp
  80082c:	89 e5                	mov    %esp,%ebp
  80082e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800831:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800834:	eb 06                	jmp    80083c <strcmp+0x11>
		p++, q++;
  800836:	83 c1 01             	add    $0x1,%ecx
  800839:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80083c:	0f b6 01             	movzbl (%ecx),%eax
  80083f:	84 c0                	test   %al,%al
  800841:	74 04                	je     800847 <strcmp+0x1c>
  800843:	3a 02                	cmp    (%edx),%al
  800845:	74 ef                	je     800836 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800847:	0f b6 c0             	movzbl %al,%eax
  80084a:	0f b6 12             	movzbl (%edx),%edx
  80084d:	29 d0                	sub    %edx,%eax
}
  80084f:	5d                   	pop    %ebp
  800850:	c3                   	ret    

00800851 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800851:	55                   	push   %ebp
  800852:	89 e5                	mov    %esp,%ebp
  800854:	53                   	push   %ebx
  800855:	8b 45 08             	mov    0x8(%ebp),%eax
  800858:	8b 55 0c             	mov    0xc(%ebp),%edx
  80085b:	89 c3                	mov    %eax,%ebx
  80085d:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800860:	eb 06                	jmp    800868 <strncmp+0x17>
		n--, p++, q++;
  800862:	83 c0 01             	add    $0x1,%eax
  800865:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800868:	39 d8                	cmp    %ebx,%eax
  80086a:	74 15                	je     800881 <strncmp+0x30>
  80086c:	0f b6 08             	movzbl (%eax),%ecx
  80086f:	84 c9                	test   %cl,%cl
  800871:	74 04                	je     800877 <strncmp+0x26>
  800873:	3a 0a                	cmp    (%edx),%cl
  800875:	74 eb                	je     800862 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800877:	0f b6 00             	movzbl (%eax),%eax
  80087a:	0f b6 12             	movzbl (%edx),%edx
  80087d:	29 d0                	sub    %edx,%eax
  80087f:	eb 05                	jmp    800886 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800881:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800886:	5b                   	pop    %ebx
  800887:	5d                   	pop    %ebp
  800888:	c3                   	ret    

00800889 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800889:	55                   	push   %ebp
  80088a:	89 e5                	mov    %esp,%ebp
  80088c:	8b 45 08             	mov    0x8(%ebp),%eax
  80088f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800893:	eb 07                	jmp    80089c <strchr+0x13>
		if (*s == c)
  800895:	38 ca                	cmp    %cl,%dl
  800897:	74 0f                	je     8008a8 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800899:	83 c0 01             	add    $0x1,%eax
  80089c:	0f b6 10             	movzbl (%eax),%edx
  80089f:	84 d2                	test   %dl,%dl
  8008a1:	75 f2                	jne    800895 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008a3:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008a8:	5d                   	pop    %ebp
  8008a9:	c3                   	ret    

008008aa <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008aa:	55                   	push   %ebp
  8008ab:	89 e5                	mov    %esp,%ebp
  8008ad:	8b 45 08             	mov    0x8(%ebp),%eax
  8008b0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008b4:	eb 03                	jmp    8008b9 <strfind+0xf>
  8008b6:	83 c0 01             	add    $0x1,%eax
  8008b9:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008bc:	38 ca                	cmp    %cl,%dl
  8008be:	74 04                	je     8008c4 <strfind+0x1a>
  8008c0:	84 d2                	test   %dl,%dl
  8008c2:	75 f2                	jne    8008b6 <strfind+0xc>
			break;
	return (char *) s;
}
  8008c4:	5d                   	pop    %ebp
  8008c5:	c3                   	ret    

008008c6 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008c6:	55                   	push   %ebp
  8008c7:	89 e5                	mov    %esp,%ebp
  8008c9:	57                   	push   %edi
  8008ca:	56                   	push   %esi
  8008cb:	53                   	push   %ebx
  8008cc:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008cf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008d2:	85 c9                	test   %ecx,%ecx
  8008d4:	74 36                	je     80090c <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008d6:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008dc:	75 28                	jne    800906 <memset+0x40>
  8008de:	f6 c1 03             	test   $0x3,%cl
  8008e1:	75 23                	jne    800906 <memset+0x40>
		c &= 0xFF;
  8008e3:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008e7:	89 d3                	mov    %edx,%ebx
  8008e9:	c1 e3 08             	shl    $0x8,%ebx
  8008ec:	89 d6                	mov    %edx,%esi
  8008ee:	c1 e6 18             	shl    $0x18,%esi
  8008f1:	89 d0                	mov    %edx,%eax
  8008f3:	c1 e0 10             	shl    $0x10,%eax
  8008f6:	09 f0                	or     %esi,%eax
  8008f8:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  8008fa:	89 d8                	mov    %ebx,%eax
  8008fc:	09 d0                	or     %edx,%eax
  8008fe:	c1 e9 02             	shr    $0x2,%ecx
  800901:	fc                   	cld    
  800902:	f3 ab                	rep stos %eax,%es:(%edi)
  800904:	eb 06                	jmp    80090c <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800906:	8b 45 0c             	mov    0xc(%ebp),%eax
  800909:	fc                   	cld    
  80090a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80090c:	89 f8                	mov    %edi,%eax
  80090e:	5b                   	pop    %ebx
  80090f:	5e                   	pop    %esi
  800910:	5f                   	pop    %edi
  800911:	5d                   	pop    %ebp
  800912:	c3                   	ret    

00800913 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800913:	55                   	push   %ebp
  800914:	89 e5                	mov    %esp,%ebp
  800916:	57                   	push   %edi
  800917:	56                   	push   %esi
  800918:	8b 45 08             	mov    0x8(%ebp),%eax
  80091b:	8b 75 0c             	mov    0xc(%ebp),%esi
  80091e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800921:	39 c6                	cmp    %eax,%esi
  800923:	73 35                	jae    80095a <memmove+0x47>
  800925:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800928:	39 d0                	cmp    %edx,%eax
  80092a:	73 2e                	jae    80095a <memmove+0x47>
		s += n;
		d += n;
  80092c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80092f:	89 d6                	mov    %edx,%esi
  800931:	09 fe                	or     %edi,%esi
  800933:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800939:	75 13                	jne    80094e <memmove+0x3b>
  80093b:	f6 c1 03             	test   $0x3,%cl
  80093e:	75 0e                	jne    80094e <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800940:	83 ef 04             	sub    $0x4,%edi
  800943:	8d 72 fc             	lea    -0x4(%edx),%esi
  800946:	c1 e9 02             	shr    $0x2,%ecx
  800949:	fd                   	std    
  80094a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80094c:	eb 09                	jmp    800957 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80094e:	83 ef 01             	sub    $0x1,%edi
  800951:	8d 72 ff             	lea    -0x1(%edx),%esi
  800954:	fd                   	std    
  800955:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800957:	fc                   	cld    
  800958:	eb 1d                	jmp    800977 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80095a:	89 f2                	mov    %esi,%edx
  80095c:	09 c2                	or     %eax,%edx
  80095e:	f6 c2 03             	test   $0x3,%dl
  800961:	75 0f                	jne    800972 <memmove+0x5f>
  800963:	f6 c1 03             	test   $0x3,%cl
  800966:	75 0a                	jne    800972 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800968:	c1 e9 02             	shr    $0x2,%ecx
  80096b:	89 c7                	mov    %eax,%edi
  80096d:	fc                   	cld    
  80096e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800970:	eb 05                	jmp    800977 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800972:	89 c7                	mov    %eax,%edi
  800974:	fc                   	cld    
  800975:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800977:	5e                   	pop    %esi
  800978:	5f                   	pop    %edi
  800979:	5d                   	pop    %ebp
  80097a:	c3                   	ret    

0080097b <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80097b:	55                   	push   %ebp
  80097c:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  80097e:	ff 75 10             	pushl  0x10(%ebp)
  800981:	ff 75 0c             	pushl  0xc(%ebp)
  800984:	ff 75 08             	pushl  0x8(%ebp)
  800987:	e8 87 ff ff ff       	call   800913 <memmove>
}
  80098c:	c9                   	leave  
  80098d:	c3                   	ret    

0080098e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80098e:	55                   	push   %ebp
  80098f:	89 e5                	mov    %esp,%ebp
  800991:	56                   	push   %esi
  800992:	53                   	push   %ebx
  800993:	8b 45 08             	mov    0x8(%ebp),%eax
  800996:	8b 55 0c             	mov    0xc(%ebp),%edx
  800999:	89 c6                	mov    %eax,%esi
  80099b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80099e:	eb 1a                	jmp    8009ba <memcmp+0x2c>
		if (*s1 != *s2)
  8009a0:	0f b6 08             	movzbl (%eax),%ecx
  8009a3:	0f b6 1a             	movzbl (%edx),%ebx
  8009a6:	38 d9                	cmp    %bl,%cl
  8009a8:	74 0a                	je     8009b4 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009aa:	0f b6 c1             	movzbl %cl,%eax
  8009ad:	0f b6 db             	movzbl %bl,%ebx
  8009b0:	29 d8                	sub    %ebx,%eax
  8009b2:	eb 0f                	jmp    8009c3 <memcmp+0x35>
		s1++, s2++;
  8009b4:	83 c0 01             	add    $0x1,%eax
  8009b7:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009ba:	39 f0                	cmp    %esi,%eax
  8009bc:	75 e2                	jne    8009a0 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009be:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009c3:	5b                   	pop    %ebx
  8009c4:	5e                   	pop    %esi
  8009c5:	5d                   	pop    %ebp
  8009c6:	c3                   	ret    

008009c7 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009c7:	55                   	push   %ebp
  8009c8:	89 e5                	mov    %esp,%ebp
  8009ca:	53                   	push   %ebx
  8009cb:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009ce:	89 c1                	mov    %eax,%ecx
  8009d0:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009d3:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009d7:	eb 0a                	jmp    8009e3 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009d9:	0f b6 10             	movzbl (%eax),%edx
  8009dc:	39 da                	cmp    %ebx,%edx
  8009de:	74 07                	je     8009e7 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009e0:	83 c0 01             	add    $0x1,%eax
  8009e3:	39 c8                	cmp    %ecx,%eax
  8009e5:	72 f2                	jb     8009d9 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009e7:	5b                   	pop    %ebx
  8009e8:	5d                   	pop    %ebp
  8009e9:	c3                   	ret    

008009ea <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009ea:	55                   	push   %ebp
  8009eb:	89 e5                	mov    %esp,%ebp
  8009ed:	57                   	push   %edi
  8009ee:	56                   	push   %esi
  8009ef:	53                   	push   %ebx
  8009f0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009f3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009f6:	eb 03                	jmp    8009fb <strtol+0x11>
		s++;
  8009f8:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009fb:	0f b6 01             	movzbl (%ecx),%eax
  8009fe:	3c 20                	cmp    $0x20,%al
  800a00:	74 f6                	je     8009f8 <strtol+0xe>
  800a02:	3c 09                	cmp    $0x9,%al
  800a04:	74 f2                	je     8009f8 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a06:	3c 2b                	cmp    $0x2b,%al
  800a08:	75 0a                	jne    800a14 <strtol+0x2a>
		s++;
  800a0a:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a0d:	bf 00 00 00 00       	mov    $0x0,%edi
  800a12:	eb 11                	jmp    800a25 <strtol+0x3b>
  800a14:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a19:	3c 2d                	cmp    $0x2d,%al
  800a1b:	75 08                	jne    800a25 <strtol+0x3b>
		s++, neg = 1;
  800a1d:	83 c1 01             	add    $0x1,%ecx
  800a20:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a25:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a2b:	75 15                	jne    800a42 <strtol+0x58>
  800a2d:	80 39 30             	cmpb   $0x30,(%ecx)
  800a30:	75 10                	jne    800a42 <strtol+0x58>
  800a32:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a36:	75 7c                	jne    800ab4 <strtol+0xca>
		s += 2, base = 16;
  800a38:	83 c1 02             	add    $0x2,%ecx
  800a3b:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a40:	eb 16                	jmp    800a58 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a42:	85 db                	test   %ebx,%ebx
  800a44:	75 12                	jne    800a58 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a46:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a4b:	80 39 30             	cmpb   $0x30,(%ecx)
  800a4e:	75 08                	jne    800a58 <strtol+0x6e>
		s++, base = 8;
  800a50:	83 c1 01             	add    $0x1,%ecx
  800a53:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a58:	b8 00 00 00 00       	mov    $0x0,%eax
  800a5d:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a60:	0f b6 11             	movzbl (%ecx),%edx
  800a63:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a66:	89 f3                	mov    %esi,%ebx
  800a68:	80 fb 09             	cmp    $0x9,%bl
  800a6b:	77 08                	ja     800a75 <strtol+0x8b>
			dig = *s - '0';
  800a6d:	0f be d2             	movsbl %dl,%edx
  800a70:	83 ea 30             	sub    $0x30,%edx
  800a73:	eb 22                	jmp    800a97 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a75:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a78:	89 f3                	mov    %esi,%ebx
  800a7a:	80 fb 19             	cmp    $0x19,%bl
  800a7d:	77 08                	ja     800a87 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a7f:	0f be d2             	movsbl %dl,%edx
  800a82:	83 ea 57             	sub    $0x57,%edx
  800a85:	eb 10                	jmp    800a97 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a87:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a8a:	89 f3                	mov    %esi,%ebx
  800a8c:	80 fb 19             	cmp    $0x19,%bl
  800a8f:	77 16                	ja     800aa7 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a91:	0f be d2             	movsbl %dl,%edx
  800a94:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a97:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a9a:	7d 0b                	jge    800aa7 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a9c:	83 c1 01             	add    $0x1,%ecx
  800a9f:	0f af 45 10          	imul   0x10(%ebp),%eax
  800aa3:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800aa5:	eb b9                	jmp    800a60 <strtol+0x76>

	if (endptr)
  800aa7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800aab:	74 0d                	je     800aba <strtol+0xd0>
		*endptr = (char *) s;
  800aad:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ab0:	89 0e                	mov    %ecx,(%esi)
  800ab2:	eb 06                	jmp    800aba <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ab4:	85 db                	test   %ebx,%ebx
  800ab6:	74 98                	je     800a50 <strtol+0x66>
  800ab8:	eb 9e                	jmp    800a58 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800aba:	89 c2                	mov    %eax,%edx
  800abc:	f7 da                	neg    %edx
  800abe:	85 ff                	test   %edi,%edi
  800ac0:	0f 45 c2             	cmovne %edx,%eax
}
  800ac3:	5b                   	pop    %ebx
  800ac4:	5e                   	pop    %esi
  800ac5:	5f                   	pop    %edi
  800ac6:	5d                   	pop    %ebp
  800ac7:	c3                   	ret    
  800ac8:	66 90                	xchg   %ax,%ax
  800aca:	66 90                	xchg   %ax,%ax
  800acc:	66 90                	xchg   %ax,%ax
  800ace:	66 90                	xchg   %ax,%ax

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

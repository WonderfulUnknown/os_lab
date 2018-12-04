
obj/user/buggyhello2：     文件格式 elf32-i386


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

const char *hello = "hello, world\n";

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 10             	sub    $0x10,%esp
	sys_cputs(hello, 1024*1024);
  800039:	68 00 00 10 00       	push   $0x100000
  80003e:	ff 35 00 10 80 00    	pushl  0x801000
  800044:	e8 60 00 00 00       	call   8000a9 <sys_cputs>
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
  800059:	e8 c9 00 00 00       	call   800127 <sys_getenvid>
	thisenv = &envs[ENVX(id)];
  80005e:	25 ff 03 00 00       	and    $0x3ff,%eax
  800063:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800066:	c1 e0 05             	shl    $0x5,%eax
  800069:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80006e:	a3 08 10 80 00       	mov    %eax,0x801008
	// save the name of the program so that panic() can use it
	if (argc > 0)
  800073:	85 db                	test   %ebx,%ebx
  800075:	7e 07                	jle    80007e <libmain+0x30>
		binaryname = argv[0];
  800077:	8b 06                	mov    (%esi),%eax
  800079:	a3 04 10 80 00       	mov    %eax,0x801004

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
  80009f:	e8 42 00 00 00       	call   8000e6 <sys_env_destroy>
}
  8000a4:	83 c4 10             	add    $0x10,%esp
  8000a7:	c9                   	leave  
  8000a8:	c3                   	ret    

008000a9 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000a9:	55                   	push   %ebp
  8000aa:	89 e5                	mov    %esp,%ebp
  8000ac:	57                   	push   %edi
  8000ad:	56                   	push   %esi
  8000ae:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000af:	b8 00 00 00 00       	mov    $0x0,%eax
  8000b4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000b7:	8b 55 08             	mov    0x8(%ebp),%edx
  8000ba:	89 c3                	mov    %eax,%ebx
  8000bc:	89 c7                	mov    %eax,%edi
  8000be:	89 c6                	mov    %eax,%esi
  8000c0:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000c2:	5b                   	pop    %ebx
  8000c3:	5e                   	pop    %esi
  8000c4:	5f                   	pop    %edi
  8000c5:	5d                   	pop    %ebp
  8000c6:	c3                   	ret    

008000c7 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000c7:	55                   	push   %ebp
  8000c8:	89 e5                	mov    %esp,%ebp
  8000ca:	57                   	push   %edi
  8000cb:	56                   	push   %esi
  8000cc:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000cd:	ba 00 00 00 00       	mov    $0x0,%edx
  8000d2:	b8 01 00 00 00       	mov    $0x1,%eax
  8000d7:	89 d1                	mov    %edx,%ecx
  8000d9:	89 d3                	mov    %edx,%ebx
  8000db:	89 d7                	mov    %edx,%edi
  8000dd:	89 d6                	mov    %edx,%esi
  8000df:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000e1:	5b                   	pop    %ebx
  8000e2:	5e                   	pop    %esi
  8000e3:	5f                   	pop    %edi
  8000e4:	5d                   	pop    %ebp
  8000e5:	c3                   	ret    

008000e6 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000e6:	55                   	push   %ebp
  8000e7:	89 e5                	mov    %esp,%ebp
  8000e9:	57                   	push   %edi
  8000ea:	56                   	push   %esi
  8000eb:	53                   	push   %ebx
  8000ec:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000ef:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000f4:	b8 03 00 00 00       	mov    $0x3,%eax
  8000f9:	8b 55 08             	mov    0x8(%ebp),%edx
  8000fc:	89 cb                	mov    %ecx,%ebx
  8000fe:	89 cf                	mov    %ecx,%edi
  800100:	89 ce                	mov    %ecx,%esi
  800102:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800104:	85 c0                	test   %eax,%eax
  800106:	7e 17                	jle    80011f <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800108:	83 ec 0c             	sub    $0xc,%esp
  80010b:	50                   	push   %eax
  80010c:	6a 03                	push   $0x3
  80010e:	68 98 0d 80 00       	push   $0x800d98
  800113:	6a 23                	push   $0x23
  800115:	68 b5 0d 80 00       	push   $0x800db5
  80011a:	e8 27 00 00 00       	call   800146 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  80011f:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800122:	5b                   	pop    %ebx
  800123:	5e                   	pop    %esi
  800124:	5f                   	pop    %edi
  800125:	5d                   	pop    %ebp
  800126:	c3                   	ret    

00800127 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800127:	55                   	push   %ebp
  800128:	89 e5                	mov    %esp,%ebp
  80012a:	57                   	push   %edi
  80012b:	56                   	push   %esi
  80012c:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80012d:	ba 00 00 00 00       	mov    $0x0,%edx
  800132:	b8 02 00 00 00       	mov    $0x2,%eax
  800137:	89 d1                	mov    %edx,%ecx
  800139:	89 d3                	mov    %edx,%ebx
  80013b:	89 d7                	mov    %edx,%edi
  80013d:	89 d6                	mov    %edx,%esi
  80013f:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800141:	5b                   	pop    %ebx
  800142:	5e                   	pop    %esi
  800143:	5f                   	pop    %edi
  800144:	5d                   	pop    %ebp
  800145:	c3                   	ret    

00800146 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800146:	55                   	push   %ebp
  800147:	89 e5                	mov    %esp,%ebp
  800149:	56                   	push   %esi
  80014a:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  80014b:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80014e:	8b 35 04 10 80 00    	mov    0x801004,%esi
  800154:	e8 ce ff ff ff       	call   800127 <sys_getenvid>
  800159:	83 ec 0c             	sub    $0xc,%esp
  80015c:	ff 75 0c             	pushl  0xc(%ebp)
  80015f:	ff 75 08             	pushl  0x8(%ebp)
  800162:	56                   	push   %esi
  800163:	50                   	push   %eax
  800164:	68 c4 0d 80 00       	push   $0x800dc4
  800169:	e8 b1 00 00 00       	call   80021f <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80016e:	83 c4 18             	add    $0x18,%esp
  800171:	53                   	push   %ebx
  800172:	ff 75 10             	pushl  0x10(%ebp)
  800175:	e8 54 00 00 00       	call   8001ce <vcprintf>
	cprintf("\n");
  80017a:	c7 04 24 8c 0d 80 00 	movl   $0x800d8c,(%esp)
  800181:	e8 99 00 00 00       	call   80021f <cprintf>
  800186:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800189:	cc                   	int3   
  80018a:	eb fd                	jmp    800189 <_panic+0x43>

0080018c <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80018c:	55                   	push   %ebp
  80018d:	89 e5                	mov    %esp,%ebp
  80018f:	53                   	push   %ebx
  800190:	83 ec 04             	sub    $0x4,%esp
  800193:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800196:	8b 13                	mov    (%ebx),%edx
  800198:	8d 42 01             	lea    0x1(%edx),%eax
  80019b:	89 03                	mov    %eax,(%ebx)
  80019d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001a0:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001a4:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001a9:	75 1a                	jne    8001c5 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8001ab:	83 ec 08             	sub    $0x8,%esp
  8001ae:	68 ff 00 00 00       	push   $0xff
  8001b3:	8d 43 08             	lea    0x8(%ebx),%eax
  8001b6:	50                   	push   %eax
  8001b7:	e8 ed fe ff ff       	call   8000a9 <sys_cputs>
		b->idx = 0;
  8001bc:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001c2:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001c5:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001c9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001cc:	c9                   	leave  
  8001cd:	c3                   	ret    

008001ce <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001ce:	55                   	push   %ebp
  8001cf:	89 e5                	mov    %esp,%ebp
  8001d1:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001d7:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001de:	00 00 00 
	b.cnt = 0;
  8001e1:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001e8:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001eb:	ff 75 0c             	pushl  0xc(%ebp)
  8001ee:	ff 75 08             	pushl  0x8(%ebp)
  8001f1:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001f7:	50                   	push   %eax
  8001f8:	68 8c 01 80 00       	push   $0x80018c
  8001fd:	e8 54 01 00 00       	call   800356 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800202:	83 c4 08             	add    $0x8,%esp
  800205:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  80020b:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800211:	50                   	push   %eax
  800212:	e8 92 fe ff ff       	call   8000a9 <sys_cputs>

	return b.cnt;
}
  800217:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80021d:	c9                   	leave  
  80021e:	c3                   	ret    

0080021f <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80021f:	55                   	push   %ebp
  800220:	89 e5                	mov    %esp,%ebp
  800222:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800225:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800228:	50                   	push   %eax
  800229:	ff 75 08             	pushl  0x8(%ebp)
  80022c:	e8 9d ff ff ff       	call   8001ce <vcprintf>
	va_end(ap);

	return cnt;
}
  800231:	c9                   	leave  
  800232:	c3                   	ret    

00800233 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800233:	55                   	push   %ebp
  800234:	89 e5                	mov    %esp,%ebp
  800236:	57                   	push   %edi
  800237:	56                   	push   %esi
  800238:	53                   	push   %ebx
  800239:	83 ec 1c             	sub    $0x1c,%esp
  80023c:	89 c7                	mov    %eax,%edi
  80023e:	89 d6                	mov    %edx,%esi
  800240:	8b 45 08             	mov    0x8(%ebp),%eax
  800243:	8b 55 0c             	mov    0xc(%ebp),%edx
  800246:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800249:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80024c:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80024f:	bb 00 00 00 00       	mov    $0x0,%ebx
  800254:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800257:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80025a:	39 d3                	cmp    %edx,%ebx
  80025c:	72 05                	jb     800263 <printnum+0x30>
  80025e:	39 45 10             	cmp    %eax,0x10(%ebp)
  800261:	77 45                	ja     8002a8 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800263:	83 ec 0c             	sub    $0xc,%esp
  800266:	ff 75 18             	pushl  0x18(%ebp)
  800269:	8b 45 14             	mov    0x14(%ebp),%eax
  80026c:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80026f:	53                   	push   %ebx
  800270:	ff 75 10             	pushl  0x10(%ebp)
  800273:	83 ec 08             	sub    $0x8,%esp
  800276:	ff 75 e4             	pushl  -0x1c(%ebp)
  800279:	ff 75 e0             	pushl  -0x20(%ebp)
  80027c:	ff 75 dc             	pushl  -0x24(%ebp)
  80027f:	ff 75 d8             	pushl  -0x28(%ebp)
  800282:	e8 69 08 00 00       	call   800af0 <__udivdi3>
  800287:	83 c4 18             	add    $0x18,%esp
  80028a:	52                   	push   %edx
  80028b:	50                   	push   %eax
  80028c:	89 f2                	mov    %esi,%edx
  80028e:	89 f8                	mov    %edi,%eax
  800290:	e8 9e ff ff ff       	call   800233 <printnum>
  800295:	83 c4 20             	add    $0x20,%esp
  800298:	eb 18                	jmp    8002b2 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80029a:	83 ec 08             	sub    $0x8,%esp
  80029d:	56                   	push   %esi
  80029e:	ff 75 18             	pushl  0x18(%ebp)
  8002a1:	ff d7                	call   *%edi
  8002a3:	83 c4 10             	add    $0x10,%esp
  8002a6:	eb 03                	jmp    8002ab <printnum+0x78>
  8002a8:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002ab:	83 eb 01             	sub    $0x1,%ebx
  8002ae:	85 db                	test   %ebx,%ebx
  8002b0:	7f e8                	jg     80029a <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002b2:	83 ec 08             	sub    $0x8,%esp
  8002b5:	56                   	push   %esi
  8002b6:	83 ec 04             	sub    $0x4,%esp
  8002b9:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002bc:	ff 75 e0             	pushl  -0x20(%ebp)
  8002bf:	ff 75 dc             	pushl  -0x24(%ebp)
  8002c2:	ff 75 d8             	pushl  -0x28(%ebp)
  8002c5:	e8 56 09 00 00       	call   800c20 <__umoddi3>
  8002ca:	83 c4 14             	add    $0x14,%esp
  8002cd:	0f be 80 e8 0d 80 00 	movsbl 0x800de8(%eax),%eax
  8002d4:	50                   	push   %eax
  8002d5:	ff d7                	call   *%edi
}
  8002d7:	83 c4 10             	add    $0x10,%esp
  8002da:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002dd:	5b                   	pop    %ebx
  8002de:	5e                   	pop    %esi
  8002df:	5f                   	pop    %edi
  8002e0:	5d                   	pop    %ebp
  8002e1:	c3                   	ret    

008002e2 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002e2:	55                   	push   %ebp
  8002e3:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002e5:	83 fa 01             	cmp    $0x1,%edx
  8002e8:	7e 0e                	jle    8002f8 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002ea:	8b 10                	mov    (%eax),%edx
  8002ec:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002ef:	89 08                	mov    %ecx,(%eax)
  8002f1:	8b 02                	mov    (%edx),%eax
  8002f3:	8b 52 04             	mov    0x4(%edx),%edx
  8002f6:	eb 22                	jmp    80031a <getuint+0x38>
	else if (lflag)
  8002f8:	85 d2                	test   %edx,%edx
  8002fa:	74 10                	je     80030c <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002fc:	8b 10                	mov    (%eax),%edx
  8002fe:	8d 4a 04             	lea    0x4(%edx),%ecx
  800301:	89 08                	mov    %ecx,(%eax)
  800303:	8b 02                	mov    (%edx),%eax
  800305:	ba 00 00 00 00       	mov    $0x0,%edx
  80030a:	eb 0e                	jmp    80031a <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  80030c:	8b 10                	mov    (%eax),%edx
  80030e:	8d 4a 04             	lea    0x4(%edx),%ecx
  800311:	89 08                	mov    %ecx,(%eax)
  800313:	8b 02                	mov    (%edx),%eax
  800315:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80031a:	5d                   	pop    %ebp
  80031b:	c3                   	ret    

0080031c <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80031c:	55                   	push   %ebp
  80031d:	89 e5                	mov    %esp,%ebp
  80031f:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800322:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800326:	8b 10                	mov    (%eax),%edx
  800328:	3b 50 04             	cmp    0x4(%eax),%edx
  80032b:	73 0a                	jae    800337 <sprintputch+0x1b>
		*b->buf++ = ch;
  80032d:	8d 4a 01             	lea    0x1(%edx),%ecx
  800330:	89 08                	mov    %ecx,(%eax)
  800332:	8b 45 08             	mov    0x8(%ebp),%eax
  800335:	88 02                	mov    %al,(%edx)
}
  800337:	5d                   	pop    %ebp
  800338:	c3                   	ret    

00800339 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800339:	55                   	push   %ebp
  80033a:	89 e5                	mov    %esp,%ebp
  80033c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80033f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800342:	50                   	push   %eax
  800343:	ff 75 10             	pushl  0x10(%ebp)
  800346:	ff 75 0c             	pushl  0xc(%ebp)
  800349:	ff 75 08             	pushl  0x8(%ebp)
  80034c:	e8 05 00 00 00       	call   800356 <vprintfmt>
	va_end(ap);
}
  800351:	83 c4 10             	add    $0x10,%esp
  800354:	c9                   	leave  
  800355:	c3                   	ret    

00800356 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800356:	55                   	push   %ebp
  800357:	89 e5                	mov    %esp,%ebp
  800359:	57                   	push   %edi
  80035a:	56                   	push   %esi
  80035b:	53                   	push   %ebx
  80035c:	83 ec 2c             	sub    $0x2c,%esp
  80035f:	8b 75 08             	mov    0x8(%ebp),%esi
  800362:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800365:	8b 7d 10             	mov    0x10(%ebp),%edi
  800368:	eb 12                	jmp    80037c <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80036a:	85 c0                	test   %eax,%eax
  80036c:	0f 84 89 03 00 00    	je     8006fb <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  800372:	83 ec 08             	sub    $0x8,%esp
  800375:	53                   	push   %ebx
  800376:	50                   	push   %eax
  800377:	ff d6                	call   *%esi
  800379:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80037c:	83 c7 01             	add    $0x1,%edi
  80037f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800383:	83 f8 25             	cmp    $0x25,%eax
  800386:	75 e2                	jne    80036a <vprintfmt+0x14>
  800388:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80038c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800393:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80039a:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8003a1:	ba 00 00 00 00       	mov    $0x0,%edx
  8003a6:	eb 07                	jmp    8003af <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a8:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8003ab:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003af:	8d 47 01             	lea    0x1(%edi),%eax
  8003b2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003b5:	0f b6 07             	movzbl (%edi),%eax
  8003b8:	0f b6 c8             	movzbl %al,%ecx
  8003bb:	83 e8 23             	sub    $0x23,%eax
  8003be:	3c 55                	cmp    $0x55,%al
  8003c0:	0f 87 1a 03 00 00    	ja     8006e0 <vprintfmt+0x38a>
  8003c6:	0f b6 c0             	movzbl %al,%eax
  8003c9:	ff 24 85 80 0e 80 00 	jmp    *0x800e80(,%eax,4)
  8003d0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003d3:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003d7:	eb d6                	jmp    8003af <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003dc:	b8 00 00 00 00       	mov    $0x0,%eax
  8003e1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003e4:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003e7:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  8003eb:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  8003ee:	8d 51 d0             	lea    -0x30(%ecx),%edx
  8003f1:	83 fa 09             	cmp    $0x9,%edx
  8003f4:	77 39                	ja     80042f <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003f6:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003f9:	eb e9                	jmp    8003e4 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003fb:	8b 45 14             	mov    0x14(%ebp),%eax
  8003fe:	8d 48 04             	lea    0x4(%eax),%ecx
  800401:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800404:	8b 00                	mov    (%eax),%eax
  800406:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800409:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80040c:	eb 27                	jmp    800435 <vprintfmt+0xdf>
  80040e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800411:	85 c0                	test   %eax,%eax
  800413:	b9 00 00 00 00       	mov    $0x0,%ecx
  800418:	0f 49 c8             	cmovns %eax,%ecx
  80041b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80041e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800421:	eb 8c                	jmp    8003af <vprintfmt+0x59>
  800423:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800426:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80042d:	eb 80                	jmp    8003af <vprintfmt+0x59>
  80042f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800432:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800435:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800439:	0f 89 70 ff ff ff    	jns    8003af <vprintfmt+0x59>
				width = precision, precision = -1;
  80043f:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800442:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800445:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80044c:	e9 5e ff ff ff       	jmp    8003af <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800451:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800454:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800457:	e9 53 ff ff ff       	jmp    8003af <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80045c:	8b 45 14             	mov    0x14(%ebp),%eax
  80045f:	8d 50 04             	lea    0x4(%eax),%edx
  800462:	89 55 14             	mov    %edx,0x14(%ebp)
  800465:	83 ec 08             	sub    $0x8,%esp
  800468:	53                   	push   %ebx
  800469:	ff 30                	pushl  (%eax)
  80046b:	ff d6                	call   *%esi
			break;
  80046d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800470:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800473:	e9 04 ff ff ff       	jmp    80037c <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800478:	8b 45 14             	mov    0x14(%ebp),%eax
  80047b:	8d 50 04             	lea    0x4(%eax),%edx
  80047e:	89 55 14             	mov    %edx,0x14(%ebp)
  800481:	8b 00                	mov    (%eax),%eax
  800483:	99                   	cltd   
  800484:	31 d0                	xor    %edx,%eax
  800486:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800488:	83 f8 07             	cmp    $0x7,%eax
  80048b:	7f 0b                	jg     800498 <vprintfmt+0x142>
  80048d:	8b 14 85 e0 0f 80 00 	mov    0x800fe0(,%eax,4),%edx
  800494:	85 d2                	test   %edx,%edx
  800496:	75 18                	jne    8004b0 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800498:	50                   	push   %eax
  800499:	68 00 0e 80 00       	push   $0x800e00
  80049e:	53                   	push   %ebx
  80049f:	56                   	push   %esi
  8004a0:	e8 94 fe ff ff       	call   800339 <printfmt>
  8004a5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004a8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8004ab:	e9 cc fe ff ff       	jmp    80037c <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8004b0:	52                   	push   %edx
  8004b1:	68 09 0e 80 00       	push   $0x800e09
  8004b6:	53                   	push   %ebx
  8004b7:	56                   	push   %esi
  8004b8:	e8 7c fe ff ff       	call   800339 <printfmt>
  8004bd:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004c0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004c3:	e9 b4 fe ff ff       	jmp    80037c <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004c8:	8b 45 14             	mov    0x14(%ebp),%eax
  8004cb:	8d 50 04             	lea    0x4(%eax),%edx
  8004ce:	89 55 14             	mov    %edx,0x14(%ebp)
  8004d1:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004d3:	85 ff                	test   %edi,%edi
  8004d5:	b8 f9 0d 80 00       	mov    $0x800df9,%eax
  8004da:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004dd:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004e1:	0f 8e 94 00 00 00    	jle    80057b <vprintfmt+0x225>
  8004e7:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004eb:	0f 84 98 00 00 00    	je     800589 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004f1:	83 ec 08             	sub    $0x8,%esp
  8004f4:	ff 75 d0             	pushl  -0x30(%ebp)
  8004f7:	57                   	push   %edi
  8004f8:	e8 86 02 00 00       	call   800783 <strnlen>
  8004fd:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800500:	29 c1                	sub    %eax,%ecx
  800502:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800505:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800508:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80050c:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80050f:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800512:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800514:	eb 0f                	jmp    800525 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800516:	83 ec 08             	sub    $0x8,%esp
  800519:	53                   	push   %ebx
  80051a:	ff 75 e0             	pushl  -0x20(%ebp)
  80051d:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80051f:	83 ef 01             	sub    $0x1,%edi
  800522:	83 c4 10             	add    $0x10,%esp
  800525:	85 ff                	test   %edi,%edi
  800527:	7f ed                	jg     800516 <vprintfmt+0x1c0>
  800529:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80052c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80052f:	85 c9                	test   %ecx,%ecx
  800531:	b8 00 00 00 00       	mov    $0x0,%eax
  800536:	0f 49 c1             	cmovns %ecx,%eax
  800539:	29 c1                	sub    %eax,%ecx
  80053b:	89 75 08             	mov    %esi,0x8(%ebp)
  80053e:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800541:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800544:	89 cb                	mov    %ecx,%ebx
  800546:	eb 4d                	jmp    800595 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800548:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80054c:	74 1b                	je     800569 <vprintfmt+0x213>
  80054e:	0f be c0             	movsbl %al,%eax
  800551:	83 e8 20             	sub    $0x20,%eax
  800554:	83 f8 5e             	cmp    $0x5e,%eax
  800557:	76 10                	jbe    800569 <vprintfmt+0x213>
					putch('?', putdat);
  800559:	83 ec 08             	sub    $0x8,%esp
  80055c:	ff 75 0c             	pushl  0xc(%ebp)
  80055f:	6a 3f                	push   $0x3f
  800561:	ff 55 08             	call   *0x8(%ebp)
  800564:	83 c4 10             	add    $0x10,%esp
  800567:	eb 0d                	jmp    800576 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800569:	83 ec 08             	sub    $0x8,%esp
  80056c:	ff 75 0c             	pushl  0xc(%ebp)
  80056f:	52                   	push   %edx
  800570:	ff 55 08             	call   *0x8(%ebp)
  800573:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800576:	83 eb 01             	sub    $0x1,%ebx
  800579:	eb 1a                	jmp    800595 <vprintfmt+0x23f>
  80057b:	89 75 08             	mov    %esi,0x8(%ebp)
  80057e:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800581:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800584:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800587:	eb 0c                	jmp    800595 <vprintfmt+0x23f>
  800589:	89 75 08             	mov    %esi,0x8(%ebp)
  80058c:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80058f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800592:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800595:	83 c7 01             	add    $0x1,%edi
  800598:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80059c:	0f be d0             	movsbl %al,%edx
  80059f:	85 d2                	test   %edx,%edx
  8005a1:	74 23                	je     8005c6 <vprintfmt+0x270>
  8005a3:	85 f6                	test   %esi,%esi
  8005a5:	78 a1                	js     800548 <vprintfmt+0x1f2>
  8005a7:	83 ee 01             	sub    $0x1,%esi
  8005aa:	79 9c                	jns    800548 <vprintfmt+0x1f2>
  8005ac:	89 df                	mov    %ebx,%edi
  8005ae:	8b 75 08             	mov    0x8(%ebp),%esi
  8005b1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005b4:	eb 18                	jmp    8005ce <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005b6:	83 ec 08             	sub    $0x8,%esp
  8005b9:	53                   	push   %ebx
  8005ba:	6a 20                	push   $0x20
  8005bc:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005be:	83 ef 01             	sub    $0x1,%edi
  8005c1:	83 c4 10             	add    $0x10,%esp
  8005c4:	eb 08                	jmp    8005ce <vprintfmt+0x278>
  8005c6:	89 df                	mov    %ebx,%edi
  8005c8:	8b 75 08             	mov    0x8(%ebp),%esi
  8005cb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005ce:	85 ff                	test   %edi,%edi
  8005d0:	7f e4                	jg     8005b6 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005d2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005d5:	e9 a2 fd ff ff       	jmp    80037c <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005da:	83 fa 01             	cmp    $0x1,%edx
  8005dd:	7e 16                	jle    8005f5 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  8005df:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e2:	8d 50 08             	lea    0x8(%eax),%edx
  8005e5:	89 55 14             	mov    %edx,0x14(%ebp)
  8005e8:	8b 50 04             	mov    0x4(%eax),%edx
  8005eb:	8b 00                	mov    (%eax),%eax
  8005ed:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005f0:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005f3:	eb 32                	jmp    800627 <vprintfmt+0x2d1>
	else if (lflag)
  8005f5:	85 d2                	test   %edx,%edx
  8005f7:	74 18                	je     800611 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  8005f9:	8b 45 14             	mov    0x14(%ebp),%eax
  8005fc:	8d 50 04             	lea    0x4(%eax),%edx
  8005ff:	89 55 14             	mov    %edx,0x14(%ebp)
  800602:	8b 00                	mov    (%eax),%eax
  800604:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800607:	89 c1                	mov    %eax,%ecx
  800609:	c1 f9 1f             	sar    $0x1f,%ecx
  80060c:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80060f:	eb 16                	jmp    800627 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  800611:	8b 45 14             	mov    0x14(%ebp),%eax
  800614:	8d 50 04             	lea    0x4(%eax),%edx
  800617:	89 55 14             	mov    %edx,0x14(%ebp)
  80061a:	8b 00                	mov    (%eax),%eax
  80061c:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80061f:	89 c1                	mov    %eax,%ecx
  800621:	c1 f9 1f             	sar    $0x1f,%ecx
  800624:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800627:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80062a:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80062d:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800632:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800636:	79 74                	jns    8006ac <vprintfmt+0x356>
				putch('-', putdat);
  800638:	83 ec 08             	sub    $0x8,%esp
  80063b:	53                   	push   %ebx
  80063c:	6a 2d                	push   $0x2d
  80063e:	ff d6                	call   *%esi
				num = -(long long) num;
  800640:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800643:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800646:	f7 d8                	neg    %eax
  800648:	83 d2 00             	adc    $0x0,%edx
  80064b:	f7 da                	neg    %edx
  80064d:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800650:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800655:	eb 55                	jmp    8006ac <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800657:	8d 45 14             	lea    0x14(%ebp),%eax
  80065a:	e8 83 fc ff ff       	call   8002e2 <getuint>
			base = 10;
  80065f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800664:	eb 46                	jmp    8006ac <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800666:	8d 45 14             	lea    0x14(%ebp),%eax
  800669:	e8 74 fc ff ff       	call   8002e2 <getuint>
			base = 8;
  80066e:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800673:	eb 37                	jmp    8006ac <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  800675:	83 ec 08             	sub    $0x8,%esp
  800678:	53                   	push   %ebx
  800679:	6a 30                	push   $0x30
  80067b:	ff d6                	call   *%esi
			putch('x', putdat);
  80067d:	83 c4 08             	add    $0x8,%esp
  800680:	53                   	push   %ebx
  800681:	6a 78                	push   $0x78
  800683:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800685:	8b 45 14             	mov    0x14(%ebp),%eax
  800688:	8d 50 04             	lea    0x4(%eax),%edx
  80068b:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80068e:	8b 00                	mov    (%eax),%eax
  800690:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800695:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800698:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  80069d:	eb 0d                	jmp    8006ac <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  80069f:	8d 45 14             	lea    0x14(%ebp),%eax
  8006a2:	e8 3b fc ff ff       	call   8002e2 <getuint>
			base = 16;
  8006a7:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006ac:	83 ec 0c             	sub    $0xc,%esp
  8006af:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8006b3:	57                   	push   %edi
  8006b4:	ff 75 e0             	pushl  -0x20(%ebp)
  8006b7:	51                   	push   %ecx
  8006b8:	52                   	push   %edx
  8006b9:	50                   	push   %eax
  8006ba:	89 da                	mov    %ebx,%edx
  8006bc:	89 f0                	mov    %esi,%eax
  8006be:	e8 70 fb ff ff       	call   800233 <printnum>
			break;
  8006c3:	83 c4 20             	add    $0x20,%esp
  8006c6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006c9:	e9 ae fc ff ff       	jmp    80037c <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006ce:	83 ec 08             	sub    $0x8,%esp
  8006d1:	53                   	push   %ebx
  8006d2:	51                   	push   %ecx
  8006d3:	ff d6                	call   *%esi
			break;
  8006d5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006d8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006db:	e9 9c fc ff ff       	jmp    80037c <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006e0:	83 ec 08             	sub    $0x8,%esp
  8006e3:	53                   	push   %ebx
  8006e4:	6a 25                	push   $0x25
  8006e6:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006e8:	83 c4 10             	add    $0x10,%esp
  8006eb:	eb 03                	jmp    8006f0 <vprintfmt+0x39a>
  8006ed:	83 ef 01             	sub    $0x1,%edi
  8006f0:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006f4:	75 f7                	jne    8006ed <vprintfmt+0x397>
  8006f6:	e9 81 fc ff ff       	jmp    80037c <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006fb:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006fe:	5b                   	pop    %ebx
  8006ff:	5e                   	pop    %esi
  800700:	5f                   	pop    %edi
  800701:	5d                   	pop    %ebp
  800702:	c3                   	ret    

00800703 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800703:	55                   	push   %ebp
  800704:	89 e5                	mov    %esp,%ebp
  800706:	83 ec 18             	sub    $0x18,%esp
  800709:	8b 45 08             	mov    0x8(%ebp),%eax
  80070c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80070f:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800712:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800716:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800719:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800720:	85 c0                	test   %eax,%eax
  800722:	74 26                	je     80074a <vsnprintf+0x47>
  800724:	85 d2                	test   %edx,%edx
  800726:	7e 22                	jle    80074a <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800728:	ff 75 14             	pushl  0x14(%ebp)
  80072b:	ff 75 10             	pushl  0x10(%ebp)
  80072e:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800731:	50                   	push   %eax
  800732:	68 1c 03 80 00       	push   $0x80031c
  800737:	e8 1a fc ff ff       	call   800356 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80073c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80073f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800742:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800745:	83 c4 10             	add    $0x10,%esp
  800748:	eb 05                	jmp    80074f <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  80074a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80074f:	c9                   	leave  
  800750:	c3                   	ret    

00800751 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800751:	55                   	push   %ebp
  800752:	89 e5                	mov    %esp,%ebp
  800754:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800757:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  80075a:	50                   	push   %eax
  80075b:	ff 75 10             	pushl  0x10(%ebp)
  80075e:	ff 75 0c             	pushl  0xc(%ebp)
  800761:	ff 75 08             	pushl  0x8(%ebp)
  800764:	e8 9a ff ff ff       	call   800703 <vsnprintf>
	va_end(ap);

	return rc;
}
  800769:	c9                   	leave  
  80076a:	c3                   	ret    

0080076b <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80076b:	55                   	push   %ebp
  80076c:	89 e5                	mov    %esp,%ebp
  80076e:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800771:	b8 00 00 00 00       	mov    $0x0,%eax
  800776:	eb 03                	jmp    80077b <strlen+0x10>
		n++;
  800778:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80077b:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80077f:	75 f7                	jne    800778 <strlen+0xd>
		n++;
	return n;
}
  800781:	5d                   	pop    %ebp
  800782:	c3                   	ret    

00800783 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800783:	55                   	push   %ebp
  800784:	89 e5                	mov    %esp,%ebp
  800786:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800789:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80078c:	ba 00 00 00 00       	mov    $0x0,%edx
  800791:	eb 03                	jmp    800796 <strnlen+0x13>
		n++;
  800793:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800796:	39 c2                	cmp    %eax,%edx
  800798:	74 08                	je     8007a2 <strnlen+0x1f>
  80079a:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80079e:	75 f3                	jne    800793 <strnlen+0x10>
  8007a0:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8007a2:	5d                   	pop    %ebp
  8007a3:	c3                   	ret    

008007a4 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007a4:	55                   	push   %ebp
  8007a5:	89 e5                	mov    %esp,%ebp
  8007a7:	53                   	push   %ebx
  8007a8:	8b 45 08             	mov    0x8(%ebp),%eax
  8007ab:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007ae:	89 c2                	mov    %eax,%edx
  8007b0:	83 c2 01             	add    $0x1,%edx
  8007b3:	83 c1 01             	add    $0x1,%ecx
  8007b6:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007ba:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007bd:	84 db                	test   %bl,%bl
  8007bf:	75 ef                	jne    8007b0 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007c1:	5b                   	pop    %ebx
  8007c2:	5d                   	pop    %ebp
  8007c3:	c3                   	ret    

008007c4 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007c4:	55                   	push   %ebp
  8007c5:	89 e5                	mov    %esp,%ebp
  8007c7:	53                   	push   %ebx
  8007c8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007cb:	53                   	push   %ebx
  8007cc:	e8 9a ff ff ff       	call   80076b <strlen>
  8007d1:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007d4:	ff 75 0c             	pushl  0xc(%ebp)
  8007d7:	01 d8                	add    %ebx,%eax
  8007d9:	50                   	push   %eax
  8007da:	e8 c5 ff ff ff       	call   8007a4 <strcpy>
	return dst;
}
  8007df:	89 d8                	mov    %ebx,%eax
  8007e1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007e4:	c9                   	leave  
  8007e5:	c3                   	ret    

008007e6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007e6:	55                   	push   %ebp
  8007e7:	89 e5                	mov    %esp,%ebp
  8007e9:	56                   	push   %esi
  8007ea:	53                   	push   %ebx
  8007eb:	8b 75 08             	mov    0x8(%ebp),%esi
  8007ee:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007f1:	89 f3                	mov    %esi,%ebx
  8007f3:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007f6:	89 f2                	mov    %esi,%edx
  8007f8:	eb 0f                	jmp    800809 <strncpy+0x23>
		*dst++ = *src;
  8007fa:	83 c2 01             	add    $0x1,%edx
  8007fd:	0f b6 01             	movzbl (%ecx),%eax
  800800:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800803:	80 39 01             	cmpb   $0x1,(%ecx)
  800806:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800809:	39 da                	cmp    %ebx,%edx
  80080b:	75 ed                	jne    8007fa <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  80080d:	89 f0                	mov    %esi,%eax
  80080f:	5b                   	pop    %ebx
  800810:	5e                   	pop    %esi
  800811:	5d                   	pop    %ebp
  800812:	c3                   	ret    

00800813 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800813:	55                   	push   %ebp
  800814:	89 e5                	mov    %esp,%ebp
  800816:	56                   	push   %esi
  800817:	53                   	push   %ebx
  800818:	8b 75 08             	mov    0x8(%ebp),%esi
  80081b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80081e:	8b 55 10             	mov    0x10(%ebp),%edx
  800821:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800823:	85 d2                	test   %edx,%edx
  800825:	74 21                	je     800848 <strlcpy+0x35>
  800827:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  80082b:	89 f2                	mov    %esi,%edx
  80082d:	eb 09                	jmp    800838 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80082f:	83 c2 01             	add    $0x1,%edx
  800832:	83 c1 01             	add    $0x1,%ecx
  800835:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800838:	39 c2                	cmp    %eax,%edx
  80083a:	74 09                	je     800845 <strlcpy+0x32>
  80083c:	0f b6 19             	movzbl (%ecx),%ebx
  80083f:	84 db                	test   %bl,%bl
  800841:	75 ec                	jne    80082f <strlcpy+0x1c>
  800843:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800845:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800848:	29 f0                	sub    %esi,%eax
}
  80084a:	5b                   	pop    %ebx
  80084b:	5e                   	pop    %esi
  80084c:	5d                   	pop    %ebp
  80084d:	c3                   	ret    

0080084e <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80084e:	55                   	push   %ebp
  80084f:	89 e5                	mov    %esp,%ebp
  800851:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800854:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800857:	eb 06                	jmp    80085f <strcmp+0x11>
		p++, q++;
  800859:	83 c1 01             	add    $0x1,%ecx
  80085c:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80085f:	0f b6 01             	movzbl (%ecx),%eax
  800862:	84 c0                	test   %al,%al
  800864:	74 04                	je     80086a <strcmp+0x1c>
  800866:	3a 02                	cmp    (%edx),%al
  800868:	74 ef                	je     800859 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  80086a:	0f b6 c0             	movzbl %al,%eax
  80086d:	0f b6 12             	movzbl (%edx),%edx
  800870:	29 d0                	sub    %edx,%eax
}
  800872:	5d                   	pop    %ebp
  800873:	c3                   	ret    

00800874 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800874:	55                   	push   %ebp
  800875:	89 e5                	mov    %esp,%ebp
  800877:	53                   	push   %ebx
  800878:	8b 45 08             	mov    0x8(%ebp),%eax
  80087b:	8b 55 0c             	mov    0xc(%ebp),%edx
  80087e:	89 c3                	mov    %eax,%ebx
  800880:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800883:	eb 06                	jmp    80088b <strncmp+0x17>
		n--, p++, q++;
  800885:	83 c0 01             	add    $0x1,%eax
  800888:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80088b:	39 d8                	cmp    %ebx,%eax
  80088d:	74 15                	je     8008a4 <strncmp+0x30>
  80088f:	0f b6 08             	movzbl (%eax),%ecx
  800892:	84 c9                	test   %cl,%cl
  800894:	74 04                	je     80089a <strncmp+0x26>
  800896:	3a 0a                	cmp    (%edx),%cl
  800898:	74 eb                	je     800885 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  80089a:	0f b6 00             	movzbl (%eax),%eax
  80089d:	0f b6 12             	movzbl (%edx),%edx
  8008a0:	29 d0                	sub    %edx,%eax
  8008a2:	eb 05                	jmp    8008a9 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008a4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008a9:	5b                   	pop    %ebx
  8008aa:	5d                   	pop    %ebp
  8008ab:	c3                   	ret    

008008ac <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008ac:	55                   	push   %ebp
  8008ad:	89 e5                	mov    %esp,%ebp
  8008af:	8b 45 08             	mov    0x8(%ebp),%eax
  8008b2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008b6:	eb 07                	jmp    8008bf <strchr+0x13>
		if (*s == c)
  8008b8:	38 ca                	cmp    %cl,%dl
  8008ba:	74 0f                	je     8008cb <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008bc:	83 c0 01             	add    $0x1,%eax
  8008bf:	0f b6 10             	movzbl (%eax),%edx
  8008c2:	84 d2                	test   %dl,%dl
  8008c4:	75 f2                	jne    8008b8 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008c6:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008cb:	5d                   	pop    %ebp
  8008cc:	c3                   	ret    

008008cd <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008cd:	55                   	push   %ebp
  8008ce:	89 e5                	mov    %esp,%ebp
  8008d0:	8b 45 08             	mov    0x8(%ebp),%eax
  8008d3:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008d7:	eb 03                	jmp    8008dc <strfind+0xf>
  8008d9:	83 c0 01             	add    $0x1,%eax
  8008dc:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008df:	38 ca                	cmp    %cl,%dl
  8008e1:	74 04                	je     8008e7 <strfind+0x1a>
  8008e3:	84 d2                	test   %dl,%dl
  8008e5:	75 f2                	jne    8008d9 <strfind+0xc>
			break;
	return (char *) s;
}
  8008e7:	5d                   	pop    %ebp
  8008e8:	c3                   	ret    

008008e9 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008e9:	55                   	push   %ebp
  8008ea:	89 e5                	mov    %esp,%ebp
  8008ec:	57                   	push   %edi
  8008ed:	56                   	push   %esi
  8008ee:	53                   	push   %ebx
  8008ef:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008f2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008f5:	85 c9                	test   %ecx,%ecx
  8008f7:	74 36                	je     80092f <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008f9:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008ff:	75 28                	jne    800929 <memset+0x40>
  800901:	f6 c1 03             	test   $0x3,%cl
  800904:	75 23                	jne    800929 <memset+0x40>
		c &= 0xFF;
  800906:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80090a:	89 d3                	mov    %edx,%ebx
  80090c:	c1 e3 08             	shl    $0x8,%ebx
  80090f:	89 d6                	mov    %edx,%esi
  800911:	c1 e6 18             	shl    $0x18,%esi
  800914:	89 d0                	mov    %edx,%eax
  800916:	c1 e0 10             	shl    $0x10,%eax
  800919:	09 f0                	or     %esi,%eax
  80091b:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  80091d:	89 d8                	mov    %ebx,%eax
  80091f:	09 d0                	or     %edx,%eax
  800921:	c1 e9 02             	shr    $0x2,%ecx
  800924:	fc                   	cld    
  800925:	f3 ab                	rep stos %eax,%es:(%edi)
  800927:	eb 06                	jmp    80092f <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800929:	8b 45 0c             	mov    0xc(%ebp),%eax
  80092c:	fc                   	cld    
  80092d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80092f:	89 f8                	mov    %edi,%eax
  800931:	5b                   	pop    %ebx
  800932:	5e                   	pop    %esi
  800933:	5f                   	pop    %edi
  800934:	5d                   	pop    %ebp
  800935:	c3                   	ret    

00800936 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800936:	55                   	push   %ebp
  800937:	89 e5                	mov    %esp,%ebp
  800939:	57                   	push   %edi
  80093a:	56                   	push   %esi
  80093b:	8b 45 08             	mov    0x8(%ebp),%eax
  80093e:	8b 75 0c             	mov    0xc(%ebp),%esi
  800941:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800944:	39 c6                	cmp    %eax,%esi
  800946:	73 35                	jae    80097d <memmove+0x47>
  800948:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80094b:	39 d0                	cmp    %edx,%eax
  80094d:	73 2e                	jae    80097d <memmove+0x47>
		s += n;
		d += n;
  80094f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800952:	89 d6                	mov    %edx,%esi
  800954:	09 fe                	or     %edi,%esi
  800956:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80095c:	75 13                	jne    800971 <memmove+0x3b>
  80095e:	f6 c1 03             	test   $0x3,%cl
  800961:	75 0e                	jne    800971 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800963:	83 ef 04             	sub    $0x4,%edi
  800966:	8d 72 fc             	lea    -0x4(%edx),%esi
  800969:	c1 e9 02             	shr    $0x2,%ecx
  80096c:	fd                   	std    
  80096d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80096f:	eb 09                	jmp    80097a <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800971:	83 ef 01             	sub    $0x1,%edi
  800974:	8d 72 ff             	lea    -0x1(%edx),%esi
  800977:	fd                   	std    
  800978:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80097a:	fc                   	cld    
  80097b:	eb 1d                	jmp    80099a <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80097d:	89 f2                	mov    %esi,%edx
  80097f:	09 c2                	or     %eax,%edx
  800981:	f6 c2 03             	test   $0x3,%dl
  800984:	75 0f                	jne    800995 <memmove+0x5f>
  800986:	f6 c1 03             	test   $0x3,%cl
  800989:	75 0a                	jne    800995 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  80098b:	c1 e9 02             	shr    $0x2,%ecx
  80098e:	89 c7                	mov    %eax,%edi
  800990:	fc                   	cld    
  800991:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800993:	eb 05                	jmp    80099a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800995:	89 c7                	mov    %eax,%edi
  800997:	fc                   	cld    
  800998:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  80099a:	5e                   	pop    %esi
  80099b:	5f                   	pop    %edi
  80099c:	5d                   	pop    %ebp
  80099d:	c3                   	ret    

0080099e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80099e:	55                   	push   %ebp
  80099f:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8009a1:	ff 75 10             	pushl  0x10(%ebp)
  8009a4:	ff 75 0c             	pushl  0xc(%ebp)
  8009a7:	ff 75 08             	pushl  0x8(%ebp)
  8009aa:	e8 87 ff ff ff       	call   800936 <memmove>
}
  8009af:	c9                   	leave  
  8009b0:	c3                   	ret    

008009b1 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009b1:	55                   	push   %ebp
  8009b2:	89 e5                	mov    %esp,%ebp
  8009b4:	56                   	push   %esi
  8009b5:	53                   	push   %ebx
  8009b6:	8b 45 08             	mov    0x8(%ebp),%eax
  8009b9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009bc:	89 c6                	mov    %eax,%esi
  8009be:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009c1:	eb 1a                	jmp    8009dd <memcmp+0x2c>
		if (*s1 != *s2)
  8009c3:	0f b6 08             	movzbl (%eax),%ecx
  8009c6:	0f b6 1a             	movzbl (%edx),%ebx
  8009c9:	38 d9                	cmp    %bl,%cl
  8009cb:	74 0a                	je     8009d7 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009cd:	0f b6 c1             	movzbl %cl,%eax
  8009d0:	0f b6 db             	movzbl %bl,%ebx
  8009d3:	29 d8                	sub    %ebx,%eax
  8009d5:	eb 0f                	jmp    8009e6 <memcmp+0x35>
		s1++, s2++;
  8009d7:	83 c0 01             	add    $0x1,%eax
  8009da:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009dd:	39 f0                	cmp    %esi,%eax
  8009df:	75 e2                	jne    8009c3 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009e1:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009e6:	5b                   	pop    %ebx
  8009e7:	5e                   	pop    %esi
  8009e8:	5d                   	pop    %ebp
  8009e9:	c3                   	ret    

008009ea <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009ea:	55                   	push   %ebp
  8009eb:	89 e5                	mov    %esp,%ebp
  8009ed:	53                   	push   %ebx
  8009ee:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009f1:	89 c1                	mov    %eax,%ecx
  8009f3:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009f6:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009fa:	eb 0a                	jmp    800a06 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009fc:	0f b6 10             	movzbl (%eax),%edx
  8009ff:	39 da                	cmp    %ebx,%edx
  800a01:	74 07                	je     800a0a <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a03:	83 c0 01             	add    $0x1,%eax
  800a06:	39 c8                	cmp    %ecx,%eax
  800a08:	72 f2                	jb     8009fc <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a0a:	5b                   	pop    %ebx
  800a0b:	5d                   	pop    %ebp
  800a0c:	c3                   	ret    

00800a0d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a0d:	55                   	push   %ebp
  800a0e:	89 e5                	mov    %esp,%ebp
  800a10:	57                   	push   %edi
  800a11:	56                   	push   %esi
  800a12:	53                   	push   %ebx
  800a13:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a16:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a19:	eb 03                	jmp    800a1e <strtol+0x11>
		s++;
  800a1b:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a1e:	0f b6 01             	movzbl (%ecx),%eax
  800a21:	3c 20                	cmp    $0x20,%al
  800a23:	74 f6                	je     800a1b <strtol+0xe>
  800a25:	3c 09                	cmp    $0x9,%al
  800a27:	74 f2                	je     800a1b <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a29:	3c 2b                	cmp    $0x2b,%al
  800a2b:	75 0a                	jne    800a37 <strtol+0x2a>
		s++;
  800a2d:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a30:	bf 00 00 00 00       	mov    $0x0,%edi
  800a35:	eb 11                	jmp    800a48 <strtol+0x3b>
  800a37:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a3c:	3c 2d                	cmp    $0x2d,%al
  800a3e:	75 08                	jne    800a48 <strtol+0x3b>
		s++, neg = 1;
  800a40:	83 c1 01             	add    $0x1,%ecx
  800a43:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a48:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a4e:	75 15                	jne    800a65 <strtol+0x58>
  800a50:	80 39 30             	cmpb   $0x30,(%ecx)
  800a53:	75 10                	jne    800a65 <strtol+0x58>
  800a55:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a59:	75 7c                	jne    800ad7 <strtol+0xca>
		s += 2, base = 16;
  800a5b:	83 c1 02             	add    $0x2,%ecx
  800a5e:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a63:	eb 16                	jmp    800a7b <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a65:	85 db                	test   %ebx,%ebx
  800a67:	75 12                	jne    800a7b <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a69:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a6e:	80 39 30             	cmpb   $0x30,(%ecx)
  800a71:	75 08                	jne    800a7b <strtol+0x6e>
		s++, base = 8;
  800a73:	83 c1 01             	add    $0x1,%ecx
  800a76:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a7b:	b8 00 00 00 00       	mov    $0x0,%eax
  800a80:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a83:	0f b6 11             	movzbl (%ecx),%edx
  800a86:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a89:	89 f3                	mov    %esi,%ebx
  800a8b:	80 fb 09             	cmp    $0x9,%bl
  800a8e:	77 08                	ja     800a98 <strtol+0x8b>
			dig = *s - '0';
  800a90:	0f be d2             	movsbl %dl,%edx
  800a93:	83 ea 30             	sub    $0x30,%edx
  800a96:	eb 22                	jmp    800aba <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a98:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a9b:	89 f3                	mov    %esi,%ebx
  800a9d:	80 fb 19             	cmp    $0x19,%bl
  800aa0:	77 08                	ja     800aaa <strtol+0x9d>
			dig = *s - 'a' + 10;
  800aa2:	0f be d2             	movsbl %dl,%edx
  800aa5:	83 ea 57             	sub    $0x57,%edx
  800aa8:	eb 10                	jmp    800aba <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800aaa:	8d 72 bf             	lea    -0x41(%edx),%esi
  800aad:	89 f3                	mov    %esi,%ebx
  800aaf:	80 fb 19             	cmp    $0x19,%bl
  800ab2:	77 16                	ja     800aca <strtol+0xbd>
			dig = *s - 'A' + 10;
  800ab4:	0f be d2             	movsbl %dl,%edx
  800ab7:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800aba:	3b 55 10             	cmp    0x10(%ebp),%edx
  800abd:	7d 0b                	jge    800aca <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800abf:	83 c1 01             	add    $0x1,%ecx
  800ac2:	0f af 45 10          	imul   0x10(%ebp),%eax
  800ac6:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ac8:	eb b9                	jmp    800a83 <strtol+0x76>

	if (endptr)
  800aca:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ace:	74 0d                	je     800add <strtol+0xd0>
		*endptr = (char *) s;
  800ad0:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ad3:	89 0e                	mov    %ecx,(%esi)
  800ad5:	eb 06                	jmp    800add <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ad7:	85 db                	test   %ebx,%ebx
  800ad9:	74 98                	je     800a73 <strtol+0x66>
  800adb:	eb 9e                	jmp    800a7b <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800add:	89 c2                	mov    %eax,%edx
  800adf:	f7 da                	neg    %edx
  800ae1:	85 ff                	test   %edi,%edi
  800ae3:	0f 45 c2             	cmovne %edx,%eax
}
  800ae6:	5b                   	pop    %ebx
  800ae7:	5e                   	pop    %esi
  800ae8:	5f                   	pop    %edi
  800ae9:	5d                   	pop    %ebp
  800aea:	c3                   	ret    
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

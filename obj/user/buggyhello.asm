
obj/user/buggyhello：     文件格式 elf32-i386


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
  80002c:	e8 16 00 00 00       	call   800047 <libmain>
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
	sys_cputs((char*)1, 1);
  800039:	6a 01                	push   $0x1
  80003b:	6a 01                	push   $0x1
  80003d:	e8 60 00 00 00       	call   8000a2 <sys_cputs>
}
  800042:	83 c4 10             	add    $0x10,%esp
  800045:	c9                   	leave  
  800046:	c3                   	ret    

00800047 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800047:	55                   	push   %ebp
  800048:	89 e5                	mov    %esp,%ebp
  80004a:	56                   	push   %esi
  80004b:	53                   	push   %ebx
  80004c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80004f:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	//thisenv = 0;
	envid_t id = sys_getenvid();
  800052:	e8 c9 00 00 00       	call   800120 <sys_getenvid>
	thisenv = &envs[ENVX(id)];
  800057:	25 ff 03 00 00       	and    $0x3ff,%eax
  80005c:	8d 04 40             	lea    (%eax,%eax,2),%eax
  80005f:	c1 e0 05             	shl    $0x5,%eax
  800062:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800067:	a3 04 10 80 00       	mov    %eax,0x801004
	// save the name of the program so that panic() can use it
	if (argc > 0)
  80006c:	85 db                	test   %ebx,%ebx
  80006e:	7e 07                	jle    800077 <libmain+0x30>
		binaryname = argv[0];
  800070:	8b 06                	mov    (%esi),%eax
  800072:	a3 00 10 80 00       	mov    %eax,0x801000

	// call user main routine
	umain(argc, argv);
  800077:	83 ec 08             	sub    $0x8,%esp
  80007a:	56                   	push   %esi
  80007b:	53                   	push   %ebx
  80007c:	e8 b2 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800081:	e8 0a 00 00 00       	call   800090 <exit>
}
  800086:	83 c4 10             	add    $0x10,%esp
  800089:	8d 65 f8             	lea    -0x8(%ebp),%esp
  80008c:	5b                   	pop    %ebx
  80008d:	5e                   	pop    %esi
  80008e:	5d                   	pop    %ebp
  80008f:	c3                   	ret    

00800090 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800090:	55                   	push   %ebp
  800091:	89 e5                	mov    %esp,%ebp
  800093:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800096:	6a 00                	push   $0x0
  800098:	e8 42 00 00 00       	call   8000df <sys_env_destroy>
}
  80009d:	83 c4 10             	add    $0x10,%esp
  8000a0:	c9                   	leave  
  8000a1:	c3                   	ret    

008000a2 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000a2:	55                   	push   %ebp
  8000a3:	89 e5                	mov    %esp,%ebp
  8000a5:	57                   	push   %edi
  8000a6:	56                   	push   %esi
  8000a7:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000a8:	b8 00 00 00 00       	mov    $0x0,%eax
  8000ad:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000b0:	8b 55 08             	mov    0x8(%ebp),%edx
  8000b3:	89 c3                	mov    %eax,%ebx
  8000b5:	89 c7                	mov    %eax,%edi
  8000b7:	89 c6                	mov    %eax,%esi
  8000b9:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000bb:	5b                   	pop    %ebx
  8000bc:	5e                   	pop    %esi
  8000bd:	5f                   	pop    %edi
  8000be:	5d                   	pop    %ebp
  8000bf:	c3                   	ret    

008000c0 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000c0:	55                   	push   %ebp
  8000c1:	89 e5                	mov    %esp,%ebp
  8000c3:	57                   	push   %edi
  8000c4:	56                   	push   %esi
  8000c5:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000c6:	ba 00 00 00 00       	mov    $0x0,%edx
  8000cb:	b8 01 00 00 00       	mov    $0x1,%eax
  8000d0:	89 d1                	mov    %edx,%ecx
  8000d2:	89 d3                	mov    %edx,%ebx
  8000d4:	89 d7                	mov    %edx,%edi
  8000d6:	89 d6                	mov    %edx,%esi
  8000d8:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000da:	5b                   	pop    %ebx
  8000db:	5e                   	pop    %esi
  8000dc:	5f                   	pop    %edi
  8000dd:	5d                   	pop    %ebp
  8000de:	c3                   	ret    

008000df <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000df:	55                   	push   %ebp
  8000e0:	89 e5                	mov    %esp,%ebp
  8000e2:	57                   	push   %edi
  8000e3:	56                   	push   %esi
  8000e4:	53                   	push   %ebx
  8000e5:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000e8:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000ed:	b8 03 00 00 00       	mov    $0x3,%eax
  8000f2:	8b 55 08             	mov    0x8(%ebp),%edx
  8000f5:	89 cb                	mov    %ecx,%ebx
  8000f7:	89 cf                	mov    %ecx,%edi
  8000f9:	89 ce                	mov    %ecx,%esi
  8000fb:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000fd:	85 c0                	test   %eax,%eax
  8000ff:	7e 17                	jle    800118 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800101:	83 ec 0c             	sub    $0xc,%esp
  800104:	50                   	push   %eax
  800105:	6a 03                	push   $0x3
  800107:	68 8a 0d 80 00       	push   $0x800d8a
  80010c:	6a 23                	push   $0x23
  80010e:	68 a7 0d 80 00       	push   $0x800da7
  800113:	e8 27 00 00 00       	call   80013f <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800118:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80011b:	5b                   	pop    %ebx
  80011c:	5e                   	pop    %esi
  80011d:	5f                   	pop    %edi
  80011e:	5d                   	pop    %ebp
  80011f:	c3                   	ret    

00800120 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800120:	55                   	push   %ebp
  800121:	89 e5                	mov    %esp,%ebp
  800123:	57                   	push   %edi
  800124:	56                   	push   %esi
  800125:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800126:	ba 00 00 00 00       	mov    $0x0,%edx
  80012b:	b8 02 00 00 00       	mov    $0x2,%eax
  800130:	89 d1                	mov    %edx,%ecx
  800132:	89 d3                	mov    %edx,%ebx
  800134:	89 d7                	mov    %edx,%edi
  800136:	89 d6                	mov    %edx,%esi
  800138:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80013a:	5b                   	pop    %ebx
  80013b:	5e                   	pop    %esi
  80013c:	5f                   	pop    %edi
  80013d:	5d                   	pop    %ebp
  80013e:	c3                   	ret    

0080013f <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80013f:	55                   	push   %ebp
  800140:	89 e5                	mov    %esp,%ebp
  800142:	56                   	push   %esi
  800143:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800144:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800147:	8b 35 00 10 80 00    	mov    0x801000,%esi
  80014d:	e8 ce ff ff ff       	call   800120 <sys_getenvid>
  800152:	83 ec 0c             	sub    $0xc,%esp
  800155:	ff 75 0c             	pushl  0xc(%ebp)
  800158:	ff 75 08             	pushl  0x8(%ebp)
  80015b:	56                   	push   %esi
  80015c:	50                   	push   %eax
  80015d:	68 b8 0d 80 00       	push   $0x800db8
  800162:	e8 b1 00 00 00       	call   800218 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800167:	83 c4 18             	add    $0x18,%esp
  80016a:	53                   	push   %ebx
  80016b:	ff 75 10             	pushl  0x10(%ebp)
  80016e:	e8 54 00 00 00       	call   8001c7 <vcprintf>
	cprintf("\n");
  800173:	c7 04 24 dc 0d 80 00 	movl   $0x800ddc,(%esp)
  80017a:	e8 99 00 00 00       	call   800218 <cprintf>
  80017f:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800182:	cc                   	int3   
  800183:	eb fd                	jmp    800182 <_panic+0x43>

00800185 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800185:	55                   	push   %ebp
  800186:	89 e5                	mov    %esp,%ebp
  800188:	53                   	push   %ebx
  800189:	83 ec 04             	sub    $0x4,%esp
  80018c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80018f:	8b 13                	mov    (%ebx),%edx
  800191:	8d 42 01             	lea    0x1(%edx),%eax
  800194:	89 03                	mov    %eax,(%ebx)
  800196:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800199:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  80019d:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001a2:	75 1a                	jne    8001be <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8001a4:	83 ec 08             	sub    $0x8,%esp
  8001a7:	68 ff 00 00 00       	push   $0xff
  8001ac:	8d 43 08             	lea    0x8(%ebx),%eax
  8001af:	50                   	push   %eax
  8001b0:	e8 ed fe ff ff       	call   8000a2 <sys_cputs>
		b->idx = 0;
  8001b5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001bb:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001be:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001c2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001c5:	c9                   	leave  
  8001c6:	c3                   	ret    

008001c7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001c7:	55                   	push   %ebp
  8001c8:	89 e5                	mov    %esp,%ebp
  8001ca:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001d0:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001d7:	00 00 00 
	b.cnt = 0;
  8001da:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001e1:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001e4:	ff 75 0c             	pushl  0xc(%ebp)
  8001e7:	ff 75 08             	pushl  0x8(%ebp)
  8001ea:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001f0:	50                   	push   %eax
  8001f1:	68 85 01 80 00       	push   $0x800185
  8001f6:	e8 54 01 00 00       	call   80034f <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001fb:	83 c4 08             	add    $0x8,%esp
  8001fe:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800204:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80020a:	50                   	push   %eax
  80020b:	e8 92 fe ff ff       	call   8000a2 <sys_cputs>

	return b.cnt;
}
  800210:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800216:	c9                   	leave  
  800217:	c3                   	ret    

00800218 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800218:	55                   	push   %ebp
  800219:	89 e5                	mov    %esp,%ebp
  80021b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80021e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800221:	50                   	push   %eax
  800222:	ff 75 08             	pushl  0x8(%ebp)
  800225:	e8 9d ff ff ff       	call   8001c7 <vcprintf>
	va_end(ap);

	return cnt;
}
  80022a:	c9                   	leave  
  80022b:	c3                   	ret    

0080022c <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80022c:	55                   	push   %ebp
  80022d:	89 e5                	mov    %esp,%ebp
  80022f:	57                   	push   %edi
  800230:	56                   	push   %esi
  800231:	53                   	push   %ebx
  800232:	83 ec 1c             	sub    $0x1c,%esp
  800235:	89 c7                	mov    %eax,%edi
  800237:	89 d6                	mov    %edx,%esi
  800239:	8b 45 08             	mov    0x8(%ebp),%eax
  80023c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80023f:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800242:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800245:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800248:	bb 00 00 00 00       	mov    $0x0,%ebx
  80024d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800250:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800253:	39 d3                	cmp    %edx,%ebx
  800255:	72 05                	jb     80025c <printnum+0x30>
  800257:	39 45 10             	cmp    %eax,0x10(%ebp)
  80025a:	77 45                	ja     8002a1 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80025c:	83 ec 0c             	sub    $0xc,%esp
  80025f:	ff 75 18             	pushl  0x18(%ebp)
  800262:	8b 45 14             	mov    0x14(%ebp),%eax
  800265:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800268:	53                   	push   %ebx
  800269:	ff 75 10             	pushl  0x10(%ebp)
  80026c:	83 ec 08             	sub    $0x8,%esp
  80026f:	ff 75 e4             	pushl  -0x1c(%ebp)
  800272:	ff 75 e0             	pushl  -0x20(%ebp)
  800275:	ff 75 dc             	pushl  -0x24(%ebp)
  800278:	ff 75 d8             	pushl  -0x28(%ebp)
  80027b:	e8 70 08 00 00       	call   800af0 <__udivdi3>
  800280:	83 c4 18             	add    $0x18,%esp
  800283:	52                   	push   %edx
  800284:	50                   	push   %eax
  800285:	89 f2                	mov    %esi,%edx
  800287:	89 f8                	mov    %edi,%eax
  800289:	e8 9e ff ff ff       	call   80022c <printnum>
  80028e:	83 c4 20             	add    $0x20,%esp
  800291:	eb 18                	jmp    8002ab <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800293:	83 ec 08             	sub    $0x8,%esp
  800296:	56                   	push   %esi
  800297:	ff 75 18             	pushl  0x18(%ebp)
  80029a:	ff d7                	call   *%edi
  80029c:	83 c4 10             	add    $0x10,%esp
  80029f:	eb 03                	jmp    8002a4 <printnum+0x78>
  8002a1:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002a4:	83 eb 01             	sub    $0x1,%ebx
  8002a7:	85 db                	test   %ebx,%ebx
  8002a9:	7f e8                	jg     800293 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002ab:	83 ec 08             	sub    $0x8,%esp
  8002ae:	56                   	push   %esi
  8002af:	83 ec 04             	sub    $0x4,%esp
  8002b2:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002b5:	ff 75 e0             	pushl  -0x20(%ebp)
  8002b8:	ff 75 dc             	pushl  -0x24(%ebp)
  8002bb:	ff 75 d8             	pushl  -0x28(%ebp)
  8002be:	e8 5d 09 00 00       	call   800c20 <__umoddi3>
  8002c3:	83 c4 14             	add    $0x14,%esp
  8002c6:	0f be 80 de 0d 80 00 	movsbl 0x800dde(%eax),%eax
  8002cd:	50                   	push   %eax
  8002ce:	ff d7                	call   *%edi
}
  8002d0:	83 c4 10             	add    $0x10,%esp
  8002d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002d6:	5b                   	pop    %ebx
  8002d7:	5e                   	pop    %esi
  8002d8:	5f                   	pop    %edi
  8002d9:	5d                   	pop    %ebp
  8002da:	c3                   	ret    

008002db <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002db:	55                   	push   %ebp
  8002dc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002de:	83 fa 01             	cmp    $0x1,%edx
  8002e1:	7e 0e                	jle    8002f1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002e3:	8b 10                	mov    (%eax),%edx
  8002e5:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002e8:	89 08                	mov    %ecx,(%eax)
  8002ea:	8b 02                	mov    (%edx),%eax
  8002ec:	8b 52 04             	mov    0x4(%edx),%edx
  8002ef:	eb 22                	jmp    800313 <getuint+0x38>
	else if (lflag)
  8002f1:	85 d2                	test   %edx,%edx
  8002f3:	74 10                	je     800305 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002f5:	8b 10                	mov    (%eax),%edx
  8002f7:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002fa:	89 08                	mov    %ecx,(%eax)
  8002fc:	8b 02                	mov    (%edx),%eax
  8002fe:	ba 00 00 00 00       	mov    $0x0,%edx
  800303:	eb 0e                	jmp    800313 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800305:	8b 10                	mov    (%eax),%edx
  800307:	8d 4a 04             	lea    0x4(%edx),%ecx
  80030a:	89 08                	mov    %ecx,(%eax)
  80030c:	8b 02                	mov    (%edx),%eax
  80030e:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800313:	5d                   	pop    %ebp
  800314:	c3                   	ret    

00800315 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800315:	55                   	push   %ebp
  800316:	89 e5                	mov    %esp,%ebp
  800318:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80031b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  80031f:	8b 10                	mov    (%eax),%edx
  800321:	3b 50 04             	cmp    0x4(%eax),%edx
  800324:	73 0a                	jae    800330 <sprintputch+0x1b>
		*b->buf++ = ch;
  800326:	8d 4a 01             	lea    0x1(%edx),%ecx
  800329:	89 08                	mov    %ecx,(%eax)
  80032b:	8b 45 08             	mov    0x8(%ebp),%eax
  80032e:	88 02                	mov    %al,(%edx)
}
  800330:	5d                   	pop    %ebp
  800331:	c3                   	ret    

00800332 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800332:	55                   	push   %ebp
  800333:	89 e5                	mov    %esp,%ebp
  800335:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800338:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80033b:	50                   	push   %eax
  80033c:	ff 75 10             	pushl  0x10(%ebp)
  80033f:	ff 75 0c             	pushl  0xc(%ebp)
  800342:	ff 75 08             	pushl  0x8(%ebp)
  800345:	e8 05 00 00 00       	call   80034f <vprintfmt>
	va_end(ap);
}
  80034a:	83 c4 10             	add    $0x10,%esp
  80034d:	c9                   	leave  
  80034e:	c3                   	ret    

0080034f <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80034f:	55                   	push   %ebp
  800350:	89 e5                	mov    %esp,%ebp
  800352:	57                   	push   %edi
  800353:	56                   	push   %esi
  800354:	53                   	push   %ebx
  800355:	83 ec 2c             	sub    $0x2c,%esp
  800358:	8b 75 08             	mov    0x8(%ebp),%esi
  80035b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80035e:	8b 7d 10             	mov    0x10(%ebp),%edi
  800361:	eb 12                	jmp    800375 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800363:	85 c0                	test   %eax,%eax
  800365:	0f 84 89 03 00 00    	je     8006f4 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  80036b:	83 ec 08             	sub    $0x8,%esp
  80036e:	53                   	push   %ebx
  80036f:	50                   	push   %eax
  800370:	ff d6                	call   *%esi
  800372:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800375:	83 c7 01             	add    $0x1,%edi
  800378:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  80037c:	83 f8 25             	cmp    $0x25,%eax
  80037f:	75 e2                	jne    800363 <vprintfmt+0x14>
  800381:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  800385:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  80038c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800393:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  80039a:	ba 00 00 00 00       	mov    $0x0,%edx
  80039f:	eb 07                	jmp    8003a8 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a1:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8003a4:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a8:	8d 47 01             	lea    0x1(%edi),%eax
  8003ab:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003ae:	0f b6 07             	movzbl (%edi),%eax
  8003b1:	0f b6 c8             	movzbl %al,%ecx
  8003b4:	83 e8 23             	sub    $0x23,%eax
  8003b7:	3c 55                	cmp    $0x55,%al
  8003b9:	0f 87 1a 03 00 00    	ja     8006d9 <vprintfmt+0x38a>
  8003bf:	0f b6 c0             	movzbl %al,%eax
  8003c2:	ff 24 85 80 0e 80 00 	jmp    *0x800e80(,%eax,4)
  8003c9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003cc:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003d0:	eb d6                	jmp    8003a8 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003d5:	b8 00 00 00 00       	mov    $0x0,%eax
  8003da:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003dd:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003e0:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  8003e4:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  8003e7:	8d 51 d0             	lea    -0x30(%ecx),%edx
  8003ea:	83 fa 09             	cmp    $0x9,%edx
  8003ed:	77 39                	ja     800428 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003ef:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003f2:	eb e9                	jmp    8003dd <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003f4:	8b 45 14             	mov    0x14(%ebp),%eax
  8003f7:	8d 48 04             	lea    0x4(%eax),%ecx
  8003fa:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003fd:	8b 00                	mov    (%eax),%eax
  8003ff:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800402:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800405:	eb 27                	jmp    80042e <vprintfmt+0xdf>
  800407:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80040a:	85 c0                	test   %eax,%eax
  80040c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800411:	0f 49 c8             	cmovns %eax,%ecx
  800414:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800417:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80041a:	eb 8c                	jmp    8003a8 <vprintfmt+0x59>
  80041c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80041f:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800426:	eb 80                	jmp    8003a8 <vprintfmt+0x59>
  800428:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80042b:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  80042e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800432:	0f 89 70 ff ff ff    	jns    8003a8 <vprintfmt+0x59>
				width = precision, precision = -1;
  800438:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80043b:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80043e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800445:	e9 5e ff ff ff       	jmp    8003a8 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80044a:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80044d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800450:	e9 53 ff ff ff       	jmp    8003a8 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800455:	8b 45 14             	mov    0x14(%ebp),%eax
  800458:	8d 50 04             	lea    0x4(%eax),%edx
  80045b:	89 55 14             	mov    %edx,0x14(%ebp)
  80045e:	83 ec 08             	sub    $0x8,%esp
  800461:	53                   	push   %ebx
  800462:	ff 30                	pushl  (%eax)
  800464:	ff d6                	call   *%esi
			break;
  800466:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800469:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  80046c:	e9 04 ff ff ff       	jmp    800375 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800471:	8b 45 14             	mov    0x14(%ebp),%eax
  800474:	8d 50 04             	lea    0x4(%eax),%edx
  800477:	89 55 14             	mov    %edx,0x14(%ebp)
  80047a:	8b 00                	mov    (%eax),%eax
  80047c:	99                   	cltd   
  80047d:	31 d0                	xor    %edx,%eax
  80047f:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800481:	83 f8 07             	cmp    $0x7,%eax
  800484:	7f 0b                	jg     800491 <vprintfmt+0x142>
  800486:	8b 14 85 e0 0f 80 00 	mov    0x800fe0(,%eax,4),%edx
  80048d:	85 d2                	test   %edx,%edx
  80048f:	75 18                	jne    8004a9 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  800491:	50                   	push   %eax
  800492:	68 f6 0d 80 00       	push   $0x800df6
  800497:	53                   	push   %ebx
  800498:	56                   	push   %esi
  800499:	e8 94 fe ff ff       	call   800332 <printfmt>
  80049e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004a1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8004a4:	e9 cc fe ff ff       	jmp    800375 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8004a9:	52                   	push   %edx
  8004aa:	68 ff 0d 80 00       	push   $0x800dff
  8004af:	53                   	push   %ebx
  8004b0:	56                   	push   %esi
  8004b1:	e8 7c fe ff ff       	call   800332 <printfmt>
  8004b6:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004b9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004bc:	e9 b4 fe ff ff       	jmp    800375 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004c1:	8b 45 14             	mov    0x14(%ebp),%eax
  8004c4:	8d 50 04             	lea    0x4(%eax),%edx
  8004c7:	89 55 14             	mov    %edx,0x14(%ebp)
  8004ca:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004cc:	85 ff                	test   %edi,%edi
  8004ce:	b8 ef 0d 80 00       	mov    $0x800def,%eax
  8004d3:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004d6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004da:	0f 8e 94 00 00 00    	jle    800574 <vprintfmt+0x225>
  8004e0:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004e4:	0f 84 98 00 00 00    	je     800582 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004ea:	83 ec 08             	sub    $0x8,%esp
  8004ed:	ff 75 d0             	pushl  -0x30(%ebp)
  8004f0:	57                   	push   %edi
  8004f1:	e8 86 02 00 00       	call   80077c <strnlen>
  8004f6:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8004f9:	29 c1                	sub    %eax,%ecx
  8004fb:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  8004fe:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800501:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800505:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800508:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80050b:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80050d:	eb 0f                	jmp    80051e <vprintfmt+0x1cf>
					putch(padc, putdat);
  80050f:	83 ec 08             	sub    $0x8,%esp
  800512:	53                   	push   %ebx
  800513:	ff 75 e0             	pushl  -0x20(%ebp)
  800516:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800518:	83 ef 01             	sub    $0x1,%edi
  80051b:	83 c4 10             	add    $0x10,%esp
  80051e:	85 ff                	test   %edi,%edi
  800520:	7f ed                	jg     80050f <vprintfmt+0x1c0>
  800522:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800525:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  800528:	85 c9                	test   %ecx,%ecx
  80052a:	b8 00 00 00 00       	mov    $0x0,%eax
  80052f:	0f 49 c1             	cmovns %ecx,%eax
  800532:	29 c1                	sub    %eax,%ecx
  800534:	89 75 08             	mov    %esi,0x8(%ebp)
  800537:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80053a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80053d:	89 cb                	mov    %ecx,%ebx
  80053f:	eb 4d                	jmp    80058e <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800541:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800545:	74 1b                	je     800562 <vprintfmt+0x213>
  800547:	0f be c0             	movsbl %al,%eax
  80054a:	83 e8 20             	sub    $0x20,%eax
  80054d:	83 f8 5e             	cmp    $0x5e,%eax
  800550:	76 10                	jbe    800562 <vprintfmt+0x213>
					putch('?', putdat);
  800552:	83 ec 08             	sub    $0x8,%esp
  800555:	ff 75 0c             	pushl  0xc(%ebp)
  800558:	6a 3f                	push   $0x3f
  80055a:	ff 55 08             	call   *0x8(%ebp)
  80055d:	83 c4 10             	add    $0x10,%esp
  800560:	eb 0d                	jmp    80056f <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800562:	83 ec 08             	sub    $0x8,%esp
  800565:	ff 75 0c             	pushl  0xc(%ebp)
  800568:	52                   	push   %edx
  800569:	ff 55 08             	call   *0x8(%ebp)
  80056c:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80056f:	83 eb 01             	sub    $0x1,%ebx
  800572:	eb 1a                	jmp    80058e <vprintfmt+0x23f>
  800574:	89 75 08             	mov    %esi,0x8(%ebp)
  800577:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80057a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80057d:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800580:	eb 0c                	jmp    80058e <vprintfmt+0x23f>
  800582:	89 75 08             	mov    %esi,0x8(%ebp)
  800585:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800588:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  80058b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  80058e:	83 c7 01             	add    $0x1,%edi
  800591:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800595:	0f be d0             	movsbl %al,%edx
  800598:	85 d2                	test   %edx,%edx
  80059a:	74 23                	je     8005bf <vprintfmt+0x270>
  80059c:	85 f6                	test   %esi,%esi
  80059e:	78 a1                	js     800541 <vprintfmt+0x1f2>
  8005a0:	83 ee 01             	sub    $0x1,%esi
  8005a3:	79 9c                	jns    800541 <vprintfmt+0x1f2>
  8005a5:	89 df                	mov    %ebx,%edi
  8005a7:	8b 75 08             	mov    0x8(%ebp),%esi
  8005aa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005ad:	eb 18                	jmp    8005c7 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005af:	83 ec 08             	sub    $0x8,%esp
  8005b2:	53                   	push   %ebx
  8005b3:	6a 20                	push   $0x20
  8005b5:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005b7:	83 ef 01             	sub    $0x1,%edi
  8005ba:	83 c4 10             	add    $0x10,%esp
  8005bd:	eb 08                	jmp    8005c7 <vprintfmt+0x278>
  8005bf:	89 df                	mov    %ebx,%edi
  8005c1:	8b 75 08             	mov    0x8(%ebp),%esi
  8005c4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005c7:	85 ff                	test   %edi,%edi
  8005c9:	7f e4                	jg     8005af <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005cb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005ce:	e9 a2 fd ff ff       	jmp    800375 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005d3:	83 fa 01             	cmp    $0x1,%edx
  8005d6:	7e 16                	jle    8005ee <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  8005d8:	8b 45 14             	mov    0x14(%ebp),%eax
  8005db:	8d 50 08             	lea    0x8(%eax),%edx
  8005de:	89 55 14             	mov    %edx,0x14(%ebp)
  8005e1:	8b 50 04             	mov    0x4(%eax),%edx
  8005e4:	8b 00                	mov    (%eax),%eax
  8005e6:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005e9:	89 55 dc             	mov    %edx,-0x24(%ebp)
  8005ec:	eb 32                	jmp    800620 <vprintfmt+0x2d1>
	else if (lflag)
  8005ee:	85 d2                	test   %edx,%edx
  8005f0:	74 18                	je     80060a <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  8005f2:	8b 45 14             	mov    0x14(%ebp),%eax
  8005f5:	8d 50 04             	lea    0x4(%eax),%edx
  8005f8:	89 55 14             	mov    %edx,0x14(%ebp)
  8005fb:	8b 00                	mov    (%eax),%eax
  8005fd:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800600:	89 c1                	mov    %eax,%ecx
  800602:	c1 f9 1f             	sar    $0x1f,%ecx
  800605:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800608:	eb 16                	jmp    800620 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  80060a:	8b 45 14             	mov    0x14(%ebp),%eax
  80060d:	8d 50 04             	lea    0x4(%eax),%edx
  800610:	89 55 14             	mov    %edx,0x14(%ebp)
  800613:	8b 00                	mov    (%eax),%eax
  800615:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800618:	89 c1                	mov    %eax,%ecx
  80061a:	c1 f9 1f             	sar    $0x1f,%ecx
  80061d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800620:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800623:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800626:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  80062b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80062f:	79 74                	jns    8006a5 <vprintfmt+0x356>
				putch('-', putdat);
  800631:	83 ec 08             	sub    $0x8,%esp
  800634:	53                   	push   %ebx
  800635:	6a 2d                	push   $0x2d
  800637:	ff d6                	call   *%esi
				num = -(long long) num;
  800639:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80063c:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80063f:	f7 d8                	neg    %eax
  800641:	83 d2 00             	adc    $0x0,%edx
  800644:	f7 da                	neg    %edx
  800646:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800649:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80064e:	eb 55                	jmp    8006a5 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800650:	8d 45 14             	lea    0x14(%ebp),%eax
  800653:	e8 83 fc ff ff       	call   8002db <getuint>
			base = 10;
  800658:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80065d:	eb 46                	jmp    8006a5 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  80065f:	8d 45 14             	lea    0x14(%ebp),%eax
  800662:	e8 74 fc ff ff       	call   8002db <getuint>
			base = 8;
  800667:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80066c:	eb 37                	jmp    8006a5 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  80066e:	83 ec 08             	sub    $0x8,%esp
  800671:	53                   	push   %ebx
  800672:	6a 30                	push   $0x30
  800674:	ff d6                	call   *%esi
			putch('x', putdat);
  800676:	83 c4 08             	add    $0x8,%esp
  800679:	53                   	push   %ebx
  80067a:	6a 78                	push   $0x78
  80067c:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80067e:	8b 45 14             	mov    0x14(%ebp),%eax
  800681:	8d 50 04             	lea    0x4(%eax),%edx
  800684:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800687:	8b 00                	mov    (%eax),%eax
  800689:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  80068e:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800691:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800696:	eb 0d                	jmp    8006a5 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800698:	8d 45 14             	lea    0x14(%ebp),%eax
  80069b:	e8 3b fc ff ff       	call   8002db <getuint>
			base = 16;
  8006a0:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006a5:	83 ec 0c             	sub    $0xc,%esp
  8006a8:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8006ac:	57                   	push   %edi
  8006ad:	ff 75 e0             	pushl  -0x20(%ebp)
  8006b0:	51                   	push   %ecx
  8006b1:	52                   	push   %edx
  8006b2:	50                   	push   %eax
  8006b3:	89 da                	mov    %ebx,%edx
  8006b5:	89 f0                	mov    %esi,%eax
  8006b7:	e8 70 fb ff ff       	call   80022c <printnum>
			break;
  8006bc:	83 c4 20             	add    $0x20,%esp
  8006bf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006c2:	e9 ae fc ff ff       	jmp    800375 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006c7:	83 ec 08             	sub    $0x8,%esp
  8006ca:	53                   	push   %ebx
  8006cb:	51                   	push   %ecx
  8006cc:	ff d6                	call   *%esi
			break;
  8006ce:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006d1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006d4:	e9 9c fc ff ff       	jmp    800375 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006d9:	83 ec 08             	sub    $0x8,%esp
  8006dc:	53                   	push   %ebx
  8006dd:	6a 25                	push   $0x25
  8006df:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006e1:	83 c4 10             	add    $0x10,%esp
  8006e4:	eb 03                	jmp    8006e9 <vprintfmt+0x39a>
  8006e6:	83 ef 01             	sub    $0x1,%edi
  8006e9:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006ed:	75 f7                	jne    8006e6 <vprintfmt+0x397>
  8006ef:	e9 81 fc ff ff       	jmp    800375 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006f4:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006f7:	5b                   	pop    %ebx
  8006f8:	5e                   	pop    %esi
  8006f9:	5f                   	pop    %edi
  8006fa:	5d                   	pop    %ebp
  8006fb:	c3                   	ret    

008006fc <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006fc:	55                   	push   %ebp
  8006fd:	89 e5                	mov    %esp,%ebp
  8006ff:	83 ec 18             	sub    $0x18,%esp
  800702:	8b 45 08             	mov    0x8(%ebp),%eax
  800705:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800708:	89 45 ec             	mov    %eax,-0x14(%ebp)
  80070b:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80070f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800712:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800719:	85 c0                	test   %eax,%eax
  80071b:	74 26                	je     800743 <vsnprintf+0x47>
  80071d:	85 d2                	test   %edx,%edx
  80071f:	7e 22                	jle    800743 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800721:	ff 75 14             	pushl  0x14(%ebp)
  800724:	ff 75 10             	pushl  0x10(%ebp)
  800727:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80072a:	50                   	push   %eax
  80072b:	68 15 03 80 00       	push   $0x800315
  800730:	e8 1a fc ff ff       	call   80034f <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800735:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800738:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80073b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80073e:	83 c4 10             	add    $0x10,%esp
  800741:	eb 05                	jmp    800748 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800743:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800748:	c9                   	leave  
  800749:	c3                   	ret    

0080074a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80074a:	55                   	push   %ebp
  80074b:	89 e5                	mov    %esp,%ebp
  80074d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800750:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800753:	50                   	push   %eax
  800754:	ff 75 10             	pushl  0x10(%ebp)
  800757:	ff 75 0c             	pushl  0xc(%ebp)
  80075a:	ff 75 08             	pushl  0x8(%ebp)
  80075d:	e8 9a ff ff ff       	call   8006fc <vsnprintf>
	va_end(ap);

	return rc;
}
  800762:	c9                   	leave  
  800763:	c3                   	ret    

00800764 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800764:	55                   	push   %ebp
  800765:	89 e5                	mov    %esp,%ebp
  800767:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80076a:	b8 00 00 00 00       	mov    $0x0,%eax
  80076f:	eb 03                	jmp    800774 <strlen+0x10>
		n++;
  800771:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800774:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800778:	75 f7                	jne    800771 <strlen+0xd>
		n++;
	return n;
}
  80077a:	5d                   	pop    %ebp
  80077b:	c3                   	ret    

0080077c <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80077c:	55                   	push   %ebp
  80077d:	89 e5                	mov    %esp,%ebp
  80077f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800782:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800785:	ba 00 00 00 00       	mov    $0x0,%edx
  80078a:	eb 03                	jmp    80078f <strnlen+0x13>
		n++;
  80078c:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80078f:	39 c2                	cmp    %eax,%edx
  800791:	74 08                	je     80079b <strnlen+0x1f>
  800793:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800797:	75 f3                	jne    80078c <strnlen+0x10>
  800799:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80079b:	5d                   	pop    %ebp
  80079c:	c3                   	ret    

0080079d <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80079d:	55                   	push   %ebp
  80079e:	89 e5                	mov    %esp,%ebp
  8007a0:	53                   	push   %ebx
  8007a1:	8b 45 08             	mov    0x8(%ebp),%eax
  8007a4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007a7:	89 c2                	mov    %eax,%edx
  8007a9:	83 c2 01             	add    $0x1,%edx
  8007ac:	83 c1 01             	add    $0x1,%ecx
  8007af:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007b3:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007b6:	84 db                	test   %bl,%bl
  8007b8:	75 ef                	jne    8007a9 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007ba:	5b                   	pop    %ebx
  8007bb:	5d                   	pop    %ebp
  8007bc:	c3                   	ret    

008007bd <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007bd:	55                   	push   %ebp
  8007be:	89 e5                	mov    %esp,%ebp
  8007c0:	53                   	push   %ebx
  8007c1:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007c4:	53                   	push   %ebx
  8007c5:	e8 9a ff ff ff       	call   800764 <strlen>
  8007ca:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007cd:	ff 75 0c             	pushl  0xc(%ebp)
  8007d0:	01 d8                	add    %ebx,%eax
  8007d2:	50                   	push   %eax
  8007d3:	e8 c5 ff ff ff       	call   80079d <strcpy>
	return dst;
}
  8007d8:	89 d8                	mov    %ebx,%eax
  8007da:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007dd:	c9                   	leave  
  8007de:	c3                   	ret    

008007df <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007df:	55                   	push   %ebp
  8007e0:	89 e5                	mov    %esp,%ebp
  8007e2:	56                   	push   %esi
  8007e3:	53                   	push   %ebx
  8007e4:	8b 75 08             	mov    0x8(%ebp),%esi
  8007e7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007ea:	89 f3                	mov    %esi,%ebx
  8007ec:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007ef:	89 f2                	mov    %esi,%edx
  8007f1:	eb 0f                	jmp    800802 <strncpy+0x23>
		*dst++ = *src;
  8007f3:	83 c2 01             	add    $0x1,%edx
  8007f6:	0f b6 01             	movzbl (%ecx),%eax
  8007f9:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007fc:	80 39 01             	cmpb   $0x1,(%ecx)
  8007ff:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800802:	39 da                	cmp    %ebx,%edx
  800804:	75 ed                	jne    8007f3 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800806:	89 f0                	mov    %esi,%eax
  800808:	5b                   	pop    %ebx
  800809:	5e                   	pop    %esi
  80080a:	5d                   	pop    %ebp
  80080b:	c3                   	ret    

0080080c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80080c:	55                   	push   %ebp
  80080d:	89 e5                	mov    %esp,%ebp
  80080f:	56                   	push   %esi
  800810:	53                   	push   %ebx
  800811:	8b 75 08             	mov    0x8(%ebp),%esi
  800814:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800817:	8b 55 10             	mov    0x10(%ebp),%edx
  80081a:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80081c:	85 d2                	test   %edx,%edx
  80081e:	74 21                	je     800841 <strlcpy+0x35>
  800820:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800824:	89 f2                	mov    %esi,%edx
  800826:	eb 09                	jmp    800831 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800828:	83 c2 01             	add    $0x1,%edx
  80082b:	83 c1 01             	add    $0x1,%ecx
  80082e:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800831:	39 c2                	cmp    %eax,%edx
  800833:	74 09                	je     80083e <strlcpy+0x32>
  800835:	0f b6 19             	movzbl (%ecx),%ebx
  800838:	84 db                	test   %bl,%bl
  80083a:	75 ec                	jne    800828 <strlcpy+0x1c>
  80083c:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80083e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800841:	29 f0                	sub    %esi,%eax
}
  800843:	5b                   	pop    %ebx
  800844:	5e                   	pop    %esi
  800845:	5d                   	pop    %ebp
  800846:	c3                   	ret    

00800847 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800847:	55                   	push   %ebp
  800848:	89 e5                	mov    %esp,%ebp
  80084a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80084d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800850:	eb 06                	jmp    800858 <strcmp+0x11>
		p++, q++;
  800852:	83 c1 01             	add    $0x1,%ecx
  800855:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800858:	0f b6 01             	movzbl (%ecx),%eax
  80085b:	84 c0                	test   %al,%al
  80085d:	74 04                	je     800863 <strcmp+0x1c>
  80085f:	3a 02                	cmp    (%edx),%al
  800861:	74 ef                	je     800852 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800863:	0f b6 c0             	movzbl %al,%eax
  800866:	0f b6 12             	movzbl (%edx),%edx
  800869:	29 d0                	sub    %edx,%eax
}
  80086b:	5d                   	pop    %ebp
  80086c:	c3                   	ret    

0080086d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80086d:	55                   	push   %ebp
  80086e:	89 e5                	mov    %esp,%ebp
  800870:	53                   	push   %ebx
  800871:	8b 45 08             	mov    0x8(%ebp),%eax
  800874:	8b 55 0c             	mov    0xc(%ebp),%edx
  800877:	89 c3                	mov    %eax,%ebx
  800879:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80087c:	eb 06                	jmp    800884 <strncmp+0x17>
		n--, p++, q++;
  80087e:	83 c0 01             	add    $0x1,%eax
  800881:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800884:	39 d8                	cmp    %ebx,%eax
  800886:	74 15                	je     80089d <strncmp+0x30>
  800888:	0f b6 08             	movzbl (%eax),%ecx
  80088b:	84 c9                	test   %cl,%cl
  80088d:	74 04                	je     800893 <strncmp+0x26>
  80088f:	3a 0a                	cmp    (%edx),%cl
  800891:	74 eb                	je     80087e <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800893:	0f b6 00             	movzbl (%eax),%eax
  800896:	0f b6 12             	movzbl (%edx),%edx
  800899:	29 d0                	sub    %edx,%eax
  80089b:	eb 05                	jmp    8008a2 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80089d:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008a2:	5b                   	pop    %ebx
  8008a3:	5d                   	pop    %ebp
  8008a4:	c3                   	ret    

008008a5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008a5:	55                   	push   %ebp
  8008a6:	89 e5                	mov    %esp,%ebp
  8008a8:	8b 45 08             	mov    0x8(%ebp),%eax
  8008ab:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008af:	eb 07                	jmp    8008b8 <strchr+0x13>
		if (*s == c)
  8008b1:	38 ca                	cmp    %cl,%dl
  8008b3:	74 0f                	je     8008c4 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008b5:	83 c0 01             	add    $0x1,%eax
  8008b8:	0f b6 10             	movzbl (%eax),%edx
  8008bb:	84 d2                	test   %dl,%dl
  8008bd:	75 f2                	jne    8008b1 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008bf:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008c4:	5d                   	pop    %ebp
  8008c5:	c3                   	ret    

008008c6 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008c6:	55                   	push   %ebp
  8008c7:	89 e5                	mov    %esp,%ebp
  8008c9:	8b 45 08             	mov    0x8(%ebp),%eax
  8008cc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008d0:	eb 03                	jmp    8008d5 <strfind+0xf>
  8008d2:	83 c0 01             	add    $0x1,%eax
  8008d5:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008d8:	38 ca                	cmp    %cl,%dl
  8008da:	74 04                	je     8008e0 <strfind+0x1a>
  8008dc:	84 d2                	test   %dl,%dl
  8008de:	75 f2                	jne    8008d2 <strfind+0xc>
			break;
	return (char *) s;
}
  8008e0:	5d                   	pop    %ebp
  8008e1:	c3                   	ret    

008008e2 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008e2:	55                   	push   %ebp
  8008e3:	89 e5                	mov    %esp,%ebp
  8008e5:	57                   	push   %edi
  8008e6:	56                   	push   %esi
  8008e7:	53                   	push   %ebx
  8008e8:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008eb:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008ee:	85 c9                	test   %ecx,%ecx
  8008f0:	74 36                	je     800928 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008f2:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008f8:	75 28                	jne    800922 <memset+0x40>
  8008fa:	f6 c1 03             	test   $0x3,%cl
  8008fd:	75 23                	jne    800922 <memset+0x40>
		c &= 0xFF;
  8008ff:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800903:	89 d3                	mov    %edx,%ebx
  800905:	c1 e3 08             	shl    $0x8,%ebx
  800908:	89 d6                	mov    %edx,%esi
  80090a:	c1 e6 18             	shl    $0x18,%esi
  80090d:	89 d0                	mov    %edx,%eax
  80090f:	c1 e0 10             	shl    $0x10,%eax
  800912:	09 f0                	or     %esi,%eax
  800914:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800916:	89 d8                	mov    %ebx,%eax
  800918:	09 d0                	or     %edx,%eax
  80091a:	c1 e9 02             	shr    $0x2,%ecx
  80091d:	fc                   	cld    
  80091e:	f3 ab                	rep stos %eax,%es:(%edi)
  800920:	eb 06                	jmp    800928 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800922:	8b 45 0c             	mov    0xc(%ebp),%eax
  800925:	fc                   	cld    
  800926:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800928:	89 f8                	mov    %edi,%eax
  80092a:	5b                   	pop    %ebx
  80092b:	5e                   	pop    %esi
  80092c:	5f                   	pop    %edi
  80092d:	5d                   	pop    %ebp
  80092e:	c3                   	ret    

0080092f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80092f:	55                   	push   %ebp
  800930:	89 e5                	mov    %esp,%ebp
  800932:	57                   	push   %edi
  800933:	56                   	push   %esi
  800934:	8b 45 08             	mov    0x8(%ebp),%eax
  800937:	8b 75 0c             	mov    0xc(%ebp),%esi
  80093a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80093d:	39 c6                	cmp    %eax,%esi
  80093f:	73 35                	jae    800976 <memmove+0x47>
  800941:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800944:	39 d0                	cmp    %edx,%eax
  800946:	73 2e                	jae    800976 <memmove+0x47>
		s += n;
		d += n;
  800948:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80094b:	89 d6                	mov    %edx,%esi
  80094d:	09 fe                	or     %edi,%esi
  80094f:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800955:	75 13                	jne    80096a <memmove+0x3b>
  800957:	f6 c1 03             	test   $0x3,%cl
  80095a:	75 0e                	jne    80096a <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80095c:	83 ef 04             	sub    $0x4,%edi
  80095f:	8d 72 fc             	lea    -0x4(%edx),%esi
  800962:	c1 e9 02             	shr    $0x2,%ecx
  800965:	fd                   	std    
  800966:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800968:	eb 09                	jmp    800973 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80096a:	83 ef 01             	sub    $0x1,%edi
  80096d:	8d 72 ff             	lea    -0x1(%edx),%esi
  800970:	fd                   	std    
  800971:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800973:	fc                   	cld    
  800974:	eb 1d                	jmp    800993 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800976:	89 f2                	mov    %esi,%edx
  800978:	09 c2                	or     %eax,%edx
  80097a:	f6 c2 03             	test   $0x3,%dl
  80097d:	75 0f                	jne    80098e <memmove+0x5f>
  80097f:	f6 c1 03             	test   $0x3,%cl
  800982:	75 0a                	jne    80098e <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800984:	c1 e9 02             	shr    $0x2,%ecx
  800987:	89 c7                	mov    %eax,%edi
  800989:	fc                   	cld    
  80098a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80098c:	eb 05                	jmp    800993 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  80098e:	89 c7                	mov    %eax,%edi
  800990:	fc                   	cld    
  800991:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800993:	5e                   	pop    %esi
  800994:	5f                   	pop    %edi
  800995:	5d                   	pop    %ebp
  800996:	c3                   	ret    

00800997 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800997:	55                   	push   %ebp
  800998:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  80099a:	ff 75 10             	pushl  0x10(%ebp)
  80099d:	ff 75 0c             	pushl  0xc(%ebp)
  8009a0:	ff 75 08             	pushl  0x8(%ebp)
  8009a3:	e8 87 ff ff ff       	call   80092f <memmove>
}
  8009a8:	c9                   	leave  
  8009a9:	c3                   	ret    

008009aa <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009aa:	55                   	push   %ebp
  8009ab:	89 e5                	mov    %esp,%ebp
  8009ad:	56                   	push   %esi
  8009ae:	53                   	push   %ebx
  8009af:	8b 45 08             	mov    0x8(%ebp),%eax
  8009b2:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009b5:	89 c6                	mov    %eax,%esi
  8009b7:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009ba:	eb 1a                	jmp    8009d6 <memcmp+0x2c>
		if (*s1 != *s2)
  8009bc:	0f b6 08             	movzbl (%eax),%ecx
  8009bf:	0f b6 1a             	movzbl (%edx),%ebx
  8009c2:	38 d9                	cmp    %bl,%cl
  8009c4:	74 0a                	je     8009d0 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009c6:	0f b6 c1             	movzbl %cl,%eax
  8009c9:	0f b6 db             	movzbl %bl,%ebx
  8009cc:	29 d8                	sub    %ebx,%eax
  8009ce:	eb 0f                	jmp    8009df <memcmp+0x35>
		s1++, s2++;
  8009d0:	83 c0 01             	add    $0x1,%eax
  8009d3:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009d6:	39 f0                	cmp    %esi,%eax
  8009d8:	75 e2                	jne    8009bc <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009da:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009df:	5b                   	pop    %ebx
  8009e0:	5e                   	pop    %esi
  8009e1:	5d                   	pop    %ebp
  8009e2:	c3                   	ret    

008009e3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009e3:	55                   	push   %ebp
  8009e4:	89 e5                	mov    %esp,%ebp
  8009e6:	53                   	push   %ebx
  8009e7:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8009ea:	89 c1                	mov    %eax,%ecx
  8009ec:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8009ef:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009f3:	eb 0a                	jmp    8009ff <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009f5:	0f b6 10             	movzbl (%eax),%edx
  8009f8:	39 da                	cmp    %ebx,%edx
  8009fa:	74 07                	je     800a03 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009fc:	83 c0 01             	add    $0x1,%eax
  8009ff:	39 c8                	cmp    %ecx,%eax
  800a01:	72 f2                	jb     8009f5 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a03:	5b                   	pop    %ebx
  800a04:	5d                   	pop    %ebp
  800a05:	c3                   	ret    

00800a06 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a06:	55                   	push   %ebp
  800a07:	89 e5                	mov    %esp,%ebp
  800a09:	57                   	push   %edi
  800a0a:	56                   	push   %esi
  800a0b:	53                   	push   %ebx
  800a0c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a0f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a12:	eb 03                	jmp    800a17 <strtol+0x11>
		s++;
  800a14:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a17:	0f b6 01             	movzbl (%ecx),%eax
  800a1a:	3c 20                	cmp    $0x20,%al
  800a1c:	74 f6                	je     800a14 <strtol+0xe>
  800a1e:	3c 09                	cmp    $0x9,%al
  800a20:	74 f2                	je     800a14 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a22:	3c 2b                	cmp    $0x2b,%al
  800a24:	75 0a                	jne    800a30 <strtol+0x2a>
		s++;
  800a26:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a29:	bf 00 00 00 00       	mov    $0x0,%edi
  800a2e:	eb 11                	jmp    800a41 <strtol+0x3b>
  800a30:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a35:	3c 2d                	cmp    $0x2d,%al
  800a37:	75 08                	jne    800a41 <strtol+0x3b>
		s++, neg = 1;
  800a39:	83 c1 01             	add    $0x1,%ecx
  800a3c:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a41:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a47:	75 15                	jne    800a5e <strtol+0x58>
  800a49:	80 39 30             	cmpb   $0x30,(%ecx)
  800a4c:	75 10                	jne    800a5e <strtol+0x58>
  800a4e:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a52:	75 7c                	jne    800ad0 <strtol+0xca>
		s += 2, base = 16;
  800a54:	83 c1 02             	add    $0x2,%ecx
  800a57:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a5c:	eb 16                	jmp    800a74 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a5e:	85 db                	test   %ebx,%ebx
  800a60:	75 12                	jne    800a74 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a62:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a67:	80 39 30             	cmpb   $0x30,(%ecx)
  800a6a:	75 08                	jne    800a74 <strtol+0x6e>
		s++, base = 8;
  800a6c:	83 c1 01             	add    $0x1,%ecx
  800a6f:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a74:	b8 00 00 00 00       	mov    $0x0,%eax
  800a79:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a7c:	0f b6 11             	movzbl (%ecx),%edx
  800a7f:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a82:	89 f3                	mov    %esi,%ebx
  800a84:	80 fb 09             	cmp    $0x9,%bl
  800a87:	77 08                	ja     800a91 <strtol+0x8b>
			dig = *s - '0';
  800a89:	0f be d2             	movsbl %dl,%edx
  800a8c:	83 ea 30             	sub    $0x30,%edx
  800a8f:	eb 22                	jmp    800ab3 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a91:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a94:	89 f3                	mov    %esi,%ebx
  800a96:	80 fb 19             	cmp    $0x19,%bl
  800a99:	77 08                	ja     800aa3 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a9b:	0f be d2             	movsbl %dl,%edx
  800a9e:	83 ea 57             	sub    $0x57,%edx
  800aa1:	eb 10                	jmp    800ab3 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800aa3:	8d 72 bf             	lea    -0x41(%edx),%esi
  800aa6:	89 f3                	mov    %esi,%ebx
  800aa8:	80 fb 19             	cmp    $0x19,%bl
  800aab:	77 16                	ja     800ac3 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800aad:	0f be d2             	movsbl %dl,%edx
  800ab0:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800ab3:	3b 55 10             	cmp    0x10(%ebp),%edx
  800ab6:	7d 0b                	jge    800ac3 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800ab8:	83 c1 01             	add    $0x1,%ecx
  800abb:	0f af 45 10          	imul   0x10(%ebp),%eax
  800abf:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800ac1:	eb b9                	jmp    800a7c <strtol+0x76>

	if (endptr)
  800ac3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ac7:	74 0d                	je     800ad6 <strtol+0xd0>
		*endptr = (char *) s;
  800ac9:	8b 75 0c             	mov    0xc(%ebp),%esi
  800acc:	89 0e                	mov    %ecx,(%esi)
  800ace:	eb 06                	jmp    800ad6 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ad0:	85 db                	test   %ebx,%ebx
  800ad2:	74 98                	je     800a6c <strtol+0x66>
  800ad4:	eb 9e                	jmp    800a74 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800ad6:	89 c2                	mov    %eax,%edx
  800ad8:	f7 da                	neg    %edx
  800ada:	85 ff                	test   %edi,%edi
  800adc:	0f 45 c2             	cmovne %edx,%eax
}
  800adf:	5b                   	pop    %ebx
  800ae0:	5e                   	pop    %esi
  800ae1:	5f                   	pop    %edi
  800ae2:	5d                   	pop    %ebp
  800ae3:	c3                   	ret    
  800ae4:	66 90                	xchg   %ax,%ax
  800ae6:	66 90                	xchg   %ax,%ax
  800ae8:	66 90                	xchg   %ax,%ax
  800aea:	66 90                	xchg   %ax,%ax
  800aec:	66 90                	xchg   %ax,%ax
  800aee:	66 90                	xchg   %ax,%ax

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

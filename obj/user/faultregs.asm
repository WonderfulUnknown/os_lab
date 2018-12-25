
obj/user/faultregs：     文件格式 elf32-i386


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
  80002c:	e8 60 05 00 00       	call   800591 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <check_regs>:
static struct regs before, during, after;

static void
check_regs(struct regs* a, const char *an, struct regs* b, const char *bn,
	   const char *testname)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	57                   	push   %edi
  800037:	56                   	push   %esi
  800038:	53                   	push   %ebx
  800039:	83 ec 0c             	sub    $0xc,%esp
  80003c:	89 c6                	mov    %eax,%esi
  80003e:	89 cb                	mov    %ecx,%ebx
	int mismatch = 0;

	cprintf("%-6s %-8s %-8s\n", "", an, bn);
  800040:	ff 75 08             	pushl  0x8(%ebp)
  800043:	52                   	push   %edx
  800044:	68 f1 14 80 00       	push   $0x8014f1
  800049:	68 c0 14 80 00       	push   $0x8014c0
  80004e:	e8 6f 06 00 00       	call   8006c2 <cprintf>
			cprintf("MISMATCH\n");				\
			mismatch = 1;					\
		}							\
	} while (0)

	CHECK(edi, regs.reg_edi);
  800053:	ff 33                	pushl  (%ebx)
  800055:	ff 36                	pushl  (%esi)
  800057:	68 d0 14 80 00       	push   $0x8014d0
  80005c:	68 d4 14 80 00       	push   $0x8014d4
  800061:	e8 5c 06 00 00       	call   8006c2 <cprintf>
  800066:	83 c4 20             	add    $0x20,%esp
  800069:	8b 03                	mov    (%ebx),%eax
  80006b:	39 06                	cmp    %eax,(%esi)
  80006d:	75 17                	jne    800086 <check_regs+0x53>
  80006f:	83 ec 0c             	sub    $0xc,%esp
  800072:	68 e4 14 80 00       	push   $0x8014e4
  800077:	e8 46 06 00 00       	call   8006c2 <cprintf>
  80007c:	83 c4 10             	add    $0x10,%esp

static void
check_regs(struct regs* a, const char *an, struct regs* b, const char *bn,
	   const char *testname)
{
	int mismatch = 0;
  80007f:	bf 00 00 00 00       	mov    $0x0,%edi
  800084:	eb 15                	jmp    80009b <check_regs+0x68>
			cprintf("MISMATCH\n");				\
			mismatch = 1;					\
		}							\
	} while (0)

	CHECK(edi, regs.reg_edi);
  800086:	83 ec 0c             	sub    $0xc,%esp
  800089:	68 e8 14 80 00       	push   $0x8014e8
  80008e:	e8 2f 06 00 00       	call   8006c2 <cprintf>
  800093:	83 c4 10             	add    $0x10,%esp
  800096:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(esi, regs.reg_esi);
  80009b:	ff 73 04             	pushl  0x4(%ebx)
  80009e:	ff 76 04             	pushl  0x4(%esi)
  8000a1:	68 f2 14 80 00       	push   $0x8014f2
  8000a6:	68 d4 14 80 00       	push   $0x8014d4
  8000ab:	e8 12 06 00 00       	call   8006c2 <cprintf>
  8000b0:	83 c4 10             	add    $0x10,%esp
  8000b3:	8b 43 04             	mov    0x4(%ebx),%eax
  8000b6:	39 46 04             	cmp    %eax,0x4(%esi)
  8000b9:	75 12                	jne    8000cd <check_regs+0x9a>
  8000bb:	83 ec 0c             	sub    $0xc,%esp
  8000be:	68 e4 14 80 00       	push   $0x8014e4
  8000c3:	e8 fa 05 00 00       	call   8006c2 <cprintf>
  8000c8:	83 c4 10             	add    $0x10,%esp
  8000cb:	eb 15                	jmp    8000e2 <check_regs+0xaf>
  8000cd:	83 ec 0c             	sub    $0xc,%esp
  8000d0:	68 e8 14 80 00       	push   $0x8014e8
  8000d5:	e8 e8 05 00 00       	call   8006c2 <cprintf>
  8000da:	83 c4 10             	add    $0x10,%esp
  8000dd:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(ebp, regs.reg_ebp);
  8000e2:	ff 73 08             	pushl  0x8(%ebx)
  8000e5:	ff 76 08             	pushl  0x8(%esi)
  8000e8:	68 f6 14 80 00       	push   $0x8014f6
  8000ed:	68 d4 14 80 00       	push   $0x8014d4
  8000f2:	e8 cb 05 00 00       	call   8006c2 <cprintf>
  8000f7:	83 c4 10             	add    $0x10,%esp
  8000fa:	8b 43 08             	mov    0x8(%ebx),%eax
  8000fd:	39 46 08             	cmp    %eax,0x8(%esi)
  800100:	75 12                	jne    800114 <check_regs+0xe1>
  800102:	83 ec 0c             	sub    $0xc,%esp
  800105:	68 e4 14 80 00       	push   $0x8014e4
  80010a:	e8 b3 05 00 00       	call   8006c2 <cprintf>
  80010f:	83 c4 10             	add    $0x10,%esp
  800112:	eb 15                	jmp    800129 <check_regs+0xf6>
  800114:	83 ec 0c             	sub    $0xc,%esp
  800117:	68 e8 14 80 00       	push   $0x8014e8
  80011c:	e8 a1 05 00 00       	call   8006c2 <cprintf>
  800121:	83 c4 10             	add    $0x10,%esp
  800124:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(ebx, regs.reg_ebx);
  800129:	ff 73 10             	pushl  0x10(%ebx)
  80012c:	ff 76 10             	pushl  0x10(%esi)
  80012f:	68 fa 14 80 00       	push   $0x8014fa
  800134:	68 d4 14 80 00       	push   $0x8014d4
  800139:	e8 84 05 00 00       	call   8006c2 <cprintf>
  80013e:	83 c4 10             	add    $0x10,%esp
  800141:	8b 43 10             	mov    0x10(%ebx),%eax
  800144:	39 46 10             	cmp    %eax,0x10(%esi)
  800147:	75 12                	jne    80015b <check_regs+0x128>
  800149:	83 ec 0c             	sub    $0xc,%esp
  80014c:	68 e4 14 80 00       	push   $0x8014e4
  800151:	e8 6c 05 00 00       	call   8006c2 <cprintf>
  800156:	83 c4 10             	add    $0x10,%esp
  800159:	eb 15                	jmp    800170 <check_regs+0x13d>
  80015b:	83 ec 0c             	sub    $0xc,%esp
  80015e:	68 e8 14 80 00       	push   $0x8014e8
  800163:	e8 5a 05 00 00       	call   8006c2 <cprintf>
  800168:	83 c4 10             	add    $0x10,%esp
  80016b:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(edx, regs.reg_edx);
  800170:	ff 73 14             	pushl  0x14(%ebx)
  800173:	ff 76 14             	pushl  0x14(%esi)
  800176:	68 fe 14 80 00       	push   $0x8014fe
  80017b:	68 d4 14 80 00       	push   $0x8014d4
  800180:	e8 3d 05 00 00       	call   8006c2 <cprintf>
  800185:	83 c4 10             	add    $0x10,%esp
  800188:	8b 43 14             	mov    0x14(%ebx),%eax
  80018b:	39 46 14             	cmp    %eax,0x14(%esi)
  80018e:	75 12                	jne    8001a2 <check_regs+0x16f>
  800190:	83 ec 0c             	sub    $0xc,%esp
  800193:	68 e4 14 80 00       	push   $0x8014e4
  800198:	e8 25 05 00 00       	call   8006c2 <cprintf>
  80019d:	83 c4 10             	add    $0x10,%esp
  8001a0:	eb 15                	jmp    8001b7 <check_regs+0x184>
  8001a2:	83 ec 0c             	sub    $0xc,%esp
  8001a5:	68 e8 14 80 00       	push   $0x8014e8
  8001aa:	e8 13 05 00 00       	call   8006c2 <cprintf>
  8001af:	83 c4 10             	add    $0x10,%esp
  8001b2:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(ecx, regs.reg_ecx);
  8001b7:	ff 73 18             	pushl  0x18(%ebx)
  8001ba:	ff 76 18             	pushl  0x18(%esi)
  8001bd:	68 02 15 80 00       	push   $0x801502
  8001c2:	68 d4 14 80 00       	push   $0x8014d4
  8001c7:	e8 f6 04 00 00       	call   8006c2 <cprintf>
  8001cc:	83 c4 10             	add    $0x10,%esp
  8001cf:	8b 43 18             	mov    0x18(%ebx),%eax
  8001d2:	39 46 18             	cmp    %eax,0x18(%esi)
  8001d5:	75 12                	jne    8001e9 <check_regs+0x1b6>
  8001d7:	83 ec 0c             	sub    $0xc,%esp
  8001da:	68 e4 14 80 00       	push   $0x8014e4
  8001df:	e8 de 04 00 00       	call   8006c2 <cprintf>
  8001e4:	83 c4 10             	add    $0x10,%esp
  8001e7:	eb 15                	jmp    8001fe <check_regs+0x1cb>
  8001e9:	83 ec 0c             	sub    $0xc,%esp
  8001ec:	68 e8 14 80 00       	push   $0x8014e8
  8001f1:	e8 cc 04 00 00       	call   8006c2 <cprintf>
  8001f6:	83 c4 10             	add    $0x10,%esp
  8001f9:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(eax, regs.reg_eax);
  8001fe:	ff 73 1c             	pushl  0x1c(%ebx)
  800201:	ff 76 1c             	pushl  0x1c(%esi)
  800204:	68 06 15 80 00       	push   $0x801506
  800209:	68 d4 14 80 00       	push   $0x8014d4
  80020e:	e8 af 04 00 00       	call   8006c2 <cprintf>
  800213:	83 c4 10             	add    $0x10,%esp
  800216:	8b 43 1c             	mov    0x1c(%ebx),%eax
  800219:	39 46 1c             	cmp    %eax,0x1c(%esi)
  80021c:	75 12                	jne    800230 <check_regs+0x1fd>
  80021e:	83 ec 0c             	sub    $0xc,%esp
  800221:	68 e4 14 80 00       	push   $0x8014e4
  800226:	e8 97 04 00 00       	call   8006c2 <cprintf>
  80022b:	83 c4 10             	add    $0x10,%esp
  80022e:	eb 15                	jmp    800245 <check_regs+0x212>
  800230:	83 ec 0c             	sub    $0xc,%esp
  800233:	68 e8 14 80 00       	push   $0x8014e8
  800238:	e8 85 04 00 00       	call   8006c2 <cprintf>
  80023d:	83 c4 10             	add    $0x10,%esp
  800240:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(eip, eip);
  800245:	ff 73 20             	pushl  0x20(%ebx)
  800248:	ff 76 20             	pushl  0x20(%esi)
  80024b:	68 0a 15 80 00       	push   $0x80150a
  800250:	68 d4 14 80 00       	push   $0x8014d4
  800255:	e8 68 04 00 00       	call   8006c2 <cprintf>
  80025a:	83 c4 10             	add    $0x10,%esp
  80025d:	8b 43 20             	mov    0x20(%ebx),%eax
  800260:	39 46 20             	cmp    %eax,0x20(%esi)
  800263:	75 12                	jne    800277 <check_regs+0x244>
  800265:	83 ec 0c             	sub    $0xc,%esp
  800268:	68 e4 14 80 00       	push   $0x8014e4
  80026d:	e8 50 04 00 00       	call   8006c2 <cprintf>
  800272:	83 c4 10             	add    $0x10,%esp
  800275:	eb 15                	jmp    80028c <check_regs+0x259>
  800277:	83 ec 0c             	sub    $0xc,%esp
  80027a:	68 e8 14 80 00       	push   $0x8014e8
  80027f:	e8 3e 04 00 00       	call   8006c2 <cprintf>
  800284:	83 c4 10             	add    $0x10,%esp
  800287:	bf 01 00 00 00       	mov    $0x1,%edi
	CHECK(eflags, eflags);
  80028c:	ff 73 24             	pushl  0x24(%ebx)
  80028f:	ff 76 24             	pushl  0x24(%esi)
  800292:	68 0e 15 80 00       	push   $0x80150e
  800297:	68 d4 14 80 00       	push   $0x8014d4
  80029c:	e8 21 04 00 00       	call   8006c2 <cprintf>
  8002a1:	83 c4 10             	add    $0x10,%esp
  8002a4:	8b 43 24             	mov    0x24(%ebx),%eax
  8002a7:	39 46 24             	cmp    %eax,0x24(%esi)
  8002aa:	75 2f                	jne    8002db <check_regs+0x2a8>
  8002ac:	83 ec 0c             	sub    $0xc,%esp
  8002af:	68 e4 14 80 00       	push   $0x8014e4
  8002b4:	e8 09 04 00 00       	call   8006c2 <cprintf>
	CHECK(esp, esp);
  8002b9:	ff 73 28             	pushl  0x28(%ebx)
  8002bc:	ff 76 28             	pushl  0x28(%esi)
  8002bf:	68 15 15 80 00       	push   $0x801515
  8002c4:	68 d4 14 80 00       	push   $0x8014d4
  8002c9:	e8 f4 03 00 00       	call   8006c2 <cprintf>
  8002ce:	83 c4 20             	add    $0x20,%esp
  8002d1:	8b 43 28             	mov    0x28(%ebx),%eax
  8002d4:	39 46 28             	cmp    %eax,0x28(%esi)
  8002d7:	74 31                	je     80030a <check_regs+0x2d7>
  8002d9:	eb 55                	jmp    800330 <check_regs+0x2fd>
	CHECK(ebx, regs.reg_ebx);
	CHECK(edx, regs.reg_edx);
	CHECK(ecx, regs.reg_ecx);
	CHECK(eax, regs.reg_eax);
	CHECK(eip, eip);
	CHECK(eflags, eflags);
  8002db:	83 ec 0c             	sub    $0xc,%esp
  8002de:	68 e8 14 80 00       	push   $0x8014e8
  8002e3:	e8 da 03 00 00       	call   8006c2 <cprintf>
	CHECK(esp, esp);
  8002e8:	ff 73 28             	pushl  0x28(%ebx)
  8002eb:	ff 76 28             	pushl  0x28(%esi)
  8002ee:	68 15 15 80 00       	push   $0x801515
  8002f3:	68 d4 14 80 00       	push   $0x8014d4
  8002f8:	e8 c5 03 00 00       	call   8006c2 <cprintf>
  8002fd:	83 c4 20             	add    $0x20,%esp
  800300:	8b 43 28             	mov    0x28(%ebx),%eax
  800303:	39 46 28             	cmp    %eax,0x28(%esi)
  800306:	75 28                	jne    800330 <check_regs+0x2fd>
  800308:	eb 6c                	jmp    800376 <check_regs+0x343>
  80030a:	83 ec 0c             	sub    $0xc,%esp
  80030d:	68 e4 14 80 00       	push   $0x8014e4
  800312:	e8 ab 03 00 00       	call   8006c2 <cprintf>

#undef CHECK

	cprintf("Registers %s ", testname);
  800317:	83 c4 08             	add    $0x8,%esp
  80031a:	ff 75 0c             	pushl  0xc(%ebp)
  80031d:	68 19 15 80 00       	push   $0x801519
  800322:	e8 9b 03 00 00       	call   8006c2 <cprintf>
	if (!mismatch)
  800327:	83 c4 10             	add    $0x10,%esp
  80032a:	85 ff                	test   %edi,%edi
  80032c:	74 24                	je     800352 <check_regs+0x31f>
  80032e:	eb 34                	jmp    800364 <check_regs+0x331>
	CHECK(edx, regs.reg_edx);
	CHECK(ecx, regs.reg_ecx);
	CHECK(eax, regs.reg_eax);
	CHECK(eip, eip);
	CHECK(eflags, eflags);
	CHECK(esp, esp);
  800330:	83 ec 0c             	sub    $0xc,%esp
  800333:	68 e8 14 80 00       	push   $0x8014e8
  800338:	e8 85 03 00 00       	call   8006c2 <cprintf>

#undef CHECK

	cprintf("Registers %s ", testname);
  80033d:	83 c4 08             	add    $0x8,%esp
  800340:	ff 75 0c             	pushl  0xc(%ebp)
  800343:	68 19 15 80 00       	push   $0x801519
  800348:	e8 75 03 00 00       	call   8006c2 <cprintf>
  80034d:	83 c4 10             	add    $0x10,%esp
  800350:	eb 12                	jmp    800364 <check_regs+0x331>
	if (!mismatch)
		cprintf("OK\n");
  800352:	83 ec 0c             	sub    $0xc,%esp
  800355:	68 e4 14 80 00       	push   $0x8014e4
  80035a:	e8 63 03 00 00       	call   8006c2 <cprintf>
  80035f:	83 c4 10             	add    $0x10,%esp
  800362:	eb 34                	jmp    800398 <check_regs+0x365>
	else
		cprintf("MISMATCH\n");
  800364:	83 ec 0c             	sub    $0xc,%esp
  800367:	68 e8 14 80 00       	push   $0x8014e8
  80036c:	e8 51 03 00 00       	call   8006c2 <cprintf>
  800371:	83 c4 10             	add    $0x10,%esp
}
  800374:	eb 22                	jmp    800398 <check_regs+0x365>
	CHECK(edx, regs.reg_edx);
	CHECK(ecx, regs.reg_ecx);
	CHECK(eax, regs.reg_eax);
	CHECK(eip, eip);
	CHECK(eflags, eflags);
	CHECK(esp, esp);
  800376:	83 ec 0c             	sub    $0xc,%esp
  800379:	68 e4 14 80 00       	push   $0x8014e4
  80037e:	e8 3f 03 00 00       	call   8006c2 <cprintf>

#undef CHECK

	cprintf("Registers %s ", testname);
  800383:	83 c4 08             	add    $0x8,%esp
  800386:	ff 75 0c             	pushl  0xc(%ebp)
  800389:	68 19 15 80 00       	push   $0x801519
  80038e:	e8 2f 03 00 00       	call   8006c2 <cprintf>
  800393:	83 c4 10             	add    $0x10,%esp
  800396:	eb cc                	jmp    800364 <check_regs+0x331>
	if (!mismatch)
		cprintf("OK\n");
	else
		cprintf("MISMATCH\n");
}
  800398:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80039b:	5b                   	pop    %ebx
  80039c:	5e                   	pop    %esi
  80039d:	5f                   	pop    %edi
  80039e:	5d                   	pop    %ebp
  80039f:	c3                   	ret    

008003a0 <pgfault>:

static void
pgfault(struct UTrapframe *utf)
{
  8003a0:	55                   	push   %ebp
  8003a1:	89 e5                	mov    %esp,%ebp
  8003a3:	83 ec 08             	sub    $0x8,%esp
  8003a6:	8b 45 08             	mov    0x8(%ebp),%eax
	int r;

	if (utf->utf_fault_va != (uint32_t)UTEMP)
  8003a9:	8b 10                	mov    (%eax),%edx
  8003ab:	81 fa 00 00 40 00    	cmp    $0x400000,%edx
  8003b1:	74 18                	je     8003cb <pgfault+0x2b>
		panic("pgfault expected at UTEMP, got 0x%08x (eip %08x)",
  8003b3:	83 ec 0c             	sub    $0xc,%esp
  8003b6:	ff 70 28             	pushl  0x28(%eax)
  8003b9:	52                   	push   %edx
  8003ba:	68 80 15 80 00       	push   $0x801580
  8003bf:	6a 51                	push   $0x51
  8003c1:	68 27 15 80 00       	push   $0x801527
  8003c6:	e8 1e 02 00 00       	call   8005e9 <_panic>
		      utf->utf_fault_va, utf->utf_eip);

	// Check registers in UTrapframe
	during.regs = utf->utf_regs;
  8003cb:	8b 50 08             	mov    0x8(%eax),%edx
  8003ce:	89 15 60 20 80 00    	mov    %edx,0x802060
  8003d4:	8b 50 0c             	mov    0xc(%eax),%edx
  8003d7:	89 15 64 20 80 00    	mov    %edx,0x802064
  8003dd:	8b 50 10             	mov    0x10(%eax),%edx
  8003e0:	89 15 68 20 80 00    	mov    %edx,0x802068
  8003e6:	8b 50 14             	mov    0x14(%eax),%edx
  8003e9:	89 15 6c 20 80 00    	mov    %edx,0x80206c
  8003ef:	8b 50 18             	mov    0x18(%eax),%edx
  8003f2:	89 15 70 20 80 00    	mov    %edx,0x802070
  8003f8:	8b 50 1c             	mov    0x1c(%eax),%edx
  8003fb:	89 15 74 20 80 00    	mov    %edx,0x802074
  800401:	8b 50 20             	mov    0x20(%eax),%edx
  800404:	89 15 78 20 80 00    	mov    %edx,0x802078
  80040a:	8b 50 24             	mov    0x24(%eax),%edx
  80040d:	89 15 7c 20 80 00    	mov    %edx,0x80207c
	during.eip = utf->utf_eip;
  800413:	8b 50 28             	mov    0x28(%eax),%edx
  800416:	89 15 80 20 80 00    	mov    %edx,0x802080
	during.eflags = utf->utf_eflags;
  80041c:	8b 50 2c             	mov    0x2c(%eax),%edx
  80041f:	89 15 84 20 80 00    	mov    %edx,0x802084
	during.esp = utf->utf_esp;
  800425:	8b 40 30             	mov    0x30(%eax),%eax
  800428:	a3 88 20 80 00       	mov    %eax,0x802088
	check_regs(&before, "before", &during, "during", "in UTrapframe");
  80042d:	83 ec 08             	sub    $0x8,%esp
  800430:	68 3f 15 80 00       	push   $0x80153f
  800435:	68 4d 15 80 00       	push   $0x80154d
  80043a:	b9 60 20 80 00       	mov    $0x802060,%ecx
  80043f:	ba 38 15 80 00       	mov    $0x801538,%edx
  800444:	b8 a0 20 80 00       	mov    $0x8020a0,%eax
  800449:	e8 e5 fb ff ff       	call   800033 <check_regs>

	// Map UTEMP so the write succeeds
	if ((r = sys_page_alloc(0, UTEMP, PTE_U|PTE_P|PTE_W)) < 0)
  80044e:	83 c4 0c             	add    $0xc,%esp
  800451:	6a 07                	push   $0x7
  800453:	68 00 00 40 00       	push   $0x400000
  800458:	6a 00                	push   $0x0
  80045a:	e8 eb 0b 00 00       	call   80104a <sys_page_alloc>
  80045f:	83 c4 10             	add    $0x10,%esp
  800462:	85 c0                	test   %eax,%eax
  800464:	79 12                	jns    800478 <pgfault+0xd8>
		panic("sys_page_alloc: %e", r);
  800466:	50                   	push   %eax
  800467:	68 54 15 80 00       	push   $0x801554
  80046c:	6a 5c                	push   $0x5c
  80046e:	68 27 15 80 00       	push   $0x801527
  800473:	e8 71 01 00 00       	call   8005e9 <_panic>
}
  800478:	c9                   	leave  
  800479:	c3                   	ret    

0080047a <umain>:

void
umain(int argc, char **argv)
{
  80047a:	55                   	push   %ebp
  80047b:	89 e5                	mov    %esp,%ebp
  80047d:	83 ec 14             	sub    $0x14,%esp
	set_pgfault_handler(pgfault);
  800480:	68 a0 03 80 00       	push   $0x8003a0
  800485:	e8 6f 0d 00 00       	call   8011f9 <set_pgfault_handler>

	__asm __volatile(
  80048a:	50                   	push   %eax
  80048b:	9c                   	pushf  
  80048c:	58                   	pop    %eax
  80048d:	0d d5 08 00 00       	or     $0x8d5,%eax
  800492:	50                   	push   %eax
  800493:	9d                   	popf   
  800494:	a3 c4 20 80 00       	mov    %eax,0x8020c4
  800499:	8d 05 d4 04 80 00    	lea    0x8004d4,%eax
  80049f:	a3 c0 20 80 00       	mov    %eax,0x8020c0
  8004a4:	58                   	pop    %eax
  8004a5:	89 3d a0 20 80 00    	mov    %edi,0x8020a0
  8004ab:	89 35 a4 20 80 00    	mov    %esi,0x8020a4
  8004b1:	89 2d a8 20 80 00    	mov    %ebp,0x8020a8
  8004b7:	89 1d b0 20 80 00    	mov    %ebx,0x8020b0
  8004bd:	89 15 b4 20 80 00    	mov    %edx,0x8020b4
  8004c3:	89 0d b8 20 80 00    	mov    %ecx,0x8020b8
  8004c9:	a3 bc 20 80 00       	mov    %eax,0x8020bc
  8004ce:	89 25 c8 20 80 00    	mov    %esp,0x8020c8
  8004d4:	c7 05 00 00 40 00 2a 	movl   $0x2a,0x400000
  8004db:	00 00 00 
  8004de:	89 3d 20 20 80 00    	mov    %edi,0x802020
  8004e4:	89 35 24 20 80 00    	mov    %esi,0x802024
  8004ea:	89 2d 28 20 80 00    	mov    %ebp,0x802028
  8004f0:	89 1d 30 20 80 00    	mov    %ebx,0x802030
  8004f6:	89 15 34 20 80 00    	mov    %edx,0x802034
  8004fc:	89 0d 38 20 80 00    	mov    %ecx,0x802038
  800502:	a3 3c 20 80 00       	mov    %eax,0x80203c
  800507:	89 25 48 20 80 00    	mov    %esp,0x802048
  80050d:	8b 3d a0 20 80 00    	mov    0x8020a0,%edi
  800513:	8b 35 a4 20 80 00    	mov    0x8020a4,%esi
  800519:	8b 2d a8 20 80 00    	mov    0x8020a8,%ebp
  80051f:	8b 1d b0 20 80 00    	mov    0x8020b0,%ebx
  800525:	8b 15 b4 20 80 00    	mov    0x8020b4,%edx
  80052b:	8b 0d b8 20 80 00    	mov    0x8020b8,%ecx
  800531:	a1 bc 20 80 00       	mov    0x8020bc,%eax
  800536:	8b 25 c8 20 80 00    	mov    0x8020c8,%esp
  80053c:	50                   	push   %eax
  80053d:	9c                   	pushf  
  80053e:	58                   	pop    %eax
  80053f:	a3 44 20 80 00       	mov    %eax,0x802044
  800544:	58                   	pop    %eax
		: : "m" (before), "m" (after) : "memory", "cc");

	// Check UTEMP to roughly determine that EIP was restored
	// correctly (of course, we probably wouldn't get this far if
	// it weren't)
	if (*(int*)UTEMP != 42)
  800545:	83 c4 10             	add    $0x10,%esp
  800548:	83 3d 00 00 40 00 2a 	cmpl   $0x2a,0x400000
  80054f:	74 10                	je     800561 <umain+0xe7>
		cprintf("EIP after page-fault MISMATCH\n");
  800551:	83 ec 0c             	sub    $0xc,%esp
  800554:	68 b4 15 80 00       	push   $0x8015b4
  800559:	e8 64 01 00 00       	call   8006c2 <cprintf>
  80055e:	83 c4 10             	add    $0x10,%esp
	after.eip = before.eip;
  800561:	a1 c0 20 80 00       	mov    0x8020c0,%eax
  800566:	a3 40 20 80 00       	mov    %eax,0x802040

	check_regs(&before, "before", &after, "after", "after page-fault");
  80056b:	83 ec 08             	sub    $0x8,%esp
  80056e:	68 67 15 80 00       	push   $0x801567
  800573:	68 78 15 80 00       	push   $0x801578
  800578:	b9 20 20 80 00       	mov    $0x802020,%ecx
  80057d:	ba 38 15 80 00       	mov    $0x801538,%edx
  800582:	b8 a0 20 80 00       	mov    $0x8020a0,%eax
  800587:	e8 a7 fa ff ff       	call   800033 <check_regs>
}
  80058c:	83 c4 10             	add    $0x10,%esp
  80058f:	c9                   	leave  
  800590:	c3                   	ret    

00800591 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800591:	55                   	push   %ebp
  800592:	89 e5                	mov    %esp,%ebp
  800594:	56                   	push   %esi
  800595:	53                   	push   %ebx
  800596:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800599:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	//thisenv = 0;
	envid_t id = sys_getenvid();
  80059c:	e8 6b 0a 00 00       	call   80100c <sys_getenvid>
	thisenv = &envs[ENVX(id)];
  8005a1:	25 ff 03 00 00       	and    $0x3ff,%eax
  8005a6:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8005a9:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8005ae:	a3 cc 20 80 00       	mov    %eax,0x8020cc
	// save the name of the program so that panic() can use it
	if (argc > 0)
  8005b3:	85 db                	test   %ebx,%ebx
  8005b5:	7e 07                	jle    8005be <libmain+0x2d>
		binaryname = argv[0];
  8005b7:	8b 06                	mov    (%esi),%eax
  8005b9:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8005be:	83 ec 08             	sub    $0x8,%esp
  8005c1:	56                   	push   %esi
  8005c2:	53                   	push   %ebx
  8005c3:	e8 b2 fe ff ff       	call   80047a <umain>

	// exit gracefully
	exit();
  8005c8:	e8 0a 00 00 00       	call   8005d7 <exit>
}
  8005cd:	83 c4 10             	add    $0x10,%esp
  8005d0:	8d 65 f8             	lea    -0x8(%ebp),%esp
  8005d3:	5b                   	pop    %ebx
  8005d4:	5e                   	pop    %esi
  8005d5:	5d                   	pop    %ebp
  8005d6:	c3                   	ret    

008005d7 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8005d7:	55                   	push   %ebp
  8005d8:	89 e5                	mov    %esp,%ebp
  8005da:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  8005dd:	6a 00                	push   $0x0
  8005df:	e8 e7 09 00 00       	call   800fcb <sys_env_destroy>
}
  8005e4:	83 c4 10             	add    $0x10,%esp
  8005e7:	c9                   	leave  
  8005e8:	c3                   	ret    

008005e9 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8005e9:	55                   	push   %ebp
  8005ea:	89 e5                	mov    %esp,%ebp
  8005ec:	56                   	push   %esi
  8005ed:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  8005ee:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8005f1:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8005f7:	e8 10 0a 00 00       	call   80100c <sys_getenvid>
  8005fc:	83 ec 0c             	sub    $0xc,%esp
  8005ff:	ff 75 0c             	pushl  0xc(%ebp)
  800602:	ff 75 08             	pushl  0x8(%ebp)
  800605:	56                   	push   %esi
  800606:	50                   	push   %eax
  800607:	68 e0 15 80 00       	push   $0x8015e0
  80060c:	e8 b1 00 00 00       	call   8006c2 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800611:	83 c4 18             	add    $0x18,%esp
  800614:	53                   	push   %ebx
  800615:	ff 75 10             	pushl  0x10(%ebp)
  800618:	e8 54 00 00 00       	call   800671 <vcprintf>
	cprintf("\n");
  80061d:	c7 04 24 f0 14 80 00 	movl   $0x8014f0,(%esp)
  800624:	e8 99 00 00 00       	call   8006c2 <cprintf>
  800629:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80062c:	cc                   	int3   
  80062d:	eb fd                	jmp    80062c <_panic+0x43>

0080062f <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80062f:	55                   	push   %ebp
  800630:	89 e5                	mov    %esp,%ebp
  800632:	53                   	push   %ebx
  800633:	83 ec 04             	sub    $0x4,%esp
  800636:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800639:	8b 13                	mov    (%ebx),%edx
  80063b:	8d 42 01             	lea    0x1(%edx),%eax
  80063e:	89 03                	mov    %eax,(%ebx)
  800640:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800643:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800647:	3d ff 00 00 00       	cmp    $0xff,%eax
  80064c:	75 1a                	jne    800668 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  80064e:	83 ec 08             	sub    $0x8,%esp
  800651:	68 ff 00 00 00       	push   $0xff
  800656:	8d 43 08             	lea    0x8(%ebx),%eax
  800659:	50                   	push   %eax
  80065a:	e8 2f 09 00 00       	call   800f8e <sys_cputs>
		b->idx = 0;
  80065f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  800665:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  800668:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80066c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80066f:	c9                   	leave  
  800670:	c3                   	ret    

00800671 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800671:	55                   	push   %ebp
  800672:	89 e5                	mov    %esp,%ebp
  800674:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  80067a:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800681:	00 00 00 
	b.cnt = 0;
  800684:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80068b:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80068e:	ff 75 0c             	pushl  0xc(%ebp)
  800691:	ff 75 08             	pushl  0x8(%ebp)
  800694:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80069a:	50                   	push   %eax
  80069b:	68 2f 06 80 00       	push   $0x80062f
  8006a0:	e8 54 01 00 00       	call   8007f9 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8006a5:	83 c4 08             	add    $0x8,%esp
  8006a8:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8006ae:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8006b4:	50                   	push   %eax
  8006b5:	e8 d4 08 00 00       	call   800f8e <sys_cputs>

	return b.cnt;
}
  8006ba:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8006c0:	c9                   	leave  
  8006c1:	c3                   	ret    

008006c2 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8006c2:	55                   	push   %ebp
  8006c3:	89 e5                	mov    %esp,%ebp
  8006c5:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8006c8:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8006cb:	50                   	push   %eax
  8006cc:	ff 75 08             	pushl  0x8(%ebp)
  8006cf:	e8 9d ff ff ff       	call   800671 <vcprintf>
	va_end(ap);

	return cnt;
}
  8006d4:	c9                   	leave  
  8006d5:	c3                   	ret    

008006d6 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8006d6:	55                   	push   %ebp
  8006d7:	89 e5                	mov    %esp,%ebp
  8006d9:	57                   	push   %edi
  8006da:	56                   	push   %esi
  8006db:	53                   	push   %ebx
  8006dc:	83 ec 1c             	sub    $0x1c,%esp
  8006df:	89 c7                	mov    %eax,%edi
  8006e1:	89 d6                	mov    %edx,%esi
  8006e3:	8b 45 08             	mov    0x8(%ebp),%eax
  8006e6:	8b 55 0c             	mov    0xc(%ebp),%edx
  8006e9:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8006ec:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8006ef:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8006f2:	bb 00 00 00 00       	mov    $0x0,%ebx
  8006f7:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  8006fa:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  8006fd:	39 d3                	cmp    %edx,%ebx
  8006ff:	72 05                	jb     800706 <printnum+0x30>
  800701:	39 45 10             	cmp    %eax,0x10(%ebp)
  800704:	77 45                	ja     80074b <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800706:	83 ec 0c             	sub    $0xc,%esp
  800709:	ff 75 18             	pushl  0x18(%ebp)
  80070c:	8b 45 14             	mov    0x14(%ebp),%eax
  80070f:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800712:	53                   	push   %ebx
  800713:	ff 75 10             	pushl  0x10(%ebp)
  800716:	83 ec 08             	sub    $0x8,%esp
  800719:	ff 75 e4             	pushl  -0x1c(%ebp)
  80071c:	ff 75 e0             	pushl  -0x20(%ebp)
  80071f:	ff 75 dc             	pushl  -0x24(%ebp)
  800722:	ff 75 d8             	pushl  -0x28(%ebp)
  800725:	e8 06 0b 00 00       	call   801230 <__udivdi3>
  80072a:	83 c4 18             	add    $0x18,%esp
  80072d:	52                   	push   %edx
  80072e:	50                   	push   %eax
  80072f:	89 f2                	mov    %esi,%edx
  800731:	89 f8                	mov    %edi,%eax
  800733:	e8 9e ff ff ff       	call   8006d6 <printnum>
  800738:	83 c4 20             	add    $0x20,%esp
  80073b:	eb 18                	jmp    800755 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80073d:	83 ec 08             	sub    $0x8,%esp
  800740:	56                   	push   %esi
  800741:	ff 75 18             	pushl  0x18(%ebp)
  800744:	ff d7                	call   *%edi
  800746:	83 c4 10             	add    $0x10,%esp
  800749:	eb 03                	jmp    80074e <printnum+0x78>
  80074b:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80074e:	83 eb 01             	sub    $0x1,%ebx
  800751:	85 db                	test   %ebx,%ebx
  800753:	7f e8                	jg     80073d <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800755:	83 ec 08             	sub    $0x8,%esp
  800758:	56                   	push   %esi
  800759:	83 ec 04             	sub    $0x4,%esp
  80075c:	ff 75 e4             	pushl  -0x1c(%ebp)
  80075f:	ff 75 e0             	pushl  -0x20(%ebp)
  800762:	ff 75 dc             	pushl  -0x24(%ebp)
  800765:	ff 75 d8             	pushl  -0x28(%ebp)
  800768:	e8 f3 0b 00 00       	call   801360 <__umoddi3>
  80076d:	83 c4 14             	add    $0x14,%esp
  800770:	0f be 80 03 16 80 00 	movsbl 0x801603(%eax),%eax
  800777:	50                   	push   %eax
  800778:	ff d7                	call   *%edi
}
  80077a:	83 c4 10             	add    $0x10,%esp
  80077d:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800780:	5b                   	pop    %ebx
  800781:	5e                   	pop    %esi
  800782:	5f                   	pop    %edi
  800783:	5d                   	pop    %ebp
  800784:	c3                   	ret    

00800785 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  800785:	55                   	push   %ebp
  800786:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800788:	83 fa 01             	cmp    $0x1,%edx
  80078b:	7e 0e                	jle    80079b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  80078d:	8b 10                	mov    (%eax),%edx
  80078f:	8d 4a 08             	lea    0x8(%edx),%ecx
  800792:	89 08                	mov    %ecx,(%eax)
  800794:	8b 02                	mov    (%edx),%eax
  800796:	8b 52 04             	mov    0x4(%edx),%edx
  800799:	eb 22                	jmp    8007bd <getuint+0x38>
	else if (lflag)
  80079b:	85 d2                	test   %edx,%edx
  80079d:	74 10                	je     8007af <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  80079f:	8b 10                	mov    (%eax),%edx
  8007a1:	8d 4a 04             	lea    0x4(%edx),%ecx
  8007a4:	89 08                	mov    %ecx,(%eax)
  8007a6:	8b 02                	mov    (%edx),%eax
  8007a8:	ba 00 00 00 00       	mov    $0x0,%edx
  8007ad:	eb 0e                	jmp    8007bd <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8007af:	8b 10                	mov    (%eax),%edx
  8007b1:	8d 4a 04             	lea    0x4(%edx),%ecx
  8007b4:	89 08                	mov    %ecx,(%eax)
  8007b6:	8b 02                	mov    (%edx),%eax
  8007b8:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8007bd:	5d                   	pop    %ebp
  8007be:	c3                   	ret    

008007bf <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8007bf:	55                   	push   %ebp
  8007c0:	89 e5                	mov    %esp,%ebp
  8007c2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8007c5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8007c9:	8b 10                	mov    (%eax),%edx
  8007cb:	3b 50 04             	cmp    0x4(%eax),%edx
  8007ce:	73 0a                	jae    8007da <sprintputch+0x1b>
		*b->buf++ = ch;
  8007d0:	8d 4a 01             	lea    0x1(%edx),%ecx
  8007d3:	89 08                	mov    %ecx,(%eax)
  8007d5:	8b 45 08             	mov    0x8(%ebp),%eax
  8007d8:	88 02                	mov    %al,(%edx)
}
  8007da:	5d                   	pop    %ebp
  8007db:	c3                   	ret    

008007dc <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8007dc:	55                   	push   %ebp
  8007dd:	89 e5                	mov    %esp,%ebp
  8007df:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  8007e2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8007e5:	50                   	push   %eax
  8007e6:	ff 75 10             	pushl  0x10(%ebp)
  8007e9:	ff 75 0c             	pushl  0xc(%ebp)
  8007ec:	ff 75 08             	pushl  0x8(%ebp)
  8007ef:	e8 05 00 00 00       	call   8007f9 <vprintfmt>
	va_end(ap);
}
  8007f4:	83 c4 10             	add    $0x10,%esp
  8007f7:	c9                   	leave  
  8007f8:	c3                   	ret    

008007f9 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8007f9:	55                   	push   %ebp
  8007fa:	89 e5                	mov    %esp,%ebp
  8007fc:	57                   	push   %edi
  8007fd:	56                   	push   %esi
  8007fe:	53                   	push   %ebx
  8007ff:	83 ec 2c             	sub    $0x2c,%esp
  800802:	8b 75 08             	mov    0x8(%ebp),%esi
  800805:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800808:	8b 7d 10             	mov    0x10(%ebp),%edi
  80080b:	eb 12                	jmp    80081f <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80080d:	85 c0                	test   %eax,%eax
  80080f:	0f 84 89 03 00 00    	je     800b9e <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
  800815:	83 ec 08             	sub    $0x8,%esp
  800818:	53                   	push   %ebx
  800819:	50                   	push   %eax
  80081a:	ff d6                	call   *%esi
  80081c:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80081f:	83 c7 01             	add    $0x1,%edi
  800822:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800826:	83 f8 25             	cmp    $0x25,%eax
  800829:	75 e2                	jne    80080d <vprintfmt+0x14>
  80082b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80082f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  800836:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80083d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  800844:	ba 00 00 00 00       	mov    $0x0,%edx
  800849:	eb 07                	jmp    800852 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80084b:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  80084e:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800852:	8d 47 01             	lea    0x1(%edi),%eax
  800855:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800858:	0f b6 07             	movzbl (%edi),%eax
  80085b:	0f b6 c8             	movzbl %al,%ecx
  80085e:	83 e8 23             	sub    $0x23,%eax
  800861:	3c 55                	cmp    $0x55,%al
  800863:	0f 87 1a 03 00 00    	ja     800b83 <vprintfmt+0x38a>
  800869:	0f b6 c0             	movzbl %al,%eax
  80086c:	ff 24 85 c0 16 80 00 	jmp    *0x8016c0(,%eax,4)
  800873:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800876:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  80087a:	eb d6                	jmp    800852 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80087c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80087f:	b8 00 00 00 00       	mov    $0x0,%eax
  800884:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800887:	8d 04 80             	lea    (%eax,%eax,4),%eax
  80088a:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  80088e:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  800891:	8d 51 d0             	lea    -0x30(%ecx),%edx
  800894:	83 fa 09             	cmp    $0x9,%edx
  800897:	77 39                	ja     8008d2 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800899:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80089c:	eb e9                	jmp    800887 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80089e:	8b 45 14             	mov    0x14(%ebp),%eax
  8008a1:	8d 48 04             	lea    0x4(%eax),%ecx
  8008a4:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8008a7:	8b 00                	mov    (%eax),%eax
  8008a9:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8008ac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8008af:	eb 27                	jmp    8008d8 <vprintfmt+0xdf>
  8008b1:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8008b4:	85 c0                	test   %eax,%eax
  8008b6:	b9 00 00 00 00       	mov    $0x0,%ecx
  8008bb:	0f 49 c8             	cmovns %eax,%ecx
  8008be:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8008c1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8008c4:	eb 8c                	jmp    800852 <vprintfmt+0x59>
  8008c6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8008c9:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  8008d0:	eb 80                	jmp    800852 <vprintfmt+0x59>
  8008d2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8008d5:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  8008d8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8008dc:	0f 89 70 ff ff ff    	jns    800852 <vprintfmt+0x59>
				width = precision, precision = -1;
  8008e2:	8b 45 d0             	mov    -0x30(%ebp),%eax
  8008e5:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8008e8:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8008ef:	e9 5e ff ff ff       	jmp    800852 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8008f4:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8008f7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8008fa:	e9 53 ff ff ff       	jmp    800852 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8008ff:	8b 45 14             	mov    0x14(%ebp),%eax
  800902:	8d 50 04             	lea    0x4(%eax),%edx
  800905:	89 55 14             	mov    %edx,0x14(%ebp)
  800908:	83 ec 08             	sub    $0x8,%esp
  80090b:	53                   	push   %ebx
  80090c:	ff 30                	pushl  (%eax)
  80090e:	ff d6                	call   *%esi
			break;
  800910:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800913:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800916:	e9 04 ff ff ff       	jmp    80081f <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80091b:	8b 45 14             	mov    0x14(%ebp),%eax
  80091e:	8d 50 04             	lea    0x4(%eax),%edx
  800921:	89 55 14             	mov    %edx,0x14(%ebp)
  800924:	8b 00                	mov    (%eax),%eax
  800926:	99                   	cltd   
  800927:	31 d0                	xor    %edx,%eax
  800929:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80092b:	83 f8 09             	cmp    $0x9,%eax
  80092e:	7f 0b                	jg     80093b <vprintfmt+0x142>
  800930:	8b 14 85 20 18 80 00 	mov    0x801820(,%eax,4),%edx
  800937:	85 d2                	test   %edx,%edx
  800939:	75 18                	jne    800953 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  80093b:	50                   	push   %eax
  80093c:	68 1b 16 80 00       	push   $0x80161b
  800941:	53                   	push   %ebx
  800942:	56                   	push   %esi
  800943:	e8 94 fe ff ff       	call   8007dc <printfmt>
  800948:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80094b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  80094e:	e9 cc fe ff ff       	jmp    80081f <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  800953:	52                   	push   %edx
  800954:	68 24 16 80 00       	push   $0x801624
  800959:	53                   	push   %ebx
  80095a:	56                   	push   %esi
  80095b:	e8 7c fe ff ff       	call   8007dc <printfmt>
  800960:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800963:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800966:	e9 b4 fe ff ff       	jmp    80081f <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80096b:	8b 45 14             	mov    0x14(%ebp),%eax
  80096e:	8d 50 04             	lea    0x4(%eax),%edx
  800971:	89 55 14             	mov    %edx,0x14(%ebp)
  800974:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  800976:	85 ff                	test   %edi,%edi
  800978:	b8 14 16 80 00       	mov    $0x801614,%eax
  80097d:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800980:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800984:	0f 8e 94 00 00 00    	jle    800a1e <vprintfmt+0x225>
  80098a:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  80098e:	0f 84 98 00 00 00    	je     800a2c <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  800994:	83 ec 08             	sub    $0x8,%esp
  800997:	ff 75 d0             	pushl  -0x30(%ebp)
  80099a:	57                   	push   %edi
  80099b:	e8 86 02 00 00       	call   800c26 <strnlen>
  8009a0:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  8009a3:	29 c1                	sub    %eax,%ecx
  8009a5:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  8009a8:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  8009ab:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  8009af:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8009b2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  8009b5:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8009b7:	eb 0f                	jmp    8009c8 <vprintfmt+0x1cf>
					putch(padc, putdat);
  8009b9:	83 ec 08             	sub    $0x8,%esp
  8009bc:	53                   	push   %ebx
  8009bd:	ff 75 e0             	pushl  -0x20(%ebp)
  8009c0:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8009c2:	83 ef 01             	sub    $0x1,%edi
  8009c5:	83 c4 10             	add    $0x10,%esp
  8009c8:	85 ff                	test   %edi,%edi
  8009ca:	7f ed                	jg     8009b9 <vprintfmt+0x1c0>
  8009cc:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8009cf:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  8009d2:	85 c9                	test   %ecx,%ecx
  8009d4:	b8 00 00 00 00       	mov    $0x0,%eax
  8009d9:	0f 49 c1             	cmovns %ecx,%eax
  8009dc:	29 c1                	sub    %eax,%ecx
  8009de:	89 75 08             	mov    %esi,0x8(%ebp)
  8009e1:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8009e4:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8009e7:	89 cb                	mov    %ecx,%ebx
  8009e9:	eb 4d                	jmp    800a38 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8009eb:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  8009ef:	74 1b                	je     800a0c <vprintfmt+0x213>
  8009f1:	0f be c0             	movsbl %al,%eax
  8009f4:	83 e8 20             	sub    $0x20,%eax
  8009f7:	83 f8 5e             	cmp    $0x5e,%eax
  8009fa:	76 10                	jbe    800a0c <vprintfmt+0x213>
					putch('?', putdat);
  8009fc:	83 ec 08             	sub    $0x8,%esp
  8009ff:	ff 75 0c             	pushl  0xc(%ebp)
  800a02:	6a 3f                	push   $0x3f
  800a04:	ff 55 08             	call   *0x8(%ebp)
  800a07:	83 c4 10             	add    $0x10,%esp
  800a0a:	eb 0d                	jmp    800a19 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800a0c:	83 ec 08             	sub    $0x8,%esp
  800a0f:	ff 75 0c             	pushl  0xc(%ebp)
  800a12:	52                   	push   %edx
  800a13:	ff 55 08             	call   *0x8(%ebp)
  800a16:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800a19:	83 eb 01             	sub    $0x1,%ebx
  800a1c:	eb 1a                	jmp    800a38 <vprintfmt+0x23f>
  800a1e:	89 75 08             	mov    %esi,0x8(%ebp)
  800a21:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800a24:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800a27:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800a2a:	eb 0c                	jmp    800a38 <vprintfmt+0x23f>
  800a2c:	89 75 08             	mov    %esi,0x8(%ebp)
  800a2f:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800a32:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800a35:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800a38:	83 c7 01             	add    $0x1,%edi
  800a3b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800a3f:	0f be d0             	movsbl %al,%edx
  800a42:	85 d2                	test   %edx,%edx
  800a44:	74 23                	je     800a69 <vprintfmt+0x270>
  800a46:	85 f6                	test   %esi,%esi
  800a48:	78 a1                	js     8009eb <vprintfmt+0x1f2>
  800a4a:	83 ee 01             	sub    $0x1,%esi
  800a4d:	79 9c                	jns    8009eb <vprintfmt+0x1f2>
  800a4f:	89 df                	mov    %ebx,%edi
  800a51:	8b 75 08             	mov    0x8(%ebp),%esi
  800a54:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800a57:	eb 18                	jmp    800a71 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800a59:	83 ec 08             	sub    $0x8,%esp
  800a5c:	53                   	push   %ebx
  800a5d:	6a 20                	push   $0x20
  800a5f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800a61:	83 ef 01             	sub    $0x1,%edi
  800a64:	83 c4 10             	add    $0x10,%esp
  800a67:	eb 08                	jmp    800a71 <vprintfmt+0x278>
  800a69:	89 df                	mov    %ebx,%edi
  800a6b:	8b 75 08             	mov    0x8(%ebp),%esi
  800a6e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800a71:	85 ff                	test   %edi,%edi
  800a73:	7f e4                	jg     800a59 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800a75:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800a78:	e9 a2 fd ff ff       	jmp    80081f <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800a7d:	83 fa 01             	cmp    $0x1,%edx
  800a80:	7e 16                	jle    800a98 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
  800a82:	8b 45 14             	mov    0x14(%ebp),%eax
  800a85:	8d 50 08             	lea    0x8(%eax),%edx
  800a88:	89 55 14             	mov    %edx,0x14(%ebp)
  800a8b:	8b 50 04             	mov    0x4(%eax),%edx
  800a8e:	8b 00                	mov    (%eax),%eax
  800a90:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800a93:	89 55 dc             	mov    %edx,-0x24(%ebp)
  800a96:	eb 32                	jmp    800aca <vprintfmt+0x2d1>
	else if (lflag)
  800a98:	85 d2                	test   %edx,%edx
  800a9a:	74 18                	je     800ab4 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
  800a9c:	8b 45 14             	mov    0x14(%ebp),%eax
  800a9f:	8d 50 04             	lea    0x4(%eax),%edx
  800aa2:	89 55 14             	mov    %edx,0x14(%ebp)
  800aa5:	8b 00                	mov    (%eax),%eax
  800aa7:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800aaa:	89 c1                	mov    %eax,%ecx
  800aac:	c1 f9 1f             	sar    $0x1f,%ecx
  800aaf:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  800ab2:	eb 16                	jmp    800aca <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
  800ab4:	8b 45 14             	mov    0x14(%ebp),%eax
  800ab7:	8d 50 04             	lea    0x4(%eax),%edx
  800aba:	89 55 14             	mov    %edx,0x14(%ebp)
  800abd:	8b 00                	mov    (%eax),%eax
  800abf:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800ac2:	89 c1                	mov    %eax,%ecx
  800ac4:	c1 f9 1f             	sar    $0x1f,%ecx
  800ac7:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800aca:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800acd:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800ad0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800ad5:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800ad9:	79 74                	jns    800b4f <vprintfmt+0x356>
				putch('-', putdat);
  800adb:	83 ec 08             	sub    $0x8,%esp
  800ade:	53                   	push   %ebx
  800adf:	6a 2d                	push   $0x2d
  800ae1:	ff d6                	call   *%esi
				num = -(long long) num;
  800ae3:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800ae6:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800ae9:	f7 d8                	neg    %eax
  800aeb:	83 d2 00             	adc    $0x0,%edx
  800aee:	f7 da                	neg    %edx
  800af0:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800af3:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800af8:	eb 55                	jmp    800b4f <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800afa:	8d 45 14             	lea    0x14(%ebp),%eax
  800afd:	e8 83 fc ff ff       	call   800785 <getuint>
			base = 10;
  800b02:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800b07:	eb 46                	jmp    800b4f <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800b09:	8d 45 14             	lea    0x14(%ebp),%eax
  800b0c:	e8 74 fc ff ff       	call   800785 <getuint>
			base = 8;
  800b11:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800b16:	eb 37                	jmp    800b4f <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
  800b18:	83 ec 08             	sub    $0x8,%esp
  800b1b:	53                   	push   %ebx
  800b1c:	6a 30                	push   $0x30
  800b1e:	ff d6                	call   *%esi
			putch('x', putdat);
  800b20:	83 c4 08             	add    $0x8,%esp
  800b23:	53                   	push   %ebx
  800b24:	6a 78                	push   $0x78
  800b26:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800b28:	8b 45 14             	mov    0x14(%ebp),%eax
  800b2b:	8d 50 04             	lea    0x4(%eax),%edx
  800b2e:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800b31:	8b 00                	mov    (%eax),%eax
  800b33:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800b38:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800b3b:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800b40:	eb 0d                	jmp    800b4f <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800b42:	8d 45 14             	lea    0x14(%ebp),%eax
  800b45:	e8 3b fc ff ff       	call   800785 <getuint>
			base = 16;
  800b4a:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800b4f:	83 ec 0c             	sub    $0xc,%esp
  800b52:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800b56:	57                   	push   %edi
  800b57:	ff 75 e0             	pushl  -0x20(%ebp)
  800b5a:	51                   	push   %ecx
  800b5b:	52                   	push   %edx
  800b5c:	50                   	push   %eax
  800b5d:	89 da                	mov    %ebx,%edx
  800b5f:	89 f0                	mov    %esi,%eax
  800b61:	e8 70 fb ff ff       	call   8006d6 <printnum>
			break;
  800b66:	83 c4 20             	add    $0x20,%esp
  800b69:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800b6c:	e9 ae fc ff ff       	jmp    80081f <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800b71:	83 ec 08             	sub    $0x8,%esp
  800b74:	53                   	push   %ebx
  800b75:	51                   	push   %ecx
  800b76:	ff d6                	call   *%esi
			break;
  800b78:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800b7b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  800b7e:	e9 9c fc ff ff       	jmp    80081f <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800b83:	83 ec 08             	sub    $0x8,%esp
  800b86:	53                   	push   %ebx
  800b87:	6a 25                	push   $0x25
  800b89:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  800b8b:	83 c4 10             	add    $0x10,%esp
  800b8e:	eb 03                	jmp    800b93 <vprintfmt+0x39a>
  800b90:	83 ef 01             	sub    $0x1,%edi
  800b93:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800b97:	75 f7                	jne    800b90 <vprintfmt+0x397>
  800b99:	e9 81 fc ff ff       	jmp    80081f <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800b9e:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800ba1:	5b                   	pop    %ebx
  800ba2:	5e                   	pop    %esi
  800ba3:	5f                   	pop    %edi
  800ba4:	5d                   	pop    %ebp
  800ba5:	c3                   	ret    

00800ba6 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800ba6:	55                   	push   %ebp
  800ba7:	89 e5                	mov    %esp,%ebp
  800ba9:	83 ec 18             	sub    $0x18,%esp
  800bac:	8b 45 08             	mov    0x8(%ebp),%eax
  800baf:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800bb2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800bb5:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800bb9:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800bbc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800bc3:	85 c0                	test   %eax,%eax
  800bc5:	74 26                	je     800bed <vsnprintf+0x47>
  800bc7:	85 d2                	test   %edx,%edx
  800bc9:	7e 22                	jle    800bed <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800bcb:	ff 75 14             	pushl  0x14(%ebp)
  800bce:	ff 75 10             	pushl  0x10(%ebp)
  800bd1:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800bd4:	50                   	push   %eax
  800bd5:	68 bf 07 80 00       	push   $0x8007bf
  800bda:	e8 1a fc ff ff       	call   8007f9 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800bdf:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800be2:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800be5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800be8:	83 c4 10             	add    $0x10,%esp
  800beb:	eb 05                	jmp    800bf2 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800bed:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800bf2:	c9                   	leave  
  800bf3:	c3                   	ret    

00800bf4 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800bf4:	55                   	push   %ebp
  800bf5:	89 e5                	mov    %esp,%ebp
  800bf7:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800bfa:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800bfd:	50                   	push   %eax
  800bfe:	ff 75 10             	pushl  0x10(%ebp)
  800c01:	ff 75 0c             	pushl  0xc(%ebp)
  800c04:	ff 75 08             	pushl  0x8(%ebp)
  800c07:	e8 9a ff ff ff       	call   800ba6 <vsnprintf>
	va_end(ap);

	return rc;
}
  800c0c:	c9                   	leave  
  800c0d:	c3                   	ret    

00800c0e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800c0e:	55                   	push   %ebp
  800c0f:	89 e5                	mov    %esp,%ebp
  800c11:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800c14:	b8 00 00 00 00       	mov    $0x0,%eax
  800c19:	eb 03                	jmp    800c1e <strlen+0x10>
		n++;
  800c1b:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800c1e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800c22:	75 f7                	jne    800c1b <strlen+0xd>
		n++;
	return n;
}
  800c24:	5d                   	pop    %ebp
  800c25:	c3                   	ret    

00800c26 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800c26:	55                   	push   %ebp
  800c27:	89 e5                	mov    %esp,%ebp
  800c29:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800c2c:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800c2f:	ba 00 00 00 00       	mov    $0x0,%edx
  800c34:	eb 03                	jmp    800c39 <strnlen+0x13>
		n++;
  800c36:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800c39:	39 c2                	cmp    %eax,%edx
  800c3b:	74 08                	je     800c45 <strnlen+0x1f>
  800c3d:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800c41:	75 f3                	jne    800c36 <strnlen+0x10>
  800c43:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800c45:	5d                   	pop    %ebp
  800c46:	c3                   	ret    

00800c47 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800c47:	55                   	push   %ebp
  800c48:	89 e5                	mov    %esp,%ebp
  800c4a:	53                   	push   %ebx
  800c4b:	8b 45 08             	mov    0x8(%ebp),%eax
  800c4e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800c51:	89 c2                	mov    %eax,%edx
  800c53:	83 c2 01             	add    $0x1,%edx
  800c56:	83 c1 01             	add    $0x1,%ecx
  800c59:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800c5d:	88 5a ff             	mov    %bl,-0x1(%edx)
  800c60:	84 db                	test   %bl,%bl
  800c62:	75 ef                	jne    800c53 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800c64:	5b                   	pop    %ebx
  800c65:	5d                   	pop    %ebp
  800c66:	c3                   	ret    

00800c67 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800c67:	55                   	push   %ebp
  800c68:	89 e5                	mov    %esp,%ebp
  800c6a:	53                   	push   %ebx
  800c6b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800c6e:	53                   	push   %ebx
  800c6f:	e8 9a ff ff ff       	call   800c0e <strlen>
  800c74:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  800c77:	ff 75 0c             	pushl  0xc(%ebp)
  800c7a:	01 d8                	add    %ebx,%eax
  800c7c:	50                   	push   %eax
  800c7d:	e8 c5 ff ff ff       	call   800c47 <strcpy>
	return dst;
}
  800c82:	89 d8                	mov    %ebx,%eax
  800c84:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  800c87:	c9                   	leave  
  800c88:	c3                   	ret    

00800c89 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800c89:	55                   	push   %ebp
  800c8a:	89 e5                	mov    %esp,%ebp
  800c8c:	56                   	push   %esi
  800c8d:	53                   	push   %ebx
  800c8e:	8b 75 08             	mov    0x8(%ebp),%esi
  800c91:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c94:	89 f3                	mov    %esi,%ebx
  800c96:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800c99:	89 f2                	mov    %esi,%edx
  800c9b:	eb 0f                	jmp    800cac <strncpy+0x23>
		*dst++ = *src;
  800c9d:	83 c2 01             	add    $0x1,%edx
  800ca0:	0f b6 01             	movzbl (%ecx),%eax
  800ca3:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800ca6:	80 39 01             	cmpb   $0x1,(%ecx)
  800ca9:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800cac:	39 da                	cmp    %ebx,%edx
  800cae:	75 ed                	jne    800c9d <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800cb0:	89 f0                	mov    %esi,%eax
  800cb2:	5b                   	pop    %ebx
  800cb3:	5e                   	pop    %esi
  800cb4:	5d                   	pop    %ebp
  800cb5:	c3                   	ret    

00800cb6 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800cb6:	55                   	push   %ebp
  800cb7:	89 e5                	mov    %esp,%ebp
  800cb9:	56                   	push   %esi
  800cba:	53                   	push   %ebx
  800cbb:	8b 75 08             	mov    0x8(%ebp),%esi
  800cbe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cc1:	8b 55 10             	mov    0x10(%ebp),%edx
  800cc4:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800cc6:	85 d2                	test   %edx,%edx
  800cc8:	74 21                	je     800ceb <strlcpy+0x35>
  800cca:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800cce:	89 f2                	mov    %esi,%edx
  800cd0:	eb 09                	jmp    800cdb <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800cd2:	83 c2 01             	add    $0x1,%edx
  800cd5:	83 c1 01             	add    $0x1,%ecx
  800cd8:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800cdb:	39 c2                	cmp    %eax,%edx
  800cdd:	74 09                	je     800ce8 <strlcpy+0x32>
  800cdf:	0f b6 19             	movzbl (%ecx),%ebx
  800ce2:	84 db                	test   %bl,%bl
  800ce4:	75 ec                	jne    800cd2 <strlcpy+0x1c>
  800ce6:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800ce8:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800ceb:	29 f0                	sub    %esi,%eax
}
  800ced:	5b                   	pop    %ebx
  800cee:	5e                   	pop    %esi
  800cef:	5d                   	pop    %ebp
  800cf0:	c3                   	ret    

00800cf1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800cf1:	55                   	push   %ebp
  800cf2:	89 e5                	mov    %esp,%ebp
  800cf4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800cf7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800cfa:	eb 06                	jmp    800d02 <strcmp+0x11>
		p++, q++;
  800cfc:	83 c1 01             	add    $0x1,%ecx
  800cff:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800d02:	0f b6 01             	movzbl (%ecx),%eax
  800d05:	84 c0                	test   %al,%al
  800d07:	74 04                	je     800d0d <strcmp+0x1c>
  800d09:	3a 02                	cmp    (%edx),%al
  800d0b:	74 ef                	je     800cfc <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800d0d:	0f b6 c0             	movzbl %al,%eax
  800d10:	0f b6 12             	movzbl (%edx),%edx
  800d13:	29 d0                	sub    %edx,%eax
}
  800d15:	5d                   	pop    %ebp
  800d16:	c3                   	ret    

00800d17 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800d17:	55                   	push   %ebp
  800d18:	89 e5                	mov    %esp,%ebp
  800d1a:	53                   	push   %ebx
  800d1b:	8b 45 08             	mov    0x8(%ebp),%eax
  800d1e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800d21:	89 c3                	mov    %eax,%ebx
  800d23:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800d26:	eb 06                	jmp    800d2e <strncmp+0x17>
		n--, p++, q++;
  800d28:	83 c0 01             	add    $0x1,%eax
  800d2b:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800d2e:	39 d8                	cmp    %ebx,%eax
  800d30:	74 15                	je     800d47 <strncmp+0x30>
  800d32:	0f b6 08             	movzbl (%eax),%ecx
  800d35:	84 c9                	test   %cl,%cl
  800d37:	74 04                	je     800d3d <strncmp+0x26>
  800d39:	3a 0a                	cmp    (%edx),%cl
  800d3b:	74 eb                	je     800d28 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800d3d:	0f b6 00             	movzbl (%eax),%eax
  800d40:	0f b6 12             	movzbl (%edx),%edx
  800d43:	29 d0                	sub    %edx,%eax
  800d45:	eb 05                	jmp    800d4c <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800d47:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800d4c:	5b                   	pop    %ebx
  800d4d:	5d                   	pop    %ebp
  800d4e:	c3                   	ret    

00800d4f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800d4f:	55                   	push   %ebp
  800d50:	89 e5                	mov    %esp,%ebp
  800d52:	8b 45 08             	mov    0x8(%ebp),%eax
  800d55:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800d59:	eb 07                	jmp    800d62 <strchr+0x13>
		if (*s == c)
  800d5b:	38 ca                	cmp    %cl,%dl
  800d5d:	74 0f                	je     800d6e <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800d5f:	83 c0 01             	add    $0x1,%eax
  800d62:	0f b6 10             	movzbl (%eax),%edx
  800d65:	84 d2                	test   %dl,%dl
  800d67:	75 f2                	jne    800d5b <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800d69:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800d6e:	5d                   	pop    %ebp
  800d6f:	c3                   	ret    

00800d70 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800d70:	55                   	push   %ebp
  800d71:	89 e5                	mov    %esp,%ebp
  800d73:	8b 45 08             	mov    0x8(%ebp),%eax
  800d76:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800d7a:	eb 03                	jmp    800d7f <strfind+0xf>
  800d7c:	83 c0 01             	add    $0x1,%eax
  800d7f:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  800d82:	38 ca                	cmp    %cl,%dl
  800d84:	74 04                	je     800d8a <strfind+0x1a>
  800d86:	84 d2                	test   %dl,%dl
  800d88:	75 f2                	jne    800d7c <strfind+0xc>
			break;
	return (char *) s;
}
  800d8a:	5d                   	pop    %ebp
  800d8b:	c3                   	ret    

00800d8c <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800d8c:	55                   	push   %ebp
  800d8d:	89 e5                	mov    %esp,%ebp
  800d8f:	57                   	push   %edi
  800d90:	56                   	push   %esi
  800d91:	53                   	push   %ebx
  800d92:	8b 7d 08             	mov    0x8(%ebp),%edi
  800d95:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800d98:	85 c9                	test   %ecx,%ecx
  800d9a:	74 36                	je     800dd2 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800d9c:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800da2:	75 28                	jne    800dcc <memset+0x40>
  800da4:	f6 c1 03             	test   $0x3,%cl
  800da7:	75 23                	jne    800dcc <memset+0x40>
		c &= 0xFF;
  800da9:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800dad:	89 d3                	mov    %edx,%ebx
  800daf:	c1 e3 08             	shl    $0x8,%ebx
  800db2:	89 d6                	mov    %edx,%esi
  800db4:	c1 e6 18             	shl    $0x18,%esi
  800db7:	89 d0                	mov    %edx,%eax
  800db9:	c1 e0 10             	shl    $0x10,%eax
  800dbc:	09 f0                	or     %esi,%eax
  800dbe:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
  800dc0:	89 d8                	mov    %ebx,%eax
  800dc2:	09 d0                	or     %edx,%eax
  800dc4:	c1 e9 02             	shr    $0x2,%ecx
  800dc7:	fc                   	cld    
  800dc8:	f3 ab                	rep stos %eax,%es:(%edi)
  800dca:	eb 06                	jmp    800dd2 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800dcc:	8b 45 0c             	mov    0xc(%ebp),%eax
  800dcf:	fc                   	cld    
  800dd0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800dd2:	89 f8                	mov    %edi,%eax
  800dd4:	5b                   	pop    %ebx
  800dd5:	5e                   	pop    %esi
  800dd6:	5f                   	pop    %edi
  800dd7:	5d                   	pop    %ebp
  800dd8:	c3                   	ret    

00800dd9 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800dd9:	55                   	push   %ebp
  800dda:	89 e5                	mov    %esp,%ebp
  800ddc:	57                   	push   %edi
  800ddd:	56                   	push   %esi
  800dde:	8b 45 08             	mov    0x8(%ebp),%eax
  800de1:	8b 75 0c             	mov    0xc(%ebp),%esi
  800de4:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800de7:	39 c6                	cmp    %eax,%esi
  800de9:	73 35                	jae    800e20 <memmove+0x47>
  800deb:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800dee:	39 d0                	cmp    %edx,%eax
  800df0:	73 2e                	jae    800e20 <memmove+0x47>
		s += n;
		d += n;
  800df2:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800df5:	89 d6                	mov    %edx,%esi
  800df7:	09 fe                	or     %edi,%esi
  800df9:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800dff:	75 13                	jne    800e14 <memmove+0x3b>
  800e01:	f6 c1 03             	test   $0x3,%cl
  800e04:	75 0e                	jne    800e14 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800e06:	83 ef 04             	sub    $0x4,%edi
  800e09:	8d 72 fc             	lea    -0x4(%edx),%esi
  800e0c:	c1 e9 02             	shr    $0x2,%ecx
  800e0f:	fd                   	std    
  800e10:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800e12:	eb 09                	jmp    800e1d <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800e14:	83 ef 01             	sub    $0x1,%edi
  800e17:	8d 72 ff             	lea    -0x1(%edx),%esi
  800e1a:	fd                   	std    
  800e1b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800e1d:	fc                   	cld    
  800e1e:	eb 1d                	jmp    800e3d <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800e20:	89 f2                	mov    %esi,%edx
  800e22:	09 c2                	or     %eax,%edx
  800e24:	f6 c2 03             	test   $0x3,%dl
  800e27:	75 0f                	jne    800e38 <memmove+0x5f>
  800e29:	f6 c1 03             	test   $0x3,%cl
  800e2c:	75 0a                	jne    800e38 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800e2e:	c1 e9 02             	shr    $0x2,%ecx
  800e31:	89 c7                	mov    %eax,%edi
  800e33:	fc                   	cld    
  800e34:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800e36:	eb 05                	jmp    800e3d <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800e38:	89 c7                	mov    %eax,%edi
  800e3a:	fc                   	cld    
  800e3b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800e3d:	5e                   	pop    %esi
  800e3e:	5f                   	pop    %edi
  800e3f:	5d                   	pop    %ebp
  800e40:	c3                   	ret    

00800e41 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800e41:	55                   	push   %ebp
  800e42:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800e44:	ff 75 10             	pushl  0x10(%ebp)
  800e47:	ff 75 0c             	pushl  0xc(%ebp)
  800e4a:	ff 75 08             	pushl  0x8(%ebp)
  800e4d:	e8 87 ff ff ff       	call   800dd9 <memmove>
}
  800e52:	c9                   	leave  
  800e53:	c3                   	ret    

00800e54 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800e54:	55                   	push   %ebp
  800e55:	89 e5                	mov    %esp,%ebp
  800e57:	56                   	push   %esi
  800e58:	53                   	push   %ebx
  800e59:	8b 45 08             	mov    0x8(%ebp),%eax
  800e5c:	8b 55 0c             	mov    0xc(%ebp),%edx
  800e5f:	89 c6                	mov    %eax,%esi
  800e61:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800e64:	eb 1a                	jmp    800e80 <memcmp+0x2c>
		if (*s1 != *s2)
  800e66:	0f b6 08             	movzbl (%eax),%ecx
  800e69:	0f b6 1a             	movzbl (%edx),%ebx
  800e6c:	38 d9                	cmp    %bl,%cl
  800e6e:	74 0a                	je     800e7a <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800e70:	0f b6 c1             	movzbl %cl,%eax
  800e73:	0f b6 db             	movzbl %bl,%ebx
  800e76:	29 d8                	sub    %ebx,%eax
  800e78:	eb 0f                	jmp    800e89 <memcmp+0x35>
		s1++, s2++;
  800e7a:	83 c0 01             	add    $0x1,%eax
  800e7d:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800e80:	39 f0                	cmp    %esi,%eax
  800e82:	75 e2                	jne    800e66 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800e84:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800e89:	5b                   	pop    %ebx
  800e8a:	5e                   	pop    %esi
  800e8b:	5d                   	pop    %ebp
  800e8c:	c3                   	ret    

00800e8d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800e8d:	55                   	push   %ebp
  800e8e:	89 e5                	mov    %esp,%ebp
  800e90:	53                   	push   %ebx
  800e91:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  800e94:	89 c1                	mov    %eax,%ecx
  800e96:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  800e99:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800e9d:	eb 0a                	jmp    800ea9 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800e9f:	0f b6 10             	movzbl (%eax),%edx
  800ea2:	39 da                	cmp    %ebx,%edx
  800ea4:	74 07                	je     800ead <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800ea6:	83 c0 01             	add    $0x1,%eax
  800ea9:	39 c8                	cmp    %ecx,%eax
  800eab:	72 f2                	jb     800e9f <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800ead:	5b                   	pop    %ebx
  800eae:	5d                   	pop    %ebp
  800eaf:	c3                   	ret    

00800eb0 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800eb0:	55                   	push   %ebp
  800eb1:	89 e5                	mov    %esp,%ebp
  800eb3:	57                   	push   %edi
  800eb4:	56                   	push   %esi
  800eb5:	53                   	push   %ebx
  800eb6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800eb9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800ebc:	eb 03                	jmp    800ec1 <strtol+0x11>
		s++;
  800ebe:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800ec1:	0f b6 01             	movzbl (%ecx),%eax
  800ec4:	3c 20                	cmp    $0x20,%al
  800ec6:	74 f6                	je     800ebe <strtol+0xe>
  800ec8:	3c 09                	cmp    $0x9,%al
  800eca:	74 f2                	je     800ebe <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800ecc:	3c 2b                	cmp    $0x2b,%al
  800ece:	75 0a                	jne    800eda <strtol+0x2a>
		s++;
  800ed0:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800ed3:	bf 00 00 00 00       	mov    $0x0,%edi
  800ed8:	eb 11                	jmp    800eeb <strtol+0x3b>
  800eda:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800edf:	3c 2d                	cmp    $0x2d,%al
  800ee1:	75 08                	jne    800eeb <strtol+0x3b>
		s++, neg = 1;
  800ee3:	83 c1 01             	add    $0x1,%ecx
  800ee6:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800eeb:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800ef1:	75 15                	jne    800f08 <strtol+0x58>
  800ef3:	80 39 30             	cmpb   $0x30,(%ecx)
  800ef6:	75 10                	jne    800f08 <strtol+0x58>
  800ef8:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800efc:	75 7c                	jne    800f7a <strtol+0xca>
		s += 2, base = 16;
  800efe:	83 c1 02             	add    $0x2,%ecx
  800f01:	bb 10 00 00 00       	mov    $0x10,%ebx
  800f06:	eb 16                	jmp    800f1e <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800f08:	85 db                	test   %ebx,%ebx
  800f0a:	75 12                	jne    800f1e <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800f0c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800f11:	80 39 30             	cmpb   $0x30,(%ecx)
  800f14:	75 08                	jne    800f1e <strtol+0x6e>
		s++, base = 8;
  800f16:	83 c1 01             	add    $0x1,%ecx
  800f19:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800f1e:	b8 00 00 00 00       	mov    $0x0,%eax
  800f23:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800f26:	0f b6 11             	movzbl (%ecx),%edx
  800f29:	8d 72 d0             	lea    -0x30(%edx),%esi
  800f2c:	89 f3                	mov    %esi,%ebx
  800f2e:	80 fb 09             	cmp    $0x9,%bl
  800f31:	77 08                	ja     800f3b <strtol+0x8b>
			dig = *s - '0';
  800f33:	0f be d2             	movsbl %dl,%edx
  800f36:	83 ea 30             	sub    $0x30,%edx
  800f39:	eb 22                	jmp    800f5d <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800f3b:	8d 72 9f             	lea    -0x61(%edx),%esi
  800f3e:	89 f3                	mov    %esi,%ebx
  800f40:	80 fb 19             	cmp    $0x19,%bl
  800f43:	77 08                	ja     800f4d <strtol+0x9d>
			dig = *s - 'a' + 10;
  800f45:	0f be d2             	movsbl %dl,%edx
  800f48:	83 ea 57             	sub    $0x57,%edx
  800f4b:	eb 10                	jmp    800f5d <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800f4d:	8d 72 bf             	lea    -0x41(%edx),%esi
  800f50:	89 f3                	mov    %esi,%ebx
  800f52:	80 fb 19             	cmp    $0x19,%bl
  800f55:	77 16                	ja     800f6d <strtol+0xbd>
			dig = *s - 'A' + 10;
  800f57:	0f be d2             	movsbl %dl,%edx
  800f5a:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800f5d:	3b 55 10             	cmp    0x10(%ebp),%edx
  800f60:	7d 0b                	jge    800f6d <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800f62:	83 c1 01             	add    $0x1,%ecx
  800f65:	0f af 45 10          	imul   0x10(%ebp),%eax
  800f69:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800f6b:	eb b9                	jmp    800f26 <strtol+0x76>

	if (endptr)
  800f6d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800f71:	74 0d                	je     800f80 <strtol+0xd0>
		*endptr = (char *) s;
  800f73:	8b 75 0c             	mov    0xc(%ebp),%esi
  800f76:	89 0e                	mov    %ecx,(%esi)
  800f78:	eb 06                	jmp    800f80 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800f7a:	85 db                	test   %ebx,%ebx
  800f7c:	74 98                	je     800f16 <strtol+0x66>
  800f7e:	eb 9e                	jmp    800f1e <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800f80:	89 c2                	mov    %eax,%edx
  800f82:	f7 da                	neg    %edx
  800f84:	85 ff                	test   %edi,%edi
  800f86:	0f 45 c2             	cmovne %edx,%eax
}
  800f89:	5b                   	pop    %ebx
  800f8a:	5e                   	pop    %esi
  800f8b:	5f                   	pop    %edi
  800f8c:	5d                   	pop    %ebp
  800f8d:	c3                   	ret    

00800f8e <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800f8e:	55                   	push   %ebp
  800f8f:	89 e5                	mov    %esp,%ebp
  800f91:	57                   	push   %edi
  800f92:	56                   	push   %esi
  800f93:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800f94:	b8 00 00 00 00       	mov    $0x0,%eax
  800f99:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800f9c:	8b 55 08             	mov    0x8(%ebp),%edx
  800f9f:	89 c3                	mov    %eax,%ebx
  800fa1:	89 c7                	mov    %eax,%edi
  800fa3:	89 c6                	mov    %eax,%esi
  800fa5:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800fa7:	5b                   	pop    %ebx
  800fa8:	5e                   	pop    %esi
  800fa9:	5f                   	pop    %edi
  800faa:	5d                   	pop    %ebp
  800fab:	c3                   	ret    

00800fac <sys_cgetc>:

int
sys_cgetc(void)
{
  800fac:	55                   	push   %ebp
  800fad:	89 e5                	mov    %esp,%ebp
  800faf:	57                   	push   %edi
  800fb0:	56                   	push   %esi
  800fb1:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800fb2:	ba 00 00 00 00       	mov    $0x0,%edx
  800fb7:	b8 01 00 00 00       	mov    $0x1,%eax
  800fbc:	89 d1                	mov    %edx,%ecx
  800fbe:	89 d3                	mov    %edx,%ebx
  800fc0:	89 d7                	mov    %edx,%edi
  800fc2:	89 d6                	mov    %edx,%esi
  800fc4:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800fc6:	5b                   	pop    %ebx
  800fc7:	5e                   	pop    %esi
  800fc8:	5f                   	pop    %edi
  800fc9:	5d                   	pop    %ebp
  800fca:	c3                   	ret    

00800fcb <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800fcb:	55                   	push   %ebp
  800fcc:	89 e5                	mov    %esp,%ebp
  800fce:	57                   	push   %edi
  800fcf:	56                   	push   %esi
  800fd0:	53                   	push   %ebx
  800fd1:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800fd4:	b9 00 00 00 00       	mov    $0x0,%ecx
  800fd9:	b8 03 00 00 00       	mov    $0x3,%eax
  800fde:	8b 55 08             	mov    0x8(%ebp),%edx
  800fe1:	89 cb                	mov    %ecx,%ebx
  800fe3:	89 cf                	mov    %ecx,%edi
  800fe5:	89 ce                	mov    %ecx,%esi
  800fe7:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800fe9:	85 c0                	test   %eax,%eax
  800feb:	7e 17                	jle    801004 <sys_env_destroy+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  800fed:	83 ec 0c             	sub    $0xc,%esp
  800ff0:	50                   	push   %eax
  800ff1:	6a 03                	push   $0x3
  800ff3:	68 48 18 80 00       	push   $0x801848
  800ff8:	6a 23                	push   $0x23
  800ffa:	68 65 18 80 00       	push   $0x801865
  800fff:	e8 e5 f5 ff ff       	call   8005e9 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  801004:	8d 65 f4             	lea    -0xc(%ebp),%esp
  801007:	5b                   	pop    %ebx
  801008:	5e                   	pop    %esi
  801009:	5f                   	pop    %edi
  80100a:	5d                   	pop    %ebp
  80100b:	c3                   	ret    

0080100c <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  80100c:	55                   	push   %ebp
  80100d:	89 e5                	mov    %esp,%ebp
  80100f:	57                   	push   %edi
  801010:	56                   	push   %esi
  801011:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801012:	ba 00 00 00 00       	mov    $0x0,%edx
  801017:	b8 02 00 00 00       	mov    $0x2,%eax
  80101c:	89 d1                	mov    %edx,%ecx
  80101e:	89 d3                	mov    %edx,%ebx
  801020:	89 d7                	mov    %edx,%edi
  801022:	89 d6                	mov    %edx,%esi
  801024:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  801026:	5b                   	pop    %ebx
  801027:	5e                   	pop    %esi
  801028:	5f                   	pop    %edi
  801029:	5d                   	pop    %ebp
  80102a:	c3                   	ret    

0080102b <sys_yield>:

void
sys_yield(void)
{
  80102b:	55                   	push   %ebp
  80102c:	89 e5                	mov    %esp,%ebp
  80102e:	57                   	push   %edi
  80102f:	56                   	push   %esi
  801030:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801031:	ba 00 00 00 00       	mov    $0x0,%edx
  801036:	b8 0a 00 00 00       	mov    $0xa,%eax
  80103b:	89 d1                	mov    %edx,%ecx
  80103d:	89 d3                	mov    %edx,%ebx
  80103f:	89 d7                	mov    %edx,%edi
  801041:	89 d6                	mov    %edx,%esi
  801043:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  801045:	5b                   	pop    %ebx
  801046:	5e                   	pop    %esi
  801047:	5f                   	pop    %edi
  801048:	5d                   	pop    %ebp
  801049:	c3                   	ret    

0080104a <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  80104a:	55                   	push   %ebp
  80104b:	89 e5                	mov    %esp,%ebp
  80104d:	57                   	push   %edi
  80104e:	56                   	push   %esi
  80104f:	53                   	push   %ebx
  801050:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801053:	be 00 00 00 00       	mov    $0x0,%esi
  801058:	b8 04 00 00 00       	mov    $0x4,%eax
  80105d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  801060:	8b 55 08             	mov    0x8(%ebp),%edx
  801063:	8b 5d 10             	mov    0x10(%ebp),%ebx
  801066:	89 f7                	mov    %esi,%edi
  801068:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80106a:	85 c0                	test   %eax,%eax
  80106c:	7e 17                	jle    801085 <sys_page_alloc+0x3b>
		panic("syscall %d returned %d (> 0)", num, ret);
  80106e:	83 ec 0c             	sub    $0xc,%esp
  801071:	50                   	push   %eax
  801072:	6a 04                	push   $0x4
  801074:	68 48 18 80 00       	push   $0x801848
  801079:	6a 23                	push   $0x23
  80107b:	68 65 18 80 00       	push   $0x801865
  801080:	e8 64 f5 ff ff       	call   8005e9 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  801085:	8d 65 f4             	lea    -0xc(%ebp),%esp
  801088:	5b                   	pop    %ebx
  801089:	5e                   	pop    %esi
  80108a:	5f                   	pop    %edi
  80108b:	5d                   	pop    %ebp
  80108c:	c3                   	ret    

0080108d <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  80108d:	55                   	push   %ebp
  80108e:	89 e5                	mov    %esp,%ebp
  801090:	57                   	push   %edi
  801091:	56                   	push   %esi
  801092:	53                   	push   %ebx
  801093:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801096:	b8 05 00 00 00       	mov    $0x5,%eax
  80109b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80109e:	8b 55 08             	mov    0x8(%ebp),%edx
  8010a1:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8010a4:	8b 7d 14             	mov    0x14(%ebp),%edi
  8010a7:	8b 75 18             	mov    0x18(%ebp),%esi
  8010aa:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8010ac:	85 c0                	test   %eax,%eax
  8010ae:	7e 17                	jle    8010c7 <sys_page_map+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  8010b0:	83 ec 0c             	sub    $0xc,%esp
  8010b3:	50                   	push   %eax
  8010b4:	6a 05                	push   $0x5
  8010b6:	68 48 18 80 00       	push   $0x801848
  8010bb:	6a 23                	push   $0x23
  8010bd:	68 65 18 80 00       	push   $0x801865
  8010c2:	e8 22 f5 ff ff       	call   8005e9 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  8010c7:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8010ca:	5b                   	pop    %ebx
  8010cb:	5e                   	pop    %esi
  8010cc:	5f                   	pop    %edi
  8010cd:	5d                   	pop    %ebp
  8010ce:	c3                   	ret    

008010cf <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  8010cf:	55                   	push   %ebp
  8010d0:	89 e5                	mov    %esp,%ebp
  8010d2:	57                   	push   %edi
  8010d3:	56                   	push   %esi
  8010d4:	53                   	push   %ebx
  8010d5:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8010d8:	bb 00 00 00 00       	mov    $0x0,%ebx
  8010dd:	b8 06 00 00 00       	mov    $0x6,%eax
  8010e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8010e5:	8b 55 08             	mov    0x8(%ebp),%edx
  8010e8:	89 df                	mov    %ebx,%edi
  8010ea:	89 de                	mov    %ebx,%esi
  8010ec:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8010ee:	85 c0                	test   %eax,%eax
  8010f0:	7e 17                	jle    801109 <sys_page_unmap+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  8010f2:	83 ec 0c             	sub    $0xc,%esp
  8010f5:	50                   	push   %eax
  8010f6:	6a 06                	push   $0x6
  8010f8:	68 48 18 80 00       	push   $0x801848
  8010fd:	6a 23                	push   $0x23
  8010ff:	68 65 18 80 00       	push   $0x801865
  801104:	e8 e0 f4 ff ff       	call   8005e9 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  801109:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80110c:	5b                   	pop    %ebx
  80110d:	5e                   	pop    %esi
  80110e:	5f                   	pop    %edi
  80110f:	5d                   	pop    %ebp
  801110:	c3                   	ret    

00801111 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  801111:	55                   	push   %ebp
  801112:	89 e5                	mov    %esp,%ebp
  801114:	57                   	push   %edi
  801115:	56                   	push   %esi
  801116:	53                   	push   %ebx
  801117:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80111a:	bb 00 00 00 00       	mov    $0x0,%ebx
  80111f:	b8 08 00 00 00       	mov    $0x8,%eax
  801124:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  801127:	8b 55 08             	mov    0x8(%ebp),%edx
  80112a:	89 df                	mov    %ebx,%edi
  80112c:	89 de                	mov    %ebx,%esi
  80112e:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  801130:	85 c0                	test   %eax,%eax
  801132:	7e 17                	jle    80114b <sys_env_set_status+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  801134:	83 ec 0c             	sub    $0xc,%esp
  801137:	50                   	push   %eax
  801138:	6a 08                	push   $0x8
  80113a:	68 48 18 80 00       	push   $0x801848
  80113f:	6a 23                	push   $0x23
  801141:	68 65 18 80 00       	push   $0x801865
  801146:	e8 9e f4 ff ff       	call   8005e9 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  80114b:	8d 65 f4             	lea    -0xc(%ebp),%esp
  80114e:	5b                   	pop    %ebx
  80114f:	5e                   	pop    %esi
  801150:	5f                   	pop    %edi
  801151:	5d                   	pop    %ebp
  801152:	c3                   	ret    

00801153 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  801153:	55                   	push   %ebp
  801154:	89 e5                	mov    %esp,%ebp
  801156:	57                   	push   %edi
  801157:	56                   	push   %esi
  801158:	53                   	push   %ebx
  801159:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80115c:	bb 00 00 00 00       	mov    $0x0,%ebx
  801161:	b8 09 00 00 00       	mov    $0x9,%eax
  801166:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  801169:	8b 55 08             	mov    0x8(%ebp),%edx
  80116c:	89 df                	mov    %ebx,%edi
  80116e:	89 de                	mov    %ebx,%esi
  801170:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  801172:	85 c0                	test   %eax,%eax
  801174:	7e 17                	jle    80118d <sys_env_set_pgfault_upcall+0x3a>
		panic("syscall %d returned %d (> 0)", num, ret);
  801176:	83 ec 0c             	sub    $0xc,%esp
  801179:	50                   	push   %eax
  80117a:	6a 09                	push   $0x9
  80117c:	68 48 18 80 00       	push   $0x801848
  801181:	6a 23                	push   $0x23
  801183:	68 65 18 80 00       	push   $0x801865
  801188:	e8 5c f4 ff ff       	call   8005e9 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  80118d:	8d 65 f4             	lea    -0xc(%ebp),%esp
  801190:	5b                   	pop    %ebx
  801191:	5e                   	pop    %esi
  801192:	5f                   	pop    %edi
  801193:	5d                   	pop    %ebp
  801194:	c3                   	ret    

00801195 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  801195:	55                   	push   %ebp
  801196:	89 e5                	mov    %esp,%ebp
  801198:	57                   	push   %edi
  801199:	56                   	push   %esi
  80119a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80119b:	be 00 00 00 00       	mov    $0x0,%esi
  8011a0:	b8 0b 00 00 00       	mov    $0xb,%eax
  8011a5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8011a8:	8b 55 08             	mov    0x8(%ebp),%edx
  8011ab:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8011ae:	8b 7d 14             	mov    0x14(%ebp),%edi
  8011b1:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  8011b3:	5b                   	pop    %ebx
  8011b4:	5e                   	pop    %esi
  8011b5:	5f                   	pop    %edi
  8011b6:	5d                   	pop    %ebp
  8011b7:	c3                   	ret    

008011b8 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  8011b8:	55                   	push   %ebp
  8011b9:	89 e5                	mov    %esp,%ebp
  8011bb:	57                   	push   %edi
  8011bc:	56                   	push   %esi
  8011bd:	53                   	push   %ebx
  8011be:	83 ec 0c             	sub    $0xc,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8011c1:	b9 00 00 00 00       	mov    $0x0,%ecx
  8011c6:	b8 0c 00 00 00       	mov    $0xc,%eax
  8011cb:	8b 55 08             	mov    0x8(%ebp),%edx
  8011ce:	89 cb                	mov    %ecx,%ebx
  8011d0:	89 cf                	mov    %ecx,%edi
  8011d2:	89 ce                	mov    %ecx,%esi
  8011d4:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8011d6:	85 c0                	test   %eax,%eax
  8011d8:	7e 17                	jle    8011f1 <sys_ipc_recv+0x39>
		panic("syscall %d returned %d (> 0)", num, ret);
  8011da:	83 ec 0c             	sub    $0xc,%esp
  8011dd:	50                   	push   %eax
  8011de:	6a 0c                	push   $0xc
  8011e0:	68 48 18 80 00       	push   $0x801848
  8011e5:	6a 23                	push   $0x23
  8011e7:	68 65 18 80 00       	push   $0x801865
  8011ec:	e8 f8 f3 ff ff       	call   8005e9 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  8011f1:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8011f4:	5b                   	pop    %ebx
  8011f5:	5e                   	pop    %esi
  8011f6:	5f                   	pop    %edi
  8011f7:	5d                   	pop    %ebp
  8011f8:	c3                   	ret    

008011f9 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  8011f9:	55                   	push   %ebp
  8011fa:	89 e5                	mov    %esp,%ebp
  8011fc:	83 ec 08             	sub    $0x8,%esp
	int r;

	if (_pgfault_handler == 0) {
  8011ff:	83 3d d0 20 80 00 00 	cmpl   $0x0,0x8020d0
  801206:	75 14                	jne    80121c <set_pgfault_handler+0x23>
		// First time through!
		// LAB 4: Your code here.
		panic("set_pgfault_handler not implemented");
  801208:	83 ec 04             	sub    $0x4,%esp
  80120b:	68 74 18 80 00       	push   $0x801874
  801210:	6a 20                	push   $0x20
  801212:	68 98 18 80 00       	push   $0x801898
  801217:	e8 cd f3 ff ff       	call   8005e9 <_panic>
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  80121c:	8b 45 08             	mov    0x8(%ebp),%eax
  80121f:	a3 d0 20 80 00       	mov    %eax,0x8020d0
}
  801224:	c9                   	leave  
  801225:	c3                   	ret    
  801226:	66 90                	xchg   %ax,%ax
  801228:	66 90                	xchg   %ax,%ax
  80122a:	66 90                	xchg   %ax,%ax
  80122c:	66 90                	xchg   %ax,%ax
  80122e:	66 90                	xchg   %ax,%ax

00801230 <__udivdi3>:
  801230:	55                   	push   %ebp
  801231:	57                   	push   %edi
  801232:	56                   	push   %esi
  801233:	53                   	push   %ebx
  801234:	83 ec 1c             	sub    $0x1c,%esp
  801237:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  80123b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  80123f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  801243:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801247:	85 f6                	test   %esi,%esi
  801249:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80124d:	89 ca                	mov    %ecx,%edx
  80124f:	89 f8                	mov    %edi,%eax
  801251:	75 3d                	jne    801290 <__udivdi3+0x60>
  801253:	39 cf                	cmp    %ecx,%edi
  801255:	0f 87 c5 00 00 00    	ja     801320 <__udivdi3+0xf0>
  80125b:	85 ff                	test   %edi,%edi
  80125d:	89 fd                	mov    %edi,%ebp
  80125f:	75 0b                	jne    80126c <__udivdi3+0x3c>
  801261:	b8 01 00 00 00       	mov    $0x1,%eax
  801266:	31 d2                	xor    %edx,%edx
  801268:	f7 f7                	div    %edi
  80126a:	89 c5                	mov    %eax,%ebp
  80126c:	89 c8                	mov    %ecx,%eax
  80126e:	31 d2                	xor    %edx,%edx
  801270:	f7 f5                	div    %ebp
  801272:	89 c1                	mov    %eax,%ecx
  801274:	89 d8                	mov    %ebx,%eax
  801276:	89 cf                	mov    %ecx,%edi
  801278:	f7 f5                	div    %ebp
  80127a:	89 c3                	mov    %eax,%ebx
  80127c:	89 d8                	mov    %ebx,%eax
  80127e:	89 fa                	mov    %edi,%edx
  801280:	83 c4 1c             	add    $0x1c,%esp
  801283:	5b                   	pop    %ebx
  801284:	5e                   	pop    %esi
  801285:	5f                   	pop    %edi
  801286:	5d                   	pop    %ebp
  801287:	c3                   	ret    
  801288:	90                   	nop
  801289:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801290:	39 ce                	cmp    %ecx,%esi
  801292:	77 74                	ja     801308 <__udivdi3+0xd8>
  801294:	0f bd fe             	bsr    %esi,%edi
  801297:	83 f7 1f             	xor    $0x1f,%edi
  80129a:	0f 84 98 00 00 00    	je     801338 <__udivdi3+0x108>
  8012a0:	bb 20 00 00 00       	mov    $0x20,%ebx
  8012a5:	89 f9                	mov    %edi,%ecx
  8012a7:	89 c5                	mov    %eax,%ebp
  8012a9:	29 fb                	sub    %edi,%ebx
  8012ab:	d3 e6                	shl    %cl,%esi
  8012ad:	89 d9                	mov    %ebx,%ecx
  8012af:	d3 ed                	shr    %cl,%ebp
  8012b1:	89 f9                	mov    %edi,%ecx
  8012b3:	d3 e0                	shl    %cl,%eax
  8012b5:	09 ee                	or     %ebp,%esi
  8012b7:	89 d9                	mov    %ebx,%ecx
  8012b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8012bd:	89 d5                	mov    %edx,%ebp
  8012bf:	8b 44 24 08          	mov    0x8(%esp),%eax
  8012c3:	d3 ed                	shr    %cl,%ebp
  8012c5:	89 f9                	mov    %edi,%ecx
  8012c7:	d3 e2                	shl    %cl,%edx
  8012c9:	89 d9                	mov    %ebx,%ecx
  8012cb:	d3 e8                	shr    %cl,%eax
  8012cd:	09 c2                	or     %eax,%edx
  8012cf:	89 d0                	mov    %edx,%eax
  8012d1:	89 ea                	mov    %ebp,%edx
  8012d3:	f7 f6                	div    %esi
  8012d5:	89 d5                	mov    %edx,%ebp
  8012d7:	89 c3                	mov    %eax,%ebx
  8012d9:	f7 64 24 0c          	mull   0xc(%esp)
  8012dd:	39 d5                	cmp    %edx,%ebp
  8012df:	72 10                	jb     8012f1 <__udivdi3+0xc1>
  8012e1:	8b 74 24 08          	mov    0x8(%esp),%esi
  8012e5:	89 f9                	mov    %edi,%ecx
  8012e7:	d3 e6                	shl    %cl,%esi
  8012e9:	39 c6                	cmp    %eax,%esi
  8012eb:	73 07                	jae    8012f4 <__udivdi3+0xc4>
  8012ed:	39 d5                	cmp    %edx,%ebp
  8012ef:	75 03                	jne    8012f4 <__udivdi3+0xc4>
  8012f1:	83 eb 01             	sub    $0x1,%ebx
  8012f4:	31 ff                	xor    %edi,%edi
  8012f6:	89 d8                	mov    %ebx,%eax
  8012f8:	89 fa                	mov    %edi,%edx
  8012fa:	83 c4 1c             	add    $0x1c,%esp
  8012fd:	5b                   	pop    %ebx
  8012fe:	5e                   	pop    %esi
  8012ff:	5f                   	pop    %edi
  801300:	5d                   	pop    %ebp
  801301:	c3                   	ret    
  801302:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801308:	31 ff                	xor    %edi,%edi
  80130a:	31 db                	xor    %ebx,%ebx
  80130c:	89 d8                	mov    %ebx,%eax
  80130e:	89 fa                	mov    %edi,%edx
  801310:	83 c4 1c             	add    $0x1c,%esp
  801313:	5b                   	pop    %ebx
  801314:	5e                   	pop    %esi
  801315:	5f                   	pop    %edi
  801316:	5d                   	pop    %ebp
  801317:	c3                   	ret    
  801318:	90                   	nop
  801319:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801320:	89 d8                	mov    %ebx,%eax
  801322:	f7 f7                	div    %edi
  801324:	31 ff                	xor    %edi,%edi
  801326:	89 c3                	mov    %eax,%ebx
  801328:	89 d8                	mov    %ebx,%eax
  80132a:	89 fa                	mov    %edi,%edx
  80132c:	83 c4 1c             	add    $0x1c,%esp
  80132f:	5b                   	pop    %ebx
  801330:	5e                   	pop    %esi
  801331:	5f                   	pop    %edi
  801332:	5d                   	pop    %ebp
  801333:	c3                   	ret    
  801334:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801338:	39 ce                	cmp    %ecx,%esi
  80133a:	72 0c                	jb     801348 <__udivdi3+0x118>
  80133c:	31 db                	xor    %ebx,%ebx
  80133e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  801342:	0f 87 34 ff ff ff    	ja     80127c <__udivdi3+0x4c>
  801348:	bb 01 00 00 00       	mov    $0x1,%ebx
  80134d:	e9 2a ff ff ff       	jmp    80127c <__udivdi3+0x4c>
  801352:	66 90                	xchg   %ax,%ax
  801354:	66 90                	xchg   %ax,%ax
  801356:	66 90                	xchg   %ax,%ax
  801358:	66 90                	xchg   %ax,%ax
  80135a:	66 90                	xchg   %ax,%ax
  80135c:	66 90                	xchg   %ax,%ax
  80135e:	66 90                	xchg   %ax,%ax

00801360 <__umoddi3>:
  801360:	55                   	push   %ebp
  801361:	57                   	push   %edi
  801362:	56                   	push   %esi
  801363:	53                   	push   %ebx
  801364:	83 ec 1c             	sub    $0x1c,%esp
  801367:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  80136b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  80136f:	8b 74 24 34          	mov    0x34(%esp),%esi
  801373:	8b 7c 24 38          	mov    0x38(%esp),%edi
  801377:	85 d2                	test   %edx,%edx
  801379:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  80137d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  801381:	89 f3                	mov    %esi,%ebx
  801383:	89 3c 24             	mov    %edi,(%esp)
  801386:	89 74 24 04          	mov    %esi,0x4(%esp)
  80138a:	75 1c                	jne    8013a8 <__umoddi3+0x48>
  80138c:	39 f7                	cmp    %esi,%edi
  80138e:	76 50                	jbe    8013e0 <__umoddi3+0x80>
  801390:	89 c8                	mov    %ecx,%eax
  801392:	89 f2                	mov    %esi,%edx
  801394:	f7 f7                	div    %edi
  801396:	89 d0                	mov    %edx,%eax
  801398:	31 d2                	xor    %edx,%edx
  80139a:	83 c4 1c             	add    $0x1c,%esp
  80139d:	5b                   	pop    %ebx
  80139e:	5e                   	pop    %esi
  80139f:	5f                   	pop    %edi
  8013a0:	5d                   	pop    %ebp
  8013a1:	c3                   	ret    
  8013a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8013a8:	39 f2                	cmp    %esi,%edx
  8013aa:	89 d0                	mov    %edx,%eax
  8013ac:	77 52                	ja     801400 <__umoddi3+0xa0>
  8013ae:	0f bd ea             	bsr    %edx,%ebp
  8013b1:	83 f5 1f             	xor    $0x1f,%ebp
  8013b4:	75 5a                	jne    801410 <__umoddi3+0xb0>
  8013b6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  8013ba:	0f 82 e0 00 00 00    	jb     8014a0 <__umoddi3+0x140>
  8013c0:	39 0c 24             	cmp    %ecx,(%esp)
  8013c3:	0f 86 d7 00 00 00    	jbe    8014a0 <__umoddi3+0x140>
  8013c9:	8b 44 24 08          	mov    0x8(%esp),%eax
  8013cd:	8b 54 24 04          	mov    0x4(%esp),%edx
  8013d1:	83 c4 1c             	add    $0x1c,%esp
  8013d4:	5b                   	pop    %ebx
  8013d5:	5e                   	pop    %esi
  8013d6:	5f                   	pop    %edi
  8013d7:	5d                   	pop    %ebp
  8013d8:	c3                   	ret    
  8013d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8013e0:	85 ff                	test   %edi,%edi
  8013e2:	89 fd                	mov    %edi,%ebp
  8013e4:	75 0b                	jne    8013f1 <__umoddi3+0x91>
  8013e6:	b8 01 00 00 00       	mov    $0x1,%eax
  8013eb:	31 d2                	xor    %edx,%edx
  8013ed:	f7 f7                	div    %edi
  8013ef:	89 c5                	mov    %eax,%ebp
  8013f1:	89 f0                	mov    %esi,%eax
  8013f3:	31 d2                	xor    %edx,%edx
  8013f5:	f7 f5                	div    %ebp
  8013f7:	89 c8                	mov    %ecx,%eax
  8013f9:	f7 f5                	div    %ebp
  8013fb:	89 d0                	mov    %edx,%eax
  8013fd:	eb 99                	jmp    801398 <__umoddi3+0x38>
  8013ff:	90                   	nop
  801400:	89 c8                	mov    %ecx,%eax
  801402:	89 f2                	mov    %esi,%edx
  801404:	83 c4 1c             	add    $0x1c,%esp
  801407:	5b                   	pop    %ebx
  801408:	5e                   	pop    %esi
  801409:	5f                   	pop    %edi
  80140a:	5d                   	pop    %ebp
  80140b:	c3                   	ret    
  80140c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801410:	8b 34 24             	mov    (%esp),%esi
  801413:	bf 20 00 00 00       	mov    $0x20,%edi
  801418:	89 e9                	mov    %ebp,%ecx
  80141a:	29 ef                	sub    %ebp,%edi
  80141c:	d3 e0                	shl    %cl,%eax
  80141e:	89 f9                	mov    %edi,%ecx
  801420:	89 f2                	mov    %esi,%edx
  801422:	d3 ea                	shr    %cl,%edx
  801424:	89 e9                	mov    %ebp,%ecx
  801426:	09 c2                	or     %eax,%edx
  801428:	89 d8                	mov    %ebx,%eax
  80142a:	89 14 24             	mov    %edx,(%esp)
  80142d:	89 f2                	mov    %esi,%edx
  80142f:	d3 e2                	shl    %cl,%edx
  801431:	89 f9                	mov    %edi,%ecx
  801433:	89 54 24 04          	mov    %edx,0x4(%esp)
  801437:	8b 54 24 0c          	mov    0xc(%esp),%edx
  80143b:	d3 e8                	shr    %cl,%eax
  80143d:	89 e9                	mov    %ebp,%ecx
  80143f:	89 c6                	mov    %eax,%esi
  801441:	d3 e3                	shl    %cl,%ebx
  801443:	89 f9                	mov    %edi,%ecx
  801445:	89 d0                	mov    %edx,%eax
  801447:	d3 e8                	shr    %cl,%eax
  801449:	89 e9                	mov    %ebp,%ecx
  80144b:	09 d8                	or     %ebx,%eax
  80144d:	89 d3                	mov    %edx,%ebx
  80144f:	89 f2                	mov    %esi,%edx
  801451:	f7 34 24             	divl   (%esp)
  801454:	89 d6                	mov    %edx,%esi
  801456:	d3 e3                	shl    %cl,%ebx
  801458:	f7 64 24 04          	mull   0x4(%esp)
  80145c:	39 d6                	cmp    %edx,%esi
  80145e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  801462:	89 d1                	mov    %edx,%ecx
  801464:	89 c3                	mov    %eax,%ebx
  801466:	72 08                	jb     801470 <__umoddi3+0x110>
  801468:	75 11                	jne    80147b <__umoddi3+0x11b>
  80146a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  80146e:	73 0b                	jae    80147b <__umoddi3+0x11b>
  801470:	2b 44 24 04          	sub    0x4(%esp),%eax
  801474:	1b 14 24             	sbb    (%esp),%edx
  801477:	89 d1                	mov    %edx,%ecx
  801479:	89 c3                	mov    %eax,%ebx
  80147b:	8b 54 24 08          	mov    0x8(%esp),%edx
  80147f:	29 da                	sub    %ebx,%edx
  801481:	19 ce                	sbb    %ecx,%esi
  801483:	89 f9                	mov    %edi,%ecx
  801485:	89 f0                	mov    %esi,%eax
  801487:	d3 e0                	shl    %cl,%eax
  801489:	89 e9                	mov    %ebp,%ecx
  80148b:	d3 ea                	shr    %cl,%edx
  80148d:	89 e9                	mov    %ebp,%ecx
  80148f:	d3 ee                	shr    %cl,%esi
  801491:	09 d0                	or     %edx,%eax
  801493:	89 f2                	mov    %esi,%edx
  801495:	83 c4 1c             	add    $0x1c,%esp
  801498:	5b                   	pop    %ebx
  801499:	5e                   	pop    %esi
  80149a:	5f                   	pop    %edi
  80149b:	5d                   	pop    %ebp
  80149c:	c3                   	ret    
  80149d:	8d 76 00             	lea    0x0(%esi),%esi
  8014a0:	29 f9                	sub    %edi,%ecx
  8014a2:	19 d6                	sbb    %edx,%esi
  8014a4:	89 74 24 04          	mov    %esi,0x4(%esp)
  8014a8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8014ac:	e9 18 ff ff ff       	jmp    8013c9 <__umoddi3+0x69>

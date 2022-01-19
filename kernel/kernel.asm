
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	f9478793          	addi	a5,a5,-108 # 80005ff0 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e1878793          	addi	a5,a5,-488 # 80000ebe <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	78a080e7          	jalr	1930(ra) # 800028b0 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b76080e7          	jalr	-1162(ra) # 80000cc4 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	b16080e7          	jalr	-1258(ra) # 80001ce4 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	41a080e7          	jalr	1050(ra) # 800025f8 <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	640080e7          	jalr	1600(ra) # 8000285a <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a78080e7          	jalr	-1416(ra) # 80000cc4 <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	932080e7          	jalr	-1742(ra) # 80000c10 <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	60a080e7          	jalr	1546(ra) # 80002906 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9b8080e7          	jalr	-1608(ra) # 80000cc4 <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	32e080e7          	jalr	814(ra) # 8000277e <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	b9e58593          	addi	a1,a1,-1122 # 80008000 <etext>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	70e080e7          	jalr	1806(ra) # 80000b80 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00022797          	auipc	a5,0x22
    80000486:	92e78793          	addi	a5,a5,-1746 # 80021db0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b6c60613          	addi	a2,a2,-1172 # 80008030 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	aac50513          	addi	a0,a0,-1364 # 80008008 <etext+0x8>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b4250513          	addi	a0,a0,-1214 # 800080b8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a40b8b93          	addi	s7,s7,-1472 # 80008030 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	606080e7          	jalr	1542(ra) # 80000c10 <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a0450513          	addi	a0,a0,-1532 # 80008018 <etext+0x18>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	8fc90913          	addi	s2,s2,-1796 # 80008010 <etext+0x10>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	556080e7          	jalr	1366(ra) # 80000cc4 <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	89e58593          	addi	a1,a1,-1890 # 80008028 <etext+0x28>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	3ec080e7          	jalr	1004(ra) # 80000b80 <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	86e58593          	addi	a1,a1,-1938 # 80008048 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	396080e7          	jalr	918(ra) # 80000b80 <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	3be080e7          	jalr	958(ra) # 80000bc4 <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	42c080e7          	jalr	1068(ra) # 80000c64 <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	ec8080e7          	jalr	-312(ra) # 8000277e <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	316080e7          	jalr	790(ra) # 80000c10 <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	ca8080e7          	jalr	-856(ra) # 800025f8 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	330080e7          	jalr	816(ra) # 80000cc4 <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	210080e7          	jalr	528(ra) # 80000c10 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2b2080e7          	jalr	690(ra) # 80000cc4 <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00026797          	auipc	a5,0x26
    80000a3c:	5e878793          	addi	a5,a5,1512 # 80027020 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	2bc080e7          	jalr	700(ra) # 80000d0c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1ae080e7          	jalr	430(ra) # 80000c10 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	24e080e7          	jalr	590(ra) # 80000cc4 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5c650513          	addi	a0,a0,1478 # 80008050 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	56c58593          	addi	a1,a1,1388 # 80008058 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00026517          	auipc	a0,0x26
    80000b0c:	51850513          	addi	a0,a0,1304 # 80027020 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	0dc080e7          	jalr	220(ra) # 80000c10 <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	178080e7          	jalr	376(ra) # 80000cc4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <memset>
  //int cnt = 0;
  //for(struct run *ppp = kmem.freelist;ppp;ppp=ppp->next,cnt++);
  //printf("mem leaved %d\n", cnt);

  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	14e080e7          	jalr	334(ra) # 80000cc4 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b86:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b88:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b8c:	00053823          	sd	zero,16(a0)
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	411c                	lw	a5,0(a0)
    80000b98:	e399                	bnez	a5,80000b9e <holding+0x8>
    80000b9a:	4501                	li	a0,0
  return r;
}
    80000b9c:	8082                	ret
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	6904                	ld	s1,16(a0)
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	11e080e7          	jalr	286(ra) # 80001cc8 <mycpu>
    80000bb2:	40a48533          	sub	a0,s1,a0
    80000bb6:	00153513          	seqz	a0,a0
}
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret

0000000080000bc4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc4:	1101                	addi	sp,sp,-32
    80000bc6:	ec06                	sd	ra,24(sp)
    80000bc8:	e822                	sd	s0,16(sp)
    80000bca:	e426                	sd	s1,8(sp)
    80000bcc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bce:	100024f3          	csrr	s1,sstatus
    80000bd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bdc:	00001097          	auipc	ra,0x1
    80000be0:	0ec080e7          	jalr	236(ra) # 80001cc8 <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	0e0080e7          	jalr	224(ra) # 80001cc8 <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	2785                	addiw	a5,a5,1
    80000bf4:	dd3c                	sw	a5,120(a0)
}
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
    mycpu()->intena = old;
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	0c8080e7          	jalr	200(ra) # 80001cc8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c08:	8085                	srli	s1,s1,0x1
    80000c0a:	8885                	andi	s1,s1,1
    80000c0c:	dd64                	sw	s1,124(a0)
    80000c0e:	bfe9                	j	80000be8 <push_off+0x24>

0000000080000c10 <acquire>:
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	fa8080e7          	jalr	-88(ra) # 80000bc4 <push_off>
  if(holding(lk))
    80000c24:	8526                	mv	a0,s1
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	f70080e7          	jalr	-144(ra) # 80000b96 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2e:	4705                	li	a4,1
  if(holding(lk))
    80000c30:	e115                	bnez	a0,80000c54 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c32:	87ba                	mv	a5,a4
    80000c34:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c38:	2781                	sext.w	a5,a5
    80000c3a:	ffe5                	bnez	a5,80000c32 <acquire+0x22>
  __sync_synchronize();
    80000c3c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	088080e7          	jalr	136(ra) # 80001cc8 <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    panic("acquire");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	40c50513          	addi	a0,a0,1036 # 80008060 <digits+0x30>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	8ec080e7          	jalr	-1812(ra) # 80000548 <panic>

0000000080000c64 <pop_off>:

void
pop_off(void)
{
    80000c64:	1141                	addi	sp,sp,-16
    80000c66:	e406                	sd	ra,8(sp)
    80000c68:	e022                	sd	s0,0(sp)
    80000c6a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	05c080e7          	jalr	92(ra) # 80001cc8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c78:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c7a:	e78d                	bnez	a5,80000ca4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c7c:	5d3c                	lw	a5,120(a0)
    80000c7e:	02f05b63          	blez	a5,80000cb4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c82:	37fd                	addiw	a5,a5,-1
    80000c84:	0007871b          	sext.w	a4,a5
    80000c88:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c8a:	eb09                	bnez	a4,80000c9c <pop_off+0x38>
    80000c8c:	5d7c                	lw	a5,124(a0)
    80000c8e:	c799                	beqz	a5,80000c9c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c98:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c9c:	60a2                	ld	ra,8(sp)
    80000c9e:	6402                	ld	s0,0(sp)
    80000ca0:	0141                	addi	sp,sp,16
    80000ca2:	8082                	ret
    panic("pop_off - interruptible");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3c450513          	addi	a0,a0,964 # 80008068 <digits+0x38>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
    panic("pop_off");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3cc50513          	addi	a0,a0,972 # 80008080 <digits+0x50>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	88c080e7          	jalr	-1908(ra) # 80000548 <panic>

0000000080000cc4 <release>:
{
    80000cc4:	1101                	addi	sp,sp,-32
    80000cc6:	ec06                	sd	ra,24(sp)
    80000cc8:	e822                	sd	s0,16(sp)
    80000cca:	e426                	sd	s1,8(sp)
    80000ccc:	1000                	addi	s0,sp,32
    80000cce:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	ec6080e7          	jalr	-314(ra) # 80000b96 <holding>
    80000cd8:	c115                	beqz	a0,80000cfc <release+0x38>
  lk->cpu = 0;
    80000cda:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cde:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ce2:	0f50000f          	fence	iorw,ow
    80000ce6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	f7a080e7          	jalr	-134(ra) # 80000c64 <pop_off>
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    panic("release");
    80000cfc:	00007517          	auipc	a0,0x7
    80000d00:	38c50513          	addi	a0,a0,908 # 80008088 <digits+0x58>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	844080e7          	jalr	-1980(ra) # 80000548 <panic>

0000000080000d0c <memset>:
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
    80000d12:	ce09                	beqz	a2,80000d2c <memset+0x20>
    80000d14:	87aa                	mv	a5,a0
    80000d16:	fff6071b          	addiw	a4,a2,-1
    80000d1a:	1702                	slli	a4,a4,0x20
    80000d1c:	9301                	srli	a4,a4,0x20
    80000d1e:	0705                	addi	a4,a4,1
    80000d20:	972a                	add	a4,a4,a0
    80000d22:	00b78023          	sb	a1,0(a5)
    80000d26:	0785                	addi	a5,a5,1
    80000d28:	fee79de3          	bne	a5,a4,80000d22 <memset+0x16>
    80000d2c:	6422                	ld	s0,8(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret

0000000080000d32 <memcmp>:
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
    80000d38:	ca05                	beqz	a2,80000d68 <memcmp+0x36>
    80000d3a:	fff6069b          	addiw	a3,a2,-1
    80000d3e:	1682                	slli	a3,a3,0x20
    80000d40:	9281                	srli	a3,a3,0x20
    80000d42:	0685                	addi	a3,a3,1
    80000d44:	96aa                	add	a3,a3,a0
    80000d46:	00054783          	lbu	a5,0(a0)
    80000d4a:	0005c703          	lbu	a4,0(a1)
    80000d4e:	00e79863          	bne	a5,a4,80000d5e <memcmp+0x2c>
    80000d52:	0505                	addi	a0,a0,1
    80000d54:	0585                	addi	a1,a1,1
    80000d56:	fed518e3          	bne	a0,a3,80000d46 <memcmp+0x14>
    80000d5a:	4501                	li	a0,0
    80000d5c:	a019                	j	80000d62 <memcmp+0x30>
    80000d5e:	40e7853b          	subw	a0,a5,a4
    80000d62:	6422                	ld	s0,8(sp)
    80000d64:	0141                	addi	sp,sp,16
    80000d66:	8082                	ret
    80000d68:	4501                	li	a0,0
    80000d6a:	bfe5                	j	80000d62 <memcmp+0x30>

0000000080000d6c <memmove>:
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
    80000d72:	00a5f963          	bgeu	a1,a0,80000d84 <memmove+0x18>
    80000d76:	02061713          	slli	a4,a2,0x20
    80000d7a:	9301                	srli	a4,a4,0x20
    80000d7c:	00e587b3          	add	a5,a1,a4
    80000d80:	02f56563          	bltu	a0,a5,80000daa <memmove+0x3e>
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x38>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x28>
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
    80000daa:	972a                	add	a4,a4,a0
    80000dac:	fff6069b          	addiw	a3,a2,-1
    80000db0:	da75                	beqz	a2,80000da4 <memmove+0x38>
    80000db2:	02069613          	slli	a2,a3,0x20
    80000db6:	9201                	srli	a2,a2,0x20
    80000db8:	fff64613          	not	a2,a2
    80000dbc:	963e                	add	a2,a2,a5
    80000dbe:	17fd                	addi	a5,a5,-1
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	0007c683          	lbu	a3,0(a5)
    80000dc6:	00d70023          	sb	a3,0(a4)
    80000dca:	fec79ae3          	bne	a5,a2,80000dbe <memmove+0x52>
    80000dce:	bfd9                	j	80000da4 <memmove+0x38>

0000000080000dd0 <memcpy>:
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f94080e7          	jalr	-108(ra) # 80000d6c <memmove>
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    80000e42:	00c05d63          	blez	a2,80000e5c <strncpy+0x38>
    80000e46:	86ba                	mv	a3,a4
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
    80000e4e:	fff6c793          	not	a5,a3
    80000e52:	9fb9                	addw	a5,a5,a4
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    80000e8a:	00078023          	sb	zero,0(a5)
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf91                	beqz	a5,80000eba <strlen+0x26>
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	87aa                	mv	a5,a0
    80000ea4:	4685                	li	a3,1
    80000ea6:	9e89                	subw	a3,a3,a0
    80000ea8:	00f6853b          	addw	a0,a3,a5
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff7c703          	lbu	a4,-1(a5)
    80000eb2:	fb7d                	bnez	a4,80000ea8 <strlen+0x14>
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
    80000eba:	4501                	li	a0,0
    80000ebc:	bfe5                	j	80000eb4 <strlen+0x20>

0000000080000ebe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e406                	sd	ra,8(sp)
    80000ec2:	e022                	sd	s0,0(sp)
    80000ec4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	df2080e7          	jalr	-526(ra) # 80001cb8 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ece:	00008717          	auipc	a4,0x8
    80000ed2:	13e70713          	addi	a4,a4,318 # 8000900c <started>
  if(cpuid() == 0){
    80000ed6:	c139                	beqz	a0,80000f1c <main+0x5e>
    while(started == 0)
    80000ed8:	431c                	lw	a5,0(a4)
    80000eda:	2781                	sext.w	a5,a5
    80000edc:	dff5                	beqz	a5,80000ed8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	dd6080e7          	jalr	-554(ra) # 80001cb8 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1bc50513          	addi	a0,a0,444 # 800080a8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0e0080e7          	jalr	224(ra) # 80000fdc <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	b5c080e7          	jalr	-1188(ra) # 80002a60 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	124080e7          	jalr	292(ra) # 80006030 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	3e4080e7          	jalr	996(ra) # 800022f8 <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    statsinit();
    80000f24:	00006097          	auipc	ra,0x6
    80000f28:	8ce080e7          	jalr	-1842(ra) # 800067f2 <statsinit>
    printfinit();
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	84c080e7          	jalr	-1972(ra) # 80000778 <printfinit>
    printf("\n");
    80000f34:	00007517          	auipc	a0,0x7
    80000f38:	18450513          	addi	a0,a0,388 # 800080b8 <digits+0x88>
    80000f3c:	fffff097          	auipc	ra,0xfffff
    80000f40:	656080e7          	jalr	1622(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f44:	00007517          	auipc	a0,0x7
    80000f48:	14c50513          	addi	a0,a0,332 # 80008090 <digits+0x60>
    80000f4c:	fffff097          	auipc	ra,0xfffff
    80000f50:	646080e7          	jalr	1606(ra) # 80000592 <printf>
    printf("\n");
    80000f54:	00007517          	auipc	a0,0x7
    80000f58:	16450513          	addi	a0,a0,356 # 800080b8 <digits+0x88>
    80000f5c:	fffff097          	auipc	ra,0xfffff
    80000f60:	636080e7          	jalr	1590(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	b80080e7          	jalr	-1152(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	2a6080e7          	jalr	678(ra) # 80001212 <kvminit>
    kvminithart();   // turn on paging
    80000f74:	00000097          	auipc	ra,0x0
    80000f78:	068080e7          	jalr	104(ra) # 80000fdc <kvminithart>
    procinit();      // process table
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	cd4080e7          	jalr	-812(ra) # 80001c50 <procinit>
    trapinit();      // trap vectors
    80000f84:	00002097          	auipc	ra,0x2
    80000f88:	ab4080e7          	jalr	-1356(ra) # 80002a38 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	ad4080e7          	jalr	-1324(ra) # 80002a60 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	086080e7          	jalr	134(ra) # 8000601a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	094080e7          	jalr	148(ra) # 80006030 <plicinithart>
    binit();         // buffer cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	218080e7          	jalr	536(ra) # 800031bc <binit>
    iinit();         // inode cache
    80000fac:	00003097          	auipc	ra,0x3
    80000fb0:	8a8080e7          	jalr	-1880(ra) # 80003854 <iinit>
    fileinit();      // file table
    80000fb4:	00004097          	auipc	ra,0x4
    80000fb8:	842080e7          	jalr	-1982(ra) # 800047f6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fbc:	00005097          	auipc	ra,0x5
    80000fc0:	17c080e7          	jalr	380(ra) # 80006138 <virtio_disk_init>
    userinit();      // first user process
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	0ce080e7          	jalr	206(ra) # 80002092 <userinit>
    __sync_synchronize();
    80000fcc:	0ff0000f          	fence
    started = 1;
    80000fd0:	4785                	li	a5,1
    80000fd2:	00008717          	auipc	a4,0x8
    80000fd6:	02f72d23          	sw	a5,58(a4) # 8000900c <started>
    80000fda:	bf2d                	j	80000f14 <main+0x56>

0000000080000fdc <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fdc:	1141                	addi	sp,sp,-16
    80000fde:	e422                	sd	s0,8(sp)
    80000fe0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fe2:	00008797          	auipc	a5,0x8
    80000fe6:	02e7b783          	ld	a5,46(a5) # 80009010 <kernel_pagetable>
    80000fea:	83b1                	srli	a5,a5,0xc
    80000fec:	577d                	li	a4,-1
    80000fee:	177e                	slli	a4,a4,0x3f
    80000ff0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ff2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ff6:	12000073          	sfence.vma
  sfence_vma();
}
    80000ffa:	6422                	ld	s0,8(sp)
    80000ffc:	0141                	addi	sp,sp,16
    80000ffe:	8082                	ret

0000000080001000 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001000:	7139                	addi	sp,sp,-64
    80001002:	fc06                	sd	ra,56(sp)
    80001004:	f822                	sd	s0,48(sp)
    80001006:	f426                	sd	s1,40(sp)
    80001008:	f04a                	sd	s2,32(sp)
    8000100a:	ec4e                	sd	s3,24(sp)
    8000100c:	e852                	sd	s4,16(sp)
    8000100e:	e456                	sd	s5,8(sp)
    80001010:	e05a                	sd	s6,0(sp)
    80001012:	0080                	addi	s0,sp,64
    80001014:	84aa                	mv	s1,a0
    80001016:	89ae                	mv	s3,a1
    80001018:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000101a:	57fd                	li	a5,-1
    8000101c:	83e9                	srli	a5,a5,0x1a
    8000101e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001020:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001022:	04b7f263          	bgeu	a5,a1,80001066 <walk+0x66>
    panic("walk");
    80001026:	00007517          	auipc	a0,0x7
    8000102a:	09a50513          	addi	a0,a0,154 # 800080c0 <digits+0x90>
    8000102e:	fffff097          	auipc	ra,0xfffff
    80001032:	51a080e7          	jalr	1306(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001036:	060a8663          	beqz	s5,800010a2 <walk+0xa2>
    8000103a:	00000097          	auipc	ra,0x0
    8000103e:	ae6080e7          	jalr	-1306(ra) # 80000b20 <kalloc>
    80001042:	84aa                	mv	s1,a0
    80001044:	c529                	beqz	a0,8000108e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001046:	6605                	lui	a2,0x1
    80001048:	4581                	li	a1,0
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	cc2080e7          	jalr	-830(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001052:	00c4d793          	srli	a5,s1,0xc
    80001056:	07aa                	slli	a5,a5,0xa
    80001058:	0017e793          	ori	a5,a5,1
    8000105c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001060:	3a5d                	addiw	s4,s4,-9
    80001062:	036a0063          	beq	s4,s6,80001082 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001066:	0149d933          	srl	s2,s3,s4
    8000106a:	1ff97913          	andi	s2,s2,511
    8000106e:	090e                	slli	s2,s2,0x3
    80001070:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001072:	00093483          	ld	s1,0(s2)
    80001076:	0014f793          	andi	a5,s1,1
    8000107a:	dfd5                	beqz	a5,80001036 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000107c:	80a9                	srli	s1,s1,0xa
    8000107e:	04b2                	slli	s1,s1,0xc
    80001080:	b7c5                	j	80001060 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001082:	00c9d513          	srli	a0,s3,0xc
    80001086:	1ff57513          	andi	a0,a0,511
    8000108a:	050e                	slli	a0,a0,0x3
    8000108c:	9526                	add	a0,a0,s1
}
    8000108e:	70e2                	ld	ra,56(sp)
    80001090:	7442                	ld	s0,48(sp)
    80001092:	74a2                	ld	s1,40(sp)
    80001094:	7902                	ld	s2,32(sp)
    80001096:	69e2                	ld	s3,24(sp)
    80001098:	6a42                	ld	s4,16(sp)
    8000109a:	6aa2                	ld	s5,8(sp)
    8000109c:	6b02                	ld	s6,0(sp)
    8000109e:	6121                	addi	sp,sp,64
    800010a0:	8082                	ret
        return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7ed                	j	8000108e <walk+0x8e>

00000000800010a6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010a6:	57fd                	li	a5,-1
    800010a8:	83e9                	srli	a5,a5,0x1a
    800010aa:	00b7f463          	bgeu	a5,a1,800010b2 <walkaddr+0xc>
    return 0;
    800010ae:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010b0:	8082                	ret
{
    800010b2:	1141                	addi	sp,sp,-16
    800010b4:	e406                	sd	ra,8(sp)
    800010b6:	e022                	sd	s0,0(sp)
    800010b8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ba:	4601                	li	a2,0
    800010bc:	00000097          	auipc	ra,0x0
    800010c0:	f44080e7          	jalr	-188(ra) # 80001000 <walk>
  if(pte == 0)
    800010c4:	c105                	beqz	a0,800010e4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010c6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c8:	0117f693          	andi	a3,a5,17
    800010cc:	4745                	li	a4,17
    return 0;
    800010ce:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010d0:	00e68663          	beq	a3,a4,800010dc <walkaddr+0x36>
}
    800010d4:	60a2                	ld	ra,8(sp)
    800010d6:	6402                	ld	s0,0(sp)
    800010d8:	0141                	addi	sp,sp,16
    800010da:	8082                	ret
  pa = PTE2PA(*pte);
    800010dc:	00a7d513          	srli	a0,a5,0xa
    800010e0:	0532                	slli	a0,a0,0xc
  return pa;
    800010e2:	bfcd                	j	800010d4 <walkaddr+0x2e>
    return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7fd                	j	800010d4 <walkaddr+0x2e>

00000000800010e8 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010e8:	1101                	addi	sp,sp,-32
    800010ea:	ec06                	sd	ra,24(sp)
    800010ec:	e822                	sd	s0,16(sp)
    800010ee:	e426                	sd	s1,8(sp)
    800010f0:	e04a                	sd	s2,0(sp)
    800010f2:	1000                	addi	s0,sp,32
    800010f4:	84aa                	mv	s1,a0
  uint64 off = va % PGSIZE;
    800010f6:	1552                	slli	a0,a0,0x34
    800010f8:	03455913          	srli	s2,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(myproc_pagetable(), va, 0);
    800010fc:	00002097          	auipc	ra,0x2
    80001100:	8b8080e7          	jalr	-1864(ra) # 800029b4 <myproc_pagetable>
    80001104:	4601                	li	a2,0
    80001106:	85a6                	mv	a1,s1
    80001108:	00000097          	auipc	ra,0x0
    8000110c:	ef8080e7          	jalr	-264(ra) # 80001000 <walk>
  if(pte == 0)
    80001110:	cd11                	beqz	a0,8000112c <kvmpa+0x44>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001112:	6108                	ld	a0,0(a0)
    80001114:	00157793          	andi	a5,a0,1
    80001118:	c395                	beqz	a5,8000113c <kvmpa+0x54>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000111a:	8129                	srli	a0,a0,0xa
    8000111c:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    8000111e:	954a                	add	a0,a0,s2
    80001120:	60e2                	ld	ra,24(sp)
    80001122:	6442                	ld	s0,16(sp)
    80001124:	64a2                	ld	s1,8(sp)
    80001126:	6902                	ld	s2,0(sp)
    80001128:	6105                	addi	sp,sp,32
    8000112a:	8082                	ret
    panic("kvmpa");
    8000112c:	00007517          	auipc	a0,0x7
    80001130:	f9c50513          	addi	a0,a0,-100 # 800080c8 <digits+0x98>
    80001134:	fffff097          	auipc	ra,0xfffff
    80001138:	414080e7          	jalr	1044(ra) # 80000548 <panic>
    panic("kvmpa");
    8000113c:	00007517          	auipc	a0,0x7
    80001140:	f8c50513          	addi	a0,a0,-116 # 800080c8 <digits+0x98>
    80001144:	fffff097          	auipc	ra,0xfffff
    80001148:	404080e7          	jalr	1028(ra) # 80000548 <panic>

000000008000114c <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000114c:	715d                	addi	sp,sp,-80
    8000114e:	e486                	sd	ra,72(sp)
    80001150:	e0a2                	sd	s0,64(sp)
    80001152:	fc26                	sd	s1,56(sp)
    80001154:	f84a                	sd	s2,48(sp)
    80001156:	f44e                	sd	s3,40(sp)
    80001158:	f052                	sd	s4,32(sp)
    8000115a:	ec56                	sd	s5,24(sp)
    8000115c:	e85a                	sd	s6,16(sp)
    8000115e:	e45e                	sd	s7,8(sp)
    80001160:	0880                	addi	s0,sp,80
    80001162:	8aaa                	mv	s5,a0
    80001164:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001166:	777d                	lui	a4,0xfffff
    80001168:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000116c:	167d                	addi	a2,a2,-1
    8000116e:	00b609b3          	add	s3,a2,a1
    80001172:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001176:	893e                	mv	s2,a5
    80001178:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000117c:	6b85                	lui	s7,0x1
    8000117e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001182:	4605                	li	a2,1
    80001184:	85ca                	mv	a1,s2
    80001186:	8556                	mv	a0,s5
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	e78080e7          	jalr	-392(ra) # 80001000 <walk>
    80001190:	c51d                	beqz	a0,800011be <mappages+0x72>
    if(*pte & PTE_V)
    80001192:	611c                	ld	a5,0(a0)
    80001194:	8b85                	andi	a5,a5,1
    80001196:	ef81                	bnez	a5,800011ae <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001198:	80b1                	srli	s1,s1,0xc
    8000119a:	04aa                	slli	s1,s1,0xa
    8000119c:	0164e4b3          	or	s1,s1,s6
    800011a0:	0014e493          	ori	s1,s1,1
    800011a4:	e104                	sd	s1,0(a0)
    if(a == last)
    800011a6:	03390863          	beq	s2,s3,800011d6 <mappages+0x8a>
    a += PGSIZE;
    800011aa:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011ac:	bfc9                	j	8000117e <mappages+0x32>
      panic("remap");
    800011ae:	00007517          	auipc	a0,0x7
    800011b2:	f2250513          	addi	a0,a0,-222 # 800080d0 <digits+0xa0>
    800011b6:	fffff097          	auipc	ra,0xfffff
    800011ba:	392080e7          	jalr	914(ra) # 80000548 <panic>
      return -1;
    800011be:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011c0:	60a6                	ld	ra,72(sp)
    800011c2:	6406                	ld	s0,64(sp)
    800011c4:	74e2                	ld	s1,56(sp)
    800011c6:	7942                	ld	s2,48(sp)
    800011c8:	79a2                	ld	s3,40(sp)
    800011ca:	7a02                	ld	s4,32(sp)
    800011cc:	6ae2                	ld	s5,24(sp)
    800011ce:	6b42                	ld	s6,16(sp)
    800011d0:	6ba2                	ld	s7,8(sp)
    800011d2:	6161                	addi	sp,sp,80
    800011d4:	8082                	ret
  return 0;
    800011d6:	4501                	li	a0,0
    800011d8:	b7e5                	j	800011c0 <mappages+0x74>

00000000800011da <kvmmap>:
{
    800011da:	1141                	addi	sp,sp,-16
    800011dc:	e406                	sd	ra,8(sp)
    800011de:	e022                	sd	s0,0(sp)
    800011e0:	0800                	addi	s0,sp,16
    800011e2:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011e4:	86ae                	mv	a3,a1
    800011e6:	85aa                	mv	a1,a0
    800011e8:	00008517          	auipc	a0,0x8
    800011ec:	e2853503          	ld	a0,-472(a0) # 80009010 <kernel_pagetable>
    800011f0:	00000097          	auipc	ra,0x0
    800011f4:	f5c080e7          	jalr	-164(ra) # 8000114c <mappages>
    800011f8:	e509                	bnez	a0,80001202 <kvmmap+0x28>
}
    800011fa:	60a2                	ld	ra,8(sp)
    800011fc:	6402                	ld	s0,0(sp)
    800011fe:	0141                	addi	sp,sp,16
    80001200:	8082                	ret
    panic("kvmmap");
    80001202:	00007517          	auipc	a0,0x7
    80001206:	ed650513          	addi	a0,a0,-298 # 800080d8 <digits+0xa8>
    8000120a:	fffff097          	auipc	ra,0xfffff
    8000120e:	33e080e7          	jalr	830(ra) # 80000548 <panic>

0000000080001212 <kvminit>:
{
    80001212:	1101                	addi	sp,sp,-32
    80001214:	ec06                	sd	ra,24(sp)
    80001216:	e822                	sd	s0,16(sp)
    80001218:	e426                	sd	s1,8(sp)
    8000121a:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000121c:	00000097          	auipc	ra,0x0
    80001220:	904080e7          	jalr	-1788(ra) # 80000b20 <kalloc>
    80001224:	00008797          	auipc	a5,0x8
    80001228:	dea7b623          	sd	a0,-532(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000122c:	6605                	lui	a2,0x1
    8000122e:	4581                	li	a1,0
    80001230:	00000097          	auipc	ra,0x0
    80001234:	adc080e7          	jalr	-1316(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001238:	4699                	li	a3,6
    8000123a:	6605                	lui	a2,0x1
    8000123c:	100005b7          	lui	a1,0x10000
    80001240:	10000537          	lui	a0,0x10000
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f96080e7          	jalr	-106(ra) # 800011da <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000124c:	4699                	li	a3,6
    8000124e:	6605                	lui	a2,0x1
    80001250:	100015b7          	lui	a1,0x10001
    80001254:	10001537          	lui	a0,0x10001
    80001258:	00000097          	auipc	ra,0x0
    8000125c:	f82080e7          	jalr	-126(ra) # 800011da <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001260:	4699                	li	a3,6
    80001262:	6641                	lui	a2,0x10
    80001264:	020005b7          	lui	a1,0x2000
    80001268:	02000537          	lui	a0,0x2000
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	f6e080e7          	jalr	-146(ra) # 800011da <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001274:	4699                	li	a3,6
    80001276:	00400637          	lui	a2,0x400
    8000127a:	0c0005b7          	lui	a1,0xc000
    8000127e:	0c000537          	lui	a0,0xc000
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f58080e7          	jalr	-168(ra) # 800011da <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000128a:	00007497          	auipc	s1,0x7
    8000128e:	d7648493          	addi	s1,s1,-650 # 80008000 <etext>
    80001292:	46a9                	li	a3,10
    80001294:	80007617          	auipc	a2,0x80007
    80001298:	d6c60613          	addi	a2,a2,-660 # 8000 <_entry-0x7fff8000>
    8000129c:	4585                	li	a1,1
    8000129e:	05fe                	slli	a1,a1,0x1f
    800012a0:	852e                	mv	a0,a1
    800012a2:	00000097          	auipc	ra,0x0
    800012a6:	f38080e7          	jalr	-200(ra) # 800011da <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012aa:	4699                	li	a3,6
    800012ac:	4645                	li	a2,17
    800012ae:	066e                	slli	a2,a2,0x1b
    800012b0:	8e05                	sub	a2,a2,s1
    800012b2:	85a6                	mv	a1,s1
    800012b4:	8526                	mv	a0,s1
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	f24080e7          	jalr	-220(ra) # 800011da <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012be:	46a9                	li	a3,10
    800012c0:	6605                	lui	a2,0x1
    800012c2:	00006597          	auipc	a1,0x6
    800012c6:	d3e58593          	addi	a1,a1,-706 # 80007000 <_trampoline>
    800012ca:	04000537          	lui	a0,0x4000
    800012ce:	157d                	addi	a0,a0,-1
    800012d0:	0532                	slli	a0,a0,0xc
    800012d2:	00000097          	auipc	ra,0x0
    800012d6:	f08080e7          	jalr	-248(ra) # 800011da <kvmmap>
  char *pa = kalloc(); 
    800012da:	00000097          	auipc	ra,0x0
    800012de:	846080e7          	jalr	-1978(ra) # 80000b20 <kalloc>
  if(pa == 0) {
    800012e2:	c515                	beqz	a0,8000130e <kvminit+0xfc>
    800012e4:	86aa                	mv	a3,a0
  if(mappages(kernel_pagetable, va, PGSIZE, (uint64)pa, PTE_R | PTE_W) != 0) 
    800012e6:	4719                	li	a4,6
    800012e8:	6605                	lui	a2,0x1
    800012ea:	040005b7          	lui	a1,0x4000
    800012ee:	15f5                	addi	a1,a1,-3
    800012f0:	05b2                	slli	a1,a1,0xc
    800012f2:	00008517          	auipc	a0,0x8
    800012f6:	d1e53503          	ld	a0,-738(a0) # 80009010 <kernel_pagetable>
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	e52080e7          	jalr	-430(ra) # 8000114c <mappages>
    80001302:	ed11                	bnez	a0,8000131e <kvminit+0x10c>
}
    80001304:	60e2                	ld	ra,24(sp)
    80001306:	6442                	ld	s0,16(sp)
    80001308:	64a2                	ld	s1,8(sp)
    8000130a:	6105                	addi	sp,sp,32
    8000130c:	8082                	ret
    panic("alloc kernel stack error\n");
    8000130e:	00007517          	auipc	a0,0x7
    80001312:	dd250513          	addi	a0,a0,-558 # 800080e0 <digits+0xb0>
    80001316:	fffff097          	auipc	ra,0xfffff
    8000131a:	232080e7          	jalr	562(ra) # 80000548 <panic>
    panic("allocproc mappages");
    8000131e:	00007517          	auipc	a0,0x7
    80001322:	de250513          	addi	a0,a0,-542 # 80008100 <digits+0xd0>
    80001326:	fffff097          	auipc	ra,0xfffff
    8000132a:	222080e7          	jalr	546(ra) # 80000548 <panic>

000000008000132e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000132e:	715d                	addi	sp,sp,-80
    80001330:	e486                	sd	ra,72(sp)
    80001332:	e0a2                	sd	s0,64(sp)
    80001334:	fc26                	sd	s1,56(sp)
    80001336:	f84a                	sd	s2,48(sp)
    80001338:	f44e                	sd	s3,40(sp)
    8000133a:	f052                	sd	s4,32(sp)
    8000133c:	ec56                	sd	s5,24(sp)
    8000133e:	e85a                	sd	s6,16(sp)
    80001340:	e45e                	sd	s7,8(sp)
    80001342:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001344:	03459793          	slli	a5,a1,0x34
    80001348:	e795                	bnez	a5,80001374 <uvmunmap+0x46>
    8000134a:	8a2a                	mv	s4,a0
    8000134c:	892e                	mv	s2,a1
    8000134e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001350:	0632                	slli	a2,a2,0xc
    80001352:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001356:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001358:	6b05                	lui	s6,0x1
    8000135a:	0735e863          	bltu	a1,s3,800013ca <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000135e:	60a6                	ld	ra,72(sp)
    80001360:	6406                	ld	s0,64(sp)
    80001362:	74e2                	ld	s1,56(sp)
    80001364:	7942                	ld	s2,48(sp)
    80001366:	79a2                	ld	s3,40(sp)
    80001368:	7a02                	ld	s4,32(sp)
    8000136a:	6ae2                	ld	s5,24(sp)
    8000136c:	6b42                	ld	s6,16(sp)
    8000136e:	6ba2                	ld	s7,8(sp)
    80001370:	6161                	addi	sp,sp,80
    80001372:	8082                	ret
    panic("uvmunmap: not aligned");
    80001374:	00007517          	auipc	a0,0x7
    80001378:	da450513          	addi	a0,a0,-604 # 80008118 <digits+0xe8>
    8000137c:	fffff097          	auipc	ra,0xfffff
    80001380:	1cc080e7          	jalr	460(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001384:	00007517          	auipc	a0,0x7
    80001388:	dac50513          	addi	a0,a0,-596 # 80008130 <digits+0x100>
    8000138c:	fffff097          	auipc	ra,0xfffff
    80001390:	1bc080e7          	jalr	444(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    80001394:	00007517          	auipc	a0,0x7
    80001398:	dac50513          	addi	a0,a0,-596 # 80008140 <digits+0x110>
    8000139c:	fffff097          	auipc	ra,0xfffff
    800013a0:	1ac080e7          	jalr	428(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    800013a4:	00007517          	auipc	a0,0x7
    800013a8:	db450513          	addi	a0,a0,-588 # 80008158 <digits+0x128>
    800013ac:	fffff097          	auipc	ra,0xfffff
    800013b0:	19c080e7          	jalr	412(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800013b4:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013b6:	0532                	slli	a0,a0,0xc
    800013b8:	fffff097          	auipc	ra,0xfffff
    800013bc:	66c080e7          	jalr	1644(ra) # 80000a24 <kfree>
    *pte = 0;
    800013c0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013c4:	995a                	add	s2,s2,s6
    800013c6:	f9397ce3          	bgeu	s2,s3,8000135e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013ca:	4601                	li	a2,0
    800013cc:	85ca                	mv	a1,s2
    800013ce:	8552                	mv	a0,s4
    800013d0:	00000097          	auipc	ra,0x0
    800013d4:	c30080e7          	jalr	-976(ra) # 80001000 <walk>
    800013d8:	84aa                	mv	s1,a0
    800013da:	d54d                	beqz	a0,80001384 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013dc:	6108                	ld	a0,0(a0)
    800013de:	00157793          	andi	a5,a0,1
    800013e2:	dbcd                	beqz	a5,80001394 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013e4:	3ff57793          	andi	a5,a0,1023
    800013e8:	fb778ee3          	beq	a5,s7,800013a4 <uvmunmap+0x76>
    if(do_free){
    800013ec:	fc0a8ae3          	beqz	s5,800013c0 <uvmunmap+0x92>
    800013f0:	b7d1                	j	800013b4 <uvmunmap+0x86>

00000000800013f2 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013f2:	1101                	addi	sp,sp,-32
    800013f4:	ec06                	sd	ra,24(sp)
    800013f6:	e822                	sd	s0,16(sp)
    800013f8:	e426                	sd	s1,8(sp)
    800013fa:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013fc:	fffff097          	auipc	ra,0xfffff
    80001400:	724080e7          	jalr	1828(ra) # 80000b20 <kalloc>
    80001404:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001406:	c519                	beqz	a0,80001414 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001408:	6605                	lui	a2,0x1
    8000140a:	4581                	li	a1,0
    8000140c:	00000097          	auipc	ra,0x0
    80001410:	900080e7          	jalr	-1792(ra) # 80000d0c <memset>
  return pagetable;
}
    80001414:	8526                	mv	a0,s1
    80001416:	60e2                	ld	ra,24(sp)
    80001418:	6442                	ld	s0,16(sp)
    8000141a:	64a2                	ld	s1,8(sp)
    8000141c:	6105                	addi	sp,sp,32
    8000141e:	8082                	ret

0000000080001420 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001420:	7179                	addi	sp,sp,-48
    80001422:	f406                	sd	ra,40(sp)
    80001424:	f022                	sd	s0,32(sp)
    80001426:	ec26                	sd	s1,24(sp)
    80001428:	e84a                	sd	s2,16(sp)
    8000142a:	e44e                	sd	s3,8(sp)
    8000142c:	e052                	sd	s4,0(sp)
    8000142e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001430:	6785                	lui	a5,0x1
    80001432:	04f67863          	bgeu	a2,a5,80001482 <uvminit+0x62>
    80001436:	8a2a                	mv	s4,a0
    80001438:	89ae                	mv	s3,a1
    8000143a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000143c:	fffff097          	auipc	ra,0xfffff
    80001440:	6e4080e7          	jalr	1764(ra) # 80000b20 <kalloc>
    80001444:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001446:	6605                	lui	a2,0x1
    80001448:	4581                	li	a1,0
    8000144a:	00000097          	auipc	ra,0x0
    8000144e:	8c2080e7          	jalr	-1854(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001452:	4779                	li	a4,30
    80001454:	86ca                	mv	a3,s2
    80001456:	6605                	lui	a2,0x1
    80001458:	4581                	li	a1,0
    8000145a:	8552                	mv	a0,s4
    8000145c:	00000097          	auipc	ra,0x0
    80001460:	cf0080e7          	jalr	-784(ra) # 8000114c <mappages>
  memmove(mem, src, sz);
    80001464:	8626                	mv	a2,s1
    80001466:	85ce                	mv	a1,s3
    80001468:	854a                	mv	a0,s2
    8000146a:	00000097          	auipc	ra,0x0
    8000146e:	902080e7          	jalr	-1790(ra) # 80000d6c <memmove>
}
    80001472:	70a2                	ld	ra,40(sp)
    80001474:	7402                	ld	s0,32(sp)
    80001476:	64e2                	ld	s1,24(sp)
    80001478:	6942                	ld	s2,16(sp)
    8000147a:	69a2                	ld	s3,8(sp)
    8000147c:	6a02                	ld	s4,0(sp)
    8000147e:	6145                	addi	sp,sp,48
    80001480:	8082                	ret
    panic("inituvm: more than a page");
    80001482:	00007517          	auipc	a0,0x7
    80001486:	cee50513          	addi	a0,a0,-786 # 80008170 <digits+0x140>
    8000148a:	fffff097          	auipc	ra,0xfffff
    8000148e:	0be080e7          	jalr	190(ra) # 80000548 <panic>

0000000080001492 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001492:	1101                	addi	sp,sp,-32
    80001494:	ec06                	sd	ra,24(sp)
    80001496:	e822                	sd	s0,16(sp)
    80001498:	e426                	sd	s1,8(sp)
    8000149a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000149c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000149e:	00b67d63          	bgeu	a2,a1,800014b8 <uvmdealloc+0x26>
    800014a2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014a4:	6785                	lui	a5,0x1
    800014a6:	17fd                	addi	a5,a5,-1
    800014a8:	00f60733          	add	a4,a2,a5
    800014ac:	767d                	lui	a2,0xfffff
    800014ae:	8f71                	and	a4,a4,a2
    800014b0:	97ae                	add	a5,a5,a1
    800014b2:	8ff1                	and	a5,a5,a2
    800014b4:	00f76863          	bltu	a4,a5,800014c4 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014b8:	8526                	mv	a0,s1
    800014ba:	60e2                	ld	ra,24(sp)
    800014bc:	6442                	ld	s0,16(sp)
    800014be:	64a2                	ld	s1,8(sp)
    800014c0:	6105                	addi	sp,sp,32
    800014c2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014c4:	8f99                	sub	a5,a5,a4
    800014c6:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014c8:	4685                	li	a3,1
    800014ca:	0007861b          	sext.w	a2,a5
    800014ce:	85ba                	mv	a1,a4
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	e5e080e7          	jalr	-418(ra) # 8000132e <uvmunmap>
    800014d8:	b7c5                	j	800014b8 <uvmdealloc+0x26>

00000000800014da <uvmalloc>:
  if(newsz < oldsz)
    800014da:	0ab66163          	bltu	a2,a1,8000157c <uvmalloc+0xa2>
{
    800014de:	7139                	addi	sp,sp,-64
    800014e0:	fc06                	sd	ra,56(sp)
    800014e2:	f822                	sd	s0,48(sp)
    800014e4:	f426                	sd	s1,40(sp)
    800014e6:	f04a                	sd	s2,32(sp)
    800014e8:	ec4e                	sd	s3,24(sp)
    800014ea:	e852                	sd	s4,16(sp)
    800014ec:	e456                	sd	s5,8(sp)
    800014ee:	0080                	addi	s0,sp,64
    800014f0:	8aaa                	mv	s5,a0
    800014f2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014f4:	6985                	lui	s3,0x1
    800014f6:	19fd                	addi	s3,s3,-1
    800014f8:	95ce                	add	a1,a1,s3
    800014fa:	79fd                	lui	s3,0xfffff
    800014fc:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001500:	08c9f063          	bgeu	s3,a2,80001580 <uvmalloc+0xa6>
    80001504:	894e                	mv	s2,s3
    mem = kalloc();
    80001506:	fffff097          	auipc	ra,0xfffff
    8000150a:	61a080e7          	jalr	1562(ra) # 80000b20 <kalloc>
    8000150e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001510:	c51d                	beqz	a0,8000153e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001512:	6605                	lui	a2,0x1
    80001514:	4581                	li	a1,0
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	7f6080e7          	jalr	2038(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000151e:	4779                	li	a4,30
    80001520:	86a6                	mv	a3,s1
    80001522:	6605                	lui	a2,0x1
    80001524:	85ca                	mv	a1,s2
    80001526:	8556                	mv	a0,s5
    80001528:	00000097          	auipc	ra,0x0
    8000152c:	c24080e7          	jalr	-988(ra) # 8000114c <mappages>
    80001530:	e905                	bnez	a0,80001560 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001532:	6785                	lui	a5,0x1
    80001534:	993e                	add	s2,s2,a5
    80001536:	fd4968e3          	bltu	s2,s4,80001506 <uvmalloc+0x2c>
  return newsz;
    8000153a:	8552                	mv	a0,s4
    8000153c:	a809                	j	8000154e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000153e:	864e                	mv	a2,s3
    80001540:	85ca                	mv	a1,s2
    80001542:	8556                	mv	a0,s5
    80001544:	00000097          	auipc	ra,0x0
    80001548:	f4e080e7          	jalr	-178(ra) # 80001492 <uvmdealloc>
      return 0;
    8000154c:	4501                	li	a0,0
}
    8000154e:	70e2                	ld	ra,56(sp)
    80001550:	7442                	ld	s0,48(sp)
    80001552:	74a2                	ld	s1,40(sp)
    80001554:	7902                	ld	s2,32(sp)
    80001556:	69e2                	ld	s3,24(sp)
    80001558:	6a42                	ld	s4,16(sp)
    8000155a:	6aa2                	ld	s5,8(sp)
    8000155c:	6121                	addi	sp,sp,64
    8000155e:	8082                	ret
      kfree(mem);
    80001560:	8526                	mv	a0,s1
    80001562:	fffff097          	auipc	ra,0xfffff
    80001566:	4c2080e7          	jalr	1218(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000156a:	864e                	mv	a2,s3
    8000156c:	85ca                	mv	a1,s2
    8000156e:	8556                	mv	a0,s5
    80001570:	00000097          	auipc	ra,0x0
    80001574:	f22080e7          	jalr	-222(ra) # 80001492 <uvmdealloc>
      return 0;
    80001578:	4501                	li	a0,0
    8000157a:	bfd1                	j	8000154e <uvmalloc+0x74>
    return oldsz;
    8000157c:	852e                	mv	a0,a1
}
    8000157e:	8082                	ret
  return newsz;
    80001580:	8532                	mv	a0,a2
    80001582:	b7f1                	j	8000154e <uvmalloc+0x74>

0000000080001584 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001584:	7179                	addi	sp,sp,-48
    80001586:	f406                	sd	ra,40(sp)
    80001588:	f022                	sd	s0,32(sp)
    8000158a:	ec26                	sd	s1,24(sp)
    8000158c:	e84a                	sd	s2,16(sp)
    8000158e:	e44e                	sd	s3,8(sp)
    80001590:	e052                	sd	s4,0(sp)
    80001592:	1800                	addi	s0,sp,48
    80001594:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001596:	84aa                	mv	s1,a0
    80001598:	6905                	lui	s2,0x1
    8000159a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000159c:	4985                	li	s3,1
    8000159e:	a821                	j	800015b6 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015a0:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015a2:	0532                	slli	a0,a0,0xc
    800015a4:	00000097          	auipc	ra,0x0
    800015a8:	fe0080e7          	jalr	-32(ra) # 80001584 <freewalk>
      pagetable[i] = 0;
    800015ac:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015b0:	04a1                	addi	s1,s1,8
    800015b2:	03248d63          	beq	s1,s2,800015ec <freewalk+0x68>
    pte_t pte = pagetable[i];
    800015b6:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015b8:	00f57793          	andi	a5,a0,15
    800015bc:	ff3782e3          	beq	a5,s3,800015a0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015c0:	00157793          	andi	a5,a0,1
    800015c4:	d7f5                	beqz	a5,800015b0 <freewalk+0x2c>
      printf("freewalk leaf : pa=%p\n", PTE2PA(pte));
    800015c6:	00a55593          	srli	a1,a0,0xa
    800015ca:	05b2                	slli	a1,a1,0xc
    800015cc:	00007517          	auipc	a0,0x7
    800015d0:	bc450513          	addi	a0,a0,-1084 # 80008190 <digits+0x160>
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	fbe080e7          	jalr	-66(ra) # 80000592 <printf>
      panic("freewalk: leaf");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	bcc50513          	addi	a0,a0,-1076 # 800081a8 <digits+0x178>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f64080e7          	jalr	-156(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800015ec:	8552                	mv	a0,s4
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	436080e7          	jalr	1078(ra) # 80000a24 <kfree>
}
    800015f6:	70a2                	ld	ra,40(sp)
    800015f8:	7402                	ld	s0,32(sp)
    800015fa:	64e2                	ld	s1,24(sp)
    800015fc:	6942                	ld	s2,16(sp)
    800015fe:	69a2                	ld	s3,8(sp)
    80001600:	6a02                	ld	s4,0(sp)
    80001602:	6145                	addi	sp,sp,48
    80001604:	8082                	ret

0000000080001606 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001606:	1101                	addi	sp,sp,-32
    80001608:	ec06                	sd	ra,24(sp)
    8000160a:	e822                	sd	s0,16(sp)
    8000160c:	e426                	sd	s1,8(sp)
    8000160e:	1000                	addi	s0,sp,32
    80001610:	84aa                	mv	s1,a0
  if(sz > 0)
    80001612:	e999                	bnez	a1,80001628 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001614:	8526                	mv	a0,s1
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	f6e080e7          	jalr	-146(ra) # 80001584 <freewalk>
}
    8000161e:	60e2                	ld	ra,24(sp)
    80001620:	6442                	ld	s0,16(sp)
    80001622:	64a2                	ld	s1,8(sp)
    80001624:	6105                	addi	sp,sp,32
    80001626:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001628:	6605                	lui	a2,0x1
    8000162a:	167d                	addi	a2,a2,-1
    8000162c:	962e                	add	a2,a2,a1
    8000162e:	4685                	li	a3,1
    80001630:	8231                	srli	a2,a2,0xc
    80001632:	4581                	li	a1,0
    80001634:	00000097          	auipc	ra,0x0
    80001638:	cfa080e7          	jalr	-774(ra) # 8000132e <uvmunmap>
    8000163c:	bfe1                	j	80001614 <uvmfree+0xe>

000000008000163e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000163e:	c679                	beqz	a2,8000170c <uvmcopy+0xce>
{
    80001640:	715d                	addi	sp,sp,-80
    80001642:	e486                	sd	ra,72(sp)
    80001644:	e0a2                	sd	s0,64(sp)
    80001646:	fc26                	sd	s1,56(sp)
    80001648:	f84a                	sd	s2,48(sp)
    8000164a:	f44e                	sd	s3,40(sp)
    8000164c:	f052                	sd	s4,32(sp)
    8000164e:	ec56                	sd	s5,24(sp)
    80001650:	e85a                	sd	s6,16(sp)
    80001652:	e45e                	sd	s7,8(sp)
    80001654:	0880                	addi	s0,sp,80
    80001656:	8b2a                	mv	s6,a0
    80001658:	8aae                	mv	s5,a1
    8000165a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000165c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000165e:	4601                	li	a2,0
    80001660:	85ce                	mv	a1,s3
    80001662:	855a                	mv	a0,s6
    80001664:	00000097          	auipc	ra,0x0
    80001668:	99c080e7          	jalr	-1636(ra) # 80001000 <walk>
    8000166c:	c531                	beqz	a0,800016b8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000166e:	6118                	ld	a4,0(a0)
    80001670:	00177793          	andi	a5,a4,1
    80001674:	cbb1                	beqz	a5,800016c8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001676:	00a75593          	srli	a1,a4,0xa
    8000167a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000167e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001682:	fffff097          	auipc	ra,0xfffff
    80001686:	49e080e7          	jalr	1182(ra) # 80000b20 <kalloc>
    8000168a:	892a                	mv	s2,a0
    8000168c:	c939                	beqz	a0,800016e2 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000168e:	6605                	lui	a2,0x1
    80001690:	85de                	mv	a1,s7
    80001692:	fffff097          	auipc	ra,0xfffff
    80001696:	6da080e7          	jalr	1754(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000169a:	8726                	mv	a4,s1
    8000169c:	86ca                	mv	a3,s2
    8000169e:	6605                	lui	a2,0x1
    800016a0:	85ce                	mv	a1,s3
    800016a2:	8556                	mv	a0,s5
    800016a4:	00000097          	auipc	ra,0x0
    800016a8:	aa8080e7          	jalr	-1368(ra) # 8000114c <mappages>
    800016ac:	e515                	bnez	a0,800016d8 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016ae:	6785                	lui	a5,0x1
    800016b0:	99be                	add	s3,s3,a5
    800016b2:	fb49e6e3          	bltu	s3,s4,8000165e <uvmcopy+0x20>
    800016b6:	a081                	j	800016f6 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016b8:	00007517          	auipc	a0,0x7
    800016bc:	b0050513          	addi	a0,a0,-1280 # 800081b8 <digits+0x188>
    800016c0:	fffff097          	auipc	ra,0xfffff
    800016c4:	e88080e7          	jalr	-376(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800016c8:	00007517          	auipc	a0,0x7
    800016cc:	b1050513          	addi	a0,a0,-1264 # 800081d8 <digits+0x1a8>
    800016d0:	fffff097          	auipc	ra,0xfffff
    800016d4:	e78080e7          	jalr	-392(ra) # 80000548 <panic>
      kfree(mem);
    800016d8:	854a                	mv	a0,s2
    800016da:	fffff097          	auipc	ra,0xfffff
    800016de:	34a080e7          	jalr	842(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016e2:	4685                	li	a3,1
    800016e4:	00c9d613          	srli	a2,s3,0xc
    800016e8:	4581                	li	a1,0
    800016ea:	8556                	mv	a0,s5
    800016ec:	00000097          	auipc	ra,0x0
    800016f0:	c42080e7          	jalr	-958(ra) # 8000132e <uvmunmap>
  return -1;
    800016f4:	557d                	li	a0,-1
}
    800016f6:	60a6                	ld	ra,72(sp)
    800016f8:	6406                	ld	s0,64(sp)
    800016fa:	74e2                	ld	s1,56(sp)
    800016fc:	7942                	ld	s2,48(sp)
    800016fe:	79a2                	ld	s3,40(sp)
    80001700:	7a02                	ld	s4,32(sp)
    80001702:	6ae2                	ld	s5,24(sp)
    80001704:	6b42                	ld	s6,16(sp)
    80001706:	6ba2                	ld	s7,8(sp)
    80001708:	6161                	addi	sp,sp,80
    8000170a:	8082                	ret
  return 0;
    8000170c:	4501                	li	a0,0
}
    8000170e:	8082                	ret

0000000080001710 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001710:	1141                	addi	sp,sp,-16
    80001712:	e406                	sd	ra,8(sp)
    80001714:	e022                	sd	s0,0(sp)
    80001716:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001718:	4601                	li	a2,0
    8000171a:	00000097          	auipc	ra,0x0
    8000171e:	8e6080e7          	jalr	-1818(ra) # 80001000 <walk>
  if(pte == 0)
    80001722:	c901                	beqz	a0,80001732 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001724:	611c                	ld	a5,0(a0)
    80001726:	9bbd                	andi	a5,a5,-17
    80001728:	e11c                	sd	a5,0(a0)
}
    8000172a:	60a2                	ld	ra,8(sp)
    8000172c:	6402                	ld	s0,0(sp)
    8000172e:	0141                	addi	sp,sp,16
    80001730:	8082                	ret
    panic("uvmclear");
    80001732:	00007517          	auipc	a0,0x7
    80001736:	ac650513          	addi	a0,a0,-1338 # 800081f8 <digits+0x1c8>
    8000173a:	fffff097          	auipc	ra,0xfffff
    8000173e:	e0e080e7          	jalr	-498(ra) # 80000548 <panic>

0000000080001742 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001742:	c6bd                	beqz	a3,800017b0 <copyout+0x6e>
{
    80001744:	715d                	addi	sp,sp,-80
    80001746:	e486                	sd	ra,72(sp)
    80001748:	e0a2                	sd	s0,64(sp)
    8000174a:	fc26                	sd	s1,56(sp)
    8000174c:	f84a                	sd	s2,48(sp)
    8000174e:	f44e                	sd	s3,40(sp)
    80001750:	f052                	sd	s4,32(sp)
    80001752:	ec56                	sd	s5,24(sp)
    80001754:	e85a                	sd	s6,16(sp)
    80001756:	e45e                	sd	s7,8(sp)
    80001758:	e062                	sd	s8,0(sp)
    8000175a:	0880                	addi	s0,sp,80
    8000175c:	8b2a                	mv	s6,a0
    8000175e:	8c2e                	mv	s8,a1
    80001760:	8a32                	mv	s4,a2
    80001762:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001764:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001766:	6a85                	lui	s5,0x1
    80001768:	a015                	j	8000178c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000176a:	9562                	add	a0,a0,s8
    8000176c:	0004861b          	sext.w	a2,s1
    80001770:	85d2                	mv	a1,s4
    80001772:	41250533          	sub	a0,a0,s2
    80001776:	fffff097          	auipc	ra,0xfffff
    8000177a:	5f6080e7          	jalr	1526(ra) # 80000d6c <memmove>

    len -= n;
    8000177e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001782:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001784:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001788:	02098263          	beqz	s3,800017ac <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000178c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001790:	85ca                	mv	a1,s2
    80001792:	855a                	mv	a0,s6
    80001794:	00000097          	auipc	ra,0x0
    80001798:	912080e7          	jalr	-1774(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    8000179c:	cd01                	beqz	a0,800017b4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000179e:	418904b3          	sub	s1,s2,s8
    800017a2:	94d6                	add	s1,s1,s5
    if(n > len)
    800017a4:	fc99f3e3          	bgeu	s3,s1,8000176a <copyout+0x28>
    800017a8:	84ce                	mv	s1,s3
    800017aa:	b7c1                	j	8000176a <copyout+0x28>
  }
  return 0;
    800017ac:	4501                	li	a0,0
    800017ae:	a021                	j	800017b6 <copyout+0x74>
    800017b0:	4501                	li	a0,0
}
    800017b2:	8082                	ret
      return -1;
    800017b4:	557d                	li	a0,-1
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6c02                	ld	s8,0(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret

00000000800017ce <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017ce:	c6bd                	beqz	a3,8000183c <copyin+0x6e>
{
    800017d0:	715d                	addi	sp,sp,-80
    800017d2:	e486                	sd	ra,72(sp)
    800017d4:	e0a2                	sd	s0,64(sp)
    800017d6:	fc26                	sd	s1,56(sp)
    800017d8:	f84a                	sd	s2,48(sp)
    800017da:	f44e                	sd	s3,40(sp)
    800017dc:	f052                	sd	s4,32(sp)
    800017de:	ec56                	sd	s5,24(sp)
    800017e0:	e85a                	sd	s6,16(sp)
    800017e2:	e45e                	sd	s7,8(sp)
    800017e4:	e062                	sd	s8,0(sp)
    800017e6:	0880                	addi	s0,sp,80
    800017e8:	8b2a                	mv	s6,a0
    800017ea:	8a2e                	mv	s4,a1
    800017ec:	8c32                	mv	s8,a2
    800017ee:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017f0:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017f2:	6a85                	lui	s5,0x1
    800017f4:	a015                	j	80001818 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017f6:	9562                	add	a0,a0,s8
    800017f8:	0004861b          	sext.w	a2,s1
    800017fc:	412505b3          	sub	a1,a0,s2
    80001800:	8552                	mv	a0,s4
    80001802:	fffff097          	auipc	ra,0xfffff
    80001806:	56a080e7          	jalr	1386(ra) # 80000d6c <memmove>

    len -= n;
    8000180a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000180e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001810:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001814:	02098263          	beqz	s3,80001838 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001818:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000181c:	85ca                	mv	a1,s2
    8000181e:	855a                	mv	a0,s6
    80001820:	00000097          	auipc	ra,0x0
    80001824:	886080e7          	jalr	-1914(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    80001828:	cd01                	beqz	a0,80001840 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000182a:	418904b3          	sub	s1,s2,s8
    8000182e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001830:	fc99f3e3          	bgeu	s3,s1,800017f6 <copyin+0x28>
    80001834:	84ce                	mv	s1,s3
    80001836:	b7c1                	j	800017f6 <copyin+0x28>
  }
  return 0;
    80001838:	4501                	li	a0,0
    8000183a:	a021                	j	80001842 <copyin+0x74>
    8000183c:	4501                	li	a0,0
}
    8000183e:	8082                	ret
      return -1;
    80001840:	557d                	li	a0,-1
}
    80001842:	60a6                	ld	ra,72(sp)
    80001844:	6406                	ld	s0,64(sp)
    80001846:	74e2                	ld	s1,56(sp)
    80001848:	7942                	ld	s2,48(sp)
    8000184a:	79a2                	ld	s3,40(sp)
    8000184c:	7a02                	ld	s4,32(sp)
    8000184e:	6ae2                	ld	s5,24(sp)
    80001850:	6b42                	ld	s6,16(sp)
    80001852:	6ba2                	ld	s7,8(sp)
    80001854:	6c02                	ld	s8,0(sp)
    80001856:	6161                	addi	sp,sp,80
    80001858:	8082                	ret

000000008000185a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000185a:	c6c5                	beqz	a3,80001902 <copyinstr+0xa8>
{
    8000185c:	715d                	addi	sp,sp,-80
    8000185e:	e486                	sd	ra,72(sp)
    80001860:	e0a2                	sd	s0,64(sp)
    80001862:	fc26                	sd	s1,56(sp)
    80001864:	f84a                	sd	s2,48(sp)
    80001866:	f44e                	sd	s3,40(sp)
    80001868:	f052                	sd	s4,32(sp)
    8000186a:	ec56                	sd	s5,24(sp)
    8000186c:	e85a                	sd	s6,16(sp)
    8000186e:	e45e                	sd	s7,8(sp)
    80001870:	0880                	addi	s0,sp,80
    80001872:	8a2a                	mv	s4,a0
    80001874:	8b2e                	mv	s6,a1
    80001876:	8bb2                	mv	s7,a2
    80001878:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000187a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000187c:	6985                	lui	s3,0x1
    8000187e:	a035                	j	800018aa <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001880:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001884:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001886:	0017b793          	seqz	a5,a5
    8000188a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000188e:	60a6                	ld	ra,72(sp)
    80001890:	6406                	ld	s0,64(sp)
    80001892:	74e2                	ld	s1,56(sp)
    80001894:	7942                	ld	s2,48(sp)
    80001896:	79a2                	ld	s3,40(sp)
    80001898:	7a02                	ld	s4,32(sp)
    8000189a:	6ae2                	ld	s5,24(sp)
    8000189c:	6b42                	ld	s6,16(sp)
    8000189e:	6ba2                	ld	s7,8(sp)
    800018a0:	6161                	addi	sp,sp,80
    800018a2:	8082                	ret
    srcva = va0 + PGSIZE;
    800018a4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018a8:	c8a9                	beqz	s1,800018fa <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018aa:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018ae:	85ca                	mv	a1,s2
    800018b0:	8552                	mv	a0,s4
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	7f4080e7          	jalr	2036(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    800018ba:	c131                	beqz	a0,800018fe <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018bc:	41790833          	sub	a6,s2,s7
    800018c0:	984e                	add	a6,a6,s3
    if(n > max)
    800018c2:	0104f363          	bgeu	s1,a6,800018c8 <copyinstr+0x6e>
    800018c6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018c8:	955e                	add	a0,a0,s7
    800018ca:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018ce:	fc080be3          	beqz	a6,800018a4 <copyinstr+0x4a>
    800018d2:	985a                	add	a6,a6,s6
    800018d4:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018d6:	41650633          	sub	a2,a0,s6
    800018da:	14fd                	addi	s1,s1,-1
    800018dc:	9b26                	add	s6,s6,s1
    800018de:	00f60733          	add	a4,a2,a5
    800018e2:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    800018e6:	df49                	beqz	a4,80001880 <copyinstr+0x26>
        *dst = *p;
    800018e8:	00e78023          	sb	a4,0(a5)
      --max;
    800018ec:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018f0:	0785                	addi	a5,a5,1
    while(n > 0){
    800018f2:	ff0796e3          	bne	a5,a6,800018de <copyinstr+0x84>
      dst++;
    800018f6:	8b42                	mv	s6,a6
    800018f8:	b775                	j	800018a4 <copyinstr+0x4a>
    800018fa:	4781                	li	a5,0
    800018fc:	b769                	j	80001886 <copyinstr+0x2c>
      return -1;
    800018fe:	557d                	li	a0,-1
    80001900:	b779                	j	8000188e <copyinstr+0x34>
  int got_null = 0;
    80001902:	4781                	li	a5,0
  if(got_null){
    80001904:	0017b793          	seqz	a5,a5
    80001908:	40f00533          	neg	a0,a5
}
    8000190c:	8082                	ret

000000008000190e <vmprint>:

// ysw
void
vmprint(pagetable_t pagetable) 
{
    8000190e:	7159                	addi	sp,sp,-112
    80001910:	f486                	sd	ra,104(sp)
    80001912:	f0a2                	sd	s0,96(sp)
    80001914:	eca6                	sd	s1,88(sp)
    80001916:	e8ca                	sd	s2,80(sp)
    80001918:	e4ce                	sd	s3,72(sp)
    8000191a:	e0d2                	sd	s4,64(sp)
    8000191c:	fc56                	sd	s5,56(sp)
    8000191e:	f85a                	sd	s6,48(sp)
    80001920:	f45e                	sd	s7,40(sp)
    80001922:	f062                	sd	s8,32(sp)
    80001924:	ec66                	sd	s9,24(sp)
    80001926:	e86a                	sd	s10,16(sp)
    80001928:	e46e                	sd	s11,8(sp)
    8000192a:	1880                	addi	s0,sp,112
    8000192c:	8baa                	mv	s7,a0
  printf("page table %p\n", pagetable);
    8000192e:	85aa                	mv	a1,a0
    80001930:	00007517          	auipc	a0,0x7
    80001934:	8d850513          	addi	a0,a0,-1832 # 80008208 <digits+0x1d8>
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	c5a080e7          	jalr	-934(ra) # 80000592 <printf>
  for(int i = 0;i < 512;i++) {
    80001940:	4c01                	li	s8,0
    uint64 PTE2 = pagetable[i];
    if(PTE2 & PTE_V) {
      pagetable_t PTE2pa = (pagetable_t)PTE2PA(PTE2);
      printf("..%d: pte %p pa %p\n", i, PTE2, PTE2pa);
    80001942:	00007d97          	auipc	s11,0x7
    80001946:	8d6d8d93          	addi	s11,s11,-1834 # 80008218 <digits+0x1e8>
      for(int j = 0;j < 512;j++) {
        uint64 PTE1 = PTE2pa[j];
        if(PTE1 & PTE_V) {
          pagetable_t PTE1pa = (pagetable_t)PTE2PA(PTE1);
          printf(".. ..%d: pte %p pa %p\n", j, PTE1, PTE1pa);
    8000194a:	00007d17          	auipc	s10,0x7
    8000194e:	8e6d0d13          	addi	s10,s10,-1818 # 80008230 <digits+0x200>
          for(int k = 0;k < 512;k++) {
    80001952:	20000993          	li	s3,512
    80001956:	4c81                	li	s9,0
            uint64 PTE0 = PTE1pa[k];
            if(PTE0 & PTE_V) {
              pagetable_t PTE0pa = (pagetable_t)PTE2PA(PTE0);
              printf(".. .. ..%d: pte %p pa %p\n", k, PTE0, PTE0pa);
    80001958:	00007a17          	auipc	s4,0x7
    8000195c:	8f0a0a13          	addi	s4,s4,-1808 # 80008248 <digits+0x218>
    80001960:	a8a9                	j	800019ba <vmprint+0xac>
              pagetable_t PTE0pa = (pagetable_t)PTE2PA(PTE0);
    80001962:	00a65693          	srli	a3,a2,0xa
              printf(".. .. ..%d: pte %p pa %p\n", k, PTE0, PTE0pa);
    80001966:	06b2                	slli	a3,a3,0xc
    80001968:	85a6                	mv	a1,s1
    8000196a:	8552                	mv	a0,s4
    8000196c:	fffff097          	auipc	ra,0xfffff
    80001970:	c26080e7          	jalr	-986(ra) # 80000592 <printf>
          for(int k = 0;k < 512;k++) {
    80001974:	2485                	addiw	s1,s1,1
    80001976:	0921                	addi	s2,s2,8
    80001978:	01348863          	beq	s1,s3,80001988 <vmprint+0x7a>
            uint64 PTE0 = PTE1pa[k];
    8000197c:	00093603          	ld	a2,0(s2) # 1000 <_entry-0x7ffff000>
            if(PTE0 & PTE_V) {
    80001980:	00167793          	andi	a5,a2,1
    80001984:	dbe5                	beqz	a5,80001974 <vmprint+0x66>
    80001986:	bff1                	j	80001962 <vmprint+0x54>
      for(int j = 0;j < 512;j++) {
    80001988:	2a85                	addiw	s5,s5,1
    8000198a:	0b21                	addi	s6,s6,8
    8000198c:	033a8363          	beq	s5,s3,800019b2 <vmprint+0xa4>
        uint64 PTE1 = PTE2pa[j];
    80001990:	000b3603          	ld	a2,0(s6) # 1000 <_entry-0x7ffff000>
        if(PTE1 & PTE_V) {
    80001994:	00167793          	andi	a5,a2,1
    80001998:	dbe5                	beqz	a5,80001988 <vmprint+0x7a>
          pagetable_t PTE1pa = (pagetable_t)PTE2PA(PTE1);
    8000199a:	00a65913          	srli	s2,a2,0xa
    8000199e:	0932                	slli	s2,s2,0xc
          printf(".. ..%d: pte %p pa %p\n", j, PTE1, PTE1pa);
    800019a0:	86ca                	mv	a3,s2
    800019a2:	85d6                	mv	a1,s5
    800019a4:	856a                	mv	a0,s10
    800019a6:	fffff097          	auipc	ra,0xfffff
    800019aa:	bec080e7          	jalr	-1044(ra) # 80000592 <printf>
          for(int k = 0;k < 512;k++) {
    800019ae:	84e6                	mv	s1,s9
    800019b0:	b7f1                	j	8000197c <vmprint+0x6e>
  for(int i = 0;i < 512;i++) {
    800019b2:	2c05                	addiw	s8,s8,1
    800019b4:	0ba1                	addi	s7,s7,8
    800019b6:	033c0363          	beq	s8,s3,800019dc <vmprint+0xce>
    uint64 PTE2 = pagetable[i];
    800019ba:	000bb603          	ld	a2,0(s7) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    if(PTE2 & PTE_V) {
    800019be:	00167793          	andi	a5,a2,1
    800019c2:	dbe5                	beqz	a5,800019b2 <vmprint+0xa4>
      pagetable_t PTE2pa = (pagetable_t)PTE2PA(PTE2);
    800019c4:	00a65b13          	srli	s6,a2,0xa
    800019c8:	0b32                	slli	s6,s6,0xc
      printf("..%d: pte %p pa %p\n", i, PTE2, PTE2pa);
    800019ca:	86da                	mv	a3,s6
    800019cc:	85e2                	mv	a1,s8
    800019ce:	856e                	mv	a0,s11
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	bc2080e7          	jalr	-1086(ra) # 80000592 <printf>
      for(int j = 0;j < 512;j++) {
    800019d8:	4a81                	li	s5,0
    800019da:	bf5d                	j	80001990 <vmprint+0x82>
          }
        }
      }
    }
  }
}
    800019dc:	70a6                	ld	ra,104(sp)
    800019de:	7406                	ld	s0,96(sp)
    800019e0:	64e6                	ld	s1,88(sp)
    800019e2:	6946                	ld	s2,80(sp)
    800019e4:	69a6                	ld	s3,72(sp)
    800019e6:	6a06                	ld	s4,64(sp)
    800019e8:	7ae2                	ld	s5,56(sp)
    800019ea:	7b42                	ld	s6,48(sp)
    800019ec:	7ba2                	ld	s7,40(sp)
    800019ee:	7c02                	ld	s8,32(sp)
    800019f0:	6ce2                	ld	s9,24(sp)
    800019f2:	6d42                	ld	s10,16(sp)
    800019f4:	6da2                	ld	s11,8(sp)
    800019f6:	6165                	addi	sp,sp,112
    800019f8:	8082                	ret

00000000800019fa <new_kernel_pagetable>:

// ysw
pagetable_t 
new_kernel_pagetable() 
{
    800019fa:	7179                	addi	sp,sp,-48
    800019fc:	f406                	sd	ra,40(sp)
    800019fe:	f022                	sd	s0,32(sp)
    80001a00:	ec26                	sd	s1,24(sp)
    80001a02:	e84a                	sd	s2,16(sp)
    80001a04:	e44e                	sd	s3,8(sp)
    80001a06:	1800                	addi	s0,sp,48
  pagetable_t temp_kernel_pagetable = (pagetable_t) kalloc();
    80001a08:	fffff097          	auipc	ra,0xfffff
    80001a0c:	118080e7          	jalr	280(ra) # 80000b20 <kalloc>
    80001a10:	892a                	mv	s2,a0
  if(temp_kernel_pagetable == 0)
    80001a12:	cd71                	beqz	a0,80001aee <new_kernel_pagetable+0xf4>
    return 0;

  memset(temp_kernel_pagetable, 0, PGSIZE);
    80001a14:	6605                	lui	a2,0x1
    80001a16:	4581                	li	a1,0
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	2f4080e7          	jalr	756(ra) # 80000d0c <memset>

  int res = 0;

  // uart registers
  res |= mappages(temp_kernel_pagetable, UART0, PGSIZE, UART0, PTE_R | PTE_W);
    80001a20:	4719                	li	a4,6
    80001a22:	100006b7          	lui	a3,0x10000
    80001a26:	6605                	lui	a2,0x1
    80001a28:	100005b7          	lui	a1,0x10000
    80001a2c:	854a                	mv	a0,s2
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	71e080e7          	jalr	1822(ra) # 8000114c <mappages>
    80001a36:	84aa                	mv	s1,a0

  // virtio mmio disk interface
  res |= mappages(temp_kernel_pagetable, VIRTIO0, PGSIZE, VIRTIO0, PTE_R | PTE_W);
    80001a38:	4719                	li	a4,6
    80001a3a:	100016b7          	lui	a3,0x10001
    80001a3e:	6605                	lui	a2,0x1
    80001a40:	100015b7          	lui	a1,0x10001
    80001a44:	854a                	mv	a0,s2
    80001a46:	fffff097          	auipc	ra,0xfffff
    80001a4a:	706080e7          	jalr	1798(ra) # 8000114c <mappages>
    80001a4e:	8cc9                	or	s1,s1,a0
    80001a50:	2481                	sext.w	s1,s1

  // CLINT
  res |= mappages(temp_kernel_pagetable, CLINT, 0x10000, CLINT, PTE_R | PTE_W);
    80001a52:	4719                	li	a4,6
    80001a54:	020006b7          	lui	a3,0x2000
    80001a58:	6641                	lui	a2,0x10
    80001a5a:	020005b7          	lui	a1,0x2000
    80001a5e:	854a                	mv	a0,s2
    80001a60:	fffff097          	auipc	ra,0xfffff
    80001a64:	6ec080e7          	jalr	1772(ra) # 8000114c <mappages>
    80001a68:	8cc9                	or	s1,s1,a0
    80001a6a:	2481                	sext.w	s1,s1

  // PLIC
  res |= mappages(temp_kernel_pagetable, PLIC, 0x400000, PLIC, PTE_R | PTE_W);
    80001a6c:	4719                	li	a4,6
    80001a6e:	0c0006b7          	lui	a3,0xc000
    80001a72:	00400637          	lui	a2,0x400
    80001a76:	0c0005b7          	lui	a1,0xc000
    80001a7a:	854a                	mv	a0,s2
    80001a7c:	fffff097          	auipc	ra,0xfffff
    80001a80:	6d0080e7          	jalr	1744(ra) # 8000114c <mappages>
    80001a84:	8cc9                	or	s1,s1,a0
    80001a86:	2481                	sext.w	s1,s1

  // map kernel text executable and read-only.
  res |= mappages(temp_kernel_pagetable, KERNBASE, (uint64)etext-KERNBASE, KERNBASE, PTE_R | PTE_X);
    80001a88:	00006997          	auipc	s3,0x6
    80001a8c:	57898993          	addi	s3,s3,1400 # 80008000 <etext>
    80001a90:	4729                	li	a4,10
    80001a92:	4685                	li	a3,1
    80001a94:	06fe                	slli	a3,a3,0x1f
    80001a96:	80006617          	auipc	a2,0x80006
    80001a9a:	56a60613          	addi	a2,a2,1386 # 8000 <_entry-0x7fff8000>
    80001a9e:	85b6                	mv	a1,a3
    80001aa0:	854a                	mv	a0,s2
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	6aa080e7          	jalr	1706(ra) # 8000114c <mappages>
    80001aaa:	8cc9                	or	s1,s1,a0
    80001aac:	2481                	sext.w	s1,s1

  // map kernel data and the physical RAM we'll make use of.
  res |= mappages(temp_kernel_pagetable, (uint64)etext, PHYSTOP-(uint64)etext, (uint64)etext, PTE_R | PTE_W);
    80001aae:	4719                	li	a4,6
    80001ab0:	86ce                	mv	a3,s3
    80001ab2:	4645                	li	a2,17
    80001ab4:	066e                	slli	a2,a2,0x1b
    80001ab6:	41360633          	sub	a2,a2,s3
    80001aba:	85ce                	mv	a1,s3
    80001abc:	854a                	mv	a0,s2
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	68e080e7          	jalr	1678(ra) # 8000114c <mappages>
    80001ac6:	8cc9                	or	s1,s1,a0
    80001ac8:	2481                	sext.w	s1,s1

  // map the trampoline for trap entry/exit to
  // the highest virtual address in the kernel.
  res |= mappages(temp_kernel_pagetable, TRAMPOLINE, PGSIZE, (uint64)trampoline, PTE_R | PTE_X);
    80001aca:	4729                	li	a4,10
    80001acc:	00005697          	auipc	a3,0x5
    80001ad0:	53468693          	addi	a3,a3,1332 # 80007000 <_trampoline>
    80001ad4:	6605                	lui	a2,0x1
    80001ad6:	040005b7          	lui	a1,0x4000
    80001ada:	15fd                	addi	a1,a1,-1
    80001adc:	05b2                	slli	a1,a1,0xc
    80001ade:	854a                	mv	a0,s2
    80001ae0:	fffff097          	auipc	ra,0xfffff
    80001ae4:	66c080e7          	jalr	1644(ra) # 8000114c <mappages>
    80001ae8:	8cc9                	or	s1,s1,a0

  if(res != 0) {
    80001aea:	2481                	sext.w	s1,s1
    80001aec:	e889                	bnez	s1,80001afe <new_kernel_pagetable+0x104>
    printf("new_kernel_pagetable error!\n");
  }
  return temp_kernel_pagetable;
}
    80001aee:	854a                	mv	a0,s2
    80001af0:	70a2                	ld	ra,40(sp)
    80001af2:	7402                	ld	s0,32(sp)
    80001af4:	64e2                	ld	s1,24(sp)
    80001af6:	6942                	ld	s2,16(sp)
    80001af8:	69a2                	ld	s3,8(sp)
    80001afa:	6145                	addi	sp,sp,48
    80001afc:	8082                	ret
    printf("new_kernel_pagetable error!\n");
    80001afe:	00006517          	auipc	a0,0x6
    80001b02:	76a50513          	addi	a0,a0,1898 # 80008268 <digits+0x238>
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	a8c080e7          	jalr	-1396(ra) # 80000592 <printf>
    80001b0e:	b7c5                	j	80001aee <new_kernel_pagetable+0xf4>

0000000080001b10 <TONPAGES>:

// ysw
uint64 TONPAGES(uint64 va, uint64 sz) {
    80001b10:	1141                	addi	sp,sp,-16
    80001b12:	e422                	sd	s0,8(sp)
    80001b14:	0800                	addi	s0,sp,16
  uint64 a = PGROUNDDOWN(va);
    80001b16:	777d                	lui	a4,0xfffff
    80001b18:	00e577b3          	and	a5,a0,a4
  //printf("a %p\n", a);
  uint64 b = PGROUNDDOWN(a+sz-1);
    80001b1c:	15fd                	addi	a1,a1,-1
    80001b1e:	00f58533          	add	a0,a1,a5
    80001b22:	8d79                	and	a0,a0,a4
  //printf("b %p\n", b);
  //printf("val %p\n", b-a);
  return (b-a)/PGSIZE + 1;
    80001b24:	8d1d                	sub	a0,a0,a5
    80001b26:	8131                	srli	a0,a0,0xc
} 
    80001b28:	0505                	addi	a0,a0,1
    80001b2a:	6422                	ld	s0,8(sp)
    80001b2c:	0141                	addi	sp,sp,16
    80001b2e:	8082                	ret

0000000080001b30 <kvmfree>:
// ysw
void 
kvmfree(pagetable_t kernel_pagetable) 
{
    80001b30:	7179                	addi	sp,sp,-48
    80001b32:	f406                	sd	ra,40(sp)
    80001b34:	f022                	sd	s0,32(sp)
    80001b36:	ec26                	sd	s1,24(sp)
    80001b38:	e84a                	sd	s2,16(sp)
    80001b3a:	e44e                	sd	s3,8(sp)
    80001b3c:	1800                	addi	s0,sp,48
    80001b3e:	892a                	mv	s2,a0
  uvmunmap(kernel_pagetable, PGROUNDDOWN(UART0), TONPAGES(UART0,PGSIZE), 0);
    80001b40:	4681                	li	a3,0
    80001b42:	4605                	li	a2,1
    80001b44:	100005b7          	lui	a1,0x10000
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	7e6080e7          	jalr	2022(ra) # 8000132e <uvmunmap>
  uvmunmap(kernel_pagetable, PGROUNDDOWN(VIRTIO0), TONPAGES(VIRTIO0,PGSIZE), 0);
    80001b50:	4681                	li	a3,0
    80001b52:	4605                	li	a2,1
    80001b54:	100015b7          	lui	a1,0x10001
    80001b58:	854a                	mv	a0,s2
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	7d4080e7          	jalr	2004(ra) # 8000132e <uvmunmap>
  uvmunmap(kernel_pagetable, PGROUNDDOWN(CLINT), TONPAGES(CLINT,0x10000), 0);
    80001b62:	4681                	li	a3,0
    80001b64:	4641                	li	a2,16
    80001b66:	020005b7          	lui	a1,0x2000
    80001b6a:	854a                	mv	a0,s2
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	7c2080e7          	jalr	1986(ra) # 8000132e <uvmunmap>
  uvmunmap(kernel_pagetable, PGROUNDDOWN(PLIC), TONPAGES(PLIC,0x400000), 0);
    80001b74:	4681                	li	a3,0
    80001b76:	40000613          	li	a2,1024
    80001b7a:	0c0005b7          	lui	a1,0xc000
    80001b7e:	854a                	mv	a0,s2
    80001b80:	fffff097          	auipc	ra,0xfffff
    80001b84:	7ae080e7          	jalr	1966(ra) # 8000132e <uvmunmap>
  uvmunmap(kernel_pagetable, PGROUNDDOWN(KERNBASE), TONPAGES(KERNBASE,(uint64)etext-KERNBASE), 0);
    80001b88:	00006497          	auipc	s1,0x6
    80001b8c:	47848493          	addi	s1,s1,1144 # 80008000 <etext>
  uint64 b = PGROUNDDOWN(a+sz-1);
    80001b90:	79fd                	lui	s3,0xfffff
    80001b92:	00006617          	auipc	a2,0x6
    80001b96:	46d60613          	addi	a2,a2,1133 # 80007fff <userret+0xf6f>
    80001b9a:	01367633          	and	a2,a2,s3
  return (b-a)/PGSIZE + 1;
    80001b9e:	800007b7          	lui	a5,0x80000
    80001ba2:	963e                	add	a2,a2,a5
    80001ba4:	8231                	srli	a2,a2,0xc
  uvmunmap(kernel_pagetable, PGROUNDDOWN(KERNBASE), TONPAGES(KERNBASE,(uint64)etext-KERNBASE), 0);
    80001ba6:	4681                	li	a3,0
    80001ba8:	0605                	addi	a2,a2,1
    80001baa:	4585                	li	a1,1
    80001bac:	05fe                	slli	a1,a1,0x1f
    80001bae:	854a                	mv	a0,s2
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	77e080e7          	jalr	1918(ra) # 8000132e <uvmunmap>
  uvmunmap(kernel_pagetable, PGROUNDDOWN((uint64)etext), TONPAGES((uint64)etext,PHYSTOP-(uint64)etext), 0);
    80001bb8:	0134f5b3          	and	a1,s1,s3
  uint64 b = PGROUNDDOWN(a+sz-1);
    80001bbc:	40958633          	sub	a2,a1,s1
    80001bc0:	44c5                	li	s1,17
    80001bc2:	04ee                	slli	s1,s1,0x1b
    80001bc4:	14fd                	addi	s1,s1,-1
    80001bc6:	9626                	add	a2,a2,s1
    80001bc8:	01367633          	and	a2,a2,s3
  return (b-a)/PGSIZE + 1;
    80001bcc:	8e0d                	sub	a2,a2,a1
    80001bce:	8231                	srli	a2,a2,0xc
  uvmunmap(kernel_pagetable, PGROUNDDOWN((uint64)etext), TONPAGES((uint64)etext,PHYSTOP-(uint64)etext), 0);
    80001bd0:	4681                	li	a3,0
    80001bd2:	0605                	addi	a2,a2,1
    80001bd4:	854a                	mv	a0,s2
    80001bd6:	fffff097          	auipc	ra,0xfffff
    80001bda:	758080e7          	jalr	1880(ra) # 8000132e <uvmunmap>
  uvmunmap(kernel_pagetable, PGROUNDDOWN(TRAMPOLINE), TONPAGES(TRAMPOLINE,PGSIZE), 0);
    80001bde:	4681                	li	a3,0
    80001be0:	4605                	li	a2,1
    80001be2:	040005b7          	lui	a1,0x4000
    80001be6:	15fd                	addi	a1,a1,-1
    80001be8:	05b2                	slli	a1,a1,0xc
    80001bea:	854a                	mv	a0,s2
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	742080e7          	jalr	1858(ra) # 8000132e <uvmunmap>
  freewalk(kernel_pagetable);
    80001bf4:	854a                	mv	a0,s2
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	98e080e7          	jalr	-1650(ra) # 80001584 <freewalk>
    80001bfe:	70a2                	ld	ra,40(sp)
    80001c00:	7402                	ld	s0,32(sp)
    80001c02:	64e2                	ld	s1,24(sp)
    80001c04:	6942                	ld	s2,16(sp)
    80001c06:	69a2                	ld	s3,8(sp)
    80001c08:	6145                	addi	sp,sp,48
    80001c0a:	8082                	ret

0000000080001c0c <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001c0c:	1101                	addi	sp,sp,-32
    80001c0e:	ec06                	sd	ra,24(sp)
    80001c10:	e822                	sd	s0,16(sp)
    80001c12:	e426                	sd	s1,8(sp)
    80001c14:	1000                	addi	s0,sp,32
    80001c16:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	f7e080e7          	jalr	-130(ra) # 80000b96 <holding>
    80001c20:	c909                	beqz	a0,80001c32 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001c22:	749c                	ld	a5,40(s1)
    80001c24:	00978f63          	beq	a5,s1,80001c42 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001c28:	60e2                	ld	ra,24(sp)
    80001c2a:	6442                	ld	s0,16(sp)
    80001c2c:	64a2                	ld	s1,8(sp)
    80001c2e:	6105                	addi	sp,sp,32
    80001c30:	8082                	ret
    panic("wakeup1");
    80001c32:	00006517          	auipc	a0,0x6
    80001c36:	65650513          	addi	a0,a0,1622 # 80008288 <digits+0x258>
    80001c3a:	fffff097          	auipc	ra,0xfffff
    80001c3e:	90e080e7          	jalr	-1778(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001c42:	4c98                	lw	a4,24(s1)
    80001c44:	4785                	li	a5,1
    80001c46:	fef711e3          	bne	a4,a5,80001c28 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001c4a:	4789                	li	a5,2
    80001c4c:	cc9c                	sw	a5,24(s1)
}
    80001c4e:	bfe9                	j	80001c28 <wakeup1+0x1c>

0000000080001c50 <procinit>:
{
    80001c50:	7179                	addi	sp,sp,-48
    80001c52:	f406                	sd	ra,40(sp)
    80001c54:	f022                	sd	s0,32(sp)
    80001c56:	ec26                	sd	s1,24(sp)
    80001c58:	e84a                	sd	s2,16(sp)
    80001c5a:	e44e                	sd	s3,8(sp)
    80001c5c:	1800                	addi	s0,sp,48
  initlock(&pid_lock, "nextpid");
    80001c5e:	00006597          	auipc	a1,0x6
    80001c62:	63258593          	addi	a1,a1,1586 # 80008290 <digits+0x260>
    80001c66:	00010517          	auipc	a0,0x10
    80001c6a:	cea50513          	addi	a0,a0,-790 # 80011950 <pid_lock>
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	f12080e7          	jalr	-238(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c76:	00010497          	auipc	s1,0x10
    80001c7a:	0f248493          	addi	s1,s1,242 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001c7e:	00006997          	auipc	s3,0x6
    80001c82:	61a98993          	addi	s3,s3,1562 # 80008298 <digits+0x268>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c86:	00016917          	auipc	s2,0x16
    80001c8a:	ee290913          	addi	s2,s2,-286 # 80017b68 <tickslock>
      initlock(&p->lock, "proc");
    80001c8e:	85ce                	mv	a1,s3
    80001c90:	8526                	mv	a0,s1
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	eee080e7          	jalr	-274(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c9a:	17848493          	addi	s1,s1,376
    80001c9e:	ff2498e3          	bne	s1,s2,80001c8e <procinit+0x3e>
  kvminithart();
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	33a080e7          	jalr	826(ra) # 80000fdc <kvminithart>
}
    80001caa:	70a2                	ld	ra,40(sp)
    80001cac:	7402                	ld	s0,32(sp)
    80001cae:	64e2                	ld	s1,24(sp)
    80001cb0:	6942                	ld	s2,16(sp)
    80001cb2:	69a2                	ld	s3,8(sp)
    80001cb4:	6145                	addi	sp,sp,48
    80001cb6:	8082                	ret

0000000080001cb8 <cpuid>:
{
    80001cb8:	1141                	addi	sp,sp,-16
    80001cba:	e422                	sd	s0,8(sp)
    80001cbc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001cbe:	8512                	mv	a0,tp
}
    80001cc0:	2501                	sext.w	a0,a0
    80001cc2:	6422                	ld	s0,8(sp)
    80001cc4:	0141                	addi	sp,sp,16
    80001cc6:	8082                	ret

0000000080001cc8 <mycpu>:
mycpu(void) {
    80001cc8:	1141                	addi	sp,sp,-16
    80001cca:	e422                	sd	s0,8(sp)
    80001ccc:	0800                	addi	s0,sp,16
    80001cce:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001cd0:	2781                	sext.w	a5,a5
    80001cd2:	079e                	slli	a5,a5,0x7
}
    80001cd4:	00010517          	auipc	a0,0x10
    80001cd8:	c9450513          	addi	a0,a0,-876 # 80011968 <cpus>
    80001cdc:	953e                	add	a0,a0,a5
    80001cde:	6422                	ld	s0,8(sp)
    80001ce0:	0141                	addi	sp,sp,16
    80001ce2:	8082                	ret

0000000080001ce4 <myproc>:
myproc(void) {
    80001ce4:	1101                	addi	sp,sp,-32
    80001ce6:	ec06                	sd	ra,24(sp)
    80001ce8:	e822                	sd	s0,16(sp)
    80001cea:	e426                	sd	s1,8(sp)
    80001cec:	1000                	addi	s0,sp,32
  push_off();
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	ed6080e7          	jalr	-298(ra) # 80000bc4 <push_off>
    80001cf6:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001cf8:	2781                	sext.w	a5,a5
    80001cfa:	079e                	slli	a5,a5,0x7
    80001cfc:	00010717          	auipc	a4,0x10
    80001d00:	c5470713          	addi	a4,a4,-940 # 80011950 <pid_lock>
    80001d04:	97ba                	add	a5,a5,a4
    80001d06:	6f84                	ld	s1,24(a5)
  pop_off();
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	f5c080e7          	jalr	-164(ra) # 80000c64 <pop_off>
}
    80001d10:	8526                	mv	a0,s1
    80001d12:	60e2                	ld	ra,24(sp)
    80001d14:	6442                	ld	s0,16(sp)
    80001d16:	64a2                	ld	s1,8(sp)
    80001d18:	6105                	addi	sp,sp,32
    80001d1a:	8082                	ret

0000000080001d1c <forkret>:
{
    80001d1c:	1141                	addi	sp,sp,-16
    80001d1e:	e406                	sd	ra,8(sp)
    80001d20:	e022                	sd	s0,0(sp)
    80001d22:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001d24:	00000097          	auipc	ra,0x0
    80001d28:	fc0080e7          	jalr	-64(ra) # 80001ce4 <myproc>
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	f98080e7          	jalr	-104(ra) # 80000cc4 <release>
  if (first) {
    80001d34:	00007797          	auipc	a5,0x7
    80001d38:	c0c7a783          	lw	a5,-1012(a5) # 80008940 <first.1686>
    80001d3c:	eb89                	bnez	a5,80001d4e <forkret+0x32>
  usertrapret();
    80001d3e:	00001097          	auipc	ra,0x1
    80001d42:	d3a080e7          	jalr	-710(ra) # 80002a78 <usertrapret>
}
    80001d46:	60a2                	ld	ra,8(sp)
    80001d48:	6402                	ld	s0,0(sp)
    80001d4a:	0141                	addi	sp,sp,16
    80001d4c:	8082                	ret
    first = 0;
    80001d4e:	00007797          	auipc	a5,0x7
    80001d52:	be07a923          	sw	zero,-1038(a5) # 80008940 <first.1686>
    fsinit(ROOTDEV);
    80001d56:	4505                	li	a0,1
    80001d58:	00002097          	auipc	ra,0x2
    80001d5c:	a7c080e7          	jalr	-1412(ra) # 800037d4 <fsinit>
    80001d60:	bff9                	j	80001d3e <forkret+0x22>

0000000080001d62 <allocpid>:
allocpid() {
    80001d62:	1101                	addi	sp,sp,-32
    80001d64:	ec06                	sd	ra,24(sp)
    80001d66:	e822                	sd	s0,16(sp)
    80001d68:	e426                	sd	s1,8(sp)
    80001d6a:	e04a                	sd	s2,0(sp)
    80001d6c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001d6e:	00010917          	auipc	s2,0x10
    80001d72:	be290913          	addi	s2,s2,-1054 # 80011950 <pid_lock>
    80001d76:	854a                	mv	a0,s2
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	e98080e7          	jalr	-360(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001d80:	00007797          	auipc	a5,0x7
    80001d84:	bc478793          	addi	a5,a5,-1084 # 80008944 <nextpid>
    80001d88:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001d8a:	0014871b          	addiw	a4,s1,1
    80001d8e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001d90:	854a                	mv	a0,s2
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	f32080e7          	jalr	-206(ra) # 80000cc4 <release>
}
    80001d9a:	8526                	mv	a0,s1
    80001d9c:	60e2                	ld	ra,24(sp)
    80001d9e:	6442                	ld	s0,16(sp)
    80001da0:	64a2                	ld	s1,8(sp)
    80001da2:	6902                	ld	s2,0(sp)
    80001da4:	6105                	addi	sp,sp,32
    80001da6:	8082                	ret

0000000080001da8 <proc_pagetable>:
{
    80001da8:	1101                	addi	sp,sp,-32
    80001daa:	ec06                	sd	ra,24(sp)
    80001dac:	e822                	sd	s0,16(sp)
    80001dae:	e426                	sd	s1,8(sp)
    80001db0:	e04a                	sd	s2,0(sp)
    80001db2:	1000                	addi	s0,sp,32
    80001db4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	63c080e7          	jalr	1596(ra) # 800013f2 <uvmcreate>
    80001dbe:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001dc0:	c121                	beqz	a0,80001e00 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001dc2:	4729                	li	a4,10
    80001dc4:	00005697          	auipc	a3,0x5
    80001dc8:	23c68693          	addi	a3,a3,572 # 80007000 <_trampoline>
    80001dcc:	6605                	lui	a2,0x1
    80001dce:	040005b7          	lui	a1,0x4000
    80001dd2:	15fd                	addi	a1,a1,-1
    80001dd4:	05b2                	slli	a1,a1,0xc
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	376080e7          	jalr	886(ra) # 8000114c <mappages>
    80001dde:	02054863          	bltz	a0,80001e0e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001de2:	4719                	li	a4,6
    80001de4:	06893683          	ld	a3,104(s2)
    80001de8:	6605                	lui	a2,0x1
    80001dea:	020005b7          	lui	a1,0x2000
    80001dee:	15fd                	addi	a1,a1,-1
    80001df0:	05b6                	slli	a1,a1,0xd
    80001df2:	8526                	mv	a0,s1
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	358080e7          	jalr	856(ra) # 8000114c <mappages>
    80001dfc:	02054163          	bltz	a0,80001e1e <proc_pagetable+0x76>
}
    80001e00:	8526                	mv	a0,s1
    80001e02:	60e2                	ld	ra,24(sp)
    80001e04:	6442                	ld	s0,16(sp)
    80001e06:	64a2                	ld	s1,8(sp)
    80001e08:	6902                	ld	s2,0(sp)
    80001e0a:	6105                	addi	sp,sp,32
    80001e0c:	8082                	ret
    uvmfree(pagetable, 0);
    80001e0e:	4581                	li	a1,0
    80001e10:	8526                	mv	a0,s1
    80001e12:	fffff097          	auipc	ra,0xfffff
    80001e16:	7f4080e7          	jalr	2036(ra) # 80001606 <uvmfree>
    return 0;
    80001e1a:	4481                	li	s1,0
    80001e1c:	b7d5                	j	80001e00 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e1e:	4681                	li	a3,0
    80001e20:	4605                	li	a2,1
    80001e22:	040005b7          	lui	a1,0x4000
    80001e26:	15fd                	addi	a1,a1,-1
    80001e28:	05b2                	slli	a1,a1,0xc
    80001e2a:	8526                	mv	a0,s1
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	502080e7          	jalr	1282(ra) # 8000132e <uvmunmap>
    uvmfree(pagetable, 0);
    80001e34:	4581                	li	a1,0
    80001e36:	8526                	mv	a0,s1
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	7ce080e7          	jalr	1998(ra) # 80001606 <uvmfree>
    return 0;
    80001e40:	4481                	li	s1,0
    80001e42:	bf7d                	j	80001e00 <proc_pagetable+0x58>

0000000080001e44 <proc_freepagetable>:
{
    80001e44:	1101                	addi	sp,sp,-32
    80001e46:	ec06                	sd	ra,24(sp)
    80001e48:	e822                	sd	s0,16(sp)
    80001e4a:	e426                	sd	s1,8(sp)
    80001e4c:	e04a                	sd	s2,0(sp)
    80001e4e:	1000                	addi	s0,sp,32
    80001e50:	84aa                	mv	s1,a0
    80001e52:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e54:	4681                	li	a3,0
    80001e56:	4605                	li	a2,1
    80001e58:	040005b7          	lui	a1,0x4000
    80001e5c:	15fd                	addi	a1,a1,-1
    80001e5e:	05b2                	slli	a1,a1,0xc
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	4ce080e7          	jalr	1230(ra) # 8000132e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e68:	4681                	li	a3,0
    80001e6a:	4605                	li	a2,1
    80001e6c:	020005b7          	lui	a1,0x2000
    80001e70:	15fd                	addi	a1,a1,-1
    80001e72:	05b6                	slli	a1,a1,0xd
    80001e74:	8526                	mv	a0,s1
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	4b8080e7          	jalr	1208(ra) # 8000132e <uvmunmap>
  uvmfree(pagetable, sz);
    80001e7e:	85ca                	mv	a1,s2
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	784080e7          	jalr	1924(ra) # 80001606 <uvmfree>
}
    80001e8a:	60e2                	ld	ra,24(sp)
    80001e8c:	6442                	ld	s0,16(sp)
    80001e8e:	64a2                	ld	s1,8(sp)
    80001e90:	6902                	ld	s2,0(sp)
    80001e92:	6105                	addi	sp,sp,32
    80001e94:	8082                	ret

0000000080001e96 <proc_freekernelpagetable>:
{
    80001e96:	1101                	addi	sp,sp,-32
    80001e98:	ec06                	sd	ra,24(sp)
    80001e9a:	e822                	sd	s0,16(sp)
    80001e9c:	e426                	sd	s1,8(sp)
    80001e9e:	1000                	addi	s0,sp,32
    80001ea0:	84aa                	mv	s1,a0
  if(kstack) 
    80001ea2:	e999                	bnez	a1,80001eb8 <proc_freekernelpagetable+0x22>
  kvmfree(kernel_pagetable);
    80001ea4:	8526                	mv	a0,s1
    80001ea6:	00000097          	auipc	ra,0x0
    80001eaa:	c8a080e7          	jalr	-886(ra) # 80001b30 <kvmfree>
}
    80001eae:	60e2                	ld	ra,24(sp)
    80001eb0:	6442                	ld	s0,16(sp)
    80001eb2:	64a2                	ld	s1,8(sp)
    80001eb4:	6105                	addi	sp,sp,32
    80001eb6:	8082                	ret
    uvmunmap(kernel_pagetable,kstack,1,1);
    80001eb8:	4685                	li	a3,1
    80001eba:	4605                	li	a2,1
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	472080e7          	jalr	1138(ra) # 8000132e <uvmunmap>
    80001ec4:	b7c5                	j	80001ea4 <proc_freekernelpagetable+0xe>

0000000080001ec6 <freeproc>:
{
    80001ec6:	1101                	addi	sp,sp,-32
    80001ec8:	ec06                	sd	ra,24(sp)
    80001eca:	e822                	sd	s0,16(sp)
    80001ecc:	e426                	sd	s1,8(sp)
    80001ece:	1000                	addi	s0,sp,32
    80001ed0:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ed2:	7528                	ld	a0,104(a0)
    80001ed4:	c509                	beqz	a0,80001ede <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	b4e080e7          	jalr	-1202(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001ede:	0604b423          	sd	zero,104(s1)
  if(p->pagetable)
    80001ee2:	68a8                	ld	a0,80(s1)
    80001ee4:	c511                	beqz	a0,80001ef0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ee6:	64ac                	ld	a1,72(s1)
    80001ee8:	00000097          	auipc	ra,0x0
    80001eec:	f5c080e7          	jalr	-164(ra) # 80001e44 <proc_freepagetable>
  if(p->kernel_pagetable) 
    80001ef0:	70a8                	ld	a0,96(s1)
    80001ef2:	c511                	beqz	a0,80001efe <freeproc+0x38>
    proc_freekernelpagetable(p->kernel_pagetable,p->kstack);
    80001ef4:	60ac                	ld	a1,64(s1)
    80001ef6:	00000097          	auipc	ra,0x0
    80001efa:	fa0080e7          	jalr	-96(ra) # 80001e96 <proc_freekernelpagetable>
  p->pagetable = 0;
    80001efe:	0404b823          	sd	zero,80(s1)
  p->kernel_pagetable = 0;
    80001f02:	0604b023          	sd	zero,96(s1)
  p->kstack = 0; // ysw
    80001f06:	0404b023          	sd	zero,64(s1)
  p->sz = 0;
    80001f0a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001f0e:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001f12:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001f16:	16048423          	sb	zero,360(s1)
  p->chan = 0;
    80001f1a:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001f1e:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001f22:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001f26:	0004ac23          	sw	zero,24(s1)
}
    80001f2a:	60e2                	ld	ra,24(sp)
    80001f2c:	6442                	ld	s0,16(sp)
    80001f2e:	64a2                	ld	s1,8(sp)
    80001f30:	6105                	addi	sp,sp,32
    80001f32:	8082                	ret

0000000080001f34 <allocproc>:
{
    80001f34:	1101                	addi	sp,sp,-32
    80001f36:	ec06                	sd	ra,24(sp)
    80001f38:	e822                	sd	s0,16(sp)
    80001f3a:	e426                	sd	s1,8(sp)
    80001f3c:	e04a                	sd	s2,0(sp)
    80001f3e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f40:	00010497          	auipc	s1,0x10
    80001f44:	e2848493          	addi	s1,s1,-472 # 80011d68 <proc>
    80001f48:	00016917          	auipc	s2,0x16
    80001f4c:	c2090913          	addi	s2,s2,-992 # 80017b68 <tickslock>
    acquire(&p->lock);
    80001f50:	8526                	mv	a0,s1
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	cbe080e7          	jalr	-834(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    80001f5a:	4c9c                	lw	a5,24(s1)
    80001f5c:	cf81                	beqz	a5,80001f74 <allocproc+0x40>
      release(&p->lock);
    80001f5e:	8526                	mv	a0,s1
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	d64080e7          	jalr	-668(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f68:	17848493          	addi	s1,s1,376
    80001f6c:	ff2492e3          	bne	s1,s2,80001f50 <allocproc+0x1c>
  return 0;
    80001f70:	4481                	li	s1,0
    80001f72:	a071                	j	80001ffe <allocproc+0xca>
  p->pid = allocpid();
    80001f74:	00000097          	auipc	ra,0x0
    80001f78:	dee080e7          	jalr	-530(ra) # 80001d62 <allocpid>
    80001f7c:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	ba2080e7          	jalr	-1118(ra) # 80000b20 <kalloc>
    80001f86:	892a                	mv	s2,a0
    80001f88:	f4a8                	sd	a0,104(s1)
    80001f8a:	c149                	beqz	a0,8000200c <allocproc+0xd8>
  p->pagetable = proc_pagetable(p);
    80001f8c:	8526                	mv	a0,s1
    80001f8e:	00000097          	auipc	ra,0x0
    80001f92:	e1a080e7          	jalr	-486(ra) # 80001da8 <proc_pagetable>
    80001f96:	892a                	mv	s2,a0
    80001f98:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001f9a:	c141                	beqz	a0,8000201a <allocproc+0xe6>
  p->kernel_pagetable = new_kernel_pagetable();
    80001f9c:	00000097          	auipc	ra,0x0
    80001fa0:	a5e080e7          	jalr	-1442(ra) # 800019fa <new_kernel_pagetable>
    80001fa4:	892a                	mv	s2,a0
    80001fa6:	f0a8                	sd	a0,96(s1)
  if(p->kernel_pagetable == 0) {
    80001fa8:	c549                	beqz	a0,80002032 <allocproc+0xfe>
  char *pa = kalloc(); 
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	b76080e7          	jalr	-1162(ra) # 80000b20 <kalloc>
    80001fb2:	892a                	mv	s2,a0
  if(pa == 0) {
    80001fb4:	c15d                	beqz	a0,8000205a <allocproc+0x126>
  if(mappages(p->kernel_pagetable, va, PGSIZE, (uint64)pa, PTE_R | PTE_W) != 0) 
    80001fb6:	4719                	li	a4,6
    80001fb8:	86aa                	mv	a3,a0
    80001fba:	6605                	lui	a2,0x1
    80001fbc:	040005b7          	lui	a1,0x4000
    80001fc0:	15f5                	addi	a1,a1,-3
    80001fc2:	05b2                	slli	a1,a1,0xc
    80001fc4:	70a8                	ld	a0,96(s1)
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	186080e7          	jalr	390(ra) # 8000114c <mappages>
    80001fce:	e955                	bnez	a0,80002082 <allocproc+0x14e>
  p->kstack = va;
    80001fd0:	040007b7          	lui	a5,0x4000
    80001fd4:	17f5                	addi	a5,a5,-3
    80001fd6:	07b2                	slli	a5,a5,0xc
    80001fd8:	e0bc                	sd	a5,64(s1)
  memset(&p->context, 0, sizeof(p->context));
    80001fda:	07000613          	li	a2,112
    80001fde:	4581                	li	a1,0
    80001fe0:	07048513          	addi	a0,s1,112
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	d28080e7          	jalr	-728(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001fec:	00000797          	auipc	a5,0x0
    80001ff0:	d3078793          	addi	a5,a5,-720 # 80001d1c <forkret>
    80001ff4:	f8bc                	sd	a5,112(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ff6:	60bc                	ld	a5,64(s1)
    80001ff8:	6705                	lui	a4,0x1
    80001ffa:	97ba                	add	a5,a5,a4
    80001ffc:	fcbc                	sd	a5,120(s1)
}
    80001ffe:	8526                	mv	a0,s1
    80002000:	60e2                	ld	ra,24(sp)
    80002002:	6442                	ld	s0,16(sp)
    80002004:	64a2                	ld	s1,8(sp)
    80002006:	6902                	ld	s2,0(sp)
    80002008:	6105                	addi	sp,sp,32
    8000200a:	8082                	ret
    release(&p->lock);
    8000200c:	8526                	mv	a0,s1
    8000200e:	fffff097          	auipc	ra,0xfffff
    80002012:	cb6080e7          	jalr	-842(ra) # 80000cc4 <release>
    return 0;
    80002016:	84ca                	mv	s1,s2
    80002018:	b7dd                	j	80001ffe <allocproc+0xca>
    freeproc(p);
    8000201a:	8526                	mv	a0,s1
    8000201c:	00000097          	auipc	ra,0x0
    80002020:	eaa080e7          	jalr	-342(ra) # 80001ec6 <freeproc>
    release(&p->lock);
    80002024:	8526                	mv	a0,s1
    80002026:	fffff097          	auipc	ra,0xfffff
    8000202a:	c9e080e7          	jalr	-866(ra) # 80000cc4 <release>
    return 0;
    8000202e:	84ca                	mv	s1,s2
    80002030:	b7f9                	j	80001ffe <allocproc+0xca>
    printf("alloc kernel_pagetable error\n");
    80002032:	00006517          	auipc	a0,0x6
    80002036:	26e50513          	addi	a0,a0,622 # 800082a0 <digits+0x270>
    8000203a:	ffffe097          	auipc	ra,0xffffe
    8000203e:	558080e7          	jalr	1368(ra) # 80000592 <printf>
    freeproc(p);
    80002042:	8526                	mv	a0,s1
    80002044:	00000097          	auipc	ra,0x0
    80002048:	e82080e7          	jalr	-382(ra) # 80001ec6 <freeproc>
    release(&p->lock);
    8000204c:	8526                	mv	a0,s1
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	c76080e7          	jalr	-906(ra) # 80000cc4 <release>
    return 0;
    80002056:	84ca                	mv	s1,s2
    80002058:	b75d                	j	80001ffe <allocproc+0xca>
    printf("alloc kernel stack error\n");
    8000205a:	00006517          	auipc	a0,0x6
    8000205e:	08650513          	addi	a0,a0,134 # 800080e0 <digits+0xb0>
    80002062:	ffffe097          	auipc	ra,0xffffe
    80002066:	530080e7          	jalr	1328(ra) # 80000592 <printf>
    freeproc(p);
    8000206a:	8526                	mv	a0,s1
    8000206c:	00000097          	auipc	ra,0x0
    80002070:	e5a080e7          	jalr	-422(ra) # 80001ec6 <freeproc>
    release(&p->lock);
    80002074:	8526                	mv	a0,s1
    80002076:	fffff097          	auipc	ra,0xfffff
    8000207a:	c4e080e7          	jalr	-946(ra) # 80000cc4 <release>
    return 0;
    8000207e:	84ca                	mv	s1,s2
    80002080:	bfbd                	j	80001ffe <allocproc+0xca>
    panic("allocproc mappages");
    80002082:	00006517          	auipc	a0,0x6
    80002086:	07e50513          	addi	a0,a0,126 # 80008100 <digits+0xd0>
    8000208a:	ffffe097          	auipc	ra,0xffffe
    8000208e:	4be080e7          	jalr	1214(ra) # 80000548 <panic>

0000000080002092 <userinit>:
{
    80002092:	1101                	addi	sp,sp,-32
    80002094:	ec06                	sd	ra,24(sp)
    80002096:	e822                	sd	s0,16(sp)
    80002098:	e426                	sd	s1,8(sp)
    8000209a:	1000                	addi	s0,sp,32
  p = allocproc();
    8000209c:	00000097          	auipc	ra,0x0
    800020a0:	e98080e7          	jalr	-360(ra) # 80001f34 <allocproc>
    800020a4:	84aa                	mv	s1,a0
  initproc = p;
    800020a6:	00007797          	auipc	a5,0x7
    800020aa:	f6a7b923          	sd	a0,-142(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800020ae:	03400613          	li	a2,52
    800020b2:	00007597          	auipc	a1,0x7
    800020b6:	89e58593          	addi	a1,a1,-1890 # 80008950 <initcode>
    800020ba:	6928                	ld	a0,80(a0)
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	364080e7          	jalr	868(ra) # 80001420 <uvminit>
  p->sz = PGSIZE;
    800020c4:	6785                	lui	a5,0x1
    800020c6:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    800020c8:	74b8                	ld	a4,104(s1)
    800020ca:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800020ce:	74b8                	ld	a4,104(s1)
    800020d0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800020d2:	4641                	li	a2,16
    800020d4:	00006597          	auipc	a1,0x6
    800020d8:	1ec58593          	addi	a1,a1,492 # 800082c0 <digits+0x290>
    800020dc:	16848513          	addi	a0,s1,360
    800020e0:	fffff097          	auipc	ra,0xfffff
    800020e4:	d82080e7          	jalr	-638(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    800020e8:	00006517          	auipc	a0,0x6
    800020ec:	1e850513          	addi	a0,a0,488 # 800082d0 <digits+0x2a0>
    800020f0:	00002097          	auipc	ra,0x2
    800020f4:	10c080e7          	jalr	268(ra) # 800041fc <namei>
    800020f8:	16a4b023          	sd	a0,352(s1)
  p->state = RUNNABLE;
    800020fc:	4789                	li	a5,2
    800020fe:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	bc2080e7          	jalr	-1086(ra) # 80000cc4 <release>
}
    8000210a:	60e2                	ld	ra,24(sp)
    8000210c:	6442                	ld	s0,16(sp)
    8000210e:	64a2                	ld	s1,8(sp)
    80002110:	6105                	addi	sp,sp,32
    80002112:	8082                	ret

0000000080002114 <growproc>:
{
    80002114:	1101                	addi	sp,sp,-32
    80002116:	ec06                	sd	ra,24(sp)
    80002118:	e822                	sd	s0,16(sp)
    8000211a:	e426                	sd	s1,8(sp)
    8000211c:	e04a                	sd	s2,0(sp)
    8000211e:	1000                	addi	s0,sp,32
    80002120:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002122:	00000097          	auipc	ra,0x0
    80002126:	bc2080e7          	jalr	-1086(ra) # 80001ce4 <myproc>
    8000212a:	892a                	mv	s2,a0
  sz = p->sz;
    8000212c:	652c                	ld	a1,72(a0)
    8000212e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002132:	00904f63          	bgtz	s1,80002150 <growproc+0x3c>
  } else if(n < 0){
    80002136:	0204cc63          	bltz	s1,8000216e <growproc+0x5a>
  p->sz = sz;
    8000213a:	1602                	slli	a2,a2,0x20
    8000213c:	9201                	srli	a2,a2,0x20
    8000213e:	04c93423          	sd	a2,72(s2)
  return 0;
    80002142:	4501                	li	a0,0
}
    80002144:	60e2                	ld	ra,24(sp)
    80002146:	6442                	ld	s0,16(sp)
    80002148:	64a2                	ld	s1,8(sp)
    8000214a:	6902                	ld	s2,0(sp)
    8000214c:	6105                	addi	sp,sp,32
    8000214e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002150:	9e25                	addw	a2,a2,s1
    80002152:	1602                	slli	a2,a2,0x20
    80002154:	9201                	srli	a2,a2,0x20
    80002156:	1582                	slli	a1,a1,0x20
    80002158:	9181                	srli	a1,a1,0x20
    8000215a:	6928                	ld	a0,80(a0)
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	37e080e7          	jalr	894(ra) # 800014da <uvmalloc>
    80002164:	0005061b          	sext.w	a2,a0
    80002168:	fa69                	bnez	a2,8000213a <growproc+0x26>
      return -1;
    8000216a:	557d                	li	a0,-1
    8000216c:	bfe1                	j	80002144 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000216e:	9e25                	addw	a2,a2,s1
    80002170:	1602                	slli	a2,a2,0x20
    80002172:	9201                	srli	a2,a2,0x20
    80002174:	1582                	slli	a1,a1,0x20
    80002176:	9181                	srli	a1,a1,0x20
    80002178:	6928                	ld	a0,80(a0)
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	318080e7          	jalr	792(ra) # 80001492 <uvmdealloc>
    80002182:	0005061b          	sext.w	a2,a0
    80002186:	bf55                	j	8000213a <growproc+0x26>

0000000080002188 <fork>:
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	e052                	sd	s4,0(sp)
    80002196:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002198:	00000097          	auipc	ra,0x0
    8000219c:	b4c080e7          	jalr	-1204(ra) # 80001ce4 <myproc>
    800021a0:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800021a2:	00000097          	auipc	ra,0x0
    800021a6:	d92080e7          	jalr	-622(ra) # 80001f34 <allocproc>
    800021aa:	c175                	beqz	a0,8000228e <fork+0x106>
    800021ac:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800021ae:	04893603          	ld	a2,72(s2)
    800021b2:	692c                	ld	a1,80(a0)
    800021b4:	05093503          	ld	a0,80(s2)
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	486080e7          	jalr	1158(ra) # 8000163e <uvmcopy>
    800021c0:	04054863          	bltz	a0,80002210 <fork+0x88>
  np->sz = p->sz;
    800021c4:	04893783          	ld	a5,72(s2)
    800021c8:	04f9b423          	sd	a5,72(s3)
  np->parent = p;
    800021cc:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    800021d0:	06893683          	ld	a3,104(s2)
    800021d4:	87b6                	mv	a5,a3
    800021d6:	0689b703          	ld	a4,104(s3)
    800021da:	12068693          	addi	a3,a3,288
    800021de:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800021e2:	6788                	ld	a0,8(a5)
    800021e4:	6b8c                	ld	a1,16(a5)
    800021e6:	6f90                	ld	a2,24(a5)
    800021e8:	01073023          	sd	a6,0(a4)
    800021ec:	e708                	sd	a0,8(a4)
    800021ee:	eb0c                	sd	a1,16(a4)
    800021f0:	ef10                	sd	a2,24(a4)
    800021f2:	02078793          	addi	a5,a5,32
    800021f6:	02070713          	addi	a4,a4,32
    800021fa:	fed792e3          	bne	a5,a3,800021de <fork+0x56>
  np->trapframe->a0 = 0;
    800021fe:	0689b783          	ld	a5,104(s3)
    80002202:	0607b823          	sd	zero,112(a5)
    80002206:	0e000493          	li	s1,224
  for(i = 0; i < NOFILE; i++)
    8000220a:	16000a13          	li	s4,352
    8000220e:	a03d                	j	8000223c <fork+0xb4>
    freeproc(np);
    80002210:	854e                	mv	a0,s3
    80002212:	00000097          	auipc	ra,0x0
    80002216:	cb4080e7          	jalr	-844(ra) # 80001ec6 <freeproc>
    release(&np->lock);
    8000221a:	854e                	mv	a0,s3
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	aa8080e7          	jalr	-1368(ra) # 80000cc4 <release>
    return -1;
    80002224:	54fd                	li	s1,-1
    80002226:	a899                	j	8000227c <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002228:	00002097          	auipc	ra,0x2
    8000222c:	660080e7          	jalr	1632(ra) # 80004888 <filedup>
    80002230:	009987b3          	add	a5,s3,s1
    80002234:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002236:	04a1                	addi	s1,s1,8
    80002238:	01448763          	beq	s1,s4,80002246 <fork+0xbe>
    if(p->ofile[i])
    8000223c:	009907b3          	add	a5,s2,s1
    80002240:	6388                	ld	a0,0(a5)
    80002242:	f17d                	bnez	a0,80002228 <fork+0xa0>
    80002244:	bfcd                	j	80002236 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002246:	16093503          	ld	a0,352(s2)
    8000224a:	00001097          	auipc	ra,0x1
    8000224e:	7c4080e7          	jalr	1988(ra) # 80003a0e <idup>
    80002252:	16a9b023          	sd	a0,352(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002256:	4641                	li	a2,16
    80002258:	16890593          	addi	a1,s2,360
    8000225c:	16898513          	addi	a0,s3,360
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	c02080e7          	jalr	-1022(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    80002268:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    8000226c:	4789                	li	a5,2
    8000226e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002272:	854e                	mv	a0,s3
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	a50080e7          	jalr	-1456(ra) # 80000cc4 <release>
}
    8000227c:	8526                	mv	a0,s1
    8000227e:	70a2                	ld	ra,40(sp)
    80002280:	7402                	ld	s0,32(sp)
    80002282:	64e2                	ld	s1,24(sp)
    80002284:	6942                	ld	s2,16(sp)
    80002286:	69a2                	ld	s3,8(sp)
    80002288:	6a02                	ld	s4,0(sp)
    8000228a:	6145                	addi	sp,sp,48
    8000228c:	8082                	ret
    return -1;
    8000228e:	54fd                	li	s1,-1
    80002290:	b7f5                	j	8000227c <fork+0xf4>

0000000080002292 <reparent>:
{
    80002292:	7179                	addi	sp,sp,-48
    80002294:	f406                	sd	ra,40(sp)
    80002296:	f022                	sd	s0,32(sp)
    80002298:	ec26                	sd	s1,24(sp)
    8000229a:	e84a                	sd	s2,16(sp)
    8000229c:	e44e                	sd	s3,8(sp)
    8000229e:	e052                	sd	s4,0(sp)
    800022a0:	1800                	addi	s0,sp,48
    800022a2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022a4:	00010497          	auipc	s1,0x10
    800022a8:	ac448493          	addi	s1,s1,-1340 # 80011d68 <proc>
      pp->parent = initproc;
    800022ac:	00007a17          	auipc	s4,0x7
    800022b0:	d6ca0a13          	addi	s4,s4,-660 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022b4:	00016997          	auipc	s3,0x16
    800022b8:	8b498993          	addi	s3,s3,-1868 # 80017b68 <tickslock>
    800022bc:	a029                	j	800022c6 <reparent+0x34>
    800022be:	17848493          	addi	s1,s1,376
    800022c2:	03348363          	beq	s1,s3,800022e8 <reparent+0x56>
    if(pp->parent == p){
    800022c6:	709c                	ld	a5,32(s1)
    800022c8:	ff279be3          	bne	a5,s2,800022be <reparent+0x2c>
      acquire(&pp->lock);
    800022cc:	8526                	mv	a0,s1
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	942080e7          	jalr	-1726(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    800022d6:	000a3783          	ld	a5,0(s4)
    800022da:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    800022dc:	8526                	mv	a0,s1
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	9e6080e7          	jalr	-1562(ra) # 80000cc4 <release>
    800022e6:	bfe1                	j	800022be <reparent+0x2c>
}
    800022e8:	70a2                	ld	ra,40(sp)
    800022ea:	7402                	ld	s0,32(sp)
    800022ec:	64e2                	ld	s1,24(sp)
    800022ee:	6942                	ld	s2,16(sp)
    800022f0:	69a2                	ld	s3,8(sp)
    800022f2:	6a02                	ld	s4,0(sp)
    800022f4:	6145                	addi	sp,sp,48
    800022f6:	8082                	ret

00000000800022f8 <scheduler>:
{
    800022f8:	715d                	addi	sp,sp,-80
    800022fa:	e486                	sd	ra,72(sp)
    800022fc:	e0a2                	sd	s0,64(sp)
    800022fe:	fc26                	sd	s1,56(sp)
    80002300:	f84a                	sd	s2,48(sp)
    80002302:	f44e                	sd	s3,40(sp)
    80002304:	f052                	sd	s4,32(sp)
    80002306:	ec56                	sd	s5,24(sp)
    80002308:	e85a                	sd	s6,16(sp)
    8000230a:	e45e                	sd	s7,8(sp)
    8000230c:	e062                	sd	s8,0(sp)
    8000230e:	0880                	addi	s0,sp,80
    80002310:	8792                	mv	a5,tp
  int id = r_tp();
    80002312:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002314:	00779b13          	slli	s6,a5,0x7
    80002318:	0000f717          	auipc	a4,0xf
    8000231c:	63870713          	addi	a4,a4,1592 # 80011950 <pid_lock>
    80002320:	975a                	add	a4,a4,s6
    80002322:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002326:	0000f717          	auipc	a4,0xf
    8000232a:	64a70713          	addi	a4,a4,1610 # 80011970 <cpus+0x8>
    8000232e:	9b3a                	add	s6,s6,a4
        c->proc = p;
    80002330:	079e                	slli	a5,a5,0x7
    80002332:	0000fa17          	auipc	s4,0xf
    80002336:	61ea0a13          	addi	s4,s4,1566 # 80011950 <pid_lock>
    8000233a:	9a3e                	add	s4,s4,a5
        w_satp(MAKE_SATP(p->kernel_pagetable));
    8000233c:	5bfd                	li	s7,-1
    8000233e:	1bfe                	slli	s7,s7,0x3f
    for(p = proc; p < &proc[NPROC]; p++) {
    80002340:	00016997          	auipc	s3,0x16
    80002344:	82898993          	addi	s3,s3,-2008 # 80017b68 <tickslock>
    80002348:	a899                	j	8000239e <scheduler+0xa6>
        p->state = RUNNING;
    8000234a:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    8000234e:	009a3c23          	sd	s1,24(s4)
        w_satp(MAKE_SATP(p->kernel_pagetable));
    80002352:	70bc                	ld	a5,96(s1)
    80002354:	83b1                	srli	a5,a5,0xc
    80002356:	0177e7b3          	or	a5,a5,s7
  asm volatile("csrw satp, %0" : : "r" (x));
    8000235a:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000235e:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    80002362:	07048593          	addi	a1,s1,112
    80002366:	855a                	mv	a0,s6
    80002368:	00000097          	auipc	ra,0x0
    8000236c:	666080e7          	jalr	1638(ra) # 800029ce <swtch>
        c->proc = 0;
    80002370:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80002374:	4c05                	li	s8,1
      release(&p->lock);
    80002376:	8526                	mv	a0,s1
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	94c080e7          	jalr	-1716(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002380:	17848493          	addi	s1,s1,376
    80002384:	01348b63          	beq	s1,s3,8000239a <scheduler+0xa2>
      acquire(&p->lock);
    80002388:	8526                	mv	a0,s1
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	886080e7          	jalr	-1914(ra) # 80000c10 <acquire>
      if(p->state == RUNNABLE) {
    80002392:	4c9c                	lw	a5,24(s1)
    80002394:	ff2791e3          	bne	a5,s2,80002376 <scheduler+0x7e>
    80002398:	bf4d                	j	8000234a <scheduler+0x52>
    if(found == 0) {
    8000239a:	020c0063          	beqz	s8,800023ba <scheduler+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000239e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800023a2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800023a6:	10079073          	csrw	sstatus,a5
    int found = 0;
    800023aa:	4c01                	li	s8,0
    for(p = proc; p < &proc[NPROC]; p++) {
    800023ac:	00010497          	auipc	s1,0x10
    800023b0:	9bc48493          	addi	s1,s1,-1604 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    800023b4:	4909                	li	s2,2
        p->state = RUNNING;
    800023b6:	4a8d                	li	s5,3
    800023b8:	bfc1                	j	80002388 <scheduler+0x90>
      kvminithart();
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	c22080e7          	jalr	-990(ra) # 80000fdc <kvminithart>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023c2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800023c6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800023ca:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800023ce:	10500073          	wfi
    800023d2:	b7f1                	j	8000239e <scheduler+0xa6>

00000000800023d4 <sched>:
{
    800023d4:	7179                	addi	sp,sp,-48
    800023d6:	f406                	sd	ra,40(sp)
    800023d8:	f022                	sd	s0,32(sp)
    800023da:	ec26                	sd	s1,24(sp)
    800023dc:	e84a                	sd	s2,16(sp)
    800023de:	e44e                	sd	s3,8(sp)
    800023e0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800023e2:	00000097          	auipc	ra,0x0
    800023e6:	902080e7          	jalr	-1790(ra) # 80001ce4 <myproc>
    800023ea:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800023ec:	ffffe097          	auipc	ra,0xffffe
    800023f0:	7aa080e7          	jalr	1962(ra) # 80000b96 <holding>
    800023f4:	cd3d                	beqz	a0,80002472 <sched+0x9e>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023f6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800023f8:	2781                	sext.w	a5,a5
    800023fa:	079e                	slli	a5,a5,0x7
    800023fc:	0000f717          	auipc	a4,0xf
    80002400:	55470713          	addi	a4,a4,1364 # 80011950 <pid_lock>
    80002404:	97ba                	add	a5,a5,a4
    80002406:	0907a703          	lw	a4,144(a5)
    8000240a:	4785                	li	a5,1
    8000240c:	06f71b63          	bne	a4,a5,80002482 <sched+0xae>
  if(p->state == RUNNING)
    80002410:	4c98                	lw	a4,24(s1)
    80002412:	478d                	li	a5,3
    80002414:	06f70f63          	beq	a4,a5,80002492 <sched+0xbe>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002418:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000241c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000241e:	e3d1                	bnez	a5,800024a2 <sched+0xce>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002420:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002422:	0000f917          	auipc	s2,0xf
    80002426:	52e90913          	addi	s2,s2,1326 # 80011950 <pid_lock>
    8000242a:	2781                	sext.w	a5,a5
    8000242c:	079e                	slli	a5,a5,0x7
    8000242e:	97ca                	add	a5,a5,s2
    80002430:	0947a983          	lw	s3,148(a5)
  kvminithart();
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	ba8080e7          	jalr	-1112(ra) # 80000fdc <kvminithart>
    8000243c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000243e:	2781                	sext.w	a5,a5
    80002440:	079e                	slli	a5,a5,0x7
    80002442:	0000f597          	auipc	a1,0xf
    80002446:	52e58593          	addi	a1,a1,1326 # 80011970 <cpus+0x8>
    8000244a:	95be                	add	a1,a1,a5
    8000244c:	07048513          	addi	a0,s1,112
    80002450:	00000097          	auipc	ra,0x0
    80002454:	57e080e7          	jalr	1406(ra) # 800029ce <swtch>
    80002458:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000245a:	2781                	sext.w	a5,a5
    8000245c:	079e                	slli	a5,a5,0x7
    8000245e:	97ca                	add	a5,a5,s2
    80002460:	0937aa23          	sw	s3,148(a5)
}
    80002464:	70a2                	ld	ra,40(sp)
    80002466:	7402                	ld	s0,32(sp)
    80002468:	64e2                	ld	s1,24(sp)
    8000246a:	6942                	ld	s2,16(sp)
    8000246c:	69a2                	ld	s3,8(sp)
    8000246e:	6145                	addi	sp,sp,48
    80002470:	8082                	ret
    panic("sched p->lock");
    80002472:	00006517          	auipc	a0,0x6
    80002476:	e6650513          	addi	a0,a0,-410 # 800082d8 <digits+0x2a8>
    8000247a:	ffffe097          	auipc	ra,0xffffe
    8000247e:	0ce080e7          	jalr	206(ra) # 80000548 <panic>
    panic("sched locks");
    80002482:	00006517          	auipc	a0,0x6
    80002486:	e6650513          	addi	a0,a0,-410 # 800082e8 <digits+0x2b8>
    8000248a:	ffffe097          	auipc	ra,0xffffe
    8000248e:	0be080e7          	jalr	190(ra) # 80000548 <panic>
    panic("sched running");
    80002492:	00006517          	auipc	a0,0x6
    80002496:	e6650513          	addi	a0,a0,-410 # 800082f8 <digits+0x2c8>
    8000249a:	ffffe097          	auipc	ra,0xffffe
    8000249e:	0ae080e7          	jalr	174(ra) # 80000548 <panic>
    panic("sched interruptible");
    800024a2:	00006517          	auipc	a0,0x6
    800024a6:	e6650513          	addi	a0,a0,-410 # 80008308 <digits+0x2d8>
    800024aa:	ffffe097          	auipc	ra,0xffffe
    800024ae:	09e080e7          	jalr	158(ra) # 80000548 <panic>

00000000800024b2 <exit>:
{
    800024b2:	7179                	addi	sp,sp,-48
    800024b4:	f406                	sd	ra,40(sp)
    800024b6:	f022                	sd	s0,32(sp)
    800024b8:	ec26                	sd	s1,24(sp)
    800024ba:	e84a                	sd	s2,16(sp)
    800024bc:	e44e                	sd	s3,8(sp)
    800024be:	e052                	sd	s4,0(sp)
    800024c0:	1800                	addi	s0,sp,48
    800024c2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024c4:	00000097          	auipc	ra,0x0
    800024c8:	820080e7          	jalr	-2016(ra) # 80001ce4 <myproc>
    800024cc:	89aa                	mv	s3,a0
  if(p == initproc)
    800024ce:	00007797          	auipc	a5,0x7
    800024d2:	b4a7b783          	ld	a5,-1206(a5) # 80009018 <initproc>
    800024d6:	0e050493          	addi	s1,a0,224
    800024da:	16050913          	addi	s2,a0,352
    800024de:	02a79363          	bne	a5,a0,80002504 <exit+0x52>
    panic("init exiting");
    800024e2:	00006517          	auipc	a0,0x6
    800024e6:	e3e50513          	addi	a0,a0,-450 # 80008320 <digits+0x2f0>
    800024ea:	ffffe097          	auipc	ra,0xffffe
    800024ee:	05e080e7          	jalr	94(ra) # 80000548 <panic>
      fileclose(f);
    800024f2:	00002097          	auipc	ra,0x2
    800024f6:	3e8080e7          	jalr	1000(ra) # 800048da <fileclose>
      p->ofile[fd] = 0;
    800024fa:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024fe:	04a1                	addi	s1,s1,8
    80002500:	01248563          	beq	s1,s2,8000250a <exit+0x58>
    if(p->ofile[fd]){
    80002504:	6088                	ld	a0,0(s1)
    80002506:	f575                	bnez	a0,800024f2 <exit+0x40>
    80002508:	bfdd                	j	800024fe <exit+0x4c>
  begin_op();
    8000250a:	00002097          	auipc	ra,0x2
    8000250e:	efe080e7          	jalr	-258(ra) # 80004408 <begin_op>
  iput(p->cwd);
    80002512:	1609b503          	ld	a0,352(s3)
    80002516:	00001097          	auipc	ra,0x1
    8000251a:	6f0080e7          	jalr	1776(ra) # 80003c06 <iput>
  end_op();
    8000251e:	00002097          	auipc	ra,0x2
    80002522:	f6a080e7          	jalr	-150(ra) # 80004488 <end_op>
  p->cwd = 0;
    80002526:	1609b023          	sd	zero,352(s3)
  acquire(&initproc->lock);
    8000252a:	00007497          	auipc	s1,0x7
    8000252e:	aee48493          	addi	s1,s1,-1298 # 80009018 <initproc>
    80002532:	6088                	ld	a0,0(s1)
    80002534:	ffffe097          	auipc	ra,0xffffe
    80002538:	6dc080e7          	jalr	1756(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    8000253c:	6088                	ld	a0,0(s1)
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	6ce080e7          	jalr	1742(ra) # 80001c0c <wakeup1>
  release(&initproc->lock);
    80002546:	6088                	ld	a0,0(s1)
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	77c080e7          	jalr	1916(ra) # 80000cc4 <release>
  acquire(&p->lock);
    80002550:	854e                	mv	a0,s3
    80002552:	ffffe097          	auipc	ra,0xffffe
    80002556:	6be080e7          	jalr	1726(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    8000255a:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000255e:	854e                	mv	a0,s3
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	764080e7          	jalr	1892(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    80002568:	8526                	mv	a0,s1
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	6a6080e7          	jalr	1702(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    80002572:	854e                	mv	a0,s3
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	69c080e7          	jalr	1692(ra) # 80000c10 <acquire>
  reparent(p);
    8000257c:	854e                	mv	a0,s3
    8000257e:	00000097          	auipc	ra,0x0
    80002582:	d14080e7          	jalr	-748(ra) # 80002292 <reparent>
  wakeup1(original_parent);
    80002586:	8526                	mv	a0,s1
    80002588:	fffff097          	auipc	ra,0xfffff
    8000258c:	684080e7          	jalr	1668(ra) # 80001c0c <wakeup1>
  p->xstate = status;
    80002590:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002594:	4791                	li	a5,4
    80002596:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000259a:	8526                	mv	a0,s1
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	728080e7          	jalr	1832(ra) # 80000cc4 <release>
  sched();
    800025a4:	00000097          	auipc	ra,0x0
    800025a8:	e30080e7          	jalr	-464(ra) # 800023d4 <sched>
  panic("zombie exit");
    800025ac:	00006517          	auipc	a0,0x6
    800025b0:	d8450513          	addi	a0,a0,-636 # 80008330 <digits+0x300>
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	f94080e7          	jalr	-108(ra) # 80000548 <panic>

00000000800025bc <yield>:
{
    800025bc:	1101                	addi	sp,sp,-32
    800025be:	ec06                	sd	ra,24(sp)
    800025c0:	e822                	sd	s0,16(sp)
    800025c2:	e426                	sd	s1,8(sp)
    800025c4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800025c6:	fffff097          	auipc	ra,0xfffff
    800025ca:	71e080e7          	jalr	1822(ra) # 80001ce4 <myproc>
    800025ce:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	640080e7          	jalr	1600(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    800025d8:	4789                	li	a5,2
    800025da:	cc9c                	sw	a5,24(s1)
  sched();
    800025dc:	00000097          	auipc	ra,0x0
    800025e0:	df8080e7          	jalr	-520(ra) # 800023d4 <sched>
  release(&p->lock);
    800025e4:	8526                	mv	a0,s1
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	6de080e7          	jalr	1758(ra) # 80000cc4 <release>
}
    800025ee:	60e2                	ld	ra,24(sp)
    800025f0:	6442                	ld	s0,16(sp)
    800025f2:	64a2                	ld	s1,8(sp)
    800025f4:	6105                	addi	sp,sp,32
    800025f6:	8082                	ret

00000000800025f8 <sleep>:
{
    800025f8:	7179                	addi	sp,sp,-48
    800025fa:	f406                	sd	ra,40(sp)
    800025fc:	f022                	sd	s0,32(sp)
    800025fe:	ec26                	sd	s1,24(sp)
    80002600:	e84a                	sd	s2,16(sp)
    80002602:	e44e                	sd	s3,8(sp)
    80002604:	1800                	addi	s0,sp,48
    80002606:	89aa                	mv	s3,a0
    80002608:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000260a:	fffff097          	auipc	ra,0xfffff
    8000260e:	6da080e7          	jalr	1754(ra) # 80001ce4 <myproc>
    80002612:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002614:	05250663          	beq	a0,s2,80002660 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	5f8080e7          	jalr	1528(ra) # 80000c10 <acquire>
    release(lk);
    80002620:	854a                	mv	a0,s2
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	6a2080e7          	jalr	1698(ra) # 80000cc4 <release>
  p->chan = chan;
    8000262a:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000262e:	4785                	li	a5,1
    80002630:	cc9c                	sw	a5,24(s1)
  sched();
    80002632:	00000097          	auipc	ra,0x0
    80002636:	da2080e7          	jalr	-606(ra) # 800023d4 <sched>
  p->chan = 0;
    8000263a:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000263e:	8526                	mv	a0,s1
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	684080e7          	jalr	1668(ra) # 80000cc4 <release>
    acquire(lk);
    80002648:	854a                	mv	a0,s2
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	5c6080e7          	jalr	1478(ra) # 80000c10 <acquire>
}
    80002652:	70a2                	ld	ra,40(sp)
    80002654:	7402                	ld	s0,32(sp)
    80002656:	64e2                	ld	s1,24(sp)
    80002658:	6942                	ld	s2,16(sp)
    8000265a:	69a2                	ld	s3,8(sp)
    8000265c:	6145                	addi	sp,sp,48
    8000265e:	8082                	ret
  p->chan = chan;
    80002660:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002664:	4785                	li	a5,1
    80002666:	cd1c                	sw	a5,24(a0)
  sched();
    80002668:	00000097          	auipc	ra,0x0
    8000266c:	d6c080e7          	jalr	-660(ra) # 800023d4 <sched>
  p->chan = 0;
    80002670:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002674:	bff9                	j	80002652 <sleep+0x5a>

0000000080002676 <wait>:
{
    80002676:	715d                	addi	sp,sp,-80
    80002678:	e486                	sd	ra,72(sp)
    8000267a:	e0a2                	sd	s0,64(sp)
    8000267c:	fc26                	sd	s1,56(sp)
    8000267e:	f84a                	sd	s2,48(sp)
    80002680:	f44e                	sd	s3,40(sp)
    80002682:	f052                	sd	s4,32(sp)
    80002684:	ec56                	sd	s5,24(sp)
    80002686:	e85a                	sd	s6,16(sp)
    80002688:	e45e                	sd	s7,8(sp)
    8000268a:	e062                	sd	s8,0(sp)
    8000268c:	0880                	addi	s0,sp,80
    8000268e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002690:	fffff097          	auipc	ra,0xfffff
    80002694:	654080e7          	jalr	1620(ra) # 80001ce4 <myproc>
    80002698:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000269a:	8c2a                	mv	s8,a0
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	574080e7          	jalr	1396(ra) # 80000c10 <acquire>
    havekids = 0;
    800026a4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800026a6:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800026a8:	00015997          	auipc	s3,0x15
    800026ac:	4c098993          	addi	s3,s3,1216 # 80017b68 <tickslock>
        havekids = 1;
    800026b0:	4a85                	li	s5,1
    havekids = 0;
    800026b2:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800026b4:	0000f497          	auipc	s1,0xf
    800026b8:	6b448493          	addi	s1,s1,1716 # 80011d68 <proc>
    800026bc:	a08d                	j	8000271e <wait+0xa8>
          pid = np->pid;
    800026be:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800026c2:	000b0e63          	beqz	s6,800026de <wait+0x68>
    800026c6:	4691                	li	a3,4
    800026c8:	03448613          	addi	a2,s1,52
    800026cc:	85da                	mv	a1,s6
    800026ce:	05093503          	ld	a0,80(s2)
    800026d2:	fffff097          	auipc	ra,0xfffff
    800026d6:	070080e7          	jalr	112(ra) # 80001742 <copyout>
    800026da:	02054263          	bltz	a0,800026fe <wait+0x88>
          freeproc(np);
    800026de:	8526                	mv	a0,s1
    800026e0:	fffff097          	auipc	ra,0xfffff
    800026e4:	7e6080e7          	jalr	2022(ra) # 80001ec6 <freeproc>
          release(&np->lock);
    800026e8:	8526                	mv	a0,s1
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	5da080e7          	jalr	1498(ra) # 80000cc4 <release>
          release(&p->lock);
    800026f2:	854a                	mv	a0,s2
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	5d0080e7          	jalr	1488(ra) # 80000cc4 <release>
          return pid;
    800026fc:	a8a9                	j	80002756 <wait+0xe0>
            release(&np->lock);
    800026fe:	8526                	mv	a0,s1
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	5c4080e7          	jalr	1476(ra) # 80000cc4 <release>
            release(&p->lock);
    80002708:	854a                	mv	a0,s2
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	5ba080e7          	jalr	1466(ra) # 80000cc4 <release>
            return -1;
    80002712:	59fd                	li	s3,-1
    80002714:	a089                	j	80002756 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002716:	17848493          	addi	s1,s1,376
    8000271a:	03348463          	beq	s1,s3,80002742 <wait+0xcc>
      if(np->parent == p){
    8000271e:	709c                	ld	a5,32(s1)
    80002720:	ff279be3          	bne	a5,s2,80002716 <wait+0xa0>
        acquire(&np->lock);
    80002724:	8526                	mv	a0,s1
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	4ea080e7          	jalr	1258(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    8000272e:	4c9c                	lw	a5,24(s1)
    80002730:	f94787e3          	beq	a5,s4,800026be <wait+0x48>
        release(&np->lock);
    80002734:	8526                	mv	a0,s1
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	58e080e7          	jalr	1422(ra) # 80000cc4 <release>
        havekids = 1;
    8000273e:	8756                	mv	a4,s5
    80002740:	bfd9                	j	80002716 <wait+0xa0>
    if(!havekids || p->killed){
    80002742:	c701                	beqz	a4,8000274a <wait+0xd4>
    80002744:	03092783          	lw	a5,48(s2)
    80002748:	c785                	beqz	a5,80002770 <wait+0xfa>
      release(&p->lock);
    8000274a:	854a                	mv	a0,s2
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	578080e7          	jalr	1400(ra) # 80000cc4 <release>
      return -1;
    80002754:	59fd                	li	s3,-1
}
    80002756:	854e                	mv	a0,s3
    80002758:	60a6                	ld	ra,72(sp)
    8000275a:	6406                	ld	s0,64(sp)
    8000275c:	74e2                	ld	s1,56(sp)
    8000275e:	7942                	ld	s2,48(sp)
    80002760:	79a2                	ld	s3,40(sp)
    80002762:	7a02                	ld	s4,32(sp)
    80002764:	6ae2                	ld	s5,24(sp)
    80002766:	6b42                	ld	s6,16(sp)
    80002768:	6ba2                	ld	s7,8(sp)
    8000276a:	6c02                	ld	s8,0(sp)
    8000276c:	6161                	addi	sp,sp,80
    8000276e:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002770:	85e2                	mv	a1,s8
    80002772:	854a                	mv	a0,s2
    80002774:	00000097          	auipc	ra,0x0
    80002778:	e84080e7          	jalr	-380(ra) # 800025f8 <sleep>
    havekids = 0;
    8000277c:	bf1d                	j	800026b2 <wait+0x3c>

000000008000277e <wakeup>:
{
    8000277e:	7139                	addi	sp,sp,-64
    80002780:	fc06                	sd	ra,56(sp)
    80002782:	f822                	sd	s0,48(sp)
    80002784:	f426                	sd	s1,40(sp)
    80002786:	f04a                	sd	s2,32(sp)
    80002788:	ec4e                	sd	s3,24(sp)
    8000278a:	e852                	sd	s4,16(sp)
    8000278c:	e456                	sd	s5,8(sp)
    8000278e:	0080                	addi	s0,sp,64
    80002790:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002792:	0000f497          	auipc	s1,0xf
    80002796:	5d648493          	addi	s1,s1,1494 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    8000279a:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000279c:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000279e:	00015917          	auipc	s2,0x15
    800027a2:	3ca90913          	addi	s2,s2,970 # 80017b68 <tickslock>
    800027a6:	a821                	j	800027be <wakeup+0x40>
      p->state = RUNNABLE;
    800027a8:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800027ac:	8526                	mv	a0,s1
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	516080e7          	jalr	1302(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800027b6:	17848493          	addi	s1,s1,376
    800027ba:	01248e63          	beq	s1,s2,800027d6 <wakeup+0x58>
    acquire(&p->lock);
    800027be:	8526                	mv	a0,s1
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	450080e7          	jalr	1104(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800027c8:	4c9c                	lw	a5,24(s1)
    800027ca:	ff3791e3          	bne	a5,s3,800027ac <wakeup+0x2e>
    800027ce:	749c                	ld	a5,40(s1)
    800027d0:	fd479ee3          	bne	a5,s4,800027ac <wakeup+0x2e>
    800027d4:	bfd1                	j	800027a8 <wakeup+0x2a>
}
    800027d6:	70e2                	ld	ra,56(sp)
    800027d8:	7442                	ld	s0,48(sp)
    800027da:	74a2                	ld	s1,40(sp)
    800027dc:	7902                	ld	s2,32(sp)
    800027de:	69e2                	ld	s3,24(sp)
    800027e0:	6a42                	ld	s4,16(sp)
    800027e2:	6aa2                	ld	s5,8(sp)
    800027e4:	6121                	addi	sp,sp,64
    800027e6:	8082                	ret

00000000800027e8 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800027e8:	7179                	addi	sp,sp,-48
    800027ea:	f406                	sd	ra,40(sp)
    800027ec:	f022                	sd	s0,32(sp)
    800027ee:	ec26                	sd	s1,24(sp)
    800027f0:	e84a                	sd	s2,16(sp)
    800027f2:	e44e                	sd	s3,8(sp)
    800027f4:	1800                	addi	s0,sp,48
    800027f6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800027f8:	0000f497          	auipc	s1,0xf
    800027fc:	57048493          	addi	s1,s1,1392 # 80011d68 <proc>
    80002800:	00015997          	auipc	s3,0x15
    80002804:	36898993          	addi	s3,s3,872 # 80017b68 <tickslock>
    acquire(&p->lock);
    80002808:	8526                	mv	a0,s1
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	406080e7          	jalr	1030(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    80002812:	5c9c                	lw	a5,56(s1)
    80002814:	01278d63          	beq	a5,s2,8000282e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002818:	8526                	mv	a0,s1
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	4aa080e7          	jalr	1194(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002822:	17848493          	addi	s1,s1,376
    80002826:	ff3491e3          	bne	s1,s3,80002808 <kill+0x20>
  }
  return -1;
    8000282a:	557d                	li	a0,-1
    8000282c:	a829                	j	80002846 <kill+0x5e>
      p->killed = 1;
    8000282e:	4785                	li	a5,1
    80002830:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002832:	4c98                	lw	a4,24(s1)
    80002834:	4785                	li	a5,1
    80002836:	00f70f63          	beq	a4,a5,80002854 <kill+0x6c>
      release(&p->lock);
    8000283a:	8526                	mv	a0,s1
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	488080e7          	jalr	1160(ra) # 80000cc4 <release>
      return 0;
    80002844:	4501                	li	a0,0
}
    80002846:	70a2                	ld	ra,40(sp)
    80002848:	7402                	ld	s0,32(sp)
    8000284a:	64e2                	ld	s1,24(sp)
    8000284c:	6942                	ld	s2,16(sp)
    8000284e:	69a2                	ld	s3,8(sp)
    80002850:	6145                	addi	sp,sp,48
    80002852:	8082                	ret
        p->state = RUNNABLE;
    80002854:	4789                	li	a5,2
    80002856:	cc9c                	sw	a5,24(s1)
    80002858:	b7cd                	j	8000283a <kill+0x52>

000000008000285a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000285a:	7179                	addi	sp,sp,-48
    8000285c:	f406                	sd	ra,40(sp)
    8000285e:	f022                	sd	s0,32(sp)
    80002860:	ec26                	sd	s1,24(sp)
    80002862:	e84a                	sd	s2,16(sp)
    80002864:	e44e                	sd	s3,8(sp)
    80002866:	e052                	sd	s4,0(sp)
    80002868:	1800                	addi	s0,sp,48
    8000286a:	84aa                	mv	s1,a0
    8000286c:	892e                	mv	s2,a1
    8000286e:	89b2                	mv	s3,a2
    80002870:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002872:	fffff097          	auipc	ra,0xfffff
    80002876:	472080e7          	jalr	1138(ra) # 80001ce4 <myproc>
  if(user_dst){
    8000287a:	c08d                	beqz	s1,8000289c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000287c:	86d2                	mv	a3,s4
    8000287e:	864e                	mv	a2,s3
    80002880:	85ca                	mv	a1,s2
    80002882:	6928                	ld	a0,80(a0)
    80002884:	fffff097          	auipc	ra,0xfffff
    80002888:	ebe080e7          	jalr	-322(ra) # 80001742 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000288c:	70a2                	ld	ra,40(sp)
    8000288e:	7402                	ld	s0,32(sp)
    80002890:	64e2                	ld	s1,24(sp)
    80002892:	6942                	ld	s2,16(sp)
    80002894:	69a2                	ld	s3,8(sp)
    80002896:	6a02                	ld	s4,0(sp)
    80002898:	6145                	addi	sp,sp,48
    8000289a:	8082                	ret
    memmove((char *)dst, src, len);
    8000289c:	000a061b          	sext.w	a2,s4
    800028a0:	85ce                	mv	a1,s3
    800028a2:	854a                	mv	a0,s2
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	4c8080e7          	jalr	1224(ra) # 80000d6c <memmove>
    return 0;
    800028ac:	8526                	mv	a0,s1
    800028ae:	bff9                	j	8000288c <either_copyout+0x32>

00000000800028b0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800028b0:	7179                	addi	sp,sp,-48
    800028b2:	f406                	sd	ra,40(sp)
    800028b4:	f022                	sd	s0,32(sp)
    800028b6:	ec26                	sd	s1,24(sp)
    800028b8:	e84a                	sd	s2,16(sp)
    800028ba:	e44e                	sd	s3,8(sp)
    800028bc:	e052                	sd	s4,0(sp)
    800028be:	1800                	addi	s0,sp,48
    800028c0:	892a                	mv	s2,a0
    800028c2:	84ae                	mv	s1,a1
    800028c4:	89b2                	mv	s3,a2
    800028c6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800028c8:	fffff097          	auipc	ra,0xfffff
    800028cc:	41c080e7          	jalr	1052(ra) # 80001ce4 <myproc>
  if(user_src){
    800028d0:	c08d                	beqz	s1,800028f2 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800028d2:	86d2                	mv	a3,s4
    800028d4:	864e                	mv	a2,s3
    800028d6:	85ca                	mv	a1,s2
    800028d8:	6928                	ld	a0,80(a0)
    800028da:	fffff097          	auipc	ra,0xfffff
    800028de:	ef4080e7          	jalr	-268(ra) # 800017ce <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800028e2:	70a2                	ld	ra,40(sp)
    800028e4:	7402                	ld	s0,32(sp)
    800028e6:	64e2                	ld	s1,24(sp)
    800028e8:	6942                	ld	s2,16(sp)
    800028ea:	69a2                	ld	s3,8(sp)
    800028ec:	6a02                	ld	s4,0(sp)
    800028ee:	6145                	addi	sp,sp,48
    800028f0:	8082                	ret
    memmove(dst, (char*)src, len);
    800028f2:	000a061b          	sext.w	a2,s4
    800028f6:	85ce                	mv	a1,s3
    800028f8:	854a                	mv	a0,s2
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	472080e7          	jalr	1138(ra) # 80000d6c <memmove>
    return 0;
    80002902:	8526                	mv	a0,s1
    80002904:	bff9                	j	800028e2 <either_copyin+0x32>

0000000080002906 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002906:	715d                	addi	sp,sp,-80
    80002908:	e486                	sd	ra,72(sp)
    8000290a:	e0a2                	sd	s0,64(sp)
    8000290c:	fc26                	sd	s1,56(sp)
    8000290e:	f84a                	sd	s2,48(sp)
    80002910:	f44e                	sd	s3,40(sp)
    80002912:	f052                	sd	s4,32(sp)
    80002914:	ec56                	sd	s5,24(sp)
    80002916:	e85a                	sd	s6,16(sp)
    80002918:	e45e                	sd	s7,8(sp)
    8000291a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000291c:	00005517          	auipc	a0,0x5
    80002920:	79c50513          	addi	a0,a0,1948 # 800080b8 <digits+0x88>
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	c6e080e7          	jalr	-914(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000292c:	0000f497          	auipc	s1,0xf
    80002930:	5a448493          	addi	s1,s1,1444 # 80011ed0 <proc+0x168>
    80002934:	00015917          	auipc	s2,0x15
    80002938:	39c90913          	addi	s2,s2,924 # 80017cd0 <bcache+0x150>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000293c:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000293e:	00006997          	auipc	s3,0x6
    80002942:	a0298993          	addi	s3,s3,-1534 # 80008340 <digits+0x310>
    printf("%d %s %s", p->pid, state, p->name);
    80002946:	00006a97          	auipc	s5,0x6
    8000294a:	a02a8a93          	addi	s5,s5,-1534 # 80008348 <digits+0x318>
    printf("\n");
    8000294e:	00005a17          	auipc	s4,0x5
    80002952:	76aa0a13          	addi	s4,s4,1898 # 800080b8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002956:	00006b97          	auipc	s7,0x6
    8000295a:	a2ab8b93          	addi	s7,s7,-1494 # 80008380 <states.1726>
    8000295e:	a00d                	j	80002980 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002960:	ed06a583          	lw	a1,-304(a3)
    80002964:	8556                	mv	a0,s5
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	c2c080e7          	jalr	-980(ra) # 80000592 <printf>
    printf("\n");
    8000296e:	8552                	mv	a0,s4
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	c22080e7          	jalr	-990(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002978:	17848493          	addi	s1,s1,376
    8000297c:	03248163          	beq	s1,s2,8000299e <procdump+0x98>
    if(p->state == UNUSED)
    80002980:	86a6                	mv	a3,s1
    80002982:	eb04a783          	lw	a5,-336(s1)
    80002986:	dbed                	beqz	a5,80002978 <procdump+0x72>
      state = "???";
    80002988:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000298a:	fcfb6be3          	bltu	s6,a5,80002960 <procdump+0x5a>
    8000298e:	1782                	slli	a5,a5,0x20
    80002990:	9381                	srli	a5,a5,0x20
    80002992:	078e                	slli	a5,a5,0x3
    80002994:	97de                	add	a5,a5,s7
    80002996:	6390                	ld	a2,0(a5)
    80002998:	f661                	bnez	a2,80002960 <procdump+0x5a>
      state = "???";
    8000299a:	864e                	mv	a2,s3
    8000299c:	b7d1                	j	80002960 <procdump+0x5a>
  }
}
    8000299e:	60a6                	ld	ra,72(sp)
    800029a0:	6406                	ld	s0,64(sp)
    800029a2:	74e2                	ld	s1,56(sp)
    800029a4:	7942                	ld	s2,48(sp)
    800029a6:	79a2                	ld	s3,40(sp)
    800029a8:	7a02                	ld	s4,32(sp)
    800029aa:	6ae2                	ld	s5,24(sp)
    800029ac:	6b42                	ld	s6,16(sp)
    800029ae:	6ba2                	ld	s7,8(sp)
    800029b0:	6161                	addi	sp,sp,80
    800029b2:	8082                	ret

00000000800029b4 <myproc_pagetable>:

// ysw
pagetable_t
myproc_pagetable() {
    800029b4:	1141                	addi	sp,sp,-16
    800029b6:	e406                	sd	ra,8(sp)
    800029b8:	e022                	sd	s0,0(sp)
    800029ba:	0800                	addi	s0,sp,16
  return myproc()->kernel_pagetable;
    800029bc:	fffff097          	auipc	ra,0xfffff
    800029c0:	328080e7          	jalr	808(ra) # 80001ce4 <myproc>
}
    800029c4:	7128                	ld	a0,96(a0)
    800029c6:	60a2                	ld	ra,8(sp)
    800029c8:	6402                	ld	s0,0(sp)
    800029ca:	0141                	addi	sp,sp,16
    800029cc:	8082                	ret

00000000800029ce <swtch>:
    800029ce:	00153023          	sd	ra,0(a0)
    800029d2:	00253423          	sd	sp,8(a0)
    800029d6:	e900                	sd	s0,16(a0)
    800029d8:	ed04                	sd	s1,24(a0)
    800029da:	03253023          	sd	s2,32(a0)
    800029de:	03353423          	sd	s3,40(a0)
    800029e2:	03453823          	sd	s4,48(a0)
    800029e6:	03553c23          	sd	s5,56(a0)
    800029ea:	05653023          	sd	s6,64(a0)
    800029ee:	05753423          	sd	s7,72(a0)
    800029f2:	05853823          	sd	s8,80(a0)
    800029f6:	05953c23          	sd	s9,88(a0)
    800029fa:	07a53023          	sd	s10,96(a0)
    800029fe:	07b53423          	sd	s11,104(a0)
    80002a02:	0005b083          	ld	ra,0(a1)
    80002a06:	0085b103          	ld	sp,8(a1)
    80002a0a:	6980                	ld	s0,16(a1)
    80002a0c:	6d84                	ld	s1,24(a1)
    80002a0e:	0205b903          	ld	s2,32(a1)
    80002a12:	0285b983          	ld	s3,40(a1)
    80002a16:	0305ba03          	ld	s4,48(a1)
    80002a1a:	0385ba83          	ld	s5,56(a1)
    80002a1e:	0405bb03          	ld	s6,64(a1)
    80002a22:	0485bb83          	ld	s7,72(a1)
    80002a26:	0505bc03          	ld	s8,80(a1)
    80002a2a:	0585bc83          	ld	s9,88(a1)
    80002a2e:	0605bd03          	ld	s10,96(a1)
    80002a32:	0685bd83          	ld	s11,104(a1)
    80002a36:	8082                	ret

0000000080002a38 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a38:	1141                	addi	sp,sp,-16
    80002a3a:	e406                	sd	ra,8(sp)
    80002a3c:	e022                	sd	s0,0(sp)
    80002a3e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a40:	00006597          	auipc	a1,0x6
    80002a44:	96858593          	addi	a1,a1,-1688 # 800083a8 <states.1726+0x28>
    80002a48:	00015517          	auipc	a0,0x15
    80002a4c:	12050513          	addi	a0,a0,288 # 80017b68 <tickslock>
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	130080e7          	jalr	304(ra) # 80000b80 <initlock>
}
    80002a58:	60a2                	ld	ra,8(sp)
    80002a5a:	6402                	ld	s0,0(sp)
    80002a5c:	0141                	addi	sp,sp,16
    80002a5e:	8082                	ret

0000000080002a60 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a60:	1141                	addi	sp,sp,-16
    80002a62:	e422                	sd	s0,8(sp)
    80002a64:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a66:	00003797          	auipc	a5,0x3
    80002a6a:	4fa78793          	addi	a5,a5,1274 # 80005f60 <kernelvec>
    80002a6e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a72:	6422                	ld	s0,8(sp)
    80002a74:	0141                	addi	sp,sp,16
    80002a76:	8082                	ret

0000000080002a78 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a78:	1141                	addi	sp,sp,-16
    80002a7a:	e406                	sd	ra,8(sp)
    80002a7c:	e022                	sd	s0,0(sp)
    80002a7e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a80:	fffff097          	auipc	ra,0xfffff
    80002a84:	264080e7          	jalr	612(ra) # 80001ce4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a88:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a8c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a8e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a92:	00004617          	auipc	a2,0x4
    80002a96:	56e60613          	addi	a2,a2,1390 # 80007000 <_trampoline>
    80002a9a:	00004697          	auipc	a3,0x4
    80002a9e:	56668693          	addi	a3,a3,1382 # 80007000 <_trampoline>
    80002aa2:	8e91                	sub	a3,a3,a2
    80002aa4:	040007b7          	lui	a5,0x4000
    80002aa8:	17fd                	addi	a5,a5,-1
    80002aaa:	07b2                	slli	a5,a5,0xc
    80002aac:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aae:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ab2:	7538                	ld	a4,104(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ab4:	180026f3          	csrr	a3,satp
    80002ab8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002aba:	7538                	ld	a4,104(a0)
    80002abc:	6134                	ld	a3,64(a0)
    80002abe:	6585                	lui	a1,0x1
    80002ac0:	96ae                	add	a3,a3,a1
    80002ac2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ac4:	7538                	ld	a4,104(a0)
    80002ac6:	00000697          	auipc	a3,0x0
    80002aca:	13868693          	addi	a3,a3,312 # 80002bfe <usertrap>
    80002ace:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002ad0:	7538                	ld	a4,104(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ad2:	8692                	mv	a3,tp
    80002ad4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ad6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ada:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ade:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ae2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ae6:	7538                	ld	a4,104(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ae8:	6f18                	ld	a4,24(a4)
    80002aea:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002aee:	692c                	ld	a1,80(a0)
    80002af0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002af2:	00004717          	auipc	a4,0x4
    80002af6:	59e70713          	addi	a4,a4,1438 # 80007090 <userret>
    80002afa:	8f11                	sub	a4,a4,a2
    80002afc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002afe:	577d                	li	a4,-1
    80002b00:	177e                	slli	a4,a4,0x3f
    80002b02:	8dd9                	or	a1,a1,a4
    80002b04:	02000537          	lui	a0,0x2000
    80002b08:	157d                	addi	a0,a0,-1
    80002b0a:	0536                	slli	a0,a0,0xd
    80002b0c:	9782                	jalr	a5
}
    80002b0e:	60a2                	ld	ra,8(sp)
    80002b10:	6402                	ld	s0,0(sp)
    80002b12:	0141                	addi	sp,sp,16
    80002b14:	8082                	ret

0000000080002b16 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b16:	1101                	addi	sp,sp,-32
    80002b18:	ec06                	sd	ra,24(sp)
    80002b1a:	e822                	sd	s0,16(sp)
    80002b1c:	e426                	sd	s1,8(sp)
    80002b1e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b20:	00015497          	auipc	s1,0x15
    80002b24:	04848493          	addi	s1,s1,72 # 80017b68 <tickslock>
    80002b28:	8526                	mv	a0,s1
    80002b2a:	ffffe097          	auipc	ra,0xffffe
    80002b2e:	0e6080e7          	jalr	230(ra) # 80000c10 <acquire>
  ticks++;
    80002b32:	00006517          	auipc	a0,0x6
    80002b36:	4ee50513          	addi	a0,a0,1262 # 80009020 <ticks>
    80002b3a:	411c                	lw	a5,0(a0)
    80002b3c:	2785                	addiw	a5,a5,1
    80002b3e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b40:	00000097          	auipc	ra,0x0
    80002b44:	c3e080e7          	jalr	-962(ra) # 8000277e <wakeup>
  release(&tickslock);
    80002b48:	8526                	mv	a0,s1
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	17a080e7          	jalr	378(ra) # 80000cc4 <release>
}
    80002b52:	60e2                	ld	ra,24(sp)
    80002b54:	6442                	ld	s0,16(sp)
    80002b56:	64a2                	ld	s1,8(sp)
    80002b58:	6105                	addi	sp,sp,32
    80002b5a:	8082                	ret

0000000080002b5c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b5c:	1101                	addi	sp,sp,-32
    80002b5e:	ec06                	sd	ra,24(sp)
    80002b60:	e822                	sd	s0,16(sp)
    80002b62:	e426                	sd	s1,8(sp)
    80002b64:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b66:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b6a:	00074d63          	bltz	a4,80002b84 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b6e:	57fd                	li	a5,-1
    80002b70:	17fe                	slli	a5,a5,0x3f
    80002b72:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b74:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b76:	06f70363          	beq	a4,a5,80002bdc <devintr+0x80>
  }
}
    80002b7a:	60e2                	ld	ra,24(sp)
    80002b7c:	6442                	ld	s0,16(sp)
    80002b7e:	64a2                	ld	s1,8(sp)
    80002b80:	6105                	addi	sp,sp,32
    80002b82:	8082                	ret
     (scause & 0xff) == 9){
    80002b84:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b88:	46a5                	li	a3,9
    80002b8a:	fed792e3          	bne	a5,a3,80002b6e <devintr+0x12>
    int irq = plic_claim();
    80002b8e:	00003097          	auipc	ra,0x3
    80002b92:	4da080e7          	jalr	1242(ra) # 80006068 <plic_claim>
    80002b96:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b98:	47a9                	li	a5,10
    80002b9a:	02f50763          	beq	a0,a5,80002bc8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b9e:	4785                	li	a5,1
    80002ba0:	02f50963          	beq	a0,a5,80002bd2 <devintr+0x76>
    return 1;
    80002ba4:	4505                	li	a0,1
    } else if(irq){
    80002ba6:	d8f1                	beqz	s1,80002b7a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ba8:	85a6                	mv	a1,s1
    80002baa:	00006517          	auipc	a0,0x6
    80002bae:	80650513          	addi	a0,a0,-2042 # 800083b0 <states.1726+0x30>
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	9e0080e7          	jalr	-1568(ra) # 80000592 <printf>
      plic_complete(irq);
    80002bba:	8526                	mv	a0,s1
    80002bbc:	00003097          	auipc	ra,0x3
    80002bc0:	4d0080e7          	jalr	1232(ra) # 8000608c <plic_complete>
    return 1;
    80002bc4:	4505                	li	a0,1
    80002bc6:	bf55                	j	80002b7a <devintr+0x1e>
      uartintr();
    80002bc8:	ffffe097          	auipc	ra,0xffffe
    80002bcc:	e0c080e7          	jalr	-500(ra) # 800009d4 <uartintr>
    80002bd0:	b7ed                	j	80002bba <devintr+0x5e>
      virtio_disk_intr();
    80002bd2:	00004097          	auipc	ra,0x4
    80002bd6:	954080e7          	jalr	-1708(ra) # 80006526 <virtio_disk_intr>
    80002bda:	b7c5                	j	80002bba <devintr+0x5e>
    if(cpuid() == 0){
    80002bdc:	fffff097          	auipc	ra,0xfffff
    80002be0:	0dc080e7          	jalr	220(ra) # 80001cb8 <cpuid>
    80002be4:	c901                	beqz	a0,80002bf4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002be6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002bea:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002bec:	14479073          	csrw	sip,a5
    return 2;
    80002bf0:	4509                	li	a0,2
    80002bf2:	b761                	j	80002b7a <devintr+0x1e>
      clockintr();
    80002bf4:	00000097          	auipc	ra,0x0
    80002bf8:	f22080e7          	jalr	-222(ra) # 80002b16 <clockintr>
    80002bfc:	b7ed                	j	80002be6 <devintr+0x8a>

0000000080002bfe <usertrap>:
{
    80002bfe:	1101                	addi	sp,sp,-32
    80002c00:	ec06                	sd	ra,24(sp)
    80002c02:	e822                	sd	s0,16(sp)
    80002c04:	e426                	sd	s1,8(sp)
    80002c06:	e04a                	sd	s2,0(sp)
    80002c08:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c0a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c0e:	1007f793          	andi	a5,a5,256
    80002c12:	e3ad                	bnez	a5,80002c74 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c14:	00003797          	auipc	a5,0x3
    80002c18:	34c78793          	addi	a5,a5,844 # 80005f60 <kernelvec>
    80002c1c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c20:	fffff097          	auipc	ra,0xfffff
    80002c24:	0c4080e7          	jalr	196(ra) # 80001ce4 <myproc>
    80002c28:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c2a:	753c                	ld	a5,104(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c2c:	14102773          	csrr	a4,sepc
    80002c30:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c32:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c36:	47a1                	li	a5,8
    80002c38:	04f71c63          	bne	a4,a5,80002c90 <usertrap+0x92>
    if(p->killed)
    80002c3c:	591c                	lw	a5,48(a0)
    80002c3e:	e3b9                	bnez	a5,80002c84 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002c40:	74b8                	ld	a4,104(s1)
    80002c42:	6f1c                	ld	a5,24(a4)
    80002c44:	0791                	addi	a5,a5,4
    80002c46:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c48:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c4c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c50:	10079073          	csrw	sstatus,a5
    syscall();
    80002c54:	00000097          	auipc	ra,0x0
    80002c58:	2fa080e7          	jalr	762(ra) # 80002f4e <syscall>
  if(p->killed)
    80002c5c:	589c                	lw	a5,48(s1)
    80002c5e:	ebc1                	bnez	a5,80002cee <usertrap+0xf0>
  usertrapret();
    80002c60:	00000097          	auipc	ra,0x0
    80002c64:	e18080e7          	jalr	-488(ra) # 80002a78 <usertrapret>
}
    80002c68:	60e2                	ld	ra,24(sp)
    80002c6a:	6442                	ld	s0,16(sp)
    80002c6c:	64a2                	ld	s1,8(sp)
    80002c6e:	6902                	ld	s2,0(sp)
    80002c70:	6105                	addi	sp,sp,32
    80002c72:	8082                	ret
    panic("usertrap: not from user mode");
    80002c74:	00005517          	auipc	a0,0x5
    80002c78:	75c50513          	addi	a0,a0,1884 # 800083d0 <states.1726+0x50>
    80002c7c:	ffffe097          	auipc	ra,0xffffe
    80002c80:	8cc080e7          	jalr	-1844(ra) # 80000548 <panic>
      exit(-1);
    80002c84:	557d                	li	a0,-1
    80002c86:	00000097          	auipc	ra,0x0
    80002c8a:	82c080e7          	jalr	-2004(ra) # 800024b2 <exit>
    80002c8e:	bf4d                	j	80002c40 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002c90:	00000097          	auipc	ra,0x0
    80002c94:	ecc080e7          	jalr	-308(ra) # 80002b5c <devintr>
    80002c98:	892a                	mv	s2,a0
    80002c9a:	c501                	beqz	a0,80002ca2 <usertrap+0xa4>
  if(p->killed)
    80002c9c:	589c                	lw	a5,48(s1)
    80002c9e:	c3a1                	beqz	a5,80002cde <usertrap+0xe0>
    80002ca0:	a815                	j	80002cd4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ca2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ca6:	5c90                	lw	a2,56(s1)
    80002ca8:	00005517          	auipc	a0,0x5
    80002cac:	74850513          	addi	a0,a0,1864 # 800083f0 <states.1726+0x70>
    80002cb0:	ffffe097          	auipc	ra,0xffffe
    80002cb4:	8e2080e7          	jalr	-1822(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cb8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cbc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cc0:	00005517          	auipc	a0,0x5
    80002cc4:	76050513          	addi	a0,a0,1888 # 80008420 <states.1726+0xa0>
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	8ca080e7          	jalr	-1846(ra) # 80000592 <printf>
    p->killed = 1;
    80002cd0:	4785                	li	a5,1
    80002cd2:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002cd4:	557d                	li	a0,-1
    80002cd6:	fffff097          	auipc	ra,0xfffff
    80002cda:	7dc080e7          	jalr	2012(ra) # 800024b2 <exit>
  if(which_dev == 2)
    80002cde:	4789                	li	a5,2
    80002ce0:	f8f910e3          	bne	s2,a5,80002c60 <usertrap+0x62>
    yield();
    80002ce4:	00000097          	auipc	ra,0x0
    80002ce8:	8d8080e7          	jalr	-1832(ra) # 800025bc <yield>
    80002cec:	bf95                	j	80002c60 <usertrap+0x62>
  int which_dev = 0;
    80002cee:	4901                	li	s2,0
    80002cf0:	b7d5                	j	80002cd4 <usertrap+0xd6>

0000000080002cf2 <kerneltrap>:
{
    80002cf2:	7179                	addi	sp,sp,-48
    80002cf4:	f406                	sd	ra,40(sp)
    80002cf6:	f022                	sd	s0,32(sp)
    80002cf8:	ec26                	sd	s1,24(sp)
    80002cfa:	e84a                	sd	s2,16(sp)
    80002cfc:	e44e                	sd	s3,8(sp)
    80002cfe:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d00:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d04:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d08:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d0c:	1004f793          	andi	a5,s1,256
    80002d10:	cb85                	beqz	a5,80002d40 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d12:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d16:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d18:	ef85                	bnez	a5,80002d50 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d1a:	00000097          	auipc	ra,0x0
    80002d1e:	e42080e7          	jalr	-446(ra) # 80002b5c <devintr>
    80002d22:	cd1d                	beqz	a0,80002d60 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d24:	4789                	li	a5,2
    80002d26:	08f50763          	beq	a0,a5,80002db4 <kerneltrap+0xc2>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d2a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d2e:	10049073          	csrw	sstatus,s1
}
    80002d32:	70a2                	ld	ra,40(sp)
    80002d34:	7402                	ld	s0,32(sp)
    80002d36:	64e2                	ld	s1,24(sp)
    80002d38:	6942                	ld	s2,16(sp)
    80002d3a:	69a2                	ld	s3,8(sp)
    80002d3c:	6145                	addi	sp,sp,48
    80002d3e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d40:	00005517          	auipc	a0,0x5
    80002d44:	70050513          	addi	a0,a0,1792 # 80008440 <states.1726+0xc0>
    80002d48:	ffffe097          	auipc	ra,0xffffe
    80002d4c:	800080e7          	jalr	-2048(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002d50:	00005517          	auipc	a0,0x5
    80002d54:	71850513          	addi	a0,a0,1816 # 80008468 <states.1726+0xe8>
    80002d58:	ffffd097          	auipc	ra,0xffffd
    80002d5c:	7f0080e7          	jalr	2032(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002d60:	85ce                	mv	a1,s3
    80002d62:	00005517          	auipc	a0,0x5
    80002d66:	72650513          	addi	a0,a0,1830 # 80008488 <states.1726+0x108>
    80002d6a:	ffffe097          	auipc	ra,0xffffe
    80002d6e:	828080e7          	jalr	-2008(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d72:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d76:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d7a:	00005517          	auipc	a0,0x5
    80002d7e:	71e50513          	addi	a0,a0,1822 # 80008498 <states.1726+0x118>
    80002d82:	ffffe097          	auipc	ra,0xffffe
    80002d86:	810080e7          	jalr	-2032(ra) # 80000592 <printf>
    printf("myproc %p\n", myproc());
    80002d8a:	fffff097          	auipc	ra,0xfffff
    80002d8e:	f5a080e7          	jalr	-166(ra) # 80001ce4 <myproc>
    80002d92:	85aa                	mv	a1,a0
    80002d94:	00005517          	auipc	a0,0x5
    80002d98:	71c50513          	addi	a0,a0,1820 # 800084b0 <states.1726+0x130>
    80002d9c:	ffffd097          	auipc	ra,0xffffd
    80002da0:	7f6080e7          	jalr	2038(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002da4:	00005517          	auipc	a0,0x5
    80002da8:	71c50513          	addi	a0,a0,1820 # 800084c0 <states.1726+0x140>
    80002dac:	ffffd097          	auipc	ra,0xffffd
    80002db0:	79c080e7          	jalr	1948(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	f30080e7          	jalr	-208(ra) # 80001ce4 <myproc>
    80002dbc:	d53d                	beqz	a0,80002d2a <kerneltrap+0x38>
    80002dbe:	fffff097          	auipc	ra,0xfffff
    80002dc2:	f26080e7          	jalr	-218(ra) # 80001ce4 <myproc>
    80002dc6:	4d18                	lw	a4,24(a0)
    80002dc8:	478d                	li	a5,3
    80002dca:	f6f710e3          	bne	a4,a5,80002d2a <kerneltrap+0x38>
    yield();
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	7ee080e7          	jalr	2030(ra) # 800025bc <yield>
    80002dd6:	bf91                	j	80002d2a <kerneltrap+0x38>

0000000080002dd8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002dd8:	1101                	addi	sp,sp,-32
    80002dda:	ec06                	sd	ra,24(sp)
    80002ddc:	e822                	sd	s0,16(sp)
    80002dde:	e426                	sd	s1,8(sp)
    80002de0:	1000                	addi	s0,sp,32
    80002de2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002de4:	fffff097          	auipc	ra,0xfffff
    80002de8:	f00080e7          	jalr	-256(ra) # 80001ce4 <myproc>
  switch (n) {
    80002dec:	4795                	li	a5,5
    80002dee:	0497e163          	bltu	a5,s1,80002e30 <argraw+0x58>
    80002df2:	048a                	slli	s1,s1,0x2
    80002df4:	00005717          	auipc	a4,0x5
    80002df8:	70470713          	addi	a4,a4,1796 # 800084f8 <states.1726+0x178>
    80002dfc:	94ba                	add	s1,s1,a4
    80002dfe:	409c                	lw	a5,0(s1)
    80002e00:	97ba                	add	a5,a5,a4
    80002e02:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e04:	753c                	ld	a5,104(a0)
    80002e06:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e08:	60e2                	ld	ra,24(sp)
    80002e0a:	6442                	ld	s0,16(sp)
    80002e0c:	64a2                	ld	s1,8(sp)
    80002e0e:	6105                	addi	sp,sp,32
    80002e10:	8082                	ret
    return p->trapframe->a1;
    80002e12:	753c                	ld	a5,104(a0)
    80002e14:	7fa8                	ld	a0,120(a5)
    80002e16:	bfcd                	j	80002e08 <argraw+0x30>
    return p->trapframe->a2;
    80002e18:	753c                	ld	a5,104(a0)
    80002e1a:	63c8                	ld	a0,128(a5)
    80002e1c:	b7f5                	j	80002e08 <argraw+0x30>
    return p->trapframe->a3;
    80002e1e:	753c                	ld	a5,104(a0)
    80002e20:	67c8                	ld	a0,136(a5)
    80002e22:	b7dd                	j	80002e08 <argraw+0x30>
    return p->trapframe->a4;
    80002e24:	753c                	ld	a5,104(a0)
    80002e26:	6bc8                	ld	a0,144(a5)
    80002e28:	b7c5                	j	80002e08 <argraw+0x30>
    return p->trapframe->a5;
    80002e2a:	753c                	ld	a5,104(a0)
    80002e2c:	6fc8                	ld	a0,152(a5)
    80002e2e:	bfe9                	j	80002e08 <argraw+0x30>
  panic("argraw");
    80002e30:	00005517          	auipc	a0,0x5
    80002e34:	6a050513          	addi	a0,a0,1696 # 800084d0 <states.1726+0x150>
    80002e38:	ffffd097          	auipc	ra,0xffffd
    80002e3c:	710080e7          	jalr	1808(ra) # 80000548 <panic>

0000000080002e40 <fetchaddr>:
{
    80002e40:	1101                	addi	sp,sp,-32
    80002e42:	ec06                	sd	ra,24(sp)
    80002e44:	e822                	sd	s0,16(sp)
    80002e46:	e426                	sd	s1,8(sp)
    80002e48:	e04a                	sd	s2,0(sp)
    80002e4a:	1000                	addi	s0,sp,32
    80002e4c:	84aa                	mv	s1,a0
    80002e4e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	e94080e7          	jalr	-364(ra) # 80001ce4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002e58:	653c                	ld	a5,72(a0)
    80002e5a:	02f4f863          	bgeu	s1,a5,80002e8a <fetchaddr+0x4a>
    80002e5e:	00848713          	addi	a4,s1,8
    80002e62:	02e7e663          	bltu	a5,a4,80002e8e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e66:	46a1                	li	a3,8
    80002e68:	8626                	mv	a2,s1
    80002e6a:	85ca                	mv	a1,s2
    80002e6c:	6928                	ld	a0,80(a0)
    80002e6e:	fffff097          	auipc	ra,0xfffff
    80002e72:	960080e7          	jalr	-1696(ra) # 800017ce <copyin>
    80002e76:	00a03533          	snez	a0,a0
    80002e7a:	40a00533          	neg	a0,a0
}
    80002e7e:	60e2                	ld	ra,24(sp)
    80002e80:	6442                	ld	s0,16(sp)
    80002e82:	64a2                	ld	s1,8(sp)
    80002e84:	6902                	ld	s2,0(sp)
    80002e86:	6105                	addi	sp,sp,32
    80002e88:	8082                	ret
    return -1;
    80002e8a:	557d                	li	a0,-1
    80002e8c:	bfcd                	j	80002e7e <fetchaddr+0x3e>
    80002e8e:	557d                	li	a0,-1
    80002e90:	b7fd                	j	80002e7e <fetchaddr+0x3e>

0000000080002e92 <fetchstr>:
{
    80002e92:	7179                	addi	sp,sp,-48
    80002e94:	f406                	sd	ra,40(sp)
    80002e96:	f022                	sd	s0,32(sp)
    80002e98:	ec26                	sd	s1,24(sp)
    80002e9a:	e84a                	sd	s2,16(sp)
    80002e9c:	e44e                	sd	s3,8(sp)
    80002e9e:	1800                	addi	s0,sp,48
    80002ea0:	892a                	mv	s2,a0
    80002ea2:	84ae                	mv	s1,a1
    80002ea4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ea6:	fffff097          	auipc	ra,0xfffff
    80002eaa:	e3e080e7          	jalr	-450(ra) # 80001ce4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002eae:	86ce                	mv	a3,s3
    80002eb0:	864a                	mv	a2,s2
    80002eb2:	85a6                	mv	a1,s1
    80002eb4:	6928                	ld	a0,80(a0)
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	9a4080e7          	jalr	-1628(ra) # 8000185a <copyinstr>
  if(err < 0)
    80002ebe:	00054763          	bltz	a0,80002ecc <fetchstr+0x3a>
  return strlen(buf);
    80002ec2:	8526                	mv	a0,s1
    80002ec4:	ffffe097          	auipc	ra,0xffffe
    80002ec8:	fd0080e7          	jalr	-48(ra) # 80000e94 <strlen>
}
    80002ecc:	70a2                	ld	ra,40(sp)
    80002ece:	7402                	ld	s0,32(sp)
    80002ed0:	64e2                	ld	s1,24(sp)
    80002ed2:	6942                	ld	s2,16(sp)
    80002ed4:	69a2                	ld	s3,8(sp)
    80002ed6:	6145                	addi	sp,sp,48
    80002ed8:	8082                	ret

0000000080002eda <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002eda:	1101                	addi	sp,sp,-32
    80002edc:	ec06                	sd	ra,24(sp)
    80002ede:	e822                	sd	s0,16(sp)
    80002ee0:	e426                	sd	s1,8(sp)
    80002ee2:	1000                	addi	s0,sp,32
    80002ee4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ee6:	00000097          	auipc	ra,0x0
    80002eea:	ef2080e7          	jalr	-270(ra) # 80002dd8 <argraw>
    80002eee:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ef0:	4501                	li	a0,0
    80002ef2:	60e2                	ld	ra,24(sp)
    80002ef4:	6442                	ld	s0,16(sp)
    80002ef6:	64a2                	ld	s1,8(sp)
    80002ef8:	6105                	addi	sp,sp,32
    80002efa:	8082                	ret

0000000080002efc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002efc:	1101                	addi	sp,sp,-32
    80002efe:	ec06                	sd	ra,24(sp)
    80002f00:	e822                	sd	s0,16(sp)
    80002f02:	e426                	sd	s1,8(sp)
    80002f04:	1000                	addi	s0,sp,32
    80002f06:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f08:	00000097          	auipc	ra,0x0
    80002f0c:	ed0080e7          	jalr	-304(ra) # 80002dd8 <argraw>
    80002f10:	e088                	sd	a0,0(s1)
  return 0;
}
    80002f12:	4501                	li	a0,0
    80002f14:	60e2                	ld	ra,24(sp)
    80002f16:	6442                	ld	s0,16(sp)
    80002f18:	64a2                	ld	s1,8(sp)
    80002f1a:	6105                	addi	sp,sp,32
    80002f1c:	8082                	ret

0000000080002f1e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f1e:	1101                	addi	sp,sp,-32
    80002f20:	ec06                	sd	ra,24(sp)
    80002f22:	e822                	sd	s0,16(sp)
    80002f24:	e426                	sd	s1,8(sp)
    80002f26:	e04a                	sd	s2,0(sp)
    80002f28:	1000                	addi	s0,sp,32
    80002f2a:	84ae                	mv	s1,a1
    80002f2c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002f2e:	00000097          	auipc	ra,0x0
    80002f32:	eaa080e7          	jalr	-342(ra) # 80002dd8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002f36:	864a                	mv	a2,s2
    80002f38:	85a6                	mv	a1,s1
    80002f3a:	00000097          	auipc	ra,0x0
    80002f3e:	f58080e7          	jalr	-168(ra) # 80002e92 <fetchstr>
}
    80002f42:	60e2                	ld	ra,24(sp)
    80002f44:	6442                	ld	s0,16(sp)
    80002f46:	64a2                	ld	s1,8(sp)
    80002f48:	6902                	ld	s2,0(sp)
    80002f4a:	6105                	addi	sp,sp,32
    80002f4c:	8082                	ret

0000000080002f4e <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002f4e:	1101                	addi	sp,sp,-32
    80002f50:	ec06                	sd	ra,24(sp)
    80002f52:	e822                	sd	s0,16(sp)
    80002f54:	e426                	sd	s1,8(sp)
    80002f56:	e04a                	sd	s2,0(sp)
    80002f58:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002f5a:	fffff097          	auipc	ra,0xfffff
    80002f5e:	d8a080e7          	jalr	-630(ra) # 80001ce4 <myproc>
    80002f62:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002f64:	06853903          	ld	s2,104(a0)
    80002f68:	0a893783          	ld	a5,168(s2)
    80002f6c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f70:	37fd                	addiw	a5,a5,-1
    80002f72:	4751                	li	a4,20
    80002f74:	00f76f63          	bltu	a4,a5,80002f92 <syscall+0x44>
    80002f78:	00369713          	slli	a4,a3,0x3
    80002f7c:	00005797          	auipc	a5,0x5
    80002f80:	59478793          	addi	a5,a5,1428 # 80008510 <syscalls>
    80002f84:	97ba                	add	a5,a5,a4
    80002f86:	639c                	ld	a5,0(a5)
    80002f88:	c789                	beqz	a5,80002f92 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002f8a:	9782                	jalr	a5
    80002f8c:	06a93823          	sd	a0,112(s2)
    80002f90:	a839                	j	80002fae <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f92:	16848613          	addi	a2,s1,360
    80002f96:	5c8c                	lw	a1,56(s1)
    80002f98:	00005517          	auipc	a0,0x5
    80002f9c:	54050513          	addi	a0,a0,1344 # 800084d8 <states.1726+0x158>
    80002fa0:	ffffd097          	auipc	ra,0xffffd
    80002fa4:	5f2080e7          	jalr	1522(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002fa8:	74bc                	ld	a5,104(s1)
    80002faa:	577d                	li	a4,-1
    80002fac:	fbb8                	sd	a4,112(a5)
  }
}
    80002fae:	60e2                	ld	ra,24(sp)
    80002fb0:	6442                	ld	s0,16(sp)
    80002fb2:	64a2                	ld	s1,8(sp)
    80002fb4:	6902                	ld	s2,0(sp)
    80002fb6:	6105                	addi	sp,sp,32
    80002fb8:	8082                	ret

0000000080002fba <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002fba:	1101                	addi	sp,sp,-32
    80002fbc:	ec06                	sd	ra,24(sp)
    80002fbe:	e822                	sd	s0,16(sp)
    80002fc0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002fc2:	fec40593          	addi	a1,s0,-20
    80002fc6:	4501                	li	a0,0
    80002fc8:	00000097          	auipc	ra,0x0
    80002fcc:	f12080e7          	jalr	-238(ra) # 80002eda <argint>
    return -1;
    80002fd0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fd2:	00054963          	bltz	a0,80002fe4 <sys_exit+0x2a>
  exit(n);
    80002fd6:	fec42503          	lw	a0,-20(s0)
    80002fda:	fffff097          	auipc	ra,0xfffff
    80002fde:	4d8080e7          	jalr	1240(ra) # 800024b2 <exit>
  return 0;  // not reached
    80002fe2:	4781                	li	a5,0
}
    80002fe4:	853e                	mv	a0,a5
    80002fe6:	60e2                	ld	ra,24(sp)
    80002fe8:	6442                	ld	s0,16(sp)
    80002fea:	6105                	addi	sp,sp,32
    80002fec:	8082                	ret

0000000080002fee <sys_getpid>:

uint64
sys_getpid(void)
{
    80002fee:	1141                	addi	sp,sp,-16
    80002ff0:	e406                	sd	ra,8(sp)
    80002ff2:	e022                	sd	s0,0(sp)
    80002ff4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ff6:	fffff097          	auipc	ra,0xfffff
    80002ffa:	cee080e7          	jalr	-786(ra) # 80001ce4 <myproc>
}
    80002ffe:	5d08                	lw	a0,56(a0)
    80003000:	60a2                	ld	ra,8(sp)
    80003002:	6402                	ld	s0,0(sp)
    80003004:	0141                	addi	sp,sp,16
    80003006:	8082                	ret

0000000080003008 <sys_fork>:

uint64
sys_fork(void)
{
    80003008:	1141                	addi	sp,sp,-16
    8000300a:	e406                	sd	ra,8(sp)
    8000300c:	e022                	sd	s0,0(sp)
    8000300e:	0800                	addi	s0,sp,16
  return fork();
    80003010:	fffff097          	auipc	ra,0xfffff
    80003014:	178080e7          	jalr	376(ra) # 80002188 <fork>
}
    80003018:	60a2                	ld	ra,8(sp)
    8000301a:	6402                	ld	s0,0(sp)
    8000301c:	0141                	addi	sp,sp,16
    8000301e:	8082                	ret

0000000080003020 <sys_wait>:

uint64
sys_wait(void)
{
    80003020:	1101                	addi	sp,sp,-32
    80003022:	ec06                	sd	ra,24(sp)
    80003024:	e822                	sd	s0,16(sp)
    80003026:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003028:	fe840593          	addi	a1,s0,-24
    8000302c:	4501                	li	a0,0
    8000302e:	00000097          	auipc	ra,0x0
    80003032:	ece080e7          	jalr	-306(ra) # 80002efc <argaddr>
    80003036:	87aa                	mv	a5,a0
    return -1;
    80003038:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000303a:	0007c863          	bltz	a5,8000304a <sys_wait+0x2a>
  return wait(p);
    8000303e:	fe843503          	ld	a0,-24(s0)
    80003042:	fffff097          	auipc	ra,0xfffff
    80003046:	634080e7          	jalr	1588(ra) # 80002676 <wait>
}
    8000304a:	60e2                	ld	ra,24(sp)
    8000304c:	6442                	ld	s0,16(sp)
    8000304e:	6105                	addi	sp,sp,32
    80003050:	8082                	ret

0000000080003052 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003052:	7179                	addi	sp,sp,-48
    80003054:	f406                	sd	ra,40(sp)
    80003056:	f022                	sd	s0,32(sp)
    80003058:	ec26                	sd	s1,24(sp)
    8000305a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000305c:	fdc40593          	addi	a1,s0,-36
    80003060:	4501                	li	a0,0
    80003062:	00000097          	auipc	ra,0x0
    80003066:	e78080e7          	jalr	-392(ra) # 80002eda <argint>
    8000306a:	87aa                	mv	a5,a0
    return -1;
    8000306c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000306e:	0207c063          	bltz	a5,8000308e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003072:	fffff097          	auipc	ra,0xfffff
    80003076:	c72080e7          	jalr	-910(ra) # 80001ce4 <myproc>
    8000307a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000307c:	fdc42503          	lw	a0,-36(s0)
    80003080:	fffff097          	auipc	ra,0xfffff
    80003084:	094080e7          	jalr	148(ra) # 80002114 <growproc>
    80003088:	00054863          	bltz	a0,80003098 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000308c:	8526                	mv	a0,s1
}
    8000308e:	70a2                	ld	ra,40(sp)
    80003090:	7402                	ld	s0,32(sp)
    80003092:	64e2                	ld	s1,24(sp)
    80003094:	6145                	addi	sp,sp,48
    80003096:	8082                	ret
    return -1;
    80003098:	557d                	li	a0,-1
    8000309a:	bfd5                	j	8000308e <sys_sbrk+0x3c>

000000008000309c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000309c:	7139                	addi	sp,sp,-64
    8000309e:	fc06                	sd	ra,56(sp)
    800030a0:	f822                	sd	s0,48(sp)
    800030a2:	f426                	sd	s1,40(sp)
    800030a4:	f04a                	sd	s2,32(sp)
    800030a6:	ec4e                	sd	s3,24(sp)
    800030a8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800030aa:	fcc40593          	addi	a1,s0,-52
    800030ae:	4501                	li	a0,0
    800030b0:	00000097          	auipc	ra,0x0
    800030b4:	e2a080e7          	jalr	-470(ra) # 80002eda <argint>
    return -1;
    800030b8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800030ba:	06054563          	bltz	a0,80003124 <sys_sleep+0x88>
  acquire(&tickslock);
    800030be:	00015517          	auipc	a0,0x15
    800030c2:	aaa50513          	addi	a0,a0,-1366 # 80017b68 <tickslock>
    800030c6:	ffffe097          	auipc	ra,0xffffe
    800030ca:	b4a080e7          	jalr	-1206(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    800030ce:	00006917          	auipc	s2,0x6
    800030d2:	f5292903          	lw	s2,-174(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    800030d6:	fcc42783          	lw	a5,-52(s0)
    800030da:	cf85                	beqz	a5,80003112 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800030dc:	00015997          	auipc	s3,0x15
    800030e0:	a8c98993          	addi	s3,s3,-1396 # 80017b68 <tickslock>
    800030e4:	00006497          	auipc	s1,0x6
    800030e8:	f3c48493          	addi	s1,s1,-196 # 80009020 <ticks>
    if(myproc()->killed){
    800030ec:	fffff097          	auipc	ra,0xfffff
    800030f0:	bf8080e7          	jalr	-1032(ra) # 80001ce4 <myproc>
    800030f4:	591c                	lw	a5,48(a0)
    800030f6:	ef9d                	bnez	a5,80003134 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800030f8:	85ce                	mv	a1,s3
    800030fa:	8526                	mv	a0,s1
    800030fc:	fffff097          	auipc	ra,0xfffff
    80003100:	4fc080e7          	jalr	1276(ra) # 800025f8 <sleep>
  while(ticks - ticks0 < n){
    80003104:	409c                	lw	a5,0(s1)
    80003106:	412787bb          	subw	a5,a5,s2
    8000310a:	fcc42703          	lw	a4,-52(s0)
    8000310e:	fce7efe3          	bltu	a5,a4,800030ec <sys_sleep+0x50>
  }
  release(&tickslock);
    80003112:	00015517          	auipc	a0,0x15
    80003116:	a5650513          	addi	a0,a0,-1450 # 80017b68 <tickslock>
    8000311a:	ffffe097          	auipc	ra,0xffffe
    8000311e:	baa080e7          	jalr	-1110(ra) # 80000cc4 <release>
  return 0;
    80003122:	4781                	li	a5,0
}
    80003124:	853e                	mv	a0,a5
    80003126:	70e2                	ld	ra,56(sp)
    80003128:	7442                	ld	s0,48(sp)
    8000312a:	74a2                	ld	s1,40(sp)
    8000312c:	7902                	ld	s2,32(sp)
    8000312e:	69e2                	ld	s3,24(sp)
    80003130:	6121                	addi	sp,sp,64
    80003132:	8082                	ret
      release(&tickslock);
    80003134:	00015517          	auipc	a0,0x15
    80003138:	a3450513          	addi	a0,a0,-1484 # 80017b68 <tickslock>
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	b88080e7          	jalr	-1144(ra) # 80000cc4 <release>
      return -1;
    80003144:	57fd                	li	a5,-1
    80003146:	bff9                	j	80003124 <sys_sleep+0x88>

0000000080003148 <sys_kill>:

uint64
sys_kill(void)
{
    80003148:	1101                	addi	sp,sp,-32
    8000314a:	ec06                	sd	ra,24(sp)
    8000314c:	e822                	sd	s0,16(sp)
    8000314e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003150:	fec40593          	addi	a1,s0,-20
    80003154:	4501                	li	a0,0
    80003156:	00000097          	auipc	ra,0x0
    8000315a:	d84080e7          	jalr	-636(ra) # 80002eda <argint>
    8000315e:	87aa                	mv	a5,a0
    return -1;
    80003160:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003162:	0007c863          	bltz	a5,80003172 <sys_kill+0x2a>
  return kill(pid);
    80003166:	fec42503          	lw	a0,-20(s0)
    8000316a:	fffff097          	auipc	ra,0xfffff
    8000316e:	67e080e7          	jalr	1662(ra) # 800027e8 <kill>
}
    80003172:	60e2                	ld	ra,24(sp)
    80003174:	6442                	ld	s0,16(sp)
    80003176:	6105                	addi	sp,sp,32
    80003178:	8082                	ret

000000008000317a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000317a:	1101                	addi	sp,sp,-32
    8000317c:	ec06                	sd	ra,24(sp)
    8000317e:	e822                	sd	s0,16(sp)
    80003180:	e426                	sd	s1,8(sp)
    80003182:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003184:	00015517          	auipc	a0,0x15
    80003188:	9e450513          	addi	a0,a0,-1564 # 80017b68 <tickslock>
    8000318c:	ffffe097          	auipc	ra,0xffffe
    80003190:	a84080e7          	jalr	-1404(ra) # 80000c10 <acquire>
  xticks = ticks;
    80003194:	00006497          	auipc	s1,0x6
    80003198:	e8c4a483          	lw	s1,-372(s1) # 80009020 <ticks>
  release(&tickslock);
    8000319c:	00015517          	auipc	a0,0x15
    800031a0:	9cc50513          	addi	a0,a0,-1588 # 80017b68 <tickslock>
    800031a4:	ffffe097          	auipc	ra,0xffffe
    800031a8:	b20080e7          	jalr	-1248(ra) # 80000cc4 <release>
  return xticks;
}
    800031ac:	02049513          	slli	a0,s1,0x20
    800031b0:	9101                	srli	a0,a0,0x20
    800031b2:	60e2                	ld	ra,24(sp)
    800031b4:	6442                	ld	s0,16(sp)
    800031b6:	64a2                	ld	s1,8(sp)
    800031b8:	6105                	addi	sp,sp,32
    800031ba:	8082                	ret

00000000800031bc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800031bc:	7179                	addi	sp,sp,-48
    800031be:	f406                	sd	ra,40(sp)
    800031c0:	f022                	sd	s0,32(sp)
    800031c2:	ec26                	sd	s1,24(sp)
    800031c4:	e84a                	sd	s2,16(sp)
    800031c6:	e44e                	sd	s3,8(sp)
    800031c8:	e052                	sd	s4,0(sp)
    800031ca:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031cc:	00005597          	auipc	a1,0x5
    800031d0:	3f458593          	addi	a1,a1,1012 # 800085c0 <syscalls+0xb0>
    800031d4:	00015517          	auipc	a0,0x15
    800031d8:	9ac50513          	addi	a0,a0,-1620 # 80017b80 <bcache>
    800031dc:	ffffe097          	auipc	ra,0xffffe
    800031e0:	9a4080e7          	jalr	-1628(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031e4:	0001d797          	auipc	a5,0x1d
    800031e8:	99c78793          	addi	a5,a5,-1636 # 8001fb80 <bcache+0x8000>
    800031ec:	0001d717          	auipc	a4,0x1d
    800031f0:	bfc70713          	addi	a4,a4,-1028 # 8001fde8 <bcache+0x8268>
    800031f4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031f8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031fc:	00015497          	auipc	s1,0x15
    80003200:	99c48493          	addi	s1,s1,-1636 # 80017b98 <bcache+0x18>
    b->next = bcache.head.next;
    80003204:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003206:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003208:	00005a17          	auipc	s4,0x5
    8000320c:	3c0a0a13          	addi	s4,s4,960 # 800085c8 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003210:	2b893783          	ld	a5,696(s2)
    80003214:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003216:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000321a:	85d2                	mv	a1,s4
    8000321c:	01048513          	addi	a0,s1,16
    80003220:	00001097          	auipc	ra,0x1
    80003224:	4ac080e7          	jalr	1196(ra) # 800046cc <initsleeplock>
    bcache.head.next->prev = b;
    80003228:	2b893783          	ld	a5,696(s2)
    8000322c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000322e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003232:	45848493          	addi	s1,s1,1112
    80003236:	fd349de3          	bne	s1,s3,80003210 <binit+0x54>
  }
}
    8000323a:	70a2                	ld	ra,40(sp)
    8000323c:	7402                	ld	s0,32(sp)
    8000323e:	64e2                	ld	s1,24(sp)
    80003240:	6942                	ld	s2,16(sp)
    80003242:	69a2                	ld	s3,8(sp)
    80003244:	6a02                	ld	s4,0(sp)
    80003246:	6145                	addi	sp,sp,48
    80003248:	8082                	ret

000000008000324a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000324a:	7179                	addi	sp,sp,-48
    8000324c:	f406                	sd	ra,40(sp)
    8000324e:	f022                	sd	s0,32(sp)
    80003250:	ec26                	sd	s1,24(sp)
    80003252:	e84a                	sd	s2,16(sp)
    80003254:	e44e                	sd	s3,8(sp)
    80003256:	1800                	addi	s0,sp,48
    80003258:	89aa                	mv	s3,a0
    8000325a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000325c:	00015517          	auipc	a0,0x15
    80003260:	92450513          	addi	a0,a0,-1756 # 80017b80 <bcache>
    80003264:	ffffe097          	auipc	ra,0xffffe
    80003268:	9ac080e7          	jalr	-1620(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000326c:	0001d497          	auipc	s1,0x1d
    80003270:	bcc4b483          	ld	s1,-1076(s1) # 8001fe38 <bcache+0x82b8>
    80003274:	0001d797          	auipc	a5,0x1d
    80003278:	b7478793          	addi	a5,a5,-1164 # 8001fde8 <bcache+0x8268>
    8000327c:	02f48f63          	beq	s1,a5,800032ba <bread+0x70>
    80003280:	873e                	mv	a4,a5
    80003282:	a021                	j	8000328a <bread+0x40>
    80003284:	68a4                	ld	s1,80(s1)
    80003286:	02e48a63          	beq	s1,a4,800032ba <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000328a:	449c                	lw	a5,8(s1)
    8000328c:	ff379ce3          	bne	a5,s3,80003284 <bread+0x3a>
    80003290:	44dc                	lw	a5,12(s1)
    80003292:	ff2799e3          	bne	a5,s2,80003284 <bread+0x3a>
      b->refcnt++;
    80003296:	40bc                	lw	a5,64(s1)
    80003298:	2785                	addiw	a5,a5,1
    8000329a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000329c:	00015517          	auipc	a0,0x15
    800032a0:	8e450513          	addi	a0,a0,-1820 # 80017b80 <bcache>
    800032a4:	ffffe097          	auipc	ra,0xffffe
    800032a8:	a20080e7          	jalr	-1504(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    800032ac:	01048513          	addi	a0,s1,16
    800032b0:	00001097          	auipc	ra,0x1
    800032b4:	456080e7          	jalr	1110(ra) # 80004706 <acquiresleep>
      return b;
    800032b8:	a8b9                	j	80003316 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032ba:	0001d497          	auipc	s1,0x1d
    800032be:	b764b483          	ld	s1,-1162(s1) # 8001fe30 <bcache+0x82b0>
    800032c2:	0001d797          	auipc	a5,0x1d
    800032c6:	b2678793          	addi	a5,a5,-1242 # 8001fde8 <bcache+0x8268>
    800032ca:	00f48863          	beq	s1,a5,800032da <bread+0x90>
    800032ce:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032d0:	40bc                	lw	a5,64(s1)
    800032d2:	cf81                	beqz	a5,800032ea <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032d4:	64a4                	ld	s1,72(s1)
    800032d6:	fee49de3          	bne	s1,a4,800032d0 <bread+0x86>
  panic("bget: no buffers");
    800032da:	00005517          	auipc	a0,0x5
    800032de:	2f650513          	addi	a0,a0,758 # 800085d0 <syscalls+0xc0>
    800032e2:	ffffd097          	auipc	ra,0xffffd
    800032e6:	266080e7          	jalr	614(ra) # 80000548 <panic>
      b->dev = dev;
    800032ea:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800032ee:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800032f2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032f6:	4785                	li	a5,1
    800032f8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032fa:	00015517          	auipc	a0,0x15
    800032fe:	88650513          	addi	a0,a0,-1914 # 80017b80 <bcache>
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	9c2080e7          	jalr	-1598(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    8000330a:	01048513          	addi	a0,s1,16
    8000330e:	00001097          	auipc	ra,0x1
    80003312:	3f8080e7          	jalr	1016(ra) # 80004706 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003316:	409c                	lw	a5,0(s1)
    80003318:	cb89                	beqz	a5,8000332a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000331a:	8526                	mv	a0,s1
    8000331c:	70a2                	ld	ra,40(sp)
    8000331e:	7402                	ld	s0,32(sp)
    80003320:	64e2                	ld	s1,24(sp)
    80003322:	6942                	ld	s2,16(sp)
    80003324:	69a2                	ld	s3,8(sp)
    80003326:	6145                	addi	sp,sp,48
    80003328:	8082                	ret
    virtio_disk_rw(b, 0);
    8000332a:	4581                	li	a1,0
    8000332c:	8526                	mv	a0,s1
    8000332e:	00003097          	auipc	ra,0x3
    80003332:	f4e080e7          	jalr	-178(ra) # 8000627c <virtio_disk_rw>
    b->valid = 1;
    80003336:	4785                	li	a5,1
    80003338:	c09c                	sw	a5,0(s1)
  return b;
    8000333a:	b7c5                	j	8000331a <bread+0xd0>

000000008000333c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000333c:	1101                	addi	sp,sp,-32
    8000333e:	ec06                	sd	ra,24(sp)
    80003340:	e822                	sd	s0,16(sp)
    80003342:	e426                	sd	s1,8(sp)
    80003344:	1000                	addi	s0,sp,32
    80003346:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003348:	0541                	addi	a0,a0,16
    8000334a:	00001097          	auipc	ra,0x1
    8000334e:	456080e7          	jalr	1110(ra) # 800047a0 <holdingsleep>
    80003352:	cd01                	beqz	a0,8000336a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003354:	4585                	li	a1,1
    80003356:	8526                	mv	a0,s1
    80003358:	00003097          	auipc	ra,0x3
    8000335c:	f24080e7          	jalr	-220(ra) # 8000627c <virtio_disk_rw>
}
    80003360:	60e2                	ld	ra,24(sp)
    80003362:	6442                	ld	s0,16(sp)
    80003364:	64a2                	ld	s1,8(sp)
    80003366:	6105                	addi	sp,sp,32
    80003368:	8082                	ret
    panic("bwrite");
    8000336a:	00005517          	auipc	a0,0x5
    8000336e:	27e50513          	addi	a0,a0,638 # 800085e8 <syscalls+0xd8>
    80003372:	ffffd097          	auipc	ra,0xffffd
    80003376:	1d6080e7          	jalr	470(ra) # 80000548 <panic>

000000008000337a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000337a:	1101                	addi	sp,sp,-32
    8000337c:	ec06                	sd	ra,24(sp)
    8000337e:	e822                	sd	s0,16(sp)
    80003380:	e426                	sd	s1,8(sp)
    80003382:	e04a                	sd	s2,0(sp)
    80003384:	1000                	addi	s0,sp,32
    80003386:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003388:	01050913          	addi	s2,a0,16
    8000338c:	854a                	mv	a0,s2
    8000338e:	00001097          	auipc	ra,0x1
    80003392:	412080e7          	jalr	1042(ra) # 800047a0 <holdingsleep>
    80003396:	c92d                	beqz	a0,80003408 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003398:	854a                	mv	a0,s2
    8000339a:	00001097          	auipc	ra,0x1
    8000339e:	3c2080e7          	jalr	962(ra) # 8000475c <releasesleep>

  acquire(&bcache.lock);
    800033a2:	00014517          	auipc	a0,0x14
    800033a6:	7de50513          	addi	a0,a0,2014 # 80017b80 <bcache>
    800033aa:	ffffe097          	auipc	ra,0xffffe
    800033ae:	866080e7          	jalr	-1946(ra) # 80000c10 <acquire>
  b->refcnt--;
    800033b2:	40bc                	lw	a5,64(s1)
    800033b4:	37fd                	addiw	a5,a5,-1
    800033b6:	0007871b          	sext.w	a4,a5
    800033ba:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800033bc:	eb05                	bnez	a4,800033ec <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800033be:	68bc                	ld	a5,80(s1)
    800033c0:	64b8                	ld	a4,72(s1)
    800033c2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800033c4:	64bc                	ld	a5,72(s1)
    800033c6:	68b8                	ld	a4,80(s1)
    800033c8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033ca:	0001c797          	auipc	a5,0x1c
    800033ce:	7b678793          	addi	a5,a5,1974 # 8001fb80 <bcache+0x8000>
    800033d2:	2b87b703          	ld	a4,696(a5)
    800033d6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033d8:	0001d717          	auipc	a4,0x1d
    800033dc:	a1070713          	addi	a4,a4,-1520 # 8001fde8 <bcache+0x8268>
    800033e0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033e2:	2b87b703          	ld	a4,696(a5)
    800033e6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033e8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033ec:	00014517          	auipc	a0,0x14
    800033f0:	79450513          	addi	a0,a0,1940 # 80017b80 <bcache>
    800033f4:	ffffe097          	auipc	ra,0xffffe
    800033f8:	8d0080e7          	jalr	-1840(ra) # 80000cc4 <release>
}
    800033fc:	60e2                	ld	ra,24(sp)
    800033fe:	6442                	ld	s0,16(sp)
    80003400:	64a2                	ld	s1,8(sp)
    80003402:	6902                	ld	s2,0(sp)
    80003404:	6105                	addi	sp,sp,32
    80003406:	8082                	ret
    panic("brelse");
    80003408:	00005517          	auipc	a0,0x5
    8000340c:	1e850513          	addi	a0,a0,488 # 800085f0 <syscalls+0xe0>
    80003410:	ffffd097          	auipc	ra,0xffffd
    80003414:	138080e7          	jalr	312(ra) # 80000548 <panic>

0000000080003418 <bpin>:

void
bpin(struct buf *b) {
    80003418:	1101                	addi	sp,sp,-32
    8000341a:	ec06                	sd	ra,24(sp)
    8000341c:	e822                	sd	s0,16(sp)
    8000341e:	e426                	sd	s1,8(sp)
    80003420:	1000                	addi	s0,sp,32
    80003422:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003424:	00014517          	auipc	a0,0x14
    80003428:	75c50513          	addi	a0,a0,1884 # 80017b80 <bcache>
    8000342c:	ffffd097          	auipc	ra,0xffffd
    80003430:	7e4080e7          	jalr	2020(ra) # 80000c10 <acquire>
  b->refcnt++;
    80003434:	40bc                	lw	a5,64(s1)
    80003436:	2785                	addiw	a5,a5,1
    80003438:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000343a:	00014517          	auipc	a0,0x14
    8000343e:	74650513          	addi	a0,a0,1862 # 80017b80 <bcache>
    80003442:	ffffe097          	auipc	ra,0xffffe
    80003446:	882080e7          	jalr	-1918(ra) # 80000cc4 <release>
}
    8000344a:	60e2                	ld	ra,24(sp)
    8000344c:	6442                	ld	s0,16(sp)
    8000344e:	64a2                	ld	s1,8(sp)
    80003450:	6105                	addi	sp,sp,32
    80003452:	8082                	ret

0000000080003454 <bunpin>:

void
bunpin(struct buf *b) {
    80003454:	1101                	addi	sp,sp,-32
    80003456:	ec06                	sd	ra,24(sp)
    80003458:	e822                	sd	s0,16(sp)
    8000345a:	e426                	sd	s1,8(sp)
    8000345c:	1000                	addi	s0,sp,32
    8000345e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003460:	00014517          	auipc	a0,0x14
    80003464:	72050513          	addi	a0,a0,1824 # 80017b80 <bcache>
    80003468:	ffffd097          	auipc	ra,0xffffd
    8000346c:	7a8080e7          	jalr	1960(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003470:	40bc                	lw	a5,64(s1)
    80003472:	37fd                	addiw	a5,a5,-1
    80003474:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003476:	00014517          	auipc	a0,0x14
    8000347a:	70a50513          	addi	a0,a0,1802 # 80017b80 <bcache>
    8000347e:	ffffe097          	auipc	ra,0xffffe
    80003482:	846080e7          	jalr	-1978(ra) # 80000cc4 <release>
}
    80003486:	60e2                	ld	ra,24(sp)
    80003488:	6442                	ld	s0,16(sp)
    8000348a:	64a2                	ld	s1,8(sp)
    8000348c:	6105                	addi	sp,sp,32
    8000348e:	8082                	ret

0000000080003490 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003490:	1101                	addi	sp,sp,-32
    80003492:	ec06                	sd	ra,24(sp)
    80003494:	e822                	sd	s0,16(sp)
    80003496:	e426                	sd	s1,8(sp)
    80003498:	e04a                	sd	s2,0(sp)
    8000349a:	1000                	addi	s0,sp,32
    8000349c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000349e:	00d5d59b          	srliw	a1,a1,0xd
    800034a2:	0001d797          	auipc	a5,0x1d
    800034a6:	dba7a783          	lw	a5,-582(a5) # 8002025c <sb+0x1c>
    800034aa:	9dbd                	addw	a1,a1,a5
    800034ac:	00000097          	auipc	ra,0x0
    800034b0:	d9e080e7          	jalr	-610(ra) # 8000324a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800034b4:	0074f713          	andi	a4,s1,7
    800034b8:	4785                	li	a5,1
    800034ba:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800034be:	14ce                	slli	s1,s1,0x33
    800034c0:	90d9                	srli	s1,s1,0x36
    800034c2:	00950733          	add	a4,a0,s1
    800034c6:	05874703          	lbu	a4,88(a4)
    800034ca:	00e7f6b3          	and	a3,a5,a4
    800034ce:	c69d                	beqz	a3,800034fc <bfree+0x6c>
    800034d0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034d2:	94aa                	add	s1,s1,a0
    800034d4:	fff7c793          	not	a5,a5
    800034d8:	8ff9                	and	a5,a5,a4
    800034da:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800034de:	00001097          	auipc	ra,0x1
    800034e2:	100080e7          	jalr	256(ra) # 800045de <log_write>
  brelse(bp);
    800034e6:	854a                	mv	a0,s2
    800034e8:	00000097          	auipc	ra,0x0
    800034ec:	e92080e7          	jalr	-366(ra) # 8000337a <brelse>
}
    800034f0:	60e2                	ld	ra,24(sp)
    800034f2:	6442                	ld	s0,16(sp)
    800034f4:	64a2                	ld	s1,8(sp)
    800034f6:	6902                	ld	s2,0(sp)
    800034f8:	6105                	addi	sp,sp,32
    800034fa:	8082                	ret
    panic("freeing free block");
    800034fc:	00005517          	auipc	a0,0x5
    80003500:	0fc50513          	addi	a0,a0,252 # 800085f8 <syscalls+0xe8>
    80003504:	ffffd097          	auipc	ra,0xffffd
    80003508:	044080e7          	jalr	68(ra) # 80000548 <panic>

000000008000350c <balloc>:
{
    8000350c:	711d                	addi	sp,sp,-96
    8000350e:	ec86                	sd	ra,88(sp)
    80003510:	e8a2                	sd	s0,80(sp)
    80003512:	e4a6                	sd	s1,72(sp)
    80003514:	e0ca                	sd	s2,64(sp)
    80003516:	fc4e                	sd	s3,56(sp)
    80003518:	f852                	sd	s4,48(sp)
    8000351a:	f456                	sd	s5,40(sp)
    8000351c:	f05a                	sd	s6,32(sp)
    8000351e:	ec5e                	sd	s7,24(sp)
    80003520:	e862                	sd	s8,16(sp)
    80003522:	e466                	sd	s9,8(sp)
    80003524:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003526:	0001d797          	auipc	a5,0x1d
    8000352a:	d1e7a783          	lw	a5,-738(a5) # 80020244 <sb+0x4>
    8000352e:	cbd1                	beqz	a5,800035c2 <balloc+0xb6>
    80003530:	8baa                	mv	s7,a0
    80003532:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003534:	0001db17          	auipc	s6,0x1d
    80003538:	d0cb0b13          	addi	s6,s6,-756 # 80020240 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000353c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000353e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003540:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003542:	6c89                	lui	s9,0x2
    80003544:	a831                	j	80003560 <balloc+0x54>
    brelse(bp);
    80003546:	854a                	mv	a0,s2
    80003548:	00000097          	auipc	ra,0x0
    8000354c:	e32080e7          	jalr	-462(ra) # 8000337a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003550:	015c87bb          	addw	a5,s9,s5
    80003554:	00078a9b          	sext.w	s5,a5
    80003558:	004b2703          	lw	a4,4(s6)
    8000355c:	06eaf363          	bgeu	s5,a4,800035c2 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003560:	41fad79b          	sraiw	a5,s5,0x1f
    80003564:	0137d79b          	srliw	a5,a5,0x13
    80003568:	015787bb          	addw	a5,a5,s5
    8000356c:	40d7d79b          	sraiw	a5,a5,0xd
    80003570:	01cb2583          	lw	a1,28(s6)
    80003574:	9dbd                	addw	a1,a1,a5
    80003576:	855e                	mv	a0,s7
    80003578:	00000097          	auipc	ra,0x0
    8000357c:	cd2080e7          	jalr	-814(ra) # 8000324a <bread>
    80003580:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003582:	004b2503          	lw	a0,4(s6)
    80003586:	000a849b          	sext.w	s1,s5
    8000358a:	8662                	mv	a2,s8
    8000358c:	faa4fde3          	bgeu	s1,a0,80003546 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003590:	41f6579b          	sraiw	a5,a2,0x1f
    80003594:	01d7d69b          	srliw	a3,a5,0x1d
    80003598:	00c6873b          	addw	a4,a3,a2
    8000359c:	00777793          	andi	a5,a4,7
    800035a0:	9f95                	subw	a5,a5,a3
    800035a2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800035a6:	4037571b          	sraiw	a4,a4,0x3
    800035aa:	00e906b3          	add	a3,s2,a4
    800035ae:	0586c683          	lbu	a3,88(a3)
    800035b2:	00d7f5b3          	and	a1,a5,a3
    800035b6:	cd91                	beqz	a1,800035d2 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035b8:	2605                	addiw	a2,a2,1
    800035ba:	2485                	addiw	s1,s1,1
    800035bc:	fd4618e3          	bne	a2,s4,8000358c <balloc+0x80>
    800035c0:	b759                	j	80003546 <balloc+0x3a>
  panic("balloc: out of blocks");
    800035c2:	00005517          	auipc	a0,0x5
    800035c6:	04e50513          	addi	a0,a0,78 # 80008610 <syscalls+0x100>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	f7e080e7          	jalr	-130(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800035d2:	974a                	add	a4,a4,s2
    800035d4:	8fd5                	or	a5,a5,a3
    800035d6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800035da:	854a                	mv	a0,s2
    800035dc:	00001097          	auipc	ra,0x1
    800035e0:	002080e7          	jalr	2(ra) # 800045de <log_write>
        brelse(bp);
    800035e4:	854a                	mv	a0,s2
    800035e6:	00000097          	auipc	ra,0x0
    800035ea:	d94080e7          	jalr	-620(ra) # 8000337a <brelse>
  bp = bread(dev, bno);
    800035ee:	85a6                	mv	a1,s1
    800035f0:	855e                	mv	a0,s7
    800035f2:	00000097          	auipc	ra,0x0
    800035f6:	c58080e7          	jalr	-936(ra) # 8000324a <bread>
    800035fa:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800035fc:	40000613          	li	a2,1024
    80003600:	4581                	li	a1,0
    80003602:	05850513          	addi	a0,a0,88
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	706080e7          	jalr	1798(ra) # 80000d0c <memset>
  log_write(bp);
    8000360e:	854a                	mv	a0,s2
    80003610:	00001097          	auipc	ra,0x1
    80003614:	fce080e7          	jalr	-50(ra) # 800045de <log_write>
  brelse(bp);
    80003618:	854a                	mv	a0,s2
    8000361a:	00000097          	auipc	ra,0x0
    8000361e:	d60080e7          	jalr	-672(ra) # 8000337a <brelse>
}
    80003622:	8526                	mv	a0,s1
    80003624:	60e6                	ld	ra,88(sp)
    80003626:	6446                	ld	s0,80(sp)
    80003628:	64a6                	ld	s1,72(sp)
    8000362a:	6906                	ld	s2,64(sp)
    8000362c:	79e2                	ld	s3,56(sp)
    8000362e:	7a42                	ld	s4,48(sp)
    80003630:	7aa2                	ld	s5,40(sp)
    80003632:	7b02                	ld	s6,32(sp)
    80003634:	6be2                	ld	s7,24(sp)
    80003636:	6c42                	ld	s8,16(sp)
    80003638:	6ca2                	ld	s9,8(sp)
    8000363a:	6125                	addi	sp,sp,96
    8000363c:	8082                	ret

000000008000363e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000363e:	7179                	addi	sp,sp,-48
    80003640:	f406                	sd	ra,40(sp)
    80003642:	f022                	sd	s0,32(sp)
    80003644:	ec26                	sd	s1,24(sp)
    80003646:	e84a                	sd	s2,16(sp)
    80003648:	e44e                	sd	s3,8(sp)
    8000364a:	e052                	sd	s4,0(sp)
    8000364c:	1800                	addi	s0,sp,48
    8000364e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003650:	47ad                	li	a5,11
    80003652:	04b7fe63          	bgeu	a5,a1,800036ae <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003656:	ff45849b          	addiw	s1,a1,-12
    8000365a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000365e:	0ff00793          	li	a5,255
    80003662:	0ae7e363          	bltu	a5,a4,80003708 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003666:	08052583          	lw	a1,128(a0)
    8000366a:	c5ad                	beqz	a1,800036d4 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000366c:	00092503          	lw	a0,0(s2)
    80003670:	00000097          	auipc	ra,0x0
    80003674:	bda080e7          	jalr	-1062(ra) # 8000324a <bread>
    80003678:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000367a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000367e:	02049593          	slli	a1,s1,0x20
    80003682:	9181                	srli	a1,a1,0x20
    80003684:	058a                	slli	a1,a1,0x2
    80003686:	00b784b3          	add	s1,a5,a1
    8000368a:	0004a983          	lw	s3,0(s1)
    8000368e:	04098d63          	beqz	s3,800036e8 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003692:	8552                	mv	a0,s4
    80003694:	00000097          	auipc	ra,0x0
    80003698:	ce6080e7          	jalr	-794(ra) # 8000337a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000369c:	854e                	mv	a0,s3
    8000369e:	70a2                	ld	ra,40(sp)
    800036a0:	7402                	ld	s0,32(sp)
    800036a2:	64e2                	ld	s1,24(sp)
    800036a4:	6942                	ld	s2,16(sp)
    800036a6:	69a2                	ld	s3,8(sp)
    800036a8:	6a02                	ld	s4,0(sp)
    800036aa:	6145                	addi	sp,sp,48
    800036ac:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800036ae:	02059493          	slli	s1,a1,0x20
    800036b2:	9081                	srli	s1,s1,0x20
    800036b4:	048a                	slli	s1,s1,0x2
    800036b6:	94aa                	add	s1,s1,a0
    800036b8:	0504a983          	lw	s3,80(s1)
    800036bc:	fe0990e3          	bnez	s3,8000369c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800036c0:	4108                	lw	a0,0(a0)
    800036c2:	00000097          	auipc	ra,0x0
    800036c6:	e4a080e7          	jalr	-438(ra) # 8000350c <balloc>
    800036ca:	0005099b          	sext.w	s3,a0
    800036ce:	0534a823          	sw	s3,80(s1)
    800036d2:	b7e9                	j	8000369c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800036d4:	4108                	lw	a0,0(a0)
    800036d6:	00000097          	auipc	ra,0x0
    800036da:	e36080e7          	jalr	-458(ra) # 8000350c <balloc>
    800036de:	0005059b          	sext.w	a1,a0
    800036e2:	08b92023          	sw	a1,128(s2)
    800036e6:	b759                	j	8000366c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800036e8:	00092503          	lw	a0,0(s2)
    800036ec:	00000097          	auipc	ra,0x0
    800036f0:	e20080e7          	jalr	-480(ra) # 8000350c <balloc>
    800036f4:	0005099b          	sext.w	s3,a0
    800036f8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800036fc:	8552                	mv	a0,s4
    800036fe:	00001097          	auipc	ra,0x1
    80003702:	ee0080e7          	jalr	-288(ra) # 800045de <log_write>
    80003706:	b771                	j	80003692 <bmap+0x54>
  panic("bmap: out of range");
    80003708:	00005517          	auipc	a0,0x5
    8000370c:	f2050513          	addi	a0,a0,-224 # 80008628 <syscalls+0x118>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	e38080e7          	jalr	-456(ra) # 80000548 <panic>

0000000080003718 <iget>:
{
    80003718:	7179                	addi	sp,sp,-48
    8000371a:	f406                	sd	ra,40(sp)
    8000371c:	f022                	sd	s0,32(sp)
    8000371e:	ec26                	sd	s1,24(sp)
    80003720:	e84a                	sd	s2,16(sp)
    80003722:	e44e                	sd	s3,8(sp)
    80003724:	e052                	sd	s4,0(sp)
    80003726:	1800                	addi	s0,sp,48
    80003728:	89aa                	mv	s3,a0
    8000372a:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000372c:	0001d517          	auipc	a0,0x1d
    80003730:	b3450513          	addi	a0,a0,-1228 # 80020260 <icache>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	4dc080e7          	jalr	1244(ra) # 80000c10 <acquire>
  empty = 0;
    8000373c:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000373e:	0001d497          	auipc	s1,0x1d
    80003742:	b3a48493          	addi	s1,s1,-1222 # 80020278 <icache+0x18>
    80003746:	0001e697          	auipc	a3,0x1e
    8000374a:	5c268693          	addi	a3,a3,1474 # 80021d08 <log>
    8000374e:	a039                	j	8000375c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003750:	02090b63          	beqz	s2,80003786 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003754:	08848493          	addi	s1,s1,136
    80003758:	02d48a63          	beq	s1,a3,8000378c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000375c:	449c                	lw	a5,8(s1)
    8000375e:	fef059e3          	blez	a5,80003750 <iget+0x38>
    80003762:	4098                	lw	a4,0(s1)
    80003764:	ff3716e3          	bne	a4,s3,80003750 <iget+0x38>
    80003768:	40d8                	lw	a4,4(s1)
    8000376a:	ff4713e3          	bne	a4,s4,80003750 <iget+0x38>
      ip->ref++;
    8000376e:	2785                	addiw	a5,a5,1
    80003770:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003772:	0001d517          	auipc	a0,0x1d
    80003776:	aee50513          	addi	a0,a0,-1298 # 80020260 <icache>
    8000377a:	ffffd097          	auipc	ra,0xffffd
    8000377e:	54a080e7          	jalr	1354(ra) # 80000cc4 <release>
      return ip;
    80003782:	8926                	mv	s2,s1
    80003784:	a03d                	j	800037b2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003786:	f7f9                	bnez	a5,80003754 <iget+0x3c>
    80003788:	8926                	mv	s2,s1
    8000378a:	b7e9                	j	80003754 <iget+0x3c>
  if(empty == 0)
    8000378c:	02090c63          	beqz	s2,800037c4 <iget+0xac>
  ip->dev = dev;
    80003790:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003794:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003798:	4785                	li	a5,1
    8000379a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000379e:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800037a2:	0001d517          	auipc	a0,0x1d
    800037a6:	abe50513          	addi	a0,a0,-1346 # 80020260 <icache>
    800037aa:	ffffd097          	auipc	ra,0xffffd
    800037ae:	51a080e7          	jalr	1306(ra) # 80000cc4 <release>
}
    800037b2:	854a                	mv	a0,s2
    800037b4:	70a2                	ld	ra,40(sp)
    800037b6:	7402                	ld	s0,32(sp)
    800037b8:	64e2                	ld	s1,24(sp)
    800037ba:	6942                	ld	s2,16(sp)
    800037bc:	69a2                	ld	s3,8(sp)
    800037be:	6a02                	ld	s4,0(sp)
    800037c0:	6145                	addi	sp,sp,48
    800037c2:	8082                	ret
    panic("iget: no inodes");
    800037c4:	00005517          	auipc	a0,0x5
    800037c8:	e7c50513          	addi	a0,a0,-388 # 80008640 <syscalls+0x130>
    800037cc:	ffffd097          	auipc	ra,0xffffd
    800037d0:	d7c080e7          	jalr	-644(ra) # 80000548 <panic>

00000000800037d4 <fsinit>:
fsinit(int dev) {
    800037d4:	7179                	addi	sp,sp,-48
    800037d6:	f406                	sd	ra,40(sp)
    800037d8:	f022                	sd	s0,32(sp)
    800037da:	ec26                	sd	s1,24(sp)
    800037dc:	e84a                	sd	s2,16(sp)
    800037de:	e44e                	sd	s3,8(sp)
    800037e0:	1800                	addi	s0,sp,48
    800037e2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037e4:	4585                	li	a1,1
    800037e6:	00000097          	auipc	ra,0x0
    800037ea:	a64080e7          	jalr	-1436(ra) # 8000324a <bread>
    800037ee:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037f0:	0001d997          	auipc	s3,0x1d
    800037f4:	a5098993          	addi	s3,s3,-1456 # 80020240 <sb>
    800037f8:	02000613          	li	a2,32
    800037fc:	05850593          	addi	a1,a0,88
    80003800:	854e                	mv	a0,s3
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	56a080e7          	jalr	1386(ra) # 80000d6c <memmove>
  brelse(bp);
    8000380a:	8526                	mv	a0,s1
    8000380c:	00000097          	auipc	ra,0x0
    80003810:	b6e080e7          	jalr	-1170(ra) # 8000337a <brelse>
  if(sb.magic != FSMAGIC)
    80003814:	0009a703          	lw	a4,0(s3)
    80003818:	102037b7          	lui	a5,0x10203
    8000381c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003820:	02f71263          	bne	a4,a5,80003844 <fsinit+0x70>
  initlog(dev, &sb);
    80003824:	0001d597          	auipc	a1,0x1d
    80003828:	a1c58593          	addi	a1,a1,-1508 # 80020240 <sb>
    8000382c:	854a                	mv	a0,s2
    8000382e:	00001097          	auipc	ra,0x1
    80003832:	b38080e7          	jalr	-1224(ra) # 80004366 <initlog>
}
    80003836:	70a2                	ld	ra,40(sp)
    80003838:	7402                	ld	s0,32(sp)
    8000383a:	64e2                	ld	s1,24(sp)
    8000383c:	6942                	ld	s2,16(sp)
    8000383e:	69a2                	ld	s3,8(sp)
    80003840:	6145                	addi	sp,sp,48
    80003842:	8082                	ret
    panic("invalid file system");
    80003844:	00005517          	auipc	a0,0x5
    80003848:	e0c50513          	addi	a0,a0,-500 # 80008650 <syscalls+0x140>
    8000384c:	ffffd097          	auipc	ra,0xffffd
    80003850:	cfc080e7          	jalr	-772(ra) # 80000548 <panic>

0000000080003854 <iinit>:
{
    80003854:	7179                	addi	sp,sp,-48
    80003856:	f406                	sd	ra,40(sp)
    80003858:	f022                	sd	s0,32(sp)
    8000385a:	ec26                	sd	s1,24(sp)
    8000385c:	e84a                	sd	s2,16(sp)
    8000385e:	e44e                	sd	s3,8(sp)
    80003860:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003862:	00005597          	auipc	a1,0x5
    80003866:	e0658593          	addi	a1,a1,-506 # 80008668 <syscalls+0x158>
    8000386a:	0001d517          	auipc	a0,0x1d
    8000386e:	9f650513          	addi	a0,a0,-1546 # 80020260 <icache>
    80003872:	ffffd097          	auipc	ra,0xffffd
    80003876:	30e080e7          	jalr	782(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000387a:	0001d497          	auipc	s1,0x1d
    8000387e:	a0e48493          	addi	s1,s1,-1522 # 80020288 <icache+0x28>
    80003882:	0001e997          	auipc	s3,0x1e
    80003886:	49698993          	addi	s3,s3,1174 # 80021d18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000388a:	00005917          	auipc	s2,0x5
    8000388e:	de690913          	addi	s2,s2,-538 # 80008670 <syscalls+0x160>
    80003892:	85ca                	mv	a1,s2
    80003894:	8526                	mv	a0,s1
    80003896:	00001097          	auipc	ra,0x1
    8000389a:	e36080e7          	jalr	-458(ra) # 800046cc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000389e:	08848493          	addi	s1,s1,136
    800038a2:	ff3498e3          	bne	s1,s3,80003892 <iinit+0x3e>
}
    800038a6:	70a2                	ld	ra,40(sp)
    800038a8:	7402                	ld	s0,32(sp)
    800038aa:	64e2                	ld	s1,24(sp)
    800038ac:	6942                	ld	s2,16(sp)
    800038ae:	69a2                	ld	s3,8(sp)
    800038b0:	6145                	addi	sp,sp,48
    800038b2:	8082                	ret

00000000800038b4 <ialloc>:
{
    800038b4:	715d                	addi	sp,sp,-80
    800038b6:	e486                	sd	ra,72(sp)
    800038b8:	e0a2                	sd	s0,64(sp)
    800038ba:	fc26                	sd	s1,56(sp)
    800038bc:	f84a                	sd	s2,48(sp)
    800038be:	f44e                	sd	s3,40(sp)
    800038c0:	f052                	sd	s4,32(sp)
    800038c2:	ec56                	sd	s5,24(sp)
    800038c4:	e85a                	sd	s6,16(sp)
    800038c6:	e45e                	sd	s7,8(sp)
    800038c8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800038ca:	0001d717          	auipc	a4,0x1d
    800038ce:	98272703          	lw	a4,-1662(a4) # 8002024c <sb+0xc>
    800038d2:	4785                	li	a5,1
    800038d4:	04e7fa63          	bgeu	a5,a4,80003928 <ialloc+0x74>
    800038d8:	8aaa                	mv	s5,a0
    800038da:	8bae                	mv	s7,a1
    800038dc:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800038de:	0001da17          	auipc	s4,0x1d
    800038e2:	962a0a13          	addi	s4,s4,-1694 # 80020240 <sb>
    800038e6:	00048b1b          	sext.w	s6,s1
    800038ea:	0044d593          	srli	a1,s1,0x4
    800038ee:	018a2783          	lw	a5,24(s4)
    800038f2:	9dbd                	addw	a1,a1,a5
    800038f4:	8556                	mv	a0,s5
    800038f6:	00000097          	auipc	ra,0x0
    800038fa:	954080e7          	jalr	-1708(ra) # 8000324a <bread>
    800038fe:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003900:	05850993          	addi	s3,a0,88
    80003904:	00f4f793          	andi	a5,s1,15
    80003908:	079a                	slli	a5,a5,0x6
    8000390a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000390c:	00099783          	lh	a5,0(s3)
    80003910:	c785                	beqz	a5,80003938 <ialloc+0x84>
    brelse(bp);
    80003912:	00000097          	auipc	ra,0x0
    80003916:	a68080e7          	jalr	-1432(ra) # 8000337a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000391a:	0485                	addi	s1,s1,1
    8000391c:	00ca2703          	lw	a4,12(s4)
    80003920:	0004879b          	sext.w	a5,s1
    80003924:	fce7e1e3          	bltu	a5,a4,800038e6 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003928:	00005517          	auipc	a0,0x5
    8000392c:	d5050513          	addi	a0,a0,-688 # 80008678 <syscalls+0x168>
    80003930:	ffffd097          	auipc	ra,0xffffd
    80003934:	c18080e7          	jalr	-1000(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003938:	04000613          	li	a2,64
    8000393c:	4581                	li	a1,0
    8000393e:	854e                	mv	a0,s3
    80003940:	ffffd097          	auipc	ra,0xffffd
    80003944:	3cc080e7          	jalr	972(ra) # 80000d0c <memset>
      dip->type = type;
    80003948:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000394c:	854a                	mv	a0,s2
    8000394e:	00001097          	auipc	ra,0x1
    80003952:	c90080e7          	jalr	-880(ra) # 800045de <log_write>
      brelse(bp);
    80003956:	854a                	mv	a0,s2
    80003958:	00000097          	auipc	ra,0x0
    8000395c:	a22080e7          	jalr	-1502(ra) # 8000337a <brelse>
      return iget(dev, inum);
    80003960:	85da                	mv	a1,s6
    80003962:	8556                	mv	a0,s5
    80003964:	00000097          	auipc	ra,0x0
    80003968:	db4080e7          	jalr	-588(ra) # 80003718 <iget>
}
    8000396c:	60a6                	ld	ra,72(sp)
    8000396e:	6406                	ld	s0,64(sp)
    80003970:	74e2                	ld	s1,56(sp)
    80003972:	7942                	ld	s2,48(sp)
    80003974:	79a2                	ld	s3,40(sp)
    80003976:	7a02                	ld	s4,32(sp)
    80003978:	6ae2                	ld	s5,24(sp)
    8000397a:	6b42                	ld	s6,16(sp)
    8000397c:	6ba2                	ld	s7,8(sp)
    8000397e:	6161                	addi	sp,sp,80
    80003980:	8082                	ret

0000000080003982 <iupdate>:
{
    80003982:	1101                	addi	sp,sp,-32
    80003984:	ec06                	sd	ra,24(sp)
    80003986:	e822                	sd	s0,16(sp)
    80003988:	e426                	sd	s1,8(sp)
    8000398a:	e04a                	sd	s2,0(sp)
    8000398c:	1000                	addi	s0,sp,32
    8000398e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003990:	415c                	lw	a5,4(a0)
    80003992:	0047d79b          	srliw	a5,a5,0x4
    80003996:	0001d597          	auipc	a1,0x1d
    8000399a:	8c25a583          	lw	a1,-1854(a1) # 80020258 <sb+0x18>
    8000399e:	9dbd                	addw	a1,a1,a5
    800039a0:	4108                	lw	a0,0(a0)
    800039a2:	00000097          	auipc	ra,0x0
    800039a6:	8a8080e7          	jalr	-1880(ra) # 8000324a <bread>
    800039aa:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039ac:	05850793          	addi	a5,a0,88
    800039b0:	40c8                	lw	a0,4(s1)
    800039b2:	893d                	andi	a0,a0,15
    800039b4:	051a                	slli	a0,a0,0x6
    800039b6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800039b8:	04449703          	lh	a4,68(s1)
    800039bc:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800039c0:	04649703          	lh	a4,70(s1)
    800039c4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800039c8:	04849703          	lh	a4,72(s1)
    800039cc:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800039d0:	04a49703          	lh	a4,74(s1)
    800039d4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800039d8:	44f8                	lw	a4,76(s1)
    800039da:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800039dc:	03400613          	li	a2,52
    800039e0:	05048593          	addi	a1,s1,80
    800039e4:	0531                	addi	a0,a0,12
    800039e6:	ffffd097          	auipc	ra,0xffffd
    800039ea:	386080e7          	jalr	902(ra) # 80000d6c <memmove>
  log_write(bp);
    800039ee:	854a                	mv	a0,s2
    800039f0:	00001097          	auipc	ra,0x1
    800039f4:	bee080e7          	jalr	-1042(ra) # 800045de <log_write>
  brelse(bp);
    800039f8:	854a                	mv	a0,s2
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	980080e7          	jalr	-1664(ra) # 8000337a <brelse>
}
    80003a02:	60e2                	ld	ra,24(sp)
    80003a04:	6442                	ld	s0,16(sp)
    80003a06:	64a2                	ld	s1,8(sp)
    80003a08:	6902                	ld	s2,0(sp)
    80003a0a:	6105                	addi	sp,sp,32
    80003a0c:	8082                	ret

0000000080003a0e <idup>:
{
    80003a0e:	1101                	addi	sp,sp,-32
    80003a10:	ec06                	sd	ra,24(sp)
    80003a12:	e822                	sd	s0,16(sp)
    80003a14:	e426                	sd	s1,8(sp)
    80003a16:	1000                	addi	s0,sp,32
    80003a18:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a1a:	0001d517          	auipc	a0,0x1d
    80003a1e:	84650513          	addi	a0,a0,-1978 # 80020260 <icache>
    80003a22:	ffffd097          	auipc	ra,0xffffd
    80003a26:	1ee080e7          	jalr	494(ra) # 80000c10 <acquire>
  ip->ref++;
    80003a2a:	449c                	lw	a5,8(s1)
    80003a2c:	2785                	addiw	a5,a5,1
    80003a2e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a30:	0001d517          	auipc	a0,0x1d
    80003a34:	83050513          	addi	a0,a0,-2000 # 80020260 <icache>
    80003a38:	ffffd097          	auipc	ra,0xffffd
    80003a3c:	28c080e7          	jalr	652(ra) # 80000cc4 <release>
}
    80003a40:	8526                	mv	a0,s1
    80003a42:	60e2                	ld	ra,24(sp)
    80003a44:	6442                	ld	s0,16(sp)
    80003a46:	64a2                	ld	s1,8(sp)
    80003a48:	6105                	addi	sp,sp,32
    80003a4a:	8082                	ret

0000000080003a4c <ilock>:
{
    80003a4c:	1101                	addi	sp,sp,-32
    80003a4e:	ec06                	sd	ra,24(sp)
    80003a50:	e822                	sd	s0,16(sp)
    80003a52:	e426                	sd	s1,8(sp)
    80003a54:	e04a                	sd	s2,0(sp)
    80003a56:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a58:	c115                	beqz	a0,80003a7c <ilock+0x30>
    80003a5a:	84aa                	mv	s1,a0
    80003a5c:	451c                	lw	a5,8(a0)
    80003a5e:	00f05f63          	blez	a5,80003a7c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a62:	0541                	addi	a0,a0,16
    80003a64:	00001097          	auipc	ra,0x1
    80003a68:	ca2080e7          	jalr	-862(ra) # 80004706 <acquiresleep>
  if(ip->valid == 0){
    80003a6c:	40bc                	lw	a5,64(s1)
    80003a6e:	cf99                	beqz	a5,80003a8c <ilock+0x40>
}
    80003a70:	60e2                	ld	ra,24(sp)
    80003a72:	6442                	ld	s0,16(sp)
    80003a74:	64a2                	ld	s1,8(sp)
    80003a76:	6902                	ld	s2,0(sp)
    80003a78:	6105                	addi	sp,sp,32
    80003a7a:	8082                	ret
    panic("ilock");
    80003a7c:	00005517          	auipc	a0,0x5
    80003a80:	c1450513          	addi	a0,a0,-1004 # 80008690 <syscalls+0x180>
    80003a84:	ffffd097          	auipc	ra,0xffffd
    80003a88:	ac4080e7          	jalr	-1340(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a8c:	40dc                	lw	a5,4(s1)
    80003a8e:	0047d79b          	srliw	a5,a5,0x4
    80003a92:	0001c597          	auipc	a1,0x1c
    80003a96:	7c65a583          	lw	a1,1990(a1) # 80020258 <sb+0x18>
    80003a9a:	9dbd                	addw	a1,a1,a5
    80003a9c:	4088                	lw	a0,0(s1)
    80003a9e:	fffff097          	auipc	ra,0xfffff
    80003aa2:	7ac080e7          	jalr	1964(ra) # 8000324a <bread>
    80003aa6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003aa8:	05850593          	addi	a1,a0,88
    80003aac:	40dc                	lw	a5,4(s1)
    80003aae:	8bbd                	andi	a5,a5,15
    80003ab0:	079a                	slli	a5,a5,0x6
    80003ab2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ab4:	00059783          	lh	a5,0(a1)
    80003ab8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003abc:	00259783          	lh	a5,2(a1)
    80003ac0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003ac4:	00459783          	lh	a5,4(a1)
    80003ac8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003acc:	00659783          	lh	a5,6(a1)
    80003ad0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ad4:	459c                	lw	a5,8(a1)
    80003ad6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ad8:	03400613          	li	a2,52
    80003adc:	05b1                	addi	a1,a1,12
    80003ade:	05048513          	addi	a0,s1,80
    80003ae2:	ffffd097          	auipc	ra,0xffffd
    80003ae6:	28a080e7          	jalr	650(ra) # 80000d6c <memmove>
    brelse(bp);
    80003aea:	854a                	mv	a0,s2
    80003aec:	00000097          	auipc	ra,0x0
    80003af0:	88e080e7          	jalr	-1906(ra) # 8000337a <brelse>
    ip->valid = 1;
    80003af4:	4785                	li	a5,1
    80003af6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003af8:	04449783          	lh	a5,68(s1)
    80003afc:	fbb5                	bnez	a5,80003a70 <ilock+0x24>
      panic("ilock: no type");
    80003afe:	00005517          	auipc	a0,0x5
    80003b02:	b9a50513          	addi	a0,a0,-1126 # 80008698 <syscalls+0x188>
    80003b06:	ffffd097          	auipc	ra,0xffffd
    80003b0a:	a42080e7          	jalr	-1470(ra) # 80000548 <panic>

0000000080003b0e <iunlock>:
{
    80003b0e:	1101                	addi	sp,sp,-32
    80003b10:	ec06                	sd	ra,24(sp)
    80003b12:	e822                	sd	s0,16(sp)
    80003b14:	e426                	sd	s1,8(sp)
    80003b16:	e04a                	sd	s2,0(sp)
    80003b18:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b1a:	c905                	beqz	a0,80003b4a <iunlock+0x3c>
    80003b1c:	84aa                	mv	s1,a0
    80003b1e:	01050913          	addi	s2,a0,16
    80003b22:	854a                	mv	a0,s2
    80003b24:	00001097          	auipc	ra,0x1
    80003b28:	c7c080e7          	jalr	-900(ra) # 800047a0 <holdingsleep>
    80003b2c:	cd19                	beqz	a0,80003b4a <iunlock+0x3c>
    80003b2e:	449c                	lw	a5,8(s1)
    80003b30:	00f05d63          	blez	a5,80003b4a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b34:	854a                	mv	a0,s2
    80003b36:	00001097          	auipc	ra,0x1
    80003b3a:	c26080e7          	jalr	-986(ra) # 8000475c <releasesleep>
}
    80003b3e:	60e2                	ld	ra,24(sp)
    80003b40:	6442                	ld	s0,16(sp)
    80003b42:	64a2                	ld	s1,8(sp)
    80003b44:	6902                	ld	s2,0(sp)
    80003b46:	6105                	addi	sp,sp,32
    80003b48:	8082                	ret
    panic("iunlock");
    80003b4a:	00005517          	auipc	a0,0x5
    80003b4e:	b5e50513          	addi	a0,a0,-1186 # 800086a8 <syscalls+0x198>
    80003b52:	ffffd097          	auipc	ra,0xffffd
    80003b56:	9f6080e7          	jalr	-1546(ra) # 80000548 <panic>

0000000080003b5a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b5a:	7179                	addi	sp,sp,-48
    80003b5c:	f406                	sd	ra,40(sp)
    80003b5e:	f022                	sd	s0,32(sp)
    80003b60:	ec26                	sd	s1,24(sp)
    80003b62:	e84a                	sd	s2,16(sp)
    80003b64:	e44e                	sd	s3,8(sp)
    80003b66:	e052                	sd	s4,0(sp)
    80003b68:	1800                	addi	s0,sp,48
    80003b6a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b6c:	05050493          	addi	s1,a0,80
    80003b70:	08050913          	addi	s2,a0,128
    80003b74:	a021                	j	80003b7c <itrunc+0x22>
    80003b76:	0491                	addi	s1,s1,4
    80003b78:	01248d63          	beq	s1,s2,80003b92 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b7c:	408c                	lw	a1,0(s1)
    80003b7e:	dde5                	beqz	a1,80003b76 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b80:	0009a503          	lw	a0,0(s3)
    80003b84:	00000097          	auipc	ra,0x0
    80003b88:	90c080e7          	jalr	-1780(ra) # 80003490 <bfree>
      ip->addrs[i] = 0;
    80003b8c:	0004a023          	sw	zero,0(s1)
    80003b90:	b7dd                	j	80003b76 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b92:	0809a583          	lw	a1,128(s3)
    80003b96:	e185                	bnez	a1,80003bb6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b98:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b9c:	854e                	mv	a0,s3
    80003b9e:	00000097          	auipc	ra,0x0
    80003ba2:	de4080e7          	jalr	-540(ra) # 80003982 <iupdate>
}
    80003ba6:	70a2                	ld	ra,40(sp)
    80003ba8:	7402                	ld	s0,32(sp)
    80003baa:	64e2                	ld	s1,24(sp)
    80003bac:	6942                	ld	s2,16(sp)
    80003bae:	69a2                	ld	s3,8(sp)
    80003bb0:	6a02                	ld	s4,0(sp)
    80003bb2:	6145                	addi	sp,sp,48
    80003bb4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003bb6:	0009a503          	lw	a0,0(s3)
    80003bba:	fffff097          	auipc	ra,0xfffff
    80003bbe:	690080e7          	jalr	1680(ra) # 8000324a <bread>
    80003bc2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003bc4:	05850493          	addi	s1,a0,88
    80003bc8:	45850913          	addi	s2,a0,1112
    80003bcc:	a811                	j	80003be0 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003bce:	0009a503          	lw	a0,0(s3)
    80003bd2:	00000097          	auipc	ra,0x0
    80003bd6:	8be080e7          	jalr	-1858(ra) # 80003490 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003bda:	0491                	addi	s1,s1,4
    80003bdc:	01248563          	beq	s1,s2,80003be6 <itrunc+0x8c>
      if(a[j])
    80003be0:	408c                	lw	a1,0(s1)
    80003be2:	dde5                	beqz	a1,80003bda <itrunc+0x80>
    80003be4:	b7ed                	j	80003bce <itrunc+0x74>
    brelse(bp);
    80003be6:	8552                	mv	a0,s4
    80003be8:	fffff097          	auipc	ra,0xfffff
    80003bec:	792080e7          	jalr	1938(ra) # 8000337a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003bf0:	0809a583          	lw	a1,128(s3)
    80003bf4:	0009a503          	lw	a0,0(s3)
    80003bf8:	00000097          	auipc	ra,0x0
    80003bfc:	898080e7          	jalr	-1896(ra) # 80003490 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c00:	0809a023          	sw	zero,128(s3)
    80003c04:	bf51                	j	80003b98 <itrunc+0x3e>

0000000080003c06 <iput>:
{
    80003c06:	1101                	addi	sp,sp,-32
    80003c08:	ec06                	sd	ra,24(sp)
    80003c0a:	e822                	sd	s0,16(sp)
    80003c0c:	e426                	sd	s1,8(sp)
    80003c0e:	e04a                	sd	s2,0(sp)
    80003c10:	1000                	addi	s0,sp,32
    80003c12:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003c14:	0001c517          	auipc	a0,0x1c
    80003c18:	64c50513          	addi	a0,a0,1612 # 80020260 <icache>
    80003c1c:	ffffd097          	auipc	ra,0xffffd
    80003c20:	ff4080e7          	jalr	-12(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c24:	4498                	lw	a4,8(s1)
    80003c26:	4785                	li	a5,1
    80003c28:	02f70363          	beq	a4,a5,80003c4e <iput+0x48>
  ip->ref--;
    80003c2c:	449c                	lw	a5,8(s1)
    80003c2e:	37fd                	addiw	a5,a5,-1
    80003c30:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003c32:	0001c517          	auipc	a0,0x1c
    80003c36:	62e50513          	addi	a0,a0,1582 # 80020260 <icache>
    80003c3a:	ffffd097          	auipc	ra,0xffffd
    80003c3e:	08a080e7          	jalr	138(ra) # 80000cc4 <release>
}
    80003c42:	60e2                	ld	ra,24(sp)
    80003c44:	6442                	ld	s0,16(sp)
    80003c46:	64a2                	ld	s1,8(sp)
    80003c48:	6902                	ld	s2,0(sp)
    80003c4a:	6105                	addi	sp,sp,32
    80003c4c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c4e:	40bc                	lw	a5,64(s1)
    80003c50:	dff1                	beqz	a5,80003c2c <iput+0x26>
    80003c52:	04a49783          	lh	a5,74(s1)
    80003c56:	fbf9                	bnez	a5,80003c2c <iput+0x26>
    acquiresleep(&ip->lock);
    80003c58:	01048913          	addi	s2,s1,16
    80003c5c:	854a                	mv	a0,s2
    80003c5e:	00001097          	auipc	ra,0x1
    80003c62:	aa8080e7          	jalr	-1368(ra) # 80004706 <acquiresleep>
    release(&icache.lock);
    80003c66:	0001c517          	auipc	a0,0x1c
    80003c6a:	5fa50513          	addi	a0,a0,1530 # 80020260 <icache>
    80003c6e:	ffffd097          	auipc	ra,0xffffd
    80003c72:	056080e7          	jalr	86(ra) # 80000cc4 <release>
    itrunc(ip);
    80003c76:	8526                	mv	a0,s1
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	ee2080e7          	jalr	-286(ra) # 80003b5a <itrunc>
    ip->type = 0;
    80003c80:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c84:	8526                	mv	a0,s1
    80003c86:	00000097          	auipc	ra,0x0
    80003c8a:	cfc080e7          	jalr	-772(ra) # 80003982 <iupdate>
    ip->valid = 0;
    80003c8e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c92:	854a                	mv	a0,s2
    80003c94:	00001097          	auipc	ra,0x1
    80003c98:	ac8080e7          	jalr	-1336(ra) # 8000475c <releasesleep>
    acquire(&icache.lock);
    80003c9c:	0001c517          	auipc	a0,0x1c
    80003ca0:	5c450513          	addi	a0,a0,1476 # 80020260 <icache>
    80003ca4:	ffffd097          	auipc	ra,0xffffd
    80003ca8:	f6c080e7          	jalr	-148(ra) # 80000c10 <acquire>
    80003cac:	b741                	j	80003c2c <iput+0x26>

0000000080003cae <iunlockput>:
{
    80003cae:	1101                	addi	sp,sp,-32
    80003cb0:	ec06                	sd	ra,24(sp)
    80003cb2:	e822                	sd	s0,16(sp)
    80003cb4:	e426                	sd	s1,8(sp)
    80003cb6:	1000                	addi	s0,sp,32
    80003cb8:	84aa                	mv	s1,a0
  iunlock(ip);
    80003cba:	00000097          	auipc	ra,0x0
    80003cbe:	e54080e7          	jalr	-428(ra) # 80003b0e <iunlock>
  iput(ip);
    80003cc2:	8526                	mv	a0,s1
    80003cc4:	00000097          	auipc	ra,0x0
    80003cc8:	f42080e7          	jalr	-190(ra) # 80003c06 <iput>
}
    80003ccc:	60e2                	ld	ra,24(sp)
    80003cce:	6442                	ld	s0,16(sp)
    80003cd0:	64a2                	ld	s1,8(sp)
    80003cd2:	6105                	addi	sp,sp,32
    80003cd4:	8082                	ret

0000000080003cd6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003cd6:	1141                	addi	sp,sp,-16
    80003cd8:	e422                	sd	s0,8(sp)
    80003cda:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003cdc:	411c                	lw	a5,0(a0)
    80003cde:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ce0:	415c                	lw	a5,4(a0)
    80003ce2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ce4:	04451783          	lh	a5,68(a0)
    80003ce8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003cec:	04a51783          	lh	a5,74(a0)
    80003cf0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003cf4:	04c56783          	lwu	a5,76(a0)
    80003cf8:	e99c                	sd	a5,16(a1)
}
    80003cfa:	6422                	ld	s0,8(sp)
    80003cfc:	0141                	addi	sp,sp,16
    80003cfe:	8082                	ret

0000000080003d00 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d00:	457c                	lw	a5,76(a0)
    80003d02:	0ed7e863          	bltu	a5,a3,80003df2 <readi+0xf2>
{
    80003d06:	7159                	addi	sp,sp,-112
    80003d08:	f486                	sd	ra,104(sp)
    80003d0a:	f0a2                	sd	s0,96(sp)
    80003d0c:	eca6                	sd	s1,88(sp)
    80003d0e:	e8ca                	sd	s2,80(sp)
    80003d10:	e4ce                	sd	s3,72(sp)
    80003d12:	e0d2                	sd	s4,64(sp)
    80003d14:	fc56                	sd	s5,56(sp)
    80003d16:	f85a                	sd	s6,48(sp)
    80003d18:	f45e                	sd	s7,40(sp)
    80003d1a:	f062                	sd	s8,32(sp)
    80003d1c:	ec66                	sd	s9,24(sp)
    80003d1e:	e86a                	sd	s10,16(sp)
    80003d20:	e46e                	sd	s11,8(sp)
    80003d22:	1880                	addi	s0,sp,112
    80003d24:	8baa                	mv	s7,a0
    80003d26:	8c2e                	mv	s8,a1
    80003d28:	8ab2                	mv	s5,a2
    80003d2a:	84b6                	mv	s1,a3
    80003d2c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d2e:	9f35                	addw	a4,a4,a3
    return 0;
    80003d30:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d32:	08d76f63          	bltu	a4,a3,80003dd0 <readi+0xd0>
  if(off + n > ip->size)
    80003d36:	00e7f463          	bgeu	a5,a4,80003d3e <readi+0x3e>
    n = ip->size - off;
    80003d3a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d3e:	0a0b0863          	beqz	s6,80003dee <readi+0xee>
    80003d42:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d44:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d48:	5cfd                	li	s9,-1
    80003d4a:	a82d                	j	80003d84 <readi+0x84>
    80003d4c:	020a1d93          	slli	s11,s4,0x20
    80003d50:	020ddd93          	srli	s11,s11,0x20
    80003d54:	05890613          	addi	a2,s2,88
    80003d58:	86ee                	mv	a3,s11
    80003d5a:	963a                	add	a2,a2,a4
    80003d5c:	85d6                	mv	a1,s5
    80003d5e:	8562                	mv	a0,s8
    80003d60:	fffff097          	auipc	ra,0xfffff
    80003d64:	afa080e7          	jalr	-1286(ra) # 8000285a <either_copyout>
    80003d68:	05950d63          	beq	a0,s9,80003dc2 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003d6c:	854a                	mv	a0,s2
    80003d6e:	fffff097          	auipc	ra,0xfffff
    80003d72:	60c080e7          	jalr	1548(ra) # 8000337a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d76:	013a09bb          	addw	s3,s4,s3
    80003d7a:	009a04bb          	addw	s1,s4,s1
    80003d7e:	9aee                	add	s5,s5,s11
    80003d80:	0569f663          	bgeu	s3,s6,80003dcc <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d84:	000ba903          	lw	s2,0(s7)
    80003d88:	00a4d59b          	srliw	a1,s1,0xa
    80003d8c:	855e                	mv	a0,s7
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	8b0080e7          	jalr	-1872(ra) # 8000363e <bmap>
    80003d96:	0005059b          	sext.w	a1,a0
    80003d9a:	854a                	mv	a0,s2
    80003d9c:	fffff097          	auipc	ra,0xfffff
    80003da0:	4ae080e7          	jalr	1198(ra) # 8000324a <bread>
    80003da4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003da6:	3ff4f713          	andi	a4,s1,1023
    80003daa:	40ed07bb          	subw	a5,s10,a4
    80003dae:	413b06bb          	subw	a3,s6,s3
    80003db2:	8a3e                	mv	s4,a5
    80003db4:	2781                	sext.w	a5,a5
    80003db6:	0006861b          	sext.w	a2,a3
    80003dba:	f8f679e3          	bgeu	a2,a5,80003d4c <readi+0x4c>
    80003dbe:	8a36                	mv	s4,a3
    80003dc0:	b771                	j	80003d4c <readi+0x4c>
      brelse(bp);
    80003dc2:	854a                	mv	a0,s2
    80003dc4:	fffff097          	auipc	ra,0xfffff
    80003dc8:	5b6080e7          	jalr	1462(ra) # 8000337a <brelse>
  }
  return tot;
    80003dcc:	0009851b          	sext.w	a0,s3
}
    80003dd0:	70a6                	ld	ra,104(sp)
    80003dd2:	7406                	ld	s0,96(sp)
    80003dd4:	64e6                	ld	s1,88(sp)
    80003dd6:	6946                	ld	s2,80(sp)
    80003dd8:	69a6                	ld	s3,72(sp)
    80003dda:	6a06                	ld	s4,64(sp)
    80003ddc:	7ae2                	ld	s5,56(sp)
    80003dde:	7b42                	ld	s6,48(sp)
    80003de0:	7ba2                	ld	s7,40(sp)
    80003de2:	7c02                	ld	s8,32(sp)
    80003de4:	6ce2                	ld	s9,24(sp)
    80003de6:	6d42                	ld	s10,16(sp)
    80003de8:	6da2                	ld	s11,8(sp)
    80003dea:	6165                	addi	sp,sp,112
    80003dec:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dee:	89da                	mv	s3,s6
    80003df0:	bff1                	j	80003dcc <readi+0xcc>
    return 0;
    80003df2:	4501                	li	a0,0
}
    80003df4:	8082                	ret

0000000080003df6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003df6:	457c                	lw	a5,76(a0)
    80003df8:	10d7e663          	bltu	a5,a3,80003f04 <writei+0x10e>
{
    80003dfc:	7159                	addi	sp,sp,-112
    80003dfe:	f486                	sd	ra,104(sp)
    80003e00:	f0a2                	sd	s0,96(sp)
    80003e02:	eca6                	sd	s1,88(sp)
    80003e04:	e8ca                	sd	s2,80(sp)
    80003e06:	e4ce                	sd	s3,72(sp)
    80003e08:	e0d2                	sd	s4,64(sp)
    80003e0a:	fc56                	sd	s5,56(sp)
    80003e0c:	f85a                	sd	s6,48(sp)
    80003e0e:	f45e                	sd	s7,40(sp)
    80003e10:	f062                	sd	s8,32(sp)
    80003e12:	ec66                	sd	s9,24(sp)
    80003e14:	e86a                	sd	s10,16(sp)
    80003e16:	e46e                	sd	s11,8(sp)
    80003e18:	1880                	addi	s0,sp,112
    80003e1a:	8baa                	mv	s7,a0
    80003e1c:	8c2e                	mv	s8,a1
    80003e1e:	8ab2                	mv	s5,a2
    80003e20:	8936                	mv	s2,a3
    80003e22:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e24:	00e687bb          	addw	a5,a3,a4
    80003e28:	0ed7e063          	bltu	a5,a3,80003f08 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e2c:	00043737          	lui	a4,0x43
    80003e30:	0cf76e63          	bltu	a4,a5,80003f0c <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e34:	0a0b0763          	beqz	s6,80003ee2 <writei+0xec>
    80003e38:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e3a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e3e:	5cfd                	li	s9,-1
    80003e40:	a091                	j	80003e84 <writei+0x8e>
    80003e42:	02099d93          	slli	s11,s3,0x20
    80003e46:	020ddd93          	srli	s11,s11,0x20
    80003e4a:	05848513          	addi	a0,s1,88
    80003e4e:	86ee                	mv	a3,s11
    80003e50:	8656                	mv	a2,s5
    80003e52:	85e2                	mv	a1,s8
    80003e54:	953a                	add	a0,a0,a4
    80003e56:	fffff097          	auipc	ra,0xfffff
    80003e5a:	a5a080e7          	jalr	-1446(ra) # 800028b0 <either_copyin>
    80003e5e:	07950263          	beq	a0,s9,80003ec2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e62:	8526                	mv	a0,s1
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	77a080e7          	jalr	1914(ra) # 800045de <log_write>
    brelse(bp);
    80003e6c:	8526                	mv	a0,s1
    80003e6e:	fffff097          	auipc	ra,0xfffff
    80003e72:	50c080e7          	jalr	1292(ra) # 8000337a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e76:	01498a3b          	addw	s4,s3,s4
    80003e7a:	0129893b          	addw	s2,s3,s2
    80003e7e:	9aee                	add	s5,s5,s11
    80003e80:	056a7663          	bgeu	s4,s6,80003ecc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e84:	000ba483          	lw	s1,0(s7)
    80003e88:	00a9559b          	srliw	a1,s2,0xa
    80003e8c:	855e                	mv	a0,s7
    80003e8e:	fffff097          	auipc	ra,0xfffff
    80003e92:	7b0080e7          	jalr	1968(ra) # 8000363e <bmap>
    80003e96:	0005059b          	sext.w	a1,a0
    80003e9a:	8526                	mv	a0,s1
    80003e9c:	fffff097          	auipc	ra,0xfffff
    80003ea0:	3ae080e7          	jalr	942(ra) # 8000324a <bread>
    80003ea4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ea6:	3ff97713          	andi	a4,s2,1023
    80003eaa:	40ed07bb          	subw	a5,s10,a4
    80003eae:	414b06bb          	subw	a3,s6,s4
    80003eb2:	89be                	mv	s3,a5
    80003eb4:	2781                	sext.w	a5,a5
    80003eb6:	0006861b          	sext.w	a2,a3
    80003eba:	f8f674e3          	bgeu	a2,a5,80003e42 <writei+0x4c>
    80003ebe:	89b6                	mv	s3,a3
    80003ec0:	b749                	j	80003e42 <writei+0x4c>
      brelse(bp);
    80003ec2:	8526                	mv	a0,s1
    80003ec4:	fffff097          	auipc	ra,0xfffff
    80003ec8:	4b6080e7          	jalr	1206(ra) # 8000337a <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003ecc:	04cba783          	lw	a5,76(s7)
    80003ed0:	0127f463          	bgeu	a5,s2,80003ed8 <writei+0xe2>
      ip->size = off;
    80003ed4:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003ed8:	855e                	mv	a0,s7
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	aa8080e7          	jalr	-1368(ra) # 80003982 <iupdate>
  }

  return n;
    80003ee2:	000b051b          	sext.w	a0,s6
}
    80003ee6:	70a6                	ld	ra,104(sp)
    80003ee8:	7406                	ld	s0,96(sp)
    80003eea:	64e6                	ld	s1,88(sp)
    80003eec:	6946                	ld	s2,80(sp)
    80003eee:	69a6                	ld	s3,72(sp)
    80003ef0:	6a06                	ld	s4,64(sp)
    80003ef2:	7ae2                	ld	s5,56(sp)
    80003ef4:	7b42                	ld	s6,48(sp)
    80003ef6:	7ba2                	ld	s7,40(sp)
    80003ef8:	7c02                	ld	s8,32(sp)
    80003efa:	6ce2                	ld	s9,24(sp)
    80003efc:	6d42                	ld	s10,16(sp)
    80003efe:	6da2                	ld	s11,8(sp)
    80003f00:	6165                	addi	sp,sp,112
    80003f02:	8082                	ret
    return -1;
    80003f04:	557d                	li	a0,-1
}
    80003f06:	8082                	ret
    return -1;
    80003f08:	557d                	li	a0,-1
    80003f0a:	bff1                	j	80003ee6 <writei+0xf0>
    return -1;
    80003f0c:	557d                	li	a0,-1
    80003f0e:	bfe1                	j	80003ee6 <writei+0xf0>

0000000080003f10 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f10:	1141                	addi	sp,sp,-16
    80003f12:	e406                	sd	ra,8(sp)
    80003f14:	e022                	sd	s0,0(sp)
    80003f16:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f18:	4639                	li	a2,14
    80003f1a:	ffffd097          	auipc	ra,0xffffd
    80003f1e:	ece080e7          	jalr	-306(ra) # 80000de8 <strncmp>
}
    80003f22:	60a2                	ld	ra,8(sp)
    80003f24:	6402                	ld	s0,0(sp)
    80003f26:	0141                	addi	sp,sp,16
    80003f28:	8082                	ret

0000000080003f2a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f2a:	7139                	addi	sp,sp,-64
    80003f2c:	fc06                	sd	ra,56(sp)
    80003f2e:	f822                	sd	s0,48(sp)
    80003f30:	f426                	sd	s1,40(sp)
    80003f32:	f04a                	sd	s2,32(sp)
    80003f34:	ec4e                	sd	s3,24(sp)
    80003f36:	e852                	sd	s4,16(sp)
    80003f38:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f3a:	04451703          	lh	a4,68(a0)
    80003f3e:	4785                	li	a5,1
    80003f40:	00f71a63          	bne	a4,a5,80003f54 <dirlookup+0x2a>
    80003f44:	892a                	mv	s2,a0
    80003f46:	89ae                	mv	s3,a1
    80003f48:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f4a:	457c                	lw	a5,76(a0)
    80003f4c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f4e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f50:	e79d                	bnez	a5,80003f7e <dirlookup+0x54>
    80003f52:	a8a5                	j	80003fca <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f54:	00004517          	auipc	a0,0x4
    80003f58:	75c50513          	addi	a0,a0,1884 # 800086b0 <syscalls+0x1a0>
    80003f5c:	ffffc097          	auipc	ra,0xffffc
    80003f60:	5ec080e7          	jalr	1516(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003f64:	00004517          	auipc	a0,0x4
    80003f68:	76450513          	addi	a0,a0,1892 # 800086c8 <syscalls+0x1b8>
    80003f6c:	ffffc097          	auipc	ra,0xffffc
    80003f70:	5dc080e7          	jalr	1500(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f74:	24c1                	addiw	s1,s1,16
    80003f76:	04c92783          	lw	a5,76(s2)
    80003f7a:	04f4f763          	bgeu	s1,a5,80003fc8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f7e:	4741                	li	a4,16
    80003f80:	86a6                	mv	a3,s1
    80003f82:	fc040613          	addi	a2,s0,-64
    80003f86:	4581                	li	a1,0
    80003f88:	854a                	mv	a0,s2
    80003f8a:	00000097          	auipc	ra,0x0
    80003f8e:	d76080e7          	jalr	-650(ra) # 80003d00 <readi>
    80003f92:	47c1                	li	a5,16
    80003f94:	fcf518e3          	bne	a0,a5,80003f64 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f98:	fc045783          	lhu	a5,-64(s0)
    80003f9c:	dfe1                	beqz	a5,80003f74 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f9e:	fc240593          	addi	a1,s0,-62
    80003fa2:	854e                	mv	a0,s3
    80003fa4:	00000097          	auipc	ra,0x0
    80003fa8:	f6c080e7          	jalr	-148(ra) # 80003f10 <namecmp>
    80003fac:	f561                	bnez	a0,80003f74 <dirlookup+0x4a>
      if(poff)
    80003fae:	000a0463          	beqz	s4,80003fb6 <dirlookup+0x8c>
        *poff = off;
    80003fb2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003fb6:	fc045583          	lhu	a1,-64(s0)
    80003fba:	00092503          	lw	a0,0(s2)
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	75a080e7          	jalr	1882(ra) # 80003718 <iget>
    80003fc6:	a011                	j	80003fca <dirlookup+0xa0>
  return 0;
    80003fc8:	4501                	li	a0,0
}
    80003fca:	70e2                	ld	ra,56(sp)
    80003fcc:	7442                	ld	s0,48(sp)
    80003fce:	74a2                	ld	s1,40(sp)
    80003fd0:	7902                	ld	s2,32(sp)
    80003fd2:	69e2                	ld	s3,24(sp)
    80003fd4:	6a42                	ld	s4,16(sp)
    80003fd6:	6121                	addi	sp,sp,64
    80003fd8:	8082                	ret

0000000080003fda <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003fda:	711d                	addi	sp,sp,-96
    80003fdc:	ec86                	sd	ra,88(sp)
    80003fde:	e8a2                	sd	s0,80(sp)
    80003fe0:	e4a6                	sd	s1,72(sp)
    80003fe2:	e0ca                	sd	s2,64(sp)
    80003fe4:	fc4e                	sd	s3,56(sp)
    80003fe6:	f852                	sd	s4,48(sp)
    80003fe8:	f456                	sd	s5,40(sp)
    80003fea:	f05a                	sd	s6,32(sp)
    80003fec:	ec5e                	sd	s7,24(sp)
    80003fee:	e862                	sd	s8,16(sp)
    80003ff0:	e466                	sd	s9,8(sp)
    80003ff2:	1080                	addi	s0,sp,96
    80003ff4:	84aa                	mv	s1,a0
    80003ff6:	8b2e                	mv	s6,a1
    80003ff8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ffa:	00054703          	lbu	a4,0(a0)
    80003ffe:	02f00793          	li	a5,47
    80004002:	02f70363          	beq	a4,a5,80004028 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004006:	ffffe097          	auipc	ra,0xffffe
    8000400a:	cde080e7          	jalr	-802(ra) # 80001ce4 <myproc>
    8000400e:	16053503          	ld	a0,352(a0)
    80004012:	00000097          	auipc	ra,0x0
    80004016:	9fc080e7          	jalr	-1540(ra) # 80003a0e <idup>
    8000401a:	89aa                	mv	s3,a0
  while(*path == '/')
    8000401c:	02f00913          	li	s2,47
  len = path - s;
    80004020:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004022:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004024:	4c05                	li	s8,1
    80004026:	a865                	j	800040de <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004028:	4585                	li	a1,1
    8000402a:	4505                	li	a0,1
    8000402c:	fffff097          	auipc	ra,0xfffff
    80004030:	6ec080e7          	jalr	1772(ra) # 80003718 <iget>
    80004034:	89aa                	mv	s3,a0
    80004036:	b7dd                	j	8000401c <namex+0x42>
      iunlockput(ip);
    80004038:	854e                	mv	a0,s3
    8000403a:	00000097          	auipc	ra,0x0
    8000403e:	c74080e7          	jalr	-908(ra) # 80003cae <iunlockput>
      return 0;
    80004042:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004044:	854e                	mv	a0,s3
    80004046:	60e6                	ld	ra,88(sp)
    80004048:	6446                	ld	s0,80(sp)
    8000404a:	64a6                	ld	s1,72(sp)
    8000404c:	6906                	ld	s2,64(sp)
    8000404e:	79e2                	ld	s3,56(sp)
    80004050:	7a42                	ld	s4,48(sp)
    80004052:	7aa2                	ld	s5,40(sp)
    80004054:	7b02                	ld	s6,32(sp)
    80004056:	6be2                	ld	s7,24(sp)
    80004058:	6c42                	ld	s8,16(sp)
    8000405a:	6ca2                	ld	s9,8(sp)
    8000405c:	6125                	addi	sp,sp,96
    8000405e:	8082                	ret
      iunlock(ip);
    80004060:	854e                	mv	a0,s3
    80004062:	00000097          	auipc	ra,0x0
    80004066:	aac080e7          	jalr	-1364(ra) # 80003b0e <iunlock>
      return ip;
    8000406a:	bfe9                	j	80004044 <namex+0x6a>
      iunlockput(ip);
    8000406c:	854e                	mv	a0,s3
    8000406e:	00000097          	auipc	ra,0x0
    80004072:	c40080e7          	jalr	-960(ra) # 80003cae <iunlockput>
      return 0;
    80004076:	89d2                	mv	s3,s4
    80004078:	b7f1                	j	80004044 <namex+0x6a>
  len = path - s;
    8000407a:	40b48633          	sub	a2,s1,a1
    8000407e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004082:	094cd463          	bge	s9,s4,8000410a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004086:	4639                	li	a2,14
    80004088:	8556                	mv	a0,s5
    8000408a:	ffffd097          	auipc	ra,0xffffd
    8000408e:	ce2080e7          	jalr	-798(ra) # 80000d6c <memmove>
  while(*path == '/')
    80004092:	0004c783          	lbu	a5,0(s1)
    80004096:	01279763          	bne	a5,s2,800040a4 <namex+0xca>
    path++;
    8000409a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000409c:	0004c783          	lbu	a5,0(s1)
    800040a0:	ff278de3          	beq	a5,s2,8000409a <namex+0xc0>
    ilock(ip);
    800040a4:	854e                	mv	a0,s3
    800040a6:	00000097          	auipc	ra,0x0
    800040aa:	9a6080e7          	jalr	-1626(ra) # 80003a4c <ilock>
    if(ip->type != T_DIR){
    800040ae:	04499783          	lh	a5,68(s3)
    800040b2:	f98793e3          	bne	a5,s8,80004038 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800040b6:	000b0563          	beqz	s6,800040c0 <namex+0xe6>
    800040ba:	0004c783          	lbu	a5,0(s1)
    800040be:	d3cd                	beqz	a5,80004060 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040c0:	865e                	mv	a2,s7
    800040c2:	85d6                	mv	a1,s5
    800040c4:	854e                	mv	a0,s3
    800040c6:	00000097          	auipc	ra,0x0
    800040ca:	e64080e7          	jalr	-412(ra) # 80003f2a <dirlookup>
    800040ce:	8a2a                	mv	s4,a0
    800040d0:	dd51                	beqz	a0,8000406c <namex+0x92>
    iunlockput(ip);
    800040d2:	854e                	mv	a0,s3
    800040d4:	00000097          	auipc	ra,0x0
    800040d8:	bda080e7          	jalr	-1062(ra) # 80003cae <iunlockput>
    ip = next;
    800040dc:	89d2                	mv	s3,s4
  while(*path == '/')
    800040de:	0004c783          	lbu	a5,0(s1)
    800040e2:	05279763          	bne	a5,s2,80004130 <namex+0x156>
    path++;
    800040e6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040e8:	0004c783          	lbu	a5,0(s1)
    800040ec:	ff278de3          	beq	a5,s2,800040e6 <namex+0x10c>
  if(*path == 0)
    800040f0:	c79d                	beqz	a5,8000411e <namex+0x144>
    path++;
    800040f2:	85a6                	mv	a1,s1
  len = path - s;
    800040f4:	8a5e                	mv	s4,s7
    800040f6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800040f8:	01278963          	beq	a5,s2,8000410a <namex+0x130>
    800040fc:	dfbd                	beqz	a5,8000407a <namex+0xa0>
    path++;
    800040fe:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004100:	0004c783          	lbu	a5,0(s1)
    80004104:	ff279ce3          	bne	a5,s2,800040fc <namex+0x122>
    80004108:	bf8d                	j	8000407a <namex+0xa0>
    memmove(name, s, len);
    8000410a:	2601                	sext.w	a2,a2
    8000410c:	8556                	mv	a0,s5
    8000410e:	ffffd097          	auipc	ra,0xffffd
    80004112:	c5e080e7          	jalr	-930(ra) # 80000d6c <memmove>
    name[len] = 0;
    80004116:	9a56                	add	s4,s4,s5
    80004118:	000a0023          	sb	zero,0(s4)
    8000411c:	bf9d                	j	80004092 <namex+0xb8>
  if(nameiparent){
    8000411e:	f20b03e3          	beqz	s6,80004044 <namex+0x6a>
    iput(ip);
    80004122:	854e                	mv	a0,s3
    80004124:	00000097          	auipc	ra,0x0
    80004128:	ae2080e7          	jalr	-1310(ra) # 80003c06 <iput>
    return 0;
    8000412c:	4981                	li	s3,0
    8000412e:	bf19                	j	80004044 <namex+0x6a>
  if(*path == 0)
    80004130:	d7fd                	beqz	a5,8000411e <namex+0x144>
  while(*path != '/' && *path != 0)
    80004132:	0004c783          	lbu	a5,0(s1)
    80004136:	85a6                	mv	a1,s1
    80004138:	b7d1                	j	800040fc <namex+0x122>

000000008000413a <dirlink>:
{
    8000413a:	7139                	addi	sp,sp,-64
    8000413c:	fc06                	sd	ra,56(sp)
    8000413e:	f822                	sd	s0,48(sp)
    80004140:	f426                	sd	s1,40(sp)
    80004142:	f04a                	sd	s2,32(sp)
    80004144:	ec4e                	sd	s3,24(sp)
    80004146:	e852                	sd	s4,16(sp)
    80004148:	0080                	addi	s0,sp,64
    8000414a:	892a                	mv	s2,a0
    8000414c:	8a2e                	mv	s4,a1
    8000414e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004150:	4601                	li	a2,0
    80004152:	00000097          	auipc	ra,0x0
    80004156:	dd8080e7          	jalr	-552(ra) # 80003f2a <dirlookup>
    8000415a:	e93d                	bnez	a0,800041d0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000415c:	04c92483          	lw	s1,76(s2)
    80004160:	c49d                	beqz	s1,8000418e <dirlink+0x54>
    80004162:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004164:	4741                	li	a4,16
    80004166:	86a6                	mv	a3,s1
    80004168:	fc040613          	addi	a2,s0,-64
    8000416c:	4581                	li	a1,0
    8000416e:	854a                	mv	a0,s2
    80004170:	00000097          	auipc	ra,0x0
    80004174:	b90080e7          	jalr	-1136(ra) # 80003d00 <readi>
    80004178:	47c1                	li	a5,16
    8000417a:	06f51163          	bne	a0,a5,800041dc <dirlink+0xa2>
    if(de.inum == 0)
    8000417e:	fc045783          	lhu	a5,-64(s0)
    80004182:	c791                	beqz	a5,8000418e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004184:	24c1                	addiw	s1,s1,16
    80004186:	04c92783          	lw	a5,76(s2)
    8000418a:	fcf4ede3          	bltu	s1,a5,80004164 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000418e:	4639                	li	a2,14
    80004190:	85d2                	mv	a1,s4
    80004192:	fc240513          	addi	a0,s0,-62
    80004196:	ffffd097          	auipc	ra,0xffffd
    8000419a:	c8e080e7          	jalr	-882(ra) # 80000e24 <strncpy>
  de.inum = inum;
    8000419e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041a2:	4741                	li	a4,16
    800041a4:	86a6                	mv	a3,s1
    800041a6:	fc040613          	addi	a2,s0,-64
    800041aa:	4581                	li	a1,0
    800041ac:	854a                	mv	a0,s2
    800041ae:	00000097          	auipc	ra,0x0
    800041b2:	c48080e7          	jalr	-952(ra) # 80003df6 <writei>
    800041b6:	872a                	mv	a4,a0
    800041b8:	47c1                	li	a5,16
  return 0;
    800041ba:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041bc:	02f71863          	bne	a4,a5,800041ec <dirlink+0xb2>
}
    800041c0:	70e2                	ld	ra,56(sp)
    800041c2:	7442                	ld	s0,48(sp)
    800041c4:	74a2                	ld	s1,40(sp)
    800041c6:	7902                	ld	s2,32(sp)
    800041c8:	69e2                	ld	s3,24(sp)
    800041ca:	6a42                	ld	s4,16(sp)
    800041cc:	6121                	addi	sp,sp,64
    800041ce:	8082                	ret
    iput(ip);
    800041d0:	00000097          	auipc	ra,0x0
    800041d4:	a36080e7          	jalr	-1482(ra) # 80003c06 <iput>
    return -1;
    800041d8:	557d                	li	a0,-1
    800041da:	b7dd                	j	800041c0 <dirlink+0x86>
      panic("dirlink read");
    800041dc:	00004517          	auipc	a0,0x4
    800041e0:	4fc50513          	addi	a0,a0,1276 # 800086d8 <syscalls+0x1c8>
    800041e4:	ffffc097          	auipc	ra,0xffffc
    800041e8:	364080e7          	jalr	868(ra) # 80000548 <panic>
    panic("dirlink");
    800041ec:	00004517          	auipc	a0,0x4
    800041f0:	60c50513          	addi	a0,a0,1548 # 800087f8 <syscalls+0x2e8>
    800041f4:	ffffc097          	auipc	ra,0xffffc
    800041f8:	354080e7          	jalr	852(ra) # 80000548 <panic>

00000000800041fc <namei>:

struct inode*
namei(char *path)
{
    800041fc:	1101                	addi	sp,sp,-32
    800041fe:	ec06                	sd	ra,24(sp)
    80004200:	e822                	sd	s0,16(sp)
    80004202:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004204:	fe040613          	addi	a2,s0,-32
    80004208:	4581                	li	a1,0
    8000420a:	00000097          	auipc	ra,0x0
    8000420e:	dd0080e7          	jalr	-560(ra) # 80003fda <namex>
}
    80004212:	60e2                	ld	ra,24(sp)
    80004214:	6442                	ld	s0,16(sp)
    80004216:	6105                	addi	sp,sp,32
    80004218:	8082                	ret

000000008000421a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000421a:	1141                	addi	sp,sp,-16
    8000421c:	e406                	sd	ra,8(sp)
    8000421e:	e022                	sd	s0,0(sp)
    80004220:	0800                	addi	s0,sp,16
    80004222:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004224:	4585                	li	a1,1
    80004226:	00000097          	auipc	ra,0x0
    8000422a:	db4080e7          	jalr	-588(ra) # 80003fda <namex>
}
    8000422e:	60a2                	ld	ra,8(sp)
    80004230:	6402                	ld	s0,0(sp)
    80004232:	0141                	addi	sp,sp,16
    80004234:	8082                	ret

0000000080004236 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004236:	1101                	addi	sp,sp,-32
    80004238:	ec06                	sd	ra,24(sp)
    8000423a:	e822                	sd	s0,16(sp)
    8000423c:	e426                	sd	s1,8(sp)
    8000423e:	e04a                	sd	s2,0(sp)
    80004240:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004242:	0001e917          	auipc	s2,0x1e
    80004246:	ac690913          	addi	s2,s2,-1338 # 80021d08 <log>
    8000424a:	01892583          	lw	a1,24(s2)
    8000424e:	02892503          	lw	a0,40(s2)
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	ff8080e7          	jalr	-8(ra) # 8000324a <bread>
    8000425a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000425c:	02c92683          	lw	a3,44(s2)
    80004260:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004262:	02d05763          	blez	a3,80004290 <write_head+0x5a>
    80004266:	0001e797          	auipc	a5,0x1e
    8000426a:	ad278793          	addi	a5,a5,-1326 # 80021d38 <log+0x30>
    8000426e:	05c50713          	addi	a4,a0,92
    80004272:	36fd                	addiw	a3,a3,-1
    80004274:	1682                	slli	a3,a3,0x20
    80004276:	9281                	srli	a3,a3,0x20
    80004278:	068a                	slli	a3,a3,0x2
    8000427a:	0001e617          	auipc	a2,0x1e
    8000427e:	ac260613          	addi	a2,a2,-1342 # 80021d3c <log+0x34>
    80004282:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004284:	4390                	lw	a2,0(a5)
    80004286:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004288:	0791                	addi	a5,a5,4
    8000428a:	0711                	addi	a4,a4,4
    8000428c:	fed79ce3          	bne	a5,a3,80004284 <write_head+0x4e>
  }
  bwrite(buf);
    80004290:	8526                	mv	a0,s1
    80004292:	fffff097          	auipc	ra,0xfffff
    80004296:	0aa080e7          	jalr	170(ra) # 8000333c <bwrite>
  brelse(buf);
    8000429a:	8526                	mv	a0,s1
    8000429c:	fffff097          	auipc	ra,0xfffff
    800042a0:	0de080e7          	jalr	222(ra) # 8000337a <brelse>
}
    800042a4:	60e2                	ld	ra,24(sp)
    800042a6:	6442                	ld	s0,16(sp)
    800042a8:	64a2                	ld	s1,8(sp)
    800042aa:	6902                	ld	s2,0(sp)
    800042ac:	6105                	addi	sp,sp,32
    800042ae:	8082                	ret

00000000800042b0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b0:	0001e797          	auipc	a5,0x1e
    800042b4:	a847a783          	lw	a5,-1404(a5) # 80021d34 <log+0x2c>
    800042b8:	0af05663          	blez	a5,80004364 <install_trans+0xb4>
{
    800042bc:	7139                	addi	sp,sp,-64
    800042be:	fc06                	sd	ra,56(sp)
    800042c0:	f822                	sd	s0,48(sp)
    800042c2:	f426                	sd	s1,40(sp)
    800042c4:	f04a                	sd	s2,32(sp)
    800042c6:	ec4e                	sd	s3,24(sp)
    800042c8:	e852                	sd	s4,16(sp)
    800042ca:	e456                	sd	s5,8(sp)
    800042cc:	0080                	addi	s0,sp,64
    800042ce:	0001ea97          	auipc	s5,0x1e
    800042d2:	a6aa8a93          	addi	s5,s5,-1430 # 80021d38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042d6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042d8:	0001e997          	auipc	s3,0x1e
    800042dc:	a3098993          	addi	s3,s3,-1488 # 80021d08 <log>
    800042e0:	0189a583          	lw	a1,24(s3)
    800042e4:	014585bb          	addw	a1,a1,s4
    800042e8:	2585                	addiw	a1,a1,1
    800042ea:	0289a503          	lw	a0,40(s3)
    800042ee:	fffff097          	auipc	ra,0xfffff
    800042f2:	f5c080e7          	jalr	-164(ra) # 8000324a <bread>
    800042f6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042f8:	000aa583          	lw	a1,0(s5)
    800042fc:	0289a503          	lw	a0,40(s3)
    80004300:	fffff097          	auipc	ra,0xfffff
    80004304:	f4a080e7          	jalr	-182(ra) # 8000324a <bread>
    80004308:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000430a:	40000613          	li	a2,1024
    8000430e:	05890593          	addi	a1,s2,88
    80004312:	05850513          	addi	a0,a0,88
    80004316:	ffffd097          	auipc	ra,0xffffd
    8000431a:	a56080e7          	jalr	-1450(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    8000431e:	8526                	mv	a0,s1
    80004320:	fffff097          	auipc	ra,0xfffff
    80004324:	01c080e7          	jalr	28(ra) # 8000333c <bwrite>
    bunpin(dbuf);
    80004328:	8526                	mv	a0,s1
    8000432a:	fffff097          	auipc	ra,0xfffff
    8000432e:	12a080e7          	jalr	298(ra) # 80003454 <bunpin>
    brelse(lbuf);
    80004332:	854a                	mv	a0,s2
    80004334:	fffff097          	auipc	ra,0xfffff
    80004338:	046080e7          	jalr	70(ra) # 8000337a <brelse>
    brelse(dbuf);
    8000433c:	8526                	mv	a0,s1
    8000433e:	fffff097          	auipc	ra,0xfffff
    80004342:	03c080e7          	jalr	60(ra) # 8000337a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004346:	2a05                	addiw	s4,s4,1
    80004348:	0a91                	addi	s5,s5,4
    8000434a:	02c9a783          	lw	a5,44(s3)
    8000434e:	f8fa49e3          	blt	s4,a5,800042e0 <install_trans+0x30>
}
    80004352:	70e2                	ld	ra,56(sp)
    80004354:	7442                	ld	s0,48(sp)
    80004356:	74a2                	ld	s1,40(sp)
    80004358:	7902                	ld	s2,32(sp)
    8000435a:	69e2                	ld	s3,24(sp)
    8000435c:	6a42                	ld	s4,16(sp)
    8000435e:	6aa2                	ld	s5,8(sp)
    80004360:	6121                	addi	sp,sp,64
    80004362:	8082                	ret
    80004364:	8082                	ret

0000000080004366 <initlog>:
{
    80004366:	7179                	addi	sp,sp,-48
    80004368:	f406                	sd	ra,40(sp)
    8000436a:	f022                	sd	s0,32(sp)
    8000436c:	ec26                	sd	s1,24(sp)
    8000436e:	e84a                	sd	s2,16(sp)
    80004370:	e44e                	sd	s3,8(sp)
    80004372:	1800                	addi	s0,sp,48
    80004374:	892a                	mv	s2,a0
    80004376:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004378:	0001e497          	auipc	s1,0x1e
    8000437c:	99048493          	addi	s1,s1,-1648 # 80021d08 <log>
    80004380:	00004597          	auipc	a1,0x4
    80004384:	36858593          	addi	a1,a1,872 # 800086e8 <syscalls+0x1d8>
    80004388:	8526                	mv	a0,s1
    8000438a:	ffffc097          	auipc	ra,0xffffc
    8000438e:	7f6080e7          	jalr	2038(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    80004392:	0149a583          	lw	a1,20(s3)
    80004396:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004398:	0109a783          	lw	a5,16(s3)
    8000439c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000439e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800043a2:	854a                	mv	a0,s2
    800043a4:	fffff097          	auipc	ra,0xfffff
    800043a8:	ea6080e7          	jalr	-346(ra) # 8000324a <bread>
  log.lh.n = lh->n;
    800043ac:	4d3c                	lw	a5,88(a0)
    800043ae:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800043b0:	02f05563          	blez	a5,800043da <initlog+0x74>
    800043b4:	05c50713          	addi	a4,a0,92
    800043b8:	0001e697          	auipc	a3,0x1e
    800043bc:	98068693          	addi	a3,a3,-1664 # 80021d38 <log+0x30>
    800043c0:	37fd                	addiw	a5,a5,-1
    800043c2:	1782                	slli	a5,a5,0x20
    800043c4:	9381                	srli	a5,a5,0x20
    800043c6:	078a                	slli	a5,a5,0x2
    800043c8:	06050613          	addi	a2,a0,96
    800043cc:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800043ce:	4310                	lw	a2,0(a4)
    800043d0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800043d2:	0711                	addi	a4,a4,4
    800043d4:	0691                	addi	a3,a3,4
    800043d6:	fef71ce3          	bne	a4,a5,800043ce <initlog+0x68>
  brelse(buf);
    800043da:	fffff097          	auipc	ra,0xfffff
    800043de:	fa0080e7          	jalr	-96(ra) # 8000337a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800043e2:	00000097          	auipc	ra,0x0
    800043e6:	ece080e7          	jalr	-306(ra) # 800042b0 <install_trans>
  log.lh.n = 0;
    800043ea:	0001e797          	auipc	a5,0x1e
    800043ee:	9407a523          	sw	zero,-1718(a5) # 80021d34 <log+0x2c>
  write_head(); // clear the log
    800043f2:	00000097          	auipc	ra,0x0
    800043f6:	e44080e7          	jalr	-444(ra) # 80004236 <write_head>
}
    800043fa:	70a2                	ld	ra,40(sp)
    800043fc:	7402                	ld	s0,32(sp)
    800043fe:	64e2                	ld	s1,24(sp)
    80004400:	6942                	ld	s2,16(sp)
    80004402:	69a2                	ld	s3,8(sp)
    80004404:	6145                	addi	sp,sp,48
    80004406:	8082                	ret

0000000080004408 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004408:	1101                	addi	sp,sp,-32
    8000440a:	ec06                	sd	ra,24(sp)
    8000440c:	e822                	sd	s0,16(sp)
    8000440e:	e426                	sd	s1,8(sp)
    80004410:	e04a                	sd	s2,0(sp)
    80004412:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004414:	0001e517          	auipc	a0,0x1e
    80004418:	8f450513          	addi	a0,a0,-1804 # 80021d08 <log>
    8000441c:	ffffc097          	auipc	ra,0xffffc
    80004420:	7f4080e7          	jalr	2036(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    80004424:	0001e497          	auipc	s1,0x1e
    80004428:	8e448493          	addi	s1,s1,-1820 # 80021d08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000442c:	4979                	li	s2,30
    8000442e:	a039                	j	8000443c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004430:	85a6                	mv	a1,s1
    80004432:	8526                	mv	a0,s1
    80004434:	ffffe097          	auipc	ra,0xffffe
    80004438:	1c4080e7          	jalr	452(ra) # 800025f8 <sleep>
    if(log.committing){
    8000443c:	50dc                	lw	a5,36(s1)
    8000443e:	fbed                	bnez	a5,80004430 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004440:	509c                	lw	a5,32(s1)
    80004442:	0017871b          	addiw	a4,a5,1
    80004446:	0007069b          	sext.w	a3,a4
    8000444a:	0027179b          	slliw	a5,a4,0x2
    8000444e:	9fb9                	addw	a5,a5,a4
    80004450:	0017979b          	slliw	a5,a5,0x1
    80004454:	54d8                	lw	a4,44(s1)
    80004456:	9fb9                	addw	a5,a5,a4
    80004458:	00f95963          	bge	s2,a5,8000446a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000445c:	85a6                	mv	a1,s1
    8000445e:	8526                	mv	a0,s1
    80004460:	ffffe097          	auipc	ra,0xffffe
    80004464:	198080e7          	jalr	408(ra) # 800025f8 <sleep>
    80004468:	bfd1                	j	8000443c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000446a:	0001e517          	auipc	a0,0x1e
    8000446e:	89e50513          	addi	a0,a0,-1890 # 80021d08 <log>
    80004472:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004474:	ffffd097          	auipc	ra,0xffffd
    80004478:	850080e7          	jalr	-1968(ra) # 80000cc4 <release>
      break;
    }
  }
}
    8000447c:	60e2                	ld	ra,24(sp)
    8000447e:	6442                	ld	s0,16(sp)
    80004480:	64a2                	ld	s1,8(sp)
    80004482:	6902                	ld	s2,0(sp)
    80004484:	6105                	addi	sp,sp,32
    80004486:	8082                	ret

0000000080004488 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004488:	7139                	addi	sp,sp,-64
    8000448a:	fc06                	sd	ra,56(sp)
    8000448c:	f822                	sd	s0,48(sp)
    8000448e:	f426                	sd	s1,40(sp)
    80004490:	f04a                	sd	s2,32(sp)
    80004492:	ec4e                	sd	s3,24(sp)
    80004494:	e852                	sd	s4,16(sp)
    80004496:	e456                	sd	s5,8(sp)
    80004498:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000449a:	0001e497          	auipc	s1,0x1e
    8000449e:	86e48493          	addi	s1,s1,-1938 # 80021d08 <log>
    800044a2:	8526                	mv	a0,s1
    800044a4:	ffffc097          	auipc	ra,0xffffc
    800044a8:	76c080e7          	jalr	1900(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    800044ac:	509c                	lw	a5,32(s1)
    800044ae:	37fd                	addiw	a5,a5,-1
    800044b0:	0007891b          	sext.w	s2,a5
    800044b4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800044b6:	50dc                	lw	a5,36(s1)
    800044b8:	efb9                	bnez	a5,80004516 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044ba:	06091663          	bnez	s2,80004526 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800044be:	0001e497          	auipc	s1,0x1e
    800044c2:	84a48493          	addi	s1,s1,-1974 # 80021d08 <log>
    800044c6:	4785                	li	a5,1
    800044c8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044ca:	8526                	mv	a0,s1
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	7f8080e7          	jalr	2040(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044d4:	54dc                	lw	a5,44(s1)
    800044d6:	06f04763          	bgtz	a5,80004544 <end_op+0xbc>
    acquire(&log.lock);
    800044da:	0001e497          	auipc	s1,0x1e
    800044de:	82e48493          	addi	s1,s1,-2002 # 80021d08 <log>
    800044e2:	8526                	mv	a0,s1
    800044e4:	ffffc097          	auipc	ra,0xffffc
    800044e8:	72c080e7          	jalr	1836(ra) # 80000c10 <acquire>
    log.committing = 0;
    800044ec:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044f0:	8526                	mv	a0,s1
    800044f2:	ffffe097          	auipc	ra,0xffffe
    800044f6:	28c080e7          	jalr	652(ra) # 8000277e <wakeup>
    release(&log.lock);
    800044fa:	8526                	mv	a0,s1
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	7c8080e7          	jalr	1992(ra) # 80000cc4 <release>
}
    80004504:	70e2                	ld	ra,56(sp)
    80004506:	7442                	ld	s0,48(sp)
    80004508:	74a2                	ld	s1,40(sp)
    8000450a:	7902                	ld	s2,32(sp)
    8000450c:	69e2                	ld	s3,24(sp)
    8000450e:	6a42                	ld	s4,16(sp)
    80004510:	6aa2                	ld	s5,8(sp)
    80004512:	6121                	addi	sp,sp,64
    80004514:	8082                	ret
    panic("log.committing");
    80004516:	00004517          	auipc	a0,0x4
    8000451a:	1da50513          	addi	a0,a0,474 # 800086f0 <syscalls+0x1e0>
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	02a080e7          	jalr	42(ra) # 80000548 <panic>
    wakeup(&log);
    80004526:	0001d497          	auipc	s1,0x1d
    8000452a:	7e248493          	addi	s1,s1,2018 # 80021d08 <log>
    8000452e:	8526                	mv	a0,s1
    80004530:	ffffe097          	auipc	ra,0xffffe
    80004534:	24e080e7          	jalr	590(ra) # 8000277e <wakeup>
  release(&log.lock);
    80004538:	8526                	mv	a0,s1
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	78a080e7          	jalr	1930(ra) # 80000cc4 <release>
  if(do_commit){
    80004542:	b7c9                	j	80004504 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004544:	0001da97          	auipc	s5,0x1d
    80004548:	7f4a8a93          	addi	s5,s5,2036 # 80021d38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000454c:	0001da17          	auipc	s4,0x1d
    80004550:	7bca0a13          	addi	s4,s4,1980 # 80021d08 <log>
    80004554:	018a2583          	lw	a1,24(s4)
    80004558:	012585bb          	addw	a1,a1,s2
    8000455c:	2585                	addiw	a1,a1,1
    8000455e:	028a2503          	lw	a0,40(s4)
    80004562:	fffff097          	auipc	ra,0xfffff
    80004566:	ce8080e7          	jalr	-792(ra) # 8000324a <bread>
    8000456a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000456c:	000aa583          	lw	a1,0(s5)
    80004570:	028a2503          	lw	a0,40(s4)
    80004574:	fffff097          	auipc	ra,0xfffff
    80004578:	cd6080e7          	jalr	-810(ra) # 8000324a <bread>
    8000457c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000457e:	40000613          	li	a2,1024
    80004582:	05850593          	addi	a1,a0,88
    80004586:	05848513          	addi	a0,s1,88
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	7e2080e7          	jalr	2018(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    80004592:	8526                	mv	a0,s1
    80004594:	fffff097          	auipc	ra,0xfffff
    80004598:	da8080e7          	jalr	-600(ra) # 8000333c <bwrite>
    brelse(from);
    8000459c:	854e                	mv	a0,s3
    8000459e:	fffff097          	auipc	ra,0xfffff
    800045a2:	ddc080e7          	jalr	-548(ra) # 8000337a <brelse>
    brelse(to);
    800045a6:	8526                	mv	a0,s1
    800045a8:	fffff097          	auipc	ra,0xfffff
    800045ac:	dd2080e7          	jalr	-558(ra) # 8000337a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045b0:	2905                	addiw	s2,s2,1
    800045b2:	0a91                	addi	s5,s5,4
    800045b4:	02ca2783          	lw	a5,44(s4)
    800045b8:	f8f94ee3          	blt	s2,a5,80004554 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800045bc:	00000097          	auipc	ra,0x0
    800045c0:	c7a080e7          	jalr	-902(ra) # 80004236 <write_head>
    install_trans(); // Now install writes to home locations
    800045c4:	00000097          	auipc	ra,0x0
    800045c8:	cec080e7          	jalr	-788(ra) # 800042b0 <install_trans>
    log.lh.n = 0;
    800045cc:	0001d797          	auipc	a5,0x1d
    800045d0:	7607a423          	sw	zero,1896(a5) # 80021d34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045d4:	00000097          	auipc	ra,0x0
    800045d8:	c62080e7          	jalr	-926(ra) # 80004236 <write_head>
    800045dc:	bdfd                	j	800044da <end_op+0x52>

00000000800045de <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045de:	1101                	addi	sp,sp,-32
    800045e0:	ec06                	sd	ra,24(sp)
    800045e2:	e822                	sd	s0,16(sp)
    800045e4:	e426                	sd	s1,8(sp)
    800045e6:	e04a                	sd	s2,0(sp)
    800045e8:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045ea:	0001d717          	auipc	a4,0x1d
    800045ee:	74a72703          	lw	a4,1866(a4) # 80021d34 <log+0x2c>
    800045f2:	47f5                	li	a5,29
    800045f4:	08e7c063          	blt	a5,a4,80004674 <log_write+0x96>
    800045f8:	84aa                	mv	s1,a0
    800045fa:	0001d797          	auipc	a5,0x1d
    800045fe:	72a7a783          	lw	a5,1834(a5) # 80021d24 <log+0x1c>
    80004602:	37fd                	addiw	a5,a5,-1
    80004604:	06f75863          	bge	a4,a5,80004674 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004608:	0001d797          	auipc	a5,0x1d
    8000460c:	7207a783          	lw	a5,1824(a5) # 80021d28 <log+0x20>
    80004610:	06f05a63          	blez	a5,80004684 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004614:	0001d917          	auipc	s2,0x1d
    80004618:	6f490913          	addi	s2,s2,1780 # 80021d08 <log>
    8000461c:	854a                	mv	a0,s2
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	5f2080e7          	jalr	1522(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004626:	02c92603          	lw	a2,44(s2)
    8000462a:	06c05563          	blez	a2,80004694 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000462e:	44cc                	lw	a1,12(s1)
    80004630:	0001d717          	auipc	a4,0x1d
    80004634:	70870713          	addi	a4,a4,1800 # 80021d38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004638:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000463a:	4314                	lw	a3,0(a4)
    8000463c:	04b68d63          	beq	a3,a1,80004696 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004640:	2785                	addiw	a5,a5,1
    80004642:	0711                	addi	a4,a4,4
    80004644:	fec79be3          	bne	a5,a2,8000463a <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004648:	0621                	addi	a2,a2,8
    8000464a:	060a                	slli	a2,a2,0x2
    8000464c:	0001d797          	auipc	a5,0x1d
    80004650:	6bc78793          	addi	a5,a5,1724 # 80021d08 <log>
    80004654:	963e                	add	a2,a2,a5
    80004656:	44dc                	lw	a5,12(s1)
    80004658:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000465a:	8526                	mv	a0,s1
    8000465c:	fffff097          	auipc	ra,0xfffff
    80004660:	dbc080e7          	jalr	-580(ra) # 80003418 <bpin>
    log.lh.n++;
    80004664:	0001d717          	auipc	a4,0x1d
    80004668:	6a470713          	addi	a4,a4,1700 # 80021d08 <log>
    8000466c:	575c                	lw	a5,44(a4)
    8000466e:	2785                	addiw	a5,a5,1
    80004670:	d75c                	sw	a5,44(a4)
    80004672:	a83d                	j	800046b0 <log_write+0xd2>
    panic("too big a transaction");
    80004674:	00004517          	auipc	a0,0x4
    80004678:	08c50513          	addi	a0,a0,140 # 80008700 <syscalls+0x1f0>
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	ecc080e7          	jalr	-308(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004684:	00004517          	auipc	a0,0x4
    80004688:	09450513          	addi	a0,a0,148 # 80008718 <syscalls+0x208>
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	ebc080e7          	jalr	-324(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004694:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004696:	00878713          	addi	a4,a5,8
    8000469a:	00271693          	slli	a3,a4,0x2
    8000469e:	0001d717          	auipc	a4,0x1d
    800046a2:	66a70713          	addi	a4,a4,1642 # 80021d08 <log>
    800046a6:	9736                	add	a4,a4,a3
    800046a8:	44d4                	lw	a3,12(s1)
    800046aa:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800046ac:	faf607e3          	beq	a2,a5,8000465a <log_write+0x7c>
  }
  release(&log.lock);
    800046b0:	0001d517          	auipc	a0,0x1d
    800046b4:	65850513          	addi	a0,a0,1624 # 80021d08 <log>
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	60c080e7          	jalr	1548(ra) # 80000cc4 <release>
}
    800046c0:	60e2                	ld	ra,24(sp)
    800046c2:	6442                	ld	s0,16(sp)
    800046c4:	64a2                	ld	s1,8(sp)
    800046c6:	6902                	ld	s2,0(sp)
    800046c8:	6105                	addi	sp,sp,32
    800046ca:	8082                	ret

00000000800046cc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046cc:	1101                	addi	sp,sp,-32
    800046ce:	ec06                	sd	ra,24(sp)
    800046d0:	e822                	sd	s0,16(sp)
    800046d2:	e426                	sd	s1,8(sp)
    800046d4:	e04a                	sd	s2,0(sp)
    800046d6:	1000                	addi	s0,sp,32
    800046d8:	84aa                	mv	s1,a0
    800046da:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046dc:	00004597          	auipc	a1,0x4
    800046e0:	05c58593          	addi	a1,a1,92 # 80008738 <syscalls+0x228>
    800046e4:	0521                	addi	a0,a0,8
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	49a080e7          	jalr	1178(ra) # 80000b80 <initlock>
  lk->name = name;
    800046ee:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046f2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046f6:	0204a423          	sw	zero,40(s1)
}
    800046fa:	60e2                	ld	ra,24(sp)
    800046fc:	6442                	ld	s0,16(sp)
    800046fe:	64a2                	ld	s1,8(sp)
    80004700:	6902                	ld	s2,0(sp)
    80004702:	6105                	addi	sp,sp,32
    80004704:	8082                	ret

0000000080004706 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004706:	1101                	addi	sp,sp,-32
    80004708:	ec06                	sd	ra,24(sp)
    8000470a:	e822                	sd	s0,16(sp)
    8000470c:	e426                	sd	s1,8(sp)
    8000470e:	e04a                	sd	s2,0(sp)
    80004710:	1000                	addi	s0,sp,32
    80004712:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004714:	00850913          	addi	s2,a0,8
    80004718:	854a                	mv	a0,s2
    8000471a:	ffffc097          	auipc	ra,0xffffc
    8000471e:	4f6080e7          	jalr	1270(ra) # 80000c10 <acquire>
  while (lk->locked) {
    80004722:	409c                	lw	a5,0(s1)
    80004724:	cb89                	beqz	a5,80004736 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004726:	85ca                	mv	a1,s2
    80004728:	8526                	mv	a0,s1
    8000472a:	ffffe097          	auipc	ra,0xffffe
    8000472e:	ece080e7          	jalr	-306(ra) # 800025f8 <sleep>
  while (lk->locked) {
    80004732:	409c                	lw	a5,0(s1)
    80004734:	fbed                	bnez	a5,80004726 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004736:	4785                	li	a5,1
    80004738:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000473a:	ffffd097          	auipc	ra,0xffffd
    8000473e:	5aa080e7          	jalr	1450(ra) # 80001ce4 <myproc>
    80004742:	5d1c                	lw	a5,56(a0)
    80004744:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004746:	854a                	mv	a0,s2
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	57c080e7          	jalr	1404(ra) # 80000cc4 <release>
}
    80004750:	60e2                	ld	ra,24(sp)
    80004752:	6442                	ld	s0,16(sp)
    80004754:	64a2                	ld	s1,8(sp)
    80004756:	6902                	ld	s2,0(sp)
    80004758:	6105                	addi	sp,sp,32
    8000475a:	8082                	ret

000000008000475c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000475c:	1101                	addi	sp,sp,-32
    8000475e:	ec06                	sd	ra,24(sp)
    80004760:	e822                	sd	s0,16(sp)
    80004762:	e426                	sd	s1,8(sp)
    80004764:	e04a                	sd	s2,0(sp)
    80004766:	1000                	addi	s0,sp,32
    80004768:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000476a:	00850913          	addi	s2,a0,8
    8000476e:	854a                	mv	a0,s2
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	4a0080e7          	jalr	1184(ra) # 80000c10 <acquire>
  lk->locked = 0;
    80004778:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000477c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004780:	8526                	mv	a0,s1
    80004782:	ffffe097          	auipc	ra,0xffffe
    80004786:	ffc080e7          	jalr	-4(ra) # 8000277e <wakeup>
  release(&lk->lk);
    8000478a:	854a                	mv	a0,s2
    8000478c:	ffffc097          	auipc	ra,0xffffc
    80004790:	538080e7          	jalr	1336(ra) # 80000cc4 <release>
}
    80004794:	60e2                	ld	ra,24(sp)
    80004796:	6442                	ld	s0,16(sp)
    80004798:	64a2                	ld	s1,8(sp)
    8000479a:	6902                	ld	s2,0(sp)
    8000479c:	6105                	addi	sp,sp,32
    8000479e:	8082                	ret

00000000800047a0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800047a0:	7179                	addi	sp,sp,-48
    800047a2:	f406                	sd	ra,40(sp)
    800047a4:	f022                	sd	s0,32(sp)
    800047a6:	ec26                	sd	s1,24(sp)
    800047a8:	e84a                	sd	s2,16(sp)
    800047aa:	e44e                	sd	s3,8(sp)
    800047ac:	1800                	addi	s0,sp,48
    800047ae:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800047b0:	00850913          	addi	s2,a0,8
    800047b4:	854a                	mv	a0,s2
    800047b6:	ffffc097          	auipc	ra,0xffffc
    800047ba:	45a080e7          	jalr	1114(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800047be:	409c                	lw	a5,0(s1)
    800047c0:	ef99                	bnez	a5,800047de <holdingsleep+0x3e>
    800047c2:	4481                	li	s1,0
  release(&lk->lk);
    800047c4:	854a                	mv	a0,s2
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	4fe080e7          	jalr	1278(ra) # 80000cc4 <release>
  return r;
}
    800047ce:	8526                	mv	a0,s1
    800047d0:	70a2                	ld	ra,40(sp)
    800047d2:	7402                	ld	s0,32(sp)
    800047d4:	64e2                	ld	s1,24(sp)
    800047d6:	6942                	ld	s2,16(sp)
    800047d8:	69a2                	ld	s3,8(sp)
    800047da:	6145                	addi	sp,sp,48
    800047dc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047de:	0284a983          	lw	s3,40(s1)
    800047e2:	ffffd097          	auipc	ra,0xffffd
    800047e6:	502080e7          	jalr	1282(ra) # 80001ce4 <myproc>
    800047ea:	5d04                	lw	s1,56(a0)
    800047ec:	413484b3          	sub	s1,s1,s3
    800047f0:	0014b493          	seqz	s1,s1
    800047f4:	bfc1                	j	800047c4 <holdingsleep+0x24>

00000000800047f6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047f6:	1141                	addi	sp,sp,-16
    800047f8:	e406                	sd	ra,8(sp)
    800047fa:	e022                	sd	s0,0(sp)
    800047fc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047fe:	00004597          	auipc	a1,0x4
    80004802:	f4a58593          	addi	a1,a1,-182 # 80008748 <syscalls+0x238>
    80004806:	0001d517          	auipc	a0,0x1d
    8000480a:	64a50513          	addi	a0,a0,1610 # 80021e50 <ftable>
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	372080e7          	jalr	882(ra) # 80000b80 <initlock>
}
    80004816:	60a2                	ld	ra,8(sp)
    80004818:	6402                	ld	s0,0(sp)
    8000481a:	0141                	addi	sp,sp,16
    8000481c:	8082                	ret

000000008000481e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000481e:	1101                	addi	sp,sp,-32
    80004820:	ec06                	sd	ra,24(sp)
    80004822:	e822                	sd	s0,16(sp)
    80004824:	e426                	sd	s1,8(sp)
    80004826:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004828:	0001d517          	auipc	a0,0x1d
    8000482c:	62850513          	addi	a0,a0,1576 # 80021e50 <ftable>
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	3e0080e7          	jalr	992(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004838:	0001d497          	auipc	s1,0x1d
    8000483c:	63048493          	addi	s1,s1,1584 # 80021e68 <ftable+0x18>
    80004840:	0001e717          	auipc	a4,0x1e
    80004844:	5c870713          	addi	a4,a4,1480 # 80022e08 <ftable+0xfb8>
    if(f->ref == 0){
    80004848:	40dc                	lw	a5,4(s1)
    8000484a:	cf99                	beqz	a5,80004868 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000484c:	02848493          	addi	s1,s1,40
    80004850:	fee49ce3          	bne	s1,a4,80004848 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004854:	0001d517          	auipc	a0,0x1d
    80004858:	5fc50513          	addi	a0,a0,1532 # 80021e50 <ftable>
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	468080e7          	jalr	1128(ra) # 80000cc4 <release>
  return 0;
    80004864:	4481                	li	s1,0
    80004866:	a819                	j	8000487c <filealloc+0x5e>
      f->ref = 1;
    80004868:	4785                	li	a5,1
    8000486a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000486c:	0001d517          	auipc	a0,0x1d
    80004870:	5e450513          	addi	a0,a0,1508 # 80021e50 <ftable>
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	450080e7          	jalr	1104(ra) # 80000cc4 <release>
}
    8000487c:	8526                	mv	a0,s1
    8000487e:	60e2                	ld	ra,24(sp)
    80004880:	6442                	ld	s0,16(sp)
    80004882:	64a2                	ld	s1,8(sp)
    80004884:	6105                	addi	sp,sp,32
    80004886:	8082                	ret

0000000080004888 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004888:	1101                	addi	sp,sp,-32
    8000488a:	ec06                	sd	ra,24(sp)
    8000488c:	e822                	sd	s0,16(sp)
    8000488e:	e426                	sd	s1,8(sp)
    80004890:	1000                	addi	s0,sp,32
    80004892:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004894:	0001d517          	auipc	a0,0x1d
    80004898:	5bc50513          	addi	a0,a0,1468 # 80021e50 <ftable>
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	374080e7          	jalr	884(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800048a4:	40dc                	lw	a5,4(s1)
    800048a6:	02f05263          	blez	a5,800048ca <filedup+0x42>
    panic("filedup");
  f->ref++;
    800048aa:	2785                	addiw	a5,a5,1
    800048ac:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800048ae:	0001d517          	auipc	a0,0x1d
    800048b2:	5a250513          	addi	a0,a0,1442 # 80021e50 <ftable>
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	40e080e7          	jalr	1038(ra) # 80000cc4 <release>
  return f;
}
    800048be:	8526                	mv	a0,s1
    800048c0:	60e2                	ld	ra,24(sp)
    800048c2:	6442                	ld	s0,16(sp)
    800048c4:	64a2                	ld	s1,8(sp)
    800048c6:	6105                	addi	sp,sp,32
    800048c8:	8082                	ret
    panic("filedup");
    800048ca:	00004517          	auipc	a0,0x4
    800048ce:	e8650513          	addi	a0,a0,-378 # 80008750 <syscalls+0x240>
    800048d2:	ffffc097          	auipc	ra,0xffffc
    800048d6:	c76080e7          	jalr	-906(ra) # 80000548 <panic>

00000000800048da <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048da:	7139                	addi	sp,sp,-64
    800048dc:	fc06                	sd	ra,56(sp)
    800048de:	f822                	sd	s0,48(sp)
    800048e0:	f426                	sd	s1,40(sp)
    800048e2:	f04a                	sd	s2,32(sp)
    800048e4:	ec4e                	sd	s3,24(sp)
    800048e6:	e852                	sd	s4,16(sp)
    800048e8:	e456                	sd	s5,8(sp)
    800048ea:	0080                	addi	s0,sp,64
    800048ec:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048ee:	0001d517          	auipc	a0,0x1d
    800048f2:	56250513          	addi	a0,a0,1378 # 80021e50 <ftable>
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	31a080e7          	jalr	794(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800048fe:	40dc                	lw	a5,4(s1)
    80004900:	06f05163          	blez	a5,80004962 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004904:	37fd                	addiw	a5,a5,-1
    80004906:	0007871b          	sext.w	a4,a5
    8000490a:	c0dc                	sw	a5,4(s1)
    8000490c:	06e04363          	bgtz	a4,80004972 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004910:	0004a903          	lw	s2,0(s1)
    80004914:	0094ca83          	lbu	s5,9(s1)
    80004918:	0104ba03          	ld	s4,16(s1)
    8000491c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004920:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004924:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004928:	0001d517          	auipc	a0,0x1d
    8000492c:	52850513          	addi	a0,a0,1320 # 80021e50 <ftable>
    80004930:	ffffc097          	auipc	ra,0xffffc
    80004934:	394080e7          	jalr	916(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    80004938:	4785                	li	a5,1
    8000493a:	04f90d63          	beq	s2,a5,80004994 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000493e:	3979                	addiw	s2,s2,-2
    80004940:	4785                	li	a5,1
    80004942:	0527e063          	bltu	a5,s2,80004982 <fileclose+0xa8>
    begin_op();
    80004946:	00000097          	auipc	ra,0x0
    8000494a:	ac2080e7          	jalr	-1342(ra) # 80004408 <begin_op>
    iput(ff.ip);
    8000494e:	854e                	mv	a0,s3
    80004950:	fffff097          	auipc	ra,0xfffff
    80004954:	2b6080e7          	jalr	694(ra) # 80003c06 <iput>
    end_op();
    80004958:	00000097          	auipc	ra,0x0
    8000495c:	b30080e7          	jalr	-1232(ra) # 80004488 <end_op>
    80004960:	a00d                	j	80004982 <fileclose+0xa8>
    panic("fileclose");
    80004962:	00004517          	auipc	a0,0x4
    80004966:	df650513          	addi	a0,a0,-522 # 80008758 <syscalls+0x248>
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	bde080e7          	jalr	-1058(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004972:	0001d517          	auipc	a0,0x1d
    80004976:	4de50513          	addi	a0,a0,1246 # 80021e50 <ftable>
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	34a080e7          	jalr	842(ra) # 80000cc4 <release>
  }
}
    80004982:	70e2                	ld	ra,56(sp)
    80004984:	7442                	ld	s0,48(sp)
    80004986:	74a2                	ld	s1,40(sp)
    80004988:	7902                	ld	s2,32(sp)
    8000498a:	69e2                	ld	s3,24(sp)
    8000498c:	6a42                	ld	s4,16(sp)
    8000498e:	6aa2                	ld	s5,8(sp)
    80004990:	6121                	addi	sp,sp,64
    80004992:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004994:	85d6                	mv	a1,s5
    80004996:	8552                	mv	a0,s4
    80004998:	00000097          	auipc	ra,0x0
    8000499c:	372080e7          	jalr	882(ra) # 80004d0a <pipeclose>
    800049a0:	b7cd                	j	80004982 <fileclose+0xa8>

00000000800049a2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800049a2:	715d                	addi	sp,sp,-80
    800049a4:	e486                	sd	ra,72(sp)
    800049a6:	e0a2                	sd	s0,64(sp)
    800049a8:	fc26                	sd	s1,56(sp)
    800049aa:	f84a                	sd	s2,48(sp)
    800049ac:	f44e                	sd	s3,40(sp)
    800049ae:	0880                	addi	s0,sp,80
    800049b0:	84aa                	mv	s1,a0
    800049b2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800049b4:	ffffd097          	auipc	ra,0xffffd
    800049b8:	330080e7          	jalr	816(ra) # 80001ce4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800049bc:	409c                	lw	a5,0(s1)
    800049be:	37f9                	addiw	a5,a5,-2
    800049c0:	4705                	li	a4,1
    800049c2:	04f76763          	bltu	a4,a5,80004a10 <filestat+0x6e>
    800049c6:	892a                	mv	s2,a0
    ilock(f->ip);
    800049c8:	6c88                	ld	a0,24(s1)
    800049ca:	fffff097          	auipc	ra,0xfffff
    800049ce:	082080e7          	jalr	130(ra) # 80003a4c <ilock>
    stati(f->ip, &st);
    800049d2:	fb840593          	addi	a1,s0,-72
    800049d6:	6c88                	ld	a0,24(s1)
    800049d8:	fffff097          	auipc	ra,0xfffff
    800049dc:	2fe080e7          	jalr	766(ra) # 80003cd6 <stati>
    iunlock(f->ip);
    800049e0:	6c88                	ld	a0,24(s1)
    800049e2:	fffff097          	auipc	ra,0xfffff
    800049e6:	12c080e7          	jalr	300(ra) # 80003b0e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049ea:	46e1                	li	a3,24
    800049ec:	fb840613          	addi	a2,s0,-72
    800049f0:	85ce                	mv	a1,s3
    800049f2:	05093503          	ld	a0,80(s2)
    800049f6:	ffffd097          	auipc	ra,0xffffd
    800049fa:	d4c080e7          	jalr	-692(ra) # 80001742 <copyout>
    800049fe:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a02:	60a6                	ld	ra,72(sp)
    80004a04:	6406                	ld	s0,64(sp)
    80004a06:	74e2                	ld	s1,56(sp)
    80004a08:	7942                	ld	s2,48(sp)
    80004a0a:	79a2                	ld	s3,40(sp)
    80004a0c:	6161                	addi	sp,sp,80
    80004a0e:	8082                	ret
  return -1;
    80004a10:	557d                	li	a0,-1
    80004a12:	bfc5                	j	80004a02 <filestat+0x60>

0000000080004a14 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a14:	7179                	addi	sp,sp,-48
    80004a16:	f406                	sd	ra,40(sp)
    80004a18:	f022                	sd	s0,32(sp)
    80004a1a:	ec26                	sd	s1,24(sp)
    80004a1c:	e84a                	sd	s2,16(sp)
    80004a1e:	e44e                	sd	s3,8(sp)
    80004a20:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a22:	00854783          	lbu	a5,8(a0)
    80004a26:	c3d5                	beqz	a5,80004aca <fileread+0xb6>
    80004a28:	84aa                	mv	s1,a0
    80004a2a:	89ae                	mv	s3,a1
    80004a2c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a2e:	411c                	lw	a5,0(a0)
    80004a30:	4705                	li	a4,1
    80004a32:	04e78963          	beq	a5,a4,80004a84 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a36:	470d                	li	a4,3
    80004a38:	04e78d63          	beq	a5,a4,80004a92 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a3c:	4709                	li	a4,2
    80004a3e:	06e79e63          	bne	a5,a4,80004aba <fileread+0xa6>
    ilock(f->ip);
    80004a42:	6d08                	ld	a0,24(a0)
    80004a44:	fffff097          	auipc	ra,0xfffff
    80004a48:	008080e7          	jalr	8(ra) # 80003a4c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a4c:	874a                	mv	a4,s2
    80004a4e:	5094                	lw	a3,32(s1)
    80004a50:	864e                	mv	a2,s3
    80004a52:	4585                	li	a1,1
    80004a54:	6c88                	ld	a0,24(s1)
    80004a56:	fffff097          	auipc	ra,0xfffff
    80004a5a:	2aa080e7          	jalr	682(ra) # 80003d00 <readi>
    80004a5e:	892a                	mv	s2,a0
    80004a60:	00a05563          	blez	a0,80004a6a <fileread+0x56>
      f->off += r;
    80004a64:	509c                	lw	a5,32(s1)
    80004a66:	9fa9                	addw	a5,a5,a0
    80004a68:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a6a:	6c88                	ld	a0,24(s1)
    80004a6c:	fffff097          	auipc	ra,0xfffff
    80004a70:	0a2080e7          	jalr	162(ra) # 80003b0e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a74:	854a                	mv	a0,s2
    80004a76:	70a2                	ld	ra,40(sp)
    80004a78:	7402                	ld	s0,32(sp)
    80004a7a:	64e2                	ld	s1,24(sp)
    80004a7c:	6942                	ld	s2,16(sp)
    80004a7e:	69a2                	ld	s3,8(sp)
    80004a80:	6145                	addi	sp,sp,48
    80004a82:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a84:	6908                	ld	a0,16(a0)
    80004a86:	00000097          	auipc	ra,0x0
    80004a8a:	418080e7          	jalr	1048(ra) # 80004e9e <piperead>
    80004a8e:	892a                	mv	s2,a0
    80004a90:	b7d5                	j	80004a74 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a92:	02451783          	lh	a5,36(a0)
    80004a96:	03079693          	slli	a3,a5,0x30
    80004a9a:	92c1                	srli	a3,a3,0x30
    80004a9c:	4725                	li	a4,9
    80004a9e:	02d76863          	bltu	a4,a3,80004ace <fileread+0xba>
    80004aa2:	0792                	slli	a5,a5,0x4
    80004aa4:	0001d717          	auipc	a4,0x1d
    80004aa8:	30c70713          	addi	a4,a4,780 # 80021db0 <devsw>
    80004aac:	97ba                	add	a5,a5,a4
    80004aae:	639c                	ld	a5,0(a5)
    80004ab0:	c38d                	beqz	a5,80004ad2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ab2:	4505                	li	a0,1
    80004ab4:	9782                	jalr	a5
    80004ab6:	892a                	mv	s2,a0
    80004ab8:	bf75                	j	80004a74 <fileread+0x60>
    panic("fileread");
    80004aba:	00004517          	auipc	a0,0x4
    80004abe:	cae50513          	addi	a0,a0,-850 # 80008768 <syscalls+0x258>
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	a86080e7          	jalr	-1402(ra) # 80000548 <panic>
    return -1;
    80004aca:	597d                	li	s2,-1
    80004acc:	b765                	j	80004a74 <fileread+0x60>
      return -1;
    80004ace:	597d                	li	s2,-1
    80004ad0:	b755                	j	80004a74 <fileread+0x60>
    80004ad2:	597d                	li	s2,-1
    80004ad4:	b745                	j	80004a74 <fileread+0x60>

0000000080004ad6 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004ad6:	00954783          	lbu	a5,9(a0)
    80004ada:	14078563          	beqz	a5,80004c24 <filewrite+0x14e>
{
    80004ade:	715d                	addi	sp,sp,-80
    80004ae0:	e486                	sd	ra,72(sp)
    80004ae2:	e0a2                	sd	s0,64(sp)
    80004ae4:	fc26                	sd	s1,56(sp)
    80004ae6:	f84a                	sd	s2,48(sp)
    80004ae8:	f44e                	sd	s3,40(sp)
    80004aea:	f052                	sd	s4,32(sp)
    80004aec:	ec56                	sd	s5,24(sp)
    80004aee:	e85a                	sd	s6,16(sp)
    80004af0:	e45e                	sd	s7,8(sp)
    80004af2:	e062                	sd	s8,0(sp)
    80004af4:	0880                	addi	s0,sp,80
    80004af6:	892a                	mv	s2,a0
    80004af8:	8aae                	mv	s5,a1
    80004afa:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004afc:	411c                	lw	a5,0(a0)
    80004afe:	4705                	li	a4,1
    80004b00:	02e78263          	beq	a5,a4,80004b24 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b04:	470d                	li	a4,3
    80004b06:	02e78563          	beq	a5,a4,80004b30 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b0a:	4709                	li	a4,2
    80004b0c:	10e79463          	bne	a5,a4,80004c14 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b10:	0ec05e63          	blez	a2,80004c0c <filewrite+0x136>
    int i = 0;
    80004b14:	4981                	li	s3,0
    80004b16:	6b05                	lui	s6,0x1
    80004b18:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004b1c:	6b85                	lui	s7,0x1
    80004b1e:	c00b8b9b          	addiw	s7,s7,-1024
    80004b22:	a851                	j	80004bb6 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004b24:	6908                	ld	a0,16(a0)
    80004b26:	00000097          	auipc	ra,0x0
    80004b2a:	254080e7          	jalr	596(ra) # 80004d7a <pipewrite>
    80004b2e:	a85d                	j	80004be4 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b30:	02451783          	lh	a5,36(a0)
    80004b34:	03079693          	slli	a3,a5,0x30
    80004b38:	92c1                	srli	a3,a3,0x30
    80004b3a:	4725                	li	a4,9
    80004b3c:	0ed76663          	bltu	a4,a3,80004c28 <filewrite+0x152>
    80004b40:	0792                	slli	a5,a5,0x4
    80004b42:	0001d717          	auipc	a4,0x1d
    80004b46:	26e70713          	addi	a4,a4,622 # 80021db0 <devsw>
    80004b4a:	97ba                	add	a5,a5,a4
    80004b4c:	679c                	ld	a5,8(a5)
    80004b4e:	cff9                	beqz	a5,80004c2c <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004b50:	4505                	li	a0,1
    80004b52:	9782                	jalr	a5
    80004b54:	a841                	j	80004be4 <filewrite+0x10e>
    80004b56:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b5a:	00000097          	auipc	ra,0x0
    80004b5e:	8ae080e7          	jalr	-1874(ra) # 80004408 <begin_op>
      ilock(f->ip);
    80004b62:	01893503          	ld	a0,24(s2)
    80004b66:	fffff097          	auipc	ra,0xfffff
    80004b6a:	ee6080e7          	jalr	-282(ra) # 80003a4c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b6e:	8762                	mv	a4,s8
    80004b70:	02092683          	lw	a3,32(s2)
    80004b74:	01598633          	add	a2,s3,s5
    80004b78:	4585                	li	a1,1
    80004b7a:	01893503          	ld	a0,24(s2)
    80004b7e:	fffff097          	auipc	ra,0xfffff
    80004b82:	278080e7          	jalr	632(ra) # 80003df6 <writei>
    80004b86:	84aa                	mv	s1,a0
    80004b88:	02a05f63          	blez	a0,80004bc6 <filewrite+0xf0>
        f->off += r;
    80004b8c:	02092783          	lw	a5,32(s2)
    80004b90:	9fa9                	addw	a5,a5,a0
    80004b92:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b96:	01893503          	ld	a0,24(s2)
    80004b9a:	fffff097          	auipc	ra,0xfffff
    80004b9e:	f74080e7          	jalr	-140(ra) # 80003b0e <iunlock>
      end_op();
    80004ba2:	00000097          	auipc	ra,0x0
    80004ba6:	8e6080e7          	jalr	-1818(ra) # 80004488 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004baa:	049c1963          	bne	s8,s1,80004bfc <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004bae:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004bb2:	0349d663          	bge	s3,s4,80004bde <filewrite+0x108>
      int n1 = n - i;
    80004bb6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004bba:	84be                	mv	s1,a5
    80004bbc:	2781                	sext.w	a5,a5
    80004bbe:	f8fb5ce3          	bge	s6,a5,80004b56 <filewrite+0x80>
    80004bc2:	84de                	mv	s1,s7
    80004bc4:	bf49                	j	80004b56 <filewrite+0x80>
      iunlock(f->ip);
    80004bc6:	01893503          	ld	a0,24(s2)
    80004bca:	fffff097          	auipc	ra,0xfffff
    80004bce:	f44080e7          	jalr	-188(ra) # 80003b0e <iunlock>
      end_op();
    80004bd2:	00000097          	auipc	ra,0x0
    80004bd6:	8b6080e7          	jalr	-1866(ra) # 80004488 <end_op>
      if(r < 0)
    80004bda:	fc04d8e3          	bgez	s1,80004baa <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004bde:	8552                	mv	a0,s4
    80004be0:	033a1863          	bne	s4,s3,80004c10 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004be4:	60a6                	ld	ra,72(sp)
    80004be6:	6406                	ld	s0,64(sp)
    80004be8:	74e2                	ld	s1,56(sp)
    80004bea:	7942                	ld	s2,48(sp)
    80004bec:	79a2                	ld	s3,40(sp)
    80004bee:	7a02                	ld	s4,32(sp)
    80004bf0:	6ae2                	ld	s5,24(sp)
    80004bf2:	6b42                	ld	s6,16(sp)
    80004bf4:	6ba2                	ld	s7,8(sp)
    80004bf6:	6c02                	ld	s8,0(sp)
    80004bf8:	6161                	addi	sp,sp,80
    80004bfa:	8082                	ret
        panic("short filewrite");
    80004bfc:	00004517          	auipc	a0,0x4
    80004c00:	b7c50513          	addi	a0,a0,-1156 # 80008778 <syscalls+0x268>
    80004c04:	ffffc097          	auipc	ra,0xffffc
    80004c08:	944080e7          	jalr	-1724(ra) # 80000548 <panic>
    int i = 0;
    80004c0c:	4981                	li	s3,0
    80004c0e:	bfc1                	j	80004bde <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004c10:	557d                	li	a0,-1
    80004c12:	bfc9                	j	80004be4 <filewrite+0x10e>
    panic("filewrite");
    80004c14:	00004517          	auipc	a0,0x4
    80004c18:	b7450513          	addi	a0,a0,-1164 # 80008788 <syscalls+0x278>
    80004c1c:	ffffc097          	auipc	ra,0xffffc
    80004c20:	92c080e7          	jalr	-1748(ra) # 80000548 <panic>
    return -1;
    80004c24:	557d                	li	a0,-1
}
    80004c26:	8082                	ret
      return -1;
    80004c28:	557d                	li	a0,-1
    80004c2a:	bf6d                	j	80004be4 <filewrite+0x10e>
    80004c2c:	557d                	li	a0,-1
    80004c2e:	bf5d                	j	80004be4 <filewrite+0x10e>

0000000080004c30 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c30:	7179                	addi	sp,sp,-48
    80004c32:	f406                	sd	ra,40(sp)
    80004c34:	f022                	sd	s0,32(sp)
    80004c36:	ec26                	sd	s1,24(sp)
    80004c38:	e84a                	sd	s2,16(sp)
    80004c3a:	e44e                	sd	s3,8(sp)
    80004c3c:	e052                	sd	s4,0(sp)
    80004c3e:	1800                	addi	s0,sp,48
    80004c40:	84aa                	mv	s1,a0
    80004c42:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c44:	0005b023          	sd	zero,0(a1)
    80004c48:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c4c:	00000097          	auipc	ra,0x0
    80004c50:	bd2080e7          	jalr	-1070(ra) # 8000481e <filealloc>
    80004c54:	e088                	sd	a0,0(s1)
    80004c56:	c551                	beqz	a0,80004ce2 <pipealloc+0xb2>
    80004c58:	00000097          	auipc	ra,0x0
    80004c5c:	bc6080e7          	jalr	-1082(ra) # 8000481e <filealloc>
    80004c60:	00aa3023          	sd	a0,0(s4)
    80004c64:	c92d                	beqz	a0,80004cd6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	eba080e7          	jalr	-326(ra) # 80000b20 <kalloc>
    80004c6e:	892a                	mv	s2,a0
    80004c70:	c125                	beqz	a0,80004cd0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c72:	4985                	li	s3,1
    80004c74:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c78:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c7c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c80:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c84:	00004597          	auipc	a1,0x4
    80004c88:	b1458593          	addi	a1,a1,-1260 # 80008798 <syscalls+0x288>
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	ef4080e7          	jalr	-268(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004c94:	609c                	ld	a5,0(s1)
    80004c96:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c9a:	609c                	ld	a5,0(s1)
    80004c9c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ca0:	609c                	ld	a5,0(s1)
    80004ca2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ca6:	609c                	ld	a5,0(s1)
    80004ca8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004cac:	000a3783          	ld	a5,0(s4)
    80004cb0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004cb4:	000a3783          	ld	a5,0(s4)
    80004cb8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004cbc:	000a3783          	ld	a5,0(s4)
    80004cc0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004cc4:	000a3783          	ld	a5,0(s4)
    80004cc8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ccc:	4501                	li	a0,0
    80004cce:	a025                	j	80004cf6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004cd0:	6088                	ld	a0,0(s1)
    80004cd2:	e501                	bnez	a0,80004cda <pipealloc+0xaa>
    80004cd4:	a039                	j	80004ce2 <pipealloc+0xb2>
    80004cd6:	6088                	ld	a0,0(s1)
    80004cd8:	c51d                	beqz	a0,80004d06 <pipealloc+0xd6>
    fileclose(*f0);
    80004cda:	00000097          	auipc	ra,0x0
    80004cde:	c00080e7          	jalr	-1024(ra) # 800048da <fileclose>
  if(*f1)
    80004ce2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ce6:	557d                	li	a0,-1
  if(*f1)
    80004ce8:	c799                	beqz	a5,80004cf6 <pipealloc+0xc6>
    fileclose(*f1);
    80004cea:	853e                	mv	a0,a5
    80004cec:	00000097          	auipc	ra,0x0
    80004cf0:	bee080e7          	jalr	-1042(ra) # 800048da <fileclose>
  return -1;
    80004cf4:	557d                	li	a0,-1
}
    80004cf6:	70a2                	ld	ra,40(sp)
    80004cf8:	7402                	ld	s0,32(sp)
    80004cfa:	64e2                	ld	s1,24(sp)
    80004cfc:	6942                	ld	s2,16(sp)
    80004cfe:	69a2                	ld	s3,8(sp)
    80004d00:	6a02                	ld	s4,0(sp)
    80004d02:	6145                	addi	sp,sp,48
    80004d04:	8082                	ret
  return -1;
    80004d06:	557d                	li	a0,-1
    80004d08:	b7fd                	j	80004cf6 <pipealloc+0xc6>

0000000080004d0a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d0a:	1101                	addi	sp,sp,-32
    80004d0c:	ec06                	sd	ra,24(sp)
    80004d0e:	e822                	sd	s0,16(sp)
    80004d10:	e426                	sd	s1,8(sp)
    80004d12:	e04a                	sd	s2,0(sp)
    80004d14:	1000                	addi	s0,sp,32
    80004d16:	84aa                	mv	s1,a0
    80004d18:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d1a:	ffffc097          	auipc	ra,0xffffc
    80004d1e:	ef6080e7          	jalr	-266(ra) # 80000c10 <acquire>
  if(writable){
    80004d22:	02090d63          	beqz	s2,80004d5c <pipeclose+0x52>
    pi->writeopen = 0;
    80004d26:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d2a:	21848513          	addi	a0,s1,536
    80004d2e:	ffffe097          	auipc	ra,0xffffe
    80004d32:	a50080e7          	jalr	-1456(ra) # 8000277e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d36:	2204b783          	ld	a5,544(s1)
    80004d3a:	eb95                	bnez	a5,80004d6e <pipeclose+0x64>
    release(&pi->lock);
    80004d3c:	8526                	mv	a0,s1
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	f86080e7          	jalr	-122(ra) # 80000cc4 <release>
    kfree((char*)pi);
    80004d46:	8526                	mv	a0,s1
    80004d48:	ffffc097          	auipc	ra,0xffffc
    80004d4c:	cdc080e7          	jalr	-804(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004d50:	60e2                	ld	ra,24(sp)
    80004d52:	6442                	ld	s0,16(sp)
    80004d54:	64a2                	ld	s1,8(sp)
    80004d56:	6902                	ld	s2,0(sp)
    80004d58:	6105                	addi	sp,sp,32
    80004d5a:	8082                	ret
    pi->readopen = 0;
    80004d5c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d60:	21c48513          	addi	a0,s1,540
    80004d64:	ffffe097          	auipc	ra,0xffffe
    80004d68:	a1a080e7          	jalr	-1510(ra) # 8000277e <wakeup>
    80004d6c:	b7e9                	j	80004d36 <pipeclose+0x2c>
    release(&pi->lock);
    80004d6e:	8526                	mv	a0,s1
    80004d70:	ffffc097          	auipc	ra,0xffffc
    80004d74:	f54080e7          	jalr	-172(ra) # 80000cc4 <release>
}
    80004d78:	bfe1                	j	80004d50 <pipeclose+0x46>

0000000080004d7a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d7a:	7119                	addi	sp,sp,-128
    80004d7c:	fc86                	sd	ra,120(sp)
    80004d7e:	f8a2                	sd	s0,112(sp)
    80004d80:	f4a6                	sd	s1,104(sp)
    80004d82:	f0ca                	sd	s2,96(sp)
    80004d84:	ecce                	sd	s3,88(sp)
    80004d86:	e8d2                	sd	s4,80(sp)
    80004d88:	e4d6                	sd	s5,72(sp)
    80004d8a:	e0da                	sd	s6,64(sp)
    80004d8c:	fc5e                	sd	s7,56(sp)
    80004d8e:	f862                	sd	s8,48(sp)
    80004d90:	f466                	sd	s9,40(sp)
    80004d92:	f06a                	sd	s10,32(sp)
    80004d94:	ec6e                	sd	s11,24(sp)
    80004d96:	0100                	addi	s0,sp,128
    80004d98:	84aa                	mv	s1,a0
    80004d9a:	8cae                	mv	s9,a1
    80004d9c:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004d9e:	ffffd097          	auipc	ra,0xffffd
    80004da2:	f46080e7          	jalr	-186(ra) # 80001ce4 <myproc>
    80004da6:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004da8:	8526                	mv	a0,s1
    80004daa:	ffffc097          	auipc	ra,0xffffc
    80004dae:	e66080e7          	jalr	-410(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004db2:	0d605963          	blez	s6,80004e84 <pipewrite+0x10a>
    80004db6:	89a6                	mv	s3,s1
    80004db8:	3b7d                	addiw	s6,s6,-1
    80004dba:	1b02                	slli	s6,s6,0x20
    80004dbc:	020b5b13          	srli	s6,s6,0x20
    80004dc0:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004dc2:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004dc6:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004dca:	5dfd                	li	s11,-1
    80004dcc:	000b8d1b          	sext.w	s10,s7
    80004dd0:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004dd2:	2184a783          	lw	a5,536(s1)
    80004dd6:	21c4a703          	lw	a4,540(s1)
    80004dda:	2007879b          	addiw	a5,a5,512
    80004dde:	02f71b63          	bne	a4,a5,80004e14 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004de2:	2204a783          	lw	a5,544(s1)
    80004de6:	cbad                	beqz	a5,80004e58 <pipewrite+0xde>
    80004de8:	03092783          	lw	a5,48(s2)
    80004dec:	e7b5                	bnez	a5,80004e58 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004dee:	8556                	mv	a0,s5
    80004df0:	ffffe097          	auipc	ra,0xffffe
    80004df4:	98e080e7          	jalr	-1650(ra) # 8000277e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004df8:	85ce                	mv	a1,s3
    80004dfa:	8552                	mv	a0,s4
    80004dfc:	ffffd097          	auipc	ra,0xffffd
    80004e00:	7fc080e7          	jalr	2044(ra) # 800025f8 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004e04:	2184a783          	lw	a5,536(s1)
    80004e08:	21c4a703          	lw	a4,540(s1)
    80004e0c:	2007879b          	addiw	a5,a5,512
    80004e10:	fcf709e3          	beq	a4,a5,80004de2 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e14:	4685                	li	a3,1
    80004e16:	019b8633          	add	a2,s7,s9
    80004e1a:	f8f40593          	addi	a1,s0,-113
    80004e1e:	05093503          	ld	a0,80(s2)
    80004e22:	ffffd097          	auipc	ra,0xffffd
    80004e26:	9ac080e7          	jalr	-1620(ra) # 800017ce <copyin>
    80004e2a:	05b50e63          	beq	a0,s11,80004e86 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e2e:	21c4a783          	lw	a5,540(s1)
    80004e32:	0017871b          	addiw	a4,a5,1
    80004e36:	20e4ae23          	sw	a4,540(s1)
    80004e3a:	1ff7f793          	andi	a5,a5,511
    80004e3e:	97a6                	add	a5,a5,s1
    80004e40:	f8f44703          	lbu	a4,-113(s0)
    80004e44:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004e48:	001d0c1b          	addiw	s8,s10,1
    80004e4c:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004e50:	036b8b63          	beq	s7,s6,80004e86 <pipewrite+0x10c>
    80004e54:	8bbe                	mv	s7,a5
    80004e56:	bf9d                	j	80004dcc <pipewrite+0x52>
        release(&pi->lock);
    80004e58:	8526                	mv	a0,s1
    80004e5a:	ffffc097          	auipc	ra,0xffffc
    80004e5e:	e6a080e7          	jalr	-406(ra) # 80000cc4 <release>
        return -1;
    80004e62:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004e64:	8562                	mv	a0,s8
    80004e66:	70e6                	ld	ra,120(sp)
    80004e68:	7446                	ld	s0,112(sp)
    80004e6a:	74a6                	ld	s1,104(sp)
    80004e6c:	7906                	ld	s2,96(sp)
    80004e6e:	69e6                	ld	s3,88(sp)
    80004e70:	6a46                	ld	s4,80(sp)
    80004e72:	6aa6                	ld	s5,72(sp)
    80004e74:	6b06                	ld	s6,64(sp)
    80004e76:	7be2                	ld	s7,56(sp)
    80004e78:	7c42                	ld	s8,48(sp)
    80004e7a:	7ca2                	ld	s9,40(sp)
    80004e7c:	7d02                	ld	s10,32(sp)
    80004e7e:	6de2                	ld	s11,24(sp)
    80004e80:	6109                	addi	sp,sp,128
    80004e82:	8082                	ret
  for(i = 0; i < n; i++){
    80004e84:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004e86:	21848513          	addi	a0,s1,536
    80004e8a:	ffffe097          	auipc	ra,0xffffe
    80004e8e:	8f4080e7          	jalr	-1804(ra) # 8000277e <wakeup>
  release(&pi->lock);
    80004e92:	8526                	mv	a0,s1
    80004e94:	ffffc097          	auipc	ra,0xffffc
    80004e98:	e30080e7          	jalr	-464(ra) # 80000cc4 <release>
  return i;
    80004e9c:	b7e1                	j	80004e64 <pipewrite+0xea>

0000000080004e9e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e9e:	715d                	addi	sp,sp,-80
    80004ea0:	e486                	sd	ra,72(sp)
    80004ea2:	e0a2                	sd	s0,64(sp)
    80004ea4:	fc26                	sd	s1,56(sp)
    80004ea6:	f84a                	sd	s2,48(sp)
    80004ea8:	f44e                	sd	s3,40(sp)
    80004eaa:	f052                	sd	s4,32(sp)
    80004eac:	ec56                	sd	s5,24(sp)
    80004eae:	e85a                	sd	s6,16(sp)
    80004eb0:	0880                	addi	s0,sp,80
    80004eb2:	84aa                	mv	s1,a0
    80004eb4:	892e                	mv	s2,a1
    80004eb6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004eb8:	ffffd097          	auipc	ra,0xffffd
    80004ebc:	e2c080e7          	jalr	-468(ra) # 80001ce4 <myproc>
    80004ec0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ec2:	8b26                	mv	s6,s1
    80004ec4:	8526                	mv	a0,s1
    80004ec6:	ffffc097          	auipc	ra,0xffffc
    80004eca:	d4a080e7          	jalr	-694(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ece:	2184a703          	lw	a4,536(s1)
    80004ed2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ed6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004eda:	02f71463          	bne	a4,a5,80004f02 <piperead+0x64>
    80004ede:	2244a783          	lw	a5,548(s1)
    80004ee2:	c385                	beqz	a5,80004f02 <piperead+0x64>
    if(pr->killed){
    80004ee4:	030a2783          	lw	a5,48(s4)
    80004ee8:	ebc1                	bnez	a5,80004f78 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004eea:	85da                	mv	a1,s6
    80004eec:	854e                	mv	a0,s3
    80004eee:	ffffd097          	auipc	ra,0xffffd
    80004ef2:	70a080e7          	jalr	1802(ra) # 800025f8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ef6:	2184a703          	lw	a4,536(s1)
    80004efa:	21c4a783          	lw	a5,540(s1)
    80004efe:	fef700e3          	beq	a4,a5,80004ede <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f02:	09505263          	blez	s5,80004f86 <piperead+0xe8>
    80004f06:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f08:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004f0a:	2184a783          	lw	a5,536(s1)
    80004f0e:	21c4a703          	lw	a4,540(s1)
    80004f12:	02f70d63          	beq	a4,a5,80004f4c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f16:	0017871b          	addiw	a4,a5,1
    80004f1a:	20e4ac23          	sw	a4,536(s1)
    80004f1e:	1ff7f793          	andi	a5,a5,511
    80004f22:	97a6                	add	a5,a5,s1
    80004f24:	0187c783          	lbu	a5,24(a5)
    80004f28:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f2c:	4685                	li	a3,1
    80004f2e:	fbf40613          	addi	a2,s0,-65
    80004f32:	85ca                	mv	a1,s2
    80004f34:	050a3503          	ld	a0,80(s4)
    80004f38:	ffffd097          	auipc	ra,0xffffd
    80004f3c:	80a080e7          	jalr	-2038(ra) # 80001742 <copyout>
    80004f40:	01650663          	beq	a0,s6,80004f4c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f44:	2985                	addiw	s3,s3,1
    80004f46:	0905                	addi	s2,s2,1
    80004f48:	fd3a91e3          	bne	s5,s3,80004f0a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f4c:	21c48513          	addi	a0,s1,540
    80004f50:	ffffe097          	auipc	ra,0xffffe
    80004f54:	82e080e7          	jalr	-2002(ra) # 8000277e <wakeup>
  release(&pi->lock);
    80004f58:	8526                	mv	a0,s1
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	d6a080e7          	jalr	-662(ra) # 80000cc4 <release>
  return i;
}
    80004f62:	854e                	mv	a0,s3
    80004f64:	60a6                	ld	ra,72(sp)
    80004f66:	6406                	ld	s0,64(sp)
    80004f68:	74e2                	ld	s1,56(sp)
    80004f6a:	7942                	ld	s2,48(sp)
    80004f6c:	79a2                	ld	s3,40(sp)
    80004f6e:	7a02                	ld	s4,32(sp)
    80004f70:	6ae2                	ld	s5,24(sp)
    80004f72:	6b42                	ld	s6,16(sp)
    80004f74:	6161                	addi	sp,sp,80
    80004f76:	8082                	ret
      release(&pi->lock);
    80004f78:	8526                	mv	a0,s1
    80004f7a:	ffffc097          	auipc	ra,0xffffc
    80004f7e:	d4a080e7          	jalr	-694(ra) # 80000cc4 <release>
      return -1;
    80004f82:	59fd                	li	s3,-1
    80004f84:	bff9                	j	80004f62 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f86:	4981                	li	s3,0
    80004f88:	b7d1                	j	80004f4c <piperead+0xae>

0000000080004f8a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004f8a:	df010113          	addi	sp,sp,-528
    80004f8e:	20113423          	sd	ra,520(sp)
    80004f92:	20813023          	sd	s0,512(sp)
    80004f96:	ffa6                	sd	s1,504(sp)
    80004f98:	fbca                	sd	s2,496(sp)
    80004f9a:	f7ce                	sd	s3,488(sp)
    80004f9c:	f3d2                	sd	s4,480(sp)
    80004f9e:	efd6                	sd	s5,472(sp)
    80004fa0:	ebda                	sd	s6,464(sp)
    80004fa2:	e7de                	sd	s7,456(sp)
    80004fa4:	e3e2                	sd	s8,448(sp)
    80004fa6:	ff66                	sd	s9,440(sp)
    80004fa8:	fb6a                	sd	s10,432(sp)
    80004faa:	f76e                	sd	s11,424(sp)
    80004fac:	0c00                	addi	s0,sp,528
    80004fae:	84aa                	mv	s1,a0
    80004fb0:	dea43c23          	sd	a0,-520(s0)
    80004fb4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004fb8:	ffffd097          	auipc	ra,0xffffd
    80004fbc:	d2c080e7          	jalr	-724(ra) # 80001ce4 <myproc>
    80004fc0:	892a                	mv	s2,a0

  begin_op();
    80004fc2:	fffff097          	auipc	ra,0xfffff
    80004fc6:	446080e7          	jalr	1094(ra) # 80004408 <begin_op>

  if((ip = namei(path)) == 0){
    80004fca:	8526                	mv	a0,s1
    80004fcc:	fffff097          	auipc	ra,0xfffff
    80004fd0:	230080e7          	jalr	560(ra) # 800041fc <namei>
    80004fd4:	c92d                	beqz	a0,80005046 <exec+0xbc>
    80004fd6:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004fd8:	fffff097          	auipc	ra,0xfffff
    80004fdc:	a74080e7          	jalr	-1420(ra) # 80003a4c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004fe0:	04000713          	li	a4,64
    80004fe4:	4681                	li	a3,0
    80004fe6:	e4840613          	addi	a2,s0,-440
    80004fea:	4581                	li	a1,0
    80004fec:	8526                	mv	a0,s1
    80004fee:	fffff097          	auipc	ra,0xfffff
    80004ff2:	d12080e7          	jalr	-750(ra) # 80003d00 <readi>
    80004ff6:	04000793          	li	a5,64
    80004ffa:	00f51a63          	bne	a0,a5,8000500e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004ffe:	e4842703          	lw	a4,-440(s0)
    80005002:	464c47b7          	lui	a5,0x464c4
    80005006:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000500a:	04f70463          	beq	a4,a5,80005052 <exec+0xc8>
 bad:
  //printf("exec bad\n");
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000500e:	8526                	mv	a0,s1
    80005010:	fffff097          	auipc	ra,0xfffff
    80005014:	c9e080e7          	jalr	-866(ra) # 80003cae <iunlockput>
    end_op();
    80005018:	fffff097          	auipc	ra,0xfffff
    8000501c:	470080e7          	jalr	1136(ra) # 80004488 <end_op>
  }
  return -1;
    80005020:	557d                	li	a0,-1
}
    80005022:	20813083          	ld	ra,520(sp)
    80005026:	20013403          	ld	s0,512(sp)
    8000502a:	74fe                	ld	s1,504(sp)
    8000502c:	795e                	ld	s2,496(sp)
    8000502e:	79be                	ld	s3,488(sp)
    80005030:	7a1e                	ld	s4,480(sp)
    80005032:	6afe                	ld	s5,472(sp)
    80005034:	6b5e                	ld	s6,464(sp)
    80005036:	6bbe                	ld	s7,456(sp)
    80005038:	6c1e                	ld	s8,448(sp)
    8000503a:	7cfa                	ld	s9,440(sp)
    8000503c:	7d5a                	ld	s10,432(sp)
    8000503e:	7dba                	ld	s11,424(sp)
    80005040:	21010113          	addi	sp,sp,528
    80005044:	8082                	ret
    end_op();
    80005046:	fffff097          	auipc	ra,0xfffff
    8000504a:	442080e7          	jalr	1090(ra) # 80004488 <end_op>
    return -1;
    8000504e:	557d                	li	a0,-1
    80005050:	bfc9                	j	80005022 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005052:	854a                	mv	a0,s2
    80005054:	ffffd097          	auipc	ra,0xffffd
    80005058:	d54080e7          	jalr	-684(ra) # 80001da8 <proc_pagetable>
    8000505c:	8baa                	mv	s7,a0
    8000505e:	d945                	beqz	a0,8000500e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005060:	e6842983          	lw	s3,-408(s0)
    80005064:	e8045783          	lhu	a5,-384(s0)
    80005068:	c7ad                	beqz	a5,800050d2 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000506a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000506c:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    8000506e:	6c85                	lui	s9,0x1
    80005070:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005074:	def43823          	sd	a5,-528(s0)
    80005078:	a489                	j	800052ba <exec+0x330>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000507a:	00003517          	auipc	a0,0x3
    8000507e:	72650513          	addi	a0,a0,1830 # 800087a0 <syscalls+0x290>
    80005082:	ffffb097          	auipc	ra,0xffffb
    80005086:	4c6080e7          	jalr	1222(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000508a:	8756                	mv	a4,s5
    8000508c:	012d86bb          	addw	a3,s11,s2
    80005090:	4581                	li	a1,0
    80005092:	8526                	mv	a0,s1
    80005094:	fffff097          	auipc	ra,0xfffff
    80005098:	c6c080e7          	jalr	-916(ra) # 80003d00 <readi>
    8000509c:	2501                	sext.w	a0,a0
    8000509e:	1caa9563          	bne	s5,a0,80005268 <exec+0x2de>
  for(i = 0; i < sz; i += PGSIZE){
    800050a2:	6785                	lui	a5,0x1
    800050a4:	0127893b          	addw	s2,a5,s2
    800050a8:	77fd                	lui	a5,0xfffff
    800050aa:	01478a3b          	addw	s4,a5,s4
    800050ae:	1f897d63          	bgeu	s2,s8,800052a8 <exec+0x31e>
    pa = walkaddr(pagetable, va + i);
    800050b2:	02091593          	slli	a1,s2,0x20
    800050b6:	9181                	srli	a1,a1,0x20
    800050b8:	95ea                	add	a1,a1,s10
    800050ba:	855e                	mv	a0,s7
    800050bc:	ffffc097          	auipc	ra,0xffffc
    800050c0:	fea080e7          	jalr	-22(ra) # 800010a6 <walkaddr>
    800050c4:	862a                	mv	a2,a0
    if(pa == 0)
    800050c6:	d955                	beqz	a0,8000507a <exec+0xf0>
      n = PGSIZE;
    800050c8:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800050ca:	fd9a70e3          	bgeu	s4,s9,8000508a <exec+0x100>
      n = sz - i;
    800050ce:	8ad2                	mv	s5,s4
    800050d0:	bf6d                	j	8000508a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800050d2:	4901                	li	s2,0
  iunlockput(ip);
    800050d4:	8526                	mv	a0,s1
    800050d6:	fffff097          	auipc	ra,0xfffff
    800050da:	bd8080e7          	jalr	-1064(ra) # 80003cae <iunlockput>
  end_op();
    800050de:	fffff097          	auipc	ra,0xfffff
    800050e2:	3aa080e7          	jalr	938(ra) # 80004488 <end_op>
  p = myproc();
    800050e6:	ffffd097          	auipc	ra,0xffffd
    800050ea:	bfe080e7          	jalr	-1026(ra) # 80001ce4 <myproc>
    800050ee:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800050f0:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800050f4:	6785                	lui	a5,0x1
    800050f6:	17fd                	addi	a5,a5,-1
    800050f8:	993e                	add	s2,s2,a5
    800050fa:	757d                	lui	a0,0xfffff
    800050fc:	00a977b3          	and	a5,s2,a0
    80005100:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005104:	6609                	lui	a2,0x2
    80005106:	963e                	add	a2,a2,a5
    80005108:	85be                	mv	a1,a5
    8000510a:	855e                	mv	a0,s7
    8000510c:	ffffc097          	auipc	ra,0xffffc
    80005110:	3ce080e7          	jalr	974(ra) # 800014da <uvmalloc>
    80005114:	8b2a                	mv	s6,a0
  ip = 0;
    80005116:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005118:	14050863          	beqz	a0,80005268 <exec+0x2de>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000511c:	75f9                	lui	a1,0xffffe
    8000511e:	95aa                	add	a1,a1,a0
    80005120:	855e                	mv	a0,s7
    80005122:	ffffc097          	auipc	ra,0xffffc
    80005126:	5ee080e7          	jalr	1518(ra) # 80001710 <uvmclear>
  stackbase = sp - PGSIZE;
    8000512a:	7c7d                	lui	s8,0xfffff
    8000512c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000512e:	e0043783          	ld	a5,-512(s0)
    80005132:	6388                	ld	a0,0(a5)
    80005134:	c535                	beqz	a0,800051a0 <exec+0x216>
    80005136:	e8840993          	addi	s3,s0,-376
    8000513a:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000513e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005140:	ffffc097          	auipc	ra,0xffffc
    80005144:	d54080e7          	jalr	-684(ra) # 80000e94 <strlen>
    80005148:	2505                	addiw	a0,a0,1
    8000514a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000514e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005152:	13896f63          	bltu	s2,s8,80005290 <exec+0x306>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005156:	e0043d83          	ld	s11,-512(s0)
    8000515a:	000dba03          	ld	s4,0(s11)
    8000515e:	8552                	mv	a0,s4
    80005160:	ffffc097          	auipc	ra,0xffffc
    80005164:	d34080e7          	jalr	-716(ra) # 80000e94 <strlen>
    80005168:	0015069b          	addiw	a3,a0,1
    8000516c:	8652                	mv	a2,s4
    8000516e:	85ca                	mv	a1,s2
    80005170:	855e                	mv	a0,s7
    80005172:	ffffc097          	auipc	ra,0xffffc
    80005176:	5d0080e7          	jalr	1488(ra) # 80001742 <copyout>
    8000517a:	10054f63          	bltz	a0,80005298 <exec+0x30e>
    ustack[argc] = sp;
    8000517e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005182:	0485                	addi	s1,s1,1
    80005184:	008d8793          	addi	a5,s11,8
    80005188:	e0f43023          	sd	a5,-512(s0)
    8000518c:	008db503          	ld	a0,8(s11)
    80005190:	c911                	beqz	a0,800051a4 <exec+0x21a>
    if(argc >= MAXARG)
    80005192:	09a1                	addi	s3,s3,8
    80005194:	fb3c96e3          	bne	s9,s3,80005140 <exec+0x1b6>
  sz = sz1;
    80005198:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000519c:	4481                	li	s1,0
    8000519e:	a0e9                	j	80005268 <exec+0x2de>
  sp = sz;
    800051a0:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800051a2:	4481                	li	s1,0
  ustack[argc] = 0;
    800051a4:	00349793          	slli	a5,s1,0x3
    800051a8:	f9040713          	addi	a4,s0,-112
    800051ac:	97ba                	add	a5,a5,a4
    800051ae:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    800051b2:	00148693          	addi	a3,s1,1
    800051b6:	068e                	slli	a3,a3,0x3
    800051b8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800051bc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800051c0:	01897663          	bgeu	s2,s8,800051cc <exec+0x242>
  sz = sz1;
    800051c4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051c8:	4481                	li	s1,0
    800051ca:	a879                	j	80005268 <exec+0x2de>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800051cc:	e8840613          	addi	a2,s0,-376
    800051d0:	85ca                	mv	a1,s2
    800051d2:	855e                	mv	a0,s7
    800051d4:	ffffc097          	auipc	ra,0xffffc
    800051d8:	56e080e7          	jalr	1390(ra) # 80001742 <copyout>
    800051dc:	0c054263          	bltz	a0,800052a0 <exec+0x316>
  p->trapframe->a1 = sp;
    800051e0:	068ab783          	ld	a5,104(s5)
    800051e4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800051e8:	df843783          	ld	a5,-520(s0)
    800051ec:	0007c703          	lbu	a4,0(a5)
    800051f0:	cf11                	beqz	a4,8000520c <exec+0x282>
    800051f2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800051f4:	02f00693          	li	a3,47
    800051f8:	a029                	j	80005202 <exec+0x278>
  for(last=s=path; *s; s++)
    800051fa:	0785                	addi	a5,a5,1
    800051fc:	fff7c703          	lbu	a4,-1(a5)
    80005200:	c711                	beqz	a4,8000520c <exec+0x282>
    if(*s == '/')
    80005202:	fed71ce3          	bne	a4,a3,800051fa <exec+0x270>
      last = s+1;
    80005206:	def43c23          	sd	a5,-520(s0)
    8000520a:	bfc5                	j	800051fa <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000520c:	4641                	li	a2,16
    8000520e:	df843583          	ld	a1,-520(s0)
    80005212:	168a8513          	addi	a0,s5,360
    80005216:	ffffc097          	auipc	ra,0xffffc
    8000521a:	c4c080e7          	jalr	-948(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    8000521e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005222:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005226:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000522a:	068ab783          	ld	a5,104(s5)
    8000522e:	e6043703          	ld	a4,-416(s0)
    80005232:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005234:	068ab783          	ld	a5,104(s5)
    80005238:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000523c:	85ea                	mv	a1,s10
    8000523e:	ffffd097          	auipc	ra,0xffffd
    80005242:	c06080e7          	jalr	-1018(ra) # 80001e44 <proc_freepagetable>
  if(p->pid==1) vmprint(p->pagetable);
    80005246:	038aa703          	lw	a4,56(s5)
    8000524a:	4785                	li	a5,1
    8000524c:	00f70563          	beq	a4,a5,80005256 <exec+0x2cc>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005250:	0004851b          	sext.w	a0,s1
    80005254:	b3f9                	j	80005022 <exec+0x98>
  if(p->pid==1) vmprint(p->pagetable);
    80005256:	050ab503          	ld	a0,80(s5)
    8000525a:	ffffc097          	auipc	ra,0xffffc
    8000525e:	6b4080e7          	jalr	1716(ra) # 8000190e <vmprint>
    80005262:	b7fd                	j	80005250 <exec+0x2c6>
    80005264:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005268:	e0843583          	ld	a1,-504(s0)
    8000526c:	855e                	mv	a0,s7
    8000526e:	ffffd097          	auipc	ra,0xffffd
    80005272:	bd6080e7          	jalr	-1066(ra) # 80001e44 <proc_freepagetable>
  if(ip){
    80005276:	d8049ce3          	bnez	s1,8000500e <exec+0x84>
  return -1;
    8000527a:	557d                	li	a0,-1
    8000527c:	b35d                	j	80005022 <exec+0x98>
    8000527e:	e1243423          	sd	s2,-504(s0)
    80005282:	b7dd                	j	80005268 <exec+0x2de>
    80005284:	e1243423          	sd	s2,-504(s0)
    80005288:	b7c5                	j	80005268 <exec+0x2de>
    8000528a:	e1243423          	sd	s2,-504(s0)
    8000528e:	bfe9                	j	80005268 <exec+0x2de>
  sz = sz1;
    80005290:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005294:	4481                	li	s1,0
    80005296:	bfc9                	j	80005268 <exec+0x2de>
  sz = sz1;
    80005298:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000529c:	4481                	li	s1,0
    8000529e:	b7e9                	j	80005268 <exec+0x2de>
  sz = sz1;
    800052a0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052a4:	4481                	li	s1,0
    800052a6:	b7c9                	j	80005268 <exec+0x2de>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052a8:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052ac:	2b05                	addiw	s6,s6,1
    800052ae:	0389899b          	addiw	s3,s3,56
    800052b2:	e8045783          	lhu	a5,-384(s0)
    800052b6:	e0fb5fe3          	bge	s6,a5,800050d4 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800052ba:	2981                	sext.w	s3,s3
    800052bc:	03800713          	li	a4,56
    800052c0:	86ce                	mv	a3,s3
    800052c2:	e1040613          	addi	a2,s0,-496
    800052c6:	4581                	li	a1,0
    800052c8:	8526                	mv	a0,s1
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	a36080e7          	jalr	-1482(ra) # 80003d00 <readi>
    800052d2:	03800793          	li	a5,56
    800052d6:	f8f517e3          	bne	a0,a5,80005264 <exec+0x2da>
    if(ph.type != ELF_PROG_LOAD)
    800052da:	e1042783          	lw	a5,-496(s0)
    800052de:	4705                	li	a4,1
    800052e0:	fce796e3          	bne	a5,a4,800052ac <exec+0x322>
    if(ph.memsz < ph.filesz)
    800052e4:	e3843603          	ld	a2,-456(s0)
    800052e8:	e3043783          	ld	a5,-464(s0)
    800052ec:	f8f669e3          	bltu	a2,a5,8000527e <exec+0x2f4>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800052f0:	e2043783          	ld	a5,-480(s0)
    800052f4:	963e                	add	a2,a2,a5
    800052f6:	f8f667e3          	bltu	a2,a5,80005284 <exec+0x2fa>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052fa:	85ca                	mv	a1,s2
    800052fc:	855e                	mv	a0,s7
    800052fe:	ffffc097          	auipc	ra,0xffffc
    80005302:	1dc080e7          	jalr	476(ra) # 800014da <uvmalloc>
    80005306:	e0a43423          	sd	a0,-504(s0)
    8000530a:	d141                	beqz	a0,8000528a <exec+0x300>
    if(ph.vaddr % PGSIZE != 0)
    8000530c:	e2043d03          	ld	s10,-480(s0)
    80005310:	df043783          	ld	a5,-528(s0)
    80005314:	00fd77b3          	and	a5,s10,a5
    80005318:	fba1                	bnez	a5,80005268 <exec+0x2de>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000531a:	e1842d83          	lw	s11,-488(s0)
    8000531e:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005322:	f80c03e3          	beqz	s8,800052a8 <exec+0x31e>
    80005326:	8a62                	mv	s4,s8
    80005328:	4901                	li	s2,0
    8000532a:	b361                	j	800050b2 <exec+0x128>

000000008000532c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000532c:	7179                	addi	sp,sp,-48
    8000532e:	f406                	sd	ra,40(sp)
    80005330:	f022                	sd	s0,32(sp)
    80005332:	ec26                	sd	s1,24(sp)
    80005334:	e84a                	sd	s2,16(sp)
    80005336:	1800                	addi	s0,sp,48
    80005338:	892e                	mv	s2,a1
    8000533a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000533c:	fdc40593          	addi	a1,s0,-36
    80005340:	ffffe097          	auipc	ra,0xffffe
    80005344:	b9a080e7          	jalr	-1126(ra) # 80002eda <argint>
    80005348:	04054063          	bltz	a0,80005388 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000534c:	fdc42703          	lw	a4,-36(s0)
    80005350:	47bd                	li	a5,15
    80005352:	02e7ed63          	bltu	a5,a4,8000538c <argfd+0x60>
    80005356:	ffffd097          	auipc	ra,0xffffd
    8000535a:	98e080e7          	jalr	-1650(ra) # 80001ce4 <myproc>
    8000535e:	fdc42703          	lw	a4,-36(s0)
    80005362:	01c70793          	addi	a5,a4,28
    80005366:	078e                	slli	a5,a5,0x3
    80005368:	953e                	add	a0,a0,a5
    8000536a:	611c                	ld	a5,0(a0)
    8000536c:	c395                	beqz	a5,80005390 <argfd+0x64>
    return -1;
  if(pfd)
    8000536e:	00090463          	beqz	s2,80005376 <argfd+0x4a>
    *pfd = fd;
    80005372:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005376:	4501                	li	a0,0
  if(pf)
    80005378:	c091                	beqz	s1,8000537c <argfd+0x50>
    *pf = f;
    8000537a:	e09c                	sd	a5,0(s1)
}
    8000537c:	70a2                	ld	ra,40(sp)
    8000537e:	7402                	ld	s0,32(sp)
    80005380:	64e2                	ld	s1,24(sp)
    80005382:	6942                	ld	s2,16(sp)
    80005384:	6145                	addi	sp,sp,48
    80005386:	8082                	ret
    return -1;
    80005388:	557d                	li	a0,-1
    8000538a:	bfcd                	j	8000537c <argfd+0x50>
    return -1;
    8000538c:	557d                	li	a0,-1
    8000538e:	b7fd                	j	8000537c <argfd+0x50>
    80005390:	557d                	li	a0,-1
    80005392:	b7ed                	j	8000537c <argfd+0x50>

0000000080005394 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005394:	1101                	addi	sp,sp,-32
    80005396:	ec06                	sd	ra,24(sp)
    80005398:	e822                	sd	s0,16(sp)
    8000539a:	e426                	sd	s1,8(sp)
    8000539c:	1000                	addi	s0,sp,32
    8000539e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800053a0:	ffffd097          	auipc	ra,0xffffd
    800053a4:	944080e7          	jalr	-1724(ra) # 80001ce4 <myproc>
    800053a8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800053aa:	0e050793          	addi	a5,a0,224 # fffffffffffff0e0 <end+0xffffffff7ffd80c0>
    800053ae:	4501                	li	a0,0
    800053b0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800053b2:	6398                	ld	a4,0(a5)
    800053b4:	cb19                	beqz	a4,800053ca <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800053b6:	2505                	addiw	a0,a0,1
    800053b8:	07a1                	addi	a5,a5,8
    800053ba:	fed51ce3          	bne	a0,a3,800053b2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800053be:	557d                	li	a0,-1
}
    800053c0:	60e2                	ld	ra,24(sp)
    800053c2:	6442                	ld	s0,16(sp)
    800053c4:	64a2                	ld	s1,8(sp)
    800053c6:	6105                	addi	sp,sp,32
    800053c8:	8082                	ret
      p->ofile[fd] = f;
    800053ca:	01c50793          	addi	a5,a0,28
    800053ce:	078e                	slli	a5,a5,0x3
    800053d0:	963e                	add	a2,a2,a5
    800053d2:	e204                	sd	s1,0(a2)
      return fd;
    800053d4:	b7f5                	j	800053c0 <fdalloc+0x2c>

00000000800053d6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800053d6:	715d                	addi	sp,sp,-80
    800053d8:	e486                	sd	ra,72(sp)
    800053da:	e0a2                	sd	s0,64(sp)
    800053dc:	fc26                	sd	s1,56(sp)
    800053de:	f84a                	sd	s2,48(sp)
    800053e0:	f44e                	sd	s3,40(sp)
    800053e2:	f052                	sd	s4,32(sp)
    800053e4:	ec56                	sd	s5,24(sp)
    800053e6:	0880                	addi	s0,sp,80
    800053e8:	89ae                	mv	s3,a1
    800053ea:	8ab2                	mv	s5,a2
    800053ec:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800053ee:	fb040593          	addi	a1,s0,-80
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	e28080e7          	jalr	-472(ra) # 8000421a <nameiparent>
    800053fa:	892a                	mv	s2,a0
    800053fc:	12050f63          	beqz	a0,8000553a <create+0x164>
    return 0;

  ilock(dp);
    80005400:	ffffe097          	auipc	ra,0xffffe
    80005404:	64c080e7          	jalr	1612(ra) # 80003a4c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005408:	4601                	li	a2,0
    8000540a:	fb040593          	addi	a1,s0,-80
    8000540e:	854a                	mv	a0,s2
    80005410:	fffff097          	auipc	ra,0xfffff
    80005414:	b1a080e7          	jalr	-1254(ra) # 80003f2a <dirlookup>
    80005418:	84aa                	mv	s1,a0
    8000541a:	c921                	beqz	a0,8000546a <create+0x94>
    iunlockput(dp);
    8000541c:	854a                	mv	a0,s2
    8000541e:	fffff097          	auipc	ra,0xfffff
    80005422:	890080e7          	jalr	-1904(ra) # 80003cae <iunlockput>
    ilock(ip);
    80005426:	8526                	mv	a0,s1
    80005428:	ffffe097          	auipc	ra,0xffffe
    8000542c:	624080e7          	jalr	1572(ra) # 80003a4c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005430:	2981                	sext.w	s3,s3
    80005432:	4789                	li	a5,2
    80005434:	02f99463          	bne	s3,a5,8000545c <create+0x86>
    80005438:	0444d783          	lhu	a5,68(s1)
    8000543c:	37f9                	addiw	a5,a5,-2
    8000543e:	17c2                	slli	a5,a5,0x30
    80005440:	93c1                	srli	a5,a5,0x30
    80005442:	4705                	li	a4,1
    80005444:	00f76c63          	bltu	a4,a5,8000545c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005448:	8526                	mv	a0,s1
    8000544a:	60a6                	ld	ra,72(sp)
    8000544c:	6406                	ld	s0,64(sp)
    8000544e:	74e2                	ld	s1,56(sp)
    80005450:	7942                	ld	s2,48(sp)
    80005452:	79a2                	ld	s3,40(sp)
    80005454:	7a02                	ld	s4,32(sp)
    80005456:	6ae2                	ld	s5,24(sp)
    80005458:	6161                	addi	sp,sp,80
    8000545a:	8082                	ret
    iunlockput(ip);
    8000545c:	8526                	mv	a0,s1
    8000545e:	fffff097          	auipc	ra,0xfffff
    80005462:	850080e7          	jalr	-1968(ra) # 80003cae <iunlockput>
    return 0;
    80005466:	4481                	li	s1,0
    80005468:	b7c5                	j	80005448 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000546a:	85ce                	mv	a1,s3
    8000546c:	00092503          	lw	a0,0(s2)
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	444080e7          	jalr	1092(ra) # 800038b4 <ialloc>
    80005478:	84aa                	mv	s1,a0
    8000547a:	c529                	beqz	a0,800054c4 <create+0xee>
  ilock(ip);
    8000547c:	ffffe097          	auipc	ra,0xffffe
    80005480:	5d0080e7          	jalr	1488(ra) # 80003a4c <ilock>
  ip->major = major;
    80005484:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005488:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000548c:	4785                	li	a5,1
    8000548e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005492:	8526                	mv	a0,s1
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	4ee080e7          	jalr	1262(ra) # 80003982 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000549c:	2981                	sext.w	s3,s3
    8000549e:	4785                	li	a5,1
    800054a0:	02f98a63          	beq	s3,a5,800054d4 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800054a4:	40d0                	lw	a2,4(s1)
    800054a6:	fb040593          	addi	a1,s0,-80
    800054aa:	854a                	mv	a0,s2
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	c8e080e7          	jalr	-882(ra) # 8000413a <dirlink>
    800054b4:	06054b63          	bltz	a0,8000552a <create+0x154>
  iunlockput(dp);
    800054b8:	854a                	mv	a0,s2
    800054ba:	ffffe097          	auipc	ra,0xffffe
    800054be:	7f4080e7          	jalr	2036(ra) # 80003cae <iunlockput>
  return ip;
    800054c2:	b759                	j	80005448 <create+0x72>
    panic("create: ialloc");
    800054c4:	00003517          	auipc	a0,0x3
    800054c8:	2fc50513          	addi	a0,a0,764 # 800087c0 <syscalls+0x2b0>
    800054cc:	ffffb097          	auipc	ra,0xffffb
    800054d0:	07c080e7          	jalr	124(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800054d4:	04a95783          	lhu	a5,74(s2)
    800054d8:	2785                	addiw	a5,a5,1
    800054da:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800054de:	854a                	mv	a0,s2
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	4a2080e7          	jalr	1186(ra) # 80003982 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800054e8:	40d0                	lw	a2,4(s1)
    800054ea:	00003597          	auipc	a1,0x3
    800054ee:	2e658593          	addi	a1,a1,742 # 800087d0 <syscalls+0x2c0>
    800054f2:	8526                	mv	a0,s1
    800054f4:	fffff097          	auipc	ra,0xfffff
    800054f8:	c46080e7          	jalr	-954(ra) # 8000413a <dirlink>
    800054fc:	00054f63          	bltz	a0,8000551a <create+0x144>
    80005500:	00492603          	lw	a2,4(s2)
    80005504:	00003597          	auipc	a1,0x3
    80005508:	2d458593          	addi	a1,a1,724 # 800087d8 <syscalls+0x2c8>
    8000550c:	8526                	mv	a0,s1
    8000550e:	fffff097          	auipc	ra,0xfffff
    80005512:	c2c080e7          	jalr	-980(ra) # 8000413a <dirlink>
    80005516:	f80557e3          	bgez	a0,800054a4 <create+0xce>
      panic("create dots");
    8000551a:	00003517          	auipc	a0,0x3
    8000551e:	2c650513          	addi	a0,a0,710 # 800087e0 <syscalls+0x2d0>
    80005522:	ffffb097          	auipc	ra,0xffffb
    80005526:	026080e7          	jalr	38(ra) # 80000548 <panic>
    panic("create: dirlink");
    8000552a:	00003517          	auipc	a0,0x3
    8000552e:	2c650513          	addi	a0,a0,710 # 800087f0 <syscalls+0x2e0>
    80005532:	ffffb097          	auipc	ra,0xffffb
    80005536:	016080e7          	jalr	22(ra) # 80000548 <panic>
    return 0;
    8000553a:	84aa                	mv	s1,a0
    8000553c:	b731                	j	80005448 <create+0x72>

000000008000553e <sys_dup>:
{
    8000553e:	7179                	addi	sp,sp,-48
    80005540:	f406                	sd	ra,40(sp)
    80005542:	f022                	sd	s0,32(sp)
    80005544:	ec26                	sd	s1,24(sp)
    80005546:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005548:	fd840613          	addi	a2,s0,-40
    8000554c:	4581                	li	a1,0
    8000554e:	4501                	li	a0,0
    80005550:	00000097          	auipc	ra,0x0
    80005554:	ddc080e7          	jalr	-548(ra) # 8000532c <argfd>
    return -1;
    80005558:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000555a:	02054363          	bltz	a0,80005580 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000555e:	fd843503          	ld	a0,-40(s0)
    80005562:	00000097          	auipc	ra,0x0
    80005566:	e32080e7          	jalr	-462(ra) # 80005394 <fdalloc>
    8000556a:	84aa                	mv	s1,a0
    return -1;
    8000556c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000556e:	00054963          	bltz	a0,80005580 <sys_dup+0x42>
  filedup(f);
    80005572:	fd843503          	ld	a0,-40(s0)
    80005576:	fffff097          	auipc	ra,0xfffff
    8000557a:	312080e7          	jalr	786(ra) # 80004888 <filedup>
  return fd;
    8000557e:	87a6                	mv	a5,s1
}
    80005580:	853e                	mv	a0,a5
    80005582:	70a2                	ld	ra,40(sp)
    80005584:	7402                	ld	s0,32(sp)
    80005586:	64e2                	ld	s1,24(sp)
    80005588:	6145                	addi	sp,sp,48
    8000558a:	8082                	ret

000000008000558c <sys_read>:
{
    8000558c:	7179                	addi	sp,sp,-48
    8000558e:	f406                	sd	ra,40(sp)
    80005590:	f022                	sd	s0,32(sp)
    80005592:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005594:	fe840613          	addi	a2,s0,-24
    80005598:	4581                	li	a1,0
    8000559a:	4501                	li	a0,0
    8000559c:	00000097          	auipc	ra,0x0
    800055a0:	d90080e7          	jalr	-624(ra) # 8000532c <argfd>
    return -1;
    800055a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055a6:	04054163          	bltz	a0,800055e8 <sys_read+0x5c>
    800055aa:	fe440593          	addi	a1,s0,-28
    800055ae:	4509                	li	a0,2
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	92a080e7          	jalr	-1750(ra) # 80002eda <argint>
    return -1;
    800055b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055ba:	02054763          	bltz	a0,800055e8 <sys_read+0x5c>
    800055be:	fd840593          	addi	a1,s0,-40
    800055c2:	4505                	li	a0,1
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	938080e7          	jalr	-1736(ra) # 80002efc <argaddr>
    return -1;
    800055cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055ce:	00054d63          	bltz	a0,800055e8 <sys_read+0x5c>
  return fileread(f, p, n);
    800055d2:	fe442603          	lw	a2,-28(s0)
    800055d6:	fd843583          	ld	a1,-40(s0)
    800055da:	fe843503          	ld	a0,-24(s0)
    800055de:	fffff097          	auipc	ra,0xfffff
    800055e2:	436080e7          	jalr	1078(ra) # 80004a14 <fileread>
    800055e6:	87aa                	mv	a5,a0
}
    800055e8:	853e                	mv	a0,a5
    800055ea:	70a2                	ld	ra,40(sp)
    800055ec:	7402                	ld	s0,32(sp)
    800055ee:	6145                	addi	sp,sp,48
    800055f0:	8082                	ret

00000000800055f2 <sys_write>:
{
    800055f2:	7179                	addi	sp,sp,-48
    800055f4:	f406                	sd	ra,40(sp)
    800055f6:	f022                	sd	s0,32(sp)
    800055f8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055fa:	fe840613          	addi	a2,s0,-24
    800055fe:	4581                	li	a1,0
    80005600:	4501                	li	a0,0
    80005602:	00000097          	auipc	ra,0x0
    80005606:	d2a080e7          	jalr	-726(ra) # 8000532c <argfd>
    return -1;
    8000560a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000560c:	04054163          	bltz	a0,8000564e <sys_write+0x5c>
    80005610:	fe440593          	addi	a1,s0,-28
    80005614:	4509                	li	a0,2
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	8c4080e7          	jalr	-1852(ra) # 80002eda <argint>
    return -1;
    8000561e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005620:	02054763          	bltz	a0,8000564e <sys_write+0x5c>
    80005624:	fd840593          	addi	a1,s0,-40
    80005628:	4505                	li	a0,1
    8000562a:	ffffe097          	auipc	ra,0xffffe
    8000562e:	8d2080e7          	jalr	-1838(ra) # 80002efc <argaddr>
    return -1;
    80005632:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005634:	00054d63          	bltz	a0,8000564e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005638:	fe442603          	lw	a2,-28(s0)
    8000563c:	fd843583          	ld	a1,-40(s0)
    80005640:	fe843503          	ld	a0,-24(s0)
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	492080e7          	jalr	1170(ra) # 80004ad6 <filewrite>
    8000564c:	87aa                	mv	a5,a0
}
    8000564e:	853e                	mv	a0,a5
    80005650:	70a2                	ld	ra,40(sp)
    80005652:	7402                	ld	s0,32(sp)
    80005654:	6145                	addi	sp,sp,48
    80005656:	8082                	ret

0000000080005658 <sys_close>:
{
    80005658:	1101                	addi	sp,sp,-32
    8000565a:	ec06                	sd	ra,24(sp)
    8000565c:	e822                	sd	s0,16(sp)
    8000565e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005660:	fe040613          	addi	a2,s0,-32
    80005664:	fec40593          	addi	a1,s0,-20
    80005668:	4501                	li	a0,0
    8000566a:	00000097          	auipc	ra,0x0
    8000566e:	cc2080e7          	jalr	-830(ra) # 8000532c <argfd>
    return -1;
    80005672:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005674:	02054463          	bltz	a0,8000569c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005678:	ffffc097          	auipc	ra,0xffffc
    8000567c:	66c080e7          	jalr	1644(ra) # 80001ce4 <myproc>
    80005680:	fec42783          	lw	a5,-20(s0)
    80005684:	07f1                	addi	a5,a5,28
    80005686:	078e                	slli	a5,a5,0x3
    80005688:	97aa                	add	a5,a5,a0
    8000568a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000568e:	fe043503          	ld	a0,-32(s0)
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	248080e7          	jalr	584(ra) # 800048da <fileclose>
  return 0;
    8000569a:	4781                	li	a5,0
}
    8000569c:	853e                	mv	a0,a5
    8000569e:	60e2                	ld	ra,24(sp)
    800056a0:	6442                	ld	s0,16(sp)
    800056a2:	6105                	addi	sp,sp,32
    800056a4:	8082                	ret

00000000800056a6 <sys_fstat>:
{
    800056a6:	1101                	addi	sp,sp,-32
    800056a8:	ec06                	sd	ra,24(sp)
    800056aa:	e822                	sd	s0,16(sp)
    800056ac:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056ae:	fe840613          	addi	a2,s0,-24
    800056b2:	4581                	li	a1,0
    800056b4:	4501                	li	a0,0
    800056b6:	00000097          	auipc	ra,0x0
    800056ba:	c76080e7          	jalr	-906(ra) # 8000532c <argfd>
    return -1;
    800056be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056c0:	02054563          	bltz	a0,800056ea <sys_fstat+0x44>
    800056c4:	fe040593          	addi	a1,s0,-32
    800056c8:	4505                	li	a0,1
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	832080e7          	jalr	-1998(ra) # 80002efc <argaddr>
    return -1;
    800056d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056d4:	00054b63          	bltz	a0,800056ea <sys_fstat+0x44>
  return filestat(f, st);
    800056d8:	fe043583          	ld	a1,-32(s0)
    800056dc:	fe843503          	ld	a0,-24(s0)
    800056e0:	fffff097          	auipc	ra,0xfffff
    800056e4:	2c2080e7          	jalr	706(ra) # 800049a2 <filestat>
    800056e8:	87aa                	mv	a5,a0
}
    800056ea:	853e                	mv	a0,a5
    800056ec:	60e2                	ld	ra,24(sp)
    800056ee:	6442                	ld	s0,16(sp)
    800056f0:	6105                	addi	sp,sp,32
    800056f2:	8082                	ret

00000000800056f4 <sys_link>:
{
    800056f4:	7169                	addi	sp,sp,-304
    800056f6:	f606                	sd	ra,296(sp)
    800056f8:	f222                	sd	s0,288(sp)
    800056fa:	ee26                	sd	s1,280(sp)
    800056fc:	ea4a                	sd	s2,272(sp)
    800056fe:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005700:	08000613          	li	a2,128
    80005704:	ed040593          	addi	a1,s0,-304
    80005708:	4501                	li	a0,0
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	814080e7          	jalr	-2028(ra) # 80002f1e <argstr>
    return -1;
    80005712:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005714:	10054e63          	bltz	a0,80005830 <sys_link+0x13c>
    80005718:	08000613          	li	a2,128
    8000571c:	f5040593          	addi	a1,s0,-176
    80005720:	4505                	li	a0,1
    80005722:	ffffd097          	auipc	ra,0xffffd
    80005726:	7fc080e7          	jalr	2044(ra) # 80002f1e <argstr>
    return -1;
    8000572a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000572c:	10054263          	bltz	a0,80005830 <sys_link+0x13c>
  begin_op();
    80005730:	fffff097          	auipc	ra,0xfffff
    80005734:	cd8080e7          	jalr	-808(ra) # 80004408 <begin_op>
  if((ip = namei(old)) == 0){
    80005738:	ed040513          	addi	a0,s0,-304
    8000573c:	fffff097          	auipc	ra,0xfffff
    80005740:	ac0080e7          	jalr	-1344(ra) # 800041fc <namei>
    80005744:	84aa                	mv	s1,a0
    80005746:	c551                	beqz	a0,800057d2 <sys_link+0xde>
  ilock(ip);
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	304080e7          	jalr	772(ra) # 80003a4c <ilock>
  if(ip->type == T_DIR){
    80005750:	04449703          	lh	a4,68(s1)
    80005754:	4785                	li	a5,1
    80005756:	08f70463          	beq	a4,a5,800057de <sys_link+0xea>
  ip->nlink++;
    8000575a:	04a4d783          	lhu	a5,74(s1)
    8000575e:	2785                	addiw	a5,a5,1
    80005760:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005764:	8526                	mv	a0,s1
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	21c080e7          	jalr	540(ra) # 80003982 <iupdate>
  iunlock(ip);
    8000576e:	8526                	mv	a0,s1
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	39e080e7          	jalr	926(ra) # 80003b0e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005778:	fd040593          	addi	a1,s0,-48
    8000577c:	f5040513          	addi	a0,s0,-176
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	a9a080e7          	jalr	-1382(ra) # 8000421a <nameiparent>
    80005788:	892a                	mv	s2,a0
    8000578a:	c935                	beqz	a0,800057fe <sys_link+0x10a>
  ilock(dp);
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	2c0080e7          	jalr	704(ra) # 80003a4c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005794:	00092703          	lw	a4,0(s2)
    80005798:	409c                	lw	a5,0(s1)
    8000579a:	04f71d63          	bne	a4,a5,800057f4 <sys_link+0x100>
    8000579e:	40d0                	lw	a2,4(s1)
    800057a0:	fd040593          	addi	a1,s0,-48
    800057a4:	854a                	mv	a0,s2
    800057a6:	fffff097          	auipc	ra,0xfffff
    800057aa:	994080e7          	jalr	-1644(ra) # 8000413a <dirlink>
    800057ae:	04054363          	bltz	a0,800057f4 <sys_link+0x100>
  iunlockput(dp);
    800057b2:	854a                	mv	a0,s2
    800057b4:	ffffe097          	auipc	ra,0xffffe
    800057b8:	4fa080e7          	jalr	1274(ra) # 80003cae <iunlockput>
  iput(ip);
    800057bc:	8526                	mv	a0,s1
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	448080e7          	jalr	1096(ra) # 80003c06 <iput>
  end_op();
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	cc2080e7          	jalr	-830(ra) # 80004488 <end_op>
  return 0;
    800057ce:	4781                	li	a5,0
    800057d0:	a085                	j	80005830 <sys_link+0x13c>
    end_op();
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	cb6080e7          	jalr	-842(ra) # 80004488 <end_op>
    return -1;
    800057da:	57fd                	li	a5,-1
    800057dc:	a891                	j	80005830 <sys_link+0x13c>
    iunlockput(ip);
    800057de:	8526                	mv	a0,s1
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	4ce080e7          	jalr	1230(ra) # 80003cae <iunlockput>
    end_op();
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	ca0080e7          	jalr	-864(ra) # 80004488 <end_op>
    return -1;
    800057f0:	57fd                	li	a5,-1
    800057f2:	a83d                	j	80005830 <sys_link+0x13c>
    iunlockput(dp);
    800057f4:	854a                	mv	a0,s2
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	4b8080e7          	jalr	1208(ra) # 80003cae <iunlockput>
  ilock(ip);
    800057fe:	8526                	mv	a0,s1
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	24c080e7          	jalr	588(ra) # 80003a4c <ilock>
  ip->nlink--;
    80005808:	04a4d783          	lhu	a5,74(s1)
    8000580c:	37fd                	addiw	a5,a5,-1
    8000580e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005812:	8526                	mv	a0,s1
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	16e080e7          	jalr	366(ra) # 80003982 <iupdate>
  iunlockput(ip);
    8000581c:	8526                	mv	a0,s1
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	490080e7          	jalr	1168(ra) # 80003cae <iunlockput>
  end_op();
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	c62080e7          	jalr	-926(ra) # 80004488 <end_op>
  return -1;
    8000582e:	57fd                	li	a5,-1
}
    80005830:	853e                	mv	a0,a5
    80005832:	70b2                	ld	ra,296(sp)
    80005834:	7412                	ld	s0,288(sp)
    80005836:	64f2                	ld	s1,280(sp)
    80005838:	6952                	ld	s2,272(sp)
    8000583a:	6155                	addi	sp,sp,304
    8000583c:	8082                	ret

000000008000583e <sys_unlink>:
{
    8000583e:	7151                	addi	sp,sp,-240
    80005840:	f586                	sd	ra,232(sp)
    80005842:	f1a2                	sd	s0,224(sp)
    80005844:	eda6                	sd	s1,216(sp)
    80005846:	e9ca                	sd	s2,208(sp)
    80005848:	e5ce                	sd	s3,200(sp)
    8000584a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000584c:	08000613          	li	a2,128
    80005850:	f3040593          	addi	a1,s0,-208
    80005854:	4501                	li	a0,0
    80005856:	ffffd097          	auipc	ra,0xffffd
    8000585a:	6c8080e7          	jalr	1736(ra) # 80002f1e <argstr>
    8000585e:	18054163          	bltz	a0,800059e0 <sys_unlink+0x1a2>
  begin_op();
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	ba6080e7          	jalr	-1114(ra) # 80004408 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000586a:	fb040593          	addi	a1,s0,-80
    8000586e:	f3040513          	addi	a0,s0,-208
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	9a8080e7          	jalr	-1624(ra) # 8000421a <nameiparent>
    8000587a:	84aa                	mv	s1,a0
    8000587c:	c979                	beqz	a0,80005952 <sys_unlink+0x114>
  ilock(dp);
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	1ce080e7          	jalr	462(ra) # 80003a4c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005886:	00003597          	auipc	a1,0x3
    8000588a:	f4a58593          	addi	a1,a1,-182 # 800087d0 <syscalls+0x2c0>
    8000588e:	fb040513          	addi	a0,s0,-80
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	67e080e7          	jalr	1662(ra) # 80003f10 <namecmp>
    8000589a:	14050a63          	beqz	a0,800059ee <sys_unlink+0x1b0>
    8000589e:	00003597          	auipc	a1,0x3
    800058a2:	f3a58593          	addi	a1,a1,-198 # 800087d8 <syscalls+0x2c8>
    800058a6:	fb040513          	addi	a0,s0,-80
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	666080e7          	jalr	1638(ra) # 80003f10 <namecmp>
    800058b2:	12050e63          	beqz	a0,800059ee <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800058b6:	f2c40613          	addi	a2,s0,-212
    800058ba:	fb040593          	addi	a1,s0,-80
    800058be:	8526                	mv	a0,s1
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	66a080e7          	jalr	1642(ra) # 80003f2a <dirlookup>
    800058c8:	892a                	mv	s2,a0
    800058ca:	12050263          	beqz	a0,800059ee <sys_unlink+0x1b0>
  ilock(ip);
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	17e080e7          	jalr	382(ra) # 80003a4c <ilock>
  if(ip->nlink < 1)
    800058d6:	04a91783          	lh	a5,74(s2)
    800058da:	08f05263          	blez	a5,8000595e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800058de:	04491703          	lh	a4,68(s2)
    800058e2:	4785                	li	a5,1
    800058e4:	08f70563          	beq	a4,a5,8000596e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800058e8:	4641                	li	a2,16
    800058ea:	4581                	li	a1,0
    800058ec:	fc040513          	addi	a0,s0,-64
    800058f0:	ffffb097          	auipc	ra,0xffffb
    800058f4:	41c080e7          	jalr	1052(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058f8:	4741                	li	a4,16
    800058fa:	f2c42683          	lw	a3,-212(s0)
    800058fe:	fc040613          	addi	a2,s0,-64
    80005902:	4581                	li	a1,0
    80005904:	8526                	mv	a0,s1
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	4f0080e7          	jalr	1264(ra) # 80003df6 <writei>
    8000590e:	47c1                	li	a5,16
    80005910:	0af51563          	bne	a0,a5,800059ba <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005914:	04491703          	lh	a4,68(s2)
    80005918:	4785                	li	a5,1
    8000591a:	0af70863          	beq	a4,a5,800059ca <sys_unlink+0x18c>
  iunlockput(dp);
    8000591e:	8526                	mv	a0,s1
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	38e080e7          	jalr	910(ra) # 80003cae <iunlockput>
  ip->nlink--;
    80005928:	04a95783          	lhu	a5,74(s2)
    8000592c:	37fd                	addiw	a5,a5,-1
    8000592e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005932:	854a                	mv	a0,s2
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	04e080e7          	jalr	78(ra) # 80003982 <iupdate>
  iunlockput(ip);
    8000593c:	854a                	mv	a0,s2
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	370080e7          	jalr	880(ra) # 80003cae <iunlockput>
  end_op();
    80005946:	fffff097          	auipc	ra,0xfffff
    8000594a:	b42080e7          	jalr	-1214(ra) # 80004488 <end_op>
  return 0;
    8000594e:	4501                	li	a0,0
    80005950:	a84d                	j	80005a02 <sys_unlink+0x1c4>
    end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	b36080e7          	jalr	-1226(ra) # 80004488 <end_op>
    return -1;
    8000595a:	557d                	li	a0,-1
    8000595c:	a05d                	j	80005a02 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000595e:	00003517          	auipc	a0,0x3
    80005962:	ea250513          	addi	a0,a0,-350 # 80008800 <syscalls+0x2f0>
    80005966:	ffffb097          	auipc	ra,0xffffb
    8000596a:	be2080e7          	jalr	-1054(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000596e:	04c92703          	lw	a4,76(s2)
    80005972:	02000793          	li	a5,32
    80005976:	f6e7f9e3          	bgeu	a5,a4,800058e8 <sys_unlink+0xaa>
    8000597a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000597e:	4741                	li	a4,16
    80005980:	86ce                	mv	a3,s3
    80005982:	f1840613          	addi	a2,s0,-232
    80005986:	4581                	li	a1,0
    80005988:	854a                	mv	a0,s2
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	376080e7          	jalr	886(ra) # 80003d00 <readi>
    80005992:	47c1                	li	a5,16
    80005994:	00f51b63          	bne	a0,a5,800059aa <sys_unlink+0x16c>
    if(de.inum != 0)
    80005998:	f1845783          	lhu	a5,-232(s0)
    8000599c:	e7a1                	bnez	a5,800059e4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000599e:	29c1                	addiw	s3,s3,16
    800059a0:	04c92783          	lw	a5,76(s2)
    800059a4:	fcf9ede3          	bltu	s3,a5,8000597e <sys_unlink+0x140>
    800059a8:	b781                	j	800058e8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800059aa:	00003517          	auipc	a0,0x3
    800059ae:	e6e50513          	addi	a0,a0,-402 # 80008818 <syscalls+0x308>
    800059b2:	ffffb097          	auipc	ra,0xffffb
    800059b6:	b96080e7          	jalr	-1130(ra) # 80000548 <panic>
    panic("unlink: writei");
    800059ba:	00003517          	auipc	a0,0x3
    800059be:	e7650513          	addi	a0,a0,-394 # 80008830 <syscalls+0x320>
    800059c2:	ffffb097          	auipc	ra,0xffffb
    800059c6:	b86080e7          	jalr	-1146(ra) # 80000548 <panic>
    dp->nlink--;
    800059ca:	04a4d783          	lhu	a5,74(s1)
    800059ce:	37fd                	addiw	a5,a5,-1
    800059d0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800059d4:	8526                	mv	a0,s1
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	fac080e7          	jalr	-84(ra) # 80003982 <iupdate>
    800059de:	b781                	j	8000591e <sys_unlink+0xe0>
    return -1;
    800059e0:	557d                	li	a0,-1
    800059e2:	a005                	j	80005a02 <sys_unlink+0x1c4>
    iunlockput(ip);
    800059e4:	854a                	mv	a0,s2
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	2c8080e7          	jalr	712(ra) # 80003cae <iunlockput>
  iunlockput(dp);
    800059ee:	8526                	mv	a0,s1
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	2be080e7          	jalr	702(ra) # 80003cae <iunlockput>
  end_op();
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	a90080e7          	jalr	-1392(ra) # 80004488 <end_op>
  return -1;
    80005a00:	557d                	li	a0,-1
}
    80005a02:	70ae                	ld	ra,232(sp)
    80005a04:	740e                	ld	s0,224(sp)
    80005a06:	64ee                	ld	s1,216(sp)
    80005a08:	694e                	ld	s2,208(sp)
    80005a0a:	69ae                	ld	s3,200(sp)
    80005a0c:	616d                	addi	sp,sp,240
    80005a0e:	8082                	ret

0000000080005a10 <sys_open>:

uint64
sys_open(void)
{
    80005a10:	7131                	addi	sp,sp,-192
    80005a12:	fd06                	sd	ra,184(sp)
    80005a14:	f922                	sd	s0,176(sp)
    80005a16:	f526                	sd	s1,168(sp)
    80005a18:	f14a                	sd	s2,160(sp)
    80005a1a:	ed4e                	sd	s3,152(sp)
    80005a1c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a1e:	08000613          	li	a2,128
    80005a22:	f5040593          	addi	a1,s0,-176
    80005a26:	4501                	li	a0,0
    80005a28:	ffffd097          	auipc	ra,0xffffd
    80005a2c:	4f6080e7          	jalr	1270(ra) # 80002f1e <argstr>
    return -1;
    80005a30:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a32:	0c054163          	bltz	a0,80005af4 <sys_open+0xe4>
    80005a36:	f4c40593          	addi	a1,s0,-180
    80005a3a:	4505                	li	a0,1
    80005a3c:	ffffd097          	auipc	ra,0xffffd
    80005a40:	49e080e7          	jalr	1182(ra) # 80002eda <argint>
    80005a44:	0a054863          	bltz	a0,80005af4 <sys_open+0xe4>

  begin_op();
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	9c0080e7          	jalr	-1600(ra) # 80004408 <begin_op>

  if(omode & O_CREATE){
    80005a50:	f4c42783          	lw	a5,-180(s0)
    80005a54:	2007f793          	andi	a5,a5,512
    80005a58:	cbdd                	beqz	a5,80005b0e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a5a:	4681                	li	a3,0
    80005a5c:	4601                	li	a2,0
    80005a5e:	4589                	li	a1,2
    80005a60:	f5040513          	addi	a0,s0,-176
    80005a64:	00000097          	auipc	ra,0x0
    80005a68:	972080e7          	jalr	-1678(ra) # 800053d6 <create>
    80005a6c:	892a                	mv	s2,a0
    if(ip == 0){
    80005a6e:	c959                	beqz	a0,80005b04 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a70:	04491703          	lh	a4,68(s2)
    80005a74:	478d                	li	a5,3
    80005a76:	00f71763          	bne	a4,a5,80005a84 <sys_open+0x74>
    80005a7a:	04695703          	lhu	a4,70(s2)
    80005a7e:	47a5                	li	a5,9
    80005a80:	0ce7ec63          	bltu	a5,a4,80005b58 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	d9a080e7          	jalr	-614(ra) # 8000481e <filealloc>
    80005a8c:	89aa                	mv	s3,a0
    80005a8e:	10050263          	beqz	a0,80005b92 <sys_open+0x182>
    80005a92:	00000097          	auipc	ra,0x0
    80005a96:	902080e7          	jalr	-1790(ra) # 80005394 <fdalloc>
    80005a9a:	84aa                	mv	s1,a0
    80005a9c:	0e054663          	bltz	a0,80005b88 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005aa0:	04491703          	lh	a4,68(s2)
    80005aa4:	478d                	li	a5,3
    80005aa6:	0cf70463          	beq	a4,a5,80005b6e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005aaa:	4789                	li	a5,2
    80005aac:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ab0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ab4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ab8:	f4c42783          	lw	a5,-180(s0)
    80005abc:	0017c713          	xori	a4,a5,1
    80005ac0:	8b05                	andi	a4,a4,1
    80005ac2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ac6:	0037f713          	andi	a4,a5,3
    80005aca:	00e03733          	snez	a4,a4
    80005ace:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ad2:	4007f793          	andi	a5,a5,1024
    80005ad6:	c791                	beqz	a5,80005ae2 <sys_open+0xd2>
    80005ad8:	04491703          	lh	a4,68(s2)
    80005adc:	4789                	li	a5,2
    80005ade:	08f70f63          	beq	a4,a5,80005b7c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ae2:	854a                	mv	a0,s2
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	02a080e7          	jalr	42(ra) # 80003b0e <iunlock>
  end_op();
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	99c080e7          	jalr	-1636(ra) # 80004488 <end_op>

  return fd;
}
    80005af4:	8526                	mv	a0,s1
    80005af6:	70ea                	ld	ra,184(sp)
    80005af8:	744a                	ld	s0,176(sp)
    80005afa:	74aa                	ld	s1,168(sp)
    80005afc:	790a                	ld	s2,160(sp)
    80005afe:	69ea                	ld	s3,152(sp)
    80005b00:	6129                	addi	sp,sp,192
    80005b02:	8082                	ret
      end_op();
    80005b04:	fffff097          	auipc	ra,0xfffff
    80005b08:	984080e7          	jalr	-1660(ra) # 80004488 <end_op>
      return -1;
    80005b0c:	b7e5                	j	80005af4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b0e:	f5040513          	addi	a0,s0,-176
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	6ea080e7          	jalr	1770(ra) # 800041fc <namei>
    80005b1a:	892a                	mv	s2,a0
    80005b1c:	c905                	beqz	a0,80005b4c <sys_open+0x13c>
    ilock(ip);
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	f2e080e7          	jalr	-210(ra) # 80003a4c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b26:	04491703          	lh	a4,68(s2)
    80005b2a:	4785                	li	a5,1
    80005b2c:	f4f712e3          	bne	a4,a5,80005a70 <sys_open+0x60>
    80005b30:	f4c42783          	lw	a5,-180(s0)
    80005b34:	dba1                	beqz	a5,80005a84 <sys_open+0x74>
      iunlockput(ip);
    80005b36:	854a                	mv	a0,s2
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	176080e7          	jalr	374(ra) # 80003cae <iunlockput>
      end_op();
    80005b40:	fffff097          	auipc	ra,0xfffff
    80005b44:	948080e7          	jalr	-1720(ra) # 80004488 <end_op>
      return -1;
    80005b48:	54fd                	li	s1,-1
    80005b4a:	b76d                	j	80005af4 <sys_open+0xe4>
      end_op();
    80005b4c:	fffff097          	auipc	ra,0xfffff
    80005b50:	93c080e7          	jalr	-1732(ra) # 80004488 <end_op>
      return -1;
    80005b54:	54fd                	li	s1,-1
    80005b56:	bf79                	j	80005af4 <sys_open+0xe4>
    iunlockput(ip);
    80005b58:	854a                	mv	a0,s2
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	154080e7          	jalr	340(ra) # 80003cae <iunlockput>
    end_op();
    80005b62:	fffff097          	auipc	ra,0xfffff
    80005b66:	926080e7          	jalr	-1754(ra) # 80004488 <end_op>
    return -1;
    80005b6a:	54fd                	li	s1,-1
    80005b6c:	b761                	j	80005af4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b6e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b72:	04691783          	lh	a5,70(s2)
    80005b76:	02f99223          	sh	a5,36(s3)
    80005b7a:	bf2d                	j	80005ab4 <sys_open+0xa4>
    itrunc(ip);
    80005b7c:	854a                	mv	a0,s2
    80005b7e:	ffffe097          	auipc	ra,0xffffe
    80005b82:	fdc080e7          	jalr	-36(ra) # 80003b5a <itrunc>
    80005b86:	bfb1                	j	80005ae2 <sys_open+0xd2>
      fileclose(f);
    80005b88:	854e                	mv	a0,s3
    80005b8a:	fffff097          	auipc	ra,0xfffff
    80005b8e:	d50080e7          	jalr	-688(ra) # 800048da <fileclose>
    iunlockput(ip);
    80005b92:	854a                	mv	a0,s2
    80005b94:	ffffe097          	auipc	ra,0xffffe
    80005b98:	11a080e7          	jalr	282(ra) # 80003cae <iunlockput>
    end_op();
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	8ec080e7          	jalr	-1812(ra) # 80004488 <end_op>
    return -1;
    80005ba4:	54fd                	li	s1,-1
    80005ba6:	b7b9                	j	80005af4 <sys_open+0xe4>

0000000080005ba8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ba8:	7175                	addi	sp,sp,-144
    80005baa:	e506                	sd	ra,136(sp)
    80005bac:	e122                	sd	s0,128(sp)
    80005bae:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	858080e7          	jalr	-1960(ra) # 80004408 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005bb8:	08000613          	li	a2,128
    80005bbc:	f7040593          	addi	a1,s0,-144
    80005bc0:	4501                	li	a0,0
    80005bc2:	ffffd097          	auipc	ra,0xffffd
    80005bc6:	35c080e7          	jalr	860(ra) # 80002f1e <argstr>
    80005bca:	02054963          	bltz	a0,80005bfc <sys_mkdir+0x54>
    80005bce:	4681                	li	a3,0
    80005bd0:	4601                	li	a2,0
    80005bd2:	4585                	li	a1,1
    80005bd4:	f7040513          	addi	a0,s0,-144
    80005bd8:	fffff097          	auipc	ra,0xfffff
    80005bdc:	7fe080e7          	jalr	2046(ra) # 800053d6 <create>
    80005be0:	cd11                	beqz	a0,80005bfc <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	0cc080e7          	jalr	204(ra) # 80003cae <iunlockput>
  end_op();
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	89e080e7          	jalr	-1890(ra) # 80004488 <end_op>
  return 0;
    80005bf2:	4501                	li	a0,0
}
    80005bf4:	60aa                	ld	ra,136(sp)
    80005bf6:	640a                	ld	s0,128(sp)
    80005bf8:	6149                	addi	sp,sp,144
    80005bfa:	8082                	ret
    end_op();
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	88c080e7          	jalr	-1908(ra) # 80004488 <end_op>
    return -1;
    80005c04:	557d                	li	a0,-1
    80005c06:	b7fd                	j	80005bf4 <sys_mkdir+0x4c>

0000000080005c08 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c08:	7135                	addi	sp,sp,-160
    80005c0a:	ed06                	sd	ra,152(sp)
    80005c0c:	e922                	sd	s0,144(sp)
    80005c0e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	7f8080e7          	jalr	2040(ra) # 80004408 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c18:	08000613          	li	a2,128
    80005c1c:	f7040593          	addi	a1,s0,-144
    80005c20:	4501                	li	a0,0
    80005c22:	ffffd097          	auipc	ra,0xffffd
    80005c26:	2fc080e7          	jalr	764(ra) # 80002f1e <argstr>
    80005c2a:	04054a63          	bltz	a0,80005c7e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c2e:	f6c40593          	addi	a1,s0,-148
    80005c32:	4505                	li	a0,1
    80005c34:	ffffd097          	auipc	ra,0xffffd
    80005c38:	2a6080e7          	jalr	678(ra) # 80002eda <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c3c:	04054163          	bltz	a0,80005c7e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005c40:	f6840593          	addi	a1,s0,-152
    80005c44:	4509                	li	a0,2
    80005c46:	ffffd097          	auipc	ra,0xffffd
    80005c4a:	294080e7          	jalr	660(ra) # 80002eda <argint>
     argint(1, &major) < 0 ||
    80005c4e:	02054863          	bltz	a0,80005c7e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c52:	f6841683          	lh	a3,-152(s0)
    80005c56:	f6c41603          	lh	a2,-148(s0)
    80005c5a:	458d                	li	a1,3
    80005c5c:	f7040513          	addi	a0,s0,-144
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	776080e7          	jalr	1910(ra) # 800053d6 <create>
     argint(2, &minor) < 0 ||
    80005c68:	c919                	beqz	a0,80005c7e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c6a:	ffffe097          	auipc	ra,0xffffe
    80005c6e:	044080e7          	jalr	68(ra) # 80003cae <iunlockput>
  end_op();
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	816080e7          	jalr	-2026(ra) # 80004488 <end_op>
  return 0;
    80005c7a:	4501                	li	a0,0
    80005c7c:	a031                	j	80005c88 <sys_mknod+0x80>
    end_op();
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	80a080e7          	jalr	-2038(ra) # 80004488 <end_op>
    return -1;
    80005c86:	557d                	li	a0,-1
}
    80005c88:	60ea                	ld	ra,152(sp)
    80005c8a:	644a                	ld	s0,144(sp)
    80005c8c:	610d                	addi	sp,sp,160
    80005c8e:	8082                	ret

0000000080005c90 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c90:	7135                	addi	sp,sp,-160
    80005c92:	ed06                	sd	ra,152(sp)
    80005c94:	e922                	sd	s0,144(sp)
    80005c96:	e526                	sd	s1,136(sp)
    80005c98:	e14a                	sd	s2,128(sp)
    80005c9a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c9c:	ffffc097          	auipc	ra,0xffffc
    80005ca0:	048080e7          	jalr	72(ra) # 80001ce4 <myproc>
    80005ca4:	892a                	mv	s2,a0
  
  begin_op();
    80005ca6:	ffffe097          	auipc	ra,0xffffe
    80005caa:	762080e7          	jalr	1890(ra) # 80004408 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005cae:	08000613          	li	a2,128
    80005cb2:	f6040593          	addi	a1,s0,-160
    80005cb6:	4501                	li	a0,0
    80005cb8:	ffffd097          	auipc	ra,0xffffd
    80005cbc:	266080e7          	jalr	614(ra) # 80002f1e <argstr>
    80005cc0:	04054b63          	bltz	a0,80005d16 <sys_chdir+0x86>
    80005cc4:	f6040513          	addi	a0,s0,-160
    80005cc8:	ffffe097          	auipc	ra,0xffffe
    80005ccc:	534080e7          	jalr	1332(ra) # 800041fc <namei>
    80005cd0:	84aa                	mv	s1,a0
    80005cd2:	c131                	beqz	a0,80005d16 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005cd4:	ffffe097          	auipc	ra,0xffffe
    80005cd8:	d78080e7          	jalr	-648(ra) # 80003a4c <ilock>
  if(ip->type != T_DIR){
    80005cdc:	04449703          	lh	a4,68(s1)
    80005ce0:	4785                	li	a5,1
    80005ce2:	04f71063          	bne	a4,a5,80005d22 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ce6:	8526                	mv	a0,s1
    80005ce8:	ffffe097          	auipc	ra,0xffffe
    80005cec:	e26080e7          	jalr	-474(ra) # 80003b0e <iunlock>
  iput(p->cwd);
    80005cf0:	16093503          	ld	a0,352(s2)
    80005cf4:	ffffe097          	auipc	ra,0xffffe
    80005cf8:	f12080e7          	jalr	-238(ra) # 80003c06 <iput>
  end_op();
    80005cfc:	ffffe097          	auipc	ra,0xffffe
    80005d00:	78c080e7          	jalr	1932(ra) # 80004488 <end_op>
  p->cwd = ip;
    80005d04:	16993023          	sd	s1,352(s2)
  return 0;
    80005d08:	4501                	li	a0,0
}
    80005d0a:	60ea                	ld	ra,152(sp)
    80005d0c:	644a                	ld	s0,144(sp)
    80005d0e:	64aa                	ld	s1,136(sp)
    80005d10:	690a                	ld	s2,128(sp)
    80005d12:	610d                	addi	sp,sp,160
    80005d14:	8082                	ret
    end_op();
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	772080e7          	jalr	1906(ra) # 80004488 <end_op>
    return -1;
    80005d1e:	557d                	li	a0,-1
    80005d20:	b7ed                	j	80005d0a <sys_chdir+0x7a>
    iunlockput(ip);
    80005d22:	8526                	mv	a0,s1
    80005d24:	ffffe097          	auipc	ra,0xffffe
    80005d28:	f8a080e7          	jalr	-118(ra) # 80003cae <iunlockput>
    end_op();
    80005d2c:	ffffe097          	auipc	ra,0xffffe
    80005d30:	75c080e7          	jalr	1884(ra) # 80004488 <end_op>
    return -1;
    80005d34:	557d                	li	a0,-1
    80005d36:	bfd1                	j	80005d0a <sys_chdir+0x7a>

0000000080005d38 <sys_exec>:

uint64
sys_exec(void)
{
    80005d38:	7145                	addi	sp,sp,-464
    80005d3a:	e786                	sd	ra,456(sp)
    80005d3c:	e3a2                	sd	s0,448(sp)
    80005d3e:	ff26                	sd	s1,440(sp)
    80005d40:	fb4a                	sd	s2,432(sp)
    80005d42:	f74e                	sd	s3,424(sp)
    80005d44:	f352                	sd	s4,416(sp)
    80005d46:	ef56                	sd	s5,408(sp)
    80005d48:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d4a:	08000613          	li	a2,128
    80005d4e:	f4040593          	addi	a1,s0,-192
    80005d52:	4501                	li	a0,0
    80005d54:	ffffd097          	auipc	ra,0xffffd
    80005d58:	1ca080e7          	jalr	458(ra) # 80002f1e <argstr>
    return -1;
    80005d5c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d5e:	0c054a63          	bltz	a0,80005e32 <sys_exec+0xfa>
    80005d62:	e3840593          	addi	a1,s0,-456
    80005d66:	4505                	li	a0,1
    80005d68:	ffffd097          	auipc	ra,0xffffd
    80005d6c:	194080e7          	jalr	404(ra) # 80002efc <argaddr>
    80005d70:	0c054163          	bltz	a0,80005e32 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005d74:	10000613          	li	a2,256
    80005d78:	4581                	li	a1,0
    80005d7a:	e4040513          	addi	a0,s0,-448
    80005d7e:	ffffb097          	auipc	ra,0xffffb
    80005d82:	f8e080e7          	jalr	-114(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d86:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d8a:	89a6                	mv	s3,s1
    80005d8c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d8e:	02000a13          	li	s4,32
    80005d92:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d96:	00391513          	slli	a0,s2,0x3
    80005d9a:	e3040593          	addi	a1,s0,-464
    80005d9e:	e3843783          	ld	a5,-456(s0)
    80005da2:	953e                	add	a0,a0,a5
    80005da4:	ffffd097          	auipc	ra,0xffffd
    80005da8:	09c080e7          	jalr	156(ra) # 80002e40 <fetchaddr>
    80005dac:	02054a63          	bltz	a0,80005de0 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005db0:	e3043783          	ld	a5,-464(s0)
    80005db4:	c3b9                	beqz	a5,80005dfa <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005db6:	ffffb097          	auipc	ra,0xffffb
    80005dba:	d6a080e7          	jalr	-662(ra) # 80000b20 <kalloc>
    80005dbe:	85aa                	mv	a1,a0
    80005dc0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005dc4:	cd11                	beqz	a0,80005de0 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005dc6:	6605                	lui	a2,0x1
    80005dc8:	e3043503          	ld	a0,-464(s0)
    80005dcc:	ffffd097          	auipc	ra,0xffffd
    80005dd0:	0c6080e7          	jalr	198(ra) # 80002e92 <fetchstr>
    80005dd4:	00054663          	bltz	a0,80005de0 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005dd8:	0905                	addi	s2,s2,1
    80005dda:	09a1                	addi	s3,s3,8
    80005ddc:	fb491be3          	bne	s2,s4,80005d92 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005de0:	10048913          	addi	s2,s1,256
    80005de4:	6088                	ld	a0,0(s1)
    80005de6:	c529                	beqz	a0,80005e30 <sys_exec+0xf8>
    kfree(argv[i]);
    80005de8:	ffffb097          	auipc	ra,0xffffb
    80005dec:	c3c080e7          	jalr	-964(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005df0:	04a1                	addi	s1,s1,8
    80005df2:	ff2499e3          	bne	s1,s2,80005de4 <sys_exec+0xac>
  return -1;
    80005df6:	597d                	li	s2,-1
    80005df8:	a82d                	j	80005e32 <sys_exec+0xfa>
      argv[i] = 0;
    80005dfa:	0a8e                	slli	s5,s5,0x3
    80005dfc:	fc040793          	addi	a5,s0,-64
    80005e00:	9abe                	add	s5,s5,a5
    80005e02:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e06:	e4040593          	addi	a1,s0,-448
    80005e0a:	f4040513          	addi	a0,s0,-192
    80005e0e:	fffff097          	auipc	ra,0xfffff
    80005e12:	17c080e7          	jalr	380(ra) # 80004f8a <exec>
    80005e16:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e18:	10048993          	addi	s3,s1,256
    80005e1c:	6088                	ld	a0,0(s1)
    80005e1e:	c911                	beqz	a0,80005e32 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e20:	ffffb097          	auipc	ra,0xffffb
    80005e24:	c04080e7          	jalr	-1020(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e28:	04a1                	addi	s1,s1,8
    80005e2a:	ff3499e3          	bne	s1,s3,80005e1c <sys_exec+0xe4>
    80005e2e:	a011                	j	80005e32 <sys_exec+0xfa>
  return -1;
    80005e30:	597d                	li	s2,-1
}
    80005e32:	854a                	mv	a0,s2
    80005e34:	60be                	ld	ra,456(sp)
    80005e36:	641e                	ld	s0,448(sp)
    80005e38:	74fa                	ld	s1,440(sp)
    80005e3a:	795a                	ld	s2,432(sp)
    80005e3c:	79ba                	ld	s3,424(sp)
    80005e3e:	7a1a                	ld	s4,416(sp)
    80005e40:	6afa                	ld	s5,408(sp)
    80005e42:	6179                	addi	sp,sp,464
    80005e44:	8082                	ret

0000000080005e46 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e46:	7139                	addi	sp,sp,-64
    80005e48:	fc06                	sd	ra,56(sp)
    80005e4a:	f822                	sd	s0,48(sp)
    80005e4c:	f426                	sd	s1,40(sp)
    80005e4e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e50:	ffffc097          	auipc	ra,0xffffc
    80005e54:	e94080e7          	jalr	-364(ra) # 80001ce4 <myproc>
    80005e58:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005e5a:	fd840593          	addi	a1,s0,-40
    80005e5e:	4501                	li	a0,0
    80005e60:	ffffd097          	auipc	ra,0xffffd
    80005e64:	09c080e7          	jalr	156(ra) # 80002efc <argaddr>
    return -1;
    80005e68:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e6a:	0e054063          	bltz	a0,80005f4a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005e6e:	fc840593          	addi	a1,s0,-56
    80005e72:	fd040513          	addi	a0,s0,-48
    80005e76:	fffff097          	auipc	ra,0xfffff
    80005e7a:	dba080e7          	jalr	-582(ra) # 80004c30 <pipealloc>
    return -1;
    80005e7e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e80:	0c054563          	bltz	a0,80005f4a <sys_pipe+0x104>
  fd0 = -1;
    80005e84:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e88:	fd043503          	ld	a0,-48(s0)
    80005e8c:	fffff097          	auipc	ra,0xfffff
    80005e90:	508080e7          	jalr	1288(ra) # 80005394 <fdalloc>
    80005e94:	fca42223          	sw	a0,-60(s0)
    80005e98:	08054c63          	bltz	a0,80005f30 <sys_pipe+0xea>
    80005e9c:	fc843503          	ld	a0,-56(s0)
    80005ea0:	fffff097          	auipc	ra,0xfffff
    80005ea4:	4f4080e7          	jalr	1268(ra) # 80005394 <fdalloc>
    80005ea8:	fca42023          	sw	a0,-64(s0)
    80005eac:	06054863          	bltz	a0,80005f1c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005eb0:	4691                	li	a3,4
    80005eb2:	fc440613          	addi	a2,s0,-60
    80005eb6:	fd843583          	ld	a1,-40(s0)
    80005eba:	68a8                	ld	a0,80(s1)
    80005ebc:	ffffc097          	auipc	ra,0xffffc
    80005ec0:	886080e7          	jalr	-1914(ra) # 80001742 <copyout>
    80005ec4:	02054063          	bltz	a0,80005ee4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ec8:	4691                	li	a3,4
    80005eca:	fc040613          	addi	a2,s0,-64
    80005ece:	fd843583          	ld	a1,-40(s0)
    80005ed2:	0591                	addi	a1,a1,4
    80005ed4:	68a8                	ld	a0,80(s1)
    80005ed6:	ffffc097          	auipc	ra,0xffffc
    80005eda:	86c080e7          	jalr	-1940(ra) # 80001742 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ede:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ee0:	06055563          	bgez	a0,80005f4a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005ee4:	fc442783          	lw	a5,-60(s0)
    80005ee8:	07f1                	addi	a5,a5,28
    80005eea:	078e                	slli	a5,a5,0x3
    80005eec:	97a6                	add	a5,a5,s1
    80005eee:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ef2:	fc042503          	lw	a0,-64(s0)
    80005ef6:	0571                	addi	a0,a0,28
    80005ef8:	050e                	slli	a0,a0,0x3
    80005efa:	9526                	add	a0,a0,s1
    80005efc:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005f00:	fd043503          	ld	a0,-48(s0)
    80005f04:	fffff097          	auipc	ra,0xfffff
    80005f08:	9d6080e7          	jalr	-1578(ra) # 800048da <fileclose>
    fileclose(wf);
    80005f0c:	fc843503          	ld	a0,-56(s0)
    80005f10:	fffff097          	auipc	ra,0xfffff
    80005f14:	9ca080e7          	jalr	-1590(ra) # 800048da <fileclose>
    return -1;
    80005f18:	57fd                	li	a5,-1
    80005f1a:	a805                	j	80005f4a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005f1c:	fc442783          	lw	a5,-60(s0)
    80005f20:	0007c863          	bltz	a5,80005f30 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005f24:	01c78513          	addi	a0,a5,28
    80005f28:	050e                	slli	a0,a0,0x3
    80005f2a:	9526                	add	a0,a0,s1
    80005f2c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005f30:	fd043503          	ld	a0,-48(s0)
    80005f34:	fffff097          	auipc	ra,0xfffff
    80005f38:	9a6080e7          	jalr	-1626(ra) # 800048da <fileclose>
    fileclose(wf);
    80005f3c:	fc843503          	ld	a0,-56(s0)
    80005f40:	fffff097          	auipc	ra,0xfffff
    80005f44:	99a080e7          	jalr	-1638(ra) # 800048da <fileclose>
    return -1;
    80005f48:	57fd                	li	a5,-1
}
    80005f4a:	853e                	mv	a0,a5
    80005f4c:	70e2                	ld	ra,56(sp)
    80005f4e:	7442                	ld	s0,48(sp)
    80005f50:	74a2                	ld	s1,40(sp)
    80005f52:	6121                	addi	sp,sp,64
    80005f54:	8082                	ret
	...

0000000080005f60 <kernelvec>:
    80005f60:	7111                	addi	sp,sp,-256
    80005f62:	e006                	sd	ra,0(sp)
    80005f64:	e40a                	sd	sp,8(sp)
    80005f66:	e80e                	sd	gp,16(sp)
    80005f68:	ec12                	sd	tp,24(sp)
    80005f6a:	f016                	sd	t0,32(sp)
    80005f6c:	f41a                	sd	t1,40(sp)
    80005f6e:	f81e                	sd	t2,48(sp)
    80005f70:	fc22                	sd	s0,56(sp)
    80005f72:	e0a6                	sd	s1,64(sp)
    80005f74:	e4aa                	sd	a0,72(sp)
    80005f76:	e8ae                	sd	a1,80(sp)
    80005f78:	ecb2                	sd	a2,88(sp)
    80005f7a:	f0b6                	sd	a3,96(sp)
    80005f7c:	f4ba                	sd	a4,104(sp)
    80005f7e:	f8be                	sd	a5,112(sp)
    80005f80:	fcc2                	sd	a6,120(sp)
    80005f82:	e146                	sd	a7,128(sp)
    80005f84:	e54a                	sd	s2,136(sp)
    80005f86:	e94e                	sd	s3,144(sp)
    80005f88:	ed52                	sd	s4,152(sp)
    80005f8a:	f156                	sd	s5,160(sp)
    80005f8c:	f55a                	sd	s6,168(sp)
    80005f8e:	f95e                	sd	s7,176(sp)
    80005f90:	fd62                	sd	s8,184(sp)
    80005f92:	e1e6                	sd	s9,192(sp)
    80005f94:	e5ea                	sd	s10,200(sp)
    80005f96:	e9ee                	sd	s11,208(sp)
    80005f98:	edf2                	sd	t3,216(sp)
    80005f9a:	f1f6                	sd	t4,224(sp)
    80005f9c:	f5fa                	sd	t5,232(sp)
    80005f9e:	f9fe                	sd	t6,240(sp)
    80005fa0:	d53fc0ef          	jal	ra,80002cf2 <kerneltrap>
    80005fa4:	6082                	ld	ra,0(sp)
    80005fa6:	6122                	ld	sp,8(sp)
    80005fa8:	61c2                	ld	gp,16(sp)
    80005faa:	7282                	ld	t0,32(sp)
    80005fac:	7322                	ld	t1,40(sp)
    80005fae:	73c2                	ld	t2,48(sp)
    80005fb0:	7462                	ld	s0,56(sp)
    80005fb2:	6486                	ld	s1,64(sp)
    80005fb4:	6526                	ld	a0,72(sp)
    80005fb6:	65c6                	ld	a1,80(sp)
    80005fb8:	6666                	ld	a2,88(sp)
    80005fba:	7686                	ld	a3,96(sp)
    80005fbc:	7726                	ld	a4,104(sp)
    80005fbe:	77c6                	ld	a5,112(sp)
    80005fc0:	7866                	ld	a6,120(sp)
    80005fc2:	688a                	ld	a7,128(sp)
    80005fc4:	692a                	ld	s2,136(sp)
    80005fc6:	69ca                	ld	s3,144(sp)
    80005fc8:	6a6a                	ld	s4,152(sp)
    80005fca:	7a8a                	ld	s5,160(sp)
    80005fcc:	7b2a                	ld	s6,168(sp)
    80005fce:	7bca                	ld	s7,176(sp)
    80005fd0:	7c6a                	ld	s8,184(sp)
    80005fd2:	6c8e                	ld	s9,192(sp)
    80005fd4:	6d2e                	ld	s10,200(sp)
    80005fd6:	6dce                	ld	s11,208(sp)
    80005fd8:	6e6e                	ld	t3,216(sp)
    80005fda:	7e8e                	ld	t4,224(sp)
    80005fdc:	7f2e                	ld	t5,232(sp)
    80005fde:	7fce                	ld	t6,240(sp)
    80005fe0:	6111                	addi	sp,sp,256
    80005fe2:	10200073          	sret
    80005fe6:	00000013          	nop
    80005fea:	00000013          	nop
    80005fee:	0001                	nop

0000000080005ff0 <timervec>:
    80005ff0:	34051573          	csrrw	a0,mscratch,a0
    80005ff4:	e10c                	sd	a1,0(a0)
    80005ff6:	e510                	sd	a2,8(a0)
    80005ff8:	e914                	sd	a3,16(a0)
    80005ffa:	710c                	ld	a1,32(a0)
    80005ffc:	7510                	ld	a2,40(a0)
    80005ffe:	6194                	ld	a3,0(a1)
    80006000:	96b2                	add	a3,a3,a2
    80006002:	e194                	sd	a3,0(a1)
    80006004:	4589                	li	a1,2
    80006006:	14459073          	csrw	sip,a1
    8000600a:	6914                	ld	a3,16(a0)
    8000600c:	6510                	ld	a2,8(a0)
    8000600e:	610c                	ld	a1,0(a0)
    80006010:	34051573          	csrrw	a0,mscratch,a0
    80006014:	30200073          	mret
	...

000000008000601a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000601a:	1141                	addi	sp,sp,-16
    8000601c:	e422                	sd	s0,8(sp)
    8000601e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006020:	0c0007b7          	lui	a5,0xc000
    80006024:	4705                	li	a4,1
    80006026:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006028:	c3d8                	sw	a4,4(a5)
}
    8000602a:	6422                	ld	s0,8(sp)
    8000602c:	0141                	addi	sp,sp,16
    8000602e:	8082                	ret

0000000080006030 <plicinithart>:

void
plicinithart(void)
{
    80006030:	1141                	addi	sp,sp,-16
    80006032:	e406                	sd	ra,8(sp)
    80006034:	e022                	sd	s0,0(sp)
    80006036:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006038:	ffffc097          	auipc	ra,0xffffc
    8000603c:	c80080e7          	jalr	-896(ra) # 80001cb8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006040:	0085171b          	slliw	a4,a0,0x8
    80006044:	0c0027b7          	lui	a5,0xc002
    80006048:	97ba                	add	a5,a5,a4
    8000604a:	40200713          	li	a4,1026
    8000604e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006052:	00d5151b          	slliw	a0,a0,0xd
    80006056:	0c2017b7          	lui	a5,0xc201
    8000605a:	953e                	add	a0,a0,a5
    8000605c:	00052023          	sw	zero,0(a0)
}
    80006060:	60a2                	ld	ra,8(sp)
    80006062:	6402                	ld	s0,0(sp)
    80006064:	0141                	addi	sp,sp,16
    80006066:	8082                	ret

0000000080006068 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006068:	1141                	addi	sp,sp,-16
    8000606a:	e406                	sd	ra,8(sp)
    8000606c:	e022                	sd	s0,0(sp)
    8000606e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006070:	ffffc097          	auipc	ra,0xffffc
    80006074:	c48080e7          	jalr	-952(ra) # 80001cb8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006078:	00d5179b          	slliw	a5,a0,0xd
    8000607c:	0c201537          	lui	a0,0xc201
    80006080:	953e                	add	a0,a0,a5
  return irq;
}
    80006082:	4148                	lw	a0,4(a0)
    80006084:	60a2                	ld	ra,8(sp)
    80006086:	6402                	ld	s0,0(sp)
    80006088:	0141                	addi	sp,sp,16
    8000608a:	8082                	ret

000000008000608c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000608c:	1101                	addi	sp,sp,-32
    8000608e:	ec06                	sd	ra,24(sp)
    80006090:	e822                	sd	s0,16(sp)
    80006092:	e426                	sd	s1,8(sp)
    80006094:	1000                	addi	s0,sp,32
    80006096:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006098:	ffffc097          	auipc	ra,0xffffc
    8000609c:	c20080e7          	jalr	-992(ra) # 80001cb8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800060a0:	00d5151b          	slliw	a0,a0,0xd
    800060a4:	0c2017b7          	lui	a5,0xc201
    800060a8:	97aa                	add	a5,a5,a0
    800060aa:	c3c4                	sw	s1,4(a5)
}
    800060ac:	60e2                	ld	ra,24(sp)
    800060ae:	6442                	ld	s0,16(sp)
    800060b0:	64a2                	ld	s1,8(sp)
    800060b2:	6105                	addi	sp,sp,32
    800060b4:	8082                	ret

00000000800060b6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800060b6:	1141                	addi	sp,sp,-16
    800060b8:	e406                	sd	ra,8(sp)
    800060ba:	e022                	sd	s0,0(sp)
    800060bc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800060be:	479d                	li	a5,7
    800060c0:	04a7cc63          	blt	a5,a0,80006118 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    800060c4:	0001d797          	auipc	a5,0x1d
    800060c8:	f3c78793          	addi	a5,a5,-196 # 80023000 <disk>
    800060cc:	00a78733          	add	a4,a5,a0
    800060d0:	6789                	lui	a5,0x2
    800060d2:	97ba                	add	a5,a5,a4
    800060d4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800060d8:	eba1                	bnez	a5,80006128 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    800060da:	00451713          	slli	a4,a0,0x4
    800060de:	0001f797          	auipc	a5,0x1f
    800060e2:	f227b783          	ld	a5,-222(a5) # 80025000 <disk+0x2000>
    800060e6:	97ba                	add	a5,a5,a4
    800060e8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    800060ec:	0001d797          	auipc	a5,0x1d
    800060f0:	f1478793          	addi	a5,a5,-236 # 80023000 <disk>
    800060f4:	97aa                	add	a5,a5,a0
    800060f6:	6509                	lui	a0,0x2
    800060f8:	953e                	add	a0,a0,a5
    800060fa:	4785                	li	a5,1
    800060fc:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006100:	0001f517          	auipc	a0,0x1f
    80006104:	f1850513          	addi	a0,a0,-232 # 80025018 <disk+0x2018>
    80006108:	ffffc097          	auipc	ra,0xffffc
    8000610c:	676080e7          	jalr	1654(ra) # 8000277e <wakeup>
}
    80006110:	60a2                	ld	ra,8(sp)
    80006112:	6402                	ld	s0,0(sp)
    80006114:	0141                	addi	sp,sp,16
    80006116:	8082                	ret
    panic("virtio_disk_intr 1");
    80006118:	00002517          	auipc	a0,0x2
    8000611c:	72850513          	addi	a0,a0,1832 # 80008840 <syscalls+0x330>
    80006120:	ffffa097          	auipc	ra,0xffffa
    80006124:	428080e7          	jalr	1064(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80006128:	00002517          	auipc	a0,0x2
    8000612c:	73050513          	addi	a0,a0,1840 # 80008858 <syscalls+0x348>
    80006130:	ffffa097          	auipc	ra,0xffffa
    80006134:	418080e7          	jalr	1048(ra) # 80000548 <panic>

0000000080006138 <virtio_disk_init>:
{
    80006138:	1101                	addi	sp,sp,-32
    8000613a:	ec06                	sd	ra,24(sp)
    8000613c:	e822                	sd	s0,16(sp)
    8000613e:	e426                	sd	s1,8(sp)
    80006140:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006142:	00002597          	auipc	a1,0x2
    80006146:	72e58593          	addi	a1,a1,1838 # 80008870 <syscalls+0x360>
    8000614a:	0001f517          	auipc	a0,0x1f
    8000614e:	f5e50513          	addi	a0,a0,-162 # 800250a8 <disk+0x20a8>
    80006152:	ffffb097          	auipc	ra,0xffffb
    80006156:	a2e080e7          	jalr	-1490(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000615a:	100017b7          	lui	a5,0x10001
    8000615e:	4398                	lw	a4,0(a5)
    80006160:	2701                	sext.w	a4,a4
    80006162:	747277b7          	lui	a5,0x74727
    80006166:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000616a:	0ef71163          	bne	a4,a5,8000624c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000616e:	100017b7          	lui	a5,0x10001
    80006172:	43dc                	lw	a5,4(a5)
    80006174:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006176:	4705                	li	a4,1
    80006178:	0ce79a63          	bne	a5,a4,8000624c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000617c:	100017b7          	lui	a5,0x10001
    80006180:	479c                	lw	a5,8(a5)
    80006182:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006184:	4709                	li	a4,2
    80006186:	0ce79363          	bne	a5,a4,8000624c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000618a:	100017b7          	lui	a5,0x10001
    8000618e:	47d8                	lw	a4,12(a5)
    80006190:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006192:	554d47b7          	lui	a5,0x554d4
    80006196:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000619a:	0af71963          	bne	a4,a5,8000624c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000619e:	100017b7          	lui	a5,0x10001
    800061a2:	4705                	li	a4,1
    800061a4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061a6:	470d                	li	a4,3
    800061a8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800061aa:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800061ac:	c7ffe737          	lui	a4,0xc7ffe
    800061b0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    800061b4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800061b6:	2701                	sext.w	a4,a4
    800061b8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061ba:	472d                	li	a4,11
    800061bc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061be:	473d                	li	a4,15
    800061c0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800061c2:	6705                	lui	a4,0x1
    800061c4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800061c6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800061ca:	5bdc                	lw	a5,52(a5)
    800061cc:	2781                	sext.w	a5,a5
  if(max == 0)
    800061ce:	c7d9                	beqz	a5,8000625c <virtio_disk_init+0x124>
  if(max < NUM)
    800061d0:	471d                	li	a4,7
    800061d2:	08f77d63          	bgeu	a4,a5,8000626c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800061d6:	100014b7          	lui	s1,0x10001
    800061da:	47a1                	li	a5,8
    800061dc:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800061de:	6609                	lui	a2,0x2
    800061e0:	4581                	li	a1,0
    800061e2:	0001d517          	auipc	a0,0x1d
    800061e6:	e1e50513          	addi	a0,a0,-482 # 80023000 <disk>
    800061ea:	ffffb097          	auipc	ra,0xffffb
    800061ee:	b22080e7          	jalr	-1246(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800061f2:	0001d717          	auipc	a4,0x1d
    800061f6:	e0e70713          	addi	a4,a4,-498 # 80023000 <disk>
    800061fa:	00c75793          	srli	a5,a4,0xc
    800061fe:	2781                	sext.w	a5,a5
    80006200:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006202:	0001f797          	auipc	a5,0x1f
    80006206:	dfe78793          	addi	a5,a5,-514 # 80025000 <disk+0x2000>
    8000620a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000620c:	0001d717          	auipc	a4,0x1d
    80006210:	e7470713          	addi	a4,a4,-396 # 80023080 <disk+0x80>
    80006214:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006216:	0001e717          	auipc	a4,0x1e
    8000621a:	dea70713          	addi	a4,a4,-534 # 80024000 <disk+0x1000>
    8000621e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006220:	4705                	li	a4,1
    80006222:	00e78c23          	sb	a4,24(a5)
    80006226:	00e78ca3          	sb	a4,25(a5)
    8000622a:	00e78d23          	sb	a4,26(a5)
    8000622e:	00e78da3          	sb	a4,27(a5)
    80006232:	00e78e23          	sb	a4,28(a5)
    80006236:	00e78ea3          	sb	a4,29(a5)
    8000623a:	00e78f23          	sb	a4,30(a5)
    8000623e:	00e78fa3          	sb	a4,31(a5)
}
    80006242:	60e2                	ld	ra,24(sp)
    80006244:	6442                	ld	s0,16(sp)
    80006246:	64a2                	ld	s1,8(sp)
    80006248:	6105                	addi	sp,sp,32
    8000624a:	8082                	ret
    panic("could not find virtio disk");
    8000624c:	00002517          	auipc	a0,0x2
    80006250:	63450513          	addi	a0,a0,1588 # 80008880 <syscalls+0x370>
    80006254:	ffffa097          	auipc	ra,0xffffa
    80006258:	2f4080e7          	jalr	756(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    8000625c:	00002517          	auipc	a0,0x2
    80006260:	64450513          	addi	a0,a0,1604 # 800088a0 <syscalls+0x390>
    80006264:	ffffa097          	auipc	ra,0xffffa
    80006268:	2e4080e7          	jalr	740(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    8000626c:	00002517          	auipc	a0,0x2
    80006270:	65450513          	addi	a0,a0,1620 # 800088c0 <syscalls+0x3b0>
    80006274:	ffffa097          	auipc	ra,0xffffa
    80006278:	2d4080e7          	jalr	724(ra) # 80000548 <panic>

000000008000627c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000627c:	7119                	addi	sp,sp,-128
    8000627e:	fc86                	sd	ra,120(sp)
    80006280:	f8a2                	sd	s0,112(sp)
    80006282:	f4a6                	sd	s1,104(sp)
    80006284:	f0ca                	sd	s2,96(sp)
    80006286:	ecce                	sd	s3,88(sp)
    80006288:	e8d2                	sd	s4,80(sp)
    8000628a:	e4d6                	sd	s5,72(sp)
    8000628c:	e0da                	sd	s6,64(sp)
    8000628e:	fc5e                	sd	s7,56(sp)
    80006290:	f862                	sd	s8,48(sp)
    80006292:	f466                	sd	s9,40(sp)
    80006294:	f06a                	sd	s10,32(sp)
    80006296:	0100                	addi	s0,sp,128
    80006298:	892a                	mv	s2,a0
    8000629a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000629c:	00c52c83          	lw	s9,12(a0)
    800062a0:	001c9c9b          	slliw	s9,s9,0x1
    800062a4:	1c82                	slli	s9,s9,0x20
    800062a6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800062aa:	0001f517          	auipc	a0,0x1f
    800062ae:	dfe50513          	addi	a0,a0,-514 # 800250a8 <disk+0x20a8>
    800062b2:	ffffb097          	auipc	ra,0xffffb
    800062b6:	95e080e7          	jalr	-1698(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    800062ba:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800062bc:	4c21                	li	s8,8
      disk.free[i] = 0;
    800062be:	0001db97          	auipc	s7,0x1d
    800062c2:	d42b8b93          	addi	s7,s7,-702 # 80023000 <disk>
    800062c6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800062c8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800062ca:	8a4e                	mv	s4,s3
    800062cc:	a051                	j	80006350 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800062ce:	00fb86b3          	add	a3,s7,a5
    800062d2:	96da                	add	a3,a3,s6
    800062d4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800062d8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800062da:	0207c563          	bltz	a5,80006304 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800062de:	2485                	addiw	s1,s1,1
    800062e0:	0711                	addi	a4,a4,4
    800062e2:	23548d63          	beq	s1,s5,8000651c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    800062e6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800062e8:	0001f697          	auipc	a3,0x1f
    800062ec:	d3068693          	addi	a3,a3,-720 # 80025018 <disk+0x2018>
    800062f0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800062f2:	0006c583          	lbu	a1,0(a3)
    800062f6:	fde1                	bnez	a1,800062ce <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800062f8:	2785                	addiw	a5,a5,1
    800062fa:	0685                	addi	a3,a3,1
    800062fc:	ff879be3          	bne	a5,s8,800062f2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006300:	57fd                	li	a5,-1
    80006302:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006304:	02905a63          	blez	s1,80006338 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006308:	f9042503          	lw	a0,-112(s0)
    8000630c:	00000097          	auipc	ra,0x0
    80006310:	daa080e7          	jalr	-598(ra) # 800060b6 <free_desc>
      for(int j = 0; j < i; j++)
    80006314:	4785                	li	a5,1
    80006316:	0297d163          	bge	a5,s1,80006338 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000631a:	f9442503          	lw	a0,-108(s0)
    8000631e:	00000097          	auipc	ra,0x0
    80006322:	d98080e7          	jalr	-616(ra) # 800060b6 <free_desc>
      for(int j = 0; j < i; j++)
    80006326:	4789                	li	a5,2
    80006328:	0097d863          	bge	a5,s1,80006338 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000632c:	f9842503          	lw	a0,-104(s0)
    80006330:	00000097          	auipc	ra,0x0
    80006334:	d86080e7          	jalr	-634(ra) # 800060b6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006338:	0001f597          	auipc	a1,0x1f
    8000633c:	d7058593          	addi	a1,a1,-656 # 800250a8 <disk+0x20a8>
    80006340:	0001f517          	auipc	a0,0x1f
    80006344:	cd850513          	addi	a0,a0,-808 # 80025018 <disk+0x2018>
    80006348:	ffffc097          	auipc	ra,0xffffc
    8000634c:	2b0080e7          	jalr	688(ra) # 800025f8 <sleep>
  for(int i = 0; i < 3; i++){
    80006350:	f9040713          	addi	a4,s0,-112
    80006354:	84ce                	mv	s1,s3
    80006356:	bf41                	j	800062e6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006358:	4785                	li	a5,1
    8000635a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000635e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006362:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006366:	f9042983          	lw	s3,-112(s0)
    8000636a:	00499493          	slli	s1,s3,0x4
    8000636e:	0001fa17          	auipc	s4,0x1f
    80006372:	c92a0a13          	addi	s4,s4,-878 # 80025000 <disk+0x2000>
    80006376:	000a3a83          	ld	s5,0(s4)
    8000637a:	9aa6                	add	s5,s5,s1
    8000637c:	f8040513          	addi	a0,s0,-128
    80006380:	ffffb097          	auipc	ra,0xffffb
    80006384:	d68080e7          	jalr	-664(ra) # 800010e8 <kvmpa>
    80006388:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000638c:	000a3783          	ld	a5,0(s4)
    80006390:	97a6                	add	a5,a5,s1
    80006392:	4741                	li	a4,16
    80006394:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006396:	000a3783          	ld	a5,0(s4)
    8000639a:	97a6                	add	a5,a5,s1
    8000639c:	4705                	li	a4,1
    8000639e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800063a2:	f9442703          	lw	a4,-108(s0)
    800063a6:	000a3783          	ld	a5,0(s4)
    800063aa:	97a6                	add	a5,a5,s1
    800063ac:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063b0:	0712                	slli	a4,a4,0x4
    800063b2:	000a3783          	ld	a5,0(s4)
    800063b6:	97ba                	add	a5,a5,a4
    800063b8:	05890693          	addi	a3,s2,88
    800063bc:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800063be:	000a3783          	ld	a5,0(s4)
    800063c2:	97ba                	add	a5,a5,a4
    800063c4:	40000693          	li	a3,1024
    800063c8:	c794                	sw	a3,8(a5)
  if(write)
    800063ca:	100d0a63          	beqz	s10,800064de <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800063ce:	0001f797          	auipc	a5,0x1f
    800063d2:	c327b783          	ld	a5,-974(a5) # 80025000 <disk+0x2000>
    800063d6:	97ba                	add	a5,a5,a4
    800063d8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063dc:	0001d517          	auipc	a0,0x1d
    800063e0:	c2450513          	addi	a0,a0,-988 # 80023000 <disk>
    800063e4:	0001f797          	auipc	a5,0x1f
    800063e8:	c1c78793          	addi	a5,a5,-996 # 80025000 <disk+0x2000>
    800063ec:	6394                	ld	a3,0(a5)
    800063ee:	96ba                	add	a3,a3,a4
    800063f0:	00c6d603          	lhu	a2,12(a3)
    800063f4:	00166613          	ori	a2,a2,1
    800063f8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800063fc:	f9842683          	lw	a3,-104(s0)
    80006400:	6390                	ld	a2,0(a5)
    80006402:	9732                	add	a4,a4,a2
    80006404:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006408:	20098613          	addi	a2,s3,512
    8000640c:	0612                	slli	a2,a2,0x4
    8000640e:	962a                	add	a2,a2,a0
    80006410:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006414:	00469713          	slli	a4,a3,0x4
    80006418:	6394                	ld	a3,0(a5)
    8000641a:	96ba                	add	a3,a3,a4
    8000641c:	6589                	lui	a1,0x2
    8000641e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006422:	94ae                	add	s1,s1,a1
    80006424:	94aa                	add	s1,s1,a0
    80006426:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006428:	6394                	ld	a3,0(a5)
    8000642a:	96ba                	add	a3,a3,a4
    8000642c:	4585                	li	a1,1
    8000642e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006430:	6394                	ld	a3,0(a5)
    80006432:	96ba                	add	a3,a3,a4
    80006434:	4509                	li	a0,2
    80006436:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000643a:	6394                	ld	a3,0(a5)
    8000643c:	9736                	add	a4,a4,a3
    8000643e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006442:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006446:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000644a:	6794                	ld	a3,8(a5)
    8000644c:	0026d703          	lhu	a4,2(a3)
    80006450:	8b1d                	andi	a4,a4,7
    80006452:	2709                	addiw	a4,a4,2
    80006454:	0706                	slli	a4,a4,0x1
    80006456:	9736                	add	a4,a4,a3
    80006458:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000645c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006460:	6798                	ld	a4,8(a5)
    80006462:	00275783          	lhu	a5,2(a4)
    80006466:	2785                	addiw	a5,a5,1
    80006468:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000646c:	100017b7          	lui	a5,0x10001
    80006470:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006474:	00492703          	lw	a4,4(s2)
    80006478:	4785                	li	a5,1
    8000647a:	02f71163          	bne	a4,a5,8000649c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000647e:	0001f997          	auipc	s3,0x1f
    80006482:	c2a98993          	addi	s3,s3,-982 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006486:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006488:	85ce                	mv	a1,s3
    8000648a:	854a                	mv	a0,s2
    8000648c:	ffffc097          	auipc	ra,0xffffc
    80006490:	16c080e7          	jalr	364(ra) # 800025f8 <sleep>
  while(b->disk == 1) {
    80006494:	00492783          	lw	a5,4(s2)
    80006498:	fe9788e3          	beq	a5,s1,80006488 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000649c:	f9042483          	lw	s1,-112(s0)
    800064a0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800064a4:	00479713          	slli	a4,a5,0x4
    800064a8:	0001d797          	auipc	a5,0x1d
    800064ac:	b5878793          	addi	a5,a5,-1192 # 80023000 <disk>
    800064b0:	97ba                	add	a5,a5,a4
    800064b2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800064b6:	0001f917          	auipc	s2,0x1f
    800064ba:	b4a90913          	addi	s2,s2,-1206 # 80025000 <disk+0x2000>
    free_desc(i);
    800064be:	8526                	mv	a0,s1
    800064c0:	00000097          	auipc	ra,0x0
    800064c4:	bf6080e7          	jalr	-1034(ra) # 800060b6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800064c8:	0492                	slli	s1,s1,0x4
    800064ca:	00093783          	ld	a5,0(s2)
    800064ce:	94be                	add	s1,s1,a5
    800064d0:	00c4d783          	lhu	a5,12(s1)
    800064d4:	8b85                	andi	a5,a5,1
    800064d6:	cf89                	beqz	a5,800064f0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800064d8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800064dc:	b7cd                	j	800064be <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800064de:	0001f797          	auipc	a5,0x1f
    800064e2:	b227b783          	ld	a5,-1246(a5) # 80025000 <disk+0x2000>
    800064e6:	97ba                	add	a5,a5,a4
    800064e8:	4689                	li	a3,2
    800064ea:	00d79623          	sh	a3,12(a5)
    800064ee:	b5fd                	j	800063dc <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064f0:	0001f517          	auipc	a0,0x1f
    800064f4:	bb850513          	addi	a0,a0,-1096 # 800250a8 <disk+0x20a8>
    800064f8:	ffffa097          	auipc	ra,0xffffa
    800064fc:	7cc080e7          	jalr	1996(ra) # 80000cc4 <release>
}
    80006500:	70e6                	ld	ra,120(sp)
    80006502:	7446                	ld	s0,112(sp)
    80006504:	74a6                	ld	s1,104(sp)
    80006506:	7906                	ld	s2,96(sp)
    80006508:	69e6                	ld	s3,88(sp)
    8000650a:	6a46                	ld	s4,80(sp)
    8000650c:	6aa6                	ld	s5,72(sp)
    8000650e:	6b06                	ld	s6,64(sp)
    80006510:	7be2                	ld	s7,56(sp)
    80006512:	7c42                	ld	s8,48(sp)
    80006514:	7ca2                	ld	s9,40(sp)
    80006516:	7d02                	ld	s10,32(sp)
    80006518:	6109                	addi	sp,sp,128
    8000651a:	8082                	ret
  if(write)
    8000651c:	e20d1ee3          	bnez	s10,80006358 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006520:	f8042023          	sw	zero,-128(s0)
    80006524:	bd2d                	j	8000635e <virtio_disk_rw+0xe2>

0000000080006526 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006526:	1101                	addi	sp,sp,-32
    80006528:	ec06                	sd	ra,24(sp)
    8000652a:	e822                	sd	s0,16(sp)
    8000652c:	e426                	sd	s1,8(sp)
    8000652e:	e04a                	sd	s2,0(sp)
    80006530:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006532:	0001f517          	auipc	a0,0x1f
    80006536:	b7650513          	addi	a0,a0,-1162 # 800250a8 <disk+0x20a8>
    8000653a:	ffffa097          	auipc	ra,0xffffa
    8000653e:	6d6080e7          	jalr	1750(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006542:	0001f717          	auipc	a4,0x1f
    80006546:	abe70713          	addi	a4,a4,-1346 # 80025000 <disk+0x2000>
    8000654a:	02075783          	lhu	a5,32(a4)
    8000654e:	6b18                	ld	a4,16(a4)
    80006550:	00275683          	lhu	a3,2(a4)
    80006554:	8ebd                	xor	a3,a3,a5
    80006556:	8a9d                	andi	a3,a3,7
    80006558:	cab9                	beqz	a3,800065ae <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000655a:	0001d917          	auipc	s2,0x1d
    8000655e:	aa690913          	addi	s2,s2,-1370 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006562:	0001f497          	auipc	s1,0x1f
    80006566:	a9e48493          	addi	s1,s1,-1378 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000656a:	078e                	slli	a5,a5,0x3
    8000656c:	97ba                	add	a5,a5,a4
    8000656e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006570:	20078713          	addi	a4,a5,512
    80006574:	0712                	slli	a4,a4,0x4
    80006576:	974a                	add	a4,a4,s2
    80006578:	03074703          	lbu	a4,48(a4)
    8000657c:	ef21                	bnez	a4,800065d4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000657e:	20078793          	addi	a5,a5,512
    80006582:	0792                	slli	a5,a5,0x4
    80006584:	97ca                	add	a5,a5,s2
    80006586:	7798                	ld	a4,40(a5)
    80006588:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000658c:	7788                	ld	a0,40(a5)
    8000658e:	ffffc097          	auipc	ra,0xffffc
    80006592:	1f0080e7          	jalr	496(ra) # 8000277e <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006596:	0204d783          	lhu	a5,32(s1)
    8000659a:	2785                	addiw	a5,a5,1
    8000659c:	8b9d                	andi	a5,a5,7
    8000659e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800065a2:	6898                	ld	a4,16(s1)
    800065a4:	00275683          	lhu	a3,2(a4)
    800065a8:	8a9d                	andi	a3,a3,7
    800065aa:	fcf690e3          	bne	a3,a5,8000656a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065ae:	10001737          	lui	a4,0x10001
    800065b2:	533c                	lw	a5,96(a4)
    800065b4:	8b8d                	andi	a5,a5,3
    800065b6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800065b8:	0001f517          	auipc	a0,0x1f
    800065bc:	af050513          	addi	a0,a0,-1296 # 800250a8 <disk+0x20a8>
    800065c0:	ffffa097          	auipc	ra,0xffffa
    800065c4:	704080e7          	jalr	1796(ra) # 80000cc4 <release>
}
    800065c8:	60e2                	ld	ra,24(sp)
    800065ca:	6442                	ld	s0,16(sp)
    800065cc:	64a2                	ld	s1,8(sp)
    800065ce:	6902                	ld	s2,0(sp)
    800065d0:	6105                	addi	sp,sp,32
    800065d2:	8082                	ret
      panic("virtio_disk_intr status");
    800065d4:	00002517          	auipc	a0,0x2
    800065d8:	30c50513          	addi	a0,a0,780 # 800088e0 <syscalls+0x3d0>
    800065dc:	ffffa097          	auipc	ra,0xffffa
    800065e0:	f6c080e7          	jalr	-148(ra) # 80000548 <panic>

00000000800065e4 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    800065e4:	7179                	addi	sp,sp,-48
    800065e6:	f406                	sd	ra,40(sp)
    800065e8:	f022                	sd	s0,32(sp)
    800065ea:	ec26                	sd	s1,24(sp)
    800065ec:	e84a                	sd	s2,16(sp)
    800065ee:	e44e                	sd	s3,8(sp)
    800065f0:	e052                	sd	s4,0(sp)
    800065f2:	1800                	addi	s0,sp,48
    800065f4:	892a                	mv	s2,a0
    800065f6:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    800065f8:	00003a17          	auipc	s4,0x3
    800065fc:	a30a0a13          	addi	s4,s4,-1488 # 80009028 <stats>
    80006600:	000a2683          	lw	a3,0(s4)
    80006604:	00002617          	auipc	a2,0x2
    80006608:	2f460613          	addi	a2,a2,756 # 800088f8 <syscalls+0x3e8>
    8000660c:	00000097          	auipc	ra,0x0
    80006610:	2c2080e7          	jalr	706(ra) # 800068ce <snprintf>
    80006614:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    80006616:	004a2683          	lw	a3,4(s4)
    8000661a:	00002617          	auipc	a2,0x2
    8000661e:	2ee60613          	addi	a2,a2,750 # 80008908 <syscalls+0x3f8>
    80006622:	85ce                	mv	a1,s3
    80006624:	954a                	add	a0,a0,s2
    80006626:	00000097          	auipc	ra,0x0
    8000662a:	2a8080e7          	jalr	680(ra) # 800068ce <snprintf>
  return n;
}
    8000662e:	9d25                	addw	a0,a0,s1
    80006630:	70a2                	ld	ra,40(sp)
    80006632:	7402                	ld	s0,32(sp)
    80006634:	64e2                	ld	s1,24(sp)
    80006636:	6942                	ld	s2,16(sp)
    80006638:	69a2                	ld	s3,8(sp)
    8000663a:	6a02                	ld	s4,0(sp)
    8000663c:	6145                	addi	sp,sp,48
    8000663e:	8082                	ret

0000000080006640 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80006640:	7179                	addi	sp,sp,-48
    80006642:	f406                	sd	ra,40(sp)
    80006644:	f022                	sd	s0,32(sp)
    80006646:	ec26                	sd	s1,24(sp)
    80006648:	e84a                	sd	s2,16(sp)
    8000664a:	e44e                	sd	s3,8(sp)
    8000664c:	1800                	addi	s0,sp,48
    8000664e:	89ae                	mv	s3,a1
    80006650:	84b2                	mv	s1,a2
    80006652:	8936                	mv	s2,a3
  struct proc *p = myproc();
    80006654:	ffffb097          	auipc	ra,0xffffb
    80006658:	690080e7          	jalr	1680(ra) # 80001ce4 <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    8000665c:	653c                	ld	a5,72(a0)
    8000665e:	02f4ff63          	bgeu	s1,a5,8000669c <copyin_new+0x5c>
    80006662:	01248733          	add	a4,s1,s2
    80006666:	02f77d63          	bgeu	a4,a5,800066a0 <copyin_new+0x60>
    8000666a:	02976d63          	bltu	a4,s1,800066a4 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    8000666e:	0009061b          	sext.w	a2,s2
    80006672:	85a6                	mv	a1,s1
    80006674:	854e                	mv	a0,s3
    80006676:	ffffa097          	auipc	ra,0xffffa
    8000667a:	6f6080e7          	jalr	1782(ra) # 80000d6c <memmove>
  stats.ncopyin++;   // XXX lock
    8000667e:	00003717          	auipc	a4,0x3
    80006682:	9aa70713          	addi	a4,a4,-1622 # 80009028 <stats>
    80006686:	431c                	lw	a5,0(a4)
    80006688:	2785                	addiw	a5,a5,1
    8000668a:	c31c                	sw	a5,0(a4)
  return 0;
    8000668c:	4501                	li	a0,0
}
    8000668e:	70a2                	ld	ra,40(sp)
    80006690:	7402                	ld	s0,32(sp)
    80006692:	64e2                	ld	s1,24(sp)
    80006694:	6942                	ld	s2,16(sp)
    80006696:	69a2                	ld	s3,8(sp)
    80006698:	6145                	addi	sp,sp,48
    8000669a:	8082                	ret
    return -1;
    8000669c:	557d                	li	a0,-1
    8000669e:	bfc5                	j	8000668e <copyin_new+0x4e>
    800066a0:	557d                	li	a0,-1
    800066a2:	b7f5                	j	8000668e <copyin_new+0x4e>
    800066a4:	557d                	li	a0,-1
    800066a6:	b7e5                	j	8000668e <copyin_new+0x4e>

00000000800066a8 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    800066a8:	7179                	addi	sp,sp,-48
    800066aa:	f406                	sd	ra,40(sp)
    800066ac:	f022                	sd	s0,32(sp)
    800066ae:	ec26                	sd	s1,24(sp)
    800066b0:	e84a                	sd	s2,16(sp)
    800066b2:	e44e                	sd	s3,8(sp)
    800066b4:	1800                	addi	s0,sp,48
    800066b6:	89ae                	mv	s3,a1
    800066b8:	8932                	mv	s2,a2
    800066ba:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    800066bc:	ffffb097          	auipc	ra,0xffffb
    800066c0:	628080e7          	jalr	1576(ra) # 80001ce4 <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    800066c4:	00003717          	auipc	a4,0x3
    800066c8:	96470713          	addi	a4,a4,-1692 # 80009028 <stats>
    800066cc:	435c                	lw	a5,4(a4)
    800066ce:	2785                	addiw	a5,a5,1
    800066d0:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    800066d2:	cc85                	beqz	s1,8000670a <copyinstr_new+0x62>
    800066d4:	00990833          	add	a6,s2,s1
    800066d8:	87ca                	mv	a5,s2
    800066da:	6538                	ld	a4,72(a0)
    800066dc:	00e7ff63          	bgeu	a5,a4,800066fa <copyinstr_new+0x52>
    dst[i] = s[i];
    800066e0:	0007c683          	lbu	a3,0(a5)
    800066e4:	41278733          	sub	a4,a5,s2
    800066e8:	974e                	add	a4,a4,s3
    800066ea:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    800066ee:	c285                	beqz	a3,8000670e <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    800066f0:	0785                	addi	a5,a5,1
    800066f2:	ff0794e3          	bne	a5,a6,800066da <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    800066f6:	557d                	li	a0,-1
    800066f8:	a011                	j	800066fc <copyinstr_new+0x54>
    800066fa:	557d                	li	a0,-1
}
    800066fc:	70a2                	ld	ra,40(sp)
    800066fe:	7402                	ld	s0,32(sp)
    80006700:	64e2                	ld	s1,24(sp)
    80006702:	6942                	ld	s2,16(sp)
    80006704:	69a2                	ld	s3,8(sp)
    80006706:	6145                	addi	sp,sp,48
    80006708:	8082                	ret
  return -1;
    8000670a:	557d                	li	a0,-1
    8000670c:	bfc5                	j	800066fc <copyinstr_new+0x54>
      return 0;
    8000670e:	4501                	li	a0,0
    80006710:	b7f5                	j	800066fc <copyinstr_new+0x54>

0000000080006712 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006712:	1141                	addi	sp,sp,-16
    80006714:	e422                	sd	s0,8(sp)
    80006716:	0800                	addi	s0,sp,16
  return -1;
}
    80006718:	557d                	li	a0,-1
    8000671a:	6422                	ld	s0,8(sp)
    8000671c:	0141                	addi	sp,sp,16
    8000671e:	8082                	ret

0000000080006720 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006720:	7179                	addi	sp,sp,-48
    80006722:	f406                	sd	ra,40(sp)
    80006724:	f022                	sd	s0,32(sp)
    80006726:	ec26                	sd	s1,24(sp)
    80006728:	e84a                	sd	s2,16(sp)
    8000672a:	e44e                	sd	s3,8(sp)
    8000672c:	e052                	sd	s4,0(sp)
    8000672e:	1800                	addi	s0,sp,48
    80006730:	892a                	mv	s2,a0
    80006732:	89ae                	mv	s3,a1
    80006734:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    80006736:	00020517          	auipc	a0,0x20
    8000673a:	8ca50513          	addi	a0,a0,-1846 # 80026000 <stats>
    8000673e:	ffffa097          	auipc	ra,0xffffa
    80006742:	4d2080e7          	jalr	1234(ra) # 80000c10 <acquire>

  if(stats.sz == 0) {
    80006746:	00021797          	auipc	a5,0x21
    8000674a:	8d27a783          	lw	a5,-1838(a5) # 80027018 <stats+0x1018>
    8000674e:	cbb5                	beqz	a5,800067c2 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006750:	00021797          	auipc	a5,0x21
    80006754:	8b078793          	addi	a5,a5,-1872 # 80027000 <stats+0x1000>
    80006758:	4fd8                	lw	a4,28(a5)
    8000675a:	4f9c                	lw	a5,24(a5)
    8000675c:	9f99                	subw	a5,a5,a4
    8000675e:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006762:	06d05e63          	blez	a3,800067de <statsread+0xbe>
    if(m > n)
    80006766:	8a3e                	mv	s4,a5
    80006768:	00d4d363          	bge	s1,a3,8000676e <statsread+0x4e>
    8000676c:	8a26                	mv	s4,s1
    8000676e:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006772:	86a6                	mv	a3,s1
    80006774:	00020617          	auipc	a2,0x20
    80006778:	8a460613          	addi	a2,a2,-1884 # 80026018 <stats+0x18>
    8000677c:	963a                	add	a2,a2,a4
    8000677e:	85ce                	mv	a1,s3
    80006780:	854a                	mv	a0,s2
    80006782:	ffffc097          	auipc	ra,0xffffc
    80006786:	0d8080e7          	jalr	216(ra) # 8000285a <either_copyout>
    8000678a:	57fd                	li	a5,-1
    8000678c:	00f50a63          	beq	a0,a5,800067a0 <statsread+0x80>
      stats.off += m;
    80006790:	00021717          	auipc	a4,0x21
    80006794:	87070713          	addi	a4,a4,-1936 # 80027000 <stats+0x1000>
    80006798:	4f5c                	lw	a5,28(a4)
    8000679a:	014787bb          	addw	a5,a5,s4
    8000679e:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    800067a0:	00020517          	auipc	a0,0x20
    800067a4:	86050513          	addi	a0,a0,-1952 # 80026000 <stats>
    800067a8:	ffffa097          	auipc	ra,0xffffa
    800067ac:	51c080e7          	jalr	1308(ra) # 80000cc4 <release>
  return m;
}
    800067b0:	8526                	mv	a0,s1
    800067b2:	70a2                	ld	ra,40(sp)
    800067b4:	7402                	ld	s0,32(sp)
    800067b6:	64e2                	ld	s1,24(sp)
    800067b8:	6942                	ld	s2,16(sp)
    800067ba:	69a2                	ld	s3,8(sp)
    800067bc:	6a02                	ld	s4,0(sp)
    800067be:	6145                	addi	sp,sp,48
    800067c0:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    800067c2:	6585                	lui	a1,0x1
    800067c4:	00020517          	auipc	a0,0x20
    800067c8:	85450513          	addi	a0,a0,-1964 # 80026018 <stats+0x18>
    800067cc:	00000097          	auipc	ra,0x0
    800067d0:	e18080e7          	jalr	-488(ra) # 800065e4 <statscopyin>
    800067d4:	00021797          	auipc	a5,0x21
    800067d8:	84a7a223          	sw	a0,-1980(a5) # 80027018 <stats+0x1018>
    800067dc:	bf95                	j	80006750 <statsread+0x30>
    stats.sz = 0;
    800067de:	00021797          	auipc	a5,0x21
    800067e2:	82278793          	addi	a5,a5,-2014 # 80027000 <stats+0x1000>
    800067e6:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    800067ea:	0007ae23          	sw	zero,28(a5)
    m = -1;
    800067ee:	54fd                	li	s1,-1
    800067f0:	bf45                	j	800067a0 <statsread+0x80>

00000000800067f2 <statsinit>:

void
statsinit(void)
{
    800067f2:	1141                	addi	sp,sp,-16
    800067f4:	e406                	sd	ra,8(sp)
    800067f6:	e022                	sd	s0,0(sp)
    800067f8:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    800067fa:	00002597          	auipc	a1,0x2
    800067fe:	11e58593          	addi	a1,a1,286 # 80008918 <syscalls+0x408>
    80006802:	0001f517          	auipc	a0,0x1f
    80006806:	7fe50513          	addi	a0,a0,2046 # 80026000 <stats>
    8000680a:	ffffa097          	auipc	ra,0xffffa
    8000680e:	376080e7          	jalr	886(ra) # 80000b80 <initlock>

  devsw[STATS].read = statsread;
    80006812:	0001b797          	auipc	a5,0x1b
    80006816:	59e78793          	addi	a5,a5,1438 # 80021db0 <devsw>
    8000681a:	00000717          	auipc	a4,0x0
    8000681e:	f0670713          	addi	a4,a4,-250 # 80006720 <statsread>
    80006822:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006824:	00000717          	auipc	a4,0x0
    80006828:	eee70713          	addi	a4,a4,-274 # 80006712 <statswrite>
    8000682c:	f798                	sd	a4,40(a5)
}
    8000682e:	60a2                	ld	ra,8(sp)
    80006830:	6402                	ld	s0,0(sp)
    80006832:	0141                	addi	sp,sp,16
    80006834:	8082                	ret

0000000080006836 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    80006836:	1101                	addi	sp,sp,-32
    80006838:	ec22                	sd	s0,24(sp)
    8000683a:	1000                	addi	s0,sp,32
    8000683c:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    8000683e:	c299                	beqz	a3,80006844 <sprintint+0xe>
    80006840:	0805c163          	bltz	a1,800068c2 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006844:	2581                	sext.w	a1,a1
    80006846:	4301                	li	t1,0

  i = 0;
    80006848:	fe040713          	addi	a4,s0,-32
    8000684c:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    8000684e:	2601                	sext.w	a2,a2
    80006850:	00002697          	auipc	a3,0x2
    80006854:	0d068693          	addi	a3,a3,208 # 80008920 <digits>
    80006858:	88aa                	mv	a7,a0
    8000685a:	2505                	addiw	a0,a0,1
    8000685c:	02c5f7bb          	remuw	a5,a1,a2
    80006860:	1782                	slli	a5,a5,0x20
    80006862:	9381                	srli	a5,a5,0x20
    80006864:	97b6                	add	a5,a5,a3
    80006866:	0007c783          	lbu	a5,0(a5)
    8000686a:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000686e:	0005879b          	sext.w	a5,a1
    80006872:	02c5d5bb          	divuw	a1,a1,a2
    80006876:	0705                	addi	a4,a4,1
    80006878:	fec7f0e3          	bgeu	a5,a2,80006858 <sprintint+0x22>

  if(sign)
    8000687c:	00030b63          	beqz	t1,80006892 <sprintint+0x5c>
    buf[i++] = '-';
    80006880:	ff040793          	addi	a5,s0,-16
    80006884:	97aa                	add	a5,a5,a0
    80006886:	02d00713          	li	a4,45
    8000688a:	fee78823          	sb	a4,-16(a5)
    8000688e:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006892:	02a05c63          	blez	a0,800068ca <sprintint+0x94>
    80006896:	fe040793          	addi	a5,s0,-32
    8000689a:	00a78733          	add	a4,a5,a0
    8000689e:	87c2                	mv	a5,a6
    800068a0:	0805                	addi	a6,a6,1
    800068a2:	fff5061b          	addiw	a2,a0,-1
    800068a6:	1602                	slli	a2,a2,0x20
    800068a8:	9201                	srli	a2,a2,0x20
    800068aa:	9642                	add	a2,a2,a6
  *s = c;
    800068ac:	fff74683          	lbu	a3,-1(a4)
    800068b0:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    800068b4:	177d                	addi	a4,a4,-1
    800068b6:	0785                	addi	a5,a5,1
    800068b8:	fec79ae3          	bne	a5,a2,800068ac <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    800068bc:	6462                	ld	s0,24(sp)
    800068be:	6105                	addi	sp,sp,32
    800068c0:	8082                	ret
    x = -xx;
    800068c2:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    800068c6:	4305                	li	t1,1
    x = -xx;
    800068c8:	b741                	j	80006848 <sprintint+0x12>
  while(--i >= 0)
    800068ca:	4501                	li	a0,0
    800068cc:	bfc5                	j	800068bc <sprintint+0x86>

00000000800068ce <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    800068ce:	7171                	addi	sp,sp,-176
    800068d0:	fc86                	sd	ra,120(sp)
    800068d2:	f8a2                	sd	s0,112(sp)
    800068d4:	f4a6                	sd	s1,104(sp)
    800068d6:	f0ca                	sd	s2,96(sp)
    800068d8:	ecce                	sd	s3,88(sp)
    800068da:	e8d2                	sd	s4,80(sp)
    800068dc:	e4d6                	sd	s5,72(sp)
    800068de:	e0da                	sd	s6,64(sp)
    800068e0:	fc5e                	sd	s7,56(sp)
    800068e2:	f862                	sd	s8,48(sp)
    800068e4:	f466                	sd	s9,40(sp)
    800068e6:	f06a                	sd	s10,32(sp)
    800068e8:	ec6e                	sd	s11,24(sp)
    800068ea:	0100                	addi	s0,sp,128
    800068ec:	e414                	sd	a3,8(s0)
    800068ee:	e818                	sd	a4,16(s0)
    800068f0:	ec1c                	sd	a5,24(s0)
    800068f2:	03043023          	sd	a6,32(s0)
    800068f6:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    800068fa:	ca0d                	beqz	a2,8000692c <snprintf+0x5e>
    800068fc:	8baa                	mv	s7,a0
    800068fe:	89ae                	mv	s3,a1
    80006900:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006902:	00840793          	addi	a5,s0,8
    80006906:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    8000690a:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000690c:	4901                	li	s2,0
    8000690e:	02b05763          	blez	a1,8000693c <snprintf+0x6e>
    if(c != '%'){
    80006912:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006916:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    8000691a:	02800d93          	li	s11,40
  *s = c;
    8000691e:	02500d13          	li	s10,37
    switch(c){
    80006922:	07800c93          	li	s9,120
    80006926:	06400c13          	li	s8,100
    8000692a:	a01d                	j	80006950 <snprintf+0x82>
    panic("null fmt");
    8000692c:	00001517          	auipc	a0,0x1
    80006930:	6ec50513          	addi	a0,a0,1772 # 80008018 <etext+0x18>
    80006934:	ffffa097          	auipc	ra,0xffffa
    80006938:	c14080e7          	jalr	-1004(ra) # 80000548 <panic>
  int off = 0;
    8000693c:	4481                	li	s1,0
    8000693e:	a86d                	j	800069f8 <snprintf+0x12a>
  *s = c;
    80006940:	009b8733          	add	a4,s7,s1
    80006944:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006948:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000694a:	2905                	addiw	s2,s2,1
    8000694c:	0b34d663          	bge	s1,s3,800069f8 <snprintf+0x12a>
    80006950:	012a07b3          	add	a5,s4,s2
    80006954:	0007c783          	lbu	a5,0(a5)
    80006958:	0007871b          	sext.w	a4,a5
    8000695c:	cfd1                	beqz	a5,800069f8 <snprintf+0x12a>
    if(c != '%'){
    8000695e:	ff5711e3          	bne	a4,s5,80006940 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    80006962:	2905                	addiw	s2,s2,1
    80006964:	012a07b3          	add	a5,s4,s2
    80006968:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    8000696c:	c7d1                	beqz	a5,800069f8 <snprintf+0x12a>
    switch(c){
    8000696e:	05678c63          	beq	a5,s6,800069c6 <snprintf+0xf8>
    80006972:	02fb6763          	bltu	s6,a5,800069a0 <snprintf+0xd2>
    80006976:	0b578763          	beq	a5,s5,80006a24 <snprintf+0x156>
    8000697a:	0b879b63          	bne	a5,s8,80006a30 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    8000697e:	f8843783          	ld	a5,-120(s0)
    80006982:	00878713          	addi	a4,a5,8
    80006986:	f8e43423          	sd	a4,-120(s0)
    8000698a:	4685                	li	a3,1
    8000698c:	4629                	li	a2,10
    8000698e:	438c                	lw	a1,0(a5)
    80006990:	009b8533          	add	a0,s7,s1
    80006994:	00000097          	auipc	ra,0x0
    80006998:	ea2080e7          	jalr	-350(ra) # 80006836 <sprintint>
    8000699c:	9ca9                	addw	s1,s1,a0
      break;
    8000699e:	b775                	j	8000694a <snprintf+0x7c>
    switch(c){
    800069a0:	09979863          	bne	a5,s9,80006a30 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    800069a4:	f8843783          	ld	a5,-120(s0)
    800069a8:	00878713          	addi	a4,a5,8
    800069ac:	f8e43423          	sd	a4,-120(s0)
    800069b0:	4685                	li	a3,1
    800069b2:	4641                	li	a2,16
    800069b4:	438c                	lw	a1,0(a5)
    800069b6:	009b8533          	add	a0,s7,s1
    800069ba:	00000097          	auipc	ra,0x0
    800069be:	e7c080e7          	jalr	-388(ra) # 80006836 <sprintint>
    800069c2:	9ca9                	addw	s1,s1,a0
      break;
    800069c4:	b759                	j	8000694a <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    800069c6:	f8843783          	ld	a5,-120(s0)
    800069ca:	00878713          	addi	a4,a5,8
    800069ce:	f8e43423          	sd	a4,-120(s0)
    800069d2:	639c                	ld	a5,0(a5)
    800069d4:	c3b1                	beqz	a5,80006a18 <snprintf+0x14a>
      for(; *s && off < sz; s++)
    800069d6:	0007c703          	lbu	a4,0(a5)
    800069da:	db25                	beqz	a4,8000694a <snprintf+0x7c>
    800069dc:	0134de63          	bge	s1,s3,800069f8 <snprintf+0x12a>
    800069e0:	009b86b3          	add	a3,s7,s1
  *s = c;
    800069e4:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    800069e8:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    800069ea:	0785                	addi	a5,a5,1
    800069ec:	0007c703          	lbu	a4,0(a5)
    800069f0:	df29                	beqz	a4,8000694a <snprintf+0x7c>
    800069f2:	0685                	addi	a3,a3,1
    800069f4:	fe9998e3          	bne	s3,s1,800069e4 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    800069f8:	8526                	mv	a0,s1
    800069fa:	70e6                	ld	ra,120(sp)
    800069fc:	7446                	ld	s0,112(sp)
    800069fe:	74a6                	ld	s1,104(sp)
    80006a00:	7906                	ld	s2,96(sp)
    80006a02:	69e6                	ld	s3,88(sp)
    80006a04:	6a46                	ld	s4,80(sp)
    80006a06:	6aa6                	ld	s5,72(sp)
    80006a08:	6b06                	ld	s6,64(sp)
    80006a0a:	7be2                	ld	s7,56(sp)
    80006a0c:	7c42                	ld	s8,48(sp)
    80006a0e:	7ca2                	ld	s9,40(sp)
    80006a10:	7d02                	ld	s10,32(sp)
    80006a12:	6de2                	ld	s11,24(sp)
    80006a14:	614d                	addi	sp,sp,176
    80006a16:	8082                	ret
        s = "(null)";
    80006a18:	00001797          	auipc	a5,0x1
    80006a1c:	5f878793          	addi	a5,a5,1528 # 80008010 <etext+0x10>
      for(; *s && off < sz; s++)
    80006a20:	876e                	mv	a4,s11
    80006a22:	bf6d                	j	800069dc <snprintf+0x10e>
  *s = c;
    80006a24:	009b87b3          	add	a5,s7,s1
    80006a28:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    80006a2c:	2485                	addiw	s1,s1,1
      break;
    80006a2e:	bf31                	j	8000694a <snprintf+0x7c>
  *s = c;
    80006a30:	009b8733          	add	a4,s7,s1
    80006a34:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006a38:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006a3c:	975e                	add	a4,a4,s7
    80006a3e:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006a42:	2489                	addiw	s1,s1,2
      break;
    80006a44:	b719                	j	8000694a <snprintf+0x7c>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...

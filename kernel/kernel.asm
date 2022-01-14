
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
    80000060:	c0478793          	addi	a5,a5,-1020 # 80005c60 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
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
    8000012a:	388080e7          	jalr	904(ra) # 800024ae <either_copyin>
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
    800001d2:	810080e7          	jalr	-2032(ra) # 800019de <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	018080e7          	jalr	24(ra) # 800021f6 <sleep>
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
    8000021e:	23e080e7          	jalr	574(ra) # 80002458 <either_copyout>
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
    80000300:	208080e7          	jalr	520(ra) # 80002504 <procdump>
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
    80000454:	f2c080e7          	jalr	-212(ra) # 8000237c <wakeup>
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
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
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
    80000482:	00021797          	auipc	a5,0x21
    80000486:	52e78793          	addi	a5,a5,1326 # 800219b0 <devsw>
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
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
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
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
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
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
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
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
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
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
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
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
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
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
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
    800008ba:	ac6080e7          	jalr	-1338(ra) # 8000237c <wakeup>
    
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
    80000954:	8a6080e7          	jalr	-1882(ra) # 800021f6 <sleep>
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
    80000a38:	00025797          	auipc	a5,0x25
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80026000 <end>
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
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
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
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00025517          	auipc	a0,0x25
    80000b0c:	4f850513          	addi	a0,a0,1272 # 80026000 <end>
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
    80000bae:	e18080e7          	jalr	-488(ra) # 800019c2 <mycpu>
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
    80000be0:	de6080e7          	jalr	-538(ra) # 800019c2 <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	dda080e7          	jalr	-550(ra) # 800019c2 <mycpu>
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
    80000c04:	dc2080e7          	jalr	-574(ra) # 800019c2 <mycpu>
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
    80000c44:	d82080e7          	jalr	-638(ra) # 800019c2 <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    panic("acquire");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	41c50513          	addi	a0,a0,1052 # 80008070 <digits+0x30>
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
    80000c70:	d56080e7          	jalr	-682(ra) # 800019c2 <mycpu>
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
    80000ca8:	3d450513          	addi	a0,a0,980 # 80008078 <digits+0x38>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
    panic("pop_off");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3dc50513          	addi	a0,a0,988 # 80008090 <digits+0x50>
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
    80000d00:	39c50513          	addi	a0,a0,924 # 80008098 <digits+0x58>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	844080e7          	jalr	-1980(ra) # 80000548 <panic>

0000000080000d0c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d12:	ce09                	beqz	a2,80000d2c <memset+0x20>
    80000d14:	87aa                	mv	a5,a0
    80000d16:	fff6071b          	addiw	a4,a2,-1
    80000d1a:	1702                	slli	a4,a4,0x20
    80000d1c:	9301                	srli	a4,a4,0x20
    80000d1e:	0705                	addi	a4,a4,1
    80000d20:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d22:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d26:	0785                	addi	a5,a5,1
    80000d28:	fee79de3          	bne	a5,a4,80000d22 <memset+0x16>
  }
  return dst;
}
    80000d2c:	6422                	ld	s0,8(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret

0000000080000d32 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d38:	ca05                	beqz	a2,80000d68 <memcmp+0x36>
    80000d3a:	fff6069b          	addiw	a3,a2,-1
    80000d3e:	1682                	slli	a3,a3,0x20
    80000d40:	9281                	srli	a3,a3,0x20
    80000d42:	0685                	addi	a3,a3,1
    80000d44:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d46:	00054783          	lbu	a5,0(a0)
    80000d4a:	0005c703          	lbu	a4,0(a1)
    80000d4e:	00e79863          	bne	a5,a4,80000d5e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d52:	0505                	addi	a0,a0,1
    80000d54:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d56:	fed518e3          	bne	a0,a3,80000d46 <memcmp+0x14>
  }

  return 0;
    80000d5a:	4501                	li	a0,0
    80000d5c:	a019                	j	80000d62 <memcmp+0x30>
      return *s1 - *s2;
    80000d5e:	40e7853b          	subw	a0,a5,a4
}
    80000d62:	6422                	ld	s0,8(sp)
    80000d64:	0141                	addi	sp,sp,16
    80000d66:	8082                	ret
  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	bfe5                	j	80000d62 <memcmp+0x30>

0000000080000d6c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d72:	00a5f963          	bgeu	a1,a0,80000d84 <memmove+0x18>
    80000d76:	02061713          	slli	a4,a2,0x20
    80000d7a:	9301                	srli	a4,a4,0x20
    80000d7c:	00e587b3          	add	a5,a1,a4
    80000d80:	02f56563          	bltu	a0,a5,80000daa <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x38>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x28>

  return dst;
}
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
    d += n;
    80000daa:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dac:	fff6069b          	addiw	a3,a2,-1
    80000db0:	da75                	beqz	a2,80000da4 <memmove+0x38>
    80000db2:	02069613          	slli	a2,a3,0x20
    80000db6:	9201                	srli	a2,a2,0x20
    80000db8:	fff64613          	not	a2,a2
    80000dbc:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dbe:	17fd                	addi	a5,a5,-1
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	0007c683          	lbu	a3,0(a5)
    80000dc6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dca:	fec79ae3          	bne	a5,a2,80000dbe <memmove+0x52>
    80000dce:	bfd9                	j	80000da4 <memmove+0x38>

0000000080000dd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f94080e7          	jalr	-108(ra) # 80000d6c <memmove>
}
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    n--, p++, q++;
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
  if(n == 0)
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e42:	00c05d63          	blez	a2,80000e5c <strncpy+0x38>
    80000e46:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4e:	fff6c793          	not	a5,a3
    80000e52:	9fb9                	addw	a5,a5,a4
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
  return os;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:

int
strlen(const char *s)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
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
    ;
  return n;
}
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
  for(n = 0; s[n]; n++)
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
    80000eca:	aec080e7          	jalr	-1300(ra) # 800019b2 <cpuid>
    virtio_disk_init(); // emulated hard disk
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
    80000ee6:	ad0080e7          	jalr	-1328(ra) # 800019b2 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0d8080e7          	jalr	216(ra) # 80000fd4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00001097          	auipc	ra,0x1
    80000f08:	77c080e7          	jalr	1916(ra) # 80002680 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	d94080e7          	jalr	-620(ra) # 80005ca0 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	006080e7          	jalr	6(ra) # 80001f1a <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    printfinit();
    80000f24:	00000097          	auipc	ra,0x0
    80000f28:	854080e7          	jalr	-1964(ra) # 80000778 <printfinit>
    printf("\n");
    80000f2c:	00007517          	auipc	a0,0x7
    80000f30:	19c50513          	addi	a0,a0,412 # 800080c8 <digits+0x88>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	65e080e7          	jalr	1630(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f3c:	00007517          	auipc	a0,0x7
    80000f40:	16450513          	addi	a0,a0,356 # 800080a0 <digits+0x60>
    80000f44:	fffff097          	auipc	ra,0xfffff
    80000f48:	64e080e7          	jalr	1614(ra) # 80000592 <printf>
    printf("\n");
    80000f4c:	00007517          	auipc	a0,0x7
    80000f50:	17c50513          	addi	a0,a0,380 # 800080c8 <digits+0x88>
    80000f54:	fffff097          	auipc	ra,0xfffff
    80000f58:	63e080e7          	jalr	1598(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	b88080e7          	jalr	-1144(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	2a0080e7          	jalr	672(ra) # 80001204 <kvminit>
    kvminithart();   // turn on paging
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	068080e7          	jalr	104(ra) # 80000fd4 <kvminithart>
    procinit();      // process table
    80000f74:	00001097          	auipc	ra,0x1
    80000f78:	96e080e7          	jalr	-1682(ra) # 800018e2 <procinit>
    trapinit();      // trap vectors
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	6dc080e7          	jalr	1756(ra) # 80002658 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	6fc080e7          	jalr	1788(ra) # 80002680 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	cfe080e7          	jalr	-770(ra) # 80005c8a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	d0c080e7          	jalr	-756(ra) # 80005ca0 <plicinithart>
    binit();         // buffer cache
    80000f9c:	00002097          	auipc	ra,0x2
    80000fa0:	eae080e7          	jalr	-338(ra) # 80002e4a <binit>
    iinit();         // inode cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	53e080e7          	jalr	1342(ra) # 800034e2 <iinit>
    fileinit();      // file table
    80000fac:	00003097          	auipc	ra,0x3
    80000fb0:	4d8080e7          	jalr	1240(ra) # 80004484 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb4:	00005097          	auipc	ra,0x5
    80000fb8:	df4080e7          	jalr	-524(ra) # 80005da8 <virtio_disk_init>
    userinit();      // first user process
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	cec080e7          	jalr	-788(ra) # 80001ca8 <userinit>
    __sync_synchronize();
    80000fc4:	0ff0000f          	fence
    started = 1;
    80000fc8:	4785                	li	a5,1
    80000fca:	00008717          	auipc	a4,0x8
    80000fce:	04f72123          	sw	a5,66(a4) # 8000900c <started>
    80000fd2:	b789                	j	80000f14 <main+0x56>

0000000080000fd4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fd4:	1141                	addi	sp,sp,-16
    80000fd6:	e422                	sd	s0,8(sp)
    80000fd8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fda:	00008797          	auipc	a5,0x8
    80000fde:	0367b783          	ld	a5,54(a5) # 80009010 <kernel_pagetable>
    80000fe2:	83b1                	srli	a5,a5,0xc
    80000fe4:	577d                	li	a4,-1
    80000fe6:	177e                	slli	a4,a4,0x3f
    80000fe8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fea:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fee:	12000073          	sfence.vma
  sfence_vma();
}
    80000ff2:	6422                	ld	s0,8(sp)
    80000ff4:	0141                	addi	sp,sp,16
    80000ff6:	8082                	ret

0000000080000ff8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000ff8:	7139                	addi	sp,sp,-64
    80000ffa:	fc06                	sd	ra,56(sp)
    80000ffc:	f822                	sd	s0,48(sp)
    80000ffe:	f426                	sd	s1,40(sp)
    80001000:	f04a                	sd	s2,32(sp)
    80001002:	ec4e                	sd	s3,24(sp)
    80001004:	e852                	sd	s4,16(sp)
    80001006:	e456                	sd	s5,8(sp)
    80001008:	e05a                	sd	s6,0(sp)
    8000100a:	0080                	addi	s0,sp,64
    8000100c:	84aa                	mv	s1,a0
    8000100e:	89ae                	mv	s3,a1
    80001010:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001012:	57fd                	li	a5,-1
    80001014:	83e9                	srli	a5,a5,0x1a
    80001016:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001018:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000101a:	04b7f263          	bgeu	a5,a1,8000105e <walk+0x66>
    panic("walk");
    8000101e:	00007517          	auipc	a0,0x7
    80001022:	0b250513          	addi	a0,a0,178 # 800080d0 <digits+0x90>
    80001026:	fffff097          	auipc	ra,0xfffff
    8000102a:	522080e7          	jalr	1314(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000102e:	060a8663          	beqz	s5,8000109a <walk+0xa2>
    80001032:	00000097          	auipc	ra,0x0
    80001036:	aee080e7          	jalr	-1298(ra) # 80000b20 <kalloc>
    8000103a:	84aa                	mv	s1,a0
    8000103c:	c529                	beqz	a0,80001086 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000103e:	6605                	lui	a2,0x1
    80001040:	4581                	li	a1,0
    80001042:	00000097          	auipc	ra,0x0
    80001046:	cca080e7          	jalr	-822(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000104a:	00c4d793          	srli	a5,s1,0xc
    8000104e:	07aa                	slli	a5,a5,0xa
    80001050:	0017e793          	ori	a5,a5,1
    80001054:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001058:	3a5d                	addiw	s4,s4,-9
    8000105a:	036a0063          	beq	s4,s6,8000107a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000105e:	0149d933          	srl	s2,s3,s4
    80001062:	1ff97913          	andi	s2,s2,511
    80001066:	090e                	slli	s2,s2,0x3
    80001068:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000106a:	00093483          	ld	s1,0(s2)
    8000106e:	0014f793          	andi	a5,s1,1
    80001072:	dfd5                	beqz	a5,8000102e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001074:	80a9                	srli	s1,s1,0xa
    80001076:	04b2                	slli	s1,s1,0xc
    80001078:	b7c5                	j	80001058 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000107a:	00c9d513          	srli	a0,s3,0xc
    8000107e:	1ff57513          	andi	a0,a0,511
    80001082:	050e                	slli	a0,a0,0x3
    80001084:	9526                	add	a0,a0,s1
}
    80001086:	70e2                	ld	ra,56(sp)
    80001088:	7442                	ld	s0,48(sp)
    8000108a:	74a2                	ld	s1,40(sp)
    8000108c:	7902                	ld	s2,32(sp)
    8000108e:	69e2                	ld	s3,24(sp)
    80001090:	6a42                	ld	s4,16(sp)
    80001092:	6aa2                	ld	s5,8(sp)
    80001094:	6b02                	ld	s6,0(sp)
    80001096:	6121                	addi	sp,sp,64
    80001098:	8082                	ret
        return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7ed                	j	80001086 <walk+0x8e>

000000008000109e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000109e:	57fd                	li	a5,-1
    800010a0:	83e9                	srli	a5,a5,0x1a
    800010a2:	00b7f463          	bgeu	a5,a1,800010aa <walkaddr+0xc>
    return 0;
    800010a6:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010a8:	8082                	ret
{
    800010aa:	1141                	addi	sp,sp,-16
    800010ac:	e406                	sd	ra,8(sp)
    800010ae:	e022                	sd	s0,0(sp)
    800010b0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010b2:	4601                	li	a2,0
    800010b4:	00000097          	auipc	ra,0x0
    800010b8:	f44080e7          	jalr	-188(ra) # 80000ff8 <walk>
  if(pte == 0)
    800010bc:	c105                	beqz	a0,800010dc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010be:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c0:	0117f693          	andi	a3,a5,17
    800010c4:	4745                	li	a4,17
    return 0;
    800010c6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010c8:	00e68663          	beq	a3,a4,800010d4 <walkaddr+0x36>
}
    800010cc:	60a2                	ld	ra,8(sp)
    800010ce:	6402                	ld	s0,0(sp)
    800010d0:	0141                	addi	sp,sp,16
    800010d2:	8082                	ret
  pa = PTE2PA(*pte);
    800010d4:	00a7d513          	srli	a0,a5,0xa
    800010d8:	0532                	slli	a0,a0,0xc
  return pa;
    800010da:	bfcd                	j	800010cc <walkaddr+0x2e>
    return 0;
    800010dc:	4501                	li	a0,0
    800010de:	b7fd                	j	800010cc <walkaddr+0x2e>

00000000800010e0 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010e0:	1101                	addi	sp,sp,-32
    800010e2:	ec06                	sd	ra,24(sp)
    800010e4:	e822                	sd	s0,16(sp)
    800010e6:	e426                	sd	s1,8(sp)
    800010e8:	1000                	addi	s0,sp,32
    800010ea:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010ec:	1552                	slli	a0,a0,0x34
    800010ee:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010f2:	4601                	li	a2,0
    800010f4:	00008517          	auipc	a0,0x8
    800010f8:	f1c53503          	ld	a0,-228(a0) # 80009010 <kernel_pagetable>
    800010fc:	00000097          	auipc	ra,0x0
    80001100:	efc080e7          	jalr	-260(ra) # 80000ff8 <walk>
  if(pte == 0)
    80001104:	cd09                	beqz	a0,8000111e <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001106:	6108                	ld	a0,0(a0)
    80001108:	00157793          	andi	a5,a0,1
    8000110c:	c38d                	beqz	a5,8000112e <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000110e:	8129                	srli	a0,a0,0xa
    80001110:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001112:	9526                	add	a0,a0,s1
    80001114:	60e2                	ld	ra,24(sp)
    80001116:	6442                	ld	s0,16(sp)
    80001118:	64a2                	ld	s1,8(sp)
    8000111a:	6105                	addi	sp,sp,32
    8000111c:	8082                	ret
    panic("kvmpa");
    8000111e:	00007517          	auipc	a0,0x7
    80001122:	fba50513          	addi	a0,a0,-70 # 800080d8 <digits+0x98>
    80001126:	fffff097          	auipc	ra,0xfffff
    8000112a:	422080e7          	jalr	1058(ra) # 80000548 <panic>
    panic("kvmpa");
    8000112e:	00007517          	auipc	a0,0x7
    80001132:	faa50513          	addi	a0,a0,-86 # 800080d8 <digits+0x98>
    80001136:	fffff097          	auipc	ra,0xfffff
    8000113a:	412080e7          	jalr	1042(ra) # 80000548 <panic>

000000008000113e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000113e:	715d                	addi	sp,sp,-80
    80001140:	e486                	sd	ra,72(sp)
    80001142:	e0a2                	sd	s0,64(sp)
    80001144:	fc26                	sd	s1,56(sp)
    80001146:	f84a                	sd	s2,48(sp)
    80001148:	f44e                	sd	s3,40(sp)
    8000114a:	f052                	sd	s4,32(sp)
    8000114c:	ec56                	sd	s5,24(sp)
    8000114e:	e85a                	sd	s6,16(sp)
    80001150:	e45e                	sd	s7,8(sp)
    80001152:	0880                	addi	s0,sp,80
    80001154:	8aaa                	mv	s5,a0
    80001156:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001158:	777d                	lui	a4,0xfffff
    8000115a:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000115e:	167d                	addi	a2,a2,-1
    80001160:	00b609b3          	add	s3,a2,a1
    80001164:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001168:	893e                	mv	s2,a5
    8000116a:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000116e:	6b85                	lui	s7,0x1
    80001170:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001174:	4605                	li	a2,1
    80001176:	85ca                	mv	a1,s2
    80001178:	8556                	mv	a0,s5
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	e7e080e7          	jalr	-386(ra) # 80000ff8 <walk>
    80001182:	c51d                	beqz	a0,800011b0 <mappages+0x72>
    if(*pte & PTE_V)
    80001184:	611c                	ld	a5,0(a0)
    80001186:	8b85                	andi	a5,a5,1
    80001188:	ef81                	bnez	a5,800011a0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000118a:	80b1                	srli	s1,s1,0xc
    8000118c:	04aa                	slli	s1,s1,0xa
    8000118e:	0164e4b3          	or	s1,s1,s6
    80001192:	0014e493          	ori	s1,s1,1
    80001196:	e104                	sd	s1,0(a0)
    if(a == last)
    80001198:	03390863          	beq	s2,s3,800011c8 <mappages+0x8a>
    a += PGSIZE;
    8000119c:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000119e:	bfc9                	j	80001170 <mappages+0x32>
      panic("remap");
    800011a0:	00007517          	auipc	a0,0x7
    800011a4:	f4050513          	addi	a0,a0,-192 # 800080e0 <digits+0xa0>
    800011a8:	fffff097          	auipc	ra,0xfffff
    800011ac:	3a0080e7          	jalr	928(ra) # 80000548 <panic>
      return -1;
    800011b0:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011b2:	60a6                	ld	ra,72(sp)
    800011b4:	6406                	ld	s0,64(sp)
    800011b6:	74e2                	ld	s1,56(sp)
    800011b8:	7942                	ld	s2,48(sp)
    800011ba:	79a2                	ld	s3,40(sp)
    800011bc:	7a02                	ld	s4,32(sp)
    800011be:	6ae2                	ld	s5,24(sp)
    800011c0:	6b42                	ld	s6,16(sp)
    800011c2:	6ba2                	ld	s7,8(sp)
    800011c4:	6161                	addi	sp,sp,80
    800011c6:	8082                	ret
  return 0;
    800011c8:	4501                	li	a0,0
    800011ca:	b7e5                	j	800011b2 <mappages+0x74>

00000000800011cc <kvmmap>:
{
    800011cc:	1141                	addi	sp,sp,-16
    800011ce:	e406                	sd	ra,8(sp)
    800011d0:	e022                	sd	s0,0(sp)
    800011d2:	0800                	addi	s0,sp,16
    800011d4:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011d6:	86ae                	mv	a3,a1
    800011d8:	85aa                	mv	a1,a0
    800011da:	00008517          	auipc	a0,0x8
    800011de:	e3653503          	ld	a0,-458(a0) # 80009010 <kernel_pagetable>
    800011e2:	00000097          	auipc	ra,0x0
    800011e6:	f5c080e7          	jalr	-164(ra) # 8000113e <mappages>
    800011ea:	e509                	bnez	a0,800011f4 <kvmmap+0x28>
}
    800011ec:	60a2                	ld	ra,8(sp)
    800011ee:	6402                	ld	s0,0(sp)
    800011f0:	0141                	addi	sp,sp,16
    800011f2:	8082                	ret
    panic("kvmmap");
    800011f4:	00007517          	auipc	a0,0x7
    800011f8:	ef450513          	addi	a0,a0,-268 # 800080e8 <digits+0xa8>
    800011fc:	fffff097          	auipc	ra,0xfffff
    80001200:	34c080e7          	jalr	844(ra) # 80000548 <panic>

0000000080001204 <kvminit>:
{
    80001204:	1101                	addi	sp,sp,-32
    80001206:	ec06                	sd	ra,24(sp)
    80001208:	e822                	sd	s0,16(sp)
    8000120a:	e426                	sd	s1,8(sp)
    8000120c:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	912080e7          	jalr	-1774(ra) # 80000b20 <kalloc>
    80001216:	00008797          	auipc	a5,0x8
    8000121a:	dea7bd23          	sd	a0,-518(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000121e:	6605                	lui	a2,0x1
    80001220:	4581                	li	a1,0
    80001222:	00000097          	auipc	ra,0x0
    80001226:	aea080e7          	jalr	-1302(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000122a:	4699                	li	a3,6
    8000122c:	6605                	lui	a2,0x1
    8000122e:	100005b7          	lui	a1,0x10000
    80001232:	10000537          	lui	a0,0x10000
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f96080e7          	jalr	-106(ra) # 800011cc <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000123e:	4699                	li	a3,6
    80001240:	6605                	lui	a2,0x1
    80001242:	100015b7          	lui	a1,0x10001
    80001246:	10001537          	lui	a0,0x10001
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	f82080e7          	jalr	-126(ra) # 800011cc <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001252:	4699                	li	a3,6
    80001254:	6641                	lui	a2,0x10
    80001256:	020005b7          	lui	a1,0x2000
    8000125a:	02000537          	lui	a0,0x2000
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f6e080e7          	jalr	-146(ra) # 800011cc <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001266:	4699                	li	a3,6
    80001268:	00400637          	lui	a2,0x400
    8000126c:	0c0005b7          	lui	a1,0xc000
    80001270:	0c000537          	lui	a0,0xc000
    80001274:	00000097          	auipc	ra,0x0
    80001278:	f58080e7          	jalr	-168(ra) # 800011cc <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000127c:	00007497          	auipc	s1,0x7
    80001280:	d8448493          	addi	s1,s1,-636 # 80008000 <etext>
    80001284:	46a9                	li	a3,10
    80001286:	80007617          	auipc	a2,0x80007
    8000128a:	d7a60613          	addi	a2,a2,-646 # 8000 <_entry-0x7fff8000>
    8000128e:	4585                	li	a1,1
    80001290:	05fe                	slli	a1,a1,0x1f
    80001292:	852e                	mv	a0,a1
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f38080e7          	jalr	-200(ra) # 800011cc <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000129c:	4699                	li	a3,6
    8000129e:	4645                	li	a2,17
    800012a0:	066e                	slli	a2,a2,0x1b
    800012a2:	8e05                	sub	a2,a2,s1
    800012a4:	85a6                	mv	a1,s1
    800012a6:	8526                	mv	a0,s1
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f24080e7          	jalr	-220(ra) # 800011cc <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012b0:	46a9                	li	a3,10
    800012b2:	6605                	lui	a2,0x1
    800012b4:	00006597          	auipc	a1,0x6
    800012b8:	d4c58593          	addi	a1,a1,-692 # 80007000 <_trampoline>
    800012bc:	04000537          	lui	a0,0x4000
    800012c0:	157d                	addi	a0,a0,-1
    800012c2:	0532                	slli	a0,a0,0xc
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f08080e7          	jalr	-248(ra) # 800011cc <kvmmap>
}
    800012cc:	60e2                	ld	ra,24(sp)
    800012ce:	6442                	ld	s0,16(sp)
    800012d0:	64a2                	ld	s1,8(sp)
    800012d2:	6105                	addi	sp,sp,32
    800012d4:	8082                	ret

00000000800012d6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012d6:	715d                	addi	sp,sp,-80
    800012d8:	e486                	sd	ra,72(sp)
    800012da:	e0a2                	sd	s0,64(sp)
    800012dc:	fc26                	sd	s1,56(sp)
    800012de:	f84a                	sd	s2,48(sp)
    800012e0:	f44e                	sd	s3,40(sp)
    800012e2:	f052                	sd	s4,32(sp)
    800012e4:	ec56                	sd	s5,24(sp)
    800012e6:	e85a                	sd	s6,16(sp)
    800012e8:	e45e                	sd	s7,8(sp)
    800012ea:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012ec:	03459793          	slli	a5,a1,0x34
    800012f0:	e795                	bnez	a5,8000131c <uvmunmap+0x46>
    800012f2:	8a2a                	mv	s4,a0
    800012f4:	892e                	mv	s2,a1
    800012f6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f8:	0632                	slli	a2,a2,0xc
    800012fa:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012fe:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001300:	6b05                	lui	s6,0x1
    80001302:	0735e863          	bltu	a1,s3,80001372 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001306:	60a6                	ld	ra,72(sp)
    80001308:	6406                	ld	s0,64(sp)
    8000130a:	74e2                	ld	s1,56(sp)
    8000130c:	7942                	ld	s2,48(sp)
    8000130e:	79a2                	ld	s3,40(sp)
    80001310:	7a02                	ld	s4,32(sp)
    80001312:	6ae2                	ld	s5,24(sp)
    80001314:	6b42                	ld	s6,16(sp)
    80001316:	6ba2                	ld	s7,8(sp)
    80001318:	6161                	addi	sp,sp,80
    8000131a:	8082                	ret
    panic("uvmunmap: not aligned");
    8000131c:	00007517          	auipc	a0,0x7
    80001320:	dd450513          	addi	a0,a0,-556 # 800080f0 <digits+0xb0>
    80001324:	fffff097          	auipc	ra,0xfffff
    80001328:	224080e7          	jalr	548(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    8000132c:	00007517          	auipc	a0,0x7
    80001330:	ddc50513          	addi	a0,a0,-548 # 80008108 <digits+0xc8>
    80001334:	fffff097          	auipc	ra,0xfffff
    80001338:	214080e7          	jalr	532(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    8000133c:	00007517          	auipc	a0,0x7
    80001340:	ddc50513          	addi	a0,a0,-548 # 80008118 <digits+0xd8>
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	204080e7          	jalr	516(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    8000134c:	00007517          	auipc	a0,0x7
    80001350:	de450513          	addi	a0,a0,-540 # 80008130 <digits+0xf0>
    80001354:	fffff097          	auipc	ra,0xfffff
    80001358:	1f4080e7          	jalr	500(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    8000135c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000135e:	0532                	slli	a0,a0,0xc
    80001360:	fffff097          	auipc	ra,0xfffff
    80001364:	6c4080e7          	jalr	1732(ra) # 80000a24 <kfree>
    *pte = 0;
    80001368:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000136c:	995a                	add	s2,s2,s6
    8000136e:	f9397ce3          	bgeu	s2,s3,80001306 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001372:	4601                	li	a2,0
    80001374:	85ca                	mv	a1,s2
    80001376:	8552                	mv	a0,s4
    80001378:	00000097          	auipc	ra,0x0
    8000137c:	c80080e7          	jalr	-896(ra) # 80000ff8 <walk>
    80001380:	84aa                	mv	s1,a0
    80001382:	d54d                	beqz	a0,8000132c <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001384:	6108                	ld	a0,0(a0)
    80001386:	00157793          	andi	a5,a0,1
    8000138a:	dbcd                	beqz	a5,8000133c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000138c:	3ff57793          	andi	a5,a0,1023
    80001390:	fb778ee3          	beq	a5,s7,8000134c <uvmunmap+0x76>
    if(do_free){
    80001394:	fc0a8ae3          	beqz	s5,80001368 <uvmunmap+0x92>
    80001398:	b7d1                	j	8000135c <uvmunmap+0x86>

000000008000139a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000139a:	1101                	addi	sp,sp,-32
    8000139c:	ec06                	sd	ra,24(sp)
    8000139e:	e822                	sd	s0,16(sp)
    800013a0:	e426                	sd	s1,8(sp)
    800013a2:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013a4:	fffff097          	auipc	ra,0xfffff
    800013a8:	77c080e7          	jalr	1916(ra) # 80000b20 <kalloc>
    800013ac:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013ae:	c519                	beqz	a0,800013bc <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013b0:	6605                	lui	a2,0x1
    800013b2:	4581                	li	a1,0
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	958080e7          	jalr	-1704(ra) # 80000d0c <memset>
  return pagetable;
}
    800013bc:	8526                	mv	a0,s1
    800013be:	60e2                	ld	ra,24(sp)
    800013c0:	6442                	ld	s0,16(sp)
    800013c2:	64a2                	ld	s1,8(sp)
    800013c4:	6105                	addi	sp,sp,32
    800013c6:	8082                	ret

00000000800013c8 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013c8:	7179                	addi	sp,sp,-48
    800013ca:	f406                	sd	ra,40(sp)
    800013cc:	f022                	sd	s0,32(sp)
    800013ce:	ec26                	sd	s1,24(sp)
    800013d0:	e84a                	sd	s2,16(sp)
    800013d2:	e44e                	sd	s3,8(sp)
    800013d4:	e052                	sd	s4,0(sp)
    800013d6:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013d8:	6785                	lui	a5,0x1
    800013da:	04f67863          	bgeu	a2,a5,8000142a <uvminit+0x62>
    800013de:	8a2a                	mv	s4,a0
    800013e0:	89ae                	mv	s3,a1
    800013e2:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013e4:	fffff097          	auipc	ra,0xfffff
    800013e8:	73c080e7          	jalr	1852(ra) # 80000b20 <kalloc>
    800013ec:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013ee:	6605                	lui	a2,0x1
    800013f0:	4581                	li	a1,0
    800013f2:	00000097          	auipc	ra,0x0
    800013f6:	91a080e7          	jalr	-1766(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013fa:	4779                	li	a4,30
    800013fc:	86ca                	mv	a3,s2
    800013fe:	6605                	lui	a2,0x1
    80001400:	4581                	li	a1,0
    80001402:	8552                	mv	a0,s4
    80001404:	00000097          	auipc	ra,0x0
    80001408:	d3a080e7          	jalr	-710(ra) # 8000113e <mappages>
  memmove(mem, src, sz);
    8000140c:	8626                	mv	a2,s1
    8000140e:	85ce                	mv	a1,s3
    80001410:	854a                	mv	a0,s2
    80001412:	00000097          	auipc	ra,0x0
    80001416:	95a080e7          	jalr	-1702(ra) # 80000d6c <memmove>
}
    8000141a:	70a2                	ld	ra,40(sp)
    8000141c:	7402                	ld	s0,32(sp)
    8000141e:	64e2                	ld	s1,24(sp)
    80001420:	6942                	ld	s2,16(sp)
    80001422:	69a2                	ld	s3,8(sp)
    80001424:	6a02                	ld	s4,0(sp)
    80001426:	6145                	addi	sp,sp,48
    80001428:	8082                	ret
    panic("inituvm: more than a page");
    8000142a:	00007517          	auipc	a0,0x7
    8000142e:	d1e50513          	addi	a0,a0,-738 # 80008148 <digits+0x108>
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	116080e7          	jalr	278(ra) # 80000548 <panic>

000000008000143a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000143a:	1101                	addi	sp,sp,-32
    8000143c:	ec06                	sd	ra,24(sp)
    8000143e:	e822                	sd	s0,16(sp)
    80001440:	e426                	sd	s1,8(sp)
    80001442:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001444:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001446:	00b67d63          	bgeu	a2,a1,80001460 <uvmdealloc+0x26>
    8000144a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000144c:	6785                	lui	a5,0x1
    8000144e:	17fd                	addi	a5,a5,-1
    80001450:	00f60733          	add	a4,a2,a5
    80001454:	767d                	lui	a2,0xfffff
    80001456:	8f71                	and	a4,a4,a2
    80001458:	97ae                	add	a5,a5,a1
    8000145a:	8ff1                	and	a5,a5,a2
    8000145c:	00f76863          	bltu	a4,a5,8000146c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001460:	8526                	mv	a0,s1
    80001462:	60e2                	ld	ra,24(sp)
    80001464:	6442                	ld	s0,16(sp)
    80001466:	64a2                	ld	s1,8(sp)
    80001468:	6105                	addi	sp,sp,32
    8000146a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000146c:	8f99                	sub	a5,a5,a4
    8000146e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001470:	4685                	li	a3,1
    80001472:	0007861b          	sext.w	a2,a5
    80001476:	85ba                	mv	a1,a4
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	e5e080e7          	jalr	-418(ra) # 800012d6 <uvmunmap>
    80001480:	b7c5                	j	80001460 <uvmdealloc+0x26>

0000000080001482 <uvmalloc>:
  if(newsz < oldsz)
    80001482:	0ab66163          	bltu	a2,a1,80001524 <uvmalloc+0xa2>
{
    80001486:	7139                	addi	sp,sp,-64
    80001488:	fc06                	sd	ra,56(sp)
    8000148a:	f822                	sd	s0,48(sp)
    8000148c:	f426                	sd	s1,40(sp)
    8000148e:	f04a                	sd	s2,32(sp)
    80001490:	ec4e                	sd	s3,24(sp)
    80001492:	e852                	sd	s4,16(sp)
    80001494:	e456                	sd	s5,8(sp)
    80001496:	0080                	addi	s0,sp,64
    80001498:	8aaa                	mv	s5,a0
    8000149a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000149c:	6985                	lui	s3,0x1
    8000149e:	19fd                	addi	s3,s3,-1
    800014a0:	95ce                	add	a1,a1,s3
    800014a2:	79fd                	lui	s3,0xfffff
    800014a4:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014a8:	08c9f063          	bgeu	s3,a2,80001528 <uvmalloc+0xa6>
    800014ac:	894e                	mv	s2,s3
    mem = kalloc();
    800014ae:	fffff097          	auipc	ra,0xfffff
    800014b2:	672080e7          	jalr	1650(ra) # 80000b20 <kalloc>
    800014b6:	84aa                	mv	s1,a0
    if(mem == 0){
    800014b8:	c51d                	beqz	a0,800014e6 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014ba:	6605                	lui	a2,0x1
    800014bc:	4581                	li	a1,0
    800014be:	00000097          	auipc	ra,0x0
    800014c2:	84e080e7          	jalr	-1970(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014c6:	4779                	li	a4,30
    800014c8:	86a6                	mv	a3,s1
    800014ca:	6605                	lui	a2,0x1
    800014cc:	85ca                	mv	a1,s2
    800014ce:	8556                	mv	a0,s5
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	c6e080e7          	jalr	-914(ra) # 8000113e <mappages>
    800014d8:	e905                	bnez	a0,80001508 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014da:	6785                	lui	a5,0x1
    800014dc:	993e                	add	s2,s2,a5
    800014de:	fd4968e3          	bltu	s2,s4,800014ae <uvmalloc+0x2c>
  return newsz;
    800014e2:	8552                	mv	a0,s4
    800014e4:	a809                	j	800014f6 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014e6:	864e                	mv	a2,s3
    800014e8:	85ca                	mv	a1,s2
    800014ea:	8556                	mv	a0,s5
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	f4e080e7          	jalr	-178(ra) # 8000143a <uvmdealloc>
      return 0;
    800014f4:	4501                	li	a0,0
}
    800014f6:	70e2                	ld	ra,56(sp)
    800014f8:	7442                	ld	s0,48(sp)
    800014fa:	74a2                	ld	s1,40(sp)
    800014fc:	7902                	ld	s2,32(sp)
    800014fe:	69e2                	ld	s3,24(sp)
    80001500:	6a42                	ld	s4,16(sp)
    80001502:	6aa2                	ld	s5,8(sp)
    80001504:	6121                	addi	sp,sp,64
    80001506:	8082                	ret
      kfree(mem);
    80001508:	8526                	mv	a0,s1
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	51a080e7          	jalr	1306(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001512:	864e                	mv	a2,s3
    80001514:	85ca                	mv	a1,s2
    80001516:	8556                	mv	a0,s5
    80001518:	00000097          	auipc	ra,0x0
    8000151c:	f22080e7          	jalr	-222(ra) # 8000143a <uvmdealloc>
      return 0;
    80001520:	4501                	li	a0,0
    80001522:	bfd1                	j	800014f6 <uvmalloc+0x74>
    return oldsz;
    80001524:	852e                	mv	a0,a1
}
    80001526:	8082                	ret
  return newsz;
    80001528:	8532                	mv	a0,a2
    8000152a:	b7f1                	j	800014f6 <uvmalloc+0x74>

000000008000152c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000152c:	7179                	addi	sp,sp,-48
    8000152e:	f406                	sd	ra,40(sp)
    80001530:	f022                	sd	s0,32(sp)
    80001532:	ec26                	sd	s1,24(sp)
    80001534:	e84a                	sd	s2,16(sp)
    80001536:	e44e                	sd	s3,8(sp)
    80001538:	e052                	sd	s4,0(sp)
    8000153a:	1800                	addi	s0,sp,48
    8000153c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000153e:	84aa                	mv	s1,a0
    80001540:	6905                	lui	s2,0x1
    80001542:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001544:	4985                	li	s3,1
    80001546:	a821                	j	8000155e <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001548:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000154a:	0532                	slli	a0,a0,0xc
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	fe0080e7          	jalr	-32(ra) # 8000152c <freewalk>
      pagetable[i] = 0;
    80001554:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001558:	04a1                	addi	s1,s1,8
    8000155a:	03248163          	beq	s1,s2,8000157c <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000155e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001560:	00f57793          	andi	a5,a0,15
    80001564:	ff3782e3          	beq	a5,s3,80001548 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001568:	8905                	andi	a0,a0,1
    8000156a:	d57d                	beqz	a0,80001558 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000156c:	00007517          	auipc	a0,0x7
    80001570:	bfc50513          	addi	a0,a0,-1028 # 80008168 <digits+0x128>
    80001574:	fffff097          	auipc	ra,0xfffff
    80001578:	fd4080e7          	jalr	-44(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    8000157c:	8552                	mv	a0,s4
    8000157e:	fffff097          	auipc	ra,0xfffff
    80001582:	4a6080e7          	jalr	1190(ra) # 80000a24 <kfree>
}
    80001586:	70a2                	ld	ra,40(sp)
    80001588:	7402                	ld	s0,32(sp)
    8000158a:	64e2                	ld	s1,24(sp)
    8000158c:	6942                	ld	s2,16(sp)
    8000158e:	69a2                	ld	s3,8(sp)
    80001590:	6a02                	ld	s4,0(sp)
    80001592:	6145                	addi	sp,sp,48
    80001594:	8082                	ret

0000000080001596 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001596:	1101                	addi	sp,sp,-32
    80001598:	ec06                	sd	ra,24(sp)
    8000159a:	e822                	sd	s0,16(sp)
    8000159c:	e426                	sd	s1,8(sp)
    8000159e:	1000                	addi	s0,sp,32
    800015a0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015a2:	e999                	bnez	a1,800015b8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015a4:	8526                	mv	a0,s1
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	f86080e7          	jalr	-122(ra) # 8000152c <freewalk>
}
    800015ae:	60e2                	ld	ra,24(sp)
    800015b0:	6442                	ld	s0,16(sp)
    800015b2:	64a2                	ld	s1,8(sp)
    800015b4:	6105                	addi	sp,sp,32
    800015b6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	167d                	addi	a2,a2,-1
    800015bc:	962e                	add	a2,a2,a1
    800015be:	4685                	li	a3,1
    800015c0:	8231                	srli	a2,a2,0xc
    800015c2:	4581                	li	a1,0
    800015c4:	00000097          	auipc	ra,0x0
    800015c8:	d12080e7          	jalr	-750(ra) # 800012d6 <uvmunmap>
    800015cc:	bfe1                	j	800015a4 <uvmfree+0xe>

00000000800015ce <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015ce:	c679                	beqz	a2,8000169c <uvmcopy+0xce>
{
    800015d0:	715d                	addi	sp,sp,-80
    800015d2:	e486                	sd	ra,72(sp)
    800015d4:	e0a2                	sd	s0,64(sp)
    800015d6:	fc26                	sd	s1,56(sp)
    800015d8:	f84a                	sd	s2,48(sp)
    800015da:	f44e                	sd	s3,40(sp)
    800015dc:	f052                	sd	s4,32(sp)
    800015de:	ec56                	sd	s5,24(sp)
    800015e0:	e85a                	sd	s6,16(sp)
    800015e2:	e45e                	sd	s7,8(sp)
    800015e4:	0880                	addi	s0,sp,80
    800015e6:	8b2a                	mv	s6,a0
    800015e8:	8aae                	mv	s5,a1
    800015ea:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015ec:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015ee:	4601                	li	a2,0
    800015f0:	85ce                	mv	a1,s3
    800015f2:	855a                	mv	a0,s6
    800015f4:	00000097          	auipc	ra,0x0
    800015f8:	a04080e7          	jalr	-1532(ra) # 80000ff8 <walk>
    800015fc:	c531                	beqz	a0,80001648 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015fe:	6118                	ld	a4,0(a0)
    80001600:	00177793          	andi	a5,a4,1
    80001604:	cbb1                	beqz	a5,80001658 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001606:	00a75593          	srli	a1,a4,0xa
    8000160a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000160e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	50e080e7          	jalr	1294(ra) # 80000b20 <kalloc>
    8000161a:	892a                	mv	s2,a0
    8000161c:	c939                	beqz	a0,80001672 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000161e:	6605                	lui	a2,0x1
    80001620:	85de                	mv	a1,s7
    80001622:	fffff097          	auipc	ra,0xfffff
    80001626:	74a080e7          	jalr	1866(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000162a:	8726                	mv	a4,s1
    8000162c:	86ca                	mv	a3,s2
    8000162e:	6605                	lui	a2,0x1
    80001630:	85ce                	mv	a1,s3
    80001632:	8556                	mv	a0,s5
    80001634:	00000097          	auipc	ra,0x0
    80001638:	b0a080e7          	jalr	-1270(ra) # 8000113e <mappages>
    8000163c:	e515                	bnez	a0,80001668 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000163e:	6785                	lui	a5,0x1
    80001640:	99be                	add	s3,s3,a5
    80001642:	fb49e6e3          	bltu	s3,s4,800015ee <uvmcopy+0x20>
    80001646:	a081                	j	80001686 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001648:	00007517          	auipc	a0,0x7
    8000164c:	b3050513          	addi	a0,a0,-1232 # 80008178 <digits+0x138>
    80001650:	fffff097          	auipc	ra,0xfffff
    80001654:	ef8080e7          	jalr	-264(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b4050513          	addi	a0,a0,-1216 # 80008198 <digits+0x158>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ee8080e7          	jalr	-280(ra) # 80000548 <panic>
      kfree(mem);
    80001668:	854a                	mv	a0,s2
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	3ba080e7          	jalr	954(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001672:	4685                	li	a3,1
    80001674:	00c9d613          	srli	a2,s3,0xc
    80001678:	4581                	li	a1,0
    8000167a:	8556                	mv	a0,s5
    8000167c:	00000097          	auipc	ra,0x0
    80001680:	c5a080e7          	jalr	-934(ra) # 800012d6 <uvmunmap>
  return -1;
    80001684:	557d                	li	a0,-1
}
    80001686:	60a6                	ld	ra,72(sp)
    80001688:	6406                	ld	s0,64(sp)
    8000168a:	74e2                	ld	s1,56(sp)
    8000168c:	7942                	ld	s2,48(sp)
    8000168e:	79a2                	ld	s3,40(sp)
    80001690:	7a02                	ld	s4,32(sp)
    80001692:	6ae2                	ld	s5,24(sp)
    80001694:	6b42                	ld	s6,16(sp)
    80001696:	6ba2                	ld	s7,8(sp)
    80001698:	6161                	addi	sp,sp,80
    8000169a:	8082                	ret
  return 0;
    8000169c:	4501                	li	a0,0
}
    8000169e:	8082                	ret

00000000800016a0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016a0:	1141                	addi	sp,sp,-16
    800016a2:	e406                	sd	ra,8(sp)
    800016a4:	e022                	sd	s0,0(sp)
    800016a6:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016a8:	4601                	li	a2,0
    800016aa:	00000097          	auipc	ra,0x0
    800016ae:	94e080e7          	jalr	-1714(ra) # 80000ff8 <walk>
  if(pte == 0)
    800016b2:	c901                	beqz	a0,800016c2 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016b4:	611c                	ld	a5,0(a0)
    800016b6:	9bbd                	andi	a5,a5,-17
    800016b8:	e11c                	sd	a5,0(a0)
}
    800016ba:	60a2                	ld	ra,8(sp)
    800016bc:	6402                	ld	s0,0(sp)
    800016be:	0141                	addi	sp,sp,16
    800016c0:	8082                	ret
    panic("uvmclear");
    800016c2:	00007517          	auipc	a0,0x7
    800016c6:	af650513          	addi	a0,a0,-1290 # 800081b8 <digits+0x178>
    800016ca:	fffff097          	auipc	ra,0xfffff
    800016ce:	e7e080e7          	jalr	-386(ra) # 80000548 <panic>

00000000800016d2 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016d2:	c6bd                	beqz	a3,80001740 <copyout+0x6e>
{
    800016d4:	715d                	addi	sp,sp,-80
    800016d6:	e486                	sd	ra,72(sp)
    800016d8:	e0a2                	sd	s0,64(sp)
    800016da:	fc26                	sd	s1,56(sp)
    800016dc:	f84a                	sd	s2,48(sp)
    800016de:	f44e                	sd	s3,40(sp)
    800016e0:	f052                	sd	s4,32(sp)
    800016e2:	ec56                	sd	s5,24(sp)
    800016e4:	e85a                	sd	s6,16(sp)
    800016e6:	e45e                	sd	s7,8(sp)
    800016e8:	e062                	sd	s8,0(sp)
    800016ea:	0880                	addi	s0,sp,80
    800016ec:	8b2a                	mv	s6,a0
    800016ee:	8c2e                	mv	s8,a1
    800016f0:	8a32                	mv	s4,a2
    800016f2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016f4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016f6:	6a85                	lui	s5,0x1
    800016f8:	a015                	j	8000171c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016fa:	9562                	add	a0,a0,s8
    800016fc:	0004861b          	sext.w	a2,s1
    80001700:	85d2                	mv	a1,s4
    80001702:	41250533          	sub	a0,a0,s2
    80001706:	fffff097          	auipc	ra,0xfffff
    8000170a:	666080e7          	jalr	1638(ra) # 80000d6c <memmove>

    len -= n;
    8000170e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001712:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001714:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001718:	02098263          	beqz	s3,8000173c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000171c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001720:	85ca                	mv	a1,s2
    80001722:	855a                	mv	a0,s6
    80001724:	00000097          	auipc	ra,0x0
    80001728:	97a080e7          	jalr	-1670(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    8000172c:	cd01                	beqz	a0,80001744 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000172e:	418904b3          	sub	s1,s2,s8
    80001732:	94d6                	add	s1,s1,s5
    if(n > len)
    80001734:	fc99f3e3          	bgeu	s3,s1,800016fa <copyout+0x28>
    80001738:	84ce                	mv	s1,s3
    8000173a:	b7c1                	j	800016fa <copyout+0x28>
  }
  return 0;
    8000173c:	4501                	li	a0,0
    8000173e:	a021                	j	80001746 <copyout+0x74>
    80001740:	4501                	li	a0,0
}
    80001742:	8082                	ret
      return -1;
    80001744:	557d                	li	a0,-1
}
    80001746:	60a6                	ld	ra,72(sp)
    80001748:	6406                	ld	s0,64(sp)
    8000174a:	74e2                	ld	s1,56(sp)
    8000174c:	7942                	ld	s2,48(sp)
    8000174e:	79a2                	ld	s3,40(sp)
    80001750:	7a02                	ld	s4,32(sp)
    80001752:	6ae2                	ld	s5,24(sp)
    80001754:	6b42                	ld	s6,16(sp)
    80001756:	6ba2                	ld	s7,8(sp)
    80001758:	6c02                	ld	s8,0(sp)
    8000175a:	6161                	addi	sp,sp,80
    8000175c:	8082                	ret

000000008000175e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000175e:	c6bd                	beqz	a3,800017cc <copyin+0x6e>
{
    80001760:	715d                	addi	sp,sp,-80
    80001762:	e486                	sd	ra,72(sp)
    80001764:	e0a2                	sd	s0,64(sp)
    80001766:	fc26                	sd	s1,56(sp)
    80001768:	f84a                	sd	s2,48(sp)
    8000176a:	f44e                	sd	s3,40(sp)
    8000176c:	f052                	sd	s4,32(sp)
    8000176e:	ec56                	sd	s5,24(sp)
    80001770:	e85a                	sd	s6,16(sp)
    80001772:	e45e                	sd	s7,8(sp)
    80001774:	e062                	sd	s8,0(sp)
    80001776:	0880                	addi	s0,sp,80
    80001778:	8b2a                	mv	s6,a0
    8000177a:	8a2e                	mv	s4,a1
    8000177c:	8c32                	mv	s8,a2
    8000177e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001780:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001782:	6a85                	lui	s5,0x1
    80001784:	a015                	j	800017a8 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001786:	9562                	add	a0,a0,s8
    80001788:	0004861b          	sext.w	a2,s1
    8000178c:	412505b3          	sub	a1,a0,s2
    80001790:	8552                	mv	a0,s4
    80001792:	fffff097          	auipc	ra,0xfffff
    80001796:	5da080e7          	jalr	1498(ra) # 80000d6c <memmove>

    len -= n;
    8000179a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000179e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017a0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017a4:	02098263          	beqz	s3,800017c8 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017a8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017ac:	85ca                	mv	a1,s2
    800017ae:	855a                	mv	a0,s6
    800017b0:	00000097          	auipc	ra,0x0
    800017b4:	8ee080e7          	jalr	-1810(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    800017b8:	cd01                	beqz	a0,800017d0 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800017ba:	418904b3          	sub	s1,s2,s8
    800017be:	94d6                	add	s1,s1,s5
    if(n > len)
    800017c0:	fc99f3e3          	bgeu	s3,s1,80001786 <copyin+0x28>
    800017c4:	84ce                	mv	s1,s3
    800017c6:	b7c1                	j	80001786 <copyin+0x28>
  }
  return 0;
    800017c8:	4501                	li	a0,0
    800017ca:	a021                	j	800017d2 <copyin+0x74>
    800017cc:	4501                	li	a0,0
}
    800017ce:	8082                	ret
      return -1;
    800017d0:	557d                	li	a0,-1
}
    800017d2:	60a6                	ld	ra,72(sp)
    800017d4:	6406                	ld	s0,64(sp)
    800017d6:	74e2                	ld	s1,56(sp)
    800017d8:	7942                	ld	s2,48(sp)
    800017da:	79a2                	ld	s3,40(sp)
    800017dc:	7a02                	ld	s4,32(sp)
    800017de:	6ae2                	ld	s5,24(sp)
    800017e0:	6b42                	ld	s6,16(sp)
    800017e2:	6ba2                	ld	s7,8(sp)
    800017e4:	6c02                	ld	s8,0(sp)
    800017e6:	6161                	addi	sp,sp,80
    800017e8:	8082                	ret

00000000800017ea <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017ea:	c6c5                	beqz	a3,80001892 <copyinstr+0xa8>
{
    800017ec:	715d                	addi	sp,sp,-80
    800017ee:	e486                	sd	ra,72(sp)
    800017f0:	e0a2                	sd	s0,64(sp)
    800017f2:	fc26                	sd	s1,56(sp)
    800017f4:	f84a                	sd	s2,48(sp)
    800017f6:	f44e                	sd	s3,40(sp)
    800017f8:	f052                	sd	s4,32(sp)
    800017fa:	ec56                	sd	s5,24(sp)
    800017fc:	e85a                	sd	s6,16(sp)
    800017fe:	e45e                	sd	s7,8(sp)
    80001800:	0880                	addi	s0,sp,80
    80001802:	8a2a                	mv	s4,a0
    80001804:	8b2e                	mv	s6,a1
    80001806:	8bb2                	mv	s7,a2
    80001808:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000180a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000180c:	6985                	lui	s3,0x1
    8000180e:	a035                	j	8000183a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001810:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001814:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001816:	0017b793          	seqz	a5,a5
    8000181a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000181e:	60a6                	ld	ra,72(sp)
    80001820:	6406                	ld	s0,64(sp)
    80001822:	74e2                	ld	s1,56(sp)
    80001824:	7942                	ld	s2,48(sp)
    80001826:	79a2                	ld	s3,40(sp)
    80001828:	7a02                	ld	s4,32(sp)
    8000182a:	6ae2                	ld	s5,24(sp)
    8000182c:	6b42                	ld	s6,16(sp)
    8000182e:	6ba2                	ld	s7,8(sp)
    80001830:	6161                	addi	sp,sp,80
    80001832:	8082                	ret
    srcva = va0 + PGSIZE;
    80001834:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001838:	c8a9                	beqz	s1,8000188a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000183a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000183e:	85ca                	mv	a1,s2
    80001840:	8552                	mv	a0,s4
    80001842:	00000097          	auipc	ra,0x0
    80001846:	85c080e7          	jalr	-1956(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    8000184a:	c131                	beqz	a0,8000188e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000184c:	41790833          	sub	a6,s2,s7
    80001850:	984e                	add	a6,a6,s3
    if(n > max)
    80001852:	0104f363          	bgeu	s1,a6,80001858 <copyinstr+0x6e>
    80001856:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001858:	955e                	add	a0,a0,s7
    8000185a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000185e:	fc080be3          	beqz	a6,80001834 <copyinstr+0x4a>
    80001862:	985a                	add	a6,a6,s6
    80001864:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001866:	41650633          	sub	a2,a0,s6
    8000186a:	14fd                	addi	s1,s1,-1
    8000186c:	9b26                	add	s6,s6,s1
    8000186e:	00f60733          	add	a4,a2,a5
    80001872:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001876:	df49                	beqz	a4,80001810 <copyinstr+0x26>
        *dst = *p;
    80001878:	00e78023          	sb	a4,0(a5)
      --max;
    8000187c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001880:	0785                	addi	a5,a5,1
    while(n > 0){
    80001882:	ff0796e3          	bne	a5,a6,8000186e <copyinstr+0x84>
      dst++;
    80001886:	8b42                	mv	s6,a6
    80001888:	b775                	j	80001834 <copyinstr+0x4a>
    8000188a:	4781                	li	a5,0
    8000188c:	b769                	j	80001816 <copyinstr+0x2c>
      return -1;
    8000188e:	557d                	li	a0,-1
    80001890:	b779                	j	8000181e <copyinstr+0x34>
  int got_null = 0;
    80001892:	4781                	li	a5,0
  if(got_null){
    80001894:	0017b793          	seqz	a5,a5
    80001898:	40f00533          	neg	a0,a5
}
    8000189c:	8082                	ret

000000008000189e <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    8000189e:	1101                	addi	sp,sp,-32
    800018a0:	ec06                	sd	ra,24(sp)
    800018a2:	e822                	sd	s0,16(sp)
    800018a4:	e426                	sd	s1,8(sp)
    800018a6:	1000                	addi	s0,sp,32
    800018a8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018aa:	fffff097          	auipc	ra,0xfffff
    800018ae:	2ec080e7          	jalr	748(ra) # 80000b96 <holding>
    800018b2:	c909                	beqz	a0,800018c4 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018b4:	749c                	ld	a5,40(s1)
    800018b6:	00978f63          	beq	a5,s1,800018d4 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800018ba:	60e2                	ld	ra,24(sp)
    800018bc:	6442                	ld	s0,16(sp)
    800018be:	64a2                	ld	s1,8(sp)
    800018c0:	6105                	addi	sp,sp,32
    800018c2:	8082                	ret
    panic("wakeup1");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	90450513          	addi	a0,a0,-1788 # 800081c8 <digits+0x188>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c7c080e7          	jalr	-900(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800018d4:	4c98                	lw	a4,24(s1)
    800018d6:	4785                	li	a5,1
    800018d8:	fef711e3          	bne	a4,a5,800018ba <wakeup1+0x1c>
    p->state = RUNNABLE;
    800018dc:	4789                	li	a5,2
    800018de:	cc9c                	sw	a5,24(s1)
}
    800018e0:	bfe9                	j	800018ba <wakeup1+0x1c>

00000000800018e2 <procinit>:
{
    800018e2:	715d                	addi	sp,sp,-80
    800018e4:	e486                	sd	ra,72(sp)
    800018e6:	e0a2                	sd	s0,64(sp)
    800018e8:	fc26                	sd	s1,56(sp)
    800018ea:	f84a                	sd	s2,48(sp)
    800018ec:	f44e                	sd	s3,40(sp)
    800018ee:	f052                	sd	s4,32(sp)
    800018f0:	ec56                	sd	s5,24(sp)
    800018f2:	e85a                	sd	s6,16(sp)
    800018f4:	e45e                	sd	s7,8(sp)
    800018f6:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8d858593          	addi	a1,a1,-1832 # 800081d0 <digits+0x190>
    80001900:	00010517          	auipc	a0,0x10
    80001904:	05050513          	addi	a0,a0,80 # 80011950 <pid_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	278080e7          	jalr	632(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	00010917          	auipc	s2,0x10
    80001914:	45890913          	addi	s2,s2,1112 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b97          	auipc	s7,0x7
    8000191c:	8c0b8b93          	addi	s7,s7,-1856 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001920:	8b4a                	mv	s6,s2
    80001922:	00006a97          	auipc	s5,0x6
    80001926:	6dea8a93          	addi	s5,s5,1758 # 80008000 <etext>
    8000192a:	040009b7          	lui	s3,0x4000
    8000192e:	19fd                	addi	s3,s3,-1
    80001930:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00016a17          	auipc	s4,0x16
    80001936:	e36a0a13          	addi	s4,s4,-458 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85de                	mv	a1,s7
    8000193c:	854a                	mv	a0,s2
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	242080e7          	jalr	578(ra) # 80000b80 <initlock>
      char *pa = kalloc();
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	1da080e7          	jalr	474(ra) # 80000b20 <kalloc>
    8000194e:	85aa                	mv	a1,a0
      if(pa == 0)
    80001950:	c929                	beqz	a0,800019a2 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001952:	416904b3          	sub	s1,s2,s6
    80001956:	848d                	srai	s1,s1,0x3
    80001958:	000ab783          	ld	a5,0(s5)
    8000195c:	02f484b3          	mul	s1,s1,a5
    80001960:	2485                	addiw	s1,s1,1
    80001962:	00d4949b          	slliw	s1,s1,0xd
    80001966:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000196a:	4699                	li	a3,6
    8000196c:	6605                	lui	a2,0x1
    8000196e:	8526                	mv	a0,s1
    80001970:	00000097          	auipc	ra,0x0
    80001974:	85c080e7          	jalr	-1956(ra) # 800011cc <kvmmap>
      p->kstack = va;
    80001978:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197c:	16890913          	addi	s2,s2,360
    80001980:	fb491de3          	bne	s2,s4,8000193a <procinit+0x58>
  kvminithart();
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	650080e7          	jalr	1616(ra) # 80000fd4 <kvminithart>
}
    8000198c:	60a6                	ld	ra,72(sp)
    8000198e:	6406                	ld	s0,64(sp)
    80001990:	74e2                	ld	s1,56(sp)
    80001992:	7942                	ld	s2,48(sp)
    80001994:	79a2                	ld	s3,40(sp)
    80001996:	7a02                	ld	s4,32(sp)
    80001998:	6ae2                	ld	s5,24(sp)
    8000199a:	6b42                	ld	s6,16(sp)
    8000199c:	6ba2                	ld	s7,8(sp)
    8000199e:	6161                	addi	sp,sp,80
    800019a0:	8082                	ret
        panic("kalloc");
    800019a2:	00007517          	auipc	a0,0x7
    800019a6:	83e50513          	addi	a0,a0,-1986 # 800081e0 <digits+0x1a0>
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	b9e080e7          	jalr	-1122(ra) # 80000548 <panic>

00000000800019b2 <cpuid>:
{
    800019b2:	1141                	addi	sp,sp,-16
    800019b4:	e422                	sd	s0,8(sp)
    800019b6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019b8:	8512                	mv	a0,tp
}
    800019ba:	2501                	sext.w	a0,a0
    800019bc:	6422                	ld	s0,8(sp)
    800019be:	0141                	addi	sp,sp,16
    800019c0:	8082                	ret

00000000800019c2 <mycpu>:
mycpu(void) {
    800019c2:	1141                	addi	sp,sp,-16
    800019c4:	e422                	sd	s0,8(sp)
    800019c6:	0800                	addi	s0,sp,16
    800019c8:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019ca:	2781                	sext.w	a5,a5
    800019cc:	079e                	slli	a5,a5,0x7
}
    800019ce:	00010517          	auipc	a0,0x10
    800019d2:	f9a50513          	addi	a0,a0,-102 # 80011968 <cpus>
    800019d6:	953e                	add	a0,a0,a5
    800019d8:	6422                	ld	s0,8(sp)
    800019da:	0141                	addi	sp,sp,16
    800019dc:	8082                	ret

00000000800019de <myproc>:
myproc(void) {
    800019de:	1101                	addi	sp,sp,-32
    800019e0:	ec06                	sd	ra,24(sp)
    800019e2:	e822                	sd	s0,16(sp)
    800019e4:	e426                	sd	s1,8(sp)
    800019e6:	1000                	addi	s0,sp,32
  push_off();
    800019e8:	fffff097          	auipc	ra,0xfffff
    800019ec:	1dc080e7          	jalr	476(ra) # 80000bc4 <push_off>
    800019f0:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    800019f2:	2781                	sext.w	a5,a5
    800019f4:	079e                	slli	a5,a5,0x7
    800019f6:	00010717          	auipc	a4,0x10
    800019fa:	f5a70713          	addi	a4,a4,-166 # 80011950 <pid_lock>
    800019fe:	97ba                	add	a5,a5,a4
    80001a00:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a02:	fffff097          	auipc	ra,0xfffff
    80001a06:	262080e7          	jalr	610(ra) # 80000c64 <pop_off>
}
    80001a0a:	8526                	mv	a0,s1
    80001a0c:	60e2                	ld	ra,24(sp)
    80001a0e:	6442                	ld	s0,16(sp)
    80001a10:	64a2                	ld	s1,8(sp)
    80001a12:	6105                	addi	sp,sp,32
    80001a14:	8082                	ret

0000000080001a16 <forkret>:
{
    80001a16:	1141                	addi	sp,sp,-16
    80001a18:	e406                	sd	ra,8(sp)
    80001a1a:	e022                	sd	s0,0(sp)
    80001a1c:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a1e:	00000097          	auipc	ra,0x0
    80001a22:	fc0080e7          	jalr	-64(ra) # 800019de <myproc>
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	29e080e7          	jalr	670(ra) # 80000cc4 <release>
  if (first) {
    80001a2e:	00007797          	auipc	a5,0x7
    80001a32:	f627a783          	lw	a5,-158(a5) # 80008990 <first.1665>
    80001a36:	eb89                	bnez	a5,80001a48 <forkret+0x32>
  usertrapret();
    80001a38:	00001097          	auipc	ra,0x1
    80001a3c:	c60080e7          	jalr	-928(ra) # 80002698 <usertrapret>
}
    80001a40:	60a2                	ld	ra,8(sp)
    80001a42:	6402                	ld	s0,0(sp)
    80001a44:	0141                	addi	sp,sp,16
    80001a46:	8082                	ret
    first = 0;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	f407a423          	sw	zero,-184(a5) # 80008990 <first.1665>
    fsinit(ROOTDEV);
    80001a50:	4505                	li	a0,1
    80001a52:	00002097          	auipc	ra,0x2
    80001a56:	a10080e7          	jalr	-1520(ra) # 80003462 <fsinit>
    80001a5a:	bff9                	j	80001a38 <forkret+0x22>

0000000080001a5c <allocpid>:
allocpid() {
    80001a5c:	1101                	addi	sp,sp,-32
    80001a5e:	ec06                	sd	ra,24(sp)
    80001a60:	e822                	sd	s0,16(sp)
    80001a62:	e426                	sd	s1,8(sp)
    80001a64:	e04a                	sd	s2,0(sp)
    80001a66:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a68:	00010917          	auipc	s2,0x10
    80001a6c:	ee890913          	addi	s2,s2,-280 # 80011950 <pid_lock>
    80001a70:	854a                	mv	a0,s2
    80001a72:	fffff097          	auipc	ra,0xfffff
    80001a76:	19e080e7          	jalr	414(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001a7a:	00007797          	auipc	a5,0x7
    80001a7e:	f1a78793          	addi	a5,a5,-230 # 80008994 <nextpid>
    80001a82:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a84:	0014871b          	addiw	a4,s1,1
    80001a88:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a8a:	854a                	mv	a0,s2
    80001a8c:	fffff097          	auipc	ra,0xfffff
    80001a90:	238080e7          	jalr	568(ra) # 80000cc4 <release>
}
    80001a94:	8526                	mv	a0,s1
    80001a96:	60e2                	ld	ra,24(sp)
    80001a98:	6442                	ld	s0,16(sp)
    80001a9a:	64a2                	ld	s1,8(sp)
    80001a9c:	6902                	ld	s2,0(sp)
    80001a9e:	6105                	addi	sp,sp,32
    80001aa0:	8082                	ret

0000000080001aa2 <proc_pagetable>:
{
    80001aa2:	1101                	addi	sp,sp,-32
    80001aa4:	ec06                	sd	ra,24(sp)
    80001aa6:	e822                	sd	s0,16(sp)
    80001aa8:	e426                	sd	s1,8(sp)
    80001aaa:	e04a                	sd	s2,0(sp)
    80001aac:	1000                	addi	s0,sp,32
    80001aae:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ab0:	00000097          	auipc	ra,0x0
    80001ab4:	8ea080e7          	jalr	-1814(ra) # 8000139a <uvmcreate>
    80001ab8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aba:	c121                	beqz	a0,80001afa <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001abc:	4729                	li	a4,10
    80001abe:	00005697          	auipc	a3,0x5
    80001ac2:	54268693          	addi	a3,a3,1346 # 80007000 <_trampoline>
    80001ac6:	6605                	lui	a2,0x1
    80001ac8:	040005b7          	lui	a1,0x4000
    80001acc:	15fd                	addi	a1,a1,-1
    80001ace:	05b2                	slli	a1,a1,0xc
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	66e080e7          	jalr	1646(ra) # 8000113e <mappages>
    80001ad8:	02054863          	bltz	a0,80001b08 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001adc:	4719                	li	a4,6
    80001ade:	05893683          	ld	a3,88(s2)
    80001ae2:	6605                	lui	a2,0x1
    80001ae4:	020005b7          	lui	a1,0x2000
    80001ae8:	15fd                	addi	a1,a1,-1
    80001aea:	05b6                	slli	a1,a1,0xd
    80001aec:	8526                	mv	a0,s1
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	650080e7          	jalr	1616(ra) # 8000113e <mappages>
    80001af6:	02054163          	bltz	a0,80001b18 <proc_pagetable+0x76>
}
    80001afa:	8526                	mv	a0,s1
    80001afc:	60e2                	ld	ra,24(sp)
    80001afe:	6442                	ld	s0,16(sp)
    80001b00:	64a2                	ld	s1,8(sp)
    80001b02:	6902                	ld	s2,0(sp)
    80001b04:	6105                	addi	sp,sp,32
    80001b06:	8082                	ret
    uvmfree(pagetable, 0);
    80001b08:	4581                	li	a1,0
    80001b0a:	8526                	mv	a0,s1
    80001b0c:	00000097          	auipc	ra,0x0
    80001b10:	a8a080e7          	jalr	-1398(ra) # 80001596 <uvmfree>
    return 0;
    80001b14:	4481                	li	s1,0
    80001b16:	b7d5                	j	80001afa <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b18:	4681                	li	a3,0
    80001b1a:	4605                	li	a2,1
    80001b1c:	040005b7          	lui	a1,0x4000
    80001b20:	15fd                	addi	a1,a1,-1
    80001b22:	05b2                	slli	a1,a1,0xc
    80001b24:	8526                	mv	a0,s1
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	7b0080e7          	jalr	1968(ra) # 800012d6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b2e:	4581                	li	a1,0
    80001b30:	8526                	mv	a0,s1
    80001b32:	00000097          	auipc	ra,0x0
    80001b36:	a64080e7          	jalr	-1436(ra) # 80001596 <uvmfree>
    return 0;
    80001b3a:	4481                	li	s1,0
    80001b3c:	bf7d                	j	80001afa <proc_pagetable+0x58>

0000000080001b3e <proc_freepagetable>:
{
    80001b3e:	1101                	addi	sp,sp,-32
    80001b40:	ec06                	sd	ra,24(sp)
    80001b42:	e822                	sd	s0,16(sp)
    80001b44:	e426                	sd	s1,8(sp)
    80001b46:	e04a                	sd	s2,0(sp)
    80001b48:	1000                	addi	s0,sp,32
    80001b4a:	84aa                	mv	s1,a0
    80001b4c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b4e:	4681                	li	a3,0
    80001b50:	4605                	li	a2,1
    80001b52:	040005b7          	lui	a1,0x4000
    80001b56:	15fd                	addi	a1,a1,-1
    80001b58:	05b2                	slli	a1,a1,0xc
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	77c080e7          	jalr	1916(ra) # 800012d6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b62:	4681                	li	a3,0
    80001b64:	4605                	li	a2,1
    80001b66:	020005b7          	lui	a1,0x2000
    80001b6a:	15fd                	addi	a1,a1,-1
    80001b6c:	05b6                	slli	a1,a1,0xd
    80001b6e:	8526                	mv	a0,s1
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	766080e7          	jalr	1894(ra) # 800012d6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b78:	85ca                	mv	a1,s2
    80001b7a:	8526                	mv	a0,s1
    80001b7c:	00000097          	auipc	ra,0x0
    80001b80:	a1a080e7          	jalr	-1510(ra) # 80001596 <uvmfree>
}
    80001b84:	60e2                	ld	ra,24(sp)
    80001b86:	6442                	ld	s0,16(sp)
    80001b88:	64a2                	ld	s1,8(sp)
    80001b8a:	6902                	ld	s2,0(sp)
    80001b8c:	6105                	addi	sp,sp,32
    80001b8e:	8082                	ret

0000000080001b90 <freeproc>:
{
    80001b90:	1101                	addi	sp,sp,-32
    80001b92:	ec06                	sd	ra,24(sp)
    80001b94:	e822                	sd	s0,16(sp)
    80001b96:	e426                	sd	s1,8(sp)
    80001b98:	1000                	addi	s0,sp,32
    80001b9a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b9c:	6d28                	ld	a0,88(a0)
    80001b9e:	c509                	beqz	a0,80001ba8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	e84080e7          	jalr	-380(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001ba8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bac:	68a8                	ld	a0,80(s1)
    80001bae:	c511                	beqz	a0,80001bba <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bb0:	64ac                	ld	a1,72(s1)
    80001bb2:	00000097          	auipc	ra,0x0
    80001bb6:	f8c080e7          	jalr	-116(ra) # 80001b3e <proc_freepagetable>
  p->pagetable = 0;
    80001bba:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bbe:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bc2:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001bc6:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001bca:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bce:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001bd2:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001bd6:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001bda:	0004ac23          	sw	zero,24(s1)
}
    80001bde:	60e2                	ld	ra,24(sp)
    80001be0:	6442                	ld	s0,16(sp)
    80001be2:	64a2                	ld	s1,8(sp)
    80001be4:	6105                	addi	sp,sp,32
    80001be6:	8082                	ret

0000000080001be8 <allocproc>:
{
    80001be8:	1101                	addi	sp,sp,-32
    80001bea:	ec06                	sd	ra,24(sp)
    80001bec:	e822                	sd	s0,16(sp)
    80001bee:	e426                	sd	s1,8(sp)
    80001bf0:	e04a                	sd	s2,0(sp)
    80001bf2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bf4:	00010497          	auipc	s1,0x10
    80001bf8:	17448493          	addi	s1,s1,372 # 80011d68 <proc>
    80001bfc:	00016917          	auipc	s2,0x16
    80001c00:	b6c90913          	addi	s2,s2,-1172 # 80017768 <tickslock>
    acquire(&p->lock);
    80001c04:	8526                	mv	a0,s1
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	00a080e7          	jalr	10(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    80001c0e:	4c9c                	lw	a5,24(s1)
    80001c10:	cf81                	beqz	a5,80001c28 <allocproc+0x40>
      release(&p->lock);
    80001c12:	8526                	mv	a0,s1
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	0b0080e7          	jalr	176(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c1c:	16848493          	addi	s1,s1,360
    80001c20:	ff2492e3          	bne	s1,s2,80001c04 <allocproc+0x1c>
  return 0;
    80001c24:	4481                	li	s1,0
    80001c26:	a0b9                	j	80001c74 <allocproc+0x8c>
  p->pid = allocpid();
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	e34080e7          	jalr	-460(ra) # 80001a5c <allocpid>
    80001c30:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	eee080e7          	jalr	-274(ra) # 80000b20 <kalloc>
    80001c3a:	892a                	mv	s2,a0
    80001c3c:	eca8                	sd	a0,88(s1)
    80001c3e:	c131                	beqz	a0,80001c82 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c40:	8526                	mv	a0,s1
    80001c42:	00000097          	auipc	ra,0x0
    80001c46:	e60080e7          	jalr	-416(ra) # 80001aa2 <proc_pagetable>
    80001c4a:	892a                	mv	s2,a0
    80001c4c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c4e:	c129                	beqz	a0,80001c90 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c50:	07000613          	li	a2,112
    80001c54:	4581                	li	a1,0
    80001c56:	06048513          	addi	a0,s1,96
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	0b2080e7          	jalr	178(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001c62:	00000797          	auipc	a5,0x0
    80001c66:	db478793          	addi	a5,a5,-588 # 80001a16 <forkret>
    80001c6a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c6c:	60bc                	ld	a5,64(s1)
    80001c6e:	6705                	lui	a4,0x1
    80001c70:	97ba                	add	a5,a5,a4
    80001c72:	f4bc                	sd	a5,104(s1)
}
    80001c74:	8526                	mv	a0,s1
    80001c76:	60e2                	ld	ra,24(sp)
    80001c78:	6442                	ld	s0,16(sp)
    80001c7a:	64a2                	ld	s1,8(sp)
    80001c7c:	6902                	ld	s2,0(sp)
    80001c7e:	6105                	addi	sp,sp,32
    80001c80:	8082                	ret
    release(&p->lock);
    80001c82:	8526                	mv	a0,s1
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	040080e7          	jalr	64(ra) # 80000cc4 <release>
    return 0;
    80001c8c:	84ca                	mv	s1,s2
    80001c8e:	b7dd                	j	80001c74 <allocproc+0x8c>
    freeproc(p);
    80001c90:	8526                	mv	a0,s1
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	efe080e7          	jalr	-258(ra) # 80001b90 <freeproc>
    release(&p->lock);
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	028080e7          	jalr	40(ra) # 80000cc4 <release>
    return 0;
    80001ca4:	84ca                	mv	s1,s2
    80001ca6:	b7f9                	j	80001c74 <allocproc+0x8c>

0000000080001ca8 <userinit>:
{
    80001ca8:	1101                	addi	sp,sp,-32
    80001caa:	ec06                	sd	ra,24(sp)
    80001cac:	e822                	sd	s0,16(sp)
    80001cae:	e426                	sd	s1,8(sp)
    80001cb0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	f36080e7          	jalr	-202(ra) # 80001be8 <allocproc>
    80001cba:	84aa                	mv	s1,a0
  initproc = p;
    80001cbc:	00007797          	auipc	a5,0x7
    80001cc0:	34a7be23          	sd	a0,860(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cc4:	03400613          	li	a2,52
    80001cc8:	00007597          	auipc	a1,0x7
    80001ccc:	cd858593          	addi	a1,a1,-808 # 800089a0 <initcode>
    80001cd0:	6928                	ld	a0,80(a0)
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	6f6080e7          	jalr	1782(ra) # 800013c8 <uvminit>
  p->sz = PGSIZE;
    80001cda:	6785                	lui	a5,0x1
    80001cdc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cde:	6cb8                	ld	a4,88(s1)
    80001ce0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ce4:	6cb8                	ld	a4,88(s1)
    80001ce6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ce8:	4641                	li	a2,16
    80001cea:	00006597          	auipc	a1,0x6
    80001cee:	4fe58593          	addi	a1,a1,1278 # 800081e8 <digits+0x1a8>
    80001cf2:	15848513          	addi	a0,s1,344
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	16c080e7          	jalr	364(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001cfe:	00006517          	auipc	a0,0x6
    80001d02:	4fa50513          	addi	a0,a0,1274 # 800081f8 <digits+0x1b8>
    80001d06:	00002097          	auipc	ra,0x2
    80001d0a:	184080e7          	jalr	388(ra) # 80003e8a <namei>
    80001d0e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d12:	4789                	li	a5,2
    80001d14:	cc9c                	sw	a5,24(s1)
  p->tracemask = 0;
    80001d16:	0204ae23          	sw	zero,60(s1)
  release(&p->lock);
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	fa8080e7          	jalr	-88(ra) # 80000cc4 <release>
}
    80001d24:	60e2                	ld	ra,24(sp)
    80001d26:	6442                	ld	s0,16(sp)
    80001d28:	64a2                	ld	s1,8(sp)
    80001d2a:	6105                	addi	sp,sp,32
    80001d2c:	8082                	ret

0000000080001d2e <growproc>:
{
    80001d2e:	1101                	addi	sp,sp,-32
    80001d30:	ec06                	sd	ra,24(sp)
    80001d32:	e822                	sd	s0,16(sp)
    80001d34:	e426                	sd	s1,8(sp)
    80001d36:	e04a                	sd	s2,0(sp)
    80001d38:	1000                	addi	s0,sp,32
    80001d3a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d3c:	00000097          	auipc	ra,0x0
    80001d40:	ca2080e7          	jalr	-862(ra) # 800019de <myproc>
    80001d44:	892a                	mv	s2,a0
  sz = p->sz;
    80001d46:	652c                	ld	a1,72(a0)
    80001d48:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d4c:	00904f63          	bgtz	s1,80001d6a <growproc+0x3c>
  } else if(n < 0){
    80001d50:	0204cc63          	bltz	s1,80001d88 <growproc+0x5a>
  p->sz = sz;
    80001d54:	1602                	slli	a2,a2,0x20
    80001d56:	9201                	srli	a2,a2,0x20
    80001d58:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d5c:	4501                	li	a0,0
}
    80001d5e:	60e2                	ld	ra,24(sp)
    80001d60:	6442                	ld	s0,16(sp)
    80001d62:	64a2                	ld	s1,8(sp)
    80001d64:	6902                	ld	s2,0(sp)
    80001d66:	6105                	addi	sp,sp,32
    80001d68:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d6a:	9e25                	addw	a2,a2,s1
    80001d6c:	1602                	slli	a2,a2,0x20
    80001d6e:	9201                	srli	a2,a2,0x20
    80001d70:	1582                	slli	a1,a1,0x20
    80001d72:	9181                	srli	a1,a1,0x20
    80001d74:	6928                	ld	a0,80(a0)
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	70c080e7          	jalr	1804(ra) # 80001482 <uvmalloc>
    80001d7e:	0005061b          	sext.w	a2,a0
    80001d82:	fa69                	bnez	a2,80001d54 <growproc+0x26>
      return -1;
    80001d84:	557d                	li	a0,-1
    80001d86:	bfe1                	j	80001d5e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d88:	9e25                	addw	a2,a2,s1
    80001d8a:	1602                	slli	a2,a2,0x20
    80001d8c:	9201                	srli	a2,a2,0x20
    80001d8e:	1582                	slli	a1,a1,0x20
    80001d90:	9181                	srli	a1,a1,0x20
    80001d92:	6928                	ld	a0,80(a0)
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	6a6080e7          	jalr	1702(ra) # 8000143a <uvmdealloc>
    80001d9c:	0005061b          	sext.w	a2,a0
    80001da0:	bf55                	j	80001d54 <growproc+0x26>

0000000080001da2 <fork>:
{
    80001da2:	7179                	addi	sp,sp,-48
    80001da4:	f406                	sd	ra,40(sp)
    80001da6:	f022                	sd	s0,32(sp)
    80001da8:	ec26                	sd	s1,24(sp)
    80001daa:	e84a                	sd	s2,16(sp)
    80001dac:	e44e                	sd	s3,8(sp)
    80001dae:	e052                	sd	s4,0(sp)
    80001db0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001db2:	00000097          	auipc	ra,0x0
    80001db6:	c2c080e7          	jalr	-980(ra) # 800019de <myproc>
    80001dba:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	e2c080e7          	jalr	-468(ra) # 80001be8 <allocproc>
    80001dc4:	c575                	beqz	a0,80001eb0 <fork+0x10e>
    80001dc6:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dc8:	04893603          	ld	a2,72(s2)
    80001dcc:	692c                	ld	a1,80(a0)
    80001dce:	05093503          	ld	a0,80(s2)
    80001dd2:	fffff097          	auipc	ra,0xfffff
    80001dd6:	7fc080e7          	jalr	2044(ra) # 800015ce <uvmcopy>
    80001dda:	04054863          	bltz	a0,80001e2a <fork+0x88>
  np->sz = p->sz;
    80001dde:	04893783          	ld	a5,72(s2)
    80001de2:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001de6:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dea:	05893683          	ld	a3,88(s2)
    80001dee:	87b6                	mv	a5,a3
    80001df0:	0589b703          	ld	a4,88(s3)
    80001df4:	12068693          	addi	a3,a3,288
    80001df8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dfc:	6788                	ld	a0,8(a5)
    80001dfe:	6b8c                	ld	a1,16(a5)
    80001e00:	6f90                	ld	a2,24(a5)
    80001e02:	01073023          	sd	a6,0(a4)
    80001e06:	e708                	sd	a0,8(a4)
    80001e08:	eb0c                	sd	a1,16(a4)
    80001e0a:	ef10                	sd	a2,24(a4)
    80001e0c:	02078793          	addi	a5,a5,32
    80001e10:	02070713          	addi	a4,a4,32
    80001e14:	fed792e3          	bne	a5,a3,80001df8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e18:	0589b783          	ld	a5,88(s3)
    80001e1c:	0607b823          	sd	zero,112(a5)
    80001e20:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e24:	15000a13          	li	s4,336
    80001e28:	a03d                	j	80001e56 <fork+0xb4>
    freeproc(np);
    80001e2a:	854e                	mv	a0,s3
    80001e2c:	00000097          	auipc	ra,0x0
    80001e30:	d64080e7          	jalr	-668(ra) # 80001b90 <freeproc>
    release(&np->lock);
    80001e34:	854e                	mv	a0,s3
    80001e36:	fffff097          	auipc	ra,0xfffff
    80001e3a:	e8e080e7          	jalr	-370(ra) # 80000cc4 <release>
    return -1;
    80001e3e:	54fd                	li	s1,-1
    80001e40:	a8b9                	j	80001e9e <fork+0xfc>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e42:	00002097          	auipc	ra,0x2
    80001e46:	6d4080e7          	jalr	1748(ra) # 80004516 <filedup>
    80001e4a:	009987b3          	add	a5,s3,s1
    80001e4e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e50:	04a1                	addi	s1,s1,8
    80001e52:	01448763          	beq	s1,s4,80001e60 <fork+0xbe>
    if(p->ofile[i])
    80001e56:	009907b3          	add	a5,s2,s1
    80001e5a:	6388                	ld	a0,0(a5)
    80001e5c:	f17d                	bnez	a0,80001e42 <fork+0xa0>
    80001e5e:	bfcd                	j	80001e50 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001e60:	15093503          	ld	a0,336(s2)
    80001e64:	00002097          	auipc	ra,0x2
    80001e68:	838080e7          	jalr	-1992(ra) # 8000369c <idup>
    80001e6c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e70:	4641                	li	a2,16
    80001e72:	15890593          	addi	a1,s2,344
    80001e76:	15898513          	addi	a0,s3,344
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	fe8080e7          	jalr	-24(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    80001e82:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001e86:	4789                	li	a5,2
    80001e88:	00f9ac23          	sw	a5,24(s3)
  np->tracemask = p->tracemask;
    80001e8c:	03c92783          	lw	a5,60(s2)
    80001e90:	02f9ae23          	sw	a5,60(s3)
  release(&np->lock);
    80001e94:	854e                	mv	a0,s3
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	e2e080e7          	jalr	-466(ra) # 80000cc4 <release>
}
    80001e9e:	8526                	mv	a0,s1
    80001ea0:	70a2                	ld	ra,40(sp)
    80001ea2:	7402                	ld	s0,32(sp)
    80001ea4:	64e2                	ld	s1,24(sp)
    80001ea6:	6942                	ld	s2,16(sp)
    80001ea8:	69a2                	ld	s3,8(sp)
    80001eaa:	6a02                	ld	s4,0(sp)
    80001eac:	6145                	addi	sp,sp,48
    80001eae:	8082                	ret
    return -1;
    80001eb0:	54fd                	li	s1,-1
    80001eb2:	b7f5                	j	80001e9e <fork+0xfc>

0000000080001eb4 <reparent>:
{
    80001eb4:	7179                	addi	sp,sp,-48
    80001eb6:	f406                	sd	ra,40(sp)
    80001eb8:	f022                	sd	s0,32(sp)
    80001eba:	ec26                	sd	s1,24(sp)
    80001ebc:	e84a                	sd	s2,16(sp)
    80001ebe:	e44e                	sd	s3,8(sp)
    80001ec0:	e052                	sd	s4,0(sp)
    80001ec2:	1800                	addi	s0,sp,48
    80001ec4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ec6:	00010497          	auipc	s1,0x10
    80001eca:	ea248493          	addi	s1,s1,-350 # 80011d68 <proc>
      pp->parent = initproc;
    80001ece:	00007a17          	auipc	s4,0x7
    80001ed2:	14aa0a13          	addi	s4,s4,330 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ed6:	00016997          	auipc	s3,0x16
    80001eda:	89298993          	addi	s3,s3,-1902 # 80017768 <tickslock>
    80001ede:	a029                	j	80001ee8 <reparent+0x34>
    80001ee0:	16848493          	addi	s1,s1,360
    80001ee4:	03348363          	beq	s1,s3,80001f0a <reparent+0x56>
    if(pp->parent == p){
    80001ee8:	709c                	ld	a5,32(s1)
    80001eea:	ff279be3          	bne	a5,s2,80001ee0 <reparent+0x2c>
      acquire(&pp->lock);
    80001eee:	8526                	mv	a0,s1
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	d20080e7          	jalr	-736(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    80001ef8:	000a3783          	ld	a5,0(s4)
    80001efc:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	dc4080e7          	jalr	-572(ra) # 80000cc4 <release>
    80001f08:	bfe1                	j	80001ee0 <reparent+0x2c>
}
    80001f0a:	70a2                	ld	ra,40(sp)
    80001f0c:	7402                	ld	s0,32(sp)
    80001f0e:	64e2                	ld	s1,24(sp)
    80001f10:	6942                	ld	s2,16(sp)
    80001f12:	69a2                	ld	s3,8(sp)
    80001f14:	6a02                	ld	s4,0(sp)
    80001f16:	6145                	addi	sp,sp,48
    80001f18:	8082                	ret

0000000080001f1a <scheduler>:
{
    80001f1a:	715d                	addi	sp,sp,-80
    80001f1c:	e486                	sd	ra,72(sp)
    80001f1e:	e0a2                	sd	s0,64(sp)
    80001f20:	fc26                	sd	s1,56(sp)
    80001f22:	f84a                	sd	s2,48(sp)
    80001f24:	f44e                	sd	s3,40(sp)
    80001f26:	f052                	sd	s4,32(sp)
    80001f28:	ec56                	sd	s5,24(sp)
    80001f2a:	e85a                	sd	s6,16(sp)
    80001f2c:	e45e                	sd	s7,8(sp)
    80001f2e:	e062                	sd	s8,0(sp)
    80001f30:	0880                	addi	s0,sp,80
    80001f32:	8792                	mv	a5,tp
  int id = r_tp();
    80001f34:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f36:	00779b13          	slli	s6,a5,0x7
    80001f3a:	00010717          	auipc	a4,0x10
    80001f3e:	a1670713          	addi	a4,a4,-1514 # 80011950 <pid_lock>
    80001f42:	975a                	add	a4,a4,s6
    80001f44:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f48:	00010717          	auipc	a4,0x10
    80001f4c:	a2870713          	addi	a4,a4,-1496 # 80011970 <cpus+0x8>
    80001f50:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f52:	4c0d                	li	s8,3
        c->proc = p;
    80001f54:	079e                	slli	a5,a5,0x7
    80001f56:	00010a17          	auipc	s4,0x10
    80001f5a:	9faa0a13          	addi	s4,s4,-1542 # 80011950 <pid_lock>
    80001f5e:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f60:	00016997          	auipc	s3,0x16
    80001f64:	80898993          	addi	s3,s3,-2040 # 80017768 <tickslock>
        found = 1;
    80001f68:	4b85                	li	s7,1
    80001f6a:	a899                	j	80001fc0 <scheduler+0xa6>
        p->state = RUNNING;
    80001f6c:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001f70:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001f74:	06048593          	addi	a1,s1,96
    80001f78:	855a                	mv	a0,s6
    80001f7a:	00000097          	auipc	ra,0x0
    80001f7e:	674080e7          	jalr	1652(ra) # 800025ee <swtch>
        c->proc = 0;
    80001f82:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001f86:	8ade                	mv	s5,s7
      release(&p->lock);
    80001f88:	8526                	mv	a0,s1
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	d3a080e7          	jalr	-710(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f92:	16848493          	addi	s1,s1,360
    80001f96:	01348b63          	beq	s1,s3,80001fac <scheduler+0x92>
      acquire(&p->lock);
    80001f9a:	8526                	mv	a0,s1
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	c74080e7          	jalr	-908(ra) # 80000c10 <acquire>
      if(p->state == RUNNABLE) {
    80001fa4:	4c9c                	lw	a5,24(s1)
    80001fa6:	ff2791e3          	bne	a5,s2,80001f88 <scheduler+0x6e>
    80001faa:	b7c9                	j	80001f6c <scheduler+0x52>
    if(found == 0) {
    80001fac:	000a9a63          	bnez	s5,80001fc0 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fb0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fb4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fb8:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001fbc:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fc0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fc4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fc8:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001fcc:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fce:	00010497          	auipc	s1,0x10
    80001fd2:	d9a48493          	addi	s1,s1,-614 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80001fd6:	4909                	li	s2,2
    80001fd8:	b7c9                	j	80001f9a <scheduler+0x80>

0000000080001fda <sched>:
{
    80001fda:	7179                	addi	sp,sp,-48
    80001fdc:	f406                	sd	ra,40(sp)
    80001fde:	f022                	sd	s0,32(sp)
    80001fe0:	ec26                	sd	s1,24(sp)
    80001fe2:	e84a                	sd	s2,16(sp)
    80001fe4:	e44e                	sd	s3,8(sp)
    80001fe6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fe8:	00000097          	auipc	ra,0x0
    80001fec:	9f6080e7          	jalr	-1546(ra) # 800019de <myproc>
    80001ff0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	ba4080e7          	jalr	-1116(ra) # 80000b96 <holding>
    80001ffa:	c93d                	beqz	a0,80002070 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ffc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ffe:	2781                	sext.w	a5,a5
    80002000:	079e                	slli	a5,a5,0x7
    80002002:	00010717          	auipc	a4,0x10
    80002006:	94e70713          	addi	a4,a4,-1714 # 80011950 <pid_lock>
    8000200a:	97ba                	add	a5,a5,a4
    8000200c:	0907a703          	lw	a4,144(a5)
    80002010:	4785                	li	a5,1
    80002012:	06f71763          	bne	a4,a5,80002080 <sched+0xa6>
  if(p->state == RUNNING)
    80002016:	4c98                	lw	a4,24(s1)
    80002018:	478d                	li	a5,3
    8000201a:	06f70b63          	beq	a4,a5,80002090 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000201e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002022:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002024:	efb5                	bnez	a5,800020a0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002026:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002028:	00010917          	auipc	s2,0x10
    8000202c:	92890913          	addi	s2,s2,-1752 # 80011950 <pid_lock>
    80002030:	2781                	sext.w	a5,a5
    80002032:	079e                	slli	a5,a5,0x7
    80002034:	97ca                	add	a5,a5,s2
    80002036:	0947a983          	lw	s3,148(a5)
    8000203a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000203c:	2781                	sext.w	a5,a5
    8000203e:	079e                	slli	a5,a5,0x7
    80002040:	00010597          	auipc	a1,0x10
    80002044:	93058593          	addi	a1,a1,-1744 # 80011970 <cpus+0x8>
    80002048:	95be                	add	a1,a1,a5
    8000204a:	06048513          	addi	a0,s1,96
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	5a0080e7          	jalr	1440(ra) # 800025ee <swtch>
    80002056:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002058:	2781                	sext.w	a5,a5
    8000205a:	079e                	slli	a5,a5,0x7
    8000205c:	97ca                	add	a5,a5,s2
    8000205e:	0937aa23          	sw	s3,148(a5)
}
    80002062:	70a2                	ld	ra,40(sp)
    80002064:	7402                	ld	s0,32(sp)
    80002066:	64e2                	ld	s1,24(sp)
    80002068:	6942                	ld	s2,16(sp)
    8000206a:	69a2                	ld	s3,8(sp)
    8000206c:	6145                	addi	sp,sp,48
    8000206e:	8082                	ret
    panic("sched p->lock");
    80002070:	00006517          	auipc	a0,0x6
    80002074:	19050513          	addi	a0,a0,400 # 80008200 <digits+0x1c0>
    80002078:	ffffe097          	auipc	ra,0xffffe
    8000207c:	4d0080e7          	jalr	1232(ra) # 80000548 <panic>
    panic("sched locks");
    80002080:	00006517          	auipc	a0,0x6
    80002084:	19050513          	addi	a0,a0,400 # 80008210 <digits+0x1d0>
    80002088:	ffffe097          	auipc	ra,0xffffe
    8000208c:	4c0080e7          	jalr	1216(ra) # 80000548 <panic>
    panic("sched running");
    80002090:	00006517          	auipc	a0,0x6
    80002094:	19050513          	addi	a0,a0,400 # 80008220 <digits+0x1e0>
    80002098:	ffffe097          	auipc	ra,0xffffe
    8000209c:	4b0080e7          	jalr	1200(ra) # 80000548 <panic>
    panic("sched interruptible");
    800020a0:	00006517          	auipc	a0,0x6
    800020a4:	19050513          	addi	a0,a0,400 # 80008230 <digits+0x1f0>
    800020a8:	ffffe097          	auipc	ra,0xffffe
    800020ac:	4a0080e7          	jalr	1184(ra) # 80000548 <panic>

00000000800020b0 <exit>:
{
    800020b0:	7179                	addi	sp,sp,-48
    800020b2:	f406                	sd	ra,40(sp)
    800020b4:	f022                	sd	s0,32(sp)
    800020b6:	ec26                	sd	s1,24(sp)
    800020b8:	e84a                	sd	s2,16(sp)
    800020ba:	e44e                	sd	s3,8(sp)
    800020bc:	e052                	sd	s4,0(sp)
    800020be:	1800                	addi	s0,sp,48
    800020c0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020c2:	00000097          	auipc	ra,0x0
    800020c6:	91c080e7          	jalr	-1764(ra) # 800019de <myproc>
    800020ca:	89aa                	mv	s3,a0
  if(p == initproc)
    800020cc:	00007797          	auipc	a5,0x7
    800020d0:	f4c7b783          	ld	a5,-180(a5) # 80009018 <initproc>
    800020d4:	0d050493          	addi	s1,a0,208
    800020d8:	15050913          	addi	s2,a0,336
    800020dc:	02a79363          	bne	a5,a0,80002102 <exit+0x52>
    panic("init exiting");
    800020e0:	00006517          	auipc	a0,0x6
    800020e4:	16850513          	addi	a0,a0,360 # 80008248 <digits+0x208>
    800020e8:	ffffe097          	auipc	ra,0xffffe
    800020ec:	460080e7          	jalr	1120(ra) # 80000548 <panic>
      fileclose(f);
    800020f0:	00002097          	auipc	ra,0x2
    800020f4:	478080e7          	jalr	1144(ra) # 80004568 <fileclose>
      p->ofile[fd] = 0;
    800020f8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800020fc:	04a1                	addi	s1,s1,8
    800020fe:	01248563          	beq	s1,s2,80002108 <exit+0x58>
    if(p->ofile[fd]){
    80002102:	6088                	ld	a0,0(s1)
    80002104:	f575                	bnez	a0,800020f0 <exit+0x40>
    80002106:	bfdd                	j	800020fc <exit+0x4c>
  begin_op();
    80002108:	00002097          	auipc	ra,0x2
    8000210c:	f8e080e7          	jalr	-114(ra) # 80004096 <begin_op>
  iput(p->cwd);
    80002110:	1509b503          	ld	a0,336(s3)
    80002114:	00001097          	auipc	ra,0x1
    80002118:	780080e7          	jalr	1920(ra) # 80003894 <iput>
  end_op();
    8000211c:	00002097          	auipc	ra,0x2
    80002120:	ffa080e7          	jalr	-6(ra) # 80004116 <end_op>
  p->cwd = 0;
    80002124:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002128:	00007497          	auipc	s1,0x7
    8000212c:	ef048493          	addi	s1,s1,-272 # 80009018 <initproc>
    80002130:	6088                	ld	a0,0(s1)
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	ade080e7          	jalr	-1314(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    8000213a:	6088                	ld	a0,0(s1)
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	762080e7          	jalr	1890(ra) # 8000189e <wakeup1>
  release(&initproc->lock);
    80002144:	6088                	ld	a0,0(s1)
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	b7e080e7          	jalr	-1154(ra) # 80000cc4 <release>
  acquire(&p->lock);
    8000214e:	854e                	mv	a0,s3
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	ac0080e7          	jalr	-1344(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    80002158:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000215c:	854e                	mv	a0,s3
    8000215e:	fffff097          	auipc	ra,0xfffff
    80002162:	b66080e7          	jalr	-1178(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    80002166:	8526                	mv	a0,s1
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	aa8080e7          	jalr	-1368(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    80002170:	854e                	mv	a0,s3
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	a9e080e7          	jalr	-1378(ra) # 80000c10 <acquire>
  reparent(p);
    8000217a:	854e                	mv	a0,s3
    8000217c:	00000097          	auipc	ra,0x0
    80002180:	d38080e7          	jalr	-712(ra) # 80001eb4 <reparent>
  wakeup1(original_parent);
    80002184:	8526                	mv	a0,s1
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	718080e7          	jalr	1816(ra) # 8000189e <wakeup1>
  p->xstate = status;
    8000218e:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002192:	4791                	li	a5,4
    80002194:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002198:	8526                	mv	a0,s1
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	b2a080e7          	jalr	-1238(ra) # 80000cc4 <release>
  sched();
    800021a2:	00000097          	auipc	ra,0x0
    800021a6:	e38080e7          	jalr	-456(ra) # 80001fda <sched>
  panic("zombie exit");
    800021aa:	00006517          	auipc	a0,0x6
    800021ae:	0ae50513          	addi	a0,a0,174 # 80008258 <digits+0x218>
    800021b2:	ffffe097          	auipc	ra,0xffffe
    800021b6:	396080e7          	jalr	918(ra) # 80000548 <panic>

00000000800021ba <yield>:
{
    800021ba:	1101                	addi	sp,sp,-32
    800021bc:	ec06                	sd	ra,24(sp)
    800021be:	e822                	sd	s0,16(sp)
    800021c0:	e426                	sd	s1,8(sp)
    800021c2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021c4:	00000097          	auipc	ra,0x0
    800021c8:	81a080e7          	jalr	-2022(ra) # 800019de <myproc>
    800021cc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	a42080e7          	jalr	-1470(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    800021d6:	4789                	li	a5,2
    800021d8:	cc9c                	sw	a5,24(s1)
  sched();
    800021da:	00000097          	auipc	ra,0x0
    800021de:	e00080e7          	jalr	-512(ra) # 80001fda <sched>
  release(&p->lock);
    800021e2:	8526                	mv	a0,s1
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	ae0080e7          	jalr	-1312(ra) # 80000cc4 <release>
}
    800021ec:	60e2                	ld	ra,24(sp)
    800021ee:	6442                	ld	s0,16(sp)
    800021f0:	64a2                	ld	s1,8(sp)
    800021f2:	6105                	addi	sp,sp,32
    800021f4:	8082                	ret

00000000800021f6 <sleep>:
{
    800021f6:	7179                	addi	sp,sp,-48
    800021f8:	f406                	sd	ra,40(sp)
    800021fa:	f022                	sd	s0,32(sp)
    800021fc:	ec26                	sd	s1,24(sp)
    800021fe:	e84a                	sd	s2,16(sp)
    80002200:	e44e                	sd	s3,8(sp)
    80002202:	1800                	addi	s0,sp,48
    80002204:	89aa                	mv	s3,a0
    80002206:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	7d6080e7          	jalr	2006(ra) # 800019de <myproc>
    80002210:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002212:	05250663          	beq	a0,s2,8000225e <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	9fa080e7          	jalr	-1542(ra) # 80000c10 <acquire>
    release(lk);
    8000221e:	854a                	mv	a0,s2
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	aa4080e7          	jalr	-1372(ra) # 80000cc4 <release>
  p->chan = chan;
    80002228:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000222c:	4785                	li	a5,1
    8000222e:	cc9c                	sw	a5,24(s1)
  sched();
    80002230:	00000097          	auipc	ra,0x0
    80002234:	daa080e7          	jalr	-598(ra) # 80001fda <sched>
  p->chan = 0;
    80002238:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a86080e7          	jalr	-1402(ra) # 80000cc4 <release>
    acquire(lk);
    80002246:	854a                	mv	a0,s2
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	9c8080e7          	jalr	-1592(ra) # 80000c10 <acquire>
}
    80002250:	70a2                	ld	ra,40(sp)
    80002252:	7402                	ld	s0,32(sp)
    80002254:	64e2                	ld	s1,24(sp)
    80002256:	6942                	ld	s2,16(sp)
    80002258:	69a2                	ld	s3,8(sp)
    8000225a:	6145                	addi	sp,sp,48
    8000225c:	8082                	ret
  p->chan = chan;
    8000225e:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002262:	4785                	li	a5,1
    80002264:	cd1c                	sw	a5,24(a0)
  sched();
    80002266:	00000097          	auipc	ra,0x0
    8000226a:	d74080e7          	jalr	-652(ra) # 80001fda <sched>
  p->chan = 0;
    8000226e:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002272:	bff9                	j	80002250 <sleep+0x5a>

0000000080002274 <wait>:
{
    80002274:	715d                	addi	sp,sp,-80
    80002276:	e486                	sd	ra,72(sp)
    80002278:	e0a2                	sd	s0,64(sp)
    8000227a:	fc26                	sd	s1,56(sp)
    8000227c:	f84a                	sd	s2,48(sp)
    8000227e:	f44e                	sd	s3,40(sp)
    80002280:	f052                	sd	s4,32(sp)
    80002282:	ec56                	sd	s5,24(sp)
    80002284:	e85a                	sd	s6,16(sp)
    80002286:	e45e                	sd	s7,8(sp)
    80002288:	e062                	sd	s8,0(sp)
    8000228a:	0880                	addi	s0,sp,80
    8000228c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	750080e7          	jalr	1872(ra) # 800019de <myproc>
    80002296:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002298:	8c2a                	mv	s8,a0
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	976080e7          	jalr	-1674(ra) # 80000c10 <acquire>
    havekids = 0;
    800022a2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022a4:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800022a6:	00015997          	auipc	s3,0x15
    800022aa:	4c298993          	addi	s3,s3,1218 # 80017768 <tickslock>
        havekids = 1;
    800022ae:	4a85                	li	s5,1
    havekids = 0;
    800022b0:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022b2:	00010497          	auipc	s1,0x10
    800022b6:	ab648493          	addi	s1,s1,-1354 # 80011d68 <proc>
    800022ba:	a08d                	j	8000231c <wait+0xa8>
          pid = np->pid;
    800022bc:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022c0:	000b0e63          	beqz	s6,800022dc <wait+0x68>
    800022c4:	4691                	li	a3,4
    800022c6:	03448613          	addi	a2,s1,52
    800022ca:	85da                	mv	a1,s6
    800022cc:	05093503          	ld	a0,80(s2)
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	402080e7          	jalr	1026(ra) # 800016d2 <copyout>
    800022d8:	02054263          	bltz	a0,800022fc <wait+0x88>
          freeproc(np);
    800022dc:	8526                	mv	a0,s1
    800022de:	00000097          	auipc	ra,0x0
    800022e2:	8b2080e7          	jalr	-1870(ra) # 80001b90 <freeproc>
          release(&np->lock);
    800022e6:	8526                	mv	a0,s1
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	9dc080e7          	jalr	-1572(ra) # 80000cc4 <release>
          release(&p->lock);
    800022f0:	854a                	mv	a0,s2
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	9d2080e7          	jalr	-1582(ra) # 80000cc4 <release>
          return pid;
    800022fa:	a8a9                	j	80002354 <wait+0xe0>
            release(&np->lock);
    800022fc:	8526                	mv	a0,s1
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	9c6080e7          	jalr	-1594(ra) # 80000cc4 <release>
            release(&p->lock);
    80002306:	854a                	mv	a0,s2
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	9bc080e7          	jalr	-1604(ra) # 80000cc4 <release>
            return -1;
    80002310:	59fd                	li	s3,-1
    80002312:	a089                	j	80002354 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002314:	16848493          	addi	s1,s1,360
    80002318:	03348463          	beq	s1,s3,80002340 <wait+0xcc>
      if(np->parent == p){
    8000231c:	709c                	ld	a5,32(s1)
    8000231e:	ff279be3          	bne	a5,s2,80002314 <wait+0xa0>
        acquire(&np->lock);
    80002322:	8526                	mv	a0,s1
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	8ec080e7          	jalr	-1812(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    8000232c:	4c9c                	lw	a5,24(s1)
    8000232e:	f94787e3          	beq	a5,s4,800022bc <wait+0x48>
        release(&np->lock);
    80002332:	8526                	mv	a0,s1
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	990080e7          	jalr	-1648(ra) # 80000cc4 <release>
        havekids = 1;
    8000233c:	8756                	mv	a4,s5
    8000233e:	bfd9                	j	80002314 <wait+0xa0>
    if(!havekids || p->killed){
    80002340:	c701                	beqz	a4,80002348 <wait+0xd4>
    80002342:	03092783          	lw	a5,48(s2)
    80002346:	c785                	beqz	a5,8000236e <wait+0xfa>
      release(&p->lock);
    80002348:	854a                	mv	a0,s2
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	97a080e7          	jalr	-1670(ra) # 80000cc4 <release>
      return -1;
    80002352:	59fd                	li	s3,-1
}
    80002354:	854e                	mv	a0,s3
    80002356:	60a6                	ld	ra,72(sp)
    80002358:	6406                	ld	s0,64(sp)
    8000235a:	74e2                	ld	s1,56(sp)
    8000235c:	7942                	ld	s2,48(sp)
    8000235e:	79a2                	ld	s3,40(sp)
    80002360:	7a02                	ld	s4,32(sp)
    80002362:	6ae2                	ld	s5,24(sp)
    80002364:	6b42                	ld	s6,16(sp)
    80002366:	6ba2                	ld	s7,8(sp)
    80002368:	6c02                	ld	s8,0(sp)
    8000236a:	6161                	addi	sp,sp,80
    8000236c:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000236e:	85e2                	mv	a1,s8
    80002370:	854a                	mv	a0,s2
    80002372:	00000097          	auipc	ra,0x0
    80002376:	e84080e7          	jalr	-380(ra) # 800021f6 <sleep>
    havekids = 0;
    8000237a:	bf1d                	j	800022b0 <wait+0x3c>

000000008000237c <wakeup>:
{
    8000237c:	7139                	addi	sp,sp,-64
    8000237e:	fc06                	sd	ra,56(sp)
    80002380:	f822                	sd	s0,48(sp)
    80002382:	f426                	sd	s1,40(sp)
    80002384:	f04a                	sd	s2,32(sp)
    80002386:	ec4e                	sd	s3,24(sp)
    80002388:	e852                	sd	s4,16(sp)
    8000238a:	e456                	sd	s5,8(sp)
    8000238c:	0080                	addi	s0,sp,64
    8000238e:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002390:	00010497          	auipc	s1,0x10
    80002394:	9d848493          	addi	s1,s1,-1576 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002398:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000239a:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000239c:	00015917          	auipc	s2,0x15
    800023a0:	3cc90913          	addi	s2,s2,972 # 80017768 <tickslock>
    800023a4:	a821                	j	800023bc <wakeup+0x40>
      p->state = RUNNABLE;
    800023a6:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800023aa:	8526                	mv	a0,s1
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	918080e7          	jalr	-1768(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023b4:	16848493          	addi	s1,s1,360
    800023b8:	01248e63          	beq	s1,s2,800023d4 <wakeup+0x58>
    acquire(&p->lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	852080e7          	jalr	-1966(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800023c6:	4c9c                	lw	a5,24(s1)
    800023c8:	ff3791e3          	bne	a5,s3,800023aa <wakeup+0x2e>
    800023cc:	749c                	ld	a5,40(s1)
    800023ce:	fd479ee3          	bne	a5,s4,800023aa <wakeup+0x2e>
    800023d2:	bfd1                	j	800023a6 <wakeup+0x2a>
}
    800023d4:	70e2                	ld	ra,56(sp)
    800023d6:	7442                	ld	s0,48(sp)
    800023d8:	74a2                	ld	s1,40(sp)
    800023da:	7902                	ld	s2,32(sp)
    800023dc:	69e2                	ld	s3,24(sp)
    800023de:	6a42                	ld	s4,16(sp)
    800023e0:	6aa2                	ld	s5,8(sp)
    800023e2:	6121                	addi	sp,sp,64
    800023e4:	8082                	ret

00000000800023e6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023e6:	7179                	addi	sp,sp,-48
    800023e8:	f406                	sd	ra,40(sp)
    800023ea:	f022                	sd	s0,32(sp)
    800023ec:	ec26                	sd	s1,24(sp)
    800023ee:	e84a                	sd	s2,16(sp)
    800023f0:	e44e                	sd	s3,8(sp)
    800023f2:	1800                	addi	s0,sp,48
    800023f4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023f6:	00010497          	auipc	s1,0x10
    800023fa:	97248493          	addi	s1,s1,-1678 # 80011d68 <proc>
    800023fe:	00015997          	auipc	s3,0x15
    80002402:	36a98993          	addi	s3,s3,874 # 80017768 <tickslock>
    acquire(&p->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	808080e7          	jalr	-2040(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    80002410:	5c9c                	lw	a5,56(s1)
    80002412:	01278d63          	beq	a5,s2,8000242c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	8ac080e7          	jalr	-1876(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002420:	16848493          	addi	s1,s1,360
    80002424:	ff3491e3          	bne	s1,s3,80002406 <kill+0x20>
  }
  return -1;
    80002428:	557d                	li	a0,-1
    8000242a:	a829                	j	80002444 <kill+0x5e>
      p->killed = 1;
    8000242c:	4785                	li	a5,1
    8000242e:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002430:	4c98                	lw	a4,24(s1)
    80002432:	4785                	li	a5,1
    80002434:	00f70f63          	beq	a4,a5,80002452 <kill+0x6c>
      release(&p->lock);
    80002438:	8526                	mv	a0,s1
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	88a080e7          	jalr	-1910(ra) # 80000cc4 <release>
      return 0;
    80002442:	4501                	li	a0,0
}
    80002444:	70a2                	ld	ra,40(sp)
    80002446:	7402                	ld	s0,32(sp)
    80002448:	64e2                	ld	s1,24(sp)
    8000244a:	6942                	ld	s2,16(sp)
    8000244c:	69a2                	ld	s3,8(sp)
    8000244e:	6145                	addi	sp,sp,48
    80002450:	8082                	ret
        p->state = RUNNABLE;
    80002452:	4789                	li	a5,2
    80002454:	cc9c                	sw	a5,24(s1)
    80002456:	b7cd                	j	80002438 <kill+0x52>

0000000080002458 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002458:	7179                	addi	sp,sp,-48
    8000245a:	f406                	sd	ra,40(sp)
    8000245c:	f022                	sd	s0,32(sp)
    8000245e:	ec26                	sd	s1,24(sp)
    80002460:	e84a                	sd	s2,16(sp)
    80002462:	e44e                	sd	s3,8(sp)
    80002464:	e052                	sd	s4,0(sp)
    80002466:	1800                	addi	s0,sp,48
    80002468:	84aa                	mv	s1,a0
    8000246a:	892e                	mv	s2,a1
    8000246c:	89b2                	mv	s3,a2
    8000246e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	56e080e7          	jalr	1390(ra) # 800019de <myproc>
  if(user_dst){
    80002478:	c08d                	beqz	s1,8000249a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000247a:	86d2                	mv	a3,s4
    8000247c:	864e                	mv	a2,s3
    8000247e:	85ca                	mv	a1,s2
    80002480:	6928                	ld	a0,80(a0)
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	250080e7          	jalr	592(ra) # 800016d2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000248a:	70a2                	ld	ra,40(sp)
    8000248c:	7402                	ld	s0,32(sp)
    8000248e:	64e2                	ld	s1,24(sp)
    80002490:	6942                	ld	s2,16(sp)
    80002492:	69a2                	ld	s3,8(sp)
    80002494:	6a02                	ld	s4,0(sp)
    80002496:	6145                	addi	sp,sp,48
    80002498:	8082                	ret
    memmove((char *)dst, src, len);
    8000249a:	000a061b          	sext.w	a2,s4
    8000249e:	85ce                	mv	a1,s3
    800024a0:	854a                	mv	a0,s2
    800024a2:	fffff097          	auipc	ra,0xfffff
    800024a6:	8ca080e7          	jalr	-1846(ra) # 80000d6c <memmove>
    return 0;
    800024aa:	8526                	mv	a0,s1
    800024ac:	bff9                	j	8000248a <either_copyout+0x32>

00000000800024ae <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024ae:	7179                	addi	sp,sp,-48
    800024b0:	f406                	sd	ra,40(sp)
    800024b2:	f022                	sd	s0,32(sp)
    800024b4:	ec26                	sd	s1,24(sp)
    800024b6:	e84a                	sd	s2,16(sp)
    800024b8:	e44e                	sd	s3,8(sp)
    800024ba:	e052                	sd	s4,0(sp)
    800024bc:	1800                	addi	s0,sp,48
    800024be:	892a                	mv	s2,a0
    800024c0:	84ae                	mv	s1,a1
    800024c2:	89b2                	mv	s3,a2
    800024c4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	518080e7          	jalr	1304(ra) # 800019de <myproc>
  if(user_src){
    800024ce:	c08d                	beqz	s1,800024f0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024d0:	86d2                	mv	a3,s4
    800024d2:	864e                	mv	a2,s3
    800024d4:	85ca                	mv	a1,s2
    800024d6:	6928                	ld	a0,80(a0)
    800024d8:	fffff097          	auipc	ra,0xfffff
    800024dc:	286080e7          	jalr	646(ra) # 8000175e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024e0:	70a2                	ld	ra,40(sp)
    800024e2:	7402                	ld	s0,32(sp)
    800024e4:	64e2                	ld	s1,24(sp)
    800024e6:	6942                	ld	s2,16(sp)
    800024e8:	69a2                	ld	s3,8(sp)
    800024ea:	6a02                	ld	s4,0(sp)
    800024ec:	6145                	addi	sp,sp,48
    800024ee:	8082                	ret
    memmove(dst, (char*)src, len);
    800024f0:	000a061b          	sext.w	a2,s4
    800024f4:	85ce                	mv	a1,s3
    800024f6:	854a                	mv	a0,s2
    800024f8:	fffff097          	auipc	ra,0xfffff
    800024fc:	874080e7          	jalr	-1932(ra) # 80000d6c <memmove>
    return 0;
    80002500:	8526                	mv	a0,s1
    80002502:	bff9                	j	800024e0 <either_copyin+0x32>

0000000080002504 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002504:	715d                	addi	sp,sp,-80
    80002506:	e486                	sd	ra,72(sp)
    80002508:	e0a2                	sd	s0,64(sp)
    8000250a:	fc26                	sd	s1,56(sp)
    8000250c:	f84a                	sd	s2,48(sp)
    8000250e:	f44e                	sd	s3,40(sp)
    80002510:	f052                	sd	s4,32(sp)
    80002512:	ec56                	sd	s5,24(sp)
    80002514:	e85a                	sd	s6,16(sp)
    80002516:	e45e                	sd	s7,8(sp)
    80002518:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000251a:	00006517          	auipc	a0,0x6
    8000251e:	bae50513          	addi	a0,a0,-1106 # 800080c8 <digits+0x88>
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	070080e7          	jalr	112(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000252a:	00010497          	auipc	s1,0x10
    8000252e:	99648493          	addi	s1,s1,-1642 # 80011ec0 <proc+0x158>
    80002532:	00015917          	auipc	s2,0x15
    80002536:	38e90913          	addi	s2,s2,910 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253a:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000253c:	00006997          	auipc	s3,0x6
    80002540:	d2c98993          	addi	s3,s3,-724 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002544:	00006a97          	auipc	s5,0x6
    80002548:	d2ca8a93          	addi	s5,s5,-724 # 80008270 <digits+0x230>
    printf("\n");
    8000254c:	00006a17          	auipc	s4,0x6
    80002550:	b7ca0a13          	addi	s4,s4,-1156 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002554:	00006b97          	auipc	s7,0x6
    80002558:	d54b8b93          	addi	s7,s7,-684 # 800082a8 <states.1705>
    8000255c:	a00d                	j	8000257e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000255e:	ee06a583          	lw	a1,-288(a3)
    80002562:	8556                	mv	a0,s5
    80002564:	ffffe097          	auipc	ra,0xffffe
    80002568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
    printf("\n");
    8000256c:	8552                	mv	a0,s4
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002576:	16848493          	addi	s1,s1,360
    8000257a:	03248163          	beq	s1,s2,8000259c <procdump+0x98>
    if(p->state == UNUSED)
    8000257e:	86a6                	mv	a3,s1
    80002580:	ec04a783          	lw	a5,-320(s1)
    80002584:	dbed                	beqz	a5,80002576 <procdump+0x72>
      state = "???";
    80002586:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002588:	fcfb6be3          	bltu	s6,a5,8000255e <procdump+0x5a>
    8000258c:	1782                	slli	a5,a5,0x20
    8000258e:	9381                	srli	a5,a5,0x20
    80002590:	078e                	slli	a5,a5,0x3
    80002592:	97de                	add	a5,a5,s7
    80002594:	6390                	ld	a2,0(a5)
    80002596:	f661                	bnez	a2,8000255e <procdump+0x5a>
      state = "???";
    80002598:	864e                	mv	a2,s3
    8000259a:	b7d1                	j	8000255e <procdump+0x5a>
  }
}
    8000259c:	60a6                	ld	ra,72(sp)
    8000259e:	6406                	ld	s0,64(sp)
    800025a0:	74e2                	ld	s1,56(sp)
    800025a2:	7942                	ld	s2,48(sp)
    800025a4:	79a2                	ld	s3,40(sp)
    800025a6:	7a02                	ld	s4,32(sp)
    800025a8:	6ae2                	ld	s5,24(sp)
    800025aa:	6b42                	ld	s6,16(sp)
    800025ac:	6ba2                	ld	s7,8(sp)
    800025ae:	6161                	addi	sp,sp,80
    800025b0:	8082                	ret

00000000800025b2 <trace>:

int
trace(int mask)
{
    800025b2:	1101                	addi	sp,sp,-32
    800025b4:	ec06                	sd	ra,24(sp)
    800025b6:	e822                	sd	s0,16(sp)
    800025b8:	e426                	sd	s1,8(sp)
    800025ba:	e04a                	sd	s2,0(sp)
    800025bc:	1000                	addi	s0,sp,32
    800025be:	892a                	mv	s2,a0
  //printf("trace %d\n", mask);
  struct proc *p = myproc();
    800025c0:	fffff097          	auipc	ra,0xfffff
    800025c4:	41e080e7          	jalr	1054(ra) # 800019de <myproc>
    800025c8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	646080e7          	jalr	1606(ra) # 80000c10 <acquire>
  p->tracemask = mask;
    800025d2:	0324ae23          	sw	s2,60(s1)
  release(&p->lock);
    800025d6:	8526                	mv	a0,s1
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	6ec080e7          	jalr	1772(ra) # 80000cc4 <release>
  return 0;
}
    800025e0:	4501                	li	a0,0
    800025e2:	60e2                	ld	ra,24(sp)
    800025e4:	6442                	ld	s0,16(sp)
    800025e6:	64a2                	ld	s1,8(sp)
    800025e8:	6902                	ld	s2,0(sp)
    800025ea:	6105                	addi	sp,sp,32
    800025ec:	8082                	ret

00000000800025ee <swtch>:
    800025ee:	00153023          	sd	ra,0(a0)
    800025f2:	00253423          	sd	sp,8(a0)
    800025f6:	e900                	sd	s0,16(a0)
    800025f8:	ed04                	sd	s1,24(a0)
    800025fa:	03253023          	sd	s2,32(a0)
    800025fe:	03353423          	sd	s3,40(a0)
    80002602:	03453823          	sd	s4,48(a0)
    80002606:	03553c23          	sd	s5,56(a0)
    8000260a:	05653023          	sd	s6,64(a0)
    8000260e:	05753423          	sd	s7,72(a0)
    80002612:	05853823          	sd	s8,80(a0)
    80002616:	05953c23          	sd	s9,88(a0)
    8000261a:	07a53023          	sd	s10,96(a0)
    8000261e:	07b53423          	sd	s11,104(a0)
    80002622:	0005b083          	ld	ra,0(a1)
    80002626:	0085b103          	ld	sp,8(a1)
    8000262a:	6980                	ld	s0,16(a1)
    8000262c:	6d84                	ld	s1,24(a1)
    8000262e:	0205b903          	ld	s2,32(a1)
    80002632:	0285b983          	ld	s3,40(a1)
    80002636:	0305ba03          	ld	s4,48(a1)
    8000263a:	0385ba83          	ld	s5,56(a1)
    8000263e:	0405bb03          	ld	s6,64(a1)
    80002642:	0485bb83          	ld	s7,72(a1)
    80002646:	0505bc03          	ld	s8,80(a1)
    8000264a:	0585bc83          	ld	s9,88(a1)
    8000264e:	0605bd03          	ld	s10,96(a1)
    80002652:	0685bd83          	ld	s11,104(a1)
    80002656:	8082                	ret

0000000080002658 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002658:	1141                	addi	sp,sp,-16
    8000265a:	e406                	sd	ra,8(sp)
    8000265c:	e022                	sd	s0,0(sp)
    8000265e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002660:	00006597          	auipc	a1,0x6
    80002664:	c7058593          	addi	a1,a1,-912 # 800082d0 <states.1705+0x28>
    80002668:	00015517          	auipc	a0,0x15
    8000266c:	10050513          	addi	a0,a0,256 # 80017768 <tickslock>
    80002670:	ffffe097          	auipc	ra,0xffffe
    80002674:	510080e7          	jalr	1296(ra) # 80000b80 <initlock>
}
    80002678:	60a2                	ld	ra,8(sp)
    8000267a:	6402                	ld	s0,0(sp)
    8000267c:	0141                	addi	sp,sp,16
    8000267e:	8082                	ret

0000000080002680 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002680:	1141                	addi	sp,sp,-16
    80002682:	e422                	sd	s0,8(sp)
    80002684:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002686:	00003797          	auipc	a5,0x3
    8000268a:	54a78793          	addi	a5,a5,1354 # 80005bd0 <kernelvec>
    8000268e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002692:	6422                	ld	s0,8(sp)
    80002694:	0141                	addi	sp,sp,16
    80002696:	8082                	ret

0000000080002698 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002698:	1141                	addi	sp,sp,-16
    8000269a:	e406                	sd	ra,8(sp)
    8000269c:	e022                	sd	s0,0(sp)
    8000269e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026a0:	fffff097          	auipc	ra,0xfffff
    800026a4:	33e080e7          	jalr	830(ra) # 800019de <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026a8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026ac:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026ae:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026b2:	00005617          	auipc	a2,0x5
    800026b6:	94e60613          	addi	a2,a2,-1714 # 80007000 <_trampoline>
    800026ba:	00005697          	auipc	a3,0x5
    800026be:	94668693          	addi	a3,a3,-1722 # 80007000 <_trampoline>
    800026c2:	8e91                	sub	a3,a3,a2
    800026c4:	040007b7          	lui	a5,0x4000
    800026c8:	17fd                	addi	a5,a5,-1
    800026ca:	07b2                	slli	a5,a5,0xc
    800026cc:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026ce:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026d2:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026d4:	180026f3          	csrr	a3,satp
    800026d8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026da:	6d38                	ld	a4,88(a0)
    800026dc:	6134                	ld	a3,64(a0)
    800026de:	6585                	lui	a1,0x1
    800026e0:	96ae                	add	a3,a3,a1
    800026e2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026e4:	6d38                	ld	a4,88(a0)
    800026e6:	00000697          	auipc	a3,0x0
    800026ea:	13868693          	addi	a3,a3,312 # 8000281e <usertrap>
    800026ee:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026f0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026f2:	8692                	mv	a3,tp
    800026f4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026f6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026fa:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026fe:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002702:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002706:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002708:	6f18                	ld	a4,24(a4)
    8000270a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000270e:	692c                	ld	a1,80(a0)
    80002710:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002712:	00005717          	auipc	a4,0x5
    80002716:	97e70713          	addi	a4,a4,-1666 # 80007090 <userret>
    8000271a:	8f11                	sub	a4,a4,a2
    8000271c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000271e:	577d                	li	a4,-1
    80002720:	177e                	slli	a4,a4,0x3f
    80002722:	8dd9                	or	a1,a1,a4
    80002724:	02000537          	lui	a0,0x2000
    80002728:	157d                	addi	a0,a0,-1
    8000272a:	0536                	slli	a0,a0,0xd
    8000272c:	9782                	jalr	a5
}
    8000272e:	60a2                	ld	ra,8(sp)
    80002730:	6402                	ld	s0,0(sp)
    80002732:	0141                	addi	sp,sp,16
    80002734:	8082                	ret

0000000080002736 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002736:	1101                	addi	sp,sp,-32
    80002738:	ec06                	sd	ra,24(sp)
    8000273a:	e822                	sd	s0,16(sp)
    8000273c:	e426                	sd	s1,8(sp)
    8000273e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002740:	00015497          	auipc	s1,0x15
    80002744:	02848493          	addi	s1,s1,40 # 80017768 <tickslock>
    80002748:	8526                	mv	a0,s1
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	4c6080e7          	jalr	1222(ra) # 80000c10 <acquire>
  ticks++;
    80002752:	00007517          	auipc	a0,0x7
    80002756:	8ce50513          	addi	a0,a0,-1842 # 80009020 <ticks>
    8000275a:	411c                	lw	a5,0(a0)
    8000275c:	2785                	addiw	a5,a5,1
    8000275e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002760:	00000097          	auipc	ra,0x0
    80002764:	c1c080e7          	jalr	-996(ra) # 8000237c <wakeup>
  release(&tickslock);
    80002768:	8526                	mv	a0,s1
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	55a080e7          	jalr	1370(ra) # 80000cc4 <release>
}
    80002772:	60e2                	ld	ra,24(sp)
    80002774:	6442                	ld	s0,16(sp)
    80002776:	64a2                	ld	s1,8(sp)
    80002778:	6105                	addi	sp,sp,32
    8000277a:	8082                	ret

000000008000277c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000277c:	1101                	addi	sp,sp,-32
    8000277e:	ec06                	sd	ra,24(sp)
    80002780:	e822                	sd	s0,16(sp)
    80002782:	e426                	sd	s1,8(sp)
    80002784:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002786:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000278a:	00074d63          	bltz	a4,800027a4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000278e:	57fd                	li	a5,-1
    80002790:	17fe                	slli	a5,a5,0x3f
    80002792:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002794:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002796:	06f70363          	beq	a4,a5,800027fc <devintr+0x80>
  }
}
    8000279a:	60e2                	ld	ra,24(sp)
    8000279c:	6442                	ld	s0,16(sp)
    8000279e:	64a2                	ld	s1,8(sp)
    800027a0:	6105                	addi	sp,sp,32
    800027a2:	8082                	ret
     (scause & 0xff) == 9){
    800027a4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027a8:	46a5                	li	a3,9
    800027aa:	fed792e3          	bne	a5,a3,8000278e <devintr+0x12>
    int irq = plic_claim();
    800027ae:	00003097          	auipc	ra,0x3
    800027b2:	52a080e7          	jalr	1322(ra) # 80005cd8 <plic_claim>
    800027b6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027b8:	47a9                	li	a5,10
    800027ba:	02f50763          	beq	a0,a5,800027e8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027be:	4785                	li	a5,1
    800027c0:	02f50963          	beq	a0,a5,800027f2 <devintr+0x76>
    return 1;
    800027c4:	4505                	li	a0,1
    } else if(irq){
    800027c6:	d8f1                	beqz	s1,8000279a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027c8:	85a6                	mv	a1,s1
    800027ca:	00006517          	auipc	a0,0x6
    800027ce:	b0e50513          	addi	a0,a0,-1266 # 800082d8 <states.1705+0x30>
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	dc0080e7          	jalr	-576(ra) # 80000592 <printf>
      plic_complete(irq);
    800027da:	8526                	mv	a0,s1
    800027dc:	00003097          	auipc	ra,0x3
    800027e0:	520080e7          	jalr	1312(ra) # 80005cfc <plic_complete>
    return 1;
    800027e4:	4505                	li	a0,1
    800027e6:	bf55                	j	8000279a <devintr+0x1e>
      uartintr();
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	1ec080e7          	jalr	492(ra) # 800009d4 <uartintr>
    800027f0:	b7ed                	j	800027da <devintr+0x5e>
      virtio_disk_intr();
    800027f2:	00004097          	auipc	ra,0x4
    800027f6:	9a4080e7          	jalr	-1628(ra) # 80006196 <virtio_disk_intr>
    800027fa:	b7c5                	j	800027da <devintr+0x5e>
    if(cpuid() == 0){
    800027fc:	fffff097          	auipc	ra,0xfffff
    80002800:	1b6080e7          	jalr	438(ra) # 800019b2 <cpuid>
    80002804:	c901                	beqz	a0,80002814 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002806:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000280a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000280c:	14479073          	csrw	sip,a5
    return 2;
    80002810:	4509                	li	a0,2
    80002812:	b761                	j	8000279a <devintr+0x1e>
      clockintr();
    80002814:	00000097          	auipc	ra,0x0
    80002818:	f22080e7          	jalr	-222(ra) # 80002736 <clockintr>
    8000281c:	b7ed                	j	80002806 <devintr+0x8a>

000000008000281e <usertrap>:
{
    8000281e:	1101                	addi	sp,sp,-32
    80002820:	ec06                	sd	ra,24(sp)
    80002822:	e822                	sd	s0,16(sp)
    80002824:	e426                	sd	s1,8(sp)
    80002826:	e04a                	sd	s2,0(sp)
    80002828:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000282a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000282e:	1007f793          	andi	a5,a5,256
    80002832:	e3ad                	bnez	a5,80002894 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002834:	00003797          	auipc	a5,0x3
    80002838:	39c78793          	addi	a5,a5,924 # 80005bd0 <kernelvec>
    8000283c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002840:	fffff097          	auipc	ra,0xfffff
    80002844:	19e080e7          	jalr	414(ra) # 800019de <myproc>
    80002848:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000284a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000284c:	14102773          	csrr	a4,sepc
    80002850:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002852:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002856:	47a1                	li	a5,8
    80002858:	04f71c63          	bne	a4,a5,800028b0 <usertrap+0x92>
    if(p->killed)
    8000285c:	591c                	lw	a5,48(a0)
    8000285e:	e3b9                	bnez	a5,800028a4 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002860:	6cb8                	ld	a4,88(s1)
    80002862:	6f1c                	ld	a5,24(a4)
    80002864:	0791                	addi	a5,a5,4
    80002866:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002868:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000286c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002870:	10079073          	csrw	sstatus,a5
    syscall();
    80002874:	00000097          	auipc	ra,0x0
    80002878:	2e0080e7          	jalr	736(ra) # 80002b54 <syscall>
  if(p->killed)
    8000287c:	589c                	lw	a5,48(s1)
    8000287e:	ebc1                	bnez	a5,8000290e <usertrap+0xf0>
  usertrapret();
    80002880:	00000097          	auipc	ra,0x0
    80002884:	e18080e7          	jalr	-488(ra) # 80002698 <usertrapret>
}
    80002888:	60e2                	ld	ra,24(sp)
    8000288a:	6442                	ld	s0,16(sp)
    8000288c:	64a2                	ld	s1,8(sp)
    8000288e:	6902                	ld	s2,0(sp)
    80002890:	6105                	addi	sp,sp,32
    80002892:	8082                	ret
    panic("usertrap: not from user mode");
    80002894:	00006517          	auipc	a0,0x6
    80002898:	a6450513          	addi	a0,a0,-1436 # 800082f8 <states.1705+0x50>
    8000289c:	ffffe097          	auipc	ra,0xffffe
    800028a0:	cac080e7          	jalr	-852(ra) # 80000548 <panic>
      exit(-1);
    800028a4:	557d                	li	a0,-1
    800028a6:	00000097          	auipc	ra,0x0
    800028aa:	80a080e7          	jalr	-2038(ra) # 800020b0 <exit>
    800028ae:	bf4d                	j	80002860 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028b0:	00000097          	auipc	ra,0x0
    800028b4:	ecc080e7          	jalr	-308(ra) # 8000277c <devintr>
    800028b8:	892a                	mv	s2,a0
    800028ba:	c501                	beqz	a0,800028c2 <usertrap+0xa4>
  if(p->killed)
    800028bc:	589c                	lw	a5,48(s1)
    800028be:	c3a1                	beqz	a5,800028fe <usertrap+0xe0>
    800028c0:	a815                	j	800028f4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028c6:	5c90                	lw	a2,56(s1)
    800028c8:	00006517          	auipc	a0,0x6
    800028cc:	a5050513          	addi	a0,a0,-1456 # 80008318 <states.1705+0x70>
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	cc2080e7          	jalr	-830(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028d8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028dc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028e0:	00006517          	auipc	a0,0x6
    800028e4:	a6850513          	addi	a0,a0,-1432 # 80008348 <states.1705+0xa0>
    800028e8:	ffffe097          	auipc	ra,0xffffe
    800028ec:	caa080e7          	jalr	-854(ra) # 80000592 <printf>
    p->killed = 1;
    800028f0:	4785                	li	a5,1
    800028f2:	d89c                	sw	a5,48(s1)
    exit(-1);
    800028f4:	557d                	li	a0,-1
    800028f6:	fffff097          	auipc	ra,0xfffff
    800028fa:	7ba080e7          	jalr	1978(ra) # 800020b0 <exit>
  if(which_dev == 2)
    800028fe:	4789                	li	a5,2
    80002900:	f8f910e3          	bne	s2,a5,80002880 <usertrap+0x62>
    yield();
    80002904:	00000097          	auipc	ra,0x0
    80002908:	8b6080e7          	jalr	-1866(ra) # 800021ba <yield>
    8000290c:	bf95                	j	80002880 <usertrap+0x62>
  int which_dev = 0;
    8000290e:	4901                	li	s2,0
    80002910:	b7d5                	j	800028f4 <usertrap+0xd6>

0000000080002912 <kerneltrap>:
{
    80002912:	7179                	addi	sp,sp,-48
    80002914:	f406                	sd	ra,40(sp)
    80002916:	f022                	sd	s0,32(sp)
    80002918:	ec26                	sd	s1,24(sp)
    8000291a:	e84a                	sd	s2,16(sp)
    8000291c:	e44e                	sd	s3,8(sp)
    8000291e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002920:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002924:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002928:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000292c:	1004f793          	andi	a5,s1,256
    80002930:	cb85                	beqz	a5,80002960 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002932:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002936:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002938:	ef85                	bnez	a5,80002970 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000293a:	00000097          	auipc	ra,0x0
    8000293e:	e42080e7          	jalr	-446(ra) # 8000277c <devintr>
    80002942:	cd1d                	beqz	a0,80002980 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002944:	4789                	li	a5,2
    80002946:	06f50a63          	beq	a0,a5,800029ba <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000294a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000294e:	10049073          	csrw	sstatus,s1
}
    80002952:	70a2                	ld	ra,40(sp)
    80002954:	7402                	ld	s0,32(sp)
    80002956:	64e2                	ld	s1,24(sp)
    80002958:	6942                	ld	s2,16(sp)
    8000295a:	69a2                	ld	s3,8(sp)
    8000295c:	6145                	addi	sp,sp,48
    8000295e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002960:	00006517          	auipc	a0,0x6
    80002964:	a0850513          	addi	a0,a0,-1528 # 80008368 <states.1705+0xc0>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	be0080e7          	jalr	-1056(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002970:	00006517          	auipc	a0,0x6
    80002974:	a2050513          	addi	a0,a0,-1504 # 80008390 <states.1705+0xe8>
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	bd0080e7          	jalr	-1072(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002980:	85ce                	mv	a1,s3
    80002982:	00006517          	auipc	a0,0x6
    80002986:	a2e50513          	addi	a0,a0,-1490 # 800083b0 <states.1705+0x108>
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	c08080e7          	jalr	-1016(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002992:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002996:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000299a:	00006517          	auipc	a0,0x6
    8000299e:	a2650513          	addi	a0,a0,-1498 # 800083c0 <states.1705+0x118>
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	bf0080e7          	jalr	-1040(ra) # 80000592 <printf>
    panic("kerneltrap");
    800029aa:	00006517          	auipc	a0,0x6
    800029ae:	a2e50513          	addi	a0,a0,-1490 # 800083d8 <states.1705+0x130>
    800029b2:	ffffe097          	auipc	ra,0xffffe
    800029b6:	b96080e7          	jalr	-1130(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029ba:	fffff097          	auipc	ra,0xfffff
    800029be:	024080e7          	jalr	36(ra) # 800019de <myproc>
    800029c2:	d541                	beqz	a0,8000294a <kerneltrap+0x38>
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	01a080e7          	jalr	26(ra) # 800019de <myproc>
    800029cc:	4d18                	lw	a4,24(a0)
    800029ce:	478d                	li	a5,3
    800029d0:	f6f71de3          	bne	a4,a5,8000294a <kerneltrap+0x38>
    yield();
    800029d4:	fffff097          	auipc	ra,0xfffff
    800029d8:	7e6080e7          	jalr	2022(ra) # 800021ba <yield>
    800029dc:	b7bd                	j	8000294a <kerneltrap+0x38>

00000000800029de <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029de:	1101                	addi	sp,sp,-32
    800029e0:	ec06                	sd	ra,24(sp)
    800029e2:	e822                	sd	s0,16(sp)
    800029e4:	e426                	sd	s1,8(sp)
    800029e6:	1000                	addi	s0,sp,32
    800029e8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029ea:	fffff097          	auipc	ra,0xfffff
    800029ee:	ff4080e7          	jalr	-12(ra) # 800019de <myproc>
  switch (n) {
    800029f2:	4795                	li	a5,5
    800029f4:	0497e163          	bltu	a5,s1,80002a36 <argraw+0x58>
    800029f8:	048a                	slli	s1,s1,0x2
    800029fa:	00006717          	auipc	a4,0x6
    800029fe:	ad670713          	addi	a4,a4,-1322 # 800084d0 <states.1705+0x228>
    80002a02:	94ba                	add	s1,s1,a4
    80002a04:	409c                	lw	a5,0(s1)
    80002a06:	97ba                	add	a5,a5,a4
    80002a08:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a0a:	6d3c                	ld	a5,88(a0)
    80002a0c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a0e:	60e2                	ld	ra,24(sp)
    80002a10:	6442                	ld	s0,16(sp)
    80002a12:	64a2                	ld	s1,8(sp)
    80002a14:	6105                	addi	sp,sp,32
    80002a16:	8082                	ret
    return p->trapframe->a1;
    80002a18:	6d3c                	ld	a5,88(a0)
    80002a1a:	7fa8                	ld	a0,120(a5)
    80002a1c:	bfcd                	j	80002a0e <argraw+0x30>
    return p->trapframe->a2;
    80002a1e:	6d3c                	ld	a5,88(a0)
    80002a20:	63c8                	ld	a0,128(a5)
    80002a22:	b7f5                	j	80002a0e <argraw+0x30>
    return p->trapframe->a3;
    80002a24:	6d3c                	ld	a5,88(a0)
    80002a26:	67c8                	ld	a0,136(a5)
    80002a28:	b7dd                	j	80002a0e <argraw+0x30>
    return p->trapframe->a4;
    80002a2a:	6d3c                	ld	a5,88(a0)
    80002a2c:	6bc8                	ld	a0,144(a5)
    80002a2e:	b7c5                	j	80002a0e <argraw+0x30>
    return p->trapframe->a5;
    80002a30:	6d3c                	ld	a5,88(a0)
    80002a32:	6fc8                	ld	a0,152(a5)
    80002a34:	bfe9                	j	80002a0e <argraw+0x30>
  panic("argraw");
    80002a36:	00006517          	auipc	a0,0x6
    80002a3a:	9b250513          	addi	a0,a0,-1614 # 800083e8 <states.1705+0x140>
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	b0a080e7          	jalr	-1270(ra) # 80000548 <panic>

0000000080002a46 <fetchaddr>:
{
    80002a46:	1101                	addi	sp,sp,-32
    80002a48:	ec06                	sd	ra,24(sp)
    80002a4a:	e822                	sd	s0,16(sp)
    80002a4c:	e426                	sd	s1,8(sp)
    80002a4e:	e04a                	sd	s2,0(sp)
    80002a50:	1000                	addi	s0,sp,32
    80002a52:	84aa                	mv	s1,a0
    80002a54:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a56:	fffff097          	auipc	ra,0xfffff
    80002a5a:	f88080e7          	jalr	-120(ra) # 800019de <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a5e:	653c                	ld	a5,72(a0)
    80002a60:	02f4f863          	bgeu	s1,a5,80002a90 <fetchaddr+0x4a>
    80002a64:	00848713          	addi	a4,s1,8
    80002a68:	02e7e663          	bltu	a5,a4,80002a94 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a6c:	46a1                	li	a3,8
    80002a6e:	8626                	mv	a2,s1
    80002a70:	85ca                	mv	a1,s2
    80002a72:	6928                	ld	a0,80(a0)
    80002a74:	fffff097          	auipc	ra,0xfffff
    80002a78:	cea080e7          	jalr	-790(ra) # 8000175e <copyin>
    80002a7c:	00a03533          	snez	a0,a0
    80002a80:	40a00533          	neg	a0,a0
}
    80002a84:	60e2                	ld	ra,24(sp)
    80002a86:	6442                	ld	s0,16(sp)
    80002a88:	64a2                	ld	s1,8(sp)
    80002a8a:	6902                	ld	s2,0(sp)
    80002a8c:	6105                	addi	sp,sp,32
    80002a8e:	8082                	ret
    return -1;
    80002a90:	557d                	li	a0,-1
    80002a92:	bfcd                	j	80002a84 <fetchaddr+0x3e>
    80002a94:	557d                	li	a0,-1
    80002a96:	b7fd                	j	80002a84 <fetchaddr+0x3e>

0000000080002a98 <fetchstr>:
{
    80002a98:	7179                	addi	sp,sp,-48
    80002a9a:	f406                	sd	ra,40(sp)
    80002a9c:	f022                	sd	s0,32(sp)
    80002a9e:	ec26                	sd	s1,24(sp)
    80002aa0:	e84a                	sd	s2,16(sp)
    80002aa2:	e44e                	sd	s3,8(sp)
    80002aa4:	1800                	addi	s0,sp,48
    80002aa6:	892a                	mv	s2,a0
    80002aa8:	84ae                	mv	s1,a1
    80002aaa:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002aac:	fffff097          	auipc	ra,0xfffff
    80002ab0:	f32080e7          	jalr	-206(ra) # 800019de <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ab4:	86ce                	mv	a3,s3
    80002ab6:	864a                	mv	a2,s2
    80002ab8:	85a6                	mv	a1,s1
    80002aba:	6928                	ld	a0,80(a0)
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	d2e080e7          	jalr	-722(ra) # 800017ea <copyinstr>
  if(err < 0)
    80002ac4:	00054763          	bltz	a0,80002ad2 <fetchstr+0x3a>
  return strlen(buf);
    80002ac8:	8526                	mv	a0,s1
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	3ca080e7          	jalr	970(ra) # 80000e94 <strlen>
}
    80002ad2:	70a2                	ld	ra,40(sp)
    80002ad4:	7402                	ld	s0,32(sp)
    80002ad6:	64e2                	ld	s1,24(sp)
    80002ad8:	6942                	ld	s2,16(sp)
    80002ada:	69a2                	ld	s3,8(sp)
    80002adc:	6145                	addi	sp,sp,48
    80002ade:	8082                	ret

0000000080002ae0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ae0:	1101                	addi	sp,sp,-32
    80002ae2:	ec06                	sd	ra,24(sp)
    80002ae4:	e822                	sd	s0,16(sp)
    80002ae6:	e426                	sd	s1,8(sp)
    80002ae8:	1000                	addi	s0,sp,32
    80002aea:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aec:	00000097          	auipc	ra,0x0
    80002af0:	ef2080e7          	jalr	-270(ra) # 800029de <argraw>
    80002af4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002af6:	4501                	li	a0,0
    80002af8:	60e2                	ld	ra,24(sp)
    80002afa:	6442                	ld	s0,16(sp)
    80002afc:	64a2                	ld	s1,8(sp)
    80002afe:	6105                	addi	sp,sp,32
    80002b00:	8082                	ret

0000000080002b02 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b02:	1101                	addi	sp,sp,-32
    80002b04:	ec06                	sd	ra,24(sp)
    80002b06:	e822                	sd	s0,16(sp)
    80002b08:	e426                	sd	s1,8(sp)
    80002b0a:	1000                	addi	s0,sp,32
    80002b0c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b0e:	00000097          	auipc	ra,0x0
    80002b12:	ed0080e7          	jalr	-304(ra) # 800029de <argraw>
    80002b16:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b18:	4501                	li	a0,0
    80002b1a:	60e2                	ld	ra,24(sp)
    80002b1c:	6442                	ld	s0,16(sp)
    80002b1e:	64a2                	ld	s1,8(sp)
    80002b20:	6105                	addi	sp,sp,32
    80002b22:	8082                	ret

0000000080002b24 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b24:	1101                	addi	sp,sp,-32
    80002b26:	ec06                	sd	ra,24(sp)
    80002b28:	e822                	sd	s0,16(sp)
    80002b2a:	e426                	sd	s1,8(sp)
    80002b2c:	e04a                	sd	s2,0(sp)
    80002b2e:	1000                	addi	s0,sp,32
    80002b30:	84ae                	mv	s1,a1
    80002b32:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b34:	00000097          	auipc	ra,0x0
    80002b38:	eaa080e7          	jalr	-342(ra) # 800029de <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b3c:	864a                	mv	a2,s2
    80002b3e:	85a6                	mv	a1,s1
    80002b40:	00000097          	auipc	ra,0x0
    80002b44:	f58080e7          	jalr	-168(ra) # 80002a98 <fetchstr>
}
    80002b48:	60e2                	ld	ra,24(sp)
    80002b4a:	6442                	ld	s0,16(sp)
    80002b4c:	64a2                	ld	s1,8(sp)
    80002b4e:	6902                	ld	s2,0(sp)
    80002b50:	6105                	addi	sp,sp,32
    80002b52:	8082                	ret

0000000080002b54 <syscall>:
};
//static int syscallCounts = 21;

void
syscall(void)
{
    80002b54:	7139                	addi	sp,sp,-64
    80002b56:	fc06                	sd	ra,56(sp)
    80002b58:	f822                	sd	s0,48(sp)
    80002b5a:	f426                	sd	s1,40(sp)
    80002b5c:	f04a                	sd	s2,32(sp)
    80002b5e:	ec4e                	sd	s3,24(sp)
    80002b60:	e852                	sd	s4,16(sp)
    80002b62:	e456                	sd	s5,8(sp)
    80002b64:	0080                	addi	s0,sp,64
  int num;
  int mask; //ysw : use for trap
  struct proc *p = myproc();
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	e78080e7          	jalr	-392(ra) # 800019de <myproc>
    80002b6e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b70:	05853903          	ld	s2,88(a0)
    80002b74:	0a893783          	ld	a5,168(s2)
    80002b78:	00078a1b          	sext.w	s4,a5
  mask = p->tracemask;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b7c:	37fd                	addiw	a5,a5,-1
    80002b7e:	4755                	li	a4,21
    80002b80:	06f76363          	bltu	a4,a5,80002be6 <syscall+0x92>
    80002b84:	003a1713          	slli	a4,s4,0x3
    80002b88:	00006797          	auipc	a5,0x6
    80002b8c:	96078793          	addi	a5,a5,-1696 # 800084e8 <syscalls>
    80002b90:	97ba                	add	a5,a5,a4
    80002b92:	639c                	ld	a5,0(a5)
    80002b94:	cba9                	beqz	a5,80002be6 <syscall+0x92>
  mask = p->tracemask;
    80002b96:	03c52983          	lw	s3,60(a0)
    //printf("%d : system call %s : mask %d\n", p->pid, syscallnumber_to_name[num], mask);
    int temp = p->trapframe->a0;
    80002b9a:	07093a83          	ld	s5,112(s2)
    p->trapframe->a0 = syscalls[num]();
    80002b9e:	9782                	jalr	a5
    80002ba0:	06a93823          	sd	a0,112(s2)
    if((mask & (1<<num)) || (num == SYS_trace && (temp & (1<<num)))) {
    80002ba4:	4149d9bb          	sraw	s3,s3,s4
    80002ba8:	0019f993          	andi	s3,s3,1
    80002bac:	00099963          	bnez	s3,80002bbe <syscall+0x6a>
    80002bb0:	47d9                	li	a5,22
    80002bb2:	04fa1963          	bne	s4,a5,80002c04 <syscall+0xb0>
    80002bb6:	029a9793          	slli	a5,s5,0x29
    80002bba:	0407d563          	bgez	a5,80002c04 <syscall+0xb0>
      printf("%d: syscall %s -> %d\n", p->pid, syscallnumber_to_name[num], p->trapframe->a0);
    80002bbe:	6cb8                	ld	a4,88(s1)
    80002bc0:	0a0e                	slli	s4,s4,0x3
    80002bc2:	00006797          	auipc	a5,0x6
    80002bc6:	92678793          	addi	a5,a5,-1754 # 800084e8 <syscalls>
    80002bca:	9a3e                	add	s4,s4,a5
    80002bcc:	7b34                	ld	a3,112(a4)
    80002bce:	0b8a3603          	ld	a2,184(s4)
    80002bd2:	5c8c                	lw	a1,56(s1)
    80002bd4:	00006517          	auipc	a0,0x6
    80002bd8:	81c50513          	addi	a0,a0,-2020 # 800083f0 <states.1705+0x148>
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	9b6080e7          	jalr	-1610(ra) # 80000592 <printf>
    80002be4:	a005                	j	80002c04 <syscall+0xb0>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002be6:	86d2                	mv	a3,s4
    80002be8:	15848613          	addi	a2,s1,344
    80002bec:	5c8c                	lw	a1,56(s1)
    80002bee:	00006517          	auipc	a0,0x6
    80002bf2:	81a50513          	addi	a0,a0,-2022 # 80008408 <states.1705+0x160>
    80002bf6:	ffffe097          	auipc	ra,0xffffe
    80002bfa:	99c080e7          	jalr	-1636(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bfe:	6cbc                	ld	a5,88(s1)
    80002c00:	577d                	li	a4,-1
    80002c02:	fbb8                	sd	a4,112(a5)
  }
    80002c04:	70e2                	ld	ra,56(sp)
    80002c06:	7442                	ld	s0,48(sp)
    80002c08:	74a2                	ld	s1,40(sp)
    80002c0a:	7902                	ld	s2,32(sp)
    80002c0c:	69e2                	ld	s3,24(sp)
    80002c0e:	6a42                	ld	s4,16(sp)
    80002c10:	6aa2                	ld	s5,8(sp)
    80002c12:	6121                	addi	sp,sp,64
    80002c14:	8082                	ret

0000000080002c16 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c16:	1101                	addi	sp,sp,-32
    80002c18:	ec06                	sd	ra,24(sp)
    80002c1a:	e822                	sd	s0,16(sp)
    80002c1c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c1e:	fec40593          	addi	a1,s0,-20
    80002c22:	4501                	li	a0,0
    80002c24:	00000097          	auipc	ra,0x0
    80002c28:	ebc080e7          	jalr	-324(ra) # 80002ae0 <argint>
    return -1;
    80002c2c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c2e:	00054963          	bltz	a0,80002c40 <sys_exit+0x2a>
  exit(n);
    80002c32:	fec42503          	lw	a0,-20(s0)
    80002c36:	fffff097          	auipc	ra,0xfffff
    80002c3a:	47a080e7          	jalr	1146(ra) # 800020b0 <exit>
  return 0;  // not reached
    80002c3e:	4781                	li	a5,0
}
    80002c40:	853e                	mv	a0,a5
    80002c42:	60e2                	ld	ra,24(sp)
    80002c44:	6442                	ld	s0,16(sp)
    80002c46:	6105                	addi	sp,sp,32
    80002c48:	8082                	ret

0000000080002c4a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c4a:	1141                	addi	sp,sp,-16
    80002c4c:	e406                	sd	ra,8(sp)
    80002c4e:	e022                	sd	s0,0(sp)
    80002c50:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c52:	fffff097          	auipc	ra,0xfffff
    80002c56:	d8c080e7          	jalr	-628(ra) # 800019de <myproc>
}
    80002c5a:	5d08                	lw	a0,56(a0)
    80002c5c:	60a2                	ld	ra,8(sp)
    80002c5e:	6402                	ld	s0,0(sp)
    80002c60:	0141                	addi	sp,sp,16
    80002c62:	8082                	ret

0000000080002c64 <sys_fork>:

uint64
sys_fork(void)
{
    80002c64:	1141                	addi	sp,sp,-16
    80002c66:	e406                	sd	ra,8(sp)
    80002c68:	e022                	sd	s0,0(sp)
    80002c6a:	0800                	addi	s0,sp,16
  return fork();
    80002c6c:	fffff097          	auipc	ra,0xfffff
    80002c70:	136080e7          	jalr	310(ra) # 80001da2 <fork>
}
    80002c74:	60a2                	ld	ra,8(sp)
    80002c76:	6402                	ld	s0,0(sp)
    80002c78:	0141                	addi	sp,sp,16
    80002c7a:	8082                	ret

0000000080002c7c <sys_wait>:

uint64
sys_wait(void)
{
    80002c7c:	1101                	addi	sp,sp,-32
    80002c7e:	ec06                	sd	ra,24(sp)
    80002c80:	e822                	sd	s0,16(sp)
    80002c82:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c84:	fe840593          	addi	a1,s0,-24
    80002c88:	4501                	li	a0,0
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	e78080e7          	jalr	-392(ra) # 80002b02 <argaddr>
    80002c92:	87aa                	mv	a5,a0
    return -1;
    80002c94:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c96:	0007c863          	bltz	a5,80002ca6 <sys_wait+0x2a>
  return wait(p);
    80002c9a:	fe843503          	ld	a0,-24(s0)
    80002c9e:	fffff097          	auipc	ra,0xfffff
    80002ca2:	5d6080e7          	jalr	1494(ra) # 80002274 <wait>
}
    80002ca6:	60e2                	ld	ra,24(sp)
    80002ca8:	6442                	ld	s0,16(sp)
    80002caa:	6105                	addi	sp,sp,32
    80002cac:	8082                	ret

0000000080002cae <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cae:	7179                	addi	sp,sp,-48
    80002cb0:	f406                	sd	ra,40(sp)
    80002cb2:	f022                	sd	s0,32(sp)
    80002cb4:	ec26                	sd	s1,24(sp)
    80002cb6:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cb8:	fdc40593          	addi	a1,s0,-36
    80002cbc:	4501                	li	a0,0
    80002cbe:	00000097          	auipc	ra,0x0
    80002cc2:	e22080e7          	jalr	-478(ra) # 80002ae0 <argint>
    80002cc6:	87aa                	mv	a5,a0
    return -1;
    80002cc8:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002cca:	0207c063          	bltz	a5,80002cea <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002cce:	fffff097          	auipc	ra,0xfffff
    80002cd2:	d10080e7          	jalr	-752(ra) # 800019de <myproc>
    80002cd6:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002cd8:	fdc42503          	lw	a0,-36(s0)
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	052080e7          	jalr	82(ra) # 80001d2e <growproc>
    80002ce4:	00054863          	bltz	a0,80002cf4 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002ce8:	8526                	mv	a0,s1
}
    80002cea:	70a2                	ld	ra,40(sp)
    80002cec:	7402                	ld	s0,32(sp)
    80002cee:	64e2                	ld	s1,24(sp)
    80002cf0:	6145                	addi	sp,sp,48
    80002cf2:	8082                	ret
    return -1;
    80002cf4:	557d                	li	a0,-1
    80002cf6:	bfd5                	j	80002cea <sys_sbrk+0x3c>

0000000080002cf8 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cf8:	7139                	addi	sp,sp,-64
    80002cfa:	fc06                	sd	ra,56(sp)
    80002cfc:	f822                	sd	s0,48(sp)
    80002cfe:	f426                	sd	s1,40(sp)
    80002d00:	f04a                	sd	s2,32(sp)
    80002d02:	ec4e                	sd	s3,24(sp)
    80002d04:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d06:	fcc40593          	addi	a1,s0,-52
    80002d0a:	4501                	li	a0,0
    80002d0c:	00000097          	auipc	ra,0x0
    80002d10:	dd4080e7          	jalr	-556(ra) # 80002ae0 <argint>
    return -1;
    80002d14:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d16:	06054563          	bltz	a0,80002d80 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d1a:	00015517          	auipc	a0,0x15
    80002d1e:	a4e50513          	addi	a0,a0,-1458 # 80017768 <tickslock>
    80002d22:	ffffe097          	auipc	ra,0xffffe
    80002d26:	eee080e7          	jalr	-274(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002d2a:	00006917          	auipc	s2,0x6
    80002d2e:	2f692903          	lw	s2,758(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002d32:	fcc42783          	lw	a5,-52(s0)
    80002d36:	cf85                	beqz	a5,80002d6e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d38:	00015997          	auipc	s3,0x15
    80002d3c:	a3098993          	addi	s3,s3,-1488 # 80017768 <tickslock>
    80002d40:	00006497          	auipc	s1,0x6
    80002d44:	2e048493          	addi	s1,s1,736 # 80009020 <ticks>
    if(myproc()->killed){
    80002d48:	fffff097          	auipc	ra,0xfffff
    80002d4c:	c96080e7          	jalr	-874(ra) # 800019de <myproc>
    80002d50:	591c                	lw	a5,48(a0)
    80002d52:	ef9d                	bnez	a5,80002d90 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d54:	85ce                	mv	a1,s3
    80002d56:	8526                	mv	a0,s1
    80002d58:	fffff097          	auipc	ra,0xfffff
    80002d5c:	49e080e7          	jalr	1182(ra) # 800021f6 <sleep>
  while(ticks - ticks0 < n){
    80002d60:	409c                	lw	a5,0(s1)
    80002d62:	412787bb          	subw	a5,a5,s2
    80002d66:	fcc42703          	lw	a4,-52(s0)
    80002d6a:	fce7efe3          	bltu	a5,a4,80002d48 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d6e:	00015517          	auipc	a0,0x15
    80002d72:	9fa50513          	addi	a0,a0,-1542 # 80017768 <tickslock>
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	f4e080e7          	jalr	-178(ra) # 80000cc4 <release>
  return 0;
    80002d7e:	4781                	li	a5,0
}
    80002d80:	853e                	mv	a0,a5
    80002d82:	70e2                	ld	ra,56(sp)
    80002d84:	7442                	ld	s0,48(sp)
    80002d86:	74a2                	ld	s1,40(sp)
    80002d88:	7902                	ld	s2,32(sp)
    80002d8a:	69e2                	ld	s3,24(sp)
    80002d8c:	6121                	addi	sp,sp,64
    80002d8e:	8082                	ret
      release(&tickslock);
    80002d90:	00015517          	auipc	a0,0x15
    80002d94:	9d850513          	addi	a0,a0,-1576 # 80017768 <tickslock>
    80002d98:	ffffe097          	auipc	ra,0xffffe
    80002d9c:	f2c080e7          	jalr	-212(ra) # 80000cc4 <release>
      return -1;
    80002da0:	57fd                	li	a5,-1
    80002da2:	bff9                	j	80002d80 <sys_sleep+0x88>

0000000080002da4 <sys_kill>:

uint64
sys_kill(void)
{
    80002da4:	1101                	addi	sp,sp,-32
    80002da6:	ec06                	sd	ra,24(sp)
    80002da8:	e822                	sd	s0,16(sp)
    80002daa:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002dac:	fec40593          	addi	a1,s0,-20
    80002db0:	4501                	li	a0,0
    80002db2:	00000097          	auipc	ra,0x0
    80002db6:	d2e080e7          	jalr	-722(ra) # 80002ae0 <argint>
    80002dba:	87aa                	mv	a5,a0
    return -1;
    80002dbc:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002dbe:	0007c863          	bltz	a5,80002dce <sys_kill+0x2a>
  return kill(pid);
    80002dc2:	fec42503          	lw	a0,-20(s0)
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	620080e7          	jalr	1568(ra) # 800023e6 <kill>
}
    80002dce:	60e2                	ld	ra,24(sp)
    80002dd0:	6442                	ld	s0,16(sp)
    80002dd2:	6105                	addi	sp,sp,32
    80002dd4:	8082                	ret

0000000080002dd6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dd6:	1101                	addi	sp,sp,-32
    80002dd8:	ec06                	sd	ra,24(sp)
    80002dda:	e822                	sd	s0,16(sp)
    80002ddc:	e426                	sd	s1,8(sp)
    80002dde:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002de0:	00015517          	auipc	a0,0x15
    80002de4:	98850513          	addi	a0,a0,-1656 # 80017768 <tickslock>
    80002de8:	ffffe097          	auipc	ra,0xffffe
    80002dec:	e28080e7          	jalr	-472(ra) # 80000c10 <acquire>
  xticks = ticks;
    80002df0:	00006497          	auipc	s1,0x6
    80002df4:	2304a483          	lw	s1,560(s1) # 80009020 <ticks>
  release(&tickslock);
    80002df8:	00015517          	auipc	a0,0x15
    80002dfc:	97050513          	addi	a0,a0,-1680 # 80017768 <tickslock>
    80002e00:	ffffe097          	auipc	ra,0xffffe
    80002e04:	ec4080e7          	jalr	-316(ra) # 80000cc4 <release>
  return xticks;
}
    80002e08:	02049513          	slli	a0,s1,0x20
    80002e0c:	9101                	srli	a0,a0,0x20
    80002e0e:	60e2                	ld	ra,24(sp)
    80002e10:	6442                	ld	s0,16(sp)
    80002e12:	64a2                	ld	s1,8(sp)
    80002e14:	6105                	addi	sp,sp,32
    80002e16:	8082                	ret

0000000080002e18 <sys_trace>:

uint64
sys_trace(void)
{
    80002e18:	1101                	addi	sp,sp,-32
    80002e1a:	ec06                	sd	ra,24(sp)
    80002e1c:	e822                	sd	s0,16(sp)
    80002e1e:	1000                	addi	s0,sp,32
  int mask;
  if(argint(0, &mask) < 0)
    80002e20:	fec40593          	addi	a1,s0,-20
    80002e24:	4501                	li	a0,0
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	cba080e7          	jalr	-838(ra) # 80002ae0 <argint>
    80002e2e:	87aa                	mv	a5,a0
    return -1;
    80002e30:	557d                	li	a0,-1
  if(argint(0, &mask) < 0)
    80002e32:	0007c863          	bltz	a5,80002e42 <sys_trace+0x2a>
  //printf("sys_trace %d\n", mask);
  return trace(mask);
    80002e36:	fec42503          	lw	a0,-20(s0)
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	778080e7          	jalr	1912(ra) # 800025b2 <trace>
    80002e42:	60e2                	ld	ra,24(sp)
    80002e44:	6442                	ld	s0,16(sp)
    80002e46:	6105                	addi	sp,sp,32
    80002e48:	8082                	ret

0000000080002e4a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e4a:	7179                	addi	sp,sp,-48
    80002e4c:	f406                	sd	ra,40(sp)
    80002e4e:	f022                	sd	s0,32(sp)
    80002e50:	ec26                	sd	s1,24(sp)
    80002e52:	e84a                	sd	s2,16(sp)
    80002e54:	e44e                	sd	s3,8(sp)
    80002e56:	e052                	sd	s4,0(sp)
    80002e58:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e5a:	00005597          	auipc	a1,0x5
    80002e5e:	7fe58593          	addi	a1,a1,2046 # 80008658 <syscallnumber_to_name+0xb8>
    80002e62:	00015517          	auipc	a0,0x15
    80002e66:	91e50513          	addi	a0,a0,-1762 # 80017780 <bcache>
    80002e6a:	ffffe097          	auipc	ra,0xffffe
    80002e6e:	d16080e7          	jalr	-746(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e72:	0001d797          	auipc	a5,0x1d
    80002e76:	90e78793          	addi	a5,a5,-1778 # 8001f780 <bcache+0x8000>
    80002e7a:	0001d717          	auipc	a4,0x1d
    80002e7e:	b6e70713          	addi	a4,a4,-1170 # 8001f9e8 <bcache+0x8268>
    80002e82:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e86:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e8a:	00015497          	auipc	s1,0x15
    80002e8e:	90e48493          	addi	s1,s1,-1778 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002e92:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e94:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e96:	00005a17          	auipc	s4,0x5
    80002e9a:	7caa0a13          	addi	s4,s4,1994 # 80008660 <syscallnumber_to_name+0xc0>
    b->next = bcache.head.next;
    80002e9e:	2b893783          	ld	a5,696(s2)
    80002ea2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ea4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ea8:	85d2                	mv	a1,s4
    80002eaa:	01048513          	addi	a0,s1,16
    80002eae:	00001097          	auipc	ra,0x1
    80002eb2:	4ac080e7          	jalr	1196(ra) # 8000435a <initsleeplock>
    bcache.head.next->prev = b;
    80002eb6:	2b893783          	ld	a5,696(s2)
    80002eba:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ebc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ec0:	45848493          	addi	s1,s1,1112
    80002ec4:	fd349de3          	bne	s1,s3,80002e9e <binit+0x54>
  }
}
    80002ec8:	70a2                	ld	ra,40(sp)
    80002eca:	7402                	ld	s0,32(sp)
    80002ecc:	64e2                	ld	s1,24(sp)
    80002ece:	6942                	ld	s2,16(sp)
    80002ed0:	69a2                	ld	s3,8(sp)
    80002ed2:	6a02                	ld	s4,0(sp)
    80002ed4:	6145                	addi	sp,sp,48
    80002ed6:	8082                	ret

0000000080002ed8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002ed8:	7179                	addi	sp,sp,-48
    80002eda:	f406                	sd	ra,40(sp)
    80002edc:	f022                	sd	s0,32(sp)
    80002ede:	ec26                	sd	s1,24(sp)
    80002ee0:	e84a                	sd	s2,16(sp)
    80002ee2:	e44e                	sd	s3,8(sp)
    80002ee4:	1800                	addi	s0,sp,48
    80002ee6:	89aa                	mv	s3,a0
    80002ee8:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002eea:	00015517          	auipc	a0,0x15
    80002eee:	89650513          	addi	a0,a0,-1898 # 80017780 <bcache>
    80002ef2:	ffffe097          	auipc	ra,0xffffe
    80002ef6:	d1e080e7          	jalr	-738(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002efa:	0001d497          	auipc	s1,0x1d
    80002efe:	b3e4b483          	ld	s1,-1218(s1) # 8001fa38 <bcache+0x82b8>
    80002f02:	0001d797          	auipc	a5,0x1d
    80002f06:	ae678793          	addi	a5,a5,-1306 # 8001f9e8 <bcache+0x8268>
    80002f0a:	02f48f63          	beq	s1,a5,80002f48 <bread+0x70>
    80002f0e:	873e                	mv	a4,a5
    80002f10:	a021                	j	80002f18 <bread+0x40>
    80002f12:	68a4                	ld	s1,80(s1)
    80002f14:	02e48a63          	beq	s1,a4,80002f48 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f18:	449c                	lw	a5,8(s1)
    80002f1a:	ff379ce3          	bne	a5,s3,80002f12 <bread+0x3a>
    80002f1e:	44dc                	lw	a5,12(s1)
    80002f20:	ff2799e3          	bne	a5,s2,80002f12 <bread+0x3a>
      b->refcnt++;
    80002f24:	40bc                	lw	a5,64(s1)
    80002f26:	2785                	addiw	a5,a5,1
    80002f28:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f2a:	00015517          	auipc	a0,0x15
    80002f2e:	85650513          	addi	a0,a0,-1962 # 80017780 <bcache>
    80002f32:	ffffe097          	auipc	ra,0xffffe
    80002f36:	d92080e7          	jalr	-622(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80002f3a:	01048513          	addi	a0,s1,16
    80002f3e:	00001097          	auipc	ra,0x1
    80002f42:	456080e7          	jalr	1110(ra) # 80004394 <acquiresleep>
      return b;
    80002f46:	a8b9                	j	80002fa4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f48:	0001d497          	auipc	s1,0x1d
    80002f4c:	ae84b483          	ld	s1,-1304(s1) # 8001fa30 <bcache+0x82b0>
    80002f50:	0001d797          	auipc	a5,0x1d
    80002f54:	a9878793          	addi	a5,a5,-1384 # 8001f9e8 <bcache+0x8268>
    80002f58:	00f48863          	beq	s1,a5,80002f68 <bread+0x90>
    80002f5c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f5e:	40bc                	lw	a5,64(s1)
    80002f60:	cf81                	beqz	a5,80002f78 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f62:	64a4                	ld	s1,72(s1)
    80002f64:	fee49de3          	bne	s1,a4,80002f5e <bread+0x86>
  panic("bget: no buffers");
    80002f68:	00005517          	auipc	a0,0x5
    80002f6c:	70050513          	addi	a0,a0,1792 # 80008668 <syscallnumber_to_name+0xc8>
    80002f70:	ffffd097          	auipc	ra,0xffffd
    80002f74:	5d8080e7          	jalr	1496(ra) # 80000548 <panic>
      b->dev = dev;
    80002f78:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002f7c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002f80:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f84:	4785                	li	a5,1
    80002f86:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f88:	00014517          	auipc	a0,0x14
    80002f8c:	7f850513          	addi	a0,a0,2040 # 80017780 <bcache>
    80002f90:	ffffe097          	auipc	ra,0xffffe
    80002f94:	d34080e7          	jalr	-716(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80002f98:	01048513          	addi	a0,s1,16
    80002f9c:	00001097          	auipc	ra,0x1
    80002fa0:	3f8080e7          	jalr	1016(ra) # 80004394 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fa4:	409c                	lw	a5,0(s1)
    80002fa6:	cb89                	beqz	a5,80002fb8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fa8:	8526                	mv	a0,s1
    80002faa:	70a2                	ld	ra,40(sp)
    80002fac:	7402                	ld	s0,32(sp)
    80002fae:	64e2                	ld	s1,24(sp)
    80002fb0:	6942                	ld	s2,16(sp)
    80002fb2:	69a2                	ld	s3,8(sp)
    80002fb4:	6145                	addi	sp,sp,48
    80002fb6:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fb8:	4581                	li	a1,0
    80002fba:	8526                	mv	a0,s1
    80002fbc:	00003097          	auipc	ra,0x3
    80002fc0:	f30080e7          	jalr	-208(ra) # 80005eec <virtio_disk_rw>
    b->valid = 1;
    80002fc4:	4785                	li	a5,1
    80002fc6:	c09c                	sw	a5,0(s1)
  return b;
    80002fc8:	b7c5                	j	80002fa8 <bread+0xd0>

0000000080002fca <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fca:	1101                	addi	sp,sp,-32
    80002fcc:	ec06                	sd	ra,24(sp)
    80002fce:	e822                	sd	s0,16(sp)
    80002fd0:	e426                	sd	s1,8(sp)
    80002fd2:	1000                	addi	s0,sp,32
    80002fd4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fd6:	0541                	addi	a0,a0,16
    80002fd8:	00001097          	auipc	ra,0x1
    80002fdc:	456080e7          	jalr	1110(ra) # 8000442e <holdingsleep>
    80002fe0:	cd01                	beqz	a0,80002ff8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fe2:	4585                	li	a1,1
    80002fe4:	8526                	mv	a0,s1
    80002fe6:	00003097          	auipc	ra,0x3
    80002fea:	f06080e7          	jalr	-250(ra) # 80005eec <virtio_disk_rw>
}
    80002fee:	60e2                	ld	ra,24(sp)
    80002ff0:	6442                	ld	s0,16(sp)
    80002ff2:	64a2                	ld	s1,8(sp)
    80002ff4:	6105                	addi	sp,sp,32
    80002ff6:	8082                	ret
    panic("bwrite");
    80002ff8:	00005517          	auipc	a0,0x5
    80002ffc:	68850513          	addi	a0,a0,1672 # 80008680 <syscallnumber_to_name+0xe0>
    80003000:	ffffd097          	auipc	ra,0xffffd
    80003004:	548080e7          	jalr	1352(ra) # 80000548 <panic>

0000000080003008 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003008:	1101                	addi	sp,sp,-32
    8000300a:	ec06                	sd	ra,24(sp)
    8000300c:	e822                	sd	s0,16(sp)
    8000300e:	e426                	sd	s1,8(sp)
    80003010:	e04a                	sd	s2,0(sp)
    80003012:	1000                	addi	s0,sp,32
    80003014:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003016:	01050913          	addi	s2,a0,16
    8000301a:	854a                	mv	a0,s2
    8000301c:	00001097          	auipc	ra,0x1
    80003020:	412080e7          	jalr	1042(ra) # 8000442e <holdingsleep>
    80003024:	c92d                	beqz	a0,80003096 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003026:	854a                	mv	a0,s2
    80003028:	00001097          	auipc	ra,0x1
    8000302c:	3c2080e7          	jalr	962(ra) # 800043ea <releasesleep>

  acquire(&bcache.lock);
    80003030:	00014517          	auipc	a0,0x14
    80003034:	75050513          	addi	a0,a0,1872 # 80017780 <bcache>
    80003038:	ffffe097          	auipc	ra,0xffffe
    8000303c:	bd8080e7          	jalr	-1064(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003040:	40bc                	lw	a5,64(s1)
    80003042:	37fd                	addiw	a5,a5,-1
    80003044:	0007871b          	sext.w	a4,a5
    80003048:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000304a:	eb05                	bnez	a4,8000307a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000304c:	68bc                	ld	a5,80(s1)
    8000304e:	64b8                	ld	a4,72(s1)
    80003050:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003052:	64bc                	ld	a5,72(s1)
    80003054:	68b8                	ld	a4,80(s1)
    80003056:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003058:	0001c797          	auipc	a5,0x1c
    8000305c:	72878793          	addi	a5,a5,1832 # 8001f780 <bcache+0x8000>
    80003060:	2b87b703          	ld	a4,696(a5)
    80003064:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003066:	0001d717          	auipc	a4,0x1d
    8000306a:	98270713          	addi	a4,a4,-1662 # 8001f9e8 <bcache+0x8268>
    8000306e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003070:	2b87b703          	ld	a4,696(a5)
    80003074:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003076:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000307a:	00014517          	auipc	a0,0x14
    8000307e:	70650513          	addi	a0,a0,1798 # 80017780 <bcache>
    80003082:	ffffe097          	auipc	ra,0xffffe
    80003086:	c42080e7          	jalr	-958(ra) # 80000cc4 <release>
}
    8000308a:	60e2                	ld	ra,24(sp)
    8000308c:	6442                	ld	s0,16(sp)
    8000308e:	64a2                	ld	s1,8(sp)
    80003090:	6902                	ld	s2,0(sp)
    80003092:	6105                	addi	sp,sp,32
    80003094:	8082                	ret
    panic("brelse");
    80003096:	00005517          	auipc	a0,0x5
    8000309a:	5f250513          	addi	a0,a0,1522 # 80008688 <syscallnumber_to_name+0xe8>
    8000309e:	ffffd097          	auipc	ra,0xffffd
    800030a2:	4aa080e7          	jalr	1194(ra) # 80000548 <panic>

00000000800030a6 <bpin>:

void
bpin(struct buf *b) {
    800030a6:	1101                	addi	sp,sp,-32
    800030a8:	ec06                	sd	ra,24(sp)
    800030aa:	e822                	sd	s0,16(sp)
    800030ac:	e426                	sd	s1,8(sp)
    800030ae:	1000                	addi	s0,sp,32
    800030b0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030b2:	00014517          	auipc	a0,0x14
    800030b6:	6ce50513          	addi	a0,a0,1742 # 80017780 <bcache>
    800030ba:	ffffe097          	auipc	ra,0xffffe
    800030be:	b56080e7          	jalr	-1194(ra) # 80000c10 <acquire>
  b->refcnt++;
    800030c2:	40bc                	lw	a5,64(s1)
    800030c4:	2785                	addiw	a5,a5,1
    800030c6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030c8:	00014517          	auipc	a0,0x14
    800030cc:	6b850513          	addi	a0,a0,1720 # 80017780 <bcache>
    800030d0:	ffffe097          	auipc	ra,0xffffe
    800030d4:	bf4080e7          	jalr	-1036(ra) # 80000cc4 <release>
}
    800030d8:	60e2                	ld	ra,24(sp)
    800030da:	6442                	ld	s0,16(sp)
    800030dc:	64a2                	ld	s1,8(sp)
    800030de:	6105                	addi	sp,sp,32
    800030e0:	8082                	ret

00000000800030e2 <bunpin>:

void
bunpin(struct buf *b) {
    800030e2:	1101                	addi	sp,sp,-32
    800030e4:	ec06                	sd	ra,24(sp)
    800030e6:	e822                	sd	s0,16(sp)
    800030e8:	e426                	sd	s1,8(sp)
    800030ea:	1000                	addi	s0,sp,32
    800030ec:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030ee:	00014517          	auipc	a0,0x14
    800030f2:	69250513          	addi	a0,a0,1682 # 80017780 <bcache>
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	b1a080e7          	jalr	-1254(ra) # 80000c10 <acquire>
  b->refcnt--;
    800030fe:	40bc                	lw	a5,64(s1)
    80003100:	37fd                	addiw	a5,a5,-1
    80003102:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003104:	00014517          	auipc	a0,0x14
    80003108:	67c50513          	addi	a0,a0,1660 # 80017780 <bcache>
    8000310c:	ffffe097          	auipc	ra,0xffffe
    80003110:	bb8080e7          	jalr	-1096(ra) # 80000cc4 <release>
}
    80003114:	60e2                	ld	ra,24(sp)
    80003116:	6442                	ld	s0,16(sp)
    80003118:	64a2                	ld	s1,8(sp)
    8000311a:	6105                	addi	sp,sp,32
    8000311c:	8082                	ret

000000008000311e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000311e:	1101                	addi	sp,sp,-32
    80003120:	ec06                	sd	ra,24(sp)
    80003122:	e822                	sd	s0,16(sp)
    80003124:	e426                	sd	s1,8(sp)
    80003126:	e04a                	sd	s2,0(sp)
    80003128:	1000                	addi	s0,sp,32
    8000312a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000312c:	00d5d59b          	srliw	a1,a1,0xd
    80003130:	0001d797          	auipc	a5,0x1d
    80003134:	d2c7a783          	lw	a5,-724(a5) # 8001fe5c <sb+0x1c>
    80003138:	9dbd                	addw	a1,a1,a5
    8000313a:	00000097          	auipc	ra,0x0
    8000313e:	d9e080e7          	jalr	-610(ra) # 80002ed8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003142:	0074f713          	andi	a4,s1,7
    80003146:	4785                	li	a5,1
    80003148:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000314c:	14ce                	slli	s1,s1,0x33
    8000314e:	90d9                	srli	s1,s1,0x36
    80003150:	00950733          	add	a4,a0,s1
    80003154:	05874703          	lbu	a4,88(a4)
    80003158:	00e7f6b3          	and	a3,a5,a4
    8000315c:	c69d                	beqz	a3,8000318a <bfree+0x6c>
    8000315e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003160:	94aa                	add	s1,s1,a0
    80003162:	fff7c793          	not	a5,a5
    80003166:	8ff9                	and	a5,a5,a4
    80003168:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000316c:	00001097          	auipc	ra,0x1
    80003170:	100080e7          	jalr	256(ra) # 8000426c <log_write>
  brelse(bp);
    80003174:	854a                	mv	a0,s2
    80003176:	00000097          	auipc	ra,0x0
    8000317a:	e92080e7          	jalr	-366(ra) # 80003008 <brelse>
}
    8000317e:	60e2                	ld	ra,24(sp)
    80003180:	6442                	ld	s0,16(sp)
    80003182:	64a2                	ld	s1,8(sp)
    80003184:	6902                	ld	s2,0(sp)
    80003186:	6105                	addi	sp,sp,32
    80003188:	8082                	ret
    panic("freeing free block");
    8000318a:	00005517          	auipc	a0,0x5
    8000318e:	50650513          	addi	a0,a0,1286 # 80008690 <syscallnumber_to_name+0xf0>
    80003192:	ffffd097          	auipc	ra,0xffffd
    80003196:	3b6080e7          	jalr	950(ra) # 80000548 <panic>

000000008000319a <balloc>:
{
    8000319a:	711d                	addi	sp,sp,-96
    8000319c:	ec86                	sd	ra,88(sp)
    8000319e:	e8a2                	sd	s0,80(sp)
    800031a0:	e4a6                	sd	s1,72(sp)
    800031a2:	e0ca                	sd	s2,64(sp)
    800031a4:	fc4e                	sd	s3,56(sp)
    800031a6:	f852                	sd	s4,48(sp)
    800031a8:	f456                	sd	s5,40(sp)
    800031aa:	f05a                	sd	s6,32(sp)
    800031ac:	ec5e                	sd	s7,24(sp)
    800031ae:	e862                	sd	s8,16(sp)
    800031b0:	e466                	sd	s9,8(sp)
    800031b2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031b4:	0001d797          	auipc	a5,0x1d
    800031b8:	c907a783          	lw	a5,-880(a5) # 8001fe44 <sb+0x4>
    800031bc:	cbd1                	beqz	a5,80003250 <balloc+0xb6>
    800031be:	8baa                	mv	s7,a0
    800031c0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031c2:	0001db17          	auipc	s6,0x1d
    800031c6:	c7eb0b13          	addi	s6,s6,-898 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031ca:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031cc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031ce:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031d0:	6c89                	lui	s9,0x2
    800031d2:	a831                	j	800031ee <balloc+0x54>
    brelse(bp);
    800031d4:	854a                	mv	a0,s2
    800031d6:	00000097          	auipc	ra,0x0
    800031da:	e32080e7          	jalr	-462(ra) # 80003008 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031de:	015c87bb          	addw	a5,s9,s5
    800031e2:	00078a9b          	sext.w	s5,a5
    800031e6:	004b2703          	lw	a4,4(s6)
    800031ea:	06eaf363          	bgeu	s5,a4,80003250 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800031ee:	41fad79b          	sraiw	a5,s5,0x1f
    800031f2:	0137d79b          	srliw	a5,a5,0x13
    800031f6:	015787bb          	addw	a5,a5,s5
    800031fa:	40d7d79b          	sraiw	a5,a5,0xd
    800031fe:	01cb2583          	lw	a1,28(s6)
    80003202:	9dbd                	addw	a1,a1,a5
    80003204:	855e                	mv	a0,s7
    80003206:	00000097          	auipc	ra,0x0
    8000320a:	cd2080e7          	jalr	-814(ra) # 80002ed8 <bread>
    8000320e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003210:	004b2503          	lw	a0,4(s6)
    80003214:	000a849b          	sext.w	s1,s5
    80003218:	8662                	mv	a2,s8
    8000321a:	faa4fde3          	bgeu	s1,a0,800031d4 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000321e:	41f6579b          	sraiw	a5,a2,0x1f
    80003222:	01d7d69b          	srliw	a3,a5,0x1d
    80003226:	00c6873b          	addw	a4,a3,a2
    8000322a:	00777793          	andi	a5,a4,7
    8000322e:	9f95                	subw	a5,a5,a3
    80003230:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003234:	4037571b          	sraiw	a4,a4,0x3
    80003238:	00e906b3          	add	a3,s2,a4
    8000323c:	0586c683          	lbu	a3,88(a3)
    80003240:	00d7f5b3          	and	a1,a5,a3
    80003244:	cd91                	beqz	a1,80003260 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003246:	2605                	addiw	a2,a2,1
    80003248:	2485                	addiw	s1,s1,1
    8000324a:	fd4618e3          	bne	a2,s4,8000321a <balloc+0x80>
    8000324e:	b759                	j	800031d4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003250:	00005517          	auipc	a0,0x5
    80003254:	45850513          	addi	a0,a0,1112 # 800086a8 <syscallnumber_to_name+0x108>
    80003258:	ffffd097          	auipc	ra,0xffffd
    8000325c:	2f0080e7          	jalr	752(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003260:	974a                	add	a4,a4,s2
    80003262:	8fd5                	or	a5,a5,a3
    80003264:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003268:	854a                	mv	a0,s2
    8000326a:	00001097          	auipc	ra,0x1
    8000326e:	002080e7          	jalr	2(ra) # 8000426c <log_write>
        brelse(bp);
    80003272:	854a                	mv	a0,s2
    80003274:	00000097          	auipc	ra,0x0
    80003278:	d94080e7          	jalr	-620(ra) # 80003008 <brelse>
  bp = bread(dev, bno);
    8000327c:	85a6                	mv	a1,s1
    8000327e:	855e                	mv	a0,s7
    80003280:	00000097          	auipc	ra,0x0
    80003284:	c58080e7          	jalr	-936(ra) # 80002ed8 <bread>
    80003288:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000328a:	40000613          	li	a2,1024
    8000328e:	4581                	li	a1,0
    80003290:	05850513          	addi	a0,a0,88
    80003294:	ffffe097          	auipc	ra,0xffffe
    80003298:	a78080e7          	jalr	-1416(ra) # 80000d0c <memset>
  log_write(bp);
    8000329c:	854a                	mv	a0,s2
    8000329e:	00001097          	auipc	ra,0x1
    800032a2:	fce080e7          	jalr	-50(ra) # 8000426c <log_write>
  brelse(bp);
    800032a6:	854a                	mv	a0,s2
    800032a8:	00000097          	auipc	ra,0x0
    800032ac:	d60080e7          	jalr	-672(ra) # 80003008 <brelse>
}
    800032b0:	8526                	mv	a0,s1
    800032b2:	60e6                	ld	ra,88(sp)
    800032b4:	6446                	ld	s0,80(sp)
    800032b6:	64a6                	ld	s1,72(sp)
    800032b8:	6906                	ld	s2,64(sp)
    800032ba:	79e2                	ld	s3,56(sp)
    800032bc:	7a42                	ld	s4,48(sp)
    800032be:	7aa2                	ld	s5,40(sp)
    800032c0:	7b02                	ld	s6,32(sp)
    800032c2:	6be2                	ld	s7,24(sp)
    800032c4:	6c42                	ld	s8,16(sp)
    800032c6:	6ca2                	ld	s9,8(sp)
    800032c8:	6125                	addi	sp,sp,96
    800032ca:	8082                	ret

00000000800032cc <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032cc:	7179                	addi	sp,sp,-48
    800032ce:	f406                	sd	ra,40(sp)
    800032d0:	f022                	sd	s0,32(sp)
    800032d2:	ec26                	sd	s1,24(sp)
    800032d4:	e84a                	sd	s2,16(sp)
    800032d6:	e44e                	sd	s3,8(sp)
    800032d8:	e052                	sd	s4,0(sp)
    800032da:	1800                	addi	s0,sp,48
    800032dc:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032de:	47ad                	li	a5,11
    800032e0:	04b7fe63          	bgeu	a5,a1,8000333c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800032e4:	ff45849b          	addiw	s1,a1,-12
    800032e8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032ec:	0ff00793          	li	a5,255
    800032f0:	0ae7e363          	bltu	a5,a4,80003396 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800032f4:	08052583          	lw	a1,128(a0)
    800032f8:	c5ad                	beqz	a1,80003362 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800032fa:	00092503          	lw	a0,0(s2)
    800032fe:	00000097          	auipc	ra,0x0
    80003302:	bda080e7          	jalr	-1062(ra) # 80002ed8 <bread>
    80003306:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003308:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000330c:	02049593          	slli	a1,s1,0x20
    80003310:	9181                	srli	a1,a1,0x20
    80003312:	058a                	slli	a1,a1,0x2
    80003314:	00b784b3          	add	s1,a5,a1
    80003318:	0004a983          	lw	s3,0(s1)
    8000331c:	04098d63          	beqz	s3,80003376 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003320:	8552                	mv	a0,s4
    80003322:	00000097          	auipc	ra,0x0
    80003326:	ce6080e7          	jalr	-794(ra) # 80003008 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000332a:	854e                	mv	a0,s3
    8000332c:	70a2                	ld	ra,40(sp)
    8000332e:	7402                	ld	s0,32(sp)
    80003330:	64e2                	ld	s1,24(sp)
    80003332:	6942                	ld	s2,16(sp)
    80003334:	69a2                	ld	s3,8(sp)
    80003336:	6a02                	ld	s4,0(sp)
    80003338:	6145                	addi	sp,sp,48
    8000333a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000333c:	02059493          	slli	s1,a1,0x20
    80003340:	9081                	srli	s1,s1,0x20
    80003342:	048a                	slli	s1,s1,0x2
    80003344:	94aa                	add	s1,s1,a0
    80003346:	0504a983          	lw	s3,80(s1)
    8000334a:	fe0990e3          	bnez	s3,8000332a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000334e:	4108                	lw	a0,0(a0)
    80003350:	00000097          	auipc	ra,0x0
    80003354:	e4a080e7          	jalr	-438(ra) # 8000319a <balloc>
    80003358:	0005099b          	sext.w	s3,a0
    8000335c:	0534a823          	sw	s3,80(s1)
    80003360:	b7e9                	j	8000332a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003362:	4108                	lw	a0,0(a0)
    80003364:	00000097          	auipc	ra,0x0
    80003368:	e36080e7          	jalr	-458(ra) # 8000319a <balloc>
    8000336c:	0005059b          	sext.w	a1,a0
    80003370:	08b92023          	sw	a1,128(s2)
    80003374:	b759                	j	800032fa <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003376:	00092503          	lw	a0,0(s2)
    8000337a:	00000097          	auipc	ra,0x0
    8000337e:	e20080e7          	jalr	-480(ra) # 8000319a <balloc>
    80003382:	0005099b          	sext.w	s3,a0
    80003386:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000338a:	8552                	mv	a0,s4
    8000338c:	00001097          	auipc	ra,0x1
    80003390:	ee0080e7          	jalr	-288(ra) # 8000426c <log_write>
    80003394:	b771                	j	80003320 <bmap+0x54>
  panic("bmap: out of range");
    80003396:	00005517          	auipc	a0,0x5
    8000339a:	32a50513          	addi	a0,a0,810 # 800086c0 <syscallnumber_to_name+0x120>
    8000339e:	ffffd097          	auipc	ra,0xffffd
    800033a2:	1aa080e7          	jalr	426(ra) # 80000548 <panic>

00000000800033a6 <iget>:
{
    800033a6:	7179                	addi	sp,sp,-48
    800033a8:	f406                	sd	ra,40(sp)
    800033aa:	f022                	sd	s0,32(sp)
    800033ac:	ec26                	sd	s1,24(sp)
    800033ae:	e84a                	sd	s2,16(sp)
    800033b0:	e44e                	sd	s3,8(sp)
    800033b2:	e052                	sd	s4,0(sp)
    800033b4:	1800                	addi	s0,sp,48
    800033b6:	89aa                	mv	s3,a0
    800033b8:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800033ba:	0001d517          	auipc	a0,0x1d
    800033be:	aa650513          	addi	a0,a0,-1370 # 8001fe60 <icache>
    800033c2:	ffffe097          	auipc	ra,0xffffe
    800033c6:	84e080e7          	jalr	-1970(ra) # 80000c10 <acquire>
  empty = 0;
    800033ca:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033cc:	0001d497          	auipc	s1,0x1d
    800033d0:	aac48493          	addi	s1,s1,-1364 # 8001fe78 <icache+0x18>
    800033d4:	0001e697          	auipc	a3,0x1e
    800033d8:	53468693          	addi	a3,a3,1332 # 80021908 <log>
    800033dc:	a039                	j	800033ea <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033de:	02090b63          	beqz	s2,80003414 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033e2:	08848493          	addi	s1,s1,136
    800033e6:	02d48a63          	beq	s1,a3,8000341a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033ea:	449c                	lw	a5,8(s1)
    800033ec:	fef059e3          	blez	a5,800033de <iget+0x38>
    800033f0:	4098                	lw	a4,0(s1)
    800033f2:	ff3716e3          	bne	a4,s3,800033de <iget+0x38>
    800033f6:	40d8                	lw	a4,4(s1)
    800033f8:	ff4713e3          	bne	a4,s4,800033de <iget+0x38>
      ip->ref++;
    800033fc:	2785                	addiw	a5,a5,1
    800033fe:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003400:	0001d517          	auipc	a0,0x1d
    80003404:	a6050513          	addi	a0,a0,-1440 # 8001fe60 <icache>
    80003408:	ffffe097          	auipc	ra,0xffffe
    8000340c:	8bc080e7          	jalr	-1860(ra) # 80000cc4 <release>
      return ip;
    80003410:	8926                	mv	s2,s1
    80003412:	a03d                	j	80003440 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003414:	f7f9                	bnez	a5,800033e2 <iget+0x3c>
    80003416:	8926                	mv	s2,s1
    80003418:	b7e9                	j	800033e2 <iget+0x3c>
  if(empty == 0)
    8000341a:	02090c63          	beqz	s2,80003452 <iget+0xac>
  ip->dev = dev;
    8000341e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003422:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003426:	4785                	li	a5,1
    80003428:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000342c:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003430:	0001d517          	auipc	a0,0x1d
    80003434:	a3050513          	addi	a0,a0,-1488 # 8001fe60 <icache>
    80003438:	ffffe097          	auipc	ra,0xffffe
    8000343c:	88c080e7          	jalr	-1908(ra) # 80000cc4 <release>
}
    80003440:	854a                	mv	a0,s2
    80003442:	70a2                	ld	ra,40(sp)
    80003444:	7402                	ld	s0,32(sp)
    80003446:	64e2                	ld	s1,24(sp)
    80003448:	6942                	ld	s2,16(sp)
    8000344a:	69a2                	ld	s3,8(sp)
    8000344c:	6a02                	ld	s4,0(sp)
    8000344e:	6145                	addi	sp,sp,48
    80003450:	8082                	ret
    panic("iget: no inodes");
    80003452:	00005517          	auipc	a0,0x5
    80003456:	28650513          	addi	a0,a0,646 # 800086d8 <syscallnumber_to_name+0x138>
    8000345a:	ffffd097          	auipc	ra,0xffffd
    8000345e:	0ee080e7          	jalr	238(ra) # 80000548 <panic>

0000000080003462 <fsinit>:
fsinit(int dev) {
    80003462:	7179                	addi	sp,sp,-48
    80003464:	f406                	sd	ra,40(sp)
    80003466:	f022                	sd	s0,32(sp)
    80003468:	ec26                	sd	s1,24(sp)
    8000346a:	e84a                	sd	s2,16(sp)
    8000346c:	e44e                	sd	s3,8(sp)
    8000346e:	1800                	addi	s0,sp,48
    80003470:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003472:	4585                	li	a1,1
    80003474:	00000097          	auipc	ra,0x0
    80003478:	a64080e7          	jalr	-1436(ra) # 80002ed8 <bread>
    8000347c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000347e:	0001d997          	auipc	s3,0x1d
    80003482:	9c298993          	addi	s3,s3,-1598 # 8001fe40 <sb>
    80003486:	02000613          	li	a2,32
    8000348a:	05850593          	addi	a1,a0,88
    8000348e:	854e                	mv	a0,s3
    80003490:	ffffe097          	auipc	ra,0xffffe
    80003494:	8dc080e7          	jalr	-1828(ra) # 80000d6c <memmove>
  brelse(bp);
    80003498:	8526                	mv	a0,s1
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	b6e080e7          	jalr	-1170(ra) # 80003008 <brelse>
  if(sb.magic != FSMAGIC)
    800034a2:	0009a703          	lw	a4,0(s3)
    800034a6:	102037b7          	lui	a5,0x10203
    800034aa:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034ae:	02f71263          	bne	a4,a5,800034d2 <fsinit+0x70>
  initlog(dev, &sb);
    800034b2:	0001d597          	auipc	a1,0x1d
    800034b6:	98e58593          	addi	a1,a1,-1650 # 8001fe40 <sb>
    800034ba:	854a                	mv	a0,s2
    800034bc:	00001097          	auipc	ra,0x1
    800034c0:	b38080e7          	jalr	-1224(ra) # 80003ff4 <initlog>
}
    800034c4:	70a2                	ld	ra,40(sp)
    800034c6:	7402                	ld	s0,32(sp)
    800034c8:	64e2                	ld	s1,24(sp)
    800034ca:	6942                	ld	s2,16(sp)
    800034cc:	69a2                	ld	s3,8(sp)
    800034ce:	6145                	addi	sp,sp,48
    800034d0:	8082                	ret
    panic("invalid file system");
    800034d2:	00005517          	auipc	a0,0x5
    800034d6:	21650513          	addi	a0,a0,534 # 800086e8 <syscallnumber_to_name+0x148>
    800034da:	ffffd097          	auipc	ra,0xffffd
    800034de:	06e080e7          	jalr	110(ra) # 80000548 <panic>

00000000800034e2 <iinit>:
{
    800034e2:	7179                	addi	sp,sp,-48
    800034e4:	f406                	sd	ra,40(sp)
    800034e6:	f022                	sd	s0,32(sp)
    800034e8:	ec26                	sd	s1,24(sp)
    800034ea:	e84a                	sd	s2,16(sp)
    800034ec:	e44e                	sd	s3,8(sp)
    800034ee:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800034f0:	00005597          	auipc	a1,0x5
    800034f4:	21058593          	addi	a1,a1,528 # 80008700 <syscallnumber_to_name+0x160>
    800034f8:	0001d517          	auipc	a0,0x1d
    800034fc:	96850513          	addi	a0,a0,-1688 # 8001fe60 <icache>
    80003500:	ffffd097          	auipc	ra,0xffffd
    80003504:	680080e7          	jalr	1664(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003508:	0001d497          	auipc	s1,0x1d
    8000350c:	98048493          	addi	s1,s1,-1664 # 8001fe88 <icache+0x28>
    80003510:	0001e997          	auipc	s3,0x1e
    80003514:	40898993          	addi	s3,s3,1032 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003518:	00005917          	auipc	s2,0x5
    8000351c:	1f090913          	addi	s2,s2,496 # 80008708 <syscallnumber_to_name+0x168>
    80003520:	85ca                	mv	a1,s2
    80003522:	8526                	mv	a0,s1
    80003524:	00001097          	auipc	ra,0x1
    80003528:	e36080e7          	jalr	-458(ra) # 8000435a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000352c:	08848493          	addi	s1,s1,136
    80003530:	ff3498e3          	bne	s1,s3,80003520 <iinit+0x3e>
}
    80003534:	70a2                	ld	ra,40(sp)
    80003536:	7402                	ld	s0,32(sp)
    80003538:	64e2                	ld	s1,24(sp)
    8000353a:	6942                	ld	s2,16(sp)
    8000353c:	69a2                	ld	s3,8(sp)
    8000353e:	6145                	addi	sp,sp,48
    80003540:	8082                	ret

0000000080003542 <ialloc>:
{
    80003542:	715d                	addi	sp,sp,-80
    80003544:	e486                	sd	ra,72(sp)
    80003546:	e0a2                	sd	s0,64(sp)
    80003548:	fc26                	sd	s1,56(sp)
    8000354a:	f84a                	sd	s2,48(sp)
    8000354c:	f44e                	sd	s3,40(sp)
    8000354e:	f052                	sd	s4,32(sp)
    80003550:	ec56                	sd	s5,24(sp)
    80003552:	e85a                	sd	s6,16(sp)
    80003554:	e45e                	sd	s7,8(sp)
    80003556:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003558:	0001d717          	auipc	a4,0x1d
    8000355c:	8f472703          	lw	a4,-1804(a4) # 8001fe4c <sb+0xc>
    80003560:	4785                	li	a5,1
    80003562:	04e7fa63          	bgeu	a5,a4,800035b6 <ialloc+0x74>
    80003566:	8aaa                	mv	s5,a0
    80003568:	8bae                	mv	s7,a1
    8000356a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000356c:	0001da17          	auipc	s4,0x1d
    80003570:	8d4a0a13          	addi	s4,s4,-1836 # 8001fe40 <sb>
    80003574:	00048b1b          	sext.w	s6,s1
    80003578:	0044d593          	srli	a1,s1,0x4
    8000357c:	018a2783          	lw	a5,24(s4)
    80003580:	9dbd                	addw	a1,a1,a5
    80003582:	8556                	mv	a0,s5
    80003584:	00000097          	auipc	ra,0x0
    80003588:	954080e7          	jalr	-1708(ra) # 80002ed8 <bread>
    8000358c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000358e:	05850993          	addi	s3,a0,88
    80003592:	00f4f793          	andi	a5,s1,15
    80003596:	079a                	slli	a5,a5,0x6
    80003598:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000359a:	00099783          	lh	a5,0(s3)
    8000359e:	c785                	beqz	a5,800035c6 <ialloc+0x84>
    brelse(bp);
    800035a0:	00000097          	auipc	ra,0x0
    800035a4:	a68080e7          	jalr	-1432(ra) # 80003008 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035a8:	0485                	addi	s1,s1,1
    800035aa:	00ca2703          	lw	a4,12(s4)
    800035ae:	0004879b          	sext.w	a5,s1
    800035b2:	fce7e1e3          	bltu	a5,a4,80003574 <ialloc+0x32>
  panic("ialloc: no inodes");
    800035b6:	00005517          	auipc	a0,0x5
    800035ba:	15a50513          	addi	a0,a0,346 # 80008710 <syscallnumber_to_name+0x170>
    800035be:	ffffd097          	auipc	ra,0xffffd
    800035c2:	f8a080e7          	jalr	-118(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    800035c6:	04000613          	li	a2,64
    800035ca:	4581                	li	a1,0
    800035cc:	854e                	mv	a0,s3
    800035ce:	ffffd097          	auipc	ra,0xffffd
    800035d2:	73e080e7          	jalr	1854(ra) # 80000d0c <memset>
      dip->type = type;
    800035d6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035da:	854a                	mv	a0,s2
    800035dc:	00001097          	auipc	ra,0x1
    800035e0:	c90080e7          	jalr	-880(ra) # 8000426c <log_write>
      brelse(bp);
    800035e4:	854a                	mv	a0,s2
    800035e6:	00000097          	auipc	ra,0x0
    800035ea:	a22080e7          	jalr	-1502(ra) # 80003008 <brelse>
      return iget(dev, inum);
    800035ee:	85da                	mv	a1,s6
    800035f0:	8556                	mv	a0,s5
    800035f2:	00000097          	auipc	ra,0x0
    800035f6:	db4080e7          	jalr	-588(ra) # 800033a6 <iget>
}
    800035fa:	60a6                	ld	ra,72(sp)
    800035fc:	6406                	ld	s0,64(sp)
    800035fe:	74e2                	ld	s1,56(sp)
    80003600:	7942                	ld	s2,48(sp)
    80003602:	79a2                	ld	s3,40(sp)
    80003604:	7a02                	ld	s4,32(sp)
    80003606:	6ae2                	ld	s5,24(sp)
    80003608:	6b42                	ld	s6,16(sp)
    8000360a:	6ba2                	ld	s7,8(sp)
    8000360c:	6161                	addi	sp,sp,80
    8000360e:	8082                	ret

0000000080003610 <iupdate>:
{
    80003610:	1101                	addi	sp,sp,-32
    80003612:	ec06                	sd	ra,24(sp)
    80003614:	e822                	sd	s0,16(sp)
    80003616:	e426                	sd	s1,8(sp)
    80003618:	e04a                	sd	s2,0(sp)
    8000361a:	1000                	addi	s0,sp,32
    8000361c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000361e:	415c                	lw	a5,4(a0)
    80003620:	0047d79b          	srliw	a5,a5,0x4
    80003624:	0001d597          	auipc	a1,0x1d
    80003628:	8345a583          	lw	a1,-1996(a1) # 8001fe58 <sb+0x18>
    8000362c:	9dbd                	addw	a1,a1,a5
    8000362e:	4108                	lw	a0,0(a0)
    80003630:	00000097          	auipc	ra,0x0
    80003634:	8a8080e7          	jalr	-1880(ra) # 80002ed8 <bread>
    80003638:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000363a:	05850793          	addi	a5,a0,88
    8000363e:	40c8                	lw	a0,4(s1)
    80003640:	893d                	andi	a0,a0,15
    80003642:	051a                	slli	a0,a0,0x6
    80003644:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003646:	04449703          	lh	a4,68(s1)
    8000364a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000364e:	04649703          	lh	a4,70(s1)
    80003652:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003656:	04849703          	lh	a4,72(s1)
    8000365a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000365e:	04a49703          	lh	a4,74(s1)
    80003662:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003666:	44f8                	lw	a4,76(s1)
    80003668:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000366a:	03400613          	li	a2,52
    8000366e:	05048593          	addi	a1,s1,80
    80003672:	0531                	addi	a0,a0,12
    80003674:	ffffd097          	auipc	ra,0xffffd
    80003678:	6f8080e7          	jalr	1784(ra) # 80000d6c <memmove>
  log_write(bp);
    8000367c:	854a                	mv	a0,s2
    8000367e:	00001097          	auipc	ra,0x1
    80003682:	bee080e7          	jalr	-1042(ra) # 8000426c <log_write>
  brelse(bp);
    80003686:	854a                	mv	a0,s2
    80003688:	00000097          	auipc	ra,0x0
    8000368c:	980080e7          	jalr	-1664(ra) # 80003008 <brelse>
}
    80003690:	60e2                	ld	ra,24(sp)
    80003692:	6442                	ld	s0,16(sp)
    80003694:	64a2                	ld	s1,8(sp)
    80003696:	6902                	ld	s2,0(sp)
    80003698:	6105                	addi	sp,sp,32
    8000369a:	8082                	ret

000000008000369c <idup>:
{
    8000369c:	1101                	addi	sp,sp,-32
    8000369e:	ec06                	sd	ra,24(sp)
    800036a0:	e822                	sd	s0,16(sp)
    800036a2:	e426                	sd	s1,8(sp)
    800036a4:	1000                	addi	s0,sp,32
    800036a6:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800036a8:	0001c517          	auipc	a0,0x1c
    800036ac:	7b850513          	addi	a0,a0,1976 # 8001fe60 <icache>
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	560080e7          	jalr	1376(ra) # 80000c10 <acquire>
  ip->ref++;
    800036b8:	449c                	lw	a5,8(s1)
    800036ba:	2785                	addiw	a5,a5,1
    800036bc:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800036be:	0001c517          	auipc	a0,0x1c
    800036c2:	7a250513          	addi	a0,a0,1954 # 8001fe60 <icache>
    800036c6:	ffffd097          	auipc	ra,0xffffd
    800036ca:	5fe080e7          	jalr	1534(ra) # 80000cc4 <release>
}
    800036ce:	8526                	mv	a0,s1
    800036d0:	60e2                	ld	ra,24(sp)
    800036d2:	6442                	ld	s0,16(sp)
    800036d4:	64a2                	ld	s1,8(sp)
    800036d6:	6105                	addi	sp,sp,32
    800036d8:	8082                	ret

00000000800036da <ilock>:
{
    800036da:	1101                	addi	sp,sp,-32
    800036dc:	ec06                	sd	ra,24(sp)
    800036de:	e822                	sd	s0,16(sp)
    800036e0:	e426                	sd	s1,8(sp)
    800036e2:	e04a                	sd	s2,0(sp)
    800036e4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036e6:	c115                	beqz	a0,8000370a <ilock+0x30>
    800036e8:	84aa                	mv	s1,a0
    800036ea:	451c                	lw	a5,8(a0)
    800036ec:	00f05f63          	blez	a5,8000370a <ilock+0x30>
  acquiresleep(&ip->lock);
    800036f0:	0541                	addi	a0,a0,16
    800036f2:	00001097          	auipc	ra,0x1
    800036f6:	ca2080e7          	jalr	-862(ra) # 80004394 <acquiresleep>
  if(ip->valid == 0){
    800036fa:	40bc                	lw	a5,64(s1)
    800036fc:	cf99                	beqz	a5,8000371a <ilock+0x40>
}
    800036fe:	60e2                	ld	ra,24(sp)
    80003700:	6442                	ld	s0,16(sp)
    80003702:	64a2                	ld	s1,8(sp)
    80003704:	6902                	ld	s2,0(sp)
    80003706:	6105                	addi	sp,sp,32
    80003708:	8082                	ret
    panic("ilock");
    8000370a:	00005517          	auipc	a0,0x5
    8000370e:	01e50513          	addi	a0,a0,30 # 80008728 <syscallnumber_to_name+0x188>
    80003712:	ffffd097          	auipc	ra,0xffffd
    80003716:	e36080e7          	jalr	-458(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000371a:	40dc                	lw	a5,4(s1)
    8000371c:	0047d79b          	srliw	a5,a5,0x4
    80003720:	0001c597          	auipc	a1,0x1c
    80003724:	7385a583          	lw	a1,1848(a1) # 8001fe58 <sb+0x18>
    80003728:	9dbd                	addw	a1,a1,a5
    8000372a:	4088                	lw	a0,0(s1)
    8000372c:	fffff097          	auipc	ra,0xfffff
    80003730:	7ac080e7          	jalr	1964(ra) # 80002ed8 <bread>
    80003734:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003736:	05850593          	addi	a1,a0,88
    8000373a:	40dc                	lw	a5,4(s1)
    8000373c:	8bbd                	andi	a5,a5,15
    8000373e:	079a                	slli	a5,a5,0x6
    80003740:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003742:	00059783          	lh	a5,0(a1)
    80003746:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000374a:	00259783          	lh	a5,2(a1)
    8000374e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003752:	00459783          	lh	a5,4(a1)
    80003756:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000375a:	00659783          	lh	a5,6(a1)
    8000375e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003762:	459c                	lw	a5,8(a1)
    80003764:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003766:	03400613          	li	a2,52
    8000376a:	05b1                	addi	a1,a1,12
    8000376c:	05048513          	addi	a0,s1,80
    80003770:	ffffd097          	auipc	ra,0xffffd
    80003774:	5fc080e7          	jalr	1532(ra) # 80000d6c <memmove>
    brelse(bp);
    80003778:	854a                	mv	a0,s2
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	88e080e7          	jalr	-1906(ra) # 80003008 <brelse>
    ip->valid = 1;
    80003782:	4785                	li	a5,1
    80003784:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003786:	04449783          	lh	a5,68(s1)
    8000378a:	fbb5                	bnez	a5,800036fe <ilock+0x24>
      panic("ilock: no type");
    8000378c:	00005517          	auipc	a0,0x5
    80003790:	fa450513          	addi	a0,a0,-92 # 80008730 <syscallnumber_to_name+0x190>
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	db4080e7          	jalr	-588(ra) # 80000548 <panic>

000000008000379c <iunlock>:
{
    8000379c:	1101                	addi	sp,sp,-32
    8000379e:	ec06                	sd	ra,24(sp)
    800037a0:	e822                	sd	s0,16(sp)
    800037a2:	e426                	sd	s1,8(sp)
    800037a4:	e04a                	sd	s2,0(sp)
    800037a6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037a8:	c905                	beqz	a0,800037d8 <iunlock+0x3c>
    800037aa:	84aa                	mv	s1,a0
    800037ac:	01050913          	addi	s2,a0,16
    800037b0:	854a                	mv	a0,s2
    800037b2:	00001097          	auipc	ra,0x1
    800037b6:	c7c080e7          	jalr	-900(ra) # 8000442e <holdingsleep>
    800037ba:	cd19                	beqz	a0,800037d8 <iunlock+0x3c>
    800037bc:	449c                	lw	a5,8(s1)
    800037be:	00f05d63          	blez	a5,800037d8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037c2:	854a                	mv	a0,s2
    800037c4:	00001097          	auipc	ra,0x1
    800037c8:	c26080e7          	jalr	-986(ra) # 800043ea <releasesleep>
}
    800037cc:	60e2                	ld	ra,24(sp)
    800037ce:	6442                	ld	s0,16(sp)
    800037d0:	64a2                	ld	s1,8(sp)
    800037d2:	6902                	ld	s2,0(sp)
    800037d4:	6105                	addi	sp,sp,32
    800037d6:	8082                	ret
    panic("iunlock");
    800037d8:	00005517          	auipc	a0,0x5
    800037dc:	f6850513          	addi	a0,a0,-152 # 80008740 <syscallnumber_to_name+0x1a0>
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	d68080e7          	jalr	-664(ra) # 80000548 <panic>

00000000800037e8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037e8:	7179                	addi	sp,sp,-48
    800037ea:	f406                	sd	ra,40(sp)
    800037ec:	f022                	sd	s0,32(sp)
    800037ee:	ec26                	sd	s1,24(sp)
    800037f0:	e84a                	sd	s2,16(sp)
    800037f2:	e44e                	sd	s3,8(sp)
    800037f4:	e052                	sd	s4,0(sp)
    800037f6:	1800                	addi	s0,sp,48
    800037f8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037fa:	05050493          	addi	s1,a0,80
    800037fe:	08050913          	addi	s2,a0,128
    80003802:	a021                	j	8000380a <itrunc+0x22>
    80003804:	0491                	addi	s1,s1,4
    80003806:	01248d63          	beq	s1,s2,80003820 <itrunc+0x38>
    if(ip->addrs[i]){
    8000380a:	408c                	lw	a1,0(s1)
    8000380c:	dde5                	beqz	a1,80003804 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000380e:	0009a503          	lw	a0,0(s3)
    80003812:	00000097          	auipc	ra,0x0
    80003816:	90c080e7          	jalr	-1780(ra) # 8000311e <bfree>
      ip->addrs[i] = 0;
    8000381a:	0004a023          	sw	zero,0(s1)
    8000381e:	b7dd                	j	80003804 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003820:	0809a583          	lw	a1,128(s3)
    80003824:	e185                	bnez	a1,80003844 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003826:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000382a:	854e                	mv	a0,s3
    8000382c:	00000097          	auipc	ra,0x0
    80003830:	de4080e7          	jalr	-540(ra) # 80003610 <iupdate>
}
    80003834:	70a2                	ld	ra,40(sp)
    80003836:	7402                	ld	s0,32(sp)
    80003838:	64e2                	ld	s1,24(sp)
    8000383a:	6942                	ld	s2,16(sp)
    8000383c:	69a2                	ld	s3,8(sp)
    8000383e:	6a02                	ld	s4,0(sp)
    80003840:	6145                	addi	sp,sp,48
    80003842:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003844:	0009a503          	lw	a0,0(s3)
    80003848:	fffff097          	auipc	ra,0xfffff
    8000384c:	690080e7          	jalr	1680(ra) # 80002ed8 <bread>
    80003850:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003852:	05850493          	addi	s1,a0,88
    80003856:	45850913          	addi	s2,a0,1112
    8000385a:	a811                	j	8000386e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000385c:	0009a503          	lw	a0,0(s3)
    80003860:	00000097          	auipc	ra,0x0
    80003864:	8be080e7          	jalr	-1858(ra) # 8000311e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003868:	0491                	addi	s1,s1,4
    8000386a:	01248563          	beq	s1,s2,80003874 <itrunc+0x8c>
      if(a[j])
    8000386e:	408c                	lw	a1,0(s1)
    80003870:	dde5                	beqz	a1,80003868 <itrunc+0x80>
    80003872:	b7ed                	j	8000385c <itrunc+0x74>
    brelse(bp);
    80003874:	8552                	mv	a0,s4
    80003876:	fffff097          	auipc	ra,0xfffff
    8000387a:	792080e7          	jalr	1938(ra) # 80003008 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000387e:	0809a583          	lw	a1,128(s3)
    80003882:	0009a503          	lw	a0,0(s3)
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	898080e7          	jalr	-1896(ra) # 8000311e <bfree>
    ip->addrs[NDIRECT] = 0;
    8000388e:	0809a023          	sw	zero,128(s3)
    80003892:	bf51                	j	80003826 <itrunc+0x3e>

0000000080003894 <iput>:
{
    80003894:	1101                	addi	sp,sp,-32
    80003896:	ec06                	sd	ra,24(sp)
    80003898:	e822                	sd	s0,16(sp)
    8000389a:	e426                	sd	s1,8(sp)
    8000389c:	e04a                	sd	s2,0(sp)
    8000389e:	1000                	addi	s0,sp,32
    800038a0:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800038a2:	0001c517          	auipc	a0,0x1c
    800038a6:	5be50513          	addi	a0,a0,1470 # 8001fe60 <icache>
    800038aa:	ffffd097          	auipc	ra,0xffffd
    800038ae:	366080e7          	jalr	870(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038b2:	4498                	lw	a4,8(s1)
    800038b4:	4785                	li	a5,1
    800038b6:	02f70363          	beq	a4,a5,800038dc <iput+0x48>
  ip->ref--;
    800038ba:	449c                	lw	a5,8(s1)
    800038bc:	37fd                	addiw	a5,a5,-1
    800038be:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800038c0:	0001c517          	auipc	a0,0x1c
    800038c4:	5a050513          	addi	a0,a0,1440 # 8001fe60 <icache>
    800038c8:	ffffd097          	auipc	ra,0xffffd
    800038cc:	3fc080e7          	jalr	1020(ra) # 80000cc4 <release>
}
    800038d0:	60e2                	ld	ra,24(sp)
    800038d2:	6442                	ld	s0,16(sp)
    800038d4:	64a2                	ld	s1,8(sp)
    800038d6:	6902                	ld	s2,0(sp)
    800038d8:	6105                	addi	sp,sp,32
    800038da:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038dc:	40bc                	lw	a5,64(s1)
    800038de:	dff1                	beqz	a5,800038ba <iput+0x26>
    800038e0:	04a49783          	lh	a5,74(s1)
    800038e4:	fbf9                	bnez	a5,800038ba <iput+0x26>
    acquiresleep(&ip->lock);
    800038e6:	01048913          	addi	s2,s1,16
    800038ea:	854a                	mv	a0,s2
    800038ec:	00001097          	auipc	ra,0x1
    800038f0:	aa8080e7          	jalr	-1368(ra) # 80004394 <acquiresleep>
    release(&icache.lock);
    800038f4:	0001c517          	auipc	a0,0x1c
    800038f8:	56c50513          	addi	a0,a0,1388 # 8001fe60 <icache>
    800038fc:	ffffd097          	auipc	ra,0xffffd
    80003900:	3c8080e7          	jalr	968(ra) # 80000cc4 <release>
    itrunc(ip);
    80003904:	8526                	mv	a0,s1
    80003906:	00000097          	auipc	ra,0x0
    8000390a:	ee2080e7          	jalr	-286(ra) # 800037e8 <itrunc>
    ip->type = 0;
    8000390e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003912:	8526                	mv	a0,s1
    80003914:	00000097          	auipc	ra,0x0
    80003918:	cfc080e7          	jalr	-772(ra) # 80003610 <iupdate>
    ip->valid = 0;
    8000391c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003920:	854a                	mv	a0,s2
    80003922:	00001097          	auipc	ra,0x1
    80003926:	ac8080e7          	jalr	-1336(ra) # 800043ea <releasesleep>
    acquire(&icache.lock);
    8000392a:	0001c517          	auipc	a0,0x1c
    8000392e:	53650513          	addi	a0,a0,1334 # 8001fe60 <icache>
    80003932:	ffffd097          	auipc	ra,0xffffd
    80003936:	2de080e7          	jalr	734(ra) # 80000c10 <acquire>
    8000393a:	b741                	j	800038ba <iput+0x26>

000000008000393c <iunlockput>:
{
    8000393c:	1101                	addi	sp,sp,-32
    8000393e:	ec06                	sd	ra,24(sp)
    80003940:	e822                	sd	s0,16(sp)
    80003942:	e426                	sd	s1,8(sp)
    80003944:	1000                	addi	s0,sp,32
    80003946:	84aa                	mv	s1,a0
  iunlock(ip);
    80003948:	00000097          	auipc	ra,0x0
    8000394c:	e54080e7          	jalr	-428(ra) # 8000379c <iunlock>
  iput(ip);
    80003950:	8526                	mv	a0,s1
    80003952:	00000097          	auipc	ra,0x0
    80003956:	f42080e7          	jalr	-190(ra) # 80003894 <iput>
}
    8000395a:	60e2                	ld	ra,24(sp)
    8000395c:	6442                	ld	s0,16(sp)
    8000395e:	64a2                	ld	s1,8(sp)
    80003960:	6105                	addi	sp,sp,32
    80003962:	8082                	ret

0000000080003964 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003964:	1141                	addi	sp,sp,-16
    80003966:	e422                	sd	s0,8(sp)
    80003968:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000396a:	411c                	lw	a5,0(a0)
    8000396c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000396e:	415c                	lw	a5,4(a0)
    80003970:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003972:	04451783          	lh	a5,68(a0)
    80003976:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000397a:	04a51783          	lh	a5,74(a0)
    8000397e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003982:	04c56783          	lwu	a5,76(a0)
    80003986:	e99c                	sd	a5,16(a1)
}
    80003988:	6422                	ld	s0,8(sp)
    8000398a:	0141                	addi	sp,sp,16
    8000398c:	8082                	ret

000000008000398e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000398e:	457c                	lw	a5,76(a0)
    80003990:	0ed7e863          	bltu	a5,a3,80003a80 <readi+0xf2>
{
    80003994:	7159                	addi	sp,sp,-112
    80003996:	f486                	sd	ra,104(sp)
    80003998:	f0a2                	sd	s0,96(sp)
    8000399a:	eca6                	sd	s1,88(sp)
    8000399c:	e8ca                	sd	s2,80(sp)
    8000399e:	e4ce                	sd	s3,72(sp)
    800039a0:	e0d2                	sd	s4,64(sp)
    800039a2:	fc56                	sd	s5,56(sp)
    800039a4:	f85a                	sd	s6,48(sp)
    800039a6:	f45e                	sd	s7,40(sp)
    800039a8:	f062                	sd	s8,32(sp)
    800039aa:	ec66                	sd	s9,24(sp)
    800039ac:	e86a                	sd	s10,16(sp)
    800039ae:	e46e                	sd	s11,8(sp)
    800039b0:	1880                	addi	s0,sp,112
    800039b2:	8baa                	mv	s7,a0
    800039b4:	8c2e                	mv	s8,a1
    800039b6:	8ab2                	mv	s5,a2
    800039b8:	84b6                	mv	s1,a3
    800039ba:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039bc:	9f35                	addw	a4,a4,a3
    return 0;
    800039be:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039c0:	08d76f63          	bltu	a4,a3,80003a5e <readi+0xd0>
  if(off + n > ip->size)
    800039c4:	00e7f463          	bgeu	a5,a4,800039cc <readi+0x3e>
    n = ip->size - off;
    800039c8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039cc:	0a0b0863          	beqz	s6,80003a7c <readi+0xee>
    800039d0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039d2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039d6:	5cfd                	li	s9,-1
    800039d8:	a82d                	j	80003a12 <readi+0x84>
    800039da:	020a1d93          	slli	s11,s4,0x20
    800039de:	020ddd93          	srli	s11,s11,0x20
    800039e2:	05890613          	addi	a2,s2,88
    800039e6:	86ee                	mv	a3,s11
    800039e8:	963a                	add	a2,a2,a4
    800039ea:	85d6                	mv	a1,s5
    800039ec:	8562                	mv	a0,s8
    800039ee:	fffff097          	auipc	ra,0xfffff
    800039f2:	a6a080e7          	jalr	-1430(ra) # 80002458 <either_copyout>
    800039f6:	05950d63          	beq	a0,s9,80003a50 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    800039fa:	854a                	mv	a0,s2
    800039fc:	fffff097          	auipc	ra,0xfffff
    80003a00:	60c080e7          	jalr	1548(ra) # 80003008 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a04:	013a09bb          	addw	s3,s4,s3
    80003a08:	009a04bb          	addw	s1,s4,s1
    80003a0c:	9aee                	add	s5,s5,s11
    80003a0e:	0569f663          	bgeu	s3,s6,80003a5a <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a12:	000ba903          	lw	s2,0(s7)
    80003a16:	00a4d59b          	srliw	a1,s1,0xa
    80003a1a:	855e                	mv	a0,s7
    80003a1c:	00000097          	auipc	ra,0x0
    80003a20:	8b0080e7          	jalr	-1872(ra) # 800032cc <bmap>
    80003a24:	0005059b          	sext.w	a1,a0
    80003a28:	854a                	mv	a0,s2
    80003a2a:	fffff097          	auipc	ra,0xfffff
    80003a2e:	4ae080e7          	jalr	1198(ra) # 80002ed8 <bread>
    80003a32:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a34:	3ff4f713          	andi	a4,s1,1023
    80003a38:	40ed07bb          	subw	a5,s10,a4
    80003a3c:	413b06bb          	subw	a3,s6,s3
    80003a40:	8a3e                	mv	s4,a5
    80003a42:	2781                	sext.w	a5,a5
    80003a44:	0006861b          	sext.w	a2,a3
    80003a48:	f8f679e3          	bgeu	a2,a5,800039da <readi+0x4c>
    80003a4c:	8a36                	mv	s4,a3
    80003a4e:	b771                	j	800039da <readi+0x4c>
      brelse(bp);
    80003a50:	854a                	mv	a0,s2
    80003a52:	fffff097          	auipc	ra,0xfffff
    80003a56:	5b6080e7          	jalr	1462(ra) # 80003008 <brelse>
  }
  return tot;
    80003a5a:	0009851b          	sext.w	a0,s3
}
    80003a5e:	70a6                	ld	ra,104(sp)
    80003a60:	7406                	ld	s0,96(sp)
    80003a62:	64e6                	ld	s1,88(sp)
    80003a64:	6946                	ld	s2,80(sp)
    80003a66:	69a6                	ld	s3,72(sp)
    80003a68:	6a06                	ld	s4,64(sp)
    80003a6a:	7ae2                	ld	s5,56(sp)
    80003a6c:	7b42                	ld	s6,48(sp)
    80003a6e:	7ba2                	ld	s7,40(sp)
    80003a70:	7c02                	ld	s8,32(sp)
    80003a72:	6ce2                	ld	s9,24(sp)
    80003a74:	6d42                	ld	s10,16(sp)
    80003a76:	6da2                	ld	s11,8(sp)
    80003a78:	6165                	addi	sp,sp,112
    80003a7a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a7c:	89da                	mv	s3,s6
    80003a7e:	bff1                	j	80003a5a <readi+0xcc>
    return 0;
    80003a80:	4501                	li	a0,0
}
    80003a82:	8082                	ret

0000000080003a84 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a84:	457c                	lw	a5,76(a0)
    80003a86:	10d7e663          	bltu	a5,a3,80003b92 <writei+0x10e>
{
    80003a8a:	7159                	addi	sp,sp,-112
    80003a8c:	f486                	sd	ra,104(sp)
    80003a8e:	f0a2                	sd	s0,96(sp)
    80003a90:	eca6                	sd	s1,88(sp)
    80003a92:	e8ca                	sd	s2,80(sp)
    80003a94:	e4ce                	sd	s3,72(sp)
    80003a96:	e0d2                	sd	s4,64(sp)
    80003a98:	fc56                	sd	s5,56(sp)
    80003a9a:	f85a                	sd	s6,48(sp)
    80003a9c:	f45e                	sd	s7,40(sp)
    80003a9e:	f062                	sd	s8,32(sp)
    80003aa0:	ec66                	sd	s9,24(sp)
    80003aa2:	e86a                	sd	s10,16(sp)
    80003aa4:	e46e                	sd	s11,8(sp)
    80003aa6:	1880                	addi	s0,sp,112
    80003aa8:	8baa                	mv	s7,a0
    80003aaa:	8c2e                	mv	s8,a1
    80003aac:	8ab2                	mv	s5,a2
    80003aae:	8936                	mv	s2,a3
    80003ab0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ab2:	00e687bb          	addw	a5,a3,a4
    80003ab6:	0ed7e063          	bltu	a5,a3,80003b96 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003aba:	00043737          	lui	a4,0x43
    80003abe:	0cf76e63          	bltu	a4,a5,80003b9a <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ac2:	0a0b0763          	beqz	s6,80003b70 <writei+0xec>
    80003ac6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003acc:	5cfd                	li	s9,-1
    80003ace:	a091                	j	80003b12 <writei+0x8e>
    80003ad0:	02099d93          	slli	s11,s3,0x20
    80003ad4:	020ddd93          	srli	s11,s11,0x20
    80003ad8:	05848513          	addi	a0,s1,88
    80003adc:	86ee                	mv	a3,s11
    80003ade:	8656                	mv	a2,s5
    80003ae0:	85e2                	mv	a1,s8
    80003ae2:	953a                	add	a0,a0,a4
    80003ae4:	fffff097          	auipc	ra,0xfffff
    80003ae8:	9ca080e7          	jalr	-1590(ra) # 800024ae <either_copyin>
    80003aec:	07950263          	beq	a0,s9,80003b50 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003af0:	8526                	mv	a0,s1
    80003af2:	00000097          	auipc	ra,0x0
    80003af6:	77a080e7          	jalr	1914(ra) # 8000426c <log_write>
    brelse(bp);
    80003afa:	8526                	mv	a0,s1
    80003afc:	fffff097          	auipc	ra,0xfffff
    80003b00:	50c080e7          	jalr	1292(ra) # 80003008 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b04:	01498a3b          	addw	s4,s3,s4
    80003b08:	0129893b          	addw	s2,s3,s2
    80003b0c:	9aee                	add	s5,s5,s11
    80003b0e:	056a7663          	bgeu	s4,s6,80003b5a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b12:	000ba483          	lw	s1,0(s7)
    80003b16:	00a9559b          	srliw	a1,s2,0xa
    80003b1a:	855e                	mv	a0,s7
    80003b1c:	fffff097          	auipc	ra,0xfffff
    80003b20:	7b0080e7          	jalr	1968(ra) # 800032cc <bmap>
    80003b24:	0005059b          	sext.w	a1,a0
    80003b28:	8526                	mv	a0,s1
    80003b2a:	fffff097          	auipc	ra,0xfffff
    80003b2e:	3ae080e7          	jalr	942(ra) # 80002ed8 <bread>
    80003b32:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b34:	3ff97713          	andi	a4,s2,1023
    80003b38:	40ed07bb          	subw	a5,s10,a4
    80003b3c:	414b06bb          	subw	a3,s6,s4
    80003b40:	89be                	mv	s3,a5
    80003b42:	2781                	sext.w	a5,a5
    80003b44:	0006861b          	sext.w	a2,a3
    80003b48:	f8f674e3          	bgeu	a2,a5,80003ad0 <writei+0x4c>
    80003b4c:	89b6                	mv	s3,a3
    80003b4e:	b749                	j	80003ad0 <writei+0x4c>
      brelse(bp);
    80003b50:	8526                	mv	a0,s1
    80003b52:	fffff097          	auipc	ra,0xfffff
    80003b56:	4b6080e7          	jalr	1206(ra) # 80003008 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003b5a:	04cba783          	lw	a5,76(s7)
    80003b5e:	0127f463          	bgeu	a5,s2,80003b66 <writei+0xe2>
      ip->size = off;
    80003b62:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003b66:	855e                	mv	a0,s7
    80003b68:	00000097          	auipc	ra,0x0
    80003b6c:	aa8080e7          	jalr	-1368(ra) # 80003610 <iupdate>
  }

  return n;
    80003b70:	000b051b          	sext.w	a0,s6
}
    80003b74:	70a6                	ld	ra,104(sp)
    80003b76:	7406                	ld	s0,96(sp)
    80003b78:	64e6                	ld	s1,88(sp)
    80003b7a:	6946                	ld	s2,80(sp)
    80003b7c:	69a6                	ld	s3,72(sp)
    80003b7e:	6a06                	ld	s4,64(sp)
    80003b80:	7ae2                	ld	s5,56(sp)
    80003b82:	7b42                	ld	s6,48(sp)
    80003b84:	7ba2                	ld	s7,40(sp)
    80003b86:	7c02                	ld	s8,32(sp)
    80003b88:	6ce2                	ld	s9,24(sp)
    80003b8a:	6d42                	ld	s10,16(sp)
    80003b8c:	6da2                	ld	s11,8(sp)
    80003b8e:	6165                	addi	sp,sp,112
    80003b90:	8082                	ret
    return -1;
    80003b92:	557d                	li	a0,-1
}
    80003b94:	8082                	ret
    return -1;
    80003b96:	557d                	li	a0,-1
    80003b98:	bff1                	j	80003b74 <writei+0xf0>
    return -1;
    80003b9a:	557d                	li	a0,-1
    80003b9c:	bfe1                	j	80003b74 <writei+0xf0>

0000000080003b9e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b9e:	1141                	addi	sp,sp,-16
    80003ba0:	e406                	sd	ra,8(sp)
    80003ba2:	e022                	sd	s0,0(sp)
    80003ba4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ba6:	4639                	li	a2,14
    80003ba8:	ffffd097          	auipc	ra,0xffffd
    80003bac:	240080e7          	jalr	576(ra) # 80000de8 <strncmp>
}
    80003bb0:	60a2                	ld	ra,8(sp)
    80003bb2:	6402                	ld	s0,0(sp)
    80003bb4:	0141                	addi	sp,sp,16
    80003bb6:	8082                	ret

0000000080003bb8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bb8:	7139                	addi	sp,sp,-64
    80003bba:	fc06                	sd	ra,56(sp)
    80003bbc:	f822                	sd	s0,48(sp)
    80003bbe:	f426                	sd	s1,40(sp)
    80003bc0:	f04a                	sd	s2,32(sp)
    80003bc2:	ec4e                	sd	s3,24(sp)
    80003bc4:	e852                	sd	s4,16(sp)
    80003bc6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bc8:	04451703          	lh	a4,68(a0)
    80003bcc:	4785                	li	a5,1
    80003bce:	00f71a63          	bne	a4,a5,80003be2 <dirlookup+0x2a>
    80003bd2:	892a                	mv	s2,a0
    80003bd4:	89ae                	mv	s3,a1
    80003bd6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bd8:	457c                	lw	a5,76(a0)
    80003bda:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bdc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bde:	e79d                	bnez	a5,80003c0c <dirlookup+0x54>
    80003be0:	a8a5                	j	80003c58 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003be2:	00005517          	auipc	a0,0x5
    80003be6:	b6650513          	addi	a0,a0,-1178 # 80008748 <syscallnumber_to_name+0x1a8>
    80003bea:	ffffd097          	auipc	ra,0xffffd
    80003bee:	95e080e7          	jalr	-1698(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003bf2:	00005517          	auipc	a0,0x5
    80003bf6:	b6e50513          	addi	a0,a0,-1170 # 80008760 <syscallnumber_to_name+0x1c0>
    80003bfa:	ffffd097          	auipc	ra,0xffffd
    80003bfe:	94e080e7          	jalr	-1714(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c02:	24c1                	addiw	s1,s1,16
    80003c04:	04c92783          	lw	a5,76(s2)
    80003c08:	04f4f763          	bgeu	s1,a5,80003c56 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c0c:	4741                	li	a4,16
    80003c0e:	86a6                	mv	a3,s1
    80003c10:	fc040613          	addi	a2,s0,-64
    80003c14:	4581                	li	a1,0
    80003c16:	854a                	mv	a0,s2
    80003c18:	00000097          	auipc	ra,0x0
    80003c1c:	d76080e7          	jalr	-650(ra) # 8000398e <readi>
    80003c20:	47c1                	li	a5,16
    80003c22:	fcf518e3          	bne	a0,a5,80003bf2 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c26:	fc045783          	lhu	a5,-64(s0)
    80003c2a:	dfe1                	beqz	a5,80003c02 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c2c:	fc240593          	addi	a1,s0,-62
    80003c30:	854e                	mv	a0,s3
    80003c32:	00000097          	auipc	ra,0x0
    80003c36:	f6c080e7          	jalr	-148(ra) # 80003b9e <namecmp>
    80003c3a:	f561                	bnez	a0,80003c02 <dirlookup+0x4a>
      if(poff)
    80003c3c:	000a0463          	beqz	s4,80003c44 <dirlookup+0x8c>
        *poff = off;
    80003c40:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c44:	fc045583          	lhu	a1,-64(s0)
    80003c48:	00092503          	lw	a0,0(s2)
    80003c4c:	fffff097          	auipc	ra,0xfffff
    80003c50:	75a080e7          	jalr	1882(ra) # 800033a6 <iget>
    80003c54:	a011                	j	80003c58 <dirlookup+0xa0>
  return 0;
    80003c56:	4501                	li	a0,0
}
    80003c58:	70e2                	ld	ra,56(sp)
    80003c5a:	7442                	ld	s0,48(sp)
    80003c5c:	74a2                	ld	s1,40(sp)
    80003c5e:	7902                	ld	s2,32(sp)
    80003c60:	69e2                	ld	s3,24(sp)
    80003c62:	6a42                	ld	s4,16(sp)
    80003c64:	6121                	addi	sp,sp,64
    80003c66:	8082                	ret

0000000080003c68 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c68:	711d                	addi	sp,sp,-96
    80003c6a:	ec86                	sd	ra,88(sp)
    80003c6c:	e8a2                	sd	s0,80(sp)
    80003c6e:	e4a6                	sd	s1,72(sp)
    80003c70:	e0ca                	sd	s2,64(sp)
    80003c72:	fc4e                	sd	s3,56(sp)
    80003c74:	f852                	sd	s4,48(sp)
    80003c76:	f456                	sd	s5,40(sp)
    80003c78:	f05a                	sd	s6,32(sp)
    80003c7a:	ec5e                	sd	s7,24(sp)
    80003c7c:	e862                	sd	s8,16(sp)
    80003c7e:	e466                	sd	s9,8(sp)
    80003c80:	1080                	addi	s0,sp,96
    80003c82:	84aa                	mv	s1,a0
    80003c84:	8b2e                	mv	s6,a1
    80003c86:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c88:	00054703          	lbu	a4,0(a0)
    80003c8c:	02f00793          	li	a5,47
    80003c90:	02f70363          	beq	a4,a5,80003cb6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c94:	ffffe097          	auipc	ra,0xffffe
    80003c98:	d4a080e7          	jalr	-694(ra) # 800019de <myproc>
    80003c9c:	15053503          	ld	a0,336(a0)
    80003ca0:	00000097          	auipc	ra,0x0
    80003ca4:	9fc080e7          	jalr	-1540(ra) # 8000369c <idup>
    80003ca8:	89aa                	mv	s3,a0
  while(*path == '/')
    80003caa:	02f00913          	li	s2,47
  len = path - s;
    80003cae:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003cb0:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cb2:	4c05                	li	s8,1
    80003cb4:	a865                	j	80003d6c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003cb6:	4585                	li	a1,1
    80003cb8:	4505                	li	a0,1
    80003cba:	fffff097          	auipc	ra,0xfffff
    80003cbe:	6ec080e7          	jalr	1772(ra) # 800033a6 <iget>
    80003cc2:	89aa                	mv	s3,a0
    80003cc4:	b7dd                	j	80003caa <namex+0x42>
      iunlockput(ip);
    80003cc6:	854e                	mv	a0,s3
    80003cc8:	00000097          	auipc	ra,0x0
    80003ccc:	c74080e7          	jalr	-908(ra) # 8000393c <iunlockput>
      return 0;
    80003cd0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003cd2:	854e                	mv	a0,s3
    80003cd4:	60e6                	ld	ra,88(sp)
    80003cd6:	6446                	ld	s0,80(sp)
    80003cd8:	64a6                	ld	s1,72(sp)
    80003cda:	6906                	ld	s2,64(sp)
    80003cdc:	79e2                	ld	s3,56(sp)
    80003cde:	7a42                	ld	s4,48(sp)
    80003ce0:	7aa2                	ld	s5,40(sp)
    80003ce2:	7b02                	ld	s6,32(sp)
    80003ce4:	6be2                	ld	s7,24(sp)
    80003ce6:	6c42                	ld	s8,16(sp)
    80003ce8:	6ca2                	ld	s9,8(sp)
    80003cea:	6125                	addi	sp,sp,96
    80003cec:	8082                	ret
      iunlock(ip);
    80003cee:	854e                	mv	a0,s3
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	aac080e7          	jalr	-1364(ra) # 8000379c <iunlock>
      return ip;
    80003cf8:	bfe9                	j	80003cd2 <namex+0x6a>
      iunlockput(ip);
    80003cfa:	854e                	mv	a0,s3
    80003cfc:	00000097          	auipc	ra,0x0
    80003d00:	c40080e7          	jalr	-960(ra) # 8000393c <iunlockput>
      return 0;
    80003d04:	89d2                	mv	s3,s4
    80003d06:	b7f1                	j	80003cd2 <namex+0x6a>
  len = path - s;
    80003d08:	40b48633          	sub	a2,s1,a1
    80003d0c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d10:	094cd463          	bge	s9,s4,80003d98 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d14:	4639                	li	a2,14
    80003d16:	8556                	mv	a0,s5
    80003d18:	ffffd097          	auipc	ra,0xffffd
    80003d1c:	054080e7          	jalr	84(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003d20:	0004c783          	lbu	a5,0(s1)
    80003d24:	01279763          	bne	a5,s2,80003d32 <namex+0xca>
    path++;
    80003d28:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d2a:	0004c783          	lbu	a5,0(s1)
    80003d2e:	ff278de3          	beq	a5,s2,80003d28 <namex+0xc0>
    ilock(ip);
    80003d32:	854e                	mv	a0,s3
    80003d34:	00000097          	auipc	ra,0x0
    80003d38:	9a6080e7          	jalr	-1626(ra) # 800036da <ilock>
    if(ip->type != T_DIR){
    80003d3c:	04499783          	lh	a5,68(s3)
    80003d40:	f98793e3          	bne	a5,s8,80003cc6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d44:	000b0563          	beqz	s6,80003d4e <namex+0xe6>
    80003d48:	0004c783          	lbu	a5,0(s1)
    80003d4c:	d3cd                	beqz	a5,80003cee <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d4e:	865e                	mv	a2,s7
    80003d50:	85d6                	mv	a1,s5
    80003d52:	854e                	mv	a0,s3
    80003d54:	00000097          	auipc	ra,0x0
    80003d58:	e64080e7          	jalr	-412(ra) # 80003bb8 <dirlookup>
    80003d5c:	8a2a                	mv	s4,a0
    80003d5e:	dd51                	beqz	a0,80003cfa <namex+0x92>
    iunlockput(ip);
    80003d60:	854e                	mv	a0,s3
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	bda080e7          	jalr	-1062(ra) # 8000393c <iunlockput>
    ip = next;
    80003d6a:	89d2                	mv	s3,s4
  while(*path == '/')
    80003d6c:	0004c783          	lbu	a5,0(s1)
    80003d70:	05279763          	bne	a5,s2,80003dbe <namex+0x156>
    path++;
    80003d74:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d76:	0004c783          	lbu	a5,0(s1)
    80003d7a:	ff278de3          	beq	a5,s2,80003d74 <namex+0x10c>
  if(*path == 0)
    80003d7e:	c79d                	beqz	a5,80003dac <namex+0x144>
    path++;
    80003d80:	85a6                	mv	a1,s1
  len = path - s;
    80003d82:	8a5e                	mv	s4,s7
    80003d84:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d86:	01278963          	beq	a5,s2,80003d98 <namex+0x130>
    80003d8a:	dfbd                	beqz	a5,80003d08 <namex+0xa0>
    path++;
    80003d8c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d8e:	0004c783          	lbu	a5,0(s1)
    80003d92:	ff279ce3          	bne	a5,s2,80003d8a <namex+0x122>
    80003d96:	bf8d                	j	80003d08 <namex+0xa0>
    memmove(name, s, len);
    80003d98:	2601                	sext.w	a2,a2
    80003d9a:	8556                	mv	a0,s5
    80003d9c:	ffffd097          	auipc	ra,0xffffd
    80003da0:	fd0080e7          	jalr	-48(ra) # 80000d6c <memmove>
    name[len] = 0;
    80003da4:	9a56                	add	s4,s4,s5
    80003da6:	000a0023          	sb	zero,0(s4)
    80003daa:	bf9d                	j	80003d20 <namex+0xb8>
  if(nameiparent){
    80003dac:	f20b03e3          	beqz	s6,80003cd2 <namex+0x6a>
    iput(ip);
    80003db0:	854e                	mv	a0,s3
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	ae2080e7          	jalr	-1310(ra) # 80003894 <iput>
    return 0;
    80003dba:	4981                	li	s3,0
    80003dbc:	bf19                	j	80003cd2 <namex+0x6a>
  if(*path == 0)
    80003dbe:	d7fd                	beqz	a5,80003dac <namex+0x144>
  while(*path != '/' && *path != 0)
    80003dc0:	0004c783          	lbu	a5,0(s1)
    80003dc4:	85a6                	mv	a1,s1
    80003dc6:	b7d1                	j	80003d8a <namex+0x122>

0000000080003dc8 <dirlink>:
{
    80003dc8:	7139                	addi	sp,sp,-64
    80003dca:	fc06                	sd	ra,56(sp)
    80003dcc:	f822                	sd	s0,48(sp)
    80003dce:	f426                	sd	s1,40(sp)
    80003dd0:	f04a                	sd	s2,32(sp)
    80003dd2:	ec4e                	sd	s3,24(sp)
    80003dd4:	e852                	sd	s4,16(sp)
    80003dd6:	0080                	addi	s0,sp,64
    80003dd8:	892a                	mv	s2,a0
    80003dda:	8a2e                	mv	s4,a1
    80003ddc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003dde:	4601                	li	a2,0
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	dd8080e7          	jalr	-552(ra) # 80003bb8 <dirlookup>
    80003de8:	e93d                	bnez	a0,80003e5e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dea:	04c92483          	lw	s1,76(s2)
    80003dee:	c49d                	beqz	s1,80003e1c <dirlink+0x54>
    80003df0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003df2:	4741                	li	a4,16
    80003df4:	86a6                	mv	a3,s1
    80003df6:	fc040613          	addi	a2,s0,-64
    80003dfa:	4581                	li	a1,0
    80003dfc:	854a                	mv	a0,s2
    80003dfe:	00000097          	auipc	ra,0x0
    80003e02:	b90080e7          	jalr	-1136(ra) # 8000398e <readi>
    80003e06:	47c1                	li	a5,16
    80003e08:	06f51163          	bne	a0,a5,80003e6a <dirlink+0xa2>
    if(de.inum == 0)
    80003e0c:	fc045783          	lhu	a5,-64(s0)
    80003e10:	c791                	beqz	a5,80003e1c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e12:	24c1                	addiw	s1,s1,16
    80003e14:	04c92783          	lw	a5,76(s2)
    80003e18:	fcf4ede3          	bltu	s1,a5,80003df2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e1c:	4639                	li	a2,14
    80003e1e:	85d2                	mv	a1,s4
    80003e20:	fc240513          	addi	a0,s0,-62
    80003e24:	ffffd097          	auipc	ra,0xffffd
    80003e28:	000080e7          	jalr	ra # 80000e24 <strncpy>
  de.inum = inum;
    80003e2c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e30:	4741                	li	a4,16
    80003e32:	86a6                	mv	a3,s1
    80003e34:	fc040613          	addi	a2,s0,-64
    80003e38:	4581                	li	a1,0
    80003e3a:	854a                	mv	a0,s2
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	c48080e7          	jalr	-952(ra) # 80003a84 <writei>
    80003e44:	872a                	mv	a4,a0
    80003e46:	47c1                	li	a5,16
  return 0;
    80003e48:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e4a:	02f71863          	bne	a4,a5,80003e7a <dirlink+0xb2>
}
    80003e4e:	70e2                	ld	ra,56(sp)
    80003e50:	7442                	ld	s0,48(sp)
    80003e52:	74a2                	ld	s1,40(sp)
    80003e54:	7902                	ld	s2,32(sp)
    80003e56:	69e2                	ld	s3,24(sp)
    80003e58:	6a42                	ld	s4,16(sp)
    80003e5a:	6121                	addi	sp,sp,64
    80003e5c:	8082                	ret
    iput(ip);
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	a36080e7          	jalr	-1482(ra) # 80003894 <iput>
    return -1;
    80003e66:	557d                	li	a0,-1
    80003e68:	b7dd                	j	80003e4e <dirlink+0x86>
      panic("dirlink read");
    80003e6a:	00005517          	auipc	a0,0x5
    80003e6e:	90650513          	addi	a0,a0,-1786 # 80008770 <syscallnumber_to_name+0x1d0>
    80003e72:	ffffc097          	auipc	ra,0xffffc
    80003e76:	6d6080e7          	jalr	1750(ra) # 80000548 <panic>
    panic("dirlink");
    80003e7a:	00005517          	auipc	a0,0x5
    80003e7e:	a0e50513          	addi	a0,a0,-1522 # 80008888 <syscallnumber_to_name+0x2e8>
    80003e82:	ffffc097          	auipc	ra,0xffffc
    80003e86:	6c6080e7          	jalr	1734(ra) # 80000548 <panic>

0000000080003e8a <namei>:

struct inode*
namei(char *path)
{
    80003e8a:	1101                	addi	sp,sp,-32
    80003e8c:	ec06                	sd	ra,24(sp)
    80003e8e:	e822                	sd	s0,16(sp)
    80003e90:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e92:	fe040613          	addi	a2,s0,-32
    80003e96:	4581                	li	a1,0
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	dd0080e7          	jalr	-560(ra) # 80003c68 <namex>
}
    80003ea0:	60e2                	ld	ra,24(sp)
    80003ea2:	6442                	ld	s0,16(sp)
    80003ea4:	6105                	addi	sp,sp,32
    80003ea6:	8082                	ret

0000000080003ea8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ea8:	1141                	addi	sp,sp,-16
    80003eaa:	e406                	sd	ra,8(sp)
    80003eac:	e022                	sd	s0,0(sp)
    80003eae:	0800                	addi	s0,sp,16
    80003eb0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003eb2:	4585                	li	a1,1
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	db4080e7          	jalr	-588(ra) # 80003c68 <namex>
}
    80003ebc:	60a2                	ld	ra,8(sp)
    80003ebe:	6402                	ld	s0,0(sp)
    80003ec0:	0141                	addi	sp,sp,16
    80003ec2:	8082                	ret

0000000080003ec4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003ec4:	1101                	addi	sp,sp,-32
    80003ec6:	ec06                	sd	ra,24(sp)
    80003ec8:	e822                	sd	s0,16(sp)
    80003eca:	e426                	sd	s1,8(sp)
    80003ecc:	e04a                	sd	s2,0(sp)
    80003ece:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ed0:	0001e917          	auipc	s2,0x1e
    80003ed4:	a3890913          	addi	s2,s2,-1480 # 80021908 <log>
    80003ed8:	01892583          	lw	a1,24(s2)
    80003edc:	02892503          	lw	a0,40(s2)
    80003ee0:	fffff097          	auipc	ra,0xfffff
    80003ee4:	ff8080e7          	jalr	-8(ra) # 80002ed8 <bread>
    80003ee8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003eea:	02c92683          	lw	a3,44(s2)
    80003eee:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ef0:	02d05763          	blez	a3,80003f1e <write_head+0x5a>
    80003ef4:	0001e797          	auipc	a5,0x1e
    80003ef8:	a4478793          	addi	a5,a5,-1468 # 80021938 <log+0x30>
    80003efc:	05c50713          	addi	a4,a0,92
    80003f00:	36fd                	addiw	a3,a3,-1
    80003f02:	1682                	slli	a3,a3,0x20
    80003f04:	9281                	srli	a3,a3,0x20
    80003f06:	068a                	slli	a3,a3,0x2
    80003f08:	0001e617          	auipc	a2,0x1e
    80003f0c:	a3460613          	addi	a2,a2,-1484 # 8002193c <log+0x34>
    80003f10:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f12:	4390                	lw	a2,0(a5)
    80003f14:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f16:	0791                	addi	a5,a5,4
    80003f18:	0711                	addi	a4,a4,4
    80003f1a:	fed79ce3          	bne	a5,a3,80003f12 <write_head+0x4e>
  }
  bwrite(buf);
    80003f1e:	8526                	mv	a0,s1
    80003f20:	fffff097          	auipc	ra,0xfffff
    80003f24:	0aa080e7          	jalr	170(ra) # 80002fca <bwrite>
  brelse(buf);
    80003f28:	8526                	mv	a0,s1
    80003f2a:	fffff097          	auipc	ra,0xfffff
    80003f2e:	0de080e7          	jalr	222(ra) # 80003008 <brelse>
}
    80003f32:	60e2                	ld	ra,24(sp)
    80003f34:	6442                	ld	s0,16(sp)
    80003f36:	64a2                	ld	s1,8(sp)
    80003f38:	6902                	ld	s2,0(sp)
    80003f3a:	6105                	addi	sp,sp,32
    80003f3c:	8082                	ret

0000000080003f3e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f3e:	0001e797          	auipc	a5,0x1e
    80003f42:	9f67a783          	lw	a5,-1546(a5) # 80021934 <log+0x2c>
    80003f46:	0af05663          	blez	a5,80003ff2 <install_trans+0xb4>
{
    80003f4a:	7139                	addi	sp,sp,-64
    80003f4c:	fc06                	sd	ra,56(sp)
    80003f4e:	f822                	sd	s0,48(sp)
    80003f50:	f426                	sd	s1,40(sp)
    80003f52:	f04a                	sd	s2,32(sp)
    80003f54:	ec4e                	sd	s3,24(sp)
    80003f56:	e852                	sd	s4,16(sp)
    80003f58:	e456                	sd	s5,8(sp)
    80003f5a:	0080                	addi	s0,sp,64
    80003f5c:	0001ea97          	auipc	s5,0x1e
    80003f60:	9dca8a93          	addi	s5,s5,-1572 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f64:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f66:	0001e997          	auipc	s3,0x1e
    80003f6a:	9a298993          	addi	s3,s3,-1630 # 80021908 <log>
    80003f6e:	0189a583          	lw	a1,24(s3)
    80003f72:	014585bb          	addw	a1,a1,s4
    80003f76:	2585                	addiw	a1,a1,1
    80003f78:	0289a503          	lw	a0,40(s3)
    80003f7c:	fffff097          	auipc	ra,0xfffff
    80003f80:	f5c080e7          	jalr	-164(ra) # 80002ed8 <bread>
    80003f84:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f86:	000aa583          	lw	a1,0(s5)
    80003f8a:	0289a503          	lw	a0,40(s3)
    80003f8e:	fffff097          	auipc	ra,0xfffff
    80003f92:	f4a080e7          	jalr	-182(ra) # 80002ed8 <bread>
    80003f96:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f98:	40000613          	li	a2,1024
    80003f9c:	05890593          	addi	a1,s2,88
    80003fa0:	05850513          	addi	a0,a0,88
    80003fa4:	ffffd097          	auipc	ra,0xffffd
    80003fa8:	dc8080e7          	jalr	-568(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fac:	8526                	mv	a0,s1
    80003fae:	fffff097          	auipc	ra,0xfffff
    80003fb2:	01c080e7          	jalr	28(ra) # 80002fca <bwrite>
    bunpin(dbuf);
    80003fb6:	8526                	mv	a0,s1
    80003fb8:	fffff097          	auipc	ra,0xfffff
    80003fbc:	12a080e7          	jalr	298(ra) # 800030e2 <bunpin>
    brelse(lbuf);
    80003fc0:	854a                	mv	a0,s2
    80003fc2:	fffff097          	auipc	ra,0xfffff
    80003fc6:	046080e7          	jalr	70(ra) # 80003008 <brelse>
    brelse(dbuf);
    80003fca:	8526                	mv	a0,s1
    80003fcc:	fffff097          	auipc	ra,0xfffff
    80003fd0:	03c080e7          	jalr	60(ra) # 80003008 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fd4:	2a05                	addiw	s4,s4,1
    80003fd6:	0a91                	addi	s5,s5,4
    80003fd8:	02c9a783          	lw	a5,44(s3)
    80003fdc:	f8fa49e3          	blt	s4,a5,80003f6e <install_trans+0x30>
}
    80003fe0:	70e2                	ld	ra,56(sp)
    80003fe2:	7442                	ld	s0,48(sp)
    80003fe4:	74a2                	ld	s1,40(sp)
    80003fe6:	7902                	ld	s2,32(sp)
    80003fe8:	69e2                	ld	s3,24(sp)
    80003fea:	6a42                	ld	s4,16(sp)
    80003fec:	6aa2                	ld	s5,8(sp)
    80003fee:	6121                	addi	sp,sp,64
    80003ff0:	8082                	ret
    80003ff2:	8082                	ret

0000000080003ff4 <initlog>:
{
    80003ff4:	7179                	addi	sp,sp,-48
    80003ff6:	f406                	sd	ra,40(sp)
    80003ff8:	f022                	sd	s0,32(sp)
    80003ffa:	ec26                	sd	s1,24(sp)
    80003ffc:	e84a                	sd	s2,16(sp)
    80003ffe:	e44e                	sd	s3,8(sp)
    80004000:	1800                	addi	s0,sp,48
    80004002:	892a                	mv	s2,a0
    80004004:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004006:	0001e497          	auipc	s1,0x1e
    8000400a:	90248493          	addi	s1,s1,-1790 # 80021908 <log>
    8000400e:	00004597          	auipc	a1,0x4
    80004012:	77258593          	addi	a1,a1,1906 # 80008780 <syscallnumber_to_name+0x1e0>
    80004016:	8526                	mv	a0,s1
    80004018:	ffffd097          	auipc	ra,0xffffd
    8000401c:	b68080e7          	jalr	-1176(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    80004020:	0149a583          	lw	a1,20(s3)
    80004024:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004026:	0109a783          	lw	a5,16(s3)
    8000402a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000402c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004030:	854a                	mv	a0,s2
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	ea6080e7          	jalr	-346(ra) # 80002ed8 <bread>
  log.lh.n = lh->n;
    8000403a:	4d3c                	lw	a5,88(a0)
    8000403c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000403e:	02f05563          	blez	a5,80004068 <initlog+0x74>
    80004042:	05c50713          	addi	a4,a0,92
    80004046:	0001e697          	auipc	a3,0x1e
    8000404a:	8f268693          	addi	a3,a3,-1806 # 80021938 <log+0x30>
    8000404e:	37fd                	addiw	a5,a5,-1
    80004050:	1782                	slli	a5,a5,0x20
    80004052:	9381                	srli	a5,a5,0x20
    80004054:	078a                	slli	a5,a5,0x2
    80004056:	06050613          	addi	a2,a0,96
    8000405a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000405c:	4310                	lw	a2,0(a4)
    8000405e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004060:	0711                	addi	a4,a4,4
    80004062:	0691                	addi	a3,a3,4
    80004064:	fef71ce3          	bne	a4,a5,8000405c <initlog+0x68>
  brelse(buf);
    80004068:	fffff097          	auipc	ra,0xfffff
    8000406c:	fa0080e7          	jalr	-96(ra) # 80003008 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004070:	00000097          	auipc	ra,0x0
    80004074:	ece080e7          	jalr	-306(ra) # 80003f3e <install_trans>
  log.lh.n = 0;
    80004078:	0001e797          	auipc	a5,0x1e
    8000407c:	8a07ae23          	sw	zero,-1860(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    80004080:	00000097          	auipc	ra,0x0
    80004084:	e44080e7          	jalr	-444(ra) # 80003ec4 <write_head>
}
    80004088:	70a2                	ld	ra,40(sp)
    8000408a:	7402                	ld	s0,32(sp)
    8000408c:	64e2                	ld	s1,24(sp)
    8000408e:	6942                	ld	s2,16(sp)
    80004090:	69a2                	ld	s3,8(sp)
    80004092:	6145                	addi	sp,sp,48
    80004094:	8082                	ret

0000000080004096 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004096:	1101                	addi	sp,sp,-32
    80004098:	ec06                	sd	ra,24(sp)
    8000409a:	e822                	sd	s0,16(sp)
    8000409c:	e426                	sd	s1,8(sp)
    8000409e:	e04a                	sd	s2,0(sp)
    800040a0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040a2:	0001e517          	auipc	a0,0x1e
    800040a6:	86650513          	addi	a0,a0,-1946 # 80021908 <log>
    800040aa:	ffffd097          	auipc	ra,0xffffd
    800040ae:	b66080e7          	jalr	-1178(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    800040b2:	0001e497          	auipc	s1,0x1e
    800040b6:	85648493          	addi	s1,s1,-1962 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040ba:	4979                	li	s2,30
    800040bc:	a039                	j	800040ca <begin_op+0x34>
      sleep(&log, &log.lock);
    800040be:	85a6                	mv	a1,s1
    800040c0:	8526                	mv	a0,s1
    800040c2:	ffffe097          	auipc	ra,0xffffe
    800040c6:	134080e7          	jalr	308(ra) # 800021f6 <sleep>
    if(log.committing){
    800040ca:	50dc                	lw	a5,36(s1)
    800040cc:	fbed                	bnez	a5,800040be <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040ce:	509c                	lw	a5,32(s1)
    800040d0:	0017871b          	addiw	a4,a5,1
    800040d4:	0007069b          	sext.w	a3,a4
    800040d8:	0027179b          	slliw	a5,a4,0x2
    800040dc:	9fb9                	addw	a5,a5,a4
    800040de:	0017979b          	slliw	a5,a5,0x1
    800040e2:	54d8                	lw	a4,44(s1)
    800040e4:	9fb9                	addw	a5,a5,a4
    800040e6:	00f95963          	bge	s2,a5,800040f8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040ea:	85a6                	mv	a1,s1
    800040ec:	8526                	mv	a0,s1
    800040ee:	ffffe097          	auipc	ra,0xffffe
    800040f2:	108080e7          	jalr	264(ra) # 800021f6 <sleep>
    800040f6:	bfd1                	j	800040ca <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040f8:	0001e517          	auipc	a0,0x1e
    800040fc:	81050513          	addi	a0,a0,-2032 # 80021908 <log>
    80004100:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004102:	ffffd097          	auipc	ra,0xffffd
    80004106:	bc2080e7          	jalr	-1086(ra) # 80000cc4 <release>
      break;
    }
  }
}
    8000410a:	60e2                	ld	ra,24(sp)
    8000410c:	6442                	ld	s0,16(sp)
    8000410e:	64a2                	ld	s1,8(sp)
    80004110:	6902                	ld	s2,0(sp)
    80004112:	6105                	addi	sp,sp,32
    80004114:	8082                	ret

0000000080004116 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004116:	7139                	addi	sp,sp,-64
    80004118:	fc06                	sd	ra,56(sp)
    8000411a:	f822                	sd	s0,48(sp)
    8000411c:	f426                	sd	s1,40(sp)
    8000411e:	f04a                	sd	s2,32(sp)
    80004120:	ec4e                	sd	s3,24(sp)
    80004122:	e852                	sd	s4,16(sp)
    80004124:	e456                	sd	s5,8(sp)
    80004126:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004128:	0001d497          	auipc	s1,0x1d
    8000412c:	7e048493          	addi	s1,s1,2016 # 80021908 <log>
    80004130:	8526                	mv	a0,s1
    80004132:	ffffd097          	auipc	ra,0xffffd
    80004136:	ade080e7          	jalr	-1314(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    8000413a:	509c                	lw	a5,32(s1)
    8000413c:	37fd                	addiw	a5,a5,-1
    8000413e:	0007891b          	sext.w	s2,a5
    80004142:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004144:	50dc                	lw	a5,36(s1)
    80004146:	efb9                	bnez	a5,800041a4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004148:	06091663          	bnez	s2,800041b4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000414c:	0001d497          	auipc	s1,0x1d
    80004150:	7bc48493          	addi	s1,s1,1980 # 80021908 <log>
    80004154:	4785                	li	a5,1
    80004156:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004158:	8526                	mv	a0,s1
    8000415a:	ffffd097          	auipc	ra,0xffffd
    8000415e:	b6a080e7          	jalr	-1174(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004162:	54dc                	lw	a5,44(s1)
    80004164:	06f04763          	bgtz	a5,800041d2 <end_op+0xbc>
    acquire(&log.lock);
    80004168:	0001d497          	auipc	s1,0x1d
    8000416c:	7a048493          	addi	s1,s1,1952 # 80021908 <log>
    80004170:	8526                	mv	a0,s1
    80004172:	ffffd097          	auipc	ra,0xffffd
    80004176:	a9e080e7          	jalr	-1378(ra) # 80000c10 <acquire>
    log.committing = 0;
    8000417a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000417e:	8526                	mv	a0,s1
    80004180:	ffffe097          	auipc	ra,0xffffe
    80004184:	1fc080e7          	jalr	508(ra) # 8000237c <wakeup>
    release(&log.lock);
    80004188:	8526                	mv	a0,s1
    8000418a:	ffffd097          	auipc	ra,0xffffd
    8000418e:	b3a080e7          	jalr	-1222(ra) # 80000cc4 <release>
}
    80004192:	70e2                	ld	ra,56(sp)
    80004194:	7442                	ld	s0,48(sp)
    80004196:	74a2                	ld	s1,40(sp)
    80004198:	7902                	ld	s2,32(sp)
    8000419a:	69e2                	ld	s3,24(sp)
    8000419c:	6a42                	ld	s4,16(sp)
    8000419e:	6aa2                	ld	s5,8(sp)
    800041a0:	6121                	addi	sp,sp,64
    800041a2:	8082                	ret
    panic("log.committing");
    800041a4:	00004517          	auipc	a0,0x4
    800041a8:	5e450513          	addi	a0,a0,1508 # 80008788 <syscallnumber_to_name+0x1e8>
    800041ac:	ffffc097          	auipc	ra,0xffffc
    800041b0:	39c080e7          	jalr	924(ra) # 80000548 <panic>
    wakeup(&log);
    800041b4:	0001d497          	auipc	s1,0x1d
    800041b8:	75448493          	addi	s1,s1,1876 # 80021908 <log>
    800041bc:	8526                	mv	a0,s1
    800041be:	ffffe097          	auipc	ra,0xffffe
    800041c2:	1be080e7          	jalr	446(ra) # 8000237c <wakeup>
  release(&log.lock);
    800041c6:	8526                	mv	a0,s1
    800041c8:	ffffd097          	auipc	ra,0xffffd
    800041cc:	afc080e7          	jalr	-1284(ra) # 80000cc4 <release>
  if(do_commit){
    800041d0:	b7c9                	j	80004192 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041d2:	0001da97          	auipc	s5,0x1d
    800041d6:	766a8a93          	addi	s5,s5,1894 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041da:	0001da17          	auipc	s4,0x1d
    800041de:	72ea0a13          	addi	s4,s4,1838 # 80021908 <log>
    800041e2:	018a2583          	lw	a1,24(s4)
    800041e6:	012585bb          	addw	a1,a1,s2
    800041ea:	2585                	addiw	a1,a1,1
    800041ec:	028a2503          	lw	a0,40(s4)
    800041f0:	fffff097          	auipc	ra,0xfffff
    800041f4:	ce8080e7          	jalr	-792(ra) # 80002ed8 <bread>
    800041f8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041fa:	000aa583          	lw	a1,0(s5)
    800041fe:	028a2503          	lw	a0,40(s4)
    80004202:	fffff097          	auipc	ra,0xfffff
    80004206:	cd6080e7          	jalr	-810(ra) # 80002ed8 <bread>
    8000420a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000420c:	40000613          	li	a2,1024
    80004210:	05850593          	addi	a1,a0,88
    80004214:	05848513          	addi	a0,s1,88
    80004218:	ffffd097          	auipc	ra,0xffffd
    8000421c:	b54080e7          	jalr	-1196(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    80004220:	8526                	mv	a0,s1
    80004222:	fffff097          	auipc	ra,0xfffff
    80004226:	da8080e7          	jalr	-600(ra) # 80002fca <bwrite>
    brelse(from);
    8000422a:	854e                	mv	a0,s3
    8000422c:	fffff097          	auipc	ra,0xfffff
    80004230:	ddc080e7          	jalr	-548(ra) # 80003008 <brelse>
    brelse(to);
    80004234:	8526                	mv	a0,s1
    80004236:	fffff097          	auipc	ra,0xfffff
    8000423a:	dd2080e7          	jalr	-558(ra) # 80003008 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000423e:	2905                	addiw	s2,s2,1
    80004240:	0a91                	addi	s5,s5,4
    80004242:	02ca2783          	lw	a5,44(s4)
    80004246:	f8f94ee3          	blt	s2,a5,800041e2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000424a:	00000097          	auipc	ra,0x0
    8000424e:	c7a080e7          	jalr	-902(ra) # 80003ec4 <write_head>
    install_trans(); // Now install writes to home locations
    80004252:	00000097          	auipc	ra,0x0
    80004256:	cec080e7          	jalr	-788(ra) # 80003f3e <install_trans>
    log.lh.n = 0;
    8000425a:	0001d797          	auipc	a5,0x1d
    8000425e:	6c07ad23          	sw	zero,1754(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004262:	00000097          	auipc	ra,0x0
    80004266:	c62080e7          	jalr	-926(ra) # 80003ec4 <write_head>
    8000426a:	bdfd                	j	80004168 <end_op+0x52>

000000008000426c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000426c:	1101                	addi	sp,sp,-32
    8000426e:	ec06                	sd	ra,24(sp)
    80004270:	e822                	sd	s0,16(sp)
    80004272:	e426                	sd	s1,8(sp)
    80004274:	e04a                	sd	s2,0(sp)
    80004276:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004278:	0001d717          	auipc	a4,0x1d
    8000427c:	6bc72703          	lw	a4,1724(a4) # 80021934 <log+0x2c>
    80004280:	47f5                	li	a5,29
    80004282:	08e7c063          	blt	a5,a4,80004302 <log_write+0x96>
    80004286:	84aa                	mv	s1,a0
    80004288:	0001d797          	auipc	a5,0x1d
    8000428c:	69c7a783          	lw	a5,1692(a5) # 80021924 <log+0x1c>
    80004290:	37fd                	addiw	a5,a5,-1
    80004292:	06f75863          	bge	a4,a5,80004302 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004296:	0001d797          	auipc	a5,0x1d
    8000429a:	6927a783          	lw	a5,1682(a5) # 80021928 <log+0x20>
    8000429e:	06f05a63          	blez	a5,80004312 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800042a2:	0001d917          	auipc	s2,0x1d
    800042a6:	66690913          	addi	s2,s2,1638 # 80021908 <log>
    800042aa:	854a                	mv	a0,s2
    800042ac:	ffffd097          	auipc	ra,0xffffd
    800042b0:	964080e7          	jalr	-1692(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800042b4:	02c92603          	lw	a2,44(s2)
    800042b8:	06c05563          	blez	a2,80004322 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042bc:	44cc                	lw	a1,12(s1)
    800042be:	0001d717          	auipc	a4,0x1d
    800042c2:	67a70713          	addi	a4,a4,1658 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042c6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042c8:	4314                	lw	a3,0(a4)
    800042ca:	04b68d63          	beq	a3,a1,80004324 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800042ce:	2785                	addiw	a5,a5,1
    800042d0:	0711                	addi	a4,a4,4
    800042d2:	fec79be3          	bne	a5,a2,800042c8 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042d6:	0621                	addi	a2,a2,8
    800042d8:	060a                	slli	a2,a2,0x2
    800042da:	0001d797          	auipc	a5,0x1d
    800042de:	62e78793          	addi	a5,a5,1582 # 80021908 <log>
    800042e2:	963e                	add	a2,a2,a5
    800042e4:	44dc                	lw	a5,12(s1)
    800042e6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042e8:	8526                	mv	a0,s1
    800042ea:	fffff097          	auipc	ra,0xfffff
    800042ee:	dbc080e7          	jalr	-580(ra) # 800030a6 <bpin>
    log.lh.n++;
    800042f2:	0001d717          	auipc	a4,0x1d
    800042f6:	61670713          	addi	a4,a4,1558 # 80021908 <log>
    800042fa:	575c                	lw	a5,44(a4)
    800042fc:	2785                	addiw	a5,a5,1
    800042fe:	d75c                	sw	a5,44(a4)
    80004300:	a83d                	j	8000433e <log_write+0xd2>
    panic("too big a transaction");
    80004302:	00004517          	auipc	a0,0x4
    80004306:	49650513          	addi	a0,a0,1174 # 80008798 <syscallnumber_to_name+0x1f8>
    8000430a:	ffffc097          	auipc	ra,0xffffc
    8000430e:	23e080e7          	jalr	574(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004312:	00004517          	auipc	a0,0x4
    80004316:	49e50513          	addi	a0,a0,1182 # 800087b0 <syscallnumber_to_name+0x210>
    8000431a:	ffffc097          	auipc	ra,0xffffc
    8000431e:	22e080e7          	jalr	558(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004322:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004324:	00878713          	addi	a4,a5,8
    80004328:	00271693          	slli	a3,a4,0x2
    8000432c:	0001d717          	auipc	a4,0x1d
    80004330:	5dc70713          	addi	a4,a4,1500 # 80021908 <log>
    80004334:	9736                	add	a4,a4,a3
    80004336:	44d4                	lw	a3,12(s1)
    80004338:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000433a:	faf607e3          	beq	a2,a5,800042e8 <log_write+0x7c>
  }
  release(&log.lock);
    8000433e:	0001d517          	auipc	a0,0x1d
    80004342:	5ca50513          	addi	a0,a0,1482 # 80021908 <log>
    80004346:	ffffd097          	auipc	ra,0xffffd
    8000434a:	97e080e7          	jalr	-1666(ra) # 80000cc4 <release>
}
    8000434e:	60e2                	ld	ra,24(sp)
    80004350:	6442                	ld	s0,16(sp)
    80004352:	64a2                	ld	s1,8(sp)
    80004354:	6902                	ld	s2,0(sp)
    80004356:	6105                	addi	sp,sp,32
    80004358:	8082                	ret

000000008000435a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000435a:	1101                	addi	sp,sp,-32
    8000435c:	ec06                	sd	ra,24(sp)
    8000435e:	e822                	sd	s0,16(sp)
    80004360:	e426                	sd	s1,8(sp)
    80004362:	e04a                	sd	s2,0(sp)
    80004364:	1000                	addi	s0,sp,32
    80004366:	84aa                	mv	s1,a0
    80004368:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000436a:	00004597          	auipc	a1,0x4
    8000436e:	46658593          	addi	a1,a1,1126 # 800087d0 <syscallnumber_to_name+0x230>
    80004372:	0521                	addi	a0,a0,8
    80004374:	ffffd097          	auipc	ra,0xffffd
    80004378:	80c080e7          	jalr	-2036(ra) # 80000b80 <initlock>
  lk->name = name;
    8000437c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004380:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004384:	0204a423          	sw	zero,40(s1)
}
    80004388:	60e2                	ld	ra,24(sp)
    8000438a:	6442                	ld	s0,16(sp)
    8000438c:	64a2                	ld	s1,8(sp)
    8000438e:	6902                	ld	s2,0(sp)
    80004390:	6105                	addi	sp,sp,32
    80004392:	8082                	ret

0000000080004394 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004394:	1101                	addi	sp,sp,-32
    80004396:	ec06                	sd	ra,24(sp)
    80004398:	e822                	sd	s0,16(sp)
    8000439a:	e426                	sd	s1,8(sp)
    8000439c:	e04a                	sd	s2,0(sp)
    8000439e:	1000                	addi	s0,sp,32
    800043a0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043a2:	00850913          	addi	s2,a0,8
    800043a6:	854a                	mv	a0,s2
    800043a8:	ffffd097          	auipc	ra,0xffffd
    800043ac:	868080e7          	jalr	-1944(ra) # 80000c10 <acquire>
  while (lk->locked) {
    800043b0:	409c                	lw	a5,0(s1)
    800043b2:	cb89                	beqz	a5,800043c4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043b4:	85ca                	mv	a1,s2
    800043b6:	8526                	mv	a0,s1
    800043b8:	ffffe097          	auipc	ra,0xffffe
    800043bc:	e3e080e7          	jalr	-450(ra) # 800021f6 <sleep>
  while (lk->locked) {
    800043c0:	409c                	lw	a5,0(s1)
    800043c2:	fbed                	bnez	a5,800043b4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043c4:	4785                	li	a5,1
    800043c6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043c8:	ffffd097          	auipc	ra,0xffffd
    800043cc:	616080e7          	jalr	1558(ra) # 800019de <myproc>
    800043d0:	5d1c                	lw	a5,56(a0)
    800043d2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043d4:	854a                	mv	a0,s2
    800043d6:	ffffd097          	auipc	ra,0xffffd
    800043da:	8ee080e7          	jalr	-1810(ra) # 80000cc4 <release>
}
    800043de:	60e2                	ld	ra,24(sp)
    800043e0:	6442                	ld	s0,16(sp)
    800043e2:	64a2                	ld	s1,8(sp)
    800043e4:	6902                	ld	s2,0(sp)
    800043e6:	6105                	addi	sp,sp,32
    800043e8:	8082                	ret

00000000800043ea <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043ea:	1101                	addi	sp,sp,-32
    800043ec:	ec06                	sd	ra,24(sp)
    800043ee:	e822                	sd	s0,16(sp)
    800043f0:	e426                	sd	s1,8(sp)
    800043f2:	e04a                	sd	s2,0(sp)
    800043f4:	1000                	addi	s0,sp,32
    800043f6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043f8:	00850913          	addi	s2,a0,8
    800043fc:	854a                	mv	a0,s2
    800043fe:	ffffd097          	auipc	ra,0xffffd
    80004402:	812080e7          	jalr	-2030(ra) # 80000c10 <acquire>
  lk->locked = 0;
    80004406:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000440a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000440e:	8526                	mv	a0,s1
    80004410:	ffffe097          	auipc	ra,0xffffe
    80004414:	f6c080e7          	jalr	-148(ra) # 8000237c <wakeup>
  release(&lk->lk);
    80004418:	854a                	mv	a0,s2
    8000441a:	ffffd097          	auipc	ra,0xffffd
    8000441e:	8aa080e7          	jalr	-1878(ra) # 80000cc4 <release>
}
    80004422:	60e2                	ld	ra,24(sp)
    80004424:	6442                	ld	s0,16(sp)
    80004426:	64a2                	ld	s1,8(sp)
    80004428:	6902                	ld	s2,0(sp)
    8000442a:	6105                	addi	sp,sp,32
    8000442c:	8082                	ret

000000008000442e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000442e:	7179                	addi	sp,sp,-48
    80004430:	f406                	sd	ra,40(sp)
    80004432:	f022                	sd	s0,32(sp)
    80004434:	ec26                	sd	s1,24(sp)
    80004436:	e84a                	sd	s2,16(sp)
    80004438:	e44e                	sd	s3,8(sp)
    8000443a:	1800                	addi	s0,sp,48
    8000443c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000443e:	00850913          	addi	s2,a0,8
    80004442:	854a                	mv	a0,s2
    80004444:	ffffc097          	auipc	ra,0xffffc
    80004448:	7cc080e7          	jalr	1996(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000444c:	409c                	lw	a5,0(s1)
    8000444e:	ef99                	bnez	a5,8000446c <holdingsleep+0x3e>
    80004450:	4481                	li	s1,0
  release(&lk->lk);
    80004452:	854a                	mv	a0,s2
    80004454:	ffffd097          	auipc	ra,0xffffd
    80004458:	870080e7          	jalr	-1936(ra) # 80000cc4 <release>
  return r;
}
    8000445c:	8526                	mv	a0,s1
    8000445e:	70a2                	ld	ra,40(sp)
    80004460:	7402                	ld	s0,32(sp)
    80004462:	64e2                	ld	s1,24(sp)
    80004464:	6942                	ld	s2,16(sp)
    80004466:	69a2                	ld	s3,8(sp)
    80004468:	6145                	addi	sp,sp,48
    8000446a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000446c:	0284a983          	lw	s3,40(s1)
    80004470:	ffffd097          	auipc	ra,0xffffd
    80004474:	56e080e7          	jalr	1390(ra) # 800019de <myproc>
    80004478:	5d04                	lw	s1,56(a0)
    8000447a:	413484b3          	sub	s1,s1,s3
    8000447e:	0014b493          	seqz	s1,s1
    80004482:	bfc1                	j	80004452 <holdingsleep+0x24>

0000000080004484 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004484:	1141                	addi	sp,sp,-16
    80004486:	e406                	sd	ra,8(sp)
    80004488:	e022                	sd	s0,0(sp)
    8000448a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000448c:	00004597          	auipc	a1,0x4
    80004490:	35458593          	addi	a1,a1,852 # 800087e0 <syscallnumber_to_name+0x240>
    80004494:	0001d517          	auipc	a0,0x1d
    80004498:	5bc50513          	addi	a0,a0,1468 # 80021a50 <ftable>
    8000449c:	ffffc097          	auipc	ra,0xffffc
    800044a0:	6e4080e7          	jalr	1764(ra) # 80000b80 <initlock>
}
    800044a4:	60a2                	ld	ra,8(sp)
    800044a6:	6402                	ld	s0,0(sp)
    800044a8:	0141                	addi	sp,sp,16
    800044aa:	8082                	ret

00000000800044ac <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044ac:	1101                	addi	sp,sp,-32
    800044ae:	ec06                	sd	ra,24(sp)
    800044b0:	e822                	sd	s0,16(sp)
    800044b2:	e426                	sd	s1,8(sp)
    800044b4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044b6:	0001d517          	auipc	a0,0x1d
    800044ba:	59a50513          	addi	a0,a0,1434 # 80021a50 <ftable>
    800044be:	ffffc097          	auipc	ra,0xffffc
    800044c2:	752080e7          	jalr	1874(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044c6:	0001d497          	auipc	s1,0x1d
    800044ca:	5a248493          	addi	s1,s1,1442 # 80021a68 <ftable+0x18>
    800044ce:	0001e717          	auipc	a4,0x1e
    800044d2:	53a70713          	addi	a4,a4,1338 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    800044d6:	40dc                	lw	a5,4(s1)
    800044d8:	cf99                	beqz	a5,800044f6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044da:	02848493          	addi	s1,s1,40
    800044de:	fee49ce3          	bne	s1,a4,800044d6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044e2:	0001d517          	auipc	a0,0x1d
    800044e6:	56e50513          	addi	a0,a0,1390 # 80021a50 <ftable>
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	7da080e7          	jalr	2010(ra) # 80000cc4 <release>
  return 0;
    800044f2:	4481                	li	s1,0
    800044f4:	a819                	j	8000450a <filealloc+0x5e>
      f->ref = 1;
    800044f6:	4785                	li	a5,1
    800044f8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044fa:	0001d517          	auipc	a0,0x1d
    800044fe:	55650513          	addi	a0,a0,1366 # 80021a50 <ftable>
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	7c2080e7          	jalr	1986(ra) # 80000cc4 <release>
}
    8000450a:	8526                	mv	a0,s1
    8000450c:	60e2                	ld	ra,24(sp)
    8000450e:	6442                	ld	s0,16(sp)
    80004510:	64a2                	ld	s1,8(sp)
    80004512:	6105                	addi	sp,sp,32
    80004514:	8082                	ret

0000000080004516 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004516:	1101                	addi	sp,sp,-32
    80004518:	ec06                	sd	ra,24(sp)
    8000451a:	e822                	sd	s0,16(sp)
    8000451c:	e426                	sd	s1,8(sp)
    8000451e:	1000                	addi	s0,sp,32
    80004520:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004522:	0001d517          	auipc	a0,0x1d
    80004526:	52e50513          	addi	a0,a0,1326 # 80021a50 <ftable>
    8000452a:	ffffc097          	auipc	ra,0xffffc
    8000452e:	6e6080e7          	jalr	1766(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    80004532:	40dc                	lw	a5,4(s1)
    80004534:	02f05263          	blez	a5,80004558 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004538:	2785                	addiw	a5,a5,1
    8000453a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000453c:	0001d517          	auipc	a0,0x1d
    80004540:	51450513          	addi	a0,a0,1300 # 80021a50 <ftable>
    80004544:	ffffc097          	auipc	ra,0xffffc
    80004548:	780080e7          	jalr	1920(ra) # 80000cc4 <release>
  return f;
}
    8000454c:	8526                	mv	a0,s1
    8000454e:	60e2                	ld	ra,24(sp)
    80004550:	6442                	ld	s0,16(sp)
    80004552:	64a2                	ld	s1,8(sp)
    80004554:	6105                	addi	sp,sp,32
    80004556:	8082                	ret
    panic("filedup");
    80004558:	00004517          	auipc	a0,0x4
    8000455c:	29050513          	addi	a0,a0,656 # 800087e8 <syscallnumber_to_name+0x248>
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	fe8080e7          	jalr	-24(ra) # 80000548 <panic>

0000000080004568 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004568:	7139                	addi	sp,sp,-64
    8000456a:	fc06                	sd	ra,56(sp)
    8000456c:	f822                	sd	s0,48(sp)
    8000456e:	f426                	sd	s1,40(sp)
    80004570:	f04a                	sd	s2,32(sp)
    80004572:	ec4e                	sd	s3,24(sp)
    80004574:	e852                	sd	s4,16(sp)
    80004576:	e456                	sd	s5,8(sp)
    80004578:	0080                	addi	s0,sp,64
    8000457a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000457c:	0001d517          	auipc	a0,0x1d
    80004580:	4d450513          	addi	a0,a0,1236 # 80021a50 <ftable>
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	68c080e7          	jalr	1676(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    8000458c:	40dc                	lw	a5,4(s1)
    8000458e:	06f05163          	blez	a5,800045f0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004592:	37fd                	addiw	a5,a5,-1
    80004594:	0007871b          	sext.w	a4,a5
    80004598:	c0dc                	sw	a5,4(s1)
    8000459a:	06e04363          	bgtz	a4,80004600 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000459e:	0004a903          	lw	s2,0(s1)
    800045a2:	0094ca83          	lbu	s5,9(s1)
    800045a6:	0104ba03          	ld	s4,16(s1)
    800045aa:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045ae:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045b2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045b6:	0001d517          	auipc	a0,0x1d
    800045ba:	49a50513          	addi	a0,a0,1178 # 80021a50 <ftable>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	706080e7          	jalr	1798(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    800045c6:	4785                	li	a5,1
    800045c8:	04f90d63          	beq	s2,a5,80004622 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045cc:	3979                	addiw	s2,s2,-2
    800045ce:	4785                	li	a5,1
    800045d0:	0527e063          	bltu	a5,s2,80004610 <fileclose+0xa8>
    begin_op();
    800045d4:	00000097          	auipc	ra,0x0
    800045d8:	ac2080e7          	jalr	-1342(ra) # 80004096 <begin_op>
    iput(ff.ip);
    800045dc:	854e                	mv	a0,s3
    800045de:	fffff097          	auipc	ra,0xfffff
    800045e2:	2b6080e7          	jalr	694(ra) # 80003894 <iput>
    end_op();
    800045e6:	00000097          	auipc	ra,0x0
    800045ea:	b30080e7          	jalr	-1232(ra) # 80004116 <end_op>
    800045ee:	a00d                	j	80004610 <fileclose+0xa8>
    panic("fileclose");
    800045f0:	00004517          	auipc	a0,0x4
    800045f4:	20050513          	addi	a0,a0,512 # 800087f0 <syscallnumber_to_name+0x250>
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	f50080e7          	jalr	-176(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004600:	0001d517          	auipc	a0,0x1d
    80004604:	45050513          	addi	a0,a0,1104 # 80021a50 <ftable>
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	6bc080e7          	jalr	1724(ra) # 80000cc4 <release>
  }
}
    80004610:	70e2                	ld	ra,56(sp)
    80004612:	7442                	ld	s0,48(sp)
    80004614:	74a2                	ld	s1,40(sp)
    80004616:	7902                	ld	s2,32(sp)
    80004618:	69e2                	ld	s3,24(sp)
    8000461a:	6a42                	ld	s4,16(sp)
    8000461c:	6aa2                	ld	s5,8(sp)
    8000461e:	6121                	addi	sp,sp,64
    80004620:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004622:	85d6                	mv	a1,s5
    80004624:	8552                	mv	a0,s4
    80004626:	00000097          	auipc	ra,0x0
    8000462a:	372080e7          	jalr	882(ra) # 80004998 <pipeclose>
    8000462e:	b7cd                	j	80004610 <fileclose+0xa8>

0000000080004630 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004630:	715d                	addi	sp,sp,-80
    80004632:	e486                	sd	ra,72(sp)
    80004634:	e0a2                	sd	s0,64(sp)
    80004636:	fc26                	sd	s1,56(sp)
    80004638:	f84a                	sd	s2,48(sp)
    8000463a:	f44e                	sd	s3,40(sp)
    8000463c:	0880                	addi	s0,sp,80
    8000463e:	84aa                	mv	s1,a0
    80004640:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004642:	ffffd097          	auipc	ra,0xffffd
    80004646:	39c080e7          	jalr	924(ra) # 800019de <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000464a:	409c                	lw	a5,0(s1)
    8000464c:	37f9                	addiw	a5,a5,-2
    8000464e:	4705                	li	a4,1
    80004650:	04f76763          	bltu	a4,a5,8000469e <filestat+0x6e>
    80004654:	892a                	mv	s2,a0
    ilock(f->ip);
    80004656:	6c88                	ld	a0,24(s1)
    80004658:	fffff097          	auipc	ra,0xfffff
    8000465c:	082080e7          	jalr	130(ra) # 800036da <ilock>
    stati(f->ip, &st);
    80004660:	fb840593          	addi	a1,s0,-72
    80004664:	6c88                	ld	a0,24(s1)
    80004666:	fffff097          	auipc	ra,0xfffff
    8000466a:	2fe080e7          	jalr	766(ra) # 80003964 <stati>
    iunlock(f->ip);
    8000466e:	6c88                	ld	a0,24(s1)
    80004670:	fffff097          	auipc	ra,0xfffff
    80004674:	12c080e7          	jalr	300(ra) # 8000379c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004678:	46e1                	li	a3,24
    8000467a:	fb840613          	addi	a2,s0,-72
    8000467e:	85ce                	mv	a1,s3
    80004680:	05093503          	ld	a0,80(s2)
    80004684:	ffffd097          	auipc	ra,0xffffd
    80004688:	04e080e7          	jalr	78(ra) # 800016d2 <copyout>
    8000468c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004690:	60a6                	ld	ra,72(sp)
    80004692:	6406                	ld	s0,64(sp)
    80004694:	74e2                	ld	s1,56(sp)
    80004696:	7942                	ld	s2,48(sp)
    80004698:	79a2                	ld	s3,40(sp)
    8000469a:	6161                	addi	sp,sp,80
    8000469c:	8082                	ret
  return -1;
    8000469e:	557d                	li	a0,-1
    800046a0:	bfc5                	j	80004690 <filestat+0x60>

00000000800046a2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046a2:	7179                	addi	sp,sp,-48
    800046a4:	f406                	sd	ra,40(sp)
    800046a6:	f022                	sd	s0,32(sp)
    800046a8:	ec26                	sd	s1,24(sp)
    800046aa:	e84a                	sd	s2,16(sp)
    800046ac:	e44e                	sd	s3,8(sp)
    800046ae:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046b0:	00854783          	lbu	a5,8(a0)
    800046b4:	c3d5                	beqz	a5,80004758 <fileread+0xb6>
    800046b6:	84aa                	mv	s1,a0
    800046b8:	89ae                	mv	s3,a1
    800046ba:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046bc:	411c                	lw	a5,0(a0)
    800046be:	4705                	li	a4,1
    800046c0:	04e78963          	beq	a5,a4,80004712 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046c4:	470d                	li	a4,3
    800046c6:	04e78d63          	beq	a5,a4,80004720 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046ca:	4709                	li	a4,2
    800046cc:	06e79e63          	bne	a5,a4,80004748 <fileread+0xa6>
    ilock(f->ip);
    800046d0:	6d08                	ld	a0,24(a0)
    800046d2:	fffff097          	auipc	ra,0xfffff
    800046d6:	008080e7          	jalr	8(ra) # 800036da <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046da:	874a                	mv	a4,s2
    800046dc:	5094                	lw	a3,32(s1)
    800046de:	864e                	mv	a2,s3
    800046e0:	4585                	li	a1,1
    800046e2:	6c88                	ld	a0,24(s1)
    800046e4:	fffff097          	auipc	ra,0xfffff
    800046e8:	2aa080e7          	jalr	682(ra) # 8000398e <readi>
    800046ec:	892a                	mv	s2,a0
    800046ee:	00a05563          	blez	a0,800046f8 <fileread+0x56>
      f->off += r;
    800046f2:	509c                	lw	a5,32(s1)
    800046f4:	9fa9                	addw	a5,a5,a0
    800046f6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046f8:	6c88                	ld	a0,24(s1)
    800046fa:	fffff097          	auipc	ra,0xfffff
    800046fe:	0a2080e7          	jalr	162(ra) # 8000379c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004702:	854a                	mv	a0,s2
    80004704:	70a2                	ld	ra,40(sp)
    80004706:	7402                	ld	s0,32(sp)
    80004708:	64e2                	ld	s1,24(sp)
    8000470a:	6942                	ld	s2,16(sp)
    8000470c:	69a2                	ld	s3,8(sp)
    8000470e:	6145                	addi	sp,sp,48
    80004710:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004712:	6908                	ld	a0,16(a0)
    80004714:	00000097          	auipc	ra,0x0
    80004718:	418080e7          	jalr	1048(ra) # 80004b2c <piperead>
    8000471c:	892a                	mv	s2,a0
    8000471e:	b7d5                	j	80004702 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004720:	02451783          	lh	a5,36(a0)
    80004724:	03079693          	slli	a3,a5,0x30
    80004728:	92c1                	srli	a3,a3,0x30
    8000472a:	4725                	li	a4,9
    8000472c:	02d76863          	bltu	a4,a3,8000475c <fileread+0xba>
    80004730:	0792                	slli	a5,a5,0x4
    80004732:	0001d717          	auipc	a4,0x1d
    80004736:	27e70713          	addi	a4,a4,638 # 800219b0 <devsw>
    8000473a:	97ba                	add	a5,a5,a4
    8000473c:	639c                	ld	a5,0(a5)
    8000473e:	c38d                	beqz	a5,80004760 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004740:	4505                	li	a0,1
    80004742:	9782                	jalr	a5
    80004744:	892a                	mv	s2,a0
    80004746:	bf75                	j	80004702 <fileread+0x60>
    panic("fileread");
    80004748:	00004517          	auipc	a0,0x4
    8000474c:	0b850513          	addi	a0,a0,184 # 80008800 <syscallnumber_to_name+0x260>
    80004750:	ffffc097          	auipc	ra,0xffffc
    80004754:	df8080e7          	jalr	-520(ra) # 80000548 <panic>
    return -1;
    80004758:	597d                	li	s2,-1
    8000475a:	b765                	j	80004702 <fileread+0x60>
      return -1;
    8000475c:	597d                	li	s2,-1
    8000475e:	b755                	j	80004702 <fileread+0x60>
    80004760:	597d                	li	s2,-1
    80004762:	b745                	j	80004702 <fileread+0x60>

0000000080004764 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004764:	00954783          	lbu	a5,9(a0)
    80004768:	14078563          	beqz	a5,800048b2 <filewrite+0x14e>
{
    8000476c:	715d                	addi	sp,sp,-80
    8000476e:	e486                	sd	ra,72(sp)
    80004770:	e0a2                	sd	s0,64(sp)
    80004772:	fc26                	sd	s1,56(sp)
    80004774:	f84a                	sd	s2,48(sp)
    80004776:	f44e                	sd	s3,40(sp)
    80004778:	f052                	sd	s4,32(sp)
    8000477a:	ec56                	sd	s5,24(sp)
    8000477c:	e85a                	sd	s6,16(sp)
    8000477e:	e45e                	sd	s7,8(sp)
    80004780:	e062                	sd	s8,0(sp)
    80004782:	0880                	addi	s0,sp,80
    80004784:	892a                	mv	s2,a0
    80004786:	8aae                	mv	s5,a1
    80004788:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000478a:	411c                	lw	a5,0(a0)
    8000478c:	4705                	li	a4,1
    8000478e:	02e78263          	beq	a5,a4,800047b2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004792:	470d                	li	a4,3
    80004794:	02e78563          	beq	a5,a4,800047be <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004798:	4709                	li	a4,2
    8000479a:	10e79463          	bne	a5,a4,800048a2 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000479e:	0ec05e63          	blez	a2,8000489a <filewrite+0x136>
    int i = 0;
    800047a2:	4981                	li	s3,0
    800047a4:	6b05                	lui	s6,0x1
    800047a6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047aa:	6b85                	lui	s7,0x1
    800047ac:	c00b8b9b          	addiw	s7,s7,-1024
    800047b0:	a851                	j	80004844 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800047b2:	6908                	ld	a0,16(a0)
    800047b4:	00000097          	auipc	ra,0x0
    800047b8:	254080e7          	jalr	596(ra) # 80004a08 <pipewrite>
    800047bc:	a85d                	j	80004872 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047be:	02451783          	lh	a5,36(a0)
    800047c2:	03079693          	slli	a3,a5,0x30
    800047c6:	92c1                	srli	a3,a3,0x30
    800047c8:	4725                	li	a4,9
    800047ca:	0ed76663          	bltu	a4,a3,800048b6 <filewrite+0x152>
    800047ce:	0792                	slli	a5,a5,0x4
    800047d0:	0001d717          	auipc	a4,0x1d
    800047d4:	1e070713          	addi	a4,a4,480 # 800219b0 <devsw>
    800047d8:	97ba                	add	a5,a5,a4
    800047da:	679c                	ld	a5,8(a5)
    800047dc:	cff9                	beqz	a5,800048ba <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800047de:	4505                	li	a0,1
    800047e0:	9782                	jalr	a5
    800047e2:	a841                	j	80004872 <filewrite+0x10e>
    800047e4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047e8:	00000097          	auipc	ra,0x0
    800047ec:	8ae080e7          	jalr	-1874(ra) # 80004096 <begin_op>
      ilock(f->ip);
    800047f0:	01893503          	ld	a0,24(s2)
    800047f4:	fffff097          	auipc	ra,0xfffff
    800047f8:	ee6080e7          	jalr	-282(ra) # 800036da <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047fc:	8762                	mv	a4,s8
    800047fe:	02092683          	lw	a3,32(s2)
    80004802:	01598633          	add	a2,s3,s5
    80004806:	4585                	li	a1,1
    80004808:	01893503          	ld	a0,24(s2)
    8000480c:	fffff097          	auipc	ra,0xfffff
    80004810:	278080e7          	jalr	632(ra) # 80003a84 <writei>
    80004814:	84aa                	mv	s1,a0
    80004816:	02a05f63          	blez	a0,80004854 <filewrite+0xf0>
        f->off += r;
    8000481a:	02092783          	lw	a5,32(s2)
    8000481e:	9fa9                	addw	a5,a5,a0
    80004820:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004824:	01893503          	ld	a0,24(s2)
    80004828:	fffff097          	auipc	ra,0xfffff
    8000482c:	f74080e7          	jalr	-140(ra) # 8000379c <iunlock>
      end_op();
    80004830:	00000097          	auipc	ra,0x0
    80004834:	8e6080e7          	jalr	-1818(ra) # 80004116 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004838:	049c1963          	bne	s8,s1,8000488a <filewrite+0x126>
        panic("short filewrite");
      i += r;
    8000483c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004840:	0349d663          	bge	s3,s4,8000486c <filewrite+0x108>
      int n1 = n - i;
    80004844:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004848:	84be                	mv	s1,a5
    8000484a:	2781                	sext.w	a5,a5
    8000484c:	f8fb5ce3          	bge	s6,a5,800047e4 <filewrite+0x80>
    80004850:	84de                	mv	s1,s7
    80004852:	bf49                	j	800047e4 <filewrite+0x80>
      iunlock(f->ip);
    80004854:	01893503          	ld	a0,24(s2)
    80004858:	fffff097          	auipc	ra,0xfffff
    8000485c:	f44080e7          	jalr	-188(ra) # 8000379c <iunlock>
      end_op();
    80004860:	00000097          	auipc	ra,0x0
    80004864:	8b6080e7          	jalr	-1866(ra) # 80004116 <end_op>
      if(r < 0)
    80004868:	fc04d8e3          	bgez	s1,80004838 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    8000486c:	8552                	mv	a0,s4
    8000486e:	033a1863          	bne	s4,s3,8000489e <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004872:	60a6                	ld	ra,72(sp)
    80004874:	6406                	ld	s0,64(sp)
    80004876:	74e2                	ld	s1,56(sp)
    80004878:	7942                	ld	s2,48(sp)
    8000487a:	79a2                	ld	s3,40(sp)
    8000487c:	7a02                	ld	s4,32(sp)
    8000487e:	6ae2                	ld	s5,24(sp)
    80004880:	6b42                	ld	s6,16(sp)
    80004882:	6ba2                	ld	s7,8(sp)
    80004884:	6c02                	ld	s8,0(sp)
    80004886:	6161                	addi	sp,sp,80
    80004888:	8082                	ret
        panic("short filewrite");
    8000488a:	00004517          	auipc	a0,0x4
    8000488e:	f8650513          	addi	a0,a0,-122 # 80008810 <syscallnumber_to_name+0x270>
    80004892:	ffffc097          	auipc	ra,0xffffc
    80004896:	cb6080e7          	jalr	-842(ra) # 80000548 <panic>
    int i = 0;
    8000489a:	4981                	li	s3,0
    8000489c:	bfc1                	j	8000486c <filewrite+0x108>
    ret = (i == n ? n : -1);
    8000489e:	557d                	li	a0,-1
    800048a0:	bfc9                	j	80004872 <filewrite+0x10e>
    panic("filewrite");
    800048a2:	00004517          	auipc	a0,0x4
    800048a6:	f7e50513          	addi	a0,a0,-130 # 80008820 <syscallnumber_to_name+0x280>
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	c9e080e7          	jalr	-866(ra) # 80000548 <panic>
    return -1;
    800048b2:	557d                	li	a0,-1
}
    800048b4:	8082                	ret
      return -1;
    800048b6:	557d                	li	a0,-1
    800048b8:	bf6d                	j	80004872 <filewrite+0x10e>
    800048ba:	557d                	li	a0,-1
    800048bc:	bf5d                	j	80004872 <filewrite+0x10e>

00000000800048be <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048be:	7179                	addi	sp,sp,-48
    800048c0:	f406                	sd	ra,40(sp)
    800048c2:	f022                	sd	s0,32(sp)
    800048c4:	ec26                	sd	s1,24(sp)
    800048c6:	e84a                	sd	s2,16(sp)
    800048c8:	e44e                	sd	s3,8(sp)
    800048ca:	e052                	sd	s4,0(sp)
    800048cc:	1800                	addi	s0,sp,48
    800048ce:	84aa                	mv	s1,a0
    800048d0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048d2:	0005b023          	sd	zero,0(a1)
    800048d6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048da:	00000097          	auipc	ra,0x0
    800048de:	bd2080e7          	jalr	-1070(ra) # 800044ac <filealloc>
    800048e2:	e088                	sd	a0,0(s1)
    800048e4:	c551                	beqz	a0,80004970 <pipealloc+0xb2>
    800048e6:	00000097          	auipc	ra,0x0
    800048ea:	bc6080e7          	jalr	-1082(ra) # 800044ac <filealloc>
    800048ee:	00aa3023          	sd	a0,0(s4)
    800048f2:	c92d                	beqz	a0,80004964 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048f4:	ffffc097          	auipc	ra,0xffffc
    800048f8:	22c080e7          	jalr	556(ra) # 80000b20 <kalloc>
    800048fc:	892a                	mv	s2,a0
    800048fe:	c125                	beqz	a0,8000495e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004900:	4985                	li	s3,1
    80004902:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004906:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000490a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000490e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004912:	00004597          	auipc	a1,0x4
    80004916:	b2e58593          	addi	a1,a1,-1234 # 80008440 <states.1705+0x198>
    8000491a:	ffffc097          	auipc	ra,0xffffc
    8000491e:	266080e7          	jalr	614(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004922:	609c                	ld	a5,0(s1)
    80004924:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004928:	609c                	ld	a5,0(s1)
    8000492a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000492e:	609c                	ld	a5,0(s1)
    80004930:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004934:	609c                	ld	a5,0(s1)
    80004936:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000493a:	000a3783          	ld	a5,0(s4)
    8000493e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004942:	000a3783          	ld	a5,0(s4)
    80004946:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000494a:	000a3783          	ld	a5,0(s4)
    8000494e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004952:	000a3783          	ld	a5,0(s4)
    80004956:	0127b823          	sd	s2,16(a5)
  return 0;
    8000495a:	4501                	li	a0,0
    8000495c:	a025                	j	80004984 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000495e:	6088                	ld	a0,0(s1)
    80004960:	e501                	bnez	a0,80004968 <pipealloc+0xaa>
    80004962:	a039                	j	80004970 <pipealloc+0xb2>
    80004964:	6088                	ld	a0,0(s1)
    80004966:	c51d                	beqz	a0,80004994 <pipealloc+0xd6>
    fileclose(*f0);
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	c00080e7          	jalr	-1024(ra) # 80004568 <fileclose>
  if(*f1)
    80004970:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004974:	557d                	li	a0,-1
  if(*f1)
    80004976:	c799                	beqz	a5,80004984 <pipealloc+0xc6>
    fileclose(*f1);
    80004978:	853e                	mv	a0,a5
    8000497a:	00000097          	auipc	ra,0x0
    8000497e:	bee080e7          	jalr	-1042(ra) # 80004568 <fileclose>
  return -1;
    80004982:	557d                	li	a0,-1
}
    80004984:	70a2                	ld	ra,40(sp)
    80004986:	7402                	ld	s0,32(sp)
    80004988:	64e2                	ld	s1,24(sp)
    8000498a:	6942                	ld	s2,16(sp)
    8000498c:	69a2                	ld	s3,8(sp)
    8000498e:	6a02                	ld	s4,0(sp)
    80004990:	6145                	addi	sp,sp,48
    80004992:	8082                	ret
  return -1;
    80004994:	557d                	li	a0,-1
    80004996:	b7fd                	j	80004984 <pipealloc+0xc6>

0000000080004998 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004998:	1101                	addi	sp,sp,-32
    8000499a:	ec06                	sd	ra,24(sp)
    8000499c:	e822                	sd	s0,16(sp)
    8000499e:	e426                	sd	s1,8(sp)
    800049a0:	e04a                	sd	s2,0(sp)
    800049a2:	1000                	addi	s0,sp,32
    800049a4:	84aa                	mv	s1,a0
    800049a6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	268080e7          	jalr	616(ra) # 80000c10 <acquire>
  if(writable){
    800049b0:	02090d63          	beqz	s2,800049ea <pipeclose+0x52>
    pi->writeopen = 0;
    800049b4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049b8:	21848513          	addi	a0,s1,536
    800049bc:	ffffe097          	auipc	ra,0xffffe
    800049c0:	9c0080e7          	jalr	-1600(ra) # 8000237c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049c4:	2204b783          	ld	a5,544(s1)
    800049c8:	eb95                	bnez	a5,800049fc <pipeclose+0x64>
    release(&pi->lock);
    800049ca:	8526                	mv	a0,s1
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	2f8080e7          	jalr	760(ra) # 80000cc4 <release>
    kfree((char*)pi);
    800049d4:	8526                	mv	a0,s1
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	04e080e7          	jalr	78(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    800049de:	60e2                	ld	ra,24(sp)
    800049e0:	6442                	ld	s0,16(sp)
    800049e2:	64a2                	ld	s1,8(sp)
    800049e4:	6902                	ld	s2,0(sp)
    800049e6:	6105                	addi	sp,sp,32
    800049e8:	8082                	ret
    pi->readopen = 0;
    800049ea:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049ee:	21c48513          	addi	a0,s1,540
    800049f2:	ffffe097          	auipc	ra,0xffffe
    800049f6:	98a080e7          	jalr	-1654(ra) # 8000237c <wakeup>
    800049fa:	b7e9                	j	800049c4 <pipeclose+0x2c>
    release(&pi->lock);
    800049fc:	8526                	mv	a0,s1
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	2c6080e7          	jalr	710(ra) # 80000cc4 <release>
}
    80004a06:	bfe1                	j	800049de <pipeclose+0x46>

0000000080004a08 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a08:	7119                	addi	sp,sp,-128
    80004a0a:	fc86                	sd	ra,120(sp)
    80004a0c:	f8a2                	sd	s0,112(sp)
    80004a0e:	f4a6                	sd	s1,104(sp)
    80004a10:	f0ca                	sd	s2,96(sp)
    80004a12:	ecce                	sd	s3,88(sp)
    80004a14:	e8d2                	sd	s4,80(sp)
    80004a16:	e4d6                	sd	s5,72(sp)
    80004a18:	e0da                	sd	s6,64(sp)
    80004a1a:	fc5e                	sd	s7,56(sp)
    80004a1c:	f862                	sd	s8,48(sp)
    80004a1e:	f466                	sd	s9,40(sp)
    80004a20:	f06a                	sd	s10,32(sp)
    80004a22:	ec6e                	sd	s11,24(sp)
    80004a24:	0100                	addi	s0,sp,128
    80004a26:	84aa                	mv	s1,a0
    80004a28:	8cae                	mv	s9,a1
    80004a2a:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004a2c:	ffffd097          	auipc	ra,0xffffd
    80004a30:	fb2080e7          	jalr	-78(ra) # 800019de <myproc>
    80004a34:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004a36:	8526                	mv	a0,s1
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	1d8080e7          	jalr	472(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004a40:	0d605963          	blez	s6,80004b12 <pipewrite+0x10a>
    80004a44:	89a6                	mv	s3,s1
    80004a46:	3b7d                	addiw	s6,s6,-1
    80004a48:	1b02                	slli	s6,s6,0x20
    80004a4a:	020b5b13          	srli	s6,s6,0x20
    80004a4e:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004a50:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a54:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a58:	5dfd                	li	s11,-1
    80004a5a:	000b8d1b          	sext.w	s10,s7
    80004a5e:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a60:	2184a783          	lw	a5,536(s1)
    80004a64:	21c4a703          	lw	a4,540(s1)
    80004a68:	2007879b          	addiw	a5,a5,512
    80004a6c:	02f71b63          	bne	a4,a5,80004aa2 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004a70:	2204a783          	lw	a5,544(s1)
    80004a74:	cbad                	beqz	a5,80004ae6 <pipewrite+0xde>
    80004a76:	03092783          	lw	a5,48(s2)
    80004a7a:	e7b5                	bnez	a5,80004ae6 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004a7c:	8556                	mv	a0,s5
    80004a7e:	ffffe097          	auipc	ra,0xffffe
    80004a82:	8fe080e7          	jalr	-1794(ra) # 8000237c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a86:	85ce                	mv	a1,s3
    80004a88:	8552                	mv	a0,s4
    80004a8a:	ffffd097          	auipc	ra,0xffffd
    80004a8e:	76c080e7          	jalr	1900(ra) # 800021f6 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a92:	2184a783          	lw	a5,536(s1)
    80004a96:	21c4a703          	lw	a4,540(s1)
    80004a9a:	2007879b          	addiw	a5,a5,512
    80004a9e:	fcf709e3          	beq	a4,a5,80004a70 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aa2:	4685                	li	a3,1
    80004aa4:	019b8633          	add	a2,s7,s9
    80004aa8:	f8f40593          	addi	a1,s0,-113
    80004aac:	05093503          	ld	a0,80(s2)
    80004ab0:	ffffd097          	auipc	ra,0xffffd
    80004ab4:	cae080e7          	jalr	-850(ra) # 8000175e <copyin>
    80004ab8:	05b50e63          	beq	a0,s11,80004b14 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004abc:	21c4a783          	lw	a5,540(s1)
    80004ac0:	0017871b          	addiw	a4,a5,1
    80004ac4:	20e4ae23          	sw	a4,540(s1)
    80004ac8:	1ff7f793          	andi	a5,a5,511
    80004acc:	97a6                	add	a5,a5,s1
    80004ace:	f8f44703          	lbu	a4,-113(s0)
    80004ad2:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004ad6:	001d0c1b          	addiw	s8,s10,1
    80004ada:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004ade:	036b8b63          	beq	s7,s6,80004b14 <pipewrite+0x10c>
    80004ae2:	8bbe                	mv	s7,a5
    80004ae4:	bf9d                	j	80004a5a <pipewrite+0x52>
        release(&pi->lock);
    80004ae6:	8526                	mv	a0,s1
    80004ae8:	ffffc097          	auipc	ra,0xffffc
    80004aec:	1dc080e7          	jalr	476(ra) # 80000cc4 <release>
        return -1;
    80004af0:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004af2:	8562                	mv	a0,s8
    80004af4:	70e6                	ld	ra,120(sp)
    80004af6:	7446                	ld	s0,112(sp)
    80004af8:	74a6                	ld	s1,104(sp)
    80004afa:	7906                	ld	s2,96(sp)
    80004afc:	69e6                	ld	s3,88(sp)
    80004afe:	6a46                	ld	s4,80(sp)
    80004b00:	6aa6                	ld	s5,72(sp)
    80004b02:	6b06                	ld	s6,64(sp)
    80004b04:	7be2                	ld	s7,56(sp)
    80004b06:	7c42                	ld	s8,48(sp)
    80004b08:	7ca2                	ld	s9,40(sp)
    80004b0a:	7d02                	ld	s10,32(sp)
    80004b0c:	6de2                	ld	s11,24(sp)
    80004b0e:	6109                	addi	sp,sp,128
    80004b10:	8082                	ret
  for(i = 0; i < n; i++){
    80004b12:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004b14:	21848513          	addi	a0,s1,536
    80004b18:	ffffe097          	auipc	ra,0xffffe
    80004b1c:	864080e7          	jalr	-1948(ra) # 8000237c <wakeup>
  release(&pi->lock);
    80004b20:	8526                	mv	a0,s1
    80004b22:	ffffc097          	auipc	ra,0xffffc
    80004b26:	1a2080e7          	jalr	418(ra) # 80000cc4 <release>
  return i;
    80004b2a:	b7e1                	j	80004af2 <pipewrite+0xea>

0000000080004b2c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b2c:	715d                	addi	sp,sp,-80
    80004b2e:	e486                	sd	ra,72(sp)
    80004b30:	e0a2                	sd	s0,64(sp)
    80004b32:	fc26                	sd	s1,56(sp)
    80004b34:	f84a                	sd	s2,48(sp)
    80004b36:	f44e                	sd	s3,40(sp)
    80004b38:	f052                	sd	s4,32(sp)
    80004b3a:	ec56                	sd	s5,24(sp)
    80004b3c:	e85a                	sd	s6,16(sp)
    80004b3e:	0880                	addi	s0,sp,80
    80004b40:	84aa                	mv	s1,a0
    80004b42:	892e                	mv	s2,a1
    80004b44:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b46:	ffffd097          	auipc	ra,0xffffd
    80004b4a:	e98080e7          	jalr	-360(ra) # 800019de <myproc>
    80004b4e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b50:	8b26                	mv	s6,s1
    80004b52:	8526                	mv	a0,s1
    80004b54:	ffffc097          	auipc	ra,0xffffc
    80004b58:	0bc080e7          	jalr	188(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b5c:	2184a703          	lw	a4,536(s1)
    80004b60:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b64:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b68:	02f71463          	bne	a4,a5,80004b90 <piperead+0x64>
    80004b6c:	2244a783          	lw	a5,548(s1)
    80004b70:	c385                	beqz	a5,80004b90 <piperead+0x64>
    if(pr->killed){
    80004b72:	030a2783          	lw	a5,48(s4)
    80004b76:	ebc1                	bnez	a5,80004c06 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b78:	85da                	mv	a1,s6
    80004b7a:	854e                	mv	a0,s3
    80004b7c:	ffffd097          	auipc	ra,0xffffd
    80004b80:	67a080e7          	jalr	1658(ra) # 800021f6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b84:	2184a703          	lw	a4,536(s1)
    80004b88:	21c4a783          	lw	a5,540(s1)
    80004b8c:	fef700e3          	beq	a4,a5,80004b6c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b90:	09505263          	blez	s5,80004c14 <piperead+0xe8>
    80004b94:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b96:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004b98:	2184a783          	lw	a5,536(s1)
    80004b9c:	21c4a703          	lw	a4,540(s1)
    80004ba0:	02f70d63          	beq	a4,a5,80004bda <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ba4:	0017871b          	addiw	a4,a5,1
    80004ba8:	20e4ac23          	sw	a4,536(s1)
    80004bac:	1ff7f793          	andi	a5,a5,511
    80004bb0:	97a6                	add	a5,a5,s1
    80004bb2:	0187c783          	lbu	a5,24(a5)
    80004bb6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bba:	4685                	li	a3,1
    80004bbc:	fbf40613          	addi	a2,s0,-65
    80004bc0:	85ca                	mv	a1,s2
    80004bc2:	050a3503          	ld	a0,80(s4)
    80004bc6:	ffffd097          	auipc	ra,0xffffd
    80004bca:	b0c080e7          	jalr	-1268(ra) # 800016d2 <copyout>
    80004bce:	01650663          	beq	a0,s6,80004bda <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bd2:	2985                	addiw	s3,s3,1
    80004bd4:	0905                	addi	s2,s2,1
    80004bd6:	fd3a91e3          	bne	s5,s3,80004b98 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bda:	21c48513          	addi	a0,s1,540
    80004bde:	ffffd097          	auipc	ra,0xffffd
    80004be2:	79e080e7          	jalr	1950(ra) # 8000237c <wakeup>
  release(&pi->lock);
    80004be6:	8526                	mv	a0,s1
    80004be8:	ffffc097          	auipc	ra,0xffffc
    80004bec:	0dc080e7          	jalr	220(ra) # 80000cc4 <release>
  return i;
}
    80004bf0:	854e                	mv	a0,s3
    80004bf2:	60a6                	ld	ra,72(sp)
    80004bf4:	6406                	ld	s0,64(sp)
    80004bf6:	74e2                	ld	s1,56(sp)
    80004bf8:	7942                	ld	s2,48(sp)
    80004bfa:	79a2                	ld	s3,40(sp)
    80004bfc:	7a02                	ld	s4,32(sp)
    80004bfe:	6ae2                	ld	s5,24(sp)
    80004c00:	6b42                	ld	s6,16(sp)
    80004c02:	6161                	addi	sp,sp,80
    80004c04:	8082                	ret
      release(&pi->lock);
    80004c06:	8526                	mv	a0,s1
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	0bc080e7          	jalr	188(ra) # 80000cc4 <release>
      return -1;
    80004c10:	59fd                	li	s3,-1
    80004c12:	bff9                	j	80004bf0 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c14:	4981                	li	s3,0
    80004c16:	b7d1                	j	80004bda <piperead+0xae>

0000000080004c18 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c18:	df010113          	addi	sp,sp,-528
    80004c1c:	20113423          	sd	ra,520(sp)
    80004c20:	20813023          	sd	s0,512(sp)
    80004c24:	ffa6                	sd	s1,504(sp)
    80004c26:	fbca                	sd	s2,496(sp)
    80004c28:	f7ce                	sd	s3,488(sp)
    80004c2a:	f3d2                	sd	s4,480(sp)
    80004c2c:	efd6                	sd	s5,472(sp)
    80004c2e:	ebda                	sd	s6,464(sp)
    80004c30:	e7de                	sd	s7,456(sp)
    80004c32:	e3e2                	sd	s8,448(sp)
    80004c34:	ff66                	sd	s9,440(sp)
    80004c36:	fb6a                	sd	s10,432(sp)
    80004c38:	f76e                	sd	s11,424(sp)
    80004c3a:	0c00                	addi	s0,sp,528
    80004c3c:	84aa                	mv	s1,a0
    80004c3e:	dea43c23          	sd	a0,-520(s0)
    80004c42:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c46:	ffffd097          	auipc	ra,0xffffd
    80004c4a:	d98080e7          	jalr	-616(ra) # 800019de <myproc>
    80004c4e:	892a                	mv	s2,a0
  //printf("exec nei 1: %d\n", p->tracemask);

  begin_op();
    80004c50:	fffff097          	auipc	ra,0xfffff
    80004c54:	446080e7          	jalr	1094(ra) # 80004096 <begin_op>

  if((ip = namei(path)) == 0){
    80004c58:	8526                	mv	a0,s1
    80004c5a:	fffff097          	auipc	ra,0xfffff
    80004c5e:	230080e7          	jalr	560(ra) # 80003e8a <namei>
    80004c62:	c92d                	beqz	a0,80004cd4 <exec+0xbc>
    80004c64:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c66:	fffff097          	auipc	ra,0xfffff
    80004c6a:	a74080e7          	jalr	-1420(ra) # 800036da <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c6e:	04000713          	li	a4,64
    80004c72:	4681                	li	a3,0
    80004c74:	e4840613          	addi	a2,s0,-440
    80004c78:	4581                	li	a1,0
    80004c7a:	8526                	mv	a0,s1
    80004c7c:	fffff097          	auipc	ra,0xfffff
    80004c80:	d12080e7          	jalr	-750(ra) # 8000398e <readi>
    80004c84:	04000793          	li	a5,64
    80004c88:	00f51a63          	bne	a0,a5,80004c9c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c8c:	e4842703          	lw	a4,-440(s0)
    80004c90:	464c47b7          	lui	a5,0x464c4
    80004c94:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c98:	04f70463          	beq	a4,a5,80004ce0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c9c:	8526                	mv	a0,s1
    80004c9e:	fffff097          	auipc	ra,0xfffff
    80004ca2:	c9e080e7          	jalr	-866(ra) # 8000393c <iunlockput>
    end_op();
    80004ca6:	fffff097          	auipc	ra,0xfffff
    80004caa:	470080e7          	jalr	1136(ra) # 80004116 <end_op>
  }
  return -1;
    80004cae:	557d                	li	a0,-1
}
    80004cb0:	20813083          	ld	ra,520(sp)
    80004cb4:	20013403          	ld	s0,512(sp)
    80004cb8:	74fe                	ld	s1,504(sp)
    80004cba:	795e                	ld	s2,496(sp)
    80004cbc:	79be                	ld	s3,488(sp)
    80004cbe:	7a1e                	ld	s4,480(sp)
    80004cc0:	6afe                	ld	s5,472(sp)
    80004cc2:	6b5e                	ld	s6,464(sp)
    80004cc4:	6bbe                	ld	s7,456(sp)
    80004cc6:	6c1e                	ld	s8,448(sp)
    80004cc8:	7cfa                	ld	s9,440(sp)
    80004cca:	7d5a                	ld	s10,432(sp)
    80004ccc:	7dba                	ld	s11,424(sp)
    80004cce:	21010113          	addi	sp,sp,528
    80004cd2:	8082                	ret
    end_op();
    80004cd4:	fffff097          	auipc	ra,0xfffff
    80004cd8:	442080e7          	jalr	1090(ra) # 80004116 <end_op>
    return -1;
    80004cdc:	557d                	li	a0,-1
    80004cde:	bfc9                	j	80004cb0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ce0:	854a                	mv	a0,s2
    80004ce2:	ffffd097          	auipc	ra,0xffffd
    80004ce6:	dc0080e7          	jalr	-576(ra) # 80001aa2 <proc_pagetable>
    80004cea:	8baa                	mv	s7,a0
    80004cec:	d945                	beqz	a0,80004c9c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cee:	e6842983          	lw	s3,-408(s0)
    80004cf2:	e8045783          	lhu	a5,-384(s0)
    80004cf6:	c7ad                	beqz	a5,80004d60 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004cf8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cfa:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004cfc:	6c85                	lui	s9,0x1
    80004cfe:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d02:	def43823          	sd	a5,-528(s0)
    80004d06:	a42d                	j	80004f30 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d08:	00004517          	auipc	a0,0x4
    80004d0c:	b2850513          	addi	a0,a0,-1240 # 80008830 <syscallnumber_to_name+0x290>
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	838080e7          	jalr	-1992(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d18:	8756                	mv	a4,s5
    80004d1a:	012d86bb          	addw	a3,s11,s2
    80004d1e:	4581                	li	a1,0
    80004d20:	8526                	mv	a0,s1
    80004d22:	fffff097          	auipc	ra,0xfffff
    80004d26:	c6c080e7          	jalr	-916(ra) # 8000398e <readi>
    80004d2a:	2501                	sext.w	a0,a0
    80004d2c:	1aaa9963          	bne	s5,a0,80004ede <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d30:	6785                	lui	a5,0x1
    80004d32:	0127893b          	addw	s2,a5,s2
    80004d36:	77fd                	lui	a5,0xfffff
    80004d38:	01478a3b          	addw	s4,a5,s4
    80004d3c:	1f897163          	bgeu	s2,s8,80004f1e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004d40:	02091593          	slli	a1,s2,0x20
    80004d44:	9181                	srli	a1,a1,0x20
    80004d46:	95ea                	add	a1,a1,s10
    80004d48:	855e                	mv	a0,s7
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	354080e7          	jalr	852(ra) # 8000109e <walkaddr>
    80004d52:	862a                	mv	a2,a0
    if(pa == 0)
    80004d54:	d955                	beqz	a0,80004d08 <exec+0xf0>
      n = PGSIZE;
    80004d56:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d58:	fd9a70e3          	bgeu	s4,s9,80004d18 <exec+0x100>
      n = sz - i;
    80004d5c:	8ad2                	mv	s5,s4
    80004d5e:	bf6d                	j	80004d18 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d60:	4901                	li	s2,0
  iunlockput(ip);
    80004d62:	8526                	mv	a0,s1
    80004d64:	fffff097          	auipc	ra,0xfffff
    80004d68:	bd8080e7          	jalr	-1064(ra) # 8000393c <iunlockput>
  end_op();
    80004d6c:	fffff097          	auipc	ra,0xfffff
    80004d70:	3aa080e7          	jalr	938(ra) # 80004116 <end_op>
  p = myproc();
    80004d74:	ffffd097          	auipc	ra,0xffffd
    80004d78:	c6a080e7          	jalr	-918(ra) # 800019de <myproc>
    80004d7c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d7e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d82:	6785                	lui	a5,0x1
    80004d84:	17fd                	addi	a5,a5,-1
    80004d86:	993e                	add	s2,s2,a5
    80004d88:	757d                	lui	a0,0xfffff
    80004d8a:	00a977b3          	and	a5,s2,a0
    80004d8e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d92:	6609                	lui	a2,0x2
    80004d94:	963e                	add	a2,a2,a5
    80004d96:	85be                	mv	a1,a5
    80004d98:	855e                	mv	a0,s7
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	6e8080e7          	jalr	1768(ra) # 80001482 <uvmalloc>
    80004da2:	8b2a                	mv	s6,a0
  ip = 0;
    80004da4:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004da6:	12050c63          	beqz	a0,80004ede <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004daa:	75f9                	lui	a1,0xffffe
    80004dac:	95aa                	add	a1,a1,a0
    80004dae:	855e                	mv	a0,s7
    80004db0:	ffffd097          	auipc	ra,0xffffd
    80004db4:	8f0080e7          	jalr	-1808(ra) # 800016a0 <uvmclear>
  stackbase = sp - PGSIZE;
    80004db8:	7c7d                	lui	s8,0xfffff
    80004dba:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004dbc:	e0043783          	ld	a5,-512(s0)
    80004dc0:	6388                	ld	a0,0(a5)
    80004dc2:	c535                	beqz	a0,80004e2e <exec+0x216>
    80004dc4:	e8840993          	addi	s3,s0,-376
    80004dc8:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004dcc:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004dce:	ffffc097          	auipc	ra,0xffffc
    80004dd2:	0c6080e7          	jalr	198(ra) # 80000e94 <strlen>
    80004dd6:	2505                	addiw	a0,a0,1
    80004dd8:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ddc:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004de0:	13896363          	bltu	s2,s8,80004f06 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004de4:	e0043d83          	ld	s11,-512(s0)
    80004de8:	000dba03          	ld	s4,0(s11)
    80004dec:	8552                	mv	a0,s4
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	0a6080e7          	jalr	166(ra) # 80000e94 <strlen>
    80004df6:	0015069b          	addiw	a3,a0,1
    80004dfa:	8652                	mv	a2,s4
    80004dfc:	85ca                	mv	a1,s2
    80004dfe:	855e                	mv	a0,s7
    80004e00:	ffffd097          	auipc	ra,0xffffd
    80004e04:	8d2080e7          	jalr	-1838(ra) # 800016d2 <copyout>
    80004e08:	10054363          	bltz	a0,80004f0e <exec+0x2f6>
    ustack[argc] = sp;
    80004e0c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e10:	0485                	addi	s1,s1,1
    80004e12:	008d8793          	addi	a5,s11,8
    80004e16:	e0f43023          	sd	a5,-512(s0)
    80004e1a:	008db503          	ld	a0,8(s11)
    80004e1e:	c911                	beqz	a0,80004e32 <exec+0x21a>
    if(argc >= MAXARG)
    80004e20:	09a1                	addi	s3,s3,8
    80004e22:	fb3c96e3          	bne	s9,s3,80004dce <exec+0x1b6>
  sz = sz1;
    80004e26:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e2a:	4481                	li	s1,0
    80004e2c:	a84d                	j	80004ede <exec+0x2c6>
  sp = sz;
    80004e2e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e30:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e32:	00349793          	slli	a5,s1,0x3
    80004e36:	f9040713          	addi	a4,s0,-112
    80004e3a:	97ba                	add	a5,a5,a4
    80004e3c:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004e40:	00148693          	addi	a3,s1,1
    80004e44:	068e                	slli	a3,a3,0x3
    80004e46:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e4a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e4e:	01897663          	bgeu	s2,s8,80004e5a <exec+0x242>
  sz = sz1;
    80004e52:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e56:	4481                	li	s1,0
    80004e58:	a059                	j	80004ede <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e5a:	e8840613          	addi	a2,s0,-376
    80004e5e:	85ca                	mv	a1,s2
    80004e60:	855e                	mv	a0,s7
    80004e62:	ffffd097          	auipc	ra,0xffffd
    80004e66:	870080e7          	jalr	-1936(ra) # 800016d2 <copyout>
    80004e6a:	0a054663          	bltz	a0,80004f16 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004e6e:	058ab783          	ld	a5,88(s5)
    80004e72:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e76:	df843783          	ld	a5,-520(s0)
    80004e7a:	0007c703          	lbu	a4,0(a5)
    80004e7e:	cf11                	beqz	a4,80004e9a <exec+0x282>
    80004e80:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e82:	02f00693          	li	a3,47
    80004e86:	a029                	j	80004e90 <exec+0x278>
  for(last=s=path; *s; s++)
    80004e88:	0785                	addi	a5,a5,1
    80004e8a:	fff7c703          	lbu	a4,-1(a5)
    80004e8e:	c711                	beqz	a4,80004e9a <exec+0x282>
    if(*s == '/')
    80004e90:	fed71ce3          	bne	a4,a3,80004e88 <exec+0x270>
      last = s+1;
    80004e94:	def43c23          	sd	a5,-520(s0)
    80004e98:	bfc5                	j	80004e88 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e9a:	4641                	li	a2,16
    80004e9c:	df843583          	ld	a1,-520(s0)
    80004ea0:	158a8513          	addi	a0,s5,344
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	fbe080e7          	jalr	-66(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    80004eac:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004eb0:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004eb4:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004eb8:	058ab783          	ld	a5,88(s5)
    80004ebc:	e6043703          	ld	a4,-416(s0)
    80004ec0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ec2:	058ab783          	ld	a5,88(s5)
    80004ec6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004eca:	85ea                	mv	a1,s10
    80004ecc:	ffffd097          	auipc	ra,0xffffd
    80004ed0:	c72080e7          	jalr	-910(ra) # 80001b3e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ed4:	0004851b          	sext.w	a0,s1
    80004ed8:	bbe1                	j	80004cb0 <exec+0x98>
    80004eda:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004ede:	e0843583          	ld	a1,-504(s0)
    80004ee2:	855e                	mv	a0,s7
    80004ee4:	ffffd097          	auipc	ra,0xffffd
    80004ee8:	c5a080e7          	jalr	-934(ra) # 80001b3e <proc_freepagetable>
  if(ip){
    80004eec:	da0498e3          	bnez	s1,80004c9c <exec+0x84>
  return -1;
    80004ef0:	557d                	li	a0,-1
    80004ef2:	bb7d                	j	80004cb0 <exec+0x98>
    80004ef4:	e1243423          	sd	s2,-504(s0)
    80004ef8:	b7dd                	j	80004ede <exec+0x2c6>
    80004efa:	e1243423          	sd	s2,-504(s0)
    80004efe:	b7c5                	j	80004ede <exec+0x2c6>
    80004f00:	e1243423          	sd	s2,-504(s0)
    80004f04:	bfe9                	j	80004ede <exec+0x2c6>
  sz = sz1;
    80004f06:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f0a:	4481                	li	s1,0
    80004f0c:	bfc9                	j	80004ede <exec+0x2c6>
  sz = sz1;
    80004f0e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f12:	4481                	li	s1,0
    80004f14:	b7e9                	j	80004ede <exec+0x2c6>
  sz = sz1;
    80004f16:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f1a:	4481                	li	s1,0
    80004f1c:	b7c9                	j	80004ede <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f1e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f22:	2b05                	addiw	s6,s6,1
    80004f24:	0389899b          	addiw	s3,s3,56
    80004f28:	e8045783          	lhu	a5,-384(s0)
    80004f2c:	e2fb5be3          	bge	s6,a5,80004d62 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f30:	2981                	sext.w	s3,s3
    80004f32:	03800713          	li	a4,56
    80004f36:	86ce                	mv	a3,s3
    80004f38:	e1040613          	addi	a2,s0,-496
    80004f3c:	4581                	li	a1,0
    80004f3e:	8526                	mv	a0,s1
    80004f40:	fffff097          	auipc	ra,0xfffff
    80004f44:	a4e080e7          	jalr	-1458(ra) # 8000398e <readi>
    80004f48:	03800793          	li	a5,56
    80004f4c:	f8f517e3          	bne	a0,a5,80004eda <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004f50:	e1042783          	lw	a5,-496(s0)
    80004f54:	4705                	li	a4,1
    80004f56:	fce796e3          	bne	a5,a4,80004f22 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004f5a:	e3843603          	ld	a2,-456(s0)
    80004f5e:	e3043783          	ld	a5,-464(s0)
    80004f62:	f8f669e3          	bltu	a2,a5,80004ef4 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f66:	e2043783          	ld	a5,-480(s0)
    80004f6a:	963e                	add	a2,a2,a5
    80004f6c:	f8f667e3          	bltu	a2,a5,80004efa <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f70:	85ca                	mv	a1,s2
    80004f72:	855e                	mv	a0,s7
    80004f74:	ffffc097          	auipc	ra,0xffffc
    80004f78:	50e080e7          	jalr	1294(ra) # 80001482 <uvmalloc>
    80004f7c:	e0a43423          	sd	a0,-504(s0)
    80004f80:	d141                	beqz	a0,80004f00 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004f82:	e2043d03          	ld	s10,-480(s0)
    80004f86:	df043783          	ld	a5,-528(s0)
    80004f8a:	00fd77b3          	and	a5,s10,a5
    80004f8e:	fba1                	bnez	a5,80004ede <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f90:	e1842d83          	lw	s11,-488(s0)
    80004f94:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f98:	f80c03e3          	beqz	s8,80004f1e <exec+0x306>
    80004f9c:	8a62                	mv	s4,s8
    80004f9e:	4901                	li	s2,0
    80004fa0:	b345                	j	80004d40 <exec+0x128>

0000000080004fa2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fa2:	7179                	addi	sp,sp,-48
    80004fa4:	f406                	sd	ra,40(sp)
    80004fa6:	f022                	sd	s0,32(sp)
    80004fa8:	ec26                	sd	s1,24(sp)
    80004faa:	e84a                	sd	s2,16(sp)
    80004fac:	1800                	addi	s0,sp,48
    80004fae:	892e                	mv	s2,a1
    80004fb0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fb2:	fdc40593          	addi	a1,s0,-36
    80004fb6:	ffffe097          	auipc	ra,0xffffe
    80004fba:	b2a080e7          	jalr	-1238(ra) # 80002ae0 <argint>
    80004fbe:	04054063          	bltz	a0,80004ffe <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fc2:	fdc42703          	lw	a4,-36(s0)
    80004fc6:	47bd                	li	a5,15
    80004fc8:	02e7ed63          	bltu	a5,a4,80005002 <argfd+0x60>
    80004fcc:	ffffd097          	auipc	ra,0xffffd
    80004fd0:	a12080e7          	jalr	-1518(ra) # 800019de <myproc>
    80004fd4:	fdc42703          	lw	a4,-36(s0)
    80004fd8:	01a70793          	addi	a5,a4,26
    80004fdc:	078e                	slli	a5,a5,0x3
    80004fde:	953e                	add	a0,a0,a5
    80004fe0:	611c                	ld	a5,0(a0)
    80004fe2:	c395                	beqz	a5,80005006 <argfd+0x64>
    return -1;
  if(pfd)
    80004fe4:	00090463          	beqz	s2,80004fec <argfd+0x4a>
    *pfd = fd;
    80004fe8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fec:	4501                	li	a0,0
  if(pf)
    80004fee:	c091                	beqz	s1,80004ff2 <argfd+0x50>
    *pf = f;
    80004ff0:	e09c                	sd	a5,0(s1)
}
    80004ff2:	70a2                	ld	ra,40(sp)
    80004ff4:	7402                	ld	s0,32(sp)
    80004ff6:	64e2                	ld	s1,24(sp)
    80004ff8:	6942                	ld	s2,16(sp)
    80004ffa:	6145                	addi	sp,sp,48
    80004ffc:	8082                	ret
    return -1;
    80004ffe:	557d                	li	a0,-1
    80005000:	bfcd                	j	80004ff2 <argfd+0x50>
    return -1;
    80005002:	557d                	li	a0,-1
    80005004:	b7fd                	j	80004ff2 <argfd+0x50>
    80005006:	557d                	li	a0,-1
    80005008:	b7ed                	j	80004ff2 <argfd+0x50>

000000008000500a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000500a:	1101                	addi	sp,sp,-32
    8000500c:	ec06                	sd	ra,24(sp)
    8000500e:	e822                	sd	s0,16(sp)
    80005010:	e426                	sd	s1,8(sp)
    80005012:	1000                	addi	s0,sp,32
    80005014:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005016:	ffffd097          	auipc	ra,0xffffd
    8000501a:	9c8080e7          	jalr	-1592(ra) # 800019de <myproc>
    8000501e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005020:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005024:	4501                	li	a0,0
    80005026:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005028:	6398                	ld	a4,0(a5)
    8000502a:	cb19                	beqz	a4,80005040 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000502c:	2505                	addiw	a0,a0,1
    8000502e:	07a1                	addi	a5,a5,8
    80005030:	fed51ce3          	bne	a0,a3,80005028 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005034:	557d                	li	a0,-1
}
    80005036:	60e2                	ld	ra,24(sp)
    80005038:	6442                	ld	s0,16(sp)
    8000503a:	64a2                	ld	s1,8(sp)
    8000503c:	6105                	addi	sp,sp,32
    8000503e:	8082                	ret
      p->ofile[fd] = f;
    80005040:	01a50793          	addi	a5,a0,26
    80005044:	078e                	slli	a5,a5,0x3
    80005046:	963e                	add	a2,a2,a5
    80005048:	e204                	sd	s1,0(a2)
      return fd;
    8000504a:	b7f5                	j	80005036 <fdalloc+0x2c>

000000008000504c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000504c:	715d                	addi	sp,sp,-80
    8000504e:	e486                	sd	ra,72(sp)
    80005050:	e0a2                	sd	s0,64(sp)
    80005052:	fc26                	sd	s1,56(sp)
    80005054:	f84a                	sd	s2,48(sp)
    80005056:	f44e                	sd	s3,40(sp)
    80005058:	f052                	sd	s4,32(sp)
    8000505a:	ec56                	sd	s5,24(sp)
    8000505c:	0880                	addi	s0,sp,80
    8000505e:	89ae                	mv	s3,a1
    80005060:	8ab2                	mv	s5,a2
    80005062:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005064:	fb040593          	addi	a1,s0,-80
    80005068:	fffff097          	auipc	ra,0xfffff
    8000506c:	e40080e7          	jalr	-448(ra) # 80003ea8 <nameiparent>
    80005070:	892a                	mv	s2,a0
    80005072:	12050f63          	beqz	a0,800051b0 <create+0x164>
    return 0;

  ilock(dp);
    80005076:	ffffe097          	auipc	ra,0xffffe
    8000507a:	664080e7          	jalr	1636(ra) # 800036da <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000507e:	4601                	li	a2,0
    80005080:	fb040593          	addi	a1,s0,-80
    80005084:	854a                	mv	a0,s2
    80005086:	fffff097          	auipc	ra,0xfffff
    8000508a:	b32080e7          	jalr	-1230(ra) # 80003bb8 <dirlookup>
    8000508e:	84aa                	mv	s1,a0
    80005090:	c921                	beqz	a0,800050e0 <create+0x94>
    iunlockput(dp);
    80005092:	854a                	mv	a0,s2
    80005094:	fffff097          	auipc	ra,0xfffff
    80005098:	8a8080e7          	jalr	-1880(ra) # 8000393c <iunlockput>
    ilock(ip);
    8000509c:	8526                	mv	a0,s1
    8000509e:	ffffe097          	auipc	ra,0xffffe
    800050a2:	63c080e7          	jalr	1596(ra) # 800036da <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050a6:	2981                	sext.w	s3,s3
    800050a8:	4789                	li	a5,2
    800050aa:	02f99463          	bne	s3,a5,800050d2 <create+0x86>
    800050ae:	0444d783          	lhu	a5,68(s1)
    800050b2:	37f9                	addiw	a5,a5,-2
    800050b4:	17c2                	slli	a5,a5,0x30
    800050b6:	93c1                	srli	a5,a5,0x30
    800050b8:	4705                	li	a4,1
    800050ba:	00f76c63          	bltu	a4,a5,800050d2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050be:	8526                	mv	a0,s1
    800050c0:	60a6                	ld	ra,72(sp)
    800050c2:	6406                	ld	s0,64(sp)
    800050c4:	74e2                	ld	s1,56(sp)
    800050c6:	7942                	ld	s2,48(sp)
    800050c8:	79a2                	ld	s3,40(sp)
    800050ca:	7a02                	ld	s4,32(sp)
    800050cc:	6ae2                	ld	s5,24(sp)
    800050ce:	6161                	addi	sp,sp,80
    800050d0:	8082                	ret
    iunlockput(ip);
    800050d2:	8526                	mv	a0,s1
    800050d4:	fffff097          	auipc	ra,0xfffff
    800050d8:	868080e7          	jalr	-1944(ra) # 8000393c <iunlockput>
    return 0;
    800050dc:	4481                	li	s1,0
    800050de:	b7c5                	j	800050be <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050e0:	85ce                	mv	a1,s3
    800050e2:	00092503          	lw	a0,0(s2)
    800050e6:	ffffe097          	auipc	ra,0xffffe
    800050ea:	45c080e7          	jalr	1116(ra) # 80003542 <ialloc>
    800050ee:	84aa                	mv	s1,a0
    800050f0:	c529                	beqz	a0,8000513a <create+0xee>
  ilock(ip);
    800050f2:	ffffe097          	auipc	ra,0xffffe
    800050f6:	5e8080e7          	jalr	1512(ra) # 800036da <ilock>
  ip->major = major;
    800050fa:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050fe:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005102:	4785                	li	a5,1
    80005104:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005108:	8526                	mv	a0,s1
    8000510a:	ffffe097          	auipc	ra,0xffffe
    8000510e:	506080e7          	jalr	1286(ra) # 80003610 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005112:	2981                	sext.w	s3,s3
    80005114:	4785                	li	a5,1
    80005116:	02f98a63          	beq	s3,a5,8000514a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000511a:	40d0                	lw	a2,4(s1)
    8000511c:	fb040593          	addi	a1,s0,-80
    80005120:	854a                	mv	a0,s2
    80005122:	fffff097          	auipc	ra,0xfffff
    80005126:	ca6080e7          	jalr	-858(ra) # 80003dc8 <dirlink>
    8000512a:	06054b63          	bltz	a0,800051a0 <create+0x154>
  iunlockput(dp);
    8000512e:	854a                	mv	a0,s2
    80005130:	fffff097          	auipc	ra,0xfffff
    80005134:	80c080e7          	jalr	-2036(ra) # 8000393c <iunlockput>
  return ip;
    80005138:	b759                	j	800050be <create+0x72>
    panic("create: ialloc");
    8000513a:	00003517          	auipc	a0,0x3
    8000513e:	71650513          	addi	a0,a0,1814 # 80008850 <syscallnumber_to_name+0x2b0>
    80005142:	ffffb097          	auipc	ra,0xffffb
    80005146:	406080e7          	jalr	1030(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    8000514a:	04a95783          	lhu	a5,74(s2)
    8000514e:	2785                	addiw	a5,a5,1
    80005150:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005154:	854a                	mv	a0,s2
    80005156:	ffffe097          	auipc	ra,0xffffe
    8000515a:	4ba080e7          	jalr	1210(ra) # 80003610 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000515e:	40d0                	lw	a2,4(s1)
    80005160:	00003597          	auipc	a1,0x3
    80005164:	70058593          	addi	a1,a1,1792 # 80008860 <syscallnumber_to_name+0x2c0>
    80005168:	8526                	mv	a0,s1
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	c5e080e7          	jalr	-930(ra) # 80003dc8 <dirlink>
    80005172:	00054f63          	bltz	a0,80005190 <create+0x144>
    80005176:	00492603          	lw	a2,4(s2)
    8000517a:	00003597          	auipc	a1,0x3
    8000517e:	6ee58593          	addi	a1,a1,1774 # 80008868 <syscallnumber_to_name+0x2c8>
    80005182:	8526                	mv	a0,s1
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	c44080e7          	jalr	-956(ra) # 80003dc8 <dirlink>
    8000518c:	f80557e3          	bgez	a0,8000511a <create+0xce>
      panic("create dots");
    80005190:	00003517          	auipc	a0,0x3
    80005194:	6e050513          	addi	a0,a0,1760 # 80008870 <syscallnumber_to_name+0x2d0>
    80005198:	ffffb097          	auipc	ra,0xffffb
    8000519c:	3b0080e7          	jalr	944(ra) # 80000548 <panic>
    panic("create: dirlink");
    800051a0:	00003517          	auipc	a0,0x3
    800051a4:	6e050513          	addi	a0,a0,1760 # 80008880 <syscallnumber_to_name+0x2e0>
    800051a8:	ffffb097          	auipc	ra,0xffffb
    800051ac:	3a0080e7          	jalr	928(ra) # 80000548 <panic>
    return 0;
    800051b0:	84aa                	mv	s1,a0
    800051b2:	b731                	j	800050be <create+0x72>

00000000800051b4 <sys_dup>:
{
    800051b4:	7179                	addi	sp,sp,-48
    800051b6:	f406                	sd	ra,40(sp)
    800051b8:	f022                	sd	s0,32(sp)
    800051ba:	ec26                	sd	s1,24(sp)
    800051bc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051be:	fd840613          	addi	a2,s0,-40
    800051c2:	4581                	li	a1,0
    800051c4:	4501                	li	a0,0
    800051c6:	00000097          	auipc	ra,0x0
    800051ca:	ddc080e7          	jalr	-548(ra) # 80004fa2 <argfd>
    return -1;
    800051ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051d0:	02054363          	bltz	a0,800051f6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051d4:	fd843503          	ld	a0,-40(s0)
    800051d8:	00000097          	auipc	ra,0x0
    800051dc:	e32080e7          	jalr	-462(ra) # 8000500a <fdalloc>
    800051e0:	84aa                	mv	s1,a0
    return -1;
    800051e2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051e4:	00054963          	bltz	a0,800051f6 <sys_dup+0x42>
  filedup(f);
    800051e8:	fd843503          	ld	a0,-40(s0)
    800051ec:	fffff097          	auipc	ra,0xfffff
    800051f0:	32a080e7          	jalr	810(ra) # 80004516 <filedup>
  return fd;
    800051f4:	87a6                	mv	a5,s1
}
    800051f6:	853e                	mv	a0,a5
    800051f8:	70a2                	ld	ra,40(sp)
    800051fa:	7402                	ld	s0,32(sp)
    800051fc:	64e2                	ld	s1,24(sp)
    800051fe:	6145                	addi	sp,sp,48
    80005200:	8082                	ret

0000000080005202 <sys_read>:
{
    80005202:	7179                	addi	sp,sp,-48
    80005204:	f406                	sd	ra,40(sp)
    80005206:	f022                	sd	s0,32(sp)
    80005208:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000520a:	fe840613          	addi	a2,s0,-24
    8000520e:	4581                	li	a1,0
    80005210:	4501                	li	a0,0
    80005212:	00000097          	auipc	ra,0x0
    80005216:	d90080e7          	jalr	-624(ra) # 80004fa2 <argfd>
    return -1;
    8000521a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000521c:	04054163          	bltz	a0,8000525e <sys_read+0x5c>
    80005220:	fe440593          	addi	a1,s0,-28
    80005224:	4509                	li	a0,2
    80005226:	ffffe097          	auipc	ra,0xffffe
    8000522a:	8ba080e7          	jalr	-1862(ra) # 80002ae0 <argint>
    return -1;
    8000522e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005230:	02054763          	bltz	a0,8000525e <sys_read+0x5c>
    80005234:	fd840593          	addi	a1,s0,-40
    80005238:	4505                	li	a0,1
    8000523a:	ffffe097          	auipc	ra,0xffffe
    8000523e:	8c8080e7          	jalr	-1848(ra) # 80002b02 <argaddr>
    return -1;
    80005242:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005244:	00054d63          	bltz	a0,8000525e <sys_read+0x5c>
  return fileread(f, p, n);
    80005248:	fe442603          	lw	a2,-28(s0)
    8000524c:	fd843583          	ld	a1,-40(s0)
    80005250:	fe843503          	ld	a0,-24(s0)
    80005254:	fffff097          	auipc	ra,0xfffff
    80005258:	44e080e7          	jalr	1102(ra) # 800046a2 <fileread>
    8000525c:	87aa                	mv	a5,a0
}
    8000525e:	853e                	mv	a0,a5
    80005260:	70a2                	ld	ra,40(sp)
    80005262:	7402                	ld	s0,32(sp)
    80005264:	6145                	addi	sp,sp,48
    80005266:	8082                	ret

0000000080005268 <sys_write>:
{
    80005268:	7179                	addi	sp,sp,-48
    8000526a:	f406                	sd	ra,40(sp)
    8000526c:	f022                	sd	s0,32(sp)
    8000526e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005270:	fe840613          	addi	a2,s0,-24
    80005274:	4581                	li	a1,0
    80005276:	4501                	li	a0,0
    80005278:	00000097          	auipc	ra,0x0
    8000527c:	d2a080e7          	jalr	-726(ra) # 80004fa2 <argfd>
    return -1;
    80005280:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005282:	04054163          	bltz	a0,800052c4 <sys_write+0x5c>
    80005286:	fe440593          	addi	a1,s0,-28
    8000528a:	4509                	li	a0,2
    8000528c:	ffffe097          	auipc	ra,0xffffe
    80005290:	854080e7          	jalr	-1964(ra) # 80002ae0 <argint>
    return -1;
    80005294:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005296:	02054763          	bltz	a0,800052c4 <sys_write+0x5c>
    8000529a:	fd840593          	addi	a1,s0,-40
    8000529e:	4505                	li	a0,1
    800052a0:	ffffe097          	auipc	ra,0xffffe
    800052a4:	862080e7          	jalr	-1950(ra) # 80002b02 <argaddr>
    return -1;
    800052a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052aa:	00054d63          	bltz	a0,800052c4 <sys_write+0x5c>
  return filewrite(f, p, n);
    800052ae:	fe442603          	lw	a2,-28(s0)
    800052b2:	fd843583          	ld	a1,-40(s0)
    800052b6:	fe843503          	ld	a0,-24(s0)
    800052ba:	fffff097          	auipc	ra,0xfffff
    800052be:	4aa080e7          	jalr	1194(ra) # 80004764 <filewrite>
    800052c2:	87aa                	mv	a5,a0
}
    800052c4:	853e                	mv	a0,a5
    800052c6:	70a2                	ld	ra,40(sp)
    800052c8:	7402                	ld	s0,32(sp)
    800052ca:	6145                	addi	sp,sp,48
    800052cc:	8082                	ret

00000000800052ce <sys_close>:
{
    800052ce:	1101                	addi	sp,sp,-32
    800052d0:	ec06                	sd	ra,24(sp)
    800052d2:	e822                	sd	s0,16(sp)
    800052d4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052d6:	fe040613          	addi	a2,s0,-32
    800052da:	fec40593          	addi	a1,s0,-20
    800052de:	4501                	li	a0,0
    800052e0:	00000097          	auipc	ra,0x0
    800052e4:	cc2080e7          	jalr	-830(ra) # 80004fa2 <argfd>
    return -1;
    800052e8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052ea:	02054463          	bltz	a0,80005312 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052ee:	ffffc097          	auipc	ra,0xffffc
    800052f2:	6f0080e7          	jalr	1776(ra) # 800019de <myproc>
    800052f6:	fec42783          	lw	a5,-20(s0)
    800052fa:	07e9                	addi	a5,a5,26
    800052fc:	078e                	slli	a5,a5,0x3
    800052fe:	97aa                	add	a5,a5,a0
    80005300:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005304:	fe043503          	ld	a0,-32(s0)
    80005308:	fffff097          	auipc	ra,0xfffff
    8000530c:	260080e7          	jalr	608(ra) # 80004568 <fileclose>
  return 0;
    80005310:	4781                	li	a5,0
}
    80005312:	853e                	mv	a0,a5
    80005314:	60e2                	ld	ra,24(sp)
    80005316:	6442                	ld	s0,16(sp)
    80005318:	6105                	addi	sp,sp,32
    8000531a:	8082                	ret

000000008000531c <sys_fstat>:
{
    8000531c:	1101                	addi	sp,sp,-32
    8000531e:	ec06                	sd	ra,24(sp)
    80005320:	e822                	sd	s0,16(sp)
    80005322:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005324:	fe840613          	addi	a2,s0,-24
    80005328:	4581                	li	a1,0
    8000532a:	4501                	li	a0,0
    8000532c:	00000097          	auipc	ra,0x0
    80005330:	c76080e7          	jalr	-906(ra) # 80004fa2 <argfd>
    return -1;
    80005334:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005336:	02054563          	bltz	a0,80005360 <sys_fstat+0x44>
    8000533a:	fe040593          	addi	a1,s0,-32
    8000533e:	4505                	li	a0,1
    80005340:	ffffd097          	auipc	ra,0xffffd
    80005344:	7c2080e7          	jalr	1986(ra) # 80002b02 <argaddr>
    return -1;
    80005348:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000534a:	00054b63          	bltz	a0,80005360 <sys_fstat+0x44>
  return filestat(f, st);
    8000534e:	fe043583          	ld	a1,-32(s0)
    80005352:	fe843503          	ld	a0,-24(s0)
    80005356:	fffff097          	auipc	ra,0xfffff
    8000535a:	2da080e7          	jalr	730(ra) # 80004630 <filestat>
    8000535e:	87aa                	mv	a5,a0
}
    80005360:	853e                	mv	a0,a5
    80005362:	60e2                	ld	ra,24(sp)
    80005364:	6442                	ld	s0,16(sp)
    80005366:	6105                	addi	sp,sp,32
    80005368:	8082                	ret

000000008000536a <sys_link>:
{
    8000536a:	7169                	addi	sp,sp,-304
    8000536c:	f606                	sd	ra,296(sp)
    8000536e:	f222                	sd	s0,288(sp)
    80005370:	ee26                	sd	s1,280(sp)
    80005372:	ea4a                	sd	s2,272(sp)
    80005374:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005376:	08000613          	li	a2,128
    8000537a:	ed040593          	addi	a1,s0,-304
    8000537e:	4501                	li	a0,0
    80005380:	ffffd097          	auipc	ra,0xffffd
    80005384:	7a4080e7          	jalr	1956(ra) # 80002b24 <argstr>
    return -1;
    80005388:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000538a:	10054e63          	bltz	a0,800054a6 <sys_link+0x13c>
    8000538e:	08000613          	li	a2,128
    80005392:	f5040593          	addi	a1,s0,-176
    80005396:	4505                	li	a0,1
    80005398:	ffffd097          	auipc	ra,0xffffd
    8000539c:	78c080e7          	jalr	1932(ra) # 80002b24 <argstr>
    return -1;
    800053a0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053a2:	10054263          	bltz	a0,800054a6 <sys_link+0x13c>
  begin_op();
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	cf0080e7          	jalr	-784(ra) # 80004096 <begin_op>
  if((ip = namei(old)) == 0){
    800053ae:	ed040513          	addi	a0,s0,-304
    800053b2:	fffff097          	auipc	ra,0xfffff
    800053b6:	ad8080e7          	jalr	-1320(ra) # 80003e8a <namei>
    800053ba:	84aa                	mv	s1,a0
    800053bc:	c551                	beqz	a0,80005448 <sys_link+0xde>
  ilock(ip);
    800053be:	ffffe097          	auipc	ra,0xffffe
    800053c2:	31c080e7          	jalr	796(ra) # 800036da <ilock>
  if(ip->type == T_DIR){
    800053c6:	04449703          	lh	a4,68(s1)
    800053ca:	4785                	li	a5,1
    800053cc:	08f70463          	beq	a4,a5,80005454 <sys_link+0xea>
  ip->nlink++;
    800053d0:	04a4d783          	lhu	a5,74(s1)
    800053d4:	2785                	addiw	a5,a5,1
    800053d6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053da:	8526                	mv	a0,s1
    800053dc:	ffffe097          	auipc	ra,0xffffe
    800053e0:	234080e7          	jalr	564(ra) # 80003610 <iupdate>
  iunlock(ip);
    800053e4:	8526                	mv	a0,s1
    800053e6:	ffffe097          	auipc	ra,0xffffe
    800053ea:	3b6080e7          	jalr	950(ra) # 8000379c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053ee:	fd040593          	addi	a1,s0,-48
    800053f2:	f5040513          	addi	a0,s0,-176
    800053f6:	fffff097          	auipc	ra,0xfffff
    800053fa:	ab2080e7          	jalr	-1358(ra) # 80003ea8 <nameiparent>
    800053fe:	892a                	mv	s2,a0
    80005400:	c935                	beqz	a0,80005474 <sys_link+0x10a>
  ilock(dp);
    80005402:	ffffe097          	auipc	ra,0xffffe
    80005406:	2d8080e7          	jalr	728(ra) # 800036da <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000540a:	00092703          	lw	a4,0(s2)
    8000540e:	409c                	lw	a5,0(s1)
    80005410:	04f71d63          	bne	a4,a5,8000546a <sys_link+0x100>
    80005414:	40d0                	lw	a2,4(s1)
    80005416:	fd040593          	addi	a1,s0,-48
    8000541a:	854a                	mv	a0,s2
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	9ac080e7          	jalr	-1620(ra) # 80003dc8 <dirlink>
    80005424:	04054363          	bltz	a0,8000546a <sys_link+0x100>
  iunlockput(dp);
    80005428:	854a                	mv	a0,s2
    8000542a:	ffffe097          	auipc	ra,0xffffe
    8000542e:	512080e7          	jalr	1298(ra) # 8000393c <iunlockput>
  iput(ip);
    80005432:	8526                	mv	a0,s1
    80005434:	ffffe097          	auipc	ra,0xffffe
    80005438:	460080e7          	jalr	1120(ra) # 80003894 <iput>
  end_op();
    8000543c:	fffff097          	auipc	ra,0xfffff
    80005440:	cda080e7          	jalr	-806(ra) # 80004116 <end_op>
  return 0;
    80005444:	4781                	li	a5,0
    80005446:	a085                	j	800054a6 <sys_link+0x13c>
    end_op();
    80005448:	fffff097          	auipc	ra,0xfffff
    8000544c:	cce080e7          	jalr	-818(ra) # 80004116 <end_op>
    return -1;
    80005450:	57fd                	li	a5,-1
    80005452:	a891                	j	800054a6 <sys_link+0x13c>
    iunlockput(ip);
    80005454:	8526                	mv	a0,s1
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	4e6080e7          	jalr	1254(ra) # 8000393c <iunlockput>
    end_op();
    8000545e:	fffff097          	auipc	ra,0xfffff
    80005462:	cb8080e7          	jalr	-840(ra) # 80004116 <end_op>
    return -1;
    80005466:	57fd                	li	a5,-1
    80005468:	a83d                	j	800054a6 <sys_link+0x13c>
    iunlockput(dp);
    8000546a:	854a                	mv	a0,s2
    8000546c:	ffffe097          	auipc	ra,0xffffe
    80005470:	4d0080e7          	jalr	1232(ra) # 8000393c <iunlockput>
  ilock(ip);
    80005474:	8526                	mv	a0,s1
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	264080e7          	jalr	612(ra) # 800036da <ilock>
  ip->nlink--;
    8000547e:	04a4d783          	lhu	a5,74(s1)
    80005482:	37fd                	addiw	a5,a5,-1
    80005484:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005488:	8526                	mv	a0,s1
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	186080e7          	jalr	390(ra) # 80003610 <iupdate>
  iunlockput(ip);
    80005492:	8526                	mv	a0,s1
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	4a8080e7          	jalr	1192(ra) # 8000393c <iunlockput>
  end_op();
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	c7a080e7          	jalr	-902(ra) # 80004116 <end_op>
  return -1;
    800054a4:	57fd                	li	a5,-1
}
    800054a6:	853e                	mv	a0,a5
    800054a8:	70b2                	ld	ra,296(sp)
    800054aa:	7412                	ld	s0,288(sp)
    800054ac:	64f2                	ld	s1,280(sp)
    800054ae:	6952                	ld	s2,272(sp)
    800054b0:	6155                	addi	sp,sp,304
    800054b2:	8082                	ret

00000000800054b4 <sys_unlink>:
{
    800054b4:	7151                	addi	sp,sp,-240
    800054b6:	f586                	sd	ra,232(sp)
    800054b8:	f1a2                	sd	s0,224(sp)
    800054ba:	eda6                	sd	s1,216(sp)
    800054bc:	e9ca                	sd	s2,208(sp)
    800054be:	e5ce                	sd	s3,200(sp)
    800054c0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054c2:	08000613          	li	a2,128
    800054c6:	f3040593          	addi	a1,s0,-208
    800054ca:	4501                	li	a0,0
    800054cc:	ffffd097          	auipc	ra,0xffffd
    800054d0:	658080e7          	jalr	1624(ra) # 80002b24 <argstr>
    800054d4:	18054163          	bltz	a0,80005656 <sys_unlink+0x1a2>
  begin_op();
    800054d8:	fffff097          	auipc	ra,0xfffff
    800054dc:	bbe080e7          	jalr	-1090(ra) # 80004096 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054e0:	fb040593          	addi	a1,s0,-80
    800054e4:	f3040513          	addi	a0,s0,-208
    800054e8:	fffff097          	auipc	ra,0xfffff
    800054ec:	9c0080e7          	jalr	-1600(ra) # 80003ea8 <nameiparent>
    800054f0:	84aa                	mv	s1,a0
    800054f2:	c979                	beqz	a0,800055c8 <sys_unlink+0x114>
  ilock(dp);
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	1e6080e7          	jalr	486(ra) # 800036da <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054fc:	00003597          	auipc	a1,0x3
    80005500:	36458593          	addi	a1,a1,868 # 80008860 <syscallnumber_to_name+0x2c0>
    80005504:	fb040513          	addi	a0,s0,-80
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	696080e7          	jalr	1686(ra) # 80003b9e <namecmp>
    80005510:	14050a63          	beqz	a0,80005664 <sys_unlink+0x1b0>
    80005514:	00003597          	auipc	a1,0x3
    80005518:	35458593          	addi	a1,a1,852 # 80008868 <syscallnumber_to_name+0x2c8>
    8000551c:	fb040513          	addi	a0,s0,-80
    80005520:	ffffe097          	auipc	ra,0xffffe
    80005524:	67e080e7          	jalr	1662(ra) # 80003b9e <namecmp>
    80005528:	12050e63          	beqz	a0,80005664 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000552c:	f2c40613          	addi	a2,s0,-212
    80005530:	fb040593          	addi	a1,s0,-80
    80005534:	8526                	mv	a0,s1
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	682080e7          	jalr	1666(ra) # 80003bb8 <dirlookup>
    8000553e:	892a                	mv	s2,a0
    80005540:	12050263          	beqz	a0,80005664 <sys_unlink+0x1b0>
  ilock(ip);
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	196080e7          	jalr	406(ra) # 800036da <ilock>
  if(ip->nlink < 1)
    8000554c:	04a91783          	lh	a5,74(s2)
    80005550:	08f05263          	blez	a5,800055d4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005554:	04491703          	lh	a4,68(s2)
    80005558:	4785                	li	a5,1
    8000555a:	08f70563          	beq	a4,a5,800055e4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000555e:	4641                	li	a2,16
    80005560:	4581                	li	a1,0
    80005562:	fc040513          	addi	a0,s0,-64
    80005566:	ffffb097          	auipc	ra,0xffffb
    8000556a:	7a6080e7          	jalr	1958(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000556e:	4741                	li	a4,16
    80005570:	f2c42683          	lw	a3,-212(s0)
    80005574:	fc040613          	addi	a2,s0,-64
    80005578:	4581                	li	a1,0
    8000557a:	8526                	mv	a0,s1
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	508080e7          	jalr	1288(ra) # 80003a84 <writei>
    80005584:	47c1                	li	a5,16
    80005586:	0af51563          	bne	a0,a5,80005630 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000558a:	04491703          	lh	a4,68(s2)
    8000558e:	4785                	li	a5,1
    80005590:	0af70863          	beq	a4,a5,80005640 <sys_unlink+0x18c>
  iunlockput(dp);
    80005594:	8526                	mv	a0,s1
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	3a6080e7          	jalr	934(ra) # 8000393c <iunlockput>
  ip->nlink--;
    8000559e:	04a95783          	lhu	a5,74(s2)
    800055a2:	37fd                	addiw	a5,a5,-1
    800055a4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055a8:	854a                	mv	a0,s2
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	066080e7          	jalr	102(ra) # 80003610 <iupdate>
  iunlockput(ip);
    800055b2:	854a                	mv	a0,s2
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	388080e7          	jalr	904(ra) # 8000393c <iunlockput>
  end_op();
    800055bc:	fffff097          	auipc	ra,0xfffff
    800055c0:	b5a080e7          	jalr	-1190(ra) # 80004116 <end_op>
  return 0;
    800055c4:	4501                	li	a0,0
    800055c6:	a84d                	j	80005678 <sys_unlink+0x1c4>
    end_op();
    800055c8:	fffff097          	auipc	ra,0xfffff
    800055cc:	b4e080e7          	jalr	-1202(ra) # 80004116 <end_op>
    return -1;
    800055d0:	557d                	li	a0,-1
    800055d2:	a05d                	j	80005678 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055d4:	00003517          	auipc	a0,0x3
    800055d8:	2bc50513          	addi	a0,a0,700 # 80008890 <syscallnumber_to_name+0x2f0>
    800055dc:	ffffb097          	auipc	ra,0xffffb
    800055e0:	f6c080e7          	jalr	-148(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055e4:	04c92703          	lw	a4,76(s2)
    800055e8:	02000793          	li	a5,32
    800055ec:	f6e7f9e3          	bgeu	a5,a4,8000555e <sys_unlink+0xaa>
    800055f0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055f4:	4741                	li	a4,16
    800055f6:	86ce                	mv	a3,s3
    800055f8:	f1840613          	addi	a2,s0,-232
    800055fc:	4581                	li	a1,0
    800055fe:	854a                	mv	a0,s2
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	38e080e7          	jalr	910(ra) # 8000398e <readi>
    80005608:	47c1                	li	a5,16
    8000560a:	00f51b63          	bne	a0,a5,80005620 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000560e:	f1845783          	lhu	a5,-232(s0)
    80005612:	e7a1                	bnez	a5,8000565a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005614:	29c1                	addiw	s3,s3,16
    80005616:	04c92783          	lw	a5,76(s2)
    8000561a:	fcf9ede3          	bltu	s3,a5,800055f4 <sys_unlink+0x140>
    8000561e:	b781                	j	8000555e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005620:	00003517          	auipc	a0,0x3
    80005624:	28850513          	addi	a0,a0,648 # 800088a8 <syscallnumber_to_name+0x308>
    80005628:	ffffb097          	auipc	ra,0xffffb
    8000562c:	f20080e7          	jalr	-224(ra) # 80000548 <panic>
    panic("unlink: writei");
    80005630:	00003517          	auipc	a0,0x3
    80005634:	29050513          	addi	a0,a0,656 # 800088c0 <syscallnumber_to_name+0x320>
    80005638:	ffffb097          	auipc	ra,0xffffb
    8000563c:	f10080e7          	jalr	-240(ra) # 80000548 <panic>
    dp->nlink--;
    80005640:	04a4d783          	lhu	a5,74(s1)
    80005644:	37fd                	addiw	a5,a5,-1
    80005646:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000564a:	8526                	mv	a0,s1
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	fc4080e7          	jalr	-60(ra) # 80003610 <iupdate>
    80005654:	b781                	j	80005594 <sys_unlink+0xe0>
    return -1;
    80005656:	557d                	li	a0,-1
    80005658:	a005                	j	80005678 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000565a:	854a                	mv	a0,s2
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	2e0080e7          	jalr	736(ra) # 8000393c <iunlockput>
  iunlockput(dp);
    80005664:	8526                	mv	a0,s1
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	2d6080e7          	jalr	726(ra) # 8000393c <iunlockput>
  end_op();
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	aa8080e7          	jalr	-1368(ra) # 80004116 <end_op>
  return -1;
    80005676:	557d                	li	a0,-1
}
    80005678:	70ae                	ld	ra,232(sp)
    8000567a:	740e                	ld	s0,224(sp)
    8000567c:	64ee                	ld	s1,216(sp)
    8000567e:	694e                	ld	s2,208(sp)
    80005680:	69ae                	ld	s3,200(sp)
    80005682:	616d                	addi	sp,sp,240
    80005684:	8082                	ret

0000000080005686 <sys_open>:

uint64
sys_open(void)
{
    80005686:	7131                	addi	sp,sp,-192
    80005688:	fd06                	sd	ra,184(sp)
    8000568a:	f922                	sd	s0,176(sp)
    8000568c:	f526                	sd	s1,168(sp)
    8000568e:	f14a                	sd	s2,160(sp)
    80005690:	ed4e                	sd	s3,152(sp)
    80005692:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005694:	08000613          	li	a2,128
    80005698:	f5040593          	addi	a1,s0,-176
    8000569c:	4501                	li	a0,0
    8000569e:	ffffd097          	auipc	ra,0xffffd
    800056a2:	486080e7          	jalr	1158(ra) # 80002b24 <argstr>
    return -1;
    800056a6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056a8:	0c054163          	bltz	a0,8000576a <sys_open+0xe4>
    800056ac:	f4c40593          	addi	a1,s0,-180
    800056b0:	4505                	li	a0,1
    800056b2:	ffffd097          	auipc	ra,0xffffd
    800056b6:	42e080e7          	jalr	1070(ra) # 80002ae0 <argint>
    800056ba:	0a054863          	bltz	a0,8000576a <sys_open+0xe4>

  begin_op();
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	9d8080e7          	jalr	-1576(ra) # 80004096 <begin_op>

  if(omode & O_CREATE){
    800056c6:	f4c42783          	lw	a5,-180(s0)
    800056ca:	2007f793          	andi	a5,a5,512
    800056ce:	cbdd                	beqz	a5,80005784 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056d0:	4681                	li	a3,0
    800056d2:	4601                	li	a2,0
    800056d4:	4589                	li	a1,2
    800056d6:	f5040513          	addi	a0,s0,-176
    800056da:	00000097          	auipc	ra,0x0
    800056de:	972080e7          	jalr	-1678(ra) # 8000504c <create>
    800056e2:	892a                	mv	s2,a0
    if(ip == 0){
    800056e4:	c959                	beqz	a0,8000577a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056e6:	04491703          	lh	a4,68(s2)
    800056ea:	478d                	li	a5,3
    800056ec:	00f71763          	bne	a4,a5,800056fa <sys_open+0x74>
    800056f0:	04695703          	lhu	a4,70(s2)
    800056f4:	47a5                	li	a5,9
    800056f6:	0ce7ec63          	bltu	a5,a4,800057ce <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	db2080e7          	jalr	-590(ra) # 800044ac <filealloc>
    80005702:	89aa                	mv	s3,a0
    80005704:	10050263          	beqz	a0,80005808 <sys_open+0x182>
    80005708:	00000097          	auipc	ra,0x0
    8000570c:	902080e7          	jalr	-1790(ra) # 8000500a <fdalloc>
    80005710:	84aa                	mv	s1,a0
    80005712:	0e054663          	bltz	a0,800057fe <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005716:	04491703          	lh	a4,68(s2)
    8000571a:	478d                	li	a5,3
    8000571c:	0cf70463          	beq	a4,a5,800057e4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005720:	4789                	li	a5,2
    80005722:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005726:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000572a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000572e:	f4c42783          	lw	a5,-180(s0)
    80005732:	0017c713          	xori	a4,a5,1
    80005736:	8b05                	andi	a4,a4,1
    80005738:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000573c:	0037f713          	andi	a4,a5,3
    80005740:	00e03733          	snez	a4,a4
    80005744:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005748:	4007f793          	andi	a5,a5,1024
    8000574c:	c791                	beqz	a5,80005758 <sys_open+0xd2>
    8000574e:	04491703          	lh	a4,68(s2)
    80005752:	4789                	li	a5,2
    80005754:	08f70f63          	beq	a4,a5,800057f2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005758:	854a                	mv	a0,s2
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	042080e7          	jalr	66(ra) # 8000379c <iunlock>
  end_op();
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	9b4080e7          	jalr	-1612(ra) # 80004116 <end_op>

  return fd;
}
    8000576a:	8526                	mv	a0,s1
    8000576c:	70ea                	ld	ra,184(sp)
    8000576e:	744a                	ld	s0,176(sp)
    80005770:	74aa                	ld	s1,168(sp)
    80005772:	790a                	ld	s2,160(sp)
    80005774:	69ea                	ld	s3,152(sp)
    80005776:	6129                	addi	sp,sp,192
    80005778:	8082                	ret
      end_op();
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	99c080e7          	jalr	-1636(ra) # 80004116 <end_op>
      return -1;
    80005782:	b7e5                	j	8000576a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005784:	f5040513          	addi	a0,s0,-176
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	702080e7          	jalr	1794(ra) # 80003e8a <namei>
    80005790:	892a                	mv	s2,a0
    80005792:	c905                	beqz	a0,800057c2 <sys_open+0x13c>
    ilock(ip);
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	f46080e7          	jalr	-186(ra) # 800036da <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000579c:	04491703          	lh	a4,68(s2)
    800057a0:	4785                	li	a5,1
    800057a2:	f4f712e3          	bne	a4,a5,800056e6 <sys_open+0x60>
    800057a6:	f4c42783          	lw	a5,-180(s0)
    800057aa:	dba1                	beqz	a5,800056fa <sys_open+0x74>
      iunlockput(ip);
    800057ac:	854a                	mv	a0,s2
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	18e080e7          	jalr	398(ra) # 8000393c <iunlockput>
      end_op();
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	960080e7          	jalr	-1696(ra) # 80004116 <end_op>
      return -1;
    800057be:	54fd                	li	s1,-1
    800057c0:	b76d                	j	8000576a <sys_open+0xe4>
      end_op();
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	954080e7          	jalr	-1708(ra) # 80004116 <end_op>
      return -1;
    800057ca:	54fd                	li	s1,-1
    800057cc:	bf79                	j	8000576a <sys_open+0xe4>
    iunlockput(ip);
    800057ce:	854a                	mv	a0,s2
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	16c080e7          	jalr	364(ra) # 8000393c <iunlockput>
    end_op();
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	93e080e7          	jalr	-1730(ra) # 80004116 <end_op>
    return -1;
    800057e0:	54fd                	li	s1,-1
    800057e2:	b761                	j	8000576a <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057e4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057e8:	04691783          	lh	a5,70(s2)
    800057ec:	02f99223          	sh	a5,36(s3)
    800057f0:	bf2d                	j	8000572a <sys_open+0xa4>
    itrunc(ip);
    800057f2:	854a                	mv	a0,s2
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	ff4080e7          	jalr	-12(ra) # 800037e8 <itrunc>
    800057fc:	bfb1                	j	80005758 <sys_open+0xd2>
      fileclose(f);
    800057fe:	854e                	mv	a0,s3
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	d68080e7          	jalr	-664(ra) # 80004568 <fileclose>
    iunlockput(ip);
    80005808:	854a                	mv	a0,s2
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	132080e7          	jalr	306(ra) # 8000393c <iunlockput>
    end_op();
    80005812:	fffff097          	auipc	ra,0xfffff
    80005816:	904080e7          	jalr	-1788(ra) # 80004116 <end_op>
    return -1;
    8000581a:	54fd                	li	s1,-1
    8000581c:	b7b9                	j	8000576a <sys_open+0xe4>

000000008000581e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000581e:	7175                	addi	sp,sp,-144
    80005820:	e506                	sd	ra,136(sp)
    80005822:	e122                	sd	s0,128(sp)
    80005824:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	870080e7          	jalr	-1936(ra) # 80004096 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000582e:	08000613          	li	a2,128
    80005832:	f7040593          	addi	a1,s0,-144
    80005836:	4501                	li	a0,0
    80005838:	ffffd097          	auipc	ra,0xffffd
    8000583c:	2ec080e7          	jalr	748(ra) # 80002b24 <argstr>
    80005840:	02054963          	bltz	a0,80005872 <sys_mkdir+0x54>
    80005844:	4681                	li	a3,0
    80005846:	4601                	li	a2,0
    80005848:	4585                	li	a1,1
    8000584a:	f7040513          	addi	a0,s0,-144
    8000584e:	fffff097          	auipc	ra,0xfffff
    80005852:	7fe080e7          	jalr	2046(ra) # 8000504c <create>
    80005856:	cd11                	beqz	a0,80005872 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	0e4080e7          	jalr	228(ra) # 8000393c <iunlockput>
  end_op();
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	8b6080e7          	jalr	-1866(ra) # 80004116 <end_op>
  return 0;
    80005868:	4501                	li	a0,0
}
    8000586a:	60aa                	ld	ra,136(sp)
    8000586c:	640a                	ld	s0,128(sp)
    8000586e:	6149                	addi	sp,sp,144
    80005870:	8082                	ret
    end_op();
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	8a4080e7          	jalr	-1884(ra) # 80004116 <end_op>
    return -1;
    8000587a:	557d                	li	a0,-1
    8000587c:	b7fd                	j	8000586a <sys_mkdir+0x4c>

000000008000587e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000587e:	7135                	addi	sp,sp,-160
    80005880:	ed06                	sd	ra,152(sp)
    80005882:	e922                	sd	s0,144(sp)
    80005884:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	810080e7          	jalr	-2032(ra) # 80004096 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000588e:	08000613          	li	a2,128
    80005892:	f7040593          	addi	a1,s0,-144
    80005896:	4501                	li	a0,0
    80005898:	ffffd097          	auipc	ra,0xffffd
    8000589c:	28c080e7          	jalr	652(ra) # 80002b24 <argstr>
    800058a0:	04054a63          	bltz	a0,800058f4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058a4:	f6c40593          	addi	a1,s0,-148
    800058a8:	4505                	li	a0,1
    800058aa:	ffffd097          	auipc	ra,0xffffd
    800058ae:	236080e7          	jalr	566(ra) # 80002ae0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058b2:	04054163          	bltz	a0,800058f4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058b6:	f6840593          	addi	a1,s0,-152
    800058ba:	4509                	li	a0,2
    800058bc:	ffffd097          	auipc	ra,0xffffd
    800058c0:	224080e7          	jalr	548(ra) # 80002ae0 <argint>
     argint(1, &major) < 0 ||
    800058c4:	02054863          	bltz	a0,800058f4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058c8:	f6841683          	lh	a3,-152(s0)
    800058cc:	f6c41603          	lh	a2,-148(s0)
    800058d0:	458d                	li	a1,3
    800058d2:	f7040513          	addi	a0,s0,-144
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	776080e7          	jalr	1910(ra) # 8000504c <create>
     argint(2, &minor) < 0 ||
    800058de:	c919                	beqz	a0,800058f4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	05c080e7          	jalr	92(ra) # 8000393c <iunlockput>
  end_op();
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	82e080e7          	jalr	-2002(ra) # 80004116 <end_op>
  return 0;
    800058f0:	4501                	li	a0,0
    800058f2:	a031                	j	800058fe <sys_mknod+0x80>
    end_op();
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	822080e7          	jalr	-2014(ra) # 80004116 <end_op>
    return -1;
    800058fc:	557d                	li	a0,-1
}
    800058fe:	60ea                	ld	ra,152(sp)
    80005900:	644a                	ld	s0,144(sp)
    80005902:	610d                	addi	sp,sp,160
    80005904:	8082                	ret

0000000080005906 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005906:	7135                	addi	sp,sp,-160
    80005908:	ed06                	sd	ra,152(sp)
    8000590a:	e922                	sd	s0,144(sp)
    8000590c:	e526                	sd	s1,136(sp)
    8000590e:	e14a                	sd	s2,128(sp)
    80005910:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005912:	ffffc097          	auipc	ra,0xffffc
    80005916:	0cc080e7          	jalr	204(ra) # 800019de <myproc>
    8000591a:	892a                	mv	s2,a0
  
  begin_op();
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	77a080e7          	jalr	1914(ra) # 80004096 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005924:	08000613          	li	a2,128
    80005928:	f6040593          	addi	a1,s0,-160
    8000592c:	4501                	li	a0,0
    8000592e:	ffffd097          	auipc	ra,0xffffd
    80005932:	1f6080e7          	jalr	502(ra) # 80002b24 <argstr>
    80005936:	04054b63          	bltz	a0,8000598c <sys_chdir+0x86>
    8000593a:	f6040513          	addi	a0,s0,-160
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	54c080e7          	jalr	1356(ra) # 80003e8a <namei>
    80005946:	84aa                	mv	s1,a0
    80005948:	c131                	beqz	a0,8000598c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	d90080e7          	jalr	-624(ra) # 800036da <ilock>
  if(ip->type != T_DIR){
    80005952:	04449703          	lh	a4,68(s1)
    80005956:	4785                	li	a5,1
    80005958:	04f71063          	bne	a4,a5,80005998 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000595c:	8526                	mv	a0,s1
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	e3e080e7          	jalr	-450(ra) # 8000379c <iunlock>
  iput(p->cwd);
    80005966:	15093503          	ld	a0,336(s2)
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	f2a080e7          	jalr	-214(ra) # 80003894 <iput>
  end_op();
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	7a4080e7          	jalr	1956(ra) # 80004116 <end_op>
  p->cwd = ip;
    8000597a:	14993823          	sd	s1,336(s2)
  return 0;
    8000597e:	4501                	li	a0,0
}
    80005980:	60ea                	ld	ra,152(sp)
    80005982:	644a                	ld	s0,144(sp)
    80005984:	64aa                	ld	s1,136(sp)
    80005986:	690a                	ld	s2,128(sp)
    80005988:	610d                	addi	sp,sp,160
    8000598a:	8082                	ret
    end_op();
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	78a080e7          	jalr	1930(ra) # 80004116 <end_op>
    return -1;
    80005994:	557d                	li	a0,-1
    80005996:	b7ed                	j	80005980 <sys_chdir+0x7a>
    iunlockput(ip);
    80005998:	8526                	mv	a0,s1
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	fa2080e7          	jalr	-94(ra) # 8000393c <iunlockput>
    end_op();
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	774080e7          	jalr	1908(ra) # 80004116 <end_op>
    return -1;
    800059aa:	557d                	li	a0,-1
    800059ac:	bfd1                	j	80005980 <sys_chdir+0x7a>

00000000800059ae <sys_exec>:

uint64
sys_exec(void)
{
    800059ae:	7145                	addi	sp,sp,-464
    800059b0:	e786                	sd	ra,456(sp)
    800059b2:	e3a2                	sd	s0,448(sp)
    800059b4:	ff26                	sd	s1,440(sp)
    800059b6:	fb4a                	sd	s2,432(sp)
    800059b8:	f74e                	sd	s3,424(sp)
    800059ba:	f352                	sd	s4,416(sp)
    800059bc:	ef56                	sd	s5,408(sp)
    800059be:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059c0:	08000613          	li	a2,128
    800059c4:	f4040593          	addi	a1,s0,-192
    800059c8:	4501                	li	a0,0
    800059ca:	ffffd097          	auipc	ra,0xffffd
    800059ce:	15a080e7          	jalr	346(ra) # 80002b24 <argstr>
    return -1;
    800059d2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059d4:	0c054a63          	bltz	a0,80005aa8 <sys_exec+0xfa>
    800059d8:	e3840593          	addi	a1,s0,-456
    800059dc:	4505                	li	a0,1
    800059de:	ffffd097          	auipc	ra,0xffffd
    800059e2:	124080e7          	jalr	292(ra) # 80002b02 <argaddr>
    800059e6:	0c054163          	bltz	a0,80005aa8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800059ea:	10000613          	li	a2,256
    800059ee:	4581                	li	a1,0
    800059f0:	e4040513          	addi	a0,s0,-448
    800059f4:	ffffb097          	auipc	ra,0xffffb
    800059f8:	318080e7          	jalr	792(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059fc:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a00:	89a6                	mv	s3,s1
    80005a02:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a04:	02000a13          	li	s4,32
    80005a08:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a0c:	00391513          	slli	a0,s2,0x3
    80005a10:	e3040593          	addi	a1,s0,-464
    80005a14:	e3843783          	ld	a5,-456(s0)
    80005a18:	953e                	add	a0,a0,a5
    80005a1a:	ffffd097          	auipc	ra,0xffffd
    80005a1e:	02c080e7          	jalr	44(ra) # 80002a46 <fetchaddr>
    80005a22:	02054a63          	bltz	a0,80005a56 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a26:	e3043783          	ld	a5,-464(s0)
    80005a2a:	c3b9                	beqz	a5,80005a70 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a2c:	ffffb097          	auipc	ra,0xffffb
    80005a30:	0f4080e7          	jalr	244(ra) # 80000b20 <kalloc>
    80005a34:	85aa                	mv	a1,a0
    80005a36:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a3a:	cd11                	beqz	a0,80005a56 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a3c:	6605                	lui	a2,0x1
    80005a3e:	e3043503          	ld	a0,-464(s0)
    80005a42:	ffffd097          	auipc	ra,0xffffd
    80005a46:	056080e7          	jalr	86(ra) # 80002a98 <fetchstr>
    80005a4a:	00054663          	bltz	a0,80005a56 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a4e:	0905                	addi	s2,s2,1
    80005a50:	09a1                	addi	s3,s3,8
    80005a52:	fb491be3          	bne	s2,s4,80005a08 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a56:	10048913          	addi	s2,s1,256
    80005a5a:	6088                	ld	a0,0(s1)
    80005a5c:	c529                	beqz	a0,80005aa6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a5e:	ffffb097          	auipc	ra,0xffffb
    80005a62:	fc6080e7          	jalr	-58(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a66:	04a1                	addi	s1,s1,8
    80005a68:	ff2499e3          	bne	s1,s2,80005a5a <sys_exec+0xac>
  return -1;
    80005a6c:	597d                	li	s2,-1
    80005a6e:	a82d                	j	80005aa8 <sys_exec+0xfa>
      argv[i] = 0;
    80005a70:	0a8e                	slli	s5,s5,0x3
    80005a72:	fc040793          	addi	a5,s0,-64
    80005a76:	9abe                	add	s5,s5,a5
    80005a78:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a7c:	e4040593          	addi	a1,s0,-448
    80005a80:	f4040513          	addi	a0,s0,-192
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	194080e7          	jalr	404(ra) # 80004c18 <exec>
    80005a8c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a8e:	10048993          	addi	s3,s1,256
    80005a92:	6088                	ld	a0,0(s1)
    80005a94:	c911                	beqz	a0,80005aa8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a96:	ffffb097          	auipc	ra,0xffffb
    80005a9a:	f8e080e7          	jalr	-114(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a9e:	04a1                	addi	s1,s1,8
    80005aa0:	ff3499e3          	bne	s1,s3,80005a92 <sys_exec+0xe4>
    80005aa4:	a011                	j	80005aa8 <sys_exec+0xfa>
  return -1;
    80005aa6:	597d                	li	s2,-1
}
    80005aa8:	854a                	mv	a0,s2
    80005aaa:	60be                	ld	ra,456(sp)
    80005aac:	641e                	ld	s0,448(sp)
    80005aae:	74fa                	ld	s1,440(sp)
    80005ab0:	795a                	ld	s2,432(sp)
    80005ab2:	79ba                	ld	s3,424(sp)
    80005ab4:	7a1a                	ld	s4,416(sp)
    80005ab6:	6afa                	ld	s5,408(sp)
    80005ab8:	6179                	addi	sp,sp,464
    80005aba:	8082                	ret

0000000080005abc <sys_pipe>:

uint64
sys_pipe(void)
{
    80005abc:	7139                	addi	sp,sp,-64
    80005abe:	fc06                	sd	ra,56(sp)
    80005ac0:	f822                	sd	s0,48(sp)
    80005ac2:	f426                	sd	s1,40(sp)
    80005ac4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ac6:	ffffc097          	auipc	ra,0xffffc
    80005aca:	f18080e7          	jalr	-232(ra) # 800019de <myproc>
    80005ace:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ad0:	fd840593          	addi	a1,s0,-40
    80005ad4:	4501                	li	a0,0
    80005ad6:	ffffd097          	auipc	ra,0xffffd
    80005ada:	02c080e7          	jalr	44(ra) # 80002b02 <argaddr>
    return -1;
    80005ade:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ae0:	0e054063          	bltz	a0,80005bc0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ae4:	fc840593          	addi	a1,s0,-56
    80005ae8:	fd040513          	addi	a0,s0,-48
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	dd2080e7          	jalr	-558(ra) # 800048be <pipealloc>
    return -1;
    80005af4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005af6:	0c054563          	bltz	a0,80005bc0 <sys_pipe+0x104>
  fd0 = -1;
    80005afa:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005afe:	fd043503          	ld	a0,-48(s0)
    80005b02:	fffff097          	auipc	ra,0xfffff
    80005b06:	508080e7          	jalr	1288(ra) # 8000500a <fdalloc>
    80005b0a:	fca42223          	sw	a0,-60(s0)
    80005b0e:	08054c63          	bltz	a0,80005ba6 <sys_pipe+0xea>
    80005b12:	fc843503          	ld	a0,-56(s0)
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	4f4080e7          	jalr	1268(ra) # 8000500a <fdalloc>
    80005b1e:	fca42023          	sw	a0,-64(s0)
    80005b22:	06054863          	bltz	a0,80005b92 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b26:	4691                	li	a3,4
    80005b28:	fc440613          	addi	a2,s0,-60
    80005b2c:	fd843583          	ld	a1,-40(s0)
    80005b30:	68a8                	ld	a0,80(s1)
    80005b32:	ffffc097          	auipc	ra,0xffffc
    80005b36:	ba0080e7          	jalr	-1120(ra) # 800016d2 <copyout>
    80005b3a:	02054063          	bltz	a0,80005b5a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b3e:	4691                	li	a3,4
    80005b40:	fc040613          	addi	a2,s0,-64
    80005b44:	fd843583          	ld	a1,-40(s0)
    80005b48:	0591                	addi	a1,a1,4
    80005b4a:	68a8                	ld	a0,80(s1)
    80005b4c:	ffffc097          	auipc	ra,0xffffc
    80005b50:	b86080e7          	jalr	-1146(ra) # 800016d2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b54:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b56:	06055563          	bgez	a0,80005bc0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b5a:	fc442783          	lw	a5,-60(s0)
    80005b5e:	07e9                	addi	a5,a5,26
    80005b60:	078e                	slli	a5,a5,0x3
    80005b62:	97a6                	add	a5,a5,s1
    80005b64:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b68:	fc042503          	lw	a0,-64(s0)
    80005b6c:	0569                	addi	a0,a0,26
    80005b6e:	050e                	slli	a0,a0,0x3
    80005b70:	9526                	add	a0,a0,s1
    80005b72:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b76:	fd043503          	ld	a0,-48(s0)
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	9ee080e7          	jalr	-1554(ra) # 80004568 <fileclose>
    fileclose(wf);
    80005b82:	fc843503          	ld	a0,-56(s0)
    80005b86:	fffff097          	auipc	ra,0xfffff
    80005b8a:	9e2080e7          	jalr	-1566(ra) # 80004568 <fileclose>
    return -1;
    80005b8e:	57fd                	li	a5,-1
    80005b90:	a805                	j	80005bc0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b92:	fc442783          	lw	a5,-60(s0)
    80005b96:	0007c863          	bltz	a5,80005ba6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b9a:	01a78513          	addi	a0,a5,26
    80005b9e:	050e                	slli	a0,a0,0x3
    80005ba0:	9526                	add	a0,a0,s1
    80005ba2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ba6:	fd043503          	ld	a0,-48(s0)
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	9be080e7          	jalr	-1602(ra) # 80004568 <fileclose>
    fileclose(wf);
    80005bb2:	fc843503          	ld	a0,-56(s0)
    80005bb6:	fffff097          	auipc	ra,0xfffff
    80005bba:	9b2080e7          	jalr	-1614(ra) # 80004568 <fileclose>
    return -1;
    80005bbe:	57fd                	li	a5,-1
}
    80005bc0:	853e                	mv	a0,a5
    80005bc2:	70e2                	ld	ra,56(sp)
    80005bc4:	7442                	ld	s0,48(sp)
    80005bc6:	74a2                	ld	s1,40(sp)
    80005bc8:	6121                	addi	sp,sp,64
    80005bca:	8082                	ret
    80005bcc:	0000                	unimp
	...

0000000080005bd0 <kernelvec>:
    80005bd0:	7111                	addi	sp,sp,-256
    80005bd2:	e006                	sd	ra,0(sp)
    80005bd4:	e40a                	sd	sp,8(sp)
    80005bd6:	e80e                	sd	gp,16(sp)
    80005bd8:	ec12                	sd	tp,24(sp)
    80005bda:	f016                	sd	t0,32(sp)
    80005bdc:	f41a                	sd	t1,40(sp)
    80005bde:	f81e                	sd	t2,48(sp)
    80005be0:	fc22                	sd	s0,56(sp)
    80005be2:	e0a6                	sd	s1,64(sp)
    80005be4:	e4aa                	sd	a0,72(sp)
    80005be6:	e8ae                	sd	a1,80(sp)
    80005be8:	ecb2                	sd	a2,88(sp)
    80005bea:	f0b6                	sd	a3,96(sp)
    80005bec:	f4ba                	sd	a4,104(sp)
    80005bee:	f8be                	sd	a5,112(sp)
    80005bf0:	fcc2                	sd	a6,120(sp)
    80005bf2:	e146                	sd	a7,128(sp)
    80005bf4:	e54a                	sd	s2,136(sp)
    80005bf6:	e94e                	sd	s3,144(sp)
    80005bf8:	ed52                	sd	s4,152(sp)
    80005bfa:	f156                	sd	s5,160(sp)
    80005bfc:	f55a                	sd	s6,168(sp)
    80005bfe:	f95e                	sd	s7,176(sp)
    80005c00:	fd62                	sd	s8,184(sp)
    80005c02:	e1e6                	sd	s9,192(sp)
    80005c04:	e5ea                	sd	s10,200(sp)
    80005c06:	e9ee                	sd	s11,208(sp)
    80005c08:	edf2                	sd	t3,216(sp)
    80005c0a:	f1f6                	sd	t4,224(sp)
    80005c0c:	f5fa                	sd	t5,232(sp)
    80005c0e:	f9fe                	sd	t6,240(sp)
    80005c10:	d03fc0ef          	jal	ra,80002912 <kerneltrap>
    80005c14:	6082                	ld	ra,0(sp)
    80005c16:	6122                	ld	sp,8(sp)
    80005c18:	61c2                	ld	gp,16(sp)
    80005c1a:	7282                	ld	t0,32(sp)
    80005c1c:	7322                	ld	t1,40(sp)
    80005c1e:	73c2                	ld	t2,48(sp)
    80005c20:	7462                	ld	s0,56(sp)
    80005c22:	6486                	ld	s1,64(sp)
    80005c24:	6526                	ld	a0,72(sp)
    80005c26:	65c6                	ld	a1,80(sp)
    80005c28:	6666                	ld	a2,88(sp)
    80005c2a:	7686                	ld	a3,96(sp)
    80005c2c:	7726                	ld	a4,104(sp)
    80005c2e:	77c6                	ld	a5,112(sp)
    80005c30:	7866                	ld	a6,120(sp)
    80005c32:	688a                	ld	a7,128(sp)
    80005c34:	692a                	ld	s2,136(sp)
    80005c36:	69ca                	ld	s3,144(sp)
    80005c38:	6a6a                	ld	s4,152(sp)
    80005c3a:	7a8a                	ld	s5,160(sp)
    80005c3c:	7b2a                	ld	s6,168(sp)
    80005c3e:	7bca                	ld	s7,176(sp)
    80005c40:	7c6a                	ld	s8,184(sp)
    80005c42:	6c8e                	ld	s9,192(sp)
    80005c44:	6d2e                	ld	s10,200(sp)
    80005c46:	6dce                	ld	s11,208(sp)
    80005c48:	6e6e                	ld	t3,216(sp)
    80005c4a:	7e8e                	ld	t4,224(sp)
    80005c4c:	7f2e                	ld	t5,232(sp)
    80005c4e:	7fce                	ld	t6,240(sp)
    80005c50:	6111                	addi	sp,sp,256
    80005c52:	10200073          	sret
    80005c56:	00000013          	nop
    80005c5a:	00000013          	nop
    80005c5e:	0001                	nop

0000000080005c60 <timervec>:
    80005c60:	34051573          	csrrw	a0,mscratch,a0
    80005c64:	e10c                	sd	a1,0(a0)
    80005c66:	e510                	sd	a2,8(a0)
    80005c68:	e914                	sd	a3,16(a0)
    80005c6a:	710c                	ld	a1,32(a0)
    80005c6c:	7510                	ld	a2,40(a0)
    80005c6e:	6194                	ld	a3,0(a1)
    80005c70:	96b2                	add	a3,a3,a2
    80005c72:	e194                	sd	a3,0(a1)
    80005c74:	4589                	li	a1,2
    80005c76:	14459073          	csrw	sip,a1
    80005c7a:	6914                	ld	a3,16(a0)
    80005c7c:	6510                	ld	a2,8(a0)
    80005c7e:	610c                	ld	a1,0(a0)
    80005c80:	34051573          	csrrw	a0,mscratch,a0
    80005c84:	30200073          	mret
	...

0000000080005c8a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c8a:	1141                	addi	sp,sp,-16
    80005c8c:	e422                	sd	s0,8(sp)
    80005c8e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c90:	0c0007b7          	lui	a5,0xc000
    80005c94:	4705                	li	a4,1
    80005c96:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c98:	c3d8                	sw	a4,4(a5)
}
    80005c9a:	6422                	ld	s0,8(sp)
    80005c9c:	0141                	addi	sp,sp,16
    80005c9e:	8082                	ret

0000000080005ca0 <plicinithart>:

void
plicinithart(void)
{
    80005ca0:	1141                	addi	sp,sp,-16
    80005ca2:	e406                	sd	ra,8(sp)
    80005ca4:	e022                	sd	s0,0(sp)
    80005ca6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ca8:	ffffc097          	auipc	ra,0xffffc
    80005cac:	d0a080e7          	jalr	-758(ra) # 800019b2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cb0:	0085171b          	slliw	a4,a0,0x8
    80005cb4:	0c0027b7          	lui	a5,0xc002
    80005cb8:	97ba                	add	a5,a5,a4
    80005cba:	40200713          	li	a4,1026
    80005cbe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005cc2:	00d5151b          	slliw	a0,a0,0xd
    80005cc6:	0c2017b7          	lui	a5,0xc201
    80005cca:	953e                	add	a0,a0,a5
    80005ccc:	00052023          	sw	zero,0(a0)
}
    80005cd0:	60a2                	ld	ra,8(sp)
    80005cd2:	6402                	ld	s0,0(sp)
    80005cd4:	0141                	addi	sp,sp,16
    80005cd6:	8082                	ret

0000000080005cd8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cd8:	1141                	addi	sp,sp,-16
    80005cda:	e406                	sd	ra,8(sp)
    80005cdc:	e022                	sd	s0,0(sp)
    80005cde:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ce0:	ffffc097          	auipc	ra,0xffffc
    80005ce4:	cd2080e7          	jalr	-814(ra) # 800019b2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ce8:	00d5179b          	slliw	a5,a0,0xd
    80005cec:	0c201537          	lui	a0,0xc201
    80005cf0:	953e                	add	a0,a0,a5
  return irq;
}
    80005cf2:	4148                	lw	a0,4(a0)
    80005cf4:	60a2                	ld	ra,8(sp)
    80005cf6:	6402                	ld	s0,0(sp)
    80005cf8:	0141                	addi	sp,sp,16
    80005cfa:	8082                	ret

0000000080005cfc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cfc:	1101                	addi	sp,sp,-32
    80005cfe:	ec06                	sd	ra,24(sp)
    80005d00:	e822                	sd	s0,16(sp)
    80005d02:	e426                	sd	s1,8(sp)
    80005d04:	1000                	addi	s0,sp,32
    80005d06:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d08:	ffffc097          	auipc	ra,0xffffc
    80005d0c:	caa080e7          	jalr	-854(ra) # 800019b2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d10:	00d5151b          	slliw	a0,a0,0xd
    80005d14:	0c2017b7          	lui	a5,0xc201
    80005d18:	97aa                	add	a5,a5,a0
    80005d1a:	c3c4                	sw	s1,4(a5)
}
    80005d1c:	60e2                	ld	ra,24(sp)
    80005d1e:	6442                	ld	s0,16(sp)
    80005d20:	64a2                	ld	s1,8(sp)
    80005d22:	6105                	addi	sp,sp,32
    80005d24:	8082                	ret

0000000080005d26 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d26:	1141                	addi	sp,sp,-16
    80005d28:	e406                	sd	ra,8(sp)
    80005d2a:	e022                	sd	s0,0(sp)
    80005d2c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d2e:	479d                	li	a5,7
    80005d30:	04a7cc63          	blt	a5,a0,80005d88 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005d34:	0001d797          	auipc	a5,0x1d
    80005d38:	2cc78793          	addi	a5,a5,716 # 80023000 <disk>
    80005d3c:	00a78733          	add	a4,a5,a0
    80005d40:	6789                	lui	a5,0x2
    80005d42:	97ba                	add	a5,a5,a4
    80005d44:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d48:	eba1                	bnez	a5,80005d98 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005d4a:	00451713          	slli	a4,a0,0x4
    80005d4e:	0001f797          	auipc	a5,0x1f
    80005d52:	2b27b783          	ld	a5,690(a5) # 80025000 <disk+0x2000>
    80005d56:	97ba                	add	a5,a5,a4
    80005d58:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005d5c:	0001d797          	auipc	a5,0x1d
    80005d60:	2a478793          	addi	a5,a5,676 # 80023000 <disk>
    80005d64:	97aa                	add	a5,a5,a0
    80005d66:	6509                	lui	a0,0x2
    80005d68:	953e                	add	a0,a0,a5
    80005d6a:	4785                	li	a5,1
    80005d6c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d70:	0001f517          	auipc	a0,0x1f
    80005d74:	2a850513          	addi	a0,a0,680 # 80025018 <disk+0x2018>
    80005d78:	ffffc097          	auipc	ra,0xffffc
    80005d7c:	604080e7          	jalr	1540(ra) # 8000237c <wakeup>
}
    80005d80:	60a2                	ld	ra,8(sp)
    80005d82:	6402                	ld	s0,0(sp)
    80005d84:	0141                	addi	sp,sp,16
    80005d86:	8082                	ret
    panic("virtio_disk_intr 1");
    80005d88:	00003517          	auipc	a0,0x3
    80005d8c:	b4850513          	addi	a0,a0,-1208 # 800088d0 <syscallnumber_to_name+0x330>
    80005d90:	ffffa097          	auipc	ra,0xffffa
    80005d94:	7b8080e7          	jalr	1976(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005d98:	00003517          	auipc	a0,0x3
    80005d9c:	b5050513          	addi	a0,a0,-1200 # 800088e8 <syscallnumber_to_name+0x348>
    80005da0:	ffffa097          	auipc	ra,0xffffa
    80005da4:	7a8080e7          	jalr	1960(ra) # 80000548 <panic>

0000000080005da8 <virtio_disk_init>:
{
    80005da8:	1101                	addi	sp,sp,-32
    80005daa:	ec06                	sd	ra,24(sp)
    80005dac:	e822                	sd	s0,16(sp)
    80005dae:	e426                	sd	s1,8(sp)
    80005db0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005db2:	00003597          	auipc	a1,0x3
    80005db6:	b4e58593          	addi	a1,a1,-1202 # 80008900 <syscallnumber_to_name+0x360>
    80005dba:	0001f517          	auipc	a0,0x1f
    80005dbe:	2ee50513          	addi	a0,a0,750 # 800250a8 <disk+0x20a8>
    80005dc2:	ffffb097          	auipc	ra,0xffffb
    80005dc6:	dbe080e7          	jalr	-578(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dca:	100017b7          	lui	a5,0x10001
    80005dce:	4398                	lw	a4,0(a5)
    80005dd0:	2701                	sext.w	a4,a4
    80005dd2:	747277b7          	lui	a5,0x74727
    80005dd6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005dda:	0ef71163          	bne	a4,a5,80005ebc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dde:	100017b7          	lui	a5,0x10001
    80005de2:	43dc                	lw	a5,4(a5)
    80005de4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005de6:	4705                	li	a4,1
    80005de8:	0ce79a63          	bne	a5,a4,80005ebc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dec:	100017b7          	lui	a5,0x10001
    80005df0:	479c                	lw	a5,8(a5)
    80005df2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005df4:	4709                	li	a4,2
    80005df6:	0ce79363          	bne	a5,a4,80005ebc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005dfa:	100017b7          	lui	a5,0x10001
    80005dfe:	47d8                	lw	a4,12(a5)
    80005e00:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e02:	554d47b7          	lui	a5,0x554d4
    80005e06:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e0a:	0af71963          	bne	a4,a5,80005ebc <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e0e:	100017b7          	lui	a5,0x10001
    80005e12:	4705                	li	a4,1
    80005e14:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e16:	470d                	li	a4,3
    80005e18:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e1a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e1c:	c7ffe737          	lui	a4,0xc7ffe
    80005e20:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e24:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e26:	2701                	sext.w	a4,a4
    80005e28:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e2a:	472d                	li	a4,11
    80005e2c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e2e:	473d                	li	a4,15
    80005e30:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e32:	6705                	lui	a4,0x1
    80005e34:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e36:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e3a:	5bdc                	lw	a5,52(a5)
    80005e3c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e3e:	c7d9                	beqz	a5,80005ecc <virtio_disk_init+0x124>
  if(max < NUM)
    80005e40:	471d                	li	a4,7
    80005e42:	08f77d63          	bgeu	a4,a5,80005edc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e46:	100014b7          	lui	s1,0x10001
    80005e4a:	47a1                	li	a5,8
    80005e4c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e4e:	6609                	lui	a2,0x2
    80005e50:	4581                	li	a1,0
    80005e52:	0001d517          	auipc	a0,0x1d
    80005e56:	1ae50513          	addi	a0,a0,430 # 80023000 <disk>
    80005e5a:	ffffb097          	auipc	ra,0xffffb
    80005e5e:	eb2080e7          	jalr	-334(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e62:	0001d717          	auipc	a4,0x1d
    80005e66:	19e70713          	addi	a4,a4,414 # 80023000 <disk>
    80005e6a:	00c75793          	srli	a5,a4,0xc
    80005e6e:	2781                	sext.w	a5,a5
    80005e70:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005e72:	0001f797          	auipc	a5,0x1f
    80005e76:	18e78793          	addi	a5,a5,398 # 80025000 <disk+0x2000>
    80005e7a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005e7c:	0001d717          	auipc	a4,0x1d
    80005e80:	20470713          	addi	a4,a4,516 # 80023080 <disk+0x80>
    80005e84:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005e86:	0001e717          	auipc	a4,0x1e
    80005e8a:	17a70713          	addi	a4,a4,378 # 80024000 <disk+0x1000>
    80005e8e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e90:	4705                	li	a4,1
    80005e92:	00e78c23          	sb	a4,24(a5)
    80005e96:	00e78ca3          	sb	a4,25(a5)
    80005e9a:	00e78d23          	sb	a4,26(a5)
    80005e9e:	00e78da3          	sb	a4,27(a5)
    80005ea2:	00e78e23          	sb	a4,28(a5)
    80005ea6:	00e78ea3          	sb	a4,29(a5)
    80005eaa:	00e78f23          	sb	a4,30(a5)
    80005eae:	00e78fa3          	sb	a4,31(a5)
}
    80005eb2:	60e2                	ld	ra,24(sp)
    80005eb4:	6442                	ld	s0,16(sp)
    80005eb6:	64a2                	ld	s1,8(sp)
    80005eb8:	6105                	addi	sp,sp,32
    80005eba:	8082                	ret
    panic("could not find virtio disk");
    80005ebc:	00003517          	auipc	a0,0x3
    80005ec0:	a5450513          	addi	a0,a0,-1452 # 80008910 <syscallnumber_to_name+0x370>
    80005ec4:	ffffa097          	auipc	ra,0xffffa
    80005ec8:	684080e7          	jalr	1668(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005ecc:	00003517          	auipc	a0,0x3
    80005ed0:	a6450513          	addi	a0,a0,-1436 # 80008930 <syscallnumber_to_name+0x390>
    80005ed4:	ffffa097          	auipc	ra,0xffffa
    80005ed8:	674080e7          	jalr	1652(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005edc:	00003517          	auipc	a0,0x3
    80005ee0:	a7450513          	addi	a0,a0,-1420 # 80008950 <syscallnumber_to_name+0x3b0>
    80005ee4:	ffffa097          	auipc	ra,0xffffa
    80005ee8:	664080e7          	jalr	1636(ra) # 80000548 <panic>

0000000080005eec <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005eec:	7119                	addi	sp,sp,-128
    80005eee:	fc86                	sd	ra,120(sp)
    80005ef0:	f8a2                	sd	s0,112(sp)
    80005ef2:	f4a6                	sd	s1,104(sp)
    80005ef4:	f0ca                	sd	s2,96(sp)
    80005ef6:	ecce                	sd	s3,88(sp)
    80005ef8:	e8d2                	sd	s4,80(sp)
    80005efa:	e4d6                	sd	s5,72(sp)
    80005efc:	e0da                	sd	s6,64(sp)
    80005efe:	fc5e                	sd	s7,56(sp)
    80005f00:	f862                	sd	s8,48(sp)
    80005f02:	f466                	sd	s9,40(sp)
    80005f04:	f06a                	sd	s10,32(sp)
    80005f06:	0100                	addi	s0,sp,128
    80005f08:	892a                	mv	s2,a0
    80005f0a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f0c:	00c52c83          	lw	s9,12(a0)
    80005f10:	001c9c9b          	slliw	s9,s9,0x1
    80005f14:	1c82                	slli	s9,s9,0x20
    80005f16:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f1a:	0001f517          	auipc	a0,0x1f
    80005f1e:	18e50513          	addi	a0,a0,398 # 800250a8 <disk+0x20a8>
    80005f22:	ffffb097          	auipc	ra,0xffffb
    80005f26:	cee080e7          	jalr	-786(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    80005f2a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f2c:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f2e:	0001db97          	auipc	s7,0x1d
    80005f32:	0d2b8b93          	addi	s7,s7,210 # 80023000 <disk>
    80005f36:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f38:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f3a:	8a4e                	mv	s4,s3
    80005f3c:	a051                	j	80005fc0 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f3e:	00fb86b3          	add	a3,s7,a5
    80005f42:	96da                	add	a3,a3,s6
    80005f44:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005f48:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005f4a:	0207c563          	bltz	a5,80005f74 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f4e:	2485                	addiw	s1,s1,1
    80005f50:	0711                	addi	a4,a4,4
    80005f52:	23548d63          	beq	s1,s5,8000618c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005f56:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005f58:	0001f697          	auipc	a3,0x1f
    80005f5c:	0c068693          	addi	a3,a3,192 # 80025018 <disk+0x2018>
    80005f60:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005f62:	0006c583          	lbu	a1,0(a3)
    80005f66:	fde1                	bnez	a1,80005f3e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f68:	2785                	addiw	a5,a5,1
    80005f6a:	0685                	addi	a3,a3,1
    80005f6c:	ff879be3          	bne	a5,s8,80005f62 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f70:	57fd                	li	a5,-1
    80005f72:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005f74:	02905a63          	blez	s1,80005fa8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f78:	f9042503          	lw	a0,-112(s0)
    80005f7c:	00000097          	auipc	ra,0x0
    80005f80:	daa080e7          	jalr	-598(ra) # 80005d26 <free_desc>
      for(int j = 0; j < i; j++)
    80005f84:	4785                	li	a5,1
    80005f86:	0297d163          	bge	a5,s1,80005fa8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f8a:	f9442503          	lw	a0,-108(s0)
    80005f8e:	00000097          	auipc	ra,0x0
    80005f92:	d98080e7          	jalr	-616(ra) # 80005d26 <free_desc>
      for(int j = 0; j < i; j++)
    80005f96:	4789                	li	a5,2
    80005f98:	0097d863          	bge	a5,s1,80005fa8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f9c:	f9842503          	lw	a0,-104(s0)
    80005fa0:	00000097          	auipc	ra,0x0
    80005fa4:	d86080e7          	jalr	-634(ra) # 80005d26 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fa8:	0001f597          	auipc	a1,0x1f
    80005fac:	10058593          	addi	a1,a1,256 # 800250a8 <disk+0x20a8>
    80005fb0:	0001f517          	auipc	a0,0x1f
    80005fb4:	06850513          	addi	a0,a0,104 # 80025018 <disk+0x2018>
    80005fb8:	ffffc097          	auipc	ra,0xffffc
    80005fbc:	23e080e7          	jalr	574(ra) # 800021f6 <sleep>
  for(int i = 0; i < 3; i++){
    80005fc0:	f9040713          	addi	a4,s0,-112
    80005fc4:	84ce                	mv	s1,s3
    80005fc6:	bf41                	j	80005f56 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80005fc8:	4785                	li	a5,1
    80005fca:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    80005fce:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80005fd2:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80005fd6:	f9042983          	lw	s3,-112(s0)
    80005fda:	00499493          	slli	s1,s3,0x4
    80005fde:	0001fa17          	auipc	s4,0x1f
    80005fe2:	022a0a13          	addi	s4,s4,34 # 80025000 <disk+0x2000>
    80005fe6:	000a3a83          	ld	s5,0(s4)
    80005fea:	9aa6                	add	s5,s5,s1
    80005fec:	f8040513          	addi	a0,s0,-128
    80005ff0:	ffffb097          	auipc	ra,0xffffb
    80005ff4:	0f0080e7          	jalr	240(ra) # 800010e0 <kvmpa>
    80005ff8:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    80005ffc:	000a3783          	ld	a5,0(s4)
    80006000:	97a6                	add	a5,a5,s1
    80006002:	4741                	li	a4,16
    80006004:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006006:	000a3783          	ld	a5,0(s4)
    8000600a:	97a6                	add	a5,a5,s1
    8000600c:	4705                	li	a4,1
    8000600e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006012:	f9442703          	lw	a4,-108(s0)
    80006016:	000a3783          	ld	a5,0(s4)
    8000601a:	97a6                	add	a5,a5,s1
    8000601c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006020:	0712                	slli	a4,a4,0x4
    80006022:	000a3783          	ld	a5,0(s4)
    80006026:	97ba                	add	a5,a5,a4
    80006028:	05890693          	addi	a3,s2,88
    8000602c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000602e:	000a3783          	ld	a5,0(s4)
    80006032:	97ba                	add	a5,a5,a4
    80006034:	40000693          	li	a3,1024
    80006038:	c794                	sw	a3,8(a5)
  if(write)
    8000603a:	100d0a63          	beqz	s10,8000614e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000603e:	0001f797          	auipc	a5,0x1f
    80006042:	fc27b783          	ld	a5,-62(a5) # 80025000 <disk+0x2000>
    80006046:	97ba                	add	a5,a5,a4
    80006048:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000604c:	0001d517          	auipc	a0,0x1d
    80006050:	fb450513          	addi	a0,a0,-76 # 80023000 <disk>
    80006054:	0001f797          	auipc	a5,0x1f
    80006058:	fac78793          	addi	a5,a5,-84 # 80025000 <disk+0x2000>
    8000605c:	6394                	ld	a3,0(a5)
    8000605e:	96ba                	add	a3,a3,a4
    80006060:	00c6d603          	lhu	a2,12(a3)
    80006064:	00166613          	ori	a2,a2,1
    80006068:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000606c:	f9842683          	lw	a3,-104(s0)
    80006070:	6390                	ld	a2,0(a5)
    80006072:	9732                	add	a4,a4,a2
    80006074:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006078:	20098613          	addi	a2,s3,512
    8000607c:	0612                	slli	a2,a2,0x4
    8000607e:	962a                	add	a2,a2,a0
    80006080:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006084:	00469713          	slli	a4,a3,0x4
    80006088:	6394                	ld	a3,0(a5)
    8000608a:	96ba                	add	a3,a3,a4
    8000608c:	6589                	lui	a1,0x2
    8000608e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006092:	94ae                	add	s1,s1,a1
    80006094:	94aa                	add	s1,s1,a0
    80006096:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006098:	6394                	ld	a3,0(a5)
    8000609a:	96ba                	add	a3,a3,a4
    8000609c:	4585                	li	a1,1
    8000609e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060a0:	6394                	ld	a3,0(a5)
    800060a2:	96ba                	add	a3,a3,a4
    800060a4:	4509                	li	a0,2
    800060a6:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800060aa:	6394                	ld	a3,0(a5)
    800060ac:	9736                	add	a4,a4,a3
    800060ae:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060b2:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800060b6:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800060ba:	6794                	ld	a3,8(a5)
    800060bc:	0026d703          	lhu	a4,2(a3)
    800060c0:	8b1d                	andi	a4,a4,7
    800060c2:	2709                	addiw	a4,a4,2
    800060c4:	0706                	slli	a4,a4,0x1
    800060c6:	9736                	add	a4,a4,a3
    800060c8:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    800060cc:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800060d0:	6798                	ld	a4,8(a5)
    800060d2:	00275783          	lhu	a5,2(a4)
    800060d6:	2785                	addiw	a5,a5,1
    800060d8:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060dc:	100017b7          	lui	a5,0x10001
    800060e0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060e4:	00492703          	lw	a4,4(s2)
    800060e8:	4785                	li	a5,1
    800060ea:	02f71163          	bne	a4,a5,8000610c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    800060ee:	0001f997          	auipc	s3,0x1f
    800060f2:	fba98993          	addi	s3,s3,-70 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800060f6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800060f8:	85ce                	mv	a1,s3
    800060fa:	854a                	mv	a0,s2
    800060fc:	ffffc097          	auipc	ra,0xffffc
    80006100:	0fa080e7          	jalr	250(ra) # 800021f6 <sleep>
  while(b->disk == 1) {
    80006104:	00492783          	lw	a5,4(s2)
    80006108:	fe9788e3          	beq	a5,s1,800060f8 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000610c:	f9042483          	lw	s1,-112(s0)
    80006110:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006114:	00479713          	slli	a4,a5,0x4
    80006118:	0001d797          	auipc	a5,0x1d
    8000611c:	ee878793          	addi	a5,a5,-280 # 80023000 <disk>
    80006120:	97ba                	add	a5,a5,a4
    80006122:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006126:	0001f917          	auipc	s2,0x1f
    8000612a:	eda90913          	addi	s2,s2,-294 # 80025000 <disk+0x2000>
    free_desc(i);
    8000612e:	8526                	mv	a0,s1
    80006130:	00000097          	auipc	ra,0x0
    80006134:	bf6080e7          	jalr	-1034(ra) # 80005d26 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006138:	0492                	slli	s1,s1,0x4
    8000613a:	00093783          	ld	a5,0(s2)
    8000613e:	94be                	add	s1,s1,a5
    80006140:	00c4d783          	lhu	a5,12(s1)
    80006144:	8b85                	andi	a5,a5,1
    80006146:	cf89                	beqz	a5,80006160 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006148:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000614c:	b7cd                	j	8000612e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000614e:	0001f797          	auipc	a5,0x1f
    80006152:	eb27b783          	ld	a5,-334(a5) # 80025000 <disk+0x2000>
    80006156:	97ba                	add	a5,a5,a4
    80006158:	4689                	li	a3,2
    8000615a:	00d79623          	sh	a3,12(a5)
    8000615e:	b5fd                	j	8000604c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006160:	0001f517          	auipc	a0,0x1f
    80006164:	f4850513          	addi	a0,a0,-184 # 800250a8 <disk+0x20a8>
    80006168:	ffffb097          	auipc	ra,0xffffb
    8000616c:	b5c080e7          	jalr	-1188(ra) # 80000cc4 <release>
}
    80006170:	70e6                	ld	ra,120(sp)
    80006172:	7446                	ld	s0,112(sp)
    80006174:	74a6                	ld	s1,104(sp)
    80006176:	7906                	ld	s2,96(sp)
    80006178:	69e6                	ld	s3,88(sp)
    8000617a:	6a46                	ld	s4,80(sp)
    8000617c:	6aa6                	ld	s5,72(sp)
    8000617e:	6b06                	ld	s6,64(sp)
    80006180:	7be2                	ld	s7,56(sp)
    80006182:	7c42                	ld	s8,48(sp)
    80006184:	7ca2                	ld	s9,40(sp)
    80006186:	7d02                	ld	s10,32(sp)
    80006188:	6109                	addi	sp,sp,128
    8000618a:	8082                	ret
  if(write)
    8000618c:	e20d1ee3          	bnez	s10,80005fc8 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006190:	f8042023          	sw	zero,-128(s0)
    80006194:	bd2d                	j	80005fce <virtio_disk_rw+0xe2>

0000000080006196 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006196:	1101                	addi	sp,sp,-32
    80006198:	ec06                	sd	ra,24(sp)
    8000619a:	e822                	sd	s0,16(sp)
    8000619c:	e426                	sd	s1,8(sp)
    8000619e:	e04a                	sd	s2,0(sp)
    800061a0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061a2:	0001f517          	auipc	a0,0x1f
    800061a6:	f0650513          	addi	a0,a0,-250 # 800250a8 <disk+0x20a8>
    800061aa:	ffffb097          	auipc	ra,0xffffb
    800061ae:	a66080e7          	jalr	-1434(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800061b2:	0001f717          	auipc	a4,0x1f
    800061b6:	e4e70713          	addi	a4,a4,-434 # 80025000 <disk+0x2000>
    800061ba:	02075783          	lhu	a5,32(a4)
    800061be:	6b18                	ld	a4,16(a4)
    800061c0:	00275683          	lhu	a3,2(a4)
    800061c4:	8ebd                	xor	a3,a3,a5
    800061c6:	8a9d                	andi	a3,a3,7
    800061c8:	cab9                	beqz	a3,8000621e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800061ca:	0001d917          	auipc	s2,0x1d
    800061ce:	e3690913          	addi	s2,s2,-458 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800061d2:	0001f497          	auipc	s1,0x1f
    800061d6:	e2e48493          	addi	s1,s1,-466 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800061da:	078e                	slli	a5,a5,0x3
    800061dc:	97ba                	add	a5,a5,a4
    800061de:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800061e0:	20078713          	addi	a4,a5,512
    800061e4:	0712                	slli	a4,a4,0x4
    800061e6:	974a                	add	a4,a4,s2
    800061e8:	03074703          	lbu	a4,48(a4)
    800061ec:	ef21                	bnez	a4,80006244 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800061ee:	20078793          	addi	a5,a5,512
    800061f2:	0792                	slli	a5,a5,0x4
    800061f4:	97ca                	add	a5,a5,s2
    800061f6:	7798                	ld	a4,40(a5)
    800061f8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800061fc:	7788                	ld	a0,40(a5)
    800061fe:	ffffc097          	auipc	ra,0xffffc
    80006202:	17e080e7          	jalr	382(ra) # 8000237c <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006206:	0204d783          	lhu	a5,32(s1)
    8000620a:	2785                	addiw	a5,a5,1
    8000620c:	8b9d                	andi	a5,a5,7
    8000620e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006212:	6898                	ld	a4,16(s1)
    80006214:	00275683          	lhu	a3,2(a4)
    80006218:	8a9d                	andi	a3,a3,7
    8000621a:	fcf690e3          	bne	a3,a5,800061da <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000621e:	10001737          	lui	a4,0x10001
    80006222:	533c                	lw	a5,96(a4)
    80006224:	8b8d                	andi	a5,a5,3
    80006226:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006228:	0001f517          	auipc	a0,0x1f
    8000622c:	e8050513          	addi	a0,a0,-384 # 800250a8 <disk+0x20a8>
    80006230:	ffffb097          	auipc	ra,0xffffb
    80006234:	a94080e7          	jalr	-1388(ra) # 80000cc4 <release>
}
    80006238:	60e2                	ld	ra,24(sp)
    8000623a:	6442                	ld	s0,16(sp)
    8000623c:	64a2                	ld	s1,8(sp)
    8000623e:	6902                	ld	s2,0(sp)
    80006240:	6105                	addi	sp,sp,32
    80006242:	8082                	ret
      panic("virtio_disk_intr status");
    80006244:	00002517          	auipc	a0,0x2
    80006248:	72c50513          	addi	a0,a0,1836 # 80008970 <syscallnumber_to_name+0x3d0>
    8000624c:	ffffa097          	auipc	ra,0xffffa
    80006250:	2fc080e7          	jalr	764(ra) # 80000548 <panic>
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

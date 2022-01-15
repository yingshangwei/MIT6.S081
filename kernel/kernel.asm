
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
    80000060:	ca478793          	addi	a5,a5,-860 # 80005d00 <timervec>
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
    800000aa:	e6278793          	addi	a5,a5,-414 # 80000f08 <main>
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
    80000110:	b4e080e7          	jalr	-1202(ra) # 80000c5a <acquire>
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
    8000012a:	3d2080e7          	jalr	978(ra) # 800024f8 <either_copyin>
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
    80000152:	bc0080e7          	jalr	-1088(ra) # 80000d0e <release>

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
    800001a2:	abc080e7          	jalr	-1348(ra) # 80000c5a <acquire>
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
    800001d2:	85a080e7          	jalr	-1958(ra) # 80001a28 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	062080e7          	jalr	98(ra) # 80002240 <sleep>
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
    8000021e:	288080e7          	jalr	648(ra) # 800024a2 <either_copyout>
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
    8000023a:	ad8080e7          	jalr	-1320(ra) # 80000d0e <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	ac2080e7          	jalr	-1342(ra) # 80000d0e <release>
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
    800002e2:	97c080e7          	jalr	-1668(ra) # 80000c5a <acquire>

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
    80000300:	252080e7          	jalr	594(ra) # 8000254e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	a02080e7          	jalr	-1534(ra) # 80000d0e <release>
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
    80000454:	f76080e7          	jalr	-138(ra) # 800023c6 <wakeup>
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
    80000476:	758080e7          	jalr	1880(ra) # 80000bca <initlock>

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
    8000060e:	650080e7          	jalr	1616(ra) # 80000c5a <acquire>
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
    80000772:	5a0080e7          	jalr	1440(ra) # 80000d0e <release>
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
    80000798:	436080e7          	jalr	1078(ra) # 80000bca <initlock>
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
    800007ee:	3e0080e7          	jalr	992(ra) # 80000bca <initlock>
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
    8000080a:	408080e7          	jalr	1032(ra) # 80000c0e <push_off>

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
    8000083c:	476080e7          	jalr	1142(ra) # 80000cae <pop_off>
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
    800008ba:	b10080e7          	jalr	-1264(ra) # 800023c6 <wakeup>
    
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
    800008fe:	360080e7          	jalr	864(ra) # 80000c5a <acquire>
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
    80000954:	8f0080e7          	jalr	-1808(ra) # 80002240 <sleep>
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
    80000998:	37a080e7          	jalr	890(ra) # 80000d0e <release>
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
    80000a04:	25a080e7          	jalr	602(ra) # 80000c5a <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2fc080e7          	jalr	764(ra) # 80000d0e <release>
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
    80000a54:	306080e7          	jalr	774(ra) # 80000d56 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1f8080e7          	jalr	504(ra) # 80000c5a <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	298080e7          	jalr	664(ra) # 80000d0e <release>
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
    80000b00:	0ce080e7          	jalr	206(ra) # 80000bca <initlock>
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
    80000b38:	126080e7          	jalr	294(ra) # 80000c5a <acquire>
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
    80000b50:	1c2080e7          	jalr	450(ra) # 80000d0e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1fc080e7          	jalr	508(ra) # 80000d56 <memset>
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
    80000b7a:	198080e7          	jalr	408(ra) # 80000d0e <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <get_freememory_count>:

// ysw
uint64 
get_freememory_count() {
    80000b80:	1101                	addi	sp,sp,-32
    80000b82:	ec06                	sd	ra,24(sp)
    80000b84:	e822                	sd	s0,16(sp)
    80000b86:	e426                	sd	s1,8(sp)
    80000b88:	1000                	addi	s0,sp,32
  struct run *r;
  uint64 cnt = 0;
  acquire(&kmem.lock);
    80000b8a:	00011497          	auipc	s1,0x11
    80000b8e:	da648493          	addi	s1,s1,-602 # 80011930 <kmem>
    80000b92:	8526                	mv	a0,s1
    80000b94:	00000097          	auipc	ra,0x0
    80000b98:	0c6080e7          	jalr	198(ra) # 80000c5a <acquire>
  r = kmem.freelist;
    80000b9c:	6c9c                	ld	a5,24(s1)
  while(r) {
    80000b9e:	c785                	beqz	a5,80000bc6 <get_freememory_count+0x46>
  uint64 cnt = 0;
    80000ba0:	4481                	li	s1,0
    r = r->next;
    80000ba2:	639c                	ld	a5,0(a5)
    cnt++;
    80000ba4:	0485                	addi	s1,s1,1
  while(r) {
    80000ba6:	fff5                	bnez	a5,80000ba2 <get_freememory_count+0x22>
  }
  release(&kmem.lock);
    80000ba8:	00011517          	auipc	a0,0x11
    80000bac:	d8850513          	addi	a0,a0,-632 # 80011930 <kmem>
    80000bb0:	00000097          	auipc	ra,0x0
    80000bb4:	15e080e7          	jalr	350(ra) # 80000d0e <release>

  return cnt*4096;
}
    80000bb8:	00c49513          	slli	a0,s1,0xc
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
  uint64 cnt = 0;
    80000bc6:	4481                	li	s1,0
    80000bc8:	b7c5                	j	80000ba8 <get_freememory_count+0x28>

0000000080000bca <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bca:	1141                	addi	sp,sp,-16
    80000bcc:	e422                	sd	s0,8(sp)
    80000bce:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bd0:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bd2:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bd6:	00053823          	sd	zero,16(a0)
}
    80000bda:	6422                	ld	s0,8(sp)
    80000bdc:	0141                	addi	sp,sp,16
    80000bde:	8082                	ret

0000000080000be0 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000be0:	411c                	lw	a5,0(a0)
    80000be2:	e399                	bnez	a5,80000be8 <holding+0x8>
    80000be4:	4501                	li	a0,0
  return r;
}
    80000be6:	8082                	ret
{
    80000be8:	1101                	addi	sp,sp,-32
    80000bea:	ec06                	sd	ra,24(sp)
    80000bec:	e822                	sd	s0,16(sp)
    80000bee:	e426                	sd	s1,8(sp)
    80000bf0:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bf2:	6904                	ld	s1,16(a0)
    80000bf4:	00001097          	auipc	ra,0x1
    80000bf8:	e18080e7          	jalr	-488(ra) # 80001a0c <mycpu>
    80000bfc:	40a48533          	sub	a0,s1,a0
    80000c00:	00153513          	seqz	a0,a0
}
    80000c04:	60e2                	ld	ra,24(sp)
    80000c06:	6442                	ld	s0,16(sp)
    80000c08:	64a2                	ld	s1,8(sp)
    80000c0a:	6105                	addi	sp,sp,32
    80000c0c:	8082                	ret

0000000080000c0e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c0e:	1101                	addi	sp,sp,-32
    80000c10:	ec06                	sd	ra,24(sp)
    80000c12:	e822                	sd	s0,16(sp)
    80000c14:	e426                	sd	s1,8(sp)
    80000c16:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c18:	100024f3          	csrr	s1,sstatus
    80000c1c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c20:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c22:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c26:	00001097          	auipc	ra,0x1
    80000c2a:	de6080e7          	jalr	-538(ra) # 80001a0c <mycpu>
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	cf89                	beqz	a5,80000c4a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	dda080e7          	jalr	-550(ra) # 80001a0c <mycpu>
    80000c3a:	5d3c                	lw	a5,120(a0)
    80000c3c:	2785                	addiw	a5,a5,1
    80000c3e:	dd3c                	sw	a5,120(a0)
}
    80000c40:	60e2                	ld	ra,24(sp)
    80000c42:	6442                	ld	s0,16(sp)
    80000c44:	64a2                	ld	s1,8(sp)
    80000c46:	6105                	addi	sp,sp,32
    80000c48:	8082                	ret
    mycpu()->intena = old;
    80000c4a:	00001097          	auipc	ra,0x1
    80000c4e:	dc2080e7          	jalr	-574(ra) # 80001a0c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8085                	srli	s1,s1,0x1
    80000c54:	8885                	andi	s1,s1,1
    80000c56:	dd64                	sw	s1,124(a0)
    80000c58:	bfe9                	j	80000c32 <push_off+0x24>

0000000080000c5a <acquire>:
{
    80000c5a:	1101                	addi	sp,sp,-32
    80000c5c:	ec06                	sd	ra,24(sp)
    80000c5e:	e822                	sd	s0,16(sp)
    80000c60:	e426                	sd	s1,8(sp)
    80000c62:	1000                	addi	s0,sp,32
    80000c64:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c66:	00000097          	auipc	ra,0x0
    80000c6a:	fa8080e7          	jalr	-88(ra) # 80000c0e <push_off>
  if(holding(lk))
    80000c6e:	8526                	mv	a0,s1
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	f70080e7          	jalr	-144(ra) # 80000be0 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c78:	4705                	li	a4,1
  if(holding(lk))
    80000c7a:	e115                	bnez	a0,80000c9e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c7c:	87ba                	mv	a5,a4
    80000c7e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c82:	2781                	sext.w	a5,a5
    80000c84:	ffe5                	bnez	a5,80000c7c <acquire+0x22>
  __sync_synchronize();
    80000c86:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c8a:	00001097          	auipc	ra,0x1
    80000c8e:	d82080e7          	jalr	-638(ra) # 80001a0c <mycpu>
    80000c92:	e888                	sd	a0,16(s1)
}
    80000c94:	60e2                	ld	ra,24(sp)
    80000c96:	6442                	ld	s0,16(sp)
    80000c98:	64a2                	ld	s1,8(sp)
    80000c9a:	6105                	addi	sp,sp,32
    80000c9c:	8082                	ret
    panic("acquire");
    80000c9e:	00007517          	auipc	a0,0x7
    80000ca2:	3d250513          	addi	a0,a0,978 # 80008070 <digits+0x30>
    80000ca6:	00000097          	auipc	ra,0x0
    80000caa:	8a2080e7          	jalr	-1886(ra) # 80000548 <panic>

0000000080000cae <pop_off>:

void
pop_off(void)
{
    80000cae:	1141                	addi	sp,sp,-16
    80000cb0:	e406                	sd	ra,8(sp)
    80000cb2:	e022                	sd	s0,0(sp)
    80000cb4:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cb6:	00001097          	auipc	ra,0x1
    80000cba:	d56080e7          	jalr	-682(ra) # 80001a0c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cbe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cc2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cc4:	e78d                	bnez	a5,80000cee <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cc6:	5d3c                	lw	a5,120(a0)
    80000cc8:	02f05b63          	blez	a5,80000cfe <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ccc:	37fd                	addiw	a5,a5,-1
    80000cce:	0007871b          	sext.w	a4,a5
    80000cd2:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cd4:	eb09                	bnez	a4,80000ce6 <pop_off+0x38>
    80000cd6:	5d7c                	lw	a5,124(a0)
    80000cd8:	c799                	beqz	a5,80000ce6 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cda:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cde:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ce2:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000ce6:	60a2                	ld	ra,8(sp)
    80000ce8:	6402                	ld	s0,0(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret
    panic("pop_off - interruptible");
    80000cee:	00007517          	auipc	a0,0x7
    80000cf2:	38a50513          	addi	a0,a0,906 # 80008078 <digits+0x38>
    80000cf6:	00000097          	auipc	ra,0x0
    80000cfa:	852080e7          	jalr	-1966(ra) # 80000548 <panic>
    panic("pop_off");
    80000cfe:	00007517          	auipc	a0,0x7
    80000d02:	39250513          	addi	a0,a0,914 # 80008090 <digits+0x50>
    80000d06:	00000097          	auipc	ra,0x0
    80000d0a:	842080e7          	jalr	-1982(ra) # 80000548 <panic>

0000000080000d0e <release>:
{
    80000d0e:	1101                	addi	sp,sp,-32
    80000d10:	ec06                	sd	ra,24(sp)
    80000d12:	e822                	sd	s0,16(sp)
    80000d14:	e426                	sd	s1,8(sp)
    80000d16:	1000                	addi	s0,sp,32
    80000d18:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d1a:	00000097          	auipc	ra,0x0
    80000d1e:	ec6080e7          	jalr	-314(ra) # 80000be0 <holding>
    80000d22:	c115                	beqz	a0,80000d46 <release+0x38>
  lk->cpu = 0;
    80000d24:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d28:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d2c:	0f50000f          	fence	iorw,ow
    80000d30:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d34:	00000097          	auipc	ra,0x0
    80000d38:	f7a080e7          	jalr	-134(ra) # 80000cae <pop_off>
}
    80000d3c:	60e2                	ld	ra,24(sp)
    80000d3e:	6442                	ld	s0,16(sp)
    80000d40:	64a2                	ld	s1,8(sp)
    80000d42:	6105                	addi	sp,sp,32
    80000d44:	8082                	ret
    panic("release");
    80000d46:	00007517          	auipc	a0,0x7
    80000d4a:	35250513          	addi	a0,a0,850 # 80008098 <digits+0x58>
    80000d4e:	fffff097          	auipc	ra,0xfffff
    80000d52:	7fa080e7          	jalr	2042(ra) # 80000548 <panic>

0000000080000d56 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d5c:	ce09                	beqz	a2,80000d76 <memset+0x20>
    80000d5e:	87aa                	mv	a5,a0
    80000d60:	fff6071b          	addiw	a4,a2,-1
    80000d64:	1702                	slli	a4,a4,0x20
    80000d66:	9301                	srli	a4,a4,0x20
    80000d68:	0705                	addi	a4,a4,1
    80000d6a:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d6c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d70:	0785                	addi	a5,a5,1
    80000d72:	fee79de3          	bne	a5,a4,80000d6c <memset+0x16>
  }
  return dst;
}
    80000d76:	6422                	ld	s0,8(sp)
    80000d78:	0141                	addi	sp,sp,16
    80000d7a:	8082                	ret

0000000080000d7c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d7c:	1141                	addi	sp,sp,-16
    80000d7e:	e422                	sd	s0,8(sp)
    80000d80:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d82:	ca05                	beqz	a2,80000db2 <memcmp+0x36>
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	1682                	slli	a3,a3,0x20
    80000d8a:	9281                	srli	a3,a3,0x20
    80000d8c:	0685                	addi	a3,a3,1
    80000d8e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d90:	00054783          	lbu	a5,0(a0)
    80000d94:	0005c703          	lbu	a4,0(a1)
    80000d98:	00e79863          	bne	a5,a4,80000da8 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d9c:	0505                	addi	a0,a0,1
    80000d9e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000da0:	fed518e3          	bne	a0,a3,80000d90 <memcmp+0x14>
  }

  return 0;
    80000da4:	4501                	li	a0,0
    80000da6:	a019                	j	80000dac <memcmp+0x30>
      return *s1 - *s2;
    80000da8:	40e7853b          	subw	a0,a5,a4
}
    80000dac:	6422                	ld	s0,8(sp)
    80000dae:	0141                	addi	sp,sp,16
    80000db0:	8082                	ret
  return 0;
    80000db2:	4501                	li	a0,0
    80000db4:	bfe5                	j	80000dac <memcmp+0x30>

0000000080000db6 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000db6:	1141                	addi	sp,sp,-16
    80000db8:	e422                	sd	s0,8(sp)
    80000dba:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dbc:	00a5f963          	bgeu	a1,a0,80000dce <memmove+0x18>
    80000dc0:	02061713          	slli	a4,a2,0x20
    80000dc4:	9301                	srli	a4,a4,0x20
    80000dc6:	00e587b3          	add	a5,a1,a4
    80000dca:	02f56563          	bltu	a0,a5,80000df4 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dce:	fff6069b          	addiw	a3,a2,-1
    80000dd2:	ce11                	beqz	a2,80000dee <memmove+0x38>
    80000dd4:	1682                	slli	a3,a3,0x20
    80000dd6:	9281                	srli	a3,a3,0x20
    80000dd8:	0685                	addi	a3,a3,1
    80000dda:	96ae                	add	a3,a3,a1
    80000ddc:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000dde:	0585                	addi	a1,a1,1
    80000de0:	0785                	addi	a5,a5,1
    80000de2:	fff5c703          	lbu	a4,-1(a1)
    80000de6:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dea:	fed59ae3          	bne	a1,a3,80000dde <memmove+0x28>

  return dst;
}
    80000dee:	6422                	ld	s0,8(sp)
    80000df0:	0141                	addi	sp,sp,16
    80000df2:	8082                	ret
    d += n;
    80000df4:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000df6:	fff6069b          	addiw	a3,a2,-1
    80000dfa:	da75                	beqz	a2,80000dee <memmove+0x38>
    80000dfc:	02069613          	slli	a2,a3,0x20
    80000e00:	9201                	srli	a2,a2,0x20
    80000e02:	fff64613          	not	a2,a2
    80000e06:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e08:	17fd                	addi	a5,a5,-1
    80000e0a:	177d                	addi	a4,a4,-1
    80000e0c:	0007c683          	lbu	a3,0(a5)
    80000e10:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e14:	fec79ae3          	bne	a5,a2,80000e08 <memmove+0x52>
    80000e18:	bfd9                	j	80000dee <memmove+0x38>

0000000080000e1a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e1a:	1141                	addi	sp,sp,-16
    80000e1c:	e406                	sd	ra,8(sp)
    80000e1e:	e022                	sd	s0,0(sp)
    80000e20:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e22:	00000097          	auipc	ra,0x0
    80000e26:	f94080e7          	jalr	-108(ra) # 80000db6 <memmove>
}
    80000e2a:	60a2                	ld	ra,8(sp)
    80000e2c:	6402                	ld	s0,0(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e38:	ce11                	beqz	a2,80000e54 <strncmp+0x22>
    80000e3a:	00054783          	lbu	a5,0(a0)
    80000e3e:	cf89                	beqz	a5,80000e58 <strncmp+0x26>
    80000e40:	0005c703          	lbu	a4,0(a1)
    80000e44:	00f71a63          	bne	a4,a5,80000e58 <strncmp+0x26>
    n--, p++, q++;
    80000e48:	367d                	addiw	a2,a2,-1
    80000e4a:	0505                	addi	a0,a0,1
    80000e4c:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e4e:	f675                	bnez	a2,80000e3a <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e50:	4501                	li	a0,0
    80000e52:	a809                	j	80000e64 <strncmp+0x32>
    80000e54:	4501                	li	a0,0
    80000e56:	a039                	j	80000e64 <strncmp+0x32>
  if(n == 0)
    80000e58:	ca09                	beqz	a2,80000e6a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e5a:	00054503          	lbu	a0,0(a0)
    80000e5e:	0005c783          	lbu	a5,0(a1)
    80000e62:	9d1d                	subw	a0,a0,a5
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret
    return 0;
    80000e6a:	4501                	li	a0,0
    80000e6c:	bfe5                	j	80000e64 <strncmp+0x32>

0000000080000e6e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e6e:	1141                	addi	sp,sp,-16
    80000e70:	e422                	sd	s0,8(sp)
    80000e72:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e74:	872a                	mv	a4,a0
    80000e76:	8832                	mv	a6,a2
    80000e78:	367d                	addiw	a2,a2,-1
    80000e7a:	01005963          	blez	a6,80000e8c <strncpy+0x1e>
    80000e7e:	0705                	addi	a4,a4,1
    80000e80:	0005c783          	lbu	a5,0(a1)
    80000e84:	fef70fa3          	sb	a5,-1(a4)
    80000e88:	0585                	addi	a1,a1,1
    80000e8a:	f7f5                	bnez	a5,80000e76 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e8c:	00c05d63          	blez	a2,80000ea6 <strncpy+0x38>
    80000e90:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e92:	0685                	addi	a3,a3,1
    80000e94:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e98:	fff6c793          	not	a5,a3
    80000e9c:	9fb9                	addw	a5,a5,a4
    80000e9e:	010787bb          	addw	a5,a5,a6
    80000ea2:	fef048e3          	bgtz	a5,80000e92 <strncpy+0x24>
  return os;
}
    80000ea6:	6422                	ld	s0,8(sp)
    80000ea8:	0141                	addi	sp,sp,16
    80000eaa:	8082                	ret

0000000080000eac <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000eac:	1141                	addi	sp,sp,-16
    80000eae:	e422                	sd	s0,8(sp)
    80000eb0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eb2:	02c05363          	blez	a2,80000ed8 <safestrcpy+0x2c>
    80000eb6:	fff6069b          	addiw	a3,a2,-1
    80000eba:	1682                	slli	a3,a3,0x20
    80000ebc:	9281                	srli	a3,a3,0x20
    80000ebe:	96ae                	add	a3,a3,a1
    80000ec0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ec2:	00d58963          	beq	a1,a3,80000ed4 <safestrcpy+0x28>
    80000ec6:	0585                	addi	a1,a1,1
    80000ec8:	0785                	addi	a5,a5,1
    80000eca:	fff5c703          	lbu	a4,-1(a1)
    80000ece:	fee78fa3          	sb	a4,-1(a5)
    80000ed2:	fb65                	bnez	a4,80000ec2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ed4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ed8:	6422                	ld	s0,8(sp)
    80000eda:	0141                	addi	sp,sp,16
    80000edc:	8082                	ret

0000000080000ede <strlen>:

int
strlen(const char *s)
{
    80000ede:	1141                	addi	sp,sp,-16
    80000ee0:	e422                	sd	s0,8(sp)
    80000ee2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ee4:	00054783          	lbu	a5,0(a0)
    80000ee8:	cf91                	beqz	a5,80000f04 <strlen+0x26>
    80000eea:	0505                	addi	a0,a0,1
    80000eec:	87aa                	mv	a5,a0
    80000eee:	4685                	li	a3,1
    80000ef0:	9e89                	subw	a3,a3,a0
    80000ef2:	00f6853b          	addw	a0,a3,a5
    80000ef6:	0785                	addi	a5,a5,1
    80000ef8:	fff7c703          	lbu	a4,-1(a5)
    80000efc:	fb7d                	bnez	a4,80000ef2 <strlen+0x14>
    ;
  return n;
}
    80000efe:	6422                	ld	s0,8(sp)
    80000f00:	0141                	addi	sp,sp,16
    80000f02:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f04:	4501                	li	a0,0
    80000f06:	bfe5                	j	80000efe <strlen+0x20>

0000000080000f08 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f08:	1141                	addi	sp,sp,-16
    80000f0a:	e406                	sd	ra,8(sp)
    80000f0c:	e022                	sd	s0,0(sp)
    80000f0e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f10:	00001097          	auipc	ra,0x1
    80000f14:	aec080e7          	jalr	-1300(ra) # 800019fc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f18:	00008717          	auipc	a4,0x8
    80000f1c:	0f470713          	addi	a4,a4,244 # 8000900c <started>
  if(cpuid() == 0){
    80000f20:	c139                	beqz	a0,80000f66 <main+0x5e>
    while(started == 0)
    80000f22:	431c                	lw	a5,0(a4)
    80000f24:	2781                	sext.w	a5,a5
    80000f26:	dff5                	beqz	a5,80000f22 <main+0x1a>
      ;
    __sync_synchronize();
    80000f28:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f2c:	00001097          	auipc	ra,0x1
    80000f30:	ad0080e7          	jalr	-1328(ra) # 800019fc <cpuid>
    80000f34:	85aa                	mv	a1,a0
    80000f36:	00007517          	auipc	a0,0x7
    80000f3a:	18250513          	addi	a0,a0,386 # 800080b8 <digits+0x78>
    80000f3e:	fffff097          	auipc	ra,0xfffff
    80000f42:	654080e7          	jalr	1620(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	0d8080e7          	jalr	216(ra) # 8000101e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f4e:	00001097          	auipc	ra,0x1
    80000f52:	7d0080e7          	jalr	2000(ra) # 8000271e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f56:	00005097          	auipc	ra,0x5
    80000f5a:	dea080e7          	jalr	-534(ra) # 80005d40 <plicinithart>
  }

  scheduler();        
    80000f5e:	00001097          	auipc	ra,0x1
    80000f62:	006080e7          	jalr	6(ra) # 80001f64 <scheduler>
    consoleinit();
    80000f66:	fffff097          	auipc	ra,0xfffff
    80000f6a:	4f4080e7          	jalr	1268(ra) # 8000045a <consoleinit>
    printfinit();
    80000f6e:	00000097          	auipc	ra,0x0
    80000f72:	80a080e7          	jalr	-2038(ra) # 80000778 <printfinit>
    printf("\n");
    80000f76:	00007517          	auipc	a0,0x7
    80000f7a:	15250513          	addi	a0,a0,338 # 800080c8 <digits+0x88>
    80000f7e:	fffff097          	auipc	ra,0xfffff
    80000f82:	614080e7          	jalr	1556(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f86:	00007517          	auipc	a0,0x7
    80000f8a:	11a50513          	addi	a0,a0,282 # 800080a0 <digits+0x60>
    80000f8e:	fffff097          	auipc	ra,0xfffff
    80000f92:	604080e7          	jalr	1540(ra) # 80000592 <printf>
    printf("\n");
    80000f96:	00007517          	auipc	a0,0x7
    80000f9a:	13250513          	addi	a0,a0,306 # 800080c8 <digits+0x88>
    80000f9e:	fffff097          	auipc	ra,0xfffff
    80000fa2:	5f4080e7          	jalr	1524(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000fa6:	00000097          	auipc	ra,0x0
    80000faa:	b3e080e7          	jalr	-1218(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000fae:	00000097          	auipc	ra,0x0
    80000fb2:	2a0080e7          	jalr	672(ra) # 8000124e <kvminit>
    kvminithart();   // turn on paging
    80000fb6:	00000097          	auipc	ra,0x0
    80000fba:	068080e7          	jalr	104(ra) # 8000101e <kvminithart>
    procinit();      // process table
    80000fbe:	00001097          	auipc	ra,0x1
    80000fc2:	96e080e7          	jalr	-1682(ra) # 8000192c <procinit>
    trapinit();      // trap vectors
    80000fc6:	00001097          	auipc	ra,0x1
    80000fca:	730080e7          	jalr	1840(ra) # 800026f6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fce:	00001097          	auipc	ra,0x1
    80000fd2:	750080e7          	jalr	1872(ra) # 8000271e <trapinithart>
    plicinit();      // set up interrupt controller
    80000fd6:	00005097          	auipc	ra,0x5
    80000fda:	d54080e7          	jalr	-684(ra) # 80005d2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	d62080e7          	jalr	-670(ra) # 80005d40 <plicinithart>
    binit();         // buffer cache
    80000fe6:	00002097          	auipc	ra,0x2
    80000fea:	f02080e7          	jalr	-254(ra) # 80002ee8 <binit>
    iinit();         // inode cache
    80000fee:	00002097          	auipc	ra,0x2
    80000ff2:	592080e7          	jalr	1426(ra) # 80003580 <iinit>
    fileinit();      // file table
    80000ff6:	00003097          	auipc	ra,0x3
    80000ffa:	52c080e7          	jalr	1324(ra) # 80004522 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ffe:	00005097          	auipc	ra,0x5
    80001002:	e4a080e7          	jalr	-438(ra) # 80005e48 <virtio_disk_init>
    userinit();      // first user process
    80001006:	00001097          	auipc	ra,0x1
    8000100a:	cec080e7          	jalr	-788(ra) # 80001cf2 <userinit>
    __sync_synchronize();
    8000100e:	0ff0000f          	fence
    started = 1;
    80001012:	4785                	li	a5,1
    80001014:	00008717          	auipc	a4,0x8
    80001018:	fef72c23          	sw	a5,-8(a4) # 8000900c <started>
    8000101c:	b789                	j	80000f5e <main+0x56>

000000008000101e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000101e:	1141                	addi	sp,sp,-16
    80001020:	e422                	sd	s0,8(sp)
    80001022:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001024:	00008797          	auipc	a5,0x8
    80001028:	fec7b783          	ld	a5,-20(a5) # 80009010 <kernel_pagetable>
    8000102c:	83b1                	srli	a5,a5,0xc
    8000102e:	577d                	li	a4,-1
    80001030:	177e                	slli	a4,a4,0x3f
    80001032:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001034:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001038:	12000073          	sfence.vma
  sfence_vma();
}
    8000103c:	6422                	ld	s0,8(sp)
    8000103e:	0141                	addi	sp,sp,16
    80001040:	8082                	ret

0000000080001042 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001042:	7139                	addi	sp,sp,-64
    80001044:	fc06                	sd	ra,56(sp)
    80001046:	f822                	sd	s0,48(sp)
    80001048:	f426                	sd	s1,40(sp)
    8000104a:	f04a                	sd	s2,32(sp)
    8000104c:	ec4e                	sd	s3,24(sp)
    8000104e:	e852                	sd	s4,16(sp)
    80001050:	e456                	sd	s5,8(sp)
    80001052:	e05a                	sd	s6,0(sp)
    80001054:	0080                	addi	s0,sp,64
    80001056:	84aa                	mv	s1,a0
    80001058:	89ae                	mv	s3,a1
    8000105a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001062:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001064:	04b7f263          	bgeu	a5,a1,800010a8 <walk+0x66>
    panic("walk");
    80001068:	00007517          	auipc	a0,0x7
    8000106c:	06850513          	addi	a0,a0,104 # 800080d0 <digits+0x90>
    80001070:	fffff097          	auipc	ra,0xfffff
    80001074:	4d8080e7          	jalr	1240(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001078:	060a8663          	beqz	s5,800010e4 <walk+0xa2>
    8000107c:	00000097          	auipc	ra,0x0
    80001080:	aa4080e7          	jalr	-1372(ra) # 80000b20 <kalloc>
    80001084:	84aa                	mv	s1,a0
    80001086:	c529                	beqz	a0,800010d0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001088:	6605                	lui	a2,0x1
    8000108a:	4581                	li	a1,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	cca080e7          	jalr	-822(ra) # 80000d56 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001094:	00c4d793          	srli	a5,s1,0xc
    80001098:	07aa                	slli	a5,a5,0xa
    8000109a:	0017e793          	ori	a5,a5,1
    8000109e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010a2:	3a5d                	addiw	s4,s4,-9
    800010a4:	036a0063          	beq	s4,s6,800010c4 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010a8:	0149d933          	srl	s2,s3,s4
    800010ac:	1ff97913          	andi	s2,s2,511
    800010b0:	090e                	slli	s2,s2,0x3
    800010b2:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010b4:	00093483          	ld	s1,0(s2)
    800010b8:	0014f793          	andi	a5,s1,1
    800010bc:	dfd5                	beqz	a5,80001078 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010be:	80a9                	srli	s1,s1,0xa
    800010c0:	04b2                	slli	s1,s1,0xc
    800010c2:	b7c5                	j	800010a2 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010c4:	00c9d513          	srli	a0,s3,0xc
    800010c8:	1ff57513          	andi	a0,a0,511
    800010cc:	050e                	slli	a0,a0,0x3
    800010ce:	9526                	add	a0,a0,s1
}
    800010d0:	70e2                	ld	ra,56(sp)
    800010d2:	7442                	ld	s0,48(sp)
    800010d4:	74a2                	ld	s1,40(sp)
    800010d6:	7902                	ld	s2,32(sp)
    800010d8:	69e2                	ld	s3,24(sp)
    800010da:	6a42                	ld	s4,16(sp)
    800010dc:	6aa2                	ld	s5,8(sp)
    800010de:	6b02                	ld	s6,0(sp)
    800010e0:	6121                	addi	sp,sp,64
    800010e2:	8082                	ret
        return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7ed                	j	800010d0 <walk+0x8e>

00000000800010e8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010e8:	57fd                	li	a5,-1
    800010ea:	83e9                	srli	a5,a5,0x1a
    800010ec:	00b7f463          	bgeu	a5,a1,800010f4 <walkaddr+0xc>
    return 0;
    800010f0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010f2:	8082                	ret
{
    800010f4:	1141                	addi	sp,sp,-16
    800010f6:	e406                	sd	ra,8(sp)
    800010f8:	e022                	sd	s0,0(sp)
    800010fa:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010fc:	4601                	li	a2,0
    800010fe:	00000097          	auipc	ra,0x0
    80001102:	f44080e7          	jalr	-188(ra) # 80001042 <walk>
  if(pte == 0)
    80001106:	c105                	beqz	a0,80001126 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001108:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000110a:	0117f693          	andi	a3,a5,17
    8000110e:	4745                	li	a4,17
    return 0;
    80001110:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001112:	00e68663          	beq	a3,a4,8000111e <walkaddr+0x36>
}
    80001116:	60a2                	ld	ra,8(sp)
    80001118:	6402                	ld	s0,0(sp)
    8000111a:	0141                	addi	sp,sp,16
    8000111c:	8082                	ret
  pa = PTE2PA(*pte);
    8000111e:	00a7d513          	srli	a0,a5,0xa
    80001122:	0532                	slli	a0,a0,0xc
  return pa;
    80001124:	bfcd                	j	80001116 <walkaddr+0x2e>
    return 0;
    80001126:	4501                	li	a0,0
    80001128:	b7fd                	j	80001116 <walkaddr+0x2e>

000000008000112a <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000112a:	1101                	addi	sp,sp,-32
    8000112c:	ec06                	sd	ra,24(sp)
    8000112e:	e822                	sd	s0,16(sp)
    80001130:	e426                	sd	s1,8(sp)
    80001132:	1000                	addi	s0,sp,32
    80001134:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001136:	1552                	slli	a0,a0,0x34
    80001138:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    8000113c:	4601                	li	a2,0
    8000113e:	00008517          	auipc	a0,0x8
    80001142:	ed253503          	ld	a0,-302(a0) # 80009010 <kernel_pagetable>
    80001146:	00000097          	auipc	ra,0x0
    8000114a:	efc080e7          	jalr	-260(ra) # 80001042 <walk>
  if(pte == 0)
    8000114e:	cd09                	beqz	a0,80001168 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001150:	6108                	ld	a0,0(a0)
    80001152:	00157793          	andi	a5,a0,1
    80001156:	c38d                	beqz	a5,80001178 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001158:	8129                	srli	a0,a0,0xa
    8000115a:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    8000115c:	9526                	add	a0,a0,s1
    8000115e:	60e2                	ld	ra,24(sp)
    80001160:	6442                	ld	s0,16(sp)
    80001162:	64a2                	ld	s1,8(sp)
    80001164:	6105                	addi	sp,sp,32
    80001166:	8082                	ret
    panic("kvmpa");
    80001168:	00007517          	auipc	a0,0x7
    8000116c:	f7050513          	addi	a0,a0,-144 # 800080d8 <digits+0x98>
    80001170:	fffff097          	auipc	ra,0xfffff
    80001174:	3d8080e7          	jalr	984(ra) # 80000548 <panic>
    panic("kvmpa");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f6050513          	addi	a0,a0,-160 # 800080d8 <digits+0x98>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3c8080e7          	jalr	968(ra) # 80000548 <panic>

0000000080001188 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001188:	715d                	addi	sp,sp,-80
    8000118a:	e486                	sd	ra,72(sp)
    8000118c:	e0a2                	sd	s0,64(sp)
    8000118e:	fc26                	sd	s1,56(sp)
    80001190:	f84a                	sd	s2,48(sp)
    80001192:	f44e                	sd	s3,40(sp)
    80001194:	f052                	sd	s4,32(sp)
    80001196:	ec56                	sd	s5,24(sp)
    80001198:	e85a                	sd	s6,16(sp)
    8000119a:	e45e                	sd	s7,8(sp)
    8000119c:	0880                	addi	s0,sp,80
    8000119e:	8aaa                	mv	s5,a0
    800011a0:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011a2:	777d                	lui	a4,0xfffff
    800011a4:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011a8:	167d                	addi	a2,a2,-1
    800011aa:	00b609b3          	add	s3,a2,a1
    800011ae:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011b2:	893e                	mv	s2,a5
    800011b4:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011b8:	6b85                	lui	s7,0x1
    800011ba:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011be:	4605                	li	a2,1
    800011c0:	85ca                	mv	a1,s2
    800011c2:	8556                	mv	a0,s5
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	e7e080e7          	jalr	-386(ra) # 80001042 <walk>
    800011cc:	c51d                	beqz	a0,800011fa <mappages+0x72>
    if(*pte & PTE_V)
    800011ce:	611c                	ld	a5,0(a0)
    800011d0:	8b85                	andi	a5,a5,1
    800011d2:	ef81                	bnez	a5,800011ea <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011d4:	80b1                	srli	s1,s1,0xc
    800011d6:	04aa                	slli	s1,s1,0xa
    800011d8:	0164e4b3          	or	s1,s1,s6
    800011dc:	0014e493          	ori	s1,s1,1
    800011e0:	e104                	sd	s1,0(a0)
    if(a == last)
    800011e2:	03390863          	beq	s2,s3,80001212 <mappages+0x8a>
    a += PGSIZE;
    800011e6:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011e8:	bfc9                	j	800011ba <mappages+0x32>
      panic("remap");
    800011ea:	00007517          	auipc	a0,0x7
    800011ee:	ef650513          	addi	a0,a0,-266 # 800080e0 <digits+0xa0>
    800011f2:	fffff097          	auipc	ra,0xfffff
    800011f6:	356080e7          	jalr	854(ra) # 80000548 <panic>
      return -1;
    800011fa:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011fc:	60a6                	ld	ra,72(sp)
    800011fe:	6406                	ld	s0,64(sp)
    80001200:	74e2                	ld	s1,56(sp)
    80001202:	7942                	ld	s2,48(sp)
    80001204:	79a2                	ld	s3,40(sp)
    80001206:	7a02                	ld	s4,32(sp)
    80001208:	6ae2                	ld	s5,24(sp)
    8000120a:	6b42                	ld	s6,16(sp)
    8000120c:	6ba2                	ld	s7,8(sp)
    8000120e:	6161                	addi	sp,sp,80
    80001210:	8082                	ret
  return 0;
    80001212:	4501                	li	a0,0
    80001214:	b7e5                	j	800011fc <mappages+0x74>

0000000080001216 <kvmmap>:
{
    80001216:	1141                	addi	sp,sp,-16
    80001218:	e406                	sd	ra,8(sp)
    8000121a:	e022                	sd	s0,0(sp)
    8000121c:	0800                	addi	s0,sp,16
    8000121e:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001220:	86ae                	mv	a3,a1
    80001222:	85aa                	mv	a1,a0
    80001224:	00008517          	auipc	a0,0x8
    80001228:	dec53503          	ld	a0,-532(a0) # 80009010 <kernel_pagetable>
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f5c080e7          	jalr	-164(ra) # 80001188 <mappages>
    80001234:	e509                	bnez	a0,8000123e <kvmmap+0x28>
}
    80001236:	60a2                	ld	ra,8(sp)
    80001238:	6402                	ld	s0,0(sp)
    8000123a:	0141                	addi	sp,sp,16
    8000123c:	8082                	ret
    panic("kvmmap");
    8000123e:	00007517          	auipc	a0,0x7
    80001242:	eaa50513          	addi	a0,a0,-342 # 800080e8 <digits+0xa8>
    80001246:	fffff097          	auipc	ra,0xfffff
    8000124a:	302080e7          	jalr	770(ra) # 80000548 <panic>

000000008000124e <kvminit>:
{
    8000124e:	1101                	addi	sp,sp,-32
    80001250:	ec06                	sd	ra,24(sp)
    80001252:	e822                	sd	s0,16(sp)
    80001254:	e426                	sd	s1,8(sp)
    80001256:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001258:	00000097          	auipc	ra,0x0
    8000125c:	8c8080e7          	jalr	-1848(ra) # 80000b20 <kalloc>
    80001260:	00008797          	auipc	a5,0x8
    80001264:	daa7b823          	sd	a0,-592(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001268:	6605                	lui	a2,0x1
    8000126a:	4581                	li	a1,0
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	aea080e7          	jalr	-1302(ra) # 80000d56 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001274:	4699                	li	a3,6
    80001276:	6605                	lui	a2,0x1
    80001278:	100005b7          	lui	a1,0x10000
    8000127c:	10000537          	lui	a0,0x10000
    80001280:	00000097          	auipc	ra,0x0
    80001284:	f96080e7          	jalr	-106(ra) # 80001216 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001288:	4699                	li	a3,6
    8000128a:	6605                	lui	a2,0x1
    8000128c:	100015b7          	lui	a1,0x10001
    80001290:	10001537          	lui	a0,0x10001
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f82080e7          	jalr	-126(ra) # 80001216 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000129c:	4699                	li	a3,6
    8000129e:	6641                	lui	a2,0x10
    800012a0:	020005b7          	lui	a1,0x2000
    800012a4:	02000537          	lui	a0,0x2000
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f6e080e7          	jalr	-146(ra) # 80001216 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012b0:	4699                	li	a3,6
    800012b2:	00400637          	lui	a2,0x400
    800012b6:	0c0005b7          	lui	a1,0xc000
    800012ba:	0c000537          	lui	a0,0xc000
    800012be:	00000097          	auipc	ra,0x0
    800012c2:	f58080e7          	jalr	-168(ra) # 80001216 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012c6:	00007497          	auipc	s1,0x7
    800012ca:	d3a48493          	addi	s1,s1,-710 # 80008000 <etext>
    800012ce:	46a9                	li	a3,10
    800012d0:	80007617          	auipc	a2,0x80007
    800012d4:	d3060613          	addi	a2,a2,-720 # 8000 <_entry-0x7fff8000>
    800012d8:	4585                	li	a1,1
    800012da:	05fe                	slli	a1,a1,0x1f
    800012dc:	852e                	mv	a0,a1
    800012de:	00000097          	auipc	ra,0x0
    800012e2:	f38080e7          	jalr	-200(ra) # 80001216 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012e6:	4699                	li	a3,6
    800012e8:	4645                	li	a2,17
    800012ea:	066e                	slli	a2,a2,0x1b
    800012ec:	8e05                	sub	a2,a2,s1
    800012ee:	85a6                	mv	a1,s1
    800012f0:	8526                	mv	a0,s1
    800012f2:	00000097          	auipc	ra,0x0
    800012f6:	f24080e7          	jalr	-220(ra) # 80001216 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012fa:	46a9                	li	a3,10
    800012fc:	6605                	lui	a2,0x1
    800012fe:	00006597          	auipc	a1,0x6
    80001302:	d0258593          	addi	a1,a1,-766 # 80007000 <_trampoline>
    80001306:	04000537          	lui	a0,0x4000
    8000130a:	157d                	addi	a0,a0,-1
    8000130c:	0532                	slli	a0,a0,0xc
    8000130e:	00000097          	auipc	ra,0x0
    80001312:	f08080e7          	jalr	-248(ra) # 80001216 <kvmmap>
}
    80001316:	60e2                	ld	ra,24(sp)
    80001318:	6442                	ld	s0,16(sp)
    8000131a:	64a2                	ld	s1,8(sp)
    8000131c:	6105                	addi	sp,sp,32
    8000131e:	8082                	ret

0000000080001320 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001320:	715d                	addi	sp,sp,-80
    80001322:	e486                	sd	ra,72(sp)
    80001324:	e0a2                	sd	s0,64(sp)
    80001326:	fc26                	sd	s1,56(sp)
    80001328:	f84a                	sd	s2,48(sp)
    8000132a:	f44e                	sd	s3,40(sp)
    8000132c:	f052                	sd	s4,32(sp)
    8000132e:	ec56                	sd	s5,24(sp)
    80001330:	e85a                	sd	s6,16(sp)
    80001332:	e45e                	sd	s7,8(sp)
    80001334:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001336:	03459793          	slli	a5,a1,0x34
    8000133a:	e795                	bnez	a5,80001366 <uvmunmap+0x46>
    8000133c:	8a2a                	mv	s4,a0
    8000133e:	892e                	mv	s2,a1
    80001340:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001342:	0632                	slli	a2,a2,0xc
    80001344:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001348:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134a:	6b05                	lui	s6,0x1
    8000134c:	0735e863          	bltu	a1,s3,800013bc <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001350:	60a6                	ld	ra,72(sp)
    80001352:	6406                	ld	s0,64(sp)
    80001354:	74e2                	ld	s1,56(sp)
    80001356:	7942                	ld	s2,48(sp)
    80001358:	79a2                	ld	s3,40(sp)
    8000135a:	7a02                	ld	s4,32(sp)
    8000135c:	6ae2                	ld	s5,24(sp)
    8000135e:	6b42                	ld	s6,16(sp)
    80001360:	6ba2                	ld	s7,8(sp)
    80001362:	6161                	addi	sp,sp,80
    80001364:	8082                	ret
    panic("uvmunmap: not aligned");
    80001366:	00007517          	auipc	a0,0x7
    8000136a:	d8a50513          	addi	a0,a0,-630 # 800080f0 <digits+0xb0>
    8000136e:	fffff097          	auipc	ra,0xfffff
    80001372:	1da080e7          	jalr	474(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001376:	00007517          	auipc	a0,0x7
    8000137a:	d9250513          	addi	a0,a0,-622 # 80008108 <digits+0xc8>
    8000137e:	fffff097          	auipc	ra,0xfffff
    80001382:	1ca080e7          	jalr	458(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    80001386:	00007517          	auipc	a0,0x7
    8000138a:	d9250513          	addi	a0,a0,-622 # 80008118 <digits+0xd8>
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	1ba080e7          	jalr	442(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001396:	00007517          	auipc	a0,0x7
    8000139a:	d9a50513          	addi	a0,a0,-614 # 80008130 <digits+0xf0>
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	1aa080e7          	jalr	426(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800013a6:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013a8:	0532                	slli	a0,a0,0xc
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	67a080e7          	jalr	1658(ra) # 80000a24 <kfree>
    *pte = 0;
    800013b2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013b6:	995a                	add	s2,s2,s6
    800013b8:	f9397ce3          	bgeu	s2,s3,80001350 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013bc:	4601                	li	a2,0
    800013be:	85ca                	mv	a1,s2
    800013c0:	8552                	mv	a0,s4
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	c80080e7          	jalr	-896(ra) # 80001042 <walk>
    800013ca:	84aa                	mv	s1,a0
    800013cc:	d54d                	beqz	a0,80001376 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013ce:	6108                	ld	a0,0(a0)
    800013d0:	00157793          	andi	a5,a0,1
    800013d4:	dbcd                	beqz	a5,80001386 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013d6:	3ff57793          	andi	a5,a0,1023
    800013da:	fb778ee3          	beq	a5,s7,80001396 <uvmunmap+0x76>
    if(do_free){
    800013de:	fc0a8ae3          	beqz	s5,800013b2 <uvmunmap+0x92>
    800013e2:	b7d1                	j	800013a6 <uvmunmap+0x86>

00000000800013e4 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013ee:	fffff097          	auipc	ra,0xfffff
    800013f2:	732080e7          	jalr	1842(ra) # 80000b20 <kalloc>
    800013f6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013f8:	c519                	beqz	a0,80001406 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013fa:	6605                	lui	a2,0x1
    800013fc:	4581                	li	a1,0
    800013fe:	00000097          	auipc	ra,0x0
    80001402:	958080e7          	jalr	-1704(ra) # 80000d56 <memset>
  return pagetable;
}
    80001406:	8526                	mv	a0,s1
    80001408:	60e2                	ld	ra,24(sp)
    8000140a:	6442                	ld	s0,16(sp)
    8000140c:	64a2                	ld	s1,8(sp)
    8000140e:	6105                	addi	sp,sp,32
    80001410:	8082                	ret

0000000080001412 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001412:	7179                	addi	sp,sp,-48
    80001414:	f406                	sd	ra,40(sp)
    80001416:	f022                	sd	s0,32(sp)
    80001418:	ec26                	sd	s1,24(sp)
    8000141a:	e84a                	sd	s2,16(sp)
    8000141c:	e44e                	sd	s3,8(sp)
    8000141e:	e052                	sd	s4,0(sp)
    80001420:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001422:	6785                	lui	a5,0x1
    80001424:	04f67863          	bgeu	a2,a5,80001474 <uvminit+0x62>
    80001428:	8a2a                	mv	s4,a0
    8000142a:	89ae                	mv	s3,a1
    8000142c:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000142e:	fffff097          	auipc	ra,0xfffff
    80001432:	6f2080e7          	jalr	1778(ra) # 80000b20 <kalloc>
    80001436:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001438:	6605                	lui	a2,0x1
    8000143a:	4581                	li	a1,0
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	91a080e7          	jalr	-1766(ra) # 80000d56 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001444:	4779                	li	a4,30
    80001446:	86ca                	mv	a3,s2
    80001448:	6605                	lui	a2,0x1
    8000144a:	4581                	li	a1,0
    8000144c:	8552                	mv	a0,s4
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	d3a080e7          	jalr	-710(ra) # 80001188 <mappages>
  memmove(mem, src, sz);
    80001456:	8626                	mv	a2,s1
    80001458:	85ce                	mv	a1,s3
    8000145a:	854a                	mv	a0,s2
    8000145c:	00000097          	auipc	ra,0x0
    80001460:	95a080e7          	jalr	-1702(ra) # 80000db6 <memmove>
}
    80001464:	70a2                	ld	ra,40(sp)
    80001466:	7402                	ld	s0,32(sp)
    80001468:	64e2                	ld	s1,24(sp)
    8000146a:	6942                	ld	s2,16(sp)
    8000146c:	69a2                	ld	s3,8(sp)
    8000146e:	6a02                	ld	s4,0(sp)
    80001470:	6145                	addi	sp,sp,48
    80001472:	8082                	ret
    panic("inituvm: more than a page");
    80001474:	00007517          	auipc	a0,0x7
    80001478:	cd450513          	addi	a0,a0,-812 # 80008148 <digits+0x108>
    8000147c:	fffff097          	auipc	ra,0xfffff
    80001480:	0cc080e7          	jalr	204(ra) # 80000548 <panic>

0000000080001484 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001484:	1101                	addi	sp,sp,-32
    80001486:	ec06                	sd	ra,24(sp)
    80001488:	e822                	sd	s0,16(sp)
    8000148a:	e426                	sd	s1,8(sp)
    8000148c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000148e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001490:	00b67d63          	bgeu	a2,a1,800014aa <uvmdealloc+0x26>
    80001494:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001496:	6785                	lui	a5,0x1
    80001498:	17fd                	addi	a5,a5,-1
    8000149a:	00f60733          	add	a4,a2,a5
    8000149e:	767d                	lui	a2,0xfffff
    800014a0:	8f71                	and	a4,a4,a2
    800014a2:	97ae                	add	a5,a5,a1
    800014a4:	8ff1                	and	a5,a5,a2
    800014a6:	00f76863          	bltu	a4,a5,800014b6 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014aa:	8526                	mv	a0,s1
    800014ac:	60e2                	ld	ra,24(sp)
    800014ae:	6442                	ld	s0,16(sp)
    800014b0:	64a2                	ld	s1,8(sp)
    800014b2:	6105                	addi	sp,sp,32
    800014b4:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014b6:	8f99                	sub	a5,a5,a4
    800014b8:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014ba:	4685                	li	a3,1
    800014bc:	0007861b          	sext.w	a2,a5
    800014c0:	85ba                	mv	a1,a4
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	e5e080e7          	jalr	-418(ra) # 80001320 <uvmunmap>
    800014ca:	b7c5                	j	800014aa <uvmdealloc+0x26>

00000000800014cc <uvmalloc>:
  if(newsz < oldsz)
    800014cc:	0ab66163          	bltu	a2,a1,8000156e <uvmalloc+0xa2>
{
    800014d0:	7139                	addi	sp,sp,-64
    800014d2:	fc06                	sd	ra,56(sp)
    800014d4:	f822                	sd	s0,48(sp)
    800014d6:	f426                	sd	s1,40(sp)
    800014d8:	f04a                	sd	s2,32(sp)
    800014da:	ec4e                	sd	s3,24(sp)
    800014dc:	e852                	sd	s4,16(sp)
    800014de:	e456                	sd	s5,8(sp)
    800014e0:	0080                	addi	s0,sp,64
    800014e2:	8aaa                	mv	s5,a0
    800014e4:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014e6:	6985                	lui	s3,0x1
    800014e8:	19fd                	addi	s3,s3,-1
    800014ea:	95ce                	add	a1,a1,s3
    800014ec:	79fd                	lui	s3,0xfffff
    800014ee:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014f2:	08c9f063          	bgeu	s3,a2,80001572 <uvmalloc+0xa6>
    800014f6:	894e                	mv	s2,s3
    mem = kalloc();
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	628080e7          	jalr	1576(ra) # 80000b20 <kalloc>
    80001500:	84aa                	mv	s1,a0
    if(mem == 0){
    80001502:	c51d                	beqz	a0,80001530 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001504:	6605                	lui	a2,0x1
    80001506:	4581                	li	a1,0
    80001508:	00000097          	auipc	ra,0x0
    8000150c:	84e080e7          	jalr	-1970(ra) # 80000d56 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001510:	4779                	li	a4,30
    80001512:	86a6                	mv	a3,s1
    80001514:	6605                	lui	a2,0x1
    80001516:	85ca                	mv	a1,s2
    80001518:	8556                	mv	a0,s5
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	c6e080e7          	jalr	-914(ra) # 80001188 <mappages>
    80001522:	e905                	bnez	a0,80001552 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001524:	6785                	lui	a5,0x1
    80001526:	993e                	add	s2,s2,a5
    80001528:	fd4968e3          	bltu	s2,s4,800014f8 <uvmalloc+0x2c>
  return newsz;
    8000152c:	8552                	mv	a0,s4
    8000152e:	a809                	j	80001540 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001530:	864e                	mv	a2,s3
    80001532:	85ca                	mv	a1,s2
    80001534:	8556                	mv	a0,s5
    80001536:	00000097          	auipc	ra,0x0
    8000153a:	f4e080e7          	jalr	-178(ra) # 80001484 <uvmdealloc>
      return 0;
    8000153e:	4501                	li	a0,0
}
    80001540:	70e2                	ld	ra,56(sp)
    80001542:	7442                	ld	s0,48(sp)
    80001544:	74a2                	ld	s1,40(sp)
    80001546:	7902                	ld	s2,32(sp)
    80001548:	69e2                	ld	s3,24(sp)
    8000154a:	6a42                	ld	s4,16(sp)
    8000154c:	6aa2                	ld	s5,8(sp)
    8000154e:	6121                	addi	sp,sp,64
    80001550:	8082                	ret
      kfree(mem);
    80001552:	8526                	mv	a0,s1
    80001554:	fffff097          	auipc	ra,0xfffff
    80001558:	4d0080e7          	jalr	1232(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000155c:	864e                	mv	a2,s3
    8000155e:	85ca                	mv	a1,s2
    80001560:	8556                	mv	a0,s5
    80001562:	00000097          	auipc	ra,0x0
    80001566:	f22080e7          	jalr	-222(ra) # 80001484 <uvmdealloc>
      return 0;
    8000156a:	4501                	li	a0,0
    8000156c:	bfd1                	j	80001540 <uvmalloc+0x74>
    return oldsz;
    8000156e:	852e                	mv	a0,a1
}
    80001570:	8082                	ret
  return newsz;
    80001572:	8532                	mv	a0,a2
    80001574:	b7f1                	j	80001540 <uvmalloc+0x74>

0000000080001576 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001576:	7179                	addi	sp,sp,-48
    80001578:	f406                	sd	ra,40(sp)
    8000157a:	f022                	sd	s0,32(sp)
    8000157c:	ec26                	sd	s1,24(sp)
    8000157e:	e84a                	sd	s2,16(sp)
    80001580:	e44e                	sd	s3,8(sp)
    80001582:	e052                	sd	s4,0(sp)
    80001584:	1800                	addi	s0,sp,48
    80001586:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001588:	84aa                	mv	s1,a0
    8000158a:	6905                	lui	s2,0x1
    8000158c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000158e:	4985                	li	s3,1
    80001590:	a821                	j	800015a8 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001592:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001594:	0532                	slli	a0,a0,0xc
    80001596:	00000097          	auipc	ra,0x0
    8000159a:	fe0080e7          	jalr	-32(ra) # 80001576 <freewalk>
      pagetable[i] = 0;
    8000159e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015a2:	04a1                	addi	s1,s1,8
    800015a4:	03248163          	beq	s1,s2,800015c6 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015a8:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015aa:	00f57793          	andi	a5,a0,15
    800015ae:	ff3782e3          	beq	a5,s3,80001592 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015b2:	8905                	andi	a0,a0,1
    800015b4:	d57d                	beqz	a0,800015a2 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015b6:	00007517          	auipc	a0,0x7
    800015ba:	bb250513          	addi	a0,a0,-1102 # 80008168 <digits+0x128>
    800015be:	fffff097          	auipc	ra,0xfffff
    800015c2:	f8a080e7          	jalr	-118(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800015c6:	8552                	mv	a0,s4
    800015c8:	fffff097          	auipc	ra,0xfffff
    800015cc:	45c080e7          	jalr	1116(ra) # 80000a24 <kfree>
}
    800015d0:	70a2                	ld	ra,40(sp)
    800015d2:	7402                	ld	s0,32(sp)
    800015d4:	64e2                	ld	s1,24(sp)
    800015d6:	6942                	ld	s2,16(sp)
    800015d8:	69a2                	ld	s3,8(sp)
    800015da:	6a02                	ld	s4,0(sp)
    800015dc:	6145                	addi	sp,sp,48
    800015de:	8082                	ret

00000000800015e0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015e0:	1101                	addi	sp,sp,-32
    800015e2:	ec06                	sd	ra,24(sp)
    800015e4:	e822                	sd	s0,16(sp)
    800015e6:	e426                	sd	s1,8(sp)
    800015e8:	1000                	addi	s0,sp,32
    800015ea:	84aa                	mv	s1,a0
  if(sz > 0)
    800015ec:	e999                	bnez	a1,80001602 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015ee:	8526                	mv	a0,s1
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	f86080e7          	jalr	-122(ra) # 80001576 <freewalk>
}
    800015f8:	60e2                	ld	ra,24(sp)
    800015fa:	6442                	ld	s0,16(sp)
    800015fc:	64a2                	ld	s1,8(sp)
    800015fe:	6105                	addi	sp,sp,32
    80001600:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001602:	6605                	lui	a2,0x1
    80001604:	167d                	addi	a2,a2,-1
    80001606:	962e                	add	a2,a2,a1
    80001608:	4685                	li	a3,1
    8000160a:	8231                	srli	a2,a2,0xc
    8000160c:	4581                	li	a1,0
    8000160e:	00000097          	auipc	ra,0x0
    80001612:	d12080e7          	jalr	-750(ra) # 80001320 <uvmunmap>
    80001616:	bfe1                	j	800015ee <uvmfree+0xe>

0000000080001618 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001618:	c679                	beqz	a2,800016e6 <uvmcopy+0xce>
{
    8000161a:	715d                	addi	sp,sp,-80
    8000161c:	e486                	sd	ra,72(sp)
    8000161e:	e0a2                	sd	s0,64(sp)
    80001620:	fc26                	sd	s1,56(sp)
    80001622:	f84a                	sd	s2,48(sp)
    80001624:	f44e                	sd	s3,40(sp)
    80001626:	f052                	sd	s4,32(sp)
    80001628:	ec56                	sd	s5,24(sp)
    8000162a:	e85a                	sd	s6,16(sp)
    8000162c:	e45e                	sd	s7,8(sp)
    8000162e:	0880                	addi	s0,sp,80
    80001630:	8b2a                	mv	s6,a0
    80001632:	8aae                	mv	s5,a1
    80001634:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001636:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001638:	4601                	li	a2,0
    8000163a:	85ce                	mv	a1,s3
    8000163c:	855a                	mv	a0,s6
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	a04080e7          	jalr	-1532(ra) # 80001042 <walk>
    80001646:	c531                	beqz	a0,80001692 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001648:	6118                	ld	a4,0(a0)
    8000164a:	00177793          	andi	a5,a4,1
    8000164e:	cbb1                	beqz	a5,800016a2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001650:	00a75593          	srli	a1,a4,0xa
    80001654:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001658:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000165c:	fffff097          	auipc	ra,0xfffff
    80001660:	4c4080e7          	jalr	1220(ra) # 80000b20 <kalloc>
    80001664:	892a                	mv	s2,a0
    80001666:	c939                	beqz	a0,800016bc <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001668:	6605                	lui	a2,0x1
    8000166a:	85de                	mv	a1,s7
    8000166c:	fffff097          	auipc	ra,0xfffff
    80001670:	74a080e7          	jalr	1866(ra) # 80000db6 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001674:	8726                	mv	a4,s1
    80001676:	86ca                	mv	a3,s2
    80001678:	6605                	lui	a2,0x1
    8000167a:	85ce                	mv	a1,s3
    8000167c:	8556                	mv	a0,s5
    8000167e:	00000097          	auipc	ra,0x0
    80001682:	b0a080e7          	jalr	-1270(ra) # 80001188 <mappages>
    80001686:	e515                	bnez	a0,800016b2 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001688:	6785                	lui	a5,0x1
    8000168a:	99be                	add	s3,s3,a5
    8000168c:	fb49e6e3          	bltu	s3,s4,80001638 <uvmcopy+0x20>
    80001690:	a081                	j	800016d0 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001692:	00007517          	auipc	a0,0x7
    80001696:	ae650513          	addi	a0,a0,-1306 # 80008178 <digits+0x138>
    8000169a:	fffff097          	auipc	ra,0xfffff
    8000169e:	eae080e7          	jalr	-338(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800016a2:	00007517          	auipc	a0,0x7
    800016a6:	af650513          	addi	a0,a0,-1290 # 80008198 <digits+0x158>
    800016aa:	fffff097          	auipc	ra,0xfffff
    800016ae:	e9e080e7          	jalr	-354(ra) # 80000548 <panic>
      kfree(mem);
    800016b2:	854a                	mv	a0,s2
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	370080e7          	jalr	880(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016bc:	4685                	li	a3,1
    800016be:	00c9d613          	srli	a2,s3,0xc
    800016c2:	4581                	li	a1,0
    800016c4:	8556                	mv	a0,s5
    800016c6:	00000097          	auipc	ra,0x0
    800016ca:	c5a080e7          	jalr	-934(ra) # 80001320 <uvmunmap>
  return -1;
    800016ce:	557d                	li	a0,-1
}
    800016d0:	60a6                	ld	ra,72(sp)
    800016d2:	6406                	ld	s0,64(sp)
    800016d4:	74e2                	ld	s1,56(sp)
    800016d6:	7942                	ld	s2,48(sp)
    800016d8:	79a2                	ld	s3,40(sp)
    800016da:	7a02                	ld	s4,32(sp)
    800016dc:	6ae2                	ld	s5,24(sp)
    800016de:	6b42                	ld	s6,16(sp)
    800016e0:	6ba2                	ld	s7,8(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret
  return 0;
    800016e6:	4501                	li	a0,0
}
    800016e8:	8082                	ret

00000000800016ea <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016ea:	1141                	addi	sp,sp,-16
    800016ec:	e406                	sd	ra,8(sp)
    800016ee:	e022                	sd	s0,0(sp)
    800016f0:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016f2:	4601                	li	a2,0
    800016f4:	00000097          	auipc	ra,0x0
    800016f8:	94e080e7          	jalr	-1714(ra) # 80001042 <walk>
  if(pte == 0)
    800016fc:	c901                	beqz	a0,8000170c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016fe:	611c                	ld	a5,0(a0)
    80001700:	9bbd                	andi	a5,a5,-17
    80001702:	e11c                	sd	a5,0(a0)
}
    80001704:	60a2                	ld	ra,8(sp)
    80001706:	6402                	ld	s0,0(sp)
    80001708:	0141                	addi	sp,sp,16
    8000170a:	8082                	ret
    panic("uvmclear");
    8000170c:	00007517          	auipc	a0,0x7
    80001710:	aac50513          	addi	a0,a0,-1364 # 800081b8 <digits+0x178>
    80001714:	fffff097          	auipc	ra,0xfffff
    80001718:	e34080e7          	jalr	-460(ra) # 80000548 <panic>

000000008000171c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000171c:	c6bd                	beqz	a3,8000178a <copyout+0x6e>
{
    8000171e:	715d                	addi	sp,sp,-80
    80001720:	e486                	sd	ra,72(sp)
    80001722:	e0a2                	sd	s0,64(sp)
    80001724:	fc26                	sd	s1,56(sp)
    80001726:	f84a                	sd	s2,48(sp)
    80001728:	f44e                	sd	s3,40(sp)
    8000172a:	f052                	sd	s4,32(sp)
    8000172c:	ec56                	sd	s5,24(sp)
    8000172e:	e85a                	sd	s6,16(sp)
    80001730:	e45e                	sd	s7,8(sp)
    80001732:	e062                	sd	s8,0(sp)
    80001734:	0880                	addi	s0,sp,80
    80001736:	8b2a                	mv	s6,a0
    80001738:	8c2e                	mv	s8,a1
    8000173a:	8a32                	mv	s4,a2
    8000173c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000173e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001740:	6a85                	lui	s5,0x1
    80001742:	a015                	j	80001766 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001744:	9562                	add	a0,a0,s8
    80001746:	0004861b          	sext.w	a2,s1
    8000174a:	85d2                	mv	a1,s4
    8000174c:	41250533          	sub	a0,a0,s2
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	666080e7          	jalr	1638(ra) # 80000db6 <memmove>

    len -= n;
    80001758:	409989b3          	sub	s3,s3,s1
    src += n;
    8000175c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000175e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001762:	02098263          	beqz	s3,80001786 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001766:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000176a:	85ca                	mv	a1,s2
    8000176c:	855a                	mv	a0,s6
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	97a080e7          	jalr	-1670(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001776:	cd01                	beqz	a0,8000178e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001778:	418904b3          	sub	s1,s2,s8
    8000177c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000177e:	fc99f3e3          	bgeu	s3,s1,80001744 <copyout+0x28>
    80001782:	84ce                	mv	s1,s3
    80001784:	b7c1                	j	80001744 <copyout+0x28>
  }
  return 0;
    80001786:	4501                	li	a0,0
    80001788:	a021                	j	80001790 <copyout+0x74>
    8000178a:	4501                	li	a0,0
}
    8000178c:	8082                	ret
      return -1;
    8000178e:	557d                	li	a0,-1
}
    80001790:	60a6                	ld	ra,72(sp)
    80001792:	6406                	ld	s0,64(sp)
    80001794:	74e2                	ld	s1,56(sp)
    80001796:	7942                	ld	s2,48(sp)
    80001798:	79a2                	ld	s3,40(sp)
    8000179a:	7a02                	ld	s4,32(sp)
    8000179c:	6ae2                	ld	s5,24(sp)
    8000179e:	6b42                	ld	s6,16(sp)
    800017a0:	6ba2                	ld	s7,8(sp)
    800017a2:	6c02                	ld	s8,0(sp)
    800017a4:	6161                	addi	sp,sp,80
    800017a6:	8082                	ret

00000000800017a8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017a8:	c6bd                	beqz	a3,80001816 <copyin+0x6e>
{
    800017aa:	715d                	addi	sp,sp,-80
    800017ac:	e486                	sd	ra,72(sp)
    800017ae:	e0a2                	sd	s0,64(sp)
    800017b0:	fc26                	sd	s1,56(sp)
    800017b2:	f84a                	sd	s2,48(sp)
    800017b4:	f44e                	sd	s3,40(sp)
    800017b6:	f052                	sd	s4,32(sp)
    800017b8:	ec56                	sd	s5,24(sp)
    800017ba:	e85a                	sd	s6,16(sp)
    800017bc:	e45e                	sd	s7,8(sp)
    800017be:	e062                	sd	s8,0(sp)
    800017c0:	0880                	addi	s0,sp,80
    800017c2:	8b2a                	mv	s6,a0
    800017c4:	8a2e                	mv	s4,a1
    800017c6:	8c32                	mv	s8,a2
    800017c8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017ca:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017cc:	6a85                	lui	s5,0x1
    800017ce:	a015                	j	800017f2 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017d0:	9562                	add	a0,a0,s8
    800017d2:	0004861b          	sext.w	a2,s1
    800017d6:	412505b3          	sub	a1,a0,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	fffff097          	auipc	ra,0xfffff
    800017e0:	5da080e7          	jalr	1498(ra) # 80000db6 <memmove>

    len -= n;
    800017e4:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017e8:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017ea:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017ee:	02098263          	beqz	s3,80001812 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017f2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017f6:	85ca                	mv	a1,s2
    800017f8:	855a                	mv	a0,s6
    800017fa:	00000097          	auipc	ra,0x0
    800017fe:	8ee080e7          	jalr	-1810(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001802:	cd01                	beqz	a0,8000181a <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001804:	418904b3          	sub	s1,s2,s8
    80001808:	94d6                	add	s1,s1,s5
    if(n > len)
    8000180a:	fc99f3e3          	bgeu	s3,s1,800017d0 <copyin+0x28>
    8000180e:	84ce                	mv	s1,s3
    80001810:	b7c1                	j	800017d0 <copyin+0x28>
  }
  return 0;
    80001812:	4501                	li	a0,0
    80001814:	a021                	j	8000181c <copyin+0x74>
    80001816:	4501                	li	a0,0
}
    80001818:	8082                	ret
      return -1;
    8000181a:	557d                	li	a0,-1
}
    8000181c:	60a6                	ld	ra,72(sp)
    8000181e:	6406                	ld	s0,64(sp)
    80001820:	74e2                	ld	s1,56(sp)
    80001822:	7942                	ld	s2,48(sp)
    80001824:	79a2                	ld	s3,40(sp)
    80001826:	7a02                	ld	s4,32(sp)
    80001828:	6ae2                	ld	s5,24(sp)
    8000182a:	6b42                	ld	s6,16(sp)
    8000182c:	6ba2                	ld	s7,8(sp)
    8000182e:	6c02                	ld	s8,0(sp)
    80001830:	6161                	addi	sp,sp,80
    80001832:	8082                	ret

0000000080001834 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001834:	c6c5                	beqz	a3,800018dc <copyinstr+0xa8>
{
    80001836:	715d                	addi	sp,sp,-80
    80001838:	e486                	sd	ra,72(sp)
    8000183a:	e0a2                	sd	s0,64(sp)
    8000183c:	fc26                	sd	s1,56(sp)
    8000183e:	f84a                	sd	s2,48(sp)
    80001840:	f44e                	sd	s3,40(sp)
    80001842:	f052                	sd	s4,32(sp)
    80001844:	ec56                	sd	s5,24(sp)
    80001846:	e85a                	sd	s6,16(sp)
    80001848:	e45e                	sd	s7,8(sp)
    8000184a:	0880                	addi	s0,sp,80
    8000184c:	8a2a                	mv	s4,a0
    8000184e:	8b2e                	mv	s6,a1
    80001850:	8bb2                	mv	s7,a2
    80001852:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001854:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001856:	6985                	lui	s3,0x1
    80001858:	a035                	j	80001884 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000185a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000185e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001860:	0017b793          	seqz	a5,a5
    80001864:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001868:	60a6                	ld	ra,72(sp)
    8000186a:	6406                	ld	s0,64(sp)
    8000186c:	74e2                	ld	s1,56(sp)
    8000186e:	7942                	ld	s2,48(sp)
    80001870:	79a2                	ld	s3,40(sp)
    80001872:	7a02                	ld	s4,32(sp)
    80001874:	6ae2                	ld	s5,24(sp)
    80001876:	6b42                	ld	s6,16(sp)
    80001878:	6ba2                	ld	s7,8(sp)
    8000187a:	6161                	addi	sp,sp,80
    8000187c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000187e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001882:	c8a9                	beqz	s1,800018d4 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001884:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001888:	85ca                	mv	a1,s2
    8000188a:	8552                	mv	a0,s4
    8000188c:	00000097          	auipc	ra,0x0
    80001890:	85c080e7          	jalr	-1956(ra) # 800010e8 <walkaddr>
    if(pa0 == 0)
    80001894:	c131                	beqz	a0,800018d8 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001896:	41790833          	sub	a6,s2,s7
    8000189a:	984e                	add	a6,a6,s3
    if(n > max)
    8000189c:	0104f363          	bgeu	s1,a6,800018a2 <copyinstr+0x6e>
    800018a0:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018a2:	955e                	add	a0,a0,s7
    800018a4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018a8:	fc080be3          	beqz	a6,8000187e <copyinstr+0x4a>
    800018ac:	985a                	add	a6,a6,s6
    800018ae:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018b0:	41650633          	sub	a2,a0,s6
    800018b4:	14fd                	addi	s1,s1,-1
    800018b6:	9b26                	add	s6,s6,s1
    800018b8:	00f60733          	add	a4,a2,a5
    800018bc:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018c0:	df49                	beqz	a4,8000185a <copyinstr+0x26>
        *dst = *p;
    800018c2:	00e78023          	sb	a4,0(a5)
      --max;
    800018c6:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018ca:	0785                	addi	a5,a5,1
    while(n > 0){
    800018cc:	ff0796e3          	bne	a5,a6,800018b8 <copyinstr+0x84>
      dst++;
    800018d0:	8b42                	mv	s6,a6
    800018d2:	b775                	j	8000187e <copyinstr+0x4a>
    800018d4:	4781                	li	a5,0
    800018d6:	b769                	j	80001860 <copyinstr+0x2c>
      return -1;
    800018d8:	557d                	li	a0,-1
    800018da:	b779                	j	80001868 <copyinstr+0x34>
  int got_null = 0;
    800018dc:	4781                	li	a5,0
  if(got_null){
    800018de:	0017b793          	seqz	a5,a5
    800018e2:	40f00533          	neg	a0,a5
}
    800018e6:	8082                	ret

00000000800018e8 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018e8:	1101                	addi	sp,sp,-32
    800018ea:	ec06                	sd	ra,24(sp)
    800018ec:	e822                	sd	s0,16(sp)
    800018ee:	e426                	sd	s1,8(sp)
    800018f0:	1000                	addi	s0,sp,32
    800018f2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	2ec080e7          	jalr	748(ra) # 80000be0 <holding>
    800018fc:	c909                	beqz	a0,8000190e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018fe:	749c                	ld	a5,40(s1)
    80001900:	00978f63          	beq	a5,s1,8000191e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001904:	60e2                	ld	ra,24(sp)
    80001906:	6442                	ld	s0,16(sp)
    80001908:	64a2                	ld	s1,8(sp)
    8000190a:	6105                	addi	sp,sp,32
    8000190c:	8082                	ret
    panic("wakeup1");
    8000190e:	00007517          	auipc	a0,0x7
    80001912:	8ba50513          	addi	a0,a0,-1862 # 800081c8 <digits+0x188>
    80001916:	fffff097          	auipc	ra,0xfffff
    8000191a:	c32080e7          	jalr	-974(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000191e:	4c98                	lw	a4,24(s1)
    80001920:	4785                	li	a5,1
    80001922:	fef711e3          	bne	a4,a5,80001904 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001926:	4789                	li	a5,2
    80001928:	cc9c                	sw	a5,24(s1)
}
    8000192a:	bfe9                	j	80001904 <wakeup1+0x1c>

000000008000192c <procinit>:
{
    8000192c:	715d                	addi	sp,sp,-80
    8000192e:	e486                	sd	ra,72(sp)
    80001930:	e0a2                	sd	s0,64(sp)
    80001932:	fc26                	sd	s1,56(sp)
    80001934:	f84a                	sd	s2,48(sp)
    80001936:	f44e                	sd	s3,40(sp)
    80001938:	f052                	sd	s4,32(sp)
    8000193a:	ec56                	sd	s5,24(sp)
    8000193c:	e85a                	sd	s6,16(sp)
    8000193e:	e45e                	sd	s7,8(sp)
    80001940:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001942:	00007597          	auipc	a1,0x7
    80001946:	88e58593          	addi	a1,a1,-1906 # 800081d0 <digits+0x190>
    8000194a:	00010517          	auipc	a0,0x10
    8000194e:	00650513          	addi	a0,a0,6 # 80011950 <pid_lock>
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	278080e7          	jalr	632(ra) # 80000bca <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195a:	00010917          	auipc	s2,0x10
    8000195e:	40e90913          	addi	s2,s2,1038 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001962:	00007b97          	auipc	s7,0x7
    80001966:	876b8b93          	addi	s7,s7,-1930 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    8000196a:	8b4a                	mv	s6,s2
    8000196c:	00006a97          	auipc	s5,0x6
    80001970:	694a8a93          	addi	s5,s5,1684 # 80008000 <etext>
    80001974:	040009b7          	lui	s3,0x4000
    80001978:	19fd                	addi	s3,s3,-1
    8000197a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197c:	00016a17          	auipc	s4,0x16
    80001980:	deca0a13          	addi	s4,s4,-532 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001984:	85de                	mv	a1,s7
    80001986:	854a                	mv	a0,s2
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	242080e7          	jalr	578(ra) # 80000bca <initlock>
      char *pa = kalloc();
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	190080e7          	jalr	400(ra) # 80000b20 <kalloc>
    80001998:	85aa                	mv	a1,a0
      if(pa == 0)
    8000199a:	c929                	beqz	a0,800019ec <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    8000199c:	416904b3          	sub	s1,s2,s6
    800019a0:	848d                	srai	s1,s1,0x3
    800019a2:	000ab783          	ld	a5,0(s5)
    800019a6:	02f484b3          	mul	s1,s1,a5
    800019aa:	2485                	addiw	s1,s1,1
    800019ac:	00d4949b          	slliw	s1,s1,0xd
    800019b0:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019b4:	4699                	li	a3,6
    800019b6:	6605                	lui	a2,0x1
    800019b8:	8526                	mv	a0,s1
    800019ba:	00000097          	auipc	ra,0x0
    800019be:	85c080e7          	jalr	-1956(ra) # 80001216 <kvmmap>
      p->kstack = va;
    800019c2:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c6:	16890913          	addi	s2,s2,360
    800019ca:	fb491de3          	bne	s2,s4,80001984 <procinit+0x58>
  kvminithart();
    800019ce:	fffff097          	auipc	ra,0xfffff
    800019d2:	650080e7          	jalr	1616(ra) # 8000101e <kvminithart>
}
    800019d6:	60a6                	ld	ra,72(sp)
    800019d8:	6406                	ld	s0,64(sp)
    800019da:	74e2                	ld	s1,56(sp)
    800019dc:	7942                	ld	s2,48(sp)
    800019de:	79a2                	ld	s3,40(sp)
    800019e0:	7a02                	ld	s4,32(sp)
    800019e2:	6ae2                	ld	s5,24(sp)
    800019e4:	6b42                	ld	s6,16(sp)
    800019e6:	6ba2                	ld	s7,8(sp)
    800019e8:	6161                	addi	sp,sp,80
    800019ea:	8082                	ret
        panic("kalloc");
    800019ec:	00006517          	auipc	a0,0x6
    800019f0:	7f450513          	addi	a0,a0,2036 # 800081e0 <digits+0x1a0>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	b54080e7          	jalr	-1196(ra) # 80000548 <panic>

00000000800019fc <cpuid>:
{
    800019fc:	1141                	addi	sp,sp,-16
    800019fe:	e422                	sd	s0,8(sp)
    80001a00:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a02:	8512                	mv	a0,tp
}
    80001a04:	2501                	sext.w	a0,a0
    80001a06:	6422                	ld	s0,8(sp)
    80001a08:	0141                	addi	sp,sp,16
    80001a0a:	8082                	ret

0000000080001a0c <mycpu>:
mycpu(void) {
    80001a0c:	1141                	addi	sp,sp,-16
    80001a0e:	e422                	sd	s0,8(sp)
    80001a10:	0800                	addi	s0,sp,16
    80001a12:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a14:	2781                	sext.w	a5,a5
    80001a16:	079e                	slli	a5,a5,0x7
}
    80001a18:	00010517          	auipc	a0,0x10
    80001a1c:	f5050513          	addi	a0,a0,-176 # 80011968 <cpus>
    80001a20:	953e                	add	a0,a0,a5
    80001a22:	6422                	ld	s0,8(sp)
    80001a24:	0141                	addi	sp,sp,16
    80001a26:	8082                	ret

0000000080001a28 <myproc>:
myproc(void) {
    80001a28:	1101                	addi	sp,sp,-32
    80001a2a:	ec06                	sd	ra,24(sp)
    80001a2c:	e822                	sd	s0,16(sp)
    80001a2e:	e426                	sd	s1,8(sp)
    80001a30:	1000                	addi	s0,sp,32
  push_off();
    80001a32:	fffff097          	auipc	ra,0xfffff
    80001a36:	1dc080e7          	jalr	476(ra) # 80000c0e <push_off>
    80001a3a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a3c:	2781                	sext.w	a5,a5
    80001a3e:	079e                	slli	a5,a5,0x7
    80001a40:	00010717          	auipc	a4,0x10
    80001a44:	f1070713          	addi	a4,a4,-240 # 80011950 <pid_lock>
    80001a48:	97ba                	add	a5,a5,a4
    80001a4a:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	262080e7          	jalr	610(ra) # 80000cae <pop_off>
}
    80001a54:	8526                	mv	a0,s1
    80001a56:	60e2                	ld	ra,24(sp)
    80001a58:	6442                	ld	s0,16(sp)
    80001a5a:	64a2                	ld	s1,8(sp)
    80001a5c:	6105                	addi	sp,sp,32
    80001a5e:	8082                	ret

0000000080001a60 <forkret>:
{
    80001a60:	1141                	addi	sp,sp,-16
    80001a62:	e406                	sd	ra,8(sp)
    80001a64:	e022                	sd	s0,0(sp)
    80001a66:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a68:	00000097          	auipc	ra,0x0
    80001a6c:	fc0080e7          	jalr	-64(ra) # 80001a28 <myproc>
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	29e080e7          	jalr	670(ra) # 80000d0e <release>
  if (first) {
    80001a78:	00007797          	auipc	a5,0x7
    80001a7c:	f287a783          	lw	a5,-216(a5) # 800089a0 <first.1670>
    80001a80:	eb89                	bnez	a5,80001a92 <forkret+0x32>
  usertrapret();
    80001a82:	00001097          	auipc	ra,0x1
    80001a86:	cb4080e7          	jalr	-844(ra) # 80002736 <usertrapret>
}
    80001a8a:	60a2                	ld	ra,8(sp)
    80001a8c:	6402                	ld	s0,0(sp)
    80001a8e:	0141                	addi	sp,sp,16
    80001a90:	8082                	ret
    first = 0;
    80001a92:	00007797          	auipc	a5,0x7
    80001a96:	f007a723          	sw	zero,-242(a5) # 800089a0 <first.1670>
    fsinit(ROOTDEV);
    80001a9a:	4505                	li	a0,1
    80001a9c:	00002097          	auipc	ra,0x2
    80001aa0:	a64080e7          	jalr	-1436(ra) # 80003500 <fsinit>
    80001aa4:	bff9                	j	80001a82 <forkret+0x22>

0000000080001aa6 <allocpid>:
allocpid() {
    80001aa6:	1101                	addi	sp,sp,-32
    80001aa8:	ec06                	sd	ra,24(sp)
    80001aaa:	e822                	sd	s0,16(sp)
    80001aac:	e426                	sd	s1,8(sp)
    80001aae:	e04a                	sd	s2,0(sp)
    80001ab0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ab2:	00010917          	auipc	s2,0x10
    80001ab6:	e9e90913          	addi	s2,s2,-354 # 80011950 <pid_lock>
    80001aba:	854a                	mv	a0,s2
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	19e080e7          	jalr	414(ra) # 80000c5a <acquire>
  pid = nextpid;
    80001ac4:	00007797          	auipc	a5,0x7
    80001ac8:	ee078793          	addi	a5,a5,-288 # 800089a4 <nextpid>
    80001acc:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ace:	0014871b          	addiw	a4,s1,1
    80001ad2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad4:	854a                	mv	a0,s2
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	238080e7          	jalr	568(ra) # 80000d0e <release>
}
    80001ade:	8526                	mv	a0,s1
    80001ae0:	60e2                	ld	ra,24(sp)
    80001ae2:	6442                	ld	s0,16(sp)
    80001ae4:	64a2                	ld	s1,8(sp)
    80001ae6:	6902                	ld	s2,0(sp)
    80001ae8:	6105                	addi	sp,sp,32
    80001aea:	8082                	ret

0000000080001aec <proc_pagetable>:
{
    80001aec:	1101                	addi	sp,sp,-32
    80001aee:	ec06                	sd	ra,24(sp)
    80001af0:	e822                	sd	s0,16(sp)
    80001af2:	e426                	sd	s1,8(sp)
    80001af4:	e04a                	sd	s2,0(sp)
    80001af6:	1000                	addi	s0,sp,32
    80001af8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	8ea080e7          	jalr	-1814(ra) # 800013e4 <uvmcreate>
    80001b02:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b04:	c121                	beqz	a0,80001b44 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b06:	4729                	li	a4,10
    80001b08:	00005697          	auipc	a3,0x5
    80001b0c:	4f868693          	addi	a3,a3,1272 # 80007000 <_trampoline>
    80001b10:	6605                	lui	a2,0x1
    80001b12:	040005b7          	lui	a1,0x4000
    80001b16:	15fd                	addi	a1,a1,-1
    80001b18:	05b2                	slli	a1,a1,0xc
    80001b1a:	fffff097          	auipc	ra,0xfffff
    80001b1e:	66e080e7          	jalr	1646(ra) # 80001188 <mappages>
    80001b22:	02054863          	bltz	a0,80001b52 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b26:	4719                	li	a4,6
    80001b28:	05893683          	ld	a3,88(s2)
    80001b2c:	6605                	lui	a2,0x1
    80001b2e:	020005b7          	lui	a1,0x2000
    80001b32:	15fd                	addi	a1,a1,-1
    80001b34:	05b6                	slli	a1,a1,0xd
    80001b36:	8526                	mv	a0,s1
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	650080e7          	jalr	1616(ra) # 80001188 <mappages>
    80001b40:	02054163          	bltz	a0,80001b62 <proc_pagetable+0x76>
}
    80001b44:	8526                	mv	a0,s1
    80001b46:	60e2                	ld	ra,24(sp)
    80001b48:	6442                	ld	s0,16(sp)
    80001b4a:	64a2                	ld	s1,8(sp)
    80001b4c:	6902                	ld	s2,0(sp)
    80001b4e:	6105                	addi	sp,sp,32
    80001b50:	8082                	ret
    uvmfree(pagetable, 0);
    80001b52:	4581                	li	a1,0
    80001b54:	8526                	mv	a0,s1
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	a8a080e7          	jalr	-1398(ra) # 800015e0 <uvmfree>
    return 0;
    80001b5e:	4481                	li	s1,0
    80001b60:	b7d5                	j	80001b44 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b62:	4681                	li	a3,0
    80001b64:	4605                	li	a2,1
    80001b66:	040005b7          	lui	a1,0x4000
    80001b6a:	15fd                	addi	a1,a1,-1
    80001b6c:	05b2                	slli	a1,a1,0xc
    80001b6e:	8526                	mv	a0,s1
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	7b0080e7          	jalr	1968(ra) # 80001320 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b78:	4581                	li	a1,0
    80001b7a:	8526                	mv	a0,s1
    80001b7c:	00000097          	auipc	ra,0x0
    80001b80:	a64080e7          	jalr	-1436(ra) # 800015e0 <uvmfree>
    return 0;
    80001b84:	4481                	li	s1,0
    80001b86:	bf7d                	j	80001b44 <proc_pagetable+0x58>

0000000080001b88 <proc_freepagetable>:
{
    80001b88:	1101                	addi	sp,sp,-32
    80001b8a:	ec06                	sd	ra,24(sp)
    80001b8c:	e822                	sd	s0,16(sp)
    80001b8e:	e426                	sd	s1,8(sp)
    80001b90:	e04a                	sd	s2,0(sp)
    80001b92:	1000                	addi	s0,sp,32
    80001b94:	84aa                	mv	s1,a0
    80001b96:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b98:	4681                	li	a3,0
    80001b9a:	4605                	li	a2,1
    80001b9c:	040005b7          	lui	a1,0x4000
    80001ba0:	15fd                	addi	a1,a1,-1
    80001ba2:	05b2                	slli	a1,a1,0xc
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	77c080e7          	jalr	1916(ra) # 80001320 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bac:	4681                	li	a3,0
    80001bae:	4605                	li	a2,1
    80001bb0:	020005b7          	lui	a1,0x2000
    80001bb4:	15fd                	addi	a1,a1,-1
    80001bb6:	05b6                	slli	a1,a1,0xd
    80001bb8:	8526                	mv	a0,s1
    80001bba:	fffff097          	auipc	ra,0xfffff
    80001bbe:	766080e7          	jalr	1894(ra) # 80001320 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bc2:	85ca                	mv	a1,s2
    80001bc4:	8526                	mv	a0,s1
    80001bc6:	00000097          	auipc	ra,0x0
    80001bca:	a1a080e7          	jalr	-1510(ra) # 800015e0 <uvmfree>
}
    80001bce:	60e2                	ld	ra,24(sp)
    80001bd0:	6442                	ld	s0,16(sp)
    80001bd2:	64a2                	ld	s1,8(sp)
    80001bd4:	6902                	ld	s2,0(sp)
    80001bd6:	6105                	addi	sp,sp,32
    80001bd8:	8082                	ret

0000000080001bda <freeproc>:
{
    80001bda:	1101                	addi	sp,sp,-32
    80001bdc:	ec06                	sd	ra,24(sp)
    80001bde:	e822                	sd	s0,16(sp)
    80001be0:	e426                	sd	s1,8(sp)
    80001be2:	1000                	addi	s0,sp,32
    80001be4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001be6:	6d28                	ld	a0,88(a0)
    80001be8:	c509                	beqz	a0,80001bf2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	e3a080e7          	jalr	-454(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001bf2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bf6:	68a8                	ld	a0,80(s1)
    80001bf8:	c511                	beqz	a0,80001c04 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bfa:	64ac                	ld	a1,72(s1)
    80001bfc:	00000097          	auipc	ra,0x0
    80001c00:	f8c080e7          	jalr	-116(ra) # 80001b88 <proc_freepagetable>
  p->pagetable = 0;
    80001c04:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c08:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c0c:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c10:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c14:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c18:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c1c:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c20:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c24:	0004ac23          	sw	zero,24(s1)
}
    80001c28:	60e2                	ld	ra,24(sp)
    80001c2a:	6442                	ld	s0,16(sp)
    80001c2c:	64a2                	ld	s1,8(sp)
    80001c2e:	6105                	addi	sp,sp,32
    80001c30:	8082                	ret

0000000080001c32 <allocproc>:
{
    80001c32:	1101                	addi	sp,sp,-32
    80001c34:	ec06                	sd	ra,24(sp)
    80001c36:	e822                	sd	s0,16(sp)
    80001c38:	e426                	sd	s1,8(sp)
    80001c3a:	e04a                	sd	s2,0(sp)
    80001c3c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c3e:	00010497          	auipc	s1,0x10
    80001c42:	12a48493          	addi	s1,s1,298 # 80011d68 <proc>
    80001c46:	00016917          	auipc	s2,0x16
    80001c4a:	b2290913          	addi	s2,s2,-1246 # 80017768 <tickslock>
    acquire(&p->lock);
    80001c4e:	8526                	mv	a0,s1
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	00a080e7          	jalr	10(ra) # 80000c5a <acquire>
    if(p->state == UNUSED) {
    80001c58:	4c9c                	lw	a5,24(s1)
    80001c5a:	cf81                	beqz	a5,80001c72 <allocproc+0x40>
      release(&p->lock);
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	0b0080e7          	jalr	176(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c66:	16848493          	addi	s1,s1,360
    80001c6a:	ff2492e3          	bne	s1,s2,80001c4e <allocproc+0x1c>
  return 0;
    80001c6e:	4481                	li	s1,0
    80001c70:	a0b9                	j	80001cbe <allocproc+0x8c>
  p->pid = allocpid();
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	e34080e7          	jalr	-460(ra) # 80001aa6 <allocpid>
    80001c7a:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	ea4080e7          	jalr	-348(ra) # 80000b20 <kalloc>
    80001c84:	892a                	mv	s2,a0
    80001c86:	eca8                	sd	a0,88(s1)
    80001c88:	c131                	beqz	a0,80001ccc <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	e60080e7          	jalr	-416(ra) # 80001aec <proc_pagetable>
    80001c94:	892a                	mv	s2,a0
    80001c96:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c98:	c129                	beqz	a0,80001cda <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c9a:	07000613          	li	a2,112
    80001c9e:	4581                	li	a1,0
    80001ca0:	06048513          	addi	a0,s1,96
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	0b2080e7          	jalr	178(ra) # 80000d56 <memset>
  p->context.ra = (uint64)forkret;
    80001cac:	00000797          	auipc	a5,0x0
    80001cb0:	db478793          	addi	a5,a5,-588 # 80001a60 <forkret>
    80001cb4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cb6:	60bc                	ld	a5,64(s1)
    80001cb8:	6705                	lui	a4,0x1
    80001cba:	97ba                	add	a5,a5,a4
    80001cbc:	f4bc                	sd	a5,104(s1)
}
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	60e2                	ld	ra,24(sp)
    80001cc2:	6442                	ld	s0,16(sp)
    80001cc4:	64a2                	ld	s1,8(sp)
    80001cc6:	6902                	ld	s2,0(sp)
    80001cc8:	6105                	addi	sp,sp,32
    80001cca:	8082                	ret
    release(&p->lock);
    80001ccc:	8526                	mv	a0,s1
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	040080e7          	jalr	64(ra) # 80000d0e <release>
    return 0;
    80001cd6:	84ca                	mv	s1,s2
    80001cd8:	b7dd                	j	80001cbe <allocproc+0x8c>
    freeproc(p);
    80001cda:	8526                	mv	a0,s1
    80001cdc:	00000097          	auipc	ra,0x0
    80001ce0:	efe080e7          	jalr	-258(ra) # 80001bda <freeproc>
    release(&p->lock);
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	028080e7          	jalr	40(ra) # 80000d0e <release>
    return 0;
    80001cee:	84ca                	mv	s1,s2
    80001cf0:	b7f9                	j	80001cbe <allocproc+0x8c>

0000000080001cf2 <userinit>:
{
    80001cf2:	1101                	addi	sp,sp,-32
    80001cf4:	ec06                	sd	ra,24(sp)
    80001cf6:	e822                	sd	s0,16(sp)
    80001cf8:	e426                	sd	s1,8(sp)
    80001cfa:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	f36080e7          	jalr	-202(ra) # 80001c32 <allocproc>
    80001d04:	84aa                	mv	s1,a0
  initproc = p;
    80001d06:	00007797          	auipc	a5,0x7
    80001d0a:	30a7b923          	sd	a0,786(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d0e:	03400613          	li	a2,52
    80001d12:	00007597          	auipc	a1,0x7
    80001d16:	c9e58593          	addi	a1,a1,-866 # 800089b0 <initcode>
    80001d1a:	6928                	ld	a0,80(a0)
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	6f6080e7          	jalr	1782(ra) # 80001412 <uvminit>
  p->sz = PGSIZE;
    80001d24:	6785                	lui	a5,0x1
    80001d26:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d28:	6cb8                	ld	a4,88(s1)
    80001d2a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d2e:	6cb8                	ld	a4,88(s1)
    80001d30:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d32:	4641                	li	a2,16
    80001d34:	00006597          	auipc	a1,0x6
    80001d38:	4b458593          	addi	a1,a1,1204 # 800081e8 <digits+0x1a8>
    80001d3c:	15848513          	addi	a0,s1,344
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	16c080e7          	jalr	364(ra) # 80000eac <safestrcpy>
  p->cwd = namei("/");
    80001d48:	00006517          	auipc	a0,0x6
    80001d4c:	4b050513          	addi	a0,a0,1200 # 800081f8 <digits+0x1b8>
    80001d50:	00002097          	auipc	ra,0x2
    80001d54:	1d8080e7          	jalr	472(ra) # 80003f28 <namei>
    80001d58:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d5c:	4789                	li	a5,2
    80001d5e:	cc9c                	sw	a5,24(s1)
  p->tracemask = 0;
    80001d60:	0204ae23          	sw	zero,60(s1)
  release(&p->lock);
    80001d64:	8526                	mv	a0,s1
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	fa8080e7          	jalr	-88(ra) # 80000d0e <release>
}
    80001d6e:	60e2                	ld	ra,24(sp)
    80001d70:	6442                	ld	s0,16(sp)
    80001d72:	64a2                	ld	s1,8(sp)
    80001d74:	6105                	addi	sp,sp,32
    80001d76:	8082                	ret

0000000080001d78 <growproc>:
{
    80001d78:	1101                	addi	sp,sp,-32
    80001d7a:	ec06                	sd	ra,24(sp)
    80001d7c:	e822                	sd	s0,16(sp)
    80001d7e:	e426                	sd	s1,8(sp)
    80001d80:	e04a                	sd	s2,0(sp)
    80001d82:	1000                	addi	s0,sp,32
    80001d84:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d86:	00000097          	auipc	ra,0x0
    80001d8a:	ca2080e7          	jalr	-862(ra) # 80001a28 <myproc>
    80001d8e:	892a                	mv	s2,a0
  sz = p->sz;
    80001d90:	652c                	ld	a1,72(a0)
    80001d92:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d96:	00904f63          	bgtz	s1,80001db4 <growproc+0x3c>
  } else if(n < 0){
    80001d9a:	0204cc63          	bltz	s1,80001dd2 <growproc+0x5a>
  p->sz = sz;
    80001d9e:	1602                	slli	a2,a2,0x20
    80001da0:	9201                	srli	a2,a2,0x20
    80001da2:	04c93423          	sd	a2,72(s2)
  return 0;
    80001da6:	4501                	li	a0,0
}
    80001da8:	60e2                	ld	ra,24(sp)
    80001daa:	6442                	ld	s0,16(sp)
    80001dac:	64a2                	ld	s1,8(sp)
    80001dae:	6902                	ld	s2,0(sp)
    80001db0:	6105                	addi	sp,sp,32
    80001db2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001db4:	9e25                	addw	a2,a2,s1
    80001db6:	1602                	slli	a2,a2,0x20
    80001db8:	9201                	srli	a2,a2,0x20
    80001dba:	1582                	slli	a1,a1,0x20
    80001dbc:	9181                	srli	a1,a1,0x20
    80001dbe:	6928                	ld	a0,80(a0)
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	70c080e7          	jalr	1804(ra) # 800014cc <uvmalloc>
    80001dc8:	0005061b          	sext.w	a2,a0
    80001dcc:	fa69                	bnez	a2,80001d9e <growproc+0x26>
      return -1;
    80001dce:	557d                	li	a0,-1
    80001dd0:	bfe1                	j	80001da8 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dd2:	9e25                	addw	a2,a2,s1
    80001dd4:	1602                	slli	a2,a2,0x20
    80001dd6:	9201                	srli	a2,a2,0x20
    80001dd8:	1582                	slli	a1,a1,0x20
    80001dda:	9181                	srli	a1,a1,0x20
    80001ddc:	6928                	ld	a0,80(a0)
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	6a6080e7          	jalr	1702(ra) # 80001484 <uvmdealloc>
    80001de6:	0005061b          	sext.w	a2,a0
    80001dea:	bf55                	j	80001d9e <growproc+0x26>

0000000080001dec <fork>:
{
    80001dec:	7179                	addi	sp,sp,-48
    80001dee:	f406                	sd	ra,40(sp)
    80001df0:	f022                	sd	s0,32(sp)
    80001df2:	ec26                	sd	s1,24(sp)
    80001df4:	e84a                	sd	s2,16(sp)
    80001df6:	e44e                	sd	s3,8(sp)
    80001df8:	e052                	sd	s4,0(sp)
    80001dfa:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dfc:	00000097          	auipc	ra,0x0
    80001e00:	c2c080e7          	jalr	-980(ra) # 80001a28 <myproc>
    80001e04:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	e2c080e7          	jalr	-468(ra) # 80001c32 <allocproc>
    80001e0e:	c575                	beqz	a0,80001efa <fork+0x10e>
    80001e10:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e12:	04893603          	ld	a2,72(s2)
    80001e16:	692c                	ld	a1,80(a0)
    80001e18:	05093503          	ld	a0,80(s2)
    80001e1c:	fffff097          	auipc	ra,0xfffff
    80001e20:	7fc080e7          	jalr	2044(ra) # 80001618 <uvmcopy>
    80001e24:	04054863          	bltz	a0,80001e74 <fork+0x88>
  np->sz = p->sz;
    80001e28:	04893783          	ld	a5,72(s2)
    80001e2c:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e30:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e34:	05893683          	ld	a3,88(s2)
    80001e38:	87b6                	mv	a5,a3
    80001e3a:	0589b703          	ld	a4,88(s3)
    80001e3e:	12068693          	addi	a3,a3,288
    80001e42:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e46:	6788                	ld	a0,8(a5)
    80001e48:	6b8c                	ld	a1,16(a5)
    80001e4a:	6f90                	ld	a2,24(a5)
    80001e4c:	01073023          	sd	a6,0(a4)
    80001e50:	e708                	sd	a0,8(a4)
    80001e52:	eb0c                	sd	a1,16(a4)
    80001e54:	ef10                	sd	a2,24(a4)
    80001e56:	02078793          	addi	a5,a5,32
    80001e5a:	02070713          	addi	a4,a4,32
    80001e5e:	fed792e3          	bne	a5,a3,80001e42 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e62:	0589b783          	ld	a5,88(s3)
    80001e66:	0607b823          	sd	zero,112(a5)
    80001e6a:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e6e:	15000a13          	li	s4,336
    80001e72:	a03d                	j	80001ea0 <fork+0xb4>
    freeproc(np);
    80001e74:	854e                	mv	a0,s3
    80001e76:	00000097          	auipc	ra,0x0
    80001e7a:	d64080e7          	jalr	-668(ra) # 80001bda <freeproc>
    release(&np->lock);
    80001e7e:	854e                	mv	a0,s3
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	e8e080e7          	jalr	-370(ra) # 80000d0e <release>
    return -1;
    80001e88:	54fd                	li	s1,-1
    80001e8a:	a8b9                	j	80001ee8 <fork+0xfc>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e8c:	00002097          	auipc	ra,0x2
    80001e90:	728080e7          	jalr	1832(ra) # 800045b4 <filedup>
    80001e94:	009987b3          	add	a5,s3,s1
    80001e98:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e9a:	04a1                	addi	s1,s1,8
    80001e9c:	01448763          	beq	s1,s4,80001eaa <fork+0xbe>
    if(p->ofile[i])
    80001ea0:	009907b3          	add	a5,s2,s1
    80001ea4:	6388                	ld	a0,0(a5)
    80001ea6:	f17d                	bnez	a0,80001e8c <fork+0xa0>
    80001ea8:	bfcd                	j	80001e9a <fork+0xae>
  np->cwd = idup(p->cwd);
    80001eaa:	15093503          	ld	a0,336(s2)
    80001eae:	00002097          	auipc	ra,0x2
    80001eb2:	88c080e7          	jalr	-1908(ra) # 8000373a <idup>
    80001eb6:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eba:	4641                	li	a2,16
    80001ebc:	15890593          	addi	a1,s2,344
    80001ec0:	15898513          	addi	a0,s3,344
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	fe8080e7          	jalr	-24(ra) # 80000eac <safestrcpy>
  pid = np->pid;
    80001ecc:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001ed0:	4789                	li	a5,2
    80001ed2:	00f9ac23          	sw	a5,24(s3)
  np->tracemask = p->tracemask;
    80001ed6:	03c92783          	lw	a5,60(s2)
    80001eda:	02f9ae23          	sw	a5,60(s3)
  release(&np->lock);
    80001ede:	854e                	mv	a0,s3
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	e2e080e7          	jalr	-466(ra) # 80000d0e <release>
}
    80001ee8:	8526                	mv	a0,s1
    80001eea:	70a2                	ld	ra,40(sp)
    80001eec:	7402                	ld	s0,32(sp)
    80001eee:	64e2                	ld	s1,24(sp)
    80001ef0:	6942                	ld	s2,16(sp)
    80001ef2:	69a2                	ld	s3,8(sp)
    80001ef4:	6a02                	ld	s4,0(sp)
    80001ef6:	6145                	addi	sp,sp,48
    80001ef8:	8082                	ret
    return -1;
    80001efa:	54fd                	li	s1,-1
    80001efc:	b7f5                	j	80001ee8 <fork+0xfc>

0000000080001efe <reparent>:
{
    80001efe:	7179                	addi	sp,sp,-48
    80001f00:	f406                	sd	ra,40(sp)
    80001f02:	f022                	sd	s0,32(sp)
    80001f04:	ec26                	sd	s1,24(sp)
    80001f06:	e84a                	sd	s2,16(sp)
    80001f08:	e44e                	sd	s3,8(sp)
    80001f0a:	e052                	sd	s4,0(sp)
    80001f0c:	1800                	addi	s0,sp,48
    80001f0e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f10:	00010497          	auipc	s1,0x10
    80001f14:	e5848493          	addi	s1,s1,-424 # 80011d68 <proc>
      pp->parent = initproc;
    80001f18:	00007a17          	auipc	s4,0x7
    80001f1c:	100a0a13          	addi	s4,s4,256 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f20:	00016997          	auipc	s3,0x16
    80001f24:	84898993          	addi	s3,s3,-1976 # 80017768 <tickslock>
    80001f28:	a029                	j	80001f32 <reparent+0x34>
    80001f2a:	16848493          	addi	s1,s1,360
    80001f2e:	03348363          	beq	s1,s3,80001f54 <reparent+0x56>
    if(pp->parent == p){
    80001f32:	709c                	ld	a5,32(s1)
    80001f34:	ff279be3          	bne	a5,s2,80001f2a <reparent+0x2c>
      acquire(&pp->lock);
    80001f38:	8526                	mv	a0,s1
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	d20080e7          	jalr	-736(ra) # 80000c5a <acquire>
      pp->parent = initproc;
    80001f42:	000a3783          	ld	a5,0(s4)
    80001f46:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f48:	8526                	mv	a0,s1
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	dc4080e7          	jalr	-572(ra) # 80000d0e <release>
    80001f52:	bfe1                	j	80001f2a <reparent+0x2c>
}
    80001f54:	70a2                	ld	ra,40(sp)
    80001f56:	7402                	ld	s0,32(sp)
    80001f58:	64e2                	ld	s1,24(sp)
    80001f5a:	6942                	ld	s2,16(sp)
    80001f5c:	69a2                	ld	s3,8(sp)
    80001f5e:	6a02                	ld	s4,0(sp)
    80001f60:	6145                	addi	sp,sp,48
    80001f62:	8082                	ret

0000000080001f64 <scheduler>:
{
    80001f64:	715d                	addi	sp,sp,-80
    80001f66:	e486                	sd	ra,72(sp)
    80001f68:	e0a2                	sd	s0,64(sp)
    80001f6a:	fc26                	sd	s1,56(sp)
    80001f6c:	f84a                	sd	s2,48(sp)
    80001f6e:	f44e                	sd	s3,40(sp)
    80001f70:	f052                	sd	s4,32(sp)
    80001f72:	ec56                	sd	s5,24(sp)
    80001f74:	e85a                	sd	s6,16(sp)
    80001f76:	e45e                	sd	s7,8(sp)
    80001f78:	e062                	sd	s8,0(sp)
    80001f7a:	0880                	addi	s0,sp,80
    80001f7c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f7e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f80:	00779b13          	slli	s6,a5,0x7
    80001f84:	00010717          	auipc	a4,0x10
    80001f88:	9cc70713          	addi	a4,a4,-1588 # 80011950 <pid_lock>
    80001f8c:	975a                	add	a4,a4,s6
    80001f8e:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f92:	00010717          	auipc	a4,0x10
    80001f96:	9de70713          	addi	a4,a4,-1570 # 80011970 <cpus+0x8>
    80001f9a:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f9c:	4c0d                	li	s8,3
        c->proc = p;
    80001f9e:	079e                	slli	a5,a5,0x7
    80001fa0:	00010a17          	auipc	s4,0x10
    80001fa4:	9b0a0a13          	addi	s4,s4,-1616 # 80011950 <pid_lock>
    80001fa8:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001faa:	00015997          	auipc	s3,0x15
    80001fae:	7be98993          	addi	s3,s3,1982 # 80017768 <tickslock>
        found = 1;
    80001fb2:	4b85                	li	s7,1
    80001fb4:	a899                	j	8000200a <scheduler+0xa6>
        p->state = RUNNING;
    80001fb6:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001fba:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001fbe:	06048593          	addi	a1,s1,96
    80001fc2:	855a                	mv	a0,s6
    80001fc4:	00000097          	auipc	ra,0x0
    80001fc8:	6c8080e7          	jalr	1736(ra) # 8000268c <swtch>
        c->proc = 0;
    80001fcc:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001fd0:	8ade                	mv	s5,s7
      release(&p->lock);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	d3a080e7          	jalr	-710(ra) # 80000d0e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fdc:	16848493          	addi	s1,s1,360
    80001fe0:	01348b63          	beq	s1,s3,80001ff6 <scheduler+0x92>
      acquire(&p->lock);
    80001fe4:	8526                	mv	a0,s1
    80001fe6:	fffff097          	auipc	ra,0xfffff
    80001fea:	c74080e7          	jalr	-908(ra) # 80000c5a <acquire>
      if(p->state == RUNNABLE) {
    80001fee:	4c9c                	lw	a5,24(s1)
    80001ff0:	ff2791e3          	bne	a5,s2,80001fd2 <scheduler+0x6e>
    80001ff4:	b7c9                	j	80001fb6 <scheduler+0x52>
    if(found == 0) {
    80001ff6:	000a9a63          	bnez	s5,8000200a <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ffe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002002:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002006:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000200a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000200e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002012:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002016:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002018:	00010497          	auipc	s1,0x10
    8000201c:	d5048493          	addi	s1,s1,-688 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002020:	4909                	li	s2,2
    80002022:	b7c9                	j	80001fe4 <scheduler+0x80>

0000000080002024 <sched>:
{
    80002024:	7179                	addi	sp,sp,-48
    80002026:	f406                	sd	ra,40(sp)
    80002028:	f022                	sd	s0,32(sp)
    8000202a:	ec26                	sd	s1,24(sp)
    8000202c:	e84a                	sd	s2,16(sp)
    8000202e:	e44e                	sd	s3,8(sp)
    80002030:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002032:	00000097          	auipc	ra,0x0
    80002036:	9f6080e7          	jalr	-1546(ra) # 80001a28 <myproc>
    8000203a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	ba4080e7          	jalr	-1116(ra) # 80000be0 <holding>
    80002044:	c93d                	beqz	a0,800020ba <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002046:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002048:	2781                	sext.w	a5,a5
    8000204a:	079e                	slli	a5,a5,0x7
    8000204c:	00010717          	auipc	a4,0x10
    80002050:	90470713          	addi	a4,a4,-1788 # 80011950 <pid_lock>
    80002054:	97ba                	add	a5,a5,a4
    80002056:	0907a703          	lw	a4,144(a5)
    8000205a:	4785                	li	a5,1
    8000205c:	06f71763          	bne	a4,a5,800020ca <sched+0xa6>
  if(p->state == RUNNING)
    80002060:	4c98                	lw	a4,24(s1)
    80002062:	478d                	li	a5,3
    80002064:	06f70b63          	beq	a4,a5,800020da <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002068:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000206c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000206e:	efb5                	bnez	a5,800020ea <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002070:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002072:	00010917          	auipc	s2,0x10
    80002076:	8de90913          	addi	s2,s2,-1826 # 80011950 <pid_lock>
    8000207a:	2781                	sext.w	a5,a5
    8000207c:	079e                	slli	a5,a5,0x7
    8000207e:	97ca                	add	a5,a5,s2
    80002080:	0947a983          	lw	s3,148(a5)
    80002084:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002086:	2781                	sext.w	a5,a5
    80002088:	079e                	slli	a5,a5,0x7
    8000208a:	00010597          	auipc	a1,0x10
    8000208e:	8e658593          	addi	a1,a1,-1818 # 80011970 <cpus+0x8>
    80002092:	95be                	add	a1,a1,a5
    80002094:	06048513          	addi	a0,s1,96
    80002098:	00000097          	auipc	ra,0x0
    8000209c:	5f4080e7          	jalr	1524(ra) # 8000268c <swtch>
    800020a0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020a2:	2781                	sext.w	a5,a5
    800020a4:	079e                	slli	a5,a5,0x7
    800020a6:	97ca                	add	a5,a5,s2
    800020a8:	0937aa23          	sw	s3,148(a5)
}
    800020ac:	70a2                	ld	ra,40(sp)
    800020ae:	7402                	ld	s0,32(sp)
    800020b0:	64e2                	ld	s1,24(sp)
    800020b2:	6942                	ld	s2,16(sp)
    800020b4:	69a2                	ld	s3,8(sp)
    800020b6:	6145                	addi	sp,sp,48
    800020b8:	8082                	ret
    panic("sched p->lock");
    800020ba:	00006517          	auipc	a0,0x6
    800020be:	14650513          	addi	a0,a0,326 # 80008200 <digits+0x1c0>
    800020c2:	ffffe097          	auipc	ra,0xffffe
    800020c6:	486080e7          	jalr	1158(ra) # 80000548 <panic>
    panic("sched locks");
    800020ca:	00006517          	auipc	a0,0x6
    800020ce:	14650513          	addi	a0,a0,326 # 80008210 <digits+0x1d0>
    800020d2:	ffffe097          	auipc	ra,0xffffe
    800020d6:	476080e7          	jalr	1142(ra) # 80000548 <panic>
    panic("sched running");
    800020da:	00006517          	auipc	a0,0x6
    800020de:	14650513          	addi	a0,a0,326 # 80008220 <digits+0x1e0>
    800020e2:	ffffe097          	auipc	ra,0xffffe
    800020e6:	466080e7          	jalr	1126(ra) # 80000548 <panic>
    panic("sched interruptible");
    800020ea:	00006517          	auipc	a0,0x6
    800020ee:	14650513          	addi	a0,a0,326 # 80008230 <digits+0x1f0>
    800020f2:	ffffe097          	auipc	ra,0xffffe
    800020f6:	456080e7          	jalr	1110(ra) # 80000548 <panic>

00000000800020fa <exit>:
{
    800020fa:	7179                	addi	sp,sp,-48
    800020fc:	f406                	sd	ra,40(sp)
    800020fe:	f022                	sd	s0,32(sp)
    80002100:	ec26                	sd	s1,24(sp)
    80002102:	e84a                	sd	s2,16(sp)
    80002104:	e44e                	sd	s3,8(sp)
    80002106:	e052                	sd	s4,0(sp)
    80002108:	1800                	addi	s0,sp,48
    8000210a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	91c080e7          	jalr	-1764(ra) # 80001a28 <myproc>
    80002114:	89aa                	mv	s3,a0
  if(p == initproc)
    80002116:	00007797          	auipc	a5,0x7
    8000211a:	f027b783          	ld	a5,-254(a5) # 80009018 <initproc>
    8000211e:	0d050493          	addi	s1,a0,208
    80002122:	15050913          	addi	s2,a0,336
    80002126:	02a79363          	bne	a5,a0,8000214c <exit+0x52>
    panic("init exiting");
    8000212a:	00006517          	auipc	a0,0x6
    8000212e:	11e50513          	addi	a0,a0,286 # 80008248 <digits+0x208>
    80002132:	ffffe097          	auipc	ra,0xffffe
    80002136:	416080e7          	jalr	1046(ra) # 80000548 <panic>
      fileclose(f);
    8000213a:	00002097          	auipc	ra,0x2
    8000213e:	4cc080e7          	jalr	1228(ra) # 80004606 <fileclose>
      p->ofile[fd] = 0;
    80002142:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002146:	04a1                	addi	s1,s1,8
    80002148:	01248563          	beq	s1,s2,80002152 <exit+0x58>
    if(p->ofile[fd]){
    8000214c:	6088                	ld	a0,0(s1)
    8000214e:	f575                	bnez	a0,8000213a <exit+0x40>
    80002150:	bfdd                	j	80002146 <exit+0x4c>
  begin_op();
    80002152:	00002097          	auipc	ra,0x2
    80002156:	fe2080e7          	jalr	-30(ra) # 80004134 <begin_op>
  iput(p->cwd);
    8000215a:	1509b503          	ld	a0,336(s3)
    8000215e:	00001097          	auipc	ra,0x1
    80002162:	7d4080e7          	jalr	2004(ra) # 80003932 <iput>
  end_op();
    80002166:	00002097          	auipc	ra,0x2
    8000216a:	04e080e7          	jalr	78(ra) # 800041b4 <end_op>
  p->cwd = 0;
    8000216e:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002172:	00007497          	auipc	s1,0x7
    80002176:	ea648493          	addi	s1,s1,-346 # 80009018 <initproc>
    8000217a:	6088                	ld	a0,0(s1)
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	ade080e7          	jalr	-1314(ra) # 80000c5a <acquire>
  wakeup1(initproc);
    80002184:	6088                	ld	a0,0(s1)
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	762080e7          	jalr	1890(ra) # 800018e8 <wakeup1>
  release(&initproc->lock);
    8000218e:	6088                	ld	a0,0(s1)
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	b7e080e7          	jalr	-1154(ra) # 80000d0e <release>
  acquire(&p->lock);
    80002198:	854e                	mv	a0,s3
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	ac0080e7          	jalr	-1344(ra) # 80000c5a <acquire>
  struct proc *original_parent = p->parent;
    800021a2:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021a6:	854e                	mv	a0,s3
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	b66080e7          	jalr	-1178(ra) # 80000d0e <release>
  acquire(&original_parent->lock);
    800021b0:	8526                	mv	a0,s1
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	aa8080e7          	jalr	-1368(ra) # 80000c5a <acquire>
  acquire(&p->lock);
    800021ba:	854e                	mv	a0,s3
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	a9e080e7          	jalr	-1378(ra) # 80000c5a <acquire>
  reparent(p);
    800021c4:	854e                	mv	a0,s3
    800021c6:	00000097          	auipc	ra,0x0
    800021ca:	d38080e7          	jalr	-712(ra) # 80001efe <reparent>
  wakeup1(original_parent);
    800021ce:	8526                	mv	a0,s1
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	718080e7          	jalr	1816(ra) # 800018e8 <wakeup1>
  p->xstate = status;
    800021d8:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021dc:	4791                	li	a5,4
    800021de:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021e2:	8526                	mv	a0,s1
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	b2a080e7          	jalr	-1238(ra) # 80000d0e <release>
  sched();
    800021ec:	00000097          	auipc	ra,0x0
    800021f0:	e38080e7          	jalr	-456(ra) # 80002024 <sched>
  panic("zombie exit");
    800021f4:	00006517          	auipc	a0,0x6
    800021f8:	06450513          	addi	a0,a0,100 # 80008258 <digits+0x218>
    800021fc:	ffffe097          	auipc	ra,0xffffe
    80002200:	34c080e7          	jalr	844(ra) # 80000548 <panic>

0000000080002204 <yield>:
{
    80002204:	1101                	addi	sp,sp,-32
    80002206:	ec06                	sd	ra,24(sp)
    80002208:	e822                	sd	s0,16(sp)
    8000220a:	e426                	sd	s1,8(sp)
    8000220c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	81a080e7          	jalr	-2022(ra) # 80001a28 <myproc>
    80002216:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	a42080e7          	jalr	-1470(ra) # 80000c5a <acquire>
  p->state = RUNNABLE;
    80002220:	4789                	li	a5,2
    80002222:	cc9c                	sw	a5,24(s1)
  sched();
    80002224:	00000097          	auipc	ra,0x0
    80002228:	e00080e7          	jalr	-512(ra) # 80002024 <sched>
  release(&p->lock);
    8000222c:	8526                	mv	a0,s1
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	ae0080e7          	jalr	-1312(ra) # 80000d0e <release>
}
    80002236:	60e2                	ld	ra,24(sp)
    80002238:	6442                	ld	s0,16(sp)
    8000223a:	64a2                	ld	s1,8(sp)
    8000223c:	6105                	addi	sp,sp,32
    8000223e:	8082                	ret

0000000080002240 <sleep>:
{
    80002240:	7179                	addi	sp,sp,-48
    80002242:	f406                	sd	ra,40(sp)
    80002244:	f022                	sd	s0,32(sp)
    80002246:	ec26                	sd	s1,24(sp)
    80002248:	e84a                	sd	s2,16(sp)
    8000224a:	e44e                	sd	s3,8(sp)
    8000224c:	1800                	addi	s0,sp,48
    8000224e:	89aa                	mv	s3,a0
    80002250:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	7d6080e7          	jalr	2006(ra) # 80001a28 <myproc>
    8000225a:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000225c:	05250663          	beq	a0,s2,800022a8 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	9fa080e7          	jalr	-1542(ra) # 80000c5a <acquire>
    release(lk);
    80002268:	854a                	mv	a0,s2
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	aa4080e7          	jalr	-1372(ra) # 80000d0e <release>
  p->chan = chan;
    80002272:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002276:	4785                	li	a5,1
    80002278:	cc9c                	sw	a5,24(s1)
  sched();
    8000227a:	00000097          	auipc	ra,0x0
    8000227e:	daa080e7          	jalr	-598(ra) # 80002024 <sched>
  p->chan = 0;
    80002282:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002286:	8526                	mv	a0,s1
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	a86080e7          	jalr	-1402(ra) # 80000d0e <release>
    acquire(lk);
    80002290:	854a                	mv	a0,s2
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	9c8080e7          	jalr	-1592(ra) # 80000c5a <acquire>
}
    8000229a:	70a2                	ld	ra,40(sp)
    8000229c:	7402                	ld	s0,32(sp)
    8000229e:	64e2                	ld	s1,24(sp)
    800022a0:	6942                	ld	s2,16(sp)
    800022a2:	69a2                	ld	s3,8(sp)
    800022a4:	6145                	addi	sp,sp,48
    800022a6:	8082                	ret
  p->chan = chan;
    800022a8:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022ac:	4785                	li	a5,1
    800022ae:	cd1c                	sw	a5,24(a0)
  sched();
    800022b0:	00000097          	auipc	ra,0x0
    800022b4:	d74080e7          	jalr	-652(ra) # 80002024 <sched>
  p->chan = 0;
    800022b8:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022bc:	bff9                	j	8000229a <sleep+0x5a>

00000000800022be <wait>:
{
    800022be:	715d                	addi	sp,sp,-80
    800022c0:	e486                	sd	ra,72(sp)
    800022c2:	e0a2                	sd	s0,64(sp)
    800022c4:	fc26                	sd	s1,56(sp)
    800022c6:	f84a                	sd	s2,48(sp)
    800022c8:	f44e                	sd	s3,40(sp)
    800022ca:	f052                	sd	s4,32(sp)
    800022cc:	ec56                	sd	s5,24(sp)
    800022ce:	e85a                	sd	s6,16(sp)
    800022d0:	e45e                	sd	s7,8(sp)
    800022d2:	e062                	sd	s8,0(sp)
    800022d4:	0880                	addi	s0,sp,80
    800022d6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	750080e7          	jalr	1872(ra) # 80001a28 <myproc>
    800022e0:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022e2:	8c2a                	mv	s8,a0
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	976080e7          	jalr	-1674(ra) # 80000c5a <acquire>
    havekids = 0;
    800022ec:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022ee:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800022f0:	00015997          	auipc	s3,0x15
    800022f4:	47898993          	addi	s3,s3,1144 # 80017768 <tickslock>
        havekids = 1;
    800022f8:	4a85                	li	s5,1
    havekids = 0;
    800022fa:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022fc:	00010497          	auipc	s1,0x10
    80002300:	a6c48493          	addi	s1,s1,-1428 # 80011d68 <proc>
    80002304:	a08d                	j	80002366 <wait+0xa8>
          pid = np->pid;
    80002306:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000230a:	000b0e63          	beqz	s6,80002326 <wait+0x68>
    8000230e:	4691                	li	a3,4
    80002310:	03448613          	addi	a2,s1,52
    80002314:	85da                	mv	a1,s6
    80002316:	05093503          	ld	a0,80(s2)
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	402080e7          	jalr	1026(ra) # 8000171c <copyout>
    80002322:	02054263          	bltz	a0,80002346 <wait+0x88>
          freeproc(np);
    80002326:	8526                	mv	a0,s1
    80002328:	00000097          	auipc	ra,0x0
    8000232c:	8b2080e7          	jalr	-1870(ra) # 80001bda <freeproc>
          release(&np->lock);
    80002330:	8526                	mv	a0,s1
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	9dc080e7          	jalr	-1572(ra) # 80000d0e <release>
          release(&p->lock);
    8000233a:	854a                	mv	a0,s2
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	9d2080e7          	jalr	-1582(ra) # 80000d0e <release>
          return pid;
    80002344:	a8a9                	j	8000239e <wait+0xe0>
            release(&np->lock);
    80002346:	8526                	mv	a0,s1
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	9c6080e7          	jalr	-1594(ra) # 80000d0e <release>
            release(&p->lock);
    80002350:	854a                	mv	a0,s2
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	9bc080e7          	jalr	-1604(ra) # 80000d0e <release>
            return -1;
    8000235a:	59fd                	li	s3,-1
    8000235c:	a089                	j	8000239e <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000235e:	16848493          	addi	s1,s1,360
    80002362:	03348463          	beq	s1,s3,8000238a <wait+0xcc>
      if(np->parent == p){
    80002366:	709c                	ld	a5,32(s1)
    80002368:	ff279be3          	bne	a5,s2,8000235e <wait+0xa0>
        acquire(&np->lock);
    8000236c:	8526                	mv	a0,s1
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	8ec080e7          	jalr	-1812(ra) # 80000c5a <acquire>
        if(np->state == ZOMBIE){
    80002376:	4c9c                	lw	a5,24(s1)
    80002378:	f94787e3          	beq	a5,s4,80002306 <wait+0x48>
        release(&np->lock);
    8000237c:	8526                	mv	a0,s1
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	990080e7          	jalr	-1648(ra) # 80000d0e <release>
        havekids = 1;
    80002386:	8756                	mv	a4,s5
    80002388:	bfd9                	j	8000235e <wait+0xa0>
    if(!havekids || p->killed){
    8000238a:	c701                	beqz	a4,80002392 <wait+0xd4>
    8000238c:	03092783          	lw	a5,48(s2)
    80002390:	c785                	beqz	a5,800023b8 <wait+0xfa>
      release(&p->lock);
    80002392:	854a                	mv	a0,s2
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	97a080e7          	jalr	-1670(ra) # 80000d0e <release>
      return -1;
    8000239c:	59fd                	li	s3,-1
}
    8000239e:	854e                	mv	a0,s3
    800023a0:	60a6                	ld	ra,72(sp)
    800023a2:	6406                	ld	s0,64(sp)
    800023a4:	74e2                	ld	s1,56(sp)
    800023a6:	7942                	ld	s2,48(sp)
    800023a8:	79a2                	ld	s3,40(sp)
    800023aa:	7a02                	ld	s4,32(sp)
    800023ac:	6ae2                	ld	s5,24(sp)
    800023ae:	6b42                	ld	s6,16(sp)
    800023b0:	6ba2                	ld	s7,8(sp)
    800023b2:	6c02                	ld	s8,0(sp)
    800023b4:	6161                	addi	sp,sp,80
    800023b6:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023b8:	85e2                	mv	a1,s8
    800023ba:	854a                	mv	a0,s2
    800023bc:	00000097          	auipc	ra,0x0
    800023c0:	e84080e7          	jalr	-380(ra) # 80002240 <sleep>
    havekids = 0;
    800023c4:	bf1d                	j	800022fa <wait+0x3c>

00000000800023c6 <wakeup>:
{
    800023c6:	7139                	addi	sp,sp,-64
    800023c8:	fc06                	sd	ra,56(sp)
    800023ca:	f822                	sd	s0,48(sp)
    800023cc:	f426                	sd	s1,40(sp)
    800023ce:	f04a                	sd	s2,32(sp)
    800023d0:	ec4e                	sd	s3,24(sp)
    800023d2:	e852                	sd	s4,16(sp)
    800023d4:	e456                	sd	s5,8(sp)
    800023d6:	0080                	addi	s0,sp,64
    800023d8:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023da:	00010497          	auipc	s1,0x10
    800023de:	98e48493          	addi	s1,s1,-1650 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023e2:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023e4:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023e6:	00015917          	auipc	s2,0x15
    800023ea:	38290913          	addi	s2,s2,898 # 80017768 <tickslock>
    800023ee:	a821                	j	80002406 <wakeup+0x40>
      p->state = RUNNABLE;
    800023f0:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800023f4:	8526                	mv	a0,s1
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	918080e7          	jalr	-1768(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023fe:	16848493          	addi	s1,s1,360
    80002402:	01248e63          	beq	s1,s2,8000241e <wakeup+0x58>
    acquire(&p->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	852080e7          	jalr	-1966(ra) # 80000c5a <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002410:	4c9c                	lw	a5,24(s1)
    80002412:	ff3791e3          	bne	a5,s3,800023f4 <wakeup+0x2e>
    80002416:	749c                	ld	a5,40(s1)
    80002418:	fd479ee3          	bne	a5,s4,800023f4 <wakeup+0x2e>
    8000241c:	bfd1                	j	800023f0 <wakeup+0x2a>
}
    8000241e:	70e2                	ld	ra,56(sp)
    80002420:	7442                	ld	s0,48(sp)
    80002422:	74a2                	ld	s1,40(sp)
    80002424:	7902                	ld	s2,32(sp)
    80002426:	69e2                	ld	s3,24(sp)
    80002428:	6a42                	ld	s4,16(sp)
    8000242a:	6aa2                	ld	s5,8(sp)
    8000242c:	6121                	addi	sp,sp,64
    8000242e:	8082                	ret

0000000080002430 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002430:	7179                	addi	sp,sp,-48
    80002432:	f406                	sd	ra,40(sp)
    80002434:	f022                	sd	s0,32(sp)
    80002436:	ec26                	sd	s1,24(sp)
    80002438:	e84a                	sd	s2,16(sp)
    8000243a:	e44e                	sd	s3,8(sp)
    8000243c:	1800                	addi	s0,sp,48
    8000243e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002440:	00010497          	auipc	s1,0x10
    80002444:	92848493          	addi	s1,s1,-1752 # 80011d68 <proc>
    80002448:	00015997          	auipc	s3,0x15
    8000244c:	32098993          	addi	s3,s3,800 # 80017768 <tickslock>
    acquire(&p->lock);
    80002450:	8526                	mv	a0,s1
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	808080e7          	jalr	-2040(ra) # 80000c5a <acquire>
    if(p->pid == pid){
    8000245a:	5c9c                	lw	a5,56(s1)
    8000245c:	01278d63          	beq	a5,s2,80002476 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002460:	8526                	mv	a0,s1
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	8ac080e7          	jalr	-1876(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000246a:	16848493          	addi	s1,s1,360
    8000246e:	ff3491e3          	bne	s1,s3,80002450 <kill+0x20>
  }
  return -1;
    80002472:	557d                	li	a0,-1
    80002474:	a829                	j	8000248e <kill+0x5e>
      p->killed = 1;
    80002476:	4785                	li	a5,1
    80002478:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000247a:	4c98                	lw	a4,24(s1)
    8000247c:	4785                	li	a5,1
    8000247e:	00f70f63          	beq	a4,a5,8000249c <kill+0x6c>
      release(&p->lock);
    80002482:	8526                	mv	a0,s1
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	88a080e7          	jalr	-1910(ra) # 80000d0e <release>
      return 0;
    8000248c:	4501                	li	a0,0
}
    8000248e:	70a2                	ld	ra,40(sp)
    80002490:	7402                	ld	s0,32(sp)
    80002492:	64e2                	ld	s1,24(sp)
    80002494:	6942                	ld	s2,16(sp)
    80002496:	69a2                	ld	s3,8(sp)
    80002498:	6145                	addi	sp,sp,48
    8000249a:	8082                	ret
        p->state = RUNNABLE;
    8000249c:	4789                	li	a5,2
    8000249e:	cc9c                	sw	a5,24(s1)
    800024a0:	b7cd                	j	80002482 <kill+0x52>

00000000800024a2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024a2:	7179                	addi	sp,sp,-48
    800024a4:	f406                	sd	ra,40(sp)
    800024a6:	f022                	sd	s0,32(sp)
    800024a8:	ec26                	sd	s1,24(sp)
    800024aa:	e84a                	sd	s2,16(sp)
    800024ac:	e44e                	sd	s3,8(sp)
    800024ae:	e052                	sd	s4,0(sp)
    800024b0:	1800                	addi	s0,sp,48
    800024b2:	84aa                	mv	s1,a0
    800024b4:	892e                	mv	s2,a1
    800024b6:	89b2                	mv	s3,a2
    800024b8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ba:	fffff097          	auipc	ra,0xfffff
    800024be:	56e080e7          	jalr	1390(ra) # 80001a28 <myproc>
  if(user_dst){
    800024c2:	c08d                	beqz	s1,800024e4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024c4:	86d2                	mv	a3,s4
    800024c6:	864e                	mv	a2,s3
    800024c8:	85ca                	mv	a1,s2
    800024ca:	6928                	ld	a0,80(a0)
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	250080e7          	jalr	592(ra) # 8000171c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024d4:	70a2                	ld	ra,40(sp)
    800024d6:	7402                	ld	s0,32(sp)
    800024d8:	64e2                	ld	s1,24(sp)
    800024da:	6942                	ld	s2,16(sp)
    800024dc:	69a2                	ld	s3,8(sp)
    800024de:	6a02                	ld	s4,0(sp)
    800024e0:	6145                	addi	sp,sp,48
    800024e2:	8082                	ret
    memmove((char *)dst, src, len);
    800024e4:	000a061b          	sext.w	a2,s4
    800024e8:	85ce                	mv	a1,s3
    800024ea:	854a                	mv	a0,s2
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	8ca080e7          	jalr	-1846(ra) # 80000db6 <memmove>
    return 0;
    800024f4:	8526                	mv	a0,s1
    800024f6:	bff9                	j	800024d4 <either_copyout+0x32>

00000000800024f8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024f8:	7179                	addi	sp,sp,-48
    800024fa:	f406                	sd	ra,40(sp)
    800024fc:	f022                	sd	s0,32(sp)
    800024fe:	ec26                	sd	s1,24(sp)
    80002500:	e84a                	sd	s2,16(sp)
    80002502:	e44e                	sd	s3,8(sp)
    80002504:	e052                	sd	s4,0(sp)
    80002506:	1800                	addi	s0,sp,48
    80002508:	892a                	mv	s2,a0
    8000250a:	84ae                	mv	s1,a1
    8000250c:	89b2                	mv	s3,a2
    8000250e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	518080e7          	jalr	1304(ra) # 80001a28 <myproc>
  if(user_src){
    80002518:	c08d                	beqz	s1,8000253a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000251a:	86d2                	mv	a3,s4
    8000251c:	864e                	mv	a2,s3
    8000251e:	85ca                	mv	a1,s2
    80002520:	6928                	ld	a0,80(a0)
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	286080e7          	jalr	646(ra) # 800017a8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000252a:	70a2                	ld	ra,40(sp)
    8000252c:	7402                	ld	s0,32(sp)
    8000252e:	64e2                	ld	s1,24(sp)
    80002530:	6942                	ld	s2,16(sp)
    80002532:	69a2                	ld	s3,8(sp)
    80002534:	6a02                	ld	s4,0(sp)
    80002536:	6145                	addi	sp,sp,48
    80002538:	8082                	ret
    memmove(dst, (char*)src, len);
    8000253a:	000a061b          	sext.w	a2,s4
    8000253e:	85ce                	mv	a1,s3
    80002540:	854a                	mv	a0,s2
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	874080e7          	jalr	-1932(ra) # 80000db6 <memmove>
    return 0;
    8000254a:	8526                	mv	a0,s1
    8000254c:	bff9                	j	8000252a <either_copyin+0x32>

000000008000254e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000254e:	715d                	addi	sp,sp,-80
    80002550:	e486                	sd	ra,72(sp)
    80002552:	e0a2                	sd	s0,64(sp)
    80002554:	fc26                	sd	s1,56(sp)
    80002556:	f84a                	sd	s2,48(sp)
    80002558:	f44e                	sd	s3,40(sp)
    8000255a:	f052                	sd	s4,32(sp)
    8000255c:	ec56                	sd	s5,24(sp)
    8000255e:	e85a                	sd	s6,16(sp)
    80002560:	e45e                	sd	s7,8(sp)
    80002562:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002564:	00006517          	auipc	a0,0x6
    80002568:	b6450513          	addi	a0,a0,-1180 # 800080c8 <digits+0x88>
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	026080e7          	jalr	38(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002574:	00010497          	auipc	s1,0x10
    80002578:	94c48493          	addi	s1,s1,-1716 # 80011ec0 <proc+0x158>
    8000257c:	00015917          	auipc	s2,0x15
    80002580:	34490913          	addi	s2,s2,836 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002584:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002586:	00006997          	auipc	s3,0x6
    8000258a:	ce298993          	addi	s3,s3,-798 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    8000258e:	00006a97          	auipc	s5,0x6
    80002592:	ce2a8a93          	addi	s5,s5,-798 # 80008270 <digits+0x230>
    printf("\n");
    80002596:	00006a17          	auipc	s4,0x6
    8000259a:	b32a0a13          	addi	s4,s4,-1230 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000259e:	00006b97          	auipc	s7,0x6
    800025a2:	d0ab8b93          	addi	s7,s7,-758 # 800082a8 <states.1710>
    800025a6:	a00d                	j	800025c8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025a8:	ee06a583          	lw	a1,-288(a3)
    800025ac:	8556                	mv	a0,s5
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	fe4080e7          	jalr	-28(ra) # 80000592 <printf>
    printf("\n");
    800025b6:	8552                	mv	a0,s4
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	fda080e7          	jalr	-38(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c0:	16848493          	addi	s1,s1,360
    800025c4:	03248163          	beq	s1,s2,800025e6 <procdump+0x98>
    if(p->state == UNUSED)
    800025c8:	86a6                	mv	a3,s1
    800025ca:	ec04a783          	lw	a5,-320(s1)
    800025ce:	dbed                	beqz	a5,800025c0 <procdump+0x72>
      state = "???";
    800025d0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d2:	fcfb6be3          	bltu	s6,a5,800025a8 <procdump+0x5a>
    800025d6:	1782                	slli	a5,a5,0x20
    800025d8:	9381                	srli	a5,a5,0x20
    800025da:	078e                	slli	a5,a5,0x3
    800025dc:	97de                	add	a5,a5,s7
    800025de:	6390                	ld	a2,0(a5)
    800025e0:	f661                	bnez	a2,800025a8 <procdump+0x5a>
      state = "???";
    800025e2:	864e                	mv	a2,s3
    800025e4:	b7d1                	j	800025a8 <procdump+0x5a>
  }
}
    800025e6:	60a6                	ld	ra,72(sp)
    800025e8:	6406                	ld	s0,64(sp)
    800025ea:	74e2                	ld	s1,56(sp)
    800025ec:	7942                	ld	s2,48(sp)
    800025ee:	79a2                	ld	s3,40(sp)
    800025f0:	7a02                	ld	s4,32(sp)
    800025f2:	6ae2                	ld	s5,24(sp)
    800025f4:	6b42                	ld	s6,16(sp)
    800025f6:	6ba2                	ld	s7,8(sp)
    800025f8:	6161                	addi	sp,sp,80
    800025fa:	8082                	ret

00000000800025fc <trace>:
// ysw
// Set tracemask which in the struct pro to control syscall() function 
// to print syscall infomation with marked syscall number
int
trace(int mask)
{
    800025fc:	1101                	addi	sp,sp,-32
    800025fe:	ec06                	sd	ra,24(sp)
    80002600:	e822                	sd	s0,16(sp)
    80002602:	e426                	sd	s1,8(sp)
    80002604:	e04a                	sd	s2,0(sp)
    80002606:	1000                	addi	s0,sp,32
    80002608:	892a                	mv	s2,a0
  //printf("trace %d\n", mask);
  struct proc *p = myproc();
    8000260a:	fffff097          	auipc	ra,0xfffff
    8000260e:	41e080e7          	jalr	1054(ra) # 80001a28 <myproc>
    80002612:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	646080e7          	jalr	1606(ra) # 80000c5a <acquire>
  p->tracemask = mask;
    8000261c:	0324ae23          	sw	s2,60(s1)
  release(&p->lock);
    80002620:	8526                	mv	a0,s1
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	6ec080e7          	jalr	1772(ra) # 80000d0e <release>
  return 0;
}
    8000262a:	4501                	li	a0,0
    8000262c:	60e2                	ld	ra,24(sp)
    8000262e:	6442                	ld	s0,16(sp)
    80002630:	64a2                	ld	s1,8(sp)
    80002632:	6902                	ld	s2,0(sp)
    80002634:	6105                	addi	sp,sp,32
    80002636:	8082                	ret

0000000080002638 <get_used_processes_count>:


uint64
get_used_processes_count() {
    80002638:	7179                	addi	sp,sp,-48
    8000263a:	f406                	sd	ra,40(sp)
    8000263c:	f022                	sd	s0,32(sp)
    8000263e:	ec26                	sd	s1,24(sp)
    80002640:	e84a                	sd	s2,16(sp)
    80002642:	e44e                	sd	s3,8(sp)
    80002644:	1800                	addi	s0,sp,48
  uint64 cnt = 0;
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002646:	0000f497          	auipc	s1,0xf
    8000264a:	72248493          	addi	s1,s1,1826 # 80011d68 <proc>
  uint64 cnt = 0;
    8000264e:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002650:	00015997          	auipc	s3,0x15
    80002654:	11898993          	addi	s3,s3,280 # 80017768 <tickslock>
    acquire(&p->lock);
    80002658:	8526                	mv	a0,s1
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	600080e7          	jalr	1536(ra) # 80000c5a <acquire>
    if(p->state != UNUSED) 
    80002662:	4c9c                	lw	a5,24(s1)
      cnt++;
    80002664:	00f037b3          	snez	a5,a5
    80002668:	993e                	add	s2,s2,a5
    release(&p->lock);
    8000266a:	8526                	mv	a0,s1
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	6a2080e7          	jalr	1698(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002674:	16848493          	addi	s1,s1,360
    80002678:	ff3490e3          	bne	s1,s3,80002658 <get_used_processes_count+0x20>
  }

  return cnt;
    8000267c:	854a                	mv	a0,s2
    8000267e:	70a2                	ld	ra,40(sp)
    80002680:	7402                	ld	s0,32(sp)
    80002682:	64e2                	ld	s1,24(sp)
    80002684:	6942                	ld	s2,16(sp)
    80002686:	69a2                	ld	s3,8(sp)
    80002688:	6145                	addi	sp,sp,48
    8000268a:	8082                	ret

000000008000268c <swtch>:
    8000268c:	00153023          	sd	ra,0(a0)
    80002690:	00253423          	sd	sp,8(a0)
    80002694:	e900                	sd	s0,16(a0)
    80002696:	ed04                	sd	s1,24(a0)
    80002698:	03253023          	sd	s2,32(a0)
    8000269c:	03353423          	sd	s3,40(a0)
    800026a0:	03453823          	sd	s4,48(a0)
    800026a4:	03553c23          	sd	s5,56(a0)
    800026a8:	05653023          	sd	s6,64(a0)
    800026ac:	05753423          	sd	s7,72(a0)
    800026b0:	05853823          	sd	s8,80(a0)
    800026b4:	05953c23          	sd	s9,88(a0)
    800026b8:	07a53023          	sd	s10,96(a0)
    800026bc:	07b53423          	sd	s11,104(a0)
    800026c0:	0005b083          	ld	ra,0(a1)
    800026c4:	0085b103          	ld	sp,8(a1)
    800026c8:	6980                	ld	s0,16(a1)
    800026ca:	6d84                	ld	s1,24(a1)
    800026cc:	0205b903          	ld	s2,32(a1)
    800026d0:	0285b983          	ld	s3,40(a1)
    800026d4:	0305ba03          	ld	s4,48(a1)
    800026d8:	0385ba83          	ld	s5,56(a1)
    800026dc:	0405bb03          	ld	s6,64(a1)
    800026e0:	0485bb83          	ld	s7,72(a1)
    800026e4:	0505bc03          	ld	s8,80(a1)
    800026e8:	0585bc83          	ld	s9,88(a1)
    800026ec:	0605bd03          	ld	s10,96(a1)
    800026f0:	0685bd83          	ld	s11,104(a1)
    800026f4:	8082                	ret

00000000800026f6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026f6:	1141                	addi	sp,sp,-16
    800026f8:	e406                	sd	ra,8(sp)
    800026fa:	e022                	sd	s0,0(sp)
    800026fc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026fe:	00006597          	auipc	a1,0x6
    80002702:	bd258593          	addi	a1,a1,-1070 # 800082d0 <states.1710+0x28>
    80002706:	00015517          	auipc	a0,0x15
    8000270a:	06250513          	addi	a0,a0,98 # 80017768 <tickslock>
    8000270e:	ffffe097          	auipc	ra,0xffffe
    80002712:	4bc080e7          	jalr	1212(ra) # 80000bca <initlock>
}
    80002716:	60a2                	ld	ra,8(sp)
    80002718:	6402                	ld	s0,0(sp)
    8000271a:	0141                	addi	sp,sp,16
    8000271c:	8082                	ret

000000008000271e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000271e:	1141                	addi	sp,sp,-16
    80002720:	e422                	sd	s0,8(sp)
    80002722:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002724:	00003797          	auipc	a5,0x3
    80002728:	54c78793          	addi	a5,a5,1356 # 80005c70 <kernelvec>
    8000272c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002730:	6422                	ld	s0,8(sp)
    80002732:	0141                	addi	sp,sp,16
    80002734:	8082                	ret

0000000080002736 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002736:	1141                	addi	sp,sp,-16
    80002738:	e406                	sd	ra,8(sp)
    8000273a:	e022                	sd	s0,0(sp)
    8000273c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000273e:	fffff097          	auipc	ra,0xfffff
    80002742:	2ea080e7          	jalr	746(ra) # 80001a28 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002746:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000274a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000274c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002750:	00005617          	auipc	a2,0x5
    80002754:	8b060613          	addi	a2,a2,-1872 # 80007000 <_trampoline>
    80002758:	00005697          	auipc	a3,0x5
    8000275c:	8a868693          	addi	a3,a3,-1880 # 80007000 <_trampoline>
    80002760:	8e91                	sub	a3,a3,a2
    80002762:	040007b7          	lui	a5,0x4000
    80002766:	17fd                	addi	a5,a5,-1
    80002768:	07b2                	slli	a5,a5,0xc
    8000276a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000276c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002770:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002772:	180026f3          	csrr	a3,satp
    80002776:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002778:	6d38                	ld	a4,88(a0)
    8000277a:	6134                	ld	a3,64(a0)
    8000277c:	6585                	lui	a1,0x1
    8000277e:	96ae                	add	a3,a3,a1
    80002780:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002782:	6d38                	ld	a4,88(a0)
    80002784:	00000697          	auipc	a3,0x0
    80002788:	13868693          	addi	a3,a3,312 # 800028bc <usertrap>
    8000278c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000278e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002790:	8692                	mv	a3,tp
    80002792:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002794:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002798:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000279c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027a0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027a4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027a6:	6f18                	ld	a4,24(a4)
    800027a8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027ac:	692c                	ld	a1,80(a0)
    800027ae:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027b0:	00005717          	auipc	a4,0x5
    800027b4:	8e070713          	addi	a4,a4,-1824 # 80007090 <userret>
    800027b8:	8f11                	sub	a4,a4,a2
    800027ba:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027bc:	577d                	li	a4,-1
    800027be:	177e                	slli	a4,a4,0x3f
    800027c0:	8dd9                	or	a1,a1,a4
    800027c2:	02000537          	lui	a0,0x2000
    800027c6:	157d                	addi	a0,a0,-1
    800027c8:	0536                	slli	a0,a0,0xd
    800027ca:	9782                	jalr	a5
}
    800027cc:	60a2                	ld	ra,8(sp)
    800027ce:	6402                	ld	s0,0(sp)
    800027d0:	0141                	addi	sp,sp,16
    800027d2:	8082                	ret

00000000800027d4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027d4:	1101                	addi	sp,sp,-32
    800027d6:	ec06                	sd	ra,24(sp)
    800027d8:	e822                	sd	s0,16(sp)
    800027da:	e426                	sd	s1,8(sp)
    800027dc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027de:	00015497          	auipc	s1,0x15
    800027e2:	f8a48493          	addi	s1,s1,-118 # 80017768 <tickslock>
    800027e6:	8526                	mv	a0,s1
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	472080e7          	jalr	1138(ra) # 80000c5a <acquire>
  ticks++;
    800027f0:	00007517          	auipc	a0,0x7
    800027f4:	83050513          	addi	a0,a0,-2000 # 80009020 <ticks>
    800027f8:	411c                	lw	a5,0(a0)
    800027fa:	2785                	addiw	a5,a5,1
    800027fc:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027fe:	00000097          	auipc	ra,0x0
    80002802:	bc8080e7          	jalr	-1080(ra) # 800023c6 <wakeup>
  release(&tickslock);
    80002806:	8526                	mv	a0,s1
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	506080e7          	jalr	1286(ra) # 80000d0e <release>
}
    80002810:	60e2                	ld	ra,24(sp)
    80002812:	6442                	ld	s0,16(sp)
    80002814:	64a2                	ld	s1,8(sp)
    80002816:	6105                	addi	sp,sp,32
    80002818:	8082                	ret

000000008000281a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000281a:	1101                	addi	sp,sp,-32
    8000281c:	ec06                	sd	ra,24(sp)
    8000281e:	e822                	sd	s0,16(sp)
    80002820:	e426                	sd	s1,8(sp)
    80002822:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002824:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002828:	00074d63          	bltz	a4,80002842 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000282c:	57fd                	li	a5,-1
    8000282e:	17fe                	slli	a5,a5,0x3f
    80002830:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002832:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002834:	06f70363          	beq	a4,a5,8000289a <devintr+0x80>
  }
}
    80002838:	60e2                	ld	ra,24(sp)
    8000283a:	6442                	ld	s0,16(sp)
    8000283c:	64a2                	ld	s1,8(sp)
    8000283e:	6105                	addi	sp,sp,32
    80002840:	8082                	ret
     (scause & 0xff) == 9){
    80002842:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002846:	46a5                	li	a3,9
    80002848:	fed792e3          	bne	a5,a3,8000282c <devintr+0x12>
    int irq = plic_claim();
    8000284c:	00003097          	auipc	ra,0x3
    80002850:	52c080e7          	jalr	1324(ra) # 80005d78 <plic_claim>
    80002854:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002856:	47a9                	li	a5,10
    80002858:	02f50763          	beq	a0,a5,80002886 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000285c:	4785                	li	a5,1
    8000285e:	02f50963          	beq	a0,a5,80002890 <devintr+0x76>
    return 1;
    80002862:	4505                	li	a0,1
    } else if(irq){
    80002864:	d8f1                	beqz	s1,80002838 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002866:	85a6                	mv	a1,s1
    80002868:	00006517          	auipc	a0,0x6
    8000286c:	a7050513          	addi	a0,a0,-1424 # 800082d8 <states.1710+0x30>
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	d22080e7          	jalr	-734(ra) # 80000592 <printf>
      plic_complete(irq);
    80002878:	8526                	mv	a0,s1
    8000287a:	00003097          	auipc	ra,0x3
    8000287e:	522080e7          	jalr	1314(ra) # 80005d9c <plic_complete>
    return 1;
    80002882:	4505                	li	a0,1
    80002884:	bf55                	j	80002838 <devintr+0x1e>
      uartintr();
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	14e080e7          	jalr	334(ra) # 800009d4 <uartintr>
    8000288e:	b7ed                	j	80002878 <devintr+0x5e>
      virtio_disk_intr();
    80002890:	00004097          	auipc	ra,0x4
    80002894:	9a6080e7          	jalr	-1626(ra) # 80006236 <virtio_disk_intr>
    80002898:	b7c5                	j	80002878 <devintr+0x5e>
    if(cpuid() == 0){
    8000289a:	fffff097          	auipc	ra,0xfffff
    8000289e:	162080e7          	jalr	354(ra) # 800019fc <cpuid>
    800028a2:	c901                	beqz	a0,800028b2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028a4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028a8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028aa:	14479073          	csrw	sip,a5
    return 2;
    800028ae:	4509                	li	a0,2
    800028b0:	b761                	j	80002838 <devintr+0x1e>
      clockintr();
    800028b2:	00000097          	auipc	ra,0x0
    800028b6:	f22080e7          	jalr	-222(ra) # 800027d4 <clockintr>
    800028ba:	b7ed                	j	800028a4 <devintr+0x8a>

00000000800028bc <usertrap>:
{
    800028bc:	1101                	addi	sp,sp,-32
    800028be:	ec06                	sd	ra,24(sp)
    800028c0:	e822                	sd	s0,16(sp)
    800028c2:	e426                	sd	s1,8(sp)
    800028c4:	e04a                	sd	s2,0(sp)
    800028c6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028cc:	1007f793          	andi	a5,a5,256
    800028d0:	e3ad                	bnez	a5,80002932 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028d2:	00003797          	auipc	a5,0x3
    800028d6:	39e78793          	addi	a5,a5,926 # 80005c70 <kernelvec>
    800028da:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028de:	fffff097          	auipc	ra,0xfffff
    800028e2:	14a080e7          	jalr	330(ra) # 80001a28 <myproc>
    800028e6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028e8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ea:	14102773          	csrr	a4,sepc
    800028ee:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028f4:	47a1                	li	a5,8
    800028f6:	04f71c63          	bne	a4,a5,8000294e <usertrap+0x92>
    if(p->killed)
    800028fa:	591c                	lw	a5,48(a0)
    800028fc:	e3b9                	bnez	a5,80002942 <usertrap+0x86>
    p->trapframe->epc += 4;
    800028fe:	6cb8                	ld	a4,88(s1)
    80002900:	6f1c                	ld	a5,24(a4)
    80002902:	0791                	addi	a5,a5,4
    80002904:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002906:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000290a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000290e:	10079073          	csrw	sstatus,a5
    syscall();
    80002912:	00000097          	auipc	ra,0x0
    80002916:	2e0080e7          	jalr	736(ra) # 80002bf2 <syscall>
  if(p->killed)
    8000291a:	589c                	lw	a5,48(s1)
    8000291c:	ebc1                	bnez	a5,800029ac <usertrap+0xf0>
  usertrapret();
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	e18080e7          	jalr	-488(ra) # 80002736 <usertrapret>
}
    80002926:	60e2                	ld	ra,24(sp)
    80002928:	6442                	ld	s0,16(sp)
    8000292a:	64a2                	ld	s1,8(sp)
    8000292c:	6902                	ld	s2,0(sp)
    8000292e:	6105                	addi	sp,sp,32
    80002930:	8082                	ret
    panic("usertrap: not from user mode");
    80002932:	00006517          	auipc	a0,0x6
    80002936:	9c650513          	addi	a0,a0,-1594 # 800082f8 <states.1710+0x50>
    8000293a:	ffffe097          	auipc	ra,0xffffe
    8000293e:	c0e080e7          	jalr	-1010(ra) # 80000548 <panic>
      exit(-1);
    80002942:	557d                	li	a0,-1
    80002944:	fffff097          	auipc	ra,0xfffff
    80002948:	7b6080e7          	jalr	1974(ra) # 800020fa <exit>
    8000294c:	bf4d                	j	800028fe <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000294e:	00000097          	auipc	ra,0x0
    80002952:	ecc080e7          	jalr	-308(ra) # 8000281a <devintr>
    80002956:	892a                	mv	s2,a0
    80002958:	c501                	beqz	a0,80002960 <usertrap+0xa4>
  if(p->killed)
    8000295a:	589c                	lw	a5,48(s1)
    8000295c:	c3a1                	beqz	a5,8000299c <usertrap+0xe0>
    8000295e:	a815                	j	80002992 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002960:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002964:	5c90                	lw	a2,56(s1)
    80002966:	00006517          	auipc	a0,0x6
    8000296a:	9b250513          	addi	a0,a0,-1614 # 80008318 <states.1710+0x70>
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	c24080e7          	jalr	-988(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002976:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000297a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000297e:	00006517          	auipc	a0,0x6
    80002982:	9ca50513          	addi	a0,a0,-1590 # 80008348 <states.1710+0xa0>
    80002986:	ffffe097          	auipc	ra,0xffffe
    8000298a:	c0c080e7          	jalr	-1012(ra) # 80000592 <printf>
    p->killed = 1;
    8000298e:	4785                	li	a5,1
    80002990:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002992:	557d                	li	a0,-1
    80002994:	fffff097          	auipc	ra,0xfffff
    80002998:	766080e7          	jalr	1894(ra) # 800020fa <exit>
  if(which_dev == 2)
    8000299c:	4789                	li	a5,2
    8000299e:	f8f910e3          	bne	s2,a5,8000291e <usertrap+0x62>
    yield();
    800029a2:	00000097          	auipc	ra,0x0
    800029a6:	862080e7          	jalr	-1950(ra) # 80002204 <yield>
    800029aa:	bf95                	j	8000291e <usertrap+0x62>
  int which_dev = 0;
    800029ac:	4901                	li	s2,0
    800029ae:	b7d5                	j	80002992 <usertrap+0xd6>

00000000800029b0 <kerneltrap>:
{
    800029b0:	7179                	addi	sp,sp,-48
    800029b2:	f406                	sd	ra,40(sp)
    800029b4:	f022                	sd	s0,32(sp)
    800029b6:	ec26                	sd	s1,24(sp)
    800029b8:	e84a                	sd	s2,16(sp)
    800029ba:	e44e                	sd	s3,8(sp)
    800029bc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029be:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029c6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029ca:	1004f793          	andi	a5,s1,256
    800029ce:	cb85                	beqz	a5,800029fe <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029d4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029d6:	ef85                	bnez	a5,80002a0e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029d8:	00000097          	auipc	ra,0x0
    800029dc:	e42080e7          	jalr	-446(ra) # 8000281a <devintr>
    800029e0:	cd1d                	beqz	a0,80002a1e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029e2:	4789                	li	a5,2
    800029e4:	06f50a63          	beq	a0,a5,80002a58 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029e8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ec:	10049073          	csrw	sstatus,s1
}
    800029f0:	70a2                	ld	ra,40(sp)
    800029f2:	7402                	ld	s0,32(sp)
    800029f4:	64e2                	ld	s1,24(sp)
    800029f6:	6942                	ld	s2,16(sp)
    800029f8:	69a2                	ld	s3,8(sp)
    800029fa:	6145                	addi	sp,sp,48
    800029fc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029fe:	00006517          	auipc	a0,0x6
    80002a02:	96a50513          	addi	a0,a0,-1686 # 80008368 <states.1710+0xc0>
    80002a06:	ffffe097          	auipc	ra,0xffffe
    80002a0a:	b42080e7          	jalr	-1214(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	98250513          	addi	a0,a0,-1662 # 80008390 <states.1710+0xe8>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b32080e7          	jalr	-1230(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002a1e:	85ce                	mv	a1,s3
    80002a20:	00006517          	auipc	a0,0x6
    80002a24:	99050513          	addi	a0,a0,-1648 # 800083b0 <states.1710+0x108>
    80002a28:	ffffe097          	auipc	ra,0xffffe
    80002a2c:	b6a080e7          	jalr	-1174(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a30:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a34:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a38:	00006517          	auipc	a0,0x6
    80002a3c:	98850513          	addi	a0,a0,-1656 # 800083c0 <states.1710+0x118>
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	b52080e7          	jalr	-1198(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002a48:	00006517          	auipc	a0,0x6
    80002a4c:	99050513          	addi	a0,a0,-1648 # 800083d8 <states.1710+0x130>
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	af8080e7          	jalr	-1288(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a58:	fffff097          	auipc	ra,0xfffff
    80002a5c:	fd0080e7          	jalr	-48(ra) # 80001a28 <myproc>
    80002a60:	d541                	beqz	a0,800029e8 <kerneltrap+0x38>
    80002a62:	fffff097          	auipc	ra,0xfffff
    80002a66:	fc6080e7          	jalr	-58(ra) # 80001a28 <myproc>
    80002a6a:	4d18                	lw	a4,24(a0)
    80002a6c:	478d                	li	a5,3
    80002a6e:	f6f71de3          	bne	a4,a5,800029e8 <kerneltrap+0x38>
    yield();
    80002a72:	fffff097          	auipc	ra,0xfffff
    80002a76:	792080e7          	jalr	1938(ra) # 80002204 <yield>
    80002a7a:	b7bd                	j	800029e8 <kerneltrap+0x38>

0000000080002a7c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a7c:	1101                	addi	sp,sp,-32
    80002a7e:	ec06                	sd	ra,24(sp)
    80002a80:	e822                	sd	s0,16(sp)
    80002a82:	e426                	sd	s1,8(sp)
    80002a84:	1000                	addi	s0,sp,32
    80002a86:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a88:	fffff097          	auipc	ra,0xfffff
    80002a8c:	fa0080e7          	jalr	-96(ra) # 80001a28 <myproc>
  switch (n) {
    80002a90:	4795                	li	a5,5
    80002a92:	0497e163          	bltu	a5,s1,80002ad4 <argraw+0x58>
    80002a96:	048a                	slli	s1,s1,0x2
    80002a98:	00006717          	auipc	a4,0x6
    80002a9c:	a4070713          	addi	a4,a4,-1472 # 800084d8 <states.1710+0x230>
    80002aa0:	94ba                	add	s1,s1,a4
    80002aa2:	409c                	lw	a5,0(s1)
    80002aa4:	97ba                	add	a5,a5,a4
    80002aa6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002aa8:	6d3c                	ld	a5,88(a0)
    80002aaa:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002aac:	60e2                	ld	ra,24(sp)
    80002aae:	6442                	ld	s0,16(sp)
    80002ab0:	64a2                	ld	s1,8(sp)
    80002ab2:	6105                	addi	sp,sp,32
    80002ab4:	8082                	ret
    return p->trapframe->a1;
    80002ab6:	6d3c                	ld	a5,88(a0)
    80002ab8:	7fa8                	ld	a0,120(a5)
    80002aba:	bfcd                	j	80002aac <argraw+0x30>
    return p->trapframe->a2;
    80002abc:	6d3c                	ld	a5,88(a0)
    80002abe:	63c8                	ld	a0,128(a5)
    80002ac0:	b7f5                	j	80002aac <argraw+0x30>
    return p->trapframe->a3;
    80002ac2:	6d3c                	ld	a5,88(a0)
    80002ac4:	67c8                	ld	a0,136(a5)
    80002ac6:	b7dd                	j	80002aac <argraw+0x30>
    return p->trapframe->a4;
    80002ac8:	6d3c                	ld	a5,88(a0)
    80002aca:	6bc8                	ld	a0,144(a5)
    80002acc:	b7c5                	j	80002aac <argraw+0x30>
    return p->trapframe->a5;
    80002ace:	6d3c                	ld	a5,88(a0)
    80002ad0:	6fc8                	ld	a0,152(a5)
    80002ad2:	bfe9                	j	80002aac <argraw+0x30>
  panic("argraw");
    80002ad4:	00006517          	auipc	a0,0x6
    80002ad8:	91450513          	addi	a0,a0,-1772 # 800083e8 <states.1710+0x140>
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	a6c080e7          	jalr	-1428(ra) # 80000548 <panic>

0000000080002ae4 <fetchaddr>:
{
    80002ae4:	1101                	addi	sp,sp,-32
    80002ae6:	ec06                	sd	ra,24(sp)
    80002ae8:	e822                	sd	s0,16(sp)
    80002aea:	e426                	sd	s1,8(sp)
    80002aec:	e04a                	sd	s2,0(sp)
    80002aee:	1000                	addi	s0,sp,32
    80002af0:	84aa                	mv	s1,a0
    80002af2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002af4:	fffff097          	auipc	ra,0xfffff
    80002af8:	f34080e7          	jalr	-204(ra) # 80001a28 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002afc:	653c                	ld	a5,72(a0)
    80002afe:	02f4f863          	bgeu	s1,a5,80002b2e <fetchaddr+0x4a>
    80002b02:	00848713          	addi	a4,s1,8
    80002b06:	02e7e663          	bltu	a5,a4,80002b32 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b0a:	46a1                	li	a3,8
    80002b0c:	8626                	mv	a2,s1
    80002b0e:	85ca                	mv	a1,s2
    80002b10:	6928                	ld	a0,80(a0)
    80002b12:	fffff097          	auipc	ra,0xfffff
    80002b16:	c96080e7          	jalr	-874(ra) # 800017a8 <copyin>
    80002b1a:	00a03533          	snez	a0,a0
    80002b1e:	40a00533          	neg	a0,a0
}
    80002b22:	60e2                	ld	ra,24(sp)
    80002b24:	6442                	ld	s0,16(sp)
    80002b26:	64a2                	ld	s1,8(sp)
    80002b28:	6902                	ld	s2,0(sp)
    80002b2a:	6105                	addi	sp,sp,32
    80002b2c:	8082                	ret
    return -1;
    80002b2e:	557d                	li	a0,-1
    80002b30:	bfcd                	j	80002b22 <fetchaddr+0x3e>
    80002b32:	557d                	li	a0,-1
    80002b34:	b7fd                	j	80002b22 <fetchaddr+0x3e>

0000000080002b36 <fetchstr>:
{
    80002b36:	7179                	addi	sp,sp,-48
    80002b38:	f406                	sd	ra,40(sp)
    80002b3a:	f022                	sd	s0,32(sp)
    80002b3c:	ec26                	sd	s1,24(sp)
    80002b3e:	e84a                	sd	s2,16(sp)
    80002b40:	e44e                	sd	s3,8(sp)
    80002b42:	1800                	addi	s0,sp,48
    80002b44:	892a                	mv	s2,a0
    80002b46:	84ae                	mv	s1,a1
    80002b48:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	ede080e7          	jalr	-290(ra) # 80001a28 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b52:	86ce                	mv	a3,s3
    80002b54:	864a                	mv	a2,s2
    80002b56:	85a6                	mv	a1,s1
    80002b58:	6928                	ld	a0,80(a0)
    80002b5a:	fffff097          	auipc	ra,0xfffff
    80002b5e:	cda080e7          	jalr	-806(ra) # 80001834 <copyinstr>
  if(err < 0)
    80002b62:	00054763          	bltz	a0,80002b70 <fetchstr+0x3a>
  return strlen(buf);
    80002b66:	8526                	mv	a0,s1
    80002b68:	ffffe097          	auipc	ra,0xffffe
    80002b6c:	376080e7          	jalr	886(ra) # 80000ede <strlen>
}
    80002b70:	70a2                	ld	ra,40(sp)
    80002b72:	7402                	ld	s0,32(sp)
    80002b74:	64e2                	ld	s1,24(sp)
    80002b76:	6942                	ld	s2,16(sp)
    80002b78:	69a2                	ld	s3,8(sp)
    80002b7a:	6145                	addi	sp,sp,48
    80002b7c:	8082                	ret

0000000080002b7e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b7e:	1101                	addi	sp,sp,-32
    80002b80:	ec06                	sd	ra,24(sp)
    80002b82:	e822                	sd	s0,16(sp)
    80002b84:	e426                	sd	s1,8(sp)
    80002b86:	1000                	addi	s0,sp,32
    80002b88:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b8a:	00000097          	auipc	ra,0x0
    80002b8e:	ef2080e7          	jalr	-270(ra) # 80002a7c <argraw>
    80002b92:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b94:	4501                	li	a0,0
    80002b96:	60e2                	ld	ra,24(sp)
    80002b98:	6442                	ld	s0,16(sp)
    80002b9a:	64a2                	ld	s1,8(sp)
    80002b9c:	6105                	addi	sp,sp,32
    80002b9e:	8082                	ret

0000000080002ba0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ba0:	1101                	addi	sp,sp,-32
    80002ba2:	ec06                	sd	ra,24(sp)
    80002ba4:	e822                	sd	s0,16(sp)
    80002ba6:	e426                	sd	s1,8(sp)
    80002ba8:	1000                	addi	s0,sp,32
    80002baa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bac:	00000097          	auipc	ra,0x0
    80002bb0:	ed0080e7          	jalr	-304(ra) # 80002a7c <argraw>
    80002bb4:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bb6:	4501                	li	a0,0
    80002bb8:	60e2                	ld	ra,24(sp)
    80002bba:	6442                	ld	s0,16(sp)
    80002bbc:	64a2                	ld	s1,8(sp)
    80002bbe:	6105                	addi	sp,sp,32
    80002bc0:	8082                	ret

0000000080002bc2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bc2:	1101                	addi	sp,sp,-32
    80002bc4:	ec06                	sd	ra,24(sp)
    80002bc6:	e822                	sd	s0,16(sp)
    80002bc8:	e426                	sd	s1,8(sp)
    80002bca:	e04a                	sd	s2,0(sp)
    80002bcc:	1000                	addi	s0,sp,32
    80002bce:	84ae                	mv	s1,a1
    80002bd0:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bd2:	00000097          	auipc	ra,0x0
    80002bd6:	eaa080e7          	jalr	-342(ra) # 80002a7c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bda:	864a                	mv	a2,s2
    80002bdc:	85a6                	mv	a1,s1
    80002bde:	00000097          	auipc	ra,0x0
    80002be2:	f58080e7          	jalr	-168(ra) # 80002b36 <fetchstr>
}
    80002be6:	60e2                	ld	ra,24(sp)
    80002be8:	6442                	ld	s0,16(sp)
    80002bea:	64a2                	ld	s1,8(sp)
    80002bec:	6902                	ld	s2,0(sp)
    80002bee:	6105                	addi	sp,sp,32
    80002bf0:	8082                	ret

0000000080002bf2 <syscall>:
};
//static int syscallCounts = 21;

void
syscall(void)
{
    80002bf2:	7139                	addi	sp,sp,-64
    80002bf4:	fc06                	sd	ra,56(sp)
    80002bf6:	f822                	sd	s0,48(sp)
    80002bf8:	f426                	sd	s1,40(sp)
    80002bfa:	f04a                	sd	s2,32(sp)
    80002bfc:	ec4e                	sd	s3,24(sp)
    80002bfe:	e852                	sd	s4,16(sp)
    80002c00:	e456                	sd	s5,8(sp)
    80002c02:	0080                	addi	s0,sp,64
  int num;
  int mask; //ysw : use for trap
  struct proc *p = myproc();
    80002c04:	fffff097          	auipc	ra,0xfffff
    80002c08:	e24080e7          	jalr	-476(ra) # 80001a28 <myproc>
    80002c0c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c0e:	05853903          	ld	s2,88(a0)
    80002c12:	0a893783          	ld	a5,168(s2)
    80002c16:	00078a1b          	sext.w	s4,a5
  mask = p->tracemask;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c1a:	37fd                	addiw	a5,a5,-1
    80002c1c:	4759                	li	a4,22
    80002c1e:	06f76363          	bltu	a4,a5,80002c84 <syscall+0x92>
    80002c22:	003a1713          	slli	a4,s4,0x3
    80002c26:	00006797          	auipc	a5,0x6
    80002c2a:	8ca78793          	addi	a5,a5,-1846 # 800084f0 <syscalls>
    80002c2e:	97ba                	add	a5,a5,a4
    80002c30:	639c                	ld	a5,0(a5)
    80002c32:	cba9                	beqz	a5,80002c84 <syscall+0x92>
  mask = p->tracemask;
    80002c34:	03c52983          	lw	s3,60(a0)
    //printf("%d : system call %s : mask %d\n", p->pid, syscallnumber_to_name[num], mask);
    int temp = p->trapframe->a0;
    80002c38:	07093a83          	ld	s5,112(s2)
    p->trapframe->a0 = syscalls[num]();
    80002c3c:	9782                	jalr	a5
    80002c3e:	06a93823          	sd	a0,112(s2)
    if((mask & (1<<num)) || (num == SYS_trace && (temp & (1<<num)))) {
    80002c42:	4149d9bb          	sraw	s3,s3,s4
    80002c46:	0019f993          	andi	s3,s3,1
    80002c4a:	00099963          	bnez	s3,80002c5c <syscall+0x6a>
    80002c4e:	47d9                	li	a5,22
    80002c50:	04fa1963          	bne	s4,a5,80002ca2 <syscall+0xb0>
    80002c54:	029a9793          	slli	a5,s5,0x29
    80002c58:	0407d563          	bgez	a5,80002ca2 <syscall+0xb0>
      printf("%d: syscall %s -> %d\n", p->pid, syscallnumber_to_name[num], p->trapframe->a0);
    80002c5c:	6cb8                	ld	a4,88(s1)
    80002c5e:	0a0e                	slli	s4,s4,0x3
    80002c60:	00006797          	auipc	a5,0x6
    80002c64:	89078793          	addi	a5,a5,-1904 # 800084f0 <syscalls>
    80002c68:	9a3e                	add	s4,s4,a5
    80002c6a:	7b34                	ld	a3,112(a4)
    80002c6c:	0c0a3603          	ld	a2,192(s4)
    80002c70:	5c8c                	lw	a1,56(s1)
    80002c72:	00005517          	auipc	a0,0x5
    80002c76:	77e50513          	addi	a0,a0,1918 # 800083f0 <states.1710+0x148>
    80002c7a:	ffffe097          	auipc	ra,0xffffe
    80002c7e:	918080e7          	jalr	-1768(ra) # 80000592 <printf>
    80002c82:	a005                	j	80002ca2 <syscall+0xb0>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c84:	86d2                	mv	a3,s4
    80002c86:	15848613          	addi	a2,s1,344
    80002c8a:	5c8c                	lw	a1,56(s1)
    80002c8c:	00005517          	auipc	a0,0x5
    80002c90:	77c50513          	addi	a0,a0,1916 # 80008408 <states.1710+0x160>
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	8fe080e7          	jalr	-1794(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c9c:	6cbc                	ld	a5,88(s1)
    80002c9e:	577d                	li	a4,-1
    80002ca0:	fbb8                	sd	a4,112(a5)
  }
    80002ca2:	70e2                	ld	ra,56(sp)
    80002ca4:	7442                	ld	s0,48(sp)
    80002ca6:	74a2                	ld	s1,40(sp)
    80002ca8:	7902                	ld	s2,32(sp)
    80002caa:	69e2                	ld	s3,24(sp)
    80002cac:	6a42                	ld	s4,16(sp)
    80002cae:	6aa2                	ld	s5,8(sp)
    80002cb0:	6121                	addi	sp,sp,64
    80002cb2:	8082                	ret

0000000080002cb4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cb4:	1101                	addi	sp,sp,-32
    80002cb6:	ec06                	sd	ra,24(sp)
    80002cb8:	e822                	sd	s0,16(sp)
    80002cba:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002cbc:	fec40593          	addi	a1,s0,-20
    80002cc0:	4501                	li	a0,0
    80002cc2:	00000097          	auipc	ra,0x0
    80002cc6:	ebc080e7          	jalr	-324(ra) # 80002b7e <argint>
    return -1;
    80002cca:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ccc:	00054963          	bltz	a0,80002cde <sys_exit+0x2a>
  exit(n);
    80002cd0:	fec42503          	lw	a0,-20(s0)
    80002cd4:	fffff097          	auipc	ra,0xfffff
    80002cd8:	426080e7          	jalr	1062(ra) # 800020fa <exit>
  return 0;  // not reached
    80002cdc:	4781                	li	a5,0
}
    80002cde:	853e                	mv	a0,a5
    80002ce0:	60e2                	ld	ra,24(sp)
    80002ce2:	6442                	ld	s0,16(sp)
    80002ce4:	6105                	addi	sp,sp,32
    80002ce6:	8082                	ret

0000000080002ce8 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ce8:	1141                	addi	sp,sp,-16
    80002cea:	e406                	sd	ra,8(sp)
    80002cec:	e022                	sd	s0,0(sp)
    80002cee:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	d38080e7          	jalr	-712(ra) # 80001a28 <myproc>
}
    80002cf8:	5d08                	lw	a0,56(a0)
    80002cfa:	60a2                	ld	ra,8(sp)
    80002cfc:	6402                	ld	s0,0(sp)
    80002cfe:	0141                	addi	sp,sp,16
    80002d00:	8082                	ret

0000000080002d02 <sys_fork>:

uint64
sys_fork(void)
{
    80002d02:	1141                	addi	sp,sp,-16
    80002d04:	e406                	sd	ra,8(sp)
    80002d06:	e022                	sd	s0,0(sp)
    80002d08:	0800                	addi	s0,sp,16
  return fork();
    80002d0a:	fffff097          	auipc	ra,0xfffff
    80002d0e:	0e2080e7          	jalr	226(ra) # 80001dec <fork>
}
    80002d12:	60a2                	ld	ra,8(sp)
    80002d14:	6402                	ld	s0,0(sp)
    80002d16:	0141                	addi	sp,sp,16
    80002d18:	8082                	ret

0000000080002d1a <sys_wait>:

uint64
sys_wait(void)
{
    80002d1a:	1101                	addi	sp,sp,-32
    80002d1c:	ec06                	sd	ra,24(sp)
    80002d1e:	e822                	sd	s0,16(sp)
    80002d20:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d22:	fe840593          	addi	a1,s0,-24
    80002d26:	4501                	li	a0,0
    80002d28:	00000097          	auipc	ra,0x0
    80002d2c:	e78080e7          	jalr	-392(ra) # 80002ba0 <argaddr>
    80002d30:	87aa                	mv	a5,a0
    return -1;
    80002d32:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d34:	0007c863          	bltz	a5,80002d44 <sys_wait+0x2a>
  return wait(p);
    80002d38:	fe843503          	ld	a0,-24(s0)
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	582080e7          	jalr	1410(ra) # 800022be <wait>
}
    80002d44:	60e2                	ld	ra,24(sp)
    80002d46:	6442                	ld	s0,16(sp)
    80002d48:	6105                	addi	sp,sp,32
    80002d4a:	8082                	ret

0000000080002d4c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d4c:	7179                	addi	sp,sp,-48
    80002d4e:	f406                	sd	ra,40(sp)
    80002d50:	f022                	sd	s0,32(sp)
    80002d52:	ec26                	sd	s1,24(sp)
    80002d54:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d56:	fdc40593          	addi	a1,s0,-36
    80002d5a:	4501                	li	a0,0
    80002d5c:	00000097          	auipc	ra,0x0
    80002d60:	e22080e7          	jalr	-478(ra) # 80002b7e <argint>
    80002d64:	87aa                	mv	a5,a0
    return -1;
    80002d66:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d68:	0207c063          	bltz	a5,80002d88 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	cbc080e7          	jalr	-836(ra) # 80001a28 <myproc>
    80002d74:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d76:	fdc42503          	lw	a0,-36(s0)
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	ffe080e7          	jalr	-2(ra) # 80001d78 <growproc>
    80002d82:	00054863          	bltz	a0,80002d92 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d86:	8526                	mv	a0,s1
}
    80002d88:	70a2                	ld	ra,40(sp)
    80002d8a:	7402                	ld	s0,32(sp)
    80002d8c:	64e2                	ld	s1,24(sp)
    80002d8e:	6145                	addi	sp,sp,48
    80002d90:	8082                	ret
    return -1;
    80002d92:	557d                	li	a0,-1
    80002d94:	bfd5                	j	80002d88 <sys_sbrk+0x3c>

0000000080002d96 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d96:	7139                	addi	sp,sp,-64
    80002d98:	fc06                	sd	ra,56(sp)
    80002d9a:	f822                	sd	s0,48(sp)
    80002d9c:	f426                	sd	s1,40(sp)
    80002d9e:	f04a                	sd	s2,32(sp)
    80002da0:	ec4e                	sd	s3,24(sp)
    80002da2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002da4:	fcc40593          	addi	a1,s0,-52
    80002da8:	4501                	li	a0,0
    80002daa:	00000097          	auipc	ra,0x0
    80002dae:	dd4080e7          	jalr	-556(ra) # 80002b7e <argint>
    return -1;
    80002db2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002db4:	06054563          	bltz	a0,80002e1e <sys_sleep+0x88>
  acquire(&tickslock);
    80002db8:	00015517          	auipc	a0,0x15
    80002dbc:	9b050513          	addi	a0,a0,-1616 # 80017768 <tickslock>
    80002dc0:	ffffe097          	auipc	ra,0xffffe
    80002dc4:	e9a080e7          	jalr	-358(ra) # 80000c5a <acquire>
  ticks0 = ticks;
    80002dc8:	00006917          	auipc	s2,0x6
    80002dcc:	25892903          	lw	s2,600(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002dd0:	fcc42783          	lw	a5,-52(s0)
    80002dd4:	cf85                	beqz	a5,80002e0c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dd6:	00015997          	auipc	s3,0x15
    80002dda:	99298993          	addi	s3,s3,-1646 # 80017768 <tickslock>
    80002dde:	00006497          	auipc	s1,0x6
    80002de2:	24248493          	addi	s1,s1,578 # 80009020 <ticks>
    if(myproc()->killed){
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	c42080e7          	jalr	-958(ra) # 80001a28 <myproc>
    80002dee:	591c                	lw	a5,48(a0)
    80002df0:	ef9d                	bnez	a5,80002e2e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002df2:	85ce                	mv	a1,s3
    80002df4:	8526                	mv	a0,s1
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	44a080e7          	jalr	1098(ra) # 80002240 <sleep>
  while(ticks - ticks0 < n){
    80002dfe:	409c                	lw	a5,0(s1)
    80002e00:	412787bb          	subw	a5,a5,s2
    80002e04:	fcc42703          	lw	a4,-52(s0)
    80002e08:	fce7efe3          	bltu	a5,a4,80002de6 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e0c:	00015517          	auipc	a0,0x15
    80002e10:	95c50513          	addi	a0,a0,-1700 # 80017768 <tickslock>
    80002e14:	ffffe097          	auipc	ra,0xffffe
    80002e18:	efa080e7          	jalr	-262(ra) # 80000d0e <release>
  return 0;
    80002e1c:	4781                	li	a5,0
}
    80002e1e:	853e                	mv	a0,a5
    80002e20:	70e2                	ld	ra,56(sp)
    80002e22:	7442                	ld	s0,48(sp)
    80002e24:	74a2                	ld	s1,40(sp)
    80002e26:	7902                	ld	s2,32(sp)
    80002e28:	69e2                	ld	s3,24(sp)
    80002e2a:	6121                	addi	sp,sp,64
    80002e2c:	8082                	ret
      release(&tickslock);
    80002e2e:	00015517          	auipc	a0,0x15
    80002e32:	93a50513          	addi	a0,a0,-1734 # 80017768 <tickslock>
    80002e36:	ffffe097          	auipc	ra,0xffffe
    80002e3a:	ed8080e7          	jalr	-296(ra) # 80000d0e <release>
      return -1;
    80002e3e:	57fd                	li	a5,-1
    80002e40:	bff9                	j	80002e1e <sys_sleep+0x88>

0000000080002e42 <sys_kill>:

uint64
sys_kill(void)
{
    80002e42:	1101                	addi	sp,sp,-32
    80002e44:	ec06                	sd	ra,24(sp)
    80002e46:	e822                	sd	s0,16(sp)
    80002e48:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e4a:	fec40593          	addi	a1,s0,-20
    80002e4e:	4501                	li	a0,0
    80002e50:	00000097          	auipc	ra,0x0
    80002e54:	d2e080e7          	jalr	-722(ra) # 80002b7e <argint>
    80002e58:	87aa                	mv	a5,a0
    return -1;
    80002e5a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e5c:	0007c863          	bltz	a5,80002e6c <sys_kill+0x2a>
  return kill(pid);
    80002e60:	fec42503          	lw	a0,-20(s0)
    80002e64:	fffff097          	auipc	ra,0xfffff
    80002e68:	5cc080e7          	jalr	1484(ra) # 80002430 <kill>
}
    80002e6c:	60e2                	ld	ra,24(sp)
    80002e6e:	6442                	ld	s0,16(sp)
    80002e70:	6105                	addi	sp,sp,32
    80002e72:	8082                	ret

0000000080002e74 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e74:	1101                	addi	sp,sp,-32
    80002e76:	ec06                	sd	ra,24(sp)
    80002e78:	e822                	sd	s0,16(sp)
    80002e7a:	e426                	sd	s1,8(sp)
    80002e7c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e7e:	00015517          	auipc	a0,0x15
    80002e82:	8ea50513          	addi	a0,a0,-1814 # 80017768 <tickslock>
    80002e86:	ffffe097          	auipc	ra,0xffffe
    80002e8a:	dd4080e7          	jalr	-556(ra) # 80000c5a <acquire>
  xticks = ticks;
    80002e8e:	00006497          	auipc	s1,0x6
    80002e92:	1924a483          	lw	s1,402(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e96:	00015517          	auipc	a0,0x15
    80002e9a:	8d250513          	addi	a0,a0,-1838 # 80017768 <tickslock>
    80002e9e:	ffffe097          	auipc	ra,0xffffe
    80002ea2:	e70080e7          	jalr	-400(ra) # 80000d0e <release>
  return xticks;
}
    80002ea6:	02049513          	slli	a0,s1,0x20
    80002eaa:	9101                	srli	a0,a0,0x20
    80002eac:	60e2                	ld	ra,24(sp)
    80002eae:	6442                	ld	s0,16(sp)
    80002eb0:	64a2                	ld	s1,8(sp)
    80002eb2:	6105                	addi	sp,sp,32
    80002eb4:	8082                	ret

0000000080002eb6 <sys_trace>:

uint64
sys_trace(void)
{
    80002eb6:	1101                	addi	sp,sp,-32
    80002eb8:	ec06                	sd	ra,24(sp)
    80002eba:	e822                	sd	s0,16(sp)
    80002ebc:	1000                	addi	s0,sp,32
  int mask;
  if(argint(0, &mask) < 0)
    80002ebe:	fec40593          	addi	a1,s0,-20
    80002ec2:	4501                	li	a0,0
    80002ec4:	00000097          	auipc	ra,0x0
    80002ec8:	cba080e7          	jalr	-838(ra) # 80002b7e <argint>
    80002ecc:	87aa                	mv	a5,a0
    return -1;
    80002ece:	557d                	li	a0,-1
  if(argint(0, &mask) < 0)
    80002ed0:	0007c863          	bltz	a5,80002ee0 <sys_trace+0x2a>
  //printf("sys_trace %d\n", mask);
  return trace(mask);
    80002ed4:	fec42503          	lw	a0,-20(s0)
    80002ed8:	fffff097          	auipc	ra,0xfffff
    80002edc:	724080e7          	jalr	1828(ra) # 800025fc <trace>
    80002ee0:	60e2                	ld	ra,24(sp)
    80002ee2:	6442                	ld	s0,16(sp)
    80002ee4:	6105                	addi	sp,sp,32
    80002ee6:	8082                	ret

0000000080002ee8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ee8:	7179                	addi	sp,sp,-48
    80002eea:	f406                	sd	ra,40(sp)
    80002eec:	f022                	sd	s0,32(sp)
    80002eee:	ec26                	sd	s1,24(sp)
    80002ef0:	e84a                	sd	s2,16(sp)
    80002ef2:	e44e                	sd	s3,8(sp)
    80002ef4:	e052                	sd	s4,0(sp)
    80002ef6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ef8:	00005597          	auipc	a1,0x5
    80002efc:	77858593          	addi	a1,a1,1912 # 80008670 <syscallnumber_to_name+0xc0>
    80002f00:	00015517          	auipc	a0,0x15
    80002f04:	88050513          	addi	a0,a0,-1920 # 80017780 <bcache>
    80002f08:	ffffe097          	auipc	ra,0xffffe
    80002f0c:	cc2080e7          	jalr	-830(ra) # 80000bca <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f10:	0001d797          	auipc	a5,0x1d
    80002f14:	87078793          	addi	a5,a5,-1936 # 8001f780 <bcache+0x8000>
    80002f18:	0001d717          	auipc	a4,0x1d
    80002f1c:	ad070713          	addi	a4,a4,-1328 # 8001f9e8 <bcache+0x8268>
    80002f20:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f24:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f28:	00015497          	auipc	s1,0x15
    80002f2c:	87048493          	addi	s1,s1,-1936 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002f30:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f32:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f34:	00005a17          	auipc	s4,0x5
    80002f38:	744a0a13          	addi	s4,s4,1860 # 80008678 <syscallnumber_to_name+0xc8>
    b->next = bcache.head.next;
    80002f3c:	2b893783          	ld	a5,696(s2)
    80002f40:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f42:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f46:	85d2                	mv	a1,s4
    80002f48:	01048513          	addi	a0,s1,16
    80002f4c:	00001097          	auipc	ra,0x1
    80002f50:	4ac080e7          	jalr	1196(ra) # 800043f8 <initsleeplock>
    bcache.head.next->prev = b;
    80002f54:	2b893783          	ld	a5,696(s2)
    80002f58:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f5a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f5e:	45848493          	addi	s1,s1,1112
    80002f62:	fd349de3          	bne	s1,s3,80002f3c <binit+0x54>
  }
}
    80002f66:	70a2                	ld	ra,40(sp)
    80002f68:	7402                	ld	s0,32(sp)
    80002f6a:	64e2                	ld	s1,24(sp)
    80002f6c:	6942                	ld	s2,16(sp)
    80002f6e:	69a2                	ld	s3,8(sp)
    80002f70:	6a02                	ld	s4,0(sp)
    80002f72:	6145                	addi	sp,sp,48
    80002f74:	8082                	ret

0000000080002f76 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f76:	7179                	addi	sp,sp,-48
    80002f78:	f406                	sd	ra,40(sp)
    80002f7a:	f022                	sd	s0,32(sp)
    80002f7c:	ec26                	sd	s1,24(sp)
    80002f7e:	e84a                	sd	s2,16(sp)
    80002f80:	e44e                	sd	s3,8(sp)
    80002f82:	1800                	addi	s0,sp,48
    80002f84:	89aa                	mv	s3,a0
    80002f86:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f88:	00014517          	auipc	a0,0x14
    80002f8c:	7f850513          	addi	a0,a0,2040 # 80017780 <bcache>
    80002f90:	ffffe097          	auipc	ra,0xffffe
    80002f94:	cca080e7          	jalr	-822(ra) # 80000c5a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f98:	0001d497          	auipc	s1,0x1d
    80002f9c:	aa04b483          	ld	s1,-1376(s1) # 8001fa38 <bcache+0x82b8>
    80002fa0:	0001d797          	auipc	a5,0x1d
    80002fa4:	a4878793          	addi	a5,a5,-1464 # 8001f9e8 <bcache+0x8268>
    80002fa8:	02f48f63          	beq	s1,a5,80002fe6 <bread+0x70>
    80002fac:	873e                	mv	a4,a5
    80002fae:	a021                	j	80002fb6 <bread+0x40>
    80002fb0:	68a4                	ld	s1,80(s1)
    80002fb2:	02e48a63          	beq	s1,a4,80002fe6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fb6:	449c                	lw	a5,8(s1)
    80002fb8:	ff379ce3          	bne	a5,s3,80002fb0 <bread+0x3a>
    80002fbc:	44dc                	lw	a5,12(s1)
    80002fbe:	ff2799e3          	bne	a5,s2,80002fb0 <bread+0x3a>
      b->refcnt++;
    80002fc2:	40bc                	lw	a5,64(s1)
    80002fc4:	2785                	addiw	a5,a5,1
    80002fc6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fc8:	00014517          	auipc	a0,0x14
    80002fcc:	7b850513          	addi	a0,a0,1976 # 80017780 <bcache>
    80002fd0:	ffffe097          	auipc	ra,0xffffe
    80002fd4:	d3e080e7          	jalr	-706(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    80002fd8:	01048513          	addi	a0,s1,16
    80002fdc:	00001097          	auipc	ra,0x1
    80002fe0:	456080e7          	jalr	1110(ra) # 80004432 <acquiresleep>
      return b;
    80002fe4:	a8b9                	j	80003042 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fe6:	0001d497          	auipc	s1,0x1d
    80002fea:	a4a4b483          	ld	s1,-1462(s1) # 8001fa30 <bcache+0x82b0>
    80002fee:	0001d797          	auipc	a5,0x1d
    80002ff2:	9fa78793          	addi	a5,a5,-1542 # 8001f9e8 <bcache+0x8268>
    80002ff6:	00f48863          	beq	s1,a5,80003006 <bread+0x90>
    80002ffa:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ffc:	40bc                	lw	a5,64(s1)
    80002ffe:	cf81                	beqz	a5,80003016 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003000:	64a4                	ld	s1,72(s1)
    80003002:	fee49de3          	bne	s1,a4,80002ffc <bread+0x86>
  panic("bget: no buffers");
    80003006:	00005517          	auipc	a0,0x5
    8000300a:	67a50513          	addi	a0,a0,1658 # 80008680 <syscallnumber_to_name+0xd0>
    8000300e:	ffffd097          	auipc	ra,0xffffd
    80003012:	53a080e7          	jalr	1338(ra) # 80000548 <panic>
      b->dev = dev;
    80003016:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000301a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000301e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003022:	4785                	li	a5,1
    80003024:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003026:	00014517          	auipc	a0,0x14
    8000302a:	75a50513          	addi	a0,a0,1882 # 80017780 <bcache>
    8000302e:	ffffe097          	auipc	ra,0xffffe
    80003032:	ce0080e7          	jalr	-800(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    80003036:	01048513          	addi	a0,s1,16
    8000303a:	00001097          	auipc	ra,0x1
    8000303e:	3f8080e7          	jalr	1016(ra) # 80004432 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003042:	409c                	lw	a5,0(s1)
    80003044:	cb89                	beqz	a5,80003056 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003046:	8526                	mv	a0,s1
    80003048:	70a2                	ld	ra,40(sp)
    8000304a:	7402                	ld	s0,32(sp)
    8000304c:	64e2                	ld	s1,24(sp)
    8000304e:	6942                	ld	s2,16(sp)
    80003050:	69a2                	ld	s3,8(sp)
    80003052:	6145                	addi	sp,sp,48
    80003054:	8082                	ret
    virtio_disk_rw(b, 0);
    80003056:	4581                	li	a1,0
    80003058:	8526                	mv	a0,s1
    8000305a:	00003097          	auipc	ra,0x3
    8000305e:	f32080e7          	jalr	-206(ra) # 80005f8c <virtio_disk_rw>
    b->valid = 1;
    80003062:	4785                	li	a5,1
    80003064:	c09c                	sw	a5,0(s1)
  return b;
    80003066:	b7c5                	j	80003046 <bread+0xd0>

0000000080003068 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003068:	1101                	addi	sp,sp,-32
    8000306a:	ec06                	sd	ra,24(sp)
    8000306c:	e822                	sd	s0,16(sp)
    8000306e:	e426                	sd	s1,8(sp)
    80003070:	1000                	addi	s0,sp,32
    80003072:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003074:	0541                	addi	a0,a0,16
    80003076:	00001097          	auipc	ra,0x1
    8000307a:	456080e7          	jalr	1110(ra) # 800044cc <holdingsleep>
    8000307e:	cd01                	beqz	a0,80003096 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003080:	4585                	li	a1,1
    80003082:	8526                	mv	a0,s1
    80003084:	00003097          	auipc	ra,0x3
    80003088:	f08080e7          	jalr	-248(ra) # 80005f8c <virtio_disk_rw>
}
    8000308c:	60e2                	ld	ra,24(sp)
    8000308e:	6442                	ld	s0,16(sp)
    80003090:	64a2                	ld	s1,8(sp)
    80003092:	6105                	addi	sp,sp,32
    80003094:	8082                	ret
    panic("bwrite");
    80003096:	00005517          	auipc	a0,0x5
    8000309a:	60250513          	addi	a0,a0,1538 # 80008698 <syscallnumber_to_name+0xe8>
    8000309e:	ffffd097          	auipc	ra,0xffffd
    800030a2:	4aa080e7          	jalr	1194(ra) # 80000548 <panic>

00000000800030a6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030a6:	1101                	addi	sp,sp,-32
    800030a8:	ec06                	sd	ra,24(sp)
    800030aa:	e822                	sd	s0,16(sp)
    800030ac:	e426                	sd	s1,8(sp)
    800030ae:	e04a                	sd	s2,0(sp)
    800030b0:	1000                	addi	s0,sp,32
    800030b2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030b4:	01050913          	addi	s2,a0,16
    800030b8:	854a                	mv	a0,s2
    800030ba:	00001097          	auipc	ra,0x1
    800030be:	412080e7          	jalr	1042(ra) # 800044cc <holdingsleep>
    800030c2:	c92d                	beqz	a0,80003134 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030c4:	854a                	mv	a0,s2
    800030c6:	00001097          	auipc	ra,0x1
    800030ca:	3c2080e7          	jalr	962(ra) # 80004488 <releasesleep>

  acquire(&bcache.lock);
    800030ce:	00014517          	auipc	a0,0x14
    800030d2:	6b250513          	addi	a0,a0,1714 # 80017780 <bcache>
    800030d6:	ffffe097          	auipc	ra,0xffffe
    800030da:	b84080e7          	jalr	-1148(ra) # 80000c5a <acquire>
  b->refcnt--;
    800030de:	40bc                	lw	a5,64(s1)
    800030e0:	37fd                	addiw	a5,a5,-1
    800030e2:	0007871b          	sext.w	a4,a5
    800030e6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030e8:	eb05                	bnez	a4,80003118 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030ea:	68bc                	ld	a5,80(s1)
    800030ec:	64b8                	ld	a4,72(s1)
    800030ee:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030f0:	64bc                	ld	a5,72(s1)
    800030f2:	68b8                	ld	a4,80(s1)
    800030f4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030f6:	0001c797          	auipc	a5,0x1c
    800030fa:	68a78793          	addi	a5,a5,1674 # 8001f780 <bcache+0x8000>
    800030fe:	2b87b703          	ld	a4,696(a5)
    80003102:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003104:	0001d717          	auipc	a4,0x1d
    80003108:	8e470713          	addi	a4,a4,-1820 # 8001f9e8 <bcache+0x8268>
    8000310c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000310e:	2b87b703          	ld	a4,696(a5)
    80003112:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003114:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003118:	00014517          	auipc	a0,0x14
    8000311c:	66850513          	addi	a0,a0,1640 # 80017780 <bcache>
    80003120:	ffffe097          	auipc	ra,0xffffe
    80003124:	bee080e7          	jalr	-1042(ra) # 80000d0e <release>
}
    80003128:	60e2                	ld	ra,24(sp)
    8000312a:	6442                	ld	s0,16(sp)
    8000312c:	64a2                	ld	s1,8(sp)
    8000312e:	6902                	ld	s2,0(sp)
    80003130:	6105                	addi	sp,sp,32
    80003132:	8082                	ret
    panic("brelse");
    80003134:	00005517          	auipc	a0,0x5
    80003138:	56c50513          	addi	a0,a0,1388 # 800086a0 <syscallnumber_to_name+0xf0>
    8000313c:	ffffd097          	auipc	ra,0xffffd
    80003140:	40c080e7          	jalr	1036(ra) # 80000548 <panic>

0000000080003144 <bpin>:

void
bpin(struct buf *b) {
    80003144:	1101                	addi	sp,sp,-32
    80003146:	ec06                	sd	ra,24(sp)
    80003148:	e822                	sd	s0,16(sp)
    8000314a:	e426                	sd	s1,8(sp)
    8000314c:	1000                	addi	s0,sp,32
    8000314e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003150:	00014517          	auipc	a0,0x14
    80003154:	63050513          	addi	a0,a0,1584 # 80017780 <bcache>
    80003158:	ffffe097          	auipc	ra,0xffffe
    8000315c:	b02080e7          	jalr	-1278(ra) # 80000c5a <acquire>
  b->refcnt++;
    80003160:	40bc                	lw	a5,64(s1)
    80003162:	2785                	addiw	a5,a5,1
    80003164:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003166:	00014517          	auipc	a0,0x14
    8000316a:	61a50513          	addi	a0,a0,1562 # 80017780 <bcache>
    8000316e:	ffffe097          	auipc	ra,0xffffe
    80003172:	ba0080e7          	jalr	-1120(ra) # 80000d0e <release>
}
    80003176:	60e2                	ld	ra,24(sp)
    80003178:	6442                	ld	s0,16(sp)
    8000317a:	64a2                	ld	s1,8(sp)
    8000317c:	6105                	addi	sp,sp,32
    8000317e:	8082                	ret

0000000080003180 <bunpin>:

void
bunpin(struct buf *b) {
    80003180:	1101                	addi	sp,sp,-32
    80003182:	ec06                	sd	ra,24(sp)
    80003184:	e822                	sd	s0,16(sp)
    80003186:	e426                	sd	s1,8(sp)
    80003188:	1000                	addi	s0,sp,32
    8000318a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000318c:	00014517          	auipc	a0,0x14
    80003190:	5f450513          	addi	a0,a0,1524 # 80017780 <bcache>
    80003194:	ffffe097          	auipc	ra,0xffffe
    80003198:	ac6080e7          	jalr	-1338(ra) # 80000c5a <acquire>
  b->refcnt--;
    8000319c:	40bc                	lw	a5,64(s1)
    8000319e:	37fd                	addiw	a5,a5,-1
    800031a0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031a2:	00014517          	auipc	a0,0x14
    800031a6:	5de50513          	addi	a0,a0,1502 # 80017780 <bcache>
    800031aa:	ffffe097          	auipc	ra,0xffffe
    800031ae:	b64080e7          	jalr	-1180(ra) # 80000d0e <release>
}
    800031b2:	60e2                	ld	ra,24(sp)
    800031b4:	6442                	ld	s0,16(sp)
    800031b6:	64a2                	ld	s1,8(sp)
    800031b8:	6105                	addi	sp,sp,32
    800031ba:	8082                	ret

00000000800031bc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031bc:	1101                	addi	sp,sp,-32
    800031be:	ec06                	sd	ra,24(sp)
    800031c0:	e822                	sd	s0,16(sp)
    800031c2:	e426                	sd	s1,8(sp)
    800031c4:	e04a                	sd	s2,0(sp)
    800031c6:	1000                	addi	s0,sp,32
    800031c8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031ca:	00d5d59b          	srliw	a1,a1,0xd
    800031ce:	0001d797          	auipc	a5,0x1d
    800031d2:	c8e7a783          	lw	a5,-882(a5) # 8001fe5c <sb+0x1c>
    800031d6:	9dbd                	addw	a1,a1,a5
    800031d8:	00000097          	auipc	ra,0x0
    800031dc:	d9e080e7          	jalr	-610(ra) # 80002f76 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031e0:	0074f713          	andi	a4,s1,7
    800031e4:	4785                	li	a5,1
    800031e6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031ea:	14ce                	slli	s1,s1,0x33
    800031ec:	90d9                	srli	s1,s1,0x36
    800031ee:	00950733          	add	a4,a0,s1
    800031f2:	05874703          	lbu	a4,88(a4)
    800031f6:	00e7f6b3          	and	a3,a5,a4
    800031fa:	c69d                	beqz	a3,80003228 <bfree+0x6c>
    800031fc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031fe:	94aa                	add	s1,s1,a0
    80003200:	fff7c793          	not	a5,a5
    80003204:	8ff9                	and	a5,a5,a4
    80003206:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000320a:	00001097          	auipc	ra,0x1
    8000320e:	100080e7          	jalr	256(ra) # 8000430a <log_write>
  brelse(bp);
    80003212:	854a                	mv	a0,s2
    80003214:	00000097          	auipc	ra,0x0
    80003218:	e92080e7          	jalr	-366(ra) # 800030a6 <brelse>
}
    8000321c:	60e2                	ld	ra,24(sp)
    8000321e:	6442                	ld	s0,16(sp)
    80003220:	64a2                	ld	s1,8(sp)
    80003222:	6902                	ld	s2,0(sp)
    80003224:	6105                	addi	sp,sp,32
    80003226:	8082                	ret
    panic("freeing free block");
    80003228:	00005517          	auipc	a0,0x5
    8000322c:	48050513          	addi	a0,a0,1152 # 800086a8 <syscallnumber_to_name+0xf8>
    80003230:	ffffd097          	auipc	ra,0xffffd
    80003234:	318080e7          	jalr	792(ra) # 80000548 <panic>

0000000080003238 <balloc>:
{
    80003238:	711d                	addi	sp,sp,-96
    8000323a:	ec86                	sd	ra,88(sp)
    8000323c:	e8a2                	sd	s0,80(sp)
    8000323e:	e4a6                	sd	s1,72(sp)
    80003240:	e0ca                	sd	s2,64(sp)
    80003242:	fc4e                	sd	s3,56(sp)
    80003244:	f852                	sd	s4,48(sp)
    80003246:	f456                	sd	s5,40(sp)
    80003248:	f05a                	sd	s6,32(sp)
    8000324a:	ec5e                	sd	s7,24(sp)
    8000324c:	e862                	sd	s8,16(sp)
    8000324e:	e466                	sd	s9,8(sp)
    80003250:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003252:	0001d797          	auipc	a5,0x1d
    80003256:	bf27a783          	lw	a5,-1038(a5) # 8001fe44 <sb+0x4>
    8000325a:	cbd1                	beqz	a5,800032ee <balloc+0xb6>
    8000325c:	8baa                	mv	s7,a0
    8000325e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003260:	0001db17          	auipc	s6,0x1d
    80003264:	be0b0b13          	addi	s6,s6,-1056 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003268:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000326a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000326c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000326e:	6c89                	lui	s9,0x2
    80003270:	a831                	j	8000328c <balloc+0x54>
    brelse(bp);
    80003272:	854a                	mv	a0,s2
    80003274:	00000097          	auipc	ra,0x0
    80003278:	e32080e7          	jalr	-462(ra) # 800030a6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000327c:	015c87bb          	addw	a5,s9,s5
    80003280:	00078a9b          	sext.w	s5,a5
    80003284:	004b2703          	lw	a4,4(s6)
    80003288:	06eaf363          	bgeu	s5,a4,800032ee <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000328c:	41fad79b          	sraiw	a5,s5,0x1f
    80003290:	0137d79b          	srliw	a5,a5,0x13
    80003294:	015787bb          	addw	a5,a5,s5
    80003298:	40d7d79b          	sraiw	a5,a5,0xd
    8000329c:	01cb2583          	lw	a1,28(s6)
    800032a0:	9dbd                	addw	a1,a1,a5
    800032a2:	855e                	mv	a0,s7
    800032a4:	00000097          	auipc	ra,0x0
    800032a8:	cd2080e7          	jalr	-814(ra) # 80002f76 <bread>
    800032ac:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ae:	004b2503          	lw	a0,4(s6)
    800032b2:	000a849b          	sext.w	s1,s5
    800032b6:	8662                	mv	a2,s8
    800032b8:	faa4fde3          	bgeu	s1,a0,80003272 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032bc:	41f6579b          	sraiw	a5,a2,0x1f
    800032c0:	01d7d69b          	srliw	a3,a5,0x1d
    800032c4:	00c6873b          	addw	a4,a3,a2
    800032c8:	00777793          	andi	a5,a4,7
    800032cc:	9f95                	subw	a5,a5,a3
    800032ce:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032d2:	4037571b          	sraiw	a4,a4,0x3
    800032d6:	00e906b3          	add	a3,s2,a4
    800032da:	0586c683          	lbu	a3,88(a3)
    800032de:	00d7f5b3          	and	a1,a5,a3
    800032e2:	cd91                	beqz	a1,800032fe <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032e4:	2605                	addiw	a2,a2,1
    800032e6:	2485                	addiw	s1,s1,1
    800032e8:	fd4618e3          	bne	a2,s4,800032b8 <balloc+0x80>
    800032ec:	b759                	j	80003272 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032ee:	00005517          	auipc	a0,0x5
    800032f2:	3d250513          	addi	a0,a0,978 # 800086c0 <syscallnumber_to_name+0x110>
    800032f6:	ffffd097          	auipc	ra,0xffffd
    800032fa:	252080e7          	jalr	594(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032fe:	974a                	add	a4,a4,s2
    80003300:	8fd5                	or	a5,a5,a3
    80003302:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003306:	854a                	mv	a0,s2
    80003308:	00001097          	auipc	ra,0x1
    8000330c:	002080e7          	jalr	2(ra) # 8000430a <log_write>
        brelse(bp);
    80003310:	854a                	mv	a0,s2
    80003312:	00000097          	auipc	ra,0x0
    80003316:	d94080e7          	jalr	-620(ra) # 800030a6 <brelse>
  bp = bread(dev, bno);
    8000331a:	85a6                	mv	a1,s1
    8000331c:	855e                	mv	a0,s7
    8000331e:	00000097          	auipc	ra,0x0
    80003322:	c58080e7          	jalr	-936(ra) # 80002f76 <bread>
    80003326:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003328:	40000613          	li	a2,1024
    8000332c:	4581                	li	a1,0
    8000332e:	05850513          	addi	a0,a0,88
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	a24080e7          	jalr	-1500(ra) # 80000d56 <memset>
  log_write(bp);
    8000333a:	854a                	mv	a0,s2
    8000333c:	00001097          	auipc	ra,0x1
    80003340:	fce080e7          	jalr	-50(ra) # 8000430a <log_write>
  brelse(bp);
    80003344:	854a                	mv	a0,s2
    80003346:	00000097          	auipc	ra,0x0
    8000334a:	d60080e7          	jalr	-672(ra) # 800030a6 <brelse>
}
    8000334e:	8526                	mv	a0,s1
    80003350:	60e6                	ld	ra,88(sp)
    80003352:	6446                	ld	s0,80(sp)
    80003354:	64a6                	ld	s1,72(sp)
    80003356:	6906                	ld	s2,64(sp)
    80003358:	79e2                	ld	s3,56(sp)
    8000335a:	7a42                	ld	s4,48(sp)
    8000335c:	7aa2                	ld	s5,40(sp)
    8000335e:	7b02                	ld	s6,32(sp)
    80003360:	6be2                	ld	s7,24(sp)
    80003362:	6c42                	ld	s8,16(sp)
    80003364:	6ca2                	ld	s9,8(sp)
    80003366:	6125                	addi	sp,sp,96
    80003368:	8082                	ret

000000008000336a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000336a:	7179                	addi	sp,sp,-48
    8000336c:	f406                	sd	ra,40(sp)
    8000336e:	f022                	sd	s0,32(sp)
    80003370:	ec26                	sd	s1,24(sp)
    80003372:	e84a                	sd	s2,16(sp)
    80003374:	e44e                	sd	s3,8(sp)
    80003376:	e052                	sd	s4,0(sp)
    80003378:	1800                	addi	s0,sp,48
    8000337a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000337c:	47ad                	li	a5,11
    8000337e:	04b7fe63          	bgeu	a5,a1,800033da <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003382:	ff45849b          	addiw	s1,a1,-12
    80003386:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000338a:	0ff00793          	li	a5,255
    8000338e:	0ae7e363          	bltu	a5,a4,80003434 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003392:	08052583          	lw	a1,128(a0)
    80003396:	c5ad                	beqz	a1,80003400 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003398:	00092503          	lw	a0,0(s2)
    8000339c:	00000097          	auipc	ra,0x0
    800033a0:	bda080e7          	jalr	-1062(ra) # 80002f76 <bread>
    800033a4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033a6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033aa:	02049593          	slli	a1,s1,0x20
    800033ae:	9181                	srli	a1,a1,0x20
    800033b0:	058a                	slli	a1,a1,0x2
    800033b2:	00b784b3          	add	s1,a5,a1
    800033b6:	0004a983          	lw	s3,0(s1)
    800033ba:	04098d63          	beqz	s3,80003414 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033be:	8552                	mv	a0,s4
    800033c0:	00000097          	auipc	ra,0x0
    800033c4:	ce6080e7          	jalr	-794(ra) # 800030a6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033c8:	854e                	mv	a0,s3
    800033ca:	70a2                	ld	ra,40(sp)
    800033cc:	7402                	ld	s0,32(sp)
    800033ce:	64e2                	ld	s1,24(sp)
    800033d0:	6942                	ld	s2,16(sp)
    800033d2:	69a2                	ld	s3,8(sp)
    800033d4:	6a02                	ld	s4,0(sp)
    800033d6:	6145                	addi	sp,sp,48
    800033d8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033da:	02059493          	slli	s1,a1,0x20
    800033de:	9081                	srli	s1,s1,0x20
    800033e0:	048a                	slli	s1,s1,0x2
    800033e2:	94aa                	add	s1,s1,a0
    800033e4:	0504a983          	lw	s3,80(s1)
    800033e8:	fe0990e3          	bnez	s3,800033c8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033ec:	4108                	lw	a0,0(a0)
    800033ee:	00000097          	auipc	ra,0x0
    800033f2:	e4a080e7          	jalr	-438(ra) # 80003238 <balloc>
    800033f6:	0005099b          	sext.w	s3,a0
    800033fa:	0534a823          	sw	s3,80(s1)
    800033fe:	b7e9                	j	800033c8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003400:	4108                	lw	a0,0(a0)
    80003402:	00000097          	auipc	ra,0x0
    80003406:	e36080e7          	jalr	-458(ra) # 80003238 <balloc>
    8000340a:	0005059b          	sext.w	a1,a0
    8000340e:	08b92023          	sw	a1,128(s2)
    80003412:	b759                	j	80003398 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003414:	00092503          	lw	a0,0(s2)
    80003418:	00000097          	auipc	ra,0x0
    8000341c:	e20080e7          	jalr	-480(ra) # 80003238 <balloc>
    80003420:	0005099b          	sext.w	s3,a0
    80003424:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003428:	8552                	mv	a0,s4
    8000342a:	00001097          	auipc	ra,0x1
    8000342e:	ee0080e7          	jalr	-288(ra) # 8000430a <log_write>
    80003432:	b771                	j	800033be <bmap+0x54>
  panic("bmap: out of range");
    80003434:	00005517          	auipc	a0,0x5
    80003438:	2a450513          	addi	a0,a0,676 # 800086d8 <syscallnumber_to_name+0x128>
    8000343c:	ffffd097          	auipc	ra,0xffffd
    80003440:	10c080e7          	jalr	268(ra) # 80000548 <panic>

0000000080003444 <iget>:
{
    80003444:	7179                	addi	sp,sp,-48
    80003446:	f406                	sd	ra,40(sp)
    80003448:	f022                	sd	s0,32(sp)
    8000344a:	ec26                	sd	s1,24(sp)
    8000344c:	e84a                	sd	s2,16(sp)
    8000344e:	e44e                	sd	s3,8(sp)
    80003450:	e052                	sd	s4,0(sp)
    80003452:	1800                	addi	s0,sp,48
    80003454:	89aa                	mv	s3,a0
    80003456:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003458:	0001d517          	auipc	a0,0x1d
    8000345c:	a0850513          	addi	a0,a0,-1528 # 8001fe60 <icache>
    80003460:	ffffd097          	auipc	ra,0xffffd
    80003464:	7fa080e7          	jalr	2042(ra) # 80000c5a <acquire>
  empty = 0;
    80003468:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000346a:	0001d497          	auipc	s1,0x1d
    8000346e:	a0e48493          	addi	s1,s1,-1522 # 8001fe78 <icache+0x18>
    80003472:	0001e697          	auipc	a3,0x1e
    80003476:	49668693          	addi	a3,a3,1174 # 80021908 <log>
    8000347a:	a039                	j	80003488 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000347c:	02090b63          	beqz	s2,800034b2 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003480:	08848493          	addi	s1,s1,136
    80003484:	02d48a63          	beq	s1,a3,800034b8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003488:	449c                	lw	a5,8(s1)
    8000348a:	fef059e3          	blez	a5,8000347c <iget+0x38>
    8000348e:	4098                	lw	a4,0(s1)
    80003490:	ff3716e3          	bne	a4,s3,8000347c <iget+0x38>
    80003494:	40d8                	lw	a4,4(s1)
    80003496:	ff4713e3          	bne	a4,s4,8000347c <iget+0x38>
      ip->ref++;
    8000349a:	2785                	addiw	a5,a5,1
    8000349c:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000349e:	0001d517          	auipc	a0,0x1d
    800034a2:	9c250513          	addi	a0,a0,-1598 # 8001fe60 <icache>
    800034a6:	ffffe097          	auipc	ra,0xffffe
    800034aa:	868080e7          	jalr	-1944(ra) # 80000d0e <release>
      return ip;
    800034ae:	8926                	mv	s2,s1
    800034b0:	a03d                	j	800034de <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034b2:	f7f9                	bnez	a5,80003480 <iget+0x3c>
    800034b4:	8926                	mv	s2,s1
    800034b6:	b7e9                	j	80003480 <iget+0x3c>
  if(empty == 0)
    800034b8:	02090c63          	beqz	s2,800034f0 <iget+0xac>
  ip->dev = dev;
    800034bc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034c0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034c4:	4785                	li	a5,1
    800034c6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034ca:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800034ce:	0001d517          	auipc	a0,0x1d
    800034d2:	99250513          	addi	a0,a0,-1646 # 8001fe60 <icache>
    800034d6:	ffffe097          	auipc	ra,0xffffe
    800034da:	838080e7          	jalr	-1992(ra) # 80000d0e <release>
}
    800034de:	854a                	mv	a0,s2
    800034e0:	70a2                	ld	ra,40(sp)
    800034e2:	7402                	ld	s0,32(sp)
    800034e4:	64e2                	ld	s1,24(sp)
    800034e6:	6942                	ld	s2,16(sp)
    800034e8:	69a2                	ld	s3,8(sp)
    800034ea:	6a02                	ld	s4,0(sp)
    800034ec:	6145                	addi	sp,sp,48
    800034ee:	8082                	ret
    panic("iget: no inodes");
    800034f0:	00005517          	auipc	a0,0x5
    800034f4:	20050513          	addi	a0,a0,512 # 800086f0 <syscallnumber_to_name+0x140>
    800034f8:	ffffd097          	auipc	ra,0xffffd
    800034fc:	050080e7          	jalr	80(ra) # 80000548 <panic>

0000000080003500 <fsinit>:
fsinit(int dev) {
    80003500:	7179                	addi	sp,sp,-48
    80003502:	f406                	sd	ra,40(sp)
    80003504:	f022                	sd	s0,32(sp)
    80003506:	ec26                	sd	s1,24(sp)
    80003508:	e84a                	sd	s2,16(sp)
    8000350a:	e44e                	sd	s3,8(sp)
    8000350c:	1800                	addi	s0,sp,48
    8000350e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003510:	4585                	li	a1,1
    80003512:	00000097          	auipc	ra,0x0
    80003516:	a64080e7          	jalr	-1436(ra) # 80002f76 <bread>
    8000351a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000351c:	0001d997          	auipc	s3,0x1d
    80003520:	92498993          	addi	s3,s3,-1756 # 8001fe40 <sb>
    80003524:	02000613          	li	a2,32
    80003528:	05850593          	addi	a1,a0,88
    8000352c:	854e                	mv	a0,s3
    8000352e:	ffffe097          	auipc	ra,0xffffe
    80003532:	888080e7          	jalr	-1912(ra) # 80000db6 <memmove>
  brelse(bp);
    80003536:	8526                	mv	a0,s1
    80003538:	00000097          	auipc	ra,0x0
    8000353c:	b6e080e7          	jalr	-1170(ra) # 800030a6 <brelse>
  if(sb.magic != FSMAGIC)
    80003540:	0009a703          	lw	a4,0(s3)
    80003544:	102037b7          	lui	a5,0x10203
    80003548:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000354c:	02f71263          	bne	a4,a5,80003570 <fsinit+0x70>
  initlog(dev, &sb);
    80003550:	0001d597          	auipc	a1,0x1d
    80003554:	8f058593          	addi	a1,a1,-1808 # 8001fe40 <sb>
    80003558:	854a                	mv	a0,s2
    8000355a:	00001097          	auipc	ra,0x1
    8000355e:	b38080e7          	jalr	-1224(ra) # 80004092 <initlog>
}
    80003562:	70a2                	ld	ra,40(sp)
    80003564:	7402                	ld	s0,32(sp)
    80003566:	64e2                	ld	s1,24(sp)
    80003568:	6942                	ld	s2,16(sp)
    8000356a:	69a2                	ld	s3,8(sp)
    8000356c:	6145                	addi	sp,sp,48
    8000356e:	8082                	ret
    panic("invalid file system");
    80003570:	00005517          	auipc	a0,0x5
    80003574:	19050513          	addi	a0,a0,400 # 80008700 <syscallnumber_to_name+0x150>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	fd0080e7          	jalr	-48(ra) # 80000548 <panic>

0000000080003580 <iinit>:
{
    80003580:	7179                	addi	sp,sp,-48
    80003582:	f406                	sd	ra,40(sp)
    80003584:	f022                	sd	s0,32(sp)
    80003586:	ec26                	sd	s1,24(sp)
    80003588:	e84a                	sd	s2,16(sp)
    8000358a:	e44e                	sd	s3,8(sp)
    8000358c:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000358e:	00005597          	auipc	a1,0x5
    80003592:	18a58593          	addi	a1,a1,394 # 80008718 <syscallnumber_to_name+0x168>
    80003596:	0001d517          	auipc	a0,0x1d
    8000359a:	8ca50513          	addi	a0,a0,-1846 # 8001fe60 <icache>
    8000359e:	ffffd097          	auipc	ra,0xffffd
    800035a2:	62c080e7          	jalr	1580(ra) # 80000bca <initlock>
  for(i = 0; i < NINODE; i++) {
    800035a6:	0001d497          	auipc	s1,0x1d
    800035aa:	8e248493          	addi	s1,s1,-1822 # 8001fe88 <icache+0x28>
    800035ae:	0001e997          	auipc	s3,0x1e
    800035b2:	36a98993          	addi	s3,s3,874 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800035b6:	00005917          	auipc	s2,0x5
    800035ba:	16a90913          	addi	s2,s2,362 # 80008720 <syscallnumber_to_name+0x170>
    800035be:	85ca                	mv	a1,s2
    800035c0:	8526                	mv	a0,s1
    800035c2:	00001097          	auipc	ra,0x1
    800035c6:	e36080e7          	jalr	-458(ra) # 800043f8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035ca:	08848493          	addi	s1,s1,136
    800035ce:	ff3498e3          	bne	s1,s3,800035be <iinit+0x3e>
}
    800035d2:	70a2                	ld	ra,40(sp)
    800035d4:	7402                	ld	s0,32(sp)
    800035d6:	64e2                	ld	s1,24(sp)
    800035d8:	6942                	ld	s2,16(sp)
    800035da:	69a2                	ld	s3,8(sp)
    800035dc:	6145                	addi	sp,sp,48
    800035de:	8082                	ret

00000000800035e0 <ialloc>:
{
    800035e0:	715d                	addi	sp,sp,-80
    800035e2:	e486                	sd	ra,72(sp)
    800035e4:	e0a2                	sd	s0,64(sp)
    800035e6:	fc26                	sd	s1,56(sp)
    800035e8:	f84a                	sd	s2,48(sp)
    800035ea:	f44e                	sd	s3,40(sp)
    800035ec:	f052                	sd	s4,32(sp)
    800035ee:	ec56                	sd	s5,24(sp)
    800035f0:	e85a                	sd	s6,16(sp)
    800035f2:	e45e                	sd	s7,8(sp)
    800035f4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035f6:	0001d717          	auipc	a4,0x1d
    800035fa:	85672703          	lw	a4,-1962(a4) # 8001fe4c <sb+0xc>
    800035fe:	4785                	li	a5,1
    80003600:	04e7fa63          	bgeu	a5,a4,80003654 <ialloc+0x74>
    80003604:	8aaa                	mv	s5,a0
    80003606:	8bae                	mv	s7,a1
    80003608:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000360a:	0001da17          	auipc	s4,0x1d
    8000360e:	836a0a13          	addi	s4,s4,-1994 # 8001fe40 <sb>
    80003612:	00048b1b          	sext.w	s6,s1
    80003616:	0044d593          	srli	a1,s1,0x4
    8000361a:	018a2783          	lw	a5,24(s4)
    8000361e:	9dbd                	addw	a1,a1,a5
    80003620:	8556                	mv	a0,s5
    80003622:	00000097          	auipc	ra,0x0
    80003626:	954080e7          	jalr	-1708(ra) # 80002f76 <bread>
    8000362a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000362c:	05850993          	addi	s3,a0,88
    80003630:	00f4f793          	andi	a5,s1,15
    80003634:	079a                	slli	a5,a5,0x6
    80003636:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003638:	00099783          	lh	a5,0(s3)
    8000363c:	c785                	beqz	a5,80003664 <ialloc+0x84>
    brelse(bp);
    8000363e:	00000097          	auipc	ra,0x0
    80003642:	a68080e7          	jalr	-1432(ra) # 800030a6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003646:	0485                	addi	s1,s1,1
    80003648:	00ca2703          	lw	a4,12(s4)
    8000364c:	0004879b          	sext.w	a5,s1
    80003650:	fce7e1e3          	bltu	a5,a4,80003612 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003654:	00005517          	auipc	a0,0x5
    80003658:	0d450513          	addi	a0,a0,212 # 80008728 <syscallnumber_to_name+0x178>
    8000365c:	ffffd097          	auipc	ra,0xffffd
    80003660:	eec080e7          	jalr	-276(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003664:	04000613          	li	a2,64
    80003668:	4581                	li	a1,0
    8000366a:	854e                	mv	a0,s3
    8000366c:	ffffd097          	auipc	ra,0xffffd
    80003670:	6ea080e7          	jalr	1770(ra) # 80000d56 <memset>
      dip->type = type;
    80003674:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003678:	854a                	mv	a0,s2
    8000367a:	00001097          	auipc	ra,0x1
    8000367e:	c90080e7          	jalr	-880(ra) # 8000430a <log_write>
      brelse(bp);
    80003682:	854a                	mv	a0,s2
    80003684:	00000097          	auipc	ra,0x0
    80003688:	a22080e7          	jalr	-1502(ra) # 800030a6 <brelse>
      return iget(dev, inum);
    8000368c:	85da                	mv	a1,s6
    8000368e:	8556                	mv	a0,s5
    80003690:	00000097          	auipc	ra,0x0
    80003694:	db4080e7          	jalr	-588(ra) # 80003444 <iget>
}
    80003698:	60a6                	ld	ra,72(sp)
    8000369a:	6406                	ld	s0,64(sp)
    8000369c:	74e2                	ld	s1,56(sp)
    8000369e:	7942                	ld	s2,48(sp)
    800036a0:	79a2                	ld	s3,40(sp)
    800036a2:	7a02                	ld	s4,32(sp)
    800036a4:	6ae2                	ld	s5,24(sp)
    800036a6:	6b42                	ld	s6,16(sp)
    800036a8:	6ba2                	ld	s7,8(sp)
    800036aa:	6161                	addi	sp,sp,80
    800036ac:	8082                	ret

00000000800036ae <iupdate>:
{
    800036ae:	1101                	addi	sp,sp,-32
    800036b0:	ec06                	sd	ra,24(sp)
    800036b2:	e822                	sd	s0,16(sp)
    800036b4:	e426                	sd	s1,8(sp)
    800036b6:	e04a                	sd	s2,0(sp)
    800036b8:	1000                	addi	s0,sp,32
    800036ba:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036bc:	415c                	lw	a5,4(a0)
    800036be:	0047d79b          	srliw	a5,a5,0x4
    800036c2:	0001c597          	auipc	a1,0x1c
    800036c6:	7965a583          	lw	a1,1942(a1) # 8001fe58 <sb+0x18>
    800036ca:	9dbd                	addw	a1,a1,a5
    800036cc:	4108                	lw	a0,0(a0)
    800036ce:	00000097          	auipc	ra,0x0
    800036d2:	8a8080e7          	jalr	-1880(ra) # 80002f76 <bread>
    800036d6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036d8:	05850793          	addi	a5,a0,88
    800036dc:	40c8                	lw	a0,4(s1)
    800036de:	893d                	andi	a0,a0,15
    800036e0:	051a                	slli	a0,a0,0x6
    800036e2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036e4:	04449703          	lh	a4,68(s1)
    800036e8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036ec:	04649703          	lh	a4,70(s1)
    800036f0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036f4:	04849703          	lh	a4,72(s1)
    800036f8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036fc:	04a49703          	lh	a4,74(s1)
    80003700:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003704:	44f8                	lw	a4,76(s1)
    80003706:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003708:	03400613          	li	a2,52
    8000370c:	05048593          	addi	a1,s1,80
    80003710:	0531                	addi	a0,a0,12
    80003712:	ffffd097          	auipc	ra,0xffffd
    80003716:	6a4080e7          	jalr	1700(ra) # 80000db6 <memmove>
  log_write(bp);
    8000371a:	854a                	mv	a0,s2
    8000371c:	00001097          	auipc	ra,0x1
    80003720:	bee080e7          	jalr	-1042(ra) # 8000430a <log_write>
  brelse(bp);
    80003724:	854a                	mv	a0,s2
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	980080e7          	jalr	-1664(ra) # 800030a6 <brelse>
}
    8000372e:	60e2                	ld	ra,24(sp)
    80003730:	6442                	ld	s0,16(sp)
    80003732:	64a2                	ld	s1,8(sp)
    80003734:	6902                	ld	s2,0(sp)
    80003736:	6105                	addi	sp,sp,32
    80003738:	8082                	ret

000000008000373a <idup>:
{
    8000373a:	1101                	addi	sp,sp,-32
    8000373c:	ec06                	sd	ra,24(sp)
    8000373e:	e822                	sd	s0,16(sp)
    80003740:	e426                	sd	s1,8(sp)
    80003742:	1000                	addi	s0,sp,32
    80003744:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003746:	0001c517          	auipc	a0,0x1c
    8000374a:	71a50513          	addi	a0,a0,1818 # 8001fe60 <icache>
    8000374e:	ffffd097          	auipc	ra,0xffffd
    80003752:	50c080e7          	jalr	1292(ra) # 80000c5a <acquire>
  ip->ref++;
    80003756:	449c                	lw	a5,8(s1)
    80003758:	2785                	addiw	a5,a5,1
    8000375a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000375c:	0001c517          	auipc	a0,0x1c
    80003760:	70450513          	addi	a0,a0,1796 # 8001fe60 <icache>
    80003764:	ffffd097          	auipc	ra,0xffffd
    80003768:	5aa080e7          	jalr	1450(ra) # 80000d0e <release>
}
    8000376c:	8526                	mv	a0,s1
    8000376e:	60e2                	ld	ra,24(sp)
    80003770:	6442                	ld	s0,16(sp)
    80003772:	64a2                	ld	s1,8(sp)
    80003774:	6105                	addi	sp,sp,32
    80003776:	8082                	ret

0000000080003778 <ilock>:
{
    80003778:	1101                	addi	sp,sp,-32
    8000377a:	ec06                	sd	ra,24(sp)
    8000377c:	e822                	sd	s0,16(sp)
    8000377e:	e426                	sd	s1,8(sp)
    80003780:	e04a                	sd	s2,0(sp)
    80003782:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003784:	c115                	beqz	a0,800037a8 <ilock+0x30>
    80003786:	84aa                	mv	s1,a0
    80003788:	451c                	lw	a5,8(a0)
    8000378a:	00f05f63          	blez	a5,800037a8 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000378e:	0541                	addi	a0,a0,16
    80003790:	00001097          	auipc	ra,0x1
    80003794:	ca2080e7          	jalr	-862(ra) # 80004432 <acquiresleep>
  if(ip->valid == 0){
    80003798:	40bc                	lw	a5,64(s1)
    8000379a:	cf99                	beqz	a5,800037b8 <ilock+0x40>
}
    8000379c:	60e2                	ld	ra,24(sp)
    8000379e:	6442                	ld	s0,16(sp)
    800037a0:	64a2                	ld	s1,8(sp)
    800037a2:	6902                	ld	s2,0(sp)
    800037a4:	6105                	addi	sp,sp,32
    800037a6:	8082                	ret
    panic("ilock");
    800037a8:	00005517          	auipc	a0,0x5
    800037ac:	f9850513          	addi	a0,a0,-104 # 80008740 <syscallnumber_to_name+0x190>
    800037b0:	ffffd097          	auipc	ra,0xffffd
    800037b4:	d98080e7          	jalr	-616(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037b8:	40dc                	lw	a5,4(s1)
    800037ba:	0047d79b          	srliw	a5,a5,0x4
    800037be:	0001c597          	auipc	a1,0x1c
    800037c2:	69a5a583          	lw	a1,1690(a1) # 8001fe58 <sb+0x18>
    800037c6:	9dbd                	addw	a1,a1,a5
    800037c8:	4088                	lw	a0,0(s1)
    800037ca:	fffff097          	auipc	ra,0xfffff
    800037ce:	7ac080e7          	jalr	1964(ra) # 80002f76 <bread>
    800037d2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037d4:	05850593          	addi	a1,a0,88
    800037d8:	40dc                	lw	a5,4(s1)
    800037da:	8bbd                	andi	a5,a5,15
    800037dc:	079a                	slli	a5,a5,0x6
    800037de:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037e0:	00059783          	lh	a5,0(a1)
    800037e4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037e8:	00259783          	lh	a5,2(a1)
    800037ec:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037f0:	00459783          	lh	a5,4(a1)
    800037f4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037f8:	00659783          	lh	a5,6(a1)
    800037fc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003800:	459c                	lw	a5,8(a1)
    80003802:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003804:	03400613          	li	a2,52
    80003808:	05b1                	addi	a1,a1,12
    8000380a:	05048513          	addi	a0,s1,80
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	5a8080e7          	jalr	1448(ra) # 80000db6 <memmove>
    brelse(bp);
    80003816:	854a                	mv	a0,s2
    80003818:	00000097          	auipc	ra,0x0
    8000381c:	88e080e7          	jalr	-1906(ra) # 800030a6 <brelse>
    ip->valid = 1;
    80003820:	4785                	li	a5,1
    80003822:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003824:	04449783          	lh	a5,68(s1)
    80003828:	fbb5                	bnez	a5,8000379c <ilock+0x24>
      panic("ilock: no type");
    8000382a:	00005517          	auipc	a0,0x5
    8000382e:	f1e50513          	addi	a0,a0,-226 # 80008748 <syscallnumber_to_name+0x198>
    80003832:	ffffd097          	auipc	ra,0xffffd
    80003836:	d16080e7          	jalr	-746(ra) # 80000548 <panic>

000000008000383a <iunlock>:
{
    8000383a:	1101                	addi	sp,sp,-32
    8000383c:	ec06                	sd	ra,24(sp)
    8000383e:	e822                	sd	s0,16(sp)
    80003840:	e426                	sd	s1,8(sp)
    80003842:	e04a                	sd	s2,0(sp)
    80003844:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003846:	c905                	beqz	a0,80003876 <iunlock+0x3c>
    80003848:	84aa                	mv	s1,a0
    8000384a:	01050913          	addi	s2,a0,16
    8000384e:	854a                	mv	a0,s2
    80003850:	00001097          	auipc	ra,0x1
    80003854:	c7c080e7          	jalr	-900(ra) # 800044cc <holdingsleep>
    80003858:	cd19                	beqz	a0,80003876 <iunlock+0x3c>
    8000385a:	449c                	lw	a5,8(s1)
    8000385c:	00f05d63          	blez	a5,80003876 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003860:	854a                	mv	a0,s2
    80003862:	00001097          	auipc	ra,0x1
    80003866:	c26080e7          	jalr	-986(ra) # 80004488 <releasesleep>
}
    8000386a:	60e2                	ld	ra,24(sp)
    8000386c:	6442                	ld	s0,16(sp)
    8000386e:	64a2                	ld	s1,8(sp)
    80003870:	6902                	ld	s2,0(sp)
    80003872:	6105                	addi	sp,sp,32
    80003874:	8082                	ret
    panic("iunlock");
    80003876:	00005517          	auipc	a0,0x5
    8000387a:	ee250513          	addi	a0,a0,-286 # 80008758 <syscallnumber_to_name+0x1a8>
    8000387e:	ffffd097          	auipc	ra,0xffffd
    80003882:	cca080e7          	jalr	-822(ra) # 80000548 <panic>

0000000080003886 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003886:	7179                	addi	sp,sp,-48
    80003888:	f406                	sd	ra,40(sp)
    8000388a:	f022                	sd	s0,32(sp)
    8000388c:	ec26                	sd	s1,24(sp)
    8000388e:	e84a                	sd	s2,16(sp)
    80003890:	e44e                	sd	s3,8(sp)
    80003892:	e052                	sd	s4,0(sp)
    80003894:	1800                	addi	s0,sp,48
    80003896:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003898:	05050493          	addi	s1,a0,80
    8000389c:	08050913          	addi	s2,a0,128
    800038a0:	a021                	j	800038a8 <itrunc+0x22>
    800038a2:	0491                	addi	s1,s1,4
    800038a4:	01248d63          	beq	s1,s2,800038be <itrunc+0x38>
    if(ip->addrs[i]){
    800038a8:	408c                	lw	a1,0(s1)
    800038aa:	dde5                	beqz	a1,800038a2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038ac:	0009a503          	lw	a0,0(s3)
    800038b0:	00000097          	auipc	ra,0x0
    800038b4:	90c080e7          	jalr	-1780(ra) # 800031bc <bfree>
      ip->addrs[i] = 0;
    800038b8:	0004a023          	sw	zero,0(s1)
    800038bc:	b7dd                	j	800038a2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038be:	0809a583          	lw	a1,128(s3)
    800038c2:	e185                	bnez	a1,800038e2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038c4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038c8:	854e                	mv	a0,s3
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	de4080e7          	jalr	-540(ra) # 800036ae <iupdate>
}
    800038d2:	70a2                	ld	ra,40(sp)
    800038d4:	7402                	ld	s0,32(sp)
    800038d6:	64e2                	ld	s1,24(sp)
    800038d8:	6942                	ld	s2,16(sp)
    800038da:	69a2                	ld	s3,8(sp)
    800038dc:	6a02                	ld	s4,0(sp)
    800038de:	6145                	addi	sp,sp,48
    800038e0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038e2:	0009a503          	lw	a0,0(s3)
    800038e6:	fffff097          	auipc	ra,0xfffff
    800038ea:	690080e7          	jalr	1680(ra) # 80002f76 <bread>
    800038ee:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038f0:	05850493          	addi	s1,a0,88
    800038f4:	45850913          	addi	s2,a0,1112
    800038f8:	a811                	j	8000390c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038fa:	0009a503          	lw	a0,0(s3)
    800038fe:	00000097          	auipc	ra,0x0
    80003902:	8be080e7          	jalr	-1858(ra) # 800031bc <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003906:	0491                	addi	s1,s1,4
    80003908:	01248563          	beq	s1,s2,80003912 <itrunc+0x8c>
      if(a[j])
    8000390c:	408c                	lw	a1,0(s1)
    8000390e:	dde5                	beqz	a1,80003906 <itrunc+0x80>
    80003910:	b7ed                	j	800038fa <itrunc+0x74>
    brelse(bp);
    80003912:	8552                	mv	a0,s4
    80003914:	fffff097          	auipc	ra,0xfffff
    80003918:	792080e7          	jalr	1938(ra) # 800030a6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000391c:	0809a583          	lw	a1,128(s3)
    80003920:	0009a503          	lw	a0,0(s3)
    80003924:	00000097          	auipc	ra,0x0
    80003928:	898080e7          	jalr	-1896(ra) # 800031bc <bfree>
    ip->addrs[NDIRECT] = 0;
    8000392c:	0809a023          	sw	zero,128(s3)
    80003930:	bf51                	j	800038c4 <itrunc+0x3e>

0000000080003932 <iput>:
{
    80003932:	1101                	addi	sp,sp,-32
    80003934:	ec06                	sd	ra,24(sp)
    80003936:	e822                	sd	s0,16(sp)
    80003938:	e426                	sd	s1,8(sp)
    8000393a:	e04a                	sd	s2,0(sp)
    8000393c:	1000                	addi	s0,sp,32
    8000393e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003940:	0001c517          	auipc	a0,0x1c
    80003944:	52050513          	addi	a0,a0,1312 # 8001fe60 <icache>
    80003948:	ffffd097          	auipc	ra,0xffffd
    8000394c:	312080e7          	jalr	786(ra) # 80000c5a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003950:	4498                	lw	a4,8(s1)
    80003952:	4785                	li	a5,1
    80003954:	02f70363          	beq	a4,a5,8000397a <iput+0x48>
  ip->ref--;
    80003958:	449c                	lw	a5,8(s1)
    8000395a:	37fd                	addiw	a5,a5,-1
    8000395c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000395e:	0001c517          	auipc	a0,0x1c
    80003962:	50250513          	addi	a0,a0,1282 # 8001fe60 <icache>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	3a8080e7          	jalr	936(ra) # 80000d0e <release>
}
    8000396e:	60e2                	ld	ra,24(sp)
    80003970:	6442                	ld	s0,16(sp)
    80003972:	64a2                	ld	s1,8(sp)
    80003974:	6902                	ld	s2,0(sp)
    80003976:	6105                	addi	sp,sp,32
    80003978:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000397a:	40bc                	lw	a5,64(s1)
    8000397c:	dff1                	beqz	a5,80003958 <iput+0x26>
    8000397e:	04a49783          	lh	a5,74(s1)
    80003982:	fbf9                	bnez	a5,80003958 <iput+0x26>
    acquiresleep(&ip->lock);
    80003984:	01048913          	addi	s2,s1,16
    80003988:	854a                	mv	a0,s2
    8000398a:	00001097          	auipc	ra,0x1
    8000398e:	aa8080e7          	jalr	-1368(ra) # 80004432 <acquiresleep>
    release(&icache.lock);
    80003992:	0001c517          	auipc	a0,0x1c
    80003996:	4ce50513          	addi	a0,a0,1230 # 8001fe60 <icache>
    8000399a:	ffffd097          	auipc	ra,0xffffd
    8000399e:	374080e7          	jalr	884(ra) # 80000d0e <release>
    itrunc(ip);
    800039a2:	8526                	mv	a0,s1
    800039a4:	00000097          	auipc	ra,0x0
    800039a8:	ee2080e7          	jalr	-286(ra) # 80003886 <itrunc>
    ip->type = 0;
    800039ac:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039b0:	8526                	mv	a0,s1
    800039b2:	00000097          	auipc	ra,0x0
    800039b6:	cfc080e7          	jalr	-772(ra) # 800036ae <iupdate>
    ip->valid = 0;
    800039ba:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039be:	854a                	mv	a0,s2
    800039c0:	00001097          	auipc	ra,0x1
    800039c4:	ac8080e7          	jalr	-1336(ra) # 80004488 <releasesleep>
    acquire(&icache.lock);
    800039c8:	0001c517          	auipc	a0,0x1c
    800039cc:	49850513          	addi	a0,a0,1176 # 8001fe60 <icache>
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	28a080e7          	jalr	650(ra) # 80000c5a <acquire>
    800039d8:	b741                	j	80003958 <iput+0x26>

00000000800039da <iunlockput>:
{
    800039da:	1101                	addi	sp,sp,-32
    800039dc:	ec06                	sd	ra,24(sp)
    800039de:	e822                	sd	s0,16(sp)
    800039e0:	e426                	sd	s1,8(sp)
    800039e2:	1000                	addi	s0,sp,32
    800039e4:	84aa                	mv	s1,a0
  iunlock(ip);
    800039e6:	00000097          	auipc	ra,0x0
    800039ea:	e54080e7          	jalr	-428(ra) # 8000383a <iunlock>
  iput(ip);
    800039ee:	8526                	mv	a0,s1
    800039f0:	00000097          	auipc	ra,0x0
    800039f4:	f42080e7          	jalr	-190(ra) # 80003932 <iput>
}
    800039f8:	60e2                	ld	ra,24(sp)
    800039fa:	6442                	ld	s0,16(sp)
    800039fc:	64a2                	ld	s1,8(sp)
    800039fe:	6105                	addi	sp,sp,32
    80003a00:	8082                	ret

0000000080003a02 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a02:	1141                	addi	sp,sp,-16
    80003a04:	e422                	sd	s0,8(sp)
    80003a06:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a08:	411c                	lw	a5,0(a0)
    80003a0a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a0c:	415c                	lw	a5,4(a0)
    80003a0e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a10:	04451783          	lh	a5,68(a0)
    80003a14:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a18:	04a51783          	lh	a5,74(a0)
    80003a1c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a20:	04c56783          	lwu	a5,76(a0)
    80003a24:	e99c                	sd	a5,16(a1)
}
    80003a26:	6422                	ld	s0,8(sp)
    80003a28:	0141                	addi	sp,sp,16
    80003a2a:	8082                	ret

0000000080003a2c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a2c:	457c                	lw	a5,76(a0)
    80003a2e:	0ed7e863          	bltu	a5,a3,80003b1e <readi+0xf2>
{
    80003a32:	7159                	addi	sp,sp,-112
    80003a34:	f486                	sd	ra,104(sp)
    80003a36:	f0a2                	sd	s0,96(sp)
    80003a38:	eca6                	sd	s1,88(sp)
    80003a3a:	e8ca                	sd	s2,80(sp)
    80003a3c:	e4ce                	sd	s3,72(sp)
    80003a3e:	e0d2                	sd	s4,64(sp)
    80003a40:	fc56                	sd	s5,56(sp)
    80003a42:	f85a                	sd	s6,48(sp)
    80003a44:	f45e                	sd	s7,40(sp)
    80003a46:	f062                	sd	s8,32(sp)
    80003a48:	ec66                	sd	s9,24(sp)
    80003a4a:	e86a                	sd	s10,16(sp)
    80003a4c:	e46e                	sd	s11,8(sp)
    80003a4e:	1880                	addi	s0,sp,112
    80003a50:	8baa                	mv	s7,a0
    80003a52:	8c2e                	mv	s8,a1
    80003a54:	8ab2                	mv	s5,a2
    80003a56:	84b6                	mv	s1,a3
    80003a58:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a5a:	9f35                	addw	a4,a4,a3
    return 0;
    80003a5c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a5e:	08d76f63          	bltu	a4,a3,80003afc <readi+0xd0>
  if(off + n > ip->size)
    80003a62:	00e7f463          	bgeu	a5,a4,80003a6a <readi+0x3e>
    n = ip->size - off;
    80003a66:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a6a:	0a0b0863          	beqz	s6,80003b1a <readi+0xee>
    80003a6e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a70:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a74:	5cfd                	li	s9,-1
    80003a76:	a82d                	j	80003ab0 <readi+0x84>
    80003a78:	020a1d93          	slli	s11,s4,0x20
    80003a7c:	020ddd93          	srli	s11,s11,0x20
    80003a80:	05890613          	addi	a2,s2,88
    80003a84:	86ee                	mv	a3,s11
    80003a86:	963a                	add	a2,a2,a4
    80003a88:	85d6                	mv	a1,s5
    80003a8a:	8562                	mv	a0,s8
    80003a8c:	fffff097          	auipc	ra,0xfffff
    80003a90:	a16080e7          	jalr	-1514(ra) # 800024a2 <either_copyout>
    80003a94:	05950d63          	beq	a0,s9,80003aee <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003a98:	854a                	mv	a0,s2
    80003a9a:	fffff097          	auipc	ra,0xfffff
    80003a9e:	60c080e7          	jalr	1548(ra) # 800030a6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aa2:	013a09bb          	addw	s3,s4,s3
    80003aa6:	009a04bb          	addw	s1,s4,s1
    80003aaa:	9aee                	add	s5,s5,s11
    80003aac:	0569f663          	bgeu	s3,s6,80003af8 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ab0:	000ba903          	lw	s2,0(s7)
    80003ab4:	00a4d59b          	srliw	a1,s1,0xa
    80003ab8:	855e                	mv	a0,s7
    80003aba:	00000097          	auipc	ra,0x0
    80003abe:	8b0080e7          	jalr	-1872(ra) # 8000336a <bmap>
    80003ac2:	0005059b          	sext.w	a1,a0
    80003ac6:	854a                	mv	a0,s2
    80003ac8:	fffff097          	auipc	ra,0xfffff
    80003acc:	4ae080e7          	jalr	1198(ra) # 80002f76 <bread>
    80003ad0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ad2:	3ff4f713          	andi	a4,s1,1023
    80003ad6:	40ed07bb          	subw	a5,s10,a4
    80003ada:	413b06bb          	subw	a3,s6,s3
    80003ade:	8a3e                	mv	s4,a5
    80003ae0:	2781                	sext.w	a5,a5
    80003ae2:	0006861b          	sext.w	a2,a3
    80003ae6:	f8f679e3          	bgeu	a2,a5,80003a78 <readi+0x4c>
    80003aea:	8a36                	mv	s4,a3
    80003aec:	b771                	j	80003a78 <readi+0x4c>
      brelse(bp);
    80003aee:	854a                	mv	a0,s2
    80003af0:	fffff097          	auipc	ra,0xfffff
    80003af4:	5b6080e7          	jalr	1462(ra) # 800030a6 <brelse>
  }
  return tot;
    80003af8:	0009851b          	sext.w	a0,s3
}
    80003afc:	70a6                	ld	ra,104(sp)
    80003afe:	7406                	ld	s0,96(sp)
    80003b00:	64e6                	ld	s1,88(sp)
    80003b02:	6946                	ld	s2,80(sp)
    80003b04:	69a6                	ld	s3,72(sp)
    80003b06:	6a06                	ld	s4,64(sp)
    80003b08:	7ae2                	ld	s5,56(sp)
    80003b0a:	7b42                	ld	s6,48(sp)
    80003b0c:	7ba2                	ld	s7,40(sp)
    80003b0e:	7c02                	ld	s8,32(sp)
    80003b10:	6ce2                	ld	s9,24(sp)
    80003b12:	6d42                	ld	s10,16(sp)
    80003b14:	6da2                	ld	s11,8(sp)
    80003b16:	6165                	addi	sp,sp,112
    80003b18:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b1a:	89da                	mv	s3,s6
    80003b1c:	bff1                	j	80003af8 <readi+0xcc>
    return 0;
    80003b1e:	4501                	li	a0,0
}
    80003b20:	8082                	ret

0000000080003b22 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b22:	457c                	lw	a5,76(a0)
    80003b24:	10d7e663          	bltu	a5,a3,80003c30 <writei+0x10e>
{
    80003b28:	7159                	addi	sp,sp,-112
    80003b2a:	f486                	sd	ra,104(sp)
    80003b2c:	f0a2                	sd	s0,96(sp)
    80003b2e:	eca6                	sd	s1,88(sp)
    80003b30:	e8ca                	sd	s2,80(sp)
    80003b32:	e4ce                	sd	s3,72(sp)
    80003b34:	e0d2                	sd	s4,64(sp)
    80003b36:	fc56                	sd	s5,56(sp)
    80003b38:	f85a                	sd	s6,48(sp)
    80003b3a:	f45e                	sd	s7,40(sp)
    80003b3c:	f062                	sd	s8,32(sp)
    80003b3e:	ec66                	sd	s9,24(sp)
    80003b40:	e86a                	sd	s10,16(sp)
    80003b42:	e46e                	sd	s11,8(sp)
    80003b44:	1880                	addi	s0,sp,112
    80003b46:	8baa                	mv	s7,a0
    80003b48:	8c2e                	mv	s8,a1
    80003b4a:	8ab2                	mv	s5,a2
    80003b4c:	8936                	mv	s2,a3
    80003b4e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b50:	00e687bb          	addw	a5,a3,a4
    80003b54:	0ed7e063          	bltu	a5,a3,80003c34 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b58:	00043737          	lui	a4,0x43
    80003b5c:	0cf76e63          	bltu	a4,a5,80003c38 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b60:	0a0b0763          	beqz	s6,80003c0e <writei+0xec>
    80003b64:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b66:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b6a:	5cfd                	li	s9,-1
    80003b6c:	a091                	j	80003bb0 <writei+0x8e>
    80003b6e:	02099d93          	slli	s11,s3,0x20
    80003b72:	020ddd93          	srli	s11,s11,0x20
    80003b76:	05848513          	addi	a0,s1,88
    80003b7a:	86ee                	mv	a3,s11
    80003b7c:	8656                	mv	a2,s5
    80003b7e:	85e2                	mv	a1,s8
    80003b80:	953a                	add	a0,a0,a4
    80003b82:	fffff097          	auipc	ra,0xfffff
    80003b86:	976080e7          	jalr	-1674(ra) # 800024f8 <either_copyin>
    80003b8a:	07950263          	beq	a0,s9,80003bee <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b8e:	8526                	mv	a0,s1
    80003b90:	00000097          	auipc	ra,0x0
    80003b94:	77a080e7          	jalr	1914(ra) # 8000430a <log_write>
    brelse(bp);
    80003b98:	8526                	mv	a0,s1
    80003b9a:	fffff097          	auipc	ra,0xfffff
    80003b9e:	50c080e7          	jalr	1292(ra) # 800030a6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ba2:	01498a3b          	addw	s4,s3,s4
    80003ba6:	0129893b          	addw	s2,s3,s2
    80003baa:	9aee                	add	s5,s5,s11
    80003bac:	056a7663          	bgeu	s4,s6,80003bf8 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bb0:	000ba483          	lw	s1,0(s7)
    80003bb4:	00a9559b          	srliw	a1,s2,0xa
    80003bb8:	855e                	mv	a0,s7
    80003bba:	fffff097          	auipc	ra,0xfffff
    80003bbe:	7b0080e7          	jalr	1968(ra) # 8000336a <bmap>
    80003bc2:	0005059b          	sext.w	a1,a0
    80003bc6:	8526                	mv	a0,s1
    80003bc8:	fffff097          	auipc	ra,0xfffff
    80003bcc:	3ae080e7          	jalr	942(ra) # 80002f76 <bread>
    80003bd0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd2:	3ff97713          	andi	a4,s2,1023
    80003bd6:	40ed07bb          	subw	a5,s10,a4
    80003bda:	414b06bb          	subw	a3,s6,s4
    80003bde:	89be                	mv	s3,a5
    80003be0:	2781                	sext.w	a5,a5
    80003be2:	0006861b          	sext.w	a2,a3
    80003be6:	f8f674e3          	bgeu	a2,a5,80003b6e <writei+0x4c>
    80003bea:	89b6                	mv	s3,a3
    80003bec:	b749                	j	80003b6e <writei+0x4c>
      brelse(bp);
    80003bee:	8526                	mv	a0,s1
    80003bf0:	fffff097          	auipc	ra,0xfffff
    80003bf4:	4b6080e7          	jalr	1206(ra) # 800030a6 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003bf8:	04cba783          	lw	a5,76(s7)
    80003bfc:	0127f463          	bgeu	a5,s2,80003c04 <writei+0xe2>
      ip->size = off;
    80003c00:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c04:	855e                	mv	a0,s7
    80003c06:	00000097          	auipc	ra,0x0
    80003c0a:	aa8080e7          	jalr	-1368(ra) # 800036ae <iupdate>
  }

  return n;
    80003c0e:	000b051b          	sext.w	a0,s6
}
    80003c12:	70a6                	ld	ra,104(sp)
    80003c14:	7406                	ld	s0,96(sp)
    80003c16:	64e6                	ld	s1,88(sp)
    80003c18:	6946                	ld	s2,80(sp)
    80003c1a:	69a6                	ld	s3,72(sp)
    80003c1c:	6a06                	ld	s4,64(sp)
    80003c1e:	7ae2                	ld	s5,56(sp)
    80003c20:	7b42                	ld	s6,48(sp)
    80003c22:	7ba2                	ld	s7,40(sp)
    80003c24:	7c02                	ld	s8,32(sp)
    80003c26:	6ce2                	ld	s9,24(sp)
    80003c28:	6d42                	ld	s10,16(sp)
    80003c2a:	6da2                	ld	s11,8(sp)
    80003c2c:	6165                	addi	sp,sp,112
    80003c2e:	8082                	ret
    return -1;
    80003c30:	557d                	li	a0,-1
}
    80003c32:	8082                	ret
    return -1;
    80003c34:	557d                	li	a0,-1
    80003c36:	bff1                	j	80003c12 <writei+0xf0>
    return -1;
    80003c38:	557d                	li	a0,-1
    80003c3a:	bfe1                	j	80003c12 <writei+0xf0>

0000000080003c3c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c3c:	1141                	addi	sp,sp,-16
    80003c3e:	e406                	sd	ra,8(sp)
    80003c40:	e022                	sd	s0,0(sp)
    80003c42:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c44:	4639                	li	a2,14
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	1ec080e7          	jalr	492(ra) # 80000e32 <strncmp>
}
    80003c4e:	60a2                	ld	ra,8(sp)
    80003c50:	6402                	ld	s0,0(sp)
    80003c52:	0141                	addi	sp,sp,16
    80003c54:	8082                	ret

0000000080003c56 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c56:	7139                	addi	sp,sp,-64
    80003c58:	fc06                	sd	ra,56(sp)
    80003c5a:	f822                	sd	s0,48(sp)
    80003c5c:	f426                	sd	s1,40(sp)
    80003c5e:	f04a                	sd	s2,32(sp)
    80003c60:	ec4e                	sd	s3,24(sp)
    80003c62:	e852                	sd	s4,16(sp)
    80003c64:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c66:	04451703          	lh	a4,68(a0)
    80003c6a:	4785                	li	a5,1
    80003c6c:	00f71a63          	bne	a4,a5,80003c80 <dirlookup+0x2a>
    80003c70:	892a                	mv	s2,a0
    80003c72:	89ae                	mv	s3,a1
    80003c74:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c76:	457c                	lw	a5,76(a0)
    80003c78:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c7a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c7c:	e79d                	bnez	a5,80003caa <dirlookup+0x54>
    80003c7e:	a8a5                	j	80003cf6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c80:	00005517          	auipc	a0,0x5
    80003c84:	ae050513          	addi	a0,a0,-1312 # 80008760 <syscallnumber_to_name+0x1b0>
    80003c88:	ffffd097          	auipc	ra,0xffffd
    80003c8c:	8c0080e7          	jalr	-1856(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003c90:	00005517          	auipc	a0,0x5
    80003c94:	ae850513          	addi	a0,a0,-1304 # 80008778 <syscallnumber_to_name+0x1c8>
    80003c98:	ffffd097          	auipc	ra,0xffffd
    80003c9c:	8b0080e7          	jalr	-1872(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ca0:	24c1                	addiw	s1,s1,16
    80003ca2:	04c92783          	lw	a5,76(s2)
    80003ca6:	04f4f763          	bgeu	s1,a5,80003cf4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003caa:	4741                	li	a4,16
    80003cac:	86a6                	mv	a3,s1
    80003cae:	fc040613          	addi	a2,s0,-64
    80003cb2:	4581                	li	a1,0
    80003cb4:	854a                	mv	a0,s2
    80003cb6:	00000097          	auipc	ra,0x0
    80003cba:	d76080e7          	jalr	-650(ra) # 80003a2c <readi>
    80003cbe:	47c1                	li	a5,16
    80003cc0:	fcf518e3          	bne	a0,a5,80003c90 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cc4:	fc045783          	lhu	a5,-64(s0)
    80003cc8:	dfe1                	beqz	a5,80003ca0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cca:	fc240593          	addi	a1,s0,-62
    80003cce:	854e                	mv	a0,s3
    80003cd0:	00000097          	auipc	ra,0x0
    80003cd4:	f6c080e7          	jalr	-148(ra) # 80003c3c <namecmp>
    80003cd8:	f561                	bnez	a0,80003ca0 <dirlookup+0x4a>
      if(poff)
    80003cda:	000a0463          	beqz	s4,80003ce2 <dirlookup+0x8c>
        *poff = off;
    80003cde:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ce2:	fc045583          	lhu	a1,-64(s0)
    80003ce6:	00092503          	lw	a0,0(s2)
    80003cea:	fffff097          	auipc	ra,0xfffff
    80003cee:	75a080e7          	jalr	1882(ra) # 80003444 <iget>
    80003cf2:	a011                	j	80003cf6 <dirlookup+0xa0>
  return 0;
    80003cf4:	4501                	li	a0,0
}
    80003cf6:	70e2                	ld	ra,56(sp)
    80003cf8:	7442                	ld	s0,48(sp)
    80003cfa:	74a2                	ld	s1,40(sp)
    80003cfc:	7902                	ld	s2,32(sp)
    80003cfe:	69e2                	ld	s3,24(sp)
    80003d00:	6a42                	ld	s4,16(sp)
    80003d02:	6121                	addi	sp,sp,64
    80003d04:	8082                	ret

0000000080003d06 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d06:	711d                	addi	sp,sp,-96
    80003d08:	ec86                	sd	ra,88(sp)
    80003d0a:	e8a2                	sd	s0,80(sp)
    80003d0c:	e4a6                	sd	s1,72(sp)
    80003d0e:	e0ca                	sd	s2,64(sp)
    80003d10:	fc4e                	sd	s3,56(sp)
    80003d12:	f852                	sd	s4,48(sp)
    80003d14:	f456                	sd	s5,40(sp)
    80003d16:	f05a                	sd	s6,32(sp)
    80003d18:	ec5e                	sd	s7,24(sp)
    80003d1a:	e862                	sd	s8,16(sp)
    80003d1c:	e466                	sd	s9,8(sp)
    80003d1e:	1080                	addi	s0,sp,96
    80003d20:	84aa                	mv	s1,a0
    80003d22:	8b2e                	mv	s6,a1
    80003d24:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d26:	00054703          	lbu	a4,0(a0)
    80003d2a:	02f00793          	li	a5,47
    80003d2e:	02f70363          	beq	a4,a5,80003d54 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d32:	ffffe097          	auipc	ra,0xffffe
    80003d36:	cf6080e7          	jalr	-778(ra) # 80001a28 <myproc>
    80003d3a:	15053503          	ld	a0,336(a0)
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	9fc080e7          	jalr	-1540(ra) # 8000373a <idup>
    80003d46:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d48:	02f00913          	li	s2,47
  len = path - s;
    80003d4c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d4e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d50:	4c05                	li	s8,1
    80003d52:	a865                	j	80003e0a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d54:	4585                	li	a1,1
    80003d56:	4505                	li	a0,1
    80003d58:	fffff097          	auipc	ra,0xfffff
    80003d5c:	6ec080e7          	jalr	1772(ra) # 80003444 <iget>
    80003d60:	89aa                	mv	s3,a0
    80003d62:	b7dd                	j	80003d48 <namex+0x42>
      iunlockput(ip);
    80003d64:	854e                	mv	a0,s3
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	c74080e7          	jalr	-908(ra) # 800039da <iunlockput>
      return 0;
    80003d6e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d70:	854e                	mv	a0,s3
    80003d72:	60e6                	ld	ra,88(sp)
    80003d74:	6446                	ld	s0,80(sp)
    80003d76:	64a6                	ld	s1,72(sp)
    80003d78:	6906                	ld	s2,64(sp)
    80003d7a:	79e2                	ld	s3,56(sp)
    80003d7c:	7a42                	ld	s4,48(sp)
    80003d7e:	7aa2                	ld	s5,40(sp)
    80003d80:	7b02                	ld	s6,32(sp)
    80003d82:	6be2                	ld	s7,24(sp)
    80003d84:	6c42                	ld	s8,16(sp)
    80003d86:	6ca2                	ld	s9,8(sp)
    80003d88:	6125                	addi	sp,sp,96
    80003d8a:	8082                	ret
      iunlock(ip);
    80003d8c:	854e                	mv	a0,s3
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	aac080e7          	jalr	-1364(ra) # 8000383a <iunlock>
      return ip;
    80003d96:	bfe9                	j	80003d70 <namex+0x6a>
      iunlockput(ip);
    80003d98:	854e                	mv	a0,s3
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	c40080e7          	jalr	-960(ra) # 800039da <iunlockput>
      return 0;
    80003da2:	89d2                	mv	s3,s4
    80003da4:	b7f1                	j	80003d70 <namex+0x6a>
  len = path - s;
    80003da6:	40b48633          	sub	a2,s1,a1
    80003daa:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003dae:	094cd463          	bge	s9,s4,80003e36 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003db2:	4639                	li	a2,14
    80003db4:	8556                	mv	a0,s5
    80003db6:	ffffd097          	auipc	ra,0xffffd
    80003dba:	000080e7          	jalr	ra # 80000db6 <memmove>
  while(*path == '/')
    80003dbe:	0004c783          	lbu	a5,0(s1)
    80003dc2:	01279763          	bne	a5,s2,80003dd0 <namex+0xca>
    path++;
    80003dc6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dc8:	0004c783          	lbu	a5,0(s1)
    80003dcc:	ff278de3          	beq	a5,s2,80003dc6 <namex+0xc0>
    ilock(ip);
    80003dd0:	854e                	mv	a0,s3
    80003dd2:	00000097          	auipc	ra,0x0
    80003dd6:	9a6080e7          	jalr	-1626(ra) # 80003778 <ilock>
    if(ip->type != T_DIR){
    80003dda:	04499783          	lh	a5,68(s3)
    80003dde:	f98793e3          	bne	a5,s8,80003d64 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003de2:	000b0563          	beqz	s6,80003dec <namex+0xe6>
    80003de6:	0004c783          	lbu	a5,0(s1)
    80003dea:	d3cd                	beqz	a5,80003d8c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dec:	865e                	mv	a2,s7
    80003dee:	85d6                	mv	a1,s5
    80003df0:	854e                	mv	a0,s3
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	e64080e7          	jalr	-412(ra) # 80003c56 <dirlookup>
    80003dfa:	8a2a                	mv	s4,a0
    80003dfc:	dd51                	beqz	a0,80003d98 <namex+0x92>
    iunlockput(ip);
    80003dfe:	854e                	mv	a0,s3
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	bda080e7          	jalr	-1062(ra) # 800039da <iunlockput>
    ip = next;
    80003e08:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e0a:	0004c783          	lbu	a5,0(s1)
    80003e0e:	05279763          	bne	a5,s2,80003e5c <namex+0x156>
    path++;
    80003e12:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e14:	0004c783          	lbu	a5,0(s1)
    80003e18:	ff278de3          	beq	a5,s2,80003e12 <namex+0x10c>
  if(*path == 0)
    80003e1c:	c79d                	beqz	a5,80003e4a <namex+0x144>
    path++;
    80003e1e:	85a6                	mv	a1,s1
  len = path - s;
    80003e20:	8a5e                	mv	s4,s7
    80003e22:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e24:	01278963          	beq	a5,s2,80003e36 <namex+0x130>
    80003e28:	dfbd                	beqz	a5,80003da6 <namex+0xa0>
    path++;
    80003e2a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e2c:	0004c783          	lbu	a5,0(s1)
    80003e30:	ff279ce3          	bne	a5,s2,80003e28 <namex+0x122>
    80003e34:	bf8d                	j	80003da6 <namex+0xa0>
    memmove(name, s, len);
    80003e36:	2601                	sext.w	a2,a2
    80003e38:	8556                	mv	a0,s5
    80003e3a:	ffffd097          	auipc	ra,0xffffd
    80003e3e:	f7c080e7          	jalr	-132(ra) # 80000db6 <memmove>
    name[len] = 0;
    80003e42:	9a56                	add	s4,s4,s5
    80003e44:	000a0023          	sb	zero,0(s4)
    80003e48:	bf9d                	j	80003dbe <namex+0xb8>
  if(nameiparent){
    80003e4a:	f20b03e3          	beqz	s6,80003d70 <namex+0x6a>
    iput(ip);
    80003e4e:	854e                	mv	a0,s3
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	ae2080e7          	jalr	-1310(ra) # 80003932 <iput>
    return 0;
    80003e58:	4981                	li	s3,0
    80003e5a:	bf19                	j	80003d70 <namex+0x6a>
  if(*path == 0)
    80003e5c:	d7fd                	beqz	a5,80003e4a <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e5e:	0004c783          	lbu	a5,0(s1)
    80003e62:	85a6                	mv	a1,s1
    80003e64:	b7d1                	j	80003e28 <namex+0x122>

0000000080003e66 <dirlink>:
{
    80003e66:	7139                	addi	sp,sp,-64
    80003e68:	fc06                	sd	ra,56(sp)
    80003e6a:	f822                	sd	s0,48(sp)
    80003e6c:	f426                	sd	s1,40(sp)
    80003e6e:	f04a                	sd	s2,32(sp)
    80003e70:	ec4e                	sd	s3,24(sp)
    80003e72:	e852                	sd	s4,16(sp)
    80003e74:	0080                	addi	s0,sp,64
    80003e76:	892a                	mv	s2,a0
    80003e78:	8a2e                	mv	s4,a1
    80003e7a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e7c:	4601                	li	a2,0
    80003e7e:	00000097          	auipc	ra,0x0
    80003e82:	dd8080e7          	jalr	-552(ra) # 80003c56 <dirlookup>
    80003e86:	e93d                	bnez	a0,80003efc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e88:	04c92483          	lw	s1,76(s2)
    80003e8c:	c49d                	beqz	s1,80003eba <dirlink+0x54>
    80003e8e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e90:	4741                	li	a4,16
    80003e92:	86a6                	mv	a3,s1
    80003e94:	fc040613          	addi	a2,s0,-64
    80003e98:	4581                	li	a1,0
    80003e9a:	854a                	mv	a0,s2
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	b90080e7          	jalr	-1136(ra) # 80003a2c <readi>
    80003ea4:	47c1                	li	a5,16
    80003ea6:	06f51163          	bne	a0,a5,80003f08 <dirlink+0xa2>
    if(de.inum == 0)
    80003eaa:	fc045783          	lhu	a5,-64(s0)
    80003eae:	c791                	beqz	a5,80003eba <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb0:	24c1                	addiw	s1,s1,16
    80003eb2:	04c92783          	lw	a5,76(s2)
    80003eb6:	fcf4ede3          	bltu	s1,a5,80003e90 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003eba:	4639                	li	a2,14
    80003ebc:	85d2                	mv	a1,s4
    80003ebe:	fc240513          	addi	a0,s0,-62
    80003ec2:	ffffd097          	auipc	ra,0xffffd
    80003ec6:	fac080e7          	jalr	-84(ra) # 80000e6e <strncpy>
  de.inum = inum;
    80003eca:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ece:	4741                	li	a4,16
    80003ed0:	86a6                	mv	a3,s1
    80003ed2:	fc040613          	addi	a2,s0,-64
    80003ed6:	4581                	li	a1,0
    80003ed8:	854a                	mv	a0,s2
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	c48080e7          	jalr	-952(ra) # 80003b22 <writei>
    80003ee2:	872a                	mv	a4,a0
    80003ee4:	47c1                	li	a5,16
  return 0;
    80003ee6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee8:	02f71863          	bne	a4,a5,80003f18 <dirlink+0xb2>
}
    80003eec:	70e2                	ld	ra,56(sp)
    80003eee:	7442                	ld	s0,48(sp)
    80003ef0:	74a2                	ld	s1,40(sp)
    80003ef2:	7902                	ld	s2,32(sp)
    80003ef4:	69e2                	ld	s3,24(sp)
    80003ef6:	6a42                	ld	s4,16(sp)
    80003ef8:	6121                	addi	sp,sp,64
    80003efa:	8082                	ret
    iput(ip);
    80003efc:	00000097          	auipc	ra,0x0
    80003f00:	a36080e7          	jalr	-1482(ra) # 80003932 <iput>
    return -1;
    80003f04:	557d                	li	a0,-1
    80003f06:	b7dd                	j	80003eec <dirlink+0x86>
      panic("dirlink read");
    80003f08:	00005517          	auipc	a0,0x5
    80003f0c:	88050513          	addi	a0,a0,-1920 # 80008788 <syscallnumber_to_name+0x1d8>
    80003f10:	ffffc097          	auipc	ra,0xffffc
    80003f14:	638080e7          	jalr	1592(ra) # 80000548 <panic>
    panic("dirlink");
    80003f18:	00005517          	auipc	a0,0x5
    80003f1c:	98850513          	addi	a0,a0,-1656 # 800088a0 <syscallnumber_to_name+0x2f0>
    80003f20:	ffffc097          	auipc	ra,0xffffc
    80003f24:	628080e7          	jalr	1576(ra) # 80000548 <panic>

0000000080003f28 <namei>:

struct inode*
namei(char *path)
{
    80003f28:	1101                	addi	sp,sp,-32
    80003f2a:	ec06                	sd	ra,24(sp)
    80003f2c:	e822                	sd	s0,16(sp)
    80003f2e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f30:	fe040613          	addi	a2,s0,-32
    80003f34:	4581                	li	a1,0
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	dd0080e7          	jalr	-560(ra) # 80003d06 <namex>
}
    80003f3e:	60e2                	ld	ra,24(sp)
    80003f40:	6442                	ld	s0,16(sp)
    80003f42:	6105                	addi	sp,sp,32
    80003f44:	8082                	ret

0000000080003f46 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f46:	1141                	addi	sp,sp,-16
    80003f48:	e406                	sd	ra,8(sp)
    80003f4a:	e022                	sd	s0,0(sp)
    80003f4c:	0800                	addi	s0,sp,16
    80003f4e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f50:	4585                	li	a1,1
    80003f52:	00000097          	auipc	ra,0x0
    80003f56:	db4080e7          	jalr	-588(ra) # 80003d06 <namex>
}
    80003f5a:	60a2                	ld	ra,8(sp)
    80003f5c:	6402                	ld	s0,0(sp)
    80003f5e:	0141                	addi	sp,sp,16
    80003f60:	8082                	ret

0000000080003f62 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f62:	1101                	addi	sp,sp,-32
    80003f64:	ec06                	sd	ra,24(sp)
    80003f66:	e822                	sd	s0,16(sp)
    80003f68:	e426                	sd	s1,8(sp)
    80003f6a:	e04a                	sd	s2,0(sp)
    80003f6c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f6e:	0001e917          	auipc	s2,0x1e
    80003f72:	99a90913          	addi	s2,s2,-1638 # 80021908 <log>
    80003f76:	01892583          	lw	a1,24(s2)
    80003f7a:	02892503          	lw	a0,40(s2)
    80003f7e:	fffff097          	auipc	ra,0xfffff
    80003f82:	ff8080e7          	jalr	-8(ra) # 80002f76 <bread>
    80003f86:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f88:	02c92683          	lw	a3,44(s2)
    80003f8c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f8e:	02d05763          	blez	a3,80003fbc <write_head+0x5a>
    80003f92:	0001e797          	auipc	a5,0x1e
    80003f96:	9a678793          	addi	a5,a5,-1626 # 80021938 <log+0x30>
    80003f9a:	05c50713          	addi	a4,a0,92
    80003f9e:	36fd                	addiw	a3,a3,-1
    80003fa0:	1682                	slli	a3,a3,0x20
    80003fa2:	9281                	srli	a3,a3,0x20
    80003fa4:	068a                	slli	a3,a3,0x2
    80003fa6:	0001e617          	auipc	a2,0x1e
    80003faa:	99660613          	addi	a2,a2,-1642 # 8002193c <log+0x34>
    80003fae:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fb0:	4390                	lw	a2,0(a5)
    80003fb2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fb4:	0791                	addi	a5,a5,4
    80003fb6:	0711                	addi	a4,a4,4
    80003fb8:	fed79ce3          	bne	a5,a3,80003fb0 <write_head+0x4e>
  }
  bwrite(buf);
    80003fbc:	8526                	mv	a0,s1
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	0aa080e7          	jalr	170(ra) # 80003068 <bwrite>
  brelse(buf);
    80003fc6:	8526                	mv	a0,s1
    80003fc8:	fffff097          	auipc	ra,0xfffff
    80003fcc:	0de080e7          	jalr	222(ra) # 800030a6 <brelse>
}
    80003fd0:	60e2                	ld	ra,24(sp)
    80003fd2:	6442                	ld	s0,16(sp)
    80003fd4:	64a2                	ld	s1,8(sp)
    80003fd6:	6902                	ld	s2,0(sp)
    80003fd8:	6105                	addi	sp,sp,32
    80003fda:	8082                	ret

0000000080003fdc <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fdc:	0001e797          	auipc	a5,0x1e
    80003fe0:	9587a783          	lw	a5,-1704(a5) # 80021934 <log+0x2c>
    80003fe4:	0af05663          	blez	a5,80004090 <install_trans+0xb4>
{
    80003fe8:	7139                	addi	sp,sp,-64
    80003fea:	fc06                	sd	ra,56(sp)
    80003fec:	f822                	sd	s0,48(sp)
    80003fee:	f426                	sd	s1,40(sp)
    80003ff0:	f04a                	sd	s2,32(sp)
    80003ff2:	ec4e                	sd	s3,24(sp)
    80003ff4:	e852                	sd	s4,16(sp)
    80003ff6:	e456                	sd	s5,8(sp)
    80003ff8:	0080                	addi	s0,sp,64
    80003ffa:	0001ea97          	auipc	s5,0x1e
    80003ffe:	93ea8a93          	addi	s5,s5,-1730 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004002:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004004:	0001e997          	auipc	s3,0x1e
    80004008:	90498993          	addi	s3,s3,-1788 # 80021908 <log>
    8000400c:	0189a583          	lw	a1,24(s3)
    80004010:	014585bb          	addw	a1,a1,s4
    80004014:	2585                	addiw	a1,a1,1
    80004016:	0289a503          	lw	a0,40(s3)
    8000401a:	fffff097          	auipc	ra,0xfffff
    8000401e:	f5c080e7          	jalr	-164(ra) # 80002f76 <bread>
    80004022:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004024:	000aa583          	lw	a1,0(s5)
    80004028:	0289a503          	lw	a0,40(s3)
    8000402c:	fffff097          	auipc	ra,0xfffff
    80004030:	f4a080e7          	jalr	-182(ra) # 80002f76 <bread>
    80004034:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004036:	40000613          	li	a2,1024
    8000403a:	05890593          	addi	a1,s2,88
    8000403e:	05850513          	addi	a0,a0,88
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	d74080e7          	jalr	-652(ra) # 80000db6 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000404a:	8526                	mv	a0,s1
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	01c080e7          	jalr	28(ra) # 80003068 <bwrite>
    bunpin(dbuf);
    80004054:	8526                	mv	a0,s1
    80004056:	fffff097          	auipc	ra,0xfffff
    8000405a:	12a080e7          	jalr	298(ra) # 80003180 <bunpin>
    brelse(lbuf);
    8000405e:	854a                	mv	a0,s2
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	046080e7          	jalr	70(ra) # 800030a6 <brelse>
    brelse(dbuf);
    80004068:	8526                	mv	a0,s1
    8000406a:	fffff097          	auipc	ra,0xfffff
    8000406e:	03c080e7          	jalr	60(ra) # 800030a6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004072:	2a05                	addiw	s4,s4,1
    80004074:	0a91                	addi	s5,s5,4
    80004076:	02c9a783          	lw	a5,44(s3)
    8000407a:	f8fa49e3          	blt	s4,a5,8000400c <install_trans+0x30>
}
    8000407e:	70e2                	ld	ra,56(sp)
    80004080:	7442                	ld	s0,48(sp)
    80004082:	74a2                	ld	s1,40(sp)
    80004084:	7902                	ld	s2,32(sp)
    80004086:	69e2                	ld	s3,24(sp)
    80004088:	6a42                	ld	s4,16(sp)
    8000408a:	6aa2                	ld	s5,8(sp)
    8000408c:	6121                	addi	sp,sp,64
    8000408e:	8082                	ret
    80004090:	8082                	ret

0000000080004092 <initlog>:
{
    80004092:	7179                	addi	sp,sp,-48
    80004094:	f406                	sd	ra,40(sp)
    80004096:	f022                	sd	s0,32(sp)
    80004098:	ec26                	sd	s1,24(sp)
    8000409a:	e84a                	sd	s2,16(sp)
    8000409c:	e44e                	sd	s3,8(sp)
    8000409e:	1800                	addi	s0,sp,48
    800040a0:	892a                	mv	s2,a0
    800040a2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040a4:	0001e497          	auipc	s1,0x1e
    800040a8:	86448493          	addi	s1,s1,-1948 # 80021908 <log>
    800040ac:	00004597          	auipc	a1,0x4
    800040b0:	6ec58593          	addi	a1,a1,1772 # 80008798 <syscallnumber_to_name+0x1e8>
    800040b4:	8526                	mv	a0,s1
    800040b6:	ffffd097          	auipc	ra,0xffffd
    800040ba:	b14080e7          	jalr	-1260(ra) # 80000bca <initlock>
  log.start = sb->logstart;
    800040be:	0149a583          	lw	a1,20(s3)
    800040c2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040c4:	0109a783          	lw	a5,16(s3)
    800040c8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040ca:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040ce:	854a                	mv	a0,s2
    800040d0:	fffff097          	auipc	ra,0xfffff
    800040d4:	ea6080e7          	jalr	-346(ra) # 80002f76 <bread>
  log.lh.n = lh->n;
    800040d8:	4d3c                	lw	a5,88(a0)
    800040da:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040dc:	02f05563          	blez	a5,80004106 <initlog+0x74>
    800040e0:	05c50713          	addi	a4,a0,92
    800040e4:	0001e697          	auipc	a3,0x1e
    800040e8:	85468693          	addi	a3,a3,-1964 # 80021938 <log+0x30>
    800040ec:	37fd                	addiw	a5,a5,-1
    800040ee:	1782                	slli	a5,a5,0x20
    800040f0:	9381                	srli	a5,a5,0x20
    800040f2:	078a                	slli	a5,a5,0x2
    800040f4:	06050613          	addi	a2,a0,96
    800040f8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040fa:	4310                	lw	a2,0(a4)
    800040fc:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040fe:	0711                	addi	a4,a4,4
    80004100:	0691                	addi	a3,a3,4
    80004102:	fef71ce3          	bne	a4,a5,800040fa <initlog+0x68>
  brelse(buf);
    80004106:	fffff097          	auipc	ra,0xfffff
    8000410a:	fa0080e7          	jalr	-96(ra) # 800030a6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000410e:	00000097          	auipc	ra,0x0
    80004112:	ece080e7          	jalr	-306(ra) # 80003fdc <install_trans>
  log.lh.n = 0;
    80004116:	0001e797          	auipc	a5,0x1e
    8000411a:	8007af23          	sw	zero,-2018(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    8000411e:	00000097          	auipc	ra,0x0
    80004122:	e44080e7          	jalr	-444(ra) # 80003f62 <write_head>
}
    80004126:	70a2                	ld	ra,40(sp)
    80004128:	7402                	ld	s0,32(sp)
    8000412a:	64e2                	ld	s1,24(sp)
    8000412c:	6942                	ld	s2,16(sp)
    8000412e:	69a2                	ld	s3,8(sp)
    80004130:	6145                	addi	sp,sp,48
    80004132:	8082                	ret

0000000080004134 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004134:	1101                	addi	sp,sp,-32
    80004136:	ec06                	sd	ra,24(sp)
    80004138:	e822                	sd	s0,16(sp)
    8000413a:	e426                	sd	s1,8(sp)
    8000413c:	e04a                	sd	s2,0(sp)
    8000413e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004140:	0001d517          	auipc	a0,0x1d
    80004144:	7c850513          	addi	a0,a0,1992 # 80021908 <log>
    80004148:	ffffd097          	auipc	ra,0xffffd
    8000414c:	b12080e7          	jalr	-1262(ra) # 80000c5a <acquire>
  while(1){
    if(log.committing){
    80004150:	0001d497          	auipc	s1,0x1d
    80004154:	7b848493          	addi	s1,s1,1976 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004158:	4979                	li	s2,30
    8000415a:	a039                	j	80004168 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000415c:	85a6                	mv	a1,s1
    8000415e:	8526                	mv	a0,s1
    80004160:	ffffe097          	auipc	ra,0xffffe
    80004164:	0e0080e7          	jalr	224(ra) # 80002240 <sleep>
    if(log.committing){
    80004168:	50dc                	lw	a5,36(s1)
    8000416a:	fbed                	bnez	a5,8000415c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000416c:	509c                	lw	a5,32(s1)
    8000416e:	0017871b          	addiw	a4,a5,1
    80004172:	0007069b          	sext.w	a3,a4
    80004176:	0027179b          	slliw	a5,a4,0x2
    8000417a:	9fb9                	addw	a5,a5,a4
    8000417c:	0017979b          	slliw	a5,a5,0x1
    80004180:	54d8                	lw	a4,44(s1)
    80004182:	9fb9                	addw	a5,a5,a4
    80004184:	00f95963          	bge	s2,a5,80004196 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004188:	85a6                	mv	a1,s1
    8000418a:	8526                	mv	a0,s1
    8000418c:	ffffe097          	auipc	ra,0xffffe
    80004190:	0b4080e7          	jalr	180(ra) # 80002240 <sleep>
    80004194:	bfd1                	j	80004168 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004196:	0001d517          	auipc	a0,0x1d
    8000419a:	77250513          	addi	a0,a0,1906 # 80021908 <log>
    8000419e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041a0:	ffffd097          	auipc	ra,0xffffd
    800041a4:	b6e080e7          	jalr	-1170(ra) # 80000d0e <release>
      break;
    }
  }
}
    800041a8:	60e2                	ld	ra,24(sp)
    800041aa:	6442                	ld	s0,16(sp)
    800041ac:	64a2                	ld	s1,8(sp)
    800041ae:	6902                	ld	s2,0(sp)
    800041b0:	6105                	addi	sp,sp,32
    800041b2:	8082                	ret

00000000800041b4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041b4:	7139                	addi	sp,sp,-64
    800041b6:	fc06                	sd	ra,56(sp)
    800041b8:	f822                	sd	s0,48(sp)
    800041ba:	f426                	sd	s1,40(sp)
    800041bc:	f04a                	sd	s2,32(sp)
    800041be:	ec4e                	sd	s3,24(sp)
    800041c0:	e852                	sd	s4,16(sp)
    800041c2:	e456                	sd	s5,8(sp)
    800041c4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041c6:	0001d497          	auipc	s1,0x1d
    800041ca:	74248493          	addi	s1,s1,1858 # 80021908 <log>
    800041ce:	8526                	mv	a0,s1
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	a8a080e7          	jalr	-1398(ra) # 80000c5a <acquire>
  log.outstanding -= 1;
    800041d8:	509c                	lw	a5,32(s1)
    800041da:	37fd                	addiw	a5,a5,-1
    800041dc:	0007891b          	sext.w	s2,a5
    800041e0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041e2:	50dc                	lw	a5,36(s1)
    800041e4:	efb9                	bnez	a5,80004242 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041e6:	06091663          	bnez	s2,80004252 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041ea:	0001d497          	auipc	s1,0x1d
    800041ee:	71e48493          	addi	s1,s1,1822 # 80021908 <log>
    800041f2:	4785                	li	a5,1
    800041f4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041f6:	8526                	mv	a0,s1
    800041f8:	ffffd097          	auipc	ra,0xffffd
    800041fc:	b16080e7          	jalr	-1258(ra) # 80000d0e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004200:	54dc                	lw	a5,44(s1)
    80004202:	06f04763          	bgtz	a5,80004270 <end_op+0xbc>
    acquire(&log.lock);
    80004206:	0001d497          	auipc	s1,0x1d
    8000420a:	70248493          	addi	s1,s1,1794 # 80021908 <log>
    8000420e:	8526                	mv	a0,s1
    80004210:	ffffd097          	auipc	ra,0xffffd
    80004214:	a4a080e7          	jalr	-1462(ra) # 80000c5a <acquire>
    log.committing = 0;
    80004218:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000421c:	8526                	mv	a0,s1
    8000421e:	ffffe097          	auipc	ra,0xffffe
    80004222:	1a8080e7          	jalr	424(ra) # 800023c6 <wakeup>
    release(&log.lock);
    80004226:	8526                	mv	a0,s1
    80004228:	ffffd097          	auipc	ra,0xffffd
    8000422c:	ae6080e7          	jalr	-1306(ra) # 80000d0e <release>
}
    80004230:	70e2                	ld	ra,56(sp)
    80004232:	7442                	ld	s0,48(sp)
    80004234:	74a2                	ld	s1,40(sp)
    80004236:	7902                	ld	s2,32(sp)
    80004238:	69e2                	ld	s3,24(sp)
    8000423a:	6a42                	ld	s4,16(sp)
    8000423c:	6aa2                	ld	s5,8(sp)
    8000423e:	6121                	addi	sp,sp,64
    80004240:	8082                	ret
    panic("log.committing");
    80004242:	00004517          	auipc	a0,0x4
    80004246:	55e50513          	addi	a0,a0,1374 # 800087a0 <syscallnumber_to_name+0x1f0>
    8000424a:	ffffc097          	auipc	ra,0xffffc
    8000424e:	2fe080e7          	jalr	766(ra) # 80000548 <panic>
    wakeup(&log);
    80004252:	0001d497          	auipc	s1,0x1d
    80004256:	6b648493          	addi	s1,s1,1718 # 80021908 <log>
    8000425a:	8526                	mv	a0,s1
    8000425c:	ffffe097          	auipc	ra,0xffffe
    80004260:	16a080e7          	jalr	362(ra) # 800023c6 <wakeup>
  release(&log.lock);
    80004264:	8526                	mv	a0,s1
    80004266:	ffffd097          	auipc	ra,0xffffd
    8000426a:	aa8080e7          	jalr	-1368(ra) # 80000d0e <release>
  if(do_commit){
    8000426e:	b7c9                	j	80004230 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004270:	0001da97          	auipc	s5,0x1d
    80004274:	6c8a8a93          	addi	s5,s5,1736 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004278:	0001da17          	auipc	s4,0x1d
    8000427c:	690a0a13          	addi	s4,s4,1680 # 80021908 <log>
    80004280:	018a2583          	lw	a1,24(s4)
    80004284:	012585bb          	addw	a1,a1,s2
    80004288:	2585                	addiw	a1,a1,1
    8000428a:	028a2503          	lw	a0,40(s4)
    8000428e:	fffff097          	auipc	ra,0xfffff
    80004292:	ce8080e7          	jalr	-792(ra) # 80002f76 <bread>
    80004296:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004298:	000aa583          	lw	a1,0(s5)
    8000429c:	028a2503          	lw	a0,40(s4)
    800042a0:	fffff097          	auipc	ra,0xfffff
    800042a4:	cd6080e7          	jalr	-810(ra) # 80002f76 <bread>
    800042a8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042aa:	40000613          	li	a2,1024
    800042ae:	05850593          	addi	a1,a0,88
    800042b2:	05848513          	addi	a0,s1,88
    800042b6:	ffffd097          	auipc	ra,0xffffd
    800042ba:	b00080e7          	jalr	-1280(ra) # 80000db6 <memmove>
    bwrite(to);  // write the log
    800042be:	8526                	mv	a0,s1
    800042c0:	fffff097          	auipc	ra,0xfffff
    800042c4:	da8080e7          	jalr	-600(ra) # 80003068 <bwrite>
    brelse(from);
    800042c8:	854e                	mv	a0,s3
    800042ca:	fffff097          	auipc	ra,0xfffff
    800042ce:	ddc080e7          	jalr	-548(ra) # 800030a6 <brelse>
    brelse(to);
    800042d2:	8526                	mv	a0,s1
    800042d4:	fffff097          	auipc	ra,0xfffff
    800042d8:	dd2080e7          	jalr	-558(ra) # 800030a6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042dc:	2905                	addiw	s2,s2,1
    800042de:	0a91                	addi	s5,s5,4
    800042e0:	02ca2783          	lw	a5,44(s4)
    800042e4:	f8f94ee3          	blt	s2,a5,80004280 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042e8:	00000097          	auipc	ra,0x0
    800042ec:	c7a080e7          	jalr	-902(ra) # 80003f62 <write_head>
    install_trans(); // Now install writes to home locations
    800042f0:	00000097          	auipc	ra,0x0
    800042f4:	cec080e7          	jalr	-788(ra) # 80003fdc <install_trans>
    log.lh.n = 0;
    800042f8:	0001d797          	auipc	a5,0x1d
    800042fc:	6207ae23          	sw	zero,1596(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004300:	00000097          	auipc	ra,0x0
    80004304:	c62080e7          	jalr	-926(ra) # 80003f62 <write_head>
    80004308:	bdfd                	j	80004206 <end_op+0x52>

000000008000430a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000430a:	1101                	addi	sp,sp,-32
    8000430c:	ec06                	sd	ra,24(sp)
    8000430e:	e822                	sd	s0,16(sp)
    80004310:	e426                	sd	s1,8(sp)
    80004312:	e04a                	sd	s2,0(sp)
    80004314:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004316:	0001d717          	auipc	a4,0x1d
    8000431a:	61e72703          	lw	a4,1566(a4) # 80021934 <log+0x2c>
    8000431e:	47f5                	li	a5,29
    80004320:	08e7c063          	blt	a5,a4,800043a0 <log_write+0x96>
    80004324:	84aa                	mv	s1,a0
    80004326:	0001d797          	auipc	a5,0x1d
    8000432a:	5fe7a783          	lw	a5,1534(a5) # 80021924 <log+0x1c>
    8000432e:	37fd                	addiw	a5,a5,-1
    80004330:	06f75863          	bge	a4,a5,800043a0 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004334:	0001d797          	auipc	a5,0x1d
    80004338:	5f47a783          	lw	a5,1524(a5) # 80021928 <log+0x20>
    8000433c:	06f05a63          	blez	a5,800043b0 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004340:	0001d917          	auipc	s2,0x1d
    80004344:	5c890913          	addi	s2,s2,1480 # 80021908 <log>
    80004348:	854a                	mv	a0,s2
    8000434a:	ffffd097          	auipc	ra,0xffffd
    8000434e:	910080e7          	jalr	-1776(ra) # 80000c5a <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004352:	02c92603          	lw	a2,44(s2)
    80004356:	06c05563          	blez	a2,800043c0 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000435a:	44cc                	lw	a1,12(s1)
    8000435c:	0001d717          	auipc	a4,0x1d
    80004360:	5dc70713          	addi	a4,a4,1500 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004364:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004366:	4314                	lw	a3,0(a4)
    80004368:	04b68d63          	beq	a3,a1,800043c2 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000436c:	2785                	addiw	a5,a5,1
    8000436e:	0711                	addi	a4,a4,4
    80004370:	fec79be3          	bne	a5,a2,80004366 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004374:	0621                	addi	a2,a2,8
    80004376:	060a                	slli	a2,a2,0x2
    80004378:	0001d797          	auipc	a5,0x1d
    8000437c:	59078793          	addi	a5,a5,1424 # 80021908 <log>
    80004380:	963e                	add	a2,a2,a5
    80004382:	44dc                	lw	a5,12(s1)
    80004384:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004386:	8526                	mv	a0,s1
    80004388:	fffff097          	auipc	ra,0xfffff
    8000438c:	dbc080e7          	jalr	-580(ra) # 80003144 <bpin>
    log.lh.n++;
    80004390:	0001d717          	auipc	a4,0x1d
    80004394:	57870713          	addi	a4,a4,1400 # 80021908 <log>
    80004398:	575c                	lw	a5,44(a4)
    8000439a:	2785                	addiw	a5,a5,1
    8000439c:	d75c                	sw	a5,44(a4)
    8000439e:	a83d                	j	800043dc <log_write+0xd2>
    panic("too big a transaction");
    800043a0:	00004517          	auipc	a0,0x4
    800043a4:	41050513          	addi	a0,a0,1040 # 800087b0 <syscallnumber_to_name+0x200>
    800043a8:	ffffc097          	auipc	ra,0xffffc
    800043ac:	1a0080e7          	jalr	416(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800043b0:	00004517          	auipc	a0,0x4
    800043b4:	41850513          	addi	a0,a0,1048 # 800087c8 <syscallnumber_to_name+0x218>
    800043b8:	ffffc097          	auipc	ra,0xffffc
    800043bc:	190080e7          	jalr	400(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800043c0:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800043c2:	00878713          	addi	a4,a5,8
    800043c6:	00271693          	slli	a3,a4,0x2
    800043ca:	0001d717          	auipc	a4,0x1d
    800043ce:	53e70713          	addi	a4,a4,1342 # 80021908 <log>
    800043d2:	9736                	add	a4,a4,a3
    800043d4:	44d4                	lw	a3,12(s1)
    800043d6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043d8:	faf607e3          	beq	a2,a5,80004386 <log_write+0x7c>
  }
  release(&log.lock);
    800043dc:	0001d517          	auipc	a0,0x1d
    800043e0:	52c50513          	addi	a0,a0,1324 # 80021908 <log>
    800043e4:	ffffd097          	auipc	ra,0xffffd
    800043e8:	92a080e7          	jalr	-1750(ra) # 80000d0e <release>
}
    800043ec:	60e2                	ld	ra,24(sp)
    800043ee:	6442                	ld	s0,16(sp)
    800043f0:	64a2                	ld	s1,8(sp)
    800043f2:	6902                	ld	s2,0(sp)
    800043f4:	6105                	addi	sp,sp,32
    800043f6:	8082                	ret

00000000800043f8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043f8:	1101                	addi	sp,sp,-32
    800043fa:	ec06                	sd	ra,24(sp)
    800043fc:	e822                	sd	s0,16(sp)
    800043fe:	e426                	sd	s1,8(sp)
    80004400:	e04a                	sd	s2,0(sp)
    80004402:	1000                	addi	s0,sp,32
    80004404:	84aa                	mv	s1,a0
    80004406:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004408:	00004597          	auipc	a1,0x4
    8000440c:	3e058593          	addi	a1,a1,992 # 800087e8 <syscallnumber_to_name+0x238>
    80004410:	0521                	addi	a0,a0,8
    80004412:	ffffc097          	auipc	ra,0xffffc
    80004416:	7b8080e7          	jalr	1976(ra) # 80000bca <initlock>
  lk->name = name;
    8000441a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000441e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004422:	0204a423          	sw	zero,40(s1)
}
    80004426:	60e2                	ld	ra,24(sp)
    80004428:	6442                	ld	s0,16(sp)
    8000442a:	64a2                	ld	s1,8(sp)
    8000442c:	6902                	ld	s2,0(sp)
    8000442e:	6105                	addi	sp,sp,32
    80004430:	8082                	ret

0000000080004432 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004432:	1101                	addi	sp,sp,-32
    80004434:	ec06                	sd	ra,24(sp)
    80004436:	e822                	sd	s0,16(sp)
    80004438:	e426                	sd	s1,8(sp)
    8000443a:	e04a                	sd	s2,0(sp)
    8000443c:	1000                	addi	s0,sp,32
    8000443e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004440:	00850913          	addi	s2,a0,8
    80004444:	854a                	mv	a0,s2
    80004446:	ffffd097          	auipc	ra,0xffffd
    8000444a:	814080e7          	jalr	-2028(ra) # 80000c5a <acquire>
  while (lk->locked) {
    8000444e:	409c                	lw	a5,0(s1)
    80004450:	cb89                	beqz	a5,80004462 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004452:	85ca                	mv	a1,s2
    80004454:	8526                	mv	a0,s1
    80004456:	ffffe097          	auipc	ra,0xffffe
    8000445a:	dea080e7          	jalr	-534(ra) # 80002240 <sleep>
  while (lk->locked) {
    8000445e:	409c                	lw	a5,0(s1)
    80004460:	fbed                	bnez	a5,80004452 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004462:	4785                	li	a5,1
    80004464:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004466:	ffffd097          	auipc	ra,0xffffd
    8000446a:	5c2080e7          	jalr	1474(ra) # 80001a28 <myproc>
    8000446e:	5d1c                	lw	a5,56(a0)
    80004470:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004472:	854a                	mv	a0,s2
    80004474:	ffffd097          	auipc	ra,0xffffd
    80004478:	89a080e7          	jalr	-1894(ra) # 80000d0e <release>
}
    8000447c:	60e2                	ld	ra,24(sp)
    8000447e:	6442                	ld	s0,16(sp)
    80004480:	64a2                	ld	s1,8(sp)
    80004482:	6902                	ld	s2,0(sp)
    80004484:	6105                	addi	sp,sp,32
    80004486:	8082                	ret

0000000080004488 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004488:	1101                	addi	sp,sp,-32
    8000448a:	ec06                	sd	ra,24(sp)
    8000448c:	e822                	sd	s0,16(sp)
    8000448e:	e426                	sd	s1,8(sp)
    80004490:	e04a                	sd	s2,0(sp)
    80004492:	1000                	addi	s0,sp,32
    80004494:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004496:	00850913          	addi	s2,a0,8
    8000449a:	854a                	mv	a0,s2
    8000449c:	ffffc097          	auipc	ra,0xffffc
    800044a0:	7be080e7          	jalr	1982(ra) # 80000c5a <acquire>
  lk->locked = 0;
    800044a4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044a8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044ac:	8526                	mv	a0,s1
    800044ae:	ffffe097          	auipc	ra,0xffffe
    800044b2:	f18080e7          	jalr	-232(ra) # 800023c6 <wakeup>
  release(&lk->lk);
    800044b6:	854a                	mv	a0,s2
    800044b8:	ffffd097          	auipc	ra,0xffffd
    800044bc:	856080e7          	jalr	-1962(ra) # 80000d0e <release>
}
    800044c0:	60e2                	ld	ra,24(sp)
    800044c2:	6442                	ld	s0,16(sp)
    800044c4:	64a2                	ld	s1,8(sp)
    800044c6:	6902                	ld	s2,0(sp)
    800044c8:	6105                	addi	sp,sp,32
    800044ca:	8082                	ret

00000000800044cc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044cc:	7179                	addi	sp,sp,-48
    800044ce:	f406                	sd	ra,40(sp)
    800044d0:	f022                	sd	s0,32(sp)
    800044d2:	ec26                	sd	s1,24(sp)
    800044d4:	e84a                	sd	s2,16(sp)
    800044d6:	e44e                	sd	s3,8(sp)
    800044d8:	1800                	addi	s0,sp,48
    800044da:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044dc:	00850913          	addi	s2,a0,8
    800044e0:	854a                	mv	a0,s2
    800044e2:	ffffc097          	auipc	ra,0xffffc
    800044e6:	778080e7          	jalr	1912(ra) # 80000c5a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044ea:	409c                	lw	a5,0(s1)
    800044ec:	ef99                	bnez	a5,8000450a <holdingsleep+0x3e>
    800044ee:	4481                	li	s1,0
  release(&lk->lk);
    800044f0:	854a                	mv	a0,s2
    800044f2:	ffffd097          	auipc	ra,0xffffd
    800044f6:	81c080e7          	jalr	-2020(ra) # 80000d0e <release>
  return r;
}
    800044fa:	8526                	mv	a0,s1
    800044fc:	70a2                	ld	ra,40(sp)
    800044fe:	7402                	ld	s0,32(sp)
    80004500:	64e2                	ld	s1,24(sp)
    80004502:	6942                	ld	s2,16(sp)
    80004504:	69a2                	ld	s3,8(sp)
    80004506:	6145                	addi	sp,sp,48
    80004508:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000450a:	0284a983          	lw	s3,40(s1)
    8000450e:	ffffd097          	auipc	ra,0xffffd
    80004512:	51a080e7          	jalr	1306(ra) # 80001a28 <myproc>
    80004516:	5d04                	lw	s1,56(a0)
    80004518:	413484b3          	sub	s1,s1,s3
    8000451c:	0014b493          	seqz	s1,s1
    80004520:	bfc1                	j	800044f0 <holdingsleep+0x24>

0000000080004522 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004522:	1141                	addi	sp,sp,-16
    80004524:	e406                	sd	ra,8(sp)
    80004526:	e022                	sd	s0,0(sp)
    80004528:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000452a:	00004597          	auipc	a1,0x4
    8000452e:	2ce58593          	addi	a1,a1,718 # 800087f8 <syscallnumber_to_name+0x248>
    80004532:	0001d517          	auipc	a0,0x1d
    80004536:	51e50513          	addi	a0,a0,1310 # 80021a50 <ftable>
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	690080e7          	jalr	1680(ra) # 80000bca <initlock>
}
    80004542:	60a2                	ld	ra,8(sp)
    80004544:	6402                	ld	s0,0(sp)
    80004546:	0141                	addi	sp,sp,16
    80004548:	8082                	ret

000000008000454a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000454a:	1101                	addi	sp,sp,-32
    8000454c:	ec06                	sd	ra,24(sp)
    8000454e:	e822                	sd	s0,16(sp)
    80004550:	e426                	sd	s1,8(sp)
    80004552:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004554:	0001d517          	auipc	a0,0x1d
    80004558:	4fc50513          	addi	a0,a0,1276 # 80021a50 <ftable>
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	6fe080e7          	jalr	1790(ra) # 80000c5a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004564:	0001d497          	auipc	s1,0x1d
    80004568:	50448493          	addi	s1,s1,1284 # 80021a68 <ftable+0x18>
    8000456c:	0001e717          	auipc	a4,0x1e
    80004570:	49c70713          	addi	a4,a4,1180 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    80004574:	40dc                	lw	a5,4(s1)
    80004576:	cf99                	beqz	a5,80004594 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004578:	02848493          	addi	s1,s1,40
    8000457c:	fee49ce3          	bne	s1,a4,80004574 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004580:	0001d517          	auipc	a0,0x1d
    80004584:	4d050513          	addi	a0,a0,1232 # 80021a50 <ftable>
    80004588:	ffffc097          	auipc	ra,0xffffc
    8000458c:	786080e7          	jalr	1926(ra) # 80000d0e <release>
  return 0;
    80004590:	4481                	li	s1,0
    80004592:	a819                	j	800045a8 <filealloc+0x5e>
      f->ref = 1;
    80004594:	4785                	li	a5,1
    80004596:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004598:	0001d517          	auipc	a0,0x1d
    8000459c:	4b850513          	addi	a0,a0,1208 # 80021a50 <ftable>
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	76e080e7          	jalr	1902(ra) # 80000d0e <release>
}
    800045a8:	8526                	mv	a0,s1
    800045aa:	60e2                	ld	ra,24(sp)
    800045ac:	6442                	ld	s0,16(sp)
    800045ae:	64a2                	ld	s1,8(sp)
    800045b0:	6105                	addi	sp,sp,32
    800045b2:	8082                	ret

00000000800045b4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045b4:	1101                	addi	sp,sp,-32
    800045b6:	ec06                	sd	ra,24(sp)
    800045b8:	e822                	sd	s0,16(sp)
    800045ba:	e426                	sd	s1,8(sp)
    800045bc:	1000                	addi	s0,sp,32
    800045be:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045c0:	0001d517          	auipc	a0,0x1d
    800045c4:	49050513          	addi	a0,a0,1168 # 80021a50 <ftable>
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	692080e7          	jalr	1682(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    800045d0:	40dc                	lw	a5,4(s1)
    800045d2:	02f05263          	blez	a5,800045f6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045d6:	2785                	addiw	a5,a5,1
    800045d8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045da:	0001d517          	auipc	a0,0x1d
    800045de:	47650513          	addi	a0,a0,1142 # 80021a50 <ftable>
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	72c080e7          	jalr	1836(ra) # 80000d0e <release>
  return f;
}
    800045ea:	8526                	mv	a0,s1
    800045ec:	60e2                	ld	ra,24(sp)
    800045ee:	6442                	ld	s0,16(sp)
    800045f0:	64a2                	ld	s1,8(sp)
    800045f2:	6105                	addi	sp,sp,32
    800045f4:	8082                	ret
    panic("filedup");
    800045f6:	00004517          	auipc	a0,0x4
    800045fa:	20a50513          	addi	a0,a0,522 # 80008800 <syscallnumber_to_name+0x250>
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	f4a080e7          	jalr	-182(ra) # 80000548 <panic>

0000000080004606 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004606:	7139                	addi	sp,sp,-64
    80004608:	fc06                	sd	ra,56(sp)
    8000460a:	f822                	sd	s0,48(sp)
    8000460c:	f426                	sd	s1,40(sp)
    8000460e:	f04a                	sd	s2,32(sp)
    80004610:	ec4e                	sd	s3,24(sp)
    80004612:	e852                	sd	s4,16(sp)
    80004614:	e456                	sd	s5,8(sp)
    80004616:	0080                	addi	s0,sp,64
    80004618:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000461a:	0001d517          	auipc	a0,0x1d
    8000461e:	43650513          	addi	a0,a0,1078 # 80021a50 <ftable>
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	638080e7          	jalr	1592(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    8000462a:	40dc                	lw	a5,4(s1)
    8000462c:	06f05163          	blez	a5,8000468e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004630:	37fd                	addiw	a5,a5,-1
    80004632:	0007871b          	sext.w	a4,a5
    80004636:	c0dc                	sw	a5,4(s1)
    80004638:	06e04363          	bgtz	a4,8000469e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000463c:	0004a903          	lw	s2,0(s1)
    80004640:	0094ca83          	lbu	s5,9(s1)
    80004644:	0104ba03          	ld	s4,16(s1)
    80004648:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000464c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004650:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004654:	0001d517          	auipc	a0,0x1d
    80004658:	3fc50513          	addi	a0,a0,1020 # 80021a50 <ftable>
    8000465c:	ffffc097          	auipc	ra,0xffffc
    80004660:	6b2080e7          	jalr	1714(ra) # 80000d0e <release>

  if(ff.type == FD_PIPE){
    80004664:	4785                	li	a5,1
    80004666:	04f90d63          	beq	s2,a5,800046c0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000466a:	3979                	addiw	s2,s2,-2
    8000466c:	4785                	li	a5,1
    8000466e:	0527e063          	bltu	a5,s2,800046ae <fileclose+0xa8>
    begin_op();
    80004672:	00000097          	auipc	ra,0x0
    80004676:	ac2080e7          	jalr	-1342(ra) # 80004134 <begin_op>
    iput(ff.ip);
    8000467a:	854e                	mv	a0,s3
    8000467c:	fffff097          	auipc	ra,0xfffff
    80004680:	2b6080e7          	jalr	694(ra) # 80003932 <iput>
    end_op();
    80004684:	00000097          	auipc	ra,0x0
    80004688:	b30080e7          	jalr	-1232(ra) # 800041b4 <end_op>
    8000468c:	a00d                	j	800046ae <fileclose+0xa8>
    panic("fileclose");
    8000468e:	00004517          	auipc	a0,0x4
    80004692:	17a50513          	addi	a0,a0,378 # 80008808 <syscallnumber_to_name+0x258>
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	eb2080e7          	jalr	-334(ra) # 80000548 <panic>
    release(&ftable.lock);
    8000469e:	0001d517          	auipc	a0,0x1d
    800046a2:	3b250513          	addi	a0,a0,946 # 80021a50 <ftable>
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	668080e7          	jalr	1640(ra) # 80000d0e <release>
  }
}
    800046ae:	70e2                	ld	ra,56(sp)
    800046b0:	7442                	ld	s0,48(sp)
    800046b2:	74a2                	ld	s1,40(sp)
    800046b4:	7902                	ld	s2,32(sp)
    800046b6:	69e2                	ld	s3,24(sp)
    800046b8:	6a42                	ld	s4,16(sp)
    800046ba:	6aa2                	ld	s5,8(sp)
    800046bc:	6121                	addi	sp,sp,64
    800046be:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046c0:	85d6                	mv	a1,s5
    800046c2:	8552                	mv	a0,s4
    800046c4:	00000097          	auipc	ra,0x0
    800046c8:	372080e7          	jalr	882(ra) # 80004a36 <pipeclose>
    800046cc:	b7cd                	j	800046ae <fileclose+0xa8>

00000000800046ce <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046ce:	715d                	addi	sp,sp,-80
    800046d0:	e486                	sd	ra,72(sp)
    800046d2:	e0a2                	sd	s0,64(sp)
    800046d4:	fc26                	sd	s1,56(sp)
    800046d6:	f84a                	sd	s2,48(sp)
    800046d8:	f44e                	sd	s3,40(sp)
    800046da:	0880                	addi	s0,sp,80
    800046dc:	84aa                	mv	s1,a0
    800046de:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046e0:	ffffd097          	auipc	ra,0xffffd
    800046e4:	348080e7          	jalr	840(ra) # 80001a28 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046e8:	409c                	lw	a5,0(s1)
    800046ea:	37f9                	addiw	a5,a5,-2
    800046ec:	4705                	li	a4,1
    800046ee:	04f76763          	bltu	a4,a5,8000473c <filestat+0x6e>
    800046f2:	892a                	mv	s2,a0
    ilock(f->ip);
    800046f4:	6c88                	ld	a0,24(s1)
    800046f6:	fffff097          	auipc	ra,0xfffff
    800046fa:	082080e7          	jalr	130(ra) # 80003778 <ilock>
    stati(f->ip, &st);
    800046fe:	fb840593          	addi	a1,s0,-72
    80004702:	6c88                	ld	a0,24(s1)
    80004704:	fffff097          	auipc	ra,0xfffff
    80004708:	2fe080e7          	jalr	766(ra) # 80003a02 <stati>
    iunlock(f->ip);
    8000470c:	6c88                	ld	a0,24(s1)
    8000470e:	fffff097          	auipc	ra,0xfffff
    80004712:	12c080e7          	jalr	300(ra) # 8000383a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004716:	46e1                	li	a3,24
    80004718:	fb840613          	addi	a2,s0,-72
    8000471c:	85ce                	mv	a1,s3
    8000471e:	05093503          	ld	a0,80(s2)
    80004722:	ffffd097          	auipc	ra,0xffffd
    80004726:	ffa080e7          	jalr	-6(ra) # 8000171c <copyout>
    8000472a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000472e:	60a6                	ld	ra,72(sp)
    80004730:	6406                	ld	s0,64(sp)
    80004732:	74e2                	ld	s1,56(sp)
    80004734:	7942                	ld	s2,48(sp)
    80004736:	79a2                	ld	s3,40(sp)
    80004738:	6161                	addi	sp,sp,80
    8000473a:	8082                	ret
  return -1;
    8000473c:	557d                	li	a0,-1
    8000473e:	bfc5                	j	8000472e <filestat+0x60>

0000000080004740 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004740:	7179                	addi	sp,sp,-48
    80004742:	f406                	sd	ra,40(sp)
    80004744:	f022                	sd	s0,32(sp)
    80004746:	ec26                	sd	s1,24(sp)
    80004748:	e84a                	sd	s2,16(sp)
    8000474a:	e44e                	sd	s3,8(sp)
    8000474c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000474e:	00854783          	lbu	a5,8(a0)
    80004752:	c3d5                	beqz	a5,800047f6 <fileread+0xb6>
    80004754:	84aa                	mv	s1,a0
    80004756:	89ae                	mv	s3,a1
    80004758:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000475a:	411c                	lw	a5,0(a0)
    8000475c:	4705                	li	a4,1
    8000475e:	04e78963          	beq	a5,a4,800047b0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004762:	470d                	li	a4,3
    80004764:	04e78d63          	beq	a5,a4,800047be <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004768:	4709                	li	a4,2
    8000476a:	06e79e63          	bne	a5,a4,800047e6 <fileread+0xa6>
    ilock(f->ip);
    8000476e:	6d08                	ld	a0,24(a0)
    80004770:	fffff097          	auipc	ra,0xfffff
    80004774:	008080e7          	jalr	8(ra) # 80003778 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004778:	874a                	mv	a4,s2
    8000477a:	5094                	lw	a3,32(s1)
    8000477c:	864e                	mv	a2,s3
    8000477e:	4585                	li	a1,1
    80004780:	6c88                	ld	a0,24(s1)
    80004782:	fffff097          	auipc	ra,0xfffff
    80004786:	2aa080e7          	jalr	682(ra) # 80003a2c <readi>
    8000478a:	892a                	mv	s2,a0
    8000478c:	00a05563          	blez	a0,80004796 <fileread+0x56>
      f->off += r;
    80004790:	509c                	lw	a5,32(s1)
    80004792:	9fa9                	addw	a5,a5,a0
    80004794:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004796:	6c88                	ld	a0,24(s1)
    80004798:	fffff097          	auipc	ra,0xfffff
    8000479c:	0a2080e7          	jalr	162(ra) # 8000383a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047a0:	854a                	mv	a0,s2
    800047a2:	70a2                	ld	ra,40(sp)
    800047a4:	7402                	ld	s0,32(sp)
    800047a6:	64e2                	ld	s1,24(sp)
    800047a8:	6942                	ld	s2,16(sp)
    800047aa:	69a2                	ld	s3,8(sp)
    800047ac:	6145                	addi	sp,sp,48
    800047ae:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047b0:	6908                	ld	a0,16(a0)
    800047b2:	00000097          	auipc	ra,0x0
    800047b6:	418080e7          	jalr	1048(ra) # 80004bca <piperead>
    800047ba:	892a                	mv	s2,a0
    800047bc:	b7d5                	j	800047a0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047be:	02451783          	lh	a5,36(a0)
    800047c2:	03079693          	slli	a3,a5,0x30
    800047c6:	92c1                	srli	a3,a3,0x30
    800047c8:	4725                	li	a4,9
    800047ca:	02d76863          	bltu	a4,a3,800047fa <fileread+0xba>
    800047ce:	0792                	slli	a5,a5,0x4
    800047d0:	0001d717          	auipc	a4,0x1d
    800047d4:	1e070713          	addi	a4,a4,480 # 800219b0 <devsw>
    800047d8:	97ba                	add	a5,a5,a4
    800047da:	639c                	ld	a5,0(a5)
    800047dc:	c38d                	beqz	a5,800047fe <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047de:	4505                	li	a0,1
    800047e0:	9782                	jalr	a5
    800047e2:	892a                	mv	s2,a0
    800047e4:	bf75                	j	800047a0 <fileread+0x60>
    panic("fileread");
    800047e6:	00004517          	auipc	a0,0x4
    800047ea:	03250513          	addi	a0,a0,50 # 80008818 <syscallnumber_to_name+0x268>
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	d5a080e7          	jalr	-678(ra) # 80000548 <panic>
    return -1;
    800047f6:	597d                	li	s2,-1
    800047f8:	b765                	j	800047a0 <fileread+0x60>
      return -1;
    800047fa:	597d                	li	s2,-1
    800047fc:	b755                	j	800047a0 <fileread+0x60>
    800047fe:	597d                	li	s2,-1
    80004800:	b745                	j	800047a0 <fileread+0x60>

0000000080004802 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004802:	00954783          	lbu	a5,9(a0)
    80004806:	14078563          	beqz	a5,80004950 <filewrite+0x14e>
{
    8000480a:	715d                	addi	sp,sp,-80
    8000480c:	e486                	sd	ra,72(sp)
    8000480e:	e0a2                	sd	s0,64(sp)
    80004810:	fc26                	sd	s1,56(sp)
    80004812:	f84a                	sd	s2,48(sp)
    80004814:	f44e                	sd	s3,40(sp)
    80004816:	f052                	sd	s4,32(sp)
    80004818:	ec56                	sd	s5,24(sp)
    8000481a:	e85a                	sd	s6,16(sp)
    8000481c:	e45e                	sd	s7,8(sp)
    8000481e:	e062                	sd	s8,0(sp)
    80004820:	0880                	addi	s0,sp,80
    80004822:	892a                	mv	s2,a0
    80004824:	8aae                	mv	s5,a1
    80004826:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004828:	411c                	lw	a5,0(a0)
    8000482a:	4705                	li	a4,1
    8000482c:	02e78263          	beq	a5,a4,80004850 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004830:	470d                	li	a4,3
    80004832:	02e78563          	beq	a5,a4,8000485c <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004836:	4709                	li	a4,2
    80004838:	10e79463          	bne	a5,a4,80004940 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000483c:	0ec05e63          	blez	a2,80004938 <filewrite+0x136>
    int i = 0;
    80004840:	4981                	li	s3,0
    80004842:	6b05                	lui	s6,0x1
    80004844:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004848:	6b85                	lui	s7,0x1
    8000484a:	c00b8b9b          	addiw	s7,s7,-1024
    8000484e:	a851                	j	800048e2 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004850:	6908                	ld	a0,16(a0)
    80004852:	00000097          	auipc	ra,0x0
    80004856:	254080e7          	jalr	596(ra) # 80004aa6 <pipewrite>
    8000485a:	a85d                	j	80004910 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000485c:	02451783          	lh	a5,36(a0)
    80004860:	03079693          	slli	a3,a5,0x30
    80004864:	92c1                	srli	a3,a3,0x30
    80004866:	4725                	li	a4,9
    80004868:	0ed76663          	bltu	a4,a3,80004954 <filewrite+0x152>
    8000486c:	0792                	slli	a5,a5,0x4
    8000486e:	0001d717          	auipc	a4,0x1d
    80004872:	14270713          	addi	a4,a4,322 # 800219b0 <devsw>
    80004876:	97ba                	add	a5,a5,a4
    80004878:	679c                	ld	a5,8(a5)
    8000487a:	cff9                	beqz	a5,80004958 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    8000487c:	4505                	li	a0,1
    8000487e:	9782                	jalr	a5
    80004880:	a841                	j	80004910 <filewrite+0x10e>
    80004882:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004886:	00000097          	auipc	ra,0x0
    8000488a:	8ae080e7          	jalr	-1874(ra) # 80004134 <begin_op>
      ilock(f->ip);
    8000488e:	01893503          	ld	a0,24(s2)
    80004892:	fffff097          	auipc	ra,0xfffff
    80004896:	ee6080e7          	jalr	-282(ra) # 80003778 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000489a:	8762                	mv	a4,s8
    8000489c:	02092683          	lw	a3,32(s2)
    800048a0:	01598633          	add	a2,s3,s5
    800048a4:	4585                	li	a1,1
    800048a6:	01893503          	ld	a0,24(s2)
    800048aa:	fffff097          	auipc	ra,0xfffff
    800048ae:	278080e7          	jalr	632(ra) # 80003b22 <writei>
    800048b2:	84aa                	mv	s1,a0
    800048b4:	02a05f63          	blez	a0,800048f2 <filewrite+0xf0>
        f->off += r;
    800048b8:	02092783          	lw	a5,32(s2)
    800048bc:	9fa9                	addw	a5,a5,a0
    800048be:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048c2:	01893503          	ld	a0,24(s2)
    800048c6:	fffff097          	auipc	ra,0xfffff
    800048ca:	f74080e7          	jalr	-140(ra) # 8000383a <iunlock>
      end_op();
    800048ce:	00000097          	auipc	ra,0x0
    800048d2:	8e6080e7          	jalr	-1818(ra) # 800041b4 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800048d6:	049c1963          	bne	s8,s1,80004928 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800048da:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048de:	0349d663          	bge	s3,s4,8000490a <filewrite+0x108>
      int n1 = n - i;
    800048e2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048e6:	84be                	mv	s1,a5
    800048e8:	2781                	sext.w	a5,a5
    800048ea:	f8fb5ce3          	bge	s6,a5,80004882 <filewrite+0x80>
    800048ee:	84de                	mv	s1,s7
    800048f0:	bf49                	j	80004882 <filewrite+0x80>
      iunlock(f->ip);
    800048f2:	01893503          	ld	a0,24(s2)
    800048f6:	fffff097          	auipc	ra,0xfffff
    800048fa:	f44080e7          	jalr	-188(ra) # 8000383a <iunlock>
      end_op();
    800048fe:	00000097          	auipc	ra,0x0
    80004902:	8b6080e7          	jalr	-1866(ra) # 800041b4 <end_op>
      if(r < 0)
    80004906:	fc04d8e3          	bgez	s1,800048d6 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    8000490a:	8552                	mv	a0,s4
    8000490c:	033a1863          	bne	s4,s3,8000493c <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004910:	60a6                	ld	ra,72(sp)
    80004912:	6406                	ld	s0,64(sp)
    80004914:	74e2                	ld	s1,56(sp)
    80004916:	7942                	ld	s2,48(sp)
    80004918:	79a2                	ld	s3,40(sp)
    8000491a:	7a02                	ld	s4,32(sp)
    8000491c:	6ae2                	ld	s5,24(sp)
    8000491e:	6b42                	ld	s6,16(sp)
    80004920:	6ba2                	ld	s7,8(sp)
    80004922:	6c02                	ld	s8,0(sp)
    80004924:	6161                	addi	sp,sp,80
    80004926:	8082                	ret
        panic("short filewrite");
    80004928:	00004517          	auipc	a0,0x4
    8000492c:	f0050513          	addi	a0,a0,-256 # 80008828 <syscallnumber_to_name+0x278>
    80004930:	ffffc097          	auipc	ra,0xffffc
    80004934:	c18080e7          	jalr	-1000(ra) # 80000548 <panic>
    int i = 0;
    80004938:	4981                	li	s3,0
    8000493a:	bfc1                	j	8000490a <filewrite+0x108>
    ret = (i == n ? n : -1);
    8000493c:	557d                	li	a0,-1
    8000493e:	bfc9                	j	80004910 <filewrite+0x10e>
    panic("filewrite");
    80004940:	00004517          	auipc	a0,0x4
    80004944:	ef850513          	addi	a0,a0,-264 # 80008838 <syscallnumber_to_name+0x288>
    80004948:	ffffc097          	auipc	ra,0xffffc
    8000494c:	c00080e7          	jalr	-1024(ra) # 80000548 <panic>
    return -1;
    80004950:	557d                	li	a0,-1
}
    80004952:	8082                	ret
      return -1;
    80004954:	557d                	li	a0,-1
    80004956:	bf6d                	j	80004910 <filewrite+0x10e>
    80004958:	557d                	li	a0,-1
    8000495a:	bf5d                	j	80004910 <filewrite+0x10e>

000000008000495c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000495c:	7179                	addi	sp,sp,-48
    8000495e:	f406                	sd	ra,40(sp)
    80004960:	f022                	sd	s0,32(sp)
    80004962:	ec26                	sd	s1,24(sp)
    80004964:	e84a                	sd	s2,16(sp)
    80004966:	e44e                	sd	s3,8(sp)
    80004968:	e052                	sd	s4,0(sp)
    8000496a:	1800                	addi	s0,sp,48
    8000496c:	84aa                	mv	s1,a0
    8000496e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004970:	0005b023          	sd	zero,0(a1)
    80004974:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004978:	00000097          	auipc	ra,0x0
    8000497c:	bd2080e7          	jalr	-1070(ra) # 8000454a <filealloc>
    80004980:	e088                	sd	a0,0(s1)
    80004982:	c551                	beqz	a0,80004a0e <pipealloc+0xb2>
    80004984:	00000097          	auipc	ra,0x0
    80004988:	bc6080e7          	jalr	-1082(ra) # 8000454a <filealloc>
    8000498c:	00aa3023          	sd	a0,0(s4)
    80004990:	c92d                	beqz	a0,80004a02 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	18e080e7          	jalr	398(ra) # 80000b20 <kalloc>
    8000499a:	892a                	mv	s2,a0
    8000499c:	c125                	beqz	a0,800049fc <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000499e:	4985                	li	s3,1
    800049a0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049a4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049a8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049ac:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049b0:	00004597          	auipc	a1,0x4
    800049b4:	a9058593          	addi	a1,a1,-1392 # 80008440 <states.1710+0x198>
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	212080e7          	jalr	530(ra) # 80000bca <initlock>
  (*f0)->type = FD_PIPE;
    800049c0:	609c                	ld	a5,0(s1)
    800049c2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049c6:	609c                	ld	a5,0(s1)
    800049c8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049cc:	609c                	ld	a5,0(s1)
    800049ce:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049d2:	609c                	ld	a5,0(s1)
    800049d4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049d8:	000a3783          	ld	a5,0(s4)
    800049dc:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049e0:	000a3783          	ld	a5,0(s4)
    800049e4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049e8:	000a3783          	ld	a5,0(s4)
    800049ec:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049f0:	000a3783          	ld	a5,0(s4)
    800049f4:	0127b823          	sd	s2,16(a5)
  return 0;
    800049f8:	4501                	li	a0,0
    800049fa:	a025                	j	80004a22 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049fc:	6088                	ld	a0,0(s1)
    800049fe:	e501                	bnez	a0,80004a06 <pipealloc+0xaa>
    80004a00:	a039                	j	80004a0e <pipealloc+0xb2>
    80004a02:	6088                	ld	a0,0(s1)
    80004a04:	c51d                	beqz	a0,80004a32 <pipealloc+0xd6>
    fileclose(*f0);
    80004a06:	00000097          	auipc	ra,0x0
    80004a0a:	c00080e7          	jalr	-1024(ra) # 80004606 <fileclose>
  if(*f1)
    80004a0e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a12:	557d                	li	a0,-1
  if(*f1)
    80004a14:	c799                	beqz	a5,80004a22 <pipealloc+0xc6>
    fileclose(*f1);
    80004a16:	853e                	mv	a0,a5
    80004a18:	00000097          	auipc	ra,0x0
    80004a1c:	bee080e7          	jalr	-1042(ra) # 80004606 <fileclose>
  return -1;
    80004a20:	557d                	li	a0,-1
}
    80004a22:	70a2                	ld	ra,40(sp)
    80004a24:	7402                	ld	s0,32(sp)
    80004a26:	64e2                	ld	s1,24(sp)
    80004a28:	6942                	ld	s2,16(sp)
    80004a2a:	69a2                	ld	s3,8(sp)
    80004a2c:	6a02                	ld	s4,0(sp)
    80004a2e:	6145                	addi	sp,sp,48
    80004a30:	8082                	ret
  return -1;
    80004a32:	557d                	li	a0,-1
    80004a34:	b7fd                	j	80004a22 <pipealloc+0xc6>

0000000080004a36 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a36:	1101                	addi	sp,sp,-32
    80004a38:	ec06                	sd	ra,24(sp)
    80004a3a:	e822                	sd	s0,16(sp)
    80004a3c:	e426                	sd	s1,8(sp)
    80004a3e:	e04a                	sd	s2,0(sp)
    80004a40:	1000                	addi	s0,sp,32
    80004a42:	84aa                	mv	s1,a0
    80004a44:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	214080e7          	jalr	532(ra) # 80000c5a <acquire>
  if(writable){
    80004a4e:	02090d63          	beqz	s2,80004a88 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a52:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a56:	21848513          	addi	a0,s1,536
    80004a5a:	ffffe097          	auipc	ra,0xffffe
    80004a5e:	96c080e7          	jalr	-1684(ra) # 800023c6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a62:	2204b783          	ld	a5,544(s1)
    80004a66:	eb95                	bnez	a5,80004a9a <pipeclose+0x64>
    release(&pi->lock);
    80004a68:	8526                	mv	a0,s1
    80004a6a:	ffffc097          	auipc	ra,0xffffc
    80004a6e:	2a4080e7          	jalr	676(ra) # 80000d0e <release>
    kfree((char*)pi);
    80004a72:	8526                	mv	a0,s1
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	fb0080e7          	jalr	-80(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004a7c:	60e2                	ld	ra,24(sp)
    80004a7e:	6442                	ld	s0,16(sp)
    80004a80:	64a2                	ld	s1,8(sp)
    80004a82:	6902                	ld	s2,0(sp)
    80004a84:	6105                	addi	sp,sp,32
    80004a86:	8082                	ret
    pi->readopen = 0;
    80004a88:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a8c:	21c48513          	addi	a0,s1,540
    80004a90:	ffffe097          	auipc	ra,0xffffe
    80004a94:	936080e7          	jalr	-1738(ra) # 800023c6 <wakeup>
    80004a98:	b7e9                	j	80004a62 <pipeclose+0x2c>
    release(&pi->lock);
    80004a9a:	8526                	mv	a0,s1
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	272080e7          	jalr	626(ra) # 80000d0e <release>
}
    80004aa4:	bfe1                	j	80004a7c <pipeclose+0x46>

0000000080004aa6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004aa6:	7119                	addi	sp,sp,-128
    80004aa8:	fc86                	sd	ra,120(sp)
    80004aaa:	f8a2                	sd	s0,112(sp)
    80004aac:	f4a6                	sd	s1,104(sp)
    80004aae:	f0ca                	sd	s2,96(sp)
    80004ab0:	ecce                	sd	s3,88(sp)
    80004ab2:	e8d2                	sd	s4,80(sp)
    80004ab4:	e4d6                	sd	s5,72(sp)
    80004ab6:	e0da                	sd	s6,64(sp)
    80004ab8:	fc5e                	sd	s7,56(sp)
    80004aba:	f862                	sd	s8,48(sp)
    80004abc:	f466                	sd	s9,40(sp)
    80004abe:	f06a                	sd	s10,32(sp)
    80004ac0:	ec6e                	sd	s11,24(sp)
    80004ac2:	0100                	addi	s0,sp,128
    80004ac4:	84aa                	mv	s1,a0
    80004ac6:	8cae                	mv	s9,a1
    80004ac8:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004aca:	ffffd097          	auipc	ra,0xffffd
    80004ace:	f5e080e7          	jalr	-162(ra) # 80001a28 <myproc>
    80004ad2:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004ad4:	8526                	mv	a0,s1
    80004ad6:	ffffc097          	auipc	ra,0xffffc
    80004ada:	184080e7          	jalr	388(ra) # 80000c5a <acquire>
  for(i = 0; i < n; i++){
    80004ade:	0d605963          	blez	s6,80004bb0 <pipewrite+0x10a>
    80004ae2:	89a6                	mv	s3,s1
    80004ae4:	3b7d                	addiw	s6,s6,-1
    80004ae6:	1b02                	slli	s6,s6,0x20
    80004ae8:	020b5b13          	srli	s6,s6,0x20
    80004aec:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004aee:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004af2:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004af6:	5dfd                	li	s11,-1
    80004af8:	000b8d1b          	sext.w	s10,s7
    80004afc:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004afe:	2184a783          	lw	a5,536(s1)
    80004b02:	21c4a703          	lw	a4,540(s1)
    80004b06:	2007879b          	addiw	a5,a5,512
    80004b0a:	02f71b63          	bne	a4,a5,80004b40 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004b0e:	2204a783          	lw	a5,544(s1)
    80004b12:	cbad                	beqz	a5,80004b84 <pipewrite+0xde>
    80004b14:	03092783          	lw	a5,48(s2)
    80004b18:	e7b5                	bnez	a5,80004b84 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004b1a:	8556                	mv	a0,s5
    80004b1c:	ffffe097          	auipc	ra,0xffffe
    80004b20:	8aa080e7          	jalr	-1878(ra) # 800023c6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b24:	85ce                	mv	a1,s3
    80004b26:	8552                	mv	a0,s4
    80004b28:	ffffd097          	auipc	ra,0xffffd
    80004b2c:	718080e7          	jalr	1816(ra) # 80002240 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b30:	2184a783          	lw	a5,536(s1)
    80004b34:	21c4a703          	lw	a4,540(s1)
    80004b38:	2007879b          	addiw	a5,a5,512
    80004b3c:	fcf709e3          	beq	a4,a5,80004b0e <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b40:	4685                	li	a3,1
    80004b42:	019b8633          	add	a2,s7,s9
    80004b46:	f8f40593          	addi	a1,s0,-113
    80004b4a:	05093503          	ld	a0,80(s2)
    80004b4e:	ffffd097          	auipc	ra,0xffffd
    80004b52:	c5a080e7          	jalr	-934(ra) # 800017a8 <copyin>
    80004b56:	05b50e63          	beq	a0,s11,80004bb2 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b5a:	21c4a783          	lw	a5,540(s1)
    80004b5e:	0017871b          	addiw	a4,a5,1
    80004b62:	20e4ae23          	sw	a4,540(s1)
    80004b66:	1ff7f793          	andi	a5,a5,511
    80004b6a:	97a6                	add	a5,a5,s1
    80004b6c:	f8f44703          	lbu	a4,-113(s0)
    80004b70:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b74:	001d0c1b          	addiw	s8,s10,1
    80004b78:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004b7c:	036b8b63          	beq	s7,s6,80004bb2 <pipewrite+0x10c>
    80004b80:	8bbe                	mv	s7,a5
    80004b82:	bf9d                	j	80004af8 <pipewrite+0x52>
        release(&pi->lock);
    80004b84:	8526                	mv	a0,s1
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	188080e7          	jalr	392(ra) # 80000d0e <release>
        return -1;
    80004b8e:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b90:	8562                	mv	a0,s8
    80004b92:	70e6                	ld	ra,120(sp)
    80004b94:	7446                	ld	s0,112(sp)
    80004b96:	74a6                	ld	s1,104(sp)
    80004b98:	7906                	ld	s2,96(sp)
    80004b9a:	69e6                	ld	s3,88(sp)
    80004b9c:	6a46                	ld	s4,80(sp)
    80004b9e:	6aa6                	ld	s5,72(sp)
    80004ba0:	6b06                	ld	s6,64(sp)
    80004ba2:	7be2                	ld	s7,56(sp)
    80004ba4:	7c42                	ld	s8,48(sp)
    80004ba6:	7ca2                	ld	s9,40(sp)
    80004ba8:	7d02                	ld	s10,32(sp)
    80004baa:	6de2                	ld	s11,24(sp)
    80004bac:	6109                	addi	sp,sp,128
    80004bae:	8082                	ret
  for(i = 0; i < n; i++){
    80004bb0:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004bb2:	21848513          	addi	a0,s1,536
    80004bb6:	ffffe097          	auipc	ra,0xffffe
    80004bba:	810080e7          	jalr	-2032(ra) # 800023c6 <wakeup>
  release(&pi->lock);
    80004bbe:	8526                	mv	a0,s1
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	14e080e7          	jalr	334(ra) # 80000d0e <release>
  return i;
    80004bc8:	b7e1                	j	80004b90 <pipewrite+0xea>

0000000080004bca <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bca:	715d                	addi	sp,sp,-80
    80004bcc:	e486                	sd	ra,72(sp)
    80004bce:	e0a2                	sd	s0,64(sp)
    80004bd0:	fc26                	sd	s1,56(sp)
    80004bd2:	f84a                	sd	s2,48(sp)
    80004bd4:	f44e                	sd	s3,40(sp)
    80004bd6:	f052                	sd	s4,32(sp)
    80004bd8:	ec56                	sd	s5,24(sp)
    80004bda:	e85a                	sd	s6,16(sp)
    80004bdc:	0880                	addi	s0,sp,80
    80004bde:	84aa                	mv	s1,a0
    80004be0:	892e                	mv	s2,a1
    80004be2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004be4:	ffffd097          	auipc	ra,0xffffd
    80004be8:	e44080e7          	jalr	-444(ra) # 80001a28 <myproc>
    80004bec:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bee:	8b26                	mv	s6,s1
    80004bf0:	8526                	mv	a0,s1
    80004bf2:	ffffc097          	auipc	ra,0xffffc
    80004bf6:	068080e7          	jalr	104(ra) # 80000c5a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bfa:	2184a703          	lw	a4,536(s1)
    80004bfe:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c02:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c06:	02f71463          	bne	a4,a5,80004c2e <piperead+0x64>
    80004c0a:	2244a783          	lw	a5,548(s1)
    80004c0e:	c385                	beqz	a5,80004c2e <piperead+0x64>
    if(pr->killed){
    80004c10:	030a2783          	lw	a5,48(s4)
    80004c14:	ebc1                	bnez	a5,80004ca4 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c16:	85da                	mv	a1,s6
    80004c18:	854e                	mv	a0,s3
    80004c1a:	ffffd097          	auipc	ra,0xffffd
    80004c1e:	626080e7          	jalr	1574(ra) # 80002240 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c22:	2184a703          	lw	a4,536(s1)
    80004c26:	21c4a783          	lw	a5,540(s1)
    80004c2a:	fef700e3          	beq	a4,a5,80004c0a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c2e:	09505263          	blez	s5,80004cb2 <piperead+0xe8>
    80004c32:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c34:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c36:	2184a783          	lw	a5,536(s1)
    80004c3a:	21c4a703          	lw	a4,540(s1)
    80004c3e:	02f70d63          	beq	a4,a5,80004c78 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c42:	0017871b          	addiw	a4,a5,1
    80004c46:	20e4ac23          	sw	a4,536(s1)
    80004c4a:	1ff7f793          	andi	a5,a5,511
    80004c4e:	97a6                	add	a5,a5,s1
    80004c50:	0187c783          	lbu	a5,24(a5)
    80004c54:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c58:	4685                	li	a3,1
    80004c5a:	fbf40613          	addi	a2,s0,-65
    80004c5e:	85ca                	mv	a1,s2
    80004c60:	050a3503          	ld	a0,80(s4)
    80004c64:	ffffd097          	auipc	ra,0xffffd
    80004c68:	ab8080e7          	jalr	-1352(ra) # 8000171c <copyout>
    80004c6c:	01650663          	beq	a0,s6,80004c78 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c70:	2985                	addiw	s3,s3,1
    80004c72:	0905                	addi	s2,s2,1
    80004c74:	fd3a91e3          	bne	s5,s3,80004c36 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c78:	21c48513          	addi	a0,s1,540
    80004c7c:	ffffd097          	auipc	ra,0xffffd
    80004c80:	74a080e7          	jalr	1866(ra) # 800023c6 <wakeup>
  release(&pi->lock);
    80004c84:	8526                	mv	a0,s1
    80004c86:	ffffc097          	auipc	ra,0xffffc
    80004c8a:	088080e7          	jalr	136(ra) # 80000d0e <release>
  return i;
}
    80004c8e:	854e                	mv	a0,s3
    80004c90:	60a6                	ld	ra,72(sp)
    80004c92:	6406                	ld	s0,64(sp)
    80004c94:	74e2                	ld	s1,56(sp)
    80004c96:	7942                	ld	s2,48(sp)
    80004c98:	79a2                	ld	s3,40(sp)
    80004c9a:	7a02                	ld	s4,32(sp)
    80004c9c:	6ae2                	ld	s5,24(sp)
    80004c9e:	6b42                	ld	s6,16(sp)
    80004ca0:	6161                	addi	sp,sp,80
    80004ca2:	8082                	ret
      release(&pi->lock);
    80004ca4:	8526                	mv	a0,s1
    80004ca6:	ffffc097          	auipc	ra,0xffffc
    80004caa:	068080e7          	jalr	104(ra) # 80000d0e <release>
      return -1;
    80004cae:	59fd                	li	s3,-1
    80004cb0:	bff9                	j	80004c8e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb2:	4981                	li	s3,0
    80004cb4:	b7d1                	j	80004c78 <piperead+0xae>

0000000080004cb6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cb6:	df010113          	addi	sp,sp,-528
    80004cba:	20113423          	sd	ra,520(sp)
    80004cbe:	20813023          	sd	s0,512(sp)
    80004cc2:	ffa6                	sd	s1,504(sp)
    80004cc4:	fbca                	sd	s2,496(sp)
    80004cc6:	f7ce                	sd	s3,488(sp)
    80004cc8:	f3d2                	sd	s4,480(sp)
    80004cca:	efd6                	sd	s5,472(sp)
    80004ccc:	ebda                	sd	s6,464(sp)
    80004cce:	e7de                	sd	s7,456(sp)
    80004cd0:	e3e2                	sd	s8,448(sp)
    80004cd2:	ff66                	sd	s9,440(sp)
    80004cd4:	fb6a                	sd	s10,432(sp)
    80004cd6:	f76e                	sd	s11,424(sp)
    80004cd8:	0c00                	addi	s0,sp,528
    80004cda:	84aa                	mv	s1,a0
    80004cdc:	dea43c23          	sd	a0,-520(s0)
    80004ce0:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ce4:	ffffd097          	auipc	ra,0xffffd
    80004ce8:	d44080e7          	jalr	-700(ra) # 80001a28 <myproc>
    80004cec:	892a                	mv	s2,a0
  //printf("exec nei 1: %d\n", p->tracemask);

  begin_op();
    80004cee:	fffff097          	auipc	ra,0xfffff
    80004cf2:	446080e7          	jalr	1094(ra) # 80004134 <begin_op>

  if((ip = namei(path)) == 0){
    80004cf6:	8526                	mv	a0,s1
    80004cf8:	fffff097          	auipc	ra,0xfffff
    80004cfc:	230080e7          	jalr	560(ra) # 80003f28 <namei>
    80004d00:	c92d                	beqz	a0,80004d72 <exec+0xbc>
    80004d02:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d04:	fffff097          	auipc	ra,0xfffff
    80004d08:	a74080e7          	jalr	-1420(ra) # 80003778 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d0c:	04000713          	li	a4,64
    80004d10:	4681                	li	a3,0
    80004d12:	e4840613          	addi	a2,s0,-440
    80004d16:	4581                	li	a1,0
    80004d18:	8526                	mv	a0,s1
    80004d1a:	fffff097          	auipc	ra,0xfffff
    80004d1e:	d12080e7          	jalr	-750(ra) # 80003a2c <readi>
    80004d22:	04000793          	li	a5,64
    80004d26:	00f51a63          	bne	a0,a5,80004d3a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d2a:	e4842703          	lw	a4,-440(s0)
    80004d2e:	464c47b7          	lui	a5,0x464c4
    80004d32:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d36:	04f70463          	beq	a4,a5,80004d7e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d3a:	8526                	mv	a0,s1
    80004d3c:	fffff097          	auipc	ra,0xfffff
    80004d40:	c9e080e7          	jalr	-866(ra) # 800039da <iunlockput>
    end_op();
    80004d44:	fffff097          	auipc	ra,0xfffff
    80004d48:	470080e7          	jalr	1136(ra) # 800041b4 <end_op>
  }
  return -1;
    80004d4c:	557d                	li	a0,-1
}
    80004d4e:	20813083          	ld	ra,520(sp)
    80004d52:	20013403          	ld	s0,512(sp)
    80004d56:	74fe                	ld	s1,504(sp)
    80004d58:	795e                	ld	s2,496(sp)
    80004d5a:	79be                	ld	s3,488(sp)
    80004d5c:	7a1e                	ld	s4,480(sp)
    80004d5e:	6afe                	ld	s5,472(sp)
    80004d60:	6b5e                	ld	s6,464(sp)
    80004d62:	6bbe                	ld	s7,456(sp)
    80004d64:	6c1e                	ld	s8,448(sp)
    80004d66:	7cfa                	ld	s9,440(sp)
    80004d68:	7d5a                	ld	s10,432(sp)
    80004d6a:	7dba                	ld	s11,424(sp)
    80004d6c:	21010113          	addi	sp,sp,528
    80004d70:	8082                	ret
    end_op();
    80004d72:	fffff097          	auipc	ra,0xfffff
    80004d76:	442080e7          	jalr	1090(ra) # 800041b4 <end_op>
    return -1;
    80004d7a:	557d                	li	a0,-1
    80004d7c:	bfc9                	j	80004d4e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d7e:	854a                	mv	a0,s2
    80004d80:	ffffd097          	auipc	ra,0xffffd
    80004d84:	d6c080e7          	jalr	-660(ra) # 80001aec <proc_pagetable>
    80004d88:	8baa                	mv	s7,a0
    80004d8a:	d945                	beqz	a0,80004d3a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d8c:	e6842983          	lw	s3,-408(s0)
    80004d90:	e8045783          	lhu	a5,-384(s0)
    80004d94:	c7ad                	beqz	a5,80004dfe <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d96:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d98:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d9a:	6c85                	lui	s9,0x1
    80004d9c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004da0:	def43823          	sd	a5,-528(s0)
    80004da4:	a42d                	j	80004fce <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004da6:	00004517          	auipc	a0,0x4
    80004daa:	aa250513          	addi	a0,a0,-1374 # 80008848 <syscallnumber_to_name+0x298>
    80004dae:	ffffb097          	auipc	ra,0xffffb
    80004db2:	79a080e7          	jalr	1946(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004db6:	8756                	mv	a4,s5
    80004db8:	012d86bb          	addw	a3,s11,s2
    80004dbc:	4581                	li	a1,0
    80004dbe:	8526                	mv	a0,s1
    80004dc0:	fffff097          	auipc	ra,0xfffff
    80004dc4:	c6c080e7          	jalr	-916(ra) # 80003a2c <readi>
    80004dc8:	2501                	sext.w	a0,a0
    80004dca:	1aaa9963          	bne	s5,a0,80004f7c <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004dce:	6785                	lui	a5,0x1
    80004dd0:	0127893b          	addw	s2,a5,s2
    80004dd4:	77fd                	lui	a5,0xfffff
    80004dd6:	01478a3b          	addw	s4,a5,s4
    80004dda:	1f897163          	bgeu	s2,s8,80004fbc <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004dde:	02091593          	slli	a1,s2,0x20
    80004de2:	9181                	srli	a1,a1,0x20
    80004de4:	95ea                	add	a1,a1,s10
    80004de6:	855e                	mv	a0,s7
    80004de8:	ffffc097          	auipc	ra,0xffffc
    80004dec:	300080e7          	jalr	768(ra) # 800010e8 <walkaddr>
    80004df0:	862a                	mv	a2,a0
    if(pa == 0)
    80004df2:	d955                	beqz	a0,80004da6 <exec+0xf0>
      n = PGSIZE;
    80004df4:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004df6:	fd9a70e3          	bgeu	s4,s9,80004db6 <exec+0x100>
      n = sz - i;
    80004dfa:	8ad2                	mv	s5,s4
    80004dfc:	bf6d                	j	80004db6 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dfe:	4901                	li	s2,0
  iunlockput(ip);
    80004e00:	8526                	mv	a0,s1
    80004e02:	fffff097          	auipc	ra,0xfffff
    80004e06:	bd8080e7          	jalr	-1064(ra) # 800039da <iunlockput>
  end_op();
    80004e0a:	fffff097          	auipc	ra,0xfffff
    80004e0e:	3aa080e7          	jalr	938(ra) # 800041b4 <end_op>
  p = myproc();
    80004e12:	ffffd097          	auipc	ra,0xffffd
    80004e16:	c16080e7          	jalr	-1002(ra) # 80001a28 <myproc>
    80004e1a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e1c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e20:	6785                	lui	a5,0x1
    80004e22:	17fd                	addi	a5,a5,-1
    80004e24:	993e                	add	s2,s2,a5
    80004e26:	757d                	lui	a0,0xfffff
    80004e28:	00a977b3          	and	a5,s2,a0
    80004e2c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e30:	6609                	lui	a2,0x2
    80004e32:	963e                	add	a2,a2,a5
    80004e34:	85be                	mv	a1,a5
    80004e36:	855e                	mv	a0,s7
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	694080e7          	jalr	1684(ra) # 800014cc <uvmalloc>
    80004e40:	8b2a                	mv	s6,a0
  ip = 0;
    80004e42:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e44:	12050c63          	beqz	a0,80004f7c <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e48:	75f9                	lui	a1,0xffffe
    80004e4a:	95aa                	add	a1,a1,a0
    80004e4c:	855e                	mv	a0,s7
    80004e4e:	ffffd097          	auipc	ra,0xffffd
    80004e52:	89c080e7          	jalr	-1892(ra) # 800016ea <uvmclear>
  stackbase = sp - PGSIZE;
    80004e56:	7c7d                	lui	s8,0xfffff
    80004e58:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e5a:	e0043783          	ld	a5,-512(s0)
    80004e5e:	6388                	ld	a0,0(a5)
    80004e60:	c535                	beqz	a0,80004ecc <exec+0x216>
    80004e62:	e8840993          	addi	s3,s0,-376
    80004e66:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e6a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e6c:	ffffc097          	auipc	ra,0xffffc
    80004e70:	072080e7          	jalr	114(ra) # 80000ede <strlen>
    80004e74:	2505                	addiw	a0,a0,1
    80004e76:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e7a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e7e:	13896363          	bltu	s2,s8,80004fa4 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e82:	e0043d83          	ld	s11,-512(s0)
    80004e86:	000dba03          	ld	s4,0(s11)
    80004e8a:	8552                	mv	a0,s4
    80004e8c:	ffffc097          	auipc	ra,0xffffc
    80004e90:	052080e7          	jalr	82(ra) # 80000ede <strlen>
    80004e94:	0015069b          	addiw	a3,a0,1
    80004e98:	8652                	mv	a2,s4
    80004e9a:	85ca                	mv	a1,s2
    80004e9c:	855e                	mv	a0,s7
    80004e9e:	ffffd097          	auipc	ra,0xffffd
    80004ea2:	87e080e7          	jalr	-1922(ra) # 8000171c <copyout>
    80004ea6:	10054363          	bltz	a0,80004fac <exec+0x2f6>
    ustack[argc] = sp;
    80004eaa:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004eae:	0485                	addi	s1,s1,1
    80004eb0:	008d8793          	addi	a5,s11,8
    80004eb4:	e0f43023          	sd	a5,-512(s0)
    80004eb8:	008db503          	ld	a0,8(s11)
    80004ebc:	c911                	beqz	a0,80004ed0 <exec+0x21a>
    if(argc >= MAXARG)
    80004ebe:	09a1                	addi	s3,s3,8
    80004ec0:	fb3c96e3          	bne	s9,s3,80004e6c <exec+0x1b6>
  sz = sz1;
    80004ec4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ec8:	4481                	li	s1,0
    80004eca:	a84d                	j	80004f7c <exec+0x2c6>
  sp = sz;
    80004ecc:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ece:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ed0:	00349793          	slli	a5,s1,0x3
    80004ed4:	f9040713          	addi	a4,s0,-112
    80004ed8:	97ba                	add	a5,a5,a4
    80004eda:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004ede:	00148693          	addi	a3,s1,1
    80004ee2:	068e                	slli	a3,a3,0x3
    80004ee4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ee8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004eec:	01897663          	bgeu	s2,s8,80004ef8 <exec+0x242>
  sz = sz1;
    80004ef0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ef4:	4481                	li	s1,0
    80004ef6:	a059                	j	80004f7c <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ef8:	e8840613          	addi	a2,s0,-376
    80004efc:	85ca                	mv	a1,s2
    80004efe:	855e                	mv	a0,s7
    80004f00:	ffffd097          	auipc	ra,0xffffd
    80004f04:	81c080e7          	jalr	-2020(ra) # 8000171c <copyout>
    80004f08:	0a054663          	bltz	a0,80004fb4 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f0c:	058ab783          	ld	a5,88(s5)
    80004f10:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f14:	df843783          	ld	a5,-520(s0)
    80004f18:	0007c703          	lbu	a4,0(a5)
    80004f1c:	cf11                	beqz	a4,80004f38 <exec+0x282>
    80004f1e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f20:	02f00693          	li	a3,47
    80004f24:	a029                	j	80004f2e <exec+0x278>
  for(last=s=path; *s; s++)
    80004f26:	0785                	addi	a5,a5,1
    80004f28:	fff7c703          	lbu	a4,-1(a5)
    80004f2c:	c711                	beqz	a4,80004f38 <exec+0x282>
    if(*s == '/')
    80004f2e:	fed71ce3          	bne	a4,a3,80004f26 <exec+0x270>
      last = s+1;
    80004f32:	def43c23          	sd	a5,-520(s0)
    80004f36:	bfc5                	j	80004f26 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f38:	4641                	li	a2,16
    80004f3a:	df843583          	ld	a1,-520(s0)
    80004f3e:	158a8513          	addi	a0,s5,344
    80004f42:	ffffc097          	auipc	ra,0xffffc
    80004f46:	f6a080e7          	jalr	-150(ra) # 80000eac <safestrcpy>
  oldpagetable = p->pagetable;
    80004f4a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f4e:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f52:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f56:	058ab783          	ld	a5,88(s5)
    80004f5a:	e6043703          	ld	a4,-416(s0)
    80004f5e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f60:	058ab783          	ld	a5,88(s5)
    80004f64:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f68:	85ea                	mv	a1,s10
    80004f6a:	ffffd097          	auipc	ra,0xffffd
    80004f6e:	c1e080e7          	jalr	-994(ra) # 80001b88 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f72:	0004851b          	sext.w	a0,s1
    80004f76:	bbe1                	j	80004d4e <exec+0x98>
    80004f78:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f7c:	e0843583          	ld	a1,-504(s0)
    80004f80:	855e                	mv	a0,s7
    80004f82:	ffffd097          	auipc	ra,0xffffd
    80004f86:	c06080e7          	jalr	-1018(ra) # 80001b88 <proc_freepagetable>
  if(ip){
    80004f8a:	da0498e3          	bnez	s1,80004d3a <exec+0x84>
  return -1;
    80004f8e:	557d                	li	a0,-1
    80004f90:	bb7d                	j	80004d4e <exec+0x98>
    80004f92:	e1243423          	sd	s2,-504(s0)
    80004f96:	b7dd                	j	80004f7c <exec+0x2c6>
    80004f98:	e1243423          	sd	s2,-504(s0)
    80004f9c:	b7c5                	j	80004f7c <exec+0x2c6>
    80004f9e:	e1243423          	sd	s2,-504(s0)
    80004fa2:	bfe9                	j	80004f7c <exec+0x2c6>
  sz = sz1;
    80004fa4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fa8:	4481                	li	s1,0
    80004faa:	bfc9                	j	80004f7c <exec+0x2c6>
  sz = sz1;
    80004fac:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fb0:	4481                	li	s1,0
    80004fb2:	b7e9                	j	80004f7c <exec+0x2c6>
  sz = sz1;
    80004fb4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fb8:	4481                	li	s1,0
    80004fba:	b7c9                	j	80004f7c <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fbc:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fc0:	2b05                	addiw	s6,s6,1
    80004fc2:	0389899b          	addiw	s3,s3,56
    80004fc6:	e8045783          	lhu	a5,-384(s0)
    80004fca:	e2fb5be3          	bge	s6,a5,80004e00 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fce:	2981                	sext.w	s3,s3
    80004fd0:	03800713          	li	a4,56
    80004fd4:	86ce                	mv	a3,s3
    80004fd6:	e1040613          	addi	a2,s0,-496
    80004fda:	4581                	li	a1,0
    80004fdc:	8526                	mv	a0,s1
    80004fde:	fffff097          	auipc	ra,0xfffff
    80004fe2:	a4e080e7          	jalr	-1458(ra) # 80003a2c <readi>
    80004fe6:	03800793          	li	a5,56
    80004fea:	f8f517e3          	bne	a0,a5,80004f78 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fee:	e1042783          	lw	a5,-496(s0)
    80004ff2:	4705                	li	a4,1
    80004ff4:	fce796e3          	bne	a5,a4,80004fc0 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004ff8:	e3843603          	ld	a2,-456(s0)
    80004ffc:	e3043783          	ld	a5,-464(s0)
    80005000:	f8f669e3          	bltu	a2,a5,80004f92 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005004:	e2043783          	ld	a5,-480(s0)
    80005008:	963e                	add	a2,a2,a5
    8000500a:	f8f667e3          	bltu	a2,a5,80004f98 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000500e:	85ca                	mv	a1,s2
    80005010:	855e                	mv	a0,s7
    80005012:	ffffc097          	auipc	ra,0xffffc
    80005016:	4ba080e7          	jalr	1210(ra) # 800014cc <uvmalloc>
    8000501a:	e0a43423          	sd	a0,-504(s0)
    8000501e:	d141                	beqz	a0,80004f9e <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005020:	e2043d03          	ld	s10,-480(s0)
    80005024:	df043783          	ld	a5,-528(s0)
    80005028:	00fd77b3          	and	a5,s10,a5
    8000502c:	fba1                	bnez	a5,80004f7c <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000502e:	e1842d83          	lw	s11,-488(s0)
    80005032:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005036:	f80c03e3          	beqz	s8,80004fbc <exec+0x306>
    8000503a:	8a62                	mv	s4,s8
    8000503c:	4901                	li	s2,0
    8000503e:	b345                	j	80004dde <exec+0x128>

0000000080005040 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005040:	7179                	addi	sp,sp,-48
    80005042:	f406                	sd	ra,40(sp)
    80005044:	f022                	sd	s0,32(sp)
    80005046:	ec26                	sd	s1,24(sp)
    80005048:	e84a                	sd	s2,16(sp)
    8000504a:	1800                	addi	s0,sp,48
    8000504c:	892e                	mv	s2,a1
    8000504e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005050:	fdc40593          	addi	a1,s0,-36
    80005054:	ffffe097          	auipc	ra,0xffffe
    80005058:	b2a080e7          	jalr	-1238(ra) # 80002b7e <argint>
    8000505c:	04054063          	bltz	a0,8000509c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005060:	fdc42703          	lw	a4,-36(s0)
    80005064:	47bd                	li	a5,15
    80005066:	02e7ed63          	bltu	a5,a4,800050a0 <argfd+0x60>
    8000506a:	ffffd097          	auipc	ra,0xffffd
    8000506e:	9be080e7          	jalr	-1602(ra) # 80001a28 <myproc>
    80005072:	fdc42703          	lw	a4,-36(s0)
    80005076:	01a70793          	addi	a5,a4,26
    8000507a:	078e                	slli	a5,a5,0x3
    8000507c:	953e                	add	a0,a0,a5
    8000507e:	611c                	ld	a5,0(a0)
    80005080:	c395                	beqz	a5,800050a4 <argfd+0x64>
    return -1;
  if(pfd)
    80005082:	00090463          	beqz	s2,8000508a <argfd+0x4a>
    *pfd = fd;
    80005086:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000508a:	4501                	li	a0,0
  if(pf)
    8000508c:	c091                	beqz	s1,80005090 <argfd+0x50>
    *pf = f;
    8000508e:	e09c                	sd	a5,0(s1)
}
    80005090:	70a2                	ld	ra,40(sp)
    80005092:	7402                	ld	s0,32(sp)
    80005094:	64e2                	ld	s1,24(sp)
    80005096:	6942                	ld	s2,16(sp)
    80005098:	6145                	addi	sp,sp,48
    8000509a:	8082                	ret
    return -1;
    8000509c:	557d                	li	a0,-1
    8000509e:	bfcd                	j	80005090 <argfd+0x50>
    return -1;
    800050a0:	557d                	li	a0,-1
    800050a2:	b7fd                	j	80005090 <argfd+0x50>
    800050a4:	557d                	li	a0,-1
    800050a6:	b7ed                	j	80005090 <argfd+0x50>

00000000800050a8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050a8:	1101                	addi	sp,sp,-32
    800050aa:	ec06                	sd	ra,24(sp)
    800050ac:	e822                	sd	s0,16(sp)
    800050ae:	e426                	sd	s1,8(sp)
    800050b0:	1000                	addi	s0,sp,32
    800050b2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050b4:	ffffd097          	auipc	ra,0xffffd
    800050b8:	974080e7          	jalr	-1676(ra) # 80001a28 <myproc>
    800050bc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050be:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800050c2:	4501                	li	a0,0
    800050c4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050c6:	6398                	ld	a4,0(a5)
    800050c8:	cb19                	beqz	a4,800050de <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050ca:	2505                	addiw	a0,a0,1
    800050cc:	07a1                	addi	a5,a5,8
    800050ce:	fed51ce3          	bne	a0,a3,800050c6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050d2:	557d                	li	a0,-1
}
    800050d4:	60e2                	ld	ra,24(sp)
    800050d6:	6442                	ld	s0,16(sp)
    800050d8:	64a2                	ld	s1,8(sp)
    800050da:	6105                	addi	sp,sp,32
    800050dc:	8082                	ret
      p->ofile[fd] = f;
    800050de:	01a50793          	addi	a5,a0,26
    800050e2:	078e                	slli	a5,a5,0x3
    800050e4:	963e                	add	a2,a2,a5
    800050e6:	e204                	sd	s1,0(a2)
      return fd;
    800050e8:	b7f5                	j	800050d4 <fdalloc+0x2c>

00000000800050ea <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050ea:	715d                	addi	sp,sp,-80
    800050ec:	e486                	sd	ra,72(sp)
    800050ee:	e0a2                	sd	s0,64(sp)
    800050f0:	fc26                	sd	s1,56(sp)
    800050f2:	f84a                	sd	s2,48(sp)
    800050f4:	f44e                	sd	s3,40(sp)
    800050f6:	f052                	sd	s4,32(sp)
    800050f8:	ec56                	sd	s5,24(sp)
    800050fa:	0880                	addi	s0,sp,80
    800050fc:	89ae                	mv	s3,a1
    800050fe:	8ab2                	mv	s5,a2
    80005100:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005102:	fb040593          	addi	a1,s0,-80
    80005106:	fffff097          	auipc	ra,0xfffff
    8000510a:	e40080e7          	jalr	-448(ra) # 80003f46 <nameiparent>
    8000510e:	892a                	mv	s2,a0
    80005110:	12050f63          	beqz	a0,8000524e <create+0x164>
    return 0;

  ilock(dp);
    80005114:	ffffe097          	auipc	ra,0xffffe
    80005118:	664080e7          	jalr	1636(ra) # 80003778 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000511c:	4601                	li	a2,0
    8000511e:	fb040593          	addi	a1,s0,-80
    80005122:	854a                	mv	a0,s2
    80005124:	fffff097          	auipc	ra,0xfffff
    80005128:	b32080e7          	jalr	-1230(ra) # 80003c56 <dirlookup>
    8000512c:	84aa                	mv	s1,a0
    8000512e:	c921                	beqz	a0,8000517e <create+0x94>
    iunlockput(dp);
    80005130:	854a                	mv	a0,s2
    80005132:	fffff097          	auipc	ra,0xfffff
    80005136:	8a8080e7          	jalr	-1880(ra) # 800039da <iunlockput>
    ilock(ip);
    8000513a:	8526                	mv	a0,s1
    8000513c:	ffffe097          	auipc	ra,0xffffe
    80005140:	63c080e7          	jalr	1596(ra) # 80003778 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005144:	2981                	sext.w	s3,s3
    80005146:	4789                	li	a5,2
    80005148:	02f99463          	bne	s3,a5,80005170 <create+0x86>
    8000514c:	0444d783          	lhu	a5,68(s1)
    80005150:	37f9                	addiw	a5,a5,-2
    80005152:	17c2                	slli	a5,a5,0x30
    80005154:	93c1                	srli	a5,a5,0x30
    80005156:	4705                	li	a4,1
    80005158:	00f76c63          	bltu	a4,a5,80005170 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000515c:	8526                	mv	a0,s1
    8000515e:	60a6                	ld	ra,72(sp)
    80005160:	6406                	ld	s0,64(sp)
    80005162:	74e2                	ld	s1,56(sp)
    80005164:	7942                	ld	s2,48(sp)
    80005166:	79a2                	ld	s3,40(sp)
    80005168:	7a02                	ld	s4,32(sp)
    8000516a:	6ae2                	ld	s5,24(sp)
    8000516c:	6161                	addi	sp,sp,80
    8000516e:	8082                	ret
    iunlockput(ip);
    80005170:	8526                	mv	a0,s1
    80005172:	fffff097          	auipc	ra,0xfffff
    80005176:	868080e7          	jalr	-1944(ra) # 800039da <iunlockput>
    return 0;
    8000517a:	4481                	li	s1,0
    8000517c:	b7c5                	j	8000515c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000517e:	85ce                	mv	a1,s3
    80005180:	00092503          	lw	a0,0(s2)
    80005184:	ffffe097          	auipc	ra,0xffffe
    80005188:	45c080e7          	jalr	1116(ra) # 800035e0 <ialloc>
    8000518c:	84aa                	mv	s1,a0
    8000518e:	c529                	beqz	a0,800051d8 <create+0xee>
  ilock(ip);
    80005190:	ffffe097          	auipc	ra,0xffffe
    80005194:	5e8080e7          	jalr	1512(ra) # 80003778 <ilock>
  ip->major = major;
    80005198:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000519c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051a0:	4785                	li	a5,1
    800051a2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051a6:	8526                	mv	a0,s1
    800051a8:	ffffe097          	auipc	ra,0xffffe
    800051ac:	506080e7          	jalr	1286(ra) # 800036ae <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051b0:	2981                	sext.w	s3,s3
    800051b2:	4785                	li	a5,1
    800051b4:	02f98a63          	beq	s3,a5,800051e8 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051b8:	40d0                	lw	a2,4(s1)
    800051ba:	fb040593          	addi	a1,s0,-80
    800051be:	854a                	mv	a0,s2
    800051c0:	fffff097          	auipc	ra,0xfffff
    800051c4:	ca6080e7          	jalr	-858(ra) # 80003e66 <dirlink>
    800051c8:	06054b63          	bltz	a0,8000523e <create+0x154>
  iunlockput(dp);
    800051cc:	854a                	mv	a0,s2
    800051ce:	fffff097          	auipc	ra,0xfffff
    800051d2:	80c080e7          	jalr	-2036(ra) # 800039da <iunlockput>
  return ip;
    800051d6:	b759                	j	8000515c <create+0x72>
    panic("create: ialloc");
    800051d8:	00003517          	auipc	a0,0x3
    800051dc:	69050513          	addi	a0,a0,1680 # 80008868 <syscallnumber_to_name+0x2b8>
    800051e0:	ffffb097          	auipc	ra,0xffffb
    800051e4:	368080e7          	jalr	872(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800051e8:	04a95783          	lhu	a5,74(s2)
    800051ec:	2785                	addiw	a5,a5,1
    800051ee:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051f2:	854a                	mv	a0,s2
    800051f4:	ffffe097          	auipc	ra,0xffffe
    800051f8:	4ba080e7          	jalr	1210(ra) # 800036ae <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051fc:	40d0                	lw	a2,4(s1)
    800051fe:	00003597          	auipc	a1,0x3
    80005202:	67a58593          	addi	a1,a1,1658 # 80008878 <syscallnumber_to_name+0x2c8>
    80005206:	8526                	mv	a0,s1
    80005208:	fffff097          	auipc	ra,0xfffff
    8000520c:	c5e080e7          	jalr	-930(ra) # 80003e66 <dirlink>
    80005210:	00054f63          	bltz	a0,8000522e <create+0x144>
    80005214:	00492603          	lw	a2,4(s2)
    80005218:	00003597          	auipc	a1,0x3
    8000521c:	66858593          	addi	a1,a1,1640 # 80008880 <syscallnumber_to_name+0x2d0>
    80005220:	8526                	mv	a0,s1
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	c44080e7          	jalr	-956(ra) # 80003e66 <dirlink>
    8000522a:	f80557e3          	bgez	a0,800051b8 <create+0xce>
      panic("create dots");
    8000522e:	00003517          	auipc	a0,0x3
    80005232:	65a50513          	addi	a0,a0,1626 # 80008888 <syscallnumber_to_name+0x2d8>
    80005236:	ffffb097          	auipc	ra,0xffffb
    8000523a:	312080e7          	jalr	786(ra) # 80000548 <panic>
    panic("create: dirlink");
    8000523e:	00003517          	auipc	a0,0x3
    80005242:	65a50513          	addi	a0,a0,1626 # 80008898 <syscallnumber_to_name+0x2e8>
    80005246:	ffffb097          	auipc	ra,0xffffb
    8000524a:	302080e7          	jalr	770(ra) # 80000548 <panic>
    return 0;
    8000524e:	84aa                	mv	s1,a0
    80005250:	b731                	j	8000515c <create+0x72>

0000000080005252 <sys_dup>:
{
    80005252:	7179                	addi	sp,sp,-48
    80005254:	f406                	sd	ra,40(sp)
    80005256:	f022                	sd	s0,32(sp)
    80005258:	ec26                	sd	s1,24(sp)
    8000525a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000525c:	fd840613          	addi	a2,s0,-40
    80005260:	4581                	li	a1,0
    80005262:	4501                	li	a0,0
    80005264:	00000097          	auipc	ra,0x0
    80005268:	ddc080e7          	jalr	-548(ra) # 80005040 <argfd>
    return -1;
    8000526c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000526e:	02054363          	bltz	a0,80005294 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005272:	fd843503          	ld	a0,-40(s0)
    80005276:	00000097          	auipc	ra,0x0
    8000527a:	e32080e7          	jalr	-462(ra) # 800050a8 <fdalloc>
    8000527e:	84aa                	mv	s1,a0
    return -1;
    80005280:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005282:	00054963          	bltz	a0,80005294 <sys_dup+0x42>
  filedup(f);
    80005286:	fd843503          	ld	a0,-40(s0)
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	32a080e7          	jalr	810(ra) # 800045b4 <filedup>
  return fd;
    80005292:	87a6                	mv	a5,s1
}
    80005294:	853e                	mv	a0,a5
    80005296:	70a2                	ld	ra,40(sp)
    80005298:	7402                	ld	s0,32(sp)
    8000529a:	64e2                	ld	s1,24(sp)
    8000529c:	6145                	addi	sp,sp,48
    8000529e:	8082                	ret

00000000800052a0 <sys_read>:
{
    800052a0:	7179                	addi	sp,sp,-48
    800052a2:	f406                	sd	ra,40(sp)
    800052a4:	f022                	sd	s0,32(sp)
    800052a6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a8:	fe840613          	addi	a2,s0,-24
    800052ac:	4581                	li	a1,0
    800052ae:	4501                	li	a0,0
    800052b0:	00000097          	auipc	ra,0x0
    800052b4:	d90080e7          	jalr	-624(ra) # 80005040 <argfd>
    return -1;
    800052b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ba:	04054163          	bltz	a0,800052fc <sys_read+0x5c>
    800052be:	fe440593          	addi	a1,s0,-28
    800052c2:	4509                	li	a0,2
    800052c4:	ffffe097          	auipc	ra,0xffffe
    800052c8:	8ba080e7          	jalr	-1862(ra) # 80002b7e <argint>
    return -1;
    800052cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ce:	02054763          	bltz	a0,800052fc <sys_read+0x5c>
    800052d2:	fd840593          	addi	a1,s0,-40
    800052d6:	4505                	li	a0,1
    800052d8:	ffffe097          	auipc	ra,0xffffe
    800052dc:	8c8080e7          	jalr	-1848(ra) # 80002ba0 <argaddr>
    return -1;
    800052e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e2:	00054d63          	bltz	a0,800052fc <sys_read+0x5c>
  return fileread(f, p, n);
    800052e6:	fe442603          	lw	a2,-28(s0)
    800052ea:	fd843583          	ld	a1,-40(s0)
    800052ee:	fe843503          	ld	a0,-24(s0)
    800052f2:	fffff097          	auipc	ra,0xfffff
    800052f6:	44e080e7          	jalr	1102(ra) # 80004740 <fileread>
    800052fa:	87aa                	mv	a5,a0
}
    800052fc:	853e                	mv	a0,a5
    800052fe:	70a2                	ld	ra,40(sp)
    80005300:	7402                	ld	s0,32(sp)
    80005302:	6145                	addi	sp,sp,48
    80005304:	8082                	ret

0000000080005306 <sys_write>:
{
    80005306:	7179                	addi	sp,sp,-48
    80005308:	f406                	sd	ra,40(sp)
    8000530a:	f022                	sd	s0,32(sp)
    8000530c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530e:	fe840613          	addi	a2,s0,-24
    80005312:	4581                	li	a1,0
    80005314:	4501                	li	a0,0
    80005316:	00000097          	auipc	ra,0x0
    8000531a:	d2a080e7          	jalr	-726(ra) # 80005040 <argfd>
    return -1;
    8000531e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005320:	04054163          	bltz	a0,80005362 <sys_write+0x5c>
    80005324:	fe440593          	addi	a1,s0,-28
    80005328:	4509                	li	a0,2
    8000532a:	ffffe097          	auipc	ra,0xffffe
    8000532e:	854080e7          	jalr	-1964(ra) # 80002b7e <argint>
    return -1;
    80005332:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005334:	02054763          	bltz	a0,80005362 <sys_write+0x5c>
    80005338:	fd840593          	addi	a1,s0,-40
    8000533c:	4505                	li	a0,1
    8000533e:	ffffe097          	auipc	ra,0xffffe
    80005342:	862080e7          	jalr	-1950(ra) # 80002ba0 <argaddr>
    return -1;
    80005346:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005348:	00054d63          	bltz	a0,80005362 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000534c:	fe442603          	lw	a2,-28(s0)
    80005350:	fd843583          	ld	a1,-40(s0)
    80005354:	fe843503          	ld	a0,-24(s0)
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	4aa080e7          	jalr	1194(ra) # 80004802 <filewrite>
    80005360:	87aa                	mv	a5,a0
}
    80005362:	853e                	mv	a0,a5
    80005364:	70a2                	ld	ra,40(sp)
    80005366:	7402                	ld	s0,32(sp)
    80005368:	6145                	addi	sp,sp,48
    8000536a:	8082                	ret

000000008000536c <sys_close>:
{
    8000536c:	1101                	addi	sp,sp,-32
    8000536e:	ec06                	sd	ra,24(sp)
    80005370:	e822                	sd	s0,16(sp)
    80005372:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005374:	fe040613          	addi	a2,s0,-32
    80005378:	fec40593          	addi	a1,s0,-20
    8000537c:	4501                	li	a0,0
    8000537e:	00000097          	auipc	ra,0x0
    80005382:	cc2080e7          	jalr	-830(ra) # 80005040 <argfd>
    return -1;
    80005386:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005388:	02054463          	bltz	a0,800053b0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000538c:	ffffc097          	auipc	ra,0xffffc
    80005390:	69c080e7          	jalr	1692(ra) # 80001a28 <myproc>
    80005394:	fec42783          	lw	a5,-20(s0)
    80005398:	07e9                	addi	a5,a5,26
    8000539a:	078e                	slli	a5,a5,0x3
    8000539c:	97aa                	add	a5,a5,a0
    8000539e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053a2:	fe043503          	ld	a0,-32(s0)
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	260080e7          	jalr	608(ra) # 80004606 <fileclose>
  return 0;
    800053ae:	4781                	li	a5,0
}
    800053b0:	853e                	mv	a0,a5
    800053b2:	60e2                	ld	ra,24(sp)
    800053b4:	6442                	ld	s0,16(sp)
    800053b6:	6105                	addi	sp,sp,32
    800053b8:	8082                	ret

00000000800053ba <sys_fstat>:
{
    800053ba:	1101                	addi	sp,sp,-32
    800053bc:	ec06                	sd	ra,24(sp)
    800053be:	e822                	sd	s0,16(sp)
    800053c0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053c2:	fe840613          	addi	a2,s0,-24
    800053c6:	4581                	li	a1,0
    800053c8:	4501                	li	a0,0
    800053ca:	00000097          	auipc	ra,0x0
    800053ce:	c76080e7          	jalr	-906(ra) # 80005040 <argfd>
    return -1;
    800053d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053d4:	02054563          	bltz	a0,800053fe <sys_fstat+0x44>
    800053d8:	fe040593          	addi	a1,s0,-32
    800053dc:	4505                	li	a0,1
    800053de:	ffffd097          	auipc	ra,0xffffd
    800053e2:	7c2080e7          	jalr	1986(ra) # 80002ba0 <argaddr>
    return -1;
    800053e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053e8:	00054b63          	bltz	a0,800053fe <sys_fstat+0x44>
  return filestat(f, st);
    800053ec:	fe043583          	ld	a1,-32(s0)
    800053f0:	fe843503          	ld	a0,-24(s0)
    800053f4:	fffff097          	auipc	ra,0xfffff
    800053f8:	2da080e7          	jalr	730(ra) # 800046ce <filestat>
    800053fc:	87aa                	mv	a5,a0
}
    800053fe:	853e                	mv	a0,a5
    80005400:	60e2                	ld	ra,24(sp)
    80005402:	6442                	ld	s0,16(sp)
    80005404:	6105                	addi	sp,sp,32
    80005406:	8082                	ret

0000000080005408 <sys_link>:
{
    80005408:	7169                	addi	sp,sp,-304
    8000540a:	f606                	sd	ra,296(sp)
    8000540c:	f222                	sd	s0,288(sp)
    8000540e:	ee26                	sd	s1,280(sp)
    80005410:	ea4a                	sd	s2,272(sp)
    80005412:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005414:	08000613          	li	a2,128
    80005418:	ed040593          	addi	a1,s0,-304
    8000541c:	4501                	li	a0,0
    8000541e:	ffffd097          	auipc	ra,0xffffd
    80005422:	7a4080e7          	jalr	1956(ra) # 80002bc2 <argstr>
    return -1;
    80005426:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005428:	10054e63          	bltz	a0,80005544 <sys_link+0x13c>
    8000542c:	08000613          	li	a2,128
    80005430:	f5040593          	addi	a1,s0,-176
    80005434:	4505                	li	a0,1
    80005436:	ffffd097          	auipc	ra,0xffffd
    8000543a:	78c080e7          	jalr	1932(ra) # 80002bc2 <argstr>
    return -1;
    8000543e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005440:	10054263          	bltz	a0,80005544 <sys_link+0x13c>
  begin_op();
    80005444:	fffff097          	auipc	ra,0xfffff
    80005448:	cf0080e7          	jalr	-784(ra) # 80004134 <begin_op>
  if((ip = namei(old)) == 0){
    8000544c:	ed040513          	addi	a0,s0,-304
    80005450:	fffff097          	auipc	ra,0xfffff
    80005454:	ad8080e7          	jalr	-1320(ra) # 80003f28 <namei>
    80005458:	84aa                	mv	s1,a0
    8000545a:	c551                	beqz	a0,800054e6 <sys_link+0xde>
  ilock(ip);
    8000545c:	ffffe097          	auipc	ra,0xffffe
    80005460:	31c080e7          	jalr	796(ra) # 80003778 <ilock>
  if(ip->type == T_DIR){
    80005464:	04449703          	lh	a4,68(s1)
    80005468:	4785                	li	a5,1
    8000546a:	08f70463          	beq	a4,a5,800054f2 <sys_link+0xea>
  ip->nlink++;
    8000546e:	04a4d783          	lhu	a5,74(s1)
    80005472:	2785                	addiw	a5,a5,1
    80005474:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005478:	8526                	mv	a0,s1
    8000547a:	ffffe097          	auipc	ra,0xffffe
    8000547e:	234080e7          	jalr	564(ra) # 800036ae <iupdate>
  iunlock(ip);
    80005482:	8526                	mv	a0,s1
    80005484:	ffffe097          	auipc	ra,0xffffe
    80005488:	3b6080e7          	jalr	950(ra) # 8000383a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000548c:	fd040593          	addi	a1,s0,-48
    80005490:	f5040513          	addi	a0,s0,-176
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	ab2080e7          	jalr	-1358(ra) # 80003f46 <nameiparent>
    8000549c:	892a                	mv	s2,a0
    8000549e:	c935                	beqz	a0,80005512 <sys_link+0x10a>
  ilock(dp);
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	2d8080e7          	jalr	728(ra) # 80003778 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054a8:	00092703          	lw	a4,0(s2)
    800054ac:	409c                	lw	a5,0(s1)
    800054ae:	04f71d63          	bne	a4,a5,80005508 <sys_link+0x100>
    800054b2:	40d0                	lw	a2,4(s1)
    800054b4:	fd040593          	addi	a1,s0,-48
    800054b8:	854a                	mv	a0,s2
    800054ba:	fffff097          	auipc	ra,0xfffff
    800054be:	9ac080e7          	jalr	-1620(ra) # 80003e66 <dirlink>
    800054c2:	04054363          	bltz	a0,80005508 <sys_link+0x100>
  iunlockput(dp);
    800054c6:	854a                	mv	a0,s2
    800054c8:	ffffe097          	auipc	ra,0xffffe
    800054cc:	512080e7          	jalr	1298(ra) # 800039da <iunlockput>
  iput(ip);
    800054d0:	8526                	mv	a0,s1
    800054d2:	ffffe097          	auipc	ra,0xffffe
    800054d6:	460080e7          	jalr	1120(ra) # 80003932 <iput>
  end_op();
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	cda080e7          	jalr	-806(ra) # 800041b4 <end_op>
  return 0;
    800054e2:	4781                	li	a5,0
    800054e4:	a085                	j	80005544 <sys_link+0x13c>
    end_op();
    800054e6:	fffff097          	auipc	ra,0xfffff
    800054ea:	cce080e7          	jalr	-818(ra) # 800041b4 <end_op>
    return -1;
    800054ee:	57fd                	li	a5,-1
    800054f0:	a891                	j	80005544 <sys_link+0x13c>
    iunlockput(ip);
    800054f2:	8526                	mv	a0,s1
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	4e6080e7          	jalr	1254(ra) # 800039da <iunlockput>
    end_op();
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	cb8080e7          	jalr	-840(ra) # 800041b4 <end_op>
    return -1;
    80005504:	57fd                	li	a5,-1
    80005506:	a83d                	j	80005544 <sys_link+0x13c>
    iunlockput(dp);
    80005508:	854a                	mv	a0,s2
    8000550a:	ffffe097          	auipc	ra,0xffffe
    8000550e:	4d0080e7          	jalr	1232(ra) # 800039da <iunlockput>
  ilock(ip);
    80005512:	8526                	mv	a0,s1
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	264080e7          	jalr	612(ra) # 80003778 <ilock>
  ip->nlink--;
    8000551c:	04a4d783          	lhu	a5,74(s1)
    80005520:	37fd                	addiw	a5,a5,-1
    80005522:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005526:	8526                	mv	a0,s1
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	186080e7          	jalr	390(ra) # 800036ae <iupdate>
  iunlockput(ip);
    80005530:	8526                	mv	a0,s1
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	4a8080e7          	jalr	1192(ra) # 800039da <iunlockput>
  end_op();
    8000553a:	fffff097          	auipc	ra,0xfffff
    8000553e:	c7a080e7          	jalr	-902(ra) # 800041b4 <end_op>
  return -1;
    80005542:	57fd                	li	a5,-1
}
    80005544:	853e                	mv	a0,a5
    80005546:	70b2                	ld	ra,296(sp)
    80005548:	7412                	ld	s0,288(sp)
    8000554a:	64f2                	ld	s1,280(sp)
    8000554c:	6952                	ld	s2,272(sp)
    8000554e:	6155                	addi	sp,sp,304
    80005550:	8082                	ret

0000000080005552 <sys_unlink>:
{
    80005552:	7151                	addi	sp,sp,-240
    80005554:	f586                	sd	ra,232(sp)
    80005556:	f1a2                	sd	s0,224(sp)
    80005558:	eda6                	sd	s1,216(sp)
    8000555a:	e9ca                	sd	s2,208(sp)
    8000555c:	e5ce                	sd	s3,200(sp)
    8000555e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005560:	08000613          	li	a2,128
    80005564:	f3040593          	addi	a1,s0,-208
    80005568:	4501                	li	a0,0
    8000556a:	ffffd097          	auipc	ra,0xffffd
    8000556e:	658080e7          	jalr	1624(ra) # 80002bc2 <argstr>
    80005572:	18054163          	bltz	a0,800056f4 <sys_unlink+0x1a2>
  begin_op();
    80005576:	fffff097          	auipc	ra,0xfffff
    8000557a:	bbe080e7          	jalr	-1090(ra) # 80004134 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000557e:	fb040593          	addi	a1,s0,-80
    80005582:	f3040513          	addi	a0,s0,-208
    80005586:	fffff097          	auipc	ra,0xfffff
    8000558a:	9c0080e7          	jalr	-1600(ra) # 80003f46 <nameiparent>
    8000558e:	84aa                	mv	s1,a0
    80005590:	c979                	beqz	a0,80005666 <sys_unlink+0x114>
  ilock(dp);
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	1e6080e7          	jalr	486(ra) # 80003778 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000559a:	00003597          	auipc	a1,0x3
    8000559e:	2de58593          	addi	a1,a1,734 # 80008878 <syscallnumber_to_name+0x2c8>
    800055a2:	fb040513          	addi	a0,s0,-80
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	696080e7          	jalr	1686(ra) # 80003c3c <namecmp>
    800055ae:	14050a63          	beqz	a0,80005702 <sys_unlink+0x1b0>
    800055b2:	00003597          	auipc	a1,0x3
    800055b6:	2ce58593          	addi	a1,a1,718 # 80008880 <syscallnumber_to_name+0x2d0>
    800055ba:	fb040513          	addi	a0,s0,-80
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	67e080e7          	jalr	1662(ra) # 80003c3c <namecmp>
    800055c6:	12050e63          	beqz	a0,80005702 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055ca:	f2c40613          	addi	a2,s0,-212
    800055ce:	fb040593          	addi	a1,s0,-80
    800055d2:	8526                	mv	a0,s1
    800055d4:	ffffe097          	auipc	ra,0xffffe
    800055d8:	682080e7          	jalr	1666(ra) # 80003c56 <dirlookup>
    800055dc:	892a                	mv	s2,a0
    800055de:	12050263          	beqz	a0,80005702 <sys_unlink+0x1b0>
  ilock(ip);
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	196080e7          	jalr	406(ra) # 80003778 <ilock>
  if(ip->nlink < 1)
    800055ea:	04a91783          	lh	a5,74(s2)
    800055ee:	08f05263          	blez	a5,80005672 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055f2:	04491703          	lh	a4,68(s2)
    800055f6:	4785                	li	a5,1
    800055f8:	08f70563          	beq	a4,a5,80005682 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055fc:	4641                	li	a2,16
    800055fe:	4581                	li	a1,0
    80005600:	fc040513          	addi	a0,s0,-64
    80005604:	ffffb097          	auipc	ra,0xffffb
    80005608:	752080e7          	jalr	1874(ra) # 80000d56 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000560c:	4741                	li	a4,16
    8000560e:	f2c42683          	lw	a3,-212(s0)
    80005612:	fc040613          	addi	a2,s0,-64
    80005616:	4581                	li	a1,0
    80005618:	8526                	mv	a0,s1
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	508080e7          	jalr	1288(ra) # 80003b22 <writei>
    80005622:	47c1                	li	a5,16
    80005624:	0af51563          	bne	a0,a5,800056ce <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005628:	04491703          	lh	a4,68(s2)
    8000562c:	4785                	li	a5,1
    8000562e:	0af70863          	beq	a4,a5,800056de <sys_unlink+0x18c>
  iunlockput(dp);
    80005632:	8526                	mv	a0,s1
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	3a6080e7          	jalr	934(ra) # 800039da <iunlockput>
  ip->nlink--;
    8000563c:	04a95783          	lhu	a5,74(s2)
    80005640:	37fd                	addiw	a5,a5,-1
    80005642:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005646:	854a                	mv	a0,s2
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	066080e7          	jalr	102(ra) # 800036ae <iupdate>
  iunlockput(ip);
    80005650:	854a                	mv	a0,s2
    80005652:	ffffe097          	auipc	ra,0xffffe
    80005656:	388080e7          	jalr	904(ra) # 800039da <iunlockput>
  end_op();
    8000565a:	fffff097          	auipc	ra,0xfffff
    8000565e:	b5a080e7          	jalr	-1190(ra) # 800041b4 <end_op>
  return 0;
    80005662:	4501                	li	a0,0
    80005664:	a84d                	j	80005716 <sys_unlink+0x1c4>
    end_op();
    80005666:	fffff097          	auipc	ra,0xfffff
    8000566a:	b4e080e7          	jalr	-1202(ra) # 800041b4 <end_op>
    return -1;
    8000566e:	557d                	li	a0,-1
    80005670:	a05d                	j	80005716 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005672:	00003517          	auipc	a0,0x3
    80005676:	23650513          	addi	a0,a0,566 # 800088a8 <syscallnumber_to_name+0x2f8>
    8000567a:	ffffb097          	auipc	ra,0xffffb
    8000567e:	ece080e7          	jalr	-306(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005682:	04c92703          	lw	a4,76(s2)
    80005686:	02000793          	li	a5,32
    8000568a:	f6e7f9e3          	bgeu	a5,a4,800055fc <sys_unlink+0xaa>
    8000568e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005692:	4741                	li	a4,16
    80005694:	86ce                	mv	a3,s3
    80005696:	f1840613          	addi	a2,s0,-232
    8000569a:	4581                	li	a1,0
    8000569c:	854a                	mv	a0,s2
    8000569e:	ffffe097          	auipc	ra,0xffffe
    800056a2:	38e080e7          	jalr	910(ra) # 80003a2c <readi>
    800056a6:	47c1                	li	a5,16
    800056a8:	00f51b63          	bne	a0,a5,800056be <sys_unlink+0x16c>
    if(de.inum != 0)
    800056ac:	f1845783          	lhu	a5,-232(s0)
    800056b0:	e7a1                	bnez	a5,800056f8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056b2:	29c1                	addiw	s3,s3,16
    800056b4:	04c92783          	lw	a5,76(s2)
    800056b8:	fcf9ede3          	bltu	s3,a5,80005692 <sys_unlink+0x140>
    800056bc:	b781                	j	800055fc <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056be:	00003517          	auipc	a0,0x3
    800056c2:	20250513          	addi	a0,a0,514 # 800088c0 <syscallnumber_to_name+0x310>
    800056c6:	ffffb097          	auipc	ra,0xffffb
    800056ca:	e82080e7          	jalr	-382(ra) # 80000548 <panic>
    panic("unlink: writei");
    800056ce:	00003517          	auipc	a0,0x3
    800056d2:	20a50513          	addi	a0,a0,522 # 800088d8 <syscallnumber_to_name+0x328>
    800056d6:	ffffb097          	auipc	ra,0xffffb
    800056da:	e72080e7          	jalr	-398(ra) # 80000548 <panic>
    dp->nlink--;
    800056de:	04a4d783          	lhu	a5,74(s1)
    800056e2:	37fd                	addiw	a5,a5,-1
    800056e4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056e8:	8526                	mv	a0,s1
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	fc4080e7          	jalr	-60(ra) # 800036ae <iupdate>
    800056f2:	b781                	j	80005632 <sys_unlink+0xe0>
    return -1;
    800056f4:	557d                	li	a0,-1
    800056f6:	a005                	j	80005716 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056f8:	854a                	mv	a0,s2
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	2e0080e7          	jalr	736(ra) # 800039da <iunlockput>
  iunlockput(dp);
    80005702:	8526                	mv	a0,s1
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	2d6080e7          	jalr	726(ra) # 800039da <iunlockput>
  end_op();
    8000570c:	fffff097          	auipc	ra,0xfffff
    80005710:	aa8080e7          	jalr	-1368(ra) # 800041b4 <end_op>
  return -1;
    80005714:	557d                	li	a0,-1
}
    80005716:	70ae                	ld	ra,232(sp)
    80005718:	740e                	ld	s0,224(sp)
    8000571a:	64ee                	ld	s1,216(sp)
    8000571c:	694e                	ld	s2,208(sp)
    8000571e:	69ae                	ld	s3,200(sp)
    80005720:	616d                	addi	sp,sp,240
    80005722:	8082                	ret

0000000080005724 <sys_open>:

uint64
sys_open(void)
{
    80005724:	7131                	addi	sp,sp,-192
    80005726:	fd06                	sd	ra,184(sp)
    80005728:	f922                	sd	s0,176(sp)
    8000572a:	f526                	sd	s1,168(sp)
    8000572c:	f14a                	sd	s2,160(sp)
    8000572e:	ed4e                	sd	s3,152(sp)
    80005730:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005732:	08000613          	li	a2,128
    80005736:	f5040593          	addi	a1,s0,-176
    8000573a:	4501                	li	a0,0
    8000573c:	ffffd097          	auipc	ra,0xffffd
    80005740:	486080e7          	jalr	1158(ra) # 80002bc2 <argstr>
    return -1;
    80005744:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005746:	0c054163          	bltz	a0,80005808 <sys_open+0xe4>
    8000574a:	f4c40593          	addi	a1,s0,-180
    8000574e:	4505                	li	a0,1
    80005750:	ffffd097          	auipc	ra,0xffffd
    80005754:	42e080e7          	jalr	1070(ra) # 80002b7e <argint>
    80005758:	0a054863          	bltz	a0,80005808 <sys_open+0xe4>

  begin_op();
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	9d8080e7          	jalr	-1576(ra) # 80004134 <begin_op>

  if(omode & O_CREATE){
    80005764:	f4c42783          	lw	a5,-180(s0)
    80005768:	2007f793          	andi	a5,a5,512
    8000576c:	cbdd                	beqz	a5,80005822 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000576e:	4681                	li	a3,0
    80005770:	4601                	li	a2,0
    80005772:	4589                	li	a1,2
    80005774:	f5040513          	addi	a0,s0,-176
    80005778:	00000097          	auipc	ra,0x0
    8000577c:	972080e7          	jalr	-1678(ra) # 800050ea <create>
    80005780:	892a                	mv	s2,a0
    if(ip == 0){
    80005782:	c959                	beqz	a0,80005818 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005784:	04491703          	lh	a4,68(s2)
    80005788:	478d                	li	a5,3
    8000578a:	00f71763          	bne	a4,a5,80005798 <sys_open+0x74>
    8000578e:	04695703          	lhu	a4,70(s2)
    80005792:	47a5                	li	a5,9
    80005794:	0ce7ec63          	bltu	a5,a4,8000586c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	db2080e7          	jalr	-590(ra) # 8000454a <filealloc>
    800057a0:	89aa                	mv	s3,a0
    800057a2:	10050263          	beqz	a0,800058a6 <sys_open+0x182>
    800057a6:	00000097          	auipc	ra,0x0
    800057aa:	902080e7          	jalr	-1790(ra) # 800050a8 <fdalloc>
    800057ae:	84aa                	mv	s1,a0
    800057b0:	0e054663          	bltz	a0,8000589c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057b4:	04491703          	lh	a4,68(s2)
    800057b8:	478d                	li	a5,3
    800057ba:	0cf70463          	beq	a4,a5,80005882 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057be:	4789                	li	a5,2
    800057c0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057c4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057c8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057cc:	f4c42783          	lw	a5,-180(s0)
    800057d0:	0017c713          	xori	a4,a5,1
    800057d4:	8b05                	andi	a4,a4,1
    800057d6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057da:	0037f713          	andi	a4,a5,3
    800057de:	00e03733          	snez	a4,a4
    800057e2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057e6:	4007f793          	andi	a5,a5,1024
    800057ea:	c791                	beqz	a5,800057f6 <sys_open+0xd2>
    800057ec:	04491703          	lh	a4,68(s2)
    800057f0:	4789                	li	a5,2
    800057f2:	08f70f63          	beq	a4,a5,80005890 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057f6:	854a                	mv	a0,s2
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	042080e7          	jalr	66(ra) # 8000383a <iunlock>
  end_op();
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	9b4080e7          	jalr	-1612(ra) # 800041b4 <end_op>

  return fd;
}
    80005808:	8526                	mv	a0,s1
    8000580a:	70ea                	ld	ra,184(sp)
    8000580c:	744a                	ld	s0,176(sp)
    8000580e:	74aa                	ld	s1,168(sp)
    80005810:	790a                	ld	s2,160(sp)
    80005812:	69ea                	ld	s3,152(sp)
    80005814:	6129                	addi	sp,sp,192
    80005816:	8082                	ret
      end_op();
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	99c080e7          	jalr	-1636(ra) # 800041b4 <end_op>
      return -1;
    80005820:	b7e5                	j	80005808 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005822:	f5040513          	addi	a0,s0,-176
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	702080e7          	jalr	1794(ra) # 80003f28 <namei>
    8000582e:	892a                	mv	s2,a0
    80005830:	c905                	beqz	a0,80005860 <sys_open+0x13c>
    ilock(ip);
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	f46080e7          	jalr	-186(ra) # 80003778 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000583a:	04491703          	lh	a4,68(s2)
    8000583e:	4785                	li	a5,1
    80005840:	f4f712e3          	bne	a4,a5,80005784 <sys_open+0x60>
    80005844:	f4c42783          	lw	a5,-180(s0)
    80005848:	dba1                	beqz	a5,80005798 <sys_open+0x74>
      iunlockput(ip);
    8000584a:	854a                	mv	a0,s2
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	18e080e7          	jalr	398(ra) # 800039da <iunlockput>
      end_op();
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	960080e7          	jalr	-1696(ra) # 800041b4 <end_op>
      return -1;
    8000585c:	54fd                	li	s1,-1
    8000585e:	b76d                	j	80005808 <sys_open+0xe4>
      end_op();
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	954080e7          	jalr	-1708(ra) # 800041b4 <end_op>
      return -1;
    80005868:	54fd                	li	s1,-1
    8000586a:	bf79                	j	80005808 <sys_open+0xe4>
    iunlockput(ip);
    8000586c:	854a                	mv	a0,s2
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	16c080e7          	jalr	364(ra) # 800039da <iunlockput>
    end_op();
    80005876:	fffff097          	auipc	ra,0xfffff
    8000587a:	93e080e7          	jalr	-1730(ra) # 800041b4 <end_op>
    return -1;
    8000587e:	54fd                	li	s1,-1
    80005880:	b761                	j	80005808 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005882:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005886:	04691783          	lh	a5,70(s2)
    8000588a:	02f99223          	sh	a5,36(s3)
    8000588e:	bf2d                	j	800057c8 <sys_open+0xa4>
    itrunc(ip);
    80005890:	854a                	mv	a0,s2
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	ff4080e7          	jalr	-12(ra) # 80003886 <itrunc>
    8000589a:	bfb1                	j	800057f6 <sys_open+0xd2>
      fileclose(f);
    8000589c:	854e                	mv	a0,s3
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	d68080e7          	jalr	-664(ra) # 80004606 <fileclose>
    iunlockput(ip);
    800058a6:	854a                	mv	a0,s2
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	132080e7          	jalr	306(ra) # 800039da <iunlockput>
    end_op();
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	904080e7          	jalr	-1788(ra) # 800041b4 <end_op>
    return -1;
    800058b8:	54fd                	li	s1,-1
    800058ba:	b7b9                	j	80005808 <sys_open+0xe4>

00000000800058bc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058bc:	7175                	addi	sp,sp,-144
    800058be:	e506                	sd	ra,136(sp)
    800058c0:	e122                	sd	s0,128(sp)
    800058c2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	870080e7          	jalr	-1936(ra) # 80004134 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058cc:	08000613          	li	a2,128
    800058d0:	f7040593          	addi	a1,s0,-144
    800058d4:	4501                	li	a0,0
    800058d6:	ffffd097          	auipc	ra,0xffffd
    800058da:	2ec080e7          	jalr	748(ra) # 80002bc2 <argstr>
    800058de:	02054963          	bltz	a0,80005910 <sys_mkdir+0x54>
    800058e2:	4681                	li	a3,0
    800058e4:	4601                	li	a2,0
    800058e6:	4585                	li	a1,1
    800058e8:	f7040513          	addi	a0,s0,-144
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	7fe080e7          	jalr	2046(ra) # 800050ea <create>
    800058f4:	cd11                	beqz	a0,80005910 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	0e4080e7          	jalr	228(ra) # 800039da <iunlockput>
  end_op();
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	8b6080e7          	jalr	-1866(ra) # 800041b4 <end_op>
  return 0;
    80005906:	4501                	li	a0,0
}
    80005908:	60aa                	ld	ra,136(sp)
    8000590a:	640a                	ld	s0,128(sp)
    8000590c:	6149                	addi	sp,sp,144
    8000590e:	8082                	ret
    end_op();
    80005910:	fffff097          	auipc	ra,0xfffff
    80005914:	8a4080e7          	jalr	-1884(ra) # 800041b4 <end_op>
    return -1;
    80005918:	557d                	li	a0,-1
    8000591a:	b7fd                	j	80005908 <sys_mkdir+0x4c>

000000008000591c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000591c:	7135                	addi	sp,sp,-160
    8000591e:	ed06                	sd	ra,152(sp)
    80005920:	e922                	sd	s0,144(sp)
    80005922:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	810080e7          	jalr	-2032(ra) # 80004134 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000592c:	08000613          	li	a2,128
    80005930:	f7040593          	addi	a1,s0,-144
    80005934:	4501                	li	a0,0
    80005936:	ffffd097          	auipc	ra,0xffffd
    8000593a:	28c080e7          	jalr	652(ra) # 80002bc2 <argstr>
    8000593e:	04054a63          	bltz	a0,80005992 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005942:	f6c40593          	addi	a1,s0,-148
    80005946:	4505                	li	a0,1
    80005948:	ffffd097          	auipc	ra,0xffffd
    8000594c:	236080e7          	jalr	566(ra) # 80002b7e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005950:	04054163          	bltz	a0,80005992 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005954:	f6840593          	addi	a1,s0,-152
    80005958:	4509                	li	a0,2
    8000595a:	ffffd097          	auipc	ra,0xffffd
    8000595e:	224080e7          	jalr	548(ra) # 80002b7e <argint>
     argint(1, &major) < 0 ||
    80005962:	02054863          	bltz	a0,80005992 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005966:	f6841683          	lh	a3,-152(s0)
    8000596a:	f6c41603          	lh	a2,-148(s0)
    8000596e:	458d                	li	a1,3
    80005970:	f7040513          	addi	a0,s0,-144
    80005974:	fffff097          	auipc	ra,0xfffff
    80005978:	776080e7          	jalr	1910(ra) # 800050ea <create>
     argint(2, &minor) < 0 ||
    8000597c:	c919                	beqz	a0,80005992 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	05c080e7          	jalr	92(ra) # 800039da <iunlockput>
  end_op();
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	82e080e7          	jalr	-2002(ra) # 800041b4 <end_op>
  return 0;
    8000598e:	4501                	li	a0,0
    80005990:	a031                	j	8000599c <sys_mknod+0x80>
    end_op();
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	822080e7          	jalr	-2014(ra) # 800041b4 <end_op>
    return -1;
    8000599a:	557d                	li	a0,-1
}
    8000599c:	60ea                	ld	ra,152(sp)
    8000599e:	644a                	ld	s0,144(sp)
    800059a0:	610d                	addi	sp,sp,160
    800059a2:	8082                	ret

00000000800059a4 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059a4:	7135                	addi	sp,sp,-160
    800059a6:	ed06                	sd	ra,152(sp)
    800059a8:	e922                	sd	s0,144(sp)
    800059aa:	e526                	sd	s1,136(sp)
    800059ac:	e14a                	sd	s2,128(sp)
    800059ae:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059b0:	ffffc097          	auipc	ra,0xffffc
    800059b4:	078080e7          	jalr	120(ra) # 80001a28 <myproc>
    800059b8:	892a                	mv	s2,a0
  
  begin_op();
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	77a080e7          	jalr	1914(ra) # 80004134 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059c2:	08000613          	li	a2,128
    800059c6:	f6040593          	addi	a1,s0,-160
    800059ca:	4501                	li	a0,0
    800059cc:	ffffd097          	auipc	ra,0xffffd
    800059d0:	1f6080e7          	jalr	502(ra) # 80002bc2 <argstr>
    800059d4:	04054b63          	bltz	a0,80005a2a <sys_chdir+0x86>
    800059d8:	f6040513          	addi	a0,s0,-160
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	54c080e7          	jalr	1356(ra) # 80003f28 <namei>
    800059e4:	84aa                	mv	s1,a0
    800059e6:	c131                	beqz	a0,80005a2a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	d90080e7          	jalr	-624(ra) # 80003778 <ilock>
  if(ip->type != T_DIR){
    800059f0:	04449703          	lh	a4,68(s1)
    800059f4:	4785                	li	a5,1
    800059f6:	04f71063          	bne	a4,a5,80005a36 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059fa:	8526                	mv	a0,s1
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	e3e080e7          	jalr	-450(ra) # 8000383a <iunlock>
  iput(p->cwd);
    80005a04:	15093503          	ld	a0,336(s2)
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	f2a080e7          	jalr	-214(ra) # 80003932 <iput>
  end_op();
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	7a4080e7          	jalr	1956(ra) # 800041b4 <end_op>
  p->cwd = ip;
    80005a18:	14993823          	sd	s1,336(s2)
  return 0;
    80005a1c:	4501                	li	a0,0
}
    80005a1e:	60ea                	ld	ra,152(sp)
    80005a20:	644a                	ld	s0,144(sp)
    80005a22:	64aa                	ld	s1,136(sp)
    80005a24:	690a                	ld	s2,128(sp)
    80005a26:	610d                	addi	sp,sp,160
    80005a28:	8082                	ret
    end_op();
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	78a080e7          	jalr	1930(ra) # 800041b4 <end_op>
    return -1;
    80005a32:	557d                	li	a0,-1
    80005a34:	b7ed                	j	80005a1e <sys_chdir+0x7a>
    iunlockput(ip);
    80005a36:	8526                	mv	a0,s1
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	fa2080e7          	jalr	-94(ra) # 800039da <iunlockput>
    end_op();
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	774080e7          	jalr	1908(ra) # 800041b4 <end_op>
    return -1;
    80005a48:	557d                	li	a0,-1
    80005a4a:	bfd1                	j	80005a1e <sys_chdir+0x7a>

0000000080005a4c <sys_exec>:

uint64
sys_exec(void)
{
    80005a4c:	7145                	addi	sp,sp,-464
    80005a4e:	e786                	sd	ra,456(sp)
    80005a50:	e3a2                	sd	s0,448(sp)
    80005a52:	ff26                	sd	s1,440(sp)
    80005a54:	fb4a                	sd	s2,432(sp)
    80005a56:	f74e                	sd	s3,424(sp)
    80005a58:	f352                	sd	s4,416(sp)
    80005a5a:	ef56                	sd	s5,408(sp)
    80005a5c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a5e:	08000613          	li	a2,128
    80005a62:	f4040593          	addi	a1,s0,-192
    80005a66:	4501                	li	a0,0
    80005a68:	ffffd097          	auipc	ra,0xffffd
    80005a6c:	15a080e7          	jalr	346(ra) # 80002bc2 <argstr>
    return -1;
    80005a70:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a72:	0c054a63          	bltz	a0,80005b46 <sys_exec+0xfa>
    80005a76:	e3840593          	addi	a1,s0,-456
    80005a7a:	4505                	li	a0,1
    80005a7c:	ffffd097          	auipc	ra,0xffffd
    80005a80:	124080e7          	jalr	292(ra) # 80002ba0 <argaddr>
    80005a84:	0c054163          	bltz	a0,80005b46 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a88:	10000613          	li	a2,256
    80005a8c:	4581                	li	a1,0
    80005a8e:	e4040513          	addi	a0,s0,-448
    80005a92:	ffffb097          	auipc	ra,0xffffb
    80005a96:	2c4080e7          	jalr	708(ra) # 80000d56 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a9a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a9e:	89a6                	mv	s3,s1
    80005aa0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005aa2:	02000a13          	li	s4,32
    80005aa6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005aaa:	00391513          	slli	a0,s2,0x3
    80005aae:	e3040593          	addi	a1,s0,-464
    80005ab2:	e3843783          	ld	a5,-456(s0)
    80005ab6:	953e                	add	a0,a0,a5
    80005ab8:	ffffd097          	auipc	ra,0xffffd
    80005abc:	02c080e7          	jalr	44(ra) # 80002ae4 <fetchaddr>
    80005ac0:	02054a63          	bltz	a0,80005af4 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ac4:	e3043783          	ld	a5,-464(s0)
    80005ac8:	c3b9                	beqz	a5,80005b0e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005aca:	ffffb097          	auipc	ra,0xffffb
    80005ace:	056080e7          	jalr	86(ra) # 80000b20 <kalloc>
    80005ad2:	85aa                	mv	a1,a0
    80005ad4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ad8:	cd11                	beqz	a0,80005af4 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ada:	6605                	lui	a2,0x1
    80005adc:	e3043503          	ld	a0,-464(s0)
    80005ae0:	ffffd097          	auipc	ra,0xffffd
    80005ae4:	056080e7          	jalr	86(ra) # 80002b36 <fetchstr>
    80005ae8:	00054663          	bltz	a0,80005af4 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005aec:	0905                	addi	s2,s2,1
    80005aee:	09a1                	addi	s3,s3,8
    80005af0:	fb491be3          	bne	s2,s4,80005aa6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af4:	10048913          	addi	s2,s1,256
    80005af8:	6088                	ld	a0,0(s1)
    80005afa:	c529                	beqz	a0,80005b44 <sys_exec+0xf8>
    kfree(argv[i]);
    80005afc:	ffffb097          	auipc	ra,0xffffb
    80005b00:	f28080e7          	jalr	-216(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b04:	04a1                	addi	s1,s1,8
    80005b06:	ff2499e3          	bne	s1,s2,80005af8 <sys_exec+0xac>
  return -1;
    80005b0a:	597d                	li	s2,-1
    80005b0c:	a82d                	j	80005b46 <sys_exec+0xfa>
      argv[i] = 0;
    80005b0e:	0a8e                	slli	s5,s5,0x3
    80005b10:	fc040793          	addi	a5,s0,-64
    80005b14:	9abe                	add	s5,s5,a5
    80005b16:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b1a:	e4040593          	addi	a1,s0,-448
    80005b1e:	f4040513          	addi	a0,s0,-192
    80005b22:	fffff097          	auipc	ra,0xfffff
    80005b26:	194080e7          	jalr	404(ra) # 80004cb6 <exec>
    80005b2a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b2c:	10048993          	addi	s3,s1,256
    80005b30:	6088                	ld	a0,0(s1)
    80005b32:	c911                	beqz	a0,80005b46 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b34:	ffffb097          	auipc	ra,0xffffb
    80005b38:	ef0080e7          	jalr	-272(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b3c:	04a1                	addi	s1,s1,8
    80005b3e:	ff3499e3          	bne	s1,s3,80005b30 <sys_exec+0xe4>
    80005b42:	a011                	j	80005b46 <sys_exec+0xfa>
  return -1;
    80005b44:	597d                	li	s2,-1
}
    80005b46:	854a                	mv	a0,s2
    80005b48:	60be                	ld	ra,456(sp)
    80005b4a:	641e                	ld	s0,448(sp)
    80005b4c:	74fa                	ld	s1,440(sp)
    80005b4e:	795a                	ld	s2,432(sp)
    80005b50:	79ba                	ld	s3,424(sp)
    80005b52:	7a1a                	ld	s4,416(sp)
    80005b54:	6afa                	ld	s5,408(sp)
    80005b56:	6179                	addi	sp,sp,464
    80005b58:	8082                	ret

0000000080005b5a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b5a:	7139                	addi	sp,sp,-64
    80005b5c:	fc06                	sd	ra,56(sp)
    80005b5e:	f822                	sd	s0,48(sp)
    80005b60:	f426                	sd	s1,40(sp)
    80005b62:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b64:	ffffc097          	auipc	ra,0xffffc
    80005b68:	ec4080e7          	jalr	-316(ra) # 80001a28 <myproc>
    80005b6c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b6e:	fd840593          	addi	a1,s0,-40
    80005b72:	4501                	li	a0,0
    80005b74:	ffffd097          	auipc	ra,0xffffd
    80005b78:	02c080e7          	jalr	44(ra) # 80002ba0 <argaddr>
    return -1;
    80005b7c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b7e:	0e054063          	bltz	a0,80005c5e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b82:	fc840593          	addi	a1,s0,-56
    80005b86:	fd040513          	addi	a0,s0,-48
    80005b8a:	fffff097          	auipc	ra,0xfffff
    80005b8e:	dd2080e7          	jalr	-558(ra) # 8000495c <pipealloc>
    return -1;
    80005b92:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b94:	0c054563          	bltz	a0,80005c5e <sys_pipe+0x104>
  fd0 = -1;
    80005b98:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b9c:	fd043503          	ld	a0,-48(s0)
    80005ba0:	fffff097          	auipc	ra,0xfffff
    80005ba4:	508080e7          	jalr	1288(ra) # 800050a8 <fdalloc>
    80005ba8:	fca42223          	sw	a0,-60(s0)
    80005bac:	08054c63          	bltz	a0,80005c44 <sys_pipe+0xea>
    80005bb0:	fc843503          	ld	a0,-56(s0)
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	4f4080e7          	jalr	1268(ra) # 800050a8 <fdalloc>
    80005bbc:	fca42023          	sw	a0,-64(s0)
    80005bc0:	06054863          	bltz	a0,80005c30 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bc4:	4691                	li	a3,4
    80005bc6:	fc440613          	addi	a2,s0,-60
    80005bca:	fd843583          	ld	a1,-40(s0)
    80005bce:	68a8                	ld	a0,80(s1)
    80005bd0:	ffffc097          	auipc	ra,0xffffc
    80005bd4:	b4c080e7          	jalr	-1204(ra) # 8000171c <copyout>
    80005bd8:	02054063          	bltz	a0,80005bf8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bdc:	4691                	li	a3,4
    80005bde:	fc040613          	addi	a2,s0,-64
    80005be2:	fd843583          	ld	a1,-40(s0)
    80005be6:	0591                	addi	a1,a1,4
    80005be8:	68a8                	ld	a0,80(s1)
    80005bea:	ffffc097          	auipc	ra,0xffffc
    80005bee:	b32080e7          	jalr	-1230(ra) # 8000171c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bf2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bf4:	06055563          	bgez	a0,80005c5e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bf8:	fc442783          	lw	a5,-60(s0)
    80005bfc:	07e9                	addi	a5,a5,26
    80005bfe:	078e                	slli	a5,a5,0x3
    80005c00:	97a6                	add	a5,a5,s1
    80005c02:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c06:	fc042503          	lw	a0,-64(s0)
    80005c0a:	0569                	addi	a0,a0,26
    80005c0c:	050e                	slli	a0,a0,0x3
    80005c0e:	9526                	add	a0,a0,s1
    80005c10:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c14:	fd043503          	ld	a0,-48(s0)
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	9ee080e7          	jalr	-1554(ra) # 80004606 <fileclose>
    fileclose(wf);
    80005c20:	fc843503          	ld	a0,-56(s0)
    80005c24:	fffff097          	auipc	ra,0xfffff
    80005c28:	9e2080e7          	jalr	-1566(ra) # 80004606 <fileclose>
    return -1;
    80005c2c:	57fd                	li	a5,-1
    80005c2e:	a805                	j	80005c5e <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c30:	fc442783          	lw	a5,-60(s0)
    80005c34:	0007c863          	bltz	a5,80005c44 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c38:	01a78513          	addi	a0,a5,26
    80005c3c:	050e                	slli	a0,a0,0x3
    80005c3e:	9526                	add	a0,a0,s1
    80005c40:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c44:	fd043503          	ld	a0,-48(s0)
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	9be080e7          	jalr	-1602(ra) # 80004606 <fileclose>
    fileclose(wf);
    80005c50:	fc843503          	ld	a0,-56(s0)
    80005c54:	fffff097          	auipc	ra,0xfffff
    80005c58:	9b2080e7          	jalr	-1614(ra) # 80004606 <fileclose>
    return -1;
    80005c5c:	57fd                	li	a5,-1
}
    80005c5e:	853e                	mv	a0,a5
    80005c60:	70e2                	ld	ra,56(sp)
    80005c62:	7442                	ld	s0,48(sp)
    80005c64:	74a2                	ld	s1,40(sp)
    80005c66:	6121                	addi	sp,sp,64
    80005c68:	8082                	ret
    80005c6a:	0000                	unimp
    80005c6c:	0000                	unimp
	...

0000000080005c70 <kernelvec>:
    80005c70:	7111                	addi	sp,sp,-256
    80005c72:	e006                	sd	ra,0(sp)
    80005c74:	e40a                	sd	sp,8(sp)
    80005c76:	e80e                	sd	gp,16(sp)
    80005c78:	ec12                	sd	tp,24(sp)
    80005c7a:	f016                	sd	t0,32(sp)
    80005c7c:	f41a                	sd	t1,40(sp)
    80005c7e:	f81e                	sd	t2,48(sp)
    80005c80:	fc22                	sd	s0,56(sp)
    80005c82:	e0a6                	sd	s1,64(sp)
    80005c84:	e4aa                	sd	a0,72(sp)
    80005c86:	e8ae                	sd	a1,80(sp)
    80005c88:	ecb2                	sd	a2,88(sp)
    80005c8a:	f0b6                	sd	a3,96(sp)
    80005c8c:	f4ba                	sd	a4,104(sp)
    80005c8e:	f8be                	sd	a5,112(sp)
    80005c90:	fcc2                	sd	a6,120(sp)
    80005c92:	e146                	sd	a7,128(sp)
    80005c94:	e54a                	sd	s2,136(sp)
    80005c96:	e94e                	sd	s3,144(sp)
    80005c98:	ed52                	sd	s4,152(sp)
    80005c9a:	f156                	sd	s5,160(sp)
    80005c9c:	f55a                	sd	s6,168(sp)
    80005c9e:	f95e                	sd	s7,176(sp)
    80005ca0:	fd62                	sd	s8,184(sp)
    80005ca2:	e1e6                	sd	s9,192(sp)
    80005ca4:	e5ea                	sd	s10,200(sp)
    80005ca6:	e9ee                	sd	s11,208(sp)
    80005ca8:	edf2                	sd	t3,216(sp)
    80005caa:	f1f6                	sd	t4,224(sp)
    80005cac:	f5fa                	sd	t5,232(sp)
    80005cae:	f9fe                	sd	t6,240(sp)
    80005cb0:	d01fc0ef          	jal	ra,800029b0 <kerneltrap>
    80005cb4:	6082                	ld	ra,0(sp)
    80005cb6:	6122                	ld	sp,8(sp)
    80005cb8:	61c2                	ld	gp,16(sp)
    80005cba:	7282                	ld	t0,32(sp)
    80005cbc:	7322                	ld	t1,40(sp)
    80005cbe:	73c2                	ld	t2,48(sp)
    80005cc0:	7462                	ld	s0,56(sp)
    80005cc2:	6486                	ld	s1,64(sp)
    80005cc4:	6526                	ld	a0,72(sp)
    80005cc6:	65c6                	ld	a1,80(sp)
    80005cc8:	6666                	ld	a2,88(sp)
    80005cca:	7686                	ld	a3,96(sp)
    80005ccc:	7726                	ld	a4,104(sp)
    80005cce:	77c6                	ld	a5,112(sp)
    80005cd0:	7866                	ld	a6,120(sp)
    80005cd2:	688a                	ld	a7,128(sp)
    80005cd4:	692a                	ld	s2,136(sp)
    80005cd6:	69ca                	ld	s3,144(sp)
    80005cd8:	6a6a                	ld	s4,152(sp)
    80005cda:	7a8a                	ld	s5,160(sp)
    80005cdc:	7b2a                	ld	s6,168(sp)
    80005cde:	7bca                	ld	s7,176(sp)
    80005ce0:	7c6a                	ld	s8,184(sp)
    80005ce2:	6c8e                	ld	s9,192(sp)
    80005ce4:	6d2e                	ld	s10,200(sp)
    80005ce6:	6dce                	ld	s11,208(sp)
    80005ce8:	6e6e                	ld	t3,216(sp)
    80005cea:	7e8e                	ld	t4,224(sp)
    80005cec:	7f2e                	ld	t5,232(sp)
    80005cee:	7fce                	ld	t6,240(sp)
    80005cf0:	6111                	addi	sp,sp,256
    80005cf2:	10200073          	sret
    80005cf6:	00000013          	nop
    80005cfa:	00000013          	nop
    80005cfe:	0001                	nop

0000000080005d00 <timervec>:
    80005d00:	34051573          	csrrw	a0,mscratch,a0
    80005d04:	e10c                	sd	a1,0(a0)
    80005d06:	e510                	sd	a2,8(a0)
    80005d08:	e914                	sd	a3,16(a0)
    80005d0a:	710c                	ld	a1,32(a0)
    80005d0c:	7510                	ld	a2,40(a0)
    80005d0e:	6194                	ld	a3,0(a1)
    80005d10:	96b2                	add	a3,a3,a2
    80005d12:	e194                	sd	a3,0(a1)
    80005d14:	4589                	li	a1,2
    80005d16:	14459073          	csrw	sip,a1
    80005d1a:	6914                	ld	a3,16(a0)
    80005d1c:	6510                	ld	a2,8(a0)
    80005d1e:	610c                	ld	a1,0(a0)
    80005d20:	34051573          	csrrw	a0,mscratch,a0
    80005d24:	30200073          	mret
	...

0000000080005d2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d2a:	1141                	addi	sp,sp,-16
    80005d2c:	e422                	sd	s0,8(sp)
    80005d2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d30:	0c0007b7          	lui	a5,0xc000
    80005d34:	4705                	li	a4,1
    80005d36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d38:	c3d8                	sw	a4,4(a5)
}
    80005d3a:	6422                	ld	s0,8(sp)
    80005d3c:	0141                	addi	sp,sp,16
    80005d3e:	8082                	ret

0000000080005d40 <plicinithart>:

void
plicinithart(void)
{
    80005d40:	1141                	addi	sp,sp,-16
    80005d42:	e406                	sd	ra,8(sp)
    80005d44:	e022                	sd	s0,0(sp)
    80005d46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	cb4080e7          	jalr	-844(ra) # 800019fc <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d50:	0085171b          	slliw	a4,a0,0x8
    80005d54:	0c0027b7          	lui	a5,0xc002
    80005d58:	97ba                	add	a5,a5,a4
    80005d5a:	40200713          	li	a4,1026
    80005d5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d62:	00d5151b          	slliw	a0,a0,0xd
    80005d66:	0c2017b7          	lui	a5,0xc201
    80005d6a:	953e                	add	a0,a0,a5
    80005d6c:	00052023          	sw	zero,0(a0)
}
    80005d70:	60a2                	ld	ra,8(sp)
    80005d72:	6402                	ld	s0,0(sp)
    80005d74:	0141                	addi	sp,sp,16
    80005d76:	8082                	ret

0000000080005d78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d78:	1141                	addi	sp,sp,-16
    80005d7a:	e406                	sd	ra,8(sp)
    80005d7c:	e022                	sd	s0,0(sp)
    80005d7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d80:	ffffc097          	auipc	ra,0xffffc
    80005d84:	c7c080e7          	jalr	-900(ra) # 800019fc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d88:	00d5179b          	slliw	a5,a0,0xd
    80005d8c:	0c201537          	lui	a0,0xc201
    80005d90:	953e                	add	a0,a0,a5
  return irq;
}
    80005d92:	4148                	lw	a0,4(a0)
    80005d94:	60a2                	ld	ra,8(sp)
    80005d96:	6402                	ld	s0,0(sp)
    80005d98:	0141                	addi	sp,sp,16
    80005d9a:	8082                	ret

0000000080005d9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d9c:	1101                	addi	sp,sp,-32
    80005d9e:	ec06                	sd	ra,24(sp)
    80005da0:	e822                	sd	s0,16(sp)
    80005da2:	e426                	sd	s1,8(sp)
    80005da4:	1000                	addi	s0,sp,32
    80005da6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	c54080e7          	jalr	-940(ra) # 800019fc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005db0:	00d5151b          	slliw	a0,a0,0xd
    80005db4:	0c2017b7          	lui	a5,0xc201
    80005db8:	97aa                	add	a5,a5,a0
    80005dba:	c3c4                	sw	s1,4(a5)
}
    80005dbc:	60e2                	ld	ra,24(sp)
    80005dbe:	6442                	ld	s0,16(sp)
    80005dc0:	64a2                	ld	s1,8(sp)
    80005dc2:	6105                	addi	sp,sp,32
    80005dc4:	8082                	ret

0000000080005dc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005dc6:	1141                	addi	sp,sp,-16
    80005dc8:	e406                	sd	ra,8(sp)
    80005dca:	e022                	sd	s0,0(sp)
    80005dcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dce:	479d                	li	a5,7
    80005dd0:	04a7cc63          	blt	a5,a0,80005e28 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005dd4:	0001d797          	auipc	a5,0x1d
    80005dd8:	22c78793          	addi	a5,a5,556 # 80023000 <disk>
    80005ddc:	00a78733          	add	a4,a5,a0
    80005de0:	6789                	lui	a5,0x2
    80005de2:	97ba                	add	a5,a5,a4
    80005de4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005de8:	eba1                	bnez	a5,80005e38 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005dea:	00451713          	slli	a4,a0,0x4
    80005dee:	0001f797          	auipc	a5,0x1f
    80005df2:	2127b783          	ld	a5,530(a5) # 80025000 <disk+0x2000>
    80005df6:	97ba                	add	a5,a5,a4
    80005df8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005dfc:	0001d797          	auipc	a5,0x1d
    80005e00:	20478793          	addi	a5,a5,516 # 80023000 <disk>
    80005e04:	97aa                	add	a5,a5,a0
    80005e06:	6509                	lui	a0,0x2
    80005e08:	953e                	add	a0,a0,a5
    80005e0a:	4785                	li	a5,1
    80005e0c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e10:	0001f517          	auipc	a0,0x1f
    80005e14:	20850513          	addi	a0,a0,520 # 80025018 <disk+0x2018>
    80005e18:	ffffc097          	auipc	ra,0xffffc
    80005e1c:	5ae080e7          	jalr	1454(ra) # 800023c6 <wakeup>
}
    80005e20:	60a2                	ld	ra,8(sp)
    80005e22:	6402                	ld	s0,0(sp)
    80005e24:	0141                	addi	sp,sp,16
    80005e26:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e28:	00003517          	auipc	a0,0x3
    80005e2c:	ac050513          	addi	a0,a0,-1344 # 800088e8 <syscallnumber_to_name+0x338>
    80005e30:	ffffa097          	auipc	ra,0xffffa
    80005e34:	718080e7          	jalr	1816(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005e38:	00003517          	auipc	a0,0x3
    80005e3c:	ac850513          	addi	a0,a0,-1336 # 80008900 <syscallnumber_to_name+0x350>
    80005e40:	ffffa097          	auipc	ra,0xffffa
    80005e44:	708080e7          	jalr	1800(ra) # 80000548 <panic>

0000000080005e48 <virtio_disk_init>:
{
    80005e48:	1101                	addi	sp,sp,-32
    80005e4a:	ec06                	sd	ra,24(sp)
    80005e4c:	e822                	sd	s0,16(sp)
    80005e4e:	e426                	sd	s1,8(sp)
    80005e50:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e52:	00003597          	auipc	a1,0x3
    80005e56:	ac658593          	addi	a1,a1,-1338 # 80008918 <syscallnumber_to_name+0x368>
    80005e5a:	0001f517          	auipc	a0,0x1f
    80005e5e:	24e50513          	addi	a0,a0,590 # 800250a8 <disk+0x20a8>
    80005e62:	ffffb097          	auipc	ra,0xffffb
    80005e66:	d68080e7          	jalr	-664(ra) # 80000bca <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e6a:	100017b7          	lui	a5,0x10001
    80005e6e:	4398                	lw	a4,0(a5)
    80005e70:	2701                	sext.w	a4,a4
    80005e72:	747277b7          	lui	a5,0x74727
    80005e76:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e7a:	0ef71163          	bne	a4,a5,80005f5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e7e:	100017b7          	lui	a5,0x10001
    80005e82:	43dc                	lw	a5,4(a5)
    80005e84:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e86:	4705                	li	a4,1
    80005e88:	0ce79a63          	bne	a5,a4,80005f5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e8c:	100017b7          	lui	a5,0x10001
    80005e90:	479c                	lw	a5,8(a5)
    80005e92:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e94:	4709                	li	a4,2
    80005e96:	0ce79363          	bne	a5,a4,80005f5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e9a:	100017b7          	lui	a5,0x10001
    80005e9e:	47d8                	lw	a4,12(a5)
    80005ea0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ea2:	554d47b7          	lui	a5,0x554d4
    80005ea6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eaa:	0af71963          	bne	a4,a5,80005f5c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eae:	100017b7          	lui	a5,0x10001
    80005eb2:	4705                	li	a4,1
    80005eb4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eb6:	470d                	li	a4,3
    80005eb8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eba:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ebc:	c7ffe737          	lui	a4,0xc7ffe
    80005ec0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ec4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ec6:	2701                	sext.w	a4,a4
    80005ec8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eca:	472d                	li	a4,11
    80005ecc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ece:	473d                	li	a4,15
    80005ed0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ed2:	6705                	lui	a4,0x1
    80005ed4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ed6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005eda:	5bdc                	lw	a5,52(a5)
    80005edc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ede:	c7d9                	beqz	a5,80005f6c <virtio_disk_init+0x124>
  if(max < NUM)
    80005ee0:	471d                	li	a4,7
    80005ee2:	08f77d63          	bgeu	a4,a5,80005f7c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ee6:	100014b7          	lui	s1,0x10001
    80005eea:	47a1                	li	a5,8
    80005eec:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005eee:	6609                	lui	a2,0x2
    80005ef0:	4581                	li	a1,0
    80005ef2:	0001d517          	auipc	a0,0x1d
    80005ef6:	10e50513          	addi	a0,a0,270 # 80023000 <disk>
    80005efa:	ffffb097          	auipc	ra,0xffffb
    80005efe:	e5c080e7          	jalr	-420(ra) # 80000d56 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f02:	0001d717          	auipc	a4,0x1d
    80005f06:	0fe70713          	addi	a4,a4,254 # 80023000 <disk>
    80005f0a:	00c75793          	srli	a5,a4,0xc
    80005f0e:	2781                	sext.w	a5,a5
    80005f10:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005f12:	0001f797          	auipc	a5,0x1f
    80005f16:	0ee78793          	addi	a5,a5,238 # 80025000 <disk+0x2000>
    80005f1a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005f1c:	0001d717          	auipc	a4,0x1d
    80005f20:	16470713          	addi	a4,a4,356 # 80023080 <disk+0x80>
    80005f24:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f26:	0001e717          	auipc	a4,0x1e
    80005f2a:	0da70713          	addi	a4,a4,218 # 80024000 <disk+0x1000>
    80005f2e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f30:	4705                	li	a4,1
    80005f32:	00e78c23          	sb	a4,24(a5)
    80005f36:	00e78ca3          	sb	a4,25(a5)
    80005f3a:	00e78d23          	sb	a4,26(a5)
    80005f3e:	00e78da3          	sb	a4,27(a5)
    80005f42:	00e78e23          	sb	a4,28(a5)
    80005f46:	00e78ea3          	sb	a4,29(a5)
    80005f4a:	00e78f23          	sb	a4,30(a5)
    80005f4e:	00e78fa3          	sb	a4,31(a5)
}
    80005f52:	60e2                	ld	ra,24(sp)
    80005f54:	6442                	ld	s0,16(sp)
    80005f56:	64a2                	ld	s1,8(sp)
    80005f58:	6105                	addi	sp,sp,32
    80005f5a:	8082                	ret
    panic("could not find virtio disk");
    80005f5c:	00003517          	auipc	a0,0x3
    80005f60:	9cc50513          	addi	a0,a0,-1588 # 80008928 <syscallnumber_to_name+0x378>
    80005f64:	ffffa097          	auipc	ra,0xffffa
    80005f68:	5e4080e7          	jalr	1508(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005f6c:	00003517          	auipc	a0,0x3
    80005f70:	9dc50513          	addi	a0,a0,-1572 # 80008948 <syscallnumber_to_name+0x398>
    80005f74:	ffffa097          	auipc	ra,0xffffa
    80005f78:	5d4080e7          	jalr	1492(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005f7c:	00003517          	auipc	a0,0x3
    80005f80:	9ec50513          	addi	a0,a0,-1556 # 80008968 <syscallnumber_to_name+0x3b8>
    80005f84:	ffffa097          	auipc	ra,0xffffa
    80005f88:	5c4080e7          	jalr	1476(ra) # 80000548 <panic>

0000000080005f8c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f8c:	7119                	addi	sp,sp,-128
    80005f8e:	fc86                	sd	ra,120(sp)
    80005f90:	f8a2                	sd	s0,112(sp)
    80005f92:	f4a6                	sd	s1,104(sp)
    80005f94:	f0ca                	sd	s2,96(sp)
    80005f96:	ecce                	sd	s3,88(sp)
    80005f98:	e8d2                	sd	s4,80(sp)
    80005f9a:	e4d6                	sd	s5,72(sp)
    80005f9c:	e0da                	sd	s6,64(sp)
    80005f9e:	fc5e                	sd	s7,56(sp)
    80005fa0:	f862                	sd	s8,48(sp)
    80005fa2:	f466                	sd	s9,40(sp)
    80005fa4:	f06a                	sd	s10,32(sp)
    80005fa6:	0100                	addi	s0,sp,128
    80005fa8:	892a                	mv	s2,a0
    80005faa:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fac:	00c52c83          	lw	s9,12(a0)
    80005fb0:	001c9c9b          	slliw	s9,s9,0x1
    80005fb4:	1c82                	slli	s9,s9,0x20
    80005fb6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fba:	0001f517          	auipc	a0,0x1f
    80005fbe:	0ee50513          	addi	a0,a0,238 # 800250a8 <disk+0x20a8>
    80005fc2:	ffffb097          	auipc	ra,0xffffb
    80005fc6:	c98080e7          	jalr	-872(ra) # 80000c5a <acquire>
  for(int i = 0; i < 3; i++){
    80005fca:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fcc:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fce:	0001db97          	auipc	s7,0x1d
    80005fd2:	032b8b93          	addi	s7,s7,50 # 80023000 <disk>
    80005fd6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005fd8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005fda:	8a4e                	mv	s4,s3
    80005fdc:	a051                	j	80006060 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005fde:	00fb86b3          	add	a3,s7,a5
    80005fe2:	96da                	add	a3,a3,s6
    80005fe4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fe8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005fea:	0207c563          	bltz	a5,80006014 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fee:	2485                	addiw	s1,s1,1
    80005ff0:	0711                	addi	a4,a4,4
    80005ff2:	23548d63          	beq	s1,s5,8000622c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005ff6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005ff8:	0001f697          	auipc	a3,0x1f
    80005ffc:	02068693          	addi	a3,a3,32 # 80025018 <disk+0x2018>
    80006000:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006002:	0006c583          	lbu	a1,0(a3)
    80006006:	fde1                	bnez	a1,80005fde <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006008:	2785                	addiw	a5,a5,1
    8000600a:	0685                	addi	a3,a3,1
    8000600c:	ff879be3          	bne	a5,s8,80006002 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006010:	57fd                	li	a5,-1
    80006012:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006014:	02905a63          	blez	s1,80006048 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006018:	f9042503          	lw	a0,-112(s0)
    8000601c:	00000097          	auipc	ra,0x0
    80006020:	daa080e7          	jalr	-598(ra) # 80005dc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006024:	4785                	li	a5,1
    80006026:	0297d163          	bge	a5,s1,80006048 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000602a:	f9442503          	lw	a0,-108(s0)
    8000602e:	00000097          	auipc	ra,0x0
    80006032:	d98080e7          	jalr	-616(ra) # 80005dc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006036:	4789                	li	a5,2
    80006038:	0097d863          	bge	a5,s1,80006048 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000603c:	f9842503          	lw	a0,-104(s0)
    80006040:	00000097          	auipc	ra,0x0
    80006044:	d86080e7          	jalr	-634(ra) # 80005dc6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006048:	0001f597          	auipc	a1,0x1f
    8000604c:	06058593          	addi	a1,a1,96 # 800250a8 <disk+0x20a8>
    80006050:	0001f517          	auipc	a0,0x1f
    80006054:	fc850513          	addi	a0,a0,-56 # 80025018 <disk+0x2018>
    80006058:	ffffc097          	auipc	ra,0xffffc
    8000605c:	1e8080e7          	jalr	488(ra) # 80002240 <sleep>
  for(int i = 0; i < 3; i++){
    80006060:	f9040713          	addi	a4,s0,-112
    80006064:	84ce                	mv	s1,s3
    80006066:	bf41                	j	80005ff6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006068:	4785                	li	a5,1
    8000606a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000606e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006072:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006076:	f9042983          	lw	s3,-112(s0)
    8000607a:	00499493          	slli	s1,s3,0x4
    8000607e:	0001fa17          	auipc	s4,0x1f
    80006082:	f82a0a13          	addi	s4,s4,-126 # 80025000 <disk+0x2000>
    80006086:	000a3a83          	ld	s5,0(s4)
    8000608a:	9aa6                	add	s5,s5,s1
    8000608c:	f8040513          	addi	a0,s0,-128
    80006090:	ffffb097          	auipc	ra,0xffffb
    80006094:	09a080e7          	jalr	154(ra) # 8000112a <kvmpa>
    80006098:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000609c:	000a3783          	ld	a5,0(s4)
    800060a0:	97a6                	add	a5,a5,s1
    800060a2:	4741                	li	a4,16
    800060a4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060a6:	000a3783          	ld	a5,0(s4)
    800060aa:	97a6                	add	a5,a5,s1
    800060ac:	4705                	li	a4,1
    800060ae:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800060b2:	f9442703          	lw	a4,-108(s0)
    800060b6:	000a3783          	ld	a5,0(s4)
    800060ba:	97a6                	add	a5,a5,s1
    800060bc:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060c0:	0712                	slli	a4,a4,0x4
    800060c2:	000a3783          	ld	a5,0(s4)
    800060c6:	97ba                	add	a5,a5,a4
    800060c8:	05890693          	addi	a3,s2,88
    800060cc:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800060ce:	000a3783          	ld	a5,0(s4)
    800060d2:	97ba                	add	a5,a5,a4
    800060d4:	40000693          	li	a3,1024
    800060d8:	c794                	sw	a3,8(a5)
  if(write)
    800060da:	100d0a63          	beqz	s10,800061ee <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060de:	0001f797          	auipc	a5,0x1f
    800060e2:	f227b783          	ld	a5,-222(a5) # 80025000 <disk+0x2000>
    800060e6:	97ba                	add	a5,a5,a4
    800060e8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060ec:	0001d517          	auipc	a0,0x1d
    800060f0:	f1450513          	addi	a0,a0,-236 # 80023000 <disk>
    800060f4:	0001f797          	auipc	a5,0x1f
    800060f8:	f0c78793          	addi	a5,a5,-244 # 80025000 <disk+0x2000>
    800060fc:	6394                	ld	a3,0(a5)
    800060fe:	96ba                	add	a3,a3,a4
    80006100:	00c6d603          	lhu	a2,12(a3)
    80006104:	00166613          	ori	a2,a2,1
    80006108:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000610c:	f9842683          	lw	a3,-104(s0)
    80006110:	6390                	ld	a2,0(a5)
    80006112:	9732                	add	a4,a4,a2
    80006114:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006118:	20098613          	addi	a2,s3,512
    8000611c:	0612                	slli	a2,a2,0x4
    8000611e:	962a                	add	a2,a2,a0
    80006120:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006124:	00469713          	slli	a4,a3,0x4
    80006128:	6394                	ld	a3,0(a5)
    8000612a:	96ba                	add	a3,a3,a4
    8000612c:	6589                	lui	a1,0x2
    8000612e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006132:	94ae                	add	s1,s1,a1
    80006134:	94aa                	add	s1,s1,a0
    80006136:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006138:	6394                	ld	a3,0(a5)
    8000613a:	96ba                	add	a3,a3,a4
    8000613c:	4585                	li	a1,1
    8000613e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006140:	6394                	ld	a3,0(a5)
    80006142:	96ba                	add	a3,a3,a4
    80006144:	4509                	li	a0,2
    80006146:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000614a:	6394                	ld	a3,0(a5)
    8000614c:	9736                	add	a4,a4,a3
    8000614e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006152:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006156:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000615a:	6794                	ld	a3,8(a5)
    8000615c:	0026d703          	lhu	a4,2(a3)
    80006160:	8b1d                	andi	a4,a4,7
    80006162:	2709                	addiw	a4,a4,2
    80006164:	0706                	slli	a4,a4,0x1
    80006166:	9736                	add	a4,a4,a3
    80006168:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000616c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006170:	6798                	ld	a4,8(a5)
    80006172:	00275783          	lhu	a5,2(a4)
    80006176:	2785                	addiw	a5,a5,1
    80006178:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000617c:	100017b7          	lui	a5,0x10001
    80006180:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006184:	00492703          	lw	a4,4(s2)
    80006188:	4785                	li	a5,1
    8000618a:	02f71163          	bne	a4,a5,800061ac <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000618e:	0001f997          	auipc	s3,0x1f
    80006192:	f1a98993          	addi	s3,s3,-230 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006196:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006198:	85ce                	mv	a1,s3
    8000619a:	854a                	mv	a0,s2
    8000619c:	ffffc097          	auipc	ra,0xffffc
    800061a0:	0a4080e7          	jalr	164(ra) # 80002240 <sleep>
  while(b->disk == 1) {
    800061a4:	00492783          	lw	a5,4(s2)
    800061a8:	fe9788e3          	beq	a5,s1,80006198 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800061ac:	f9042483          	lw	s1,-112(s0)
    800061b0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800061b4:	00479713          	slli	a4,a5,0x4
    800061b8:	0001d797          	auipc	a5,0x1d
    800061bc:	e4878793          	addi	a5,a5,-440 # 80023000 <disk>
    800061c0:	97ba                	add	a5,a5,a4
    800061c2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061c6:	0001f917          	auipc	s2,0x1f
    800061ca:	e3a90913          	addi	s2,s2,-454 # 80025000 <disk+0x2000>
    free_desc(i);
    800061ce:	8526                	mv	a0,s1
    800061d0:	00000097          	auipc	ra,0x0
    800061d4:	bf6080e7          	jalr	-1034(ra) # 80005dc6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061d8:	0492                	slli	s1,s1,0x4
    800061da:	00093783          	ld	a5,0(s2)
    800061de:	94be                	add	s1,s1,a5
    800061e0:	00c4d783          	lhu	a5,12(s1)
    800061e4:	8b85                	andi	a5,a5,1
    800061e6:	cf89                	beqz	a5,80006200 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800061e8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800061ec:	b7cd                	j	800061ce <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061ee:	0001f797          	auipc	a5,0x1f
    800061f2:	e127b783          	ld	a5,-494(a5) # 80025000 <disk+0x2000>
    800061f6:	97ba                	add	a5,a5,a4
    800061f8:	4689                	li	a3,2
    800061fa:	00d79623          	sh	a3,12(a5)
    800061fe:	b5fd                	j	800060ec <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006200:	0001f517          	auipc	a0,0x1f
    80006204:	ea850513          	addi	a0,a0,-344 # 800250a8 <disk+0x20a8>
    80006208:	ffffb097          	auipc	ra,0xffffb
    8000620c:	b06080e7          	jalr	-1274(ra) # 80000d0e <release>
}
    80006210:	70e6                	ld	ra,120(sp)
    80006212:	7446                	ld	s0,112(sp)
    80006214:	74a6                	ld	s1,104(sp)
    80006216:	7906                	ld	s2,96(sp)
    80006218:	69e6                	ld	s3,88(sp)
    8000621a:	6a46                	ld	s4,80(sp)
    8000621c:	6aa6                	ld	s5,72(sp)
    8000621e:	6b06                	ld	s6,64(sp)
    80006220:	7be2                	ld	s7,56(sp)
    80006222:	7c42                	ld	s8,48(sp)
    80006224:	7ca2                	ld	s9,40(sp)
    80006226:	7d02                	ld	s10,32(sp)
    80006228:	6109                	addi	sp,sp,128
    8000622a:	8082                	ret
  if(write)
    8000622c:	e20d1ee3          	bnez	s10,80006068 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006230:	f8042023          	sw	zero,-128(s0)
    80006234:	bd2d                	j	8000606e <virtio_disk_rw+0xe2>

0000000080006236 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006236:	1101                	addi	sp,sp,-32
    80006238:	ec06                	sd	ra,24(sp)
    8000623a:	e822                	sd	s0,16(sp)
    8000623c:	e426                	sd	s1,8(sp)
    8000623e:	e04a                	sd	s2,0(sp)
    80006240:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006242:	0001f517          	auipc	a0,0x1f
    80006246:	e6650513          	addi	a0,a0,-410 # 800250a8 <disk+0x20a8>
    8000624a:	ffffb097          	auipc	ra,0xffffb
    8000624e:	a10080e7          	jalr	-1520(ra) # 80000c5a <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006252:	0001f717          	auipc	a4,0x1f
    80006256:	dae70713          	addi	a4,a4,-594 # 80025000 <disk+0x2000>
    8000625a:	02075783          	lhu	a5,32(a4)
    8000625e:	6b18                	ld	a4,16(a4)
    80006260:	00275683          	lhu	a3,2(a4)
    80006264:	8ebd                	xor	a3,a3,a5
    80006266:	8a9d                	andi	a3,a3,7
    80006268:	cab9                	beqz	a3,800062be <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000626a:	0001d917          	auipc	s2,0x1d
    8000626e:	d9690913          	addi	s2,s2,-618 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006272:	0001f497          	auipc	s1,0x1f
    80006276:	d8e48493          	addi	s1,s1,-626 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000627a:	078e                	slli	a5,a5,0x3
    8000627c:	97ba                	add	a5,a5,a4
    8000627e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006280:	20078713          	addi	a4,a5,512
    80006284:	0712                	slli	a4,a4,0x4
    80006286:	974a                	add	a4,a4,s2
    80006288:	03074703          	lbu	a4,48(a4)
    8000628c:	ef21                	bnez	a4,800062e4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000628e:	20078793          	addi	a5,a5,512
    80006292:	0792                	slli	a5,a5,0x4
    80006294:	97ca                	add	a5,a5,s2
    80006296:	7798                	ld	a4,40(a5)
    80006298:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000629c:	7788                	ld	a0,40(a5)
    8000629e:	ffffc097          	auipc	ra,0xffffc
    800062a2:	128080e7          	jalr	296(ra) # 800023c6 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062a6:	0204d783          	lhu	a5,32(s1)
    800062aa:	2785                	addiw	a5,a5,1
    800062ac:	8b9d                	andi	a5,a5,7
    800062ae:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062b2:	6898                	ld	a4,16(s1)
    800062b4:	00275683          	lhu	a3,2(a4)
    800062b8:	8a9d                	andi	a3,a3,7
    800062ba:	fcf690e3          	bne	a3,a5,8000627a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062be:	10001737          	lui	a4,0x10001
    800062c2:	533c                	lw	a5,96(a4)
    800062c4:	8b8d                	andi	a5,a5,3
    800062c6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800062c8:	0001f517          	auipc	a0,0x1f
    800062cc:	de050513          	addi	a0,a0,-544 # 800250a8 <disk+0x20a8>
    800062d0:	ffffb097          	auipc	ra,0xffffb
    800062d4:	a3e080e7          	jalr	-1474(ra) # 80000d0e <release>
}
    800062d8:	60e2                	ld	ra,24(sp)
    800062da:	6442                	ld	s0,16(sp)
    800062dc:	64a2                	ld	s1,8(sp)
    800062de:	6902                	ld	s2,0(sp)
    800062e0:	6105                	addi	sp,sp,32
    800062e2:	8082                	ret
      panic("virtio_disk_intr status");
    800062e4:	00002517          	auipc	a0,0x2
    800062e8:	6a450513          	addi	a0,a0,1700 # 80008988 <syscallnumber_to_name+0x3d8>
    800062ec:	ffffa097          	auipc	ra,0xffffa
    800062f0:	25c080e7          	jalr	604(ra) # 80000548 <panic>

00000000800062f4 <sys_sysinfo>:



uint64
sys_sysinfo(void)
{
    800062f4:	1101                	addi	sp,sp,-32
    800062f6:	ec06                	sd	ra,24(sp)
    800062f8:	e822                	sd	s0,16(sp)
    800062fa:	1000                	addi	s0,sp,32
  uint64 addr;
  if(argaddr(0, &addr) < 0)
    800062fc:	fe840593          	addi	a1,s0,-24
    80006300:	4501                	li	a0,0
    80006302:	ffffd097          	auipc	ra,0xffffd
    80006306:	89e080e7          	jalr	-1890(ra) # 80002ba0 <argaddr>
    8000630a:	87aa                	mv	a5,a0
    return -1;
    8000630c:	557d                	li	a0,-1
  if(argaddr(0, &addr) < 0)
    8000630e:	0007c863          	bltz	a5,8000631e <sys_sysinfo+0x2a>
  
  return sysinfo((struct sysinfo *)addr);
    80006312:	fe843503          	ld	a0,-24(s0)
    80006316:	00000097          	auipc	ra,0x0
    8000631a:	010080e7          	jalr	16(ra) # 80006326 <sysinfo>
    8000631e:	60e2                	ld	ra,24(sp)
    80006320:	6442                	ld	s0,16(sp)
    80006322:	6105                	addi	sp,sp,32
    80006324:	8082                	ret

0000000080006326 <sysinfo>:
#include "defs.h"
#include "sysinfo.h"
#include "proc.h"

int
sysinfo(struct sysinfo * pinfo) {
    80006326:	7179                	addi	sp,sp,-48
    80006328:	f406                	sd	ra,40(sp)
    8000632a:	f022                	sd	s0,32(sp)
    8000632c:	ec26                	sd	s1,24(sp)
    8000632e:	1800                	addi	s0,sp,48
    80006330:	84aa                	mv	s1,a0
  struct  sysinfo sinfo;
  sinfo.nproc = get_used_processes_count();
    80006332:	ffffc097          	auipc	ra,0xffffc
    80006336:	306080e7          	jalr	774(ra) # 80002638 <get_used_processes_count>
    8000633a:	fca43c23          	sd	a0,-40(s0)
  sinfo.freemem = get_freememory_count();
    8000633e:	ffffb097          	auipc	ra,0xffffb
    80006342:	842080e7          	jalr	-1982(ra) # 80000b80 <get_freememory_count>
    80006346:	fca43823          	sd	a0,-48(s0)

  struct proc *p = myproc();
    8000634a:	ffffb097          	auipc	ra,0xffffb
    8000634e:	6de080e7          	jalr	1758(ra) # 80001a28 <myproc>
  if(copyout(p->pagetable, (uint64)pinfo, (char*)&sinfo, sizeof(sinfo)) < 0)
    80006352:	46c1                	li	a3,16
    80006354:	fd040613          	addi	a2,s0,-48
    80006358:	85a6                	mv	a1,s1
    8000635a:	6928                	ld	a0,80(a0)
    8000635c:	ffffb097          	auipc	ra,0xffffb
    80006360:	3c0080e7          	jalr	960(ra) # 8000171c <copyout>
    return -1;
  return 0;
    80006364:	41f5551b          	sraiw	a0,a0,0x1f
    80006368:	70a2                	ld	ra,40(sp)
    8000636a:	7402                	ld	s0,32(sp)
    8000636c:	64e2                	ld	s1,24(sp)
    8000636e:	6145                	addi	sp,sp,48
    80006370:	8082                	ret
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

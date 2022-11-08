
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00010117          	auipc	sp,0x10
    80000004:	89010113          	addi	sp,sp,-1904 # 8000f890 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	0000f717          	auipc	a4,0xf
    80000056:	6fe70713          	addi	a4,a4,1790 # 8000f750 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	49c78793          	addi	a5,a5,1180 # 80006500 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd2c17>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	91a080e7          	jalr	-1766(ra) # 80002a46 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00017517          	auipc	a0,0x17
    80000190:	70450513          	addi	a0,a0,1796 # 80017890 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00017497          	auipc	s1,0x17
    800001a0:	6f448493          	addi	s1,s1,1780 # 80017890 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00017917          	auipc	s2,0x17
    800001aa:	78290913          	addi	s2,s2,1922 # 80017928 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	968080e7          	jalr	-1688(ra) # 80001b2c <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	6c4080e7          	jalr	1732(ra) # 80002890 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	2b2080e7          	jalr	690(ra) # 8000248c <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	7da080e7          	jalr	2010(ra) # 800029f0 <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00017517          	auipc	a0,0x17
    8000022e:	66650513          	addi	a0,a0,1638 # 80017890 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00017517          	auipc	a0,0x17
    80000244:	65050513          	addi	a0,a0,1616 # 80017890 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00017717          	auipc	a4,0x17
    8000027c:	6af72823          	sw	a5,1712(a4) # 80017928 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00017517          	auipc	a0,0x17
    800002d6:	5be50513          	addi	a0,a0,1470 # 80017890 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	7a4080e7          	jalr	1956(ra) # 80002a9c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00017517          	auipc	a0,0x17
    80000304:	59050513          	addi	a0,a0,1424 # 80017890 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00017717          	auipc	a4,0x17
    80000328:	56c70713          	addi	a4,a4,1388 # 80017890 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00017797          	auipc	a5,0x17
    80000352:	54278793          	addi	a5,a5,1346 # 80017890 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00017797          	auipc	a5,0x17
    80000380:	5ac7a783          	lw	a5,1452(a5) # 80017928 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00017717          	auipc	a4,0x17
    80000394:	50070713          	addi	a4,a4,1280 # 80017890 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00017497          	auipc	s1,0x17
    800003a4:	4f048493          	addi	s1,s1,1264 # 80017890 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00017717          	auipc	a4,0x17
    800003e0:	4b470713          	addi	a4,a4,1204 # 80017890 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00017717          	auipc	a4,0x17
    800003f6:	52f72f23          	sw	a5,1342(a4) # 80017930 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00017797          	auipc	a5,0x17
    8000041c:	47878793          	addi	a5,a5,1144 # 80017890 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00017797          	auipc	a5,0x17
    80000440:	4ec7a823          	sw	a2,1264(a5) # 8001792c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00017517          	auipc	a0,0x17
    80000448:	4e450513          	addi	a0,a0,1252 # 80017928 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	1f4080e7          	jalr	500(ra) # 80002640 <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00017517          	auipc	a0,0x17
    8000046a:	42a50513          	addi	a0,a0,1066 # 80017890 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	0002a797          	auipc	a5,0x2a
    80000482:	5d278793          	addi	a5,a5,1490 # 8002aa50 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00017797          	auipc	a5,0x17
    80000554:	4007a023          	sw	zero,1024(a5) # 80017950 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	0000f717          	auipc	a4,0xf
    80000588:	18f72623          	sw	a5,396(a4) # 8000f710 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00017d97          	auipc	s11,0x17
    800005c4:	390dad83          	lw	s11,912(s11) # 80017950 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00017517          	auipc	a0,0x17
    80000602:	33a50513          	addi	a0,a0,826 # 80017938 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00017517          	auipc	a0,0x17
    80000766:	1d650513          	addi	a0,a0,470 # 80017938 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00017497          	auipc	s1,0x17
    80000782:	1ba48493          	addi	s1,s1,442 # 80017938 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00017517          	auipc	a0,0x17
    800007e2:	17a50513          	addi	a0,a0,378 # 80017958 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	0000f797          	auipc	a5,0xf
    8000080e:	f067a783          	lw	a5,-250(a5) # 8000f710 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	0000f717          	auipc	a4,0xf
    8000084a:	ed273703          	ld	a4,-302(a4) # 8000f718 <uart_tx_r>
    8000084e:	0000f797          	auipc	a5,0xf
    80000852:	ed27b783          	ld	a5,-302(a5) # 8000f720 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00017a17          	auipc	s4,0x17
    80000874:	0e8a0a13          	addi	s4,s4,232 # 80017958 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	0000f497          	auipc	s1,0xf
    8000087c:	ea048493          	addi	s1,s1,-352 # 8000f718 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	0000f997          	auipc	s3,0xf
    80000884:	ea098993          	addi	s3,s3,-352 # 8000f720 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	d9a080e7          	jalr	-614(ra) # 80002640 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00017517          	auipc	a0,0x17
    800008e6:	07650513          	addi	a0,a0,118 # 80017958 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	0000f797          	auipc	a5,0xf
    800008f6:	e1e7a783          	lw	a5,-482(a5) # 8000f710 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	0000f797          	auipc	a5,0xf
    80000900:	e247b783          	ld	a5,-476(a5) # 8000f720 <uart_tx_w>
    80000904:	0000f717          	auipc	a4,0xf
    80000908:	e1473703          	ld	a4,-492(a4) # 8000f718 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00017a17          	auipc	s4,0x17
    80000914:	048a0a13          	addi	s4,s4,72 # 80017958 <uart_tx_lock>
    80000918:	0000f497          	auipc	s1,0xf
    8000091c:	e0048493          	addi	s1,s1,-512 # 8000f718 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	0000f917          	auipc	s2,0xf
    80000924:	e0090913          	addi	s2,s2,-512 # 8000f720 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	b5c080e7          	jalr	-1188(ra) # 8000248c <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00017497          	auipc	s1,0x17
    8000094a:	01248493          	addi	s1,s1,18 # 80017958 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	0000f717          	auipc	a4,0xf
    8000095e:	dcf73323          	sd	a5,-570(a4) # 8000f720 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00017497          	auipc	s1,0x17
    800009d4:	f8848493          	addi	s1,s1,-120 # 80017958 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	0002b797          	auipc	a5,0x2b
    80000a16:	1d678793          	addi	a5,a5,470 # 8002bbe8 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00017917          	auipc	s2,0x17
    80000a36:	f5e90913          	addi	s2,s2,-162 # 80017990 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00017517          	auipc	a0,0x17
    80000ad2:	ec250513          	addi	a0,a0,-318 # 80017990 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	0002b517          	auipc	a0,0x2b
    80000ae6:	10650513          	addi	a0,a0,262 # 8002bbe8 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00017497          	auipc	s1,0x17
    80000b08:	e8c48493          	addi	s1,s1,-372 # 80017990 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00017517          	auipc	a0,0x17
    80000b20:	e7450513          	addi	a0,a0,-396 # 80017990 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00017517          	auipc	a0,0x17
    80000b4c:	e4850513          	addi	a0,a0,-440 # 80017990 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	f5a080e7          	jalr	-166(ra) # 80001b10 <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	f4e080e7          	jalr	-178(ra) # 80001b10 <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	f36080e7          	jalr	-202(ra) # 80001b10 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	ef6080e7          	jalr	-266(ra) # 80001b10 <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	eca080e7          	jalr	-310(ra) # 80001b10 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	c64080e7          	jalr	-924(ra) # 80001b00 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	0000f717          	auipc	a4,0xf
    80000ea8:	88470713          	addi	a4,a4,-1916 # 8000f728 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	c48080e7          	jalr	-952(ra) # 80001b00 <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00002097          	auipc	ra,0x2
    80000ede:	d02080e7          	jalr	-766(ra) # 80002bdc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	65e080e7          	jalr	1630(ra) # 80006540 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	1fe080e7          	jalr	510(ra) # 800020e8 <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	326080e7          	jalr	806(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	068080e7          	jalr	104(ra) # 80000faa <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	ada080e7          	jalr	-1318(ra) # 80001a24 <procinit>
    trapinit();      // trap vectors
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	c62080e7          	jalr	-926(ra) # 80002bb4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	c82080e7          	jalr	-894(ra) # 80002bdc <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	5c8080e7          	jalr	1480(ra) # 8000652a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	5d6080e7          	jalr	1494(ra) # 80006540 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	784080e7          	jalr	1924(ra) # 800036f6 <binit>
    iinit();         // inode table
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	e28080e7          	jalr	-472(ra) # 80003da2 <iinit>
    fileinit();      // file table
    80000f82:	00004097          	auipc	ra,0x4
    80000f86:	dc6080e7          	jalr	-570(ra) # 80004d48 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	6be080e7          	jalr	1726(ra) # 80006648 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	ec8080e7          	jalr	-312(ra) # 80001e5a <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	0000e717          	auipc	a4,0xe
    80000fa4:	78f72423          	sw	a5,1928(a4) # 8000f728 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	0000e797          	auipc	a5,0xe
    80000fb8:	77c7b783          	ld	a5,1916(a5) # 8000f730 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d850513          	addi	a0,a0,216 # 800080d0 <digits+0x90>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	aee080e7          	jalr	-1298(ra) # 80000afa <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cca080e7          	jalr	-822(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
    return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ba:	715d                	addi	sp,sp,-80
    800010bc:	e486                	sd	ra,72(sp)
    800010be:	e0a2                	sd	s0,64(sp)
    800010c0:	fc26                	sd	s1,56(sp)
    800010c2:	f84a                	sd	s2,48(sp)
    800010c4:	f44e                	sd	s3,40(sp)
    800010c6:	f052                	sd	s4,32(sp)
    800010c8:	ec56                	sd	s5,24(sp)
    800010ca:	e85a                	sd	s6,16(sp)
    800010cc:	e45e                	sd	s7,8(sp)
    800010ce:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d0:	c205                	beqz	a2,800010f0 <mappages+0x36>
    800010d2:	8aaa                	mv	s5,a0
    800010d4:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d6:	77fd                	lui	a5,0xfffff
    800010d8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010dc:	15fd                	addi	a1,a1,-1
    800010de:	00c589b3          	add	s3,a1,a2
    800010e2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e6:	8952                	mv	s2,s4
    800010e8:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ec:	6b85                	lui	s7,0x1
    800010ee:	a015                	j	80001112 <mappages+0x58>
    panic("mappages: size");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	44c080e7          	jalr	1100(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	fe850513          	addi	a0,a0,-24 # 800080e8 <digits+0xa8>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	43c080e7          	jalr	1084(ra) # 80000544 <panic>
    a += PGSIZE;
    80001110:	995e                	add	s2,s2,s7
  for(;;){
    80001112:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001116:	4605                	li	a2,1
    80001118:	85ca                	mv	a1,s2
    8000111a:	8556                	mv	a0,s5
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	eb6080e7          	jalr	-330(ra) # 80000fd2 <walk>
    80001124:	cd19                	beqz	a0,80001142 <mappages+0x88>
    if(*pte & PTE_V)
    80001126:	611c                	ld	a5,0(a0)
    80001128:	8b85                	andi	a5,a5,1
    8000112a:	fbf9                	bnez	a5,80001100 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112c:	80b1                	srli	s1,s1,0xc
    8000112e:	04aa                	slli	s1,s1,0xa
    80001130:	0164e4b3          	or	s1,s1,s6
    80001134:	0014e493          	ori	s1,s1,1
    80001138:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113a:	fd391be3          	bne	s2,s3,80001110 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113e:	4501                	li	a0,0
    80001140:	a011                	j	80001144 <mappages+0x8a>
      return -1;
    80001142:	557d                	li	a0,-1
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret

000000008000115a <kvmmap>:
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
    80001162:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001164:	86b2                	mv	a3,a2
    80001166:	863e                	mv	a2,a5
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	f52080e7          	jalr	-174(ra) # 800010ba <mappages>
    80001170:	e509                	bnez	a0,8000117a <kvmmap+0x20>
}
    80001172:	60a2                	ld	ra,8(sp)
    80001174:	6402                	ld	s0,0(sp)
    80001176:	0141                	addi	sp,sp,16
    80001178:	8082                	ret
    panic("kvmmap");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f7e50513          	addi	a0,a0,-130 # 800080f8 <digits+0xb8>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c2080e7          	jalr	962(ra) # 80000544 <panic>

000000008000118a <kvmmake>:
{
    8000118a:	1101                	addi	sp,sp,-32
    8000118c:	ec06                	sd	ra,24(sp)
    8000118e:	e822                	sd	s0,16(sp)
    80001190:	e426                	sd	s1,8(sp)
    80001192:	e04a                	sd	s2,0(sp)
    80001194:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	964080e7          	jalr	-1692(ra) # 80000afa <kalloc>
    8000119e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a0:	6605                	lui	a2,0x1
    800011a2:	4581                	li	a1,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	b42080e7          	jalr	-1214(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ac:	4719                	li	a4,6
    800011ae:	6685                	lui	a3,0x1
    800011b0:	10000637          	lui	a2,0x10000
    800011b4:	100005b7          	lui	a1,0x10000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	fa0080e7          	jalr	-96(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c2:	4719                	li	a4,6
    800011c4:	6685                	lui	a3,0x1
    800011c6:	10001637          	lui	a2,0x10001
    800011ca:	100015b7          	lui	a1,0x10001
    800011ce:	8526                	mv	a0,s1
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	f8a080e7          	jalr	-118(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	004006b7          	lui	a3,0x400
    800011de:	0c000637          	lui	a2,0xc000
    800011e2:	0c0005b7          	lui	a1,0xc000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f72080e7          	jalr	-142(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f0:	00007917          	auipc	s2,0x7
    800011f4:	e1090913          	addi	s2,s2,-496 # 80008000 <etext>
    800011f8:	4729                	li	a4,10
    800011fa:	80007697          	auipc	a3,0x80007
    800011fe:	e0668693          	addi	a3,a3,-506 # 8000 <_entry-0x7fff8000>
    80001202:	4605                	li	a2,1
    80001204:	067e                	slli	a2,a2,0x1f
    80001206:	85b2                	mv	a1,a2
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f50080e7          	jalr	-176(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001212:	4719                	li	a4,6
    80001214:	46c5                	li	a3,17
    80001216:	06ee                	slli	a3,a3,0x1b
    80001218:	412686b3          	sub	a3,a3,s2
    8000121c:	864a                	mv	a2,s2
    8000121e:	85ca                	mv	a1,s2
    80001220:	8526                	mv	a0,s1
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f38080e7          	jalr	-200(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122a:	4729                	li	a4,10
    8000122c:	6685                	lui	a3,0x1
    8000122e:	00006617          	auipc	a2,0x6
    80001232:	dd260613          	addi	a2,a2,-558 # 80007000 <_trampoline>
    80001236:	040005b7          	lui	a1,0x4000
    8000123a:	15fd                	addi	a1,a1,-1
    8000123c:	05b2                	slli	a1,a1,0xc
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f1a080e7          	jalr	-230(ra) # 8000115a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	758080e7          	jalr	1880(ra) # 800019a2 <proc_mapstacks>
}
    80001252:	8526                	mv	a0,s1
    80001254:	60e2                	ld	ra,24(sp)
    80001256:	6442                	ld	s0,16(sp)
    80001258:	64a2                	ld	s1,8(sp)
    8000125a:	6902                	ld	s2,0(sp)
    8000125c:	6105                	addi	sp,sp,32
    8000125e:	8082                	ret

0000000080001260 <kvminit>:
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e406                	sd	ra,8(sp)
    80001264:	e022                	sd	s0,0(sp)
    80001266:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f22080e7          	jalr	-222(ra) # 8000118a <kvmmake>
    80001270:	0000e797          	auipc	a5,0xe
    80001274:	4ca7b023          	sd	a0,1216(a5) # 8000f730 <kernel_pagetable>
}
    80001278:	60a2                	ld	ra,8(sp)
    8000127a:	6402                	ld	s0,0(sp)
    8000127c:	0141                	addi	sp,sp,16
    8000127e:	8082                	ret

0000000080001280 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001280:	715d                	addi	sp,sp,-80
    80001282:	e486                	sd	ra,72(sp)
    80001284:	e0a2                	sd	s0,64(sp)
    80001286:	fc26                	sd	s1,56(sp)
    80001288:	f84a                	sd	s2,48(sp)
    8000128a:	f44e                	sd	s3,40(sp)
    8000128c:	f052                	sd	s4,32(sp)
    8000128e:	ec56                	sd	s5,24(sp)
    80001290:	e85a                	sd	s6,16(sp)
    80001292:	e45e                	sd	s7,8(sp)
    80001294:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001296:	03459793          	slli	a5,a1,0x34
    8000129a:	e795                	bnez	a5,800012c6 <uvmunmap+0x46>
    8000129c:	8a2a                	mv	s4,a0
    8000129e:	892e                	mv	s2,a1
    800012a0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a2:	0632                	slli	a2,a2,0xc
    800012a4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012aa:	6b05                	lui	s6,0x1
    800012ac:	0735e863          	bltu	a1,s3,8000131c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	e3a50513          	addi	a0,a0,-454 # 80008100 <digits+0xc0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	276080e7          	jalr	630(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012d6:	00007517          	auipc	a0,0x7
    800012da:	e4250513          	addi	a0,a0,-446 # 80008118 <digits+0xd8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	266080e7          	jalr	614(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e4250513          	addi	a0,a0,-446 # 80008128 <digits+0xe8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	256080e7          	jalr	598(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e4a50513          	addi	a0,a0,-438 # 80008140 <digits+0x100>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	246080e7          	jalr	582(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001306:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	6f4080e7          	jalr	1780(ra) # 800009fe <kfree>
    *pte = 0;
    80001312:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001316:	995a                	add	s2,s2,s6
    80001318:	f9397ce3          	bgeu	s2,s3,800012b0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131c:	4601                	li	a2,0
    8000131e:	85ca                	mv	a1,s2
    80001320:	8552                	mv	a0,s4
    80001322:	00000097          	auipc	ra,0x0
    80001326:	cb0080e7          	jalr	-848(ra) # 80000fd2 <walk>
    8000132a:	84aa                	mv	s1,a0
    8000132c:	d54d                	beqz	a0,800012d6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132e:	6108                	ld	a0,0(a0)
    80001330:	00157793          	andi	a5,a0,1
    80001334:	dbcd                	beqz	a5,800012e6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001336:	3ff57793          	andi	a5,a0,1023
    8000133a:	fb778ee3          	beq	a5,s7,800012f6 <uvmunmap+0x76>
    if(do_free){
    8000133e:	fc0a8ae3          	beqz	s5,80001312 <uvmunmap+0x92>
    80001342:	b7d1                	j	80001306 <uvmunmap+0x86>

0000000080001344 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001344:	1101                	addi	sp,sp,-32
    80001346:	ec06                	sd	ra,24(sp)
    80001348:	e822                	sd	s0,16(sp)
    8000134a:	e426                	sd	s1,8(sp)
    8000134c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	7ac080e7          	jalr	1964(ra) # 80000afa <kalloc>
    80001356:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001358:	c519                	beqz	a0,80001366 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	988080e7          	jalr	-1656(ra) # 80000ce6 <memset>
  return pagetable;
}
    80001366:	8526                	mv	a0,s1
    80001368:	60e2                	ld	ra,24(sp)
    8000136a:	6442                	ld	s0,16(sp)
    8000136c:	64a2                	ld	s1,8(sp)
    8000136e:	6105                	addi	sp,sp,32
    80001370:	8082                	ret

0000000080001372 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001372:	7179                	addi	sp,sp,-48
    80001374:	f406                	sd	ra,40(sp)
    80001376:	f022                	sd	s0,32(sp)
    80001378:	ec26                	sd	s1,24(sp)
    8000137a:	e84a                	sd	s2,16(sp)
    8000137c:	e44e                	sd	s3,8(sp)
    8000137e:	e052                	sd	s4,0(sp)
    80001380:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001382:	6785                	lui	a5,0x1
    80001384:	04f67863          	bgeu	a2,a5,800013d4 <uvmfirst+0x62>
    80001388:	8a2a                	mv	s4,a0
    8000138a:	89ae                	mv	s3,a1
    8000138c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	76c080e7          	jalr	1900(ra) # 80000afa <kalloc>
    80001396:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001398:	6605                	lui	a2,0x1
    8000139a:	4581                	li	a1,0
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	94a080e7          	jalr	-1718(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a4:	4779                	li	a4,30
    800013a6:	86ca                	mv	a3,s2
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	8552                	mv	a0,s4
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	d0c080e7          	jalr	-756(ra) # 800010ba <mappages>
  memmove(mem, src, sz);
    800013b6:	8626                	mv	a2,s1
    800013b8:	85ce                	mv	a1,s3
    800013ba:	854a                	mv	a0,s2
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	98a080e7          	jalr	-1654(ra) # 80000d46 <memmove>
}
    800013c4:	70a2                	ld	ra,40(sp)
    800013c6:	7402                	ld	s0,32(sp)
    800013c8:	64e2                	ld	s1,24(sp)
    800013ca:	6942                	ld	s2,16(sp)
    800013cc:	69a2                	ld	s3,8(sp)
    800013ce:	6a02                	ld	s4,0(sp)
    800013d0:	6145                	addi	sp,sp,48
    800013d2:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d4:	00007517          	auipc	a0,0x7
    800013d8:	d8450513          	addi	a0,a0,-636 # 80008158 <digits+0x118>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	168080e7          	jalr	360(ra) # 80000544 <panic>

00000000800013e4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ee:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f0:	00b67d63          	bgeu	a2,a1,8000140a <uvmdealloc+0x26>
    800013f4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f6:	6785                	lui	a5,0x1
    800013f8:	17fd                	addi	a5,a5,-1
    800013fa:	00f60733          	add	a4,a2,a5
    800013fe:	767d                	lui	a2,0xfffff
    80001400:	8f71                	and	a4,a4,a2
    80001402:	97ae                	add	a5,a5,a1
    80001404:	8ff1                	and	a5,a5,a2
    80001406:	00f76863          	bltu	a4,a5,80001416 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001416:	8f99                	sub	a5,a5,a4
    80001418:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141a:	4685                	li	a3,1
    8000141c:	0007861b          	sext.w	a2,a5
    80001420:	85ba                	mv	a1,a4
    80001422:	00000097          	auipc	ra,0x0
    80001426:	e5e080e7          	jalr	-418(ra) # 80001280 <uvmunmap>
    8000142a:	b7c5                	j	8000140a <uvmdealloc+0x26>

000000008000142c <uvmalloc>:
  if(newsz < oldsz)
    8000142c:	0ab66563          	bltu	a2,a1,800014d6 <uvmalloc+0xaa>
{
    80001430:	7139                	addi	sp,sp,-64
    80001432:	fc06                	sd	ra,56(sp)
    80001434:	f822                	sd	s0,48(sp)
    80001436:	f426                	sd	s1,40(sp)
    80001438:	f04a                	sd	s2,32(sp)
    8000143a:	ec4e                	sd	s3,24(sp)
    8000143c:	e852                	sd	s4,16(sp)
    8000143e:	e456                	sd	s5,8(sp)
    80001440:	e05a                	sd	s6,0(sp)
    80001442:	0080                	addi	s0,sp,64
    80001444:	8aaa                	mv	s5,a0
    80001446:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001448:	6985                	lui	s3,0x1
    8000144a:	19fd                	addi	s3,s3,-1
    8000144c:	95ce                	add	a1,a1,s3
    8000144e:	79fd                	lui	s3,0xfffff
    80001450:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001454:	08c9f363          	bgeu	s3,a2,800014da <uvmalloc+0xae>
    80001458:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	69c080e7          	jalr	1692(ra) # 80000afa <kalloc>
    80001466:	84aa                	mv	s1,a0
    if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	878080e7          	jalr	-1928(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001476:	875a                	mv	a4,s6
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c3a080e7          	jalr	-966(ra) # 800010ba <mappages>
    80001488:	e90d                	bnez	a0,800014ba <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x32>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f48080e7          	jalr	-184(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6b02                	ld	s6,0(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	542080e7          	jalr	1346(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f1a080e7          	jalr	-230(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfc9                	j	800014a6 <uvmalloc+0x7a>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7e9                	j	800014a6 <uvmalloc+0x7a>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	4985                	li	s3,1
    800014f8:	a821                	j	80001510 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fc:	0532                	slli	a0,a0,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fe0080e7          	jalr	-32(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001510:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f57793          	andi	a5,a0,15
    80001516:	ff3782e3          	beq	a5,s3,800014fa <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8905                	andi	a0,a0,1
    8000151c:	d57d                	beqz	a0,8000150a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c5a50513          	addi	a0,a0,-934 # 80008178 <digits+0x138>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	01e080e7          	jalr	30(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4ce080e7          	jalr	1230(ra) # 800009fe <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f86080e7          	jalr	-122(ra) # 800014de <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6605                	lui	a2,0x1
    8000156c:	167d                	addi	a2,a2,-1
    8000156e:	962e                	add	a2,a2,a1
    80001570:	4685                	li	a3,1
    80001572:	8231                	srli	a2,a2,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d0a080e7          	jalr	-758(ra) # 80001280 <uvmunmap>
    8000157e:	bfe1                	j	80001556 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a2c080e7          	jalr	-1492(ra) # 80000fd2 <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	536080e7          	jalr	1334(ra) # 80000afa <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	772080e7          	jalr	1906(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	ad4080e7          	jalr	-1324(ra) # 800010ba <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b8e50513          	addi	a0,a0,-1138 # 80008188 <digits+0x148>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f42080e7          	jalr	-190(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800081a8 <digits+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f32080e7          	jalr	-206(ra) # 80000544 <panic>
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c52080e7          	jalr	-942(ra) # 80001280 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	976080e7          	jalr	-1674(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b5450513          	addi	a0,a0,-1196 # 800081c8 <digits+0x188>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec8080e7          	jalr	-312(ra) # 80000544 <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	68e080e7          	jalr	1678(ra) # 80000d46 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9a2080e7          	jalr	-1630(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	c6bd                	beqz	a3,8000177e <copyin+0x6e>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a015                	j	8000175a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	9562                	add	a0,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412505b3          	sub	a1,a0,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	602080e7          	jalr	1538(ra) # 80000d46 <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	916080e7          	jalr	-1770(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if(n > len)
    80001772:	fc99f3e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	b7c1                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x74>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	884080e7          	jalr	-1916(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if(n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4)
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <queueesizee>:
Queuee fivequeues[5];

unsigned long long int randomq = 1;

int queueesizee(Queuee *q)
{
    80001850:	1141                	addi	sp,sp,-16
    80001852:	e422                	sd	s0,8(sp)
    80001854:	0800                	addi	s0,sp,16
  if (q->oneafterlast >= q->first)
    80001856:	415c                	lw	a5,4(a0)
    80001858:	4108                	lw	a0,0(a0)
    8000185a:	00a7c763          	blt	a5,a0,80001868 <queueesizee+0x18>
  {
    return q->oneafterlast - q->first;
    8000185e:	40a7853b          	subw	a0,a5,a0
  }
  else
  {
    return 64 - q->first + q->oneafterlast;
  }
}
    80001862:	6422                	ld	s0,8(sp)
    80001864:	0141                	addi	sp,sp,16
    80001866:	8082                	ret
    return 64 - q->first + q->oneafterlast;
    80001868:	9f89                	subw	a5,a5,a0
    8000186a:	0407851b          	addiw	a0,a5,64
    8000186e:	bfd5                	j	80001862 <queueesizee+0x12>

0000000080001870 <addtoq>:

void addtoq(Queuee *q, struct proc *currentproc)
{
    80001870:	1101                	addi	sp,sp,-32
    80001872:	ec06                	sd	ra,24(sp)
    80001874:	e822                	sd	s0,16(sp)
    80001876:	e426                	sd	s1,8(sp)
    80001878:	e04a                	sd	s2,0(sp)
    8000187a:	1000                	addi	s0,sp,32
    8000187c:	892a                	mv	s2,a0
    8000187e:	84ae                	mv	s1,a1
  if (queueesizee(q) == 64)
    80001880:	00000097          	auipc	ra,0x0
    80001884:	fd0080e7          	jalr	-48(ra) # 80001850 <queueesizee>
    80001888:	04000793          	li	a5,64
    8000188c:	04f50063          	beq	a0,a5,800018cc <addtoq+0x5c>
  {
    panic("Queue overflowing!");
  }
  q->allProcesses[q->oneafterlast] = currentproc;
    80001890:	00492783          	lw	a5,4(s2) # 1004 <_entry-0x7fffeffc>
    80001894:	00379713          	slli	a4,a5,0x3
    80001898:	974a                	add	a4,a4,s2
    8000189a:	e704                	sd	s1,8(a4)
  q->oneafterlast++;
    8000189c:	2785                	addiw	a5,a5,1
    8000189e:	0007869b          	sext.w	a3,a5
  if (q->oneafterlast == 64)
    800018a2:	04000713          	li	a4,64
    800018a6:	02e68b63          	beq	a3,a4,800018dc <addtoq+0x6c>
  q->oneafterlast++;
    800018aa:	00f92223          	sw	a5,4(s2)
    q->oneafterlast = 0;

  currentproc->ptimeqenter = ticks;
    800018ae:	0000e797          	auipc	a5,0xe
    800018b2:	e927e783          	lwu	a5,-366(a5) # 8000f740 <ticks>
    800018b6:	1af4bc23          	sd	a5,440(s1)
  currentproc->isthispinq = 1;
    800018ba:	4785                	li	a5,1
    800018bc:	1cf4b023          	sd	a5,448(s1)
}
    800018c0:	60e2                	ld	ra,24(sp)
    800018c2:	6442                	ld	s0,16(sp)
    800018c4:	64a2                	ld	s1,8(sp)
    800018c6:	6902                	ld	s2,0(sp)
    800018c8:	6105                	addi	sp,sp,32
    800018ca:	8082                	ret
    panic("Queue overflowing!");
    800018cc:	00007517          	auipc	a0,0x7
    800018d0:	90c50513          	addi	a0,a0,-1780 # 800081d8 <digits+0x198>
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	c70080e7          	jalr	-912(ra) # 80000544 <panic>
    q->oneafterlast = 0;
    800018dc:	00092223          	sw	zero,4(s2)
    800018e0:	b7f9                	j	800018ae <addtoq+0x3e>

00000000800018e2 <removeparticularfromq>:

void removeparticularfromq(Queuee *q, struct proc *p)
{
    800018e2:	1141                	addi	sp,sp,-16
    800018e4:	e422                	sd	s0,8(sp)
    800018e6:	0800                	addi	s0,sp,16
  int found = 0;
  int pidtoremove = p->pid;
    800018e8:	5994                	lw	a3,48(a1)
  for (int i = q->first; i != q->oneafterlast; i = (i + 1) % NPROC)
    800018ea:	411c                	lw	a5,0(a0)
    800018ec:	4150                	lw	a2,4(a0)
    800018ee:	02c79263          	bne	a5,a2,80001912 <removeparticularfromq+0x30>
      }
    }
    if (found == 1)
      break;
  }
  p->isthispinq = 0;
    800018f2:	1c05b023          	sd	zero,448(a1) # 40001c0 <_entry-0x7bfffe40>
    if (q->oneafterlast == -1)
    {
      q->oneafterlast = 63;
    }
  }
}
    800018f6:	6422                	ld	s0,8(sp)
    800018f8:	0141                	addi	sp,sp,16
    800018fa:	8082                	ret
  for (int i = q->first; i != q->oneafterlast; i = (i + 1) % NPROC)
    800018fc:	2785                	addiw	a5,a5,1
    800018fe:	41f7d71b          	sraiw	a4,a5,0x1f
    80001902:	01a7571b          	srliw	a4,a4,0x1a
    80001906:	9fb9                	addw	a5,a5,a4
    80001908:	03f7f793          	andi	a5,a5,63
    8000190c:	9f99                	subw	a5,a5,a4
    8000190e:	fec782e3          	beq	a5,a2,800018f2 <removeparticularfromq+0x10>
    if (q->allProcesses[i]->pid == pidtoremove)
    80001912:	00379713          	slli	a4,a5,0x3
    80001916:	972a                	add	a4,a4,a0
    80001918:	6718                	ld	a4,8(a4)
    8000191a:	5b18                	lw	a4,48(a4)
    8000191c:	fed710e3          	bne	a4,a3,800018fc <removeparticularfromq+0x1a>
      for (int j = i; j != q->oneafterlast - 1; j = (j + 1) % NPROC)
    80001920:	367d                	addiw	a2,a2,-1
    80001922:	02f60563          	beq	a2,a5,8000194c <removeparticularfromq+0x6a>
        q->allProcesses[j] = q->allProcesses[(j + 1) % NPROC];
    80001926:	873e                	mv	a4,a5
    80001928:	2785                	addiw	a5,a5,1
    8000192a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000192e:	01a6d69b          	srliw	a3,a3,0x1a
    80001932:	9fb5                	addw	a5,a5,a3
    80001934:	03f7f793          	andi	a5,a5,63
    80001938:	9f95                	subw	a5,a5,a3
    8000193a:	00379693          	slli	a3,a5,0x3
    8000193e:	96aa                	add	a3,a3,a0
    80001940:	6694                	ld	a3,8(a3)
    80001942:	070e                	slli	a4,a4,0x3
    80001944:	972a                	add	a4,a4,a0
    80001946:	e714                	sd	a3,8(a4)
      for (int j = i; j != q->oneafterlast - 1; j = (j + 1) % NPROC)
    80001948:	fcc79fe3          	bne	a5,a2,80001926 <removeparticularfromq+0x44>
  p->isthispinq = 0;
    8000194c:	1c05b023          	sd	zero,448(a1)
    q->oneafterlast--;
    80001950:	415c                	lw	a5,4(a0)
    80001952:	37fd                	addiw	a5,a5,-1
    80001954:	0007869b          	sext.w	a3,a5
    if (q->oneafterlast == -1)
    80001958:	577d                	li	a4,-1
    8000195a:	00e68463          	beq	a3,a4,80001962 <removeparticularfromq+0x80>
    q->oneafterlast--;
    8000195e:	c15c                	sw	a5,4(a0)
    80001960:	bf59                	j	800018f6 <removeparticularfromq+0x14>
      q->oneafterlast = 63;
    80001962:	03f00793          	li	a5,63
    80001966:	c15c                	sw	a5,4(a0)
}
    80001968:	b779                	j	800018f6 <removeparticularfromq+0x14>

000000008000196a <getrandomnumber>:

unsigned long long int getrandomnumber()
{
    8000196a:	1141                	addi	sp,sp,-16
    8000196c:	e422                	sd	s0,8(sp)
    8000196e:	0800                	addi	s0,sp,16
  randomq = ((randomq * 432581) + 83723) % 1000000007;
    80001970:	00007717          	auipc	a4,0x7
    80001974:	f8870713          	addi	a4,a4,-120 # 800088f8 <randomq>
    80001978:	6308                	ld	a0,0(a4)
    8000197a:	0006a7b7          	lui	a5,0x6a
    8000197e:	9c578793          	addi	a5,a5,-1595 # 699c5 <_entry-0x7ff9663b>
    80001982:	02f50533          	mul	a0,a0,a5
    80001986:	67d1                	lui	a5,0x14
    80001988:	70b78793          	addi	a5,a5,1803 # 1470b <_entry-0x7ffeb8f5>
    8000198c:	953e                	add	a0,a0,a5
    8000198e:	3b9ad7b7          	lui	a5,0x3b9ad
    80001992:	a0778793          	addi	a5,a5,-1529 # 3b9aca07 <_entry-0x446535f9>
    80001996:	02f57533          	remu	a0,a0,a5
    8000199a:	e308                	sd	a0,0(a4)
  return randomq;
}
    8000199c:	6422                	ld	s0,8(sp)
    8000199e:	0141                	addi	sp,sp,16
    800019a0:	8082                	ret

00000000800019a2 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    800019a2:	7139                	addi	sp,sp,-64
    800019a4:	fc06                	sd	ra,56(sp)
    800019a6:	f822                	sd	s0,48(sp)
    800019a8:	f426                	sd	s1,40(sp)
    800019aa:	f04a                	sd	s2,32(sp)
    800019ac:	ec4e                	sd	s3,24(sp)
    800019ae:	e852                	sd	s4,16(sp)
    800019b0:	e456                	sd	s5,8(sp)
    800019b2:	0080                	addi	s0,sp,64
    800019b4:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800019b6:	00017497          	auipc	s1,0x17
    800019ba:	e5248493          	addi	s1,s1,-430 # 80018808 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    800019be:	8a26                	mv	s4,s1
    800019c0:	04000937          	lui	s2,0x4000
    800019c4:	197d                	addi	s2,s2,-1
    800019c6:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800019c8:	0001fa97          	auipc	s5,0x1f
    800019cc:	e40a8a93          	addi	s5,s5,-448 # 80020808 <tickslock>
    char *pa = kalloc();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	12a080e7          	jalr	298(ra) # 80000afa <kalloc>
    800019d8:	862a                	mv	a2,a0
    if (pa == 0)
    800019da:	cd0d                	beqz	a0,80001a14 <proc_mapstacks+0x72>
    uint64 va = KSTACK((int)(p - proc));
    800019dc:	414485b3          	sub	a1,s1,s4
    800019e0:	85a5                	srai	a1,a1,0x9
    800019e2:	2585                	addiw	a1,a1,1
    800019e4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019e8:	4719                	li	a4,6
    800019ea:	6685                	lui	a3,0x1
    800019ec:	40b905b3          	sub	a1,s2,a1
    800019f0:	854e                	mv	a0,s3
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	768080e7          	jalr	1896(ra) # 8000115a <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800019fa:	20048493          	addi	s1,s1,512
    800019fe:	fd5499e3          	bne	s1,s5,800019d0 <proc_mapstacks+0x2e>
  }
}
    80001a02:	70e2                	ld	ra,56(sp)
    80001a04:	7442                	ld	s0,48(sp)
    80001a06:	74a2                	ld	s1,40(sp)
    80001a08:	7902                	ld	s2,32(sp)
    80001a0a:	69e2                	ld	s3,24(sp)
    80001a0c:	6a42                	ld	s4,16(sp)
    80001a0e:	6aa2                	ld	s5,8(sp)
    80001a10:	6121                	addi	sp,sp,64
    80001a12:	8082                	ret
      panic("kalloc");
    80001a14:	00006517          	auipc	a0,0x6
    80001a18:	7dc50513          	addi	a0,a0,2012 # 800081f0 <digits+0x1b0>
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	b28080e7          	jalr	-1240(ra) # 80000544 <panic>

0000000080001a24 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001a24:	7139                	addi	sp,sp,-64
    80001a26:	fc06                	sd	ra,56(sp)
    80001a28:	f822                	sd	s0,48(sp)
    80001a2a:	f426                	sd	s1,40(sp)
    80001a2c:	f04a                	sd	s2,32(sp)
    80001a2e:	ec4e                	sd	s3,24(sp)
    80001a30:	e852                	sd	s4,16(sp)
    80001a32:	e456                	sd	s5,8(sp)
    80001a34:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001a36:	00006597          	auipc	a1,0x6
    80001a3a:	7c258593          	addi	a1,a1,1986 # 800081f8 <digits+0x1b8>
    80001a3e:	00016517          	auipc	a0,0x16
    80001a42:	f7250513          	addi	a0,a0,-142 # 800179b0 <pid_lock>
    80001a46:	fffff097          	auipc	ra,0xfffff
    80001a4a:	114080e7          	jalr	276(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a4e:	00006597          	auipc	a1,0x6
    80001a52:	7b258593          	addi	a1,a1,1970 # 80008200 <digits+0x1c0>
    80001a56:	00016517          	auipc	a0,0x16
    80001a5a:	f7250513          	addi	a0,a0,-142 # 800179c8 <wait_lock>
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	0fc080e7          	jalr	252(ra) # 80000b5a <initlock>

  for (int i = 0; i < 5; i++)
  {
    fivequeues[i].first = fivequeues[i].oneafterlast = 0;
    80001a66:	00016797          	auipc	a5,0x16
    80001a6a:	37a78793          	addi	a5,a5,890 # 80017de0 <fivequeues>
    80001a6e:	0007a223          	sw	zero,4(a5)
    80001a72:	0007a023          	sw	zero,0(a5)
    80001a76:	2007a623          	sw	zero,524(a5)
    80001a7a:	2007a423          	sw	zero,520(a5)
    80001a7e:	4007aa23          	sw	zero,1044(a5)
    80001a82:	4007a823          	sw	zero,1040(a5)
    80001a86:	6007ae23          	sw	zero,1564(a5)
    80001a8a:	6007ac23          	sw	zero,1560(a5)
    80001a8e:	00017797          	auipc	a5,0x17
    80001a92:	35278793          	addi	a5,a5,850 # 80018de0 <proc+0x5d8>
    80001a96:	8207a223          	sw	zero,-2012(a5)
    80001a9a:	8207a023          	sw	zero,-2016(a5)
  }
  for (p = proc; p < &proc[NPROC]; p++)
    80001a9e:	00017497          	auipc	s1,0x17
    80001aa2:	d6a48493          	addi	s1,s1,-662 # 80018808 <proc>
  {
    initlock(&p->lock, "proc");
    80001aa6:	00006a17          	auipc	s4,0x6
    80001aaa:	76aa0a13          	addi	s4,s4,1898 # 80008210 <digits+0x1d0>
    p->state = UNUSED;
    p->masknumber = 0;
    p->kstack = KSTACK((int)(p - proc));
    80001aae:	89a6                	mv	s3,s1
    80001ab0:	04000937          	lui	s2,0x4000
    80001ab4:	197d                	addi	s2,s2,-1
    80001ab6:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001ab8:	0001fa97          	auipc	s5,0x1f
    80001abc:	d50a8a93          	addi	s5,s5,-688 # 80020808 <tickslock>
    initlock(&p->lock, "proc");
    80001ac0:	85d2                	mv	a1,s4
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	096080e7          	jalr	150(ra) # 80000b5a <initlock>
    p->state = UNUSED;
    80001acc:	0004ac23          	sw	zero,24(s1)
    p->masknumber = 0;
    80001ad0:	1604a423          	sw	zero,360(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001ad4:	413487b3          	sub	a5,s1,s3
    80001ad8:	87a5                	srai	a5,a5,0x9
    80001ada:	2785                	addiw	a5,a5,1
    80001adc:	00d7979b          	slliw	a5,a5,0xd
    80001ae0:	40f907b3          	sub	a5,s2,a5
    80001ae4:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001ae6:	20048493          	addi	s1,s1,512
    80001aea:	fd549be3          	bne	s1,s5,80001ac0 <procinit+0x9c>
  }
}
    80001aee:	70e2                	ld	ra,56(sp)
    80001af0:	7442                	ld	s0,48(sp)
    80001af2:	74a2                	ld	s1,40(sp)
    80001af4:	7902                	ld	s2,32(sp)
    80001af6:	69e2                	ld	s3,24(sp)
    80001af8:	6a42                	ld	s4,16(sp)
    80001afa:	6aa2                	ld	s5,8(sp)
    80001afc:	6121                	addi	sp,sp,64
    80001afe:	8082                	ret

0000000080001b00 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001b00:	1141                	addi	sp,sp,-16
    80001b02:	e422                	sd	s0,8(sp)
    80001b04:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b06:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b08:	2501                	sext.w	a0,a0
    80001b0a:	6422                	ld	s0,8(sp)
    80001b0c:	0141                	addi	sp,sp,16
    80001b0e:	8082                	ret

0000000080001b10 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001b10:	1141                	addi	sp,sp,-16
    80001b12:	e422                	sd	s0,8(sp)
    80001b14:	0800                	addi	s0,sp,16
    80001b16:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b18:	2781                	sext.w	a5,a5
    80001b1a:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b1c:	00016517          	auipc	a0,0x16
    80001b20:	ec450513          	addi	a0,a0,-316 # 800179e0 <cpus>
    80001b24:	953e                	add	a0,a0,a5
    80001b26:	6422                	ld	s0,8(sp)
    80001b28:	0141                	addi	sp,sp,16
    80001b2a:	8082                	ret

0000000080001b2c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001b2c:	1101                	addi	sp,sp,-32
    80001b2e:	ec06                	sd	ra,24(sp)
    80001b30:	e822                	sd	s0,16(sp)
    80001b32:	e426                	sd	s1,8(sp)
    80001b34:	1000                	addi	s0,sp,32
  push_off();
    80001b36:	fffff097          	auipc	ra,0xfffff
    80001b3a:	068080e7          	jalr	104(ra) # 80000b9e <push_off>
    80001b3e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b40:	2781                	sext.w	a5,a5
    80001b42:	079e                	slli	a5,a5,0x7
    80001b44:	00016717          	auipc	a4,0x16
    80001b48:	e6c70713          	addi	a4,a4,-404 # 800179b0 <pid_lock>
    80001b4c:	97ba                	add	a5,a5,a4
    80001b4e:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b50:	fffff097          	auipc	ra,0xfffff
    80001b54:	0ee080e7          	jalr	238(ra) # 80000c3e <pop_off>
  return p;
}
    80001b58:	8526                	mv	a0,s1
    80001b5a:	60e2                	ld	ra,24(sp)
    80001b5c:	6442                	ld	s0,16(sp)
    80001b5e:	64a2                	ld	s1,8(sp)
    80001b60:	6105                	addi	sp,sp,32
    80001b62:	8082                	ret

0000000080001b64 <forkret>:
// ************************

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001b64:	1141                	addi	sp,sp,-16
    80001b66:	e406                	sd	ra,8(sp)
    80001b68:	e022                	sd	s0,0(sp)
    80001b6a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b6c:	00000097          	auipc	ra,0x0
    80001b70:	fc0080e7          	jalr	-64(ra) # 80001b2c <myproc>
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	12a080e7          	jalr	298(ra) # 80000c9e <release>

  if (first)
    80001b7c:	00007797          	auipc	a5,0x7
    80001b80:	d747a783          	lw	a5,-652(a5) # 800088f0 <first.1820>
    80001b84:	eb89                	bnez	a5,80001b96 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b86:	00001097          	auipc	ra,0x1
    80001b8a:	06e080e7          	jalr	110(ra) # 80002bf4 <usertrapret>
}
    80001b8e:	60a2                	ld	ra,8(sp)
    80001b90:	6402                	ld	s0,0(sp)
    80001b92:	0141                	addi	sp,sp,16
    80001b94:	8082                	ret
    first = 0;
    80001b96:	00007797          	auipc	a5,0x7
    80001b9a:	d407ad23          	sw	zero,-678(a5) # 800088f0 <first.1820>
    fsinit(ROOTDEV);
    80001b9e:	4505                	li	a0,1
    80001ba0:	00002097          	auipc	ra,0x2
    80001ba4:	182080e7          	jalr	386(ra) # 80003d22 <fsinit>
    80001ba8:	bff9                	j	80001b86 <forkret+0x22>

0000000080001baa <allocpid>:
{
    80001baa:	1101                	addi	sp,sp,-32
    80001bac:	ec06                	sd	ra,24(sp)
    80001bae:	e822                	sd	s0,16(sp)
    80001bb0:	e426                	sd	s1,8(sp)
    80001bb2:	e04a                	sd	s2,0(sp)
    80001bb4:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001bb6:	00016917          	auipc	s2,0x16
    80001bba:	dfa90913          	addi	s2,s2,-518 # 800179b0 <pid_lock>
    80001bbe:	854a                	mv	a0,s2
    80001bc0:	fffff097          	auipc	ra,0xfffff
    80001bc4:	02a080e7          	jalr	42(ra) # 80000bea <acquire>
  pid = nextpid;
    80001bc8:	00007797          	auipc	a5,0x7
    80001bcc:	d2c78793          	addi	a5,a5,-724 # 800088f4 <nextpid>
    80001bd0:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bd2:	0014871b          	addiw	a4,s1,1
    80001bd6:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bd8:	854a                	mv	a0,s2
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	0c4080e7          	jalr	196(ra) # 80000c9e <release>
}
    80001be2:	8526                	mv	a0,s1
    80001be4:	60e2                	ld	ra,24(sp)
    80001be6:	6442                	ld	s0,16(sp)
    80001be8:	64a2                	ld	s1,8(sp)
    80001bea:	6902                	ld	s2,0(sp)
    80001bec:	6105                	addi	sp,sp,32
    80001bee:	8082                	ret

0000000080001bf0 <proc_pagetable>:
{
    80001bf0:	1101                	addi	sp,sp,-32
    80001bf2:	ec06                	sd	ra,24(sp)
    80001bf4:	e822                	sd	s0,16(sp)
    80001bf6:	e426                	sd	s1,8(sp)
    80001bf8:	e04a                	sd	s2,0(sp)
    80001bfa:	1000                	addi	s0,sp,32
    80001bfc:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	746080e7          	jalr	1862(ra) # 80001344 <uvmcreate>
    80001c06:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c08:	c121                	beqz	a0,80001c48 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c0a:	4729                	li	a4,10
    80001c0c:	00005697          	auipc	a3,0x5
    80001c10:	3f468693          	addi	a3,a3,1012 # 80007000 <_trampoline>
    80001c14:	6605                	lui	a2,0x1
    80001c16:	040005b7          	lui	a1,0x4000
    80001c1a:	15fd                	addi	a1,a1,-1
    80001c1c:	05b2                	slli	a1,a1,0xc
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	49c080e7          	jalr	1180(ra) # 800010ba <mappages>
    80001c26:	02054863          	bltz	a0,80001c56 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c2a:	4719                	li	a4,6
    80001c2c:	05893683          	ld	a3,88(s2)
    80001c30:	6605                	lui	a2,0x1
    80001c32:	020005b7          	lui	a1,0x2000
    80001c36:	15fd                	addi	a1,a1,-1
    80001c38:	05b6                	slli	a1,a1,0xd
    80001c3a:	8526                	mv	a0,s1
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	47e080e7          	jalr	1150(ra) # 800010ba <mappages>
    80001c44:	02054163          	bltz	a0,80001c66 <proc_pagetable+0x76>
}
    80001c48:	8526                	mv	a0,s1
    80001c4a:	60e2                	ld	ra,24(sp)
    80001c4c:	6442                	ld	s0,16(sp)
    80001c4e:	64a2                	ld	s1,8(sp)
    80001c50:	6902                	ld	s2,0(sp)
    80001c52:	6105                	addi	sp,sp,32
    80001c54:	8082                	ret
    uvmfree(pagetable, 0);
    80001c56:	4581                	li	a1,0
    80001c58:	8526                	mv	a0,s1
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	8ee080e7          	jalr	-1810(ra) # 80001548 <uvmfree>
    return 0;
    80001c62:	4481                	li	s1,0
    80001c64:	b7d5                	j	80001c48 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c66:	4681                	li	a3,0
    80001c68:	4605                	li	a2,1
    80001c6a:	040005b7          	lui	a1,0x4000
    80001c6e:	15fd                	addi	a1,a1,-1
    80001c70:	05b2                	slli	a1,a1,0xc
    80001c72:	8526                	mv	a0,s1
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	60c080e7          	jalr	1548(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c7c:	4581                	li	a1,0
    80001c7e:	8526                	mv	a0,s1
    80001c80:	00000097          	auipc	ra,0x0
    80001c84:	8c8080e7          	jalr	-1848(ra) # 80001548 <uvmfree>
    return 0;
    80001c88:	4481                	li	s1,0
    80001c8a:	bf7d                	j	80001c48 <proc_pagetable+0x58>

0000000080001c8c <proc_freepagetable>:
{
    80001c8c:	1101                	addi	sp,sp,-32
    80001c8e:	ec06                	sd	ra,24(sp)
    80001c90:	e822                	sd	s0,16(sp)
    80001c92:	e426                	sd	s1,8(sp)
    80001c94:	e04a                	sd	s2,0(sp)
    80001c96:	1000                	addi	s0,sp,32
    80001c98:	84aa                	mv	s1,a0
    80001c9a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c9c:	4681                	li	a3,0
    80001c9e:	4605                	li	a2,1
    80001ca0:	040005b7          	lui	a1,0x4000
    80001ca4:	15fd                	addi	a1,a1,-1
    80001ca6:	05b2                	slli	a1,a1,0xc
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	5d8080e7          	jalr	1496(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cb0:	4681                	li	a3,0
    80001cb2:	4605                	li	a2,1
    80001cb4:	020005b7          	lui	a1,0x2000
    80001cb8:	15fd                	addi	a1,a1,-1
    80001cba:	05b6                	slli	a1,a1,0xd
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	5c2080e7          	jalr	1474(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001cc6:	85ca                	mv	a1,s2
    80001cc8:	8526                	mv	a0,s1
    80001cca:	00000097          	auipc	ra,0x0
    80001cce:	87e080e7          	jalr	-1922(ra) # 80001548 <uvmfree>
}
    80001cd2:	60e2                	ld	ra,24(sp)
    80001cd4:	6442                	ld	s0,16(sp)
    80001cd6:	64a2                	ld	s1,8(sp)
    80001cd8:	6902                	ld	s2,0(sp)
    80001cda:	6105                	addi	sp,sp,32
    80001cdc:	8082                	ret

0000000080001cde <freeproc>:
{
    80001cde:	1101                	addi	sp,sp,-32
    80001ce0:	ec06                	sd	ra,24(sp)
    80001ce2:	e822                	sd	s0,16(sp)
    80001ce4:	e426                	sd	s1,8(sp)
    80001ce6:	1000                	addi	s0,sp,32
    80001ce8:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001cea:	6d28                	ld	a0,88(a0)
    80001cec:	c509                	beqz	a0,80001cf6 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	d10080e7          	jalr	-752(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001cf6:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001cfa:	68a8                	ld	a0,80(s1)
    80001cfc:	c511                	beqz	a0,80001d08 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cfe:	64ac                	ld	a1,72(s1)
    80001d00:	00000097          	auipc	ra,0x0
    80001d04:	f8c080e7          	jalr	-116(ra) # 80001c8c <proc_freepagetable>
  p->pagetable = 0;
    80001d08:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d0c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d10:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d14:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d18:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d1c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d20:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d24:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d28:	0004ac23          	sw	zero,24(s1)
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6105                	addi	sp,sp,32
    80001d34:	8082                	ret

0000000080001d36 <allocproc>:
{
    80001d36:	1101                	addi	sp,sp,-32
    80001d38:	ec06                	sd	ra,24(sp)
    80001d3a:	e822                	sd	s0,16(sp)
    80001d3c:	e426                	sd	s1,8(sp)
    80001d3e:	e04a                	sd	s2,0(sp)
    80001d40:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d42:	00017497          	auipc	s1,0x17
    80001d46:	ac648493          	addi	s1,s1,-1338 # 80018808 <proc>
    80001d4a:	0001f917          	auipc	s2,0x1f
    80001d4e:	abe90913          	addi	s2,s2,-1346 # 80020808 <tickslock>
    acquire(&p->lock);
    80001d52:	8526                	mv	a0,s1
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	e96080e7          	jalr	-362(ra) # 80000bea <acquire>
    if (p->state == UNUSED)
    80001d5c:	4c9c                	lw	a5,24(s1)
    80001d5e:	cf81                	beqz	a5,80001d76 <allocproc+0x40>
      release(&p->lock);
    80001d60:	8526                	mv	a0,s1
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	f3c080e7          	jalr	-196(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d6a:	20048493          	addi	s1,s1,512
    80001d6e:	ff2492e3          	bne	s1,s2,80001d52 <allocproc+0x1c>
  return 0;
    80001d72:	4481                	li	s1,0
    80001d74:	a065                	j	80001e1c <allocproc+0xe6>
  p->pid = allocpid();
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	e34080e7          	jalr	-460(ra) # 80001baa <allocpid>
    80001d7e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d80:	4785                	li	a5,1
    80001d82:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	d76080e7          	jalr	-650(ra) # 80000afa <kalloc>
    80001d8c:	892a                	mv	s2,a0
    80001d8e:	eca8                	sd	a0,88(s1)
    80001d90:	cd49                	beqz	a0,80001e2a <allocproc+0xf4>
  p->pagetable = proc_pagetable(p);
    80001d92:	8526                	mv	a0,s1
    80001d94:	00000097          	auipc	ra,0x0
    80001d98:	e5c080e7          	jalr	-420(ra) # 80001bf0 <proc_pagetable>
    80001d9c:	892a                	mv	s2,a0
    80001d9e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001da0:	c14d                	beqz	a0,80001e42 <allocproc+0x10c>
  memset(&p->context, 0, sizeof(p->context));
    80001da2:	07000613          	li	a2,112
    80001da6:	4581                	li	a1,0
    80001da8:	06048513          	addi	a0,s1,96
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	f3a080e7          	jalr	-198(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001db4:	00000797          	auipc	a5,0x0
    80001db8:	db078793          	addi	a5,a5,-592 # 80001b64 <forkret>
    80001dbc:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001dbe:	60bc                	ld	a5,64(s1)
    80001dc0:	6705                	lui	a4,0x1
    80001dc2:	97ba                	add	a5,a5,a4
    80001dc4:	f4bc                	sd	a5,104(s1)
  p->cTimee = ticks;
    80001dc6:	0000e717          	auipc	a4,0xe
    80001dca:	97a76703          	lwu	a4,-1670(a4) # 8000f740 <ticks>
    80001dce:	16e4b823          	sd	a4,368(s1)
  p->SP = 60; //
    80001dd2:	03c00793          	li	a5,60
    80001dd6:	16f4ac23          	sw	a5,376(s1)
  p->new_proc = 1;
    80001dda:	4785                	li	a5,1
    80001ddc:	1af4b423          	sd	a5,424(s1)
  p->previous_runtime = 0;
    80001de0:	1804bc23          	sd	zero,408(s1)
  p->scheduled_ct = 0;
    80001de4:	1804b023          	sd	zero,384(s1)
  p->previous_sleeptime = 0;
    80001de8:	1a04b023          	sd	zero,416(s1)
  p->total_runtime = 0;
    80001dec:	1804b823          	sd	zero,400(s1)
  p->exit_time = 0;
    80001df0:	1804b423          	sd	zero,392(s1)
  p->isthispinq = 0;
    80001df4:	1c04b023          	sd	zero,448(s1)
  p->pcurrentqlevel = 0;
    80001df8:	1a04b823          	sd	zero,432(s1)
  p->checkfornextq = 1;
    80001dfc:	1cf4b423          	sd	a5,456(s1)
  p->numberoftickets = 1;
    80001e00:	1cf4b823          	sd	a5,464(s1)
  p->ptimeqenter = p->cTimee;
    80001e04:	1ae4bc23          	sd	a4,440(s1)
  p->tickswhenalarmisoff = p->tickswhenalarmison = 0;
    80001e08:	1e04b023          	sd	zero,480(s1)
    80001e0c:	1e04b423          	sd	zero,488(s1)
  p->counttointerrupt = 1000000000;
    80001e10:	3b9ad7b7          	lui	a5,0x3b9ad
    80001e14:	a007879b          	addiw	a5,a5,-1536
    80001e18:	1cf4ac23          	sw	a5,472(s1)
}
    80001e1c:	8526                	mv	a0,s1
    80001e1e:	60e2                	ld	ra,24(sp)
    80001e20:	6442                	ld	s0,16(sp)
    80001e22:	64a2                	ld	s1,8(sp)
    80001e24:	6902                	ld	s2,0(sp)
    80001e26:	6105                	addi	sp,sp,32
    80001e28:	8082                	ret
    freeproc(p);
    80001e2a:	8526                	mv	a0,s1
    80001e2c:	00000097          	auipc	ra,0x0
    80001e30:	eb2080e7          	jalr	-334(ra) # 80001cde <freeproc>
    release(&p->lock);
    80001e34:	8526                	mv	a0,s1
    80001e36:	fffff097          	auipc	ra,0xfffff
    80001e3a:	e68080e7          	jalr	-408(ra) # 80000c9e <release>
    return 0;
    80001e3e:	84ca                	mv	s1,s2
    80001e40:	bff1                	j	80001e1c <allocproc+0xe6>
    freeproc(p);
    80001e42:	8526                	mv	a0,s1
    80001e44:	00000097          	auipc	ra,0x0
    80001e48:	e9a080e7          	jalr	-358(ra) # 80001cde <freeproc>
    release(&p->lock);
    80001e4c:	8526                	mv	a0,s1
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	e50080e7          	jalr	-432(ra) # 80000c9e <release>
    return 0;
    80001e56:	84ca                	mv	s1,s2
    80001e58:	b7d1                	j	80001e1c <allocproc+0xe6>

0000000080001e5a <userinit>:
{
    80001e5a:	1101                	addi	sp,sp,-32
    80001e5c:	ec06                	sd	ra,24(sp)
    80001e5e:	e822                	sd	s0,16(sp)
    80001e60:	e426                	sd	s1,8(sp)
    80001e62:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e64:	00000097          	auipc	ra,0x0
    80001e68:	ed2080e7          	jalr	-302(ra) # 80001d36 <allocproc>
    80001e6c:	84aa                	mv	s1,a0
  initproc = p;
    80001e6e:	0000e797          	auipc	a5,0xe
    80001e72:	8ca7b523          	sd	a0,-1846(a5) # 8000f738 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e76:	03400613          	li	a2,52
    80001e7a:	00007597          	auipc	a1,0x7
    80001e7e:	a8658593          	addi	a1,a1,-1402 # 80008900 <initcode>
    80001e82:	6928                	ld	a0,80(a0)
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	4ee080e7          	jalr	1262(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001e8c:	6785                	lui	a5,0x1
    80001e8e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e90:	6cb8                	ld	a4,88(s1)
    80001e92:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e96:	6cb8                	ld	a4,88(s1)
    80001e98:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e9a:	4641                	li	a2,16
    80001e9c:	00006597          	auipc	a1,0x6
    80001ea0:	37c58593          	addi	a1,a1,892 # 80008218 <digits+0x1d8>
    80001ea4:	15848513          	addi	a0,s1,344
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	f90080e7          	jalr	-112(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001eb0:	00006517          	auipc	a0,0x6
    80001eb4:	37850513          	addi	a0,a0,888 # 80008228 <digits+0x1e8>
    80001eb8:	00003097          	auipc	ra,0x3
    80001ebc:	88c080e7          	jalr	-1908(ra) # 80004744 <namei>
    80001ec0:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ec4:	478d                	li	a5,3
    80001ec6:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ec8:	8526                	mv	a0,s1
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	dd4080e7          	jalr	-556(ra) # 80000c9e <release>
}
    80001ed2:	60e2                	ld	ra,24(sp)
    80001ed4:	6442                	ld	s0,16(sp)
    80001ed6:	64a2                	ld	s1,8(sp)
    80001ed8:	6105                	addi	sp,sp,32
    80001eda:	8082                	ret

0000000080001edc <growproc>:
{
    80001edc:	1101                	addi	sp,sp,-32
    80001ede:	ec06                	sd	ra,24(sp)
    80001ee0:	e822                	sd	s0,16(sp)
    80001ee2:	e426                	sd	s1,8(sp)
    80001ee4:	e04a                	sd	s2,0(sp)
    80001ee6:	1000                	addi	s0,sp,32
    80001ee8:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001eea:	00000097          	auipc	ra,0x0
    80001eee:	c42080e7          	jalr	-958(ra) # 80001b2c <myproc>
    80001ef2:	84aa                	mv	s1,a0
  sz = p->sz;
    80001ef4:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001ef6:	01204c63          	bgtz	s2,80001f0e <growproc+0x32>
  else if (n < 0)
    80001efa:	02094663          	bltz	s2,80001f26 <growproc+0x4a>
  p->sz = sz;
    80001efe:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f00:	4501                	li	a0,0
}
    80001f02:	60e2                	ld	ra,24(sp)
    80001f04:	6442                	ld	s0,16(sp)
    80001f06:	64a2                	ld	s1,8(sp)
    80001f08:	6902                	ld	s2,0(sp)
    80001f0a:	6105                	addi	sp,sp,32
    80001f0c:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f0e:	4691                	li	a3,4
    80001f10:	00b90633          	add	a2,s2,a1
    80001f14:	6928                	ld	a0,80(a0)
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	516080e7          	jalr	1302(ra) # 8000142c <uvmalloc>
    80001f1e:	85aa                	mv	a1,a0
    80001f20:	fd79                	bnez	a0,80001efe <growproc+0x22>
      return -1;
    80001f22:	557d                	li	a0,-1
    80001f24:	bff9                	j	80001f02 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f26:	00b90633          	add	a2,s2,a1
    80001f2a:	6928                	ld	a0,80(a0)
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	4b8080e7          	jalr	1208(ra) # 800013e4 <uvmdealloc>
    80001f34:	85aa                	mv	a1,a0
    80001f36:	b7e1                	j	80001efe <growproc+0x22>

0000000080001f38 <fork>:
{
    80001f38:	7179                	addi	sp,sp,-48
    80001f3a:	f406                	sd	ra,40(sp)
    80001f3c:	f022                	sd	s0,32(sp)
    80001f3e:	ec26                	sd	s1,24(sp)
    80001f40:	e84a                	sd	s2,16(sp)
    80001f42:	e44e                	sd	s3,8(sp)
    80001f44:	e052                	sd	s4,0(sp)
    80001f46:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f48:	00000097          	auipc	ra,0x0
    80001f4c:	be4080e7          	jalr	-1052(ra) # 80001b2c <myproc>
    80001f50:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001f52:	00000097          	auipc	ra,0x0
    80001f56:	de4080e7          	jalr	-540(ra) # 80001d36 <allocproc>
    80001f5a:	10050f63          	beqz	a0,80002078 <fork+0x140>
    80001f5e:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f60:	04893603          	ld	a2,72(s2)
    80001f64:	692c                	ld	a1,80(a0)
    80001f66:	05093503          	ld	a0,80(s2)
    80001f6a:	fffff097          	auipc	ra,0xfffff
    80001f6e:	616080e7          	jalr	1558(ra) # 80001580 <uvmcopy>
    80001f72:	04054a63          	bltz	a0,80001fc6 <fork+0x8e>
  np->sz = p->sz;
    80001f76:	04893783          	ld	a5,72(s2)
    80001f7a:	04f9b423          	sd	a5,72(s3) # 1048 <_entry-0x7fffefb8>
  *(np->trapframe) = *(p->trapframe);
    80001f7e:	05893683          	ld	a3,88(s2)
    80001f82:	87b6                	mv	a5,a3
    80001f84:	0589b703          	ld	a4,88(s3)
    80001f88:	12068693          	addi	a3,a3,288
    80001f8c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f90:	6788                	ld	a0,8(a5)
    80001f92:	6b8c                	ld	a1,16(a5)
    80001f94:	6f90                	ld	a2,24(a5)
    80001f96:	01073023          	sd	a6,0(a4)
    80001f9a:	e708                	sd	a0,8(a4)
    80001f9c:	eb0c                	sd	a1,16(a4)
    80001f9e:	ef10                	sd	a2,24(a4)
    80001fa0:	02078793          	addi	a5,a5,32
    80001fa4:	02070713          	addi	a4,a4,32
    80001fa8:	fed792e3          	bne	a5,a3,80001f8c <fork+0x54>
  np->trapframe->a0 = 0;
    80001fac:	0589b783          	ld	a5,88(s3)
    80001fb0:	0607b823          	sd	zero,112(a5)
  np->masknumber = p->masknumber;
    80001fb4:	16892783          	lw	a5,360(s2)
    80001fb8:	16f9a423          	sw	a5,360(s3)
    80001fbc:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80001fc0:	15000a13          	li	s4,336
    80001fc4:	a03d                	j	80001ff2 <fork+0xba>
    freeproc(np);
    80001fc6:	854e                	mv	a0,s3
    80001fc8:	00000097          	auipc	ra,0x0
    80001fcc:	d16080e7          	jalr	-746(ra) # 80001cde <freeproc>
    release(&np->lock);
    80001fd0:	854e                	mv	a0,s3
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	ccc080e7          	jalr	-820(ra) # 80000c9e <release>
    return -1;
    80001fda:	5a7d                	li	s4,-1
    80001fdc:	a069                	j	80002066 <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fde:	00003097          	auipc	ra,0x3
    80001fe2:	dfc080e7          	jalr	-516(ra) # 80004dda <filedup>
    80001fe6:	009987b3          	add	a5,s3,s1
    80001fea:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001fec:	04a1                	addi	s1,s1,8
    80001fee:	01448763          	beq	s1,s4,80001ffc <fork+0xc4>
    if (p->ofile[i])
    80001ff2:	009907b3          	add	a5,s2,s1
    80001ff6:	6388                	ld	a0,0(a5)
    80001ff8:	f17d                	bnez	a0,80001fde <fork+0xa6>
    80001ffa:	bfcd                	j	80001fec <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001ffc:	15093503          	ld	a0,336(s2)
    80002000:	00002097          	auipc	ra,0x2
    80002004:	f60080e7          	jalr	-160(ra) # 80003f60 <idup>
    80002008:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000200c:	4641                	li	a2,16
    8000200e:	15890593          	addi	a1,s2,344
    80002012:	15898513          	addi	a0,s3,344
    80002016:	fffff097          	auipc	ra,0xfffff
    8000201a:	e22080e7          	jalr	-478(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    8000201e:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80002022:	854e                	mv	a0,s3
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	c7a080e7          	jalr	-902(ra) # 80000c9e <release>
  acquire(&wait_lock);
    8000202c:	00016497          	auipc	s1,0x16
    80002030:	99c48493          	addi	s1,s1,-1636 # 800179c8 <wait_lock>
    80002034:	8526                	mv	a0,s1
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	bb4080e7          	jalr	-1100(ra) # 80000bea <acquire>
  np->parent = p;
    8000203e:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80002042:	8526                	mv	a0,s1
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	c5a080e7          	jalr	-934(ra) # 80000c9e <release>
  acquire(&np->lock);
    8000204c:	854e                	mv	a0,s3
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	b9c080e7          	jalr	-1124(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80002056:	478d                	li	a5,3
    80002058:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000205c:	854e                	mv	a0,s3
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	c40080e7          	jalr	-960(ra) # 80000c9e <release>
}
    80002066:	8552                	mv	a0,s4
    80002068:	70a2                	ld	ra,40(sp)
    8000206a:	7402                	ld	s0,32(sp)
    8000206c:	64e2                	ld	s1,24(sp)
    8000206e:	6942                	ld	s2,16(sp)
    80002070:	69a2                	ld	s3,8(sp)
    80002072:	6a02                	ld	s4,0(sp)
    80002074:	6145                	addi	sp,sp,48
    80002076:	8082                	ret
    return -1;
    80002078:	5a7d                	li	s4,-1
    8000207a:	b7f5                	j	80002066 <fork+0x12e>

000000008000207c <MINN>:
{
    8000207c:	1141                	addi	sp,sp,-16
    8000207e:	e422                	sd	s0,8(sp)
    80002080:	0800                	addi	s0,sp,16
    80002082:	87aa                	mv	a5,a0
    80002084:	852e                	mv	a0,a1
  return (a < b ? a : b);
    80002086:	00b7d363          	bge	a5,a1,8000208c <MINN+0x10>
    8000208a:	853e                	mv	a0,a5
}
    8000208c:	6422                	ld	s0,8(sp)
    8000208e:	0141                	addi	sp,sp,16
    80002090:	8082                	ret

0000000080002092 <MAXX>:
{
    80002092:	1141                	addi	sp,sp,-16
    80002094:	e422                	sd	s0,8(sp)
    80002096:	0800                	addi	s0,sp,16
    80002098:	87aa                	mv	a5,a0
    8000209a:	852e                	mv	a0,a1
  return (a > b ? a : b);
    8000209c:	00f5d363          	bge	a1,a5,800020a2 <MAXX+0x10>
    800020a0:	853e                	mv	a0,a5
}
    800020a2:	6422                	ld	s0,8(sp)
    800020a4:	0141                	addi	sp,sp,16
    800020a6:	8082                	ret

00000000800020a8 <calculate_dp>:
{
    800020a8:	1141                	addi	sp,sp,-16
    800020aa:	e422                	sd	s0,8(sp)
    800020ac:	0800                	addi	s0,sp,16
    niceness = 5;
    800020ae:	4795                	li	a5,5
  if (ifitisnew_proc == 0 && previous_runtime > 0)
    800020b0:	ea99                	bnez	a3,800020c6 <calculate_dp+0x1e>
    800020b2:	00a05a63          	blez	a0,800020c6 <calculate_dp+0x1e>
    niceness = (previous_sleeptime / (previous_runtime + previous_sleeptime)) * 10;
    800020b6:	952e                	add	a0,a0,a1
    800020b8:	02a5c5b3          	div	a1,a1,a0
    800020bc:	0025979b          	slliw	a5,a1,0x2
    800020c0:	9dbd                	addw	a1,a1,a5
    800020c2:	0015979b          	slliw	a5,a1,0x1
  ans = MAXX(0, MINN(staticp - niceness + 5, 100));
    800020c6:	40f6053b          	subw	a0,a2,a5
    800020ca:	2515                	addiw	a0,a0,5
  return (a < b ? a : b);
    800020cc:	06400793          	li	a5,100
    800020d0:	00a7d463          	bge	a5,a0,800020d8 <calculate_dp+0x30>
    800020d4:	06400513          	li	a0,100
  return (a > b ? a : b);
    800020d8:	fff54793          	not	a5,a0
    800020dc:	97fd                	srai	a5,a5,0x3f
    800020de:	8d7d                	and	a0,a0,a5
}
    800020e0:	2501                	sext.w	a0,a0
    800020e2:	6422                	ld	s0,8(sp)
    800020e4:	0141                	addi	sp,sp,16
    800020e6:	8082                	ret

00000000800020e8 <scheduler>:
{
    800020e8:	711d                	addi	sp,sp,-96
    800020ea:	ec86                	sd	ra,88(sp)
    800020ec:	e8a2                	sd	s0,80(sp)
    800020ee:	e4a6                	sd	s1,72(sp)
    800020f0:	e0ca                	sd	s2,64(sp)
    800020f2:	fc4e                	sd	s3,56(sp)
    800020f4:	f852                	sd	s4,48(sp)
    800020f6:	f456                	sd	s5,40(sp)
    800020f8:	f05a                	sd	s6,32(sp)
    800020fa:	ec5e                	sd	s7,24(sp)
    800020fc:	e862                	sd	s8,16(sp)
    800020fe:	e466                	sd	s9,8(sp)
    80002100:	e06a                	sd	s10,0(sp)
    80002102:	1080                	addi	s0,sp,96
    80002104:	8792                	mv	a5,tp
  int id = r_tp();
    80002106:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002108:	00779d13          	slli	s10,a5,0x7
    8000210c:	00016717          	auipc	a4,0x16
    80002110:	8a470713          	addi	a4,a4,-1884 # 800179b0 <pid_lock>
    80002114:	976a                	add	a4,a4,s10
    80002116:	02073823          	sd	zero,48(a4)
    swtch(&c->context, &givetoCPU->context);
    8000211a:	00016717          	auipc	a4,0x16
    8000211e:	8ce70713          	addi	a4,a4,-1842 # 800179e8 <cpus+0x8>
    80002122:	9d3a                	add	s10,s10,a4
    long long respectivecreationtime = inf16; // 1e16 initialised to inf. this will be the upperbound  for creation time for all processes.
    80002124:	00006b17          	auipc	s6,0x6
    80002128:	edcb0b13          	addi	s6,s6,-292 # 80008000 <etext>
    for (p = proc; p < &proc[NPROC]; p++)
    8000212c:	0001ea17          	auipc	s4,0x1e
    80002130:	6dca0a13          	addi	s4,s4,1756 # 80020808 <tickslock>
    long long respectivecreationtime = inf16; // 1e16 initialised to inf. this will be the upperbound  for creation time for all processes.
    80002134:	000b3c83          	ld	s9,0(s6)
    struct proc *givetoCPU = 0;
    80002138:	4c01                	li	s8,0
    c->proc = givetoCPU;
    8000213a:	079e                	slli	a5,a5,0x7
    8000213c:	00016b97          	auipc	s7,0x16
    80002140:	874b8b93          	addi	s7,s7,-1932 # 800179b0 <pid_lock>
    80002144:	9bbe                	add	s7,s7,a5
    80002146:	a841                	j	800021d6 <scheduler+0xee>
          release(&givetoCPU->lock);
    80002148:	8556                	mv	a0,s5
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	b54080e7          	jalr	-1196(ra) # 80000c9e <release>
    80002152:	a815                	j	80002186 <scheduler+0x9e>
        release(&p->lock);
    80002154:	8526                	mv	a0,s1
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	b48080e7          	jalr	-1208(ra) # 80000c9e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000215e:	20048493          	addi	s1,s1,512
    80002162:	03448663          	beq	s1,s4,8000218e <scheduler+0xa6>
      acquire(&p->lock);
    80002166:	8526                	mv	a0,s1
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	a82080e7          	jalr	-1406(ra) # 80000bea <acquire>
      if (p->state == RUNNABLE && respectivecreationtime > p->cTimee)
    80002170:	4c9c                	lw	a5,24(s1)
    80002172:	ff3791e3          	bne	a5,s3,80002154 <scheduler+0x6c>
    80002176:	1704b783          	ld	a5,368(s1)
    8000217a:	fd27dde3          	bge	a5,s2,80002154 <scheduler+0x6c>
        if (respectivecreationtime != inf16)
    8000217e:	000b3783          	ld	a5,0(s6)
    80002182:	fcf913e3          	bne	s2,a5,80002148 <scheduler+0x60>
        respectivecreationtime = p->cTimee;
    80002186:	1704b903          	ld	s2,368(s1)
        continue;
    8000218a:	8aa6                	mv	s5,s1
    8000218c:	bfc9                	j	8000215e <scheduler+0x76>
    if (respectivecreationtime == inf16)
    8000218e:	000b3783          	ld	a5,0(s6)
    80002192:	00f91f63          	bne	s2,a5,800021b0 <scheduler+0xc8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002196:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000219a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000219e:	10079073          	csrw	sstatus,a5
    long long respectivecreationtime = inf16; // 1e16 initialised to inf. this will be the upperbound  for creation time for all processes.
    800021a2:	8966                	mv	s2,s9
    struct proc *givetoCPU = 0;
    800021a4:	8ae2                	mv	s5,s8
    for (p = proc; p < &proc[NPROC]; p++)
    800021a6:	00016497          	auipc	s1,0x16
    800021aa:	66248493          	addi	s1,s1,1634 # 80018808 <proc>
    800021ae:	bf65                	j	80002166 <scheduler+0x7e>
    givetoCPU->state = RUNNING;
    800021b0:	4791                	li	a5,4
    800021b2:	00faac23          	sw	a5,24(s5)
    c->proc = givetoCPU;
    800021b6:	035bb823          	sd	s5,48(s7)
    swtch(&c->context, &givetoCPU->context);
    800021ba:	060a8593          	addi	a1,s5,96
    800021be:	856a                	mv	a0,s10
    800021c0:	00001097          	auipc	ra,0x1
    800021c4:	98a080e7          	jalr	-1654(ra) # 80002b4a <swtch>
    release(&givetoCPU->lock);
    800021c8:	8556                	mv	a0,s5
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	ad4080e7          	jalr	-1324(ra) # 80000c9e <release>
    c->proc = 0;
    800021d2:	020bb823          	sd	zero,48(s7)
      if (p->state == RUNNABLE && respectivecreationtime > p->cTimee)
    800021d6:	498d                	li	s3,3
    800021d8:	bf7d                	j	80002196 <scheduler+0xae>

00000000800021da <sched>:
{
    800021da:	7179                	addi	sp,sp,-48
    800021dc:	f406                	sd	ra,40(sp)
    800021de:	f022                	sd	s0,32(sp)
    800021e0:	ec26                	sd	s1,24(sp)
    800021e2:	e84a                	sd	s2,16(sp)
    800021e4:	e44e                	sd	s3,8(sp)
    800021e6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021e8:	00000097          	auipc	ra,0x0
    800021ec:	944080e7          	jalr	-1724(ra) # 80001b2c <myproc>
    800021f0:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	97e080e7          	jalr	-1666(ra) # 80000b70 <holding>
    800021fa:	c93d                	beqz	a0,80002270 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021fc:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800021fe:	2781                	sext.w	a5,a5
    80002200:	079e                	slli	a5,a5,0x7
    80002202:	00015717          	auipc	a4,0x15
    80002206:	7ae70713          	addi	a4,a4,1966 # 800179b0 <pid_lock>
    8000220a:	97ba                	add	a5,a5,a4
    8000220c:	0a87a703          	lw	a4,168(a5)
    80002210:	4785                	li	a5,1
    80002212:	06f71763          	bne	a4,a5,80002280 <sched+0xa6>
  if (p->state == RUNNING)
    80002216:	4c98                	lw	a4,24(s1)
    80002218:	4791                	li	a5,4
    8000221a:	06f70b63          	beq	a4,a5,80002290 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000221e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002222:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002224:	efb5                	bnez	a5,800022a0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002226:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002228:	00015917          	auipc	s2,0x15
    8000222c:	78890913          	addi	s2,s2,1928 # 800179b0 <pid_lock>
    80002230:	2781                	sext.w	a5,a5
    80002232:	079e                	slli	a5,a5,0x7
    80002234:	97ca                	add	a5,a5,s2
    80002236:	0ac7a983          	lw	s3,172(a5)
    8000223a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000223c:	2781                	sext.w	a5,a5
    8000223e:	079e                	slli	a5,a5,0x7
    80002240:	00015597          	auipc	a1,0x15
    80002244:	7a858593          	addi	a1,a1,1960 # 800179e8 <cpus+0x8>
    80002248:	95be                	add	a1,a1,a5
    8000224a:	06048513          	addi	a0,s1,96
    8000224e:	00001097          	auipc	ra,0x1
    80002252:	8fc080e7          	jalr	-1796(ra) # 80002b4a <swtch>
    80002256:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002258:	2781                	sext.w	a5,a5
    8000225a:	079e                	slli	a5,a5,0x7
    8000225c:	97ca                	add	a5,a5,s2
    8000225e:	0b37a623          	sw	s3,172(a5)
}
    80002262:	70a2                	ld	ra,40(sp)
    80002264:	7402                	ld	s0,32(sp)
    80002266:	64e2                	ld	s1,24(sp)
    80002268:	6942                	ld	s2,16(sp)
    8000226a:	69a2                	ld	s3,8(sp)
    8000226c:	6145                	addi	sp,sp,48
    8000226e:	8082                	ret
    panic("sched p->lock");
    80002270:	00006517          	auipc	a0,0x6
    80002274:	fc050513          	addi	a0,a0,-64 # 80008230 <digits+0x1f0>
    80002278:	ffffe097          	auipc	ra,0xffffe
    8000227c:	2cc080e7          	jalr	716(ra) # 80000544 <panic>
    panic("sched locks");
    80002280:	00006517          	auipc	a0,0x6
    80002284:	fc050513          	addi	a0,a0,-64 # 80008240 <digits+0x200>
    80002288:	ffffe097          	auipc	ra,0xffffe
    8000228c:	2bc080e7          	jalr	700(ra) # 80000544 <panic>
    panic("sched running");
    80002290:	00006517          	auipc	a0,0x6
    80002294:	fc050513          	addi	a0,a0,-64 # 80008250 <digits+0x210>
    80002298:	ffffe097          	auipc	ra,0xffffe
    8000229c:	2ac080e7          	jalr	684(ra) # 80000544 <panic>
    panic("sched interruptible");
    800022a0:	00006517          	auipc	a0,0x6
    800022a4:	fc050513          	addi	a0,a0,-64 # 80008260 <digits+0x220>
    800022a8:	ffffe097          	auipc	ra,0xffffe
    800022ac:	29c080e7          	jalr	668(ra) # 80000544 <panic>

00000000800022b0 <yield>:
{
    800022b0:	1101                	addi	sp,sp,-32
    800022b2:	ec06                	sd	ra,24(sp)
    800022b4:	e822                	sd	s0,16(sp)
    800022b6:	e426                	sd	s1,8(sp)
    800022b8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	872080e7          	jalr	-1934(ra) # 80001b2c <myproc>
    800022c2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	926080e7          	jalr	-1754(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    800022cc:	478d                	li	a5,3
    800022ce:	cc9c                	sw	a5,24(s1)
  sched();
    800022d0:	00000097          	auipc	ra,0x0
    800022d4:	f0a080e7          	jalr	-246(ra) # 800021da <sched>
  release(&p->lock);
    800022d8:	8526                	mv	a0,s1
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	9c4080e7          	jalr	-1596(ra) # 80000c9e <release>
}
    800022e2:	60e2                	ld	ra,24(sp)
    800022e4:	6442                	ld	s0,16(sp)
    800022e6:	64a2                	ld	s1,8(sp)
    800022e8:	6105                	addi	sp,sp,32
    800022ea:	8082                	ret

00000000800022ec <set_priority>:
{
    800022ec:	715d                	addi	sp,sp,-80
    800022ee:	e486                	sd	ra,72(sp)
    800022f0:	e0a2                	sd	s0,64(sp)
    800022f2:	fc26                	sd	s1,56(sp)
    800022f4:	f84a                	sd	s2,48(sp)
    800022f6:	f44e                	sd	s3,40(sp)
    800022f8:	f052                	sd	s4,32(sp)
    800022fa:	ec56                	sd	s5,24(sp)
    800022fc:	e85a                	sd	s6,16(sp)
    800022fe:	e45e                	sd	s7,8(sp)
    80002300:	0880                	addi	s0,sp,80
    80002302:	8aaa                	mv	s5,a0
    80002304:	8b2e                	mv	s6,a1
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002306:	00016497          	auipc	s1,0x16
    8000230a:	50248493          	addi	s1,s1,1282 # 80018808 <proc>
  int foundptochange = 0;
    8000230e:	4901                	li	s2,0
      p->new_proc = 1;
    80002310:	4985                	li	s3,1
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002312:	0001eb97          	auipc	s7,0x1e
    80002316:	4f6b8b93          	addi	s7,s7,1270 # 80020808 <tickslock>
    8000231a:	a835                	j	80002356 <set_priority+0x6a>
        release(&p->lock);
    8000231c:	8526                	mv	a0,s1
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	980080e7          	jalr	-1664(ra) # 80000c9e <release>
        yield();
    80002326:	00000097          	auipc	ra,0x0
    8000232a:	f8a080e7          	jalr	-118(ra) # 800022b0 <yield>
}
    8000232e:	60a6                	ld	ra,72(sp)
    80002330:	6406                	ld	s0,64(sp)
    80002332:	74e2                	ld	s1,56(sp)
    80002334:	7942                	ld	s2,48(sp)
    80002336:	79a2                	ld	s3,40(sp)
    80002338:	7a02                	ld	s4,32(sp)
    8000233a:	6ae2                	ld	s5,24(sp)
    8000233c:	6b42                	ld	s6,16(sp)
    8000233e:	6ba2                	ld	s7,8(sp)
    80002340:	6161                	addi	sp,sp,80
    80002342:	8082                	ret
    release(&p->lock);
    80002344:	8526                	mv	a0,s1
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	958080e7          	jalr	-1704(ra) # 80000c9e <release>
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    8000234e:	20048493          	addi	s1,s1,512
    80002352:	05748a63          	beq	s1,s7,800023a6 <set_priority+0xba>
    acquire(&p->lock);
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	892080e7          	jalr	-1902(ra) # 80000bea <acquire>
    if (p->pid == tochangepid)
    80002360:	589c                	lw	a5,48(s1)
    80002362:	ff6791e3          	bne	a5,s6,80002344 <set_priority+0x58>
      int prevdp = calculate_dp(p->previous_runtime, p->previous_sleeptime, p->SP, p->new_proc);
    80002366:	1a04ba03          	ld	s4,416(s1)
    8000236a:	1a84a683          	lw	a3,424(s1)
    8000236e:	1784a603          	lw	a2,376(s1)
    80002372:	85d2                	mv	a1,s4
    80002374:	1984b503          	ld	a0,408(s1)
    80002378:	00000097          	auipc	ra,0x0
    8000237c:	d30080e7          	jalr	-720(ra) # 800020a8 <calculate_dp>
    80002380:	892a                	mv	s2,a0
      p->SP = newp;
    80002382:	1754ac23          	sw	s5,376(s1)
      p->new_proc = 1;
    80002386:	1b34b423          	sd	s3,424(s1)
      p->previous_runtime = 0;
    8000238a:	1804bc23          	sd	zero,408(s1)
      int newdp = calculate_dp(p->previous_runtime, p->previous_sleeptime, p->SP, p->new_proc);
    8000238e:	86ce                	mv	a3,s3
    80002390:	8656                	mv	a2,s5
    80002392:	85d2                	mv	a1,s4
    80002394:	4501                	li	a0,0
    80002396:	00000097          	auipc	ra,0x0
    8000239a:	d12080e7          	jalr	-750(ra) # 800020a8 <calculate_dp>
      if (newdp < prevdp)
    8000239e:	f7254fe3          	blt	a0,s2,8000231c <set_priority+0x30>
      foundptochange = 1;
    800023a2:	894e                	mv	s2,s3
    800023a4:	b745                	j	80002344 <set_priority+0x58>
  if (foundptochange == 0)
    800023a6:	f80914e3          	bnez	s2,8000232e <set_priority+0x42>
    printf("A process with such PID could not be found\n");
    800023aa:	00006517          	auipc	a0,0x6
    800023ae:	ece50513          	addi	a0,a0,-306 # 80008278 <digits+0x238>
    800023b2:	ffffe097          	auipc	ra,0xffffe
    800023b6:	1dc080e7          	jalr	476(ra) # 8000058e <printf>
    800023ba:	bf95                	j	8000232e <set_priority+0x42>

00000000800023bc <settickets>:
{
    800023bc:	1101                	addi	sp,sp,-32
    800023be:	ec06                	sd	ra,24(sp)
    800023c0:	e822                	sd	s0,16(sp)
    800023c2:	e426                	sd	s1,8(sp)
    800023c4:	e04a                	sd	s2,0(sp)
    800023c6:	1000                	addi	s0,sp,32
    800023c8:	8792                	mv	a5,tp
  struct proc *p = mycpu()->proc;
    800023ca:	2781                	sext.w	a5,a5
    800023cc:	079e                	slli	a5,a5,0x7
    800023ce:	00015717          	auipc	a4,0x15
    800023d2:	5e270713          	addi	a4,a4,1506 # 800179b0 <pid_lock>
    800023d6:	97ba                	add	a5,a5,a4
    800023d8:	7b84                	ld	s1,48(a5)
  if (p != 0)
    800023da:	cc91                	beqz	s1,800023f6 <settickets+0x3a>
    800023dc:	892a                	mv	s2,a0
    acquire(&p->lock);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	80a080e7          	jalr	-2038(ra) # 80000bea <acquire>
    p->numberoftickets = newtickets;
    800023e8:	1d24b823          	sd	s2,464(s1)
    release(&p->lock);
    800023ec:	8526                	mv	a0,s1
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	8b0080e7          	jalr	-1872(ra) # 80000c9e <release>
}
    800023f6:	60e2                	ld	ra,24(sp)
    800023f8:	6442                	ld	s0,16(sp)
    800023fa:	64a2                	ld	s1,8(sp)
    800023fc:	6902                	ld	s2,0(sp)
    800023fe:	6105                	addi	sp,sp,32
    80002400:	8082                	ret

0000000080002402 <updateprocesstimes>:
{
    80002402:	7179                	addi	sp,sp,-48
    80002404:	f406                	sd	ra,40(sp)
    80002406:	f022                	sd	s0,32(sp)
    80002408:	ec26                	sd	s1,24(sp)
    8000240a:	e84a                	sd	s2,16(sp)
    8000240c:	e44e                	sd	s3,8(sp)
    8000240e:	e052                	sd	s4,0(sp)
    80002410:	1800                	addi	s0,sp,48
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002412:	00016497          	auipc	s1,0x16
    80002416:	3f648493          	addi	s1,s1,1014 # 80018808 <proc>
    if (p->state == RUNNING)
    8000241a:	4991                	li	s3,4
    if (p->state == SLEEPING)
    8000241c:	4a09                	li	s4,2
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    8000241e:	0001e917          	auipc	s2,0x1e
    80002422:	3ea90913          	addi	s2,s2,1002 # 80020808 <tickslock>
    80002426:	a81d                	j	8000245c <updateprocesstimes+0x5a>
      p->total_runtime++;
    80002428:	1904b783          	ld	a5,400(s1)
    8000242c:	0785                	addi	a5,a5,1
    8000242e:	18f4b823          	sd	a5,400(s1)
      p->previous_runtime++;
    80002432:	1984b783          	ld	a5,408(s1)
    80002436:	0785                	addi	a5,a5,1
    80002438:	18f4bc23          	sd	a5,408(s1)
      p->new_proc = 0;
    8000243c:	1a04b423          	sd	zero,424(s1)
      p->checkfornextq--;
    80002440:	1c84b783          	ld	a5,456(s1)
    80002444:	17fd                	addi	a5,a5,-1
    80002446:	1cf4b423          	sd	a5,456(s1)
    release(&p->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	852080e7          	jalr	-1966(ra) # 80000c9e <release>
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002454:	20048493          	addi	s1,s1,512
    80002458:	03248263          	beq	s1,s2,8000247c <updateprocesstimes+0x7a>
    acquire(&p->lock);
    8000245c:	8526                	mv	a0,s1
    8000245e:	ffffe097          	auipc	ra,0xffffe
    80002462:	78c080e7          	jalr	1932(ra) # 80000bea <acquire>
    if (p->state == RUNNING)
    80002466:	4c9c                	lw	a5,24(s1)
    80002468:	fd3780e3          	beq	a5,s3,80002428 <updateprocesstimes+0x26>
    if (p->state == SLEEPING)
    8000246c:	fd479fe3          	bne	a5,s4,8000244a <updateprocesstimes+0x48>
      p->previous_sleeptime++;
    80002470:	1a04b783          	ld	a5,416(s1)
    80002474:	0785                	addi	a5,a5,1
    80002476:	1af4b023          	sd	a5,416(s1)
    8000247a:	bfc1                	j	8000244a <updateprocesstimes+0x48>
}
    8000247c:	70a2                	ld	ra,40(sp)
    8000247e:	7402                	ld	s0,32(sp)
    80002480:	64e2                	ld	s1,24(sp)
    80002482:	6942                	ld	s2,16(sp)
    80002484:	69a2                	ld	s3,8(sp)
    80002486:	6a02                	ld	s4,0(sp)
    80002488:	6145                	addi	sp,sp,48
    8000248a:	8082                	ret

000000008000248c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000248c:	7179                	addi	sp,sp,-48
    8000248e:	f406                	sd	ra,40(sp)
    80002490:	f022                	sd	s0,32(sp)
    80002492:	ec26                	sd	s1,24(sp)
    80002494:	e84a                	sd	s2,16(sp)
    80002496:	e44e                	sd	s3,8(sp)
    80002498:	1800                	addi	s0,sp,48
    8000249a:	89aa                	mv	s3,a0
    8000249c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	68e080e7          	jalr	1678(ra) # 80001b2c <myproc>
    800024a6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800024a8:	ffffe097          	auipc	ra,0xffffe
    800024ac:	742080e7          	jalr	1858(ra) # 80000bea <acquire>
  release(lk);
    800024b0:	854a                	mv	a0,s2
    800024b2:	ffffe097          	auipc	ra,0xffffe
    800024b6:	7ec080e7          	jalr	2028(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    800024ba:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800024be:	4789                	li	a5,2
    800024c0:	cc9c                	sw	a5,24(s1)

  sched();
    800024c2:	00000097          	auipc	ra,0x0
    800024c6:	d18080e7          	jalr	-744(ra) # 800021da <sched>

  // Tidy up.
  p->chan = 0;
    800024ca:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800024ce:	8526                	mv	a0,s1
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	7ce080e7          	jalr	1998(ra) # 80000c9e <release>
  acquire(lk);
    800024d8:	854a                	mv	a0,s2
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	710080e7          	jalr	1808(ra) # 80000bea <acquire>
}
    800024e2:	70a2                	ld	ra,40(sp)
    800024e4:	7402                	ld	s0,32(sp)
    800024e6:	64e2                	ld	s1,24(sp)
    800024e8:	6942                	ld	s2,16(sp)
    800024ea:	69a2                	ld	s3,8(sp)
    800024ec:	6145                	addi	sp,sp,48
    800024ee:	8082                	ret

00000000800024f0 <waitx>:
{
    800024f0:	711d                	addi	sp,sp,-96
    800024f2:	ec86                	sd	ra,88(sp)
    800024f4:	e8a2                	sd	s0,80(sp)
    800024f6:	e4a6                	sd	s1,72(sp)
    800024f8:	e0ca                	sd	s2,64(sp)
    800024fa:	fc4e                	sd	s3,56(sp)
    800024fc:	f852                	sd	s4,48(sp)
    800024fe:	f456                	sd	s5,40(sp)
    80002500:	f05a                	sd	s6,32(sp)
    80002502:	ec5e                	sd	s7,24(sp)
    80002504:	e862                	sd	s8,16(sp)
    80002506:	e466                	sd	s9,8(sp)
    80002508:	e06a                	sd	s10,0(sp)
    8000250a:	1080                	addi	s0,sp,96
    8000250c:	8b2a                	mv	s6,a0
    8000250e:	8bae                	mv	s7,a1
    80002510:	8c32                	mv	s8,a2
  struct proc *p = myproc();
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	61a080e7          	jalr	1562(ra) # 80001b2c <myproc>
    8000251a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000251c:	00015517          	auipc	a0,0x15
    80002520:	4ac50513          	addi	a0,a0,1196 # 800179c8 <wait_lock>
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	6c6080e7          	jalr	1734(ra) # 80000bea <acquire>
    havekids = 0;
    8000252c:	4c81                	li	s9,0
        if (np->state == ZOMBIE)
    8000252e:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    80002530:	0001e997          	auipc	s3,0x1e
    80002534:	2d898993          	addi	s3,s3,728 # 80020808 <tickslock>
        havekids = 1;
    80002538:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000253a:	00015d17          	auipc	s10,0x15
    8000253e:	48ed0d13          	addi	s10,s10,1166 # 800179c8 <wait_lock>
    havekids = 0;
    80002542:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002544:	00016497          	auipc	s1,0x16
    80002548:	2c448493          	addi	s1,s1,708 # 80018808 <proc>
    8000254c:	a069                	j	800025d6 <waitx+0xe6>
          pid = np->pid;
    8000254e:	0304a983          	lw	s3,48(s1)
          *rtime = np->total_runtime;
    80002552:	1904b783          	ld	a5,400(s1)
    80002556:	00fc2023          	sw	a5,0(s8)
          *wtime = np->exit_time - np->cTimee - np->total_runtime;
    8000255a:	1884b783          	ld	a5,392(s1)
    8000255e:	1704b703          	ld	a4,368(s1)
    80002562:	1904b683          	ld	a3,400(s1)
    80002566:	9f35                	addw	a4,a4,a3
    80002568:	9f99                	subw	a5,a5,a4
    8000256a:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000256e:	000b0e63          	beqz	s6,8000258a <waitx+0x9a>
    80002572:	4691                	li	a3,4
    80002574:	02c48613          	addi	a2,s1,44
    80002578:	85da                	mv	a1,s6
    8000257a:	05093503          	ld	a0,80(s2)
    8000257e:	fffff097          	auipc	ra,0xfffff
    80002582:	106080e7          	jalr	262(ra) # 80001684 <copyout>
    80002586:	02054563          	bltz	a0,800025b0 <waitx+0xc0>
          freeproc(np);
    8000258a:	8526                	mv	a0,s1
    8000258c:	fffff097          	auipc	ra,0xfffff
    80002590:	752080e7          	jalr	1874(ra) # 80001cde <freeproc>
          release(&np->lock);
    80002594:	8526                	mv	a0,s1
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	708080e7          	jalr	1800(ra) # 80000c9e <release>
          release(&wait_lock);
    8000259e:	00015517          	auipc	a0,0x15
    800025a2:	42a50513          	addi	a0,a0,1066 # 800179c8 <wait_lock>
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	6f8080e7          	jalr	1784(ra) # 80000c9e <release>
          return pid;
    800025ae:	a09d                	j	80002614 <waitx+0x124>
            release(&np->lock);
    800025b0:	8526                	mv	a0,s1
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	6ec080e7          	jalr	1772(ra) # 80000c9e <release>
            release(&wait_lock);
    800025ba:	00015517          	auipc	a0,0x15
    800025be:	40e50513          	addi	a0,a0,1038 # 800179c8 <wait_lock>
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	6dc080e7          	jalr	1756(ra) # 80000c9e <release>
            return -1;
    800025ca:	59fd                	li	s3,-1
    800025cc:	a0a1                	j	80002614 <waitx+0x124>
    for (np = proc; np < &proc[NPROC]; np++)
    800025ce:	20048493          	addi	s1,s1,512
    800025d2:	03348463          	beq	s1,s3,800025fa <waitx+0x10a>
      if (np->parent == p)
    800025d6:	7c9c                	ld	a5,56(s1)
    800025d8:	ff279be3          	bne	a5,s2,800025ce <waitx+0xde>
        acquire(&np->lock);
    800025dc:	8526                	mv	a0,s1
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	60c080e7          	jalr	1548(ra) # 80000bea <acquire>
        if (np->state == ZOMBIE)
    800025e6:	4c9c                	lw	a5,24(s1)
    800025e8:	f74783e3          	beq	a5,s4,8000254e <waitx+0x5e>
        release(&np->lock);
    800025ec:	8526                	mv	a0,s1
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	6b0080e7          	jalr	1712(ra) # 80000c9e <release>
        havekids = 1;
    800025f6:	8756                	mv	a4,s5
    800025f8:	bfd9                	j	800025ce <waitx+0xde>
    if (!havekids || p->killed)
    800025fa:	c701                	beqz	a4,80002602 <waitx+0x112>
    800025fc:	02892783          	lw	a5,40(s2)
    80002600:	cb8d                	beqz	a5,80002632 <waitx+0x142>
      release(&wait_lock);
    80002602:	00015517          	auipc	a0,0x15
    80002606:	3c650513          	addi	a0,a0,966 # 800179c8 <wait_lock>
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	694080e7          	jalr	1684(ra) # 80000c9e <release>
      return -1;
    80002612:	59fd                	li	s3,-1
}
    80002614:	854e                	mv	a0,s3
    80002616:	60e6                	ld	ra,88(sp)
    80002618:	6446                	ld	s0,80(sp)
    8000261a:	64a6                	ld	s1,72(sp)
    8000261c:	6906                	ld	s2,64(sp)
    8000261e:	79e2                	ld	s3,56(sp)
    80002620:	7a42                	ld	s4,48(sp)
    80002622:	7aa2                	ld	s5,40(sp)
    80002624:	7b02                	ld	s6,32(sp)
    80002626:	6be2                	ld	s7,24(sp)
    80002628:	6c42                	ld	s8,16(sp)
    8000262a:	6ca2                	ld	s9,8(sp)
    8000262c:	6d02                	ld	s10,0(sp)
    8000262e:	6125                	addi	sp,sp,96
    80002630:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002632:	85ea                	mv	a1,s10
    80002634:	854a                	mv	a0,s2
    80002636:	00000097          	auipc	ra,0x0
    8000263a:	e56080e7          	jalr	-426(ra) # 8000248c <sleep>
    havekids = 0;
    8000263e:	b711                	j	80002542 <waitx+0x52>

0000000080002640 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002640:	7139                	addi	sp,sp,-64
    80002642:	fc06                	sd	ra,56(sp)
    80002644:	f822                	sd	s0,48(sp)
    80002646:	f426                	sd	s1,40(sp)
    80002648:	f04a                	sd	s2,32(sp)
    8000264a:	ec4e                	sd	s3,24(sp)
    8000264c:	e852                	sd	s4,16(sp)
    8000264e:	e456                	sd	s5,8(sp)
    80002650:	0080                	addi	s0,sp,64
    80002652:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002654:	00016497          	auipc	s1,0x16
    80002658:	1b448493          	addi	s1,s1,436 # 80018808 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000265c:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000265e:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002660:	0001e917          	auipc	s2,0x1e
    80002664:	1a890913          	addi	s2,s2,424 # 80020808 <tickslock>
    80002668:	a821                	j	80002680 <wakeup+0x40>
        p->state = RUNNABLE;
    8000266a:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000266e:	8526                	mv	a0,s1
    80002670:	ffffe097          	auipc	ra,0xffffe
    80002674:	62e080e7          	jalr	1582(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002678:	20048493          	addi	s1,s1,512
    8000267c:	03248463          	beq	s1,s2,800026a4 <wakeup+0x64>
    if (p != myproc())
    80002680:	fffff097          	auipc	ra,0xfffff
    80002684:	4ac080e7          	jalr	1196(ra) # 80001b2c <myproc>
    80002688:	fea488e3          	beq	s1,a0,80002678 <wakeup+0x38>
      acquire(&p->lock);
    8000268c:	8526                	mv	a0,s1
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	55c080e7          	jalr	1372(ra) # 80000bea <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002696:	4c9c                	lw	a5,24(s1)
    80002698:	fd379be3          	bne	a5,s3,8000266e <wakeup+0x2e>
    8000269c:	709c                	ld	a5,32(s1)
    8000269e:	fd4798e3          	bne	a5,s4,8000266e <wakeup+0x2e>
    800026a2:	b7e1                	j	8000266a <wakeup+0x2a>
    }
  }
}
    800026a4:	70e2                	ld	ra,56(sp)
    800026a6:	7442                	ld	s0,48(sp)
    800026a8:	74a2                	ld	s1,40(sp)
    800026aa:	7902                	ld	s2,32(sp)
    800026ac:	69e2                	ld	s3,24(sp)
    800026ae:	6a42                	ld	s4,16(sp)
    800026b0:	6aa2                	ld	s5,8(sp)
    800026b2:	6121                	addi	sp,sp,64
    800026b4:	8082                	ret

00000000800026b6 <reparent>:
{
    800026b6:	7179                	addi	sp,sp,-48
    800026b8:	f406                	sd	ra,40(sp)
    800026ba:	f022                	sd	s0,32(sp)
    800026bc:	ec26                	sd	s1,24(sp)
    800026be:	e84a                	sd	s2,16(sp)
    800026c0:	e44e                	sd	s3,8(sp)
    800026c2:	e052                	sd	s4,0(sp)
    800026c4:	1800                	addi	s0,sp,48
    800026c6:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800026c8:	00016497          	auipc	s1,0x16
    800026cc:	14048493          	addi	s1,s1,320 # 80018808 <proc>
      pp->parent = initproc;
    800026d0:	0000da17          	auipc	s4,0xd
    800026d4:	068a0a13          	addi	s4,s4,104 # 8000f738 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800026d8:	0001e997          	auipc	s3,0x1e
    800026dc:	13098993          	addi	s3,s3,304 # 80020808 <tickslock>
    800026e0:	a029                	j	800026ea <reparent+0x34>
    800026e2:	20048493          	addi	s1,s1,512
    800026e6:	01348d63          	beq	s1,s3,80002700 <reparent+0x4a>
    if (pp->parent == p)
    800026ea:	7c9c                	ld	a5,56(s1)
    800026ec:	ff279be3          	bne	a5,s2,800026e2 <reparent+0x2c>
      pp->parent = initproc;
    800026f0:	000a3503          	ld	a0,0(s4)
    800026f4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800026f6:	00000097          	auipc	ra,0x0
    800026fa:	f4a080e7          	jalr	-182(ra) # 80002640 <wakeup>
    800026fe:	b7d5                	j	800026e2 <reparent+0x2c>
}
    80002700:	70a2                	ld	ra,40(sp)
    80002702:	7402                	ld	s0,32(sp)
    80002704:	64e2                	ld	s1,24(sp)
    80002706:	6942                	ld	s2,16(sp)
    80002708:	69a2                	ld	s3,8(sp)
    8000270a:	6a02                	ld	s4,0(sp)
    8000270c:	6145                	addi	sp,sp,48
    8000270e:	8082                	ret

0000000080002710 <exit>:
{
    80002710:	7179                	addi	sp,sp,-48
    80002712:	f406                	sd	ra,40(sp)
    80002714:	f022                	sd	s0,32(sp)
    80002716:	ec26                	sd	s1,24(sp)
    80002718:	e84a                	sd	s2,16(sp)
    8000271a:	e44e                	sd	s3,8(sp)
    8000271c:	e052                	sd	s4,0(sp)
    8000271e:	1800                	addi	s0,sp,48
    80002720:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002722:	fffff097          	auipc	ra,0xfffff
    80002726:	40a080e7          	jalr	1034(ra) # 80001b2c <myproc>
    8000272a:	89aa                	mv	s3,a0
  if (p == initproc)
    8000272c:	0000d797          	auipc	a5,0xd
    80002730:	00c7b783          	ld	a5,12(a5) # 8000f738 <initproc>
    80002734:	0d050493          	addi	s1,a0,208
    80002738:	15050913          	addi	s2,a0,336
    8000273c:	02a79363          	bne	a5,a0,80002762 <exit+0x52>
    panic("init exiting");
    80002740:	00006517          	auipc	a0,0x6
    80002744:	b6850513          	addi	a0,a0,-1176 # 800082a8 <digits+0x268>
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	dfc080e7          	jalr	-516(ra) # 80000544 <panic>
      fileclose(f);
    80002750:	00002097          	auipc	ra,0x2
    80002754:	6dc080e7          	jalr	1756(ra) # 80004e2c <fileclose>
      p->ofile[fd] = 0;
    80002758:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000275c:	04a1                	addi	s1,s1,8
    8000275e:	01248563          	beq	s1,s2,80002768 <exit+0x58>
    if (p->ofile[fd])
    80002762:	6088                	ld	a0,0(s1)
    80002764:	f575                	bnez	a0,80002750 <exit+0x40>
    80002766:	bfdd                	j	8000275c <exit+0x4c>
  begin_op();
    80002768:	00002097          	auipc	ra,0x2
    8000276c:	1f8080e7          	jalr	504(ra) # 80004960 <begin_op>
  iput(p->cwd);
    80002770:	1509b503          	ld	a0,336(s3)
    80002774:	00002097          	auipc	ra,0x2
    80002778:	9e4080e7          	jalr	-1564(ra) # 80004158 <iput>
  end_op();
    8000277c:	00002097          	auipc	ra,0x2
    80002780:	264080e7          	jalr	612(ra) # 800049e0 <end_op>
  p->cwd = 0;
    80002784:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002788:	00015497          	auipc	s1,0x15
    8000278c:	24048493          	addi	s1,s1,576 # 800179c8 <wait_lock>
    80002790:	8526                	mv	a0,s1
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	458080e7          	jalr	1112(ra) # 80000bea <acquire>
  reparent(p);
    8000279a:	854e                	mv	a0,s3
    8000279c:	00000097          	auipc	ra,0x0
    800027a0:	f1a080e7          	jalr	-230(ra) # 800026b6 <reparent>
  wakeup(p->parent);
    800027a4:	0389b503          	ld	a0,56(s3)
    800027a8:	00000097          	auipc	ra,0x0
    800027ac:	e98080e7          	jalr	-360(ra) # 80002640 <wakeup>
  acquire(&p->lock);
    800027b0:	854e                	mv	a0,s3
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	438080e7          	jalr	1080(ra) # 80000bea <acquire>
  p->xstate = status;
    800027ba:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800027be:	4795                	li	a5,5
    800027c0:	00f9ac23          	sw	a5,24(s3)
  p->exit_time = ticks;
    800027c4:	0000d797          	auipc	a5,0xd
    800027c8:	f7c7e783          	lwu	a5,-132(a5) # 8000f740 <ticks>
    800027cc:	18f9b423          	sd	a5,392(s3)
  release(&wait_lock);
    800027d0:	8526                	mv	a0,s1
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	4cc080e7          	jalr	1228(ra) # 80000c9e <release>
  sched();
    800027da:	00000097          	auipc	ra,0x0
    800027de:	a00080e7          	jalr	-1536(ra) # 800021da <sched>
  panic("zombie exit");
    800027e2:	00006517          	auipc	a0,0x6
    800027e6:	ad650513          	addi	a0,a0,-1322 # 800082b8 <digits+0x278>
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	d5a080e7          	jalr	-678(ra) # 80000544 <panic>

00000000800027f2 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800027f2:	7179                	addi	sp,sp,-48
    800027f4:	f406                	sd	ra,40(sp)
    800027f6:	f022                	sd	s0,32(sp)
    800027f8:	ec26                	sd	s1,24(sp)
    800027fa:	e84a                	sd	s2,16(sp)
    800027fc:	e44e                	sd	s3,8(sp)
    800027fe:	1800                	addi	s0,sp,48
    80002800:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002802:	00016497          	auipc	s1,0x16
    80002806:	00648493          	addi	s1,s1,6 # 80018808 <proc>
    8000280a:	0001e997          	auipc	s3,0x1e
    8000280e:	ffe98993          	addi	s3,s3,-2 # 80020808 <tickslock>
  {
    acquire(&p->lock);
    80002812:	8526                	mv	a0,s1
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	3d6080e7          	jalr	982(ra) # 80000bea <acquire>
    if (p->pid == pid)
    8000281c:	589c                	lw	a5,48(s1)
    8000281e:	01278d63          	beq	a5,s2,80002838 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002822:	8526                	mv	a0,s1
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	47a080e7          	jalr	1146(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000282c:	20048493          	addi	s1,s1,512
    80002830:	ff3491e3          	bne	s1,s3,80002812 <kill+0x20>
  }
  return -1;
    80002834:	557d                	li	a0,-1
    80002836:	a829                	j	80002850 <kill+0x5e>
      p->killed = 1;
    80002838:	4785                	li	a5,1
    8000283a:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000283c:	4c98                	lw	a4,24(s1)
    8000283e:	4789                	li	a5,2
    80002840:	00f70f63          	beq	a4,a5,8000285e <kill+0x6c>
      release(&p->lock);
    80002844:	8526                	mv	a0,s1
    80002846:	ffffe097          	auipc	ra,0xffffe
    8000284a:	458080e7          	jalr	1112(ra) # 80000c9e <release>
      return 0;
    8000284e:	4501                	li	a0,0
}
    80002850:	70a2                	ld	ra,40(sp)
    80002852:	7402                	ld	s0,32(sp)
    80002854:	64e2                	ld	s1,24(sp)
    80002856:	6942                	ld	s2,16(sp)
    80002858:	69a2                	ld	s3,8(sp)
    8000285a:	6145                	addi	sp,sp,48
    8000285c:	8082                	ret
        p->state = RUNNABLE;
    8000285e:	478d                	li	a5,3
    80002860:	cc9c                	sw	a5,24(s1)
    80002862:	b7cd                	j	80002844 <kill+0x52>

0000000080002864 <setkilled>:

void setkilled(struct proc *p)
{
    80002864:	1101                	addi	sp,sp,-32
    80002866:	ec06                	sd	ra,24(sp)
    80002868:	e822                	sd	s0,16(sp)
    8000286a:	e426                	sd	s1,8(sp)
    8000286c:	1000                	addi	s0,sp,32
    8000286e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	37a080e7          	jalr	890(ra) # 80000bea <acquire>
  p->killed = 1;
    80002878:	4785                	li	a5,1
    8000287a:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000287c:	8526                	mv	a0,s1
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	420080e7          	jalr	1056(ra) # 80000c9e <release>
}
    80002886:	60e2                	ld	ra,24(sp)
    80002888:	6442                	ld	s0,16(sp)
    8000288a:	64a2                	ld	s1,8(sp)
    8000288c:	6105                	addi	sp,sp,32
    8000288e:	8082                	ret

0000000080002890 <killed>:

int killed(struct proc *p)
{
    80002890:	1101                	addi	sp,sp,-32
    80002892:	ec06                	sd	ra,24(sp)
    80002894:	e822                	sd	s0,16(sp)
    80002896:	e426                	sd	s1,8(sp)
    80002898:	e04a                	sd	s2,0(sp)
    8000289a:	1000                	addi	s0,sp,32
    8000289c:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000289e:	ffffe097          	auipc	ra,0xffffe
    800028a2:	34c080e7          	jalr	844(ra) # 80000bea <acquire>
  k = p->killed;
    800028a6:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800028aa:	8526                	mv	a0,s1
    800028ac:	ffffe097          	auipc	ra,0xffffe
    800028b0:	3f2080e7          	jalr	1010(ra) # 80000c9e <release>
  return k;
}
    800028b4:	854a                	mv	a0,s2
    800028b6:	60e2                	ld	ra,24(sp)
    800028b8:	6442                	ld	s0,16(sp)
    800028ba:	64a2                	ld	s1,8(sp)
    800028bc:	6902                	ld	s2,0(sp)
    800028be:	6105                	addi	sp,sp,32
    800028c0:	8082                	ret

00000000800028c2 <wait>:
{
    800028c2:	715d                	addi	sp,sp,-80
    800028c4:	e486                	sd	ra,72(sp)
    800028c6:	e0a2                	sd	s0,64(sp)
    800028c8:	fc26                	sd	s1,56(sp)
    800028ca:	f84a                	sd	s2,48(sp)
    800028cc:	f44e                	sd	s3,40(sp)
    800028ce:	f052                	sd	s4,32(sp)
    800028d0:	ec56                	sd	s5,24(sp)
    800028d2:	e85a                	sd	s6,16(sp)
    800028d4:	e45e                	sd	s7,8(sp)
    800028d6:	e062                	sd	s8,0(sp)
    800028d8:	0880                	addi	s0,sp,80
    800028da:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800028dc:	fffff097          	auipc	ra,0xfffff
    800028e0:	250080e7          	jalr	592(ra) # 80001b2c <myproc>
    800028e4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800028e6:	00015517          	auipc	a0,0x15
    800028ea:	0e250513          	addi	a0,a0,226 # 800179c8 <wait_lock>
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	2fc080e7          	jalr	764(ra) # 80000bea <acquire>
    havekids = 0;
    800028f6:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800028f8:	4a15                	li	s4,5
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800028fa:	0001e997          	auipc	s3,0x1e
    800028fe:	f0e98993          	addi	s3,s3,-242 # 80020808 <tickslock>
        havekids = 1;
    80002902:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002904:	00015c17          	auipc	s8,0x15
    80002908:	0c4c0c13          	addi	s8,s8,196 # 800179c8 <wait_lock>
    havekids = 0;
    8000290c:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000290e:	00016497          	auipc	s1,0x16
    80002912:	efa48493          	addi	s1,s1,-262 # 80018808 <proc>
    80002916:	a0bd                	j	80002984 <wait+0xc2>
          pid = pp->pid;
    80002918:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000291c:	000b0e63          	beqz	s6,80002938 <wait+0x76>
    80002920:	4691                	li	a3,4
    80002922:	02c48613          	addi	a2,s1,44
    80002926:	85da                	mv	a1,s6
    80002928:	05093503          	ld	a0,80(s2)
    8000292c:	fffff097          	auipc	ra,0xfffff
    80002930:	d58080e7          	jalr	-680(ra) # 80001684 <copyout>
    80002934:	02054563          	bltz	a0,8000295e <wait+0x9c>
          freeproc(pp);
    80002938:	8526                	mv	a0,s1
    8000293a:	fffff097          	auipc	ra,0xfffff
    8000293e:	3a4080e7          	jalr	932(ra) # 80001cde <freeproc>
          release(&pp->lock);
    80002942:	8526                	mv	a0,s1
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	35a080e7          	jalr	858(ra) # 80000c9e <release>
          release(&wait_lock);
    8000294c:	00015517          	auipc	a0,0x15
    80002950:	07c50513          	addi	a0,a0,124 # 800179c8 <wait_lock>
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	34a080e7          	jalr	842(ra) # 80000c9e <release>
          return pid;
    8000295c:	a0b5                	j	800029c8 <wait+0x106>
            release(&pp->lock);
    8000295e:	8526                	mv	a0,s1
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	33e080e7          	jalr	830(ra) # 80000c9e <release>
            release(&wait_lock);
    80002968:	00015517          	auipc	a0,0x15
    8000296c:	06050513          	addi	a0,a0,96 # 800179c8 <wait_lock>
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	32e080e7          	jalr	814(ra) # 80000c9e <release>
            return -1;
    80002978:	59fd                	li	s3,-1
    8000297a:	a0b9                	j	800029c8 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000297c:	20048493          	addi	s1,s1,512
    80002980:	03348463          	beq	s1,s3,800029a8 <wait+0xe6>
      if (pp->parent == p)
    80002984:	7c9c                	ld	a5,56(s1)
    80002986:	ff279be3          	bne	a5,s2,8000297c <wait+0xba>
        acquire(&pp->lock);
    8000298a:	8526                	mv	a0,s1
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	25e080e7          	jalr	606(ra) # 80000bea <acquire>
        if (pp->state == ZOMBIE)
    80002994:	4c9c                	lw	a5,24(s1)
    80002996:	f94781e3          	beq	a5,s4,80002918 <wait+0x56>
        release(&pp->lock);
    8000299a:	8526                	mv	a0,s1
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	302080e7          	jalr	770(ra) # 80000c9e <release>
        havekids = 1;
    800029a4:	8756                	mv	a4,s5
    800029a6:	bfd9                	j	8000297c <wait+0xba>
    if (!havekids || killed(p))
    800029a8:	c719                	beqz	a4,800029b6 <wait+0xf4>
    800029aa:	854a                	mv	a0,s2
    800029ac:	00000097          	auipc	ra,0x0
    800029b0:	ee4080e7          	jalr	-284(ra) # 80002890 <killed>
    800029b4:	c51d                	beqz	a0,800029e2 <wait+0x120>
      release(&wait_lock);
    800029b6:	00015517          	auipc	a0,0x15
    800029ba:	01250513          	addi	a0,a0,18 # 800179c8 <wait_lock>
    800029be:	ffffe097          	auipc	ra,0xffffe
    800029c2:	2e0080e7          	jalr	736(ra) # 80000c9e <release>
      return -1;
    800029c6:	59fd                	li	s3,-1
}
    800029c8:	854e                	mv	a0,s3
    800029ca:	60a6                	ld	ra,72(sp)
    800029cc:	6406                	ld	s0,64(sp)
    800029ce:	74e2                	ld	s1,56(sp)
    800029d0:	7942                	ld	s2,48(sp)
    800029d2:	79a2                	ld	s3,40(sp)
    800029d4:	7a02                	ld	s4,32(sp)
    800029d6:	6ae2                	ld	s5,24(sp)
    800029d8:	6b42                	ld	s6,16(sp)
    800029da:	6ba2                	ld	s7,8(sp)
    800029dc:	6c02                	ld	s8,0(sp)
    800029de:	6161                	addi	sp,sp,80
    800029e0:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800029e2:	85e2                	mv	a1,s8
    800029e4:	854a                	mv	a0,s2
    800029e6:	00000097          	auipc	ra,0x0
    800029ea:	aa6080e7          	jalr	-1370(ra) # 8000248c <sleep>
    havekids = 0;
    800029ee:	bf39                	j	8000290c <wait+0x4a>

00000000800029f0 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029f0:	7179                	addi	sp,sp,-48
    800029f2:	f406                	sd	ra,40(sp)
    800029f4:	f022                	sd	s0,32(sp)
    800029f6:	ec26                	sd	s1,24(sp)
    800029f8:	e84a                	sd	s2,16(sp)
    800029fa:	e44e                	sd	s3,8(sp)
    800029fc:	e052                	sd	s4,0(sp)
    800029fe:	1800                	addi	s0,sp,48
    80002a00:	84aa                	mv	s1,a0
    80002a02:	892e                	mv	s2,a1
    80002a04:	89b2                	mv	s3,a2
    80002a06:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a08:	fffff097          	auipc	ra,0xfffff
    80002a0c:	124080e7          	jalr	292(ra) # 80001b2c <myproc>
  if (user_dst)
    80002a10:	c08d                	beqz	s1,80002a32 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002a12:	86d2                	mv	a3,s4
    80002a14:	864e                	mv	a2,s3
    80002a16:	85ca                	mv	a1,s2
    80002a18:	6928                	ld	a0,80(a0)
    80002a1a:	fffff097          	auipc	ra,0xfffff
    80002a1e:	c6a080e7          	jalr	-918(ra) # 80001684 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002a22:	70a2                	ld	ra,40(sp)
    80002a24:	7402                	ld	s0,32(sp)
    80002a26:	64e2                	ld	s1,24(sp)
    80002a28:	6942                	ld	s2,16(sp)
    80002a2a:	69a2                	ld	s3,8(sp)
    80002a2c:	6a02                	ld	s4,0(sp)
    80002a2e:	6145                	addi	sp,sp,48
    80002a30:	8082                	ret
    memmove((char *)dst, src, len);
    80002a32:	000a061b          	sext.w	a2,s4
    80002a36:	85ce                	mv	a1,s3
    80002a38:	854a                	mv	a0,s2
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	30c080e7          	jalr	780(ra) # 80000d46 <memmove>
    return 0;
    80002a42:	8526                	mv	a0,s1
    80002a44:	bff9                	j	80002a22 <either_copyout+0x32>

0000000080002a46 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a46:	7179                	addi	sp,sp,-48
    80002a48:	f406                	sd	ra,40(sp)
    80002a4a:	f022                	sd	s0,32(sp)
    80002a4c:	ec26                	sd	s1,24(sp)
    80002a4e:	e84a                	sd	s2,16(sp)
    80002a50:	e44e                	sd	s3,8(sp)
    80002a52:	e052                	sd	s4,0(sp)
    80002a54:	1800                	addi	s0,sp,48
    80002a56:	892a                	mv	s2,a0
    80002a58:	84ae                	mv	s1,a1
    80002a5a:	89b2                	mv	s3,a2
    80002a5c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a5e:	fffff097          	auipc	ra,0xfffff
    80002a62:	0ce080e7          	jalr	206(ra) # 80001b2c <myproc>
  if (user_src)
    80002a66:	c08d                	beqz	s1,80002a88 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002a68:	86d2                	mv	a3,s4
    80002a6a:	864e                	mv	a2,s3
    80002a6c:	85ca                	mv	a1,s2
    80002a6e:	6928                	ld	a0,80(a0)
    80002a70:	fffff097          	auipc	ra,0xfffff
    80002a74:	ca0080e7          	jalr	-864(ra) # 80001710 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002a78:	70a2                	ld	ra,40(sp)
    80002a7a:	7402                	ld	s0,32(sp)
    80002a7c:	64e2                	ld	s1,24(sp)
    80002a7e:	6942                	ld	s2,16(sp)
    80002a80:	69a2                	ld	s3,8(sp)
    80002a82:	6a02                	ld	s4,0(sp)
    80002a84:	6145                	addi	sp,sp,48
    80002a86:	8082                	ret
    memmove(dst, (char *)src, len);
    80002a88:	000a061b          	sext.w	a2,s4
    80002a8c:	85ce                	mv	a1,s3
    80002a8e:	854a                	mv	a0,s2
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	2b6080e7          	jalr	694(ra) # 80000d46 <memmove>
    return 0;
    80002a98:	8526                	mv	a0,s1
    80002a9a:	bff9                	j	80002a78 <either_copyin+0x32>

0000000080002a9c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002a9c:	715d                	addi	sp,sp,-80
    80002a9e:	e486                	sd	ra,72(sp)
    80002aa0:	e0a2                	sd	s0,64(sp)
    80002aa2:	fc26                	sd	s1,56(sp)
    80002aa4:	f84a                	sd	s2,48(sp)
    80002aa6:	f44e                	sd	s3,40(sp)
    80002aa8:	f052                	sd	s4,32(sp)
    80002aaa:	ec56                	sd	s5,24(sp)
    80002aac:	e85a                	sd	s6,16(sp)
    80002aae:	e45e                	sd	s7,8(sp)
    80002ab0:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002ab2:	00005517          	auipc	a0,0x5
    80002ab6:	61650513          	addi	a0,a0,1558 # 800080c8 <digits+0x88>
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	ad4080e7          	jalr	-1324(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002ac2:	00016497          	auipc	s1,0x16
    80002ac6:	e9e48493          	addi	s1,s1,-354 # 80018960 <proc+0x158>
    80002aca:	0001e917          	auipc	s2,0x1e
    80002ace:	e9690913          	addi	s2,s2,-362 # 80020960 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ad2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002ad4:	00005997          	auipc	s3,0x5
    80002ad8:	7f498993          	addi	s3,s3,2036 # 800082c8 <digits+0x288>
    printf("%d %s %s", p->pid, state, p->name);
    80002adc:	00005a97          	auipc	s5,0x5
    80002ae0:	7f4a8a93          	addi	s5,s5,2036 # 800082d0 <digits+0x290>
    printf("\n");
    80002ae4:	00005a17          	auipc	s4,0x5
    80002ae8:	5e4a0a13          	addi	s4,s4,1508 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aec:	00006b97          	auipc	s7,0x6
    80002af0:	824b8b93          	addi	s7,s7,-2012 # 80008310 <states.1864>
    80002af4:	a00d                	j	80002b16 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002af6:	ed86a583          	lw	a1,-296(a3)
    80002afa:	8556                	mv	a0,s5
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	a92080e7          	jalr	-1390(ra) # 8000058e <printf>
    printf("\n");
    80002b04:	8552                	mv	a0,s4
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	a88080e7          	jalr	-1400(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002b0e:	20048493          	addi	s1,s1,512
    80002b12:	03248163          	beq	s1,s2,80002b34 <procdump+0x98>
    if (p->state == UNUSED)
    80002b16:	86a6                	mv	a3,s1
    80002b18:	ec04a783          	lw	a5,-320(s1)
    80002b1c:	dbed                	beqz	a5,80002b0e <procdump+0x72>
      state = "???";
    80002b1e:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b20:	fcfb6be3          	bltu	s6,a5,80002af6 <procdump+0x5a>
    80002b24:	1782                	slli	a5,a5,0x20
    80002b26:	9381                	srli	a5,a5,0x20
    80002b28:	078e                	slli	a5,a5,0x3
    80002b2a:	97de                	add	a5,a5,s7
    80002b2c:	6390                	ld	a2,0(a5)
    80002b2e:	f661                	bnez	a2,80002af6 <procdump+0x5a>
      state = "???";
    80002b30:	864e                	mv	a2,s3
    80002b32:	b7d1                	j	80002af6 <procdump+0x5a>
  }
}
    80002b34:	60a6                	ld	ra,72(sp)
    80002b36:	6406                	ld	s0,64(sp)
    80002b38:	74e2                	ld	s1,56(sp)
    80002b3a:	7942                	ld	s2,48(sp)
    80002b3c:	79a2                	ld	s3,40(sp)
    80002b3e:	7a02                	ld	s4,32(sp)
    80002b40:	6ae2                	ld	s5,24(sp)
    80002b42:	6b42                	ld	s6,16(sp)
    80002b44:	6ba2                	ld	s7,8(sp)
    80002b46:	6161                	addi	sp,sp,80
    80002b48:	8082                	ret

0000000080002b4a <swtch>:
    80002b4a:	00153023          	sd	ra,0(a0)
    80002b4e:	00253423          	sd	sp,8(a0)
    80002b52:	e900                	sd	s0,16(a0)
    80002b54:	ed04                	sd	s1,24(a0)
    80002b56:	03253023          	sd	s2,32(a0)
    80002b5a:	03353423          	sd	s3,40(a0)
    80002b5e:	03453823          	sd	s4,48(a0)
    80002b62:	03553c23          	sd	s5,56(a0)
    80002b66:	05653023          	sd	s6,64(a0)
    80002b6a:	05753423          	sd	s7,72(a0)
    80002b6e:	05853823          	sd	s8,80(a0)
    80002b72:	05953c23          	sd	s9,88(a0)
    80002b76:	07a53023          	sd	s10,96(a0)
    80002b7a:	07b53423          	sd	s11,104(a0)
    80002b7e:	0005b083          	ld	ra,0(a1)
    80002b82:	0085b103          	ld	sp,8(a1)
    80002b86:	6980                	ld	s0,16(a1)
    80002b88:	6d84                	ld	s1,24(a1)
    80002b8a:	0205b903          	ld	s2,32(a1)
    80002b8e:	0285b983          	ld	s3,40(a1)
    80002b92:	0305ba03          	ld	s4,48(a1)
    80002b96:	0385ba83          	ld	s5,56(a1)
    80002b9a:	0405bb03          	ld	s6,64(a1)
    80002b9e:	0485bb83          	ld	s7,72(a1)
    80002ba2:	0505bc03          	ld	s8,80(a1)
    80002ba6:	0585bc83          	ld	s9,88(a1)
    80002baa:	0605bd03          	ld	s10,96(a1)
    80002bae:	0685bd83          	ld	s11,104(a1)
    80002bb2:	8082                	ret

0000000080002bb4 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002bb4:	1141                	addi	sp,sp,-16
    80002bb6:	e406                	sd	ra,8(sp)
    80002bb8:	e022                	sd	s0,0(sp)
    80002bba:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002bbc:	00005597          	auipc	a1,0x5
    80002bc0:	78458593          	addi	a1,a1,1924 # 80008340 <states.1864+0x30>
    80002bc4:	0001e517          	auipc	a0,0x1e
    80002bc8:	c4450513          	addi	a0,a0,-956 # 80020808 <tickslock>
    80002bcc:	ffffe097          	auipc	ra,0xffffe
    80002bd0:	f8e080e7          	jalr	-114(ra) # 80000b5a <initlock>
}
    80002bd4:	60a2                	ld	ra,8(sp)
    80002bd6:	6402                	ld	s0,0(sp)
    80002bd8:	0141                	addi	sp,sp,16
    80002bda:	8082                	ret

0000000080002bdc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002bdc:	1141                	addi	sp,sp,-16
    80002bde:	e422                	sd	s0,8(sp)
    80002be0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002be2:	00004797          	auipc	a5,0x4
    80002be6:	88e78793          	addi	a5,a5,-1906 # 80006470 <kernelvec>
    80002bea:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bee:	6422                	ld	s0,8(sp)
    80002bf0:	0141                	addi	sp,sp,16
    80002bf2:	8082                	ret

0000000080002bf4 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002bf4:	1141                	addi	sp,sp,-16
    80002bf6:	e406                	sd	ra,8(sp)
    80002bf8:	e022                	sd	s0,0(sp)
    80002bfa:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bfc:	fffff097          	auipc	ra,0xfffff
    80002c00:	f30080e7          	jalr	-208(ra) # 80001b2c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c04:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c08:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c0a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002c0e:	00004617          	auipc	a2,0x4
    80002c12:	3f260613          	addi	a2,a2,1010 # 80007000 <_trampoline>
    80002c16:	00004697          	auipc	a3,0x4
    80002c1a:	3ea68693          	addi	a3,a3,1002 # 80007000 <_trampoline>
    80002c1e:	8e91                	sub	a3,a3,a2
    80002c20:	040007b7          	lui	a5,0x4000
    80002c24:	17fd                	addi	a5,a5,-1
    80002c26:	07b2                	slli	a5,a5,0xc
    80002c28:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c2a:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c2e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c30:	180026f3          	csrr	a3,satp
    80002c34:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c36:	6d38                	ld	a4,88(a0)
    80002c38:	6134                	ld	a3,64(a0)
    80002c3a:	6585                	lui	a1,0x1
    80002c3c:	96ae                	add	a3,a3,a1
    80002c3e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c40:	6d38                	ld	a4,88(a0)
    80002c42:	00000697          	auipc	a3,0x0
    80002c46:	13e68693          	addi	a3,a3,318 # 80002d80 <usertrap>
    80002c4a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002c4c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c4e:	8692                	mv	a3,tp
    80002c50:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c52:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c56:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c5a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c5e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c62:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c64:	6f18                	ld	a4,24(a4)
    80002c66:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c6a:	6928                	ld	a0,80(a0)
    80002c6c:	8131                	srli	a0,a0,0xc

  // jump totrapframe userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c6e:	00004717          	auipc	a4,0x4
    80002c72:	42e70713          	addi	a4,a4,1070 # 8000709c <userret>
    80002c76:	8f11                	sub	a4,a4,a2
    80002c78:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c7a:	577d                	li	a4,-1
    80002c7c:	177e                	slli	a4,a4,0x3f
    80002c7e:	8d59                	or	a0,a0,a4
    80002c80:	9782                	jalr	a5
}
    80002c82:	60a2                	ld	ra,8(sp)
    80002c84:	6402                	ld	s0,0(sp)
    80002c86:	0141                	addi	sp,sp,16
    80002c88:	8082                	ret

0000000080002c8a <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002c8a:	1101                	addi	sp,sp,-32
    80002c8c:	ec06                	sd	ra,24(sp)
    80002c8e:	e822                	sd	s0,16(sp)
    80002c90:	e426                	sd	s1,8(sp)
    80002c92:	e04a                	sd	s2,0(sp)
    80002c94:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c96:	0001e917          	auipc	s2,0x1e
    80002c9a:	b7290913          	addi	s2,s2,-1166 # 80020808 <tickslock>
    80002c9e:	854a                	mv	a0,s2
    80002ca0:	ffffe097          	auipc	ra,0xffffe
    80002ca4:	f4a080e7          	jalr	-182(ra) # 80000bea <acquire>
  ticks++;
    80002ca8:	0000d497          	auipc	s1,0xd
    80002cac:	a9848493          	addi	s1,s1,-1384 # 8000f740 <ticks>
    80002cb0:	409c                	lw	a5,0(s1)
    80002cb2:	2785                	addiw	a5,a5,1
    80002cb4:	c09c                	sw	a5,0(s1)
  updateprocesstimes();
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	74c080e7          	jalr	1868(ra) # 80002402 <updateprocesstimes>
  wakeup(&ticks);
    80002cbe:	8526                	mv	a0,s1
    80002cc0:	00000097          	auipc	ra,0x0
    80002cc4:	980080e7          	jalr	-1664(ra) # 80002640 <wakeup>
  release(&tickslock);
    80002cc8:	854a                	mv	a0,s2
    80002cca:	ffffe097          	auipc	ra,0xffffe
    80002cce:	fd4080e7          	jalr	-44(ra) # 80000c9e <release>
}
    80002cd2:	60e2                	ld	ra,24(sp)
    80002cd4:	6442                	ld	s0,16(sp)
    80002cd6:	64a2                	ld	s1,8(sp)
    80002cd8:	6902                	ld	s2,0(sp)
    80002cda:	6105                	addi	sp,sp,32
    80002cdc:	8082                	ret

0000000080002cde <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002cde:	1101                	addi	sp,sp,-32
    80002ce0:	ec06                	sd	ra,24(sp)
    80002ce2:	e822                	sd	s0,16(sp)
    80002ce4:	e426                	sd	s1,8(sp)
    80002ce6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ce8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002cec:	00074d63          	bltz	a4,80002d06 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002cf0:	57fd                	li	a5,-1
    80002cf2:	17fe                	slli	a5,a5,0x3f
    80002cf4:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002cf6:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002cf8:	06f70363          	beq	a4,a5,80002d5e <devintr+0x80>
  }
}
    80002cfc:	60e2                	ld	ra,24(sp)
    80002cfe:	6442                	ld	s0,16(sp)
    80002d00:	64a2                	ld	s1,8(sp)
    80002d02:	6105                	addi	sp,sp,32
    80002d04:	8082                	ret
      (scause & 0xff) == 9)
    80002d06:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002d0a:	46a5                	li	a3,9
    80002d0c:	fed792e3          	bne	a5,a3,80002cf0 <devintr+0x12>
    int irq = plic_claim();
    80002d10:	00004097          	auipc	ra,0x4
    80002d14:	868080e7          	jalr	-1944(ra) # 80006578 <plic_claim>
    80002d18:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002d1a:	47a9                	li	a5,10
    80002d1c:	02f50763          	beq	a0,a5,80002d4a <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002d20:	4785                	li	a5,1
    80002d22:	02f50963          	beq	a0,a5,80002d54 <devintr+0x76>
    return 1;
    80002d26:	4505                	li	a0,1
    else if (irq)
    80002d28:	d8f1                	beqz	s1,80002cfc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d2a:	85a6                	mv	a1,s1
    80002d2c:	00005517          	auipc	a0,0x5
    80002d30:	61c50513          	addi	a0,a0,1564 # 80008348 <states.1864+0x38>
    80002d34:	ffffe097          	auipc	ra,0xffffe
    80002d38:	85a080e7          	jalr	-1958(ra) # 8000058e <printf>
      plic_complete(irq);
    80002d3c:	8526                	mv	a0,s1
    80002d3e:	00004097          	auipc	ra,0x4
    80002d42:	85e080e7          	jalr	-1954(ra) # 8000659c <plic_complete>
    return 1;
    80002d46:	4505                	li	a0,1
    80002d48:	bf55                	j	80002cfc <devintr+0x1e>
      uartintr();
    80002d4a:	ffffe097          	auipc	ra,0xffffe
    80002d4e:	c64080e7          	jalr	-924(ra) # 800009ae <uartintr>
    80002d52:	b7ed                	j	80002d3c <devintr+0x5e>
      virtio_disk_intr();
    80002d54:	00004097          	auipc	ra,0x4
    80002d58:	d72080e7          	jalr	-654(ra) # 80006ac6 <virtio_disk_intr>
    80002d5c:	b7c5                	j	80002d3c <devintr+0x5e>
    if (cpuid() == 0)
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	da2080e7          	jalr	-606(ra) # 80001b00 <cpuid>
    80002d66:	c901                	beqz	a0,80002d76 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d68:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d6c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d6e:	14479073          	csrw	sip,a5
    return 2;
    80002d72:	4509                	li	a0,2
    80002d74:	b761                	j	80002cfc <devintr+0x1e>
      clockintr();
    80002d76:	00000097          	auipc	ra,0x0
    80002d7a:	f14080e7          	jalr	-236(ra) # 80002c8a <clockintr>
    80002d7e:	b7ed                	j	80002d68 <devintr+0x8a>

0000000080002d80 <usertrap>:
{
    80002d80:	1101                	addi	sp,sp,-32
    80002d82:	ec06                	sd	ra,24(sp)
    80002d84:	e822                	sd	s0,16(sp)
    80002d86:	e426                	sd	s1,8(sp)
    80002d88:	e04a                	sd	s2,0(sp)
    80002d8a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d8c:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002d90:	1007f793          	andi	a5,a5,256
    80002d94:	e3b1                	bnez	a5,80002dd8 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d96:	00003797          	auipc	a5,0x3
    80002d9a:	6da78793          	addi	a5,a5,1754 # 80006470 <kernelvec>
    80002d9e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	d8a080e7          	jalr	-630(ra) # 80001b2c <myproc>
    80002daa:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002dac:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dae:	14102773          	csrr	a4,sepc
    80002db2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002db4:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002db8:	47a1                	li	a5,8
    80002dba:	02f70763          	beq	a4,a5,80002de8 <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80002dbe:	00000097          	auipc	ra,0x0
    80002dc2:	f20080e7          	jalr	-224(ra) # 80002cde <devintr>
    80002dc6:	892a                	mv	s2,a0
    80002dc8:	c151                	beqz	a0,80002e4c <usertrap+0xcc>
  if (killed(p))
    80002dca:	8526                	mv	a0,s1
    80002dcc:	00000097          	auipc	ra,0x0
    80002dd0:	ac4080e7          	jalr	-1340(ra) # 80002890 <killed>
    80002dd4:	c929                	beqz	a0,80002e26 <usertrap+0xa6>
    80002dd6:	a099                	j	80002e1c <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002dd8:	00005517          	auipc	a0,0x5
    80002ddc:	59050513          	addi	a0,a0,1424 # 80008368 <states.1864+0x58>
    80002de0:	ffffd097          	auipc	ra,0xffffd
    80002de4:	764080e7          	jalr	1892(ra) # 80000544 <panic>
    if (killed(p))
    80002de8:	00000097          	auipc	ra,0x0
    80002dec:	aa8080e7          	jalr	-1368(ra) # 80002890 <killed>
    80002df0:	e921                	bnez	a0,80002e40 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002df2:	6cb8                	ld	a4,88(s1)
    80002df4:	6f1c                	ld	a5,24(a4)
    80002df6:	0791                	addi	a5,a5,4
    80002df8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dfa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002dfe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e02:	10079073          	csrw	sstatus,a5
    syscall();
    80002e06:	00000097          	auipc	ra,0x0
    80002e0a:	33a080e7          	jalr	826(ra) # 80003140 <syscall>
  if (killed(p))
    80002e0e:	8526                	mv	a0,s1
    80002e10:	00000097          	auipc	ra,0x0
    80002e14:	a80080e7          	jalr	-1408(ra) # 80002890 <killed>
    80002e18:	c911                	beqz	a0,80002e2c <usertrap+0xac>
    80002e1a:	4901                	li	s2,0
    exit(-1);
    80002e1c:	557d                	li	a0,-1
    80002e1e:	00000097          	auipc	ra,0x0
    80002e22:	8f2080e7          	jalr	-1806(ra) # 80002710 <exit>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e26:	4789                	li	a5,2
    80002e28:	04f90f63          	beq	s2,a5,80002e86 <usertrap+0x106>
  usertrapret();
    80002e2c:	00000097          	auipc	ra,0x0
    80002e30:	dc8080e7          	jalr	-568(ra) # 80002bf4 <usertrapret>
}
    80002e34:	60e2                	ld	ra,24(sp)
    80002e36:	6442                	ld	s0,16(sp)
    80002e38:	64a2                	ld	s1,8(sp)
    80002e3a:	6902                	ld	s2,0(sp)
    80002e3c:	6105                	addi	sp,sp,32
    80002e3e:	8082                	ret
      exit(-1);
    80002e40:	557d                	li	a0,-1
    80002e42:	00000097          	auipc	ra,0x0
    80002e46:	8ce080e7          	jalr	-1842(ra) # 80002710 <exit>
    80002e4a:	b765                	j	80002df2 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e4c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e50:	5890                	lw	a2,48(s1)
    80002e52:	00005517          	auipc	a0,0x5
    80002e56:	53650513          	addi	a0,a0,1334 # 80008388 <states.1864+0x78>
    80002e5a:	ffffd097          	auipc	ra,0xffffd
    80002e5e:	734080e7          	jalr	1844(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e62:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e66:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e6a:	00005517          	auipc	a0,0x5
    80002e6e:	54e50513          	addi	a0,a0,1358 # 800083b8 <states.1864+0xa8>
    80002e72:	ffffd097          	auipc	ra,0xffffd
    80002e76:	71c080e7          	jalr	1820(ra) # 8000058e <printf>
    setkilled(p);
    80002e7a:	8526                	mv	a0,s1
    80002e7c:	00000097          	auipc	ra,0x0
    80002e80:	9e8080e7          	jalr	-1560(ra) # 80002864 <setkilled>
    80002e84:	b769                	j	80002e0e <usertrap+0x8e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e86:	fffff097          	auipc	ra,0xfffff
    80002e8a:	ca6080e7          	jalr	-858(ra) # 80001b2c <myproc>
    80002e8e:	dd59                	beqz	a0,80002e2c <usertrap+0xac>
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	c9c080e7          	jalr	-868(ra) # 80001b2c <myproc>
    80002e98:	4d18                	lw	a4,24(a0)
    80002e9a:	4791                	li	a5,4
    80002e9c:	f8f718e3          	bne	a4,a5,80002e2c <usertrap+0xac>
    if(p->tickswhenalarmisoff == -1) p->tickswhenalarmison++;
    80002ea0:	1e84b783          	ld	a5,488(s1)
    80002ea4:	577d                	li	a4,-1
    80002ea6:	04e78163          	beq	a5,a4,80002ee8 <usertrap+0x168>
    else p->tickswhenalarmisoff++;
    80002eaa:	0785                	addi	a5,a5,1
    80002eac:	1ef4b423          	sd	a5,488(s1)
    if(p->tickswhenalarmisoff >= 0)
    80002eb0:	f607cee3          	bltz	a5,80002e2c <usertrap+0xac>
      p->savingthetrapframe = kalloc();
    80002eb4:	ffffe097          	auipc	ra,0xffffe
    80002eb8:	c46080e7          	jalr	-954(ra) # 80000afa <kalloc>
    80002ebc:	1ea4bc23          	sd	a0,504(s1)
      memmove(p->savingthetrapframe, p->trapframe, PGSIZE);
    80002ec0:	6605                	lui	a2,0x1
    80002ec2:	6cac                	ld	a1,88(s1)
    80002ec4:	ffffe097          	auipc	ra,0xffffe
    80002ec8:	e82080e7          	jalr	-382(ra) # 80000d46 <memmove>
      if(p->tickswhenalarmisoff >= p->counttointerrupt)
    80002ecc:	1d84a783          	lw	a5,472(s1)
    80002ed0:	1e84b703          	ld	a4,488(s1)
    80002ed4:	f4f74ce3          	blt	a4,a5,80002e2c <usertrap+0xac>
        p->trapframe->epc = p->specificfn;
    80002ed8:	6cbc                	ld	a5,88(s1)
    80002eda:	1f04a703          	lw	a4,496(s1)
    80002ede:	ef98                	sd	a4,24(a5)
        p->tickswhenalarmisoff = -1; 
    80002ee0:	57fd                	li	a5,-1
    80002ee2:	1ef4b423          	sd	a5,488(s1)
    80002ee6:	b799                	j	80002e2c <usertrap+0xac>
    if(p->tickswhenalarmisoff == -1) p->tickswhenalarmison++;
    80002ee8:	1e04b783          	ld	a5,480(s1)
    80002eec:	0785                	addi	a5,a5,1
    80002eee:	1ef4b023          	sd	a5,480(s1)
    if(p->tickswhenalarmisoff >= 0)
    80002ef2:	bf2d                	j	80002e2c <usertrap+0xac>

0000000080002ef4 <kerneltrap>:
{
    80002ef4:	7179                	addi	sp,sp,-48
    80002ef6:	f406                	sd	ra,40(sp)
    80002ef8:	f022                	sd	s0,32(sp)
    80002efa:	ec26                	sd	s1,24(sp)
    80002efc:	e84a                	sd	s2,16(sp)
    80002efe:	e44e                	sd	s3,8(sp)
    80002f00:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f02:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f06:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f0a:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002f0e:	1004f793          	andi	a5,s1,256
    80002f12:	cb85                	beqz	a5,80002f42 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f14:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f18:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002f1a:	ef85                	bnez	a5,80002f52 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002f1c:	00000097          	auipc	ra,0x0
    80002f20:	dc2080e7          	jalr	-574(ra) # 80002cde <devintr>
    80002f24:	cd1d                	beqz	a0,80002f62 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f26:	4789                	li	a5,2
    80002f28:	06f50a63          	beq	a0,a5,80002f9c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f2c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f30:	10049073          	csrw	sstatus,s1
}
    80002f34:	70a2                	ld	ra,40(sp)
    80002f36:	7402                	ld	s0,32(sp)
    80002f38:	64e2                	ld	s1,24(sp)
    80002f3a:	6942                	ld	s2,16(sp)
    80002f3c:	69a2                	ld	s3,8(sp)
    80002f3e:	6145                	addi	sp,sp,48
    80002f40:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f42:	00005517          	auipc	a0,0x5
    80002f46:	49650513          	addi	a0,a0,1174 # 800083d8 <states.1864+0xc8>
    80002f4a:	ffffd097          	auipc	ra,0xffffd
    80002f4e:	5fa080e7          	jalr	1530(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002f52:	00005517          	auipc	a0,0x5
    80002f56:	4ae50513          	addi	a0,a0,1198 # 80008400 <states.1864+0xf0>
    80002f5a:	ffffd097          	auipc	ra,0xffffd
    80002f5e:	5ea080e7          	jalr	1514(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002f62:	85ce                	mv	a1,s3
    80002f64:	00005517          	auipc	a0,0x5
    80002f68:	4bc50513          	addi	a0,a0,1212 # 80008420 <states.1864+0x110>
    80002f6c:	ffffd097          	auipc	ra,0xffffd
    80002f70:	622080e7          	jalr	1570(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f74:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f78:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f7c:	00005517          	auipc	a0,0x5
    80002f80:	4b450513          	addi	a0,a0,1204 # 80008430 <states.1864+0x120>
    80002f84:	ffffd097          	auipc	ra,0xffffd
    80002f88:	60a080e7          	jalr	1546(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002f8c:	00005517          	auipc	a0,0x5
    80002f90:	4bc50513          	addi	a0,a0,1212 # 80008448 <states.1864+0x138>
    80002f94:	ffffd097          	auipc	ra,0xffffd
    80002f98:	5b0080e7          	jalr	1456(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f9c:	fffff097          	auipc	ra,0xfffff
    80002fa0:	b90080e7          	jalr	-1136(ra) # 80001b2c <myproc>
    80002fa4:	d541                	beqz	a0,80002f2c <kerneltrap+0x38>
    80002fa6:	fffff097          	auipc	ra,0xfffff
    80002faa:	b86080e7          	jalr	-1146(ra) # 80001b2c <myproc>
    80002fae:	bfbd                	j	80002f2c <kerneltrap+0x38>

0000000080002fb0 <argraw>:
}


static uint64
argraw(int n)
{
    80002fb0:	1101                	addi	sp,sp,-32
    80002fb2:	ec06                	sd	ra,24(sp)
    80002fb4:	e822                	sd	s0,16(sp)
    80002fb6:	e426                	sd	s1,8(sp)
    80002fb8:	1000                	addi	s0,sp,32
    80002fba:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002fbc:	fffff097          	auipc	ra,0xfffff
    80002fc0:	b70080e7          	jalr	-1168(ra) # 80001b2c <myproc>
  switch (n) {
    80002fc4:	4795                	li	a5,5
    80002fc6:	0497e163          	bltu	a5,s1,80003008 <argraw+0x58>
    80002fca:	048a                	slli	s1,s1,0x2
    80002fcc:	00005717          	auipc	a4,0x5
    80002fd0:	4ec70713          	addi	a4,a4,1260 # 800084b8 <states.1864+0x1a8>
    80002fd4:	94ba                	add	s1,s1,a4
    80002fd6:	409c                	lw	a5,0(s1)
    80002fd8:	97ba                	add	a5,a5,a4
    80002fda:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002fdc:	6d3c                	ld	a5,88(a0)
    80002fde:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002fe0:	60e2                	ld	ra,24(sp)
    80002fe2:	6442                	ld	s0,16(sp)
    80002fe4:	64a2                	ld	s1,8(sp)
    80002fe6:	6105                	addi	sp,sp,32
    80002fe8:	8082                	ret
    return p->trapframe->a1;
    80002fea:	6d3c                	ld	a5,88(a0)
    80002fec:	7fa8                	ld	a0,120(a5)
    80002fee:	bfcd                	j	80002fe0 <argraw+0x30>
    return p->trapframe->a2;
    80002ff0:	6d3c                	ld	a5,88(a0)
    80002ff2:	63c8                	ld	a0,128(a5)
    80002ff4:	b7f5                	j	80002fe0 <argraw+0x30>
    return p->trapframe->a3;
    80002ff6:	6d3c                	ld	a5,88(a0)
    80002ff8:	67c8                	ld	a0,136(a5)
    80002ffa:	b7dd                	j	80002fe0 <argraw+0x30>
    return p->trapframe->a4;
    80002ffc:	6d3c                	ld	a5,88(a0)
    80002ffe:	6bc8                	ld	a0,144(a5)
    80003000:	b7c5                	j	80002fe0 <argraw+0x30>
    return p->trapframe->a5;
    80003002:	6d3c                	ld	a5,88(a0)
    80003004:	6fc8                	ld	a0,152(a5)
    80003006:	bfe9                	j	80002fe0 <argraw+0x30>
  panic("argraw");
    80003008:	00005517          	auipc	a0,0x5
    8000300c:	45050513          	addi	a0,a0,1104 # 80008458 <states.1864+0x148>
    80003010:	ffffd097          	auipc	ra,0xffffd
    80003014:	534080e7          	jalr	1332(ra) # 80000544 <panic>

0000000080003018 <fetchaddr>:
{
    80003018:	1101                	addi	sp,sp,-32
    8000301a:	ec06                	sd	ra,24(sp)
    8000301c:	e822                	sd	s0,16(sp)
    8000301e:	e426                	sd	s1,8(sp)
    80003020:	e04a                	sd	s2,0(sp)
    80003022:	1000                	addi	s0,sp,32
    80003024:	84aa                	mv	s1,a0
    80003026:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003028:	fffff097          	auipc	ra,0xfffff
    8000302c:	b04080e7          	jalr	-1276(ra) # 80001b2c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003030:	653c                	ld	a5,72(a0)
    80003032:	02f4f863          	bgeu	s1,a5,80003062 <fetchaddr+0x4a>
    80003036:	00848713          	addi	a4,s1,8
    8000303a:	02e7e663          	bltu	a5,a4,80003066 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000303e:	46a1                	li	a3,8
    80003040:	8626                	mv	a2,s1
    80003042:	85ca                	mv	a1,s2
    80003044:	6928                	ld	a0,80(a0)
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	6ca080e7          	jalr	1738(ra) # 80001710 <copyin>
    8000304e:	00a03533          	snez	a0,a0
    80003052:	40a00533          	neg	a0,a0
}
    80003056:	60e2                	ld	ra,24(sp)
    80003058:	6442                	ld	s0,16(sp)
    8000305a:	64a2                	ld	s1,8(sp)
    8000305c:	6902                	ld	s2,0(sp)
    8000305e:	6105                	addi	sp,sp,32
    80003060:	8082                	ret
    return -1;
    80003062:	557d                	li	a0,-1
    80003064:	bfcd                	j	80003056 <fetchaddr+0x3e>
    80003066:	557d                	li	a0,-1
    80003068:	b7fd                	j	80003056 <fetchaddr+0x3e>

000000008000306a <fetchstr>:
{
    8000306a:	7179                	addi	sp,sp,-48
    8000306c:	f406                	sd	ra,40(sp)
    8000306e:	f022                	sd	s0,32(sp)
    80003070:	ec26                	sd	s1,24(sp)
    80003072:	e84a                	sd	s2,16(sp)
    80003074:	e44e                	sd	s3,8(sp)
    80003076:	1800                	addi	s0,sp,48
    80003078:	892a                	mv	s2,a0
    8000307a:	84ae                	mv	s1,a1
    8000307c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000307e:	fffff097          	auipc	ra,0xfffff
    80003082:	aae080e7          	jalr	-1362(ra) # 80001b2c <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003086:	86ce                	mv	a3,s3
    80003088:	864a                	mv	a2,s2
    8000308a:	85a6                	mv	a1,s1
    8000308c:	6928                	ld	a0,80(a0)
    8000308e:	ffffe097          	auipc	ra,0xffffe
    80003092:	70e080e7          	jalr	1806(ra) # 8000179c <copyinstr>
    80003096:	00054e63          	bltz	a0,800030b2 <fetchstr+0x48>
  return strlen(buf);
    8000309a:	8526                	mv	a0,s1
    8000309c:	ffffe097          	auipc	ra,0xffffe
    800030a0:	dce080e7          	jalr	-562(ra) # 80000e6a <strlen>
}
    800030a4:	70a2                	ld	ra,40(sp)
    800030a6:	7402                	ld	s0,32(sp)
    800030a8:	64e2                	ld	s1,24(sp)
    800030aa:	6942                	ld	s2,16(sp)
    800030ac:	69a2                	ld	s3,8(sp)
    800030ae:	6145                	addi	sp,sp,48
    800030b0:	8082                	ret
    return -1;
    800030b2:	557d                	li	a0,-1
    800030b4:	bfc5                	j	800030a4 <fetchstr+0x3a>

00000000800030b6 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    800030b6:	1101                	addi	sp,sp,-32
    800030b8:	ec06                	sd	ra,24(sp)
    800030ba:	e822                	sd	s0,16(sp)
    800030bc:	e426                	sd	s1,8(sp)
    800030be:	1000                	addi	s0,sp,32
    800030c0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030c2:	00000097          	auipc	ra,0x0
    800030c6:	eee080e7          	jalr	-274(ra) # 80002fb0 <argraw>
    800030ca:	c088                	sw	a0,0(s1)
}
    800030cc:	60e2                	ld	ra,24(sp)
    800030ce:	6442                	ld	s0,16(sp)
    800030d0:	64a2                	ld	s1,8(sp)
    800030d2:	6105                	addi	sp,sp,32
    800030d4:	8082                	ret

00000000800030d6 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    800030d6:	1101                	addi	sp,sp,-32
    800030d8:	ec06                	sd	ra,24(sp)
    800030da:	e822                	sd	s0,16(sp)
    800030dc:	e426                	sd	s1,8(sp)
    800030de:	1000                	addi	s0,sp,32
    800030e0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030e2:	00000097          	auipc	ra,0x0
    800030e6:	ece080e7          	jalr	-306(ra) # 80002fb0 <argraw>
    800030ea:	e088                	sd	a0,0(s1)
}
    800030ec:	60e2                	ld	ra,24(sp)
    800030ee:	6442                	ld	s0,16(sp)
    800030f0:	64a2                	ld	s1,8(sp)
    800030f2:	6105                	addi	sp,sp,32
    800030f4:	8082                	ret

00000000800030f6 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    800030f6:	7179                	addi	sp,sp,-48
    800030f8:	f406                	sd	ra,40(sp)
    800030fa:	f022                	sd	s0,32(sp)
    800030fc:	ec26                	sd	s1,24(sp)
    800030fe:	e84a                	sd	s2,16(sp)
    80003100:	1800                	addi	s0,sp,48
    80003102:	84ae                	mv	s1,a1
    80003104:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003106:	fd840593          	addi	a1,s0,-40
    8000310a:	00000097          	auipc	ra,0x0
    8000310e:	fcc080e7          	jalr	-52(ra) # 800030d6 <argaddr>
  return fetchstr(addr, buf, max);
    80003112:	864a                	mv	a2,s2
    80003114:	85a6                	mv	a1,s1
    80003116:	fd843503          	ld	a0,-40(s0)
    8000311a:	00000097          	auipc	ra,0x0
    8000311e:	f50080e7          	jalr	-176(ra) # 8000306a <fetchstr>
}
    80003122:	70a2                	ld	ra,40(sp)
    80003124:	7402                	ld	s0,32(sp)
    80003126:	64e2                	ld	s1,24(sp)
    80003128:	6942                	ld	s2,16(sp)
    8000312a:	6145                	addi	sp,sp,48
    8000312c:	8082                	ret

000000008000312e <isbitset>:
[SYS_sigreturn] {"sigreturn\0", 0},
//***********
};


int isbitset(int mask,int i){
    8000312e:	1141                	addi	sp,sp,-16
    80003130:	e422                	sd	s0,8(sp)
    80003132:	0800                	addi	s0,sp,16
  int ans=0;
  if(mask & (1<<i)) ans=1;
    80003134:	40b5553b          	sraw	a0,a0,a1
  return ans;
}
    80003138:	8905                	andi	a0,a0,1
    8000313a:	6422                	ld	s0,8(sp)
    8000313c:	0141                	addi	sp,sp,16
    8000313e:	8082                	ret

0000000080003140 <syscall>:

void
syscall(void)
{
    80003140:	7139                	addi	sp,sp,-64
    80003142:	fc06                	sd	ra,56(sp)
    80003144:	f822                	sd	s0,48(sp)
    80003146:	f426                	sd	s1,40(sp)
    80003148:	f04a                	sd	s2,32(sp)
    8000314a:	ec4e                	sd	s3,24(sp)
    8000314c:	e852                	sd	s4,16(sp)
    8000314e:	e456                	sd	s5,8(sp)
    80003150:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80003152:	fffff097          	auipc	ra,0xfffff
    80003156:	9da080e7          	jalr	-1574(ra) # 80001b2c <myproc>
    8000315a:	892a                	mv	s2,a0

  num = p->trapframe->a7;
    8000315c:	6d3c                	ld	a5,88(a0)
    8000315e:	77dc                	ld	a5,168(a5)
    80003160:	0007899b          	sext.w	s3,a5

  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003164:	37fd                	addiw	a5,a5,-1
    80003166:	4769                	li	a4,26
    80003168:	14f76663          	bltu	a4,a5,800032b4 <syscall+0x174>
    8000316c:	00399713          	slli	a4,s3,0x3
    80003170:	00005797          	auipc	a5,0x5
    80003174:	36078793          	addi	a5,a5,864 # 800084d0 <syscalls>
    80003178:	97ba                	add	a5,a5,a4
    8000317a:	6384                	ld	s1,0(a5)
    8000317c:	12048c63          	beqz	s1,800032b4 <syscall+0x174>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0

  // added 
    long long firstargument = 0; 
    if(findinfo[num].systemcalledargc > 0) firstargument = argraw(0);
    80003180:	3ec00793          	li	a5,1004
    80003184:	02f98733          	mul	a4,s3,a5
    80003188:	00005797          	auipc	a5,0x5
    8000318c:	7b078793          	addi	a5,a5,1968 # 80008938 <findinfo>
    80003190:	97ba                	add	a5,a5,a4
    80003192:	3e87a783          	lw	a5,1000(a5)
    long long firstargument = 0; 
    80003196:	4a01                	li	s4,0
    if(findinfo[num].systemcalledargc > 0) firstargument = argraw(0);
    80003198:	0af04263          	bgtz	a5,8000323c <syscall+0xfc>

  // done added
    p->trapframe->a0 = syscalls[num](); // we are storing the return value of the function in trapframe->a0
    8000319c:	05893a83          	ld	s5,88(s2)
    800031a0:	9482                	jalr	s1
    800031a2:	06aab823          	sd	a0,112(s5)
  if(mask & (1<<i)) ans=1;
    800031a6:	16892483          	lw	s1,360(s2)
    800031aa:	4134d4bb          	sraw	s1,s1,s3
    800031ae:	8885                	andi	s1,s1,1

    // added

    if(isbitset(p->masknumber,num))
    800031b0:	12048363          	beqz	s1,800032d6 <syscall+0x196>
    {
        printf("%d: syscall %s (", p->pid, findinfo[num].systemcalledname);
    800031b4:	3ec00a93          	li	s5,1004
    800031b8:	03598ab3          	mul	s5,s3,s5
    800031bc:	00005797          	auipc	a5,0x5
    800031c0:	77c78793          	addi	a5,a5,1916 # 80008938 <findinfo>
    800031c4:	9abe                	add	s5,s5,a5
    800031c6:	8656                	mv	a2,s5
    800031c8:	03092583          	lw	a1,48(s2)
    800031cc:	00005517          	auipc	a0,0x5
    800031d0:	29450513          	addi	a0,a0,660 # 80008460 <states.1864+0x150>
    800031d4:	ffffd097          	auipc	ra,0xffffd
    800031d8:	3ba080e7          	jalr	954(ra) # 8000058e <printf>


        if(findinfo[num].systemcalledargc > 0)
    800031dc:	3e8aa783          	lw	a5,1000(s5)
    800031e0:	00f05e63          	blez	a5,800031fc <syscall+0xbc>
        {
          if(findinfo[num].systemcalledargc == 1) { // we seperate these two cases to perfectly handle the spacings while printing arguments
    800031e4:	4705                	li	a4,1
    800031e6:	06e78263          	beq	a5,a4,8000324a <syscall+0x10a>
            printf("%d", firstargument);
          } 
          else {
            printf("%d ", firstargument);
    800031ea:	85d2                	mv	a1,s4
    800031ec:	00005517          	auipc	a0,0x5
    800031f0:	29450513          	addi	a0,a0,660 # 80008480 <states.1864+0x170>
    800031f4:	ffffd097          	auipc	ra,0xffffd
    800031f8:	39a080e7          	jalr	922(ra) # 8000058e <printf>
          }
        }

        for (int i = 1; i < findinfo[num].systemcalledargc; i++)
    800031fc:	3ec00793          	li	a5,1004
    80003200:	02f98733          	mul	a4,s3,a5
    80003204:	00005797          	auipc	a5,0x5
    80003208:	73478793          	addi	a5,a5,1844 # 80008938 <findinfo>
    8000320c:	97ba                	add	a5,a5,a4
    8000320e:	3e87a783          	lw	a5,1000(a5)
    80003212:	4705                	li	a4,1
    80003214:	08f75463          	bge	a4,a5,8000329c <syscall+0x15c>
          {
            printf("%d", argraw(i));
          }
          else 
          {
              printf("%d ", argraw(i));
    80003218:	00005a17          	auipc	s4,0x5
    8000321c:	268a0a13          	addi	s4,s4,616 # 80008480 <states.1864+0x170>
            printf("%d", argraw(i));
    80003220:	00005a97          	auipc	s5,0x5
    80003224:	258a8a93          	addi	s5,s5,600 # 80008478 <states.1864+0x168>
        for (int i = 1; i < findinfo[num].systemcalledargc; i++)
    80003228:	3ec00713          	li	a4,1004
    8000322c:	02e98733          	mul	a4,s3,a4
    80003230:	00005997          	auipc	s3,0x5
    80003234:	70898993          	addi	s3,s3,1800 # 80008938 <findinfo>
    80003238:	99ba                	add	s3,s3,a4
    8000323a:	a091                	j	8000327e <syscall+0x13e>
    if(findinfo[num].systemcalledargc > 0) firstargument = argraw(0);
    8000323c:	4501                	li	a0,0
    8000323e:	00000097          	auipc	ra,0x0
    80003242:	d72080e7          	jalr	-654(ra) # 80002fb0 <argraw>
    80003246:	8a2a                	mv	s4,a0
    80003248:	bf91                	j	8000319c <syscall+0x5c>
            printf("%d", firstargument);
    8000324a:	85d2                	mv	a1,s4
    8000324c:	00005517          	auipc	a0,0x5
    80003250:	22c50513          	addi	a0,a0,556 # 80008478 <states.1864+0x168>
    80003254:	ffffd097          	auipc	ra,0xffffd
    80003258:	33a080e7          	jalr	826(ra) # 8000058e <printf>
    8000325c:	b745                	j	800031fc <syscall+0xbc>
              printf("%d ", argraw(i));
    8000325e:	8526                	mv	a0,s1
    80003260:	00000097          	auipc	ra,0x0
    80003264:	d50080e7          	jalr	-688(ra) # 80002fb0 <argraw>
    80003268:	85aa                	mv	a1,a0
    8000326a:	8552                	mv	a0,s4
    8000326c:	ffffd097          	auipc	ra,0xffffd
    80003270:	322080e7          	jalr	802(ra) # 8000058e <printf>
        for (int i = 1; i < findinfo[num].systemcalledargc; i++)
    80003274:	2485                	addiw	s1,s1,1
    80003276:	3e89a783          	lw	a5,1000(s3)
    8000327a:	02f4d163          	bge	s1,a5,8000329c <syscall+0x15c>
          if(i == findinfo[num].systemcalledargc-1)
    8000327e:	37fd                	addiw	a5,a5,-1
    80003280:	fc979fe3          	bne	a5,s1,8000325e <syscall+0x11e>
            printf("%d", argraw(i));
    80003284:	8526                	mv	a0,s1
    80003286:	00000097          	auipc	ra,0x0
    8000328a:	d2a080e7          	jalr	-726(ra) # 80002fb0 <argraw>
    8000328e:	85aa                	mv	a1,a0
    80003290:	8556                	mv	a0,s5
    80003292:	ffffd097          	auipc	ra,0xffffd
    80003296:	2fc080e7          	jalr	764(ra) # 8000058e <printf>
    8000329a:	bfe9                	j	80003274 <syscall+0x134>
          }   
        }
        printf(") -> %d\n", p->trapframe->a0);
    8000329c:	05893783          	ld	a5,88(s2)
    800032a0:	7bac                	ld	a1,112(a5)
    800032a2:	00005517          	auipc	a0,0x5
    800032a6:	1e650513          	addi	a0,a0,486 # 80008488 <states.1864+0x178>
    800032aa:	ffffd097          	auipc	ra,0xffffd
    800032ae:	2e4080e7          	jalr	740(ra) # 8000058e <printf>
    800032b2:	a015                	j	800032d6 <syscall+0x196>
    }

  // done added

  } else {
    printf("%d %s: unknown sys call %d\n",
    800032b4:	86ce                	mv	a3,s3
    800032b6:	15890613          	addi	a2,s2,344
    800032ba:	03092583          	lw	a1,48(s2)
    800032be:	00005517          	auipc	a0,0x5
    800032c2:	1da50513          	addi	a0,a0,474 # 80008498 <states.1864+0x188>
    800032c6:	ffffd097          	auipc	ra,0xffffd
    800032ca:	2c8080e7          	jalr	712(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800032ce:	05893783          	ld	a5,88(s2)
    800032d2:	577d                	li	a4,-1
    800032d4:	fbb8                	sd	a4,112(a5)
  }
}
    800032d6:	70e2                	ld	ra,56(sp)
    800032d8:	7442                	ld	s0,48(sp)
    800032da:	74a2                	ld	s1,40(sp)
    800032dc:	7902                	ld	s2,32(sp)
    800032de:	69e2                	ld	s3,24(sp)
    800032e0:	6a42                	ld	s4,16(sp)
    800032e2:	6aa2                	ld	s5,8(sp)
    800032e4:	6121                	addi	sp,sp,64
    800032e6:	8082                	ret

00000000800032e8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800032e8:	1101                	addi	sp,sp,-32
    800032ea:	ec06                	sd	ra,24(sp)
    800032ec:	e822                	sd	s0,16(sp)
    800032ee:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800032f0:	fec40593          	addi	a1,s0,-20
    800032f4:	4501                	li	a0,0
    800032f6:	00000097          	auipc	ra,0x0
    800032fa:	dc0080e7          	jalr	-576(ra) # 800030b6 <argint>
  exit(n);
    800032fe:	fec42503          	lw	a0,-20(s0)
    80003302:	fffff097          	auipc	ra,0xfffff
    80003306:	40e080e7          	jalr	1038(ra) # 80002710 <exit>
  return 0; // not reached
}
    8000330a:	4501                	li	a0,0
    8000330c:	60e2                	ld	ra,24(sp)
    8000330e:	6442                	ld	s0,16(sp)
    80003310:	6105                	addi	sp,sp,32
    80003312:	8082                	ret

0000000080003314 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003314:	1141                	addi	sp,sp,-16
    80003316:	e406                	sd	ra,8(sp)
    80003318:	e022                	sd	s0,0(sp)
    8000331a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000331c:	fffff097          	auipc	ra,0xfffff
    80003320:	810080e7          	jalr	-2032(ra) # 80001b2c <myproc>
}
    80003324:	5908                	lw	a0,48(a0)
    80003326:	60a2                	ld	ra,8(sp)
    80003328:	6402                	ld	s0,0(sp)
    8000332a:	0141                	addi	sp,sp,16
    8000332c:	8082                	ret

000000008000332e <sys_fork>:

uint64
sys_fork(void)
{
    8000332e:	1141                	addi	sp,sp,-16
    80003330:	e406                	sd	ra,8(sp)
    80003332:	e022                	sd	s0,0(sp)
    80003334:	0800                	addi	s0,sp,16
  return fork();
    80003336:	fffff097          	auipc	ra,0xfffff
    8000333a:	c02080e7          	jalr	-1022(ra) # 80001f38 <fork>
}
    8000333e:	60a2                	ld	ra,8(sp)
    80003340:	6402                	ld	s0,0(sp)
    80003342:	0141                	addi	sp,sp,16
    80003344:	8082                	ret

0000000080003346 <sys_wait>:

uint64
sys_wait(void)
{
    80003346:	1101                	addi	sp,sp,-32
    80003348:	ec06                	sd	ra,24(sp)
    8000334a:	e822                	sd	s0,16(sp)
    8000334c:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000334e:	fe840593          	addi	a1,s0,-24
    80003352:	4501                	li	a0,0
    80003354:	00000097          	auipc	ra,0x0
    80003358:	d82080e7          	jalr	-638(ra) # 800030d6 <argaddr>
  return wait(p);
    8000335c:	fe843503          	ld	a0,-24(s0)
    80003360:	fffff097          	auipc	ra,0xfffff
    80003364:	562080e7          	jalr	1378(ra) # 800028c2 <wait>
}
    80003368:	60e2                	ld	ra,24(sp)
    8000336a:	6442                	ld	s0,16(sp)
    8000336c:	6105                	addi	sp,sp,32
    8000336e:	8082                	ret

0000000080003370 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003370:	7179                	addi	sp,sp,-48
    80003372:	f406                	sd	ra,40(sp)
    80003374:	f022                	sd	s0,32(sp)
    80003376:	ec26                	sd	s1,24(sp)
    80003378:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000337a:	fdc40593          	addi	a1,s0,-36
    8000337e:	4501                	li	a0,0
    80003380:	00000097          	auipc	ra,0x0
    80003384:	d36080e7          	jalr	-714(ra) # 800030b6 <argint>
  addr = myproc()->sz;
    80003388:	ffffe097          	auipc	ra,0xffffe
    8000338c:	7a4080e7          	jalr	1956(ra) # 80001b2c <myproc>
    80003390:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003392:	fdc42503          	lw	a0,-36(s0)
    80003396:	fffff097          	auipc	ra,0xfffff
    8000339a:	b46080e7          	jalr	-1210(ra) # 80001edc <growproc>
    8000339e:	00054863          	bltz	a0,800033ae <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800033a2:	8526                	mv	a0,s1
    800033a4:	70a2                	ld	ra,40(sp)
    800033a6:	7402                	ld	s0,32(sp)
    800033a8:	64e2                	ld	s1,24(sp)
    800033aa:	6145                	addi	sp,sp,48
    800033ac:	8082                	ret
    return -1;
    800033ae:	54fd                	li	s1,-1
    800033b0:	bfcd                	j	800033a2 <sys_sbrk+0x32>

00000000800033b2 <sys_sleep>:

uint64
sys_sleep(void)
{
    800033b2:	7139                	addi	sp,sp,-64
    800033b4:	fc06                	sd	ra,56(sp)
    800033b6:	f822                	sd	s0,48(sp)
    800033b8:	f426                	sd	s1,40(sp)
    800033ba:	f04a                	sd	s2,32(sp)
    800033bc:	ec4e                	sd	s3,24(sp)
    800033be:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800033c0:	fcc40593          	addi	a1,s0,-52
    800033c4:	4501                	li	a0,0
    800033c6:	00000097          	auipc	ra,0x0
    800033ca:	cf0080e7          	jalr	-784(ra) # 800030b6 <argint>
  acquire(&tickslock);
    800033ce:	0001d517          	auipc	a0,0x1d
    800033d2:	43a50513          	addi	a0,a0,1082 # 80020808 <tickslock>
    800033d6:	ffffe097          	auipc	ra,0xffffe
    800033da:	814080e7          	jalr	-2028(ra) # 80000bea <acquire>
  ticks0 = ticks;
    800033de:	0000c917          	auipc	s2,0xc
    800033e2:	36292903          	lw	s2,866(s2) # 8000f740 <ticks>
  while (ticks - ticks0 < n)
    800033e6:	fcc42783          	lw	a5,-52(s0)
    800033ea:	cf9d                	beqz	a5,80003428 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800033ec:	0001d997          	auipc	s3,0x1d
    800033f0:	41c98993          	addi	s3,s3,1052 # 80020808 <tickslock>
    800033f4:	0000c497          	auipc	s1,0xc
    800033f8:	34c48493          	addi	s1,s1,844 # 8000f740 <ticks>
    if (killed(myproc()))
    800033fc:	ffffe097          	auipc	ra,0xffffe
    80003400:	730080e7          	jalr	1840(ra) # 80001b2c <myproc>
    80003404:	fffff097          	auipc	ra,0xfffff
    80003408:	48c080e7          	jalr	1164(ra) # 80002890 <killed>
    8000340c:	ed15                	bnez	a0,80003448 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000340e:	85ce                	mv	a1,s3
    80003410:	8526                	mv	a0,s1
    80003412:	fffff097          	auipc	ra,0xfffff
    80003416:	07a080e7          	jalr	122(ra) # 8000248c <sleep>
  while (ticks - ticks0 < n)
    8000341a:	409c                	lw	a5,0(s1)
    8000341c:	412787bb          	subw	a5,a5,s2
    80003420:	fcc42703          	lw	a4,-52(s0)
    80003424:	fce7ece3          	bltu	a5,a4,800033fc <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003428:	0001d517          	auipc	a0,0x1d
    8000342c:	3e050513          	addi	a0,a0,992 # 80020808 <tickslock>
    80003430:	ffffe097          	auipc	ra,0xffffe
    80003434:	86e080e7          	jalr	-1938(ra) # 80000c9e <release>
  return 0;
    80003438:	4501                	li	a0,0
}
    8000343a:	70e2                	ld	ra,56(sp)
    8000343c:	7442                	ld	s0,48(sp)
    8000343e:	74a2                	ld	s1,40(sp)
    80003440:	7902                	ld	s2,32(sp)
    80003442:	69e2                	ld	s3,24(sp)
    80003444:	6121                	addi	sp,sp,64
    80003446:	8082                	ret
      release(&tickslock);
    80003448:	0001d517          	auipc	a0,0x1d
    8000344c:	3c050513          	addi	a0,a0,960 # 80020808 <tickslock>
    80003450:	ffffe097          	auipc	ra,0xffffe
    80003454:	84e080e7          	jalr	-1970(ra) # 80000c9e <release>
      return -1;
    80003458:	557d                	li	a0,-1
    8000345a:	b7c5                	j	8000343a <sys_sleep+0x88>

000000008000345c <sys_kill>:

uint64
sys_kill(void)
{
    8000345c:	1101                	addi	sp,sp,-32
    8000345e:	ec06                	sd	ra,24(sp)
    80003460:	e822                	sd	s0,16(sp)
    80003462:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003464:	fec40593          	addi	a1,s0,-20
    80003468:	4501                	li	a0,0
    8000346a:	00000097          	auipc	ra,0x0
    8000346e:	c4c080e7          	jalr	-948(ra) # 800030b6 <argint>
  return kill(pid);
    80003472:	fec42503          	lw	a0,-20(s0)
    80003476:	fffff097          	auipc	ra,0xfffff
    8000347a:	37c080e7          	jalr	892(ra) # 800027f2 <kill>
}
    8000347e:	60e2                	ld	ra,24(sp)
    80003480:	6442                	ld	s0,16(sp)
    80003482:	6105                	addi	sp,sp,32
    80003484:	8082                	ret

0000000080003486 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003486:	1101                	addi	sp,sp,-32
    80003488:	ec06                	sd	ra,24(sp)
    8000348a:	e822                	sd	s0,16(sp)
    8000348c:	e426                	sd	s1,8(sp)
    8000348e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003490:	0001d517          	auipc	a0,0x1d
    80003494:	37850513          	addi	a0,a0,888 # 80020808 <tickslock>
    80003498:	ffffd097          	auipc	ra,0xffffd
    8000349c:	752080e7          	jalr	1874(ra) # 80000bea <acquire>
  xticks = ticks;
    800034a0:	0000c497          	auipc	s1,0xc
    800034a4:	2a04a483          	lw	s1,672(s1) # 8000f740 <ticks>
  release(&tickslock);
    800034a8:	0001d517          	auipc	a0,0x1d
    800034ac:	36050513          	addi	a0,a0,864 # 80020808 <tickslock>
    800034b0:	ffffd097          	auipc	ra,0xffffd
    800034b4:	7ee080e7          	jalr	2030(ra) # 80000c9e <release>
  return xticks;
}
    800034b8:	02049513          	slli	a0,s1,0x20
    800034bc:	9101                	srli	a0,a0,0x20
    800034be:	60e2                	ld	ra,24(sp)
    800034c0:	6442                	ld	s0,16(sp)
    800034c2:	64a2                	ld	s1,8(sp)
    800034c4:	6105                	addi	sp,sp,32
    800034c6:	8082                	ret

00000000800034c8 <sys_trace>:

uint64
sys_trace(void)
{
    800034c8:	1101                	addi	sp,sp,-32
    800034ca:	ec06                	sd	ra,24(sp)
    800034cc:	e822                	sd	s0,16(sp)
    800034ce:	e426                	sd	s1,8(sp)
    800034d0:	1000                	addi	s0,sp,32
  struct proc* tempfortrace = myproc();
    800034d2:	ffffe097          	auipc	ra,0xffffe
    800034d6:	65a080e7          	jalr	1626(ra) # 80001b2c <myproc>
    800034da:	84aa                	mv	s1,a0
  argint(0, &tempfortrace->masknumber);
    800034dc:	16850593          	addi	a1,a0,360
    800034e0:	4501                	li	a0,0
    800034e2:	00000097          	auipc	ra,0x0
    800034e6:	bd4080e7          	jalr	-1068(ra) # 800030b6 <argint>
  tempfortrace->masknumber = MAXX(0, tempfortrace->masknumber);
    800034ea:	1684a583          	lw	a1,360(s1)
    800034ee:	4501                	li	a0,0
    800034f0:	fffff097          	auipc	ra,0xfffff
    800034f4:	ba2080e7          	jalr	-1118(ra) # 80002092 <MAXX>
    800034f8:	16a4a423          	sw	a0,360(s1)
  return 0;
}
    800034fc:	4501                	li	a0,0
    800034fe:	60e2                	ld	ra,24(sp)
    80003500:	6442                	ld	s0,16(sp)
    80003502:	64a2                	ld	s1,8(sp)
    80003504:	6105                	addi	sp,sp,32
    80003506:	8082                	ret

0000000080003508 <sys_set_priority>:

uint64
sys_set_priority(void)
{
    80003508:	1101                	addi	sp,sp,-32
    8000350a:	ec06                	sd	ra,24(sp)
    8000350c:	e822                	sd	s0,16(sp)
    8000350e:	1000                	addi	s0,sp,32
  int pid, newPriority;
  argint(0, &newPriority); argint(1, &pid);
    80003510:	fe840593          	addi	a1,s0,-24
    80003514:	4501                	li	a0,0
    80003516:	00000097          	auipc	ra,0x0
    8000351a:	ba0080e7          	jalr	-1120(ra) # 800030b6 <argint>
    8000351e:	fec40593          	addi	a1,s0,-20
    80003522:	4505                	li	a0,1
    80003524:	00000097          	auipc	ra,0x0
    80003528:	b92080e7          	jalr	-1134(ra) # 800030b6 <argint>
  if(newPriority < 0 || pid < 0) {
    8000352c:	fe842503          	lw	a0,-24(s0)
    80003530:	00054f63          	bltz	a0,8000354e <sys_set_priority+0x46>
    80003534:	fec42583          	lw	a1,-20(s0)
    80003538:	0005cb63          	bltz	a1,8000354e <sys_set_priority+0x46>
    newPriority = MAXX(newPriority, 60);
    pid = MAXX(pid, 0);
    return -1; 
  }
  set_priority(newPriority, pid);
    8000353c:	fffff097          	auipc	ra,0xfffff
    80003540:	db0080e7          	jalr	-592(ra) # 800022ec <set_priority>
  return 0;
    80003544:	4501                	li	a0,0
}
    80003546:	60e2                	ld	ra,24(sp)
    80003548:	6442                	ld	s0,16(sp)
    8000354a:	6105                	addi	sp,sp,32
    8000354c:	8082                	ret
    newPriority = MAXX(newPriority, 60);
    8000354e:	03c00593          	li	a1,60
    80003552:	fffff097          	auipc	ra,0xfffff
    80003556:	b40080e7          	jalr	-1216(ra) # 80002092 <MAXX>
    8000355a:	fea42423          	sw	a0,-24(s0)
    pid = MAXX(pid, 0);
    8000355e:	4581                	li	a1,0
    80003560:	fec42503          	lw	a0,-20(s0)
    80003564:	fffff097          	auipc	ra,0xfffff
    80003568:	b2e080e7          	jalr	-1234(ra) # 80002092 <MAXX>
    return -1; 
    8000356c:	557d                	li	a0,-1
    8000356e:	bfe1                	j	80003546 <sys_set_priority+0x3e>

0000000080003570 <sys_sigalarm>:

uint64
sys_sigalarm(void)
{
    80003570:	1101                	addi	sp,sp,-32
    80003572:	ec06                	sd	ra,24(sp)
    80003574:	e822                	sd	s0,16(sp)
    80003576:	e426                	sd	s1,8(sp)
    80003578:	1000                	addi	s0,sp,32
  struct proc* p = myproc();
    8000357a:	ffffe097          	auipc	ra,0xffffe
    8000357e:	5b2080e7          	jalr	1458(ra) # 80001b2c <myproc>
    80003582:	84aa                	mv	s1,a0
  argint(0, &p->counttointerrupt); argint(1, &p->specificfn);
    80003584:	1d850593          	addi	a1,a0,472
    80003588:	4501                	li	a0,0
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	b2c080e7          	jalr	-1236(ra) # 800030b6 <argint>
    80003592:	1f048593          	addi	a1,s1,496
    80003596:	4505                	li	a0,1
    80003598:	00000097          	auipc	ra,0x0
    8000359c:	b1e080e7          	jalr	-1250(ra) # 800030b6 <argint>
  if(p->counttointerrupt < 0 || p->specificfn < 0) {
    800035a0:	1d84a783          	lw	a5,472(s1)
    800035a4:	0007cc63          	bltz	a5,800035bc <sys_sigalarm+0x4c>
    800035a8:	1f04a703          	lw	a4,496(s1)
    p->counttointerrupt = MAXX(p->counttointerrupt, 0);
    p->specificfn = MAXX(p->specificfn, 0);
    return -1; 
  }
  return 0; 
    800035ac:	4501                	li	a0,0
  if(p->counttointerrupt < 0 || p->specificfn < 0) {
    800035ae:	00074763          	bltz	a4,800035bc <sys_sigalarm+0x4c>
}
    800035b2:	60e2                	ld	ra,24(sp)
    800035b4:	6442                	ld	s0,16(sp)
    800035b6:	64a2                	ld	s1,8(sp)
    800035b8:	6105                	addi	sp,sp,32
    800035ba:	8082                	ret
    p->counttointerrupt = MAXX(p->counttointerrupt, 0);
    800035bc:	4581                	li	a1,0
    800035be:	853e                	mv	a0,a5
    800035c0:	fffff097          	auipc	ra,0xfffff
    800035c4:	ad2080e7          	jalr	-1326(ra) # 80002092 <MAXX>
    800035c8:	1ca4ac23          	sw	a0,472(s1)
    p->specificfn = MAXX(p->specificfn, 0);
    800035cc:	4581                	li	a1,0
    800035ce:	1f04a503          	lw	a0,496(s1)
    800035d2:	fffff097          	auipc	ra,0xfffff
    800035d6:	ac0080e7          	jalr	-1344(ra) # 80002092 <MAXX>
    800035da:	1ea4a823          	sw	a0,496(s1)
    return -1; 
    800035de:	557d                	li	a0,-1
    800035e0:	bfc9                	j	800035b2 <sys_sigalarm+0x42>

00000000800035e2 <sys_sigreturn>:

uint64 
sys_sigreturn(void)
{
    800035e2:	1101                	addi	sp,sp,-32
    800035e4:	ec06                	sd	ra,24(sp)
    800035e6:	e822                	sd	s0,16(sp)
    800035e8:	e426                	sd	s1,8(sp)
    800035ea:	1000                	addi	s0,sp,32
  struct proc* p = myproc();
    800035ec:	ffffe097          	auipc	ra,0xffffe
    800035f0:	540080e7          	jalr	1344(ra) # 80001b2c <myproc>
    800035f4:	84aa                	mv	s1,a0
  p->tickswhenalarmisoff = 0; 
    800035f6:	1e053423          	sd	zero,488(a0)
  memmove(p->trapframe, p->savingthetrapframe, PGSIZE);
    800035fa:	6605                	lui	a2,0x1
    800035fc:	1f853583          	ld	a1,504(a0)
    80003600:	6d28                	ld	a0,88(a0)
    80003602:	ffffd097          	auipc	ra,0xffffd
    80003606:	744080e7          	jalr	1860(ra) # 80000d46 <memmove>
  kfree(p->savingthetrapframe);
    8000360a:	1f84b503          	ld	a0,504(s1)
    8000360e:	ffffd097          	auipc	ra,0xffffd
    80003612:	3f0080e7          	jalr	1008(ra) # 800009fe <kfree>
  p->savingthetrapframe = 0; 
    80003616:	1e04bc23          	sd	zero,504(s1)
  usertrapret();
    8000361a:	fffff097          	auipc	ra,0xfffff
    8000361e:	5da080e7          	jalr	1498(ra) # 80002bf4 <usertrapret>
  return 0; 
}
    80003622:	4501                	li	a0,0
    80003624:	60e2                	ld	ra,24(sp)
    80003626:	6442                	ld	s0,16(sp)
    80003628:	64a2                	ld	s1,8(sp)
    8000362a:	6105                	addi	sp,sp,32
    8000362c:	8082                	ret

000000008000362e <sys_waitx>:

uint64
sys_waitx(void)
{
    8000362e:	7139                	addi	sp,sp,-64
    80003630:	fc06                	sd	ra,56(sp)
    80003632:	f822                	sd	s0,48(sp)
    80003634:	f426                	sd	s1,40(sp)
    80003636:	f04a                	sd	s2,32(sp)
    80003638:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    8000363a:	fd840593          	addi	a1,s0,-40
    8000363e:	4501                	li	a0,0
    80003640:	00000097          	auipc	ra,0x0
    80003644:	a96080e7          	jalr	-1386(ra) # 800030d6 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003648:	fd040593          	addi	a1,s0,-48
    8000364c:	4505                	li	a0,1
    8000364e:	00000097          	auipc	ra,0x0
    80003652:	a88080e7          	jalr	-1400(ra) # 800030d6 <argaddr>
  argaddr(2, &addr2);
    80003656:	fc840593          	addi	a1,s0,-56
    8000365a:	4509                	li	a0,2
    8000365c:	00000097          	auipc	ra,0x0
    80003660:	a7a080e7          	jalr	-1414(ra) # 800030d6 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003664:	fc040613          	addi	a2,s0,-64
    80003668:	fc440593          	addi	a1,s0,-60
    8000366c:	fd843503          	ld	a0,-40(s0)
    80003670:	fffff097          	auipc	ra,0xfffff
    80003674:	e80080e7          	jalr	-384(ra) # 800024f0 <waitx>
    80003678:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000367a:	ffffe097          	auipc	ra,0xffffe
    8000367e:	4b2080e7          	jalr	1202(ra) # 80001b2c <myproc>
    80003682:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003684:	4691                	li	a3,4
    80003686:	fc440613          	addi	a2,s0,-60
    8000368a:	fd043583          	ld	a1,-48(s0)
    8000368e:	6928                	ld	a0,80(a0)
    80003690:	ffffe097          	auipc	ra,0xffffe
    80003694:	ff4080e7          	jalr	-12(ra) # 80001684 <copyout>
    return -1;
    80003698:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000369a:	00054f63          	bltz	a0,800036b8 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000369e:	4691                	li	a3,4
    800036a0:	fc040613          	addi	a2,s0,-64
    800036a4:	fc843583          	ld	a1,-56(s0)
    800036a8:	68a8                	ld	a0,80(s1)
    800036aa:	ffffe097          	auipc	ra,0xffffe
    800036ae:	fda080e7          	jalr	-38(ra) # 80001684 <copyout>
    800036b2:	00054a63          	bltz	a0,800036c6 <sys_waitx+0x98>
    return -1;
  return ret;
    800036b6:	87ca                	mv	a5,s2
}
    800036b8:	853e                	mv	a0,a5
    800036ba:	70e2                	ld	ra,56(sp)
    800036bc:	7442                	ld	s0,48(sp)
    800036be:	74a2                	ld	s1,40(sp)
    800036c0:	7902                	ld	s2,32(sp)
    800036c2:	6121                	addi	sp,sp,64
    800036c4:	8082                	ret
    return -1;
    800036c6:	57fd                	li	a5,-1
    800036c8:	bfc5                	j	800036b8 <sys_waitx+0x8a>

00000000800036ca <sys_settickets>:


uint64
sys_settickets(void)
{
    800036ca:	1101                	addi	sp,sp,-32
    800036cc:	ec06                	sd	ra,24(sp)
    800036ce:	e822                	sd	s0,16(sp)
    800036d0:	1000                	addi	s0,sp,32
  int newtickets; 
  argint(0, &newtickets);
    800036d2:	fec40593          	addi	a1,s0,-20
    800036d6:	4501                	li	a0,0
    800036d8:	00000097          	auipc	ra,0x0
    800036dc:	9de080e7          	jalr	-1570(ra) # 800030b6 <argint>
  settickets(newtickets);
    800036e0:	fec42503          	lw	a0,-20(s0)
    800036e4:	fffff097          	auipc	ra,0xfffff
    800036e8:	cd8080e7          	jalr	-808(ra) # 800023bc <settickets>
  return 1; 
    800036ec:	4505                	li	a0,1
    800036ee:	60e2                	ld	ra,24(sp)
    800036f0:	6442                	ld	s0,16(sp)
    800036f2:	6105                	addi	sp,sp,32
    800036f4:	8082                	ret

00000000800036f6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800036f6:	7179                	addi	sp,sp,-48
    800036f8:	f406                	sd	ra,40(sp)
    800036fa:	f022                	sd	s0,32(sp)
    800036fc:	ec26                	sd	s1,24(sp)
    800036fe:	e84a                	sd	s2,16(sp)
    80003700:	e44e                	sd	s3,8(sp)
    80003702:	e052                	sd	s4,0(sp)
    80003704:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003706:	00005597          	auipc	a1,0x5
    8000370a:	eaa58593          	addi	a1,a1,-342 # 800085b0 <syscalls+0xe0>
    8000370e:	0001d517          	auipc	a0,0x1d
    80003712:	11250513          	addi	a0,a0,274 # 80020820 <bcache>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	444080e7          	jalr	1092(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000371e:	00025797          	auipc	a5,0x25
    80003722:	10278793          	addi	a5,a5,258 # 80028820 <bcache+0x8000>
    80003726:	00025717          	auipc	a4,0x25
    8000372a:	36270713          	addi	a4,a4,866 # 80028a88 <bcache+0x8268>
    8000372e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003732:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003736:	0001d497          	auipc	s1,0x1d
    8000373a:	10248493          	addi	s1,s1,258 # 80020838 <bcache+0x18>
    b->next = bcache.head.next;
    8000373e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003740:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003742:	00005a17          	auipc	s4,0x5
    80003746:	e76a0a13          	addi	s4,s4,-394 # 800085b8 <syscalls+0xe8>
    b->next = bcache.head.next;
    8000374a:	2b893783          	ld	a5,696(s2)
    8000374e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003750:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003754:	85d2                	mv	a1,s4
    80003756:	01048513          	addi	a0,s1,16
    8000375a:	00001097          	auipc	ra,0x1
    8000375e:	4c4080e7          	jalr	1220(ra) # 80004c1e <initsleeplock>
    bcache.head.next->prev = b;
    80003762:	2b893783          	ld	a5,696(s2)
    80003766:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003768:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000376c:	45848493          	addi	s1,s1,1112
    80003770:	fd349de3          	bne	s1,s3,8000374a <binit+0x54>
  }
}
    80003774:	70a2                	ld	ra,40(sp)
    80003776:	7402                	ld	s0,32(sp)
    80003778:	64e2                	ld	s1,24(sp)
    8000377a:	6942                	ld	s2,16(sp)
    8000377c:	69a2                	ld	s3,8(sp)
    8000377e:	6a02                	ld	s4,0(sp)
    80003780:	6145                	addi	sp,sp,48
    80003782:	8082                	ret

0000000080003784 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003784:	7179                	addi	sp,sp,-48
    80003786:	f406                	sd	ra,40(sp)
    80003788:	f022                	sd	s0,32(sp)
    8000378a:	ec26                	sd	s1,24(sp)
    8000378c:	e84a                	sd	s2,16(sp)
    8000378e:	e44e                	sd	s3,8(sp)
    80003790:	1800                	addi	s0,sp,48
    80003792:	89aa                	mv	s3,a0
    80003794:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003796:	0001d517          	auipc	a0,0x1d
    8000379a:	08a50513          	addi	a0,a0,138 # 80020820 <bcache>
    8000379e:	ffffd097          	auipc	ra,0xffffd
    800037a2:	44c080e7          	jalr	1100(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800037a6:	00025497          	auipc	s1,0x25
    800037aa:	3324b483          	ld	s1,818(s1) # 80028ad8 <bcache+0x82b8>
    800037ae:	00025797          	auipc	a5,0x25
    800037b2:	2da78793          	addi	a5,a5,730 # 80028a88 <bcache+0x8268>
    800037b6:	02f48f63          	beq	s1,a5,800037f4 <bread+0x70>
    800037ba:	873e                	mv	a4,a5
    800037bc:	a021                	j	800037c4 <bread+0x40>
    800037be:	68a4                	ld	s1,80(s1)
    800037c0:	02e48a63          	beq	s1,a4,800037f4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800037c4:	449c                	lw	a5,8(s1)
    800037c6:	ff379ce3          	bne	a5,s3,800037be <bread+0x3a>
    800037ca:	44dc                	lw	a5,12(s1)
    800037cc:	ff2799e3          	bne	a5,s2,800037be <bread+0x3a>
      b->refcnt++;
    800037d0:	40bc                	lw	a5,64(s1)
    800037d2:	2785                	addiw	a5,a5,1
    800037d4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800037d6:	0001d517          	auipc	a0,0x1d
    800037da:	04a50513          	addi	a0,a0,74 # 80020820 <bcache>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	4c0080e7          	jalr	1216(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800037e6:	01048513          	addi	a0,s1,16
    800037ea:	00001097          	auipc	ra,0x1
    800037ee:	46e080e7          	jalr	1134(ra) # 80004c58 <acquiresleep>
      return b;
    800037f2:	a8b9                	j	80003850 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800037f4:	00025497          	auipc	s1,0x25
    800037f8:	2dc4b483          	ld	s1,732(s1) # 80028ad0 <bcache+0x82b0>
    800037fc:	00025797          	auipc	a5,0x25
    80003800:	28c78793          	addi	a5,a5,652 # 80028a88 <bcache+0x8268>
    80003804:	00f48863          	beq	s1,a5,80003814 <bread+0x90>
    80003808:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000380a:	40bc                	lw	a5,64(s1)
    8000380c:	cf81                	beqz	a5,80003824 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000380e:	64a4                	ld	s1,72(s1)
    80003810:	fee49de3          	bne	s1,a4,8000380a <bread+0x86>
  panic("bget: no buffers");
    80003814:	00005517          	auipc	a0,0x5
    80003818:	dac50513          	addi	a0,a0,-596 # 800085c0 <syscalls+0xf0>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	d28080e7          	jalr	-728(ra) # 80000544 <panic>
      b->dev = dev;
    80003824:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003828:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000382c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003830:	4785                	li	a5,1
    80003832:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003834:	0001d517          	auipc	a0,0x1d
    80003838:	fec50513          	addi	a0,a0,-20 # 80020820 <bcache>
    8000383c:	ffffd097          	auipc	ra,0xffffd
    80003840:	462080e7          	jalr	1122(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003844:	01048513          	addi	a0,s1,16
    80003848:	00001097          	auipc	ra,0x1
    8000384c:	410080e7          	jalr	1040(ra) # 80004c58 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003850:	409c                	lw	a5,0(s1)
    80003852:	cb89                	beqz	a5,80003864 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003854:	8526                	mv	a0,s1
    80003856:	70a2                	ld	ra,40(sp)
    80003858:	7402                	ld	s0,32(sp)
    8000385a:	64e2                	ld	s1,24(sp)
    8000385c:	6942                	ld	s2,16(sp)
    8000385e:	69a2                	ld	s3,8(sp)
    80003860:	6145                	addi	sp,sp,48
    80003862:	8082                	ret
    virtio_disk_rw(b, 0);
    80003864:	4581                	li	a1,0
    80003866:	8526                	mv	a0,s1
    80003868:	00003097          	auipc	ra,0x3
    8000386c:	fd0080e7          	jalr	-48(ra) # 80006838 <virtio_disk_rw>
    b->valid = 1;
    80003870:	4785                	li	a5,1
    80003872:	c09c                	sw	a5,0(s1)
  return b;
    80003874:	b7c5                	j	80003854 <bread+0xd0>

0000000080003876 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003876:	1101                	addi	sp,sp,-32
    80003878:	ec06                	sd	ra,24(sp)
    8000387a:	e822                	sd	s0,16(sp)
    8000387c:	e426                	sd	s1,8(sp)
    8000387e:	1000                	addi	s0,sp,32
    80003880:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003882:	0541                	addi	a0,a0,16
    80003884:	00001097          	auipc	ra,0x1
    80003888:	46e080e7          	jalr	1134(ra) # 80004cf2 <holdingsleep>
    8000388c:	cd01                	beqz	a0,800038a4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000388e:	4585                	li	a1,1
    80003890:	8526                	mv	a0,s1
    80003892:	00003097          	auipc	ra,0x3
    80003896:	fa6080e7          	jalr	-90(ra) # 80006838 <virtio_disk_rw>
}
    8000389a:	60e2                	ld	ra,24(sp)
    8000389c:	6442                	ld	s0,16(sp)
    8000389e:	64a2                	ld	s1,8(sp)
    800038a0:	6105                	addi	sp,sp,32
    800038a2:	8082                	ret
    panic("bwrite");
    800038a4:	00005517          	auipc	a0,0x5
    800038a8:	d3450513          	addi	a0,a0,-716 # 800085d8 <syscalls+0x108>
    800038ac:	ffffd097          	auipc	ra,0xffffd
    800038b0:	c98080e7          	jalr	-872(ra) # 80000544 <panic>

00000000800038b4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800038b4:	1101                	addi	sp,sp,-32
    800038b6:	ec06                	sd	ra,24(sp)
    800038b8:	e822                	sd	s0,16(sp)
    800038ba:	e426                	sd	s1,8(sp)
    800038bc:	e04a                	sd	s2,0(sp)
    800038be:	1000                	addi	s0,sp,32
    800038c0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800038c2:	01050913          	addi	s2,a0,16
    800038c6:	854a                	mv	a0,s2
    800038c8:	00001097          	auipc	ra,0x1
    800038cc:	42a080e7          	jalr	1066(ra) # 80004cf2 <holdingsleep>
    800038d0:	c92d                	beqz	a0,80003942 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800038d2:	854a                	mv	a0,s2
    800038d4:	00001097          	auipc	ra,0x1
    800038d8:	3da080e7          	jalr	986(ra) # 80004cae <releasesleep>

  acquire(&bcache.lock);
    800038dc:	0001d517          	auipc	a0,0x1d
    800038e0:	f4450513          	addi	a0,a0,-188 # 80020820 <bcache>
    800038e4:	ffffd097          	auipc	ra,0xffffd
    800038e8:	306080e7          	jalr	774(ra) # 80000bea <acquire>
  b->refcnt--;
    800038ec:	40bc                	lw	a5,64(s1)
    800038ee:	37fd                	addiw	a5,a5,-1
    800038f0:	0007871b          	sext.w	a4,a5
    800038f4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800038f6:	eb05                	bnez	a4,80003926 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800038f8:	68bc                	ld	a5,80(s1)
    800038fa:	64b8                	ld	a4,72(s1)
    800038fc:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800038fe:	64bc                	ld	a5,72(s1)
    80003900:	68b8                	ld	a4,80(s1)
    80003902:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003904:	00025797          	auipc	a5,0x25
    80003908:	f1c78793          	addi	a5,a5,-228 # 80028820 <bcache+0x8000>
    8000390c:	2b87b703          	ld	a4,696(a5)
    80003910:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003912:	00025717          	auipc	a4,0x25
    80003916:	17670713          	addi	a4,a4,374 # 80028a88 <bcache+0x8268>
    8000391a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000391c:	2b87b703          	ld	a4,696(a5)
    80003920:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003922:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003926:	0001d517          	auipc	a0,0x1d
    8000392a:	efa50513          	addi	a0,a0,-262 # 80020820 <bcache>
    8000392e:	ffffd097          	auipc	ra,0xffffd
    80003932:	370080e7          	jalr	880(ra) # 80000c9e <release>
}
    80003936:	60e2                	ld	ra,24(sp)
    80003938:	6442                	ld	s0,16(sp)
    8000393a:	64a2                	ld	s1,8(sp)
    8000393c:	6902                	ld	s2,0(sp)
    8000393e:	6105                	addi	sp,sp,32
    80003940:	8082                	ret
    panic("brelse");
    80003942:	00005517          	auipc	a0,0x5
    80003946:	c9e50513          	addi	a0,a0,-866 # 800085e0 <syscalls+0x110>
    8000394a:	ffffd097          	auipc	ra,0xffffd
    8000394e:	bfa080e7          	jalr	-1030(ra) # 80000544 <panic>

0000000080003952 <bpin>:

void
bpin(struct buf *b) {
    80003952:	1101                	addi	sp,sp,-32
    80003954:	ec06                	sd	ra,24(sp)
    80003956:	e822                	sd	s0,16(sp)
    80003958:	e426                	sd	s1,8(sp)
    8000395a:	1000                	addi	s0,sp,32
    8000395c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000395e:	0001d517          	auipc	a0,0x1d
    80003962:	ec250513          	addi	a0,a0,-318 # 80020820 <bcache>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	284080e7          	jalr	644(ra) # 80000bea <acquire>
  b->refcnt++;
    8000396e:	40bc                	lw	a5,64(s1)
    80003970:	2785                	addiw	a5,a5,1
    80003972:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003974:	0001d517          	auipc	a0,0x1d
    80003978:	eac50513          	addi	a0,a0,-340 # 80020820 <bcache>
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	322080e7          	jalr	802(ra) # 80000c9e <release>
}
    80003984:	60e2                	ld	ra,24(sp)
    80003986:	6442                	ld	s0,16(sp)
    80003988:	64a2                	ld	s1,8(sp)
    8000398a:	6105                	addi	sp,sp,32
    8000398c:	8082                	ret

000000008000398e <bunpin>:

void
bunpin(struct buf *b) {
    8000398e:	1101                	addi	sp,sp,-32
    80003990:	ec06                	sd	ra,24(sp)
    80003992:	e822                	sd	s0,16(sp)
    80003994:	e426                	sd	s1,8(sp)
    80003996:	1000                	addi	s0,sp,32
    80003998:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000399a:	0001d517          	auipc	a0,0x1d
    8000399e:	e8650513          	addi	a0,a0,-378 # 80020820 <bcache>
    800039a2:	ffffd097          	auipc	ra,0xffffd
    800039a6:	248080e7          	jalr	584(ra) # 80000bea <acquire>
  b->refcnt--;
    800039aa:	40bc                	lw	a5,64(s1)
    800039ac:	37fd                	addiw	a5,a5,-1
    800039ae:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800039b0:	0001d517          	auipc	a0,0x1d
    800039b4:	e7050513          	addi	a0,a0,-400 # 80020820 <bcache>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	2e6080e7          	jalr	742(ra) # 80000c9e <release>
}
    800039c0:	60e2                	ld	ra,24(sp)
    800039c2:	6442                	ld	s0,16(sp)
    800039c4:	64a2                	ld	s1,8(sp)
    800039c6:	6105                	addi	sp,sp,32
    800039c8:	8082                	ret

00000000800039ca <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800039ca:	1101                	addi	sp,sp,-32
    800039cc:	ec06                	sd	ra,24(sp)
    800039ce:	e822                	sd	s0,16(sp)
    800039d0:	e426                	sd	s1,8(sp)
    800039d2:	e04a                	sd	s2,0(sp)
    800039d4:	1000                	addi	s0,sp,32
    800039d6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800039d8:	00d5d59b          	srliw	a1,a1,0xd
    800039dc:	00025797          	auipc	a5,0x25
    800039e0:	5207a783          	lw	a5,1312(a5) # 80028efc <sb+0x1c>
    800039e4:	9dbd                	addw	a1,a1,a5
    800039e6:	00000097          	auipc	ra,0x0
    800039ea:	d9e080e7          	jalr	-610(ra) # 80003784 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800039ee:	0074f713          	andi	a4,s1,7
    800039f2:	4785                	li	a5,1
    800039f4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800039f8:	14ce                	slli	s1,s1,0x33
    800039fa:	90d9                	srli	s1,s1,0x36
    800039fc:	00950733          	add	a4,a0,s1
    80003a00:	05874703          	lbu	a4,88(a4)
    80003a04:	00e7f6b3          	and	a3,a5,a4
    80003a08:	c69d                	beqz	a3,80003a36 <bfree+0x6c>
    80003a0a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003a0c:	94aa                	add	s1,s1,a0
    80003a0e:	fff7c793          	not	a5,a5
    80003a12:	8ff9                	and	a5,a5,a4
    80003a14:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003a18:	00001097          	auipc	ra,0x1
    80003a1c:	120080e7          	jalr	288(ra) # 80004b38 <log_write>
  brelse(bp);
    80003a20:	854a                	mv	a0,s2
    80003a22:	00000097          	auipc	ra,0x0
    80003a26:	e92080e7          	jalr	-366(ra) # 800038b4 <brelse>
}
    80003a2a:	60e2                	ld	ra,24(sp)
    80003a2c:	6442                	ld	s0,16(sp)
    80003a2e:	64a2                	ld	s1,8(sp)
    80003a30:	6902                	ld	s2,0(sp)
    80003a32:	6105                	addi	sp,sp,32
    80003a34:	8082                	ret
    panic("freeing free block");
    80003a36:	00005517          	auipc	a0,0x5
    80003a3a:	bb250513          	addi	a0,a0,-1102 # 800085e8 <syscalls+0x118>
    80003a3e:	ffffd097          	auipc	ra,0xffffd
    80003a42:	b06080e7          	jalr	-1274(ra) # 80000544 <panic>

0000000080003a46 <balloc>:
{
    80003a46:	711d                	addi	sp,sp,-96
    80003a48:	ec86                	sd	ra,88(sp)
    80003a4a:	e8a2                	sd	s0,80(sp)
    80003a4c:	e4a6                	sd	s1,72(sp)
    80003a4e:	e0ca                	sd	s2,64(sp)
    80003a50:	fc4e                	sd	s3,56(sp)
    80003a52:	f852                	sd	s4,48(sp)
    80003a54:	f456                	sd	s5,40(sp)
    80003a56:	f05a                	sd	s6,32(sp)
    80003a58:	ec5e                	sd	s7,24(sp)
    80003a5a:	e862                	sd	s8,16(sp)
    80003a5c:	e466                	sd	s9,8(sp)
    80003a5e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003a60:	00025797          	auipc	a5,0x25
    80003a64:	4847a783          	lw	a5,1156(a5) # 80028ee4 <sb+0x4>
    80003a68:	10078163          	beqz	a5,80003b6a <balloc+0x124>
    80003a6c:	8baa                	mv	s7,a0
    80003a6e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003a70:	00025b17          	auipc	s6,0x25
    80003a74:	470b0b13          	addi	s6,s6,1136 # 80028ee0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a78:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003a7a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a7c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003a7e:	6c89                	lui	s9,0x2
    80003a80:	a061                	j	80003b08 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a82:	974a                	add	a4,a4,s2
    80003a84:	8fd5                	or	a5,a5,a3
    80003a86:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003a8a:	854a                	mv	a0,s2
    80003a8c:	00001097          	auipc	ra,0x1
    80003a90:	0ac080e7          	jalr	172(ra) # 80004b38 <log_write>
        brelse(bp);
    80003a94:	854a                	mv	a0,s2
    80003a96:	00000097          	auipc	ra,0x0
    80003a9a:	e1e080e7          	jalr	-482(ra) # 800038b4 <brelse>
  bp = bread(dev, bno);
    80003a9e:	85a6                	mv	a1,s1
    80003aa0:	855e                	mv	a0,s7
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	ce2080e7          	jalr	-798(ra) # 80003784 <bread>
    80003aaa:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003aac:	40000613          	li	a2,1024
    80003ab0:	4581                	li	a1,0
    80003ab2:	05850513          	addi	a0,a0,88
    80003ab6:	ffffd097          	auipc	ra,0xffffd
    80003aba:	230080e7          	jalr	560(ra) # 80000ce6 <memset>
  log_write(bp);
    80003abe:	854a                	mv	a0,s2
    80003ac0:	00001097          	auipc	ra,0x1
    80003ac4:	078080e7          	jalr	120(ra) # 80004b38 <log_write>
  brelse(bp);
    80003ac8:	854a                	mv	a0,s2
    80003aca:	00000097          	auipc	ra,0x0
    80003ace:	dea080e7          	jalr	-534(ra) # 800038b4 <brelse>
}
    80003ad2:	8526                	mv	a0,s1
    80003ad4:	60e6                	ld	ra,88(sp)
    80003ad6:	6446                	ld	s0,80(sp)
    80003ad8:	64a6                	ld	s1,72(sp)
    80003ada:	6906                	ld	s2,64(sp)
    80003adc:	79e2                	ld	s3,56(sp)
    80003ade:	7a42                	ld	s4,48(sp)
    80003ae0:	7aa2                	ld	s5,40(sp)
    80003ae2:	7b02                	ld	s6,32(sp)
    80003ae4:	6be2                	ld	s7,24(sp)
    80003ae6:	6c42                	ld	s8,16(sp)
    80003ae8:	6ca2                	ld	s9,8(sp)
    80003aea:	6125                	addi	sp,sp,96
    80003aec:	8082                	ret
    brelse(bp);
    80003aee:	854a                	mv	a0,s2
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	dc4080e7          	jalr	-572(ra) # 800038b4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003af8:	015c87bb          	addw	a5,s9,s5
    80003afc:	00078a9b          	sext.w	s5,a5
    80003b00:	004b2703          	lw	a4,4(s6)
    80003b04:	06eaf363          	bgeu	s5,a4,80003b6a <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003b08:	41fad79b          	sraiw	a5,s5,0x1f
    80003b0c:	0137d79b          	srliw	a5,a5,0x13
    80003b10:	015787bb          	addw	a5,a5,s5
    80003b14:	40d7d79b          	sraiw	a5,a5,0xd
    80003b18:	01cb2583          	lw	a1,28(s6)
    80003b1c:	9dbd                	addw	a1,a1,a5
    80003b1e:	855e                	mv	a0,s7
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	c64080e7          	jalr	-924(ra) # 80003784 <bread>
    80003b28:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b2a:	004b2503          	lw	a0,4(s6)
    80003b2e:	000a849b          	sext.w	s1,s5
    80003b32:	8662                	mv	a2,s8
    80003b34:	faa4fde3          	bgeu	s1,a0,80003aee <balloc+0xa8>
      m = 1 << (bi % 8);
    80003b38:	41f6579b          	sraiw	a5,a2,0x1f
    80003b3c:	01d7d69b          	srliw	a3,a5,0x1d
    80003b40:	00c6873b          	addw	a4,a3,a2
    80003b44:	00777793          	andi	a5,a4,7
    80003b48:	9f95                	subw	a5,a5,a3
    80003b4a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003b4e:	4037571b          	sraiw	a4,a4,0x3
    80003b52:	00e906b3          	add	a3,s2,a4
    80003b56:	0586c683          	lbu	a3,88(a3)
    80003b5a:	00d7f5b3          	and	a1,a5,a3
    80003b5e:	d195                	beqz	a1,80003a82 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b60:	2605                	addiw	a2,a2,1
    80003b62:	2485                	addiw	s1,s1,1
    80003b64:	fd4618e3          	bne	a2,s4,80003b34 <balloc+0xee>
    80003b68:	b759                	j	80003aee <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003b6a:	00005517          	auipc	a0,0x5
    80003b6e:	a9650513          	addi	a0,a0,-1386 # 80008600 <syscalls+0x130>
    80003b72:	ffffd097          	auipc	ra,0xffffd
    80003b76:	a1c080e7          	jalr	-1508(ra) # 8000058e <printf>
  return 0;
    80003b7a:	4481                	li	s1,0
    80003b7c:	bf99                	j	80003ad2 <balloc+0x8c>

0000000080003b7e <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003b7e:	7179                	addi	sp,sp,-48
    80003b80:	f406                	sd	ra,40(sp)
    80003b82:	f022                	sd	s0,32(sp)
    80003b84:	ec26                	sd	s1,24(sp)
    80003b86:	e84a                	sd	s2,16(sp)
    80003b88:	e44e                	sd	s3,8(sp)
    80003b8a:	e052                	sd	s4,0(sp)
    80003b8c:	1800                	addi	s0,sp,48
    80003b8e:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003b90:	47ad                	li	a5,11
    80003b92:	02b7e763          	bltu	a5,a1,80003bc0 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003b96:	02059493          	slli	s1,a1,0x20
    80003b9a:	9081                	srli	s1,s1,0x20
    80003b9c:	048a                	slli	s1,s1,0x2
    80003b9e:	94aa                	add	s1,s1,a0
    80003ba0:	0504a903          	lw	s2,80(s1)
    80003ba4:	06091e63          	bnez	s2,80003c20 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003ba8:	4108                	lw	a0,0(a0)
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	e9c080e7          	jalr	-356(ra) # 80003a46 <balloc>
    80003bb2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003bb6:	06090563          	beqz	s2,80003c20 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003bba:	0524a823          	sw	s2,80(s1)
    80003bbe:	a08d                	j	80003c20 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003bc0:	ff45849b          	addiw	s1,a1,-12
    80003bc4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003bc8:	0ff00793          	li	a5,255
    80003bcc:	08e7e563          	bltu	a5,a4,80003c56 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003bd0:	08052903          	lw	s2,128(a0)
    80003bd4:	00091d63          	bnez	s2,80003bee <bmap+0x70>
      addr = balloc(ip->dev);
    80003bd8:	4108                	lw	a0,0(a0)
    80003bda:	00000097          	auipc	ra,0x0
    80003bde:	e6c080e7          	jalr	-404(ra) # 80003a46 <balloc>
    80003be2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003be6:	02090d63          	beqz	s2,80003c20 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003bea:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003bee:	85ca                	mv	a1,s2
    80003bf0:	0009a503          	lw	a0,0(s3)
    80003bf4:	00000097          	auipc	ra,0x0
    80003bf8:	b90080e7          	jalr	-1136(ra) # 80003784 <bread>
    80003bfc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003bfe:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003c02:	02049593          	slli	a1,s1,0x20
    80003c06:	9181                	srli	a1,a1,0x20
    80003c08:	058a                	slli	a1,a1,0x2
    80003c0a:	00b784b3          	add	s1,a5,a1
    80003c0e:	0004a903          	lw	s2,0(s1)
    80003c12:	02090063          	beqz	s2,80003c32 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003c16:	8552                	mv	a0,s4
    80003c18:	00000097          	auipc	ra,0x0
    80003c1c:	c9c080e7          	jalr	-868(ra) # 800038b4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003c20:	854a                	mv	a0,s2
    80003c22:	70a2                	ld	ra,40(sp)
    80003c24:	7402                	ld	s0,32(sp)
    80003c26:	64e2                	ld	s1,24(sp)
    80003c28:	6942                	ld	s2,16(sp)
    80003c2a:	69a2                	ld	s3,8(sp)
    80003c2c:	6a02                	ld	s4,0(sp)
    80003c2e:	6145                	addi	sp,sp,48
    80003c30:	8082                	ret
      addr = balloc(ip->dev);
    80003c32:	0009a503          	lw	a0,0(s3)
    80003c36:	00000097          	auipc	ra,0x0
    80003c3a:	e10080e7          	jalr	-496(ra) # 80003a46 <balloc>
    80003c3e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003c42:	fc090ae3          	beqz	s2,80003c16 <bmap+0x98>
        a[bn] = addr;
    80003c46:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003c4a:	8552                	mv	a0,s4
    80003c4c:	00001097          	auipc	ra,0x1
    80003c50:	eec080e7          	jalr	-276(ra) # 80004b38 <log_write>
    80003c54:	b7c9                	j	80003c16 <bmap+0x98>
  panic("bmap: out of range");
    80003c56:	00005517          	auipc	a0,0x5
    80003c5a:	9c250513          	addi	a0,a0,-1598 # 80008618 <syscalls+0x148>
    80003c5e:	ffffd097          	auipc	ra,0xffffd
    80003c62:	8e6080e7          	jalr	-1818(ra) # 80000544 <panic>

0000000080003c66 <iget>:
{
    80003c66:	7179                	addi	sp,sp,-48
    80003c68:	f406                	sd	ra,40(sp)
    80003c6a:	f022                	sd	s0,32(sp)
    80003c6c:	ec26                	sd	s1,24(sp)
    80003c6e:	e84a                	sd	s2,16(sp)
    80003c70:	e44e                	sd	s3,8(sp)
    80003c72:	e052                	sd	s4,0(sp)
    80003c74:	1800                	addi	s0,sp,48
    80003c76:	89aa                	mv	s3,a0
    80003c78:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003c7a:	00025517          	auipc	a0,0x25
    80003c7e:	28650513          	addi	a0,a0,646 # 80028f00 <itable>
    80003c82:	ffffd097          	auipc	ra,0xffffd
    80003c86:	f68080e7          	jalr	-152(ra) # 80000bea <acquire>
  empty = 0;
    80003c8a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c8c:	00025497          	auipc	s1,0x25
    80003c90:	28c48493          	addi	s1,s1,652 # 80028f18 <itable+0x18>
    80003c94:	00027697          	auipc	a3,0x27
    80003c98:	d1468693          	addi	a3,a3,-748 # 8002a9a8 <log>
    80003c9c:	a039                	j	80003caa <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c9e:	02090b63          	beqz	s2,80003cd4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ca2:	08848493          	addi	s1,s1,136
    80003ca6:	02d48a63          	beq	s1,a3,80003cda <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003caa:	449c                	lw	a5,8(s1)
    80003cac:	fef059e3          	blez	a5,80003c9e <iget+0x38>
    80003cb0:	4098                	lw	a4,0(s1)
    80003cb2:	ff3716e3          	bne	a4,s3,80003c9e <iget+0x38>
    80003cb6:	40d8                	lw	a4,4(s1)
    80003cb8:	ff4713e3          	bne	a4,s4,80003c9e <iget+0x38>
      ip->ref++;
    80003cbc:	2785                	addiw	a5,a5,1
    80003cbe:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003cc0:	00025517          	auipc	a0,0x25
    80003cc4:	24050513          	addi	a0,a0,576 # 80028f00 <itable>
    80003cc8:	ffffd097          	auipc	ra,0xffffd
    80003ccc:	fd6080e7          	jalr	-42(ra) # 80000c9e <release>
      return ip;
    80003cd0:	8926                	mv	s2,s1
    80003cd2:	a03d                	j	80003d00 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003cd4:	f7f9                	bnez	a5,80003ca2 <iget+0x3c>
    80003cd6:	8926                	mv	s2,s1
    80003cd8:	b7e9                	j	80003ca2 <iget+0x3c>
  if(empty == 0)
    80003cda:	02090c63          	beqz	s2,80003d12 <iget+0xac>
  ip->dev = dev;
    80003cde:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003ce2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003ce6:	4785                	li	a5,1
    80003ce8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003cec:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003cf0:	00025517          	auipc	a0,0x25
    80003cf4:	21050513          	addi	a0,a0,528 # 80028f00 <itable>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	fa6080e7          	jalr	-90(ra) # 80000c9e <release>
}
    80003d00:	854a                	mv	a0,s2
    80003d02:	70a2                	ld	ra,40(sp)
    80003d04:	7402                	ld	s0,32(sp)
    80003d06:	64e2                	ld	s1,24(sp)
    80003d08:	6942                	ld	s2,16(sp)
    80003d0a:	69a2                	ld	s3,8(sp)
    80003d0c:	6a02                	ld	s4,0(sp)
    80003d0e:	6145                	addi	sp,sp,48
    80003d10:	8082                	ret
    panic("iget: no inodes");
    80003d12:	00005517          	auipc	a0,0x5
    80003d16:	91e50513          	addi	a0,a0,-1762 # 80008630 <syscalls+0x160>
    80003d1a:	ffffd097          	auipc	ra,0xffffd
    80003d1e:	82a080e7          	jalr	-2006(ra) # 80000544 <panic>

0000000080003d22 <fsinit>:
fsinit(int dev) {
    80003d22:	7179                	addi	sp,sp,-48
    80003d24:	f406                	sd	ra,40(sp)
    80003d26:	f022                	sd	s0,32(sp)
    80003d28:	ec26                	sd	s1,24(sp)
    80003d2a:	e84a                	sd	s2,16(sp)
    80003d2c:	e44e                	sd	s3,8(sp)
    80003d2e:	1800                	addi	s0,sp,48
    80003d30:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003d32:	4585                	li	a1,1
    80003d34:	00000097          	auipc	ra,0x0
    80003d38:	a50080e7          	jalr	-1456(ra) # 80003784 <bread>
    80003d3c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003d3e:	00025997          	auipc	s3,0x25
    80003d42:	1a298993          	addi	s3,s3,418 # 80028ee0 <sb>
    80003d46:	02000613          	li	a2,32
    80003d4a:	05850593          	addi	a1,a0,88
    80003d4e:	854e                	mv	a0,s3
    80003d50:	ffffd097          	auipc	ra,0xffffd
    80003d54:	ff6080e7          	jalr	-10(ra) # 80000d46 <memmove>
  brelse(bp);
    80003d58:	8526                	mv	a0,s1
    80003d5a:	00000097          	auipc	ra,0x0
    80003d5e:	b5a080e7          	jalr	-1190(ra) # 800038b4 <brelse>
  if(sb.magic != FSMAGIC)
    80003d62:	0009a703          	lw	a4,0(s3)
    80003d66:	102037b7          	lui	a5,0x10203
    80003d6a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003d6e:	02f71263          	bne	a4,a5,80003d92 <fsinit+0x70>
  initlog(dev, &sb);
    80003d72:	00025597          	auipc	a1,0x25
    80003d76:	16e58593          	addi	a1,a1,366 # 80028ee0 <sb>
    80003d7a:	854a                	mv	a0,s2
    80003d7c:	00001097          	auipc	ra,0x1
    80003d80:	b40080e7          	jalr	-1216(ra) # 800048bc <initlog>
}
    80003d84:	70a2                	ld	ra,40(sp)
    80003d86:	7402                	ld	s0,32(sp)
    80003d88:	64e2                	ld	s1,24(sp)
    80003d8a:	6942                	ld	s2,16(sp)
    80003d8c:	69a2                	ld	s3,8(sp)
    80003d8e:	6145                	addi	sp,sp,48
    80003d90:	8082                	ret
    panic("invalid file system");
    80003d92:	00005517          	auipc	a0,0x5
    80003d96:	8ae50513          	addi	a0,a0,-1874 # 80008640 <syscalls+0x170>
    80003d9a:	ffffc097          	auipc	ra,0xffffc
    80003d9e:	7aa080e7          	jalr	1962(ra) # 80000544 <panic>

0000000080003da2 <iinit>:
{
    80003da2:	7179                	addi	sp,sp,-48
    80003da4:	f406                	sd	ra,40(sp)
    80003da6:	f022                	sd	s0,32(sp)
    80003da8:	ec26                	sd	s1,24(sp)
    80003daa:	e84a                	sd	s2,16(sp)
    80003dac:	e44e                	sd	s3,8(sp)
    80003dae:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003db0:	00005597          	auipc	a1,0x5
    80003db4:	8a858593          	addi	a1,a1,-1880 # 80008658 <syscalls+0x188>
    80003db8:	00025517          	auipc	a0,0x25
    80003dbc:	14850513          	addi	a0,a0,328 # 80028f00 <itable>
    80003dc0:	ffffd097          	auipc	ra,0xffffd
    80003dc4:	d9a080e7          	jalr	-614(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003dc8:	00025497          	auipc	s1,0x25
    80003dcc:	16048493          	addi	s1,s1,352 # 80028f28 <itable+0x28>
    80003dd0:	00027997          	auipc	s3,0x27
    80003dd4:	be898993          	addi	s3,s3,-1048 # 8002a9b8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003dd8:	00005917          	auipc	s2,0x5
    80003ddc:	88890913          	addi	s2,s2,-1912 # 80008660 <syscalls+0x190>
    80003de0:	85ca                	mv	a1,s2
    80003de2:	8526                	mv	a0,s1
    80003de4:	00001097          	auipc	ra,0x1
    80003de8:	e3a080e7          	jalr	-454(ra) # 80004c1e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003dec:	08848493          	addi	s1,s1,136
    80003df0:	ff3498e3          	bne	s1,s3,80003de0 <iinit+0x3e>
}
    80003df4:	70a2                	ld	ra,40(sp)
    80003df6:	7402                	ld	s0,32(sp)
    80003df8:	64e2                	ld	s1,24(sp)
    80003dfa:	6942                	ld	s2,16(sp)
    80003dfc:	69a2                	ld	s3,8(sp)
    80003dfe:	6145                	addi	sp,sp,48
    80003e00:	8082                	ret

0000000080003e02 <ialloc>:
{
    80003e02:	715d                	addi	sp,sp,-80
    80003e04:	e486                	sd	ra,72(sp)
    80003e06:	e0a2                	sd	s0,64(sp)
    80003e08:	fc26                	sd	s1,56(sp)
    80003e0a:	f84a                	sd	s2,48(sp)
    80003e0c:	f44e                	sd	s3,40(sp)
    80003e0e:	f052                	sd	s4,32(sp)
    80003e10:	ec56                	sd	s5,24(sp)
    80003e12:	e85a                	sd	s6,16(sp)
    80003e14:	e45e                	sd	s7,8(sp)
    80003e16:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e18:	00025717          	auipc	a4,0x25
    80003e1c:	0d472703          	lw	a4,212(a4) # 80028eec <sb+0xc>
    80003e20:	4785                	li	a5,1
    80003e22:	04e7fa63          	bgeu	a5,a4,80003e76 <ialloc+0x74>
    80003e26:	8aaa                	mv	s5,a0
    80003e28:	8bae                	mv	s7,a1
    80003e2a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003e2c:	00025a17          	auipc	s4,0x25
    80003e30:	0b4a0a13          	addi	s4,s4,180 # 80028ee0 <sb>
    80003e34:	00048b1b          	sext.w	s6,s1
    80003e38:	0044d593          	srli	a1,s1,0x4
    80003e3c:	018a2783          	lw	a5,24(s4)
    80003e40:	9dbd                	addw	a1,a1,a5
    80003e42:	8556                	mv	a0,s5
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	940080e7          	jalr	-1728(ra) # 80003784 <bread>
    80003e4c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003e4e:	05850993          	addi	s3,a0,88
    80003e52:	00f4f793          	andi	a5,s1,15
    80003e56:	079a                	slli	a5,a5,0x6
    80003e58:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003e5a:	00099783          	lh	a5,0(s3)
    80003e5e:	c3a1                	beqz	a5,80003e9e <ialloc+0x9c>
    brelse(bp);
    80003e60:	00000097          	auipc	ra,0x0
    80003e64:	a54080e7          	jalr	-1452(ra) # 800038b4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e68:	0485                	addi	s1,s1,1
    80003e6a:	00ca2703          	lw	a4,12(s4)
    80003e6e:	0004879b          	sext.w	a5,s1
    80003e72:	fce7e1e3          	bltu	a5,a4,80003e34 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003e76:	00004517          	auipc	a0,0x4
    80003e7a:	7f250513          	addi	a0,a0,2034 # 80008668 <syscalls+0x198>
    80003e7e:	ffffc097          	auipc	ra,0xffffc
    80003e82:	710080e7          	jalr	1808(ra) # 8000058e <printf>
  return 0;
    80003e86:	4501                	li	a0,0
}
    80003e88:	60a6                	ld	ra,72(sp)
    80003e8a:	6406                	ld	s0,64(sp)
    80003e8c:	74e2                	ld	s1,56(sp)
    80003e8e:	7942                	ld	s2,48(sp)
    80003e90:	79a2                	ld	s3,40(sp)
    80003e92:	7a02                	ld	s4,32(sp)
    80003e94:	6ae2                	ld	s5,24(sp)
    80003e96:	6b42                	ld	s6,16(sp)
    80003e98:	6ba2                	ld	s7,8(sp)
    80003e9a:	6161                	addi	sp,sp,80
    80003e9c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003e9e:	04000613          	li	a2,64
    80003ea2:	4581                	li	a1,0
    80003ea4:	854e                	mv	a0,s3
    80003ea6:	ffffd097          	auipc	ra,0xffffd
    80003eaa:	e40080e7          	jalr	-448(ra) # 80000ce6 <memset>
      dip->type = type;
    80003eae:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003eb2:	854a                	mv	a0,s2
    80003eb4:	00001097          	auipc	ra,0x1
    80003eb8:	c84080e7          	jalr	-892(ra) # 80004b38 <log_write>
      brelse(bp);
    80003ebc:	854a                	mv	a0,s2
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	9f6080e7          	jalr	-1546(ra) # 800038b4 <brelse>
      return iget(dev, inum);
    80003ec6:	85da                	mv	a1,s6
    80003ec8:	8556                	mv	a0,s5
    80003eca:	00000097          	auipc	ra,0x0
    80003ece:	d9c080e7          	jalr	-612(ra) # 80003c66 <iget>
    80003ed2:	bf5d                	j	80003e88 <ialloc+0x86>

0000000080003ed4 <iupdate>:
{
    80003ed4:	1101                	addi	sp,sp,-32
    80003ed6:	ec06                	sd	ra,24(sp)
    80003ed8:	e822                	sd	s0,16(sp)
    80003eda:	e426                	sd	s1,8(sp)
    80003edc:	e04a                	sd	s2,0(sp)
    80003ede:	1000                	addi	s0,sp,32
    80003ee0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ee2:	415c                	lw	a5,4(a0)
    80003ee4:	0047d79b          	srliw	a5,a5,0x4
    80003ee8:	00025597          	auipc	a1,0x25
    80003eec:	0105a583          	lw	a1,16(a1) # 80028ef8 <sb+0x18>
    80003ef0:	9dbd                	addw	a1,a1,a5
    80003ef2:	4108                	lw	a0,0(a0)
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	890080e7          	jalr	-1904(ra) # 80003784 <bread>
    80003efc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003efe:	05850793          	addi	a5,a0,88
    80003f02:	40c8                	lw	a0,4(s1)
    80003f04:	893d                	andi	a0,a0,15
    80003f06:	051a                	slli	a0,a0,0x6
    80003f08:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003f0a:	04449703          	lh	a4,68(s1)
    80003f0e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003f12:	04649703          	lh	a4,70(s1)
    80003f16:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003f1a:	04849703          	lh	a4,72(s1)
    80003f1e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003f22:	04a49703          	lh	a4,74(s1)
    80003f26:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003f2a:	44f8                	lw	a4,76(s1)
    80003f2c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003f2e:	03400613          	li	a2,52
    80003f32:	05048593          	addi	a1,s1,80
    80003f36:	0531                	addi	a0,a0,12
    80003f38:	ffffd097          	auipc	ra,0xffffd
    80003f3c:	e0e080e7          	jalr	-498(ra) # 80000d46 <memmove>
  log_write(bp);
    80003f40:	854a                	mv	a0,s2
    80003f42:	00001097          	auipc	ra,0x1
    80003f46:	bf6080e7          	jalr	-1034(ra) # 80004b38 <log_write>
  brelse(bp);
    80003f4a:	854a                	mv	a0,s2
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	968080e7          	jalr	-1688(ra) # 800038b4 <brelse>
}
    80003f54:	60e2                	ld	ra,24(sp)
    80003f56:	6442                	ld	s0,16(sp)
    80003f58:	64a2                	ld	s1,8(sp)
    80003f5a:	6902                	ld	s2,0(sp)
    80003f5c:	6105                	addi	sp,sp,32
    80003f5e:	8082                	ret

0000000080003f60 <idup>:
{
    80003f60:	1101                	addi	sp,sp,-32
    80003f62:	ec06                	sd	ra,24(sp)
    80003f64:	e822                	sd	s0,16(sp)
    80003f66:	e426                	sd	s1,8(sp)
    80003f68:	1000                	addi	s0,sp,32
    80003f6a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f6c:	00025517          	auipc	a0,0x25
    80003f70:	f9450513          	addi	a0,a0,-108 # 80028f00 <itable>
    80003f74:	ffffd097          	auipc	ra,0xffffd
    80003f78:	c76080e7          	jalr	-906(ra) # 80000bea <acquire>
  ip->ref++;
    80003f7c:	449c                	lw	a5,8(s1)
    80003f7e:	2785                	addiw	a5,a5,1
    80003f80:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f82:	00025517          	auipc	a0,0x25
    80003f86:	f7e50513          	addi	a0,a0,-130 # 80028f00 <itable>
    80003f8a:	ffffd097          	auipc	ra,0xffffd
    80003f8e:	d14080e7          	jalr	-748(ra) # 80000c9e <release>
}
    80003f92:	8526                	mv	a0,s1
    80003f94:	60e2                	ld	ra,24(sp)
    80003f96:	6442                	ld	s0,16(sp)
    80003f98:	64a2                	ld	s1,8(sp)
    80003f9a:	6105                	addi	sp,sp,32
    80003f9c:	8082                	ret

0000000080003f9e <ilock>:
{
    80003f9e:	1101                	addi	sp,sp,-32
    80003fa0:	ec06                	sd	ra,24(sp)
    80003fa2:	e822                	sd	s0,16(sp)
    80003fa4:	e426                	sd	s1,8(sp)
    80003fa6:	e04a                	sd	s2,0(sp)
    80003fa8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003faa:	c115                	beqz	a0,80003fce <ilock+0x30>
    80003fac:	84aa                	mv	s1,a0
    80003fae:	451c                	lw	a5,8(a0)
    80003fb0:	00f05f63          	blez	a5,80003fce <ilock+0x30>
  acquiresleep(&ip->lock);
    80003fb4:	0541                	addi	a0,a0,16
    80003fb6:	00001097          	auipc	ra,0x1
    80003fba:	ca2080e7          	jalr	-862(ra) # 80004c58 <acquiresleep>
  if(ip->valid == 0){
    80003fbe:	40bc                	lw	a5,64(s1)
    80003fc0:	cf99                	beqz	a5,80003fde <ilock+0x40>
}
    80003fc2:	60e2                	ld	ra,24(sp)
    80003fc4:	6442                	ld	s0,16(sp)
    80003fc6:	64a2                	ld	s1,8(sp)
    80003fc8:	6902                	ld	s2,0(sp)
    80003fca:	6105                	addi	sp,sp,32
    80003fcc:	8082                	ret
    panic("ilock");
    80003fce:	00004517          	auipc	a0,0x4
    80003fd2:	6b250513          	addi	a0,a0,1714 # 80008680 <syscalls+0x1b0>
    80003fd6:	ffffc097          	auipc	ra,0xffffc
    80003fda:	56e080e7          	jalr	1390(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003fde:	40dc                	lw	a5,4(s1)
    80003fe0:	0047d79b          	srliw	a5,a5,0x4
    80003fe4:	00025597          	auipc	a1,0x25
    80003fe8:	f145a583          	lw	a1,-236(a1) # 80028ef8 <sb+0x18>
    80003fec:	9dbd                	addw	a1,a1,a5
    80003fee:	4088                	lw	a0,0(s1)
    80003ff0:	fffff097          	auipc	ra,0xfffff
    80003ff4:	794080e7          	jalr	1940(ra) # 80003784 <bread>
    80003ff8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ffa:	05850593          	addi	a1,a0,88
    80003ffe:	40dc                	lw	a5,4(s1)
    80004000:	8bbd                	andi	a5,a5,15
    80004002:	079a                	slli	a5,a5,0x6
    80004004:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004006:	00059783          	lh	a5,0(a1)
    8000400a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000400e:	00259783          	lh	a5,2(a1)
    80004012:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004016:	00459783          	lh	a5,4(a1)
    8000401a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000401e:	00659783          	lh	a5,6(a1)
    80004022:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004026:	459c                	lw	a5,8(a1)
    80004028:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000402a:	03400613          	li	a2,52
    8000402e:	05b1                	addi	a1,a1,12
    80004030:	05048513          	addi	a0,s1,80
    80004034:	ffffd097          	auipc	ra,0xffffd
    80004038:	d12080e7          	jalr	-750(ra) # 80000d46 <memmove>
    brelse(bp);
    8000403c:	854a                	mv	a0,s2
    8000403e:	00000097          	auipc	ra,0x0
    80004042:	876080e7          	jalr	-1930(ra) # 800038b4 <brelse>
    ip->valid = 1;
    80004046:	4785                	li	a5,1
    80004048:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000404a:	04449783          	lh	a5,68(s1)
    8000404e:	fbb5                	bnez	a5,80003fc2 <ilock+0x24>
      panic("ilock: no type");
    80004050:	00004517          	auipc	a0,0x4
    80004054:	63850513          	addi	a0,a0,1592 # 80008688 <syscalls+0x1b8>
    80004058:	ffffc097          	auipc	ra,0xffffc
    8000405c:	4ec080e7          	jalr	1260(ra) # 80000544 <panic>

0000000080004060 <iunlock>:
{
    80004060:	1101                	addi	sp,sp,-32
    80004062:	ec06                	sd	ra,24(sp)
    80004064:	e822                	sd	s0,16(sp)
    80004066:	e426                	sd	s1,8(sp)
    80004068:	e04a                	sd	s2,0(sp)
    8000406a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000406c:	c905                	beqz	a0,8000409c <iunlock+0x3c>
    8000406e:	84aa                	mv	s1,a0
    80004070:	01050913          	addi	s2,a0,16
    80004074:	854a                	mv	a0,s2
    80004076:	00001097          	auipc	ra,0x1
    8000407a:	c7c080e7          	jalr	-900(ra) # 80004cf2 <holdingsleep>
    8000407e:	cd19                	beqz	a0,8000409c <iunlock+0x3c>
    80004080:	449c                	lw	a5,8(s1)
    80004082:	00f05d63          	blez	a5,8000409c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004086:	854a                	mv	a0,s2
    80004088:	00001097          	auipc	ra,0x1
    8000408c:	c26080e7          	jalr	-986(ra) # 80004cae <releasesleep>
}
    80004090:	60e2                	ld	ra,24(sp)
    80004092:	6442                	ld	s0,16(sp)
    80004094:	64a2                	ld	s1,8(sp)
    80004096:	6902                	ld	s2,0(sp)
    80004098:	6105                	addi	sp,sp,32
    8000409a:	8082                	ret
    panic("iunlock");
    8000409c:	00004517          	auipc	a0,0x4
    800040a0:	5fc50513          	addi	a0,a0,1532 # 80008698 <syscalls+0x1c8>
    800040a4:	ffffc097          	auipc	ra,0xffffc
    800040a8:	4a0080e7          	jalr	1184(ra) # 80000544 <panic>

00000000800040ac <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800040ac:	7179                	addi	sp,sp,-48
    800040ae:	f406                	sd	ra,40(sp)
    800040b0:	f022                	sd	s0,32(sp)
    800040b2:	ec26                	sd	s1,24(sp)
    800040b4:	e84a                	sd	s2,16(sp)
    800040b6:	e44e                	sd	s3,8(sp)
    800040b8:	e052                	sd	s4,0(sp)
    800040ba:	1800                	addi	s0,sp,48
    800040bc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800040be:	05050493          	addi	s1,a0,80
    800040c2:	08050913          	addi	s2,a0,128
    800040c6:	a021                	j	800040ce <itrunc+0x22>
    800040c8:	0491                	addi	s1,s1,4
    800040ca:	01248d63          	beq	s1,s2,800040e4 <itrunc+0x38>
    if(ip->addrs[i]){
    800040ce:	408c                	lw	a1,0(s1)
    800040d0:	dde5                	beqz	a1,800040c8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800040d2:	0009a503          	lw	a0,0(s3)
    800040d6:	00000097          	auipc	ra,0x0
    800040da:	8f4080e7          	jalr	-1804(ra) # 800039ca <bfree>
      ip->addrs[i] = 0;
    800040de:	0004a023          	sw	zero,0(s1)
    800040e2:	b7dd                	j	800040c8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800040e4:	0809a583          	lw	a1,128(s3)
    800040e8:	e185                	bnez	a1,80004108 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800040ea:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800040ee:	854e                	mv	a0,s3
    800040f0:	00000097          	auipc	ra,0x0
    800040f4:	de4080e7          	jalr	-540(ra) # 80003ed4 <iupdate>
}
    800040f8:	70a2                	ld	ra,40(sp)
    800040fa:	7402                	ld	s0,32(sp)
    800040fc:	64e2                	ld	s1,24(sp)
    800040fe:	6942                	ld	s2,16(sp)
    80004100:	69a2                	ld	s3,8(sp)
    80004102:	6a02                	ld	s4,0(sp)
    80004104:	6145                	addi	sp,sp,48
    80004106:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004108:	0009a503          	lw	a0,0(s3)
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	678080e7          	jalr	1656(ra) # 80003784 <bread>
    80004114:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004116:	05850493          	addi	s1,a0,88
    8000411a:	45850913          	addi	s2,a0,1112
    8000411e:	a811                	j	80004132 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004120:	0009a503          	lw	a0,0(s3)
    80004124:	00000097          	auipc	ra,0x0
    80004128:	8a6080e7          	jalr	-1882(ra) # 800039ca <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000412c:	0491                	addi	s1,s1,4
    8000412e:	01248563          	beq	s1,s2,80004138 <itrunc+0x8c>
      if(a[j])
    80004132:	408c                	lw	a1,0(s1)
    80004134:	dde5                	beqz	a1,8000412c <itrunc+0x80>
    80004136:	b7ed                	j	80004120 <itrunc+0x74>
    brelse(bp);
    80004138:	8552                	mv	a0,s4
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	77a080e7          	jalr	1914(ra) # 800038b4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004142:	0809a583          	lw	a1,128(s3)
    80004146:	0009a503          	lw	a0,0(s3)
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	880080e7          	jalr	-1920(ra) # 800039ca <bfree>
    ip->addrs[NDIRECT] = 0;
    80004152:	0809a023          	sw	zero,128(s3)
    80004156:	bf51                	j	800040ea <itrunc+0x3e>

0000000080004158 <iput>:
{
    80004158:	1101                	addi	sp,sp,-32
    8000415a:	ec06                	sd	ra,24(sp)
    8000415c:	e822                	sd	s0,16(sp)
    8000415e:	e426                	sd	s1,8(sp)
    80004160:	e04a                	sd	s2,0(sp)
    80004162:	1000                	addi	s0,sp,32
    80004164:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004166:	00025517          	auipc	a0,0x25
    8000416a:	d9a50513          	addi	a0,a0,-614 # 80028f00 <itable>
    8000416e:	ffffd097          	auipc	ra,0xffffd
    80004172:	a7c080e7          	jalr	-1412(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004176:	4498                	lw	a4,8(s1)
    80004178:	4785                	li	a5,1
    8000417a:	02f70363          	beq	a4,a5,800041a0 <iput+0x48>
  ip->ref--;
    8000417e:	449c                	lw	a5,8(s1)
    80004180:	37fd                	addiw	a5,a5,-1
    80004182:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004184:	00025517          	auipc	a0,0x25
    80004188:	d7c50513          	addi	a0,a0,-644 # 80028f00 <itable>
    8000418c:	ffffd097          	auipc	ra,0xffffd
    80004190:	b12080e7          	jalr	-1262(ra) # 80000c9e <release>
}
    80004194:	60e2                	ld	ra,24(sp)
    80004196:	6442                	ld	s0,16(sp)
    80004198:	64a2                	ld	s1,8(sp)
    8000419a:	6902                	ld	s2,0(sp)
    8000419c:	6105                	addi	sp,sp,32
    8000419e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800041a0:	40bc                	lw	a5,64(s1)
    800041a2:	dff1                	beqz	a5,8000417e <iput+0x26>
    800041a4:	04a49783          	lh	a5,74(s1)
    800041a8:	fbf9                	bnez	a5,8000417e <iput+0x26>
    acquiresleep(&ip->lock);
    800041aa:	01048913          	addi	s2,s1,16
    800041ae:	854a                	mv	a0,s2
    800041b0:	00001097          	auipc	ra,0x1
    800041b4:	aa8080e7          	jalr	-1368(ra) # 80004c58 <acquiresleep>
    release(&itable.lock);
    800041b8:	00025517          	auipc	a0,0x25
    800041bc:	d4850513          	addi	a0,a0,-696 # 80028f00 <itable>
    800041c0:	ffffd097          	auipc	ra,0xffffd
    800041c4:	ade080e7          	jalr	-1314(ra) # 80000c9e <release>
    itrunc(ip);
    800041c8:	8526                	mv	a0,s1
    800041ca:	00000097          	auipc	ra,0x0
    800041ce:	ee2080e7          	jalr	-286(ra) # 800040ac <itrunc>
    ip->type = 0;
    800041d2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800041d6:	8526                	mv	a0,s1
    800041d8:	00000097          	auipc	ra,0x0
    800041dc:	cfc080e7          	jalr	-772(ra) # 80003ed4 <iupdate>
    ip->valid = 0;
    800041e0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800041e4:	854a                	mv	a0,s2
    800041e6:	00001097          	auipc	ra,0x1
    800041ea:	ac8080e7          	jalr	-1336(ra) # 80004cae <releasesleep>
    acquire(&itable.lock);
    800041ee:	00025517          	auipc	a0,0x25
    800041f2:	d1250513          	addi	a0,a0,-750 # 80028f00 <itable>
    800041f6:	ffffd097          	auipc	ra,0xffffd
    800041fa:	9f4080e7          	jalr	-1548(ra) # 80000bea <acquire>
    800041fe:	b741                	j	8000417e <iput+0x26>

0000000080004200 <iunlockput>:
{
    80004200:	1101                	addi	sp,sp,-32
    80004202:	ec06                	sd	ra,24(sp)
    80004204:	e822                	sd	s0,16(sp)
    80004206:	e426                	sd	s1,8(sp)
    80004208:	1000                	addi	s0,sp,32
    8000420a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000420c:	00000097          	auipc	ra,0x0
    80004210:	e54080e7          	jalr	-428(ra) # 80004060 <iunlock>
  iput(ip);
    80004214:	8526                	mv	a0,s1
    80004216:	00000097          	auipc	ra,0x0
    8000421a:	f42080e7          	jalr	-190(ra) # 80004158 <iput>
}
    8000421e:	60e2                	ld	ra,24(sp)
    80004220:	6442                	ld	s0,16(sp)
    80004222:	64a2                	ld	s1,8(sp)
    80004224:	6105                	addi	sp,sp,32
    80004226:	8082                	ret

0000000080004228 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004228:	1141                	addi	sp,sp,-16
    8000422a:	e422                	sd	s0,8(sp)
    8000422c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000422e:	411c                	lw	a5,0(a0)
    80004230:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004232:	415c                	lw	a5,4(a0)
    80004234:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004236:	04451783          	lh	a5,68(a0)
    8000423a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000423e:	04a51783          	lh	a5,74(a0)
    80004242:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004246:	04c56783          	lwu	a5,76(a0)
    8000424a:	e99c                	sd	a5,16(a1)
}
    8000424c:	6422                	ld	s0,8(sp)
    8000424e:	0141                	addi	sp,sp,16
    80004250:	8082                	ret

0000000080004252 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004252:	457c                	lw	a5,76(a0)
    80004254:	0ed7e963          	bltu	a5,a3,80004346 <readi+0xf4>
{
    80004258:	7159                	addi	sp,sp,-112
    8000425a:	f486                	sd	ra,104(sp)
    8000425c:	f0a2                	sd	s0,96(sp)
    8000425e:	eca6                	sd	s1,88(sp)
    80004260:	e8ca                	sd	s2,80(sp)
    80004262:	e4ce                	sd	s3,72(sp)
    80004264:	e0d2                	sd	s4,64(sp)
    80004266:	fc56                	sd	s5,56(sp)
    80004268:	f85a                	sd	s6,48(sp)
    8000426a:	f45e                	sd	s7,40(sp)
    8000426c:	f062                	sd	s8,32(sp)
    8000426e:	ec66                	sd	s9,24(sp)
    80004270:	e86a                	sd	s10,16(sp)
    80004272:	e46e                	sd	s11,8(sp)
    80004274:	1880                	addi	s0,sp,112
    80004276:	8b2a                	mv	s6,a0
    80004278:	8bae                	mv	s7,a1
    8000427a:	8a32                	mv	s4,a2
    8000427c:	84b6                	mv	s1,a3
    8000427e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004280:	9f35                	addw	a4,a4,a3
    return 0;
    80004282:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004284:	0ad76063          	bltu	a4,a3,80004324 <readi+0xd2>
  if(off + n > ip->size)
    80004288:	00e7f463          	bgeu	a5,a4,80004290 <readi+0x3e>
    n = ip->size - off;
    8000428c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004290:	0a0a8963          	beqz	s5,80004342 <readi+0xf0>
    80004294:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004296:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000429a:	5c7d                	li	s8,-1
    8000429c:	a82d                	j	800042d6 <readi+0x84>
    8000429e:	020d1d93          	slli	s11,s10,0x20
    800042a2:	020ddd93          	srli	s11,s11,0x20
    800042a6:	05890613          	addi	a2,s2,88
    800042aa:	86ee                	mv	a3,s11
    800042ac:	963a                	add	a2,a2,a4
    800042ae:	85d2                	mv	a1,s4
    800042b0:	855e                	mv	a0,s7
    800042b2:	ffffe097          	auipc	ra,0xffffe
    800042b6:	73e080e7          	jalr	1854(ra) # 800029f0 <either_copyout>
    800042ba:	05850d63          	beq	a0,s8,80004314 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800042be:	854a                	mv	a0,s2
    800042c0:	fffff097          	auipc	ra,0xfffff
    800042c4:	5f4080e7          	jalr	1524(ra) # 800038b4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042c8:	013d09bb          	addw	s3,s10,s3
    800042cc:	009d04bb          	addw	s1,s10,s1
    800042d0:	9a6e                	add	s4,s4,s11
    800042d2:	0559f763          	bgeu	s3,s5,80004320 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800042d6:	00a4d59b          	srliw	a1,s1,0xa
    800042da:	855a                	mv	a0,s6
    800042dc:	00000097          	auipc	ra,0x0
    800042e0:	8a2080e7          	jalr	-1886(ra) # 80003b7e <bmap>
    800042e4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800042e8:	cd85                	beqz	a1,80004320 <readi+0xce>
    bp = bread(ip->dev, addr);
    800042ea:	000b2503          	lw	a0,0(s6)
    800042ee:	fffff097          	auipc	ra,0xfffff
    800042f2:	496080e7          	jalr	1174(ra) # 80003784 <bread>
    800042f6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800042f8:	3ff4f713          	andi	a4,s1,1023
    800042fc:	40ec87bb          	subw	a5,s9,a4
    80004300:	413a86bb          	subw	a3,s5,s3
    80004304:	8d3e                	mv	s10,a5
    80004306:	2781                	sext.w	a5,a5
    80004308:	0006861b          	sext.w	a2,a3
    8000430c:	f8f679e3          	bgeu	a2,a5,8000429e <readi+0x4c>
    80004310:	8d36                	mv	s10,a3
    80004312:	b771                	j	8000429e <readi+0x4c>
      brelse(bp);
    80004314:	854a                	mv	a0,s2
    80004316:	fffff097          	auipc	ra,0xfffff
    8000431a:	59e080e7          	jalr	1438(ra) # 800038b4 <brelse>
      tot = -1;
    8000431e:	59fd                	li	s3,-1
  }
  return tot;
    80004320:	0009851b          	sext.w	a0,s3
}
    80004324:	70a6                	ld	ra,104(sp)
    80004326:	7406                	ld	s0,96(sp)
    80004328:	64e6                	ld	s1,88(sp)
    8000432a:	6946                	ld	s2,80(sp)
    8000432c:	69a6                	ld	s3,72(sp)
    8000432e:	6a06                	ld	s4,64(sp)
    80004330:	7ae2                	ld	s5,56(sp)
    80004332:	7b42                	ld	s6,48(sp)
    80004334:	7ba2                	ld	s7,40(sp)
    80004336:	7c02                	ld	s8,32(sp)
    80004338:	6ce2                	ld	s9,24(sp)
    8000433a:	6d42                	ld	s10,16(sp)
    8000433c:	6da2                	ld	s11,8(sp)
    8000433e:	6165                	addi	sp,sp,112
    80004340:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004342:	89d6                	mv	s3,s5
    80004344:	bff1                	j	80004320 <readi+0xce>
    return 0;
    80004346:	4501                	li	a0,0
}
    80004348:	8082                	ret

000000008000434a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000434a:	457c                	lw	a5,76(a0)
    8000434c:	10d7e863          	bltu	a5,a3,8000445c <writei+0x112>
{
    80004350:	7159                	addi	sp,sp,-112
    80004352:	f486                	sd	ra,104(sp)
    80004354:	f0a2                	sd	s0,96(sp)
    80004356:	eca6                	sd	s1,88(sp)
    80004358:	e8ca                	sd	s2,80(sp)
    8000435a:	e4ce                	sd	s3,72(sp)
    8000435c:	e0d2                	sd	s4,64(sp)
    8000435e:	fc56                	sd	s5,56(sp)
    80004360:	f85a                	sd	s6,48(sp)
    80004362:	f45e                	sd	s7,40(sp)
    80004364:	f062                	sd	s8,32(sp)
    80004366:	ec66                	sd	s9,24(sp)
    80004368:	e86a                	sd	s10,16(sp)
    8000436a:	e46e                	sd	s11,8(sp)
    8000436c:	1880                	addi	s0,sp,112
    8000436e:	8aaa                	mv	s5,a0
    80004370:	8bae                	mv	s7,a1
    80004372:	8a32                	mv	s4,a2
    80004374:	8936                	mv	s2,a3
    80004376:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004378:	00e687bb          	addw	a5,a3,a4
    8000437c:	0ed7e263          	bltu	a5,a3,80004460 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004380:	00043737          	lui	a4,0x43
    80004384:	0ef76063          	bltu	a4,a5,80004464 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004388:	0c0b0863          	beqz	s6,80004458 <writei+0x10e>
    8000438c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000438e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004392:	5c7d                	li	s8,-1
    80004394:	a091                	j	800043d8 <writei+0x8e>
    80004396:	020d1d93          	slli	s11,s10,0x20
    8000439a:	020ddd93          	srli	s11,s11,0x20
    8000439e:	05848513          	addi	a0,s1,88
    800043a2:	86ee                	mv	a3,s11
    800043a4:	8652                	mv	a2,s4
    800043a6:	85de                	mv	a1,s7
    800043a8:	953a                	add	a0,a0,a4
    800043aa:	ffffe097          	auipc	ra,0xffffe
    800043ae:	69c080e7          	jalr	1692(ra) # 80002a46 <either_copyin>
    800043b2:	07850263          	beq	a0,s8,80004416 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800043b6:	8526                	mv	a0,s1
    800043b8:	00000097          	auipc	ra,0x0
    800043bc:	780080e7          	jalr	1920(ra) # 80004b38 <log_write>
    brelse(bp);
    800043c0:	8526                	mv	a0,s1
    800043c2:	fffff097          	auipc	ra,0xfffff
    800043c6:	4f2080e7          	jalr	1266(ra) # 800038b4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043ca:	013d09bb          	addw	s3,s10,s3
    800043ce:	012d093b          	addw	s2,s10,s2
    800043d2:	9a6e                	add	s4,s4,s11
    800043d4:	0569f663          	bgeu	s3,s6,80004420 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800043d8:	00a9559b          	srliw	a1,s2,0xa
    800043dc:	8556                	mv	a0,s5
    800043de:	fffff097          	auipc	ra,0xfffff
    800043e2:	7a0080e7          	jalr	1952(ra) # 80003b7e <bmap>
    800043e6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800043ea:	c99d                	beqz	a1,80004420 <writei+0xd6>
    bp = bread(ip->dev, addr);
    800043ec:	000aa503          	lw	a0,0(s5)
    800043f0:	fffff097          	auipc	ra,0xfffff
    800043f4:	394080e7          	jalr	916(ra) # 80003784 <bread>
    800043f8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800043fa:	3ff97713          	andi	a4,s2,1023
    800043fe:	40ec87bb          	subw	a5,s9,a4
    80004402:	413b06bb          	subw	a3,s6,s3
    80004406:	8d3e                	mv	s10,a5
    80004408:	2781                	sext.w	a5,a5
    8000440a:	0006861b          	sext.w	a2,a3
    8000440e:	f8f674e3          	bgeu	a2,a5,80004396 <writei+0x4c>
    80004412:	8d36                	mv	s10,a3
    80004414:	b749                	j	80004396 <writei+0x4c>
      brelse(bp);
    80004416:	8526                	mv	a0,s1
    80004418:	fffff097          	auipc	ra,0xfffff
    8000441c:	49c080e7          	jalr	1180(ra) # 800038b4 <brelse>
  }

  if(off > ip->size)
    80004420:	04caa783          	lw	a5,76(s5)
    80004424:	0127f463          	bgeu	a5,s2,8000442c <writei+0xe2>
    ip->size = off;
    80004428:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000442c:	8556                	mv	a0,s5
    8000442e:	00000097          	auipc	ra,0x0
    80004432:	aa6080e7          	jalr	-1370(ra) # 80003ed4 <iupdate>

  return tot;
    80004436:	0009851b          	sext.w	a0,s3
}
    8000443a:	70a6                	ld	ra,104(sp)
    8000443c:	7406                	ld	s0,96(sp)
    8000443e:	64e6                	ld	s1,88(sp)
    80004440:	6946                	ld	s2,80(sp)
    80004442:	69a6                	ld	s3,72(sp)
    80004444:	6a06                	ld	s4,64(sp)
    80004446:	7ae2                	ld	s5,56(sp)
    80004448:	7b42                	ld	s6,48(sp)
    8000444a:	7ba2                	ld	s7,40(sp)
    8000444c:	7c02                	ld	s8,32(sp)
    8000444e:	6ce2                	ld	s9,24(sp)
    80004450:	6d42                	ld	s10,16(sp)
    80004452:	6da2                	ld	s11,8(sp)
    80004454:	6165                	addi	sp,sp,112
    80004456:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004458:	89da                	mv	s3,s6
    8000445a:	bfc9                	j	8000442c <writei+0xe2>
    return -1;
    8000445c:	557d                	li	a0,-1
}
    8000445e:	8082                	ret
    return -1;
    80004460:	557d                	li	a0,-1
    80004462:	bfe1                	j	8000443a <writei+0xf0>
    return -1;
    80004464:	557d                	li	a0,-1
    80004466:	bfd1                	j	8000443a <writei+0xf0>

0000000080004468 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004468:	1141                	addi	sp,sp,-16
    8000446a:	e406                	sd	ra,8(sp)
    8000446c:	e022                	sd	s0,0(sp)
    8000446e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004470:	4639                	li	a2,14
    80004472:	ffffd097          	auipc	ra,0xffffd
    80004476:	94c080e7          	jalr	-1716(ra) # 80000dbe <strncmp>
}
    8000447a:	60a2                	ld	ra,8(sp)
    8000447c:	6402                	ld	s0,0(sp)
    8000447e:	0141                	addi	sp,sp,16
    80004480:	8082                	ret

0000000080004482 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004482:	7139                	addi	sp,sp,-64
    80004484:	fc06                	sd	ra,56(sp)
    80004486:	f822                	sd	s0,48(sp)
    80004488:	f426                	sd	s1,40(sp)
    8000448a:	f04a                	sd	s2,32(sp)
    8000448c:	ec4e                	sd	s3,24(sp)
    8000448e:	e852                	sd	s4,16(sp)
    80004490:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004492:	04451703          	lh	a4,68(a0)
    80004496:	4785                	li	a5,1
    80004498:	00f71a63          	bne	a4,a5,800044ac <dirlookup+0x2a>
    8000449c:	892a                	mv	s2,a0
    8000449e:	89ae                	mv	s3,a1
    800044a0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800044a2:	457c                	lw	a5,76(a0)
    800044a4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800044a6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044a8:	e79d                	bnez	a5,800044d6 <dirlookup+0x54>
    800044aa:	a8a5                	j	80004522 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800044ac:	00004517          	auipc	a0,0x4
    800044b0:	1f450513          	addi	a0,a0,500 # 800086a0 <syscalls+0x1d0>
    800044b4:	ffffc097          	auipc	ra,0xffffc
    800044b8:	090080e7          	jalr	144(ra) # 80000544 <panic>
      panic("dirlookup read");
    800044bc:	00004517          	auipc	a0,0x4
    800044c0:	1fc50513          	addi	a0,a0,508 # 800086b8 <syscalls+0x1e8>
    800044c4:	ffffc097          	auipc	ra,0xffffc
    800044c8:	080080e7          	jalr	128(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044cc:	24c1                	addiw	s1,s1,16
    800044ce:	04c92783          	lw	a5,76(s2)
    800044d2:	04f4f763          	bgeu	s1,a5,80004520 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044d6:	4741                	li	a4,16
    800044d8:	86a6                	mv	a3,s1
    800044da:	fc040613          	addi	a2,s0,-64
    800044de:	4581                	li	a1,0
    800044e0:	854a                	mv	a0,s2
    800044e2:	00000097          	auipc	ra,0x0
    800044e6:	d70080e7          	jalr	-656(ra) # 80004252 <readi>
    800044ea:	47c1                	li	a5,16
    800044ec:	fcf518e3          	bne	a0,a5,800044bc <dirlookup+0x3a>
    if(de.inum == 0)
    800044f0:	fc045783          	lhu	a5,-64(s0)
    800044f4:	dfe1                	beqz	a5,800044cc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800044f6:	fc240593          	addi	a1,s0,-62
    800044fa:	854e                	mv	a0,s3
    800044fc:	00000097          	auipc	ra,0x0
    80004500:	f6c080e7          	jalr	-148(ra) # 80004468 <namecmp>
    80004504:	f561                	bnez	a0,800044cc <dirlookup+0x4a>
      if(poff)
    80004506:	000a0463          	beqz	s4,8000450e <dirlookup+0x8c>
        *poff = off;
    8000450a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000450e:	fc045583          	lhu	a1,-64(s0)
    80004512:	00092503          	lw	a0,0(s2)
    80004516:	fffff097          	auipc	ra,0xfffff
    8000451a:	750080e7          	jalr	1872(ra) # 80003c66 <iget>
    8000451e:	a011                	j	80004522 <dirlookup+0xa0>
  return 0;
    80004520:	4501                	li	a0,0
}
    80004522:	70e2                	ld	ra,56(sp)
    80004524:	7442                	ld	s0,48(sp)
    80004526:	74a2                	ld	s1,40(sp)
    80004528:	7902                	ld	s2,32(sp)
    8000452a:	69e2                	ld	s3,24(sp)
    8000452c:	6a42                	ld	s4,16(sp)
    8000452e:	6121                	addi	sp,sp,64
    80004530:	8082                	ret

0000000080004532 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004532:	711d                	addi	sp,sp,-96
    80004534:	ec86                	sd	ra,88(sp)
    80004536:	e8a2                	sd	s0,80(sp)
    80004538:	e4a6                	sd	s1,72(sp)
    8000453a:	e0ca                	sd	s2,64(sp)
    8000453c:	fc4e                	sd	s3,56(sp)
    8000453e:	f852                	sd	s4,48(sp)
    80004540:	f456                	sd	s5,40(sp)
    80004542:	f05a                	sd	s6,32(sp)
    80004544:	ec5e                	sd	s7,24(sp)
    80004546:	e862                	sd	s8,16(sp)
    80004548:	e466                	sd	s9,8(sp)
    8000454a:	1080                	addi	s0,sp,96
    8000454c:	84aa                	mv	s1,a0
    8000454e:	8b2e                	mv	s6,a1
    80004550:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004552:	00054703          	lbu	a4,0(a0)
    80004556:	02f00793          	li	a5,47
    8000455a:	02f70363          	beq	a4,a5,80004580 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000455e:	ffffd097          	auipc	ra,0xffffd
    80004562:	5ce080e7          	jalr	1486(ra) # 80001b2c <myproc>
    80004566:	15053503          	ld	a0,336(a0)
    8000456a:	00000097          	auipc	ra,0x0
    8000456e:	9f6080e7          	jalr	-1546(ra) # 80003f60 <idup>
    80004572:	89aa                	mv	s3,a0
  while(*path == '/')
    80004574:	02f00913          	li	s2,47
  len = path - s;
    80004578:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000457a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000457c:	4c05                	li	s8,1
    8000457e:	a865                	j	80004636 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004580:	4585                	li	a1,1
    80004582:	4505                	li	a0,1
    80004584:	fffff097          	auipc	ra,0xfffff
    80004588:	6e2080e7          	jalr	1762(ra) # 80003c66 <iget>
    8000458c:	89aa                	mv	s3,a0
    8000458e:	b7dd                	j	80004574 <namex+0x42>
      iunlockput(ip);
    80004590:	854e                	mv	a0,s3
    80004592:	00000097          	auipc	ra,0x0
    80004596:	c6e080e7          	jalr	-914(ra) # 80004200 <iunlockput>
      return 0;
    8000459a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000459c:	854e                	mv	a0,s3
    8000459e:	60e6                	ld	ra,88(sp)
    800045a0:	6446                	ld	s0,80(sp)
    800045a2:	64a6                	ld	s1,72(sp)
    800045a4:	6906                	ld	s2,64(sp)
    800045a6:	79e2                	ld	s3,56(sp)
    800045a8:	7a42                	ld	s4,48(sp)
    800045aa:	7aa2                	ld	s5,40(sp)
    800045ac:	7b02                	ld	s6,32(sp)
    800045ae:	6be2                	ld	s7,24(sp)
    800045b0:	6c42                	ld	s8,16(sp)
    800045b2:	6ca2                	ld	s9,8(sp)
    800045b4:	6125                	addi	sp,sp,96
    800045b6:	8082                	ret
      iunlock(ip);
    800045b8:	854e                	mv	a0,s3
    800045ba:	00000097          	auipc	ra,0x0
    800045be:	aa6080e7          	jalr	-1370(ra) # 80004060 <iunlock>
      return ip;
    800045c2:	bfe9                	j	8000459c <namex+0x6a>
      iunlockput(ip);
    800045c4:	854e                	mv	a0,s3
    800045c6:	00000097          	auipc	ra,0x0
    800045ca:	c3a080e7          	jalr	-966(ra) # 80004200 <iunlockput>
      return 0;
    800045ce:	89d2                	mv	s3,s4
    800045d0:	b7f1                	j	8000459c <namex+0x6a>
  len = path - s;
    800045d2:	40b48633          	sub	a2,s1,a1
    800045d6:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800045da:	094cd463          	bge	s9,s4,80004662 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800045de:	4639                	li	a2,14
    800045e0:	8556                	mv	a0,s5
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	764080e7          	jalr	1892(ra) # 80000d46 <memmove>
  while(*path == '/')
    800045ea:	0004c783          	lbu	a5,0(s1)
    800045ee:	01279763          	bne	a5,s2,800045fc <namex+0xca>
    path++;
    800045f2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800045f4:	0004c783          	lbu	a5,0(s1)
    800045f8:	ff278de3          	beq	a5,s2,800045f2 <namex+0xc0>
    ilock(ip);
    800045fc:	854e                	mv	a0,s3
    800045fe:	00000097          	auipc	ra,0x0
    80004602:	9a0080e7          	jalr	-1632(ra) # 80003f9e <ilock>
    if(ip->type != T_DIR){
    80004606:	04499783          	lh	a5,68(s3)
    8000460a:	f98793e3          	bne	a5,s8,80004590 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000460e:	000b0563          	beqz	s6,80004618 <namex+0xe6>
    80004612:	0004c783          	lbu	a5,0(s1)
    80004616:	d3cd                	beqz	a5,800045b8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004618:	865e                	mv	a2,s7
    8000461a:	85d6                	mv	a1,s5
    8000461c:	854e                	mv	a0,s3
    8000461e:	00000097          	auipc	ra,0x0
    80004622:	e64080e7          	jalr	-412(ra) # 80004482 <dirlookup>
    80004626:	8a2a                	mv	s4,a0
    80004628:	dd51                	beqz	a0,800045c4 <namex+0x92>
    iunlockput(ip);
    8000462a:	854e                	mv	a0,s3
    8000462c:	00000097          	auipc	ra,0x0
    80004630:	bd4080e7          	jalr	-1068(ra) # 80004200 <iunlockput>
    ip = next;
    80004634:	89d2                	mv	s3,s4
  while(*path == '/')
    80004636:	0004c783          	lbu	a5,0(s1)
    8000463a:	05279763          	bne	a5,s2,80004688 <namex+0x156>
    path++;
    8000463e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004640:	0004c783          	lbu	a5,0(s1)
    80004644:	ff278de3          	beq	a5,s2,8000463e <namex+0x10c>
  if(*path == 0)
    80004648:	c79d                	beqz	a5,80004676 <namex+0x144>
    path++;
    8000464a:	85a6                	mv	a1,s1
  len = path - s;
    8000464c:	8a5e                	mv	s4,s7
    8000464e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004650:	01278963          	beq	a5,s2,80004662 <namex+0x130>
    80004654:	dfbd                	beqz	a5,800045d2 <namex+0xa0>
    path++;
    80004656:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004658:	0004c783          	lbu	a5,0(s1)
    8000465c:	ff279ce3          	bne	a5,s2,80004654 <namex+0x122>
    80004660:	bf8d                	j	800045d2 <namex+0xa0>
    memmove(name, s, len);
    80004662:	2601                	sext.w	a2,a2
    80004664:	8556                	mv	a0,s5
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	6e0080e7          	jalr	1760(ra) # 80000d46 <memmove>
    name[len] = 0;
    8000466e:	9a56                	add	s4,s4,s5
    80004670:	000a0023          	sb	zero,0(s4)
    80004674:	bf9d                	j	800045ea <namex+0xb8>
  if(nameiparent){
    80004676:	f20b03e3          	beqz	s6,8000459c <namex+0x6a>
    iput(ip);
    8000467a:	854e                	mv	a0,s3
    8000467c:	00000097          	auipc	ra,0x0
    80004680:	adc080e7          	jalr	-1316(ra) # 80004158 <iput>
    return 0;
    80004684:	4981                	li	s3,0
    80004686:	bf19                	j	8000459c <namex+0x6a>
  if(*path == 0)
    80004688:	d7fd                	beqz	a5,80004676 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000468a:	0004c783          	lbu	a5,0(s1)
    8000468e:	85a6                	mv	a1,s1
    80004690:	b7d1                	j	80004654 <namex+0x122>

0000000080004692 <dirlink>:
{
    80004692:	7139                	addi	sp,sp,-64
    80004694:	fc06                	sd	ra,56(sp)
    80004696:	f822                	sd	s0,48(sp)
    80004698:	f426                	sd	s1,40(sp)
    8000469a:	f04a                	sd	s2,32(sp)
    8000469c:	ec4e                	sd	s3,24(sp)
    8000469e:	e852                	sd	s4,16(sp)
    800046a0:	0080                	addi	s0,sp,64
    800046a2:	892a                	mv	s2,a0
    800046a4:	8a2e                	mv	s4,a1
    800046a6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800046a8:	4601                	li	a2,0
    800046aa:	00000097          	auipc	ra,0x0
    800046ae:	dd8080e7          	jalr	-552(ra) # 80004482 <dirlookup>
    800046b2:	e93d                	bnez	a0,80004728 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046b4:	04c92483          	lw	s1,76(s2)
    800046b8:	c49d                	beqz	s1,800046e6 <dirlink+0x54>
    800046ba:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046bc:	4741                	li	a4,16
    800046be:	86a6                	mv	a3,s1
    800046c0:	fc040613          	addi	a2,s0,-64
    800046c4:	4581                	li	a1,0
    800046c6:	854a                	mv	a0,s2
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	b8a080e7          	jalr	-1142(ra) # 80004252 <readi>
    800046d0:	47c1                	li	a5,16
    800046d2:	06f51163          	bne	a0,a5,80004734 <dirlink+0xa2>
    if(de.inum == 0)
    800046d6:	fc045783          	lhu	a5,-64(s0)
    800046da:	c791                	beqz	a5,800046e6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046dc:	24c1                	addiw	s1,s1,16
    800046de:	04c92783          	lw	a5,76(s2)
    800046e2:	fcf4ede3          	bltu	s1,a5,800046bc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800046e6:	4639                	li	a2,14
    800046e8:	85d2                	mv	a1,s4
    800046ea:	fc240513          	addi	a0,s0,-62
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	70c080e7          	jalr	1804(ra) # 80000dfa <strncpy>
  de.inum = inum;
    800046f6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046fa:	4741                	li	a4,16
    800046fc:	86a6                	mv	a3,s1
    800046fe:	fc040613          	addi	a2,s0,-64
    80004702:	4581                	li	a1,0
    80004704:	854a                	mv	a0,s2
    80004706:	00000097          	auipc	ra,0x0
    8000470a:	c44080e7          	jalr	-956(ra) # 8000434a <writei>
    8000470e:	1541                	addi	a0,a0,-16
    80004710:	00a03533          	snez	a0,a0
    80004714:	40a00533          	neg	a0,a0
}
    80004718:	70e2                	ld	ra,56(sp)
    8000471a:	7442                	ld	s0,48(sp)
    8000471c:	74a2                	ld	s1,40(sp)
    8000471e:	7902                	ld	s2,32(sp)
    80004720:	69e2                	ld	s3,24(sp)
    80004722:	6a42                	ld	s4,16(sp)
    80004724:	6121                	addi	sp,sp,64
    80004726:	8082                	ret
    iput(ip);
    80004728:	00000097          	auipc	ra,0x0
    8000472c:	a30080e7          	jalr	-1488(ra) # 80004158 <iput>
    return -1;
    80004730:	557d                	li	a0,-1
    80004732:	b7dd                	j	80004718 <dirlink+0x86>
      panic("dirlink read");
    80004734:	00004517          	auipc	a0,0x4
    80004738:	f9450513          	addi	a0,a0,-108 # 800086c8 <syscalls+0x1f8>
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	e08080e7          	jalr	-504(ra) # 80000544 <panic>

0000000080004744 <namei>:

struct inode*
namei(char *path)
{
    80004744:	1101                	addi	sp,sp,-32
    80004746:	ec06                	sd	ra,24(sp)
    80004748:	e822                	sd	s0,16(sp)
    8000474a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000474c:	fe040613          	addi	a2,s0,-32
    80004750:	4581                	li	a1,0
    80004752:	00000097          	auipc	ra,0x0
    80004756:	de0080e7          	jalr	-544(ra) # 80004532 <namex>
}
    8000475a:	60e2                	ld	ra,24(sp)
    8000475c:	6442                	ld	s0,16(sp)
    8000475e:	6105                	addi	sp,sp,32
    80004760:	8082                	ret

0000000080004762 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004762:	1141                	addi	sp,sp,-16
    80004764:	e406                	sd	ra,8(sp)
    80004766:	e022                	sd	s0,0(sp)
    80004768:	0800                	addi	s0,sp,16
    8000476a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000476c:	4585                	li	a1,1
    8000476e:	00000097          	auipc	ra,0x0
    80004772:	dc4080e7          	jalr	-572(ra) # 80004532 <namex>
}
    80004776:	60a2                	ld	ra,8(sp)
    80004778:	6402                	ld	s0,0(sp)
    8000477a:	0141                	addi	sp,sp,16
    8000477c:	8082                	ret

000000008000477e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000477e:	1101                	addi	sp,sp,-32
    80004780:	ec06                	sd	ra,24(sp)
    80004782:	e822                	sd	s0,16(sp)
    80004784:	e426                	sd	s1,8(sp)
    80004786:	e04a                	sd	s2,0(sp)
    80004788:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000478a:	00026917          	auipc	s2,0x26
    8000478e:	21e90913          	addi	s2,s2,542 # 8002a9a8 <log>
    80004792:	01892583          	lw	a1,24(s2)
    80004796:	02892503          	lw	a0,40(s2)
    8000479a:	fffff097          	auipc	ra,0xfffff
    8000479e:	fea080e7          	jalr	-22(ra) # 80003784 <bread>
    800047a2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800047a4:	02c92683          	lw	a3,44(s2)
    800047a8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800047aa:	02d05763          	blez	a3,800047d8 <write_head+0x5a>
    800047ae:	00026797          	auipc	a5,0x26
    800047b2:	22a78793          	addi	a5,a5,554 # 8002a9d8 <log+0x30>
    800047b6:	05c50713          	addi	a4,a0,92
    800047ba:	36fd                	addiw	a3,a3,-1
    800047bc:	1682                	slli	a3,a3,0x20
    800047be:	9281                	srli	a3,a3,0x20
    800047c0:	068a                	slli	a3,a3,0x2
    800047c2:	00026617          	auipc	a2,0x26
    800047c6:	21a60613          	addi	a2,a2,538 # 8002a9dc <log+0x34>
    800047ca:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800047cc:	4390                	lw	a2,0(a5)
    800047ce:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800047d0:	0791                	addi	a5,a5,4
    800047d2:	0711                	addi	a4,a4,4
    800047d4:	fed79ce3          	bne	a5,a3,800047cc <write_head+0x4e>
  }
  bwrite(buf);
    800047d8:	8526                	mv	a0,s1
    800047da:	fffff097          	auipc	ra,0xfffff
    800047de:	09c080e7          	jalr	156(ra) # 80003876 <bwrite>
  brelse(buf);
    800047e2:	8526                	mv	a0,s1
    800047e4:	fffff097          	auipc	ra,0xfffff
    800047e8:	0d0080e7          	jalr	208(ra) # 800038b4 <brelse>
}
    800047ec:	60e2                	ld	ra,24(sp)
    800047ee:	6442                	ld	s0,16(sp)
    800047f0:	64a2                	ld	s1,8(sp)
    800047f2:	6902                	ld	s2,0(sp)
    800047f4:	6105                	addi	sp,sp,32
    800047f6:	8082                	ret

00000000800047f8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800047f8:	00026797          	auipc	a5,0x26
    800047fc:	1dc7a783          	lw	a5,476(a5) # 8002a9d4 <log+0x2c>
    80004800:	0af05d63          	blez	a5,800048ba <install_trans+0xc2>
{
    80004804:	7139                	addi	sp,sp,-64
    80004806:	fc06                	sd	ra,56(sp)
    80004808:	f822                	sd	s0,48(sp)
    8000480a:	f426                	sd	s1,40(sp)
    8000480c:	f04a                	sd	s2,32(sp)
    8000480e:	ec4e                	sd	s3,24(sp)
    80004810:	e852                	sd	s4,16(sp)
    80004812:	e456                	sd	s5,8(sp)
    80004814:	e05a                	sd	s6,0(sp)
    80004816:	0080                	addi	s0,sp,64
    80004818:	8b2a                	mv	s6,a0
    8000481a:	00026a97          	auipc	s5,0x26
    8000481e:	1bea8a93          	addi	s5,s5,446 # 8002a9d8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004822:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004824:	00026997          	auipc	s3,0x26
    80004828:	18498993          	addi	s3,s3,388 # 8002a9a8 <log>
    8000482c:	a035                	j	80004858 <install_trans+0x60>
      bunpin(dbuf);
    8000482e:	8526                	mv	a0,s1
    80004830:	fffff097          	auipc	ra,0xfffff
    80004834:	15e080e7          	jalr	350(ra) # 8000398e <bunpin>
    brelse(lbuf);
    80004838:	854a                	mv	a0,s2
    8000483a:	fffff097          	auipc	ra,0xfffff
    8000483e:	07a080e7          	jalr	122(ra) # 800038b4 <brelse>
    brelse(dbuf);
    80004842:	8526                	mv	a0,s1
    80004844:	fffff097          	auipc	ra,0xfffff
    80004848:	070080e7          	jalr	112(ra) # 800038b4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000484c:	2a05                	addiw	s4,s4,1
    8000484e:	0a91                	addi	s5,s5,4
    80004850:	02c9a783          	lw	a5,44(s3)
    80004854:	04fa5963          	bge	s4,a5,800048a6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004858:	0189a583          	lw	a1,24(s3)
    8000485c:	014585bb          	addw	a1,a1,s4
    80004860:	2585                	addiw	a1,a1,1
    80004862:	0289a503          	lw	a0,40(s3)
    80004866:	fffff097          	auipc	ra,0xfffff
    8000486a:	f1e080e7          	jalr	-226(ra) # 80003784 <bread>
    8000486e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004870:	000aa583          	lw	a1,0(s5)
    80004874:	0289a503          	lw	a0,40(s3)
    80004878:	fffff097          	auipc	ra,0xfffff
    8000487c:	f0c080e7          	jalr	-244(ra) # 80003784 <bread>
    80004880:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004882:	40000613          	li	a2,1024
    80004886:	05890593          	addi	a1,s2,88
    8000488a:	05850513          	addi	a0,a0,88
    8000488e:	ffffc097          	auipc	ra,0xffffc
    80004892:	4b8080e7          	jalr	1208(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004896:	8526                	mv	a0,s1
    80004898:	fffff097          	auipc	ra,0xfffff
    8000489c:	fde080e7          	jalr	-34(ra) # 80003876 <bwrite>
    if(recovering == 0)
    800048a0:	f80b1ce3          	bnez	s6,80004838 <install_trans+0x40>
    800048a4:	b769                	j	8000482e <install_trans+0x36>
}
    800048a6:	70e2                	ld	ra,56(sp)
    800048a8:	7442                	ld	s0,48(sp)
    800048aa:	74a2                	ld	s1,40(sp)
    800048ac:	7902                	ld	s2,32(sp)
    800048ae:	69e2                	ld	s3,24(sp)
    800048b0:	6a42                	ld	s4,16(sp)
    800048b2:	6aa2                	ld	s5,8(sp)
    800048b4:	6b02                	ld	s6,0(sp)
    800048b6:	6121                	addi	sp,sp,64
    800048b8:	8082                	ret
    800048ba:	8082                	ret

00000000800048bc <initlog>:
{
    800048bc:	7179                	addi	sp,sp,-48
    800048be:	f406                	sd	ra,40(sp)
    800048c0:	f022                	sd	s0,32(sp)
    800048c2:	ec26                	sd	s1,24(sp)
    800048c4:	e84a                	sd	s2,16(sp)
    800048c6:	e44e                	sd	s3,8(sp)
    800048c8:	1800                	addi	s0,sp,48
    800048ca:	892a                	mv	s2,a0
    800048cc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800048ce:	00026497          	auipc	s1,0x26
    800048d2:	0da48493          	addi	s1,s1,218 # 8002a9a8 <log>
    800048d6:	00004597          	auipc	a1,0x4
    800048da:	e0258593          	addi	a1,a1,-510 # 800086d8 <syscalls+0x208>
    800048de:	8526                	mv	a0,s1
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	27a080e7          	jalr	634(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    800048e8:	0149a583          	lw	a1,20(s3)
    800048ec:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800048ee:	0109a783          	lw	a5,16(s3)
    800048f2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800048f4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800048f8:	854a                	mv	a0,s2
    800048fa:	fffff097          	auipc	ra,0xfffff
    800048fe:	e8a080e7          	jalr	-374(ra) # 80003784 <bread>
  log.lh.n = lh->n;
    80004902:	4d3c                	lw	a5,88(a0)
    80004904:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004906:	02f05563          	blez	a5,80004930 <initlog+0x74>
    8000490a:	05c50713          	addi	a4,a0,92
    8000490e:	00026697          	auipc	a3,0x26
    80004912:	0ca68693          	addi	a3,a3,202 # 8002a9d8 <log+0x30>
    80004916:	37fd                	addiw	a5,a5,-1
    80004918:	1782                	slli	a5,a5,0x20
    8000491a:	9381                	srli	a5,a5,0x20
    8000491c:	078a                	slli	a5,a5,0x2
    8000491e:	06050613          	addi	a2,a0,96
    80004922:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004924:	4310                	lw	a2,0(a4)
    80004926:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004928:	0711                	addi	a4,a4,4
    8000492a:	0691                	addi	a3,a3,4
    8000492c:	fef71ce3          	bne	a4,a5,80004924 <initlog+0x68>
  brelse(buf);
    80004930:	fffff097          	auipc	ra,0xfffff
    80004934:	f84080e7          	jalr	-124(ra) # 800038b4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004938:	4505                	li	a0,1
    8000493a:	00000097          	auipc	ra,0x0
    8000493e:	ebe080e7          	jalr	-322(ra) # 800047f8 <install_trans>
  log.lh.n = 0;
    80004942:	00026797          	auipc	a5,0x26
    80004946:	0807a923          	sw	zero,146(a5) # 8002a9d4 <log+0x2c>
  write_head(); // clear the log
    8000494a:	00000097          	auipc	ra,0x0
    8000494e:	e34080e7          	jalr	-460(ra) # 8000477e <write_head>
}
    80004952:	70a2                	ld	ra,40(sp)
    80004954:	7402                	ld	s0,32(sp)
    80004956:	64e2                	ld	s1,24(sp)
    80004958:	6942                	ld	s2,16(sp)
    8000495a:	69a2                	ld	s3,8(sp)
    8000495c:	6145                	addi	sp,sp,48
    8000495e:	8082                	ret

0000000080004960 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004960:	1101                	addi	sp,sp,-32
    80004962:	ec06                	sd	ra,24(sp)
    80004964:	e822                	sd	s0,16(sp)
    80004966:	e426                	sd	s1,8(sp)
    80004968:	e04a                	sd	s2,0(sp)
    8000496a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000496c:	00026517          	auipc	a0,0x26
    80004970:	03c50513          	addi	a0,a0,60 # 8002a9a8 <log>
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	276080e7          	jalr	630(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    8000497c:	00026497          	auipc	s1,0x26
    80004980:	02c48493          	addi	s1,s1,44 # 8002a9a8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004984:	4979                	li	s2,30
    80004986:	a039                	j	80004994 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004988:	85a6                	mv	a1,s1
    8000498a:	8526                	mv	a0,s1
    8000498c:	ffffe097          	auipc	ra,0xffffe
    80004990:	b00080e7          	jalr	-1280(ra) # 8000248c <sleep>
    if(log.committing){
    80004994:	50dc                	lw	a5,36(s1)
    80004996:	fbed                	bnez	a5,80004988 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004998:	509c                	lw	a5,32(s1)
    8000499a:	0017871b          	addiw	a4,a5,1
    8000499e:	0007069b          	sext.w	a3,a4
    800049a2:	0027179b          	slliw	a5,a4,0x2
    800049a6:	9fb9                	addw	a5,a5,a4
    800049a8:	0017979b          	slliw	a5,a5,0x1
    800049ac:	54d8                	lw	a4,44(s1)
    800049ae:	9fb9                	addw	a5,a5,a4
    800049b0:	00f95963          	bge	s2,a5,800049c2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800049b4:	85a6                	mv	a1,s1
    800049b6:	8526                	mv	a0,s1
    800049b8:	ffffe097          	auipc	ra,0xffffe
    800049bc:	ad4080e7          	jalr	-1324(ra) # 8000248c <sleep>
    800049c0:	bfd1                	j	80004994 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800049c2:	00026517          	auipc	a0,0x26
    800049c6:	fe650513          	addi	a0,a0,-26 # 8002a9a8 <log>
    800049ca:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	2d2080e7          	jalr	722(ra) # 80000c9e <release>
      break;
    }
  }
}
    800049d4:	60e2                	ld	ra,24(sp)
    800049d6:	6442                	ld	s0,16(sp)
    800049d8:	64a2                	ld	s1,8(sp)
    800049da:	6902                	ld	s2,0(sp)
    800049dc:	6105                	addi	sp,sp,32
    800049de:	8082                	ret

00000000800049e0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800049e0:	7139                	addi	sp,sp,-64
    800049e2:	fc06                	sd	ra,56(sp)
    800049e4:	f822                	sd	s0,48(sp)
    800049e6:	f426                	sd	s1,40(sp)
    800049e8:	f04a                	sd	s2,32(sp)
    800049ea:	ec4e                	sd	s3,24(sp)
    800049ec:	e852                	sd	s4,16(sp)
    800049ee:	e456                	sd	s5,8(sp)
    800049f0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800049f2:	00026497          	auipc	s1,0x26
    800049f6:	fb648493          	addi	s1,s1,-74 # 8002a9a8 <log>
    800049fa:	8526                	mv	a0,s1
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	1ee080e7          	jalr	494(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004a04:	509c                	lw	a5,32(s1)
    80004a06:	37fd                	addiw	a5,a5,-1
    80004a08:	0007891b          	sext.w	s2,a5
    80004a0c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004a0e:	50dc                	lw	a5,36(s1)
    80004a10:	efb9                	bnez	a5,80004a6e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004a12:	06091663          	bnez	s2,80004a7e <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004a16:	00026497          	auipc	s1,0x26
    80004a1a:	f9248493          	addi	s1,s1,-110 # 8002a9a8 <log>
    80004a1e:	4785                	li	a5,1
    80004a20:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004a22:	8526                	mv	a0,s1
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	27a080e7          	jalr	634(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004a2c:	54dc                	lw	a5,44(s1)
    80004a2e:	06f04763          	bgtz	a5,80004a9c <end_op+0xbc>
    acquire(&log.lock);
    80004a32:	00026497          	auipc	s1,0x26
    80004a36:	f7648493          	addi	s1,s1,-138 # 8002a9a8 <log>
    80004a3a:	8526                	mv	a0,s1
    80004a3c:	ffffc097          	auipc	ra,0xffffc
    80004a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
    log.committing = 0;
    80004a44:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004a48:	8526                	mv	a0,s1
    80004a4a:	ffffe097          	auipc	ra,0xffffe
    80004a4e:	bf6080e7          	jalr	-1034(ra) # 80002640 <wakeup>
    release(&log.lock);
    80004a52:	8526                	mv	a0,s1
    80004a54:	ffffc097          	auipc	ra,0xffffc
    80004a58:	24a080e7          	jalr	586(ra) # 80000c9e <release>
}
    80004a5c:	70e2                	ld	ra,56(sp)
    80004a5e:	7442                	ld	s0,48(sp)
    80004a60:	74a2                	ld	s1,40(sp)
    80004a62:	7902                	ld	s2,32(sp)
    80004a64:	69e2                	ld	s3,24(sp)
    80004a66:	6a42                	ld	s4,16(sp)
    80004a68:	6aa2                	ld	s5,8(sp)
    80004a6a:	6121                	addi	sp,sp,64
    80004a6c:	8082                	ret
    panic("log.committing");
    80004a6e:	00004517          	auipc	a0,0x4
    80004a72:	c7250513          	addi	a0,a0,-910 # 800086e0 <syscalls+0x210>
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	ace080e7          	jalr	-1330(ra) # 80000544 <panic>
    wakeup(&log);
    80004a7e:	00026497          	auipc	s1,0x26
    80004a82:	f2a48493          	addi	s1,s1,-214 # 8002a9a8 <log>
    80004a86:	8526                	mv	a0,s1
    80004a88:	ffffe097          	auipc	ra,0xffffe
    80004a8c:	bb8080e7          	jalr	-1096(ra) # 80002640 <wakeup>
  release(&log.lock);
    80004a90:	8526                	mv	a0,s1
    80004a92:	ffffc097          	auipc	ra,0xffffc
    80004a96:	20c080e7          	jalr	524(ra) # 80000c9e <release>
  if(do_commit){
    80004a9a:	b7c9                	j	80004a5c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a9c:	00026a97          	auipc	s5,0x26
    80004aa0:	f3ca8a93          	addi	s5,s5,-196 # 8002a9d8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004aa4:	00026a17          	auipc	s4,0x26
    80004aa8:	f04a0a13          	addi	s4,s4,-252 # 8002a9a8 <log>
    80004aac:	018a2583          	lw	a1,24(s4)
    80004ab0:	012585bb          	addw	a1,a1,s2
    80004ab4:	2585                	addiw	a1,a1,1
    80004ab6:	028a2503          	lw	a0,40(s4)
    80004aba:	fffff097          	auipc	ra,0xfffff
    80004abe:	cca080e7          	jalr	-822(ra) # 80003784 <bread>
    80004ac2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004ac4:	000aa583          	lw	a1,0(s5)
    80004ac8:	028a2503          	lw	a0,40(s4)
    80004acc:	fffff097          	auipc	ra,0xfffff
    80004ad0:	cb8080e7          	jalr	-840(ra) # 80003784 <bread>
    80004ad4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004ad6:	40000613          	li	a2,1024
    80004ada:	05850593          	addi	a1,a0,88
    80004ade:	05848513          	addi	a0,s1,88
    80004ae2:	ffffc097          	auipc	ra,0xffffc
    80004ae6:	264080e7          	jalr	612(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004aea:	8526                	mv	a0,s1
    80004aec:	fffff097          	auipc	ra,0xfffff
    80004af0:	d8a080e7          	jalr	-630(ra) # 80003876 <bwrite>
    brelse(from);
    80004af4:	854e                	mv	a0,s3
    80004af6:	fffff097          	auipc	ra,0xfffff
    80004afa:	dbe080e7          	jalr	-578(ra) # 800038b4 <brelse>
    brelse(to);
    80004afe:	8526                	mv	a0,s1
    80004b00:	fffff097          	auipc	ra,0xfffff
    80004b04:	db4080e7          	jalr	-588(ra) # 800038b4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b08:	2905                	addiw	s2,s2,1
    80004b0a:	0a91                	addi	s5,s5,4
    80004b0c:	02ca2783          	lw	a5,44(s4)
    80004b10:	f8f94ee3          	blt	s2,a5,80004aac <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004b14:	00000097          	auipc	ra,0x0
    80004b18:	c6a080e7          	jalr	-918(ra) # 8000477e <write_head>
    install_trans(0); // Now install writes to home locations
    80004b1c:	4501                	li	a0,0
    80004b1e:	00000097          	auipc	ra,0x0
    80004b22:	cda080e7          	jalr	-806(ra) # 800047f8 <install_trans>
    log.lh.n = 0;
    80004b26:	00026797          	auipc	a5,0x26
    80004b2a:	ea07a723          	sw	zero,-338(a5) # 8002a9d4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004b2e:	00000097          	auipc	ra,0x0
    80004b32:	c50080e7          	jalr	-944(ra) # 8000477e <write_head>
    80004b36:	bdf5                	j	80004a32 <end_op+0x52>

0000000080004b38 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004b38:	1101                	addi	sp,sp,-32
    80004b3a:	ec06                	sd	ra,24(sp)
    80004b3c:	e822                	sd	s0,16(sp)
    80004b3e:	e426                	sd	s1,8(sp)
    80004b40:	e04a                	sd	s2,0(sp)
    80004b42:	1000                	addi	s0,sp,32
    80004b44:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004b46:	00026917          	auipc	s2,0x26
    80004b4a:	e6290913          	addi	s2,s2,-414 # 8002a9a8 <log>
    80004b4e:	854a                	mv	a0,s2
    80004b50:	ffffc097          	auipc	ra,0xffffc
    80004b54:	09a080e7          	jalr	154(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004b58:	02c92603          	lw	a2,44(s2)
    80004b5c:	47f5                	li	a5,29
    80004b5e:	06c7c563          	blt	a5,a2,80004bc8 <log_write+0x90>
    80004b62:	00026797          	auipc	a5,0x26
    80004b66:	e627a783          	lw	a5,-414(a5) # 8002a9c4 <log+0x1c>
    80004b6a:	37fd                	addiw	a5,a5,-1
    80004b6c:	04f65e63          	bge	a2,a5,80004bc8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004b70:	00026797          	auipc	a5,0x26
    80004b74:	e587a783          	lw	a5,-424(a5) # 8002a9c8 <log+0x20>
    80004b78:	06f05063          	blez	a5,80004bd8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004b7c:	4781                	li	a5,0
    80004b7e:	06c05563          	blez	a2,80004be8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004b82:	44cc                	lw	a1,12(s1)
    80004b84:	00026717          	auipc	a4,0x26
    80004b88:	e5470713          	addi	a4,a4,-428 # 8002a9d8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004b8c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004b8e:	4314                	lw	a3,0(a4)
    80004b90:	04b68c63          	beq	a3,a1,80004be8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004b94:	2785                	addiw	a5,a5,1
    80004b96:	0711                	addi	a4,a4,4
    80004b98:	fef61be3          	bne	a2,a5,80004b8e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004b9c:	0621                	addi	a2,a2,8
    80004b9e:	060a                	slli	a2,a2,0x2
    80004ba0:	00026797          	auipc	a5,0x26
    80004ba4:	e0878793          	addi	a5,a5,-504 # 8002a9a8 <log>
    80004ba8:	963e                	add	a2,a2,a5
    80004baa:	44dc                	lw	a5,12(s1)
    80004bac:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004bae:	8526                	mv	a0,s1
    80004bb0:	fffff097          	auipc	ra,0xfffff
    80004bb4:	da2080e7          	jalr	-606(ra) # 80003952 <bpin>
    log.lh.n++;
    80004bb8:	00026717          	auipc	a4,0x26
    80004bbc:	df070713          	addi	a4,a4,-528 # 8002a9a8 <log>
    80004bc0:	575c                	lw	a5,44(a4)
    80004bc2:	2785                	addiw	a5,a5,1
    80004bc4:	d75c                	sw	a5,44(a4)
    80004bc6:	a835                	j	80004c02 <log_write+0xca>
    panic("too big a transaction");
    80004bc8:	00004517          	auipc	a0,0x4
    80004bcc:	b2850513          	addi	a0,a0,-1240 # 800086f0 <syscalls+0x220>
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	974080e7          	jalr	-1676(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004bd8:	00004517          	auipc	a0,0x4
    80004bdc:	b3050513          	addi	a0,a0,-1232 # 80008708 <syscalls+0x238>
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	964080e7          	jalr	-1692(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004be8:	00878713          	addi	a4,a5,8
    80004bec:	00271693          	slli	a3,a4,0x2
    80004bf0:	00026717          	auipc	a4,0x26
    80004bf4:	db870713          	addi	a4,a4,-584 # 8002a9a8 <log>
    80004bf8:	9736                	add	a4,a4,a3
    80004bfa:	44d4                	lw	a3,12(s1)
    80004bfc:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004bfe:	faf608e3          	beq	a2,a5,80004bae <log_write+0x76>
  }
  release(&log.lock);
    80004c02:	00026517          	auipc	a0,0x26
    80004c06:	da650513          	addi	a0,a0,-602 # 8002a9a8 <log>
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	094080e7          	jalr	148(ra) # 80000c9e <release>
}
    80004c12:	60e2                	ld	ra,24(sp)
    80004c14:	6442                	ld	s0,16(sp)
    80004c16:	64a2                	ld	s1,8(sp)
    80004c18:	6902                	ld	s2,0(sp)
    80004c1a:	6105                	addi	sp,sp,32
    80004c1c:	8082                	ret

0000000080004c1e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004c1e:	1101                	addi	sp,sp,-32
    80004c20:	ec06                	sd	ra,24(sp)
    80004c22:	e822                	sd	s0,16(sp)
    80004c24:	e426                	sd	s1,8(sp)
    80004c26:	e04a                	sd	s2,0(sp)
    80004c28:	1000                	addi	s0,sp,32
    80004c2a:	84aa                	mv	s1,a0
    80004c2c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004c2e:	00004597          	auipc	a1,0x4
    80004c32:	afa58593          	addi	a1,a1,-1286 # 80008728 <syscalls+0x258>
    80004c36:	0521                	addi	a0,a0,8
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	f22080e7          	jalr	-222(ra) # 80000b5a <initlock>
  lk->name = name;
    80004c40:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004c44:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c48:	0204a423          	sw	zero,40(s1)
}
    80004c4c:	60e2                	ld	ra,24(sp)
    80004c4e:	6442                	ld	s0,16(sp)
    80004c50:	64a2                	ld	s1,8(sp)
    80004c52:	6902                	ld	s2,0(sp)
    80004c54:	6105                	addi	sp,sp,32
    80004c56:	8082                	ret

0000000080004c58 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004c58:	1101                	addi	sp,sp,-32
    80004c5a:	ec06                	sd	ra,24(sp)
    80004c5c:	e822                	sd	s0,16(sp)
    80004c5e:	e426                	sd	s1,8(sp)
    80004c60:	e04a                	sd	s2,0(sp)
    80004c62:	1000                	addi	s0,sp,32
    80004c64:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c66:	00850913          	addi	s2,a0,8
    80004c6a:	854a                	mv	a0,s2
    80004c6c:	ffffc097          	auipc	ra,0xffffc
    80004c70:	f7e080e7          	jalr	-130(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004c74:	409c                	lw	a5,0(s1)
    80004c76:	cb89                	beqz	a5,80004c88 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004c78:	85ca                	mv	a1,s2
    80004c7a:	8526                	mv	a0,s1
    80004c7c:	ffffe097          	auipc	ra,0xffffe
    80004c80:	810080e7          	jalr	-2032(ra) # 8000248c <sleep>
  while (lk->locked) {
    80004c84:	409c                	lw	a5,0(s1)
    80004c86:	fbed                	bnez	a5,80004c78 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004c88:	4785                	li	a5,1
    80004c8a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004c8c:	ffffd097          	auipc	ra,0xffffd
    80004c90:	ea0080e7          	jalr	-352(ra) # 80001b2c <myproc>
    80004c94:	591c                	lw	a5,48(a0)
    80004c96:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004c98:	854a                	mv	a0,s2
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	004080e7          	jalr	4(ra) # 80000c9e <release>
}
    80004ca2:	60e2                	ld	ra,24(sp)
    80004ca4:	6442                	ld	s0,16(sp)
    80004ca6:	64a2                	ld	s1,8(sp)
    80004ca8:	6902                	ld	s2,0(sp)
    80004caa:	6105                	addi	sp,sp,32
    80004cac:	8082                	ret

0000000080004cae <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004cae:	1101                	addi	sp,sp,-32
    80004cb0:	ec06                	sd	ra,24(sp)
    80004cb2:	e822                	sd	s0,16(sp)
    80004cb4:	e426                	sd	s1,8(sp)
    80004cb6:	e04a                	sd	s2,0(sp)
    80004cb8:	1000                	addi	s0,sp,32
    80004cba:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004cbc:	00850913          	addi	s2,a0,8
    80004cc0:	854a                	mv	a0,s2
    80004cc2:	ffffc097          	auipc	ra,0xffffc
    80004cc6:	f28080e7          	jalr	-216(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004cca:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004cce:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004cd2:	8526                	mv	a0,s1
    80004cd4:	ffffe097          	auipc	ra,0xffffe
    80004cd8:	96c080e7          	jalr	-1684(ra) # 80002640 <wakeup>
  release(&lk->lk);
    80004cdc:	854a                	mv	a0,s2
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	fc0080e7          	jalr	-64(ra) # 80000c9e <release>
}
    80004ce6:	60e2                	ld	ra,24(sp)
    80004ce8:	6442                	ld	s0,16(sp)
    80004cea:	64a2                	ld	s1,8(sp)
    80004cec:	6902                	ld	s2,0(sp)
    80004cee:	6105                	addi	sp,sp,32
    80004cf0:	8082                	ret

0000000080004cf2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004cf2:	7179                	addi	sp,sp,-48
    80004cf4:	f406                	sd	ra,40(sp)
    80004cf6:	f022                	sd	s0,32(sp)
    80004cf8:	ec26                	sd	s1,24(sp)
    80004cfa:	e84a                	sd	s2,16(sp)
    80004cfc:	e44e                	sd	s3,8(sp)
    80004cfe:	1800                	addi	s0,sp,48
    80004d00:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004d02:	00850913          	addi	s2,a0,8
    80004d06:	854a                	mv	a0,s2
    80004d08:	ffffc097          	auipc	ra,0xffffc
    80004d0c:	ee2080e7          	jalr	-286(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d10:	409c                	lw	a5,0(s1)
    80004d12:	ef99                	bnez	a5,80004d30 <holdingsleep+0x3e>
    80004d14:	4481                	li	s1,0
  release(&lk->lk);
    80004d16:	854a                	mv	a0,s2
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	f86080e7          	jalr	-122(ra) # 80000c9e <release>
  return r;
}
    80004d20:	8526                	mv	a0,s1
    80004d22:	70a2                	ld	ra,40(sp)
    80004d24:	7402                	ld	s0,32(sp)
    80004d26:	64e2                	ld	s1,24(sp)
    80004d28:	6942                	ld	s2,16(sp)
    80004d2a:	69a2                	ld	s3,8(sp)
    80004d2c:	6145                	addi	sp,sp,48
    80004d2e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d30:	0284a983          	lw	s3,40(s1)
    80004d34:	ffffd097          	auipc	ra,0xffffd
    80004d38:	df8080e7          	jalr	-520(ra) # 80001b2c <myproc>
    80004d3c:	5904                	lw	s1,48(a0)
    80004d3e:	413484b3          	sub	s1,s1,s3
    80004d42:	0014b493          	seqz	s1,s1
    80004d46:	bfc1                	j	80004d16 <holdingsleep+0x24>

0000000080004d48 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004d48:	1141                	addi	sp,sp,-16
    80004d4a:	e406                	sd	ra,8(sp)
    80004d4c:	e022                	sd	s0,0(sp)
    80004d4e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004d50:	00004597          	auipc	a1,0x4
    80004d54:	9e858593          	addi	a1,a1,-1560 # 80008738 <syscalls+0x268>
    80004d58:	00026517          	auipc	a0,0x26
    80004d5c:	d9850513          	addi	a0,a0,-616 # 8002aaf0 <ftable>
    80004d60:	ffffc097          	auipc	ra,0xffffc
    80004d64:	dfa080e7          	jalr	-518(ra) # 80000b5a <initlock>
}
    80004d68:	60a2                	ld	ra,8(sp)
    80004d6a:	6402                	ld	s0,0(sp)
    80004d6c:	0141                	addi	sp,sp,16
    80004d6e:	8082                	ret

0000000080004d70 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004d70:	1101                	addi	sp,sp,-32
    80004d72:	ec06                	sd	ra,24(sp)
    80004d74:	e822                	sd	s0,16(sp)
    80004d76:	e426                	sd	s1,8(sp)
    80004d78:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004d7a:	00026517          	auipc	a0,0x26
    80004d7e:	d7650513          	addi	a0,a0,-650 # 8002aaf0 <ftable>
    80004d82:	ffffc097          	auipc	ra,0xffffc
    80004d86:	e68080e7          	jalr	-408(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d8a:	00026497          	auipc	s1,0x26
    80004d8e:	d7e48493          	addi	s1,s1,-642 # 8002ab08 <ftable+0x18>
    80004d92:	00027717          	auipc	a4,0x27
    80004d96:	d1670713          	addi	a4,a4,-746 # 8002baa8 <disk>
    if(f->ref == 0){
    80004d9a:	40dc                	lw	a5,4(s1)
    80004d9c:	cf99                	beqz	a5,80004dba <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d9e:	02848493          	addi	s1,s1,40
    80004da2:	fee49ce3          	bne	s1,a4,80004d9a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004da6:	00026517          	auipc	a0,0x26
    80004daa:	d4a50513          	addi	a0,a0,-694 # 8002aaf0 <ftable>
    80004dae:	ffffc097          	auipc	ra,0xffffc
    80004db2:	ef0080e7          	jalr	-272(ra) # 80000c9e <release>
  return 0;
    80004db6:	4481                	li	s1,0
    80004db8:	a819                	j	80004dce <filealloc+0x5e>
      f->ref = 1;
    80004dba:	4785                	li	a5,1
    80004dbc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004dbe:	00026517          	auipc	a0,0x26
    80004dc2:	d3250513          	addi	a0,a0,-718 # 8002aaf0 <ftable>
    80004dc6:	ffffc097          	auipc	ra,0xffffc
    80004dca:	ed8080e7          	jalr	-296(ra) # 80000c9e <release>
}
    80004dce:	8526                	mv	a0,s1
    80004dd0:	60e2                	ld	ra,24(sp)
    80004dd2:	6442                	ld	s0,16(sp)
    80004dd4:	64a2                	ld	s1,8(sp)
    80004dd6:	6105                	addi	sp,sp,32
    80004dd8:	8082                	ret

0000000080004dda <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004dda:	1101                	addi	sp,sp,-32
    80004ddc:	ec06                	sd	ra,24(sp)
    80004dde:	e822                	sd	s0,16(sp)
    80004de0:	e426                	sd	s1,8(sp)
    80004de2:	1000                	addi	s0,sp,32
    80004de4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004de6:	00026517          	auipc	a0,0x26
    80004dea:	d0a50513          	addi	a0,a0,-758 # 8002aaf0 <ftable>
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	dfc080e7          	jalr	-516(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004df6:	40dc                	lw	a5,4(s1)
    80004df8:	02f05263          	blez	a5,80004e1c <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004dfc:	2785                	addiw	a5,a5,1
    80004dfe:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004e00:	00026517          	auipc	a0,0x26
    80004e04:	cf050513          	addi	a0,a0,-784 # 8002aaf0 <ftable>
    80004e08:	ffffc097          	auipc	ra,0xffffc
    80004e0c:	e96080e7          	jalr	-362(ra) # 80000c9e <release>
  return f;
}
    80004e10:	8526                	mv	a0,s1
    80004e12:	60e2                	ld	ra,24(sp)
    80004e14:	6442                	ld	s0,16(sp)
    80004e16:	64a2                	ld	s1,8(sp)
    80004e18:	6105                	addi	sp,sp,32
    80004e1a:	8082                	ret
    panic("filedup");
    80004e1c:	00004517          	auipc	a0,0x4
    80004e20:	92450513          	addi	a0,a0,-1756 # 80008740 <syscalls+0x270>
    80004e24:	ffffb097          	auipc	ra,0xffffb
    80004e28:	720080e7          	jalr	1824(ra) # 80000544 <panic>

0000000080004e2c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004e2c:	7139                	addi	sp,sp,-64
    80004e2e:	fc06                	sd	ra,56(sp)
    80004e30:	f822                	sd	s0,48(sp)
    80004e32:	f426                	sd	s1,40(sp)
    80004e34:	f04a                	sd	s2,32(sp)
    80004e36:	ec4e                	sd	s3,24(sp)
    80004e38:	e852                	sd	s4,16(sp)
    80004e3a:	e456                	sd	s5,8(sp)
    80004e3c:	0080                	addi	s0,sp,64
    80004e3e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004e40:	00026517          	auipc	a0,0x26
    80004e44:	cb050513          	addi	a0,a0,-848 # 8002aaf0 <ftable>
    80004e48:	ffffc097          	auipc	ra,0xffffc
    80004e4c:	da2080e7          	jalr	-606(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004e50:	40dc                	lw	a5,4(s1)
    80004e52:	06f05163          	blez	a5,80004eb4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004e56:	37fd                	addiw	a5,a5,-1
    80004e58:	0007871b          	sext.w	a4,a5
    80004e5c:	c0dc                	sw	a5,4(s1)
    80004e5e:	06e04363          	bgtz	a4,80004ec4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004e62:	0004a903          	lw	s2,0(s1)
    80004e66:	0094ca83          	lbu	s5,9(s1)
    80004e6a:	0104ba03          	ld	s4,16(s1)
    80004e6e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004e72:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004e76:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004e7a:	00026517          	auipc	a0,0x26
    80004e7e:	c7650513          	addi	a0,a0,-906 # 8002aaf0 <ftable>
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	e1c080e7          	jalr	-484(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004e8a:	4785                	li	a5,1
    80004e8c:	04f90d63          	beq	s2,a5,80004ee6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004e90:	3979                	addiw	s2,s2,-2
    80004e92:	4785                	li	a5,1
    80004e94:	0527e063          	bltu	a5,s2,80004ed4 <fileclose+0xa8>
    begin_op();
    80004e98:	00000097          	auipc	ra,0x0
    80004e9c:	ac8080e7          	jalr	-1336(ra) # 80004960 <begin_op>
    iput(ff.ip);
    80004ea0:	854e                	mv	a0,s3
    80004ea2:	fffff097          	auipc	ra,0xfffff
    80004ea6:	2b6080e7          	jalr	694(ra) # 80004158 <iput>
    end_op();
    80004eaa:	00000097          	auipc	ra,0x0
    80004eae:	b36080e7          	jalr	-1226(ra) # 800049e0 <end_op>
    80004eb2:	a00d                	j	80004ed4 <fileclose+0xa8>
    panic("fileclose");
    80004eb4:	00004517          	auipc	a0,0x4
    80004eb8:	89450513          	addi	a0,a0,-1900 # 80008748 <syscalls+0x278>
    80004ebc:	ffffb097          	auipc	ra,0xffffb
    80004ec0:	688080e7          	jalr	1672(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004ec4:	00026517          	auipc	a0,0x26
    80004ec8:	c2c50513          	addi	a0,a0,-980 # 8002aaf0 <ftable>
    80004ecc:	ffffc097          	auipc	ra,0xffffc
    80004ed0:	dd2080e7          	jalr	-558(ra) # 80000c9e <release>
  }
}
    80004ed4:	70e2                	ld	ra,56(sp)
    80004ed6:	7442                	ld	s0,48(sp)
    80004ed8:	74a2                	ld	s1,40(sp)
    80004eda:	7902                	ld	s2,32(sp)
    80004edc:	69e2                	ld	s3,24(sp)
    80004ede:	6a42                	ld	s4,16(sp)
    80004ee0:	6aa2                	ld	s5,8(sp)
    80004ee2:	6121                	addi	sp,sp,64
    80004ee4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ee6:	85d6                	mv	a1,s5
    80004ee8:	8552                	mv	a0,s4
    80004eea:	00000097          	auipc	ra,0x0
    80004eee:	34c080e7          	jalr	844(ra) # 80005236 <pipeclose>
    80004ef2:	b7cd                	j	80004ed4 <fileclose+0xa8>

0000000080004ef4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ef4:	715d                	addi	sp,sp,-80
    80004ef6:	e486                	sd	ra,72(sp)
    80004ef8:	e0a2                	sd	s0,64(sp)
    80004efa:	fc26                	sd	s1,56(sp)
    80004efc:	f84a                	sd	s2,48(sp)
    80004efe:	f44e                	sd	s3,40(sp)
    80004f00:	0880                	addi	s0,sp,80
    80004f02:	84aa                	mv	s1,a0
    80004f04:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004f06:	ffffd097          	auipc	ra,0xffffd
    80004f0a:	c26080e7          	jalr	-986(ra) # 80001b2c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004f0e:	409c                	lw	a5,0(s1)
    80004f10:	37f9                	addiw	a5,a5,-2
    80004f12:	4705                	li	a4,1
    80004f14:	04f76763          	bltu	a4,a5,80004f62 <filestat+0x6e>
    80004f18:	892a                	mv	s2,a0
    ilock(f->ip);
    80004f1a:	6c88                	ld	a0,24(s1)
    80004f1c:	fffff097          	auipc	ra,0xfffff
    80004f20:	082080e7          	jalr	130(ra) # 80003f9e <ilock>
    stati(f->ip, &st);
    80004f24:	fb840593          	addi	a1,s0,-72
    80004f28:	6c88                	ld	a0,24(s1)
    80004f2a:	fffff097          	auipc	ra,0xfffff
    80004f2e:	2fe080e7          	jalr	766(ra) # 80004228 <stati>
    iunlock(f->ip);
    80004f32:	6c88                	ld	a0,24(s1)
    80004f34:	fffff097          	auipc	ra,0xfffff
    80004f38:	12c080e7          	jalr	300(ra) # 80004060 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004f3c:	46e1                	li	a3,24
    80004f3e:	fb840613          	addi	a2,s0,-72
    80004f42:	85ce                	mv	a1,s3
    80004f44:	05093503          	ld	a0,80(s2)
    80004f48:	ffffc097          	auipc	ra,0xffffc
    80004f4c:	73c080e7          	jalr	1852(ra) # 80001684 <copyout>
    80004f50:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004f54:	60a6                	ld	ra,72(sp)
    80004f56:	6406                	ld	s0,64(sp)
    80004f58:	74e2                	ld	s1,56(sp)
    80004f5a:	7942                	ld	s2,48(sp)
    80004f5c:	79a2                	ld	s3,40(sp)
    80004f5e:	6161                	addi	sp,sp,80
    80004f60:	8082                	ret
  return -1;
    80004f62:	557d                	li	a0,-1
    80004f64:	bfc5                	j	80004f54 <filestat+0x60>

0000000080004f66 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004f66:	7179                	addi	sp,sp,-48
    80004f68:	f406                	sd	ra,40(sp)
    80004f6a:	f022                	sd	s0,32(sp)
    80004f6c:	ec26                	sd	s1,24(sp)
    80004f6e:	e84a                	sd	s2,16(sp)
    80004f70:	e44e                	sd	s3,8(sp)
    80004f72:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004f74:	00854783          	lbu	a5,8(a0)
    80004f78:	c3d5                	beqz	a5,8000501c <fileread+0xb6>
    80004f7a:	84aa                	mv	s1,a0
    80004f7c:	89ae                	mv	s3,a1
    80004f7e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f80:	411c                	lw	a5,0(a0)
    80004f82:	4705                	li	a4,1
    80004f84:	04e78963          	beq	a5,a4,80004fd6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f88:	470d                	li	a4,3
    80004f8a:	04e78d63          	beq	a5,a4,80004fe4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f8e:	4709                	li	a4,2
    80004f90:	06e79e63          	bne	a5,a4,8000500c <fileread+0xa6>
    ilock(f->ip);
    80004f94:	6d08                	ld	a0,24(a0)
    80004f96:	fffff097          	auipc	ra,0xfffff
    80004f9a:	008080e7          	jalr	8(ra) # 80003f9e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004f9e:	874a                	mv	a4,s2
    80004fa0:	5094                	lw	a3,32(s1)
    80004fa2:	864e                	mv	a2,s3
    80004fa4:	4585                	li	a1,1
    80004fa6:	6c88                	ld	a0,24(s1)
    80004fa8:	fffff097          	auipc	ra,0xfffff
    80004fac:	2aa080e7          	jalr	682(ra) # 80004252 <readi>
    80004fb0:	892a                	mv	s2,a0
    80004fb2:	00a05563          	blez	a0,80004fbc <fileread+0x56>
      f->off += r;
    80004fb6:	509c                	lw	a5,32(s1)
    80004fb8:	9fa9                	addw	a5,a5,a0
    80004fba:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004fbc:	6c88                	ld	a0,24(s1)
    80004fbe:	fffff097          	auipc	ra,0xfffff
    80004fc2:	0a2080e7          	jalr	162(ra) # 80004060 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004fc6:	854a                	mv	a0,s2
    80004fc8:	70a2                	ld	ra,40(sp)
    80004fca:	7402                	ld	s0,32(sp)
    80004fcc:	64e2                	ld	s1,24(sp)
    80004fce:	6942                	ld	s2,16(sp)
    80004fd0:	69a2                	ld	s3,8(sp)
    80004fd2:	6145                	addi	sp,sp,48
    80004fd4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004fd6:	6908                	ld	a0,16(a0)
    80004fd8:	00000097          	auipc	ra,0x0
    80004fdc:	3ce080e7          	jalr	974(ra) # 800053a6 <piperead>
    80004fe0:	892a                	mv	s2,a0
    80004fe2:	b7d5                	j	80004fc6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004fe4:	02451783          	lh	a5,36(a0)
    80004fe8:	03079693          	slli	a3,a5,0x30
    80004fec:	92c1                	srli	a3,a3,0x30
    80004fee:	4725                	li	a4,9
    80004ff0:	02d76863          	bltu	a4,a3,80005020 <fileread+0xba>
    80004ff4:	0792                	slli	a5,a5,0x4
    80004ff6:	00026717          	auipc	a4,0x26
    80004ffa:	a5a70713          	addi	a4,a4,-1446 # 8002aa50 <devsw>
    80004ffe:	97ba                	add	a5,a5,a4
    80005000:	639c                	ld	a5,0(a5)
    80005002:	c38d                	beqz	a5,80005024 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005004:	4505                	li	a0,1
    80005006:	9782                	jalr	a5
    80005008:	892a                	mv	s2,a0
    8000500a:	bf75                	j	80004fc6 <fileread+0x60>
    panic("fileread");
    8000500c:	00003517          	auipc	a0,0x3
    80005010:	74c50513          	addi	a0,a0,1868 # 80008758 <syscalls+0x288>
    80005014:	ffffb097          	auipc	ra,0xffffb
    80005018:	530080e7          	jalr	1328(ra) # 80000544 <panic>
    return -1;
    8000501c:	597d                	li	s2,-1
    8000501e:	b765                	j	80004fc6 <fileread+0x60>
      return -1;
    80005020:	597d                	li	s2,-1
    80005022:	b755                	j	80004fc6 <fileread+0x60>
    80005024:	597d                	li	s2,-1
    80005026:	b745                	j	80004fc6 <fileread+0x60>

0000000080005028 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005028:	715d                	addi	sp,sp,-80
    8000502a:	e486                	sd	ra,72(sp)
    8000502c:	e0a2                	sd	s0,64(sp)
    8000502e:	fc26                	sd	s1,56(sp)
    80005030:	f84a                	sd	s2,48(sp)
    80005032:	f44e                	sd	s3,40(sp)
    80005034:	f052                	sd	s4,32(sp)
    80005036:	ec56                	sd	s5,24(sp)
    80005038:	e85a                	sd	s6,16(sp)
    8000503a:	e45e                	sd	s7,8(sp)
    8000503c:	e062                	sd	s8,0(sp)
    8000503e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005040:	00954783          	lbu	a5,9(a0)
    80005044:	10078663          	beqz	a5,80005150 <filewrite+0x128>
    80005048:	892a                	mv	s2,a0
    8000504a:	8aae                	mv	s5,a1
    8000504c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000504e:	411c                	lw	a5,0(a0)
    80005050:	4705                	li	a4,1
    80005052:	02e78263          	beq	a5,a4,80005076 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005056:	470d                	li	a4,3
    80005058:	02e78663          	beq	a5,a4,80005084 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000505c:	4709                	li	a4,2
    8000505e:	0ee79163          	bne	a5,a4,80005140 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005062:	0ac05d63          	blez	a2,8000511c <filewrite+0xf4>
    int i = 0;
    80005066:	4981                	li	s3,0
    80005068:	6b05                	lui	s6,0x1
    8000506a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000506e:	6b85                	lui	s7,0x1
    80005070:	c00b8b9b          	addiw	s7,s7,-1024
    80005074:	a861                	j	8000510c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005076:	6908                	ld	a0,16(a0)
    80005078:	00000097          	auipc	ra,0x0
    8000507c:	22e080e7          	jalr	558(ra) # 800052a6 <pipewrite>
    80005080:	8a2a                	mv	s4,a0
    80005082:	a045                	j	80005122 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005084:	02451783          	lh	a5,36(a0)
    80005088:	03079693          	slli	a3,a5,0x30
    8000508c:	92c1                	srli	a3,a3,0x30
    8000508e:	4725                	li	a4,9
    80005090:	0cd76263          	bltu	a4,a3,80005154 <filewrite+0x12c>
    80005094:	0792                	slli	a5,a5,0x4
    80005096:	00026717          	auipc	a4,0x26
    8000509a:	9ba70713          	addi	a4,a4,-1606 # 8002aa50 <devsw>
    8000509e:	97ba                	add	a5,a5,a4
    800050a0:	679c                	ld	a5,8(a5)
    800050a2:	cbdd                	beqz	a5,80005158 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800050a4:	4505                	li	a0,1
    800050a6:	9782                	jalr	a5
    800050a8:	8a2a                	mv	s4,a0
    800050aa:	a8a5                	j	80005122 <filewrite+0xfa>
    800050ac:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800050b0:	00000097          	auipc	ra,0x0
    800050b4:	8b0080e7          	jalr	-1872(ra) # 80004960 <begin_op>
      ilock(f->ip);
    800050b8:	01893503          	ld	a0,24(s2)
    800050bc:	fffff097          	auipc	ra,0xfffff
    800050c0:	ee2080e7          	jalr	-286(ra) # 80003f9e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800050c4:	8762                	mv	a4,s8
    800050c6:	02092683          	lw	a3,32(s2)
    800050ca:	01598633          	add	a2,s3,s5
    800050ce:	4585                	li	a1,1
    800050d0:	01893503          	ld	a0,24(s2)
    800050d4:	fffff097          	auipc	ra,0xfffff
    800050d8:	276080e7          	jalr	630(ra) # 8000434a <writei>
    800050dc:	84aa                	mv	s1,a0
    800050de:	00a05763          	blez	a0,800050ec <filewrite+0xc4>
        f->off += r;
    800050e2:	02092783          	lw	a5,32(s2)
    800050e6:	9fa9                	addw	a5,a5,a0
    800050e8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800050ec:	01893503          	ld	a0,24(s2)
    800050f0:	fffff097          	auipc	ra,0xfffff
    800050f4:	f70080e7          	jalr	-144(ra) # 80004060 <iunlock>
      end_op();
    800050f8:	00000097          	auipc	ra,0x0
    800050fc:	8e8080e7          	jalr	-1816(ra) # 800049e0 <end_op>

      if(r != n1){
    80005100:	009c1f63          	bne	s8,s1,8000511e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005104:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005108:	0149db63          	bge	s3,s4,8000511e <filewrite+0xf6>
      int n1 = n - i;
    8000510c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005110:	84be                	mv	s1,a5
    80005112:	2781                	sext.w	a5,a5
    80005114:	f8fb5ce3          	bge	s6,a5,800050ac <filewrite+0x84>
    80005118:	84de                	mv	s1,s7
    8000511a:	bf49                	j	800050ac <filewrite+0x84>
    int i = 0;
    8000511c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000511e:	013a1f63          	bne	s4,s3,8000513c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005122:	8552                	mv	a0,s4
    80005124:	60a6                	ld	ra,72(sp)
    80005126:	6406                	ld	s0,64(sp)
    80005128:	74e2                	ld	s1,56(sp)
    8000512a:	7942                	ld	s2,48(sp)
    8000512c:	79a2                	ld	s3,40(sp)
    8000512e:	7a02                	ld	s4,32(sp)
    80005130:	6ae2                	ld	s5,24(sp)
    80005132:	6b42                	ld	s6,16(sp)
    80005134:	6ba2                	ld	s7,8(sp)
    80005136:	6c02                	ld	s8,0(sp)
    80005138:	6161                	addi	sp,sp,80
    8000513a:	8082                	ret
    ret = (i == n ? n : -1);
    8000513c:	5a7d                	li	s4,-1
    8000513e:	b7d5                	j	80005122 <filewrite+0xfa>
    panic("filewrite");
    80005140:	00003517          	auipc	a0,0x3
    80005144:	62850513          	addi	a0,a0,1576 # 80008768 <syscalls+0x298>
    80005148:	ffffb097          	auipc	ra,0xffffb
    8000514c:	3fc080e7          	jalr	1020(ra) # 80000544 <panic>
    return -1;
    80005150:	5a7d                	li	s4,-1
    80005152:	bfc1                	j	80005122 <filewrite+0xfa>
      return -1;
    80005154:	5a7d                	li	s4,-1
    80005156:	b7f1                	j	80005122 <filewrite+0xfa>
    80005158:	5a7d                	li	s4,-1
    8000515a:	b7e1                	j	80005122 <filewrite+0xfa>

000000008000515c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000515c:	7179                	addi	sp,sp,-48
    8000515e:	f406                	sd	ra,40(sp)
    80005160:	f022                	sd	s0,32(sp)
    80005162:	ec26                	sd	s1,24(sp)
    80005164:	e84a                	sd	s2,16(sp)
    80005166:	e44e                	sd	s3,8(sp)
    80005168:	e052                	sd	s4,0(sp)
    8000516a:	1800                	addi	s0,sp,48
    8000516c:	84aa                	mv	s1,a0
    8000516e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005170:	0005b023          	sd	zero,0(a1)
    80005174:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005178:	00000097          	auipc	ra,0x0
    8000517c:	bf8080e7          	jalr	-1032(ra) # 80004d70 <filealloc>
    80005180:	e088                	sd	a0,0(s1)
    80005182:	c551                	beqz	a0,8000520e <pipealloc+0xb2>
    80005184:	00000097          	auipc	ra,0x0
    80005188:	bec080e7          	jalr	-1044(ra) # 80004d70 <filealloc>
    8000518c:	00aa3023          	sd	a0,0(s4)
    80005190:	c92d                	beqz	a0,80005202 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005192:	ffffc097          	auipc	ra,0xffffc
    80005196:	968080e7          	jalr	-1688(ra) # 80000afa <kalloc>
    8000519a:	892a                	mv	s2,a0
    8000519c:	c125                	beqz	a0,800051fc <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000519e:	4985                	li	s3,1
    800051a0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800051a4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800051a8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800051ac:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800051b0:	00003597          	auipc	a1,0x3
    800051b4:	5c858593          	addi	a1,a1,1480 # 80008778 <syscalls+0x2a8>
    800051b8:	ffffc097          	auipc	ra,0xffffc
    800051bc:	9a2080e7          	jalr	-1630(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    800051c0:	609c                	ld	a5,0(s1)
    800051c2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800051c6:	609c                	ld	a5,0(s1)
    800051c8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800051cc:	609c                	ld	a5,0(s1)
    800051ce:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800051d2:	609c                	ld	a5,0(s1)
    800051d4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800051d8:	000a3783          	ld	a5,0(s4)
    800051dc:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800051e0:	000a3783          	ld	a5,0(s4)
    800051e4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800051e8:	000a3783          	ld	a5,0(s4)
    800051ec:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800051f0:	000a3783          	ld	a5,0(s4)
    800051f4:	0127b823          	sd	s2,16(a5)
  return 0;
    800051f8:	4501                	li	a0,0
    800051fa:	a025                	j	80005222 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800051fc:	6088                	ld	a0,0(s1)
    800051fe:	e501                	bnez	a0,80005206 <pipealloc+0xaa>
    80005200:	a039                	j	8000520e <pipealloc+0xb2>
    80005202:	6088                	ld	a0,0(s1)
    80005204:	c51d                	beqz	a0,80005232 <pipealloc+0xd6>
    fileclose(*f0);
    80005206:	00000097          	auipc	ra,0x0
    8000520a:	c26080e7          	jalr	-986(ra) # 80004e2c <fileclose>
  if(*f1)
    8000520e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005212:	557d                	li	a0,-1
  if(*f1)
    80005214:	c799                	beqz	a5,80005222 <pipealloc+0xc6>
    fileclose(*f1);
    80005216:	853e                	mv	a0,a5
    80005218:	00000097          	auipc	ra,0x0
    8000521c:	c14080e7          	jalr	-1004(ra) # 80004e2c <fileclose>
  return -1;
    80005220:	557d                	li	a0,-1
}
    80005222:	70a2                	ld	ra,40(sp)
    80005224:	7402                	ld	s0,32(sp)
    80005226:	64e2                	ld	s1,24(sp)
    80005228:	6942                	ld	s2,16(sp)
    8000522a:	69a2                	ld	s3,8(sp)
    8000522c:	6a02                	ld	s4,0(sp)
    8000522e:	6145                	addi	sp,sp,48
    80005230:	8082                	ret
  return -1;
    80005232:	557d                	li	a0,-1
    80005234:	b7fd                	j	80005222 <pipealloc+0xc6>

0000000080005236 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005236:	1101                	addi	sp,sp,-32
    80005238:	ec06                	sd	ra,24(sp)
    8000523a:	e822                	sd	s0,16(sp)
    8000523c:	e426                	sd	s1,8(sp)
    8000523e:	e04a                	sd	s2,0(sp)
    80005240:	1000                	addi	s0,sp,32
    80005242:	84aa                	mv	s1,a0
    80005244:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005246:	ffffc097          	auipc	ra,0xffffc
    8000524a:	9a4080e7          	jalr	-1628(ra) # 80000bea <acquire>
  if(writable){
    8000524e:	02090d63          	beqz	s2,80005288 <pipeclose+0x52>
    pi->writeopen = 0;
    80005252:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005256:	21848513          	addi	a0,s1,536
    8000525a:	ffffd097          	auipc	ra,0xffffd
    8000525e:	3e6080e7          	jalr	998(ra) # 80002640 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005262:	2204b783          	ld	a5,544(s1)
    80005266:	eb95                	bnez	a5,8000529a <pipeclose+0x64>
    release(&pi->lock);
    80005268:	8526                	mv	a0,s1
    8000526a:	ffffc097          	auipc	ra,0xffffc
    8000526e:	a34080e7          	jalr	-1484(ra) # 80000c9e <release>
    kfree((char*)pi);
    80005272:	8526                	mv	a0,s1
    80005274:	ffffb097          	auipc	ra,0xffffb
    80005278:	78a080e7          	jalr	1930(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    8000527c:	60e2                	ld	ra,24(sp)
    8000527e:	6442                	ld	s0,16(sp)
    80005280:	64a2                	ld	s1,8(sp)
    80005282:	6902                	ld	s2,0(sp)
    80005284:	6105                	addi	sp,sp,32
    80005286:	8082                	ret
    pi->readopen = 0;
    80005288:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000528c:	21c48513          	addi	a0,s1,540
    80005290:	ffffd097          	auipc	ra,0xffffd
    80005294:	3b0080e7          	jalr	944(ra) # 80002640 <wakeup>
    80005298:	b7e9                	j	80005262 <pipeclose+0x2c>
    release(&pi->lock);
    8000529a:	8526                	mv	a0,s1
    8000529c:	ffffc097          	auipc	ra,0xffffc
    800052a0:	a02080e7          	jalr	-1534(ra) # 80000c9e <release>
}
    800052a4:	bfe1                	j	8000527c <pipeclose+0x46>

00000000800052a6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800052a6:	7159                	addi	sp,sp,-112
    800052a8:	f486                	sd	ra,104(sp)
    800052aa:	f0a2                	sd	s0,96(sp)
    800052ac:	eca6                	sd	s1,88(sp)
    800052ae:	e8ca                	sd	s2,80(sp)
    800052b0:	e4ce                	sd	s3,72(sp)
    800052b2:	e0d2                	sd	s4,64(sp)
    800052b4:	fc56                	sd	s5,56(sp)
    800052b6:	f85a                	sd	s6,48(sp)
    800052b8:	f45e                	sd	s7,40(sp)
    800052ba:	f062                	sd	s8,32(sp)
    800052bc:	ec66                	sd	s9,24(sp)
    800052be:	1880                	addi	s0,sp,112
    800052c0:	84aa                	mv	s1,a0
    800052c2:	8aae                	mv	s5,a1
    800052c4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800052c6:	ffffd097          	auipc	ra,0xffffd
    800052ca:	866080e7          	jalr	-1946(ra) # 80001b2c <myproc>
    800052ce:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800052d0:	8526                	mv	a0,s1
    800052d2:	ffffc097          	auipc	ra,0xffffc
    800052d6:	918080e7          	jalr	-1768(ra) # 80000bea <acquire>
  while(i < n){
    800052da:	0d405463          	blez	s4,800053a2 <pipewrite+0xfc>
    800052de:	8ba6                	mv	s7,s1
  int i = 0;
    800052e0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800052e2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800052e4:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800052e8:	21c48c13          	addi	s8,s1,540
    800052ec:	a08d                	j	8000534e <pipewrite+0xa8>
      release(&pi->lock);
    800052ee:	8526                	mv	a0,s1
    800052f0:	ffffc097          	auipc	ra,0xffffc
    800052f4:	9ae080e7          	jalr	-1618(ra) # 80000c9e <release>
      return -1;
    800052f8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800052fa:	854a                	mv	a0,s2
    800052fc:	70a6                	ld	ra,104(sp)
    800052fe:	7406                	ld	s0,96(sp)
    80005300:	64e6                	ld	s1,88(sp)
    80005302:	6946                	ld	s2,80(sp)
    80005304:	69a6                	ld	s3,72(sp)
    80005306:	6a06                	ld	s4,64(sp)
    80005308:	7ae2                	ld	s5,56(sp)
    8000530a:	7b42                	ld	s6,48(sp)
    8000530c:	7ba2                	ld	s7,40(sp)
    8000530e:	7c02                	ld	s8,32(sp)
    80005310:	6ce2                	ld	s9,24(sp)
    80005312:	6165                	addi	sp,sp,112
    80005314:	8082                	ret
      wakeup(&pi->nread);
    80005316:	8566                	mv	a0,s9
    80005318:	ffffd097          	auipc	ra,0xffffd
    8000531c:	328080e7          	jalr	808(ra) # 80002640 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005320:	85de                	mv	a1,s7
    80005322:	8562                	mv	a0,s8
    80005324:	ffffd097          	auipc	ra,0xffffd
    80005328:	168080e7          	jalr	360(ra) # 8000248c <sleep>
    8000532c:	a839                	j	8000534a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000532e:	21c4a783          	lw	a5,540(s1)
    80005332:	0017871b          	addiw	a4,a5,1
    80005336:	20e4ae23          	sw	a4,540(s1)
    8000533a:	1ff7f793          	andi	a5,a5,511
    8000533e:	97a6                	add	a5,a5,s1
    80005340:	f9f44703          	lbu	a4,-97(s0)
    80005344:	00e78c23          	sb	a4,24(a5)
      i++;
    80005348:	2905                	addiw	s2,s2,1
  while(i < n){
    8000534a:	05495063          	bge	s2,s4,8000538a <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    8000534e:	2204a783          	lw	a5,544(s1)
    80005352:	dfd1                	beqz	a5,800052ee <pipewrite+0x48>
    80005354:	854e                	mv	a0,s3
    80005356:	ffffd097          	auipc	ra,0xffffd
    8000535a:	53a080e7          	jalr	1338(ra) # 80002890 <killed>
    8000535e:	f941                	bnez	a0,800052ee <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005360:	2184a783          	lw	a5,536(s1)
    80005364:	21c4a703          	lw	a4,540(s1)
    80005368:	2007879b          	addiw	a5,a5,512
    8000536c:	faf705e3          	beq	a4,a5,80005316 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005370:	4685                	li	a3,1
    80005372:	01590633          	add	a2,s2,s5
    80005376:	f9f40593          	addi	a1,s0,-97
    8000537a:	0509b503          	ld	a0,80(s3)
    8000537e:	ffffc097          	auipc	ra,0xffffc
    80005382:	392080e7          	jalr	914(ra) # 80001710 <copyin>
    80005386:	fb6514e3          	bne	a0,s6,8000532e <pipewrite+0x88>
  wakeup(&pi->nread);
    8000538a:	21848513          	addi	a0,s1,536
    8000538e:	ffffd097          	auipc	ra,0xffffd
    80005392:	2b2080e7          	jalr	690(ra) # 80002640 <wakeup>
  release(&pi->lock);
    80005396:	8526                	mv	a0,s1
    80005398:	ffffc097          	auipc	ra,0xffffc
    8000539c:	906080e7          	jalr	-1786(ra) # 80000c9e <release>
  return i;
    800053a0:	bfa9                	j	800052fa <pipewrite+0x54>
  int i = 0;
    800053a2:	4901                	li	s2,0
    800053a4:	b7dd                	j	8000538a <pipewrite+0xe4>

00000000800053a6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800053a6:	715d                	addi	sp,sp,-80
    800053a8:	e486                	sd	ra,72(sp)
    800053aa:	e0a2                	sd	s0,64(sp)
    800053ac:	fc26                	sd	s1,56(sp)
    800053ae:	f84a                	sd	s2,48(sp)
    800053b0:	f44e                	sd	s3,40(sp)
    800053b2:	f052                	sd	s4,32(sp)
    800053b4:	ec56                	sd	s5,24(sp)
    800053b6:	e85a                	sd	s6,16(sp)
    800053b8:	0880                	addi	s0,sp,80
    800053ba:	84aa                	mv	s1,a0
    800053bc:	892e                	mv	s2,a1
    800053be:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800053c0:	ffffc097          	auipc	ra,0xffffc
    800053c4:	76c080e7          	jalr	1900(ra) # 80001b2c <myproc>
    800053c8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800053ca:	8b26                	mv	s6,s1
    800053cc:	8526                	mv	a0,s1
    800053ce:	ffffc097          	auipc	ra,0xffffc
    800053d2:	81c080e7          	jalr	-2020(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800053d6:	2184a703          	lw	a4,536(s1)
    800053da:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800053de:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800053e2:	02f71763          	bne	a4,a5,80005410 <piperead+0x6a>
    800053e6:	2244a783          	lw	a5,548(s1)
    800053ea:	c39d                	beqz	a5,80005410 <piperead+0x6a>
    if(killed(pr)){
    800053ec:	8552                	mv	a0,s4
    800053ee:	ffffd097          	auipc	ra,0xffffd
    800053f2:	4a2080e7          	jalr	1186(ra) # 80002890 <killed>
    800053f6:	e941                	bnez	a0,80005486 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800053f8:	85da                	mv	a1,s6
    800053fa:	854e                	mv	a0,s3
    800053fc:	ffffd097          	auipc	ra,0xffffd
    80005400:	090080e7          	jalr	144(ra) # 8000248c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005404:	2184a703          	lw	a4,536(s1)
    80005408:	21c4a783          	lw	a5,540(s1)
    8000540c:	fcf70de3          	beq	a4,a5,800053e6 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005410:	09505263          	blez	s5,80005494 <piperead+0xee>
    80005414:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005416:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005418:	2184a783          	lw	a5,536(s1)
    8000541c:	21c4a703          	lw	a4,540(s1)
    80005420:	02f70d63          	beq	a4,a5,8000545a <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005424:	0017871b          	addiw	a4,a5,1
    80005428:	20e4ac23          	sw	a4,536(s1)
    8000542c:	1ff7f793          	andi	a5,a5,511
    80005430:	97a6                	add	a5,a5,s1
    80005432:	0187c783          	lbu	a5,24(a5)
    80005436:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000543a:	4685                	li	a3,1
    8000543c:	fbf40613          	addi	a2,s0,-65
    80005440:	85ca                	mv	a1,s2
    80005442:	050a3503          	ld	a0,80(s4)
    80005446:	ffffc097          	auipc	ra,0xffffc
    8000544a:	23e080e7          	jalr	574(ra) # 80001684 <copyout>
    8000544e:	01650663          	beq	a0,s6,8000545a <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005452:	2985                	addiw	s3,s3,1
    80005454:	0905                	addi	s2,s2,1
    80005456:	fd3a91e3          	bne	s5,s3,80005418 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000545a:	21c48513          	addi	a0,s1,540
    8000545e:	ffffd097          	auipc	ra,0xffffd
    80005462:	1e2080e7          	jalr	482(ra) # 80002640 <wakeup>
  release(&pi->lock);
    80005466:	8526                	mv	a0,s1
    80005468:	ffffc097          	auipc	ra,0xffffc
    8000546c:	836080e7          	jalr	-1994(ra) # 80000c9e <release>
  return i;
}
    80005470:	854e                	mv	a0,s3
    80005472:	60a6                	ld	ra,72(sp)
    80005474:	6406                	ld	s0,64(sp)
    80005476:	74e2                	ld	s1,56(sp)
    80005478:	7942                	ld	s2,48(sp)
    8000547a:	79a2                	ld	s3,40(sp)
    8000547c:	7a02                	ld	s4,32(sp)
    8000547e:	6ae2                	ld	s5,24(sp)
    80005480:	6b42                	ld	s6,16(sp)
    80005482:	6161                	addi	sp,sp,80
    80005484:	8082                	ret
      release(&pi->lock);
    80005486:	8526                	mv	a0,s1
    80005488:	ffffc097          	auipc	ra,0xffffc
    8000548c:	816080e7          	jalr	-2026(ra) # 80000c9e <release>
      return -1;
    80005490:	59fd                	li	s3,-1
    80005492:	bff9                	j	80005470 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005494:	4981                	li	s3,0
    80005496:	b7d1                	j	8000545a <piperead+0xb4>

0000000080005498 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005498:	1141                	addi	sp,sp,-16
    8000549a:	e422                	sd	s0,8(sp)
    8000549c:	0800                	addi	s0,sp,16
    8000549e:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800054a0:	8905                	andi	a0,a0,1
    800054a2:	c111                	beqz	a0,800054a6 <flags2perm+0xe>
      perm = PTE_X;
    800054a4:	4521                	li	a0,8
    if(flags & 0x2)
    800054a6:	8b89                	andi	a5,a5,2
    800054a8:	c399                	beqz	a5,800054ae <flags2perm+0x16>
      perm |= PTE_W;
    800054aa:	00456513          	ori	a0,a0,4
    return perm;
}
    800054ae:	6422                	ld	s0,8(sp)
    800054b0:	0141                	addi	sp,sp,16
    800054b2:	8082                	ret

00000000800054b4 <exec>:

int
exec(char *path, char **argv)
{
    800054b4:	df010113          	addi	sp,sp,-528
    800054b8:	20113423          	sd	ra,520(sp)
    800054bc:	20813023          	sd	s0,512(sp)
    800054c0:	ffa6                	sd	s1,504(sp)
    800054c2:	fbca                	sd	s2,496(sp)
    800054c4:	f7ce                	sd	s3,488(sp)
    800054c6:	f3d2                	sd	s4,480(sp)
    800054c8:	efd6                	sd	s5,472(sp)
    800054ca:	ebda                	sd	s6,464(sp)
    800054cc:	e7de                	sd	s7,456(sp)
    800054ce:	e3e2                	sd	s8,448(sp)
    800054d0:	ff66                	sd	s9,440(sp)
    800054d2:	fb6a                	sd	s10,432(sp)
    800054d4:	f76e                	sd	s11,424(sp)
    800054d6:	0c00                	addi	s0,sp,528
    800054d8:	84aa                	mv	s1,a0
    800054da:	dea43c23          	sd	a0,-520(s0)
    800054de:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800054e2:	ffffc097          	auipc	ra,0xffffc
    800054e6:	64a080e7          	jalr	1610(ra) # 80001b2c <myproc>
    800054ea:	892a                	mv	s2,a0

  begin_op();
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	474080e7          	jalr	1140(ra) # 80004960 <begin_op>

  if((ip = namei(path)) == 0){
    800054f4:	8526                	mv	a0,s1
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	24e080e7          	jalr	590(ra) # 80004744 <namei>
    800054fe:	c92d                	beqz	a0,80005570 <exec+0xbc>
    80005500:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005502:	fffff097          	auipc	ra,0xfffff
    80005506:	a9c080e7          	jalr	-1380(ra) # 80003f9e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000550a:	04000713          	li	a4,64
    8000550e:	4681                	li	a3,0
    80005510:	e5040613          	addi	a2,s0,-432
    80005514:	4581                	li	a1,0
    80005516:	8526                	mv	a0,s1
    80005518:	fffff097          	auipc	ra,0xfffff
    8000551c:	d3a080e7          	jalr	-710(ra) # 80004252 <readi>
    80005520:	04000793          	li	a5,64
    80005524:	00f51a63          	bne	a0,a5,80005538 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005528:	e5042703          	lw	a4,-432(s0)
    8000552c:	464c47b7          	lui	a5,0x464c4
    80005530:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005534:	04f70463          	beq	a4,a5,8000557c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005538:	8526                	mv	a0,s1
    8000553a:	fffff097          	auipc	ra,0xfffff
    8000553e:	cc6080e7          	jalr	-826(ra) # 80004200 <iunlockput>
    end_op();
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	49e080e7          	jalr	1182(ra) # 800049e0 <end_op>
  }
  return -1;
    8000554a:	557d                	li	a0,-1
}
    8000554c:	20813083          	ld	ra,520(sp)
    80005550:	20013403          	ld	s0,512(sp)
    80005554:	74fe                	ld	s1,504(sp)
    80005556:	795e                	ld	s2,496(sp)
    80005558:	79be                	ld	s3,488(sp)
    8000555a:	7a1e                	ld	s4,480(sp)
    8000555c:	6afe                	ld	s5,472(sp)
    8000555e:	6b5e                	ld	s6,464(sp)
    80005560:	6bbe                	ld	s7,456(sp)
    80005562:	6c1e                	ld	s8,448(sp)
    80005564:	7cfa                	ld	s9,440(sp)
    80005566:	7d5a                	ld	s10,432(sp)
    80005568:	7dba                	ld	s11,424(sp)
    8000556a:	21010113          	addi	sp,sp,528
    8000556e:	8082                	ret
    end_op();
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	470080e7          	jalr	1136(ra) # 800049e0 <end_op>
    return -1;
    80005578:	557d                	li	a0,-1
    8000557a:	bfc9                	j	8000554c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000557c:	854a                	mv	a0,s2
    8000557e:	ffffc097          	auipc	ra,0xffffc
    80005582:	672080e7          	jalr	1650(ra) # 80001bf0 <proc_pagetable>
    80005586:	8baa                	mv	s7,a0
    80005588:	d945                	beqz	a0,80005538 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000558a:	e7042983          	lw	s3,-400(s0)
    8000558e:	e8845783          	lhu	a5,-376(s0)
    80005592:	c7ad                	beqz	a5,800055fc <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005594:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005596:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80005598:	6c85                	lui	s9,0x1
    8000559a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000559e:	def43823          	sd	a5,-528(s0)
    800055a2:	ac0d                	j	800057d4 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800055a4:	00003517          	auipc	a0,0x3
    800055a8:	1dc50513          	addi	a0,a0,476 # 80008780 <syscalls+0x2b0>
    800055ac:	ffffb097          	auipc	ra,0xffffb
    800055b0:	f98080e7          	jalr	-104(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800055b4:	8756                	mv	a4,s5
    800055b6:	012d86bb          	addw	a3,s11,s2
    800055ba:	4581                	li	a1,0
    800055bc:	8526                	mv	a0,s1
    800055be:	fffff097          	auipc	ra,0xfffff
    800055c2:	c94080e7          	jalr	-876(ra) # 80004252 <readi>
    800055c6:	2501                	sext.w	a0,a0
    800055c8:	1aaa9a63          	bne	s5,a0,8000577c <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    800055cc:	6785                	lui	a5,0x1
    800055ce:	0127893b          	addw	s2,a5,s2
    800055d2:	77fd                	lui	a5,0xfffff
    800055d4:	01478a3b          	addw	s4,a5,s4
    800055d8:	1f897563          	bgeu	s2,s8,800057c2 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    800055dc:	02091593          	slli	a1,s2,0x20
    800055e0:	9181                	srli	a1,a1,0x20
    800055e2:	95ea                	add	a1,a1,s10
    800055e4:	855e                	mv	a0,s7
    800055e6:	ffffc097          	auipc	ra,0xffffc
    800055ea:	a92080e7          	jalr	-1390(ra) # 80001078 <walkaddr>
    800055ee:	862a                	mv	a2,a0
    if(pa == 0)
    800055f0:	d955                	beqz	a0,800055a4 <exec+0xf0>
      n = PGSIZE;
    800055f2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800055f4:	fd9a70e3          	bgeu	s4,s9,800055b4 <exec+0x100>
      n = sz - i;
    800055f8:	8ad2                	mv	s5,s4
    800055fa:	bf6d                	j	800055b4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800055fc:	4a01                	li	s4,0
  iunlockput(ip);
    800055fe:	8526                	mv	a0,s1
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	c00080e7          	jalr	-1024(ra) # 80004200 <iunlockput>
  end_op();
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	3d8080e7          	jalr	984(ra) # 800049e0 <end_op>
  p = myproc();
    80005610:	ffffc097          	auipc	ra,0xffffc
    80005614:	51c080e7          	jalr	1308(ra) # 80001b2c <myproc>
    80005618:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000561a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000561e:	6785                	lui	a5,0x1
    80005620:	17fd                	addi	a5,a5,-1
    80005622:	9a3e                	add	s4,s4,a5
    80005624:	757d                	lui	a0,0xfffff
    80005626:	00aa77b3          	and	a5,s4,a0
    8000562a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000562e:	4691                	li	a3,4
    80005630:	6609                	lui	a2,0x2
    80005632:	963e                	add	a2,a2,a5
    80005634:	85be                	mv	a1,a5
    80005636:	855e                	mv	a0,s7
    80005638:	ffffc097          	auipc	ra,0xffffc
    8000563c:	df4080e7          	jalr	-524(ra) # 8000142c <uvmalloc>
    80005640:	8b2a                	mv	s6,a0
  ip = 0;
    80005642:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005644:	12050c63          	beqz	a0,8000577c <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005648:	75f9                	lui	a1,0xffffe
    8000564a:	95aa                	add	a1,a1,a0
    8000564c:	855e                	mv	a0,s7
    8000564e:	ffffc097          	auipc	ra,0xffffc
    80005652:	004080e7          	jalr	4(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80005656:	7c7d                	lui	s8,0xfffff
    80005658:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000565a:	e0043783          	ld	a5,-512(s0)
    8000565e:	6388                	ld	a0,0(a5)
    80005660:	c535                	beqz	a0,800056cc <exec+0x218>
    80005662:	e9040993          	addi	s3,s0,-368
    80005666:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000566a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000566c:	ffffb097          	auipc	ra,0xffffb
    80005670:	7fe080e7          	jalr	2046(ra) # 80000e6a <strlen>
    80005674:	2505                	addiw	a0,a0,1
    80005676:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000567a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000567e:	13896663          	bltu	s2,s8,800057aa <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005682:	e0043d83          	ld	s11,-512(s0)
    80005686:	000dba03          	ld	s4,0(s11)
    8000568a:	8552                	mv	a0,s4
    8000568c:	ffffb097          	auipc	ra,0xffffb
    80005690:	7de080e7          	jalr	2014(ra) # 80000e6a <strlen>
    80005694:	0015069b          	addiw	a3,a0,1
    80005698:	8652                	mv	a2,s4
    8000569a:	85ca                	mv	a1,s2
    8000569c:	855e                	mv	a0,s7
    8000569e:	ffffc097          	auipc	ra,0xffffc
    800056a2:	fe6080e7          	jalr	-26(ra) # 80001684 <copyout>
    800056a6:	10054663          	bltz	a0,800057b2 <exec+0x2fe>
    ustack[argc] = sp;
    800056aa:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800056ae:	0485                	addi	s1,s1,1
    800056b0:	008d8793          	addi	a5,s11,8
    800056b4:	e0f43023          	sd	a5,-512(s0)
    800056b8:	008db503          	ld	a0,8(s11)
    800056bc:	c911                	beqz	a0,800056d0 <exec+0x21c>
    if(argc >= MAXARG)
    800056be:	09a1                	addi	s3,s3,8
    800056c0:	fb3c96e3          	bne	s9,s3,8000566c <exec+0x1b8>
  sz = sz1;
    800056c4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056c8:	4481                	li	s1,0
    800056ca:	a84d                	j	8000577c <exec+0x2c8>
  sp = sz;
    800056cc:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800056ce:	4481                	li	s1,0
  ustack[argc] = 0;
    800056d0:	00349793          	slli	a5,s1,0x3
    800056d4:	f9040713          	addi	a4,s0,-112
    800056d8:	97ba                	add	a5,a5,a4
    800056da:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800056de:	00148693          	addi	a3,s1,1
    800056e2:	068e                	slli	a3,a3,0x3
    800056e4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800056e8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800056ec:	01897663          	bgeu	s2,s8,800056f8 <exec+0x244>
  sz = sz1;
    800056f0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056f4:	4481                	li	s1,0
    800056f6:	a059                	j	8000577c <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800056f8:	e9040613          	addi	a2,s0,-368
    800056fc:	85ca                	mv	a1,s2
    800056fe:	855e                	mv	a0,s7
    80005700:	ffffc097          	auipc	ra,0xffffc
    80005704:	f84080e7          	jalr	-124(ra) # 80001684 <copyout>
    80005708:	0a054963          	bltz	a0,800057ba <exec+0x306>
  p->trapframe->a1 = sp;
    8000570c:	058ab783          	ld	a5,88(s5)
    80005710:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005714:	df843783          	ld	a5,-520(s0)
    80005718:	0007c703          	lbu	a4,0(a5)
    8000571c:	cf11                	beqz	a4,80005738 <exec+0x284>
    8000571e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005720:	02f00693          	li	a3,47
    80005724:	a039                	j	80005732 <exec+0x27e>
      last = s+1;
    80005726:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000572a:	0785                	addi	a5,a5,1
    8000572c:	fff7c703          	lbu	a4,-1(a5)
    80005730:	c701                	beqz	a4,80005738 <exec+0x284>
    if(*s == '/')
    80005732:	fed71ce3          	bne	a4,a3,8000572a <exec+0x276>
    80005736:	bfc5                	j	80005726 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005738:	4641                	li	a2,16
    8000573a:	df843583          	ld	a1,-520(s0)
    8000573e:	158a8513          	addi	a0,s5,344
    80005742:	ffffb097          	auipc	ra,0xffffb
    80005746:	6f6080e7          	jalr	1782(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    8000574a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000574e:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005752:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005756:	058ab783          	ld	a5,88(s5)
    8000575a:	e6843703          	ld	a4,-408(s0)
    8000575e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005760:	058ab783          	ld	a5,88(s5)
    80005764:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005768:	85ea                	mv	a1,s10
    8000576a:	ffffc097          	auipc	ra,0xffffc
    8000576e:	522080e7          	jalr	1314(ra) # 80001c8c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005772:	0004851b          	sext.w	a0,s1
    80005776:	bbd9                	j	8000554c <exec+0x98>
    80005778:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000577c:	e0843583          	ld	a1,-504(s0)
    80005780:	855e                	mv	a0,s7
    80005782:	ffffc097          	auipc	ra,0xffffc
    80005786:	50a080e7          	jalr	1290(ra) # 80001c8c <proc_freepagetable>
  if(ip){
    8000578a:	da0497e3          	bnez	s1,80005538 <exec+0x84>
  return -1;
    8000578e:	557d                	li	a0,-1
    80005790:	bb75                	j	8000554c <exec+0x98>
    80005792:	e1443423          	sd	s4,-504(s0)
    80005796:	b7dd                	j	8000577c <exec+0x2c8>
    80005798:	e1443423          	sd	s4,-504(s0)
    8000579c:	b7c5                	j	8000577c <exec+0x2c8>
    8000579e:	e1443423          	sd	s4,-504(s0)
    800057a2:	bfe9                	j	8000577c <exec+0x2c8>
    800057a4:	e1443423          	sd	s4,-504(s0)
    800057a8:	bfd1                	j	8000577c <exec+0x2c8>
  sz = sz1;
    800057aa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800057ae:	4481                	li	s1,0
    800057b0:	b7f1                	j	8000577c <exec+0x2c8>
  sz = sz1;
    800057b2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800057b6:	4481                	li	s1,0
    800057b8:	b7d1                	j	8000577c <exec+0x2c8>
  sz = sz1;
    800057ba:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800057be:	4481                	li	s1,0
    800057c0:	bf75                	j	8000577c <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800057c2:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057c6:	2b05                	addiw	s6,s6,1
    800057c8:	0389899b          	addiw	s3,s3,56
    800057cc:	e8845783          	lhu	a5,-376(s0)
    800057d0:	e2fb57e3          	bge	s6,a5,800055fe <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800057d4:	2981                	sext.w	s3,s3
    800057d6:	03800713          	li	a4,56
    800057da:	86ce                	mv	a3,s3
    800057dc:	e1840613          	addi	a2,s0,-488
    800057e0:	4581                	li	a1,0
    800057e2:	8526                	mv	a0,s1
    800057e4:	fffff097          	auipc	ra,0xfffff
    800057e8:	a6e080e7          	jalr	-1426(ra) # 80004252 <readi>
    800057ec:	03800793          	li	a5,56
    800057f0:	f8f514e3          	bne	a0,a5,80005778 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    800057f4:	e1842783          	lw	a5,-488(s0)
    800057f8:	4705                	li	a4,1
    800057fa:	fce796e3          	bne	a5,a4,800057c6 <exec+0x312>
    if(ph.memsz < ph.filesz)
    800057fe:	e4043903          	ld	s2,-448(s0)
    80005802:	e3843783          	ld	a5,-456(s0)
    80005806:	f8f966e3          	bltu	s2,a5,80005792 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000580a:	e2843783          	ld	a5,-472(s0)
    8000580e:	993e                	add	s2,s2,a5
    80005810:	f8f964e3          	bltu	s2,a5,80005798 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005814:	df043703          	ld	a4,-528(s0)
    80005818:	8ff9                	and	a5,a5,a4
    8000581a:	f3d1                	bnez	a5,8000579e <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000581c:	e1c42503          	lw	a0,-484(s0)
    80005820:	00000097          	auipc	ra,0x0
    80005824:	c78080e7          	jalr	-904(ra) # 80005498 <flags2perm>
    80005828:	86aa                	mv	a3,a0
    8000582a:	864a                	mv	a2,s2
    8000582c:	85d2                	mv	a1,s4
    8000582e:	855e                	mv	a0,s7
    80005830:	ffffc097          	auipc	ra,0xffffc
    80005834:	bfc080e7          	jalr	-1028(ra) # 8000142c <uvmalloc>
    80005838:	e0a43423          	sd	a0,-504(s0)
    8000583c:	d525                	beqz	a0,800057a4 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000583e:	e2843d03          	ld	s10,-472(s0)
    80005842:	e2042d83          	lw	s11,-480(s0)
    80005846:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000584a:	f60c0ce3          	beqz	s8,800057c2 <exec+0x30e>
    8000584e:	8a62                	mv	s4,s8
    80005850:	4901                	li	s2,0
    80005852:	b369                	j	800055dc <exec+0x128>

0000000080005854 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005854:	7179                	addi	sp,sp,-48
    80005856:	f406                	sd	ra,40(sp)
    80005858:	f022                	sd	s0,32(sp)
    8000585a:	ec26                	sd	s1,24(sp)
    8000585c:	e84a                	sd	s2,16(sp)
    8000585e:	1800                	addi	s0,sp,48
    80005860:	892e                	mv	s2,a1
    80005862:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005864:	fdc40593          	addi	a1,s0,-36
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	84e080e7          	jalr	-1970(ra) # 800030b6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005870:	fdc42703          	lw	a4,-36(s0)
    80005874:	47bd                	li	a5,15
    80005876:	02e7eb63          	bltu	a5,a4,800058ac <argfd+0x58>
    8000587a:	ffffc097          	auipc	ra,0xffffc
    8000587e:	2b2080e7          	jalr	690(ra) # 80001b2c <myproc>
    80005882:	fdc42703          	lw	a4,-36(s0)
    80005886:	01a70793          	addi	a5,a4,26
    8000588a:	078e                	slli	a5,a5,0x3
    8000588c:	953e                	add	a0,a0,a5
    8000588e:	611c                	ld	a5,0(a0)
    80005890:	c385                	beqz	a5,800058b0 <argfd+0x5c>
    return -1;
  if(pfd)
    80005892:	00090463          	beqz	s2,8000589a <argfd+0x46>
    *pfd = fd;
    80005896:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000589a:	4501                	li	a0,0
  if(pf)
    8000589c:	c091                	beqz	s1,800058a0 <argfd+0x4c>
    *pf = f;
    8000589e:	e09c                	sd	a5,0(s1)
}
    800058a0:	70a2                	ld	ra,40(sp)
    800058a2:	7402                	ld	s0,32(sp)
    800058a4:	64e2                	ld	s1,24(sp)
    800058a6:	6942                	ld	s2,16(sp)
    800058a8:	6145                	addi	sp,sp,48
    800058aa:	8082                	ret
    return -1;
    800058ac:	557d                	li	a0,-1
    800058ae:	bfcd                	j	800058a0 <argfd+0x4c>
    800058b0:	557d                	li	a0,-1
    800058b2:	b7fd                	j	800058a0 <argfd+0x4c>

00000000800058b4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800058b4:	1101                	addi	sp,sp,-32
    800058b6:	ec06                	sd	ra,24(sp)
    800058b8:	e822                	sd	s0,16(sp)
    800058ba:	e426                	sd	s1,8(sp)
    800058bc:	1000                	addi	s0,sp,32
    800058be:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800058c0:	ffffc097          	auipc	ra,0xffffc
    800058c4:	26c080e7          	jalr	620(ra) # 80001b2c <myproc>
    800058c8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800058ca:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd34e8>
    800058ce:	4501                	li	a0,0
    800058d0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800058d2:	6398                	ld	a4,0(a5)
    800058d4:	cb19                	beqz	a4,800058ea <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800058d6:	2505                	addiw	a0,a0,1
    800058d8:	07a1                	addi	a5,a5,8
    800058da:	fed51ce3          	bne	a0,a3,800058d2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800058de:	557d                	li	a0,-1
}
    800058e0:	60e2                	ld	ra,24(sp)
    800058e2:	6442                	ld	s0,16(sp)
    800058e4:	64a2                	ld	s1,8(sp)
    800058e6:	6105                	addi	sp,sp,32
    800058e8:	8082                	ret
      p->ofile[fd] = f;
    800058ea:	01a50793          	addi	a5,a0,26
    800058ee:	078e                	slli	a5,a5,0x3
    800058f0:	963e                	add	a2,a2,a5
    800058f2:	e204                	sd	s1,0(a2)
      return fd;
    800058f4:	b7f5                	j	800058e0 <fdalloc+0x2c>

00000000800058f6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800058f6:	715d                	addi	sp,sp,-80
    800058f8:	e486                	sd	ra,72(sp)
    800058fa:	e0a2                	sd	s0,64(sp)
    800058fc:	fc26                	sd	s1,56(sp)
    800058fe:	f84a                	sd	s2,48(sp)
    80005900:	f44e                	sd	s3,40(sp)
    80005902:	f052                	sd	s4,32(sp)
    80005904:	ec56                	sd	s5,24(sp)
    80005906:	e85a                	sd	s6,16(sp)
    80005908:	0880                	addi	s0,sp,80
    8000590a:	8b2e                	mv	s6,a1
    8000590c:	89b2                	mv	s3,a2
    8000590e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005910:	fb040593          	addi	a1,s0,-80
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	e4e080e7          	jalr	-434(ra) # 80004762 <nameiparent>
    8000591c:	84aa                	mv	s1,a0
    8000591e:	16050063          	beqz	a0,80005a7e <create+0x188>
    return 0;

  ilock(dp);
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	67c080e7          	jalr	1660(ra) # 80003f9e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000592a:	4601                	li	a2,0
    8000592c:	fb040593          	addi	a1,s0,-80
    80005930:	8526                	mv	a0,s1
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	b50080e7          	jalr	-1200(ra) # 80004482 <dirlookup>
    8000593a:	8aaa                	mv	s5,a0
    8000593c:	c931                	beqz	a0,80005990 <create+0x9a>
    iunlockput(dp);
    8000593e:	8526                	mv	a0,s1
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	8c0080e7          	jalr	-1856(ra) # 80004200 <iunlockput>
    ilock(ip);
    80005948:	8556                	mv	a0,s5
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	654080e7          	jalr	1620(ra) # 80003f9e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005952:	000b059b          	sext.w	a1,s6
    80005956:	4789                	li	a5,2
    80005958:	02f59563          	bne	a1,a5,80005982 <create+0x8c>
    8000595c:	044ad783          	lhu	a5,68(s5)
    80005960:	37f9                	addiw	a5,a5,-2
    80005962:	17c2                	slli	a5,a5,0x30
    80005964:	93c1                	srli	a5,a5,0x30
    80005966:	4705                	li	a4,1
    80005968:	00f76d63          	bltu	a4,a5,80005982 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000596c:	8556                	mv	a0,s5
    8000596e:	60a6                	ld	ra,72(sp)
    80005970:	6406                	ld	s0,64(sp)
    80005972:	74e2                	ld	s1,56(sp)
    80005974:	7942                	ld	s2,48(sp)
    80005976:	79a2                	ld	s3,40(sp)
    80005978:	7a02                	ld	s4,32(sp)
    8000597a:	6ae2                	ld	s5,24(sp)
    8000597c:	6b42                	ld	s6,16(sp)
    8000597e:	6161                	addi	sp,sp,80
    80005980:	8082                	ret
    iunlockput(ip);
    80005982:	8556                	mv	a0,s5
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	87c080e7          	jalr	-1924(ra) # 80004200 <iunlockput>
    return 0;
    8000598c:	4a81                	li	s5,0
    8000598e:	bff9                	j	8000596c <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005990:	85da                	mv	a1,s6
    80005992:	4088                	lw	a0,0(s1)
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	46e080e7          	jalr	1134(ra) # 80003e02 <ialloc>
    8000599c:	8a2a                	mv	s4,a0
    8000599e:	c921                	beqz	a0,800059ee <create+0xf8>
  ilock(ip);
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	5fe080e7          	jalr	1534(ra) # 80003f9e <ilock>
  ip->major = major;
    800059a8:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800059ac:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800059b0:	4785                	li	a5,1
    800059b2:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800059b6:	8552                	mv	a0,s4
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	51c080e7          	jalr	1308(ra) # 80003ed4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800059c0:	000b059b          	sext.w	a1,s6
    800059c4:	4785                	li	a5,1
    800059c6:	02f58b63          	beq	a1,a5,800059fc <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800059ca:	004a2603          	lw	a2,4(s4)
    800059ce:	fb040593          	addi	a1,s0,-80
    800059d2:	8526                	mv	a0,s1
    800059d4:	fffff097          	auipc	ra,0xfffff
    800059d8:	cbe080e7          	jalr	-834(ra) # 80004692 <dirlink>
    800059dc:	06054f63          	bltz	a0,80005a5a <create+0x164>
  iunlockput(dp);
    800059e0:	8526                	mv	a0,s1
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	81e080e7          	jalr	-2018(ra) # 80004200 <iunlockput>
  return ip;
    800059ea:	8ad2                	mv	s5,s4
    800059ec:	b741                	j	8000596c <create+0x76>
    iunlockput(dp);
    800059ee:	8526                	mv	a0,s1
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	810080e7          	jalr	-2032(ra) # 80004200 <iunlockput>
    return 0;
    800059f8:	8ad2                	mv	s5,s4
    800059fa:	bf8d                	j	8000596c <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800059fc:	004a2603          	lw	a2,4(s4)
    80005a00:	00003597          	auipc	a1,0x3
    80005a04:	da058593          	addi	a1,a1,-608 # 800087a0 <syscalls+0x2d0>
    80005a08:	8552                	mv	a0,s4
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	c88080e7          	jalr	-888(ra) # 80004692 <dirlink>
    80005a12:	04054463          	bltz	a0,80005a5a <create+0x164>
    80005a16:	40d0                	lw	a2,4(s1)
    80005a18:	00003597          	auipc	a1,0x3
    80005a1c:	d9058593          	addi	a1,a1,-624 # 800087a8 <syscalls+0x2d8>
    80005a20:	8552                	mv	a0,s4
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	c70080e7          	jalr	-912(ra) # 80004692 <dirlink>
    80005a2a:	02054863          	bltz	a0,80005a5a <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005a2e:	004a2603          	lw	a2,4(s4)
    80005a32:	fb040593          	addi	a1,s0,-80
    80005a36:	8526                	mv	a0,s1
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	c5a080e7          	jalr	-934(ra) # 80004692 <dirlink>
    80005a40:	00054d63          	bltz	a0,80005a5a <create+0x164>
    dp->nlink++;  // for ".."
    80005a44:	04a4d783          	lhu	a5,74(s1)
    80005a48:	2785                	addiw	a5,a5,1
    80005a4a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a4e:	8526                	mv	a0,s1
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	484080e7          	jalr	1156(ra) # 80003ed4 <iupdate>
    80005a58:	b761                	j	800059e0 <create+0xea>
  ip->nlink = 0;
    80005a5a:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005a5e:	8552                	mv	a0,s4
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	474080e7          	jalr	1140(ra) # 80003ed4 <iupdate>
  iunlockput(ip);
    80005a68:	8552                	mv	a0,s4
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	796080e7          	jalr	1942(ra) # 80004200 <iunlockput>
  iunlockput(dp);
    80005a72:	8526                	mv	a0,s1
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	78c080e7          	jalr	1932(ra) # 80004200 <iunlockput>
  return 0;
    80005a7c:	bdc5                	j	8000596c <create+0x76>
    return 0;
    80005a7e:	8aaa                	mv	s5,a0
    80005a80:	b5f5                	j	8000596c <create+0x76>

0000000080005a82 <sys_dup>:
{
    80005a82:	7179                	addi	sp,sp,-48
    80005a84:	f406                	sd	ra,40(sp)
    80005a86:	f022                	sd	s0,32(sp)
    80005a88:	ec26                	sd	s1,24(sp)
    80005a8a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005a8c:	fd840613          	addi	a2,s0,-40
    80005a90:	4581                	li	a1,0
    80005a92:	4501                	li	a0,0
    80005a94:	00000097          	auipc	ra,0x0
    80005a98:	dc0080e7          	jalr	-576(ra) # 80005854 <argfd>
    return -1;
    80005a9c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005a9e:	02054363          	bltz	a0,80005ac4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005aa2:	fd843503          	ld	a0,-40(s0)
    80005aa6:	00000097          	auipc	ra,0x0
    80005aaa:	e0e080e7          	jalr	-498(ra) # 800058b4 <fdalloc>
    80005aae:	84aa                	mv	s1,a0
    return -1;
    80005ab0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005ab2:	00054963          	bltz	a0,80005ac4 <sys_dup+0x42>
  filedup(f);
    80005ab6:	fd843503          	ld	a0,-40(s0)
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	320080e7          	jalr	800(ra) # 80004dda <filedup>
  return fd;
    80005ac2:	87a6                	mv	a5,s1
}
    80005ac4:	853e                	mv	a0,a5
    80005ac6:	70a2                	ld	ra,40(sp)
    80005ac8:	7402                	ld	s0,32(sp)
    80005aca:	64e2                	ld	s1,24(sp)
    80005acc:	6145                	addi	sp,sp,48
    80005ace:	8082                	ret

0000000080005ad0 <sys_read>:
{
    80005ad0:	7179                	addi	sp,sp,-48
    80005ad2:	f406                	sd	ra,40(sp)
    80005ad4:	f022                	sd	s0,32(sp)
    80005ad6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005ad8:	fd840593          	addi	a1,s0,-40
    80005adc:	4505                	li	a0,1
    80005ade:	ffffd097          	auipc	ra,0xffffd
    80005ae2:	5f8080e7          	jalr	1528(ra) # 800030d6 <argaddr>
  argint(2, &n);
    80005ae6:	fe440593          	addi	a1,s0,-28
    80005aea:	4509                	li	a0,2
    80005aec:	ffffd097          	auipc	ra,0xffffd
    80005af0:	5ca080e7          	jalr	1482(ra) # 800030b6 <argint>
  if(argfd(0, 0, &f) < 0)
    80005af4:	fe840613          	addi	a2,s0,-24
    80005af8:	4581                	li	a1,0
    80005afa:	4501                	li	a0,0
    80005afc:	00000097          	auipc	ra,0x0
    80005b00:	d58080e7          	jalr	-680(ra) # 80005854 <argfd>
    80005b04:	87aa                	mv	a5,a0
    return -1;
    80005b06:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b08:	0007cc63          	bltz	a5,80005b20 <sys_read+0x50>
  return fileread(f, p, n);
    80005b0c:	fe442603          	lw	a2,-28(s0)
    80005b10:	fd843583          	ld	a1,-40(s0)
    80005b14:	fe843503          	ld	a0,-24(s0)
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	44e080e7          	jalr	1102(ra) # 80004f66 <fileread>
}
    80005b20:	70a2                	ld	ra,40(sp)
    80005b22:	7402                	ld	s0,32(sp)
    80005b24:	6145                	addi	sp,sp,48
    80005b26:	8082                	ret

0000000080005b28 <sys_write>:
{
    80005b28:	7179                	addi	sp,sp,-48
    80005b2a:	f406                	sd	ra,40(sp)
    80005b2c:	f022                	sd	s0,32(sp)
    80005b2e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005b30:	fd840593          	addi	a1,s0,-40
    80005b34:	4505                	li	a0,1
    80005b36:	ffffd097          	auipc	ra,0xffffd
    80005b3a:	5a0080e7          	jalr	1440(ra) # 800030d6 <argaddr>
  argint(2, &n);
    80005b3e:	fe440593          	addi	a1,s0,-28
    80005b42:	4509                	li	a0,2
    80005b44:	ffffd097          	auipc	ra,0xffffd
    80005b48:	572080e7          	jalr	1394(ra) # 800030b6 <argint>
  if(argfd(0, 0, &f) < 0)
    80005b4c:	fe840613          	addi	a2,s0,-24
    80005b50:	4581                	li	a1,0
    80005b52:	4501                	li	a0,0
    80005b54:	00000097          	auipc	ra,0x0
    80005b58:	d00080e7          	jalr	-768(ra) # 80005854 <argfd>
    80005b5c:	87aa                	mv	a5,a0
    return -1;
    80005b5e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b60:	0007cc63          	bltz	a5,80005b78 <sys_write+0x50>
  return filewrite(f, p, n);
    80005b64:	fe442603          	lw	a2,-28(s0)
    80005b68:	fd843583          	ld	a1,-40(s0)
    80005b6c:	fe843503          	ld	a0,-24(s0)
    80005b70:	fffff097          	auipc	ra,0xfffff
    80005b74:	4b8080e7          	jalr	1208(ra) # 80005028 <filewrite>
}
    80005b78:	70a2                	ld	ra,40(sp)
    80005b7a:	7402                	ld	s0,32(sp)
    80005b7c:	6145                	addi	sp,sp,48
    80005b7e:	8082                	ret

0000000080005b80 <sys_close>:
{
    80005b80:	1101                	addi	sp,sp,-32
    80005b82:	ec06                	sd	ra,24(sp)
    80005b84:	e822                	sd	s0,16(sp)
    80005b86:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005b88:	fe040613          	addi	a2,s0,-32
    80005b8c:	fec40593          	addi	a1,s0,-20
    80005b90:	4501                	li	a0,0
    80005b92:	00000097          	auipc	ra,0x0
    80005b96:	cc2080e7          	jalr	-830(ra) # 80005854 <argfd>
    return -1;
    80005b9a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005b9c:	02054463          	bltz	a0,80005bc4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005ba0:	ffffc097          	auipc	ra,0xffffc
    80005ba4:	f8c080e7          	jalr	-116(ra) # 80001b2c <myproc>
    80005ba8:	fec42783          	lw	a5,-20(s0)
    80005bac:	07e9                	addi	a5,a5,26
    80005bae:	078e                	slli	a5,a5,0x3
    80005bb0:	97aa                	add	a5,a5,a0
    80005bb2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005bb6:	fe043503          	ld	a0,-32(s0)
    80005bba:	fffff097          	auipc	ra,0xfffff
    80005bbe:	272080e7          	jalr	626(ra) # 80004e2c <fileclose>
  return 0;
    80005bc2:	4781                	li	a5,0
}
    80005bc4:	853e                	mv	a0,a5
    80005bc6:	60e2                	ld	ra,24(sp)
    80005bc8:	6442                	ld	s0,16(sp)
    80005bca:	6105                	addi	sp,sp,32
    80005bcc:	8082                	ret

0000000080005bce <sys_fstat>:
{
    80005bce:	1101                	addi	sp,sp,-32
    80005bd0:	ec06                	sd	ra,24(sp)
    80005bd2:	e822                	sd	s0,16(sp)
    80005bd4:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005bd6:	fe040593          	addi	a1,s0,-32
    80005bda:	4505                	li	a0,1
    80005bdc:	ffffd097          	auipc	ra,0xffffd
    80005be0:	4fa080e7          	jalr	1274(ra) # 800030d6 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005be4:	fe840613          	addi	a2,s0,-24
    80005be8:	4581                	li	a1,0
    80005bea:	4501                	li	a0,0
    80005bec:	00000097          	auipc	ra,0x0
    80005bf0:	c68080e7          	jalr	-920(ra) # 80005854 <argfd>
    80005bf4:	87aa                	mv	a5,a0
    return -1;
    80005bf6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005bf8:	0007ca63          	bltz	a5,80005c0c <sys_fstat+0x3e>
  return filestat(f, st);
    80005bfc:	fe043583          	ld	a1,-32(s0)
    80005c00:	fe843503          	ld	a0,-24(s0)
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	2f0080e7          	jalr	752(ra) # 80004ef4 <filestat>
}
    80005c0c:	60e2                	ld	ra,24(sp)
    80005c0e:	6442                	ld	s0,16(sp)
    80005c10:	6105                	addi	sp,sp,32
    80005c12:	8082                	ret

0000000080005c14 <sys_link>:
{
    80005c14:	7169                	addi	sp,sp,-304
    80005c16:	f606                	sd	ra,296(sp)
    80005c18:	f222                	sd	s0,288(sp)
    80005c1a:	ee26                	sd	s1,280(sp)
    80005c1c:	ea4a                	sd	s2,272(sp)
    80005c1e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c20:	08000613          	li	a2,128
    80005c24:	ed040593          	addi	a1,s0,-304
    80005c28:	4501                	li	a0,0
    80005c2a:	ffffd097          	auipc	ra,0xffffd
    80005c2e:	4cc080e7          	jalr	1228(ra) # 800030f6 <argstr>
    return -1;
    80005c32:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c34:	10054e63          	bltz	a0,80005d50 <sys_link+0x13c>
    80005c38:	08000613          	li	a2,128
    80005c3c:	f5040593          	addi	a1,s0,-176
    80005c40:	4505                	li	a0,1
    80005c42:	ffffd097          	auipc	ra,0xffffd
    80005c46:	4b4080e7          	jalr	1204(ra) # 800030f6 <argstr>
    return -1;
    80005c4a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c4c:	10054263          	bltz	a0,80005d50 <sys_link+0x13c>
  begin_op();
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	d10080e7          	jalr	-752(ra) # 80004960 <begin_op>
  if((ip = namei(old)) == 0){
    80005c58:	ed040513          	addi	a0,s0,-304
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	ae8080e7          	jalr	-1304(ra) # 80004744 <namei>
    80005c64:	84aa                	mv	s1,a0
    80005c66:	c551                	beqz	a0,80005cf2 <sys_link+0xde>
  ilock(ip);
    80005c68:	ffffe097          	auipc	ra,0xffffe
    80005c6c:	336080e7          	jalr	822(ra) # 80003f9e <ilock>
  if(ip->type == T_DIR){
    80005c70:	04449703          	lh	a4,68(s1)
    80005c74:	4785                	li	a5,1
    80005c76:	08f70463          	beq	a4,a5,80005cfe <sys_link+0xea>
  ip->nlink++;
    80005c7a:	04a4d783          	lhu	a5,74(s1)
    80005c7e:	2785                	addiw	a5,a5,1
    80005c80:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c84:	8526                	mv	a0,s1
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	24e080e7          	jalr	590(ra) # 80003ed4 <iupdate>
  iunlock(ip);
    80005c8e:	8526                	mv	a0,s1
    80005c90:	ffffe097          	auipc	ra,0xffffe
    80005c94:	3d0080e7          	jalr	976(ra) # 80004060 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005c98:	fd040593          	addi	a1,s0,-48
    80005c9c:	f5040513          	addi	a0,s0,-176
    80005ca0:	fffff097          	auipc	ra,0xfffff
    80005ca4:	ac2080e7          	jalr	-1342(ra) # 80004762 <nameiparent>
    80005ca8:	892a                	mv	s2,a0
    80005caa:	c935                	beqz	a0,80005d1e <sys_link+0x10a>
  ilock(dp);
    80005cac:	ffffe097          	auipc	ra,0xffffe
    80005cb0:	2f2080e7          	jalr	754(ra) # 80003f9e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005cb4:	00092703          	lw	a4,0(s2)
    80005cb8:	409c                	lw	a5,0(s1)
    80005cba:	04f71d63          	bne	a4,a5,80005d14 <sys_link+0x100>
    80005cbe:	40d0                	lw	a2,4(s1)
    80005cc0:	fd040593          	addi	a1,s0,-48
    80005cc4:	854a                	mv	a0,s2
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	9cc080e7          	jalr	-1588(ra) # 80004692 <dirlink>
    80005cce:	04054363          	bltz	a0,80005d14 <sys_link+0x100>
  iunlockput(dp);
    80005cd2:	854a                	mv	a0,s2
    80005cd4:	ffffe097          	auipc	ra,0xffffe
    80005cd8:	52c080e7          	jalr	1324(ra) # 80004200 <iunlockput>
  iput(ip);
    80005cdc:	8526                	mv	a0,s1
    80005cde:	ffffe097          	auipc	ra,0xffffe
    80005ce2:	47a080e7          	jalr	1146(ra) # 80004158 <iput>
  end_op();
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	cfa080e7          	jalr	-774(ra) # 800049e0 <end_op>
  return 0;
    80005cee:	4781                	li	a5,0
    80005cf0:	a085                	j	80005d50 <sys_link+0x13c>
    end_op();
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	cee080e7          	jalr	-786(ra) # 800049e0 <end_op>
    return -1;
    80005cfa:	57fd                	li	a5,-1
    80005cfc:	a891                	j	80005d50 <sys_link+0x13c>
    iunlockput(ip);
    80005cfe:	8526                	mv	a0,s1
    80005d00:	ffffe097          	auipc	ra,0xffffe
    80005d04:	500080e7          	jalr	1280(ra) # 80004200 <iunlockput>
    end_op();
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	cd8080e7          	jalr	-808(ra) # 800049e0 <end_op>
    return -1;
    80005d10:	57fd                	li	a5,-1
    80005d12:	a83d                	j	80005d50 <sys_link+0x13c>
    iunlockput(dp);
    80005d14:	854a                	mv	a0,s2
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	4ea080e7          	jalr	1258(ra) # 80004200 <iunlockput>
  ilock(ip);
    80005d1e:	8526                	mv	a0,s1
    80005d20:	ffffe097          	auipc	ra,0xffffe
    80005d24:	27e080e7          	jalr	638(ra) # 80003f9e <ilock>
  ip->nlink--;
    80005d28:	04a4d783          	lhu	a5,74(s1)
    80005d2c:	37fd                	addiw	a5,a5,-1
    80005d2e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d32:	8526                	mv	a0,s1
    80005d34:	ffffe097          	auipc	ra,0xffffe
    80005d38:	1a0080e7          	jalr	416(ra) # 80003ed4 <iupdate>
  iunlockput(ip);
    80005d3c:	8526                	mv	a0,s1
    80005d3e:	ffffe097          	auipc	ra,0xffffe
    80005d42:	4c2080e7          	jalr	1218(ra) # 80004200 <iunlockput>
  end_op();
    80005d46:	fffff097          	auipc	ra,0xfffff
    80005d4a:	c9a080e7          	jalr	-870(ra) # 800049e0 <end_op>
  return -1;
    80005d4e:	57fd                	li	a5,-1
}
    80005d50:	853e                	mv	a0,a5
    80005d52:	70b2                	ld	ra,296(sp)
    80005d54:	7412                	ld	s0,288(sp)
    80005d56:	64f2                	ld	s1,280(sp)
    80005d58:	6952                	ld	s2,272(sp)
    80005d5a:	6155                	addi	sp,sp,304
    80005d5c:	8082                	ret

0000000080005d5e <sys_unlink>:
{
    80005d5e:	7151                	addi	sp,sp,-240
    80005d60:	f586                	sd	ra,232(sp)
    80005d62:	f1a2                	sd	s0,224(sp)
    80005d64:	eda6                	sd	s1,216(sp)
    80005d66:	e9ca                	sd	s2,208(sp)
    80005d68:	e5ce                	sd	s3,200(sp)
    80005d6a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005d6c:	08000613          	li	a2,128
    80005d70:	f3040593          	addi	a1,s0,-208
    80005d74:	4501                	li	a0,0
    80005d76:	ffffd097          	auipc	ra,0xffffd
    80005d7a:	380080e7          	jalr	896(ra) # 800030f6 <argstr>
    80005d7e:	18054163          	bltz	a0,80005f00 <sys_unlink+0x1a2>
  begin_op();
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	bde080e7          	jalr	-1058(ra) # 80004960 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005d8a:	fb040593          	addi	a1,s0,-80
    80005d8e:	f3040513          	addi	a0,s0,-208
    80005d92:	fffff097          	auipc	ra,0xfffff
    80005d96:	9d0080e7          	jalr	-1584(ra) # 80004762 <nameiparent>
    80005d9a:	84aa                	mv	s1,a0
    80005d9c:	c979                	beqz	a0,80005e72 <sys_unlink+0x114>
  ilock(dp);
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	200080e7          	jalr	512(ra) # 80003f9e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005da6:	00003597          	auipc	a1,0x3
    80005daa:	9fa58593          	addi	a1,a1,-1542 # 800087a0 <syscalls+0x2d0>
    80005dae:	fb040513          	addi	a0,s0,-80
    80005db2:	ffffe097          	auipc	ra,0xffffe
    80005db6:	6b6080e7          	jalr	1718(ra) # 80004468 <namecmp>
    80005dba:	14050a63          	beqz	a0,80005f0e <sys_unlink+0x1b0>
    80005dbe:	00003597          	auipc	a1,0x3
    80005dc2:	9ea58593          	addi	a1,a1,-1558 # 800087a8 <syscalls+0x2d8>
    80005dc6:	fb040513          	addi	a0,s0,-80
    80005dca:	ffffe097          	auipc	ra,0xffffe
    80005dce:	69e080e7          	jalr	1694(ra) # 80004468 <namecmp>
    80005dd2:	12050e63          	beqz	a0,80005f0e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005dd6:	f2c40613          	addi	a2,s0,-212
    80005dda:	fb040593          	addi	a1,s0,-80
    80005dde:	8526                	mv	a0,s1
    80005de0:	ffffe097          	auipc	ra,0xffffe
    80005de4:	6a2080e7          	jalr	1698(ra) # 80004482 <dirlookup>
    80005de8:	892a                	mv	s2,a0
    80005dea:	12050263          	beqz	a0,80005f0e <sys_unlink+0x1b0>
  ilock(ip);
    80005dee:	ffffe097          	auipc	ra,0xffffe
    80005df2:	1b0080e7          	jalr	432(ra) # 80003f9e <ilock>
  if(ip->nlink < 1)
    80005df6:	04a91783          	lh	a5,74(s2)
    80005dfa:	08f05263          	blez	a5,80005e7e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005dfe:	04491703          	lh	a4,68(s2)
    80005e02:	4785                	li	a5,1
    80005e04:	08f70563          	beq	a4,a5,80005e8e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005e08:	4641                	li	a2,16
    80005e0a:	4581                	li	a1,0
    80005e0c:	fc040513          	addi	a0,s0,-64
    80005e10:	ffffb097          	auipc	ra,0xffffb
    80005e14:	ed6080e7          	jalr	-298(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e18:	4741                	li	a4,16
    80005e1a:	f2c42683          	lw	a3,-212(s0)
    80005e1e:	fc040613          	addi	a2,s0,-64
    80005e22:	4581                	li	a1,0
    80005e24:	8526                	mv	a0,s1
    80005e26:	ffffe097          	auipc	ra,0xffffe
    80005e2a:	524080e7          	jalr	1316(ra) # 8000434a <writei>
    80005e2e:	47c1                	li	a5,16
    80005e30:	0af51563          	bne	a0,a5,80005eda <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005e34:	04491703          	lh	a4,68(s2)
    80005e38:	4785                	li	a5,1
    80005e3a:	0af70863          	beq	a4,a5,80005eea <sys_unlink+0x18c>
  iunlockput(dp);
    80005e3e:	8526                	mv	a0,s1
    80005e40:	ffffe097          	auipc	ra,0xffffe
    80005e44:	3c0080e7          	jalr	960(ra) # 80004200 <iunlockput>
  ip->nlink--;
    80005e48:	04a95783          	lhu	a5,74(s2)
    80005e4c:	37fd                	addiw	a5,a5,-1
    80005e4e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005e52:	854a                	mv	a0,s2
    80005e54:	ffffe097          	auipc	ra,0xffffe
    80005e58:	080080e7          	jalr	128(ra) # 80003ed4 <iupdate>
  iunlockput(ip);
    80005e5c:	854a                	mv	a0,s2
    80005e5e:	ffffe097          	auipc	ra,0xffffe
    80005e62:	3a2080e7          	jalr	930(ra) # 80004200 <iunlockput>
  end_op();
    80005e66:	fffff097          	auipc	ra,0xfffff
    80005e6a:	b7a080e7          	jalr	-1158(ra) # 800049e0 <end_op>
  return 0;
    80005e6e:	4501                	li	a0,0
    80005e70:	a84d                	j	80005f22 <sys_unlink+0x1c4>
    end_op();
    80005e72:	fffff097          	auipc	ra,0xfffff
    80005e76:	b6e080e7          	jalr	-1170(ra) # 800049e0 <end_op>
    return -1;
    80005e7a:	557d                	li	a0,-1
    80005e7c:	a05d                	j	80005f22 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005e7e:	00003517          	auipc	a0,0x3
    80005e82:	93250513          	addi	a0,a0,-1742 # 800087b0 <syscalls+0x2e0>
    80005e86:	ffffa097          	auipc	ra,0xffffa
    80005e8a:	6be080e7          	jalr	1726(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e8e:	04c92703          	lw	a4,76(s2)
    80005e92:	02000793          	li	a5,32
    80005e96:	f6e7f9e3          	bgeu	a5,a4,80005e08 <sys_unlink+0xaa>
    80005e9a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e9e:	4741                	li	a4,16
    80005ea0:	86ce                	mv	a3,s3
    80005ea2:	f1840613          	addi	a2,s0,-232
    80005ea6:	4581                	li	a1,0
    80005ea8:	854a                	mv	a0,s2
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	3a8080e7          	jalr	936(ra) # 80004252 <readi>
    80005eb2:	47c1                	li	a5,16
    80005eb4:	00f51b63          	bne	a0,a5,80005eca <sys_unlink+0x16c>
    if(de.inum != 0)
    80005eb8:	f1845783          	lhu	a5,-232(s0)
    80005ebc:	e7a1                	bnez	a5,80005f04 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ebe:	29c1                	addiw	s3,s3,16
    80005ec0:	04c92783          	lw	a5,76(s2)
    80005ec4:	fcf9ede3          	bltu	s3,a5,80005e9e <sys_unlink+0x140>
    80005ec8:	b781                	j	80005e08 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005eca:	00003517          	auipc	a0,0x3
    80005ece:	8fe50513          	addi	a0,a0,-1794 # 800087c8 <syscalls+0x2f8>
    80005ed2:	ffffa097          	auipc	ra,0xffffa
    80005ed6:	672080e7          	jalr	1650(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005eda:	00003517          	auipc	a0,0x3
    80005ede:	90650513          	addi	a0,a0,-1786 # 800087e0 <syscalls+0x310>
    80005ee2:	ffffa097          	auipc	ra,0xffffa
    80005ee6:	662080e7          	jalr	1634(ra) # 80000544 <panic>
    dp->nlink--;
    80005eea:	04a4d783          	lhu	a5,74(s1)
    80005eee:	37fd                	addiw	a5,a5,-1
    80005ef0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ef4:	8526                	mv	a0,s1
    80005ef6:	ffffe097          	auipc	ra,0xffffe
    80005efa:	fde080e7          	jalr	-34(ra) # 80003ed4 <iupdate>
    80005efe:	b781                	j	80005e3e <sys_unlink+0xe0>
    return -1;
    80005f00:	557d                	li	a0,-1
    80005f02:	a005                	j	80005f22 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005f04:	854a                	mv	a0,s2
    80005f06:	ffffe097          	auipc	ra,0xffffe
    80005f0a:	2fa080e7          	jalr	762(ra) # 80004200 <iunlockput>
  iunlockput(dp);
    80005f0e:	8526                	mv	a0,s1
    80005f10:	ffffe097          	auipc	ra,0xffffe
    80005f14:	2f0080e7          	jalr	752(ra) # 80004200 <iunlockput>
  end_op();
    80005f18:	fffff097          	auipc	ra,0xfffff
    80005f1c:	ac8080e7          	jalr	-1336(ra) # 800049e0 <end_op>
  return -1;
    80005f20:	557d                	li	a0,-1
}
    80005f22:	70ae                	ld	ra,232(sp)
    80005f24:	740e                	ld	s0,224(sp)
    80005f26:	64ee                	ld	s1,216(sp)
    80005f28:	694e                	ld	s2,208(sp)
    80005f2a:	69ae                	ld	s3,200(sp)
    80005f2c:	616d                	addi	sp,sp,240
    80005f2e:	8082                	ret

0000000080005f30 <sys_open>:

uint64
sys_open(void)
{
    80005f30:	7131                	addi	sp,sp,-192
    80005f32:	fd06                	sd	ra,184(sp)
    80005f34:	f922                	sd	s0,176(sp)
    80005f36:	f526                	sd	s1,168(sp)
    80005f38:	f14a                	sd	s2,160(sp)
    80005f3a:	ed4e                	sd	s3,152(sp)
    80005f3c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005f3e:	f4c40593          	addi	a1,s0,-180
    80005f42:	4505                	li	a0,1
    80005f44:	ffffd097          	auipc	ra,0xffffd
    80005f48:	172080e7          	jalr	370(ra) # 800030b6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005f4c:	08000613          	li	a2,128
    80005f50:	f5040593          	addi	a1,s0,-176
    80005f54:	4501                	li	a0,0
    80005f56:	ffffd097          	auipc	ra,0xffffd
    80005f5a:	1a0080e7          	jalr	416(ra) # 800030f6 <argstr>
    80005f5e:	87aa                	mv	a5,a0
    return -1;
    80005f60:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005f62:	0a07c963          	bltz	a5,80006014 <sys_open+0xe4>

  begin_op();
    80005f66:	fffff097          	auipc	ra,0xfffff
    80005f6a:	9fa080e7          	jalr	-1542(ra) # 80004960 <begin_op>

  if(omode & O_CREATE){
    80005f6e:	f4c42783          	lw	a5,-180(s0)
    80005f72:	2007f793          	andi	a5,a5,512
    80005f76:	cfc5                	beqz	a5,8000602e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005f78:	4681                	li	a3,0
    80005f7a:	4601                	li	a2,0
    80005f7c:	4589                	li	a1,2
    80005f7e:	f5040513          	addi	a0,s0,-176
    80005f82:	00000097          	auipc	ra,0x0
    80005f86:	974080e7          	jalr	-1676(ra) # 800058f6 <create>
    80005f8a:	84aa                	mv	s1,a0
    if(ip == 0){
    80005f8c:	c959                	beqz	a0,80006022 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005f8e:	04449703          	lh	a4,68(s1)
    80005f92:	478d                	li	a5,3
    80005f94:	00f71763          	bne	a4,a5,80005fa2 <sys_open+0x72>
    80005f98:	0464d703          	lhu	a4,70(s1)
    80005f9c:	47a5                	li	a5,9
    80005f9e:	0ce7ed63          	bltu	a5,a4,80006078 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005fa2:	fffff097          	auipc	ra,0xfffff
    80005fa6:	dce080e7          	jalr	-562(ra) # 80004d70 <filealloc>
    80005faa:	89aa                	mv	s3,a0
    80005fac:	10050363          	beqz	a0,800060b2 <sys_open+0x182>
    80005fb0:	00000097          	auipc	ra,0x0
    80005fb4:	904080e7          	jalr	-1788(ra) # 800058b4 <fdalloc>
    80005fb8:	892a                	mv	s2,a0
    80005fba:	0e054763          	bltz	a0,800060a8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005fbe:	04449703          	lh	a4,68(s1)
    80005fc2:	478d                	li	a5,3
    80005fc4:	0cf70563          	beq	a4,a5,8000608e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005fc8:	4789                	li	a5,2
    80005fca:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005fce:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005fd2:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005fd6:	f4c42783          	lw	a5,-180(s0)
    80005fda:	0017c713          	xori	a4,a5,1
    80005fde:	8b05                	andi	a4,a4,1
    80005fe0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005fe4:	0037f713          	andi	a4,a5,3
    80005fe8:	00e03733          	snez	a4,a4
    80005fec:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ff0:	4007f793          	andi	a5,a5,1024
    80005ff4:	c791                	beqz	a5,80006000 <sys_open+0xd0>
    80005ff6:	04449703          	lh	a4,68(s1)
    80005ffa:	4789                	li	a5,2
    80005ffc:	0af70063          	beq	a4,a5,8000609c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006000:	8526                	mv	a0,s1
    80006002:	ffffe097          	auipc	ra,0xffffe
    80006006:	05e080e7          	jalr	94(ra) # 80004060 <iunlock>
  end_op();
    8000600a:	fffff097          	auipc	ra,0xfffff
    8000600e:	9d6080e7          	jalr	-1578(ra) # 800049e0 <end_op>

  return fd;
    80006012:	854a                	mv	a0,s2
}
    80006014:	70ea                	ld	ra,184(sp)
    80006016:	744a                	ld	s0,176(sp)
    80006018:	74aa                	ld	s1,168(sp)
    8000601a:	790a                	ld	s2,160(sp)
    8000601c:	69ea                	ld	s3,152(sp)
    8000601e:	6129                	addi	sp,sp,192
    80006020:	8082                	ret
      end_op();
    80006022:	fffff097          	auipc	ra,0xfffff
    80006026:	9be080e7          	jalr	-1602(ra) # 800049e0 <end_op>
      return -1;
    8000602a:	557d                	li	a0,-1
    8000602c:	b7e5                	j	80006014 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000602e:	f5040513          	addi	a0,s0,-176
    80006032:	ffffe097          	auipc	ra,0xffffe
    80006036:	712080e7          	jalr	1810(ra) # 80004744 <namei>
    8000603a:	84aa                	mv	s1,a0
    8000603c:	c905                	beqz	a0,8000606c <sys_open+0x13c>
    ilock(ip);
    8000603e:	ffffe097          	auipc	ra,0xffffe
    80006042:	f60080e7          	jalr	-160(ra) # 80003f9e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006046:	04449703          	lh	a4,68(s1)
    8000604a:	4785                	li	a5,1
    8000604c:	f4f711e3          	bne	a4,a5,80005f8e <sys_open+0x5e>
    80006050:	f4c42783          	lw	a5,-180(s0)
    80006054:	d7b9                	beqz	a5,80005fa2 <sys_open+0x72>
      iunlockput(ip);
    80006056:	8526                	mv	a0,s1
    80006058:	ffffe097          	auipc	ra,0xffffe
    8000605c:	1a8080e7          	jalr	424(ra) # 80004200 <iunlockput>
      end_op();
    80006060:	fffff097          	auipc	ra,0xfffff
    80006064:	980080e7          	jalr	-1664(ra) # 800049e0 <end_op>
      return -1;
    80006068:	557d                	li	a0,-1
    8000606a:	b76d                	j	80006014 <sys_open+0xe4>
      end_op();
    8000606c:	fffff097          	auipc	ra,0xfffff
    80006070:	974080e7          	jalr	-1676(ra) # 800049e0 <end_op>
      return -1;
    80006074:	557d                	li	a0,-1
    80006076:	bf79                	j	80006014 <sys_open+0xe4>
    iunlockput(ip);
    80006078:	8526                	mv	a0,s1
    8000607a:	ffffe097          	auipc	ra,0xffffe
    8000607e:	186080e7          	jalr	390(ra) # 80004200 <iunlockput>
    end_op();
    80006082:	fffff097          	auipc	ra,0xfffff
    80006086:	95e080e7          	jalr	-1698(ra) # 800049e0 <end_op>
    return -1;
    8000608a:	557d                	li	a0,-1
    8000608c:	b761                	j	80006014 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000608e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006092:	04649783          	lh	a5,70(s1)
    80006096:	02f99223          	sh	a5,36(s3)
    8000609a:	bf25                	j	80005fd2 <sys_open+0xa2>
    itrunc(ip);
    8000609c:	8526                	mv	a0,s1
    8000609e:	ffffe097          	auipc	ra,0xffffe
    800060a2:	00e080e7          	jalr	14(ra) # 800040ac <itrunc>
    800060a6:	bfa9                	j	80006000 <sys_open+0xd0>
      fileclose(f);
    800060a8:	854e                	mv	a0,s3
    800060aa:	fffff097          	auipc	ra,0xfffff
    800060ae:	d82080e7          	jalr	-638(ra) # 80004e2c <fileclose>
    iunlockput(ip);
    800060b2:	8526                	mv	a0,s1
    800060b4:	ffffe097          	auipc	ra,0xffffe
    800060b8:	14c080e7          	jalr	332(ra) # 80004200 <iunlockput>
    end_op();
    800060bc:	fffff097          	auipc	ra,0xfffff
    800060c0:	924080e7          	jalr	-1756(ra) # 800049e0 <end_op>
    return -1;
    800060c4:	557d                	li	a0,-1
    800060c6:	b7b9                	j	80006014 <sys_open+0xe4>

00000000800060c8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800060c8:	7175                	addi	sp,sp,-144
    800060ca:	e506                	sd	ra,136(sp)
    800060cc:	e122                	sd	s0,128(sp)
    800060ce:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800060d0:	fffff097          	auipc	ra,0xfffff
    800060d4:	890080e7          	jalr	-1904(ra) # 80004960 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800060d8:	08000613          	li	a2,128
    800060dc:	f7040593          	addi	a1,s0,-144
    800060e0:	4501                	li	a0,0
    800060e2:	ffffd097          	auipc	ra,0xffffd
    800060e6:	014080e7          	jalr	20(ra) # 800030f6 <argstr>
    800060ea:	02054963          	bltz	a0,8000611c <sys_mkdir+0x54>
    800060ee:	4681                	li	a3,0
    800060f0:	4601                	li	a2,0
    800060f2:	4585                	li	a1,1
    800060f4:	f7040513          	addi	a0,s0,-144
    800060f8:	fffff097          	auipc	ra,0xfffff
    800060fc:	7fe080e7          	jalr	2046(ra) # 800058f6 <create>
    80006100:	cd11                	beqz	a0,8000611c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006102:	ffffe097          	auipc	ra,0xffffe
    80006106:	0fe080e7          	jalr	254(ra) # 80004200 <iunlockput>
  end_op();
    8000610a:	fffff097          	auipc	ra,0xfffff
    8000610e:	8d6080e7          	jalr	-1834(ra) # 800049e0 <end_op>
  return 0;
    80006112:	4501                	li	a0,0
}
    80006114:	60aa                	ld	ra,136(sp)
    80006116:	640a                	ld	s0,128(sp)
    80006118:	6149                	addi	sp,sp,144
    8000611a:	8082                	ret
    end_op();
    8000611c:	fffff097          	auipc	ra,0xfffff
    80006120:	8c4080e7          	jalr	-1852(ra) # 800049e0 <end_op>
    return -1;
    80006124:	557d                	li	a0,-1
    80006126:	b7fd                	j	80006114 <sys_mkdir+0x4c>

0000000080006128 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006128:	7135                	addi	sp,sp,-160
    8000612a:	ed06                	sd	ra,152(sp)
    8000612c:	e922                	sd	s0,144(sp)
    8000612e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006130:	fffff097          	auipc	ra,0xfffff
    80006134:	830080e7          	jalr	-2000(ra) # 80004960 <begin_op>
  argint(1, &major);
    80006138:	f6c40593          	addi	a1,s0,-148
    8000613c:	4505                	li	a0,1
    8000613e:	ffffd097          	auipc	ra,0xffffd
    80006142:	f78080e7          	jalr	-136(ra) # 800030b6 <argint>
  argint(2, &minor);
    80006146:	f6840593          	addi	a1,s0,-152
    8000614a:	4509                	li	a0,2
    8000614c:	ffffd097          	auipc	ra,0xffffd
    80006150:	f6a080e7          	jalr	-150(ra) # 800030b6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006154:	08000613          	li	a2,128
    80006158:	f7040593          	addi	a1,s0,-144
    8000615c:	4501                	li	a0,0
    8000615e:	ffffd097          	auipc	ra,0xffffd
    80006162:	f98080e7          	jalr	-104(ra) # 800030f6 <argstr>
    80006166:	02054b63          	bltz	a0,8000619c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000616a:	f6841683          	lh	a3,-152(s0)
    8000616e:	f6c41603          	lh	a2,-148(s0)
    80006172:	458d                	li	a1,3
    80006174:	f7040513          	addi	a0,s0,-144
    80006178:	fffff097          	auipc	ra,0xfffff
    8000617c:	77e080e7          	jalr	1918(ra) # 800058f6 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006180:	cd11                	beqz	a0,8000619c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006182:	ffffe097          	auipc	ra,0xffffe
    80006186:	07e080e7          	jalr	126(ra) # 80004200 <iunlockput>
  end_op();
    8000618a:	fffff097          	auipc	ra,0xfffff
    8000618e:	856080e7          	jalr	-1962(ra) # 800049e0 <end_op>
  return 0;
    80006192:	4501                	li	a0,0
}
    80006194:	60ea                	ld	ra,152(sp)
    80006196:	644a                	ld	s0,144(sp)
    80006198:	610d                	addi	sp,sp,160
    8000619a:	8082                	ret
    end_op();
    8000619c:	fffff097          	auipc	ra,0xfffff
    800061a0:	844080e7          	jalr	-1980(ra) # 800049e0 <end_op>
    return -1;
    800061a4:	557d                	li	a0,-1
    800061a6:	b7fd                	j	80006194 <sys_mknod+0x6c>

00000000800061a8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800061a8:	7135                	addi	sp,sp,-160
    800061aa:	ed06                	sd	ra,152(sp)
    800061ac:	e922                	sd	s0,144(sp)
    800061ae:	e526                	sd	s1,136(sp)
    800061b0:	e14a                	sd	s2,128(sp)
    800061b2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800061b4:	ffffc097          	auipc	ra,0xffffc
    800061b8:	978080e7          	jalr	-1672(ra) # 80001b2c <myproc>
    800061bc:	892a                	mv	s2,a0
  
  begin_op();
    800061be:	ffffe097          	auipc	ra,0xffffe
    800061c2:	7a2080e7          	jalr	1954(ra) # 80004960 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800061c6:	08000613          	li	a2,128
    800061ca:	f6040593          	addi	a1,s0,-160
    800061ce:	4501                	li	a0,0
    800061d0:	ffffd097          	auipc	ra,0xffffd
    800061d4:	f26080e7          	jalr	-218(ra) # 800030f6 <argstr>
    800061d8:	04054b63          	bltz	a0,8000622e <sys_chdir+0x86>
    800061dc:	f6040513          	addi	a0,s0,-160
    800061e0:	ffffe097          	auipc	ra,0xffffe
    800061e4:	564080e7          	jalr	1380(ra) # 80004744 <namei>
    800061e8:	84aa                	mv	s1,a0
    800061ea:	c131                	beqz	a0,8000622e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800061ec:	ffffe097          	auipc	ra,0xffffe
    800061f0:	db2080e7          	jalr	-590(ra) # 80003f9e <ilock>
  if(ip->type != T_DIR){
    800061f4:	04449703          	lh	a4,68(s1)
    800061f8:	4785                	li	a5,1
    800061fa:	04f71063          	bne	a4,a5,8000623a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800061fe:	8526                	mv	a0,s1
    80006200:	ffffe097          	auipc	ra,0xffffe
    80006204:	e60080e7          	jalr	-416(ra) # 80004060 <iunlock>
  iput(p->cwd);
    80006208:	15093503          	ld	a0,336(s2)
    8000620c:	ffffe097          	auipc	ra,0xffffe
    80006210:	f4c080e7          	jalr	-180(ra) # 80004158 <iput>
  end_op();
    80006214:	ffffe097          	auipc	ra,0xffffe
    80006218:	7cc080e7          	jalr	1996(ra) # 800049e0 <end_op>
  p->cwd = ip;
    8000621c:	14993823          	sd	s1,336(s2)
  return 0;
    80006220:	4501                	li	a0,0
}
    80006222:	60ea                	ld	ra,152(sp)
    80006224:	644a                	ld	s0,144(sp)
    80006226:	64aa                	ld	s1,136(sp)
    80006228:	690a                	ld	s2,128(sp)
    8000622a:	610d                	addi	sp,sp,160
    8000622c:	8082                	ret
    end_op();
    8000622e:	ffffe097          	auipc	ra,0xffffe
    80006232:	7b2080e7          	jalr	1970(ra) # 800049e0 <end_op>
    return -1;
    80006236:	557d                	li	a0,-1
    80006238:	b7ed                	j	80006222 <sys_chdir+0x7a>
    iunlockput(ip);
    8000623a:	8526                	mv	a0,s1
    8000623c:	ffffe097          	auipc	ra,0xffffe
    80006240:	fc4080e7          	jalr	-60(ra) # 80004200 <iunlockput>
    end_op();
    80006244:	ffffe097          	auipc	ra,0xffffe
    80006248:	79c080e7          	jalr	1948(ra) # 800049e0 <end_op>
    return -1;
    8000624c:	557d                	li	a0,-1
    8000624e:	bfd1                	j	80006222 <sys_chdir+0x7a>

0000000080006250 <sys_exec>:

uint64
sys_exec(void)
{
    80006250:	7145                	addi	sp,sp,-464
    80006252:	e786                	sd	ra,456(sp)
    80006254:	e3a2                	sd	s0,448(sp)
    80006256:	ff26                	sd	s1,440(sp)
    80006258:	fb4a                	sd	s2,432(sp)
    8000625a:	f74e                	sd	s3,424(sp)
    8000625c:	f352                	sd	s4,416(sp)
    8000625e:	ef56                	sd	s5,408(sp)
    80006260:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006262:	e3840593          	addi	a1,s0,-456
    80006266:	4505                	li	a0,1
    80006268:	ffffd097          	auipc	ra,0xffffd
    8000626c:	e6e080e7          	jalr	-402(ra) # 800030d6 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006270:	08000613          	li	a2,128
    80006274:	f4040593          	addi	a1,s0,-192
    80006278:	4501                	li	a0,0
    8000627a:	ffffd097          	auipc	ra,0xffffd
    8000627e:	e7c080e7          	jalr	-388(ra) # 800030f6 <argstr>
    80006282:	87aa                	mv	a5,a0
    return -1;
    80006284:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006286:	0c07c263          	bltz	a5,8000634a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000628a:	10000613          	li	a2,256
    8000628e:	4581                	li	a1,0
    80006290:	e4040513          	addi	a0,s0,-448
    80006294:	ffffb097          	auipc	ra,0xffffb
    80006298:	a52080e7          	jalr	-1454(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000629c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800062a0:	89a6                	mv	s3,s1
    800062a2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800062a4:	02000a13          	li	s4,32
    800062a8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800062ac:	00391513          	slli	a0,s2,0x3
    800062b0:	e3040593          	addi	a1,s0,-464
    800062b4:	e3843783          	ld	a5,-456(s0)
    800062b8:	953e                	add	a0,a0,a5
    800062ba:	ffffd097          	auipc	ra,0xffffd
    800062be:	d5e080e7          	jalr	-674(ra) # 80003018 <fetchaddr>
    800062c2:	02054a63          	bltz	a0,800062f6 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800062c6:	e3043783          	ld	a5,-464(s0)
    800062ca:	c3b9                	beqz	a5,80006310 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800062cc:	ffffb097          	auipc	ra,0xffffb
    800062d0:	82e080e7          	jalr	-2002(ra) # 80000afa <kalloc>
    800062d4:	85aa                	mv	a1,a0
    800062d6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800062da:	cd11                	beqz	a0,800062f6 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800062dc:	6605                	lui	a2,0x1
    800062de:	e3043503          	ld	a0,-464(s0)
    800062e2:	ffffd097          	auipc	ra,0xffffd
    800062e6:	d88080e7          	jalr	-632(ra) # 8000306a <fetchstr>
    800062ea:	00054663          	bltz	a0,800062f6 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800062ee:	0905                	addi	s2,s2,1
    800062f0:	09a1                	addi	s3,s3,8
    800062f2:	fb491be3          	bne	s2,s4,800062a8 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062f6:	10048913          	addi	s2,s1,256
    800062fa:	6088                	ld	a0,0(s1)
    800062fc:	c531                	beqz	a0,80006348 <sys_exec+0xf8>
    kfree(argv[i]);
    800062fe:	ffffa097          	auipc	ra,0xffffa
    80006302:	700080e7          	jalr	1792(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006306:	04a1                	addi	s1,s1,8
    80006308:	ff2499e3          	bne	s1,s2,800062fa <sys_exec+0xaa>
  return -1;
    8000630c:	557d                	li	a0,-1
    8000630e:	a835                	j	8000634a <sys_exec+0xfa>
      argv[i] = 0;
    80006310:	0a8e                	slli	s5,s5,0x3
    80006312:	fc040793          	addi	a5,s0,-64
    80006316:	9abe                	add	s5,s5,a5
    80006318:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000631c:	e4040593          	addi	a1,s0,-448
    80006320:	f4040513          	addi	a0,s0,-192
    80006324:	fffff097          	auipc	ra,0xfffff
    80006328:	190080e7          	jalr	400(ra) # 800054b4 <exec>
    8000632c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000632e:	10048993          	addi	s3,s1,256
    80006332:	6088                	ld	a0,0(s1)
    80006334:	c901                	beqz	a0,80006344 <sys_exec+0xf4>
    kfree(argv[i]);
    80006336:	ffffa097          	auipc	ra,0xffffa
    8000633a:	6c8080e7          	jalr	1736(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000633e:	04a1                	addi	s1,s1,8
    80006340:	ff3499e3          	bne	s1,s3,80006332 <sys_exec+0xe2>
  return ret;
    80006344:	854a                	mv	a0,s2
    80006346:	a011                	j	8000634a <sys_exec+0xfa>
  return -1;
    80006348:	557d                	li	a0,-1
}
    8000634a:	60be                	ld	ra,456(sp)
    8000634c:	641e                	ld	s0,448(sp)
    8000634e:	74fa                	ld	s1,440(sp)
    80006350:	795a                	ld	s2,432(sp)
    80006352:	79ba                	ld	s3,424(sp)
    80006354:	7a1a                	ld	s4,416(sp)
    80006356:	6afa                	ld	s5,408(sp)
    80006358:	6179                	addi	sp,sp,464
    8000635a:	8082                	ret

000000008000635c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000635c:	7139                	addi	sp,sp,-64
    8000635e:	fc06                	sd	ra,56(sp)
    80006360:	f822                	sd	s0,48(sp)
    80006362:	f426                	sd	s1,40(sp)
    80006364:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006366:	ffffb097          	auipc	ra,0xffffb
    8000636a:	7c6080e7          	jalr	1990(ra) # 80001b2c <myproc>
    8000636e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006370:	fd840593          	addi	a1,s0,-40
    80006374:	4501                	li	a0,0
    80006376:	ffffd097          	auipc	ra,0xffffd
    8000637a:	d60080e7          	jalr	-672(ra) # 800030d6 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000637e:	fc840593          	addi	a1,s0,-56
    80006382:	fd040513          	addi	a0,s0,-48
    80006386:	fffff097          	auipc	ra,0xfffff
    8000638a:	dd6080e7          	jalr	-554(ra) # 8000515c <pipealloc>
    return -1;
    8000638e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006390:	0c054463          	bltz	a0,80006458 <sys_pipe+0xfc>
  fd0 = -1;
    80006394:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006398:	fd043503          	ld	a0,-48(s0)
    8000639c:	fffff097          	auipc	ra,0xfffff
    800063a0:	518080e7          	jalr	1304(ra) # 800058b4 <fdalloc>
    800063a4:	fca42223          	sw	a0,-60(s0)
    800063a8:	08054b63          	bltz	a0,8000643e <sys_pipe+0xe2>
    800063ac:	fc843503          	ld	a0,-56(s0)
    800063b0:	fffff097          	auipc	ra,0xfffff
    800063b4:	504080e7          	jalr	1284(ra) # 800058b4 <fdalloc>
    800063b8:	fca42023          	sw	a0,-64(s0)
    800063bc:	06054863          	bltz	a0,8000642c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800063c0:	4691                	li	a3,4
    800063c2:	fc440613          	addi	a2,s0,-60
    800063c6:	fd843583          	ld	a1,-40(s0)
    800063ca:	68a8                	ld	a0,80(s1)
    800063cc:	ffffb097          	auipc	ra,0xffffb
    800063d0:	2b8080e7          	jalr	696(ra) # 80001684 <copyout>
    800063d4:	02054063          	bltz	a0,800063f4 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800063d8:	4691                	li	a3,4
    800063da:	fc040613          	addi	a2,s0,-64
    800063de:	fd843583          	ld	a1,-40(s0)
    800063e2:	0591                	addi	a1,a1,4
    800063e4:	68a8                	ld	a0,80(s1)
    800063e6:	ffffb097          	auipc	ra,0xffffb
    800063ea:	29e080e7          	jalr	670(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800063ee:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800063f0:	06055463          	bgez	a0,80006458 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800063f4:	fc442783          	lw	a5,-60(s0)
    800063f8:	07e9                	addi	a5,a5,26
    800063fa:	078e                	slli	a5,a5,0x3
    800063fc:	97a6                	add	a5,a5,s1
    800063fe:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006402:	fc042503          	lw	a0,-64(s0)
    80006406:	0569                	addi	a0,a0,26
    80006408:	050e                	slli	a0,a0,0x3
    8000640a:	94aa                	add	s1,s1,a0
    8000640c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006410:	fd043503          	ld	a0,-48(s0)
    80006414:	fffff097          	auipc	ra,0xfffff
    80006418:	a18080e7          	jalr	-1512(ra) # 80004e2c <fileclose>
    fileclose(wf);
    8000641c:	fc843503          	ld	a0,-56(s0)
    80006420:	fffff097          	auipc	ra,0xfffff
    80006424:	a0c080e7          	jalr	-1524(ra) # 80004e2c <fileclose>
    return -1;
    80006428:	57fd                	li	a5,-1
    8000642a:	a03d                	j	80006458 <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000642c:	fc442783          	lw	a5,-60(s0)
    80006430:	0007c763          	bltz	a5,8000643e <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006434:	07e9                	addi	a5,a5,26
    80006436:	078e                	slli	a5,a5,0x3
    80006438:	94be                	add	s1,s1,a5
    8000643a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000643e:	fd043503          	ld	a0,-48(s0)
    80006442:	fffff097          	auipc	ra,0xfffff
    80006446:	9ea080e7          	jalr	-1558(ra) # 80004e2c <fileclose>
    fileclose(wf);
    8000644a:	fc843503          	ld	a0,-56(s0)
    8000644e:	fffff097          	auipc	ra,0xfffff
    80006452:	9de080e7          	jalr	-1570(ra) # 80004e2c <fileclose>
    return -1;
    80006456:	57fd                	li	a5,-1
}
    80006458:	853e                	mv	a0,a5
    8000645a:	70e2                	ld	ra,56(sp)
    8000645c:	7442                	ld	s0,48(sp)
    8000645e:	74a2                	ld	s1,40(sp)
    80006460:	6121                	addi	sp,sp,64
    80006462:	8082                	ret
	...

0000000080006470 <kernelvec>:
    80006470:	7111                	addi	sp,sp,-256
    80006472:	e006                	sd	ra,0(sp)
    80006474:	e40a                	sd	sp,8(sp)
    80006476:	e80e                	sd	gp,16(sp)
    80006478:	ec12                	sd	tp,24(sp)
    8000647a:	f016                	sd	t0,32(sp)
    8000647c:	f41a                	sd	t1,40(sp)
    8000647e:	f81e                	sd	t2,48(sp)
    80006480:	fc22                	sd	s0,56(sp)
    80006482:	e0a6                	sd	s1,64(sp)
    80006484:	e4aa                	sd	a0,72(sp)
    80006486:	e8ae                	sd	a1,80(sp)
    80006488:	ecb2                	sd	a2,88(sp)
    8000648a:	f0b6                	sd	a3,96(sp)
    8000648c:	f4ba                	sd	a4,104(sp)
    8000648e:	f8be                	sd	a5,112(sp)
    80006490:	fcc2                	sd	a6,120(sp)
    80006492:	e146                	sd	a7,128(sp)
    80006494:	e54a                	sd	s2,136(sp)
    80006496:	e94e                	sd	s3,144(sp)
    80006498:	ed52                	sd	s4,152(sp)
    8000649a:	f156                	sd	s5,160(sp)
    8000649c:	f55a                	sd	s6,168(sp)
    8000649e:	f95e                	sd	s7,176(sp)
    800064a0:	fd62                	sd	s8,184(sp)
    800064a2:	e1e6                	sd	s9,192(sp)
    800064a4:	e5ea                	sd	s10,200(sp)
    800064a6:	e9ee                	sd	s11,208(sp)
    800064a8:	edf2                	sd	t3,216(sp)
    800064aa:	f1f6                	sd	t4,224(sp)
    800064ac:	f5fa                	sd	t5,232(sp)
    800064ae:	f9fe                	sd	t6,240(sp)
    800064b0:	a45fc0ef          	jal	ra,80002ef4 <kerneltrap>
    800064b4:	6082                	ld	ra,0(sp)
    800064b6:	6122                	ld	sp,8(sp)
    800064b8:	61c2                	ld	gp,16(sp)
    800064ba:	7282                	ld	t0,32(sp)
    800064bc:	7322                	ld	t1,40(sp)
    800064be:	73c2                	ld	t2,48(sp)
    800064c0:	7462                	ld	s0,56(sp)
    800064c2:	6486                	ld	s1,64(sp)
    800064c4:	6526                	ld	a0,72(sp)
    800064c6:	65c6                	ld	a1,80(sp)
    800064c8:	6666                	ld	a2,88(sp)
    800064ca:	7686                	ld	a3,96(sp)
    800064cc:	7726                	ld	a4,104(sp)
    800064ce:	77c6                	ld	a5,112(sp)
    800064d0:	7866                	ld	a6,120(sp)
    800064d2:	688a                	ld	a7,128(sp)
    800064d4:	692a                	ld	s2,136(sp)
    800064d6:	69ca                	ld	s3,144(sp)
    800064d8:	6a6a                	ld	s4,152(sp)
    800064da:	7a8a                	ld	s5,160(sp)
    800064dc:	7b2a                	ld	s6,168(sp)
    800064de:	7bca                	ld	s7,176(sp)
    800064e0:	7c6a                	ld	s8,184(sp)
    800064e2:	6c8e                	ld	s9,192(sp)
    800064e4:	6d2e                	ld	s10,200(sp)
    800064e6:	6dce                	ld	s11,208(sp)
    800064e8:	6e6e                	ld	t3,216(sp)
    800064ea:	7e8e                	ld	t4,224(sp)
    800064ec:	7f2e                	ld	t5,232(sp)
    800064ee:	7fce                	ld	t6,240(sp)
    800064f0:	6111                	addi	sp,sp,256
    800064f2:	10200073          	sret
    800064f6:	00000013          	nop
    800064fa:	00000013          	nop
    800064fe:	0001                	nop

0000000080006500 <timervec>:
    80006500:	34051573          	csrrw	a0,mscratch,a0
    80006504:	e10c                	sd	a1,0(a0)
    80006506:	e510                	sd	a2,8(a0)
    80006508:	e914                	sd	a3,16(a0)
    8000650a:	6d0c                	ld	a1,24(a0)
    8000650c:	7110                	ld	a2,32(a0)
    8000650e:	6194                	ld	a3,0(a1)
    80006510:	96b2                	add	a3,a3,a2
    80006512:	e194                	sd	a3,0(a1)
    80006514:	4589                	li	a1,2
    80006516:	14459073          	csrw	sip,a1
    8000651a:	6914                	ld	a3,16(a0)
    8000651c:	6510                	ld	a2,8(a0)
    8000651e:	610c                	ld	a1,0(a0)
    80006520:	34051573          	csrrw	a0,mscratch,a0
    80006524:	30200073          	mret
	...

000000008000652a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000652a:	1141                	addi	sp,sp,-16
    8000652c:	e422                	sd	s0,8(sp)
    8000652e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006530:	0c0007b7          	lui	a5,0xc000
    80006534:	4705                	li	a4,1
    80006536:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006538:	c3d8                	sw	a4,4(a5)
}
    8000653a:	6422                	ld	s0,8(sp)
    8000653c:	0141                	addi	sp,sp,16
    8000653e:	8082                	ret

0000000080006540 <plicinithart>:

void
plicinithart(void)
{
    80006540:	1141                	addi	sp,sp,-16
    80006542:	e406                	sd	ra,8(sp)
    80006544:	e022                	sd	s0,0(sp)
    80006546:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006548:	ffffb097          	auipc	ra,0xffffb
    8000654c:	5b8080e7          	jalr	1464(ra) # 80001b00 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006550:	0085171b          	slliw	a4,a0,0x8
    80006554:	0c0027b7          	lui	a5,0xc002
    80006558:	97ba                	add	a5,a5,a4
    8000655a:	40200713          	li	a4,1026
    8000655e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006562:	00d5151b          	slliw	a0,a0,0xd
    80006566:	0c2017b7          	lui	a5,0xc201
    8000656a:	953e                	add	a0,a0,a5
    8000656c:	00052023          	sw	zero,0(a0)
}
    80006570:	60a2                	ld	ra,8(sp)
    80006572:	6402                	ld	s0,0(sp)
    80006574:	0141                	addi	sp,sp,16
    80006576:	8082                	ret

0000000080006578 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006578:	1141                	addi	sp,sp,-16
    8000657a:	e406                	sd	ra,8(sp)
    8000657c:	e022                	sd	s0,0(sp)
    8000657e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006580:	ffffb097          	auipc	ra,0xffffb
    80006584:	580080e7          	jalr	1408(ra) # 80001b00 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006588:	00d5179b          	slliw	a5,a0,0xd
    8000658c:	0c201537          	lui	a0,0xc201
    80006590:	953e                	add	a0,a0,a5
  return irq;
}
    80006592:	4148                	lw	a0,4(a0)
    80006594:	60a2                	ld	ra,8(sp)
    80006596:	6402                	ld	s0,0(sp)
    80006598:	0141                	addi	sp,sp,16
    8000659a:	8082                	ret

000000008000659c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000659c:	1101                	addi	sp,sp,-32
    8000659e:	ec06                	sd	ra,24(sp)
    800065a0:	e822                	sd	s0,16(sp)
    800065a2:	e426                	sd	s1,8(sp)
    800065a4:	1000                	addi	s0,sp,32
    800065a6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800065a8:	ffffb097          	auipc	ra,0xffffb
    800065ac:	558080e7          	jalr	1368(ra) # 80001b00 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800065b0:	00d5151b          	slliw	a0,a0,0xd
    800065b4:	0c2017b7          	lui	a5,0xc201
    800065b8:	97aa                	add	a5,a5,a0
    800065ba:	c3c4                	sw	s1,4(a5)
}
    800065bc:	60e2                	ld	ra,24(sp)
    800065be:	6442                	ld	s0,16(sp)
    800065c0:	64a2                	ld	s1,8(sp)
    800065c2:	6105                	addi	sp,sp,32
    800065c4:	8082                	ret

00000000800065c6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800065c6:	1141                	addi	sp,sp,-16
    800065c8:	e406                	sd	ra,8(sp)
    800065ca:	e022                	sd	s0,0(sp)
    800065cc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800065ce:	479d                	li	a5,7
    800065d0:	04a7cc63          	blt	a5,a0,80006628 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800065d4:	00025797          	auipc	a5,0x25
    800065d8:	4d478793          	addi	a5,a5,1236 # 8002baa8 <disk>
    800065dc:	97aa                	add	a5,a5,a0
    800065de:	0187c783          	lbu	a5,24(a5)
    800065e2:	ebb9                	bnez	a5,80006638 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800065e4:	00451613          	slli	a2,a0,0x4
    800065e8:	00025797          	auipc	a5,0x25
    800065ec:	4c078793          	addi	a5,a5,1216 # 8002baa8 <disk>
    800065f0:	6394                	ld	a3,0(a5)
    800065f2:	96b2                	add	a3,a3,a2
    800065f4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800065f8:	6398                	ld	a4,0(a5)
    800065fa:	9732                	add	a4,a4,a2
    800065fc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006600:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006604:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006608:	953e                	add	a0,a0,a5
    8000660a:	4785                	li	a5,1
    8000660c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006610:	00025517          	auipc	a0,0x25
    80006614:	4b050513          	addi	a0,a0,1200 # 8002bac0 <disk+0x18>
    80006618:	ffffc097          	auipc	ra,0xffffc
    8000661c:	028080e7          	jalr	40(ra) # 80002640 <wakeup>
}
    80006620:	60a2                	ld	ra,8(sp)
    80006622:	6402                	ld	s0,0(sp)
    80006624:	0141                	addi	sp,sp,16
    80006626:	8082                	ret
    panic("free_desc 1");
    80006628:	00002517          	auipc	a0,0x2
    8000662c:	1c850513          	addi	a0,a0,456 # 800087f0 <syscalls+0x320>
    80006630:	ffffa097          	auipc	ra,0xffffa
    80006634:	f14080e7          	jalr	-236(ra) # 80000544 <panic>
    panic("free_desc 2");
    80006638:	00002517          	auipc	a0,0x2
    8000663c:	1c850513          	addi	a0,a0,456 # 80008800 <syscalls+0x330>
    80006640:	ffffa097          	auipc	ra,0xffffa
    80006644:	f04080e7          	jalr	-252(ra) # 80000544 <panic>

0000000080006648 <virtio_disk_init>:
{
    80006648:	1101                	addi	sp,sp,-32
    8000664a:	ec06                	sd	ra,24(sp)
    8000664c:	e822                	sd	s0,16(sp)
    8000664e:	e426                	sd	s1,8(sp)
    80006650:	e04a                	sd	s2,0(sp)
    80006652:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006654:	00002597          	auipc	a1,0x2
    80006658:	1bc58593          	addi	a1,a1,444 # 80008810 <syscalls+0x340>
    8000665c:	00025517          	auipc	a0,0x25
    80006660:	57450513          	addi	a0,a0,1396 # 8002bbd0 <disk+0x128>
    80006664:	ffffa097          	auipc	ra,0xffffa
    80006668:	4f6080e7          	jalr	1270(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000666c:	100017b7          	lui	a5,0x10001
    80006670:	4398                	lw	a4,0(a5)
    80006672:	2701                	sext.w	a4,a4
    80006674:	747277b7          	lui	a5,0x74727
    80006678:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000667c:	14f71e63          	bne	a4,a5,800067d8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006680:	100017b7          	lui	a5,0x10001
    80006684:	43dc                	lw	a5,4(a5)
    80006686:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006688:	4709                	li	a4,2
    8000668a:	14e79763          	bne	a5,a4,800067d8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000668e:	100017b7          	lui	a5,0x10001
    80006692:	479c                	lw	a5,8(a5)
    80006694:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006696:	14e79163          	bne	a5,a4,800067d8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000669a:	100017b7          	lui	a5,0x10001
    8000669e:	47d8                	lw	a4,12(a5)
    800066a0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800066a2:	554d47b7          	lui	a5,0x554d4
    800066a6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800066aa:	12f71763          	bne	a4,a5,800067d8 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    800066ae:	100017b7          	lui	a5,0x10001
    800066b2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800066b6:	4705                	li	a4,1
    800066b8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066ba:	470d                	li	a4,3
    800066bc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800066be:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800066c0:	c7ffe737          	lui	a4,0xc7ffe
    800066c4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd2b77>
    800066c8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800066ca:	2701                	sext.w	a4,a4
    800066cc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066ce:	472d                	li	a4,11
    800066d0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800066d2:	0707a903          	lw	s2,112(a5)
    800066d6:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800066d8:	00897793          	andi	a5,s2,8
    800066dc:	10078663          	beqz	a5,800067e8 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800066e0:	100017b7          	lui	a5,0x10001
    800066e4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800066e8:	43fc                	lw	a5,68(a5)
    800066ea:	2781                	sext.w	a5,a5
    800066ec:	10079663          	bnez	a5,800067f8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800066f0:	100017b7          	lui	a5,0x10001
    800066f4:	5bdc                	lw	a5,52(a5)
    800066f6:	2781                	sext.w	a5,a5
  if(max == 0)
    800066f8:	10078863          	beqz	a5,80006808 <virtio_disk_init+0x1c0>
  if(max < NUM)
    800066fc:	471d                	li	a4,7
    800066fe:	10f77d63          	bgeu	a4,a5,80006818 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006702:	ffffa097          	auipc	ra,0xffffa
    80006706:	3f8080e7          	jalr	1016(ra) # 80000afa <kalloc>
    8000670a:	00025497          	auipc	s1,0x25
    8000670e:	39e48493          	addi	s1,s1,926 # 8002baa8 <disk>
    80006712:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006714:	ffffa097          	auipc	ra,0xffffa
    80006718:	3e6080e7          	jalr	998(ra) # 80000afa <kalloc>
    8000671c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000671e:	ffffa097          	auipc	ra,0xffffa
    80006722:	3dc080e7          	jalr	988(ra) # 80000afa <kalloc>
    80006726:	87aa                	mv	a5,a0
    80006728:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    8000672a:	6088                	ld	a0,0(s1)
    8000672c:	cd75                	beqz	a0,80006828 <virtio_disk_init+0x1e0>
    8000672e:	00025717          	auipc	a4,0x25
    80006732:	38273703          	ld	a4,898(a4) # 8002bab0 <disk+0x8>
    80006736:	cb6d                	beqz	a4,80006828 <virtio_disk_init+0x1e0>
    80006738:	cbe5                	beqz	a5,80006828 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    8000673a:	6605                	lui	a2,0x1
    8000673c:	4581                	li	a1,0
    8000673e:	ffffa097          	auipc	ra,0xffffa
    80006742:	5a8080e7          	jalr	1448(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006746:	00025497          	auipc	s1,0x25
    8000674a:	36248493          	addi	s1,s1,866 # 8002baa8 <disk>
    8000674e:	6605                	lui	a2,0x1
    80006750:	4581                	li	a1,0
    80006752:	6488                	ld	a0,8(s1)
    80006754:	ffffa097          	auipc	ra,0xffffa
    80006758:	592080e7          	jalr	1426(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    8000675c:	6605                	lui	a2,0x1
    8000675e:	4581                	li	a1,0
    80006760:	6888                	ld	a0,16(s1)
    80006762:	ffffa097          	auipc	ra,0xffffa
    80006766:	584080e7          	jalr	1412(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000676a:	100017b7          	lui	a5,0x10001
    8000676e:	4721                	li	a4,8
    80006770:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006772:	4098                	lw	a4,0(s1)
    80006774:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006778:	40d8                	lw	a4,4(s1)
    8000677a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000677e:	6498                	ld	a4,8(s1)
    80006780:	0007069b          	sext.w	a3,a4
    80006784:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006788:	9701                	srai	a4,a4,0x20
    8000678a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000678e:	6898                	ld	a4,16(s1)
    80006790:	0007069b          	sext.w	a3,a4
    80006794:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006798:	9701                	srai	a4,a4,0x20
    8000679a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000679e:	4685                	li	a3,1
    800067a0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    800067a2:	4705                	li	a4,1
    800067a4:	00d48c23          	sb	a3,24(s1)
    800067a8:	00e48ca3          	sb	a4,25(s1)
    800067ac:	00e48d23          	sb	a4,26(s1)
    800067b0:	00e48da3          	sb	a4,27(s1)
    800067b4:	00e48e23          	sb	a4,28(s1)
    800067b8:	00e48ea3          	sb	a4,29(s1)
    800067bc:	00e48f23          	sb	a4,30(s1)
    800067c0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800067c4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800067c8:	0727a823          	sw	s2,112(a5)
}
    800067cc:	60e2                	ld	ra,24(sp)
    800067ce:	6442                	ld	s0,16(sp)
    800067d0:	64a2                	ld	s1,8(sp)
    800067d2:	6902                	ld	s2,0(sp)
    800067d4:	6105                	addi	sp,sp,32
    800067d6:	8082                	ret
    panic("could not find virtio disk");
    800067d8:	00002517          	auipc	a0,0x2
    800067dc:	04850513          	addi	a0,a0,72 # 80008820 <syscalls+0x350>
    800067e0:	ffffa097          	auipc	ra,0xffffa
    800067e4:	d64080e7          	jalr	-668(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    800067e8:	00002517          	auipc	a0,0x2
    800067ec:	05850513          	addi	a0,a0,88 # 80008840 <syscalls+0x370>
    800067f0:	ffffa097          	auipc	ra,0xffffa
    800067f4:	d54080e7          	jalr	-684(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    800067f8:	00002517          	auipc	a0,0x2
    800067fc:	06850513          	addi	a0,a0,104 # 80008860 <syscalls+0x390>
    80006800:	ffffa097          	auipc	ra,0xffffa
    80006804:	d44080e7          	jalr	-700(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006808:	00002517          	auipc	a0,0x2
    8000680c:	07850513          	addi	a0,a0,120 # 80008880 <syscalls+0x3b0>
    80006810:	ffffa097          	auipc	ra,0xffffa
    80006814:	d34080e7          	jalr	-716(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006818:	00002517          	auipc	a0,0x2
    8000681c:	08850513          	addi	a0,a0,136 # 800088a0 <syscalls+0x3d0>
    80006820:	ffffa097          	auipc	ra,0xffffa
    80006824:	d24080e7          	jalr	-732(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006828:	00002517          	auipc	a0,0x2
    8000682c:	09850513          	addi	a0,a0,152 # 800088c0 <syscalls+0x3f0>
    80006830:	ffffa097          	auipc	ra,0xffffa
    80006834:	d14080e7          	jalr	-748(ra) # 80000544 <panic>

0000000080006838 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006838:	7159                	addi	sp,sp,-112
    8000683a:	f486                	sd	ra,104(sp)
    8000683c:	f0a2                	sd	s0,96(sp)
    8000683e:	eca6                	sd	s1,88(sp)
    80006840:	e8ca                	sd	s2,80(sp)
    80006842:	e4ce                	sd	s3,72(sp)
    80006844:	e0d2                	sd	s4,64(sp)
    80006846:	fc56                	sd	s5,56(sp)
    80006848:	f85a                	sd	s6,48(sp)
    8000684a:	f45e                	sd	s7,40(sp)
    8000684c:	f062                	sd	s8,32(sp)
    8000684e:	ec66                	sd	s9,24(sp)
    80006850:	e86a                	sd	s10,16(sp)
    80006852:	1880                	addi	s0,sp,112
    80006854:	892a                	mv	s2,a0
    80006856:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006858:	00c52c83          	lw	s9,12(a0)
    8000685c:	001c9c9b          	slliw	s9,s9,0x1
    80006860:	1c82                	slli	s9,s9,0x20
    80006862:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006866:	00025517          	auipc	a0,0x25
    8000686a:	36a50513          	addi	a0,a0,874 # 8002bbd0 <disk+0x128>
    8000686e:	ffffa097          	auipc	ra,0xffffa
    80006872:	37c080e7          	jalr	892(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006876:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006878:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000687a:	00025b17          	auipc	s6,0x25
    8000687e:	22eb0b13          	addi	s6,s6,558 # 8002baa8 <disk>
  for(int i = 0; i < 3; i++){
    80006882:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006884:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006886:	00025c17          	auipc	s8,0x25
    8000688a:	34ac0c13          	addi	s8,s8,842 # 8002bbd0 <disk+0x128>
    8000688e:	a8b5                	j	8000690a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006890:	00fb06b3          	add	a3,s6,a5
    80006894:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006898:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000689a:	0207c563          	bltz	a5,800068c4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000689e:	2485                	addiw	s1,s1,1
    800068a0:	0711                	addi	a4,a4,4
    800068a2:	1f548a63          	beq	s1,s5,80006a96 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    800068a6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800068a8:	00025697          	auipc	a3,0x25
    800068ac:	20068693          	addi	a3,a3,512 # 8002baa8 <disk>
    800068b0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800068b2:	0186c583          	lbu	a1,24(a3)
    800068b6:	fde9                	bnez	a1,80006890 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800068b8:	2785                	addiw	a5,a5,1
    800068ba:	0685                	addi	a3,a3,1
    800068bc:	ff779be3          	bne	a5,s7,800068b2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800068c0:	57fd                	li	a5,-1
    800068c2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800068c4:	02905a63          	blez	s1,800068f8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800068c8:	f9042503          	lw	a0,-112(s0)
    800068cc:	00000097          	auipc	ra,0x0
    800068d0:	cfa080e7          	jalr	-774(ra) # 800065c6 <free_desc>
      for(int j = 0; j < i; j++)
    800068d4:	4785                	li	a5,1
    800068d6:	0297d163          	bge	a5,s1,800068f8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800068da:	f9442503          	lw	a0,-108(s0)
    800068de:	00000097          	auipc	ra,0x0
    800068e2:	ce8080e7          	jalr	-792(ra) # 800065c6 <free_desc>
      for(int j = 0; j < i; j++)
    800068e6:	4789                	li	a5,2
    800068e8:	0097d863          	bge	a5,s1,800068f8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800068ec:	f9842503          	lw	a0,-104(s0)
    800068f0:	00000097          	auipc	ra,0x0
    800068f4:	cd6080e7          	jalr	-810(ra) # 800065c6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800068f8:	85e2                	mv	a1,s8
    800068fa:	00025517          	auipc	a0,0x25
    800068fe:	1c650513          	addi	a0,a0,454 # 8002bac0 <disk+0x18>
    80006902:	ffffc097          	auipc	ra,0xffffc
    80006906:	b8a080e7          	jalr	-1142(ra) # 8000248c <sleep>
  for(int i = 0; i < 3; i++){
    8000690a:	f9040713          	addi	a4,s0,-112
    8000690e:	84ce                	mv	s1,s3
    80006910:	bf59                	j	800068a6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006912:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006916:	00479693          	slli	a3,a5,0x4
    8000691a:	00025797          	auipc	a5,0x25
    8000691e:	18e78793          	addi	a5,a5,398 # 8002baa8 <disk>
    80006922:	97b6                	add	a5,a5,a3
    80006924:	4685                	li	a3,1
    80006926:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006928:	00025597          	auipc	a1,0x25
    8000692c:	18058593          	addi	a1,a1,384 # 8002baa8 <disk>
    80006930:	00a60793          	addi	a5,a2,10
    80006934:	0792                	slli	a5,a5,0x4
    80006936:	97ae                	add	a5,a5,a1
    80006938:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000693c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006940:	f6070693          	addi	a3,a4,-160
    80006944:	619c                	ld	a5,0(a1)
    80006946:	97b6                	add	a5,a5,a3
    80006948:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000694a:	6188                	ld	a0,0(a1)
    8000694c:	96aa                	add	a3,a3,a0
    8000694e:	47c1                	li	a5,16
    80006950:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006952:	4785                	li	a5,1
    80006954:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006958:	f9442783          	lw	a5,-108(s0)
    8000695c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006960:	0792                	slli	a5,a5,0x4
    80006962:	953e                	add	a0,a0,a5
    80006964:	05890693          	addi	a3,s2,88
    80006968:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000696a:	6188                	ld	a0,0(a1)
    8000696c:	97aa                	add	a5,a5,a0
    8000696e:	40000693          	li	a3,1024
    80006972:	c794                	sw	a3,8(a5)
  if(write)
    80006974:	100d0d63          	beqz	s10,80006a8e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006978:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000697c:	00c7d683          	lhu	a3,12(a5)
    80006980:	0016e693          	ori	a3,a3,1
    80006984:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006988:	f9842583          	lw	a1,-104(s0)
    8000698c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006990:	00025697          	auipc	a3,0x25
    80006994:	11868693          	addi	a3,a3,280 # 8002baa8 <disk>
    80006998:	00260793          	addi	a5,a2,2
    8000699c:	0792                	slli	a5,a5,0x4
    8000699e:	97b6                	add	a5,a5,a3
    800069a0:	587d                	li	a6,-1
    800069a2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800069a6:	0592                	slli	a1,a1,0x4
    800069a8:	952e                	add	a0,a0,a1
    800069aa:	f9070713          	addi	a4,a4,-112
    800069ae:	9736                	add	a4,a4,a3
    800069b0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    800069b2:	6298                	ld	a4,0(a3)
    800069b4:	972e                	add	a4,a4,a1
    800069b6:	4585                	li	a1,1
    800069b8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800069ba:	4509                	li	a0,2
    800069bc:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800069c0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800069c4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800069c8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800069cc:	6698                	ld	a4,8(a3)
    800069ce:	00275783          	lhu	a5,2(a4)
    800069d2:	8b9d                	andi	a5,a5,7
    800069d4:	0786                	slli	a5,a5,0x1
    800069d6:	97ba                	add	a5,a5,a4
    800069d8:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    800069dc:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800069e0:	6698                	ld	a4,8(a3)
    800069e2:	00275783          	lhu	a5,2(a4)
    800069e6:	2785                	addiw	a5,a5,1
    800069e8:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800069ec:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800069f0:	100017b7          	lui	a5,0x10001
    800069f4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800069f8:	00492703          	lw	a4,4(s2)
    800069fc:	4785                	li	a5,1
    800069fe:	02f71163          	bne	a4,a5,80006a20 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006a02:	00025997          	auipc	s3,0x25
    80006a06:	1ce98993          	addi	s3,s3,462 # 8002bbd0 <disk+0x128>
  while(b->disk == 1) {
    80006a0a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006a0c:	85ce                	mv	a1,s3
    80006a0e:	854a                	mv	a0,s2
    80006a10:	ffffc097          	auipc	ra,0xffffc
    80006a14:	a7c080e7          	jalr	-1412(ra) # 8000248c <sleep>
  while(b->disk == 1) {
    80006a18:	00492783          	lw	a5,4(s2)
    80006a1c:	fe9788e3          	beq	a5,s1,80006a0c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006a20:	f9042903          	lw	s2,-112(s0)
    80006a24:	00290793          	addi	a5,s2,2
    80006a28:	00479713          	slli	a4,a5,0x4
    80006a2c:	00025797          	auipc	a5,0x25
    80006a30:	07c78793          	addi	a5,a5,124 # 8002baa8 <disk>
    80006a34:	97ba                	add	a5,a5,a4
    80006a36:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006a3a:	00025997          	auipc	s3,0x25
    80006a3e:	06e98993          	addi	s3,s3,110 # 8002baa8 <disk>
    80006a42:	00491713          	slli	a4,s2,0x4
    80006a46:	0009b783          	ld	a5,0(s3)
    80006a4a:	97ba                	add	a5,a5,a4
    80006a4c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006a50:	854a                	mv	a0,s2
    80006a52:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006a56:	00000097          	auipc	ra,0x0
    80006a5a:	b70080e7          	jalr	-1168(ra) # 800065c6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006a5e:	8885                	andi	s1,s1,1
    80006a60:	f0ed                	bnez	s1,80006a42 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006a62:	00025517          	auipc	a0,0x25
    80006a66:	16e50513          	addi	a0,a0,366 # 8002bbd0 <disk+0x128>
    80006a6a:	ffffa097          	auipc	ra,0xffffa
    80006a6e:	234080e7          	jalr	564(ra) # 80000c9e <release>
}
    80006a72:	70a6                	ld	ra,104(sp)
    80006a74:	7406                	ld	s0,96(sp)
    80006a76:	64e6                	ld	s1,88(sp)
    80006a78:	6946                	ld	s2,80(sp)
    80006a7a:	69a6                	ld	s3,72(sp)
    80006a7c:	6a06                	ld	s4,64(sp)
    80006a7e:	7ae2                	ld	s5,56(sp)
    80006a80:	7b42                	ld	s6,48(sp)
    80006a82:	7ba2                	ld	s7,40(sp)
    80006a84:	7c02                	ld	s8,32(sp)
    80006a86:	6ce2                	ld	s9,24(sp)
    80006a88:	6d42                	ld	s10,16(sp)
    80006a8a:	6165                	addi	sp,sp,112
    80006a8c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006a8e:	4689                	li	a3,2
    80006a90:	00d79623          	sh	a3,12(a5)
    80006a94:	b5e5                	j	8000697c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006a96:	f9042603          	lw	a2,-112(s0)
    80006a9a:	00a60713          	addi	a4,a2,10
    80006a9e:	0712                	slli	a4,a4,0x4
    80006aa0:	00025517          	auipc	a0,0x25
    80006aa4:	01050513          	addi	a0,a0,16 # 8002bab0 <disk+0x8>
    80006aa8:	953a                	add	a0,a0,a4
  if(write)
    80006aaa:	e60d14e3          	bnez	s10,80006912 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006aae:	00a60793          	addi	a5,a2,10
    80006ab2:	00479693          	slli	a3,a5,0x4
    80006ab6:	00025797          	auipc	a5,0x25
    80006aba:	ff278793          	addi	a5,a5,-14 # 8002baa8 <disk>
    80006abe:	97b6                	add	a5,a5,a3
    80006ac0:	0007a423          	sw	zero,8(a5)
    80006ac4:	b595                	j	80006928 <virtio_disk_rw+0xf0>

0000000080006ac6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006ac6:	1101                	addi	sp,sp,-32
    80006ac8:	ec06                	sd	ra,24(sp)
    80006aca:	e822                	sd	s0,16(sp)
    80006acc:	e426                	sd	s1,8(sp)
    80006ace:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006ad0:	00025497          	auipc	s1,0x25
    80006ad4:	fd848493          	addi	s1,s1,-40 # 8002baa8 <disk>
    80006ad8:	00025517          	auipc	a0,0x25
    80006adc:	0f850513          	addi	a0,a0,248 # 8002bbd0 <disk+0x128>
    80006ae0:	ffffa097          	auipc	ra,0xffffa
    80006ae4:	10a080e7          	jalr	266(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006ae8:	10001737          	lui	a4,0x10001
    80006aec:	533c                	lw	a5,96(a4)
    80006aee:	8b8d                	andi	a5,a5,3
    80006af0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006af2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006af6:	689c                	ld	a5,16(s1)
    80006af8:	0204d703          	lhu	a4,32(s1)
    80006afc:	0027d783          	lhu	a5,2(a5)
    80006b00:	04f70863          	beq	a4,a5,80006b50 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006b04:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006b08:	6898                	ld	a4,16(s1)
    80006b0a:	0204d783          	lhu	a5,32(s1)
    80006b0e:	8b9d                	andi	a5,a5,7
    80006b10:	078e                	slli	a5,a5,0x3
    80006b12:	97ba                	add	a5,a5,a4
    80006b14:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006b16:	00278713          	addi	a4,a5,2
    80006b1a:	0712                	slli	a4,a4,0x4
    80006b1c:	9726                	add	a4,a4,s1
    80006b1e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006b22:	e721                	bnez	a4,80006b6a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006b24:	0789                	addi	a5,a5,2
    80006b26:	0792                	slli	a5,a5,0x4
    80006b28:	97a6                	add	a5,a5,s1
    80006b2a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006b2c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006b30:	ffffc097          	auipc	ra,0xffffc
    80006b34:	b10080e7          	jalr	-1264(ra) # 80002640 <wakeup>

    disk.used_idx += 1;
    80006b38:	0204d783          	lhu	a5,32(s1)
    80006b3c:	2785                	addiw	a5,a5,1
    80006b3e:	17c2                	slli	a5,a5,0x30
    80006b40:	93c1                	srli	a5,a5,0x30
    80006b42:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006b46:	6898                	ld	a4,16(s1)
    80006b48:	00275703          	lhu	a4,2(a4)
    80006b4c:	faf71ce3          	bne	a4,a5,80006b04 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006b50:	00025517          	auipc	a0,0x25
    80006b54:	08050513          	addi	a0,a0,128 # 8002bbd0 <disk+0x128>
    80006b58:	ffffa097          	auipc	ra,0xffffa
    80006b5c:	146080e7          	jalr	326(ra) # 80000c9e <release>
}
    80006b60:	60e2                	ld	ra,24(sp)
    80006b62:	6442                	ld	s0,16(sp)
    80006b64:	64a2                	ld	s1,8(sp)
    80006b66:	6105                	addi	sp,sp,32
    80006b68:	8082                	ret
      panic("virtio_disk_intr status");
    80006b6a:	00002517          	auipc	a0,0x2
    80006b6e:	d6e50513          	addi	a0,a0,-658 # 800088d8 <syscalls+0x408>
    80006b72:	ffffa097          	auipc	ra,0xffffa
    80006b76:	9d2080e7          	jalr	-1582(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...

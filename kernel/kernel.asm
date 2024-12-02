
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a4010113          	addi	sp,sp,-1472 # 80008a40 <stack0>
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
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8ae70713          	addi	a4,a4,-1874 # 80008900 <timer_scratch>
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
    80000068:	f4c78793          	addi	a5,a5,-180 # 80005fb0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb80f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
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
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	3a6080e7          	jalr	934(ra) # 800024d2 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
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
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8b650513          	addi	a0,a0,-1866 # 80010a40 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8a648493          	addi	s1,s1,-1882 # 80010a40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	93690913          	addi	s2,s2,-1738 # 80010ad8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	154080e7          	jalr	340(ra) # 8000231c <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e92080e7          	jalr	-366(ra) # 80002068 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	26a080e7          	jalr	618(ra) # 8000247c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	81a50513          	addi	a0,a0,-2022 # 80010a40 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	80450513          	addi	a0,a0,-2044 # 80010a40 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	86f72323          	sw	a5,-1946(a4) # 80010ad8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	77450513          	addi	a0,a0,1908 # 80010a40 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	236080e7          	jalr	566(ra) # 80002528 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	74650513          	addi	a0,a0,1862 # 80010a40 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	72270713          	addi	a4,a4,1826 # 80010a40 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	6f878793          	addi	a5,a5,1784 # 80010a40 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7627a783          	lw	a5,1890(a5) # 80010ad8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6b670713          	addi	a4,a4,1718 # 80010a40 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6a648493          	addi	s1,s1,1702 # 80010a40 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	66a70713          	addi	a4,a4,1642 # 80010a40 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	6ef72a23          	sw	a5,1780(a4) # 80010ae0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	62e78793          	addi	a5,a5,1582 # 80010a40 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ac7a323          	sw	a2,1702(a5) # 80010adc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	69a50513          	addi	a0,a0,1690 # 80010ad8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c86080e7          	jalr	-890(ra) # 800020cc <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5e050513          	addi	a0,a0,1504 # 80010a40 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	9e078793          	addi	a5,a5,-1568 # 80021e58 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5a07ab23          	sw	zero,1462(a5) # 80010b00 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	34f72123          	sw	a5,834(a4) # 800088c0 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	546dad83          	lw	s11,1350(s11) # 80010b00 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	4f050513          	addi	a0,a0,1264 # 80010ae8 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	39250513          	addi	a0,a0,914 # 80010ae8 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	37648493          	addi	s1,s1,886 # 80010ae8 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	33650513          	addi	a0,a0,822 # 80010b08 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0c27a783          	lw	a5,194(a5) # 800088c0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0927b783          	ld	a5,146(a5) # 800088c8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	09273703          	ld	a4,146(a4) # 800088d0 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	2a8a0a13          	addi	s4,s4,680 # 80010b08 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	06048493          	addi	s1,s1,96 # 800088c8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	06098993          	addi	s3,s3,96 # 800088d0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	83a080e7          	jalr	-1990(ra) # 800020cc <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	23a50513          	addi	a0,a0,570 # 80010b08 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	fe27a783          	lw	a5,-30(a5) # 800088c0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	fe873703          	ld	a4,-24(a4) # 800088d0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	fd87b783          	ld	a5,-40(a5) # 800088c8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	20c98993          	addi	s3,s3,524 # 80010b08 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	fc448493          	addi	s1,s1,-60 # 800088c8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	fc490913          	addi	s2,s2,-60 # 800088d0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	74c080e7          	jalr	1868(ra) # 80002068 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1d648493          	addi	s1,s1,470 # 80010b08 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	f8e7b523          	sd	a4,-118(a5) # 800088d0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	14c48493          	addi	s1,s1,332 # 80010b08 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00022797          	auipc	a5,0x22
    80000a02:	5f278793          	addi	a5,a5,1522 # 80022ff0 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	12290913          	addi	s2,s2,290 # 80010b40 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	08650513          	addi	a0,a0,134 # 80010b40 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	52250513          	addi	a0,a0,1314 # 80022ff0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	05048493          	addi	s1,s1,80 # 80010b40 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	03850513          	addi	a0,a0,56 # 80010b40 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	00c50513          	addi	a0,a0,12 # 80010b40 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
      userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a5070713          	addi	a4,a4,-1456 # 800088d8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	968080e7          	jalr	-1688(ra) # 80002826 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	12a080e7          	jalr	298(ra) # 80005ff0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fe8080e7          	jalr	-24(ra) # 80001eb6 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	8c8080e7          	jalr	-1848(ra) # 800027fe <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	8e8080e7          	jalr	-1816(ra) # 80002826 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	094080e7          	jalr	148(ra) # 80005fda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	0a2080e7          	jalr	162(ra) # 80005ff0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	244080e7          	jalr	580(ra) # 8000319a <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	8e8080e7          	jalr	-1816(ra) # 80003846 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	886080e7          	jalr	-1914(ra) # 800047ec <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	18a080e7          	jalr	394(ra) # 800060f8 <virtio_disk_init>
      userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d22080e7          	jalr	-734(ra) # 80001c98 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	94f72a23          	sw	a5,-1708(a4) # 800088d8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9487b783          	ld	a5,-1720(a5) # 800088e0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	77fd                	lui	a5,0xfffff
    800010bc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	15fd                	addi	a1,a1,-1
    800010c2:	00c589b3          	add	s3,a1,a2
    800010c6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ca:	8952                	mv	s2,s4
    800010cc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	68a7b623          	sd	a0,1676(a5) # 800088e0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6cc080e7          	jalr	1740(ra) # 800009ea <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	767d                	lui	a2,0xfffff
    800013e4:	8f71                	and	a4,a4,a2
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff1                	and	a5,a5,a2
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6985                	lui	s3,0x1
    8000142e:	19fd                	addi	s3,s3,-1
    80001430:	95ce                	add	a1,a1,s3
    80001432:	79fd                	lui	s3,0xfffff
    80001434:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	54a080e7          	jalr	1354(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a821                	j	800014f4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e0:	0532                	slli	a0,a0,0xc
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	fe0080e7          	jalr	-32(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ea:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ee:	04a1                	addi	s1,s1,8
    800014f0:	03248163          	beq	s1,s2,80001512 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014f4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	00f57793          	andi	a5,a0,15
    800014fa:	ff3782e3          	beq	a5,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fe:	8905                	andi	a0,a0,1
    80001500:	d57d                	beqz	a0,800014ee <freewalk+0x2c>
      panic("freewalk: leaf");
    80001502:	00007517          	auipc	a0,0x7
    80001506:	c7650513          	addi	a0,a0,-906 # 80008178 <digits+0x138>
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	034080e7          	jalr	52(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001512:	8552                	mv	a0,s4
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	4d6080e7          	jalr	1238(ra) # 800009ea <kfree>
}
    8000151c:	70a2                	ld	ra,40(sp)
    8000151e:	7402                	ld	s0,32(sp)
    80001520:	64e2                	ld	s1,24(sp)
    80001522:	6942                	ld	s2,16(sp)
    80001524:	69a2                	ld	s3,8(sp)
    80001526:	6a02                	ld	s4,0(sp)
    80001528:	6145                	addi	sp,sp,48
    8000152a:	8082                	ret

000000008000152c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152c:	1101                	addi	sp,sp,-32
    8000152e:	ec06                	sd	ra,24(sp)
    80001530:	e822                	sd	s0,16(sp)
    80001532:	e426                	sd	s1,8(sp)
    80001534:	1000                	addi	s0,sp,32
    80001536:	84aa                	mv	s1,a0
  if(sz > 0)
    80001538:	e999                	bnez	a1,8000154e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153a:	8526                	mv	a0,s1
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f86080e7          	jalr	-122(ra) # 800014c2 <freewalk>
}
    80001544:	60e2                	ld	ra,24(sp)
    80001546:	6442                	ld	s0,16(sp)
    80001548:	64a2                	ld	s1,8(sp)
    8000154a:	6105                	addi	sp,sp,32
    8000154c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154e:	6605                	lui	a2,0x1
    80001550:	167d                	addi	a2,a2,-1
    80001552:	962e                	add	a2,a2,a1
    80001554:	4685                	li	a3,1
    80001556:	8231                	srli	a2,a2,0xc
    80001558:	4581                	li	a1,0
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	d0a080e7          	jalr	-758(ra) # 80001264 <uvmunmap>
    80001562:	bfe1                	j	8000153a <uvmfree+0xe>

0000000080001564 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001564:	c679                	beqz	a2,80001632 <uvmcopy+0xce>
{
    80001566:	715d                	addi	sp,sp,-80
    80001568:	e486                	sd	ra,72(sp)
    8000156a:	e0a2                	sd	s0,64(sp)
    8000156c:	fc26                	sd	s1,56(sp)
    8000156e:	f84a                	sd	s2,48(sp)
    80001570:	f44e                	sd	s3,40(sp)
    80001572:	f052                	sd	s4,32(sp)
    80001574:	ec56                	sd	s5,24(sp)
    80001576:	e85a                	sd	s6,16(sp)
    80001578:	e45e                	sd	s7,8(sp)
    8000157a:	0880                	addi	s0,sp,80
    8000157c:	8b2a                	mv	s6,a0
    8000157e:	8aae                	mv	s5,a1
    80001580:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001582:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001584:	4601                	li	a2,0
    80001586:	85ce                	mv	a1,s3
    80001588:	855a                	mv	a0,s6
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	a2c080e7          	jalr	-1492(ra) # 80000fb6 <walk>
    80001592:	c531                	beqz	a0,800015de <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001594:	6118                	ld	a4,0(a0)
    80001596:	00177793          	andi	a5,a4,1
    8000159a:	cbb1                	beqz	a5,800015ee <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159c:	00a75593          	srli	a1,a4,0xa
    800015a0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	53e080e7          	jalr	1342(ra) # 80000ae6 <kalloc>
    800015b0:	892a                	mv	s2,a0
    800015b2:	c939                	beqz	a0,80001608 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b4:	6605                	lui	a2,0x1
    800015b6:	85de                	mv	a1,s7
    800015b8:	fffff097          	auipc	ra,0xfffff
    800015bc:	776080e7          	jalr	1910(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c0:	8726                	mv	a4,s1
    800015c2:	86ca                	mv	a3,s2
    800015c4:	6605                	lui	a2,0x1
    800015c6:	85ce                	mv	a1,s3
    800015c8:	8556                	mv	a0,s5
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	ad4080e7          	jalr	-1324(ra) # 8000109e <mappages>
    800015d2:	e515                	bnez	a0,800015fe <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d4:	6785                	lui	a5,0x1
    800015d6:	99be                	add	s3,s3,a5
    800015d8:	fb49e6e3          	bltu	s3,s4,80001584 <uvmcopy+0x20>
    800015dc:	a081                	j	8000161c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015de:	00007517          	auipc	a0,0x7
    800015e2:	baa50513          	addi	a0,a0,-1110 # 80008188 <digits+0x148>
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015ee:	00007517          	auipc	a0,0x7
    800015f2:	bba50513          	addi	a0,a0,-1094 # 800081a8 <digits+0x168>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      kfree(mem);
    800015fe:	854a                	mv	a0,s2
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	3ea080e7          	jalr	1002(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001608:	4685                	li	a3,1
    8000160a:	00c9d613          	srli	a2,s3,0xc
    8000160e:	4581                	li	a1,0
    80001610:	8556                	mv	a0,s5
    80001612:	00000097          	auipc	ra,0x0
    80001616:	c52080e7          	jalr	-942(ra) # 80001264 <uvmunmap>
  return -1;
    8000161a:	557d                	li	a0,-1
}
    8000161c:	60a6                	ld	ra,72(sp)
    8000161e:	6406                	ld	s0,64(sp)
    80001620:	74e2                	ld	s1,56(sp)
    80001622:	7942                	ld	s2,48(sp)
    80001624:	79a2                	ld	s3,40(sp)
    80001626:	7a02                	ld	s4,32(sp)
    80001628:	6ae2                	ld	s5,24(sp)
    8000162a:	6b42                	ld	s6,16(sp)
    8000162c:	6ba2                	ld	s7,8(sp)
    8000162e:	6161                	addi	sp,sp,80
    80001630:	8082                	ret
  return 0;
    80001632:	4501                	li	a0,0
}
    80001634:	8082                	ret

0000000080001636 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001636:	1141                	addi	sp,sp,-16
    80001638:	e406                	sd	ra,8(sp)
    8000163a:	e022                	sd	s0,0(sp)
    8000163c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163e:	4601                	li	a2,0
    80001640:	00000097          	auipc	ra,0x0
    80001644:	976080e7          	jalr	-1674(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001648:	c901                	beqz	a0,80001658 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164a:	611c                	ld	a5,0(a0)
    8000164c:	9bbd                	andi	a5,a5,-17
    8000164e:	e11c                	sd	a5,0(a0)
}
    80001650:	60a2                	ld	ra,8(sp)
    80001652:	6402                	ld	s0,0(sp)
    80001654:	0141                	addi	sp,sp,16
    80001656:	8082                	ret
    panic("uvmclear");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b7050513          	addi	a0,a0,-1168 # 800081c8 <digits+0x188>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>

0000000080001668 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001668:	c6bd                	beqz	a3,800016d6 <copyout+0x6e>
{
    8000166a:	715d                	addi	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	0880                	addi	s0,sp,80
    80001682:	8b2a                	mv	s6,a0
    80001684:	8c2e                	mv	s8,a1
    80001686:	8a32                	mv	s4,a2
    80001688:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168c:	6a85                	lui	s5,0x1
    8000168e:	a015                	j	800016b2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001690:	9562                	add	a0,a0,s8
    80001692:	0004861b          	sext.w	a2,s1
    80001696:	85d2                	mv	a1,s4
    80001698:	41250533          	sub	a0,a0,s2
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	692080e7          	jalr	1682(ra) # 80000d2e <memmove>

    len -= n;
    800016a4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016aa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ae:	02098263          	beqz	s3,800016d2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b6:	85ca                	mv	a1,s2
    800016b8:	855a                	mv	a0,s6
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	9a2080e7          	jalr	-1630(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c2:	cd01                	beqz	a0,800016da <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c4:	418904b3          	sub	s1,s2,s8
    800016c8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016ca:	fc99f3e3          	bgeu	s3,s1,80001690 <copyout+0x28>
    800016ce:	84ce                	mv	s1,s3
    800016d0:	b7c1                	j	80001690 <copyout+0x28>
  }
  return 0;
    800016d2:	4501                	li	a0,0
    800016d4:	a021                	j	800016dc <copyout+0x74>
    800016d6:	4501                	li	a0,0
}
    800016d8:	8082                	ret
      return -1;
    800016da:	557d                	li	a0,-1
}
    800016dc:	60a6                	ld	ra,72(sp)
    800016de:	6406                	ld	s0,64(sp)
    800016e0:	74e2                	ld	s1,56(sp)
    800016e2:	7942                	ld	s2,48(sp)
    800016e4:	79a2                	ld	s3,40(sp)
    800016e6:	7a02                	ld	s4,32(sp)
    800016e8:	6ae2                	ld	s5,24(sp)
    800016ea:	6b42                	ld	s6,16(sp)
    800016ec:	6ba2                	ld	s7,8(sp)
    800016ee:	6c02                	ld	s8,0(sp)
    800016f0:	6161                	addi	sp,sp,80
    800016f2:	8082                	ret

00000000800016f4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f4:	caa5                	beqz	a3,80001764 <copyin+0x70>
{
    800016f6:	715d                	addi	sp,sp,-80
    800016f8:	e486                	sd	ra,72(sp)
    800016fa:	e0a2                	sd	s0,64(sp)
    800016fc:	fc26                	sd	s1,56(sp)
    800016fe:	f84a                	sd	s2,48(sp)
    80001700:	f44e                	sd	s3,40(sp)
    80001702:	f052                	sd	s4,32(sp)
    80001704:	ec56                	sd	s5,24(sp)
    80001706:	e85a                	sd	s6,16(sp)
    80001708:	e45e                	sd	s7,8(sp)
    8000170a:	e062                	sd	s8,0(sp)
    8000170c:	0880                	addi	s0,sp,80
    8000170e:	8b2a                	mv	s6,a0
    80001710:	8a2e                	mv	s4,a1
    80001712:	8c32                	mv	s8,a2
    80001714:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001716:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001718:	6a85                	lui	s5,0x1
    8000171a:	a01d                	j	80001740 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171c:	018505b3          	add	a1,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	412585b3          	sub	a1,a1,s2
    80001728:	8552                	mv	a0,s4
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	604080e7          	jalr	1540(ra) # 80000d2e <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001736:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	914080e7          	jalr	-1772(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f2e3          	bgeu	s3,s1,8000171c <copyin+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	bf7d                	j	8000171c <copyin+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyin+0x76>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001782:	c6c5                	beqz	a3,8000182a <copyinstr+0xa8>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	0880                	addi	s0,sp,80
    8000179a:	8a2a                	mv	s4,a0
    8000179c:	8b2e                	mv	s6,a1
    8000179e:	8bb2                	mv	s7,a2
    800017a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a4:	6985                	lui	s3,0x1
    800017a6:	a035                	j	800017d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ae:	0017b793          	seqz	a5,a5
    800017b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
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
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800017cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d0:	c8a9                	beqz	s1,80001822 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d6:	85ca                	mv	a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	882080e7          	jalr	-1918(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e2:	c131                	beqz	a0,80001826 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017e4:	41790833          	sub	a6,s2,s7
    800017e8:	984e                	add	a6,a6,s3
    if(n > max)
    800017ea:	0104f363          	bgeu	s1,a6,800017f0 <copyinstr+0x6e>
    800017ee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f0:	955e                	add	a0,a0,s7
    800017f2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f6:	fc080be3          	beqz	a6,800017cc <copyinstr+0x4a>
    800017fa:	985a                	add	a6,a6,s6
    800017fc:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fe:	41650633          	sub	a2,a0,s6
    80001802:	14fd                	addi	s1,s1,-1
    80001804:	9b26                	add	s6,s6,s1
    80001806:	00f60733          	add	a4,a2,a5
    8000180a:	00074703          	lbu	a4,0(a4)
    8000180e:	df49                	beqz	a4,800017a8 <copyinstr+0x26>
        *dst = *p;
    80001810:	00e78023          	sb	a4,0(a5)
      --max;
    80001814:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001818:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181a:	ff0796e3          	bne	a5,a6,80001806 <copyinstr+0x84>
      dst++;
    8000181e:	8b42                	mv	s6,a6
    80001820:	b775                	j	800017cc <copyinstr+0x4a>
    80001822:	4781                	li	a5,0
    80001824:	b769                	j	800017ae <copyinstr+0x2c>
      return -1;
    80001826:	557d                	li	a0,-1
    80001828:	b779                	j	800017b6 <copyinstr+0x34>
  int got_null = 0;
    8000182a:	4781                	li	a5,0
  if(got_null){
    8000182c:	0017b793          	seqz	a5,a5
    80001830:	40f00533          	neg	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	74448493          	addi	s1,s1,1860 # 80010f90 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	32aa0a13          	addi	s4,s4,810 # 80017b90 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8591                	srai	a1,a1,0x4
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	1b048493          	addi	s1,s1,432
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7a080e7          	jalr	-902(ra) # 8000053e <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	27850513          	addi	a0,a0,632 # 80010b60 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	27850513          	addi	a0,a0,632 # 80010b78 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	68048493          	addi	s1,s1,1664 # 80010f90 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00016997          	auipc	s3,0x16
    80001936:	25e98993          	addi	s3,s3,606 # 80017b90 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8791                	srai	a5,a5,0x4
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	1b048493          	addi	s1,s1,432
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	1f450513          	addi	a0,a0,500 # 80010b90 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	19c70713          	addi	a4,a4,412 # 80010b60 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e747a783          	lw	a5,-396(a5) # 80008870 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	e38080e7          	jalr	-456(ra) # 8000283e <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407ad23          	sw	zero,-422(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	da6080e7          	jalr	-602(ra) # 800037c6 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	12a90913          	addi	s2,s2,298 # 80010b60 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e2c78793          	addi	a5,a5,-468 # 80008874 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a52080e7          	jalr	-1454(ra) # 8000152c <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2c080e7          	jalr	-1492(ra) # 8000152c <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e2080e7          	jalr	-1566(ra) # 8000152c <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7c080e7          	jalr	-388(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3ce48493          	addi	s1,s1,974 # 80010f90 <proc>
    80001bca:	00016917          	auipc	s2,0x16
    80001bce:	fc690913          	addi	s2,s2,-58 # 80017b90 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	1b048493          	addi	s1,s1,432
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a09d                	j	80001c5a <allocproc+0xa4>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	cd21                	beqz	a0,80001c68 <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c20:	c125                	beqz	a0,80001c80 <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c46:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c4a:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c4e:	00007797          	auipc	a5,0x7
    80001c52:	ca27a783          	lw	a5,-862(a5) # 800088f0 <ticks>
    80001c56:	16f4a623          	sw	a5,364(s1)
}
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	60e2                	ld	ra,24(sp)
    80001c5e:	6442                	ld	s0,16(sp)
    80001c60:	64a2                	ld	s1,8(sp)
    80001c62:	6902                	ld	s2,0(sp)
    80001c64:	6105                	addi	sp,sp,32
    80001c66:	8082                	ret
    freeproc(p);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	00000097          	auipc	ra,0x0
    80001c6e:	ef4080e7          	jalr	-268(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c72:	8526                	mv	a0,s1
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	016080e7          	jalr	22(ra) # 80000c8a <release>
    return 0;
    80001c7c:	84ca                	mv	s1,s2
    80001c7e:	bff1                	j	80001c5a <allocproc+0xa4>
    freeproc(p);
    80001c80:	8526                	mv	a0,s1
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	edc080e7          	jalr	-292(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	ffe080e7          	jalr	-2(ra) # 80000c8a <release>
    return 0;
    80001c94:	84ca                	mv	s1,s2
    80001c96:	b7d1                	j	80001c5a <allocproc+0xa4>

0000000080001c98 <userinit>:
{
    80001c98:	1101                	addi	sp,sp,-32
    80001c9a:	ec06                	sd	ra,24(sp)
    80001c9c:	e822                	sd	s0,16(sp)
    80001c9e:	e426                	sd	s1,8(sp)
    80001ca0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	f14080e7          	jalr	-236(ra) # 80001bb6 <allocproc>
    80001caa:	84aa                	mv	s1,a0
  initproc = p;
    80001cac:	00007797          	auipc	a5,0x7
    80001cb0:	c2a7be23          	sd	a0,-964(a5) # 800088e8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cb4:	03400613          	li	a2,52
    80001cb8:	00007597          	auipc	a1,0x7
    80001cbc:	bc858593          	addi	a1,a1,-1080 # 80008880 <initcode>
    80001cc0:	6928                	ld	a0,80(a0)
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	694080e7          	jalr	1684(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cca:	6785                	lui	a5,0x1
    80001ccc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cce:	6cb8                	ld	a4,88(s1)
    80001cd0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cd4:	6cb8                	ld	a4,88(s1)
    80001cd6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd8:	4641                	li	a2,16
    80001cda:	00006597          	auipc	a1,0x6
    80001cde:	52658593          	addi	a1,a1,1318 # 80008200 <digits+0x1c0>
    80001ce2:	15848513          	addi	a0,s1,344
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	136080e7          	jalr	310(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cee:	00006517          	auipc	a0,0x6
    80001cf2:	52250513          	addi	a0,a0,1314 # 80008210 <digits+0x1d0>
    80001cf6:	00002097          	auipc	ra,0x2
    80001cfa:	4f2080e7          	jalr	1266(ra) # 800041e8 <namei>
    80001cfe:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d02:	478d                	li	a5,3
    80001d04:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	f82080e7          	jalr	-126(ra) # 80000c8a <release>
}
    80001d10:	60e2                	ld	ra,24(sp)
    80001d12:	6442                	ld	s0,16(sp)
    80001d14:	64a2                	ld	s1,8(sp)
    80001d16:	6105                	addi	sp,sp,32
    80001d18:	8082                	ret

0000000080001d1a <growproc>:
{
    80001d1a:	1101                	addi	sp,sp,-32
    80001d1c:	ec06                	sd	ra,24(sp)
    80001d1e:	e822                	sd	s0,16(sp)
    80001d20:	e426                	sd	s1,8(sp)
    80001d22:	e04a                	sd	s2,0(sp)
    80001d24:	1000                	addi	s0,sp,32
    80001d26:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	c84080e7          	jalr	-892(ra) # 800019ac <myproc>
    80001d30:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d32:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d34:	01204c63          	bgtz	s2,80001d4c <growproc+0x32>
  else if (n < 0)
    80001d38:	02094663          	bltz	s2,80001d64 <growproc+0x4a>
  p->sz = sz;
    80001d3c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d3e:	4501                	li	a0,0
}
    80001d40:	60e2                	ld	ra,24(sp)
    80001d42:	6442                	ld	s0,16(sp)
    80001d44:	64a2                	ld	s1,8(sp)
    80001d46:	6902                	ld	s2,0(sp)
    80001d48:	6105                	addi	sp,sp,32
    80001d4a:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d4c:	4691                	li	a3,4
    80001d4e:	00b90633          	add	a2,s2,a1
    80001d52:	6928                	ld	a0,80(a0)
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	6bc080e7          	jalr	1724(ra) # 80001410 <uvmalloc>
    80001d5c:	85aa                	mv	a1,a0
    80001d5e:	fd79                	bnez	a0,80001d3c <growproc+0x22>
      return -1;
    80001d60:	557d                	li	a0,-1
    80001d62:	bff9                	j	80001d40 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d64:	00b90633          	add	a2,s2,a1
    80001d68:	6928                	ld	a0,80(a0)
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	65e080e7          	jalr	1630(ra) # 800013c8 <uvmdealloc>
    80001d72:	85aa                	mv	a1,a0
    80001d74:	b7e1                	j	80001d3c <growproc+0x22>

0000000080001d76 <fork>:
{
    80001d76:	7139                	addi	sp,sp,-64
    80001d78:	fc06                	sd	ra,56(sp)
    80001d7a:	f822                	sd	s0,48(sp)
    80001d7c:	f426                	sd	s1,40(sp)
    80001d7e:	f04a                	sd	s2,32(sp)
    80001d80:	ec4e                	sd	s3,24(sp)
    80001d82:	e852                	sd	s4,16(sp)
    80001d84:	e456                	sd	s5,8(sp)
    80001d86:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	c24080e7          	jalr	-988(ra) # 800019ac <myproc>
    80001d90:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	e24080e7          	jalr	-476(ra) # 80001bb6 <allocproc>
    80001d9a:	10050c63          	beqz	a0,80001eb2 <fork+0x13c>
    80001d9e:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001da0:	048ab603          	ld	a2,72(s5)
    80001da4:	692c                	ld	a1,80(a0)
    80001da6:	050ab503          	ld	a0,80(s5)
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	7ba080e7          	jalr	1978(ra) # 80001564 <uvmcopy>
    80001db2:	04054863          	bltz	a0,80001e02 <fork+0x8c>
  np->sz = p->sz;
    80001db6:	048ab783          	ld	a5,72(s5)
    80001dba:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dbe:	058ab683          	ld	a3,88(s5)
    80001dc2:	87b6                	mv	a5,a3
    80001dc4:	058a3703          	ld	a4,88(s4)
    80001dc8:	12068693          	addi	a3,a3,288
    80001dcc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd0:	6788                	ld	a0,8(a5)
    80001dd2:	6b8c                	ld	a1,16(a5)
    80001dd4:	6f90                	ld	a2,24(a5)
    80001dd6:	01073023          	sd	a6,0(a4)
    80001dda:	e708                	sd	a0,8(a4)
    80001ddc:	eb0c                	sd	a1,16(a4)
    80001dde:	ef10                	sd	a2,24(a4)
    80001de0:	02078793          	addi	a5,a5,32
    80001de4:	02070713          	addi	a4,a4,32
    80001de8:	fed792e3          	bne	a5,a3,80001dcc <fork+0x56>
  np->trapframe->a0 = 0;
    80001dec:	058a3783          	ld	a5,88(s4)
    80001df0:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001df4:	0d0a8493          	addi	s1,s5,208
    80001df8:	0d0a0913          	addi	s2,s4,208
    80001dfc:	150a8993          	addi	s3,s5,336
    80001e00:	a00d                	j	80001e22 <fork+0xac>
    freeproc(np);
    80001e02:	8552                	mv	a0,s4
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	d5a080e7          	jalr	-678(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e0c:	8552                	mv	a0,s4
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	e7c080e7          	jalr	-388(ra) # 80000c8a <release>
    return -1;
    80001e16:	597d                	li	s2,-1
    80001e18:	a059                	j	80001e9e <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e1a:	04a1                	addi	s1,s1,8
    80001e1c:	0921                	addi	s2,s2,8
    80001e1e:	01348b63          	beq	s1,s3,80001e34 <fork+0xbe>
    if (p->ofile[i])
    80001e22:	6088                	ld	a0,0(s1)
    80001e24:	d97d                	beqz	a0,80001e1a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e26:	00003097          	auipc	ra,0x3
    80001e2a:	a58080e7          	jalr	-1448(ra) # 8000487e <filedup>
    80001e2e:	00a93023          	sd	a0,0(s2)
    80001e32:	b7e5                	j	80001e1a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e34:	150ab503          	ld	a0,336(s5)
    80001e38:	00002097          	auipc	ra,0x2
    80001e3c:	bcc080e7          	jalr	-1076(ra) # 80003a04 <idup>
    80001e40:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e44:	4641                	li	a2,16
    80001e46:	158a8593          	addi	a1,s5,344
    80001e4a:	158a0513          	addi	a0,s4,344
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	fce080e7          	jalr	-50(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e56:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e5a:	8552                	mv	a0,s4
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	e2e080e7          	jalr	-466(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e64:	0000f497          	auipc	s1,0xf
    80001e68:	d1448493          	addi	s1,s1,-748 # 80010b78 <wait_lock>
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	d68080e7          	jalr	-664(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e76:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	e0e080e7          	jalr	-498(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e84:	8552                	mv	a0,s4
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	d50080e7          	jalr	-688(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e8e:	478d                	li	a5,3
    80001e90:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e94:	8552                	mv	a0,s4
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	df4080e7          	jalr	-524(ra) # 80000c8a <release>
}
    80001e9e:	854a                	mv	a0,s2
    80001ea0:	70e2                	ld	ra,56(sp)
    80001ea2:	7442                	ld	s0,48(sp)
    80001ea4:	74a2                	ld	s1,40(sp)
    80001ea6:	7902                	ld	s2,32(sp)
    80001ea8:	69e2                	ld	s3,24(sp)
    80001eaa:	6a42                	ld	s4,16(sp)
    80001eac:	6aa2                	ld	s5,8(sp)
    80001eae:	6121                	addi	sp,sp,64
    80001eb0:	8082                	ret
    return -1;
    80001eb2:	597d                	li	s2,-1
    80001eb4:	b7ed                	j	80001e9e <fork+0x128>

0000000080001eb6 <scheduler>:
{
    80001eb6:	7139                	addi	sp,sp,-64
    80001eb8:	fc06                	sd	ra,56(sp)
    80001eba:	f822                	sd	s0,48(sp)
    80001ebc:	f426                	sd	s1,40(sp)
    80001ebe:	f04a                	sd	s2,32(sp)
    80001ec0:	ec4e                	sd	s3,24(sp)
    80001ec2:	e852                	sd	s4,16(sp)
    80001ec4:	e456                	sd	s5,8(sp)
    80001ec6:	e05a                	sd	s6,0(sp)
    80001ec8:	0080                	addi	s0,sp,64
    80001eca:	8792                	mv	a5,tp
  int id = r_tp();
    80001ecc:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ece:	00779a93          	slli	s5,a5,0x7
    80001ed2:	0000f717          	auipc	a4,0xf
    80001ed6:	c8e70713          	addi	a4,a4,-882 # 80010b60 <pid_lock>
    80001eda:	9756                	add	a4,a4,s5
    80001edc:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ee0:	0000f717          	auipc	a4,0xf
    80001ee4:	cb870713          	addi	a4,a4,-840 # 80010b98 <cpus+0x8>
    80001ee8:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001eea:	498d                	li	s3,3
        p->state = RUNNING;
    80001eec:	4b11                	li	s6,4
        c->proc = p;
    80001eee:	079e                	slli	a5,a5,0x7
    80001ef0:	0000fa17          	auipc	s4,0xf
    80001ef4:	c70a0a13          	addi	s4,s4,-912 # 80010b60 <pid_lock>
    80001ef8:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001efa:	00016917          	auipc	s2,0x16
    80001efe:	c9690913          	addi	s2,s2,-874 # 80017b90 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f02:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f06:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f0a:	10079073          	csrw	sstatus,a5
    80001f0e:	0000f497          	auipc	s1,0xf
    80001f12:	08248493          	addi	s1,s1,130 # 80010f90 <proc>
    80001f16:	a811                	j	80001f2a <scheduler+0x74>
      release(&p->lock);
    80001f18:	8526                	mv	a0,s1
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	d70080e7          	jalr	-656(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f22:	1b048493          	addi	s1,s1,432
    80001f26:	fd248ee3          	beq	s1,s2,80001f02 <scheduler+0x4c>
      acquire(&p->lock);
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	caa080e7          	jalr	-854(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001f34:	4c9c                	lw	a5,24(s1)
    80001f36:	ff3791e3          	bne	a5,s3,80001f18 <scheduler+0x62>
        p->state = RUNNING;
    80001f3a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f3e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f42:	06048593          	addi	a1,s1,96
    80001f46:	8556                	mv	a0,s5
    80001f48:	00001097          	auipc	ra,0x1
    80001f4c:	84c080e7          	jalr	-1972(ra) # 80002794 <swtch>
        c->proc = 0;
    80001f50:	020a3823          	sd	zero,48(s4)
    80001f54:	b7d1                	j	80001f18 <scheduler+0x62>

0000000080001f56 <sched>:
{
    80001f56:	7179                	addi	sp,sp,-48
    80001f58:	f406                	sd	ra,40(sp)
    80001f5a:	f022                	sd	s0,32(sp)
    80001f5c:	ec26                	sd	s1,24(sp)
    80001f5e:	e84a                	sd	s2,16(sp)
    80001f60:	e44e                	sd	s3,8(sp)
    80001f62:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f64:	00000097          	auipc	ra,0x0
    80001f68:	a48080e7          	jalr	-1464(ra) # 800019ac <myproc>
    80001f6c:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	bee080e7          	jalr	-1042(ra) # 80000b5c <holding>
    80001f76:	c93d                	beqz	a0,80001fec <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f78:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f7a:	2781                	sext.w	a5,a5
    80001f7c:	079e                	slli	a5,a5,0x7
    80001f7e:	0000f717          	auipc	a4,0xf
    80001f82:	be270713          	addi	a4,a4,-1054 # 80010b60 <pid_lock>
    80001f86:	97ba                	add	a5,a5,a4
    80001f88:	0a87a703          	lw	a4,168(a5)
    80001f8c:	4785                	li	a5,1
    80001f8e:	06f71763          	bne	a4,a5,80001ffc <sched+0xa6>
  if (p->state == RUNNING)
    80001f92:	4c98                	lw	a4,24(s1)
    80001f94:	4791                	li	a5,4
    80001f96:	06f70b63          	beq	a4,a5,8000200c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f9a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f9e:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001fa0:	efb5                	bnez	a5,8000201c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fa4:	0000f917          	auipc	s2,0xf
    80001fa8:	bbc90913          	addi	s2,s2,-1092 # 80010b60 <pid_lock>
    80001fac:	2781                	sext.w	a5,a5
    80001fae:	079e                	slli	a5,a5,0x7
    80001fb0:	97ca                	add	a5,a5,s2
    80001fb2:	0ac7a983          	lw	s3,172(a5)
    80001fb6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fb8:	2781                	sext.w	a5,a5
    80001fba:	079e                	slli	a5,a5,0x7
    80001fbc:	0000f597          	auipc	a1,0xf
    80001fc0:	bdc58593          	addi	a1,a1,-1060 # 80010b98 <cpus+0x8>
    80001fc4:	95be                	add	a1,a1,a5
    80001fc6:	06048513          	addi	a0,s1,96
    80001fca:	00000097          	auipc	ra,0x0
    80001fce:	7ca080e7          	jalr	1994(ra) # 80002794 <swtch>
    80001fd2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fd4:	2781                	sext.w	a5,a5
    80001fd6:	079e                	slli	a5,a5,0x7
    80001fd8:	97ca                	add	a5,a5,s2
    80001fda:	0b37a623          	sw	s3,172(a5)
}
    80001fde:	70a2                	ld	ra,40(sp)
    80001fe0:	7402                	ld	s0,32(sp)
    80001fe2:	64e2                	ld	s1,24(sp)
    80001fe4:	6942                	ld	s2,16(sp)
    80001fe6:	69a2                	ld	s3,8(sp)
    80001fe8:	6145                	addi	sp,sp,48
    80001fea:	8082                	ret
    panic("sched p->lock");
    80001fec:	00006517          	auipc	a0,0x6
    80001ff0:	22c50513          	addi	a0,a0,556 # 80008218 <digits+0x1d8>
    80001ff4:	ffffe097          	auipc	ra,0xffffe
    80001ff8:	54a080e7          	jalr	1354(ra) # 8000053e <panic>
    panic("sched locks");
    80001ffc:	00006517          	auipc	a0,0x6
    80002000:	22c50513          	addi	a0,a0,556 # 80008228 <digits+0x1e8>
    80002004:	ffffe097          	auipc	ra,0xffffe
    80002008:	53a080e7          	jalr	1338(ra) # 8000053e <panic>
    panic("sched running");
    8000200c:	00006517          	auipc	a0,0x6
    80002010:	22c50513          	addi	a0,a0,556 # 80008238 <digits+0x1f8>
    80002014:	ffffe097          	auipc	ra,0xffffe
    80002018:	52a080e7          	jalr	1322(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000201c:	00006517          	auipc	a0,0x6
    80002020:	22c50513          	addi	a0,a0,556 # 80008248 <digits+0x208>
    80002024:	ffffe097          	auipc	ra,0xffffe
    80002028:	51a080e7          	jalr	1306(ra) # 8000053e <panic>

000000008000202c <yield>:
{
    8000202c:	1101                	addi	sp,sp,-32
    8000202e:	ec06                	sd	ra,24(sp)
    80002030:	e822                	sd	s0,16(sp)
    80002032:	e426                	sd	s1,8(sp)
    80002034:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002036:	00000097          	auipc	ra,0x0
    8000203a:	976080e7          	jalr	-1674(ra) # 800019ac <myproc>
    8000203e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002040:	fffff097          	auipc	ra,0xfffff
    80002044:	b96080e7          	jalr	-1130(ra) # 80000bd6 <acquire>
    p->state = RUNNABLE;
    80002048:	478d                	li	a5,3
    8000204a:	cc9c                	sw	a5,24(s1)
  sched();
    8000204c:	00000097          	auipc	ra,0x0
    80002050:	f0a080e7          	jalr	-246(ra) # 80001f56 <sched>
  release(&p->lock);
    80002054:	8526                	mv	a0,s1
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	c34080e7          	jalr	-972(ra) # 80000c8a <release>
}
    8000205e:	60e2                	ld	ra,24(sp)
    80002060:	6442                	ld	s0,16(sp)
    80002062:	64a2                	ld	s1,8(sp)
    80002064:	6105                	addi	sp,sp,32
    80002066:	8082                	ret

0000000080002068 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002068:	7179                	addi	sp,sp,-48
    8000206a:	f406                	sd	ra,40(sp)
    8000206c:	f022                	sd	s0,32(sp)
    8000206e:	ec26                	sd	s1,24(sp)
    80002070:	e84a                	sd	s2,16(sp)
    80002072:	e44e                	sd	s3,8(sp)
    80002074:	1800                	addi	s0,sp,48
    80002076:	89aa                	mv	s3,a0
    80002078:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000207a:	00000097          	auipc	ra,0x0
    8000207e:	932080e7          	jalr	-1742(ra) # 800019ac <myproc>
    80002082:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	b52080e7          	jalr	-1198(ra) # 80000bd6 <acquire>
  release(lk);
    8000208c:	854a                	mv	a0,s2
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	bfc080e7          	jalr	-1028(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002096:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000209a:	4789                	li	a5,2
    8000209c:	cc9c                	sw	a5,24(s1)

  sched();
    8000209e:	00000097          	auipc	ra,0x0
    800020a2:	eb8080e7          	jalr	-328(ra) # 80001f56 <sched>

  // Tidy up.
  p->chan = 0;
    800020a6:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020aa:	8526                	mv	a0,s1
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	bde080e7          	jalr	-1058(ra) # 80000c8a <release>
  acquire(lk);
    800020b4:	854a                	mv	a0,s2
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	b20080e7          	jalr	-1248(ra) # 80000bd6 <acquire>
}
    800020be:	70a2                	ld	ra,40(sp)
    800020c0:	7402                	ld	s0,32(sp)
    800020c2:	64e2                	ld	s1,24(sp)
    800020c4:	6942                	ld	s2,16(sp)
    800020c6:	69a2                	ld	s3,8(sp)
    800020c8:	6145                	addi	sp,sp,48
    800020ca:	8082                	ret

00000000800020cc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800020cc:	7139                	addi	sp,sp,-64
    800020ce:	fc06                	sd	ra,56(sp)
    800020d0:	f822                	sd	s0,48(sp)
    800020d2:	f426                	sd	s1,40(sp)
    800020d4:	f04a                	sd	s2,32(sp)
    800020d6:	ec4e                	sd	s3,24(sp)
    800020d8:	e852                	sd	s4,16(sp)
    800020da:	e456                	sd	s5,8(sp)
    800020dc:	0080                	addi	s0,sp,64
    800020de:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800020e0:	0000f497          	auipc	s1,0xf
    800020e4:	eb048493          	addi	s1,s1,-336 # 80010f90 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800020e8:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800020ea:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800020ec:	00016917          	auipc	s2,0x16
    800020f0:	aa490913          	addi	s2,s2,-1372 # 80017b90 <tickslock>
    800020f4:	a811                	j	80002108 <wakeup+0x3c>
      }
      release(&p->lock);
    800020f6:	8526                	mv	a0,s1
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	b92080e7          	jalr	-1134(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002100:	1b048493          	addi	s1,s1,432
    80002104:	03248663          	beq	s1,s2,80002130 <wakeup+0x64>
    if (p != myproc())
    80002108:	00000097          	auipc	ra,0x0
    8000210c:	8a4080e7          	jalr	-1884(ra) # 800019ac <myproc>
    80002110:	fea488e3          	beq	s1,a0,80002100 <wakeup+0x34>
      acquire(&p->lock);
    80002114:	8526                	mv	a0,s1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	ac0080e7          	jalr	-1344(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000211e:	4c9c                	lw	a5,24(s1)
    80002120:	fd379be3          	bne	a5,s3,800020f6 <wakeup+0x2a>
    80002124:	709c                	ld	a5,32(s1)
    80002126:	fd4798e3          	bne	a5,s4,800020f6 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000212a:	0154ac23          	sw	s5,24(s1)
    8000212e:	b7e1                	j	800020f6 <wakeup+0x2a>
    }
  }
}
    80002130:	70e2                	ld	ra,56(sp)
    80002132:	7442                	ld	s0,48(sp)
    80002134:	74a2                	ld	s1,40(sp)
    80002136:	7902                	ld	s2,32(sp)
    80002138:	69e2                	ld	s3,24(sp)
    8000213a:	6a42                	ld	s4,16(sp)
    8000213c:	6aa2                	ld	s5,8(sp)
    8000213e:	6121                	addi	sp,sp,64
    80002140:	8082                	ret

0000000080002142 <reparent>:
{
    80002142:	7179                	addi	sp,sp,-48
    80002144:	f406                	sd	ra,40(sp)
    80002146:	f022                	sd	s0,32(sp)
    80002148:	ec26                	sd	s1,24(sp)
    8000214a:	e84a                	sd	s2,16(sp)
    8000214c:	e44e                	sd	s3,8(sp)
    8000214e:	e052                	sd	s4,0(sp)
    80002150:	1800                	addi	s0,sp,48
    80002152:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002154:	0000f497          	auipc	s1,0xf
    80002158:	e3c48493          	addi	s1,s1,-452 # 80010f90 <proc>
      pp->parent = initproc;
    8000215c:	00006a17          	auipc	s4,0x6
    80002160:	78ca0a13          	addi	s4,s4,1932 # 800088e8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002164:	00016997          	auipc	s3,0x16
    80002168:	a2c98993          	addi	s3,s3,-1492 # 80017b90 <tickslock>
    8000216c:	a029                	j	80002176 <reparent+0x34>
    8000216e:	1b048493          	addi	s1,s1,432
    80002172:	01348d63          	beq	s1,s3,8000218c <reparent+0x4a>
    if (pp->parent == p)
    80002176:	7c9c                	ld	a5,56(s1)
    80002178:	ff279be3          	bne	a5,s2,8000216e <reparent+0x2c>
      pp->parent = initproc;
    8000217c:	000a3503          	ld	a0,0(s4)
    80002180:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002182:	00000097          	auipc	ra,0x0
    80002186:	f4a080e7          	jalr	-182(ra) # 800020cc <wakeup>
    8000218a:	b7d5                	j	8000216e <reparent+0x2c>
}
    8000218c:	70a2                	ld	ra,40(sp)
    8000218e:	7402                	ld	s0,32(sp)
    80002190:	64e2                	ld	s1,24(sp)
    80002192:	6942                	ld	s2,16(sp)
    80002194:	69a2                	ld	s3,8(sp)
    80002196:	6a02                	ld	s4,0(sp)
    80002198:	6145                	addi	sp,sp,48
    8000219a:	8082                	ret

000000008000219c <exit>:
{
    8000219c:	7179                	addi	sp,sp,-48
    8000219e:	f406                	sd	ra,40(sp)
    800021a0:	f022                	sd	s0,32(sp)
    800021a2:	ec26                	sd	s1,24(sp)
    800021a4:	e84a                	sd	s2,16(sp)
    800021a6:	e44e                	sd	s3,8(sp)
    800021a8:	e052                	sd	s4,0(sp)
    800021aa:	1800                	addi	s0,sp,48
    800021ac:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	7fe080e7          	jalr	2046(ra) # 800019ac <myproc>
    800021b6:	89aa                	mv	s3,a0
  if (p == initproc)
    800021b8:	00006797          	auipc	a5,0x6
    800021bc:	7307b783          	ld	a5,1840(a5) # 800088e8 <initproc>
    800021c0:	0d050493          	addi	s1,a0,208
    800021c4:	15050913          	addi	s2,a0,336
    800021c8:	02a79363          	bne	a5,a0,800021ee <exit+0x52>
    panic("init exiting");
    800021cc:	00006517          	auipc	a0,0x6
    800021d0:	09450513          	addi	a0,a0,148 # 80008260 <digits+0x220>
    800021d4:	ffffe097          	auipc	ra,0xffffe
    800021d8:	36a080e7          	jalr	874(ra) # 8000053e <panic>
      fileclose(f);
    800021dc:	00002097          	auipc	ra,0x2
    800021e0:	6f4080e7          	jalr	1780(ra) # 800048d0 <fileclose>
      p->ofile[fd] = 0;
    800021e4:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800021e8:	04a1                	addi	s1,s1,8
    800021ea:	01248563          	beq	s1,s2,800021f4 <exit+0x58>
    if (p->ofile[fd])
    800021ee:	6088                	ld	a0,0(s1)
    800021f0:	f575                	bnez	a0,800021dc <exit+0x40>
    800021f2:	bfdd                	j	800021e8 <exit+0x4c>
  begin_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	210080e7          	jalr	528(ra) # 80004404 <begin_op>
  iput(p->cwd);
    800021fc:	1509b503          	ld	a0,336(s3)
    80002200:	00002097          	auipc	ra,0x2
    80002204:	9fc080e7          	jalr	-1540(ra) # 80003bfc <iput>
  end_op();
    80002208:	00002097          	auipc	ra,0x2
    8000220c:	27c080e7          	jalr	636(ra) # 80004484 <end_op>
  p->cwd = 0;
    80002210:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002214:	0000f497          	auipc	s1,0xf
    80002218:	96448493          	addi	s1,s1,-1692 # 80010b78 <wait_lock>
    8000221c:	8526                	mv	a0,s1
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	9b8080e7          	jalr	-1608(ra) # 80000bd6 <acquire>
  reparent(p);
    80002226:	854e                	mv	a0,s3
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	f1a080e7          	jalr	-230(ra) # 80002142 <reparent>
  wakeup(p->parent);
    80002230:	0389b503          	ld	a0,56(s3)
    80002234:	00000097          	auipc	ra,0x0
    80002238:	e98080e7          	jalr	-360(ra) # 800020cc <wakeup>
  acquire(&p->lock);
    8000223c:	854e                	mv	a0,s3
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	998080e7          	jalr	-1640(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002246:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000224a:	4795                	li	a5,5
    8000224c:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002250:	00006797          	auipc	a5,0x6
    80002254:	6a07a783          	lw	a5,1696(a5) # 800088f0 <ticks>
    80002258:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    8000225c:	8526                	mv	a0,s1
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	a2c080e7          	jalr	-1492(ra) # 80000c8a <release>
  sched();
    80002266:	00000097          	auipc	ra,0x0
    8000226a:	cf0080e7          	jalr	-784(ra) # 80001f56 <sched>
  panic("zombie exit");
    8000226e:	00006517          	auipc	a0,0x6
    80002272:	00250513          	addi	a0,a0,2 # 80008270 <digits+0x230>
    80002276:	ffffe097          	auipc	ra,0xffffe
    8000227a:	2c8080e7          	jalr	712(ra) # 8000053e <panic>

000000008000227e <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).id
int kill(int pid)
{
    8000227e:	7179                	addi	sp,sp,-48
    80002280:	f406                	sd	ra,40(sp)
    80002282:	f022                	sd	s0,32(sp)
    80002284:	ec26                	sd	s1,24(sp)
    80002286:	e84a                	sd	s2,16(sp)
    80002288:	e44e                	sd	s3,8(sp)
    8000228a:	1800                	addi	s0,sp,48
    8000228c:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000228e:	0000f497          	auipc	s1,0xf
    80002292:	d0248493          	addi	s1,s1,-766 # 80010f90 <proc>
    80002296:	00016997          	auipc	s3,0x16
    8000229a:	8fa98993          	addi	s3,s3,-1798 # 80017b90 <tickslock>
  {
    acquire(&p->lock);
    8000229e:	8526                	mv	a0,s1
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	936080e7          	jalr	-1738(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800022a8:	589c                	lw	a5,48(s1)
    800022aa:	01278d63          	beq	a5,s2,800022c4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022ae:	8526                	mv	a0,s1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	9da080e7          	jalr	-1574(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022b8:	1b048493          	addi	s1,s1,432
    800022bc:	ff3491e3          	bne	s1,s3,8000229e <kill+0x20>
  }
  return -1;
    800022c0:	557d                	li	a0,-1
    800022c2:	a829                	j	800022dc <kill+0x5e>
      p->killed = 1;
    800022c4:	4785                	li	a5,1
    800022c6:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800022c8:	4c98                	lw	a4,24(s1)
    800022ca:	4789                	li	a5,2
    800022cc:	00f70f63          	beq	a4,a5,800022ea <kill+0x6c>
      release(&p->lock);
    800022d0:	8526                	mv	a0,s1
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	9b8080e7          	jalr	-1608(ra) # 80000c8a <release>
      return 0;
    800022da:	4501                	li	a0,0
}
    800022dc:	70a2                	ld	ra,40(sp)
    800022de:	7402                	ld	s0,32(sp)
    800022e0:	64e2                	ld	s1,24(sp)
    800022e2:	6942                	ld	s2,16(sp)
    800022e4:	69a2                	ld	s3,8(sp)
    800022e6:	6145                	addi	sp,sp,48
    800022e8:	8082                	ret
        p->state = RUNNABLE;
    800022ea:	478d                	li	a5,3
    800022ec:	cc9c                	sw	a5,24(s1)
    800022ee:	b7cd                	j	800022d0 <kill+0x52>

00000000800022f0 <setkilled>:

void setkilled(struct proc *p)
{
    800022f0:	1101                	addi	sp,sp,-32
    800022f2:	ec06                	sd	ra,24(sp)
    800022f4:	e822                	sd	s0,16(sp)
    800022f6:	e426                	sd	s1,8(sp)
    800022f8:	1000                	addi	s0,sp,32
    800022fa:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	8da080e7          	jalr	-1830(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002304:	4785                	li	a5,1
    80002306:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002308:	8526                	mv	a0,s1
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	980080e7          	jalr	-1664(ra) # 80000c8a <release>
}
    80002312:	60e2                	ld	ra,24(sp)
    80002314:	6442                	ld	s0,16(sp)
    80002316:	64a2                	ld	s1,8(sp)
    80002318:	6105                	addi	sp,sp,32
    8000231a:	8082                	ret

000000008000231c <killed>:

int killed(struct proc *p)
{
    8000231c:	1101                	addi	sp,sp,-32
    8000231e:	ec06                	sd	ra,24(sp)
    80002320:	e822                	sd	s0,16(sp)
    80002322:	e426                	sd	s1,8(sp)
    80002324:	e04a                	sd	s2,0(sp)
    80002326:	1000                	addi	s0,sp,32
    80002328:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	8ac080e7          	jalr	-1876(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002332:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002336:	8526                	mv	a0,s1
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	952080e7          	jalr	-1710(ra) # 80000c8a <release>
  return k;
}
    80002340:	854a                	mv	a0,s2
    80002342:	60e2                	ld	ra,24(sp)
    80002344:	6442                	ld	s0,16(sp)
    80002346:	64a2                	ld	s1,8(sp)
    80002348:	6902                	ld	s2,0(sp)
    8000234a:	6105                	addi	sp,sp,32
    8000234c:	8082                	ret

000000008000234e <wait>:
{
    8000234e:	715d                	addi	sp,sp,-80
    80002350:	e486                	sd	ra,72(sp)
    80002352:	e0a2                	sd	s0,64(sp)
    80002354:	fc26                	sd	s1,56(sp)
    80002356:	f84a                	sd	s2,48(sp)
    80002358:	f44e                	sd	s3,40(sp)
    8000235a:	f052                	sd	s4,32(sp)
    8000235c:	ec56                	sd	s5,24(sp)
    8000235e:	e85a                	sd	s6,16(sp)
    80002360:	e45e                	sd	s7,8(sp)
    80002362:	e062                	sd	s8,0(sp)
    80002364:	0880                	addi	s0,sp,80
    80002366:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	644080e7          	jalr	1604(ra) # 800019ac <myproc>
    80002370:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002372:	0000f517          	auipc	a0,0xf
    80002376:	80650513          	addi	a0,a0,-2042 # 80010b78 <wait_lock>
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	85c080e7          	jalr	-1956(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002382:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002384:	4a15                	li	s4,5
        havekids = 1;
    80002386:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002388:	00016997          	auipc	s3,0x16
    8000238c:	80898993          	addi	s3,s3,-2040 # 80017b90 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002390:	0000ec17          	auipc	s8,0xe
    80002394:	7e8c0c13          	addi	s8,s8,2024 # 80010b78 <wait_lock>
    havekids = 0;
    80002398:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000239a:	0000f497          	auipc	s1,0xf
    8000239e:	bf648493          	addi	s1,s1,-1034 # 80010f90 <proc>
    800023a2:	a0bd                	j	80002410 <wait+0xc2>
          pid = pp->pid;
    800023a4:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023a8:	000b0e63          	beqz	s6,800023c4 <wait+0x76>
    800023ac:	4691                	li	a3,4
    800023ae:	02c48613          	addi	a2,s1,44
    800023b2:	85da                	mv	a1,s6
    800023b4:	05093503          	ld	a0,80(s2)
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	2b0080e7          	jalr	688(ra) # 80001668 <copyout>
    800023c0:	02054563          	bltz	a0,800023ea <wait+0x9c>
          freeproc(pp);
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	798080e7          	jalr	1944(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	8ba080e7          	jalr	-1862(ra) # 80000c8a <release>
          release(&wait_lock);
    800023d8:	0000e517          	auipc	a0,0xe
    800023dc:	7a050513          	addi	a0,a0,1952 # 80010b78 <wait_lock>
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8aa080e7          	jalr	-1878(ra) # 80000c8a <release>
          return pid;
    800023e8:	a0b5                	j	80002454 <wait+0x106>
            release(&pp->lock);
    800023ea:	8526                	mv	a0,s1
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	89e080e7          	jalr	-1890(ra) # 80000c8a <release>
            release(&wait_lock);
    800023f4:	0000e517          	auipc	a0,0xe
    800023f8:	78450513          	addi	a0,a0,1924 # 80010b78 <wait_lock>
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	88e080e7          	jalr	-1906(ra) # 80000c8a <release>
            return -1;
    80002404:	59fd                	li	s3,-1
    80002406:	a0b9                	j	80002454 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002408:	1b048493          	addi	s1,s1,432
    8000240c:	03348463          	beq	s1,s3,80002434 <wait+0xe6>
      if (pp->parent == p)
    80002410:	7c9c                	ld	a5,56(s1)
    80002412:	ff279be3          	bne	a5,s2,80002408 <wait+0xba>
        acquire(&pp->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	ffffe097          	auipc	ra,0xffffe
    8000241c:	7be080e7          	jalr	1982(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002420:	4c9c                	lw	a5,24(s1)
    80002422:	f94781e3          	beq	a5,s4,800023a4 <wait+0x56>
        release(&pp->lock);
    80002426:	8526                	mv	a0,s1
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	862080e7          	jalr	-1950(ra) # 80000c8a <release>
        havekids = 1;
    80002430:	8756                	mv	a4,s5
    80002432:	bfd9                	j	80002408 <wait+0xba>
    if (!havekids || killed(p))
    80002434:	c719                	beqz	a4,80002442 <wait+0xf4>
    80002436:	854a                	mv	a0,s2
    80002438:	00000097          	auipc	ra,0x0
    8000243c:	ee4080e7          	jalr	-284(ra) # 8000231c <killed>
    80002440:	c51d                	beqz	a0,8000246e <wait+0x120>
      release(&wait_lock);
    80002442:	0000e517          	auipc	a0,0xe
    80002446:	73650513          	addi	a0,a0,1846 # 80010b78 <wait_lock>
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	840080e7          	jalr	-1984(ra) # 80000c8a <release>
      return -1;
    80002452:	59fd                	li	s3,-1
}
    80002454:	854e                	mv	a0,s3
    80002456:	60a6                	ld	ra,72(sp)
    80002458:	6406                	ld	s0,64(sp)
    8000245a:	74e2                	ld	s1,56(sp)
    8000245c:	7942                	ld	s2,48(sp)
    8000245e:	79a2                	ld	s3,40(sp)
    80002460:	7a02                	ld	s4,32(sp)
    80002462:	6ae2                	ld	s5,24(sp)
    80002464:	6b42                	ld	s6,16(sp)
    80002466:	6ba2                	ld	s7,8(sp)
    80002468:	6c02                	ld	s8,0(sp)
    8000246a:	6161                	addi	sp,sp,80
    8000246c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000246e:	85e2                	mv	a1,s8
    80002470:	854a                	mv	a0,s2
    80002472:	00000097          	auipc	ra,0x0
    80002476:	bf6080e7          	jalr	-1034(ra) # 80002068 <sleep>
    havekids = 0;
    8000247a:	bf39                	j	80002398 <wait+0x4a>

000000008000247c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000247c:	7179                	addi	sp,sp,-48
    8000247e:	f406                	sd	ra,40(sp)
    80002480:	f022                	sd	s0,32(sp)
    80002482:	ec26                	sd	s1,24(sp)
    80002484:	e84a                	sd	s2,16(sp)
    80002486:	e44e                	sd	s3,8(sp)
    80002488:	e052                	sd	s4,0(sp)
    8000248a:	1800                	addi	s0,sp,48
    8000248c:	84aa                	mv	s1,a0
    8000248e:	892e                	mv	s2,a1
    80002490:	89b2                	mv	s3,a2
    80002492:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	518080e7          	jalr	1304(ra) # 800019ac <myproc>
  if (user_dst)
    8000249c:	c08d                	beqz	s1,800024be <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000249e:	86d2                	mv	a3,s4
    800024a0:	864e                	mv	a2,s3
    800024a2:	85ca                	mv	a1,s2
    800024a4:	6928                	ld	a0,80(a0)
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	1c2080e7          	jalr	450(ra) # 80001668 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024ae:	70a2                	ld	ra,40(sp)
    800024b0:	7402                	ld	s0,32(sp)
    800024b2:	64e2                	ld	s1,24(sp)
    800024b4:	6942                	ld	s2,16(sp)
    800024b6:	69a2                	ld	s3,8(sp)
    800024b8:	6a02                	ld	s4,0(sp)
    800024ba:	6145                	addi	sp,sp,48
    800024bc:	8082                	ret
    memmove((char *)dst, src, len);
    800024be:	000a061b          	sext.w	a2,s4
    800024c2:	85ce                	mv	a1,s3
    800024c4:	854a                	mv	a0,s2
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	868080e7          	jalr	-1944(ra) # 80000d2e <memmove>
    return 0;
    800024ce:	8526                	mv	a0,s1
    800024d0:	bff9                	j	800024ae <either_copyout+0x32>

00000000800024d2 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024d2:	7179                	addi	sp,sp,-48
    800024d4:	f406                	sd	ra,40(sp)
    800024d6:	f022                	sd	s0,32(sp)
    800024d8:	ec26                	sd	s1,24(sp)
    800024da:	e84a                	sd	s2,16(sp)
    800024dc:	e44e                	sd	s3,8(sp)
    800024de:	e052                	sd	s4,0(sp)
    800024e0:	1800                	addi	s0,sp,48
    800024e2:	892a                	mv	s2,a0
    800024e4:	84ae                	mv	s1,a1
    800024e6:	89b2                	mv	s3,a2
    800024e8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ea:	fffff097          	auipc	ra,0xfffff
    800024ee:	4c2080e7          	jalr	1218(ra) # 800019ac <myproc>
  if (user_src)
    800024f2:	c08d                	beqz	s1,80002514 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800024f4:	86d2                	mv	a3,s4
    800024f6:	864e                	mv	a2,s3
    800024f8:	85ca                	mv	a1,s2
    800024fa:	6928                	ld	a0,80(a0)
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	1f8080e7          	jalr	504(ra) # 800016f4 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002504:	70a2                	ld	ra,40(sp)
    80002506:	7402                	ld	s0,32(sp)
    80002508:	64e2                	ld	s1,24(sp)
    8000250a:	6942                	ld	s2,16(sp)
    8000250c:	69a2                	ld	s3,8(sp)
    8000250e:	6a02                	ld	s4,0(sp)
    80002510:	6145                	addi	sp,sp,48
    80002512:	8082                	ret
    memmove(dst, (char *)src, len);
    80002514:	000a061b          	sext.w	a2,s4
    80002518:	85ce                	mv	a1,s3
    8000251a:	854a                	mv	a0,s2
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	812080e7          	jalr	-2030(ra) # 80000d2e <memmove>
    return 0;
    80002524:	8526                	mv	a0,s1
    80002526:	bff9                	j	80002504 <either_copyin+0x32>

0000000080002528 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002528:	715d                	addi	sp,sp,-80
    8000252a:	e486                	sd	ra,72(sp)
    8000252c:	e0a2                	sd	s0,64(sp)
    8000252e:	fc26                	sd	s1,56(sp)
    80002530:	f84a                	sd	s2,48(sp)
    80002532:	f44e                	sd	s3,40(sp)
    80002534:	f052                	sd	s4,32(sp)
    80002536:	ec56                	sd	s5,24(sp)
    80002538:	e85a                	sd	s6,16(sp)
    8000253a:	e45e                	sd	s7,8(sp)
    8000253c:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000253e:	00006517          	auipc	a0,0x6
    80002542:	b8a50513          	addi	a0,a0,-1142 # 800080c8 <digits+0x88>
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	042080e7          	jalr	66(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000254e:	0000f497          	auipc	s1,0xf
    80002552:	b9a48493          	addi	s1,s1,-1126 # 800110e8 <proc+0x158>
    80002556:	00015917          	auipc	s2,0x15
    8000255a:	79290913          	addi	s2,s2,1938 # 80017ce8 <bcache+0xc0>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000255e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002560:	00006997          	auipc	s3,0x6
    80002564:	d2098993          	addi	s3,s3,-736 # 80008280 <digits+0x240>
    printf("%d %s %s %d %d\n", p->pid, state, p->name, p->qid, ticks - p->stime);
#endif
#ifdef LBS
    printf("%d %s %s %d %d\n", p->pid, state, p->name, p->tickets, ticks - p->start_time);
#endif
    printf("%d %s %s", p->pid, state, p->name);
    80002568:	00006a97          	auipc	s5,0x6
    8000256c:	d20a8a93          	addi	s5,s5,-736 # 80008288 <digits+0x248>
    printf("\n");
    80002570:	00006a17          	auipc	s4,0x6
    80002574:	b58a0a13          	addi	s4,s4,-1192 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002578:	00006b97          	auipc	s7,0x6
    8000257c:	d50b8b93          	addi	s7,s7,-688 # 800082c8 <states.0>
    80002580:	a00d                	j	800025a2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002582:	ed86a583          	lw	a1,-296(a3)
    80002586:	8556                	mv	a0,s5
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	000080e7          	jalr	ra # 80000588 <printf>
    printf("\n");
    80002590:	8552                	mv	a0,s4
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	ff6080e7          	jalr	-10(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000259a:	1b048493          	addi	s1,s1,432
    8000259e:	03248163          	beq	s1,s2,800025c0 <procdump+0x98>
    if (p->state == UNUSED)
    800025a2:	86a6                	mv	a3,s1
    800025a4:	ec04a783          	lw	a5,-320(s1)
    800025a8:	dbed                	beqz	a5,8000259a <procdump+0x72>
      state = "???";
    800025aa:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ac:	fcfb6be3          	bltu	s6,a5,80002582 <procdump+0x5a>
    800025b0:	1782                	slli	a5,a5,0x20
    800025b2:	9381                	srli	a5,a5,0x20
    800025b4:	078e                	slli	a5,a5,0x3
    800025b6:	97de                	add	a5,a5,s7
    800025b8:	6390                	ld	a2,0(a5)
    800025ba:	f661                	bnez	a2,80002582 <procdump+0x5a>
      state = "???";
    800025bc:	864e                	mv	a2,s3
    800025be:	b7d1                	j	80002582 <procdump+0x5a>
  }
}
    800025c0:	60a6                	ld	ra,72(sp)
    800025c2:	6406                	ld	s0,64(sp)
    800025c4:	74e2                	ld	s1,56(sp)
    800025c6:	7942                	ld	s2,48(sp)
    800025c8:	79a2                	ld	s3,40(sp)
    800025ca:	7a02                	ld	s4,32(sp)
    800025cc:	6ae2                	ld	s5,24(sp)
    800025ce:	6b42                	ld	s6,16(sp)
    800025d0:	6ba2                	ld	s7,8(sp)
    800025d2:	6161                	addi	sp,sp,80
    800025d4:	8082                	ret

00000000800025d6 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800025d6:	711d                	addi	sp,sp,-96
    800025d8:	ec86                	sd	ra,88(sp)
    800025da:	e8a2                	sd	s0,80(sp)
    800025dc:	e4a6                	sd	s1,72(sp)
    800025de:	e0ca                	sd	s2,64(sp)
    800025e0:	fc4e                	sd	s3,56(sp)
    800025e2:	f852                	sd	s4,48(sp)
    800025e4:	f456                	sd	s5,40(sp)
    800025e6:	f05a                	sd	s6,32(sp)
    800025e8:	ec5e                	sd	s7,24(sp)
    800025ea:	e862                	sd	s8,16(sp)
    800025ec:	e466                	sd	s9,8(sp)
    800025ee:	e06a                	sd	s10,0(sp)
    800025f0:	1080                	addi	s0,sp,96
    800025f2:	8b2a                	mv	s6,a0
    800025f4:	8bae                	mv	s7,a1
    800025f6:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800025f8:	fffff097          	auipc	ra,0xfffff
    800025fc:	3b4080e7          	jalr	948(ra) # 800019ac <myproc>
    80002600:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002602:	0000e517          	auipc	a0,0xe
    80002606:	57650513          	addi	a0,a0,1398 # 80010b78 <wait_lock>
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	5cc080e7          	jalr	1484(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002612:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002614:	4a15                	li	s4,5
        havekids = 1;
    80002616:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002618:	00015997          	auipc	s3,0x15
    8000261c:	57898993          	addi	s3,s3,1400 # 80017b90 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002620:	0000ed17          	auipc	s10,0xe
    80002624:	558d0d13          	addi	s10,s10,1368 # 80010b78 <wait_lock>
    havekids = 0;
    80002628:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000262a:	0000f497          	auipc	s1,0xf
    8000262e:	96648493          	addi	s1,s1,-1690 # 80010f90 <proc>
    80002632:	a059                	j	800026b8 <waitx+0xe2>
          pid = np->pid;
    80002634:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002638:	1684a703          	lw	a4,360(s1)
    8000263c:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002640:	16c4a783          	lw	a5,364(s1)
    80002644:	9f3d                	addw	a4,a4,a5
    80002646:	1704a783          	lw	a5,368(s1)
    8000264a:	9f99                	subw	a5,a5,a4
    8000264c:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002650:	000b0e63          	beqz	s6,8000266c <waitx+0x96>
    80002654:	4691                	li	a3,4
    80002656:	02c48613          	addi	a2,s1,44
    8000265a:	85da                	mv	a1,s6
    8000265c:	05093503          	ld	a0,80(s2)
    80002660:	fffff097          	auipc	ra,0xfffff
    80002664:	008080e7          	jalr	8(ra) # 80001668 <copyout>
    80002668:	02054563          	bltz	a0,80002692 <waitx+0xbc>
          freeproc(np);
    8000266c:	8526                	mv	a0,s1
    8000266e:	fffff097          	auipc	ra,0xfffff
    80002672:	4f0080e7          	jalr	1264(ra) # 80001b5e <freeproc>
          release(&np->lock);
    80002676:	8526                	mv	a0,s1
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	612080e7          	jalr	1554(ra) # 80000c8a <release>
          release(&wait_lock);
    80002680:	0000e517          	auipc	a0,0xe
    80002684:	4f850513          	addi	a0,a0,1272 # 80010b78 <wait_lock>
    80002688:	ffffe097          	auipc	ra,0xffffe
    8000268c:	602080e7          	jalr	1538(ra) # 80000c8a <release>
          return pid;
    80002690:	a09d                	j	800026f6 <waitx+0x120>
            release(&np->lock);
    80002692:	8526                	mv	a0,s1
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	5f6080e7          	jalr	1526(ra) # 80000c8a <release>
            release(&wait_lock);
    8000269c:	0000e517          	auipc	a0,0xe
    800026a0:	4dc50513          	addi	a0,a0,1244 # 80010b78 <wait_lock>
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	5e6080e7          	jalr	1510(ra) # 80000c8a <release>
            return -1;
    800026ac:	59fd                	li	s3,-1
    800026ae:	a0a1                	j	800026f6 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800026b0:	1b048493          	addi	s1,s1,432
    800026b4:	03348463          	beq	s1,s3,800026dc <waitx+0x106>
      if (np->parent == p)
    800026b8:	7c9c                	ld	a5,56(s1)
    800026ba:	ff279be3          	bne	a5,s2,800026b0 <waitx+0xda>
        acquire(&np->lock);
    800026be:	8526                	mv	a0,s1
    800026c0:	ffffe097          	auipc	ra,0xffffe
    800026c4:	516080e7          	jalr	1302(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    800026c8:	4c9c                	lw	a5,24(s1)
    800026ca:	f74785e3          	beq	a5,s4,80002634 <waitx+0x5e>
        release(&np->lock);
    800026ce:	8526                	mv	a0,s1
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	5ba080e7          	jalr	1466(ra) # 80000c8a <release>
        havekids = 1;
    800026d8:	8756                	mv	a4,s5
    800026da:	bfd9                	j	800026b0 <waitx+0xda>
    if (!havekids || p->killed)
    800026dc:	c701                	beqz	a4,800026e4 <waitx+0x10e>
    800026de:	02892783          	lw	a5,40(s2)
    800026e2:	cb8d                	beqz	a5,80002714 <waitx+0x13e>
      release(&wait_lock);
    800026e4:	0000e517          	auipc	a0,0xe
    800026e8:	49450513          	addi	a0,a0,1172 # 80010b78 <wait_lock>
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	59e080e7          	jalr	1438(ra) # 80000c8a <release>
      return -1;
    800026f4:	59fd                	li	s3,-1
  }
}
    800026f6:	854e                	mv	a0,s3
    800026f8:	60e6                	ld	ra,88(sp)
    800026fa:	6446                	ld	s0,80(sp)
    800026fc:	64a6                	ld	s1,72(sp)
    800026fe:	6906                	ld	s2,64(sp)
    80002700:	79e2                	ld	s3,56(sp)
    80002702:	7a42                	ld	s4,48(sp)
    80002704:	7aa2                	ld	s5,40(sp)
    80002706:	7b02                	ld	s6,32(sp)
    80002708:	6be2                	ld	s7,24(sp)
    8000270a:	6c42                	ld	s8,16(sp)
    8000270c:	6ca2                	ld	s9,8(sp)
    8000270e:	6d02                	ld	s10,0(sp)
    80002710:	6125                	addi	sp,sp,96
    80002712:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002714:	85ea                	mv	a1,s10
    80002716:	854a                	mv	a0,s2
    80002718:	00000097          	auipc	ra,0x0
    8000271c:	950080e7          	jalr	-1712(ra) # 80002068 <sleep>
    havekids = 0;
    80002720:	b721                	j	80002628 <waitx+0x52>

0000000080002722 <update_time>:

void update_time()
{
    80002722:	7179                	addi	sp,sp,-48
    80002724:	f406                	sd	ra,40(sp)
    80002726:	f022                	sd	s0,32(sp)
    80002728:	ec26                	sd	s1,24(sp)
    8000272a:	e84a                	sd	s2,16(sp)
    8000272c:	e44e                	sd	s3,8(sp)
    8000272e:	e052                	sd	s4,0(sp)
    80002730:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002732:	0000f497          	auipc	s1,0xf
    80002736:	85e48493          	addi	s1,s1,-1954 # 80010f90 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    8000273a:	4991                	li	s3,4
      p->rtime++;
#ifdef MLFQ
      p->stime++;
#endif
#ifndef LBS
p->start_time = ticks;
    8000273c:	00006a17          	auipc	s4,0x6
    80002740:	1b4a0a13          	addi	s4,s4,436 # 800088f0 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    80002744:	00015917          	auipc	s2,0x15
    80002748:	44c90913          	addi	s2,s2,1100 # 80017b90 <tickslock>
    8000274c:	a811                	j	80002760 <update_time+0x3e>
    {
#ifdef MLFQ
      p->w_time++;
#endif
    }
    release(&p->lock);
    8000274e:	8526                	mv	a0,s1
    80002750:	ffffe097          	auipc	ra,0xffffe
    80002754:	53a080e7          	jalr	1338(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002758:	1b048493          	addi	s1,s1,432
    8000275c:	03248463          	beq	s1,s2,80002784 <update_time+0x62>
    acquire(&p->lock);
    80002760:	8526                	mv	a0,s1
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	474080e7          	jalr	1140(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    8000276a:	4c9c                	lw	a5,24(s1)
    8000276c:	ff3791e3          	bne	a5,s3,8000274e <update_time+0x2c>
      p->rtime++;
    80002770:	1684a783          	lw	a5,360(s1)
    80002774:	2785                	addiw	a5,a5,1
    80002776:	16f4a423          	sw	a5,360(s1)
p->start_time = ticks;
    8000277a:	000a2783          	lw	a5,0(s4)
    8000277e:	18f4ac23          	sw	a5,408(s1)
    80002782:	b7f1                	j	8000274e <update_time+0x2c>
  }


}
    80002784:	70a2                	ld	ra,40(sp)
    80002786:	7402                	ld	s0,32(sp)
    80002788:	64e2                	ld	s1,24(sp)
    8000278a:	6942                	ld	s2,16(sp)
    8000278c:	69a2                	ld	s3,8(sp)
    8000278e:	6a02                	ld	s4,0(sp)
    80002790:	6145                	addi	sp,sp,48
    80002792:	8082                	ret

0000000080002794 <swtch>:
    80002794:	00153023          	sd	ra,0(a0)
    80002798:	00253423          	sd	sp,8(a0)
    8000279c:	e900                	sd	s0,16(a0)
    8000279e:	ed04                	sd	s1,24(a0)
    800027a0:	03253023          	sd	s2,32(a0)
    800027a4:	03353423          	sd	s3,40(a0)
    800027a8:	03453823          	sd	s4,48(a0)
    800027ac:	03553c23          	sd	s5,56(a0)
    800027b0:	05653023          	sd	s6,64(a0)
    800027b4:	05753423          	sd	s7,72(a0)
    800027b8:	05853823          	sd	s8,80(a0)
    800027bc:	05953c23          	sd	s9,88(a0)
    800027c0:	07a53023          	sd	s10,96(a0)
    800027c4:	07b53423          	sd	s11,104(a0)
    800027c8:	0005b083          	ld	ra,0(a1)
    800027cc:	0085b103          	ld	sp,8(a1)
    800027d0:	6980                	ld	s0,16(a1)
    800027d2:	6d84                	ld	s1,24(a1)
    800027d4:	0205b903          	ld	s2,32(a1)
    800027d8:	0285b983          	ld	s3,40(a1)
    800027dc:	0305ba03          	ld	s4,48(a1)
    800027e0:	0385ba83          	ld	s5,56(a1)
    800027e4:	0405bb03          	ld	s6,64(a1)
    800027e8:	0485bb83          	ld	s7,72(a1)
    800027ec:	0505bc03          	ld	s8,80(a1)
    800027f0:	0585bc83          	ld	s9,88(a1)
    800027f4:	0605bd03          	ld	s10,96(a1)
    800027f8:	0685bd83          	ld	s11,104(a1)
    800027fc:	8082                	ret

00000000800027fe <trapinit>:
  
  priority_queues[queid].Process[NPROC - 1] = 0;
}
#endif
void trapinit(void)
{
    800027fe:	1141                	addi	sp,sp,-16
    80002800:	e406                	sd	ra,8(sp)
    80002802:	e022                	sd	s0,0(sp)
    80002804:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002806:	00006597          	auipc	a1,0x6
    8000280a:	af258593          	addi	a1,a1,-1294 # 800082f8 <states.0+0x30>
    8000280e:	00015517          	auipc	a0,0x15
    80002812:	38250513          	addi	a0,a0,898 # 80017b90 <tickslock>
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	330080e7          	jalr	816(ra) # 80000b46 <initlock>
}
    8000281e:	60a2                	ld	ra,8(sp)
    80002820:	6402                	ld	s0,0(sp)
    80002822:	0141                	addi	sp,sp,16
    80002824:	8082                	ret

0000000080002826 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002826:	1141                	addi	sp,sp,-16
    80002828:	e422                	sd	s0,8(sp)
    8000282a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000282c:	00003797          	auipc	a5,0x3
    80002830:	6f478793          	addi	a5,a5,1780 # 80005f20 <kernelvec>
    80002834:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002838:	6422                	ld	s0,8(sp)
    8000283a:	0141                	addi	sp,sp,16
    8000283c:	8082                	ret

000000008000283e <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    8000283e:	1141                	addi	sp,sp,-16
    80002840:	e406                	sd	ra,8(sp)
    80002842:	e022                	sd	s0,0(sp)
    80002844:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002846:	fffff097          	auipc	ra,0xfffff
    8000284a:	166080e7          	jalr	358(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000284e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002852:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002854:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002858:	00004617          	auipc	a2,0x4
    8000285c:	7a860613          	addi	a2,a2,1960 # 80007000 <_trampoline>
    80002860:	00004697          	auipc	a3,0x4
    80002864:	7a068693          	addi	a3,a3,1952 # 80007000 <_trampoline>
    80002868:	8e91                	sub	a3,a3,a2
    8000286a:	040007b7          	lui	a5,0x4000
    8000286e:	17fd                	addi	a5,a5,-1
    80002870:	07b2                	slli	a5,a5,0xc
    80002872:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002874:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002878:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000287a:	180026f3          	csrr	a3,satp
    8000287e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002880:	6d38                	ld	a4,88(a0)
    80002882:	6134                	ld	a3,64(a0)
    80002884:	6585                	lui	a1,0x1
    80002886:	96ae                	add	a3,a3,a1
    80002888:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000288a:	6d38                	ld	a4,88(a0)
    8000288c:	00000697          	auipc	a3,0x0
    80002890:	13e68693          	addi	a3,a3,318 # 800029ca <usertrap>
    80002894:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002896:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002898:	8692                	mv	a3,tp
    8000289a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028a0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028a4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028ac:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028ae:	6f18                	ld	a4,24(a4)
    800028b0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028b4:	6928                	ld	a0,80(a0)
    800028b6:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028b8:	00004717          	auipc	a4,0x4
    800028bc:	7e470713          	addi	a4,a4,2020 # 8000709c <userret>
    800028c0:	8f11                	sub	a4,a4,a2
    800028c2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028c4:	577d                	li	a4,-1
    800028c6:	177e                	slli	a4,a4,0x3f
    800028c8:	8d59                	or	a0,a0,a4
    800028ca:	9782                	jalr	a5
}
    800028cc:	60a2                	ld	ra,8(sp)
    800028ce:	6402                	ld	s0,0(sp)
    800028d0:	0141                	addi	sp,sp,16
    800028d2:	8082                	ret

00000000800028d4 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800028d4:	1101                	addi	sp,sp,-32
    800028d6:	ec06                	sd	ra,24(sp)
    800028d8:	e822                	sd	s0,16(sp)
    800028da:	e426                	sd	s1,8(sp)
    800028dc:	e04a                	sd	s2,0(sp)
    800028de:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028e0:	00015917          	auipc	s2,0x15
    800028e4:	2b090913          	addi	s2,s2,688 # 80017b90 <tickslock>
    800028e8:	854a                	mv	a0,s2
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	2ec080e7          	jalr	748(ra) # 80000bd6 <acquire>
  ticks++;
    800028f2:	00006497          	auipc	s1,0x6
    800028f6:	ffe48493          	addi	s1,s1,-2 # 800088f0 <ticks>
    800028fa:	409c                	lw	a5,0(s1)
    800028fc:	2785                	addiw	a5,a5,1
    800028fe:	c09c                	sw	a5,0(s1)
  update_time();
    80002900:	00000097          	auipc	ra,0x0
    80002904:	e22080e7          	jalr	-478(ra) # 80002722 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002908:	8526                	mv	a0,s1
    8000290a:	fffff097          	auipc	ra,0xfffff
    8000290e:	7c2080e7          	jalr	1986(ra) # 800020cc <wakeup>
  release(&tickslock);
    80002912:	854a                	mv	a0,s2
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	376080e7          	jalr	886(ra) # 80000c8a <release>
}
    8000291c:	60e2                	ld	ra,24(sp)
    8000291e:	6442                	ld	s0,16(sp)
    80002920:	64a2                	ld	s1,8(sp)
    80002922:	6902                	ld	s2,0(sp)
    80002924:	6105                	addi	sp,sp,32
    80002926:	8082                	ret

0000000080002928 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002928:	1101                	addi	sp,sp,-32
    8000292a:	ec06                	sd	ra,24(sp)
    8000292c:	e822                	sd	s0,16(sp)
    8000292e:	e426                	sd	s1,8(sp)
    80002930:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002932:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002936:	00074d63          	bltz	a4,80002950 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    8000293a:	57fd                	li	a5,-1
    8000293c:	17fe                	slli	a5,a5,0x3f
    8000293e:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002940:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002942:	06f70363          	beq	a4,a5,800029a8 <devintr+0x80>
  }
}
    80002946:	60e2                	ld	ra,24(sp)
    80002948:	6442                	ld	s0,16(sp)
    8000294a:	64a2                	ld	s1,8(sp)
    8000294c:	6105                	addi	sp,sp,32
    8000294e:	8082                	ret
      (scause & 0xff) == 9)
    80002950:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002954:	46a5                	li	a3,9
    80002956:	fed792e3          	bne	a5,a3,8000293a <devintr+0x12>
    int irq = plic_claim();
    8000295a:	00003097          	auipc	ra,0x3
    8000295e:	6ce080e7          	jalr	1742(ra) # 80006028 <plic_claim>
    80002962:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002964:	47a9                	li	a5,10
    80002966:	02f50763          	beq	a0,a5,80002994 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    8000296a:	4785                	li	a5,1
    8000296c:	02f50963          	beq	a0,a5,8000299e <devintr+0x76>
    return 1;
    80002970:	4505                	li	a0,1
    else if (irq)
    80002972:	d8f1                	beqz	s1,80002946 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002974:	85a6                	mv	a1,s1
    80002976:	00006517          	auipc	a0,0x6
    8000297a:	98a50513          	addi	a0,a0,-1654 # 80008300 <states.0+0x38>
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	c0a080e7          	jalr	-1014(ra) # 80000588 <printf>
      plic_complete(irq);
    80002986:	8526                	mv	a0,s1
    80002988:	00003097          	auipc	ra,0x3
    8000298c:	6c4080e7          	jalr	1732(ra) # 8000604c <plic_complete>
    return 1;
    80002990:	4505                	li	a0,1
    80002992:	bf55                	j	80002946 <devintr+0x1e>
      uartintr();
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	006080e7          	jalr	6(ra) # 8000099a <uartintr>
    8000299c:	b7ed                	j	80002986 <devintr+0x5e>
      virtio_disk_intr();
    8000299e:	00004097          	auipc	ra,0x4
    800029a2:	b7a080e7          	jalr	-1158(ra) # 80006518 <virtio_disk_intr>
    800029a6:	b7c5                	j	80002986 <devintr+0x5e>
    if (cpuid() == 0)
    800029a8:	fffff097          	auipc	ra,0xfffff
    800029ac:	fd8080e7          	jalr	-40(ra) # 80001980 <cpuid>
    800029b0:	c901                	beqz	a0,800029c0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029b2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029b6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029b8:	14479073          	csrw	sip,a5
    return 2;
    800029bc:	4509                	li	a0,2
    800029be:	b761                	j	80002946 <devintr+0x1e>
      clockintr();
    800029c0:	00000097          	auipc	ra,0x0
    800029c4:	f14080e7          	jalr	-236(ra) # 800028d4 <clockintr>
    800029c8:	b7ed                	j	800029b2 <devintr+0x8a>

00000000800029ca <usertrap>:
{
    800029ca:	1101                	addi	sp,sp,-32
    800029cc:	ec06                	sd	ra,24(sp)
    800029ce:	e822                	sd	s0,16(sp)
    800029d0:	e426                	sd	s1,8(sp)
    800029d2:	e04a                	sd	s2,0(sp)
    800029d4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d6:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    800029da:	1007f793          	andi	a5,a5,256
    800029de:	efa1                	bnez	a5,80002a36 <usertrap+0x6c>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029e0:	00003797          	auipc	a5,0x3
    800029e4:	54078793          	addi	a5,a5,1344 # 80005f20 <kernelvec>
    800029e8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029ec:	fffff097          	auipc	ra,0xfffff
    800029f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800029f4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029f6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f8:	14102773          	csrr	a4,sepc
    800029fc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029fe:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002a02:	47a1                	li	a5,8
    80002a04:	04f70163          	beq	a4,a5,80002a46 <usertrap+0x7c>
  else if ((which_dev = devintr()) != 0)
    80002a08:	00000097          	auipc	ra,0x0
    80002a0c:	f20080e7          	jalr	-224(ra) # 80002928 <devintr>
    80002a10:	892a                	mv	s2,a0
    80002a12:	c171                	beqz	a0,80002ad6 <usertrap+0x10c>
    if (which_dev == 2 && p->alarm_active == 0)
    80002a14:	4789                	li	a5,2
    80002a16:	04f51c63          	bne	a0,a5,80002a6e <usertrap+0xa4>
    80002a1a:	1804a783          	lw	a5,384(s1)
    80002a1e:	cfb5                	beqz	a5,80002a9a <usertrap+0xd0>
  if (killed(p))
    80002a20:	8526                	mv	a0,s1
    80002a22:	00000097          	auipc	ra,0x0
    80002a26:	8fa080e7          	jalr	-1798(ra) # 8000231c <killed>
    80002a2a:	ed65                	bnez	a0,80002b22 <usertrap+0x158>
    yield();
    80002a2c:	fffff097          	auipc	ra,0xfffff
    80002a30:	600080e7          	jalr	1536(ra) # 8000202c <yield>
    80002a34:	a099                	j	80002a7a <usertrap+0xb0>
    panic("usertrap: not from user mode");
    80002a36:	00006517          	auipc	a0,0x6
    80002a3a:	8ea50513          	addi	a0,a0,-1814 # 80008320 <states.0+0x58>
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	b00080e7          	jalr	-1280(ra) # 8000053e <panic>
    if (killed(p))
    80002a46:	00000097          	auipc	ra,0x0
    80002a4a:	8d6080e7          	jalr	-1834(ra) # 8000231c <killed>
    80002a4e:	e121                	bnez	a0,80002a8e <usertrap+0xc4>
    p->trapframe->epc += 4;
    80002a50:	6cb8                	ld	a4,88(s1)
    80002a52:	6f1c                	ld	a5,24(a4)
    80002a54:	0791                	addi	a5,a5,4
    80002a56:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a58:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a5c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a60:	10079073          	csrw	sstatus,a5
    syscall();
    80002a64:	00000097          	auipc	ra,0x0
    80002a68:	314080e7          	jalr	788(ra) # 80002d78 <syscall>
  int which_dev = 0;
    80002a6c:	4901                	li	s2,0
  if (killed(p))
    80002a6e:	8526                	mv	a0,s1
    80002a70:	00000097          	auipc	ra,0x0
    80002a74:	8ac080e7          	jalr	-1876(ra) # 8000231c <killed>
    80002a78:	ed41                	bnez	a0,80002b10 <usertrap+0x146>
  usertrapret();
    80002a7a:	00000097          	auipc	ra,0x0
    80002a7e:	dc4080e7          	jalr	-572(ra) # 8000283e <usertrapret>
}
    80002a82:	60e2                	ld	ra,24(sp)
    80002a84:	6442                	ld	s0,16(sp)
    80002a86:	64a2                	ld	s1,8(sp)
    80002a88:	6902                	ld	s2,0(sp)
    80002a8a:	6105                	addi	sp,sp,32
    80002a8c:	8082                	ret
      exit(-1);
    80002a8e:	557d                	li	a0,-1
    80002a90:	fffff097          	auipc	ra,0xfffff
    80002a94:	70c080e7          	jalr	1804(ra) # 8000219c <exit>
    80002a98:	bf65                	j	80002a50 <usertrap+0x86>
      struct trapframe *newframe = kalloc();
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	04c080e7          	jalr	76(ra) # 80000ae6 <kalloc>
    80002aa2:	892a                	mv	s2,a0
      memmove(newframe, p->trapframe, PGSIZE);
    80002aa4:	6605                	lui	a2,0x1
    80002aa6:	6cac                	ld	a1,88(s1)
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	286080e7          	jalr	646(ra) # 80000d2e <memmove>
      p->back_tofunc_context = newframe;
    80002ab0:	1924b423          	sd	s2,392(s1)
      p->tick_count--;
    80002ab4:	1744a783          	lw	a5,372(s1)
    80002ab8:	37fd                	addiw	a5,a5,-1
    80002aba:	0007871b          	sext.w	a4,a5
    80002abe:	16f4aa23          	sw	a5,372(s1)
      if (p->tick_count <= 0)
    80002ac2:	f4e04fe3          	bgtz	a4,80002a20 <usertrap+0x56>
        p->trapframe->epc = (uint64)p->handler;
    80002ac6:	6cbc                	ld	a5,88(s1)
    80002ac8:	1784b703          	ld	a4,376(s1)
    80002acc:	ef98                	sd	a4,24(a5)
        p->alarm_active = 1;
    80002ace:	4785                	li	a5,1
    80002ad0:	18f4a023          	sw	a5,384(s1)
    80002ad4:	b7b1                	j	80002a20 <usertrap+0x56>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ad6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ada:	5890                	lw	a2,48(s1)
    80002adc:	00006517          	auipc	a0,0x6
    80002ae0:	86450513          	addi	a0,a0,-1948 # 80008340 <states.0+0x78>
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	aa4080e7          	jalr	-1372(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aec:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002af0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002af4:	00006517          	auipc	a0,0x6
    80002af8:	87c50513          	addi	a0,a0,-1924 # 80008370 <states.0+0xa8>
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	a8c080e7          	jalr	-1396(ra) # 80000588 <printf>
    setkilled(p);
    80002b04:	8526                	mv	a0,s1
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	7ea080e7          	jalr	2026(ra) # 800022f0 <setkilled>
    80002b0e:	b785                	j	80002a6e <usertrap+0xa4>
    exit(-1);
    80002b10:	557d                	li	a0,-1
    80002b12:	fffff097          	auipc	ra,0xfffff
    80002b16:	68a080e7          	jalr	1674(ra) # 8000219c <exit>
  if (which_dev == 2)
    80002b1a:	4789                	li	a5,2
    80002b1c:	f4f91fe3          	bne	s2,a5,80002a7a <usertrap+0xb0>
    80002b20:	b731                	j	80002a2c <usertrap+0x62>
    exit(-1);
    80002b22:	557d                	li	a0,-1
    80002b24:	fffff097          	auipc	ra,0xfffff
    80002b28:	678080e7          	jalr	1656(ra) # 8000219c <exit>
  if (which_dev == 2)
    80002b2c:	b701                	j	80002a2c <usertrap+0x62>

0000000080002b2e <kerneltrap>:
{
    80002b2e:	7179                	addi	sp,sp,-48
    80002b30:	f406                	sd	ra,40(sp)
    80002b32:	f022                	sd	s0,32(sp)
    80002b34:	ec26                	sd	s1,24(sp)
    80002b36:	e84a                	sd	s2,16(sp)
    80002b38:	e44e                	sd	s3,8(sp)
    80002b3a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b3c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b40:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b44:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002b48:	1004f793          	andi	a5,s1,256
    80002b4c:	cb85                	beqz	a5,80002b7c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b52:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002b54:	ef85                	bnez	a5,80002b8c <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002b56:	00000097          	auipc	ra,0x0
    80002b5a:	dd2080e7          	jalr	-558(ra) # 80002928 <devintr>
    80002b5e:	cd1d                	beqz	a0,80002b9c <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b60:	4789                	li	a5,2
    80002b62:	06f50a63          	beq	a0,a5,80002bd6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b66:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b6a:	10049073          	csrw	sstatus,s1
}
    80002b6e:	70a2                	ld	ra,40(sp)
    80002b70:	7402                	ld	s0,32(sp)
    80002b72:	64e2                	ld	s1,24(sp)
    80002b74:	6942                	ld	s2,16(sp)
    80002b76:	69a2                	ld	s3,8(sp)
    80002b78:	6145                	addi	sp,sp,48
    80002b7a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b7c:	00006517          	auipc	a0,0x6
    80002b80:	81450513          	addi	a0,a0,-2028 # 80008390 <states.0+0xc8>
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	9ba080e7          	jalr	-1606(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b8c:	00006517          	auipc	a0,0x6
    80002b90:	82c50513          	addi	a0,a0,-2004 # 800083b8 <states.0+0xf0>
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	9aa080e7          	jalr	-1622(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b9c:	85ce                	mv	a1,s3
    80002b9e:	00006517          	auipc	a0,0x6
    80002ba2:	83a50513          	addi	a0,a0,-1990 # 800083d8 <states.0+0x110>
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	9e2080e7          	jalr	-1566(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bae:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bb2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bb6:	00006517          	auipc	a0,0x6
    80002bba:	83250513          	addi	a0,a0,-1998 # 800083e8 <states.0+0x120>
    80002bbe:	ffffe097          	auipc	ra,0xffffe
    80002bc2:	9ca080e7          	jalr	-1590(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002bc6:	00006517          	auipc	a0,0x6
    80002bca:	83a50513          	addi	a0,a0,-1990 # 80008400 <states.0+0x138>
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	970080e7          	jalr	-1680(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bd6:	fffff097          	auipc	ra,0xfffff
    80002bda:	dd6080e7          	jalr	-554(ra) # 800019ac <myproc>
    80002bde:	d541                	beqz	a0,80002b66 <kerneltrap+0x38>
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	dcc080e7          	jalr	-564(ra) # 800019ac <myproc>
    80002be8:	4d18                	lw	a4,24(a0)
    80002bea:	4791                	li	a5,4
    80002bec:	f6f71de3          	bne	a4,a5,80002b66 <kerneltrap+0x38>
    yield();
    80002bf0:	fffff097          	auipc	ra,0xfffff
    80002bf4:	43c080e7          	jalr	1084(ra) # 8000202c <yield>
    80002bf8:	b7bd                	j	80002b66 <kerneltrap+0x38>

0000000080002bfa <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bfa:	1101                	addi	sp,sp,-32
    80002bfc:	ec06                	sd	ra,24(sp)
    80002bfe:	e822                	sd	s0,16(sp)
    80002c00:	e426                	sd	s1,8(sp)
    80002c02:	1000                	addi	s0,sp,32
    80002c04:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c06:	fffff097          	auipc	ra,0xfffff
    80002c0a:	da6080e7          	jalr	-602(ra) # 800019ac <myproc>
  switch (n)
    80002c0e:	4795                	li	a5,5
    80002c10:	0497e163          	bltu	a5,s1,80002c52 <argraw+0x58>
    80002c14:	048a                	slli	s1,s1,0x2
    80002c16:	00006717          	auipc	a4,0x6
    80002c1a:	82270713          	addi	a4,a4,-2014 # 80008438 <states.0+0x170>
    80002c1e:	94ba                	add	s1,s1,a4
    80002c20:	409c                	lw	a5,0(s1)
    80002c22:	97ba                	add	a5,a5,a4
    80002c24:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002c26:	6d3c                	ld	a5,88(a0)
    80002c28:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c2a:	60e2                	ld	ra,24(sp)
    80002c2c:	6442                	ld	s0,16(sp)
    80002c2e:	64a2                	ld	s1,8(sp)
    80002c30:	6105                	addi	sp,sp,32
    80002c32:	8082                	ret
    return p->trapframe->a1;
    80002c34:	6d3c                	ld	a5,88(a0)
    80002c36:	7fa8                	ld	a0,120(a5)
    80002c38:	bfcd                	j	80002c2a <argraw+0x30>
    return p->trapframe->a2;
    80002c3a:	6d3c                	ld	a5,88(a0)
    80002c3c:	63c8                	ld	a0,128(a5)
    80002c3e:	b7f5                	j	80002c2a <argraw+0x30>
    return p->trapframe->a3;
    80002c40:	6d3c                	ld	a5,88(a0)
    80002c42:	67c8                	ld	a0,136(a5)
    80002c44:	b7dd                	j	80002c2a <argraw+0x30>
    return p->trapframe->a4;
    80002c46:	6d3c                	ld	a5,88(a0)
    80002c48:	6bc8                	ld	a0,144(a5)
    80002c4a:	b7c5                	j	80002c2a <argraw+0x30>
    return p->trapframe->a5;
    80002c4c:	6d3c                	ld	a5,88(a0)
    80002c4e:	6fc8                	ld	a0,152(a5)
    80002c50:	bfe9                	j	80002c2a <argraw+0x30>
  panic("argraw");
    80002c52:	00005517          	auipc	a0,0x5
    80002c56:	7be50513          	addi	a0,a0,1982 # 80008410 <states.0+0x148>
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	8e4080e7          	jalr	-1820(ra) # 8000053e <panic>

0000000080002c62 <fetchaddr>:
{
    80002c62:	1101                	addi	sp,sp,-32
    80002c64:	ec06                	sd	ra,24(sp)
    80002c66:	e822                	sd	s0,16(sp)
    80002c68:	e426                	sd	s1,8(sp)
    80002c6a:	e04a                	sd	s2,0(sp)
    80002c6c:	1000                	addi	s0,sp,32
    80002c6e:	84aa                	mv	s1,a0
    80002c70:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c72:	fffff097          	auipc	ra,0xfffff
    80002c76:	d3a080e7          	jalr	-710(ra) # 800019ac <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c7a:	653c                	ld	a5,72(a0)
    80002c7c:	02f4f863          	bgeu	s1,a5,80002cac <fetchaddr+0x4a>
    80002c80:	00848713          	addi	a4,s1,8
    80002c84:	02e7e663          	bltu	a5,a4,80002cb0 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c88:	46a1                	li	a3,8
    80002c8a:	8626                	mv	a2,s1
    80002c8c:	85ca                	mv	a1,s2
    80002c8e:	6928                	ld	a0,80(a0)
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	a64080e7          	jalr	-1436(ra) # 800016f4 <copyin>
    80002c98:	00a03533          	snez	a0,a0
    80002c9c:	40a00533          	neg	a0,a0
}
    80002ca0:	60e2                	ld	ra,24(sp)
    80002ca2:	6442                	ld	s0,16(sp)
    80002ca4:	64a2                	ld	s1,8(sp)
    80002ca6:	6902                	ld	s2,0(sp)
    80002ca8:	6105                	addi	sp,sp,32
    80002caa:	8082                	ret
    return -1;
    80002cac:	557d                	li	a0,-1
    80002cae:	bfcd                	j	80002ca0 <fetchaddr+0x3e>
    80002cb0:	557d                	li	a0,-1
    80002cb2:	b7fd                	j	80002ca0 <fetchaddr+0x3e>

0000000080002cb4 <fetchstr>:
{
    80002cb4:	7179                	addi	sp,sp,-48
    80002cb6:	f406                	sd	ra,40(sp)
    80002cb8:	f022                	sd	s0,32(sp)
    80002cba:	ec26                	sd	s1,24(sp)
    80002cbc:	e84a                	sd	s2,16(sp)
    80002cbe:	e44e                	sd	s3,8(sp)
    80002cc0:	1800                	addi	s0,sp,48
    80002cc2:	892a                	mv	s2,a0
    80002cc4:	84ae                	mv	s1,a1
    80002cc6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cc8:	fffff097          	auipc	ra,0xfffff
    80002ccc:	ce4080e7          	jalr	-796(ra) # 800019ac <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002cd0:	86ce                	mv	a3,s3
    80002cd2:	864a                	mv	a2,s2
    80002cd4:	85a6                	mv	a1,s1
    80002cd6:	6928                	ld	a0,80(a0)
    80002cd8:	fffff097          	auipc	ra,0xfffff
    80002cdc:	aaa080e7          	jalr	-1366(ra) # 80001782 <copyinstr>
    80002ce0:	00054e63          	bltz	a0,80002cfc <fetchstr+0x48>
  return strlen(buf);
    80002ce4:	8526                	mv	a0,s1
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	168080e7          	jalr	360(ra) # 80000e4e <strlen>
}
    80002cee:	70a2                	ld	ra,40(sp)
    80002cf0:	7402                	ld	s0,32(sp)
    80002cf2:	64e2                	ld	s1,24(sp)
    80002cf4:	6942                	ld	s2,16(sp)
    80002cf6:	69a2                	ld	s3,8(sp)
    80002cf8:	6145                	addi	sp,sp,48
    80002cfa:	8082                	ret
    return -1;
    80002cfc:	557d                	li	a0,-1
    80002cfe:	bfc5                	j	80002cee <fetchstr+0x3a>

0000000080002d00 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002d00:	1101                	addi	sp,sp,-32
    80002d02:	ec06                	sd	ra,24(sp)
    80002d04:	e822                	sd	s0,16(sp)
    80002d06:	e426                	sd	s1,8(sp)
    80002d08:	1000                	addi	s0,sp,32
    80002d0a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d0c:	00000097          	auipc	ra,0x0
    80002d10:	eee080e7          	jalr	-274(ra) # 80002bfa <argraw>
    80002d14:	c088                	sw	a0,0(s1)
}
    80002d16:	60e2                	ld	ra,24(sp)
    80002d18:	6442                	ld	s0,16(sp)
    80002d1a:	64a2                	ld	s1,8(sp)
    80002d1c:	6105                	addi	sp,sp,32
    80002d1e:	8082                	ret

0000000080002d20 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002d20:	1101                	addi	sp,sp,-32
    80002d22:	ec06                	sd	ra,24(sp)
    80002d24:	e822                	sd	s0,16(sp)
    80002d26:	e426                	sd	s1,8(sp)
    80002d28:	1000                	addi	s0,sp,32
    80002d2a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d2c:	00000097          	auipc	ra,0x0
    80002d30:	ece080e7          	jalr	-306(ra) # 80002bfa <argraw>
    80002d34:	e088                	sd	a0,0(s1)
}
    80002d36:	60e2                	ld	ra,24(sp)
    80002d38:	6442                	ld	s0,16(sp)
    80002d3a:	64a2                	ld	s1,8(sp)
    80002d3c:	6105                	addi	sp,sp,32
    80002d3e:	8082                	ret

0000000080002d40 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002d40:	7179                	addi	sp,sp,-48
    80002d42:	f406                	sd	ra,40(sp)
    80002d44:	f022                	sd	s0,32(sp)
    80002d46:	ec26                	sd	s1,24(sp)
    80002d48:	e84a                	sd	s2,16(sp)
    80002d4a:	1800                	addi	s0,sp,48
    80002d4c:	84ae                	mv	s1,a1
    80002d4e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d50:	fd840593          	addi	a1,s0,-40
    80002d54:	00000097          	auipc	ra,0x0
    80002d58:	fcc080e7          	jalr	-52(ra) # 80002d20 <argaddr>
  return fetchstr(addr, buf, max);
    80002d5c:	864a                	mv	a2,s2
    80002d5e:	85a6                	mv	a1,s1
    80002d60:	fd843503          	ld	a0,-40(s0)
    80002d64:	00000097          	auipc	ra,0x0
    80002d68:	f50080e7          	jalr	-176(ra) # 80002cb4 <fetchstr>
}
    80002d6c:	70a2                	ld	ra,40(sp)
    80002d6e:	7402                	ld	s0,32(sp)
    80002d70:	64e2                	ld	s1,24(sp)
    80002d72:	6942                	ld	s2,16(sp)
    80002d74:	6145                	addi	sp,sp,48
    80002d76:	8082                	ret

0000000080002d78 <syscall>:
    [SYS_sigreturn] sys_sigreturn,
    [SYS_settickets] sys_settickets,
};

void syscall(void)
{
    80002d78:	7179                	addi	sp,sp,-48
    80002d7a:	f406                	sd	ra,40(sp)
    80002d7c:	f022                	sd	s0,32(sp)
    80002d7e:	ec26                	sd	s1,24(sp)
    80002d80:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	c2a080e7          	jalr	-982(ra) # 800019ac <myproc>
    80002d8a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d8c:	6d3c                	ld	a5,88(a0)
    80002d8e:	77dc                	ld	a5,168(a5)
    80002d90:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002d94:	37fd                	addiw	a5,a5,-1
    80002d96:	4765                	li	a4,25
    80002d98:	08f76763          	bltu	a4,a5,80002e26 <syscall+0xae>
    80002d9c:	00369713          	slli	a4,a3,0x3
    80002da0:	00005797          	auipc	a5,0x5
    80002da4:	6b078793          	addi	a5,a5,1712 # 80008450 <syscalls>
    80002da8:	97ba                	add	a5,a5,a4
    80002daa:	6398                	ld	a4,0(a5)
    80002dac:	cf2d                	beqz	a4,80002e26 <syscall+0xae>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    if (num == SYS_getSysCount)
    80002dae:	47dd                	li	a5,23
    80002db0:	00f68f63          	beq	a3,a5,80002dce <syscall+0x56>
    
      p->trapframe->a0 = syscalls[num]();
    }
    else
    {      
      system_call_count[num]++;
    80002db4:	068a                	slli	a3,a3,0x2
    80002db6:	00015797          	auipc	a5,0x15
    80002dba:	df278793          	addi	a5,a5,-526 # 80017ba8 <system_call_count>
    80002dbe:	96be                	add	a3,a3,a5
    80002dc0:	429c                	lw	a5,0(a3)
    80002dc2:	2785                	addiw	a5,a5,1
    80002dc4:	c29c                	sw	a5,0(a3)
      p->trapframe->a0 = syscalls[num]();
    80002dc6:	6d24                	ld	s1,88(a0)
    80002dc8:	9702                	jalr	a4
    80002dca:	f8a8                	sd	a0,112(s1)
    80002dcc:	a89d                	j	80002e42 <syscall+0xca>
      argint(0, &mask);
    80002dce:	fdc40593          	addi	a1,s0,-36
    80002dd2:	4501                	li	a0,0
    80002dd4:	00000097          	auipc	ra,0x0
    80002dd8:	f2c080e7          	jalr	-212(ra) # 80002d00 <argint>
      while (mask > 1)
    80002ddc:	fdc42783          	lw	a5,-36(s0)
    80002de0:	4705                	li	a4,1
    80002de2:	04f75063          	bge	a4,a5,80002e22 <syscall+0xaa>
      int index = 0;
    80002de6:	4701                	li	a4,0
      while (mask > 1)
    80002de8:	4685                	li	a3,1
        mask >>= 1; // Right shift by 1
    80002dea:	4017d79b          	sraiw	a5,a5,0x1
        index++;
    80002dee:	2705                	addiw	a4,a4,1
      while (mask > 1)
    80002df0:	fef6cde3          	blt	a3,a5,80002dea <syscall+0x72>
    80002df4:	fcf42e23          	sw	a5,-36(s0)
      system_call_count[num]++;
    80002df8:	00015797          	auipc	a5,0x15
    80002dfc:	db078793          	addi	a5,a5,-592 # 80017ba8 <system_call_count>
    80002e00:	4ff4                	lw	a3,92(a5)
    80002e02:	2685                	addiw	a3,a3,1
    80002e04:	cff4                	sw	a3,92(a5)
      the_count = system_call_count[index];
    80002e06:	070a                	slli	a4,a4,0x2
    80002e08:	973e                	add	a4,a4,a5
    80002e0a:	431c                	lw	a5,0(a4)
    80002e0c:	00006717          	auipc	a4,0x6
    80002e10:	a6f72623          	sw	a5,-1428(a4) # 80008878 <the_count>
      p->trapframe->a0 = syscalls[num]();
    80002e14:	6ca4                	ld	s1,88(s1)
    80002e16:	00000097          	auipc	ra,0x0
    80002e1a:	0f4080e7          	jalr	244(ra) # 80002f0a <sys_getSysCount>
    80002e1e:	f8a8                	sd	a0,112(s1)
    80002e20:	a00d                	j	80002e42 <syscall+0xca>
      int index = 0;
    80002e22:	4701                	li	a4,0
    80002e24:	bfd1                	j	80002df8 <syscall+0x80>
    }
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002e26:	15848613          	addi	a2,s1,344
    80002e2a:	588c                	lw	a1,48(s1)
    80002e2c:	00005517          	auipc	a0,0x5
    80002e30:	5ec50513          	addi	a0,a0,1516 # 80008418 <states.0+0x150>
    80002e34:	ffffd097          	auipc	ra,0xffffd
    80002e38:	754080e7          	jalr	1876(ra) # 80000588 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e3c:	6cbc                	ld	a5,88(s1)
    80002e3e:	577d                	li	a4,-1
    80002e40:	fbb8                	sd	a4,112(a5)
  }
    80002e42:	70a2                	ld	ra,40(sp)
    80002e44:	7402                	ld	s0,32(sp)
    80002e46:	64e2                	ld	s1,24(sp)
    80002e48:	6145                	addi	sp,sp,48
    80002e4a:	8082                	ret

0000000080002e4c <sys_settickets>:

#define SYS_MAX 31

uint64 
sys_settickets(void)
{
    80002e4c:	1101                	addi	sp,sp,-32
    80002e4e:	ec06                	sd	ra,24(sp)
    80002e50:	e822                	sd	s0,16(sp)
    80002e52:	1000                	addi	s0,sp,32
  int tickets;
  argint(0, &tickets);
    80002e54:	fec40593          	addi	a1,s0,-20
    80002e58:	4501                	li	a0,0
    80002e5a:	00000097          	auipc	ra,0x0
    80002e5e:	ea6080e7          	jalr	-346(ra) # 80002d00 <argint>
  if(tickets < 0)
    80002e62:	fec42783          	lw	a5,-20(s0)
  {
    return -1;
    80002e66:	557d                	li	a0,-1
  if(tickets < 0)
    80002e68:	0007cb63          	bltz	a5,80002e7e <sys_settickets+0x32>
  }
  struct proc *p = myproc();
    80002e6c:	fffff097          	auipc	ra,0xfffff
    80002e70:	b40080e7          	jalr	-1216(ra) # 800019ac <myproc>
  p->tickets = tickets;
    80002e74:	fec42783          	lw	a5,-20(s0)
    80002e78:	18f52a23          	sw	a5,404(a0)
  return 0;
    80002e7c:	4501                	li	a0,0
}  
    80002e7e:	60e2                	ld	ra,24(sp)
    80002e80:	6442                	ld	s0,16(sp)
    80002e82:	6105                	addi	sp,sp,32
    80002e84:	8082                	ret

0000000080002e86 <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    80002e86:	1101                	addi	sp,sp,-32
    80002e88:	ec06                	sd	ra,24(sp)
    80002e8a:	e822                	sd	s0,16(sp)
    80002e8c:	e426                	sd	s1,8(sp)
    80002e8e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	b1c080e7          	jalr	-1252(ra) # 800019ac <myproc>
    80002e98:	84aa                	mv	s1,a0

  if (p->alarm_active == 0 ||p->back_tofunc_context == 0 )
    80002e9a:	18052783          	lw	a5,384(a0)
  {
    return -1;
    80002e9e:	557d                	li	a0,-1
  if (p->alarm_active == 0 ||p->back_tofunc_context == 0 )
    80002ea0:	c395                	beqz	a5,80002ec4 <sys_sigreturn+0x3e>
    80002ea2:	1884b583          	ld	a1,392(s1)
    80002ea6:	c585                	beqz	a1,80002ece <sys_sigreturn+0x48>
  }
  p->alarm_active = 0;
    80002ea8:	1804a023          	sw	zero,384(s1)
  p->tick_count = p->tick_interval;
    80002eac:	1904a783          	lw	a5,400(s1)
    80002eb0:	16f4aa23          	sw	a5,372(s1)
  memmove(p->trapframe, p->back_tofunc_context, PGSIZE);
    80002eb4:	6605                	lui	a2,0x1
    80002eb6:	6ca8                	ld	a0,88(s1)
    80002eb8:	ffffe097          	auipc	ra,0xffffe
    80002ebc:	e76080e7          	jalr	-394(ra) # 80000d2e <memmove>

  return p->trapframe->a0;
    80002ec0:	6cbc                	ld	a5,88(s1)
    80002ec2:	7ba8                	ld	a0,112(a5)
}
    80002ec4:	60e2                	ld	ra,24(sp)
    80002ec6:	6442                	ld	s0,16(sp)
    80002ec8:	64a2                	ld	s1,8(sp)
    80002eca:	6105                	addi	sp,sp,32
    80002ecc:	8082                	ret
    return -1;
    80002ece:	557d                	li	a0,-1
    80002ed0:	bfd5                	j	80002ec4 <sys_sigreturn+0x3e>

0000000080002ed2 <sys_sigalarm>:
uint64
sys_sigalarm(void)
{
    80002ed2:	1141                	addi	sp,sp,-16
    80002ed4:	e406                	sd	ra,8(sp)
    80002ed6:	e022                	sd	s0,0(sp)
    80002ed8:	0800                	addi	s0,sp,16
  int ticks;
  struct proc *p = myproc();
    80002eda:	fffff097          	auipc	ra,0xfffff
    80002ede:	ad2080e7          	jalr	-1326(ra) # 800019ac <myproc>

  ticks = p->trapframe->a0;
    80002ee2:	6d38                	ld	a4,88(a0)
    80002ee4:	5b3c                	lw	a5,112(a4)

  if (ticks < 0)
    80002ee6:	0207c063          	bltz	a5,80002f06 <sys_sigalarm+0x34>
  {
    return -1;
  }
  p->tick_interval = ticks;
    80002eea:	18f52823          	sw	a5,400(a0)
  p->tick_count = ticks;
    80002eee:	16f52a23          	sw	a5,372(a0)
  p->alarm_active = 0;
    80002ef2:	18052023          	sw	zero,384(a0)
  p->handler = p->trapframe->a1;
    80002ef6:	7f3c                	ld	a5,120(a4)
    80002ef8:	16f53c23          	sd	a5,376(a0)
  return 0;
    80002efc:	4501                	li	a0,0
}
    80002efe:	60a2                	ld	ra,8(sp)
    80002f00:	6402                	ld	s0,0(sp)
    80002f02:	0141                	addi	sp,sp,16
    80002f04:	8082                	ret
    return -1;
    80002f06:	557d                	li	a0,-1
    80002f08:	bfdd                	j	80002efe <sys_sigalarm+0x2c>

0000000080002f0a <sys_getSysCount>:
uint64
sys_getSysCount(void)
{
    80002f0a:	1141                	addi	sp,sp,-16
    80002f0c:	e422                	sd	s0,8(sp)
    80002f0e:	0800                	addi	s0,sp,16
  return the_count;
}
    80002f10:	00006517          	auipc	a0,0x6
    80002f14:	96852503          	lw	a0,-1688(a0) # 80008878 <the_count>
    80002f18:	6422                	ld	s0,8(sp)
    80002f1a:	0141                	addi	sp,sp,16
    80002f1c:	8082                	ret

0000000080002f1e <sys_exit>:
uint64
sys_exit(void)
{
    80002f1e:	1101                	addi	sp,sp,-32
    80002f20:	ec06                	sd	ra,24(sp)
    80002f22:	e822                	sd	s0,16(sp)
    80002f24:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002f26:	fec40593          	addi	a1,s0,-20
    80002f2a:	4501                	li	a0,0
    80002f2c:	00000097          	auipc	ra,0x0
    80002f30:	dd4080e7          	jalr	-556(ra) # 80002d00 <argint>
  exit(n);
    80002f34:	fec42503          	lw	a0,-20(s0)
    80002f38:	fffff097          	auipc	ra,0xfffff
    80002f3c:	264080e7          	jalr	612(ra) # 8000219c <exit>
  return 0; // not reached
}
    80002f40:	4501                	li	a0,0
    80002f42:	60e2                	ld	ra,24(sp)
    80002f44:	6442                	ld	s0,16(sp)
    80002f46:	6105                	addi	sp,sp,32
    80002f48:	8082                	ret

0000000080002f4a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f4a:	1141                	addi	sp,sp,-16
    80002f4c:	e406                	sd	ra,8(sp)
    80002f4e:	e022                	sd	s0,0(sp)
    80002f50:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f52:	fffff097          	auipc	ra,0xfffff
    80002f56:	a5a080e7          	jalr	-1446(ra) # 800019ac <myproc>
}
    80002f5a:	5908                	lw	a0,48(a0)
    80002f5c:	60a2                	ld	ra,8(sp)
    80002f5e:	6402                	ld	s0,0(sp)
    80002f60:	0141                	addi	sp,sp,16
    80002f62:	8082                	ret

0000000080002f64 <sys_fork>:

uint64
sys_fork(void)
{
    80002f64:	1141                	addi	sp,sp,-16
    80002f66:	e406                	sd	ra,8(sp)
    80002f68:	e022                	sd	s0,0(sp)
    80002f6a:	0800                	addi	s0,sp,16
  return fork();
    80002f6c:	fffff097          	auipc	ra,0xfffff
    80002f70:	e0a080e7          	jalr	-502(ra) # 80001d76 <fork>
}
    80002f74:	60a2                	ld	ra,8(sp)
    80002f76:	6402                	ld	s0,0(sp)
    80002f78:	0141                	addi	sp,sp,16
    80002f7a:	8082                	ret

0000000080002f7c <sys_wait>:

uint64
sys_wait(void)
{
    80002f7c:	1101                	addi	sp,sp,-32
    80002f7e:	ec06                	sd	ra,24(sp)
    80002f80:	e822                	sd	s0,16(sp)
    80002f82:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002f84:	fe840593          	addi	a1,s0,-24
    80002f88:	4501                	li	a0,0
    80002f8a:	00000097          	auipc	ra,0x0
    80002f8e:	d96080e7          	jalr	-618(ra) # 80002d20 <argaddr>
  return wait(p);
    80002f92:	fe843503          	ld	a0,-24(s0)
    80002f96:	fffff097          	auipc	ra,0xfffff
    80002f9a:	3b8080e7          	jalr	952(ra) # 8000234e <wait>
}
    80002f9e:	60e2                	ld	ra,24(sp)
    80002fa0:	6442                	ld	s0,16(sp)
    80002fa2:	6105                	addi	sp,sp,32
    80002fa4:	8082                	ret

0000000080002fa6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002fa6:	7179                	addi	sp,sp,-48
    80002fa8:	f406                	sd	ra,40(sp)
    80002faa:	f022                	sd	s0,32(sp)
    80002fac:	ec26                	sd	s1,24(sp)
    80002fae:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002fb0:	fdc40593          	addi	a1,s0,-36
    80002fb4:	4501                	li	a0,0
    80002fb6:	00000097          	auipc	ra,0x0
    80002fba:	d4a080e7          	jalr	-694(ra) # 80002d00 <argint>
  addr = myproc()->sz;
    80002fbe:	fffff097          	auipc	ra,0xfffff
    80002fc2:	9ee080e7          	jalr	-1554(ra) # 800019ac <myproc>
    80002fc6:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002fc8:	fdc42503          	lw	a0,-36(s0)
    80002fcc:	fffff097          	auipc	ra,0xfffff
    80002fd0:	d4e080e7          	jalr	-690(ra) # 80001d1a <growproc>
    80002fd4:	00054863          	bltz	a0,80002fe4 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002fd8:	8526                	mv	a0,s1
    80002fda:	70a2                	ld	ra,40(sp)
    80002fdc:	7402                	ld	s0,32(sp)
    80002fde:	64e2                	ld	s1,24(sp)
    80002fe0:	6145                	addi	sp,sp,48
    80002fe2:	8082                	ret
    return -1;
    80002fe4:	54fd                	li	s1,-1
    80002fe6:	bfcd                	j	80002fd8 <sys_sbrk+0x32>

0000000080002fe8 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fe8:	7139                	addi	sp,sp,-64
    80002fea:	fc06                	sd	ra,56(sp)
    80002fec:	f822                	sd	s0,48(sp)
    80002fee:	f426                	sd	s1,40(sp)
    80002ff0:	f04a                	sd	s2,32(sp)
    80002ff2:	ec4e                	sd	s3,24(sp)
    80002ff4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002ff6:	fcc40593          	addi	a1,s0,-52
    80002ffa:	4501                	li	a0,0
    80002ffc:	00000097          	auipc	ra,0x0
    80003000:	d04080e7          	jalr	-764(ra) # 80002d00 <argint>
  acquire(&tickslock);
    80003004:	00015517          	auipc	a0,0x15
    80003008:	b8c50513          	addi	a0,a0,-1140 # 80017b90 <tickslock>
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	bca080e7          	jalr	-1078(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80003014:	00006917          	auipc	s2,0x6
    80003018:	8dc92903          	lw	s2,-1828(s2) # 800088f0 <ticks>
  while (ticks - ticks0 < n)
    8000301c:	fcc42783          	lw	a5,-52(s0)
    80003020:	cf9d                	beqz	a5,8000305e <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003022:	00015997          	auipc	s3,0x15
    80003026:	b6e98993          	addi	s3,s3,-1170 # 80017b90 <tickslock>
    8000302a:	00006497          	auipc	s1,0x6
    8000302e:	8c648493          	addi	s1,s1,-1850 # 800088f0 <ticks>
    if (killed(myproc()))
    80003032:	fffff097          	auipc	ra,0xfffff
    80003036:	97a080e7          	jalr	-1670(ra) # 800019ac <myproc>
    8000303a:	fffff097          	auipc	ra,0xfffff
    8000303e:	2e2080e7          	jalr	738(ra) # 8000231c <killed>
    80003042:	ed15                	bnez	a0,8000307e <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003044:	85ce                	mv	a1,s3
    80003046:	8526                	mv	a0,s1
    80003048:	fffff097          	auipc	ra,0xfffff
    8000304c:	020080e7          	jalr	32(ra) # 80002068 <sleep>
  while (ticks - ticks0 < n)
    80003050:	409c                	lw	a5,0(s1)
    80003052:	412787bb          	subw	a5,a5,s2
    80003056:	fcc42703          	lw	a4,-52(s0)
    8000305a:	fce7ece3          	bltu	a5,a4,80003032 <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000305e:	00015517          	auipc	a0,0x15
    80003062:	b3250513          	addi	a0,a0,-1230 # 80017b90 <tickslock>
    80003066:	ffffe097          	auipc	ra,0xffffe
    8000306a:	c24080e7          	jalr	-988(ra) # 80000c8a <release>
  return 0;
    8000306e:	4501                	li	a0,0
}
    80003070:	70e2                	ld	ra,56(sp)
    80003072:	7442                	ld	s0,48(sp)
    80003074:	74a2                	ld	s1,40(sp)
    80003076:	7902                	ld	s2,32(sp)
    80003078:	69e2                	ld	s3,24(sp)
    8000307a:	6121                	addi	sp,sp,64
    8000307c:	8082                	ret
      release(&tickslock);
    8000307e:	00015517          	auipc	a0,0x15
    80003082:	b1250513          	addi	a0,a0,-1262 # 80017b90 <tickslock>
    80003086:	ffffe097          	auipc	ra,0xffffe
    8000308a:	c04080e7          	jalr	-1020(ra) # 80000c8a <release>
      return -1;
    8000308e:	557d                	li	a0,-1
    80003090:	b7c5                	j	80003070 <sys_sleep+0x88>

0000000080003092 <sys_kill>:

uint64
sys_kill(void)
{
    80003092:	1101                	addi	sp,sp,-32
    80003094:	ec06                	sd	ra,24(sp)
    80003096:	e822                	sd	s0,16(sp)
    80003098:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000309a:	fec40593          	addi	a1,s0,-20
    8000309e:	4501                	li	a0,0
    800030a0:	00000097          	auipc	ra,0x0
    800030a4:	c60080e7          	jalr	-928(ra) # 80002d00 <argint>
  return kill(pid);
    800030a8:	fec42503          	lw	a0,-20(s0)
    800030ac:	fffff097          	auipc	ra,0xfffff
    800030b0:	1d2080e7          	jalr	466(ra) # 8000227e <kill>
}
    800030b4:	60e2                	ld	ra,24(sp)
    800030b6:	6442                	ld	s0,16(sp)
    800030b8:	6105                	addi	sp,sp,32
    800030ba:	8082                	ret

00000000800030bc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030bc:	1101                	addi	sp,sp,-32
    800030be:	ec06                	sd	ra,24(sp)
    800030c0:	e822                	sd	s0,16(sp)
    800030c2:	e426                	sd	s1,8(sp)
    800030c4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030c6:	00015517          	auipc	a0,0x15
    800030ca:	aca50513          	addi	a0,a0,-1334 # 80017b90 <tickslock>
    800030ce:	ffffe097          	auipc	ra,0xffffe
    800030d2:	b08080e7          	jalr	-1272(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800030d6:	00006497          	auipc	s1,0x6
    800030da:	81a4a483          	lw	s1,-2022(s1) # 800088f0 <ticks>
  release(&tickslock);
    800030de:	00015517          	auipc	a0,0x15
    800030e2:	ab250513          	addi	a0,a0,-1358 # 80017b90 <tickslock>
    800030e6:	ffffe097          	auipc	ra,0xffffe
    800030ea:	ba4080e7          	jalr	-1116(ra) # 80000c8a <release>
  return xticks;
}
    800030ee:	02049513          	slli	a0,s1,0x20
    800030f2:	9101                	srli	a0,a0,0x20
    800030f4:	60e2                	ld	ra,24(sp)
    800030f6:	6442                	ld	s0,16(sp)
    800030f8:	64a2                	ld	s1,8(sp)
    800030fa:	6105                	addi	sp,sp,32
    800030fc:	8082                	ret

00000000800030fe <sys_waitx>:

uint64
sys_waitx(void)
{
    800030fe:	7139                	addi	sp,sp,-64
    80003100:	fc06                	sd	ra,56(sp)
    80003102:	f822                	sd	s0,48(sp)
    80003104:	f426                	sd	s1,40(sp)
    80003106:	f04a                	sd	s2,32(sp)
    80003108:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    8000310a:	fd840593          	addi	a1,s0,-40
    8000310e:	4501                	li	a0,0
    80003110:	00000097          	auipc	ra,0x0
    80003114:	c10080e7          	jalr	-1008(ra) # 80002d20 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003118:	fd040593          	addi	a1,s0,-48
    8000311c:	4505                	li	a0,1
    8000311e:	00000097          	auipc	ra,0x0
    80003122:	c02080e7          	jalr	-1022(ra) # 80002d20 <argaddr>
  argaddr(2, &addr2);
    80003126:	fc840593          	addi	a1,s0,-56
    8000312a:	4509                	li	a0,2
    8000312c:	00000097          	auipc	ra,0x0
    80003130:	bf4080e7          	jalr	-1036(ra) # 80002d20 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003134:	fc040613          	addi	a2,s0,-64
    80003138:	fc440593          	addi	a1,s0,-60
    8000313c:	fd843503          	ld	a0,-40(s0)
    80003140:	fffff097          	auipc	ra,0xfffff
    80003144:	496080e7          	jalr	1174(ra) # 800025d6 <waitx>
    80003148:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000314a:	fffff097          	auipc	ra,0xfffff
    8000314e:	862080e7          	jalr	-1950(ra) # 800019ac <myproc>
    80003152:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003154:	4691                	li	a3,4
    80003156:	fc440613          	addi	a2,s0,-60
    8000315a:	fd043583          	ld	a1,-48(s0)
    8000315e:	6928                	ld	a0,80(a0)
    80003160:	ffffe097          	auipc	ra,0xffffe
    80003164:	508080e7          	jalr	1288(ra) # 80001668 <copyout>
    return -1;
    80003168:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000316a:	00054f63          	bltz	a0,80003188 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000316e:	4691                	li	a3,4
    80003170:	fc040613          	addi	a2,s0,-64
    80003174:	fc843583          	ld	a1,-56(s0)
    80003178:	68a8                	ld	a0,80(s1)
    8000317a:	ffffe097          	auipc	ra,0xffffe
    8000317e:	4ee080e7          	jalr	1262(ra) # 80001668 <copyout>
    80003182:	00054a63          	bltz	a0,80003196 <sys_waitx+0x98>
    return -1;
  return ret;
    80003186:	87ca                	mv	a5,s2
    80003188:	853e                	mv	a0,a5
    8000318a:	70e2                	ld	ra,56(sp)
    8000318c:	7442                	ld	s0,48(sp)
    8000318e:	74a2                	ld	s1,40(sp)
    80003190:	7902                	ld	s2,32(sp)
    80003192:	6121                	addi	sp,sp,64
    80003194:	8082                	ret
    return -1;
    80003196:	57fd                	li	a5,-1
    80003198:	bfc5                	j	80003188 <sys_waitx+0x8a>

000000008000319a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000319a:	7179                	addi	sp,sp,-48
    8000319c:	f406                	sd	ra,40(sp)
    8000319e:	f022                	sd	s0,32(sp)
    800031a0:	ec26                	sd	s1,24(sp)
    800031a2:	e84a                	sd	s2,16(sp)
    800031a4:	e44e                	sd	s3,8(sp)
    800031a6:	e052                	sd	s4,0(sp)
    800031a8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031aa:	00005597          	auipc	a1,0x5
    800031ae:	37e58593          	addi	a1,a1,894 # 80008528 <syscalls+0xd8>
    800031b2:	00015517          	auipc	a0,0x15
    800031b6:	a7650513          	addi	a0,a0,-1418 # 80017c28 <bcache>
    800031ba:	ffffe097          	auipc	ra,0xffffe
    800031be:	98c080e7          	jalr	-1652(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031c2:	0001d797          	auipc	a5,0x1d
    800031c6:	a6678793          	addi	a5,a5,-1434 # 8001fc28 <bcache+0x8000>
    800031ca:	0001d717          	auipc	a4,0x1d
    800031ce:	cc670713          	addi	a4,a4,-826 # 8001fe90 <bcache+0x8268>
    800031d2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031d6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031da:	00015497          	auipc	s1,0x15
    800031de:	a6648493          	addi	s1,s1,-1434 # 80017c40 <bcache+0x18>
    b->next = bcache.head.next;
    800031e2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800031e4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800031e6:	00005a17          	auipc	s4,0x5
    800031ea:	34aa0a13          	addi	s4,s4,842 # 80008530 <syscalls+0xe0>
    b->next = bcache.head.next;
    800031ee:	2b893783          	ld	a5,696(s2)
    800031f2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800031f4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800031f8:	85d2                	mv	a1,s4
    800031fa:	01048513          	addi	a0,s1,16
    800031fe:	00001097          	auipc	ra,0x1
    80003202:	4c4080e7          	jalr	1220(ra) # 800046c2 <initsleeplock>
    bcache.head.next->prev = b;
    80003206:	2b893783          	ld	a5,696(s2)
    8000320a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000320c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003210:	45848493          	addi	s1,s1,1112
    80003214:	fd349de3          	bne	s1,s3,800031ee <binit+0x54>
  }
}
    80003218:	70a2                	ld	ra,40(sp)
    8000321a:	7402                	ld	s0,32(sp)
    8000321c:	64e2                	ld	s1,24(sp)
    8000321e:	6942                	ld	s2,16(sp)
    80003220:	69a2                	ld	s3,8(sp)
    80003222:	6a02                	ld	s4,0(sp)
    80003224:	6145                	addi	sp,sp,48
    80003226:	8082                	ret

0000000080003228 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003228:	7179                	addi	sp,sp,-48
    8000322a:	f406                	sd	ra,40(sp)
    8000322c:	f022                	sd	s0,32(sp)
    8000322e:	ec26                	sd	s1,24(sp)
    80003230:	e84a                	sd	s2,16(sp)
    80003232:	e44e                	sd	s3,8(sp)
    80003234:	1800                	addi	s0,sp,48
    80003236:	892a                	mv	s2,a0
    80003238:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000323a:	00015517          	auipc	a0,0x15
    8000323e:	9ee50513          	addi	a0,a0,-1554 # 80017c28 <bcache>
    80003242:	ffffe097          	auipc	ra,0xffffe
    80003246:	994080e7          	jalr	-1644(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000324a:	0001d497          	auipc	s1,0x1d
    8000324e:	c964b483          	ld	s1,-874(s1) # 8001fee0 <bcache+0x82b8>
    80003252:	0001d797          	auipc	a5,0x1d
    80003256:	c3e78793          	addi	a5,a5,-962 # 8001fe90 <bcache+0x8268>
    8000325a:	02f48f63          	beq	s1,a5,80003298 <bread+0x70>
    8000325e:	873e                	mv	a4,a5
    80003260:	a021                	j	80003268 <bread+0x40>
    80003262:	68a4                	ld	s1,80(s1)
    80003264:	02e48a63          	beq	s1,a4,80003298 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003268:	449c                	lw	a5,8(s1)
    8000326a:	ff279ce3          	bne	a5,s2,80003262 <bread+0x3a>
    8000326e:	44dc                	lw	a5,12(s1)
    80003270:	ff3799e3          	bne	a5,s3,80003262 <bread+0x3a>
      b->refcnt++;
    80003274:	40bc                	lw	a5,64(s1)
    80003276:	2785                	addiw	a5,a5,1
    80003278:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000327a:	00015517          	auipc	a0,0x15
    8000327e:	9ae50513          	addi	a0,a0,-1618 # 80017c28 <bcache>
    80003282:	ffffe097          	auipc	ra,0xffffe
    80003286:	a08080e7          	jalr	-1528(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000328a:	01048513          	addi	a0,s1,16
    8000328e:	00001097          	auipc	ra,0x1
    80003292:	46e080e7          	jalr	1134(ra) # 800046fc <acquiresleep>
      return b;
    80003296:	a8b9                	j	800032f4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003298:	0001d497          	auipc	s1,0x1d
    8000329c:	c404b483          	ld	s1,-960(s1) # 8001fed8 <bcache+0x82b0>
    800032a0:	0001d797          	auipc	a5,0x1d
    800032a4:	bf078793          	addi	a5,a5,-1040 # 8001fe90 <bcache+0x8268>
    800032a8:	00f48863          	beq	s1,a5,800032b8 <bread+0x90>
    800032ac:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032ae:	40bc                	lw	a5,64(s1)
    800032b0:	cf81                	beqz	a5,800032c8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032b2:	64a4                	ld	s1,72(s1)
    800032b4:	fee49de3          	bne	s1,a4,800032ae <bread+0x86>
  panic("bget: no buffers");
    800032b8:	00005517          	auipc	a0,0x5
    800032bc:	28050513          	addi	a0,a0,640 # 80008538 <syscalls+0xe8>
    800032c0:	ffffd097          	auipc	ra,0xffffd
    800032c4:	27e080e7          	jalr	638(ra) # 8000053e <panic>
      b->dev = dev;
    800032c8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800032cc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800032d0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032d4:	4785                	li	a5,1
    800032d6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032d8:	00015517          	auipc	a0,0x15
    800032dc:	95050513          	addi	a0,a0,-1712 # 80017c28 <bcache>
    800032e0:	ffffe097          	auipc	ra,0xffffe
    800032e4:	9aa080e7          	jalr	-1622(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800032e8:	01048513          	addi	a0,s1,16
    800032ec:	00001097          	auipc	ra,0x1
    800032f0:	410080e7          	jalr	1040(ra) # 800046fc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800032f4:	409c                	lw	a5,0(s1)
    800032f6:	cb89                	beqz	a5,80003308 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032f8:	8526                	mv	a0,s1
    800032fa:	70a2                	ld	ra,40(sp)
    800032fc:	7402                	ld	s0,32(sp)
    800032fe:	64e2                	ld	s1,24(sp)
    80003300:	6942                	ld	s2,16(sp)
    80003302:	69a2                	ld	s3,8(sp)
    80003304:	6145                	addi	sp,sp,48
    80003306:	8082                	ret
    virtio_disk_rw(b, 0);
    80003308:	4581                	li	a1,0
    8000330a:	8526                	mv	a0,s1
    8000330c:	00003097          	auipc	ra,0x3
    80003310:	fd8080e7          	jalr	-40(ra) # 800062e4 <virtio_disk_rw>
    b->valid = 1;
    80003314:	4785                	li	a5,1
    80003316:	c09c                	sw	a5,0(s1)
  return b;
    80003318:	b7c5                	j	800032f8 <bread+0xd0>

000000008000331a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000331a:	1101                	addi	sp,sp,-32
    8000331c:	ec06                	sd	ra,24(sp)
    8000331e:	e822                	sd	s0,16(sp)
    80003320:	e426                	sd	s1,8(sp)
    80003322:	1000                	addi	s0,sp,32
    80003324:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003326:	0541                	addi	a0,a0,16
    80003328:	00001097          	auipc	ra,0x1
    8000332c:	46e080e7          	jalr	1134(ra) # 80004796 <holdingsleep>
    80003330:	cd01                	beqz	a0,80003348 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003332:	4585                	li	a1,1
    80003334:	8526                	mv	a0,s1
    80003336:	00003097          	auipc	ra,0x3
    8000333a:	fae080e7          	jalr	-82(ra) # 800062e4 <virtio_disk_rw>
}
    8000333e:	60e2                	ld	ra,24(sp)
    80003340:	6442                	ld	s0,16(sp)
    80003342:	64a2                	ld	s1,8(sp)
    80003344:	6105                	addi	sp,sp,32
    80003346:	8082                	ret
    panic("bwrite");
    80003348:	00005517          	auipc	a0,0x5
    8000334c:	20850513          	addi	a0,a0,520 # 80008550 <syscalls+0x100>
    80003350:	ffffd097          	auipc	ra,0xffffd
    80003354:	1ee080e7          	jalr	494(ra) # 8000053e <panic>

0000000080003358 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003358:	1101                	addi	sp,sp,-32
    8000335a:	ec06                	sd	ra,24(sp)
    8000335c:	e822                	sd	s0,16(sp)
    8000335e:	e426                	sd	s1,8(sp)
    80003360:	e04a                	sd	s2,0(sp)
    80003362:	1000                	addi	s0,sp,32
    80003364:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003366:	01050913          	addi	s2,a0,16
    8000336a:	854a                	mv	a0,s2
    8000336c:	00001097          	auipc	ra,0x1
    80003370:	42a080e7          	jalr	1066(ra) # 80004796 <holdingsleep>
    80003374:	c92d                	beqz	a0,800033e6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003376:	854a                	mv	a0,s2
    80003378:	00001097          	auipc	ra,0x1
    8000337c:	3da080e7          	jalr	986(ra) # 80004752 <releasesleep>

  acquire(&bcache.lock);
    80003380:	00015517          	auipc	a0,0x15
    80003384:	8a850513          	addi	a0,a0,-1880 # 80017c28 <bcache>
    80003388:	ffffe097          	auipc	ra,0xffffe
    8000338c:	84e080e7          	jalr	-1970(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003390:	40bc                	lw	a5,64(s1)
    80003392:	37fd                	addiw	a5,a5,-1
    80003394:	0007871b          	sext.w	a4,a5
    80003398:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000339a:	eb05                	bnez	a4,800033ca <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000339c:	68bc                	ld	a5,80(s1)
    8000339e:	64b8                	ld	a4,72(s1)
    800033a0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800033a2:	64bc                	ld	a5,72(s1)
    800033a4:	68b8                	ld	a4,80(s1)
    800033a6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033a8:	0001d797          	auipc	a5,0x1d
    800033ac:	88078793          	addi	a5,a5,-1920 # 8001fc28 <bcache+0x8000>
    800033b0:	2b87b703          	ld	a4,696(a5)
    800033b4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033b6:	0001d717          	auipc	a4,0x1d
    800033ba:	ada70713          	addi	a4,a4,-1318 # 8001fe90 <bcache+0x8268>
    800033be:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033c0:	2b87b703          	ld	a4,696(a5)
    800033c4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033c6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033ca:	00015517          	auipc	a0,0x15
    800033ce:	85e50513          	addi	a0,a0,-1954 # 80017c28 <bcache>
    800033d2:	ffffe097          	auipc	ra,0xffffe
    800033d6:	8b8080e7          	jalr	-1864(ra) # 80000c8a <release>
}
    800033da:	60e2                	ld	ra,24(sp)
    800033dc:	6442                	ld	s0,16(sp)
    800033de:	64a2                	ld	s1,8(sp)
    800033e0:	6902                	ld	s2,0(sp)
    800033e2:	6105                	addi	sp,sp,32
    800033e4:	8082                	ret
    panic("brelse");
    800033e6:	00005517          	auipc	a0,0x5
    800033ea:	17250513          	addi	a0,a0,370 # 80008558 <syscalls+0x108>
    800033ee:	ffffd097          	auipc	ra,0xffffd
    800033f2:	150080e7          	jalr	336(ra) # 8000053e <panic>

00000000800033f6 <bpin>:

void
bpin(struct buf *b) {
    800033f6:	1101                	addi	sp,sp,-32
    800033f8:	ec06                	sd	ra,24(sp)
    800033fa:	e822                	sd	s0,16(sp)
    800033fc:	e426                	sd	s1,8(sp)
    800033fe:	1000                	addi	s0,sp,32
    80003400:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003402:	00015517          	auipc	a0,0x15
    80003406:	82650513          	addi	a0,a0,-2010 # 80017c28 <bcache>
    8000340a:	ffffd097          	auipc	ra,0xffffd
    8000340e:	7cc080e7          	jalr	1996(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003412:	40bc                	lw	a5,64(s1)
    80003414:	2785                	addiw	a5,a5,1
    80003416:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003418:	00015517          	auipc	a0,0x15
    8000341c:	81050513          	addi	a0,a0,-2032 # 80017c28 <bcache>
    80003420:	ffffe097          	auipc	ra,0xffffe
    80003424:	86a080e7          	jalr	-1942(ra) # 80000c8a <release>
}
    80003428:	60e2                	ld	ra,24(sp)
    8000342a:	6442                	ld	s0,16(sp)
    8000342c:	64a2                	ld	s1,8(sp)
    8000342e:	6105                	addi	sp,sp,32
    80003430:	8082                	ret

0000000080003432 <bunpin>:

void
bunpin(struct buf *b) {
    80003432:	1101                	addi	sp,sp,-32
    80003434:	ec06                	sd	ra,24(sp)
    80003436:	e822                	sd	s0,16(sp)
    80003438:	e426                	sd	s1,8(sp)
    8000343a:	1000                	addi	s0,sp,32
    8000343c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000343e:	00014517          	auipc	a0,0x14
    80003442:	7ea50513          	addi	a0,a0,2026 # 80017c28 <bcache>
    80003446:	ffffd097          	auipc	ra,0xffffd
    8000344a:	790080e7          	jalr	1936(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000344e:	40bc                	lw	a5,64(s1)
    80003450:	37fd                	addiw	a5,a5,-1
    80003452:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003454:	00014517          	auipc	a0,0x14
    80003458:	7d450513          	addi	a0,a0,2004 # 80017c28 <bcache>
    8000345c:	ffffe097          	auipc	ra,0xffffe
    80003460:	82e080e7          	jalr	-2002(ra) # 80000c8a <release>
}
    80003464:	60e2                	ld	ra,24(sp)
    80003466:	6442                	ld	s0,16(sp)
    80003468:	64a2                	ld	s1,8(sp)
    8000346a:	6105                	addi	sp,sp,32
    8000346c:	8082                	ret

000000008000346e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000346e:	1101                	addi	sp,sp,-32
    80003470:	ec06                	sd	ra,24(sp)
    80003472:	e822                	sd	s0,16(sp)
    80003474:	e426                	sd	s1,8(sp)
    80003476:	e04a                	sd	s2,0(sp)
    80003478:	1000                	addi	s0,sp,32
    8000347a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000347c:	00d5d59b          	srliw	a1,a1,0xd
    80003480:	0001d797          	auipc	a5,0x1d
    80003484:	e847a783          	lw	a5,-380(a5) # 80020304 <sb+0x1c>
    80003488:	9dbd                	addw	a1,a1,a5
    8000348a:	00000097          	auipc	ra,0x0
    8000348e:	d9e080e7          	jalr	-610(ra) # 80003228 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003492:	0074f713          	andi	a4,s1,7
    80003496:	4785                	li	a5,1
    80003498:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000349c:	14ce                	slli	s1,s1,0x33
    8000349e:	90d9                	srli	s1,s1,0x36
    800034a0:	00950733          	add	a4,a0,s1
    800034a4:	05874703          	lbu	a4,88(a4)
    800034a8:	00e7f6b3          	and	a3,a5,a4
    800034ac:	c69d                	beqz	a3,800034da <bfree+0x6c>
    800034ae:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034b0:	94aa                	add	s1,s1,a0
    800034b2:	fff7c793          	not	a5,a5
    800034b6:	8ff9                	and	a5,a5,a4
    800034b8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800034bc:	00001097          	auipc	ra,0x1
    800034c0:	120080e7          	jalr	288(ra) # 800045dc <log_write>
  brelse(bp);
    800034c4:	854a                	mv	a0,s2
    800034c6:	00000097          	auipc	ra,0x0
    800034ca:	e92080e7          	jalr	-366(ra) # 80003358 <brelse>
}
    800034ce:	60e2                	ld	ra,24(sp)
    800034d0:	6442                	ld	s0,16(sp)
    800034d2:	64a2                	ld	s1,8(sp)
    800034d4:	6902                	ld	s2,0(sp)
    800034d6:	6105                	addi	sp,sp,32
    800034d8:	8082                	ret
    panic("freeing free block");
    800034da:	00005517          	auipc	a0,0x5
    800034de:	08650513          	addi	a0,a0,134 # 80008560 <syscalls+0x110>
    800034e2:	ffffd097          	auipc	ra,0xffffd
    800034e6:	05c080e7          	jalr	92(ra) # 8000053e <panic>

00000000800034ea <balloc>:
{
    800034ea:	711d                	addi	sp,sp,-96
    800034ec:	ec86                	sd	ra,88(sp)
    800034ee:	e8a2                	sd	s0,80(sp)
    800034f0:	e4a6                	sd	s1,72(sp)
    800034f2:	e0ca                	sd	s2,64(sp)
    800034f4:	fc4e                	sd	s3,56(sp)
    800034f6:	f852                	sd	s4,48(sp)
    800034f8:	f456                	sd	s5,40(sp)
    800034fa:	f05a                	sd	s6,32(sp)
    800034fc:	ec5e                	sd	s7,24(sp)
    800034fe:	e862                	sd	s8,16(sp)
    80003500:	e466                	sd	s9,8(sp)
    80003502:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003504:	0001d797          	auipc	a5,0x1d
    80003508:	de87a783          	lw	a5,-536(a5) # 800202ec <sb+0x4>
    8000350c:	10078163          	beqz	a5,8000360e <balloc+0x124>
    80003510:	8baa                	mv	s7,a0
    80003512:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003514:	0001db17          	auipc	s6,0x1d
    80003518:	dd4b0b13          	addi	s6,s6,-556 # 800202e8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000351c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000351e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003520:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003522:	6c89                	lui	s9,0x2
    80003524:	a061                	j	800035ac <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003526:	974a                	add	a4,a4,s2
    80003528:	8fd5                	or	a5,a5,a3
    8000352a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000352e:	854a                	mv	a0,s2
    80003530:	00001097          	auipc	ra,0x1
    80003534:	0ac080e7          	jalr	172(ra) # 800045dc <log_write>
        brelse(bp);
    80003538:	854a                	mv	a0,s2
    8000353a:	00000097          	auipc	ra,0x0
    8000353e:	e1e080e7          	jalr	-482(ra) # 80003358 <brelse>
  bp = bread(dev, bno);
    80003542:	85a6                	mv	a1,s1
    80003544:	855e                	mv	a0,s7
    80003546:	00000097          	auipc	ra,0x0
    8000354a:	ce2080e7          	jalr	-798(ra) # 80003228 <bread>
    8000354e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003550:	40000613          	li	a2,1024
    80003554:	4581                	li	a1,0
    80003556:	05850513          	addi	a0,a0,88
    8000355a:	ffffd097          	auipc	ra,0xffffd
    8000355e:	778080e7          	jalr	1912(ra) # 80000cd2 <memset>
  log_write(bp);
    80003562:	854a                	mv	a0,s2
    80003564:	00001097          	auipc	ra,0x1
    80003568:	078080e7          	jalr	120(ra) # 800045dc <log_write>
  brelse(bp);
    8000356c:	854a                	mv	a0,s2
    8000356e:	00000097          	auipc	ra,0x0
    80003572:	dea080e7          	jalr	-534(ra) # 80003358 <brelse>
}
    80003576:	8526                	mv	a0,s1
    80003578:	60e6                	ld	ra,88(sp)
    8000357a:	6446                	ld	s0,80(sp)
    8000357c:	64a6                	ld	s1,72(sp)
    8000357e:	6906                	ld	s2,64(sp)
    80003580:	79e2                	ld	s3,56(sp)
    80003582:	7a42                	ld	s4,48(sp)
    80003584:	7aa2                	ld	s5,40(sp)
    80003586:	7b02                	ld	s6,32(sp)
    80003588:	6be2                	ld	s7,24(sp)
    8000358a:	6c42                	ld	s8,16(sp)
    8000358c:	6ca2                	ld	s9,8(sp)
    8000358e:	6125                	addi	sp,sp,96
    80003590:	8082                	ret
    brelse(bp);
    80003592:	854a                	mv	a0,s2
    80003594:	00000097          	auipc	ra,0x0
    80003598:	dc4080e7          	jalr	-572(ra) # 80003358 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000359c:	015c87bb          	addw	a5,s9,s5
    800035a0:	00078a9b          	sext.w	s5,a5
    800035a4:	004b2703          	lw	a4,4(s6)
    800035a8:	06eaf363          	bgeu	s5,a4,8000360e <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800035ac:	41fad79b          	sraiw	a5,s5,0x1f
    800035b0:	0137d79b          	srliw	a5,a5,0x13
    800035b4:	015787bb          	addw	a5,a5,s5
    800035b8:	40d7d79b          	sraiw	a5,a5,0xd
    800035bc:	01cb2583          	lw	a1,28(s6)
    800035c0:	9dbd                	addw	a1,a1,a5
    800035c2:	855e                	mv	a0,s7
    800035c4:	00000097          	auipc	ra,0x0
    800035c8:	c64080e7          	jalr	-924(ra) # 80003228 <bread>
    800035cc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035ce:	004b2503          	lw	a0,4(s6)
    800035d2:	000a849b          	sext.w	s1,s5
    800035d6:	8662                	mv	a2,s8
    800035d8:	faa4fde3          	bgeu	s1,a0,80003592 <balloc+0xa8>
      m = 1 << (bi % 8);
    800035dc:	41f6579b          	sraiw	a5,a2,0x1f
    800035e0:	01d7d69b          	srliw	a3,a5,0x1d
    800035e4:	00c6873b          	addw	a4,a3,a2
    800035e8:	00777793          	andi	a5,a4,7
    800035ec:	9f95                	subw	a5,a5,a3
    800035ee:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800035f2:	4037571b          	sraiw	a4,a4,0x3
    800035f6:	00e906b3          	add	a3,s2,a4
    800035fa:	0586c683          	lbu	a3,88(a3)
    800035fe:	00d7f5b3          	and	a1,a5,a3
    80003602:	d195                	beqz	a1,80003526 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003604:	2605                	addiw	a2,a2,1
    80003606:	2485                	addiw	s1,s1,1
    80003608:	fd4618e3          	bne	a2,s4,800035d8 <balloc+0xee>
    8000360c:	b759                	j	80003592 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000360e:	00005517          	auipc	a0,0x5
    80003612:	f6a50513          	addi	a0,a0,-150 # 80008578 <syscalls+0x128>
    80003616:	ffffd097          	auipc	ra,0xffffd
    8000361a:	f72080e7          	jalr	-142(ra) # 80000588 <printf>
  return 0;
    8000361e:	4481                	li	s1,0
    80003620:	bf99                	j	80003576 <balloc+0x8c>

0000000080003622 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003622:	7179                	addi	sp,sp,-48
    80003624:	f406                	sd	ra,40(sp)
    80003626:	f022                	sd	s0,32(sp)
    80003628:	ec26                	sd	s1,24(sp)
    8000362a:	e84a                	sd	s2,16(sp)
    8000362c:	e44e                	sd	s3,8(sp)
    8000362e:	e052                	sd	s4,0(sp)
    80003630:	1800                	addi	s0,sp,48
    80003632:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003634:	47ad                	li	a5,11
    80003636:	02b7e763          	bltu	a5,a1,80003664 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000363a:	02059493          	slli	s1,a1,0x20
    8000363e:	9081                	srli	s1,s1,0x20
    80003640:	048a                	slli	s1,s1,0x2
    80003642:	94aa                	add	s1,s1,a0
    80003644:	0504a903          	lw	s2,80(s1)
    80003648:	06091e63          	bnez	s2,800036c4 <bmap+0xa2>
      addr = balloc(ip->dev);
    8000364c:	4108                	lw	a0,0(a0)
    8000364e:	00000097          	auipc	ra,0x0
    80003652:	e9c080e7          	jalr	-356(ra) # 800034ea <balloc>
    80003656:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000365a:	06090563          	beqz	s2,800036c4 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    8000365e:	0524a823          	sw	s2,80(s1)
    80003662:	a08d                	j	800036c4 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003664:	ff45849b          	addiw	s1,a1,-12
    80003668:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000366c:	0ff00793          	li	a5,255
    80003670:	08e7e563          	bltu	a5,a4,800036fa <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003674:	08052903          	lw	s2,128(a0)
    80003678:	00091d63          	bnez	s2,80003692 <bmap+0x70>
      addr = balloc(ip->dev);
    8000367c:	4108                	lw	a0,0(a0)
    8000367e:	00000097          	auipc	ra,0x0
    80003682:	e6c080e7          	jalr	-404(ra) # 800034ea <balloc>
    80003686:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000368a:	02090d63          	beqz	s2,800036c4 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000368e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003692:	85ca                	mv	a1,s2
    80003694:	0009a503          	lw	a0,0(s3)
    80003698:	00000097          	auipc	ra,0x0
    8000369c:	b90080e7          	jalr	-1136(ra) # 80003228 <bread>
    800036a0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800036a2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800036a6:	02049593          	slli	a1,s1,0x20
    800036aa:	9181                	srli	a1,a1,0x20
    800036ac:	058a                	slli	a1,a1,0x2
    800036ae:	00b784b3          	add	s1,a5,a1
    800036b2:	0004a903          	lw	s2,0(s1)
    800036b6:	02090063          	beqz	s2,800036d6 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800036ba:	8552                	mv	a0,s4
    800036bc:	00000097          	auipc	ra,0x0
    800036c0:	c9c080e7          	jalr	-868(ra) # 80003358 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800036c4:	854a                	mv	a0,s2
    800036c6:	70a2                	ld	ra,40(sp)
    800036c8:	7402                	ld	s0,32(sp)
    800036ca:	64e2                	ld	s1,24(sp)
    800036cc:	6942                	ld	s2,16(sp)
    800036ce:	69a2                	ld	s3,8(sp)
    800036d0:	6a02                	ld	s4,0(sp)
    800036d2:	6145                	addi	sp,sp,48
    800036d4:	8082                	ret
      addr = balloc(ip->dev);
    800036d6:	0009a503          	lw	a0,0(s3)
    800036da:	00000097          	auipc	ra,0x0
    800036de:	e10080e7          	jalr	-496(ra) # 800034ea <balloc>
    800036e2:	0005091b          	sext.w	s2,a0
      if(addr){
    800036e6:	fc090ae3          	beqz	s2,800036ba <bmap+0x98>
        a[bn] = addr;
    800036ea:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800036ee:	8552                	mv	a0,s4
    800036f0:	00001097          	auipc	ra,0x1
    800036f4:	eec080e7          	jalr	-276(ra) # 800045dc <log_write>
    800036f8:	b7c9                	j	800036ba <bmap+0x98>
  panic("bmap: out of range");
    800036fa:	00005517          	auipc	a0,0x5
    800036fe:	e9650513          	addi	a0,a0,-362 # 80008590 <syscalls+0x140>
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	e3c080e7          	jalr	-452(ra) # 8000053e <panic>

000000008000370a <iget>:
{
    8000370a:	7179                	addi	sp,sp,-48
    8000370c:	f406                	sd	ra,40(sp)
    8000370e:	f022                	sd	s0,32(sp)
    80003710:	ec26                	sd	s1,24(sp)
    80003712:	e84a                	sd	s2,16(sp)
    80003714:	e44e                	sd	s3,8(sp)
    80003716:	e052                	sd	s4,0(sp)
    80003718:	1800                	addi	s0,sp,48
    8000371a:	89aa                	mv	s3,a0
    8000371c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000371e:	0001d517          	auipc	a0,0x1d
    80003722:	bea50513          	addi	a0,a0,-1046 # 80020308 <itable>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	4b0080e7          	jalr	1200(ra) # 80000bd6 <acquire>
  empty = 0;
    8000372e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003730:	0001d497          	auipc	s1,0x1d
    80003734:	bf048493          	addi	s1,s1,-1040 # 80020320 <itable+0x18>
    80003738:	0001e697          	auipc	a3,0x1e
    8000373c:	67868693          	addi	a3,a3,1656 # 80021db0 <log>
    80003740:	a039                	j	8000374e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003742:	02090b63          	beqz	s2,80003778 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003746:	08848493          	addi	s1,s1,136
    8000374a:	02d48a63          	beq	s1,a3,8000377e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000374e:	449c                	lw	a5,8(s1)
    80003750:	fef059e3          	blez	a5,80003742 <iget+0x38>
    80003754:	4098                	lw	a4,0(s1)
    80003756:	ff3716e3          	bne	a4,s3,80003742 <iget+0x38>
    8000375a:	40d8                	lw	a4,4(s1)
    8000375c:	ff4713e3          	bne	a4,s4,80003742 <iget+0x38>
      ip->ref++;
    80003760:	2785                	addiw	a5,a5,1
    80003762:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003764:	0001d517          	auipc	a0,0x1d
    80003768:	ba450513          	addi	a0,a0,-1116 # 80020308 <itable>
    8000376c:	ffffd097          	auipc	ra,0xffffd
    80003770:	51e080e7          	jalr	1310(ra) # 80000c8a <release>
      return ip;
    80003774:	8926                	mv	s2,s1
    80003776:	a03d                	j	800037a4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003778:	f7f9                	bnez	a5,80003746 <iget+0x3c>
    8000377a:	8926                	mv	s2,s1
    8000377c:	b7e9                	j	80003746 <iget+0x3c>
  if(empty == 0)
    8000377e:	02090c63          	beqz	s2,800037b6 <iget+0xac>
  ip->dev = dev;
    80003782:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003786:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000378a:	4785                	li	a5,1
    8000378c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003790:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003794:	0001d517          	auipc	a0,0x1d
    80003798:	b7450513          	addi	a0,a0,-1164 # 80020308 <itable>
    8000379c:	ffffd097          	auipc	ra,0xffffd
    800037a0:	4ee080e7          	jalr	1262(ra) # 80000c8a <release>
}
    800037a4:	854a                	mv	a0,s2
    800037a6:	70a2                	ld	ra,40(sp)
    800037a8:	7402                	ld	s0,32(sp)
    800037aa:	64e2                	ld	s1,24(sp)
    800037ac:	6942                	ld	s2,16(sp)
    800037ae:	69a2                	ld	s3,8(sp)
    800037b0:	6a02                	ld	s4,0(sp)
    800037b2:	6145                	addi	sp,sp,48
    800037b4:	8082                	ret
    panic("iget: no inodes");
    800037b6:	00005517          	auipc	a0,0x5
    800037ba:	df250513          	addi	a0,a0,-526 # 800085a8 <syscalls+0x158>
    800037be:	ffffd097          	auipc	ra,0xffffd
    800037c2:	d80080e7          	jalr	-640(ra) # 8000053e <panic>

00000000800037c6 <fsinit>:
fsinit(int dev) {
    800037c6:	7179                	addi	sp,sp,-48
    800037c8:	f406                	sd	ra,40(sp)
    800037ca:	f022                	sd	s0,32(sp)
    800037cc:	ec26                	sd	s1,24(sp)
    800037ce:	e84a                	sd	s2,16(sp)
    800037d0:	e44e                	sd	s3,8(sp)
    800037d2:	1800                	addi	s0,sp,48
    800037d4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037d6:	4585                	li	a1,1
    800037d8:	00000097          	auipc	ra,0x0
    800037dc:	a50080e7          	jalr	-1456(ra) # 80003228 <bread>
    800037e0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037e2:	0001d997          	auipc	s3,0x1d
    800037e6:	b0698993          	addi	s3,s3,-1274 # 800202e8 <sb>
    800037ea:	02000613          	li	a2,32
    800037ee:	05850593          	addi	a1,a0,88
    800037f2:	854e                	mv	a0,s3
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	53a080e7          	jalr	1338(ra) # 80000d2e <memmove>
  brelse(bp);
    800037fc:	8526                	mv	a0,s1
    800037fe:	00000097          	auipc	ra,0x0
    80003802:	b5a080e7          	jalr	-1190(ra) # 80003358 <brelse>
  if(sb.magic != FSMAGIC)
    80003806:	0009a703          	lw	a4,0(s3)
    8000380a:	102037b7          	lui	a5,0x10203
    8000380e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003812:	02f71263          	bne	a4,a5,80003836 <fsinit+0x70>
  initlog(dev, &sb);
    80003816:	0001d597          	auipc	a1,0x1d
    8000381a:	ad258593          	addi	a1,a1,-1326 # 800202e8 <sb>
    8000381e:	854a                	mv	a0,s2
    80003820:	00001097          	auipc	ra,0x1
    80003824:	b40080e7          	jalr	-1216(ra) # 80004360 <initlog>
}
    80003828:	70a2                	ld	ra,40(sp)
    8000382a:	7402                	ld	s0,32(sp)
    8000382c:	64e2                	ld	s1,24(sp)
    8000382e:	6942                	ld	s2,16(sp)
    80003830:	69a2                	ld	s3,8(sp)
    80003832:	6145                	addi	sp,sp,48
    80003834:	8082                	ret
    panic("invalid file system");
    80003836:	00005517          	auipc	a0,0x5
    8000383a:	d8250513          	addi	a0,a0,-638 # 800085b8 <syscalls+0x168>
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	d00080e7          	jalr	-768(ra) # 8000053e <panic>

0000000080003846 <iinit>:
{
    80003846:	7179                	addi	sp,sp,-48
    80003848:	f406                	sd	ra,40(sp)
    8000384a:	f022                	sd	s0,32(sp)
    8000384c:	ec26                	sd	s1,24(sp)
    8000384e:	e84a                	sd	s2,16(sp)
    80003850:	e44e                	sd	s3,8(sp)
    80003852:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003854:	00005597          	auipc	a1,0x5
    80003858:	d7c58593          	addi	a1,a1,-644 # 800085d0 <syscalls+0x180>
    8000385c:	0001d517          	auipc	a0,0x1d
    80003860:	aac50513          	addi	a0,a0,-1364 # 80020308 <itable>
    80003864:	ffffd097          	auipc	ra,0xffffd
    80003868:	2e2080e7          	jalr	738(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000386c:	0001d497          	auipc	s1,0x1d
    80003870:	ac448493          	addi	s1,s1,-1340 # 80020330 <itable+0x28>
    80003874:	0001e997          	auipc	s3,0x1e
    80003878:	54c98993          	addi	s3,s3,1356 # 80021dc0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000387c:	00005917          	auipc	s2,0x5
    80003880:	d5c90913          	addi	s2,s2,-676 # 800085d8 <syscalls+0x188>
    80003884:	85ca                	mv	a1,s2
    80003886:	8526                	mv	a0,s1
    80003888:	00001097          	auipc	ra,0x1
    8000388c:	e3a080e7          	jalr	-454(ra) # 800046c2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003890:	08848493          	addi	s1,s1,136
    80003894:	ff3498e3          	bne	s1,s3,80003884 <iinit+0x3e>
}
    80003898:	70a2                	ld	ra,40(sp)
    8000389a:	7402                	ld	s0,32(sp)
    8000389c:	64e2                	ld	s1,24(sp)
    8000389e:	6942                	ld	s2,16(sp)
    800038a0:	69a2                	ld	s3,8(sp)
    800038a2:	6145                	addi	sp,sp,48
    800038a4:	8082                	ret

00000000800038a6 <ialloc>:
{
    800038a6:	715d                	addi	sp,sp,-80
    800038a8:	e486                	sd	ra,72(sp)
    800038aa:	e0a2                	sd	s0,64(sp)
    800038ac:	fc26                	sd	s1,56(sp)
    800038ae:	f84a                	sd	s2,48(sp)
    800038b0:	f44e                	sd	s3,40(sp)
    800038b2:	f052                	sd	s4,32(sp)
    800038b4:	ec56                	sd	s5,24(sp)
    800038b6:	e85a                	sd	s6,16(sp)
    800038b8:	e45e                	sd	s7,8(sp)
    800038ba:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800038bc:	0001d717          	auipc	a4,0x1d
    800038c0:	a3872703          	lw	a4,-1480(a4) # 800202f4 <sb+0xc>
    800038c4:	4785                	li	a5,1
    800038c6:	04e7fa63          	bgeu	a5,a4,8000391a <ialloc+0x74>
    800038ca:	8aaa                	mv	s5,a0
    800038cc:	8bae                	mv	s7,a1
    800038ce:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800038d0:	0001da17          	auipc	s4,0x1d
    800038d4:	a18a0a13          	addi	s4,s4,-1512 # 800202e8 <sb>
    800038d8:	00048b1b          	sext.w	s6,s1
    800038dc:	0044d793          	srli	a5,s1,0x4
    800038e0:	018a2583          	lw	a1,24(s4)
    800038e4:	9dbd                	addw	a1,a1,a5
    800038e6:	8556                	mv	a0,s5
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	940080e7          	jalr	-1728(ra) # 80003228 <bread>
    800038f0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800038f2:	05850993          	addi	s3,a0,88
    800038f6:	00f4f793          	andi	a5,s1,15
    800038fa:	079a                	slli	a5,a5,0x6
    800038fc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800038fe:	00099783          	lh	a5,0(s3)
    80003902:	c3a1                	beqz	a5,80003942 <ialloc+0x9c>
    brelse(bp);
    80003904:	00000097          	auipc	ra,0x0
    80003908:	a54080e7          	jalr	-1452(ra) # 80003358 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000390c:	0485                	addi	s1,s1,1
    8000390e:	00ca2703          	lw	a4,12(s4)
    80003912:	0004879b          	sext.w	a5,s1
    80003916:	fce7e1e3          	bltu	a5,a4,800038d8 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000391a:	00005517          	auipc	a0,0x5
    8000391e:	cc650513          	addi	a0,a0,-826 # 800085e0 <syscalls+0x190>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	c66080e7          	jalr	-922(ra) # 80000588 <printf>
  return 0;
    8000392a:	4501                	li	a0,0
}
    8000392c:	60a6                	ld	ra,72(sp)
    8000392e:	6406                	ld	s0,64(sp)
    80003930:	74e2                	ld	s1,56(sp)
    80003932:	7942                	ld	s2,48(sp)
    80003934:	79a2                	ld	s3,40(sp)
    80003936:	7a02                	ld	s4,32(sp)
    80003938:	6ae2                	ld	s5,24(sp)
    8000393a:	6b42                	ld	s6,16(sp)
    8000393c:	6ba2                	ld	s7,8(sp)
    8000393e:	6161                	addi	sp,sp,80
    80003940:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003942:	04000613          	li	a2,64
    80003946:	4581                	li	a1,0
    80003948:	854e                	mv	a0,s3
    8000394a:	ffffd097          	auipc	ra,0xffffd
    8000394e:	388080e7          	jalr	904(ra) # 80000cd2 <memset>
      dip->type = type;
    80003952:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003956:	854a                	mv	a0,s2
    80003958:	00001097          	auipc	ra,0x1
    8000395c:	c84080e7          	jalr	-892(ra) # 800045dc <log_write>
      brelse(bp);
    80003960:	854a                	mv	a0,s2
    80003962:	00000097          	auipc	ra,0x0
    80003966:	9f6080e7          	jalr	-1546(ra) # 80003358 <brelse>
      return iget(dev, inum);
    8000396a:	85da                	mv	a1,s6
    8000396c:	8556                	mv	a0,s5
    8000396e:	00000097          	auipc	ra,0x0
    80003972:	d9c080e7          	jalr	-612(ra) # 8000370a <iget>
    80003976:	bf5d                	j	8000392c <ialloc+0x86>

0000000080003978 <iupdate>:
{
    80003978:	1101                	addi	sp,sp,-32
    8000397a:	ec06                	sd	ra,24(sp)
    8000397c:	e822                	sd	s0,16(sp)
    8000397e:	e426                	sd	s1,8(sp)
    80003980:	e04a                	sd	s2,0(sp)
    80003982:	1000                	addi	s0,sp,32
    80003984:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003986:	415c                	lw	a5,4(a0)
    80003988:	0047d79b          	srliw	a5,a5,0x4
    8000398c:	0001d597          	auipc	a1,0x1d
    80003990:	9745a583          	lw	a1,-1676(a1) # 80020300 <sb+0x18>
    80003994:	9dbd                	addw	a1,a1,a5
    80003996:	4108                	lw	a0,0(a0)
    80003998:	00000097          	auipc	ra,0x0
    8000399c:	890080e7          	jalr	-1904(ra) # 80003228 <bread>
    800039a0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039a2:	05850793          	addi	a5,a0,88
    800039a6:	40c8                	lw	a0,4(s1)
    800039a8:	893d                	andi	a0,a0,15
    800039aa:	051a                	slli	a0,a0,0x6
    800039ac:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800039ae:	04449703          	lh	a4,68(s1)
    800039b2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800039b6:	04649703          	lh	a4,70(s1)
    800039ba:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800039be:	04849703          	lh	a4,72(s1)
    800039c2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800039c6:	04a49703          	lh	a4,74(s1)
    800039ca:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800039ce:	44f8                	lw	a4,76(s1)
    800039d0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800039d2:	03400613          	li	a2,52
    800039d6:	05048593          	addi	a1,s1,80
    800039da:	0531                	addi	a0,a0,12
    800039dc:	ffffd097          	auipc	ra,0xffffd
    800039e0:	352080e7          	jalr	850(ra) # 80000d2e <memmove>
  log_write(bp);
    800039e4:	854a                	mv	a0,s2
    800039e6:	00001097          	auipc	ra,0x1
    800039ea:	bf6080e7          	jalr	-1034(ra) # 800045dc <log_write>
  brelse(bp);
    800039ee:	854a                	mv	a0,s2
    800039f0:	00000097          	auipc	ra,0x0
    800039f4:	968080e7          	jalr	-1688(ra) # 80003358 <brelse>
}
    800039f8:	60e2                	ld	ra,24(sp)
    800039fa:	6442                	ld	s0,16(sp)
    800039fc:	64a2                	ld	s1,8(sp)
    800039fe:	6902                	ld	s2,0(sp)
    80003a00:	6105                	addi	sp,sp,32
    80003a02:	8082                	ret

0000000080003a04 <idup>:
{
    80003a04:	1101                	addi	sp,sp,-32
    80003a06:	ec06                	sd	ra,24(sp)
    80003a08:	e822                	sd	s0,16(sp)
    80003a0a:	e426                	sd	s1,8(sp)
    80003a0c:	1000                	addi	s0,sp,32
    80003a0e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a10:	0001d517          	auipc	a0,0x1d
    80003a14:	8f850513          	addi	a0,a0,-1800 # 80020308 <itable>
    80003a18:	ffffd097          	auipc	ra,0xffffd
    80003a1c:	1be080e7          	jalr	446(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003a20:	449c                	lw	a5,8(s1)
    80003a22:	2785                	addiw	a5,a5,1
    80003a24:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a26:	0001d517          	auipc	a0,0x1d
    80003a2a:	8e250513          	addi	a0,a0,-1822 # 80020308 <itable>
    80003a2e:	ffffd097          	auipc	ra,0xffffd
    80003a32:	25c080e7          	jalr	604(ra) # 80000c8a <release>
}
    80003a36:	8526                	mv	a0,s1
    80003a38:	60e2                	ld	ra,24(sp)
    80003a3a:	6442                	ld	s0,16(sp)
    80003a3c:	64a2                	ld	s1,8(sp)
    80003a3e:	6105                	addi	sp,sp,32
    80003a40:	8082                	ret

0000000080003a42 <ilock>:
{
    80003a42:	1101                	addi	sp,sp,-32
    80003a44:	ec06                	sd	ra,24(sp)
    80003a46:	e822                	sd	s0,16(sp)
    80003a48:	e426                	sd	s1,8(sp)
    80003a4a:	e04a                	sd	s2,0(sp)
    80003a4c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a4e:	c115                	beqz	a0,80003a72 <ilock+0x30>
    80003a50:	84aa                	mv	s1,a0
    80003a52:	451c                	lw	a5,8(a0)
    80003a54:	00f05f63          	blez	a5,80003a72 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a58:	0541                	addi	a0,a0,16
    80003a5a:	00001097          	auipc	ra,0x1
    80003a5e:	ca2080e7          	jalr	-862(ra) # 800046fc <acquiresleep>
  if(ip->valid == 0){
    80003a62:	40bc                	lw	a5,64(s1)
    80003a64:	cf99                	beqz	a5,80003a82 <ilock+0x40>
}
    80003a66:	60e2                	ld	ra,24(sp)
    80003a68:	6442                	ld	s0,16(sp)
    80003a6a:	64a2                	ld	s1,8(sp)
    80003a6c:	6902                	ld	s2,0(sp)
    80003a6e:	6105                	addi	sp,sp,32
    80003a70:	8082                	ret
    panic("ilock");
    80003a72:	00005517          	auipc	a0,0x5
    80003a76:	b8650513          	addi	a0,a0,-1146 # 800085f8 <syscalls+0x1a8>
    80003a7a:	ffffd097          	auipc	ra,0xffffd
    80003a7e:	ac4080e7          	jalr	-1340(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a82:	40dc                	lw	a5,4(s1)
    80003a84:	0047d79b          	srliw	a5,a5,0x4
    80003a88:	0001d597          	auipc	a1,0x1d
    80003a8c:	8785a583          	lw	a1,-1928(a1) # 80020300 <sb+0x18>
    80003a90:	9dbd                	addw	a1,a1,a5
    80003a92:	4088                	lw	a0,0(s1)
    80003a94:	fffff097          	auipc	ra,0xfffff
    80003a98:	794080e7          	jalr	1940(ra) # 80003228 <bread>
    80003a9c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a9e:	05850593          	addi	a1,a0,88
    80003aa2:	40dc                	lw	a5,4(s1)
    80003aa4:	8bbd                	andi	a5,a5,15
    80003aa6:	079a                	slli	a5,a5,0x6
    80003aa8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003aaa:	00059783          	lh	a5,0(a1)
    80003aae:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ab2:	00259783          	lh	a5,2(a1)
    80003ab6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003aba:	00459783          	lh	a5,4(a1)
    80003abe:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ac2:	00659783          	lh	a5,6(a1)
    80003ac6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003aca:	459c                	lw	a5,8(a1)
    80003acc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ace:	03400613          	li	a2,52
    80003ad2:	05b1                	addi	a1,a1,12
    80003ad4:	05048513          	addi	a0,s1,80
    80003ad8:	ffffd097          	auipc	ra,0xffffd
    80003adc:	256080e7          	jalr	598(ra) # 80000d2e <memmove>
    brelse(bp);
    80003ae0:	854a                	mv	a0,s2
    80003ae2:	00000097          	auipc	ra,0x0
    80003ae6:	876080e7          	jalr	-1930(ra) # 80003358 <brelse>
    ip->valid = 1;
    80003aea:	4785                	li	a5,1
    80003aec:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003aee:	04449783          	lh	a5,68(s1)
    80003af2:	fbb5                	bnez	a5,80003a66 <ilock+0x24>
      panic("ilock: no type");
    80003af4:	00005517          	auipc	a0,0x5
    80003af8:	b0c50513          	addi	a0,a0,-1268 # 80008600 <syscalls+0x1b0>
    80003afc:	ffffd097          	auipc	ra,0xffffd
    80003b00:	a42080e7          	jalr	-1470(ra) # 8000053e <panic>

0000000080003b04 <iunlock>:
{
    80003b04:	1101                	addi	sp,sp,-32
    80003b06:	ec06                	sd	ra,24(sp)
    80003b08:	e822                	sd	s0,16(sp)
    80003b0a:	e426                	sd	s1,8(sp)
    80003b0c:	e04a                	sd	s2,0(sp)
    80003b0e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b10:	c905                	beqz	a0,80003b40 <iunlock+0x3c>
    80003b12:	84aa                	mv	s1,a0
    80003b14:	01050913          	addi	s2,a0,16
    80003b18:	854a                	mv	a0,s2
    80003b1a:	00001097          	auipc	ra,0x1
    80003b1e:	c7c080e7          	jalr	-900(ra) # 80004796 <holdingsleep>
    80003b22:	cd19                	beqz	a0,80003b40 <iunlock+0x3c>
    80003b24:	449c                	lw	a5,8(s1)
    80003b26:	00f05d63          	blez	a5,80003b40 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b2a:	854a                	mv	a0,s2
    80003b2c:	00001097          	auipc	ra,0x1
    80003b30:	c26080e7          	jalr	-986(ra) # 80004752 <releasesleep>
}
    80003b34:	60e2                	ld	ra,24(sp)
    80003b36:	6442                	ld	s0,16(sp)
    80003b38:	64a2                	ld	s1,8(sp)
    80003b3a:	6902                	ld	s2,0(sp)
    80003b3c:	6105                	addi	sp,sp,32
    80003b3e:	8082                	ret
    panic("iunlock");
    80003b40:	00005517          	auipc	a0,0x5
    80003b44:	ad050513          	addi	a0,a0,-1328 # 80008610 <syscalls+0x1c0>
    80003b48:	ffffd097          	auipc	ra,0xffffd
    80003b4c:	9f6080e7          	jalr	-1546(ra) # 8000053e <panic>

0000000080003b50 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b50:	7179                	addi	sp,sp,-48
    80003b52:	f406                	sd	ra,40(sp)
    80003b54:	f022                	sd	s0,32(sp)
    80003b56:	ec26                	sd	s1,24(sp)
    80003b58:	e84a                	sd	s2,16(sp)
    80003b5a:	e44e                	sd	s3,8(sp)
    80003b5c:	e052                	sd	s4,0(sp)
    80003b5e:	1800                	addi	s0,sp,48
    80003b60:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b62:	05050493          	addi	s1,a0,80
    80003b66:	08050913          	addi	s2,a0,128
    80003b6a:	a021                	j	80003b72 <itrunc+0x22>
    80003b6c:	0491                	addi	s1,s1,4
    80003b6e:	01248d63          	beq	s1,s2,80003b88 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b72:	408c                	lw	a1,0(s1)
    80003b74:	dde5                	beqz	a1,80003b6c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b76:	0009a503          	lw	a0,0(s3)
    80003b7a:	00000097          	auipc	ra,0x0
    80003b7e:	8f4080e7          	jalr	-1804(ra) # 8000346e <bfree>
      ip->addrs[i] = 0;
    80003b82:	0004a023          	sw	zero,0(s1)
    80003b86:	b7dd                	j	80003b6c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b88:	0809a583          	lw	a1,128(s3)
    80003b8c:	e185                	bnez	a1,80003bac <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b8e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b92:	854e                	mv	a0,s3
    80003b94:	00000097          	auipc	ra,0x0
    80003b98:	de4080e7          	jalr	-540(ra) # 80003978 <iupdate>
}
    80003b9c:	70a2                	ld	ra,40(sp)
    80003b9e:	7402                	ld	s0,32(sp)
    80003ba0:	64e2                	ld	s1,24(sp)
    80003ba2:	6942                	ld	s2,16(sp)
    80003ba4:	69a2                	ld	s3,8(sp)
    80003ba6:	6a02                	ld	s4,0(sp)
    80003ba8:	6145                	addi	sp,sp,48
    80003baa:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003bac:	0009a503          	lw	a0,0(s3)
    80003bb0:	fffff097          	auipc	ra,0xfffff
    80003bb4:	678080e7          	jalr	1656(ra) # 80003228 <bread>
    80003bb8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003bba:	05850493          	addi	s1,a0,88
    80003bbe:	45850913          	addi	s2,a0,1112
    80003bc2:	a021                	j	80003bca <itrunc+0x7a>
    80003bc4:	0491                	addi	s1,s1,4
    80003bc6:	01248b63          	beq	s1,s2,80003bdc <itrunc+0x8c>
      if(a[j])
    80003bca:	408c                	lw	a1,0(s1)
    80003bcc:	dde5                	beqz	a1,80003bc4 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003bce:	0009a503          	lw	a0,0(s3)
    80003bd2:	00000097          	auipc	ra,0x0
    80003bd6:	89c080e7          	jalr	-1892(ra) # 8000346e <bfree>
    80003bda:	b7ed                	j	80003bc4 <itrunc+0x74>
    brelse(bp);
    80003bdc:	8552                	mv	a0,s4
    80003bde:	fffff097          	auipc	ra,0xfffff
    80003be2:	77a080e7          	jalr	1914(ra) # 80003358 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003be6:	0809a583          	lw	a1,128(s3)
    80003bea:	0009a503          	lw	a0,0(s3)
    80003bee:	00000097          	auipc	ra,0x0
    80003bf2:	880080e7          	jalr	-1920(ra) # 8000346e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003bf6:	0809a023          	sw	zero,128(s3)
    80003bfa:	bf51                	j	80003b8e <itrunc+0x3e>

0000000080003bfc <iput>:
{
    80003bfc:	1101                	addi	sp,sp,-32
    80003bfe:	ec06                	sd	ra,24(sp)
    80003c00:	e822                	sd	s0,16(sp)
    80003c02:	e426                	sd	s1,8(sp)
    80003c04:	e04a                	sd	s2,0(sp)
    80003c06:	1000                	addi	s0,sp,32
    80003c08:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c0a:	0001c517          	auipc	a0,0x1c
    80003c0e:	6fe50513          	addi	a0,a0,1790 # 80020308 <itable>
    80003c12:	ffffd097          	auipc	ra,0xffffd
    80003c16:	fc4080e7          	jalr	-60(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c1a:	4498                	lw	a4,8(s1)
    80003c1c:	4785                	li	a5,1
    80003c1e:	02f70363          	beq	a4,a5,80003c44 <iput+0x48>
  ip->ref--;
    80003c22:	449c                	lw	a5,8(s1)
    80003c24:	37fd                	addiw	a5,a5,-1
    80003c26:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c28:	0001c517          	auipc	a0,0x1c
    80003c2c:	6e050513          	addi	a0,a0,1760 # 80020308 <itable>
    80003c30:	ffffd097          	auipc	ra,0xffffd
    80003c34:	05a080e7          	jalr	90(ra) # 80000c8a <release>
}
    80003c38:	60e2                	ld	ra,24(sp)
    80003c3a:	6442                	ld	s0,16(sp)
    80003c3c:	64a2                	ld	s1,8(sp)
    80003c3e:	6902                	ld	s2,0(sp)
    80003c40:	6105                	addi	sp,sp,32
    80003c42:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c44:	40bc                	lw	a5,64(s1)
    80003c46:	dff1                	beqz	a5,80003c22 <iput+0x26>
    80003c48:	04a49783          	lh	a5,74(s1)
    80003c4c:	fbf9                	bnez	a5,80003c22 <iput+0x26>
    acquiresleep(&ip->lock);
    80003c4e:	01048913          	addi	s2,s1,16
    80003c52:	854a                	mv	a0,s2
    80003c54:	00001097          	auipc	ra,0x1
    80003c58:	aa8080e7          	jalr	-1368(ra) # 800046fc <acquiresleep>
    release(&itable.lock);
    80003c5c:	0001c517          	auipc	a0,0x1c
    80003c60:	6ac50513          	addi	a0,a0,1708 # 80020308 <itable>
    80003c64:	ffffd097          	auipc	ra,0xffffd
    80003c68:	026080e7          	jalr	38(ra) # 80000c8a <release>
    itrunc(ip);
    80003c6c:	8526                	mv	a0,s1
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	ee2080e7          	jalr	-286(ra) # 80003b50 <itrunc>
    ip->type = 0;
    80003c76:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c7a:	8526                	mv	a0,s1
    80003c7c:	00000097          	auipc	ra,0x0
    80003c80:	cfc080e7          	jalr	-772(ra) # 80003978 <iupdate>
    ip->valid = 0;
    80003c84:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c88:	854a                	mv	a0,s2
    80003c8a:	00001097          	auipc	ra,0x1
    80003c8e:	ac8080e7          	jalr	-1336(ra) # 80004752 <releasesleep>
    acquire(&itable.lock);
    80003c92:	0001c517          	auipc	a0,0x1c
    80003c96:	67650513          	addi	a0,a0,1654 # 80020308 <itable>
    80003c9a:	ffffd097          	auipc	ra,0xffffd
    80003c9e:	f3c080e7          	jalr	-196(ra) # 80000bd6 <acquire>
    80003ca2:	b741                	j	80003c22 <iput+0x26>

0000000080003ca4 <iunlockput>:
{
    80003ca4:	1101                	addi	sp,sp,-32
    80003ca6:	ec06                	sd	ra,24(sp)
    80003ca8:	e822                	sd	s0,16(sp)
    80003caa:	e426                	sd	s1,8(sp)
    80003cac:	1000                	addi	s0,sp,32
    80003cae:	84aa                	mv	s1,a0
  iunlock(ip);
    80003cb0:	00000097          	auipc	ra,0x0
    80003cb4:	e54080e7          	jalr	-428(ra) # 80003b04 <iunlock>
  iput(ip);
    80003cb8:	8526                	mv	a0,s1
    80003cba:	00000097          	auipc	ra,0x0
    80003cbe:	f42080e7          	jalr	-190(ra) # 80003bfc <iput>
}
    80003cc2:	60e2                	ld	ra,24(sp)
    80003cc4:	6442                	ld	s0,16(sp)
    80003cc6:	64a2                	ld	s1,8(sp)
    80003cc8:	6105                	addi	sp,sp,32
    80003cca:	8082                	ret

0000000080003ccc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ccc:	1141                	addi	sp,sp,-16
    80003cce:	e422                	sd	s0,8(sp)
    80003cd0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003cd2:	411c                	lw	a5,0(a0)
    80003cd4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003cd6:	415c                	lw	a5,4(a0)
    80003cd8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003cda:	04451783          	lh	a5,68(a0)
    80003cde:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ce2:	04a51783          	lh	a5,74(a0)
    80003ce6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003cea:	04c56783          	lwu	a5,76(a0)
    80003cee:	e99c                	sd	a5,16(a1)
}
    80003cf0:	6422                	ld	s0,8(sp)
    80003cf2:	0141                	addi	sp,sp,16
    80003cf4:	8082                	ret

0000000080003cf6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cf6:	457c                	lw	a5,76(a0)
    80003cf8:	0ed7e963          	bltu	a5,a3,80003dea <readi+0xf4>
{
    80003cfc:	7159                	addi	sp,sp,-112
    80003cfe:	f486                	sd	ra,104(sp)
    80003d00:	f0a2                	sd	s0,96(sp)
    80003d02:	eca6                	sd	s1,88(sp)
    80003d04:	e8ca                	sd	s2,80(sp)
    80003d06:	e4ce                	sd	s3,72(sp)
    80003d08:	e0d2                	sd	s4,64(sp)
    80003d0a:	fc56                	sd	s5,56(sp)
    80003d0c:	f85a                	sd	s6,48(sp)
    80003d0e:	f45e                	sd	s7,40(sp)
    80003d10:	f062                	sd	s8,32(sp)
    80003d12:	ec66                	sd	s9,24(sp)
    80003d14:	e86a                	sd	s10,16(sp)
    80003d16:	e46e                	sd	s11,8(sp)
    80003d18:	1880                	addi	s0,sp,112
    80003d1a:	8b2a                	mv	s6,a0
    80003d1c:	8bae                	mv	s7,a1
    80003d1e:	8a32                	mv	s4,a2
    80003d20:	84b6                	mv	s1,a3
    80003d22:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003d24:	9f35                	addw	a4,a4,a3
    return 0;
    80003d26:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d28:	0ad76063          	bltu	a4,a3,80003dc8 <readi+0xd2>
  if(off + n > ip->size)
    80003d2c:	00e7f463          	bgeu	a5,a4,80003d34 <readi+0x3e>
    n = ip->size - off;
    80003d30:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d34:	0a0a8963          	beqz	s5,80003de6 <readi+0xf0>
    80003d38:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d3a:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d3e:	5c7d                	li	s8,-1
    80003d40:	a82d                	j	80003d7a <readi+0x84>
    80003d42:	020d1d93          	slli	s11,s10,0x20
    80003d46:	020ddd93          	srli	s11,s11,0x20
    80003d4a:	05890793          	addi	a5,s2,88
    80003d4e:	86ee                	mv	a3,s11
    80003d50:	963e                	add	a2,a2,a5
    80003d52:	85d2                	mv	a1,s4
    80003d54:	855e                	mv	a0,s7
    80003d56:	ffffe097          	auipc	ra,0xffffe
    80003d5a:	726080e7          	jalr	1830(ra) # 8000247c <either_copyout>
    80003d5e:	05850d63          	beq	a0,s8,80003db8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d62:	854a                	mv	a0,s2
    80003d64:	fffff097          	auipc	ra,0xfffff
    80003d68:	5f4080e7          	jalr	1524(ra) # 80003358 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d6c:	013d09bb          	addw	s3,s10,s3
    80003d70:	009d04bb          	addw	s1,s10,s1
    80003d74:	9a6e                	add	s4,s4,s11
    80003d76:	0559f763          	bgeu	s3,s5,80003dc4 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003d7a:	00a4d59b          	srliw	a1,s1,0xa
    80003d7e:	855a                	mv	a0,s6
    80003d80:	00000097          	auipc	ra,0x0
    80003d84:	8a2080e7          	jalr	-1886(ra) # 80003622 <bmap>
    80003d88:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d8c:	cd85                	beqz	a1,80003dc4 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d8e:	000b2503          	lw	a0,0(s6)
    80003d92:	fffff097          	auipc	ra,0xfffff
    80003d96:	496080e7          	jalr	1174(ra) # 80003228 <bread>
    80003d9a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d9c:	3ff4f613          	andi	a2,s1,1023
    80003da0:	40cc87bb          	subw	a5,s9,a2
    80003da4:	413a873b          	subw	a4,s5,s3
    80003da8:	8d3e                	mv	s10,a5
    80003daa:	2781                	sext.w	a5,a5
    80003dac:	0007069b          	sext.w	a3,a4
    80003db0:	f8f6f9e3          	bgeu	a3,a5,80003d42 <readi+0x4c>
    80003db4:	8d3a                	mv	s10,a4
    80003db6:	b771                	j	80003d42 <readi+0x4c>
      brelse(bp);
    80003db8:	854a                	mv	a0,s2
    80003dba:	fffff097          	auipc	ra,0xfffff
    80003dbe:	59e080e7          	jalr	1438(ra) # 80003358 <brelse>
      tot = -1;
    80003dc2:	59fd                	li	s3,-1
  }
  return tot;
    80003dc4:	0009851b          	sext.w	a0,s3
}
    80003dc8:	70a6                	ld	ra,104(sp)
    80003dca:	7406                	ld	s0,96(sp)
    80003dcc:	64e6                	ld	s1,88(sp)
    80003dce:	6946                	ld	s2,80(sp)
    80003dd0:	69a6                	ld	s3,72(sp)
    80003dd2:	6a06                	ld	s4,64(sp)
    80003dd4:	7ae2                	ld	s5,56(sp)
    80003dd6:	7b42                	ld	s6,48(sp)
    80003dd8:	7ba2                	ld	s7,40(sp)
    80003dda:	7c02                	ld	s8,32(sp)
    80003ddc:	6ce2                	ld	s9,24(sp)
    80003dde:	6d42                	ld	s10,16(sp)
    80003de0:	6da2                	ld	s11,8(sp)
    80003de2:	6165                	addi	sp,sp,112
    80003de4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003de6:	89d6                	mv	s3,s5
    80003de8:	bff1                	j	80003dc4 <readi+0xce>
    return 0;
    80003dea:	4501                	li	a0,0
}
    80003dec:	8082                	ret

0000000080003dee <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dee:	457c                	lw	a5,76(a0)
    80003df0:	10d7e863          	bltu	a5,a3,80003f00 <writei+0x112>
{
    80003df4:	7159                	addi	sp,sp,-112
    80003df6:	f486                	sd	ra,104(sp)
    80003df8:	f0a2                	sd	s0,96(sp)
    80003dfa:	eca6                	sd	s1,88(sp)
    80003dfc:	e8ca                	sd	s2,80(sp)
    80003dfe:	e4ce                	sd	s3,72(sp)
    80003e00:	e0d2                	sd	s4,64(sp)
    80003e02:	fc56                	sd	s5,56(sp)
    80003e04:	f85a                	sd	s6,48(sp)
    80003e06:	f45e                	sd	s7,40(sp)
    80003e08:	f062                	sd	s8,32(sp)
    80003e0a:	ec66                	sd	s9,24(sp)
    80003e0c:	e86a                	sd	s10,16(sp)
    80003e0e:	e46e                	sd	s11,8(sp)
    80003e10:	1880                	addi	s0,sp,112
    80003e12:	8aaa                	mv	s5,a0
    80003e14:	8bae                	mv	s7,a1
    80003e16:	8a32                	mv	s4,a2
    80003e18:	8936                	mv	s2,a3
    80003e1a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e1c:	00e687bb          	addw	a5,a3,a4
    80003e20:	0ed7e263          	bltu	a5,a3,80003f04 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e24:	00043737          	lui	a4,0x43
    80003e28:	0ef76063          	bltu	a4,a5,80003f08 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e2c:	0c0b0863          	beqz	s6,80003efc <writei+0x10e>
    80003e30:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e32:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e36:	5c7d                	li	s8,-1
    80003e38:	a091                	j	80003e7c <writei+0x8e>
    80003e3a:	020d1d93          	slli	s11,s10,0x20
    80003e3e:	020ddd93          	srli	s11,s11,0x20
    80003e42:	05848793          	addi	a5,s1,88
    80003e46:	86ee                	mv	a3,s11
    80003e48:	8652                	mv	a2,s4
    80003e4a:	85de                	mv	a1,s7
    80003e4c:	953e                	add	a0,a0,a5
    80003e4e:	ffffe097          	auipc	ra,0xffffe
    80003e52:	684080e7          	jalr	1668(ra) # 800024d2 <either_copyin>
    80003e56:	07850263          	beq	a0,s8,80003eba <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e5a:	8526                	mv	a0,s1
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	780080e7          	jalr	1920(ra) # 800045dc <log_write>
    brelse(bp);
    80003e64:	8526                	mv	a0,s1
    80003e66:	fffff097          	auipc	ra,0xfffff
    80003e6a:	4f2080e7          	jalr	1266(ra) # 80003358 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e6e:	013d09bb          	addw	s3,s10,s3
    80003e72:	012d093b          	addw	s2,s10,s2
    80003e76:	9a6e                	add	s4,s4,s11
    80003e78:	0569f663          	bgeu	s3,s6,80003ec4 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e7c:	00a9559b          	srliw	a1,s2,0xa
    80003e80:	8556                	mv	a0,s5
    80003e82:	fffff097          	auipc	ra,0xfffff
    80003e86:	7a0080e7          	jalr	1952(ra) # 80003622 <bmap>
    80003e8a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e8e:	c99d                	beqz	a1,80003ec4 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e90:	000aa503          	lw	a0,0(s5)
    80003e94:	fffff097          	auipc	ra,0xfffff
    80003e98:	394080e7          	jalr	916(ra) # 80003228 <bread>
    80003e9c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e9e:	3ff97513          	andi	a0,s2,1023
    80003ea2:	40ac87bb          	subw	a5,s9,a0
    80003ea6:	413b073b          	subw	a4,s6,s3
    80003eaa:	8d3e                	mv	s10,a5
    80003eac:	2781                	sext.w	a5,a5
    80003eae:	0007069b          	sext.w	a3,a4
    80003eb2:	f8f6f4e3          	bgeu	a3,a5,80003e3a <writei+0x4c>
    80003eb6:	8d3a                	mv	s10,a4
    80003eb8:	b749                	j	80003e3a <writei+0x4c>
      brelse(bp);
    80003eba:	8526                	mv	a0,s1
    80003ebc:	fffff097          	auipc	ra,0xfffff
    80003ec0:	49c080e7          	jalr	1180(ra) # 80003358 <brelse>
  }

  if(off > ip->size)
    80003ec4:	04caa783          	lw	a5,76(s5)
    80003ec8:	0127f463          	bgeu	a5,s2,80003ed0 <writei+0xe2>
    ip->size = off;
    80003ecc:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ed0:	8556                	mv	a0,s5
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	aa6080e7          	jalr	-1370(ra) # 80003978 <iupdate>

  return tot;
    80003eda:	0009851b          	sext.w	a0,s3
}
    80003ede:	70a6                	ld	ra,104(sp)
    80003ee0:	7406                	ld	s0,96(sp)
    80003ee2:	64e6                	ld	s1,88(sp)
    80003ee4:	6946                	ld	s2,80(sp)
    80003ee6:	69a6                	ld	s3,72(sp)
    80003ee8:	6a06                	ld	s4,64(sp)
    80003eea:	7ae2                	ld	s5,56(sp)
    80003eec:	7b42                	ld	s6,48(sp)
    80003eee:	7ba2                	ld	s7,40(sp)
    80003ef0:	7c02                	ld	s8,32(sp)
    80003ef2:	6ce2                	ld	s9,24(sp)
    80003ef4:	6d42                	ld	s10,16(sp)
    80003ef6:	6da2                	ld	s11,8(sp)
    80003ef8:	6165                	addi	sp,sp,112
    80003efa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003efc:	89da                	mv	s3,s6
    80003efe:	bfc9                	j	80003ed0 <writei+0xe2>
    return -1;
    80003f00:	557d                	li	a0,-1
}
    80003f02:	8082                	ret
    return -1;
    80003f04:	557d                	li	a0,-1
    80003f06:	bfe1                	j	80003ede <writei+0xf0>
    return -1;
    80003f08:	557d                	li	a0,-1
    80003f0a:	bfd1                	j	80003ede <writei+0xf0>

0000000080003f0c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f0c:	1141                	addi	sp,sp,-16
    80003f0e:	e406                	sd	ra,8(sp)
    80003f10:	e022                	sd	s0,0(sp)
    80003f12:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f14:	4639                	li	a2,14
    80003f16:	ffffd097          	auipc	ra,0xffffd
    80003f1a:	e8c080e7          	jalr	-372(ra) # 80000da2 <strncmp>
}
    80003f1e:	60a2                	ld	ra,8(sp)
    80003f20:	6402                	ld	s0,0(sp)
    80003f22:	0141                	addi	sp,sp,16
    80003f24:	8082                	ret

0000000080003f26 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f26:	7139                	addi	sp,sp,-64
    80003f28:	fc06                	sd	ra,56(sp)
    80003f2a:	f822                	sd	s0,48(sp)
    80003f2c:	f426                	sd	s1,40(sp)
    80003f2e:	f04a                	sd	s2,32(sp)
    80003f30:	ec4e                	sd	s3,24(sp)
    80003f32:	e852                	sd	s4,16(sp)
    80003f34:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f36:	04451703          	lh	a4,68(a0)
    80003f3a:	4785                	li	a5,1
    80003f3c:	00f71a63          	bne	a4,a5,80003f50 <dirlookup+0x2a>
    80003f40:	892a                	mv	s2,a0
    80003f42:	89ae                	mv	s3,a1
    80003f44:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f46:	457c                	lw	a5,76(a0)
    80003f48:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f4a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f4c:	e79d                	bnez	a5,80003f7a <dirlookup+0x54>
    80003f4e:	a8a5                	j	80003fc6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f50:	00004517          	auipc	a0,0x4
    80003f54:	6c850513          	addi	a0,a0,1736 # 80008618 <syscalls+0x1c8>
    80003f58:	ffffc097          	auipc	ra,0xffffc
    80003f5c:	5e6080e7          	jalr	1510(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003f60:	00004517          	auipc	a0,0x4
    80003f64:	6d050513          	addi	a0,a0,1744 # 80008630 <syscalls+0x1e0>
    80003f68:	ffffc097          	auipc	ra,0xffffc
    80003f6c:	5d6080e7          	jalr	1494(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f70:	24c1                	addiw	s1,s1,16
    80003f72:	04c92783          	lw	a5,76(s2)
    80003f76:	04f4f763          	bgeu	s1,a5,80003fc4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f7a:	4741                	li	a4,16
    80003f7c:	86a6                	mv	a3,s1
    80003f7e:	fc040613          	addi	a2,s0,-64
    80003f82:	4581                	li	a1,0
    80003f84:	854a                	mv	a0,s2
    80003f86:	00000097          	auipc	ra,0x0
    80003f8a:	d70080e7          	jalr	-656(ra) # 80003cf6 <readi>
    80003f8e:	47c1                	li	a5,16
    80003f90:	fcf518e3          	bne	a0,a5,80003f60 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f94:	fc045783          	lhu	a5,-64(s0)
    80003f98:	dfe1                	beqz	a5,80003f70 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f9a:	fc240593          	addi	a1,s0,-62
    80003f9e:	854e                	mv	a0,s3
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	f6c080e7          	jalr	-148(ra) # 80003f0c <namecmp>
    80003fa8:	f561                	bnez	a0,80003f70 <dirlookup+0x4a>
      if(poff)
    80003faa:	000a0463          	beqz	s4,80003fb2 <dirlookup+0x8c>
        *poff = off;
    80003fae:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003fb2:	fc045583          	lhu	a1,-64(s0)
    80003fb6:	00092503          	lw	a0,0(s2)
    80003fba:	fffff097          	auipc	ra,0xfffff
    80003fbe:	750080e7          	jalr	1872(ra) # 8000370a <iget>
    80003fc2:	a011                	j	80003fc6 <dirlookup+0xa0>
  return 0;
    80003fc4:	4501                	li	a0,0
}
    80003fc6:	70e2                	ld	ra,56(sp)
    80003fc8:	7442                	ld	s0,48(sp)
    80003fca:	74a2                	ld	s1,40(sp)
    80003fcc:	7902                	ld	s2,32(sp)
    80003fce:	69e2                	ld	s3,24(sp)
    80003fd0:	6a42                	ld	s4,16(sp)
    80003fd2:	6121                	addi	sp,sp,64
    80003fd4:	8082                	ret

0000000080003fd6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003fd6:	711d                	addi	sp,sp,-96
    80003fd8:	ec86                	sd	ra,88(sp)
    80003fda:	e8a2                	sd	s0,80(sp)
    80003fdc:	e4a6                	sd	s1,72(sp)
    80003fde:	e0ca                	sd	s2,64(sp)
    80003fe0:	fc4e                	sd	s3,56(sp)
    80003fe2:	f852                	sd	s4,48(sp)
    80003fe4:	f456                	sd	s5,40(sp)
    80003fe6:	f05a                	sd	s6,32(sp)
    80003fe8:	ec5e                	sd	s7,24(sp)
    80003fea:	e862                	sd	s8,16(sp)
    80003fec:	e466                	sd	s9,8(sp)
    80003fee:	1080                	addi	s0,sp,96
    80003ff0:	84aa                	mv	s1,a0
    80003ff2:	8aae                	mv	s5,a1
    80003ff4:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ff6:	00054703          	lbu	a4,0(a0)
    80003ffa:	02f00793          	li	a5,47
    80003ffe:	02f70363          	beq	a4,a5,80004024 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004002:	ffffe097          	auipc	ra,0xffffe
    80004006:	9aa080e7          	jalr	-1622(ra) # 800019ac <myproc>
    8000400a:	15053503          	ld	a0,336(a0)
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	9f6080e7          	jalr	-1546(ra) # 80003a04 <idup>
    80004016:	89aa                	mv	s3,a0
  while(*path == '/')
    80004018:	02f00913          	li	s2,47
  len = path - s;
    8000401c:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000401e:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004020:	4b85                	li	s7,1
    80004022:	a865                	j	800040da <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004024:	4585                	li	a1,1
    80004026:	4505                	li	a0,1
    80004028:	fffff097          	auipc	ra,0xfffff
    8000402c:	6e2080e7          	jalr	1762(ra) # 8000370a <iget>
    80004030:	89aa                	mv	s3,a0
    80004032:	b7dd                	j	80004018 <namex+0x42>
      iunlockput(ip);
    80004034:	854e                	mv	a0,s3
    80004036:	00000097          	auipc	ra,0x0
    8000403a:	c6e080e7          	jalr	-914(ra) # 80003ca4 <iunlockput>
      return 0;
    8000403e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004040:	854e                	mv	a0,s3
    80004042:	60e6                	ld	ra,88(sp)
    80004044:	6446                	ld	s0,80(sp)
    80004046:	64a6                	ld	s1,72(sp)
    80004048:	6906                	ld	s2,64(sp)
    8000404a:	79e2                	ld	s3,56(sp)
    8000404c:	7a42                	ld	s4,48(sp)
    8000404e:	7aa2                	ld	s5,40(sp)
    80004050:	7b02                	ld	s6,32(sp)
    80004052:	6be2                	ld	s7,24(sp)
    80004054:	6c42                	ld	s8,16(sp)
    80004056:	6ca2                	ld	s9,8(sp)
    80004058:	6125                	addi	sp,sp,96
    8000405a:	8082                	ret
      iunlock(ip);
    8000405c:	854e                	mv	a0,s3
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	aa6080e7          	jalr	-1370(ra) # 80003b04 <iunlock>
      return ip;
    80004066:	bfe9                	j	80004040 <namex+0x6a>
      iunlockput(ip);
    80004068:	854e                	mv	a0,s3
    8000406a:	00000097          	auipc	ra,0x0
    8000406e:	c3a080e7          	jalr	-966(ra) # 80003ca4 <iunlockput>
      return 0;
    80004072:	89e6                	mv	s3,s9
    80004074:	b7f1                	j	80004040 <namex+0x6a>
  len = path - s;
    80004076:	40b48633          	sub	a2,s1,a1
    8000407a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000407e:	099c5463          	bge	s8,s9,80004106 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004082:	4639                	li	a2,14
    80004084:	8552                	mv	a0,s4
    80004086:	ffffd097          	auipc	ra,0xffffd
    8000408a:	ca8080e7          	jalr	-856(ra) # 80000d2e <memmove>
  while(*path == '/')
    8000408e:	0004c783          	lbu	a5,0(s1)
    80004092:	01279763          	bne	a5,s2,800040a0 <namex+0xca>
    path++;
    80004096:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004098:	0004c783          	lbu	a5,0(s1)
    8000409c:	ff278de3          	beq	a5,s2,80004096 <namex+0xc0>
    ilock(ip);
    800040a0:	854e                	mv	a0,s3
    800040a2:	00000097          	auipc	ra,0x0
    800040a6:	9a0080e7          	jalr	-1632(ra) # 80003a42 <ilock>
    if(ip->type != T_DIR){
    800040aa:	04499783          	lh	a5,68(s3)
    800040ae:	f97793e3          	bne	a5,s7,80004034 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800040b2:	000a8563          	beqz	s5,800040bc <namex+0xe6>
    800040b6:	0004c783          	lbu	a5,0(s1)
    800040ba:	d3cd                	beqz	a5,8000405c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040bc:	865a                	mv	a2,s6
    800040be:	85d2                	mv	a1,s4
    800040c0:	854e                	mv	a0,s3
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	e64080e7          	jalr	-412(ra) # 80003f26 <dirlookup>
    800040ca:	8caa                	mv	s9,a0
    800040cc:	dd51                	beqz	a0,80004068 <namex+0x92>
    iunlockput(ip);
    800040ce:	854e                	mv	a0,s3
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	bd4080e7          	jalr	-1068(ra) # 80003ca4 <iunlockput>
    ip = next;
    800040d8:	89e6                	mv	s3,s9
  while(*path == '/')
    800040da:	0004c783          	lbu	a5,0(s1)
    800040de:	05279763          	bne	a5,s2,8000412c <namex+0x156>
    path++;
    800040e2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040e4:	0004c783          	lbu	a5,0(s1)
    800040e8:	ff278de3          	beq	a5,s2,800040e2 <namex+0x10c>
  if(*path == 0)
    800040ec:	c79d                	beqz	a5,8000411a <namex+0x144>
    path++;
    800040ee:	85a6                	mv	a1,s1
  len = path - s;
    800040f0:	8cda                	mv	s9,s6
    800040f2:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800040f4:	01278963          	beq	a5,s2,80004106 <namex+0x130>
    800040f8:	dfbd                	beqz	a5,80004076 <namex+0xa0>
    path++;
    800040fa:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800040fc:	0004c783          	lbu	a5,0(s1)
    80004100:	ff279ce3          	bne	a5,s2,800040f8 <namex+0x122>
    80004104:	bf8d                	j	80004076 <namex+0xa0>
    memmove(name, s, len);
    80004106:	2601                	sext.w	a2,a2
    80004108:	8552                	mv	a0,s4
    8000410a:	ffffd097          	auipc	ra,0xffffd
    8000410e:	c24080e7          	jalr	-988(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004112:	9cd2                	add	s9,s9,s4
    80004114:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004118:	bf9d                	j	8000408e <namex+0xb8>
  if(nameiparent){
    8000411a:	f20a83e3          	beqz	s5,80004040 <namex+0x6a>
    iput(ip);
    8000411e:	854e                	mv	a0,s3
    80004120:	00000097          	auipc	ra,0x0
    80004124:	adc080e7          	jalr	-1316(ra) # 80003bfc <iput>
    return 0;
    80004128:	4981                	li	s3,0
    8000412a:	bf19                	j	80004040 <namex+0x6a>
  if(*path == 0)
    8000412c:	d7fd                	beqz	a5,8000411a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000412e:	0004c783          	lbu	a5,0(s1)
    80004132:	85a6                	mv	a1,s1
    80004134:	b7d1                	j	800040f8 <namex+0x122>

0000000080004136 <dirlink>:
{
    80004136:	7139                	addi	sp,sp,-64
    80004138:	fc06                	sd	ra,56(sp)
    8000413a:	f822                	sd	s0,48(sp)
    8000413c:	f426                	sd	s1,40(sp)
    8000413e:	f04a                	sd	s2,32(sp)
    80004140:	ec4e                	sd	s3,24(sp)
    80004142:	e852                	sd	s4,16(sp)
    80004144:	0080                	addi	s0,sp,64
    80004146:	892a                	mv	s2,a0
    80004148:	8a2e                	mv	s4,a1
    8000414a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000414c:	4601                	li	a2,0
    8000414e:	00000097          	auipc	ra,0x0
    80004152:	dd8080e7          	jalr	-552(ra) # 80003f26 <dirlookup>
    80004156:	e93d                	bnez	a0,800041cc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004158:	04c92483          	lw	s1,76(s2)
    8000415c:	c49d                	beqz	s1,8000418a <dirlink+0x54>
    8000415e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004160:	4741                	li	a4,16
    80004162:	86a6                	mv	a3,s1
    80004164:	fc040613          	addi	a2,s0,-64
    80004168:	4581                	li	a1,0
    8000416a:	854a                	mv	a0,s2
    8000416c:	00000097          	auipc	ra,0x0
    80004170:	b8a080e7          	jalr	-1142(ra) # 80003cf6 <readi>
    80004174:	47c1                	li	a5,16
    80004176:	06f51163          	bne	a0,a5,800041d8 <dirlink+0xa2>
    if(de.inum == 0)
    8000417a:	fc045783          	lhu	a5,-64(s0)
    8000417e:	c791                	beqz	a5,8000418a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004180:	24c1                	addiw	s1,s1,16
    80004182:	04c92783          	lw	a5,76(s2)
    80004186:	fcf4ede3          	bltu	s1,a5,80004160 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000418a:	4639                	li	a2,14
    8000418c:	85d2                	mv	a1,s4
    8000418e:	fc240513          	addi	a0,s0,-62
    80004192:	ffffd097          	auipc	ra,0xffffd
    80004196:	c4c080e7          	jalr	-948(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000419a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000419e:	4741                	li	a4,16
    800041a0:	86a6                	mv	a3,s1
    800041a2:	fc040613          	addi	a2,s0,-64
    800041a6:	4581                	li	a1,0
    800041a8:	854a                	mv	a0,s2
    800041aa:	00000097          	auipc	ra,0x0
    800041ae:	c44080e7          	jalr	-956(ra) # 80003dee <writei>
    800041b2:	1541                	addi	a0,a0,-16
    800041b4:	00a03533          	snez	a0,a0
    800041b8:	40a00533          	neg	a0,a0
}
    800041bc:	70e2                	ld	ra,56(sp)
    800041be:	7442                	ld	s0,48(sp)
    800041c0:	74a2                	ld	s1,40(sp)
    800041c2:	7902                	ld	s2,32(sp)
    800041c4:	69e2                	ld	s3,24(sp)
    800041c6:	6a42                	ld	s4,16(sp)
    800041c8:	6121                	addi	sp,sp,64
    800041ca:	8082                	ret
    iput(ip);
    800041cc:	00000097          	auipc	ra,0x0
    800041d0:	a30080e7          	jalr	-1488(ra) # 80003bfc <iput>
    return -1;
    800041d4:	557d                	li	a0,-1
    800041d6:	b7dd                	j	800041bc <dirlink+0x86>
      panic("dirlink read");
    800041d8:	00004517          	auipc	a0,0x4
    800041dc:	46850513          	addi	a0,a0,1128 # 80008640 <syscalls+0x1f0>
    800041e0:	ffffc097          	auipc	ra,0xffffc
    800041e4:	35e080e7          	jalr	862(ra) # 8000053e <panic>

00000000800041e8 <namei>:

struct inode*
namei(char *path)
{
    800041e8:	1101                	addi	sp,sp,-32
    800041ea:	ec06                	sd	ra,24(sp)
    800041ec:	e822                	sd	s0,16(sp)
    800041ee:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041f0:	fe040613          	addi	a2,s0,-32
    800041f4:	4581                	li	a1,0
    800041f6:	00000097          	auipc	ra,0x0
    800041fa:	de0080e7          	jalr	-544(ra) # 80003fd6 <namex>
}
    800041fe:	60e2                	ld	ra,24(sp)
    80004200:	6442                	ld	s0,16(sp)
    80004202:	6105                	addi	sp,sp,32
    80004204:	8082                	ret

0000000080004206 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004206:	1141                	addi	sp,sp,-16
    80004208:	e406                	sd	ra,8(sp)
    8000420a:	e022                	sd	s0,0(sp)
    8000420c:	0800                	addi	s0,sp,16
    8000420e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004210:	4585                	li	a1,1
    80004212:	00000097          	auipc	ra,0x0
    80004216:	dc4080e7          	jalr	-572(ra) # 80003fd6 <namex>
}
    8000421a:	60a2                	ld	ra,8(sp)
    8000421c:	6402                	ld	s0,0(sp)
    8000421e:	0141                	addi	sp,sp,16
    80004220:	8082                	ret

0000000080004222 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004222:	1101                	addi	sp,sp,-32
    80004224:	ec06                	sd	ra,24(sp)
    80004226:	e822                	sd	s0,16(sp)
    80004228:	e426                	sd	s1,8(sp)
    8000422a:	e04a                	sd	s2,0(sp)
    8000422c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000422e:	0001e917          	auipc	s2,0x1e
    80004232:	b8290913          	addi	s2,s2,-1150 # 80021db0 <log>
    80004236:	01892583          	lw	a1,24(s2)
    8000423a:	02892503          	lw	a0,40(s2)
    8000423e:	fffff097          	auipc	ra,0xfffff
    80004242:	fea080e7          	jalr	-22(ra) # 80003228 <bread>
    80004246:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004248:	02c92683          	lw	a3,44(s2)
    8000424c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000424e:	02d05763          	blez	a3,8000427c <write_head+0x5a>
    80004252:	0001e797          	auipc	a5,0x1e
    80004256:	b8e78793          	addi	a5,a5,-1138 # 80021de0 <log+0x30>
    8000425a:	05c50713          	addi	a4,a0,92
    8000425e:	36fd                	addiw	a3,a3,-1
    80004260:	1682                	slli	a3,a3,0x20
    80004262:	9281                	srli	a3,a3,0x20
    80004264:	068a                	slli	a3,a3,0x2
    80004266:	0001e617          	auipc	a2,0x1e
    8000426a:	b7e60613          	addi	a2,a2,-1154 # 80021de4 <log+0x34>
    8000426e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004270:	4390                	lw	a2,0(a5)
    80004272:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004274:	0791                	addi	a5,a5,4
    80004276:	0711                	addi	a4,a4,4
    80004278:	fed79ce3          	bne	a5,a3,80004270 <write_head+0x4e>
  }
  bwrite(buf);
    8000427c:	8526                	mv	a0,s1
    8000427e:	fffff097          	auipc	ra,0xfffff
    80004282:	09c080e7          	jalr	156(ra) # 8000331a <bwrite>
  brelse(buf);
    80004286:	8526                	mv	a0,s1
    80004288:	fffff097          	auipc	ra,0xfffff
    8000428c:	0d0080e7          	jalr	208(ra) # 80003358 <brelse>
}
    80004290:	60e2                	ld	ra,24(sp)
    80004292:	6442                	ld	s0,16(sp)
    80004294:	64a2                	ld	s1,8(sp)
    80004296:	6902                	ld	s2,0(sp)
    80004298:	6105                	addi	sp,sp,32
    8000429a:	8082                	ret

000000008000429c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000429c:	0001e797          	auipc	a5,0x1e
    800042a0:	b407a783          	lw	a5,-1216(a5) # 80021ddc <log+0x2c>
    800042a4:	0af05d63          	blez	a5,8000435e <install_trans+0xc2>
{
    800042a8:	7139                	addi	sp,sp,-64
    800042aa:	fc06                	sd	ra,56(sp)
    800042ac:	f822                	sd	s0,48(sp)
    800042ae:	f426                	sd	s1,40(sp)
    800042b0:	f04a                	sd	s2,32(sp)
    800042b2:	ec4e                	sd	s3,24(sp)
    800042b4:	e852                	sd	s4,16(sp)
    800042b6:	e456                	sd	s5,8(sp)
    800042b8:	e05a                	sd	s6,0(sp)
    800042ba:	0080                	addi	s0,sp,64
    800042bc:	8b2a                	mv	s6,a0
    800042be:	0001ea97          	auipc	s5,0x1e
    800042c2:	b22a8a93          	addi	s5,s5,-1246 # 80021de0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042c6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042c8:	0001e997          	auipc	s3,0x1e
    800042cc:	ae898993          	addi	s3,s3,-1304 # 80021db0 <log>
    800042d0:	a00d                	j	800042f2 <install_trans+0x56>
    brelse(lbuf);
    800042d2:	854a                	mv	a0,s2
    800042d4:	fffff097          	auipc	ra,0xfffff
    800042d8:	084080e7          	jalr	132(ra) # 80003358 <brelse>
    brelse(dbuf);
    800042dc:	8526                	mv	a0,s1
    800042de:	fffff097          	auipc	ra,0xfffff
    800042e2:	07a080e7          	jalr	122(ra) # 80003358 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042e6:	2a05                	addiw	s4,s4,1
    800042e8:	0a91                	addi	s5,s5,4
    800042ea:	02c9a783          	lw	a5,44(s3)
    800042ee:	04fa5e63          	bge	s4,a5,8000434a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042f2:	0189a583          	lw	a1,24(s3)
    800042f6:	014585bb          	addw	a1,a1,s4
    800042fa:	2585                	addiw	a1,a1,1
    800042fc:	0289a503          	lw	a0,40(s3)
    80004300:	fffff097          	auipc	ra,0xfffff
    80004304:	f28080e7          	jalr	-216(ra) # 80003228 <bread>
    80004308:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000430a:	000aa583          	lw	a1,0(s5)
    8000430e:	0289a503          	lw	a0,40(s3)
    80004312:	fffff097          	auipc	ra,0xfffff
    80004316:	f16080e7          	jalr	-234(ra) # 80003228 <bread>
    8000431a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000431c:	40000613          	li	a2,1024
    80004320:	05890593          	addi	a1,s2,88
    80004324:	05850513          	addi	a0,a0,88
    80004328:	ffffd097          	auipc	ra,0xffffd
    8000432c:	a06080e7          	jalr	-1530(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004330:	8526                	mv	a0,s1
    80004332:	fffff097          	auipc	ra,0xfffff
    80004336:	fe8080e7          	jalr	-24(ra) # 8000331a <bwrite>
    if(recovering == 0)
    8000433a:	f80b1ce3          	bnez	s6,800042d2 <install_trans+0x36>
      bunpin(dbuf);
    8000433e:	8526                	mv	a0,s1
    80004340:	fffff097          	auipc	ra,0xfffff
    80004344:	0f2080e7          	jalr	242(ra) # 80003432 <bunpin>
    80004348:	b769                	j	800042d2 <install_trans+0x36>
}
    8000434a:	70e2                	ld	ra,56(sp)
    8000434c:	7442                	ld	s0,48(sp)
    8000434e:	74a2                	ld	s1,40(sp)
    80004350:	7902                	ld	s2,32(sp)
    80004352:	69e2                	ld	s3,24(sp)
    80004354:	6a42                	ld	s4,16(sp)
    80004356:	6aa2                	ld	s5,8(sp)
    80004358:	6b02                	ld	s6,0(sp)
    8000435a:	6121                	addi	sp,sp,64
    8000435c:	8082                	ret
    8000435e:	8082                	ret

0000000080004360 <initlog>:
{
    80004360:	7179                	addi	sp,sp,-48
    80004362:	f406                	sd	ra,40(sp)
    80004364:	f022                	sd	s0,32(sp)
    80004366:	ec26                	sd	s1,24(sp)
    80004368:	e84a                	sd	s2,16(sp)
    8000436a:	e44e                	sd	s3,8(sp)
    8000436c:	1800                	addi	s0,sp,48
    8000436e:	892a                	mv	s2,a0
    80004370:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004372:	0001e497          	auipc	s1,0x1e
    80004376:	a3e48493          	addi	s1,s1,-1474 # 80021db0 <log>
    8000437a:	00004597          	auipc	a1,0x4
    8000437e:	2d658593          	addi	a1,a1,726 # 80008650 <syscalls+0x200>
    80004382:	8526                	mv	a0,s1
    80004384:	ffffc097          	auipc	ra,0xffffc
    80004388:	7c2080e7          	jalr	1986(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000438c:	0149a583          	lw	a1,20(s3)
    80004390:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004392:	0109a783          	lw	a5,16(s3)
    80004396:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004398:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000439c:	854a                	mv	a0,s2
    8000439e:	fffff097          	auipc	ra,0xfffff
    800043a2:	e8a080e7          	jalr	-374(ra) # 80003228 <bread>
  log.lh.n = lh->n;
    800043a6:	4d34                	lw	a3,88(a0)
    800043a8:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800043aa:	02d05563          	blez	a3,800043d4 <initlog+0x74>
    800043ae:	05c50793          	addi	a5,a0,92
    800043b2:	0001e717          	auipc	a4,0x1e
    800043b6:	a2e70713          	addi	a4,a4,-1490 # 80021de0 <log+0x30>
    800043ba:	36fd                	addiw	a3,a3,-1
    800043bc:	1682                	slli	a3,a3,0x20
    800043be:	9281                	srli	a3,a3,0x20
    800043c0:	068a                	slli	a3,a3,0x2
    800043c2:	06050613          	addi	a2,a0,96
    800043c6:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800043c8:	4390                	lw	a2,0(a5)
    800043ca:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043cc:	0791                	addi	a5,a5,4
    800043ce:	0711                	addi	a4,a4,4
    800043d0:	fed79ce3          	bne	a5,a3,800043c8 <initlog+0x68>
  brelse(buf);
    800043d4:	fffff097          	auipc	ra,0xfffff
    800043d8:	f84080e7          	jalr	-124(ra) # 80003358 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043dc:	4505                	li	a0,1
    800043de:	00000097          	auipc	ra,0x0
    800043e2:	ebe080e7          	jalr	-322(ra) # 8000429c <install_trans>
  log.lh.n = 0;
    800043e6:	0001e797          	auipc	a5,0x1e
    800043ea:	9e07ab23          	sw	zero,-1546(a5) # 80021ddc <log+0x2c>
  write_head(); // clear the log
    800043ee:	00000097          	auipc	ra,0x0
    800043f2:	e34080e7          	jalr	-460(ra) # 80004222 <write_head>
}
    800043f6:	70a2                	ld	ra,40(sp)
    800043f8:	7402                	ld	s0,32(sp)
    800043fa:	64e2                	ld	s1,24(sp)
    800043fc:	6942                	ld	s2,16(sp)
    800043fe:	69a2                	ld	s3,8(sp)
    80004400:	6145                	addi	sp,sp,48
    80004402:	8082                	ret

0000000080004404 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004404:	1101                	addi	sp,sp,-32
    80004406:	ec06                	sd	ra,24(sp)
    80004408:	e822                	sd	s0,16(sp)
    8000440a:	e426                	sd	s1,8(sp)
    8000440c:	e04a                	sd	s2,0(sp)
    8000440e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004410:	0001e517          	auipc	a0,0x1e
    80004414:	9a050513          	addi	a0,a0,-1632 # 80021db0 <log>
    80004418:	ffffc097          	auipc	ra,0xffffc
    8000441c:	7be080e7          	jalr	1982(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004420:	0001e497          	auipc	s1,0x1e
    80004424:	99048493          	addi	s1,s1,-1648 # 80021db0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004428:	4979                	li	s2,30
    8000442a:	a039                	j	80004438 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000442c:	85a6                	mv	a1,s1
    8000442e:	8526                	mv	a0,s1
    80004430:	ffffe097          	auipc	ra,0xffffe
    80004434:	c38080e7          	jalr	-968(ra) # 80002068 <sleep>
    if(log.committing){
    80004438:	50dc                	lw	a5,36(s1)
    8000443a:	fbed                	bnez	a5,8000442c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000443c:	509c                	lw	a5,32(s1)
    8000443e:	0017871b          	addiw	a4,a5,1
    80004442:	0007069b          	sext.w	a3,a4
    80004446:	0027179b          	slliw	a5,a4,0x2
    8000444a:	9fb9                	addw	a5,a5,a4
    8000444c:	0017979b          	slliw	a5,a5,0x1
    80004450:	54d8                	lw	a4,44(s1)
    80004452:	9fb9                	addw	a5,a5,a4
    80004454:	00f95963          	bge	s2,a5,80004466 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004458:	85a6                	mv	a1,s1
    8000445a:	8526                	mv	a0,s1
    8000445c:	ffffe097          	auipc	ra,0xffffe
    80004460:	c0c080e7          	jalr	-1012(ra) # 80002068 <sleep>
    80004464:	bfd1                	j	80004438 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004466:	0001e517          	auipc	a0,0x1e
    8000446a:	94a50513          	addi	a0,a0,-1718 # 80021db0 <log>
    8000446e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004470:	ffffd097          	auipc	ra,0xffffd
    80004474:	81a080e7          	jalr	-2022(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004478:	60e2                	ld	ra,24(sp)
    8000447a:	6442                	ld	s0,16(sp)
    8000447c:	64a2                	ld	s1,8(sp)
    8000447e:	6902                	ld	s2,0(sp)
    80004480:	6105                	addi	sp,sp,32
    80004482:	8082                	ret

0000000080004484 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004484:	7139                	addi	sp,sp,-64
    80004486:	fc06                	sd	ra,56(sp)
    80004488:	f822                	sd	s0,48(sp)
    8000448a:	f426                	sd	s1,40(sp)
    8000448c:	f04a                	sd	s2,32(sp)
    8000448e:	ec4e                	sd	s3,24(sp)
    80004490:	e852                	sd	s4,16(sp)
    80004492:	e456                	sd	s5,8(sp)
    80004494:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004496:	0001e497          	auipc	s1,0x1e
    8000449a:	91a48493          	addi	s1,s1,-1766 # 80021db0 <log>
    8000449e:	8526                	mv	a0,s1
    800044a0:	ffffc097          	auipc	ra,0xffffc
    800044a4:	736080e7          	jalr	1846(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800044a8:	509c                	lw	a5,32(s1)
    800044aa:	37fd                	addiw	a5,a5,-1
    800044ac:	0007891b          	sext.w	s2,a5
    800044b0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800044b2:	50dc                	lw	a5,36(s1)
    800044b4:	e7b9                	bnez	a5,80004502 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044b6:	04091e63          	bnez	s2,80004512 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800044ba:	0001e497          	auipc	s1,0x1e
    800044be:	8f648493          	addi	s1,s1,-1802 # 80021db0 <log>
    800044c2:	4785                	li	a5,1
    800044c4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044c6:	8526                	mv	a0,s1
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	7c2080e7          	jalr	1986(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044d0:	54dc                	lw	a5,44(s1)
    800044d2:	06f04763          	bgtz	a5,80004540 <end_op+0xbc>
    acquire(&log.lock);
    800044d6:	0001e497          	auipc	s1,0x1e
    800044da:	8da48493          	addi	s1,s1,-1830 # 80021db0 <log>
    800044de:	8526                	mv	a0,s1
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	6f6080e7          	jalr	1782(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800044e8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044ec:	8526                	mv	a0,s1
    800044ee:	ffffe097          	auipc	ra,0xffffe
    800044f2:	bde080e7          	jalr	-1058(ra) # 800020cc <wakeup>
    release(&log.lock);
    800044f6:	8526                	mv	a0,s1
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	792080e7          	jalr	1938(ra) # 80000c8a <release>
}
    80004500:	a03d                	j	8000452e <end_op+0xaa>
    panic("log.committing");
    80004502:	00004517          	auipc	a0,0x4
    80004506:	15650513          	addi	a0,a0,342 # 80008658 <syscalls+0x208>
    8000450a:	ffffc097          	auipc	ra,0xffffc
    8000450e:	034080e7          	jalr	52(ra) # 8000053e <panic>
    wakeup(&log);
    80004512:	0001e497          	auipc	s1,0x1e
    80004516:	89e48493          	addi	s1,s1,-1890 # 80021db0 <log>
    8000451a:	8526                	mv	a0,s1
    8000451c:	ffffe097          	auipc	ra,0xffffe
    80004520:	bb0080e7          	jalr	-1104(ra) # 800020cc <wakeup>
  release(&log.lock);
    80004524:	8526                	mv	a0,s1
    80004526:	ffffc097          	auipc	ra,0xffffc
    8000452a:	764080e7          	jalr	1892(ra) # 80000c8a <release>
}
    8000452e:	70e2                	ld	ra,56(sp)
    80004530:	7442                	ld	s0,48(sp)
    80004532:	74a2                	ld	s1,40(sp)
    80004534:	7902                	ld	s2,32(sp)
    80004536:	69e2                	ld	s3,24(sp)
    80004538:	6a42                	ld	s4,16(sp)
    8000453a:	6aa2                	ld	s5,8(sp)
    8000453c:	6121                	addi	sp,sp,64
    8000453e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004540:	0001ea97          	auipc	s5,0x1e
    80004544:	8a0a8a93          	addi	s5,s5,-1888 # 80021de0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004548:	0001ea17          	auipc	s4,0x1e
    8000454c:	868a0a13          	addi	s4,s4,-1944 # 80021db0 <log>
    80004550:	018a2583          	lw	a1,24(s4)
    80004554:	012585bb          	addw	a1,a1,s2
    80004558:	2585                	addiw	a1,a1,1
    8000455a:	028a2503          	lw	a0,40(s4)
    8000455e:	fffff097          	auipc	ra,0xfffff
    80004562:	cca080e7          	jalr	-822(ra) # 80003228 <bread>
    80004566:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004568:	000aa583          	lw	a1,0(s5)
    8000456c:	028a2503          	lw	a0,40(s4)
    80004570:	fffff097          	auipc	ra,0xfffff
    80004574:	cb8080e7          	jalr	-840(ra) # 80003228 <bread>
    80004578:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000457a:	40000613          	li	a2,1024
    8000457e:	05850593          	addi	a1,a0,88
    80004582:	05848513          	addi	a0,s1,88
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	7a8080e7          	jalr	1960(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000458e:	8526                	mv	a0,s1
    80004590:	fffff097          	auipc	ra,0xfffff
    80004594:	d8a080e7          	jalr	-630(ra) # 8000331a <bwrite>
    brelse(from);
    80004598:	854e                	mv	a0,s3
    8000459a:	fffff097          	auipc	ra,0xfffff
    8000459e:	dbe080e7          	jalr	-578(ra) # 80003358 <brelse>
    brelse(to);
    800045a2:	8526                	mv	a0,s1
    800045a4:	fffff097          	auipc	ra,0xfffff
    800045a8:	db4080e7          	jalr	-588(ra) # 80003358 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ac:	2905                	addiw	s2,s2,1
    800045ae:	0a91                	addi	s5,s5,4
    800045b0:	02ca2783          	lw	a5,44(s4)
    800045b4:	f8f94ee3          	blt	s2,a5,80004550 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800045b8:	00000097          	auipc	ra,0x0
    800045bc:	c6a080e7          	jalr	-918(ra) # 80004222 <write_head>
    install_trans(0); // Now install writes to home locations
    800045c0:	4501                	li	a0,0
    800045c2:	00000097          	auipc	ra,0x0
    800045c6:	cda080e7          	jalr	-806(ra) # 8000429c <install_trans>
    log.lh.n = 0;
    800045ca:	0001e797          	auipc	a5,0x1e
    800045ce:	8007a923          	sw	zero,-2030(a5) # 80021ddc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045d2:	00000097          	auipc	ra,0x0
    800045d6:	c50080e7          	jalr	-944(ra) # 80004222 <write_head>
    800045da:	bdf5                	j	800044d6 <end_op+0x52>

00000000800045dc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045dc:	1101                	addi	sp,sp,-32
    800045de:	ec06                	sd	ra,24(sp)
    800045e0:	e822                	sd	s0,16(sp)
    800045e2:	e426                	sd	s1,8(sp)
    800045e4:	e04a                	sd	s2,0(sp)
    800045e6:	1000                	addi	s0,sp,32
    800045e8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045ea:	0001d917          	auipc	s2,0x1d
    800045ee:	7c690913          	addi	s2,s2,1990 # 80021db0 <log>
    800045f2:	854a                	mv	a0,s2
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	5e2080e7          	jalr	1506(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045fc:	02c92603          	lw	a2,44(s2)
    80004600:	47f5                	li	a5,29
    80004602:	06c7c563          	blt	a5,a2,8000466c <log_write+0x90>
    80004606:	0001d797          	auipc	a5,0x1d
    8000460a:	7c67a783          	lw	a5,1990(a5) # 80021dcc <log+0x1c>
    8000460e:	37fd                	addiw	a5,a5,-1
    80004610:	04f65e63          	bge	a2,a5,8000466c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004614:	0001d797          	auipc	a5,0x1d
    80004618:	7bc7a783          	lw	a5,1980(a5) # 80021dd0 <log+0x20>
    8000461c:	06f05063          	blez	a5,8000467c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004620:	4781                	li	a5,0
    80004622:	06c05563          	blez	a2,8000468c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004626:	44cc                	lw	a1,12(s1)
    80004628:	0001d717          	auipc	a4,0x1d
    8000462c:	7b870713          	addi	a4,a4,1976 # 80021de0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004630:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004632:	4314                	lw	a3,0(a4)
    80004634:	04b68c63          	beq	a3,a1,8000468c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004638:	2785                	addiw	a5,a5,1
    8000463a:	0711                	addi	a4,a4,4
    8000463c:	fef61be3          	bne	a2,a5,80004632 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004640:	0621                	addi	a2,a2,8
    80004642:	060a                	slli	a2,a2,0x2
    80004644:	0001d797          	auipc	a5,0x1d
    80004648:	76c78793          	addi	a5,a5,1900 # 80021db0 <log>
    8000464c:	963e                	add	a2,a2,a5
    8000464e:	44dc                	lw	a5,12(s1)
    80004650:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004652:	8526                	mv	a0,s1
    80004654:	fffff097          	auipc	ra,0xfffff
    80004658:	da2080e7          	jalr	-606(ra) # 800033f6 <bpin>
    log.lh.n++;
    8000465c:	0001d717          	auipc	a4,0x1d
    80004660:	75470713          	addi	a4,a4,1876 # 80021db0 <log>
    80004664:	575c                	lw	a5,44(a4)
    80004666:	2785                	addiw	a5,a5,1
    80004668:	d75c                	sw	a5,44(a4)
    8000466a:	a835                	j	800046a6 <log_write+0xca>
    panic("too big a transaction");
    8000466c:	00004517          	auipc	a0,0x4
    80004670:	ffc50513          	addi	a0,a0,-4 # 80008668 <syscalls+0x218>
    80004674:	ffffc097          	auipc	ra,0xffffc
    80004678:	eca080e7          	jalr	-310(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000467c:	00004517          	auipc	a0,0x4
    80004680:	00450513          	addi	a0,a0,4 # 80008680 <syscalls+0x230>
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	eba080e7          	jalr	-326(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000468c:	00878713          	addi	a4,a5,8
    80004690:	00271693          	slli	a3,a4,0x2
    80004694:	0001d717          	auipc	a4,0x1d
    80004698:	71c70713          	addi	a4,a4,1820 # 80021db0 <log>
    8000469c:	9736                	add	a4,a4,a3
    8000469e:	44d4                	lw	a3,12(s1)
    800046a0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800046a2:	faf608e3          	beq	a2,a5,80004652 <log_write+0x76>
  }
  release(&log.lock);
    800046a6:	0001d517          	auipc	a0,0x1d
    800046aa:	70a50513          	addi	a0,a0,1802 # 80021db0 <log>
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	5dc080e7          	jalr	1500(ra) # 80000c8a <release>
}
    800046b6:	60e2                	ld	ra,24(sp)
    800046b8:	6442                	ld	s0,16(sp)
    800046ba:	64a2                	ld	s1,8(sp)
    800046bc:	6902                	ld	s2,0(sp)
    800046be:	6105                	addi	sp,sp,32
    800046c0:	8082                	ret

00000000800046c2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046c2:	1101                	addi	sp,sp,-32
    800046c4:	ec06                	sd	ra,24(sp)
    800046c6:	e822                	sd	s0,16(sp)
    800046c8:	e426                	sd	s1,8(sp)
    800046ca:	e04a                	sd	s2,0(sp)
    800046cc:	1000                	addi	s0,sp,32
    800046ce:	84aa                	mv	s1,a0
    800046d0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046d2:	00004597          	auipc	a1,0x4
    800046d6:	fce58593          	addi	a1,a1,-50 # 800086a0 <syscalls+0x250>
    800046da:	0521                	addi	a0,a0,8
    800046dc:	ffffc097          	auipc	ra,0xffffc
    800046e0:	46a080e7          	jalr	1130(ra) # 80000b46 <initlock>
  lk->name = name;
    800046e4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046e8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046ec:	0204a423          	sw	zero,40(s1)
}
    800046f0:	60e2                	ld	ra,24(sp)
    800046f2:	6442                	ld	s0,16(sp)
    800046f4:	64a2                	ld	s1,8(sp)
    800046f6:	6902                	ld	s2,0(sp)
    800046f8:	6105                	addi	sp,sp,32
    800046fa:	8082                	ret

00000000800046fc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046fc:	1101                	addi	sp,sp,-32
    800046fe:	ec06                	sd	ra,24(sp)
    80004700:	e822                	sd	s0,16(sp)
    80004702:	e426                	sd	s1,8(sp)
    80004704:	e04a                	sd	s2,0(sp)
    80004706:	1000                	addi	s0,sp,32
    80004708:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000470a:	00850913          	addi	s2,a0,8
    8000470e:	854a                	mv	a0,s2
    80004710:	ffffc097          	auipc	ra,0xffffc
    80004714:	4c6080e7          	jalr	1222(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004718:	409c                	lw	a5,0(s1)
    8000471a:	cb89                	beqz	a5,8000472c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000471c:	85ca                	mv	a1,s2
    8000471e:	8526                	mv	a0,s1
    80004720:	ffffe097          	auipc	ra,0xffffe
    80004724:	948080e7          	jalr	-1720(ra) # 80002068 <sleep>
  while (lk->locked) {
    80004728:	409c                	lw	a5,0(s1)
    8000472a:	fbed                	bnez	a5,8000471c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000472c:	4785                	li	a5,1
    8000472e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004730:	ffffd097          	auipc	ra,0xffffd
    80004734:	27c080e7          	jalr	636(ra) # 800019ac <myproc>
    80004738:	591c                	lw	a5,48(a0)
    8000473a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000473c:	854a                	mv	a0,s2
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	54c080e7          	jalr	1356(ra) # 80000c8a <release>
}
    80004746:	60e2                	ld	ra,24(sp)
    80004748:	6442                	ld	s0,16(sp)
    8000474a:	64a2                	ld	s1,8(sp)
    8000474c:	6902                	ld	s2,0(sp)
    8000474e:	6105                	addi	sp,sp,32
    80004750:	8082                	ret

0000000080004752 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004752:	1101                	addi	sp,sp,-32
    80004754:	ec06                	sd	ra,24(sp)
    80004756:	e822                	sd	s0,16(sp)
    80004758:	e426                	sd	s1,8(sp)
    8000475a:	e04a                	sd	s2,0(sp)
    8000475c:	1000                	addi	s0,sp,32
    8000475e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004760:	00850913          	addi	s2,a0,8
    80004764:	854a                	mv	a0,s2
    80004766:	ffffc097          	auipc	ra,0xffffc
    8000476a:	470080e7          	jalr	1136(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    8000476e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004772:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004776:	8526                	mv	a0,s1
    80004778:	ffffe097          	auipc	ra,0xffffe
    8000477c:	954080e7          	jalr	-1708(ra) # 800020cc <wakeup>
  release(&lk->lk);
    80004780:	854a                	mv	a0,s2
    80004782:	ffffc097          	auipc	ra,0xffffc
    80004786:	508080e7          	jalr	1288(ra) # 80000c8a <release>
}
    8000478a:	60e2                	ld	ra,24(sp)
    8000478c:	6442                	ld	s0,16(sp)
    8000478e:	64a2                	ld	s1,8(sp)
    80004790:	6902                	ld	s2,0(sp)
    80004792:	6105                	addi	sp,sp,32
    80004794:	8082                	ret

0000000080004796 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004796:	7179                	addi	sp,sp,-48
    80004798:	f406                	sd	ra,40(sp)
    8000479a:	f022                	sd	s0,32(sp)
    8000479c:	ec26                	sd	s1,24(sp)
    8000479e:	e84a                	sd	s2,16(sp)
    800047a0:	e44e                	sd	s3,8(sp)
    800047a2:	1800                	addi	s0,sp,48
    800047a4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800047a6:	00850913          	addi	s2,a0,8
    800047aa:	854a                	mv	a0,s2
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	42a080e7          	jalr	1066(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800047b4:	409c                	lw	a5,0(s1)
    800047b6:	ef99                	bnez	a5,800047d4 <holdingsleep+0x3e>
    800047b8:	4481                	li	s1,0
  release(&lk->lk);
    800047ba:	854a                	mv	a0,s2
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	4ce080e7          	jalr	1230(ra) # 80000c8a <release>
  return r;
}
    800047c4:	8526                	mv	a0,s1
    800047c6:	70a2                	ld	ra,40(sp)
    800047c8:	7402                	ld	s0,32(sp)
    800047ca:	64e2                	ld	s1,24(sp)
    800047cc:	6942                	ld	s2,16(sp)
    800047ce:	69a2                	ld	s3,8(sp)
    800047d0:	6145                	addi	sp,sp,48
    800047d2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047d4:	0284a983          	lw	s3,40(s1)
    800047d8:	ffffd097          	auipc	ra,0xffffd
    800047dc:	1d4080e7          	jalr	468(ra) # 800019ac <myproc>
    800047e0:	5904                	lw	s1,48(a0)
    800047e2:	413484b3          	sub	s1,s1,s3
    800047e6:	0014b493          	seqz	s1,s1
    800047ea:	bfc1                	j	800047ba <holdingsleep+0x24>

00000000800047ec <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047ec:	1141                	addi	sp,sp,-16
    800047ee:	e406                	sd	ra,8(sp)
    800047f0:	e022                	sd	s0,0(sp)
    800047f2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047f4:	00004597          	auipc	a1,0x4
    800047f8:	ebc58593          	addi	a1,a1,-324 # 800086b0 <syscalls+0x260>
    800047fc:	0001d517          	auipc	a0,0x1d
    80004800:	6fc50513          	addi	a0,a0,1788 # 80021ef8 <ftable>
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	342080e7          	jalr	834(ra) # 80000b46 <initlock>
}
    8000480c:	60a2                	ld	ra,8(sp)
    8000480e:	6402                	ld	s0,0(sp)
    80004810:	0141                	addi	sp,sp,16
    80004812:	8082                	ret

0000000080004814 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004814:	1101                	addi	sp,sp,-32
    80004816:	ec06                	sd	ra,24(sp)
    80004818:	e822                	sd	s0,16(sp)
    8000481a:	e426                	sd	s1,8(sp)
    8000481c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000481e:	0001d517          	auipc	a0,0x1d
    80004822:	6da50513          	addi	a0,a0,1754 # 80021ef8 <ftable>
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	3b0080e7          	jalr	944(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000482e:	0001d497          	auipc	s1,0x1d
    80004832:	6e248493          	addi	s1,s1,1762 # 80021f10 <ftable+0x18>
    80004836:	0001e717          	auipc	a4,0x1e
    8000483a:	67a70713          	addi	a4,a4,1658 # 80022eb0 <disk>
    if(f->ref == 0){
    8000483e:	40dc                	lw	a5,4(s1)
    80004840:	cf99                	beqz	a5,8000485e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004842:	02848493          	addi	s1,s1,40
    80004846:	fee49ce3          	bne	s1,a4,8000483e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000484a:	0001d517          	auipc	a0,0x1d
    8000484e:	6ae50513          	addi	a0,a0,1710 # 80021ef8 <ftable>
    80004852:	ffffc097          	auipc	ra,0xffffc
    80004856:	438080e7          	jalr	1080(ra) # 80000c8a <release>
  return 0;
    8000485a:	4481                	li	s1,0
    8000485c:	a819                	j	80004872 <filealloc+0x5e>
      f->ref = 1;
    8000485e:	4785                	li	a5,1
    80004860:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004862:	0001d517          	auipc	a0,0x1d
    80004866:	69650513          	addi	a0,a0,1686 # 80021ef8 <ftable>
    8000486a:	ffffc097          	auipc	ra,0xffffc
    8000486e:	420080e7          	jalr	1056(ra) # 80000c8a <release>
}
    80004872:	8526                	mv	a0,s1
    80004874:	60e2                	ld	ra,24(sp)
    80004876:	6442                	ld	s0,16(sp)
    80004878:	64a2                	ld	s1,8(sp)
    8000487a:	6105                	addi	sp,sp,32
    8000487c:	8082                	ret

000000008000487e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000487e:	1101                	addi	sp,sp,-32
    80004880:	ec06                	sd	ra,24(sp)
    80004882:	e822                	sd	s0,16(sp)
    80004884:	e426                	sd	s1,8(sp)
    80004886:	1000                	addi	s0,sp,32
    80004888:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000488a:	0001d517          	auipc	a0,0x1d
    8000488e:	66e50513          	addi	a0,a0,1646 # 80021ef8 <ftable>
    80004892:	ffffc097          	auipc	ra,0xffffc
    80004896:	344080e7          	jalr	836(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000489a:	40dc                	lw	a5,4(s1)
    8000489c:	02f05263          	blez	a5,800048c0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800048a0:	2785                	addiw	a5,a5,1
    800048a2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800048a4:	0001d517          	auipc	a0,0x1d
    800048a8:	65450513          	addi	a0,a0,1620 # 80021ef8 <ftable>
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	3de080e7          	jalr	990(ra) # 80000c8a <release>
  return f;
}
    800048b4:	8526                	mv	a0,s1
    800048b6:	60e2                	ld	ra,24(sp)
    800048b8:	6442                	ld	s0,16(sp)
    800048ba:	64a2                	ld	s1,8(sp)
    800048bc:	6105                	addi	sp,sp,32
    800048be:	8082                	ret
    panic("filedup");
    800048c0:	00004517          	auipc	a0,0x4
    800048c4:	df850513          	addi	a0,a0,-520 # 800086b8 <syscalls+0x268>
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	c76080e7          	jalr	-906(ra) # 8000053e <panic>

00000000800048d0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048d0:	7139                	addi	sp,sp,-64
    800048d2:	fc06                	sd	ra,56(sp)
    800048d4:	f822                	sd	s0,48(sp)
    800048d6:	f426                	sd	s1,40(sp)
    800048d8:	f04a                	sd	s2,32(sp)
    800048da:	ec4e                	sd	s3,24(sp)
    800048dc:	e852                	sd	s4,16(sp)
    800048de:	e456                	sd	s5,8(sp)
    800048e0:	0080                	addi	s0,sp,64
    800048e2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048e4:	0001d517          	auipc	a0,0x1d
    800048e8:	61450513          	addi	a0,a0,1556 # 80021ef8 <ftable>
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	2ea080e7          	jalr	746(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800048f4:	40dc                	lw	a5,4(s1)
    800048f6:	06f05163          	blez	a5,80004958 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048fa:	37fd                	addiw	a5,a5,-1
    800048fc:	0007871b          	sext.w	a4,a5
    80004900:	c0dc                	sw	a5,4(s1)
    80004902:	06e04363          	bgtz	a4,80004968 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004906:	0004a903          	lw	s2,0(s1)
    8000490a:	0094ca83          	lbu	s5,9(s1)
    8000490e:	0104ba03          	ld	s4,16(s1)
    80004912:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004916:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000491a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000491e:	0001d517          	auipc	a0,0x1d
    80004922:	5da50513          	addi	a0,a0,1498 # 80021ef8 <ftable>
    80004926:	ffffc097          	auipc	ra,0xffffc
    8000492a:	364080e7          	jalr	868(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    8000492e:	4785                	li	a5,1
    80004930:	04f90d63          	beq	s2,a5,8000498a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004934:	3979                	addiw	s2,s2,-2
    80004936:	4785                	li	a5,1
    80004938:	0527e063          	bltu	a5,s2,80004978 <fileclose+0xa8>
    begin_op();
    8000493c:	00000097          	auipc	ra,0x0
    80004940:	ac8080e7          	jalr	-1336(ra) # 80004404 <begin_op>
    iput(ff.ip);
    80004944:	854e                	mv	a0,s3
    80004946:	fffff097          	auipc	ra,0xfffff
    8000494a:	2b6080e7          	jalr	694(ra) # 80003bfc <iput>
    end_op();
    8000494e:	00000097          	auipc	ra,0x0
    80004952:	b36080e7          	jalr	-1226(ra) # 80004484 <end_op>
    80004956:	a00d                	j	80004978 <fileclose+0xa8>
    panic("fileclose");
    80004958:	00004517          	auipc	a0,0x4
    8000495c:	d6850513          	addi	a0,a0,-664 # 800086c0 <syscalls+0x270>
    80004960:	ffffc097          	auipc	ra,0xffffc
    80004964:	bde080e7          	jalr	-1058(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004968:	0001d517          	auipc	a0,0x1d
    8000496c:	59050513          	addi	a0,a0,1424 # 80021ef8 <ftable>
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	31a080e7          	jalr	794(ra) # 80000c8a <release>
  }
}
    80004978:	70e2                	ld	ra,56(sp)
    8000497a:	7442                	ld	s0,48(sp)
    8000497c:	74a2                	ld	s1,40(sp)
    8000497e:	7902                	ld	s2,32(sp)
    80004980:	69e2                	ld	s3,24(sp)
    80004982:	6a42                	ld	s4,16(sp)
    80004984:	6aa2                	ld	s5,8(sp)
    80004986:	6121                	addi	sp,sp,64
    80004988:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000498a:	85d6                	mv	a1,s5
    8000498c:	8552                	mv	a0,s4
    8000498e:	00000097          	auipc	ra,0x0
    80004992:	34c080e7          	jalr	844(ra) # 80004cda <pipeclose>
    80004996:	b7cd                	j	80004978 <fileclose+0xa8>

0000000080004998 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004998:	715d                	addi	sp,sp,-80
    8000499a:	e486                	sd	ra,72(sp)
    8000499c:	e0a2                	sd	s0,64(sp)
    8000499e:	fc26                	sd	s1,56(sp)
    800049a0:	f84a                	sd	s2,48(sp)
    800049a2:	f44e                	sd	s3,40(sp)
    800049a4:	0880                	addi	s0,sp,80
    800049a6:	84aa                	mv	s1,a0
    800049a8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800049aa:	ffffd097          	auipc	ra,0xffffd
    800049ae:	002080e7          	jalr	2(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800049b2:	409c                	lw	a5,0(s1)
    800049b4:	37f9                	addiw	a5,a5,-2
    800049b6:	4705                	li	a4,1
    800049b8:	04f76763          	bltu	a4,a5,80004a06 <filestat+0x6e>
    800049bc:	892a                	mv	s2,a0
    ilock(f->ip);
    800049be:	6c88                	ld	a0,24(s1)
    800049c0:	fffff097          	auipc	ra,0xfffff
    800049c4:	082080e7          	jalr	130(ra) # 80003a42 <ilock>
    stati(f->ip, &st);
    800049c8:	fb840593          	addi	a1,s0,-72
    800049cc:	6c88                	ld	a0,24(s1)
    800049ce:	fffff097          	auipc	ra,0xfffff
    800049d2:	2fe080e7          	jalr	766(ra) # 80003ccc <stati>
    iunlock(f->ip);
    800049d6:	6c88                	ld	a0,24(s1)
    800049d8:	fffff097          	auipc	ra,0xfffff
    800049dc:	12c080e7          	jalr	300(ra) # 80003b04 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049e0:	46e1                	li	a3,24
    800049e2:	fb840613          	addi	a2,s0,-72
    800049e6:	85ce                	mv	a1,s3
    800049e8:	05093503          	ld	a0,80(s2)
    800049ec:	ffffd097          	auipc	ra,0xffffd
    800049f0:	c7c080e7          	jalr	-900(ra) # 80001668 <copyout>
    800049f4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049f8:	60a6                	ld	ra,72(sp)
    800049fa:	6406                	ld	s0,64(sp)
    800049fc:	74e2                	ld	s1,56(sp)
    800049fe:	7942                	ld	s2,48(sp)
    80004a00:	79a2                	ld	s3,40(sp)
    80004a02:	6161                	addi	sp,sp,80
    80004a04:	8082                	ret
  return -1;
    80004a06:	557d                	li	a0,-1
    80004a08:	bfc5                	j	800049f8 <filestat+0x60>

0000000080004a0a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a0a:	7179                	addi	sp,sp,-48
    80004a0c:	f406                	sd	ra,40(sp)
    80004a0e:	f022                	sd	s0,32(sp)
    80004a10:	ec26                	sd	s1,24(sp)
    80004a12:	e84a                	sd	s2,16(sp)
    80004a14:	e44e                	sd	s3,8(sp)
    80004a16:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a18:	00854783          	lbu	a5,8(a0)
    80004a1c:	c3d5                	beqz	a5,80004ac0 <fileread+0xb6>
    80004a1e:	84aa                	mv	s1,a0
    80004a20:	89ae                	mv	s3,a1
    80004a22:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a24:	411c                	lw	a5,0(a0)
    80004a26:	4705                	li	a4,1
    80004a28:	04e78963          	beq	a5,a4,80004a7a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a2c:	470d                	li	a4,3
    80004a2e:	04e78d63          	beq	a5,a4,80004a88 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a32:	4709                	li	a4,2
    80004a34:	06e79e63          	bne	a5,a4,80004ab0 <fileread+0xa6>
    ilock(f->ip);
    80004a38:	6d08                	ld	a0,24(a0)
    80004a3a:	fffff097          	auipc	ra,0xfffff
    80004a3e:	008080e7          	jalr	8(ra) # 80003a42 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a42:	874a                	mv	a4,s2
    80004a44:	5094                	lw	a3,32(s1)
    80004a46:	864e                	mv	a2,s3
    80004a48:	4585                	li	a1,1
    80004a4a:	6c88                	ld	a0,24(s1)
    80004a4c:	fffff097          	auipc	ra,0xfffff
    80004a50:	2aa080e7          	jalr	682(ra) # 80003cf6 <readi>
    80004a54:	892a                	mv	s2,a0
    80004a56:	00a05563          	blez	a0,80004a60 <fileread+0x56>
      f->off += r;
    80004a5a:	509c                	lw	a5,32(s1)
    80004a5c:	9fa9                	addw	a5,a5,a0
    80004a5e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a60:	6c88                	ld	a0,24(s1)
    80004a62:	fffff097          	auipc	ra,0xfffff
    80004a66:	0a2080e7          	jalr	162(ra) # 80003b04 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a6a:	854a                	mv	a0,s2
    80004a6c:	70a2                	ld	ra,40(sp)
    80004a6e:	7402                	ld	s0,32(sp)
    80004a70:	64e2                	ld	s1,24(sp)
    80004a72:	6942                	ld	s2,16(sp)
    80004a74:	69a2                	ld	s3,8(sp)
    80004a76:	6145                	addi	sp,sp,48
    80004a78:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a7a:	6908                	ld	a0,16(a0)
    80004a7c:	00000097          	auipc	ra,0x0
    80004a80:	3c6080e7          	jalr	966(ra) # 80004e42 <piperead>
    80004a84:	892a                	mv	s2,a0
    80004a86:	b7d5                	j	80004a6a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a88:	02451783          	lh	a5,36(a0)
    80004a8c:	03079693          	slli	a3,a5,0x30
    80004a90:	92c1                	srli	a3,a3,0x30
    80004a92:	4725                	li	a4,9
    80004a94:	02d76863          	bltu	a4,a3,80004ac4 <fileread+0xba>
    80004a98:	0792                	slli	a5,a5,0x4
    80004a9a:	0001d717          	auipc	a4,0x1d
    80004a9e:	3be70713          	addi	a4,a4,958 # 80021e58 <devsw>
    80004aa2:	97ba                	add	a5,a5,a4
    80004aa4:	639c                	ld	a5,0(a5)
    80004aa6:	c38d                	beqz	a5,80004ac8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004aa8:	4505                	li	a0,1
    80004aaa:	9782                	jalr	a5
    80004aac:	892a                	mv	s2,a0
    80004aae:	bf75                	j	80004a6a <fileread+0x60>
    panic("fileread");
    80004ab0:	00004517          	auipc	a0,0x4
    80004ab4:	c2050513          	addi	a0,a0,-992 # 800086d0 <syscalls+0x280>
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	a86080e7          	jalr	-1402(ra) # 8000053e <panic>
    return -1;
    80004ac0:	597d                	li	s2,-1
    80004ac2:	b765                	j	80004a6a <fileread+0x60>
      return -1;
    80004ac4:	597d                	li	s2,-1
    80004ac6:	b755                	j	80004a6a <fileread+0x60>
    80004ac8:	597d                	li	s2,-1
    80004aca:	b745                	j	80004a6a <fileread+0x60>

0000000080004acc <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004acc:	715d                	addi	sp,sp,-80
    80004ace:	e486                	sd	ra,72(sp)
    80004ad0:	e0a2                	sd	s0,64(sp)
    80004ad2:	fc26                	sd	s1,56(sp)
    80004ad4:	f84a                	sd	s2,48(sp)
    80004ad6:	f44e                	sd	s3,40(sp)
    80004ad8:	f052                	sd	s4,32(sp)
    80004ada:	ec56                	sd	s5,24(sp)
    80004adc:	e85a                	sd	s6,16(sp)
    80004ade:	e45e                	sd	s7,8(sp)
    80004ae0:	e062                	sd	s8,0(sp)
    80004ae2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ae4:	00954783          	lbu	a5,9(a0)
    80004ae8:	10078663          	beqz	a5,80004bf4 <filewrite+0x128>
    80004aec:	892a                	mv	s2,a0
    80004aee:	8aae                	mv	s5,a1
    80004af0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004af2:	411c                	lw	a5,0(a0)
    80004af4:	4705                	li	a4,1
    80004af6:	02e78263          	beq	a5,a4,80004b1a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004afa:	470d                	li	a4,3
    80004afc:	02e78663          	beq	a5,a4,80004b28 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b00:	4709                	li	a4,2
    80004b02:	0ee79163          	bne	a5,a4,80004be4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b06:	0ac05d63          	blez	a2,80004bc0 <filewrite+0xf4>
    int i = 0;
    80004b0a:	4981                	li	s3,0
    80004b0c:	6b05                	lui	s6,0x1
    80004b0e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004b12:	6b85                	lui	s7,0x1
    80004b14:	c00b8b9b          	addiw	s7,s7,-1024
    80004b18:	a861                	j	80004bb0 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004b1a:	6908                	ld	a0,16(a0)
    80004b1c:	00000097          	auipc	ra,0x0
    80004b20:	22e080e7          	jalr	558(ra) # 80004d4a <pipewrite>
    80004b24:	8a2a                	mv	s4,a0
    80004b26:	a045                	j	80004bc6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b28:	02451783          	lh	a5,36(a0)
    80004b2c:	03079693          	slli	a3,a5,0x30
    80004b30:	92c1                	srli	a3,a3,0x30
    80004b32:	4725                	li	a4,9
    80004b34:	0cd76263          	bltu	a4,a3,80004bf8 <filewrite+0x12c>
    80004b38:	0792                	slli	a5,a5,0x4
    80004b3a:	0001d717          	auipc	a4,0x1d
    80004b3e:	31e70713          	addi	a4,a4,798 # 80021e58 <devsw>
    80004b42:	97ba                	add	a5,a5,a4
    80004b44:	679c                	ld	a5,8(a5)
    80004b46:	cbdd                	beqz	a5,80004bfc <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004b48:	4505                	li	a0,1
    80004b4a:	9782                	jalr	a5
    80004b4c:	8a2a                	mv	s4,a0
    80004b4e:	a8a5                	j	80004bc6 <filewrite+0xfa>
    80004b50:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b54:	00000097          	auipc	ra,0x0
    80004b58:	8b0080e7          	jalr	-1872(ra) # 80004404 <begin_op>
      ilock(f->ip);
    80004b5c:	01893503          	ld	a0,24(s2)
    80004b60:	fffff097          	auipc	ra,0xfffff
    80004b64:	ee2080e7          	jalr	-286(ra) # 80003a42 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b68:	8762                	mv	a4,s8
    80004b6a:	02092683          	lw	a3,32(s2)
    80004b6e:	01598633          	add	a2,s3,s5
    80004b72:	4585                	li	a1,1
    80004b74:	01893503          	ld	a0,24(s2)
    80004b78:	fffff097          	auipc	ra,0xfffff
    80004b7c:	276080e7          	jalr	630(ra) # 80003dee <writei>
    80004b80:	84aa                	mv	s1,a0
    80004b82:	00a05763          	blez	a0,80004b90 <filewrite+0xc4>
        f->off += r;
    80004b86:	02092783          	lw	a5,32(s2)
    80004b8a:	9fa9                	addw	a5,a5,a0
    80004b8c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b90:	01893503          	ld	a0,24(s2)
    80004b94:	fffff097          	auipc	ra,0xfffff
    80004b98:	f70080e7          	jalr	-144(ra) # 80003b04 <iunlock>
      end_op();
    80004b9c:	00000097          	auipc	ra,0x0
    80004ba0:	8e8080e7          	jalr	-1816(ra) # 80004484 <end_op>

      if(r != n1){
    80004ba4:	009c1f63          	bne	s8,s1,80004bc2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ba8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004bac:	0149db63          	bge	s3,s4,80004bc2 <filewrite+0xf6>
      int n1 = n - i;
    80004bb0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004bb4:	84be                	mv	s1,a5
    80004bb6:	2781                	sext.w	a5,a5
    80004bb8:	f8fb5ce3          	bge	s6,a5,80004b50 <filewrite+0x84>
    80004bbc:	84de                	mv	s1,s7
    80004bbe:	bf49                	j	80004b50 <filewrite+0x84>
    int i = 0;
    80004bc0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004bc2:	013a1f63          	bne	s4,s3,80004be0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004bc6:	8552                	mv	a0,s4
    80004bc8:	60a6                	ld	ra,72(sp)
    80004bca:	6406                	ld	s0,64(sp)
    80004bcc:	74e2                	ld	s1,56(sp)
    80004bce:	7942                	ld	s2,48(sp)
    80004bd0:	79a2                	ld	s3,40(sp)
    80004bd2:	7a02                	ld	s4,32(sp)
    80004bd4:	6ae2                	ld	s5,24(sp)
    80004bd6:	6b42                	ld	s6,16(sp)
    80004bd8:	6ba2                	ld	s7,8(sp)
    80004bda:	6c02                	ld	s8,0(sp)
    80004bdc:	6161                	addi	sp,sp,80
    80004bde:	8082                	ret
    ret = (i == n ? n : -1);
    80004be0:	5a7d                	li	s4,-1
    80004be2:	b7d5                	j	80004bc6 <filewrite+0xfa>
    panic("filewrite");
    80004be4:	00004517          	auipc	a0,0x4
    80004be8:	afc50513          	addi	a0,a0,-1284 # 800086e0 <syscalls+0x290>
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	952080e7          	jalr	-1710(ra) # 8000053e <panic>
    return -1;
    80004bf4:	5a7d                	li	s4,-1
    80004bf6:	bfc1                	j	80004bc6 <filewrite+0xfa>
      return -1;
    80004bf8:	5a7d                	li	s4,-1
    80004bfa:	b7f1                	j	80004bc6 <filewrite+0xfa>
    80004bfc:	5a7d                	li	s4,-1
    80004bfe:	b7e1                	j	80004bc6 <filewrite+0xfa>

0000000080004c00 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c00:	7179                	addi	sp,sp,-48
    80004c02:	f406                	sd	ra,40(sp)
    80004c04:	f022                	sd	s0,32(sp)
    80004c06:	ec26                	sd	s1,24(sp)
    80004c08:	e84a                	sd	s2,16(sp)
    80004c0a:	e44e                	sd	s3,8(sp)
    80004c0c:	e052                	sd	s4,0(sp)
    80004c0e:	1800                	addi	s0,sp,48
    80004c10:	84aa                	mv	s1,a0
    80004c12:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c14:	0005b023          	sd	zero,0(a1)
    80004c18:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c1c:	00000097          	auipc	ra,0x0
    80004c20:	bf8080e7          	jalr	-1032(ra) # 80004814 <filealloc>
    80004c24:	e088                	sd	a0,0(s1)
    80004c26:	c551                	beqz	a0,80004cb2 <pipealloc+0xb2>
    80004c28:	00000097          	auipc	ra,0x0
    80004c2c:	bec080e7          	jalr	-1044(ra) # 80004814 <filealloc>
    80004c30:	00aa3023          	sd	a0,0(s4)
    80004c34:	c92d                	beqz	a0,80004ca6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c36:	ffffc097          	auipc	ra,0xffffc
    80004c3a:	eb0080e7          	jalr	-336(ra) # 80000ae6 <kalloc>
    80004c3e:	892a                	mv	s2,a0
    80004c40:	c125                	beqz	a0,80004ca0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c42:	4985                	li	s3,1
    80004c44:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c48:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c4c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c50:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c54:	00004597          	auipc	a1,0x4
    80004c58:	a9c58593          	addi	a1,a1,-1380 # 800086f0 <syscalls+0x2a0>
    80004c5c:	ffffc097          	auipc	ra,0xffffc
    80004c60:	eea080e7          	jalr	-278(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004c64:	609c                	ld	a5,0(s1)
    80004c66:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c6a:	609c                	ld	a5,0(s1)
    80004c6c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c70:	609c                	ld	a5,0(s1)
    80004c72:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c76:	609c                	ld	a5,0(s1)
    80004c78:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c7c:	000a3783          	ld	a5,0(s4)
    80004c80:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c84:	000a3783          	ld	a5,0(s4)
    80004c88:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c8c:	000a3783          	ld	a5,0(s4)
    80004c90:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c94:	000a3783          	ld	a5,0(s4)
    80004c98:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c9c:	4501                	li	a0,0
    80004c9e:	a025                	j	80004cc6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ca0:	6088                	ld	a0,0(s1)
    80004ca2:	e501                	bnez	a0,80004caa <pipealloc+0xaa>
    80004ca4:	a039                	j	80004cb2 <pipealloc+0xb2>
    80004ca6:	6088                	ld	a0,0(s1)
    80004ca8:	c51d                	beqz	a0,80004cd6 <pipealloc+0xd6>
    fileclose(*f0);
    80004caa:	00000097          	auipc	ra,0x0
    80004cae:	c26080e7          	jalr	-986(ra) # 800048d0 <fileclose>
  if(*f1)
    80004cb2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004cb6:	557d                	li	a0,-1
  if(*f1)
    80004cb8:	c799                	beqz	a5,80004cc6 <pipealloc+0xc6>
    fileclose(*f1);
    80004cba:	853e                	mv	a0,a5
    80004cbc:	00000097          	auipc	ra,0x0
    80004cc0:	c14080e7          	jalr	-1004(ra) # 800048d0 <fileclose>
  return -1;
    80004cc4:	557d                	li	a0,-1
}
    80004cc6:	70a2                	ld	ra,40(sp)
    80004cc8:	7402                	ld	s0,32(sp)
    80004cca:	64e2                	ld	s1,24(sp)
    80004ccc:	6942                	ld	s2,16(sp)
    80004cce:	69a2                	ld	s3,8(sp)
    80004cd0:	6a02                	ld	s4,0(sp)
    80004cd2:	6145                	addi	sp,sp,48
    80004cd4:	8082                	ret
  return -1;
    80004cd6:	557d                	li	a0,-1
    80004cd8:	b7fd                	j	80004cc6 <pipealloc+0xc6>

0000000080004cda <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004cda:	1101                	addi	sp,sp,-32
    80004cdc:	ec06                	sd	ra,24(sp)
    80004cde:	e822                	sd	s0,16(sp)
    80004ce0:	e426                	sd	s1,8(sp)
    80004ce2:	e04a                	sd	s2,0(sp)
    80004ce4:	1000                	addi	s0,sp,32
    80004ce6:	84aa                	mv	s1,a0
    80004ce8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cea:	ffffc097          	auipc	ra,0xffffc
    80004cee:	eec080e7          	jalr	-276(ra) # 80000bd6 <acquire>
  if(writable){
    80004cf2:	02090d63          	beqz	s2,80004d2c <pipeclose+0x52>
    pi->writeopen = 0;
    80004cf6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004cfa:	21848513          	addi	a0,s1,536
    80004cfe:	ffffd097          	auipc	ra,0xffffd
    80004d02:	3ce080e7          	jalr	974(ra) # 800020cc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d06:	2204b783          	ld	a5,544(s1)
    80004d0a:	eb95                	bnez	a5,80004d3e <pipeclose+0x64>
    release(&pi->lock);
    80004d0c:	8526                	mv	a0,s1
    80004d0e:	ffffc097          	auipc	ra,0xffffc
    80004d12:	f7c080e7          	jalr	-132(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004d16:	8526                	mv	a0,s1
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	cd2080e7          	jalr	-814(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004d20:	60e2                	ld	ra,24(sp)
    80004d22:	6442                	ld	s0,16(sp)
    80004d24:	64a2                	ld	s1,8(sp)
    80004d26:	6902                	ld	s2,0(sp)
    80004d28:	6105                	addi	sp,sp,32
    80004d2a:	8082                	ret
    pi->readopen = 0;
    80004d2c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d30:	21c48513          	addi	a0,s1,540
    80004d34:	ffffd097          	auipc	ra,0xffffd
    80004d38:	398080e7          	jalr	920(ra) # 800020cc <wakeup>
    80004d3c:	b7e9                	j	80004d06 <pipeclose+0x2c>
    release(&pi->lock);
    80004d3e:	8526                	mv	a0,s1
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	f4a080e7          	jalr	-182(ra) # 80000c8a <release>
}
    80004d48:	bfe1                	j	80004d20 <pipeclose+0x46>

0000000080004d4a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d4a:	711d                	addi	sp,sp,-96
    80004d4c:	ec86                	sd	ra,88(sp)
    80004d4e:	e8a2                	sd	s0,80(sp)
    80004d50:	e4a6                	sd	s1,72(sp)
    80004d52:	e0ca                	sd	s2,64(sp)
    80004d54:	fc4e                	sd	s3,56(sp)
    80004d56:	f852                	sd	s4,48(sp)
    80004d58:	f456                	sd	s5,40(sp)
    80004d5a:	f05a                	sd	s6,32(sp)
    80004d5c:	ec5e                	sd	s7,24(sp)
    80004d5e:	e862                	sd	s8,16(sp)
    80004d60:	1080                	addi	s0,sp,96
    80004d62:	84aa                	mv	s1,a0
    80004d64:	8aae                	mv	s5,a1
    80004d66:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d68:	ffffd097          	auipc	ra,0xffffd
    80004d6c:	c44080e7          	jalr	-956(ra) # 800019ac <myproc>
    80004d70:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d72:	8526                	mv	a0,s1
    80004d74:	ffffc097          	auipc	ra,0xffffc
    80004d78:	e62080e7          	jalr	-414(ra) # 80000bd6 <acquire>
  while(i < n){
    80004d7c:	0b405663          	blez	s4,80004e28 <pipewrite+0xde>
  int i = 0;
    80004d80:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d82:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d84:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d88:	21c48b93          	addi	s7,s1,540
    80004d8c:	a089                	j	80004dce <pipewrite+0x84>
      release(&pi->lock);
    80004d8e:	8526                	mv	a0,s1
    80004d90:	ffffc097          	auipc	ra,0xffffc
    80004d94:	efa080e7          	jalr	-262(ra) # 80000c8a <release>
      return -1;
    80004d98:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d9a:	854a                	mv	a0,s2
    80004d9c:	60e6                	ld	ra,88(sp)
    80004d9e:	6446                	ld	s0,80(sp)
    80004da0:	64a6                	ld	s1,72(sp)
    80004da2:	6906                	ld	s2,64(sp)
    80004da4:	79e2                	ld	s3,56(sp)
    80004da6:	7a42                	ld	s4,48(sp)
    80004da8:	7aa2                	ld	s5,40(sp)
    80004daa:	7b02                	ld	s6,32(sp)
    80004dac:	6be2                	ld	s7,24(sp)
    80004dae:	6c42                	ld	s8,16(sp)
    80004db0:	6125                	addi	sp,sp,96
    80004db2:	8082                	ret
      wakeup(&pi->nread);
    80004db4:	8562                	mv	a0,s8
    80004db6:	ffffd097          	auipc	ra,0xffffd
    80004dba:	316080e7          	jalr	790(ra) # 800020cc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004dbe:	85a6                	mv	a1,s1
    80004dc0:	855e                	mv	a0,s7
    80004dc2:	ffffd097          	auipc	ra,0xffffd
    80004dc6:	2a6080e7          	jalr	678(ra) # 80002068 <sleep>
  while(i < n){
    80004dca:	07495063          	bge	s2,s4,80004e2a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004dce:	2204a783          	lw	a5,544(s1)
    80004dd2:	dfd5                	beqz	a5,80004d8e <pipewrite+0x44>
    80004dd4:	854e                	mv	a0,s3
    80004dd6:	ffffd097          	auipc	ra,0xffffd
    80004dda:	546080e7          	jalr	1350(ra) # 8000231c <killed>
    80004dde:	f945                	bnez	a0,80004d8e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004de0:	2184a783          	lw	a5,536(s1)
    80004de4:	21c4a703          	lw	a4,540(s1)
    80004de8:	2007879b          	addiw	a5,a5,512
    80004dec:	fcf704e3          	beq	a4,a5,80004db4 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004df0:	4685                	li	a3,1
    80004df2:	01590633          	add	a2,s2,s5
    80004df6:	faf40593          	addi	a1,s0,-81
    80004dfa:	0509b503          	ld	a0,80(s3)
    80004dfe:	ffffd097          	auipc	ra,0xffffd
    80004e02:	8f6080e7          	jalr	-1802(ra) # 800016f4 <copyin>
    80004e06:	03650263          	beq	a0,s6,80004e2a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e0a:	21c4a783          	lw	a5,540(s1)
    80004e0e:	0017871b          	addiw	a4,a5,1
    80004e12:	20e4ae23          	sw	a4,540(s1)
    80004e16:	1ff7f793          	andi	a5,a5,511
    80004e1a:	97a6                	add	a5,a5,s1
    80004e1c:	faf44703          	lbu	a4,-81(s0)
    80004e20:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e24:	2905                	addiw	s2,s2,1
    80004e26:	b755                	j	80004dca <pipewrite+0x80>
  int i = 0;
    80004e28:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004e2a:	21848513          	addi	a0,s1,536
    80004e2e:	ffffd097          	auipc	ra,0xffffd
    80004e32:	29e080e7          	jalr	670(ra) # 800020cc <wakeup>
  release(&pi->lock);
    80004e36:	8526                	mv	a0,s1
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	e52080e7          	jalr	-430(ra) # 80000c8a <release>
  return i;
    80004e40:	bfa9                	j	80004d9a <pipewrite+0x50>

0000000080004e42 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e42:	715d                	addi	sp,sp,-80
    80004e44:	e486                	sd	ra,72(sp)
    80004e46:	e0a2                	sd	s0,64(sp)
    80004e48:	fc26                	sd	s1,56(sp)
    80004e4a:	f84a                	sd	s2,48(sp)
    80004e4c:	f44e                	sd	s3,40(sp)
    80004e4e:	f052                	sd	s4,32(sp)
    80004e50:	ec56                	sd	s5,24(sp)
    80004e52:	e85a                	sd	s6,16(sp)
    80004e54:	0880                	addi	s0,sp,80
    80004e56:	84aa                	mv	s1,a0
    80004e58:	892e                	mv	s2,a1
    80004e5a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e5c:	ffffd097          	auipc	ra,0xffffd
    80004e60:	b50080e7          	jalr	-1200(ra) # 800019ac <myproc>
    80004e64:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e66:	8526                	mv	a0,s1
    80004e68:	ffffc097          	auipc	ra,0xffffc
    80004e6c:	d6e080e7          	jalr	-658(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e70:	2184a703          	lw	a4,536(s1)
    80004e74:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e78:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e7c:	02f71763          	bne	a4,a5,80004eaa <piperead+0x68>
    80004e80:	2244a783          	lw	a5,548(s1)
    80004e84:	c39d                	beqz	a5,80004eaa <piperead+0x68>
    if(killed(pr)){
    80004e86:	8552                	mv	a0,s4
    80004e88:	ffffd097          	auipc	ra,0xffffd
    80004e8c:	494080e7          	jalr	1172(ra) # 8000231c <killed>
    80004e90:	e941                	bnez	a0,80004f20 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e92:	85a6                	mv	a1,s1
    80004e94:	854e                	mv	a0,s3
    80004e96:	ffffd097          	auipc	ra,0xffffd
    80004e9a:	1d2080e7          	jalr	466(ra) # 80002068 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e9e:	2184a703          	lw	a4,536(s1)
    80004ea2:	21c4a783          	lw	a5,540(s1)
    80004ea6:	fcf70de3          	beq	a4,a5,80004e80 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eaa:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004eac:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eae:	05505363          	blez	s5,80004ef4 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004eb2:	2184a783          	lw	a5,536(s1)
    80004eb6:	21c4a703          	lw	a4,540(s1)
    80004eba:	02f70d63          	beq	a4,a5,80004ef4 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ebe:	0017871b          	addiw	a4,a5,1
    80004ec2:	20e4ac23          	sw	a4,536(s1)
    80004ec6:	1ff7f793          	andi	a5,a5,511
    80004eca:	97a6                	add	a5,a5,s1
    80004ecc:	0187c783          	lbu	a5,24(a5)
    80004ed0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ed4:	4685                	li	a3,1
    80004ed6:	fbf40613          	addi	a2,s0,-65
    80004eda:	85ca                	mv	a1,s2
    80004edc:	050a3503          	ld	a0,80(s4)
    80004ee0:	ffffc097          	auipc	ra,0xffffc
    80004ee4:	788080e7          	jalr	1928(ra) # 80001668 <copyout>
    80004ee8:	01650663          	beq	a0,s6,80004ef4 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eec:	2985                	addiw	s3,s3,1
    80004eee:	0905                	addi	s2,s2,1
    80004ef0:	fd3a91e3          	bne	s5,s3,80004eb2 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ef4:	21c48513          	addi	a0,s1,540
    80004ef8:	ffffd097          	auipc	ra,0xffffd
    80004efc:	1d4080e7          	jalr	468(ra) # 800020cc <wakeup>
  release(&pi->lock);
    80004f00:	8526                	mv	a0,s1
    80004f02:	ffffc097          	auipc	ra,0xffffc
    80004f06:	d88080e7          	jalr	-632(ra) # 80000c8a <release>
  return i;
}
    80004f0a:	854e                	mv	a0,s3
    80004f0c:	60a6                	ld	ra,72(sp)
    80004f0e:	6406                	ld	s0,64(sp)
    80004f10:	74e2                	ld	s1,56(sp)
    80004f12:	7942                	ld	s2,48(sp)
    80004f14:	79a2                	ld	s3,40(sp)
    80004f16:	7a02                	ld	s4,32(sp)
    80004f18:	6ae2                	ld	s5,24(sp)
    80004f1a:	6b42                	ld	s6,16(sp)
    80004f1c:	6161                	addi	sp,sp,80
    80004f1e:	8082                	ret
      release(&pi->lock);
    80004f20:	8526                	mv	a0,s1
    80004f22:	ffffc097          	auipc	ra,0xffffc
    80004f26:	d68080e7          	jalr	-664(ra) # 80000c8a <release>
      return -1;
    80004f2a:	59fd                	li	s3,-1
    80004f2c:	bff9                	j	80004f0a <piperead+0xc8>

0000000080004f2e <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004f2e:	1141                	addi	sp,sp,-16
    80004f30:	e422                	sd	s0,8(sp)
    80004f32:	0800                	addi	s0,sp,16
    80004f34:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004f36:	8905                	andi	a0,a0,1
    80004f38:	c111                	beqz	a0,80004f3c <flags2perm+0xe>
      perm = PTE_X;
    80004f3a:	4521                	li	a0,8
    if(flags & 0x2)
    80004f3c:	8b89                	andi	a5,a5,2
    80004f3e:	c399                	beqz	a5,80004f44 <flags2perm+0x16>
      perm |= PTE_W;
    80004f40:	00456513          	ori	a0,a0,4
    return perm;
}
    80004f44:	6422                	ld	s0,8(sp)
    80004f46:	0141                	addi	sp,sp,16
    80004f48:	8082                	ret

0000000080004f4a <exec>:

int
exec(char *path, char **argv)
{
    80004f4a:	de010113          	addi	sp,sp,-544
    80004f4e:	20113c23          	sd	ra,536(sp)
    80004f52:	20813823          	sd	s0,528(sp)
    80004f56:	20913423          	sd	s1,520(sp)
    80004f5a:	21213023          	sd	s2,512(sp)
    80004f5e:	ffce                	sd	s3,504(sp)
    80004f60:	fbd2                	sd	s4,496(sp)
    80004f62:	f7d6                	sd	s5,488(sp)
    80004f64:	f3da                	sd	s6,480(sp)
    80004f66:	efde                	sd	s7,472(sp)
    80004f68:	ebe2                	sd	s8,464(sp)
    80004f6a:	e7e6                	sd	s9,456(sp)
    80004f6c:	e3ea                	sd	s10,448(sp)
    80004f6e:	ff6e                	sd	s11,440(sp)
    80004f70:	1400                	addi	s0,sp,544
    80004f72:	892a                	mv	s2,a0
    80004f74:	dea43423          	sd	a0,-536(s0)
    80004f78:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f7c:	ffffd097          	auipc	ra,0xffffd
    80004f80:	a30080e7          	jalr	-1488(ra) # 800019ac <myproc>
    80004f84:	84aa                	mv	s1,a0

  begin_op();
    80004f86:	fffff097          	auipc	ra,0xfffff
    80004f8a:	47e080e7          	jalr	1150(ra) # 80004404 <begin_op>

  if((ip = namei(path)) == 0){
    80004f8e:	854a                	mv	a0,s2
    80004f90:	fffff097          	auipc	ra,0xfffff
    80004f94:	258080e7          	jalr	600(ra) # 800041e8 <namei>
    80004f98:	c93d                	beqz	a0,8000500e <exec+0xc4>
    80004f9a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f9c:	fffff097          	auipc	ra,0xfffff
    80004fa0:	aa6080e7          	jalr	-1370(ra) # 80003a42 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004fa4:	04000713          	li	a4,64
    80004fa8:	4681                	li	a3,0
    80004faa:	e5040613          	addi	a2,s0,-432
    80004fae:	4581                	li	a1,0
    80004fb0:	8556                	mv	a0,s5
    80004fb2:	fffff097          	auipc	ra,0xfffff
    80004fb6:	d44080e7          	jalr	-700(ra) # 80003cf6 <readi>
    80004fba:	04000793          	li	a5,64
    80004fbe:	00f51a63          	bne	a0,a5,80004fd2 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004fc2:	e5042703          	lw	a4,-432(s0)
    80004fc6:	464c47b7          	lui	a5,0x464c4
    80004fca:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004fce:	04f70663          	beq	a4,a5,8000501a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004fd2:	8556                	mv	a0,s5
    80004fd4:	fffff097          	auipc	ra,0xfffff
    80004fd8:	cd0080e7          	jalr	-816(ra) # 80003ca4 <iunlockput>
    end_op();
    80004fdc:	fffff097          	auipc	ra,0xfffff
    80004fe0:	4a8080e7          	jalr	1192(ra) # 80004484 <end_op>
  }
  return -1;
    80004fe4:	557d                	li	a0,-1
}
    80004fe6:	21813083          	ld	ra,536(sp)
    80004fea:	21013403          	ld	s0,528(sp)
    80004fee:	20813483          	ld	s1,520(sp)
    80004ff2:	20013903          	ld	s2,512(sp)
    80004ff6:	79fe                	ld	s3,504(sp)
    80004ff8:	7a5e                	ld	s4,496(sp)
    80004ffa:	7abe                	ld	s5,488(sp)
    80004ffc:	7b1e                	ld	s6,480(sp)
    80004ffe:	6bfe                	ld	s7,472(sp)
    80005000:	6c5e                	ld	s8,464(sp)
    80005002:	6cbe                	ld	s9,456(sp)
    80005004:	6d1e                	ld	s10,448(sp)
    80005006:	7dfa                	ld	s11,440(sp)
    80005008:	22010113          	addi	sp,sp,544
    8000500c:	8082                	ret
    end_op();
    8000500e:	fffff097          	auipc	ra,0xfffff
    80005012:	476080e7          	jalr	1142(ra) # 80004484 <end_op>
    return -1;
    80005016:	557d                	li	a0,-1
    80005018:	b7f9                	j	80004fe6 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000501a:	8526                	mv	a0,s1
    8000501c:	ffffd097          	auipc	ra,0xffffd
    80005020:	a54080e7          	jalr	-1452(ra) # 80001a70 <proc_pagetable>
    80005024:	8b2a                	mv	s6,a0
    80005026:	d555                	beqz	a0,80004fd2 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005028:	e7042783          	lw	a5,-400(s0)
    8000502c:	e8845703          	lhu	a4,-376(s0)
    80005030:	c735                	beqz	a4,8000509c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005032:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005034:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005038:	6a05                	lui	s4,0x1
    8000503a:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000503e:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005042:	6d85                	lui	s11,0x1
    80005044:	7d7d                	lui	s10,0xfffff
    80005046:	a481                	j	80005286 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005048:	00003517          	auipc	a0,0x3
    8000504c:	6b050513          	addi	a0,a0,1712 # 800086f8 <syscalls+0x2a8>
    80005050:	ffffb097          	auipc	ra,0xffffb
    80005054:	4ee080e7          	jalr	1262(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005058:	874a                	mv	a4,s2
    8000505a:	009c86bb          	addw	a3,s9,s1
    8000505e:	4581                	li	a1,0
    80005060:	8556                	mv	a0,s5
    80005062:	fffff097          	auipc	ra,0xfffff
    80005066:	c94080e7          	jalr	-876(ra) # 80003cf6 <readi>
    8000506a:	2501                	sext.w	a0,a0
    8000506c:	1aa91a63          	bne	s2,a0,80005220 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80005070:	009d84bb          	addw	s1,s11,s1
    80005074:	013d09bb          	addw	s3,s10,s3
    80005078:	1f74f763          	bgeu	s1,s7,80005266 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    8000507c:	02049593          	slli	a1,s1,0x20
    80005080:	9181                	srli	a1,a1,0x20
    80005082:	95e2                	add	a1,a1,s8
    80005084:	855a                	mv	a0,s6
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	fd6080e7          	jalr	-42(ra) # 8000105c <walkaddr>
    8000508e:	862a                	mv	a2,a0
    if(pa == 0)
    80005090:	dd45                	beqz	a0,80005048 <exec+0xfe>
      n = PGSIZE;
    80005092:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005094:	fd49f2e3          	bgeu	s3,s4,80005058 <exec+0x10e>
      n = sz - i;
    80005098:	894e                	mv	s2,s3
    8000509a:	bf7d                	j	80005058 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000509c:	4901                	li	s2,0
  iunlockput(ip);
    8000509e:	8556                	mv	a0,s5
    800050a0:	fffff097          	auipc	ra,0xfffff
    800050a4:	c04080e7          	jalr	-1020(ra) # 80003ca4 <iunlockput>
  end_op();
    800050a8:	fffff097          	auipc	ra,0xfffff
    800050ac:	3dc080e7          	jalr	988(ra) # 80004484 <end_op>
  p = myproc();
    800050b0:	ffffd097          	auipc	ra,0xffffd
    800050b4:	8fc080e7          	jalr	-1796(ra) # 800019ac <myproc>
    800050b8:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800050ba:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800050be:	6785                	lui	a5,0x1
    800050c0:	17fd                	addi	a5,a5,-1
    800050c2:	993e                	add	s2,s2,a5
    800050c4:	77fd                	lui	a5,0xfffff
    800050c6:	00f977b3          	and	a5,s2,a5
    800050ca:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800050ce:	4691                	li	a3,4
    800050d0:	6609                	lui	a2,0x2
    800050d2:	963e                	add	a2,a2,a5
    800050d4:	85be                	mv	a1,a5
    800050d6:	855a                	mv	a0,s6
    800050d8:	ffffc097          	auipc	ra,0xffffc
    800050dc:	338080e7          	jalr	824(ra) # 80001410 <uvmalloc>
    800050e0:	8c2a                	mv	s8,a0
  ip = 0;
    800050e2:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800050e4:	12050e63          	beqz	a0,80005220 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800050e8:	75f9                	lui	a1,0xffffe
    800050ea:	95aa                	add	a1,a1,a0
    800050ec:	855a                	mv	a0,s6
    800050ee:	ffffc097          	auipc	ra,0xffffc
    800050f2:	548080e7          	jalr	1352(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    800050f6:	7afd                	lui	s5,0xfffff
    800050f8:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800050fa:	df043783          	ld	a5,-528(s0)
    800050fe:	6388                	ld	a0,0(a5)
    80005100:	c925                	beqz	a0,80005170 <exec+0x226>
    80005102:	e9040993          	addi	s3,s0,-368
    80005106:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000510a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000510c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000510e:	ffffc097          	auipc	ra,0xffffc
    80005112:	d40080e7          	jalr	-704(ra) # 80000e4e <strlen>
    80005116:	0015079b          	addiw	a5,a0,1
    8000511a:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000511e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005122:	13596663          	bltu	s2,s5,8000524e <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005126:	df043d83          	ld	s11,-528(s0)
    8000512a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000512e:	8552                	mv	a0,s4
    80005130:	ffffc097          	auipc	ra,0xffffc
    80005134:	d1e080e7          	jalr	-738(ra) # 80000e4e <strlen>
    80005138:	0015069b          	addiw	a3,a0,1
    8000513c:	8652                	mv	a2,s4
    8000513e:	85ca                	mv	a1,s2
    80005140:	855a                	mv	a0,s6
    80005142:	ffffc097          	auipc	ra,0xffffc
    80005146:	526080e7          	jalr	1318(ra) # 80001668 <copyout>
    8000514a:	10054663          	bltz	a0,80005256 <exec+0x30c>
    ustack[argc] = sp;
    8000514e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005152:	0485                	addi	s1,s1,1
    80005154:	008d8793          	addi	a5,s11,8
    80005158:	def43823          	sd	a5,-528(s0)
    8000515c:	008db503          	ld	a0,8(s11)
    80005160:	c911                	beqz	a0,80005174 <exec+0x22a>
    if(argc >= MAXARG)
    80005162:	09a1                	addi	s3,s3,8
    80005164:	fb3c95e3          	bne	s9,s3,8000510e <exec+0x1c4>
  sz = sz1;
    80005168:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000516c:	4a81                	li	s5,0
    8000516e:	a84d                	j	80005220 <exec+0x2d6>
  sp = sz;
    80005170:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005172:	4481                	li	s1,0
  ustack[argc] = 0;
    80005174:	00349793          	slli	a5,s1,0x3
    80005178:	f9040713          	addi	a4,s0,-112
    8000517c:	97ba                	add	a5,a5,a4
    8000517e:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdbf10>
  sp -= (argc+1) * sizeof(uint64);
    80005182:	00148693          	addi	a3,s1,1
    80005186:	068e                	slli	a3,a3,0x3
    80005188:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000518c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005190:	01597663          	bgeu	s2,s5,8000519c <exec+0x252>
  sz = sz1;
    80005194:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005198:	4a81                	li	s5,0
    8000519a:	a059                	j	80005220 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000519c:	e9040613          	addi	a2,s0,-368
    800051a0:	85ca                	mv	a1,s2
    800051a2:	855a                	mv	a0,s6
    800051a4:	ffffc097          	auipc	ra,0xffffc
    800051a8:	4c4080e7          	jalr	1220(ra) # 80001668 <copyout>
    800051ac:	0a054963          	bltz	a0,8000525e <exec+0x314>
  p->trapframe->a1 = sp;
    800051b0:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800051b4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800051b8:	de843783          	ld	a5,-536(s0)
    800051bc:	0007c703          	lbu	a4,0(a5)
    800051c0:	cf11                	beqz	a4,800051dc <exec+0x292>
    800051c2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800051c4:	02f00693          	li	a3,47
    800051c8:	a039                	j	800051d6 <exec+0x28c>
      last = s+1;
    800051ca:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800051ce:	0785                	addi	a5,a5,1
    800051d0:	fff7c703          	lbu	a4,-1(a5)
    800051d4:	c701                	beqz	a4,800051dc <exec+0x292>
    if(*s == '/')
    800051d6:	fed71ce3          	bne	a4,a3,800051ce <exec+0x284>
    800051da:	bfc5                	j	800051ca <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800051dc:	4641                	li	a2,16
    800051de:	de843583          	ld	a1,-536(s0)
    800051e2:	158b8513          	addi	a0,s7,344
    800051e6:	ffffc097          	auipc	ra,0xffffc
    800051ea:	c36080e7          	jalr	-970(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800051ee:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800051f2:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800051f6:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051fa:	058bb783          	ld	a5,88(s7)
    800051fe:	e6843703          	ld	a4,-408(s0)
    80005202:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005204:	058bb783          	ld	a5,88(s7)
    80005208:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000520c:	85ea                	mv	a1,s10
    8000520e:	ffffd097          	auipc	ra,0xffffd
    80005212:	8fe080e7          	jalr	-1794(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005216:	0004851b          	sext.w	a0,s1
    8000521a:	b3f1                	j	80004fe6 <exec+0x9c>
    8000521c:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005220:	df843583          	ld	a1,-520(s0)
    80005224:	855a                	mv	a0,s6
    80005226:	ffffd097          	auipc	ra,0xffffd
    8000522a:	8e6080e7          	jalr	-1818(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    8000522e:	da0a92e3          	bnez	s5,80004fd2 <exec+0x88>
  return -1;
    80005232:	557d                	li	a0,-1
    80005234:	bb4d                	j	80004fe6 <exec+0x9c>
    80005236:	df243c23          	sd	s2,-520(s0)
    8000523a:	b7dd                	j	80005220 <exec+0x2d6>
    8000523c:	df243c23          	sd	s2,-520(s0)
    80005240:	b7c5                	j	80005220 <exec+0x2d6>
    80005242:	df243c23          	sd	s2,-520(s0)
    80005246:	bfe9                	j	80005220 <exec+0x2d6>
    80005248:	df243c23          	sd	s2,-520(s0)
    8000524c:	bfd1                	j	80005220 <exec+0x2d6>
  sz = sz1;
    8000524e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005252:	4a81                	li	s5,0
    80005254:	b7f1                	j	80005220 <exec+0x2d6>
  sz = sz1;
    80005256:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000525a:	4a81                	li	s5,0
    8000525c:	b7d1                	j	80005220 <exec+0x2d6>
  sz = sz1;
    8000525e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005262:	4a81                	li	s5,0
    80005264:	bf75                	j	80005220 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005266:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000526a:	e0843783          	ld	a5,-504(s0)
    8000526e:	0017869b          	addiw	a3,a5,1
    80005272:	e0d43423          	sd	a3,-504(s0)
    80005276:	e0043783          	ld	a5,-512(s0)
    8000527a:	0387879b          	addiw	a5,a5,56
    8000527e:	e8845703          	lhu	a4,-376(s0)
    80005282:	e0e6dee3          	bge	a3,a4,8000509e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005286:	2781                	sext.w	a5,a5
    80005288:	e0f43023          	sd	a5,-512(s0)
    8000528c:	03800713          	li	a4,56
    80005290:	86be                	mv	a3,a5
    80005292:	e1840613          	addi	a2,s0,-488
    80005296:	4581                	li	a1,0
    80005298:	8556                	mv	a0,s5
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	a5c080e7          	jalr	-1444(ra) # 80003cf6 <readi>
    800052a2:	03800793          	li	a5,56
    800052a6:	f6f51be3          	bne	a0,a5,8000521c <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    800052aa:	e1842783          	lw	a5,-488(s0)
    800052ae:	4705                	li	a4,1
    800052b0:	fae79de3          	bne	a5,a4,8000526a <exec+0x320>
    if(ph.memsz < ph.filesz)
    800052b4:	e4043483          	ld	s1,-448(s0)
    800052b8:	e3843783          	ld	a5,-456(s0)
    800052bc:	f6f4ede3          	bltu	s1,a5,80005236 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800052c0:	e2843783          	ld	a5,-472(s0)
    800052c4:	94be                	add	s1,s1,a5
    800052c6:	f6f4ebe3          	bltu	s1,a5,8000523c <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    800052ca:	de043703          	ld	a4,-544(s0)
    800052ce:	8ff9                	and	a5,a5,a4
    800052d0:	fbad                	bnez	a5,80005242 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052d2:	e1c42503          	lw	a0,-484(s0)
    800052d6:	00000097          	auipc	ra,0x0
    800052da:	c58080e7          	jalr	-936(ra) # 80004f2e <flags2perm>
    800052de:	86aa                	mv	a3,a0
    800052e0:	8626                	mv	a2,s1
    800052e2:	85ca                	mv	a1,s2
    800052e4:	855a                	mv	a0,s6
    800052e6:	ffffc097          	auipc	ra,0xffffc
    800052ea:	12a080e7          	jalr	298(ra) # 80001410 <uvmalloc>
    800052ee:	dea43c23          	sd	a0,-520(s0)
    800052f2:	d939                	beqz	a0,80005248 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052f4:	e2843c03          	ld	s8,-472(s0)
    800052f8:	e2042c83          	lw	s9,-480(s0)
    800052fc:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005300:	f60b83e3          	beqz	s7,80005266 <exec+0x31c>
    80005304:	89de                	mv	s3,s7
    80005306:	4481                	li	s1,0
    80005308:	bb95                	j	8000507c <exec+0x132>

000000008000530a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000530a:	7179                	addi	sp,sp,-48
    8000530c:	f406                	sd	ra,40(sp)
    8000530e:	f022                	sd	s0,32(sp)
    80005310:	ec26                	sd	s1,24(sp)
    80005312:	e84a                	sd	s2,16(sp)
    80005314:	1800                	addi	s0,sp,48
    80005316:	892e                	mv	s2,a1
    80005318:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000531a:	fdc40593          	addi	a1,s0,-36
    8000531e:	ffffe097          	auipc	ra,0xffffe
    80005322:	9e2080e7          	jalr	-1566(ra) # 80002d00 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005326:	fdc42703          	lw	a4,-36(s0)
    8000532a:	47bd                	li	a5,15
    8000532c:	02e7eb63          	bltu	a5,a4,80005362 <argfd+0x58>
    80005330:	ffffc097          	auipc	ra,0xffffc
    80005334:	67c080e7          	jalr	1660(ra) # 800019ac <myproc>
    80005338:	fdc42703          	lw	a4,-36(s0)
    8000533c:	01a70793          	addi	a5,a4,26
    80005340:	078e                	slli	a5,a5,0x3
    80005342:	953e                	add	a0,a0,a5
    80005344:	611c                	ld	a5,0(a0)
    80005346:	c385                	beqz	a5,80005366 <argfd+0x5c>
    return -1;
  if(pfd)
    80005348:	00090463          	beqz	s2,80005350 <argfd+0x46>
    *pfd = fd;
    8000534c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005350:	4501                	li	a0,0
  if(pf)
    80005352:	c091                	beqz	s1,80005356 <argfd+0x4c>
    *pf = f;
    80005354:	e09c                	sd	a5,0(s1)
}
    80005356:	70a2                	ld	ra,40(sp)
    80005358:	7402                	ld	s0,32(sp)
    8000535a:	64e2                	ld	s1,24(sp)
    8000535c:	6942                	ld	s2,16(sp)
    8000535e:	6145                	addi	sp,sp,48
    80005360:	8082                	ret
    return -1;
    80005362:	557d                	li	a0,-1
    80005364:	bfcd                	j	80005356 <argfd+0x4c>
    80005366:	557d                	li	a0,-1
    80005368:	b7fd                	j	80005356 <argfd+0x4c>

000000008000536a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000536a:	1101                	addi	sp,sp,-32
    8000536c:	ec06                	sd	ra,24(sp)
    8000536e:	e822                	sd	s0,16(sp)
    80005370:	e426                	sd	s1,8(sp)
    80005372:	1000                	addi	s0,sp,32
    80005374:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005376:	ffffc097          	auipc	ra,0xffffc
    8000537a:	636080e7          	jalr	1590(ra) # 800019ac <myproc>
    8000537e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005380:	0d050793          	addi	a5,a0,208
    80005384:	4501                	li	a0,0
    80005386:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005388:	6398                	ld	a4,0(a5)
    8000538a:	cb19                	beqz	a4,800053a0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000538c:	2505                	addiw	a0,a0,1
    8000538e:	07a1                	addi	a5,a5,8
    80005390:	fed51ce3          	bne	a0,a3,80005388 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005394:	557d                	li	a0,-1
}
    80005396:	60e2                	ld	ra,24(sp)
    80005398:	6442                	ld	s0,16(sp)
    8000539a:	64a2                	ld	s1,8(sp)
    8000539c:	6105                	addi	sp,sp,32
    8000539e:	8082                	ret
      p->ofile[fd] = f;
    800053a0:	01a50793          	addi	a5,a0,26
    800053a4:	078e                	slli	a5,a5,0x3
    800053a6:	963e                	add	a2,a2,a5
    800053a8:	e204                	sd	s1,0(a2)
      return fd;
    800053aa:	b7f5                	j	80005396 <fdalloc+0x2c>

00000000800053ac <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800053ac:	715d                	addi	sp,sp,-80
    800053ae:	e486                	sd	ra,72(sp)
    800053b0:	e0a2                	sd	s0,64(sp)
    800053b2:	fc26                	sd	s1,56(sp)
    800053b4:	f84a                	sd	s2,48(sp)
    800053b6:	f44e                	sd	s3,40(sp)
    800053b8:	f052                	sd	s4,32(sp)
    800053ba:	ec56                	sd	s5,24(sp)
    800053bc:	e85a                	sd	s6,16(sp)
    800053be:	0880                	addi	s0,sp,80
    800053c0:	8b2e                	mv	s6,a1
    800053c2:	89b2                	mv	s3,a2
    800053c4:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800053c6:	fb040593          	addi	a1,s0,-80
    800053ca:	fffff097          	auipc	ra,0xfffff
    800053ce:	e3c080e7          	jalr	-452(ra) # 80004206 <nameiparent>
    800053d2:	84aa                	mv	s1,a0
    800053d4:	14050f63          	beqz	a0,80005532 <create+0x186>
    return 0;

  ilock(dp);
    800053d8:	ffffe097          	auipc	ra,0xffffe
    800053dc:	66a080e7          	jalr	1642(ra) # 80003a42 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053e0:	4601                	li	a2,0
    800053e2:	fb040593          	addi	a1,s0,-80
    800053e6:	8526                	mv	a0,s1
    800053e8:	fffff097          	auipc	ra,0xfffff
    800053ec:	b3e080e7          	jalr	-1218(ra) # 80003f26 <dirlookup>
    800053f0:	8aaa                	mv	s5,a0
    800053f2:	c931                	beqz	a0,80005446 <create+0x9a>
    iunlockput(dp);
    800053f4:	8526                	mv	a0,s1
    800053f6:	fffff097          	auipc	ra,0xfffff
    800053fa:	8ae080e7          	jalr	-1874(ra) # 80003ca4 <iunlockput>
    ilock(ip);
    800053fe:	8556                	mv	a0,s5
    80005400:	ffffe097          	auipc	ra,0xffffe
    80005404:	642080e7          	jalr	1602(ra) # 80003a42 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005408:	000b059b          	sext.w	a1,s6
    8000540c:	4789                	li	a5,2
    8000540e:	02f59563          	bne	a1,a5,80005438 <create+0x8c>
    80005412:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc054>
    80005416:	37f9                	addiw	a5,a5,-2
    80005418:	17c2                	slli	a5,a5,0x30
    8000541a:	93c1                	srli	a5,a5,0x30
    8000541c:	4705                	li	a4,1
    8000541e:	00f76d63          	bltu	a4,a5,80005438 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005422:	8556                	mv	a0,s5
    80005424:	60a6                	ld	ra,72(sp)
    80005426:	6406                	ld	s0,64(sp)
    80005428:	74e2                	ld	s1,56(sp)
    8000542a:	7942                	ld	s2,48(sp)
    8000542c:	79a2                	ld	s3,40(sp)
    8000542e:	7a02                	ld	s4,32(sp)
    80005430:	6ae2                	ld	s5,24(sp)
    80005432:	6b42                	ld	s6,16(sp)
    80005434:	6161                	addi	sp,sp,80
    80005436:	8082                	ret
    iunlockput(ip);
    80005438:	8556                	mv	a0,s5
    8000543a:	fffff097          	auipc	ra,0xfffff
    8000543e:	86a080e7          	jalr	-1942(ra) # 80003ca4 <iunlockput>
    return 0;
    80005442:	4a81                	li	s5,0
    80005444:	bff9                	j	80005422 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005446:	85da                	mv	a1,s6
    80005448:	4088                	lw	a0,0(s1)
    8000544a:	ffffe097          	auipc	ra,0xffffe
    8000544e:	45c080e7          	jalr	1116(ra) # 800038a6 <ialloc>
    80005452:	8a2a                	mv	s4,a0
    80005454:	c539                	beqz	a0,800054a2 <create+0xf6>
  ilock(ip);
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	5ec080e7          	jalr	1516(ra) # 80003a42 <ilock>
  ip->major = major;
    8000545e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005462:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005466:	4905                	li	s2,1
    80005468:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000546c:	8552                	mv	a0,s4
    8000546e:	ffffe097          	auipc	ra,0xffffe
    80005472:	50a080e7          	jalr	1290(ra) # 80003978 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005476:	000b059b          	sext.w	a1,s6
    8000547a:	03258b63          	beq	a1,s2,800054b0 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000547e:	004a2603          	lw	a2,4(s4)
    80005482:	fb040593          	addi	a1,s0,-80
    80005486:	8526                	mv	a0,s1
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	cae080e7          	jalr	-850(ra) # 80004136 <dirlink>
    80005490:	06054f63          	bltz	a0,8000550e <create+0x162>
  iunlockput(dp);
    80005494:	8526                	mv	a0,s1
    80005496:	fffff097          	auipc	ra,0xfffff
    8000549a:	80e080e7          	jalr	-2034(ra) # 80003ca4 <iunlockput>
  return ip;
    8000549e:	8ad2                	mv	s5,s4
    800054a0:	b749                	j	80005422 <create+0x76>
    iunlockput(dp);
    800054a2:	8526                	mv	a0,s1
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	800080e7          	jalr	-2048(ra) # 80003ca4 <iunlockput>
    return 0;
    800054ac:	8ad2                	mv	s5,s4
    800054ae:	bf95                	j	80005422 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800054b0:	004a2603          	lw	a2,4(s4)
    800054b4:	00003597          	auipc	a1,0x3
    800054b8:	26458593          	addi	a1,a1,612 # 80008718 <syscalls+0x2c8>
    800054bc:	8552                	mv	a0,s4
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	c78080e7          	jalr	-904(ra) # 80004136 <dirlink>
    800054c6:	04054463          	bltz	a0,8000550e <create+0x162>
    800054ca:	40d0                	lw	a2,4(s1)
    800054cc:	00003597          	auipc	a1,0x3
    800054d0:	25458593          	addi	a1,a1,596 # 80008720 <syscalls+0x2d0>
    800054d4:	8552                	mv	a0,s4
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	c60080e7          	jalr	-928(ra) # 80004136 <dirlink>
    800054de:	02054863          	bltz	a0,8000550e <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800054e2:	004a2603          	lw	a2,4(s4)
    800054e6:	fb040593          	addi	a1,s0,-80
    800054ea:	8526                	mv	a0,s1
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	c4a080e7          	jalr	-950(ra) # 80004136 <dirlink>
    800054f4:	00054d63          	bltz	a0,8000550e <create+0x162>
    dp->nlink++;  // for ".."
    800054f8:	04a4d783          	lhu	a5,74(s1)
    800054fc:	2785                	addiw	a5,a5,1
    800054fe:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005502:	8526                	mv	a0,s1
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	474080e7          	jalr	1140(ra) # 80003978 <iupdate>
    8000550c:	b761                	j	80005494 <create+0xe8>
  ip->nlink = 0;
    8000550e:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005512:	8552                	mv	a0,s4
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	464080e7          	jalr	1124(ra) # 80003978 <iupdate>
  iunlockput(ip);
    8000551c:	8552                	mv	a0,s4
    8000551e:	ffffe097          	auipc	ra,0xffffe
    80005522:	786080e7          	jalr	1926(ra) # 80003ca4 <iunlockput>
  iunlockput(dp);
    80005526:	8526                	mv	a0,s1
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	77c080e7          	jalr	1916(ra) # 80003ca4 <iunlockput>
  return 0;
    80005530:	bdcd                	j	80005422 <create+0x76>
    return 0;
    80005532:	8aaa                	mv	s5,a0
    80005534:	b5fd                	j	80005422 <create+0x76>

0000000080005536 <sys_dup>:
{
    80005536:	7179                	addi	sp,sp,-48
    80005538:	f406                	sd	ra,40(sp)
    8000553a:	f022                	sd	s0,32(sp)
    8000553c:	ec26                	sd	s1,24(sp)
    8000553e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005540:	fd840613          	addi	a2,s0,-40
    80005544:	4581                	li	a1,0
    80005546:	4501                	li	a0,0
    80005548:	00000097          	auipc	ra,0x0
    8000554c:	dc2080e7          	jalr	-574(ra) # 8000530a <argfd>
    return -1;
    80005550:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005552:	02054363          	bltz	a0,80005578 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005556:	fd843503          	ld	a0,-40(s0)
    8000555a:	00000097          	auipc	ra,0x0
    8000555e:	e10080e7          	jalr	-496(ra) # 8000536a <fdalloc>
    80005562:	84aa                	mv	s1,a0
    return -1;
    80005564:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005566:	00054963          	bltz	a0,80005578 <sys_dup+0x42>
  filedup(f);
    8000556a:	fd843503          	ld	a0,-40(s0)
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	310080e7          	jalr	784(ra) # 8000487e <filedup>
  return fd;
    80005576:	87a6                	mv	a5,s1
}
    80005578:	853e                	mv	a0,a5
    8000557a:	70a2                	ld	ra,40(sp)
    8000557c:	7402                	ld	s0,32(sp)
    8000557e:	64e2                	ld	s1,24(sp)
    80005580:	6145                	addi	sp,sp,48
    80005582:	8082                	ret

0000000080005584 <sys_read>:
{
    80005584:	7179                	addi	sp,sp,-48
    80005586:	f406                	sd	ra,40(sp)
    80005588:	f022                	sd	s0,32(sp)
    8000558a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000558c:	fd840593          	addi	a1,s0,-40
    80005590:	4505                	li	a0,1
    80005592:	ffffd097          	auipc	ra,0xffffd
    80005596:	78e080e7          	jalr	1934(ra) # 80002d20 <argaddr>
  argint(2, &n);
    8000559a:	fe440593          	addi	a1,s0,-28
    8000559e:	4509                	li	a0,2
    800055a0:	ffffd097          	auipc	ra,0xffffd
    800055a4:	760080e7          	jalr	1888(ra) # 80002d00 <argint>
  if(argfd(0, 0, &f) < 0)
    800055a8:	fe840613          	addi	a2,s0,-24
    800055ac:	4581                	li	a1,0
    800055ae:	4501                	li	a0,0
    800055b0:	00000097          	auipc	ra,0x0
    800055b4:	d5a080e7          	jalr	-678(ra) # 8000530a <argfd>
    800055b8:	87aa                	mv	a5,a0
    return -1;
    800055ba:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055bc:	0007cc63          	bltz	a5,800055d4 <sys_read+0x50>
  return fileread(f, p, n);
    800055c0:	fe442603          	lw	a2,-28(s0)
    800055c4:	fd843583          	ld	a1,-40(s0)
    800055c8:	fe843503          	ld	a0,-24(s0)
    800055cc:	fffff097          	auipc	ra,0xfffff
    800055d0:	43e080e7          	jalr	1086(ra) # 80004a0a <fileread>
}
    800055d4:	70a2                	ld	ra,40(sp)
    800055d6:	7402                	ld	s0,32(sp)
    800055d8:	6145                	addi	sp,sp,48
    800055da:	8082                	ret

00000000800055dc <sys_write>:
{
    800055dc:	7179                	addi	sp,sp,-48
    800055de:	f406                	sd	ra,40(sp)
    800055e0:	f022                	sd	s0,32(sp)
    800055e2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800055e4:	fd840593          	addi	a1,s0,-40
    800055e8:	4505                	li	a0,1
    800055ea:	ffffd097          	auipc	ra,0xffffd
    800055ee:	736080e7          	jalr	1846(ra) # 80002d20 <argaddr>
  argint(2, &n);
    800055f2:	fe440593          	addi	a1,s0,-28
    800055f6:	4509                	li	a0,2
    800055f8:	ffffd097          	auipc	ra,0xffffd
    800055fc:	708080e7          	jalr	1800(ra) # 80002d00 <argint>
  if(argfd(0, 0, &f) < 0)
    80005600:	fe840613          	addi	a2,s0,-24
    80005604:	4581                	li	a1,0
    80005606:	4501                	li	a0,0
    80005608:	00000097          	auipc	ra,0x0
    8000560c:	d02080e7          	jalr	-766(ra) # 8000530a <argfd>
    80005610:	87aa                	mv	a5,a0
    return -1;
    80005612:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005614:	0007cc63          	bltz	a5,8000562c <sys_write+0x50>
  return filewrite(f, p, n);
    80005618:	fe442603          	lw	a2,-28(s0)
    8000561c:	fd843583          	ld	a1,-40(s0)
    80005620:	fe843503          	ld	a0,-24(s0)
    80005624:	fffff097          	auipc	ra,0xfffff
    80005628:	4a8080e7          	jalr	1192(ra) # 80004acc <filewrite>
}
    8000562c:	70a2                	ld	ra,40(sp)
    8000562e:	7402                	ld	s0,32(sp)
    80005630:	6145                	addi	sp,sp,48
    80005632:	8082                	ret

0000000080005634 <sys_close>:
{
    80005634:	1101                	addi	sp,sp,-32
    80005636:	ec06                	sd	ra,24(sp)
    80005638:	e822                	sd	s0,16(sp)
    8000563a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000563c:	fe040613          	addi	a2,s0,-32
    80005640:	fec40593          	addi	a1,s0,-20
    80005644:	4501                	li	a0,0
    80005646:	00000097          	auipc	ra,0x0
    8000564a:	cc4080e7          	jalr	-828(ra) # 8000530a <argfd>
    return -1;
    8000564e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005650:	02054463          	bltz	a0,80005678 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005654:	ffffc097          	auipc	ra,0xffffc
    80005658:	358080e7          	jalr	856(ra) # 800019ac <myproc>
    8000565c:	fec42783          	lw	a5,-20(s0)
    80005660:	07e9                	addi	a5,a5,26
    80005662:	078e                	slli	a5,a5,0x3
    80005664:	97aa                	add	a5,a5,a0
    80005666:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000566a:	fe043503          	ld	a0,-32(s0)
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	262080e7          	jalr	610(ra) # 800048d0 <fileclose>
  return 0;
    80005676:	4781                	li	a5,0
}
    80005678:	853e                	mv	a0,a5
    8000567a:	60e2                	ld	ra,24(sp)
    8000567c:	6442                	ld	s0,16(sp)
    8000567e:	6105                	addi	sp,sp,32
    80005680:	8082                	ret

0000000080005682 <sys_fstat>:
{
    80005682:	1101                	addi	sp,sp,-32
    80005684:	ec06                	sd	ra,24(sp)
    80005686:	e822                	sd	s0,16(sp)
    80005688:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000568a:	fe040593          	addi	a1,s0,-32
    8000568e:	4505                	li	a0,1
    80005690:	ffffd097          	auipc	ra,0xffffd
    80005694:	690080e7          	jalr	1680(ra) # 80002d20 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005698:	fe840613          	addi	a2,s0,-24
    8000569c:	4581                	li	a1,0
    8000569e:	4501                	li	a0,0
    800056a0:	00000097          	auipc	ra,0x0
    800056a4:	c6a080e7          	jalr	-918(ra) # 8000530a <argfd>
    800056a8:	87aa                	mv	a5,a0
    return -1;
    800056aa:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056ac:	0007ca63          	bltz	a5,800056c0 <sys_fstat+0x3e>
  return filestat(f, st);
    800056b0:	fe043583          	ld	a1,-32(s0)
    800056b4:	fe843503          	ld	a0,-24(s0)
    800056b8:	fffff097          	auipc	ra,0xfffff
    800056bc:	2e0080e7          	jalr	736(ra) # 80004998 <filestat>
}
    800056c0:	60e2                	ld	ra,24(sp)
    800056c2:	6442                	ld	s0,16(sp)
    800056c4:	6105                	addi	sp,sp,32
    800056c6:	8082                	ret

00000000800056c8 <sys_link>:
{
    800056c8:	7169                	addi	sp,sp,-304
    800056ca:	f606                	sd	ra,296(sp)
    800056cc:	f222                	sd	s0,288(sp)
    800056ce:	ee26                	sd	s1,280(sp)
    800056d0:	ea4a                	sd	s2,272(sp)
    800056d2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056d4:	08000613          	li	a2,128
    800056d8:	ed040593          	addi	a1,s0,-304
    800056dc:	4501                	li	a0,0
    800056de:	ffffd097          	auipc	ra,0xffffd
    800056e2:	662080e7          	jalr	1634(ra) # 80002d40 <argstr>
    return -1;
    800056e6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056e8:	10054e63          	bltz	a0,80005804 <sys_link+0x13c>
    800056ec:	08000613          	li	a2,128
    800056f0:	f5040593          	addi	a1,s0,-176
    800056f4:	4505                	li	a0,1
    800056f6:	ffffd097          	auipc	ra,0xffffd
    800056fa:	64a080e7          	jalr	1610(ra) # 80002d40 <argstr>
    return -1;
    800056fe:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005700:	10054263          	bltz	a0,80005804 <sys_link+0x13c>
  begin_op();
    80005704:	fffff097          	auipc	ra,0xfffff
    80005708:	d00080e7          	jalr	-768(ra) # 80004404 <begin_op>
  if((ip = namei(old)) == 0){
    8000570c:	ed040513          	addi	a0,s0,-304
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	ad8080e7          	jalr	-1320(ra) # 800041e8 <namei>
    80005718:	84aa                	mv	s1,a0
    8000571a:	c551                	beqz	a0,800057a6 <sys_link+0xde>
  ilock(ip);
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	326080e7          	jalr	806(ra) # 80003a42 <ilock>
  if(ip->type == T_DIR){
    80005724:	04449703          	lh	a4,68(s1)
    80005728:	4785                	li	a5,1
    8000572a:	08f70463          	beq	a4,a5,800057b2 <sys_link+0xea>
  ip->nlink++;
    8000572e:	04a4d783          	lhu	a5,74(s1)
    80005732:	2785                	addiw	a5,a5,1
    80005734:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005738:	8526                	mv	a0,s1
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	23e080e7          	jalr	574(ra) # 80003978 <iupdate>
  iunlock(ip);
    80005742:	8526                	mv	a0,s1
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	3c0080e7          	jalr	960(ra) # 80003b04 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000574c:	fd040593          	addi	a1,s0,-48
    80005750:	f5040513          	addi	a0,s0,-176
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	ab2080e7          	jalr	-1358(ra) # 80004206 <nameiparent>
    8000575c:	892a                	mv	s2,a0
    8000575e:	c935                	beqz	a0,800057d2 <sys_link+0x10a>
  ilock(dp);
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	2e2080e7          	jalr	738(ra) # 80003a42 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005768:	00092703          	lw	a4,0(s2)
    8000576c:	409c                	lw	a5,0(s1)
    8000576e:	04f71d63          	bne	a4,a5,800057c8 <sys_link+0x100>
    80005772:	40d0                	lw	a2,4(s1)
    80005774:	fd040593          	addi	a1,s0,-48
    80005778:	854a                	mv	a0,s2
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	9bc080e7          	jalr	-1604(ra) # 80004136 <dirlink>
    80005782:	04054363          	bltz	a0,800057c8 <sys_link+0x100>
  iunlockput(dp);
    80005786:	854a                	mv	a0,s2
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	51c080e7          	jalr	1308(ra) # 80003ca4 <iunlockput>
  iput(ip);
    80005790:	8526                	mv	a0,s1
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	46a080e7          	jalr	1130(ra) # 80003bfc <iput>
  end_op();
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	cea080e7          	jalr	-790(ra) # 80004484 <end_op>
  return 0;
    800057a2:	4781                	li	a5,0
    800057a4:	a085                	j	80005804 <sys_link+0x13c>
    end_op();
    800057a6:	fffff097          	auipc	ra,0xfffff
    800057aa:	cde080e7          	jalr	-802(ra) # 80004484 <end_op>
    return -1;
    800057ae:	57fd                	li	a5,-1
    800057b0:	a891                	j	80005804 <sys_link+0x13c>
    iunlockput(ip);
    800057b2:	8526                	mv	a0,s1
    800057b4:	ffffe097          	auipc	ra,0xffffe
    800057b8:	4f0080e7          	jalr	1264(ra) # 80003ca4 <iunlockput>
    end_op();
    800057bc:	fffff097          	auipc	ra,0xfffff
    800057c0:	cc8080e7          	jalr	-824(ra) # 80004484 <end_op>
    return -1;
    800057c4:	57fd                	li	a5,-1
    800057c6:	a83d                	j	80005804 <sys_link+0x13c>
    iunlockput(dp);
    800057c8:	854a                	mv	a0,s2
    800057ca:	ffffe097          	auipc	ra,0xffffe
    800057ce:	4da080e7          	jalr	1242(ra) # 80003ca4 <iunlockput>
  ilock(ip);
    800057d2:	8526                	mv	a0,s1
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	26e080e7          	jalr	622(ra) # 80003a42 <ilock>
  ip->nlink--;
    800057dc:	04a4d783          	lhu	a5,74(s1)
    800057e0:	37fd                	addiw	a5,a5,-1
    800057e2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057e6:	8526                	mv	a0,s1
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	190080e7          	jalr	400(ra) # 80003978 <iupdate>
  iunlockput(ip);
    800057f0:	8526                	mv	a0,s1
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	4b2080e7          	jalr	1202(ra) # 80003ca4 <iunlockput>
  end_op();
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	c8a080e7          	jalr	-886(ra) # 80004484 <end_op>
  return -1;
    80005802:	57fd                	li	a5,-1
}
    80005804:	853e                	mv	a0,a5
    80005806:	70b2                	ld	ra,296(sp)
    80005808:	7412                	ld	s0,288(sp)
    8000580a:	64f2                	ld	s1,280(sp)
    8000580c:	6952                	ld	s2,272(sp)
    8000580e:	6155                	addi	sp,sp,304
    80005810:	8082                	ret

0000000080005812 <sys_unlink>:
{
    80005812:	7151                	addi	sp,sp,-240
    80005814:	f586                	sd	ra,232(sp)
    80005816:	f1a2                	sd	s0,224(sp)
    80005818:	eda6                	sd	s1,216(sp)
    8000581a:	e9ca                	sd	s2,208(sp)
    8000581c:	e5ce                	sd	s3,200(sp)
    8000581e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005820:	08000613          	li	a2,128
    80005824:	f3040593          	addi	a1,s0,-208
    80005828:	4501                	li	a0,0
    8000582a:	ffffd097          	auipc	ra,0xffffd
    8000582e:	516080e7          	jalr	1302(ra) # 80002d40 <argstr>
    80005832:	18054163          	bltz	a0,800059b4 <sys_unlink+0x1a2>
  begin_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	bce080e7          	jalr	-1074(ra) # 80004404 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000583e:	fb040593          	addi	a1,s0,-80
    80005842:	f3040513          	addi	a0,s0,-208
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	9c0080e7          	jalr	-1600(ra) # 80004206 <nameiparent>
    8000584e:	84aa                	mv	s1,a0
    80005850:	c979                	beqz	a0,80005926 <sys_unlink+0x114>
  ilock(dp);
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	1f0080e7          	jalr	496(ra) # 80003a42 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000585a:	00003597          	auipc	a1,0x3
    8000585e:	ebe58593          	addi	a1,a1,-322 # 80008718 <syscalls+0x2c8>
    80005862:	fb040513          	addi	a0,s0,-80
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	6a6080e7          	jalr	1702(ra) # 80003f0c <namecmp>
    8000586e:	14050a63          	beqz	a0,800059c2 <sys_unlink+0x1b0>
    80005872:	00003597          	auipc	a1,0x3
    80005876:	eae58593          	addi	a1,a1,-338 # 80008720 <syscalls+0x2d0>
    8000587a:	fb040513          	addi	a0,s0,-80
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	68e080e7          	jalr	1678(ra) # 80003f0c <namecmp>
    80005886:	12050e63          	beqz	a0,800059c2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000588a:	f2c40613          	addi	a2,s0,-212
    8000588e:	fb040593          	addi	a1,s0,-80
    80005892:	8526                	mv	a0,s1
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	692080e7          	jalr	1682(ra) # 80003f26 <dirlookup>
    8000589c:	892a                	mv	s2,a0
    8000589e:	12050263          	beqz	a0,800059c2 <sys_unlink+0x1b0>
  ilock(ip);
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	1a0080e7          	jalr	416(ra) # 80003a42 <ilock>
  if(ip->nlink < 1)
    800058aa:	04a91783          	lh	a5,74(s2)
    800058ae:	08f05263          	blez	a5,80005932 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800058b2:	04491703          	lh	a4,68(s2)
    800058b6:	4785                	li	a5,1
    800058b8:	08f70563          	beq	a4,a5,80005942 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800058bc:	4641                	li	a2,16
    800058be:	4581                	li	a1,0
    800058c0:	fc040513          	addi	a0,s0,-64
    800058c4:	ffffb097          	auipc	ra,0xffffb
    800058c8:	40e080e7          	jalr	1038(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058cc:	4741                	li	a4,16
    800058ce:	f2c42683          	lw	a3,-212(s0)
    800058d2:	fc040613          	addi	a2,s0,-64
    800058d6:	4581                	li	a1,0
    800058d8:	8526                	mv	a0,s1
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	514080e7          	jalr	1300(ra) # 80003dee <writei>
    800058e2:	47c1                	li	a5,16
    800058e4:	0af51563          	bne	a0,a5,8000598e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058e8:	04491703          	lh	a4,68(s2)
    800058ec:	4785                	li	a5,1
    800058ee:	0af70863          	beq	a4,a5,8000599e <sys_unlink+0x18c>
  iunlockput(dp);
    800058f2:	8526                	mv	a0,s1
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	3b0080e7          	jalr	944(ra) # 80003ca4 <iunlockput>
  ip->nlink--;
    800058fc:	04a95783          	lhu	a5,74(s2)
    80005900:	37fd                	addiw	a5,a5,-1
    80005902:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005906:	854a                	mv	a0,s2
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	070080e7          	jalr	112(ra) # 80003978 <iupdate>
  iunlockput(ip);
    80005910:	854a                	mv	a0,s2
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	392080e7          	jalr	914(ra) # 80003ca4 <iunlockput>
  end_op();
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	b6a080e7          	jalr	-1174(ra) # 80004484 <end_op>
  return 0;
    80005922:	4501                	li	a0,0
    80005924:	a84d                	j	800059d6 <sys_unlink+0x1c4>
    end_op();
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	b5e080e7          	jalr	-1186(ra) # 80004484 <end_op>
    return -1;
    8000592e:	557d                	li	a0,-1
    80005930:	a05d                	j	800059d6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005932:	00003517          	auipc	a0,0x3
    80005936:	df650513          	addi	a0,a0,-522 # 80008728 <syscalls+0x2d8>
    8000593a:	ffffb097          	auipc	ra,0xffffb
    8000593e:	c04080e7          	jalr	-1020(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005942:	04c92703          	lw	a4,76(s2)
    80005946:	02000793          	li	a5,32
    8000594a:	f6e7f9e3          	bgeu	a5,a4,800058bc <sys_unlink+0xaa>
    8000594e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005952:	4741                	li	a4,16
    80005954:	86ce                	mv	a3,s3
    80005956:	f1840613          	addi	a2,s0,-232
    8000595a:	4581                	li	a1,0
    8000595c:	854a                	mv	a0,s2
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	398080e7          	jalr	920(ra) # 80003cf6 <readi>
    80005966:	47c1                	li	a5,16
    80005968:	00f51b63          	bne	a0,a5,8000597e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000596c:	f1845783          	lhu	a5,-232(s0)
    80005970:	e7a1                	bnez	a5,800059b8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005972:	29c1                	addiw	s3,s3,16
    80005974:	04c92783          	lw	a5,76(s2)
    80005978:	fcf9ede3          	bltu	s3,a5,80005952 <sys_unlink+0x140>
    8000597c:	b781                	j	800058bc <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000597e:	00003517          	auipc	a0,0x3
    80005982:	dc250513          	addi	a0,a0,-574 # 80008740 <syscalls+0x2f0>
    80005986:	ffffb097          	auipc	ra,0xffffb
    8000598a:	bb8080e7          	jalr	-1096(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000598e:	00003517          	auipc	a0,0x3
    80005992:	dca50513          	addi	a0,a0,-566 # 80008758 <syscalls+0x308>
    80005996:	ffffb097          	auipc	ra,0xffffb
    8000599a:	ba8080e7          	jalr	-1112(ra) # 8000053e <panic>
    dp->nlink--;
    8000599e:	04a4d783          	lhu	a5,74(s1)
    800059a2:	37fd                	addiw	a5,a5,-1
    800059a4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800059a8:	8526                	mv	a0,s1
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	fce080e7          	jalr	-50(ra) # 80003978 <iupdate>
    800059b2:	b781                	j	800058f2 <sys_unlink+0xe0>
    return -1;
    800059b4:	557d                	li	a0,-1
    800059b6:	a005                	j	800059d6 <sys_unlink+0x1c4>
    iunlockput(ip);
    800059b8:	854a                	mv	a0,s2
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	2ea080e7          	jalr	746(ra) # 80003ca4 <iunlockput>
  iunlockput(dp);
    800059c2:	8526                	mv	a0,s1
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	2e0080e7          	jalr	736(ra) # 80003ca4 <iunlockput>
  end_op();
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	ab8080e7          	jalr	-1352(ra) # 80004484 <end_op>
  return -1;
    800059d4:	557d                	li	a0,-1
}
    800059d6:	70ae                	ld	ra,232(sp)
    800059d8:	740e                	ld	s0,224(sp)
    800059da:	64ee                	ld	s1,216(sp)
    800059dc:	694e                	ld	s2,208(sp)
    800059de:	69ae                	ld	s3,200(sp)
    800059e0:	616d                	addi	sp,sp,240
    800059e2:	8082                	ret

00000000800059e4 <sys_open>:

uint64
sys_open(void)
{
    800059e4:	7131                	addi	sp,sp,-192
    800059e6:	fd06                	sd	ra,184(sp)
    800059e8:	f922                	sd	s0,176(sp)
    800059ea:	f526                	sd	s1,168(sp)
    800059ec:	f14a                	sd	s2,160(sp)
    800059ee:	ed4e                	sd	s3,152(sp)
    800059f0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800059f2:	f4c40593          	addi	a1,s0,-180
    800059f6:	4505                	li	a0,1
    800059f8:	ffffd097          	auipc	ra,0xffffd
    800059fc:	308080e7          	jalr	776(ra) # 80002d00 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a00:	08000613          	li	a2,128
    80005a04:	f5040593          	addi	a1,s0,-176
    80005a08:	4501                	li	a0,0
    80005a0a:	ffffd097          	auipc	ra,0xffffd
    80005a0e:	336080e7          	jalr	822(ra) # 80002d40 <argstr>
    80005a12:	87aa                	mv	a5,a0
    return -1;
    80005a14:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a16:	0a07c963          	bltz	a5,80005ac8 <sys_open+0xe4>

  begin_op();
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	9ea080e7          	jalr	-1558(ra) # 80004404 <begin_op>

  if(omode & O_CREATE){
    80005a22:	f4c42783          	lw	a5,-180(s0)
    80005a26:	2007f793          	andi	a5,a5,512
    80005a2a:	cfc5                	beqz	a5,80005ae2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a2c:	4681                	li	a3,0
    80005a2e:	4601                	li	a2,0
    80005a30:	4589                	li	a1,2
    80005a32:	f5040513          	addi	a0,s0,-176
    80005a36:	00000097          	auipc	ra,0x0
    80005a3a:	976080e7          	jalr	-1674(ra) # 800053ac <create>
    80005a3e:	84aa                	mv	s1,a0
    if(ip == 0){
    80005a40:	c959                	beqz	a0,80005ad6 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a42:	04449703          	lh	a4,68(s1)
    80005a46:	478d                	li	a5,3
    80005a48:	00f71763          	bne	a4,a5,80005a56 <sys_open+0x72>
    80005a4c:	0464d703          	lhu	a4,70(s1)
    80005a50:	47a5                	li	a5,9
    80005a52:	0ce7ed63          	bltu	a5,a4,80005b2c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	dbe080e7          	jalr	-578(ra) # 80004814 <filealloc>
    80005a5e:	89aa                	mv	s3,a0
    80005a60:	10050363          	beqz	a0,80005b66 <sys_open+0x182>
    80005a64:	00000097          	auipc	ra,0x0
    80005a68:	906080e7          	jalr	-1786(ra) # 8000536a <fdalloc>
    80005a6c:	892a                	mv	s2,a0
    80005a6e:	0e054763          	bltz	a0,80005b5c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a72:	04449703          	lh	a4,68(s1)
    80005a76:	478d                	li	a5,3
    80005a78:	0cf70563          	beq	a4,a5,80005b42 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a7c:	4789                	li	a5,2
    80005a7e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a82:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a86:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a8a:	f4c42783          	lw	a5,-180(s0)
    80005a8e:	0017c713          	xori	a4,a5,1
    80005a92:	8b05                	andi	a4,a4,1
    80005a94:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a98:	0037f713          	andi	a4,a5,3
    80005a9c:	00e03733          	snez	a4,a4
    80005aa0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005aa4:	4007f793          	andi	a5,a5,1024
    80005aa8:	c791                	beqz	a5,80005ab4 <sys_open+0xd0>
    80005aaa:	04449703          	lh	a4,68(s1)
    80005aae:	4789                	li	a5,2
    80005ab0:	0af70063          	beq	a4,a5,80005b50 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ab4:	8526                	mv	a0,s1
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	04e080e7          	jalr	78(ra) # 80003b04 <iunlock>
  end_op();
    80005abe:	fffff097          	auipc	ra,0xfffff
    80005ac2:	9c6080e7          	jalr	-1594(ra) # 80004484 <end_op>

  return fd;
    80005ac6:	854a                	mv	a0,s2
}
    80005ac8:	70ea                	ld	ra,184(sp)
    80005aca:	744a                	ld	s0,176(sp)
    80005acc:	74aa                	ld	s1,168(sp)
    80005ace:	790a                	ld	s2,160(sp)
    80005ad0:	69ea                	ld	s3,152(sp)
    80005ad2:	6129                	addi	sp,sp,192
    80005ad4:	8082                	ret
      end_op();
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	9ae080e7          	jalr	-1618(ra) # 80004484 <end_op>
      return -1;
    80005ade:	557d                	li	a0,-1
    80005ae0:	b7e5                	j	80005ac8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ae2:	f5040513          	addi	a0,s0,-176
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	702080e7          	jalr	1794(ra) # 800041e8 <namei>
    80005aee:	84aa                	mv	s1,a0
    80005af0:	c905                	beqz	a0,80005b20 <sys_open+0x13c>
    ilock(ip);
    80005af2:	ffffe097          	auipc	ra,0xffffe
    80005af6:	f50080e7          	jalr	-176(ra) # 80003a42 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005afa:	04449703          	lh	a4,68(s1)
    80005afe:	4785                	li	a5,1
    80005b00:	f4f711e3          	bne	a4,a5,80005a42 <sys_open+0x5e>
    80005b04:	f4c42783          	lw	a5,-180(s0)
    80005b08:	d7b9                	beqz	a5,80005a56 <sys_open+0x72>
      iunlockput(ip);
    80005b0a:	8526                	mv	a0,s1
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	198080e7          	jalr	408(ra) # 80003ca4 <iunlockput>
      end_op();
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	970080e7          	jalr	-1680(ra) # 80004484 <end_op>
      return -1;
    80005b1c:	557d                	li	a0,-1
    80005b1e:	b76d                	j	80005ac8 <sys_open+0xe4>
      end_op();
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	964080e7          	jalr	-1692(ra) # 80004484 <end_op>
      return -1;
    80005b28:	557d                	li	a0,-1
    80005b2a:	bf79                	j	80005ac8 <sys_open+0xe4>
    iunlockput(ip);
    80005b2c:	8526                	mv	a0,s1
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	176080e7          	jalr	374(ra) # 80003ca4 <iunlockput>
    end_op();
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	94e080e7          	jalr	-1714(ra) # 80004484 <end_op>
    return -1;
    80005b3e:	557d                	li	a0,-1
    80005b40:	b761                	j	80005ac8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b42:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b46:	04649783          	lh	a5,70(s1)
    80005b4a:	02f99223          	sh	a5,36(s3)
    80005b4e:	bf25                	j	80005a86 <sys_open+0xa2>
    itrunc(ip);
    80005b50:	8526                	mv	a0,s1
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	ffe080e7          	jalr	-2(ra) # 80003b50 <itrunc>
    80005b5a:	bfa9                	j	80005ab4 <sys_open+0xd0>
      fileclose(f);
    80005b5c:	854e                	mv	a0,s3
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	d72080e7          	jalr	-654(ra) # 800048d0 <fileclose>
    iunlockput(ip);
    80005b66:	8526                	mv	a0,s1
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	13c080e7          	jalr	316(ra) # 80003ca4 <iunlockput>
    end_op();
    80005b70:	fffff097          	auipc	ra,0xfffff
    80005b74:	914080e7          	jalr	-1772(ra) # 80004484 <end_op>
    return -1;
    80005b78:	557d                	li	a0,-1
    80005b7a:	b7b9                	j	80005ac8 <sys_open+0xe4>

0000000080005b7c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b7c:	7175                	addi	sp,sp,-144
    80005b7e:	e506                	sd	ra,136(sp)
    80005b80:	e122                	sd	s0,128(sp)
    80005b82:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	880080e7          	jalr	-1920(ra) # 80004404 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b8c:	08000613          	li	a2,128
    80005b90:	f7040593          	addi	a1,s0,-144
    80005b94:	4501                	li	a0,0
    80005b96:	ffffd097          	auipc	ra,0xffffd
    80005b9a:	1aa080e7          	jalr	426(ra) # 80002d40 <argstr>
    80005b9e:	02054963          	bltz	a0,80005bd0 <sys_mkdir+0x54>
    80005ba2:	4681                	li	a3,0
    80005ba4:	4601                	li	a2,0
    80005ba6:	4585                	li	a1,1
    80005ba8:	f7040513          	addi	a0,s0,-144
    80005bac:	00000097          	auipc	ra,0x0
    80005bb0:	800080e7          	jalr	-2048(ra) # 800053ac <create>
    80005bb4:	cd11                	beqz	a0,80005bd0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	0ee080e7          	jalr	238(ra) # 80003ca4 <iunlockput>
  end_op();
    80005bbe:	fffff097          	auipc	ra,0xfffff
    80005bc2:	8c6080e7          	jalr	-1850(ra) # 80004484 <end_op>
  return 0;
    80005bc6:	4501                	li	a0,0
}
    80005bc8:	60aa                	ld	ra,136(sp)
    80005bca:	640a                	ld	s0,128(sp)
    80005bcc:	6149                	addi	sp,sp,144
    80005bce:	8082                	ret
    end_op();
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	8b4080e7          	jalr	-1868(ra) # 80004484 <end_op>
    return -1;
    80005bd8:	557d                	li	a0,-1
    80005bda:	b7fd                	j	80005bc8 <sys_mkdir+0x4c>

0000000080005bdc <sys_mknod>:

uint64
sys_mknod(void)
{
    80005bdc:	7135                	addi	sp,sp,-160
    80005bde:	ed06                	sd	ra,152(sp)
    80005be0:	e922                	sd	s0,144(sp)
    80005be2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005be4:	fffff097          	auipc	ra,0xfffff
    80005be8:	820080e7          	jalr	-2016(ra) # 80004404 <begin_op>
  argint(1, &major);
    80005bec:	f6c40593          	addi	a1,s0,-148
    80005bf0:	4505                	li	a0,1
    80005bf2:	ffffd097          	auipc	ra,0xffffd
    80005bf6:	10e080e7          	jalr	270(ra) # 80002d00 <argint>
  argint(2, &minor);
    80005bfa:	f6840593          	addi	a1,s0,-152
    80005bfe:	4509                	li	a0,2
    80005c00:	ffffd097          	auipc	ra,0xffffd
    80005c04:	100080e7          	jalr	256(ra) # 80002d00 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c08:	08000613          	li	a2,128
    80005c0c:	f7040593          	addi	a1,s0,-144
    80005c10:	4501                	li	a0,0
    80005c12:	ffffd097          	auipc	ra,0xffffd
    80005c16:	12e080e7          	jalr	302(ra) # 80002d40 <argstr>
    80005c1a:	02054b63          	bltz	a0,80005c50 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c1e:	f6841683          	lh	a3,-152(s0)
    80005c22:	f6c41603          	lh	a2,-148(s0)
    80005c26:	458d                	li	a1,3
    80005c28:	f7040513          	addi	a0,s0,-144
    80005c2c:	fffff097          	auipc	ra,0xfffff
    80005c30:	780080e7          	jalr	1920(ra) # 800053ac <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c34:	cd11                	beqz	a0,80005c50 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c36:	ffffe097          	auipc	ra,0xffffe
    80005c3a:	06e080e7          	jalr	110(ra) # 80003ca4 <iunlockput>
  end_op();
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	846080e7          	jalr	-1978(ra) # 80004484 <end_op>
  return 0;
    80005c46:	4501                	li	a0,0
}
    80005c48:	60ea                	ld	ra,152(sp)
    80005c4a:	644a                	ld	s0,144(sp)
    80005c4c:	610d                	addi	sp,sp,160
    80005c4e:	8082                	ret
    end_op();
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	834080e7          	jalr	-1996(ra) # 80004484 <end_op>
    return -1;
    80005c58:	557d                	li	a0,-1
    80005c5a:	b7fd                	j	80005c48 <sys_mknod+0x6c>

0000000080005c5c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c5c:	7135                	addi	sp,sp,-160
    80005c5e:	ed06                	sd	ra,152(sp)
    80005c60:	e922                	sd	s0,144(sp)
    80005c62:	e526                	sd	s1,136(sp)
    80005c64:	e14a                	sd	s2,128(sp)
    80005c66:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c68:	ffffc097          	auipc	ra,0xffffc
    80005c6c:	d44080e7          	jalr	-700(ra) # 800019ac <myproc>
    80005c70:	892a                	mv	s2,a0
  
  begin_op();
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	792080e7          	jalr	1938(ra) # 80004404 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c7a:	08000613          	li	a2,128
    80005c7e:	f6040593          	addi	a1,s0,-160
    80005c82:	4501                	li	a0,0
    80005c84:	ffffd097          	auipc	ra,0xffffd
    80005c88:	0bc080e7          	jalr	188(ra) # 80002d40 <argstr>
    80005c8c:	04054b63          	bltz	a0,80005ce2 <sys_chdir+0x86>
    80005c90:	f6040513          	addi	a0,s0,-160
    80005c94:	ffffe097          	auipc	ra,0xffffe
    80005c98:	554080e7          	jalr	1364(ra) # 800041e8 <namei>
    80005c9c:	84aa                	mv	s1,a0
    80005c9e:	c131                	beqz	a0,80005ce2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	da2080e7          	jalr	-606(ra) # 80003a42 <ilock>
  if(ip->type != T_DIR){
    80005ca8:	04449703          	lh	a4,68(s1)
    80005cac:	4785                	li	a5,1
    80005cae:	04f71063          	bne	a4,a5,80005cee <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005cb2:	8526                	mv	a0,s1
    80005cb4:	ffffe097          	auipc	ra,0xffffe
    80005cb8:	e50080e7          	jalr	-432(ra) # 80003b04 <iunlock>
  iput(p->cwd);
    80005cbc:	15093503          	ld	a0,336(s2)
    80005cc0:	ffffe097          	auipc	ra,0xffffe
    80005cc4:	f3c080e7          	jalr	-196(ra) # 80003bfc <iput>
  end_op();
    80005cc8:	ffffe097          	auipc	ra,0xffffe
    80005ccc:	7bc080e7          	jalr	1980(ra) # 80004484 <end_op>
  p->cwd = ip;
    80005cd0:	14993823          	sd	s1,336(s2)
  return 0;
    80005cd4:	4501                	li	a0,0
}
    80005cd6:	60ea                	ld	ra,152(sp)
    80005cd8:	644a                	ld	s0,144(sp)
    80005cda:	64aa                	ld	s1,136(sp)
    80005cdc:	690a                	ld	s2,128(sp)
    80005cde:	610d                	addi	sp,sp,160
    80005ce0:	8082                	ret
    end_op();
    80005ce2:	ffffe097          	auipc	ra,0xffffe
    80005ce6:	7a2080e7          	jalr	1954(ra) # 80004484 <end_op>
    return -1;
    80005cea:	557d                	li	a0,-1
    80005cec:	b7ed                	j	80005cd6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005cee:	8526                	mv	a0,s1
    80005cf0:	ffffe097          	auipc	ra,0xffffe
    80005cf4:	fb4080e7          	jalr	-76(ra) # 80003ca4 <iunlockput>
    end_op();
    80005cf8:	ffffe097          	auipc	ra,0xffffe
    80005cfc:	78c080e7          	jalr	1932(ra) # 80004484 <end_op>
    return -1;
    80005d00:	557d                	li	a0,-1
    80005d02:	bfd1                	j	80005cd6 <sys_chdir+0x7a>

0000000080005d04 <sys_exec>:

uint64
sys_exec(void)
{
    80005d04:	7145                	addi	sp,sp,-464
    80005d06:	e786                	sd	ra,456(sp)
    80005d08:	e3a2                	sd	s0,448(sp)
    80005d0a:	ff26                	sd	s1,440(sp)
    80005d0c:	fb4a                	sd	s2,432(sp)
    80005d0e:	f74e                	sd	s3,424(sp)
    80005d10:	f352                	sd	s4,416(sp)
    80005d12:	ef56                	sd	s5,408(sp)
    80005d14:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005d16:	e3840593          	addi	a1,s0,-456
    80005d1a:	4505                	li	a0,1
    80005d1c:	ffffd097          	auipc	ra,0xffffd
    80005d20:	004080e7          	jalr	4(ra) # 80002d20 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005d24:	08000613          	li	a2,128
    80005d28:	f4040593          	addi	a1,s0,-192
    80005d2c:	4501                	li	a0,0
    80005d2e:	ffffd097          	auipc	ra,0xffffd
    80005d32:	012080e7          	jalr	18(ra) # 80002d40 <argstr>
    80005d36:	87aa                	mv	a5,a0
    return -1;
    80005d38:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005d3a:	0c07c263          	bltz	a5,80005dfe <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005d3e:	10000613          	li	a2,256
    80005d42:	4581                	li	a1,0
    80005d44:	e4040513          	addi	a0,s0,-448
    80005d48:	ffffb097          	auipc	ra,0xffffb
    80005d4c:	f8a080e7          	jalr	-118(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d50:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d54:	89a6                	mv	s3,s1
    80005d56:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d58:	02000a13          	li	s4,32
    80005d5c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d60:	00391793          	slli	a5,s2,0x3
    80005d64:	e3040593          	addi	a1,s0,-464
    80005d68:	e3843503          	ld	a0,-456(s0)
    80005d6c:	953e                	add	a0,a0,a5
    80005d6e:	ffffd097          	auipc	ra,0xffffd
    80005d72:	ef4080e7          	jalr	-268(ra) # 80002c62 <fetchaddr>
    80005d76:	02054a63          	bltz	a0,80005daa <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005d7a:	e3043783          	ld	a5,-464(s0)
    80005d7e:	c3b9                	beqz	a5,80005dc4 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d80:	ffffb097          	auipc	ra,0xffffb
    80005d84:	d66080e7          	jalr	-666(ra) # 80000ae6 <kalloc>
    80005d88:	85aa                	mv	a1,a0
    80005d8a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d8e:	cd11                	beqz	a0,80005daa <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d90:	6605                	lui	a2,0x1
    80005d92:	e3043503          	ld	a0,-464(s0)
    80005d96:	ffffd097          	auipc	ra,0xffffd
    80005d9a:	f1e080e7          	jalr	-226(ra) # 80002cb4 <fetchstr>
    80005d9e:	00054663          	bltz	a0,80005daa <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005da2:	0905                	addi	s2,s2,1
    80005da4:	09a1                	addi	s3,s3,8
    80005da6:	fb491be3          	bne	s2,s4,80005d5c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005daa:	10048913          	addi	s2,s1,256
    80005dae:	6088                	ld	a0,0(s1)
    80005db0:	c531                	beqz	a0,80005dfc <sys_exec+0xf8>
    kfree(argv[i]);
    80005db2:	ffffb097          	auipc	ra,0xffffb
    80005db6:	c38080e7          	jalr	-968(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dba:	04a1                	addi	s1,s1,8
    80005dbc:	ff2499e3          	bne	s1,s2,80005dae <sys_exec+0xaa>
  return -1;
    80005dc0:	557d                	li	a0,-1
    80005dc2:	a835                	j	80005dfe <sys_exec+0xfa>
      argv[i] = 0;
    80005dc4:	0a8e                	slli	s5,s5,0x3
    80005dc6:	fc040793          	addi	a5,s0,-64
    80005dca:	9abe                	add	s5,s5,a5
    80005dcc:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005dd0:	e4040593          	addi	a1,s0,-448
    80005dd4:	f4040513          	addi	a0,s0,-192
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	172080e7          	jalr	370(ra) # 80004f4a <exec>
    80005de0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005de2:	10048993          	addi	s3,s1,256
    80005de6:	6088                	ld	a0,0(s1)
    80005de8:	c901                	beqz	a0,80005df8 <sys_exec+0xf4>
    kfree(argv[i]);
    80005dea:	ffffb097          	auipc	ra,0xffffb
    80005dee:	c00080e7          	jalr	-1024(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005df2:	04a1                	addi	s1,s1,8
    80005df4:	ff3499e3          	bne	s1,s3,80005de6 <sys_exec+0xe2>
  return ret;
    80005df8:	854a                	mv	a0,s2
    80005dfa:	a011                	j	80005dfe <sys_exec+0xfa>
  return -1;
    80005dfc:	557d                	li	a0,-1
}
    80005dfe:	60be                	ld	ra,456(sp)
    80005e00:	641e                	ld	s0,448(sp)
    80005e02:	74fa                	ld	s1,440(sp)
    80005e04:	795a                	ld	s2,432(sp)
    80005e06:	79ba                	ld	s3,424(sp)
    80005e08:	7a1a                	ld	s4,416(sp)
    80005e0a:	6afa                	ld	s5,408(sp)
    80005e0c:	6179                	addi	sp,sp,464
    80005e0e:	8082                	ret

0000000080005e10 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e10:	7139                	addi	sp,sp,-64
    80005e12:	fc06                	sd	ra,56(sp)
    80005e14:	f822                	sd	s0,48(sp)
    80005e16:	f426                	sd	s1,40(sp)
    80005e18:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e1a:	ffffc097          	auipc	ra,0xffffc
    80005e1e:	b92080e7          	jalr	-1134(ra) # 800019ac <myproc>
    80005e22:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005e24:	fd840593          	addi	a1,s0,-40
    80005e28:	4501                	li	a0,0
    80005e2a:	ffffd097          	auipc	ra,0xffffd
    80005e2e:	ef6080e7          	jalr	-266(ra) # 80002d20 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005e32:	fc840593          	addi	a1,s0,-56
    80005e36:	fd040513          	addi	a0,s0,-48
    80005e3a:	fffff097          	auipc	ra,0xfffff
    80005e3e:	dc6080e7          	jalr	-570(ra) # 80004c00 <pipealloc>
    return -1;
    80005e42:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e44:	0c054463          	bltz	a0,80005f0c <sys_pipe+0xfc>
  fd0 = -1;
    80005e48:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e4c:	fd043503          	ld	a0,-48(s0)
    80005e50:	fffff097          	auipc	ra,0xfffff
    80005e54:	51a080e7          	jalr	1306(ra) # 8000536a <fdalloc>
    80005e58:	fca42223          	sw	a0,-60(s0)
    80005e5c:	08054b63          	bltz	a0,80005ef2 <sys_pipe+0xe2>
    80005e60:	fc843503          	ld	a0,-56(s0)
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	506080e7          	jalr	1286(ra) # 8000536a <fdalloc>
    80005e6c:	fca42023          	sw	a0,-64(s0)
    80005e70:	06054863          	bltz	a0,80005ee0 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e74:	4691                	li	a3,4
    80005e76:	fc440613          	addi	a2,s0,-60
    80005e7a:	fd843583          	ld	a1,-40(s0)
    80005e7e:	68a8                	ld	a0,80(s1)
    80005e80:	ffffb097          	auipc	ra,0xffffb
    80005e84:	7e8080e7          	jalr	2024(ra) # 80001668 <copyout>
    80005e88:	02054063          	bltz	a0,80005ea8 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e8c:	4691                	li	a3,4
    80005e8e:	fc040613          	addi	a2,s0,-64
    80005e92:	fd843583          	ld	a1,-40(s0)
    80005e96:	0591                	addi	a1,a1,4
    80005e98:	68a8                	ld	a0,80(s1)
    80005e9a:	ffffb097          	auipc	ra,0xffffb
    80005e9e:	7ce080e7          	jalr	1998(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ea2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ea4:	06055463          	bgez	a0,80005f0c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005ea8:	fc442783          	lw	a5,-60(s0)
    80005eac:	07e9                	addi	a5,a5,26
    80005eae:	078e                	slli	a5,a5,0x3
    80005eb0:	97a6                	add	a5,a5,s1
    80005eb2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005eb6:	fc042503          	lw	a0,-64(s0)
    80005eba:	0569                	addi	a0,a0,26
    80005ebc:	050e                	slli	a0,a0,0x3
    80005ebe:	94aa                	add	s1,s1,a0
    80005ec0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005ec4:	fd043503          	ld	a0,-48(s0)
    80005ec8:	fffff097          	auipc	ra,0xfffff
    80005ecc:	a08080e7          	jalr	-1528(ra) # 800048d0 <fileclose>
    fileclose(wf);
    80005ed0:	fc843503          	ld	a0,-56(s0)
    80005ed4:	fffff097          	auipc	ra,0xfffff
    80005ed8:	9fc080e7          	jalr	-1540(ra) # 800048d0 <fileclose>
    return -1;
    80005edc:	57fd                	li	a5,-1
    80005ede:	a03d                	j	80005f0c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005ee0:	fc442783          	lw	a5,-60(s0)
    80005ee4:	0007c763          	bltz	a5,80005ef2 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005ee8:	07e9                	addi	a5,a5,26
    80005eea:	078e                	slli	a5,a5,0x3
    80005eec:	94be                	add	s1,s1,a5
    80005eee:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005ef2:	fd043503          	ld	a0,-48(s0)
    80005ef6:	fffff097          	auipc	ra,0xfffff
    80005efa:	9da080e7          	jalr	-1574(ra) # 800048d0 <fileclose>
    fileclose(wf);
    80005efe:	fc843503          	ld	a0,-56(s0)
    80005f02:	fffff097          	auipc	ra,0xfffff
    80005f06:	9ce080e7          	jalr	-1586(ra) # 800048d0 <fileclose>
    return -1;
    80005f0a:	57fd                	li	a5,-1
}
    80005f0c:	853e                	mv	a0,a5
    80005f0e:	70e2                	ld	ra,56(sp)
    80005f10:	7442                	ld	s0,48(sp)
    80005f12:	74a2                	ld	s1,40(sp)
    80005f14:	6121                	addi	sp,sp,64
    80005f16:	8082                	ret
	...

0000000080005f20 <kernelvec>:
    80005f20:	7111                	addi	sp,sp,-256
    80005f22:	e006                	sd	ra,0(sp)
    80005f24:	e40a                	sd	sp,8(sp)
    80005f26:	e80e                	sd	gp,16(sp)
    80005f28:	ec12                	sd	tp,24(sp)
    80005f2a:	f016                	sd	t0,32(sp)
    80005f2c:	f41a                	sd	t1,40(sp)
    80005f2e:	f81e                	sd	t2,48(sp)
    80005f30:	fc22                	sd	s0,56(sp)
    80005f32:	e0a6                	sd	s1,64(sp)
    80005f34:	e4aa                	sd	a0,72(sp)
    80005f36:	e8ae                	sd	a1,80(sp)
    80005f38:	ecb2                	sd	a2,88(sp)
    80005f3a:	f0b6                	sd	a3,96(sp)
    80005f3c:	f4ba                	sd	a4,104(sp)
    80005f3e:	f8be                	sd	a5,112(sp)
    80005f40:	fcc2                	sd	a6,120(sp)
    80005f42:	e146                	sd	a7,128(sp)
    80005f44:	e54a                	sd	s2,136(sp)
    80005f46:	e94e                	sd	s3,144(sp)
    80005f48:	ed52                	sd	s4,152(sp)
    80005f4a:	f156                	sd	s5,160(sp)
    80005f4c:	f55a                	sd	s6,168(sp)
    80005f4e:	f95e                	sd	s7,176(sp)
    80005f50:	fd62                	sd	s8,184(sp)
    80005f52:	e1e6                	sd	s9,192(sp)
    80005f54:	e5ea                	sd	s10,200(sp)
    80005f56:	e9ee                	sd	s11,208(sp)
    80005f58:	edf2                	sd	t3,216(sp)
    80005f5a:	f1f6                	sd	t4,224(sp)
    80005f5c:	f5fa                	sd	t5,232(sp)
    80005f5e:	f9fe                	sd	t6,240(sp)
    80005f60:	bcffc0ef          	jal	ra,80002b2e <kerneltrap>
    80005f64:	6082                	ld	ra,0(sp)
    80005f66:	6122                	ld	sp,8(sp)
    80005f68:	61c2                	ld	gp,16(sp)
    80005f6a:	7282                	ld	t0,32(sp)
    80005f6c:	7322                	ld	t1,40(sp)
    80005f6e:	73c2                	ld	t2,48(sp)
    80005f70:	7462                	ld	s0,56(sp)
    80005f72:	6486                	ld	s1,64(sp)
    80005f74:	6526                	ld	a0,72(sp)
    80005f76:	65c6                	ld	a1,80(sp)
    80005f78:	6666                	ld	a2,88(sp)
    80005f7a:	7686                	ld	a3,96(sp)
    80005f7c:	7726                	ld	a4,104(sp)
    80005f7e:	77c6                	ld	a5,112(sp)
    80005f80:	7866                	ld	a6,120(sp)
    80005f82:	688a                	ld	a7,128(sp)
    80005f84:	692a                	ld	s2,136(sp)
    80005f86:	69ca                	ld	s3,144(sp)
    80005f88:	6a6a                	ld	s4,152(sp)
    80005f8a:	7a8a                	ld	s5,160(sp)
    80005f8c:	7b2a                	ld	s6,168(sp)
    80005f8e:	7bca                	ld	s7,176(sp)
    80005f90:	7c6a                	ld	s8,184(sp)
    80005f92:	6c8e                	ld	s9,192(sp)
    80005f94:	6d2e                	ld	s10,200(sp)
    80005f96:	6dce                	ld	s11,208(sp)
    80005f98:	6e6e                	ld	t3,216(sp)
    80005f9a:	7e8e                	ld	t4,224(sp)
    80005f9c:	7f2e                	ld	t5,232(sp)
    80005f9e:	7fce                	ld	t6,240(sp)
    80005fa0:	6111                	addi	sp,sp,256
    80005fa2:	10200073          	sret
    80005fa6:	00000013          	nop
    80005faa:	00000013          	nop
    80005fae:	0001                	nop

0000000080005fb0 <timervec>:
    80005fb0:	34051573          	csrrw	a0,mscratch,a0
    80005fb4:	e10c                	sd	a1,0(a0)
    80005fb6:	e510                	sd	a2,8(a0)
    80005fb8:	e914                	sd	a3,16(a0)
    80005fba:	6d0c                	ld	a1,24(a0)
    80005fbc:	7110                	ld	a2,32(a0)
    80005fbe:	6194                	ld	a3,0(a1)
    80005fc0:	96b2                	add	a3,a3,a2
    80005fc2:	e194                	sd	a3,0(a1)
    80005fc4:	4589                	li	a1,2
    80005fc6:	14459073          	csrw	sip,a1
    80005fca:	6914                	ld	a3,16(a0)
    80005fcc:	6510                	ld	a2,8(a0)
    80005fce:	610c                	ld	a1,0(a0)
    80005fd0:	34051573          	csrrw	a0,mscratch,a0
    80005fd4:	30200073          	mret
	...

0000000080005fda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005fda:	1141                	addi	sp,sp,-16
    80005fdc:	e422                	sd	s0,8(sp)
    80005fde:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fe0:	0c0007b7          	lui	a5,0xc000
    80005fe4:	4705                	li	a4,1
    80005fe6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fe8:	c3d8                	sw	a4,4(a5)
}
    80005fea:	6422                	ld	s0,8(sp)
    80005fec:	0141                	addi	sp,sp,16
    80005fee:	8082                	ret

0000000080005ff0 <plicinithart>:

void
plicinithart(void)
{
    80005ff0:	1141                	addi	sp,sp,-16
    80005ff2:	e406                	sd	ra,8(sp)
    80005ff4:	e022                	sd	s0,0(sp)
    80005ff6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ff8:	ffffc097          	auipc	ra,0xffffc
    80005ffc:	988080e7          	jalr	-1656(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006000:	0085171b          	slliw	a4,a0,0x8
    80006004:	0c0027b7          	lui	a5,0xc002
    80006008:	97ba                	add	a5,a5,a4
    8000600a:	40200713          	li	a4,1026
    8000600e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006012:	00d5151b          	slliw	a0,a0,0xd
    80006016:	0c2017b7          	lui	a5,0xc201
    8000601a:	953e                	add	a0,a0,a5
    8000601c:	00052023          	sw	zero,0(a0)
}
    80006020:	60a2                	ld	ra,8(sp)
    80006022:	6402                	ld	s0,0(sp)
    80006024:	0141                	addi	sp,sp,16
    80006026:	8082                	ret

0000000080006028 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006028:	1141                	addi	sp,sp,-16
    8000602a:	e406                	sd	ra,8(sp)
    8000602c:	e022                	sd	s0,0(sp)
    8000602e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006030:	ffffc097          	auipc	ra,0xffffc
    80006034:	950080e7          	jalr	-1712(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006038:	00d5179b          	slliw	a5,a0,0xd
    8000603c:	0c201537          	lui	a0,0xc201
    80006040:	953e                	add	a0,a0,a5
  return irq;
}
    80006042:	4148                	lw	a0,4(a0)
    80006044:	60a2                	ld	ra,8(sp)
    80006046:	6402                	ld	s0,0(sp)
    80006048:	0141                	addi	sp,sp,16
    8000604a:	8082                	ret

000000008000604c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000604c:	1101                	addi	sp,sp,-32
    8000604e:	ec06                	sd	ra,24(sp)
    80006050:	e822                	sd	s0,16(sp)
    80006052:	e426                	sd	s1,8(sp)
    80006054:	1000                	addi	s0,sp,32
    80006056:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006058:	ffffc097          	auipc	ra,0xffffc
    8000605c:	928080e7          	jalr	-1752(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006060:	00d5151b          	slliw	a0,a0,0xd
    80006064:	0c2017b7          	lui	a5,0xc201
    80006068:	97aa                	add	a5,a5,a0
    8000606a:	c3c4                	sw	s1,4(a5)
}
    8000606c:	60e2                	ld	ra,24(sp)
    8000606e:	6442                	ld	s0,16(sp)
    80006070:	64a2                	ld	s1,8(sp)
    80006072:	6105                	addi	sp,sp,32
    80006074:	8082                	ret

0000000080006076 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006076:	1141                	addi	sp,sp,-16
    80006078:	e406                	sd	ra,8(sp)
    8000607a:	e022                	sd	s0,0(sp)
    8000607c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000607e:	479d                	li	a5,7
    80006080:	04a7cc63          	blt	a5,a0,800060d8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006084:	0001d797          	auipc	a5,0x1d
    80006088:	e2c78793          	addi	a5,a5,-468 # 80022eb0 <disk>
    8000608c:	97aa                	add	a5,a5,a0
    8000608e:	0187c783          	lbu	a5,24(a5)
    80006092:	ebb9                	bnez	a5,800060e8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006094:	00451613          	slli	a2,a0,0x4
    80006098:	0001d797          	auipc	a5,0x1d
    8000609c:	e1878793          	addi	a5,a5,-488 # 80022eb0 <disk>
    800060a0:	6394                	ld	a3,0(a5)
    800060a2:	96b2                	add	a3,a3,a2
    800060a4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800060a8:	6398                	ld	a4,0(a5)
    800060aa:	9732                	add	a4,a4,a2
    800060ac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800060b0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800060b4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800060b8:	953e                	add	a0,a0,a5
    800060ba:	4785                	li	a5,1
    800060bc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800060c0:	0001d517          	auipc	a0,0x1d
    800060c4:	e0850513          	addi	a0,a0,-504 # 80022ec8 <disk+0x18>
    800060c8:	ffffc097          	auipc	ra,0xffffc
    800060cc:	004080e7          	jalr	4(ra) # 800020cc <wakeup>
}
    800060d0:	60a2                	ld	ra,8(sp)
    800060d2:	6402                	ld	s0,0(sp)
    800060d4:	0141                	addi	sp,sp,16
    800060d6:	8082                	ret
    panic("free_desc 1");
    800060d8:	00002517          	auipc	a0,0x2
    800060dc:	69050513          	addi	a0,a0,1680 # 80008768 <syscalls+0x318>
    800060e0:	ffffa097          	auipc	ra,0xffffa
    800060e4:	45e080e7          	jalr	1118(ra) # 8000053e <panic>
    panic("free_desc 2");
    800060e8:	00002517          	auipc	a0,0x2
    800060ec:	69050513          	addi	a0,a0,1680 # 80008778 <syscalls+0x328>
    800060f0:	ffffa097          	auipc	ra,0xffffa
    800060f4:	44e080e7          	jalr	1102(ra) # 8000053e <panic>

00000000800060f8 <virtio_disk_init>:
{
    800060f8:	1101                	addi	sp,sp,-32
    800060fa:	ec06                	sd	ra,24(sp)
    800060fc:	e822                	sd	s0,16(sp)
    800060fe:	e426                	sd	s1,8(sp)
    80006100:	e04a                	sd	s2,0(sp)
    80006102:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006104:	00002597          	auipc	a1,0x2
    80006108:	68458593          	addi	a1,a1,1668 # 80008788 <syscalls+0x338>
    8000610c:	0001d517          	auipc	a0,0x1d
    80006110:	ecc50513          	addi	a0,a0,-308 # 80022fd8 <disk+0x128>
    80006114:	ffffb097          	auipc	ra,0xffffb
    80006118:	a32080e7          	jalr	-1486(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000611c:	100017b7          	lui	a5,0x10001
    80006120:	4398                	lw	a4,0(a5)
    80006122:	2701                	sext.w	a4,a4
    80006124:	747277b7          	lui	a5,0x74727
    80006128:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000612c:	14f71c63          	bne	a4,a5,80006284 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006130:	100017b7          	lui	a5,0x10001
    80006134:	43dc                	lw	a5,4(a5)
    80006136:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006138:	4709                	li	a4,2
    8000613a:	14e79563          	bne	a5,a4,80006284 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000613e:	100017b7          	lui	a5,0x10001
    80006142:	479c                	lw	a5,8(a5)
    80006144:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006146:	12e79f63          	bne	a5,a4,80006284 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000614a:	100017b7          	lui	a5,0x10001
    8000614e:	47d8                	lw	a4,12(a5)
    80006150:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006152:	554d47b7          	lui	a5,0x554d4
    80006156:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000615a:	12f71563          	bne	a4,a5,80006284 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000615e:	100017b7          	lui	a5,0x10001
    80006162:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006166:	4705                	li	a4,1
    80006168:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000616a:	470d                	li	a4,3
    8000616c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000616e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006170:	c7ffe737          	lui	a4,0xc7ffe
    80006174:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb76f>
    80006178:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000617a:	2701                	sext.w	a4,a4
    8000617c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000617e:	472d                	li	a4,11
    80006180:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006182:	5bbc                	lw	a5,112(a5)
    80006184:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006188:	8ba1                	andi	a5,a5,8
    8000618a:	10078563          	beqz	a5,80006294 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000618e:	100017b7          	lui	a5,0x10001
    80006192:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006196:	43fc                	lw	a5,68(a5)
    80006198:	2781                	sext.w	a5,a5
    8000619a:	10079563          	bnez	a5,800062a4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000619e:	100017b7          	lui	a5,0x10001
    800061a2:	5bdc                	lw	a5,52(a5)
    800061a4:	2781                	sext.w	a5,a5
  if(max == 0)
    800061a6:	10078763          	beqz	a5,800062b4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    800061aa:	471d                	li	a4,7
    800061ac:	10f77c63          	bgeu	a4,a5,800062c4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    800061b0:	ffffb097          	auipc	ra,0xffffb
    800061b4:	936080e7          	jalr	-1738(ra) # 80000ae6 <kalloc>
    800061b8:	0001d497          	auipc	s1,0x1d
    800061bc:	cf848493          	addi	s1,s1,-776 # 80022eb0 <disk>
    800061c0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800061c2:	ffffb097          	auipc	ra,0xffffb
    800061c6:	924080e7          	jalr	-1756(ra) # 80000ae6 <kalloc>
    800061ca:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800061cc:	ffffb097          	auipc	ra,0xffffb
    800061d0:	91a080e7          	jalr	-1766(ra) # 80000ae6 <kalloc>
    800061d4:	87aa                	mv	a5,a0
    800061d6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800061d8:	6088                	ld	a0,0(s1)
    800061da:	cd6d                	beqz	a0,800062d4 <virtio_disk_init+0x1dc>
    800061dc:	0001d717          	auipc	a4,0x1d
    800061e0:	cdc73703          	ld	a4,-804(a4) # 80022eb8 <disk+0x8>
    800061e4:	cb65                	beqz	a4,800062d4 <virtio_disk_init+0x1dc>
    800061e6:	c7fd                	beqz	a5,800062d4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800061e8:	6605                	lui	a2,0x1
    800061ea:	4581                	li	a1,0
    800061ec:	ffffb097          	auipc	ra,0xffffb
    800061f0:	ae6080e7          	jalr	-1306(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800061f4:	0001d497          	auipc	s1,0x1d
    800061f8:	cbc48493          	addi	s1,s1,-836 # 80022eb0 <disk>
    800061fc:	6605                	lui	a2,0x1
    800061fe:	4581                	li	a1,0
    80006200:	6488                	ld	a0,8(s1)
    80006202:	ffffb097          	auipc	ra,0xffffb
    80006206:	ad0080e7          	jalr	-1328(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000620a:	6605                	lui	a2,0x1
    8000620c:	4581                	li	a1,0
    8000620e:	6888                	ld	a0,16(s1)
    80006210:	ffffb097          	auipc	ra,0xffffb
    80006214:	ac2080e7          	jalr	-1342(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006218:	100017b7          	lui	a5,0x10001
    8000621c:	4721                	li	a4,8
    8000621e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006220:	4098                	lw	a4,0(s1)
    80006222:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006226:	40d8                	lw	a4,4(s1)
    80006228:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000622c:	6498                	ld	a4,8(s1)
    8000622e:	0007069b          	sext.w	a3,a4
    80006232:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006236:	9701                	srai	a4,a4,0x20
    80006238:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000623c:	6898                	ld	a4,16(s1)
    8000623e:	0007069b          	sext.w	a3,a4
    80006242:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006246:	9701                	srai	a4,a4,0x20
    80006248:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000624c:	4705                	li	a4,1
    8000624e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006250:	00e48c23          	sb	a4,24(s1)
    80006254:	00e48ca3          	sb	a4,25(s1)
    80006258:	00e48d23          	sb	a4,26(s1)
    8000625c:	00e48da3          	sb	a4,27(s1)
    80006260:	00e48e23          	sb	a4,28(s1)
    80006264:	00e48ea3          	sb	a4,29(s1)
    80006268:	00e48f23          	sb	a4,30(s1)
    8000626c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006270:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006274:	0727a823          	sw	s2,112(a5)
}
    80006278:	60e2                	ld	ra,24(sp)
    8000627a:	6442                	ld	s0,16(sp)
    8000627c:	64a2                	ld	s1,8(sp)
    8000627e:	6902                	ld	s2,0(sp)
    80006280:	6105                	addi	sp,sp,32
    80006282:	8082                	ret
    panic("could not find virtio disk");
    80006284:	00002517          	auipc	a0,0x2
    80006288:	51450513          	addi	a0,a0,1300 # 80008798 <syscalls+0x348>
    8000628c:	ffffa097          	auipc	ra,0xffffa
    80006290:	2b2080e7          	jalr	690(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006294:	00002517          	auipc	a0,0x2
    80006298:	52450513          	addi	a0,a0,1316 # 800087b8 <syscalls+0x368>
    8000629c:	ffffa097          	auipc	ra,0xffffa
    800062a0:	2a2080e7          	jalr	674(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    800062a4:	00002517          	auipc	a0,0x2
    800062a8:	53450513          	addi	a0,a0,1332 # 800087d8 <syscalls+0x388>
    800062ac:	ffffa097          	auipc	ra,0xffffa
    800062b0:	292080e7          	jalr	658(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800062b4:	00002517          	auipc	a0,0x2
    800062b8:	54450513          	addi	a0,a0,1348 # 800087f8 <syscalls+0x3a8>
    800062bc:	ffffa097          	auipc	ra,0xffffa
    800062c0:	282080e7          	jalr	642(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800062c4:	00002517          	auipc	a0,0x2
    800062c8:	55450513          	addi	a0,a0,1364 # 80008818 <syscalls+0x3c8>
    800062cc:	ffffa097          	auipc	ra,0xffffa
    800062d0:	272080e7          	jalr	626(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    800062d4:	00002517          	auipc	a0,0x2
    800062d8:	56450513          	addi	a0,a0,1380 # 80008838 <syscalls+0x3e8>
    800062dc:	ffffa097          	auipc	ra,0xffffa
    800062e0:	262080e7          	jalr	610(ra) # 8000053e <panic>

00000000800062e4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062e4:	7119                	addi	sp,sp,-128
    800062e6:	fc86                	sd	ra,120(sp)
    800062e8:	f8a2                	sd	s0,112(sp)
    800062ea:	f4a6                	sd	s1,104(sp)
    800062ec:	f0ca                	sd	s2,96(sp)
    800062ee:	ecce                	sd	s3,88(sp)
    800062f0:	e8d2                	sd	s4,80(sp)
    800062f2:	e4d6                	sd	s5,72(sp)
    800062f4:	e0da                	sd	s6,64(sp)
    800062f6:	fc5e                	sd	s7,56(sp)
    800062f8:	f862                	sd	s8,48(sp)
    800062fa:	f466                	sd	s9,40(sp)
    800062fc:	f06a                	sd	s10,32(sp)
    800062fe:	ec6e                	sd	s11,24(sp)
    80006300:	0100                	addi	s0,sp,128
    80006302:	8aaa                	mv	s5,a0
    80006304:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006306:	00c52d03          	lw	s10,12(a0)
    8000630a:	001d1d1b          	slliw	s10,s10,0x1
    8000630e:	1d02                	slli	s10,s10,0x20
    80006310:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006314:	0001d517          	auipc	a0,0x1d
    80006318:	cc450513          	addi	a0,a0,-828 # 80022fd8 <disk+0x128>
    8000631c:	ffffb097          	auipc	ra,0xffffb
    80006320:	8ba080e7          	jalr	-1862(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006324:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006326:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006328:	0001db97          	auipc	s7,0x1d
    8000632c:	b88b8b93          	addi	s7,s7,-1144 # 80022eb0 <disk>
  for(int i = 0; i < 3; i++){
    80006330:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006332:	0001dc97          	auipc	s9,0x1d
    80006336:	ca6c8c93          	addi	s9,s9,-858 # 80022fd8 <disk+0x128>
    8000633a:	a08d                	j	8000639c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000633c:	00fb8733          	add	a4,s7,a5
    80006340:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006344:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006346:	0207c563          	bltz	a5,80006370 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000634a:	2905                	addiw	s2,s2,1
    8000634c:	0611                	addi	a2,a2,4
    8000634e:	05690c63          	beq	s2,s6,800063a6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006352:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006354:	0001d717          	auipc	a4,0x1d
    80006358:	b5c70713          	addi	a4,a4,-1188 # 80022eb0 <disk>
    8000635c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000635e:	01874683          	lbu	a3,24(a4)
    80006362:	fee9                	bnez	a3,8000633c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006364:	2785                	addiw	a5,a5,1
    80006366:	0705                	addi	a4,a4,1
    80006368:	fe979be3          	bne	a5,s1,8000635e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000636c:	57fd                	li	a5,-1
    8000636e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006370:	01205d63          	blez	s2,8000638a <virtio_disk_rw+0xa6>
    80006374:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006376:	000a2503          	lw	a0,0(s4)
    8000637a:	00000097          	auipc	ra,0x0
    8000637e:	cfc080e7          	jalr	-772(ra) # 80006076 <free_desc>
      for(int j = 0; j < i; j++)
    80006382:	2d85                	addiw	s11,s11,1
    80006384:	0a11                	addi	s4,s4,4
    80006386:	ffb918e3          	bne	s2,s11,80006376 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000638a:	85e6                	mv	a1,s9
    8000638c:	0001d517          	auipc	a0,0x1d
    80006390:	b3c50513          	addi	a0,a0,-1220 # 80022ec8 <disk+0x18>
    80006394:	ffffc097          	auipc	ra,0xffffc
    80006398:	cd4080e7          	jalr	-812(ra) # 80002068 <sleep>
  for(int i = 0; i < 3; i++){
    8000639c:	f8040a13          	addi	s4,s0,-128
{
    800063a0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800063a2:	894e                	mv	s2,s3
    800063a4:	b77d                	j	80006352 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063a6:	f8042583          	lw	a1,-128(s0)
    800063aa:	00a58793          	addi	a5,a1,10
    800063ae:	0792                	slli	a5,a5,0x4

  if(write)
    800063b0:	0001d617          	auipc	a2,0x1d
    800063b4:	b0060613          	addi	a2,a2,-1280 # 80022eb0 <disk>
    800063b8:	00f60733          	add	a4,a2,a5
    800063bc:	018036b3          	snez	a3,s8
    800063c0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800063c2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800063c6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800063ca:	f6078693          	addi	a3,a5,-160
    800063ce:	6218                	ld	a4,0(a2)
    800063d0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063d2:	00878513          	addi	a0,a5,8
    800063d6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063d8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063da:	6208                	ld	a0,0(a2)
    800063dc:	96aa                	add	a3,a3,a0
    800063de:	4741                	li	a4,16
    800063e0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063e2:	4705                	li	a4,1
    800063e4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800063e8:	f8442703          	lw	a4,-124(s0)
    800063ec:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063f0:	0712                	slli	a4,a4,0x4
    800063f2:	953a                	add	a0,a0,a4
    800063f4:	058a8693          	addi	a3,s5,88
    800063f8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800063fa:	6208                	ld	a0,0(a2)
    800063fc:	972a                	add	a4,a4,a0
    800063fe:	40000693          	li	a3,1024
    80006402:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006404:	001c3c13          	seqz	s8,s8
    80006408:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000640a:	001c6c13          	ori	s8,s8,1
    8000640e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006412:	f8842603          	lw	a2,-120(s0)
    80006416:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000641a:	0001d697          	auipc	a3,0x1d
    8000641e:	a9668693          	addi	a3,a3,-1386 # 80022eb0 <disk>
    80006422:	00258713          	addi	a4,a1,2
    80006426:	0712                	slli	a4,a4,0x4
    80006428:	9736                	add	a4,a4,a3
    8000642a:	587d                	li	a6,-1
    8000642c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006430:	0612                	slli	a2,a2,0x4
    80006432:	9532                	add	a0,a0,a2
    80006434:	f9078793          	addi	a5,a5,-112
    80006438:	97b6                	add	a5,a5,a3
    8000643a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000643c:	629c                	ld	a5,0(a3)
    8000643e:	97b2                	add	a5,a5,a2
    80006440:	4605                	li	a2,1
    80006442:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006444:	4509                	li	a0,2
    80006446:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000644a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000644e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006452:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006456:	6698                	ld	a4,8(a3)
    80006458:	00275783          	lhu	a5,2(a4)
    8000645c:	8b9d                	andi	a5,a5,7
    8000645e:	0786                	slli	a5,a5,0x1
    80006460:	97ba                	add	a5,a5,a4
    80006462:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006466:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000646a:	6698                	ld	a4,8(a3)
    8000646c:	00275783          	lhu	a5,2(a4)
    80006470:	2785                	addiw	a5,a5,1
    80006472:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006476:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000647a:	100017b7          	lui	a5,0x10001
    8000647e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006482:	004aa783          	lw	a5,4(s5)
    80006486:	02c79163          	bne	a5,a2,800064a8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000648a:	0001d917          	auipc	s2,0x1d
    8000648e:	b4e90913          	addi	s2,s2,-1202 # 80022fd8 <disk+0x128>
  while(b->disk == 1) {
    80006492:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006494:	85ca                	mv	a1,s2
    80006496:	8556                	mv	a0,s5
    80006498:	ffffc097          	auipc	ra,0xffffc
    8000649c:	bd0080e7          	jalr	-1072(ra) # 80002068 <sleep>
  while(b->disk == 1) {
    800064a0:	004aa783          	lw	a5,4(s5)
    800064a4:	fe9788e3          	beq	a5,s1,80006494 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800064a8:	f8042903          	lw	s2,-128(s0)
    800064ac:	00290793          	addi	a5,s2,2
    800064b0:	00479713          	slli	a4,a5,0x4
    800064b4:	0001d797          	auipc	a5,0x1d
    800064b8:	9fc78793          	addi	a5,a5,-1540 # 80022eb0 <disk>
    800064bc:	97ba                	add	a5,a5,a4
    800064be:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800064c2:	0001d997          	auipc	s3,0x1d
    800064c6:	9ee98993          	addi	s3,s3,-1554 # 80022eb0 <disk>
    800064ca:	00491713          	slli	a4,s2,0x4
    800064ce:	0009b783          	ld	a5,0(s3)
    800064d2:	97ba                	add	a5,a5,a4
    800064d4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800064d8:	854a                	mv	a0,s2
    800064da:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064de:	00000097          	auipc	ra,0x0
    800064e2:	b98080e7          	jalr	-1128(ra) # 80006076 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064e6:	8885                	andi	s1,s1,1
    800064e8:	f0ed                	bnez	s1,800064ca <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064ea:	0001d517          	auipc	a0,0x1d
    800064ee:	aee50513          	addi	a0,a0,-1298 # 80022fd8 <disk+0x128>
    800064f2:	ffffa097          	auipc	ra,0xffffa
    800064f6:	798080e7          	jalr	1944(ra) # 80000c8a <release>
}
    800064fa:	70e6                	ld	ra,120(sp)
    800064fc:	7446                	ld	s0,112(sp)
    800064fe:	74a6                	ld	s1,104(sp)
    80006500:	7906                	ld	s2,96(sp)
    80006502:	69e6                	ld	s3,88(sp)
    80006504:	6a46                	ld	s4,80(sp)
    80006506:	6aa6                	ld	s5,72(sp)
    80006508:	6b06                	ld	s6,64(sp)
    8000650a:	7be2                	ld	s7,56(sp)
    8000650c:	7c42                	ld	s8,48(sp)
    8000650e:	7ca2                	ld	s9,40(sp)
    80006510:	7d02                	ld	s10,32(sp)
    80006512:	6de2                	ld	s11,24(sp)
    80006514:	6109                	addi	sp,sp,128
    80006516:	8082                	ret

0000000080006518 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006518:	1101                	addi	sp,sp,-32
    8000651a:	ec06                	sd	ra,24(sp)
    8000651c:	e822                	sd	s0,16(sp)
    8000651e:	e426                	sd	s1,8(sp)
    80006520:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006522:	0001d497          	auipc	s1,0x1d
    80006526:	98e48493          	addi	s1,s1,-1650 # 80022eb0 <disk>
    8000652a:	0001d517          	auipc	a0,0x1d
    8000652e:	aae50513          	addi	a0,a0,-1362 # 80022fd8 <disk+0x128>
    80006532:	ffffa097          	auipc	ra,0xffffa
    80006536:	6a4080e7          	jalr	1700(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000653a:	10001737          	lui	a4,0x10001
    8000653e:	533c                	lw	a5,96(a4)
    80006540:	8b8d                	andi	a5,a5,3
    80006542:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006544:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006548:	689c                	ld	a5,16(s1)
    8000654a:	0204d703          	lhu	a4,32(s1)
    8000654e:	0027d783          	lhu	a5,2(a5)
    80006552:	04f70863          	beq	a4,a5,800065a2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006556:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000655a:	6898                	ld	a4,16(s1)
    8000655c:	0204d783          	lhu	a5,32(s1)
    80006560:	8b9d                	andi	a5,a5,7
    80006562:	078e                	slli	a5,a5,0x3
    80006564:	97ba                	add	a5,a5,a4
    80006566:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006568:	00278713          	addi	a4,a5,2
    8000656c:	0712                	slli	a4,a4,0x4
    8000656e:	9726                	add	a4,a4,s1
    80006570:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006574:	e721                	bnez	a4,800065bc <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006576:	0789                	addi	a5,a5,2
    80006578:	0792                	slli	a5,a5,0x4
    8000657a:	97a6                	add	a5,a5,s1
    8000657c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000657e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006582:	ffffc097          	auipc	ra,0xffffc
    80006586:	b4a080e7          	jalr	-1206(ra) # 800020cc <wakeup>

    disk.used_idx += 1;
    8000658a:	0204d783          	lhu	a5,32(s1)
    8000658e:	2785                	addiw	a5,a5,1
    80006590:	17c2                	slli	a5,a5,0x30
    80006592:	93c1                	srli	a5,a5,0x30
    80006594:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006598:	6898                	ld	a4,16(s1)
    8000659a:	00275703          	lhu	a4,2(a4)
    8000659e:	faf71ce3          	bne	a4,a5,80006556 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800065a2:	0001d517          	auipc	a0,0x1d
    800065a6:	a3650513          	addi	a0,a0,-1482 # 80022fd8 <disk+0x128>
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	6e0080e7          	jalr	1760(ra) # 80000c8a <release>
}
    800065b2:	60e2                	ld	ra,24(sp)
    800065b4:	6442                	ld	s0,16(sp)
    800065b6:	64a2                	ld	s1,8(sp)
    800065b8:	6105                	addi	sp,sp,32
    800065ba:	8082                	ret
      panic("virtio_disk_intr status");
    800065bc:	00002517          	auipc	a0,0x2
    800065c0:	29450513          	addi	a0,a0,660 # 80008850 <syscalls+0x400>
    800065c4:	ffffa097          	auipc	ra,0xffffa
    800065c8:	f7a080e7          	jalr	-134(ra) # 8000053e <panic>
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


user/_schedulertest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:

#define NFORK 10
#define IO 5

int main()
{
   0:	7139                	addi	sp,sp,-64
   2:	fc06                	sd	ra,56(sp)
   4:	f822                	sd	s0,48(sp)
   6:	f426                	sd	s1,40(sp)
   8:	f04a                	sd	s2,32(sp)
   a:	ec4e                	sd	s3,24(sp)
   c:	0080                	addi	s0,sp,64
  int n, pid;
  int wtime, rtime;
  int twtime = 0, trtime = 0;
  for (n = 0; n < NFORK; n++)
   e:	4481                	li	s1,0
  10:	4929                	li	s2,10
  {
    pid = fork();
  12:	00000097          	auipc	ra,0x0
  16:	34e080e7          	jalr	846(ra) # 360 <fork>
    if (pid < 0)
  1a:	00054963          	bltz	a0,2c <main+0x2c>
      break;
    if (pid == 0)
  1e:	cd0d                	beqz	a0,58 <main+0x58>
  for (n = 0; n < NFORK; n++)
  20:	2485                	addiw	s1,s1,1
  22:	ff2498e3          	bne	s1,s2,12 <main+0x12>
  26:	4901                	li	s2,0
  28:	4981                	li	s3,0
  2a:	a079                	j	b8 <main+0xb8>
      }
      printf("Process %d finished\n", n);
      exit(0);
    }
  }
  for (; n > 0; n--)
  2c:	fe904de3          	bgtz	s1,26 <main+0x26>
  30:	4901                	li	s2,0
  32:	4981                	li	s3,0
    {
      trtime += rtime;
      twtime += wtime;
    }
  }
  printf("Average rtime %d,  wtime %d\n", trtime / NFORK, twtime / NFORK);
  34:	45a9                	li	a1,10
  36:	02b9c63b          	divw	a2,s3,a1
  3a:	02b945bb          	divw	a1,s2,a1
  3e:	00001517          	auipc	a0,0x1
  42:	88a50513          	addi	a0,a0,-1910 # 8c8 <malloc+0x102>
  46:	00000097          	auipc	ra,0x0
  4a:	6c2080e7          	jalr	1730(ra) # 708 <printf>
  exit(0);
  4e:	4501                	li	a0,0
  50:	00000097          	auipc	ra,0x0
  54:	318080e7          	jalr	792(ra) # 368 <exit>
      if (n < IO)
  58:	4791                	li	a5,4
  5a:	0497d663          	bge	a5,s1,a6 <main+0xa6>
        for (volatile int i = 0; i < 1000000000; i++)
  5e:	fc042223          	sw	zero,-60(s0)
  62:	fc442703          	lw	a4,-60(s0)
  66:	2701                	sext.w	a4,a4
  68:	3b9ad7b7          	lui	a5,0x3b9ad
  6c:	9ff78793          	addi	a5,a5,-1537 # 3b9ac9ff <base+0x3b9ab9ef>
  70:	00e7cd63          	blt	a5,a4,8a <main+0x8a>
  74:	873e                	mv	a4,a5
  76:	fc442783          	lw	a5,-60(s0)
  7a:	2785                	addiw	a5,a5,1
  7c:	fcf42223          	sw	a5,-60(s0)
  80:	fc442783          	lw	a5,-60(s0)
  84:	2781                	sext.w	a5,a5
  86:	fef758e3          	bge	a4,a5,76 <main+0x76>
      printf("Process %d finished\n", n);
  8a:	85a6                	mv	a1,s1
  8c:	00001517          	auipc	a0,0x1
  90:	82450513          	addi	a0,a0,-2012 # 8b0 <malloc+0xea>
  94:	00000097          	auipc	ra,0x0
  98:	674080e7          	jalr	1652(ra) # 708 <printf>
      exit(0);
  9c:	4501                	li	a0,0
  9e:	00000097          	auipc	ra,0x0
  a2:	2ca080e7          	jalr	714(ra) # 368 <exit>
        sleep(200); // IO bound processes
  a6:	0c800513          	li	a0,200
  aa:	00000097          	auipc	ra,0x0
  ae:	34e080e7          	jalr	846(ra) # 3f8 <sleep>
  b2:	bfe1                	j	8a <main+0x8a>
  for (; n > 0; n--)
  b4:	34fd                	addiw	s1,s1,-1
  b6:	dcbd                	beqz	s1,34 <main+0x34>
    if (waitx(0, &wtime, &rtime) >= 0)
  b8:	fc840613          	addi	a2,s0,-56
  bc:	fcc40593          	addi	a1,s0,-52
  c0:	4501                	li	a0,0
  c2:	00000097          	auipc	ra,0x0
  c6:	346080e7          	jalr	838(ra) # 408 <waitx>
  ca:	fe0545e3          	bltz	a0,b4 <main+0xb4>
      trtime += rtime;
  ce:	fc842783          	lw	a5,-56(s0)
  d2:	0127893b          	addw	s2,a5,s2
      twtime += wtime;
  d6:	fcc42783          	lw	a5,-52(s0)
  da:	013789bb          	addw	s3,a5,s3
  de:	bfd9                	j	b4 <main+0xb4>

00000000000000e0 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  e0:	1141                	addi	sp,sp,-16
  e2:	e406                	sd	ra,8(sp)
  e4:	e022                	sd	s0,0(sp)
  e6:	0800                	addi	s0,sp,16
  extern int main();
  main();
  e8:	00000097          	auipc	ra,0x0
  ec:	f18080e7          	jalr	-232(ra) # 0 <main>
  exit(0);
  f0:	4501                	li	a0,0
  f2:	00000097          	auipc	ra,0x0
  f6:	276080e7          	jalr	630(ra) # 368 <exit>

00000000000000fa <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  fa:	1141                	addi	sp,sp,-16
  fc:	e422                	sd	s0,8(sp)
  fe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 100:	87aa                	mv	a5,a0
 102:	0585                	addi	a1,a1,1
 104:	0785                	addi	a5,a5,1
 106:	fff5c703          	lbu	a4,-1(a1)
 10a:	fee78fa3          	sb	a4,-1(a5)
 10e:	fb75                	bnez	a4,102 <strcpy+0x8>
    ;
  return os;
}
 110:	6422                	ld	s0,8(sp)
 112:	0141                	addi	sp,sp,16
 114:	8082                	ret

0000000000000116 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 116:	1141                	addi	sp,sp,-16
 118:	e422                	sd	s0,8(sp)
 11a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 11c:	00054783          	lbu	a5,0(a0)
 120:	cb91                	beqz	a5,134 <strcmp+0x1e>
 122:	0005c703          	lbu	a4,0(a1)
 126:	00f71763          	bne	a4,a5,134 <strcmp+0x1e>
    p++, q++;
 12a:	0505                	addi	a0,a0,1
 12c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 12e:	00054783          	lbu	a5,0(a0)
 132:	fbe5                	bnez	a5,122 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 134:	0005c503          	lbu	a0,0(a1)
}
 138:	40a7853b          	subw	a0,a5,a0
 13c:	6422                	ld	s0,8(sp)
 13e:	0141                	addi	sp,sp,16
 140:	8082                	ret

0000000000000142 <strlen>:

uint
strlen(const char *s)
{
 142:	1141                	addi	sp,sp,-16
 144:	e422                	sd	s0,8(sp)
 146:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 148:	00054783          	lbu	a5,0(a0)
 14c:	cf91                	beqz	a5,168 <strlen+0x26>
 14e:	0505                	addi	a0,a0,1
 150:	87aa                	mv	a5,a0
 152:	4685                	li	a3,1
 154:	9e89                	subw	a3,a3,a0
 156:	00f6853b          	addw	a0,a3,a5
 15a:	0785                	addi	a5,a5,1
 15c:	fff7c703          	lbu	a4,-1(a5)
 160:	fb7d                	bnez	a4,156 <strlen+0x14>
    ;
  return n;
}
 162:	6422                	ld	s0,8(sp)
 164:	0141                	addi	sp,sp,16
 166:	8082                	ret
  for(n = 0; s[n]; n++)
 168:	4501                	li	a0,0
 16a:	bfe5                	j	162 <strlen+0x20>

000000000000016c <memset>:

void*
memset(void *dst, int c, uint n)
{
 16c:	1141                	addi	sp,sp,-16
 16e:	e422                	sd	s0,8(sp)
 170:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 172:	ca19                	beqz	a2,188 <memset+0x1c>
 174:	87aa                	mv	a5,a0
 176:	1602                	slli	a2,a2,0x20
 178:	9201                	srli	a2,a2,0x20
 17a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 17e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 182:	0785                	addi	a5,a5,1
 184:	fee79de3          	bne	a5,a4,17e <memset+0x12>
  }
  return dst;
}
 188:	6422                	ld	s0,8(sp)
 18a:	0141                	addi	sp,sp,16
 18c:	8082                	ret

000000000000018e <strchr>:

char*
strchr(const char *s, char c)
{
 18e:	1141                	addi	sp,sp,-16
 190:	e422                	sd	s0,8(sp)
 192:	0800                	addi	s0,sp,16
  for(; *s; s++)
 194:	00054783          	lbu	a5,0(a0)
 198:	cb99                	beqz	a5,1ae <strchr+0x20>
    if(*s == c)
 19a:	00f58763          	beq	a1,a5,1a8 <strchr+0x1a>
  for(; *s; s++)
 19e:	0505                	addi	a0,a0,1
 1a0:	00054783          	lbu	a5,0(a0)
 1a4:	fbfd                	bnez	a5,19a <strchr+0xc>
      return (char*)s;
  return 0;
 1a6:	4501                	li	a0,0
}
 1a8:	6422                	ld	s0,8(sp)
 1aa:	0141                	addi	sp,sp,16
 1ac:	8082                	ret
  return 0;
 1ae:	4501                	li	a0,0
 1b0:	bfe5                	j	1a8 <strchr+0x1a>

00000000000001b2 <gets>:

char*
gets(char *buf, int max)
{
 1b2:	711d                	addi	sp,sp,-96
 1b4:	ec86                	sd	ra,88(sp)
 1b6:	e8a2                	sd	s0,80(sp)
 1b8:	e4a6                	sd	s1,72(sp)
 1ba:	e0ca                	sd	s2,64(sp)
 1bc:	fc4e                	sd	s3,56(sp)
 1be:	f852                	sd	s4,48(sp)
 1c0:	f456                	sd	s5,40(sp)
 1c2:	f05a                	sd	s6,32(sp)
 1c4:	ec5e                	sd	s7,24(sp)
 1c6:	1080                	addi	s0,sp,96
 1c8:	8baa                	mv	s7,a0
 1ca:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1cc:	892a                	mv	s2,a0
 1ce:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1d0:	4aa9                	li	s5,10
 1d2:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1d4:	89a6                	mv	s3,s1
 1d6:	2485                	addiw	s1,s1,1
 1d8:	0344d863          	bge	s1,s4,208 <gets+0x56>
    cc = read(0, &c, 1);
 1dc:	4605                	li	a2,1
 1de:	faf40593          	addi	a1,s0,-81
 1e2:	4501                	li	a0,0
 1e4:	00000097          	auipc	ra,0x0
 1e8:	19c080e7          	jalr	412(ra) # 380 <read>
    if(cc < 1)
 1ec:	00a05e63          	blez	a0,208 <gets+0x56>
    buf[i++] = c;
 1f0:	faf44783          	lbu	a5,-81(s0)
 1f4:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1f8:	01578763          	beq	a5,s5,206 <gets+0x54>
 1fc:	0905                	addi	s2,s2,1
 1fe:	fd679be3          	bne	a5,s6,1d4 <gets+0x22>
  for(i=0; i+1 < max; ){
 202:	89a6                	mv	s3,s1
 204:	a011                	j	208 <gets+0x56>
 206:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 208:	99de                	add	s3,s3,s7
 20a:	00098023          	sb	zero,0(s3)
  return buf;
}
 20e:	855e                	mv	a0,s7
 210:	60e6                	ld	ra,88(sp)
 212:	6446                	ld	s0,80(sp)
 214:	64a6                	ld	s1,72(sp)
 216:	6906                	ld	s2,64(sp)
 218:	79e2                	ld	s3,56(sp)
 21a:	7a42                	ld	s4,48(sp)
 21c:	7aa2                	ld	s5,40(sp)
 21e:	7b02                	ld	s6,32(sp)
 220:	6be2                	ld	s7,24(sp)
 222:	6125                	addi	sp,sp,96
 224:	8082                	ret

0000000000000226 <stat>:

int
stat(const char *n, struct stat *st)
{
 226:	1101                	addi	sp,sp,-32
 228:	ec06                	sd	ra,24(sp)
 22a:	e822                	sd	s0,16(sp)
 22c:	e426                	sd	s1,8(sp)
 22e:	e04a                	sd	s2,0(sp)
 230:	1000                	addi	s0,sp,32
 232:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 234:	4581                	li	a1,0
 236:	00000097          	auipc	ra,0x0
 23a:	172080e7          	jalr	370(ra) # 3a8 <open>
  if(fd < 0)
 23e:	02054563          	bltz	a0,268 <stat+0x42>
 242:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 244:	85ca                	mv	a1,s2
 246:	00000097          	auipc	ra,0x0
 24a:	17a080e7          	jalr	378(ra) # 3c0 <fstat>
 24e:	892a                	mv	s2,a0
  close(fd);
 250:	8526                	mv	a0,s1
 252:	00000097          	auipc	ra,0x0
 256:	13e080e7          	jalr	318(ra) # 390 <close>
  return r;
}
 25a:	854a                	mv	a0,s2
 25c:	60e2                	ld	ra,24(sp)
 25e:	6442                	ld	s0,16(sp)
 260:	64a2                	ld	s1,8(sp)
 262:	6902                	ld	s2,0(sp)
 264:	6105                	addi	sp,sp,32
 266:	8082                	ret
    return -1;
 268:	597d                	li	s2,-1
 26a:	bfc5                	j	25a <stat+0x34>

000000000000026c <atoi>:

int
atoi(const char *s)
{
 26c:	1141                	addi	sp,sp,-16
 26e:	e422                	sd	s0,8(sp)
 270:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 272:	00054603          	lbu	a2,0(a0)
 276:	fd06079b          	addiw	a5,a2,-48
 27a:	0ff7f793          	andi	a5,a5,255
 27e:	4725                	li	a4,9
 280:	02f76963          	bltu	a4,a5,2b2 <atoi+0x46>
 284:	86aa                	mv	a3,a0
  n = 0;
 286:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 288:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 28a:	0685                	addi	a3,a3,1
 28c:	0025179b          	slliw	a5,a0,0x2
 290:	9fa9                	addw	a5,a5,a0
 292:	0017979b          	slliw	a5,a5,0x1
 296:	9fb1                	addw	a5,a5,a2
 298:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 29c:	0006c603          	lbu	a2,0(a3)
 2a0:	fd06071b          	addiw	a4,a2,-48
 2a4:	0ff77713          	andi	a4,a4,255
 2a8:	fee5f1e3          	bgeu	a1,a4,28a <atoi+0x1e>
  return n;
}
 2ac:	6422                	ld	s0,8(sp)
 2ae:	0141                	addi	sp,sp,16
 2b0:	8082                	ret
  n = 0;
 2b2:	4501                	li	a0,0
 2b4:	bfe5                	j	2ac <atoi+0x40>

00000000000002b6 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2b6:	1141                	addi	sp,sp,-16
 2b8:	e422                	sd	s0,8(sp)
 2ba:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2bc:	02b57463          	bgeu	a0,a1,2e4 <memmove+0x2e>
    while(n-- > 0)
 2c0:	00c05f63          	blez	a2,2de <memmove+0x28>
 2c4:	1602                	slli	a2,a2,0x20
 2c6:	9201                	srli	a2,a2,0x20
 2c8:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 2cc:	872a                	mv	a4,a0
      *dst++ = *src++;
 2ce:	0585                	addi	a1,a1,1
 2d0:	0705                	addi	a4,a4,1
 2d2:	fff5c683          	lbu	a3,-1(a1)
 2d6:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2da:	fee79ae3          	bne	a5,a4,2ce <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2de:	6422                	ld	s0,8(sp)
 2e0:	0141                	addi	sp,sp,16
 2e2:	8082                	ret
    dst += n;
 2e4:	00c50733          	add	a4,a0,a2
    src += n;
 2e8:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2ea:	fec05ae3          	blez	a2,2de <memmove+0x28>
 2ee:	fff6079b          	addiw	a5,a2,-1
 2f2:	1782                	slli	a5,a5,0x20
 2f4:	9381                	srli	a5,a5,0x20
 2f6:	fff7c793          	not	a5,a5
 2fa:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2fc:	15fd                	addi	a1,a1,-1
 2fe:	177d                	addi	a4,a4,-1
 300:	0005c683          	lbu	a3,0(a1)
 304:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 308:	fee79ae3          	bne	a5,a4,2fc <memmove+0x46>
 30c:	bfc9                	j	2de <memmove+0x28>

000000000000030e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 30e:	1141                	addi	sp,sp,-16
 310:	e422                	sd	s0,8(sp)
 312:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 314:	ca05                	beqz	a2,344 <memcmp+0x36>
 316:	fff6069b          	addiw	a3,a2,-1
 31a:	1682                	slli	a3,a3,0x20
 31c:	9281                	srli	a3,a3,0x20
 31e:	0685                	addi	a3,a3,1
 320:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 322:	00054783          	lbu	a5,0(a0)
 326:	0005c703          	lbu	a4,0(a1)
 32a:	00e79863          	bne	a5,a4,33a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 32e:	0505                	addi	a0,a0,1
    p2++;
 330:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 332:	fed518e3          	bne	a0,a3,322 <memcmp+0x14>
  }
  return 0;
 336:	4501                	li	a0,0
 338:	a019                	j	33e <memcmp+0x30>
      return *p1 - *p2;
 33a:	40e7853b          	subw	a0,a5,a4
}
 33e:	6422                	ld	s0,8(sp)
 340:	0141                	addi	sp,sp,16
 342:	8082                	ret
  return 0;
 344:	4501                	li	a0,0
 346:	bfe5                	j	33e <memcmp+0x30>

0000000000000348 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 348:	1141                	addi	sp,sp,-16
 34a:	e406                	sd	ra,8(sp)
 34c:	e022                	sd	s0,0(sp)
 34e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 350:	00000097          	auipc	ra,0x0
 354:	f66080e7          	jalr	-154(ra) # 2b6 <memmove>
}
 358:	60a2                	ld	ra,8(sp)
 35a:	6402                	ld	s0,0(sp)
 35c:	0141                	addi	sp,sp,16
 35e:	8082                	ret

0000000000000360 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 360:	4885                	li	a7,1
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <exit>:
.global exit
exit:
 li a7, SYS_exit
 368:	4889                	li	a7,2
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <wait>:
.global wait
wait:
 li a7, SYS_wait
 370:	488d                	li	a7,3
 ecall
 372:	00000073          	ecall
 ret
 376:	8082                	ret

0000000000000378 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 378:	4891                	li	a7,4
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <read>:
.global read
read:
 li a7, SYS_read
 380:	4895                	li	a7,5
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <write>:
.global write
write:
 li a7, SYS_write
 388:	48c1                	li	a7,16
 ecall
 38a:	00000073          	ecall
 ret
 38e:	8082                	ret

0000000000000390 <close>:
.global close
close:
 li a7, SYS_close
 390:	48d5                	li	a7,21
 ecall
 392:	00000073          	ecall
 ret
 396:	8082                	ret

0000000000000398 <kill>:
.global kill
kill:
 li a7, SYS_kill
 398:	4899                	li	a7,6
 ecall
 39a:	00000073          	ecall
 ret
 39e:	8082                	ret

00000000000003a0 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3a0:	489d                	li	a7,7
 ecall
 3a2:	00000073          	ecall
 ret
 3a6:	8082                	ret

00000000000003a8 <open>:
.global open
open:
 li a7, SYS_open
 3a8:	48bd                	li	a7,15
 ecall
 3aa:	00000073          	ecall
 ret
 3ae:	8082                	ret

00000000000003b0 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3b0:	48c5                	li	a7,17
 ecall
 3b2:	00000073          	ecall
 ret
 3b6:	8082                	ret

00000000000003b8 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3b8:	48c9                	li	a7,18
 ecall
 3ba:	00000073          	ecall
 ret
 3be:	8082                	ret

00000000000003c0 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3c0:	48a1                	li	a7,8
 ecall
 3c2:	00000073          	ecall
 ret
 3c6:	8082                	ret

00000000000003c8 <link>:
.global link
link:
 li a7, SYS_link
 3c8:	48cd                	li	a7,19
 ecall
 3ca:	00000073          	ecall
 ret
 3ce:	8082                	ret

00000000000003d0 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3d0:	48d1                	li	a7,20
 ecall
 3d2:	00000073          	ecall
 ret
 3d6:	8082                	ret

00000000000003d8 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3d8:	48a5                	li	a7,9
 ecall
 3da:	00000073          	ecall
 ret
 3de:	8082                	ret

00000000000003e0 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3e0:	48a9                	li	a7,10
 ecall
 3e2:	00000073          	ecall
 ret
 3e6:	8082                	ret

00000000000003e8 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3e8:	48ad                	li	a7,11
 ecall
 3ea:	00000073          	ecall
 ret
 3ee:	8082                	ret

00000000000003f0 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3f0:	48b1                	li	a7,12
 ecall
 3f2:	00000073          	ecall
 ret
 3f6:	8082                	ret

00000000000003f8 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3f8:	48b5                	li	a7,13
 ecall
 3fa:	00000073          	ecall
 ret
 3fe:	8082                	ret

0000000000000400 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 400:	48b9                	li	a7,14
 ecall
 402:	00000073          	ecall
 ret
 406:	8082                	ret

0000000000000408 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 408:	48d9                	li	a7,22
 ecall
 40a:	00000073          	ecall
 ret
 40e:	8082                	ret

0000000000000410 <getSysCount>:
.global getSysCount
getSysCount:
 li a7, SYS_getSysCount
 410:	48dd                	li	a7,23
 ecall
 412:	00000073          	ecall
 ret
 416:	8082                	ret

0000000000000418 <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 418:	48e1                	li	a7,24
 ecall
 41a:	00000073          	ecall
 ret
 41e:	8082                	ret

0000000000000420 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 420:	48e5                	li	a7,25
 ecall
 422:	00000073          	ecall
 ret
 426:	8082                	ret

0000000000000428 <settickets>:
.global settickets
settickets:
 li a7, SYS_settickets
 428:	48e9                	li	a7,26
 ecall
 42a:	00000073          	ecall
 ret
 42e:	8082                	ret

0000000000000430 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 430:	1101                	addi	sp,sp,-32
 432:	ec06                	sd	ra,24(sp)
 434:	e822                	sd	s0,16(sp)
 436:	1000                	addi	s0,sp,32
 438:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 43c:	4605                	li	a2,1
 43e:	fef40593          	addi	a1,s0,-17
 442:	00000097          	auipc	ra,0x0
 446:	f46080e7          	jalr	-186(ra) # 388 <write>
}
 44a:	60e2                	ld	ra,24(sp)
 44c:	6442                	ld	s0,16(sp)
 44e:	6105                	addi	sp,sp,32
 450:	8082                	ret

0000000000000452 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 452:	7139                	addi	sp,sp,-64
 454:	fc06                	sd	ra,56(sp)
 456:	f822                	sd	s0,48(sp)
 458:	f426                	sd	s1,40(sp)
 45a:	f04a                	sd	s2,32(sp)
 45c:	ec4e                	sd	s3,24(sp)
 45e:	0080                	addi	s0,sp,64
 460:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 462:	c299                	beqz	a3,468 <printint+0x16>
 464:	0805c863          	bltz	a1,4f4 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 468:	2581                	sext.w	a1,a1
  neg = 0;
 46a:	4881                	li	a7,0
 46c:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 470:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 472:	2601                	sext.w	a2,a2
 474:	00000517          	auipc	a0,0x0
 478:	47c50513          	addi	a0,a0,1148 # 8f0 <digits>
 47c:	883a                	mv	a6,a4
 47e:	2705                	addiw	a4,a4,1
 480:	02c5f7bb          	remuw	a5,a1,a2
 484:	1782                	slli	a5,a5,0x20
 486:	9381                	srli	a5,a5,0x20
 488:	97aa                	add	a5,a5,a0
 48a:	0007c783          	lbu	a5,0(a5)
 48e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 492:	0005879b          	sext.w	a5,a1
 496:	02c5d5bb          	divuw	a1,a1,a2
 49a:	0685                	addi	a3,a3,1
 49c:	fec7f0e3          	bgeu	a5,a2,47c <printint+0x2a>
  if(neg)
 4a0:	00088b63          	beqz	a7,4b6 <printint+0x64>
    buf[i++] = '-';
 4a4:	fd040793          	addi	a5,s0,-48
 4a8:	973e                	add	a4,a4,a5
 4aa:	02d00793          	li	a5,45
 4ae:	fef70823          	sb	a5,-16(a4)
 4b2:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4b6:	02e05863          	blez	a4,4e6 <printint+0x94>
 4ba:	fc040793          	addi	a5,s0,-64
 4be:	00e78933          	add	s2,a5,a4
 4c2:	fff78993          	addi	s3,a5,-1
 4c6:	99ba                	add	s3,s3,a4
 4c8:	377d                	addiw	a4,a4,-1
 4ca:	1702                	slli	a4,a4,0x20
 4cc:	9301                	srli	a4,a4,0x20
 4ce:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4d2:	fff94583          	lbu	a1,-1(s2)
 4d6:	8526                	mv	a0,s1
 4d8:	00000097          	auipc	ra,0x0
 4dc:	f58080e7          	jalr	-168(ra) # 430 <putc>
  while(--i >= 0)
 4e0:	197d                	addi	s2,s2,-1
 4e2:	ff3918e3          	bne	s2,s3,4d2 <printint+0x80>
}
 4e6:	70e2                	ld	ra,56(sp)
 4e8:	7442                	ld	s0,48(sp)
 4ea:	74a2                	ld	s1,40(sp)
 4ec:	7902                	ld	s2,32(sp)
 4ee:	69e2                	ld	s3,24(sp)
 4f0:	6121                	addi	sp,sp,64
 4f2:	8082                	ret
    x = -xx;
 4f4:	40b005bb          	negw	a1,a1
    neg = 1;
 4f8:	4885                	li	a7,1
    x = -xx;
 4fa:	bf8d                	j	46c <printint+0x1a>

00000000000004fc <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4fc:	7119                	addi	sp,sp,-128
 4fe:	fc86                	sd	ra,120(sp)
 500:	f8a2                	sd	s0,112(sp)
 502:	f4a6                	sd	s1,104(sp)
 504:	f0ca                	sd	s2,96(sp)
 506:	ecce                	sd	s3,88(sp)
 508:	e8d2                	sd	s4,80(sp)
 50a:	e4d6                	sd	s5,72(sp)
 50c:	e0da                	sd	s6,64(sp)
 50e:	fc5e                	sd	s7,56(sp)
 510:	f862                	sd	s8,48(sp)
 512:	f466                	sd	s9,40(sp)
 514:	f06a                	sd	s10,32(sp)
 516:	ec6e                	sd	s11,24(sp)
 518:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 51a:	0005c903          	lbu	s2,0(a1)
 51e:	18090f63          	beqz	s2,6bc <vprintf+0x1c0>
 522:	8aaa                	mv	s5,a0
 524:	8b32                	mv	s6,a2
 526:	00158493          	addi	s1,a1,1
  state = 0;
 52a:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 52c:	02500a13          	li	s4,37
      if(c == 'd'){
 530:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 534:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 538:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 53c:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 540:	00000b97          	auipc	s7,0x0
 544:	3b0b8b93          	addi	s7,s7,944 # 8f0 <digits>
 548:	a839                	j	566 <vprintf+0x6a>
        putc(fd, c);
 54a:	85ca                	mv	a1,s2
 54c:	8556                	mv	a0,s5
 54e:	00000097          	auipc	ra,0x0
 552:	ee2080e7          	jalr	-286(ra) # 430 <putc>
 556:	a019                	j	55c <vprintf+0x60>
    } else if(state == '%'){
 558:	01498f63          	beq	s3,s4,576 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 55c:	0485                	addi	s1,s1,1
 55e:	fff4c903          	lbu	s2,-1(s1)
 562:	14090d63          	beqz	s2,6bc <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 566:	0009079b          	sext.w	a5,s2
    if(state == 0){
 56a:	fe0997e3          	bnez	s3,558 <vprintf+0x5c>
      if(c == '%'){
 56e:	fd479ee3          	bne	a5,s4,54a <vprintf+0x4e>
        state = '%';
 572:	89be                	mv	s3,a5
 574:	b7e5                	j	55c <vprintf+0x60>
      if(c == 'd'){
 576:	05878063          	beq	a5,s8,5b6 <vprintf+0xba>
      } else if(c == 'l') {
 57a:	05978c63          	beq	a5,s9,5d2 <vprintf+0xd6>
      } else if(c == 'x') {
 57e:	07a78863          	beq	a5,s10,5ee <vprintf+0xf2>
      } else if(c == 'p') {
 582:	09b78463          	beq	a5,s11,60a <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 586:	07300713          	li	a4,115
 58a:	0ce78663          	beq	a5,a4,656 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 58e:	06300713          	li	a4,99
 592:	0ee78e63          	beq	a5,a4,68e <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 596:	11478863          	beq	a5,s4,6a6 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 59a:	85d2                	mv	a1,s4
 59c:	8556                	mv	a0,s5
 59e:	00000097          	auipc	ra,0x0
 5a2:	e92080e7          	jalr	-366(ra) # 430 <putc>
        putc(fd, c);
 5a6:	85ca                	mv	a1,s2
 5a8:	8556                	mv	a0,s5
 5aa:	00000097          	auipc	ra,0x0
 5ae:	e86080e7          	jalr	-378(ra) # 430 <putc>
      }
      state = 0;
 5b2:	4981                	li	s3,0
 5b4:	b765                	j	55c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 5b6:	008b0913          	addi	s2,s6,8
 5ba:	4685                	li	a3,1
 5bc:	4629                	li	a2,10
 5be:	000b2583          	lw	a1,0(s6)
 5c2:	8556                	mv	a0,s5
 5c4:	00000097          	auipc	ra,0x0
 5c8:	e8e080e7          	jalr	-370(ra) # 452 <printint>
 5cc:	8b4a                	mv	s6,s2
      state = 0;
 5ce:	4981                	li	s3,0
 5d0:	b771                	j	55c <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5d2:	008b0913          	addi	s2,s6,8
 5d6:	4681                	li	a3,0
 5d8:	4629                	li	a2,10
 5da:	000b2583          	lw	a1,0(s6)
 5de:	8556                	mv	a0,s5
 5e0:	00000097          	auipc	ra,0x0
 5e4:	e72080e7          	jalr	-398(ra) # 452 <printint>
 5e8:	8b4a                	mv	s6,s2
      state = 0;
 5ea:	4981                	li	s3,0
 5ec:	bf85                	j	55c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5ee:	008b0913          	addi	s2,s6,8
 5f2:	4681                	li	a3,0
 5f4:	4641                	li	a2,16
 5f6:	000b2583          	lw	a1,0(s6)
 5fa:	8556                	mv	a0,s5
 5fc:	00000097          	auipc	ra,0x0
 600:	e56080e7          	jalr	-426(ra) # 452 <printint>
 604:	8b4a                	mv	s6,s2
      state = 0;
 606:	4981                	li	s3,0
 608:	bf91                	j	55c <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 60a:	008b0793          	addi	a5,s6,8
 60e:	f8f43423          	sd	a5,-120(s0)
 612:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 616:	03000593          	li	a1,48
 61a:	8556                	mv	a0,s5
 61c:	00000097          	auipc	ra,0x0
 620:	e14080e7          	jalr	-492(ra) # 430 <putc>
  putc(fd, 'x');
 624:	85ea                	mv	a1,s10
 626:	8556                	mv	a0,s5
 628:	00000097          	auipc	ra,0x0
 62c:	e08080e7          	jalr	-504(ra) # 430 <putc>
 630:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 632:	03c9d793          	srli	a5,s3,0x3c
 636:	97de                	add	a5,a5,s7
 638:	0007c583          	lbu	a1,0(a5)
 63c:	8556                	mv	a0,s5
 63e:	00000097          	auipc	ra,0x0
 642:	df2080e7          	jalr	-526(ra) # 430 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 646:	0992                	slli	s3,s3,0x4
 648:	397d                	addiw	s2,s2,-1
 64a:	fe0914e3          	bnez	s2,632 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 64e:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 652:	4981                	li	s3,0
 654:	b721                	j	55c <vprintf+0x60>
        s = va_arg(ap, char*);
 656:	008b0993          	addi	s3,s6,8
 65a:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 65e:	02090163          	beqz	s2,680 <vprintf+0x184>
        while(*s != 0){
 662:	00094583          	lbu	a1,0(s2)
 666:	c9a1                	beqz	a1,6b6 <vprintf+0x1ba>
          putc(fd, *s);
 668:	8556                	mv	a0,s5
 66a:	00000097          	auipc	ra,0x0
 66e:	dc6080e7          	jalr	-570(ra) # 430 <putc>
          s++;
 672:	0905                	addi	s2,s2,1
        while(*s != 0){
 674:	00094583          	lbu	a1,0(s2)
 678:	f9e5                	bnez	a1,668 <vprintf+0x16c>
        s = va_arg(ap, char*);
 67a:	8b4e                	mv	s6,s3
      state = 0;
 67c:	4981                	li	s3,0
 67e:	bdf9                	j	55c <vprintf+0x60>
          s = "(null)";
 680:	00000917          	auipc	s2,0x0
 684:	26890913          	addi	s2,s2,616 # 8e8 <malloc+0x122>
        while(*s != 0){
 688:	02800593          	li	a1,40
 68c:	bff1                	j	668 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 68e:	008b0913          	addi	s2,s6,8
 692:	000b4583          	lbu	a1,0(s6)
 696:	8556                	mv	a0,s5
 698:	00000097          	auipc	ra,0x0
 69c:	d98080e7          	jalr	-616(ra) # 430 <putc>
 6a0:	8b4a                	mv	s6,s2
      state = 0;
 6a2:	4981                	li	s3,0
 6a4:	bd65                	j	55c <vprintf+0x60>
        putc(fd, c);
 6a6:	85d2                	mv	a1,s4
 6a8:	8556                	mv	a0,s5
 6aa:	00000097          	auipc	ra,0x0
 6ae:	d86080e7          	jalr	-634(ra) # 430 <putc>
      state = 0;
 6b2:	4981                	li	s3,0
 6b4:	b565                	j	55c <vprintf+0x60>
        s = va_arg(ap, char*);
 6b6:	8b4e                	mv	s6,s3
      state = 0;
 6b8:	4981                	li	s3,0
 6ba:	b54d                	j	55c <vprintf+0x60>
    }
  }
}
 6bc:	70e6                	ld	ra,120(sp)
 6be:	7446                	ld	s0,112(sp)
 6c0:	74a6                	ld	s1,104(sp)
 6c2:	7906                	ld	s2,96(sp)
 6c4:	69e6                	ld	s3,88(sp)
 6c6:	6a46                	ld	s4,80(sp)
 6c8:	6aa6                	ld	s5,72(sp)
 6ca:	6b06                	ld	s6,64(sp)
 6cc:	7be2                	ld	s7,56(sp)
 6ce:	7c42                	ld	s8,48(sp)
 6d0:	7ca2                	ld	s9,40(sp)
 6d2:	7d02                	ld	s10,32(sp)
 6d4:	6de2                	ld	s11,24(sp)
 6d6:	6109                	addi	sp,sp,128
 6d8:	8082                	ret

00000000000006da <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6da:	715d                	addi	sp,sp,-80
 6dc:	ec06                	sd	ra,24(sp)
 6de:	e822                	sd	s0,16(sp)
 6e0:	1000                	addi	s0,sp,32
 6e2:	e010                	sd	a2,0(s0)
 6e4:	e414                	sd	a3,8(s0)
 6e6:	e818                	sd	a4,16(s0)
 6e8:	ec1c                	sd	a5,24(s0)
 6ea:	03043023          	sd	a6,32(s0)
 6ee:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6f2:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6f6:	8622                	mv	a2,s0
 6f8:	00000097          	auipc	ra,0x0
 6fc:	e04080e7          	jalr	-508(ra) # 4fc <vprintf>
}
 700:	60e2                	ld	ra,24(sp)
 702:	6442                	ld	s0,16(sp)
 704:	6161                	addi	sp,sp,80
 706:	8082                	ret

0000000000000708 <printf>:

void
printf(const char *fmt, ...)
{
 708:	711d                	addi	sp,sp,-96
 70a:	ec06                	sd	ra,24(sp)
 70c:	e822                	sd	s0,16(sp)
 70e:	1000                	addi	s0,sp,32
 710:	e40c                	sd	a1,8(s0)
 712:	e810                	sd	a2,16(s0)
 714:	ec14                	sd	a3,24(s0)
 716:	f018                	sd	a4,32(s0)
 718:	f41c                	sd	a5,40(s0)
 71a:	03043823          	sd	a6,48(s0)
 71e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 722:	00840613          	addi	a2,s0,8
 726:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 72a:	85aa                	mv	a1,a0
 72c:	4505                	li	a0,1
 72e:	00000097          	auipc	ra,0x0
 732:	dce080e7          	jalr	-562(ra) # 4fc <vprintf>
}
 736:	60e2                	ld	ra,24(sp)
 738:	6442                	ld	s0,16(sp)
 73a:	6125                	addi	sp,sp,96
 73c:	8082                	ret

000000000000073e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 73e:	1141                	addi	sp,sp,-16
 740:	e422                	sd	s0,8(sp)
 742:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 744:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 748:	00001797          	auipc	a5,0x1
 74c:	8b87b783          	ld	a5,-1864(a5) # 1000 <freep>
 750:	a805                	j	780 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 752:	4618                	lw	a4,8(a2)
 754:	9db9                	addw	a1,a1,a4
 756:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 75a:	6398                	ld	a4,0(a5)
 75c:	6318                	ld	a4,0(a4)
 75e:	fee53823          	sd	a4,-16(a0)
 762:	a091                	j	7a6 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 764:	ff852703          	lw	a4,-8(a0)
 768:	9e39                	addw	a2,a2,a4
 76a:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 76c:	ff053703          	ld	a4,-16(a0)
 770:	e398                	sd	a4,0(a5)
 772:	a099                	j	7b8 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 774:	6398                	ld	a4,0(a5)
 776:	00e7e463          	bltu	a5,a4,77e <free+0x40>
 77a:	00e6ea63          	bltu	a3,a4,78e <free+0x50>
{
 77e:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 780:	fed7fae3          	bgeu	a5,a3,774 <free+0x36>
 784:	6398                	ld	a4,0(a5)
 786:	00e6e463          	bltu	a3,a4,78e <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 78a:	fee7eae3          	bltu	a5,a4,77e <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 78e:	ff852583          	lw	a1,-8(a0)
 792:	6390                	ld	a2,0(a5)
 794:	02059713          	slli	a4,a1,0x20
 798:	9301                	srli	a4,a4,0x20
 79a:	0712                	slli	a4,a4,0x4
 79c:	9736                	add	a4,a4,a3
 79e:	fae60ae3          	beq	a2,a4,752 <free+0x14>
    bp->s.ptr = p->s.ptr;
 7a2:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7a6:	4790                	lw	a2,8(a5)
 7a8:	02061713          	slli	a4,a2,0x20
 7ac:	9301                	srli	a4,a4,0x20
 7ae:	0712                	slli	a4,a4,0x4
 7b0:	973e                	add	a4,a4,a5
 7b2:	fae689e3          	beq	a3,a4,764 <free+0x26>
  } else
    p->s.ptr = bp;
 7b6:	e394                	sd	a3,0(a5)
  freep = p;
 7b8:	00001717          	auipc	a4,0x1
 7bc:	84f73423          	sd	a5,-1976(a4) # 1000 <freep>
}
 7c0:	6422                	ld	s0,8(sp)
 7c2:	0141                	addi	sp,sp,16
 7c4:	8082                	ret

00000000000007c6 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7c6:	7139                	addi	sp,sp,-64
 7c8:	fc06                	sd	ra,56(sp)
 7ca:	f822                	sd	s0,48(sp)
 7cc:	f426                	sd	s1,40(sp)
 7ce:	f04a                	sd	s2,32(sp)
 7d0:	ec4e                	sd	s3,24(sp)
 7d2:	e852                	sd	s4,16(sp)
 7d4:	e456                	sd	s5,8(sp)
 7d6:	e05a                	sd	s6,0(sp)
 7d8:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7da:	02051493          	slli	s1,a0,0x20
 7de:	9081                	srli	s1,s1,0x20
 7e0:	04bd                	addi	s1,s1,15
 7e2:	8091                	srli	s1,s1,0x4
 7e4:	0014899b          	addiw	s3,s1,1
 7e8:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7ea:	00001517          	auipc	a0,0x1
 7ee:	81653503          	ld	a0,-2026(a0) # 1000 <freep>
 7f2:	c515                	beqz	a0,81e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7f4:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7f6:	4798                	lw	a4,8(a5)
 7f8:	02977f63          	bgeu	a4,s1,836 <malloc+0x70>
 7fc:	8a4e                	mv	s4,s3
 7fe:	0009871b          	sext.w	a4,s3
 802:	6685                	lui	a3,0x1
 804:	00d77363          	bgeu	a4,a3,80a <malloc+0x44>
 808:	6a05                	lui	s4,0x1
 80a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 80e:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 812:	00000917          	auipc	s2,0x0
 816:	7ee90913          	addi	s2,s2,2030 # 1000 <freep>
  if(p == (char*)-1)
 81a:	5afd                	li	s5,-1
 81c:	a88d                	j	88e <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 81e:	00000797          	auipc	a5,0x0
 822:	7f278793          	addi	a5,a5,2034 # 1010 <base>
 826:	00000717          	auipc	a4,0x0
 82a:	7cf73d23          	sd	a5,2010(a4) # 1000 <freep>
 82e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 830:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 834:	b7e1                	j	7fc <malloc+0x36>
      if(p->s.size == nunits)
 836:	02e48b63          	beq	s1,a4,86c <malloc+0xa6>
        p->s.size -= nunits;
 83a:	4137073b          	subw	a4,a4,s3
 83e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 840:	1702                	slli	a4,a4,0x20
 842:	9301                	srli	a4,a4,0x20
 844:	0712                	slli	a4,a4,0x4
 846:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 848:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 84c:	00000717          	auipc	a4,0x0
 850:	7aa73a23          	sd	a0,1972(a4) # 1000 <freep>
      return (void*)(p + 1);
 854:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 858:	70e2                	ld	ra,56(sp)
 85a:	7442                	ld	s0,48(sp)
 85c:	74a2                	ld	s1,40(sp)
 85e:	7902                	ld	s2,32(sp)
 860:	69e2                	ld	s3,24(sp)
 862:	6a42                	ld	s4,16(sp)
 864:	6aa2                	ld	s5,8(sp)
 866:	6b02                	ld	s6,0(sp)
 868:	6121                	addi	sp,sp,64
 86a:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 86c:	6398                	ld	a4,0(a5)
 86e:	e118                	sd	a4,0(a0)
 870:	bff1                	j	84c <malloc+0x86>
  hp->s.size = nu;
 872:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 876:	0541                	addi	a0,a0,16
 878:	00000097          	auipc	ra,0x0
 87c:	ec6080e7          	jalr	-314(ra) # 73e <free>
  return freep;
 880:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 884:	d971                	beqz	a0,858 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 886:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 888:	4798                	lw	a4,8(a5)
 88a:	fa9776e3          	bgeu	a4,s1,836 <malloc+0x70>
    if(p == freep)
 88e:	00093703          	ld	a4,0(s2)
 892:	853e                	mv	a0,a5
 894:	fef719e3          	bne	a4,a5,886 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 898:	8552                	mv	a0,s4
 89a:	00000097          	auipc	ra,0x0
 89e:	b56080e7          	jalr	-1194(ra) # 3f0 <sbrk>
  if(p == (char*)-1)
 8a2:	fd5518e3          	bne	a0,s5,872 <malloc+0xac>
        return 0;
 8a6:	4501                	li	a0,0
 8a8:	bf45                	j	858 <malloc+0x92>

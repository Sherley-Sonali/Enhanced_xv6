#ifndef SYSCOUNT
#define SYSCOUNT
// This is the count printed by getsyscount
extern int the_count;
//extern int system_call_count[31];
#define SYS_MAX 31
extern int system_call_count[SYS_MAX];
#endif
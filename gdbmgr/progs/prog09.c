/* pingpong.c: this program tests out a two thread idea
 *             where two threads ping-pong
 *   Author: Charles E. Campbell, Jr.
 *   Date:   Jan 09, 2009
 */

/* =====================================================================
 * Header Section: {{{1
 */

/* ---------------------------------------------------------------------
 * Includes: {{{2
 */
#include <stdio.h>
#include <math.h>
#include <pthread.h>

/* ------------------------------------------------------------------------
 * Definitions: {{{2
 */
#define LOOPS 100
#define IMAX  10000

#define NRML    "\e[m"
#define GREEN   "\e[32m"
#define YELLOW  "\e[33m"
#define RED     "\e[31m"

/* ------------------------------------------------------------------------
 * Global Data: {{{2
 */
pthread_mutex_t pingmtx = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t pongmtx = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t  pingcv  = PTHREAD_COND_INITIALIZER;
pthread_cond_t  pongcv  = PTHREAD_COND_INITIALIZER;
int             minprio;
int             maxprio;
int             nrmlprio;
int             specprio;

/* ------------------------------------------------------------------------
 * Prototypes: {{{2
 */
int main( int, char **);                /* pingpong.c */
void Ping(int *);                       /* pingpong.c */
void Pong(int *);                       /* pingpong.c */
static void SchedReport(char *,char *); /* pingpong.c */

/* ========================================================================
 * Functions: {{{1
 */

/* --------------------------------------------------------------------- */
/* main: {{{2 */
int main(
  int    argc,
  char **argv)
{
pthread_attr_t     attr;
pthread_t          ping;
pthread_t          pong;
int                pingresult;
int                pongresult;
struct sched_param mainsp;

/* determine normal and special priority */
minprio               = sched_get_priority_min(SCHED_FIFO);
maxprio               = sched_get_priority_max(SCHED_FIFO);
nrmlprio              = (minprio + maxprio)/2;
specprio              = nrmlprio + 1;
mainsp.sched_priority = nrmlprio;
pthread_setschedparam(pthread_self(),SCHED_FIFO,&mainsp);

pthread_attr_init(&attr);
pthread_attr_setschedpolicy(&attr,SCHED_FIFO);
pthread_attr_setschedparam(&attr,&mainsp);

pthread_create(&ping,&attr,(void *) Ping,&pingresult);
pthread_create(&pong,&attr,(void *) Pong,&pongresult);
sched_yield();
pthread_cond_signal(&pingcv);

pthread_join(ping,NULL);
pthread_join(pong,NULL);

printf("ping result=%d\n",NRML,pingresult);
printf("pong result=%d\n",NRML,pongresult);
}

/* --------------------------------------------------------------------- */
/* Ping: this function {{{2 */
void Ping(int *result)
{
int                loop;
int                i;
double             x;
struct sched_param nrmlsp;
struct sched_param specsp;

nrmlsp.sched_priority= nrmlprio;
specsp.sched_priority= specprio;

for(loop= 0; loop < LOOPS; ++loop) {
	pthread_setschedparam(pthread_self(),SCHED_FIFO,&specsp);
	SchedReport(GREEN,"ping");
	pthread_cond_signal(&pongcv);
	pthread_mutex_lock(&pingmtx);
	pthread_cond_wait(&pingcv,&pingmtx);
	pthread_mutex_unlock(&pingmtx);
	pthread_setschedparam(pthread_self(),SCHED_FIFO,&nrmlsp);
	sched_yield();
	for(i= 0, x= 0.; i < IMAX; ++i) {
		x+= sin((double) i*M_PI/IMAX);
		}
	printf("%sping#%2d: x=%le\n",GREEN,loop,x); fflush(stdout);
	}
printf("%sping now trying to exit\n",YELLOW); fflush(stdout);
pthread_cond_signal(&pongcv);
printf("ping: GOT HERE#1\n"); fflush(stdout);

*result= (int) x;
printf("ping: GOT HERE#2\n"); fflush(stdout);

sched_yield();
pthread_exit(NULL);
}

/* --------------------------------------------------------------------- */
/* Pong: this function {{{2 */
void Pong(int *result)
{
int    loop;
int    i;
double x;
struct sched_param nrmlsp;
struct sched_param specsp;


nrmlsp.sched_priority= nrmlprio;
specsp.sched_priority= specprio;

for(loop= 0; loop < LOOPS; ++loop) {
	pthread_setschedparam(pthread_self(),SCHED_FIFO,&specsp);
	SchedReport(RED,"pong");
	pthread_cond_signal(&pingcv);
	pthread_mutex_lock(&pongmtx);
	pthread_cond_wait(&pongcv,&pongmtx);
	pthread_mutex_unlock(&pongmtx);
	pthread_setschedparam(pthread_self(),SCHED_FIFO,&nrmlsp);
	sched_yield();
	for(i= 0, x= 0.; i < IMAX; ++i) {
		x+= sin((double) i*M_PI/IMAX);
		}
	printf("%spong#%2d: x=%le\n",RED,loop,x); fflush(stdout);
	}
printf("%spong now trying to exit\n",YELLOW); fflush(stdout);
pthread_cond_signal(&pingcv);
printf("pong: GOT HERE#1\n"); fflush(stdout);

*result= (int) x;
printf("pong: GOT HERE#2\n"); fflush(stdout);

sched_yield();
pthread_exit(NULL);
}

/* --------------------------------------------------------------------- */
/* SchedReport: this function unfortunately demonstrates that the process is not allowed to change scheduling or priority {{{2 */
static void SchedReport(char *escseq,char *thrdname)
{
struct sched_param sp;
int                policy;

pthread_getschedparam(pthread_self(),&policy,&sp);
printf("%s%s  : policy=%d<%s> priority=%d\n",
  escseq,thrdname,
  policy,
  (policy == SCHED_RR)?    "rr"    :
  (policy == SCHED_FIFO)?  "fifo"  :
  (policy == SCHED_OTHER)? "other" : "???",
  sp.sched_priority);
}

/* --------------------------------------------------------------------- */
/* Modelines: {{{1
 * vim: fdm=marker
 */

/* prog8.c : example program illustrating threads with gdbmgr
 *   Author: Charles Campbell
 *   Date: Oct 26, 2010
 */

/* =====================================================================
 * Header Section: {{{1
 */

/* ---------------------------------------------------------------------
 * Includes: {{{2
 */
#include <stdio.h>
#include <unistd.h>
#include <pthread.h>

/* ---------------------------------------------------------------------
 * Prototypes: {{{2
 */
void procA(int *);
void procB(int *);
int  resA;
int  resB;

/* =====================================================================
 * Functions: {{{1
 */

/* ---------------------------------------------------------------------
 * main: {{{2
 */
int main(int argc,char **argv)
{
pthread_t thrdA;
pthread_t thrdB;

pthread_create(
  &thrdA,			/* pthread_t                        */
  NULL,				/* attribute                        */
  (void *) procA,	/* starting routine for this thread */
  (void *) &resA);	/* argument supplied to this thread */
pthread_create(
  &thrdB,			/* pthread_t                        */
  NULL,				/* attribute                        */
  (void *) procB,	/* starting routine for this thread */
  (void *) &resB);	/* argument supplied to this thread */

pthread_join(thrdA,NULL);
pthread_join(thrdB,NULL);

return 0;
}

/* ---------------------------------------------------------- */
/* procA: {{{2 */
void procA(int *inpA)
{
int i;
int j;
int x;

for(i= 0; i < 4; ++i) {
	printf("procA\n");
	sleep(1);
	}
pthread_exit(NULL);
}

/* ---------------------------------------------------------- */
/* procB: {{{2 */
void procB(int *inpA)
{
int i;
int j;
int x;

for(i= 0; i < 4; ++i) {
	printf("procB\n");
	sleep(1);
	}
pthread_exit(NULL);
}

/* ===================================================================== */
/* Modelines: {{{1
 *  vim: fdm=marker
 */

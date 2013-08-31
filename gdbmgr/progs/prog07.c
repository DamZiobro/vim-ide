/* prog7.c: this program
 *   Author: Charles E. Campbell, Jr.
 *   Date:   Jan 03, 2009
 */

/* =====================================================================
 * Header Section: {{{1
 */

/* ---------------------------------------------------------------------
 * Includes: {{{2
 */
#include <stdio.h>

/* ------------------------------------------------------------------------
 * Prototypes: {{{2
 */
int main( int, char **); /* prog7.c */
int Func1(int);          /* prog7.c */
int Func2();             /* prog7.c */

/* ========================================================================
 * Functions: {{{1
 */

/* --------------------------------------------------------------------- */
/* main: {{{2 */
int main(
  int    argc,
  char **argv)
{
int x = 0;
int y = 0;

y= x;
y= Func1(1);
printf("y=%d\n",y);

return 0;
}

/* --------------------------------------------------------------------- */
/* Func1: this function simply calls Func2 with one added to its input arg {{{2 */
int Func1(int x)
{
x= Func2(x + 1);
return x;
}

/* --------------------------------------------------------------------- */
/* Func2: this function doubles its input {{{2 */
int Func2(x)
{
x= x*2;
return x;
}

/* ===================================================================== */
/* Modelines: {{{1
 * vim: fdm=marker
 */

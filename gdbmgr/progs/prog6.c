/* prog6.c: this program issues two prompts and asks for input each time
 *   Author: Charles E. Campbell, Jr.
 *   Date:   Dec 31, 2008
 */

/* =====================================================================
 * Header Section: {{{1
 */

/* ---------------------------------------------------------------------
 * Includes: {{{2
 */
#include <stdio.h>
#include <string.h>

/* ------------------------------------------------------------------------
 * Definitions: {{{2
 */
#define BUFSIZE	256

/* ========================================================================
 * Functions: {{{1
 */

/* --------------------------------------------------------------------- */
/* main: {{{2 */
int main(
  int    argc,
  char **argv)
{
char buf[BUFSIZE];

printf("Enter something#1: ");
fgets(buf,BUFSIZE,stdin);
buf[strlen(buf)-1]= '\0'; /* remove trailing newline */
printf("Entered buf<%s>\n",buf);

printf("Enter something#2: ");
fgets(buf,BUFSIZE,stdin);
buf[strlen(buf)-1]= '\0'; /* remove trailing newline */
printf("Entered buf<%s>\n",buf);

return 0;
}

/* ===================================================================== */
/* Modelines: {{{1
 * vim: fdm=marker
 */

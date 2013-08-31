/* gdbmgr.h: this header file supports the gdbmgr program
 *  Author: Charles E. Campbell, Jr.
 *  Date:   Nov 21, 2008
 */

/* =====================================================================
 * Header Section: {{{1
 */

/* ------------------------------------------------------------------------
 * Includes: {{{2
 */
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/shm.h>
#include <sys/ipc.h>

/* ------------------------------------------------------------------------
 * Definitions: {{{2
 */
#define BUFSIZE         65536
#define EOA             ((char)0xff)
#define MAXATTCH		32
#define MEDBUFSIZE      4096
#define SHMKEY          ((key_t) 3316)
#define SHORTWAITCNTMAX 15
#define SHORTWAIT       usleep((useconds_t) 20000)
#define SMBUFSIZE       128

/* ---------------------------------------------------------------------
 * Debugging Support: {{{2
 */
#ifdef DEBUG
# define Dprintf(x) {FILE *fp; fp= fopen("tmp.gdbmgr","a"); fprintf(fp,"|"); fprintf x; fclose(fp); }
# define Edbg(x)    {FILE *fp; fp= fopen("tmp.gdbmgr","a"); fprintf x; fprintf(fp," {\n"); fclose(fp); }
# define Rdbg(x)    {FILE *fp; fp= fopen("tmp.gdbmgr","a"); fprintf(fp,"|return "); fprintf x; fprintf(fp," }\n"); fclose(fp); }
#else
# define Dprintf(x)
# define Edbg(x)
# define Initdbg(x)
# define Rdbg(x)
#endif

/* ------------------------------------------------------------------------
 * Enumerations: {{{2
 */

/* ------------------------------------------------------------------------
 * Typedefs: {{{2
 */
typedef struct GdbMgr_str GdbMgr;

/* ------------------------------------------------------------------------
 * Data Structures: {{{2
 */
struct GdbMgr_str {
	char   mlbuf[BUFSIZE];         /* multi-line buffer                                       */
	char   gdbmgrbuf[SMBUFSIZE];   /* small buffer                                            */
	char   errmsg[MEDBUFSIZE];     /* medium buffer for error messages                        */
	int    shmid;                  /* shared memory id                                        */
	int    init;                   /* indicates if its being initialized the first time       */
	int    rwfd;                   /* master-side read-write file descriptor                  */
	int    nbrfd;                  /* non-blocking read from rwfd file descriptor             */
	int    running;                /* indicates if vdlGdb is in run (starting..stopping) mode */
	int    runstate;               /* FSA to determine whether to stop running                */
	pid_t  gdbpid;                 /* process id of gdb                                       */
	};

/* ------------------------------------------------------------------------
 * Options: {{{2
 */

/* ------------------------------------------------------------------------
 * Global Data: {{{2
 */
#ifdef MAIN_PROG
GdbMgr *gdbmgr= NULL;
#endif

/* ------------------------------------------------------------------------
 * Prototypes: {{{2
 */
char *gmInit(char *);  /* gdbmgr.c */
char *gmGdb(char *);   /* gdbmgr.c */
char *gmPoll(char *);  /* gdbmgr.c */
char *gmClose(char *); /* gdbmgr.c */


/* ===================================================================== */
/* Modelines: {{{1
 *  vim: fdm=marker
 */

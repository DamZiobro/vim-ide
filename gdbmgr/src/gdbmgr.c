/* gdbmgr.c: this program provides an interface between vim and gdb
 *           via vim's libcall() mechanism and gdb's annotate level 3
 *   Author: Charles E. Campbell, Jr.
 *   Date:   Nov 18, 2008
 *
 *   See http://davis.lbl.gov/Manuals/GDB/gdb_23.html
 *   for information on gdb and annotations.
 */

/* =====================================================================
 * Header Section: {{{1
 */

/* ---------------------------------------------------------------------
 * Includes: {{{2
 */
/*#define DEBUG*/
#define MAIN_PROG
#include "gdbmgr.h"
#ifndef DEBUG
# undef Dprintf
# undef Edbg
# undef Initdbg
# undef Rdbg
# define Dprintf(x)
# define Edbg(x)
# define Initdbg(x)
# define Rdbg(x)
#endif

/* ---------------------------------------------------------------------
 * Definitions: {{{2
 */
#define STOPPED  0 /* S */
#define RUNNING  1 /* R */
#define QUERY    2 /* Q */
#define COMMANDS 3 /* C */

/* ---------------------------------------------------------------------
 * Prototypes: {{{2
 */
static void GetGdbMgr(void);         /* gdbmgr.c */
static void CloseGdbMgr(void);       /* gdbmgr.c */
static char *fdputs(char *,int);     /* gdbmgr.c */
static char *fdgets(char *,int,int); /* gdbmgr.c */

/* ========================================================================
 * Functions: {{{1
 */

/* --------------------------------------------------------------------- */
/* gmInit: this function sets up a child process (gdb) and pipes to communicate with it {{{2 */
char *gmInit(char *gdbcmd)
{
char           *ret      = NULL;
int             fd[2];
int             pid;
int             rwfd     = -1;
struct termios  stermios;

Edbg((fp,"gmInit(gdbcmd<%s>)",gdbcmd));

/* initialize gdbmgr */
GetGdbMgr();       /* this call initializes gdbmgr to a valid pointer and gdbmgr->shmid */
if(!gdbmgr) {
	Rdbg((fp,"gmInit <***error*** ...> : unable to access GdbMgr memory"));
	return "***error*** (gmInit) unable to access GdbMgr memory";
	}
gdbmgr->mlbuf[0]     = '\0';
gdbmgr->init         = 2;       /* indicates initialization needed to gmGdb()        */
gdbmgr->rwfd         = -1;      /* blocking read from rwfd file descriptor           */
gdbmgr->gdbpid       = 0;
gdbmgr->gdbmgrbuf[0] = '\0';
gdbmgr->running      = STOPPED; /* indicate that user program is not running, gdb is */
gdbmgr->nbrfd        = -1;      /* non-blocking read from rwfd file descriptor       */
gdbmgr->runstate     = 0;

/* open a pseudo-terminal interface to gdb */
pid= gdbmgr->gdbpid= forkpty(&rwfd,NULL,NULL,NULL);
if(pid < 0) {
	sprintf(gdbmgr->gdbmgrbuf,"***error*** %s",strerror(errno));
	Rdbg((fp,"gmInit <%s> : badfork",gdbmgr->gdbmgrbuf));
	return gdbmgr->gdbmgrbuf;
	}
else if(pid == 0) { /* child process */
	/* set up stdin/stdout/stderr to and from the child process to use the slave end of the pseudo-terminal */
	Dprintf((fp,"child process began (pid#%d) rwfd#%d  (will become gdb)\n",getpid(),rwfd));
	/* the gdb process will have its stdin, stdout, and stderr
	 * going through the pseudo-terminal slave.
	 * Turn echo'ing off.  Turn NL -> CR/NL output mapping off.
	 */
	if(tcgetattr(STDIN_FILENO,&stermios) >= 0) {
		stermios.c_lflag &= ~(ECHO | ECHOE | ECHOK | ECHONL);
		stermios.c_oflag &= ~(ONLCR);
		(void) tcsetattr(STDIN_FILENO,TCSANOW,&stermios);
		}
	/* Will now exec gdb, thereby using it as the child process.
	 */
	Dprintf((fp,"(child) about to execlp \"gdb --annotate=3\"\n"));
	if(execlp("gdb","gdb","--annotate=3",(char *) NULL) < 0) {
		sprintf(gdbmgr->gdbmgrbuf,"***error*** %s",strerror(errno));
		Rdbg((fp,"gmInit <%s> : (child) badexec",gdbmgr->gdbmgrbuf));
		return gdbmgr->gdbmgrbuf;
		}
	}
else { /* parent process */
	Dprintf((fp,"gmInit: parent process began  (child pid#%d  rwfd#%d)\n",pid,rwfd));

	/* the rwfd here provides i/o through the master end of the pseudo-terminal */
	gdbmgr->rwfd= rwfd;
	Dprintf((fp,"gmInit: (parent) rwfd#%d\n",gdbmgr->rwfd));

	/* avoid prompt-for-continue prompts */
	(void) gmGdb(NULL);           /* eat the initial startup text; gmGdb() changes init to 1        */
	gdbmgr->init= 0;              /* indicate that gmGdb() may now start detaching shared memory    */
	(void) gmGdb("set height 0"); /* avoids some prompts from gdb                                   */
	(void) gmGdb("set width 0");  /* avoids having gdb wrap the text, introducing unwanted newlines */
	}

Rdbg((fp,"gmInit \"gdb ready\""));
return "gdb ready";
}

/* --------------------------------------------------------------------- */
/* gmGdb: this function acts as the interface between gdb and vim {{{2
 *        uses blocking read&write file descriptor (rwfd)
 *        Does not support polling.
 *        Returns "S" + message (not in running mode == stopped == gdb not accepting commands, the pgm is)
 *                "R" + message (    in running mode)
 *                "Q" + message (    in query   mode)
 */
char *gmGdb(char *gdbcmd)
{
char    buf[MEDBUFSIZE];
char   *mlb             = NULL;
int     exitstatus      = -1;
int     record2mlbuf    = 1;
int     shortwaitcnt;
size_t  buflen;

/* the way vim implements libcall() means that no data may be retained between
 * invocations as global variables (or static ones inside functions).
 */
Edbg((fp,"gmGdb(gdbcmd<%s>)",gdbcmd? gdbcmd : "-null-"));
GetGdbMgr(); /* get GdbMgr pointer */
Dprintf((fp,"gdbmgr=%px gdbcmd<%s> running=%d<%s>\n",
  gdbmgr,
  gdbcmd?                                  gdbcmd          : "-null-",
  gdbmgr?                                  gdbmgr->running : -1,
  (gdbmgr && gdbmgr->running == STOPPED)?  "stopped"       :
  (gdbmgr && gdbmgr->running == RUNNING)?  "running"       :
  (gdbmgr && gdbmgr->running == QUERY)?    "query"         :
  (gdbmgr && gdbmgr->running == COMMANDS)? "commands"      : "???"));
if(!gdbmgr) {
	Rdbg((fp,"gmGdb : unable to access GdbMgr memory"));
	return "***error*** (gmGdb) unable to access GdbMgr memory";
	}
Dprintf((fp,"gdbmgr: gdbpid#%d rwfd#%d\n",
  gdbmgr? gdbmgr->gdbpid : -1,
  gdbmgr? gdbmgr->rwfd   : -1));

/* initial interaction with gdb */
if(gdbmgr->init == 2) {
	gdbmgr->init= 1;

	/* look for prompt */
	shortwaitcnt= 0;
	Dprintf((fp,"(gmGdb) stage-1: look for prompt\n"));
	while(1) {
		Dprintf((fp,"(gmGdb) stage-1: mlbuf<%s>\n",gdbmgr->mlbuf));
		if(!fdgets(buf,MEDBUFSIZE,gdbmgr->rwfd)) {
			if(++shortwaitcnt > SHORTWAITCNTMAX) {
				Dprintf((fp,"(gmGdb) stage-1: looking for prompt shortwaitcnt>%d!\n",SHORTWAITCNTMAX));
				strcpy(gdbmgr->mlbuf,"Sgdb not responding as expected");
				if     (gdbmgr->running == RUNNING)  gdbmgr->mlbuf[0]= 'R';
				else if(gdbmgr->running == QUERY)    gdbmgr->mlbuf[0]= 'Q';
				else if(gdbmgr->running == COMMANDS) gdbmgr->mlbuf[0]= 'C';
				Rdbg((fp,"gmGdb <%s>",gdbmgr->mlbuf));
				return gdbmgr->mlbuf;
				}
			SHORTWAIT;
			continue;
			}
		else shortwaitcnt= 0;
    	Dprintf((fp,"(gmGdb) stage-1: init, buf<%s>\n",buf));
        if(!strcmp(buf,"\x1a\x1aprompt")) {        /* the annotate=3 prompt string     */
			Dprintf((fp,"(gmGdb) stage-1: [prompt] encountered\n"));
			strcpy(gdbmgr->mlbuf,"Sgdb ready");
			if     (gdbmgr->running == RUNNING)  gdbmgr->mlbuf[0]= 'R';
			else if(gdbmgr->running == QUERY)    gdbmgr->mlbuf[0]= 'Q';
			else if(gdbmgr->running == COMMANDS) gdbmgr->mlbuf[0]= 'C';
			Rdbg((fp,"gmGdb <%s>",gdbmgr->mlbuf));
			return gdbmgr->mlbuf;
			}
		}
	}

Dprintf((fp,"(gmGdb) stage-2: initialize buffer%s\n",(gdbcmd[0] != '\0')? ", send command to gdb" : ""));
/* initialize mlbuf (multi-line buffer) to empty */
mlb              = gdbmgr->mlbuf + 1;
if     (gdbmgr->running == STOPPED)  gdbmgr->mlbuf[0]= 'S';
else if(gdbmgr->running == RUNNING)  gdbmgr->mlbuf[0]= 'R';
else if(gdbmgr->running == QUERY)    gdbmgr->mlbuf[0]= 'Q';
else if(gdbmgr->running == COMMANDS) gdbmgr->mlbuf[0]= 'C';
else                                 gdbmgr->mlbuf[0]= '?';
gdbmgr->mlbuf[1] = '\0';
Dprintf((fp,"(gmGdb) stage-2: mlbuf initialized to empty\n"));

/* fdputs the command to gdb */
if(gdbcmd && gdbcmd[0] != '\0') {
	Dprintf((fp,"(gmGdb) stage-2: sending<%s>\n",gdbcmd));
	fdputs(gdbcmd,gdbmgr->rwfd);
	SHORTWAIT;
	}

/* check if the user's program just stopped */
if(gdbmgr->running == RUNNING || gdbmgr->running == QUERY || gdbmgr->running == COMMANDS) {
	char *ret;
	if(buf[0] == '\x1a' && buf[1] == '\x1a') {
		if(!strncmp(buf+2,"stopped",7)  ||
		   !strncmp(buf+2,"exited",6)   ||
		   !strncmp(buf+2,"signalled",9)) {
			Dprintf((fp,"(gmGdb) stage-2: program in running<%s> received<%s>.  Switching to<stopped>\n",
			  (gdbmgr && gdbmgr->running == STOPPED)?  "stopped"   :
			  (gdbmgr && gdbmgr->running == RUNNING)?  "running"   :
			  (gdbmgr && gdbmgr->running == QUERY)?    "query"     :
			  (gdbmgr && gdbmgr->running == COMMANDS)? "commands"  : "???",
			  !strncmp(buf+2,"stopped",7)?             "stopped"   :
			  !strncmp(buf+2,"exited",6)?              "exited"    :
			  !strncmp(buf+2,"signalled",9)?           "signalled" : "???"));
			gdbmgr->running  = STOPPED;
			record2mlbuf     = 0;
			gdbmgr->mlbuf[0] = 'S';
			strcpy(gdbmgr->mlbuf,buf+2);
			}
		}
	}

/* check if the user's program has (resumed) running */
else if(gdbmgr->running == STOPPED) {
	if(buf[0] == '\x1a' && buf[1] == '\x1a') {
		if(!strncmp(buf+2,"Continuing.",11)) {
			gdbmgr->running  = RUNNING;
			gdbmgr->mlbuf[0] = 'R';
			Dprintf((fp,"(gmGdb) stage-2: program in running<stopped> received<Continuing.>.  Switching to running<%s>\n",
			  (gdbmgr && gdbmgr->running == STOPPED)?  "stopped"       :
			  (gdbmgr && gdbmgr->running == RUNNING)?  "running"       :
			  (gdbmgr && gdbmgr->running == QUERY)?    "query"         :
			  (gdbmgr && gdbmgr->running == COMMANDS)? "commands"      : "???"));
			}
		}
	}

/* look for post-prompt */
Dprintf((fp,"(gmGdb) stage-3: look for <c-z><c-z>post-prompt\n"));
shortwaitcnt= 0;
while(1) {
	Dprintf((fp,"(gmGdb) stage-3: mlbuf<%s>\n",gdbmgr->mlbuf));
	if(!fdgets(buf,MEDBUFSIZE,gdbmgr->rwfd)) {
		if(++shortwaitcnt > SHORTWAITCNTMAX) {
			Dprintf((fp,"(gmGdb) stage-3: looking for post-prompt shortwaitcnt>%d!\n",shortwaitcnt));
			strcpy(gdbmgr->mlbuf,"Sgdb not responding as expected");
			gdbmgr->running  = STOPPED;
			record2mlbuf     = 0;
			Rdbg((fp,"gmGdb <%s>",gdbmgr->mlbuf));
			return gdbmgr->mlbuf;
			}
		SHORTWAIT;
		continue;
		}
	else shortwaitcnt= 0;
    Dprintf((fp,"(gmGdb) stage-3: looking for post-prompt: buf<%s> gdbmgr->running=%d<%s>  (will attempt to recognize)\n",
	  buf,
	  gdbmgr->running,
	  (gdbmgr->running == STOPPED)?  "S" :
	  (gdbmgr->running == RUNNING)?  "R" :
	  (gdbmgr->running == QUERY)?    "Q" :
	  (gdbmgr->running == COMMANDS)? "C" : "?"));
	if(buf[0] == '\x1a' && buf[1] == '\x1a') {
		Dprintf((fp,"(gmGdb) stage-3: buf[0] and buf[1] both are <c-z>\n"));
		if(!strncmp(buf+2,"post-prompt",11)) {
			Dprintf((fp,"(gmGdb) stage-3: [post-prompt] encountered\n"));
			break;
			}
		else if(!strncmp(buf+2,"breakpoint ",10)) {
			gdbmgr->running  = STOPPED;
			gdbmgr->mlbuf[0] = 'S';
			strcpy(gdbmgr->mlbuf+1,buf);
			sscanf(buf+2,"%*s %d",&exitstatus);
			Rdbg((fp,"gmGdb <%s> : [breakpoint] encountered",gdbmgr->mlbuf,exitstatus));
			return gdbmgr->mlbuf;
			}
		else if(!strncmp(buf+2,"exited ",7)) {
			gdbmgr->running  = STOPPED;
			gdbmgr->mlbuf[0] = 'S';
			strcpy(gdbmgr->mlbuf+1,buf);
			sscanf(buf+2,"%*s %d",&exitstatus);
			Rdbg((fp,"gmGdb <%s> : [exited %d] encountered",gdbmgr->mlbuf,exitstatus));
			return gdbmgr->mlbuf;
			}
		else if(!strncmp(buf+2,"commands",8)) {
			gdbmgr->running= COMMANDS;
			gdbmgr->mlbuf[0] = 'C';
			Rdbg((fp,"gmGdb <%s> : [exited %d] encountered",gdbmgr->mlbuf,exitstatus));
			return gdbmgr->mlbuf;
			}
		else if(!strncmp(buf+2,"starting",8)) {
			gdbmgr->running  = RUNNING;
			gdbmgr->mlbuf[0] = 'R';
			strcpy(gdbmgr->mlbuf+1,buf+2);
			Rdbg((fp,"gmGdb <%s> : [starting] encountered",gdbmgr->mlbuf));
			return gdbmgr->mlbuf;
			}
		else if(!strncmp(buf+2,"stopped",7)) {
			gdbmgr->running  = STOPPED;
			gdbmgr->mlbuf[0] = 'S';
			strcpy(gdbmgr->mlbuf+1,buf+2);
			Dprintf((fp,"(gmGdb) stage-3: [%s] encountered\n",gdbmgr->mlbuf));
			continue;
			}
		else if(!strncmp(buf+2,"signalled",9)) {
			gdbmgr->running  = STOPPED;
			gdbmgr->mlbuf[0] = 'S';
			strcpy(gdbmgr->mlbuf+1,buf+2);
			Dprintf((fp,"(gmGdb) stage-3: [signalled %d] encountered\n",exitstatus));
			continue;
			}
		else if(!strncmp(buf+2,"post-commands",13)) {
			gdbmgr->running  = STOPPED;
			gdbmgr->mlbuf[0] = 'S';
			strcpy(gdbmgr->mlbuf+1,buf+2);
			Dprintf((fp,"(gmGdb) stage-3: [post-commands] encountered\n"));
			break;
			}
		else {
			Dprintf((fp,"(gmGdb) stage-3: [%s] encountered\n",buf+2));
			continue;
			}
		strcpy(mlb,buf);
		mlb+= strlen(mlb);
		}
	else if(buf[0] == '$' && isdigit(buf[1])) {
		strcpy(gdbmgr->mlbuf+1,buf);
		Rdbg((fp,"gmGdb <%s> : [$#] encountered",gdbmgr->mlbuf));
		return gdbmgr->mlbuf;
		}
	else if(!strncmp(buf,"Make breaking pending",21)) {
		fdputs("y",gdbmgr->rwfd);
		}
	Dprintf((fp,"(gmGdb) stage-3: continue looking for <c-z><c-z>post-prompt\n"));
	}

/* look for pre-prompt, filling in mlbuf with gdb's response(s) to the command,
 * except for any intervening annotations.
 */
Dprintf((fp,"(gmGdb) stage-4: look for pre-prompt, %s  (running=%s)\n",
  record2mlbuf? "recording to mlbuf with gdb's response(s)" : "mlbuf recording disabled",
  (gdbmgr->running == STOPPED)?  "stopped"  :
  (gdbmgr->running == RUNNING)?  "running"  :
  (gdbmgr->running == QUERY)?    "query"    :
  (gdbmgr->running == COMMANDS)? "commands" : "???"));
shortwaitcnt= 0;
while(1) {
	Dprintf((fp,"(gmGdb) stage-4 (recording): mlbuf<%s>\n",gdbmgr->mlbuf));
	if(!fdgets(buf,MEDBUFSIZE,gdbmgr->rwfd)) {
		if(++shortwaitcnt > SHORTWAITCNTMAX) break;
		SHORTWAIT;
		continue;
		}
	else shortwaitcnt= 0;
    Dprintf((fp,"(gmGdb) stage-4 (recording): looking for pre-%s: buf<%s>\n",
	  (gdbmgr->running == COMMANDS)? "commands" : "prompt",
	  buf));
	if(buf[0] == '\x1a' && buf[1] == '\x1a') {
		/* buffer begins with <c-z><c-z> */
		if(!strncmp(buf+2,"pre-prompt",10)) {       /* <c-z><c-z>pre-prompt  */
			Dprintf((fp,"(gmGdb) stage-4 (recording): looking for pre-prompt: encountered\n"));
			break;
			}
		else if(!strncmp(buf+2,"error-begin",11)) { /* <c-z><c-z>error-begin */
			Dprintf((fp,"(gmGdb) stage-4 (recording): looking for pre-prompt: [error-begin] encountered\n"));
			continue;
			}
		else if(!strncmp(buf+2,"error",5)) {        /* <c-z><c-z>error       */
			Dprintf((fp,"(gmGdb) stage-4 (recording): looking for pre-prompt: [error] encountered\n"));
			Rdbg((fp,"gmGdb <%s>",gdbmgr->mlbuf));
			return gdbmgr->mlbuf;
			}
		else if(!strncmp(buf+2,"exited ",7)) {      /* <c-z><c-z>exited      */
			gdbmgr->running  = STOPPED;
			gdbmgr->mlbuf[0] = 'S';
			sscanf(buf+2,"%*s %d",&exitstatus);
			Dprintf((fp,"(gmGdb) stage-4 (recording): looking for pre-prompt: [exited %d] encountered\n",exitstatus));
			continue;
			}
		else if(!strncmp(buf+2,"starting",8)) {     /* <c-z><c-z>starting    */
			gdbmgr->running  = RUNNING;
			gdbmgr->mlbuf[0] = 'R';
			strcpy(gdbmgr->mlbuf+1,buf+2);
			Rdbg((fp,"gmGdb <%s>",gdbmgr->mlbuf));
			return gdbmgr->mlbuf;
			}
		else if(!strncmp(buf+2,"stopped",7)) {      /* <c-z><c-z>stopped     */
			gdbmgr->running  = STOPPED;
			gdbmgr->mlbuf[0] = 'S';
			strcpy(gdbmgr->mlbuf+1,buf+2);
			Dprintf((fp,"(gmGdb) stage-4 (recording): looking for pre-prompt: [stopped] encountered\n"));
			break;
			}
		else if(!strncmp(buf+2,"signalled",9)) {    /* <c-z><c-z>signalled   */
			gdbmgr->running  = STOPPED;
			gdbmgr->mlbuf[0] = 'S';
			strcpy(gdbmgr->mlbuf+1,buf+2);
			Dprintf((fp,"(gmGdb) stage-4 (recording): looking for pre-prompt: [signalled] encountered\n"));
			break;
			}
		else if(!strncmp(buf+2,"pre-query",9)) {    /* <c-z><c-z>pre-query   */
			strcpy(gdbmgr->mlbuf+1,buf+2);
			gdbmgr->mlbuf[0]= 'Q';
			Dprintf((fp,"(gmGdb) stage-4 (recording): looking for <c-z><c-z>query: [pre-query] encountered\n"));
			continue;
			}
		else if(!strncmp(buf+2,"query",5)) {    /* <c-z><c-z>pre-query   */
			Rdbg((fp,"gmGdb <%s> : [query] encountered",gdbmgr->mlbuf));
			return gdbmgr->mlbuf;
			}
		else if(!strncmp(buf+2,"pre-commands",12)) {    /* <c-z><c-z>pre-commands   */
			gdbmgr->running= COMMANDS;
			gdbmgr->mlbuf[0] = 'C';
			Dprintf((fp,"(gmGdb) stage-4 (recording): [pre-commands] encountered\n"));
			break;
			}
		else {
			Dprintf((fp,"(gmGdb) stage-4 (recording): [%s] encountered\n",buf+2));
			continue;
			}
		}
	else if(buf[0] == '\0') continue;
	if(!record2mlbuf) continue;

	buflen  = strlen(buf); /* determine length of new string                     */
	strcpy(mlb,buf);       /* append new string to mlbuf                         */
	mlb+= buflen;          /* update mlb (end-of-mlbuf string) pointer           */
	if(exitstatus != -1 && !strncmp(buf,"Program exited normally.",24)) {
		sprintf(mlb," [exit code %d]\n",exitstatus);
		}
	*mlb++ = '\n';         /* terminate received string with a newline           */
	*mlb   = '\0';         /* insure that mlbuf has a properly terminated string */
	Dprintf((fp,"(gmGdb) stage-4 (recording): mlbuf<%s>\n",gdbmgr->mlbuf));
	}

/* look for <c-z><c-z>[prompt|commands] */
Dprintf((fp,"(gmGdb) stage-5: look for %s\n",(gdbmgr->running == COMMANDS)? "commands" : "prompt"));
shortwaitcnt= 0;
while(1) {
	Dprintf((fp,"(gmGdb) stage-5: mlbuf<%s>\n",gdbmgr->mlbuf));
	if(!fdgets(buf,MEDBUFSIZE,gdbmgr->rwfd)) {
		if(++shortwaitcnt > SHORTWAITCNTMAX) {
			Dprintf((fp,"(gmGdb) stage-5: looking-for-prompt shortwaitcnt>%d!\n",shortwaitcnt));
			Rdbg((fp,"gmGdb <%s> : too many retries",gdbmgr->mlbuf));
			return gdbmgr->mlbuf;
			}
		SHORTWAIT;
		continue;
		}
	Dprintf((fp,"(gmGdb) stage-5: looking-for-prompt buf<%s>\n",buf));
	if(buf[0] == '\x1a' && buf[1] == '\x1a') {
		if(!strncmp(buf+2,"prompt",6)) {
			Dprintf((fp,"(gmGdb) stage-5: [prompt] encountered\n"));
			break;
			}
		else if(!strncmp(buf+2,"commands",8)) {
			Dprintf((fp,"(gmGdb) stage-5: [commands] encountered\n"));
			break;
			}
		}
	}

Rdbg((fp,"gmGdb <%s> : running=%d<%s>",
  gdbmgr->mlbuf,
  gdbmgr?                                  gdbmgr->running : -1,
  (gdbmgr && gdbmgr->running == STOPPED)?  "stopped"       :
  (gdbmgr && gdbmgr->running == RUNNING)?  "running"       :
  (gdbmgr && gdbmgr->running == QUERY)?    "query"         :
  (gdbmgr && gdbmgr->running == COMMANDS)? "commands"      : "???"));
return gdbmgr->mlbuf;
}

/* --------------------------------------------------------------------- */
/* gmPoll: this function used to keep track of output from the program being debugged {{{2
 *         Uses nbrfd  (non-blocking reading file descriptor)
 *         Supports polling.
 */
char *gmPoll(char *gdbcmd)
{
char   *b;
ssize_t ret;
int     size;
int     shortwaitcnt= 0;

Edbg((fp,"gmPoll(gdbcmd<%s>)",gdbcmd));

/* get access to GdbMgr */
GetGdbMgr();
Dprintf((fp,"gdbmgr=%px gdbcmd<%s> running=%d<%s>\n",
  gdbmgr,
  gdbcmd?                                  gdbcmd          : "-null-",
  gdbmgr?                                  gdbmgr->running : -1,
  (gdbmgr && gdbmgr->running == STOPPED)?  "stopped"       :
  (gdbmgr && gdbmgr->running == RUNNING)?  "running"       :
  (gdbmgr && gdbmgr->running == QUERY)?    "query"         :
  (gdbmgr && gdbmgr->running == COMMANDS)? "commands"      : "???"));

if(!gdbmgr) {
	Rdbg((fp,"gmGdb : unable to access GdbMgr memory"));
	return "***error*** (gmPoll) unable to access GdbMgr memory";
	}
Dprintf((fp,"gdbmgr: gdbpid#%d rwfd#%d\n",
  gdbmgr? gdbmgr->gdbpid : -1,
  gdbmgr? gdbmgr->rwfd   : -1));

/* fdputs the non-null command to gdb */
if(gdbcmd && gdbcmd[0] != '\0') {
	Dprintf((fp,"(gmGdb) sending<%s>\n",gdbcmd));
	fdputs(gdbcmd,gdbmgr->rwfd);
	SHORTWAIT;
	}

/* set up the non-blocking read-file-descriptor */
if(gdbmgr->nbrfd < 0) {
	gdbmgr->nbrfd= dup(gdbmgr->rwfd);
	if(gdbmgr->nbrfd < 0) {
		sprintf(gdbmgr->gdbmgrbuf,"%cunable to dup read descriptor<%s>",
		 (gdbmgr->running == STOPPED)? 'S' :
		 (gdbmgr->running == RUNNING)? 'R' :
		 (gdbmgr->running == QUERY)?   'Q' : '?',
		 strerror(errno));
		Rdbg((fp,"gmPoll <%s>",gdbmgr->gdbmgrbuf));
		return gdbmgr->gdbmgrbuf;
		}
	Dprintf((fp,"successfully duplicated rwfd descriptor  (nbrfd=%px)\n",gdbmgr->nbrfd));
	if(fcntl(gdbmgr->nbrfd,F_SETFL,O_NONBLOCK) < 0) {
		sprintf(gdbmgr->gdbmgrbuf,"%cunable to open non-blocking read descriptor<%s>",
		 (gdbmgr->running == STOPPED)? 'S' :
		 (gdbmgr->running == RUNNING)? 'R' :
		 (gdbmgr->running == QUERY)?   'Q' : '?',
		 strerror(errno));
		Rdbg((fp,"gmPoll <%s>",gdbmgr->gdbmgrbuf));
		return gdbmgr->gdbmgrbuf;
		}
	Dprintf((fp,"set up non-blocking read-file-descriptor (nbrfd=%px)\n",gdbmgr->nbrfd));
	}

/* grab as many bytes as are available and send them back to vim */
if     (gdbmgr->running == STOPPED) gdbmgr->mlbuf[0]= 'S';
else if(gdbmgr->running == RUNNING) gdbmgr->mlbuf[0]= 'R';
else if(gdbmgr->running == QUERY)   gdbmgr->mlbuf[0]= 'Q';
else                                gdbmgr->mlbuf[0]= '?';
b                = gdbmgr->mlbuf + 1;
b[1]             = '\0';
size             = BUFSIZE;
shortwaitcnt     = 0;
while((ret= read(gdbmgr->nbrfd,b,(size_t)1)) > 0 || (20 <= gdbmgr->runstate && gdbmgr->runstate <= 2000)) {
	Dprintf((fp,"ret=%d nbrfd=%px runstate=%-4d shortwaitcnt=%-3d b[%4d]<%c>\n",ret,gdbmgr->nbrfd,gdbmgr->runstate,shortwaitcnt,((int)(b-gdbmgr->mlbuf)),*b));

	if(ret <= 0) {
		/* if nothing was read, then we're in the middle of reading bytes.
		* Introduce a short wait and then try reading again. (up to SHORTWAITCNTMAX short waits)
		*/
		*b= '\0';
		if(++shortwaitcnt > SHORTWAITCNTMAX) {
			Dprintf((fp,"(attempting to complete annotation) shortwaitcnt>%d!\n",SHORTWAITCNTMAX));
			strcpy(gdbmgr->mlbuf,"Sgdb not responding as expected");
			if     (gdbmgr->running == STOPPED) gdbmgr->mlbuf[0]= 'S';
			else if(gdbmgr->running == RUNNING) gdbmgr->mlbuf[0]= 'R';
			else if(gdbmgr->running == QUERY)   gdbmgr->mlbuf[0]= 'Q';
			else                                gdbmgr->mlbuf[0]= '?';
			Rdbg((fp,"gmGdb <%s>",gdbmgr->mlbuf));
			return gdbmgr->mlbuf;
			}
		SHORTWAIT;
		continue;
		}
	else shortwaitcnt= 0;
	b[1]= '\0';
	if(--size <= 1) break;

	/* handle ctrl-z ctrl-z [signalled|stopped|exited] etc
	* done via a FSA because the string may be received in segments, albeit sequentially
	* break   : means record character in buffer, read new character
	* continue: means don't record character, read new character into its place in the buffer
	*/
	switch(gdbmgr->runstate) {
	case 0: if(*b == '\x1a') ++gdbmgr->runstate; break;
	case 1: if(*b == '\x1a') ++gdbmgr->runstate; else gdbmgr->runstate= 0; break;
	case 2:
		if     (*b == 'b') gdbmgr->runstate= 20;   /* look for <c-z><c-z>breakpoint\n          */
		else if(*b == 'e') gdbmgr->runstate= 40;   /* look for <c-z><c-z>exited\n              */
		else if(*b == 'p') gdbmgr->runstate= 140;  /* look for <c-z><c-z>[pre-prompt|prompt]\n */
		else if(*b == 's') gdbmgr->runstate= 60;   /* look for <c-z><c-z>[signal...|stopped]\n */
		else               gdbmgr->runstate= 1000; /* discard until newline                    */
		break;

	/* --------------------------------------------------------------------- */
	/* look for <c-z><c-z>breakpoint ## \n */
	case 20: if(*b == 'r')     ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 21: if(*b == 'e')     ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 22: if(*b == 'a')     ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 23: if(*b == 'k')     ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 24: if(*b == 'p')     ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 25: if(*b == 'o')     ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 26: if(*b == 'i')     ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 27: if(*b == 'n')     ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 28: if(*b == 't')     ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 29: if(*b == ' ')     ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 30: 
		if(*b == '\n') {
			gdbmgr->runstate = 0;
			gdbmgr->running  = STOPPED;
			gdbmgr->mlbuf[0] = 'S';
			Rdbg((fp,"gmPoll <%s> : running=%d  runstate=%d",
			 gdbmgr->mlbuf,
			 gdbmgr->running,
			 gdbmgr->runstate));
			return gdbmgr->mlbuf;
			}
		else if(isdigit(*b)) break;
		gdbmgr->runstate= 40;
		break;

	/* --------------------------------------------------------------------- */
	/* look for <c-z><c-z>exited\n */
	case 40: if(*b == 'x') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 41: if(*b == 'i') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 42: if(*b == 't') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 43: if(*b == 'e') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 44: if(*b == 'd') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 45:
		if(*b == ' ' || isdigit(*b)) break;
		else if(*b == '\n') {
			gdbmgr->runstate = 0;
			gdbmgr->running  = STOPPED;
			gdbmgr->mlbuf[0] = 'S';
			Rdbg((fp,"gmPoll <%s> : running=%d  runstate=%d",
			 gdbmgr->mlbuf,
			 gdbmgr->running,
			 gdbmgr->runstate));
			return gdbmgr->mlbuf;
			}
		gdbmgr->runstate= 1000;
		break;

	/* --------------------------------------------------------------------- */
	/* look for <c-z><c-z>stopped\n */
	case 60:
	if     (*b == 't') ++gdbmgr->runstate;
		 else if(*b == 'i') gdbmgr->runstate= 100; /* look for <c-z><c-z>signal...\n */
	else               gdbmgr->runstate= 1000;
	break;
	case 61: if(*b == 'o') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 62: if(*b == 'p') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 63: if(*b == 'p') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 64: if(*b == 'e') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 65: if(*b == 'd') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 66:
		if(*b == '\n') {
			gdbmgr->runstate = 0;
			gdbmgr->running  = STOPPED;
			gdbmgr->mlbuf[0] = 'S';
			Rdbg((fp,"gmPoll <%s> : running=%d  runstate=%d",
			gdbmgr->mlbuf,
			gdbmgr->running,
			gdbmgr->runstate));
			return gdbmgr->mlbuf;
			}
		else gdbmgr->runstate= 0;
		break;

	/* --------------------------------------------------------------------- */
	/* look for <c-z><c-z>si[gnal|gnal-name|gnal-name-end|gnal-string]\n */
	case 100: if(*b == 'g') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 101: if(*b == 'n') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 102: if(*b == 'a') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 103: if(*b == 'l') ++gdbmgr->runstate;
	case 104:
		if     (*b == 'l') ++gdbmgr->runstate;    /* look for <c-z><c-z>signall[ed]\n                   */
		else if(*b == '-') gdbmgr->runstate= 108; /* look for <c-z><c-z>signal-[name|name-end|string]\n */
		else if(*b == '\n') {                     /* encountered <c-z><c-z>signal\n                     */
			gdbmgr->runstate = 0;
			gdbmgr->running  = STOPPED;
			gdbmgr->mlbuf[0] = 'S';
			Rdbg((fp,"gmPoll <%s> : running=%d  runstate=%d",
			gdbmgr->mlbuf,
			gdbmgr->running,
			gdbmgr->runstate));
			return gdbmgr->mlbuf;
			}
		else gdbmgr->runstate= 1000;
		break;
	case 105: if(*b == 'e') ++gdbmgr->runstate; else gdbmgr->runstate= 0; break;
	case 106: if(*b == 'd') ++gdbmgr->runstate; else gdbmgr->runstate= 0; break;
	case 107:
		if(*b == '\n') {            /* encountered <c-z><c-z>signalled\n            */
			gdbmgr->runstate = 0;
			gdbmgr->running  = STOPPED;
			gdbmgr->mlbuf[0] = 'S';
			Rdbg((fp,"gmPoll <%s> : running=%d  runstate=%d",
			gdbmgr->mlbuf,
			gdbmgr->running,
			gdbmgr->runstate));
			return gdbmgr->mlbuf;
			}
		else gdbmgr->runstate= 1000;
		break;

	/* --------------------------------------------------------------------- */
	/* expecting <c-z><c-z>signal-[name|name-end] */
	case 108: if(*b == 'n') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 109: if(*b == 'a') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 110: if(*b == 'm') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 111: if(*b == 'e') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 112:
		if(*b == '-') ++gdbmgr->runstate; /* look for <c-z><c-z>signal-name-[end]\n */
		else if(*b == '\n') {             /* <c-z><c-z>signal-name\n                */
			gdbmgr->runstate = 0;
			b                = gdbmgr->mlbuf + 1;
			*b               = '\0';
			size             = BUFSIZE;
			shortwaitcnt     = 0;
			continue;
			}
		else gdbmgr->runstate= 1000;
		break;
	case 113: if(*b == 'e') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 114: if(*b == 'n') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 115: if(*b == 'd') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 116:
		if(*b == '\n') { /* <c-z><c-z>signal-name-end\n */
			gdbmgr->runstate = 0;
			b                = gdbmgr->mlbuf + 1;
			*b               = '\0';
			size             = BUFSIZE;
			shortwaitcnt     = 0;
			continue;
			}
		else gdbmgr->runstate= 1000;
		break;

	/* --------------------------------------------------------------------- */
	/* expecting <c-z><c-z>signal-string */
	case 117: if(*b == 's') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 118: if(*b == 't') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 119: if(*b == 'r') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 120: if(*b == 'i') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 121: if(*b == 'n') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 122: if(*b == 'g') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 123:
		if(*b == '\n') { /* <c-z><c-z>signal-string\n */
			gdbmgr->runstate = 0;
			b                = gdbmgr->mlbuf + 1;
			*b               = '\0';
			size             = BUFSIZE;
			shortwaitcnt     = 0;
			continue;
			}
		gdbmgr->runstate = 0;
		break;

	/* --------------------------------------------------------------------- */
	/* look for <c-z><c-z>p[re-prompt|rompt] */
	case 140: if(*b == 'r')     ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 141:
		if(*b == 'o')          ++gdbmgr->runstate;
		if(*b == 'e')            gdbmgr->runstate= 160; /* look for <c-z><c-z>pre-prompt\n */
		else                     gdbmgr->runstate= 1000;
		break;
	case 142: if(*b == 'm')     ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 143: if(*b == 'p')     ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 144: if(*b == 't')     ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 145:
		if(*b == '\n') { /* found for <c-z><c-z>prompt\n */
			*b               = '\0';
			gdbmgr->runstate = 0;
			gdbmgr->running  = STOPPED;
			gdbmgr->mlbuf[0] = 'S';
			Rdbg((fp,"gmPoll <%s> : running=%d  runstate=%d",
			gdbmgr->mlbuf,
			gdbmgr->running,
			gdbmgr->runstate));
			return gdbmgr->mlbuf;
			}
		else gdbmgr->runstate= 1000;
		break;

	/* --------------------------------------------------------------------- */
	/* look for <c-z><c-z>pre[-prompt] */
	case 160: if(*b == '-') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 161: if(*b == 'p') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 162: if(*b == 'r') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 163: if(*b == 'o') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 164: if(*b == 'm') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 165: if(*b == 'p') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 166: if(*b == 't') ++gdbmgr->runstate; else gdbmgr->runstate= 1000; break;
	case 167:
		if(*b == '\n') {
			gdbmgr->runstate = 0;
			b                = gdbmgr->mlbuf + 1;
			*b               = '\0';
			size             = BUFSIZE;
			shortwaitcnt     = 0;
			continue;
			}
		else gdbmgr->runstate= 1000;
		break;

	/* --------------------------------------------------------------------- */
	case 1000: /* read and discard rest of annotation */
		if(*b == '\n') {
			gdbmgr->runstate = 0;
			b                = gdbmgr->mlbuf + 1;
			*b               = '\0';
			size             = BUFSIZE;
			shortwaitcnt     = 0;
			continue;
			}
		break;
		} /* end of switch on gdbmgr->runstate */

	/* record character in gdbmgr->mlbuf */
	if(*b == '\n') {
		*b= '\0';
		break;
		}
	++b;
	}
if(gdbmgr->running == RUNNING) *++b= '\0';
else                           *b  = '\0';

if(size == BUFSIZE) { /* received nothing, so send <c-z><c-z>empty to gdbmgr.vim */
	Dprintf((fp,"rcvd nothing, so am sending ^z^zempty to gdbmgr.vim\n"));
	gdbmgr->mlbuf[1]= '\x1a';
	gdbmgr->mlbuf[2]= '\x1a';
	strcpy(gdbmgr->mlbuf+3,"empty");
	}

if     (gdbmgr->running == STOPPED) gdbmgr->mlbuf[0]= 'S';
else if(gdbmgr->running == RUNNING) gdbmgr->mlbuf[0]= 'R';
else if(gdbmgr->running == QUERY)   gdbmgr->mlbuf[0]= 'Q';
else                                gdbmgr->mlbuf[0]= '?';
Rdbg((fp,"gmPoll <%s> : running=%d  runstate=%d",
  gdbmgr->mlbuf,
  gdbmgr->running,
  gdbmgr->runstate));
return gdbmgr->mlbuf;
}

/* --------------------------------------------------------------------- */
/* gmClose: this function shuts down the pipes and tells gdb to quit {{{2 */
char *gmClose(char *gdbcmd)
{
int status;

Edbg((fp,"gmClose(gdbcmd<%s>)",gdbcmd));
GetGdbMgr();
Dprintf((fp,"gdbmgr: gdbpid#%d rwfd#%d\n",
  gdbmgr? gdbmgr->gdbpid : -1,
  gdbmgr? gdbmgr->rwfd   : -1));

gdbmgr->init= 1; /* prevent gmGdb() from detaching from gdbmgr */
gmGdb("quit");
Dprintf((fp,"waitpid on child#%d\n",gdbmgr->gdbpid));
errno= 0;
/* try to prevent zombies ... but if gdb hasn't quit, wait one second.
 * Then try one last time to waitpid().  If that works, great; otherwise,
 * just go ahead and terminate.
 */
if(waitpid(gdbmgr->gdbpid,&status,WNOHANG) == -1) {
	Dprintf((fp,"first try at waitpid failed\n"));
	if(errno == ECHILD) {
		int ret;
		sleep(1);
		ret= waitpid(gdbmgr->gdbpid,&status,WNOHANG);
		Dprintf((fp,"second try at waitpid %s\n",ret? "succeeded" : "failed"));
		}
	}
Dprintf((fp,"child status=%d\n",status));

/* close streams/descriptors */
Dprintf((fp,"closing read/write file descriptor\n"));
if(gdbmgr->rwfd) close(gdbmgr->rwfd);

/* close shared memory */
CloseGdbMgr();

Rdbg((fp,"gmClose \"gdb closed\""));
return "gdb closed";
}

/* --------------------------------------------------------------------- */
/* GetGdbMgr: its really tough to keep something accessable across {{{2
 *               calls from vim to gmGdb.  static variables are always
 *               re-initialized.  Apparently there's a pointer offset
 *               associated with the library that changes occasionally
 *               when its (re-)loaded.  The solution used here sets up
 *               shared memory, even though there's no intention to
 *               share it with some other process.  So, the solution
 *               I'm using is essentially to have it share the memory
 *               with itself.
 */
static void GetGdbMgr()
{
int shmid;

Edbg((fp,"GetGdbMgr()"));

if(!gdbmgr) {
	shmid  = shmget(SHMKEY,sizeof(GdbMgr),IPC_CREAT|SHM_R|SHM_W);
	Dprintf((fp,"shmid=%d errno=%d\n",shmid,errno));
	gdbmgr = (GdbMgr *) shmat(shmid,NULL,0);
	Dprintf((fp,"gdbmgr=%px errno=%d\n",gdbmgr,errno));
	if     (gdbmgr == (GdbMgr *) -1) gdbmgr= NULL;
	else if(gdbmgr) gdbmgr->shmid= shmid;

	if(gdbmgr) {
		/* one effect of this approach is that it never clears previous
		 * attachments to the shared memory.  Detaching the shared memory
		 * means that the routines can't pass the buffer back (gdbmgr->mlbuf).
		 * So the method chosen here to prevent too many attachments lying
		 * around in memory: every MAXATTCH attaches, copy the shared memory
		 * to a local copy, remove the shared memory, and then restore it.
		 * I don't copy the character buffers.
		 */
		struct shmid_ds buf;
		int             ret;

		errno = 0;
		ret   = shmctl(shmid,IPC_STAT,&buf); /* get nattch status */
		Dprintf((fp,"shmctl status: ret=%d errno=%d<%s> buf.shm.nattch=%d\n",
		  ret,
		  errno,
		  (ret >= 0)? "good"         : strerror(errno),
		  (ret >= 0)? buf.shm_nattch : -1));
		if(ret != -1 && buf.shm_nattch > MAXATTCH) {
			int init     = gdbmgr->init;
			int rwfd     = gdbmgr->rwfd;
			int nbrfd    = gdbmgr->nbrfd;
			int running  = gdbmgr->running;
			int runstate = gdbmgr->runstate;
			int gdbpid   = gdbmgr->gdbpid;
			ret          = shmctl(gdbmgr->shmid,IPC_RMID,NULL); /* remove shared memory */
			Dprintf((fp,"shmctl rmid: %s\n",(ret >= 0)? "succeeded" : "FAILED!!!"));
			if(ret >= 0) {
				gdbmgr           = NULL;
				GetGdbMgr();                 /* re-open shared memory */
				gdbmgr->init     = init;
				gdbmgr->rwfd     = rwfd;
				gdbmgr->nbrfd    = nbrfd;
				gdbmgr->running  = running;
				gdbmgr->runstate = runstate;
				gdbmgr->gdbpid   = gdbpid;
				}
			}
		}
	}

Rdbg((fp,"GetGdbMgr : gdbmgr=%px",gdbmgr));
}

/* --------------------------------------------------------------------- */
/* CloseGdbMgr: this function closes the GdbMgr shared memory {{{2 */
static void CloseGdbMgr()
{
Edbg((fp,"CloseGdbMgr() gdbmgr=%px",gdbmgr));

if(gdbmgr) shmctl(gdbmgr->shmid,IPC_RMID,NULL);
gdbmgr= NULL;

Rdbg((fp,"CloseGdbMgr"));
}

/* --------------------------------------------------------------------- */
/* fdputs: this function puts a buffer out via the file descriptor {{{2 */
static char *fdputs(char *buf,int fd)
{
char    locbuf[MEDBUFSIZE];
size_t  blen;
ssize_t ret;

Edbg((fp,"fdputs(%sbuf<%s>,fd=%d)",
  buf? ""  : "null ",
  buf? buf : "",
  fd));

sprintf(locbuf,"%s\n",buf);
blen= strlen(locbuf);
ret = write(fd,locbuf,blen);

Rdbg((fp,"fdputs <%s> : %d chars (ret=%d)",buf? buf : "null",blen,ret));
return buf;
}

/* --------------------------------------------------------------------- */
/* fdgets: this function gets characters from a file descriptor {{{2 */
static char *fdgets(char *buf,int size,int fd)
{
char    *b;
ssize_t  ret;

Edbg((fp,"fdgets(%sbuf,size=%d,fd=%d)",
  buf? "" : "null ",
  size,
  fd));

b= buf;
while((ret= read(fd,b,(size_t) 1)) >= 0) {
/*    Dprintf((fp,"read buf[%4d]<%c>\n",(int)(b-buf),*b));*/
	if(*b == '\0')  break;
	if(*b == '\n')  break;
	if(--size <= 1) break;
	if(ret) ++b;
	else if(b > buf && ret == 0) break;
	}
if(gdbmgr && gdbmgr->running == STOPPED) *b= '\0';
b[1]= '\0';

Rdbg((fp,"fdgets <%s>",(ret > 0)? buf : "null"));
return (ret > 0)? buf : NULL;
}

/* --------------------------------------------------------------------- */
/* Modelines: {{{1
 * vim: fdm=marker ts=4
 */

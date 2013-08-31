all : prog01 prog02 prog03 prog04 prog05 prog06 prog07 prog08 prog09 prog10

prog01 : prog01.c
	gcc ${CFLAGS} -g -o prog01 prog01.c

prog02 : prog02.c
	gcc ${CFLAGS} -g -o prog02 prog02.c

prog03 : prog03.c
	gcc ${CFLAGS} -g -o prog03 prog03.c

prog04 : prog04.c
	gcc ${CFLAGS} -g -o prog04 prog04.c

prog05 : prog05.c
	gcc ${CFLAGS} -g -o prog05 prog05.c

prog06 : prog06.c
	gcc ${CFLAGS} -g -o prog06 prog06.c

prog07 : prog07.c
	gcc ${CFLAGS} -g -o prog07 prog07.c

prog08 : prog08.c
	gcc ${CFLAGS} -g -o prog08 prog08.c -lpthread

prog09 : prog09.c
	gcc ${CFLAGS} -g -o prog09 prog09.c -lpthread -lm

prog10 : prog10.c
	gcc ${CFLAGS} -g -o prog10 prog10.c -lpthread -lm

clean :
	/bin/rm -f *.o prog0[1-9] prog10 core* tags

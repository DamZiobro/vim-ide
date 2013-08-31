SRC = gdbmgr.c
OBJ = gdbmgr.o

gdbmgr.so : gdbmgr.o gdbmgr.h
	/bin/rm -f tmp*
	gcc -shared gdbmgr.o -Wl,-soname,gdbmgr.so -o gdbmgr.so
	@echo "*** Don't forget to adjust your LD_LIBRARY_PATH env-var ***"

%.o: %.c
	gcc ${CFLAGS} -fPIC -c -o $@ $<

clean :
	/bin/rm -f tmp* core* gdbmgr.o gdbmgr.so

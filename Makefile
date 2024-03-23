CC = g++
.cc.o:
	$(CC) $(CFLAGS) -c -o $@ $<

disbesm6: disbesm6.o encoding.o

dtran: dtran.o

clean:
	rm disbesm6.o encoding.o disbesm6

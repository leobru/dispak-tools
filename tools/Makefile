CC = g++
DEBUG =
CFLAGS += -std=c++20  -Wall -Wextra -Wno-parentheses
.cc.o:
	$(CC) $(DEBUG) $(CFLAGS) -c -o $@ $<

disbesm6: disbesm6.o encoding.o
	$(CC) $(DEBUG) $(CFLAGS) -o $@ $^

dtran: dtran.o

clean:
	rm disbesm6.o encoding.o disbesm6

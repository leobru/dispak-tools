#include <cstdio>
int main() {
    int i;
    printf("%%!\n\
0 setlinewidth 0 0 moveto 72 400 div dup scale\n\
/mv { rmoveto } def\n\
/x00 { -2 0 mv } def\n\
/x01 { -2 2 mv } def\n\
/x02 { 0 2 mv } def\n\
/x03 { 2 2 mv } def\n\
/x04 { 2 0 mv } def\n\
/x05 { 2 -2 mv } def\n\
/x06 { 0 -2 mv } def\n\
/x07 { -2 -2 mv } def\n\
/x10 { } def\n\
/x11 { /mv { rmoveto } def currentpoint /y exch def /x exch def stroke x y moveto } def\n\
/x12 { /mv { rlineto } def currentpoint /y exch def /x exch def stroke x y moveto } def\n\
/x20 { -1 0 mv } def\n\
/x21 { -1 1 mv } def\n\
/x22 { 0 1 mv } def\n\
/x23 { 1 1 mv } def\n\
/x24 { 1 0 mv } def\n\
/x25 { 1 -1 mv } def\n\
/x26 { 0 -1 mv } def\n\
/x27 { -1 -1 mv } def\n\
/x30 { -1 2 mv } def\n\
/x31 { -1 -2 mv } def\n\
/x32 { -2 1 mv } def\n\
/x33 { -2 -1 mv } def\n\
/x34 { 1 2 mv } def\n\
/x35 { 1 -2 mv } def\n\
/x36 { 2 1 mv } def\n\
/x37 { 2 -1 mv } def\n\
/x54 { stroke showpage } def\n");

    while (scanf("%o", &i) == 1) {
        printf("x%02o\n", i);
        if (i == 054) break;
    }
}

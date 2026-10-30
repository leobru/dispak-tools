svodka: svodka.gold svodka.be.silver
	diff -q $^

koka:   koka.gold koka.be.silver
	diff -q $^

svodka.gold:
	./textdump.sh 2113 1702 3 800 > $@

svodka.be.silver: svodka.be
	./zongp.pl -v svodka.be 1

koka.be.silver: koka.be
	./zongp.pl -v koka.be 1

koka.gold:
	./textdump.sh 2113 1727 3 468 > $@

mdupla: mdupla.gold mdupla.be.silver
	diff -q $^

mdupla.be.silver: mdupla.be
	./zongp.pl -v mdupla.be 1

mdupla.gold:
	./textdump.sh 2113 1726 3 737 > $@

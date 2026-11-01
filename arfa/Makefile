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

# BUST is built by *call overlay: zone 1703 holds the overlay catalog,
# 1704-1706 the packed image, which unpacks to addresses 0770-010001.
bust.bin:
	rm -f bust.ovl
	besmtool dump 2113 --start=01704 --length=3 --to-file=bust.ovl
	../tools/ovl2bin < bust.ovl > $@
	rm bust.ovl

# STARFA: catalog in 1710, the packed image in 1711-1717 (0770-022001).
starfa.bin:
	rm -f starfa.ovl
	besmtool dump 2113 --start=01711 --length=7 --to-file=starfa.ovl
	../tools/ovl2bin < starfa.ovl > $@
	rm starfa.ovl

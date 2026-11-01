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

prorva: prorva.gold prorva.be.silver
	diff -q $^

prorva.be.silver: prorva.be
	./zongp.pl -v prorva.be 1

prorva.gold:
	./textdump.sh 2248 0116 3 1001 > $@

prorva.bin:
	besmtool dump 2248 --start=0116 --length=1 --to-file=$@

arfa: arfa.gold arfa.be.silver
	diff -q $^

arfa.be.silver: arfa.be
	./zongp.pl -v arfa.be 1

arfa.gold:
	./textdump.sh 2113 1707 3 1023 > $@

arfa.bin:
	besmtool dump 2113 --start=01707 --length=1 --to-file=$@

# The batch ARFA: a Dubna Monitor object module in 2113/1723-1725.
arfab.mad: b1723.bin arfab.py arfa.bin arfa.sym
	python3 arfab.py b1723.bin > $@

b1723.bin:
	besmtool dump 2113 --start=01723 --length=3 --to-file=$@

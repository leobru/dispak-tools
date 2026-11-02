# ПАК and БРЕГЕТ: zones 2053/0713-0714, loaded at 0-03777.
# make breget  - assemble breget.be with ГП and compare with the zones.

breget: breget.gold breget.be.silver
	diff -q $^

breget.be.silver: breget.be
	../../arfa/zongp.pl -v breget.be 1

breget.gold:
	../../arfa/textdump.sh 2053 0713 2 1856 2 | sed 's/^с 0 ;/к 00 000 0000, 00 000 0000 ; с 0000 0000 0000 0000 ;/' > $@

breget.bin:
	besmtool dump 2053 --start=0713 --length=2 --to-file=$@

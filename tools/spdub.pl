#!/usr/bin/env perl
$i = 0;
while (<>) {
next unless /:  (....) (....) (....) (....)/;
$lib[$i++] = oct("$1$2$3$4");
}
sub prdata {
my ($w) = @_;
	$w &= 017777;
	if ($lib[$w+1] == $lib[0]) {
		$len1 = $lib[$w] & 077777;
		$len2 = $lib[$w] >> 15;
		printf "disk len %04o mem len %04o", $len1, $len2;
		$sp = sprintf("%03o", $num);
		open(F, ">sp$sp.hex") || die "Cannot open sp$sp.hex for writing\n";
		for ($j = $w+2; $j < $w + $len1; ++$j) {
			printf F "%016llo\n", $lib[$j];
		}
		close(F);
	} else {
		print "corrupted";
	}
}

for ($i = 1; $lib[$i]; ++$i) {
	$w = $lib[$i];
	$num = $w >> 36;
	$zone = ($w >> 10) & 7;
	$loc = $w & 01777;
	if ($num) {
		printf "SP %o is %o:%04o ", $num, $zone, $loc;
		prdata($w);
	} else {
		printf "FREE @%o:%04o ", $zone, $loc;
	}
	print "\n";
}

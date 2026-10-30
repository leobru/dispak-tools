#!/usr/bin/env perl
$i = 0;
while (<>) {
next unless /:  (....) (....) (....) (....)/;
$lib[$i++] = oct("$1$2$3$4");
}
sub prdata {
my ($w, $len) = @_;
	$w &= 017777;
	$len1 = $lib[$w] & 077777;
	$len2 = $lib[$w] >> 15;
	$check = $lib[$w+1] & 01777;
	if ($len == $len1 && $check == $w%1024) {
		printf "disk len %04o mem len %04o", $len1, $len2;
		$sp = sprintf("%03o", $num);
		open(F, ">sp$sp.hex") || die "Cannot open sp$sp.hex for writing\n";
		for ($j = $w+2; $j < $w + $len1; ++$j) {
			printf F "%016llo\n", $lib[$j];
		}
		close(F);
	} elsif ($len != $len1) {
		printf "length mismatch: %04o vs %04o", $len, $len1;
	} else {
		printf "location mismatch: %04o vs %04o", $w%1024, $check;  
	}
}

for ($i = 0; $i < 0400; ++$i) {
	$w = $lib[$i];
	$num = $i + 1;
	$zone = ($w >> 12) & 07;
	$loc = $w & 01777;
	$len = $w >> 21;
	if ($zone || $loc) {
		printf "SP %o is %o:%04o ", $num, $zone, $loc;
		prdata($zone*1024+$loc, $len);
		print "\n";
	}
}

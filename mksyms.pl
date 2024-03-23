#!/usr/bin/env perl
use utf8;
use feature 'unicode_strings';
use open ':encoding(UTF-8)';
use open ':std', ':encoding(UTF-8)';

$dec{'OUTPUT'} = 1;
$dec{'INPUT'} = 1;
$dec{'TTIO'} = 1;
$dec{'FIND'} = 1;
$dec{'P/08'} = 1;

while(<>) { last if /PASCODER.*01000/; }

$lditm = 0;
$lditm = 1 if /^          /;

sub doit {
    my ($a, $n) = @_;
    $n =~ s/[ @]//g;
    if (defined($dec{$n})) {
        print ",", oct($a), " ,$n\n";
        return;
    }
    $a = 'L' . $a;
    $a =~ s/L0/L/;
    print "$a $n\n" if $a =~ m/\d/;    
}


do {
    exit 0 if /^\b*$/;
    $a = $_;
    for ($i = 0; $i < length; ++$i) {
        substr($a, $i, 1) = '@' if substr($a, $i, 1) eq '*';
    }
    if ($lditm) {
    doit(substr($a, 21, 5), substr($a, 10, 8)); 
    doit(substr($a, 45, 5), substr($a, 34, 8)); 
    doit(substr($a, 69, 5), substr($a, 58, 8));
    doit(substr($a, 93, 5), substr($a, 82, 8));
    doit(substr($a, 117, 5), substr($a, 106, 8));
    } else {
    doit(substr($a, 19, 5), substr($a, 8, 8)); 
    doit(substr($a, 43, 5), substr($a, 32, 8)); 
    doit(substr($a, 67, 5), substr($a, 56, 8));
    }
} while (<>);

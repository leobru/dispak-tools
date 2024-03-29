#!/usr/bin/env perl
use utf8;
undef $/;

$prog = <>;
$prog =~ s/\n /;/g;

$/=chr(10);

# Normalizing offsets

$prog =~ s/,;/,0;/g;

$prog =~ s/,UTM,(327\d\d);/',UTM,'.($1-32768).';'/ge;

# Recognizing "convert to Boolean" sequences (before normalizing labels)
# Does not work correctly in case of AND/OR of Boolean expressions
# $prog =~ s@,UZA,([^;]+);,XTA,0;,UJ,([^;]+);\1:1,XTA,8;\2:@isUZACond;@g;
# $prog =~ s@,U1A,([^;]+);,XTA,0;,UJ,([^;]+);\1:1,XTA,8;\2:@isU1ACond;@g;
# $prog =~ s@,UZA,([^;]+);1,XTA,8;,UJ,([^;]+);\1:,XTA,0;\2:@isU1ACond;@g;
# $prog =~ s@,U1A,([^;]+);1,XTA,8;,UJ,([^;]+);\1:,XTA,0;\2:@isUZACond;@g;

# Converting for loops to stack-friendly form (takes a few seconds)

while ($prog =~ s@,UJ,([^;]+);(.*?);\1:([^,]*),ATX,([^;]+)@\3,ATX,\4;,UJ,\1;\2;\3,ATX,\4;\1:\3,XTA,\4@g) { }

# Normalizing references to addresses of globals

$prog =~ s@;1,UTC,0;(\d+),VTM,(\d+)@;1,UTC,\2;\1,VTM,0@g;
$prog =~ s@;,UTC,(\d+);1,(...),0@;1,\2,\1@g;
$prog =~ s@([:;]),UTC,(\d+);2,(...),0@"$1"."2,$3,$2"@ge;

# Normalising labels

$prog =~ s/;([^:']+:)/;\1,BSS,;/g;

# Now BSS is the only case with no "offset"

# Recognizing subroutines

if (open(ROUTINES, "routines.txt")) {
    while (<ROUTINES>) {
        chop;
        my ($offset, $name, $rt) = split;
        $routines{$offset} = $name;
        $rtype{$offset} = $rt;
    }
    close(ROUTINES);
} else {
    print STDERR "File routines.txt not found, no labels will be replaced\n";
}


sub noargs {
    my ($off, $l, $n) = @_;
return $n==1 ? 
    "==========;L$off: Level $l procedure with 0 arguments and 0 locals;" :
    $rtype{$off} eq 'f' ? "==========;L$off: Level $l function with 0 arguments and ".($n-2)." locals;" :
    $rtype{$off} eq 'p' ? "==========;L$off: Level $l procedure with 0 arguments and ".($n-1)." locals;" :
    "==========;L$off: Level $l procedure with 0 arguments and ".($n-1)." (or a func with ".($n-2).") locals;";
}

sub manyargs {
my ($off, $l, $n,$m) = @_;
return
    $rtype{$off} eq 'f' ? "==========;L$off: Level $l function with ".($n-4)." arguments and ".($m-$n+2)." locals;" :
    $rtype{$off} eq 'p' ? "==========;L$off: Level $l procedure with ".($n-3)." arguments and ".($m-$n+2)." locals;" :
    "==========;L$off: Level $l procedure with ".($n-3)." (or a func with ".($n-4).") arguments and ".($m-$n+2)." locals;";   
}

$prog =~ s@L([^:,;]+):,BSS,;14,VJM,P/(\d) *;15,UTM,(\d+);@noargs($1,$2,$3)@eg;

$prog =~ s@L([^:,;]+):,BSS,;15,ATX,3;14,VJM,P/(\d) *;15,UTM,(\d+);@"==========;L$1: Level $2 procedure with 1 argument and ".($3-2)." locals;"@eg;

$prog =~ s@L([^:,;]+):,BSS,;15,ATX,4;14,VJM,P/(\d) *;15,UTM,(\d+);@"==========;L$1: Level $2 function with 1 argument and ".($3-3)." locals;"@eg;

$prog =~ s@L([^:,;]+):,BSS,;15,ATX,0;15,UTM,-(\d+);14,VJM,P/(\d) *;15,UTM,(\d+);@manyargs($1,$3,$2,$4)@eg;

$prog =~ s@L([^:,;]+):,BSS,;,NTR,7;13,MTJ,(\d);@"==========;L$1: Level ".($2-1)." procedure with no frame;"@eg;

# Converting shortcuts to standard subroutine calls

$prog =~ s@13,VTM,([^;]+);,UJ,([^;]+);@13,VJM,\2;,UJ,\1;@g;


# Converting global variables addressed via index register 1
# avoiding register-register intructions.

$prog =~ s@;1,([^M][^M][^M]),(\d+)@;,$1,g$2z@g;

# Converting global variable references (block P/1D) in the data setting section

# $prog =~ s@P/1D *\+(\d+)@g\1z@g;

$prog =~ s@\&(\d+)@if ($1 >= 2863 && $1 < 2934) { '&g' . ($1-2963) . 'z'; } else { "&$1"; }@ge;

# Converting local variables avoiding insns accessing registers
# (with M in their names)
# This should be recognized and conversion suppressed.

my @isfunc, @nargs, @nlocs;

sub renameLocRef {
    my ($lev, $idx) = @_;
    if ($isfunc[$lev]) {
        return $procname[$lev] if $idx == 0;
        return "l${lev}a${idx}z" if $idx <= $nargs[$lev];
        return "l${lev}v".($idx-$nargs[$lev])."z";
    } else {
        return "l${lev}a".($idx+1)."z" if $idx < $nargs[$lev];
        return "l${lev}v".($idx-$nargs[$lev]+1)."z";
    }
}

sub processprocs {
    
my @ops = split /;/, $prog;
my @knownregs;
my $curlev = -1;
my $funcname = '';
my $args = 0;
my $unkn = 0;
my $offset = 0;
for ($i = 0; $i <= $#ops; ++$i) {
    $line = $ops[$i];
    if ($line =~ m/^(.*?): Level (\d) ([a-z]+) with (\d+) argument/) {
        $funcname = $1;
        $curlev = $2;
        $args = $4;
        $funcname = '' unless $3 eq 'function';
        $unkn = 1 if $line =~ m/ or /;
        @knownregs = ();
        next;
    }
    if ($curlev != -1 && $line =~ m@^([2-$curlev]),([^M][^M][^M]),(\d+)$@) {
        my $idx = $3-3;
        if ($unkn || $1 ne $curlev) {
            $ops[$i] = ",$2,l$1loc${idx}z";
            $ops[$i] =~ s/l${curlev}loc0z/$funcname/ if $funcname ne '';
        } elsif ($funcname ne '') {
            if ($idx <= $args) {
                $ops[$i] = ",$2,l$1a${idx}z";
            } else {
                $ops[$i] = ",$2,l$1v".($idx-$args)."z";
            }
            $ops[$i] =~ s/l${curlev}a0z/$funcname/;
        } else {
            if ($idx < $args) {
                $ops[$i] = ",$2,l$1a".($idx+1)."z";
            } else {
                $ops[$i] = ",$2,l$1v".($idx-$args+1)."z";
            }
        }
        next;
    }

    # Faking assignment to a register "variable"
    if ($line =~ m/^([$curlev-69]),VTM,(.*)/) {
        $ops[$i] = ",XTA,&$2;,ATX,R$1";
        $knownregs[$1] = 1;
        next;
    }
    # Replacing known references via registers
    if ($line =~ m@^([$curlev-69]),([^M][^M][^M]),(\d+)$@ && $knownregs[$1]) {
        $ops[$i] = ",$2,R$1->$3";
        next;
    }
    # Faking reading of a register "variable"
    if ($line =~ m/,ITA,([$curlev-69])$/ && $knownregs[$1]) {
        $ops[$i] = ",XTA,R$1";
        next;
    }
    # Recognizing return from frameless procedures
    $avail = $curlev+1;
    $ops[$i] =~ s@$avail,UJ,0@RETURN@;

    if ($line =~ m@/(\d+):@) { $offset = $1; }
    if ($line =~ /,(ISO|GOST), \|(......*?)\|/) { $strings[$offset] = $2; }
}

# Bringing procedure headers up
my $curlev = 2;

for ($i = 0; $i <= $#ops; ++$i) {
    my $line = $ops[$i];
    next if $line !~ /Level (\d)/;
    $level = $1;
    next if $curlev == $level;
    if ($curlev > $level) {
        $ops[$i] .= ' (body)';
        $curlev = $level;
        next;
    }
    # The current line starts a subroutine at a greater nesting
    # level; find the header of the routine at the current level
    # and bring it up.
    for ($k = $level-1; $k >= $curlev; --$k) {
        for ($j = $i+1; $j <= $#ops; ++$j) {
            $l2 = $ops[$j];
            last if $l2 =~ /Level $k/;
        }
         splice(@ops, $i, 0, "$l2");
    }
    $i += $level-$curlev;
    $curlev = $level;
}

# Rename references to variables of upper level routines

for ($i = 0; $i <= $#ops; ++$i) {
    if ($ops[$i] =~ /([^:]+): Level (\d) ([^ ]+) with (\d+).* and (\d+)/) {
        # printf STDERR "Recording $1 $2 $3 $4 $5\n";
        $procname[$2] = $1;
        $isfunc[$2] = $3 eq "function";
        $nargs[$2] = $4;
        $nlocs[$2] = $5;
    } else {
        $ops[$i] =~ s@l(\d)loc(\d+)z@renameLocRef($1, $2)@ge;
    }
}

$prog = join ';', @ops;

}

processprocs();


# Recognizing known pre-seeded constants in the global area

$prog =~ s@g8z@e1@g;
$prog =~ s@g9z@00@g;
$prog =~ s@g10z@multmask@g; # 640... -> 400... 
$prog =~ s@g12z@mantissa@g;
$prog =~ s@g15z@-1@g;
$prog =~ s@g17z@+1@g;
$prog =~ s@g18z@p77777@g;
$prog =~ s@g19z@real0_5@g;
$prog =~ s@g20z@allones@g;

# Also
$prog =~ s@\(74000C\)@NIL@g;
$prog =~ s@\(360100B\)@ASN64template@g;
$prog =~ s@\(400016B\)@ATI14template@g;
$prog =~ s@\(370007B\)@NTR7template@g;

# Known globals

if (open(GLOBALS, "globals.txt")) {
    while (<GLOBALS>) {
        chop;
        my ($offset, $name) = split;
        $prog =~ s@g${offset}z@$name@g || print STDERR "Global $offset not found\n";
    }
    close(GLOBALS);
} else {
    print STDERR "File globals.txt not found, no names replaced\n";
}
# Recognizing known subroutine names

if (%routines) {
    $pattern = join '|', keys %routines;
    $prog =~ s@L($pattern)@$routines{$1}@ge;
}

# Converting indirect addressing
while ($prog =~ s@;,WTC,([^;]+);([^;]+)@;\2\[\1\]@g) { }

$prog =~ s@;,UTC,([^;]+);([^;]*?),([^,;]+);@;\2,*(&\1+\3);@g;
# $prog =~ s@;14,UTC,([^;]+);([^;]*?),([^,;]+);@;\2,\3[R14+\1];@g;

# Reading the address of a variable
$prog =~ s@14,VTM,([^;]+);,IT([AS]),14@,XT\2,&\1@g;

# Setting a register in an indirect way
$prog =~ s@,XTA,int\((\d+)\);,ATI,(\d+)@\2,VTM,\1@g;

# Recognizing a variety of write routines

sub getString {
    my ($addr, $len, $f) = @_;
    my $i = $len;
    my $ret = '';
    while ($i > 0) {
        $ret .= defined($strings[$addr]) ? $strings[$addr] : "??[$addr]??";
	++$addr;
        $i -= 6;
    }
    return $f ? "write($f, '$ret')": "write('$ret')";
}

$prog =~ s@10,VTM,(\d+);12,VTM,(\w+);?13,VJM,P/6A *@-\2-writeAlfa\1@g;
$prog =~ s@(12,VTM,OUTPUT;)?13,VJM,P/7A *@writeString@g;
$prog =~ s@12,VTM,(\w+);13,VJM,L5353 *@-\1-writeString@g;
$prog =~ s@12,VTM,(\w+);writeString@-\1-writeString@g;
$prog =~ s@(12,VTM,OUTPUT;)?13,VJM,P/WI *@writeInt@g;
$prog =~ s@(12,VTM,OUTPUT;)?13,VJM,P/A6 *@writeAlfaWide@g;
$prog =~ s@(12,VTM,OUTPUT;)?13,VJM,P/WL *@writeLN@g;
$prog =~ s@(12,VTM,OUTPUT;)?13,VJM,P/CW *@writeChar@g;
$prog =~ s@(12,VTM,OUTPUT;)?13,VJM,P/WC *@writeCharWide@g;
$prog =~ s@13,VJM,P/WOLN *@writeLN@g;

$prog =~ s@12,VTM,([^;]+);13,VJM,P/EO *@eof(\1)@g;
$prog =~ s@12,VTM,([^;]+);13,VJM,P/EL *@eoln(\1)@g;
$prog =~ s@12,VTM,([^;]+);13,VJM,P/GF *@get(\1)@g;
$prog =~ s@12,VTM,([^;]+);13,VJM,P/PF *@put(\1)@g;
$prog =~ s@12,VTM,([^;]+);13,VJM,P/RF *@reset(\1)@g;
$prog =~ s@12,VTM,([^;]+);13,VJM,P/TF *@rewrite(\1)@g;

$prog =~ s@11,VTM,(\d+);10,VTM,(\d+);writeString@getString($1,$2)@ge;
$prog =~ s@11,VTM,(\d+);10,VTM,(\d+);-(\w+)-writeString@getString($1,$2,$3)@ge;

# Converting NEW

$prog =~ s@14,VTM,(\d+);13,VJM,P/NW *;,ATX,([^;]+)@new(\2=\1)@g;

# Converting calls (including scope-crossing calls)

$prog =~ s@13,VJM,([^;]+);13,VJM,P/\d\d@CALL \1@g;
$prog =~ s@13,VJM,([^;]+)(;7,MTJ,\d)?@CALL \1@g;

# Removing base register resetting after external calls
$prog =~ s@8,BASE,([^;]+);@@g;
$prog =~ s@,NTR,6;@@g;

# Converting non-local GOTO

$prog =~ s@\d,MTJ,13;14,VTM,([^;]+);,UJ,P/RC *@GOTO \1@g;

# Recognizing casts and conversions 
$prog =~ s@,NTR,0(;,AVX,0)?@toReal@g;
$prog =~ s@,APX,p77777;,ASN,64\+33;,AEX,int\(0\)@mapAI@g;
$prog =~ s@,A\+X,half;,NTR,7;,A\+X,int\(0\)@round@g;

# Simplifying code for case statements

$prog =~ s@15,ATX,1;,UJ,@caseto @g;

$prog =~ s@15,XTA,1;,A-X,([^;]+);,U1A,([^;]+);,X-A,([^;]+);,U1A,\2;15,XTA,1;,ATI,14@Case decoder from \1 to \1+\3, otherwise goto \2@g;

# Converting common conditional branches

$prog =~ s@;(\d+)?,AAX,([^;]+);,UZA,@;\1,AAX,\2;ifnot @g;
$prog =~ s@;(\d+)?,AEX,([^;]+);,UZA,@;\1,CEQ,\2;ifgoto @g;
$prog =~ s@;(\d+)?,A-X,([^;]+);,UZA,@;\1,CGE,\2;ifgoto @g;
$prog =~ s@;(\d+)?,X-A,([^;]+);,UZA,@;\1,CLE,\2;ifgoto @g;

$prog =~ s@;(\d+)?,AAX,([^;]+);,U1A,@;\1,AAX,\2;ifgoto @g;
$prog =~ s@;(\d+)?,AEX,([^;]+);,U1A,@;\1,CNE,\2;ifgoto @g;
$prog =~ s@;(\d+)?,A-X,([^;]+);,U1A,@;\1,CLT,\2;ifgoto @g;
$prog =~ s@;(\d+)?,X-A,([^;]+);,U1A,@;\1,CGT,\2;ifgoto @g;

$prog =~ s@;(\d+)?,AAX,([^;]+);isUZACond@;\1,AAX,\2;invBool@g;
$prog =~ s@;(\d+)?,AEX,([^;]+);isUZACond@;\1,CEQ,\2;toBool@g;
$prog =~ s@;(\d+)?,A-X,([^;]+);isUZACond@;\1,CGE,\2;toBool@g;
$prog =~ s@;(\d+)?,X-A,([^;]+);isUZACond@;\1,CLE,\2;toBool@g;

$prog =~ s@;(\d+)?,AAX,([^;]+);isU1ACond@;\1,AAX,\2;toBool@g;
$prog =~ s@;(\d+)?,AEX,([^;]+);isU1ACond@;\1,CNE,\2;toBool@g;
$prog =~ s@;(\d+)?,A-X,([^;]+);isU1ACond@;\1,CLT,\2;toBool@g;
$prog =~ s@;(\d+)?,X-A,([^;]+);isU1ACond@;\1,CGT,\2;toBool@g;

$prog =~ s@;(\d+)?,XTA,([^;]+);,UZA,@;\1,XTA,\2;,CEQ,0;ifgoto @g;
$prog =~ s@;(\d+)?,XTA,([^;]+);,U1A,@;\1,XTA,\2;,CNE,0;ifgoto @g;

$prog =~ s@;CALL P/IN *;,UZA,@;CALL P/IN;ifnot @g;
$prog =~ s@;CALL P/IN *;,U1A,@;CALL P/IN;ifgoto @g;

$prog =~ s@;(eo[^;]+);,UZA,@;\1;ifnot @g;
$prog =~ s@;(eo[^;]+);,U1A,@;\1;ifgoto @g;

$prog =~ s@;(\d+)?,XTA,([^;]+);isUZACond@;\1,XTA,\2;,CEQ,0;toBool@g;
$prog =~ s@;(\d+)?,XTA,([^;]+);isU1ACond@;\1,XTA,\2;,CNE,0;toBool@g;


@ops = split /;/, $prog;

print "Got $#ops lines\n";


# Emulating a simple stack machine starting with XTA
# and ending with a non-recognized operation or a label. At that point the stack is
# dumped and reset.


$from = 0;
@stack = ();

@to = ();

sub dumpStack {
    push @to, '#' . join(' % ', @stack) if @stack;
    @stack = ();
}

while ($from <= $#ops) {
    my $line = $ops[$from];

    if (@stack && $line =~ m@CALL P/MI@) {
        $stack[$#stack] = "mulFix($stack[$#stack])";
        ++$from;
        next;
    }
    if (@stack && $line eq ',YTA,64') {
        $stack[$#stack] = "nonNeg($stack[$#stack])";
        ++$from;
        next;
    }
    if (@stack && $line =~ m@CALL P/SS@) {
        $stack[$#stack] = "toSet($stack[$#stack])";
        ++$from;
        next;
    }
    if (@stack && $line =~ m@CALL P/TR@) {
        $stack[$#stack] = "trunc($stack[$#stack])";
        ++$from;
        next;
    }
    if (@stack && $line =~ m/^(toBool|toReal|invBool|mapAI|round)$/) {
        $stack[$#stack] = "$1($stack[$#stack])";
        ++$from;
        next;
    }
    if ($line =~ /^eo[lf]/) {
        if (@stack) { $stack[$#stack] = $line; }
        else { $stack[0] = $line; }
        ++$from;
        next;
    }
    if (@stack >= 2 && $line =~ m@CALL P/IN@) {
        $stack[$#stack-1] = "($stack[$#stack] IN $stack[$#stack-1])";
        --$#stack;
        ++$from;
        next;
    }
    if (@stack >= 2 && $line =~ m@CALL P/PI@) {
        $stack[$#stack-1] = "toRange($stack[$#stack-1]..$stack[$#stack])";
        --$#stack;
        ++$from;
        next;
    }
    if (@stack >= 2 && $line =~ m@CALL P/DI@) {
        $stack[$#stack-1] = "($stack[$#stack-1] DIV $stack[$#stack])";
        --$#stack;
        ++$from;
        next;
    }
    if (@stack >= 2 && $line =~ m@CALL P/IS@) {
        $stack[$#stack-1] = "($stack[$#stack-1] /int/ $stack[$#stack])";
        --$#stack;
        ++$from;
        next;
    }
    if (@stack >= 2 && $line =~ m@CALL P/MD@) {
        $stack[$#stack-1] = "($stack[$#stack-1] MOD $stack[$#stack])";
        --$#stack;
        ++$from;
        next;
    }
    if (@stack && $line =~ m@,AVX,int\(-1\)@) {
        $stack[$#stack] = "neg($stack[$#stack])";
        ++$from;
        next;
    }
    if (@stack && $line =~ m@,AMX,0@) {
        $stack[$#stack] = "abs($stack[$#stack])";
        ++$from;
        next;
    }
    if (@stack && $line =~ m@,ACX,0@) {
        $stack[$#stack] = "card($stack[$#stack])";
        ++$from;
        next;
    }
    if (@stack && $line =~ m@,ANX,int\(0\)@) {
        $stack[$#stack] = "ffs($stack[$#stack])";
        ++$from;
        next;
    }
    if (@stack && $line =~ m@,ATI,(\d+)@) {
        $stack[$#stack] = "{R$1=$stack[$#stack]}";
        ++$from;
        next;
    }

    if (@stack && ($line =~ /CALL / || $line =~ /^write/) ) {
        # This is not always correct; some values are put on the stack
        # to be consumed after the return from a subroutine.
        push @to, "$line( ".join(', ', @stack)." )";
        ++$from;
        @stack = ();
        next;
    }
    if (@stack >= 2 && $line =~ m@15,A([-/EROA+*])X,0?$@) {
        $op = $1;
        $op =~ tr/EROA/^$|&/;
        $stack[$#stack-1] = "($stack[$#stack] $op $stack[$#stack-1])";
        --$#stack;
        ++$from;
        next;
    }

    if (@stack >= 2 && $line =~ m@15,C(..),0?$@) {
        $op = $1;
        $stack[$#stack-1] = "($stack[$#stack] $op $stack[$#stack-1])";
        --$#stack;
        ++$from;
        next;
    } elsif (@stack && $line =~ m@^,C(..),(.*)@) {
        $op = $1;
        $stack[$#stack] = "($stack[$#stack] $op $2)";
        ++$from;
        next;
    } elsif (@stack && $line =~/^ifgoto (.*)/) {
        push @to, "if $stack[$#stack] goto $1";
        # If there was just one element on the stack, consider it consumed
        @stack = () if @stack == 1;
        ++$from;
        next;
    } elsif (@stack && $line =~/^ifnot (.*)/) {
        push @to, "if not $stack[$#stack] goto $1";
        # If there was just one element on the stack, consider it consumed
        @stack = () if @stack == 1;
        ++$from;
        next;
    } elsif (@stack && $line =~/^caseto (.*)/) {
        push @to, "case $stack[$#stack] at $1";
        # If there was just one element on the stack, consider it consumed
        @stack = () if @stack == 1;
        ++$from;
        next;
    }
    
    if ($line !~ /,[ASX].[ASX],/ || (@stack && $line =~ /:/)) {
        dumpStack() if @stack;
        push @to, $ops[$from++];
        next;
    }
    if ($line eq '15,XTA,3') {
        if (@stack) { $stack[$#stack] = 'FUNCRET'; }
        else { $stack[0] = 'FUNCRET'; }
        ++$from;
    } elsif ($line =~ /^,XTA,(.*)/) {
        if (@stack) { $stack[$#stack] = $1; }
        else { $stack[0] = $1; }
        ++$from;
    } elsif ($line =~ /15,XTA,$/) {
        ++$from;
        if (@stack) { --$#stack; }
        else { push @to, "!!! Popping empty stack at $from"; }
    } elsif (@stack && $line =~ m@^,A([-+*/EROA])X,(.*)@) {
        $op = $1;
        $op =~ tr/EROA/^$|&/;
        $stack[$#stack] = "($stack[$#stack] $op $2)";
        ++$from;
    } elsif (@stack && $line =~ m@^,X-A,(.*)@) {
        $stack[$#stack] = "($1 - $stack[$#stack])";
        ++$from;
    } elsif (@stack && $line =~/^,XTS,(.*)/) {
        $stack[++$#stack] = $1;
        ++$from;
    } elsif (@stack && $line eq '15,ATX,0') {
        push @stack, $stack[$#stack];
        ++$from;
    } elsif (@stack && $line =~ /^,ATX,(.*)/) {
        push @to, "$1 := $stack[$#stack]";
        # If there was just one element on the stack, consider it consumed
        @stack = () if @stack == 1;
        ++$from;
    } elsif (@stack && $line =~ /^,STX,(.*)/) {
        push @to, "$1 := $stack[$#stack--]";
        ++$from;
    } else {
        dumpStack() if @stack;
        push @to, $ops[$from++];
        next;
    }             
}

$prog = join ';', @to;

# Converting simple ops

$prog =~ s@,UJ,P/E *;@RETURN;@g;
$prog =~ s@;([^;:]+) := g23z@;setup(\1)@g;
$prog =~ s@;g23z := ([^;]+)@;rollup(\1)@g;

# Removing stack corrections after calls
$prog =~ s@15,UTM,[34];@@g;


# Converting small literals to enums based on context
$context = 'SY |checkSymAndRead|requiredSymErr|ifWhileStatement';

sub convertEnumSet {
    my $bitset = $_[0];
    my $enum = $_[1];
    $bitset =~ s/0/OOO/g;
    $bitset =~ s/1/OOI/g;
    $bitset =~ s/2/OIO/g;
    $bitset =~ s/3/OII/g;
    $bitset =~ s/4/IOO/g;
    $bitset =~ s/5/IOI/g;
    $bitset =~ s/6/IIO/g;
    $bitset =~ s/7/III/g;
    $bitset = 'O'x(48-length($bitset)) . $bitset;
    my @bits = split //, $bitset;
    my @set = ();
    for ($i = 0; $i < 48; ++$i) { push @set, ${$enum}[$i] if $bits[$i] eq 'I'; }
    return '['.join(',', @set).']';
}

sub convertIntSet {
    my $bitset = $_[0];
    my $orig = $bitset;
    $bitset =~ s/0/OOO/g;
    $bitset =~ s/1/OOI/g;
    $bitset =~ s/2/OIO/g;
    $bitset =~ s/3/OII/g;
    $bitset =~ s/4/IOO/g;
    $bitset =~ s/5/IOI/g;
    $bitset =~ s/6/IIO/g;
    $bitset =~ s/7/III/g;
    $bitset = 'O'x(48-length($bitset)) . $bitset;
    my @bits = split //, $bitset;
    my @set = ();
    for ($i = 0; $i < 48; ++$i) { push @set, $i if $bits[$i] eq 'I'; }
    $bitset = '['.join(',', @set).']';
    # printf STDERR "Converting $orig to $bitset\n";
    return $bitset;
}

if (open(SYMBOL, "symbol.txt")) {
    while (<SYMBOL>) {
        my ($val, $name) = split;
        $symbol[oct($val)] = $name;
    }
    close(SYMBOL);
    
    $prog =~ s@(($context)[^;]+?)\(([0-7][0-7]?)C\)@"$1$symbol[oct($3)]"@ge;

    $prog =~ s@SY IN ([^;]*?)\(([0-7]+)C\)@"SY IN $1".convertEnumSet($2, \ \@symbol)@ge;
    $prog =~ s@(skipToSet|statBegSys|statEndSys|blockBegSys) ([^;]*?)\(([0-7]+)C\)@"$1 $2".convertEnumSet($3, \ \@symbol)@ge;
} else {
    print STDERR "symbol.txt not found, SY enums not replaced\n";
}

if (open(OPERATOR, "operator.txt")) {
    while (<OPERATOR>) {
        my ($val, $name) = split;
        $oper[oct($val)] = $name;
    }
    close(OPERATOR);
    $context = 'charClass';
    
    $prog =~ s@(($context)[^;]+?)\(([0-7][0-7]?)C\)@"$1$oper[oct($3)]"@ge;
    $prog =~ s@charClass IN ([^;]*?)\(([0-7]+)C\)@"charClass IN $1".convertEnumSet($2, \ \@oper)@ge;
    $prog =~ s@(lvalOpSet) ([^;]*?)\(([0-7]+)C\)@"$1 $2".convertEnumSet($3, \ \@oper)@ge;

} else {
    print STDERR "operator.txt not found, OP enums not replaced\n";
}

if (open(OPTIONS, "options.txt")) {
    while (<OPTIONS>) {
        my ($val, $name) = split;
        $opts[oct($val)] = $name;
    }
    close(OPTIONS);
    # $context = 'optSflags';
    
    # $prog =~ s@(($context)[^;]+?)=([0-7][0-7]?)([^0-7])@"$1$oper[oct($3)]$4"@ge;
    $prog =~ s@optSflags ([^;]*?)\(([0-7]+)C\)@"optSflags $1".convertEnumSet($2, \ \@opts)@ge;

} else {
    print STDERR "operator.txt not found, OP enums not replaced\n";
}

if (open(FORM, "form.txt")) {
    while (<FORM>) {
        my ($val, $name) = split;
        $form[oct($val)] = $name;
    }
    close(FORM);
    $context = 'formOperator';
    
    $prog =~ s@(($context)[^;]+?)\(([0-7][0-7]?)C\)@"$1$form[oct($3)]"@ge;
    # $prog =~ s@formOperator ([^;]*?)=([0-7]+)@"formOperator $1".convertEnumSet($2, \ \@form)@ge;

} else {
    print STDERR "operator.txt not found, OP enums not replaced\n";
}

# Converting chars based on context
$prog =~ s@(CH [^;]+)\(([0-7][0-7][0-7]?)C\)@"$1'".chr(oct($2))."'"@ge;

# Converting sets based on context
$prog =~ s@ IN \(([0-7]+)C\)@" IN ".convertIntSet($1)@ge;
$prog =~ s@ \| \(([0-7]+)C\)@" + ".convertIntSet($1)@ge;
$prog =~ s@ \& \(([0-7]+)C\)@" * ".convertIntSet($1)@ge;

$prog =~ s@(if[^;]*)\(\(\(([0-7]+)C\) \^ allones\) \& ([^()]+)\)@"$1 not ($3 <= ".convertIntSet($2).')'@ge;
$prog =~ s@\(\(\(([0-7]+)C\) \^ allones\) \& ([^()]+)\)@"($2 - ".convertIntSet($1).')'@ge;
    
if (open(HELPERS, "helpers.txt")) {
    while (<HELPERS>) {
        chop;
        my ($val, $name) = split;
#        $prog =~ s@(getHelperProc[^;]+)int\($val\)@\1"$name"@g;
         $prog =~ s@(getHelperProc[^;]+)\($val\)@\1"$name"@g;
         $prog =~ s@(P0715[^;,]+?,[^;]+?)\($val\)@\1"$name"@g;
    }
    close(HELPERS);
} else {
    print STDERR "File helpers.txt not found, no names replaced\n";
}

if (open(ERRORS, "errors.txt")) {
    while (<ERRORS>) {
        chop;
        my ($val, $name) = split;
        $prog =~ s@((error|errAndSkip|printErrMsg)[^;]+)\($val\)@\1$name@g;
    }
    close(ERRORS);
} else {
    print STDERR "File errors.txt not found, no names replaced\n";
}

# Convert if/then/else (nesting not handled due to label reuse)

# while ($prog =~ s@;if ([^;]+)goto ([^;]+);(.*),UJ,([^;]+);\2:(.*)\4:@;if \1 {;\2:\5;\4:;} else {;\3};@g) { }

# Marking up for loops
# $prog =~ s@,UJ,([^;]+);([^:]+):(.*)\1:(.*);ifgoto \2@loop {;\3 } while (;\4;)@g;

# Finding case statements (kinda slow)

# $prog =~ s@,UJ,([^;]+);(.*?)\1:,BSS,;15,ATX,1;,CLT,([^;]+);ifgoto ([^;]+);,CGT,([^;]+);ifgoto \4;15,XTA,1;,ATI,14;14,UJ,([^;]+)@case in [\3 .. \5] else \6; { \2 };@g;

# Finding only bounds (faster)
# $prog =~ s@:,BSS,;15,ATX,1;,CLT,([^;]+);ifgoto ([^;]+);,CGT,([^;]+);ifgoto \2@:bounds [\1 .. \3] else \2@g;

# Simplifying function call/returns

$prog =~ s@CALL([^;]+);([^;]+)FUNCRET([^;]*);@\2 \1 \3;@g;
$prog =~ s@CALL @@g;

# Converting structure field access

$prog =~ s/(\d+)\[([^][]+)\]/\2@.f[\1]/g;

$relop{' EQ '} = ' = ';
$relop{' NE '} = ' <> ';
$relop{' LT '} = ' < ';
$relop{' LE '} = ' <= ';
$relop{' GT '} = ' > ';
$relop{' GE '} = ' >= ';
# Converting relational ops
$prog =~ s/( EQ | NE | LT | LE | GT | GE )/$relop{$1}/ge;

# Removing extra spaces

$prog =~ s/ +;/;/g;
$prog =~ s/ +\( +/ (/g;
$prog =~ s/ +\) +/) /g;

$prog =~ s/;([^;]+);-(\w+)-writeAlfa(\d)/;writeAlfa\3(\2, \1)/g;

#Restoring line feeds

$prog =~ s/;/;\n /g;

sub mkargs {
  my $ret = "l$_[0]a1z";
  map { $ret .= ", l$_[0]a${_}z"; } (2..$_[1]) if $_[1] > 1;
  return $ret . ":integer";
}
sub mkvars {
  return "" if $_[1] == 0;
  my $ret = "_var l$_[0]v1z";
  map { $ret .= ", l$_[0]v${_}z"; } (2..$_[1]) if $_[1] > 1;
  return $ret . ":integer;";
}
$prog =~ s/\n (.*): Level (\d) procedure with 0 arguments and (\d+) locals?;/"\n(* Level $2 *) procedure $1;\n".mkvars($2,$3)." _("/ge;
$prog =~ s/\n (.*): Level (\d) procedure with (\d) arguments? and (\d+) locals?;/"\n(* Level $2 *) procedure $1(".mkargs($2, $3).");\n".mkvars($2, $4)." _("/ge;
$prog =~ s/\n (.*): Level (\d) function with (\d) arguments? and (\d+) locals?;/"\n(* Level $1 *) function $1(".mkargs($2, $3)."):integer;\n".mkvars($2, $4)." _("/ge;

$prog =~ s/RETURN;\n ===/_);\n ===/g;

print $prog;

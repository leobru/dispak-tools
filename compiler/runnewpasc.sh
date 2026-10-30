#!/bin/sh
# Compile and run a Pascal program with NEWPASC, the improved compiler
# that mypas.b6 builds onto disk 77 (run "dispak -l mypas.b6" first).
# Usage: ./runnewpasc.sh prog.pas [dispak options]
# The job listing goes to stdout.
prog=$1; shift
deck=`mktemp`
{
cat <<'HDR'
user 419900 зс5^
dis 67(77)^
dis 66(2148-440)^
dis 65(2048)^
EEB1A3
*name
*call yesmemory
*libra:66
*call ocatalog:670000
*system
*trans:newpasc,,670000
HDR
cat "$prog"
cat <<'TRL'
*execute
*end file
``````
ЕКОНЕЦ
TRL
} > $deck
dispak -l "$@" $deck
rm -f $deck

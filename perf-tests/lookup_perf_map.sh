#!/bin/bash

#
# usage:
# $> ./lookup_perf_map.sh 140000000 ./perf.map
#
# Prints all lines of a `/tmp/perf-PID.map`-file style that contains/encapsulate
# the given address.
#

set -euo pipefail

addr="$1"
file="$2"

[[ "$addr" == 0x* ]] || addr="0x$addr"

echo "Looking for $addr in $file:"

gawk -v "n=$addr" 'BEGIN {n=strtonum(n)} // { st=strtonum("0x"$1); si=strtonum("0x"$2); if (n > st && n < st + si) print; }' "$file"

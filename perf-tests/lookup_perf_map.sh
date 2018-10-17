#!/bin/bash

set -euo pipefail

usage() {
    echo -n "$0: ADDRESS FILE

example: $0 140000000 ./perf.map

Prints all lines of a /tmp/perf-PID.map-file style FILE that
contains/encapsulate the given ADDRESS.

"
}

if [[ "${1:--h}" = "-h" || "${1:-}" = "--help" ]]
then
    usage
    exit 0
fi

addr="$1"
file="$2"

[[ "$addr" == 0x* ]] || addr="0x$addr"

echo "Looking for $addr in $file:"

gawk -v "n=$addr" 'BEGIN {n=strtonum(n)} // { st=strtonum("0x"$1); si=strtonum("0x"$2); if (n > st && n < st + si) print; }' "$file"

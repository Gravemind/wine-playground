#!/bin/bash

set -euo pipefail

here="$(cd "$(dirname "$0")"; pwd)"

bin="$1"
out="$2"

echo "bench $bin to $out"

export WINEARCH=win64
export WINEPREFIX="$here/wineprefix"

rm -f "$out"

cmd=( "./$bin" 30000000 )

if [[ "$bin" = *.exe ]]
then
    bench() {
        # warmup
        wine "./$bin" 10 > /dev/null

        /usr/bin/time -f '%e' -ao "$out" wine "${cmd[@]}" > /dev/null
    }
else
    bench() {
        # warmup
        "./$bin" 10 > /dev/null

        /usr/bin/time -f '%e' -ao "$out" "${cmd[@]}" > /dev/null
    }
fi

rm -f "$out"
for ((i=0; i<3; ++i))
do
    bench
done

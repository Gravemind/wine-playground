#!/usr/bin/env python3

#
# usage:
# $> ./lookup_maps.py 1405936f1 ./proc_maps
#
# Prints all lines of a `/proc/PID/maps`-style file that contains/encapsulate
# the given address.
#

import sys
import os.path
import subprocess
import re

import pprint
pp = pprint.PrettyPrinter(indent=4).pprint

def main(args):
    look_addr = int(args[0], base=16)
    maps_file = args[1]

    with open(maps_file, 'r') as f:
        last_lines = []
        last_path = ""
        for line in f:
            spl = line.split(maxsplit=5)
            assert(len(spl) == 5 or len(spl) == 6)

            addrs = [ int(a, base=16) for a in spl[0].split('-', maxsplit=2) ]
            path = spl[5] if len(spl) == 6 else None

            if path is None:
                path = last_path
                last_lines.append(line)
            else:
                last_path = path
                last_lines = [ line ]

            if look_addr >= addrs[0] and look_addr < addrs[1]:

                for l in last_lines:
                    print(l, end="")

                break

if __name__ == "__main__":
    ret = main(sys.argv[1:])
    sys.exit(ret)

#!/usr/bin/env python3

import sys
import os.path
import subprocess
import re

import pprint
pp = pprint.PrettyPrinter(indent=4).pprint

def usage():
    u="""usage: {exe} [-h] ADDRESS FILE

example: {exe} 1405936f1 ./proc_maps

Prints all lines of a /proc/PID/maps-style FILE that contains/encapsulate the
given ADDRESS (hex).

""".format(exe=sys.argv[0])
    print(u, end="")

def main(args):

    if len(args) > 0 and (args[0] == '-h' or args[0] == '--help'):
        usage();
        return 0

    if len(args) != 2:
        print("invalid argument", file=sys.stderr)
        usage();
        return 1

    look_addr = int(args[0], base=16)

    if args[1] != '-':
        maps_file = open(args[1], 'r')
    else:
        maps_file = os.fdopen(sys.stdin.fileno(), 'r')

    with maps_file as f:
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

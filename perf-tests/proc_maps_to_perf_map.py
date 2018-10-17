#!/usr/bin/env python3

proc_maps_path = "proc_maps"
output_perf_map = "perf.map"

import sys
import os.path
import subprocess
import re

import pprint
pp = pprint.PrettyPrinter(indent=4).pprint

def usage():
    u="""usage: {exe} [-h] [INPUT [OUTPUT]]

example: {exe} < /proc/PID/maps > /tmp/perf-PID.map

Reads INPUT (stdin by default) expecting /proc/PID/maps style content, objdumps
all .dll and .exe, and generates a perf.map style output (for perf report) to
OUTPUT (stdout by default) containing all mapped symbols.

""".format(exe=sys.argv[0])
    print(u)

def log(*args, **kargs):
    print(*args, **kargs, file=sys.stderr)

class Mapping:
    def __init__(self):
        #self.base = -1
        self.start = -1
        self.end = -1

    def add(self, start, end):
        if self.start == -1:
            self.start = start
        else:
            assert(start > self.start)
        assert(end > self.end)
        self.end = end

class Lib:
    def __init__(self, path):
        self.path = path
        self.mappings = []
        self.syms = None

    def __repr__(self):
        return "{!r} {:x} [{:x}-{:x}]".format(self.path, self.base, self.start, self.end)

    RE_HEADER_KV = re.compile(r"^([A-Za-z]+)\t+([0-9A-Za-z]+)")
    RE_SYM = re.compile(r"^([0-9a-zA-Z]+) <(.+)>:$")

    def extract_symbols(self):
        prefix = os.path.basename(self.path)
        log(prefix)

        log("  mappings:")
        for mapping in self.mappings:
            log("    {:x} - {:x}".format(mapping.start, mapping.end))

        self.syms = []
        self.image_ph = dict()

        i = 0
        head_n = 100
        with subprocess.Popen(['objdump', '-p', self.path], stdout=subprocess.PIPE) as proc:
            for line in proc.stdout:
                m = re.match(Lib.RE_HEADER_KV, str(line, 'utf-8'))
                if m:
                    k = m.group(1)
                    v = int(m.group(2), base=16)
                    assert(k not in self.image_ph)
                    self.image_ph[k] = v
                i += 1
                if i > head_n:
                    break
        self.image_base = self.image_ph['ImageBase']
        self.image_code_offset = self.image_ph['BaseOfCode']
        self.image_size = self.image_ph['SizeOfImage']

        log("  base: {:x}".format(self.image_base))

        base = self.image_base + self.image_code_offset

        with subprocess.Popen(['objdump', '-C', '-d', self.path], stdout=subprocess.PIPE) as proc:
            last_addr = -1
            last_name = "??"
            for line in proc.stdout:
                line = str(line, 'utf-8')
                m = re.match(Lib.RE_SYM, line)
                if m:
                    addr = int(m.group(1), base=16) - base
                    assert(addr >= 0 and addr < self.image_size)
                    name = m.group(2)
                    if last_addr > 0:
                        self.syms.append( [ last_addr, addr - last_addr, last_name ] )
                    last_addr = addr
                    last_name = name
            if len(self.syms) > 0:
                start = self.syms[0][0]
                assert(start >= 0)
                end = start + self.image_size
                assert(end >= last_addr)
                self.syms.append( [ last_addr, end - last_addr, last_name ] )

    def output_perf_map(self):
        o = ""
        prefix = os.path.basename(self.path)

        i = 0
        for mapping in self.mappings:
            base = mapping.start + self.image_code_offset

            # if base + self.image_size > mapping.end:
            #     log("{}: no space for mapping to {:x}-{:x}, need up to {:x}".format(prefix, mapping.start, mapping.end, base + self.image_size))
            #     continue

            last_known = 0

            si = 0
            for sym in self.syms:
                if sym[0] > last_known:
                    o += "{:x} {:x} {}_{}_{}\n".format(base + last_known, sym[0] - last_known, prefix, i, "padd"+str(i))
                    si += 1
                o += "{:x} {:x} {}_{}_{}\n".format(base + sym[0], sym[1], prefix, i, sym[2])
                last_known = sym[0] + sym[1]

            if base + last_known < mapping.end:
                o += "{:x} {:x} {}_{}_{}\n".format(base + last_known, mapping.end - (base + last_known), prefix, i, "TAIL")

            i += 1

        # for mapping in self.mappings:
        #     o += "{:x} {:x} {}_{}\n".format(mapping.start, mapping.end - mapping.start, prefix, i)

        # for sym in self.syms:
        #     o += "{:x} {:x} {}_{}\n".format(sym[0], sym[1], prefix, sym[2])

        return o

def main(args):

    proc_libs_bypath = dict()

    if len(args) > 0 and (args[0] == '-h' or args[0] == '--help'):
        usage();
        return 0

    if len(args) > 1 and args[0] != '-':
        maps_file = open(args[0], 'rb')
    else:
        maps_file = os.fdopen(sys.stdin.fileno(), 'rb')

    with maps_file as f:
        lastmap = None
        content = str(f.read(), 'utf-8')
        #content = f.read()
        #log(content)
        for line in content.splitlines():
            spl = line.split(maxsplit=5)
            assert(len(spl) == 5 or len(spl) == 6)
            addrs = [ int(a, base=16) for a in spl[0].split('-', maxsplit=2) ]
            path = spl[5] if len(spl) == 6 else None

            if path is not None:
                lastmap = proc_libs_bypath.setdefault(path, Lib(path))
                lastmap.mappings.append( Mapping() )

            if lastmap is not None:
                lastmap.mappings[-1].add(addrs[0], addrs[1])

    for path, mp in proc_libs_bypath.items():
        if path.endswith(" (deleted)"):
            continue
        if not (path.endswith(".dll") or path.endswith(".exe")):
            continue
        if not os.path.exists(path):
            log("Not such file: " + path)

        mp.extract_symbols()

    if len(args) > 1 and args[1] != '-':
        perf_file = open(args[1], 'w')
    else:
        perf_file = sys.stdout

    with perf_file as output:
        for path, mp in proc_libs_bypath.items():
            if mp.syms is None:
                continue
            o = mp.output_perf_map()
            output.write(o)

    # pp(proc_maps_bypath)

if __name__ == "__main__":
    ret = main(sys.argv[1:])
    sys.exit(ret)

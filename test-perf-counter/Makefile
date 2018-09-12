
CC?=gcc
WINCC?=x86_64-w64-mingw32-gcc

CFLAGS=-Wall -Wextra -Wno-unused-parameter -O2

WIN_SRCS=win-query-perf-counter.c rdtsc.c rdtsc_flush.c
LINUX_SRCS=clock_gettime_mono.c clock_gettime_mono_raw.c rdtsc.c rdtsc_flush.c

BUILDDIR=build
BENCHDIR=bench_logs

all: $(WIN_SRCS:%.c=$(BUILDDIR)/%.exe) $(LINUX_SRCS:%.c=$(BUILDDIR)/%.elf)

bench: $(WIN_SRCS:%.c=$(BENCHDIR)/%.exe.bench) $(LINUX_SRCS:%.c=$(BENCHDIR)/%.elf.bench)

clean:
	rm -rf "$(BUILDDIR)"
	rm -rf "$(BENCHDIR)"

.PHONY: all bench clean

$(BUILDDIR)/%.exe: %.c Makefile | $(BUILDDIR)
	@echo "--- WIN: $@"
	$(WINCC) $(CFLAGS) -MD -MP -MF "$(@:.exe=.exe.d)" $< -o $@

$(BUILDDIR)/%.elf: %.c Makefile | $(BUILDDIR)
	@echo "--- LINUX: $@"
	$(CC) $(CFLAGS)  -MD -MP -MF "$(@:.elf=.elf.d)" $< -o $@

$(BENCHDIR)/%.bench: $(BUILDDIR)/% bench.sh | $(BENCHDIR)
	@echo --- BENCH $<
	./bench.sh $< $@

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

$(BENCHDIR):
	mkdir -p $(BENCHDIR)


# disable built-in rules (.sh)
.SUFFIXES:

-include $(WIN_SRCS:.c=.exe.d)
-include $(LINUX_SRCS:.c=.elf.d)


CFLAGS= -static -static-libgcc -O0 -gdwarf -fno-omit-frame-pointer

all:
	mkdir -p build
	x86_64-w64-mingw32-gcc $(CFLAGS) main.c -o build/test

.PHONY: all

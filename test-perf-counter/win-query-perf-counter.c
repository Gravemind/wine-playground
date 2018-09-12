
#include <windows.h>
#include <stdio.h>

#include "utils.h"

int main(int argc, char **argv)
{
    intlong             times = atol(argv[1]);
    uintlong            sum = 0;
    LARGE_INTEGER       c;
    for (long i = 0; i < times; ++i)
    {
        QueryPerformanceCounter(&c);
        sum += c.QuadPart;
    }
    printf("%" PRIduil "\n", sum);
    return 0;
}

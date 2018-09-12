
#include "utils.h"

#include <time.h>

#ifndef BENCH_USE_CLOCK
#   define BENCH_USE_CLOCK CLOCK_MONOTONIC
#endif

#define TICKSPERSEC        10000000

static uintlong monotonic_counter(void)
{
    struct timespec ts;
    clock_gettime( BENCH_USE_CLOCK, &ts );
    return (uintlong)ts.tv_sec * (uintlong)TICKSPERSEC + (uintlong)ts.tv_nsec / (uintlong)100;
}


int main(int argc, char **argv)
{
    intlong     times = atol(argv[1]);
    uintlong    sum = 0;
    for (intlong i = 0; i < times; ++i)
    {
        sum += monotonic_counter();
    }
    printf("%" PRIduil "\n", sum);
    return 0;
}


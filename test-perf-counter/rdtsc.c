
#include "utils.h"

#ifdef WIN32
#   include <intrin.h>
#else
#   include <cpuid.h>
#endif

static uintlong rdtsc(void)
{
#ifdef BENCH_FLUSH
#   if WIN32
    int     _[4];
    __cpuid(_, 0);
#   else
    __asm__ __volatile__("cpuid" : : : "%eax", "%ebx", "%ecx", "%edx");

    // gets optimized out
    /* unsigned int _[4]; */
    /* __get_cpuid(0, _+0, _+1, _+2, _+3); */
#   endif
#endif
    return __rdtsc();
}

int main(int argc, char **argv)
{
    intlong     times = atol(argv[1]);
    uintlong    sum = 0;
    for (intlong i = 0; i < times; ++i)
    {
        sum += rdtsc();
    }
    printf("%" PRIduil "\n", sum);
    return 0;
}


#include <windows.h>
#include <time.h>
#include <sys/timeb.h>

void my_function() {
    time_t t;
    time(&t);
    double     i = 0;
    for (;;)
    {
        i += 42.2;
        i /= i - 245.0;
        //qtime_t t2;
        //time(&t2);
        //if (t2 - t > 10000)
        //break;
    }
}

int main(int argc, char **argv) {
    int class=0;
    my_function();
    return class;
}



#include <cstdlib>
#include <cstdio>
#include <unistd.h>
#include <string.h>

#include <X11/Xlib.h>
#include <X11/extensions/XInput2.h>
#include <X11/Intrinsic.h>

Boolean dispatch_generic_event(XEvent *event)
{
    printf("event %p\n", event);
    return true;
}

int main(int argc, char** argv)
{
    printf("XOpenDisplay\n");
    Display *dpy = XOpenDisplay(0);

    // https://keithp.com/blogs/Cursor_tracking/

    XIEventMask evmasks[1];
    unsigned char mask1[(XI_LASTEVENT + 7)/8];
    unsigned char mask2[(XI_LASTEVENT + 7)/8];

    memset(mask1, 0, sizeof(mask1));

    /* select for button and key events from all master devices */
    XISetMask(mask1, XI_RawMotion);

    evmasks[0].deviceid = XIAllMasterDevices;
    evmasks[0].mask_len = sizeof(mask1);
    evmasks[0].mask = mask1;

    printf("XISelectEvents\n");
    XISelectEvents(dpy,
                   RootWindowOfScreen(XDefaultScreenOfDisplay(dpy)),
                   evmasks, 1);
    XFlush(dpy);

    int xi_opcode, event, error;
    if (!XQueryExtension(dpy, "XInputExtension", &xi_opcode, &event, &error)) {
       printf("X Input extension not available.\n");
          return -1;
    }

    int     pointer;
    XIGetClientPointer(dpy, None, &pointer);
    int     dcount;
    XIDeviceInfo    *dev = XIQueryDevice(dpy, pointer, &dcount);

    for (int i = 0; i < dev->num_classes; i++)
    {
        if (dev->classes[i]->type != XIValuatorClass)
            continue;
        XIValuatorClassInfo *c = (XIValuatorClassInfo *)dev->classes[i];
        printf("%d: %g %g-%g\n", i, c->value, c->min, c->max);
    }

    double  x = 0, y = 0;

    XEvent ev;
    while(1) {
        XGenericEventCookie *cookie = &ev.xcookie;
        XIRawEvent      *re;
        Window          root_ret, child_ret;
        int         root_x, root_y;
        int         win_x, win_y;
        unsigned int        mask;

        XNextEvent(dpy, &ev);

        if (cookie->type != GenericEvent ||
            cookie->extension != xi_opcode ||
            !XGetEventData(dpy, cookie))
            continue;

        switch (cookie->evtype) {
        case XI_RawMotion:
            re = (XIRawEvent *) cookie->data;
            XQueryPointer(dpy, DefaultRootWindow(dpy),
                          &root_ret, &child_ret, &root_x, &root_y, &win_x, &win_y, &mask);
            x += re->raw_values[0];
            y += re->raw_values[1];
            printf ("raw %g,%g (%g,%g) root %d,%d\n",
                    re->raw_values[0], re->raw_values[1],
                    x, y,
                    root_x, root_y);
            break;
        }
        XFreeEventData(dpy, cookie);
    }

    printf("pause\n");
    char c;
    read(0, &c , 1);
    return 0;
}

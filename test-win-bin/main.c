
#include <windows.h>
#include <time.h>
#include <sys/timeb.h>
#include <stdio.h>

#include <winuser.h>
#include <windowsx.h>

LRESULT CALLBACK WindowProc(
    _In_ HWND   hwnd,
    _In_ UINT   uMsg,
    _In_ WPARAM wParam,
    _In_ LPARAM lParam
)
{
    //printf("msg %d\n", uMsg);
    switch (uMsg)
    {
    case WM_MOUSEMOVE:
    {
        /* RECT        r= {0, 0, 1000, 1000}; */
        /* ClipCursor(&r); */

        int x = GET_X_LPARAM(lParam);
        int y = GET_Y_LPARAM(lParam);
        printf("%d %d\n", x, y);
        break;
    }
    case WM_KEYDOWN:
    {
        RECT        r= {0, 0, 1000, 1000};
        ClipCursor(&r);
        break;
    }
    case WM_QUIT:
        exit(0);
    }
}

INT WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
            PSTR lpCmdLine, INT nCmdShow)
{

    // Register the window class.
    const char CLASS_NAME[]  = "Sample Window Class";

    WNDCLASS wc = { };

    wc.lpfnWndProc   = WindowProc;
    wc.hInstance     = hInstance;
    wc.lpszClassName = "Sample Window Class";

    RegisterClass(&wc);

    // Create the window.

    HWND hwnd = CreateWindowEx(
        0,                              // Optional window styles.
        CLASS_NAME,                     // Window class
        "Learn to Program Windows",    // Window text
        WS_OVERLAPPEDWINDOW,            // Window style

        // Size and position
        CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,

        NULL,       // Parent window
        NULL,       // Menu
        hInstance,  // Instance handle
        NULL        // Additional application data
    );

    if (hwnd == NULL)
    {
        return 0;
    }

    ShowWindow(hwnd, nCmdShow);

    SetCapture(hwnd);

    /* RECT        r= {0, 0, 1000, 1000}; */
    /* ClipCursor(&r); */
    /* ClipCursor(&r); */

    POINT       lp;
    for (;;)
    {

#if 1
        MSG     msg;
        BOOL bRet = GetMessage( &msg, NULL, 0, 0 );
        if (bRet == -1)
        {
            // handle the error and possibly exit
        }
        else
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }

#else
        POINT   p;
        GetCursorPos(&p);
        if (p.x != lp.x || p.y != lp.y)
        {
            printf("%d %d\n", p.x, p.y);
            lp = p;
        }
#endif

        Sleep(10);
    }
}

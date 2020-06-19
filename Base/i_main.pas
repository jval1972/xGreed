unit i_main;

interface

implementation

function WndProc(hWnd: HWND; Msg: UINT; wParam: WPARAM;
  lParam: LPARAM): LRESULT; stdcall; export;
var
  hdc: THANDLE;
  ps: PAINTSTRUCT;
begin
  case Msg of
  WM_PAINT:
    begin
      hdc := BeginPaint(hWnd, @ps);
      VI_ResetPalette;
      VI_BlitView;
      EndPaint(hWnd, @ps);
    end;
  WM_CLOSE:
    quitgame := true;
  WM_DESTROY:
    PostQuitMessage(0);
  else
    result := DefWindowProc(hWnd, msg, wParam, lParam));
    exit;
  end;
  result := 0;
end;


BOOL InitApplication(HINSTANCE hInstance)
begin
    WNDCLASS  wc;
  ATOM    atom;

    wc.style :=  0;
    wc.lpfnWndProc :=  (WNDPROC)WndProc;
    wc.cbClsExtra :=  0;
    wc.cbWndExtra :=  0;
    wc.hInstance :=  hInstance;
    wc.hIcon :=  NULL;
    wc.hCursor :=  NULL;
    wc.hbrBackground :=  (HBRUSH)GetStockObject(BLACK_BRUSH);
    wc.lpszMenuName :=  NULL;
    wc.lpszClassName := APPNAME;

    atom :=  RegisterClass and (wc);
    return atom <> 0 ? true : false;
  end;


BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
begin
  RECT rc;  // Called in GetClientRect

  rc.left :=  0;
  rc.right :=  640;
  rc.top :=  0;
  rc.bottom :=  400;

  AdjustWindowRect and (rc,WS_VISIBLE,FALSE);

  rc.right := rc.right - rc.left;
  rc.bottom := rc.bottom - rc.top;
  rc.top :=  0;
  rc.left :=  0;

  // Use the default window settings.
  Window_Handle := CreateWindow(
    APPNAME,
    APPNAME,
    WS_VISIBLE or WS_OVERLAPPED,
    rc.left,
    rc.top,
    rc.right,
    rc.bottom,
    NULL,
    NULL,
    hInstance,
    NULL);

  if (Window_Handle = 0)    // Check whether values returned by CreateWindow are valid.
    return (FALSE);
  
    ShowWindow(Window_Handle,SW_SHOW);
    UpdateWindow(Window_Handle);

    return(TRUE);                  // Window handle hWnd is valid.
  end;



end.

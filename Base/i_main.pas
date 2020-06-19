unit i_main;

interface

uses
  Windows;

function WndProc(hWnd: HWND; Msg: UINT; wParam: WPARAM;
  lParam: LPARAM): LRESULT; stdcall; export;

function InitApplication(inst: HINST): boolean;

function InitInstance(inst: HINST; nCmdShow: integer): boolean;

implementation

uses
  Messages,
  d_misc,
  d_video,
  i_windows,
  raven;

function WndProc(hWnd: HWND; Msg: UINT; wParam: WPARAM;
  lParam: LPARAM): LRESULT; stdcall; export;
var
  hdc: THANDLE;
  ps: PAINTSTRUCT;
begin
  case Msg of
  WM_PAINT:
    begin
      hdc := BeginPaint(hWnd, ps);
      VI_ResetPalette;
      VI_BlitView;
      EndPaint(hWnd, ps);
    end;
  WM_CLOSE:
    quitgame := true;
  WM_DESTROY:
    PostQuitMessage(0);
  else
    result := DefWindowProc(hWnd, msg, wParam, lParam);
    exit;
  end;
  result := DefWindowProc(hWnd, msg, wParam, lParam);
end;


function InitApplication(inst: HINST): boolean;
var
  wc: WNDCLASS;
  a: ATOM;
begin
  ZeroMemory(@wc, SizeOf(WNDCLASS));
  wc.style :=  0;
  wc.lpfnWndProc := @WndProc;
  wc.cbClsExtra := 0;
  wc.cbWndExtra := 0;
  wc.hInstance := inst;
  wc.hIcon := 0;
  wc.hCursor := 0;
  wc.hbrBackground := HBRUSH(GetStockObject(BLACK_BRUSH));
  wc.lpszMenuName :=  nil;
  wc.lpszClassName := APPNAME;

  a :=  RegisterClass(wc);
  result := a <> 0;
end;


function InitInstance(inst: HINST; nCmdShow: integer): boolean;
var
  rc: TRect;  // Called in GetClientRect
begin
  rc.left := 0;
  rc.right := 640;
  rc.top := 0;
  rc.bottom := 400;

  AdjustWindowRect(rc, WS_VISIBLE, false);

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
    0,
    0,
    hInstance,
    nil
  );

  if Window_Handle = 0 then // Check whether values returned by CreateWindow are valid.
  begin
    result := false;
    exit;
  end;

  ShowWindow(Window_Handle, SW_SHOW);
  UpdateWindow(Window_Handle);

  result := true; // Window handle hWnd is valid.
end;

end.

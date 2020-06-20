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
begin
  case Msg of
    WM_SETCURSOR:
      begin
        SetCursor(0);
      end;
    WM_SYSCOMMAND:
      begin
        if (wParam = SC_SCREENSAVE) or (wParam = SC_MINIMIZE) then
        begin
          result := 0;
          exit;
        end;
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
  wc.hIcon := LoadIcon(HInstance, 'MAINICON');
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
  I_SetDPIAwareness;

  rc.left := 0;
  rc.right := 640;
  rc.top := 0;
  rc.bottom := 400;

//  AdjustWindowRect(rc, WS_VISIBLE, false);

//  rc.right := rc.right - rc.left;
//  rc.bottom := rc.bottom - rc.top;
//  rc.top :=  0;
//  rc.left :=  0;

  // Use the default window settings.
  hMainWnd := CreateWindow(
    APPNAME,
    APPNAME,
    0,
    rc.left,
    rc.top,
    rc.right,
    rc.bottom,
    0,
    0,
    hInstance,
    nil
  );

  SetWindowLong(hMainWnd, GWL_STYLE, 0);

  if hMainWnd = 0 then // Check whether values returned by CreateWindow are valid.
  begin
    result := false;
    exit;
  end;

  ShowWindow(hMainWnd, SW_SHOW);
  UpdateWindow(hMainWnd);

  result := true; // Window handle hWnd is valid.
end;

end.

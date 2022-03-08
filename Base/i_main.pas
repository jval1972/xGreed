(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020-2022 by Jim Valavanis                                *)
(*                                                                         *)
(***************************************************************************)
(* License applies to this source file                                     *)
(***************************************************************************)
(*                                                                         *)
(*  This program is free software; you can redistribute it and/or          *)
(*  modify it under the terms of the GNU General Public License            *)
(*  as published by the Free Software Foundation; either version 2         *)
(*  of the License, or (at your option) any later version.                 *)
(*                                                                         *)
(*  This program is distributed in the hope that it will be useful,        *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of         *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *)
(*  GNU General Public License for more details.                           *)
(*                                                                         *)
(*  You should have received a copy of the GNU General Public License      *)
(*  along with this program; if not, write to the Free Software            *)
(*  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA              *)
(*  02111-1307, USA.                                                       *)
(*                                                                         *)
(***************************************************************************)

{$I xGreed.inc}

unit i_main;

interface

uses
  Windows;

function WndProc(hWnd: HWND; Msg: UINT; wParam: WPARAM;
  lParam: LPARAM): LRESULT; stdcall; export;

function InitApplication(inst: HINST): boolean;

function InitInstance(inst: HINST; nCmdShow: integer): boolean;

var
  InBackground: boolean = true;
  GameFinished: boolean = false;

implementation

uses
  Messages,
  d_misc,
  d_ints,
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
    WM_ACTIVATE:
      begin
        InBackground := (LOWORD(wparam) = WA_INACTIVE) or (HIWORD(wparam) <> 0);
        I_SynchronizeInput(not InBackground);
      end;
    WM_CLOSE:
      begin
        quitgame := true;
        result := 0;
        exit;
      end;
    WM_LBUTTONDOWN:
      lbuttondown := true;
    WM_LBUTTONUP:
      lbuttondown := false;
    WM_MBUTTONDOWN:
      mbuttondown := true;
    WM_MBUTTONUP:
      mbuttondown := false;
    WM_RBUTTONDOWN:
      rbuttondown := true;
    WM_RBUTTONUP:
      rbuttondown := false;
    WM_DESTROY:
      begin
        ShowWindow(hWnd, SW_HIDE);
        GameFinished := true;
        PostQuitMessage(0);
      end;
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
  SetForegroundWindow(hMainWnd);

  result := true; // Window handle hWnd is valid.
end;

end.


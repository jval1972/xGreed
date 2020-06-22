(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020 by Jim Valavanis                                     *)
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

unit i_windows;

interface

uses
  g_delphi,
  Windows,
  MMSystem;

var
  hMainWnd: HWND;

function I_MapVirtualKey(const uCode, uMapType: UINT): UINT;

function I_GetKeyState(const nVirtKey: Integer): SHORT;

const
  IMB_ERROR = MB_OK or MB_ICONERROR or MB_APPLMODAL;

function I_MessageBox(hWnd: HWND; lpText, lpCaption: PChar; uType: UINT): Integer;

function I_GetFocus: HWND;

function I_timeKillEvent(const uTimerID: UINT): MMRESULT;

const
  TSE_TIME_PERIODIC = TIME_PERIODIC;

function I_timeSetEvent(const uDelay, uResolution: UINT;
  lpFunction: TFNTimeCallBack; dwUser: DWORD; uFlags: UINT): MMRESULT;

procedure I_PeekAndDisplatch;

procedure I_ClearInterface(var Dest: IInterface);

function I_SetDPIAwareness: boolean;

procedure I_Init;

procedure I_ShutDown;

function I_VersionBuilt(fname: string = ''): string;

function I_GetTime: integer;

function clock: LongWord;

var
  basedefault: string;
  stdoutfile: string;
  cdr_drivenum: integer;

implementation

uses
  SysUtils,
  d_ints,
  d_misc;

function I_MapVirtualKey(const uCode, uMapType: UINT): UINT;
begin
  result := MapVirtualKey(uCode, uMapType);
end;

function I_GetKeyState(const nVirtKey: Integer): SHORT;
begin
  result := GetKeyState(nVirtKey);
end;

function I_MessageBox(hWnd: HWND; lpText, lpCaption: PChar; uType: UINT): Integer;
begin
  result := MessageBox(hWnd, lpText, lpCaption, uType);
end;

function I_GetFocus: HWND;
begin
  result := GetFocus;
end;

function I_timeKillEvent(const uTimerID: UINT): MMRESULT;
begin
  result := timeKillEvent(uTimerID);
end;

function I_timeSetEvent(const uDelay, uResolution: UINT;
  lpFunction: TFNTimeCallBack; dwUser: DWORD; uFlags: UINT): MMRESULT;
begin
  result := timeSetEvent(uDelay, uResolution, lpFunction, dwUser, uFlags);
end;

procedure I_PeekAndDisplatch;
var
  msg: TMsg;
begin
  if PeekMessage(msg, 0, 0, 0, PM_REMOVE) then
    DispatchMessage(msg);
end;

procedure I_ClearInterface(var Dest: IInterface);
var
  P: Pointer;
begin
  if Dest <> nil then
  begin
    P := Pointer(Dest);
    Pointer(Dest) := nil;
    IInterface(P)._Release;
  end;
end;

type
  dpiproc_t = function: BOOL; stdcall;
  dpiproc2_t = function(value: integer): HRESULT; stdcall;

function I_SetDPIAwareness: boolean;
var
  dpifunc: dpiproc_t;
  dpifunc2: dpiproc2_t;
  dllinst: THandle;
begin
  result := false;

  dllinst := LoadLibrary('Shcore.dll');
  if dllinst <> 0 then
  begin
    dpifunc2 := GetProcAddress(dllinst, 'SetProcessDpiAwareness');
    if assigned(dpifunc2) then
    begin
      result := dpifunc2(2) = S_OK;
      if not result then
        result := dpifunc2(1) = S_OK;
    end;
    FreeLibrary(dllinst);
    exit;
  end;

  dllinst := LoadLibrary('user32');
  dpifunc := GetProcAddress(dllinst, 'SetProcessDPIAware');
  if assigned(dpifunc) then
    result := dpifunc;
  FreeLibrary(dllinst);
end;

var
  fout: file;

procedure I_OutProc(const s: string);
var
  i: integer;
begin
  for i := 1 to Length(s) do
    BlockWrite(fout, s[i], 1);
end;

procedure I_Init;
var
  c: char;
  drv: array[0..3] of char;
begin
  basedefault := ExtractFilePath(ExpandFileName(ParamStr(0)));
  if basedefault <> '' then
    if basedefault[Length(basedefault)] <> '\' then
      basedefault := basedefault + '\';
  stdoutfile := basedefault + APPNAME + '_stdout.txt';
  assignfile(fout, stdoutfile);
  rewrite(fout, 1);
  outproc := I_OutProc;

  cdr_drivenum := -1;
  drv[1] := ':';
  drv[2] := '\';
  drv[3] := #0;
  for c := 'A' to 'Z' do
  begin
    drv[0] := c;
    if GetDriveType(drv) = DRIVE_CDROM then
    begin
      cdr_drivenum := Ord(c) - Ord('A');
      break;
    end;
  end;
end;

procedure I_ShutDown;
begin
  close(fout);
end;

function I_VersionBuilt(fname: string = ''): string;
var
  vsize: LongWord;
  zero: LongWord;
  buffer: PByteArray;
  res: pointer;
  len: LongWord;
  i: integer;
begin
  if fname = '' then
    fname := ParamStr(0);
  vsize := GetFileVersionInfoSize(PChar(fname), zero);
  if vsize = 0 then
  begin
    result := '';
    exit;
  end;

  buffer := PByteArray(malloc(vsize + 1));
  GetFileVersionInfo(PChar(fname), 0, vsize, buffer);
  VerQueryValue(buffer, '\StringFileInfo\040904E4\FileVersion', res, len);
  result := '';
  for i := 0 to len - 1 do
  begin
    if PChar(res)^ = #0 then
      break;
    result := result + PChar(res)^;
    res := pointer(integer(res) + 1);
  end;
  memfree(pointer(buffer));
end;

//
// I_GetTime
// returns time in 1/70th second tics
//
var
  basetime: int64 = 0;
  Freq: int64;

function I_GetSysTime: extended;
var
  _time: int64;
begin
  if Freq = 1000 then
    _time := GetTickCount
  else
  begin
    if not QueryPerformanceCounter(_time) then
    begin
      Freq := 1000;
      _time := GetTickCount;
      basetime := _time;
      printf('I_GetSysTime(): QueryPerformanceCounter() failed, basetime reset.'#13#10);
    end;
  end;
  if basetime = 0 then
    basetime := _time;
  result := (_time - basetime) / Freq;
end;

function I_GetTime: integer;
begin
  result := trunc(I_GetSysTime * TICRATE);
end;

const
  CLOCKS_PER_SEC = 1000000;

function clock: LongWord;
begin
//  result := trunc(I_GetSysTime * CLOCKS_PER_SEC);
  result := gametic;
end;

initialization

  if not QueryPerformanceFrequency(Freq) then
    Freq := 1000;

end.

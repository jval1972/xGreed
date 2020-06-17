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
  Windows, MMSystem;

var
  Window_Handle: HWND;

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

function clock: LongWord;

implementation

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

function clock: LongWord;
begin
  result := GetTickCount;
end;

end.

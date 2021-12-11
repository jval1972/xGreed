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

unit m_screenshot;

interface

var
  doscreenshot: boolean = false;

procedure SaveScreenShot;

implementation

uses
  SysUtils,
  g_delphi,
  i_video,
  i_windows,
  r_public_h,
  pngimage;

procedure Save_24_Bit_PNG(const filename: string; const buf: PByteArray; const W, H: integer);
var
  png: TPngObject;
  r, c: integer;
  lpng, lsrc: PByteArray;
begin
  png := TPngObject.CreateBlank(COLOR_RGB, 8, W, H);
  try
    for r := 0 to H - 1 do
    begin
      lpng := png.Scanline[r];
      lsrc := @buf[r * W * 4];
      for c := 0 to W - 1 do
      begin
        lpng[c * 3] := lsrc[c * 4];
        lpng[c * 3 + 1] := lsrc[c * 4 + 1];
        lpng[c * 3 + 2] := lsrc[c * 4 + 2];
      end;
    end;
    png.SaveToFile(filename);
  finally
    png.Free;
  end;
end;

procedure SaveScreenShot;
var
  imgname: string;
  src: PByteArray;
  dir: string;
begin
  DateTimeToString(imgname, 'yyyymmdd_hhnnsszzz', Now);
  dir := basedefault + 'ScreenShots\';
  MkDir(dir);
  imgname := dir + imgname + '.png';
  src := malloc(RENDER_VIEW_WIDTH * RENDER_VIEW_HEIGHT * SizeOf(LongWord));
  I_ReadScreen32(src);
  Save_24_Bit_PNG(imgname, src, RENDER_VIEW_WIDTH, RENDER_VIEW_HEIGHT);
  memfree(pointer(src));
  doscreenshot := false;
end;

end.

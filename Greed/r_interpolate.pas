(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020-2021 by Jim Valavanis                                *)
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

unit r_interpolate;

interface

procedure InterpolateSprites;

procedure RestoreInterpolateSprites;

var
  interpolate: boolean = true;
  isintepolating: boolean = false;

implementation

uses
  d_ints,
  protos_h,
  raven,
  r_conten,
  r_public_h,
  r_public;

function InterpolationCalcInt(const prev, next: integer; const frac: integer): integer;
begin
  if next = prev then
    result := prev
  else
    result := prev + round((next - prev) / FRACUNIT * frac);
end;

function InterpolationCalcAngle(const prev, next: integer; const frac: integer): integer;
var
  prev_e, next_e, mid_e: Extended;
begin
  if prev = next then
    result := prev
  else
  begin
    if ((prev < NORTH) and (next > SOUTH)) or
       ((next < NORTH) and (prev > SOUTH)) then
    begin
      prev_e := prev / (ANGLES + 1);
      next_e := next / (ANGLES + 1);
      if prev > next then
        next_e := next_e + 1.0
      else
        prev_e := prev_e + 1.0;

      mid_e := prev_e + (next_e - prev_e) / FRACUNIT * frac;
      if mid_e > 1.0 then
        mid_e := mid_e - 1.0;
      result := Round(mid_e * (ANGLES + 1)) and ANGLES;
    end
    else if prev > next then
    begin
      result := (prev - round((prev - next) / FRACUNIT * frac)) and ANGLES;
    end
    else
    begin
      result := (prev + round((next - prev) / FRACUNIT * frac)) and ANGLES;
    end;
  end;
end;

procedure InterpolateSprites;
var
  spr: Pscaleobj_t;
  frac: integer;
  typ: integer;
begin
  if not interpolate then
    exit;

  isintepolating := true;

  frac := FRACUNIT - (spritemovetime - timecount) * (FRACUNIT div 8);
  if frac <= 0 then
    frac := 0;
  if frac >= FRACUNIT then
    exit;
  spr := firstscaleobj.next;
  while spr <> @lastscaleobj do
  begin
    typ := spr.typ;
    if not (typ in [S_MONSTER1, S_MONSTER1_NS, S_MONSTER2, S_MONSTER2_NS, S_MONSTER3,
      S_MONSTER3_NS, S_MONSTER5, S_MONSTER5_NS, S_MONSTER4, S_MONSTER4_NS, S_MONSTER6,
      S_MONSTER6_NS, S_MONSTER7, S_MONSTER7_NS, S_MONSTER8, S_MONSTER8_NS, S_MONSTER9,
      S_MONSTER9_NS, S_MONSTER10, S_MONSTER10_NS, S_MONSTER11, S_MONSTER11_NS, S_MONSTER12,
      S_MONSTER12_NS, S_MONSTER13, S_MONSTER13_NS, S_MONSTER14, S_MONSTER14_NS, S_MONSTER15,
      S_MONSTER15_NS]) then
    begin
      spr.x := InterpolationCalcInt(spr.oldx, spr.newx, frac);
      spr.y := InterpolationCalcInt(spr.oldy, spr.newy, frac);
      if (typ = S_BLOODSPLAT) and spr.grounded then
        spr.z := RF_GetFloorZ(spr.x, spr.y)
      else if (spr.oldfloorz >= spr.oldz) and (spr.newfloorz >= spr.newz) then
        spr.z := RF_GetFloorZ(spr.x, spr.y)
      else
        spr.z := InterpolationCalcInt(spr.oldz, spr.newz, frac);
      spr.angle := InterpolationCalcAngle(spr.oldangle, spr.newangle, frac);
    end;
    spr := spr.next;
  end;
end;

procedure RestoreInterpolateSprites;
var
  spr: Pscaleobj_t;
  typ: integer;
begin
  spr := firstscaleobj.next;
  while spr <> @lastscaleobj do
  begin
    typ := spr.typ;
    if not (typ in [S_MONSTER1, S_MONSTER1_NS, S_MONSTER2, S_MONSTER2_NS, S_MONSTER3,
      S_MONSTER3_NS, S_MONSTER5, S_MONSTER5_NS, S_MONSTER4, S_MONSTER4_NS, S_MONSTER6,
      S_MONSTER6_NS, S_MONSTER7, S_MONSTER7_NS, S_MONSTER8, S_MONSTER8_NS, S_MONSTER9,
      S_MONSTER9_NS, S_MONSTER10, S_MONSTER10_NS, S_MONSTER11, S_MONSTER11_NS, S_MONSTER12,
      S_MONSTER12_NS, S_MONSTER13, S_MONSTER13_NS, S_MONSTER14, S_MONSTER14_NS, S_MONSTER15,
      S_MONSTER15_NS]) then
    begin
      spr.x := spr.newx;
      spr.y := spr.newy;
      spr.z := spr.newz;
      spr.angle := spr.newangle;
    end;
    spr := spr.next;
  end;
  isintepolating := false;
end;

end.

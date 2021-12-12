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

unit m_defs;

interface

uses
  d_ints,
  d_ints_h,
  i_video,
  modplay,
  protos_h;

type
  ttype_t = (tString, tBoolean, tInteger);

  default_t = record
    name: string;
    location: pointer;
    defaultsvalue: string;
    defaultivalue: integer;
    _type: ttype_t;
  end;

var
  gameepisode: integer = 1;

const
  NUMDEFAULTS = 34;

  defaults: array[0..NUMDEFAULTS - 1] of default_t = (

    (name: 'ambientlight';
     location: @SC.ambientlight;
     defaultivalue: AMBIENTLIGHT;
     _type: tInteger),

    (name: 'violence';
     location: @SC.violence;
     defaultivalue: 1;
     _type: tBoolean),

    (name: 'animation';
     location: @SC.animation;
     defaultivalue: 1;
     _type: tBoolean),

    (name: 'musicvol';
     location: @SC.musicvol;
     defaultivalue: 100;
     _type: tInteger),

    (name: 'sfxvol';
     location: @SC.sfxvol;
     defaultivalue: 128;
     _type: tInteger),

    (name: 'bt_north';
     location: @scanbuttons[bt_north];
     defaultivalue: SC_UPARROW;
     _type: tInteger),

    (name: 'bt_east';
     location: @scanbuttons[bt_east];
     defaultivalue: SC_RIGHTARROW;
     _type: tInteger),

    (name: 'bt_south';
     location: @scanbuttons[bt_south];
     defaultivalue: SC_DOWNARROW;
     _type: tInteger),

    (name: 'bt_west';
     location: @scanbuttons[bt_west];
     defaultivalue: SC_LEFTARROW;
     _type: tInteger),

    (name: 'bt_fire';
     location: @scanbuttons[bt_fire];
     defaultivalue: SC_CONTROL;
     _type: tInteger),

    (name: 'bt_straf';
     location: @scanbuttons[bt_straf];
     defaultivalue: SC_ALT;
     _type: tInteger),

    (name: 'bt_use';
     location: @scanbuttons[bt_use];
     defaultivalue: SC_SPACE;
     _type: tInteger),

    (name: 'bt_run';
     location: @scanbuttons[bt_run];
     defaultivalue: SC_LSHIFT;
     _type: tInteger),

    (name: 'bt_jump';
     location: @scanbuttons[bt_jump];
     defaultivalue: SC_Z;
     _type: tInteger),

    (name: 'bt_useitem';
     location: @scanbuttons[bt_useitem];
     defaultivalue: SC_X;
     _type: tInteger),

    (name: 'bt_asscam';
     location: @scanbuttons[bt_asscam];
     defaultivalue: SC_A;
     _type: tInteger),

    (name: 'bt_lookup';
     location: @scanbuttons[bt_lookup];
     defaultivalue: SC_PGUP;
     _type: tInteger),

    (name: 'bt_lookdown';
     location: @scanbuttons[bt_lookdown];
     defaultivalue: SC_PGDN;
     _type: tInteger),

    (name: 'bt_centerview';
     location: @scanbuttons[bt_centerview];
     defaultivalue: SC_HOME;
     _type: tInteger),

    (name: 'bt_slideleft';
     location: @scanbuttons[bt_slideleft];
     defaultivalue: SC_COMMA;
     _type: tInteger),

    (name: 'bt_slideright';
     location: @scanbuttons[bt_slideright];
     defaultivalue: SC_PERIOD;
     _type: tInteger),

    (name: 'bt_invleft';
     location: @scanbuttons[bt_invleft];
     defaultivalue: SC_INSERT;
     _type: tInteger),

    (name: 'bt_invright';
     location: @scanbuttons[bt_invright];
     defaultivalue: SC_DELETE;
     _type: tInteger),

    (name: 'bt_motionmode';
     location: @scanbuttons[bt_motionmode];
     defaultivalue: SC_S;
     _type: tInteger),

    (name: 'gameepisode';
     location: @gameepisode;
     defaultivalue: 1;
     _type: tInteger),

    (name: 'screensize';
     location: @SC.screensize;
     defaultivalue: 4;
     _type: tInteger),

    (name: 'camdelay';
     location: @SC.camdelay;
     defaultivalue: 35;
     _type: tInteger),

    (name: 'vid_pillarbox_pct';
     location: @vid_pillarbox_pct;
     defaultivalue: 17;
     _type: tInteger),

    (name: 'mouse';
     location: @SC.mouse;
     defaultivalue: 1;
     _type: tBoolean),

    (name: 'mousesensitivity';
     location: @SC.mousesensitivity;
     defaultivalue: 10;
     _type: tInteger),

    (name: 'mousesensitivityx';
     location: @mousesensitivityx;
     defaultivalue: 10;
     _type: tInteger),

    (name: 'mousesensitivityy';
     location: @mousesensitivityy;
     defaultivalue: 5;
     _type: tInteger),

    (name: 'invertmouseturn';
     location: @invertmouseturn;
     defaultivalue: 0;
     _type: tBoolean),

    (name: 'invertmouselook';
     location: @invertmouselook;
     defaultivalue: 0;
     _type: tBoolean)

  );


procedure M_SaveDefaults;

function M_LoadDefaults: boolean;

implementation

uses
  Classes,
  g_delphi,
  constant,
  d_misc;

var
  basedefault: string = APPNAME + '.ini';
  defaultfile: string;

procedure M_SaveDefaults;
var
  i: integer;
  s: TStringList;
begin
  if GAME2 then
    gameepisode := 2
  else if GAME3 then
    gameepisode := 3
  else
    gameepisode := 1;

  s := TStringList.Create;
  try
    for i := 0 to NUMDEFAULTS - 1 do
      if defaults[i]._type = tInteger then
        s.Add(defaults[i].name + '=' + itoa(PInteger(defaults[i].location)^))
      else if defaults[i]._type = tBoolean then
      begin
        if PInteger(defaults[i].location)^ <> 0 then
          s.Add(defaults[i].name + '=1')
        else
          s.Add(defaults[i].name + '=0');
      end
      else if defaults[i]._type = tString then
        s.Add(defaults[i].name + '=' + PString(defaults[i].location)^);

    s.SaveToFile(defaultfile);

  finally
    s.Free;
  end;
end;

function M_LoadDefaults: boolean;
var
  i: integer;
  j: integer;
  idx: integer;
  s: TStringList;
  n, v: string;
begin
  // set everything to base values
  for i := 0 to NUMDEFAULTS - 1 do
    if defaults[i]._type = tInteger then
      PInteger(defaults[i].location)^ := defaults[i].defaultivalue
    else if defaults[i]._type = tBoolean then
    begin
      if defaults[i].defaultivalue <> 0 then
        PBoolean(defaults[i].location)^ := true
      else
        PBoolean(defaults[i].location)^ := false;
    end
    else if defaults[i]._type = tString then
      PString(defaults[i].location)^ := defaults[i].defaultsvalue;

  // check for a custom default file
  i := MS_CheckParm ('config');
  if (i > 0) and (i < my_argc) then
  begin
    defaultfile := my_argv(i + 1);
    printf(' default file: %s' + #13#10, [defaultfile]);
  end
  else
    defaultfile := basedefault;

  s := TStringList.Create;
  try
    // read the file in, overriding any set defaults
    if fexists(defaultfile) then
      s.LoadFromFile(defaultfile);

    for i := 0 to s.Count - 1 do
    begin
      idx := -1;
      n := s.Names[i];
      for j := 0 to NUMDEFAULTS - 1 do
        if defaults[j].name = n then
        begin
          idx := j;
          Break;
        end;

      if idx > -1 then
      begin
        v := s.Values[n];
        if defaults[idx]._type = tInteger then
        begin
          if v <> '' then
            PInteger(defaults[idx].location)^ := atoi(v)
        end
        else if defaults[idx]._type = tBoolean then
        begin
          PBoolean(defaults[idx].location)^ := (v <> '0') and (v <> '');
        end
        else if defaults[idx]._type = tString then
          PString(defaults[idx].location)^ := v;
      end;
    end;

    Result := s.Count > 0;

  finally
    s.Free;
  end;

  if gameepisode = 2 then
  begin
    GAME1 := false;
    GAME2 := true;
    GAME3 := false;
  end
  else if gameepisode = 3 then
  begin
    GAME1 := false;
    GAME2 := false;
    GAME3 := true;
  end
  else
  begin
    GAME1 := true;
    GAME2 := false;
    GAME3 := false;
  end;
end;

end.

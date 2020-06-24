(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020 by Jim Valavanis                                     *)
(*                                                                         *)
(***************************************************************************)
(*                                                                         *)
(* Raven 3D Engine                                                         *)
(* Copyright (C) 1996 by Softdisk Publishing                               *)
(*                                                                         *)
(* Original Design:                                                        *)
(*  John Carmack of id Software                                            *)
(*                                                                         *)
(* Enhancements by:                                                        *)
(*  Robert Morgan of Channel 7............................Main Engine Code *)
(*  Todd Lewis of Softdisk Publishing......Tools,Utilities,Special Effects *)
(*  John Bianca of Softdisk Publishing..............Low-level Optimization *)
(*  Carlos Hasan..........................................Music/Sound Code *)
(*                                                                         *)
(***************************************************************************)
(*                                                                         *)
(* Copyright 1996 by Robert Morgan of Channel 7                            *)
(* Sound Interface                                                         *)
(*                                                                         *)
(***************************************************************************)

{$I xGreed.inc}

unit modplay;

interface

uses
  protos_h,
  r_public_h;

const
  MAXEFFECTS = 8;
//  NUMTRACKS = effecttracks;
  MAXCACHESIZE = MAXEFFECTS * 2 + 4;
  MAXSOUNDS = 90;
  MAXSOUNDDIST = 384;
  MSD = MAXSOUNDDIST * FRACUNIT;
  DEFAULTVRDIST = 157286;
  DEFAULTVRANGLE = 4;

var
  MusicPresent, MusicSwapChannels: boolean;
  SC: SoundCard;
  MusicError, EffectChan, CurrentChan, FXLump: integer;
  effecttracks: integer;

function SaveSetup(const SC: PSoundCard; const Filename: string): integer;

procedure PlaySong(const sname: string; const pattern: integer);

procedure StopMusic;

procedure InitSound;

procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);

procedure SetVolumes(const amusic: integer; const afx: integer);

procedure UpdateSound;

implementation

uses
  g_delphi,
  d_ints_h,
  d_ints,
  bass,
  intro,
  i_windows,
  raven;

function LoadSetup(const SC: PSoundCard; const Filename: string): integer;
var
  f: file;
begin
  if not fopen(f, FileName, fOpenReadOnly) then
  begin
    result := 1;
    exit;
  end;
  if not fread(SC, SizeOf(SoundCard), 1, f) then
  begin
    close(f);
    result := 1;
    exit;
  end;

  close(f);
  result := 0;
end;


function SaveSetup(const SC: PSoundCard; const Filename: string): integer;
var
  f: file;
begin
  if not fopen(f, FileName, fCreate) then
  begin
    result := 1;
    exit;
  end;

  if not fwrite(SC, SizeOf(SoundCard), 1, f) then
  begin
    close(f);
    result := 1;
    exit;
  end;

  close(f);
  result := 0;
end;

var
  MUSIC_HANDLE: DWORD;

procedure StopMusic;
var
  i: integer;
  oldvol: integer;
begin
  if MusicError <> 0 then
    exit;
  if MUSIC_HANDLE <> 0 then
  begin
    oldvol := SC.MusicVol;
    if not netmode then
    begin
      i := oldvol;
      while i > 0 do  // fade out
      begin
        SetVolumes(i, SC.sfxvol);
        Wait(1);
        dec(i, 3);
      end;
    end;
    StopMusic;
    SetVolumes(oldvol, SC.sfxvol);
  end;
end;


procedure InitSound;
begin
  MusicPresent := false;

  // load config file
  if LoadSetup(@SC, 'SETUP.CFG') <> 0 then
  begin
    printf('Sound: SETUP.CFG not found'#13#10);
    printf('       Setting default values'#13#10);

    SC.ambientlight := 2048;      // load all defaults
    SC.violence := true;
    SC.animation := true;
    SC.musicvol := 100;
    SC.sfxvol := 128;
    SC.ckeys[0] := scanbuttons[bt_run];
    SC.ckeys[1] := scanbuttons[bt_jump];
    SC.ckeys[2] := scanbuttons[bt_straf];
    SC.ckeys[3] := scanbuttons[bt_fire];
    SC.ckeys[4] := scanbuttons[bt_use];
    SC.ckeys[5] := scanbuttons[bt_useitem];
    SC.ckeys[6] := scanbuttons[bt_asscam];
    SC.ckeys[7] := scanbuttons[bt_lookup];
    SC.ckeys[8] := scanbuttons[bt_lookdown];
    SC.ckeys[9] := scanbuttons[bt_centerview];
    SC.ckeys[10] := scanbuttons[bt_slideleft];
    SC.ckeys[11] := scanbuttons[bt_slideright];
    SC.ckeys[12] := scanbuttons[bt_invleft];
    SC.ckeys[13] := scanbuttons[bt_invright];
    SC.inversepan := false;
    SC.screensize := 0;
    SC.camdelay := 35;
    SC.effecttracks := 4;
    SC.mouse := 1;
    SC.joystick := 0;

    SC.chartype := 0;
    SC.socket := 1234;
    SC.numplayers := 2;
    SC.serplayers := 1;
    SC.com := 1;
    SC.rightbutton := bt_north;
    SC.leftbutton := bt_fire;
    SC.joybut1 := bt_fire;
    SC.joybut2 := bt_straf;
    SC.dialnum := '            ';
    SC.netname := '            ';
    SC.netmap := 22;
    SC.netdifficulty := 2;
    SC.mousesensitivity := 32;
    SC.turnspeed := 8;
    SC.turnaccel := 2;

    SC.vrhelmet := 0;
    SC.vrangle := DEFAULTVRANGLE;
    SC.vrdist := DEFAULTVRDIST;

    lighting := 1;
    changelight := SC.ambientlight;

  end;

  MusicError := 0;
  if not BASS_Init(-1, 44100, 0, hMainWnd, nil) then
  begin
    printf('Can''t initialize music device'#13#19);
    MusicError := 1;
  end;
  if BASS_GetVersion shr 16 <> BASSVERSION then
  begin
    printf('An incorrect version of BASS.DLL was loaded, needs version %d'#13#10, [BASSVERSION]);
    MusicError := BASS_ERROR_VERSION;
  end
  else
    printf('Success'#13#10);

  MusicSwapChannels := SC.inversepan;

  scanbuttons[bt_run] := SC.ckeys[0];
  scanbuttons[bt_jump] := SC.ckeys[1];
  scanbuttons[bt_straf] := SC.ckeys[2];
  scanbuttons[bt_fire] := SC.ckeys[3];
  scanbuttons[bt_use] := SC.ckeys[4];
  scanbuttons[bt_useitem] := SC.ckeys[5];
  scanbuttons[bt_asscam] := SC.ckeys[6];
  scanbuttons[bt_lookup] := SC.ckeys[7];
  scanbuttons[bt_lookdown] := SC.ckeys[8];
  scanbuttons[bt_centerview] := SC.ckeys[9];
  scanbuttons[bt_slideleft] := SC.ckeys[10];
  scanbuttons[bt_slideright] := SC.ckeys[11];
  scanbuttons[bt_invleft] := SC.ckeys[12];
  scanbuttons[bt_invright] := SC.ckeys[13];

  lighting := 1;
  changelight := SC.ambientlight;
  playerturnspeed := SC.turnspeed;
  turnunit := SC.turnaccel;

  effecttracks := SC.effecttracks;
end;

procedure PlaySong(const sname: string; const pattern: integer);
begin
  MUSIC_HANDLE := BASS_MusicLoad(False, PChar(sname), 0, 0, BASS_MUSIC_POSRESET, 1);
  if MUSIC_HANDLE <> 0 then
  begin
    BASS_ChannelSetAttribute(MUSIC_HANDLE, BASS_ATTRIB_VOL, SC.MusicVol / 255);
    BASS_ChannelPlay(MUSIC_HANDLE, true);
  end;
end;

procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
begin
end;

procedure StaticSoundEffect(const n: integer; const x, y: fixed_t);
begin
end;


procedure UpdateSound;
begin
end;


procedure SetVolumes(const amusic: integer; const afx: integer);
var
  music, fx: integer;
begin
  if MusicError <> 0 then
    exit;
  music := amusic;
  if music > 255 then
    music := 255;
  fx := afx;
  if fx > 255 then
    fx := 255;
  BASS_ChannelSetAttribute(MUSIC_HANDLE, BASS_ATTRIB_VOL, SC.MusicVol / 255);
//  BASS_ChannelSetAttribute(BASS_ATTRIB_VOL, BASS_ATTRIB_VOL, SC.MusicVol / 255);
//  BASS_SetVolume(music / 255);
  SC.musicvol := music;
  SC.sfxvol := fx;
end;

end.

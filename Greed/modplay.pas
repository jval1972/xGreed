(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020-2021 by Jim Valavanis                                *)
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

procedure PlaySong(const aname: string; const pattern: integer);

procedure StopMusic;

procedure InitSound;

procedure I_ShutDownSound;

procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);

procedure SetVolumes(const amusic: integer; const afx: integer);

procedure UpdateSound;

implementation

uses
  SysUtils,
  constant,
  g_delphi,
  d_disk,
  d_ints_h,
  d_ints,
  d_misc,
  m_defs,
  bass,
  intro,
  i_windows,
  raven,
  r_public,
  r_render;

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
    SetVolumes(oldvol, SC.sfxvol);
    BASS_ChannelStop(MUSIC_HANDLE);
    MUSIC_HANDLE := 0;
  end;
end;


procedure InitSound;
begin
  MusicPresent := false;

  SC.ambientlight := AMBIENTLIGHT;      // load all defaults
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
  SC.screensize := 4;
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
  SC.turnspeed := DEF_PLAYERTURNSPEED;
  SC.turnaccel := DEF_TURNUNIT;
  SC.mousesensitivity := 10;

  SC.vrhelmet := 0;
  SC.vrangle := DEFAULTVRANGLE;
  SC.vrdist := DEFAULTVRDIST;

  lighting := 1;
  changelight := SC.ambientlight;

  // load config file
  if not M_LoadDefaults then
    printf('LoadDefaults: Default file not found, using defaults'#13#10);

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

  FXLump := CA_GetNamedNum('SOUNDEFFECTS') + 1;
  if FXLump <= 0 then
    MS_Error('InitSound: SOUNDEFFECTS lump not found in BLO file.');

  MusicSwapChannels := SC.inversepan;

  lighting := 1;
  changelight := SC.ambientlight;
  playerturnspeed := SC.turnspeed;
  turnunit := SC.turnaccel;

  effecttracks := SC.effecttracks;
end;

procedure I_ShutDownSound;
begin
  BASS_Stop;
  BASS_Free;
end;

procedure FindMusicFile(var fname: string);
var
  stmp: string;
  test: string;
begin
  stmp := ExtractFileName(fname);
  test := basedefault + stmp;
  if fexists(test) then
  begin
    fname := test;
    exit;
  end;

  test := basedefault + 'MUSIC\' + stmp;
  if fexists(test) then
  begin
    fname := test;
    exit;
  end;

  test := Chr(cdr_drivenum + Ord('A')) + ':\GREED\MUSIC\' + stmp;
  if fexists(test) then
  begin
    fname := test;
    exit;
  end;

  test := Chr(cdr_drivenum + Ord('A')) + ':\GREED\' + stmp;
  if fexists(test) then
  begin
    fname := test;
    exit;
  end;

  test := Chr(cdr_drivenum + Ord('A')) + ':\GREED2\MUSIC\' + stmp;
  if fexists(test) then
  begin
    fname := test;
    exit;
  end;

  test := Chr(cdr_drivenum + Ord('A')) + ':\GREED2\' + stmp;
  if fexists(test) then
  begin
    fname := test;
    exit;
  end;

  test := Chr(cdr_drivenum + Ord('A')) + ':\GREED3\MUSIC\' + stmp;
  if fexists(test) then
  begin
    fname := test;
    exit;
  end;

  test := Chr(cdr_drivenum + Ord('A')) + ':\GREED3\' + stmp;
  if fexists(test) then
  begin
    fname := test;
    exit;
  end;

end;

procedure PlaySong(const aname: string; const pattern: integer);
var
  sname: string;
begin
  StopMusic;
  sname := aname;
  if not fexists(sname) then
    FindMusicFile(sname);
  MUSIC_HANDLE := BASS_MusicLoad(False, PChar(sname), 0, 0, BASS_MUSIC_POSRESET, 1);
  if MUSIC_HANDLE <> 0 then
  begin
    BASS_ChannelSetAttribute(MUSIC_HANDLE, BASS_ATTRIB_VOL, SC.MusicVol / 255);
    BASS_ChannelPlay(MUSIC_HANDLE, true);
  end;
end;

const
  MAXSFXCHANNELS = 64;

type
  channel_t = record
    channel: DWORD;
    sample: DWORD;
    samplerate: integer;
    lump: integer;
    x, y: fixed_t;
  end;
  Pchannel_t = ^channel_t;

var
  channels: array[0..MAXSFXCHANNELS - 1] of channel_t;

procedure CheckChannels;
var
  i: integer;
  active: DWORD;
begin
  for i := 0 to MAXSFXCHANNELS - 1 do
    if channels[i].channel <> 0 then
    begin
      active := BASS_ChannelIsActive(channels[i].channel);
      if active = BASS_ACTIVE_STOPPED then
      begin
        BASS_SampleFree(channels[i].channel);
        BASS_MusicFree(channels[i].channel);
        channels[i].channel := 0;
      end;
    end;
end;

function GetSoundChannel: integer;
var
  i: integer;
begin
  for i := 0 to MAXSFXCHANNELS - 1 do
    if channels[i].channel = 0 then
    begin
      result := i;
      exit;
    end;
  result := -1;
end;

procedure UpdateChannelParams(const ch: integer);
var
  d, asin, acos: integer;
  dx, dy: integer;
begin
  acos := costable[player.angle];
  asin := sintable[player.angle]; // compute left,right pan value
  dx := channels[ch].x - player.x;
  dy := channels[ch].y - player.y;
  d := FIXEDMUL(dx, acos) + FIXEDMUL(dy, asin);
  d := FIXEDDIV(d, MSD) * $40;
  d := d div FRACUNIT;
  if d < -64 then
    d := -64
  else if d > 64 then
    d := 64;
  BASS_ChannelSetAttribute(channels[ch].channel, BASS_ATTRIB_PAN, d / 64);
  dx := dx div FRACTILEUNIT;  // don't play if too far
  dy := dy div FRACTILEUNIT;
  d := dx * dx + dy * dy;
  if d > MAXSOUNDDIST then
    d := MAXSOUNDDIST;
  BASS_ChannelSetAttribute(channels[ch].channel, BASS_ATTRIB_VOL, (MAXSOUNDDIST - d) / MAXSOUNDDIST);
end;

procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
var
  x1, y1, z: integer;
  ch: integer;
  data: pointer;
  datalen: integer;
  lump: integer;
begin
  x1 := (x - player.x) div FRACTILEUNIT;  // don't play if too far
  y1 := (y - player.y) div FRACTILEUNIT;
  z := x1 * x1 + y1 * y1;
  if z >= MAXSOUNDDIST then
    exit;

  ch := GetSoundChannel;
  if ch <= 0 then
  begin
    CheckChannels;
    ch := GetSoundChannel;
  end;
  if ch = -1 then
    exit;

  lump := FXLump + n;
  data := CA_CacheLump(lump);
  if data = nil then
    exit;

  datalen := CA_LumpLen(lump);
  if datalen <= 0 then
    exit;

  channels[ch].sample := BASS_SampleLoad(true, data, 0, datalen, 1,  {BASS_SAMPLE_3D or}
      BASS_SAMPLE_MONO {$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});
  channels[ch].channel := BASS_SampleGetChannel(channels[ch].sample, false); // initialize sample channel
  channels[ch].x := x;
  channels[ch].y := y;
  channels[ch].lump := lump;
  BASS_ChannelSetAttribute(channels[ch].channel, BASS_ATTRIB_VOL, SC.sfxvol / 255);
  BASS_ChannelPlay(channels[ch].channel, false);
  UpdateChannelParams(ch);
end;

procedure UpdateSound;
var
  i: integer;
begin
  CheckChannels;
  for i := 0 to MAXSFXCHANNELS - 1 do
    if channels[i].channel <> 0 then
      UpdateChannelParams(i);
  BASS_ChannelSetAttribute(MUSIC_HANDLE, BASS_ATTRIB_VOL, SC.MusicVol / 255);
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
  SC.musicvol := music;
  SC.sfxvol := fx;
  BASS_ChannelSetAttribute(MUSIC_HANDLE, BASS_ATTRIB_VOL, SC.MusicVol / 255);
end;

end.


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
(*                                                                         *)
(***************************************************************************)

{$I xGreed.inc}

unit menu;

interface

uses
  g_delphi,
  d_video;

type
  cursor_t = record
    x, y: integer;
    w, h: integer;
  end;
  Pcursor_t = ^cursor_t;

const
  KBDELAY2 = 10;
  MENUS = 6;
  MAXSAVEGAMES = 10;

const
  cursors: array[0..MENUS - 1, 0..14] of cursor_t  = (
  (
  // main menu
   (x: 41; y: 114; w: 55; h: 20),   // new
   (x: 41; y: 138; w: 55; h: 20),   // quit
   (x: 134; y: 42; w: 127; h: 19),  // load
   (x: 134; y: 62; w: 127; h: 19),  // save
   (x: 134; y: 82; w: 127; h: 19),  // options
   (x: 134; y: 102; w: 127; h: 19), // info
   (x: 142; y: 142; w: 62; h: 15),  // quit/resume
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0)
  ),
  (
  // char menu
   (x: 41; y: 138; w: 55; h: 20),   // quit
   (x: 134; y: 32; w: 127; h: 18),  // cyborg
   (x: 134; y: 51; w: 127; h: 18),  // lizard
   (x: 134; y: 70; w: 127; h: 18),  // moo
   (x: 134; y: 89; w: 127; h: 18),  // specimen
   (x: 134; y: 108; w: 127; h: 18), // dominatrix
   (x: 142; y: 142; w: 62; h: 15),  // back
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0)
  ),
  (
  // load
   (x: 41; y: 138; w: 55; h: 20),   // quit
   (x: 137; y: 34; w: 7; h: 5),
   (x: 137; y: 44; w: 7; h: 5),
   (x: 137; y: 54; w: 7; h: 5),
   (x: 137; y: 64; w: 7; h: 5),
   (x: 137; y: 74; w: 7; h: 5),
   (x: 137; y: 84; w: 7; h: 5),
   (x: 137; y: 94; w: 7; h: 5),
   (x: 137; y: 104; w: 7; h: 5),
   (x: 137; y: 114; w: 7; h: 5),
   (x: 137; y: 124; w: 7; h: 5),
   (x: 142; y: 142; w: 62; h: 15),  // back
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0)
  ),
  (
  // save
   (x: 41; y: 138; w: 55; h: 20),   // quit
   (x: 137; y: 34; w: 7; h: 5),
   (x: 137; y: 44; w: 7; h: 5),
   (x: 137; y: 54; w: 7; h: 5),
   (x: 137; y: 64; w: 7; h: 5),
   (x: 137; y: 74; w: 7; h: 5),
   (x: 137; y: 84; w: 7; h: 5),
   (x: 137; y: 94; w: 7; h: 5),
   (x: 137; y: 104; w: 7; h: 5),
   (x: 137; y: 114; w: 7; h: 5),
   (x: 137; y: 124; w: 7; h: 5),
   (x: 142; y: 142; w: 62; h: 15),  // back
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0)
  ),
  (
  // options
   (x: 41; y: 114; w: 55; h: 20),
   (x: 41; y: 138; w: 55; h: 20),
   (x: 134; y: 32; w: 127; h: 15),
   (x: 134; y: 46; w: 127; h: 15),
   (x: 134; y: 60; w: 127; h: 15),
   (x: 134; y: 74; w: 127; h: 15),
   (x: 134; y: 88; w: 127; h: 15),
   (x: 134; y: 101; w: 127; h: 15),
   (x: 134; y: 115; w: 127; h: 15),
   (x: 142; y: 142; w: 62; h: 15),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0)
  ),
  (
  // monster menu
   (x: 41; y: 138; w: 55; h: 20),   // quit
   (x: 134; y: 30; w: 127; h: 15),  // difficulty level 0
   (x: 134; y: 45; w: 127; h: 15),
   (x: 134; y: 60; w: 127; h: 15),
   (x: 134; y: 75; w: 127; h: 15),
   (x: 134; y: 90; w: 127; h: 15),
   (x: 134; y: 117; w: 127; h: 15),
   (x: 142; y: 142; w: 62; h: 15),  // back
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0),
   (x: 0; y: 0; w: 0; h: 0)
  )
  );


const
  menumax: array[0..MENUS - 1] of integer = ( // max cursor
    7, 7, 12, 12, 10, 8
  );

var
  menuscreen: Ppic_t;
  menulevel: integer;
  menucursor: integer;
  menucurloc: integer;
  menumaincursor: integer;
  identity: integer;
  waitanim: integer;
  saveposition: integer;
  menutimedelay: integer;
  quitmenu, menuexecute, downlevel, goright, goleft, waiting: boolean;
  savedir: array[0..MAXSAVEGAMES - 1] of string[22];
  waitpics: array[0..3] of Ppic_t;

procedure ShowMenu(const n: integer);

procedure ShowHelp;

function ShowQuit(const kbdfunction: PProcedure): boolean;

procedure ShowPause;

procedure UpdateWait;

procedure StartWait;

procedure EndWait;

implementation

uses
  constant,
  d_disk,
  d_font,
  d_ints,
  d_ints_h,
  d_misc,
  protos_h,
  i_video,
  intro,
  m_defs,
  modplay,
  net,
  raven,
  r_render,
  utils;

(**** FUNCTIONS ****)

// Draws a formatted image to the screen, masked with zero
procedure VI_DrawMaskedPic2(x, y: integer; const pic: Ppic_t; const backbuffer: PByteArray = nil);
var
  dest: PByte;
  source, source2: PByteArray;
  width, height, xcor: integer;
  backb: PByteArray;
begin
  if backbuffer = nil then
    backb := @viewbuffer
  else
    backb := backbuffer;
  x := x - pic.orgx;
  y := y - pic.orgy;
  height := pic.height;
  source := @pic.data;
  while y < 0 do
  begin
    source := @source[pic.width];
    dec(height);
    inc(y);
  end;
  while height > 0 do
  begin
    if y < 200 then
    begin
      dest := @ylookup[y][x];
      source2 := @backb[y * 320 + x];
      xcor := x;
      width := pic.width;
      while width > 0 do
      begin
        if (xcor >= 0) and (xcor <= 319) and (source[0] <> 0) then
          dest^ := source[0]
        else
          dest^ := source2[0];
        inc(xcor);
        source := @source[1];
        source2 := @source2[1];
        inc(dest);
        dec(width);
      end;
    end;
    inc(y);
    dec(height);
  end;
end;

function ShowQuit(const kbdfunction: PProcedure): boolean;
var
  animtime, droptime: integer;
  anim, y, i, lump: integer;
  mx, my: smallint;
  pics: array[0..2] of Ppic_t;
  c: char;
  pscreen: PByteArray;
begin
  INT_TimerHook(nil);
  pscreen := malloc(64000);
  if pscreen = nil then
    MS_Error('Error allocating ShowQuit buffer');
  MouseHide;
  memcpy(pscreen, @viewbuffer, 64000);
  MouseShow;
  if netmode then
    TimeUpdate;
  lump := CA_GetNamedNum('quit');
  for i := 0 to 2 do
    pics[i] := CA_CacheLump(lump + i);
  menutimedelay := timecount + KBDELAY2;
  Wait(KBDELAY2, 1);
  if netmode then
    TimeUpdate;
  newascii := false;
  anim := 0;
  MouseHide;
  if not SC.animation or netmode then
  begin
    y := 68;
    MouseShow;
  end
  else
    y := -66;
  droptime := timecount;
  animtime := timecount;
  c := #0;
  while true do
  begin
    Wait(1, 1);
    if (y >= 67) and MouseGetClick(mx, my) and (my >= 110) and (my <= 117) then
    begin
      if (mx >= 130) and (mx <= 153) then
      begin
        c := 'y';
        break;
      end
      else if (mx >= 162) and (mx <= 186) then
      begin
        c := 'n';
        break;
      end;
    end;

    if netmode then
      TimeUpdate;

    if newascii and (y >= 67) then
    begin
      c := lastascii;
      break;
    end;
    if (timecount >= droptime) and (y < 67) then
    begin
      if y >= 0 then
        memcpy(@viewbuffer[320 * y], @pscreen[320 * y], 640);
      y := y + 2;
      droptime := timecount + 1;
      VI_DrawMaskedPic2(111, y, pics[anim], pscreen);
      if y >= 67 then
        MouseShow;
    end;
    if timecount >= animtime then
    begin
      inc(anim);
      anim := anim mod 3;
      animtime := animtime + 10;
      MouseHide;
      VI_DrawMaskedPic2(111, y, pics[anim], pscreen);
      MouseShow;
    end;
  end;

  result := (c = 'y') or (c = 'Y');
  droptime := timecount;
  animtime := timecount;
  if not SC.animation or netmode then
    y := 200;
  MouseHide;
  while y < 199 do
  begin
    Wait(1, 1);
    if timecount >= droptime then
    begin
      if y >= 0 then
        memcpy(@viewbuffer[320 * y], @pscreen[320 * y], 640);
      y := y + 2;
      droptime := timecount + 1;
      VI_DrawMaskedPic2(111, y, pics[anim], pscreen);
    end;
    if timecount >= animtime then
    begin
      inc(anim);
      anim := anim mod 3;
      animtime := animtime + 10;
      VI_DrawMaskedPic2(111, y, pics[anim], pscreen);
    end;
  end;
  memcpy(screen, @viewbuffer, 64000);
  memcpy(@viewbuffer, pscreen, 64000);
  for i := 0 to 2 do
    CA_FreeLump(lump + i);
  MouseShow;
  memfree(pointer(pscreen));
  menutimedelay := timecount + KBDELAY2;
  turnrate := 0;
  moverate := 0;
  fallrate := 0;
  strafrate := 0;
  ResetMouse;
  INT_TimerHook(kbdfunction);
  if netmode then
    TimeUpdate;
end;


(******************************************************************************)


procedure ShowMenuSliders(const value, range: integer);
var
  a, c, d, i: integer;
begin
  MouseHide;
  d := (value * 49) div range;
  for a := 0 to d - 1 do
  begin
    c := (a * 32) div d + 140;
    for i := 49 to 64 do
      ylookup[i][a + 42] := c;
  end;
  if d < 49 then
    for a := d to 48 do
    begin
      for i := 49 to 64 do
        ylookup[i][a + 42] := approx_zero;
    end;
  MouseShow;
end;


function _SAVEDIR: string;
begin
  if GAME1 then
    result := 'SAVE1.DIR'
  else if GAME2 then
    result := 'SAVE2.DIR'
  else if GAME3 then
    result := 'SAVE3.DIR'
  else
    result := 'SAVEGAME.DIR';
end;

procedure SaveDirectory;
var
  f: file;
  dd: string;
begin
  dd := _SAVEDIR;
  if not fopen(f, dd, fCreate) then
    MS_Error('SaveDirectory(): Error creating ' + dd);
  if not fwrite(@savedir, SizeOf(savedir), 1, f) then
    MS_Error('SaveDirectory(): Error saving ' + dd);
  fclose(f);
end;


procedure InitSaveDir;
var
  i: integer;
begin
  for i := 0 to MAXSAVEGAMES - 1 do
    savedir[i] := '';
  SaveDirectory;
end;


procedure ShowSaveDir;
var
  f: file;
  i, j: integer;
  dd: string;
begin
  dd := _SAVEDIR;

  if not fopen(f, dd, fOpenReadOnly) then
    InitSaveDir
  else
  begin
    if not fread(@savedir, SizeOf(savedir), 1, f) then
      MS_Error('ShowSaveDir(): Savegame directory read failure!');
    fclose(f);
  end;
  fontbasecolor := 93;
  font := font1;
  MouseHide;
  for i := 0 to MAXSAVEGAMES - 1 do
  begin
    printx := 148;
    printy := 34 + i * 10;
    for j := 0 to 5 do
      memset(@ylookup[printy + j][printx], approx_zero, 110);
    FN_Print(savedir[i]);
  end;
  MouseShow;
end;


procedure MenuShowOptions;
begin
  MouseHide;
  case menucursor of
  2: // music vol
    begin
      VI_DrawPicSolid(35, 29, CA_CacheLump(CA_GetNamedNum('menumussli')));
      ShowMenuSliders(SC.musicvol, 256);
    end;

  3: // sound vol
    begin
      VI_DrawPicSolid(35, 29, CA_CacheLump(CA_GetNamedNum('menusousli')));
      ShowMenuSliders(SC.sfxvol, 256);
    end;

  4: // violence
    begin
      if SC.violence then
        VI_DrawPicSolid(35, 29, CA_CacheLump(CA_GetNamedNum('menuvioon')))
      else
        VI_DrawPicSolid(35, 29, CA_CacheLump(CA_GetNamedNum('menuviooff')));
    end;

  5: // animation
    begin
      if SC.animation then
        VI_DrawPicSolid(35, 29, CA_CacheLump(CA_GetNamedNum('menuanion')))
      else
        VI_DrawPicSolid(35, 29, CA_CacheLump(CA_GetNamedNum('menuanioff')));
    end;

  6: // ambient light
    begin
      VI_DrawPicSolid(35, 29, CA_CacheLump(CA_GetNamedNum('menuambsli')));
      ShowMenuSliders(SC.ambientlight, 4096);
    end;

  7: // screen size
    begin
      VI_DrawPicSolid(35, 29, CA_CacheLump(CA_GetNamedNum('menuscrsli')));
      ShowMenuSliders(MAXVIEWSIZE - SC.screensize - 1, MAXVIEWSIZE - 1);
    end;

  8: // asscam
    begin
      VI_DrawPicSolid(35, 29, CA_CacheLump(CA_GetNamedNum('menucamsli')));
      ShowMenuSliders(SC.camdelay, 70);
    end;
  end;
  MouseShow;
end;


procedure MenuLeft;
begin
  if menulevel = 4 then
  begin
    MouseHide;
    case menucursor of
    2:
      begin
        if SC.musicvol <> 0 then
        begin
          SC.musicvol := SC.musicvol - 4;
          if SC.musicvol < 0 then
            SC.musicvol := 0;
          SetVolumes(SC.musicvol, SC.sfxvol);
          ShowMenuSliders(SC.musicvol, 255);
        end;
      end;

    3:
      begin
        if SC.sfxvol <> 0 then
        begin
          SC.sfxvol := SC.sfxvol - 4;
          if SC.sfxvol < 0 then
            SC.sfxvol := 0;
          SetVolumes(SC.musicvol, SC.sfxvol);
          ShowMenuSliders(SC.sfxvol, 255);
        end;
      end;

    4: // violence
      begin
        SC.violence := true;
        MenuShowOptions;
      end;

    5: // animation
      begin
        SC.animation := true;
        MenuShowOptions;
      end;

    6: // ambient
      begin
        if SC.ambientlight <> 0 then
        begin
          SC.ambientlight := SC.ambientlight - 64;
          if SC.ambientlight < 0 then
            SC.ambientlight := 0;
          ShowMenuSliders(SC.ambientlight, 4096);
          changelight := SC.ambientlight;
          lighting := 1;
        end;
      end;

    7: // screensize
      begin
        if SC.screensize < MAXVIEWSIZE - 1 then
        begin
          inc(SC.screensize);
          ShowMenuSliders(MAXVIEWSIZE - SC.screensize - 1, MAXVIEWSIZE - 1);
          menutimedelay := timecount + KBDELAY2;
          goleft := false;
        end;
      end;

    8: // camera delay
      begin
        if SC.camdelay <> 0 then
        begin
          dec(SC.camdelay);
          ShowMenuSliders(SC.camdelay, 70);
        end;
      end;
    end;
    MouseShow;
  end;
end;


procedure MenuRight;
begin
  if menulevel = 4 then
  begin
    MouseHide;
    case menucursor of
    2:
      begin
        if SC.musicvol < 255 then
        begin
          SC.musicvol := SC.musicvol + 4;
          if SC.musicvol > 255 then
            SC.musicvol := 255;
          SetVolumes(SC.musicvol, SC.sfxvol);
          ShowMenuSliders(SC.musicvol, 255);
        end;
      end;

    3:
      begin
        if SC.sfxvol < 255 then
        begin
          SC.sfxvol := SC.sfxvol + 4;
          if SC.sfxvol > 255 then
            SC.sfxvol := 255;
          SetVolumes(SC.musicvol,SC.sfxvol);
          ShowMenuSliders(SC.sfxvol, 255);
        end;
      end;

    4: // violence
      begin
        SC.violence := false;
        MenuShowOptions;
      end;

    5: // animation
      begin
        SC.animation := false;
        MenuShowOptions;
      end;

    6: // ambient
      begin
        if SC.ambientlight < 4096 then
        begin
          SC.ambientlight := SC.ambientlight + 64;
          if SC.ambientlight > 4096 then
            SC.ambientlight := 4096;
          ShowMenuSliders(SC.ambientlight, 4096);
          changelight := SC.ambientlight;
          lighting := 1;
        end;
      end;

    7: // screensize
      begin
        if SC.screensize <> 0 then
        begin
          dec(SC.screensize);
          ShowMenuSliders(MAXVIEWSIZE - SC.screensize - 1, MAXVIEWSIZE - 1);
          menutimedelay := timecount + KBDELAY2;
          goright := false;
        end;
      end;

    8: // camera delay
      begin
        if SC.camdelay < 70 then
        begin
          inc(SC.camdelay);
          ShowMenuSliders(SC.camdelay, 70);
        end;
      end;
    end;
    MouseShow;
  end;
end;


procedure MenuCommand;
var
  x, y, w, h, i: integer;
begin
  if (keyboard[SC_ESCAPE] = 1) and (timecount > menutimedelay) then
  begin
    eat_key(SC_ESCAPE);
    downlevel := true;
    menutimedelay := timecount + KBDELAY2;
  end;

  if (keyboard[SC_UPARROW] <> 0) and (timecount > menutimedelay) then
  begin
    dec(menucursor);
    if menucursor < 0 then
      menucursor := menumax[menulevel] - 1;
    menutimedelay := timecount + KBDELAY2;
  end
  else if (keyboard[SC_DOWNARROW] <> 0) and (timecount > menutimedelay) then
  begin
    inc(menucursor);
    if menucursor = menumax[menulevel] then
      menucursor := 0;
    menutimedelay := timecount + KBDELAY2;
  end;

  if (keyboard[SC_RIGHTARROW] <> 0) and (timecount > menutimedelay) then
    goright := true
  else if (keyboard[SC_LEFTARROW] <> 0) and (timecount > menutimedelay) then
    goleft := true;

  if (keyboard[SC_ENTER] <> 0) and (timecount > menutimedelay) then
  begin
    menuexecute := true;
    menutimedelay := timecount + KBDELAY2;
  end;

  if menuusemouse then
    for i := 0 to 14 do
    begin
      x := cursors[menulevel][i].x;
      y := cursors[menulevel][i].y;
      w := cursors[menulevel][i].w;
      h := cursors[menulevel][i].h;
      if (mousehx > x) and (mousehx < x + w) and (mousehy > y) and (mousehy < y + h) then
      begin
        menucursor := i;
        break;
      end;
    end;
end;


procedure MenuShowCursor(const menucursor: integer);
var
  x, y, w, h, i: integer;
begin
  if (menucursor = -1) or (menucursor = menucurloc) then
    exit;
  MouseHide;
  VI_DrawMaskedPic(20, 15, CA_CacheLump(CA_GetNamedNum('menumain') + menulevel));
  menucurloc := menucursor;
  x := cursors[menulevel][menucurloc].x;
  y := cursors[menulevel][menucurloc].y;
  w := cursors[menulevel][menucurloc].w;
  h := cursors[menulevel][menucurloc].h;
  memset(@ylookup[y][x], 133, w);
  memset(@ylookup[y + h - 1][x], 133, w);
  for i := y to y + h - 1 do
  begin
    ylookup[i][x] := 133;
    ylookup[i][x + w - 1] := 133;
  end;
  MouseShow;
  if (menulevel = 2) or (menulevel = 3) then
    ShowSaveDir;
  if menulevel = 4 then
    MenuShowOptions;
end;


procedure ShowMenuLevel(const level: integer);
begin
  if menulevel = 0 then
    menumaincursor := menucursor;
  menulevel := level;
  MouseHide;
  VI_DrawMaskedPic(20, 15, CA_CacheLump(CA_GetNamedNum('menumain') + level));
  MouseShow;

  if menulevel = 0 then
    menucursor := menumaincursor
  else if menulevel = 1 then
    menucursor := 1
  else if (menulevel = 2) or (menulevel = 3) then
  begin
    if saveposition > 0 then
      menucursor := saveposition
    else
      menucursor := 1;
  end
  else
    menucursor := 2;

  menucurloc := -1;
  MenuShowCursor(menucursor);
end;


procedure GetSavedName(const menucursor: integer);
var
  done: boolean;
  cursor, i: integer;
begin
  MouseHide;
  cursor := MinI(Length(savedir[menucursor]), 20);
  savedir[menucursor] := savedir[menucursor] + '_';
  done := false;
  INT_TimerHook(nil);
  lastascii := #0;
  newascii := false;
  while not done do
  begin
    printx := 148;
    printy := 34 + menucursor * 10;
    for i := 0 to 5 do
      memset(@ylookup[printy + i][printx], approx_zero, 100);
    FN_Print(savedir[menucursor]);
    while not newascii do   // wait for a new key
    begin
      Wait(1, 1);
      MenuShowCursor(menucursor + 1);
    end;

    case Ord(lastascii) of
    13,
    27:
      done := true;

    8:
      begin
        if Length(savedir[menucursor]) > 0 then
          dec(savedir[menucursor][0]);
        if Length(savedir[menucursor]) > 0 then
          dec(savedir[menucursor][0]);
        savedir[menucursor] := savedir[menucursor] + '_';
        dec(cursor);
      end;

    else
      if isalnum(lastascii) or (lastascii in [' ', '.', '-', '!', ',', '?', '''']) then
      begin
        if Length(savedir[menucursor]) = 0 then
          savedir[menucursor] := lastascii
        else if savedir[menucursor][Length(savedir[menucursor])] = '_' then
          savedir[menucursor][Length(savedir[menucursor])] := lastascii
        else
          savedir[menucursor] := savedir[menucursor] + lastascii;
        if cursor < 19 then
          inc(cursor);
        savedir[menucursor] := savedir[menucursor] + '_';
      end;
    end;
    newascii := false;
  end;

  if Length(savedir[menucursor]) > 0 then
    if savedir[menucursor][Length(savedir[menucursor])] = '_' then
      dec(savedir[menucursor][0]);
  if lastascii = #27 then
    ShowSaveDir
  else
  begin
    downlevel := true;
    SaveDirectory;
    SaveGame(menucursor);
  end;
  menutimedelay := timecount + KBDELAY2;
  INT_TimerHook(MenuCommand);
  MouseShow;
end;


procedure ShowHelp;
var
  s: PByteArray;
  f: file;
begin
  s := malloc(64000);
  if s = nil then
    MS_Error('Error Allocating in ShowHelp');
  memcpy(s, screen, 64000);
  VI_FillPalette(0, 0, 0);
  memset(screen, 0, 64000);

  if ASSASSINATOR then
  begin
    if not fopen(f, 'help.dat', fOpenReadOnly) then
      MS_Error('Error Loading Help.Dat file');
    fread(screen, 64000, 1,f);
    fread(@colors, 768, 1,f);
    fclose(f);
  end
  else
    loadscreen('INFO1');
  I_SetPalette(@colors);
  newascii := false;
  while true do
  begin
    Wait(10, 1);
    if netmode then
      TimeUpdate;
    if newascii then
      break;
  end;
  VI_FillPalette(0, 0, 0);
  memset(screen, 0, 64000);

  if DEMO then
  begin
    loadscreen('INFO2');
    I_SetPalette(@colors);
    newascii := false;
    while true do
    begin
      Wait(10, 1);
      if netmode then
        TimeUpdate;
      if newascii then
        break;
    end;
    VI_FillPalette(0, 0, 0);
    memset(screen, 0, 64000);

    loadscreen('INFO3');
    I_SetPalette(@colors);
    newascii := false;
    while true do
    begin
      Wait(10, 1);
      if netmode then
        TimeUpdate;
      if newascii then
        break;
    end;
    memset(screen, 0, 64000);
    VI_FillPalette(0, 0, 0);
  end;

  I_SetPalette(CA_CachePalette(CA_GetNamedNum('palette')));
  memcpy(screen, s, 64000);
  memfree(pointer(s));
end;

procedure Execute(const level: integer; const cursor: integer);
begin
  case level of
  0: // main menu
    begin
      case cursor of
      0: // new game
        begin
          if not netmode then
            ShowMenuLevel(1);
         end;
      1: // quit
        begin
          if ShowQuit(MenuCommand) then
          begin
            quitgame := true;
            quitmenu := true;
          end;
        end;
      2: // load
        begin
          if not netmode then
            ShowMenuLevel(2);
        end;
      3: // save
        begin
          if not netmode and gameloaded then
            ShowMenuLevel(3);
        end;
      4: // volume menu
        begin
          ShowMenuLevel(4);
        end;
      5: // info
        begin
          INT_TimerHook(nil);
          MouseHide;
          ShowHelp;
          MouseShow;
          INT_TimerHook(MenuCommand);
        end;
      6: // resume
        begin
          quitmenu := true;
        end;
      end;
    end;

  1: // char selection
    begin
      case cursor of
      0: // quit
        begin
          if ShowQuit(MenuCommand) then
          begin
            quitgame := true;
            quitmenu := true;
          end;
        end;
      1,
      2,
      3,
      4,
      5:
        begin
          identity := cursor - 1;
          ShowMenuLevel(5);
        end;
      6: // resume
        begin
          downlevel := true;
        end;
      end;
    end;

  2: // load menu
    begin
      case cursor of
      0: // quit
        begin
          if ShowQuit(MenuCommand) then
          begin
            quitgame := true;
            quitmenu := true;
          end;
        end;
      11: // back
        begin
          downlevel := true;
        end;
      else
        MouseHide;
        LoadGame(menucursor - 1);
        quitmenu := true;
        MouseShow;
        saveposition := cursor;
      end;
    end;

  3: // save menu
    begin
      case cursor of
      0: // quit
        begin
          if ShowQuit(MenuCommand) then
          begin
            quitgame := true;
            quitmenu := true;
          end;
        end;
      11: // back
        begin
          downlevel := true;
        end;
      else
        GetSavedName(menucursor - 1);
        saveposition := cursor;
      end;
    end;

   4: // option menu
    begin
      case cursor of
      0:
        begin
          ShowMenuLevel(1);
        end;
      1:
        begin
          if ShowQuit(MenuCommand) then
          begin
            quitgame := true;
            quitmenu := true;
          end;
        end;
      2, // music vol
      3, // sound vol
      4, // violence
      5, // animations
      6, // ambient light
      7, // screen size
      8:; // camera delay
      9:
        begin
          downlevel := true;
        end;
      end;
    end;

  5: // difficulty selection
    begin
      case cursor of
      0: // quit
        begin
          if ShowQuit(MenuCommand) then
          begin
            quitgame := true;
            quitmenu := true;
          end;
        end;
      1,
      2,
      3,
      4,
      5,
      6:
        begin
          timecount := 0;
          frames := 0;
          MouseHide;
          if GAME1 then
            newplayer(0, identity, 6 - cursor)
          else if GAME2 then
            newplayer(8, identity, 6 - cursor)
          else if GAME3 then
            newplayer(16, identity, 6 - cursor)
          else
            newplayer(0, identity, 6 - cursor);
          MouseShow;
          quitmenu := true;
        end;
      7:
        begin
          ShowMenuLevel(1);
        end;
      end;
    end;
  end;
end;


procedure MenuAnimate;
var
  lump: integer;
  frames: array[0..7] of Ppic_t;
  i, frame: integer;
  waittime: integer;
begin
  if netmode then
    exit;
  memcpy(@viewbuffer, screen, 64000);
  lump := CA_GetNamedNum('menuanim');
  for i := 0 to 7 do
    frames[i] := CA_CacheLump(lump + i);
  frame := -1;
  waittime := timecount;
  while true do
  begin
    Wait(1, 1);
    if timecount >= waittime then
    begin
      inc(frame);
      if frame = 8 then
        break;
      VI_DrawMaskedPic2(20, 15, frames[frame]);
      waittime := waittime + 7;
    end;
  end;
  for i := 0 to 7 do
    CA_FreeLump(lump + i);
end;


procedure CheckMouse;
var
  i: integer;
  x, y: smallint;
  c: Pcursor_t;
begin
  if not MouseGetClick(x, y) then
    exit;

  for i := 0 to menumax[menulevel] - 1 do
  begin
    c := @cursors[menulevel][i];
    if (x < c.x + c.w) and (x > c.x) and
       (y < c.y + c.h) and (y > c.y) then
    begin
      menucursor := i;
      MenuShowCursor(menucursor);
      menuexecute := true;
      exit;
    end;
  end;

  if menulevel = 4 then
  begin
    case menucursor of
    2:
      begin
        if (y >= 49) and (y <= 64) and (x >= 42) and (x <= 90) then
        begin
          SC.musicvol := ((x - 40) * 256) div 49;
          if SC.musicvol > 255 then
            SC.musicvol := 255;
          SetVolumes(SC.musicvol, SC.sfxvol);
          ShowMenuSliders(SC.musicvol, 255);
        end;
      end;

    3:
      begin
        if (y >= 49) and (y <= 64) and (x >= 42) and (x <= 90) then
        begin
          SC.sfxvol := ((x - 40) * 256) div 49;
          if SC.sfxvol > 255 then
            SC.sfxvol := 255;
          SetVolumes(SC.musicvol, SC.sfxvol);
          ShowMenuSliders(SC.sfxvol, 255);
        end;
      end;

    4,
    5:
      begin
        if (y >= 62) and (y <= 70) then
        begin
          if (x >= 50) and (x <= 61) then
            goleft := true
          else if (x >= 72) and (x <= 83) then
            goright := true;
        end;
      end;

    6:
      begin
        if (y >= 49) and (y <= 64) and (x >= 42) and (x <= 90) then
        begin
          SC.ambientlight := ((x - 40) * 4096) div 49;
          if SC.ambientlight > 4096 then
            SC.ambientlight := 4096;
          ShowMenuSliders(SC.ambientlight, 4096);
          changelight := SC.ambientlight;
          lighting := 1;
        end;
      end;

    7:
      begin
        if (y >= 49) and (y <= 64) and (x >= 42) and (x <= 90) then
        begin
          SC.screensize := MAXVIEWSIZE - 1 - (((x - 40) * MAXVIEWSIZE) div 49);
          if SC.screensize > MAXVIEWSIZE - 1 then
            SC.screensize := MAXVIEWSIZE - 1
          else if SC.screensize < 0 then
            SC.screensize := 0;
          ShowMenuSliders(MAXVIEWSIZE - SC.screensize, MAXVIEWSIZE);
        end;
      end;

    8:
      begin
        if (y >= 49) and (y <= 64) and (x >= 42) and (x <= 90) then
        begin
          SC.camdelay := ((x - 40) * 70) div 49;
          if SC.camdelay > 70 then
            SC.camdelay := 70;
          ShowMenuSliders(SC.camdelay, 70);
        end;
      end;
    end;
  end;
end;


procedure ShowMenu(const n: integer);
const
  MENUDELAYTICS = 30;
var
  scr: PByteArray;
  entertime: integer;
begin
  menutimedelay := timecount + KBDELAY2;
  entertime := timecount;
  INT_TimerHook(MenuCommand);

  scr := malloc(64000);
  if scr = nil then
    MS_Error('ShowMenu(): Out of Memory!');
  memcpy(scr, screen, 64000);
  if SC.animation then
    MenuAnimate;
  MouseShow;
  ShowMenuLevel(n);
  quitmenu := false;
  repeat
    Wait(1, 1);
    MenuShowCursor(menucursor);
    CheckMouse;
    if menuexecute then
    begin
      Execute(menulevel, menucursor);
      menuexecute := false;
    end;
    if downlevel then
    begin
      if menulevel = 0 then
      begin
        if timecount > entertime + MENUDELAYTICS then
          quitmenu := true;
      end
      else
        ShowMenuLevel(0);
      downlevel := false;
    end;
    if goright then
    begin
      MenuRight;
      goright := false;
    end;
    if goleft then
    begin
      MenuLeft;
      goleft := false;
    end;
    if netmode then
      TimeUpdate;
  until quitmenu;
  MouseHide;
  memcpy(screen, scr, 64000);
  memfree(pointer(scr));
  if gameloaded then
  begin
    if SC.vrhelmet = 0 then
    begin
      if SC.screensize > MAXVIEWSIZE - 1 then
        SC.screensize := MAXVIEWSIZE - 1
      else if SC.screensize < 0 then
        SC.screensize := 0;
      while currentViewSize < SC.screensize do
        ChangeViewSize(true);
      while currentViewSize > SC.screensize do
        ChangeViewSize(false);
    end;
  end;
  M_SaveDefaults;
  turnrate := 0;
  moverate := 0;
  fallrate := 0;
  strafrate := 0;
  ResetMouse;
end;

//**************************************************************************

function CheckPause: boolean;
begin
  if netmode then
  begin
    NetGetData;
    if not gamepause then
    begin
      result := true;
      exit;
    end;
  end;
  result := newascii;
end;


procedure ShowPause;
var
  animtime, droptime: integer;
  anim, y, i: integer;
  lump: integer;
  pics: array[0..3] of Ppic_t;
  pscreen: PByteArray;
begin
  INT_TimerHook(nil);
  pscreen := malloc(64000);
  memcpy(pscreen, @viewbuffer, 64000);
  if pscreen = nil then
    MS_Error('Error allocating ShowPause buffer');
  lump := CA_GetNamedNum('pause');
  for i := 0 to 3 do
    pics[i] := CA_CacheLump(lump + i);
  menutimedelay := timecount + KBDELAY2;
  Wait(KBDELAY2, 1);
  anim := 0;
  if not SC.animation then
    y := 72
  else
    y := -56;
  droptime := timecount;
  animtime := timecount;
  newascii := false;
  while not CheckPause do
  begin
    Wait(1, 1);
    if (timecount >= droptime) and (y < 72) then
    begin
      if y >= 0 then
        memcpy(@viewbuffer[320 * y], @pscreen[320 * y], 640);
      y := y + 2;
      droptime := timecount + 1;
    end;
    if timecount >= animtime then
    begin
      inc(anim);
      anim := anim and 3;
      animtime := animtime + 10;
    end;
    VI_DrawMaskedPic2(106, y, pics[anim], pscreen);
  end;
  if not SC.animation then
    y := 200;
  droptime := timecount;
  animtime := timecount;
  while y < 199 do
  begin
    Wait(1, 1);
    if timecount >= droptime then
    begin
      if y >= 0 then
        memcpy(@viewbuffer[320 * y], @pscreen[320 * y], 640);
      y := y + 2;
      droptime := timecount + 1;
    end;
    if timecount >= animtime then
    begin
      inc(anim);
      anim := anim and 3;
      animtime := animtime + 10;
    end;
    VI_DrawMaskedPic2(106, y, pics[anim], pscreen);
  end;
  memcpy(@viewbuffer, pscreen, 64000);
  memfree(pointer(pscreen));
  for i := 0 to 3 do
    CA_FreeLump(lump + i);
end;

(*****************************************************************************)

procedure StartWait;
var
  i, lump: integer;
begin
  memcpy(@viewbuffer, screen, 64000);
  lump := CA_GetNamedNum('wait');
  for i := 0 to 3 do
    waitpics[i] := CA_CacheLump(lump + i);
  waitanim := 0;
  VI_DrawMaskedPic2(106, 72, waitpics[0]);
  menutimedelay := timecount + KBDELAY2;
  waiting := true;
end;


procedure UpdateWait;
begin
  if timecount > menutimedelay then
  begin
    inc(waitanim);
    waitanim := waitanim and 3;
    VI_DrawMaskedPic2(106, 72, waitpics[waitanim]);
    menutimedelay := timecount + KBDELAY2;
  end;
end;


procedure EndWait;
var
  lump, i: integer;
begin
  lump := CA_GetNamedNum('wait');
  for i := 0 to 3 do
    CA_FreeLump(lump + i);
  memcpy(screen, @viewbuffer, 64000);
  waiting := false;
end;

end.


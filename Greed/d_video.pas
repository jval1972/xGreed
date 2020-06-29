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
(*                                                                         *)
(***************************************************************************)

{$I xGreed.inc}

unit d_video;

interface

uses
  g_delphi,
  r_public_h,
  Windows;

type
  pic_t = packed record
    width: smallint;
    height: smallint;
    orgx: smallint;
    orgy: smallint;
    data: byte;
  end;
  Ppic_t = ^pic_t;

(**** VARIABLES ****)
var
  screen: PByteArray;
  ylookup: array[0..MAX_VIEW_WIDTH - 1] of PByteArray;
  transparency: PByteArray;
  translookup: array[0..255] of PByteArray;

procedure VI_FillPalette(const red, green, blue: integer);

procedure VI_FadeOut(start, stop: integer; const red, green, blue: integer;
  const steps: integer);

procedure VI_FadeIn(start, stop: integer; const apal: PByteArray;
  const steps: integer);

procedure VI_DrawPic(const x, y: integer; const pic: Ppic_t);

procedure VI_DrawMaskedPic(x, y: integer; const pic: Ppic_t);

procedure VI_DrawTransPicToBuffer(x, y: integer; const pic: Ppic_t);

procedure VI_DrawMaskedPicToBuffer2(x, y: integer; const pic: Ppic_t);

procedure VI_Init;

procedure VI_BlitView;

procedure VI_DrawMaskedPicToBuffer(x, y: integer; const pic: Ppic_t);

implementation

uses
  d_disk,
  d_misc,
  intro,
  i_windows,
  i_video,
  raven,
  r_public,
  r_render;

procedure VI_FillPalette(const red, green, blue: integer);
var
  apal: packed array[0..767] of byte;
  i: integer;
begin
  for i := 0 to 255 do
  begin
    apal[i * 3] := red;
    apal[i * 3 + 1] := green;
    apal[i * 3 + 2] := blue;
  end;
  I_SetPalette(@apal);
end;

procedure VI_FadeOut(start, stop: integer; const red, green, blue: integer;
  const steps: integer);
var
  basep: array[0..767] of byte;
  px, pdx, dx: array[0..767] of smallint;
  i, j: integer;
begin
  I_GetPalette(@basep);
  memset(@dx, 0, 768 * 2);
  for j := start to stop - 1 do
  begin
    pdx[j * 3] := (basep[j * 3] - red) mod steps;
    px[j * 3] := (basep[j * 3] - red) div steps;
    pdx[j * 3 + 1] := (basep[j * 3 + 1] - green) mod steps;
    px[j * 3 + 1] := (basep[j * 3 + 1] - green) div steps;
    pdx[j * 3 + 2] := (basep[j * 3 + 2] - blue) mod steps;
    px[j * 3 + 2] := (basep[j * 3 + 2] - blue) div steps;
  end;
  start := start * 3;
  stop := stop * 3;
  for i := 0 to steps - 1 do
  begin
    for j := start to stop - 1 do
    begin
      basep[j] := basep[j] - px[j];
      dx[j] := dx[j] + pdx[j];
      if dx[j] >= steps then
      begin
        dx[j] := dx[j] - steps;
        dec(basep[j]);
      end
      else if dx[j] <= -steps then
      begin
        dx[j] := dx[j] + steps;
        inc(basep[j]);
      end;
    end;
    Wait(1, 1);
    I_SetPalette(@basep);
  end;
  VI_FillPalette(red, green, blue);
end;


procedure VI_FadeIn(start, stop: integer; const apal: PByteArray;
  const steps: integer);
var
  basep, work: packed array[0..767] of byte;
  px, pdx, dx: packed array[0..767] of shortint;
  i, j: integer;
begin
  I_GetPalette(@basep);
  memset(@dx, 0, 768);
  memset(@work, 0, 768);
  start := start * 3;
  stop := stop * 3;
  for j := start to stop - 1 do
  begin
    pdx[j] := (apal[j] - basep[j]) mod steps;
    px[j] := (apal[j] - basep[j]) div steps;
  end;
  for i := 0 to steps - 1 do
  begin
    for j := start to stop - 1 do
    begin
      work[j] := work[j] + px[j];
      dx[j] := dx[j] + pdx[j];
      if dx[j] >= steps then
      begin
        dx[j] := dx[j] - steps;
        inc(work[j]);
      end
      else if dx[j] <= -steps then
      begin
        dx[j] := dx[j] + steps;
        dec(work[j]);
      end;
    end;
    Wait(1, 1);
    I_SetPalette(@work);
  end;
  I_SetPalette(apal);
end;


procedure VI_DrawPic(const x, y: integer; const pic: Ppic_t);
var
  dest, source: PByteArray;
  width: integer;
  height: integer;
begin
  width := pic.width;
  height := pic.height;
  source := @pic.data;
  dest := @ylookup[y][x];

  while height > 0 do
  begin
    memcpy(dest, source, width);
    dest := @dest[MAX_VIEW_WIDTH];
    source := @source[width];
    dec(height);
  end;
end;


// Draws a formatted image to the screen, masked with zero
procedure VI_DrawMaskedPic(x, y: integer; const pic: Ppic_t);
var
  dest, source: PByteArray;
  width, height, xcor: integer;
begin
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
    dec(height);
    if y < 200 then
    begin
      dest := @ylookup[y][x];
      xcor := x;
      width := pic.width;
      while width > 0 do
      begin
        if (xcor >= 0) and (xcor <= 319) and (source[0] <> 0) then
          dest[0] := source[0];
        inc(xcor);
        source := @source[1];
        dest := @dest[1];
        dec(width);
      end;
    end;
    inc(y);
  end;
end;


// Draws a transpartent, masked pic to the view buffer
procedure VI_DrawTransPicToBuffer(x, y: integer; const pic: Ppic_t);
var
  dest, source: PByteArray;
  width,height: integer;
begin
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
    dec(height);
    if y < 200 then
    begin
      dest := @viewylookup[y][x];
      width := pic.width;
      while width > 0 do
      begin
        if source[0] <> 0 then
          dest[0] := translookup[source[0] - 1][dest[0]];
        source := @source[1];
        dest := @dest[1];
        dec(width);
      end;
    end;
    inc(y);
  end;
end;


// Draws a masked pic to the view buffer
procedure VI_DrawMaskedPicToBuffer2(x, y: integer; const pic: Ppic_t);
var
  dest, source, colormap: PByteArray;
  width, height, maplight: integer;
begin
// x-:= pic.orgx;
// y-:= pic.orgy;
  height := pic.height;
  source := @pic.data;

  colormap := colormaps; // JVAL: Avoid compiler waring
  wallshadow := mapeffects[player.mapspot];
  if wallshadow = 0 then
  begin
    maplight := (maplights[player.mapspot] * 8) + reallight[player.mapspot];
    if maplight < 0 then
      colormap := zcolormap[0]
    else if maplight > MAXZLIGHT then
      colormap := zcolormap[MAXZLIGHT]
    else
      colormap := zcolormap[maplight];
  end
  else if wallshadow = 1 then
    colormap := @colormaps[wallglow * 256]
  else if wallshadow = 2 then
    colormap := @colormaps[wallflicker1 * 256]
  else if wallshadow = 3 then
    colormap := @colormaps[wallflicker2 * 256]
  else if wallshadow = 4 then
    colormap := @colormaps[wallflicker3 * 256]
  else if (wallshadow >= 5) and (wallshadow <= 8) then
  begin
    if (wallcycle = wallshadow - 5) then
      colormap := colormaps
    else
    begin
      maplight := (maplights[player.mapspot] * 8) + reallight[player.mapspot];
      if maplight < 0 then
        colormap := zcolormap[0]
      else if maplight > MAXZLIGHT then
        colormap := zcolormap[MAXZLIGHT]
      else
        colormap := zcolormap[maplight];
    end;
  end
  else if wallshadow = 9 then
  begin
    maplight := (maplights[player.mapspot] * 8) + reallight[player.mapspot] + wallflicker4;
    if maplight < 0 then
      colormap := zcolormap[0]
    else if maplight > MAXZLIGHT then
      colormap := zcolormap[MAXZLIGHT]
    else
      colormap := zcolormap[maplight];
  end;
  if height + y > windowHeight then
    height := windowHeight - y;
  while height > 0 do
  begin
    dec(height);
    dest := @viewylookup[y][x];
    width := pic.width;
    while width > 0 do
    begin
      if source[0] <> 0 then
        dest[0] := colormap[source[0]];
      source := @source[1];
      dest := @dest[1];
      dec(width);
    end;
    inc(y);
  end;
end;


procedure VI_Init;
var
  y: integer;
begin
  screen := @viewbuffer;

  for y := 0 to MAX_VIEW_HEIGHT - 1 do
    ylookup[y] := @screen[y * MAX_VIEW_WIDTH];

  transparency := CA_CacheLump(CA_GetNamedNum('TRANSPARENCY'));

  for y := 0 to 255 do
    translookup[y] := @transparency[256 * y];
end;


procedure VI_BlitView;
begin
  I_FinishUpdate;
end;


// Draws a masked pic to the view buffer
procedure VI_DrawMaskedPicToBuffer(x, y: integer; const pic: Ppic_t);
var
  dest, source: PByteArray;
  width, height, xcor: integer;
begin
  x := x - pic.orgx;
  y := y - pic.orgy;
  height :=  pic.height;
  source := @pic.data;
  while y < 0 do
  begin
    source := @source[pic.width];
    dec(height);
    inc(y);
  end;
  while height > 0 do
  begin
    dec(height);
    if y < 200 then
    begin
      dest := @viewbuffer[(y * MAX_VIEW_WIDTH + x)];
      xcor := x;
      width := pic.width;
      while width > 0 do
      begin
        if (xcor >= 0) and (xcor <= 319) then
        begin
          if source[0] <> 0 then
            dest[0] := source[0];
        end;
        inc(xcor);
        source := @source[1];
        dest := @dest[1];
        dec(width);
      end;
    end;
    inc(y);
  end;
end;

end.


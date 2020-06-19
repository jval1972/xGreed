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
  Windows;

const
  SCREENWIDTH = 320;
  SCREENHEIGHT = 200;

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
  ylookup: array[0..SCREENHEIGHT - 1] of PByteArray;
  transparency: PByteArray;
  translookup: array[0..255] of PByteArray;
  Bitmap: HBITMAP;
  Memory_DC: HDC;
  Palette: HPALETTE;

procedure VI_FillPalette(const red, green, blue: integer);

procedure VI_SetPalette(const apal: PByteArray);

procedure VI_ResetPalette;

procedure VI_GetPalette(const apal: PByteArray);

procedure VI_FadeOut(start, stop: integer; const red, green, blue: integer;
  const steps: integer);

procedure VI_FadeIn(start, stop: integer; const apal: PByteArray;
  const steps: integer);

procedure VI_DrawPic(const x, y: integer; const pic: Ppic_t);

procedure VI_DrawMaskedPic(x, y: integer; const pic: Ppic_t);

procedure VI_DrawTransPicToBuffer(x, y: integer; const pic: Ppic_t);

procedure VI_DrawMaskedPicToBuffer2(x, y: integer; const pic: Ppic_t);

procedure VI_Init(const specialbuffer: integer);

procedure RF_BlitView;

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
  r_public_h,
  r_public,
  r_render;

procedure VI_FillPalette(const red, green, blue: integer);
begin
end;

procedure VI_SetPalette(const apal: PByteArray);
var
  dc: HDC;
  i: integer;
  j: integer;
  entries: array[0..255] of PALETTEENTRY;
begin
  I_SetPalette(apal);
  
  j := 0;

  for i := 0 to 255 do
  begin
    entries[i].peRed := apal[j] shl 2;
    inc(j);
    entries[i].peGreen := apal[j] shl 2;
    inc(j);
    entries[i].peBlue := apal[j] shl 2;
    inc(j);
    entries[i].peFlags := PC_NOCOLLAPSE;
  end;

  dc := GetDC(hMainWnd);

  SetPaletteEntries(Palette, 0, 256, entries);

  VI_BlitView;

  SelectPalette(Memory_DC, Palette, true);
  SelectPalette(dc,Palette, true);

  RealizePalette(Memory_DC);
  RealizePalette(dc);

  ReleaseDC(hMainWnd, dc);
end;


procedure VI_ResetPalette;
var
  dc: HDC;
begin
  dc := GetDC(hMainWnd);

  RealizePalette(dc);

  ReleaseDC(hMainWnd, dc);
end;


procedure VI_GetPalette(const apal: PByteArray);
begin
//  memset(apal, 0, 768);
end;


procedure VI_FadeOut(start, stop: integer; const red, green, blue: integer;
  const steps: integer);
var
  basep: array[0..767] of byte;
  px, pdx, dx: array[0..767] of shortint;
  i, j: integer;
begin
  VI_GetPalette(@basep);
  memset(@dx, 0, 768);
  for j := start to stop - 1 do
  begin
    pdx[j * 3] := (basep[j * 3] - red) mod steps;
    px[j * 3] := (basep[j*3] - red) div steps;
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
    Wait(1);
    VI_SetPalette(@basep);
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
  VI_GetPalette(@basep);
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
    Wait(1);
    VI_SetPalette(@work);
  end;
  VI_SetPalette(apal);
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
    dest := @dest[SCREENWIDTH];
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

  colormap := zcolormap[0]; // JVAL: Avoid compiler waring
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
    colormap := @colormaps[wallglow shl 8]
  else if wallshadow = 2 then
    colormap := @colormaps[wallflicker1 shl 8]
  else if wallshadow = 3 then
    colormap := @colormaps[wallflicker2 shl 8]
  else if wallshadow = 4 then
    colormap := @colormaps[wallflicker3 shl 8]
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


procedure VI_Init(const specialbuffer: integer);
var
  dc: HDC;
  y: integer;
  i: integer;
  j: integer;
  bmi: ^BITMAPINFO;
  pal: ^LOGPALETTE;
  pal_data: PByteArray;
begin
  dc :=  GetDC(hMainWnd);
  Memory_DC :=  CreateCompatibleDC(dc);

  bmi := malloc(SizeOf(BITMAPINFO) + SizeOf(RGBQUAD) * 256);
  memset(bmi, 0, SizeOf(BITMAPINFO) + SizeOf(RGBQUAD) * 256);

  bmi.bmiHeader.biSize := SizeOf(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth := SCREENWIDTH;
  bmi.bmiHeader.biHeight := SCREENHEIGHT;
  bmi.bmiHeader.biPlanes := 1;
  bmi.bmiHeader.biBitCount := 8;
  bmi.bmiHeader.biCompression := BI_RGB;

  for i := 0 to 255 do
  begin
    bmi.bmiColors[i].rgbRed := i;
    bmi.bmiColors[i].rgbGreen := i;
    bmi.bmiColors[i].rgbBlue := i;
    bmi.bmiColors[i].rgbReserved := 0;
  end;

  pal :=  malloc(SizeOf(LOGPALETTE) + 256 * SizeOf(PALETTEENTRY));
  memset(pal,0,SizeOf(LOGPALETTE) + 256 * SizeOf(PALETTEENTRY));

  pal.palVersion := $300;
  pal.palNumEntries := 256;

  pal_data := CA_CacheLump(CA_GetNamedNum('palette'));

  j := 0;
  for i := 0 to 255 do
  begin
    pal.palPalEntry[i].peRed := pal_data[j] * 4;
    inc(j);
    pal.palPalEntry[i].peGreen := pal_data[j] * 4;
    inc(j);
    pal.palPalEntry[i].peBlue := pal_data[j] * 4;
    inc(j);
    pal.palPalEntry[i].peFlags := PC_NOCOLLAPSE;
  end;

  Palette := CreatePalette(pal^);
  SelectPalette(dc,Palette, true);
  SelectPalette(Memory_DC, Palette, true);
  RealizePalette(dc);
  RealizePalette(Memory_DC);

  memfree(pointer(pal));

  Bitmap := CreateDIBSection(Memory_DC, bmi^, DIB_PAL_COLORS, pointer(screen), 0, 0);

  memfree(pointer(bmi));

  SelectObject(Memory_DC, Bitmap);

  ReleaseDC(hMainWnd, dc);

  if screen = nil then
    MS_Error('VI_Init(): Out of memory for screen');

  for y := 0 to SCREENHEIGHT - 1 do
    ylookup[y] := @screen[y * SCREENWIDTH];

  transparency := CA_CacheLump(CA_GetNamedNum('TRANSPARENCY'));

  for y := 0 to 255 do
    translookup[y] := @transparency[256 * y];
end;


procedure RF_BlitView;
var
  i, j: integer;
begin
  i := 0;
  j := SCREENHEIGHT - 1;

  while i < SCREENHEIGHT do
  begin
    memcpy(@ylookup[i], @viewylookup[j], SCREENWIDTH);
    inc(i);
    dec(j);
  end;
end;

var
  yyy: integer;

procedure doit;
var
  f: file;
  i, j: integer;
  c: byte;
  b: byte;
  pal: PByteArray;//array[0..767] of byte;
  lump: integer;
begin
  lump := CA_CheckNamedNum('palette');
  if lump < 0 then
    exit;
  assign(f, 'screenshot' + itoa(yyy) + '.raw');
  pal := CA_CacheLump(lump);
  rewrite(f,1);
  for i := 0 to 199 do
    for j := 0 to 319 do
    begin
      b := viewylookup[i][j];
      c := pal[3 * b] * 4;
      blockwrite(f, c, 1);
      c := pal[3 * b + 1] * 4;
      blockwrite(f, c, 1);
      c := pal[3 * b + 2] * 4;
      blockwrite(f, c, 1);
    end;
  close(f);
  inc(yyy);
end;

procedure VI_BlitView;
var
  dc: HDC;
begin
  I_FinishUpdate;
  exit;
  dc :=  GetDC(hMainWnd);
//  BitBlt(dc, 0, 0, SCREENWIDTH, SCREENHEIGHT, Memory_DC, 0, 0, SRCCOPY);
  StretchBlt(dc, 0, 0, 2 * SCREENWIDTH, 2 * SCREENHEIGHT, Memory_DC, 0, 0, SCREENWIDTH, SCREENHEIGHT, SRCCOPY);
  ReleaseDC(hMainWnd, dc);
//  doit;
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
        dest := @dest[0];
        dec(width);
      end;
    end;
    inc(y);
  end;
end;

end.


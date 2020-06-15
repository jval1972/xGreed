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

procedure VI_SetPalette(const palette: PByteArray);

procedure VI_ResetPalette;

procedure VI_GetPalette(const palette: PByteArray);

procedure VI_FadeOut(const start, stop: integer; const red, green, blue: integer;
  const steps: integer);

procedure VI_FadeIn(const start, stop: integer; const palette: PByteArray;
  const steps: integer);

procedure VI_DrawPic(const x, y: integer; const pic: Ppic_t);

procedure VI_DrawMaskedPic(const x, y: integer; const pic: Ppic_t);

procedure VI_DrawTransPicToBuffer(const x, y: integer; const pic: Ppic_t);

procedure VI_DrawMaskedPicToBuffer2(const x, y: integer; const pic: Ppic_t);

procedure VI_Init(const specialbuffer: integer);

procedure RF_BlitView;

procedure VI_BlitView;

procedure VI_DrawMaskedPicToBuffer(const x, y: integer; const pic: Ppic_t);

implementation

uses
  intro;
  
procedure VI_FillPalette(const red, green, blue: integer);
begin
end;

procedure VI_SetPalette(const palette: PByteArray);
var
  dc: HDC;
  i: integer;
  j: integer;
  entries: array[0..255] of PALETTEENTRY;
begin
  j := 0;

  for i := 0 to 255 do
  begin
    entries[i].peRed := palette[j] shl 2;
    inc(j);
    entries[i].peGreen := palette[j] shl 2;
    inc(j);
    entries[i].peBlue := palette[j] shl 2;
    inc(j);
    entries[i].peFlags := PC_NOCOLLAPSE;
  end;

  dc := GetDC(Window_Handle);

  SetPaletteEntries(Palette, 0, 256, entries);

  VI_BlitView;

  SelectPalette(Memory_DC, Palette, TRUE);
  SelectPalette(dc,Palette, TRUE);

  RealizePalette(Memory_DC);
  RealizePalette(dc);

  ReleaseDC(Window_Handle, dc);
end;


procedure VI_ResetPalette;
var
  dc: HDC;
begin
  dc := GetDC(Window_Handle);

  RealizePalette(dc);

  ReleaseDC(Window_Handle, dc);
end;


procedure VI_GetPalette(const palette: PByteArray);
begin
end;


procedure VI_FadeOut(const start, stop: integer; const red, green, blue: integer;
  const steps: integer);
var
  basep: array[0..767] of byte;
  px, pdx, dx: array[0..767] of shortint;
  i, j: integer;
begin
  VI_GetPalette(basep);
  memset(dx, 0, 768);
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
    VI_SetPalette(basep);
  end;
  VI_FillPalette(red, green, blue);
end;


procedure VI_FadeIn(const start, stop: integer; const palette: PByteArray;
  const steps: integer);
begin
  byte        basep[768], work[768];
  signed char px[768], pdx[768], dx[768];
  i, j: integer;

  VI_GetPalette(basep);
  memset(dx,0,768);
  memset(work,0,768);
  start := start * 3;
  stop := stop * 3;
  for(j := start;j<stop;j++)
  begin
   pdx[j] := (palette[j]-basep[j]) mod steps;
   px[j] := (palette[j]-basep[j])/steps;
    end;
  for (i := 0;i<steps;i++)
  begin
   for (j := start;j<stop;j++)
   begin
     work[j] := work[j] + px[j];
     dx[j] := dx[j] + pdx[j];
     if dx[j] >= steps then
     begin
       dx[j] := dx[j] - steps;
       ++work[j];
     end
     else if dx[j] <= -steps then
     begin
       dx[j] := dx[j] + steps;
       --work[j];
        end;
      end;
   Wait(1);
   VI_SetPalette(work);
    end;
  VI_SetPalette(palette);
  end;


procedure VI_DrawPic(const x, y: integer; const pic: Ppic_t);
begin
  byte *  dest;
  byte *  source;
  width: integer;
  height: integer;

  width :=  pic.width;
  height :=  pic.height;
  source := ) and (pic.data;
  dest :=  ylookup[y] + x;

  while height-- do
  begin
    memcpy(dest,source,width);
    dest := dest + SCREENWIDTH;
    source := source + width;
   end;
  end;


procedure VI_DrawMaskedPic(const x, y: integer; const pic: Ppic_t);
(* Draws a formatted image to the screen, masked with zero *)
begin
  byte *dest, *source;
  width, height, xcor: integer;

  x := x - pic.orgx;
  y := y - pic.orgy;
  height := pic.height;
  source := @pic.data;
  while y<0 do
  begin
   source := source + pic.width;
   height--;
   y++;
    end;
  while height-- do
  begin
   if y<200 then
   begin
     dest := ylookup[y]+x;
     xcor := x;
     width := pic.width;
     while width-- do
     begin
       if (xcor >= 0) and (xcor <= 319) and (*source) *dest := *source;
       xcor++;
       source++;
       dest++;
        end;
      end;
   y++;
    end;
  end;


procedure VI_DrawTransPicToBuffer(const x, y: integer; const pic: Ppic_t);
(* Draws a transpartent, masked pic to the view buffer *)
begin
  byte *dest,*source;
  width,height: integer;

  x := x - pic.orgx;
  y := y - pic.orgy;
  height := pic.height;
  source := @pic.data;
  while y<0 do
  begin
   source := source + pic.width;
   height--;
   y++;
    end;
  while height-.0 do
  begin
   if y<200 then
   begin
     dest := viewylookup[y]+x;
     width := pic.width;
     while width-- do
     begin
       if (*source) *dest := *(translookup[*source-1]+*dest);
       source++;
       dest++;
        end;
      end;
   y++;
    end;
  end;


procedure VI_DrawMaskedPicToBuffer2(const x, y: integer; const pic: Ppic_t);
(* Draws a masked pic to the view buffer *)
begin
  byte *dest, *source, *colormap;
  width, height, maplight: integer;

// x-:= pic.orgx;
// y-:= pic.orgy;
  height := pic.height;
  source := @pic.data;

  wallshadow := mapeffects[player.mapspot];
  if wallshadow = 0 then
  begin
   maplight := ((int)maplights[player.mapspot] shl 3)+reallight[player.mapspot];
   if (maplight<0) colormap := zcolormap[0];
    else if (maplight>MAXZLIGHT) colormap := zcolormap[MAXZLIGHT];
    else colormap := zcolormap[maplight];
  end
  else if (wallshadow = 1) colormap := colormaps+(wallglow shl 8);
  else if (wallshadow = 2) colormap := colormaps+(wallflicker1 shl 8);
  else if (wallshadow = 3) colormap := colormaps+(wallflicker2 shl 8);
  else if (wallshadow = 4) colormap := colormaps+(wallflicker3 shl 8);
  else if (wallshadow >= 5) and (wallshadow <= 8) then
  begin
   if (wallcycle = wallshadow-5) colormap := colormaps;
   else
   begin
     maplight := ((int)maplights[player.mapspot] shl 3)+reallight[player.mapspot];
     if (maplight<0) colormap := zcolormap[0];
      else if (maplight>MAXZLIGHT) colormap := zcolormap[MAXZLIGHT];
      else colormap := zcolormap[maplight];
      end;
  end
  else if wallshadow = 9 then
  begin
   maplight := ((int)maplights[player.mapspot] shl 3)+reallight[player.mapspot]+wallflicker4;
   if (maplight<0) colormap := zcolormap[0];
    else if (maplight>MAXZLIGHT) colormap := zcolormap[MAXZLIGHT];
    else colormap := zcolormap[maplight];
    end;
  if height+y>windowHeight then
  height := windowHeight-y;
  while height-.0 do
  begin
   dest := viewylookup[y]+x;
   width := pic.width;
   while width-- do
   begin
     if (*source) *dest := *(colormap + *(source));
     source++;
     dest++;
      end;
   y++;
    end;
  end;


procedure VI_Init(const specialbuffer: integer);
begin
  HDC        dc;
  y: integer;
  i: integer;
  j: integer;
  BITMAPINFO *  bmi;
  LOGPALETTE *  pal;
  byte *      pal_data;

  dc :=  GetDC(Window_Handle);
  Memory_DC :=  CreateCompatibleDC(dc);

  bmi :=  malloc(SizeOf(BITMAPINFO) + SizeOf(RGBQUAD) * 256);
  memset(bmi,0,SizeOf(BITMAPINFO) + SizeOf(RGBQUAD) * 256);

  bmi.bmiHeader.biSize :=  SizeOf(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth :=  SCREENWIDTH;   
  bmi.bmiHeader.biHeight :=  SCREENHEIGHT;    
  bmi.bmiHeader.biPlanes :=  1;
  bmi.bmiHeader.biBitCount :=  8;
  bmi.bmiHeader.biCompression :=  BI_RGB;  

  for (i :=  0 ; i < 256 ; i++)
  begin
    (WORD)*((WORD*)(bmi.bmiColors) + i) :=  i;
   end;

  pal :=  malloc(SizeOf(LOGPALETTE) + 256 * SizeOf(PALETTEENTRY));
  memset(pal,0,SizeOf(LOGPALETTE) + 256 * SizeOf(PALETTEENTRY));

  pal.palVersion :=  $300;
  pal.palNumEntries :=  256;

  pal_data :=  CA_CacheLump(CA_GetNamedNum('palette'));

  for (i :=  0,j :=  0 ; i < 256 ; i++)
  begin
    pal.palPalEntry[i].peRed :=  pal_data[j++]  shl  2;
    pal.palPalEntry[i].peGreen :=  pal_data[j++]  shl  2;
    pal.palPalEntry[i].peBlue :=  pal_data[j++]  shl  2;
    pal.palPalEntry[i].peFlags :=  PC_NOCOLLAPSE;
   end;

  Palette :=  CreatePalette(pal);
  SelectPalette(dc,Palette,TRUE);
  SelectPalette(Memory_DC,Palette,TRUE);
  RealizePalette(dc);
  RealizePalette(Memory_DC);
  
  free(pal);

  Bitmap :=  CreateDIBSection(
    Memory_DC,
    bmi,
    DIB_PAL_COLORS, 
   ) and (screen,
    NULL,
    0);

  free(bmi);

  SelectObject(Memory_DC,Bitmap);

  ReleaseDC(Window_Handle,dc);

  if screen = NULL then
    MS_Error('VI_Init: Out of memory for screen');

  for (y :=  0 ; y < SCREENHEIGHT ; y++)
    ylookup[y] :=  screen + y * SCREENWIDTH;

  transparency := CA_CacheLump(CA_GetNamedNum('TRANSPARENCY'));

  for(y :=  0 ; y < 255 ; y++)
    translookup[y] :=  transparency + 256 * y;
  end;


procedure RF_BlitView;
begin
  i :=  0: integer;
  j :=  SCREENHEIGHT - 1: integer;

  for (; i < SCREENHEIGHT ; i++,j--)
    memcpy(ylookup[i], viewylookup[j], SCREENWIDTH);
  end;


procedure VI_BlitView;
begin
  HDC dc;

  dc :=  GetDC(Window_Handle);
//  BitBlt(dc,0,0,SCREENWIDTH,SCREENHEIGHT,Memory_DC,0,0,SRCCOPY);
  StretchBlt(dc, 0, 0, 2 * SCREENWIDTH, 2 * SCREENHEIGHT, Memory_DC, 0, 0, SCREENWIDTH, SCREENHEIGHT, SRCCOPY);
  ReleaseDC(Window_Handle,dc);
  end;


procedure VI_DrawMaskedPicToBuffer(const x, y: integer; const pic: Ppic_t);
(* Draws a masked pic to the view buffer *)
begin
  BYTE *  dest;
  BYTE *  source;
  width,height,xcor: integer;

  x := x - pic.orgx;
  y := y - pic.orgy;
  height :=  pic.height;
  source := ) and (pic.data;
  while y<0 do
  begin
    source := source + pic.width;
    height--;
   end;
  while height-- do
  begin
    if y<200 then
    begin
      dest :=  viewbuffer + (y * MAX_VIEW_WIDTH + x);
      xcor :=  x;
      width :=  pic.width;
      while width-- do
      begin
        if ((xcor >= 0)) and ((xcor <= 319)) then
        begin
          if *source then
            *dest :=  *source;
         end;
        xcor++;
        source++;
        dest++;
       end;
     end;
    y++;
   end;
  end;

end.

(***************************************************************************)
(*                                                                         *)
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

#include <STRING.H>
#include <STDLIB.H>
#include <CONIO.H>
#include 'd_global.h'
#include 'd_ints.h'
#include 'd_video.h'
#include 'd_misc.h'
#include 'd_disk.h'
#include 'r_public.h'
#include 'r_refdef.h'

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

(**** CONSTANTS ****)

#define CRTCOFF (inbyte(STATUS_REGISTER_1)) and (1)


(**** VARIABLES ****)

byte *    screen;
byte *    ylookup[SCREENHEIGHT];
byte *    transparency;
byte *    translookup[255];
HBITMAP    Bitmap;
HDC      Memory_DC;
HPALETTE  Palette;

extern SoundCard SC;


(**** FUNCTIONS ****)

procedure VI_FillPalette(int red, int green, int blue);
begin
  end;


procedure VI_SetPalette(byte *palette);
begin
  HDC        dc;
  i: integer;
  j :=  0: integer;
  PALETTEENTRY  entries[256];

  for (i :=  0 ; i < 256 ; i++)
  begin
    entries[i].peRed :=  palette[j++]  shl  2;
    entries[i].peGreen :=  palette[j++]  shl  2;
    entries[i].peBlue :=  palette[j++]  shl  2;
    entries[i].peFlags :=  PC_NOCOLLAPSE;
   end;  
  
  dc :=  GetDC(Window_Handle);

  SetPaletteEntries(Palette,0,256,entries);

  VI_BlitView;

  SelectPalette(Memory_DC,Palette,TRUE);
  SelectPalette(dc,Palette,TRUE);

  RealizePalette(Memory_DC);
  RealizePalette(dc);

  ReleaseDC(Window_Handle,dc);
  end;


void VI_ResetPalette
begin
  HDC  dc;

  dc :=  GetDC(Window_Handle);

  RealizePalette(dc);

  ReleaseDC(Window_Handle,dc);
  end;


procedure VI_GetPalette(byte *palette);
begin
  end;


procedure VI_FadeOut(int start,int end,int red,int green,int blue,int steps);
begin
  byte        basep[768];
  signed char px[768], pdx[768], dx[768];
  i, j: integer;

  VI_GetPalette(basep);
  memset(dx,0,768);
  for(j := start;j<end;j++)
  begin
   pdx[j*3] := (basep[j*3]-red) mod steps;
   px[j*3] := (basep[j*3]-red)/steps;
   pdx[j*3+1] := (basep[j*3+1]-green) mod steps;
   px[j*3+1] := (basep[j*3+1]-green)/steps;
   pdx[j*3+2] := (basep[j*3+2]-blue) mod steps;
   px[j*3+2] := (basep[j*3+2]-blue)/steps;
    end;
  start := start * 3;
  end := end * 3;
  for (i := 0;i<steps;i++)
  begin
   for (j := start;j<end;j++)
   begin
     basep[j] := basep[j] - px[j];
     dx[j] := dx[j] + pdx[j];
     if dx[j] >= steps then
     begin
       dx[j] := dx[j] - steps;
       --basep[j];
     end
     else if dx[j] <= -steps then
     begin
       dx[j] := dx[j] + steps;
       ++basep[j];
        end;
      end;
   Wait(1);
   VI_SetPalette(basep);
    end;
  VI_FillPalette(red,green,blue);
  end;


procedure VI_FadeIn(int start,int end,byte *palette,int steps);
begin
  byte        basep[768], work[768];
  signed char px[768], pdx[768], dx[768];
  i, j: integer;

  VI_GetPalette(basep);
  memset(dx,0,768);
  memset(work,0,768);
  start := start * 3;
  end := end * 3;
  for(j := start;j<end;j++)
  begin
   pdx[j] := (palette[j]-basep[j]) mod steps;
   px[j] := (palette[j]-basep[j])/steps;
    end;
  for (i := 0;i<steps;i++)
  begin
   for (j := start;j<end;j++)
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


procedure VI_DrawPic(int x,int y,pic_t * pic);
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


procedure VI_DrawMaskedPic(int x, int y, pic_t  *pic);
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


procedure VI_DrawTransPicToBuffer(int x,int y,pic_t *pic);
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


procedure VI_DrawMaskedPicToBuffer2(int x,int y,pic_t *pic);
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


procedure VI_Init(int specialbuffer);
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

  bmi :=  malloc(sizeof(BITMAPINFO) + sizeof(RGBQUAD) * 256);
  memset(bmi,0,sizeof(BITMAPINFO) + sizeof(RGBQUAD) * 256);

  bmi.bmiHeader.biSize :=  sizeof(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth :=  SCREENWIDTH;   
  bmi.bmiHeader.biHeight :=  SCREENHEIGHT;    
  bmi.bmiHeader.biPlanes :=  1;
  bmi.bmiHeader.biBitCount :=  8;
  bmi.bmiHeader.biCompression :=  BI_RGB;  

  for (i :=  0 ; i < 256 ; i++)
  begin
    (WORD)*((WORD*)(bmi.bmiColors) + i) :=  i;
   end;

  pal :=  malloc(sizeof(LOGPALETTE) + 256 * sizeof(PALETTEENTRY));
  memset(pal,0,sizeof(LOGPALETTE) + 256 * sizeof(PALETTEENTRY));

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
    memcpy(ylookup[i],viewylookup[j],SCREENWIDTH);
  end;


void VI_BlitView
begin
  HDC dc;

  dc :=  GetDC(Window_Handle);
//  BitBlt(dc,0,0,SCREENWIDTH,SCREENHEIGHT,Memory_DC,0,0,SRCCOPY);
  StretchBlt(dc, 0, 0, 2 * SCREENWIDTH, 2 * SCREENHEIGHT, Memory_DC, 0, 0, SCREENWIDTH, SCREENHEIGHT, SRCCOPY);
  ReleaseDC(Window_Handle,dc);
  end;


procedure VI_DrawMaskedPicToBuffer(int x,int y,pic_t *pic);
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

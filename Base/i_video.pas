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

unit i_video;

interface

uses
  SysUtils,
  g_delphi,
  Windows,
  d_video;

// Called by D_DoomMain,
// determines the hardware configuration
// and sets up the video mode
procedure I_InitGraphics;

procedure I_ChangeFullScreen(const dofull, doexclusive: boolean);

procedure I_ShutDownGraphics;

// Takes full 8 bit values.
procedure I_SetPalette(const palette: PByteArray);

procedure I_FinishUpdate;

procedure I_ReadScreen32(dest: pointer);

procedure I_RestoreWindowPos;

type
  displaymode_t = record
    width, height: integer;
    bpp: integer;
  end;
  displaymode_tArray = array[0..$FF] of displaymode_t;
  Pdisplaymode_tArray = ^displaymode_tArray;

var
  displaymodes: Pdisplaymode_tArray = nil;
  numdisplaymodes: integer = 0;

function I_DisplayModeIndex(const w, h: integer): integer;

function I_NearestDisplayModeIndex(const w, h: integer): integer;

var
  vid_pillarbox_pct: integer;
  vid_letterbox_pct: integer;

const
  PILLARLETTER_MIN = 0;
  PILLARLETTER_MAX = 50;

var
  fullscreen: boolean = true;
  fullscreenexclusive: boolean = false;

var
  usegamma: byte = 0;

implementation

uses
  DirectX,
  d_misc,
  i_windows,
  i_main,
  r_render;

var
  g_pDD: IDirectDraw7 = nil; // DirectDraw object
  g_pDDSPrimary: IDirectDrawSurface7 = nil;// DirectDraw primary surface
  g_pDDScreen: IDirectDrawSurface7 = nil;   // DirectDraw surface

var
  bpp: integer;

var
  s_alttab_disabled: boolean = false;

var
  screen16: PWordArray;
  screen32: PLongWordArray;

var
  XWINDOWWIDTH: integer;
  XWINDOWHEIGHT: integer;

procedure I_RestoreWindowPos;
begin
  SetWindowPos(hMainWnd, HWND_TOP, 0, 0, XWINDOWWIDTH, XWINDOWHEIGHT, SWP_SHOWWINDOW);
end;

procedure I_DisableAltTab;
var
  old: Boolean;
begin
  if s_alttab_disabled then
    Exit;

  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    if isLibrary then
      RegisterHotKey(0, $C000, MOD_ALT, VK_TAB)
    else
      RegisterHotKey(0, 0, MOD_ALT, VK_TAB)
  end
  else
    SystemParametersInfo(SPI_SCREENSAVERRUNNING, 1, @old, 0);

  s_alttab_disabled := true;
end;

procedure I_EnableAltTab;
var
  old: Boolean;
begin
  if s_alttab_disabled then
  begin
    if Win32Platform = VER_PLATFORM_WIN32_NT then
    begin
      if isLibrary then
        UnregisterHotKey(0, $C000)
      else
        UnregisterHotKey(0, 0)
    end
    else
      SystemParametersInfo(SPI_SCREENSAVERRUNNING, 0, @old, 0);

    s_alttab_disabled := false;
  end;
end;

var
  allocscreensize: integer;

procedure I_ShutDownGraphics;
begin
  I_ClearInterface(IInterface(g_pDDScreen));
  I_ClearInterface(IInterface(g_pDDSPrimary));
  I_ClearInterface(IInterface(g_pDD));
  I_EnableAltTab;
  realloc(pointer(displaymodes), 0);
  numdisplaymodes := 0;
  memfree(pointer(screen32));
  if screen16 <> nil then
    memfree(pointer(screen16));
end;

type
  finishupdateparms_t = record
    start, stop: integer;
  end;
  Pfinishupdateparms_t = ^finishupdateparms_t;

var
  curpal: array[0..255] of LongWord;

//
// I_FinishUpdate
//
procedure I_FinishUpdate8(parms: Pfinishupdateparms_t);
var
  destl: PLongWord;
  destw: PWord;
  pixel: LongWord;
  r, g, b: LongWord;
  src: PByte;
  srcstop: PByte;
begin
  src := @(viewbuffer[parms.start]);
  srcstop := @(viewbuffer[parms.stop]);
  if bpp = 32 then
  begin
    destl := @screen32[parms.start];
    while PCAST(src) < PCAST(srcstop) do
    begin
      destl^ := curpal[src^];
      inc(destl);
      inc(src);
    end;
  end
  else if bpp = 16 then
  begin
    destw := @screen16[parms.start];
    while PCAST(src) < PCAST(srcstop) do
    begin
      pixel := curpal[src^];
      r := (pixel shr 19) and 31;
      g := (pixel shr 11) and 31;
      b := (pixel shr 3) and 31;
      destw^ := (r shl 11) or (g shl 6) or b;
      inc(destw);
      inc(src);
    end;
  end;
end;

procedure I_FinishUpdate16;
var
  i: integer;
  destw: PWord;
  pixel: LongWord;
  r, g, b: LongWord;
  srcl: PLongWord;
begin
  destw := @screen16[0];
  srcl := @screen[0];
  for i := 0 to SCREENWIDTH * SCREENHEIGHT - 1 do
  begin
    pixel := srcl^;
    r := (pixel shr 19) and 31;
    g := (pixel shr 11) and 31;
    b := (pixel shr 3) and 31;
    destw^ := (r shl 11) or (g shl 6) or b;
    inc(destw);
    inc(srcl);
  end;
end;

var
  old_pillarbox_pct: integer = -1;
  old_letterbox_pct: integer = -1;
  old_windowwidth: integer = -1;
  old_windowheight: integer = -1;
  old_fullscreen: boolean = false;
  old_fullscreenexclusive: boolean = false;

procedure I_FinishUpdate;
var
  srcrect: TRect;
  destrect: TRect;
  blackrect: TRect;
  oldcolor: LongWord;
  parms1: finishupdateparms_t;
  hpan, vpan: integer;
begin
  if (screen16 = nil) and (screen32 = nil) then
    exit;

  parms1.start := 0;
  parms1.stop := SCREENWIDTH * SCREENHEIGHT - 1;
  I_FinishUpdate8(@parms1);

  vid_pillarbox_pct := ibetween(vid_pillarbox_pct, PILLARLETTER_MIN, PILLARLETTER_MAX);
  vid_letterbox_pct := ibetween(vid_letterbox_pct, PILLARLETTER_MIN, PILLARLETTER_MAX);

  srcrect.Left := 0;
  srcrect.Top := 0;
  srcrect.Right := SCREENWIDTH;
  srcrect.Bottom := SCREENHEIGHT;

  hpan := Trunc(vid_pillarbox_pct * XWINDOWWIDTH / 100 / 2);
  vpan := Trunc(vid_letterbox_pct * XWINDOWHEIGHT / 100 / 2);

  if (vid_pillarbox_pct <> old_pillarbox_pct) or
     (vid_letterbox_pct <> old_letterbox_pct) or
     (old_windowwidth <> XWINDOWWIDTH) or
     (old_windowheight <> XWINDOWHEIGHT) or
     (fullscreen <> old_fullscreen) or (fullscreenexclusive <> old_fullscreenexclusive) then
  begin
    if bpp = 16 then
    begin
      oldcolor := screen16[0];
      screen16[0] := 0;
    end
    else
    begin
      oldcolor := screen32[0];
      screen32[0] := 0;
    end;

    blackrect.Left := 0;
    blackrect.Top := 0;
    blackrect.Right := 1;
    blackrect.Bottom := 1;

    if hpan <> 0 then
    begin
      destrect.Left := 0;
      destrect.Top := 0;
      destrect.Right := hpan;
      destrect.Bottom := XWINDOWHEIGHT;

      if g_pDDSPrimary.Blt(destrect, g_pDDScreen, blackrect, DDBLTFAST_DONOTWAIT or DDBLTFAST_NOCOLORKEY, PDDBltFX(0)^) = DDERR_SURFACELOST then
        g_pDDSPrimary.Restore;

      destrect.Left := XWINDOWWIDTH - hpan;
      destrect.Top := 0;
      destrect.Right := XWINDOWWIDTH;
      destrect.Bottom := XWINDOWHEIGHT;

      if g_pDDSPrimary.Blt(destrect, g_pDDScreen, blackrect, DDBLTFAST_DONOTWAIT or DDBLTFAST_NOCOLORKEY, PDDBltFX(0)^) = DDERR_SURFACELOST then
        g_pDDSPrimary.Restore;
    end;

    if vpan <> 0 then
    begin
      destrect.Left := hpan;
      destrect.Top := 0;
      destrect.Right := XWINDOWWIDTH - hpan;
      destrect.Bottom := vpan;

      if g_pDDSPrimary.Blt(destrect, g_pDDScreen, blackrect, DDBLTFAST_DONOTWAIT or DDBLTFAST_NOCOLORKEY, PDDBltFX(0)^) = DDERR_SURFACELOST then
        g_pDDSPrimary.Restore;

      destrect.Left := hpan;
      destrect.Top := XWINDOWHEIGHT - vpan;
      destrect.Right := XWINDOWWIDTH - hpan;
      destrect.Bottom := XWINDOWHEIGHT;

      if g_pDDSPrimary.Blt(destrect, g_pDDScreen, blackrect, DDBLTFAST_DONOTWAIT or DDBLTFAST_NOCOLORKEY, PDDBltFX(0)^) = DDERR_SURFACELOST then
        g_pDDSPrimary.Restore;
    end;

    if bpp = 16 then
      screen16[0] := oldcolor
    else
      screen32[0] := oldcolor;

    old_pillarbox_pct := vid_pillarbox_pct;
    old_letterbox_pct := vid_letterbox_pct;
    old_windowwidth := XWINDOWWIDTH;
    old_windowheight := XWINDOWHEIGHT;
    old_fullscreen := fullscreen;
    old_fullscreenexclusive := fullscreenexclusive;
  end;

  destrect.Left := hpan;
  destrect.Top := vpan;
  destrect.Right := XWINDOWWIDTH - hpan;
  destrect.Bottom := XWINDOWHEIGHT - vpan;

  if g_pDDSPrimary.Blt(destrect, g_pDDScreen, srcrect, DDBLTFAST_DONOTWAIT or DDBLTFAST_NOCOLORKEY, PDDBltFX(0)^) = DDERR_SURFACELOST then
    g_pDDSPrimary.Restore;
end;

//
// Palette stuff.
//

const
  GAMMASIZE = 5;

// Now where did these came from?
  gammatable: array[0..GAMMASIZE - 1, 0..255] of byte = (
    (  1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14,  15,  16,
      17,  18,  19,  20,  21,  22,  23,  24,  25,  26,  27,  28,  29,  30,  31,  32,
      33,  34,  35,  36,  37,  38,  39,  40,  41,  42,  43,  44,  45,  46,  47,  48,
      49,  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  60,  61,  62,  63,  64,
      65,  66,  67,  68,  69,  70,  71,  72,  73,  74,  75,  76,  77,  78,  79,  80,
      81,  82,  83,  84,  85,  86,  87,  88,  89,  90,  91,  92,  93,  94,  95,  96,
      97,  98,  99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112,
     113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128,
     128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143,
     144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159,
     160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175,
     176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191,
     192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207,
     208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223,
     224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239,
     240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255),

    (  2,   4,   5,   7,   8,  10,  11,  12,  14,  15,  16,  18,  19,  20,  21,  23,
      24,  25,  26,  27,  29,  30,  31,  32,  33,  34,  36,  37,  38,  39,  40,  41,
      42,  44,  45,  46,  47,  48,  49,  50,  51,  52,  54,  55,  56,  57,  58,  59,
      60,  61,  62,  63,  64,  65,  66,  67,  69,  70,  71,  72,  73,  74,  75,  76,
      77,  78,  79,  80,  81,  82,  83,  84,  85,  86,  87,  88,  89,  90,  91,  92,
      93,  94,  95,  96,  97,  98,  99, 100, 101, 102, 103, 104, 105, 106, 107, 108,
     109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124,
     125, 126, 127, 128, 129, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139,
     140, 141, 142, 143, 144, 145, 146, 147, 148, 148, 149, 150, 151, 152, 153, 154,
     155, 156, 157, 158, 159, 160, 161, 162, 163, 163, 164, 165, 166, 167, 168, 169,
     170, 171, 172, 173, 174, 175, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184,
     185, 186, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 196, 197, 198,
     199, 200, 201, 202, 203, 204, 205, 205, 206, 207, 208, 209, 210, 211, 212, 213,
     214, 214, 215, 216, 217, 218, 219, 220, 221, 222, 222, 223, 224, 225, 226, 227,
     228, 229, 230, 230, 231, 232, 233, 234, 235, 236, 237, 237, 238, 239, 240, 241,
     242, 243, 244, 245, 245, 246, 247, 248, 249, 250, 251, 252, 252, 253, 254, 255),

    (  4,   7,   9,  11,  13,  15,  17,  19,  21,  22,  24,  26,  27,  29,  30,  32,
      33,  35,  36,  38,  39,  40,  42,  43,  45,  46,  47,  48,  50,  51,  52,  54,
      55,  56,  57,  59,  60,  61,  62,  63,  65,  66,  67,  68,  69,  70,  72,  73,
      74,  75,  76,  77,  78,  79,  80,  82,  83,  84,  85,  86,  87,  88,  89,  90,
      91,  92,  93,  94,  95,  96,  97,  98, 100, 101, 102, 103, 104, 105, 106, 107,
     108, 109, 110, 111, 112, 113, 114, 114, 115, 116, 117, 118, 119, 120, 121, 122,
     123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 133, 134, 135, 136, 137,
     138, 139, 140, 141, 142, 143, 144, 144, 145, 146, 147, 148, 149, 150, 151, 152,
     153, 153, 154, 155, 156, 157, 158, 159, 160, 160, 161, 162, 163, 164, 165, 166,
     166, 167, 168, 169, 170, 171, 172, 172, 173, 174, 175, 176, 177, 178, 178, 179,
     180, 181, 182, 183, 183, 184, 185, 186, 187, 188, 188, 189, 190, 191, 192, 193,
     193, 194, 195, 196, 197, 197, 198, 199, 200, 201, 201, 202, 203, 204, 205, 206,
     206, 207, 208, 209, 210, 210, 211, 212, 213, 213, 214, 215, 216, 217, 217, 218,
     219, 220, 221, 221, 222, 223, 224, 224, 225, 226, 227, 228, 228, 229, 230, 231,
     231, 232, 233, 234, 235, 235, 236, 237, 238, 238, 239, 240, 241, 241, 242, 243,
     244, 244, 245, 246, 247, 247, 248, 249, 250, 251, 251, 252, 253, 254, 254, 255),

    (  8,  12,  16,  19,  22,  24,  27,  29,  31,  34,  36,  38,  40,  41,  43,  45,
      47,  49,  50,  52,  53,  55,  57,  58,  60,  61,  63,  64,  65,  67,  68,  70,
      71,  72,  74,  75,  76,  77,  79,  80,  81,  82,  84,  85,  86,  87,  88,  90,
      91,  92,  93,  94,  95,  96,  98,  99, 100, 101, 102, 103, 104, 105, 106, 107,
     108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123,
     124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 135, 136, 137, 138,
     139, 140, 141, 142, 143, 143, 144, 145, 146, 147, 148, 149, 150, 150, 151, 152,
     153, 154, 155, 155, 156, 157, 158, 159, 160, 160, 161, 162, 163, 164, 165, 165,
     166, 167, 168, 169, 169, 170, 171, 172, 173, 173, 174, 175, 176, 176, 177, 178,
     179, 180, 180, 181, 182, 183, 183, 184, 185, 186, 186, 187, 188, 189, 189, 190,
     191, 192, 192, 193, 194, 195, 195, 196, 197, 197, 198, 199, 200, 200, 201, 202,
     202, 203, 204, 205, 205, 206, 207, 207, 208, 209, 210, 210, 211, 212, 212, 213,
     214, 214, 215, 216, 216, 217, 218, 219, 219, 220, 221, 221, 222, 223, 223, 224,
     225, 225, 226, 227, 227, 228, 229, 229, 230, 231, 231, 232, 233, 233, 234, 235,
     235, 236, 237, 237, 238, 238, 239, 240, 240, 241, 242, 242, 243, 244, 244, 245,
     246, 246, 247, 247, 248, 249, 249, 250, 251, 251, 252, 253, 253, 254, 254, 255),

    ( 16,  23,  28,  32,  36,  39,  42,  45,  48,  50,  53,  55,  57,  60,  62,  64,
      66,  68,  69,  71,  73,  75,  76,  78,  80,  81,  83,  84,  86,  87,  89,  90,
      92,  93,  94,  96,  97,  98, 100, 101, 102, 103, 105, 106, 107, 108, 109, 110,
     112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 128,
     128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143,
     143, 144, 145, 146, 147, 148, 149, 150, 150, 151, 152, 153, 154, 155, 155, 156,
     157, 158, 159, 159, 160, 161, 162, 163, 163, 164, 165, 166, 166, 167, 168, 169,
     169, 170, 171, 172, 172, 173, 174, 175, 175, 176, 177, 177, 178, 179, 180, 180,
     181, 182, 182, 183, 184, 184, 185, 186, 187, 187, 188, 189, 189, 190, 191, 191,
     192, 193, 193, 194, 195, 195, 196, 196, 197, 198, 198, 199, 200, 200, 201, 202,
     202, 203, 203, 204, 205, 205, 206, 207, 207, 208, 208, 209, 210, 210, 211, 211,
     212, 213, 213, 214, 214, 215, 216, 216, 217, 217, 218, 219, 219, 220, 220, 221,
     221, 222, 223, 223, 224, 224, 225, 225, 226, 227, 227, 228, 228, 229, 229, 230,
     230, 231, 232, 232, 233, 233, 234, 234, 235, 235, 236, 236, 237, 237, 238, 239,
     239, 240, 240, 241, 241, 242, 242, 243, 243, 244, 244, 245, 245, 246, 246, 247,
     247, 248, 248, 249, 249, 250, 250, 251, 251, 252, 252, 253, 254, 254, 255, 255)
  );

//
// I_SetPalette
//
procedure I_SetPalette(const palette: PByteArray);
var
  dest: PLongWord;
  src: PByteArray;
  curgamma: PByteArray;
begin
  dest := @curpal[0];
  src := palette;
  curgamma := @gammatable[usegamma];
  while PCAST(src) < PCAST(@palette[256 * 3]) do
  begin
    dest^ := ((LongWord(curgamma[src[0]]) shl 16) * 4) or
             ((LongWord(curgamma[src[1]]) shl 8) * 4) or
             ((LongWord(curgamma[src[2]]) * 4));
    inc(dest);
    src := @src[3];
  end;
end;

var
  NATIVEWIDTH: integer;
  NATIVEHEIGHT: integer;

function I_AdjustWindowMode: boolean;
begin
  result := false;
  if XWINDOWWIDTH > NATIVEWIDTH then
  begin
    XWINDOWWIDTH := NATIVEWIDTH;
    result := true;
  end;
  if XWINDOWHEIGHT > NATIVEHEIGHT then
  begin
    XWINDOWHEIGHT := NATIVEHEIGHT;
    result := true;
  end;
end;

procedure SortDisplayModes;

  function sortvalue(const idx: integer): double;
  begin
    result := displaymodes[idx].width + displaymodes[idx].height / 1000000
  end;

  procedure qsort(l, r: Integer);
  var
    i, j: Integer;
    tmp: displaymode_t;
    rover: double;
  begin
    repeat
      i := l;
      j := r;
      rover := sortvalue((l + r) shr 1);
      repeat
        while sortvalue(i) < rover do
          inc(i);
        while sortvalue(j) > rover do
          dec(j);
        if i <= j then
        begin
          tmp := displaymodes[i];
          displaymodes[i] := displaymodes[j];
          displaymodes[j] := tmp;
          inc(i);
          dec(j);
        end;
      until i > j;
      if l < j then
        qsort(l, j);
      l := i;
    until i >= r;
  end;

begin
  if numdisplaymodes > 0 then
    qsort(0, numdisplaymodes - 1);
end;


function I_DisplayModeIndex(const w, h: integer): integer;
var
  i: integer;
begin
  result := -1;

  if displaymodes = nil then
    exit;

  for i := 0 to numdisplaymodes - 1 do
    if (displaymodes[i].width = w) and (displaymodes[i].height = h) then
    begin
      result := i;
      exit;
    end;
end;

function I_NearestDisplayModeIndex(const w, h: integer): integer;
var
  i: integer;
  dist: double;
  mindist: double;
begin
  result := I_DisplayModeIndex(w, h);
  if result >= 0 then
    exit;

  mindist := 1000000000000.0;
  for i := 0 to numdisplaymodes - 1 do
  begin
    dist := sqrt(sqr(displaymodes[i].width - SCREENWIDTH) + sqr(displaymodes[i].height - SCREENHEIGHT));
    if SCREENWIDTH < displaymodes[i].width then
      dist := dist + 50.0;
    if SCREENHEIGHT < displaymodes[i].height then
      dist := dist + 50.0;
    if dist < mindist then
    begin
      mindist := dist;
      result := i;
    end;
  end;
end;

function IsAvailableScreenResolution(const w, h: integer): boolean;
begin
  result := I_DisplayModeIndex(w, h) >= 0;
end;

procedure I_EnumDisplayModes;
var
  dm: TDevMode;
  i: integer;
begin
  if displaymodes <> nil then
    memfree(pointer(displaymodes));

  numdisplaymodes := 0;
  i := 0;
  while EnumDisplaySettings(nil, i, dm) do
  begin
    if (dm.dmPelsWidth >= 320) and (dm.dmPelsHeight >= 200) and (dm.dmBitsPerPel = 32) and not IsAvailableScreenResolution(dm.dmPelsWidth, dm.dmPelsHeight) then
    begin
      realloc(pointer(displaymodes), (numdisplaymodes + 1) * SizeOf(displaymode_t));
      displaymodes[numdisplaymodes].width := dm.dmPelsWidth;
      displaymodes[numdisplaymodes].height := dm.dmPelsHeight;
      displaymodes[numdisplaymodes].bpp := dm.dmBitsPerPel;
      inc(numdisplaymodes);
    end;
    Inc(i);
  end;
  if numdisplaymodes = 0 then
  begin
    while EnumDisplaySettings(nil, i, dm) do
    begin
      if (dm.dmPelsWidth >= 640) and (dm.dmPelsHeight >= 400) and (dm.dmBitsPerPel >= 16) and not IsAvailableScreenResolution(dm.dmPelsWidth, dm.dmPelsHeight) then
      begin
        realloc(pointer(displaymodes), (numdisplaymodes + 1) * SizeOf(displaymode_t));
        displaymodes[numdisplaymodes].width := dm.dmPelsWidth;
        displaymodes[numdisplaymodes].height := dm.dmPelsHeight;
        displaymodes[numdisplaymodes].bpp := dm.dmBitsPerPel;
        inc(numdisplaymodes);
      end;
      Inc(i);
    end;
  end;
  if numdisplaymodes = 0 then
  begin
    displaymodes := malloc(SizeOf(displaymode_t));
    displaymodes[0].width := 320;
    displaymodes[0].height := 200;
    displaymodes[0].bpp := 32;
    displaymodes[1].width := 640;
    displaymodes[1].height := 400;
    displaymodes[1].bpp := 32;
    numdisplaymodes := 2;
  end;

  SortDisplayModes;
end;

procedure I_DoFindWindowSize(const dofull, doexclusive: boolean);
var
  i: integer;
  dist: double;
  mindist: double;
  idx: integer;
begin
  if dofull and not doexclusive then
  begin
    XWINDOWWIDTH := NATIVEWIDTH;
    XWINDOWHEIGHT := NATIVEHEIGHT;
    exit;
  end;

  if not dofull then
  begin
    XWINDOWWIDTH := SCREENWIDTH;
    XWINDOWHEIGHT := SCREENHEIGHT;
    exit;
  end;

  for i := 0 to numdisplaymodes - 1 do
    if displaymodes[i].width = SCREENWIDTH then
      if displaymodes[i].height = SCREENHEIGHT then
      begin
        XWINDOWWIDTH := SCREENWIDTH;
        XWINDOWHEIGHT := SCREENHEIGHT;
        exit;
      end;

  mindist := 1000000000000.0;
  idx := -1;
  for i := 0 to numdisplaymodes - 1 do
  begin
    dist := sqrt(sqr(displaymodes[i].width - SCREENWIDTH) + sqr(displaymodes[i].height - SCREENHEIGHT));
    if SCREENWIDTH < displaymodes[i].width then
      dist := dist + 50.0;
    if SCREENHEIGHT < displaymodes[i].height then
      dist := dist + 50.0;
    if dist < mindist then
    begin
      mindist := dist;
      idx := i;
    end;
  end;

  if idx >= 0 then
  begin
    XWINDOWWIDTH := displaymodes[idx].width;
    XWINDOWHEIGHT := displaymodes[idx].height;
    exit;
  end;

  XWINDOWWIDTH := NATIVEWIDTH;
  XWINDOWHEIGHT := NATIVEHEIGHT;
end;

procedure I_FindWindowSize(const dofull, doexclusive: boolean);
var
  oldw, oldh: integer;
begin
  oldw := XWINDOWWIDTH;
  oldh := XWINDOWHEIGHT;
  I_DoFindWindowSize(dofull, doexclusive);
  if (oldw <> XWINDOWWIDTH) or (oldh <> XWINDOWHEIGHT) then
    printf('I_FindWindowSize: Set window size at (%d, %d)'#13#10, [XWINDOWWIDTH, XWINDOWHEIGHT]);
end;

procedure I_DetectNativeScreenResolution;
begin
  NATIVEWIDTH := GetSystemMetrics(SM_CXSCREEN);
  NATIVEHEIGHT := GetSystemMetrics(SM_CYSCREEN);
end;

var
  isexclusive: boolean = false;

function I_SetCooperativeLevel(const exclusive: boolean): HResult;
begin
  if exclusive then
    result := g_pDD.SetCooperativeLevel(hMainWnd, DDSCL_ALLOWMODEX or DDSCL_EXCLUSIVE or DDSCL_FULLSCREEN)
  else
    result := g_pDD.SetCooperativeLevel(hMainWnd, DDSCL_NORMAL);
  isexclusive := exclusive;
end;

const
  ERROR_OFFSET = 20;

// Called by D_DoomMain,
// determines the hardware configuration
// and sets up the video mode
procedure I_InitGraphics;
var
  hres: HRESULT;
  ddsd: DDSURFACEDESC2;

  procedure I_ErrorInitGraphics(const procname: string);
  begin
    MS_Error('I_InitGraphics(): %s failed, result = %d', [procname, hres]);
  end;

begin
  if g_pDD <> nil then
    exit;

  printf('I_InitGraphics: Initialize directdraw.' + #13#10);

  I_DetectNativeScreenResolution;
  I_FindWindowSize(fullscreen, fullscreenexclusive);
  I_RestoreWindowPos;

  I_EnumDisplayModes;

///////////////////////////////////////////////////////////////////////////
// Create the main DirectDraw object
///////////////////////////////////////////////////////////////////////////
  hres := DirectDrawCreateEx(nil, g_pDD, IID_IDirectDraw7, nil);
  if hres <> DD_OK then
    I_ErrorInitGraphics('DirectDrawCreateEx');

  if fullscreen then
  begin
    I_FindWindowSize(true, fullscreenexclusive);

    // Get exclusive mode
    hres := I_SetCooperativeLevel(fullscreenexclusive);

    if hres <> DD_OK then
      I_ErrorInitGraphics('SetCooperativeLevel');

    if fullscreenexclusive then
    begin
      // Set the video mode to XWINDOWWIDTH x XWINDOWHEIGHT x 32
      hres := g_pDD.SetDisplayMode(XWINDOWWIDTH, XWINDOWHEIGHT, 32, 0, 0);
      if hres <> DD_OK then
      begin
      // Fullscreen mode failed, trying window mode
        fullscreen := false;

        I_AdjustWindowMode;
        I_RestoreWindowPos;

        printf('SetDisplayMode(): Failed to fullscreen %dx%dx%d, trying window mode...'#13#10,
          [XWINDOWWIDTH, XWINDOWHEIGHT, 32]);
        printf('Window Mode %dx%d' + #13#10, [XWINDOWWIDTH, XWINDOWHEIGHT]);

        hres := I_SetCooperativeLevel(false);
        if hres <> DD_OK then
        begin
          printf('SetDisplayMode(): Failed to window mode %dx%d...' + #13#10, [XWINDOWWIDTH, XWINDOWHEIGHT]);
          XWINDOWWIDTH := 640;
          XWINDOWHEIGHT := 480;
          hres := g_pDD.SetDisplayMode(XWINDOWWIDTH, XWINDOWHEIGHT, 32, 0, 0);
          if hres <> DD_OK then
            I_ErrorInitGraphics('SetDisplayMode');
          printf('SetDisplayMode(): %dx%d...'#13#10, [XWINDOWWIDTH, XWINDOWHEIGHT]);
        end;
      end
      else
        I_DisableAltTab;
    end;
  end
  else
  begin
    I_FindWindowSize(false, false);
    I_AdjustWindowMode;
    I_RestoreWindowPos;
    hres := I_SetCooperativeLevel(false);
    if hres <> DD_OK then
      I_ErrorInitGraphics('SetCooperativeLevel');
  end;

  ZeroMemory(@ddsd, SizeOf(ddsd));
  ddsd.dwSize := SizeOf(ddsd);
  ddsd.dwFlags := DDSD_CAPS;
  ddsd.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE or DDSCAPS_VIDEOMEMORY;
  hres := g_pDD.CreateSurface(ddsd, g_pDDSPrimary, nil);
  if hres <> DD_OK then
  begin
    printf('I_InitGraphics(): Usage of video memory failed, trying system memory.'#13#10);
    ddsd.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE;
    hres := g_pDD.CreateSurface(ddsd, g_pDDSPrimary, nil);
    if hres <> DD_OK then
      I_ErrorInitGraphics('CreateSurface');
  end;


  ZeroMemory(@ddsd, SizeOf(ddsd));
  ZeroMemory(@ddsd.ddpfPixelFormat, SizeOf(ddsd.ddpfPixelFormat));

  ddsd.ddpfPixelFormat.dwSize := SizeOf(ddsd.ddpfPixelFormat);
  g_pDDSPrimary.GetPixelFormat(ddsd.ddpfPixelFormat);

  ddsd.dwSize := SizeOf(ddsd);
  ddsd.dwFlags := DDSD_WIDTH or DDSD_HEIGHT or DDSD_LPSURFACE or
                  DDSD_PITCH or DDSD_PIXELFORMAT or DDSD_CAPS;
  ddsd.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN or DDSCAPS_SYSTEMMEMORY;

  bpp := ddsd.ddpfPixelFormat.dwRGBBitCount;

  ddsd.dwWidth := SCREENWIDTH;
  ddsd.dwHeight := SCREENHEIGHT;

  if bpp = 32 then
  begin
    ddsd.lPitch := 4 * SCREENWIDTH; // Display is true color
    screen16 := nil;
  end
  else if bpp = 16 then
  begin
    ddsd.lPitch := 2 * SCREENWIDTH;
    screen16 := malloc(SCREENWIDTH * SCREENHEIGHT * 2);
    printf('I_InitGraphics(): using 16 bit color depth desktop in non fullscreen mode reduces performance'#13#10);
  end
  else
    MS_Error('I_InitGraphics(): invalid colordepth = %d, only 16 and 32 bit color depth allowed', [bpp]);

  allocscreensize := SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord);
  screen32 := malloc(allocscreensize); // JVAL: Memory padding may increase performance until 4%

  if bpp = 16 then
    ddsd.lpSurface := screen16
  else
    ddsd.lpSurface := screen32;

  hres := g_pDD.CreateSurface(ddsd, g_pDDScreen, nil);
  if hres <> DD_OK then
    I_ErrorInitGraphics('CreateSurface');
end;

procedure I_RecreateSurfaces;
var
  hres: HRESULT;
  ddsd: DDSURFACEDESC2;
begin
  I_ClearInterface(IInterface(g_pDDScreen));
  I_ClearInterface(IInterface(g_pDDSPrimary));

  ZeroMemory(@ddsd, SizeOf(ddsd));
  ddsd.dwSize := SizeOf(ddsd);
  ddsd.dwFlags := DDSD_CAPS;
  ddsd.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE or DDSCAPS_VIDEOMEMORY;
  hres := g_pDD.CreateSurface(ddsd, g_pDDSPrimary, nil);
  if hres <> DD_OK then
  begin
    ddsd.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE;
    hres := g_pDD.CreateSurface(ddsd, g_pDDSPrimary, nil);
    if hres <> DD_OK then
      MS_Error('I_RecreateSurfaces(): CreateSurface failed');
  end;

  ZeroMemory(@ddsd, SizeOf(ddsd));
  ZeroMemory(@ddsd.ddpfPixelFormat, SizeOf(ddsd.ddpfPixelFormat));

  ddsd.ddpfPixelFormat.dwSize := SizeOf(ddsd.ddpfPixelFormat);
  g_pDDSPrimary.GetPixelFormat(ddsd.ddpfPixelFormat);

  ddsd.dwSize := SizeOf(ddsd);
  ddsd.dwFlags := DDSD_WIDTH or DDSD_HEIGHT or DDSD_LPSURFACE or
                  DDSD_PITCH or DDSD_PIXELFORMAT or DDSD_CAPS;
  ddsd.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN or DDSCAPS_SYSTEMMEMORY;

  bpp := ddsd.ddpfPixelFormat.dwRGBBitCount;

  ddsd.dwWidth := SCREENWIDTH;
  ddsd.dwHeight := SCREENHEIGHT;

  if bpp = 32 then
  begin
    ddsd.lPitch := 4 * SCREENWIDTH; // Display is true color
    if screen16 <> nil then
      memfree(pointer(screen16));
  end
  else if bpp = 16 then
  begin
    ddsd.lPitch := 2 * SCREENWIDTH;
    if screen16 <> nil then
      screen16 := malloc(SCREENWIDTH * SCREENHEIGHT * 2);
    printf('I_RecreateSurfaces(): using 16 bit color depth desktop in non fullscreen mode reduces performance'#13#10);
  end
  else
    MS_Error('I_RecreateSurfaces(): invalid colordepth = %d, only 16 and 32 bit color depth allowed', [bpp]);

  if bpp = 16 then
    ddsd.lpSurface := screen16
  else
    ddsd.lpSurface := screen32;

  hres := g_pDD.CreateSurface(ddsd, g_pDDScreen, nil);
  if hres <> DD_OK then
    MS_Error('I_RecreateSurfaces(): CreateSurface failed');
end;

const
  NUMSTDRESOLUTIONS = 11;
  STANDARDSCREENRESOLUTIONS: array[0..NUMSTDRESOLUTIONS - 1, 0..1] of integer = (
    (1920, 1080), (1366, 768), (1280, 1024), (1280, 800), (1024, 768), (800, 600), (640, 480), (600, 400), (512, 384), (400, 300), (320, 200)
  );

const
  s_cfs_descs: array[boolean] of string = ('window', 'fullscreen');

procedure I_DoChangeFullScreen(const dofull, doexclusive: boolean);
var
  hres: HRESULT;
  i: integer;
  wasexclusive: boolean;
begin
  if dofull = fullscreen then
    if doexclusive = fullscreenexclusive then
      exit;

  if not dofull and not fullscreen then
  begin
    fullscreenexclusive := doexclusive;
    exit;
  end;

  wasexclusive := isexclusive;

  hres := I_SetCooperativeLevel(dofull and doexclusive);

  if hres <> DD_OK then
  begin
    printf('I_ChangeFullScreen(): Can not change to %s mode'#13#10, [s_cfs_descs[dofull and doexclusive]]);
    exit;
  end;

  I_FindWindowSize(dofull, doexclusive);
  I_AdjustWindowMode;
  I_RestoreWindowPos;

  if dofull and doexclusive then
  begin
    hres := g_pDD.SetDisplayMode(XWINDOWWIDTH, XWINDOWHEIGHT, 32, 0, 0);
    if hres <> DD_OK then
    begin
      printf('I_ChangeFullScreen(): Can not change to (%d, %d)'#13#10, [XWINDOWWIDTH, XWINDOWHEIGHT]);

      i := 0;

      // Determine a standard screen resolution
      XWINDOWWIDTH := STANDARDSCREENRESOLUTIONS[NUMSTDRESOLUTIONS - 1, 0];
      XWINDOWHEIGHT := STANDARDSCREENRESOLUTIONS[NUMSTDRESOLUTIONS - 1, 1];
      while i < NUMSTDRESOLUTIONS - 1 do
      begin
        if (XWINDOWWIDTH <= STANDARDSCREENRESOLUTIONS[i, 0]) and
           (XWINDOWHEIGHT <= STANDARDSCREENRESOLUTIONS[i, 1]) and
           (XWINDOWWIDTH >= STANDARDSCREENRESOLUTIONS[i + 1, 0]) then
        begin
          XWINDOWWIDTH := STANDARDSCREENRESOLUTIONS[i, 0];
          XWINDOWHEIGHT := STANDARDSCREENRESOLUTIONS[i, 1];
          break;
        end;
        inc(i);
      end;

      hres := g_pDD.SetDisplayMode(XWINDOWWIDTH, XWINDOWHEIGHT, 32, 0, 0);
      if hres <> DD_OK then
      begin
        printf('I_ChangeFullScreen(): Can not change to %s mode'#13#10, [s_cfs_descs[fullscreen]]);
        // Restore original window state
        I_SetCooperativeLevel(false);
        exit;
      end;
    end;
  end;

  if wasexclusive then
    if not isexclusive then
      g_pDD.RestoreDisplayMode;

  fullscreen := dofull;
  fullscreenexclusive := doexclusive;

  I_RecreateSurfaces;
end;

procedure I_ChangeFullScreen(const dofull, doexclusive: boolean);
begin
//  I_IgnoreInput(MAXINT);
  I_DoChangeFullScreen(dofull, doexclusive);
//  I_IgnoreInput(15);
end;

procedure I_ReadScreen32(dest: pointer);
begin
  memcpy(dest, screen32, SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord));
end;

end.


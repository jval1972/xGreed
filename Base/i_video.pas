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

procedure I_GetPalette(const palette: PByteArray);

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
  fullscreen: boolean = {$IFDEF VALIDATE}false{$ELSE}true{$ENDIF};
  fullscreenexclusive: boolean = false;
  approx_zero: byte = 0;

procedure I_TranslateBuffer(const buf: PByteArray; const sz: integer);

implementation

uses
  DirectX,
  d_misc,
  i_windows,
  i_main,
  r_public_h,
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
type
  screen320_t8 = packed array[0..199, 0..319] of byte;
  Pscreen320_t8 = ^screen320_t8;
  screen640_t32 = packed array[0..399, 0..639] of LongWord;
  Pscreen640_t32 = ^screen640_t32;

procedure I_FinishUpdate8(parms: Pfinishupdateparms_t);
var
  destl: PLongWord;
  destw: PWord;
  pixel: LongWord;
  r, g, b: LongWord;
  src: PByte;
  srcstop: PByte;
  i, x, y: integer;
  s8: Pscreen320_t8;
  s32: Pscreen640_t32;
begin
  src := @(renderbuffer[parms.start]);
  srcstop := @(renderbuffer[parms.stop]);
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

  s8 := @viewbuffer[0];
  s32 := @screen32[0];
  for i := parms.start to parms.stop do
  begin
    x := (i mod 640) div 2;
    y := (i div 640) div 2;
    if s8[y, x] <> 0 then
      screen32[i] := curpal[s8[y, x]];
  end;     
end;

var
  old_pillarbox_pct: integer = -1;
  old_letterbox_pct: integer = -1;
  old_windowwidth: integer = -1;
  old_windowheight: integer = -1;
  old_fullscreen: boolean = false;
  old_fullscreenexclusive: boolean = false;
  infinishupdate: boolean = false;

procedure I_FinishUpdate;
var
  srcrect: TRect;
  destrect: TRect;
  blackrect: TRect;
  oldcolor: LongWord;
  parms1: finishupdateparms_t;
  hpan, vpan: integer;
begin
  if (screen16 = nil) and (screen32 = nil) or (g_pDDScreen = nil) or infinishupdate then
    exit;

  infinishupdate := true;
  parms1.start := 0;
  parms1.stop := RENDER_VIEW_WIDTH * RENDER_VIEW_HEIGHT - 1;
  I_FinishUpdate8(@parms1);

  vid_pillarbox_pct := ibetween(vid_pillarbox_pct, PILLARLETTER_MIN, PILLARLETTER_MAX);
  vid_letterbox_pct := ibetween(vid_letterbox_pct, PILLARLETTER_MIN, PILLARLETTER_MAX);

  srcrect.Left := 0;
  srcrect.Top := 0;
  srcrect.Right := RENDER_VIEW_WIDTH;
  srcrect.Bottom := RENDER_VIEW_HEIGHT;

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

//  if g_pDDSPrimary.Blt(destrect, g_pDDScreen, srcrect, DDBLTFAST_DONOTWAIT or DDBLTFAST_NOCOLORKEY, PDDBltFX(0)^) = DDERR_SURFACELOST then
  if g_pDDSPrimary.Blt(destrect, g_pDDScreen, srcrect, DDBLTFAST_WAIT or DDBLTFAST_NOCOLORKEY, PDDBltFX(0)^) = DDERR_SURFACELOST then
    g_pDDSPrimary.Restore;

  infinishupdate := false;
end;

//
// Palette stuff.
//

//
// I_SetPalette
//
procedure I_SetPalette(const palette: PByteArray);
var
  dest: PLongWord;
  src: PByteArray;
  r, g, b, idx: byte;
  dist, maxdist: integer;
begin
  dest := @curpal[0];
  src := palette;

  r := src[0];
  g := src[1];
  b := src[2];

  dest^ := 0;
  inc(dest);
  src := @src[3];

  while PCAST(src) < PCAST(@palette[256 * 3]) do
  begin
    dest^ := (LongWord(src[0]) shl 16) or
             (LongWord(src[1]) shl 8) or
             LongWord(src[2]);
    inc(dest);
    src := @src[3];
  end;

  maxdist := MAXINT;
  src := @palette[3];
  idx := 0;
  while PCAST(src) < PCAST(@palette[256 * 3]) do
  begin
    Inc(idx);
    dist :=
      (r - src[0]) * (r - src[0]) +
      (g - src[1]) * (g - src[1]) +
      (b - src[2]) * (b - src[2]);
    if dist < maxdist then
    begin
      approx_zero := idx;
      maxdist := dist;
      if dist = 0 then
        break;
    end;
    src := @src[3];
  end;
end;

procedure I_GetPalette(const palette: PByteArray);
var
  i: integer;
  dest: PByte;
begin
  dest := @palette[0];
  for i := 0 to 255 do
  begin
    dest^ := curpal[i] div 65536;
    inc(dest);
    dest^ := curpal[i] div 256;
    inc(dest);
    dest^ := curpal[i];
    inc(dest);
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
    dist := sqrt(sqr(displaymodes[i].width - RENDER_VIEW_WIDTH) + sqr(displaymodes[i].height - RENDER_VIEW_HEIGHT));
    if RENDER_VIEW_WIDTH < displaymodes[i].width then
      dist := dist + 50.0;
    if RENDER_VIEW_HEIGHT < displaymodes[i].height then
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
    XWINDOWWIDTH := {$IFDEF VALIDATE}NATIVEWIDTH{$ELSE}RENDER_VIEW_WIDTH{$ENDIF};
    XWINDOWHEIGHT := {$IFDEF VALIDATE}NATIVEHEIGHT{$ELSE}RENDER_VIEW_HEIGHT{$ENDIF};
    exit;
  end;

  for i := 0 to numdisplaymodes - 1 do
    if displaymodes[i].width = RENDER_VIEW_WIDTH then
      if displaymodes[i].height = RENDER_VIEW_HEIGHT then
      begin
        XWINDOWWIDTH := RENDER_VIEW_WIDTH;
        XWINDOWHEIGHT := RENDER_VIEW_HEIGHT;
        exit;
      end;

  mindist := 1000000000000.0;
  idx := -1;
  for i := 0 to numdisplaymodes - 1 do
  begin
    dist := sqrt(sqr(displaymodes[i].width - RENDER_VIEW_WIDTH) + sqr(displaymodes[i].height - RENDER_VIEW_HEIGHT));
    if RENDER_VIEW_WIDTH < displaymodes[i].width then
      dist := dist + 50.0;
    if RENDER_VIEW_HEIGHT < displaymodes[i].height then
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
{$IFDEF VALIDATE}
  NATIVEWIDTH := 640;
  NATIVEHEIGHT := 400;
{$ELSE}
  NATIVEWIDTH := GetSystemMetrics(SM_CXSCREEN);
  NATIVEHEIGHT := GetSystemMetrics(SM_CYSCREEN);
{$ENDIF}
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

  ddsd.dwWidth := RENDER_VIEW_WIDTH;
  ddsd.dwHeight := RENDER_VIEW_HEIGHT;

  if bpp = 32 then
  begin
    ddsd.lPitch := 4 * RENDER_VIEW_WIDTH; // Display is true color
    screen16 := nil;
  end
  else if bpp = 16 then
  begin
    ddsd.lPitch := 2 * RENDER_VIEW_WIDTH;
    screen16 := malloc(RENDER_VIEW_WIDTH * RENDER_VIEW_HEIGHT * 2);
    printf('I_InitGraphics(): using 16 bit color depth desktop in non fullscreen mode reduces performance'#13#10);
  end
  else
    MS_Error('I_InitGraphics(): invalid colordepth = %d, only 16 and 32 bit color depth allowed', [bpp]);

  allocscreensize := RENDER_VIEW_WIDTH * RENDER_VIEW_HEIGHT * SizeOf(LongWord);
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

  ddsd.dwWidth := RENDER_VIEW_WIDTH;
  ddsd.dwHeight := RENDER_VIEW_HEIGHT;

  if bpp = 32 then
  begin
    ddsd.lPitch := 4 * RENDER_VIEW_WIDTH; // Display is true color
    if screen16 <> nil then
      memfree(pointer(screen16));
  end
  else if bpp = 16 then
  begin
    ddsd.lPitch := 2 * RENDER_VIEW_WIDTH;
    if screen16 <> nil then
      screen16 := malloc(RENDER_VIEW_WIDTH * RENDER_VIEW_HEIGHT * 2);
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
  memcpy(dest, screen32, RENDER_VIEW_WIDTH * RENDER_VIEW_HEIGHT * SizeOf(LongWord));
end;

procedure I_TranslateBuffer(const buf: PByteArray; const sz: integer);
var
  i: integer;
begin
  for i := 0 to sz - 1 do
    if buf[i] = 0 then
      buf[i] := approx_zero;
end;

end.


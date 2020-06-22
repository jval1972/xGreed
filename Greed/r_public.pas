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

unit r_public;

interface

uses
  g_delphi,
  r_public_h,
  r_refdef;

(**** VARIABLES ****)
var
  windowHeight: integer = INIT_VIEW_HEIGHT;
  windowWidth: integer = INIT_VIEW_WIDTH;
  windowLeft: integer = 0;
  windowTop: integer = 0;
  windowSize: integer = INIT_VIEW_HEIGHT * INIT_VIEW_WIDTH;
  viewLocation: pointer;
  CENTERX: fixed_t = INIT_VIEW_WIDTH div 2;
  CENTERY: fixed_t = INIT_VIEW_HEIGHT div 2;
  FSCALE: fixed_t;
  ISCALE: fixed_t;
  backtangents: array[0..TANANGLES * 2 - 1] of integer;
  autoangle2: array[0..MAXAUTO - 1, 0..MAXAUTO - 1] of integer;
  scrollmin, scrollmax, bloodcount, metalcount: integer;
  actionhook: PProcedure;

function FIXEDMUL(const a, b: fixed_t): fixed_t; assembler;

function FIXEDDIV(const a, b: fixed_t): fixed_t;

procedure RF_PreloadGraphics;

function RF_GetSprite: Pscaleobj_t;

function RF_GetElevator: Pelevobj_t;

procedure RF_RemoveElevator(const e: Pelevobj_t);

function RF_GetFloorZ(const x, y: fixed_t): fixed_t;

function RF_GetCeilingZ(const x, y: fixed_t): fixed_t;

function RF_GetSpawnArea: Pspawnarea_t;

procedure RF_RemoveSprite(const spr: Pscaleobj_t);

procedure RF_ClearWorld;

function RF_GetDoor(const tilex, tiley: integer): Pdoorobj_t;

procedure RF_SetActionHook(const hook: PProcedure);

procedure RF_SetLights(const ablackz: fixed_t);

procedure RF_RenderView(const x, y, z: fixed_t; const angle: integer);

procedure RF_Startup;

procedure SetViewSize(const awidth, aheight: integer);

implementation

uses
  Math,
  d_disk,
  d_ints,
  d_misc,
  modplay,
  raven,
  r_conten,
  r_render,
  r_spans,
  r_walls,
  spawn;

function FIXEDMUL(const a, b: fixed_t): fixed_t; assembler;
asm
  imul b
  shrd eax, edx, 16
end;

function FIXEDDIV2(const a, b: fixed_t): fixed_t; assembler;
asm
  mov ebx, b
  mov edx, eax
  sal eax, 16
  sar edx, 16
  idiv ebx
end;

function FIXEDDIV(const a, b: fixed_t): fixed_t;
begin
  if (absI(a) shr 14) >= absI(b) then
  begin
    if a xor b < 0 then
      result := MININT
    else
      result := MAXINT;
  end
  else
    result := FixedDiv2(a, b);
end;

procedure RF_PreloadGraphics;
var
  i: integer;
  doorlump: integer;
begin
  // find the number of lumps of each type
  spritelump := CA_GetNamedNum('startsprites');
  numsprites := CA_GetNamedNum('endsprites') - spritelump;
  walllump := CA_GetNamedNum('startwalls');
  numwalls := CA_GetNamedNum('endwalls') - walllump;
  flatlump := CA_GetNamedNum('startflats');
  numflats := CA_GetNamedNum('endflats') - flatlump;
  doorlump := CA_GetNamedNum('door_1');
  printf('RF_PreloadGraphics().');
  // load the lumps
  for i := 1 to numsprites - 1 do
  begin
    DemandLoadMonster(spritelump + i, 1);
//   CA_CacheLump(spritelump+i);
    if i mod 50 = 0 then
    begin
      printf('.');
      if newascii and (lastascii = #27) then
      begin
        printf('.Aborted!'#13#10);
        exit;
      end;
    end;

  end;
  printf('.');
  if not debugmode then
  begin
    for i := doorlump to numwalls + walllump - 1 do
      CA_CacheLump(i);
  end
  else
  begin
    CA_CacheLump(walllump + 1);
    CA_CacheLump(flatlump + 1);
  end;
  printf('.Done!'#13#10);
end;


procedure RF_InitTargets;
var
  at, atf: double;
  j, angle, x1, y1, i: integer;
  x, y: fixed_t;
begin
  for i := 0 to MAXAUTO - 1 do
    for j := 0 to MAXAUTO - 1 do
      autoangle2[i, j] := -1;
  i := 0;
  repeat
    at := ArcTan(i / MAXAUTO);
    atf := at * ANGLES / (2 * PI);
    angle := rint(atf);
    for j := 0 to MAXAUTO * 2 - 1 do
    begin
      y := FIXEDMUL(sintable[angle], j * FRACUNIT);
      x := FIXEDMUL(costable[angle], j * FRACUNIT);
      x1 := x div FRACUNIT;
      y1 := y div FRACUNIT;
      if (x1 >= MAXAUTO) or (y1 >= MAXAUTO) or (autoangle2[x1][y1] <> -1) then
        continue;
      autoangle2[x1][y1] := angle;
    end;
    inc(i);
  until angle >= DEGREE45 + DEGREE45_2;

  for i := MAXAUTO - 1 downto 1 do
    for j := 0 to MAXAUTO - 1 do
      if autoangle2[j][i] = -1 then
        autoangle2[j][i] := autoangle2[j][i - 1];
  for i := MAXAUTO - 1 downto 1 do
    for j := 0 to MAXAUTO - 1 do
      if autoangle2[j][i] = -1 then
        autoangle2[j][i] := autoangle2[j][i - 1];
end;


// Builds tangent tables for -90 degrees to +90 degrees
// and pixel angle table
procedure InitTables;
var
  tang, value, ivalue: double;
  intval, i: integer;
begin
  // tangent values for wall tracing
  for i := 0 to TANANGLES div 2 - 1 do
  begin
    tang := (i + 0.5) * PI / (TANANGLES * 2);
    value := tan(tang);
    ivalue := 1 / value;
    value := rint(value * FRACUNIT);
    ivalue := rint(ivalue * FRACUNIT);
    tangents[TANANGLES + i] := trunc(-value);
    tangents[TANANGLES + TANANGLES - 1 - i] := trunc(-ivalue);
    tangents[i] := trunc(ivalue);
    tangents[TANANGLES - 1 - i] := trunc(value);
  end;
  // high precision sin / cos for distance calculations
  for i := 0 to TANANGLES - 1 do
  begin
    tang := (i + 0.5) * PI / (TANANGLES * 2);
//   tang := i*PI/(TANANGLES*2);
    value := sin(tang);
    intval := rint(value * FRACUNIT);
    sines[i] := intval;
    sines[TANANGLES * 4 + i] := intval;
    sines[TANANGLES * 2 - 1 - i] := intval;
    sines[TANANGLES * 2 + i] := -intval;
    sines[TANANGLES * 4 - 1 - i] := -intval;
  end;
  cosines := @sines[TANANGLES];
  for i := 0 to TANANGLES * 2 - 1 do
    backtangents[i] := ((windowWidth div 2) * tangents[i]) div FRACUNIT;
end;


procedure InitReverseCam;
var
  i, intval: integer;
begin
  for i := 0 to 64 do
  begin
    intval := rint(arctan((32.0 - (i + 1.0)) / 32.0) / PI * TANANGLES * 2.0);
    pixelangle[i] := intval;
    pixelcosine[i] := cosines[intval and (TANANGLES * 4 - 1)];
  end;
  memcpy(@campixelangle, @pixelangle, SizeOf(pixelangle));
  memcpy(@campixelcosine, @pixelcosine, SizeOf(pixelcosine));
end;


procedure RF_Startup;
var
  i: integer;
  angle: double;
  lightlump: integer;
begin
  memset(@framevalid, 0, SizeOf(framevalid));
  printf('RF_Startup().');
  frameon := 0;
  // trig tables
  for i := 0 to ANGLES do
  begin
    angle := (i * PI * 2) / (ANGLES + 1);
    sintable[i] := rint(sin(angle) * FRACUNIT);
    costable[i] := rint(cos(angle) * FRACUNIT);
  end;
  printf('.');
  SetViewSize(windowWidth, windowHeight);
  // set up lights
  // Allocates a page aligned buffer and load in the light tables
  lightlump := CA_GetNamedNum('lights');
  numcolormaps := infotable[lightlump].size div 256;
  colormaps := malloc(256 * (numcolormaps));
  //colormaps := (byte *)(((int)colormaps+255)) and (~0xff);// JVAL: Removed align
  CA_ReadLump(lightlump, colormaps);
  RF_SetLights(MAXZ);
  RF_ClearWorld;
  printf('.');
  // initialize the translation to no animation
  flattranslation := malloc((numflats + 1) * 4);
  walltranslation := malloc((numwalls + 1) * 4);
  if not debugmode then
  begin
    for i := 0 to numflats do flattranslation[i] := i;
    for i := 0 to numwalls do walltranslation[i] := i;
  end
  else
  begin
    flattranslation[0] := 0;
    walltranslation[0] := 0;
    for i := 1 to numflats do flattranslation[i] := 1;
    for i := 1 to numwalls do walltranslation[i] := 1;
  end;
  actionhook := nil;
  actionflag := 0;
  RF_InitTargets;
  InitTables;
  printf('.');
  InitReverseCam;
  InitWalls;
  printf('.Done!'#13#10);
end;


procedure RF_ClearWorld;
var
  i: integer;
begin
  firstscaleobj.prev := nil;
  firstscaleobj.next := @lastscaleobj;
  lastscaleobj.prev := @firstscaleobj;
  lastscaleobj.next := nil;
  freescaleobj_p := @scaleobjlist[0];
  memset(@scaleobjlist, 0, SizeOf(scaleobjlist));
  for i := 0 to MAXSPRITES - 2 do
    scaleobjlist[i].next := @scaleobjlist[i + 1];
  firstelevobj.prev := nil;
  firstelevobj.next := @lastelevobj;
  lastelevobj.prev := @firstelevobj;
  lastelevobj.next := nil;
  freeelevobj_p := @elevlist[0];
  memset(@elevlist, 0, SizeOf(elevlist));
  for i := 0 to MAXELEVATORS - 2 do
    elevlist[i].next := @elevlist[i + 1];
  numdoors := 0;
  numspawnareas := 0;
  bloodcount := 0;
  metalcount := 0;
end;


function RF_GetDoor(const tilex, tiley: integer): Pdoorobj_t;
var
  door: Pdoorobj_t;
begin
  if numdoors = MAXDOORS then
    MS_Error('RF_GetDoor(): Too many doors placed! (%d)', [MAXDOORS]);
  door := @doorlist[numdoors];
  inc(numdoors);
  door.tilex := tilex;
  door.tiley := tiley;
  mapflags[tiley * MAPROWS + tilex] := mapflags[tiley * MAPROWS + tilex] or FL_DOOR;
  result := door;
end;


// returns a new sprite
function RF_GetSprite: Pscaleobj_t;
begin
  if freescaleobj_p = nil then
    MS_Error('RF_GetSprite(): Out of spots in scaleobjlist!');
  result := freescaleobj_p;
  freescaleobj_p := freescaleobj_p.next;
  memset(result, 0, SizeOf(scaleobj_t));
  result.next := @lastscaleobj;
  result.prev := lastscaleobj.prev;
  lastscaleobj.prev := result;
  result.prev.next := result;
end;


// returns a elevator structure
function RF_GetElevator: Pelevobj_t;
begin
  if  freeelevobj_p = nil then
    MS_Error('RF_GetElevator(): Too many elevators placed!');
  result := freeelevobj_p;
  freeelevobj_p := freeelevobj_p.next;
  memset(result, 0, SizeOf(elevobj_t));
  result.next := @lastelevobj;
  result.prev := lastelevobj.prev;
  lastelevobj.prev := result;
  result.prev.next := result;
end;


function RF_GetSpawnArea: Pspawnarea_t;
begin
  if numspawnareas = MAXSPAWNAREAS then
    MS_Error('RF_GetSpawnArea(): Too many Spawn Areas placed! (%d)', [MAXSPAWNAREAS]);
  result := @spawnareas[numspawnareas];
  inc(numspawnareas);
end;


// removes sprite from doublely linked list of sprites
procedure RF_RemoveSprite(const spr: Pscaleobj_t);
begin
  spr.next.prev := spr.prev;
  spr.prev.next := spr.next;
  spr.next := freescaleobj_p;
  freescaleobj_p := spr;
end;


procedure RF_RemoveElevator(const e: Pelevobj_t);
begin
  e.next.prev := e.prev;
  e.prev.next := e.next;
  e.next := freeelevobj_p;
  freeelevobj_p := e;
end;


function RF_GetFloorZ(const x, y: fixed_t): fixed_t;
var
  h1, h2, h3, h4: fixed_t;
  tilex, tiley, mapspot: integer;
  polytype: integer;
  fx, fy: fixed_t;
  top, bottom, water: fixed_t;
begin
  tilex := x shr (FRACBITS + TILESHIFT);
  tiley := y shr (FRACBITS + TILESHIFT);
  mapspot := tiley * MAPSIZE + tilex;
  polytype := (mapflags[mapspot] and FL_FLOOR) shr FLS_FLOOR;
  if (floorpic[mapspot] >= 57) and (floorpic[mapspot] <= 59) then
    water := -(20 * FRACUNIT)
  else
    water := 0;
  if polytype = POLY_FLAT then
  begin
    result := (floorheight[mapspot] * FRACUNIT) + water;
    exit;
  end;
  h1 := floorheight[mapspot] * FRACUNIT;
  h2 := floorheight[mapspot + 1] * FRACUNIT;
  h3 := floorheight[mapspot + MAPSIZE] * FRACUNIT;
  h4 := floorheight[mapspot + MAPSIZE + 1] * FRACUNIT;
  fx := (x and (TILEUNIT - 1)) div 64; // range from 0 to fracunit-1
  fy := (y and (TILEUNIT - 1)) div 64;
  if polytype = POLY_SLOPE then
  begin
    if h1 = h2 then
      result := h1 + FIXEDMUL(h3 - h1, fy) + water
    else
      result := h1 + FIXEDMUL(h2 - h1, fx) + water;
    exit;
  end;
  // triangulated slopes
  // set the outside corner of the triangle that the point is NOT in s
  // plane with the other three
  if polytype = POLY_ULTOLR then
  begin
    if fx > fy then
      h3 := h1 - (h2 - h1)
    else
      h2 := h1 + (h1 - h3);
  end
  else
  begin
    if fx < FRACUNIT - fy then
      h4 := h2 + (h2 - h1)
    else
      h1 := h2 - (h4 - h2);
  end;
  top := h1 + FIXEDMUL(h2 - h1, fx);
  bottom := h3 + FIXEDMUL(h4 - h3, fx);
  result := top + FIXEDMUL(bottom - top, fy) + water;
end;


// find how high the ceiling is at x,y
function RF_GetCeilingZ(const x, y: fixed_t): fixed_t;
var
  h1, h2, h3, h4: fixed_t;
  tilex, tiley, mapspot: integer;
  polytype: integer;
  fx, fy: fixed_t;
  top, bottom: fixed_t;
begin
  tilex := x shr (FRACBITS + TILESHIFT);
  tiley := y shr (FRACBITS + TILESHIFT);
  mapspot := tiley * MAPSIZE + tilex;
  polytype := (mapflags[mapspot] and FL_CEILING) shr FLS_CEILING;
  // flat
  if polytype = POLY_FLAT then
  begin
    result := ceilingheight[mapspot] * FRACUNIT;
    exit;
  end;
  // constant slopes
  if polytype = POLY_SLOPE then
  begin
    h1 := ceilingheight[mapspot] * FRACUNIT;
    h2 := ceilingheight[mapspot + 1] * FRACUNIT;
    if h1 = h2 then
    begin
      h3 := ceilingheight[mapspot + MAPSIZE] * FRACUNIT;
      fy := (y and (TILEUNIT - 1)) div 64;
      result := h1 + FIXEDMUL(h3 - h1, fy); // north/south slope
      exit;
    end
    else
    begin
      fx := (x and (TILEUNIT - 1)) div 64;
      result := h1 + FIXEDMUL(h2 - h1, fx); // east/west slope
      exit;
    end;
  end;
  // triangulated slopes
  // set the outside corner of the triangle that the point is NOT in s
  // plane with the other three
  h1 := ceilingheight[mapspot] * FRACUNIT;
  h2 := ceilingheight[mapspot + 1] * FRACUNIT;
  h3 := ceilingheight[mapspot + MAPSIZE] * FRACUNIT;
  h4 := ceilingheight[mapspot + MAPSIZE + 1] * FRACUNIT;
  fx := (x and (TILEUNIT - 1)) div 64; // range from 0 to fracunit-1
  fy := (y and (TILEUNIT - 1)) div 64;
  if polytype = POLY_ULTOLR then
  begin
    if fx > fy then
      h3 := h1 - (h2 - h1)
    else
      h2 := h1 + (h1 - h3);
  end
  else
  begin
    if fx < FRACUNIT - fy then
      h4 := h2 + (h2 - h1)
    else
      h1 := h2 - (h4 - h2);
  end;
  top := h1 + FIXEDMUL(h2 - h1, fx);
  bottom := h3 + FIXEDMUL(h4 - h3, fx);
  result := top + FIXEDMUL(bottom - top, fy);
end;


procedure RF_SetActionHook(const hook: PProcedure);
begin
  actionhook := hook;
  actionflag := 1;
end;

procedure r_publicstub2;
begin
end;


// resets the color maps to new lighting values
procedure RF_SetLights(const ablackz: fixed_t);
var
  i, table: integer;
  blackz: fixed_t;
begin
  // linear diminishing, table is actually logrithmic
  blackz := ablackz div FRACUNIT;
  for i := 0 to MAXZ div FRACUNIT do
  begin
    table := (numcolormaps * i) div blackz;
    if table >= numcolormaps then
      table := numcolormaps - 1;
    zcolormap[i] := @colormaps[table * 256];
  end;
end;


procedure RF_CheckActionFlag;
begin
  if SC.vrhelmet = 0 then
    TimeUpdate;
  if actionflag = 0 then
    exit;
  actionhook;
  actionflag := 0;
end;


procedure RF_RenderView(const x, y, z: fixed_t; const angle: integer);
begin
{$IFDEF VALIDATE}
  if (x <= 0) or (x >= ((MAPSIZE - 1) shl (FRACBITS + TILESHIFT))) or (y <= 0) or (
    y >= ((MAPSIZE - 1) shl (FRACBITS + TILESHIFT))) then
    MS_Error('Invalid RF_RenderView (%d, %d, %d, %d)', [x, y, z, angle]);
{$ENDIF}

// viewx := (x) and (~0xfff) + $800;
// viewy := (y) and (~0xfff) + $800;
// viewz := (z) and (~0xfff) + $800;

  viewx := x;
  viewy := y;
  viewz := z;
  viewangle := angle and ANGLES;
  RF_CheckActionFlag;
  SetupFrame;
  RF_CheckActionFlag;
  FlowView;
  RF_CheckActionFlag;
  RenderSprites;
  DrawSpans;
  RF_CheckActionFlag;
end;


procedure SetViewSize(const awidth, aheight: integer);
var
  i: integer;
  width, height: integer;
begin
  if awidth > MAX_VIEW_WIDTH then
    width := MAX_VIEW_WIDTH
  else
    width := awidth;
  if aheight > MAX_VIEW_HEIGHT then
    height := MAX_VIEW_HEIGHT
  else
    height := aheight;
  windowHeight := height;
  windowWidth := width;
  windowSize := width * height;
  scrollmax := windowHeight + scrollmin;
  CENTERX := width div 2;
  CENTERY := height div 2;
  FSCALE := (width div 2) * FRACUNIT;
  ISCALE := FRACUNIT div (width div 2);

  for i := 0 to height - 1 do
    viewylookup[i] := @viewbuffer[i * width];

// slopes for rows and collumns of screen pixels
// slightly biased to account for the truncation in coordinates
  for i := 0 to width do
    xslope[i] := rint((i + 1 - CENTERX) / CENTERX * FRACUNIT);
  for i := -MAXSCROLL to height + MAXSCROLL - 1 do
    yslope[i + MAXSCROLL] := rint(-(i - 0.5 - CENTERY) / CENTERX * FRACUNIT);
  for i := 0 to TANANGLES * 2 - 1 do
    backtangents[i] := ((width div 2) * tangents[i]) div FRACUNIT;
  hfrac := FIXEDDIV(BACKDROPHEIGHT * FRACUNIT, (windowHeight div 2) * FRACUNIT);
  afrac := FIXEDDIV(TANANGLES * FRACUNIT, width * FRACUNIT);
end;

end.


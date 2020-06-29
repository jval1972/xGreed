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

unit r_render;

interface

uses
  g_delphi,
  r_public_h,
  r_refdef;

const
  MAXENTRIES = 1024;

var
  westwall: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  westflags: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  northwall: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  northflags: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  floorpic: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  floorflags: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  ceilingpic: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  ceilingflags: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  floorheight: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  ceilingheight: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  floordef: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  floordefflags: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  ceilingdef: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  ceilingdefflags: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  maplights: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  mapsprites: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  mapslopes: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  mapeffects: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  mapflags: packed array[0..MAPROWS * MAPCOLS - 1] of byte;
  reallight: array[0..MAPROWS * MAPCOLS - 1] of integer;
  actionflag: integer;
  wallglow, wallglowindex: integer;
  wallrotate: integer;
  maplight: integer;
  wallflicker1, wallflicker2, wallflicker3, wallflicker4, wallflags, wallcycle: integer;

// each visible vertex is used up to four times, so to prevent recalculation
// the vertex info is reused if it has been calculated previously that f
// The calculated flag is also used to determine if a moving sprite is i
// is at least partially visable.
//
// frameon is incremented at the start of each frame, so it is 1 on the
// framevalid[][] holds the frameon number for which vertex[][] is valid
//      set to 0 at initialization, so no points are valid
// cornervertex[][] is a pointer into vertexlist[]
// vertexlist[] holds the currently valid transformed vertexes
// vertexlist_p is set to vertexlist[0] at the start of each frame, and
//      after transforming a new vertex

  frameon: integer;
  framevalid: array[0..MAPROWS * MAPCOLS] of integer;
  framech: array[0..MAPROWS * MAPCOLS] of integer;
  framefl: array[0..MAPROWS * MAPCOLS] of integer;
  cornervertex: array[0..MAPROWS * MAPCOLS] of Pvertex_t;
  vertexlist: array[0..MAXVISVERTEXES{$IFNDEF VALIDATE} - 1{$ENDIF}] of vertex_t;
  vertexlist_p: Pvertex_t;
  costable: array[0..ANGLES] of fixed_t;
  sintable: array[0..ANGLES] of fixed_t;
  viewbuffer: packed array[0..MAX_VIEW_WIDTH * MAX_VIEW_HEIGHT - 1] of pixel_t;
  renderbuffer: packed array[0..RENDER_VIEW_WIDTH * RENDER_VIEW_HEIGHT - 1] of pixel_t;
  viewylookup: array[0..RENDER_VIEW_HEIGHT - 1] of Ppixel_tArray;
  yslope: array[0..RENDER_VIEW_HEIGHT + MAXSCROLL2 - 1] of fixed_t;
  xslope: array[0..RENDER_VIEW_WIDTH] of fixed_t;
  wallposts: PBytePArray;
  colormaps: PByteArray;
  numcolormaps: integer;
  zcolormap: array[0..(MAXZ div FRACUNIT)] of PByteArray;
  viewx, viewy, viewz: fixed_t;
  viewcos, viewsin: fixed_t;
  xscale, yscale: fixed_t;         // FSCALE/viewcos , FSCALE/viewsin
  viewangle, viewfineangle: integer;
  viewtilex, viewtiley: integer;
  vertex: array[0..3] of Pvertex_t;// points to the for corner vertexes in vert
  p1, p2: Pvertex_t;
  side: integer;                   // wall number 0-3
  walltype: integer;               // wall number (picture) of p1-p2 edge
  wallshadow: integer;             // degree of shadow for a tile
  xclipl, xcliph: integer;         // clip window for current tile
  tilex, tiley: integer;           // coordinates of the tile being rendered
  mapspot: integer;                // tiley*MAPSIZE+tilex
  flattranslation: PIntegerArray;  // global animation tables
  walltranslation: PIntegerArray;
  spritelump, walllump, flatlump: integer;
  numsprites, numwalls, numflats: integer;
  doortile: boolean;               // true if the tile being renderd has a door
  adjacentx: array[0..3] of integer = ( 0, 1, 0,-1);
  adjacenty: array[0..3] of integer = (-1, 0, 1, 0);
  entries: array[0..MAXENTRIES{$IFNDEF VALIDATE} - 1{$ENDIF}] of entry_t;
  entry_p: Pentry_t;
  entrymap: array[0..MAPCOLS * MAPROWS - 1] of integer;
  entrycount: array[0..MAPCOLS * MAPROWS - 1] of integer;
  entrycounter: integer;
  fxtimecount: integer;

procedure SetupFrame;

procedure FlowView;

implementation

uses
  d_ints,
  d_misc,
  r_conten,
  r_plane,
  r_public,
  r_spans,
  r_walls;

// Returns a pointer to the vertex for a given coordinate
// tx,tz will be the transformed coordinates
// px, floorheight, ceilingheight will be valid if tz >= MINZ
function TransformVertex(const tilex, tiley: integer): Pvertex_t;
var
  ttrx, ttry, scale: fixed_t;
  point: Pvertex_t;
  mapspot2, fl, ch: integer;
begin
  mapspot2 := tiley * MAPROWS + tilex;
  if mapspot <> mapspot2 then
  begin
    if mapflags[mapspot] and FL_FLOOR <> 0 then
      fl := (floorheight[mapspot2] * FRACUNIT) - viewz
    else
      fl := (floorheight[mapspot] * FRACUNIT) - viewz;
    if mapflags[mapspot] and FL_CEILING <> 0 then
      ch := (ceilingheight[mapspot2] * FRACUNIT) - viewz
    else
      ch := (ceilingheight[mapspot] * FRACUNIT) - viewz;
  end
  else
  begin
    fl := (floorheight[mapspot2] * FRACUNIT) - viewz;
    ch := (ceilingheight[mapspot2] * FRACUNIT) - viewz;
  end;
  if (framevalid[mapspot2] = frameon) and (framefl[mapspot2] = fl) and (framech[mapspot2] = ch) then
  begin
    result := cornervertex[mapspot2];
    exit;
  end;
  point := vertexlist_p;
  inc(vertexlist_p);
{$IFDEF VALIDATE}
  if point = @vertexlist[MAXVISVERTEXES] then
    MS_Error('TransformVertex(): Vertexlist overflow (%d)', [MAXVISVERTEXES]);
{$ENDIF}
  point.floorheight := fl;
  point.ceilingheight := ch;
  ttrx := (_SHL(tilex, (FRACBITS + TILESHIFT))) - viewx;
  ttry := (_SHL(tiley, (FRACBITS + TILESHIFT))) - viewy;
  point.tx := FIXEDMUL(ttrx, viewsin) + FIXEDMUL(ttry, viewcos);
  point.tz := FIXEDMUL(ttrx, viewcos) - FIXEDMUL(ttry, viewsin);
  if point.tz >= MINZ then
  begin
    scale := FIXEDDIV(FSCALE, point.tz);
    point.px := CENTERX + (FIXEDMUL(point.tx, scale) div FRACUNIT);
    point.floory := CENTERY - (FIXEDMUL(point.floorheight, scale) div FRACUNIT);
    point.ceilingy := CENTERY - (FIXEDMUL(point.ceilingheight,scale) div FRACUNIT);
  end;
  framevalid[mapspot2] := frameon;
  cornervertex[mapspot2] := point;
  framefl[mapspot2] := fl;
  framech[mapspot2] := ch;
  result := point;
end;


// Sets p1.px and p2.px correctly for Z values < MINZ
// Returns false if entire edge is too close or far away
function ClipEdge: boolean;
var
  leftfrac, rightfrac, clipz, dx, dz: fixed_t;
begin
  if (p1.tz > MAXZ) and (p2.tz > MAXZ) then
  begin
    result := false; // entire face is too far away
    exit;
  end;
  if (p1.tz <= 0) and (p2.tz <= 0) then
  begin
    result := false; // totally behind the projection plane
    exit;
  end;
  if (p1.tz < MINZ) or (p2.tz < MINZ) then
  begin
    dx :=  p2.tx - p1.tx;
    dz :=  p2.tz - p1.tz;
    if p1.tz < MINZ then
    begin
      if absI(dx + dz) < 1024 then
      begin
        result := false;
        exit;
      end;
      leftfrac :=  FIXEDDIV(-p1.tx - p1.tz, dx + dz);
    end;
    if p2.tz < MINZ then
    begin
      if absI(dz - dx) < 1024 then
      begin
        result := false;
        exit;
      end;
      rightfrac :=  FIXEDDIV(p1.tx - p1.tz , dz - dx);
      if (p1.tz < MINZ) and (rightfrac < leftfrac) then
      begin
        result := false;  // back face
        exit;
      end;
      clipz :=  p1.tz + FIXEDMUL(dz, rightfrac);
      if clipz < 0 then
      begin
        result := false;
        exit;
      end;
      p2.px := windowWidth;
    end;
  end;
  if p1.tz < MINZ then
  begin
    clipz :=  p1.tz + FIXEDMUL(dz, leftfrac);
    if clipz < 0 then
    begin
      result := false;
      exit;
    end;
    p1.px :=  0;
  end;
  result := p1.px <> p2.px;
end;


procedure RenderTileWalls(const e: Pentry_t);
var
  xl, xh, tx, ty, x1, x2: integer;
begin
  tilex := e.tilex;
  tiley := e.tiley;
  xclipl := e.xmin;
  xcliph := e.xmax;
//#ifdef VALIDATE
// if ((tilex<0)) or ((tilex >= MAPCOLS)) or ((tiley<0)) or ((tiley >= MAPROWS)) or ((xclipl<0)) or (
//  (xclipl >= windowWidth)) or ((xcliph<0)) or ((xcliph >= windowWidth)) or ((xclipl>xcliph))
//  MS_Error('Invalid RenderTile (%i, %i, %i, %i)\n', e.tilex, e.tiley,
//  e.xmin, e.xmax);
//{$ENDIF}
  mapspot := tiley * MAPCOLS + tilex;
  maplight := (maplights[mapspot] * 8) + reallight[mapspot];
  wallshadow := mapeffects[mapspot];
  // validate or transform the four corner vertexes
  vertex[0] := TransformVertex(tilex, tiley);
  vertex[1] := TransformVertex(tilex + 1, tiley);
  vertex[2] := TransformVertex(tilex + 1, tiley + 1);
  vertex[3] := TransformVertex(tilex, tiley + 1);
  // handle a door if present
  if mapflags[mapspot] and FL_DOOR <> 0 then
  begin
    doortile := true;
    RenderDoor;      // sets doorxl / doorxh
  end
  else
    doortile := false;
  // draw or flow through the walls
  side := -1;
  while side < 3 do
  begin
    inc(side);
    p1 := vertex[side];
    p2 := vertex[(side + 1) and 3];
    if not ClipEdge then
      continue;
    if p1.px >= p2.px then
      continue;
    case side of
    0: // north
      begin
        walltype := northwall[mapspot];
        wallflags := northflags[mapspot];
      end;
    1: // east
      begin
        walltype := westwall[mapspot + 1];
        wallflags := westflags[mapspot + 1];
      end;
    2: // south
      begin
        walltype := northwall[mapspot + MAPCOLS];
        wallflags := northflags[mapspot + MAPCOLS];
      end;
    3: // west
      begin
        walltype := westwall[mapspot];
        wallflags := westflags[mapspot];
      end;
    end;
    if p1.px < xclipl then
      x1 := xclipl
    else
      x1 := p1.px;
    if p2.px - 1 > xcliph then
      x2 := xcliph
    else
      x2 := p2.px - 1;
    if x1 <= x2 then
    begin // totally clipped off side
      if walltype <> 0 then
        DrawWall(x1, x2);
      DrawSteps(x1, x2);
    end;
    if (walltype = 0) or (wallflags and F_TRANSPARENT <> 0) then
    begin
      // restrict outward flow by the door, if present
      xl := p1.px;
      xh := p2.px - 1;
      // restrict by clipping window
      if xl < xclipl then
        xl := xclipl;
      if xh > xcliph then
        xh := xcliph;
      // flow into the adjacent tile if there is at least a one pix
      if xh >= xl then
      begin
        tx := tilex + adjacentx[side];
        ty := tiley + adjacenty[side];
        if (tx < 0) or (tx >= MAPCOLS - 1) or (ty < 0) or (ty >= MAPROWS - 1) then
          continue;
        entry_p.tilex := tx;
        entry_p.tiley := ty;
        entry_p.xmin := xl;
        entry_p.xmax := xh;
        entry_p.mapspot := (ty * 64) + tx;
        inc(entrycounter);
        entry_p.counter := entrycounter;
        entrycount[entry_p.mapspot] := entrycounter;
        inc(entry_p);
{$IFDEF VALIDATE}
        if entry_p = @entries[MAXENTRIES] then
          MS_Error('RenderTileWalls(): Entry Array OverFlow (%d)', [MAXENTRIES]);
{$ENDIF}
      end;
    end;
  end;
end;


procedure SetupFrame;
var
  i: integer;
begin
  memset(@viewbuffer, 0, windowSize);

  // Clears the wallz array, so posts that fade out into the distance won't block sprites
  for i := 0 to windowWidth - 1 do
    wallz[i] := MAXZ + 1;

  // reset span counters
  numspans := 0;
  transparentposts := 0;
  inc(frameon);
  vertexlist_p := @vertexlist[0];    // put the first transformed vertex

  // special effects
  if rtimecount > fxtimecount then
  begin
    inc(wallglowindex);
    if wallglowindex = 32 then
      wallglowindex := 0;
    if wallglowindex < 16 then
      wallglow := wallglowindex * 2
    else
      wallglow := (32 - wallglowindex) * 2;
    if wallrotate = 63 then
      wallrotate := 0
    else
      inc(wallrotate);
    wallflicker1 := MS_RndT and 63;
    wallflicker2 := MS_RndT and 63;
    wallflicker3 := MS_RndT and 63;
    if frameon and 1 <> 0 then
      wallflicker4 := (MS_RndT mod 63) - 32;
    inc(wallcycle);
    wallcycle := wallcycle and 3;
    fxtimecount := timecount + 5;
  end;

  viewtilex := viewx div TILEFRACUNIT;
  viewtiley := viewy div TILEFRACUNIT;
  viewfineangle := viewangle * FINEUNIT;
  viewcos := costable[viewangle];
  viewsin := sintable[viewangle];
  xscale := FIXEDDIV(viewsin, FSCALE);
  yscale := FIXEDDIV(viewcos, FSCALE);
end;


procedure FlowView;
var
  process_p, nextprocess_p: Pentry_t;
begin
  process_p := @entries[0];
  process_p.tilex := viewtilex;
  process_p.tiley := viewtiley;
  process_p.mapspot := (viewtiley * 64) + viewtilex;
  process_p.xmin := 0;
  process_p.xmax := windowWidth - 1;
  entry_p := process_p;
  inc(entry_p);
  memset(@entrycount, 0, MAPCOLS * MAPROWS * SizeOf(integer));
  entrycounter := 1;
  while LongWord(process_p) < LongWord(entry_p) do
  begin
    if process_p.mapspot = -1 then // entry has been merged
    begin
      inc(process_p);
      continue;
    end;

    // check for mergeable entries
    if entrycount[process_p.mapspot] > process_p.counter then // mergeable tile
    begin
      nextprocess_p := process_p;
      inc(nextprocess_p);
      while LongWord(nextprocess_p) < LongWord(entry_p) do // scan for mergeable entries
      begin
        if nextprocess_p.mapspot = process_p.mapspot then
        begin
          if nextprocess_p.xmin = process_p.xmax + 1 then
            process_p.xmax := nextprocess_p.xmax
          else if nextprocess_p.xmax = process_p.xmin - 1 then
            process_p.xmin := nextprocess_p.xmin
          else // bad merge not
            MS_Error('FlowView(): Bad tile event combination:'#13#10 +
                     ' nextprocess_p := %d process_p := %d'#13#10 +
                     ' nextprocess_p.xmin := %d  nextprocess_p.xmax := %d'#13#10 +
                     ' process_p.xmin := %d  process_p.xmax := %d',
                     [integer(nextprocess_p), integer(process_p),
                      nextprocess_p.xmin, nextprocess_p.xmax,
                      process_p.xmin, process_p.xmax]);
          entrycount[nextprocess_p.mapspot] := 0;
          nextprocess_p.mapspot := -1;
        end;
        inc(nextprocess_p);
      end;
    end;

    // check for a dublicate entry
    if entrymap[process_p.mapspot] <> frameon then
    begin
      entrymap[process_p.mapspot] := frameon;
      RenderTileWalls(process_p);
      RenderTileEnds;
    end;
    inc(process_p);
  end;
end;

end.


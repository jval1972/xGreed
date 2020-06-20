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

unit r_plane;

interface

uses
  g_delphi,
  r_refdef,
  r_public_h;

var
  mr_y, mr_x1, mr_x2: integer; // used by mapplane to calculate texture end
  mr_shadow: integer;          // special lighting effect
  mr_light: integer;
  mr_deltaheight: fixed_t;
  flatpic: integer;
  transparent, ceilingbit: boolean;

var
  // vertexes for drawable polygon
  numvertex: integer;
  vertexy: array[0..4] of integer;
  vertexx: array[0..4] of integer;
  spantype: spanobj_t;


  // vertexes in need of Z clipping
  vertexpt: array[0..4] of clippoint_t;

var  
  // coefficients of the plane equation for sloping polygons
  planeA, planeB, planeC, planeD: float;

procedure RenderTileEnds;
  
implementation

uses
  d_disk,
  {$IFDEF VALIDATE}
  d_misc,
  {$ENDIF}
  r_public,
  r_render,
  r_spans;

procedure COPYFLOOR(const s, d: integer);
begin
  vertexpt[d].tx := vertex[s].tx;
  vertexpt[d].ty := vertex[s].floorheight;
  vertexpt[d].tz := vertex[s].tz;
  vertexpt[d].px := vertex[s].px;
  vertexpt[d].py := vertex[s].floory;
end;

procedure COPYCEILING(const s, d: integer);
begin
  vertexpt[d].tx := vertex[s].tx;
  vertexpt[d].ty := vertex[s].ceilingheight;
  vertexpt[d].tz := vertex[s].tz;
  vertexpt[d].px := vertex[s].px;
  vertexpt[d].py := vertex[s].ceilingy;
end;


// used for flat floors and ceilings, coordinates must be pre clipped
// mr_deltaheight is planeheight - viewheight, with height values increased
// mr_picture and mr_deltaheight are set once per polygon
procedure FlatSpan;
var
  pointz: fixed_t;  // row's distance to view plane
  span_p: Pspan_t;
  span: LongWord;
begin
  pointz := FIXEDDIV(mr_deltaheight, yslope[mr_y + MAXSCROLL]);
  if pointz > MAXZ then
    exit;
  // post the span in the draw list
  span := (pointz * ZTOFRACUNIT) and ZMASK;
  spansx[numspans] := mr_x1;
  span := span or numspans;
  spantags[numspans] := span;
  span_p := @spans[numspans];
  span_p.spantype := spantype;
  span_p.picture := mr_picture;
  span_p.x2 := mr_x2;
  span_p.y := mr_y;
  span_p.shadow := mr_shadow;
  span_p.light := mr_light;
  inc(numspans);
{$IFDEF VALIDATE}
  if numspans >= MAXSPANS then
    MS_Error('FlatSpan(): MAXSPANS exceeded, (%d)', [MAXSPANS]);
{$ENDIF}
end;


// used for sloping floors and ceilings
// planeA, planeB, planeC, planeD must be precalculated
// mr_picture is set once per polygon
procedure SlopeSpan;
var
  pointz, pointz2: fixed_t; // row's distance to view plane
  partial, denom: float;
  span_p: Pspan_t;
  span: LongWord;
begin
  // calculate the Z values for each end of the span
  partial := (planeB / FRACUNIT) * yslope[mr_y + MAXSCROLL] + planeC;
  denom := (planeA / FRACUNIT) * xslope[mr_x1] + partial;
  if denom < 8000 then
    exit;
  pointz := trunc(planeD / denom * FRACUNIT);
  if pointz > MAXZ then
    exit;
  denom := (planeA / FRACUNIT) * xslope[mr_x2] + partial;
  if denom < 8000 then
    exit;
  pointz2 := trunc(planeD / denom * FRACUNIT);
  if pointz2 > MAXZ then
    exit;
  // post the span in the draw list
  span := (pointz * ZTOFRACUNIT) and ZMASK;
  spansx[numspans] := mr_x1;
  span := span or numspans;
  spantags[numspans] := span;
  span_p := @spans[numspans];
  span_p.spantype := spantype;
  span_p.picture := mr_picture;
  span_p.x2 := mr_x2;
  span_p.y := mr_y;
  span_p.yh := pointz2;
  span_p.shadow := mr_shadow;
  span_p.light := mr_light;
  inc(numspans);
{$IFDEF VALIDATE}
  if numspans >= MAXSPANS then
    MS_Error('SlopeSpan(): MAXSPANS exceeded, (%d)', [MAXSPANS]);
{$ENDIF}
end;


// Vertex list must be precliped, convex, and in clockwise order
// Backfaces (not in clockwise order) generate no pixels
// The polygon is divided into trapezoids (from 1 to numvertex-1 can be
// which have a constant slope on both sides
// mr_x1                       screen coordinates of the span to draw, use by map
// mr_x2                       plane to calculate textures at the endpoints
// mr_y                        along with mr_deltaheight
// mr_dest                     pointer inside viewbuffer where span starts
// mr_count                    length of span to draw (mr_x2 - mr_x1)
// spanfunction is a pointer to a function that will handle determining
// in the calculated span (FlatSpan or SlopeSpan)
procedure RenderPolygon(const spanfunction: PProcedure);
var
  stopy: integer;
  leftfrac, rightfrac: fixed_t;
  leftstep, rightstep: fixed_t;
  leftvertex, rightvertex: integer;
  deltax, deltay: integer;
  oldx: integer;
label
  skiprightvertex,
  skipleftvertex;
begin
  // find topmost vertex
  rightvertex := 0; // topmost so far
  for leftvertex := 1 to numvertex - 1 do
    if vertexy[leftvertex] < vertexy[rightvertex] then
      rightvertex := leftvertex;
  // ride down the left and right edges
  mr_y := vertexy[rightvertex];
  leftvertex := rightvertex;
  if mr_y >= scrollmax then
    exit;   // totally off bottom
  repeat
    if mr_y = vertexy[rightvertex] then
    begin
skiprightvertex:
      oldx := vertexx[rightvertex];
      inc(rightvertex);
      if rightvertex = numvertex then
        rightvertex := 0;
      deltay := vertexy[rightvertex] - mr_y;
      if deltay = 0 then
      begin
        if leftvertex = rightvertex then
          exit; // the last edge is exactly horizontal
        goto skiprightvertex;
      end;
      deltax := vertexx[rightvertex] - oldx;
      rightfrac := oldx * FRACUNIT; // fix roundoff
      rightstep := (deltax * FRACUNIT) div deltay;
    end;
    if mr_y = vertexy[leftvertex] then
    begin
skipleftvertex:
      oldx := vertexx[leftvertex];
      dec(leftvertex);
      if leftvertex = -1 then
        leftvertex := numvertex - 1;
      deltay := vertexy[leftvertex] - mr_y;
      if deltay = 0 then
        goto skipleftvertex;
      deltax := vertexx[leftvertex] - oldx;
      leftfrac := oldx * FRACUNIT;  // fix roundoff
      leftstep := (deltax * FRACUNIT) div deltay;
    end;
    if vertexy[rightvertex] < vertexy[leftvertex] then
      stopy := vertexy[rightvertex]
    else
      stopy := vertexy[leftvertex];
    // draw a trapezoid
    if stopy <= scrollmin then
    begin
      leftfrac := leftfrac + leftstep * (stopy - mr_y);
      rightfrac := rightfrac + rightstep * (stopy - mr_y);
      mr_y := stopy;
      continue;
    end;
    if mr_y < scrollmin then
    begin
      leftfrac := leftfrac + leftstep * (scrollmin - mr_y);
      rightfrac := rightfrac + rightstep * (scrollmin - mr_y);
      mr_y := scrollmin;
    end;
    if stopy > scrollmax then
      stopy := scrollmax;
    while mr_y < stopy do
    begin
      mr_x1 := leftfrac div FRACUNIT;
      mr_x2 := rightfrac div FRACUNIT;
      if mr_x1 < xclipl then
        mr_x1 := xclipl;
      if mr_x2 > xcliph then
        mr_x2 := xcliph;
      if (mr_x1 < xcliph) and (mr_x2 > mr_x1) then
        spanfunction; // different functions for flat and slope
      leftfrac := leftfrac + leftstep;
      rightfrac := rightfrac + rightstep;
      inc(mr_y);
    end;
  until (rightvertex = leftvertex) or (mr_y = scrollmax);
end;


// Calculates planeA, planeB, planeC, planeD
// planeD is actually -planeD
// for vertexpt[0-2]
procedure CalcPlaneEquation;
var
  x1, y1, z1: fixed_t;
  x2, y2, z2: fixed_t;
begin
  // calculate two vectors going away from the middle vertex
  x1 := vertexpt[0].tx - vertexpt[1].tx;
  y1 := vertexpt[0].ty - vertexpt[1].ty;
  z1 := vertexpt[0].tz - vertexpt[1].tz;
  x2 := vertexpt[2].tx - vertexpt[1].tx;
  y2 := vertexpt[2].ty - vertexpt[1].ty;
  z2 := vertexpt[2].tz - vertexpt[1].tz;
  // the A, B, C coefficients are the cross product of v1 and v2
  // shift over to save some precision bits
  planeA := (((y1 / FRACUNIT * z2) - (z1 / FRACUNIT * y2)) / 256);
  planeB := (((z1 / FRACUNIT * x2) - (x1 / FRACUNIT * z2)) / 256);
  planeC := (((x1 / FRACUNIT * y2) - (y1 / FRACUNIT * x2)) / 256);
  // calculate D based on A,B,C and one of the vertex points
  planeD := (planeA * vertexpt[0].tx / FRACUNIT) +
            (planeB * vertexpt[0].ty / FRACUNIT) +
            (planeC * vertexpt[0].tz / FRACUNIT);
end;


function ZClipPolygon(const numvertexpts: integer; zmin: fixed_t): boolean;
var
  v: integer;
  scale: fixed_t;
  frac, cliptx, clipty: fixed_t;
  p1, p2: Pclippoint_t;
begin
  numvertex := 0;
  if zmin < MINZ then
    zmin := MINZ; // less than this will cause problems
  p1 := @vertexpt[0];
  for v := 1 to numvertexpts do
  begin
    p2 := p1; // p2 is old point
    if v <> numvertexpts then
      p1 := @vertexpt[v]  // p1 is new point
    else
      p1 := @vertexpt[0];
    if (p1.tz < zmin) xor (p2.tz < zmin) then
    begin
      scale := FIXEDDIV(FSCALE, zmin);
      frac := FIXEDDIV((p1.tz - zmin), (p1.tz - p2.tz));
      cliptx := p1.tx + FIXEDMUL((p2.tx - p1.tx), frac);
      clipty := p1.ty + FIXEDMUL((p2.ty - p1.ty), frac);
      vertexx[numvertex] := CENTERX + (FIXEDMUL(cliptx, scale) div FRACUNIT);
      vertexy[numvertex] := CENTERY - (FIXEDMUL(clipty, scale) div FRACUNIT);
      if ceilingbit and (vertexy[numvertex] > 640) then
      begin
        result := false;
        exit;
      end;
      inc(numvertex);
    end;
    if p1.tz >= zmin then
    begin
      vertexx[numvertex] := p1.px;
      vertexy[numvertex] := p1.py;
      if ceilingbit and (vertexy[numvertex] > 640) then
      begin
        result := false;
        exit;
      end;
      inc(numvertex);
    end;
  end;
  result := numvertex <> 0;
end;


// draw floor and ceiling for tile
procedure RenderTileEnds;
var
  flags, polytype: integer;
begin
  inc(xcliph);
  flags := mapflags[mapspot];
  // draw the floor
  flatpic := floorpic[mapspot];
  mr_shadow := mapeffects[mapspot];

  if mr_shadow = 1 then
    mr_shadow := integer(@colormaps[wallglow shl 8])
  else if mr_shadow = 2 then
    mr_shadow := integer(@colormaps[wallflicker1 shl 8])
  else if mr_shadow = 3 then
    mr_shadow := integer(@colormaps[wallflicker2 shl 8])
  else if mr_shadow = 4 then
    mr_shadow := integer(@colormaps[wallflicker3 shl 8])
  else if (mr_shadow >= 5) and (mr_shadow <= 8) then
  begin
    if (wallcycle = mr_shadow - 5) then
      mr_shadow := integer(@colormaps)
    else
      mr_shadow := 0;
  end;
  mr_light := maplight;
  flatpic := flattranslation[flatpic];
  mr_picture := lumpmain[flatlump + flatpic];
  polytype := (flags and FL_FLOOR) shr FLS_FLOOR;
  ceilingbit := false;
  case polytype of
  POLY_FLAT:
    begin
      spantype := sp_flat;
      mr_deltaheight := vertex[0].floorheight;
      if mr_deltaheight < 0 then
      begin
        COPYFLOOR(0, 0);
        COPYFLOOR(1, 1);
        COPYFLOOR(2, 2);
        COPYFLOOR(3, 3);
        if ZClipPolygon(4, -mr_deltaheight) then
          RenderPolygon(FlatSpan);
      end;
    end;

  POLY_SLOPE:
    begin
      spantype := sp_slope;
      COPYFLOOR(0, 0);
      COPYFLOOR(1, 1);
      COPYFLOOR(2, 2);
      COPYFLOOR(3, 3);
      CalcPlaneEquation;
      if ZClipPolygon(4, MINZ) then
        RenderPolygon(SlopeSpan);
    end;

  POLY_ULTOLR:
    begin
      spantype := sp_slope;
      COPYFLOOR(0, 0);
      COPYFLOOR(1, 1);
      COPYFLOOR(2, 2);
      CalcPlaneEquation;
      if ZClipPolygon(3, MINZ) then
        RenderPolygon(SlopeSpan);
      COPYFLOOR(2, 0);
      COPYFLOOR(3, 1);
      COPYFLOOR(0, 2);
      CalcPlaneEquation;
      if ZClipPolygon(3, MINZ) then
        RenderPolygon(SlopeSpan);
    end;

  POLY_URTOLL:
    begin
      spantype := sp_slope;
      COPYFLOOR(0, 0);
      COPYFLOOR(1, 1);
      COPYFLOOR(3, 2);
      CalcPlaneEquation;
      if ZClipPolygon(3, MINZ) then
        RenderPolygon(SlopeSpan);
      COPYFLOOR(1, 0);
      COPYFLOOR(2, 1);
      COPYFLOOR(3, 2);
      CalcPlaneEquation;
      if ZClipPolygon(3, MINZ) then
        RenderPolygon(SlopeSpan);
    end;
  end;
  // draw the ceiling
  ceilingbit := true;
  flatpic := ceilingpic[mapspot];
  transparent := ceilingflags[mapspot] and F_TRANSPARENT <> 0;
  flatpic := flattranslation[flatpic];
  mr_picture := lumpmain[flatlump + flatpic];
  polytype := (flags and FL_CEILING) shr FLS_CEILING;
  case polytype of
  POLY_FLAT:
    begin
      if flatpic = 63 then
        spantype := sp_sky
      else if transparent then
        spantype := sp_flatsky
      else
        spantype := sp_flat;
      mr_deltaheight := vertex[0].ceilingheight;
      if mr_deltaheight > 0 then
      begin
        COPYCEILING(3, 0);
        COPYCEILING(2, 1);
        COPYCEILING(1, 2);
        COPYCEILING(0, 3);
        if ZClipPolygon(4, mr_deltaheight) then
          RenderPolygon(FlatSpan);
      end;
    end;

  POLY_SLOPE:
    begin
      if flatpic = 63 then
        spantype := sp_sky
      else if transparent then
        spantype := sp_slopesky
      else
        spantype := sp_slope;
      COPYCEILING(3, 0);
      COPYCEILING(2, 1);
      COPYCEILING(1, 2);
      COPYCEILING(0, 3);
      CalcPlaneEquation;
      if ZClipPolygon(4, MINZ) then
        RenderPolygon(SlopeSpan);
    end;

  POLY_ULTOLR:
    begin
      if flatpic = 63 then
        spantype := sp_sky
      else if transparent then
        spantype := sp_slopesky
      else
        spantype := sp_slope;
      COPYCEILING(3, 0);
      COPYCEILING(2, 1);
      COPYCEILING(1, 2);
      CalcPlaneEquation;
      if ZClipPolygon(3, MINZ) then
        RenderPolygon(SlopeSpan);
      COPYCEILING(3, 0);
      COPYCEILING(1, 1);
      COPYCEILING(0, 2);
      CalcPlaneEquation;
      if ZClipPolygon(3, MINZ) then
        RenderPolygon(SlopeSpan);
    end;

  POLY_URTOLL:
    begin
      if flatpic = 63 then
        spantype := sp_sky
      else if transparent then
        spantype := sp_slopesky
      else
        spantype := sp_slope;
      COPYCEILING(3, 0);
      COPYCEILING(2, 1);
      COPYCEILING(0, 2);
      CalcPlaneEquation;
      if ZClipPolygon(3, MINZ) then
        RenderPolygon(SlopeSpan);
      COPYCEILING(2, 0);
      COPYCEILING(1, 1);
      COPYCEILING(0, 2);
      CalcPlaneEquation;
      if ZClipPolygon(3, MINZ) then
        RenderPolygon(SlopeSpan);
    end;
  end;
end;

end.


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

unit r_walls;

interface

uses
  g_delphi,
  r_refdef,
  r_public_h;

var
  tangents: array[0..TANANGLES * 2 - 1] of fixed_t;
  sines: array[0..TANANGLES * 5 - 1] of fixed_t;
  cosines: Pfixed_tArray; // point 1/4 phase into sines
  pixelangle: array[0..MAX_VIEW_WIDTH] of integer;
  pixelcosine: array[0..MAX_VIEW_WIDTH] of fixed_t;
  wallz: array[0..MAX_VIEW_WIDTH - 1] of fixed_t;  // pointx
  tpwalls_dest: array[0..MAXPEND - 1] of PByteArray;
  tpwalls_colormap: array[0..MAXPEND - 1] of PByteArray;
  tpwalls_count: array[0..MAXPEND - 1] of integer;
  transparentposts: integer;
  wallpixelangle: array[0..MAX_VIEW_WIDTH] of integer;
  wallpixelcosine: array[0..MAX_VIEW_WIDTH] of fixed_t;
  campixelangle: array[0..MAX_VIEW_WIDTH] of integer;
  campixelcosine: array[0..MAX_VIEW_WIDTH] of fixed_t;

procedure InitWalls;

procedure DrawWall(const x1, x2: integer);

procedure DrawSteps(const x1, x2: integer);

implementation

uses
  d_disk,
  {$IFDEF VALIDATE}
  d_misc,
  {$ENDIF}
  raven,
  r_public,
  r_render,
  r_spans;

// calculate the angle deltas for each view post
// VIEWWIDTH view posts covers TANANGLES angles
// traces go through the RIGHT EDGE of the pixel to follow the direction
procedure InitWalls;
var
  intval, i: integer;
begin
  for i := 0 to windowWidth do
  begin
    intval := rint(ArcTan((CENTERX - (i + 1.0)) / CENTERX) / g_PI * TANANGLES * 2);
    pixelangle[i] := intval;
    pixelcosine[i] := cosines[intval and (TANANGLES * 4 - 1)];
  end;
  memcpy(@wallpixelangle, @pixelangle, SizeOf(pixelangle));
  memcpy(@wallpixelcosine, @pixelcosine, SizeOf(pixelcosine));
end;


// Draws the wall on side from p1.px to p2.px-1 with wall picture wall
// p1/p2 are projected and Z clipped, but unclipped to the view window
procedure DrawWall(const x1, x2: integer);
var
  baseangle: integer;
  postindex: PBytePArray;   // start of the 64 entry texture table for t
  distance: fixed_t;        // horizontal / vertical dist to wall segmen
  pointz: fixed_t;          // transformed distance to wall post
  anglecos: fixed_t;
  textureadjust: fixed_t;   // the amount the texture p1ane is shifted
  ceiling: fixed_t;         // top of the wall
  floor: fixed_t;           // bottom of the wall
  top, bottom: fixed_t;     // precise y coordinates for post
  scale: fixed_t;
  topy, bottomy: integer;   // pixel y coordinates for post
  fracadjust: fixed_t;      // the amount to prestep for the top pixel
  angle: integer;           // the ray angle that strikes the current po
  texture: integer;         // 0-63 post number
  x: integer;               // collumn and ranges
  light: integer;
  wall: PSmallInt;
  span: LongWord;
  span_p: Pspan_t;
  rotateright, rotateleft, transparent, rotateup, rotatedown, invisible: integer;
begin
  walltype := walltranslation[walltype];        // global animation
  wall := lumpmain[walllump + walltype];        // to get wall height
  postindex := @wallposts[(walltype - 1) * 64];  // 64 pointers to texture start
  baseangle := viewfineangle;
  transparent := wallflags and F_TRANSPARENT;
  floor := floorheight[mapspot];
  ceiling := ceilingheight[mapspot];
  case side of
  0:  // south facing wall
    begin
      distance := viewy - (tiley * FRACTILEUNIT);
      textureadjust := viewx;
      baseangle := baseangle + TANANGLES * 2;
      if transparent <> 0 then
        player.northmap[mapspot] := TRANS_COLOR
      else
        player.northmap[mapspot] := WALL_COLOR;
      if mapflags[mapspot] and (FL_CEILING + FL_FLOOR) <> 0 then
      begin
        if floorheight[mapspot + 1] < floor then
          floor := floorheight[mapspot + 1];
        if ceilingheight[mapspot + 1] > ceiling then
          ceiling := ceilingheight[mapspot + 1];
      end;
    end;
  1:  // west facing wall
    begin
      distance := ((tilex + 1) * FRACTILEUNIT) - viewx;
      textureadjust := viewy;
      baseangle := baseangle + TANANGLES;
      if transparent <> 0 then
        player.westmap[mapspot + 1] := TRANS_COLOR
      else
        player.westmap[mapspot + 1] := WALL_COLOR;
      if mapflags[mapspot] and (FL_CEILING + FL_FLOOR) <> 0 then
      begin
        if floorheight[mapspot + MAPCOLS + 1] < floor then
          floor := floorheight[mapspot + MAPCOLS + 1];
        if ceilingheight[mapspot + MAPCOLS + 1] > ceiling then
          ceiling := ceilingheight[mapspot + MAPCOLS + 1];
      end;
    end;
  2:  // north facing wall
    begin
      distance := ((tiley + 1) * FRACTILEUNIT) - viewy;
      textureadjust := -viewx;
      baseangle := baseangle + TANANGLES * 2;
      if transparent <> 0 then
        player.northmap[mapspot + MAPCOLS] := TRANS_COLOR
      else
        player.northmap[mapspot+MAPCOLS] := WALL_COLOR;
      if mapflags[mapspot] and (FL_CEILING + FL_FLOOR) <> 0 then
      begin
        if floorheight[mapspot + MAPCOLS + 1] < floor then
          floor := floorheight[mapspot + MAPCOLS+  1];
        if ceilingheight[mapspot + MAPCOLS + 1] > ceiling then
          ceiling := ceilingheight[mapspot + MAPCOLS + 1];
      end;
    end;
  3:  // east facing wall
    begin
      distance := viewx - (tilex * FRACTILEUNIT);
      textureadjust := -viewy;
      baseangle := baseangle + TANANGLES;
      if transparent <> 0 then
        player.westmap[mapspot] := TRANS_COLOR
      else
        player.westmap[mapspot] := WALL_COLOR;
      if mapflags[mapspot] and (FL_CEILING + FL_FLOOR) <> 0 then
      begin
        if floorheight[mapspot + MAPCOLS] < floor then
          floor := floorheight[mapspot + MAPCOLS];
        if ceilingheight[mapspot + MAPCOLS] > ceiling then
          ceiling := ceilingheight[mapspot + MAPCOLS];
      end;
    end;
  end;

  // the floor and ceiling height is the max of the points
  ceiling := (ceiling * FRACUNIT) - viewz;
  floor := -((floor * FRACUNIT) - viewz);   // distance below vi
  sp_loopvalue := (wall^ * 4) * FRACUNIT - 1;

  (* special effects *)
  if wallshadow = 1 then
    sp_colormap := @colormaps[wallglow * 256]
  else if wallshadow = 2 then
    sp_colormap := @colormaps[wallflicker1 * 256]
  else if wallshadow = 3 then
    sp_colormap := @colormaps[wallflicker2 * 256]
  else if wallshadow = 4 then
    sp_colormap := @colormaps[wallflicker3 * 256]
  else if (wallshadow >= 5) and (wallshadow <= 8) then
  begin
    if wallcycle = wallshadow - 5 then
      sp_colormap := colormaps
    else
    begin
      light := (pointz div FRACUNIT) + maplight;
      if light > MAXZLIGHT then
        light := MAXZLIGHT
      else if light < 0 then
        light := 0;
      sp_colormap := zcolormap[light];
    end;
  end;

  rotateleft := wallflags and F_LEFT;
  rotateright := wallflags and F_RIGHT;
  rotateup := wallflags and F_UP;
  rotatedown := wallflags and F_DOWN;
  invisible := wallflags and F_DAMAGE;

  // step through the individual posts
  for x := x1 to x2 do
  begin
    // first do the z clipping
    angle := baseangle + pixelangle[x];
    angle := angle and (TANANGLES * 2 - 1);
    anglecos := cosines[(angle - TANANGLES) and (TANANGLES * 4 - 1)];
    {$IFDEF USEFLOATPOINT}
    pointz := rint(distance / anglecos * pixelcosine[x]);
    {$ELSE}
    pointz := FIXEDDIV(distance, anglecos);
    pointz := FIXEDMUL(pointz, pixelcosine[x]);
    {$ENDIF}
    if pointz > MAXZ then
      exit;
    if pointz < MINZ then
      continue;

    // wall special effects
    if wallshadow = 0 then
    begin
      light := (pointz div FRACUNIT) + maplight;
      if light > MAXZLIGHT then
        light := MAXZLIGHT
      else if light < 0 then
        light := 0;
      sp_colormap := zcolormap[light];
    end
    else if wallshadow = 9 then
    begin
      light := (pointz div FRACUNIT) + maplight + wallflicker4;
      if light > MAXZLIGHT then
        light := MAXZLIGHT
      else if light < 0 then
        light := 0;
      sp_colormap := zcolormap[light];
    end;

    // calculate the texture post along the wall that was hit
    texture := (textureadjust + FIXEDMUL(distance, tangents[angle])) div FRACUNIT;

    if rotateright <> 0 then
      texture := texture - wallrotate
    else if rotateleft <> 0 then
      texture := texture + wallrotate
    else if (x = x1) and (x <> 0) then
      texture := 0; // fix the incorrect looping problem
    texture := texture and 63;

    sp_source := postindex[texture];
    if transparent = 0 then
      wallz[x] := pointz;

    // calculate the size and scale of the post
    sp_fracstep := FIXEDMUL(pointz, ISCALE);
    scale := sp_fracstep;
    if scale < 1000 then
      continue;

    top := FIXEDDIV(ceiling, scale) + FRACUNIT;
    topy := CENTERY - (top div FRACUNIT);
    fracadjust := top and (FRACUNIT - 1);
    sp_frac := FIXEDMUL(fracadjust, sp_fracstep);

    if rotatedown <> 0 then
      sp_frac := sp_frac + FRACUNIT * (63 - wallrotate)
    else if rotateup <> 0 then
      sp_frac := sp_frac + FRACUNIT * wallrotate;

    if topy < scrollmin then
    begin
      sp_frac := sp_frac + (scrollmin - topy) * scale;
      while sp_frac > sp_loopvalue do
        sp_frac := sp_frac - sp_loopvalue - 1;
      topy := scrollmin;
    end;
    bottom := FIXEDDIV(floor, scale) + FRACUNIT * 2;
    if bottom >= (CENTERY + scrollmin) * FRACUNIT then
      bottomy :=  scrollmax - 1
    else
      bottomy := CENTERY + (bottom div FRACUNIT);
    if (bottomy < scrollmin) or (topy >= scrollmax) or (topy = bottomy) then
      continue;

    sp_count := bottomy - topy + 1;

    sp_dest := @viewylookup[bottomy - scrollmin][x];
    if transparent <> 0 then
    begin
      span := (pointz * ZTOFRACUNIT) and ZMASK;
      spansx[numspans] := x;
      span := span or numspans;
      spantags[numspans] := span;
      span_p := @spans[numspans];
      if invisible <> 0 then
        span_p.spantype := sp_inviswall
      else
        span_p.spantype := sp_transparentwall;
      span_p.picture := sp_source;
      span_p.y := sp_frac;           // store info in span structure
      span_p.yh := sp_fracstep;
      span_p.x2 := transparentposts; // post index
      span_p.light := wall^ * 4;
      inc(numspans);
      tpwalls_dest[transparentposts] := sp_dest;
      tpwalls_colormap[transparentposts] := sp_colormap;
      tpwalls_count[transparentposts] := sp_count;
      inc(transparentposts);
{$IFDEF VALIDATE}
      if transparentposts >= MAXPEND then
        MS_Error('Too many Pending Posts! (%d)', [MAXPEND]);
      if numspans >= MAXSPANS then
        MS_Error('MAXSPANS exceeded, Walls (%d)', [MAXSPANS]);
{$ENDIF}
    end
    else
      ScalePost;
  end;
end;


procedure DrawSteps(const x1, x2: integer);
var
  baseangle: integer;
  postindex1, postindex2: PBytePArray; // start of the 64 entry texture table for t
  distance: fixed_t;       // horizontal / vertical dist to wall segmen
  pointz: fixed_t;         // transformed distance to wall post
  anglecos: fixed_t;
  textureadjust: fixed_t;  // the amount the texture p1ane is shifted
  ceiling1, ceiling2: fixed_t; // top of the wall
  floor1, floor2: fixed_t;     // bottom of the wall
  top, bottom: fixed_t;    // precise y coordinates for post
  scale: fixed_t;
  cclip1: fixed_t;
  topy, bottomy: integer;  // pixel y coordinates for post
  fracadjust: fixed_t;     // the amount to prestep for the top pixel
  angle: integer;          // the ray angle that strikes the current po
  texture, texture2: integer; // 0-63 post number
  x: integer;      // collumn and ranges
  light: integer;
  wall1, wall2: PSmallInt;
  span: LongWord;
  span_p: Pspan_t;
  walltype1, walltype2, c, rotateright1, rotateright2: integer;
  rotateleft1, rotateleft2, tm: integer;
  rotateup1, rotateup2, rotatedown1, rotatedown2: integer;
  floor, ceiling: boolean;
label
  ceilingstep,
  skipceilingcalc,
  contceiling;
begin
  floor := false;
  ceiling := false;
  if mapflags[mapspot] and FL_FLOOR <> 0 then
    goto ceilingstep;
  baseangle := viewfineangle;
  case side of
  0:  // south facing wall
    begin
      distance := viewy - (tiley * FRACTILEUNIT);
      textureadjust := viewx;
      baseangle := baseangle + TANANGLES * 2;
      tm := mapspot - MAPCOLS;
    end;

  1:  // west facing wall
    begin
      distance := ((tilex + 1) * FRACTILEUNIT) - viewx;
      textureadjust := viewy;
      baseangle := baseangle + TANANGLES;
      tm := mapspot + 1;
    end;

  2:  // north facing wall
    begin
      distance := ((tiley + 1) * FRACTILEUNIT) - viewy;
      textureadjust := -viewx;
      baseangle := baseangle + TANANGLES * 2;
      tm := mapspot + MAPCOLS;
    end;
  3:  // east facing wall
    begin
      distance := viewx - (tilex * FRACTILEUNIT);
      textureadjust := -viewy;
      baseangle := baseangle + TANANGLES;
      tm := mapspot - 1;
    end;
  end;

  ceiling1 := floorheight[tm];
  floor1 := floorheight[mapspot];

  if ceiling1 <= floor1 then
    goto ceilingstep;
  if ceiling1 >= ceilingheight[mapspot] then
    walltype := 1; // clip beyond this tile

  floor := true;
  walltype1 := floordef[tm];
  rotateright1 := floordefflags[tm] and F_RIGHT;
  rotateleft1 := floordefflags[tm] and F_LEFT;
  rotateup1 := floordefflags[tm] and F_UP;
  rotatedown1 := floordefflags[tm] and F_DOWN;
  cclip1 := ceiling1;
  ceiling1 := (ceiling1 * FRACUNIT) - viewz;
  floor1 := -((floor1 * FRACUNIT) - viewz); // distance below vi
  walltype1 := walltranslation[walltype1];    // global animation
  wall1 := lumpmain[walllump + walltype1];    // to get wall height
  postindex1 := @wallposts[(walltype1 - 1) * 64];  // 64 pointers to texture start

ceilingstep:

  if mapflags[mapspot] and FL_CEILING <> 0 then
  begin
    if not floor then
      exit;
    goto skipceilingcalc;
  end;

  case side of
  0:  // south facing wall
    begin
      tm := mapspot - MAPSIZE;
    end;

  1:  // west facing wall
    begin
      tm := mapspot + 1;
    end;

  2:  // north facing wall
    begin
      tm := mapspot + MAPSIZE;
    end;

  3:  // east facing wall
    begin
      tm := mapspot - 1;
    end;
  end;

  floor2 := ceilingheight[tm];
  ceiling2 := ceilingheight[mapspot];

  if ceiling2 <= floor2 then
  begin
    if not floor then
      exit;
    goto skipceilingcalc;
  end;

  if floor2 <= floorheight[mapspot] then
    walltype := 1; // clip beyond this tile
  if floor and (cclip1 >= floor2) then
    walltype := 1;

  ceiling := true;
  ceiling2 := (ceiling2 * FRACUNIT) - viewz;
  floor2 := -((floor2 * FRACUNIT) - viewz);   // distance below vi
  walltype2 := ceilingdef[tm];
  walltype2 := walltranslation[walltype2];  // global animation
  wall2 := lumpmain[walllump + walltype2];  // to get wall height
  postindex2 := @wallposts[(walltype2 - 1) * 64];  // 64 pointers to texture start
  rotateleft2 := ceilingdefflags[tm] and F_LEFT;
  rotateright2 := ceilingdefflags[tm] and F_RIGHT;
  rotateup2 := ceilingdefflags[tm] and F_UP;
  rotatedown2 := ceilingdefflags[tm] and F_DOWN;

skipceilingcalc:

  if wallshadow = 1 then
    sp_colormap := @colormaps[wallglow * 256]
  else if wallshadow = 2 then
    sp_colormap := @colormaps[wallflicker1 * 256]
  else if wallshadow = 3 then
    sp_colormap := @colormaps[wallflicker2 * 256]
  else if wallshadow = 4 then
    sp_colormap := @colormaps[wallflicker3 * 256];

  // step through the individual posts
  for x := x1 to x2 do
  begin
    // first do the z clipping
    angle := baseangle + pixelangle[x];
    angle := angle and (TANANGLES * 2 - 1);
    anglecos := cosines[(angle - TANANGLES) and (TANANGLES * 4 - 1)];
    pointz := FIXEDDIV(distance, anglecos);
    pointz := FIXEDMUL(pointz, pixelcosine[x]);
    if (pointz > MAXZ) or (pointz < MINZ) then
      continue;

    // wall special effects
    if wallshadow = 0 then
    begin
      light := (pointz div FRACUNIT) + maplight;
      if light > MAXZLIGHT then
        light := MAXZLIGHT
      else if light < 0 then
        light := 0;
      sp_colormap := zcolormap[light];
    end
    else if (wallshadow >= 5) and (wallshadow <= 8) then
    begin
      if wallcycle = wallshadow - 5 then
        sp_colormap := colormaps
      else
      begin
        light := (pointz div FRACUNIT) + maplight;
        if light > MAXZLIGHT then
          light := MAXZLIGHT
        else if light < 0 then
          light := 0;
        sp_colormap := zcolormap[light];
      end;
    end
    else if wallshadow = 9 then
    begin
      light := (pointz div FRACUNIT) + maplight + wallflicker4;
      if light > MAXZLIGHT then
        light := MAXZLIGHT
      else if light < 0 then
        light := 0;
      sp_colormap := zcolormap[light];
    end;

    texture := (textureadjust + FIXEDMUL(distance, tangents[angle])) div FRACUNIT;

    scale := FIXEDMUL(pointz, ISCALE);

    if scale < 1000 then
      continue;

    sp_fracstep := scale;

    if floor then
    begin
      texture2 := texture;
      if rotateright1 <> 0 then
        texture2 := texture2 - wallrotate
      else if rotateleft1 <> 0 then
        texture2 := texture2 + wallrotate
      else if (x = x1) and (x <> 0) then
        texture2 := 0; // fix the incorrect looping problem
      texture2 := texture2 and 63;
      sp_source := postindex1[texture2];
      top := FIXEDDIV(ceiling1, scale);
      topy := CENTERY - (top div FRACUNIT);
      fracadjust := top and (FRACUNIT - 1);
      sp_frac := FIXEDMUL(fracadjust, sp_fracstep);

      if topy < scrollmin then
      begin
        sp_frac := sp_frac + (scrollmin - topy) * scale;
        sp_loopvalue := (wall1^ * 4) * FRACUNIT - 1;
        while sp_frac > sp_loopvalue do
          sp_frac := sp_frac - sp_loopvalue - 1;
        topy := scrollmin;
      end;
      if rotatedown1 <> 0 then
        sp_frac := sp_frac + FRACUNIT * (63 - wallrotate)
      else if rotateup1 <> 0 then
        sp_frac := sp_frac + FRACUNIT * wallrotate;

      bottom := FIXEDDIV(floor1, scale) + FRACUNIT;
      if bottom >= ((CENTERY + scrollmin) * FRACUNIT) then
        bottomy := scrollmax - 1
      else
        bottomy := CENTERY + (bottom div FRACUNIT);
      if (bottomy < scrollmin) or (topy >= scrollmax) then
        goto contceiling;
      sp_count := bottomy - topy + 1;
      sp_dest := @viewylookup[bottomy - scrollmin][x];
      span := (pointz * ZTOFRACUNIT) and ZMASK;
      spansx[numspans] := x;
      span := span or numspans;
      spantags[numspans] := span;
      span_p := @spans[numspans];
      span_p.spantype := sp_step;
      span_p.picture := sp_source;
      span_p.y := sp_frac;           // store info in span structure
      span_p.yh := sp_fracstep;
      span_p.x2 := transparentposts; // post index
      span_p.light := wall1^ * 4;
      inc(numspans);
      tpwalls_dest[transparentposts] := sp_dest;
      tpwalls_colormap[transparentposts] := sp_colormap;
      tpwalls_count[transparentposts] := sp_count;
      inc(transparentposts);
{$IFDEF VALIDATE}
      if transparentposts >= MAXPEND then
        MS_Error('Too many Pending Posts! (%d)', [MAXPEND]);
      if numspans >= MAXSPANS then
        MS_Error('MAXSPANS exceeded, FloorDefs (%d)', [MAXSPANS]);
  {$ENDIF}
    end;

contceiling:
    if ceiling then
    begin
      texture2 := texture;
      if rotateright2 <> 0 then
        texture2 := texture2 - wallrotate
      else if rotateleft2 <> 0 then
        texture2 := texture2 + wallrotate
      else if (x = x1) and (x <> 0) then
        texture2 := 0; // fix the incorrect looping problem
      texture2 := texture2 and 63;
      sp_source := postindex2[texture2];
      top := FIXEDDIV(ceiling2, scale) + FRACUNIT;
      topy := CENTERY - (top div FRACUNIT);
      fracadjust := top and (FRACUNIT - 1);
      sp_frac := FIXEDMUL(fracadjust, sp_fracstep);

      if topy < scrollmin then
      begin
        sp_frac := sp_frac + (scrollmin - topy) * scale;
        sp_loopvalue := (wall2^ * 4) * FRACUNIT - 1;
        while sp_frac > sp_loopvalue do
          sp_frac := sp_frac - sp_loopvalue - 1;
        topy := scrollmin;
      end;
      if rotatedown2 <> 0 then
        sp_frac := sp_frac + FRACUNIT * (63 - wallrotate)
      else if rotateup2 <> 0 then
        sp_frac := sp_frac + FRACUNIT * wallrotate;

      bottom := FIXEDDIV(floor2, scale) + FRACUNIT;
      if bottom >= ((CENTERY + scrollmin) * FRACUNIT) then
        bottomy := scrollmax - 1
      else
        bottomy := CENTERY + (bottom div FRACUNIT);
      if (bottomy < scrollmin) or (topy >= scrollmax) then
        continue;
      sp_count := bottomy - topy + 1;
  {$IFDEF VALIDATE}
      if (bottomy - scrollmin < 0) or (bottomy - scrollmin >= MAX_VIEW_HEIGHT) then
        MS_Error('DrawSteps(): Indexing viewylookup at %d (out of range [%d,%d])', [bottomy - scrollmin, 0, MAX_VIEW_HEIGHT - 1]);
  {$ENDIF}
      sp_dest := @viewylookup[bottomy - scrollmin][x];
      span := (pointz * ZTOFRACUNIT) and ZMASK;
      spansx[numspans] := x;
      span := span or numspans;
      spantags[numspans] := span;
      span_p := @spans[numspans];
      span_p.spantype := sp_step;
      span_p.picture := sp_source;
      span_p.y := sp_frac;  // store info in span structure
      span_p.yh := sp_fracstep;
      span_p.x2 := transparentposts;  // post index
      span_p.light := wall2^ * 4; // loop value
      inc(numspans);
      tpwalls_dest[transparentposts] := sp_dest;
      tpwalls_colormap[transparentposts] := sp_colormap;
      tpwalls_count[transparentposts] := sp_count;
      inc(transparentposts);
  {$IFDEF VALIDATE}
      if transparentposts >= MAXPEND then
        MS_Error('Too many Pending Posts! (%d)', [MAXPEND]);
      if numspans >= MAXSPANS then
        MS_Error('MAXSPANS exceeded, CeilingDefs (%d)', [MAXSPANS]);
  {$ENDIF}
    end;
  end;

  if floor then
  begin
    if walltype <> 0 then
      c := WALL_COLOR
    else
      c := STEP_COLOR;
    case side of
    0: player.northmap[mapspot] := c;
    1: player.westmap[mapspot + 1] := c;
    2: player.northmap[mapspot + MAPCOLS] := c;
    3: player.westmap[mapspot] := c;
    end;
  end;
end;

end.


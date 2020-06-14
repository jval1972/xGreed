(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020 by Jim Valavanis                                     *)
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

unit r_walls;

interface

uses
  r_refdef,
  r_public_h;

var
  tangents: array[0..TANANGLES * 2 - 1] of fixed_t;
  sines: array[0..TANANGLES * 5 - 1] of fixed_t;
  cosines: Pfixed_tArray; // point 1/4 phase into sines
  pixelangle: array[0..MAX_VIEW_WIDTH] of integer;
  pixelcosine: array[0..MAX_VIEW_WIDTH] of fixed_t;
  wallz: array[0..MAX_VIEW_WIDTH - 1] of fixed_t;  // pointx
  tpwalls_dest: array[0..MAXPEND - 1] of PByte;
  tpwalls_colormap: array[0..MAXPEND - 1] of PByte;
  tpwalls_count: array[0..MAXPEND - 1] of integer;
  transparentposts: integer;
  wallpixelangle: array[0..MAX_VIEW_WIDTH] of integer;
  wallpixelcosine: array[0..MAX_VIEW_WIDTH] of fixed_t;
  campixelangle: array[0..MAX_VIEW_WIDTH] of integer;
  campixelcosine: array[0..MAX_VIEW_WIDTH] of fixed_t;

implementation

uses
  g_delphi,
  r_public;

// calculate the angle deltas for each view post
// VIEWWIDTH view posts covers TANANGLES angles
// traces go through the RIGHT EDGE of the pixel to follow the direction
procedure InitWalls;
var
  intval, i: integer;
begin
  for i := 0 to windowWidth do
  begin
    intval := rint(ArcTan((CENTERX - (i + 1.0)) / CENTERX) / PI * TANANGLES * 2);
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
  postindex := wallposts + ((walltype - 1) shl 6);  // 64 pointers to texture start
  baseangle := viewfineangle;
  transparent := wallflags and F_TRANSPARENT;
  floor := floorheight[mapspot];
  ceiling := ceilingheight[mapspot];
  case side of
  0:  // south facing wall
    begin
      distance := viewy - (tiley shl FRACTILESHIFT);
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
      distance := ((tilex + 1) shl FRACTILESHIFT) - viewx;
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
      distance := ((tiley + 1) shl FRACTILESHIFT) - viewy;
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
      distance := viewx - (tilex shl FRACTILESHIFT);
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
  ceiling := (ceiling shl FRACBITS) - viewz;
  floor := -((floor shl FRACBITS) - viewz);   // distance below vi
  sp_loopvalue := (wall^ * 4) shl FRACBITS;

  (* special effects *)
  if wallshadow = 1 then
    sp_colormap := colormaps+(wallglow shl 8);
  else if (wallshadow = 2) sp_colormap := colormaps+(wallflicker1 shl 8);
  else if (wallshadow = 3) sp_colormap := colormaps+(wallflicker2 shl 8);
  else if (wallshadow = 4) sp_colormap := colormaps+(wallflicker3 shl 8);
  else if (wallshadow >= 5) and (wallshadow <= 8) then
  begin
    if (wallcycle = wallshadow-5) sp_colormap := colormaps;
    else
    begin
      light := (pointz shr FRACBITS)+maplight;
      if (light>MAXZLIGHT) light := MAXZLIGHT;
       else if (light<0) light := 0;
      sp_colormap := zcolormap[light];
       end;
     end;

  rotateleft := wallflags) and (F_LEFT;
  rotateright := wallflags) and (F_RIGHT;
  rotateup := wallflags) and (F_UP;
  rotatedown := wallflags) and (F_DOWN;
  invisible := wallflags) and (F_DAMAGE;

  // step through the individual posts
  for (x := x1; x <= x2; x++)
  begin
    // first do the z clipping
   angle := baseangle+pixelangle[x];
   angle) and (:= TANANGLES *2-1;
   anglecos := cosines[(angle-TANANGLES)) and ((TANANGLES *4-1)];
   pointz := FIXEDDIV(distance, anglecos);
   pointz := FIXEDMUL(pointz, pixelcosine[x]);
   if pointz>MAXZ then
    exit;
   if pointz<MINZ then
    continue;

   (* wall special effects *)
   if wallshadow = 0 then
   begin
     light := (pointz shr FRACBITS)+maplight;
     if (light>MAXZLIGHT) light := MAXZLIGHT;
      else if (light<0) light := 0;
     sp_colormap := zcolormap[light];
   end
   else if wallshadow = 9 then
   begin
     light := (pointz shr FRACBITS)+maplight+wallflicker4;
     if (light>MAXZLIGHT) light := MAXZLIGHT;
      else if (light<0) light := 0;
     sp_colormap := zcolormap[light];
      end;

   // calculate the texture post along the wall that was hit
   texture := (textureadjust+FIXEDMUL(distance,tangents[angle])) shr FRACBITS;

   if (rotateright) texture-:= wallrotate;
    else if (rotateleft) texture+:= wallrotate;
    else if (x = x1) and (x <> 0) texture := 0; // fix the incorrect looping problem
   texture) and (:= 63;

   sp_source := postindex[texture];
   if not transparent then
    wallz[x] := pointz;

   // calculate the size and scale of the post
   sp_fracstep := FIXEDMUL(pointz,ISCALE);
   scale := sp_fracstep;
   if (scale<1000) continue;
   top := FIXEDDIV(ceiling,scale)+FRACUNIT;
   topy := CENTERY - (top shr FRACBITS);
   fracadjust := top) and ((FRACUNIT-1);
   sp_frac := FIXEDMUL(fracadjust,sp_fracstep);

   if rotatedown then
    sp_frac+:= FRACUNIT*(63-wallrotate);
   else if (rotateup)
    sp_frac+:= FRACUNIT*wallrotate;

   if topy<scrollmin then
   begin
     sp_frac+:= (scrollmin-topy)*scale;
     while (sp_frac >= sp_loopvalue) sp_frac-:= sp_loopvalue;
     topy := scrollmin;
      end;
   bottom := FIXEDDIV(floor,scale)+FRACUNIT*2;
   bottomy := bottom >= ((CENTERY+scrollmin) shl FRACBITS) ?
    scrollmax-1: CENTERY+(bottom shr FRACBITS);
   if (bottomy<scrollmin) or (topy >= scrollmax) or (topy = bottomy) continue;
   sp_count := bottomy-topy+1;

   sp_dest := viewylookup[bottomy-scrollmin]+x;
   if transparent then
   begin
     span := (pointz shl ZTOFRAC)) and (ZMASK;
     spansx[numspans] := x;
     span) or (:= numspans;
     spantags[numspans] := span;
     span_p := @spans[numspans];
     if invisible then
      span_p.spantype := sp_inviswall;
     else
      span_p.spantype := sp_transparentwall;
     span_p.picture := sp_source;
     span_p.y := sp_frac;           // store info in span structure
     span_p.yh := sp_fracstep;
     span_p.x2 := transparentposts; // post index
     span_p.light := (*wall*4);
     numspans++;
     tpwalls_dest[transparentposts] := sp_dest;
     tpwalls_colormap[transparentposts] := sp_colormap;
     tpwalls_count[transparentposts] := sp_count;
     transparentposts++;
{$IFDEF VALIDATE}
     if (transparentposts >= MAXPEND) MS_Error('Too many Pending Posts! (%i >= %i)',transparentposts,MAXPEND);
     if (numspans >= MAXSPANS) MS_Error('MAXSPANS exceeded, Walls (%i >= %i)',numspans,MAXSPANS);
{$ENDIF}
      end;
    else ScalePost;
    end;
  end;


procedure DrawSteps(int x1, int x2);
begin
  baseangle: integer;
  byte     **postindex1,**postindex2; // start of the 64 entry texture table for t
  fixed_t  distance;       // horizontal / vertical dist to wall segmen
  fixed_t  pointz;         // transformed distance to wall post
  anglecos: fixed_t;
  fixed_t  textureadjust;  // the amount the texture p1ane is shifted
  fixed_t  ceiling1, ceiling2; // top of the wall
  fixed_t  floor1,floor2;     // bottom of the wall
  fixed_t  top, bottom;    // precise y coordinates for post
  scale: fixed_t;
  cclip1: fixed_t;
  int      topy, bottomy;  // pixel y coordinates for post
  fixed_t  fracadjust;     // the amount to prestep for the top pixel
  int      angle;          // the ray angle that strikes the current po
  int      texture, texture2; // 0-63 post number
  int      x;      // collumn and ranges
  light: integer;
  short    *wall1, *wall2;
  unsigned span;
  span_t   *span_p;
  walltype1, walltype2, c, rotateright1, rotateright2: integer;
  rotateleft1, rotateleft2, tm: integer;
  rotateup1, rotateup2, rotatedown1, rotatedown2: integer;
  floor, ceiling: boolean;

  floor := false;
  ceiling := false;
  if (mapflags[mapspot]) and (FL_FLOOR) goto ceilingstep;
  baseangle := viewfineangle;
  case side  of
  begin
   0:                         // south facing wall
    distance := viewy-(tiley shl FRACTILESHIFT);
    textureadjust := viewx;
    baseangle+:= TANANGLES *2;
    tm := mapspot-MAPCOLS;
    break;
   1:                         // west facing wall
    distance := ((tilex+1) shl FRACTILESHIFT)-viewx;
    textureadjust := viewy;
    baseangle := baseangle + TANANGLES;
    tm := mapspot+1;
    break;
   2:                         // north facing wall
    distance := ((tiley+1) shl FRACTILESHIFT)-viewy;
    textureadjust := -viewx;
    baseangle+:= TANANGLES *2;
    tm := mapspot+MAPCOLS;
    break;
   3:                         // east facing wall
    distance := viewx-(tilex shl FRACTILESHIFT);
    textureadjust := -viewy;
    baseangle := baseangle + TANANGLES;
    tm := mapspot-1;
    break;
    end;
  ceiling1 := floorheight[tm];
  floor1 := floorheight[mapspot];

  if (ceiling1 <= floor1) goto ceilingstep;
  if (ceiling1 >= ceilingheight[mapspot]) walltype := 1; // clip beyond this tile

  floor := true;
  walltype1 := floordef[tm];
  rotateright1 := floordefflags[tm]) and (F_RIGHT;
  rotateleft1 := floordefflags[tm]) and (F_LEFT;
  rotateup1 := floordefflags[tm]) and (F_UP;
  rotatedown1 := floordefflags[tm]) and (F_DOWN;
  cclip1 := ceiling1;
  ceiling1 := (ceiling1 shl FRACBITS)-viewz;
  floor1 := -((floor1 shl FRACBITS)-viewz);       // distance below vi
  walltype1 := walltranslation[walltype1];     // global animation
  wall1 := lumpmain[walllump+walltype1];       // to get wall height
  postindex1 := wallposts+((walltype1-1) shl 6);  // 64 pointers to texture start

ceilingstep:

  if (mapflags[mapspot]) and (FL_CEILING) then
  begin
   if (not floor) exit;
   goto skipceilingcalc;
    end;
  case side  of
  begin
   0:                         // south facing wall
    tm := mapspot-MAPSIZE;
    break;
   1:                         // west facing wall
    tm := mapspot+1;
    break;
   2:                         // north facing wall
    tm := mapspot+MAPSIZE;
    break;
   3:                         // east facing wall
    tm := mapspot-1;
    break;
    end;
  floor2 := ceilingheight[tm];
  ceiling2 := ceilingheight[mapspot];

  if ceiling2 <= floor2 then
  begin
   if (not floor) exit;
   goto skipceilingcalc;
    end;

  if (floor2 <= floorheight[mapspot]) walltype := 1; // clip beyond this tile
  if (floor) and (cclip1 >= floor2) walltype := 1;

  ceiling := true;
  ceiling2 := (ceiling2 shl FRACBITS)-viewz;
  floor2 := -((floor2 shl FRACBITS)-viewz);   // distance below vi
  walltype2 := ceilingdef[tm];
  walltype2 := walltranslation[walltype2];     // global animation
  wall2 := lumpmain[walllump+walltype2];       // to get wall height
  postindex2 := wallposts+((walltype2-1) shl 6);  // 64 pointers to texture start
  rotateleft2 := ceilingdefflags[tm]) and (F_LEFT;
  rotateright2 := ceilingdefflags[tm]) and (F_RIGHT;
  rotateup2 := ceilingdefflags[tm]) and (F_UP;
  rotatedown2 := ceilingdefflags[tm]) and (F_DOWN;

skipceilingcalc:

  if (wallshadow = 1) sp_colormap := colormaps+(wallglow shl 8);
  else if (wallshadow = 2) sp_colormap := colormaps+(wallflicker1 shl 8);
  else if (wallshadow = 3) sp_colormap := colormaps+(wallflicker2 shl 8);
  else if (wallshadow = 4) sp_colormap := colormaps+(wallflicker3 shl 8);

  // step through the individual posts
  for (x := x1; x <= x2; x++)
  begin
    // first do the z clipping
   angle := baseangle+pixelangle[x];
   angle) and (:= TANANGLES *2-1;
   anglecos := cosines[(angle-TANANGLES)) and ((TANANGLES *4-1)];
   pointz := FIXEDDIV(distance, anglecos);
   pointz := FIXEDMUL(pointz, pixelcosine[x]);
   if (pointz>MAXZ) or (pointz<MINZ) continue;

   (* wall special effects *)
   if wallshadow = 0 then
   begin
     light := (pointz shr FRACBITS)+maplight;
     if (light>MAXZLIGHT) light := MAXZLIGHT;
      else if (light<0) light := 0;
     sp_colormap := zcolormap[light];
   end
   else if (wallshadow >= 5) and (wallshadow <= 8) then
   begin
     if (wallcycle = wallshadow-5) sp_colormap := colormaps;
     else
     begin
       light := (pointz shr FRACBITS)+maplight;
       if (light>MAXZLIGHT) light := MAXZLIGHT;
  else if (light<0) light := 0;
       sp_colormap := zcolormap[light];
        end;
   end
   else if wallshadow = 9 then
   begin
     light := (pointz shr FRACBITS)+maplight+wallflicker4;
     if (light>MAXZLIGHT) light := MAXZLIGHT;
      else if (light<0) light := 0;
     sp_colormap := zcolormap[light];
      end;

   texture := (textureadjust+FIXEDMUL(distance,tangents[angle])) shr FRACBITS;

   scale := FIXEDMUL(pointz,ISCALE);

   if (scale<1000) continue;

   sp_fracstep := scale;

  (* = = = = = = = = = = = = = = = = = = = := *)
   if floor then
   begin
     texture2 := texture;
     if (rotateright1) texture2-:= wallrotate;
      else if (rotateleft1) texture2+:= wallrotate;
      else if (x = x1) and (x <> 0) texture2 := 0; // fix the incorrect looping problem
     texture2) and (:= 63;
     sp_source := postindex1[texture2];
     top := FIXEDDIV(ceiling1,scale);
     topy := CENTERY - (top shr FRACBITS);
     fracadjust := top) and ((FRACUNIT-1);
     sp_frac := FIXEDMUL(fracadjust,sp_fracstep);

     if topy<scrollmin then
     begin
       sp_frac+:= (scrollmin-topy)*scale;
       sp_loopvalue := (*wall1 * 4) shl FRACBITS;
       while (sp_frac >= sp_loopvalue) sp_frac-:= sp_loopvalue;
       topy := scrollmin;
        end;
     if rotatedown1 then
      sp_frac+:= FRACUNIT*(63-wallrotate);
     else if (rotateup1)
      sp_frac+:= FRACUNIT*wallrotate;

     bottom := FIXEDDIV(floor1,scale)+FRACUNIT;
     bottomy := bottom >= ((CENTERY+scrollmin) shl FRACBITS) ?
      scrollmax-1: CENTERY+(bottom shr FRACBITS);
     if ((bottomy<scrollmin)) or ((topy >= scrollmax)) goto contceiling;
     sp_count := bottomy-topy+1;
     sp_dest := viewylookup[bottomy-scrollmin]+x;
     span := (pointz shl ZTOFRAC)) and (ZMASK;
     spansx[numspans] := x;
     span) or (:= numspans;
     spantags[numspans] := span;
     span_p := @spans[numspans];
     span_p.spantype := sp_step;
     span_p.picture := sp_source;
     span_p.y := sp_frac;           // store info in span structure
     span_p.yh := sp_fracstep;
     span_p.x2 := transparentposts; // post index
     span_p.light := (*wall1 * 4);
     numspans++;
     tpwalls_dest[transparentposts] := sp_dest;
     tpwalls_colormap[transparentposts] := sp_colormap;
     tpwalls_count[transparentposts] := sp_count;
     transparentposts++;
{$IFDEF VALIDATE}
     if (transparentposts >= MAXPEND) MS_Error('Too many Pending Posts! (%i >= %i)',transparentposts,MAXPEND);
     if (numspans >= MAXSPANS) MS_Error('MAXSPANS exceeded, FloorDefs (%i >= %i)',numspans,MAXSPANS);
  {$ENDIF}
      end;

contceiling:
  (* = = = = = = = = = = = = = = = = = = = := *)
   if ceiling then
   begin
     texture2 := texture;
     if (rotateright2) texture2-:= wallrotate;
      else if (rotateleft2) texture2+:= wallrotate;
      else if (x = x1) and (x <> 0) texture2 := 0; // fix the incorrect looping problem
     texture2) and (:= 63;
     sp_source := postindex2[texture2];
     top := FIXEDDIV(ceiling2,scale)+FRACUNIT;
     topy := CENTERY - (top shr FRACBITS);
     fracadjust := top) and ((FRACUNIT-1);
     sp_frac := FIXEDMUL(fracadjust,sp_fracstep);

     if topy<scrollmin then
     begin
       sp_frac+:= (scrollmin-topy)*scale;
       sp_loopvalue := (*wall2 * 4) shl FRACBITS;
       while (sp_frac >= sp_loopvalue) sp_frac-:= sp_loopvalue;
       topy := scrollmin;
        end;
     if rotatedown2 then
      sp_frac+:= FRACUNIT*(63-wallrotate);
     else if (rotateup2)
      sp_frac+:= FRACUNIT*wallrotate;

     bottom := FIXEDDIV(floor2,scale)+FRACUNIT;
     bottomy := bottom >= ((CENTERY+scrollmin) shl FRACBITS) ?
      scrollmax-1: CENTERY+(bottom shr FRACBITS);
     if (bottomy<scrollmin) or (topy >= scrollmax) continue;
     sp_count := bottomy-topy+1;
     sp_dest := viewylookup[bottomy-scrollmin]+x;
     span := (pointz shl ZTOFRAC)) and (ZMASK;
     spansx[numspans] := x;
     span) or (:= numspans;
     spantags[numspans] := span;
     span_p := @spans[numspans];
     span_p.spantype := sp_step;
     span_p.picture := sp_source;
     span_p.y := sp_frac;           // store info in span structure
     span_p.yh := sp_fracstep;
     span_p.x2 := transparentposts; // post index
     span_p.light := (*wall2 * 4);  // loop value
     numspans++;
     tpwalls_dest[transparentposts] := sp_dest;
     tpwalls_colormap[transparentposts] := sp_colormap;
     tpwalls_count[transparentposts] := sp_count;
     transparentposts++;
{$IFDEF VALIDATE}
     if (transparentposts >= MAXPEND) MS_Error('Too many Pending Posts! (%i >= %i)',transparentposts,MAXPEND);
     if (numspans >= MAXSPANS) MS_Error('MAXSPANS exceeded, CeilingDefs (%i >= %i)',numspans,MAXSPANS);
  {$ENDIF}
      end;
    end;

  if floor then
  begin
   if (walltype) c := WALL_COLOR;
    else c := STEP_COLOR;
   switch(side)
   begin
     0:
      player.northmap[mapspot] := c;
      break;
     1:
      player.westmap[mapspot+1] := c;
      break;
     2:
      player.northmap[mapspot+MAPCOLS] := c;
      break;
     3:
      player.westmap[mapspot] := c;
      end;
    end;
  end;

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

#include <STDLIB.H>
#include 'd_global.h'
#include 'd_disk.h'
#include 'r_refdef.h'
#include 'd_misc.h'
#include 'd_ints.h'


(**** VARIABLES ****)

scaleobj_t  firstscaleobj, lastscaleobj; // just placeholders for links
scaleobj_t  scaleobjlist[MAXSPRITES], *freescaleobj_p;
doorobj_t   doorlist[MAXDOORS];
  numdoors: integer;
elevobj_t   firstelevobj, lastelevobj;
elevobj_t   elevlist[MAXELEVATORS], *freeelevobj_p;
  numelev: integer;
  doorxl, doorxh: integer;
spawnarea_t spawnareas[MAXSPAWNAREAS];
  numspawnareas, rtimecount: integer;


(**** FUNCTIONS ****)

procedure DrawDoor;

vertex_t *TransformPoint(fixed_t x, fixed_t y)
(* returns vertex pointer of transformed vertex *)
begin
  trx, try: fixed_t;
  scale: fixed_t;
  vertex_t *point;

  point := vertexlist_p++;
{$IFDEF VALIDATE}
  if (point >= @vertexlist[MAXVISVERTEXES]) MS_Error('TransformPoint: Vertexlist overflow');
{$ENDIF}
  trx := x-viewx;
  try := y-viewy;
  point.tx := FIXEDMUL(try, viewcos)+FIXEDMUL(trx, viewsin);
  point.tz := FIXEDMUL(trx, viewcos)-FIXEDMUL(try, viewsin);
  if point.tz >= MINZ then
  begin
   scale := FIXEDDIV(SCALE,point.tz);
   point.px := CENTERX+(FIXEDMUL(point.tx, scale) shr FRACBITS);
    end;
  return point;
  end;


  ClipDoor: boolean;
(* Sets p1.px and p2.px correctly for Z values < MINZ
   Returns false if entire door is too close or far away *)
   begin
  frac, clip: fixed_t;

  if ((p1.tz>MAXZ) and (p2.tz>MAXZ)) or (      // entire face is too far away
     (p1.tz <= 0) and (p2.tz <= 0)) return false; // totally behind the projection plane
  if p1.tz<MINZ then
  begin
   if (p1.tz = 0) clip := p1.tx;
   else
   begin
     if (p2.tz = p1.tz) return false;
     frac := FIXEDDIV(p2.tz, (p2.tz-p1.tz));
     clip := p2.tx+FIXEDMUL((p1.tx-p2.tx), frac);
      end;
   p1.px := clip<0?0:windowWidth;
  end
  else if p2.tz<MINZ then
  begin
   if (p2.tz = 0) clip := p2.tx;
   else
   begin
     if (p2.tz = p1.tz) return false;
     frac := FIXEDDIV(p1.tz, (p1.tz-p2.tz));
     clip := p1.tx+FIXEDMUL((p2.tx-p1.tx), frac);
      end;
   p2.px := clip<0?0:windowWidth;
    end;
  return true;
  end;


procedure RenderDoor;
(*  Posts one pixel wide span events for each visible post of the door a
    tilex / tiley / xclipl / xcliph
    sets doorxl, doorxh based on the position of the door.  One of the t
    in the tile bounds, the other will be off the edge of the view.  The
    restrict the flowing into other tiles bounds. *)
    begin
  doorobj_t *door_p, *last_p;
  tx, ty: fixed_t;
  byte      **postindex;    // start of the 64 entry texture table for t
  fixed_t   pointz;         // transformed distance to wall post
  anglecos: fixed_t;
  fixed_t   ceilingheight;  // top of the wall
  fixed_t   floorh;         // bottom of the wall
  int       angle;          // the ray angle that strikes the current post
  int       texture;        // 0-63 post number
  int       x, x1, x2;      // collumn and ranges
  span_t    *span_p;
  unsigned  span;
  distance, absdistance, position: fixed_t;
  baseangle: integer;
  fixed_t   textureadjust;  // the amount the texture p1ane is shifted
  spanobj_t spantype;
  short     *wall;
  vertex_t  *p3;

  // scan the doorlist for matching tilex/tiley
  // this only happens a couple times / frame max, so it's not a big deal
  last_p := @doorlist[numdoors];
  for (door_p := doorlist;door_p++)
  begin
   if door_p.transparent then
    MS_Error('Door transparent');
   if (door_p.tilex = tilex) and (door_p.tiley = tiley) break;
    end;
  // transform both endpoints of the door
  // p1 is the anchored point, p2 is the moveable point
  tx := tilex shl (TILESHIFT+FRACBITS);
  ty := tiley shl (TILESHIFT+FRACBITS);
  position := door_p.position;
  case door_p.orientation  of
  begin
   dr_horizontal:
    ty+:= FRACUNIT *27;
    p1 := TransformPoint(tx+position, ty);
    p2 := TransformPoint(tx, ty);
    textureadjust := viewx+TILEGLOBAL - (tx+position);
    baseangle := TANANGLES*2;
    distance := viewy-ty;
    if (not player.northmap[mapspot]) player.northmap[mapspot] := DOOR_COLOR;
    break;
   dr_vertical:
    tx+:= FRACUNIT *27;
    p1 := TransformPoint(tx, ty+position);
    p2 := TransformPoint(tx, ty);
    textureadjust := viewy+TILEGLOBAL - (ty+position);
    baseangle := TANANGLES;
    distance := tx-viewx;
    if (not player.westmap[mapspot]) player.westmap[mapspot] := DOOR_COLOR;
    break;
   dr_horizontal2:
    tx := tx + TILEGLOBAL;
    ty+:= FRACUNIT*27;
    p1 := TransformPoint(tx-position, ty);
    p2 := TransformPoint(tx, ty);
    textureadjust := viewx+TILEGLOBAL - (tx-position);
    baseangle := TANANGLES*2;
    distance := viewy-ty;
    if (not player.northmap[mapspot]) player.northmap[mapspot] := DOOR_COLOR;
    break;
   dr_vertical2:
    tx+:= FRACUNIT*27;
    ty := ty + TILEGLOBAL;
    p1 := TransformPoint(tx, ty-position);
    p2 := TransformPoint(tx, ty);
    textureadjust := viewy+TILEGLOBAL - (ty-position);
    baseangle := TANANGLES;
    distance := tx-viewx;
    if (not player.westmap[mapspot]) player.westmap[mapspot] := DOOR_COLOR;
    break;
    end;

  if p1.px>p2.px then
  begin
   p3 := p1;
   p1 := p2;
   p2 := p3;
    end;
  if (not door_p.position) or ( not ClipDoor) goto part2;
  x1 := p1.px;
  x2 := p2.px;

  // calculate the textures to post into the span list
  if (x1<xclipl) x1 := xclipl;
  if (x2>xcliph+1) x2 := xcliph+1;
  if (x1 >= x2) goto part2; // totally clipped off side
  // set up for loop
  if door_p.transparent then
  begin
   spantype := sp_maskeddoor;
   doortile :=  false;
    end;
  else spantype := sp_door;
  walltype := door_p.pic;
  walltype := walltranslation[walltype];     // global animation
  walltype--;                             // make 0 based
  wall := lumpmain[walllump+walltype];
  ceilingheight := vertex[0].ceilingheight;
  floorh := -vertex[0].floorheight;
  postindex := wallposts+(walltype shl 6);      // 64 pointers to texture starts
  baseangle := baseangle + viewfineangle;
  absdistance := distance<0?-distance : distance;
  // step through the individual posts
  for (x := x1; x<x2; x++)
  begin
   angle := baseangle+pixelangle[x];
   angle) and (:= TANANGLES *2-1;
   // the z distance of the post hit :=  walldistance*cos(screenangle
   anglecos := cosines[(angle-TANANGLES)) and ((TANANGLES *4-1)];
   if anglecos<8000 then
    continue;
   pointz := FIXEDDIV(absdistance, anglecos);
   pointz := FIXEDMUL(pointz, pixelcosine[x]);
   if (pointz>MAXZ) or (pointz<MINZ) continue;

   // calculate the texture post along the wall that was hit
   texture := (textureadjust+FIXEDMUL(distance, tangents[angle])) shr FRACBITS;
   texture) and (:= 63;
   sp_source := postindex[texture];

   // post the span in the draw list
   span := (pointz shl ZTOFRAC)) and (ZMASK;
   spansx[numspans] := x;
   span) or (:= numspans;
   spantags[numspans] := span;
   span_p := @spans[numspans];
   span_p.spantype := spantype;
   span_p.picture := sp_source;
   span_p.y := ceilingheight;
   span_p.yh := floorh;
   span_p.structure := door_p;
   span_p.light := maplight;
   span_p.shadow := wallshadow;

   numspans++;
{$IFDEF VALIDATE}
   if (numspans >= MAXSPANS) MS_Error('MAXSPANS exceeded, RenderDoor (%i >= %i)',numspans,MAXSPANS);
{$ENDIF}
    end;

part2:
  tx := tilex shl (TILESHIFT+FRACBITS);
  ty := tiley shl (TILESHIFT+FRACBITS);
  position := door_p.position;
  case door_p.orientation  of
  begin
   dr_horizontal:
    ty+:= FRACUNIT*37;
    p1 := TransformPoint(tx+position, ty);
    p2 := TransformPoint(tx, ty);
    textureadjust := viewx+TILEGLOBAL - (tx+position);
    baseangle := TANANGLES*2;
    distance := viewy-ty;
    if (not player.northmap[mapspot]) player.northmap[mapspot] := DOOR_COLOR;
    break;
   dr_vertical:
    tx+:= FRACUNIT*37;
    p1 := TransformPoint(tx, ty+position);
    p2 := TransformPoint(tx, ty);
    textureadjust := viewy+TILEGLOBAL - (ty+position);
    baseangle := TANANGLES;
    distance := tx-viewx;
    if (not player.westmap[mapspot]) player.westmap[mapspot] := DOOR_COLOR;
    break;
   dr_horizontal2:
    tx := tx + TILEGLOBAL;
    ty+:= FRACUNIT*37;
    p1 := TransformPoint(tx-position, ty);
    p2 := TransformPoint(tx, ty);
    textureadjust := viewx+TILEGLOBAL - (tx-position);
    baseangle := TANANGLES*2;
    distance := viewy-ty;
    if (not player.northmap[mapspot]) player.northmap[mapspot] := DOOR_COLOR;
    break;
   dr_vertical2:
    tx+:= FRACUNIT*37;
    ty := ty + TILEGLOBAL;
    p1 := TransformPoint(tx, ty-position);
    p2 := TransformPoint(tx, ty);
    textureadjust := viewy+TILEGLOBAL - (ty-position);
    baseangle := TANANGLES;
    distance := tx-viewx;
    if (not player.westmap[mapspot]) player.westmap[mapspot] := DOOR_COLOR;
    break;
    end;

  if p1.px>p2.px then
  begin
   p3 := p1;
   p1 := p2;
   p2 := p3;
    end;
  if (not door_p.position) or ( not ClipDoor) goto part3;
  x1 := p1.px;
  x2 := p2.px;
  if (x1<xclipl) x1 := xclipl;
  if (x2>xcliph+1) x2 := xcliph+1;
  if (x1 >= x2) goto part3;
  // set up for loop
  if door_p.transparent then
  begin
   spantype := sp_maskeddoor;
   doortile :=  false;
    end;
  else spantype := sp_door;
  walltype := door_p.pic;
  walltype := walltranslation[walltype];     // global animation
  walltype--;                             // make 0 based
  wall := lumpmain[walllump+walltype];
  ceilingheight := vertex[0].ceilingheight;
  floorh := -vertex[0].floorheight;
  postindex := wallposts+(walltype shl 6);      // 64 pointers to texture starts
  baseangle := baseangle + viewfineangle;
  absdistance := distance<0?-distance : distance;
  // step through the individual posts
  for (x := x1; x<x2; x++)
  begin
   angle := baseangle+pixelangle[x];
   angle) and (:= TANANGLES *2-1;
   // the z distance of the post hit :=  walldistance*cos(screenangle
   anglecos := cosines[(angle-TANANGLES)) and ((TANANGLES *4-1)];
   if anglecos<8000 then
    continue;
   pointz := FIXEDDIV(absdistance, anglecos);
   pointz := FIXEDMUL(pointz, pixelcosine[x]);
   if (pointz>MAXZ) exit;
   if (pointz<MINZ) continue;

   // calculate the texture post along the wall that was hit
   texture := (textureadjust+FIXEDMUL(distance, tangents[angle])) shr FRACBITS;
   texture) and (:= 63;
   sp_source := postindex[texture];

   // post the span in the draw list
   span := (pointz shl ZTOFRAC)) and (ZMASK;
   spansx[numspans] := x;
   span) or (:= numspans;
   spantags[numspans] := span;
   span_p := @spans[numspans];
   span_p.spantype := spantype;
   span_p.picture := sp_source;
   span_p.y := ceilingheight;
   span_p.yh := floorh;
   span_p.structure := door_p;
   span_p.light := maplight;
   span_p.shadow := wallshadow;

   numspans++;
{$IFDEF VALIDATE}
   if (numspans >= MAXSPANS) MS_Error('MAXSPANS exceeded, RenderDoor (%i >= %i)',numspans,MAXSPANS);
{$ENDIF}
    end;


part3:
  tx := tilex shl (TILESHIFT+FRACBITS);
  ty := tiley shl (TILESHIFT+FRACBITS);
  case door_p.orientation  of
  begin
   dr_horizontal:
    ty+:= FRACUNIT*32;
    tx := tx + position;
    p1 := TransformPoint(tx, ty+(5 shl FRACBITS));
    p2 := TransformPoint(tx, ty-(5 shl FRACBITS));
    textureadjust := viewy+TILEGLOBAL - ty;
    baseangle := TANANGLES;
    distance := tx-viewx;
    break;
   dr_vertical:
    tx+:= FRACUNIT*32;
    ty := ty + position;
    p1 := TransformPoint(tx+(5 shl FRACBITS), ty);
    p2 := TransformPoint(tx-(5 shl FRACBITS), ty);
    textureadjust := viewx+TILEGLOBAL - tx;
    baseangle := TANANGLES*2;
    distance := viewy-ty;
    break;
   dr_horizontal2:
    ty+:= FRACUNIT*32;
    tx+:= FRACUNIT*64-position;
    p1 := TransformPoint(tx, ty+(5 shl FRACBITS));
    p2 := TransformPoint(tx, ty-(5 shl FRACBITS));
    textureadjust := viewy+TILEGLOBAL - ty;
    baseangle := TANANGLES;
    distance := tx-viewx;
    break;
   dr_vertical2:
    tx+:= FRACUNIT*32;
    ty+:= FRACUNIT*64-position;
    p1 := TransformPoint(tx+(5 shl FRACBITS), ty);
    p2 := TransformPoint(tx-(5 shl FRACBITS), ty);
    textureadjust := viewx+TILEGLOBAL - tx;
    baseangle := TANANGLES*2;
    distance := viewy-ty;
    break;
    end;
  if p1.px>p2.px then
  begin
   p3 := p1;
   p1 := p2;
   p2 := p3;
    end;
  if (not door_p.position) or ( not ClipDoor) exit;
  x1 := p1.px;
  x2 := p2.px;

  // calculate the textures to post into the span list
  if (x1<xclipl) x1 := xclipl;
  if (x2>xcliph+1) x2 := xcliph+1;
  if (x1 >= x2) exit;  // totally clipped off side
  // set up for loop
  walltype := 2;
  wall := lumpmain[walllump+walltype];
  postindex := wallposts+(walltype shl 6);      // 64 pointers to texture starts
  baseangle := baseangle + viewfineangle;
  absdistance := distance<0?-distance : distance;
  // step through the individual posts
  for (x := x1; x<x2; x++)
  begin
   angle := baseangle+pixelangle[x];
   angle) and (:= TANANGLES *2-1;
   // the z distance of the post hit :=  walldistance*cos(screenangle
   anglecos := cosines[(angle-TANANGLES)) and ((TANANGLES *4-1)];
   if anglecos<8000 then
    continue;
   pointz := FIXEDDIV(absdistance, anglecos);
   pointz := FIXEDMUL(pointz, pixelcosine[x]);
   if (pointz>MAXZ) exit;
   if (pointz<MINZ) continue;

   // calculate the texture post along the wall that was hit
   texture := (textureadjust+FIXEDMUL(distance, tangents[angle])) shr FRACBITS;
   texture) and (:= 63;
   sp_source := postindex[texture];

   // post the span in the draw list
   span := (pointz shl ZTOFRAC)) and (ZMASK;
   spansx[numspans] := x;
   span) or (:= numspans;
   spantags[numspans] := span;
   span_p := @spans[numspans];
   span_p.spantype := spantype;
   span_p.picture := sp_source;
   span_p.y := ceilingheight;
   span_p.yh := floorh;
   span_p.structure := door_p;
   span_p.light := maplight;
   span_p.shadow := wallshadow;

   numspans++;
{$IFDEF VALIDATE}
   if (numspans >= MAXSPANS) MS_Error('MAXSPANS exceeded, RenderDoor (%i >= %i)',numspans,MAXSPANS);
{$ENDIF}
    end;

  end;


void RenderSprites
(*  For each sprite, if the sprite's bounding rect touches a tile with a
    vertex, transform and clip the projected view rect.  If still visible
    a span into the span list *)
    begin
  scaleobj_t *sprite;
  deltax, deltay, pointx, pointz, gxt, gyt: fixed_t;
  picnum: integer;
  unsigned   span;
  span_t     *span_p;
  byte       animationGraphic, animationMax, animationDelay;
  mapx, mapy, mapspot: integer;

  for (sprite := firstscaleobj.next; sprite <> @lastscaleobj;sprite := sprite.next)
  begin
   // calculate which image to display
   picnum := sprite.basepic;
   if sprite.rotate then
     begin    // this is only aproximate, but ok for 8
     if sprite.rotate = rt_eight then
      picnum+:= ((viewangle - sprite.angle+WEST+DEGREE45_2) shr 7)) and (7;
     else picnum+:= ((viewangle - sprite.angle+WEST+DEGREE45) shr 8)) and (3;
      end;

   if ((sprite.animation)) and ((rtimecount >= (int)sprite.animationTime)) then
   begin
     animationGraphic :=  (sprite.animation) and (ANIM_CG_MASK)  shr  1;
     animationMax :=  (sprite.animation) and (ANIM_MG_MASK)  shr  5;
     animationDelay :=  (sprite.animation) and (ANIM_DELAY_MASK)  shr  9;
     if (animationGraphic < animationMax-1) animationGraphic++;
      else if (sprite.animation) and (ANIM_LOOP_MASK) animationGraphic := 0;
      else if (sprite.animation) and (ANIM_SELFDEST) then
      begin
  sprite := sprite.prev; (* some sprites exist only to animate and die (like some people ;p) *)
  RF_RemoveSprite(sprite.next);
  continue;
   end;
     picnum := picnum + animationGraphic;
     sprite.animation :=  (sprite.animation) and (ANIM_LOOP_MASK) +
      (animationGraphic  shl  1) + (animationMax  shl  5) + (animationDelay  shl  9) +
      (sprite.animation) and (ANIM_SELFDEST);
     sprite.animationTime :=  timecount + animationDelay;
   end
   else if (sprite.animation) picnum+:= (sprite.animation) and (ANIM_CG_MASK) shr 1;

   deltax := sprite.x - viewx;
   if (deltax<-MAXZ) or (deltax>MAXZ) continue;
   deltay := sprite.y - viewy;
   if (deltay<-MAXZ) or (deltay>MAXZ) continue;

   // transform the point

   gxt := FIXEDMUL(deltax,viewcos);
   gyt := FIXEDMUL(deltay,viewsin);

   pointz := gxt-gyt;

   if (pointz>MAXZ) or (pointz<FRACUNIT*8) continue;

   // transform the point
   pointx := FIXEDMUL(deltax, viewsin) + FIXEDMUL(deltay, viewcos);
   // post the span event
   span := (pointz shl ZTOFRAC)) and (ZMASK;
   span) or (:= numspans;
   spantags[numspans] := span;
   span_p := @spans[numspans];
   span_p.spantype := sp_shape;
   span_p.picture := lumpmain[picnum];
   span_p.x2 := pointx;
   span_p.y := sprite.z-viewz;
   span_p.structure := sprite;
   mapy := sprite.y shr FRACTILESHIFT;
   mapx := sprite.x shr FRACTILESHIFT;
   mapspot := mapy*MAPCOLS+mapx;
   if (sprite.specialtype = st_noclip) span_p.shadow := (st_noclip shl 8);
    else span_p.shadow := (sprite.specialtype shl 8)+mapeffects[mapspot];
   if (sprite.specialtype = st_noclip) span_p.light := -1000;
    else span_p.light := (maplights[mapspot] shl 2) + reallight[mapspot];
   numspans++;
{$IFDEF VALIDATE}
   if (numspans >= MAXSPANS) MS_Error('MAXSPANS exceeded, RenderSprites (%i >= %i)',numspans,MAXSPANS);
{$ENDIF}
    end;
  end;

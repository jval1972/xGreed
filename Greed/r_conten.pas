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

unit r_conten;

interface

uses
  r_public_h;

var
  firstscaleobj, lastscaleobj: scaleobj_t; // just placeholders for links
  scaleobjlist: array[0..MAXSPRITES - 1] of scaleobj_t;
  freescaleobj_p: Pscaleobj_t;
  doorlist: array[0..MAXDOORS - 1] of doorobj_t;
  numdoors: integer;
  firstelevobj, lastelevobj: elevobj_t;
  elevlist: array[0..MAXELEVATORS - 1] of elevobj_t;
  freeelevobj_p: Pelevobj_t;
  spawnareas: array[0..MAXSPAWNAREAS - 1] of spawnarea_t;
  numspawnareas, rtimecount: integer;

procedure RenderSprites;

procedure RenderDoor;

implementation

uses
  g_delphi,
  d_disk,
  d_misc,
  d_ints,
  raven,
  r_public,
  r_refdef,
  r_render,
  r_spans,
  r_walls;

// returns vertex pointer of transformed vertex
function TransformPoint(const x, y: fixed_t): Pvertex_t;
var
  ttrx, ttry: fixed_t;
  scale: fixed_t;
  point: Pvertex_t;
begin
  point := vertexlist_p;
  inc(vertexlist_p);
{$IFDEF VALIDATE}
  if point = @vertexlist[MAXVISVERTEXES] then
    MS_Error('TransformPoint(): Vertexlist overflow (%d)', [MAXVISVERTEXES]);
{$ENDIF}
  ttrx := x - viewx;
  ttry := y - viewy;
  point.tx := FIXEDMUL(ttry, viewcos) + FIXEDMUL(ttrx, viewsin);
  point.tz := FIXEDMUL(ttrx, viewcos) - FIXEDMUL(ttry, viewsin);
  if point.tz >= MINZ then
  begin
    scale := FIXEDDIV(FSCALE, point.tz);
    point.px := CENTERX + (FIXEDMUL(point.tx, scale) div FRACUNIT);
  end;
  result := point;
end;


// Sets p1.px and p2.px correctly for Z values < MINZ
// Returns false if entire door is too close or far away
function ClipDoor: boolean;
var
  frac, clip: fixed_t;
begin
  if ((p1.tz > MAXZ) and (p2.tz > MAXZ)) or       // entire face is too far away
     ((p1.tz <= 0) and (p2.tz <= 0)) then
  begin
    result := false; // totally behind the projection plane
    exit;
  end;
  if p1.tz < MINZ then
  begin
    if p1.tz = 0 then
      clip := p1.tx
    else
    begin
      if p2.tz = p1.tz then
      begin
        result := false;
        exit;
      end;
      frac := FIXEDDIV(p2.tz, (p2.tz - p1.tz));
      clip := p2.tx + FIXEDMUL((p1.tx - p2.tx), frac);
    end;
    if clip < 0 then
      p1.px := 0
    else
      p1.px := windowWidth;
  end
  else if p2.tz < MINZ then
  begin
    if p2.tz = 0 then
      clip := p2.tx
    else
    begin
      if p2.tz = p1.tz then
      begin
        result := false;
        exit;
      end;
      frac := FIXEDDIV(p1.tz, (p1.tz - p2.tz));
      clip := p1.tx + FIXEDMUL((p2.tx - p1.tx), frac);
    end;
    if clip < 0 then
      p2.px := 0
    else
      p2.px := windowWidth;
  end;
  result := true;
end;


//  Posts one pixel wide span events for each visible post of the door a
//  tilex / tiley / xclipl / xcliph
//  sets doorxl, doorxh based on the position of the door.  One of the t
//  in the tile bounds, the other will be off the edge of the view.  The
//  restrict the flowing into other tiles bounds.
procedure RenderDoor;
var
  door_p, last_p: Pdoorobj_t;
  tx, ty: fixed_t;
  postindex: PBytePArray;   // start of the 64 entry texture table for t
  pointz: fixed_t;          // transformed distance to wall post
  anglecos: fixed_t;
  ceilingheight: fixed_t;   // top of the wall
  floorh: fixed_t;          // bottom of the wall
  angle: integer;           // the ray angle that strikes the current post
  texture: integer;         // 0-63 post number
  x, x1, x2: integer;       // collumn and ranges
  span_p: Pspan_t;
  span: LongWord;
  distance, absdistance, position: fixed_t;
  baseangle: integer;
  textureadjust: fixed_t;   // the amount the texture p1ane is shifted
  spantype: spanobj_t;
  wall: PSmallIntArray;
  p3: Pvertex_t;
label
  part2, part3;
begin
  // scan the doorlist for matching tilex/tiley
  // this only happens a couple times / frame max, so it's not a big deal
  last_p := @doorlist[numdoors];
  door_p := @doorlist[0];
  while door_p <> nil do
  begin
    if door_p.transparent then
      MS_Error('RenderDoor(): Door transparent');
    if (door_p.tilex = tilex) and (door_p.tiley = tiley) then
      break;
    inc(door_p);
  end;

  // transform both endpoints of the door
  // p1 is the anchored point, p2 is the moveable point
  tx := tilex * (TILESIZE * FRACUNIT);
  ty := tiley * (TILESIZE * FRACUNIT);
  position := door_p.position;
  case door_p.orientation of
  dr_horizontal:
    begin
      ty := ty + FRACUNIT * 27;
      p1 := TransformPoint(tx + position, ty);
      p2 := TransformPoint(tx, ty);
      textureadjust := viewx + TILEGLOBAL - (tx + position);
      baseangle := TANANGLES * 2;
      distance := viewy - ty;
      if player.northmap[mapspot] = 0 then
        player.northmap[mapspot] := DOOR_COLOR;
    end;
  dr_vertical:
    begin
      tx := tx + FRACUNIT * 27;
      p1 := TransformPoint(tx, ty + position);
      p2 := TransformPoint(tx, ty);
      textureadjust := viewy + TILEGLOBAL - (ty + position);
      baseangle := TANANGLES;
      distance := tx - viewx;
      if player.westmap[mapspot] = 0 then
        player.westmap[mapspot] := DOOR_COLOR;
    end;
  dr_horizontal2:
    begin
      tx := tx + TILEGLOBAL;
      ty := ty + FRACUNIT * 27;
      p1 := TransformPoint(tx - position, ty);
      p2 := TransformPoint(tx, ty);
      textureadjust := viewx + TILEGLOBAL - (tx - position);
      baseangle := TANANGLES * 2;
      distance := viewy - ty;
      if player.northmap[mapspot] = 0 then
        player.northmap[mapspot] := DOOR_COLOR;
    end;
  dr_vertical2:
    begin
      tx := tx + FRACUNIT * 27;
      ty := ty + TILEGLOBAL;
      p1 := TransformPoint(tx, ty - position);
      p2 := TransformPoint(tx, ty);
      textureadjust := viewy + TILEGLOBAL - (ty - position);
      baseangle := TANANGLES;
      distance := tx - viewx;
      if player.westmap[mapspot] = 0 then
        player.westmap[mapspot] := DOOR_COLOR;
    end;
  else
    MS_Error('RenderDoor(): Unknown door orientation (%d)', [Ord(door_p.orientation)]);
    exit;
  end;

  if p1.px > p2.px then
  begin
    p3 := p1;
    p1 := p2;
    p2 := p3;
  end;

  if (door_p.position = 0) or not ClipDoor then
    goto part2;

  x1 := p1.px;
  x2 := p2.px;

  // calculate the textures to post into the span list
  if x1 < xclipl then
    x1 := xclipl;
  if x2 > xcliph + 1 then
    x2 := xcliph + 1;
  if x1 >= x2 then
    goto part2; // totally clipped off side

  // set up for loop
  if door_p.transparent then
  begin
    spantype := sp_maskeddoor;
    doortile :=  false;
  end
  else
    spantype := sp_door;
  walltype := door_p.pic;
  walltype := walltranslation[walltype];     // global animation
  dec(walltype);                             // make 0 based
  wall := lumpmain[walllump + walltype];
  ceilingheight := vertex[0].ceilingheight;
  floorh := -vertex[0].floorheight;
  postindex := @wallposts[walltype * 64];      // 64 pointers to texture starts
  baseangle := baseangle + viewfineangle;
  absdistance := absI(distance);
  // step through the individual posts
  for x := x1 to x2 - 1 do
  begin
    angle := baseangle + pixelangle[x];
    angle := angle and (TANANGLES * 2 - 1);
    // the z distance of the post hit :=  walldistance*cos(screenangle
    anglecos := cosines[(angle - TANANGLES) and (TANANGLES * 4 - 1)];
    if anglecos < 8000 then
      continue;
    pointz := FIXEDDIV(absdistance, anglecos);
    pointz := FIXEDMUL(pointz, pixelcosine[x]);
    if (pointz > MAXZ) or (pointz < MINZ) then
      continue;

    // calculate the texture post along the wall that was hit
    texture := (textureadjust + FIXEDMUL(distance, tangents[angle])) div FRACUNIT;
    texture := texture and 63;
    sp_source := postindex[texture];

    // post the span in the draw list
    span := (pointz * ZTOFRACUNIT) and ZMASK;
    spansx[numspans] := x;
    span := span or numspans;
    spantags[numspans] := span;
    span_p := @spans[numspans];
    span_p.spantype := spantype;
    span_p.picture := sp_source;
    span_p.y := ceilingheight;
    span_p.yh := floorh;
    span_p.structure := door_p;
    span_p.light := maplight;
    span_p.shadow := wallshadow;

    inc(numspans);
{$IFDEF VALIDATE}
    if numspans >= MAXSPANS then
      MS_Error('MAXSPANS exceeded, RenderDoor (%d)', [MAXSPANS]);
{$ENDIF}
  end;

part2:
  tx := tilex * (TILESIZE * FRACUNIT);
  ty := tiley * (TILESIZE * FRACUNIT);
  position := door_p.position;
  case door_p.orientation of
  dr_horizontal:
    begin
      ty := ty + FRACUNIT * 37;
      p1 := TransformPoint(tx + position, ty);
      p2 := TransformPoint(tx, ty);
      textureadjust := viewx + TILEGLOBAL - (tx + position);
      baseangle := TANANGLES * 2;
      distance := viewy - ty;
      if player.northmap[mapspot] = 0 then
        player.northmap[mapspot] := DOOR_COLOR;
    end;
  dr_vertical:
    begin
      tx := tx + FRACUNIT * 37;
      p1 := TransformPoint(tx, ty + position);
      p2 := TransformPoint(tx, ty);
      textureadjust := viewy + TILEGLOBAL - (ty + position);
      baseangle := TANANGLES;
      distance := tx - viewx;
      if player.westmap[mapspot] = 0 then
        player.westmap[mapspot] := DOOR_COLOR;
    end;
  dr_horizontal2:
    begin
      tx := tx + TILEGLOBAL;
      ty := ty + FRACUNIT * 37;
      p1 := TransformPoint(tx - position, ty);
      p2 := TransformPoint(tx, ty);
      textureadjust := viewx + TILEGLOBAL - (tx - position);
      baseangle := TANANGLES * 2;
      distance := viewy - ty;
      if player.northmap[mapspot] = 0 then
        player.northmap[mapspot] := DOOR_COLOR;
    end;
  dr_vertical2:
    begin
      tx := tx + FRACUNIT * 37;
      ty := ty + TILEGLOBAL;
      p1 := TransformPoint(tx, ty - position);
      p2 := TransformPoint(tx, ty);
      textureadjust := viewy + TILEGLOBAL - (ty - position);
      baseangle := TANANGLES;
      distance := tx - viewx;
      if player.westmap[mapspot] = 0 then
        player.westmap[mapspot] := DOOR_COLOR;
    end;
  end;

  if p1.px > p2.px then
  begin
    p3 := p1;
    p1 := p2;
    p2 := p3;
  end;

  if (door_p.position = 0) or not ClipDoor then
    goto part3;

  x1 := p1.px;
  x2 := p2.px;
  if x1 < xclipl then
    x1 := xclipl;
  if x2 > xcliph + 1 then
    x2 := xcliph + 1;
  if x1 >= x2 then
    goto part3;

  // set up for loop
  if door_p.transparent then
  begin
    spantype := sp_maskeddoor;
    doortile := false;
  end
  else
    spantype := sp_door;
  walltype := door_p.pic;
  walltype := walltranslation[walltype];     // global animation
  inc(walltype);                             // make 0 based
  wall := lumpmain[walllump + walltype];
  ceilingheight := vertex[0].ceilingheight;
  floorh := -vertex[0].floorheight;
  postindex := @wallposts[walltype * 64];      // 64 pointers to texture starts
  baseangle := baseangle + viewfineangle;
  absdistance := absI(distance);
  // step through the individual posts
  for x := x1 to x2 - 1 do
  begin
    angle := baseangle + pixelangle[x];
    angle := angle and (TANANGLES * 2 - 1);
    // the z distance of the post hit :=  walldistance*cos(screenangle
    anglecos := cosines[(angle - TANANGLES) and (TANANGLES * 4 - 1)];
    if anglecos < 8000 then
      continue;
    pointz := FIXEDDIV(absdistance, anglecos);
    pointz := FIXEDMUL(pointz, pixelcosine[x]);
    if pointz > MAXZ then
      exit;
    if pointz < MINZ then
      continue;

    // calculate the texture post along the wall that was hit
    texture := (textureadjust + FIXEDMUL(distance, tangents[angle])) div FRACUNIT;
    texture := texture and 63;
    sp_source := postindex[texture];

    // post the span in the draw list
    span := (pointz * ZTOFRACUNIT) and ZMASK;
    spansx[numspans] := x;
    span := span or numspans;
    spantags[numspans] := span;
    span_p := @spans[numspans];
    span_p.spantype := spantype;
    span_p.picture := sp_source;
    span_p.y := ceilingheight;
    span_p.yh := floorh;
    span_p.structure := door_p;
    span_p.light := maplight;
    span_p.shadow := wallshadow;

    inc(numspans);
{$IFDEF VALIDATE}
    if numspans >= MAXSPANS then
      MS_Error('MAXSPANS exceeded, RenderDoor (%d)', [MAXSPANS]);
{$ENDIF}
    end;

part3:
  tx := tilex * (TILESIZE * FRACUNIT);
  ty := tiley * (TILESIZE * FRACUNIT);
  case door_p.orientation of
  dr_horizontal:
    begin
      ty := ty + FRACUNIT * 32;
      tx := tx + position;
      p1 := TransformPoint(tx, ty + (5 * FRACUNIT));
      p2 := TransformPoint(tx, ty - (5 * FRACUNIT));
      textureadjust := viewy + TILEGLOBAL - ty;
      baseangle := TANANGLES;
      distance := tx - viewx;
    end;
  dr_vertical:
    begin
      tx := tx + FRACUNIT * 32;
      ty := ty + position;
      p1 := TransformPoint(tx + (5 * FRACUNIT), ty);
      p2 := TransformPoint(tx - (5 * FRACUNIT), ty);
      textureadjust := viewx + TILEGLOBAL - tx;
      baseangle := TANANGLES * 2;
      distance := viewy - ty;
    end;
  dr_horizontal2:
    begin
      ty := ty + FRACUNIT * 32;
      tx := tx + FRACUNIT * 64 - position;
      p1 := TransformPoint(tx, ty + (5 * FRACUNIT));
      p2 := TransformPoint(tx, ty - (5 * FRACUNIT));
      textureadjust := viewy + TILEGLOBAL - ty;
      baseangle := TANANGLES;
      distance := tx - viewx;
    end;
  dr_vertical2:
    begin
      tx := tx + FRACUNIT * 32;
      ty := ty + FRACUNIT * 64 - position;
      p1 := TransformPoint(tx + (5 * FRACUNIT), ty);
      p2 := TransformPoint(tx - (5 * FRACUNIT), ty);
      textureadjust := viewx + TILEGLOBAL - tx;
      baseangle := TANANGLES * 2;
      distance := viewy - ty;
    end;
  end;

  if p1.px > p2.px then
  begin
    p3 := p1;
    p1 := p2;
    p2 := p3;
  end;

  if (door_p.position = 0) or not ClipDoor then
    exit;

  x1 := p1.px;
  x2 := p2.px;

  // calculate the textures to post into the span list
  if x1 < xclipl then
    x1 := xclipl;
  if x2 > xcliph + 1 then
    x2 := xcliph + 1;
  if x1 >= x2 then
    exit;  // totally clipped off side

  // set up for loop
  walltype := 2;
  wall := lumpmain[walllump + walltype];
  postindex := @wallposts[walltype * 64];      // 64 pointers to texture starts
  baseangle := baseangle + viewfineangle;
  absdistance := absI(distance);
  // step through the individual posts
  for x := x1 to x2 - 1 do
  begin
    angle := baseangle + pixelangle[x];
    angle := angle and (TANANGLES * 2 - 1);
    // the z distance of the post hit :=  walldistance*cos(screenangle
    anglecos := cosines[(angle - TANANGLES) and (TANANGLES * 4 - 1)];
    if anglecos < 8000 then
      continue;
    pointz := FIXEDDIV(absdistance, anglecos);
    pointz := FIXEDMUL(pointz, pixelcosine[x]);
    if pointz > MAXZ then
      exit;
    if pointz < MINZ then
      continue;

    // calculate the texture post along the wall that was hit
    texture := (textureadjust + FIXEDMUL(distance, tangents[angle])) div FRACUNIT;
    texture := texture and 63;
    sp_source := postindex[texture];

    // post the span in the draw list
    span := (pointz * ZTOFRACUNIT) and ZMASK;
    spansx[numspans] := x;
    span := span or numspans;
    spantags[numspans] := span;
    span_p := @spans[numspans];
    span_p.spantype := spantype;
    span_p.picture := sp_source;
    span_p.y := ceilingheight;
    span_p.yh := floorh;
    span_p.structure := door_p;
    span_p.light := maplight;
    span_p.shadow := wallshadow;

    inc(numspans);
{$IFDEF VALIDATE}
    if numspans >= MAXSPANS then
      MS_Error('MAXSPANS exceeded, RenderDoor (%d)', [MAXSPANS]);
{$ENDIF}
  end;

end;


// For each sprite, if the sprite's bounding rect touches a tile with a
// vertex, transform and clip the projected view rect.  If still visible
// a span into the span list
procedure RenderSprite(var sprite: Pscaleobj_t);
var
  deltax, deltay, pointx, pointz, gxt, gyt: fixed_t;
  picnum: integer;
  span: LongWord;
  span_p: Pspan_t;
  animationGraphic, animationMax, animationDelay: byte;
  mapx, mapy, mapspot: integer;
begin
  // calculate which image to display
  picnum := sprite.basepic;
  if sprite.rotate <> rt_one then
  begin    // this is only aproximate, but ok for 8
    if sprite.rotate = rt_eight then
      picnum := picnum + ((viewangle - sprite.angle + WEST + DEGREE45_2) div 128) and 7
    else
      picnum := picnum + ((viewangle - sprite.angle + WEST + DEGREE45) div 256) and 3;
  end;

  if (sprite.animation <> 0) and (rtimecount >= sprite.animationTime) then
  begin
    animationGraphic := (sprite.animation and ANIM_CG_MASK) div 2;
    animationMax := (sprite.animation and ANIM_MG_MASK) div 32;
    animationDelay := (sprite.animation and ANIM_DELAY_MASK) shr 9;
    if animationGraphic < animationMax - 1 then
      inc(animationGraphic)
    else if sprite.animation and ANIM_LOOP_MASK <> 0 then
      animationGraphic := 0
    else if sprite.animation and ANIM_SELFDEST <> 0 then
    begin
      sprite := sprite.prev; // some sprites exist only to animate and die (like some people ;p)
      RF_RemoveSprite(sprite.next);
      exit;
    end;
    picnum := picnum + animationGraphic;
    sprite.animation := (sprite.animation and ANIM_LOOP_MASK) +
                        (animationGraphic * 2) + (animationMax * 32) + (animationDelay shl 9) +
                        (sprite.animation and ANIM_SELFDEST);
    sprite.animationTime := timecount + animationDelay;
  end
  else if sprite.animation <> 0 then
    picnum := picnum + (sprite.animation and ANIM_CG_MASK) div 2;

  deltax := sprite.x - viewx;
  if (deltax < -MAXZ) or (deltax > MAXZ) then
    exit;
  deltay := sprite.y - viewy;
  if (deltay < -MAXZ) or (deltay > MAXZ) then
    exit;

  // transform the point

  gxt := FIXEDMUL(deltax, viewcos);
  gyt := FIXEDMUL(deltay, viewsin);

  pointz := gxt - gyt;

  if (pointz > MAXZ) or (pointz < FRACUNIT * 8) then
    exit;

  // transform the point
  pointx := FIXEDMUL(deltax, viewsin) + FIXEDMUL(deltay, viewcos);
  // post the span event
  span := (pointz * ZTOFRACUNIT) and ZMASK;
  span := span or numspans;
  spantags[numspans] := span;
  span_p := @spans[numspans];
  span_p.spantype := sp_shape;
  span_p.picture := lumpmain[picnum];
  span_p.x2 := pointx;
  span_p.y := sprite.z - viewz;
  span_p.structure := sprite;
  mapy := sprite.y div FRACTILEUNIT;
  mapx := sprite.x div FRACTILEUNIT;
  mapspot := mapy * MAPCOLS + mapx;
  if sprite.specialtype = st_noclip then
    span_p.shadow := Ord(st_noclip) * 256
  else
    span_p.shadow := Ord(sprite.specialtype) * 256 + mapeffects[mapspot];
  if sprite.specialtype = st_noclip then
    span_p.light := -1000
  else
    span_p.light := (maplights[mapspot] * 4) + reallight[mapspot];
  inc(numspans);
{$IFDEF VALIDATE}
  if numspans >= MAXSPANS then
    MS_Error('MAXSPANS exceeded, RenderSprites (%d)', [MAXSPANS]);
{$ENDIF}
end;

procedure RenderSprites;
var
  sprite: Pscaleobj_t;
begin
  sprite := firstscaleobj.next;
  while sprite <> @lastscaleobj do
  begin
    RenderSprite(sprite);
    sprite := sprite.next;
  end;
end;

end.


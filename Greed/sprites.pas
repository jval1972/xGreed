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

unit sprites;

interface

uses
  r_public_h;

var

  msprite: Pscaleobj_t;
  probe: scaleobj_t;
  spritehit, playerhit: boolean;
  hitx, hity, targx, targy, targz: fixed_t;
  spriteloc: integer; // where did it hit on a sprite

implementation

uses
  modplay,
  protos_h,
  r_conten,
  r_render;

function SP_TryDoor(const xcenter, ycenter: fixed_t): boolean;
var
  xl, yl, xh, yh, x, y: integer;
  door_p, last_p: Pdoorobj_t;
begin
  if msprite = @probe then
  begin
    result := true;
    exit;
  end;

  // These values will probably have to be tweaked for doors that are along
  // the vertical opposite axis (northwall)
  xl := ((xcenter - msprite.movesize) shr FRACTILESHIFT);
  yl := ((ycenter - msprite.movesize(* - (TILEUNIT shr 1)*)) shr FRACTILESHIFT);
  xh := ((xcenter + msprite.movesize) shr FRACTILESHIFT);
  yh := ((ycenter + msprite.movesize(* - (TILEUNIT shr 1)*)) shr FRACTILESHIFT);
  // check for doors on the north wall
  for y := yl + 1 to yh do
    for x := xl to xh do
    begin
      if mapflags[y * MAPSIZE + x] and FL_DOOR <> 0 then  // if tile has a door
      begin
        last_p := @doorlist[numdoors];
        door_p := @doorlist[0];
        while door_p <> last_p do
        begin
          if (door_p.tilex = x) and (door_p.tiley = y) and ((door_p.orientation = dr_horizontal) or (door_p.orientation = dr_horizontal2)) then
          begin
            if door_p.doorOpen and not door_p.doorClosing then
            begin
              result := true; // can move, door is open
              exit;
            end
            else if not door_p.doorOpen and door_p.doorBumpable and not door_p.doorOpening then
            begin
              door_p.doorOpening := true;
              door_p.doorClosing := false;
              SoundEffect(SN_DOOR, 15, door_p.tilex shl FRACTILESHIFT, door_p.tiley shl FRACTILESHIFT);
              door_p.doorTimer := door_p.doorTimer + 20;
              if door_p.orientation = dr_horizontal then
                SP_TryDoor(xcenter + 64 * FRACUNIT, ycenter)
              else
                SP_TryDoor(xcenter - 64 * FRACUNIT, ycenter);
              result := false;
              exit;
            end
            else if not door_p.doorOpen and door_p.doorBumpable and door_p.doorClosing then
            begin
              door_p.doorClosing := false;
              door_p.doorOpening := true;
              SoundEffect(SN_DOOR, 15, door_p.tilex shl FRACTILESHIFT, door_p.tiley shl FRACTILESHIFT);
              door_p.doorTimer := door_p.doorTimer + 20;
              if door_p.orientation = dr_horizontal then
                SP_TryDoor(xcenter + 64 * FRACUNIT, ycenter)
              else
                SP_TryDoor(xcenter - 64 * FRACUNIT, ycenter);
              result := false;
              exit;
            end
            else
            begin
              result := false;
              exit;
            end;
          end;
          inc(door_p);
        end;
      end;
    end;

  // check for doors on the west wall
  xl := ((xcenter - msprite.movesize(* - (TILEUNIT shr 1)*)) shr FRACTILESHIFT);
  yl := ((ycenter - msprite.movesize) shr FRACTILESHIFT);
  xh := ((xcenter + msprite.movesize(* - (TILEUNIT shr 1)*)) shr FRACTILESHIFT);
  yh := ((ycenter + msprite.movesize) shr FRACTILESHIFT);
  for y := yl to yh do
    for x := xl + 1 to xh do
    begin
      if mapflags[y * MAPSIZE + x] and FL_DOOR <> 0 then // if tile has a door
      begin
        last_p := @doorlist[numdoors];
        door_p := @doorlist[0];
        while door_p <> last_p do
        begin
          if (door_p.tilex = x) and (door_p.tiley = y) and ((door_p.orientation = dr_vertical) or (door_p.orientation = dr_vertical2)) then
          begin
            if door_p.doorOpen and not door_p.doorClosing then
            begin
              result := true; // can move, door is open
              exit;
            end
            else if not door_p.doorOpen and door_p.doorBumpable and not door_p.doorOpening then
            begin
              door_p.doorOpening := true;
              door_p.doorClosing := false;
              SoundEffect(SN_DOOR, 15, door_p.tilex shl FRACTILESHIFT, door_p.tiley shl FRACTILESHIFT);
              door_p.doorTimer := door_p.doorTimer + 20;
              if door_p.orientation = dr_vertical then
                SP_TryDoor(xcenter, ycenter + 64 * FRACUNIT)
              else
                SP_TryDoor(xcenter, ycenter - 64 * FRACUNIT);
              result := false;
              exit;
            end
            else if not door_p.doorOpen and door_p.doorBumpable and door_p.doorClosing then
            begin
              door_p.doorClosing := false;
              door_p.doorOpening := true;
              SoundEffect(SN_DOOR, 15, door_p.tilex shl FRACTILESHIFT, door_p.tiley shl FRACTILESHIFT);
              door_p.doorTimer := door_p.doorTimer + 20;
              if door_p.orientation = dr_vertical then
                SP_TryDoor(xcenter, ycenter + 64 * FRACUNIT)
              else
                SP_TryDoor(xcenter, ycenter - 64 * FRACUNIT);
              result := false;
              exit;
            end
            else
            begin
              result := false;
              exit;
            end;
          end;
          inc(door_p);
        end;
      end;
    end;

  result := true;
end;


function SP_TryMove(const xcenter, ycenter: fixed_t): integer;
var
  xl, yl, xh, yh, x, y, mapspot: integer;
begin
  xl := ((xcenter - msprite.movesize) shr FRACTILESHIFT);
  yl := ((ycenter - msprite.movesize) shr FRACTILESHIFT);
  xh := ((xcenter + msprite.movesize) shr FRACTILESHIFT);
  yh := ((ycenter + msprite.movesize) shr FRACTILESHIFT);
  for y := yl to yh do
    for x := xl to xh do
    begin
      mapspot := MAPCOLS * y + x;
      if ((y > yl) and (northwall[mapspot] <> 0) and (northflags[mapspot] and F_NOCLIP = 0) and (northflags[mapspot] and F_NOBULLETCLIP = 0)) or
         ((x > xl) and (westwall[mapspot] <> 0) and (westflags[mapspot] and F_NOCLIP = 0) and (westflags[mapspot] and F_NOBULLETCLIP = 0)) then
      begin
        result := 2; // wall hit
        exit;
      end;
      if msprite <> @probe then
      begin
        if msprite.z < RF_GetFloorZ((x shl FRACTILESHIFT) + (32 shl FRACBITS), (y shl FRACTILESHIFT) + (32 shl FRACBITS)) then
        begin
          result := 2;    // below floor
          exit;
        end;
        if msprite.z > RF_GetCeilingZ((x shl FRACTILESHIFT) + (32 shl FRACBITS), (y shl FRACTILESHIFT) + (32 shl FRACBITS)) then
        begin
          result := 2; // below ceiling
          exit;
        end;
      end;

      if mapsprites[mapspot] = 64 then
      begin
        result := 2; // instawall
        exit;
      end;

      if (mapsprites[mapspot] > 0) and (mapsprites[mapspot] < 128) and (mapspot <> msprite.startspot) then
      begin
        spritehit := true;
        spriteloc := mapspot;
        result := 1;
        exit;
      end;

      if (mapspot = player.mapspot) and (mapspot <> msprite.startspot) and (msprite.spawnid <> playernum) then  // can't shot yourself
      begin
        playerhit := true;
        result := 1;
        exit;
      end;
    end;

  result := 0;
end;


function SP_ClipMove(const xmove, ymove, zmove: fixed_t): byte;
var
  dx, dy: fixed_t;
begin
  dx := msprite.x + xmove;
  dy := msprite.y + ymove;
  spritehit := false;
  result := SP_TryMove(dx, dy);
  if result <> 0 then
  begin
    hitx := dx;
    hity := dy;
  end;
  if (result <> 2) and not SP_TryDoor(dx, dy) then
    result := 2;  // door hit or wall hit
  if result <> 2 then
  begin
    msprite.x := msprite.x + xmove;
    msprite.y := msprite.y + ymove;
    msprite.z := msprite.z + zmove;
  end;
end;


function SP_Thrust: byte;
begin
  msprite.angle := msprite.angle and ANGLES;
  msprite.angle2 := msprite.angle2 and ANGLES;
  result := SP_ClipMove(costable[msprite.angle], -sintable[msprite.angle], sintable[msprite.angle2]);
end;


function SP_TryMove2(const angle: integer; const xcenter, ycenter: fixed_t; const smapspot: integer): boolean;
var
  xl, yl, xh, yh, x, y, mapspot: integer;
  sz, sz2, floorz, ceilingz: fixed_t;
begin
  if (angle < NORTH) or (angle > SOUTH) then
  begin
    xl := xcenter shr FRACTILESHIFT;
    xh := (xcenter + msprite.movesize) shr FRACTILESHIFT;
  end
  else if (angle > NORTH) and (angle < SOUTH) then
  begin
    xh := xcenter shr FRACTILESHIFT;
    xl := (xcenter - msprite.movesize) shr FRACTILESHIFT;
  end
  else
  begin
    xl := (xcenter - msprite.movesize) shr FRACTILESHIFT;
    xh := (xcenter + msprite.movesize) shr FRACTILESHIFT;
  end;

  if angle > WEST then
  begin
    yl := ycenter shr FRACTILESHIFT;
    yh := (ycenter + msprite.movesize) shr FRACTILESHIFT;
  end
  else if (angle < WEST) and (angle <> EAST) then
  begin
    yl := (ycenter - msprite.movesize) shr FRACTILESHIFT;
    yh := ycenter shr FRACTILESHIFT;
  end
  else
  begin
    yl := (ycenter - msprite.movesize) shr FRACTILESHIFT;
    yh := (ycenter + msprite.movesize) shr FRACTILESHIFT;
  end;
  sz :=  msprite.z - msprite.zadj + (20 shl FRACBITS);
  sz2 :=  msprite.z - msprite.zadj;
  for y := yl to yh do
    for x := xl to xh do
    begin
      mapspot := MAPCOLS * y + x;
      if (mapspot = player.mapspot) or
         ((y > yl) and (northwall[mapspot] <> 0) and (northflags[mapspot] and F_NOCLIP = 0)) or
         ((x > xl) and (westwall[mapspot] <> 0) and (westflags[mapspot] and F_NOCLIP = 0)) then
      begin
        result := false; // wall hit
        exit;
      end;

      floorz := RF_GetFloorZ((x shl FRACTILESHIFT) + (32 shl FRACBITS), (y shl FRACTILESHIFT) + (32 shl FRACBITS));
      if floorz > sz then
      begin
        result := false;
        exit;
      end;

      if msprite.nofalling and (floorz + (5 shl FRACBITS) < sz2) then
      begin
        result := false;
        exit;
      end;

      ceilingz := RF_GetCeilingZ((x shl FRACTILESHIFT) + (32 shl FRACBITS), (y shl FRACTILESHIFT) + (32 shl FRACBITS));
      if ceilingz < msprite.z + msprite.height then
      begin
        result := false;
        exit;
      end;

      if ceilingz - floorz < msprite.height then
      begin
        result := false;
        exit;
      end;

      if (mapspot <> smapspot) and (mapsprites[mapspot] <> 0) then
      begin
        result := false;
        exit;
      end;
    end;

  result := true;
end;


function SP_ClipMove2(const xmove, ymove: fixed_t): byte;
var
  dx, dy: fixed_t;
  smapspot, angle2, ms: integer;
begin
  if msprite.typ = S_CLONE then
    ms := SM_CLONE
  else
    ms := 1;
  dx := msprite.x + xmove;
  dy := msprite.y + ymove;
  smapspot := (msprite.y shr FRACTILESHIFT) * MAPCOLS + (msprite.x shr FRACTILESHIFT);
  if SP_TryMove2(msprite.angle, dx, dy, smapspot) and SP_TryDoor(dx, dy) then
  begin
    if floorpic[(dy shr FRACTILESHIFT) * MAPCOLS + (dx shr FRACTILESHIFT)] = 0 then
    begin
      result := 0;
      exit;
    end;

    mapsprites[smapspot] := 0;
    msprite.x := msprite.x + xmove;
    msprite.y := msprite.y + ymove;
    mapsprites[(msprite.y shr FRACTILESHIFT) * MAPCOLS + (msprite.x shr FRACTILESHIFT)] := ms;
    result := 1;
    exit;
  end;

  // the move goes into a wall, so try and move along one axis
  if xmove > 0 then
  begin
    angle2 := EAST;
    dx := msprite.x + msprite.moveSpeed;
  end
  else
  begin
    angle2 := WEST;
    dx := msprite.x - msprite.moveSpeed;
  end
  if SP_TryMove2(angle2, dx, msprite.y, smapspot) and SP_TryDoor(dx, msprite.y) then
  begin
    if floorpic[(msprite.y shr FRACTILESHIFT) * MAPCOLS + (dx shr FRACTILESHIFT)] = 0 then
    begin
      result := 0;
      exit;
    end;
    mapsprites[smapspot] := 0;
    msprite.x := msprite.x + xmove;
    mapsprites[(msprite.y shr FRACTILESHIFT) * MAPCOLS + (msprite.x shr FRACTILESHIFT)] := ms;
    result := 2;
  end;

  if ymove > 0 then
  begin
    angle2 := SOUTH;
    dy := msprite.y + msprite.moveSpeed;
  end
  else
  begin
    angle2 := NORTH;
    dy := msprite.y - msprite.moveSpeed;
  end
  if SP_TryMove2(angle2, msprite.x, dy, smapspot) and SP_TryDoor(msprite.x, dy) then
  begin
    if floorpic[(dy shr FRACTILESHIFT) * MAPCOLS + (msprite.x shr FRACTILESHIFT)] = 0 then
    begin
      result := 0;
      exit;
    end;
    mapsprites[smapspot] := 0;
    msprite.y := msprite.y + ymove;
    mapsprites[(msprite.y shr FRACTILESHIFT) * MAPCOLS + (msprite.x shr FRACTILESHIFT)] := ms;
    result := 3;
    exit;
  end;

  result := 0;
end;


function SP_Thrust2: byte;
var
  xmove, ymove: fixed_t;
begin
  msprite.angle := msprite.angle and ANGLES;
  xmove := FIXEDMUL(msprite.moveSpeed, costable[msprite.angle]);
  ymove := -FIXEDMUL(msprite.moveSpeed, sintable[msprite.angle]);
  result := SP_ClipMove2(xmove, ymove);
end;


procedure ActivationSound(const sp: Pscaleobj_t);
begin
  case sp.typ  of
  S_MONSTER1: SoundEffect(SN_MON1_WAKE, 7, sp.x, sp.y);
  S_MONSTER2: SoundEffect(SN_MON2_WAKE, 7, sp.x, sp.y);
  S_MONSTER3: SoundEffect(SN_MON3_WAKE, 7, sp.x, sp.y);
  S_MONSTER4: SoundEffect(SN_MON4_WAKE, 7, sp.x, sp.y);
  S_MONSTER5: SoundEffect(SN_MON5_WAKE, 7, sp.x, sp.y);
  S_MONSTER6: SoundEffect(SN_MON6_WAKE, 7, sp.x, sp.y);
  S_MONSTER7: SoundEffect(SN_MON7_WAKE, 7, sp.x, sp.y);
  S_MONSTER8: SoundEffect(SN_MON8_WAKE, 7, sp.x, sp.y);
  S_MONSTER9: SoundEffect(SN_MON9_WAKE, 7, sp.x, sp.y);
  S_MONSTER10: SoundEffect(SN_MON10_WAKE, 7, sp.x, sp.y);
  S_MONSTER11: SoundEffect(SN_MON11_WAKE, 7, sp.x, sp.y);
  S_MONSTER12: SoundEffect(SN_MON12_WAKE, 7, sp.x, sp.y);
  S_MONSTER13: SoundEffect(SN_MON13_WAKE, 7, sp.x, sp.y);
  S_MONSTER14: SoundEffect(SN_MON14_WAKE, 7, sp.x, sp.y);
  S_MONSTER15: SoundEffect(SN_MON15_WAKE, 7, sp.x, sp.y);
  end;
end;


// proximity activation (recursive chain reaction)
procedure ActivateSprites(int sx,int sy);
  scaleobj_t *sp;
  x, y: integer;
begin
  sp := firstscaleobj.next;
  while sp <> @lastscaleobj do
  begin
    if (sp.active = false) and (sp.moveSpeed <> 0) then
    begin
      x := sp.x shr FRACTILESHIFT;
      y := sp.y shr FRACTILESHIFT;
      if (absI(x - sx) < 5) and (absI(y - sy) < 5) then
      begin
        sp.active := true;
        sp.actiontime := timecount + 40;
        ActivationSound(sp);
        ActivationSound(sp);
        ActivateSprites(x, y);
      end;
    end;
    sp := sp.next;
  end;
end;

procedure ShowWallPuff;
var
  i: integer;
begin
  case msprite.typ of
  S_BULLET3,
  S_BULLET12,
  S_BULLET17,
  S_MONSTERBULLET2,
  S_MONSTERBULLET4,
  S_MONSTERBULLET6,
  S_MONSTERBULLET8,
  S_GRENADEBULLET:
    i := S_SMALLEXPLODE;

  S_BULLET4,
  S_MONSTERBULLET5,
  S_MONSTERBULLET11:
    i := S_PLASMAWALLPUFF;

  S_HANDBULLET,
  S_BLOODSPLAT,
  S_BULLET7,
  S_MONSTERBULLET7,
  S_MONSTERBULLET10,
  S_MONSTERBULLET12,
  S_MONSTERBULLET15,
  S_SOULBULLET:
    exit;

  S_BULLET9:
    i := S_ARROWPUFF;

  S_BULLET10,
  S_BULLET18:
    i := S_GREENPUFF;

  S_MINEBULLET:
    i := S_MINEPUFF;

  else
    i := S_WALLPUFF;
  end;
  SpawnSprite(i, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
  ActivateSprites(msprite.x shr FRACTILESHIFT, msprite.y shr FRACTILESHIFT);
end;


procedure HitSprite(const sp: Pscaleobj_t);
begin
  case sp.typ  of
  S_CLONE:
    begin
      if not sp.active then
      begin
        ActivateSprites(sp.x shr FRACTILESHIFT, sp.y shr FRACTILESHIFT);
        sp.active := true;
      end;
      sp.modetime := timecount + 8;
      sp.basepic := sp.startpic + 32;
      SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
      if msprite.typ <> S_BULLET17 then
      begin
        SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
        SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
        SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
        SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
        SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
      end;
    end;

  S_MONSTER1,
  S_MONSTER2,
  S_MONSTER7,
  S_MONSTER9,
  S_MONSTER10,
  S_MONSTER12,
  S_MONSTER13,
  S_MONSTER14,
  S_MONSTER15:
    begin
      if not sp.active then
      begin
        ActivateSprites(sp.x shr FRACTILESHIFT, sp.y shr FRACTILESHIFT);
        sp.active := true;
      end;
      sp.modetime := timecount + 8;
      sp.basepic := sp.startpic + 40;
      SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
      if msprite.typ <> S_BULLET17 then
      begin
        SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
        SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
        SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
        SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
        SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
      end;
    end;

  S_MONSTER3,
  S_MONSTER4,
  S_MONSTER5,
  S_MONSTER6,
  S_MONSTER8,
  S_MONSTER11:
    ShowWallPuff;
  end;
end;


// control of bullets, explosions, and other objects (not monsters!!)
procedure Int0: boolean;
var
  hsprite, sp: Pscaleobj_t;
  counter, mapspot, angle, angleinc, i, oldfall: integer;
  oldangle, oldmovespeed: integer;
  killed, blood: boolean;
begin
  counter := 0;
  killed := false;

  if msprite.typ = S_GRENADE then
    msprite.angle2 := msprite.angle2 - 4
  else if ((msprite.typ = S_BLOODSPLAT) or (msprite.typ = S_METALPARTS)) and ((msprite.angle2 < NORTH) or (msprite.angle2 > SOUTH))
    msprite.angle2 := msprite.angle2 - 32;

  if msprite.maxmove <> 0 then
  begin
    dec(msprite.maxmove);
    if msprite.maxmove <= 0 then
    begin
      ShowWallPuff;
      result := true;
      exit;
    end;
  end;

  if (msprite.typ = S_MONSTERBULLET4) or (msprite.typ = S_MONSTERBULLET6) or (msprite.typ = S_BULLET17) then
    SpawnSprite(S_WALLPUFF, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);

  blood := false;
  while counter++<msprite.moveSpeed do
  begin
   result := SP_Thrust;
   if msprite.typ = S_BULLET3 then
    msprite.z := RF_GetFloorZ(msprite.x, msprite.y) + (20 shl FRACBITS);

   if result <> 0 then
   begin
     if msprite.typ = S_BLOODSPLAT then
     begin
       if (result = 2) return true;
       spritehit := false;
       playerhit := false;
     end
     else if (msprite.typ = S_METALPARTS) and (result = 2) then
     begin
       playerhit := false;
       return true;
        end;
     if spritehit then
     begin
       if mapsprites[spriteloc] = SM_NETPLAYER then
       begin
   for(hsprite := firstscaleobj.next;hsprite <> @lastscaleobj;hsprite := hsprite.next)
    if hsprite <> msprite then
    begin
      mapspot := (hsprite.y shr FRACTILESHIFT) * MAPCOLS + (hsprite.x shr FRACTILESHIFT);
      if mapspot = spriteloc then
      begin
        if (msprite.z<hsprite.z) or (msprite.z>hsprite.z+hsprite.height) or (hsprite.typ <> S_NETPLAYER) break;
        begin
    SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
       //  if (msprite.typ <> S_BULLET17)
       //    begin
      SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
      SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
      SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
      blood := true;
      killed := true;
       //     end;
     end;
         end;
       end;
     end;
       else
  for(hsprite := firstscaleobj.next;hsprite <> @lastscaleobj;hsprite := hsprite.next)
   if hsprite <> msprite then
   begin
     mapspot := (hsprite.y shr FRACTILESHIFT) * MAPCOLS + (hsprite.x shr FRACTILESHIFT);
     if mapspot = spriteloc then
     begin
       if (msprite.z<hsprite.z) or (msprite.z>hsprite.z+hsprite.height) continue;
       if hsprite.hitpoints then
       begin
         if hsprite.typ <> S_MONSTER5 then
    hsprite.actiontime := hsprite.actiontime + 15;
         else
    hsprite.actiontime := hsprite.actiontime + 5;
         hsprite.hitpoints := hsprite.hitpoints - msprite.damage;
         if (msprite.spawnid = 255) hsprite.enraged++;

         if (msprite.typ = S_SOULBULLET) and (msprite.spawnid = playernum) then
         begin
     heal(msprite.damage/2);
     medpaks(msprite.damage/2);
      end;

         killed := true;
         if hsprite.hitpoints <= 0 then
         begin
     if (msprite.spawnid = playernum) or (msprite.spawnid-200 = playernum) then
     begin
       ++player.bodycount;
       addscore(hsprite.score);
        end;
     mapsprites[spriteloc] := 0;
     blood := true;
     HitSprite(hsprite);
     KillSprite(hsprite, msprite.typ);
         end
         else if msprite.damage then
         begin
     oldangle := hsprite.angle;
     oldmovespeed := hsprite.moveSpeed;
     hsprite.angle := msprite.angle;
     hsprite.moveSpeed := (msprite.damage shr 2) shl FRACBITS;
     sp := msprite;
     msprite := hsprite;
     oldfall := msprite.nofalling;
     msprite.nofalling := 0;
     SP_Thrust2;
     msprite.nofalling := oldfall;
     msprite := sp;
     hsprite.angle := oldangle;
     hsprite.moveSpeed := oldmovespeed;
     blood := true;
     HitSprite(hsprite);
      end;
         break;
          end;
        end;
      end;
     end
     else if (playerhit) and (msprite.z > player.z-player.height) and (msprite.z<player.z) then
     begin
       if (player.angst <> 0) // don't keep hitting
       begin
   hurt(msprite.damage);
   if (player.angst = 0) and (netmode) NetDeath(msprite.spawnid);
    end;
       Thrust(msprite.angle, msprite.damage shl (FRACBITS-3));
       playerhit := false;
       killed := true;
       if msprite.damage>50 then
       begin
   player.angle+:= -15+(MS_RndT) and (31);
   player.angle) and (:= ANGLES;
    end;
        end;
     if result = 2 then
      killed := true;
     if killed then
     begin
       if not blood then
  ShowWallPuff;
       break;
        end;
      end;
    end;
  if (killed) and (msprite.typ = S_GRENADE) then
  begin
   angleinc := ANGLES/12;
   angle := 0;
   for(i := 0, angle := 0;i<12;i++, angle+:= angleinc)
   begin
     sp := SpawnSprite(S_GRENADEBULLET, msprite.x, msprite.y, msprite.z,20 shl FRACBITS, angle, 0, true, msprite.spawnid);
     sp.maxmove := 3;
     sp.startspot := -1;
      end;
   angleinc := ANGLES/8;
   angle := 0;
   for(i := 0, angle := 0;i<8;i++, angle+:= angleinc)
   begin
     sp := SpawnSprite(S_GRENADEBULLET, msprite.x, msprite.y, msprite.z,20 shl FRACBITS, angle,64, true, msprite.spawnid);
     sp.maxmove := 2;
     sp.startspot := -1;
      end;
   angleinc := ANGLES/8;
   angle := 0;
   for(i := 0, angle := 0;i<8;i++, angle+:= angleinc)
   begin
     sp := SpawnSprite(S_GRENADEBULLET, msprite.x, msprite.y, msprite.z,20 shl FRACBITS, angle,-64, true, msprite.spawnid);
     sp.maxmove := 2;
     sp.startspot := -1;
      end;
   sp := SpawnSprite(S_EXPLODE, msprite.x, msprite.y, msprite.z, 0, 0, 0, true, 255);
   SoundEffect(SN_EXPLODE1+(MS_RndT) and (1), 15, msprite.x, msprite.y);
  end
  else if (killed) and (msprite.typ = S_BULLET17) then
  begin
   angleinc := ANGLES/8;
   angle := 0;
   for(i := 0, angle := 0;i<8;i++, angle+:= angleinc)
   begin
     sp := SpawnSprite(S_GRENADEBULLET, msprite.x, msprite.y, msprite.z,20 shl FRACBITS, angle, 0, true, msprite.spawnid);
     sp.maxmove := 3;
     sp.startspot := -1;
      end;
   angleinc := ANGLES/6;
   angle := 0;
   for(i := 0, angle := 0;i<6;i++, angle+:= angleinc)
   begin
     sp := SpawnSprite(S_GRENADEBULLET, msprite.x, msprite.y, msprite.z,20 shl FRACBITS, angle,64, true, msprite.spawnid);
     sp.maxmove := 2;
     sp.startspot := -1;
      end;
   angleinc := ANGLES/6;
   angle := 0;
   for(i := 0, angle := 0;i<6;i++, angle+:= angleinc)
   begin
     sp := SpawnSprite(S_GRENADEBULLET, msprite.x, msprite.y, msprite.z,20 shl FRACBITS, angle,-64, true, msprite.spawnid);
     sp.maxmove := 2;
     sp.startspot := -1;
      end;
   sp := SpawnSprite(S_EXPLODE, msprite.x, msprite.y, msprite.z, 0, 0, 0, true, 255);
   SoundEffect(SN_EXPLODE1+(MS_RndT) and (1), 15, msprite.x, msprite.y);
    end;
  return killed;
  end;

(***************************************************************************)

int ScanX(int limit1, int x1, int y1, int x2, int y2,int *tx,int *ty)
(* check for the player along the x axis *)
begin
  mapspot, wall, x, limit, flags: integer;

  mapspot := y1* MAPCOLS +x1 + 1;
  x := x1;
  limit := limit1;
  while 1 do
  begin
   if (mapsprites[mapspot] = SM_NETPLAYER) or (mapsprites[mapspot] = SM_CLONE) or ((x = x2) and (y1 = y2)) then
   begin
     *tx := x+1;
     return 2;
      end;
   if (msprite.enraged >= 6-player.difficulty) and (mapsprites[mapspot] = 1) then
   begin
     *tx := x+1;
     *ty := y1;
     return 2;
      end;
   if (mapsprites[mapspot]>0) and (mapsprites[mapspot] < 128) break;
   wall := westwall[mapspot];
   flags := westflags[mapspot];
   if (wall) and ( not (flags) and (F_NOCLIP)) and ( not (flags) and (F_NOBULLETCLIP)) break;
   ++mapspot;
   ++x;
   --limit;
   if (not limit) break;
    end;
  limit := limit1;
  mapspot := y1* MAPCOLS +x1 - 1;
  x := x1;
  while 1 do
  begin
   if (mapsprites[mapspot] = SM_NETPLAYER) or (mapsprites[mapspot] = SM_CLONE) or ((x = x2) and (y1 = y2)) then
   begin
     *tx := x-1;
     return 2;
      end;
   if (msprite.enraged >= 6-player.difficulty) and (mapsprites[mapspot] = 1) then
   begin
     *tx := x-1;
     *ty := y1;
     return 2;
      end;
   if (mapsprites[mapspot]>0) and (mapsprites[mapspot] < 128) return 1;
   wall := westwall[mapspot + 1];
   flags := westflags[mapspot + 1];
   if (wall) and ( not (flags) and (F_NOCLIP)) and ( not (flags) and (F_NOBULLETCLIP)) return 0;
   --mapspot;
   --x;
   --limit;
   if (not limit) break;
    end;
  return 0;
  end;


int ScanY(int limit1, int x1, int y1, int x2, int y2,int *tx,int *ty)
(* check for the player along the y axis *)
begin
  mapspot, wall, y, limit, flags: integer;

  limit := limit1;
  mapspot := y1* MAPCOLS +x1+MAPCOLS;
  y := y1;
  while 1 do
  begin
   if (mapsprites[mapspot] = SM_NETPLAYER) or (mapsprites[mapspot] = SM_CLONE) or ((y = y2) and (x1 = x2)) then
   begin
     *ty := y+1;
     return 2;
      end;
   if (msprite.enraged >= 6-player.difficulty) and (mapsprites[mapspot] = 1) then
   begin
     *tx := x1;
     *ty := y+1;
     return 2;
      end;
   if (mapsprites[mapspot]>0) and (mapsprites[mapspot] < 128) break;
   wall := northwall[mapspot];
   flags := northflags[mapspot];
   if (wall) and ( not (flags) and (F_NOCLIP)) and ( not (flags) and (F_NOBULLETCLIP)) break;
   mapspot := mapspot + MAPCOLS;
   ++y;
   --limit;
   if (not limit) break;
    end;
  limit := limit1;
  mapspot := y1* MAPCOLS +x1-MAPCOLS;
  y := y1;
  while 1 do
  begin
   if (mapsprites[mapspot] = SM_NETPLAYER) or (mapsprites[mapspot] = SM_CLONE) or ((y = y2) and (x1 = x2)) then
   begin
     *ty := y-1;
     return 2;
      end;
   if (msprite.enraged >= 6-player.difficulty) and (mapsprites[mapspot] = 1) then
   begin
     *tx := x1;
     *ty := y-1;
     return 2;
      end;
   if (mapsprites[mapspot]>0) and (mapsprites[mapspot] < 128) break;
   wall := northwall[mapspot + MAPCOLS];
   flags := northflags[mapspot + MAPCOLS];
   if (wall) and ( not (flags) and (F_NOCLIP)) and ( not (flags) and (F_NOBULLETCLIP)) break;
   mapspot := mapspot - MAPCOLS;
   --y;
   --limit;
   if (not limit) break;
    end;
  return 0;
  end;


int ScanAngle(int limit1, int x1, int y1, int x2, int y2,int *tx,int *ty)
(* scan for the player along a 45 degree angle
   this is not very accurate not  not  approximate only *)
   begin
  mapspot, wall, x, y, limit, flags: integer;

  limit := limit1;
  mapspot := y1* MAPCOLS +x1+MAPCOLS+1;
  y := y1;
  x := x1;
  while 1 do
  begin
   wall := northwall[mapspot-1];
   flags := northflags[mapspot-1];
   if (wall) and ( not (flags) and (F_NOCLIP)) and ( not (flags) and (F_NOBULLETCLIP)) break;

   wall := westwall[mapspot-MAPCOLS];
   flags := westflags[mapspot-MAPCOLS];
   if (wall) and ( not (flags) and (F_NOCLIP)) and ( not (flags) and (F_NOBULLETCLIP)) return 0;

   if (mapsprites[mapspot] = SM_NETPLAYER) or (mapsprites[mapspot] = SM_CLONE) or ((y = y2) and (x = x2)) then
   begin
     *tx := x+1;
     *ty := y+1;
     return 2;
      end;
   if (msprite.enraged >= 6-player.difficulty) and (mapsprites[mapspot] = 1) then
   begin
     *tx := x+1;
     *ty := y+1;
     return 2;
      end;
   if (mapsprites[mapspot]>0) and (mapsprites[mapspot] < 128) break;

   mapspot+:= MAPCOLS+1;
   ++y;
   ++x;
   --limit;
   if (not limit) break;
    end;

  limit := limit1;
  mapspot := y1* MAPCOLS +x1+MAPCOLS-1;
  y := y1;
  x := x1;
  while 1 do
  begin
   wall := northwall[mapspot + 1];
   flags := northflags[mapspot + 1];
   if (wall) and ( not (flags) and (F_NOCLIP)) and ( not (flags) and (F_NOBULLETCLIP)) break;

   wall := westwall[mapspot-MAPCOLS];
   flags := westflags[mapspot-MAPCOLS];
   if (wall) and ( not (flags) and (F_NOCLIP)) and ( not (flags) and (F_NOBULLETCLIP)) return 0;

   if (mapsprites[mapspot] = SM_NETPLAYER) or (mapsprites[mapspot] = SM_CLONE) or ((y = y2) and (x = x2)) then
   begin
     *tx := x-1;
     *ty := y+1;
     return 2;
      end;
   if (msprite.enraged >= 6-player.difficulty) and (mapsprites[mapspot] = 1) then
   begin
     *tx := x-1;
     *ty := y+1;
     return 2;
      end;
   if (mapsprites[mapspot]>0) and (mapsprites[mapspot] < 128) break;

   mapspot+:= MAPCOLS-1;
   ++y;
   --x;
   --limit;
   if (not limit) break;
    end;

  limit := limit1;
  mapspot := y1* MAPCOLS +x1-MAPCOLS+1;
  y := y1;
  x := x1;
  while 1 do
  begin
   wall := northwall[mapspot-1+MAPCOLS];
   flags := northflags[mapspot-1+MAPCOLS];
   if (wall) and ( not (flags) and (F_NOCLIP)) and ( not (flags) and (F_NOBULLETCLIP)) break;

   wall := westwall[mapspot-MAPCOLS];
   flags := westflags[mapspot-MAPCOLS];
   if (wall) and ( not (flags) and (F_NOCLIP)) and ( not (flags) and (F_NOBULLETCLIP)) return 0;

   if (mapsprites[mapspot] = SM_NETPLAYER) or (mapsprites[mapspot] = SM_CLONE) or ((y = y2) and (x = x2)) then
   begin
     *tx := x+1;
     *ty := y-1;
     return 2;
      end;
   if (msprite.enraged >= 6-player.difficulty) and (mapsprites[mapspot] = 1) then
   begin
     *tx := x+1;
     *ty := y-1;
     return 2;
      end;
   if (mapsprites[mapspot]>0) and (mapsprites[mapspot] < 128) break;

   mapspot-:= MAPCOLS+1;
   --y;
   ++x;
   --limit;
   if (not limit) break;
    end;

  limit := limit1;
  mapspot := y1* MAPCOLS +x1-MAPCOLS-1;
  y := y1;
  x := x1;
  while 1 do
  begin
   wall := northwall[mapspot + 1+MAPCOLS];
   flags := northflags[mapspot + 1+MAPCOLS];
   if (wall) and ( not (flags) and (F_NOCLIP)) and ( not (flags) and (F_NOBULLETCLIP)) break;

   wall := westwall[mapspot-MAPCOLS];
   flags := westflags[mapspot-MAPCOLS];
   if (wall) and ( not (flags) and (F_NOCLIP)) and ( not (flags) and (F_NOBULLETCLIP)) return 0;

   if (mapsprites[mapspot] = SM_NETPLAYER) or (mapsprites[mapspot] = SM_CLONE) or ((y = y2) and (x = x2)) then
   begin
     *tx := x-1;
     *ty := y-1;
     return 2;
      end;
   if (msprite.enraged >= 6-player.difficulty) and (mapsprites[mapspot] = 1) then
   begin
     *tx := x-1;
     *ty := y-1;
     return 2;
      end;
   if (mapsprites[mapspot]>0) and (mapsprites[mapspot] < 128) break;

   mapspot-:= MAPCOLS-1;
   --y;
   --x;
   --limit;
   if (not limit) break;
    end;

  return 0;
  end;

(***************************************************************************)

int GetFireAngle(fixed_t sz,int x1,int y1,fixed_t px,fixed_t py,fixed_t pz)
begin
  scaleobj_t *hsprite;
  x, y, z, d, spriteloc, mapspot: integer;
  found: boolean;

  sz := sz + msprite.z;
  if (x1 <> px shr FRACTILESHIFT) or (y1 <> py shr FRACTILESHIFT) then
  begin
   spriteloc := y1* MAPCOLS +x1;
   found := false;
   for(hsprite := firstscaleobj.next;hsprite <> @lastscaleobj;hsprite := hsprite.next)
    if hsprite.hitpoints then
    begin
      mapspot := (hsprite.y shr FRACTILESHIFT) * MAPCOLS + (hsprite.x shr FRACTILESHIFT);
      if mapspot = spriteloc then
      begin
  found := true;
  break;
   end;
       end;
   if found then
   begin
     px := hsprite.x;
     py := hsprite.y;
     pz := hsprite.z + (32 shl FRACBITS);
      end;
    end;
  else pz+:= 20 shl FRACBITS;
  if sz > pz then
  begin
   z := (sz-pz) shr (FRACBITS + 2);
   if (z >= MAXAUTO) return 0;
   x := (msprite.x - px) shr (FRACBITS + 2);
   y := (msprite.y - py) shr (FRACBITS + 2);
   d := (int)sqrt(x*x + y*y);
   if (d >= MAXAUTO) or (autoangle2[d][z] = -1) return 0;
   return -autoangle2[d][z];
  end
  else if sz<pz then
  begin
   z := (pz-sz) shr (FRACBITS + 2);
   if (z >= MAXAUTO) return 0;
   x := (msprite.x - px) shr (FRACBITS + 2);
   y := (msprite.y - py) shr (FRACBITS + 2);
   d := (int)sqrt(x*x + y*y);
   if (d >= MAXAUTO) or (autoangle2[d][z] = -1) return 0;
   return autoangle2[d][z];
    end;
  else return 0;
  end;

(***************************************************************************)

void Int5;  // priests / viscount lords
begin
  angle, sx, sy, px, py, tx, ty, pangle: integer;
  floorz, oldspeed, fheight: fixed_t;

  sx := msprite.x shr FRACTILESHIFT;
  sy := msprite.y shr FRACTILESHIFT;
  if (netmode) NetGetClosestPlayer(sx, sy);
  else
  begin
   if specialeffect = SE_INVISIBILITY then
   begin
     targx := 0;
     targy := 0;
     targz := 0;
      end;
   else
   begin
     targx := player.x;
     targy := player.y;
     targz := player.z;
      end;
    end;
  px := targx shr FRACTILESHIFT;
  py := targy shr FRACTILESHIFT;

  oldspeed := msprite.moveSpeed;
  if (absI(px - sx) < 6) and (absI(py - sy) < 6) msprite.moveSpeed := msprite.moveSpeed*2;

  if timecount>msprite.movetime then
  begin
   if (px>sx) angle := EAST;
    else if (px<sx) angle := WEST;
    else angle := -1;
   if py<sy then
   begin
     if (angle = EAST) angle+:= DEGREE45;
      else if (angle = WEST) angle-:= DEGREE45;
      else angle := NORTH;
   end
   else if py>sy then
   begin
     if (angle = EAST) angle-:= DEGREE45;
      else if (angle = WEST) angle+:= DEGREE45;
      else angle := SOUTH;
      end;
   angle := angle - DEGREE45 + MS_RndT;
   msprite.angle := angle) and (ANGLES;
   msprite.movetime := timecount + 140; // 350
    end;

  if (timecount>msprite.firetime) and (timecount>msprite.scantime) then
  begin
   tx := px;
   ty := py;
   if (ScanX(10, sx, sy,px,py,) and (tx,) and (ty) > 1) or (ScanY(10, sx, sy,px,py,) and (tx,) and (ty) > 1
   ) or (ScanAngle(10, sx, sy,px,py,) and (tx,) and (ty) > 1)
   begin
     if (tx>sx) angle := EAST;
      else if (tx<sx) angle := WEST;
      else angle := -1;
     if ty<sy then
     begin
       if (angle = EAST) angle+:= DEGREE45;
  else if (angle = WEST) angle-:= DEGREE45;
  else angle := NORTH;
     end
     else if ty>sy then
     begin
       if (angle = EAST) angle-:= DEGREE45;
  else if (angle = WEST) angle+:= DEGREE45;
  else angle := SOUTH;
        end;
     msprite.angle := angle) and (ANGLES;
     msprite.basepic := msprite.startpic+24;
     msprite.movemode := 4;
     msprite.firetime := timecount+(40+5*player.difficulty);
     msprite.actiontime := timecount + 30;
     msprite.modetime := timecount + 15;
      end;
   msprite.scantime := timecount + 30;
    end;

  if timecount>msprite.modetime then
  begin
   msprite.modetime := timecount + 10;
   case msprite.movemode  of
   begin
     0: // left
     1: // mid
      if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
      begin
  ++msprite.movemode;
  msprite.basepic := msprite.startpic+msprite.movemode*8;
  msprite.lasty := msprite.y;
  msprite.lastx := msprite.x;
   end;
      break;
     2: // right
      if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
      begin
  msprite.basepic := msprite.startpic + 8; // midstep
  ++msprite.movemode;
  msprite.lasty := msprite.y;
  msprite.lastx := msprite.x;
   end;
      break;
     3: // mid #2
      if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
      begin
  msprite.movemode := 0;
  msprite.basepic := msprite.startpic;
  msprite.lasty := msprite.y;
  msprite.lastx := msprite.x;
   end;
      break;
     4: // fire #1
      tx := px;
      ty := py;
      if (ScanX(10, sx, sy,px,py,) and (tx,) and (ty) > 1) or (ScanY(10, sx, sy,px,py,) and (tx,) and (ty) > 1
      ) or (ScanAngle(10, sx, sy,px,py,) and (tx,) and (ty) > 1)
      begin
  if (tx>sx) angle := EAST;
   else if (tx<sx) angle := WEST;
   else angle := -1;
  if ty<sy then
  begin
    if (angle = EAST) angle+:= DEGREE45;
     else if (angle = WEST) angle-:= DEGREE45;
     else angle := NORTH;
  end
  else if ty>sy then
  begin
    if (angle = EAST) angle-:= DEGREE45;
     else if (angle = WEST) angle+:= DEGREE45;
     else angle := SOUTH;
     end;
  msprite.angle := angle) and (ANGLES;
  msprite.movemode := 5;
  msprite.basepic := msprite.startpic + 32;
  if (msprite.typ = S_MONSTER7) fheight := 15 shl FRACBITS;
   else fheight := 40 shl FRACBITS;
  pangle := GetFireAngle(fheight, tx, ty, targx, targy, targz)-15+(MS_RndT) and (31);
  SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z,fheight, msprite.angle-15+(MS_RndT) and (31), pangle, true, 255);
  msprite.modetime := msprite.modetime + 8;
   end;
      else
      begin
  msprite.movemode := 0;
  msprite.basepic := msprite.startpic;
   end;
      break;
     5: // fire #2
      msprite.movemode := 0;
      msprite.basepic := msprite.startpic;
      break;
      end;
    end;

  if (timecount>msprite.actiontime) and (SP_Thrust2 <> 1) then
  begin
   angle := msprite.angle + DEGREE45;
   msprite.angle := angle) and (ANGLES;
    end;
  floorz := RF_GetFloorZ(msprite.x, msprite.y);
  if floorz + msprite.zadj<msprite.z then
  msprite.z-:= FRACUNIT shl 4;
  if floorz + msprite.zadj > msprite.z then
  msprite.z := floorz + msprite.zadj;
  msprite.moveSpeed := oldspeed;
  if MS_RndT >= 255 then
  ActivationSound(msprite);
  end;

(***************************************************************************)

bool Int6 // intelligence for mines
begin
  scaleobj_t *sp;
  i, j, angle, angleinc, x, y, sx, sy: integer;
  activate: boolean;

  if (timecount>msprite.actiontime) // now active
  begin
   if msprite.typ = S_TIMEMINE then
   begin
     angleinc := ANGLES/20;
     angle := 0;
     for(i := 0, angle := 0;i<20;i++, angle+:= angleinc)
      sp := SpawnSprite(S_MINEBULLET, msprite.x, msprite.y, msprite.z,20 shl FRACBITS, angle, 0, true, msprite.spawnid);
     sp := SpawnSprite(S_EXPLODE, msprite.x, msprite.y, msprite.z, 0, 0, 0, true, 255);
     SoundEffect(SN_EXPLODE1+(MS_RndT) and (1), 15, msprite.x, msprite.y);
     return true;
   end
   else if msprite.typ = S_PROXMINE then
   begin
     if (MS_RndT) and (1) msprite.angle+:= 8;
      else msprite.angle := msprite.angle - 8;
     msprite.angle) and (:= ANGLES;

     x := msprite.x shr FRACTILESHIFT;
     y := msprite.y shr FRACTILESHIFT;
     activate := false;
     if (absI(x-(player.x shr FRACTILESHIFT))<2) and (absI(y-(player.y shr FRACTILESHIFT))<2) activate := true;
     if not activate then
      for (sp := firstscaleobj.next;sp <> @lastscaleobj;sp := sp.next)
       if sp.hitpoints then
       begin
   sx := sp.x shr FRACTILESHIFT;
   sy := sp.y shr FRACTILESHIFT;
   if (absI(x - sx)<2) and (absI(y - sy)<2) then
   begin
     activate := true;
     break;
      end;
    end;
     for(i := -1;i<2;i++)
      for(j := -1;j<2;j++)
       if (mapsprites[(i+y) * MAPCOLS+j+x] = SM_NETPLAYER) activate := true;
     if activate then
     begin
       angleinc := ANGLES/16;
       angle := 0;
       for(i := 0, angle := 0;i<16;i++, angle+:= angleinc)
  sp := SpawnSprite(S_MINEBULLET, msprite.x, msprite.y, msprite.z,20 shl FRACBITS, angle, 0, true, msprite.spawnid);
       sp := SpawnSprite(S_EXPLODE, msprite.x, msprite.y, msprite.z, 0, 0, 0, true, 255);
       SoundEffect(SN_EXPLODE1+(MS_RndT) and (1), 15, msprite.x, msprite.y);
       return true;
        end;
   end
   else if msprite.typ = S_INSTAWALL then
   begin
     mapsprites[(msprite.y shr FRACTILESHIFT) * MAPCOLS + (msprite.x shr FRACTILESHIFT)] := 0;
     return true;
      end;
    end;
  return false;
  end;

(***************************************************************************)

int CloneScanX(int x,int y,int *x2)
(* check for the target along the x axis *)
begin
  mapspot, wall, x1, limit, flags: integer;

  mapspot := y* MAPCOLS +x+1;
  x1 := x;
  limit := 10;
  while 1 do
  begin
   if (mapsprites[mapspot] = SM_CLONE) or (mapsprites[mapspot] = 1) then
   begin
     *x2 := x1 + 1;
     return 1+(MS_RndT) and (1);
      end;
   if (mapsprites[mapspot]>0) and (mapsprites[mapspot] < 128) break;
   wall := westwall[mapspot];
   flags := westflags[mapspot];
   if (wall) and ( not (flags) and (F_NOCLIP)) and ( not (flags) and (F_NOBULLETCLIP)) break;
   ++mapspot;
   ++x1;
   --limit;
   if (not limit) break;
    end;
  limit := 10;
  mapspot := y* MAPCOLS +x-1;
  x1 := x;
  while 1 do
  begin
   if (mapsprites[mapspot] = SM_CLONE) or (mapsprites[mapspot] = 1) then
   begin
     *x2 := x1 - 1;
     return 1+(MS_RndT) and (1);
      end;
   if (mapsprites[mapspot]>0) and (mapsprites[mapspot] < 128) return 1;
   wall := westwall[mapspot + 1];
   flags := westflags[mapspot + 1];
   if (wall) and ( not (flags) and (F_NOCLIP)) and ( not (flags) and (F_NOBULLETCLIP)) return 0;
   --mapspot;
   --x1;
   --limit;
   if (not limit) break;
    end;
  return 0;
  end;


int CloneScanY(int x,int y,int *y2)
(* check for the player along the y axis *)
begin
  mapspot, wall, y1, limit, flags: integer;

  limit := 10;
  mapspot := y* MAPCOLS + x + MAPCOLS;
  y1 := y;
  while 1 do
  begin
   if (mapsprites[mapspot] = SM_CLONE) or (mapsprites[mapspot] = 1) then
   begin
     *y2 := y1 + 1;
     return 1+(MS_RndT) and (1);
      end;
   if (mapsprites[mapspot]>0) and (mapsprites[mapspot] < 128) break;
   wall := northwall[mapspot];
   flags := northflags[mapspot];
   if (wall) and ( not (flags) and (F_NOCLIP)) and ( not (flags) and (F_NOBULLETCLIP)) break;
   mapspot := mapspot + MAPCOLS;
   ++y1;
   --limit;
   if (not limit) break;
    end;
  limit := 10;
  mapspot := y * MAPCOLS + x - MAPCOLS;
  y1 := y;
  while 1 do
  begin
   if (mapsprites[mapspot] = SM_CLONE) or (mapsprites[mapspot] = 1) then
   begin
     *y2 := y1 - 1;
     return 1+(MS_RndT) and (1);
      end;
   if (mapsprites[mapspot]>0) and (mapsprites[mapspot] < 128) break;
   wall := northwall[mapspot + MAPCOLS];
   flags := northflags[mapspot + MAPCOLS];
   if (wall) and ( not (flags) and (F_NOCLIP)) and ( not (flags) and (F_NOBULLETCLIP)) break;
   mapspot := mapspot - MAPCOLS;
   --y1;
   --limit;
   if (not limit) break;
    end;
  return 0;
  end;


void Int7;  // clone ai
begin
  angle, sx, sy, px, py, pangle, r: integer;
  floorz, fheight: fixed_t;

  sx := msprite.x shr FRACTILESHIFT;
  sy := msprite.y shr FRACTILESHIFT;

  if timecount>msprite.movetime then
  begin
   angle := msprite.angle - DEGREE45;
   r := MS_RndT mod 3;

   if r = 1 then
    angle := angle + DEGREE45;
   else if (r = 2)
    angle := angle + NORTH;

   msprite.angle := angle) and (ANGLES;
   msprite.movetime := timecount+250;
    end;

  if (timecount>msprite.firetime) and (timecount>msprite.scantime) then
  begin
   px := sx;
   py := sy;
   if (CloneScanX(sx, sy,) and (px) > 1) then
   begin
     if (px>sx) angle := EAST;
      else if (px<sx) angle := WEST;
     msprite.angle := angle) and (ANGLES;
     msprite.movemode := 4;
     msprite.basepic := msprite.startpic+24;
     fheight := 40 shl FRACBITS;
     pangle := GetFireAngle(fheight,px,py, 0, 0, 0);
     SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z,fheight, msprite.angle, pangle, true, 255);
     msprite.modetime := timecount + 8;
     msprite.actiontime := timecount + 30;
     msprite.firetime := timecount + 30;
   end
   else if (CloneScanY(sx, sy,) and (py) > 1) then
   begin
     if (py>sy) angle := SOUTH;
      else if (py<sy) angle := NORTH;
     msprite.angle := angle) and (ANGLES;
     msprite.movemode := 4;
     msprite.basepic := msprite.startpic+24;
     fheight := 40 shl FRACBITS;
     pangle := GetFireAngle(fheight,px,py, 0, 0, 0);
     SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z,fheight, msprite.angle, pangle, true, 255);
     msprite.modetime := timecount + 8;
     msprite.actiontime := timecount + 30;
     msprite.firetime := timecount + 30;
      end;
   msprite.scantime := timecount+20;
    end;

  if timecount>msprite.modetime then
  begin
   msprite.modetime := timecount + 10;
   case msprite.movemode  of
   begin
     0: // left
     1: // mid
      if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
      begin
  ++msprite.movemode;
  msprite.basepic := msprite.startpic+msprite.movemode*8;
  msprite.lasty := msprite.y;
  msprite.lastx := msprite.x;
   end;
      break;
     2: // right
      if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
      begin
  msprite.basepic := msprite.startpic + 8;
  ++msprite.movemode;
  msprite.lasty := msprite.y;
  msprite.lastx := msprite.x;
   end;
      break;
     3: // mid #2
      if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
      begin
  msprite.movemode := 0;
  msprite.basepic := msprite.startpic;
  msprite.lasty := msprite.y;
  msprite.lastx := msprite.x;
   end;
      break;
     4: // fire
      msprite.movemode := 0;
      msprite.basepic := msprite.startpic;
      break;
      end;
    end;
  if (timecount>msprite.actiontime) and (SP_Thrust2 <> 1) then
  begin
   angle := msprite.angle + DEGREE45;
   msprite.angle := angle) and (ANGLES;
    end;
  floorz := RF_GetFloorZ(msprite.x, msprite.y);
  if (floorz + msprite.zadj<msprite.z) msprite.z-:= FRACUNIT shl 4;
  if (floorz + msprite.zadj > msprite.z) msprite.z := floorz + msprite.zadj;
  end;

(***************************************************************************)

void Int8;  // prisoners
begin
  angle, sx, sy, px, py, tx, ty, pangle: integer;
  floorz, oldspeed, fheight: fixed_t;

  sx := msprite.x shr FRACTILESHIFT;
  sy := msprite.y shr FRACTILESHIFT;
  if (netmode) NetGetClosestPlayer(sx, sy);
  else
  begin
   if specialeffect = SE_INVISIBILITY then
   begin
     targx := 0;
     targy := 0;
     targz := 0;
      end;
   else
   begin
     targx := player.x;
     targy := player.y;
     targz := player.z;
      end;
    end;
  px := targx shr FRACTILESHIFT;
  py := targy shr FRACTILESHIFT;

  oldspeed := msprite.moveSpeed;
  if (absI(px - sx) < 6) and (absI(py - sy) < 6) msprite.moveSpeed := msprite.moveSpeed*2;

  if timecount>msprite.movetime then
  begin
   if (px>sx) angle := EAST;
    else if (px<sx) angle := WEST;
    else angle := -1;
   if py<sy then
   begin
     if (angle = EAST) angle+:= DEGREE45;
      else if (angle = WEST) angle-:= DEGREE45;
      else angle := NORTH;
   end
   else if py>sy then
   begin
     if (angle = EAST) angle-:= DEGREE45;
      else if (angle = WEST) angle+:= DEGREE45;
      else angle := SOUTH;
      end;
   angle := angle - DEGREE45 + MS_RndT;
   msprite.angle := angle) and (ANGLES;
   msprite.movetime := timecount + 350;
    end;

  if (timecount>msprite.firetime) and (timecount>msprite.scantime) then
  begin
   tx := px;
   ty := py;
   if (ScanX(7, sx, sy,px,py,) and (tx,) and (ty) > 1) or (ScanY(7, sx, sy,px,py,) and (tx,) and (ty) > 1
   ) or (ScanAngle(7, sx, sy,px,py,) and (tx,) and (ty) > 1)
   begin
     if (tx>sx) angle := EAST;
      else if (tx<sx) angle := WEST;
      else angle := -1;
     if ty<sy then
     begin
       if (angle = EAST) angle+:= DEGREE45;
  else if (angle = WEST) angle-:= DEGREE45;
  else angle := NORTH;
     end
     else if ty>sy then
     begin
       if (angle = EAST) angle-:= DEGREE45;
  else if (angle = WEST) angle+:= DEGREE45;
  else angle := SOUTH;
        end;
     msprite.angle := angle) and (ANGLES;

     if (absI(tx - sx) > 2) or (absI(ty - sy) > 2) then
     begin
       msprite.scantime := timecount+45;
       goto endscan;
        end;

     msprite.basepic := msprite.startpic+24;
     msprite.movemode := 4;
     msprite.firetime := timecount+(80+5*player.difficulty);
     msprite.actiontime := timecount + 30;
     msprite.modetime := timecount + 15;
      end;
   msprite.scantime := timecount+45;
    end;

endscan:
  if timecount>msprite.modetime then
  begin
   msprite.modetime := timecount + 10;
   case msprite.movemode  of
   begin
     0: // left
     1: // mid
      if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
      begin
  ++msprite.movemode;
  msprite.basepic := msprite.startpic+msprite.movemode*8;
  msprite.lasty := msprite.y;
  msprite.lastx := msprite.x;
   end;
      break;
     2: // right
      if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
      begin
  msprite.basepic := msprite.startpic + 8; // midstep
  ++msprite.movemode;
  msprite.lasty := msprite.y;
  msprite.lastx := msprite.x;
   end;
      break;
     3: // mid #2
      if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
      begin
  msprite.movemode := 0;
  msprite.basepic := msprite.startpic;
  msprite.lasty := msprite.y;
  msprite.lastx := msprite.x;
   end;
      break;
     4: // fire #1
      tx := px;
      ty := py;
      if (ScanX(7, sx, sy,px,py,) and (tx,) and (ty) > 1) or (ScanY(7, sx, sy,px,py,) and (tx,) and (ty) > 1
      ) or (ScanAngle(7, sx, sy,px,py,) and (tx,) and (ty) > 1)
      begin
  if (tx>sx) angle := EAST;
   else if (tx<sx) angle := WEST;
   else angle := -1;
  if ty<sy then
  begin
    if (angle = EAST) angle+:= DEGREE45;
     else if (angle = WEST) angle-:= DEGREE45;
     else angle := NORTH;
  end
  else if ty>sy then
  begin
    if (angle = EAST) angle-:= DEGREE45;
     else if (angle = WEST) angle+:= DEGREE45;
     else angle := SOUTH;
     end;

  msprite.angle := angle) and (ANGLES;

  if (absI(tx - sx) > 2) or (absI(ty - sy) > 2) then
  begin
    msprite.movemode := 0;
    msprite.basepic := msprite.startpic;
    break;
     end;

  msprite.movemode := 5;
  msprite.basepic := msprite.startpic + 32;
  fheight := 40 shl FRACBITS;
  pangle := GetFireAngle(fheight, tx, ty, targx, targy, targz);
  SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z,fheight, msprite.angle, pangle, true, 255);
  msprite.modetime := msprite.modetime + 8;
   end;
      else
      begin
  msprite.movemode := 0;
  msprite.basepic := msprite.startpic;
   end;
      break;
     5: // fire #2
      msprite.movemode := 0;
      msprite.basepic := msprite.startpic;
      break;
      end;
    end;

  if (timecount>msprite.actiontime) and (SP_Thrust2 <> 1) then
  begin
   angle := msprite.angle + DEGREE45;
   msprite.angle := angle) and (ANGLES;
    end;
  floorz := RF_GetFloorZ(msprite.x, msprite.y);
  if floorz + msprite.zadj<msprite.z then
  msprite.z-:= FRACUNIT shl 4;
  if floorz + msprite.zadj > msprite.z then
  msprite.z := floorz + msprite.zadj;
  msprite.moveSpeed := oldspeed;
  if MS_RndT >= 255 then
  ActivationSound(msprite);
  end;

(***************************************************************************)

void Int9;  // big guards only
begin
  i, angleinc, angle, sx, sy, px, py, tx, ty, pangle: integer;
  floorz, oldspeed, fheight: fixed_t;

  if msprite.hitpoints<1000 then
  msprite.hitpoints := msprite.hitpoints + 10;
  msprite.enraged := 0;
  sx := msprite.x shr FRACTILESHIFT;
  sy := msprite.y shr FRACTILESHIFT;
  if (netmode) NetGetClosestPlayer(sx, sy);
  else
  begin
   if specialeffect = SE_INVISIBILITY then
   begin
     targx := 0;
     targy := 0;
     targz := 0;
      end;
   else
   begin
     targx := player.x;
     targy := player.y;
     targz := player.z;
      end;
    end;
  px := targx shr FRACTILESHIFT;
  py := targy shr FRACTILESHIFT;

  oldspeed := msprite.moveSpeed;
  if (absI(px - sx) < 6) and (absI(py - sy) < 6) msprite.moveSpeed := msprite.moveSpeed*2;

  if timecount>msprite.movetime then
  begin
   if (px>sx) angle := EAST;
    else if (px<sx) angle := WEST;
    else angle := -1;
   if py<sy then
   begin
     if (angle = EAST) angle+:= DEGREE45;
      else if (angle = WEST) angle-:= DEGREE45;
      else angle := NORTH;
   end
   else if py>sy then
   begin
     if (angle = EAST) angle-:= DEGREE45;
      else if (angle = WEST) angle+:= DEGREE45;
      else angle := SOUTH;
      end;
   angle := angle - DEGREE45 + MS_RndT;
   msprite.angle := angle) and (ANGLES;
   msprite.movetime := timecount+200;
    end;

  if (timecount>msprite.firetime) and (timecount>msprite.scantime) then
  begin
   SoundEffect(SN_MON11_WAKE, 7, msprite.x, msprite.y);
   tx := px;
   ty := py;
   if (ScanX(8, sx, sy,px,py,) and (tx,) and (ty) > 1) or (ScanY(8, sx, sy,px,py,) and (tx,) and (ty) > 1
   ) or (ScanAngle(8, sx, sy,px,py,) and (tx,) and (ty) > 1)
   begin
     if (tx>sx) angle := EAST;
      else if (tx<sx) angle := WEST;
      else angle := -1;
     if ty<sy then
     begin
       if (angle = EAST) angle+:= DEGREE45;
  else if (angle = WEST) angle-:= DEGREE45;
  else angle := NORTH;
     end
     else if ty>sy then
     begin
       if (angle = EAST) angle-:= DEGREE45;
  else if (angle = WEST) angle+:= DEGREE45;
  else angle := SOUTH;
        end;
     msprite.angle := angle) and (ANGLES;
     msprite.basepic := msprite.startpic+24;
     msprite.movemode := 4;
     msprite.firetime := timecount+(120+5*player.difficulty);
     msprite.actiontime := timecount + 30;
     msprite.modetime := timecount+20;
      end;
   msprite.scantime := timecount+45;
    end;

  if timecount>msprite.modetime then
  begin
   msprite.modetime := timecount+20;
   case msprite.movemode  of
   begin
     0: // left
     1: // mid
      if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
      begin
  ++msprite.movemode;
  msprite.basepic := msprite.startpic+msprite.movemode*8;
  msprite.lasty := msprite.y;
  msprite.lastx := msprite.x;
   end;
      if MS_RndT<32 then
      begin
  angle := 0;
  angleinc := ANGLES/16;
  for (i := 0;i<16;i++, angle+:= angleinc)
   SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, 32 shl FRACBITS, angle, 0, true, 255);
  SoundEffect(SN_MON11_FIRE, 7, msprite.x, msprite.y);
   end;
      break;
     2: // right
      if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
      begin
  msprite.basepic := msprite.startpic + 8; // midstep
  ++msprite.movemode;
  msprite.lasty := msprite.y;
  msprite.lastx := msprite.x;
   end;
      if MS_RndT<32 then
      begin
  angle := 0;
  angleinc := ANGLES/16;
  for (i := 0;i<16;i++, angle+:= angleinc)
   SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, 32 shl FRACBITS, angle, 0, true, 255);
  SoundEffect(SN_MON11_FIRE, 7, msprite.x, msprite.y);
   end;
      break;
     3: // mid #2
      if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
      begin
  msprite.movemode := 0;
  msprite.basepic := msprite.startpic;
  msprite.lasty := msprite.y;
  msprite.lastx := msprite.x;
   end;
      if MS_RndT<32 then
      begin
  angle := 0;
  angleinc := ANGLES/16;
  for (i := 0;i<16;i++, angle+:= angleinc)
   SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, 32 shl FRACBITS, angle, 0, true, 255);
  SoundEffect(SN_MON11_FIRE, 7, msprite.x, msprite.y);
   end;
      break;
     4: // firing bullets
     5:
     6:
     7:
      tx := px;
      ty := py;
      if (ScanX(8, sx, sy,px,py,) and (tx,) and (ty) > 1) or (ScanY(8, sx, sy,px,py,) and (tx,) and (ty) > 1
      ) or (ScanAngle(8, sx, sy,px,py,) and (tx,) and (ty) > 1)
      begin
  if (tx>sx) angle := EAST;
   else if (tx<sx) angle := WEST;
   else angle := -1;
  if ty<sy then
  begin
    if (angle = EAST) angle+:= DEGREE45;
     else if (angle = WEST) angle-:= DEGREE45;
     else angle := NORTH;
  end
  else if ty>sy then
  begin
    if (angle = EAST) angle-:= DEGREE45;
     else if (angle = WEST) angle+:= DEGREE45;
     else angle := SOUTH;
     end;
  msprite.angle := angle) and (ANGLES;
  ++msprite.movemode;
  msprite.basepic := msprite.startpic + 32;
  fheight := 70 shl FRACBITS;
  if (msprite.movemode = 5) and (MS_RndT<32) then
  begin
    SpawnSprite(S_GRENADE, msprite.x, msprite.y, msprite.z,fheight, msprite.angle-15+(MS_RndT) and (31), 0, true, 255);
    SpawnSprite(S_GRENADE, msprite.x, msprite.y, msprite.z,fheight, msprite.angle+15+(MS_RndT) and (31), 0, true, 255);
    SoundEffect(SN_GRENADE, 0, msprite.x, msprite.y);
    msprite.movemode := 0;
    msprite.basepic := msprite.startpic;
    msprite.firetime := timecount+(120+5*player.difficulty);
    msprite.actiontime := timecount + 30;
     end;
  else
  begin
    pangle := GetFireAngle(fheight, tx, ty, targx, targy, targz)-15+(MS_RndT) and (31);
    SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z,fheight, msprite.angle-15+(MS_RndT) and (31), pangle, true, 255);
    SoundEffect(SN_MON11_FIRE, 7, msprite.x, msprite.y);
    msprite.modetime := timecount + 15;
     end;
   end;
      else
      begin
  msprite.movemode := 0;
  msprite.basepic := msprite.startpic;
  msprite.firetime := timecount+(120+5*player.difficulty);
  msprite.actiontime := timecount + 30;
   end;
      break;
     8: // fire #2
      msprite.movemode := 0;
      msprite.basepic := msprite.startpic;
      msprite.firetime := timecount+(120+5*player.difficulty);
      msprite.actiontime := timecount + 30;
      break;
      end;
    end;

  if (timecount>msprite.actiontime) and (SP_Thrust2 <> 1) then
  begin
   angle := msprite.angle + DEGREE45;
   msprite.angle := angle) and (ANGLES;
    end;
  floorz := RF_GetFloorZ(msprite.x, msprite.y);
  if floorz + msprite.zadj<msprite.z then
  msprite.z-:= FRACUNIT shl 4;
  if floorz + msprite.zadj > msprite.z then
  msprite.z := floorz + msprite.zadj;
  msprite.moveSpeed := oldspeed;
  if MS_RndT >= 255 then
  ActivationSound(msprite);
  end;

(***************************************************************************)

procedure Int10;
begin
  angle, sx, sy, px, py, tx, ty, pangle: integer;
  floorz, oldspeed, fheight: fixed_t;

  if (msprite.typ = S_MONSTER5) and (msprite.hitpoints<5000) then
  msprite.hitpoints := msprite.hitpoints + 4;
  else if (msprite.typ = S_MONSTER13) and (msprite.hitpoints<300) then
  begin
   msprite.hitpoints := msprite.hitpoints + 25;
   msprite.enraged := 0;
  end
  else if (msprite.typ = S_MONSTER15) and (msprite.hitpoints<2000) then
  begin
   msprite.hitpoints := msprite.hitpoints + 6;
   msprite.enraged := 0;
  end
  else if (msprite.typ = S_MONSTER14) and (msprite.hitpoints<350)
  msprite.hitpoints := msprite.hitpoints + 1;
  sx := msprite.x shr FRACTILESHIFT;
  sy := msprite.y shr FRACTILESHIFT;
  if (netmode) NetGetClosestPlayer(sx, sy);
  else
  begin
   if specialeffect = SE_INVISIBILITY then
   begin
     targx := 0;
     targy := 0;
     targz := 0;
      end;
   else
   begin
     targx := player.x;
     targy := player.y;
     targz := player.z;
      end;
    end;
  px := targx shr FRACTILESHIFT;
  py := targy shr FRACTILESHIFT;

  oldspeed := msprite.moveSpeed;
  if (absI(px - sx) < 6) and (absI(py - sy) < 6) msprite.moveSpeed := msprite.moveSpeed*2;

  if timecount>msprite.movetime then
  begin
   if (px>sx) angle := EAST;
    else if (px<sx) angle := WEST;
    else angle := -1;
   if py<sy then
   begin
     if (angle = EAST) angle+:= DEGREE45;
      else if (angle = WEST) angle-:= DEGREE45;
      else angle := NORTH;
   end
   else if py>sy then
   begin
     if (angle = EAST) angle-:= DEGREE45;
      else if (angle = WEST) angle+:= DEGREE45;
      else angle := SOUTH;
      end;
   angle := angle - DEGREE45 + MS_RndT;
   msprite.angle := angle) and (ANGLES;
   msprite.movetime := timecount + 350;
    end;

  if (timecount>msprite.firetime) and (timecount>msprite.scantime) then
  begin
   tx := px;
   ty := py;
   if (ScanX(10, sx, sy,px,py,) and (tx,) and (ty) > 1) or (ScanY(10, sx, sy,px,py,) and (tx,) and (ty) > 1
   ) or (ScanAngle(10, sx, sy,px,py,) and (tx,) and (ty) > 1)
   begin
     if (tx>sx) angle := EAST;
      else if (tx<sx) angle := WEST;
      else angle := -1;
     if ty<sy then
     begin
       if (angle = EAST) angle+:= DEGREE45;
  else if (angle = WEST) angle-:= DEGREE45;
  else angle := NORTH;
     end
     else if ty>sy then
     begin
       if (angle = EAST) angle-:= DEGREE45;
  else if (angle = WEST) angle+:= DEGREE45;
  else angle := SOUTH;
        end;
     msprite.angle := angle) and (ANGLES;

     if (msprite.typ = S_MONSTER7) and ((absI(tx - sx) > 2) or (absI(ty - sy) > 2)) then
     begin
       msprite.scantime := timecount + 30;
       goto endscan;
        end;

     if (msprite.typ = S_MONSTER15) and ((absI(tx - sx)>4) or (absI(ty - sy)>4)) then
     begin
       msprite.scantime := timecount + 30;
       goto endscan;
        end;

     msprite.basepic := msprite.startpic + 32;
     msprite.movemode := 6;
     if msprite.typ = S_MONSTER5 then
      msprite.firetime := timecount+(10+3*player.difficulty);
     else
      msprite.firetime := timecount+(40+5*player.difficulty);

     msprite.actiontime := timecount + 30;
     msprite.modetime := timecount + 15;
     if msprite.typ = S_MONSTER3 then
      fheight := 3 shl FRACBITS;
     else if (msprite.typ = S_MONSTER6)
      fheight := 100 shl FRACBITS;
     else
      fheight := 40 shl FRACBITS;

     pangle := GetFireAngle(fheight, tx, ty, targx, targy, targz)-15+(MS_RndT) and (31);
     if (msprite.typ = S_MONSTER13) or (msprite.typ = S_MONSTER6) or (msprite.typ = S_MONSTER15) or (msprite.typ = S_MONSTER5) then
     begin
       SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z,fheight, msprite.angle-15+(MS_RndT) and (31)+16, pangle, true, 255);
       SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z,fheight, msprite.angle-15+(MS_RndT) and (31)-16, pangle, true, 255);
       SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z,fheight, msprite.angle-15+(MS_RndT) and (31), pangle, true, 255);
     end
     else if msprite.typ = S_MONSTER4 then
     begin
       SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z,fheight, msprite.angle-15+(MS_RndT) and (31)+8, pangle, true, 255);
       SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z,fheight, msprite.angle-15+(MS_RndT) and (31)-8, pangle, true, 255);
        end;
     else
      SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z,fheight, msprite.angle-15+(MS_RndT) and (31), pangle, true, 255);
      end;
   msprite.scantime := timecount + 30;
    end;
endscan:
  if timecount>msprite.modetime then
  begin
   msprite.modetime := timecount + 8;
   case msprite.movemode  of
   begin
     0: // 1
     1: // 2
     2: // 3
      if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
      begin
  ++msprite.movemode;
  msprite.basepic := msprite.startpic+msprite.movemode*8;
  msprite.lasty := msprite.y;
  msprite.lastx := msprite.x;
   end;
      break;
     3: // 2
     4: // 1
      if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
      begin
  msprite.movemode++;
  msprite.basepic := msprite.startpic+(6-msprite.movemode)*8;
  msprite.lasty := msprite.y;
  msprite.lastx := msprite.x;
   end;
      break;
     5:
      if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
      begin
  msprite.movemode := 0;
  msprite.basepic := msprite.startpic;
  msprite.lasty := msprite.y;
  msprite.lastx := msprite.x;
   end;
      break;
     6: // fire
      msprite.movemode := 0;
      msprite.basepic := msprite.startpic;
      break;
      end;
   end;

  if (timecount>msprite.actiontime) and (SP_Thrust2 <> 1) then
  begin
   angle := msprite.angle + DEGREE45;
   msprite.angle := angle) and (ANGLES;
    end;
  floorz := RF_GetFloorZ(msprite.x, msprite.y) + msprite.zadj;
  if floorz<msprite.z then
  msprite.z-:= FRACUNIT shl 4;
  if floorz>msprite.z then
  msprite.z := floorz;
  msprite.moveSpeed := oldspeed;
  if MS_RndT >= 255 then
  ActivationSound(msprite);
  end;


(***************************************************************************)

procedure MoveSprites;
begin
  mapspot, i, j, c, px, py, sx, sy: integer;
  killed: boolean;
  floor: fixed_t;

  if not netmode then
  begin
   targx := player.x;
   targy := player.y;
   px := targx shr FRACTILESHIFT;
   py := targy shr FRACTILESHIFT;
    end;

  for (msprite := firstscaleobj.next;msprite <> @lastscaleobj;msprite := msprite.next)
  begin
   if msprite.active then
   begin
     if msprite.moveSpeed then
      case msprite.intelligence  of
      begin
  0:
   killed := Int0;
   if killed then
   begin
     if msprite.typ = S_BLOODSPLAT then
     begin
       msprite.intelligence := 128;
       break;
     end
     else if (msprite.typ = S_METALPARTS) and ( not spritehit) then
     begin
       killed := false;
       continue;
        end;
     msprite := msprite.prev;
     RF_RemoveSprite(msprite.next);
     killed := false;
     continue;
      end;
   break;
  5:
   Int5;
   break;
  6:
   killed := Int6;
   if killed then
   begin
     msprite := msprite.prev;
     RF_RemoveSprite(msprite.next);
     killed := false;
     continue;
      end;
   break;
  7:
   Int7;
   break;
  8:
   Int8;
   break;
  9:
   Int9;
   break;
  10:
   Int10;
   break;
  128:
   floor := RF_GetFloorZ(msprite.x, msprite.y);
   if msprite.z > floor + FRACUNIT then
    msprite.z-:= FRACUNIT * 2;
   if msprite.z < floor then
    msprite.z := floor;
   break;
   end;
     if (not killed) and (msprite.heat) then
     begin
       mapspot := (msprite.y shr FRACTILESHIFT) * MAPCOLS + (msprite.x shr FRACTILESHIFT);
       if msprite.heat > 256 then
       begin
   c := msprite.heat shr 1;
   for(i := -1;i<2;i++)
    for(j := -1;j<2;j++)
     reallight[mapspot+(i*MAPCOLS)+j]-:= c;
   reallight[mapspot]-:= msprite.heat shr 2;
    end;
       else reallight[mapspot] := reallight[mapspot] - msprite.heat;
        end;
     killed := false;
   end
   else if msprite.intelligence <> 255 then
   begin

     if msprite.moveSpeed then
     begin

       sx := msprite.x shr FRACTILESHIFT;
       sy := msprite.y shr FRACTILESHIFT;
       if netmode then
       begin
   NetGetClosestPlayer(sx, sy);
   px := targx shr FRACTILESHIFT;
   py := targy shr FRACTILESHIFT;
    end;

       if ((absI(px - sx) < 6) and (absI(py - sy) < 6)) then
       begin
   msprite.active := true;
   ActivateSprites(sx, sy);
    end;
        end;

     floor := RF_GetFloorZ(msprite.x, msprite.y) + msprite.zadj;
     if (msprite.z > floor) msprite.z-:= FRACUNIT shl 4;
     if (msprite.z < floor) msprite.z := floor;
     if msprite.heat then
     begin
       mapspot := (msprite.y shr FRACTILESHIFT) * MAPCOLS + (msprite.x shr FRACTILESHIFT);
       if msprite.heat > 256 then
       begin
   c := msprite.heat shr 1;
   for(i := -1;i<2;i++)
    for(j := -1;j<2;j++)
     reallight[mapspot+(i*MAPCOLS)+j]-:= c;
   reallight[mapspot]-:= msprite.heat shr 2;
   msprite.heat := msprite.heat - 64;
    end;
       else reallight[mapspot] := reallight[mapspot] - msprite.heat;
        end;
      end;
    end;
  end;

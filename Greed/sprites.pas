(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020-2022 by Jim Valavanis                                *)
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
  g_delphi,
  r_public_h;

var
  msprite: Pscaleobj_t;
  probe: scaleobj_t;
  spritehit, playerhit: boolean;
  hitx, hity, targx, targy, targz: fixed_t;
  spriteloc: integer; // where did it hit on a sprite

procedure ActivationSound(const sp: Pscaleobj_t);

function SP_Thrust: byte;

procedure MoveSprites;

implementation

uses
  d_ints,
  d_misc,
  modplay,
  net,
  protos_h,
  spawn,
  raven,
  r_conten,
  r_public,
  r_refdef,
  r_render,
  utils;

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
  xl := ((xcenter - msprite.movesize) div FRACTILEUNIT);
  yl := ((ycenter - msprite.movesize) div FRACTILEUNIT);
  xh := ((xcenter + msprite.movesize) div FRACTILEUNIT);
  yh := ((ycenter + msprite.movesize) div FRACTILEUNIT);
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
              SoundEffect(SN_DOOR, 15, door_p.tilex * FRACTILEUNIT, door_p.tiley * FRACTILEUNIT);
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
              SoundEffect(SN_DOOR, 15, door_p.tilex * FRACTILEUNIT, door_p.tiley * FRACTILEUNIT);
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
  xl := ((xcenter - msprite.movesize) div FRACTILEUNIT);
  yl := ((ycenter - msprite.movesize) div FRACTILEUNIT);
  xh := ((xcenter + msprite.movesize) div FRACTILEUNIT);
  yh := ((ycenter + msprite.movesize) div FRACTILEUNIT);
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
              SoundEffect(SN_DOOR, 15, door_p.tilex * FRACTILEUNIT, door_p.tiley * FRACTILEUNIT);
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
              SoundEffect(SN_DOOR, 15, door_p.tilex * FRACTILEUNIT, door_p.tiley * FRACTILEUNIT);
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
  xl := ((xcenter - msprite.movesize) div FRACTILEUNIT);
  yl := ((ycenter - msprite.movesize) div FRACTILEUNIT);
  xh := ((xcenter + msprite.movesize) div FRACTILEUNIT);
  yh := ((ycenter + msprite.movesize) div FRACTILEUNIT);
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
        if msprite.z < RF_GetFloorZ((x * FRACTILEUNIT) + (32 * FRACUNIT), (y * FRACTILEUNIT) + (32 * FRACUNIT)) then
        begin
          result := 2;    // below floor
          exit;
        end;
        if msprite.z > RF_GetCeilingZ((x * FRACTILEUNIT) + (32 * FRACUNIT), (y * FRACTILEUNIT) + (32 * FRACUNIT)) then
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
    xl := xcenter div FRACTILEUNIT;
    xh := (xcenter + msprite.movesize) div FRACTILEUNIT;
  end
  else if (angle > NORTH) and (angle < SOUTH) then
  begin
    xh := xcenter div FRACTILEUNIT;
    xl := (xcenter - msprite.movesize) div FRACTILEUNIT;
  end
  else
  begin
    xl := (xcenter - msprite.movesize) div FRACTILEUNIT;
    xh := (xcenter + msprite.movesize) div FRACTILEUNIT;
  end;

  if angle > WEST then
  begin
    yl := ycenter div FRACTILEUNIT;
    yh := (ycenter + msprite.movesize) div FRACTILEUNIT;
  end
  else if (angle < WEST) and (angle <> EAST) then
  begin
    yl := (ycenter - msprite.movesize) div FRACTILEUNIT;
    yh := ycenter div FRACTILEUNIT;
  end
  else
  begin
    yl := (ycenter - msprite.movesize) div FRACTILEUNIT;
    yh := (ycenter + msprite.movesize) div FRACTILEUNIT;
  end;
  sz :=  msprite.z - msprite.zadj + (20 * FRACUNIT);
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

      floorz := RF_GetFloorZ((x * FRACTILEUNIT) + (32 * FRACUNIT), (y * FRACTILEUNIT) + (32 * FRACUNIT));
      if floorz > sz then
      begin
        result := false;
        exit;
      end;

      if msprite.nofalling and (floorz + (5 * FRACUNIT) < sz2) then
      begin
        result := false;
        exit;
      end;

      ceilingz := RF_GetCeilingZ((x * FRACTILEUNIT) + (32 * FRACUNIT), (y * FRACTILEUNIT) + (32 * FRACUNIT));
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
  smapspot := (msprite.y div FRACTILEUNIT) * MAPCOLS + (msprite.x div FRACTILEUNIT);
  if SP_TryMove2(msprite.angle, dx, dy, smapspot) and SP_TryDoor(dx, dy) then
  begin
    if floorpic[(dy div FRACTILEUNIT) * MAPCOLS + (dx div FRACTILEUNIT)] = 0 then
    begin
      result := 0;
      exit;
    end;

    mapsprites[smapspot] := 0;
    msprite.x := msprite.x + xmove;
    msprite.y := msprite.y + ymove;
    mapsprites[(msprite.y div FRACTILEUNIT) * MAPCOLS + (msprite.x div FRACTILEUNIT)] := ms;
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
  end;
  if SP_TryMove2(angle2, dx, msprite.y, smapspot) and SP_TryDoor(dx, msprite.y) then
  begin
    if floorpic[(msprite.y div FRACTILEUNIT) * MAPCOLS + (dx div FRACTILEUNIT)] = 0 then
    begin
      result := 0;
      exit;
    end;
    mapsprites[smapspot] := 0;
    msprite.x := msprite.x + xmove;
    mapsprites[(msprite.y div FRACTILEUNIT) * MAPCOLS + (msprite.x div FRACTILEUNIT)] := ms;
    result := 2;
    exit;
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
  end;
  if SP_TryMove2(angle2, msprite.x, dy, smapspot) and SP_TryDoor(msprite.x, dy) then
  begin
    if floorpic[(dy div FRACTILEUNIT) * MAPCOLS + (msprite.x div FRACTILEUNIT)] = 0 then
    begin
      result := 0;
      exit;
    end;
    mapsprites[smapspot] := 0;
    msprite.y := msprite.y + ymove;
    mapsprites[(msprite.y div FRACTILEUNIT) * MAPCOLS + (msprite.x div FRACTILEUNIT)] := ms;
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
  case sp.typ of
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
procedure ActivateSprites(const sx, sy: integer);
var
  sp: Pscaleobj_t;
  x, y: integer;
begin
  sp := firstscaleobj.next;
  while sp <> @lastscaleobj do
  begin
    if (sp.active = false) and (sp.moveSpeed <> 0) then
    begin
      x := sp.x div FRACTILEUNIT;
      y := sp.y div FRACTILEUNIT;
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
  ActivateSprites(msprite.x div FRACTILEUNIT, msprite.y div FRACTILEUNIT);
end;


procedure HitSprite(const sp: Pscaleobj_t);
begin
  case sp.typ of
  S_CLONE:
    begin
      if not sp.active then
      begin
        ActivateSprites(sp.x div FRACTILEUNIT, sp.y div FRACTILEUNIT);
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
        ActivateSprites(sp.x div FRACTILEUNIT, sp.y div FRACTILEUNIT);
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
function Int0: boolean;
var
  hsprite, sp: Pscaleobj_t;
  counter, mapspot, angle, angleinc, ret, i: integer;
  oldfall: boolean;
  oldangle, oldmovespeed: integer;
  killed, blood: boolean;

  function inc_counter: integer;
  begin
    result := counter;
    inc(counter);
  end;

begin
  counter := 0;
  killed := false;

  if msprite.typ = S_GRENADE then
    msprite.angle2 := msprite.angle2 - 4
  else if ((msprite.typ = S_BLOODSPLAT) or (msprite.typ = S_METALPARTS)) and ((msprite.angle2 < NORTH) or (msprite.angle2 > SOUTH)) then
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
  while inc_counter < msprite.moveSpeed do
  begin
    ret := SP_Thrust;
    if msprite.typ = S_BULLET3 then
      msprite.z := RF_GetFloorZ(msprite.x, msprite.y) + (20 * FRACUNIT);

    if ret <> 0 then
    begin
      if msprite.typ = S_BLOODSPLAT then
      begin
        if ret = 2 then
        begin
          result := true;
          exit;
        end;
        spritehit := false;
        playerhit := false;
      end
      else if (msprite.typ = S_METALPARTS) and (ret = 2) then
      begin
        playerhit := false;
        result := true;
        exit;
      end;
      if spritehit then
      begin
        if mapsprites[spriteloc] = SM_NETPLAYER then
        begin
          hsprite := firstscaleobj.next;
          while hsprite <> @lastscaleobj do
          begin
            if hsprite <> msprite then
            begin
              mapspot := (hsprite.y div FRACTILEUNIT) * MAPCOLS + (hsprite.x div FRACTILEUNIT);
              if mapspot = spriteloc then
              begin
                if (msprite.z < hsprite.z) or (msprite.z > hsprite.z + hsprite.height) or (hsprite.typ <> S_NETPLAYER) then
                  break;
                SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
                //  if msprite.typ <> S_BULLET17 then
                //    begin
                SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
                SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
                SpawnSprite(S_BLOODSPLAT, msprite.x, msprite.y, msprite.z, msprite.zadj, 0, 0, false, 0);
                blood := true;
                killed := true;
                //   end;
              end;
            end;
            hsprite := hsprite.next;
          end;
        end
        else
        begin
          hsprite := firstscaleobj.next;
          while hsprite <> @lastscaleobj do
          begin
            if hsprite <> msprite then
            begin
              mapspot := (hsprite.y div FRACTILEUNIT) * MAPCOLS + (hsprite.x div FRACTILEUNIT);
              if mapspot = spriteloc then
              begin
                if (msprite.z < hsprite.z) or (msprite.z > hsprite.z + hsprite.height) then
                begin
                  hsprite := hsprite.next;
                  continue;
                end;
                if hsprite.hitpoints <> 0 then
                begin
                  if hsprite.typ <> S_MONSTER5 then
                    hsprite.actiontime := hsprite.actiontime + 15
                  else
                    hsprite.actiontime := hsprite.actiontime + 5;
                  hsprite.hitpoints := hsprite.hitpoints - msprite.damage;
                  if msprite.spawnid = 255 then
                    inc(hsprite.enraged);

                  if (msprite.typ = S_SOULBULLET) and (msprite.spawnid = playernum) then
                  begin
                    heal(msprite.damage div 2);
                    medpaks(msprite.damage div 2);
                  end;

                  killed := true;
                  if hsprite.hitpoints <= 0 then
                  begin
                    if (msprite.spawnid = playernum) or (msprite.spawnid - 200 = playernum) then
                    begin
                      inc(player.bodycount);
                      addscore(hsprite.score);
                    end;
                    mapsprites[spriteloc] := 0;
                    blood := true;
                    HitSprite(hsprite);
                    KillSprite(hsprite, msprite.typ);
                  end
                  else if msprite.damage <> 0 then
                  begin
                    oldangle := hsprite.angle;
                    oldmovespeed := hsprite.moveSpeed;
                    hsprite.angle := msprite.angle;
                    hsprite.moveSpeed := (msprite.damage div 4) * FRACUNIT;
                    sp := msprite;
                    msprite := hsprite;
                    oldfall := msprite.nofalling;
                    msprite.nofalling := false;
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
            hsprite := hsprite.next;
          end;
        end;
      end
      else if playerhit and (msprite.z > player.z - player.height) and (msprite.z < player.z) then
      begin
        if player.angst <> 0 then // don't keep hitting
        begin
          hurt(msprite.damage);
          if (player.angst = 0) and netmode then
            NetDeath(msprite.spawnid);
        end;
        Thrust(msprite.angle, msprite.damage shl (FRACBITS - 3));
        playerhit := false;
        killed := true;
        if msprite.damage > 50 then
        begin
          player.angle := player.angle - 15 + (MS_RndT and 31);
          player.angle := player.angle and ANGLES;
          player_angle64 := player.angle * 64;
        end;
      end;
      if ret = 2 then
        killed := true;
      if killed then
      begin
        if not blood then
          ShowWallPuff;
        break;
      end;
    end;
  end;
  if killed and (msprite.typ = S_GRENADE) then
  begin
    angleinc := ANGLES div 12;
    angle := 0;
    for i := 0 to 11 do
    begin
      sp := SpawnSprite(S_GRENADEBULLET, msprite.x, msprite.y, msprite.z, 20 * FRACUNIT, angle, 0, true, msprite.spawnid);
      sp.maxmove := 3;
      sp.startspot := -1;
      angle := angle + angleinc;
    end;
    angleinc := ANGLES div 8;
    angle := 0;
    for i := 0 to 7 do
    begin
      sp := SpawnSprite(S_GRENADEBULLET, msprite.x, msprite.y, msprite.z, 20 * FRACUNIT, angle,64, true, msprite.spawnid);
      sp.maxmove := 2;
      sp.startspot := -1;
      angle := angle + angleinc;
    end;
    angleinc := ANGLES div 8;
    angle := 0;
    for i := 0 to 7 do
    begin
      sp := SpawnSprite(S_GRENADEBULLET, msprite.x, msprite.y, msprite.z, 20 * FRACUNIT, angle,-64, true, msprite.spawnid);
      sp.maxmove := 2;
      sp.startspot := -1;
      angle := angle + angleinc;
    end;
    sp := SpawnSprite(S_EXPLODE, msprite.x, msprite.y, msprite.z, 0, 0, 0, true, 255);
    SoundEffect(SN_EXPLODE1 + (MS_RndT and 1), 15, msprite.x, msprite.y);
  end
  else if killed and (msprite.typ = S_BULLET17) then
  begin
    angleinc := ANGLES div 8;
    angle := 0;
    for i := 0 to 7 do
    begin
      sp := SpawnSprite(S_GRENADEBULLET, msprite.x, msprite.y, msprite.z, 20 * FRACUNIT, angle, 0, true, msprite.spawnid);
      sp.maxmove := 3;
      sp.startspot := -1;
      angle := angle + angleinc;
    end;
    angleinc := ANGLES div 6;
    angle := 0;
    for i := 0 to 5 do
    begin
      sp := SpawnSprite(S_GRENADEBULLET, msprite.x, msprite.y, msprite.z, 20 * FRACUNIT, angle,64, true, msprite.spawnid);
      sp.maxmove := 2;
      sp.startspot := -1;
      angle := angle + angleinc;
    end;
    angleinc := ANGLES div 6;
    angle := 0;
    for i := 0 to 5 do
    begin
      sp := SpawnSprite(S_GRENADEBULLET, msprite.x, msprite.y, msprite.z, 20 * FRACUNIT, angle,-64, true, msprite.spawnid);
      sp.maxmove := 2;
      sp.startspot := -1;
      angle := angle + angleinc;
    end;
    sp := SpawnSprite(S_EXPLODE, msprite.x, msprite.y, msprite.z, 0, 0, 0, true, 255);
    SoundEffect(SN_EXPLODE1 + (MS_RndT and 1), 15, msprite.x, msprite.y);
  end;
  result := killed;
end;

//***************************************************************************
// check for the player along the x axis
function ScanX(const limit1, x1, y1, x2, y2: integer; const tx, ty: PInteger): integer;
var
  mapspot, wall, x, limit, flags: integer;
begin
  mapspot := y1 * MAPCOLS + x1 + 1;
  x := x1;
  limit := limit1;
  while true do
  begin
    if (mapsprites[mapspot] = SM_NETPLAYER) or (mapsprites[mapspot] = SM_CLONE) or ((x = x2) and (y1 = y2)) then
    begin
      tx^ := x + 1;
      result := 2;
      exit;
    end;
    if (msprite.enraged >= 6 - player.difficulty) and (mapsprites[mapspot] = 1) then
    begin
      tx^ := x + 1;
      ty^ := y1;
      result := 2;
      exit;
    end;
    if (mapsprites[mapspot] > 0) and (mapsprites[mapspot] < 128) then
      break;
    wall := westwall[mapspot];
    flags := westflags[mapspot];
    if (wall <> 0) and (flags and F_NOCLIP = 0) and (flags and F_NOBULLETCLIP = 0) then
      break;
    inc(mapspot);
    inc(x);
    dec(limit);
    if limit = 0 then
      break;
  end;

  limit := limit1;
  mapspot := y1 * MAPCOLS + x1 - 1;
  x := x1;
  while true do
  begin
    if (mapsprites[mapspot] = SM_NETPLAYER) or (mapsprites[mapspot] = SM_CLONE) or ((x = x2) and (y1 = y2)) then
    begin
      tx^ := x - 1;
      result := 2;
      exit;
    end;
    if (msprite.enraged >= 6 - player.difficulty) and (mapsprites[mapspot] = 1) then
    begin
     tx^ := x - 1;
     ty^ := y1;
     result := 2;
     exit;
    end;
    if (mapsprites[mapspot] > 0) and (mapsprites[mapspot] < 128) then
    begin
      result := 1;
      exit;
    end;
    wall := westwall[mapspot + 1];
    flags := westflags[mapspot + 1];
    if (wall <> 0) and (flags and F_NOCLIP = 0) and (flags and F_NOBULLETCLIP = 0) then
    begin
      result := 0;
      exit;
    end;
    dec(mapspot);
    dec(x);
    dec(limit);
    if limit = 0 then
      break;
  end;
  result := 0;
end;


// check for the player along the y axis
function ScanY(const limit1, x1, y1, x2, y2: integer; const tx, ty: PInteger): integer;
var
  mapspot, wall, y, limit, flags: integer;
begin
  limit := limit1;
  mapspot := y1* MAPCOLS + x1 + MAPCOLS;
  y := y1;
  while true do
  begin
    if (mapsprites[mapspot] = SM_NETPLAYER) or (mapsprites[mapspot] = SM_CLONE) or ((y = y2) and (x1 = x2)) then
    begin
      ty^ := y + 1;
      result := 2;
      exit;
    end;
    if (msprite.enraged >= 6 - player.difficulty) and (mapsprites[mapspot] = 1) then
    begin
     tx^ := x1;
     ty^ := y + 1;
     result := 2;
     exit;
    end;
    if (mapsprites[mapspot] > 0) and (mapsprites[mapspot] < 128) then
      break;
    wall := northwall[mapspot];
    flags := northflags[mapspot];
    if (wall <> 0) and (flags and F_NOCLIP = 0) and (flags and F_NOBULLETCLIP = 0) then
      break;
    mapspot := mapspot + MAPCOLS;
    inc(y);
    inc(limit);
    if limit = 0 then
      break;
  end;

  limit := limit1;
  mapspot := y1 * MAPCOLS + x1 - MAPCOLS;
  y := y1;
  while true do
  begin
    if (mapsprites[mapspot] = SM_NETPLAYER) or (mapsprites[mapspot] = SM_CLONE) or ((y = y2) and (x1 = x2)) then
    begin
      ty^ := y - 1;
      result := 2;
      exit;
    end;
    if (msprite.enraged >= 6 - player.difficulty) and (mapsprites[mapspot] = 1) then
    begin
      tx^ := x1;
      ty^ := y - 1;
      result := 2;
      exit;
    end;
    if (mapsprites[mapspot] > 0) and (mapsprites[mapspot] < 128) then
      break;
    wall := northwall[mapspot + MAPCOLS];
    flags := northflags[mapspot + MAPCOLS];
    if (wall <> 0) and (flags and F_NOCLIP = 0) and (flags and F_NOBULLETCLIP = 0) then
      break;
    mapspot := mapspot - MAPCOLS;
    dec(y);
    dec(limit);
    if limit = 0 then
      break;
  end;
  result := 0;
end;


// scan for the player along a 45 degree angle
// this is not very accurate!!  approximate only
function ScanAngle(const limit1, x1, y1, x2, y2: integer ; const tx, ty: PInteger): integer;
var
  mapspot, wall, x, y, limit, flags: integer;
begin
  limit := limit1;
  mapspot := y1 * MAPCOLS + x1 + MAPCOLS + 1;
  y := y1;
  x := x1;
  while true do
  begin
    wall := northwall[mapspot - 1];
    flags := northflags[mapspot - 1];
    if (wall <> 0) and (flags and F_NOCLIP = 0) and (flags and F_NOBULLETCLIP = 0) then
      break;
    wall := westwall[mapspot - MAPCOLS];
    flags := westflags[mapspot - MAPCOLS];
    if (wall <> 0) and (flags and F_NOCLIP = 0) and (flags and F_NOBULLETCLIP = 0) then
    begin
      result := 0;
      exit;
    end;
    if (mapsprites[mapspot] = SM_NETPLAYER) or (mapsprites[mapspot] = SM_CLONE) or ((y = y2) and (x = x2)) then
    begin
      tx^ := x + 1;
      ty^ := y + 1;
      result := 2;
      exit;
    end;
    if (msprite.enraged >= 6 - player.difficulty) and (mapsprites[mapspot] = 1) then
    begin
      tx^ := x + 1;
      ty^ := y + 1;
      result := 2;
      exit;
    end;
    if (mapsprites[mapspot] > 0) and (mapsprites[mapspot] < 128) then
      break;

    mapspot := mapspot + MAPCOLS + 1;
    inc(y);
    inc(x);
    dec(limit);
    if limit = 0 then
      break;
  end;

  limit := limit1;
  mapspot := y1 * MAPCOLS + x1 + MAPCOLS - 1;
  y := y1;
  x := x1;
  while true do
  begin
    wall := northwall[mapspot + 1];
    flags := northflags[mapspot + 1];
    if (wall <> 0) and (flags and F_NOCLIP = 0) and (flags and F_NOBULLETCLIP = 0) then
      break;

    wall := westwall[mapspot - MAPCOLS];
    flags := westflags[mapspot - MAPCOLS];
    if (wall <> 0) and (flags and F_NOCLIP = 0) and (flags and F_NOBULLETCLIP = 0) then
    begin
      result := 0;
      exit;
    end;

    if (mapsprites[mapspot] = SM_NETPLAYER) or (mapsprites[mapspot] = SM_CLONE) or ((y = y2) and (x = x2)) then
    begin
      tx^ := x - 1;
      ty^ := y + 1;
      result := 2;
      exit;
    end;
    if (msprite.enraged >= 6 - player.difficulty) and (mapsprites[mapspot] = 1) then
    begin
      tx^ := x - 1;
      ty^ := y + 1;
      result := 2;
      exit;
    end;
    if (mapsprites[mapspot] > 0) and (mapsprites[mapspot] < 128) then
      break;

    mapspot := mapspot + MAPCOLS - 1;
    inc(y);
    dec(x);
    dec(limit);
    if limit = 0 then
      break;
  end;

  limit := limit1;
  mapspot := y1 * MAPCOLS + x1 - MAPCOLS + 1;
  y := y1;
  x := x1;
  while true do
  begin
    wall := northwall[mapspot - 1 + MAPCOLS];
    flags := northflags[mapspot - 1 + MAPCOLS];
    if (wall <> 0) and (flags and F_NOCLIP = 0) and (flags and F_NOBULLETCLIP = 0) then
      break;

    wall := westwall[mapspot - MAPCOLS];
    flags := westflags[mapspot - MAPCOLS];
    if (wall <> 0) and (flags and F_NOCLIP = 0) and (flags and F_NOBULLETCLIP = 0) then
    begin
      result := 0;
      exit;
    end;

    if (mapsprites[mapspot] = SM_NETPLAYER) or (mapsprites[mapspot] = SM_CLONE) or ((y = y2) and (x = x2)) then
    begin
      tx^ := x + 1;
      ty^ := y - 1;
      result := 2;
      exit;
    end;
    if (msprite.enraged >= 6 - player.difficulty) and (mapsprites[mapspot] = 1) then
    begin
      tx^ := x + 1;
      ty^ := y - 1;
      result := 2;
      exit;
    end;
    if (mapsprites[mapspot] > 0) and (mapsprites[mapspot] < 128) then
      break;

    mapspot := mapspot - (MAPCOLS + 1);
    dec(y);
    inc(x);
    dec(limit);
    if limit = 0 then
      break;
  end;

  limit := limit1;
  mapspot := y1 * MAPCOLS + x1 - MAPCOLS - 1;
  y := y1;
  x := x1;
  while true do
  begin
    wall := northwall[mapspot + 1 + MAPCOLS];
    flags := northflags[mapspot + 1 + MAPCOLS];
    if (wall <> 0) and (flags and F_NOCLIP = 0) and (flags and F_NOBULLETCLIP = 0) then
      break;

    wall := westwall[mapspot - MAPCOLS];
    flags := westflags[mapspot - MAPCOLS];
    if (wall <> 0) and (flags and F_NOCLIP = 0) and (flags and F_NOBULLETCLIP = 0) then
    begin
      result := 0;
      exit;
    end;

    if (mapsprites[mapspot] = SM_NETPLAYER) or (mapsprites[mapspot] = SM_CLONE) or ((y = y2) and (x = x2)) then
    begin
      tx^ := x - 1;
      ty^ := y - 1;
      result := 2;
      exit;
    end;
    if (msprite.enraged >= 6 - player.difficulty) and (mapsprites[mapspot] = 1) then
    begin
      tx^ := x - 1;
      ty^ := y - 1;
      result := 2;
      exit;
    end;
    if (mapsprites[mapspot] > 0) and (mapsprites[mapspot] < 128) then
      break;

    mapspot := mapspot - (MAPCOLS - 1);
    dec(y);
    dec(x);
    dec(limit);
    if limit = 0 then
      break;
  end;

  result := 0;
end;

//***************************************************************************

function GetFireAngle(sz: fixed_t; const x1, y1: integer; px, py, pz: fixed_t): integer;
var
  hsprite: Pscaleobj_t;
  x, y, z, d, spriteloc, mapspot: integer;
  found: boolean;
begin
  sz := sz + msprite.z;
  if (x1 <> px div FRACTILEUNIT) or (y1 <> py div FRACTILEUNIT) then
  begin
    spriteloc := y1 * MAPCOLS + x1;
    found := false;
    hsprite := firstscaleobj.next;
    while hsprite <> @lastscaleobj do
    begin
      if hsprite.hitpoints <> 0 then
      begin
        mapspot := (hsprite.y div FRACTILEUNIT) * MAPCOLS + (hsprite.x div FRACTILEUNIT);
        if mapspot = spriteloc then
        begin
          found := true;
          break;
        end;
      end;
      hsprite := hsprite.next;
    end;

    if found then
    begin
      px := hsprite.x;
      py := hsprite.y;
      pz := hsprite.z + (32 * FRACUNIT);
    end;
  end
  else
    pz := pz + 20 * FRACUNIT;

  if sz > pz then
  begin
    z := _SHR((sz - pz), (FRACBITS + 2));
    if z >= MAXAUTO then
    begin
      result := 0;
      exit;
    end;
    x := _SHR((msprite.x - px), (FRACBITS + 2));
    y := _SHR((msprite.y - py), (FRACBITS + 2));
    d := trunc(sqrt(x * x + y * y));
    if (d >= MAXAUTO) or (autoangle2[d][z] = -1) then
    begin
      result := 0;
      exit;
    end;

    result := -autoangle2[d][z];
    exit;
  end
  else if sz < pz then
  begin
    z := _SHR((pz - sz), (FRACBITS + 2));
    if z >= MAXAUTO then
    begin
      result := 0;
      exit;
    end;

    x := _SHR((msprite.x - px), (FRACBITS + 2));
    y := _SHR((msprite.y - py), (FRACBITS + 2));
    d := trunc(sqrt(x * x + y * y));
    if (d >= MAXAUTO) or (autoangle2[d][z] = -1) then
    begin
      result := 0;
      exit;
    end;
    result := autoangle2[d][z];
  end
  else
    result := 0;
end;

//**************************************************************************

procedure Int5;  // priests / viscount lords
var
  angle, sx, sy, px, py, tx, ty, pangle: integer;
  floorz, oldspeed, fheight: fixed_t;
begin
  sx := msprite.x div FRACTILEUNIT;
  sy := msprite.y div FRACTILEUNIT;
  if netmode then
    NetGetClosestPlayer(sx, sy)
  else
  begin
    if specialeffect = SE_INVISIBILITY then
    begin
      targx := 0;
      targy := 0;
      targz := 0;
    end
    else
    begin
      targx := player.x;
      targy := player.y;
      targz := player.z;
    end;
  end;
  px := targx div FRACTILEUNIT;
  py := targy div FRACTILEUNIT;

  oldspeed := msprite.moveSpeed;
  if (absI(px - sx) < 6) and (absI(py - sy) < 6) then
    msprite.moveSpeed := msprite.moveSpeed * 2;

  if timecount > msprite.movetime then
  begin
    if px > sx then
      angle := EAST
    else if px < sx then
      angle := WEST
    else
      angle := -1;
    if py < sy then
    begin
      if angle = EAST then
        angle := angle + DEGREE45
      else if angle = WEST then
        angle := angle - DEGREE45
      else
        angle := NORTH;
    end
    else if py > sy then
    begin
      if angle = EAST then
        angle := angle - DEGREE45
      else if angle = WEST then
        angle := angle + DEGREE45
      else
        angle := SOUTH;
    end;
    angle := angle - DEGREE45 + MS_RndT;
    msprite.angle := angle and ANGLES;
    msprite.movetime := timecount + 2 * TICRATE; // 350
  end;

  if (timecount > msprite.firetime) and (timecount > msprite.scantime) then
  begin
    tx := px;
    ty := py;
    if (ScanX(10, sx, sy, px, py, @tx, @ty) > 1) or
       (ScanY(10, sx, sy, px, py, @tx, @ty) > 1) or
       (ScanAngle(10, sx, sy, px, py, @tx, @ty) > 1) then
    begin
      if tx > sx then
        angle := EAST
      else if tx < sx then
        angle := WEST
      else
        angle := -1;
      if ty < sy then
      begin
        if angle = EAST then
          angle := angle + DEGREE45
        else if angle = WEST then
          angle := angle - DEGREE45
        else
          angle := NORTH;
      end
      else if ty > sy then
      begin
        if angle = EAST then
          angle := angle - DEGREE45
        else if angle = WEST then
          angle := angle + DEGREE45
        else
          angle := SOUTH;
      end;
      msprite.angle := angle and ANGLES;
      msprite.basepic := msprite.startpic + 24;
      msprite.movemode := 4;
      msprite.firetime := timecount + (40 + 5 * player.difficulty);
      msprite.actiontime := timecount + 30;
      msprite.modetime := timecount + 15;
    end;
    msprite.scantime := timecount + 30;
  end;

  if timecount > msprite.modetime then
  begin
    msprite.modetime := timecount + 10;
    case msprite.movemode of
    0, // left
    1: // mid
      begin
        if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
        begin
          inc(msprite.movemode);
          msprite.basepic := msprite.startpic + msprite.movemode * 8;
          msprite.lasty := msprite.y;
          msprite.lastx := msprite.x;
        end;
      end;

    2: // right
      begin
        if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
        begin
          msprite.basepic := msprite.startpic + 8; // midstep
          inc(msprite.movemode);
          msprite.lasty := msprite.y;
          msprite.lastx := msprite.x;
        end;
      end;

    3: // mid #2
      begin
        if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
        begin
          msprite.movemode := 0;
          msprite.basepic := msprite.startpic;
          msprite.lasty := msprite.y;
          msprite.lastx := msprite.x;
        end;
      end;

    4: // fire #1
      begin
        tx := px;
        ty := py;
        if (ScanX(10, sx, sy, px, py, @tx, @ty) > 1) or
           (ScanY(10, sx, sy, px, py, @tx, @ty) > 1) or
           (ScanAngle(10, sx, sy, px, py, @tx, @ty) > 1) then
        begin
          if tx > sx then
            angle := EAST
          else if tx < sx then
            angle := WEST
          else
            angle := -1;
          if ty < sy then
          begin
            if angle = EAST then
              angle := angle + DEGREE45
            else if angle = WEST then
              angle := angle - DEGREE45
            else
              angle := NORTH;
          end
          else if ty > sy then
          begin
            if angle = EAST then
              angle := angle - DEGREE45
            else if angle = WEST then
              angle := angle + DEGREE45
            else
              angle := SOUTH;
          end;
          msprite.angle := angle and ANGLES;
          msprite.movemode := 5;
          msprite.basepic := msprite.startpic + 32;
          if msprite.typ = S_MONSTER7 then
            fheight := 15 * FRACUNIT
          else
            fheight := 40 * FRACUNIT;
          pangle := GetFireAngle(fheight, tx, ty, targx, targy, targz) - 15 + (MS_RndT and 31);
          SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, fheight, msprite.angle - 15 + (MS_RndT and 31), pangle, true, 255);
          msprite.modetime := msprite.modetime + 8;
        end
        else
        begin
          msprite.movemode := 0;
          msprite.basepic := msprite.startpic;
        end;
      end;

    5: // fire #2
      begin
        msprite.movemode := 0;
        msprite.basepic := msprite.startpic;
      end;
    end;
  end;

  if (timecount > msprite.actiontime) and (SP_Thrust2 <> 1) then
  begin
    angle := msprite.angle + DEGREE45;
    msprite.angle := angle and ANGLES;
  end;

  floorz := RF_GetFloorZ(msprite.x, msprite.y);
  if floorz + msprite.zadj<msprite.z then
    msprite.z := msprite.z - 16 * FRACUNIT;
  if floorz + msprite.zadj > msprite.z then
    msprite.z := floorz + msprite.zadj;
  msprite.moveSpeed := oldspeed;
  if MS_RndT >= 255 then
    ActivationSound(msprite);
end;

(***************************************************************************)

function Int6: boolean; // intelligence for mines
var
  sp: Pscaleobj_t;
  i, j, angle, angleinc, x, y, sx, sy: integer;
  activate: boolean;
begin
  if timecount > msprite.actiontime then // now active
  begin
    if msprite.typ = S_TIMEMINE then
    begin
      angleinc := ANGLES div 20;
      angle := 0;
      for i := 0 to 19 do
      begin
        sp := SpawnSprite(S_MINEBULLET, msprite.x, msprite.y, msprite.z, 20 * FRACUNIT, angle, 0, true, msprite.spawnid);
        angle := angle + angleinc;
      end;
      sp := SpawnSprite(S_EXPLODE, msprite.x, msprite.y, msprite.z, 0, 0, 0, true, 255);
      SoundEffect(SN_EXPLODE1 + (MS_RndT and 1), 15, msprite.x, msprite.y);
      result := true;
      exit;
    end
    else if msprite.typ = S_PROXMINE then
    begin
      if MS_RndT and 1 <> 0 then
        msprite.angle := msprite.angle + 8
      else
        msprite.angle := msprite.angle - 8;
      msprite.angle := msprite.angle and ANGLES;
      x := msprite.x div FRACTILEUNIT;
      y := msprite.y div FRACTILEUNIT;
      activate := false;
      if (absI(x - (player.x div FRACTILEUNIT)) < 2) and (absI(y - (player.y div FRACTILEUNIT)) < 2) then
        activate := true;
      if not activate then
      begin
        sp := firstscaleobj.next;
        while sp <> @lastscaleobj do
        begin
          if sp.hitpoints <> 0 then
          begin
            sx := sp.x div FRACTILEUNIT;
            sy := sp.y div FRACTILEUNIT;
            if (absI(x - sx) < 2) and (absI(y - sy) < 2) then
            begin
              activate := true;
              break;
            end;
          end;
          sp := sp.next;
        end;
      end;
      for i := -1 to 1 do
        for j := -1 to 1 do
          if mapsprites[(i + y) * MAPCOLS + j + x] = SM_NETPLAYER then
            activate := true;
      if activate then
      begin
        angleinc := ANGLES div 16;
        angle := 0;
        for i := 0 to 15 do
        begin
          sp := SpawnSprite(S_MINEBULLET, msprite.x, msprite.y, msprite.z, 20 * FRACUNIT, angle, 0, true, msprite.spawnid);
          angle := angle + angleinc;
        end;
        sp := SpawnSprite(S_EXPLODE, msprite.x, msprite.y, msprite.z, 0, 0, 0, true, 255);
        SoundEffect(SN_EXPLODE1 + (MS_RndT and 1), 15, msprite.x, msprite.y);
        result := true;
        exit;
      end;
    end
    else if msprite.typ = S_INSTAWALL then
    begin
      mapsprites[(msprite.y div FRACTILEUNIT) * MAPCOLS + (msprite.x div FRACTILEUNIT)] := 0;
      result := true;
      exit;
    end;
  end;

  result := false;
end;

//***************************************************************************

// check for the target along the x axis
function CloneScanX(const x, y: integer; const x2: PInteger): integer;
var
  mapspot, wall, x1, limit, flags: integer;
begin
  mapspot := y * MAPCOLS + x + 1;
  x1 := x;
  limit := 10;
  while true do
  begin
    if (mapsprites[mapspot] = SM_CLONE) or (mapsprites[mapspot] = 1) then
    begin
      x2^ := x1 + 1;
      result := 1 + (MS_RndT and 1);
      exit;
    end;
    if (mapsprites[mapspot] > 0) and (mapsprites[mapspot] < 128) then
      break;
    wall := westwall[mapspot];
    flags := westflags[mapspot];
    if (wall <> 0) and (flags and F_NOCLIP = 0) and (flags and F_NOBULLETCLIP = 0) then
      break;
    inc(mapspot);
    inc(x1);
    dec(limit);
    if limit = 0 then
      break;
  end;

  limit := 10;
  mapspot := y * MAPCOLS + x - 1;
  x1 := x;
  while true do
  begin
    if (mapsprites[mapspot] = SM_CLONE) or (mapsprites[mapspot] = 1) then
    begin
      x2^ := x1 - 1;
      result := 1 + (MS_RndT and 1);
      exit;
    end;
    if (mapsprites[mapspot] > 0) and (mapsprites[mapspot] < 128) then
    begin
      result := 1;
      exit;
    end;
    wall := westwall[mapspot + 1];
    flags := westflags[mapspot + 1];
    if (wall <> 0) and (flags and F_NOCLIP = 0) and (flags and F_NOBULLETCLIP = 0) then
    begin
      result := 0;
      exit;
    end;
    dec(mapspot);
    dec(x1);
    dec(limit);
    if limit = 0 then
      break;
  end;

  result := 0;
end;


// check for the player along the y axis
function CloneScanY(const x, y: integer; const y2: PInteger): integer;
var
  mapspot, wall, y1, limit, flags: integer;
begin
  limit := 10;
  mapspot := y * MAPCOLS + x + MAPCOLS;
  y1 := y;
  while true do
  begin
    if (mapsprites[mapspot] = SM_CLONE) or (mapsprites[mapspot] = 1) then
    begin
      y2^ := y1 + 1;
      result := 1 + (MS_RndT and 1);
      exit;
    end;
    if (mapsprites[mapspot] > 0) and (mapsprites[mapspot] < 128) then
      break;
    wall := northwall[mapspot];
    flags := northflags[mapspot];
    if (wall <> 0) and (flags and F_NOCLIP = 0) and (flags and F_NOBULLETCLIP = 0) then
      break;
    mapspot := mapspot + MAPCOLS;
    inc(y1);
    dec(limit);
    if limit = 0 then
      break;
  end;

  limit := 10;
  mapspot := y * MAPCOLS + x - MAPCOLS;
  y1 := y;
  while true do
  begin
    if (mapsprites[mapspot] = SM_CLONE) or (mapsprites[mapspot] = 1) then
    begin
      y2^ := y1 - 1;
      result := 1 + (MS_RndT and 1);
      exit;
    end;
    if (mapsprites[mapspot] > 0) and (mapsprites[mapspot] < 128) then
      break;
    wall := northwall[mapspot + MAPCOLS];
    flags := northflags[mapspot + MAPCOLS];
    if (wall <> 0) and (flags and F_NOCLIP = 0) and (flags and F_NOBULLETCLIP = 0) then
      break;
    mapspot := mapspot - MAPCOLS;
    dec(y1);
    dec(limit);
    if limit = 0 then
      break;
  end;

  result := 0;
end;


// clone ai
procedure Int7;
var
  angle, sx, sy, px, py, pangle, r: integer;
  floorz, fheight: fixed_t;
begin
  sx := msprite.x div FRACTILEUNIT;
  sy := msprite.y div FRACTILEUNIT;

  if timecount > msprite.movetime then
  begin
    angle := msprite.angle - DEGREE45;
    r := MS_RndT mod 3;

    if r = 1 then
      angle := angle + DEGREE45
    else if r = 2 then
      angle := angle + NORTH;

    msprite.angle := angle and ANGLES;
    msprite.movetime := timecount + 250;
  end;

  if (timecount > msprite.firetime) and (timecount > msprite.scantime) then
  begin
    px := sx;
    py := sy;
    if CloneScanX(sx, sy, @px) > 1 then
    begin
      if px > sx then
        angle := EAST
      else if px < sx then
        angle := WEST;
      msprite.angle := angle and ANGLES;
      msprite.movemode := 4;
      msprite.basepic := msprite.startpic + 24;
      fheight := 40 * FRACUNIT;
      pangle := GetFireAngle(fheight, px, py, 0, 0, 0);
      SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, fheight, msprite.angle, pangle, true, 255);
      msprite.modetime := timecount + 8;
      msprite.actiontime := timecount + 30;
      msprite.firetime := timecount + 30;
    end
    else if CloneScanY(sx, sy, @py) > 1 then
    begin
      if py > sy then
        angle := SOUTH
      else if py < sy then
        angle := NORTH;
      msprite.angle := angle and ANGLES;
      msprite.movemode := 4;
      msprite.basepic := msprite.startpic + 24;
      fheight := 40 * FRACUNIT;
      pangle := GetFireAngle(fheight, px, py, 0, 0, 0);
      SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, fheight, msprite.angle, pangle, true, 255);
      msprite.modetime := timecount + 8;
      msprite.actiontime := timecount + 30;
      msprite.firetime := timecount + 30;
    end;
    msprite.scantime := timecount + 20;
  end;

  if timecount > msprite.modetime then
  begin
    msprite.modetime := timecount + 10;
    case msprite.movemode of
    0, // left
    1: // mid
      begin
        if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
        begin
          inc(msprite.movemode);
          msprite.basepic := msprite.startpic + msprite.movemode * 8;
          msprite.lasty := msprite.y;
          msprite.lastx := msprite.x;
        end;
      end;

    2: // right
      begin
        if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
        begin
          msprite.basepic := msprite.startpic + 8;
          inc(msprite.movemode);
          msprite.lasty := msprite.y;
          msprite.lastx := msprite.x;
        end;
      end;

    3: // mid #2
      begin
        if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
        begin
          msprite.movemode := 0;
          msprite.basepic := msprite.startpic;
          msprite.lasty := msprite.y;
          msprite.lastx := msprite.x;
        end;
      end;

    4: // fire
      begin
        msprite.movemode := 0;
        msprite.basepic := msprite.startpic;
      end;
    end;
  end;

  if (timecount > msprite.actiontime) and (SP_Thrust2 <> 1) then
  begin
    angle := msprite.angle + DEGREE45;
    msprite.angle := angle and ANGLES;
  end;

  floorz := RF_GetFloorZ(msprite.x, msprite.y);
  if floorz + msprite.zadj < msprite.z then
    msprite.z := msprite.z - 16 * FRACUNIT;
  if floorz + msprite.zadj > msprite.z then
    msprite.z := floorz + msprite.zadj;
end;

//***************************************************************************

// prisoners
procedure Int8;
var
  angle, sx, sy, px, py, tx, ty, pangle: integer;
  floorz, oldspeed, fheight: fixed_t;
label
  endscan,
  endscan2;
begin
  sx := msprite.x div FRACTILEUNIT;
  sy := msprite.y div FRACTILEUNIT;
  if netmode then
    NetGetClosestPlayer(sx, sy)
  else
  begin
    if specialeffect = SE_INVISIBILITY then
    begin
      targx := 0;
      targy := 0;
      targz := 0;
    end
    else
    begin
      targx := player.x;
      targy := player.y;
      targz := player.z;
    end;
  end;
  px := targx div FRACTILEUNIT;
  py := targy div FRACTILEUNIT;

  oldspeed := msprite.moveSpeed;
  if (absI(px - sx) < 6) and (absI(py - sy) < 6) then
    msprite.moveSpeed := msprite.moveSpeed * 2;

  if timecount > msprite.movetime then
  begin
    if px > sx then
      angle := EAST
    else if px < sx then
      angle := WEST
    else
      angle := -1;
    if py < sy then
    begin
      if angle = EAST then
        angle := angle + DEGREE45
      else if angle = WEST then
        angle := angle - DEGREE45
      else
        angle := NORTH;
    end
    else if py > sy then
    begin
      if angle = EAST then
        angle := angle - DEGREE45
      else if angle = WEST then
        angle := angle + DEGREE45
      else
        angle := SOUTH;
    end;
    angle := angle - DEGREE45 + MS_RndT;
    msprite.angle := angle and ANGLES;
    msprite.movetime := timecount + 350;
  end;

  if (timecount > msprite.firetime) and (timecount > msprite.scantime) then
  begin
    tx := px;
    ty := py;
    if (ScanX(7, sx, sy, px, py, @tx, @ty) > 1) or
       (ScanY(7, sx, sy, px, py, @tx, @ty) > 1) or
       (ScanAngle(7, sx, sy, px, py, @tx, @ty) > 1) then
    begin
      if tx > sx then
        angle := EAST
      else if tx < sx then
        angle := WEST
      else
        angle := -1;
      if ty < sy then
      begin
        if angle = EAST then
          angle := angle + DEGREE45
        else if angle = WEST then
          angle := angle - DEGREE45
        else
          angle := NORTH;
      end
      else if ty > sy then
      begin
        if angle = EAST then
          angle := angle - DEGREE45
        else if angle = WEST then
          angle := angle + DEGREE45
        else
          angle := SOUTH;
      end;
      msprite.angle := angle and ANGLES;

      if (absI(tx - sx) > 2) or (absI(ty - sy) > 2) then
      begin
        msprite.scantime := timecount + 45;
        goto endscan;
      end;

      msprite.basepic := msprite.startpic + 24;
      msprite.movemode := 4;
      msprite.firetime := timecount+(80 + 5 * player.difficulty);
      msprite.actiontime := timecount + 30;
      msprite.modetime := timecount + 15;
    end;
    msprite.scantime := timecount + 45;
  end;

endscan:
  if timecount > msprite.modetime then
  begin
    msprite.modetime := timecount + 10;
    case msprite.movemode of
    0, // left
    1: // mid
      begin
        if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
        begin
          inc(msprite.movemode);
          msprite.basepic := msprite.startpic + msprite.movemode * 8;
          msprite.lasty := msprite.y;
          msprite.lastx := msprite.x;
        end;
      end;

    2: // right
      begin
        if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
        begin
          msprite.basepic := msprite.startpic + 8; // midstep
          inc(msprite.movemode);
          msprite.lasty := msprite.y;
          msprite.lastx := msprite.x;
        end;
      end;

    3: // mid #2
      begin
        if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
        begin
          msprite.movemode := 0;
          msprite.basepic := msprite.startpic;
          msprite.lasty := msprite.y;
          msprite.lastx := msprite.x;
        end;
      end;

    4: // fire #1
      begin
        tx := px;
        ty := py;
        if (ScanX(7, sx, sy, px, py, @tx, @ty) > 1) or
           (ScanY(7, sx, sy, px, py, @tx, @ty) > 1) or
           (ScanAngle(7, sx, sy, px, py, @tx, @ty) > 1) then
        begin
          if tx > sx then
            angle := EAST
          else if tx < sx then
            angle := WEST
          else
            angle := -1;
          if ty < sy then
          begin
            if angle = EAST then
              angle := angle + DEGREE45
            else if angle = WEST then
              angle := angle - DEGREE45
            else
              angle := NORTH;
          end
          else if ty > sy then
          begin
            if angle = EAST then
              angle := angle - DEGREE45
            else if angle = WEST then
              angle := angle + DEGREE45
            else
              angle := SOUTH;
          end;

          msprite.angle := angle and ANGLES;

          if (absI(tx - sx) > 2) or (absI(ty - sy) > 2) then
          begin
            msprite.movemode := 0;
            msprite.basepic := msprite.startpic;
            goto endscan2;
          end;

          msprite.movemode := 5;
          msprite.basepic := msprite.startpic + 32;
          fheight := 40 * FRACUNIT;
          pangle := GetFireAngle(fheight, tx, ty, targx, targy, targz);
          SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, fheight, msprite.angle, pangle, true, 255);
          msprite.modetime := msprite.modetime + 8;
        end
        else
        begin
          msprite.movemode := 0;
          msprite.basepic := msprite.startpic;
        end;
      end;

    5: // fire #2
      begin
        msprite.movemode := 0;
        msprite.basepic := msprite.startpic;
        end;
      end;
    end;

endscan2:
  if (timecount > msprite.actiontime) and (SP_Thrust2 <> 1) then
  begin
    angle := msprite.angle + DEGREE45;
    msprite.angle := angle and ANGLES;
  end;
  floorz := RF_GetFloorZ(msprite.x, msprite.y);
  if floorz + msprite.zadj < msprite.z then
    msprite.z := msprite.z - 16 * FRACUNIT;
  if floorz + msprite.zadj > msprite.z then
    msprite.z := floorz + msprite.zadj;
  msprite.moveSpeed := oldspeed;
  if MS_RndT >= 255 then
    ActivationSound(msprite);
end;

//***************************************************************************

// big guards only
procedure Int9;
var
  i, angleinc, angle, sx, sy, px, py, tx, ty, pangle: integer;
  floorz, oldspeed, fheight: fixed_t;
begin
  if msprite.hitpoints < 1000 then
    msprite.hitpoints := msprite.hitpoints + 10;
  msprite.enraged := 0;
  sx := msprite.x div FRACTILEUNIT;
  sy := msprite.y div FRACTILEUNIT;
  if netmode then
    NetGetClosestPlayer(sx, sy)
  else
  begin
    if specialeffect = SE_INVISIBILITY then
    begin
      targx := 0;
      targy := 0;
      targz := 0;
    end
    else
    begin
      targx := player.x;
      targy := player.y;
      targz := player.z;
    end;
  end;
  px := targx div FRACTILEUNIT;
  py := targy div FRACTILEUNIT;

  oldspeed := msprite.moveSpeed;
  if (absI(px - sx) < 6) and (absI(py - sy) < 6) then
    msprite.moveSpeed := msprite.moveSpeed * 2;

  if timecount > msprite.movetime then
  begin
    if px > sx then
      angle := EAST
    else if px < sx then
      angle := WEST
    else
      angle := -1;
    if py < sy then
    begin
      if angle = EAST then
        angle := angle + DEGREE45
      else if angle = WEST then
        angle := angle - DEGREE45
      else
        angle := NORTH;
    end
    else if py > sy then
    begin
      if angle = EAST then
        angle := angle - DEGREE45
      else if angle = WEST then
        angle := angle + DEGREE45
      else
        angle := SOUTH;
    end;
    angle := angle - DEGREE45 + MS_RndT;
    msprite.angle := angle and ANGLES;
    msprite.movetime := timecount + 200;
  end;

  if (timecount > msprite.firetime) and (timecount > msprite.scantime) then
  begin
    SoundEffect(SN_MON11_WAKE, 7, msprite.x, msprite.y);
    tx := px;
    ty := py;
    if (ScanX(8, sx, sy, px, py, @tx, @ty) > 1) or
       (ScanY(8, sx, sy, px, py, @tx, @ty) > 1) or
       (ScanAngle(8, sx, sy, px, py, @tx, @ty) > 1) then
    begin
      if tx > sx then
        angle := EAST
      else if tx < sx then
        angle := WEST
      else angle := -1;
      if ty < sy then
      begin
        if angle = EAST then
          angle := angle + DEGREE45
        else if angle = WEST then
          angle := angle - DEGREE45
        else
          angle := NORTH;
      end
      else if ty > sy then
      begin
        if angle = EAST then
          angle := angle - DEGREE45
        else if angle = WEST then
          angle := angle + DEGREE45
        else
          angle := SOUTH;
      end;
      msprite.angle := angle and ANGLES;
      msprite.basepic := msprite.startpic + 24;
      msprite.movemode := 4;
      msprite.firetime := timecount + (120 + 5 * player.difficulty);
      msprite.actiontime := timecount + 30;
      msprite.modetime := timecount + 20;
    end;
    msprite.scantime := timecount + 45;
  end;

  if timecount > msprite.modetime then
  begin
    msprite.modetime := timecount + 20;
    case msprite.movemode of
    0, // left
    1: // mid
      begin
        if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
        begin
          inc(msprite.movemode);
          msprite.basepic := msprite.startpic + msprite.movemode * 8;
          msprite.lasty := msprite.y;
          msprite.lastx := msprite.x;
        end;
        if MS_RndT < 32 then
        begin
          angle := 0;
          angleinc := ANGLES div 16;
          for i := 0 to 15 do
          begin
            SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, 32 * FRACUNIT, angle, 0, true, 255);
            angle := angle + angleinc;
          end;
          SoundEffect(SN_MON11_FIRE, 7, msprite.x, msprite.y);
        end;
      end;

    2: // right
      begin
        if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
        begin
          msprite.basepic := msprite.startpic + 8; // midstep
          inc(msprite.movemode);
          msprite.lasty := msprite.y;
          msprite.lastx := msprite.x;
        end;
        if MS_RndT < 32 then
        begin
          angle := 0;
          angleinc := ANGLES div 16;
          for i := 0 to 15 do
          begin
            SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, 32 * FRACUNIT, angle, 0, true, 255);
            angle := angle + angleinc;
          end;
          SoundEffect(SN_MON11_FIRE, 7, msprite.x, msprite.y);
        end;
      end;

    3: // mid #2
      begin
        if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
        begin
          msprite.movemode := 0;
          msprite.basepic := msprite.startpic;
          msprite.lasty := msprite.y;
          msprite.lastx := msprite.x;
        end;
        if MS_RndT < 32 then
        begin
          angle := 0;
          angleinc := ANGLES div 16;
          for i := 0 to 15 do
          begin
            SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, 32 * FRACUNIT, angle, 0, true, 255);
            angle := angle + angleinc;
          end;
          SoundEffect(SN_MON11_FIRE, 7, msprite.x, msprite.y);
        end;
      end;

    4, // firing bullets
    5,
    6,
    7:
      begin
        tx := px;
        ty := py;
        if (ScanX(8, sx, sy, px, py, @tx, @ty) > 1) or
           (ScanY(8, sx, sy, px, py, @tx, @ty) > 1) or
           (ScanAngle(8, sx, sy, px, py, @tx, @ty) > 1) then
        begin
          if tx > sx then
            angle := EAST
          else if tx < sx then
            angle := WEST
          else
            angle := -1;
          if ty < sy then
          begin
            if angle = EAST then
              angle := angle + DEGREE45
            else if angle = WEST then
              angle := angle - DEGREE45
            else
              angle := NORTH;
          end
          else if ty > sy then
          begin
            if angle = EAST then
              angle := angle - DEGREE45
            else if angle = WEST then
              angle := angle + DEGREE45
            else
              angle := SOUTH;
          end;
          msprite.angle := angle and ANGLES;
          inc(msprite.movemode);
          msprite.basepic := msprite.startpic + 32;
          fheight := 70 * FRACUNIT;
          if (msprite.movemode = 5) and (MS_RndT < 32) then
          begin
            SpawnSprite(S_GRENADE, msprite.x, msprite.y, msprite.z, fheight, msprite.angle - 15 + (MS_RndT and 31), 0, true, 255);
            SpawnSprite(S_GRENADE, msprite.x, msprite.y, msprite.z, fheight, msprite.angle + 15 + (MS_RndT and 31), 0, true, 255);
            SoundEffect(SN_GRENADE, 0, msprite.x, msprite.y);
            msprite.movemode := 0;
            msprite.basepic := msprite.startpic;
            msprite.firetime := timecount + (120 + 5 * player.difficulty);
            msprite.actiontime := timecount + 30;
          end
          else
          begin
            pangle := GetFireAngle(fheight, tx, ty, targx, targy, targz) - 15 + (MS_RndT and 31);
            SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, fheight, msprite.angle - 15 + (MS_RndT and 31), pangle, true, 255);
            SoundEffect(SN_MON11_FIRE, 7, msprite.x, msprite.y);
            msprite.modetime := timecount + 15;
          end;
        end
        else
        begin
          msprite.movemode := 0;
          msprite.basepic := msprite.startpic;
          msprite.firetime := timecount + (120 + 5 * player.difficulty);
          msprite.actiontime := timecount + 30;
        end;
      end;

    8: // fire #2
      begin
        msprite.movemode := 0;
        msprite.basepic := msprite.startpic;
        msprite.firetime := timecount + (120 + 5 * player.difficulty);
        msprite.actiontime := timecount + 30;
      end;
    end;
  end;

  if (timecount > msprite.actiontime) and (SP_Thrust2 <> 1) then
  begin
    angle := msprite.angle + DEGREE45;
    msprite.angle := angle and ANGLES;
  end;
  floorz := RF_GetFloorZ(msprite.x, msprite.y);
  if floorz + msprite.zadj < msprite.z then
    msprite.z := msprite.z - 16 * FRACUNIT;
  if floorz + msprite.zadj > msprite.z then
    msprite.z := floorz + msprite.zadj;
  msprite.moveSpeed := oldspeed;
  if MS_RndT >= 255 then
    ActivationSound(msprite);
end;

(***************************************************************************)

procedure Int10;
var
  angle, sx, sy, px, py, tx, ty, pangle: integer;
  floorz, oldspeed, fheight: fixed_t;
label
  endscan;
begin
  if (msprite.typ = S_MONSTER5) and (msprite.hitpoints < 5000) then
    msprite.hitpoints := msprite.hitpoints + 4
  else if (msprite.typ = S_MONSTER13) and (msprite.hitpoints < 300) then
  begin
    msprite.hitpoints := msprite.hitpoints + 25;
    msprite.enraged := 0;
  end
  else if (msprite.typ = S_MONSTER15) and (msprite.hitpoints < 2000) then
  begin
    msprite.hitpoints := msprite.hitpoints + 6;
    msprite.enraged := 0;
  end
  else if (msprite.typ = S_MONSTER14) and (msprite.hitpoints < 350) then
    msprite.hitpoints := msprite.hitpoints + 1;
  sx := msprite.x div FRACTILEUNIT;
  sy := msprite.y div FRACTILEUNIT;
  if netmode then
    NetGetClosestPlayer(sx, sy)
  else
  begin
    if specialeffect = SE_INVISIBILITY then
    begin
      targx := 0;
      targy := 0;
      targz := 0;
    end
    else
    begin
      targx := player.x;
      targy := player.y;
      targz := player.z;
    end;
  end;
  px := targx div FRACTILEUNIT;
  py := targy div FRACTILEUNIT;

  oldspeed := msprite.moveSpeed;
  if (absI(px - sx) < 6) and (absI(py - sy) < 6) then
    msprite.moveSpeed := msprite.moveSpeed * 2;

  if timecount > msprite.movetime then
  begin
    if px > sx then
      angle := EAST
    else if px < sx then
      angle := WEST
    else
      angle := -1;
    if py < sy then
    begin
      if angle = EAST then
        angle := angle + DEGREE45
      else if angle = WEST then
        angle := angle - DEGREE45
      else
        angle := NORTH;
    end
    else if py > sy then
    begin
      if angle = EAST then
        angle := angle - DEGREE45
      else if angle = WEST then
        angle := angle + DEGREE45
      else
        angle := SOUTH;
    end;
    angle := angle - DEGREE45 + MS_RndT;
    msprite.angle := angle and ANGLES;
    msprite.movetime := timecount + 350;
  end;

  if (timecount > msprite.firetime) and (timecount > msprite.scantime) then
  begin
    tx := px;
    ty := py;
    if (ScanX(10, sx, sy, px, py, @tx, @ty) > 1) or
       (ScanY(10, sx, sy, px, py, @tx, @ty) > 1) or
       (ScanAngle(10, sx, sy, px, py, @tx, @ty) > 1) then
    begin
      if tx > sx then
        angle := EAST
      else if tx < sx then
        angle := WEST
      else
        angle := -1;
      if ty < sy then
      begin
        if angle = EAST then
          angle := angle + DEGREE45
        else if angle = WEST then
          angle := angle - DEGREE45
        else
          angle := NORTH;
      end
      else if ty > sy then
      begin
        if angle = EAST then
          angle := angle - DEGREE45
        else if angle = WEST then
          angle := angle + DEGREE45
        else
          angle := SOUTH;
      end;
      msprite.angle := angle and ANGLES;

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
        msprite.firetime := timecount + (10 + 3 * player.difficulty)
      else
        msprite.firetime := timecount + (40 + 5 * player.difficulty);

      msprite.actiontime := timecount + 30;
      msprite.modetime := timecount + 15;
      if msprite.typ = S_MONSTER3 then
        fheight := 3 * FRACUNIT
      else if msprite.typ = S_MONSTER6 then
        fheight := 100 * FRACUNIT
      else
        fheight := 40 * FRACUNIT;

      pangle := GetFireAngle(fheight, tx, ty, targx, targy, targz) - 15 + (MS_RndT and 31);
      if (msprite.typ = S_MONSTER13) or (msprite.typ = S_MONSTER6) or (msprite.typ = S_MONSTER15) or (msprite.typ = S_MONSTER5) then
      begin
        SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, fheight, msprite.angle - 15 + (MS_RndT and 31) + 16, pangle, true, 255);
        SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, fheight, msprite.angle - 15 + (MS_RndT and 31) - 16, pangle, true, 255);
        SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, fheight, msprite.angle - 15 + (MS_RndT and 31), pangle, true, 255);
      end
      else if msprite.typ = S_MONSTER4 then
      begin
        SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, fheight, msprite.angle - 15 + (MS_RndT and 31) + 8, pangle, true, 255);
        SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, fheight, msprite.angle - 15 + (MS_RndT and 31) - 8, pangle, true, 255);
      end
      else
        SpawnSprite(msprite.bullet, msprite.x, msprite.y, msprite.z, fheight, msprite.angle - 15 + (MS_RndT and 31), pangle, true, 255);
    end;
    msprite.scantime := timecount + 30;
  end;

endscan:
  if timecount > msprite.modetime then
  begin
    msprite.modetime := timecount + 8;
    case msprite.movemode of
    0, // 1
    1, // 2
    2: // 3
      begin
        if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
        begin
          inc(msprite.movemode);
          msprite.basepic := msprite.startpic + msprite.movemode * 8;
          msprite.lasty := msprite.y;
          msprite.lastx := msprite.x;
        end;
      end;

    3, // 2
    4: // 1
      begin
        if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
        begin
          inc(msprite.movemode);
          msprite.basepic := msprite.startpic + (6 - msprite.movemode) * 8;
          msprite.lasty := msprite.y;
          msprite.lastx := msprite.x;
        end;
      end;

    5:
      begin
        if (msprite.lastx <> msprite.x) or (msprite.lasty <> msprite.y) then
        begin
          msprite.movemode := 0;
          msprite.basepic := msprite.startpic;
          msprite.lasty := msprite.y;
          msprite.lastx := msprite.x;
        end;
      end;

    6: // fire
      begin
        msprite.movemode := 0;
        msprite.basepic := msprite.startpic;
      end;
    end;
  end;

  if (timecount > msprite.actiontime) and (SP_Thrust2 <> 1) then
  begin
    angle := msprite.angle + DEGREE45;
    msprite.angle := angle and ANGLES;
  end;
  floorz := RF_GetFloorZ(msprite.x, msprite.y) + msprite.zadj;
  if floorz < msprite.z then
    msprite.z := msprite.z - 16 * FRACUNIT;
  if floorz > msprite.z then
    msprite.z := floorz;
  msprite.moveSpeed := oldspeed;
  if MS_RndT >= 255 then
    ActivationSound(msprite);
end;


//**************************************************************************
procedure RecreateMapSprites;
var
  spr: Pscaleobj_t;
  typ: integer;
  i: integer;
  mapspot, x1, y1: integer;
begin
  for i := 0 to MAPROWS * MAPCOLS - 1 do
    if mapsprites[i] = 1 then
      mapsprites[i] := 0;
  spr := firstscaleobj.next;
  while spr <> @lastscaleobj do
  begin
    typ := spr.typ;
    if IsMonster(typ) then
    begin
      if (spr.deathevent = 0) and (spr.hitpoints <> 0) then
      begin
        x1 := spr.x div FRACTILEUNIT;
        y1 := spr.y div FRACTILEUNIT;
        mapspot := y1 * MAPCOLS + x1;
        mapsprites[mapspot] := 1;
      end;
    end;
    spr := spr.next;
  end;
end;

procedure MoveSprites;
var
  mapspot, i, j, c, px, py, sx, sy: integer;
  killed: boolean;
  floor: fixed_t;

  procedure _save_old;
  begin
    msprite.oldx := msprite.x;
    msprite.oldy := msprite.y;
    msprite.oldz := msprite.z;
    msprite.oldangle := msprite.angle;
    msprite.oldangle2 := msprite.angle2;
    msprite.oldfloorz := msprite.newfloorz;
    if not msprite.grounded then
      msprite.grounded := msprite.oldfloorz >= msprite.oldz;
  end;

  procedure _save_new;
  begin
    msprite.newx := msprite.x;
    msprite.newy := msprite.y;
    msprite.newz := msprite.z;
    msprite.newangle := msprite.angle;
    msprite.newangle2 := msprite.angle2;
    msprite.newfloorz := RF_GetFloorZ(msprite.x, msprite.y);
  end;

begin
  if not netmode then
  begin
    targx := player.x;
    targy := player.y;
    px := targx div FRACTILEUNIT;
    py := targy div FRACTILEUNIT;
  end;

  msprite := firstscaleobj.next;
  while msprite <> @lastscaleobj do
  begin
    _save_old;
    if msprite.active then
    begin
      if msprite.moveSpeed <> 0 then
      case msprite.intelligence of
      0:
        begin
          killed := Int0;
          if killed then
          begin
            if msprite.typ = S_BLOODSPLAT then
            begin
              msprite.intelligence := 128;
//              break;
            end
            else if (msprite.typ = S_METALPARTS) and not spritehit then
            begin
              killed := false;
              _save_new;
              msprite := msprite.next;
              continue;
            end;
            if msprite.typ <> S_BLOODSPLAT then
            begin
              _save_new;
              msprite := msprite.prev;
              RF_RemoveSprite(msprite.next);
              killed := false;
              msprite := msprite.next;
              continue;
            end;
          end;
        end;

      5:
        begin
          Int5;
        end;

      6:
        begin
          killed := Int6;
          if killed then
          begin
            _save_new;
            msprite := msprite.prev;
            RF_RemoveSprite(msprite.next);
            killed := false;
            msprite := msprite.next;
            continue;
          end;
        end;

      7:
        begin
          Int7;
        end;

      8:
        begin
          Int8;
        end;

      9:
        begin
          Int9;
        end;

      10:
        begin
          Int10;
        end;

      128:
        begin
          floor := RF_GetFloorZ(msprite.x, msprite.y);
          if msprite.z > floor + FRACUNIT then
            msprite.z := msprite.z - FRACUNIT * 2;
          if msprite.z < floor then
            msprite.z := floor;
        end;
      end;

      if not killed and (msprite.heat <> 0) then
      begin
        mapspot := (msprite.y div FRACTILEUNIT) * MAPCOLS + (msprite.x div FRACTILEUNIT);
        if msprite.heat > 256 then
        begin
          c := msprite.heat div 2;
          for i := -1 to 1 do
            for j := -1 to 1 do
              reallight[mapspot + (i * MAPCOLS) + j] := reallight[mapspot + (i * MAPCOLS) + j] - c;
          reallight[mapspot] := reallight[mapspot] - msprite.heat div 4;
        end
        else
          reallight[mapspot] := reallight[mapspot] - msprite.heat;
      end;
      killed := false;
    end
    else if msprite.intelligence <> 255 then
    begin
      if msprite.moveSpeed <> 0 then
      begin
        sx := msprite.x div FRACTILEUNIT;
        sy := msprite.y div FRACTILEUNIT;
        if netmode then
        begin
          NetGetClosestPlayer(sx, sy);
          px := targx div FRACTILEUNIT;
          py := targy div FRACTILEUNIT;
        end;

        if (absI(px - sx) < 6) and (absI(py - sy) < 6) then
        begin
          msprite.active := true;
          ActivateSprites(sx, sy);
        end;
      end;

      floor := RF_GetFloorZ(msprite.x, msprite.y) + msprite.zadj;
      if msprite.z > floor then
        msprite.z := msprite.z - 16 * FRACUNIT;
      if msprite.z < floor then
        msprite.z := floor;
      if msprite.heat <> 0 then
      begin
        mapspot := (msprite.y div FRACTILEUNIT) * MAPCOLS + (msprite.x div FRACTILEUNIT);
        if msprite.heat > 256 then
        begin
          c := msprite.heat div 2;
          for i := -1 to 1 do
            for j := -1 to 1 do
              reallight[mapspot + (i * MAPCOLS) + j] := reallight[mapspot + (i * MAPCOLS) + j] - c;
          reallight[mapspot] := reallight[mapspot] - msprite.heat div 4;
          msprite.heat := msprite.heat - 64;
        end
        else
          reallight[mapspot] := reallight[mapspot] - msprite.heat;
      end;
    end;
    _save_new;
    msprite := msprite.next;
  end;
  RecreateMapSprites;
end;

end.


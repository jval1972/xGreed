(***************************************************************************)
(*                                                                         *)
(* xGreed - Source port of the game "In Pursuit of Greed"                  *)
(* Copyright (C) 2020-2021 by Jim Valavanis                                *)
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

unit spawn;

interface

uses
  g_delphi,
  r_public_h;

procedure DemandLoadMonster(const lump, num: integer);

function SpawnSprite(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  angle, angle2: integer; const active: boolean; const spawnid: integer): Pscaleobj_t;

implementation

uses
  constant,
  d_disk,
  d_ints,
  d_misc,
  modplay,
  net,
  protos_h,
  raven,
  r_conten,
  r_refdef,
  r_render,
  r_public,
  utils;

const
  MAXMETALPARTS = 100;

procedure DemandLoadMonster(const lump, num: integer);
var
  i, j, l, count, top, bottom: integer;
  pic: Pscalepic_t;
  collumn: PByteArray;
begin
  if lumpcache[lump].data <> nil then
    exit; // already loaded
  for l := 0 to num - 1 do
  begin
    CA_CacheLump(lump + l);
    pic := lumpcache[lump + l].data;
    for i := 0 to pic.width - 1 do
      if pic.collumnofs[i] <> 0 then
      begin
        collumn := PByteArray(pic);
        collumn := @collumn[pic.collumnofs[i]];
        top := collumn[1];
        bottom := collumn[0];
        count := bottom - top + 1;
        collumn := @collumn[2];
        for j := 0 to count - 1 do
        begin
          if collumn[0] = 255 then
            collumn[0] := 0;
          collumn := @collumn[1];
        end;
      end;
  end;
end;

function SpawnSprite(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  angle, angle2: integer; const active: boolean; const spawnid: integer): Pscaleobj_t;
var
  sprite_p, s: Pscaleobj_t;
  door_p: Pdoorobj_t;
  elevator_p: Pelevobj_t;
  sa: Pspawnarea_t;
  x1, y1, mapspot, maxheight, i, j: integer;
begin
  sprite_p := nil;

  x1 := x div FRACTILEUNIT;
  y1 := y div FRACTILEUNIT;
  mapspot := y1 * MAPCOLS + x1;
  angle := angle and ANGLES;

  case value of
  S_BLOODSPLAT:
    begin
      if MS_RndT > 220 then
      begin
        sprite_p := RF_GetSprite;
        sprite_p.animation := 0 + (0 shl 1) + (5 shl 5) + ((2 + (MS_RndT and 7)) shl 9) + ANIM_SELFDEST;
        sprite_p.x := x + ((-3 + MS_RndT and 7) * FRACUNIT);
        sprite_p.y := y + ((-3 + MS_RndT and 7) * FRACUNIT);
        sprite_p.z := z + ((-3 + MS_RndT and 7) * FRACUNIT);
        sprite_p.basepic := slumps[S_WALLPUFF - S_START];
        sprite_p.active := true;
        sprite_p.heat := 100;
        sprite_p.active := true;
        sprite_p.typ := S_WALLPUFF;
        sprite_p.specialtype := st_transparent;
      end
      else if SC.violence then
      begin
        if bloodcount > MAXBLOODSPRITES then
        begin
          s := firstscaleobj.next;
          while s <> @lastscaleobj do
          begin
            if s.typ = S_BLOODSPLAT then
            begin
              RF_RemoveSprite(s);
              dec(bloodcount);
              break;
            end;
            s := s.next;
          end;
        end;
        inc(bloodcount);
        sprite_p := RF_GetSprite;
        sprite_p.x := x + ((-3 + MS_RndT and 7) * FRACUNIT);
        sprite_p.y := y + ((-3 + MS_RndT and 7) * FRACUNIT);
        sprite_p.z := z + ((7 + MS_RndT and 15) * FRACUNIT);
        sprite_p.zadj := zadj;
        sprite_p.active := true;
        sprite_p.angle := MS_RndT * 4;
        sprite_p.moveSpeed := 15 - (MS_RndT and 7);
        sprite_p.angle2 := (MS_RndT and 63) + 32;
        sprite_p.basepic := slumps[value - S_START] + (MS_RndT mod 10);
        sprite_p.typ := S_BLOODSPLAT;
        sprite_p.startspot := mapspot;
        sprite_p.movesize := FRACUNIT;
        sprite_p.scale := 1;
      end;
    end;

    (*
    if (not SC.violence) break;
    if bloodcount>200 then
    begin
      for (s := firstscaleobj.next; s <> @lastscaleobj;s := s.next)
       if s.typ = S_BLOODSPLAT then
       begin
   RF_RemoveSprite(s);
   break;
    end;
       end;
    bloodcount++;
    sprite_p := RF_GetSprite;
    sprite_p.x := x+((-3+MS_RndT) and (7) * FRACUNIT);
    sprite_p.y := y+((-3+MS_RndT) and (7) * FRACUNIT);
    sprite_p.z := z+((7+MS_RndT) and (15) * FRACUNIT);
    sprite_p.zadj := zadj;
    sprite_p.active := true;
    sprite_p.angle := MS_RndT*4;
    sprite_p.moveSpeed := 15-(MS_RndT) and (7);
    sprite_p.angle2 := (MS_RndT) and (63)+32;
    sprite_p.basepic := slumps[value-S_START]+(MS_RndT mod 10);
    sprite_p.typ := S_BLOODSPLAT;
    sprite_p.startspot := mapspot;
    sprite_p.movesize := FRACUNIT;
    sprite_p.scale := 1;
    break; *)
  (*  S_GREENBLOOD:
    if (not SC.violence) break;
    if bloodcount>100 then
    begin
      for (s := firstscaleobj.next; s <> @lastscaleobj;s := s.next)
       if s.typ = S_BLOODSPLAT then
       begin
   RF_RemoveSprite(s);
   break;
    end;
       end;
    bloodcount++;
    sprite_p := RF_GetSprite;
    sprite_p.x := x+((-3+MS_RndT) and (7) * FRACUNIT);
    sprite_p.y := y+((-3+MS_RndT) and (7) * FRACUNIT);
    sprite_p.z := z+((7+MS_RndT) and (15) * FRACUNIT);
    sprite_p.zadj := zadj;
    sprite_p.active := true;
    sprite_p.angle := MS_RndT*4;
    sprite_p.moveSpeed := 15-(MS_RndT) and (7);
    sprite_p.angle2 := (MS_RndT) and (63)+32;
    sprite_p.basepic := slumps[value-S_START]+(MS_RndT mod 10);
    sprite_p.typ := S_BLOODSPLAT;
    sprite_p.startspot := mapspot;
    sprite_p.movesize := FRACUNIT;
    break; *)

  (* ammo *)
  S_BULLET1: // autopistol
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 500;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 35;
      sprite_p.typ := value;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      if netmode and not gameloading then
        NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_BULLET2: // vulcan cannon
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 500;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 40;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 40;
      sprite_p.typ := value;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      if netmode and not gameloading then
        NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_BULLET3: // flamer
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 90;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 96;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 30;
      sprite_p.typ := value;
      sprite_p.angle2 := angle2;
      sprite_p.spawnid := spawnid;
      sprite_p.rotate := rt_eight;
      sprite_p.specialtype := st_noclip;
      if netmode and not gameloading then
        NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_BULLET4: // spread gun
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 100;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 4 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 112;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 50;
      sprite_p.typ := value;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      sprite_p.rotate := rt_eight;
      if netmode and not gameloading then
        NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_BULLET7: // psyborg #1
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 72;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 30;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 50;
      sprite_p.typ := value;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      sprite_p.maxmove := 2;
      if netmode and not gameloading then
        NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_BULLET9: // lizard #2
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 100;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 90;
      sprite_p.typ := value;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      sprite_p.rotate := rt_four;
      if netmode and not gameloading then
        NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_BULLET10: // specimen #2
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 50;
      sprite_p.angle := angle;
      sprite_p.animation := 1 + (0 shl 1) + (3 shl 5) + (5 shl 9);
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 3 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 500;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 35;
      sprite_p.typ := value;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      if netmode and not gameloading then
        NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_BULLET11: // mooman #2
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 500;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 10;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 50;
      sprite_p.typ := value;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      if netmode and not gameloading then
        NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_BULLET12: // dominatrix #2
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 100;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 2 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 300;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 45;
      sprite_p.typ := value;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      if netmode and not gameloading then
        NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_BULLET16: // red
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 100;
      sprite_p.angle := angle;
      sprite_p.animation := 1 + (0 shl 1) + (3 shl 5) + (5 shl 9);
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 3 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 30;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 30;
      sprite_p.typ := value;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      if netmode and not gameloading then
        NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_BULLET17: // blue gun
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 64;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 100;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 75;
      sprite_p.typ := S_BULLET17;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      sprite_p.scale := 1;
      sprite_p.rotate := rt_eight;
      if netmode and not gameloading then
       NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

(*    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 20;
    sprite_p.maxmove := 17;
    sprite_p.angle := angle;
    sprite_p.animation := 1 + (0 shl 1) + (3 shl 5) + (3 shl 9);
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z + zadj;
    sprite_p.basepic := slumps[value - S_START];
    sprite_p.movesize := 5 * FRACUNIT;
    sprite_p.active := true;
    sprite_p.heat := 5;
    sprite_p.damage := 1;
    sprite_p.startspot := mapspot;
    sprite_p.typ := value;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    sprite_p.specialtype := st_transparent;
    if netmode and not gameloading then
     NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    break; *)

  S_BULLET18: // green
    begin
      sprite_p := RF_GetSprite;
      sprite_p.animation := 1 + (0 shl 1) + (3 shl 5) + (5 shl 9);
      sprite_p.moveSpeed := 50;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 5 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 300;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 400;
      sprite_p.typ := value;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
    end;

  S_EXPLODE,
  S_SMALLEXPLODE:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.animation := 0 + (0 shl 1) + (4 shl 5) + ((2 + MS_RndT and 7) shl 9) + ANIM_SELFDEST;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := z;
      if MS_RndT and 1 <> 0 then
         sprite_p.basepic := slumps[S_EXPLODE - S_START]
      else
         sprite_p.basepic := slumps[S_EXPLODE2 - S_START];
      sprite_p.active := true;
      sprite_p.heat := 512;
      sprite_p.typ := S_EXPLODE;
      sprite_p.specialtype := st_noclip;
    end;

  S_WALLPUFF:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.animation := 0 + (0 shl 1) + (5 shl 5) + ((2 + MS_RndT and 7) shl 9) + ANIM_SELFDEST;
      sprite_p.x := x + (-3 + MS_RndT and 7) * FRACUNIT;
      sprite_p.y := y + (-3 + MS_RndT and 7) * FRACUNIT;
      sprite_p.z := z + (-3 + MS_RndT and 7) * FRACUNIT;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.active := true;
      sprite_p.heat := 100;
      sprite_p.active := true;
      sprite_p.typ := S_WALLPUFF;
      sprite_p.specialtype := st_transparent;
    end;

  S_GREENPUFF:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.animation := 0 + (0 shl 1) + (4 shl 5) + ((2 + MS_RndT and 7) shl 9) + ANIM_SELFDEST;
      sprite_p.x := x + ((-3 + MS_RndT and 7) * FRACUNIT);
      sprite_p.y := y + ((-3 + MS_RndT and 7) * FRACUNIT);
      sprite_p.z := z + ((-3 + MS_RndT and 7) * FRACUNIT);
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.active := true;
      sprite_p.heat := 150;
      sprite_p.active := true;
      sprite_p.typ := S_WALLPUFF;
      sprite_p.specialtype := st_transparent;
    end;

  S_PLASMAWALLPUFF:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.animation := 0 + (0 shl 1) + (4 shl 5) + ((5 + MS_RndT and 7) shl 9) + ANIM_SELFDEST;
      sprite_p.x := x + ((-3 + MS_RndT and 7) * FRACUNIT);
      sprite_p.y := y + ((-3 + MS_RndT and 7) * FRACUNIT);
      sprite_p.z := z + ((-3 + MS_RndT and 7) * FRACUNIT);
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.heat := 600;
      sprite_p.active := true;
      sprite_p.typ := S_PLASMAWALLPUFF;
      sprite_p.specialtype := st_transparent;
    end;

  S_ARROWPUFF:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.animation := 0 + (0 shl 1) + (4 shl 5) + ((3 + MS_RndT and 7) shl 9) + ANIM_SELFDEST;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := z;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.active := true;
      sprite_p.heat := 512;
      sprite_p.typ := S_EXPLODE;
      sprite_p.specialtype := st_noclip;
      SoundEffect(SN_EXPLODE1 + (MS_RndT and 1), 15, x, y);
    end;

  S_MONSTERBULLET1:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 500;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 40;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 60;
      sprite_p.typ := S_MONSTERBULLET1;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      SoundEffect(SN_MON1_FIRE, 7, x, y);
    end;

  S_MONSTERBULLET2:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 90;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 96;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 100;
      sprite_p.typ := S_MONSTERBULLET2;
      sprite_p.spawnid := spawnid;
      sprite_p.rotate := rt_eight;
      sprite_p.angle2 := angle2;
      SoundEffect(SN_MON2_FIRE, 7, x, y);
    end;

  S_MONSTERBULLET3:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 60;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 40;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 60;
      sprite_p.typ := S_MONSTERBULLET3;
      sprite_p.spawnid := spawnid;
      sprite_p.animation := 1 + (0 shl 1) + (3 shl 5) + (2 shl 9);
      sprite_p.angle2 := angle2;
      SoundEffect(SN_MON3_FIRE, 7, x, y);
    end;

  S_MONSTERBULLET4:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 80;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 40;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 75;
      sprite_p.typ := S_MONSTERBULLET4;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      sprite_p.scale := 1;
      sprite_p.rotate := rt_eight;
      SoundEffect(SN_MON4_FIRE, 7, x, y);
    end;

  S_MONSTERBULLET5:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 80;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 40;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 100;
      sprite_p.typ := S_MONSTERBULLET5;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      SoundEffect(SN_MON5_FIRE, 7, x, y);
    end;

  S_MONSTERBULLET6:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 70;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 100;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 150;
      sprite_p.typ := S_MONSTERBULLET6;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      sprite_p.scale := 2;
      sprite_p.rotate := rt_eight;
      SoundEffect(SN_MON6_FIRE, 7, x, y);
    end;

  S_MONSTERBULLET7:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.maxmove := 2;
      sprite_p.moveSpeed := 128;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 0;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 60;
      sprite_p.typ := S_MONSTERBULLET7;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      SoundEffect(SN_MON7_FIRE, 7, x, y);
    end;

  S_MONSTERBULLET8:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 90;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 96;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 100;
      sprite_p.typ := S_MONSTERBULLET8;
      sprite_p.angle2 := angle2;
      sprite_p.spawnid := spawnid;
      sprite_p.rotate := rt_eight;
      sprite_p.specialtype := st_noclip;
      SoundEffect(SN_MON8_FIRE, 7, x, y);
    end;

  S_MONSTERBULLET9:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 500;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 40;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 60;
      sprite_p.typ := S_MONSTERBULLET9;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      SoundEffect(SN_MON9_FIRE, 7, x, y);
    end;

  S_MONSTERBULLET10:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 128;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 20;
      sprite_p.maxmove := 2;
      sprite_p.typ := S_MONSTERBULLET10;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      SoundEffect(SN_MON10_FIRE, 7, x, y);
    end;

  S_MONSTERBULLET11:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 100;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 100;
      sprite_p.typ := S_MONSTERBULLET11;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      SoundEffect(SN_MON11_FIRE, 7, x, y);
    end;

  S_MONSTERBULLET12:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 70;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 40;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 40;
      sprite_p.typ := S_MONSTERBULLET12;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      SoundEffect(SN_MON12_FIRE, 7, x, y);
    end;

  S_MONSTERBULLET13:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 100;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 40;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 50;
      sprite_p.typ := S_MONSTERBULLET13;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      SoundEffect(SN_MON13_FIRE, 7, x, y);
    end;

  S_MONSTERBULLET14:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 100;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 40;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 100;
      sprite_p.typ := S_MONSTERBULLET14;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      SoundEffect(SN_MON14_FIRE, 7, x, y);
    end;

  S_MONSTERBULLET15:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.maxmove := 4;
      sprite_p.moveSpeed := 128;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 75;
      sprite_p.typ := S_MONSTERBULLET15;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      SoundEffect(SN_MON15_FIRE, 7, x, y);
    end;

  S_GRENADEBULLET:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 64;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[S_BULLET3-S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 96;
      sprite_p.startspot := -1;
      sprite_p.damage := 50;
      sprite_p.typ := value;
      if spawnid = playernum then
        sprite_p.spawnid := 200 + spawnid
      else
        sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
    end;

  S_MINEBULLET:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 128;
      sprite_p.maxmove := 2;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 8 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.heat := 112;
      sprite_p.startspot := -1;
      sprite_p.damage := 50;
      sprite_p.typ := value;
      if spawnid = playernum then
        sprite_p.spawnid := 200 + spawnid
      else
        sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
    end;

  S_HANDBULLET: // hand weapon attack
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 72;
      sprite_p.maxmove := 2;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.startspot := mapspot;
      sprite_p.damage := 100;
      sprite_p.typ := value;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      if netmode and not gameloading then
        NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_SOULBULLET: // soul stealer attack
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 72;
      sprite_p.maxmove := 4;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.movesize := 1 * FRACUNIT;
      sprite_p.active := true;
      sprite_p.startspot := -1;
      sprite_p.damage := 250;
      sprite_p.typ := value;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
    end;

  S_METALPARTS:
    begin
      if metalcount > MAXMETALPARTS then
      begin
        s := firstscaleobj.next;
        while s <> @lastscaleobj do
        begin
          if s.typ = S_METALPARTS then
          begin
            RF_RemoveSprite(s);
            break;
          end;
          s := s.next;
        end;
      end;
      inc(metalcount);
      sprite_p := RF_GetSprite;
      sprite_p.x := x +(-15 + MS_RndT and 31) * FRACUNIT;
      sprite_p.y := y +(-15 + MS_RndT and 31) * FRACUNIT;
      sprite_p.z := z +(-32 + MS_RndT and 63) * FRACUNIT;
      sprite_p.zadj := zadj;
      sprite_p.active := true;
      sprite_p.angle := MS_RndT * 4;
      sprite_p.moveSpeed := 10 + (MS_RndT and 15);
      sprite_p.angle2 := (MS_RndT and 63) + 32;
      sprite_p.basepic := CA_GetNamedNum('METALPARTS') + (MS_RndT and 3);
      sprite_p.typ := S_METALPARTS;
      sprite_p.startspot := mapspot;
      sprite_p.movesize := FRACUNIT;
      sprite_p.damage := 100;
    end;

  S_WARP:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.animation := 0 + (0 shl 1) + (8 shl 5) + (6 shl 9) + ANIM_SELFDEST;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.typ := value;
      sprite_p.specialtype := st_maxlight;
      SoundEffect(SN_WARP, 0, x, y);
    end;

  S_PROXMINE:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 1;
      sprite_p.active := true;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('proxmine');
      sprite_p.intelligence := 6;
      sprite_p.typ := S_PROXMINE;
      sprite_p.spawnid := spawnid;
      sprite_p.actiontime := timecount + 105;
      if netmode and not gameloading then
        NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_TIMEMINE:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 1;
      sprite_p.active := true;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('timemine');
      sprite_p.intelligence := 6;
      sprite_p.typ := S_TIMEMINE;
      sprite_p.spawnid := spawnid;
      sprite_p.actiontime := timecount + (2 * TICRATE);
      if netmode and not gameloading then
        NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_INSTAWALL:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 1;
      sprite_p.active := true;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.animation := 1 + (0 shl 1) + (4 shl 5) + (16 shl 9);
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('instaanim');
      sprite_p.intelligence := 6;
      sprite_p.typ := value;
      sprite_p.spawnid := spawnid;
      sprite_p.actiontime := timecount + (45 * TICRATE);
      sprite_p.specialtype := st_transparent;
      if netmode and not gameloading then
        NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
      mapsprites[mapspot] := 64;
    end;

  S_DECOY:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 1;
      sprite_p.active := true;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum(charnames[spawnid]);
      sprite_p.scale := 1;
      sprite_p.rotate := rt_eight;
      sprite_p.intelligence := 6;
      sprite_p.typ := S_PROXMINE;
      sprite_p.spawnid := spawnid;
      sprite_p.actiontime := timecount + (2 * TICRATE);
      if netmode and not gameloading then
        NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_CLONE:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 10 * FRACUNIT;
      sprite_p.angle := angle;
      sprite_p.active := active;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.rotate := rt_eight;
      sprite_p.basepic := CA_GetNamedNum(charnames[spawnid]);
      sprite_p.scale := 1;
      sprite_p.startpic := sprite_p.basepic;
      sprite_p.movesize := 24 * FRACUNIT;
      sprite_p.intelligence := 7;
      sprite_p.hitpoints := 700;
      sprite_p.typ := S_CLONE;
      sprite_p.height := 54 * FRACUNIT;
      sprite_p.bullet := S_MONSTERBULLET8;
      mapsprites[mapspot] := 1;
      if netmode and not gameloading then
       NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_GRENADE:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.moveSpeed := 50;
      sprite_p.angle := angle;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := zadj;
      sprite_p.z := z + zadj;
      sprite_p.basepic := CA_GetNamedNum('grenadeshot');
      sprite_p.movesize := 10 * FRACUNIT;
      sprite_p.hitpoints := 1;
      sprite_p.active := true;
      sprite_p.startspot := mapspot;
      sprite_p.typ := S_GRENADE;
      sprite_p.spawnid := spawnid;
      sprite_p.angle2 := angle2;
      sprite_p.rotate := rt_four;
      if netmode and not gameloading then
       NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_MINEPUFF:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.animation := 0 + (0 shl 1) + (4 shl 5) + ((5 + (MS_RndT and 7)) shl 9) + ANIM_SELFDEST;
      sprite_p.x := x + ((-3 + MS_RndT and 7) * FRACUNIT);
      sprite_p.y := y + ((-3 + MS_RndT and 7) * FRACUNIT);
      sprite_p.z := z + ((-3 + MS_RndT and 7) * FRACUNIT);
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.heat := 600;
      sprite_p.active := true;
      sprite_p.typ := S_MINEPUFF;
      sprite_p.specialtype := st_noclip;
    end;

  (* monsters ********************************************************)
  S_MONSTER1_NS, // kman
  S_MONSTER1:
    begin
      sprite_p := RF_GetSprite;
      if value = S_MONSTER1_NS then
        sprite_p.nofalling := true;
      sprite_p.moveSpeed := 4 * FRACUNIT;
      sprite_p.angle := angle;
      sprite_p.active := active;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.rotate := rt_eight;
      sprite_p.basepic := CA_GetNamedNum('kman');
      DemandLoadMonster(sprite_p.basepic, 56);
      sprite_p.startpic := sprite_p.basepic;
      sprite_p.movesize := 26 * FRACUNIT;
      sprite_p.intelligence := 10;
      sprite_p.heat := 8;
      sprite_p.hitpoints := 80;
      sprite_p.typ := S_MONSTER1;
      sprite_p.height := 59 * FRACUNIT;
      sprite_p.score := 160;
      sprite_p.bullet := S_MONSTERBULLET1;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 1;
    end;

  S_MONSTER2_NS, // kfem
  S_MONSTER2:
    begin
      sprite_p := RF_GetSprite;
      if value = S_MONSTER2_NS then
        sprite_p.nofalling := true;
      sprite_p.moveSpeed := 4 * FRACUNIT;
      sprite_p.angle := angle;
      sprite_p.active := active;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.rotate := rt_eight;
      sprite_p.basepic := CA_GetNamedNum('kfem');
      DemandLoadMonster(sprite_p.basepic, 56);
      sprite_p.startpic := sprite_p.basepic;
      sprite_p.movesize := 26 * FRACUNIT;
      sprite_p.intelligence := 10;
      sprite_p.heat := 8;
      sprite_p.hitpoints := 110;
      sprite_p.typ := S_MONSTER2;
      sprite_p.height := 59 * FRACUNIT;
      sprite_p.score := 220;
      sprite_p.bullet := S_MONSTERBULLET2;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 1;
    end;

  S_MONSTER3_NS, // kprob
  S_MONSTER3:
    begin
      sprite_p := RF_GetSprite;
      if value = S_MONSTER3_NS then
        sprite_p.nofalling := true;
      sprite_p.moveSpeed := 7 * FRACUNIT;
      sprite_p.angle := angle;
      sprite_p.active := active;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := 25 * FRACUNIT;
      sprite_p.z := RF_GetFloorZ(x, y) + sprite_p.zadj;
      sprite_p.rotate := rt_eight;
      sprite_p.basepic := CA_GetNamedNum('kprob');
      DemandLoadMonster(sprite_p.basepic, 56);
      sprite_p.startpic := sprite_p.basepic;
      sprite_p.movesize := 26 * FRACUNIT;
      sprite_p.intelligence := 10;
      sprite_p.hitpoints := 150;
      sprite_p.typ := S_MONSTER3;
      sprite_p.height := 20 * FRACUNIT;
      sprite_p.score := 300;
      sprite_p.bullet := S_MONSTERBULLET3;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 1;
    end;

  S_MONSTER4_NS, // kbot
  S_MONSTER4:
    begin
      sprite_p := RF_GetSprite;
      if value = S_MONSTER4_NS then
        sprite_p.nofalling := true;
      sprite_p.moveSpeed := 4 * FRACUNIT;
      sprite_p.angle := angle;
      sprite_p.active := active;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.rotate := rt_eight;
      sprite_p.basepic := CA_GetNamedNum('kbot');
      DemandLoadMonster(sprite_p.basepic, 48);
      sprite_p.startpic := sprite_p.basepic;
      sprite_p.movesize := 26 * FRACUNIT;
      sprite_p.intelligence := 10;
      sprite_p.hitpoints := 350;
      sprite_p.typ := S_MONSTER4;
      sprite_p.height := 45 * FRACUNIT;
      sprite_p.score := 700;
      sprite_p.bullet := S_MONSTERBULLET4;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 1;
    end;

  S_MONSTER5_NS, // kboss
  S_MONSTER5:
    begin
      sprite_p := RF_GetSprite;
      if value = S_MONSTER5_NS then
        sprite_p.nofalling := true;
      sprite_p.moveSpeed := 6 * FRACUNIT;
      sprite_p.angle := angle;
      sprite_p.active := active;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.rotate := rt_eight;
      sprite_p.basepic := CA_GetNamedNum('kboss');
      DemandLoadMonster(sprite_p.basepic, 48);
      sprite_p.startpic := sprite_p.basepic;
      sprite_p.movesize := 49 * FRACUNIT;
      sprite_p.intelligence := 10;
      sprite_p.hitpoints := 10000;
      sprite_p.typ := S_MONSTER5;
      sprite_p.height := 59 * FRACUNIT;
      sprite_p.score := 30000;
      sprite_p.bullet := S_MONSTERBULLET5;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 1;
    end;

  S_MONSTER6_NS, // pboss
  S_MONSTER6:
    begin
      sprite_p := RF_GetSprite;
      if value = S_MONSTER6_NS then
        sprite_p.nofalling := true;
      sprite_p.moveSpeed := 7 * FRACUNIT;
      sprite_p.angle := angle;
      sprite_p.active := active;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.rotate := rt_eight;
      sprite_p.basepic := CA_GetNamedNum('pboss');
      DemandLoadMonster(sprite_p.basepic, 56);
      sprite_p.startpic := sprite_p.basepic;
      sprite_p.movesize := 26 * FRACUNIT;
      sprite_p.intelligence := 10;
      sprite_p.heat := 8;
      sprite_p.hitpoints := 5000;
      sprite_p.typ := S_MONSTER6;
      sprite_p.height := 120 * FRACUNIT;
      sprite_p.score := 15000;
      sprite_p.bullet := S_MONSTERBULLET6;
      mapsprites[mapspot] := 1;
    end;

  S_MONSTER7_NS, // pst
  S_MONSTER7:
    begin
      sprite_p := RF_GetSprite;
      if value = S_MONSTER7_NS then
        sprite_p.nofalling := true;
      sprite_p.moveSpeed := 4 * FRACUNIT;
      sprite_p.angle := angle;
      sprite_p.active := active;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.rotate := rt_eight;
      sprite_p.basepic := CA_GetNamedNum('pst');
      DemandLoadMonster(sprite_p.basepic, 56);
      sprite_p.startpic := sprite_p.basepic;
      sprite_p.movesize := 26 * FRACUNIT;
      sprite_p.intelligence := 10;
      sprite_p.heat := 8;
      sprite_p.hitpoints := 150;
      sprite_p.typ := S_MONSTER7;
      sprite_p.height := 59 * FRACUNIT;
      sprite_p.score := 300;
      sprite_p.bullet := S_MONSTERBULLET7;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 1;
    end;

  S_MONSTER8_NS, // guard
  S_MONSTER8:
    begin
      sprite_p := RF_GetSprite;
      if value = S_MONSTER8_NS then
        sprite_p.nofalling := true;
      sprite_p.moveSpeed := 4 * FRACUNIT;
      sprite_p.angle := angle;
      sprite_p.active := active;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.rotate := rt_eight;
      sprite_p.basepic := CA_GetNamedNum('guard');
      DemandLoadMonster(sprite_p.basepic, 56);
      sprite_p.startpic := sprite_p.basepic;
      sprite_p.movesize := 26 * FRACUNIT;
      sprite_p.intelligence := 5;
      sprite_p.hitpoints := 350;
      sprite_p.typ := S_MONSTER8;
      sprite_p.height := 59 * FRACUNIT;
      sprite_p.score := 700;
      sprite_p.bullet := S_MONSTERBULLET8;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 1;
    end;

  S_MONSTER9_NS,  // trooper
  S_MONSTER9:
    begin
      sprite_p := RF_GetSprite;
      if value = S_MONSTER9_NS then
        sprite_p.nofalling := true;
      sprite_p.moveSpeed := 4 * FRACUNIT;
      sprite_p.angle := angle;
      sprite_p.active := active;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.rotate := rt_eight;
      sprite_p.basepic := CA_GetNamedNum('trooper');
      DemandLoadMonster(sprite_p.basepic, 56);
      sprite_p.startpic := sprite_p.basepic;
      sprite_p.movesize := 26 * FRACUNIT;
      sprite_p.intelligence := 5;
      sprite_p.heat := 24;
      sprite_p.hitpoints := 80;
      sprite_p.typ := S_MONSTER9;
      sprite_p.height := 59 * FRACUNIT;
      sprite_p.score := 160;
      sprite_p.bullet := S_MONSTERBULLET9;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 1;
    end;

  S_MONSTER10_NS,  // prisoner
  S_MONSTER10:
    begin
      sprite_p := RF_GetSprite;
      if value = S_MONSTER10_NS then
         sprite_p.nofalling := true;
      sprite_p.moveSpeed := 4 * FRACUNIT;
      sprite_p.angle := angle;
      sprite_p.active := active;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.rotate := rt_eight;
      sprite_p.basepic := CA_GetNamedNum('prisoner');
      DemandLoadMonster(sprite_p.basepic, 56);
      sprite_p.startpic := sprite_p.basepic;
      sprite_p.movesize := 26 * FRACUNIT;
      sprite_p.intelligence := 8;
      sprite_p.heat := 16;
      sprite_p.hitpoints := 20;
      sprite_p.typ := S_MONSTER10;
      sprite_p.height := 59 * FRACUNIT;
      sprite_p.score := 40;
      sprite_p.bullet := S_MONSTERBULLET10;
      sprite_p.scale := 1;
      sprite_p.enraged := 10;
      mapsprites[mapspot] := 1;
    end;

  S_MONSTER11_NS, // big guard
  S_MONSTER11:
    begin
      sprite_p := RF_GetSprite;
      if value = S_MONSTER11_NS then
        sprite_p.nofalling := true;
      sprite_p.moveSpeed := 3 * FRACUNIT;
      sprite_p.angle := angle;
      sprite_p.active := active;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.rotate := rt_eight;
      sprite_p.basepic := CA_GetNamedNum('bigguard');
      DemandLoadMonster(sprite_p.basepic, 48);
      sprite_p.startpic := sprite_p.basepic;
      sprite_p.movesize := 31 * FRACUNIT;
      sprite_p.intelligence := 9;
      sprite_p.heat := 300;
      sprite_p.hitpoints := 1200;
      sprite_p.score := 10000;
      sprite_p.typ := S_MONSTER11;
      sprite_p.height := 128 * FRACUNIT;
      sprite_p.bullet := S_MONSTERBULLET11;
      sprite_p.deathevent := 255;
      mapsprites[mapspot] := 1;
    end;

  S_MONSTER12_NS, // pss
  S_MONSTER12:
    begin
      sprite_p := RF_GetSprite;
      if value = S_MONSTER12_NS then
        sprite_p.nofalling := true;
      sprite_p.moveSpeed := 4 * FRACUNIT;
      sprite_p.angle := angle;
      sprite_p.active := active;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.rotate := rt_eight;
      sprite_p.basepic := CA_GetNamedNum('pss');
      DemandLoadMonster(sprite_p.basepic, 56);
      sprite_p.startpic := sprite_p.basepic;
      sprite_p.movesize := 26 * FRACUNIT;
      sprite_p.intelligence := 10;
      sprite_p.heat := 8;
      sprite_p.hitpoints := 90;
      sprite_p.typ := S_MONSTER12;
      sprite_p.height := 59 * FRACUNIT;
      sprite_p.score := 180;
      sprite_p.bullet := S_MONSTERBULLET12;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 1;
    end;

  S_MONSTER13_NS, // kwiz
  S_MONSTER13:
    begin
      sprite_p := RF_GetSprite;
      if value = S_MONSTER13_NS then
        sprite_p.nofalling := true;
      sprite_p.moveSpeed := 4 * FRACUNIT;
      sprite_p.angle := angle;
      sprite_p.active := active;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.rotate := rt_eight;
      sprite_p.basepic := CA_GetNamedNum('wiz');
      DemandLoadMonster(sprite_p.basepic, 56);
      sprite_p.startpic := sprite_p.basepic;
      sprite_p.movesize := 26 * FRACUNIT;
      sprite_p.intelligence := 10;
      sprite_p.heat := 8;
      sprite_p.hitpoints := 300;
      sprite_p.typ := S_MONSTER13;
      sprite_p.height := 59 * FRACUNIT;
      sprite_p.score := 600;
      sprite_p.bullet := S_MONSTERBULLET13;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 1;
    end;

  S_MONSTER14_NS, // veek
  S_MONSTER14:
    begin
      sprite_p := RF_GetSprite;
      if value = S_MONSTER14_NS then
        sprite_p.nofalling := true;
      sprite_p.moveSpeed := 4 * FRACUNIT;
      sprite_p.angle := angle;
      sprite_p.active := active;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.rotate := rt_eight;
      sprite_p.basepic := CA_GetNamedNum('veek');
      DemandLoadMonster(sprite_p.basepic, 56);
      sprite_p.startpic := sprite_p.basepic;
      sprite_p.movesize := 26 * FRACUNIT;
      sprite_p.intelligence := 10;
      sprite_p.heat := 8;
      sprite_p.hitpoints := 350;
      sprite_p.typ := S_MONSTER14;
      sprite_p.height := 59 * FRACUNIT;
      sprite_p.score := 700;
      sprite_p.bullet := S_MONSTERBULLET14;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 1;
    end;

  S_MONSTER15_NS, // tboss
  S_MONSTER15:
    begin
      sprite_p := RF_GetSprite;
      if value = S_MONSTER15_NS then
        sprite_p.nofalling := true;
      sprite_p.moveSpeed := 7 * FRACUNIT;
      sprite_p.angle := angle;
      sprite_p.active := active;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.rotate := rt_eight;
      sprite_p.basepic := CA_GetNamedNum('tboss');
      DemandLoadMonster(sprite_p.basepic, 56);
      sprite_p.startpic := sprite_p.basepic;
      sprite_p.movesize := 26 * FRACUNIT;
      sprite_p.intelligence := 10;
      sprite_p.heat := 8;
      sprite_p.hitpoints := 3000;
      sprite_p.typ := S_MONSTER15;
      sprite_p.height := 59 * FRACUNIT;
      sprite_p.score := 15000;
      sprite_p.bullet := S_MONSTERBULLET15;
      mapsprites[mapspot] := 1;
    end;


  (* bonus item *********************************************************)
  S_BONUSITEM:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.angle := angle;
      sprite_p.active := false;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('randitem');
      sprite_p.typ := S_BONUSITEM;
      mapsprites[mapspot] := SM_BONUSITEM;
    end;


  (* items **************************************************************)
  S_ITEM2,
  S_ITEM3:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := RF_GetCeilingZ(x, y) - (20 * FRACUNIT) - RF_GetFloorZ(x, y);
      sprite_p.z := RF_GetFloorZ(x, y) + sprite_p.zadj;
      sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := value;
      mapsprites[mapspot] := 0;
    end;

  S_ITEM8:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := RF_GetCeilingZ(x, y) - (39 * FRACUNIT) - RF_GetFloorZ(x, y);
      sprite_p.z := RF_GetFloorZ(x, y) + sprite_p.zadj;
      sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := value;
      mapsprites[mapspot] := 0;
    end;

  S_ITEM10:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := RF_GetCeilingZ(x, y) - (33 * FRACUNIT) - RF_GetFloorZ(x, y);
      sprite_p.z := RF_GetFloorZ(x, y) + sprite_p.zadj;
      sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := value;
      mapsprites[mapspot] := 0;
    end;

  S_ITEM11:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := RF_GetCeilingZ(x, y) - (73 * FRACUNIT) - RF_GetFloorZ(x, y);
      sprite_p.z := RF_GetFloorZ(x, y) + sprite_p.zadj;
      sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := value;
      mapsprites[mapspot] := 0;
    end;

  S_ITEM12:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := RF_GetCeilingZ(x, y) - (35 * FRACUNIT) - RF_GetFloorZ(x, y);
      sprite_p.z := RF_GetFloorZ(x, y) + sprite_p.zadj;
      sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := value;
      mapsprites[mapspot] := 0;
    end;

  S_ITEM13:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := RF_GetCeilingZ(x, y) - (65 * FRACUNIT) - RF_GetFloorZ(x, y);
      sprite_p.z := RF_GetFloorZ(x, y) + sprite_p.zadj;
      sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := value;
      mapsprites[mapspot] := 0;
    end;

  S_ITEM20:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := RF_GetCeilingZ(x, y) - (91 * FRACUNIT) - RF_GetFloorZ(x, y);
      sprite_p.z := RF_GetFloorZ(x, y) + sprite_p.zadj;
      sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := value;
      mapsprites[mapspot] := 0;
    end;

  S_ITEM23:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := RF_GetCeilingZ(x, y) - (121 * FRACUNIT) - RF_GetFloorZ(x, y);
      sprite_p.z := RF_GetFloorZ(x, y) + sprite_p.zadj;
      sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := value;
      mapsprites[mapspot] := 0;
    end;

  S_ITEM30:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := RF_GetCeilingZ(x, y) - (40 * FRACUNIT) - RF_GetFloorZ(x, y);
      sprite_p.z := RF_GetFloorZ(x, y) + sprite_p.zadj;
      sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := value;
      mapsprites[mapspot] := 0;
    end;

  S_ITEM31:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := RF_GetCeilingZ(x, y) - (39 * FRACUNIT) - RF_GetFloorZ(x, y);
      sprite_p.z := RF_GetFloorZ(x, y) + sprite_p.zadj;
      sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := value;
      mapsprites[mapspot] := 0;
    end;

  S_ITEM32:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := RF_GetCeilingZ(x, y) - (36 * FRACUNIT) - RF_GetFloorZ(x, y);
      sprite_p.z := RF_GetFloorZ(x, y) + sprite_p.zadj;
      sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := value;
      mapsprites[mapspot] := 0;
    end;

  S_ITEM33:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := RF_GetCeilingZ(x, y) - (51 * FRACUNIT) - RF_GetFloorZ(x, y);
      sprite_p.z := RF_GetFloorZ(x, y) + sprite_p.zadj;
      sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := value;
      mapsprites[mapspot] := 0;
    end;

  S_ITEM34:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.zadj := RF_GetCeilingZ(x, y) - (49 * FRACUNIT) - RF_GetFloorZ(x, y);
      sprite_p.z := RF_GetFloorZ(x, y) + sprite_p.zadj;
      sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := value;
      mapsprites[mapspot] := 0;
    end;

  S_ITEM1,
  S_ITEM4,
  S_ITEM5,
  S_ITEM6,
  S_ITEM7,
  S_ITEM9,
  S_ITEM14,
  S_ITEM15,
  S_ITEM16,
  S_ITEM17,
  S_ITEM18,
  S_ITEM19,
  S_ITEM21,
  S_ITEM22,
  S_ITEM24,
  S_ITEM25,
  S_ITEM26,
  S_ITEM27,
  S_ITEM28,
  S_ITEM29:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := value;
      sprite_p.height := 48 * FRACUNIT;
      mapsprites[mapspot] := 2;
    end;

  S_WEAPON0,
  S_WEAPON1,
  S_WEAPON2,
  S_WEAPON3,
  S_WEAPON4,
  S_WEAPON5,
  S_WEAPON6,
  S_WEAPON7,
  S_WEAPON8,
  S_WEAPON9,
  S_WEAPON10,
  S_WEAPON11,
  S_WEAPON12,
  S_WEAPON13,
  S_WEAPON14,
  S_WEAPON15,
  S_WEAPON16,
  S_WEAPON17,
  S_WEAPON18:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('weapons') + value - S_WEAPON0;
      sprite_p.typ := value;
      mapsprites[mapspot] := value - S_WEAPON0 + SM_WEAPON0;
    end;

  S_MEDPAK1,
  S_MEDPAK2,
  S_MEDPAK3,
  S_MEDPAK4,
  S_ENERGY,
  S_BALLISTIC,
  S_PLASMA,
  S_SHIELD1,
  S_SHIELD2,
  S_SHIELD3,
  S_SHIELD4,
  S_IPROXMINE,
  S_ITIMEMINE,
  S_IREVERSO,
  S_IGRENADE,
  S_IDECOY,
  S_IINSTAWALL,
  S_ICLONE,
  S_IHOLO,
  S_IINVIS,
  S_IJAMMER,
  S_ISTEALER:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('medtube1') + (value - S_MEDPAK1) * 4;
      sprite_p.typ := value;
      sprite_p.animation := 1 + (0 shl 1) + (4 shl 5) + (10 shl 9);
      mapsprites[mapspot] := (value - S_MEDPAK1) + SM_MEDPAK1;
      if netmode and not gameloading then
        NetSendSpawn(value, x, y, z, zadj, angle, angle2, active, spawnid);
    end;

  S_AMMOBOX:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('ammobox');
      sprite_p.typ := S_AMMOBOX;
      mapsprites[mapspot] := SM_AMMOBOX;
    end;

  S_MEDBOX:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('autodoc');
      sprite_p.typ := S_MEDBOX;
      mapsprites[mapspot] := SM_MEDBOX;
    end;

  S_GOODIEBOX:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('toolchest');
      sprite_p.typ := S_GOODIEBOX;
      mapsprites[mapspot] := SM_GOODIEBOX;
    end;

  S_GENERATOR:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := slumps[value - S_START];
      sprite_p.typ := value;
      sprite_p.animation := 1 + (0 shl 1) + (4 shl 5) + (10 shl 9);
    end;

  S_DEADMONSTER1:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('kman') + 55;
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := S_DEADMONSTER1;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 0;
    end;

  S_DEADMONSTER2:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('kfem') + 55;
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := S_DEADMONSTER2;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 0;
    end;

  S_DEADMONSTER3:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('kprob') + 55;
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := S_DEADMONSTER3;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 0;
    end;

  S_DEADMONSTER4:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('kbot') + 55;
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := S_DEADMONSTER4;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 0;
    end;

  S_DEADMONSTER5:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('kboss') + 55;
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := S_DEADMONSTER5;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 0;
    end;

  S_DEADMONSTER6:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('pboss') + 55;
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := S_DEADMONSTER6;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 0;
    end;

  S_DEADMONSTER7:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('pst') + 55;
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := S_DEADMONSTER7;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 0;
    end;

  S_DEADMONSTER8:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('guard') + 55;
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := S_DEADMONSTER8;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 0;
    end;

  S_DEADMONSTER9:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('trooper') + 55;
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := S_DEADMONSTER9;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 0;
    end;

  S_DEADMONSTER10:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('prisoner') + 55;
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := S_DEADMONSTER10;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 0;
    end;

  S_DEADMONSTER11:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('bigguard') + 55;
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := S_DEADMONSTER11;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 0;
    end;

  S_DEADMONSTER12:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('pss') + 55;
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := S_DEADMONSTER12;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 0;
    end;

  S_DEADMONSTER13:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('wiz') + 55;
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := S_DEADMONSTER13;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 0;
    end;

  S_DEADMONSTER14:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('veek') + 55;
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := S_DEADMONSTER14;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 0;
    end;

  S_DEADMONSTER15:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('tboss') + 55;
      DemandLoadMonster(sprite_p.basepic, 1);
      sprite_p.typ := S_DEADMONSTER15;
      sprite_p.scale := 1;
      mapsprites[mapspot] := 0;
    end;

  (* primary/secondary ****************************************************)
  S_PRIMARY1,
  S_PRIMARY2:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('primary') + primaries[(value - S_PRIMARY1) * 2];
      sprite_p.typ := value;
      mapsprites[mapspot] := (value - S_PRIMARY1) + SM_PRIMARY1;
      sprite_p.score := primaries[(value - S_PRIMARY1) * 2 + 1];
    end;

  S_SECONDARY1,
  S_SECONDARY2,
  S_SECONDARY3,
  S_SECONDARY4,
  S_SECONDARY5,
  S_SECONDARY6,
  S_SECONDARY7:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('secondary') + secondaries[(value - S_SECONDARY1) * 2];
      sprite_p.typ := value;
      mapsprites[mapspot] := (value - S_SECONDARY1) + SM_SECONDARY1;
      sprite_p.score := secondaries[(value - S_SECONDARY1) * 2 + 1];
    end;

  (* players **************************************************************)
  S_PLAYER: // player
    begin
      startlocations[0][0] := x1;
      startlocations[0][1] := y1;
      if (player.x = -1) and ((netmode and (greedcom.consoleplayer = 0)) or not netmode) then
      begin
        player.x := x;
        player.y := y;
        player.z := RF_GetFloorZ(player.x, player.y) + player.height;
        player.mapspot := mapspot;
        player.angle := NORTH;
        player_angle64 := NORTH * 64;
      end;
      mapsprites[mapspot] := 0;
    end;

  S_NETPLAYER2,
  S_NETPLAYER3,
  S_NETPLAYER4,
  S_NETPLAYER5,
  S_NETPLAYER6,
  S_NETPLAYER7,
  S_NETPLAYER8:
    begin
      if (floorpic[mapspot] = 0) or (ceilingpic[mapspot] = 0) then
        MS_Error('Invalid start %d at %d,%d', [value, x1, y1]);
      startlocations[value - 1][0] := x1;
      startlocations[value - 1][1] := y1;
      if netmode and (greedcom.consoleplayer = value - 1) and (player.x = -1) then
      begin
        player.x := x;
        player.y := y;
        player.z := RF_GetFloorZ(player.x, player.y) + player.height;
        player.mapspot := mapspot;
        player.angle := NORTH;
        player_angle64 := NORTH * 64;
      end;
      mapsprites[mapspot] := 0;
    end;

  (* doors *************************************************************)
  S_VDOOR1: // vertical door 1
    begin
      door_p := RF_GetDoor(x1, y1);
      if mapflags[mapspot - MAPCOLS] and FL_DOOR <> 0 then
         door_p.orientation := dr_vertical2
      else
         door_p.orientation := dr_vertical;
      door_p.doorBumpable := true;
      door_p.doorSize := 64 * FRACUNIT;
      door_p.position := door_p.doorSize;
      door_p.pic := CA_GetNamedNum('door_1') - walllump;
      door_p.doorTimer := player.timecount;
      mapsprites[mapspot] := 0;
    end;

  S_HDOOR1: // horizontal door 1
    begin
      door_p := RF_GetDoor(x1, y1);
      if mapflags[mapspot - 1] and FL_DOOR <> 0 then
        door_p.orientation := dr_horizontal2
      else
        door_p.orientation := dr_horizontal;
      door_p.doorBumpable := true;
      door_p.doorSize := 64 * FRACUNIT;
      door_p.position := door_p.doorSize;
      door_p.doorTimer := player.timecount;
      door_p.pic := CA_GetNamedNum('door_1') - walllump;
      mapsprites[mapspot] := 0;
    end;

  S_VDOOR2: // vertical door 2
    begin
      door_p := RF_GetDoor(x1, y1);
      if mapflags[mapspot - MAPCOLS] and FL_DOOR <> 0 then
        door_p.orientation := dr_vertical2
      else
        door_p.orientation := dr_vertical;
      door_p.doorBumpable := true;
      door_p.doorSize := 64 * FRACUNIT;
      door_p.position := door_p.doorSize;
    //   door_p.transparent := true;
      door_p.doorTimer := player.timecount;
      door_p.pic := CA_GetNamedNum('door_2') - walllump;
      mapsprites[mapspot] := 0;
    end;

  S_HDOOR2: // horizontal door 2
    begin
      door_p := RF_GetDoor(x1, y1);
      if mapflags[mapspot - 1] and FL_DOOR <> 0 then
        door_p.orientation := dr_horizontal2
      else
        door_p.orientation := dr_horizontal;
      door_p.doorBumpable := true;
      door_p.doorSize := 64 * FRACUNIT;
      door_p.position := door_p.doorSize;
    //   door_p.transparent := true;
      door_p.doorTimer := player.timecount;
      door_p.pic := CA_GetNamedNum('door_2') - walllump;
      mapsprites[mapspot] := 0;
    end;

  S_VDOOR3: // vertical door 3
    begin
      door_p := RF_GetDoor(x1, y1);
      if mapflags[mapspot - MAPCOLS] and FL_DOOR <> 0 then
        door_p.orientation := dr_vertical2
      else
        door_p.orientation := dr_vertical;
      door_p.doorBumpable := true;
      door_p.doorSize := 64 * FRACUNIT;
      door_p.position := door_p.doorSize;
      door_p.doorTimer := player.timecount;
      door_p.pic := CA_GetNamedNum('door_3') - walllump;
      mapsprites[mapspot] := 0;
    end;

  S_HDOOR3: // horizontal door 3
    begin
      door_p := RF_GetDoor(x1, y1);
      if mapflags[mapspot - 1] and FL_DOOR <> 0 then
        door_p.orientation := dr_horizontal2
      else
        door_p.orientation := dr_horizontal;
      door_p.doorBumpable := true;
      door_p.doorSize := 64 * FRACUNIT;
      door_p.position := door_p.doorSize;
      door_p.doorTimer := player.timecount;
      door_p.pic := CA_GetNamedNum('door_3') - walllump;
      mapsprites[mapspot] := 0;
    end;

  S_VDOOR4: // vertical door 4
    begin
      door_p := RF_GetDoor(x1, y1);
      if mapflags[mapspot - MAPCOLS] and FL_DOOR <> 0 then
        door_p.orientation := dr_vertical2
      else
        door_p.orientation := dr_vertical;
      door_p.doorBumpable := true;
      door_p.doorSize := 64 * FRACUNIT;
      door_p.position := door_p.doorSize;
      door_p.doorTimer := player.timecount;
      door_p.pic := CA_GetNamedNum('door_4') - walllump;
      mapsprites[mapspot] := 0;
    end;

  S_HDOOR4: // horizontal door 4
    begin
      door_p := RF_GetDoor(x1, y1);
      if mapflags[mapspot - 1] and FL_DOOR <> 0 then
        door_p.orientation := dr_horizontal2
      else
        door_p.orientation := dr_horizontal;
      door_p.doorBumpable := true;
      door_p.doorSize := 64 * FRACUNIT;
      door_p.position := door_p.doorSize;
      door_p.doorTimer := player.timecount;
      door_p.pic := CA_GetNamedNum('door_4') - walllump;
      mapsprites[mapspot] := 0;
    end;

  S_VDOOR5: // vertical door 5
    begin
      door_p := RF_GetDoor(x1, y1);
      if mapflags[mapspot - MAPCOLS] and FL_DOOR <> 0 then
        door_p.orientation := dr_vertical2
      else
        door_p.orientation := dr_vertical;
      door_p.doorBumpable := true;
      door_p.doorSize := 64 * FRACUNIT;
      door_p.position := door_p.doorSize;
      door_p.pic := CA_GetNamedNum('door_5') - walllump;
      door_p.doorTimer := player.timecount;
      mapsprites[mapspot] := 0;
    end;

  S_HDOOR5: // horizontal door 5
    begin
      door_p := RF_GetDoor(x1, y1);
      if mapflags[mapspot - 1] and FL_DOOR <> 0 then
        door_p.orientation := dr_horizontal2
      else
        door_p.orientation := dr_horizontal;
      door_p.doorBumpable := true;
      door_p.doorSize := 64 * FRACUNIT;
      door_p.position := door_p.doorSize;
      door_p.doorTimer := player.timecount;
      door_p.pic := CA_GetNamedNum('door_5') - walllump;
      mapsprites[mapspot] := 0;
    end;

  S_VDOOR6: // vertical door 6
    begin
      door_p := RF_GetDoor(x1, y1);
      if mapflags[mapspot - MAPCOLS] and FL_DOOR <> 0 then
        door_p.orientation := dr_vertical2
      else
        door_p.orientation := dr_vertical;
      door_p.doorBumpable := true;
      door_p.doorSize := 64 * FRACUNIT;
      door_p.position := door_p.doorSize;
      door_p.pic := CA_GetNamedNum('door_6') - walllump;
      door_p.doorTimer := player.timecount;
      mapsprites[mapspot] := 0;
    end;

  S_HDOOR6: // horizontal door 6
    begin
      door_p := RF_GetDoor(x1, y1);
      if mapflags[mapspot - 1] and FL_DOOR <> 0 then
        door_p.orientation := dr_horizontal2
      else
        door_p.orientation := dr_horizontal;
      door_p.doorBumpable := true;
      door_p.doorSize := 64 * FRACUNIT;
      door_p.position := door_p.doorSize;
      door_p.doorTimer := player.timecount;
      door_p.pic := CA_GetNamedNum('door_6') - walllump;
      mapsprites[mapspot] := 0;
    end;

  S_VDOOR7: // vertical door 7
    begin
      door_p := RF_GetDoor(x1, y1);
      if mapflags[mapspot - MAPCOLS] and FL_DOOR <> 0 then
        door_p.orientation := dr_vertical2
      else
        door_p.orientation := dr_vertical;
      door_p.doorBumpable := true;
      door_p.doorSize := 64 * FRACUNIT;
      door_p.position := door_p.doorSize;
      door_p.pic := CA_GetNamedNum('door_7') - walllump;
      door_p.doorTimer := player.timecount;
      mapsprites[mapspot] := 0;
    end;

  S_HDOOR7: // horizontal door 7
    begin
      door_p := RF_GetDoor(x1, y1);
      if mapflags[mapspot - 1] and FL_DOOR <> 0 then
        door_p.orientation := dr_horizontal2
      else
        door_p.orientation := dr_horizontal;
      door_p.doorBumpable := true;
      door_p.doorSize := 64 * FRACUNIT;
      door_p.position := door_p.doorSize;
      door_p.doorTimer := player.timecount;
      door_p.pic := CA_GetNamedNum('door_7') - walllump;
      mapsprites[mapspot] := 0;
    end;

  (* elevators ***********************************************************)
  S_ELEVATOR: // normal elevator
    begin
      elevator_p := RF_GetElevator;
      elevator_p.elevUp := true;
      elevator_p.floor := floorheight[mapspot];
      elevator_p.mapspot := mapspot;
      mapsprites[mapspot] := 0;
      maxheight := floorheight[mapspot];
      for i := y1 - 1 to y1 + 1 do
        for j := x1 - 1 to x1 + 1 do
        begin
          mapspot := i * MAPCOLS + j;
          if floorheight[mapspot] > maxheight then
            maxheight := floorheight[mapspot];
        end;
      elevator_p.ceiling := maxheight;
      elevator_p.position := maxheight;
      elevator_p.position64 := elevator_p.position * FRACUNIT;
      elevator_p.typ := E_NORMAL;
      elevator_p.elevTimer := player.timecount;
      elevator_p.speed := 8;
      floorheight[elevator_p.mapspot] := maxheight;
    end;

  S_PAUSEDELEVATOR: // these don't move yet
    begin
      elevator_p := RF_GetElevator;
      elevator_p.floor := floorheight[mapspot];
      elevator_p.mapspot := mapspot;
      mapsprites[mapspot] := 0;
      maxheight := floorheight[mapspot];
      for i := y1 - 1 to y1 + 1 do
        for j := x1 - 1 to x1 + 1 do
        begin
          mapspot := i * MAPCOLS + j;
          if floorheight[mapspot] > maxheight then
            maxheight := floorheight[mapspot];
        end;
      elevator_p.ceiling := maxheight;
      elevator_p.position := maxheight;
      elevator_p.position64 := elevator_p.position * FRACUNIT;
      elevator_p.typ := E_NORMAL;
      elevator_p.elevTimer := $70000000;
      elevator_p.speed := 8;
      floorheight[elevator_p.mapspot] := maxheight;
    end;

  S_SWAPSWITCH:
    begin
      mapsprites[mapspot] := SM_SWAPSWITCH;
    end;

  S_ELEVATORLOW:
    begin
      elevator_p := RF_GetElevator;
      elevator_p.position := floorheight[mapspot];
      elevator_p.position64 := elevator_p.position * FRACUNIT;
      elevator_p.floor := floorheight[mapspot];
      elevator_p.mapspot := mapspot;
      mapsprites[mapspot] := 0;
      elevator_p.ceiling := ceilingheight[mapspot];
      elevator_p.typ := E_SWAP;
      elevator_p.speed := 8;
      elevator_p.elevTimer := $70000000;
    end;

  S_ELEVATORHIGH:
    begin
      elevator_p := RF_GetElevator;
      elevator_p.floor := floorheight[mapspot];
      elevator_p.mapspot := mapspot;
      mapsprites[mapspot] := 0;
      elevator_p.ceiling := ceilingheight[mapspot];
      elevator_p.position := ceilingheight[mapspot];
      floorheight[mapspot] := elevator_p.position;
      elevator_p.typ := E_SWAP;
      elevator_p.speed := 8;
      elevator_p.elevTimer := $70000000;
    end;

  S_ELEVATOR3M: // 3 min elevator
    begin
      elevator_p := RF_GetElevator;
      elevator_p.elevDown := true;
      elevator_p.position := ceilingheight[mapspot];
      elevator_p.position64 := elevator_p.position * FRACUNIT;
      elevator_p.floor := floorheight[mapspot];
      elevator_p.ceiling := ceilingheight[mapspot];
      floorheight[mapspot] := ceilingheight[mapspot];
      elevator_p.mapspot := mapspot;
      elevator_p.typ := E_TIMED;
      elevator_p.elevTimer := 12600;
      elevator_p.speed := 8;
      mapsprites[mapspot] := SM_ELEVATOR;
    end;

  S_ELEVATOR6M: // 6 min elevator
    begin
      elevator_p := RF_GetElevator;
      elevator_p.elevDown := true;
      elevator_p.position := ceilingheight[mapspot];
      elevator_p.position64 := elevator_p.position * FRACUNIT;
      elevator_p.floor := floorheight[mapspot];
      elevator_p.ceiling := ceilingheight[mapspot];
      floorheight[mapspot] := ceilingheight[mapspot];
      elevator_p.mapspot := mapspot;
      elevator_p.typ := E_TIMED;
      elevator_p.elevTimer := 25200;
      elevator_p.speed := 8;
      mapsprites[mapspot] := SM_ELEVATOR;
    end;

  S_ELEVATOR15M: // 15 min elevator
    begin
      elevator_p := RF_GetElevator;
      elevator_p.elevDown := true;
      elevator_p.position := ceilingheight[mapspot];
      elevator_p.position64 := elevator_p.position * FRACUNIT;
      elevator_p.floor := floorheight[mapspot];
      elevator_p.ceiling := ceilingheight[mapspot];
      floorheight[mapspot] := ceilingheight[mapspot];
      elevator_p.mapspot := mapspot;
      elevator_p.typ := E_TIMED;
      elevator_p.elevTimer := 63000;
      elevator_p.speed := 8;
      mapsprites[mapspot] := SM_ELEVATOR;
    end;

  S_TRIGGER1: // trigger 1
    begin
      mapsprites[mapspot] := SM_SWITCHDOWN;
    end;

  S_TRIGGERD1: // trigger door 1
    begin
      elevator_p := RF_GetElevator;
      elevator_p.position := ceilingheight[mapspot];
      elevator_p.position64 := elevator_p.position * FRACUNIT;
      elevator_p.floor := floorheight[mapspot];
      elevator_p.ceiling := ceilingheight[mapspot];
      elevator_p.mapspot := mapspot;
      elevator_p.typ := E_SWITCHDOWN;
      elevator_p.speed := 8;
      elevator_p.elevTimer := $70000000;
      mapsprites[mapspot] := SM_ELEVATOR;
      floorheight[mapspot] := elevator_p.position;
    end;

  S_TRIGGER2: // trigger 2
    begin
      mapsprites[mapspot] := SM_SWITCHDOWN2;
    end;

  S_TRIGGERD2: // trigger door 2
    begin
      elevator_p := RF_GetElevator;
      elevator_p.position := ceilingheight[mapspot];
      elevator_p.position64 := elevator_p.position * FRACUNIT;
      elevator_p.floor := floorheight[mapspot];
      elevator_p.ceiling := ceilingheight[mapspot];
      elevator_p.mapspot := mapspot;
      elevator_p.typ := E_SWITCHDOWN2;
      elevator_p.speed := 8;
      elevator_p.elevTimer := $70000000;
      mapsprites[mapspot] := SM_ELEVATOR;
      floorheight[mapspot] := elevator_p.position;
    end;

  S_STRIGGER:
    begin
      mapsprites[mapspot] := SM_STRIGGER;
    end;

  S_SDOOR:
    begin
      elevator_p := RF_GetElevator;
      elevator_p.floor := floorheight[mapspot];
      elevator_p.mapspot := mapspot;
      elevator_p.ceiling := ceilingheight[mapspot];
      elevator_p.position := ceilingheight[mapspot];
      elevator_p.position64 := elevator_p.position * FRACUNIT;
      elevator_p.typ := E_SECRET;
      elevator_p.elevTimer := $70000000;
      elevator_p.speed := 8;
      mapsprites[mapspot] := 0;
      floorheight[mapspot] := ceilingheight[mapspot];
    end;

  (* warps ***************************************************************)
  S_WARP1: // warp 1
    begin
      mapsprites[mapspot] := SM_WARP1;   // mapsprites>128 := > ignore (clear movement)
    end;

  S_WARP2: // warp 2
    begin
      mapsprites[mapspot] := SM_WARP2;
    end;

  S_WARP3: // warp 3
    begin
      mapsprites[mapspot] := SM_WARP3;
    end;

  (* misc ****************************************************************)

  S_SOLID:
    begin
    end;

  (* generators *********************************************************)

  S_GENERATOR1,
  S_GENERATOR2:
    begin
      sa := RF_GetSpawnArea;
      sa.mapx := (x1 * FRACTILEUNIT) + (32 * FRACUNIT);
      sa.mapy := (y1 * FRACTILEUNIT) + (32 * FRACUNIT);
      sa.mapspot := mapspot;
      sa.time := player.timecount + ((MS_RndT and 15) * 64);
      sa.typ := value - S_GENERATOR1;
      SpawnSprite(S_GENERATOR, (x1 * MAPSIZE + 32) * FRACUNIT, (y1 * MAPCOLS + 32) * FRACUNIT, 0, 0, MS_RndT * 4, 0, false, 0);
      mapsprites[mapspot] := 0;
    end;

  S_SPAWN1,
  S_SPAWN2,
  S_SPAWN3,
  S_SPAWN4,
  S_SPAWN5,
  S_SPAWN6,
  S_SPAWN7,
  S_SPAWN8,
  S_SPAWN9,
  S_SPAWN10,
  S_SPAWN11,
  S_SPAWN12,
  S_SPAWN13,
  S_SPAWN14,
  S_SPAWN15:
    begin
      if not nospawn then
      begin
        sa := RF_GetSpawnArea;
        sa.mapx := (x1 * FRACTILEUNIT) + (32 * FRACUNIT);
        sa.mapy := (y1 * FRACTILEUNIT) + (32 * FRACUNIT);
        sa.mapspot := mapspot;
        sa.time := player.timecount + ((MS_RndT and 15) * 64);
        sa.typ := value - S_SPAWN1 + 10;
      end;
      mapsprites[mapspot] := 0;
    end;

  S_SPAWN8_NS,
  S_SPAWN9_NS:
    begin
      if not nospawn then
      begin
        sa := RF_GetSpawnArea;
        sa.mapx := (x1 * FRACTILEUNIT) + (32 * FRACUNIT);
        sa.mapy := (y1 * FRACTILEUNIT) + (32 * FRACUNIT);
        sa.mapspot := mapspot;
        sa.time := player.timecount + ((MS_RndT and 15) * 64);
        sa.typ := value - S_SPAWN8_NS + 100;
      end;
      mapsprites[mapspot] := 0;
    end;

  S_EXIT:
    begin
      sprite_p := RF_GetSprite;
      sprite_p.x := x;
      sprite_p.y := y;
      sprite_p.z := RF_GetFloorZ(x, y);
      sprite_p.basepic := CA_GetNamedNum('exitwarp');
      sprite_p.typ := S_EXIT;
      sprite_p.animation := 1 + (0 shl 1) + (8 shl 5) + (5 shl 9);
      mapsprites[mapspot] := SM_EXIT;
      exitexists := true;
      exitx := x1;
      exity := y1;
    end;

  end;

  if (midgetmode) and (sprite_p <> nil) then
    inc(sprite_p.scale);
  result := sprite_p;
  if result <> nil then
  begin
    result.oldx := result.x;
    result.oldy := result.y;
    result.oldz := result.z;
    result.oldangle := result.angle;
    result.oldangle2 := result.angle2;
    result.newx := result.x;
    result.newy := result.y;
    result.newz := result.z;
    result.newangle := result.angle;
    result.newangle2 := result.angle2;
  end;
end;

end.


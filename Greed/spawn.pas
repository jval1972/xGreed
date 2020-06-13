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

unit spawn;

interface

const
  MAXSTARTLOCATIONS = 8;

procedure DemandLoadMonster(const lump, num: integer);

implementation

uses
  g_delphi,
  d_disk,
  r_refdef;

procedure DemandLoadMonster(const lump, num: integer);
var
  i, j, l, count, top, bottom: integer;
  pic: Pscalepic_t;
  collumn: PByteArray;
begin
  if lumpmain[lump] <> nil then
    exit; // already loaded
  for l := 0 to num - 1 do
  begin
    CA_CacheLump(lump + l);
    pic := lumpmain[lump + l];
    for i := 0 to pic.width - 1 do
      if pic.collumnofs[i] <> 0 then
      begin
        collumn := @PByteArray(pic)[pic.collumnofs[i]];
        top := collumn[1];
        bottom := collumn[0];
        count := bottom - top + 1;
        collumn := @collumn[2];
        for j := 0 to count - 1 do
        begin
          if collumn[0] = 255 then
            collumn[0] := 0;
          column := @column[1];
        end;
      end;
  end;
end;

scaleobj_t *SpawnSprite(int value, fixed_t x, fixed_t y, fixed_t z,fixed_t zadj,int angle,int angle2,bool active,int spawnid)
begin
  scaleobj_t  *sprite_p := 0, *s;
  doorobj_t   *door_p;
  elevobj_t   *elevator_p;
  spawnarea_t *sa;
  x1, y1, mapspot, maxheight, i, j: integer;

  x1 := x shr FRACTILESHIFT;
  y1 := y shr FRACTILESHIFT;
  mapspot := y1*MAPCOLS+x1;
  angle) and (:= ANGLES;

  case value  of
  begin
   S_BLOODSPLAT:
    if MS_RndT>220 then
    begin
     sprite_p := RF_GetSprite ;
     sprite_p.animation := 0 + (0 shl 1) + (5 shl 5) + ((2+(MS_RndT) and (7)) shl 9) + ANIM_SELFDEST;
     sprite_p.x := x+((-3+MS_RndT) and (7) shl FRACBITS);
     sprite_p.y := y+((-3+MS_RndT) and (7) shl FRACBITS);
     sprite_p.z := z+((-3+MS_RndT) and (7) shl FRACBITS);
     sprite_p.basepic := slumps[S_WALLPUFF-S_START];
     sprite_p.active := true;
     sprite_p.heat := 100;
     sprite_p.active := true;
     sprite_p.type := S_WALLPUFF;
     sprite_p.specialtype := st_transparent;
     end;
    break;
    (*
    if (not SC.violence) break;
    if bloodcount>200 then
    begin
      for (s := firstscaleobj.next; s <> @lastscaleobj;s := s.next)
       if s.type = S_BLOODSPLAT then
       begin
   RF_RemoveSprite(s);
   break;
    end;
       end;
    bloodcount++;
    sprite_p := RF_GetSprite;
    sprite_p.x := x+((-3+MS_RndT) and (7) shl FRACBITS);
    sprite_p.y := y+((-3+MS_RndT) and (7) shl FRACBITS);
    sprite_p.z := z+((7+MS_RndT) and (15) shl FRACBITS);
    sprite_p.zadj := zadj;
    sprite_p.active := true;
    sprite_p.angle := MS_RndT*4;
    sprite_p.moveSpeed := 15-(MS_RndT) and (7);
    sprite_p.angle2 := (MS_RndT) and (63)+32;
    sprite_p.basepic := slumps[value-S_START]+(MS_RndT mod 10);
    sprite_p.type := S_BLOODSPLAT;
    sprite_p.startspot := mapspot;
    sprite_p.movesize := FRACUNIT;
    sprite_p.scale := 1;
    break; *)
  (*  S_GREENBLOOD:
    if (not SC.violence) break;
    if bloodcount>100 then
    begin
      for (s := firstscaleobj.next; s <> @lastscaleobj;s := s.next)
       if s.type = S_BLOODSPLAT then
       begin
   RF_RemoveSprite(s);
   break;
    end;
       end;
    bloodcount++;
    sprite_p := RF_GetSprite;
    sprite_p.x := x+((-3+MS_RndT) and (7) shl FRACBITS);
    sprite_p.y := y+((-3+MS_RndT) and (7) shl FRACBITS);
    sprite_p.z := z+((7+MS_RndT) and (15) shl FRACBITS);
    sprite_p.zadj := zadj;
    sprite_p.active := true;
    sprite_p.angle := MS_RndT*4;
    sprite_p.moveSpeed := 15-(MS_RndT) and (7);
    sprite_p.angle2 := (MS_RndT) and (63)+32;
    sprite_p.basepic := slumps[value-S_START]+(MS_RndT mod 10);
    sprite_p.type := S_BLOODSPLAT;
    sprite_p.startspot := mapspot;
    sprite_p.movesize := FRACUNIT;
    break; *)

   (* ammo *)
   S_BULLET1: // autopistol
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 500;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 35;
    sprite_p.type := value;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;
   S_BULLET2: // vulcan cannon
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 500;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 40;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 40;
    sprite_p.type := value;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;
   S_BULLET3: // flamer
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 90;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 96;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 30;
    sprite_p.type := value;
    sprite_p.angle2 := angle2;
    sprite_p.spawnid := spawnid;
    sprite_p.rotate := rt_eight;
    sprite_p.specialtype := st_noclip;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;
   S_BULLET4: // spread gun
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 100;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 4 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 112;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 50;
    sprite_p.type := value;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    sprite_p.rotate := rt_eight;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;
   S_BULLET7: // psyborg #1
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 72;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 30;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 50;
    sprite_p.type := value;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    sprite_p.maxmove := 2;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;
   S_BULLET9: // lizard #2
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 100;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 90;
    sprite_p.type := value;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    sprite_p.rotate := rt_four;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;
   S_BULLET10: // specimen #2
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 50;
    sprite_p.angle := angle;
    sprite_p.animation := 1 + (0 shl 1) + (3 shl 5) + (5 shl 9);
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 3 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 500;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 35;
    sprite_p.type := value;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;
   S_BULLET11: // mooman #2
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 500;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 10;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 50;
    sprite_p.type := value;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;
   S_BULLET12: // dominatrix #2
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 100;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 2 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 300;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 45;
    sprite_p.type := value;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;
   S_BULLET16: // red
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 100;
    sprite_p.angle := angle;
    sprite_p.animation := 1 + (0 shl 1) + (3 shl 5) + (5 shl 9);
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 3 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 30;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 30;
    sprite_p.type := value;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;
   S_BULLET17: // blue gun
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 64;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 100;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 75;
    sprite_p.type := S_BULLET17;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    sprite_p.scale := 1;
    sprite_p.rotate := rt_eight;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;

(*    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 20;
    sprite_p.maxmove := 17;
    sprite_p.angle := angle;
    sprite_p.animation := 1 + (0 shl 1) + (3 shl 5) + (3 shl 9);
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 5 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 5;
    sprite_p.damage := 1;
    sprite_p.startspot := mapspot;
    sprite_p.type := value;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    sprite_p.specialtype := st_transparent;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break; *)
   S_BULLET18: // green
    sprite_p := RF_GetSprite;
    sprite_p.animation := 1 + (0 shl 1) + (3 shl 5) + (5 shl 9);
    sprite_p.moveSpeed := 50;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 5 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 300;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 400;
    sprite_p.type := value;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    break;

   S_EXPLODE:
   S_SMALLEXPLODE:
    sprite_p := RF_GetSprite;
    sprite_p.animation := 0 + (0 shl 1) + (4 shl 5) + ((2+(MS_RndT) and (7)) shl 9) + ANIM_SELFDEST;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := z;
    if (MS_RndT) and (1) sprite_p.basepic := slumps[S_EXPLODE-S_START];
     else sprite_p.basepic := slumps[S_EXPLODE2-S_START];
    sprite_p.active := true;
    sprite_p.heat := 512;
    sprite_p.type := S_EXPLODE;
    sprite_p.specialtype := st_noclip;
    break;

   S_WALLPUFF:
    sprite_p := RF_GetSprite ;
    sprite_p.animation := 0 + (0 shl 1) + (5 shl 5) + ((2+(MS_RndT) and (7)) shl 9) + ANIM_SELFDEST;
    sprite_p.x := x+((-3+MS_RndT) and (7) shl FRACBITS);
    sprite_p.y := y+((-3+MS_RndT) and (7) shl FRACBITS);
    sprite_p.z := z+((-3+MS_RndT) and (7) shl FRACBITS);
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.active := true;
    sprite_p.heat := 100;
    sprite_p.active := true;
    sprite_p.type := S_WALLPUFF;
    sprite_p.specialtype := st_transparent;
    break;
   S_GREENPUFF:
    sprite_p := RF_GetSprite ;
    sprite_p.animation := 0 + (0 shl 1) + (4 shl 5) + ((2+(MS_RndT) and (7)) shl 9) + ANIM_SELFDEST;
    sprite_p.x := x+((-3+MS_RndT) and (7) shl FRACBITS);
    sprite_p.y := y+((-3+MS_RndT) and (7) shl FRACBITS);
    sprite_p.z := z+((-3+MS_RndT) and (7) shl FRACBITS);
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.active := true;
    sprite_p.heat := 150;
    sprite_p.active := true;
    sprite_p.type := S_WALLPUFF;
    sprite_p.specialtype := st_transparent;
    break;

   S_PLASMAWALLPUFF:
    sprite_p := RF_GetSprite ;
    sprite_p.animation := 0 + (0 shl 1) + (4 shl 5) + ((5+(MS_RndT) and (7)) shl 9) + ANIM_SELFDEST;
    sprite_p.x := x+((-3+MS_RndT) and (7) shl FRACBITS);
    sprite_p.y := y+((-3+MS_RndT) and (7) shl FRACBITS);
    sprite_p.z := z+((-3+MS_RndT) and (7) shl FRACBITS);
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.heat := 600;
    sprite_p.active := true;
    sprite_p.type := S_PLASMAWALLPUFF;
    sprite_p.specialtype := st_transparent;
    break;
   S_ARROWPUFF:
    sprite_p := RF_GetSprite ;
    sprite_p.animation := 0 + (0 shl 1) + (4 shl 5) + ((3+(MS_RndT) and (7)) shl 9) + ANIM_SELFDEST;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := z;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.active := true;
    sprite_p.heat := 512;
    sprite_p.type := S_EXPLODE;
    sprite_p.specialtype := st_noclip;
    SoundEffect(SN_EXPLODE1+(MS_RndT) and (1),15,x,y);
    break;

   S_MONSTERBULLET1:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 500;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 40;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 60;
    sprite_p.type := S_MONSTERBULLET1;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    SoundEffect(SN_MON1_FIRE,7,x,y);
    break;
   S_MONSTERBULLET2:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 90;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 96;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 100;
    sprite_p.type := S_MONSTERBULLET2;
    sprite_p.spawnid := spawnid;
    sprite_p.rotate := rt_eight;
    sprite_p.angle2 := angle2;
    SoundEffect(SN_MON2_FIRE,7,x,y);
    break;
   S_MONSTERBULLET3:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 60;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 40;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 60;
    sprite_p.type := S_MONSTERBULLET3;
    sprite_p.spawnid := spawnid;
    sprite_p.animation := 1 + (0 shl 1) + (3 shl 5) + (2 shl 9);
    sprite_p.angle2 := angle2;
    SoundEffect(SN_MON3_FIRE,7,x,y);
    break;
   S_MONSTERBULLET4:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 80;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 40;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 75;
    sprite_p.type := S_MONSTERBULLET4;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    sprite_p.scale := 1;
    sprite_p.rotate := rt_eight;
    SoundEffect(SN_MON4_FIRE,7,x,y);
    break;
   S_MONSTERBULLET5:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 80;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 40;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 100;
    sprite_p.type := S_MONSTERBULLET5;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    SoundEffect(SN_MON5_FIRE,7,x,y);
    break;
   S_MONSTERBULLET6:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 70;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 100;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 150;
    sprite_p.type := S_MONSTERBULLET6;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    sprite_p.scale := 2;
    sprite_p.rotate := rt_eight;
    SoundEffect(SN_MON6_FIRE,7,x,y);
    break;

   S_MONSTERBULLET7:
    sprite_p := RF_GetSprite;
    sprite_p.maxmove := 2;
    sprite_p.moveSpeed := 128;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 0;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 60;
    sprite_p.type := S_MONSTERBULLET7;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    SoundEffect(SN_MON7_FIRE,7,x,y);
    break;

   S_MONSTERBULLET8:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 90;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 96;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 100;
    sprite_p.type := S_MONSTERBULLET8;
    sprite_p.angle2 := angle2;
    sprite_p.spawnid := spawnid;
    sprite_p.rotate := rt_eight;
    sprite_p.specialtype := st_noclip;
    SoundEffect(SN_MON8_FIRE,7,x,y);
    break;
   S_MONSTERBULLET9:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 500;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 40;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 60;
    sprite_p.type := S_MONSTERBULLET9;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    SoundEffect(SN_MON9_FIRE,7,x,y);
    break;
   S_MONSTERBULLET10:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 128;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 20;
    sprite_p.maxmove := 2;
    sprite_p.type := S_MONSTERBULLET10;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    SoundEffect(SN_MON10_FIRE,7,x,y);
    break;
   S_MONSTERBULLET11:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 100;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 100;
    sprite_p.type := S_MONSTERBULLET11;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    SoundEffect(SN_MON11_FIRE,7,x,y);
    break;
   S_MONSTERBULLET12:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 70;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 40;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 40;
    sprite_p.type := S_MONSTERBULLET12;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    SoundEffect(SN_MON12_FIRE,7,x,y);
    break;
   S_MONSTERBULLET13:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 100;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 40;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 50;
    sprite_p.type := S_MONSTERBULLET13;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    SoundEffect(SN_MON13_FIRE,7,x,y);
    break;
   S_MONSTERBULLET14:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 100;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 40;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 100;
    sprite_p.type := S_MONSTERBULLET14;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    SoundEffect(SN_MON14_FIRE,7,x,y);
    break;
   S_MONSTERBULLET15:
    sprite_p := RF_GetSprite;
    sprite_p.maxmove := 4;
    sprite_p.moveSpeed := 128;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 75;
    sprite_p.type := S_MONSTERBULLET15;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    SoundEffect(SN_MON15_FIRE,7,x,y);
    break;

   S_GRENADEBULLET:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 64;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[S_BULLET3-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 96;
    sprite_p.startspot := -1;
    sprite_p.damage := 50;
    sprite_p.type := value;
    if (spawnid = playernum) sprite_p.spawnid := 200+spawnid;
     else sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    break;

   S_MINEBULLET:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 128;
    sprite_p.maxmove := 2;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 8 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.heat := 112;
    sprite_p.startspot := -1;
    sprite_p.damage := 50;
    sprite_p.type := value;
    if (spawnid = playernum) sprite_p.spawnid := 200+spawnid;
     else sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    break;
   S_HANDBULLET: // hand weapon attack
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 72;
    sprite_p.maxmove := 2;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.startspot := mapspot;
    sprite_p.damage := 100;
    sprite_p.type := value;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;
   S_SOULBULLET: // soul stealer attack
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 72;
    sprite_p.maxmove := 4;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.movesize := 1 shl FRACBITS;
    sprite_p.active := true;
    sprite_p.startspot := -1;
    sprite_p.damage := 250;
    sprite_p.type := value;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    break;
   S_METALPARTS:
    if metalcount>100 then
    begin
      for (s := firstscaleobj.next; s <> @lastscaleobj;s := s.next)
       if s.type = S_METALPARTS then
       begin
   RF_RemoveSprite(s);
   break;
    end;
       end;
    metalcount++;
    sprite_p := RF_GetSprite;
    sprite_p.x := x+((-15+MS_RndT) and (31) shl FRACBITS);
    sprite_p.y := y+((-15+MS_RndT) and (31) shl FRACBITS);
    sprite_p.z := z+((-32+MS_RndT) and (63) shl FRACBITS);
    sprite_p.zadj := zadj;
    sprite_p.active := true;
    sprite_p.angle := MS_RndT*4;
    sprite_p.moveSpeed := 10+(MS_RndT) and (15);
    sprite_p.angle2 := (MS_RndT) and (63)+32;
    sprite_p.basepic := CA_GetNamedNum('METALPARTS')+(MS_RndT) and (3);
    sprite_p.type := S_METALPARTS;
    sprite_p.startspot := mapspot;
    sprite_p.movesize := FRACUNIT;
    sprite_p.damage := 100;
    break;

   S_WARP:
    sprite_p := RF_GetSprite;
    sprite_p.animation := 0 + (0 shl 1) + (8 shl 5) + (6 shl 9) + ANIM_SELFDEST;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.type := value;
    sprite_p.specialtype := st_maxlight;
    SoundEffect(SN_WARP,0,x,y);
    break;
   S_PROXMINE:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 1;
    sprite_p.active := true;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('proxmine');
    sprite_p.intelligence := 6;
    sprite_p.type := S_PROXMINE;
    sprite_p.spawnid := spawnid;
    sprite_p.actiontime := timecount+105;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;
   S_TIMEMINE:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 1;
    sprite_p.active := true;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('timemine');
    sprite_p.intelligence := 6;
    sprite_p.type := S_TIMEMINE;
    sprite_p.spawnid := spawnid;
    sprite_p.actiontime := timecount+(2*70);
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;
   S_INSTAWALL:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 1;
    sprite_p.active := true;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.animation := 1 + (0 shl 1) + (4 shl 5) + (16 shl 9);
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('instaanim');
    sprite_p.intelligence := 6;
    sprite_p.type := value;
    sprite_p.spawnid := spawnid;
    sprite_p.actiontime := timecount+(45*70);
    sprite_p.specialtype := st_transparent;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    mapsprites[mapspot] := 64;
    break;
   S_DECOY:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 1;
    sprite_p.active := true;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum(charnames[spawnid]);
    sprite_p.scale := 1;
    sprite_p.rotate := rt_eight;
    sprite_p.intelligence := 6;
    sprite_p.type := S_PROXMINE;
    sprite_p.spawnid := spawnid;
    sprite_p.actiontime := timecount+(2*70);
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;
   S_CLONE:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 10 shl FRACBITS;
    sprite_p.angle := angle;
    sprite_p.active := active;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.rotate := rt_eight;
    sprite_p.basepic := CA_GetNamedNum(charnames[spawnid]);
    sprite_p.scale := 1;
    sprite_p.startpic := sprite_p.basepic;
    sprite_p.movesize := 24 shl FRACBITS;
    sprite_p.intelligence := 7;
    sprite_p.hitpoints := 700;
    sprite_p.type := S_CLONE;
    sprite_p.height := 54 shl FRACBITS;
    sprite_p.bullet := S_MONSTERBULLET8;
    mapsprites[mapspot] := 1;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;
   S_GRENADE:
    sprite_p := RF_GetSprite;
    sprite_p.moveSpeed := 50;
    sprite_p.angle := angle;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := zadj;
    sprite_p.z := z+zadj;
    sprite_p.basepic := CA_GetNamedNum('grenadeshot');
    sprite_p.movesize := 10 shl FRACBITS;
    sprite_p.hitpoints := 1;
    sprite_p.active := true;
    sprite_p.startspot := mapspot;
    sprite_p.type := S_GRENADE;
    sprite_p.spawnid := spawnid;
    sprite_p.angle2 := angle2;
    sprite_p.rotate := rt_four;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;

   S_MINEPUFF:
    sprite_p := RF_GetSprite ;
    sprite_p.animation := 0 + (0 shl 1) + (4 shl 5) + ((5+(MS_RndT) and (7)) shl 9) + ANIM_SELFDEST;
    sprite_p.x := x+((-3+MS_RndT) and (7) shl FRACBITS);
    sprite_p.y := y+((-3+MS_RndT) and (7) shl FRACBITS);
    sprite_p.z := z+((-3+MS_RndT) and (7) shl FRACBITS);
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.heat := 600;
    sprite_p.active := true;
    sprite_p.type := S_MINEPUFF;
    sprite_p.specialtype := st_noclip;
    break;

  (* monsters ********************************************************)
   S_MONSTER1_NS: // kman
   S_MONSTER1:
    sprite_p := RF_GetSprite;
    if value = S_MONSTER1_NS then
     sprite_p.nofalling := 1;
    sprite_p.moveSpeed := 4 shl FRACBITS;
    sprite_p.angle := angle;
    sprite_p.active := active;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.rotate := rt_eight;
    sprite_p.basepic := CA_GetNamedNum('kman');
    DemandLoadMonster(sprite_p.basepic,56);
    sprite_p.startpic := sprite_p.basepic;
    sprite_p.movesize := 26 shl FRACBITS;
    sprite_p.intelligence := 10;
    sprite_p.heat := 8;
    sprite_p.hitpoints := 80;
    sprite_p.type := S_MONSTER1;
    sprite_p.height := 59 shl FRACBITS;
    sprite_p.score := 160;
    sprite_p.bullet := S_MONSTERBULLET1;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 1;
    break;
   S_MONSTER2_NS: // kfem
   S_MONSTER2:
    sprite_p := RF_GetSprite;
    if value = S_MONSTER2_NS then
     sprite_p.nofalling := 1;
    sprite_p.moveSpeed := 4 shl FRACBITS;
    sprite_p.angle := angle;
    sprite_p.active := active;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.rotate := rt_eight;
    sprite_p.basepic := CA_GetNamedNum('kfem');
    DemandLoadMonster(sprite_p.basepic,56);
    sprite_p.startpic := sprite_p.basepic;
    sprite_p.movesize := 26 shl FRACBITS;
    sprite_p.intelligence := 10;
    sprite_p.heat := 8;
    sprite_p.hitpoints := 110;
    sprite_p.type := S_MONSTER2;
    sprite_p.height := 59 shl FRACBITS;
    sprite_p.score := 220;
    sprite_p.bullet := S_MONSTERBULLET2;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 1;
    break;
   S_MONSTER3_NS: // kprob
   S_MONSTER3:
    sprite_p := RF_GetSprite;
    if value = S_MONSTER3_NS then
     sprite_p.nofalling := 1;
    sprite_p.moveSpeed := 7 shl FRACBITS;
    sprite_p.angle := angle;
    sprite_p.active := active;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := 25 shl FRACBITS;
    sprite_p.z := RF_GetFloorZ(x,y)+sprite_p.zadj;
    sprite_p.rotate := rt_eight;
    sprite_p.basepic := CA_GetNamedNum('kprob');
    DemandLoadMonster(sprite_p.basepic,56);
    sprite_p.startpic := sprite_p.basepic;
    sprite_p.movesize := 26 shl FRACBITS;
    sprite_p.intelligence := 10;
    sprite_p.hitpoints := 150;
    sprite_p.type := S_MONSTER3;
    sprite_p.height := 20 shl FRACBITS;
    sprite_p.score := 300;
    sprite_p.bullet := S_MONSTERBULLET3;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 1;
    break;
   S_MONSTER4_NS: // kbot
   S_MONSTER4:
    sprite_p := RF_GetSprite;
    if value = S_MONSTER4_NS then
     sprite_p.nofalling := 1;
    sprite_p.moveSpeed := 4 shl FRACBITS;
    sprite_p.angle := angle;
    sprite_p.active := active;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.rotate := rt_eight;
    sprite_p.basepic := CA_GetNamedNum('kbot');
    DemandLoadMonster(sprite_p.basepic,48);
    sprite_p.startpic := sprite_p.basepic;
    sprite_p.movesize := 26 shl FRACBITS;
    sprite_p.intelligence := 10;
    sprite_p.hitpoints := 350;
    sprite_p.type := S_MONSTER4;
    sprite_p.height := 45 shl FRACBITS;
    sprite_p.score := 700;
    sprite_p.bullet := S_MONSTERBULLET4;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 1;
    break;
   S_MONSTER5_NS: // kboss
   S_MONSTER5:
    sprite_p := RF_GetSprite;
    if value = S_MONSTER5_NS then
     sprite_p.nofalling := 1;
    sprite_p.moveSpeed := 6 shl FRACBITS;
    sprite_p.angle := angle;
    sprite_p.active := active;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.rotate := rt_eight;
    sprite_p.basepic := CA_GetNamedNum('kboss');
    DemandLoadMonster(sprite_p.basepic,48);
    sprite_p.startpic := sprite_p.basepic;
    sprite_p.movesize := 49 shl FRACBITS;
    sprite_p.intelligence := 10;
    sprite_p.hitpoints := 10000;
    sprite_p.type := S_MONSTER5;
    sprite_p.height := 59 shl FRACBITS;
    sprite_p.score := 30000;
    sprite_p.bullet := S_MONSTERBULLET5;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 1;
    break;
   S_MONSTER6_NS: // pboss
   S_MONSTER6:
    sprite_p := RF_GetSprite;
    if value = S_MONSTER6_NS then
     sprite_p.nofalling := 1;
    sprite_p.moveSpeed := 7 shl FRACBITS;
    sprite_p.angle := angle;
    sprite_p.active := active;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.rotate := rt_eight;
    sprite_p.basepic := CA_GetNamedNum('pboss');
    DemandLoadMonster(sprite_p.basepic,56);
    sprite_p.startpic := sprite_p.basepic;
    sprite_p.movesize := 26 shl FRACBITS;
    sprite_p.intelligence := 10;
    sprite_p.heat := 8;
    sprite_p.hitpoints := 5000;
    sprite_p.type := S_MONSTER6;
    sprite_p.height := 120 shl FRACBITS;
    sprite_p.score := 15000;
    sprite_p.bullet := S_MONSTERBULLET6;
    mapsprites[mapspot] := 1;
    break;
   S_MONSTER7_NS: // pst
   S_MONSTER7:
    sprite_p := RF_GetSprite;
    if value = S_MONSTER7_NS then
     sprite_p.nofalling := 1;
    sprite_p.moveSpeed := 4 shl FRACBITS;
    sprite_p.angle := angle;
    sprite_p.active := active;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.rotate := rt_eight;
    sprite_p.basepic := CA_GetNamedNum('pst');
    DemandLoadMonster(sprite_p.basepic,56);
    sprite_p.startpic := sprite_p.basepic;
    sprite_p.movesize := 26 shl FRACBITS;
    sprite_p.intelligence := 10;
    sprite_p.heat := 8;
    sprite_p.hitpoints := 150;
    sprite_p.type := S_MONSTER7;
    sprite_p.height := 59 shl FRACBITS;
    sprite_p.score := 300;
    sprite_p.bullet := S_MONSTERBULLET7;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 1;
    break;

   S_MONSTER8_NS:   // guard
   S_MONSTER8:
    sprite_p := RF_GetSprite;
    if value = S_MONSTER8_NS then
     sprite_p.nofalling := 1;
    sprite_p.moveSpeed := 4 shl FRACBITS;
    sprite_p.angle := angle;
    sprite_p.active := active;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.rotate := rt_eight;
    sprite_p.basepic := CA_GetNamedNum('guard');
    DemandLoadMonster(sprite_p.basepic,56);
    sprite_p.startpic := sprite_p.basepic;
    sprite_p.movesize := 26 shl FRACBITS;
    sprite_p.intelligence := 5;
    sprite_p.hitpoints := 350;
    sprite_p.type := S_MONSTER8;
    sprite_p.height := 59 shl FRACBITS;
    sprite_p.score := 700;
    sprite_p.bullet := S_MONSTERBULLET8;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 1;
    break;
   S_MONSTER9_NS:  // trooper
   S_MONSTER9:
    sprite_p := RF_GetSprite;
    if value = S_MONSTER9_NS then
     sprite_p.nofalling := 1;
    sprite_p.moveSpeed := 4 shl FRACBITS;
    sprite_p.angle := angle;
    sprite_p.active := active;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.rotate := rt_eight;
    sprite_p.basepic := CA_GetNamedNum('trooper');
    DemandLoadMonster(sprite_p.basepic,56);
    sprite_p.startpic := sprite_p.basepic;
    sprite_p.movesize := 26 shl FRACBITS;
    sprite_p.intelligence := 5;
    sprite_p.heat := 24;
    sprite_p.hitpoints := 80;
    sprite_p.type := S_MONSTER9;
    sprite_p.height := 59 shl FRACBITS;
    sprite_p.score := 160;
    sprite_p.bullet := S_MONSTERBULLET9;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 1;
    break;
   S_MONSTER10_NS:  // prisoner
   S_MONSTER10:
    sprite_p := RF_GetSprite;
    if (value = S_MONSTER10_NS) sprite_p.nofalling := 1;
    sprite_p.moveSpeed := 4 shl FRACBITS;
    sprite_p.angle := angle;
    sprite_p.active := active;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.rotate := rt_eight;
    sprite_p.basepic := CA_GetNamedNum('prisoner');
    DemandLoadMonster(sprite_p.basepic,56);
    sprite_p.startpic := sprite_p.basepic;
    sprite_p.movesize := 26 shl FRACBITS;
    sprite_p.intelligence := 8;
    sprite_p.heat := 16;
    sprite_p.hitpoints := 20;
    sprite_p.type := S_MONSTER10;
    sprite_p.height := 59 shl FRACBITS;
    sprite_p.score := 40;
    sprite_p.bullet := S_MONSTERBULLET10;
    sprite_p.scale := 1;
    sprite_p.enraged := 10;
    mapsprites[mapspot] := 1;
    break;
   S_MONSTER11_NS:  // big guard
   S_MONSTER11:
    sprite_p := RF_GetSprite;
    if value = S_MONSTER11_NS then
     sprite_p.nofalling := 1;
    sprite_p.moveSpeed := 3 shl FRACBITS;
    sprite_p.angle := angle;
    sprite_p.active := active;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.rotate := rt_eight;
    sprite_p.basepic := CA_GetNamedNum('bigguard');
    DemandLoadMonster(sprite_p.basepic,48);
    sprite_p.startpic := sprite_p.basepic;
    sprite_p.movesize := 31 shl FRACBITS;
    sprite_p.intelligence := 9;
    sprite_p.heat := 300;
    sprite_p.hitpoints := 1200;
    sprite_p.score := 10000;
    sprite_p.type := S_MONSTER11;
    sprite_p.height := 128 shl FRACBITS;
    sprite_p.bullet := S_MONSTERBULLET11;
    sprite_p.deathevent := 255;
    mapsprites[mapspot] := 1;
    break;

   S_MONSTER12_NS: // pss
   S_MONSTER12:
    sprite_p := RF_GetSprite;
    if value = S_MONSTER12_NS then
     sprite_p.nofalling := 1;
    sprite_p.moveSpeed := 4 shl FRACBITS;
    sprite_p.angle := angle;
    sprite_p.active := active;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.rotate := rt_eight;
    sprite_p.basepic := CA_GetNamedNum('pss');
    DemandLoadMonster(sprite_p.basepic,56);
    sprite_p.startpic := sprite_p.basepic;
    sprite_p.movesize := 26 shl FRACBITS;
    sprite_p.intelligence := 10;
    sprite_p.heat := 8;
    sprite_p.hitpoints := 90;
    sprite_p.type := S_MONSTER12;
    sprite_p.height := 59 shl FRACBITS;
    sprite_p.score := 180;
    sprite_p.bullet := S_MONSTERBULLET12;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 1;
    break;
   S_MONSTER13_NS: // kwiz
   S_MONSTER13:
    sprite_p := RF_GetSprite;
    if value = S_MONSTER13_NS then
     sprite_p.nofalling := 1;
    sprite_p.moveSpeed := 4 shl FRACBITS;
    sprite_p.angle := angle;
    sprite_p.active := active;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.rotate := rt_eight;
    sprite_p.basepic := CA_GetNamedNum('wiz');
    DemandLoadMonster(sprite_p.basepic,56);
    sprite_p.startpic := sprite_p.basepic;
    sprite_p.movesize := 26 shl FRACBITS;
    sprite_p.intelligence := 10;
    sprite_p.heat := 8;
    sprite_p.hitpoints := 300;
    sprite_p.type := S_MONSTER13;
    sprite_p.height := 59 shl FRACBITS;
    sprite_p.score := 600;
    sprite_p.bullet := S_MONSTERBULLET13;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 1;
    break;
   S_MONSTER14_NS: // veek
   S_MONSTER14:
    sprite_p := RF_GetSprite;
    if value = S_MONSTER14_NS then
     sprite_p.nofalling := 1;
    sprite_p.moveSpeed := 4 shl FRACBITS;
    sprite_p.angle := angle;
    sprite_p.active := active;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.rotate := rt_eight;
    sprite_p.basepic := CA_GetNamedNum('veek');
    DemandLoadMonster(sprite_p.basepic,56);
    sprite_p.startpic := sprite_p.basepic;
    sprite_p.movesize := 26 shl FRACBITS;
    sprite_p.intelligence := 10;
    sprite_p.heat := 8;
    sprite_p.hitpoints := 350;
    sprite_p.type := S_MONSTER14;
    sprite_p.height := 59 shl FRACBITS;
    sprite_p.score := 700;
    sprite_p.bullet := S_MONSTERBULLET14;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 1;
    break;
   S_MONSTER15_NS: // tboss
   S_MONSTER15:
    sprite_p := RF_GetSprite;
    if value = S_MONSTER15_NS then
     sprite_p.nofalling := 1;
    sprite_p.moveSpeed := 7 shl FRACBITS;
    sprite_p.angle := angle;
    sprite_p.active := active;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.rotate := rt_eight;
    sprite_p.basepic := CA_GetNamedNum('tboss');
    DemandLoadMonster(sprite_p.basepic,56);
    sprite_p.startpic := sprite_p.basepic;
    sprite_p.movesize := 26 shl FRACBITS;
    sprite_p.intelligence := 10;
    sprite_p.heat := 8;
    sprite_p.hitpoints := 3000;
    sprite_p.type := S_MONSTER15;
    sprite_p.height := 59 shl FRACBITS;
    sprite_p.score := 15000;
    sprite_p.bullet := S_MONSTERBULLET15;
    mapsprites[mapspot] := 1;
    break;


  (* bonus item *********************************************************)
   S_BONUSITEM:
    sprite_p := RF_GetSprite;
    sprite_p.angle := angle;
    sprite_p.active := false;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('randitem');
    sprite_p.type := S_BONUSITEM;
    mapsprites[mapspot] := SM_BONUSITEM;
    break;


  (* items **************************************************************)
   S_ITEM2:
   S_ITEM3:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := RF_GetCeilingZ(x,y)-(20 shl FRACBITS) - RF_GetFloorZ(x,y);
    sprite_p.z := RF_GetFloorZ(x,y)+sprite_p.zadj;
    sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := value;
    mapsprites[mapspot] := 0;
    break;
  S_ITEM8:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := RF_GetCeilingZ(x,y)-(39 shl FRACBITS) - RF_GetFloorZ(x,y);
    sprite_p.z := RF_GetFloorZ(x,y)+sprite_p.zadj;
    sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := value;
    mapsprites[mapspot] := 0;
    break;
  S_ITEM10:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := RF_GetCeilingZ(x,y)-(33 shl FRACBITS) - RF_GetFloorZ(x,y);
    sprite_p.z := RF_GetFloorZ(x,y)+sprite_p.zadj;
    sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := value;
    mapsprites[mapspot] := 0;
    break;
   S_ITEM11:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := RF_GetCeilingZ(x,y)-(73 shl FRACBITS) - RF_GetFloorZ(x,y);
    sprite_p.z := RF_GetFloorZ(x,y)+sprite_p.zadj;
    sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := value;
    mapsprites[mapspot] := 0;
    break;
   S_ITEM12:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := RF_GetCeilingZ(x,y)-(35 shl FRACBITS) - RF_GetFloorZ(x,y);
    sprite_p.z := RF_GetFloorZ(x,y)+sprite_p.zadj;
    sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := value;
    mapsprites[mapspot] := 0;
    break;
   S_ITEM13:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := RF_GetCeilingZ(x,y)-(65 shl FRACBITS) - RF_GetFloorZ(x,y);
    sprite_p.z := RF_GetFloorZ(x,y)+sprite_p.zadj;
    sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := value;
    mapsprites[mapspot] := 0;
    break;
   S_ITEM20:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := RF_GetCeilingZ(x,y)-(91 shl FRACBITS) - RF_GetFloorZ(x,y);
    sprite_p.z := RF_GetFloorZ(x,y)+sprite_p.zadj;
    sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := value;
    mapsprites[mapspot] := 0;
    break;
   S_ITEM23:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := RF_GetCeilingZ(x,y)-(121 shl FRACBITS) - RF_GetFloorZ(x,y);
    sprite_p.z := RF_GetFloorZ(x,y)+sprite_p.zadj;
    sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := value;
    mapsprites[mapspot] := 0;
    break;
   S_ITEM30:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := RF_GetCeilingZ(x,y)-(40 shl FRACBITS) - RF_GetFloorZ(x,y);
    sprite_p.z := RF_GetFloorZ(x,y)+sprite_p.zadj;
    sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := value;
    mapsprites[mapspot] := 0;
    break;
   S_ITEM31:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := RF_GetCeilingZ(x,y)-(39 shl FRACBITS) - RF_GetFloorZ(x,y);
    sprite_p.z := RF_GetFloorZ(x,y)+sprite_p.zadj;
    sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := value;
    mapsprites[mapspot] := 0;
    break;
   S_ITEM32:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := RF_GetCeilingZ(x,y)-(36 shl FRACBITS) - RF_GetFloorZ(x,y);
    sprite_p.z := RF_GetFloorZ(x,y)+sprite_p.zadj;
    sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := value;
    mapsprites[mapspot] := 0;
    break;
   S_ITEM33:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := RF_GetCeilingZ(x,y)-(51 shl FRACBITS) - RF_GetFloorZ(x,y);
    sprite_p.z := RF_GetFloorZ(x,y)+sprite_p.zadj;
    sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := value;
    mapsprites[mapspot] := 0;
    break;
   S_ITEM34:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.zadj := RF_GetCeilingZ(x,y)-(49 shl FRACBITS) - RF_GetFloorZ(x,y);
    sprite_p.z := RF_GetFloorZ(x,y)+sprite_p.zadj;
    sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := value;
    mapsprites[mapspot] := 0;
    break;
   S_ITEM1:
   S_ITEM4:
   S_ITEM5:
   S_ITEM6:
   S_ITEM7:
   S_ITEM9:
   S_ITEM14:
   S_ITEM15:
   S_ITEM16:
   S_ITEM17:
   S_ITEM18:
   S_ITEM19:
   S_ITEM21:
   S_ITEM22:
   S_ITEM24:
   S_ITEM25:
   S_ITEM26:
   S_ITEM27:
   S_ITEM28:
   S_ITEM29:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('miscobj') + (value - S_ITEM1);
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := value;
    sprite_p.height := 48 shl FRACBITS;
    mapsprites[mapspot] := 2;
    break;

   S_WEAPON0:
   S_WEAPON1:
   S_WEAPON2:
   S_WEAPON3:
   S_WEAPON4:
   S_WEAPON5:
   S_WEAPON6:
   S_WEAPON7:
   S_WEAPON8:
   S_WEAPON9:
   S_WEAPON10:
   S_WEAPON11:
   S_WEAPON12:
   S_WEAPON13:
   S_WEAPON14:
   S_WEAPON15:
   S_WEAPON16:
   S_WEAPON17:
   S_WEAPON18:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('weapons')+value-S_WEAPON0;
    sprite_p.type := value;
    mapsprites[mapspot] := value - S_WEAPON0 + SM_WEAPON0;
    break;

   S_MEDPAK1:
   S_MEDPAK2:
   S_MEDPAK3:
   S_MEDPAK4:
   S_ENERGY:
   S_BALLISTIC:
   S_PLASMA:
   S_SHIELD1:
   S_SHIELD2:
   S_SHIELD3:
   S_SHIELD4:
   S_IPROXMINE:
   S_ITIMEMINE:
   S_IREVERSO:
   S_IGRENADE:
   S_IDECOY:
   S_IINSTAWALL:
   S_ICLONE:
   S_IHOLO:
   S_IINVIS:
   S_IJAMMER:
   S_ISTEALER:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('medtube1') + (value-S_MEDPAK1)*4;
    sprite_p.type := value;
    sprite_p.animation := 1 + (0 shl 1) + (4 shl 5) + (10 shl 9);
    mapsprites[mapspot] := (value-S_MEDPAK1) + SM_MEDPAK1;
    if (netmode) and ( not gameloading) then
     NetSendSpawn(value,x,y,z,zadj,angle,angle2,active,spawnid);
    break;

   S_AMMOBOX:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('ammobox');
    sprite_p.type := S_AMMOBOX;
    mapsprites[mapspot] := SM_AMMOBOX;
    break;
   S_MEDBOX:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('autodoc');
    sprite_p.type := S_MEDBOX;
    mapsprites[mapspot] := SM_MEDBOX;
    break;
   S_GOODIEBOX:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('toolchest');
    sprite_p.type := S_GOODIEBOX;
    mapsprites[mapspot] := SM_GOODIEBOX;
    break;


   S_GENERATOR:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := slumps[value-S_START];
    sprite_p.type := value;
    sprite_p.animation := 1 + (0 shl 1) + (4 shl 5) + (10 shl 9);
    break;

   S_DEADMONSTER1:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('kman') + 55;
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := S_DEADMONSTER1;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 0;
    break;
   S_DEADMONSTER2:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('kfem') + 55;
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := S_DEADMONSTER2;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 0;
    break;
   S_DEADMONSTER3:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('kprob') + 55;
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := S_DEADMONSTER3;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 0;
    break;
   S_DEADMONSTER4:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('kbot') + 55;
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := S_DEADMONSTER4;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 0;
    break;
   S_DEADMONSTER5:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('kboss') + 55;
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := S_DEADMONSTER5;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 0;
    break;

   S_DEADMONSTER6:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('pboss') + 55;
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := S_DEADMONSTER6;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 0;
    break;
   S_DEADMONSTER7:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('pst') + 55;
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := S_DEADMONSTER7;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 0;
    break;

   S_DEADMONSTER8:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('guard') + 55;
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := S_DEADMONSTER8;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 0;
    break;
   S_DEADMONSTER9:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('trooper') + 55;
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := S_DEADMONSTER9;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 0;
    break;
   S_DEADMONSTER10:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('prisoner') + 55;
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := S_DEADMONSTER10;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 0;
    break;
   S_DEADMONSTER11:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('bigguard') + 55;
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := S_DEADMONSTER11;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 0;
    break;

   S_DEADMONSTER12:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('pss') + 55;
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := S_DEADMONSTER12;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 0;
    break;
   S_DEADMONSTER13:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('wiz') + 55;
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := S_DEADMONSTER13;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 0;
    break;
   S_DEADMONSTER14:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('veek') + 55;
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := S_DEADMONSTER14;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 0;
    break;
   S_DEADMONSTER15:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('tboss') + 55;
    DemandLoadMonster(sprite_p.basepic,1);
    sprite_p.type := S_DEADMONSTER15;
    sprite_p.scale := 1;
    mapsprites[mapspot] := 0;
    break;

  (* primary/secondary ****************************************************)
   S_PRIMARY1:
   S_PRIMARY2:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('primary') + primaries[(value-S_PRIMARY1)*2];
    sprite_p.type := value;
    mapsprites[mapspot] := (value-S_PRIMARY1)+SM_PRIMARY1;
    sprite_p.score := primaries[(value-S_PRIMARY1)*2 + 1];
    break;
   S_SECONDARY1:
   S_SECONDARY2:
   S_SECONDARY3:
   S_SECONDARY4:
   S_SECONDARY5:
   S_SECONDARY6:
   S_SECONDARY7:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('secondary') + secondaries[(value-S_SECONDARY1)*2];
    sprite_p.type := value;
    mapsprites[mapspot] := (value-S_SECONDARY1)+SM_SECONDARY1;
    sprite_p.score := secondaries[(value-S_SECONDARY1)*2 + 1];
    break;

  (* players **************************************************************)
   S_PLAYER: // player
    startlocations[0][0] := x1;
    startlocations[0][1] := y1;
    if (player.x = -1) and (((netmode) and (greedcom.consoleplayer = 0)) or ( not netmode)) then
    begin
      player.x := x;
      player.y := y;
      player.z := RF_GetFloorZ(player.x,player.y)+player.height;
      player.mapspot := mapspot;
      player.angle := NORTH;
       end;
    mapsprites[mapspot] := 0;
    break;
   S_NETPLAYER2:
   S_NETPLAYER3:
   S_NETPLAYER4:
   S_NETPLAYER5:
   S_NETPLAYER6:
   S_NETPLAYER7:
   S_NETPLAYER8:
    if (floorpic[mapspot] = 0) or (ceilingpic[mapspot] = 0) MS_Error('Invalid start %i at %i,%i',value,x1,y1);
    startlocations[value-1][0] := x1;
    startlocations[value-1][1] := y1;
    if (netmode) and (greedcom.consoleplayer = value-1) and (player.x = -1) then
    begin
      player.x := x;
      player.y := y;
      player.z := RF_GetFloorZ(player.x,player.y)+player.height;
      player.mapspot := mapspot;
      player.angle := NORTH;
       end;
    mapsprites[mapspot] := 0;
    break;

  (* doors *************************************************************)
   S_VDOOR1: // vertical door 1
    door_p := RF_GetDoor(x1,y1);
    if (mapflags[mapspot-MAPCOLS]) and (FL_DOOR) door_p.orientation := dr_vertical2;
     else door_p.orientation := dr_vertical;
    door_p.doorBumpable := true;
    door_p.doorSize := 64;
    door_p.position := door_p.doorSize*FRACUNIT;
    door_p.pic := CA_GetNamedNum('door_1') - walllump;
    door_p.doorTimer := player.timecount;
    mapsprites[mapspot] := 0;
    break;
   S_HDOOR1: // horizontal door 1
    door_p := RF_GetDoor(x1,y1);
    if (mapflags[mapspot-1]) and (FL_DOOR) door_p.orientation := dr_horizontal2;
     else door_p.orientation := dr_horizontal;
    door_p.doorBumpable := true;
    door_p.doorSize := 64;
    door_p.position := door_p.doorSize*FRACUNIT;
    door_p.doorTimer := player.timecount;
    door_p.pic := CA_GetNamedNum('door_1') - walllump;
    mapsprites[mapspot] := 0;
    break;
   S_VDOOR2: // vertical door 2
    door_p := RF_GetDoor(x1,y1);
    if (mapflags[mapspot-MAPCOLS]) and (FL_DOOR) door_p.orientation := dr_vertical2;
     else door_p.orientation := dr_vertical;
    door_p.doorBumpable := true;
    door_p.doorSize := 64;
    door_p.position := door_p.doorSize*FRACUNIT;
  //   door_p.transparent := true;
    door_p.doorTimer := player.timecount;
    door_p.pic := CA_GetNamedNum('door_2') - walllump;
    mapsprites[mapspot] := 0;
    break;
   S_HDOOR2: // horizontal door 2
    door_p := RF_GetDoor(x1,y1);
    if (mapflags[mapspot-1]) and (FL_DOOR) door_p.orientation := dr_horizontal2;
     else door_p.orientation := dr_horizontal;
    door_p.doorBumpable := true;
    door_p.doorSize := 64;
    door_p.position := door_p.doorSize*FRACUNIT;
  //   door_p.transparent := true;
    door_p.doorTimer := player.timecount;
    door_p.pic := CA_GetNamedNum('door_2') - walllump;
    mapsprites[mapspot] := 0;
    break;
   S_VDOOR3: // vertical door 3
    door_p := RF_GetDoor(x1,y1);
    if (mapflags[mapspot-MAPCOLS]) and (FL_DOOR) door_p.orientation := dr_vertical2;
     else door_p.orientation := dr_vertical;
    door_p.doorBumpable := true;
    door_p.doorSize := 64;
    door_p.position := door_p.doorSize*FRACUNIT;
    door_p.doorTimer := player.timecount;
    door_p.pic := CA_GetNamedNum('door_3') - walllump;
    mapsprites[mapspot] := 0;
    break;
   S_HDOOR3: // horizontal door 3
    door_p := RF_GetDoor(x1,y1);
    if (mapflags[mapspot-1]) and (FL_DOOR) door_p.orientation := dr_horizontal2;
     else door_p.orientation := dr_horizontal;
    door_p.doorBumpable := true;
    door_p.doorSize := 64;
    door_p.position := door_p.doorSize*FRACUNIT;
    door_p.doorTimer := player.timecount;
    door_p.pic := CA_GetNamedNum('door_3') - walllump;
    mapsprites[mapspot] := 0;
    break;
   S_VDOOR4: // vertical door 4
    door_p := RF_GetDoor(x1,y1);
    if (mapflags[mapspot-MAPCOLS]) and (FL_DOOR) door_p.orientation := dr_vertical2;
     else door_p.orientation := dr_vertical;
    door_p.doorBumpable := true;
    door_p.doorSize := 64;
    door_p.position := door_p.doorSize*FRACUNIT;
    door_p.doorTimer := player.timecount;
    door_p.pic := CA_GetNamedNum('door_4') - walllump;
    mapsprites[mapspot] := 0;
    break;
   S_HDOOR4: // horizontal door 4
    door_p := RF_GetDoor(x1,y1);
    if (mapflags[mapspot-1]) and (FL_DOOR) door_p.orientation := dr_horizontal2;
     else door_p.orientation := dr_horizontal;
    door_p.doorBumpable := true;
    door_p.doorSize := 64;
    door_p.position := door_p.doorSize*FRACUNIT;
    door_p.doorTimer := player.timecount;
    door_p.pic := CA_GetNamedNum('door_4') - walllump;
    mapsprites[mapspot] := 0;
    break;
   S_VDOOR5: // vertical door 5
    door_p := RF_GetDoor(x1,y1);
    if (mapflags[mapspot-MAPCOLS]) and (FL_DOOR) door_p.orientation := dr_vertical2;
     else door_p.orientation := dr_vertical;
    door_p.doorBumpable := true;
    door_p.doorSize := 64;
    door_p.position := door_p.doorSize*FRACUNIT;
    door_p.pic := CA_GetNamedNum('door_5') - walllump;
    door_p.doorTimer := player.timecount;
    mapsprites[mapspot] := 0;
    break;
   S_HDOOR5: // horizontal door 5
    door_p := RF_GetDoor(x1,y1);
    if (mapflags[mapspot-1]) and (FL_DOOR) door_p.orientation := dr_horizontal2;
     else door_p.orientation := dr_horizontal;
    door_p.doorBumpable := true;
    door_p.doorSize := 64;
    door_p.position := door_p.doorSize*FRACUNIT;
    door_p.doorTimer := player.timecount;
    door_p.pic := CA_GetNamedNum('door_5') - walllump;
    mapsprites[mapspot] := 0;
    break;
   S_VDOOR6: // vertical door 6
    door_p := RF_GetDoor(x1,y1);
    if (mapflags[mapspot-MAPCOLS]) and (FL_DOOR) door_p.orientation := dr_vertical2;
     else door_p.orientation := dr_vertical;
    door_p.doorBumpable := true;
    door_p.doorSize := 64;
    door_p.position := door_p.doorSize*FRACUNIT;
    door_p.pic := CA_GetNamedNum('door_6') - walllump;
    door_p.doorTimer := player.timecount;
    mapsprites[mapspot] := 0;
    break;
   S_HDOOR6: // horizontal door 6
    door_p := RF_GetDoor(x1,y1);
    if (mapflags[mapspot-1]) and (FL_DOOR) door_p.orientation := dr_horizontal2;
     else door_p.orientation := dr_horizontal;
    door_p.doorBumpable := true;
    door_p.doorSize := 64;
    door_p.position := door_p.doorSize*FRACUNIT;
    door_p.doorTimer := player.timecount;
    door_p.pic := CA_GetNamedNum('door_6') - walllump;
    mapsprites[mapspot] := 0;
    break;
   S_VDOOR7: // vertical door 7
    door_p := RF_GetDoor(x1,y1);
    if (mapflags[mapspot-MAPCOLS]) and (FL_DOOR) door_p.orientation := dr_vertical2;
     else door_p.orientation := dr_vertical;
    door_p.doorBumpable := true;
    door_p.doorSize := 64;
    door_p.position := door_p.doorSize*FRACUNIT;
    door_p.pic := CA_GetNamedNum('door_7') - walllump;
    door_p.doorTimer := player.timecount;
    mapsprites[mapspot] := 0;
    break;
   S_HDOOR7: // horizontal door 7
    door_p := RF_GetDoor(x1,y1);
    if (mapflags[mapspot-1]) and (FL_DOOR) door_p.orientation := dr_horizontal2;
     else door_p.orientation := dr_horizontal;
    door_p.doorBumpable := true;
    door_p.doorSize := 64;
    door_p.position := door_p.doorSize*FRACUNIT;
    door_p.doorTimer := player.timecount;
    door_p.pic := CA_GetNamedNum('door_7') - walllump;
    mapsprites[mapspot] := 0;
    break;

  (* elevators ***********************************************************)
   S_ELEVATOR: // normal elevator
    elevator_p := RF_GetElevator;
    elevator_p.elevUp := true;
    elevator_p.floor := floorheight[mapspot];
    elevator_p.mapspot := mapspot;
    mapsprites[mapspot] := 0;
    maxheight := floorheight[mapspot];
    for(i := y1-1;i <= y1+1;i++)
     for(j := x1-1;j <= x1+1;j++)
     begin
       mapspot := i*MAPCOLS+j;
       if floorheight[mapspot]>maxheight then
  maxheight := floorheight[mapspot];
        end;
    elevator_p.ceiling := maxheight;
    elevator_p.position := maxheight;
    elevator_p.type := E_NORMAL;
    elevator_p.elevTimer := player.timecount;
    elevator_p.speed := 8;
    floorheight[elevator_p.mapspot] := maxheight;
    break;
   S_PAUSEDELEVATOR: // these don't move yet
    elevator_p := RF_GetElevator;
    elevator_p.floor := floorheight[mapspot];
    elevator_p.mapspot := mapspot;
    mapsprites[mapspot] := 0;
    maxheight := floorheight[mapspot];
    for(i := y1-1;i <= y1+1;i++)
     for(j := x1-1;j <= x1+1;j++)
     begin
       mapspot := i*MAPCOLS+j;
       if floorheight[mapspot]>maxheight then
  maxheight := floorheight[mapspot];
        end;
    elevator_p.ceiling := maxheight;
    elevator_p.position := maxheight;
    elevator_p.type := E_NORMAL;
    elevator_p.elevTimer := $70000000;
    elevator_p.speed := 8;
    floorheight[elevator_p.mapspot] := maxheight;
    break;
   S_SWAPSWITCH:
    mapsprites[mapspot] := SM_SWAPSWITCH;
    break;
   S_ELEVATORLOW:
    elevator_p := RF_GetElevator;
    elevator_p.position := floorheight[mapspot];
    elevator_p.floor := floorheight[mapspot];
    elevator_p.mapspot := mapspot;
    mapsprites[mapspot] := 0;
    elevator_p.ceiling := ceilingheight[mapspot];
    elevator_p.type := E_SWAP;
    elevator_p.speed := 8;
    elevator_p.elevTimer := $70000000;
    break;
   S_ELEVATORHIGH:
    elevator_p := RF_GetElevator;
    elevator_p.floor := floorheight[mapspot];
    elevator_p.mapspot := mapspot;
    mapsprites[mapspot] := 0;
    elevator_p.ceiling := ceilingheight[mapspot];
    elevator_p.position := ceilingheight[mapspot];
    floorheight[mapspot] := elevator_p.position;
    elevator_p.type := E_SWAP;
    elevator_p.speed := 8;
    elevator_p.elevTimer := $70000000;
    break;
   S_ELEVATOR3M: // 3 min elevator
    elevator_p := RF_GetElevator;
    elevator_p.elevDown := true;
    elevator_p.position := ceilingheight[mapspot];
    elevator_p.floor := floorheight[mapspot];
    elevator_p.ceiling := ceilingheight[mapspot];
    floorheight[mapspot] := ceilingheight[mapspot];
    elevator_p.mapspot := mapspot;
    elevator_p.type := E_TIMED;
    elevator_p.elevTimer := 12600;
    elevator_p.speed := 8;
    mapsprites[mapspot] := SM_ELEVATOR;
    break;
   S_ELEVATOR6M: // 6 min elevator
    elevator_p := RF_GetElevator;
    elevator_p.elevDown := true;
    elevator_p.position := ceilingheight[mapspot];
    elevator_p.floor := floorheight[mapspot];
    elevator_p.ceiling := ceilingheight[mapspot];
    floorheight[mapspot] := ceilingheight[mapspot];
    elevator_p.mapspot := mapspot;
    elevator_p.type := E_TIMED;
    elevator_p.elevTimer := 25200;
    elevator_p.speed := 8;
    mapsprites[mapspot] := SM_ELEVATOR;
    break;
   S_ELEVATOR15M: // 15 min elevator
    elevator_p := RF_GetElevator;
    elevator_p.elevDown := true;
    elevator_p.position := ceilingheight[mapspot];
    elevator_p.floor := floorheight[mapspot];
    elevator_p.ceiling := ceilingheight[mapspot];
    floorheight[mapspot] := ceilingheight[mapspot];
    elevator_p.mapspot := mapspot;
    elevator_p.type := E_TIMED;
    elevator_p.elevTimer := 63000;
    elevator_p.speed := 8;
    mapsprites[mapspot] := SM_ELEVATOR;
    break;

   S_TRIGGER1: // trigger 1
    mapsprites[mapspot] := SM_SWITCHDOWN;
    break;
   S_TRIGGERD1: // trigger door 1
    elevator_p := RF_GetElevator;
    elevator_p.position := ceilingheight[mapspot];
    elevator_p.floor := floorheight[mapspot];
    elevator_p.ceiling := ceilingheight[mapspot];
    elevator_p.mapspot := mapspot;
    elevator_p.type := E_SWITCHDOWN;
    elevator_p.speed := 8;
    elevator_p.elevTimer := $70000000;
    mapsprites[mapspot] := SM_ELEVATOR;
    floorheight[mapspot] := elevator_p.position;
    break;
   S_TRIGGER2: // trigger 2
    mapsprites[mapspot] := SM_SWITCHDOWN2;
    break;
   S_TRIGGERD2: // trigger door 2
    elevator_p := RF_GetElevator;
    elevator_p.position := ceilingheight[mapspot];
    elevator_p.floor := floorheight[mapspot];
    elevator_p.ceiling := ceilingheight[mapspot];
    elevator_p.mapspot := mapspot;
    elevator_p.type := E_SWITCHDOWN2;
    elevator_p.speed := 8;
    elevator_p.elevTimer := $70000000;
    mapsprites[mapspot] := SM_ELEVATOR;
    floorheight[mapspot] := elevator_p.position;
    break;
   S_STRIGGER:
    mapsprites[mapspot] := SM_STRIGGER;
    break;
   S_SDOOR:
    elevator_p := RF_GetElevator;
    elevator_p.floor := floorheight[mapspot];
    elevator_p.mapspot := mapspot;
    elevator_p.ceiling := ceilingheight[mapspot];
    elevator_p.position := ceilingheight[mapspot];
    elevator_p.type := E_SECRET;
    elevator_p.elevTimer := $70000000;
    elevator_p.speed := 8;
    mapsprites[mapspot] := 0;
    floorheight[mapspot] := ceilingheight[mapspot];
    break;

  (* warps ***************************************************************)
   S_WARP1: // warp 1
    mapsprites[mapspot] := SM_WARP1;   // mapsprites>128 := > ignore (clear movement)
    break;
   S_WARP2: // warp 2
    mapsprites[mapspot] := SM_WARP2;
    break;
   S_WARP3: // warp 3
    mapsprites[mapspot] := SM_WARP3;
    break;

  (* misc ****************************************************************)

   S_SOLID:
    break;

  (* generators *********************************************************)

   S_GENERATOR1:
   S_GENERATOR2:
    sa := RF_GetSpawnArea;
    sa.mapx := (x1 shl FRACTILESHIFT) + (32 shl FRACBITS);
    sa.mapy := (y1 shl FRACTILESHIFT) + (32 shl FRACBITS);
    sa.mapspot := mapspot;
    sa.time := player.timecount + ((MS_RndT) and (15) shl 6);
    sa.type := value-S_GENERATOR1;
    SpawnSprite(S_GENERATOR,(fixed_t)(x1*MAPSIZE+32) shl FRACBITS,(fixed_t)(y1*MAPCOLS+32) shl FRACBITS,0,0,MS_RndT*4,0,false,0);
    mapsprites[mapspot] := 0;
    break;

   S_SPAWN1:
   S_SPAWN2:
   S_SPAWN3:
   S_SPAWN4:
   S_SPAWN5:
   S_SPAWN6:
   S_SPAWN7:
   S_SPAWN8:
   S_SPAWN9:
   S_SPAWN10:
   S_SPAWN11:
   S_SPAWN12:
   S_SPAWN13:
   S_SPAWN14:
   S_SPAWN15:
    if not nospawn then
    begin
      sa := RF_GetSpawnArea;
      sa.mapx := (x1 shl FRACTILESHIFT) + (32 shl FRACBITS);
      sa.mapy := (y1 shl FRACTILESHIFT) + (32 shl FRACBITS);
      sa.mapspot := mapspot;
      sa.time := player.timecount + ((MS_RndT) and (15) shl 6);
      sa.type := value - S_SPAWN1 + 10;
       end;
    mapsprites[mapspot] := 0;
    break;
   S_SPAWN8_NS:
   S_SPAWN9_NS:
    if not nospawn then
    begin
      sa := RF_GetSpawnArea;
      sa.mapx := (x1 shl FRACTILESHIFT) + (32 shl FRACBITS);
      sa.mapy := (y1 shl FRACTILESHIFT) + (32 shl FRACBITS);
      sa.mapspot := mapspot;
      sa.time := player.timecount + ((MS_RndT) and (15) shl 6);
      sa.type := value - S_SPAWN8_NS + 100;
       end;
    mapsprites[mapspot] := 0;
    break;


   S_EXIT:
    sprite_p := RF_GetSprite;
    sprite_p.x := x;
    sprite_p.y := y;
    sprite_p.z := RF_GetFloorZ(x,y);
    sprite_p.basepic := CA_GetNamedNum('exitwarp');
    sprite_p.type := S_EXIT;
    sprite_p.animation := 1 + (0 shl 1) + (8 shl 5) + (5 shl 9);
    mapsprites[mapspot] := SM_EXIT;
    exitexists := true;
    exitx := x1;
    exity := y1;
    break;

    end;
  if (midgetmode) and (sprite_p) then
  sprite_p.scale++;
  return sprite_p;
  end;

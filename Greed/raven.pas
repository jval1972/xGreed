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

#include <DOS.H>
#include <STDIO.H>
#include <STDLIB.H>
#include <STRING.H>
#include <MATH.H>
#include <TIME.H>
#include 'd_global.h'
#include 'd_disk.h'
#include 'd_misc.h'
#include 'd_video.h'
#include 'd_ints.h'
#include 'r_refdef.h'
#include 'd_font.h'
#include 'protos.h'

(**** VARIABLES ****)

#define PLAYERMOVESPEED   FRACUNIT*2.5
#define MOVEUNIT          FRACUNIT
#define FALLUNIT          FRACUNIT
#define MAXAMMO           300
#define DEFAULTVRDIST     157286
#define DEFAULTVRANGLE    4

player_t player;
byte     resizeScreen, biggerScreen, warpActive, currentViewSize := 0;
longint  keyboardDelay, frames, weapdelay, spritemovetime, secretdelay,
   RearViewTime, RearViewDelay, inventorytime;
font_t   *font1, *font2, *font3;
pic_t    *weaponpic[7], *statusbar[4];
byte     *backdrop;
byte     *backdroplookup[256];
bool  changingweapons, weaponlowering, quitgame, togglemapmode,
   toggleheatmode, heatmode, godmode, togglemotionmode, motionmode,
   hurtborder, recording, playback, activatemenu, specialcode,
   debugmode, gameloaded, nospawn, doorsound, deadrestart, ticker,
   togglegoalitem, waterdrop, gamepause, ExitLevel, exitexists, warpjammer,
   paused, QuickExit, autorun, ToggleRearView, RearViewOn, checktrigger,
   activatehelp, useitem, toggleautorun, goiright, goileft, activatebrief,
   midgetmode, autotarget := 1, toggleautotarget, adjustvrangle;
float   adjustvrdist;
int      weapmode, newweapon, weaponychange, headbob, weapbob, moveforward,
   changelight, lighting, wbobcount, turnrate, mapmode, secretindex,
   scrollview, doorx, doory, MapZoom, Warping, goalitem, specialeffect,
   falldamage, netmode, wallanimcount, netmsgindex, netmsgstatus,
   playerturnspeed := 8, turnunit := 2, exitx, exity, songnum, enemyviewmode;
  moverate, strafrate, fallrate, WarpX, WarpY: fixed_t;
longint  wallanimationtime, recordindex, netsendtime, specialeffecttime,
   SwitchTime, nethurtsoundtime;
byte     *demobuffer;
byte     demokb[NUMCODES];
char     secretbuf[30];
char     netmsg[30];
byte     rearbuf[64*64];
bonus_t  BonusItem;
  SaveTheScreen, redo, newsong: boolean;

extern entry_t   entries[1024], *entry_p;
extern int       frameon, rtimecount;
extern SoundCard SC;
extern int       fliplayed;
extern void      (*timerhook2);

(**** FUNCTIONS ****)

procedure selectsong(int num);

procedure CheckElevators;
begin
  elevobj_t *elev_p;
  time: integer;
  floorz, newfloorz: fixed_t;

  floorz := RF_GetFloorZ(player.x,player.y)+player.height;
  time := timecount;
  for(elev_p := firstelevobj.next;elev_p <> @lastelevobj;elev_p := elev_p.next)
  while time >= elev_p.elevTimer do
  begin
    if (elev_p.elevUp) and ((elev_p.position+:= elev_p.speed) >= elev_p.ceiling) then
    begin
      SoundEffect(SN_ELEVATORSTART,15,(elev_p.mapspot) and (63) shl FRACTILESHIFT,(elev_p.mapspot shr 6) shl FRACTILESHIFT);
      elev_p.position := elev_p.ceiling;
      if (elev_p.type = E_NORMAL) elev_p.elevDown := true;
       else if (elev_p.type <> E_SWAP) and (elev_p.type <> E_SECRET) then
       begin
   if elev_p.endeval then
    Event(elev_p.endeval,false);
   floorheight[elev_p.mapspot] := elev_p.position;
   if mapsprites[elev_p.mapspot] = SM_ELEVATOR then
    mapsprites[elev_p.mapspot] := 0;
   elev_p := elev_p.prev;
   RF_RemoveElevator(elev_p.next);
   break;
    end;
      elev_p.elevUp := false;
      elev_p.elevTimer := elev_p.elevTimer + 280;
    end
    else if (elev_p.elevDown) and ((elev_p.position-:= elev_p.speed) <= elev_p.floor) then
    begin
      SoundEffect(SN_ELEVATORSTART,15,(elev_p.mapspot) and (63) shl FRACTILESHIFT,(elev_p.mapspot shr 6) shl FRACTILESHIFT);
      elev_p.position := elev_p.floor;
      if (elev_p.type = E_NORMAL) or (elev_p.type = E_SECRET) elev_p.elevUp := true;
       else if elev_p.type <> E_SWAP then
       begin
   if elev_p.endeval then
    Event(elev_p.endeval,false);
   floorheight[elev_p.mapspot] := elev_p.position;
   if mapsprites[elev_p.mapspot] = SM_ELEVATOR then
    mapsprites[elev_p.mapspot] := 0;
   elev_p := elev_p.prev;
   RF_RemoveElevator(elev_p.next);
   break;
    end;
      elev_p.elevDown := false;
      elev_p.elevTimer := elev_p.elevTimer + 280;
       end;
    if (elev_p.type = E_SECRET) and (elev_p.elevUp) then
    begin
      if (player.mapspot = elev_p.mapspot) or (mapsprites[elev_p.mapspot]) elev_p.position := elev_p.floor;
       end;
    if (mapsprites[elev_p.mapspot] = SM_ELEVATOR) mapsprites[elev_p.mapspot] := 0;
    floorheight[elev_p.mapspot] := elev_p.position;
    elev_p.elevTimer := elev_p.elevTimer + MOVEDELAY;
     end;
  newfloorz := RF_GetFloorZ(player.x,player.y)+player.height;
  if newfloorz <> floorz then
  begin
   if player.z>newfloorz then
   begin
     fallrate := fallrate + FALLUNIT;
     player.z := player.z - fallrate;
     if (player.z<newfloorz) player.z := newfloorz;
   end
   else if player.z<newfloorz then
   begin
     player.z := newfloorz;
     fallrate := 0;
      end;
    end;
  end;


int GetTargetAngle(int n, fixed_t pz)
begin
  scaleobj_t *hsprite;
  counter, mapspot, result, x, y, z, d, accuracy: integer;
  found: boolean;
  sz: fixed_t;

  if not autotarget then
  return (-player.scrollmin)) and (ANGLES;
  accuracy := 16; //16 + 2*player.difficulty;
  counter := 0;
  found := false;
  msprite := @probe;
  probe.x := player.x;
  probe.y := player.y;
  probe.z := player.z;
  probe.angle := player.angle+n;
  probe.zadj := player.height;
  probe.startspot := (player.y shr FRACTILESHIFT)*MAPCOLS+(player.x shr FRACTILESHIFT);
  while counter++<MAXPROBE do
  begin
   result := SP_Thrust;
   if result = 1 then
   begin
     for(hsprite := firstscaleobj.next;hsprite <> @lastscaleobj;hsprite := hsprite.next)
      if hsprite.hitpoints then
      begin
  mapspot := (hsprite.y shr FRACTILESHIFT)*MAPCOLS+(hsprite.x shr FRACTILESHIFT);
  if mapspot = spriteloc then
  begin
    found := true;
    counter := MAXPROBE;
    break;
     end;
   end;
      end;
    end;
  if not found then
  begin
   counter := 0;
   msprite := @probe;
   probe.x := player.x;
   probe.y := player.y;
   probe.z := player.z;
   probe.angle := player.angle+n+accuracy;
   probe.zadj := player.height;
   probe.startspot := (player.y shr FRACTILESHIFT)*MAPCOLS+(player.x shr FRACTILESHIFT);
   while counter++<MAXPROBE do
   begin
     result := SP_Thrust;
     if result = 1 then
     begin
       for(hsprite := firstscaleobj.next;hsprite <> @lastscaleobj;hsprite := hsprite.next)
  if hsprite.hitpoints then
  begin
    mapspot := (hsprite.y shr FRACTILESHIFT)*MAPCOLS+(hsprite.x shr FRACTILESHIFT);
    if mapspot = spriteloc then
    begin
      found := true;
      player.angle := player.angle + accuracy;
      counter := MAXPROBE;
      break;
       end;
     end;
        end;
      end;
    end;
  if not found then
  begin
   counter := 0;
   msprite := @probe;
   probe.x := player.x;
   probe.y := player.y;
   probe.z := player.z;
   probe.angle := player.angle+n-accuracy;
   probe.zadj := player.height;
   probe.startspot := (player.y shr FRACTILESHIFT)*MAPCOLS+(player.x shr FRACTILESHIFT);
   while counter++<MAXPROBE do
   begin
     result := SP_Thrust;
     if result = 1 then
     begin
       for(hsprite := firstscaleobj.next;hsprite <> @lastscaleobj;hsprite := hsprite.next)
  if hsprite.hitpoints then
  begin
    mapspot := (hsprite.y shr FRACTILESHIFT)*MAPCOLS+(hsprite.x shr FRACTILESHIFT);
    if mapspot = spriteloc then
    begin
      found := true;
      player.angle := player.angle - accuracy;
      counter := MAXPROBE;
      break;
       end;
     end;
        end;
      end;
    end;
  if not found then
  begin
   counter := 0;
   msprite := @probe;
   probe.x := player.x;
   probe.y := player.y;
   probe.z := player.z;
   probe.angle := player.angle+n+accuracy/2;
   probe.zadj := player.height;
   probe.startspot := (player.y shr FRACTILESHIFT)*MAPCOLS+(player.x shr FRACTILESHIFT);
   while counter++<MAXPROBE do
   begin
     result := SP_Thrust;
     if result = 1 then
     begin
       for(hsprite := firstscaleobj.next;hsprite <> @lastscaleobj;hsprite := hsprite.next)
  if hsprite.hitpoints then
  begin
    mapspot := (hsprite.y shr FRACTILESHIFT)*MAPCOLS+(hsprite.x shr FRACTILESHIFT);
    if mapspot = spriteloc then
    begin
      found := true;
      player.angle := player.angle + accuracy/2;
      counter := MAXPROBE;
      break;
       end;
     end;
        end;
      end;
    end;
  if not found then
  begin
   counter := 0;
   msprite := @probe;
   probe.x := player.x;
   probe.y := player.y;
   probe.z := player.z;
   probe.angle := player.angle+n-accuracy/2;
   probe.zadj := player.height;
   probe.startspot := (player.y shr FRACTILESHIFT)*MAPCOLS+(player.x shr FRACTILESHIFT);
   while counter++<MAXPROBE do
   begin
     result := SP_Thrust;
     if result = 1 then
     begin
       for(hsprite := firstscaleobj.next;hsprite <> @lastscaleobj;hsprite := hsprite.next)
  if hsprite.hitpoints then
  begin
    mapspot := (hsprite.y shr FRACTILESHIFT)*MAPCOLS+(hsprite.x shr FRACTILESHIFT);
    if mapspot = spriteloc then
    begin
      found := true;
      player.angle := player.angle - accuracy/2;
      counter := MAXPROBE;
      break;
       end;
     end;
        end;
      end;
    end;
  if found then
  begin
   pz := pz + player.z;
   sz := hsprite.z+(hsprite.height/2);
   if sz>pz then
   begin
     z := (sz-pz) shr (FRACBITS+2);
     if (z >= MAXAUTO) return (-player.scrollmin)) and (ANGLES;
     x := (hsprite.x-player.x) shr (FRACBITS+2);
     y := (hsprite.y-player.y) shr (FRACBITS+2);
     d := (int)sqrt(x*x + y*y);
     if (d >= MAXAUTO) or (autoangle2[d][z] = -1) return (-player.scrollmin)) and (ANGLES;
     return autoangle2[d][z];
   end
   else if sz<pz then
   begin
     z := (pz-sz) shr (FRACBITS+2);
     if (z >= MAXAUTO) return (-player.scrollmin)) and (ANGLES;
     x := (hsprite.x-player.x) shr (FRACBITS+2);
     y := (hsprite.y-player.y) shr (FRACBITS+2);
     d := (int)sqrt(x*x + y*y);
     if (d >= MAXAUTO) or (autoangle2[d][z] = -1) return (-player.scrollmin)) and (ANGLES;
     return -autoangle2[d][z];
      end;
   else return (-player.scrollmin)) and (ANGLES;
    end;
  else return (-player.scrollmin)) and (ANGLES;
  end;


procedure fireweapon;
begin
// scaleobj_t *hsprite;
// int        px, py, sx, sy, xmove, ymove, spriteloc1, spriteloc2, mapspot;
  i, n, angle2, ammo, angle, angleinc, oldangle: integer;
  z, xmove2, ymove2: fixed_t;

  player.status := 2;
  n := player.weapons[player.currentweapon];
  ammo := weapons[n].ammorate;
  if (player.ammo[weapons[n].ammotype]<ammo) exit;
  oldangle := player.angle;
  weapons[n].charge := 0;
  player.ammo[weapons[n].ammotype] := player.ammo[weapons[n].ammotype] - ammo;
  if (n <> 4) and (n <> 18) and (weapmode <> 1) weapmode := 1;
  case n  of
  begin
   13: // mooman #1
    z := player.height-(fixed_t)(50 shl FRACBITS);
    SpawnSprite(S_HANDBULLET,player.x,player.y,player.z,z,player.angle,GetTargetAngle(0,z),true,playernum);
    SoundEffect(SN_BULLET13,0,player.x,player.y);
    if (netmode) NetSoundEffect(SN_BULLET13,0,player.x,player.y);
    break;
   8: // lizard #1
   14: // specimen #1
   15: // trix #1
    z := player.height-(fixed_t)(50 shl FRACBITS);
    SpawnSprite(S_HANDBULLET,player.x,player.y,player.z,z,player.angle,GetTargetAngle(0,z),true,playernum);
    SoundEffect(SN_BULLET8,0,player.x,player.y);
    if (netmode) NetSoundEffect(SN_BULLET8,0,player.x,player.y);
    break;
   1: // psyborg #2
    z := player.height-(52 shl FRACBITS);
    angle2 := GetTargetAngle(0,z);
    SpawnSprite(S_BULLET1,player.x,player.y,player.z,z,player.angle,angle2,true,playernum);
    SoundEffect(SN_BULLET1,0,player.x,player.y);
    if (netmode) NetSoundEffect(SN_BULLET1,0,player.x,player.y);
    break;
   2:
    z := player.height-(fixed_t)(50 shl FRACBITS);
    SpawnSprite(S_BULLET2,player.x,player.y,player.z,z,player.angle,GetTargetAngle(0,z),true,playernum);
    SoundEffect(SN_BULLET5,0,player.x,player.y);
    if (netmode) NetSoundEffect(SN_BULLET5,0,player.x,player.y);
    break;
   3:
    z := player.height-(fixed_t)(50 shl FRACBITS);
    SpawnSprite(S_BULLET3,player.x,player.y,player.z,z,player.angle,GetTargetAngle(0,z),true,playernum);
    SoundEffect(SN_BULLET3,0,player.x,player.y);
    if (netmode) NetSoundEffect(SN_BULLET3,0,player.x,player.y);
    break;
   4:
    z := player.height-(fixed_t)(50 shl FRACBITS);
    SpawnSprite(S_BULLET4,player.x,player.y,player.z,z,player.angle-48,GetTargetAngle(-16,z),true,playernum);
    SpawnSprite(S_BULLET4,player.x,player.y,player.z,z,player.angle-24,GetTargetAngle(-32,z),true,playernum);
    SpawnSprite(S_BULLET4,player.x,player.y,player.z,z,player.angle,GetTargetAngle(0,z),true,playernum);
    SpawnSprite(S_BULLET4,player.x,player.y,player.z,z,player.angle+24,GetTargetAngle(+16,z),true,playernum);
    SpawnSprite(S_BULLET4,player.x,player.y,player.z,z,player.angle+48,GetTargetAngle(+32,z),true,playernum);
    break;
   5:

    break;
   6:
    break;
   7: // psyborg #1
    z := player.height-(52 shl FRACBITS);
    angle2 := GetTargetAngle(0,z);
    SpawnSprite(S_BULLET7,player.x,player.y,player.z,z,player.angle,angle2,true,playernum);
    SoundEffect(SN_BULLET13,0,player.x,player.y);
    if (netmode) NetSoundEffect(SN_BULLET13,0,player.x,player.y);
    break;
   9: // lizard #2
    z := player.height-(52 shl FRACBITS);
    angle2 := GetTargetAngle(0,z);
    SpawnSprite(S_BULLET9,player.x,player.y,player.z,z,player.angle,angle2,true,playernum);
    SoundEffect(SN_BULLET9,0,player.x,player.y);
    if (netmode) NetSoundEffect(SN_BULLET1,0,player.x,player.y);
    break;
   10: // specimen #2
    z := player.height-(52 shl FRACBITS);
    angle2 := GetTargetAngle(0,z);
    SpawnSprite(S_BULLET10,player.x,player.y,player.z,z,player.angle,angle2,true,playernum);
    SoundEffect(SN_BULLET10,0,player.x,player.y);
    if (netmode) NetSoundEffect(SN_BULLET10,0,player.x,player.y);
    break;
   11: // mooman #2
    z := player.height-(52 shl FRACBITS);
    angle2 := GetTargetAngle(0,z);
    SpawnSprite(S_BULLET11,player.x,player.y,player.z,z,player.angle,angle2,true,playernum);
    SoundEffect(SN_BULLET1,0,player.x,player.y);
    if (netmode) NetSoundEffect(SN_BULLET1,0,player.x,player.y);
    break;
   12: // dominatrix #2
    angle := (player.angle-NORTH)) and (ANGLES;
    xmove2 := FIXEDMUL(FRACUNIT*4,costable[angle]);
    ymove2 := -FIXEDMUL(FRACUNIT*4,sintable[angle]);
    z := player.height-(fixed_t)(50 shl FRACBITS);
    SpawnSprite(S_BULLET12,player.x+xmove2,player.y+ymove2,player.z,z,player.angle,GetTargetAngle(0,z),true,playernum);
    angle := (player.angle+NORTH)) and (ANGLES;
    xmove2 := FIXEDMUL(FRACUNIT*4,costable[angle]);
    ymove2 := -FIXEDMUL(FRACUNIT*4,sintable[angle]);
    z := player.height-(fixed_t)(50 shl FRACBITS);
    SpawnSprite(S_BULLET12,player.x+xmove2,player.y+ymove2,player.z,z,player.angle,GetTargetAngle(0,z),true,playernum);
    SoundEffect(SN_BULLET12,0,player.x,player.y);
    if (netmode) NetSoundEffect(SN_BULLET12,0,player.x,player.y);
    break;

   16: // red gun
    angle := (player.angle-NORTH)) and (ANGLES;
    xmove2 := FIXEDMUL(FRACUNIT*4,costable[angle]);
    ymove2 := -FIXEDMUL(FRACUNIT*4,sintable[angle]);
    z := player.height-(fixed_t)(50 shl FRACBITS);
    SpawnSprite(S_BULLET16,player.x+xmove2,player.y+ymove2,player.z,z,player.angle,GetTargetAngle(0,z),true,playernum);
    angle := (player.angle+NORTH)) and (ANGLES;
    xmove2 := FIXEDMUL(FRACUNIT*4,costable[angle]);
    ymove2 := -FIXEDMUL(FRACUNIT*4,sintable[angle]);
    z := player.height-(fixed_t)(50 shl FRACBITS);
    SpawnSprite(S_BULLET16,player.x+xmove2,player.y+ymove2,player.z,z,player.angle,GetTargetAngle(0,z),true,playernum);
    SoundEffect(SN_BULLET12,0,player.x,player.y);
    if (netmode) NetSoundEffect(SN_BULLET12,0,player.x,player.y);
    break;

   17: // blue gun
    z := player.height-(64 shl FRACBITS);
    angle2 := GetTargetAngle(0,z);
    SpawnSprite(S_BULLET17,player.x,player.y,player.z,z,player.angle,angle2,true,playernum);
    SoundEffect(SN_BULLET17,0,player.x,player.y);
    if (netmode) NetSoundEffect(SN_BULLET1,0,player.x,player.y);
    break;

   18: // green gun
    angleinc := ANGLES/12;
    angle := 0;
    for(i := 0;i<12;i++,angle+:= angleinc)
    begin
      z := player.height-(52 shl FRACBITS);
      angle2 := GetTargetAngle(0,z);
      SpawnSprite(S_BULLET18,player.x,player.y,player.z,z,angle,angle2,true,playernum);
       end;
    if netmode then
     NetSendSpawn(S_BULLET18,player.x,player.y,player.z,z,angle,angle2,true,playernum);
    break;
    end;
  player.angle := oldangle;
  end;


bool FindWarpDestination(int *x, int *y,byte warpValue)
begin
  search, nosearch: integer;

  nosearch := *y*MAPSIZE+*x;
  if not warpActive then
  begin
   for(search := 0;search<MAPROWS*MAPCOLS;search++)
    if (mapsprites[search] = warpValue) and (search <> nosearch) then
    begin
      *x := search) and ((MAPSIZE-1);
      *y := search shr TILESHIFT;
      turnrate := 0;
      moverate := 0;
      fallrate := 0;
      strafrate := 0;
      ResetMouse;
      warpActive := warpValue;
      return true;
       end;
    end;
  return false;
  end;


procedure CheckItems(int centerx,int centery,bool useit,int chartype);
begin
  scaleobj_t *sprite;
  mapspot, value, value2, index, ammo, cmapspot: integer;
  x, y, i, j: integer;
  elevobj_t  *elev_p;
  sound: boolean;

  mapspot := centery*MAPCOLS+centerx;
  value := mapsprites[mapspot];
  case value  of
  begin
   SM_MEDPAK1:
   SM_MEDPAK2:
   SM_MEDPAK3:
   SM_MEDPAK4:
    value2 := value-SM_MEDPAK1+S_MEDPAK1;
    for (sprite := firstscaleobj.next; sprite <> @lastscaleobj;sprite := sprite.next)
     if (sprite.x shr FRACTILESHIFT = centerx) and (sprite.y shr FRACTILESHIFT = centery) then
      if sprite.type = value2 then
      begin
  if (useit) and (netmode) NetItemPickup(centerx,centery);
  mapsprites[mapspot] := 0;
  SoundEffect(SN_PICKUP0+chartype,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
  if useit then
  begin
    if player.angst = player.maxangst then
    begin
      player.inventory[0]+:= 5-(value-SM_MEDPAK1);
      if (player.inventory[0]>20) player.inventory[0] := 20;
      oldinventory := -2;
      inventoryleft;
      inventoryright;
      writemsg('Stored MedTube!');
       end;
    else
    begin
      medpaks((5-(value-SM_MEDPAK1))*50);
      writemsg('Used MedTube!');
       end;
     end;
  SpawnSprite(S_GENERATOR,sprite.x,sprite.y,0,0,0,0,false,0);
  RF_RemoveSprite(sprite);
  exit;
   end;
    break;

   SM_SHIELD1:
   SM_SHIELD2:
   SM_SHIELD3:
   SM_SHIELD4:
    value2 := value-SM_MEDPAK1+S_MEDPAK1;
    for (sprite := firstscaleobj.next; sprite <> @lastscaleobj;sprite := sprite.next)
     if (sprite.x shr FRACTILESHIFT = centerx) and (sprite.y shr FRACTILESHIFT = centery) then
      if sprite.type = value2 then
      begin
  if (useit) and (netmode) NetItemPickup(centerx,centery);
  mapsprites[mapspot] := 0;
  SoundEffect(SN_PICKUP0+chartype,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
  if useit then
  begin
    if player.shield = player.maxshield then
    begin
      player.inventory[1]+:= 1+(value-SM_SHIELD1);
      if (player.inventory[1]>20) player.inventory[1] := 20;
      oldinventory := -2;
      inventoryleft;
      inventoryright;
      writemsg('Stored Shield Charge!');
       end;
    else
    begin
      heal((1+(value-SM_SHIELD1))*50);
      writemsg('Used Shield Charge!');
       end;
     end;
  SpawnSprite(S_GENERATOR,sprite.x,sprite.y,0,0,0,0,false,0);
  RF_RemoveSprite(sprite);
  exit;
   end;
    break;

   SM_ENERGY:
   SM_BALLISTIC:
   SM_PLASMA:
    value2 := value-SM_ENERGY+S_ENERGY;
    for (sprite := firstscaleobj.next;sprite <> @lastscaleobj;sprite := sprite.next)
     if (sprite.x shr FRACTILESHIFT = centerx) and (sprite.y shr FRACTILESHIFT = centery) then
      if sprite.type = value2 then
      begin
  if (useit) and (netmode) then
   NetItemPickup(centerx,centery);
  mapsprites[mapspot] := 0;
  SoundEffect(SN_PICKUP0+chartype,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
  if useit then
  begin
    hurtborder := true;
    player.ammo[value-SM_ENERGY]+:= 75;
    if player.ammo[value-SM_ENERGY]>MAXAMMO then
     player.ammo[value-SM_ENERGY] := MAXAMMO;
    oldshots := -1;
    writemsg(pickupammomsg[value-SM_ENERGY]);
     end;
  SpawnSprite(S_GENERATOR,sprite.x,sprite.y,0,0,0,0,false,0);
  RF_RemoveSprite(sprite);
  exit;
   end;
    break;

   SM_AMMOBOX:
    value2 := weapons[player.weapons[player.currentweapon]].ammotype;
    if (useit) and ((player.ammo[value2] >= MAXAMMO) or (
     (weapons[player.currentweapon].ammorate = 0) and (
      player.ammo[0] >= MAXAMMO) and (player.ammo[1] >= MAXAMMO) and (
      player.ammo[2] >= MAXAMMO)))
     exit;
    for (sprite := firstscaleobj.next;sprite <> @lastscaleobj;sprite := sprite.next)
     if (sprite.x shr FRACTILESHIFT = centerx) and (sprite.y shr FRACTILESHIFT = centery) then
      if sprite.type = S_AMMOBOX then
      begin
  if (useit) and (netmode) then
   NetItemPickup(centerx,centery);
  mapsprites[mapspot] := 0;
  SoundEffect(SN_PICKUP0+chartype,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
  if useit then
  begin
    hurtborder := true;
    if weapons[player.currentweapon].ammorate = 0 then
    begin
      player.ammo[0] := player.ammo[0] + 45;
      if player.ammo[0]>MAXAMMO then
       player.ammo[0] := MAXAMMO;
      player.ammo[1] := player.ammo[1] + 45;
      if player.ammo[1]>MAXAMMO then
       player.ammo[1] := MAXAMMO;
      player.ammo[2] := player.ammo[2] + 45;
      if player.ammo[2]>MAXAMMO then
       player.ammo[2] := MAXAMMO;
       end;
    else
    begin
      player.ammo[value2] := player.ammo[value2] + 125;
      if player.ammo[value2]>MAXAMMO then
       player.ammo[value2] := MAXAMMO;
       end;
    oldshots := -1;
    writemsg(pickupmsg[11]);
     end;
  if sprite.deathevent then
   Event(sprite.deathevent,false);
  RF_RemoveSprite(sprite);
  exit;
   end;
    break;
   SM_MEDBOX:
    if (useit) and (player.angst = player.maxangst) and (player.shield = player.maxshield) then
     exit;
    for (sprite := firstscaleobj.next;sprite <> @lastscaleobj;sprite := sprite.next)
     if (sprite.x shr FRACTILESHIFT = centerx) and (sprite.y shr FRACTILESHIFT = centery) then
      if sprite.type = S_MEDBOX then
      begin
  if (useit) and (netmode) then
   NetItemPickup(centerx,centery);
  mapsprites[mapspot] := 0;
  SoundEffect(SN_PICKUP0+chartype,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
  if useit then
  begin
    heal(250);
    medpaks(250);
    hurtborder := true;
    writemsg(pickupmsg[12]);
     end;
  if sprite.deathevent then
   Event(sprite.deathevent,false);
  RF_RemoveSprite(sprite);
  exit;
   end;
    break;
   SM_GOODIEBOX:
    for (sprite := firstscaleobj.next;sprite <> @lastscaleobj;sprite := sprite.next)
     if (sprite.x shr FRACTILESHIFT = centerx) and (sprite.y shr FRACTILESHIFT = centery) then
      if sprite.type = S_GOODIEBOX then
      begin
  if (useit) and (netmode) then
   NetItemPickup(centerx,centery);
  mapsprites[mapspot] := 0;
  SoundEffect(SN_PICKUP0+chartype,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
  if useit then
  begin
    for (i := 0;i<2;i++)
    begin
      if netmode then
       do
       begin
         value2 := (clock+MS_RndT) mod 11;
          end; while (value2 <> 8);
      else
       do
       begin
         value2 := (clock+MS_RndT) mod 11;
          end; while (value2 <> 6) and (value2 <> 10) and (value2 <> 12);
      player.inventory[value2+2]+:= pickupamounts[value2];
      if value2 = 2 then
      begin
        if player.inventory[2]>15 then
         player.inventory[2] := 15;
      end
      else if (player.inventory[value2+2]>10)
       player.inventory[value2+2] := 10;
       end;
    oldinventory := -2;
    inventoryleft;
    inventoryright;
    hurtborder := true;
    writemsg(pickupmsg[13]);
     end;
  if sprite.deathevent then
   Event(sprite.deathevent,false);
  RF_RemoveSprite(sprite);
  exit;
   end;
    break;

   SM_IGRENADE:
   SM_IREVERSO:
   SM_IPROXMINE:
   SM_ITIMEMINE:
   SM_IDECOY:
   SM_IINSTAWALL:
   SM_ICLONE:
   SM_IHOLO:
   SM_IINVIS:
   SM_IJAMMER:
   SM_ISTEALER:
    value2 := value-SM_IGRENADE+S_IGRENADE;
    for (sprite := firstscaleobj.next;sprite <> @lastscaleobj;sprite := sprite.next)
     if (sprite.x shr FRACTILESHIFT = centerx) and (sprite.y shr FRACTILESHIFT = centery) then
      if sprite.type = value2 then
      begin
  if (useit) and (netmode) then
   NetItemPickup(centerx,centery);
  mapsprites[mapspot] := 0;
  SoundEffect(SN_PICKUP0+chartype,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
  if useit then
  begin
    hurtborder := true;
    player.inventory[value-SM_IGRENADE+2]+:= pickupamounts[value-SM_IGRENADE];
    if value = SM_IGRENADE then
    begin
      if player.inventory[2]>15 then
       player.inventory[2] := 15;
    end
    else if (player.inventory[value-SM_IGRENADE+2]>10)
     player.inventory[value-SM_IGRENADE+2] := 10;
    writemsg(pickupmsg[value-SM_IGRENADE]);
    oldinventory := -2;
    inventoryleft;
    inventoryright;
     end;
  SpawnSprite(S_GENERATOR,sprite.x,sprite.y,0,0,0,0,false,0);
  RF_RemoveSprite(sprite);
  exit;
   end;
    break;
(*   SM_HOLE:
    if (useit) and (player.inventory[10] >= 10) exit;
    for (sprite := firstscaleobj.next;sprite <> @lastscaleobj;sprite := sprite.next)
     if (sprite.x shr FRACTILESHIFT = centerx) and (sprite.y shr FRACTILESHIFT = centery) then
      if sprite.type = S_HOLE then
      begin
  if (useit) and (netmode) NetItemPickup(centerx,centery);
  mapsprites[mapspot] := 0;
  SoundEffect(SN_PICKUP0+chartype,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
  if useit then
  begin
    hurtborder := true;
    ++player.inventory[10];
    writemsg('Portable Hole picked up!');
    oldinventory := -2;
    inventoryleft;
    inventoryright;
     end;
  RF_RemoveSprite(sprite);
  exit;
   end;
    break; *)

   SM_BONUSITEM:
    if useit then
    begin
      if (netmode) NetItemPickup(centerx,centery);
      addscore(BonusItem.score);
      heal(150);
      medpaks(150);
      hurtborder := true;
      writemsg('Bonus Item!');
       end;
    BonusItem.score := 0;
    BonusItem.mapspot := -1;
    RF_RemoveSprite(BonusItem.sprite);
    mapsprites[mapspot] := 0;
    SoundEffect(SN_WEAPPICKUP0+chartype,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
    BonusItem.name := NULL;
    break;

   SM_PRIMARY1:
   SM_PRIMARY2:
    value2 := mapsprites[mapspot]-SM_PRIMARY1 + S_PRIMARY1;
    for (sprite := firstscaleobj.next; sprite <> @lastscaleobj;sprite := sprite.next)
     if (sprite.x shr FRACTILESHIFT = centerx) and (sprite.y shr FRACTILESHIFT = centery) then
      if sprite.type = value2 then
      begin
  if (useit) and (netmode) NetItemPickup(centerx,centery);
  RF_RemoveSprite(sprite);
  mapsprites[mapspot] := 0;
  SoundEffect(SN_WEAPPICKUP0+chartype,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
  if useit then
  begin
    heal(150);
    medpaks(150);
    hurtborder := true;
    addscore(primaries[(value2-S_PRIMARY1)*2 + 1]);
    writemsg('Primary goal item!');
    player.primaries[value2-S_PRIMARY1]++;
     end;
  exit;
   end;
    break;
   SM_SECONDARY1:
   SM_SECONDARY2:
   SM_SECONDARY3:
   SM_SECONDARY4:
   SM_SECONDARY5:
   SM_SECONDARY6:
   SM_SECONDARY7:
    value2 := mapsprites[mapspot]-SM_SECONDARY1 + S_SECONDARY1;
    for (sprite := firstscaleobj.next; sprite <> @lastscaleobj;sprite := sprite.next)
     if (sprite.x shr FRACTILESHIFT = centerx) and (sprite.y shr FRACTILESHIFT = centery) and (sprite.type = value2) then
     begin
       if (useit) and (netmode) then
  NetItemPickup(centerx,centery);
       RF_RemoveSprite(sprite);
       mapsprites[mapspot] := 0;
       SoundEffect(SN_WEAPPICKUP0+chartype,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
       if useit then
       begin
   heal(150);
   medpaks(150);
   hurtborder := true;
   addscore(secondaries[(value2-S_SECONDARY1)*2 + 1]);
   writemsg('Secondary goal item!');
   player.secondaries[value2-S_SECONDARY1]++;
    end;
       exit;
        end;
    break;

   SM_SWITCHDOWN:
    sound := false;
    for(elev_p := firstelevobj.next;elev_p <> @lastelevobj;elev_p := elev_p.next)
     if (elev_p.type = E_SWITCHDOWN) and ( not elev_p.elevDown) then
     begin
       elev_p.elevDown := true;
       elev_p.elevTimer := timecount;
       sound := true;
       SoundEffect(SN_ELEVATORSTART,15,(elev_p.mapspot) and (63) shl FRACTILESHIFT,(elev_p.mapspot shr 6) shl FRACTILESHIFT);
        end;
    if (useit) and (netmode) NetItemPickup(centerx,centery);
    mapsprites[mapspot] := 0;
    if (useit) and (sound) then
    begin
      SoundEffect(SN_TRIGGER,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
      if (netmode) NetSoundEffect(SN_TRIGGER,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
      SoundEffect(SN_TRIGGER,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
      if (netmode) NetSoundEffect(SN_TRIGGER,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
       end;
    break;
   SM_SWITCHDOWN2:
    if (useit) and (netmode) NetItemPickup(centerx,centery);
    sound := false;
    for(elev_p := firstelevobj.next;elev_p <> @lastelevobj;elev_p := elev_p.next)
     if (elev_p.type = E_SWITCHDOWN2) and ( not elev_p.elevDown) then
     begin
       elev_p.elevDown := true;
       elev_p.elevTimer := timecount;
       SoundEffect(SN_ELEVATORSTART,15,(elev_p.mapspot) and (63) shl FRACTILESHIFT,(elev_p.mapspot shr 6) shl FRACTILESHIFT);
       sound := true;
        end;
    if (useit) and (netmode) NetItemPickup(centerx,centery);
    mapsprites[mapspot] := 0;
    if (sound) SoundEffect(SN_TRIGGER,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
    break;
   SM_SWITCHUP:
    if (useit) and (netmode) NetItemPickup(centerx,centery);
    sound := false;
    for(elev_p := firstelevobj.next;elev_p <> @lastelevobj;elev_p := elev_p.next)
     if (elev_p.type = E_SWITCHUP) and ( not elev_p.elevUp) then
     begin
       elev_p.elevUp := true;
       elev_p.elevTimer := timecount;
       sound := true;
       SoundEffect(SN_ELEVATORSTART,15,(elev_p.mapspot) and (63) shl FRACTILESHIFT,(elev_p.mapspot shr 6) shl FRACTILESHIFT);
        end;
    if (useit) and (netmode) NetItemPickup(centerx,centery);
    mapsprites[mapspot] := 0;
    if (sound) SoundEffect(SN_TRIGGER,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
    break;

   SM_EXIT:
    ExitLevel := true;
    break;

   SM_WEAPON0:
   SM_WEAPON1:
   SM_WEAPON2:
   SM_WEAPON3:
   SM_WEAPON4:
   SM_WEAPON5:
   SM_WEAPON6:
   SM_WEAPON7:
   SM_WEAPON8:
   SM_WEAPON9:
   SM_WEAPON10:
   SM_WEAPON11:
   SM_WEAPON12:
   SM_WEAPON13:
   SM_WEAPON14:
   SM_WEAPON15:
   SM_WEAPON16:
   SM_WEAPON17:
   SM_WEAPON18:
    value2 := value-SM_WEAPON0;
    ammo := weapons[value2].ammotype;
    index := ammo+2;

    if (player.weapons[index] = value2) and ( not netmode) then
    begin
      player.ammo[ammo] := player.ammo[ammo] + 100;
      if (player.ammo[ammo]>MAXAMMO) player.ammo[ammo] := MAXAMMO;
      writemsg('Found more ammo.');
    end
    else if (player.weapons[index] <> -1) and ( not netmode) then
    begin
      for(i := -MAPCOLS;i <= MAPCOLS;i+:= MAPCOLS)
       for(j := -1;j <= 1;j++)
       begin
   cmapspot := mapspot+i+j;
   if (cmapspot <> mapspot) and (floorpic[cmapspot]) and (mapsprites[cmapspot] = 0) then
   begin
     x := (cmapspot) and (63)*MAPSIZE+32;
     y := (cmapspot/64)*MAPSIZE+32;
     SpawnSprite(player.weapons[index]+S_WEAPON0,x shl FRACBITS,y shl FRACBITS,0,0,0,0,0,0);
     i := MAPCOLS*2;
     j := 1;
     break;
      end;
    end;
      if player.currentweapon = index then
      begin
  weaponlowering := false;
  newweapon := index;
  loadweapon(value2);
  weaponychange := weaponpic[0].height-20;
  changingweapons := true;
   end;
      else
      begin
  changingweapons := true;
  weaponlowering := true;
  newweapon := index;
   end;
      writemsg('Exchanged weapons!');
    end
    else if not netmode then
    begin
      writemsg('Acquired new weapon!');
      changingweapons := true;
      weaponlowering := true;
      newweapon := index;
       end;
    if netmode then
    begin
      if player.weapons[index] = value2 then
       exit;
      writemsg('Acquired new weapon!');
      player.weapons[index] := value-SM_WEAPON0;
      player.ammo[ammo] := player.ammo[ammo] + 100;
      if (player.ammo[ammo]>MAXAMMO) player.ammo[ammo] := MAXAMMO;
      SoundEffect(SN_WEAPPICKUP0+chartype,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
      NetSoundEffect(SN_WEAPPICKUP0+chartype,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
      changingweapons := true;
      weaponlowering := true;
      newweapon := index;
       end;
    else
    begin
      value2 := value-SM_WEAPON0+S_WEAPON0;
      for (sprite := firstscaleobj.next;sprite <> @lastscaleobj;sprite := sprite.next)
       if (sprite.x shr FRACTILESHIFT = centerx) and (sprite.y shr FRACTILESHIFT = centery) then
  if sprite.type = value2 then
  begin
    player.weapons[index] := value-SM_WEAPON0;
    value2 := weapons[player.weapons[index]].ammotype;
    hurtborder := true;
    RF_RemoveSprite(sprite);
    mapsprites[mapspot] := 0;
    SoundEffect(SN_WEAPPICKUP0+chartype,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
    exit;
     end;
       end;
    break;
    end;
  end;


procedure CheckWarps(fixed_t centerx,fixed_t centery);
begin
  x, y, mapspot: integer;

  x := centerx shr FRACTILESHIFT;
  y := centery shr FRACTILESHIFT;
  mapspot := y*MAPCOLS+x;
  if (mapsprites[mapspot] >= 128) and (mapsprites[mapspot] <= 130) then
  begin
   if (Warping) exit;
   if (FindWarpDestination and (x,) and (y, mapsprites[mapspot])) then
   begin
     WarpX := (x*MAPSIZE+32) shl FRACBITS;
     WarpY := (y*MAPSIZE+32) shl FRACBITS;
     Warping := 1;
      end;
    end;
  else
  begin
   warpActive := 0;
   if mapsprites[mapspot]>130 then
    CheckItems(x,y,true,player.chartype);
    end;
  if triggers[x][y] then
  begin
   SoundEffect(SN_TRIGGER,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
   if (netmode) NetSoundEffect(SN_TRIGGER,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
   SoundEffect(SN_TRIGGER,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
   if (netmode) NetSoundEffect(SN_TRIGGER,0,centerx shl FRACTILESHIFT,centery shl FRACTILESHIFT);
   Event(triggers[x][y],true);
    end;
  end;


procedure CheckDoors(fixed_t centerx, fixed_t centery);
begin
  x, y, mapspot: integer;
  doorobj_t *door_p, *last_p;

  x := (int)((centerx) shr FRACTILESHIFT);
  y := (int)((centery) shr FRACTILESHIFT);
  last_p := @doorlist[numdoors];
  for (door_p := doorlist; door_p <> last_p; door_p++)
  while (timecount >= door_p.doorTimer) do
  begin
    mapspot := door_p.tiley*MAPCOLS + door_p.tilex;
    if ((door_p.tilex = x) and (door_p.tiley = y)) or (mapsprites[mapspot]) then
    begin
      if (door_p.doorOpen) and ( not door_p.doorClosing) door_p.doorBlocked := true;
       end;
    else door_p.doorBlocked := false;

    if door_p.doorOpening then
    begin
      if ((door_p.doorSize-:= 4) <= MINDOORSIZE) then
      begin
  door_p.doorSize := MINDOORSIZE;
  door_p.doorOpening := false;
  door_p.doorOpen := true;
  door_p.doorTimer+:= 270; // 3 seconds
   end;
      else door_p.doorTimer := door_p.doorTimer + MOVEDELAY;
    end
    else if door_p.doorClosing then
    begin
      if ((door_p.doorSize+:= 4) >= 64) then
      begin
  door_p.doorSize := 64;
  door_p.doorClosing := false;
  door_p.doorTimer := door_p.doorTimer + MOVEDELAY;
   end;
      else door_p.doorTimer := door_p.doorTimer + MOVEDELAY;
    end
    else if (door_p.doorOpen) and (timecount>door_p.doorTimer) and ( not door_p.doorBlocked) then
    begin
      door_p.doorClosing := true;
      door_p.doorOpen := false;
      SoundEffect(SN_DOOR,15,door_p.tilex shl FRACTILESHIFT,door_p.tiley shl FRACTILESHIFT);
      door_p.doorTimer := door_p.doorTimer + MOVEDELAY;
       end;
    else door_p.doorTimer := door_p.doorTimer + MOVEDELAY;

    door_p.position := door_p.doorSize shl FRACBITS;
     end;
  end;


bool CheckForSwitch(int x,int y,int angle,bool doubleswitch)
begin
  mapspot: integer;

  mapspot := y*MAPCOLS+x;
  if (timecount<SwitchTime) return false;
  if (angle >= SOUTH+DEGREE45) or (angle<DEGREE45) then
  begin
   if (westwall[mapspot+1] = 127) return true;
    else if (westwall[mapspot+1] = 128) and (doubleswitch) return true;
    else if (westwall[mapspot+1] = 172) return true;
    else if (westwall[mapspot+1] = 173) and (doubleswitch) return true;
    else if (westwall[mapspot+1] = 75) return true;
    else if (westwall[mapspot+1] = 76) and (doubleswitch) return true;
    else if (westwall[mapspot+1] = 140) return true;
    else if (westwall[mapspot+1] = 141) and (doubleswitch) return true;
    else if (westwall[mapspot+1] = 234) return true;
    else if (westwall[mapspot+1] = 235) and (doubleswitch) return true;
  end
  else if (angle >= DEGREE45) and (angle<NORTH+DEGREE45) then
  begin
   if (northwall[mapspot] = 127) return true;
    else if (northwall[mapspot] = 128) and (doubleswitch) return true;
    else if (northwall[mapspot] = 172) return true;
    else if (northwall[mapspot] = 173) and (doubleswitch) return true;
    else if (northwall[mapspot] = 75) return true;
    else if (northwall[mapspot] = 76) and (doubleswitch) return true;
    else if (northwall[mapspot] = 140) return true;
    else if (northwall[mapspot] = 141) and (doubleswitch) return true;
    else if (northwall[mapspot] = 234) return true;
    else if (northwall[mapspot] = 235) and (doubleswitch) return true;
  end
  else if (angle >= NORTH+DEGREE45) and (angle<WEST+DEGREE45) then
  begin
   if (westwall[mapspot] = 127) return true;
    else if (westwall[mapspot] = 128) and (doubleswitch) return true;
    else if (westwall[mapspot] = 172) return true;
    else if (westwall[mapspot] = 173) and (doubleswitch) return true;
    else if (westwall[mapspot] = 75) return true;
    else if (westwall[mapspot] = 76) and (doubleswitch) return true;
    else if (westwall[mapspot] = 140) return true;
    else if (westwall[mapspot] = 141) and (doubleswitch) return true;
    else if (westwall[mapspot] = 234) return true;
    else if (westwall[mapspot] = 235) and (doubleswitch) return true;
  end
  else if angle >= WEST+DEGREE45 then
  begin
   if (northwall[mapspot+MAPCOLS] = 127) return true;
    else if (northwall[mapspot+MAPCOLS] = 128) and (doubleswitch) return true;
    else if (northwall[mapspot+MAPCOLS] = 172) return true;
    else if (northwall[mapspot+MAPCOLS] = 173) and (doubleswitch) return true;
    else if (northwall[mapspot+MAPCOLS] = 75) return true;
    else if (northwall[mapspot+MAPCOLS] = 76) and (doubleswitch) return true;
    else if (northwall[mapspot+MAPCOLS] = 140) return true;
    else if (northwall[mapspot+MAPCOLS] = 141) and (doubleswitch) return true;
    else if (northwall[mapspot+MAPCOLS] = 234) return true;
    else if (northwall[mapspot+MAPCOLS] = 235) and (doubleswitch) return true;
    end;
  return false;
  end;


procedure SwitchWall(int x,int y,int angle,bool doubleswitch);
begin
  mapspot: integer;

  SoundEffect(SN_WALLSWITCH,0,x shl FRACTILESHIFT,y shl FRACTILESHIFT);
  mapspot := y*MAPCOLS+x;
  if (angle >= SOUTH+DEGREE45) or (angle<DEGREE45) then
  begin
   if (westwall[mapspot+1] = 127) westwall[mapspot+1] := 128;
    else if (westwall[mapspot+1] = 128) and (doubleswitch) westwall[mapspot+1] := 127;
    else if (westwall[mapspot+1] = 172) westwall[mapspot+1] := 173;
    else if (westwall[mapspot+1] = 173) and (doubleswitch) westwall[mapspot+1] := 172;
    else if (westwall[mapspot+1] = 75) westwall[mapspot+1] := 76;
    else if (westwall[mapspot+1] = 76) and (doubleswitch) westwall[mapspot+1] := 75;
    else if (westwall[mapspot+1] = 140) westwall[mapspot+1] := 141;
    else if (westwall[mapspot+1] = 141) and (doubleswitch) westwall[mapspot+1] := 140;
    else if (westwall[mapspot+1] = 234) westwall[mapspot+1] := 235;
    else if (westwall[mapspot+1] = 235) and (doubleswitch) westwall[mapspot+1] := 234;
  end
  else if (angle >= DEGREE45) and (angle<NORTH+DEGREE45) then
  begin
   if (northwall[mapspot] = 127) northwall[mapspot] := 128;
    else if (northwall[mapspot] = 128) and (doubleswitch) northwall[mapspot] := 127;
    else if (northwall[mapspot] = 172) northwall[mapspot] := 173;
    else if (northwall[mapspot] = 173) and (doubleswitch) northwall[mapspot] := 172;
    else if (northwall[mapspot] = 75) northwall[mapspot] := 76;
    else if (northwall[mapspot] = 76) and (doubleswitch) northwall[mapspot] := 75;
    else if (northwall[mapspot] = 140) northwall[mapspot] := 141;
    else if (northwall[mapspot] = 141) and (doubleswitch) northwall[mapspot] := 140;
    else if (northwall[mapspot] = 234) northwall[mapspot] := 235;
    else if (northwall[mapspot] = 235) and (doubleswitch) northwall[mapspot] := 234;
  end
  else if (angle >= NORTH+DEGREE45) and (angle<WEST+DEGREE45) then
  begin
   if (westwall[mapspot] = 127) westwall[mapspot] := 128;
    else if (westwall[mapspot] = 128) and (doubleswitch) westwall[mapspot] := 127;
    else if (westwall[mapspot] = 172) westwall[mapspot] := 173;
    else if (westwall[mapspot] = 173) and (doubleswitch) westwall[mapspot] := 172;
    else if (westwall[mapspot] = 75) westwall[mapspot] := 76;
    else if (westwall[mapspot] = 76) and (doubleswitch) westwall[mapspot] := 75;
    else if (westwall[mapspot] = 140) westwall[mapspot] := 141;
    else if (westwall[mapspot] = 141) and (doubleswitch) westwall[mapspot] := 140;
    else if (westwall[mapspot] = 234) westwall[mapspot] := 235;
    else if (westwall[mapspot] = 235) and (doubleswitch) westwall[mapspot] := 234;
  end
  else if angle >= WEST+DEGREE45 then
  begin
   if (northwall[mapspot+MAPCOLS] = 127) northwall[mapspot+MAPCOLS] := 128;
    else if (northwall[mapspot+MAPCOLS] = 128) and (doubleswitch) northwall[mapspot+MAPCOLS] := 127;
    else if (northwall[mapspot+MAPCOLS] = 172) northwall[mapspot+MAPCOLS] := 173;
    else if (northwall[mapspot+MAPCOLS] = 173) and (doubleswitch) northwall[mapspot+MAPCOLS] := 172;
    else if (northwall[mapspot+MAPCOLS] = 75) northwall[mapspot+MAPCOLS] := 76;
    else if (northwall[mapspot+MAPCOLS] = 76) and (doubleswitch) northwall[mapspot+MAPCOLS] := 75;
    else if (northwall[mapspot+MAPCOLS] = 140) northwall[mapspot+MAPCOLS] := 141;
    else if (northwall[mapspot+MAPCOLS] = 141) and (doubleswitch) northwall[mapspot+MAPCOLS] := 140;
    else if (northwall[mapspot+MAPCOLS] = 234) northwall[mapspot+MAPCOLS] := 235;
    else if (northwall[mapspot+MAPCOLS] = 235) and (doubleswitch) northwall[mapspot+MAPCOLS] := 234;
    end;
  end;


procedure CheckHere(int useit,fixed_t centerx,fixed_t centery,int angle);
(* check for door at centerx, centery *)
begin
  mapspot, x, y, x1, y1: integer;
  elevobj_t  *elev_p;
  switchit: boolean;

  TryDoor(centerx,centery);
  x := centerx shr FRACTILESHIFT;
  y := centery shr FRACTILESHIFT;
  mapspot := y*MAPCOLS+x;
  switchit := false;

  if switches[x][y] then
  begin
   if useit then
   begin
     if (not CheckForSwitch(x,y,angle,true)) then
      goto skipit;
     if netmode then
      NetCheckHere(centerx,centery,angle);
      end;
   SwitchWall(x,y,angle,true);
   Event(switches[x][y],false);
    end;
skipit:
  case mapsprites[mapspot]  of
  begin
   SM_SWAPSWITCH:
    if (useit) and ( not CheckForSwitch(x,y,angle,true)) break;
    if (useit) and (netmode) NetCheckHere(centerx,centery,angle);
    for(elev_p := firstelevobj.next;elev_p <> @lastelevobj;elev_p := elev_p.next)
     if elev_p.type = E_SWAP then
     begin
       if elev_p.position = elev_p.ceiling then
       begin
   elev_p.elevDown := true;
   elev_p.elevTimer := timecount;
   switchit := true;
       end
       else if elev_p.position = elev_p.floor then
       begin
   elev_p.elevUp := true;
   elev_p.elevTimer := timecount;
   switchit := true;
    end;
        end;
    if switchit then
    begin
      SwitchWall(x,y,angle,true);
      SwitchTime := timecount+210;
       end;
    break;

   SM_STRIGGER:
    for(elev_p := firstelevobj.next;elev_p <> @lastelevobj;elev_p := elev_p.next)
     if (elev_p.type = E_SECRET) and (elev_p.elevDown = false) and (elev_p.elevUp = false) then
     begin
       x1 := elev_p.mapspot mod MAPCOLS;
       y1 := elev_p.mapspot/MAPCOLS;
       if (abs(x1-x)<2) and (abs(y1-y)<2) then
       begin
   switchit := true;
   elev_p.elevDown := true;
   elev_p.elevTimer := timecount;
   CheckHere(false,x1 shl FRACTILESHIFT,y1 shl FRACTILESHIFT,angle);
    end;
        end;
    if (switchit) and (useit) and (netmode) then
     NetCheckHere(centerx,centery,angle);
    break;
    end;
  end;


procedure chargeweapons;
begin
  i, n: integer;
  time: integer;

  time := timecount;
  for(i := 0;i<5;i++)
  begin
   n := player.weapons[i];
   while (n <> -1) and (weapons[n].charge<100) and (time >= weapons[n].chargetime) do
   begin
     if weapons[n].charge = 0 then
      weapons[n].chargetime := timecount;
     weapons[n].charge := weapons[n].charge + 20;
     weapons[n].chargetime := weapons[n].chargetime + weapons[n].chargerate;
      end;
    end;
  end;


(* timer access not  ********************************************)
procedure ControlStub1;
begin
  end;

bool TryDoor(fixed_t xcenter, fixed_t ycenter)
begin
  xl, yl, xh, yh, x, y: integer;
  doorobj_t *door_p, *last_p;

  xl :=  (int)((xcenter-PLAYERSIZE)  shr  FRACTILESHIFT);
  yl :=  (int)((ycenter-PLAYERSIZE - (TILEUNIT shr 1))  shr  FRACTILESHIFT);
  xh :=  (int)((xcenter+PLAYERSIZE)  shr  FRACTILESHIFT);
  yh :=  (int)((ycenter+PLAYERSIZE - (TILEUNIT shr 1))  shr  FRACTILESHIFT);
// check for doors on the north wall
  for (y := yl+1;y <= yh;y++)
  for (x := xl;x <= xh;x++)
  begin
    if (mapflags[y*MAPSIZE+x]) and (FL_DOOR) // if tile has a door
    begin
      last_p := @doorlist[numdoors];
      for (door_p := doorlist; door_p <> last_p; door_p++)
       if (door_p.tilex = x) and (door_p.tiley = y) and ((door_p.orientation = dr_horizontal) or (door_p.orientation = dr_horizontal2)) then
       begin
   if (door_p.doorOpen) and ( not door_p.doorClosing) return true; // can move, door is open
   else if (not door_p.doorOpen) and (door_p.doorBumpable) and ( not door_p.doorOpening) then
   begin
     door_p.doorClosing := false;
     door_p.doorOpening := true;
     doorsound := true;
     doorx := door_p.tilex shl FRACTILESHIFT;
     doory := door_p.tiley shl FRACTILESHIFT;
     if (door_p.orientation = dr_horizontal) TryDoor(xcenter+64*FRACUNIT,ycenter);
      else TryDoor(xcenter-64*FRACUNIT,ycenter);
     if (netmode) NetOpenDoor(xcenter,ycenter);
     return false;
   end
   else if (not door_p.doorOpen) and (door_p.doorBumpable) and (door_p.doorClosing) then
   begin
     door_p.doorClosing := false;
     door_p.doorOpening := true;
     doorsound := true;
     doorx := door_p.tilex shl FRACTILESHIFT;
     doory := door_p.tiley shl FRACTILESHIFT;
     if (door_p.orientation = dr_horizontal) TryDoor(xcenter+64*FRACUNIT,ycenter);
      else TryDoor(xcenter-64*FRACUNIT,ycenter);
     if (netmode) NetOpenDoor(xcenter,ycenter);
     return false;
      end;
   else return false;
    end;
       end;
     end;
// check for doors on the west wall
  xl :=  (int)((xcenter-PLAYERSIZE - (TILEUNIT shr 1))  shr  FRACTILESHIFT);
  yl :=  (int)((ycenter-PLAYERSIZE)  shr  FRACTILESHIFT);
  xh :=  (int)((xcenter+PLAYERSIZE - (TILEUNIT shr 1))  shr  FRACTILESHIFT);
  yh :=  (int)((ycenter+PLAYERSIZE)  shr  FRACTILESHIFT);
  for (y := yl;y <= yh;y++)
  for (x := xl+1;x <= xh;x++)
  begin
    if (mapflags[y*MAPSIZE+x]) and (FL_DOOR) // if tile has a door
    begin
      last_p := @doorlist[numdoors];
      for (door_p := doorlist; door_p <> last_p; door_p++)
       if (door_p.tilex = x) and (door_p.tiley = y) and ((door_p.orientation = dr_vertical) or (door_p.orientation = dr_vertical2)) then
       begin
   if (door_p.doorOpen) and ( not door_p.doorClosing) return true; // can move, door is open
   else if (not door_p.doorOpen) and (door_p.doorBumpable) and ( not door_p.doorOpening) then
   begin
     door_p.doorOpening := true;
     door_p.doorClosing := false;
     doorsound := true;
     doorx := door_p.tilex shl FRACTILESHIFT;
     doory := door_p.tiley shl FRACTILESHIFT;
     if (door_p.orientation = dr_vertical) TryDoor(xcenter,ycenter+64*FRACUNIT);
      else TryDoor(xcenter,ycenter-64*FRACUNIT);
     if (netmode) NetOpenDoor(xcenter,ycenter);
     return false;
   end
   else if (not door_p.doorOpen) and (door_p.doorBumpable) and (door_p.doorClosing) then
   begin
     door_p.doorClosing := false;
     door_p.doorOpening := true;
     doorsound := true;
     doorx := door_p.tilex shl FRACTILESHIFT;
     doory := door_p.tiley shl FRACTILESHIFT;
     if (door_p.orientation = dr_vertical) TryDoor(xcenter,ycenter+64*FRACUNIT);
      else TryDoor(xcenter,ycenter-64*FRACUNIT);
     if (netmode) NetOpenDoor(xcenter,ycenter);
     return false;
      end;
   else return false;
    end;
       end;
     end;
  return true;
  end;


bool TryMove(int angle,fixed_t xcenter, fixed_t ycenter)
begin
  xl, yl, xh, yh, x, y, mapspot: integer;
  pz: fixed_t;

  if (angle<NORTH) or (angle>SOUTH) then
  begin
   xl := xcenter shr FRACTILESHIFT;
   xh := (xcenter+PLAYERSIZE) shr FRACTILESHIFT;
  end
  else if (angle>NORTH) and (angle<SOUTH) then
  begin
   xh := xcenter shr FRACTILESHIFT;
   xl := (xcenter-PLAYERSIZE) shr FRACTILESHIFT;
    end;
  else
  begin
   xh := (xcenter+PLAYERSIZE) shr FRACTILESHIFT;
   xl := (xcenter-PLAYERSIZE) shr FRACTILESHIFT;
    end;
  if angle>WEST then
  begin
   yl := ycenter shr FRACTILESHIFT;
   yh := (ycenter+PLAYERSIZE) shr FRACTILESHIFT;
  end
  else if (angle<WEST) and (angle <> EAST) then
  begin
   yl := (ycenter-PLAYERSIZE) shr FRACTILESHIFT;
   yh := ycenter shr FRACTILESHIFT;
    end;
  else
  begin
   yl := (ycenter-PLAYERSIZE) shr FRACTILESHIFT;
   yh := (ycenter+PLAYERSIZE) shr FRACTILESHIFT;
    end;
  pz := player.z - player.height + (26 shl FRACBITS);
// check for solid walls
  for (y := yl;y <= yh;y++)
  for (x := xl;x <= xh;x++)
  begin
    mapspot := MAPCOLS*y+x;
    if ((y>yl) and (northwall[mapspot]) and ( not (northflags[mapspot]) and (F_NOCLIP))) or (
  (x>xl) and (westwall[mapspot]) and ( not (westflags[mapspot]) and (F_NOCLIP))) return false;
    if mapspot <> player.mapspot then
    begin
      if (mapsprites[mapspot]>0) and (mapsprites[mapspot]<128) return false;
      if (RF_GetFloorZ((x shl FRACTILESHIFT)+(32 shl FRACBITS),(y shl FRACTILESHIFT)+(32 shl FRACBITS))>pz) return false;
      if (RF_GetCeilingZ((x shl FRACTILESHIFT)+(32 shl FRACBITS),(y shl FRACTILESHIFT)+(32 shl FRACBITS))<player.z+(10 shl FRACBITS)) return false;
       end;
     end;
  return true;
  end;


bool ClipMove(int angle,fixed_t xmove, fixed_t ymove)
begin
  dx, dy: fixed_t;
  angle2: integer;

  dx := player.x+xmove;
  dy := player.y+ymove;
  if (TryMove(angle,dx,dy)) and (TryDoor(dx,dy)) then
  begin
   if (floorpic[(dy shr FRACTILESHIFT)*MAPCOLS+(dx shr FRACTILESHIFT)] = 0) return false;
   player.x := player.x + xmove;
   player.y := player.y + ymove;
   return true;
    end;
// the move goes into a wall, so try and move along one axis
  if (xmove>0) angle2 := EAST;
  else angle2 := WEST;
  if (TryMove(angle2,dx,player.y)) and (TryDoor(dx,player.y)) then
  begin
   if (floorpic[(player.y shr FRACTILESHIFT)*MAPCOLS+(dx shr FRACTILESHIFT)] = 0) then
    return false;
   player.x := player.x + xmove;
   return true;
    end;
  if (ymove>0) angle2 := SOUTH;
  else angle2 := NORTH;
  if (TryMove(angle2,player.x,dy)) and (TryDoor(player.x,dy)) then
  begin
   if (floorpic[(dy shr FRACTILESHIFT)*MAPCOLS+(player.x shr FRACTILESHIFT)] = 0) then
    return false;
   player.y := player.y + ymove;
   return true;
    end;
  return false;
  end;


bool Thrust(int angle,fixed_t speed)
begin
  xmove, ymove: fixed_t;
  result: integer;

  angle) and (:= ANGLES;
  xmove := FIXEDMUL(speed,costable[angle]);
  ymove := -FIXEDMUL(speed,sintable[angle]);
  result := ClipMove(angle,xmove,ymove);
  player.mapspot := (player.y shr FRACTILESHIFT)*MAPCOLS+(player.x shr FRACTILESHIFT);
  return result;
  end;


procedure ControlMovement ;
begin
  modifiedSpeed: fixed_t;
  modifiedTurn, modifiedMoveUnit, modifiedturnunit, n: integer;
  floorz, fz, xl, yl, xh, yh, maxz: fixed_t;
  maxx, maxy, mapspot: integer;

  if Warping then
  begin
   floorz := RF_GetFloorZ(player.x,player.y)+player.height;
   if player.z>floorz then
   begin
     fallrate := fallrate + MOVEUNIT;
     player.z := player.z - fallrate;
     if (player.z<floorz) player.z := floorz;
   end
   else if player.z<floorz then
   begin
     player.z := floorz;
     fallrate := 0;
      end;
   exit;
    end;

//#ifndef DEMO
// if (keyboard[SC_G]) and (timecount>keyboardDelay) and ( not netmsgstatus)
//   begin 
//   SaveTheScreen := true;
//   keyboardDelay := timecount+KBDELAY;
//    end;
//{$ENDIF}

  if (keyboard[SC_ESCAPE]) and (timecount>keyboardDelay) and ( not netmsgstatus) then
  activatemenu := true;

  if (keyboard[SC_F5]) and (keyboard[SC_LSHIFT]) and (timecount>keyboardDelay) then
  begin
   adjustvrangle := -SC.vrangle+DEFAULTVRANGLE;
   adjustvrdist := -1;
   keyboardDelay := timecount+KBDELAY;
    end;
  if (keyboard[SC_F4]) and (keyboard[SC_LSHIFT]) and (timecount>keyboardDelay) then
  begin
   adjustvrdist := 72090;
   keyboardDelay := timecount+KBDELAY;
    end;
  if (keyboard[SC_F3]) and (keyboard[SC_LSHIFT]) and (timecount>keyboardDelay) then
  begin
   adjustvrdist := 59578;
   keyboardDelay := timecount+KBDELAY;
    end;
  if (keyboard[SC_F2]) and (keyboard[SC_LSHIFT]) and (timecount>keyboardDelay) then
  begin
   adjustvrangle := 1;
   keyboardDelay := timecount+KBDELAY;
    end;
  if (keyboard[SC_F1]) and (keyboard[SC_LSHIFT]) and (timecount>keyboardDelay) then
  begin
   adjustvrangle := -1;
   keyboardDelay := timecount+KBDELAY;
    end;

  if (keyboard[SC_F1]) and (timecount>keyboardDelay) then
  begin
   activatehelp := true;
   keyboardDelay := timecount+KBDELAY;
    end;

  if ((keyboard[SC_F4]) or ((keyboard[SC_ALT]) and (keyboard[SC_Q])) then
  ) and (timecount>keyboardDelay) QuickExit := true;

  if (keyboard[SC_F5]) and (timecount>keyboardDelay) and ( not netmode) then
  activatebrief := true;

  if (keyboard[SC_P]) and (timecount>keyboardDelay) and ( not netmsgstatus) then
  paused := true;

  (* change screen size *)
  if (keyboard[SC_F9]) and ( not resizeScreen) and (timecount>keyboardDelay) then
  begin
   resizeScreen := 1;
   biggerScreen := 1;
   keyboardDelay := timecount+KBDELAY;
   if (SC.screensize<9) SC.screensize++;
   exit;
    end;
  if (keyboard[SC_F10]) and ( not resizeScreen) and (timecount>keyboardDelay) then
  begin
   resizeScreen := 1;
   biggerScreen := 0;
   keyboardDelay := timecount+KBDELAY;
   if (SC.screensize) SC.screensize--;
   exit;
    end;

  if (keyboard[SC_MINUS]) and (timecount>keyboardDelay) and ( not netmsgstatus) then
  begin
   case MapZoom  of
   begin
     8:
      MapZoom := 4;
      break;
     16:
      MapZoom := 8;
      break;
      end;
   keyboardDelay := timecount+KBDELAY;
    end;
  if (keyboard[SC_PLUS]) and (timecount>keyboardDelay) and ( not netmsgstatus) then
  begin
   case MapZoom  of
   begin
     4:
      MapZoom := 8;
      break;
     8:
      MapZoom := 16;
      break;
      end;
   keyboardDelay := timecount+KBDELAY;
    end;

  if (in_button[bt_lookup]) and ( not netmsgstatus) scrollview-:= SCROLLRATE;
  if (in_button[bt_lookdown]) and ( not netmsgstatus) scrollview+:= SCROLLRATE;
  if (in_button[bt_centerview]) and ( not netmsgstatus) scrollview := 255;

  if scrollview = 255 then
  begin
   if player.scrollmin<0 then
   begin
     player.scrollmin := player.scrollmin + SCROLLRATE;
     player.scrollmax := player.scrollmax + SCROLLRATE;
   end
   else if player.scrollmin>0 then
   begin
     player.scrollmin := player.scrollmin - SCROLLRATE;
     player.scrollmax := player.scrollmax - SCROLLRATE;
      end;
   else scrollview := 0;
    end;

  (* display mode toggles *)
  if (keyboard[SC_M]) and (timecount>keyboardDelay) and ( not netmsgstatus) then
  begin
   togglemapmode := true;
   keyboardDelay := timecount+KBDELAY;
    end;
  if (keyboard[SC_H]) and (timecount>keyboardDelay) and ( not netmsgstatus) then
  begin
   toggleheatmode := true;
   keyboardDelay := timecount+KBDELAY;
    end;
  if (keyboard[SC_S]) and (timecount>keyboardDelay) and ( not netmsgstatus) then
  begin
   togglemotionmode := true;
   keyboardDelay := timecount+KBDELAY;
    end;
  if (in_button[bt_asscam]) and (timecount>keyboardDelay) and ( not netmsgstatus) then
  begin
   ToggleRearView := true;
   keyboardDelay := timecount+KBDELAY;
    end;
  if (keyboard[SC_TAB]) and (timecount>keyboardDelay) and ( not netmsgstatus) then
  begin
   togglegoalitem := true;
   keyboardDelay := timecount+KBDELAY;
    end;


  if (keyboard[SC_CAPSLOCK]) and (timecount>keyboardDelay) then
  begin
   toggleautorun := true;
   keyboardDelay := timecount+KBDELAY;
    end;
  if (keyboard[SC_NUMLOCK]) and (timecount>keyboardDelay) then
  begin
   toggleautotarget := true;
   keyboardDelay := timecount+KBDELAY;
    end;


  (* secrets *)
  if newascii then
  begin
   secretbuf[secretindex++] := lastascii;
   if (secretindex >= 19) specialcode := true;
   if (netmsgstatus = 1) // getting message
   begin
     case lastascii  of
     begin
       27:
  netmsgstatus := 0;
  break;
       8:
  netmsg[netmsgindex] := ' ';
  if netmsgindex>0 then
    netmsgindex--;
  netmsg[netmsgindex] := '_';
  break;
       13:
  netmsgstatus := 2; // sending
  netmsg[netmsgindex] := ' ';
  break;
       default:
  netmsg[netmsgindex] := lastascii;
  if netmsgindex<29 then
   netmsgindex++;
  netmsg[netmsgindex] := '_';
  break;
        end;
      end;
   newascii := false;
   secretdelay := timecount+KBDELAY*5;
    end;
  if timecount>secretdelay then
  begin
   specialcode := true;
   secretdelay := timecount+KBDELAY*5;
    end;

  if (keyboard[SC_F6]) and (netmode) and (netmsgstatus = 0) and (timecount>keyboardDelay) then
  begin
   memset(netmsg,0,sizeof(netmsg));
   netmsgstatus := 1;
   netmsgindex := 0;
   netmsg[0] := '_';
   keyboardDelay := timecount+KBDELAY;
    end;

  if keyboard[SC_F7] then
  newsong := true;

  if (in_button[bt_invright]) and (timecount>keyboardDelay) then
  begin
   goiright := true;
   keyboardDelay := timecount+KBDELAY;
   inventorytime := timecount+(3*70);
    end;
  if (in_button[bt_invleft] ) and (timecount>keyboardDelay) then
  begin
   goileft := true;
   keyboardDelay := timecount+KBDELAY;
   inventorytime := timecount+(3*70);
    end;

  (* he's dead jim not  *)
  if player.angst = 0 then
  begin

   if (floorpic[player.mapspot] >= 57) and (floorpic[player.mapspot] <= 59) then
   begin
     if (player.z>RF_GetFloorZ(player.x,player.y)+(40 shl FRACBITS)) then
      player.z := player.z - FRACUNIT;
     else if (player.z<RF_GetFloorZ(player.x,player.y)+(40 shl FRACBITS))
      player.z := RF_GetFloorZ(player.x,player.y)+(40 shl FRACBITS);
      end;
   else
   begin
     if (player.z>RF_GetFloorZ(player.x,player.y)+(12 shl FRACBITS)) then
      player.z := player.z - FRACUNIT;
     else if (player.z<RF_GetFloorZ(player.x,player.y)+(12 shl FRACBITS))
      player.z := RF_GetFloorZ(player.x,player.y)+(12 shl FRACBITS);
      end;
   if (keyboard[SC_SPACE]) deadrestart := true;
   exit;
    end;

  if (in_button[bt_useitem]) and (timecount>keyboardDelay) then
  begin
   useitem := true;
   keyboardDelay := timecount+KBDELAY;
   inventorytime := timecount+(3*70);
    end;

  (* change weapon *)
  if (keyboard[SC_1]) and ( not changingweapons) and (player.currentweapon <> 0) and ( not netmsgstatus) then
  begin
   changingweapons := true;
   weaponlowering := true;
   newweapon := 0;
  end
  else if (keyboard[SC_2]) and ( not changingweapons) and (player.currentweapon <> 1) and (player.weapons[1] <> -1) and ( not netmsgstatus) then
  begin
   changingweapons := true;
   weaponlowering := true;
   newweapon := 1;
  end
  else if (keyboard[SC_3]) and ( not changingweapons) and (player.currentweapon <> 2) and (player.weapons[2] <> -1) and ( not netmsgstatus) then
  begin
   changingweapons := true;
   weaponlowering := true;
   newweapon := 2;
  end
  else if (keyboard[SC_4]) and ( not changingweapons) and (player.currentweapon <> 3) and (player.weapons[3] <> -1) and ( not netmsgstatus) then
  begin
   changingweapons := true;
   weaponlowering := true;
   newweapon := 3;
  end
  else if (keyboard[SC_5]) and ( not changingweapons) and (player.currentweapon <> 4) and (player.weapons[4] <> -1) and ( not netmsgstatus) then
  begin
   changingweapons := true;
   weaponlowering := true;
   newweapon := 4;
    end;

  if (in_button[bt_jump]) and (timecount>keyboardDelay) and (fallrate = 0) and ( not netmsgstatus) then
  begin
   fallrate-:= FALLUNIT*9+player.jumpmod;
   keyboardDelay := timecount+KBDELAY;
    end;

  (* check run/slow keys *)
  if (in_button[bt_run]) or (autorun) then
  begin
   modifiedSpeed := (int)((PLAYERMOVESPEED)*6 + player.runmod);
   modifiedTurn := (int)(playerturnspeed*2.5);
   modifiedMoveUnit := MOVEUNIT*2;
   modifiedturnunit := turnunit;
    end;
  else
  begin
   modifiedSpeed := (int)((PLAYERMOVESPEED)*3.5 + player.walkmod);
   modifiedTurn := playerturnspeed;
   modifiedMoveUnit := MOVEUNIT;
   modifiedturnunit := turnunit*2;
    end;

  floorz := RF_GetFloorZ(player.x,player.y)+player.height;
  if (floorpic[player.mapspot] >= 57) and (floorpic[player.mapspot] <= 59) then
  begin
   if player.z = floorz then
    modifiedSpeed> >= 1;
    end;

  (* check strafe *)
  if ((in_button[bt_straf]) or (in_button[bt_slideleft]) or (in_button[bt_slideright])) and ( not netmsgstatus) then
  begin
   if (in_button[bt_west]) or (in_button[bt_slideleft]) then
   begin
     strafrate := strafrate - modifiedMoveUnit;
     if (strafrate<-modifiedSpeed) strafrate+:= modifiedMoveUnit;
      end;
   if (in_button[bt_east]) or (in_button[bt_slideright]) then
   begin
     strafrate := strafrate + modifiedMoveUnit;
     if (strafrate>modifiedSpeed) strafrate-:= modifiedMoveUnit;
   end
   else if (not in_button[bt_west]) and ( not in_button[bt_slideleft]) then
   begin
     if (strafrate<0) strafrate+:= MOVEUNIT;
     else if (strafrate>0) strafrate-:= MOVEUNIT;
      end;
    end;
  else
  begin
   if (strafrate<0) strafrate+:= MOVEUNIT;
    else if (strafrate>0) strafrate-:= MOVEUNIT;

   (* not strafing *)
   if in_button[bt_east] then
   begin
     turnrate := turnrate - modifiedturnunit;
     if turnrate<-modifiedTurn then
      turnrate := -modifiedTurn;
     player.angle := player.angle + turnrate;
   end
   else if in_button[bt_west] then
   begin
     turnrate := turnrate + modifiedturnunit;
     if turnrate>modifiedTurn then
      turnrate := modifiedTurn;
     player.angle := player.angle + turnrate;
      end;
   else
   begin
     if turnrate<0 then
     begin
       turnrate := turnrate + modifiedturnunit;
       if turnrate>0 then
  turnrate := 0;
     end
     else if turnrate>0 then
     begin
       turnrate := turnrate - modifiedturnunit;
       if turnrate<0 then
  turnrate := 0;
        end;
     player.angle := player.angle + turnrate;
      end;
   player.angle) and (:= ANGLES;
    end;

  if strafrate<0 then
  begin
   if (not Thrust(player.angle+NORTH,-strafrate)) then
   begin
     moverate := 0;
     strafrate := 0;
      end;
  end
  else if strafrate>0 then
  begin
   if (not Thrust(player.angle+SOUTH,strafrate)) then
   begin
     moverate := 0;
     strafrate := 0;
      end;
    end;

  (* forward/backwards move *)
  if (in_button[bt_north]) moveforward := 1;
  else if (in_button[bt_south]) moveforward := -1;
  else moveforward := 0;

  (* compute move vectors *)
  if moveforward = 1 then
  begin
   if (moverate<modifiedSpeed) moverate+:= modifiedMoveUnit;
   if (moverate>modifiedSpeed) moverate-:= modifiedMoveUnit;
  end
  else if moveforward = -1 then
  begin
   if (moverate>-modifiedSpeed) moverate-:= modifiedMoveUnit;
   if (moverate<-modifiedSpeed) moverate+:= modifiedMoveUnit;
  end
  else if moverate <> 0 then
  begin
   if (moverate<0) moverate+:= MOVEUNIT;
    else moverate := moverate - MOVEUNIT;
    end;

  (* move along move vector) and (compute head bobbing *)
  if moverate<0 then
  begin
   if (headbob = MAXBOBS-1) headbob := 0;
    else ++headbob;
   if wbobcount = 4 then
   begin
     wbobcount := 0;
     if (weapbob = MAXBOBS-1) weapbob := 0;
      else ++weapbob;
      end;
   else ++wbobcount;
   if (not Thrust(player.angle+WEST,-moverate)) moverate := 0;
  end
  else if moverate>0 then
  begin
   if (headbob = MAXBOBS-1) headbob := 0;
    else ++headbob;
   if wbobcount = 4 then
   begin
     wbobcount := 0;
     if (weapbob = MAXBOBS-1) weapbob := 0;
      else ++weapbob;
      end;
   else ++wbobcount;
   if (not Thrust(player.angle,moverate)) moverate := 0;
  end
  else if (timecount) and (8) then
  begin
   if weapmove[weapbob] <> 0 then
   begin
     if (abs(weapmove[weapbob-1])<abs(weapmove[weapbob])) --weapbob;
     else
     begin
       ++weapbob;
       if (weapbob = MAXBOBS) weapbob := 0;
        end;
      end;
   if headmove[headbob] <> 0 then
   begin
     if (abs(headmove[headbob-1])<abs(headmove[headbob])) --headbob;
     else
     begin
       ++headbob;
       if (headbob = MAXBOBS) headbob := 0;
        end;
      end;
    end;

  (* try to open a door in front of player *)
  if (in_button[bt_use]) and (timecount>keyboardDelay) and ( not netmsgstatus) then
  begin
   checktrigger := true;
   keyboardDelay := timecount+KBDELAY*2;
    end;

  (* fire a weapon *)
  if (in_button[bt_fire]) and (weapons[player.weapons[player.currentweapon]].charge = 100) and ( not changingweapons) then
  begin
   n := player.weapons[player.currentweapon];
   if (n = 18) or (n = 4) then
   begin
     if (player.ammo[weapons[n].ammotype] >= weapons[n].ammorate) and (weapmode = 0) weapmode := 1;
      end;
   else RF_SetActionHook(fireweapon);
    end;

  (* compute falling or stepping up higher *)
  xl := (player.x-(FRACUNIT*8)) shr FRACTILESHIFT;
  xh := (player.x+(FRACUNIT*8)) shr FRACTILESHIFT;
  yl := (player.y-(FRACUNIT*8)) shr FRACTILESHIFT;
  yh := (player.y+(FRACUNIT*8)) shr FRACTILESHIFT;
  floorz := player.z-player.height;
  maxz := 0;
  for(;xl <= xh;xl++)
  for(;yl <= yh;yl++)
  begin
    fz := RF_GetFloorZ((xl*64+32) shl FRACBITS,(yl*64+32) shl FRACBITS);
    if (fz>maxz) and (fz<floorz+(20 shl FRACBITS)) then
    begin
      maxz := fz;
      maxx := xl;
      maxy := yl;
       end;
     end;
  if maxz = 0 then
  begin
   maxz := RF_GetFloorZ(player.x,player.y);
   maxx := player.x shr FRACTILESHIFT;
   maxy := player.y shr FRACTILESHIFT;
    end;
  floorz := maxz + player.height;

  if (abs(player.z-floorz) <= 10 shl FRACBITS) then
  begin
   mapspot := maxy*MAPCOLS + maxx;
   if (floorflags[mapspot]) and (F_RIGHT) then
    Thrust(EAST,FRACUNIT*4);
   if (floorflags[mapspot]) and (F_LEFT) then
    Thrust(WEST,FRACUNIT*4);
   if (floorflags[mapspot]) and (F_UP) then
    Thrust(NORTH,FRACUNIT*4);
   if (floorflags[mapspot]) and (F_DOWN) then
    Thrust(SOUTH,FRACUNIT*4);
    end;

// floorz := RF_GetFloorZ(player.x,player.y)+player.height;

  player.z := player.z - fallrate;
  if (player.z>floorz) fallrate+:= FALLUNIT;
  else if player.z<floorz then
  begin
   if (fallrate >= 12*FRACUNIT) falldamage := (fallrate shr FRACBITS)/7;
   player.z+:= FRACUNIT shl 2;
   if (player.z>floorz) player.z := floorz;
   fallrate := 0;
    end;
  floorz := RF_GetCeilingZ(player.x,player.y);
  if (player.z+(10 shl FRACBITS)>floorz) then
  begin
   player.z := floorz-(10 shl FRACBITS);
   fallrate := FALLUNIT;
    end;
  end;


procedure PlayerCommand;
(* called by an interrupt *)
begin
  INT_ReadControls;
  ControlMovement;
  end;


procedure newlights;
begin
  if (lighting+changelight>4096) lighting := 4096;
  else lighting := lighting + changelight;
  if (lighting <= 0) lighting := 1;
  RF_SetLights((fixed_t)lighting shl FRACBITS);
  changelight := 0;
  end;


procedure ChangeScroll;
begin
  if (scrollview = 255) exit;
  if (player.scrollmin+scrollview <= -MAXSCROLL) or (player.scrollmin+scrollview >= MAXSCROLL) then
  begin
   scrollview := 0;
   exit;
    end;
  player.scrollmin := player.scrollmin + scrollview;
  player.scrollmax := player.scrollmax + scrollview;
  scrollview := 0;
  end;


procedure Special_Code(char *s);
(* secrets *)
begin
  scaleobj_t *hsprite_p, *sprite_p;
  i: integer;

  if (netmode) and ( not MS_CheckParm('ravenger')) then
  begin
   specialcode := false;
   memset(secretbuf,0,sizeof(secretbuf));
   secretindex := 0;
   exit;
    end;
  if (stricmp(s,'belfast') = 0) then
  begin
   for (sprite_p := firstscaleobj.next; sprite_p <> @lastscaleobj;sprite_p := sprite_p.next)
    if sprite_p.hitpoints then
    begin
      mapsprites[(sprite_p.y shr FRACTILESHIFT)*MAPCOLS+(sprite_p.x shr FRACTILESHIFT)] := 0;
      hsprite_p := sprite_p;
      sprite_p := sprite_p.prev;
      KillSprite(hsprite_p,S_BULLET3);
      player.bodycount++;
       end;
   writemsg('DeathKiss');
  end
  else if (stricmp(s,'allahmode') = 0) then
  begin
   if godmode then
   begin
     godmode := false;
     writemsg('GodMode Off');
      end;
   else
   begin
     godmode := true;
     writemsg('GodMode On');
      end;
  end
  else if (stricmp(s,'channel7') = 0) then
  begin
   writemsg('Rob Lays Eggs');
  end
  else if (stricmp(s,'lizardman') = 0) then
  begin
   writemsg('Jeremy Lays Eggs');
  end
  else if (stricmp(s,'dominatrix') = 0) then
  begin
   writemsg('On your knees worm!');
  end
  else if (stricmp(s,'cyborg') = 0) then
  begin
   writemsg('Psyborgs Rule!');
  end
  else if (stricmp(s,'mooman') = 0) then
  begin
   writemsg('Brady is better than you, and that ain''t saying much!');
  end
  else if (stricmp(s,'raven') = 0) then
  begin
   player.angst := player.maxangst;
   player.shield := player.maxshield;
   writemsg('Ambrosia');
  end
  else if (stricmp(s,'omni') = 0) then
  begin
   for(i := 0;i<MAPCOLS*MAPROWS;i++)
    if (northwall[i]) and (255) player.northmap[i] := WALL_COLOR;
   for(i := 0;i<MAPCOLS*MAPROWS;i++)
    if (westwall[i]) and (255) player.westmap[i] := WALL_COLOR;
   writemsg('Omniscience');
  end
  else if (stricmp(s,'kmfdm') = 0) then
  begin
   player.ammo[0] := 999;
   player.ammo[1] := 999;
   player.ammo[2] := 999;
   writemsg('Backpack of Holding');
   oldshots := -1;
  end
  else if (stricmp(s,'beavis') = 0) then
  begin
   player.levelscore := 100;
   player.primaries[0] := pcount[0];
   player.primaries[1] := pcount[1];
   for (i := 0;i<7;i++)
    player.secondaries[i] := scount[i];
   writemsg('Time Warp');
  end
  else if (stricmp(s,'gulliver') = 0) then
  begin
   if midgetmode then
   begin
     for (sprite_p := firstscaleobj.next;sprite_p <> @lastscaleobj;sprite_p := sprite_p.next)
      sprite_p.scale--;
     midgetmode := false;
     writemsg('Midget Mode Off');
      end;
   else
   begin
     for (sprite_p := firstscaleobj.next;sprite_p <> @lastscaleobj;sprite_p := sprite_p.next)
      sprite_p.scale++;
     midgetmode := true;
     writemsg('Midget Mode On');
      end;
  end
  else if (stricmp(s,'gimme') = 0) then
  begin
   player.inventory[0] := 20;
   player.inventory[1] := 20;
   player.inventory[2] := 15;
   player.inventory[3] := 10;
   player.inventory[4] := 10;
   player.inventory[5] := 10;
   player.inventory[6] := 10;
   player.inventory[7] := 10;
   player.inventory[8] := 10;
#ifndef DEMO
   player.inventory[9] := 10;
   player.inventory[10] := 10;
   player.inventory[11] := 10;
   player.inventory[12] := 10;
{$ENDIF}
   writemsg('Bag of Holding');
  end
  else if (stricmp(s,'taco') = 0) then
  begin
   enemyviewmode) xor (:= 1;
   writemsg('Enemy view toggled');
    end;
#if  not defined(DEMO)) and ( not defined(GAME1)) and ( not defined(GAME2)) and ( not defined(GAME3)
  if (s[0] = 'g') and (s[1] = 'o') then
  begin
   if (stricmp(s,'go1') = 0) newmap(0,2);
    else if (stricmp(s,'go2') = 0) newmap(1,2);
    else if (stricmp(s,'go3') = 0) newmap(2,2);
    else if (stricmp(s,'go4') = 0) newmap(3,2);
    else if (stricmp(s,'go5') = 0) newmap(4,2);
    else if (stricmp(s,'go6') = 0) newmap(5,2);
    else if (stricmp(s,'go7') = 0) newmap(6,2);
    else if (stricmp(s,'go8') = 0) newmap(7,2);
    else if (stricmp(s,'go9') = 0) newmap(8,2);
    else if (stricmp(s,'go10') = 0) newmap(9,2);
    else if (stricmp(s,'go11') = 0) newmap(10,2);
    else if (stricmp(s,'go12') = 0) newmap(11,2);
    else if (stricmp(s,'go13') = 0) newmap(12,2);
    else if (stricmp(s,'go14') = 0) newmap(13,2);
    else if (stricmp(s,'go15') = 0) newmap(14,2);
    else if (stricmp(s,'go16') = 0) newmap(15,2);
    else if (stricmp(s,'go17') = 0) newmap(16,2);
    else if (stricmp(s,'go18') = 0) newmap(17,2);
    else if (stricmp(s,'go19') = 0) newmap(18,2);
    else if (stricmp(s,'go20') = 0) newmap(19,2);
    else if (stricmp(s,'go21') = 0) newmap(20,2);
    else if (stricmp(s,'go22') = 0) newmap(21,2);
    else if (stricmp(s,'go23') = 0) newmap(22,2);
    else if (stricmp(s,'go24') = 0) newmap(23,2);
    else if (stricmp(s,'go25') = 0) newmap(24,2);
    else if (stricmp(s,'go26') = 0) newmap(25,2);
    else if (stricmp(s,'go27') = 0) newmap(26,2);
    else if (stricmp(s,'go28') = 0) newmap(27,2);
    else if (stricmp(s,'go29') = 0) newmap(28,2);
    else if (stricmp(s,'go30') = 0) newmap(29,2);
    else if (stricmp(s,'go31') = 0) newmap(30,2);
    else if (stricmp(s,'go32') = 0) newmap(31,2);
   INT_TimerHook(PlayerCommand);
    end;
{$ENDIF}
  else if (s[0] = 'b') and (s[1] = 'l') then
  begin
   if (stricmp(s,'blammo1') = 0) player.weapons[2] := 2;
    else if (stricmp(s,'blammo2') = 0) player.weapons[2] := 3;
    else if (stricmp(s,'blammo3') = 0) player.weapons[2] := 4;
    else if (stricmp(s,'blammo4') = 0) player.weapons[2] := 16;
    else if (stricmp(s,'blammo5') = 0) player.weapons[2] := 17;
    else if (stricmp(s,'blammo6') = 0) player.weapons[2] := 18;
   if player.weapons[2] >= 0 then
   begin
     loadweapon(player.weapons[2]);
     player.currentweapon := 2;
     weapmode := 0;
      end;
    end;
  specialcode := false;
  memset(secretbuf,0,sizeof(secretbuf));
  secretindex := 0;
  end;


procedure CheckSpawnAreas;
begin
  spawnarea_t *sa;
  i, count, type, stype: integer;
  scaleobj_t  *sprite_p;

  if (specialeffect = SE_WARPJAMMER) exit;
  if (netwarpjammer) and (netwarpjamtime>(int)timecount) exit;

  sa := spawnareas;
  for(i := 0;i<numspawnareas;i++,sa++)
  if timecount >= sa.time then
  begin
    if (mapsprites[sa.mapspot] = 0) and (sa.mapspot <> player.mapspot) then
    begin
      case sa.type  of
      begin
  0:
   if not netmode then
   begin
{$IFDEF DEMO}
      type := (clock+MS_RndT) mod 110;
     {$ELSE}
      type := (clock+MS_RndT) mod 114;
     {$ENDIF}
     if (type<30) stype := S_ENERGY;
      else if (type<60) stype := S_BALLISTIC;
      else if (type<90) stype := S_PLASMA;
{$IFDEF DEMO}
      else if (type<96) stype := S_IGRENADE;
      else if (type<98) stype := S_IREVERSO;
      else if (type<102) stype := S_IPROXMINE;
      else if (type<106) stype := S_ITIMEMINE;
      else if (type<108) stype := S_IINSTAWALL;
      else stype := S_ICLONE;
     {$ELSE}
      else if (type<96) stype := S_IGRENADE;
      else if (type<98) stype := S_IREVERSO;
      else if (type<102) stype := S_IPROXMINE;
      else if (type<106) stype := S_ITIMEMINE;
      else if (type<108) stype := S_IINSTAWALL;
      else if (type<110) stype := S_ICLONE;
      else if (type<112) stype := S_IJAMMER;
      else stype := S_ISTEALER;
     {$ENDIF}
     sa.time := timecount+(clock) and (255) + 3500 - (350*(player.difficulty+1));
      end;
   else
   begin
{$IFDEF DEMO}
      type := (clock+MS_RndT) mod 110;
     {$ELSE}
      type := (clock+MS_RndT) mod 146;
     {$ENDIF}
     if (type<30) stype := S_ENERGY;
      else if (type<60) stype := S_BALLISTIC;
      else if (type<90) stype := S_PLASMA;
{$IFDEF DEMO}
      else if (type<96) stype := S_IGRENADE;
      else if (type<98) stype := S_IREVERSO;
      else if (type<102) stype := S_IPROXMINE;
      else if (type<106) stype := S_ITIMEMINE;
      else if (type<108) stype := S_IDECOY;
      else stype := S_IINSTAWALL;
     {$ELSE}
      else if (type<98) stype := S_IGRENADE;
      else if (type<102) stype := S_IREVERSO;
      else if (type<112) stype := S_IPROXMINE;
      else if (type<116) stype := S_ITIMEMINE;
      else if (type<120) stype := S_IDECOY;
      else if (type<134) stype := S_IINSTAWALL;
      else if (type<138) stype := S_IINVIS;
      else if (type<142) stype := S_ISTEALER;
      else stype := S_IHOLO;
     {$ENDIF}
     sa.time := timecount + (clock) and (255) + (9-greedcom.numplayers)*437;
      end;
   break;
  1:
   if not netmode then
   begin
{$IFDEF DEMO}
      type := (clock+MS_RndT) mod 110;
     {$ELSE}
      type := (clock+MS_RndT) mod 114;
     {$ENDIF}
     if (type<15) stype := S_MEDPAK1;
      else if (type<22) stype := S_MEDPAK2;
      else if (type<30) stype := S_MEDPAK3;
      else if (type<45) stype := S_MEDPAK4;
      else if (type<60) stype := S_SHIELD4;
      else if (type<67) stype := S_SHIELD3;
      else if (type<75) stype := S_SHIELD2;
      else if (type<90) stype := S_SHIELD1;
{$IFDEF DEMO}
      else if (type<96) stype := S_IGRENADE;
      else if (type<98) stype := S_IREVERSO;
      else if (type<102) stype := S_IPROXMINE;
      else if (type<106) stype := S_ITIMEMINE;
      else if (type<108) stype := S_IINSTAWALL;
      else stype := S_ICLONE;
     {$ELSE}
      else if (type<96) stype := S_IGRENADE;
      else if (type<98) stype := S_IREVERSO;
      else if (type<102) stype := S_IPROXMINE;
      else if (type<106) stype := S_ITIMEMINE;
      else if (type<108) stype := S_IINSTAWALL;
      else if (type<110) stype := S_ICLONE;
      else if (type<112) stype := S_IJAMMER;
      else stype := S_ISTEALER;
     {$ENDIF}
     sa.time := timecount+(clock) and (255) + 3500 - (350*(player.difficulty+1));
      end;
   else
   begin
{$IFDEF DEMO}
      type := (clock+MS_RndT) mod 110;
     {$ELSE}
      type := (clock+MS_RndT) mod 116;
     {$ENDIF}
     if (type<15) stype := S_MEDPAK1;
      else if (type<22) stype := S_MEDPAK2;
      else if (type<30) stype := S_MEDPAK3;
      else if (type<45) stype := S_MEDPAK4;
      else if (type<60) stype := S_SHIELD4;
      else if (type<67) stype := S_SHIELD3;
      else if (type<75) stype := S_SHIELD2;
      else if (type<90) stype := S_SHIELD1;
{$IFDEF DEMO}
      else if (type<96) stype := S_IGRENADE;
      else if (type<98) stype := S_IREVERSO;
      else if (type<102) stype := S_IPROXMINE;
      else if (type<106) stype := S_ITIMEMINE;
      else if (type<108) stype := S_IDECOY;
      else stype := S_IINSTAWALL;
     {$ELSE}
      else if (type<96) stype := S_IGRENADE;
      else if (type<98) stype := S_IREVERSO;
      else if (type<102) stype := S_IPROXMINE;
      else if (type<106) stype := S_ITIMEMINE;
      else if (type<108) stype := S_IDECOY;
      else if (type<110) stype := S_IINSTAWALL;
      else if (type<110) stype := S_IINVIS;
      else if (type<112) stype := S_IJAMMER;
      else if (type<114) stype := S_ISTEALER;
      else stype := S_IHOLO;
     {$ENDIF}
     sa.time := timecount + (clock) and (255) + (9-greedcom.numplayers)*437;
      end;
   break;
  10:
   stype := S_MONSTER1;
   sa.time := timecount+(clock) and (255) + (2100*(player.difficulty+1));
   break;
  11:
   stype := S_MONSTER2;
   sa.time := timecount+(clock) and (255) + (4200*(player.difficulty+1));
   break;
  12:
   stype := S_MONSTER3;
   sa.time := timecount+(clock) and (255) + (2100*(player.difficulty+1));
   break;
  13:
   stype := S_MONSTER4;
   sa.time := timecount+(clock) and (255) + (10500*(player.difficulty+1));
   break;
  14:
   stype := S_MONSTER5;
   sa.time := timecount+(clock) and (255) + (4200*(player.difficulty+1));
   break;
  15:
   stype := S_MONSTER6;
   sa.time := timecount+(clock) and (255) + (4200*(player.difficulty+1));
   break;
  16:
   stype := S_MONSTER7;
   sa.time := timecount+(clock) and (255) + (4200*(player.difficulty+1));
   break;
  17:
   stype := S_MONSTER8;
   sa.time := timecount+(clock) and (255) + (4200*(player.difficulty+1));
   break;
  18:
   stype := S_MONSTER9;
   sa.time := timecount+(clock) and (255) + (4200*(player.difficulty+1));
   break;
  19:
   stype := S_MONSTER10;
   sa.time := timecount+(clock) and (255) + (1200*(player.difficulty+1));
   break;
  20:
   stype := S_MONSTER11;
   sa.time := timecount+(clock) and (255) + (4200*(player.difficulty+1));
   break;
  21:
   stype := S_MONSTER12;
   sa.time := timecount+(clock) and (255) + (4200*(player.difficulty+1));
   break;
  22:
   stype := S_MONSTER13;
   sa.time := timecount+(clock) and (255) + (4200*(player.difficulty+1));
   break;
  23:
   stype := S_MONSTER14;
   sa.time := timecount+(clock) and (255) + (4200*(player.difficulty+1));
   break;
  24:
   stype := S_MONSTER15;
   sa.time := timecount+(clock) and (255) + (4200*(player.difficulty+1));
   break;

  100:
   stype := S_MONSTER8_NS;
   sa.time := timecount+(clock) and (255) + (4200*(player.difficulty+1));
   break;
  101:
   stype := S_MONSTER9_NS;
   sa.time := timecount+(clock) and (255) + (4200*(player.difficulty+1));
   break;
   end;

      if sa.type >= 10 then
      begin
  count := 0;
  for (sprite_p := firstscaleobj.next; sprite_p <> @lastscaleobj;sprite_p := sprite_p.next)
   if (sprite_p.type = stype) and (sprite_p.hitpoints) ++count;
   end;
      else count := 0;

      if count<MAXSPAWN then
      begin
  for (sprite_p := firstscaleobj.next; sprite_p <> @lastscaleobj;sprite_p := sprite_p.next)
   if ((sprite_p.type = S_GENERATOR) or ((sprite_p.type >= S_GENSTART) and (sprite_p.type <= S_GENEND)) then
   ) and (sprite_p.x = sa.mapx) and (sprite_p.y = sa.mapy)
   begin
     sprite_p := sprite_p.prev;
     RF_RemoveSprite(sprite_p.next);
      end;
  if sa.type >= 10 then
   for (sprite_p := firstscaleobj.next; sprite_p <> @lastscaleobj;sprite_p := sprite_p.next)
    if (sprite_p.type = stype) and (sprite_p.hitpoints = 0) then
    begin
      RF_RemoveSprite(sprite_p);
      break;
       end;
  if (not netmode) or ((netmode) and (playernum = 0)) then
  begin
    SpawnSprite(stype,sa.mapx,sa.mapy,0,0,0,0,true,0);
    SpawnSprite(S_WARP,sa.mapx,sa.mapy,0,0,0,0,true,0);
    if (netmode) and (sa.type >= 10) then
     NetSendSpawn(stype,sa.mapx,sa.mapy,0,0,0,0,true,0);
     end;
   end;
       end;
    else sa.time := timecount+(clock) and (255) + 7000;
     end;
  end;


procedure CheckBonusItem;
begin
  scaleobj_t *sprite;

  if timecount>BonusItem.time then
  begin
   if (netmode) and (playernum <> 0) exit; // player 0 spawns the bonuses

   if BonusItem.score>0 then
   begin
     for (sprite := firstscaleobj.next; sprite <> @lastscaleobj;sprite := sprite.next)
      if sprite.type = S_BONUSITEM then
      begin
  RF_RemoveSprite(sprite);
  mapsprites[BonusItem.mapspot] := 0;
  break;
   end;
      SpawnSprite(S_WARP,(BonusItem.tilex*MAPSIZE+32) shl FRACBITS,(BonusItem.tiley*MAPSIZE+32) shl FRACBITS,0,0,0,0,false,0);
      end;
   do
   begin
     BonusItem.tilex := (clock+MS_RndT)) and (63;
     BonusItem.tiley := (clock+MS_RndT)) and (63;
     BonusItem.mapspot := BonusItem.tiley*MAPCOLS + BonusItem.tilex;
      end; while (floorpic[BonusItem.mapspot] = 0) or (mapsprites[BonusItem.mapspot]) or (mapeffects[BonusItem.mapspot]) and (FL_FLOOR
  ) or (floorheight[BonusItem.mapspot] = ceilingheight[BonusItem.mapspot]);
   BonusItem.score := 2000 + (clock) and (7)*300;
   BonusItem.time := timecount + bonustime + (clock) and (1023);
   BonusItem.num := clock mod MAXRANDOMITEMS;
   BonusItem.name := randnames[BonusItem.num];
   BonusItem.sprite := SpawnSprite(S_BONUSITEM,(BonusItem.tilex*MAPSIZE+32) shl FRACBITS,(BonusItem.tiley*MAPSIZE+32) shl FRACBITS,0,0,0,0,false,0);
   SpawnSprite(S_WARP,(BonusItem.tilex*MAPSIZE+32) shl FRACBITS,(BonusItem.tiley*MAPSIZE+32) shl FRACBITS,0,0,0,0,false,0);
   BonusItem.sprite.basepic := BonusItem.sprite.basepic + BonusItem.num;
   oldgoalitem := -1;
   if (netmode) NetBonusItem;
   goalitem := 0;
    end;
  end;


procedure TimeUpdate;
begin
  time: integer;
  MSG    msg;

  if (PeekMessage and (msg,NULL,0,0,PM_REMOVE)) then
    DispatchMessage and (msg);

  chargeweapons;
  UpdateMouse;
  if (netmode) NetGetData;
  if netmode then
  begin
   NetGetData;
   if timecount>netsendtime then
   begin
     if (player.angst) NetSendPlayerData;
     netsendtime := timecount + 3 + greedcom.numplayers;
      end;
   NetGetData;
    end;
  time := timecount;
  UpdateSound;
  while time >= spritemovetime do
  begin
   if (netmode) NetGetData;
   if numprocesses then
   begin
     Process;
     if (netmode) NetGetData;
      end;

//   if (recording) or (playback) rndofs := 0;

   memset(reallight,0,MAPROWS*MAPCOLS*4);
   MoveSprites;

   if netmode then
   begin
     NetGetData;
     spritemovetime := spritemovetime + 2;
      end;

   spritemovetime := spritemovetime + 8;
    end;
  UpdateMouse;
  if (netmode) NetGetData;
  if (numspawnareas) CheckSpawnAreas;
  if (netmode) NetGetData;
  CheckElevators;
  if (netmode) NetGetData;
  CheckBonusItem;
  if (netmode) NetGetData;
  if doorsound then
  begin
   doorsound := false;
   SoundEffect(SN_DOOR,15,doorx,doory);
    end;
  if (netmode) NetGetData;
  UpdateMouse;
  end;


extern pevent_t playerdata[MAXPLAYERS];


procedure RearView;
begin
  scrollmin1, scrollmax1, view, location: integer;

  view := currentViewSize*2;
  location := viewLocation;
  windowWidth := 64;
  windowHeight := 64;
  windowLeft := 0;
  windowTop := 0;
  windowSize := 4096;
  viewLocation := (int)screen;
  scrollmin1 := player.scrollmin;
  scrollmax1 := player.scrollmax;
  SetViewSize(windowWidth,windowHeight);
  ResetScalePostWidth(windowWidth);
  scrollmin := 0;
  scrollmax := 64;
  memcpy(pixelangle,campixelangle,sizeof(pixelangle));
  memcpy(pixelcosine,campixelcosine,sizeof(pixelcosine));
  if (enemyviewmode) and (goalitem>0) then
  RF_RenderView(playerdata[goalitem-1].x,playerdata[goalitem-1].y,playerdata[goalitem-1].z,playerdata[goalitem-1].angle);
  else
  RF_RenderView(player.x,player.y,player.z,player.angle+WEST);
  memcpy(rearbuf,viewbuffer,sizeof(rearbuf));
  windowLeft := viewLoc[view];
  windowTop := viewLoc[view+1];
  viewLocation := location;
  SetViewSize(viewSizes[view],viewSizes[view+1]);
  ResetScalePostWidth(windowWidth);
  memcpy(pixelangle,wallpixelangle,sizeof(pixelangle));
  memcpy(pixelcosine,wallpixelcosine,sizeof(pixelcosine));
  player.scrollmin := scrollmin1;
  player.scrollmax := scrollmax1;
  end;


procedure NewGoalItem;
begin
  togglegoalitem := false;
  goalitem++;

  if not netmode then
  begin
   if (goalitem = 0) and (BonusItem.score = 0) goalitem++;
   while (goalitem >= 1) and (goalitem <= 2) and (primaries[(goalitem-1)*2] = -1) goalitem++;
   while (goalitem >= 3) and (goalitem <= 9) and (secondaries[(goalitem-3)*2] = -1) goalitem++;
   if goalitem >= 10 then
   begin
     goalitem := 0;
     if (goalitem = 0) and (BonusItem.score = 0) goalitem++;
     while (goalitem >= 1) and (goalitem <= 2) and (primaries[(goalitem-1)*2] = -1) goalitem++;
     while (goalitem >= 3) and (goalitem <= 9) and (secondaries[(goalitem-3)*2] = -1) goalitem++;
     if (goalitem = 10) goalitem := -1;
      end;
    end;
  else
  begin
   if (goalitem = 0) and (BonusItem.score = 0) goalitem++;
   if goalitem>greedcom.numplayers then
   begin
     goalitem := 0;
     if (goalitem = 0) and (BonusItem.score = 0) goalitem++;
     if goalitem>greedcom.numplayers then
      goalitem := -1;
      end;
    end;
  end;


procedure GrabTheScreen;
begin
  FILE *f;
  char name[15];
  byte palette[768];
  static int count := 0;

  if (MS_CheckParm('GRAB')) then
  begin
   sprintf(name,'grab%i.raw',count);
   ++count;
   f := fopen(name,'wb');
   if f = NULL then
    MS_Error('Error opening the screen grab file!');
   fwrite((char *)0xa0000,64000,1,f);
   VI_GetPalette(palette);
   fwrite(palette,768,1,f);
   fclose(f);
    end;
  SaveTheScreen := false;
  end;


procedure startover(int restartvalue);
begin
  i: integer;

  if (netmode) NetGetData;
  resetdisplay;
  if restartvalue <> 1 then
  begin
   player.score := 0;
   player.levelscore := levelscore;
   player.weapons[2] := -1;
   player.weapons[3] := -1;
   player.weapons[4] := -1;
   player.currentweapon := 0;
   loadweapon(player.weapons[0]);

   if not netmode then
   begin
     memset(player.inventory,0,sizeof(player.inventory));
     player.inventory[7] := 2;
     player.inventory[5] := 2;
     player.inventory[4] := 2;
     player.inventory[2] := 4;
      end;
   else
   begin
     if player.inventory[7]<2 then
      player.inventory[7] := 2;
     if player.inventory[5]<2 then
      player.inventory[5] := 2;
     if player.inventory[4]<2 then
      player.inventory[4] := 2;
     if player.inventory[2]<4 then
      player.inventory[2] := 4;
      end;
   player.bodycount := 0;
   player.ammo[0] := 100;
   player.ammo[1] := 100;
   player.ammo[2] := 100;
   player.angst := player.maxangst;
   player.shield := 200;
    end;
  player.holopic := 0;

  if not netmode then
  begin
   newmap(player.map,restartvalue);
   INT_TimerHook(PlayerCommand);
    end;
  else
  respawnplayer;

  if (netmode) NetGetData;

  exitexists := false;
  specialeffecttime := 0;
  ExitLevel := false;
  if currentViewSize >= 5 then
  VI_DrawPic(4,149,statusbar[2]);
  if currentViewSize >= 4 then
  VI_DrawMaskedPic(0,0,statusbar[3]);
  if (netmode) NetGetData;
  turnrate := 0;
  moverate := 0;
  fallrate := 0;
  strafrate := 0;
  deadrestart := false;
  player.primaries[0] := 0;
  player.primaries[1] := 0;
  for(i := 0;i<7;i++)
  player.secondaries[i] := 0;
  end;


procedure EndLevel;
begin
  VI_FadeOut(0,256,0,0,0,64);
  memset(screen,0,64000);
  VI_SetPalette(CA_CacheLump(CA_GetNamedNum('palette')));
  ++player.map;
  startover(1);
  end;


procedure WarpAnim;
begin
  if Warping = 1 then
  begin
   CA_ReadLump(CA_GetNamedNum('WARPLIGHTS'),colormaps);
   Warping := 2;
  end
  else if Warping = 2 then
  begin
   if (lighting >= 128) changelight := -128;
   else
   begin
     Warping := 3;
     player.x := WarpX;
     player.y := WarpY;
      end;
  end
  else if Warping = 3 then
  begin
   if (lighting<SC.ambientlight) changelight := 128;
   else
   begin
     CA_ReadLump(CA_GetNamedNum('LIGHTS'),colormaps);
     Warping := 0;
      end;
    end;
  end;


procedure DrawHolo;
begin
  i, j, count, bottom, top, x, y: integer;
  byte       *collumn;
  scalepic_t *spic;

  spic := lumpmain[player.holopic]; // draw the pic for it
  x := 5;
  for (i := 0;i<spic.width;i++,x++)
  if spic.collumnofs[i] then
  begin
    collumn := (byte *)spic+spic.collumnofs[i];
    top := *(collumn+1);
    bottom := *(collumn);
    count := bottom-top+1;
    collumn := collumn + 2;
    y := windowHeight-top-count-5;
    for (j := 0;j<count;j++,collumn++,y++)
     if (y >= 0) and (*collumn) *(viewylookup[y]+x) := *collumn;
     end;
  end;


procedure RunMenu;
begin
  player.timecount := timecount;
  ShowMenu(0);
  if (not netmode) timecount := player.timecount;
  activatemenu := false;
  INT_TimerHook(PlayerCommand);
  keyboardDelay := timecount+KBDELAY;
  end;


procedure RunHelp;
begin
  player.timecount := timecount;
  INT_TimerHook(NULL);
  ShowHelp;
  INT_TimerHook(PlayerCommand);
  activatehelp := false;
  timecount := player.timecount;
  keyboardDelay := timecount+KBDELAY;
  end;


procedure RunQuickExit;
begin
  QuickExit := false;
  MouseShow;
  if (ShowQuit(PlayerCommand)) quitgame := true;
  MouseHide;
  keyboardDelay := timecount+KBDELAY;
  end;


procedure RunPause;
begin
  if paused then
  begin
   gamepause := true;
   if (netmode) NetPause;
    end;
  player.timecount := timecount;
  ShowPause;
  timecount := player.timecount;
  if (paused) and (netmode) NetUnPause;
  paused := false;
  gamepause := false;
  INT_TimerHook(PlayerCommand);
  keyboardDelay := timecount+KBDELAY;
  end;


procedure PrepareNexus;
begin
  i, j, mapspot, x, y: integer;

  for(i := -MAPCOLS;i <= MAPCOLS;i+:= MAPCOLS)
  for(j := -1;j <= 1;j++)
  begin
    mapspot := player.mapspot+i+j;
    if (mapspot <> player.mapspot) and (floorpic[mapspot]) and (mapsprites[mapspot] = 0) then
    begin
      x := ((player.mapspot+i+j)) and (63)*MAPSIZE+32;
      y := ((player.mapspot+i+j)/64)*MAPSIZE+32;
      SpawnSprite(S_EXIT,x shl FRACBITS,y shl FRACBITS,0,0,0,0,0,0);
      SoundEffect(SN_NEXUS,0,x shl FRACBITS,y shl FRACBITS);
      SoundEffect(SN_NEXUS,0,x shl FRACBITS,y shl FRACBITS);
      exitexists := true;
      writemsg('Translation Nexus Created!');
      exit;
       end;
     end;
  end;


procedure RunBrief;
begin
  memcpy(viewbuffer,screen,64000);
  MissionBriefing(player.map);
  INT_TimerHook(PlayerCommand);
  memcpy(screen,viewbuffer,64000);
  activatebrief := false;
  end;


procedure JamWarps;
begin
  scaleobj_t  *sp, *t;
  mapspot, i: integer;
  spawnarea_t *sa;

  if specialeffect <> SE_WARPJAMMER then
  begin
   specialeffect := SE_WARPJAMMER;
   specialeffecttime := timecount+70*60;
   totaleffecttime := 70*60;
   --player.inventory[11];
   for (sp := firstscaleobj.next; sp <> @lastscaleobj;)
    if (sp.type = S_GENERATOR) or ((sp.type >= S_GENSTART) and (sp.type <= S_GENEND)) then
    begin
      mapspot := (sp.y shr FRACTILESHIFT)*MAPCOLS + (sp.x shr FRACTILESHIFT);
      mapsprites[mapspot] := 0;
      t := sp;
      sp := sp.next;
      RF_RemoveSprite(t);
       end;
    else
     sp := sp.next;
   sa := spawnareas;
   for(i := 0;i<numspawnareas;i++,sa++)
    sa.time := timecount;
   writemsg('Used Warp Jammer');
    end;
  warpjammer := false;
  end;


procedure SelectNewSong;
begin
  songnum++;
  songnum mod  := 32;
  selectsong(songnum);
  newsong := false;
  end;


procedure UpdateView(fixed_t px,fixed_t py,fixed_t pz,int angle,int update);
begin
  weaponx, weapony, i, x: integer;
  pic_t        *pic;
  static pic_t *wpic;
  char         dbg[80];
  static int   weapbob1, wx, wy;

  angle) and (:= ANGLES;

  if update then
  weapbob1 := weapbob;

  if update then
  rtimecount := timecount;
  RF_RenderView(px,py,pz,angle);

  if (update = 1) TimeUpdate;

  if (player.holopic) DrawHolo;

  if (netmode) NetGetData;

  if timecount<RearViewTime then
  begin
   x := windowWidth-66;
   for(i := 1;i<64;i++)
   begin
     memcpy(viewylookup[i+1]+x,rearbuf+(i shl 6),64);
     *(viewylookup[i+1]+x-1) := 30;
     *(viewylookup[i+1]+x+64) := 30;
      end;
   memset(viewylookup[65]+x-1,30,66);
   memset(viewylookup[1]+x-1,30,66);
    end;

(* update sprite movement *)
  if (update = 1) TimeUpdate;

(* draw the weapon pic *)

  if (player.angst)  // only if alive
  begin
   if update then
    wpic := weaponpic[weapmode];

   weaponx := ((windowWidth-wpic.width) shr 1) + (weapmove[weapbob1] shr 1);
   weapony := windowHeight - wpic.height + (weapmove[weapbob1/2] shr 3);

     if (currentViewSize >= 6) weapony+:= 25;
      else if (currentViewSize = 5) weapony+:= 15;
     if (changingweapons) and (weaponlowering) then
     begin
       weaponychange := weaponychange + 15;
       weapony := weapony + weaponychange;
       if weapony >= windowHeight-20 then
       begin
   weaponlowering := false;
   player.currentweapon := newweapon;
   loadweapon(player.weapons[newweapon]);
   weapmode := 0;
   wpic := weaponpic[weapmode];
   weaponychange := weaponpic[weapmode].height-20;
   weapony := windowHeight-21;
   weaponx := ((windowWidth-wpic.width) shr 1) + (weapmove[weapbob1] shr 1);
    end;
     end
     else if changingweapons then
     begin
       weaponychange := weaponychange - 10;
       if (weaponychange <= 0) changingweapons := false;
  else weapony := weapony + weaponychange;
        end;

   if update then
   begin
     wx := weaponx;
     wy := weapony;
      end;
   else
   begin
     weaponx := wx;
     weapony := wy;
      end;

   if (netmode) NetGetData;
   if (weapmode = 0) VI_DrawMaskedPicToBuffer2(weaponx,weapony,wpic);
    else VI_DrawMaskedPicToBuffer(weaponx,weapony,wpic);
    end;

(* update sprite movement *)
  if (update = 1) TimeUpdate;

(* update displays *)

  if (mapmode = 1) displaymapmode;
  else if (mapmode = 2) displayswingmapmode;
  else if (mapmode) MS_Error('PlayLoop: mapmode %i',mapmode);
  if heatmode then
  begin
   if (mapmode) displayheatmapmode;
    else displayheatmode;
    end;
  if motionmode then
  begin
   if (mapmode) displaymotionmapmode;
    else displaymotionmode;
    end;

  if (netmode) NetGetData;

  if (currentViewSize>0) and (currentViewSize <= 4) then
  begin
   if (currentViewSize = 4) pic := statusbar[2];
    else pic := statusbar[currentViewSize-1];
   VI_DrawMaskedPicToBuffer(statusbarloc[currentViewSize*2],statusbarloc[currentViewSize*2+1],pic);
    end;

  if (netmode) NetGetData;

  updatedisplay;

  if (netmode) NetGetData;

(* display the message string *)
  rewritemsg;

(* finally draw it *)

  if (netmode) NetGetData;

  if ticker then
  begin
   sprintf(dbg,'sp:%-4i tp:%-4i ver:%-4i e:%-4i mu:%-2i t:%3i:%2i',
    numspans,transparentposts,vertexlist_p-vertexlist,entry_p-entries,greedcom.maxusage,timecount/4200,(timecount/70) mod 60);
//     sprintf(dbg,'x: %i  y: %i',(player.x shr FRACBITS)) and (63,(player.y shr FRACBITS)) and (63);
   fontbasecolor := 73;
   font := font1;
   printx := 2;
   printy := 19;
   FN_RawPrint2(dbg);
    end;
  if netmsgstatus = 1 then
  begin
   fontbasecolor := 73;
   font := font1;
   printx := 2;
   printy := 19;
   sprintf(dbg,'Message: %s',netmsg);
   FN_RawPrint2(dbg);
  end
  else if netmsgstatus = 2 then
  begin
   NetSendMessage(netmsg);
   netmsgstatus := 0;
    end;

(* update sprite movement *)
  if update = 1 then
  TimeUpdate;
  end;

procedure PlayLoop ;
begin
  i: integer;

  if (netmode) NetWaitStart;
  else timecount := 0;

  while not quitgame do
  begin
   if fliplayed then
   begin
     if deadrestart then
     begin
    memset(screen,0,64000);

    VI_SetPalette(CA_CacheLump(CA_GetNamedNum('palette')));

       startover(2);
        end;
     continue;
      end;
   if (netmode) NetGetData;
   if toggleautorun then
   begin
     autorun) xor (:= 1;
     if (autorun) writemsg('Auto-Run On');
      else writemsg('Auto-Run Off');
     toggleautorun := false;
      end;
   if toggleautotarget then
   begin
     autotarget) xor (:= 1;
     if autotarget then
      writemsg('Auto-Target On');
     else
      writemsg('Auto-Target Off');
     toggleautotarget := false;
      end;
   if goiright then
   begin
     inventoryright;
     goiright := false;
      end;
   if goileft then
   begin
     inventoryleft;
     goileft := false;
      end;
   if useitem then
   begin
     useinventory;
     useitem := false;
      end;
   if checktrigger then
   begin
     checktrigger := false;
     CheckHere(true,player.x,player.y,player.angle);
     if fliplayed then
      continue;
      end;
   if (warpjammer) JamWarps;
   if (netmode) NetGetData;
   if falldamage then
     begin  // just makes a grunt sound
     SoundEffect(SN_HIT0+player.chartype,15,player.x,player.y);
     if (netmode) NetSoundEffect(SN_HIT0+player.chartype,15,player.x,player.y);
     falldamage := 0;
      end;

   if (player.levelscore = 0) and ( not exitexists) and ( not netmode) and (
    ((primaries[0] <> -1) and (player.primaries[0] = pcount[0])) or (primaries[0] = -1)) and (
    ((primaries[2] <> -1) and (player.primaries[1] = pcount[1])) or (primaries[2] = -1))
    PrepareNexus;

   if ExitLevel then
   begin
     EndLevel;
     if player.map >= 22 then
     begin
       quitgame := true;
       exit;
        end;
      end;

   if (netmode) NetGetData;

   if timecount>specialeffecttime then
   begin
     specialeffect := 0;
     specialeffecttime := $7FFFFFFF;
      end;
   if firegrenade then
   begin
     SpawnSprite(S_GRENADE,player.x,player.y,player.z,player.height-(50 shl FRACBITS),player.angle,(-player.scrollmin)) and (ANGLES,true,playernum);
     SoundEffect(SN_GRENADE,0,player.x,player.y);
     if (netmode) NetSoundEffect(SN_GRENADE,0,player.x,player.y);
     --player.inventory[2];
     firegrenade := false;
      end;

   if (netmode) NetGetData;

   if (Warping) WarpAnim;

   if (netmode) NetGetData;

(* check special code flag *)
   if (specialcode) Special_Code(secretbuf);

(* update sprite movement *)
   TimeUpdate;

(* update wallanimation *)
   if timecount >= wallanimationtime then
   begin
     wallanimcount++;
     case wallanimcount mod 3  of
     begin
       0:
  flattranslation[57] := 58;
  flattranslation[58] := 59;
  flattranslation[59] := 57;
  flattranslation[217] := 218;
  flattranslation[218] := 219;
  flattranslation[219] := 217;
  walltranslation[228] := 229;
  walltranslation[229] := 230;
  walltranslation[230] := 228;
  break;
       1:
  flattranslation[57] := 59;
  flattranslation[58] := 57;
  flattranslation[59] := 58;
  flattranslation[217] := 219;
  flattranslation[218] := 217;
  flattranslation[219] := 218;
  walltranslation[228] := 230;
  walltranslation[229] := 228;
  walltranslation[230] := 229;
  break;
       2:
  flattranslation[57] := 57;
  flattranslation[58] := 58;
  flattranslation[59] := 59;
  flattranslation[217] := 217;
  flattranslation[218] := 218;
  flattranslation[219] := 219;
  walltranslation[228] := 228;
  walltranslation[229] := 229;
  walltranslation[230] := 230;
  break;
        end;
     wallanimationtime := timecount+12;
     if netmode then
      NetGetData;
     if (floorflags[player.mapspot]) and (F_DAMAGE) and (player.z = RF_GetFloorZ(player.x,player.y)+player.height) then
      hurt(30);
      end;

   CheckWarps(player.x,player.y);
   if fliplayed then
    continue;

   CheckDoors(player.x,player.y);
   if (netmode) NetGetData;
   if (deadrestart) startover(2);
   if (resizeScreen) ChangeViewSize(biggerScreen);
   if (netmode) NetGetData;
   if (scrollview) ChangeScroll;

(* update sprite movement *)
   TimeUpdate;

(* check display toggle flags *)
   if toggleheatmode then
   begin
     if (heatmode) heatmode := false;
     else
     begin
       heatmode := true;
       if (mapmode = 2) mapmode := 1;
        end;
     toggleheatmode := false;
      end;
   if togglemotionmode then
   begin
     if (motionmode) motionmode := false;
     else
     begin
       motionmode := true;
       if (mapmode = 2) mapmode := 1;
        end;
     togglemotionmode := false;
      end;
   if togglemapmode then
   begin
     case mapmode  of
     begin
       0:
  mapmode := 1;
  break;
       1:
  if (heatmode) or (motionmode) mapmode := 0;
   else mapmode := 2;
  break;
       2:
  mapmode := 0;
        end;
     togglemapmode := false;
      end;
   if (togglegoalitem) NewGoalItem;
   if ToggleRearView then
   begin
     RearViewOn) xor (:= 1;
     ToggleRearView := false;
     RearViewDelay := timecount;
      end;

   if (netmode) NetGetData;

(* render the view *)
   if (RearViewOn) and (timecount >= RearViewDelay) then
   begin
     RearViewTime := timecount+140;
     RearView;
     RearViewDelay := timecount+SC.camdelay;
     if SC.camdelay = 70 then
      RearViewOn := false;
      end;

   if (netmode) NetGetData;

   scrollmin := player.scrollmin;
   scrollmax := player.scrollmax;
   
   (*for (i :=  0 ; i < 200 ; i++)
     memset(ylookup[i],i,320);
   VI_BlitView;*)

   UpdateView(player.x,player.y,player.z,player.angle,1);

   RF_BlitView;
   VI_BlitView;
  
   if (newsong) SelectNewSong;

   if (activatemenu) RunMenu;

   if (activatehelp) RunHelp;

   if (activatebrief) RunBrief;

   TimeUpdate;

   if (QuickExit) RunQuickExit;

   if (netmode) NetGetData;

   if (paused) or (netpaused) RunPause;

   ++frames;

(* update sprite movement *)
   TimeUpdate;

(* update lights if necessary *)
   if (changelight <> 0) newlights;

(* update weapon to be displayed *)
   while (weapmode) and (timecount >= weapdelay) do
   begin
     if (player.weapons[player.currentweapon] = 4) or (player.weapons[player.currentweapon] = 18) then
     begin
       if weapmode = 1 then
       begin
   if player.weapons[player.currentweapon] = 4 then
   begin
     SoundEffect(SN_BULLET4,0,player.x,player.y);
     if (netmode) NetSoundEffect(SN_BULLET4,0,player.x,player.y);
      end;
   if player.weapons[player.currentweapon] = 18 then
   begin
     SoundEffect(SN_BULLET18,0,player.x,player.y);
     if netmode then
      NetSoundEffect(SN_BULLET18,0,player.x,player.y);
      end;
    end;
       weapmode := weaponstate[player.weapons[player.currentweapon]][weapmode];
       if weapmode = 0 then
  fireweapon;
        end;
     else
      weapmode := weaponstate[player.weapons[player.currentweapon]][weapmode];
     weapdelay := timecount+8;
      end;

   if (netmode) NetGetData;
    end;
  end;


procedure ActionHook ;
begin
  actionflag :=  0;
  end;


procedure InitData;
begin
  i: integer;

  quitgame := false;
  mapmode := 0;
  heatmode := false;
  motionmode := false;
  turnrate := 0;
  moverate := 0;
  fallrate := 0;
  strafrate := 0;
  MapZoom := 8;
  memset(secretbuf,0,20);
  secretindex := 0;
//   demobuffer := CA_CacheLump(CA_GetNamedNum('demo'));
  if playback then
  begin
   demobuffer := CA_LoadFile('demo1');
   recordindex := 0;
    end;
  if recording then
  begin
   demobuffer := CA_CacheLump(CA_GetNamedNum('demo'));
   memset(demobuffer,0,RECBUFSIZE);
   recordindex := 0;
    end;
  probe.moveSpeed := MAXPROBE;
  probe.movesize := 16 shl FRACBITS; // half a tile
  probe.spawnid := playernum;
  ChangeViewSize(true);
  ChangeViewSize(true);
  ChangeViewSize(true);
  ChangeViewSize(true);
  ChangeViewSize(false);
  ChangeViewSize(false);
  ChangeViewSize(false);
  ChangeViewSize(false);
  for (i := 0;i<currentViewSize;i++)
  ChangeViewSize(true);
  resetdisplay;
  end;


procedure SaveDemo;
begin
  FILE *f;

  f := fopen('demo1','w');
  fwrite(demobuffer,RECBUFSIZE,1,f);
  fclose(f);
  end;


procedure maingame;
begin
  VI_SetPalette(CA_CacheLump(CA_GetNamedNum('palette')));
  InitData;
  INT_TimerHook(PlayerCommand);   // the players actions are sampled by an interrupt
  newlights;
  PlayLoop;
  player.timecount := timecount;
  if netmode then
   NetQuitGame;
  if recording then
   SaveDemo;
  SaveSetup and (SC,'SETUP.CFG');
  playback := false;
  end;


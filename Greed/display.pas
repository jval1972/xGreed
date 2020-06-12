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
#include 'd_disk.h'
#include 'd_global.h'
#include 'd_video.h'
#include 'd_ints.h'
#include 'r_refdef.h'
#include 'protos.h'

(**** CONSTANTS ****)


char *primnames[] := 
begin
  'Explosives',
  'Head of Warden',
  'Phlegmatic Eel',
  'Byzantium Brass Ring',
  'Sacrificial Dagger',
  'Book of Chants',
  'Holy Incantation Brazier',
  'error 7',
  'Personality Encode',
  'Space Generator',
  'Imperial Sigil',
  'Psiflex Data Module',
  'Fissure Prism',
  'Mummification Glyph',
  'Soylent Brown Narcotic',
  'Viral Stabilization Pods',
  'Idol of the Felasha Pont',
  'Skull Scepter',
  'Sacred Cow of Tooms',
  'Gene Coding Cube',
  'Desecrate Summoning Circle',
  'Power Coupler',
   end;


char *secnames[] := 
begin
  'Inmate Uniforms',
  'Delousing Kits',
  'Truth Serum Vials',
  'Hypodermic Needles',
  'Lubricants',
  'Emergency Lantern',
  'Water Tanks',
  'Oxygen Tanks',
  'Exo-suit',
  'Phosfor Pellets',
  'Plasma Conduit Coupling',
  'Madree 3 Cypher Kit',
  'Security Key',
  'Denatured Bio-Proteins',
  'Neural Reanimation Focus',
  'Shunt Matrix',
  'Plasmoid CryoVice',
  'Rad-Shield Goggles',
  'Prayer Scroll',
  'Silver Beetle',
  'Finger Bones',
  'Pain Ankh',
  'War Slug Larvae',
  'War Slug Food',
  'Ritual Candles',
  'Idth Force Key 1',
  'Idth Force Key 2',
  'Idth Force Key 3',
  'Idth Force Key 4',
  'error 29',
  'error 30',
  'error 31',
  'error 32',
  'Tribolek Game Cubes',
  'Atomic Space Heater',
  'Reactor Coolant Container',
  'Power Flow Calibrator',
  'Verimax Insulated Gloves',
  'Gold Ingots',
  'Soul Orb of Eyul',
  'Prayer Scroll'
   end;


char *ammonames[] := 
begin
  'ENERGY',
  'BULLET',
  'PLASMA',
   end;


char *inventorynames[] := 
begin
  'Medical Tube  ',
  'Shield Charge ',
  'Grenade       ',
  'Reverso Pill  ',
  'Proximity Mine',
  'Time Bomb     ',
  'Decoy         ',
  'InstaWall     ',
  'Clone         ',
  'HoloSuit      ',
//'Portable Hole ',
  'Invisibility  ',
  'Warp Jammer   ',
  'Soul Stealer  '
   end;


(**** VARIABLES ****)

byte    oldcharges[7];       (* delta values (only changes if different) *)
  oldbodycount, oldscore, oldlevelscore: integer;
int     oldshield, oldangst, oldshots, oldgoalitem, oldangle, statcursor := 269,
  oldangstpic, inventorycursor := -1, oldinventory, totaleffecttime,
  inventorylump, primarylump, secondarylump, fraglump;
pic_t   *heart[10];
  firegrenade: boolean;

extern int fragcount[MAXPLAYERS];

(**** FUNCTIONS ****)

(* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = *)

procedure resetdisplay;
(* clears delta values *)
begin
  i: integer;

  memset(oldcharges,-1,7);
  oldbodycount := -1;
  oldshield := -1;
  oldangst := -1;
  oldscore := -1;
  oldshots := -1;
  oldlevelscore := -1;
  oldangle := -1;
  oldangstpic := -1;
  oldinventory := -2;
  oldgoalitem := -1;
  inventorylump := CA_GetNamedNum('medtube');
  primarylump := CA_GetNamedNum('primary');
  secondarylump := CA_GetNamedNum('secondary');
  if netmode then
  begin
   fraglump := CA_GetNamedNum('profiles');
   for (i := 0;i<MAXCHARTYPES;i++)
    CA_CacheLump(fraglump+i);
    end;
  end;


procedure inventoryright;
begin
  if (inventorycursor = -1) inventorycursor := 0;
  else inventorycursor++;
  while (inventorycursor<MAXINVENTORY) and (player.inventory[inventorycursor] = 0) inventorycursor++;
  if inventorycursor >= MAXINVENTORY then
  begin
   inventorycursor := 0;
   while (inventorycursor<MAXINVENTORY) and (player.inventory[inventorycursor] = 0) inventorycursor++;
   if (inventorycursor = MAXINVENTORY) inventorycursor := -1; // nothing found
    end;
  end;


procedure inventoryleft;
begin
  inventorycursor--;
  while (inventorycursor >= 0) and (player.inventory[inventorycursor] = 0) inventorycursor--;
  if inventorycursor <= -1 then
  begin
   inventorycursor := MAXINVENTORY-1;
   while (inventorycursor >= 0) and (player.inventory[inventorycursor] = 0) inventorycursor--;
    end;
  end;


procedure useinventory;
begin
  mindist, pic, x, y, dist, angle, angleinc, i, scale: integer;
  scaleobj_t  *sp;

  if (inventorycursor = -1) or (player.inventory[inventorycursor] = 0) exit;

  case inventorycursor  of
  begin
   0: // medtube
    if player.angst<player.maxangst then
    begin
      medpaks(50);
      --player.inventory[inventorycursor];
      writemsg('Used Medtube');
       end;
    break;
   1: // shield
    if player.shield<player.maxshield then
    begin
      heal(50);
      --player.inventory[inventorycursor];
      writemsg('Used Shield Charge');
       end;
    break;
   2: // grenade
    firegrenade := true;
    break;
   3: // reversopill
    if specialeffect <> SE_REVERSOPILL then
    begin
      specialeffect := SE_REVERSOPILL;
      specialeffecttime := timecount+70*15;
      totaleffecttime := 70*15;
      --player.inventory[inventorycursor];
      writemsg('Used Reverso Pill');
       end;
     break;
   4:
    SpawnSprite(S_PROXMINE,player.x,player.y,0,0,0,0,false,playernum);
    --player.inventory[inventorycursor];
    writemsg('Dropped Proximity Mine');
    break;
   5:
    SpawnSprite(S_TIMEMINE,player.x,player.y,0,0,0,0,false,playernum);
    --player.inventory[inventorycursor];
    writemsg('Dropped Time Bomb');
    break;
   6:
    SpawnSprite(S_DECOY,player.x,player.y,0,0,0,0,false,player.chartype);
    --player.inventory[inventorycursor];
    writemsg('Activated Decoy');
    break;
   7:
    SpawnSprite(S_INSTAWALL,player.x,player.y,0,0,0,0,false,playernum);
    --player.inventory[inventorycursor];
    writemsg('Activated InstaWall');
    break;
   8: // clone
    SpawnSprite(S_CLONE,player.x,player.y,0,0,0,0,false,player.chartype);
    --player.inventory[inventorycursor];
    writemsg('Clone Activated');
    break;
   9: // holosuit
    mindist := $7FFFFFFF;
    for (sp := firstscaleobj.next;sp <> @lastscaleobj;sp := sp.next)
     if (not sp.active) and ( not sp.hitpoints) then
     begin
       x := (player.x-sp.x) shr FRACTILESHIFT;
       y := (player.y-sp.y) shr FRACTILESHIFT;
       dist := x*x+y*y;
       if dist<mindist then
       begin
   pic := sp.basepic;
   scale := sp.scale;
   mindist := dist;
    end;
        end;
     if mindist <> $7FFFFFFF then
     begin
       --player.inventory[inventorycursor];
       player.holopic := pic;
       player.holoscale := scale;
       writemsg('HoloSuit Active');
        end;
     else writemsg('Unsuccessful Holo');
    break;
(*   10: // portable hole
    if mapsprites[player.mapspot] <> 0 then
    begin
      SpawnSprite(S_HOLE,player.x,player.y,0,0,0,0,false,player.chartype);
      --player.inventory[inventorycursor];
      writemsg('Dropped Portable Hole');
       end;
    else
     writemsg('Portable Hole Blocked');
    break; *)
   10: // invisibility
    if specialeffect <> SE_INVISIBILITY then
    begin
      specialeffect := SE_INVISIBILITY;
      specialeffecttime := timecount+70*30;
      totaleffecttime := 70*30;
      --player.inventory[inventorycursor];
      writemsg('Activated Invisibility Shield');
       end;
     break;
   11: // warp jammer
    warpjammer := true;
    break;
   12: // soul stealer
    angleinc := ANGLES/16;
    angle := 0;
    for(i := 0,angle := 0;i<16;i++,angle+:= angleinc)
     SpawnSprite(S_SOULBULLET,player.x,player.y,player.z,player.height-(52 shl FRACBITS),angle,0,true,playernum);
    SoundEffect(SN_SOULSTEALER,0,player.x,player.y);
    SoundEffect(SN_SOULSTEALER,0,player.x,player.y);
    if netmode then
    begin
      NetSendSpawn(S_SOULBULLET,player.x,player.y,player.z,player.height-(52 shl FRACBITS),angle,0,true,playernum);
      NetSoundEffect(SN_SOULSTEALER,0,player.x,player.y);
      NetSoundEffect(SN_SOULSTEALER,0,player.x,player.y);
       end;
    --player.inventory[inventorycursor];
    writemsg('Used Soul Stealer');
    break;
    end;
  oldinventory := -2;
  inventoryleft;
  inventoryright;
  end;


(* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = := *)

procedure displaystats1(int ofs);
begin
  d, i, j, c: integer;
  char str1[20];

  d := (player.shield*28)/player.maxshield;
  for(i := 152+ofs;i <= 159+ofs;i++)
  begin
   c := (d*(i-(152+ofs)))/8 + 140;
   for(j := 272;j <= 300;j++)
    if (*(viewylookup[i]+j) = 254) *(viewylookup[i]+j) := c;
    end;
  for(i := 193+ofs;i <= 199+ofs;i++)
  begin
   c := (d*((199+ofs)-i))/7 + 140;
   for(j := 272;j <= 300;j++)
    if (*(viewylookup[i]+j) = 254) *(viewylookup[i]+j) := c;
    end;
  for(j := 307;j <= 315;j++)
  begin
   c := (d*(315-j))/9 + 140;
   for(i := 165+ofs;i <= 187+ofs;i++)
    if (*(viewylookup[i]+j) = 254) *(viewylookup[i]+j) := c;
    end;
  for(j := 257;j <= 265;j++)
  begin
   c := (d*(j-257))/9 + 140;
   for(i := 165+ofs;i <= 187+ofs;i++)
    if (*(viewylookup[i]+j) = 254) *(viewylookup[i]+j) := c;
    end;
  d := (player.angst*10)/player.maxangst;
  if (d >= 10) d := 9;
  VI_DrawMaskedPicToBuffer(269,161+ofs,heart[d]);
  statcursor := statcursor + 2;
  if (statcursor >= 323) statcursor := 269;
  for(j := 269;j <= 305;j++)
  begin
   if (j>statcursor) c := 113;
   else
   begin
     c := 139 - (statcursor-j);
     if (c<120) c := 113;
      end;
   for(i := 161+ofs;i <= 185+ofs;i++)
    if (*(viewylookup[i]+j) = 254) *(viewylookup[i]+j) := c;
    end;
  font := font2;
  fontbasecolor := 0;
  sprintf(str1,'%3i',player.angst);
  printx := 280;
  printy := 188+ofs;
  FN_RawPrint4(str1);
  end;


procedure displaycompass1(int ofs);
begin
  c, x, y, i: integer;
  x1, y1: fixed_t;

  x := 237;
  x1 := x shl FRACBITS;
  y := 161+ofs;
  y1 := y shl FRACBITS;
  c := 139;
  for(i := 0;i<10;i++,c--)
  begin
   *(viewylookup[y]+x) := c;
   x1 := x1 + costable[player.angle];
   y1-:= FIXEDMUL(sintable[player.angle],54394);
   x := x1 shr FRACBITS;
   y := y1 shr FRACBITS;
    end;
  end;


procedure displaysettings1(int ofs);
begin
  if (heatmode) memset(viewylookup[199+ofs]+236,102,6);
  else memset(viewylookup[199+ofs]+236,0,6);
  if (motionmode) memset(viewylookup[199+ofs]+246,156,6);
  else memset(viewylookup[199+ofs]+246,0,6);
  if (mapmode) memset(viewylookup[199+ofs]+226,133,6);
  else memset(viewylookup[199+ofs]+226,0,6);
  end;


procedure displayinventory1(int ofs);
begin
  n, ammo, lump, maxshots, i, j, count, top, bottom, x, y: integer;
  char       str1[20];
  scalepic_t *pic;
  byte       *collumn;

  font := font2;
  fontbasecolor := 0;
  n := player.weapons[player.currentweapon];
  if weapons[n].ammorate>0 then
  begin
   ammo := player.ammo[weapons[n].ammotype];
   maxshots := weapons[n].ammorate;
    end;
  else
  begin
   ammo := 999;
   maxshots := 999;
    end;
  printx := 186;
  printy := 183+ofs;
  sprintf(str1,'%3i',ammo);
  FN_RawPrint2(str1);
  printx := 203;
  printy := 183+ofs;
  sprintf(str1,'%3i',maxshots);
  FN_RawPrint2(str1);
  printx := 187;
  printy := 191+ofs;
  FN_RawPrint2(ammonames[weapons[n].ammotype]);

  if (inventorycursor = -1) or (player.inventory[inventorycursor] = 0) inventoryright;
  if inventorycursor <> -1 then
  begin
   lump := inventorylump + inventorycursor;
   printx := 149;         // name
   printy := 163+ofs;
   FN_RawPrint2(inventorynames[inventorycursor]);
   font := font3;         // number of items
   printx := 150;
   printy := 172+ofs;
   sprintf(str1,'%2i',player.inventory[inventorycursor]);
   FN_RawPrint2(str1);
   pic := lumpmain[lump]; // draw the pic for it
   x := 128-(pic.width shr 1);
   for (i := 0;i<pic.width;i++,x++)
    if pic.collumnofs[i] then
    begin
      collumn := (byte *)pic+pic.collumnofs[i];
      top := *(collumn+1);
      bottom := *(collumn);
      count := bottom-top+1;
      collumn := collumn + 2;
      y := (188+ofs)-top-count;
      for (j := 0;j<count;j++,collumn++,y++)
       if *collumn then
        *(viewylookup[y]+x) := *collumn;
       end;
    end;
  else
  begin
   printx := 149;   // name
   printy := 163+ofs;
   sprintf(str1,'%14s',' ');
   FN_RawPrint2(str1);
   font := font3;   // number of items
   printx := 150;
   printy := 172+ofs;
   FN_RawPrint2('  ');
    end;

  end;


procedure displaynetbonusitem1(int ofs);
begin
  char       *type, *name;
  char       str1[40];
  i, j, count, top, bottom, x, y, lump, score: integer;
  scalepic_t *pic;
  pic_t      *p;
  byte       *collumn, *b;
  time: integer;

  font := font2;
  fontbasecolor := 0;
  if goalitem = -1 then
  begin
   if (BonusItem.score) togglegoalitem := true;
   exit;
    end;
  if goalitem = 0 then
  begin
   if (BonusItem.score = 0) // bonus item go bye-bye
   begin
     togglegoalitem := true;
     exit;
      end;
   lump := BonusItem.sprite.basepic;
   score := BonusItem.score;
   type := 'Bonus  ';
   time := (BonusItem.time-timecount)/70;
   if (time>10000) time := 0;
   sprintf(str1,'%3i s ',time);
   name := BonusItem.name;
   pic := lumpmain[lump];
   x := 34-(pic.width shr 1);
   for (i := 0;i<pic.width;i++,x++)
    if pic.collumnofs[i] then
    begin
      collumn := (byte *)pic+pic.collumnofs[i];
      top := *(collumn+1);
      bottom := *(collumn);
      count := bottom-top+1;
      collumn := collumn + 2;
      y := (188+ofs)-top-count;
       for (j := 0;j<count;j++,collumn++,y++)
  if *collumn then
   *(viewylookup[y]+x) := *collumn;
       end;
    end;
  else
  begin
   lump := fraglump + playerdata[goalitem-1].chartype;
   p := (pic_t *)lumpmain[lump];
   type := 'Player ';
   name := netnames[goalitem-1];
   sprintf(str1,'%-5i',fragcount[goalitem-1]);
   b := @(p.data);
   for (y := 0;y<30;y++)
    for (x := 0;x<30;x++,b++)
     *(viewylookup[y+158+ofs]+19+x) := *b;
    end;
  printx := 53;
  printy := 172+ofs;
  FN_RawPrint2(str1);
  printx := 53;
  printy := 182+ofs;
  FN_RawPrint2(type);
  printx := 22;
  printy := 192+ofs;
  sprintf(str1,'%-32s',name);
  FN_RawPrint2(str1);
  end;


procedure displaybonusitem1(int ofs);
begin
  char       *type, *name;
  char       str1[40];
  i, j, count, top, bottom, x, y, lump, score, found, total: integer;
  scalepic_t *pic;
  byte       *collumn;
  time: integer;

  font := font2;
  fontbasecolor := 0;
  if goalitem = -1 then
  begin
   if (BonusItem.score) togglegoalitem := true;
   exit;
    end;
  if goalitem = 0 then
  begin
   if (BonusItem.score = 0) // bonus item go bye-bye
   begin
     togglegoalitem := true;
     exit;
      end;
   lump := BonusItem.sprite.basepic;
   score := BonusItem.score;
   type := 'Bonus  ';
   time := (BonusItem.time-timecount)/70;
   if (time>10000) time := 0;
   sprintf(str1,'%3i s',time);
   name := BonusItem.name;
  end
  else if (goalitem >= 1) and (goalitem <= 2) then
  begin
   lump := primarylump + primaries[(goalitem-1)*2];
   score := primaries[(goalitem-1)*2+1];
   type := 'Primary';
   found := player.primaries[goalitem-1];
   total := pcount[goalitem-1];
   sprintf(str1,'%2i/%2i',found,total);
   name := primnames[primaries[(goalitem-1)*2]];
  end
  else if goalitem >= 3 then
  begin
   lump := secondarylump + secondaries[(goalitem-3)*2];
   score := secondaries[(goalitem-3)*2+1];
   type := 'Second ';
   found := player.secondaries[goalitem-3];
   total := scount[goalitem-3];
   sprintf(str1,'%2i/%2i',found,total);
   name := secnames[secondaries[(goalitem-3)*2]];
    end;

  pic := lumpmain[lump];
  x := 34-(pic.width shr 1);
  for (i := 0;i<pic.width;i++,x++)
  if pic.collumnofs[i] then
  begin
    collumn := (byte *)pic+pic.collumnofs[i];
    top := *(collumn+1);
    bottom := *(collumn);
    count := bottom-top+1;
    collumn := collumn + 2;
    y := (188+ofs)-top-count;
    for (j := 0;j<count;j++,collumn++,y++)
     if *collumn then
      *(viewylookup[y]+x) := *collumn;
     end;

  printx := 53;
  printy := 162+ofs;
  FN_RawPrint2(str1);
  sprintf(str1,'%5i',score);
  printx := 53;
  printy := 172+ofs;
  FN_RawPrint2(str1);
  printx := 53;
  printy := 182+ofs;
  FN_RawPrint2(type);
  printx := 22;
  printy := 192+ofs;
  sprintf(str1,'%-32s',name);
  FN_RawPrint2(str1);
  end;


procedure displayrightstats1(int ofs);
begin
  n, shots: integer;
  char str1[10];

  n := player.weapons[player.currentweapon];
  if weapons[n].ammorate>0 then
  shots := player.ammo[weapons[n].ammotype]/weapons[n].ammorate;
  else shots := 999;
  font := font3;
  printx := 225;
  printy := 178+ofs;
  fontbasecolor := 0;
  sprintf(str1,'%3i',shots);
  FN_RawPrint2(str1);
  displaycompass1(ofs);
  displaysettings1(ofs);
  displaystats1(ofs);
  end;

(* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = *)

procedure displaystats2;
begin
  d, i, j, c, p: integer;
  char str1[20];

  if player.shield <> oldshield then
  begin
   oldshield := player.shield;
   d := (player.shield*28)/player.maxshield;
   for(i := 152;i <= 159;i++)
   begin
     c := (d*(i-(152)))/8 + 140;
     for(j := 272;j <= 300;j++)
     begin
       p := *(ylookup[i]+j);
       if (p = 254) or ((p >= 140) and (p <= 168)) *(ylookup[i]+j) := c;
        end;
      end;
   for(i := 193;i <= 199;i++)
   begin
     c := (d*((199)-i))/7 + 140;
     for(j := 272;j <= 300;j++)
     begin
       p := *(ylookup[i]+j);
       if (p = 254) or ((p >= 140) and (p <= 168)) *(ylookup[i]+j) := c;
        end;
      end;
   for(j := 307;j <= 315;j++)
   begin
     c := (d*(315-j))/9 + 140;
     for(i := 165;i <= 187;i++)
     begin
       p := *(ylookup[i]+j);
       if (p = 254) or ((p >= 140) and (p <= 168)) *(ylookup[i]+j) := c;
        end;
      end;
   for(j := 257;j <= 265;j++)
   begin
     c := (d*(j-257))/9 + 140;
     for(i := 165;i <= 187;i++)
     begin
       p := *(ylookup[i]+j);
       if (p = 254) or ((p >= 140) and (p <= 168)) *(ylookup[i]+j) := c;
        end;
      end;
    end;
  if player.angst <> oldangst then
  begin
   d := (player.angst*10)/player.maxangst;
   if (d >= 10) d := 9;
   if oldangstpic <> d then
   begin
     VI_DrawPic(269,161,heart[d]);
     oldangstpic := d;
      end;
   oldangst := player.angst;
   font := font2;
   fontbasecolor := 0;
   sprintf(str1,'%3i',player.angst);
   printx := 280;
   printy := 188;
   FN_RawPrint(str1);
    end;
  statcursor := statcursor + 2;
  if (statcursor >= 323) statcursor := 269;
  for(j := 269;j <= 305;j++)
  begin
   if (j>statcursor) c := 113;
   else
   begin
     c := 139 - (statcursor-j);
     if (c<120) c := 113;
      end;
   for(i := 161;i <= 185;i++)
   begin
     p := *(ylookup[i]+j);
     if (p = 254) or ((p >= 113) and (p <= 139)) *(ylookup[i]+j) := c;
      end;
    end;
  end;


procedure displaycompass2;
begin
  c, x, y, i: integer;
  x1, y1: fixed_t;

  if (player.angle = oldangle) exit;
  if oldangle <> -1 then
  begin
   x := 237;
   x1 := x shl FRACBITS;
   y := 161;
   y1 := y shl FRACBITS;
   for(i := 0;i<10;i++)
   begin
     *(ylookup[y]+x) := 0;
     x1 := x1 + costable[oldangle];
     y1-:= FIXEDMUL(sintable[oldangle],54394);
     x := x1 shr FRACBITS;
     y := y1 shr FRACBITS;
      end;
    end;
  oldangle := player.angle;
  x := 237;
  x1 := x shl FRACBITS;
  y := 161;
  y1 := y shl FRACBITS;
  c := 139;
  for(i := 0;i<10;i++,c--)
  begin
   *(ylookup[y]+x) := c;
   x1 := x1 + costable[oldangle];
   y1-:= FIXEDMUL(sintable[oldangle],54394);
   x := x1 shr FRACBITS;
   y := y1 shr FRACBITS;
    end;
  end;


procedure displaysettings2;
begin
  if (heatmode) memset(ylookup[199]+236,102,6);
  else memset(ylookup[199]+236,0,6);
  if (motionmode) memset(ylookup[199]+246,156,6);
  else memset(ylookup[199]+246,0,6);
  if (mapmode) memset(ylookup[199]+226,133,6);
  else memset(ylookup[199]+226,0,6);
  end;


procedure displayinventory2;
begin
  n, ammo, lump, i, j, count, top, bottom, x, y, maxshots: integer;
  char       str1[20];
  scalepic_t *pic;
  byte       *collumn;

  font := font2;
  fontbasecolor := 0;
  n := player.weapons[player.currentweapon];
  if weapons[n].ammorate>0 then
  begin
   ammo := player.ammo[weapons[n].ammotype];
   maxshots := weapons[n].ammorate;
    end;
  else
  begin
   maxshots := 999;
   ammo := 999;
    end;
  printx := 186;
  printy := 183;
  FN_Printf('%3i',ammo);
  printx := 203;
  printy := 183;
  FN_Printf('%3i',maxshots);
  printx := 187;
  printy := 191;
  FN_RawPrint(ammonames[weapons[n].ammotype]);

  if (inventorycursor = -1) or (player.inventory[inventorycursor] = 0) inventoryright;
  if inventorycursor <> oldinventory then
  begin
   oldinventory := inventorycursor;
   for (i := 162;i <= 184;i++) memset(ylookup[i]+113,0,30);
   if inventorycursor <> -1 then
   begin
     lump := inventorylump + inventorycursor;
     printx := 149;         // name
     printy := 163;
     FN_RawPrint(inventorynames[inventorycursor]);
     pic := lumpmain[lump]; // draw the pic for it
     x := 128-(pic.width shr 1);
     for (i := 0;i<pic.width;i++,x++)
      if pic.collumnofs[i] then
      begin
  collumn := (byte *)pic+pic.collumnofs[i];
  top := *(collumn+1);
  bottom := *(collumn);
  count := bottom-top+1;
  collumn := collumn + 2;
  y := 188-top-count;
  for (j := 0;j<count;j++,collumn++,y++)
   if *collumn then
          *(ylookup[y]+x) := *collumn;
   end;
     font := font3;         // number of items
     printx := 150;
     printy := 172;
     sprintf(str1,'%2i',player.inventory[inventorycursor]);
     FN_RawPrint(str1);
      end;
   else
   begin
     printx := 149;   // name
     printy := 163;
     sprintf(str1,'%14s',' ');
     FN_RawPrint(str1);
     font := font3;   // number of items
     printx := 150;
     printy := 172;
     FN_RawPrint('  ');
      end;
    end;
  end;


procedure displaynetbonusitem2;
begin
  char       *type, *name;
  char       str1[40];
  i, j, count, top, bottom, x, y, lump, score: integer;
  scalepic_t *pic;
  pic_t      *p;
  byte       *collumn, *b;
  time: integer;

  if goalitem = -1 then
  begin
   if (BonusItem.score) togglegoalitem := true;
   for(i := 158;i<188;i++)
    memset(ylookup[i]+19,0,30);
   font := font2;
   fontbasecolor := 0;
   printx := 53;
   printy := 162;
   FN_RawPrint('     ');
   printx := 53;
   printy := 172;
   FN_RawPrint('     ');
   printx := 53;
   printy := 182;
   FN_RawPrint('       ');
   printx := 22;
   printy := 192;
   sprintf(str1,'%-32s',' ');
   FN_RawPrint(str1);
   exit;
    end;
  if (goalitem = 0) and (BonusItem.score = 0) then
  begin
   togglegoalitem := true;
   exit;
    end;
  if (oldgoalitem = goalitem) exit;
  font := font2;
  fontbasecolor := 0;
  if goalitem = 0 then
  begin
   lump := BonusItem.sprite.basepic;
   score := BonusItem.score;
   type := 'Bonus  ';
   time := (BonusItem.time-timecount)/70;
   if (time>10000) time := 0;
   sprintf(str1,'%3i s',time);
   name := BonusItem.name;
   pic := lumpmain[lump];
   x := 34-(pic.width shr 1);
   for(i := 158;i<188;i++)
    memset(ylookup[i]+19,0,30);
   for (i := 0;i<pic.width;i++,x++)
    if pic.collumnofs[i] then
    begin
      collumn := (byte *)pic+pic.collumnofs[i];
      top := *(collumn+1);
      bottom := *(collumn);
      count := bottom-top+1;
      collumn := collumn + 2;
      y := 188-top-count;
      for (j := 0;j<count;j++,collumn++,y++)
       if *collumn then
  *(ylookup[y]+x) := *collumn;
       end;
    end;
  else
  begin
   lump := fraglump + playerdata[goalitem-1].chartype;
   p := (pic_t *)lumpmain[lump];
   type := 'Player';
   name := netnames[goalitem-1];
   sprintf(str1,'%-5i',fragcount[goalitem-1]);

   b := @(p.data);
   for (y := 0;y<30;y++)
    for (x := 0;x<30;x++,b++)
     *(ylookup[y+158]+19+x) := *b;
    end;
  oldgoalitem := goalitem;
  for(i := 162;i<168;i++)
  memset(ylookup[i]+53,0,23);
  for(i := 172;i<178;i++)
  memset(ylookup[i]+53,0,30);
  for(i := 182;i<188;i++)
  memset(ylookup[i]+53,0,39);
  for(i := 192;i<198;i++)
  memset(ylookup[i]+22,0,159);
  printx := 53;
  printy := 162;
  FN_RawPrint('     ');
  printx := 53;
  printy := 172;
  FN_RawPrint(str1);
  printx := 53;
  printy := 182;
  FN_RawPrint(type);
  printx := 22;
  printy := 192;
  sprintf(str1,'%-32s',name);
  FN_RawPrint(str1);
  end;


procedure displaybonusitem2;
begin
  char       *type, *name;
  char       str1[40];
  i, j, count, top, bottom, x, y, lump, score, found, total: integer;
  scalepic_t *pic;
  byte       *collumn;
  time: integer;

  if goalitem = -1 then
  begin
   if (BonusItem.score) togglegoalitem := true;
   for(i := 158;i<188;i++)
    memset(ylookup[i]+19,0,30);
   font := font2;
   fontbasecolor := 0;
   printx := 53;
   printy := 162;
   FN_RawPrint('     ');
   printx := 53;
   printy := 172;
   FN_RawPrint('     ');
   printx := 53;
   printy := 182;
   FN_RawPrint('       ');
   printx := 22;
   printy := 192;
   sprintf(str1,'%-32s',' ');
   FN_RawPrint(str1);
   exit;
    end;
  if (goalitem = 0) and (BonusItem.score = 0) then
  begin
   togglegoalitem := true;
   exit;
    end;
  if (oldgoalitem = goalitem) and (goalitem <> 0) exit;
  font := font2;
  fontbasecolor := 0;
  if goalitem = 0 then
  begin
   lump := BonusItem.sprite.basepic;
   score := BonusItem.score;
   type := 'Bonus  ';
   time := (BonusItem.time-timecount)/70;
   if (time>10000) time := 0;
   sprintf(str1,'%3i s',time);
   name := BonusItem.name;
   if oldgoalitem = goalitem then
   begin
     printx := 53;
     printy := 162;
     FN_RawPrint(str1);
     exit;
      end;
  end
  else if (goalitem >= 1) and (goalitem <= 2) then
  begin
   lump := primarylump + primaries[(goalitem-1)*2];
   score := primaries[(goalitem-1)*2+1];
   type := 'Primary';
   found := player.primaries[goalitem-1];
   total := pcount[goalitem-1];
   sprintf(str1,'%2i/%2i',found,total);
   name := primnames[primaries[(goalitem-1)*2]];
  end
  else if goalitem >= 3 then
  begin
   lump := secondarylump + secondaries[(goalitem-3)*2];
   score := secondaries[(goalitem-3)*2+1];
   type := 'Second ';
   found := player.secondaries[goalitem-3];
   total := scount[goalitem-3];
   sprintf(str1,'%2i/%2i',found,total);
   name := secnames[secondaries[(goalitem-3)*2]];
    end;

  oldgoalitem := goalitem;

  for(i := 158;i<188;i++)
  memset(ylookup[i]+19,0,30);
  pic := lumpmain[lump];
  x := 34-(pic.width shr 1);
  for (i := 0;i<pic.width;i++,x++)
  if pic.collumnofs[i] then
  begin
    collumn := (byte *)pic+pic.collumnofs[i];
    top := *(collumn+1);
    bottom := *(collumn);
    count := bottom-top+1;
    collumn := collumn + 2;
    y := 188-top-count;
    for (j := 0;j<count;j++,collumn++,y++)
     if *collumn then
      *(ylookup[y]+x) := *collumn;
     end;

  for(i := 162;i<168;i++)
  memset(ylookup[i]+53,0,23);
  for(i := 172;i<178;i++)
  memset(ylookup[i]+53,0,30);
  for(i := 182;i<188;i++)
  memset(ylookup[i]+53,0,39);
  for(i := 192;i<198;i++)
  memset(ylookup[i]+22,0,159);

  printx := 53;
  printy := 162;
  FN_RawPrint(str1);
  printx := 53;
  printy := 172;
  FN_Printf('%5i',score);
  printx := 53;
  printy := 182;
  FN_RawPrint(type);
  printx := 22;
  printy := 192;
  sprintf(str1,'%-32s',name);
  FN_RawPrint(str1);
  end;


procedure displayrightstats2;
begin
  n, shots: integer;

  n := player.weapons[player.currentweapon];
  if weapons[n].ammorate>0 then
  shots := player.ammo[weapons[n].ammotype]/weapons[n].ammorate;
  else shots := 999;
  if shots <> oldshots then
  begin
   font := font3;
   printx := 225;
   printy := 178;
   fontbasecolor := 0;
   FN_Printf('%3i',shots);
   oldshots := shots;
    end;
  displaycompass2;
  displaysettings2;
  displaystats2;
  end;


procedure displaybodycount2;
begin
  char str1[20];
  i, j, d, d1, c: integer;

  if player.bodycount <> oldbodycount then
  begin
   font := font2;
   printx := 178;
   printy := 3;
   fontbasecolor := 0;
   sprintf(str1,'%8lu',player.bodycount);
   FN_RawPrint(str1);
   oldbodycount := player.bodycount;
    end;
  if player.score <> oldscore then
  begin
   font := font2;
   printx := 28;
   printy := 3;
   fontbasecolor := 0;
   sprintf(str1,'%9lu',player.score);
   FN_RawPrint(str1);
   oldscore := player.score;
    end;
  if (player.levelscore <> (int)oldlevelscore) then
  begin
   font := font2;
   printx := 104;
   printy := 3;
   fontbasecolor := 0;
   sprintf(str1,'%9lu',player.levelscore);
   FN_RawPrint(str1);
   oldlevelscore := player.levelscore;
    end;
  if specialeffecttime <> $7FFFFFFF then
  begin
   d1 := (specialeffecttime-timecount) shr 2;
   if (d1>97) d := 97;
    else if (d1<0) d := 0;
    else d := d1;

   for(j := 0;j<d;j++)
   begin
     c := (j*26)/d1;
     for(i := 2;i <= 8;i++)
      *(ylookup[i]+j+221) := c+140;
      end;
   if d<97 then
    for(j := d;j <= 97;j++)
     for(i := 2;i <= 8;i++)
      *(ylookup[i]+j+221) := 0;
    end;
  end;

(* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = := *)

procedure displayinventoryitem;
begin
  lump, i, j, count, top, bottom, x, y: integer;
  char       str1[20];
  scalepic_t *pic;
  byte       *collumn;

  if (inventorycursor<0) exit;
  for(i := 0;i<27;i++)
  begin
   memset(viewylookup[i]+windowWidth-54,0,54);
   *(viewylookup[i]+windowWidth-55) := 30;
    end;
  memset(viewylookup[i]+windowWidth-55,30,55);
  lump := inventorylump + inventorycursor;
  pic := lumpmain[lump]; // draw the pic for it
  x := windowWidth-31;
  for (i := 0;i<pic.width;i++,x++)
  if pic.collumnofs[i] then
  begin
    collumn := (byte *)pic+pic.collumnofs[i];
    top := *(collumn+1);
    bottom := *(collumn);
    count := bottom-top+1;
    collumn := collumn + 2;
    y := 28-top-count;
    for (j := 0;j<count;j++,collumn++,y++)
     if *collumn then
      *(viewylookup[y]+x) := *collumn;
     end;
  fontbasecolor := 0;
  font := font3;         // number of items
  printx := windowWidth-53;
  printy := 6;
  sprintf(str1,'%2i',player.inventory[inventorycursor]);
  FN_RawPrint4(str1);
  end;

(* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = := *)

procedure updatedisplay;
begin
  case currentViewSize  of
  begin
   0:
    if (timecount<inventorytime) displayinventoryitem;
    break;
   3:
    displayinventory1(0);   // level 3 to view
   2:  // no break not 
    if not netmode then
     displaybonusitem1(0);   // level 2 to view
    else
     displaynetbonusitem1(0);
   1:  // no break not 
    displayrightstats1(0);  // level 1 to view
    if (currentViewSize<3) and (timecount<inventorytime) displayinventoryitem;
    break;
   4:                 // level 4 to view + top to screen
    displayinventory1(-11);
    if not netmode then
     displaybonusitem1(-11);
    else
     displaynetbonusitem1(-11);
    displayrightstats1(-11);
    displaybodycount2;
    break;
   5:                 // smaller screen sizes
   6:
   7:
   8:
   9:
    displayinventory2;
    if not netmode then
     displaybonusitem2;
    else
     displaynetbonusitem2;
    displayrightstats2;
    displaybodycount2;
    break;
    end;
  end;


(* = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = := *)

procedure displayarrow(int x,int y);
begin
  angle: integer;

  *(viewylookup[y]+x) := 26;
  angle := (((player.angle+DEGREE45_2)) and (ANGLES)*8)/ANGLES;
  case angle  of
  begin
   0:
    *(viewylookup[y]+x+1) := 40;
    *(viewylookup[y]+x-1) := 20;
    break;
   1:
    *(viewylookup[y-1]+x+1) := 40;
    *(viewylookup[y+1]+x-1) := 20;
    break;
   2:
    *(viewylookup[y-1]+x) := 40;
    *(viewylookup[y+1]+x) := 20;
    break;
   3:
    *(viewylookup[y-1]+x-1) := 40;
    *(viewylookup[y+1]+x+1) := 20;
    break;
   4:
    *(viewylookup[y]+x-1) := 40;
    *(viewylookup[y]+x+1) := 20;
    break;
   5:
    *(viewylookup[y+1]+x-1) := 40;
    *(viewylookup[y-1]+x+1) := 20;
    break;
   6:
    *(viewylookup[y+1]+x) := 40;
    *(viewylookup[y-1]+x) := 20;
    break;
   7:
    *(viewylookup[y+1]+x+1) := 40;
    *(viewylookup[y-1]+x-1) := 20;
    break;
    end;
  end;


procedure displaymapmode;
(* head up display map *)
begin
  i, j, ofsx, ofsy, x, y, px, py, mapy, mapx, c, a, miny, maxy, minx, maxx: integer;
  mapspot: integer;
  b: integer;

  y := windowHeight/4;
  miny := -(y/2);
  maxy := y/2;
  x := windowWidth/4;
  minx := -(x/2);
  maxx := x/2;
  ofsx := 1-((player.x shr (FRACBITS+4))) and (3);
  ofsy := 1-((player.y shr (FRACBITS+4))) and (3);
  px := player.x shr FRACTILESHIFT;
  py := player.y shr FRACTILESHIFT;
  y := ofsy;
  for(i := miny;i <= maxy;i++,y+:= 4)  // display north maps
  begin
   mapy := py+i;
   if (mapy<0) or (mapy >= MAPROWS) continue;
   mapx := px+minx;
   mapspot := mapy*MAPCOLS+mapx;
   x := ofsx;
   for(j := minx;j <= maxx;j++,mapspot++,mapx++)
    if (mapx >= 0) and (mapx<MAPCOLS) and (player.northmap[mapspot]) then
    begin
      c := player.northmap[mapspot];
      if c = DOOR_COLOR then
      begin
  for(a := 0;a<5;a++,x++)
   if (x >= 0) and (x<windowWidth) and (y+2<windowHeight) and (y+2 >= 0) *(viewylookup[y+2]+x) := c;
   end;
      else
      begin
  for(a := 0;a<5;a++,x++)
   if (x >= 0) and (x<windowWidth) and (y<windowHeight) and (y >= 0) *(viewylookup[y]+x) := c;
   end;
      x--;
       end;
    else x := x + 4;
    end;
  x := ofsx;
  for(j := minx;j <= maxx;j++,x+:= 4) // display west maps
  begin
   mapx := px+j;
   if (mapx<0) or (mapx >= MAPCOLS) continue;
   mapy := py+miny;
   mapspot := mapy*MAPCOLS+mapx;
   y := ofsy;
   for(i := miny;i <= maxy;i++,mapspot+:= MAPCOLS,mapy++)
    if (mapy >= 0) and (mapy<MAPROWS) and (player.westmap[mapspot]) then
    begin
      c := player.westmap[mapspot];
      if c = DOOR_COLOR then
      begin
  for(a := 0;a<5;a++,y++)
   if (y >= 0) and (y<windowHeight) and (x+2<windowWidth) and (x+2 >= 0) *(viewylookup[y]+x+2) := c;
   end;
      else
      begin
  for(a := 0;a<5;a++,y++)
   if (y >= 0) and (y<windowHeight) and (x<windowWidth) and (x >= 0) *(viewylookup[y]+x) := c;
   end;
      y--;
       end;
   else y := y + 4;
    end;
  displayarrow(windowWidth/2+1,windowHeight/2+1);
  if BonusItem.score then
  begin
   y := ofsy + 4*(BonusItem.tiley - py);
   y := y + windowHeight/2;
   x := ofsx + 4*(BonusItem.tilex - px);
   x := x + windowWidth/2;
   c := 44;
   for(a := 0;a<4;a++)
    for(b := 0;b<4;b++)
     if (x+b<windowWidth) and (x+b >= 0) and (y+a<windowHeight) and (y+a >= 0) *(viewylookup[y+a]+b+x) := c;
    end;
  if exitexists then
  begin
   y := ofsy + 4*(exity - py);
   y := y + windowHeight/2;
   x := ofsx + 4*(exitx - px);
   x := x + windowWidth/2;
   for(a := 0;a<4;a++)
    for(b := 0;b<4;b++)
     if (x+b<windowWidth) and (x+b >= 0) and (y+a<windowHeight) and (y+a >= 0) *(viewylookup[y+a]+b+x) := 187;
    end;
  end;


procedure displayswingmapmode;
(* rotating map display *)
begin
  i, j, ofsx, ofsy, x, y, px, py, c, a, x1, y1, y2, x2: integer;
  xfrac, yfrac, xfrac2, yfrac2, xfracstep, yfracstep, xfracstep2, yfracstep2: fixed_t;
  mapspot: integer;

  case MapZoom  of
  begin
   8:
    ofsx := 1-((player.x shr (FRACBITS+3))) and (7); (* compute player tile offset *)
    ofsy := 1-((player.y shr (FRACBITS+3))) and (7);
    break;
   4:
    ofsx := 1-((player.x shr (FRACBITS+4))) and (3); (* compute player tile offset *)
    ofsy := 1-((player.y shr (FRACBITS+4))) and (3);
    break;
   16:
    ofsx := 1-((player.x shr (FRACBITS+2))) and (15); (* compute player tile offset *)
    ofsy := 1-((player.y shr (FRACBITS+2))) and (15);
    break;
    end;

  px := (player.x shr FRACTILESHIFT)*MapZoom-ofsx; (* compute player position *)
  py := (player.y shr FRACTILESHIFT)*MapZoom-ofsy;
  (* compute incremental values for both diagonal axis *)
  xfracstep := cosines[((player.angle+SOUTH)) and (ANGLES) shl FINESHIFT];
  yfracstep := sines[((player.angle+SOUTH)) and (ANGLES) shl FINESHIFT];
  xfracstep2 := cosines[player.angle shl FINESHIFT];
  yfracstep2 := sines[player.angle shl FINESHIFT];
  xfrac2 := ((windowWidth/2) shl FRACBITS) - (py*xfracstep2 + px*xfracstep);
  yfrac2 := ((windowHeight/2) shl FRACBITS) - (py*yfracstep2 + px*yfracstep);
  y := yfrac2 shr FRACBITS;
  x := xfrac2 shr FRACBITS;
  mapspot := 0;
  (* don't ask me to explain this not  not  not
     basically you start at upper left corner, adding one axis increment
      on the y axis and then updating the one for the x axis as it draws *)
  if BonusItem.score then
  begin
   yfrac2+:= yfracstep2*MapZoom*BonusItem.tiley + (yfracstep2*MapZoom/2); //+ ((MapZoom shr 1)*yfracstep2);
   xfrac2+:= xfracstep2*MapZoom*BonusItem.tiley + (xfracstep2*MapZoom/2); //+ ((MapZoom shr 1)*yfracstep2);

   xfrac := xfrac2 + xfracstep*MapZoom*BonusItem.tilex + (xfracstep*MapZoom/2); //+ ((MapZoom shr 1)*yfracstep);
   yfrac := yfrac2 + yfracstep*MapZoom*BonusItem.tilex + (yfracstep*MapZoom/2); //+ ((MapZoom shr 1)*yfracstep);

   x1 := (xfrac shr FRACBITS);
   y1 := (yfrac shr FRACBITS);

   if (y1 >= 0) and (x1 >= 0) and (x1<windowWidth) and (y1<windowHeight) *(viewylookup[y1]+x1) := 44;
   if (y1+1 >= 0) and (x1 >= 0) and (x1<windowWidth) and (y1+1<windowHeight) *(viewylookup[y1+1]+x1) := 44;
   x1++;
   if (y1 >= 0) and (x1 >= 0) and (x1<windowWidth) and (y1<windowHeight) *(viewylookup[y1]+x1) := 44;
   y1++;
   if (y1 >= 0) and (x1 >= 0) and (x1<windowWidth) and (y1<windowHeight) *(viewylookup[y1]+x1) := 44;

   xfrac2 := ((windowWidth/2) shl FRACBITS) - (py*xfracstep2 + px*xfracstep);
   yfrac2 := ((windowHeight/2) shl FRACBITS) - (py*yfracstep2 + px*yfracstep);
   y := yfrac2 shr FRACBITS;
   x := xfrac2 shr FRACBITS;
    end;
  if exitexists then
  begin
   yfrac2+:= yfracstep2*MapZoom*exity + (yfracstep2*MapZoom/2); //+ ((MapZoom shr 1)*yfracstep2);
   xfrac2+:= xfracstep2*MapZoom*exity + (xfracstep2*MapZoom/2); //+ ((MapZoom shr 1)*yfracstep2);

   xfrac := xfrac2 + xfracstep*MapZoom*exitx + (xfracstep*MapZoom/2); //+ ((MapZoom shr 1)*yfracstep);
   yfrac := yfrac2 + yfracstep*MapZoom*exitx + (yfracstep*MapZoom/2); //+ ((MapZoom shr 1)*yfracstep);

   x1 := (xfrac shr FRACBITS);
   y1 := (yfrac shr FRACBITS);

   if (y1 >= 0) and (x1 >= 0) and (x1<windowWidth) and (y1<windowHeight) *(viewylookup[y1]+x1) := 187;
   if (y1+1 >= 0) and (x1 >= 0) and (x1<windowWidth) and (y1+1<windowHeight) *(viewylookup[y1+1]+x1) := 187;
   x1++;
   if (y1 >= 0) and (x1 >= 0) and (x1<windowWidth) and (y1<windowHeight) *(viewylookup[y1]+x1) := 187;
   y1++;
   if (y1 >= 0) and (x1 >= 0) and (x1<windowWidth) and (y1<windowHeight) *(viewylookup[y1]+x1) := 187;

   xfrac2 := ((windowWidth/2) shl FRACBITS) - (py*xfracstep2 + px*xfracstep);
   yfrac2 := ((windowHeight/2) shl FRACBITS) - (py*yfracstep2 + px*yfracstep);
   y := yfrac2 shr FRACBITS;
   x := xfrac2 shr FRACBITS;
    end;

  for(i := 0;i<MAPCOLS;i++)
  begin
   xfrac := xfrac2;
   yfrac := yfrac2;
   x1 := x;
   y1 := y;
   for(j := 0;j<MAPROWS;j++,mapspot++)
    if player.northmap[mapspot] then
    begin
      c := player.northmap[mapspot];
      if c = DOOR_COLOR then
      begin
  for(a := 0;a <= MapZoom;a++)
  begin
    y2 := y1+(((MapZoom shr 1)*yfracstep2) shr FRACBITS);
    x2 := x1+(((MapZoom shr 1)*xfracstep2) shr FRACBITS);
    if (y2 >= 0) and (x2 >= 0) and (x2<windowWidth) and (y2<windowHeight) *(viewylookup[y2]+x2) := c;
    xfrac := xfrac + xfracstep;
    x1 := xfrac shr FRACBITS;
    yfrac := yfrac + yfracstep;
    y1 := yfrac shr FRACBITS;
     end;
   end;
      else
      begin
  for(a := 0;a <= MapZoom;a++)
  begin
    if (y1 >= 0) and (x1 >= 0) and (x1<windowWidth) and (y1<windowHeight) *(viewylookup[y1]+x1) := c;
    xfrac := xfrac + xfracstep;
    x1 := xfrac shr FRACBITS;
    yfrac := yfrac + yfracstep;
    y1 := yfrac shr FRACBITS;
     end;
   end;
      xfrac := xfrac - xfracstep;
      x1 := xfrac shr FRACBITS;
      yfrac := yfrac - yfracstep;
      y1 := yfrac shr FRACBITS;
       end;
    else
    begin
      xfrac+:= xfracstep*MapZoom;
      x1 := xfrac shr FRACBITS;
      yfrac+:= yfracstep*MapZoom;
      y1 := yfrac shr FRACBITS;
       end;
   yfrac2+:= yfracstep2*MapZoom;
   y := yfrac2 shr FRACBITS;
   xfrac2+:= xfracstep2*MapZoom;
   x := xfrac2 shr FRACBITS;
    end;
  xfrac := ((windowWidth/2) shl FRACBITS) - (py*xfracstep2 + px*xfracstep);
  yfrac := ((windowHeight/2) shl FRACBITS) - (py*yfracstep2 + px*yfracstep);
  y := yfrac shr FRACBITS;
  x := xfrac shr FRACBITS;
  for(i := 0;i<MAPCOLS;i++)
  begin
   xfrac2 := xfrac;
   yfrac2 := yfrac;
   x1 := x;
   y1 := y;
   mapspot := i;
   for(j := 0;j<MAPROWS;j++,mapspot+:= MAPCOLS)
    if player.westmap[mapspot] then
    begin
      c := player.westmap[mapspot];
      if c = DOOR_COLOR then
      begin
  for(a := 0;a <= MapZoom;a++)
  begin
    y2 := y1+(((MapZoom shr 1)*yfracstep) shr FRACBITS);
    x2 := x1+(((MapZoom shr 1)*xfracstep) shr FRACBITS);
    if (y2 >= 0) and (x2 >= 0) and (x2<windowWidth) and (y2<windowHeight) *(viewylookup[y2]+x2) := c;
    xfrac2 := xfrac2 + xfracstep2;
    x1 := xfrac2 shr FRACBITS;
    yfrac2 := yfrac2 + yfracstep2;
    y1 := yfrac2 shr FRACBITS;
     end;
   end;
      else
      begin
  for(a := 0;a <= MapZoom;a++)
  begin
    if (y1 >= 0) and (x1 >= 0) and (x1<windowWidth) and (y1<windowHeight) *(viewylookup[y1]+x1) := c;
    xfrac2 := xfrac2 + xfracstep2;
    x1 := xfrac2 shr FRACBITS;
    yfrac2 := yfrac2 + yfracstep2;
    y1 := yfrac2 shr FRACBITS;
     end;
   end;
      xfrac2 := xfrac2 - xfracstep2;
      x1 := xfrac2 shr FRACBITS;
      yfrac2 := yfrac2 - yfracstep2;
      y1 := yfrac2 shr FRACBITS;
       end;
    else
    begin
      xfrac2+:= xfracstep2*MapZoom;
      x1 := xfrac2 shr FRACBITS;
      yfrac2+:= yfracstep2*MapZoom;
      y1 := yfrac2 shr FRACBITS;
       end;
   yfrac+:= yfracstep*MapZoom;
   y := yfrac shr FRACBITS;
   xfrac+:= xfracstep*MapZoom;
   x := xfrac shr FRACBITS;
    end;
  *(viewylookup[windowHeight/2+1]+windowWidth/2+1) := 40;
  end;


procedure displayheatmode;
(* display overhead heat sensor *)
begin
  i, j, c: integer;

  for(i := 0;i<64;i++)
  for(j := 0;j<64;j++)
   if reallight[i*64+j] then
   begin
     c := -reallight[i*64+j]/48;
     if (c>15) c := 15;
      else if (c<0) c := 0;
     *(viewylookup[i+21]+j+3) := 88-c;
      end;
  memset(viewylookup[20]+2,73,66);
  memset(viewylookup[85]+2,73,66);
  for(i := 21;i<85;i++)
  begin
   *(viewylookup[i]+2) := 73;
   *(viewylookup[i]+67) := 73;
    end;
  *(viewylookup[(player.y shr FRACTILESHIFT)+21]+(player.x shr FRACTILESHIFT)+3) := 40;
  if BonusItem.score then
  *(viewylookup[BonusItem.tiley + 21] + BonusItem.tilex + 3) := 44;
  if exitexists then
  *(viewylookup[exity + 21] + exitx + 3) := 187;
  end;


procedure displayheatmapmode;
(* display heat traces on the overhead map *)
begin
  i, j, ofsx, ofsy, x, y, px, py, mapy, mapx, c, a, miny, maxy, minx, maxx: integer;
  mapspot, b: integer;

  y := windowHeight/4;
  miny := -(y/2);
  maxy := y/2;
  x := windowWidth/4;
  minx := -(x/2);
  maxx := x/2;
  ofsx := 1-((player.x shr (FRACBITS+4))) and (3);
  ofsy := 1-((player.y shr (FRACBITS+4))) and (3);
  px := player.x shr FRACTILESHIFT;
  py := player.y shr FRACTILESHIFT;
  y := ofsy;
  for(i := miny;i <= maxy;i++,y+:= 4)
  begin
   mapy := py+i;
   if (mapy<0) or (mapy >= MAPROWS) continue;
   mapx := px+minx;
   mapspot := mapy*MAPCOLS+mapx;
   x := ofsx;
   for(j := minx;j <= maxx;j++,mapspot++,mapx++,x+:= 4)
    if (mapx >= 0) and (mapx<MAPCOLS) and (reallight[mapspot]) then
    begin
      c := -reallight[mapspot]/48;
      if (c>15) c := 15;
       else if (c<0) c := 0;
      c := 88-c;
      for(a := 0;a<4;a++)
       if (y+a<windowHeight) and (y+a >= 0) then
  for(b := 0;b<4;b++)
   if (x+b<windowWidth) and (x+b >= 0) *(viewylookup[y+a]+b+x) := c;
       end;
     end;
  end;


procedure displaymotionmode;
(* display sensors on overhead display *)
begin
  scaleobj_t *sp;
  sx, sy, i: integer;

  for(sp := firstscaleobj.next;sp <> @lastscaleobj;sp := sp.next)
  if (sp.active) and (sp.hitpoints) then
  begin
    sx := sp.x shr FRACTILESHIFT;
    sy := sp.y shr FRACTILESHIFT;
    *(viewylookup[sy+21]+sx+3) := 152;
     end;
  memset(viewylookup[20]+2,73,66);
  memset(viewylookup[85]+2,73,66);
  for(i := 21;i<85;i++)
  begin
   *(viewylookup[i]+2) := 73;
   *(viewylookup[i]+67) := 73;
    end;
  *(viewylookup[(player.y shr FRACTILESHIFT)+21]+(player.x shr FRACTILESHIFT)+3) := 40;
  if BonusItem.score then
  *(viewylookup[BonusItem.tiley + 21] + BonusItem.tilex + 3) := 44;
  if exitexists then
  *(viewylookup[exity + 21] + exitx + 3) := 187;
  end;


procedure displaymotionmapmode;
(* display sensors on overhead map *)
begin
  ofsx, ofsy, x, y, a, b, px, py: integer;
  scaleobj_t *sp;

  ofsx := 1-((player.x shr (FRACBITS+4))) and (3)+windowWidth/2;
  ofsy := 1-((player.y shr (FRACBITS+4))) and (3)+windowHeight/2;
  px := player.x shr FRACTILESHIFT;
  py := player.y shr FRACTILESHIFT;
  for(sp := firstscaleobj.next;sp <> @lastscaleobj;sp := sp.next)
  if (sp.active) and (sp.hitpoints) then
  begin
    x := ((((sp.x) shr FRACTILESHIFT)-px) shl 2)+ofsx;
    y := ((((sp.y) shr FRACTILESHIFT)-py) shl 2)+ofsy;
    for(a := 0;a<4;a++)
     if (y+a<windowHeight) and (y+a >= 0) then
      for(b := 0;b<4;b++)
       if (x+b<windowWidth) and (x+b >= 0) *(viewylookup[y+a]+b+x) := 152;
     end;
  end;


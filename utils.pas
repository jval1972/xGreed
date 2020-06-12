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
#include <IO.H>
#include <FCNTL.H>
#include <TIME.H>
#include <sys/stat.h>
#include 'd_disk.h'
#include 'd_global.h'
#include 'r_refdef.h'
#include 'd_font.h'
#include 'protos.h'
#include 'd_ints.h'
#include 'd_misc.h'

{$IFDEF GAME1}
  #define SAVENAME 'SAVE1.%i'
#elif defined(GAME2)
  #define SAVENAME 'SAVE2.%i'
#elif defined(GAME3)
  #define SAVENAME 'SAVE3.%i'
{$ELSE}
  #define SAVENAME 'SAVEGAME.%i'
{$ENDIF}


(**** VARIABLES ****)

int primaries[4], secondaries[14], pcount[2], scount[7], bonustime;
extern int cdr_drivenum;

  levelscore: integer;

  gameloading, eventloading: boolean;

int startlocations[MAXSTARTLOCATIONS][2];

extern bool redo;
extern int fxtimecount;
extern SoundCard SC;


(**** FUNCTIONS ****)

procedure KillSprite(scaleobj_t *sp, int weapon);
begin
  scaleobj_t *s;
  i: integer;
  x, y, z: fixed_t;

  if sp.deathevent then
  Event(sp.deathevent,false);
  case sp.type  of
  begin
   S_CLONE:
    if (sp.startpic = CA_GetNamedNum(charnames[0])) then
    begin
      s := SpawnSprite(S_TIMEMINE,sp.x,sp.y,0,0,0,0,false,playernum);
      s.basepic := sp.startpic+40;
      s.scale := 1;
      sp.animation := 0 + (0 shl 1) + (1 shl 5) + (0 shl 9) + ANIM_SELFDEST;
       end;
    else
      sp.animation := 0 + (0 shl 1) + (8 shl 5) + ((4+(MS_RndT) and (3)) shl 9);
    sp.basepic := sp.startpic+40;
    sp.rotate := rt_one;
    sp.heat := 0;
    sp.active := false;
    sp.moveSpeed := 0;
    sp.hitpoints := 0;
    break;
   S_MONSTER1:
   S_MONSTER2:
   S_MONSTER5:
   S_MONSTER7:
   S_MONSTER8:
   S_MONSTER9:
   S_MONSTER10:
   S_MONSTER12:
   S_MONSTER13:
   S_MONSTER14:
   S_MONSTER15:
    sp.basepic := sp.startpic+48;
    sp.animation := 0 + (0 shl 1) + (8 shl 5) + ((2+(MS_RndT) and (3)) shl 9);
    case sp.type  of
    begin
      S_MONSTER1:
       SoundEffect(SN_MON1_DIE,7,sp.x,sp.y);
       break;
      S_MONSTER2:
       SoundEffect(SN_MON2_DIE,7,sp.x,sp.y);
       break;
      S_MONSTER5:
       SoundEffect(SN_MON5_DIE,7,sp.x,sp.y);
       break;
      S_MONSTER7:
       SoundEffect(SN_MON7_DIE,7,sp.x,sp.y);
       break;
      S_MONSTER8:
       SoundEffect(SN_MON8_DIE,7,sp.x,sp.y);
       break;
      S_MONSTER9:
       SoundEffect(SN_MON9_DIE,7,sp.x,sp.y);
       break;
      S_MONSTER10:
       SoundEffect(SN_MON10_DIE,7,sp.x,sp.y);
       break;
      S_MONSTER12:
       SoundEffect(SN_MON12_DIE,7,sp.x,sp.y);
       break;
      S_MONSTER13:
       SoundEffect(SN_MON13_DIE,7,sp.x,sp.y);
       break;
      S_MONSTER14:
       SoundEffect(SN_MON14_DIE,7,sp.x,sp.y);
       break;
      S_MONSTER15:
       SoundEffect(SN_MON15_DIE,7,sp.x,sp.y);
       break;
       end;
    sp.rotate := rt_one;
    sp.heat := 0;
    sp.active := false;
    sp.moveSpeed := 0;
    sp.hitpoints := 0;
    break;
   S_MONSTER3:
    SpawnSprite(S_EXPLODE,sp.x,sp.y,sp.z,0,0,0,false,0);
    SoundEffect(SN_MON3_DIE,7,sp.x,sp.y);
    RF_RemoveSprite(sp);
    break;
   S_MONSTER4:
    SpawnSprite(S_EXPLODE,sp.x,sp.y,sp.z,0,0,0,false,0);
    SoundEffect(SN_MON4_DIE,7,sp.x,sp.y);
    RF_RemoveSprite(sp);
    break;
   S_MONSTER6:
   S_MONSTER11:
    for(i := 0;i<30;i++)
     SpawnSprite(S_METALPARTS,sp.x,sp.y,sp.z+64*FRACUNIT,0,0,0,false,0);
    for(i := 0;i<10;i++)
    begin
      x := sp.x + ((-64+(MS_RndT) and (127)) shl FRACBITS);
      y := sp.y + ((-64+(MS_RndT) and (127)) shl FRACBITS);
      z := sp.z + ((MS_RndT) and (127) shl FRACBITS);
      SpawnSprite(S_EXPLODE+(MS_RndT) and (1),x,y,z,0,0,0,false,0);
       end;
    SoundEffect(SN_EXPLODE1+(clock) and (1),15,x,y);
    SoundEffect(SN_MON11_DIE,7,sp.x,sp.y);
    SoundEffect(SN_MON11_DIE,7,sp.x,sp.y);
    RF_RemoveSprite(sp);
    break;
   default:
    MS_Error('Illegal KillSprite: type %i',sp.type);
    end;
  end;


procedure ActivateSpritesFromMap;
begin
  x, y: integer;

  gameloading := true;
  for(y := 0;y<MAPROWS;y++)
  for(x := 0;x<MAPCOLS;x++)
   if mapsprites[y*MAPCOLS+x] then
    SpawnSprite((int)mapsprites[y*MAPCOLS+x],(fixed_t)(x*MAPSIZE+32) shl FRACBITS,
     (fixed_t)(y*MAPCOLS+32) shl FRACBITS,0,0,0,0,false,0);
  gameloading := false;
  end;


procedure ActivateSlopes;
begin
  i, j, mapspot: integer;

  for(i := 0;i<MAPCOLS;i++)
  for(j := 0;j<MAPROWS;j++)
  begin
    mapspot := i*MAPCOLS+j;
    case mapslopes[mapspot]  of
    begin
      49:
       mapflags[mapspot]) or (:= POLY_SLOPE shl FLS_CEILING;
       break;
      50:
       mapflags[mapspot]) or (:= POLY_URTOLL shl FLS_CEILING;
       break;
      51:
       mapflags[mapspot]) or (:= POLY_ULTOLR shl FLS_CEILING;
       break;

      52:
       mapflags[mapspot]) or (:= POLY_SLOPE;
       break;
      53:
       mapflags[mapspot]) or (:= POLY_SLOPE;
       mapflags[mapspot]) or (:= POLY_URTOLL shl FLS_CEILING;
       break;
      54:
       mapflags[mapspot]) or (:= POLY_SLOPE;
       mapflags[mapspot]) or (:= POLY_ULTOLR shl FLS_CEILING;
       break;

      55:
       mapflags[mapspot]) or (:= POLY_URTOLL;
       mapflags[mapspot]) or (:= POLY_SLOPE shl FLS_CEILING;
       break;
      56:
       mapflags[mapspot]) or (:= POLY_URTOLL;
       break;
      57:
       mapflags[mapspot]) or (:= POLY_URTOLL;
       mapflags[mapspot]) or (:= POLY_ULTOLR shl FLS_CEILING;
       break;

      58:
       mapflags[mapspot]) or (:= POLY_ULTOLR;
       mapflags[mapspot]) or (:= POLY_SLOPE shl FLS_CEILING;
       break;
      59:
       mapflags[mapspot]) or (:= POLY_ULTOLR;
       mapflags[mapspot]) or (:= POLY_URTOLL shl FLS_CEILING;
       break;
      60:
       mapflags[mapspot]) or (:= POLY_ULTOLR;
       break;

      61:
       mapflags[mapspot]) or (:= POLY_SLOPE;
       mapflags[mapspot]) or (:= POLY_SLOPE shl FLS_CEILING;
       break;
      62:
       mapflags[mapspot]) or (:= POLY_URTOLL;
       mapflags[mapspot]) or (:= POLY_URTOLL shl FLS_CEILING;
       break;
      63:
       mapflags[mapspot]) or (:= POLY_ULTOLR;
       mapflags[mapspot]) or (:= POLY_ULTOLR shl FLS_CEILING;
       break;
       end;
     end;
  end;


procedure LoadTextures;
begin
  char textures[256];
  i, x, size, numsprites, startsprites: integer;
  byte *base, *wall;

  startsprites := CA_GetNamedNum('startdemand');
  numsprites := CA_GetNamedNum('enddemand')-startsprites;
  for (i := 1; i<numsprites; i++)
  CA_FreeLump(startsprites+i);
  UpdateWait;
  DemandLoadMonster(CA_GetNamedNum(charnames[player.chartype]),48);
  UpdateWait;
  if debugmode then
  begin
   for (i := 0;i<numwalls-1;i++)
   begin
     wall := lumpmain[walllump+i+1];
     base := wall+65*2;
     size := *wall*4;
     for (x := 0;x<64;x++)
      wallposts[i*64+x] := base+size*x;
      end;
   exit;
    end;
  UpdateWait;
  for(i := 1;i<numwalls-7;i++) CA_FreeLump(walllump+i);
  UpdateWait;
  if wallposts then
  free(wallposts);
  memset(textures,0,sizeof(textures));
  UpdateWait;
  for(i := 0;i<MAPCOLS*MAPROWS;i++)
  begin
   textures[northwall[i]] := 1;
   textures[westwall[i]] := 1;
   textures[floordef[i]] := 1;
   textures[ceilingdef[i]] := 1;
    end;
  UpdateWait;
  textures[3] := 1;    // for sides of doors

  if (textures[228]) or (textures[229]) or (textures[230]) then
  begin
   textures[228] := 1;  // animation textures
   textures[229] := 1;
   textures[230] := 1;
    end;
  if (textures[172]) or (textures[173]) then
  begin
   textures[172] := 1;  // case textures
   textures[173] := 1;
    end;
  if (textures[127]) or (textures[128]) then
  begin
   textures[127] := 1;
   textures[128] := 1;
    end;
  if (textures[75]) or (textures[76]) then
  begin
   textures[75] := 1;
   textures[76] := 1;
    end;
  if (textures[140]) or (textures[141]) then
  begin
   textures[140] := 1;
   textures[141] := 1;
    end;
  if (textures[234]) or (textures[235]) then
  begin
   textures[234] := 1;
   textures[235] := 1;
    end;

  UpdateWait;
  for(i := 1;i<numwalls;i++)
  if textures[i] then
  begin
    CA_CacheLump(walllump+i);
    UpdateWait;
     end;
  wallposts := malloc((size_t)(numwalls+1)*64*4);
  UpdateWait;

  for (i :=  0 ; i < numwalls - 1 ; i++)
  begin
    wall :=  lumpmain[walllump + i + 1];
    if wall then
    begin
      base :=  wall + 65 * 2;
      size :=  *wall * 4;
      for (x :=  0 ; x < 64 ; x++)
        wallposts[i * 64 + x] :=  base + size * x;
     end;
   end;

  UpdateWait;
  for(i := 1;i<numflats;i++) CA_FreeLump(flatlump+i);
  UpdateWait;
  memset(textures,0,sizeof(textures));
  UpdateWait;
  for(i := 0;i<MAPCOLS*MAPROWS;i++)
  begin
   textures[floorpic[i]] := 1;
   textures[ceilingpic[i]] := 1;
    end;
  UpdateWait;
  if (textures[57]) or (textures[58]) or (textures[59]) then
  begin
   textures[57] := 1;  // animation textures
   textures[58] := 1;
   textures[59] := 1;
    end;
  if (textures[217]) or (textures[218]) or (textures[219]) then
  begin
   textures[217] := 1;  // animation textures
   textures[218] := 1;
   textures[219] := 1;
    end;
  textures[133] := 1;
  textures[134] := 1;
  textures[135] := 1;
  for(i := 1;i<numflats;i++)
//  if (textures[i])
begin
    CA_CacheLump(flatlump+i);
    UpdateWait;
     end;
  end;


procedure LoadNewMap(int lump);
begin
  i, j, f: integer;
  char *fname;

  StartWait;
  for(i := 0;i<S_END-S_START+1;i++)
  slumps[i] := CA_GetNamedNum(slumpnames[i]);
  UpdateWait;
  goalitem := -1;
  oldgoalitem := -1;
  togglegoalitem := true;
  RF_ClearWorld;
  UpdateWait;
  if (not MS_CheckParm('file')) then
  begin
   lseek(cachehandle,infotable[lump].filepos,SEEK_SET);
   UpdateWait;
   read(cachehandle,northwall,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,northflags,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,westwall,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,westflags,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,floorpic,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,floorflags,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,ceilingpic,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,ceilingflags,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,floorheight,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,ceilingheight,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,floordef,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,floordefflags,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,ceilingdef,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,ceilingdefflags,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,maplights,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,mapeffects,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,mapsprites,MAPROWS*MAPCOLS);
   UpdateWait;
   read(cachehandle,mapslopes,MAPROWS*MAPCOLS);
   UpdateWait;
    end;
  else
  begin
   fname := infotable[lump].nameofs + (char *)infotable;
   if ((f := fopen(fname,'r')) = -1) MS_Error('LoadNewMap: Can't open %s not ',fname);
   UpdateWait;
   read(f,northwall,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,northflags,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,westwall,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,westflags,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,floorpic,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,floorflags,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,ceilingpic,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,ceilingflags,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,floorheight,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,ceilingheight,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,floordef,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,floordefflags,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,ceilingdef,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,ceilingdefflags,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,maplights,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,mapeffects,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,mapsprites,MAPROWS*MAPCOLS);
   UpdateWait;
   read(f,mapslopes,MAPROWS*MAPCOLS);
   UpdateWait;
   close(f);
    end;
  memset(mapflags,0,sizeof(mapflags));
  UpdateWait;
  for(i := 0;i<MAPCOLS;i++)
  for(j := 0;j<MAPROWS;j++)
  begin
    if (floordef[i*64+j] = 0) floordef[i*64+j] := 56;
    if (ceilingdef[i*64+j] = 0) ceilingdef[i*64+j] := 56;
     end;
  UpdateWait;
  ActivateSlopes;
  UpdateWait;
  LoadTextures;
  end;


procedure loadweapon(int n);
begin
  static weaponlump := 0, numlumps := 0;
  i: integer;

  if weaponlump then
  for (i := 0;i<numlumps;i++)
   CA_FreeLump(weaponlump+i);
  weapons[n].charge := 100;
  weapons[n].chargetime := timecount+weapons[n].chargerate;
  case n  of
  begin
   1:
    i := CA_GetNamedNum('gun2');
    weaponlump := i;
    numlumps := 3;
    if (netmode) NetGetData;
    weaponpic[0] := CA_CacheLump(i);
    if (netmode) NetGetData;
    weaponpic[1] := CA_CacheLump(i+1);
    if (netmode) NetGetData;
    weaponpic[2] := CA_CacheLump(i+2);
    break;
   2:
    i := CA_GetNamedNum('gun3');
    weaponlump := i;
    numlumps := 4;
    weaponpic[0] := CA_CacheLump(i);
    if (netmode) NetGetData;
    weaponpic[1] := CA_CacheLump(i+1);
    if (netmode) NetGetData;
    weaponpic[2] := CA_CacheLump(i+2);
    if (netmode) NetGetData;
    weaponpic[3] := CA_CacheLump(i+3);
    if (netmode) NetGetData;
    break;
   3:
    i := CA_GetNamedNum('gun4');
    weaponlump := i;
    numlumps := 4;
    weaponpic[0] := CA_CacheLump(i);
    if (netmode) NetGetData;
    weaponpic[1] := CA_CacheLump(i+1);
    if (netmode) NetGetData;
    weaponpic[2] := CA_CacheLump(i+2);
    if (netmode) NetGetData;
    weaponpic[3] := CA_CacheLump(i+3);
    if (netmode) NetGetData;
    break;
   4:
    i := CA_GetNamedNum('gun5');
    weaponlump := i;
    numlumps := 4;
    weaponpic[0] := CA_CacheLump(i);
    if (netmode) NetGetData;
    weaponpic[1] := CA_CacheLump(i+1);
    if (netmode) NetGetData;
    weaponpic[2] := CA_CacheLump(i+2);
    if (netmode) NetGetData;
    weaponpic[3] := CA_CacheLump(i+3);
    if (netmode) NetGetData;
    break;
   7:
    i := CA_GetNamedNum('gunsquar');
    weaponlump := i;
    numlumps := 3;
    weaponpic[0] := CA_CacheLump(i);
    if (netmode) NetGetData;
    weaponpic[1] := CA_CacheLump(i+1);
    if (netmode) NetGetData;
    weaponpic[2] := CA_CacheLump(i+2);
    if (netmode) NetGetData;
    break;
   8:
    i := CA_GetNamedNum('gunknife');
    weaponlump := i;
    numlumps := 4;
    weaponpic[0] := CA_CacheLump(i);
    if (netmode) NetGetData;
    weaponpic[1] := CA_CacheLump(i+1);
    if (netmode) NetGetData;
    weaponpic[2] := CA_CacheLump(i+2);
    if (netmode) NetGetData;
    weaponpic[3] := CA_CacheLump(i+3);
    if (netmode) NetGetData;
    break;
   9:
    i := CA_GetNamedNum('guncross');
    weaponlump := i;
    numlumps := 3;
    weaponpic[0] := CA_CacheLump(i);
    if (netmode) NetGetData;
    weaponpic[1] := CA_CacheLump(i+1);
    if (netmode) NetGetData;
    weaponpic[2] := CA_CacheLump(i+2);
    if (netmode) NetGetData;
    break;
   10:
    i := CA_GetNamedNum('gunspec7');
    weaponlump := i;
    numlumps := 4;
    weaponpic[0] := CA_CacheLump(i);
    if (netmode) NetGetData;
    weaponpic[1] := CA_CacheLump(i+1);
    if (netmode) NetGetData;
    weaponpic[2] := CA_CacheLump(i+2);
    if (netmode) NetGetData;
    weaponpic[3] := CA_CacheLump(i+3);
    if (netmode) NetGetData;
    break;
   11:
    i := CA_GetNamedNum('gunmoo');
    weaponlump := i;
    numlumps := 3;
    weaponpic[0] := CA_CacheLump(i);
    if (netmode) NetGetData;
    weaponpic[1] := CA_CacheLump(i+1);
    if (netmode) NetGetData;
    weaponpic[2] := CA_CacheLump(i+2);
    if (netmode) NetGetData;
    break;
   12:
    i := CA_GetNamedNum('gunprong');
    weaponlump := i;
    numlumps := 3;
    weaponpic[0] := CA_CacheLump(i);
    if (netmode) NetGetData;
    weaponpic[1] := CA_CacheLump(i+1);
    if (netmode) NetGetData;
    weaponpic[2] := CA_CacheLump(i+2);
    if (netmode) NetGetData;
    break;
   13:
    i := CA_GetNamedNum('catlprod');
    weaponlump := i;
    numlumps := 3;
    weaponpic[0] := CA_CacheLump(i);
    if (netmode) NetGetData;
    weaponpic[1] := CA_CacheLump(i+1);
    if (netmode) NetGetData;
    weaponpic[2] := CA_CacheLump(i+2);
    if (netmode) NetGetData;
    break;
   14:
    i := CA_GetNamedNum('s7weapon');
    weaponlump := i;
    numlumps := 3;
    weaponpic[0] := CA_CacheLump(i);
    if (netmode) NetGetData;
    weaponpic[1] := CA_CacheLump(i+1);
    if (netmode) NetGetData;
    weaponpic[2] := CA_CacheLump(i+2);
    if (netmode) NetGetData;
    break;
   15:
    i := CA_GetNamedNum('domknife');
    weaponlump := i;
    numlumps := 3;
    weaponpic[0] := CA_CacheLump(i);
    if (netmode) NetGetData;
    weaponpic[1] := CA_CacheLump(i+1);
    if (netmode) NetGetData;
    weaponpic[2] := CA_CacheLump(i+2);
    if (netmode) NetGetData;
    break;
   16:
    i := CA_GetNamedNum('redgun');
    weaponlump := i;
    numlumps := 2;
    weaponpic[0] := CA_CacheLump(i);
    if (netmode) NetGetData;
    weaponpic[1] := CA_CacheLump(i+1);
    if (netmode) NetGetData;
    break;
   17:
    i := CA_GetNamedNum('bluegun');
    weaponlump := i;
    numlumps := 3;
    weaponpic[0] := CA_CacheLump(i);
    if (netmode) NetGetData;
    weaponpic[1] := CA_CacheLump(i+1);
    if (netmode) NetGetData;
    weaponpic[2] := CA_CacheLump(i+2);
    if (netmode) NetGetData;
    break;
   18:
    i := CA_GetNamedNum('greengun');
    weaponlump := i;
    numlumps := 5;
    weaponpic[0] := CA_CacheLump(i);
    if (netmode) NetGetData;
    weaponpic[1] := CA_CacheLump(i+1);
    if (netmode) NetGetData;
    weaponpic[2] := CA_CacheLump(i+2);
    if (netmode) NetGetData;
    weaponpic[3] := CA_CacheLump(i+3);
    if (netmode) NetGetData;
    weaponpic[4] := CA_CacheLump(i+4);
    if (netmode) NetGetData;
    break;
    end;
  end;


procedure ResetScalePostWidth (int NewWindowWidth);
(* this must be updated if the scalepost or scalemaskedpost are changed
   the increment is size of each replicated asm block
   the offset is the location of the line to draw the pixel

   *note: runtime change of code not  not  *)
   begin
  end;


procedure ChangeViewSize(byte MakeLarger);
begin
  lastviewsize: integer;

  if SC.vrhelmet = 1 then
  begin
   if (MakeLarger) and (viewSizes[(currentViewSize+1)*2] <> 320) then
    exit;
   else if (not MakeLarger) and (viewSizes[(currentViewSize-1)*2] <> 320)
    exit;
    end;
  lastviewsize := currentViewSize;
  resizeScreen := 0;
  if MakeLarger then
  begin
   if (currentViewSize<MAXVIEWSIZE-1) currentViewSize++;
    else exit;
    end;
  else
  begin
   if (currentViewSize>0) currentViewSize--;
    else exit;
    end;
  if (viewSizes[currentViewSize*2] <> viewSizes[lastviewsize*2]
  ) or (viewSizes[currentViewSize*2+1] <> viewSizes[lastviewsize*2+1]
  )
  begin
   windowWidth := viewSizes[currentViewSize*2];
   windowHeight := viewSizes[currentViewSize*2+1];
   windowLeft := viewLoc[currentViewSize*2];
   windowTop := viewLoc[currentViewSize*2+1];
   windowSize := windowHeight*windowWidth;
   viewLocation := (int)screen+windowTop*320+windowLeft;
   SetViewSize(windowWidth,windowHeight);
   ResetScalePostWidth(windowWidth);
   InitWalls;
    end;
  resetdisplay;
  if currentViewSize >= 5 then
  begin
   memset(screen,0,64000);
   VI_DrawPic(4,149,statusbar[2]);
    end;
  if (currentViewSize >= 4) VI_DrawMaskedPic(0,0,statusbar[3]);
  player.scrollmin := scrollmin;
  player.scrollmax := scrollmax;
  end;


procedure SaveGame(int n);
begin
  scaleobj_t  *sprite_p;
  FILE        *f;
  char        fname[20];
  doorobj_t   *door_p, *last_p;
  i, mapspot: integer;
  spawnarea_t *sa;
  elevobj_t   *elev_p;

  StartWait;
  memset(player.savesprites,0,sizeof(player.savesprites));
  memcpy(player.westwall,westwall,sizeof(westwall));
  memcpy(player.northwall,northwall,sizeof(northwall));

  UpdateWait;
  (* sprites *)
  for (sprite_p := firstscaleobj.next; sprite_p <> @lastscaleobj;sprite_p := sprite_p.next)
  begin
   mapspot := (sprite_p.y shr FRACTILESHIFT)*MAPCOLS+(sprite_p.x shr FRACTILESHIFT);
   case sprite_p.type  of
   begin
     S_MONSTER1:
      if sprite_p.deathevent then
       break;
      if sprite_p.hitpoints then
      begin
  if (sprite_p.nofalling) player.savesprites[mapspot] := S_MONSTER1_NS;
   else player.savesprites[mapspot] := S_MONSTER1;
   end;
       else player.savesprites[mapspot] := S_DEADMONSTER1;
      break;
     S_MONSTER2:
      if sprite_p.deathevent then
       break;
      if sprite_p.hitpoints then
      begin
  if (sprite_p.nofalling) player.savesprites[mapspot] := S_MONSTER2_NS;
   else player.savesprites[mapspot] := S_MONSTER2;
   end;
      break;
     S_MONSTER3:
      if sprite_p.deathevent then
       break;
      if sprite_p.hitpoints then
      begin
  if (sprite_p.nofalling) player.savesprites[mapspot] := S_MONSTER3_NS;
   else player.savesprites[mapspot] := S_MONSTER3;
   end;
      else player.savesprites[mapspot] := S_DEADMONSTER3;
      break;
     S_MONSTER4:
      if sprite_p.deathevent then
       break;
      if sprite_p.hitpoints then
      begin
  if (sprite_p.nofalling) player.savesprites[mapspot] := S_MONSTER4_NS;
   else player.savesprites[mapspot] := S_MONSTER4;
   end;
      else player.savesprites[mapspot] := S_DEADMONSTER4;
      break;
     S_MONSTER5:
      if sprite_p.deathevent then
       break;
      if (sprite_p.hitpoints) player.savesprites[mapspot] := S_MONSTER5;
       else player.savesprites[mapspot] := S_DEADMONSTER5;
      break;
     S_MONSTER6:
      if sprite_p.deathevent then
       break;
      if sprite_p.hitpoints then
      begin
  if (sprite_p.nofalling) player.savesprites[mapspot] := S_MONSTER6_NS;
   else player.savesprites[mapspot] := S_MONSTER6;
   end;
      else player.savesprites[mapspot] := S_DEADMONSTER6;
      break;
     S_MONSTER7:
      if sprite_p.deathevent then
       break;
      if sprite_p.hitpoints then
      begin
  if (sprite_p.nofalling) player.savesprites[mapspot] := S_MONSTER7_NS;
   else player.savesprites[mapspot] := S_MONSTER7;
   end;
      else player.savesprites[mapspot] := S_DEADMONSTER7;
      break;
     S_MONSTER8:
      if sprite_p.deathevent then
       break;
      if sprite_p.hitpoints then
      begin
  if (sprite_p.nofalling) player.savesprites[mapspot] := S_MONSTER8_NS;
   else player.savesprites[mapspot] := S_MONSTER8;
   end;
      else player.savesprites[mapspot] := S_DEADMONSTER8;
      break;
     S_MONSTER9:
      if sprite_p.deathevent then
       break;
      if sprite_p.hitpoints then
      begin
  if (sprite_p.nofalling) player.savesprites[mapspot] := S_MONSTER9_NS;
   else player.savesprites[mapspot] := S_MONSTER9;
   end;
      else player.savesprites[mapspot] := S_DEADMONSTER9;
      break;
     S_MONSTER10:
      if sprite_p.deathevent then
       break;
      if sprite_p.hitpoints then
      begin
  if (sprite_p.nofalling) player.savesprites[mapspot] := S_MONSTER10_NS;
   else player.savesprites[mapspot] := S_MONSTER10;
   end;
      else player.savesprites[mapspot] := S_DEADMONSTER10;
      break;
     S_MONSTER11:
      if sprite_p.deathevent then
       break;
      if sprite_p.hitpoints then
      begin
  if (sprite_p.nofalling) player.savesprites[mapspot] := S_MONSTER11_NS;
   else player.savesprites[mapspot] := S_MONSTER11;
   end;
      else player.savesprites[mapspot] := S_DEADMONSTER11;
      break;
     S_MONSTER12:
      if sprite_p.deathevent then
       break;
      if sprite_p.hitpoints then
      begin
  if (sprite_p.nofalling) player.savesprites[mapspot] := S_MONSTER12_NS;
   else player.savesprites[mapspot] := S_MONSTER12;
   end;
      else player.savesprites[mapspot] := S_DEADMONSTER12;
      break;
     S_MONSTER13:
      if sprite_p.deathevent then
       break;
      if sprite_p.hitpoints then
      begin
  if (sprite_p.nofalling) player.savesprites[mapspot] := S_MONSTER13_NS;
   else player.savesprites[mapspot] := S_MONSTER13;
   end;
      else player.savesprites[mapspot] := S_DEADMONSTER13;
      break;
     S_MONSTER14:
      if sprite_p.deathevent then
       break;
      if sprite_p.hitpoints then
      begin
  if (sprite_p.nofalling) player.savesprites[mapspot] := S_MONSTER14_NS;
   else player.savesprites[mapspot] := S_MONSTER14;
   end;
      else player.savesprites[mapspot] := S_DEADMONSTER14;
      break;
     S_MONSTER15:
      if sprite_p.deathevent then
       break;
      if sprite_p.hitpoints then
      begin
  if (sprite_p.nofalling) player.savesprites[mapspot] := S_MONSTER15_NS;
   else player.savesprites[mapspot] := S_MONSTER15;
   end;
      else player.savesprites[mapspot] := S_DEADMONSTER15;
      break;
     S_DEADMONSTER1:
     S_DEADMONSTER2:
     S_DEADMONSTER3:
     S_DEADMONSTER4:
     S_DEADMONSTER5:
     S_DEADMONSTER6:
     S_DEADMONSTER7:
     S_DEADMONSTER8:
     S_DEADMONSTER9:
     S_DEADMONSTER10:
     S_DEADMONSTER11:
     S_DEADMONSTER12:
     S_DEADMONSTER13:
     S_DEADMONSTER14:
     S_DEADMONSTER15:
     S_AMMOBOX:
     S_MEDBOX:
     S_GOODIEBOX:
     S_PROXMINE:
     S_TIMEMINE:
     S_PRIMARY1:
     S_PRIMARY2:
     S_SECONDARY1:
     S_SECONDARY2:
     S_SECONDARY3:
     S_SECONDARY4:
     S_SECONDARY5:
     S_SECONDARY6:
     S_SECONDARY7:
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
     S_ITEM1:
     S_ITEM2:
     S_ITEM3:
     S_ITEM4:
     S_ITEM5:
     S_ITEM6:
     S_ITEM7:
     S_ITEM8:
     S_ITEM9:
     S_ITEM10:
     S_ITEM11:
     S_ITEM12:
     S_ITEM13:
     S_ITEM14:
     S_ITEM15:
     S_ITEM16:
     S_ITEM17:
     S_ITEM18:
     S_ITEM19:
     S_ITEM20:
     S_ITEM21:
     S_ITEM22:
     S_ITEM23:
     S_ITEM24:
     S_ITEM25:
      player.savesprites[mapspot] := sprite_p.type;
      break;
      end;
    end;
  UpdateWait;

  (* map triggers *)
  for(i := 0;i<MAPCOLS*MAPROWS;i++)  // remember warps
  case mapsprites[i]  of
  begin
    SM_WARP1:
    SM_WARP2:
    SM_WARP3:
     player.savesprites[i] := mapsprites[i];
     break;
    SM_SWITCHDOWN:
     player.savesprites[i] := S_TRIGGER1;
     break;
    SM_SWITCHDOWN2:
     player.savesprites[i] := S_TRIGGER2;
     break;
    SM_SWAPSWITCH:
     player.savesprites[i] := S_SWAPSWITCH;
     break;
    SM_STRIGGER:
     player.savesprites[i] := S_STRIGGER;
     break;
    SM_EXIT:
     player.savesprites[i] := S_EXIT;
     break;
//    SM_HOLE:
//     player.savesprites[i] := S_HOLE;
//     break;
     end;
  UpdateWait;

  (* doors *)
  last_p := @doorlist[numdoors];
  for (door_p := doorlist;door_p <> last_p;door_p++)
  if (door_p.pic = CA_GetNamedNum('door_1')-walllump) then
  begin
    if (door_p.orientation = dr_vertical) or (door_p.orientation = dr_vertical2) then
     player.savesprites[door_p.tiley*MAPCOLS+door_p.tilex] := S_VDOOR1;
    else player.savesprites[door_p.tiley*MAPCOLS+door_p.tilex] := S_HDOOR1;
  end
  else if (door_p.pic = CA_GetNamedNum('door_2')-walllump) then
  begin
    if (door_p.orientation = dr_vertical) or (door_p.orientation = dr_vertical2) then
     player.savesprites[door_p.tiley*MAPCOLS+door_p.tilex] := S_VDOOR2;
    else player.savesprites[door_p.tiley*MAPCOLS+door_p.tilex] := S_HDOOR2;
  end
  else if (door_p.pic = CA_GetNamedNum('door_3')-walllump) then
  begin
    if (door_p.orientation = dr_vertical) or (door_p.orientation = dr_vertical2) then
     player.savesprites[door_p.tiley*MAPCOLS+door_p.tilex] := S_VDOOR3;
    else player.savesprites[door_p.tiley*MAPCOLS+door_p.tilex] := S_HDOOR3;
  end
  else if (door_p.pic = CA_GetNamedNum('door_4')-walllump) then
  begin
    if (door_p.orientation = dr_vertical) or (door_p.orientation = dr_vertical2) then
     player.savesprites[door_p.tiley*MAPCOLS+door_p.tilex] := S_VDOOR4;
    else player.savesprites[door_p.tiley*MAPCOLS+door_p.tilex] := S_HDOOR4;
  end
  else if (door_p.pic = CA_GetNamedNum('door_5')-walllump) then
  begin
    if (door_p.orientation = dr_vertical) or (door_p.orientation = dr_vertical2) then
     player.savesprites[door_p.tiley*MAPCOLS+door_p.tilex] := S_VDOOR5;
    else player.savesprites[door_p.tiley*MAPCOLS+door_p.tilex] := S_HDOOR5;
  end
  else if (door_p.pic = CA_GetNamedNum('door_6')-walllump) then
  begin
    if (door_p.orientation = dr_vertical) or (door_p.orientation = dr_vertical2) then
     player.savesprites[door_p.tiley*MAPCOLS+door_p.tilex] := S_VDOOR6;
    else player.savesprites[door_p.tiley*MAPCOLS+door_p.tilex] := S_HDOOR6;
  end
  else if (door_p.pic = CA_GetNamedNum('door_7')-walllump) then
  begin
    if (door_p.orientation = dr_vertical) or (door_p.orientation = dr_vertical2) then
     player.savesprites[door_p.tiley*MAPCOLS+door_p.tilex] := S_VDOOR7;
    else player.savesprites[door_p.tiley*MAPCOLS+door_p.tilex] := S_HDOOR7;
     end;
  UpdateWait;

  (* spawning areas / generators *)
  sa := spawnareas;
  for(i := 0;i<numspawnareas;i++,sa++)
  case sa.type  of
  begin
    0:
     player.savesprites[sa.mapspot] := S_GENERATOR1;
     break;
    1:
     player.savesprites[sa.mapspot] := S_GENERATOR2;
     break;
    10:
     player.savesprites[sa.mapspot] := S_SPAWN1;
     break;
    11:
     player.savesprites[sa.mapspot] := S_SPAWN2;
     break;
    12:
     player.savesprites[sa.mapspot] := S_SPAWN3;
     break;
    13:
     player.savesprites[sa.mapspot] := S_SPAWN4;
     break;
    14:
     player.savesprites[sa.mapspot] := S_SPAWN5;
     break;
    15:
     player.savesprites[sa.mapspot] := S_SPAWN6;
     break;
    16:
     player.savesprites[sa.mapspot] := S_SPAWN7;
     break;
    17:
     player.savesprites[sa.mapspot] := S_SPAWN8;
     break;
    18:
     player.savesprites[sa.mapspot] := S_SPAWN9;
     break;
    19:
     player.savesprites[sa.mapspot] := S_SPAWN10;
     break;
    20:
     player.savesprites[sa.mapspot] := S_SPAWN11;
     break;
    21:
     player.savesprites[sa.mapspot] := S_SPAWN12;
     break;
    22:
     player.savesprites[sa.mapspot] := S_SPAWN13;
     break;
    23:
     player.savesprites[sa.mapspot] := S_SPAWN14;
     break;
    24:
     player.savesprites[sa.mapspot] := S_SPAWN15;
     break;
    100:
     player.savesprites[sa.mapspot] := S_SPAWN8_NS;
     break;
    101:
     player.savesprites[sa.mapspot] := S_SPAWN9_NS;
     break;
     end;
  UpdateWait;

  (* elevators *)
  for(elev_p := firstelevobj.next;elev_p <> @lastelevobj;elev_p := elev_p.next)
  case elev_p.type  of
  begin
    E_NORMAL:
     if not elev_p.nosave then
     begin
       if elev_p.elevTimer = $70000000 then
  player.savesprites[elev_p.mapspot] := S_PAUSEDELEVATOR;
       else
  player.savesprites[elev_p.mapspot] := S_ELEVATOR;
        end;
     break;
    E_TIMED:
     case elev_p.elevTimer  of
     begin
       12600:
  player.savesprites[elev_p.mapspot] := S_ELEVATOR3M;
  break;
       25200:
  player.savesprites[elev_p.mapspot] := S_ELEVATOR6M;
  break;
       63000:
  player.savesprites[elev_p.mapspot] := S_ELEVATOR15M;
  break;
        end;
     break;
    E_SWITCHDOWN:
     player.savesprites[elev_p.mapspot] := S_TRIGGERD1;
     break;
    E_SWITCHDOWN2:
     player.savesprites[elev_p.mapspot] := S_TRIGGERD2;
     break;
    E_SECRET:
     player.savesprites[elev_p.mapspot] := S_SDOOR;
     break;
    E_SWAP:
     if ((elev_p.position = elev_p.floor) and ( not elev_p.elevUp)) or (elev_p.elevDown) player.savesprites[elev_p.mapspot] := S_ELEVATORLOW;
      else if ((elev_p.position = elev_p.ceiling) and ( not elev_p.elevDown)) or (elev_p.elevUp) player.savesprites[elev_p.mapspot] := S_ELEVATORHIGH;
     break;
     end;

  UpdateWait;

  sprintf(fname,SAVENAME,n);
  f := fopen(fname,'w+b');
  if (f = NULL) MS_Error('SaveGame: File Open Error: %s',fname);
  UpdateWait;
  if (not fwrite and (player,sizeof(player),1,f)) MS_Error('SaveGame: File Write Error:%s',fname);
  UpdateWait;
  fclose(f);
  EndWait;
  end;


procedure resetengine;
begin
  turnrate := 0;
  moverate := 0;
  fallrate := 0;
  strafrate := 0;
  exitexists := false;
  BonusItem.time := 2100;
  BonusItem.score := 0;
  timecount := 0;
  frames := 0;
  player.timecount := 0;
  weapdelay := 0;
  secretdelay := 0;
  frames := 0;
  keyboardDelay := 0;
  spritemovetime := 0;
  wallanimationtime := 0;
  msgtime := 0;
  RearViewTime := 0;
  RearViewDelay := 0;
  netsendtime := 0;
  SwitchTime := 0;
  inventorytime := 0;
  nethurtsoundtime := 0;
  midgetmode := 0;
  fxtimecount := 0;
  ResetMouse;
  end;


procedure selectsong(int songmap);
begin
  char fname[20];
  pattern: integer;

{$IFDEF DEMO}
  songmap mod  := 5;
{$ENDIF}
  case songmap  of
  begin
   0:
    pattern := 0;
    strcpy(fname,'SONG0.S3M');
    break;
   1:
    pattern := 20;
    strcpy(fname,'SONG0.S3M');
    break;
   2:
    pattern := 37;
    strcpy(fname,'SONG0.S3M');
    break;
   3:
    pattern := 54;
    strcpy(fname,'SONG0.S3M');
    break;
   4:
    pattern := 73;
    strcpy(fname,'SONG0.S3M');
    break;

   5:
    pattern := 0;
    strcpy(fname,'SONG2.S3M');
    break;
   6:
    pattern := 26;
    strcpy(fname,'SONG2.S3M');
    break;
   7:
    pattern := 46;
    strcpy(fname,'SONG2.S3M');
    break;
   8:
    pattern := 64;
    strcpy(fname,'SONG2.S3M');
    break;
   9:
    pattern := 83;
    strcpy(fname,'SONG2.S3M');
    break;

   10:
    pattern := 0;
    strcpy(fname,'SONG3.S3M');
    break;
   11:
    pattern := 39;
    strcpy(fname,'SONG3.S3M');
    break;
   12:
    pattern := 58;
    strcpy(fname,'SONG3.S3M');
    break;
   13:
    pattern := 78;
    strcpy(fname,'SONG3.S3M');
    break;
   14:
    pattern := 94;
    strcpy(fname,'SONG3.S3M');
    break;

   15:
    pattern := 0;
    strcpy(fname,'SONG1.S3M');
    break;
   16:
    pattern := 24;
    strcpy(fname,'SONG1.S3M');
    break;
   17:
    pattern := 45;
    strcpy(fname,'SONG1.S3M');
    break;

   18:
    pattern := 0;
    strcpy(fname,'SONG4.S3M');
    break;
   19:
    pattern := 10;
    strcpy(fname,'SONG4.S3M');
    break;
   20:
    pattern := 21;
    strcpy(fname,'SONG4.S3M');
    break;
   21:
    pattern := 0;
    strcpy(fname,'SONG8.MOD');
    break;

   22:
    if netmode then
    begin
      pattern := 0;
      strcpy(fname,'SONG14.MOD');
       end;
    else
    begin
      pattern := 0;
      strcpy(fname,'ENDING.MOD');
       end;
    break;

   23:
    pattern := 0;
    strcpy(fname,'SONG5.MOD');
    break;
   24:
    pattern := 0;
    strcpy(fname,'SONG6.MOD');
    break;
   25:
    pattern := 0;
    strcpy(fname,'SONG7.MOD');
    break;
   26:
    pattern := 33;
    strcpy(fname,'SONG4.S3M');
    break;
   27:
    pattern := 0;
    strcpy(fname,'SONG9.MOD');
    break;
   28:
    pattern := 0;
    strcpy(fname,'SONG10.MOD');
    break;
   29:
    pattern := 0;
    strcpy(fname,'SONG11.MOD');
    break;
   30:
    pattern := 0;
    strcpy(fname,'SONG12.MOD');
    break;
   31:
    pattern := 0;
    strcpy(fname,'SONG13.MOD');
    break;

   99:
    pattern := 0;
    strcpy(fname,'PROBE.MOD');
    break;

   default:
    pattern := 0;
    strcpy(fname,'SONG0.S3M');
    break;

    end;
  PlaySong(fname,pattern);
  end;


procedure EndGame1;
begin
  char name[64];

  selectsong(22);

{$IFDEF CDROMGREEDDIR}
  sprintf(name,'%c:\\GREED\\MOVIES\\PRISON1.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\GREED\\MOVIES\\TEMPLE1.FLI',cdr_drivenum+'A');
  playfli(name,0);
{$ELSE}
  sprintf(name,'%c:\\MOVIES\\PRISON1.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\MOVIES\\TEMPLE1.FLI',cdr_drivenum+'A');
  playfli(name,0);
{$ENDIF}

  VI_FillPalette(0,0,0);

  loadscreen('REDCHARS');
  VI_FadeIn(0,256,colors,48);
  Wait(140);
  for(fontbasecolor := 64;fontbasecolor<73;++fontbasecolor)
  begin
   printy := 80;
   FN_PrintCentered(
    'BY SUCCESSFULLY BRAVING THE DESARIAN\n'
    'PENAL COLONY YOU EMERGE VICTORIOUS\n'
    'WITH THE BRASS RING OF BYZANT IN HAND.\n'
    '...BUT IT'S NOT OVER YET, HUNTER.\n'
    'IT'S ON TO PHASE TWO OF THE HUNT, THE\n'
    'CITY TEMPLE OF RISTANAK.  ARE YOU\n'
    'PREPARED TO FACE THE Y'RKTARELIAN\n'
    'PRIESTHOOD AND THEIR PAGAN GOD?\n'
    'NOT BLOODY LIKELY...\n'
    '\n\n\n\n\nTO BE CONTINUED...\n');
    end;
  newascii := false;
  for (;)
  begin
   Wait(10);
   if (newascii) break;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  memset(screen,0,64000);

  loadscreen('SOFTLOGO');
  VI_FadeIn(0,256,colors,48);
  newascii := false;
  for (;)
  begin
   Wait(10);
   if (newascii) break;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  memset(screen,0,64000);

  loadscreen('CREDITS1');
  VI_FadeIn(0,256,colors,48);
  newascii := false;
  for (;)
  begin
   Wait(10);
   if (newascii) break;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  memset(screen,0,64000);

  loadscreen('CREDITS2');
  VI_FadeIn(0,256,colors,48);
  newascii := false;
  for (;)
  begin
   Wait(10);
   if (newascii) break;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  memset(screen,0,64000);

#ifndef ASSASSINATOR
  loadscreen('CREDITS3');
  VI_FadeIn(0,256,colors,48);
  newascii := false;
  for (;)
  begin
   Wait(10);
   if (newascii) break;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  memset(screen,0,64000);
{$ENDIF}

  redo := true;
  end;


procedure EndGame2;
begin
  char name[64];

  selectsong(22);

{$IFDEF CDROMGREEDDIR}
  sprintf(name,'%c:\\GREED\\MOVIES\\TEMPLE2.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\GREED\\MOVIES\\JUMPBAS1.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\GREED\\MOVIES\\JUMPBAS2.FLI',cdr_drivenum+'A');
  playfli(name,0);
{$ELSE}
  sprintf(name,'%c:\\MOVIES\\TEMPLE2.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\MOVIES\\JUMPBAS1.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\MOVIES\\JUMPBAS2.FLI',cdr_drivenum+'A');
  playfli(name,0);
{$ENDIF}


  VI_FillPalette(0,0,0);

  loadscreen('REDCHARS');
  VI_FadeIn(0,256,colors,48);
  Wait(140);
  for(fontbasecolor := 64;fontbasecolor<73;++fontbasecolor)
  begin
   printy := 80;
   FN_PrintCentered(
    'WITH Y'RKTAREL DEAD AND THE PRIESTHOOD\n'
    'IN RUINS CONGRATULATE YOURSELF, HUNTER.\n'
    'YOU'VE ANNHILIATED YET ANOTHER CULTURE\n'
    'ALL FOR THE SAKE OF THE HUNT.\n'
    '...BUT DON'T RELAX YET, FOR IT'S ON TO\n'
    'PHASE THREE OF THE HUNT.  THIS TIME\n'
    'YOU'LL BATTLE AN ENTIRE ARMY AS YOU FACE\n'
    'OFF WITH LORD KAAL IN HIS SPACEBORN\n'
    'MOUNTAIN CITADEL.\n'
    'DO YOU HAVE WHAT IT TAKES TO SLAY LORD\n'
    'KAAL AND WREST FROM HIM THE IMPERIAL SIGIL?\n'
    '\n\n\n\n\nTO BE CONTINUED...\n');
    end;
  newascii := false;
  for (;)
  begin
   Wait(10);
   if (newascii) break;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  memset(screen,0,64000);

  loadscreen('SOFTLOGO');
  VI_FadeIn(0,256,colors,48);
  newascii := false;
  for (;)
  begin
   Wait(10);
   if (newascii) break;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  memset(screen,0,64000);

  loadscreen('CREDITS1');
  VI_FadeIn(0,256,colors,48);
  newascii := false;
  for (;)
  begin
   Wait(10);
   if (newascii) break;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  memset(screen,0,64000);

  loadscreen('CREDITS2');
  VI_FadeIn(0,256,colors,48);
  newascii := false;
  for (;)
  begin
   Wait(10);
   if (newascii) break;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  memset(screen,0,64000);

  loadscreen('CREDITS3');
  VI_FadeIn(0,256,colors,48);
  newascii := false;
  for (;)
  begin
   Wait(10);
   if (newascii) break;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  memset(screen,0,64000);

  redo := true;
  end;


procedure EndGame3;
begin
  char name[64];

{$IFDEF CDROMGREEDDIR}
  sprintf(name,'%c:\\GREED\\MOVIES\\JUMPBAS3.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\GREED\\MOVIES\\JUMPBAS4.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\GREED\\MOVIES\\JUMPBAS5.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\GREED\\MOVIES\\JUMPBAS6.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\GREED\\MOVIES\\JUMPBS6B.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\GREED\\MOVIES\\JUMPBAS7.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\GREED\\MOVIES\\JUMPBAS8.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\GREED\\MOVIES\\JUMPBAS9.FLI',cdr_drivenum+'A');
  playfli(name,0);
{$ELSE}
  sprintf(name,'%c:\\MOVIES\\JUMPBAS3.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\MOVIES\\JUMPBAS4.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\MOVIES\\JUMPBAS5.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\MOVIES\\JUMPBAS6.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\MOVIES\\JUMPBS6B.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\MOVIES\\JUMPBAS7.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\MOVIES\\JUMPBAS8.FLI',cdr_drivenum+'A');
  playfli(name,0);
  sprintf(name,'%c:\\MOVIES\\JUMPBAS9.FLI',cdr_drivenum+'A');
  playfli(name,0);
{$ENDIF}

  VI_FillPalette(0,0,0);

  loadscreen('REDCHARS');
  VI_FadeIn(0,256,colors,48);
  Wait(140);
  for(fontbasecolor := 64;fontbasecolor<73;++fontbasecolor)
  begin
   printy := 80;
{$IFDEF GAME3}
   FN_PrintCentered(
    'WELL, YOU SUCCESSFULLY PULLED DOWN THE LAST\n'
    'VESTIGES OF MILITARY AUTHORITY FOR THE SECTOR.\n'
    'YOU COULD HAVE RICHES, FAME AND POWER,\n'
    'AND YOUR CHOICE OF PLEASURE PLANETS.\n'
    'UNFORTUNATELY, YOU'RE STUCK ON A SHIP THAT'S\n'
    'DRIFTING THROUGH HYPERSPACE.  IN SHORT\n'
    'YOU'RE LOST.  LUCKY FOR THE PASSENGERS\n'
    'THAT YOU'RE A HEROIC HUNTER THAT CAN SAVE\n'
    'THEM FROM THEIR FATE IN THE CLUTCHES\n'
    'OF THE MAZDEEN EMPEROR.  OR CAN YOU?\n'
    '\n\n\n\n\nTO BE CONTINUED...\n');
{$ELSE}
   FN_PrintCentered(
    'WELL, YOU SUCCESSFULLY BRAVED A BLOODY RIOT, FACED\n'
    'A GOD AND SURVIVED, AND PULLED DOWN THE LAST\n'
    'VESTIGES OF MILITARY AUTHORITY FOR THE SECTOR.\n'
    'YOU COULD HAVE RICHES, FAME AND POWER,\n'
    'AND YOUR CHOICE OF PLEASURE PLANETS.\n'
    'UNFORTUNATELY, YOU'RE STUCK ON A SHIP THAT'S\n'
    'DRIFTING THROUGH HYPERSPACE.  IN SHORT\n'
    'YOU'RE LOST.  LUCKY FOR THE PASSENGERS\n'
    'THAT YOU'RE A HEROIC HUNTER THAT CAN SAVE\n'
    'THEM FROM THEIR FATE IN THE CLUTCHES\n'
    'OF THE MAZDEEN EMPEROR.  OR CAN YOU?\n'
    '\n\n\n\n\nTO BE CONTINUED...\n');
{$ENDIF}
    end;
  newascii := false;
  for (;)
  begin
   Wait(10);
   if (newascii) break;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  memset(screen,0,64000);

  loadscreen('SOFTLOGO');
  VI_FadeIn(0,256,colors,48);
  newascii := false;
  for (;)
  begin
   Wait(10);
   if (newascii) break;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  memset(screen,0,64000);

  loadscreen('CREDITS1');
  VI_FadeIn(0,256,colors,48);
  newascii := false;
  for (;)
  begin
   Wait(10);
   if (newascii) break;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  memset(screen,0,64000);

  loadscreen('CREDITS2');
  VI_FadeIn(0,256,colors,48);
  newascii := false;
  for (;)
  begin
   Wait(10);
   if (newascii) break;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  memset(screen,0,64000);

  loadscreen('CREDITS3');
  VI_FadeIn(0,256,colors,48);
  newascii := false;
  for (;)
  begin
   Wait(10);
   if (newascii) break;
    end;
  VI_FadeOut(0,256,0,0,0,48);
  memset(screen,0,64000);

  redo := true;
  end;


procedure newmap(int map,int activate);
begin
  lump, i, n, songmap: integer;

  if activate then
  begin
   memset(player.westmap,0,sizeof(player.westmap));
   memset(player.northmap,0,sizeof(player.northmap));
   memset(player.events,0,sizeof(player.events));
   player.x := -1;
    end;
  player.map := map;
  songmap := map;
  if ((map <> 8) and (map <> 16)) or (netmode) then
  selectsong(songmap);
  else
  StopMusic;
  if activate = 1 then
  MissionBriefing(map);
  resetengine;
  lump := CA_GetNamedNum('map') + map + 1;
{$IFDEF DEMO}
  if (map = 3) and ( not netmode) ;
  else
  begin
   LoadNewMap(lump);
   if activate then
   begin
     LoadScript(lump,true);
     ActivateSpritesFromMap;
      end;
   else
    LoadScript(lump,false);
    end;
{$ELSE}

{$IFDEF GAME1}
  if (map = 8) and ( not netmode) then
  EndGame1;
#elif defined(GAME2)
  if (map = 16) and ( not netmode) then
  EndGame2;
{$ELSE}
  if (map = 22) and ( not netmode) then
  EndGame3;
{$ENDIF}

  else
  begin
   LoadNewMap(lump);
   if activate then
   begin
     LoadScript(lump,true);
     ActivateSpritesFromMap;
      end;
   else
    LoadScript(lump,false);
    end;
{$ENDIF}
  EndWait;
  for(i := 0;i<5;i++)
  if player.weapons[i] <> -1 then
  begin
    n := player.weapons[i];
    weapons[n].charge := 100;
    weapons[n].chargetime := timecount+weapons[n].chargerate;
     end;
  end;


procedure LoadGame(int n);
begin
  char fname[20];
  handle, i, oldscore: integer;

  sprintf(fname,SAVENAME,n);
  if ((handle := open(fname,O_RDONLY) or (O_BINARY)) = -1) exit;
  if (not read(handle,) and (player,sizeof(player))) then
  begin
   close(handle);
   MS_Error('LoadGame: Error loading %s not ',fname);
    end;
  close(handle);
  oldscore := player.levelscore;

  resetengine;
  gameloaded := true;
  player.scrollmax := windowHeight+player.scrollmin;
  timecount := player.timecount;
  keyboardDelay := 0;
  BonusItem.time := timecount+2100;
  wallanimationtime := player.timecount;
  spritemovetime := player.timecount;

  newmap(player.map,0);
  memcpy(mapsprites,player.savesprites,sizeof(mapsprites));
  ActivateSpritesFromMap;
  timecount := player.timecount;
  loadweapon(player.weapons[player.currentweapon]);
  player.levelscore := oldscore;
  memcpy(westwall,player.westwall,sizeof(westwall));
  memcpy(northwall,player.northwall,sizeof(northwall));
  eventloading := true;
  for (i := 1;i<256;i++)
  if player.events[i] then
   Event(i,true);
  eventloading := false;
  end;


procedure heal(int n);
begin
  player.shield := player.shield + n;
  if (player.shield>player.maxshield) player.shield := player.maxshield;
  hurtborder := true;
  end;


procedure medpaks(int n);
begin
  if (player.angst <= 0) exit;
  player.angst := player.angst + n;
  if (player.angst>player.maxangst) player.angst := player.maxangst;
  hurtborder := true;
  end;


procedure hurt(int n);
begin
  if (godmode) or (player.angst = 0) exit;

  if specialeffect = SE_INVISIBILITY then
  n := n / 3;

  if specialeffect = SE_REVERSOPILL then
  begin
   medpaks(n/2);
   heal(n/2);
   exit;
    end;
  player.status := 1;
  if n>player.shield then
  begin
   n := n - player.shield;
   player.shield := 0;
   player.angst := player.angst - n;
   if (player.angst<0) player.angst := 0;
    end;
  else player.shield := player.shield - n;
  hurtborder := true;
  if player.angst = 0 then
  begin
   SoundEffect(SN_DEATH0+player.chartype,15,player.x,player.y);
   if (netmode) NetSoundEffect(SN_DEATH0+player.chartype,15,player.x,player.y);
   SoundEffect(SN_DEATH0+player.chartype,15,player.x,player.y);
   if (netmode) NetSoundEffect(SN_DEATH0+player.chartype,15,player.x,player.y);
    end;
  else
  begin
   SoundEffect(SN_HIT0+player.chartype,15,player.x,player.y);
   if (netmode) and (timecount>nethurtsoundtime) then
   begin
     NetSoundEffect(SN_HIT0+player.chartype,15,player.x,player.y);
     nethurtsoundtime := timecount+35;
      end;
    end;
  end;


procedure newplayer(int map,int chartype,int difficulty);
begin
  parm: integer;

  parm := MS_CheckParm('char');
  if (parm) and (parm<my_argc-1) then
  begin
   chartype := atoi(my_argv[parm+1]);
   if (chartype<0) or (chartype >= MAXCHARTYPES) then
    MS_Error('Invalid Character Selection (%i)',chartype);
    end;

  gameloaded := true;
  memset and (player,0,sizeof(player));
  player.scrollmin := 0;
  player.scrollmax := windowHeight;
  player.x := -1;
  player.map := map;
  player.height := pheights[chartype];
  player.maxangst := pmaxangst[chartype];
  player.maxshield := pmaxshield[chartype];
  player.walkmod := pwalkmod[chartype];
  player.runmod := prunmod[chartype];
  player.jumpmod := pjumpmod[chartype];
  player.shield := player.maxshield;
  player.angst := player.maxangst;
  player.levelscore := levelscore;
  player.chartype := chartype;
  player.difficulty := difficulty;
  resetengine;
  case chartype  of
  begin
   0: // psyborg
    player.weapons[0] := 7;
    player.weapons[1] := 1;
    break;
   1: // lizard
    player.weapons[0] := 8;
    player.weapons[1] := 9;
    break;
   2: // mooman
    player.weapons[0] := 13;
    player.weapons[1] := 11;
    break;
   3: // specimen 7
    player.weapons[0] := 14;
    player.weapons[1] := 10;
    break;
   4: // trix
    player.weapons[0] := 15;
    player.weapons[1] := 12;
    break;
   5:
    player.weapons[0] := 8;
    player.weapons[1] := 9;
    end;
  player.weapons[2] := -1;
  player.weapons[3] := -1;
  player.weapons[4] := -1;
  player.ammo[0] := 100;
  player.ammo[1] := 100;
  player.ammo[2] := 100;
  player.inventory[7] := 2;
  player.inventory[5] := 2;
  player.inventory[4] := 2;
  player.inventory[2] := 4;
  newmap(player.map,1);
  timecount := 0;
  loadweapon(player.weapons[0]);
  end;


procedure addscore(int n);
begin
  player.score := player.score + n;
  if (player.score>4000000000) player.score := 0;
  player.levelscore := player.levelscore - n;
  if (player.levelscore<0) player.levelscore := 0;
  end;


procedure ControlMovement;


procedure respawnplayer;
begin
  mapspot: integer;
  x, y, n: integer;

  do
  begin
   n := (clock+MS_RndT) mod MAXSTARTLOCATIONS;
   x := startlocations[n][0];
   y := startlocations[n][1];
   mapspot := y*MAPCOLS+x;
    end; while (mapsprites[mapspot]>0);
  player.x := (x shl FRACTILESHIFT) + (32 shl FRACBITS);
  player.y := (y shl FRACTILESHIFT) + (32 shl FRACBITS);
  player.z := RF_GetFloorZ(player.x,player.y)+player.height;
  player.angle := NORTH;
  NetNewPlayerData;
  end;


procedure PlayerCommand;


procedure MissionBriefing(int map);
begin
  pprimaries, psecondaries, i, tprimaries, tsecondaries, oldtimecount: integer;
  char str[255], name[64];
  byte *scr;

  if (netmode) or (nointro) then
   exit;

  scr := (byte *)malloc(64000);
  if scr = NULL then
  MS_Error('Error allocating MissonBriefing buffer');
  memcpy(scr,viewbuffer,64000);

  oldtimecount := timecount;

  INT_TimerHook(NULL);
  font := font1;

  if map = 0 then
  begin
   VI_FillPalette(0,0,0);

  loadscreen('BRIEF3');
  VI_BlitView;
  VI_FadeIn(0,256,colors,64);
   Wait(70);
   newascii := false;
   for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
   begin
     printy := 149;
     FN_PrintCentered(
      'WELCOME ABOARD HUNTER.\n'
      'DUE TO INCREASED FUNDING FROM THE AVC YOU'LL BE EQUIPPED WITH THE\n'
      'LATEST IN HUNTER HARDWARE.  ALONG WITH YOUR EXISTING AUTO MAPPER,\n'
      'HEAT AND MOTION SENSORS HAVE BEEN ADDED TO YOUR VISUAL ARRAY AS\n'
      'WELL AS AN AFT SENSORY SYSTEM, OR A.S.S. CAM, FOR CONTINUOUS\n'
      'REAR VIEW.');
   VI_BlitView;
     Wait(3);
      end;
  
   for (i :=  0 ; i < 200 ; i++)
     memset(ylookup[i],i,320);
   VI_BlitView;

   for(;)
   begin
     Wait(10);
     if (newascii) break;
      end;
   if (lastascii = 27) goto end;

   loadscreen('BRIEF3');
   newascii := false;
   for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
   begin
     printy := 149;
     FN_PrintCentered(
      'A MENUING SYSTEM HAS ALSO BEEN INSTALLED ALLOWING YOU TO\n'
      'FINE TUNE YOUR HARDWARE SETTINGS.  STAY ALERT THOUGH, YOUR MENU\n'
      'OVERLAY CANCELS INPUT FROM YOUR VISUAL ARRAY SO DON'T EXPECT TO\n'
      'SEE THINGS COMING WHILE YOU'RE ADJUSTING YOUR SETTINGS.');
     Wait(3);
      end;
   for(;)
   begin
     Wait(10);
     if (newascii) break;
      end;
   if (lastascii = 27) goto end;
   VI_FadeOut(0,256,0,0,0,64);


   loadscreen('BRIEF1');
   VI_FadeIn(0,256,colors,64);
   Wait(70);
   newascii := false;
   for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
   begin
     printy := 139;
     FN_PrintCentered(
      'BUILT FROM A HOLLOWED ASTEROID, THE DESARIAN PENAL COLONY\n'
      'HOUSES THE DREGS OF IMPERIAL SOCIETY.  A RIOT IS IN PROGRESS\n'
      'WHICH SHOULD MAKE ITEM RETRIEVAL INTERESTING.\n'
      'THE PRIMARY ITEM TO BE LOCATED HERE IS THE BYZANTIUM BRASS RING,\n'
      'AN ANCIENT ARTIFACT NOW USED AS THE POWER CORE FOR THE COMPLEX.\n'
      'SUCH AN ENIGMATIC ENERGY SOURCE IS OF OBVIOUS INTEREST TO A.V.C.\n'
      'RESEARCH, SO ACQUIRING IT UNDAMAGED IS ESSENTIAL.\n'
      'YOUR ENTRY POINT WILL BE AT THE BASE OF THE COMPLEX.\n');
     Wait(3);
      end;
   for(;)
   begin
     Wait(10);
     if (newascii) break;
      end;
   if (lastascii = 27) goto end;
   VI_FadeOut(0,256,0,0,0,64);

   loadscreen('BRIEF2');
   VI_FadeIn(0,256,colors,64);
   Wait(70);
   newascii := false;
   for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
   begin
     printy := 139;
     FN_PrintCentered(
      'EACH SUBLEVEL WILL HAVE A MANDATORY PRIMARY OBJECTIVE, AS WELL\n'
      'AS OPTIONAL SECONDARY OBJECTIVES, ALL OF WHICH HELP YOU TO\n'
      'ACHIEVE A STATED POINT TOTAL NEEDED TO ADVANCE TO THE NEXT LEVEL.\n'
      'POINTS ARE ALSO AWARDED FOR KILLS AS WELL AS ACQUIRING RANDOMLY\n'
      'PLACED OBJECTS TAKEN FROM THE SHIP'S INVENTORY. EXPECT\n'
      'NON-COOPERATIVES (NOPS) FROM OTHER PARTS OF THE COLONY TO BE\n'
      'BROUGHT IN AT REGULAR INTERVALS TO REPLACE CASUALTIES OF THE HUNT.\n');
     Wait(3);
      end;
   for(;)
   begin
     Wait(10);
     if (newascii) break;
      end;
   if (lastascii = 27) goto end;

   loadscreen('BRIEF2');
   newascii := false;
   for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
   begin
     printy := 139;
     FN_PrintCentered(
      'THIS MISSION WILL BEGIN IN THE INMATE PROCESSING AREA, WHERE\n'
      'YOU ARE TO SEARCH FOR AN EXPERIMENTAL EXPLOSIVE HIDDEN\n'
      'IN THE SUBLEVEL.\n'
      'SECONDARY GOALS ARE PHOSPHER PELLETS AND DELOUSING KITS.\n');
     Wait(3);
      end;
   for(;)
   begin
     Wait(10);
     if (newascii) break;
      end;
   if (lastascii = 27) goto end;

   loadscreen('BRIEF2');
   newascii := false;
   for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
   begin
     printy := 139;
     FN_PrintCentered(
      'YOU WILL BE MONITORED.  POINTS WILL BE AWARDED FOR PRIMARY,\n'
      'SECONDARY, AND RANDOM ITEMS, AS WELL AS FOR KILLING NOPS.\n'
      'WHEN YOU'VE ACQUIRED THE PRIMARY ITEM AND YOUR POINT TOTAL\n'
      'MEETS OR EXCEEDS 50000 WE'LL OPEN A TRANSLATION NEXUS.  WATCH\n'
      'FOR THE FLASHING EXIT SIGN.  ENTER THE NEXUS AND WE'LL\n'
      'TRANSLATE YOU TO THE NEXT AREA OF THE BASE.\n \nGOOD LUCK.');
     Wait(3);
      end;
   for(;)
   begin
     Wait(10);
     if (newascii) break;
      end;
   if (lastascii = 27) goto end;
    end;
{$IFDEF GAME1}
  else if (map<8)
#elif defined(GAME2)
  else if (map<16)
{$ELSE}
  else if (map<22)
{$ENDIF}
begin
   if map = 8 then
   begin
     player.levelscore := levelscore;
     player.weapons[2] := -1;
     player.weapons[3] := -1;
     player.weapons[4] := -1;
     player.currentweapon := 0;
     loadweapon(player.weapons[0]);
     memset(player.inventory,0,sizeof(player.inventory));
     player.inventory[7] := 2;
     player.inventory[5] := 2;
     player.inventory[4] := 2;
     player.inventory[2] := 4;
     player.ammo[0] := 100;
     player.ammo[1] := 100;
     player.ammo[2] := 100;
     player.angst := player.maxangst;
     player.shield := 200;
     selectsong(99);

{$IFDEF CDROMGREEDDIR}

  #ifndef GAME2
      sprintf(name,'%c:\\GREED\\MOVIES\\PRISON1.FLI',cdr_drivenum+'A');
      playfli(name,0);
  {$ENDIF}
      sprintf(name,'%c:\\GREED\\MOVIES\\TEMPLE1.FLI',cdr_drivenum+'A');
      playfli(name,0);

{$ELSE}

  #ifndef GAME2
      sprintf(name,'%c:\\MOVIES\\PRISON1.FLI',cdr_drivenum+'A');
      playfli(name,0);
  {$ENDIF}
      sprintf(name,'%c:\\MOVIES\\TEMPLE1.FLI',cdr_drivenum+'A');
      playfli(name,0);


{$ENDIF}

     selectsong(map);

     VI_FillPalette(0,0,0);
     loadscreen('BRIEF4');
     VI_FadeIn(0,256,colors,64);
     Wait(70);
     newascii := false;
     for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
     begin
       printy := 139;
       FN_PrintCentered(
       'THIS IS THE CITY-TEMPLE OF RISTANAK, ANCIENT HOME TO THE\n'
       'PRIESTHOOD OF YRKTAREL.  THE PRIESTHOOD HAS WORSHIPPED THEIR\n'
       'PAGAN DEITY FOR CENTURIES IN PEACE... UNTIL NOW.\n'
      );

       Wait(3);
        end;
     for(;)
     begin
       Wait(10);
       if (newascii) break;
        end;
     if (lastascii = 27) goto end;
     VI_FadeOut(0,256,0,0,0,64);

     loadscreen('BRIEF5');
     VI_FadeIn(0,256,colors,64);
     Wait(70);
     newascii := false;
     for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
     begin
       printy := 139;
       FN_PrintCentered(
       'THE PRIMARY OBJECTIVE FOR THE TEMPLE IS THE ENCODED\n'
       'PERSONALITY MATRIX OF THE DEMON-SAINT B'RNOURD.  THIS IS,\n'
       'OF COURSE, AN ITEM WHOSE POSSESSION, IF KNOWN, WOULD BRING\n'
       'INSTANT DESTRUCTION.  THE IMPERIAL COUNCIL WOULD ORDER THE\n'
       'SECTOR STERILIZED IF IT KNEW OF ITS EXISTENCE.\n'
       'THE A.V.C. BELIEVES THE ENCODE TO CONTAIN FORGOTTEN\n'
       'TECHNOLOGIES WHICH WOULD BE PRICELESS ON THE BLACK MARKET.\n'
       'IT IS YOUR MISSION TO ACQUIRE IT.\n'
      );

       Wait(3);
        end;
     for(;)
     begin
       Wait(10);
       if (newascii) break;
        end;
     if (lastascii = 27) goto end;
     VI_FadeOut(0,256,0,0,0,64);

   end
   else if map = 16 then
   begin
     player.levelscore := levelscore;
     player.weapons[2] := -1;
     player.weapons[3] := -1;
     player.weapons[4] := -1;
     player.currentweapon := 0;
     loadweapon(player.weapons[0]);
     memset(player.inventory,0,sizeof(player.inventory));
     player.inventory[7] := 2;
     player.inventory[5] := 2;
     player.inventory[4] := 2;
     player.inventory[2] := 4;
     player.ammo[0] := 100;
     player.ammo[1] := 100;
     player.ammo[2] := 100;
     player.angst := player.maxangst;
     player.shield := 200;
     selectsong(99);
{$IFDEF CDROMGREEDDIR}

  #ifndef GAME3
      sprintf(name,'%c:\\GREED\\MOVIES\\TEMPLE2.FLI',cdr_drivenum+'A');
      playfli(name,0);
  {$ENDIF}
      sprintf(name,'%c:\\GREED\\MOVIES\\JUMPBAS1.FLI',cdr_drivenum+'A');
      playfli(name,0);
      sprintf(name,'%c:\\GREED\\MOVIES\\JUMPBAS2.FLI',cdr_drivenum+'A');
      playfli(name,0);
{$ELSE}

  #ifndef GAME3
      sprintf(name,'%c:\\MOVIES\\TEMPLE2.FLI',cdr_drivenum+'A');
      playfli(name,0);
  {$ENDIF}
      sprintf(name,'%c:\\MOVIES\\JUMPBAS1.FLI',cdr_drivenum+'A');
      playfli(name,0);
      sprintf(name,'%c:\\MOVIES\\JUMPBAS2.FLI',cdr_drivenum+'A');
      playfli(name,0);
{$ENDIF}


     selectsong(map);

     VI_FillPalette(0,0,0);

     loadscreen('BRIEF6');
     VI_FadeIn(0,256,colors,64);
     Wait(70);
     newascii := false;
     for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
     begin
       printy := 139;
       FN_PrintCentered(
       'DURING THE INSURRECTION AT ALPHA PRAM,  THE FOURTH PLANET IN\n'
       'THE SYSTEM, WHICH WAS BASE TO THE ELITE GALACTIC CORPS, WAS\n'
       'DESTROYED BY A BOVINARIAN VIOLATOR SHIP.  THE SHIELDING\n'
       'SURROUNDING THE MOUNTAIN WHERE THE CORPS WAS BASED WAS SO\n'
       'STRONG, HOWEVER, THAT THE MOUNTAIN SURVIVED.  THE BASE WAS\n'
       'THEN MOUNTED TO A TROJAN GATE JUMP POINT AND TO THIS DAY IT\n'
       'REMAINS AS A WAY POINT BETWEEN THE RIM WORLDS AND THE CORE\n'
       'QUARTER, AS WELL AS HOUSING MILITARY MIGHT IN THIS SECTOR.\n'
      );
       Wait(3);
        end;
     for(;)
     begin
       Wait(10);
       if (newascii) break;
        end;
     if (lastascii = 27) goto end;
     VI_FadeOut(0,256,0,0,0,64);

     loadscreen('BRIEF7');
     VI_FadeIn(0,256,colors,64);
     Wait(70);
     newascii := false;
     for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
     begin
       printy := 139;
       FN_PrintCentered(
       'THE PRIMARY OBJECTIVE FOR THIS WORLD IS THE IMPERIAL SIGIL.\n'
       'IT IS THE SYMBOL OF POWER WHICH MAINTAINS THE CHANCELLOR\n'
       'IN HIS POSITION OF DOMINANCE WITHIN THE SECTOR.  YOU HAVE BUT\n'
       'TO TAKE THE SIGIL FROM THE CHANCELLOR HIMSELF.  UNFORTUNATELY\n'
       'FOR YOU, THE DESPOTIC CHANCELLOR HAD HIS FLESH REPLACED\n'
       'BY A CYBERNETIC SYMBIOTE IN ORDER TO INSURE HIS IMMORTALITY\n'
       'AND SUBSEQUENT ETERNAL RULE OF THE CORPS.  OVER 30 ATTEMPTS\n'
       'HAVE BEEN MADE TO WREST THE SIGIL FROM THE CHANCELLOR'S GRASP.\n'
       'THEY ALL FAILED.\n'
      );
       Wait(3);
        end;
     for(;)
     begin
       Wait(10);
       if (newascii) break;
        end;
     if (lastascii = 27) goto end;
     VI_FadeOut(0,256,0,0,0,64);

      end;

   VI_FillPalette(0,0,0);
   if map<8 then
    loadscreen('TRANS');
   else if (map<16)
    loadscreen('TRANS2');
   else
    loadscreen('TRANS3');
   VI_FadeIn(0,256,colors,64);
   newascii := false;
   pprimaries := player.primaries[0]+player.primaries[1];
   tprimaries := pcount[0] + pcount[1];
   psecondaries := 0;
   tsecondaries := 0;
   for(i := 0;i<7;i++)
   begin
     psecondaries := psecondaries + player.secondaries[i];
     tsecondaries := tsecondaries + scount[i];
      end;
   fontbasecolor := 8;
   printx := 20;
   printy := 30;
   sprintf(str,'MISSION SUCCESSFUL not ');
   FN_RawPrint3(str);
   printx := 25;
   printy := 40;
   sprintf(str,'PRIMARY GOALS STOLEN: %i of %i',pprimaries,tprimaries);
   FN_RawPrint3(str);
   printx := 25;
   printy := 50;
   sprintf(str,'SECONDARY GOALS STOLEN: %i of %i',psecondaries,tsecondaries);
   FN_RawPrint3(str);
   printx := 25;
   printy := 65;
   sprintf(str,'POINT TOTAL: %i',player.score);
   FN_RawPrint3(str);
   printx := 25;
   printy := 75;
   sprintf(str,'TOTAL KILLS: %i',player.bodycount);
   FN_RawPrint3(str);
   for(fontbasecolor := 0;fontbasecolor<9;++fontbasecolor)
   begin
     printy := 85;
     FN_PrintCentered(missioninfo[map][0]);
     FN_PrintCentered(missioninfo[map][1]);
     FN_PrintCentered(missioninfo[map][2]);
     Wait(3);
      end;
   for(;)
   begin
     Wait(10);
     if (newascii) break;
      end;
   VI_FadeOut(0,256,0,0,0,64);
    end;

end:
  memcpy(viewbuffer,scr,64000);
  free(scr);
  memset(screen,0,64000);
  VI_SetPalette(CA_CacheLump(CA_GetNamedNum('palette')));
  timecount := oldtimecount;
  end;

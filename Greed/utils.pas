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

unit utils;

interface

uses
  protos_h,
  r_public_h;

function SAVENAME: string;

(**** VARIABLES ****)
var
  primaries: array[0..3] of integer;
  secondaries: array[0..13] of integer;
  pcount: array[0..1] of integer;
  scount: array[0..6] of integer;
  bonustime: integer;

  levelscore: integer;

  gameloading, eventloading: boolean;

  startlocations: array[0..MAXSTARTLOCATIONS - 1, 0..1] of integer;

procedure KillSprite(const sp: Pscaleobj_t; const weapon: integer);

procedure ChangeViewSize(const MakeLarger: boolean);

procedure SaveGame(const n: integer);

procedure LoadGame(const n: integer);

procedure MissionBriefing(const map: integer);

procedure newplayer(const map: integer; chartype: integer; const difficulty: integer);

procedure addscore(const n: integer);

procedure respawnplayer;

procedure heal(const n: integer);

procedure medpaks(const n: integer);

procedure hurt(n: integer);

procedure loadweapon(const n: integer);

procedure newmap(const map: integer; const activate: integer);

procedure selectsong(const asongmap: integer);

procedure ResetScalePostWidth(const NewWindowWidth: integer);

implementation

uses
  g_delphi,
  constant,
  d_disk,
  d_font,
  d_ints,
  d_misc,
  d_video,
  display,
  event,
  intro,
  i_windows,
  i_video,
  menu,
  modplay,
  net,
  playfli,
  raven,
  r_conten,
  r_public,
  r_render,
  r_walls,
  spawn;

function SAVENAME: string;
begin
  if GAME1 then
    result := 'SAVE1.%d'
  else if GAME2 then
    result := 'SAVE2.%d'
  else if GAME3 then
    result := 'SAVE3.%d'
  else
    result := 'SAVEGAME.%d'
end;


(**** FUNCTIONS ****)

procedure KillSprite(const sp: Pscaleobj_t; const weapon: integer);
var
  s: Pscaleobj_t;
  i: integer;
  x, y, z: fixed_t;
begin
  if sp.deathevent <> 0 then
    RunEvent(sp.deathevent, false);
  case sp.typ of
  S_CLONE:
    begin
      if sp.startpic = CA_GetNamedNum(charnames[0]) then
      begin
        s := SpawnSprite(S_TIMEMINE, sp.x, sp.y, 0, 0, 0, 0, false, playernum);
        s.basepic := sp.startpic + 40;
        s.scale := 1;
        sp.animation := 0 + (0 shl 1) + (1 shl 5) + (0 shl 9) + ANIM_SELFDEST;
      end
      else
        sp.animation := 0 + (0 shl 1) + (8 shl 5) + ((4 + MS_RndT and 3) shl 9);
      sp.basepic := sp.startpic + 40;
      sp.rotate := rt_one;
      sp.heat := 0;
      sp.active := false;
      sp.moveSpeed := 0;
      sp.hitpoints := 0;
    end;

  S_MONSTER1,
  S_MONSTER2,
  S_MONSTER5,
  S_MONSTER7,
  S_MONSTER8,
  S_MONSTER9,
  S_MONSTER10,
  S_MONSTER12,
  S_MONSTER13,
  S_MONSTER14,
  S_MONSTER15:
    begin
      sp.basepic := sp.startpic + 48;
      sp.animation := 0 + (0 shl 1) + (8 shl 5) + ((2 + MS_RndT and 3) shl 9);
      case sp.typ of
      S_MONSTER1:
        SoundEffect(SN_MON1_DIE, 7, sp.x, sp.y);
      S_MONSTER2:
        SoundEffect(SN_MON2_DIE, 7, sp.x, sp.y);
      S_MONSTER5:
        SoundEffect(SN_MON5_DIE, 7, sp.x, sp.y);
      S_MONSTER7:
        SoundEffect(SN_MON7_DIE, 7, sp.x, sp.y);
      S_MONSTER8:
        SoundEffect(SN_MON8_DIE, 7, sp.x, sp.y);
      S_MONSTER9:
        SoundEffect(SN_MON9_DIE, 7, sp.x, sp.y);
      S_MONSTER10:
        SoundEffect(SN_MON10_DIE, 7, sp.x, sp.y);
      S_MONSTER12:
        SoundEffect(SN_MON12_DIE, 7, sp.x, sp.y);
      S_MONSTER13:
        SoundEffect(SN_MON13_DIE, 7, sp.x, sp.y);
      S_MONSTER14:
        SoundEffect(SN_MON14_DIE, 7, sp.x, sp.y);
      S_MONSTER15:
        SoundEffect(SN_MON15_DIE, 7, sp.x, sp.y);
      end;
      sp.rotate := rt_one;
      sp.heat := 0;
      sp.active := false;
      sp.moveSpeed := 0;
      sp.hitpoints := 0;
    end;

  S_MONSTER3:
    begin
      SpawnSprite(S_EXPLODE, sp.x, sp.y, sp.z, 0, 0, 0, false, 0);
      SoundEffect(SN_MON3_DIE, 7, sp.x, sp.y);
      RF_RemoveSprite(sp);
    end;

  S_MONSTER4:
    begin
      SpawnSprite(S_EXPLODE, sp.x, sp.y, sp.z, 0, 0, 0, false, 0);
      SoundEffect(SN_MON4_DIE, 7, sp.x, sp.y);
      RF_RemoveSprite(sp);
    end;

  S_MONSTER6,
  S_MONSTER11:
    begin
      for i := 0 to 29 do
        SpawnSprite(S_METALPARTS, sp.x, sp.y, sp.z + 64 * FRACUNIT, 0, 0, 0, false, 0);
      for i := 0 to 9 do
      begin
        x := sp.x + ((-64 + (MS_RndT and 127)) * FRACUNIT);
        y := sp.y + ((-64 + (MS_RndT and 127)) * FRACUNIT);
        z := sp.z + ((MS_RndT and 127) * FRACUNIT);
        SpawnSprite(S_EXPLODE + (MS_RndT and 1), x, y, z, 0, 0, 0, false, 0);
      end;
      SoundEffect(SN_EXPLODE1 + (clock and 1), 15, x, y);
      SoundEffect(SN_MON11_DIE, 7, sp.x, sp.y);
      SoundEffect(SN_MON11_DIE, 7, sp.x, sp.y);
      RF_RemoveSprite(sp);
    end;
  else
    MS_Error('Illegal KillSprite: type %d', [sp.typ]);
  end;
end;


procedure ActivateSpritesFromMap;
var
  x, y: integer;
begin
  gameloading := true;
  for y := 0 to MAPROWS - 1 do
    for x := 0 to MAPCOLS - 1 do
     if mapsprites[y * MAPCOLS + x] <> 0 then
       SpawnSprite(mapsprites[y * MAPCOLS + x], (x * MAPSIZE + 32) * FRACUNIT, (y * MAPCOLS + 32) * FRACUNIT, 0, 0, 0, 0, false, 0);
  gameloading := false;
end;


procedure ActivateSlopes;
var
  i, j, mapspot: integer;
begin
  for i := 0 to MAPCOLS - 1 do
    for j := 0 to MAPROWS - 1 do
    begin
      mapspot := i * MAPCOLS + j;
      case mapslopes[mapspot] of
      49:
        mapflags[mapspot] := mapflags[mapspot] or (POLY_SLOPE shl FLS_CEILING);
      50:
        mapflags[mapspot] := mapflags[mapspot] or (POLY_URTOLL shl FLS_CEILING);
      51:
        mapflags[mapspot] := mapflags[mapspot] or (POLY_ULTOLR shl FLS_CEILING);
      52:
        mapflags[mapspot] := mapflags[mapspot] or POLY_SLOPE;
      53:
        begin
          mapflags[mapspot] := mapflags[mapspot] or POLY_SLOPE;
          mapflags[mapspot] := mapflags[mapspot] or (POLY_URTOLL shl FLS_CEILING);
        end;
      54:
        begin
          mapflags[mapspot] := mapflags[mapspot] or POLY_SLOPE;
          mapflags[mapspot] := mapflags[mapspot] or (POLY_ULTOLR shl FLS_CEILING);
        end;
      55:
        begin
          mapflags[mapspot] := mapflags[mapspot] or POLY_URTOLL;
          mapflags[mapspot] := mapflags[mapspot] or (POLY_SLOPE shl FLS_CEILING);
        end;
      56:
         mapflags[mapspot] := mapflags[mapspot] or POLY_URTOLL;
      57:
        begin
          mapflags[mapspot] := mapflags[mapspot] or POLY_URTOLL;
          mapflags[mapspot] := mapflags[mapspot] or (POLY_ULTOLR shl FLS_CEILING);
        end;
      58:
        begin
          mapflags[mapspot] := mapflags[mapspot] or POLY_ULTOLR;
          mapflags[mapspot] := mapflags[mapspot] or (POLY_SLOPE shl FLS_CEILING);
        end;
      59:
        begin
          mapflags[mapspot] := mapflags[mapspot] or POLY_ULTOLR;
          mapflags[mapspot] := mapflags[mapspot] or (POLY_URTOLL shl FLS_CEILING);
        end;
      60:
        mapflags[mapspot] := mapflags[mapspot] or POLY_ULTOLR;
      61:
        begin
          mapflags[mapspot] := mapflags[mapspot] or POLY_SLOPE;
          mapflags[mapspot] := mapflags[mapspot] or (POLY_SLOPE shl FLS_CEILING);
        end;
      62:
        begin
          mapflags[mapspot] := mapflags[mapspot] or POLY_URTOLL;
          mapflags[mapspot] := mapflags[mapspot] or (POLY_URTOLL shl FLS_CEILING);
        end;
      63:
        begin
          mapflags[mapspot] := mapflags[mapspot] or POLY_ULTOLR;
          mapflags[mapspot] := mapflags[mapspot] or (POLY_ULTOLR shl FLS_CEILING);
        end;
      end;
    end;
end;


procedure LoadTextures;
var
  textures: array[0..255] of boolean;
  i, x, size, numsprites, startsprites: integer;
  base, wall: PByteArray;
begin
  startsprites := CA_GetNamedNum('startdemand');
  numsprites := CA_GetNamedNum('enddemand') - startsprites;
  for i := 1 to numsprites - 1 do
    CA_FreeLump(startsprites + i);
  UpdateWait;
  DemandLoadMonster(CA_GetNamedNum(charnames[player.chartype]), 48);
  UpdateWait;
  if debugmode then
  begin
    for i := 0 to numwalls - 2 do
    begin
      wall := lumpmain[walllump + i + 1];
      base := @wall[65 * 2];
      size := wall[0] * 4;
      for x := 0 to 63 do
        wallposts[i * 64 + x] := @base[size * x];
    end;
    exit;
  end;
  UpdateWait;
  for i := 1 to numwalls - 8 do  // JVAL: SOS
    CA_FreeLump(walllump + i);
  UpdateWait;
  if wallposts <> nil then
    memfree(pointer(wallposts));
  memset(@textures, 0, SizeOf(textures));
  UpdateWait;
  for i := 0 to MAPCOLS * MAPROWS - 1 do
  begin
    textures[northwall[i]] := true;
    textures[westwall[i]] := true;
    textures[floordef[i]] := true;
    textures[ceilingdef[i]] := true;
  end;
  UpdateWait;
  textures[3] := true;    // for sides of doors

  if textures[228] or textures[229] or textures[230] then
  begin
    textures[228] := true;  // animation textures
    textures[229] := true;
    textures[230] := true;
  end;
  if textures[172] or textures[173] then
  begin
    textures[172] := true;  // case textures
    textures[173] := true;
  end;
  if textures[127] or textures[128] then
  begin
    textures[127] := true;
    textures[128] := true;
  end;
  if textures[75] or textures[76] then
  begin
    textures[75] := true;
    textures[76] := true;
  end;
  if textures[140] or textures[141] then
  begin
   textures[140] := true;
   textures[141] := true;
  end;
  if textures[234] or textures[235] then
  begin
    textures[234] := true;
    textures[235] := true;
  end;

  UpdateWait;
  for i := 1 to numwalls - 1 do
    if textures[i] then
    begin
      CA_CacheLump(walllump + i);
      UpdateWait;
    end;
  wallposts := malloc((numwalls + 1) * 64 * 4);
  UpdateWait;

  for i :=  0 to numwalls - 2 do
  begin
    wall := lumpmain[walllump + i + 1];
    if wall <> nil then
    begin
      base := @wall[65 * 2];
      size := wall[0] * 4;
      for x := 0 to 63 do
        wallposts[i * 64 + x] := @base[size * x];
    end;
  end;

  UpdateWait;
  for i := 1 to numflats - 1 do
    CA_FreeLump(flatlump + i);
  UpdateWait;
  memset(@textures, 0, SizeOf(textures));
  UpdateWait;
  for i := 0 to MAPCOLS * MAPROWS - 1 do
  begin
    textures[floorpic[i]] := true;
    textures[ceilingpic[i]] := true;
  end;
  UpdateWait;
  if textures[57] or textures[58] or textures[59] then
  begin
    textures[57] := true;  // animation textures
    textures[58] := true;
    textures[59] := true;
  end;
  if textures[217] or textures[218] or textures[219] then
  begin
    textures[217] := true;  // animation textures
    textures[218] := true;
    textures[219] := true;
  end;
  textures[133] := true;
  textures[134] := true;
  textures[135] := true;
  for i := 1 to numflats - 1 do
//  if (textures[i]) // JVAL ?
  begin
    CA_CacheLump(flatlump + i);
    UpdateWait;
  end;
end;


procedure LoadNewMap(const lump: integer);
var
  i, j: integer;
  f: file;
  fname: string;
begin
  StartWait;
  for i := 0 to S_END - S_START do
    slumps[i] := CA_GetNamedNum(slumpnames[i]);
  UpdateWait;
  goalitem := -1;
  oldgoalitem := -1;
  togglegoalitem := true;
  RF_ClearWorld;
  UpdateWait;
  if MS_CheckParm('file') = 0 then
  begin
    seek(cachehandle, infotable[lump].filepos);
    UpdateWait;
    fread(@northwall, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@northflags, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@westwall, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@westflags, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@floorpic, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@floorflags, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@ceilingpic, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@ceilingflags, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@floorheight, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@ceilingheight, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@floordef, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@floordefflags, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@ceilingdef, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@ceilingdefflags, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@maplights, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@mapeffects, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@mapsprites, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
    fread(@mapslopes, MAPROWS * MAPCOLS, 1, cachehandle);
    UpdateWait;
  end
  else
  begin
    fname := CA_LumpName(lump);
    if not fopen(f, fname, fOpenReadOnly)then
      MS_Error('LoadNewMap(): Can''t open %s!', [fname]);
    UpdateWait;
    fread(@northwall, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@northflags, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@westwall, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@westflags, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@floorpic, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@floorflags, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@ceilingpic, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@ceilingflags, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@floorheight, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@ceilingheight, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@floordef, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@floordefflags, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@ceilingdef, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@ceilingdefflags, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@maplights, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@mapeffects, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@mapsprites, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    fread(@mapslopes, MAPROWS * MAPCOLS, 1, f);
    UpdateWait;
    close(f);
  end;
  memset(@mapflags, 0, SizeOf(mapflags));
  UpdateWait;
  for i := 0 to MAPCOLS - 1 do
    for j := 0 to MAPROWS - 1 do
    begin
      if floordef[i * 64 + j] = 0 then floordef[i * 64 + j] := 56;
      if ceilingdef[i * 64 + j] = 0 then ceilingdef[i * 64 + j] := 56;
    end;
  UpdateWait;
  ActivateSlopes;
  UpdateWait;
  LoadTextures;
end;

var
  weaponlump: integer = 0;
  numweaponlumps: integer = 0;
 
procedure loadweapon(const n: integer);
var
  i: integer;
begin
  if weaponlump <> 0 then
    for i := 0 to numweaponlumps - 1 do
      CA_FreeLump(weaponlump + i);
  weapons[n].charge := 100;
  weapons[n].chargetime := timecount + weapons[n].chargerate;
  case n of
  1:
    begin
      i := CA_GetNamedNum('gun2');
      weaponlump := i;
      numweaponlumps := 3;
      if netmode then NetGetData;
      weaponpic[0] := CA_CacheLump(i);
      if netmode then NetGetData;
      weaponpic[1] := CA_CacheLump(i + 1);
      if netmode then NetGetData;
      weaponpic[2] := CA_CacheLump(i + 2);
    end;
  2:
    begin
      i := CA_GetNamedNum('gun3');
      weaponlump := i;
      numweaponlumps := 4;
      weaponpic[0] := CA_CacheLump(i);
      if netmode then NetGetData;
      weaponpic[1] := CA_CacheLump(i + 1);
      if netmode then NetGetData;
      weaponpic[2] := CA_CacheLump(i + 2);
      if netmode then NetGetData;
      weaponpic[3] := CA_CacheLump(i + 3);
      if netmode then NetGetData;
    end;
  3:
    begin
      i := CA_GetNamedNum('gun4');
      weaponlump := i;
      numweaponlumps := 4;
      weaponpic[0] := CA_CacheLump(i);
      if netmode then NetGetData;
      weaponpic[1] := CA_CacheLump(i + 1);
      if netmode then NetGetData;
      weaponpic[2] := CA_CacheLump(i + 2);
      if netmode then NetGetData;
      weaponpic[3] := CA_CacheLump(i + 3);
      if netmode then NetGetData;
    end;
  4:
    begin
      i := CA_GetNamedNum('gun5');
      weaponlump := i;
      numweaponlumps := 4;
      weaponpic[0] := CA_CacheLump(i);
      if netmode then NetGetData;
      weaponpic[1] := CA_CacheLump(i + 1);
      if netmode then NetGetData;
      weaponpic[2] := CA_CacheLump(i + 2);
      if netmode then NetGetData;
      weaponpic[3] := CA_CacheLump(i + 3);
      if netmode then NetGetData;
    end;
  7:
    begin
      i := CA_GetNamedNum('gunsquar');
      weaponlump := i;
      numweaponlumps := 3;
      weaponpic[0] := CA_CacheLump(i);
      if netmode then NetGetData;
      weaponpic[1] := CA_CacheLump(i + 1);
      if netmode then NetGetData;
      weaponpic[2] := CA_CacheLump(i + 2);
      if netmode then NetGetData;
    end;
  8:
    begin
      i := CA_GetNamedNum('gunknife');
      weaponlump := i;
      numweaponlumps := 4;
      weaponpic[0] := CA_CacheLump(i);
      if netmode then NetGetData;
      weaponpic[1] := CA_CacheLump(i + 1);
      if netmode then NetGetData;
      weaponpic[2] := CA_CacheLump(i + 2);
      if netmode then NetGetData;
      weaponpic[3] := CA_CacheLump(i + 3);
      if netmode then NetGetData;
    end;
  9:
    begin
      i := CA_GetNamedNum('guncross');
      weaponlump := i;
      numweaponlumps := 3;
      weaponpic[0] := CA_CacheLump(i);
      if netmode then NetGetData;
      weaponpic[1] := CA_CacheLump(i + 1);
      if netmode then NetGetData;
      weaponpic[2] := CA_CacheLump(i + 2);
      if netmode then NetGetData;
    end;
  10:
    begin
      i := CA_GetNamedNum('gunspec7');
      weaponlump := i;
      numweaponlumps := 4;
      weaponpic[0] := CA_CacheLump(i);
      if netmode then NetGetData;
      weaponpic[1] := CA_CacheLump(i + 1);
      if netmode then NetGetData;
      weaponpic[2] := CA_CacheLump(i + 2);
      if netmode then NetGetData;
      weaponpic[3] := CA_CacheLump(i + 3);
      if netmode then NetGetData;
    end;
  11:
    begin
      i := CA_GetNamedNum('gunmoo');
      weaponlump := i;
      numweaponlumps := 3;
      weaponpic[0] := CA_CacheLump(i);
      if netmode then NetGetData;
      weaponpic[1] := CA_CacheLump(i + 1);
      if netmode then NetGetData;
      weaponpic[2] := CA_CacheLump(i + 2);
      if netmode then NetGetData;
    end;
  12:
    begin
      i := CA_GetNamedNum('gunprong');
      weaponlump := i;
      numweaponlumps := 3;
      weaponpic[0] := CA_CacheLump(i);
      if netmode then NetGetData;
      weaponpic[1] := CA_CacheLump(i + 1);
      if netmode then NetGetData;
      weaponpic[2] := CA_CacheLump(i + 2);
      if netmode then NetGetData;
    end;
  13:
    begin
      i := CA_GetNamedNum('catlprod');
      weaponlump := i;
      numweaponlumps := 3;
      weaponpic[0] := CA_CacheLump(i);
      if netmode then NetGetData;
      weaponpic[1] := CA_CacheLump(i + 1);
      if netmode then NetGetData;
      weaponpic[2] := CA_CacheLump(i + 2);
      if netmode then NetGetData;
    end;
  14:
    begin
      i := CA_GetNamedNum('s7weapon');
      weaponlump := i;
      numweaponlumps := 3;
      weaponpic[0] := CA_CacheLump(i);
      if netmode then NetGetData;
      weaponpic[1] := CA_CacheLump(i + 1);
      if netmode then NetGetData;
      weaponpic[2] := CA_CacheLump(i + 2);
      if netmode then NetGetData;
    end;
  15:
    begin
      i := CA_GetNamedNum('domknife');
      weaponlump := i;
      numweaponlumps := 3;
      weaponpic[0] := CA_CacheLump(i);
      if netmode then NetGetData;
      weaponpic[1] := CA_CacheLump(i + 1);
      if netmode then NetGetData;
      weaponpic[2] := CA_CacheLump(i + 2);
      if netmode then NetGetData;
    end;
  16:
    begin
      i := CA_GetNamedNum('redgun');
      weaponlump := i;
      numweaponlumps := 2;
      weaponpic[0] := CA_CacheLump(i);
      if netmode then NetGetData;
      weaponpic[1] := CA_CacheLump(i + 1);
      if netmode then NetGetData;
    end;
  17:
    begin
      i := CA_GetNamedNum('bluegun');
      weaponlump := i;
      numweaponlumps := 3;
      weaponpic[0] := CA_CacheLump(i);
      if netmode then NetGetData;
      weaponpic[1] := CA_CacheLump(i + 1);
      if netmode then NetGetData;
      weaponpic[2] := CA_CacheLump(i + 2);
      if netmode then NetGetData;
    end;
  18:
    begin
      i := CA_GetNamedNum('greengun');
      weaponlump := i;
      numweaponlumps := 5;
      weaponpic[0] := CA_CacheLump(i);
      if netmode then NetGetData;
      weaponpic[1] := CA_CacheLump(i + 1);
      if netmode then NetGetData;
      weaponpic[2] := CA_CacheLump(i + 2);
      if netmode then NetGetData;
      weaponpic[3] := CA_CacheLump(i + 3);
      if netmode then NetGetData;
      weaponpic[4] := CA_CacheLump(i + 4);
      if netmode then NetGetData;
    end;
  end;
end;


// this must be updated if the scalepost or scalemaskedpost are changed
// the increment is size of each replicated asm block
// the offset is the location of the line to draw the pixel
//
// *note: runtime change of code !!
procedure ResetScalePostWidth(const NewWindowWidth: integer);
begin
end;


procedure ChangeViewSize(const MakeLarger: boolean);
var
  lastviewsize: integer;
begin
  resizeScreen := false;
  if SC.vrhelmet = 1 then
  begin
    if MakeLarger and (viewSizes[(currentViewSize + 1) * 2] <> 320) then
      exit
    else if not MakeLarger and (viewSizes[(currentViewSize - 1) * 2] <> 320) then
      exit;
  end;
  lastviewsize := currentViewSize;
  if MakeLarger then
  begin
    if currentViewSize < MAXVIEWSIZE - 1 then
      inc(currentViewSize)
    else
      exit;
  end
  else
  begin
    if currentViewSize > 0 then
      dec(currentViewSize)
    else
      exit;
  end;
  if (viewSizes[currentViewSize * 2] <> viewSizes[lastviewsize * 2]) or
     (viewSizes[currentViewSize * 2 + 1] <> viewSizes[lastviewsize * 2 + 1]) then
  begin
    windowWidth := viewSizes[currentViewSize * 2];
    windowHeight := viewSizes[currentViewSize * 2 + 1];
    windowLeft := viewLoc[currentViewSize * 2];
    windowTop := viewLoc[currentViewSize * 2 + 1];
    windowSize := windowHeight * windowWidth;
    viewLocation := @screen[windowTop * 320 + windowLeft];
    SetViewSize(windowWidth, windowHeight);
    ResetScalePostWidth(windowWidth);
    InitWalls;
  end;
  resetdisplay;
  player.scrollmin := scrollmin;
  player.scrollmax := scrollmax;
end;


procedure SaveGame(const n: integer);
var
  sprite_p: Pscaleobj_t;
  f: file;
  fname: string;
  door_p, last_p: Pdoorobj_t;
  i, mapspot: integer;
  sa: Pspawnarea_t;
  elev_p: Pelevobj_t;
begin
  StartWait;
  memset(@player.savesprites, 0, SizeOf(player.savesprites));
  memcpy(@player.westwall, @westwall, SizeOf(westwall));
  memcpy(@player.northwall, @northwall, SizeOf(northwall));

  UpdateWait;
  // sprites
  sprite_p := firstscaleobj.next;
  while sprite_p <> @lastscaleobj do
  begin
    mapspot := (sprite_p.y div FRACTILEUNIT) * MAPCOLS + (sprite_p.x div FRACTILEUNIT);
    case sprite_p.typ of
    S_MONSTER1:
	    begin
        if sprite_p.deathevent = 0 then
		    begin
          if sprite_p.hitpoints <> 0 then
          begin
            if sprite_p.nofalling then
              player.savesprites[mapspot] := S_MONSTER1_NS
            else
              player.savesprites[mapspot] := S_MONSTER1;
          end
          else
            player.savesprites[mapspot] := S_DEADMONSTER1;
        end;
      end;

    S_MONSTER2:
	    begin
        if sprite_p.deathevent = 0 then
	      begin
          if sprite_p.hitpoints <> 0 then
          begin
            if sprite_p.nofalling then
              player.savesprites[mapspot] := S_MONSTER2_NS
            else
              player.savesprites[mapspot] := S_MONSTER2;
          end;
        end;
      end;

    S_MONSTER3:
	    begin
        if sprite_p.deathevent = 0 then
        begin
          if sprite_p.hitpoints <> 0 then
          begin
            if sprite_p.nofalling then
              player.savesprites[mapspot] := S_MONSTER3_NS
            else
              player.savesprites[mapspot] := S_MONSTER3;
          end
          else
            player.savesprites[mapspot] := S_DEADMONSTER3;
        end;
      end;

    S_MONSTER4:
	    begin
        if sprite_p.deathevent = 0 then
        begin
          if sprite_p.hitpoints <> 0 then
          begin
            if sprite_p.nofalling then
              player.savesprites[mapspot] := S_MONSTER4_NS
            else
              player.savesprites[mapspot] := S_MONSTER4;
          end
          else
            player.savesprites[mapspot] := S_DEADMONSTER4;
        end;
      end;

    S_MONSTER5:
	    begin
        if sprite_p.deathevent = 0 then
        begin
          if sprite_p.hitpoints <> 0 then
            player.savesprites[mapspot] := S_MONSTER5
          else
            player.savesprites[mapspot] := S_DEADMONSTER5;
        end;
      end;

    S_MONSTER6:
	    begin
        if sprite_p.deathevent = 0 then
        begin
          if sprite_p.hitpoints <> 0 then
          begin
            if sprite_p.nofalling then
              player.savesprites[mapspot] := S_MONSTER6_NS
            else
              player.savesprites[mapspot] := S_MONSTER6;
          end
          else
            player.savesprites[mapspot] := S_DEADMONSTER6;
        end;
      end;

    S_MONSTER7:
	    begin
        if sprite_p.deathevent = 0 then
        begin
          if sprite_p.hitpoints <> 0 then
          begin
            if sprite_p.nofalling then
              player.savesprites[mapspot] := S_MONSTER7_NS
            else
              player.savesprites[mapspot] := S_MONSTER7;
          end
          else
            player.savesprites[mapspot] := S_DEADMONSTER7;
        end;
      end;

    S_MONSTER8:
	    begin
        if sprite_p.deathevent = 0 then
        begin
          if sprite_p.hitpoints <> 0 then
          begin
            if sprite_p.nofalling then
              player.savesprites[mapspot] := S_MONSTER8_NS
            else
              player.savesprites[mapspot] := S_MONSTER8;
          end
          else
            player.savesprites[mapspot] := S_DEADMONSTER8;
        end;
      end;

    S_MONSTER9:
	    begin
        if sprite_p.deathevent = 0 then
        begin
          if sprite_p.hitpoints <> 0 then
          begin
            if sprite_p.nofalling then
              player.savesprites[mapspot] := S_MONSTER9_NS
            else
              player.savesprites[mapspot] := S_MONSTER9;
          end
          else
            player.savesprites[mapspot] := S_DEADMONSTER9;
        end;
      end;

    S_MONSTER10:
	    begin
        if sprite_p.deathevent = 0 then
        begin
          if sprite_p.hitpoints <> 0 then
          begin
            if sprite_p.nofalling then
              player.savesprites[mapspot] := S_MONSTER10_NS
            else
              player.savesprites[mapspot] := S_MONSTER10;
          end
          else
            player.savesprites[mapspot] := S_DEADMONSTER10;
        end;
      end;

    S_MONSTER11:
	    begin
        if sprite_p.deathevent = 0 then
        begin
          if sprite_p.hitpoints <> 0 then
          begin
            if sprite_p.nofalling then
              player.savesprites[mapspot] := S_MONSTER11_NS
            else
              player.savesprites[mapspot] := S_MONSTER11;
          end
          else
            player.savesprites[mapspot] := S_DEADMONSTER11;
        end;
      end;

    S_MONSTER12:
	    begin
        if sprite_p.deathevent = 0 then
        begin
          if sprite_p.hitpoints <> 0 then
          begin
            if sprite_p.nofalling then
              player.savesprites[mapspot] := S_MONSTER12_NS
            else
              player.savesprites[mapspot] := S_MONSTER12;
          end
          else
            player.savesprites[mapspot] := S_DEADMONSTER12;
        end;
      end;

    S_MONSTER13:
	    begin
        if sprite_p.deathevent = 0 then
        begin
          if sprite_p.hitpoints <> 0 then
          begin
            if sprite_p.nofalling then
              player.savesprites[mapspot] := S_MONSTER13_NS
            else
              player.savesprites[mapspot] := S_MONSTER13;
          end
          else
            player.savesprites[mapspot] := S_DEADMONSTER13;
        end;
      end;

    S_MONSTER14:
	    begin
        if sprite_p.deathevent = 0 then
        begin
          if sprite_p.hitpoints <> 0 then
          begin
            if sprite_p.nofalling then
              player.savesprites[mapspot] := S_MONSTER14_NS
            else
              player.savesprites[mapspot] := S_MONSTER14;
          end
          else
            player.savesprites[mapspot] := S_DEADMONSTER14;
        end;
      end;

    S_MONSTER15:
	    begin
        if sprite_p.deathevent = 0 then
        begin
          if sprite_p.hitpoints <> 0 then
          begin
            if sprite_p.nofalling then
              player.savesprites[mapspot] := S_MONSTER15_NS
            else
              player.savesprites[mapspot] := S_MONSTER15;
          end
          else
            player.savesprites[mapspot] := S_DEADMONSTER15;
        end;
      end;

    S_DEADMONSTER1,
    S_DEADMONSTER2,
    S_DEADMONSTER3,
    S_DEADMONSTER4,
    S_DEADMONSTER5,
    S_DEADMONSTER6,
    S_DEADMONSTER7,
    S_DEADMONSTER8,
    S_DEADMONSTER9,
    S_DEADMONSTER10,
    S_DEADMONSTER11,
    S_DEADMONSTER12,
    S_DEADMONSTER13,
    S_DEADMONSTER14,
    S_DEADMONSTER15,
    S_AMMOBOX,
    S_MEDBOX,
    S_GOODIEBOX,
    S_PROXMINE,
    S_TIMEMINE,
    S_PRIMARY1,
    S_PRIMARY2,
    S_SECONDARY1,
    S_SECONDARY2,
    S_SECONDARY3,
    S_SECONDARY4,
    S_SECONDARY5,
    S_SECONDARY6,
    S_SECONDARY7,
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
    S_WEAPON18,
    S_ITEM1,
    S_ITEM2,
    S_ITEM3,
    S_ITEM4,
    S_ITEM5,
    S_ITEM6,
    S_ITEM7,
    S_ITEM8,
    S_ITEM9,
    S_ITEM10,
    S_ITEM11,
    S_ITEM12,
    S_ITEM13,
    S_ITEM14,
    S_ITEM15,
    S_ITEM16,
    S_ITEM17,
    S_ITEM18,
    S_ITEM19,
    S_ITEM20,
    S_ITEM21,
    S_ITEM22,
    S_ITEM23,
    S_ITEM24,
    S_ITEM25:
      player.savesprites[mapspot] := sprite_p.typ;
    end;
    sprite_p := sprite_p.next;
  end;

  UpdateWait;

  // map triggers
  for i := 0 to MAPCOLS * MAPROWS - 1 do  // remember warps
  begin
    case mapsprites[i] of
    SM_WARP1,
    SM_WARP2,
    SM_WARP3:
      player.savesprites[i] := mapsprites[i];
    SM_SWITCHDOWN:
     player.savesprites[i] := S_TRIGGER1;
    SM_SWITCHDOWN2:
     player.savesprites[i] := S_TRIGGER2;
    SM_SWAPSWITCH:
     player.savesprites[i] := S_SWAPSWITCH;
    SM_STRIGGER:
     player.savesprites[i] := S_STRIGGER;
    SM_EXIT:
     player.savesprites[i] := S_EXIT;
//    SM_HOLE:
//     player.savesprites[i] := S_HOLE;
//     break;
    end;
  end;

  UpdateWait;

  (* doors *)
  last_p := @doorlist[numdoors];
  door_p := @doorlist[0];
  while door_p <> last_p do
  begin
    if door_p.pic = CA_GetNamedNum('door_1') - walllump then
    begin
      if (door_p.orientation = dr_vertical) or (door_p.orientation = dr_vertical2) then
        player.savesprites[door_p.tiley * MAPCOLS + door_p.tilex] := S_VDOOR1
      else
        player.savesprites[door_p.tiley * MAPCOLS + door_p.tilex] := S_HDOOR1;
    end
    else if door_p.pic = CA_GetNamedNum('door_2') - walllump then
    begin
      if (door_p.orientation = dr_vertical) or (door_p.orientation = dr_vertical2) then
        player.savesprites[door_p.tiley * MAPCOLS + door_p.tilex] := S_VDOOR2
      else
        player.savesprites[door_p.tiley * MAPCOLS + door_p.tilex] := S_HDOOR2;
    end
    else if door_p.pic = CA_GetNamedNum('door_3') - walllump then
    begin
      if (door_p.orientation = dr_vertical) or (door_p.orientation = dr_vertical2) then
        player.savesprites[door_p.tiley * MAPCOLS + door_p.tilex] := S_VDOOR3
      else
        player.savesprites[door_p.tiley * MAPCOLS + door_p.tilex] := S_HDOOR3;
    end
    else if door_p.pic = CA_GetNamedNum('door_4') - walllump then
    begin
      if (door_p.orientation = dr_vertical) or (door_p.orientation = dr_vertical2) then
        player.savesprites[door_p.tiley * MAPCOLS + door_p.tilex] := S_VDOOR4
      else
        player.savesprites[door_p.tiley * MAPCOLS + door_p.tilex] := S_HDOOR4;
    end
    else if door_p.pic = CA_GetNamedNum('door_5') - walllump then
    begin
      if (door_p.orientation = dr_vertical) or (door_p.orientation = dr_vertical2) then
        player.savesprites[door_p.tiley * MAPCOLS + door_p.tilex] := S_VDOOR5
      else
        player.savesprites[door_p.tiley * MAPCOLS + door_p.tilex] := S_HDOOR5;
    end
    else if door_p.pic = CA_GetNamedNum('door_6') - walllump then
    begin
      if (door_p.orientation = dr_vertical) or (door_p.orientation = dr_vertical2) then
        player.savesprites[door_p.tiley * MAPCOLS + door_p.tilex] := S_VDOOR6
      else
        player.savesprites[door_p.tiley * MAPCOLS + door_p.tilex] := S_HDOOR6;
    end
    else if door_p.pic = CA_GetNamedNum('door_7') - walllump then
    begin
      if (door_p.orientation = dr_vertical) or (door_p.orientation = dr_vertical2) then
        player.savesprites[door_p.tiley * MAPCOLS + door_p.tilex] := S_VDOOR7
      else
        player.savesprites[door_p.tiley * MAPCOLS + door_p.tilex] := S_HDOOR7;
    end;
	  inc(door_p);
  end;

  UpdateWait;

  (* spawning areas / generators *)
  sa := @spawnareas[0];
  for i := 0 to numspawnareas - 1 do
  begin
    case sa.typ of
    0:
      player.savesprites[sa.mapspot] := S_GENERATOR1;
    1:
      player.savesprites[sa.mapspot] := S_GENERATOR2;
    10:
      player.savesprites[sa.mapspot] := S_SPAWN1;
    11:
      player.savesprites[sa.mapspot] := S_SPAWN2;
    12:
      player.savesprites[sa.mapspot] := S_SPAWN3;
    13:
      player.savesprites[sa.mapspot] := S_SPAWN4;
    14:
      player.savesprites[sa.mapspot] := S_SPAWN5;
    15:
      player.savesprites[sa.mapspot] := S_SPAWN6;
    16:
      player.savesprites[sa.mapspot] := S_SPAWN7;
    17:
      player.savesprites[sa.mapspot] := S_SPAWN8;
    18:
      player.savesprites[sa.mapspot] := S_SPAWN9;
    19:
      player.savesprites[sa.mapspot] := S_SPAWN10;
    20:
      player.savesprites[sa.mapspot] := S_SPAWN11;
    21:
      player.savesprites[sa.mapspot] := S_SPAWN12;
    22:
      player.savesprites[sa.mapspot] := S_SPAWN13;
    23:
      player.savesprites[sa.mapspot] := S_SPAWN14;
    24:
      player.savesprites[sa.mapspot] := S_SPAWN15;
    100:
      player.savesprites[sa.mapspot] := S_SPAWN8_NS;
    101:
      player.savesprites[sa.mapspot] := S_SPAWN9_NS;
	  end;
	  inc(sa);
  end;

  UpdateWait;

  // elevators
  elev_p := firstelevobj.next;
  while elev_p <> @lastelevobj do
  begin
    case elev_p.typ of
    E_NORMAL:
      begin
        if elev_p.nosave = 0 then
        begin
          if elev_p.elevTimer = $70000000 then
            player.savesprites[elev_p.mapspot] := S_PAUSEDELEVATOR
          else
            player.savesprites[elev_p.mapspot] := S_ELEVATOR;
        end;
      end;

    E_TIMED:
      begin
        case elev_p.elevTimer of
        12600:
          player.savesprites[elev_p.mapspot] := S_ELEVATOR3M;
        25200:
          player.savesprites[elev_p.mapspot] := S_ELEVATOR6M;
        63000:
          player.savesprites[elev_p.mapspot] := S_ELEVATOR15M;
        end;
      end;

    E_SWITCHDOWN:
      player.savesprites[elev_p.mapspot] := S_TRIGGERD1;

    E_SWITCHDOWN2:
      player.savesprites[elev_p.mapspot] := S_TRIGGERD2;

    E_SECRET:
      player.savesprites[elev_p.mapspot] := S_SDOOR;

    E_SWAP:
      begin
        if ((elev_p.position = elev_p.floor) and not elev_p.elevUp) or (elev_p.elevDown) then
          player.savesprites[elev_p.mapspot] := S_ELEVATORLOW
        else if ((elev_p.position = elev_p.ceiling) and not elev_p.elevDown) or elev_p.elevUp then
          player.savesprites[elev_p.mapspot] := S_ELEVATORHIGH;
      end;
    end;
    elev_p := elev_p.next;
  end;

  UpdateWait;

  sprintf(fname, SAVENAME, [n]);
  if not fopen(f, fname, fCreate) then
    MS_Error('SaveGame(): File Open Error: %s', [fname]);
  UpdateWait;
  if not fwrite(@player, SizeOf(player_t), 1, f) then
    MS_Error('SaveGame(): File Write Error: %s', [fname]);
  UpdateWait;
  close(f);
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
  inventorydelay := 0;
  usedelay := 0;
  jumpdelay := 0;
  frames := 0;
  keyboardDelay := 0;
  spritemovetime := 0;
  wallanimationtime := 0;
  timemsg := 0;
  RearViewTime := 0;
  RearViewDelay := 0;
  netsendtime := 0;
  SwitchTime := 0;
  inventorytime := 0;
  nethurtsoundtime := 0;
  midgetmode := false;
  fxtimecount := 0;
  ResetMouse;
end;


procedure selectsong(const asongmap: integer);
var
  sname: string;
  pattern: integer;
  songmap: integer;
begin
  if DEMO then
    songmap := asongmap mod 5
  else
    songmap := asongmap;
  case songmap of
  0:
    begin
      pattern := 0;
      sname := 'SONG0.S3M';
    end;
  1:
    begin
      pattern := 20;
      sname := 'SONG0.S3M';
    end;
  2:
    begin
      pattern := 37;
      sname := 'SONG0.S3M';
    end;
  3:
    begin
      pattern := 54;
      sname := 'SONG0.S3M';
    end;
  4:
    begin
      pattern := 73;
      sname := 'SONG0.S3M';
    end;

  5:
    begin
      pattern := 0;
      sname := 'SONG2.S3M';
    end;
  6:
    begin
      pattern := 26;
      sname := 'SONG2.S3M';
    end;
  7:
    begin
      pattern := 46;
      sname := 'SONG2.S3M';
    end;
  8:
    begin
      pattern := 64;
      sname := 'SONG2.S3M';
    end;
  9:
    begin
      pattern := 83;
      sname := 'SONG2.S3M';
    end;

  10:
    begin
      pattern := 0;
      sname := 'SONG3.S3M';
    end;
  11:
    begin
      pattern := 39;
      sname := 'SONG3.S3M';
    end;
  12:
    begin
      pattern := 58;
      sname := 'SONG3.S3M';
    end;
  13:
    begin
      pattern := 78;
      sname := 'SONG3.S3M';
    end;
  14:
    begin
      pattern := 94;
      sname := 'SONG3.S3M';
    end;

  15:
    begin
      pattern := 0;
      sname := 'SONG1.S3M';
    end;
  16:
    begin
      pattern := 24;
      sname := 'SONG1.S3M';
    end;
  17:
    begin
      pattern := 45;
      sname := 'SONG1.S3M';
    end;

  18:
    begin
      pattern := 0;
      sname := 'SONG4.S3M';
    end;
  19:
    begin
      pattern := 10;
      sname := 'SONG4.S3M';
    end;
  20:
    begin
      pattern := 21;
      sname := 'SONG4.S3M';
    end;
  21:
    begin
      pattern := 0;
      sname := 'SONG8.MOD';
    end;

  22:
    begin
      if netmode then
      begin
        pattern := 0;
        sname := 'SONG14.MOD';
      end
      else
      begin
        pattern := 0;
        sname := 'ENDING.MOD';
      end;
    end;

  23:
    begin
      pattern := 0;
      sname := 'SONG5.MOD';
    end;
  24:
    begin
      pattern := 0;
      sname := 'SONG6.MOD';
    end;
  25:
    begin
      pattern := 0;
      sname := 'SONG7.MOD';
    end;
  26:
    begin
      pattern := 33;
      sname := 'SONG4.S3M';
    end;
  27:
    begin
      pattern := 0;
      sname := 'SONG9.MOD';
    end;
  28:
    begin
      pattern := 0;
      sname := 'SONG10.MOD';
    end;
  29:
    begin
      pattern := 0;
      sname := 'SONG11.MOD';
    end;
  30:
    begin
      pattern := 0;
      sname := 'SONG12.MOD';
    end;
  31:
    begin
      pattern := 0;
      sname := 'SONG13.MOD';
    end;

  99:
    begin
      pattern := 0;
      sname := 'PROBE.MOD';
    end;

  else
    pattern := 0;
    sname := 'SONG0.S3M';
  end;

  PlaySong(sname, pattern);
end;


procedure EndGame1;
var
  name: string;
  c: char;
label
  endgame1exit;
begin
  selectsong(22);

  c := Chr(cdr_drivenum + Ord('A'));
  if CDROMGREEDDIR then
  begin
    name := c + ':\GREED\MOVIES\PRISON1.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\GREED\MOVIES\TEMPLE1.FLI';
    DoPlayFLI(name, 0);
  end
  else
  begin
    name := c + ':\MOVIES\PRISON1.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\MOVIES\TEMPLE1.FLI';
    DoPlayFLI(name, 0);
  end;

  VI_FillPalette(0, 0, 0);

  loadscreen('REDCHARS');
  VI_FadeIn(0, 256, @colors, 48);
  Wait(140, 1);
  fontbasecolor := 64;
  while fontbasecolor < 73 do
  begin
    printy := 80;
    FN_PrintCentered(
      'BY SUCCESSFULLY BRAVING THE DESARIAN'#13#10 +
      'PENAL COLONY YOU EMERGE VICTORIOUS'#13#10 +
      'WITH THE BRASS RING OF BYZANT IN HAND.'#13#10 +
      '...BUT IT''S NOT OVER YET, HUNTER.'#13#10 +
      'IT''S ON TO PHASE TWO OF THE HUNT, THE'#13#10 +
      'CITY TEMPLE OF RISTANAK.  ARE YOU'#13#10 +
      'PREPARED TO FACE THE Y''RKTARELIAN'#13#10 +
      'PRIESTHOOD AND THEIR PAGAN GOD?'#13#10 +
      'NOT BLOODY LIKELY...'#13#10#13#10#13#10#13#10#13#10#13#10 +
      'TO BE CONTINUED...'#13#10);
    inc(fontbasecolor);
  end;

  newascii := false;
  while true do
  begin
    Wait(10, 1);
    if newascii then
      break;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  memset(screen, 0, 64000);

  loadscreen('SOFTLOGO');
  VI_FadeIn(0, 256, @colors, 48);
  newascii := false;
  while true do
  begin
    Wait(10, 1);
    if newascii then
      break;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  memset(screen, 0, 64000);

  loadscreen('CREDITS1');
  VI_FadeIn(0, 256, @colors, 48);
  newascii := false;
  while true do
  begin
    Wait(10, 1);
    if newascii then
      break;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  memset(screen, 0, 64000);

  loadscreen('CREDITS2');
  VI_FadeIn(0, 256, @colors, 48);
  newascii := false;
  while true do
  begin
    Wait(10, 1);
    if newascii then
      break;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  memset(screen, 0, 64000);

  if not ASSASSINATOR then
  begin
    loadscreen('CREDITS3');
    VI_FadeIn(0, 256, @colors, 48);
    newascii := false;
    while true do
    begin
      Wait(10, 1);
      if newascii then
        break;
    end;
    VI_FadeOut(0, 256, 0, 0, 0, 48);
    memset(screen, 0, 64000);
  end;

endgame1exit:
  redo := true;
end;


procedure EndGame2;
var
  name: string;
  c: char;
begin
  selectsong(22);

  c := Chr(cdr_drivenum + Ord('A'));
  if CDROMGREEDDIR then
  begin
    name := c + ':\GREED\MOVIES\TEMPLE2.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\GREED\MOVIES\JUMPBAS1.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\GREED\MOVIES\JUMPBAS2.FLI';
    DoPlayFLI(name, 0);
  end
  else
  begin
    name := c + ':\MOVIES\TEMPLE2.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\MOVIES\JUMPBAS1.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\MOVIES\JUMPBAS2.FLI';
    DoPlayFLI(name, 0);
  end;


  VI_FillPalette(0, 0, 0);

  loadscreen('REDCHARS');
  VI_FadeIn(0, 256, @colors, 48);
  Wait(2 * TICRATE, 1);
  fontbasecolor := 64;
  while fontbasecolor < 73 do
  begin
    printy := 80;
    FN_PrintCentered(
      'WITH Y''RKTAREL DEAD AND THE PRIESTHOOD'#13#10 +
      'IN RUINS CONGRATULATE YOURSELF, HUNTER.'#13#10 +
      'YOU''VE ANNHILIATED YET ANOTHER CULTURE'#13#10 +
      'ALL FOR THE SAKE OF THE HUNT.'#13#10 +
      '...BUT DON''T RELAX YET, FOR IT''S ON TO'#13#10 +
      'PHASE THREE OF THE HUNT.  THIS TIME'#13#10 +
      'YOU''LL BATTLE AN ENTIRE ARMY AS YOU FACE'#13#10 +
      'OFF WITH LORD KAAL IN HIS SPACEBORN'#13#10 +
      'MOUNTAIN CITADEL.'#13#10 +
      'DO YOU HAVE WHAT IT TAKES TO SLAY LORD'#13#10 +
      'KAAL AND WREST FROM HIM THE IMPERIAL SIGIL?'#13#10#13#10#13#10#13#10#13#10#13#10 +
      'TO BE CONTINUED...'#13#10);
    inc(fontbasecolor);
  end;
  newascii := false;
  while true do
  begin
    Wait(10, 1);
    if newascii then
      break;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  memset(screen, 0, 64000);

  loadscreen('SOFTLOGO');
  VI_FadeIn(0, 256, @colors, 48);
  newascii := false;
  while true do
  begin
    Wait(10, 1);
    if newascii then
      break;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  memset(screen, 0, 64000);

  loadscreen('CREDITS1');
  VI_FadeIn(0, 256, @colors, 48);
  newascii := false;
  while true do
  begin
    Wait(10, 1);
    if newascii then
      break;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  memset(screen, 0, 64000);

  loadscreen('CREDITS2');
  VI_FadeIn(0, 256, @colors, 48);
  newascii := false;
  while true do
  begin
    Wait(10, 1);
    if newascii then
      break;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  memset(screen, 0, 64000);

  loadscreen('CREDITS3');
  VI_FadeIn(0, 256, @colors, 48);
  newascii := false;
  while true do
  begin
    Wait(10, 1);
    if newascii then
      break;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  memset(screen, 0, 64000);

  redo := true;
end;


procedure EndGame3;
var
  name: string;
  c: char;
begin
  c := Chr(cdr_drivenum + Ord('A'));
  if CDROMGREEDDIR then
  begin
    name := c + ':\GREED\MOVIES\JUMPBAS3.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\GREED\MOVIES\JUMPBAS4.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\GREED\MOVIES\JUMPBAS5.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\GREED\MOVIES\JUMPBAS6.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\GREED\MOVIES\JUMPBS6B.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\GREED\MOVIES\JUMPBAS7.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\GREED\MOVIES\JUMPBAS8.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\GREED\MOVIES\JUMPBAS9.FLI';
    DoPlayFLI(name, 0);
  end
  else
  begin
    name := c + ':\MOVIES\JUMPBAS3.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\MOVIES\JUMPBAS4.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\MOVIES\JUMPBAS5.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\MOVIES\JUMPBAS6.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\MOVIES\JUMPBS6B.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\MOVIES\JUMPBAS7.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\MOVIES\JUMPBAS8.FLI';
    DoPlayFLI(name, 0);
    name := c + ':\MOVIES\JUMPBAS9.FLI';
    DoPlayFLI(name, 0);
  end;

  VI_FillPalette(0, 0, 0);

  loadscreen('REDCHARS');
  VI_FadeIn(0, 256, @colors, 48);
  Wait(2 * TICRATE, 1);
  fontbasecolor := 64;
  while fontbasecolor < 73 do
  begin
    printy := 80;
    if GAME3 then
      FN_PrintCentered(
        'WELL, YOU SUCCESSFULLY PULLED DOWN THE LAST'#13#10 +
        'VESTIGES OF MILITARY AUTHORITY FOR THE SECTOR.'#13#10 +
        'YOU COULD HAVE RICHES, FAME AND POWER,'#13#10 +
        'AND YOUR CHOICE OF PLEASURE PLANETS.'#13#10 +
        'UNFORTUNATELY, YOU''RE STUCK ON A SHIP THAT''S'#13#10 +
        'DRIFTING THROUGH HYPERSPACE.  IN SHORT'#13#10 +
        'YOU''RE LOST.  LUCKY FOR THE PASSENGERS'#13#10 +
        'THAT YOU''RE A HEROIC HUNTER THAT CAN SAVE'#13#10 +
        'THEM FROM THEIR FATE IN THE CLUTCHES'#13#10 +
        'OF THE MAZDEEN EMPEROR.  OR CAN YOU?'#13#10#13#10#13#10#13#10#13#10#13#10 +
        'TO BE CONTINUED...'#13#10)
    else
      FN_PrintCentered(
        'WELL, YOU SUCCESSFULLY BRAVED A BLOODY RIOT, FACED'#13#10 +
        'A GOD AND SURVIVED, AND PULLED DOWN THE LAST'#13#10 +
        'VESTIGES OF MILITARY AUTHORITY FOR THE SECTOR.'#13#10 +
        'YOU COULD HAVE RICHES, FAME AND POWER,'#13#10 +
        'AND YOUR CHOICE OF PLEASURE PLANETS.'#13#10 +
        'UNFORTUNATELY, YOU''RE STUCK ON A SHIP THAT''S'#13#10 +
        'DRIFTING THROUGH HYPERSPACE.  IN SHORT'#13#10 +
        'YOU''RE LOST.  LUCKY FOR THE PASSENGERS'#13#10 +
        'THAT YOU''RE A HEROIC HUNTER THAT CAN SAVE'#13#10 +
        'THEM FROM THEIR FATE IN THE CLUTCHES'#13#10 +
        'OF THE MAZDEEN EMPEROR.  OR CAN YOU?'#13#10#13#10#13#10#13#10#13#10#13#10 +
        'TO BE CONTINUED...'#13#10);
    inc(fontbasecolor);
  end;
  newascii := false;
  while true do
  begin
    Wait(10, 1);
    if newascii then
      break;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  memset(screen, 0, 64000);

  loadscreen('SOFTLOGO');
  VI_FadeIn(0, 256, @colors, 48);
  newascii := false;
  while true do
  begin
    Wait(10, 1);
    if newascii then
      break;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  memset(screen, 0, 64000);

  loadscreen('CREDITS1');
  VI_FadeIn(0, 256, @colors, 48);
  newascii := false;
  while true do
  begin
    Wait(10, 1);
    if newascii then
      break;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  memset(screen, 0, 64000);

  loadscreen('CREDITS2');
  VI_FadeIn(0, 256, @colors, 48);
  newascii := false;
  while true do
  begin
    Wait(10, 1);
    if newascii then
      break;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  memset(screen, 0, 64000);

  loadscreen('CREDITS3');
  VI_FadeIn(0, 256, @colors, 48);
  newascii := false;
  while true do
  begin
    Wait(10, 1);
    if newascii then
      break;
  end;
  VI_FadeOut(0, 256, 0, 0, 0, 48);
  memset(screen, 0, 64000);

  redo := true;
end;


procedure newmap(const map: integer; const activate: integer);
var
  lump, i, n, songmap: integer;
  didend: boolean;
begin
  if activate <> 0 then
  begin
    memset(@player.westmap, 0, SizeOf(player.westmap));
    memset(@player.northmap, 0, SizeOf(player.northmap));
    memset(@player.events, 0, SizeOf(player.events));
    player.x := -1;
  end;
  player.map := map;
  songmap := map;
  if ((map <> 8) and (map <> 16)) or netmode then
    selectsong(songmap)
  else
    StopMusic;
  if activate = 1 then
    MissionBriefing(map);
  resetengine;
  lump := CA_GetNamedNum('map') + map + 1;
  if DEMO then
  begin
    if (map <> 3) or netmode then
    begin
      LoadNewMap(lump);
      if activate <> 0 then
      begin
        LoadScript(lump, true);
        ActivateSpritesFromMap;
      end
      else
        LoadScript(lump, false);
    end;
  end
  else
  begin
    didend := false;
    if GAME1 then
    begin
      if (map = 8) and not netmode then
      begin
        EndGame1;
        didend := true;
      end;
    end
    else if GAME2 then
    begin
      if (map = 16) and not netmode then
      begin
        EndGame2;
        didend := true;
      end;
    end
    else
    begin
      if (map = 22) and not netmode then
      begin
        EndGame3;
        didend := true;
      end;
    end;
    if not didend then
    begin
      LoadNewMap(lump);
      if activate <> 0 then
      begin
        LoadScript(lump, true);
        ActivateSpritesFromMap;
      end
      else
        LoadScript(lump, false);
    end;
  end;
  EndWait;
  for i := 0 to 4 do
    if player.weapons[i] <> -1 then
    begin
      n := player.weapons[i];
      weapons[n].charge := 100;
      weapons[n].chargetime := timecount + weapons[n].chargerate;
    end;
end;


procedure LoadGame(const n: integer);
var
  fname: string;
  i, oldscore: integer;
  handle: file;
begin
  sprintf(fname, SAVENAME, [n]);
  if not fopen(handle, fname, fOpenReadOnly) then
    exit;
  if not fread(@player, SizeOf(player_t), 1, handle) then
  begin
    close(handle);
    MS_Error('LoadGame(): Error loading %s!', [fname]);
  end;
  close(handle);
  oldscore := player.levelscore;

  resetengine;
  gameloaded := true;
  player.scrollmax := windowHeight + player.scrollmin;
  timecount := player.timecount;
  keyboardDelay := 0;
  BonusItem.time := timecount + 2100;
  wallanimationtime := player.timecount;
  spritemovetime := player.timecount;

  newmap(player.map, 0);
  memcpy(@mapsprites, @player.savesprites, SizeOf(mapsprites));
  ActivateSpritesFromMap;
  timecount := player.timecount;
  loadweapon(player.weapons[player.currentweapon]);
  player.levelscore := oldscore;
  memcpy(@westwall, @player.westwall, SizeOf(westwall));
  memcpy(@northwall, @player.northwall, SizeOf(northwall));
  eventloading := true;
  for i := 1 to 255 do
    if player.events[i] <> 0 then
      RunEvent(i, true);
  eventloading := false;
end;


procedure heal(const n: integer);
begin
  player.shield := player.shield + n;
  if player.shield > player.maxshield then
    player.shield := player.maxshield;
  hurtborder := true;
end;


procedure medpaks(const n: integer);
begin
  if player.angst <= 0 then
    exit;
  player.angst := player.angst + n;
  if player.angst > player.maxangst then
    player.angst := player.maxangst;
  hurtborder := true;
end;


procedure hurt(n: integer);
begin
  if godmode or (player.angst = 0) then
    exit;

  if specialeffect = SE_INVISIBILITY then
    n := n div 3;

  if specialeffect = SE_REVERSOPILL then
  begin
    medpaks(n div 2);
    heal(n div 2);
    exit;
  end;
  player.status := 1;
  if n > player.shield then
  begin
    n := n - player.shield;
    player.shield := 0;
    player.angst := player.angst - n;
    if player.angst < 0 then
      player.angst := 0;
  end
  else
    player.shield := player.shield - n;
  hurtborder := true;
  if player.angst = 0 then
  begin
    SoundEffect(SN_DEATH0 + player.chartype, 15, player.x, player.y);
    if netmode then
      NetSoundEffect(SN_DEATH0 + player.chartype, 15, player.x, player.y);
    SoundEffect(SN_DEATH0 + player.chartype, 15, player.x, player.y);
    if netmode then
      NetSoundEffect(SN_DEATH0 + player.chartype, 15, player.x, player.y);
  end
  else
  begin
    SoundEffect(SN_HIT0 + player.chartype, 15, player.x, player.y);
    if netmode and (timecount > nethurtsoundtime) then
    begin
      NetSoundEffect(SN_HIT0 + player.chartype, 15, player.x, player.y);
      nethurtsoundtime := timecount+35;
    end;
  end;
end;


procedure newplayer(const map: integer; chartype: integer; const difficulty: integer);
var
  parm: integer;
begin
  parm := MS_CheckParm('char');
  if (parm > 0) and (parm < my_argc - 1) then
  begin
    chartype := atoi(my_argv(parm + 1));
    if (chartype < 0) or (chartype >= MAXCHARTYPES) then
      MS_Error('Invalid Character Selection (%d)', [chartype]);
  end;

  gameloaded := true;
  memset(@player, 0, SizeOf(player));
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
  case chartype of
  0: // psyborg
    begin
      player.weapons[0] := 7;
      player.weapons[1] := 1;
    end;
  1: // lizard
    begin
      player.weapons[0] := 8;
      player.weapons[1] := 9;
    end;
  2: // mooman
    begin
      player.weapons[0] := 13;
      player.weapons[1] := 11;
    end;
  3: // specimen 7
    begin
      player.weapons[0] := 14;
      player.weapons[1] := 10;
    end;
  4: // trix
    begin
      player.weapons[0] := 15;
      player.weapons[1] := 12;
    end;
  5:
    begin
      player.weapons[0] := 8;
      player.weapons[1] := 9;
    end;
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
  newmap(player.map, 1);
  timecount := 0;
  keyboardDelay := 0;
  loadweapon(player.weapons[0]);
end;


procedure addscore(const n: integer);
begin
  player.score := player.score + n;
  if player.score > 2000000000 then
    player.score := 0;
  player.levelscore := player.levelscore - n;
  if player.levelscore < 0 then
    player.levelscore := 0;
end;


procedure respawnplayer;
var
  mapspot: integer;
  x, y, n: integer;
begin
  repeat
    n := (clock + MS_RndT) mod MAXSTARTLOCATIONS;
    x := startlocations[n][0];
    y := startlocations[n][1];
    mapspot := y * MAPCOLS + x;
  until mapsprites[mapspot] <= 0;
  player.x := (x * FRACTILEUNIT) + (32 * FRACUNIT);
  player.y := (y * FRACTILEUNIT) + (32 * FRACUNIT);
  player.z := RF_GetFloorZ(player.x, player.y) + player.height;
  player.angle := NORTH;
  NetNewPlayerData;
end;


procedure MissionBriefing(const map: integer);
var
  pprimaries, psecondaries, i, tprimaries, tsecondaries, oldtimecount: integer;
  str, name: string;
  scr: PByteArray;
  c: char;
label
  finale;
begin
  if netmode or nointro then
    exit;

  scr := malloc(64000);
  if scr = nil then
    MS_Error('Error allocating MissonBriefing buffer');

  memcpy(scr, @viewbuffer, 64000);

  oldtimecount := timecount;

  INT_TimerHook(nil);
  font := font1;

  if map = 0 then
  begin
    VI_FillPalette(0, 0, 0);

    if not DEMO then
    begin
      loadscreen('BRIEF3');
      VI_BlitView;
      VI_FadeIn(0, 256, @colors, 64);
      Wait(TICRATE);
      newascii := false;
      fontbasecolor := 0;
      while fontbasecolor < 9 do
      begin
        printy := 149;
        FN_PrintCentered(
          'WELCOME ABOARD HUNTER.'#13#10 +
          'DUE TO INCREASED FUNDING FROM THE AVC YOU''LL BE EQUIPPED WITH THE'#13#10 +
          'LATEST IN HUNTER HARDWARE.  ALONG WITH YOUR EXISTING AUTO MAPPER,'#13#10 +
          'HEAT AND MOTION SENSORS HAVE BEEN ADDED TO YOUR VISUAL ARRAY AS'#13#10 +
          'WELL AS AN AFT SENSORY SYSTEM, OR A.S.S. CAM, FOR CONTINUOUS'#13#10 +
          'REAR VIEW.');
        VI_BlitView;
        Wait(3, 1);
        inc(fontbasecolor);
      end;
      while true do
      begin
        Wait(10, 1);
        if newascii then
          break;
      end;
      if lastascii = #27 then
        goto finale;

      VI_FadeOut(0, 256, 0, 0, 0, 64);

      loadscreen('BRIEF3');
      newascii := false;
      fontbasecolor := 0;
      while fontbasecolor < 9 do
      begin
        printy := 149;
        FN_PrintCentered(
          'A MENUING SYSTEM HAS ALSO BEEN INSTALLED ALLOWING YOU TO'#13#10 +
          'FINE TUNE YOUR HARDWARE SETTINGS.  STAY ALERT THOUGH, YOUR MENU'#13#10 +
          'OVERLAY CANCELS INPUT FROM YOUR VISUAL ARRAY SO DON''T EXPECT TO'#13#10 +
          'SEE THINGS COMING WHILE YOU''RE ADJUSTING YOUR SETTINGS.');
        Wait(3, 1);
        inc(fontbasecolor);
      end;
      while true do
      begin
        Wait(10, 1);
        if newascii then
          break;
      end;
      if lastascii = #27 then
        goto finale;
      VI_FadeOut(0, 256, 0, 0, 0, 64);
    end;

    loadscreen('BRIEF1');
    VI_FadeIn(0, 256, @colors, 64);
    Wait(TICRATE);
    newascii := false;
    fontbasecolor := 0;
    while fontbasecolor < 9 do
    begin
      printy := 139;
      FN_PrintCentered(
        'BUILT FROM A HOLLOWED ASTEROID, THE DESARIAN PENAL COLONY'#13#10 +
        'HOUSES THE DREGS OF IMPERIAL SOCIETY.  A RIOT IS IN PROGRESS'#13#10 +
        'WHICH SHOULD MAKE ITEM RETRIEVAL INTERESTING.'#13#10 +
        'THE PRIMARY ITEM TO BE LOCATED HERE IS THE BYZANTIUM BRASS RING,'#13#10 +
        'AN ANCIENT ARTIFACT NOW USED AS THE POWER CORE FOR THE COMPLEX.'#13#10 +
        'SUCH AN ENIGMATIC ENERGY SOURCE IS OF OBVIOUS INTEREST TO A.V.C.'#13#10 +
        'RESEARCH, SO ACQUIRING IT UNDAMAGED IS ESSENTIAL.'#13#10 +
        'YOUR ENTRY POINT WILL BE AT THE BASE OF THE COMPLEX.'#13#10);
      Wait(3, 1);
      inc(fontbasecolor);
    end;
    while true do
    begin
      Wait(10, 1);
      if newascii then
        break;
    end;
    if lastascii = #27 then
      goto finale;
    VI_FadeOut(0, 256, 0, 0, 0, 64);

    loadscreen('BRIEF2');
    VI_FadeIn(0, 256, @colors, 64);
    Wait(TICRATE);
    newascii := false;
    fontbasecolor := 0;
    while fontbasecolor < 9 do
    begin
      printy := 139;
      FN_PrintCentered(
        'EACH SUBLEVEL WILL HAVE A MANDATORY PRIMARY OBJECTIVE, AS WELL'#13#10 +
        'AS OPTIONAL SECONDARY OBJECTIVES, ALL OF WHICH HELP YOU TO'#13#10 +
        'ACHIEVE A STATED POINT TOTAL NEEDED TO ADVANCE TO THE NEXT LEVEL.'#13#10 +
        'POINTS ARE ALSO AWARDED FOR KILLS AS WELL AS ACQUIRING RANDOMLY'#13#10 +
        'PLACED OBJECTS TAKEN FROM THE SHIP''S INVENTORY. EXPECT'#13#10 +
        'NON-COOPERATIVES (NOPS) FROM OTHER PARTS OF THE COLONY TO BE'#13#10 +
        'BROUGHT IN AT REGULAR INTERVALS TO REPLACE CASUALTIES OF THE HUNT.'#13#10);
      Wait(3, 1);
      inc(fontbasecolor);
    end;
    while true do
    begin
      Wait(10, 1);
      if newascii then
        break;
    end;
    if lastascii = #27 then
      goto finale;

    loadscreen('BRIEF2');
    newascii := false;
    fontbasecolor := 0;
    while fontbasecolor < 9 do
    begin
      printy := 139;
      FN_PrintCentered(
        'THIS MISSION WILL BEGIN IN THE INMATE PROCESSING AREA, WHERE'#13#10 +
        'YOU ARE TO SEARCH FOR AN EXPERIMENTAL EXPLOSIVE HIDDEN'#13#10 +
        'IN THE SUBLEVEL.'#13#10 +
        'SECONDARY GOALS ARE PHOSPHER PELLETS AND DELOUSING KITS.'#13#10);
      Wait(3, 1);
      inc(fontbasecolor);
    end;
    while true do
    begin
      Wait(10, 1);
      if newascii then
        break;
    end;
    if lastascii = #27 then
      goto finale;

    loadscreen('BRIEF2');
    newascii := false;
    fontbasecolor := 0;
    while fontbasecolor < 9 do
    begin
      printy := 139;
      FN_PrintCentered(
        'YOU WILL BE MONITORED.  POINTS WILL BE AWARDED FOR PRIMARY,'#13#10 +
        'SECONDARY, AND RANDOM ITEMS, AS WELL AS FOR KILLING NOPS.'#13#10 +
        'WHEN YOU''VE ACQUIRED THE PRIMARY ITEM AND YOUR POINT TOTAL'#13#10 +
        'MEETS OR EXCEEDS 50000 WE''LL OPEN A TRANSLATION NEXUS.  WATCH'#13#10 +
        'FOR THE FLASHING EXIT SIGN.  ENTER THE NEXUS AND WE''LL'#13#10 +
        'TRANSLATE YOU TO THE NEXT AREA OF THE BASE.\n \nGOOD LUCK.');
      Wait(3, 1);
      inc(fontbasecolor);
    end;
    while true do
    begin
      Wait(10, 1);
      if newascii then
        break;
    end;
    if lastascii = #27 then
      goto finale;
  end
  else if (GAME1 and (map < 8)) or (GAME2 and (map < 16)) or (GAME3 and (map < 22)) then
  begin
    c := Chr(cdr_drivenum + Ord('A'));
    if map = 8 then
    begin
      player.levelscore := levelscore;
      player.weapons[2] := -1;
      player.weapons[3] := -1;
      player.weapons[4] := -1;
      player.currentweapon := 0;
      loadweapon(player.weapons[0]);
      memset(@player.inventory, 0, SizeOf(player.inventory));
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

      if CDROMGREEDDIR then
      begin
        if not GAME2 then
        begin
          name := c + ':\GREED\MOVIES\PRISON1.FLI';
          DoPlayFLI(name, 0);
        end;
        name := c + ':\GREED\MOVIES\TEMPLE1.FLI';
        DoPlayFLI(name, 0);
      end
      else
      begin
        if not GAME2 then
        begin
          name := c + ':\MOVIES\PRISON1.FLI';
          DoPlayFLI(name, 0);
        end;
        name := c + ':\MOVIES\TEMPLE1.FLI';
        DoPlayFLI(name, 0);
      end;

      selectsong(map);

      VI_FillPalette(0, 0, 0);
      loadscreen('BRIEF4');
      VI_FadeIn(0, 256, @colors, 64);
      Wait(TICRATE);
      newascii := false;
      fontbasecolor := 0;
      while fontbasecolor < 9 do
      begin
        printy := 139;
        FN_PrintCentered(
         'THIS IS THE CITY-TEMPLE OF RISTANAK, ANCIENT HOME TO THE'#13#10 +
         'PRIESTHOOD OF YRKTAREL.  THE PRIESTHOOD HAS WORSHIPPED THEIR'#13#10 +
         'PAGAN DEITY FOR CENTURIES IN PEACE... UNTIL NOW.'#13#10);
        Wait(3, 1);
        inc(fontbasecolor);
      end;
      while true do
      begin
        Wait(10, 1);
        if newascii then
          break;
      end;
      if lastascii = #27 then
        goto finale;
      VI_FadeOut(0, 256, 0, 0, 0, 64);

      loadscreen('BRIEF5');
      VI_FadeIn(0, 256, @colors, 64);
      Wait(TICRATE);
      newascii := false;
      fontbasecolor := 0;
      while fontbasecolor < 9 do
      begin
        printy := 139;
        FN_PrintCentered(
         'THE PRIMARY OBJECTIVE FOR THE TEMPLE IS THE ENCODED'#13#10 +
         'PERSONALITY MATRIX OF THE DEMON-SAINT B''RNOURD.  THIS IS,'#13#10 +
         'OF COURSE, AN ITEM WHOSE POSSESSION, IF KNOWN, WOULD BRING'#13#10 +
         'INSTANT DESTRUCTION.  THE IMPERIAL COUNCIL WOULD ORDER THE'#13#10 +
         'SECTOR STERILIZED IF IT KNEW OF ITS EXISTENCE.'#13#10 +
         'THE A.V.C. BELIEVES THE ENCODE TO CONTAIN FORGOTTEN'#13#10 +
         'TECHNOLOGIES WHICH WOULD BE PRICELESS ON THE BLACK MARKET.'#13#10 +
         'IT IS YOUR MISSION TO ACQUIRE IT.'#13#10);
        Wait(3, 1);
        inc(fontbasecolor);
      end;
      while true do
      begin
        Wait(10, 1);
        if newascii then
          break;
      end;
      if lastascii = #27 then
        goto finale;
      VI_FadeOut(0, 256, 0, 0, 0, 64);
    end
    else if map = 16 then
    begin
      player.levelscore := levelscore;
      player.weapons[2] := -1;
      player.weapons[3] := -1;
      player.weapons[4] := -1;
      player.currentweapon := 0;
      loadweapon(player.weapons[0]);
      memset(@player.inventory, 0, SizeOf(player.inventory));
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

      if CDROMGREEDDIR then
      begin
        if not GAME3 then
        begin
          name := c + ':\GREED\MOVIES\TEMPLE2.FLI';
          DoPlayFLI(name, 0);
        end;
        name := c + ':\GREED\MOVIES\JUMPBAS1.FLI';
        DoPlayFLI(name, 0);
        name := c + ':\GREED\MOVIES\JUMPBAS2.FLI';
        DoPlayFLI(name, 0);
      end
      else
      begin
        if not GAME3 then
        begin
          name := c + ':\MOVIES\TEMPLE2.FLI';
          DoPlayFLI(name, 0);
        end;
        name := c + ':\MOVIES\JUMPBAS1.FLI';
        DoPlayFLI(name, 0);
        name := c + ':\MOVIES\JUMPBAS2.FLI';
        DoPlayFLI(name, 0);
      end;

      selectsong(map);

      VI_FillPalette(0, 0, 0);

      loadscreen('BRIEF6');
      VI_FadeIn(0, 256, @colors, 64);
      Wait(TICRATE);
      newascii := false;
      fontbasecolor := 0;
      while fontbasecolor < 9 do
      begin
        printy := 139;
        FN_PrintCentered(
         'DURING THE INSURRECTION AT ALPHA PRAM,  THE FOURTH PLANET IN'#13#10 +
         'THE SYSTEM, WHICH WAS BASE TO THE ELITE GALACTIC CORPS, WAS'#13#10 +
         'DESTROYED BY A BOVINARIAN VIOLATOR SHIP.  THE SHIELDING'#13#10 +
         'SURROUNDING THE MOUNTAIN WHERE THE CORPS WAS BASED WAS SO'#13#10 +
         'STRONG, HOWEVER, THAT THE MOUNTAIN SURVIVED.  THE BASE WAS'#13#10 +
         'THEN MOUNTED TO A TROJAN GATE JUMP POINT AND TO THIS DAY IT'#13#10 +
         'REMAINS AS A WAY POINT BETWEEN THE RIM WORLDS AND THE CORE'#13#10 +
         'QUARTER, AS WELL AS HOUSING MILITARY MIGHT IN THIS SECTOR.'#13#10);
        Wait(3, 1);
        inc(fontbasecolor);
      end;
      while true do
      begin
        Wait(10, 1);
        if newascii then
          break;
      end;
      if lastascii = #27 then
        goto finale;
      VI_FadeOut(0, 256, 0, 0, 0, 64);

      loadscreen('BRIEF7');
      VI_FadeIn(0, 256, @colors, 64);
      Wait(TICRATE);
      newascii := false;
      fontbasecolor := 0;
      while fontbasecolor < 9 do
      begin
        printy := 139;
        FN_PrintCentered(
         'THE PRIMARY OBJECTIVE FOR THIS WORLD IS THE IMPERIAL SIGIL.'#13#10 +
         'IT IS THE SYMBOL OF POWER WHICH MAINTAINS THE CHANCELLOR'#13#10 +
         'IN HIS POSITION OF DOMINANCE WITHIN THE SECTOR.  YOU HAVE BUT'#13#10 +
         'TO TAKE THE SIGIL FROM THE CHANCELLOR HIMSELF.  UNFORTUNATELY'#13#10 +
         'FOR YOU, THE DESPOTIC CHANCELLOR HAD HIS FLESH REPLACED'#13#10 +
         'BY A CYBERNETIC SYMBIOTE IN ORDER TO INSURE HIS IMMORTALITY'#13#10 +
         'AND SUBSEQUENT ETERNAL RULE OF THE CORPS.  OVER 30 ATTEMPTS'#13#10 +
         'HAVE BEEN MADE TO WREST THE SIGIL FROM THE CHANCELLOR''S GRASP.'#13#10 +
         'THEY ALL FAILED.'#13#10);
        Wait(3, 1);
        inc(fontbasecolor);
      end;
      while true do
      begin
        Wait(10, 1);
        if newascii then
          break;
      end;
      if lastascii = #27 then
        goto finale;
      VI_FadeOut(0, 256, 0, 0, 0, 64);
    end;

    VI_FillPalette(0, 0, 0);
    if map < 8 then
      loadscreen('TRANS')
    else if map < 16 then
      loadscreen('TRANS2')
    else
      loadscreen('TRANS3');
    VI_FadeIn(0, 256, @colors, 64);
    newascii := false;
    pprimaries := player.primaries[0] + player.primaries[1];
    tprimaries := pcount[0] + pcount[1];
    psecondaries := 0;
    tsecondaries := 0;
    for i := 0 to 6 do
    begin
      psecondaries := psecondaries + player.secondaries[i];
      tsecondaries := tsecondaries + scount[i];
    end;
    fontbasecolor := 8;
    printx := 20;
    printy := 30;
    str := 'MISSION SUCCESSFUL!';
    FN_RawPrint3(str);
    printx := 25;
    printy := 40;
    sprintf(str, 'PRIMARY GOALS STOLEN: %d of %d', [pprimaries, tprimaries]);
    FN_RawPrint3(str);
    printx := 25;
    printy := 50;
    sprintf(str, 'SECONDARY GOALS STOLEN: %d of %d', [psecondaries, tsecondaries]);
    FN_RawPrint3(str);
    printx := 25;
    printy := 65;
    sprintf(str, 'POINT TOTAL: %d', [player.score]);
    FN_RawPrint3(str);
    printx := 25;
    printy := 75;
    sprintf(str, 'TOTAL KILLS: %d', [player.bodycount]);
    FN_RawPrint3(str);
    fontbasecolor := 0;
    while fontbasecolor < 9 do
    begin
      printy := 85;
      FN_PrintCentered(missioninfo(map, 0));
      FN_PrintCentered(missioninfo(map, 1));
      FN_PrintCentered(missioninfo(map, 2));
      Wait(3, 1);
      inc(fontbasecolor);
    end;
    while true do
    begin
      Wait(10, 1);
      if newascii then
        break;
    end;
    VI_FadeOut(0, 256, 0, 0, 0, 64);
  end;

finale:
  memcpy(@viewbuffer, scr, 64000);
  memfree(pointer(scr));
  memset(screen, 0, 64000);
  I_SetPalette(CA_CachePalette(CA_GetNamedNum('palette')));
  timecount := oldtimecount;
end;

end.
